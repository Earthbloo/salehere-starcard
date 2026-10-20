#!/usr/bin/env node
// แปลง `theme` ของ doc การ์ดจากชื่อพาเลตต์/คู่สี → `colors: { primary, secondary? }` (20 ต.ค. 2569 รอบ 3)
//
//   node shared/tools/theme-colors-v4.mjs <file.json>…      เขียนทับไฟล์ (เทมเพลต · ตัวอย่าง API · starter cards)
//   node shared/tools/theme-colors-v4.mjs --dry <file>…     รายงานอย่างเดียว
//
// สูตรแปลงอยู่ที่ `migrateTheme` ใน sync-server/web/js/theme.js (= `LegacyTheme` ใน iOS/Android ตอนอ่าน doc เก่า)
// หา `theme` ทุกก้อนในไฟล์ (ระดับบน · ใน `snapshot` · ใน array) แล้วแปลงให้หมด

import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { migrateTheme } from '../../sync-server/web/js/theme.js'

const dry = process.argv.includes('--dry')
const files = process.argv.slice(2).filter((a) => !a.startsWith('--'))
if (!files.length) { console.error('ใส่ไฟล์ JSON อย่างน้อยหนึ่งไฟล์'); process.exit(2) }

const LEGACY = ['palette', 'duo', 'duoFlipped', 'customHue', 'customSat', 'customBri', 'brightness', 'hueShift', 'inkAuto', 'corner', 'strip']
const isTheme = (o) => o && typeof o === 'object' && !Array.isArray(o) && ('palette' in o || 'colors' in o) && ('ink' in o || 'backdrop' in o)

function walk(o, hit) {
  if (Array.isArray(o)) { o.forEach((x) => walk(x, hit)); return }
  if (!o || typeof o !== 'object') return
  for (const [k, v] of Object.entries(o)) {
    if (k === 'theme' && isTheme(v)) { o.theme = hit(v); continue }
    walk(v, hit)
  }
}

for (const f of files) {
  const p = path.resolve(f)
  const doc = JSON.parse(fs.readFileSync(p, 'utf8'))
  let n = 0, before = []
  walk(doc, (t) => {
    const had = LEGACY.filter((k) => k in t)
    const out = migrateTheme(t)
    if (had.length || !t.colors) { n++; before.push(`${had.join(',') || '(no colors)'} → ${JSON.stringify(out.colors)}`) }
    return out
  })
  console.log(`${dry ? '[dry] ' : ''}${path.relative(process.cwd(), p)} · theme ที่แปลง ${n}`)
  for (const b of before) console.log('  ', b)
  if (!dry && n) fs.writeFileSync(p, JSON.stringify(doc, null, 2) + '\n')
}
