// ธีมของการ์ด + สีทุก token ที่ผังอ้าง (= Theme/CardTheme.swift · theme/CardTheme.kt Ink.kt ColorTools.kt ColorDuo.kt
// Legibility.kt ScrapTone.kt · KitLook (model/KitModel.kt) · PosterPlate · Ed.skin · Pop)
//
// สีเป็น {r, g, b, a} ค่า 0…1 · `css(c)` แปลงเป็น rgba() ตอนวาด

// MARK: - สี

export const rgb = (r, g, b, a = 1) => ({ r, g, b, a })
export const grey = (w, a = 1) => rgb(w, w, w, a)
export const WHITE = rgb(1, 1, 1)
export const BLACK = rgb(0, 0, 0)
export const CLEAR = rgb(0, 0, 0, 0)
const clamp01 = (v) => Math.min(1, Math.max(0, v))
const frac = (v) => v - Math.floor(v)

/** `Color(hue:saturation:brightness:)` — hue 0…1 */
export function hsb(h, s, v, a = 1) {
  const h6 = frac(h) * 6
  s = clamp01(s); v = clamp01(v)
  const c = v * s, x = c * (1 - Math.abs((h6 % 2) - 1)), m = v - c
  const i = Math.floor(h6)
  const [r, g, b] = i === 0 ? [c, x, 0] : i === 1 ? [x, c, 0] : i === 2 ? [0, c, x] : i === 3 ? [0, x, c] : i === 4 ? [x, 0, c] : [c, 0, x]
  return rgb(r + m, g + m, b + m, a)
}
export const hex = (v) => rgb(((v >> 16) & 255) / 255, ((v >> 8) & 255) / 255, (v & 255) / 255)
/** `#RRGGBB` หรือ `#RRGGBBAA` */
export function parseHex(s) {
  let h = s.replace(/^#/, '')
  if (h.length === 3) h = [...h].map((c) => c + c).join('')
  if (h.length === 6) h += 'FF'
  const n = parseInt(h, 16)
  if (Number.isNaN(n)) return CLEAR
  return rgb(((n >>> 24) & 255) / 255, ((n >>> 16) & 255) / 255, ((n >>> 8) & 255) / 255, (n & 255) / 255)
}
/** `.opacity(x)` ของ SwiftUI — **คูณ** กับความทึบเดิม */
export const opacity = (c, a) => ({ ...c, a: clamp01(c.a * a) })
/** ผสมไปหาอีกสีตามสัดส่วน 0…1 ใน sRGB */
export function mixed(c, o, k) {
  k = clamp01(k)
  return rgb(c.r + (o.r - c.r) * k, c.g + (o.g - c.g) * k, c.b + (o.b - c.b) * k, c.a)
}
export function toHSB(c) {
  const mx = Math.max(c.r, c.g, c.b), mn = Math.min(c.r, c.g, c.b), d = mx - mn
  const s = mx <= 0 ? 0 : d / mx
  let h = 0
  if (d > 1e-9) {
    h = (mx === c.r ? ((c.g - c.b) / d) % 6 : mx === c.g ? (c.b - c.r) / d + 2 : (c.r - c.g) / d + 4) / 6
    if (h < 0) h += 1
  }
  return { h, s, b: mx }
}
/** เวอร์ชันที่อ่านออกบนพื้นสว่าง — ลดความสว่าง เพิ่มความอิ่ม */
export function onLightSurface(c, depth = 1) {
  const { h, s, b } = toHSB(c)
  const k = clamp01(depth)
  return hsb(h, Math.min(1, s * (1.35 - 0.28 * (1 - k)) + 0.12), Math.min(1, b * (0.60 + 0.26 * (1 - k))), c.a)
}
export const css = (c) => `rgba(${Math.round(clamp01(c.r) * 255)},${Math.round(clamp01(c.g) * 255)},${Math.round(clamp01(c.b) * 255)},${+clamp01(c.a).toFixed(4)})`
export const hexOf = (c) => '#' + [c.r, c.g, c.b].map((v) => Math.round(clamp01(v) * 255).toString(16).padStart(2, '0')).join('').toUpperCase()

// MARK: - ความอ่านออก (Legibility)

export const Legibility = {
  body: 4.5, large: 3.0,
  linear(v) { const x = clamp01(v); return x <= 0.04045 ? x / 12.92 : ((x + 0.055) / 1.055) ** 2.4 },
  encoded(l) { const x = clamp01(l); return x <= 0.0031308 ? x * 12.92 : 1.055 * x ** (1 / 2.4) - 0.055 },
  ratio(a, b) { return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05) },
  target(e) { return e >= 0.4 ? this.body : e >= 0.28 ? this.large : 1 },
  composite(top, alpha, over) { const a = clamp01(alpha); return this.linear(this.encoded(over) * (1 - a) + this.encoded(top) * a) },
  alpha(ink, over, target) {
    if (target <= 1) return 0
    const g = this.encoded(over), b = this.encoded(ink)
    if (Math.abs(b - g) <= 0.0001) return 1
    let goal
    if (ink > over) { goal = target * (over + 0.05) - 0.05; if (goal >= ink) return 1 }
    else { goal = (over + 0.05) / target - 0.05; if (goal <= ink) return 1 }
    return clamp01((this.encoded(goal) - g) / (b - g))
  },
}
export const luminance = (c) => 0.2126 * Legibility.linear(c.r) + 0.7152 * Legibility.linear(c.g) + 0.0722 * Legibility.linear(c.b)

