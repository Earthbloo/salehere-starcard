// ไอคอนของผัง (= SpecIcons.kt · `SpecPainter.icon(_:)` ของ iOS · รายชื่อตาม WIDGET-SPEC.md §6)
//
// ไฟล์ภาพมาจาก asset ของแอปผ่าน `/card/icon/<ชื่อ>` · ของที่แอปวาดด้วยโค้ด (ตรา · คลิป · ประกาย …) วาดเป็น SVG ที่นี่
// tint = สีที่แปลงแล้ว (rgba) · ไม่ส่ง = คงสีต้นฉบับของไฟล์ (โลโก้แบรนด์)

import { css, opacity, grey, WHITE, BLACK, mixed, rgb } from './theme.js'
import { shapePath } from './spec-shapes.js'

const NS = 'http://www.w3.org/2000/svg'
export const RED = rgb(0xDA / 255, 0x38 / 255, 0x32 / 255)
const GREEN = rgb(0.13, 0.70, 0.40)
const GOLD = rgb(1.0, 0.76, 0.2)
let uid = 0

export function el(tag, style = '', html = '') {
  const e = document.createElement(tag)
  if (style) e.style.cssText = style
  if (html) e.innerHTML = html
  return e
}
function svg(w, h, body, style = '') {
  const s = document.createElementNS(NS, 'svg')
  s.setAttribute('width', w); s.setAttribute('height', h)
  s.setAttribute('viewBox', `0 0 ${w} ${h}`)
  s.style.cssText = `position:absolute;left:0;top:0;overflow:visible;${style}`
  s.innerHTML = body
  return s
}

/** ภาพจากไฟล์ asset — ย้อมสีด้วย mask เมื่อมี tint (= `FitIcon`) */
export function assetIcon(name, w, h, tint, base) {
  const url = `${base}icon/${encodeURIComponent(name)}`
  if (tint) {
    return el('div', `position:absolute;inset:0;background:${tint};-webkit-mask:url("${url}") center/contain no-repeat;mask:url("${url}") center/contain no-repeat`)
  }
  const img = el('img', 'position:absolute;inset:0;width:100%;height:100%;object-fit:contain')
  img.src = url
  img.onerror = () => { img.style.display = 'none' }
  return img
}

/** โลโก้จากเน็ต (= `RemoteLogo`) — เต็มกรอบแบบ fit */
function remote(url) {
  const img = el('img', 'position:absolute;inset:0;width:100%;height:100%;object-fit:contain')
  img.src = url; img.referrerPolicy = 'no-referrer'
  img.onerror = () => { img.style.display = 'none' }
  return img
}

// MARK: - ตรา

const sealPath = (d, x = 0, y = 0) => {
  let p = ''
  const cx = x + d / 2, cy = y + d / 2, r0 = d / 2
  for (let i = 0; i <= 224; i++) {
    const t = i / 224 * 2 * Math.PI, r = r0 * (1 - 0.075 + 0.075 * Math.cos(8 * t))
    p += `${i ? 'L' : 'M'}${(cx + r * Math.cos(t)).toFixed(2)} ${(cy + r * Math.sin(t)).toFixed(2)}`
  }
  return p + 'Z'
}
const checkPath = (w, h, x, y) => `M${x} ${y + h * 0.55}L${x + w * 0.36} ${y + h}L${x + w} ${y}`

/** เหรียญรับรองแปดกลีบ (= `VerifiedSeal`) — หมึกสีเดียว · เครื่องหมายถูกเจาะด้วยสีพื้น */
export function verifiedSeal(d, punch, tint, compact) {
  const id = `vs${uid++}`
  let body = `<path d="${sealPath(d)}" fill="${tint}"/>`
  if (!compact) {
    body = `<defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.22"/><stop offset="1" stop-color="#000" stop-opacity="0.10"/></linearGradient></defs>`
      + body + `<path d="${sealPath(d)}" fill="url(#${id})"/>`
      + `<path d="${sealPath(d * 0.8, d * 0.1, d * 0.1)}" fill="none" stroke="${punch}" stroke-opacity="0.45" stroke-width="0.7" stroke-dasharray="1.2 2.4"/>`
  }
  const cw = d * 0.44, ch = d * 0.34
  body += `<path d="${checkPath(cw, ch, (d - cw) / 2, (d - ch) / 2)}" fill="none" stroke="${punch}" stroke-width="${d * 0.105}" stroke-linecap="round" stroke-linejoin="round"/>`
  return svg(d, d, body, compact ? '' : 'filter:drop-shadow(0 0 6px rgba(0,0,0,0.3))')
}

