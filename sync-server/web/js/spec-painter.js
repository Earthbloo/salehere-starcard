// ตัววาดผัง (เว็บ) (= Views/Widgets/SpecPainter.swift · ui/widgets/SpecPainter.kt)
//
// รู้จักของไม่กี่อย่าง — กล่องมุมมน · เส้น · ไล่สี · ลาย · ข้อความ · รูป · ไอคอน — และ **ไม่ตัดสินใจอะไรเอง**
// ตำแหน่ง/ขนาด/ขนาดตัวอักษร/จำนวนบรรทัด มาจาก `SpecSolver` ทั้งหมด · ข้อความวาดเฉพาะบรรทัดที่ตัววัดตัดไว้
//
// ctx = { color(token, on, item) → css (on = พื้นของโหนด · §4), photo(slot, item) → {url, fit}, measurer, fontCSS, base, icon(o) → element,
//         platePattern ('plain'|'stripe'|'diamond'), mixed(css,…) }

import { shapePath, drawPattern, drawPlatePattern, makeCanvas } from './spec-shapes.js'
import { el } from './spec-icons.js'

const NS = 'http://www.w3.org/2000/svg'
let uid = 0

/** ต้นไม้จากรายการกล่องแบน — ลูกของ `r/0` คือ `r/0/<n>` และ `r/0/c<n>` */
function tree(boxes) {
  const kids = new Map()
  let root = null
  for (const b of boxes) {
    if (b.id === 'r') { root = b; continue }
    const cut = b.id.lastIndexOf('/')
    const p = b.id.slice(0, cut)
    if (!kids.has(p)) kids.set(p, [])
    kids.get(p).push(b)
  }
  return { root, kids }
}

const corner = (n, w, h) => (n.circle ? Math.min(w, h) / 2 : n.radius ?? 0)
const rotation = (n, item) => (n.rotateCycle?.length && item ? n.rotateCycle[item.i % n.rotateCycle.length] : n.rotate ?? 0)
const cssPath = (d) => `path("${d}")`

/** วาดทั้งใบลงใน `host` — ผังวางใน box/k แล้วย่อทั้งก้อนด้วย k */
export function paintWidget(host, boxes, k, ctx) {
  const { root, kids } = tree(boxes)
  if (!root) return
  const wrap = el('div', `position:absolute;left:0;top:0;width:${root.frame.width}px;height:${root.frame.height}px;transform-origin:0 0;transform:scale(${k})`)
  wrap.appendChild(node(root, kids, root.frame, ctx))
  host.appendChild(wrap)
}

function node(b, kids, parent, ctx) {
  const n = b.node, f = b.frame
  const d = el('div', `position:absolute;left:${f.x - parent.x}px;top:${f.y - parent.y}px;width:${f.width}px;height:${f.height}px`)
  const rot = rotation(n, b.item)
  if (rot) d.style.transform = `rotate(${rot}deg)`
  if (n.opacity != null && n.opacity !== 1) d.style.opacity = n.opacity
  if (n.clip) {
    if (n.shape) d.style.clipPath = cssPath(shapePath(n.shape, f.width, f.height, corner(n, f.width, f.height)))
    else { d.style.overflow = 'hidden'; d.style.borderRadius = `${corner(n, f.width, f.height)}px` }
  }
  paint(d, b, ctx)
  for (const c of kids.get(b.id) || []) d.appendChild(node(c, kids, f, ctx))
  return d
}

function paint(d, b, ctx) {
  const n = b.node
  switch (n.type) {
    case 'text': return text(d, b, ctx)
    case 'image': return image(d, b, ctx)
    case 'icon': return icon(d, b, ctx)
    case 'line': return background(d, n, b.item, b.frame, ctx, 'ink@0.12')
    default: return background(d, n, b.item, b.frame, ctx, null)
  }
}

// MARK: - พื้น · ไล่สี · ลาย · เส้น · เงา

