// node sync-server/web/test/replay.mjs [kind…]
// ตัวคำนวณ JS ต้องได้กล่องเท่า iOS ทุกกล่อง (= SpecSolverFixtureTest.kt ของ Android)
// เล่นคำตอบของ iOS ซ้ำทั้งตัววัดและข้อมูล → ทดสอบอัลกอริทึมล้วน ๆ · ต่างได้แค่เศษปัด (≤ 0.01)

import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { parseSpec } from '../js/spec-model.js'
import { SpecSolver } from '../js/spec-solver.js'
import { ReplayData, ReplayMeasurer } from '../js/replay.js'

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..')
const specDir = path.join(repo, 'shared/WidgetSpecs')
const fixtureDir = path.join(repo, 'present/spec-fixtures/fixtures')
const tol = 0.0101
const only = process.argv.slice(2)

let pass = 0, total = 0
for (const f of fs.readdirSync(specDir).filter((f) => f.endsWith('.json')).sort()) {
  const kind = f.slice(0, -5)
  if (only.length && !only.includes(kind)) continue
  const fx = path.join(fixtureDir, f)
  if (!fs.existsSync(fx)) { console.log(`${kind.padEnd(18)} SKIP no iOS fixture`); continue }
  total++
  const spec = parseSpec(JSON.parse(fs.readFileSync(path.join(specDir, f), 'utf8')))
  const fixture = JSON.parse(fs.readFileSync(fx, 'utf8'))
  let cases = 0, boxes = 0, diffs = []
  for (const c of fixture.cases) {
    cases++
    const data = new ReplayData(c.data)
    const measurer = new ReplayMeasurer(c)
    const solver = new SpecSolver(spec, { width: c.box[0], height: c.box[1] }, data, measurer, c.renderScale ?? 1)
    let got
    try { got = solver.solve() } catch (e) { diffs.push(`${c.probe}: threw ${e.message}`); continue }
    const diff = (what) => diffs.push(`${c.probe} ${what}`)
    for (const m of [...new Set([...data.misses, ...measurer.misses])].slice(0, 3)) diff(`asked what iOS never asked: ${m}`)
    if (Math.abs((c.scale ?? 1) - solver.scale) > 1e-9) diff(`fitScale ${solver.scale} ≠ ${c.scale}`)
    const byId = new Map(got.map((b) => [b.id, b]))
    for (const b of c.boxes) {
      boxes++
      const g = byId.get(b.id)
      if (!g) { diff(`${b.id} missing`); continue }
      const fr = g.frame
      for (const [k, v] of [['x', fr.x], ['y', fr.y], ['w', fr.width], ['h', fr.height]]) {
        if (Math.abs(v - b[k]) > tol) diff(`${b.id} ${k} ${v} ≠ ${b[k]}`)
      }
      if (b.text != null) {
        if (!g.text) diff(`${b.id} no text`)
        else {
          if (g.text.string !== b.text) diff(`${b.id} text '${g.text.string}' ≠ '${b.text}'`)
          if (Math.abs(g.text.size - b.size) > tol) diff(`${b.id} size ${g.text.size} ≠ ${b.size}`)
          if (g.text.lines !== b.lines) diff(`${b.id} lines ${g.text.lines} ≠ ${b.lines}`)
        }
      }
    }
    if (got.length !== c.boxes.length) diff(`box count ${got.length} ≠ ${c.boxes.length}`)
  }
  const ok = diffs.length === 0
  if (ok) pass++
  console.log(`${kind.padEnd(18)} ${ok ? 'PASS' : 'FAIL'} cases ${String(cases).padStart(2)}  boxes ${String(boxes).padStart(5)}  diffs ${String(diffs.length).padStart(4)}`)
  for (const d of diffs.slice(0, 6)) console.log('    ' + d)
}
console.log(`=== kinds passing: ${pass}/${total} ===`)
