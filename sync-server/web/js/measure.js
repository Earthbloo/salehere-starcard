// ตัววัดข้อความ (เว็บ) (= `IOSSpecMeasurer` ท้าย Views/Widgets/SpecPainter.swift · layout/AndroidSpecMeasurer.kt)
//
// ฟอนต์ **ไฟล์เดียวกับแอป** (Noto Sans Thai Light…Black · Mitr) · กติกาให้ตรง CoreText ชุดเดียวกับ Android:
// · ระยะรายกลุ่มอักษรเป็น **หน่วยฟอนต์จำนวนเต็ม** (วัดด้วย canvas ที่ 1000px = 1 หน่วยต่อ px · จัดรูปทั้งย่อหน้าก่อนแล้วหาระยะ
//   ของแต่ละกลุ่มจากผลต่างของส่วนท้าย — kerning ของตัวท้ายบรรทัดกับตัวแรกของบรรทัดถัดไปจึงยังอยู่ เหมือน CoreText)
// · Σ `หน่วย × (size / 1000)` แบบ double ทีละกลุ่ม (เศษของ double ต้องตรงกับ CoreText ถึงจะปัด `ceil(w × 100) / 100` ตรงกัน)
// · ระยะตัวอักษร (`tracking` + `kerning`) บวกทุกตัวที่กินที่ รวมตัวท้าย (ไม่นับสระบน/ล่าง วรรณยุกต์ = Mn · Me)
// · จุดตัดบรรทัด = กติกา UAX #14 + พจนานุกรมไทยของเบราว์เซอร์เอง (วางข้อความในกล่องกว้าง 0 แล้วอ่านว่าบรรทัดขึ้นตรงไหน —
//   ไม่ใช้ `Intl.Segmenter` แบบคำ เพราะมันตัด "BUILDING|..." กับ "@maneerat|.review" ที่ CoreText ไม่ตัด) · ตัดแบบโลภ ไม่ตัดยัติภังค์
// · ความกว้างบรรทัดนับช่องว่างท้ายบรรทัด (= `boundingRect` ของ iOS) · ความสูง = จำนวนบรรทัด × ความสูงบรรทัด (hhea ของไฟล์ฟอนต์)
//
// ตัววาดใช้ `displayLines` ตัวเดียวกันนี้ — บรรทัดที่วาดคือบรรทัดที่วัดเสมอ ไม่ปล่อยให้เบราว์เซอร์ตัดเอง
// พิสูจน์กับ iOS: `node sync-server/web/test/measure-parity.mjs` (WIDGET-SPEC.md §7)

const r2 = (v) => { const s = v * 100; return (s >= 0 ? Math.round(s) : -Math.round(-s)) / 100 }

/** ไฟล์ฟอนต์ของน้ำหนักนี้ (= `notoFontRes`) — < 400 Light · 400 Regular · 500 Medium … 900 Black */
const NOTO = [[400, 'Light', 300], [500, 'Regular', 400], [600, 'Medium', 500], [700, 'SemiBold', 600], [800, 'Bold', 700], [900, 'ExtraBold', 800], [Infinity, 'Black', 900]]
const notoFile = (w) => NOTO.find(([lim]) => w < lim)