function background(d, n, item, f, ctx, defaultFill) {
  const w = f.width, h = f.height
  const cyc = n.fillCycle?.length && item ? n.fillCycle[item.i % n.fillCycle.length] : null
  const fill = cyc ?? n.fill ?? defaultFill
  const g = n.gradient, s = n.stroke, pat = n.pattern, pp = n.platePattern
  if (!fill && !g && !s && !pat && !pp) return
  const r = corner(n, w, h)
  const path = shapePath(n.shape, w, h, r)
  const layer = el('div', 'position:absolute;inset:0;pointer-events:none')
  // ลายแผ่นของถาด — เฉดเข้มของแผ่นเอง ตัดตามรูปร่าง · แผ่นใสไม่วาด
  if (pp && ctx.platePattern && ctx.platePattern !== 'plain') {
    const sheet = ctx.colorObj(pp, n.on, item)
    if (sheet.a > 0.002) {
      const band = ctx.css(ctx.mixDark(sheet))
      const c = makeCanvas(w, h, (x) => drawPlatePattern(x, ctx.platePattern, band, w, h))
      c.style.clipPath = cssPath(path)
      layer.appendChild(c)
    }
  }
  const svg = document.createElementNS(NS, 'svg')
  svg.setAttribute('width', w); svg.setAttribute('height', h); svg.setAttribute('viewBox', `0 0 ${w} ${h}`)
  svg.style.cssText = 'position:absolute;left:0;top:0;overflow:visible'
  let body = '', defs = ''
  if (g) {
    const id = `gr${uid++}`
    const a = g.angle * Math.PI / 180, dx = Math.cos(a), dy = Math.sin(a)
    defs += `<linearGradient id="${id}" gradientUnits="userSpaceOnUse" x1="${w * (0.5 - dx / 2)}" y1="${h * (0.5 - dy / 2)}" x2="${w * (0.5 + dx / 2)}" y2="${h * (0.5 + dy / 2)}">`
      + `<stop offset="0" stop-color="${ctx.color(g.from, n.on, item)}"/><stop offset="1" stop-color="${ctx.color(g.to, n.on, item)}"/></linearGradient>`
    body += `<path d="${path}" fill="url(#${id})"/>`
  } else if (fill) {
    body += `<path d="${path}" fill="${ctx.color(fill, n.on, item)}"/>`
  }
  if (s) {
    const id = `cl${uid++}`
    defs += `<clipPath id="${id}"><path d="${path}"/></clipPath>`
    // เส้นขอบด้านใน — ไม่มี dash: หนา 2× แล้วตัด (= iOS) · มี dash: หนาตามจริงแล้วตัด
    body += `<path d="${path}" fill="none" stroke="${ctx.color(s.color, n.on, item)}" stroke-width="${s.dash ? s.width : s.width * 2}" clip-path="url(#${id})"${s.dash ? ` stroke-dasharray="${s.dash.join(' ')}"` : ''}/>`
  }
  svg.innerHTML = `<defs>${defs}</defs>${body}`
  if (n.shadow) {
    const c = ctx.color(n.shadow.color, n.on, item)
    svg.style.filter = `drop-shadow(${n.shadow.x ?? 0}px ${n.shadow.y ?? 0}px ${n.shadow.sigma * 2}px ${c})`
  }
  layer.appendChild(svg)
  if (pat) {
    const c1 = ctx.color(pat.color, n.on, item), c2 = ctx.color(pat.color2 ?? pat.color, n.on, item)
    const c = makeCanvas(w, h, (x) => drawPattern(x, pat, c1, c2, w, h))
    c.style.clipPath = cssPath(path)
    // ลายทับบน fill แต่ใต้เส้นขอบ — วาดเส้นขอบซ้ำเหนือลาย
    layer.insertBefore(c, svg.nextSibling)
    if (s) { const top = svg.cloneNode(true); top.style.filter = ''; top.querySelectorAll('path:not([stroke])').forEach((p) => p.remove()); layer.appendChild(top) }
  }
  d.appendChild(layer)
}

