// ไอคอนของแอปสำหรับเว็บดูการ์ด — ไฟล์ชุดเดียวกับที่ iOS/Android ใช้ (ทดลอง · ลบได้พร้อม sync-server/web)
//
// ลำดับหา: asset ของ iOS ที่เป็น svg/png/jpg → Phosphor ของแพ็กเกจ iOS → drawable ของ Android
// (vector XML แปลงเป็น SVG ที่นี่ · PDF ของ iOS เบราว์เซอร์ใช้ไม่ได้ จึงข้ามไปหาของ Android)

import fs from 'node:fs'
import path from 'node:path'

export function iconResolver(repo) {
  const iosAssets = path.join(repo, 'StarCard', 'StarCard', 'Assets.xcassets')
  const phosphor = path.join(repo, 'StarCard', 'Packages', 'PhosphorSwift', 'Sources', 'PhosphorSwift', 'Resources', 'Assets.xcassets', 'SVG')
  const res = path.join(repo, 'StarCardAndroid', 'app', 'src', 'main', 'res')

  // ชื่อ imageset → โฟลเดอร์ (ทุกกลุ่ม)
  const sets = new Map()
  const walk = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      if (!e.isDirectory()) continue
      const p = path.join(dir, e.name)
      if (e.name.endsWith('.imageset')) sets.set(e.name.slice(0, -9).toLowerCase(), p)
      else walk(p)
    }
  }
  walk(iosAssets)
  walk(phosphor)

  const SH = {
    instagram: 'about-social-instagram', tiktok: 'about-social-tiktok', youtube: 'about-social-youtube',
    facebook: 'about-social-facebook', x: 'about-social-x', lemon8: 'about-social-lemon8',
    sealCheck: 'ic-seal-check', verifiedPill: 'ic-verified-sale-here', star: 'ic-salehere-star-outline',
    wordmark: 'ic-salehere-text', watermark: 'ic-salehere-watermark', qr: 'ic-salehere-qr',
  }

  /** ไฟล์ที่เบราว์เซอร์เปิดได้ในหนึ่ง imageset (ภาพใหญ่สุดก่อน) */
  function fromSet(name) {
    const dir = sets.get(name.toLowerCase())
    if (!dir) return null
    const files = fs.readdirSync(dir).filter((f) => /\.(svg|png|jpe?g)$/i.test(f))
      .sort((a, b) => (/\.svg$/i.test(b) - /\.svg$/i.test(a)) || (b.includes('@3x') - a.includes('@3x')) || (b.includes('@2x') - a.includes('@2x')))
    return files.length ? { file: path.join(dir, files[0]) } : null
  }

  function fromAndroid(name) {
    const key = name.replace(/-/g, '_').toLowerCase()
    for (const d of ['drawable-nodpi', 'drawable']) {
      for (const ext of ['.png', '.webp', '.jpg']) {
        const f = path.join(res, d, key + ext)
        if (fs.existsSync(f)) return { file: f }
      }
      const x = path.join(res, d, key + '.xml')
      if (fs.existsSync(x)) {
        const svg = vectorToSVG(fs.readFileSync(x, 'utf8'))
        if (svg) return { svg }
      }
    }
    return null
  }

  return function resolve(raw) {
    let name = raw
    if (name.startsWith('ph:')) {
      const short = name.slice(3)
      const fill = short.endsWith('-fill')
      const base = fill ? short.slice(0, -5) : short
      return fromSet('ph-' + short) || (fill ? fromSet(base + '-fill') : fromSet(base + '-bold') || fromSet(base))
        || fromAndroid('ph_' + base + (fill ? '_fill' : '_bold')) || fromAndroid('ph_' + short)
    }
    if (name.startsWith('sh:')) name = SH[name.slice(3)] || name.slice(3)
    return fromSet(name) || fromAndroid(name)
  }
}

// MARK: - Android vector drawable → SVG

