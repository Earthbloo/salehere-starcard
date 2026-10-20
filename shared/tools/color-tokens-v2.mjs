#!/usr/bin/env node
// แปลง token สีของผัง widget จากชุดเก่า 40 ชื่อ → ชุดใหม่ 6 ชื่อ × พื้น (20 ต.ค. 2569)
//
//   node shared/tools/color-tokens-v2.mjs --dry     รายงานอย่างเดียว ไม่เขียนไฟล์
//   node shared/tools/color-tokens-v2.mjs           เขียนทับ shared/WidgetSpecs/*.json
//
// ชื่อใหม่ (WIDGET-SPEC.md §4): bg · bg2 · ink · ink2 · accent · line  (+ white black clear #hex · @ความทึบ)
// "พื้น" ที่ชื่อเหล่านี้หมายถึง: widget.on = พื้นตั้งต้นของทั้งใบ · โหนดที่นั่งคนละพื้นใส่ "on" ของตัวเอง
// พื้นที่มี: card (ค่าเริ่มต้น) · plate · paper · kit · pop · scrap

import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..')
const specDir = path.join(root, 'shared/WidgetSpecs')
const dry = process.argv.includes('--dry')

// ชื่อเก่า → [พื้น, ชื่อใหม่, ความทึบตั้งต้นเมื่อผังไม่ได้ใส่ @]
//   สีเก่าเกือบทุกตัวเป็นสีทึบ: ผังที่เขียน `@0.2` ไว้หมายถึง 20% ของสีนั้น → คง @ เดิม · ไม่ใส่ @ = ใช้ความทึบตั้งต้นของชื่อใหม่
//   ยกเว้น `pop.shadow` ที่เป็นสีโปร่งอยู่แล้ว (ชมพู 35%) → คูณ (ดู MULTIPLY)
const MULTIPLY = new Set(['pop.shadow'])
const MAP = {
  // การ์ด
  ink: ['card', 'ink', 1], line: ['card', 'line', 1], fill: ['card', 'bg2', 1], ghost: ['card', 'ink2', 1],
  accent: ['card', 'accent', 1], accentSoft: ['card', 'accent', 0.6], paper: ['card', 'bg', 1],
  // แผ่นเข้มของโปสเตอร์ (ในไฟล์ pop: สีชมพูของแผ่นสติกเกอร์ — ดู popOverride)
  plate: ['plate', 'bg', 1], plateInk: ['plate', 'ink', 1], rawAccent: ['plate', 'accent', 1], rawAccentSoft: ['plate', 'accent', 0.6],
  // กระดาษครีมของสำรับบรรณาธิการ
  accentPaper: ['paper', 'accent', 1],
  'ed.sheet': ['paper', 'bg', 1], 'ed.ink': ['paper', 'ink', 1], 'ed.inkSoft': ['paper', 'ink2', 1], 'ed.ghost': ['paper', 'bg2', 1],
  'ed.marker': ['paper', 'accent', 1], 'ed.red': ['paper', 'accent', 1],
  // ชุดห้าสไตล์
  'kit.fill': ['kit', 'bg', 1], 'kit.block': ['kit', 'bg2', 1], 'kit.ink': ['kit', 'ink', 1], 'kit.title': ['kit', 'ink', 1],
  'kit.mut': ['kit', 'ink2', 1], 'kit.accent': ['kit', 'accent', 1], 'kit.border': ['kit', 'line', 1],
  // สติกเกอร์
  'pop.sheet': ['pop', 'bg', 1], 'pop.paper': ['pop', 'bg2', 1], 'pop.ink': ['pop', 'ink', 1], 'pop.inkSoft': ['pop', 'ink2', 1],
  'pop.rule': ['pop', 'line', 1], 'pop.shadow': ['pop', 'accent', 0.35],
  // สแครปบุ๊ก
  'scrap.paper': ['scrap', 'bg', 1], 'scrap.band': ['scrap', 'bg2', 1], 'scrap.mid': ['scrap', 'bg2', 1], 'scrap.blush': ['scrap', 'bg2', 1],
  'scrap.ink': ['scrap', 'ink', 1], 'scrap.soft': ['scrap', 'ink2', 1], 'scrap.accent': ['scrap', 'accent', 1], 'scrap.strong': ['scrap', 'accent', 1],
  'scrap.paperAccent': ['paper', 'accent', 1], 'scrap.paperStrong': ['paper', 'accent', 1],
  // เงาของของที่ลอยบนแผ่น = ดำ (แผ่นมืดเคยเป็นดำอยู่แล้ว · แผ่นสว่างเคยอาบเฉด) · เกล็ดกระดาษ = หมึกจาง
  'scrap.shade': ['scrap', 'black', 1], 'scrap.speck': ['scrap', 'ink', 0.1],
}
const LITERAL = new Set(['white', 'black', 'clear'])
const COLOR_KEYS = ['fill', 'stroke', 'color', 'tint', 'color2', 'platePattern']

function parse(tok) {
  const at = tok.lastIndexOf('@')
  return at < 0 ? [tok, null] : [tok.slice(0, at), Number(tok.slice(at + 1))]
}
function isToken(v) { return typeof v === 'string' && !v.startsWith('#') && !v.startsWith('$') && !LITERAL.has(parse(v)[0]) }
function fmt(a) { return String(Math.round(a * 100) / 100) }