// MARK: - ข้อความ

function text(d, b, ctx) {
  const n = b.node, r = b.text
  if (!r) return
  const face = n.face
  const font = { face: face ?? 'noto', size: r.size, weight: n.weight ?? 400, tracking: n.tracking ?? 0, kerning: n.kerning ?? 0,
    italic: n.italic ?? false, lineHeight: n.lineHeight ?? 1 }
  const col = ctx.color(n.color ?? 'ink', n.on, b.item)
  const one = ctx.measurer.lineHeight({ ...font, lineHeight: 1 })
  // ระยะบรรทัดเพิ่ม = ความสูงบรรทัดของฟอนต์ × (lineHeight − 1) (= `lineSpacing` ของ iOS)
  const spacing = n.lineHeight != null && n.lineHeight !== 1
    ? ctx.measurer.lineHeight({ face: n.face ?? 'body', size: r.size, weight: n.weight ?? 400 }) * (n.lineHeight - 1) : 0
  const fc = ctx.fontCSS(font.face, font.weight, font.italic)
  const align = n.textAlign === 'center' ? 'center' : n.textAlign === 'right' ? 'right' : 'left'
  const t = el('div', `position:absolute;left:0;top:${-spacing / 2}px;width:100%;white-space:pre;text-align:${align};color:${col};`
    + `font-family:${fc.family};font-weight:${fc.weight};font-style:${fc.style};font-size:${r.size}px;line-height:${one + spacing}px;`
    + `letter-spacing:${font.tracking + font.kerning}px;font-kerning:normal;font-synthesis:none`)
  if (n.shadow) {
    const c = ctx.color(n.shadow.color, n.on, b.item)
    t.style.textShadow = `${n.shadow.x ?? 0}px ${n.shadow.y ?? 0}px ${n.shadow.sigma * 2}px ${c}`
  }
  if (n.mixHead && r.string.trim().includes(' ')) {
    mixedHead(t, n, r, font, ctx, b.frame.width)
  } else {
    const shown = n.textCase === 'upper' ? r.string.toUpperCase() : r.string
    t.textContent = ctx.measurer.displayLines(shown, font, b.frame.width, Math.max(1, r.lines)).join('\n')
  }
  d.appendChild(t)
}

/** พาดหัวสองเสียง: คำแรกตามฟอนต์ของโหนด · ที่เหลือ noto บางเอียง ×1.04 · ย่อทั้งก้อนได้ถึงครึ่ง */
function mixedHead(t, n, r, font, ctx, width) {
  const s = r.string.trim()
  const i = s.search(/ +/)
  const head = s.slice(0, i), tail = s.slice(i).trim()
  const tailFace = 'noto'
  const measure = (size) => ctx.measurer.width(head, { ...font, size, tracking: 0 }) + ((n.kerning ?? 0) * [...head].length)
    + ctx.measurer.width(' ' + tail, { face: tailFace, size: size * 1.04, weight: 300, italic: true })
  let size = r.size
  while (size > r.size * 0.5 && measure(size) > width + 0.01) size -= 0.5
  const hf = ctx.fontCSS(font.face, font.weight, false), tf = ctx.fontCSS(tailFace, 300, true)
  t.style.letterSpacing = '0'
  t.innerHTML = ''
  const a = document.createElement('span'); a.textContent = head
  a.style.cssText = `font-family:${hf.family};font-weight:${hf.weight};font-size:${size}px;letter-spacing:${n.kerning ?? 0}px`
  const bb = document.createElement('span'); bb.textContent = ' ' + tail
  bb.style.cssText = `font-family:${tf.family};font-weight:${tf.weight};font-style:italic;font-size:${size * 1.04}px`
  t.append(a, bb)
}

// MARK: - รูป