/** ตราวงกลมแดงของ Sale Here (= `SaleHereMark`) */
export function saleHereMark(size, base) {
  const w = el('div', `position:relative;flex:none;width:${size}px;height:${size}px;border-radius:50%;background:${css(RED)}`)
  const inner = el('div', `position:absolute;left:${size * 0.21}px;top:${size * 0.21}px;width:${size * 0.58}px;height:${size * 0.58}px`)
  inner.appendChild(assetIcon('sh:wordmark', size * 0.58, size * 0.58, '#fff', base))
  w.appendChild(inner)
  return w
}

/** ดาวหยักสิบกลีบของติ๊กแดง (= `sealPath` ใน SaleHereByline.kt) */
function lobedSeal(s) {
  const c = s / 2, outer = s / 2, inner = outer * 0.8, step = 2 * Math.PI / 10
  const pt = (r, a) => `${(c + r * Math.cos(a)).toFixed(2)} ${(c + r * Math.sin(a)).toFixed(2)}`
  let p = ''
  for (let i = 0; i < 10; i++) {
    const a = i * step - Math.PI / 2
    if (i === 0) p += `M${pt(inner, a)}`
    p += `Q${pt(outer * 1.12, a + step / 2)} ${pt(inner, a + step)}`
  }
  return p + 'Z'
}

const FONT = '"SC Noto"'
/** "Verified by Sale Here" ของ widget (= `SaleHereByline`) */
export function byline(tint, size, tone, base) {
  const text = tone === 'dark' ? 'rgba(255,255,255,0.92)' : tone === 'light' ? css(opacity(grey(0.1), 0.85)) : tint
  const fill = tone === 'dark' ? 'rgba(0,0,0,0.38)' : tone === 'light' ? 'rgba(255,255,255,0.92)' : `color-mix(in srgb, ${tint} 12%, transparent)`
  const stroke = tone === 'dark' ? 'rgba(255,255,255,0.22)' : tone === 'light' ? 'rgba(0,0,0,0.08)' : `color-mix(in srgb, ${tint} 20%, transparent)`
  const row = el('div', `display:inline-flex;align-items:center;gap:${size * 0.38}px;white-space:nowrap;border-radius:999px;background:${fill};box-shadow:inset 0 0 0 0.5px ${stroke};padding:${size * 0.26}px ${size * 0.3}px ${size * 0.26}px ${size * 0.42}px`)
  const s = size * 1.45
  const seal = el('div', `position:relative;flex:none;width:${s}px;height:${s}px`)
  seal.appendChild(svg(s, s, `<path d="${lobedSeal(s)}" fill="${css(RED)}"/>`))
  const ck = el('div', `position:absolute;left:${(s - size * 0.78) / 2}px;top:${(s - size * 0.78) / 2}px;width:${size * 0.78}px;height:${size * 0.78}px`)
  ck.appendChild(assetIcon('ph:check', size * 0.78, size * 0.78, '#fff', base))
  seal.appendChild(ck)
  row.appendChild(seal)
  row.appendChild(el('span', `font:600 ${size}px/1 ${FONT};color:${text}`, 'Verified by'))
  row.appendChild(saleHereMark(size * 1.7, base))
  return row
}

