// ฉากหลังของการ์ด (= `CardBackdrop` ใน theme/CardTheme.kt · Theme/Marble.swift · `SignatureCorner`)
//
// วาดผืนเดียวคลุมทั้งแผ่น (ทุกหน้าต่อกัน) ลง canvas — ทุกลายเป็นเรขาคณิตที่สุ่มด้วยเมล็ดคงที่ จึงได้ลายเดียวกับแอป

import { css, opacity, hsb, WHITE, BLACK } from './theme.js'

/** วาดฉากหลังลงในกล่อง `host` ขนาด w×h หน่วยออกแบบ */
export function paintBackdrop(host, t, w, h, opts = {}) {
  const density = opts.density ?? 2
  const c = document.createElement('canvas')
  c.width = Math.ceil(w * density); c.height = Math.ceil(h * density)
  c.style.cssText = `position:absolute;left:0;top:0;width:${w}px;height:${h}px`
  const g = c.getContext('2d')
  g.scale(density, density)
  const col = t.backdropColors, light = t.isLight
  const vertical = (a, b) => { const gr = g.createLinearGradient(0, 0, 0, h); gr.addColorStop(0, css(a)); gr.addColorStop(1, css(b)); g.fillStyle = gr; g.fillRect(0, 0, w, h) }
  const solid = (a) => { g.fillStyle = css(a); g.fillRect(0, 0, w, h) }
  switch (t.backdrop) {
    case 'gradient': vertical(col.top, col.bottom); orbs(g, t, 0.5, w, h, opts.pageW); break
    case 'grid': vertical(col.top, col.bottom); grid(g, css(opacity(WHITE, light ? 0.55 : 0.09)), w, h); orbs(g, t, 0.35, w, h, opts.pageW); break
    case 'stripe': solid(col.top); stripes(g, css(t.stripeInk), w, h); grain(g, 2400, light ? 0.05 : 0.09, light ? BLACK : WHITE, w, h); break
    case 'diamond': solid(col.top); diamonds(g, css(t.stripeInk), w, h); grain(g, 2400, light ? 0.05 : 0.09, light ? BLACK : WHITE, w, h); break
    case 'glow':
      if (light) { const gr = g.createLinearGradient(0, 0, w / 2, h); gr.addColorStop(0, css(col.top)); gr.addColorStop(1, css(col.bottom)); g.fillStyle = gr; g.fillRect(0, 0, w, h) }
      else solid(col.bottom)
      orbs(g, t, 1.0, w, h, opts.pageW); break
    case 'marble': {
      const gr = g.createLinearGradient(0, 0, w, h); gr.addColorStop(0, css(col.top)); gr.addColorStop(1, css(col.bottom))
      g.fillStyle = gr; g.fillRect(0, 0, w, h)
      marble(g, t, w, h)
      orbs(g, t, 0.24, w, h, opts.pageW); break
    }
    case 'photo': {
      solid(col.bottom)
      host.appendChild(c)
      if (opts.backgroundURL) {
        const img = document.createElement('img')
        img.src = opts.backgroundURL
        img.style.cssText = `position:absolute;left:0;top:0;width:${w}px;height:${h}px;object-fit:cover;`
          + (t.photoEffect === 'mono' ? 'filter:grayscale(1);' : t.photoEffect === 'blur' ? 'filter:blur(26px);' : '')
        host.appendChild(img)
        host.appendChild(Object.assign(document.createElement('div'), { style: `position:absolute;inset:0;background:${css(opacity(col.top, t.photoDim))}` }))
        host.appendChild(Object.assign(document.createElement('div'), { style: `position:absolute;inset:0;background:linear-gradient(transparent 50%, ${css(opacity(col.bottom, 0.5))})` }))
      }
      const o = document.createElement('canvas')
      o.width = c.width; o.height = c.height; o.style.cssText = c.style.cssText
      const og = o.getContext('2d'); og.scale(density, density)
      orbs(og, t, 0.35, w, h, opts.pageW)
      host.appendChild(o)
      return
    }
    default: solid(col.top)
  }
  host.appendChild(c)
}

