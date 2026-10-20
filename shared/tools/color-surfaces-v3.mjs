#!/usr/bin/env node
// ยุบ "พื้น" ของสีจาก 6 → 3 (20 ต.ค. 2569 รอบ 2): card · light · dark
//   plate → dark · paper/kit/pop/scrap → light · ยกเว้นชุด Canva แบบกลางคืน (kit*Night = แผ่นมืด) → dark
//   node ที่มี "on" แปลงตามตารางเดียวกัน · "on": "card" ที่ซ้ำกับพื้นตั้งต้นถูกถอด
//
//   node shared/tools/color-surfaces-v3.mjs --dry | (ไม่มี flag = เขียนทับ shared/WidgetSpecs/*.json)

import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..')
const specDir = path.join(root, 'shared/WidgetSpecs')
const dry = process.argv.includes('--dry')
const MAP = { card: 'card', plate: 'dark', paper: 'light', kit: 'light', pop: 'light', scrap: 'light', light: 'light', dark: 'dark' }

const report = { files: 0, widget: {}, node: {} }
for (const file of fs.readdirSync(specDir).filter(f => f.endsWith('.json')).sort()) {
  const p = path.join(specDir, file)
  const spec = JSON.parse(fs.readFileSync(p, 'utf8'))
  const night = spec.widget?.kit?.look === 'night'
  const def = night ? 'dark' : (MAP[spec.widget.on ?? 'card'] ?? 'card')
  if (def === 'card') delete spec.widget.on; else spec.widget.on = def
  report.widget[def] = (report.widget[def] ?? 0) + 1
  const walk = (n) => {
    if (Array.isArray(n)) { n.forEach(walk); return }
    if (!n || typeof n !== 'object') return
    if (typeof n.type === 'string' && typeof n.on === 'string') {
      const s = MAP[n.on] ?? 'card'
      if (s === def) delete n.on; else { n.on = s; report.node[s] = (report.node[s] ?? 0) + 1 }
    }
    for (const [k, v] of Object.entries(n)) if (k !== 'widget' && typeof v === 'object') walk(v)
  }
  walk([spec.root, spec.variants ?? []])
  report.files++
  if (!dry) fs.writeFileSync(p, JSON.stringify(spec, null, 1) + '\n')
}
console.log(`${dry ? '[dry] ' : ''}ไฟล์ ${report.files} · widget.on`, report.widget, '· node on', report.node)