/** ป้าย "Verified by" + ตราแดง (= `VerifiedBadge` · ใบที่ได้ป้าย Sale Here แล้วใช้ `byline` แทน) */
function verifiedBadge(ink, stamped, base) {
  if (stamped) return byline(css(ink.text(0.82)), 8.5, 'ink', base)
  const row = el('div', `display:inline-flex;align-items:center;gap:5px;white-space:nowrap;border-radius:999px;background:${css(ink.fill(0.16))};box-shadow:inset 0 0 0 0.5px ${css(ink.line(0.22))};padding:3px 4px 3px 8px`)
  row.appendChild(el('span', `font:600 8px/1 ${FONT};color:${css(ink.text(0.92))}`, 'Verified by'))
  row.appendChild(saleHereMark(14, base))
  return row
}

/** ป้ายที่มาของตัวเลข (= `ProvenanceTag`) */
function provenance(kind, ink, onPhoto, base) {
  if (kind.type === 'connected') {
    const fg = onPhoto ? 'rgba(255,255,255,0.92)' : css(ink.text(0.86))
    const row = el('div', `display:inline-flex;align-items:center;gap:4px;white-space:nowrap;border-radius:999px;background:${onPhoto ? 'rgba(0,0,0,0.34)' : css(ink.fill(0.12))};box-shadow:inset 0 0 0 0.5px ${onPhoto ? 'rgba(255,255,255,0.22)' : css(ink.line(0.16))};padding:2.5px 7px 2.5px 3px`)
    const seal = el('div', 'position:relative;flex:none;width:11px;height:11px')
    seal.appendChild(verifiedSeal(11, css(onPhoto || !ink.isLight ? grey(0.12) : grey(0.97)), onPhoto ? '#fff' : css(ink.text(0.86)), true))
    row.appendChild(seal)
    const ago = /\d/.test(kind.ago) ? `<span style="font-size:8px;font-weight:500"> · ${kind.ago}</span>` : ''
    row.appendChild(el('span', `font:700 8.5px/1.4 ${FONT};color:${fg}`, `Verified${ago}`))
    return row
  }
  const fg = onPhoto ? 'rgba(255,255,255,0.8)' : css(ink.text(0.62))
  const row = el('div', `display:inline-flex;align-items:center;gap:4px;white-space:nowrap;border-radius:999px;background:${onPhoto ? 'rgba(0,0,0,0.3)' : css(ink.fill(0.10))};box-shadow:inset 0 0 0 0.5px ${onPhoto ? 'rgba(255,255,255,0.18)' : css(ink.line(0.14))};padding:2.5px 6px`)
  const lead = {
    manual: () => { const d = el('div', 'position:relative;width:7.5px;height:7.5px;flex:none'); d.appendChild(assetIcon('ph:clock', 7.5, 7.5, fg, base)); return d },
    profile: () => { const d = el('div', 'position:relative;width:7px;height:7px;flex:none'); d.appendChild(assetIcon('ph:star-fill', 7, 7, css(GOLD), base)); return d },
    screenshot: () => { const d = el('div', 'position:relative;width:7.5px;height:7.5px;flex:none'); d.appendChild(assetIcon('ph:camera', 7.5, 7.5, fg, base)); return d },
    verified: () => saleHereMark(9, base),
  }[kind.type]
  if (lead) row.appendChild(lead())
  row.appendChild(el('span', `font:600 8px/1.4 ${FONT};color:${fg}`, kind.label))
  return row
}

// MARK: - ของตกแต่ง

const PAPERCLIP = (s) => {
  const P = (x, y) => `${(x * s).toFixed(2)} ${(y * s).toFixed(2)}`
  return `M${P(20, 22)}L${P(20, 62)}A${7 * s} ${7 * s} 0 0 1 ${P(6, 62)}L${P(6, 14)}A${10 * s} ${10 * s} 0 0 1 ${P(26, 14)}L${P(26, 58)}`
}