export class InkGround {
  constructor(lo, hi) { this.lo = lo; this.hi = hi }
  static of(a, b) { return new InkGround(Math.min(a, b), Math.max(a, b)) }
  covered(panel, alpha) {
    if (alpha <= 0) return this
    return InkGround.of(Legibility.composite(panel, alpha, this.lo), Legibility.composite(panel, alpha, this.hi))
  }
}
InkGround.stage = new InkGround(0.002, 0.03)

/** ชุดสีที่ใช้ "บนพื้นการ์ด" (= `InkStyle`) */
export class InkStyle {
  constructor(ink, base, ground = InkGround.stage) {
    this.ink = ink; this.base = base; this.ground = ground
    this.baseLuminance = luminance(base)
  }
  get isLight() { return this.ink !== 'night' }
  text(l) {
    const designed = this.isLight ? Math.min(0.94, Math.max(0, l) ** 0.85) : l
    const needed = Legibility.alpha(this.baseLuminance, this.isLight ? this.ground.lo : this.ground.hi, Legibility.target(l))
    return opacity(this.base, Math.min(1, Math.max(designed, needed)))
  }
  covered(panel, alpha) { return new InkStyle(this.ink, this.base, this.ground.covered(panel, alpha)) }
  ghost(l) { return this.isLight ? opacity(this.base, l * 0.5) : opacity(this.base, l) }
  line(l) { return this.isLight ? opacity(this.base, Math.min(0.6, l * 0.8)) : opacity(this.base, l) }
  fill(l) { return this.isLight ? opacity(this.base, Math.min(0.5, l * 0.8)) : opacity(this.base, l) }
  get lift() { return this.isLight ? opacity(BLACK, 0.18) : CLEAR }
  get liftRadius() { return this.isLight ? 14 : 0 }
}
InkStyle.night = new InkStyle('night', WHITE)

// MARK: - พาเลตต์ · คู่สี

