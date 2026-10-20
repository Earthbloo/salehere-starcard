// ผังของ widget เป็นข้อมูล (= Model/WidgetSpec.swift · model/WidgetSpec.kt)
//
// อ่าน JSON หนึ่งไฟล์ต่อชนิด → โหนดที่ตัวคำนวณ/ตัววาดใช้ · ค่าว่าง = ค่าตั้งต้นตามชนิด (ตัวคำนวณเป็นคนเติม)
// รูปของค่าที่แปลงแล้ว:
//   ความยาว (`w` `h`)  → {pt: n} · {pct: n} · 'fill' · 'hug'
//   ระยะขอบ (`pad`)    → {top, right, bottom, left}
//   เงื่อนไข (`if`)     → `cond`

/** ความยาวของกล่อง — ตัวเลข · `"72%"` · `"fill"` · `"hug"` */
function length(v) {
  if (v === undefined || v === null) return null
  if (typeof v === 'number') return { pt: v }
  if (v === 'fill' || v === 'hug') return v
  const s = String(v)
  if (s.endsWith('%')) return { pct: Number(s.slice(0, -1)) }
  return { pt: Number(s) }
}

/** ระยะขอบใน — `8` · `[v, h]` · `[t, r, b, l]` */
function insets(v) {
  if (v === undefined || v === null) return null
  if (typeof v === 'number') return { top: v, right: v, bottom: v, left: v }
  if (v.length === 1) return { top: v[0], right: v[0], bottom: v[0], left: v[0] }
  if (v.length === 2) return { top: v[0], right: v[1], bottom: v[0], left: v[1] }
  return { top: v[0], right: v[1], bottom: v[2], left: v[3] }
}

/** โหนดหนึ่งตัว — คัดลอกทุกฟิลด์ แล้วแปลงฟิลด์ที่มีรูปพิเศษ */
export function parseNode(j) {
  const n = { ...j }
  if ('if' in n) { n.cond = n.if; delete n.if }
  n.w = length(j.w)
  n.h = length(j.h)
  n.pad = insets(j.pad)
  if (j.stroke) n.stroke = { width: 1, ...j.stroke }
  if (j.shadow) n.shadow = { y: 0, x: 0, color: 'black@0.25', ...j.shadow }
  if (j.gradient) n.gradient = { angle: 90, ...j.gradient }
  if (j.pattern) n.pattern = { color: 'ink@0.12', ...j.pattern }
  if (j.each) n.each = parseNode(j.each)
  if (j.children) n.children = j.children.map(parseNode)
  return n
}

/** แผนผังของ widget หนึ่งชนิด */
export function parseSpec(j) {
  return {
    kind: j.kind,
    design: j.design,
    root: parseNode(j.root),
    notes: j.notes,
    variants: (j.variants || []).map((v) => ({ when: v.when, root: parseNode(v.root) })),
    fitScale: j.fitScale || null,
    widget: j.widget || null,
  }
}

// เงื่อนไขบนกรอบ
export const SpecCondition = {
  /** `w<260` · `h>=120` · `ratio<0.6` (ratio = h/w) — หลายเงื่อนไขคั่นด้วย `&` */
  box(expr, w, h) {
    for (const part of expr.split('&')) {
      const e = part.trim()
      const p = parse(e)
      if (!p) return false
      const [key, op, v] = p
      let lhs
      if (key === 'w') lhs = w
      else if (key === 'h') lhs = h
      else if (key === 'ratio') lhs = w > 0 ? h / w : 0
      else return false
      if (!compare(lhs, op, v)) return false
    }
    return true
  },
}

function parse(e) {
  for (const op of ['<=', '>=', '<', '>', '=']) {
    const i = e.indexOf(op)
    if (i >= 0) {
      const k = e.slice(0, i).trim()
      const v = e.slice(i + op.length).trim()
      const d = swiftParseDouble(v)
      if (d === null) return null
      return [k, op, d]
    }
  }
  return null
}

function compare(a, op, b) {
  switch (op) {
    case '<': return a < b
    case '<=': return a <= b
    case '>': return a > b
    case '>=': return a >= b
    default: return Math.abs(a - b) < 0.001
  }
}

/** `Double(String)` ของ Swift — ไม่รับช่องว่างหน้า/หลัง ไม่รับสตริงว่าง */
export function swiftParseDouble(s) {
  if (typeof s !== 'string' || s === '' || /^\s|\s$/.test(s)) return null
  if (!/^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$/.test(s)) return null
  return Number(s)
}

/** `String(Double)` ของ Swift — `27.0` · `1240000.0` · `0.5` */
export function swiftDouble(d) {
  if (!Number.isFinite(d)) return String(d)
  const a = Math.abs(d)
  if (a !== 0 && (a >= 1e16 || a < 1e-4)) {
    // Swift เขียน 1e+16 · 5e-05
    const [m, e] = d.toExponential().split('e')
    const exp = Number(e)
    return `${m}e${exp < 0 ? '-' : '+'}${String(Math.abs(exp)).padStart(2, '0')}`
  }
  const s = String(d)
  return s.includes('.') ? s : s + '.0'
}