function sparkPath(w, h) {
  const cx = w / 2, cy = h / 2, a = w / 2, b = h / 2, k = 0.16
  const P = (x, y) => `${x.toFixed(2)} ${y.toFixed(2)}`
  return `M${P(cx, cy - b)}Q${P(cx + a * k, cy - b * k)} ${P(cx + a, cy)}Q${P(cx + a * k, cy + b * k)} ${P(cx, cy + b)}Q${P(cx - a * k, cy + b * k)} ${P(cx - a, cy)}Q${P(cx - a * k, cy - b * k)} ${P(cx, cy - b)}Z`
}

function qr(text, tint, w, h) {
  const box = el('div', 'position:absolute;inset:0;display:flex;align-items:center;justify-content:center')
  const side = Math.min(w, h)
  const gen = globalThis.qrcode
  if (!gen) return box
  const q = gen(0, 'M'); q.addData(text); q.make()
  const n = q.getModuleCount(), m = 1, total = n + m * 2
  let d = ''
  for (let r = 0; r < n; r++) for (let c = 0; c < n; c++) if (q.isDark(r, c)) d += `M${c + m} ${r + m}h1v1h-1z`
  const s = svg(total, total, `<path d="${d}" fill="${tint}" shape-rendering="crispEdges"/>`, `position:static;width:${side}px;height:${side}px`)
  box.appendChild(s)
  return box
}

/**
 * ไอคอนหนึ่งตัว (= `SpecIcon`)
 * o = { name, w, h, tint (css|null), text, size, ink, accent (css), stamped, handle, provenance, scrap, base }
 */