const P = (accent, soft, hue) => ({ accent: rgb(...accent), accentSoft: rgb(...soft), hue })
export const PALETTES = {
  midnight: P([0.51, 0.60, 1.00], [0.62, 0.78, 1.00], 0.64),
  sky: P([0.38, 0.66, 1.00], [0.58, 0.80, 1.00], 0.58),
  ocean: P([0.32, 0.79, 0.95], [0.46, 0.94, 0.88], 0.54),
  mint: P([0.36, 0.90, 0.68], [0.63, 0.96, 0.80], 0.42),
  lime: P([0.72, 0.93, 0.40], [0.85, 1.00, 0.62], 0.24),
  lavender: P([0.72, 0.63, 1.00], [0.88, 0.74, 1.00], 0.74),
  orchid: P([0.93, 0.52, 0.98], [1.00, 0.70, 1.00], 0.82),
  rose: P([1.00, 0.55, 0.74], [1.00, 0.73, 0.85], 0.93),
  ruby: P([1.00, 0.42, 0.47], [1.00, 0.63, 0.66], 0.98),
  coral: P([1.00, 0.60, 0.43], [1.00, 0.77, 0.60], 0.04),
  champagne: P([0.93, 0.80, 0.55], [1.00, 0.92, 0.74], 0.10),
  noir: P([0.84, 0.86, 0.90], [0.62, 0.65, 0.72], 0.62),
}
export const DUOS = {
  indigo: [0x282B4A, 0xEEEBDA], ink: [0x14161A, 0xF1EEE6], field: [0x3A4B41, 0xE6CFA7], cocoa: [0x3E000C, 0xFFECD1],
  teal: [0x0E3B3E, 0xF7CBA7], plum: [0x2B1A47, 0xE6D8FF], merlot: [0x4A1B2F, 0xF6D9DE], cordovan: [0x8C2F39, 0xFFF6E7],
  cobalt: [0x17307E, 0xFFE08A], clay: [0x8E3620, 0xF3E3D0], acid: [0x17181C, 0xD8FF3E],
}
const CORNER = { soft: 18, round: 28, pill: 38 }

// MARK: - ธีม

