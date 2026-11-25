// จำลอง "สีวิดเจ็ต" ของ salehere-ios (`StarCardTheme.withWidgetColor` + `StarCardPalette.sheet`) บนเว็บเรนเดอร์ — ใช้ถ่ายภาพก่อน/หลังเท่านั้น
// import map ชี้ /js/theme.js → ไฟล์นี้ · ของจริงยังมาจาก theme.js?orig ทุกตัว ยกเว้น specPalette
export * from '/js/theme.js?orig'
import * as T from '/js/theme.js?orig'
const { kitLook, hsb, mixed, opacity, parseHex, toHSB, luminance, onLightSurface, Legibility, WHITE, BLACK, CLEAR, grey } = T
const SURFACES = new Set(['card', 'light', 'dark'])
const ROLES = new Set(['bg', 'bg2', 'ink', 'ink2', 'accent', 'line'])

// = StarCardTheme.widgetInk(on:) — คืน { light: หมึกสำหรับพื้นสว่าง?, base }
function widgetInk(plate) {
  const l = luminance(plate)
  if (!((l + 0.05) / 0.07 > 1.05 / (l + 0.05))) return { isLight: false, base: WHITE }
  const p = toHSB(plate)
  return { isLight: true, base: hsb(p.h, Math.min(0.45, p.s), 0.13) }
}
// = StarCardRGBA.legible(on:target:prefersLight:) แบบย่อ: ดันความสว่างทีละขั้นจนถึง contrast เป้า
function legible(c, groundLum, target, prefersLight) {
  const h = toHSB(c)
  for (let i = 0; i <= 40; i++) {
    const v = prefersLight ? Math.min(1, h.b + i * 0.025) : Math.max(0, h.b - i * 0.025)
    const s = prefersLight ? Math.max(0, h.s - i * 0.012) : h.s
    const x = hsb(h.h, s, v, c.a)
    if (Legibility.ratio(luminance(x), groundLum) >= target) return x
  }
  return prefersLight ? WHITE : BLACK
}
function widgetAccent(t, plate) {
  const ink = widgetInk(plate)
  if (toHSB(plate).s < 0.02) return ink.base
  const c = ink.isLight ? onLightSurface(t.rawAccent) : t.rawAccent
  return legible(c, luminance(plate), Legibility.large, !ink.isLight)
}

export function specPalette({ t, ink, accent, surface, skin, kit, border, base }) {
  const wc = globalThis.__wc ? parseHex(globalThis.__wc) : null
  const look = kitLook(kit, border, !ink.isLight, t)
  const baseSurface = SURFACES.has(base) ? base : 'card'
  const noSheet = surface === 'clear' || surface === 'pane' || (kit?.fill ?? 'solid') === 'clear'
  const card = (role, a) => {
    switch (role) {
      case 'ink': return ink.text(a ?? 1)
      case 'ink2': return ink.ghost(a ?? 0.5)
      case 'line': return ink.line(a ?? 0.12)
      case 'bg2': return ink.fill(a ?? 0.14)
      case 'accent': return a != null ? opacity(accent, a) : accent
      default: { const p = ink.isLight ? WHITE : grey(0.08); return a != null ? opacity(p, a) : p }
    }
  }
  const customSheetIsLight = (c) => baseSurface === 'light' ? true : baseSurface === 'dark' ? false : widgetInk(c).isLight
  const sheet = (role, light) => {
    let paper, inkC, accentC
    if (wc && light === customSheetIsLight(wc)) {
      paper = wc; inkC = widgetInk(wc).base; accentC = widgetAccent(t, wc)
    } else if (light) {
      if (t.duoLight && t.duoDark) { paper = mixed(t.duoLight, t.duoDark, t.duoFlipped ? 0.07 : 0); inkC = t.duoDark; accentC = t.duoDark }
      else { paper = hsb(t.backdropHue, 0.10, 0.97); inkC = hsb(t.backdropHue, 0.06, 0.11); accentC = onLightSurface(t.rawAccent) }
    } else { paper = t.plate; inkC = t.plateCream; accentC = t.rawAccent }
    switch (role) {
      case 'bg': return paper
      case 'bg2': return mixed(paper, inkC, 0.06)
      case 'ink': return inkC
      case 'ink2': return mixed(inkC, paper, 0.38)
      case 'accent': return accentC
      default: return opacity(inkC, 0.2)
    }
  }
  const role = (r, s) => s === 'light' ? sheet(r, true) : s === 'dark' ? sheet(r, false) : card(r, null)
  const color = (token, on) => {
    let name = token, alpha = null
    const at = token.lastIndexOf('@')
    if (at >= 0) { name = token.slice(0, at); const v = Number(token.slice(at + 1)); alpha = Number.isNaN(v) ? null : v }
    const explicit = SURFACES.has(on) ? on : null
    const s = explicit ?? baseSurface
    let c
    switch (name) {
      case 'white': c = WHITE; break
      case 'black': c = BLACK; break
      case 'clear': return CLEAR
      default:
        if (ROLES.has(name)) {
          if (s === 'card' || (explicit == null && noSheet)) return card(name, alpha)
          c = role(name, s)
        } else c = name.startsWith('#') ? parseHex(name) : CLEAR
    }
    return alpha != null ? opacity(c, alpha) : c
  }
  return { look, base: baseSurface, noSheet, color }
}