function parseXML(src) {
  const root = { tag: '#root', attrs: {}, children: [] }
  const stack = [root]
  const re = /<!--[\s\S]*?-->|<\?[\s\S]*?\?>|<\/([\w:.-]+)\s*>|<([\w:.-]+)((?:\s+[\w:.-]+\s*=\s*"[^"]*")*)\s*(\/?)>/g
  let m
  while ((m = re.exec(src))) {
    if (m[1]) { stack.pop(); continue }
    if (!m[2]) continue
    const attrs = {}
    for (const a of m[3].matchAll(/([\w:.-]+)\s*=\s*"([^"]*)"/g)) attrs[a[1]] = a[2]
    const node = { tag: m[2], attrs, children: [] }
    stack[stack.length - 1].children.push(node)
    if (!m[4]) stack.push(node)
  }
  return root.children[0]
}

/** #AARRGGBB / #RRGGBB / #RGB → [css, alpha] */
function androidColor(c) {
  if (!c || !c.startsWith('#')) return null
  let h = c.slice(1)
  if (h.length === 3) h = [...h].map((x) => x + x).join('')
  if (h.length === 4) h = [...h].map((x) => x + x).join('')
  let a = 1
  if (h.length === 8) { a = parseInt(h.slice(0, 2), 16) / 255; h = h.slice(2) }
  return [`#${h}`, a]
}

const A = (n, k) => n.attrs['android:' + k]

function vectorToSVG(xml) {
  const v = parseXML(xml)
  if (!v || v.tag !== 'vector') return null
  const vw = A(v, 'viewportWidth'), vh = A(v, 'viewportHeight')
  const w = parseFloat(A(v, 'width')) || vw, h = parseFloat(A(v, 'height')) || vh
  const defs = []
  let gid = 0
  const paint = (n, which) => {
    // สีแบบไล่เฉดอยู่ใน <aapt:attr name="android:fillColor"><gradient …>
    const attr = n.children.find((c) => c.tag === 'aapt:attr' && c.attrs.name === `android:${which}Color`)
    const g = attr?.children.find((c) => c.tag === 'gradient')
    if (g) {
      const id = `g${gid++}`
      const stops = g.children.filter((c) => c.tag === 'item').map((it) => {
        const [col, a] = androidColor(A(it, 'color')) || ['#000', 1]
        return `<stop offset="${A(it, 'offset') ?? 0}" stop-color="${col}" stop-opacity="${a}"/>`
      })
      if (!stops.length) {
        for (const [k, o] of [['startColor', 0], ['centerColor', 0.5], ['endColor', 1]]) {
          const c = androidColor(A(g, k)); if (c) stops.push(`<stop offset="${o}" stop-color="${c[0]}" stop-opacity="${c[1]}"/>`)
        }
      }
      if (A(g, 'type') === 'radial') {
        defs.push(`<radialGradient id="${id}" gradientUnits="userSpaceOnUse" cx="${A(g, 'centerX') ?? 0}" cy="${A(g, 'centerY') ?? 0}" r="${A(g, 'gradientRadius') ?? 1}">${stops.join('')}</radialGradient>`)
      } else {
        defs.push(`<linearGradient id="${id}" gradientUnits="userSpaceOnUse" x1="${A(g, 'startX') ?? 0}" y1="${A(g, 'startY') ?? 0}" x2="${A(g, 'endX') ?? 0}" y2="${A(g, 'endY') ?? 0}">${stops.join('')}</linearGradient>`)
      }
      return [`url(#${id})`, 1]
    }
    return androidColor(A(n, `${which}Color`))
  }
  const draw = (n) => {
    if (n.tag === 'path') {
      const d = A(n, 'pathData')
      if (!d) return ''
      const fill = paint(n, 'fill'), stroke = paint(n, 'stroke')
      const fa = parseFloat(A(n, 'fillAlpha') ?? '1'), sa = parseFloat(A(n, 'strokeAlpha') ?? '1')
      let s = `<path d="${d}"`
      s += fill ? ` fill="${fill[0]}" fill-opacity="${fill[1] * fa}"` : ' fill="none"'
      if (stroke) s += ` stroke="${stroke[0]}" stroke-opacity="${stroke[1] * sa}" stroke-width="${A(n, 'strokeWidth') ?? 1}" stroke-linecap="${A(n, 'strokeLineCap') ?? 'butt'}" stroke-linejoin="${A(n, 'strokeLineJoin') ?? 'miter'}"`
      if (A(n, 'fillType') === 'evenOdd') s += ' fill-rule="evenodd"'
      return s + '/>'
    }
    if (n.tag === 'group') {
      const px = +(A(n, 'pivotX') ?? 0), py = +(A(n, 'pivotY') ?? 0)
      const t = `translate(${+(A(n, 'translateX') ?? 0) + px} ${+(A(n, 'translateY') ?? 0) + py}) rotate(${A(n, 'rotation') ?? 0}) scale(${A(n, 'scaleX') ?? 1} ${A(n, 'scaleY') ?? 1}) translate(${-px} ${-py})`
      let clip = ''
      const cp = n.children.find((c) => c.tag === 'clip-path')
      if (cp) { const id = `c${gid++}`; defs.push(`<clipPath id="${id}"><path d="${A(cp, 'pathData')}"/></clipPath>`); clip = ` clip-path="url(#${id})"` }
      return `<g transform="${t}"${clip}>${n.children.map(draw).join('')}</g>`
    }
    return ''
  }
  const body = v.children.map(draw).join('')
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${vw} ${vh}"><defs>${defs.join('')}</defs>${body}</svg>`
}