/** ธีมของการ์ดจาก `doc.theme` (= `CardTheme`) — ค่าที่ไม่มีใช้ค่าตั้งต้นของแอป */
export function makeTheme(t = {}) {
  const th = {
    palette: PALETTES[t.palette] ? t.palette : 'midnight',
    ink: ['night', 'paper', 'mist'].includes(t.ink) ? t.ink : 'night',
    inkAuto: t.inkAuto ?? true,
    corner: CORNER[t.corner] ? t.corner : 'round',
    strip: t.strip || 'line',
    backdrop: t.backdrop || 'gradient',
    duoID: t.duo ?? t.duoID ?? null,
    duoFlipped: t.duoFlipped ?? false,
    brightness: t.brightness ?? 0.30,
    hueShift: t.hueShift ?? 0,
    customHue: t.customHue ?? null,
    customSat: t.customSat ?? null,
    customBri: t.customBri ?? null,
    photoEffect: t.photoEffect || 'none',
    photoDim: t.photoDim ?? 0.42,
  }
  const pal = PALETTES[th.palette]
  const duo = th.duoID && DUOS[th.duoID] ? { dark: hex(DUOS[th.duoID][0]), light: hex(DUOS[th.duoID][1]) } : null
  th.activeDuo = th.backdrop === 'photo' ? null : duo
  th.duoColors = th.activeDuo ? (th.duoFlipped ? { bg: th.activeDuo.light, ink: th.activeDuo.dark } : { bg: th.activeDuo.dark, ink: th.activeDuo.light }) : null
  th.duoDark = th.activeDuo ? th.activeDuo.dark : null
  th.duoLight = th.activeDuo ? th.activeDuo.light : null
  th.backdropHue = frac((th.customHue ?? pal.hue) + th.hueShift)
  const backdropSat = th.customHue != null ? Math.min(0.6, Math.max(0.15, th.customSat ?? 0.5)) : (th.palette === 'noir' ? 0.10 : 0.58)
  const customParts = th.customBri != null && th.customHue != null
    ? { h: th.backdropHue, s: clamp01(th.customSat ?? 0.5), b: clamp01(th.customBri) } : null
  th.lightInk = (th.customSat ?? 0) >= 0.35 ? 'mist' : 'paper'
  th.activeInk = (() => {
    if (th.backdrop === 'photo') return 'night'
    if (th.duoColors) return luminance(th.duoColors.bg) > luminance(th.duoColors.ink) ? th.lightInk : 'night'
    if (!th.inkAuto) return th.ink !== 'night' ? th.lightInk : 'night'
    if (!customParts) return 'night'
    const l = luminance(hsb(customParts.h, customParts.s, customParts.b))
    return (l + 0.05) / 0.07 <= 1.05 / (l + 0.05) ? 'night' : th.lightInk
  })()
  th.isLight = th.activeInk !== 'night'
  th.backdropColors = (() => {
    const c = th.duoColors
    if (c) {
      const inkDarker = luminance(c.ink) < luminance(c.bg)
      return { top: c.bg, bottom: inkDarker ? mixed(c.bg, c.ink, 0.10) : mixed(c.bg, BLACK, 0.26) }
    }
    if (customParts) {
      const p = customParts
      return { top: hsb(p.h, p.s, p.b), bottom: hsb(p.h, Math.min(1, p.s * 1.06), p.b * 0.80) }
    }
    const h = th.backdropHue, s = backdropSat, b = th.brightness
    if (th.activeInk === 'night') return { top: hsb(h, Math.max(0, s - b * 0.28), 0.05 + b * 0.52), bottom: hsb(h, Math.max(0, s - b * 0.20), 0.015 + b * 0.22) }
    if (th.activeInk === 'paper') return { top: hsb(h, 0.03 + s * 0.04, 0.955 + b * 0.045), bottom: hsb(h, 0.06 + s * 0.07, 0.865 + b * 0.075) }
    return { top: hsb(h, 0.09 + s * 0.16, 0.945 + b * 0.05), bottom: hsb(h, 0.20 + s * 0.26, 0.815 + b * 0.10) }
  })()
  th.stripeInk = th.duoColors ? opacity(th.duoColors.ink, 0.10)
    : th.activeInk === 'night' ? opacity(hsb(th.backdropHue, Math.min(1, backdropSat + 0.1), 0.85), 0.10)
      : th.activeInk === 'paper' ? opacity(hsb(th.backdropHue, 0.22, 0.58), 0.13) : opacity(hsb(th.backdropHue, 0.40, 0.55), 0.14)
  th.inkStyle = th.duoColors ? new InkStyle(th.activeInk, th.duoColors.ink)
    : !th.isLight ? InkStyle.night
      : new InkStyle(th.activeInk, hsb(th.backdropHue, th.activeInk === 'mist' ? 0.38 : 0.26, th.activeInk === 'mist' ? 0.155 : 0.135))
  th.rawAccent = th.activeDuo ? th.activeDuo.light
    : th.customHue != null ? hsb(th.customHue, Math.min(0.72, Math.max(0.35, (th.customSat ?? 0.5) + 0.1)), 0.96) : pal.accent
  th.rawAccentSoft = th.activeDuo ? mixed(th.activeDuo.light, th.activeDuo.dark, 0.30)
    : th.customHue != null ? hsb(frac(th.customHue + 0.04), Math.min(0.5, Math.max(0.25, th.customSat ?? 0.4)), 1) : pal.accentSoft
  th.accent = th.duoColors ? th.duoColors.ink : th.isLight ? onLightSurface(th.rawAccent) : th.rawAccent
  th.accentSoft = th.duoColors ? mixed(th.duoColors.ink, th.duoColors.bg, 0.34) : th.isLight ? onLightSurface(th.rawAccent, 0.35) : th.rawAccentSoft
  th.radius = CORNER[th.corner]
  /** แผ่น "เข้ม" (= `WidgetChrome.slab`) */
  th.slab = th.duoDark ?? hsb(th.backdropHue, 0.30, 0.10)
  /** แผ่นโปสเตอร์ (= `PosterPlate`) */
  th.plate = th.duoDark ?? hsb(th.backdropHue, 0.60, 0.255)
  th.plateInk = th.duoLight ?? hsb(th.backdropHue, 0.085, 0.95)
  th.scrap = scrapTone(th)
  return th
}

// MARK: - สแครปบุ๊ก (= ScrapTone)

