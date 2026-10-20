#!/usr/bin/env node
// แผ่นของใบที่เคยมีสองสาขา (`papered & !duo` = กระดาษสีตายตัว · `papered & duo` = แผ่นเข้ม) → สาขาเดียว `papered` ที่ทาสี `bg` ของพื้นตัวเอง
// (20 ต.ค. 2569: บนการ์ดคู่สี สาขา duo วาดแผ่นเข้มแต่ตัวหนังสือใช้หมึกของพื้น light → หายทั้งใบ · กระดาษ hex ตายตัวไม่ตามธีม)
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url'
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..')
const dir = path.join(root, 'shared/WidgetSpecs'); const dry = process.argv.includes('--dry')
let removed = 0, kept = 0
const isSheetColor = v => typeof v === 'string' && (v.startsWith('#') || v === 'white')
function walk(n, parent, key) {
  if (Array.isArray(n)) { for (let i = n.length - 1; i >= 0; i--) walk(n[i], n, i); return }
  if (!n || typeof n !== 'object') return
  if (typeof n.type === 'string' && typeof n.if === 'string' && /(^|&\s*)duo(\s*&|$)/.test(n.if)) {
    if (Array.isArray(parent)) parent.splice(key, 1); else delete parent[key]
    removed++; return
  }
  if (typeof n.type === 'string' && typeof n.if === 'string' && /!duo/.test(n.if)) {
    n.if = n.if.split('&').map(s => s.trim()).filter(s => s !== '!duo').join(' & ') || undefined
    if (n.if === undefined) delete n.if
    if (isSheetColor(n.fill)) n.fill = 'bg'
    if (isSheetColor(n.platePattern)) n.platePattern = 'bg'
    if (!n.on && typeof n.if === 'string' && n.if.includes('ink.light')) n.on = 'light'
    kept++
  }
  for (const [k, v] of Object.entries(n)) if (k !== 'widget' && typeof v === 'object') walk(v, n, k)
}
for (const f of fs.readdirSync(dir).filter(f => f.endsWith('.json')).sort()) {
  const p = path.join(dir, f); const s = JSON.parse(fs.readFileSync(p, 'utf8'))
  const before = JSON.stringify(s); walk([s.root, s.variants ?? []], null, null)
  if (JSON.stringify(s) !== before) { console.log('·', f); if (!dry) fs.writeFileSync(p, JSON.stringify(s, null, 1) + '\n') }
}
console.log(`${dry ? '[dry] ' : ''}ลบสาขา duo ${removed} โหนด · แก้สาขา !duo ${kept} โหนด`)
