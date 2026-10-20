// ตัววัดข้อความ (เว็บ) (= `IOSSpecMeasurer` · layout/AndroidSpecMeasurer.kt)
//
// ฟอนต์ **ไฟล์เดียวกับแอป** (Noto Sans Thai Light…Black · Mitr) วัดด้วย canvas ที่ขนาด 1000px แล้วคูณ size/1000
// (= หน่วยฟอนต์ เหมือน CoreText บวกระยะรายตัวในหน่วยฟอนต์) · ระยะตัวอักษร (`tracking` + `kerning`) บวกเองทุกตัวที่กินที่
// (ไม่นับสระบน/ล่าง วรรณยุกต์ = Mn · Me) · ตัดบรรทัดแบบโลภที่จุดตัดคำของ `Intl.Segmenter` ภาษาไทย ·
// ความกว้างปัดขึ้น 2 ทศนิยม · ความสูง = จำนวนบรรทัด × ความสูงบรรทัด (hhea ของไฟล์ฟอนต์ — ตรงกับ iOS)
//
// ตัววาดใช้ `displayLines` ตัวเดียวกันนี้ — บรรทัดที่วาดคือบรรทัดที่วัดเสมอ ไม่ปล่อยให้เบราว์เซอร์ตัดเอง

const r2 = (v) => { const s = v * 100; return (s >= 0 ? Math.round(s) : -Math.round(-s)) / 100 }

/** ไฟล์ฟอนต์ของน้ำหนักนี้ (= `notoFontRes`) — < 400 Light · 400 Regular · 500 Medium … 900 Black */
const NOTO = [[400, 'Light', 300], [500, 'Regular', 400], [600, 'Medium', 500], [700, 'SemiBold', 600], [800, 'Bold', 700], [900, 'ExtraBold', 800], [Infinity, 'Black', 900]]
const notoFile = (w) => NOTO.find(([lim]) => w < lim)

/** ascender / descender / lineGap จากตาราง hhea ของไฟล์ (หน่วยต่อ em = 1000) */
const METRICS = { noto: [1061, 450, 0], mitr: [1150, 420, 0] }

/** ลงทะเบียนฟอนต์ของแอป — เรียกครั้งเดียวก่อนวัด */
export async function loadFonts(base = 'fonts/') {
  const faces = []
  for (const [, name, css] of NOTO) faces.push(new FontFace('SC Noto', `url(${base}NotoSansThai-${name}.ttf)`, { weight: String(css) }))
  faces.push(new FontFace('SC Mitr', `url(${base}Mitr-Regular.ttf)`, { weight: '100 900' }))
  await Promise.all(faces.map((f) => f.load().then((ff) => document.fonts.add(ff))))
}

/** ตระกูลฟอนต์ CSS ของ face ในผัง — มีแค่ฟอนต์ OFL ที่มากับแอป · face ที่ไม่รู้จัก (serif · rounded · sukhumvit … ที่ถอดออก) ตกไป noto */
export function fontCSS(face, weight, italic = false) {
  switch (face) {
    case 'mitr': return { family: '"SC Mitr"', weight: 400, style: 'normal', bundled: 'mitr' }
    default: return { family: '"SC Noto"', weight: notoFile(weight)[2], style: 'normal', bundled: 'noto' }
  }
}

const MARK = /[\p{Mn}\p{Me}]/u

export class WebMeasurer {
  constructor() {
    this.ctx = document.createElement('canvas').getContext('2d')
    this.cache = new Map()
    this.words = new Intl.Segmenter('th', { granularity: 'word' })
    this.graphemes = new Intl.Segmenter('th', { granularity: 'grapheme' })
  }

  /** ความกว้างของสตริงในหน่วยออกแบบ (ยังไม่ปัด) */
  width(s, f) {
    if (!s) return 0
    const css = fontCSS(f.face, f.weight, f.italic)
    const key = `${css.family}|${css.weight}|${css.style}|${s}`
    let w = this.cache.get(key)
    if (w === undefined) {
      this.ctx.font = `${css.style} ${css.weight} 1000px ${css.family}`
      w = this.ctx.measureText(s).width
      this.cache.set(key, w)
    }
    let out = w * f.size / 1000
    const sp = (f.tracking || 0) + (f.kerning || 0)
    if (sp) for (const ch of s) if (!MARK.test(ch)) out += sp
    return out
  }