function image(d, b, ctx) {
  const n = b.node, f = b.frame, item = b.item
  const ref = n.photoRef
  const asInt = (v) => (v != null && /^-?\d+$/.test(String(v)) ? Number(v) : null)
  const slot = (ref != null ? (ref.startsWith('$') ? asInt(item?.value(ref.slice(1))) : asInt(ref)) : null)
    ?? n.photo ?? asInt(item?.value('photo')) ?? 0
  const src = n.src ? (n.src.startsWith('$') ? (item?.value(n.src.slice(1)) ?? '') : n.src) : ''
  const r = corner(n, f.width, f.height)
  const outer = el('div', 'position:absolute;inset:0')
  if (n.shadow) outer.style.filter = `drop-shadow(${n.shadow.x ?? 0}px ${n.shadow.y ?? 0}px ${n.shadow.sigma * 2}px ${ctx.color(n.shadow.color, n.on)})`
  const clip = el('div', `position:absolute;inset:0;overflow:hidden;border-radius:${r}px`)
  if (n.shape) { clip.style.borderRadius = '0'; clip.style.clipPath = cssPath(shapePath(n.shape, f.width, f.height, r)) }
  if (n.mono) clip.style.filter = 'grayscale(1)'
  const contain = n.fit === 'contain'
  const img = document.createElement('img')
  img.decoding = 'async'; img.referrerPolicy = 'no-referrer'
  img.style.cssText = `position:absolute;left:0;top:0;width:100%;height:100%;object-fit:${contain ? 'contain' : 'cover'}`
  if (src) {
    img.src = src.startsWith('http') ? src : `${ctx.base}icon/${encodeURIComponent(src)}`
  } else {
    const p = ctx.photo(slot)
    img.src = p.url
    const fit = p.fit
    if (!contain && (fit.dx || fit.dy || fit.zoom !== 1)) {
      // `dx`/`dy` เป็นสัดส่วนของขนาดที่วาดแบบ fill (ไม่ใช่กรอบ) — รู้ได้หลังรูปโหลด
      const apply = () => {
        const iw = img.naturalWidth, ih = img.naturalHeight
        if (!iw || !ih) return
        const k = Math.max(f.width / iw, f.height / ih)
        img.style.transform = `translate(${fit.dx * iw * k}px, ${fit.dy * ih * k}px) scale(${fit.zoom})`
      }
      img.addEventListener('load', apply)
      if (img.complete) apply()
    }
  }
  img.onerror = () => { img.style.visibility = 'hidden' }
  clip.appendChild(img)
  if (n.stroke) {
    const s = n.stroke
    const svg = document.createElementNS(NS, 'svg')
    svg.setAttribute('width', f.width); svg.setAttribute('height', f.height)
    svg.style.cssText = 'position:absolute;left:0;top:0'
    const path = shapePath(n.shape, f.width, f.height, r), id = `ic${uid++}`
    svg.innerHTML = `<defs><clipPath id="${id}"><path d="${path}"/></clipPath></defs><path d="${path}" fill="none" stroke="${ctx.color(s.color, n.on)}" stroke-width="${s.width * 2}" clip-path="url(#${id})"/>`
    clip.appendChild(svg)
  }
  outer.appendChild(clip)
  d.appendChild(outer)
}

// MARK: - ไอคอน

function icon(d, b, ctx) {
  const n = b.node, f = b.frame
  const raw = n.icon || ''
  const name = raw.startsWith('$') ? (b.item?.value(raw.slice(1)) ?? '') : raw
  const tint = n.tint ? ctx.color(n.tint, n.on, b.item) : null
  const r = corner(n, f.width, f.height)
  const holder = el('div', `position:absolute;inset:0;border-radius:${r}px;${r ? 'overflow:hidden' : ''}`)
  holder.appendChild(ctx.icon({ name, w: f.width, h: f.height, tint, text: n.text, size: n.size }))
  d.appendChild(holder)
}