function scrapTone(t) {
  const duo = t.duoColors
  if (duo) {
    const bg = duo.bg, fg = duo.ink, light = t.duoLight ?? fg, deep = t.duoDark ?? bg
    return { dark: luminance(bg) < luminance(fg), paper: mixed(bg, fg, 0.07), speck: fg, ink: fg, soft: mixed(fg, bg, 0.35),
      accent: fg, strong: fg, paperAccent: deep, paperStrong: deep, band: mixed(light, deep, 0.18), mid: mixed(light, deep, 0.32),
      blush: mixed(light, deep, 0.08), shade: deep }
  }
  const hv = toHSB(t.rawAccent), h = hv.h
  const k = Math.min(1.2, Math.max(0.3, hv.s / 0.49))
  const c = (s, v) => hsb(h, Math.min(1, s * k), v)
  const base = { paperAccent: c(0.49, 0.86), paperStrong: c(0.67, 0.76), blush: c(0.10, 0.985) }
  if (!t.isLight) return { ...base, dark: true, paper: c(0.42, 0.31), speck: WHITE, ink: hsb(h, 0.04, 0.98), soft: c(0.16, 0.80),
    accent: c(0.40, 0.98), strong: c(0.45, 1.0), band: c(0.30, 0.95), mid: c(0.36, 0.88), shade: BLACK }
  return { ...base, dark: false, paper: c(0.16, 0.965), speck: c(0.58, 0.75), ink: hex(0x141414), soft: c(0.30, 0.48),
    accent: c(0.49, 0.89), strong: c(0.67, 0.79), band: c(0.28, 0.96), mid: c(0.33, 0.94), shade: c(0.71, 0.55) }
}

// MARK: - ชุดห้าสไตล์ (= KitStyle · KitColor · KitLook)