/** ดวงแสงสองดวงต่อหน้า — ไล่เฉดวงกลมสามช่วง (บนกระดาษเบาลงมาก) */
function orbs(g, t, strength, w, h, pageW) {
  const k = t.isLight ? strength * 0.34 : strength
  const a = opacity(t.accent, 0.5 * k), b = opacity(t.accentSoft, 0.34 * k)
  // กลางของผืนทั้งแผ่น (ทุกหน้าต่อกัน) — แอปวาดฉากหลังครั้งเดียวคลุมทั้งสำรับ
  const cx = w / 2, cy = h / 2
  glow(g, a, cx - 140, cy - 240, 220, 140)
  glow(g, b, cx + 160, cy + 280, 190, 150)
}
function glow(g, c, x, y, radius, blur) {
  const outer = radius + blur, core = Math.max(0, radius - blur) / outer
  const gr = g.createRadialGradient(x, y, 0, x, y, outer)
  gr.addColorStop(0, css(c)); gr.addColorStop(core, css(c)); gr.addColorStop((core + 1) / 2, css(opacity(c, 0.45))); gr.addColorStop(1, css(opacity(c, 0)))
  g.fillStyle = gr
  g.beginPath(); g.arc(x, y, outer, 0, Math.PI * 2); g.fill()
}

function grid(g, line, w, h, step = 22) {
  g.strokeStyle = line; g.lineWidth = 0.8; g.beginPath()
  for (let x = 0; x <= w; x += step) { g.moveTo(x, 0); g.lineTo(x, h) }
  for (let y = 0; y <= h; y += step) { g.moveTo(0, y); g.lineTo(w, y) }
  g.stroke()
}
function stripes(g, band, w, h, bw = 15) {
  g.fillStyle = band
  for (let x = bw * 0.5; x < w; x += bw * 2) g.fillRect(x, 0, bw, h)
}
function diamonds(g, band, w, h, dw = 42) {
  const dh = dw * 1.75
  g.fillStyle = band; g.beginPath()
  for (let y = 0; y <= h + dh / 2; y += dh) for (let x = 0; x <= w + dw / 2; x += dw) {
    g.moveTo(x, y - dh / 2); g.lineTo(x + dw / 2, y); g.lineTo(x, y + dh / 2); g.lineTo(x - dw / 2, y); g.closePath()
  }
  g.fill()
}

/** เกล็ดกระดาษ — xorshift 64 บิตเมล็ดคงที่ (= `EdGrain`) */
function grain(g, count, op, tint, w, h) {
  const M = (1n << 64n) - 1n
  let seed = 0x9E3779B97F4A7C15n
  const rnd = () => {
    seed ^= (seed << 13n) & M; seed ^= seed >> 7n; seed ^= (seed << 17n) & M
    return Number(seed % 10000n) / 10000
  }
  for (let i = 0; i < count; i++) {
    const x = rnd() * w, y = rnd() * h, d = 0.6 + rnd() * 1.1
    const a = op * (0.4 + rnd() * 0.6)
    g.fillStyle = css(opacity(tint, a))
    g.beginPath(); g.ellipse(x + d / 2, y + d / 2, d / 2, d / 2, 0, 0, 7); g.fill()
  }
}

// MARK: - หินอ่อน (= MarbleSlab · MarbleVeins)

