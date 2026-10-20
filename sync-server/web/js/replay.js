// เล่นคำตอบที่ iOS บันทึกไว้ใน fixture ซ้ำ (= layout/SpecReplay.kt)
//
// fixture ของ iOS (`-exportSpecs`) จดทุกคำถามที่ตัวคำนวณถาม — ตัววัดข้อความ (`measures` · `lineHeights`)
// และแหล่งข้อมูล (`data`) · ใช้ทดสอบอัลกอริทึมล้วน ๆ และใช้วาดหน้าทดสอบด้วยข้อมูลชุดเดียวกับ iOS

import { SpecItem } from './spec-solver.js'

const near = (a, b) => Math.abs(a - b) < 1e-6

/** แหล่งข้อมูลที่ตอบด้วยค่าที่ iOS บันทึกไว้ (`case.data`) · ถามนอกชุด → `fallback` (ถ้ามี) และจดไว้ */
export class ReplayData {
  constructor(o, fallback = null) {
    this.misses = []
    this.fallback = fallback
    this.texts = new Map(o.texts.map((t) => [`${t.slot}\u0000${t.preset ?? ''}\u0000${t.preset == null}`, t.v]))
    this.lists = new Map(Object.entries(o.lists).map(([k, arr]) => [k, arr.map((it) => new SpecItem(it.id, it.i, it.fields))]))
    this.flags = new Map(Object.entries(o.flags))
    this.fonts = o.fonts
  }
  text(slot, preset) {
    const v = this.texts.get(`${slot}\u0000${preset ?? ''}\u0000${preset == null}`)
    if (v !== undefined) return v
    this.misses.push(`text ${slot} preset=${preset}`)
    return this.fallback ? this.fallback.text(slot, preset) : ''
  }
  list(name) {
    const v = this.lists.get(name)
    if (v) return v
    this.misses.push(`list ${name}`)
    return this.fallback ? this.fallback.list(name) : []
  }
  flag(name) {
    const v = this.flags.get(name)
    if (v !== undefined) return v
    this.misses.push(`flag ${name}`)
    return this.fallback ? this.fallback.flag(name) : false
  }
  font(slot, face, size, weight) {
    const f = this.fonts.find((it) => (it.slot ?? null) === slot && it.face === face && near(it.size, size) && it.weight === weight)
    if (!f) {
      this.misses.push(`font ${slot} ${face}/${size}/${weight}`)
      return this.fallback ? this.fallback.font(slot, face, size, weight) : { face, size, weight }
    }
    return { face: f.outFace, size: f.outSize, weight: f.outWeight }
  }
}

/** ตัววัดที่ตอบด้วยค่าที่ iOS บันทึกไว้ (`case.measures` · `case.lineHeights`) */
export class ReplayMeasurer {
  constructor(c, fallback = null) {
    this.measures = c.measures
    this.lineQs = c.lineHeights || []
    this.fallback = fallback
    this.misses = []
  }
  measure(text, font, width) {
    const m = this.measures.find((it) => it.t === text && it.face === font.face && it.weight === font.weight && near(it.size, font.size) &&
      near(it.tracking ?? 0, font.tracking ?? 0) && near(it.kerning ?? 0, font.kerning ?? 0) && near(it.lineHeight ?? 1, font.lineHeight ?? 1) &&
      ((it.width == null || width == null) ? it.width == null && width == null : near(it.width, width)))
    if (m) return { w: m.w, h: m.h, lines: m.lines }
    this.misses.push(`measure '${text.slice(0, 24)}' ${font.face}/${font.size}/${font.weight} w=${width}`)
    return this.fallback ? this.fallback.measure(text, font, width) : { w: 0, h: 0, lines: 1 }
  }
  lineHeight(font) {
    const q = this.lineQs.find((it) => it.face === font.face && it.weight === font.weight && near(it.size, font.size) &&
      near(it.lineHeight, font.lineHeight ?? 1) && it.italic === (font.italic ?? false))
    if (q) return q.v
    this.misses.push(`lineHeight ${font.face}/${font.size}/${font.weight}×${font.lineHeight}`)
    return this.fallback ? this.fallback.lineHeight(font) : 0
  }
  displayLines(text, font, width, maxLines) {
    return this.fallback ? this.fallback.displayLines(text, font, width, maxLines) : [text]
  }
}