export const KIT_STYLES = {
  purple: { fill: '#B57EF7', cardToken: 'accent', borderToken: 'card-3', bordered: true, radius: 14 },
  cream: { fill: '#ECE8E2', cardToken: 'card+2', borderToken: 'card-1', bordered: false, radius: 20 },
  gingham: { fill: '#C9D4A6', cardToken: 'card+1', borderToken: 'card-3', bordered: true, radius: 20 },
  night: { fill: '#0B0F14', cardToken: 'card-3', borderToken: 'accent', bordered: true, radius: 16 },
  mac: { fill: '#FAFAFA', cardToken: 'card+3', borderToken: 'card+2', bordered: true, radius: 12 },
}
const hexInt = (h) => { const n = parseInt(String(h).replace(/^#/, ''), 16); return Number.isNaN(n) ? 0x888888 : n }
const kitHex = (h) => hex(hexInt(h))
const kitLum = (h) => { const n = hexInt(h); return (0.299 * ((n >> 16) & 255) + 0.587 * ((n >> 8) & 255) + 0.114 * (n & 255)) / 255 }
function kitShade(h, t) {
  const n = hexInt(h)
  const c = [(n >> 16) & 255, (n >> 8) & 255, n & 255].map((v) => v / 255)
  const to = t >= 0 ? 1 : 0, k = Math.abs(t)
  const m = c.map((v) => v + (to - v) * k)
  return rgb(m[0], m[1], m[2])
}
export function kitResolve(token, t) {
  if (token.startsWith('#')) return token
  const card = hexOf(t.backdropColors.top)
  switch (token) {
    case 'card': return card
    case 'card+1': return hexOf(kitShade(card, 0.35))
    case 'card+2': return hexOf(kitShade(card, 0.72))
    case 'card+3': return hexOf(kitShade(card, 0.92))
    case 'card-1': return hexOf(kitShade(card, -0.35))
    case 'card-2': return hexOf(kitShade(card, -0.62))
    case 'card-3': return hexOf(kitShade(card, -0.84))
    case 'card2': return hexOf(t.backdropColors.bottom)
    case 'accent': return hexOf(t.rawAccent)
    case 'duoDark': return t.duoDark ? hexOf(t.duoDark) : card
    case 'duoLight': return t.duoLight ? hexOf(t.duoLight) : card
    default: return card
  }
}
/** ค่าของชิ้นในชุดห้าสไตล์ (`item.kit`) ที่สีพื้น/ขอบคิดจากการ์ดแล้ว + สีทั้งชุด (= `KitLook`) */
export function kitLook(kit = {}, border, cardDark, t) {
  const style = KIT_STYLES[kit.style] ? kit.style : 'purple'
  const st = KIT_STYLES[style]
  const fill = kit.fill || 'solid'
  const fillHex = kitResolve(st.cardToken, t)
  const borderHex = kitResolve(st.borderToken, t)
  const dark = style === 'gingham' ? false : fill === 'clear' ? cardDark : kitLum(fillHex) < 0.45
  const ink = dark ? grey(0.96) : rgb(0.08, 0.08, 0.09)
  const mut = dark ? opacity(WHITE, 0.6) : opacity(BLACK, 0.52)
  const borderColor = kitHex(borderHex)
  const accent = style === 'night'
    ? (border ? (dark || kitLum(borderHex) < 0.5 ? borderColor : kitShade(borderHex, -0.55)) : dark ? kitHex('#5AC8F0') : kitHex('#0E7FB0'))
    : style === 'mac' ? (dark ? kitHex('#6AA8FF') : kitHex('#2F6FE4')) : ink
  const title = style === 'gingham' ? rgb(0.07, 0.07, 0.07) : style === 'cream' ? (dark ? ink : rgb(0.17, 0.17, 0.17))
    : style === 'mac' ? (dark ? grey(0.9) : grey(0.29)) : ink
  const block = style === 'purple' ? WHITE
    : style === 'cream' ? (fill === 'clear' ? (dark ? opacity(WHITE, 0.08) : opacity(WHITE, 0.7)) : dark ? kitShade(fillHex, 0.08) : kitShade(fillHex, 0.55))
      : style === 'gingham' ? grey(0.95) : style === 'night' ? (dark ? opacity(WHITE, 0.035) : opacity(BLACK, 0.04)) : dark ? opacity(WHITE, 0.08) : grey(0.93)
  return { style, fill, fillHex, dark, ink, mut, borderColor, accent, title, block, fillColor: fill === 'clear' ? CLEAR : kitHex(fillHex) }
}

// MARK: - สำรับบรรณาธิการ (= Ed.skin) · สติกเกอร์ (= Pop)

const ED = { paper: rgb(0.937, 0.933, 0.925), ink: rgb(0.105, 0.105, 0.110), inkSoft: rgb(0.365, 0.357, 0.345),
  red: rgb(0.647, 0.161, 0.129), marker: rgb(0.145, 0.290, 0.776) }
function edSkin(surface, ink, t) {
  if (surface === 'pane') {
    return { sheet: CLEAR, ink: ink.text(0.95), inkSoft: ink.text(0.55), ghost: ink.ghost(0.14), marker: t.accent, red: t.accent }
  }
  if (surface !== 'clear') {
    if (t.activeDuo) {
      const plate = t.plate, cream = t.plateInk
      return { sheet: plate, ink: cream, inkSoft: mixed(cream, plate, 0.38), ghost: opacity(cream, 0.16), marker: cream, red: cream }
    }
    const onPaper = onLightSurface(t.rawAccent)
    return { sheet: ED.paper, ink: ED.ink, inkSoft: ED.inkSoft, ghost: WHITE, marker: onPaper, red: onPaper }
  }
  return { sheet: CLEAR, ink: ink.text(0.95), inkSoft: ink.text(0.6), ghost: ink.ghost(0.22), marker: t.accent, red: t.accent }
}
const POP = { ink: rgb(0.11, 0.10, 0.13), inkSoft: rgb(0.40, 0.37, 0.43), paper: WHITE, rule: rgb(0.84, 0.82, 0.85) }

/**
 * สีของ token เพิ่มเติมต่อชิ้น (= `extraTokens` ใน SpecPainter.kt) — ขึ้นกับธีม หมึกที่ชิ้นนั่ง พื้นผิว วัสดุแผ่น (`widget.skin`) และค่าชุดห้าสไตล์
 */
export function extraTokens(t, ink, surface, skin, kit, border) {
  const look = kitLook(kit, border, !ink.isLight, t)
  const ed = edSkin(surface, ink, t)
  // วัสดุแผ่นสติกเกอร์ (`widget.skin`) — ไม่ใช่สำรับนี้ = กระจก (ค่าตั้งต้นของ `pop.sheet`)
  const glassSkin = skin !== 'paper'
  const s = t.scrap
  return {
    look,
    map: {
      'kit.fill': kitHex(look.fillHex), 'kit.border': look.borderColor, 'kit.ink': look.ink, 'kit.mut': look.mut,
      'kit.accent': look.accent, 'kit.title': look.title, 'kit.block': look.block,
      'scrap.paper': s.paper, 'scrap.ink': s.ink, 'scrap.soft': s.soft, 'scrap.accent': s.accent, 'scrap.strong': s.strong,
      'scrap.paperAccent': s.paperAccent, 'scrap.paperStrong': s.paperStrong, 'scrap.band': s.band, 'scrap.mid': s.mid,
      'scrap.blush': s.blush, 'scrap.shade': s.shade, 'scrap.speck': s.speck,
      rawAccent: t.rawAccent, rawAccentSoft: t.rawAccentSoft,
      plate: t.plate, plateInk: t.plateInk,
      accentPaper: onLightSurface(t.rawAccent),
      'ed.sheet': ed.sheet, 'ed.ink': ed.ink, 'ed.inkSoft': ed.inkSoft, 'ed.ghost': ed.ghost, 'ed.marker': ed.marker, 'ed.red': ed.red,
      'pop.ink': POP.ink, 'pop.inkSoft': POP.inkSoft, 'pop.rule': POP.rule, 'pop.paper': POP.paper,
      'pop.sheet': surface === 'glass' ? opacity(POP.paper, glassSkin ? 0.62 : 0.9) : POP.paper,
      'pop.shadow': glassSkin ? opacity(t.rawAccent, 0.35) : opacity(BLACK, 0.22),
    },
  }
}

/** token → สี (= `SpecColor.resolve`) · `ink` `ink@0.45` · `line` · `fill` · `ghost` · `accent` · `paper` · `#RRGGBB[AA]` */
export function tokenColor(token, ink, accent, t, extra = {}) {
  let name = token, alpha = null
  const at = token.lastIndexOf('@')
  if (at >= 0) { name = token.slice(0, at); const v = Number(token.slice(at + 1)); alpha = Number.isNaN(v) ? null : v }
  const x = extra[name]
  if (x) return alpha != null ? opacity(x, alpha) : x
  let base
  switch (name) {
    case 'ink': return ink.text(alpha ?? 1)
    case 'line': return ink.line(alpha ?? 0.12)
    case 'fill': return ink.fill(alpha ?? 0.14)
    case 'ghost': return ink.ghost(alpha ?? 0.5)
    case 'accent': base = accent; break
    case 'accentSoft': base = t.accentSoft; break
    case 'paper': base = ink.isLight ? WHITE : grey(0.08); break
    case 'white': base = WHITE; break
    case 'black': base = BLACK; break
    case 'clear': return CLEAR
    default: base = name.startsWith('#') ? parseHex(name) : CLEAR
  }
  return alpha != null ? opacity(base, alpha) : base
}

/** หมึกบนแผ่นของ chrome (= `chromeInk` ใน WidgetChrome.kt) */
export function chromeInk(ink, surface, t) {
  if (surface === 'clear') return ink
  if (surface === 'glass' || surface === 'pane') {
    if (t.activeDuo) return ink.covered(0, 0.16)
    return ink.isLight ? ink.covered(1, 0.58) : ink.covered(0, 0.16)
  }
  const lum = luminance(t.slab)
  return new InkStyle('night', t.duoLight ?? WHITE, InkGround.of(lum, lum))
}
