// แบ่ง shared/WidgetSpecs/ เป็นโฟลเดอร์ย่อยตามหมวดถาดของ API (`starCardWidgetCategories`)
//   ข้อมูลหมวด = shared/widget-categories.api.json (ดึงใหม่: shared/tools/fetch-widget-categories.sh
//   หรือคัดจาก log ของ salehere-ios DEBUG ตอนเปิดหน้า Star Card — response "StarCardWidgetCategories")
//   node shared/tools/split-widget-specs.mjs         ย้ายไฟล์ (git mv) · รันซ้ำได้ — ไฟล์ที่อยู่ถูกที่แล้วไม่ขยับ
//   node shared/tools/split-widget-specs.mjs --dry   ดูอย่างเดียว
// ชื่อโฟลเดอร์ = <sequence 2 หลัก>-<ชื่อหมวดภาษาไทยตาม API> เช่น 01-โปรไฟล์ (ผู้ใช้ขอชื่อไทย 11 พ.ย. 2569) · kind ที่ API ไม่มี → _unassigned/
// เปลี่ยนชื่อหมวดใน API แล้วรันใหม่ = ย้ายไปโฟลเดอร์ชื่อใหม่ โฟลเดอร์เก่าที่ว่างถูกลบ
// หมวดที่ไม่มี widget (เช่น แบรนด์) ไม่สร้างโฟลเดอร์
// ทุกตัวอ่านผัง (iOS / Android / sync-server / tools) กวาดโฟลเดอร์ย่อยแล้ว — ชื่อโฟลเดอร์ไม่มีผลกับการวาด ชื่อไฟล์ = kind เหมือนเดิม
import fs from 'node:fs'
import path from 'node:path'
import { execFileSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..')
const specDir = path.join(root, 'shared/WidgetSpecs')
const dry = process.argv.includes('--dry')

// ชื่อเป็น NFC · ตัด / และอักขระที่ใช้เป็นชื่อไฟล์ไม่ได้ · ช่องว่าง → -
const folderName = (c) => `${String(c.sequence).padStart(2, '0')}-${c.name.normalize('NFC').trim().replace(/[\/:*?"<>|]/g, '').replace(/\s+/g, '-')}`

const cats = JSON.parse(fs.readFileSync(path.join(root, 'shared/widget-categories.api.json'), 'utf8'))
const target = {}
for (const c of cats) {
  const folder = folderName(c)
  for (const w of c.widgets) target[w.kind] = folder
}

const walk = (dir, out = []) => {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name)
    if (e.isDirectory()) walk(p, out)
    else if (e.name.endsWith('.json')) out.push(p)
  }
  return out
}

const tracked = new Set(execFileSync('git', ['ls-files', 'shared/WidgetSpecs'], { cwd: root, encoding: 'utf8' }).split('\n').filter(Boolean).map((f) => path.join(root, f)))
let moved = 0
const count = {}
for (const p of walk(specDir).sort()) {
  const kind = path.basename(p, '.json')
  const folder = target[kind] || '_unassigned'
  count[folder] = (count[folder] || 0) + 1
  const dest = path.join(specDir, folder, kind + '.json')
  if (p === dest) continue
  moved++
  console.log(`${path.relative(specDir, p)} → ${path.relative(specDir, dest)}`)
  if (dry) continue
  fs.mkdirSync(path.dirname(dest), { recursive: true })
  if (tracked.has(p)) execFileSync('git', ['mv', p, dest], { cwd: root })
  else fs.renameSync(p, dest)
}
// โฟลเดอร์ที่ว่างแล้ว (หมวดเปลี่ยนชื่อ / ย้ายออกหมด) ลบทิ้ง
if (!dry) for (const e of fs.readdirSync(specDir, { withFileTypes: true })) {
  const d = path.join(specDir, e.name)
  if (e.isDirectory() && fs.readdirSync(d).filter((f) => f !== '.DS_Store').length === 0) fs.rmSync(d, { recursive: true })
}
for (const k of Object.keys(target)) if (!fs.existsSync(path.join(specDir, target[k], k + '.json')) && !dry) console.log(`⚠︎ API มี ${k} แต่ไม่มีไฟล์ผัง`)
console.log(`${dry ? '(dry) ' : ''}ย้าย ${moved} ไฟล์`)
console.log(Object.entries(count).sort().map(([f, n]) => `  ${f}: ${n}`).join('\n'))