/** พื้นที่ token เก่าตัวนี้หมายถึง (ในไฟล์ที่เป็นสำรับ pop สีชมพูดิบคือสีเน้นของแผ่นสติกเกอร์) */
function surfaceOf(name, popFile) {
  const m = MAP[name]
  if (!m) return null
  if (popFile && (name === 'rawAccent' || name === 'rawAccentSoft')) return 'pop'
  return m[0]
}
function convert(tok, popFile) {
  const [name, a] = parse(tok)
  const m = MAP[name]
  if (!m) return tok
  const def = m[2]
  let alpha = a
  if (MULTIPLY.has(name)) alpha = (a ?? 1) * def
  else if (a == null && def !== 1) alpha = def
  return alpha == null ? m[1] : `${m[1]}@${fmt(alpha)}`
}

/** ทุกค่าสีของโหนดหนึ่ง: [อ็อบเจกต์, คีย์] */
function colorRefs(n) {
  const out = []
  for (const k of COLOR_KEYS) if (typeof n[k] === 'string') out.push([n, k])
  if (n.stroke && typeof n.stroke === 'object' && typeof n.stroke.color === 'string') out.push([n.stroke, 'color'])
  if (Array.isArray(n.fillCycle)) n.fillCycle.forEach((_, i) => out.push([n.fillCycle, i]))
  if (n.gradient) { out.push([n.gradient, 'from']); out.push([n.gradient, 'to']) }
  if (n.shadow && typeof n.shadow === 'object') { if (n.shadow.color == null) n.shadow.color = 'black@0.25'; out.push([n.shadow, 'color']) }
  if (n.pattern && typeof n.pattern === 'object') { if (typeof n.pattern.color === 'string') out.push([n.pattern, 'color']); if (typeof n.pattern.color2 === 'string') out.push([n.pattern, 'color2']) }
  return out.filter(([o, k]) => isToken(o[k]))
}

const report = { files: 0, nodesOn: 0, tokens: 0, warnings: [], defaults: {}, newNames: {} }

function walkNodes(n, fn) {
  if (Array.isArray(n)) { n.forEach(x => walkNodes(x, fn)); return }
  if (!n || typeof n !== 'object') return
  if (typeof n.type === 'string') fn(n)
  for (const [k, v] of Object.entries(n)) if (k !== 'widget' && typeof v === 'object') walkNodes(v, fn)
}

for (const file of fs.readdirSync(specDir).filter(f => f.endsWith('.json')).sort()) {
  const p = path.join(specDir, file)
  const spec = JSON.parse(fs.readFileSync(p, 'utf8'))
  const popFile = Object.keys(spec).length && JSON.stringify(spec).includes('"pop.')
  // 1) นับพื้นทั้งไฟล์ → พื้นตั้งต้นของใบ = พื้นที่ใช้มากสุด
  const count = {}
  const nodes = []
  walkNodes([spec.root, spec.variants ?? []], n => {
    const refs = colorRefs(n)
    const surfaces = new Set(refs.map(([o, k]) => surfaceOf(parse(o[k])[0], popFile)).filter(Boolean))
    for (const s of surfaces) count[s] = (count[s] ?? 0) + 1
    nodes.push([n, refs, surfaces])
  })
  const def = Object.entries(count).sort((a, b) => b[1] - a[1])[0]?.[0] ?? 'card'
  report.defaults[def] = (report.defaults[def] ?? 0) + 1
  // 2) โหนด: พื้นเดียว ≠ ตั้งต้น → on · หลายพื้น → พื้นที่ใช้มากสุดของโหนด + เงาของหมึกเป็นดำ
  for (const [n, refs, surfaces] of nodes) {
    if (!refs.length) continue
    let on = null
    if (surfaces.size === 1) on = [...surfaces][0]
    else if (surfaces.size > 1) {
      const c = {}
      for (const [o, k] of refs) { const s = surfaceOf(parse(o[k])[0], popFile); c[s] = (c[s] ?? 0) + 1 }
      on = Object.entries(c).sort((a, b) => b[1] - a[1])[0][0]
      for (const [o, k] of refs) {
        const [name, a] = parse(o[k])
        const s = surfaceOf(name, popFile)
        if (s === on) continue
        if (name === 'ink' && o === n.shadow) { o[k] = `black@${fmt(a ?? 1)}`; continue }   // เงาของตัวหนังสือบนกระดาษ
        report.warnings.push(`${file} ${n.id ?? n.type}: ${o[k]} นั่งบน ${s} แต่โหนดอยู่บน ${on}`)
      }
    }
    for (const [o, k] of refs) {
      const before = o[k]
      o[k] = convert(before, popFile)
      if (o[k] !== before) report.tokens++
      report.newNames[parse(o[k])[0]] = (report.newNames[parse(o[k])[0]] ?? 0) + 1
    }
    if (on && on !== def) { n.on = on; report.nodesOn++ } else delete n.on
  }
  if (def !== 'card') spec.widget.on = def; else delete spec.widget.on
  report.files++
  if (!dry) fs.writeFileSync(p, JSON.stringify(spec, null, 1) + '\n')
}

console.log(`${dry ? '[dry] ' : ''}ไฟล์ ${report.files} · token ที่แปลง ${report.tokens} · โหนดที่ใส่ on ${report.nodesOn}`)
console.log('พื้นตั้งต้นของไฟล์:', report.defaults)
console.log('ชื่อใหม่ที่ใช้:', report.newNames)
for (const w of report.warnings) console.log('⚠', w)