  /** ความสูงหนึ่งบรรทัด (ไม่คูณ `lineHeight` ของผัง) = ascent + descent + leading */
  rawLine(f) {
    const css = fontCSS(f.face, f.weight, f.italic)
    const m = METRICS[css.bundled || 'noto']
    const sc = f.size / 1000
    return m[0] * sc + m[1] * sc + m[2] * sc
  }

  lineHeight(f) { return r2(this.rawLine(f) * (f.lineHeight ?? 1)) }

  /** จุดตัดคำของย่อหน้า (หลังตัวอักษรตัวที่เท่าไร) — คำไทยตามพจนานุกรม + หลังช่องว่าง */
  stops(para) {
    const out = []
    for (const seg of this.words.segment(para)) {
      const end = seg.index + seg.segment.length
      // ช่องว่าง/เครื่องหมายผูกกับคำก่อนหน้า (ตัดหลังช่องว่าง ไม่ใช่ก่อน)
      if (/^\s+$/.test(seg.segment) && out.length) out[out.length - 1] = end
      else out.push(end)
    }
    return out
  }

  breakParagraph(para, f, width) {
    if (!para.length || width == null) return [{ text: para, width: this.width(para, f) }]
    const limit = width + 1e-9
    const fits = (a, b) => {
      let e = b
      while (e > a && /\s/.test(para[e - 1])) e--
      return this.width(para.slice(a, e), f) <= limit
    }
    const stops = this.stops(para)
    const gStops = [...this.graphemes.segment(para)].map((g) => g.index + g.segment.length)
    const lines = []
    let start = 0
    while (start < para.length) {
      let end = -1
      for (const st of stops) {
        if (st <= start) continue
        if (fits(start, st)) end = st; else break
      }
      if (end < 0) {
        // คำแรกของบรรทัดยาวกว่าบรรทัด — ตัดทีละกลุ่มอักษร (อย่างน้อยหนึ่งกลุ่ม)
        const gs = gStops.filter((g) => g > start)
        end = gs[0]
        for (const g of gs) { if (fits(start, g)) end = g; else break }
      }
      lines.push({ text: para.slice(start, end), width: this.width(para.slice(start, end), f) })
      start = end
    }
    return lines
  }

  layoutLines(text, f, width) { return text.split('\n').flatMap((p) => this.breakParagraph(p, f, width)) }

  measure(text, f, width) {
    const lines = this.layoutLines(text, f, width)
    const n = Math.max(1, lines.length)
    const w = lines.length ? Math.max(...lines.map((l) => l.width)) : 0
    return { w: Math.ceil(w * 100 - 1e-7) / 100, h: n * this.lineHeight(f), lines: n }
  }

  /** บรรทัดที่ตัววาดแสดง — `lines` บรรทัดแรกตามที่วัด · ถ้ายังเหลือ บรรทัดสุดท้ายรวมที่เหลือแล้วตัดท้ายด้วย … */
  displayLines(text, f, width, lines) {
    const all = this.layoutLines(text, f, width).map((l) => l.text)
    const keep = Math.max(1, lines)
    if (all.length <= keep) return all.map((s) => s.trimEnd())
    const head = all.slice(0, keep - 1).map((s) => s.trimEnd())
    let rest = all.slice(keep - 1).join('').replace(/\n/g, ' ').trimEnd()
    if (this.width(rest, f) > width + 0.01) {
      const gs = [...this.graphemes.segment(rest)].map((g) => g.index + g.segment.length)
      let cut = 0
      for (const g of gs) { if (this.width(rest.slice(0, g).trimEnd() + '…', f) <= width + 0.01) cut = g; else break }
      rest = rest.slice(0, cut).trimEnd() + '…'
    }
    return [...head, rest]
  }
}