/** ascender / descender / lineGap จากตาราง hhea ของไฟล์ (หน่วยต่อ em = 1000) — ตรงกับ `UIFont.lineHeight` ของ iOS */
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
    this.shapes = new Map()
    this.breaks = new Map()
    this.graphemes = new Intl.Segmenter('th', { granularity: 'grapheme' })
    this.probe = null
  }

  /**
   * ระยะรายกลุ่มอักษรของ **ทั้งย่อหน้า** เป็นหน่วยฟอนต์จำนวนเต็ม (= `getTextWidths` ของ Android หลังจัดรูป รวม kerning กับตัวถัดไป)
   * วัดส่วนท้าย `para[k…]` ทุกกลุ่มที่ 1000px แล้วหาผลต่าง — ระยะของกลุ่มท้ายบรรทัดจึงรวม kerning กับกลุ่มแรกของบรรทัดถัดไป
   * ("Tarmjaip|a" มิตร 29pt: 118.67 ไม่ใช่ 119.40 ของการจัดรูปทีละบรรทัด)
   */
  shape(para, css) {
    const key = `${css.family}|${css.weight}|${css.style}|${para}`
    let s = this.shapes.get(key)
    if (s) return s
    const starts = [...this.graphemes.segment(para)].map((g) => g.index)
    starts.push(para.length)
    this.ctx.font = `${css.style} ${css.weight} 1000px ${css.family}`
    const suffix = starts.map((i) => (i < para.length ? this.ctx.measureText(para.slice(i)).width : 0))
    // ระยะต่อกลุ่ม (ตำแหน่งตามดัชนีตัวอักษรแรกของกลุ่ม) · กลุ่มที่ไม่กินที่ (ช่องว่างศูนย์) = 0
    const units = new Map()
    for (let k = 0; k + 1 < starts.length; k++) units.set(starts[k], Math.round(suffix[k] - suffix[k + 1]))
    s = { starts: starts.slice(0, -1), units }
    this.shapes.set(key, s)
    return s
  }

  /**
   * ความกว้างของ `para[a, b)` เป็นหน่วยออกแบบ — เลียนเลขคณิตของ CoreText กลุ่มต่อกลุ่ม:
   * Σ `หน่วย × (size / 1000)` แบบ double (ตัวคูณคิดก่อน) + ระยะตัวอักษรต่อตัวที่ไม่ใช่ Mn/Me
   */
  advance(para, shaped, a, b, f) {
    if (b <= a) return 0
    const sp = (f.tracking || 0) + (f.kerning || 0)
    // ลองแล้ว (20 ต.ค. 2569 · 19,605 คำถาม): `u × (size/1000)` ไม่ต่างเลย 99.55% (ที่เหลือ 88 ค่าต่าง 0.01 พอดี = เศษ double คนละทาง) ·
    // `u × size / 1000` 98.79% · `(u/1000) × size` 98.49% · รวมหน่วยทั้งบรรทัดก่อนค่อยคูณ 98.02% · แยก kerning เป็นพจน์ของตัวเอง 99.42%
    const scale = f.size / 1000
    let sum = 0
    for (const st of shaped.starts) {
      if (st < a) continue
      if (st >= b) break
      sum += shaped.units.get(st) * scale
    }
    if (sp) for (const ch of para.slice(a, b)) if (!MARK.test(ch)) sum += sp
    return sum
  }

  /** ความกว้างของสตริงหนึ่งบรรทัดในหน่วยออกแบบ (ยังไม่ปัด) */
  width(s, f) {
    if (!s) return 0
    return this.advance(s, this.shape(s, fontCSS(f.face, f.weight, f.italic)), 0, s.length, f)
  }

  /** ความสูงหนึ่งบรรทัด (ไม่คูณ `lineHeight` ของผัง) = ascent + descent + leading (ทีละส่วน × size/1000 แบบ iOS) */
  rawLine(f) {
    const css = fontCSS(f.face, f.weight, f.italic)
    const m = METRICS[css.bundled || 'noto']
    const sc = f.size / 1000
    return m[0] * sc + m[1] * sc + m[2] * sc
  }

  lineHeight(f) { return r2(this.rawLine(f) * (f.lineHeight ?? 1)) }

  /**
   * จุดตัดบรรทัดของย่อหน้า (หลังตัวอักษรตัวที่เท่าไร) = โอกาสตัดบรรทัดของเบราว์เซอร์เอง (ICU UAX #14 + พจนานุกรมไทย
   * = `BreakIterator.getLineInstance("th")` ที่ Android ใช้ · CoreText ใช้กติกาชุดเดียวกัน): วางย่อหน้าในกล่องกว้าง 0
   * ที่ห้ามตัดกลางคำ แล้วอ่านว่ากลุ่มอักษรไหนขึ้นบรรทัดใหม่ · ช่องว่างห้อยท้ายบรรทัดก่อนหน้า (ตัดหลังช่องว่าง ไม่ใช่ก่อน)
   */
  stops(para) {
    let out = this.breaks.get(para)
    if (out) return out
    if (!this.probe) {
      const p = document.createElement('div')
      p.style.cssText = 'position:absolute;left:-99999px;top:0;width:0;white-space:pre-wrap;overflow-wrap:normal;word-break:normal;line-break:auto;hyphens:none;font:16px/1 "SC Noto",sans-serif;visibility:hidden;contain:layout style'
      p.lang = 'th'
      document.body.appendChild(p)
      this.probe = p
    }
    const p = this.probe
    p.textContent = para
    const text = p.firstChild
    const range = document.createRange()
    out = []
    let lastTop = null
    for (const g of this.graphemes.segment(para)) {
      if (/^\s+$/.test(g.segment)) continue // ช่องว่างห้อยท้ายบรรทัด ไม่ขึ้นต้นบรรทัดใหม่
      range.setStart(text, g.index)
      range.setEnd(text, g.index + g.segment.length)
      const rect = range.getBoundingClientRect()
      if (lastTop != null && rect.top > lastTop + 0.5) out.push(g.index)
      lastTop = rect.top
    }
    out.push(para.length)
    p.textContent = ''
    this.breaks.set(para, out)
    return out
  }

  breakParagraph(para, f, width) {
    const css = fontCSS(f.face, f.weight, f.italic)
    const shaped = this.shape(para, css)
    const w = (a, b) => this.advance(para, shaped, a, b, f)
    if (!para.length || width == null) return [{ text: para, width: w(0, para.length) }]
    // พอดีบรรทัด = กว้างไม่เกินบรรทัดเลย (ไม่มีส่วนเผื่อ) — CoreText ไม่ยอมให้เกินแม้ 0.01
    const limit = width + 1e-9
    // `tracking` บวกหลังกลุ่มสุดท้ายของบรรทัดห้อยท้ายได้เหมือนช่องว่าง — ไม่นับตอนตัดสินว่าพอดีบรรทัด
    // ("STAR CARD|" 12.12pt tr 0.9 ในกล่อง 71.77: 72.52 − 0.9 พอดี · ค่าลบไม่ห้อย: "ในกรุงเทพ" tr −0.8 ต้องพอดีทั้งก้อน)
    const hang = Math.max(0, f.tracking || 0)
    const fits = (a, b) => {
      let e = b
      while (e > a && /\s/.test(para[e - 1])) e--
      return w(a, e) - (hang && e > a && !MARK.test(para[e - 1]) ? hang : 0) <= limit
    }
    const stops = this.stops(para)
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
        const gs = shaped.starts.filter((g) => g > start)
        gs.push(para.length)
        end = gs[0]
        for (const g of gs) { if (fits(start, g)) end = g; else break }
      }
      lines.push({ text: para.slice(start, end), width: w(start, end) })
      start = end
    }
    return lines
  }

  /** ย่อหน้าตาม '\n' (CoreText ตัดที่ขึ้นบรรทัดใหม่เสมอ) แล้วตัดคำในแต่ละย่อหน้า */
  layoutLines(text, f, width) { return text.split('\n').flatMap((p) => this.breakParagraph(p, f, width)) }

  /**
   * กว้าง × สูง + จำนวนบรรทัด = `boundingRect` ของ iOS (ตรวจกับ fixture 19,605 คำถาม):
   * · ความกว้างต่อบรรทัดนับช่องว่างท้ายบรรทัด แต่ **ไม่เกินความกว้างกล่อง** — บรรทัดที่ช่องว่างท้ายล้นกรอบ ("Sivanna␠" 133.89 ในกล่อง 126.27)
   *   หรือกลุ่มอักษรเดียวที่กว้างกว่ากล่อง ("•" 3.2 ในกล่อง 1.84) iOS รายงานเท่ากล่อง
   * · ข้อความหลายบรรทัด: `tracking` หลังกลุ่มสุดท้ายของบรรทัดสุดท้ายไม่นับ (บรรทัดเดียวนับ — TextKit กับ CTLine ตอบต่างกัน)
   * · ปัดขึ้น 2 ทศนิยม = `ceil(r.width * 100) / 100` (เศษของ double ใน `advance` ตรงกับ CoreText แล้ว จึงไม่ต้องเผื่อ)
   */
  measure(text, f, width) {
    const lines = this.layoutLines(text, f, width)
    const n = Math.max(1, lines.length)
    let w = 0
    lines.forEach((l, i) => {
      let lw = l.width
      if (i === lines.length - 1 && lines.length > 1 && f.tracking && l.text.length && !MARK.test(l.text[l.text.length - 1]) && !/\s$/.test(l.text)) lw -= f.tracking
      if (width != null && lw > width) lw = width
      if (lw > w) w = lw
    })
    return { w: Math.ceil(w * 100) / 100, h: n * this.lineHeight(f), lines: n }
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