const U64 = (1n << 64n) - 1n
class Rng {
  constructor(seed) { this.s = (BigInt(seed) * 0x9E3779B97F4A7C15n) & U64 }
  next() {
    this.s = (this.s + 0x9E3779B97F4A7C15n) & U64
    let z = this.s
    z = ((z ^ (z >> 30n)) * 0xBF58476D1CE4E5B9n) & U64
    z = ((z ^ (z >> 27n)) * 0x94D049BB133111EBn) & U64
    return z ^ (z >> 31n)
  }
  d() { return Number(this.next() >> 11n) * (1 / 9007199254740992) }
  range(a, b) { return a + this.d() * (b - a) }
}
let slabCache = null
function slab() {
  if (slabCache) return slabCache
  const rng = new Rng(0xA17), veins = [], CH = 5
  const lean = -1.02
  const swell = (s) => Array.from({ length: CH }, () => 1 + rng.range(-s, s))
  const veil = (f) => Array.from({ length: CH }, () => rng.range(f, 1))
  const angle = (pts, i) => { const j = Math.min(i + 1, pts.length - 1), hh = j === i ? Math.max(0, i - 1) : i; return Math.atan2(pts[j][1] - pts[hh][1], pts[j][0] - pts[hh][0]) }
  const walk = (start, a0, steps, step, wobble) => {
    const pts = [start]
    let [px, py] = start, a = a0, drift = 0
    for (let i = 0; i < steps; i++) {
      drift = Math.max(-1, Math.min(1, drift + rng.range(-0.5, 0.5)))
      a += drift * wobble
      if (rng.d() < 0.22) a += rng.range(-0.34, 0.34)
      px += Math.cos(a) * step; py += Math.sin(a) * step
      pts.push([px, py])
      if (py < -0.3 || py > 1.3 || px < -0.4 || px > 1.4) return pts
    }
    return pts
  }
  const strand = (pts, lo, hi, off, sway) => {
    let d = off
    const out = []
    for (let i = lo; i <= hi; i++) {
      d += rng.range(-sway, sway)
      const a = angle(pts, i) + Math.PI / 2
      out.push([pts[i][0] + Math.cos(a) * d, pts[i][1] + Math.sin(a) * d])
    }
    return out
  }
  const bundle = (start, ln, [w0, w1], strands, steps, reach) => {
    const a = ln + rng.range(-0.22, 0.22)
    const spine = walk([start[0] + rng.range(-0.05, 0.05), start[1]], a, steps, reach, 0.055)
    veins.push({ pts: spine, width: rng.range(w0, w1), alpha: rng.range(0.6, 1), main: true, soft: true, swell: swell(0.32), veil: veil(0.12) })
    for (let s = 0; s < strands; s++) {
      const lo = Math.trunc(rng.range(0, 0.55) * (spine.length - 2))
      const hi = Math.min(spine.length - 1, lo + Math.trunc(rng.range(0.3, 1) * (spine.length - 1)))
      if (hi - lo <= 3) continue
      const pts = strand(spine, lo, hi, rng.range(-0.024, 0.024), 0.008)
      veins.push({ pts, width: rng.range(0.22, 0.62), alpha: rng.range(0.3, 0.8), main: false, soft: false, swell: swell(0.3), veil: veil(0.06) })
    }
    const nb = Math.trunc(rng.range(2, 3.99))
    for (let s = 0; s < nb; s++) {
      const i = Math.trunc(rng.range(0.1, 0.9) * (spine.length - 2))
      const side = rng.d() < 0.5 ? -1 : 1
      const a2 = angle(spine, i) + side * rng.range(0.3, 0.8)
      const b = walk(spine[i], a2, Math.trunc(rng.range(6, 16)), 0.026, 0.085)
      veins.push({ pts: b, width: rng.range(0.35, 0.7), alpha: rng.range(0.35, 0.7), main: false, soft: true, swell: swell(0.26), veil: veil(0.1) })
      for (let r = 0; r < 2; r++) {
        const pts = strand(b, 0, b.length - 1, rng.range(-0.022, 0.022), 0.008)
        veins.push({ pts, width: rng.range(0.2, 0.42), alpha: rng.range(0.25, 0.55), main: false, soft: false, swell: swell(0.24), veil: veil(0.06) })
      }
    }
  }
  for (let i = 0; ; i++) { const x0 = -0.3 + i * 0.22; if (x0 > 1.25) break; bundle([x0, 1.12], lean, [0.7, 1.4], 7, 46, 0.04) }
  for (let i = 0; ; i++) { const x0 = -0.1 + i * 0.4; if (x0 > 1.1) break; bundle([x0, 1.12], lean + 0.42, [0.45, 0.9], 5, 44, 0.038) }
  for (let i = 0; i < 12; i++) bundle([rng.range(-0.1, 1.1), rng.range(-0.05, 1.05)], lean + rng.range(-0.5, 0.5), [0.35, 0.8], 4, Math.trunc(rng.range(8, 18)), 0.03)
  const clouds = Array.from({ length: 20 }, () => ({ at: [rng.range(-0.15, 1.15), rng.range(-0.1, 1.1)], r: rng.range(0.05, 0.22), k: rng.range(0.25, 0.95), stretch: rng.range(1.5, 3.2), lean: lean + rng.range(-0.3, 0.3) }))
  const flecks = Array.from({ length: 60 }, () => ({ at: [rng.d(), rng.d()], r: rng.range(0.3, 1.1), k: rng.range(0.15, 0.5) }))
  slabCache = { veins, clouds, flecks }
  return slabCache
}

function marbleInk(t) {
  if (t.duoColors) return { vein: opacity(t.duoColors.ink, 0.28), bleed: opacity(t.duoColors.ink, 0.10) }
  const h = t.backdropHue
  if (t.activeInk === 'night') return { vein: opacity(WHITE, 0.26), bleed: opacity(WHITE, 0.07) }
  if (t.activeInk === 'paper') return { vein: opacity(hsb(h, 0.16, 0.42), 0.34), bleed: opacity(hsb(h, 0.13, 0.55), 0.22) }
  return { vein: opacity(hsb(h, 0.34, 0.34), 0.34), bleed: opacity(hsb(h, 0.34, 0.48), 0.24) }
}