export function specIcon(o) {
  const { name, w, h, tint, ink } = o
  const inkC = css(ink.text(1))
  const accentC = o.accent ?? inkC
  const m = Math.min(w, h)
  const punch = css(ink.isLight ? WHITE : grey(0.10))
  const box = el('div', `position:absolute;left:0;top:0;width:${w}px;height:${h}px;display:flex;align-items:center;justify-content:center`)
  const put = (c) => { box.appendChild(c); return box }
  switch (name) {
    case 'qr': return put(qr(`https://salehere.co.th/star/${o.handle || ''}`, tint ?? inkC, w, h))
    case 'provenance': case 'provenance:profile': return put(provenance({ type: 'profile', label: 'จากโปรไฟล์ STAR' }, ink, false, o.base))
    case 'provenance:socials': case 'provenance:photo': return put(provenance(o.provenance, ink, name === 'provenance:photo', o.base))
    case 'provenance:screenshot': return put(provenance({ type: 'screenshot', label: 'จากสกรีนช็อต · 12 ก.ย.' }, ink, false, o.base))
    case 'byline': case 'byline:dark': case 'byline:light':
      return put(byline(tint ?? css(ink.text(0.9)), Math.max(6, h * 0.45), name === 'byline:dark' ? 'dark' : name === 'byline:light' ? 'light' : 'ink', o.base))
    case 'verifiedBadge': return put(verifiedBadge(ink, o.stamped, o.base))
    case 'verifiedSeal': { const d = el('div', `position:relative;width:${m}px;height:${m}px`); d.appendChild(verifiedSeal(m, punch, tint ?? inkC, false)); return put(d) }
    case 'starSeal': {
      const r = m * 0.68 * 2
      const d = el('div', `position:relative;width:${r}px;height:${r}px;filter:drop-shadow(0 0 ${m * 0.12}px rgba(0,0,0,0.35))`)
      d.appendChild(verifiedSeal(r, punch, tint ?? accentC, true)); return put(d)
    }
    case 'guilloche': {
      const c = tint ?? css(ink.text(0.2))
      const cx = w / 2, cy = h / 2, r0 = Math.min(w, h) / 2
      let body = ''
      for (const [n, amp, base, count] of [[16, 0.115, 0.86, 16], [9, 0.10, 0.60, 12]]) {
        for (let k = 0; k < count; k++) {
          const phi = k / count * 2 * Math.PI / n
          let d = ''
          for (let i = 0; i <= 420; i++) {
            const t = i / 420 * 2 * Math.PI, r = r0 * (base + amp * Math.sin(n * (t + phi)))
            d += `${i ? 'L' : 'M'}${(cx + r * Math.cos(t)).toFixed(2)} ${(cy + r * Math.sin(t)).toFixed(2)}`
          }
          body += `<path d="${d}Z" fill="none" stroke="${c}" stroke-width="0.5"/>`
        }
      }
      return put(svg(w, h, body))
    }
    case 'ringText': {
      const size = o.size ?? 7, r = m / 2 - size, chars = [...(o.text || '')]
      const c = tint ?? inkC
      const body = chars.map((ch, i) => `<text x="${w / 2}" y="${h / 2 - r}" text-anchor="middle" dominant-baseline="central" transform="rotate(${i / chars.length * 360} ${w / 2} ${h / 2})" font-family="ui-monospace, Menlo, monospace" font-weight="700" font-size="${size}" fill="${c}">${ch.replace(/[<&]/g, (x) => (x === '<' ? '&lt;' : '&amp;'))}</text>`).join('')
      return put(svg(w, h, body))
    }
    case 'washi': {
      const stripe = o.scrap?.band ?? WHITE
      let body = ''
      let odd = false
      for (let x = 0; x < w; x += 4.5) { body += `<rect x="${x}" y="0" width="4.5" height="${h}" fill="${odd ? css(opacity(stripe, 0.62)) : (tint ? `color-mix(in srgb, ${tint} 72%, transparent)` : 'rgba(255,255,255,0.72)')}"/>`; odd = !odd }
      return put(svg(w, h, body, 'filter:drop-shadow(0 0 1px rgba(0,0,0,0.14))'))
    }
    case 'binderClip': {
      const s = w / 68, P = (x, y) => `${x * s} ${y * s}`
      const body = `<path d="M${P(20, 36)}L${P(25, 8)}Q${P(34, 1)} ${P(43, 8)}L${P(48, 36)}" fill="none" stroke="#C3C7CF" stroke-width="${3.2 * s}" stroke-linecap="round"/>`
        + `<path d="M${P(26, 36)}L${P(29, 14)}Q${P(34, 10)} ${P(39, 14)}L${P(42, 36)}" fill="none" stroke="#9EA3AC" stroke-width="${2.4 * s}" stroke-linecap="round"/>`
        + `<path d="M${P(8, 34)}L${P(60, 34)}L${P(56, 62)}L${P(12, 62)}Z" fill="#161616"/>`
        + `<path d="M${P(12, 38)}L${P(56, 38)}" stroke="#4A4A4A" stroke-width="${2 * s}"/>`
      const d = el('div', `position:absolute;left:0;top:0;width:${w}px;height:${w * 66 / 68}px;filter:drop-shadow(0 0 2px rgba(0,0,0,0.18))`)
      d.appendChild(svg(w, w * 66 / 68, body)); return put(d)
    }
    case 'paperClip': {
      const s = w / 30
      return put(svg(w, h, `<path d="${PAPERCLIP(s)}" fill="none" stroke="${tint ?? css(ink.text(0.6))}" stroke-width="1.6"/>`))
    }
    case 'barcode': {
      const bars = [3, 1, 1, 2, 4, 1, 2, 3, 1, 1, 3, 2, 1, 4, 1, 2, 2, 1, 3, 1, 1, 2, 4, 1, 2, 1, 3]
      const unit = w / bars.reduce((a, b) => a + b, 0)
      let x = 0, body = ''
      bars.forEach((b, i) => { if (i % 2 === 0) body += `<rect x="${x}" y="0" width="${b * unit}" height="${h}" fill="${tint ?? inkC}"/>`; x += b * unit })
      return put(svg(w, h, body))
    }
    case 'bow': {
      const tone = o.scrap, color = tone ? tone.band : WHITE, edge = tone ? tone.paperAccent : grey(0.6)
      const s = w / 64, P = (x, y) => `${x * s} ${y * s}`
      const loop = (dir) => `M${P(32, 20)}C${P(32 - 8 * dir, 6)} ${P(32 - 26 * dir, 4)} ${P(32 - 26 * dir, 16)}C${P(32 - 26 * dir, 28)} ${P(32 - 8 * dir, 28)} ${P(32, 20)}`
      const body = `<path d="M${P(29, 22)}L${P(19, 44)}L${P(26, 41)}L${P(30, 47)}ZM${P(35, 22)}L${P(45, 44)}L${P(38, 41)}L${P(34, 47)}Z" fill="${css(mixed(color, edge, 0.3))}"/>`
        + [1, -1].map((d) => `<path d="${loop(d)}" fill="${css(color)}" stroke="${css(edge)}" stroke-width="${1.6 * s}"/>`).join('')
        + `<ellipse cx="${32 * s}" cy="${21 * s}" rx="${5 * s}" ry="${5 * s}" fill="${css(edge)}"/>`
      return put(svg(w, w * 0.75, body, `position:absolute;left:0;top:${(h - w * 0.75) / 2}px`))
    }
    case 'spark': return put(svg(m, m, `<path d="${sparkPath(m, m)}" fill="${tint ?? '#fff'}"/>`, `position:static`))
    case 'windowDots': {
      const t = o.scrap
      const row = el('div', 'display:flex;gap:4px;width:26px;height:6px')
      for (const c of t ? [t.paperAccent, t.mid, t.band] : [grey(0.7), grey(0.6), grey(0.5)]) row.appendChild(el('div', `width:6px;height:6px;border-radius:50%;background:${css(c)}`))
      return put(row)
    }
    case 'embossedLockup': {
      const lh = h, lw = lh * 34 / 24
      const wrap = el('div', `position:relative;width:${lw}px;height:${lh}px`)
      const light = ink.isLight
      const depth = Math.max(0.6, lh * 0.03)
      // แสงบนซ้าย + เงาล่างขวา แล้วเจาะเนื้อตราออก (= DstOut) — เว็บใช้ mask ซ้อนแทน
      const url = `${o.base}icon/sh%3Astar`
      const layer = (color, dx, dy) => el('div', `position:absolute;left:${dx}px;top:${dy}px;width:${lw}px;height:${lh}px;background:${color};-webkit-mask:url("${url}") center/contain no-repeat;mask:url("${url}") center/contain no-repeat`)
      const shade = el('div', `position:absolute;inset:0;-webkit-mask:url("${url}") center/contain no-repeat exclude, linear-gradient(#000,#000);mask:url("${url}") center/contain no-repeat exclude, linear-gradient(#000,#000)`)
      shade.appendChild(layer(light ? 'rgba(255,255,255,0.72)' : 'rgba(255,255,255,0.42)', -depth, -depth))
      shade.appendChild(layer(light ? 'rgba(0,0,0,0.36)' : 'rgba(0,0,0,0.62)', depth, depth * 1.15))
      wrap.appendChild(shade)
      wrap.appendChild(layer(light ? 'rgba(0,0,0,0.045)' : 'rgba(255,255,255,0.06)', 0, 0))
      return put(wrap)
    }
    case 'starLockup': {
      const lh = h, lw = lh * 34 / 24
      const d = el('div', `position:relative;width:${lw}px;height:${lh}px;flex:none`)
      d.appendChild(assetIcon('sh:star', lw, lh, tint ?? accentC, o.base)); return put(d)
    }
    case 'saleHereStar': return put(assetIcon('sh:star', w, h, tint ?? inkC, o.base))
    default:
      if (name.startsWith('url:')) return put(remote(name.slice(4)))
      if (name.startsWith('http')) return put(remote(name))
      if (name.startsWith('ph:')) {
        const d = el('div', `position:relative;width:${m}px;height:${m}px`)
        d.appendChild(assetIcon(name, m, m, tint ?? inkC, o.base)); return put(d)
      }
      if (name) return put(assetIcon(name, w, h, tint, o.base))
      return box
  }
}

export { GREEN, GOLD, BLACK }
export { shapePath }