function marble(g, t, w, h) {
  const s = slab(), { vein, bleed } = marbleInk(t)
  const k = Math.max(0.3, w / 402), b = k
  const layer = (blur, draw) => {
    g.save(); g.filter = `blur(${blur}px)`; draw(); g.restore()
  }
  const path = (pts) => {
    const p = pts.map(([x, y]) => [x * w, y * h])
    g.beginPath(); g.moveTo(p[0][0], p[0][1])
    if (p.length === 2) { g.lineTo(p[1][0], p[1][1]); return }
    for (let i = 1; i < p.length - 1; i++) g.quadraticCurveTo(p[i][0], p[i][1], (p[i][0] + p[i + 1][0]) / 2, (p[i][1] + p[i + 1][1]) / 2)
    g.lineTo(p[p.length - 1][0], p[p.length - 1][1])
  }
  const stroke = (v, kk, color, alpha) => {
    const n = v.pts.length
    if (n <= 2) return
    for (let c = 0; c < 5; c++) {
      const lo = Math.trunc(c * (n - 1) / 5), hi = Math.min(n - 1, Math.trunc((c + 1) * (n - 1) / 5) + 1)
      if (hi - lo < 1) continue
      const tt = (c + 0.5) / 5
      const taper = v.main ? 1 : Math.sin(Math.PI * tt) ** 0.5
      const fade = v.main ? 1 : 0.4 + 0.6 * Math.sin(Math.PI * tt) ** 0.6
      path(v.pts.slice(lo, hi + 1))
      g.strokeStyle = css(opacity(color, alpha * v.alpha * fade * v.veil[c]))
      g.lineWidth = Math.max(0.2, v.width * v.swell[c] * taper * kk)
      g.lineCap = 'round'; g.lineJoin = 'round'
      g.stroke()
    }
  }
  layer(17 * b, () => {
    for (const c of s.clouds) {
      const ww = c.r * 2 * w * c.stretch, hh = c.r * 2 * w
      g.save(); g.translate(c.at[0] * w, c.at[1] * h); g.rotate(c.lean)
      g.fillStyle = css(opacity(bleed, c.k)); g.beginPath(); g.ellipse(0, 0, ww / 2, hh / 2, 0, 0, 7); g.fill(); g.restore()
    }
  })
  layer(7 * b, () => { for (const v of s.veins) if (v.soft) stroke(v, k * (v.main ? 5 : 3), bleed, 0.9) })
  layer(1.6 * b, () => { for (const v of s.veins) stroke(v, k * 1.7, vein, 0.34) })
  layer(0.8 * b, () => {
    for (const v of s.veins) stroke(v, k * 0.8, vein, 0.55)
    for (const f of s.flecks) { g.fillStyle = css(opacity(vein, f.k)); g.beginPath(); g.ellipse(f.at[0] * w, f.at[1] * h, f.r * k, f.r * k, 0, 0, 7); g.fill() }
  })
}

/**
 * ลายเซ็นมุมขวาล่างของผืน (= `SignatureCorner`) — โลโก้ Sale Here ตัวใหญ่จาง ๆ เอียง −8° ไหลพ้นขอบนิดหนึ่ง
 * แอปวาดครั้งเดียวคลุมทั้งผืน (มุมขวาล่างของหน้าสุดท้าย)
 */
export function signatureCorner(host, t, w, h, base) {
  const ink = t.inkStyle
  const side = Math.min(w, h) * 0.68
  const alpha = t.isLight ? 0.07 : 0.17
  const url = `${base}icon/sh%3Awordmark`
  const d = document.createElement('div')
  d.style.cssText = `position:absolute;left:${w - side + side * 0.12}px;top:${h - side + side * 0.06}px;width:${side}px;height:${side}px;`
    + `transform-origin:100% 100%;transform:rotate(-8deg);opacity:${alpha};`
    + `background:linear-gradient(135deg, ${css(ink.base)}, ${css(opacity(ink.base, 0.35))});`
    + `-webkit-mask:url("${url}") center/contain no-repeat;mask:url("${url}") center/contain no-repeat;pointer-events:none`
  host.appendChild(d)
}
