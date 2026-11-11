#!/usr/bin/env node
// ตรวจกติกา "Widget = ข้อมูลล้วน" (shared/docs/WIDGET-CATEGORY-PLAN.md ข้อ 2.1 · 5 · 9) — ผ่าน = exit 0
//
//   node shared/tools/check-widgets.mjs            ตรวจทั้งหมด
//   node shared/tools/check-widgets.mjs --usage    พิมพ์ field ที่แต่ละ widget อ่าน (ตามหมวด)
//   node shared/tools/check-widgets.mjs --write-requires   เขียน `widget.requires` ใหม่จาก binding (หลังแก้ผัง)
//
// 1. ไม่มีชื่อ widget ในโค้ด iOS / Android / เว็บ — ชื่อ = `kind` ของทุกไฟล์ผัง + `widget.replaces` (ข้ามบรรทัดคอมเมนต์)
// 2. ทุกไฟล์ผังมีบล็อก `widget` ที่มี `title` + `category` ที่แอปรู้จัก · คีย์ในบล็อกต้องอยู่ในรายการที่แอปอ่าน · ไม่มี `like`
// 3. widget อ่านได้เฉพาะ field ใน Model ของหมวดตัวเอง (`shared/category-models.json`) — เกิน = error
// 4. `widget.requires` (ล็อกต่อวิดเจ็ต) อยู่ใน enum 12 ค่า และตรงกับที่คิดจาก binding — ไม่ตรง = error
// 5. `removeBg` อยู่ได้แค่บนโหนด image ที่ดึงช่องรูปครีเอเตอร์ (photo 1–3) และต้องเป็น true

import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..')
const specDir = path.join(root, 'shared/WidgetSpecs')
const models = JSON.parse(fs.readFileSync(path.join(root, 'shared/category-models.json'), 'utf8'))
const errors = []

// คีย์ของบล็อก `widget` ที่ทั้งสามแพลตฟอร์มอ่าน (= `WidgetSpec.Widget` ของ iOS/Android · `kindInfo` ของเว็บ)
const WIDGET_KEYS = new Set(['title', 'category', 'symbol', 'size', 'order', 'tier', 'ownSurface', 'ownBorder', 'surfaces',
  'surfaceNames', 'border', 'photo', 'keepAspect', 'fullBleed', 'resize', 'controls', 'kit',
  'skin', 'on', 'stamp', 'stampAt', 'motion', 'pinned', 'replaces', 'requires'])
// `widget.requires` — ใบนี้ล็อกจนกว่าทุกค่าจะผ่าน (ชื่อ = แถวติ๊กถูกใน Star Profile · ลำดับตามนี้เสมอ) · WIDGET-SPEC.md §3.3d
const REQUIRES = ['kind', 'socials', 'categories', 'about', 'provinces', 'availability', 'contact', 'kyc', 'insight', 'body', 'rate', 'work']
const ENUMS = {
  tier: ['verified', 'connected', 'personal'], skin: ['paper', 'glass'], on: ['card', 'light', 'dark'], stamp: ['followers', 'insight', 'work'],
  motion: ['deep', 'mid', 'light', 'anchored'],
}
const SURFACES = ['glass', 'dim', 'clear', 'pane']
const KIT_LOOKS = ['purple', 'cream', 'gingham', 'night', 'mac']
const KIT_TYPES = ['checks', 'pick', 'segment', 'switch', 'stepper']
const KIT_SOURCES = ['socials', 'shownSocials', 'rates', 'ratePlatforms', 'categories']

// ผังแบ่งโฟลเดอร์ย่อยตามหมวดถาดของ API (`<NN-หมวด>/<kind>.json`) → กวาดทุกชั้น · คืน path เต็ม เรียงตามชื่อไฟล์ (= kind)
const specFiles = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => e.isDirectory() ? specFiles(path.join(d, e.name)) : e.name.endsWith('.json') ? [path.join(d, e.name)] : [])
const listSpecs = (d) => specFiles(d).sort((a, b) => path.basename(a) < path.basename(b) ? -1 : 1)
const specs = listSpecs(specDir)
  .map((p) => ({ file: path.basename(p), path: p, spec: JSON.parse(fs.readFileSync(p, 'utf8')) }))

// MARK: 2 · บล็อก widget

for (const { file, spec } of specs) {
  const w = spec.widget
  const at = `${file}: widget`
  if (spec.kind + '.json' !== file) errors.push(`${file}: kind "${spec.kind}" ไม่ตรงชื่อไฟล์`)
  if (!w) { errors.push(`${at} ไม่มีบล็อก`); continue }
  if (!w.title) errors.push(`${at}.title ว่าง`)
  if (!models.categories[w.category]) errors.push(`${at}.category "${w.category}" ไม่ใช่หมวดที่แอปรู้จัก`)
  for (const k of Object.keys(w)) if (!WIDGET_KEYS.has(k)) errors.push(`${at}.${k} — คีย์ที่แอปไม่อ่าน${k === 'like' ? ' (ห้ามยืมนิสัยด้วยชื่อ)' : ''}`)
  for (const [k, vals] of Object.entries(ENUMS)) if (w[k] != null && !vals.includes(w[k])) errors.push(`${at}.${k} "${w[k]}" ไม่อยู่ใน ${vals.join('/')}`)
  for (const s of w.surfaces || []) if (!SURFACES.includes(s)) errors.push(`${at}.surfaces "${s}"`)
  for (const s of Object.keys(w.surfaceNames || {})) if (!SURFACES.includes(s)) errors.push(`${at}.surfaceNames "${s}"`)
  if (w.stampAt && !['ink', 'dark', 'light'].includes(w.stampAt.tone)) errors.push(`${at}.stampAt.tone "${w.stampAt.tone}"`)
  for (const k of Object.keys(w.kit || {})) if (k !== 'look') errors.push(`${at}.kit.${k} — ในบล็อก kit มีได้แค่ look (ตัวเลือกอยู่ที่ widget.controls)`)
  if (w.kit && w.kit.look != null && !KIT_LOOKS.includes(w.kit.look)) errors.push(`${at}.kit.look "${w.kit.look}" ไม่อยู่ใน ${KIT_LOOKS.join('/')}`)
  for (const c of w.controls || []) {
    if (!KIT_TYPES.includes(c.type)) errors.push(`${at}.controls type "${c.type}"`)
    if (typeof c.items === 'string' && !KIT_SOURCES.includes(c.items)) errors.push(`${at}.controls items "${c.items}"`)
    // ทุกตัวเลือกต้องบอกคีย์ที่เก็บใน `options` — `opt` หรือธงแยก (`flags`)
    if (!c.opt && !c.flags) errors.push(`${at}.controls "${c.label}" ไม่มี opt`)
  }
}

// MARK: 3 · field ที่ widget อ่าน ⊆ Model ของหมวด

const SKIP = new Set(['i', 'rank', 'rank2', 'max', 'sum'])
function usage(spec) {
  const used = new Set()
  const field = (list, f) => { if (list && f && !SKIP.has(f)) { used.add('list:' + list); used.add(`list:${list}.${f}`) } }
  const slot = (v) => {
    if (/^(stat|count):/.test(v)) used.add(v)
    else used.add('slot:' + v.replace(/#(\$i|\d+)$/, '#N'))
  }
  const cond = (str, list) => {
    for (const t0 of str.split(/[&|]/)) {
      const t = t0.trim().replace(/^!/, '')
      if (!t) continue
      if (t.startsWith('list:')) used.add('list:' + t.slice(5).replace(/[<>=].*/, ''))
      else if (t.startsWith('has:')) slot(t.slice(4))
      else if (t.startsWith('$')) field(list, t.slice(1).replace(/[<>=].*/, ''))
      else if (t.startsWith('hidden:')) for (const m of t.matchAll(/\$(\w+)/g)) field(list, m[1])
      else if (/^(owner\.verified|stamped|cutout)/.test(t)) used.add('flag:' + t.replace(/[<>=].*/, ''))
    }
  }
  const walk = (n, list) => {
    if (Array.isArray(n)) return n.forEach((x) => walk(x, list))
    if (!n || typeof n !== 'object') return
    const inner = typeof n.list === 'string' ? n.list : list
    if (typeof n.list === 'string') used.add('list:' + n.list)
    if (typeof n.slot === 'string') n.slot.startsWith('$') ? field(list, n.slot.slice(1)) : slot(n.slot)
    if (n.photo !== undefined) typeof n.photo === 'string' && n.photo.startsWith('$') ? field(list, n.photo.slice(1)) : used.add('photo')
    if (typeof n.photoRef === 'string') field(list, n.photoRef.replace('$', ''))
    if (typeof n.text === 'string') for (const m of n.text.matchAll(/\{(\w+)\}/g)) field(list, m[1])
    for (const k of ['icon', 'pct', 'src', 'fill', 'color', 'tint']) if (typeof n[k] === 'string') for (const m of n[k].matchAll(/\$(\w+)/g)) field(list, m[1])
    for (const k of ['sort', 'group']) if (typeof n[k] === 'string') for (const part of n[k].split(',')) field(inner, part.trim().split(' ')[0])
    if (typeof n.if === 'string') cond(n.if, list)
    if (typeof n.where === 'string') cond(n.where, inner)
    for (const [k, v] of Object.entries(n)) if (v && typeof v === 'object') walk(v, k === 'each' || k === 'children' ? inner : list)
  }
  walk(spec.root)
  for (const v of spec.variants || []) { if (typeof v.when === 'string') cond(v.when); walk(v.root) }
  return used
}

const report = {}
for (const { file, spec } of specs) {
  const cat = spec.widget?.category
  const m = models.categories[cat]
  if (!m) continue
  const ok = new Set([...models.base, ...(m.fields || []), ...(m.borrow || [])])
  const used = [...usage(spec)].sort()
  ;(report[cat] = report[cat] || []).push([spec.kind, used])
  for (const u of used) if (!ok.has(u)) errors.push(`${file}: อ่าน "${u}" ซึ่งไม่อยู่ใน Model ของหมวด ${cat}`)
}

// MARK: 4 · `widget.requires` = แถวที่ข้อมูลของใบนี้มาจาก (คิดจาก binding)
//
// เนื้อหาที่ใบอ่าน → ชื่อแถว · ข้อมูลบัญชี (ชื่อ · @handle · ชื่อเล่น) / ลิงก์การ์ด ไม่นับ
// รูป: ช่อง (เลข mod 12) 1–3 = รูปครีเอเตอร์ ไม่มีก็ avatar บัญชี → ไม่นับ · ช่องอื่น = รูปผลงาน → about
// อ่านแค่ใน `if` / `where` / `when` (ซ่อน-โชว์บางส่วน) ไม่นับ · works/brands ที่ทุกจุดดึงแค่ `limit: 1` (ไอคอนประดับ) ไม่นับ
// หมวด seal = kyc เสมอ

function rowOf(ref) {
  const r = ref.replace(/^(list|slot):/, '')
  if (/^(name|handle|nickname)$/.test(r) || ref === 'flag:cutout' || r === 'stat:cardURL') return null
  if (/^(tagline|categories)/.test(r)) return 'categories'
  if (/^(workArea|areas)/.test(r)) return 'provinces'
  if (r === 'stat:creatorKind') return 'kind'
  if (/^about/.test(r)) return 'about'
  if (/^socials|stat:totalFollowers|count:socials/.test(r) || ref === 'flag:stamped') return 'socials'
  if (/^(rates|rateSocials|rateLabels|ratePrices)|stat:rateCount/.test(r)) return 'rate'
  if (/^(gender|ages|places)|stat:reach|count:places/.test(r)) return 'insight'
  if (/^(brands|works)|stat:(brandCount|workCount)/.test(r)) return 'work'
  if (/^(phone|email|lineId|website|contacts)|stat:(phoneFmt|site|lineFlow)/.test(r)) return 'contact'
  if (/^avail/.test(r)) return 'availability'
  if (/^body/.test(r)) return 'body'
  if (ref === 'flag:owner.verified') return 'kyc'
  return '?' + ref
}

function requiresOf(spec) {
  const hard = new Set(), soft = new Set()
  let into = hard
  const add = (ref) => { const row = rowOf(ref); if (row) into.add(row) }
  const field = (list, f) => { if (list && f && !SKIP.has(f)) { add('list:' + list); add(`list:${list}.${f}`) } }
  const slot = (v) => add(/^(stat|count):/.test(v) ? v : 'slot:' + v)
  const cond = (str, list) => {
    const prev = into; into = soft
    for (const t0 of str.split(/[&|]/)) {
      const t = t0.trim().replace(/^!/, '')
      if (!t) continue
      if (t.startsWith('list:')) add('list:' + t.slice(5).replace(/[<>=].*/, ''))
      else if (t.startsWith('has:')) slot(t.slice(4))
      else if (t.startsWith('$')) field(list, t.slice(1).replace(/[<>=].*/, ''))
      else if (t.startsWith('hidden:')) for (const m of t.matchAll(/\$(\w+)/g)) field(list, m[1])
      else if (/^(owner\.verified|stamped|cutout)/.test(t)) add('flag:' + t.replace(/[<>=].*/, ''))
    }
    into = prev
  }
  const accent = new Map() // works/brands → ทุกจุดเป็น limit 1 ไหม
  const walk = (n, list) => {
    if (Array.isArray(n)) return n.forEach((x) => walk(x, list))
    if (!n || typeof n !== 'object') return
    const inner = typeof n.list === 'string' ? n.list : list
    if (typeof n.list === 'string') {
      if (n.list === 'works' || n.list === 'brands') accent.set(n.list, (accent.get(n.list) ?? true) && n.limit === 1)
      add('list:' + n.list)
    }
    if (typeof n.slot === 'string') n.slot.startsWith('$') ? field(list, n.slot.slice(1)) : slot(n.slot)
    if (typeof n.photo === 'number') { const c = ((n.photo % 12) + 12) % 12; if (c < 1 || c > 3) into.add('about') }
    else if (typeof n.photo === 'string' && n.photo.startsWith('$')) field(list, n.photo.slice(1))
    // photoRef → ช่องรูปจากฟิลด์ของรายการ: works.workPhoto = ช่อง 0 = รูปผลงาน (ตอนไม่มีปก `cover`) → about
    if (typeof n.photoRef === 'string') { field(list, n.photoRef.replace('$', '')); into.add('about') }
    if (typeof n.text === 'string') for (const m of n.text.matchAll(/\{(\w+)\}/g)) field(list, m[1])
    for (const k of ['icon', 'pct', 'src', 'fill', 'color', 'tint']) if (typeof n[k] === 'string') for (const m of n[k].matchAll(/\$(\w+)/g)) field(list, m[1])
    for (const k of ['sort', 'group']) if (typeof n[k] === 'string') for (const part of n[k].split(',')) field(inner, part.trim().split(' ')[0])
    if (typeof n.if === 'string') cond(n.if, list)
    if (typeof n.where === 'string') cond(n.where, inner)
    for (const [k, v] of Object.entries(n)) if (v && typeof v === 'object') walk(v, k === 'each' || k === 'children' ? inner : list)
  }
  walk(spec.root)
  for (const v of spec.variants || []) { if (typeof v.when === 'string') cond(v.when); walk(v.root) }
  if (spec.widget?.category === 'seal') hard.add('kyc')
  // เรทอยู่บนช่องทางที่ผูก — มีเรทต้องมีช่องทางก่อนเสมอ
  if (hard.has('rate')) hard.add('socials')
  if ([...accent.values()].length && [...accent.values()].every(Boolean)) hard.delete('work')
  const unknown = [...hard, ...soft].filter((x) => x.startsWith('?'))
  return { requires: REQUIRES.filter((x) => hard.has(x)), unknown }
}

const writeRequires = process.argv.includes('--write-requires')
let written = 0
for (const { file, path: specPath, spec } of specs) {
  const w = spec.widget
  if (!w) continue
  const { requires, unknown } = requiresOf(spec)
  for (const u of unknown) errors.push(`${file}: อ่าน "${u.slice(1)}" แต่ไม่รู้ว่ามาจากแถวไหน — เพิ่มใน rowOf()`)
  if (writeRequires && JSON.stringify(w.requires) !== JSON.stringify(requires)) {
    // ใส่ต่อจาก category · คงรูปแบบไฟล์เดิม (เว้น 1 ช่อง · ขึ้นบรรทัดท้ายถ้าเดิมมี)
    const p = specPath, raw = fs.readFileSync(p, 'utf8')
    const entries = Object.entries(w).filter(([k]) => k !== 'requires')
    const at = entries.findIndex(([k]) => k === 'category') + 1
    entries.splice(at, 0, ['requires', requires])
    spec.widget = Object.fromEntries(entries)
    fs.writeFileSync(p, JSON.stringify(spec, null, 1) + (raw.endsWith('\n') ? '\n' : ''))
    written++
    continue
  }
  const at = `${file}: widget.requires`
  if (!Array.isArray(w.requires)) { errors.push(`${at} ไม่มี — ควรเป็น ${JSON.stringify(requires)} (node shared/tools/check-widgets.mjs --write-requires)`); continue }
  for (const r of w.requires) if (!REQUIRES.includes(r)) errors.push(`${at} "${r}" ไม่อยู่ใน ${REQUIRES.join('/')}`)
  if (JSON.stringify(w.requires) !== JSON.stringify(requires)) errors.push(`${at} ${JSON.stringify(w.requires)} ≠ จาก binding ${JSON.stringify(requires)}`)
}
if (writeRequires) console.log(`เขียน widget.requires ${written} ไฟล์`)

// MARK: 5 · `removeBg` บนโหนดรูป — ใช้ได้เฉพาะโหนด image ที่ดึงช่องรูปครีเอเตอร์ (ช่อง mod 12 = 1–3)

for (const { file, spec } of specs) {
  const walk = (n, where) => {
    if (Array.isArray(n)) return n.forEach((x, i) => walk(x, `${where}[${i}]`))
    if (!n || typeof n !== 'object') return
    if ('removeBg' in n) {
      const c = typeof n.photo === 'number' ? ((n.photo % 12) + 12) % 12 : -1
      if (n.removeBg !== true) errors.push(`${file}${where}: removeBg ต้องเป็น true (ไม่ต้องลบพื้นหลัง = ไม่ใส่ field)`)
      if (n.type !== 'image' || c < 1 || c > 3) errors.push(`${file}${where}: removeBg ใช้ได้กับ image ที่ photo ช่อง 1–3 (รูปครีเอเตอร์) เท่านั้น`)
    }
    for (const [k, v] of Object.entries(n)) if (v && typeof v === 'object') walk(v, `${where}.${k}`)
  }
  walk(spec.root, '.root')
  for (const [i, v] of (spec.variants || []).entries()) walk(v.root, `.variants[${i}].root`)
}

// MARK: 1 · ไม่มีชื่อ widget ในโค้ด

const names = new Set()
for (const { spec } of specs) { names.add(spec.kind); for (const r of spec.widget?.replaces || []) names.add(r) }
const nameRx = new RegExp(`\\b(${[...names].join('|')})\\b`)
const codeRoots = [
  ['StarCard/StarCard', '.swift'],
  ['StarCardAndroid/app/src/main', '.kt'],
  ['sync-server/web/js', '.js'],
]
const walkFiles = (dir, ext, out = []) => {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name)
    if (e.isDirectory()) walkFiles(p, ext, out)
    else if (p.endsWith(ext)) out.push(p)
  }
  return out
}
for (const [rel, ext] of codeRoots) {
  const dir = path.join(root, rel)
  if (!fs.existsSync(dir)) continue
  for (const f of walkFiles(dir, ext)) {
    let block = false
    fs.readFileSync(f, 'utf8').split('\n').forEach((line, i) => {
      let code = line
      if (block) { const end = code.indexOf('*/'); if (end < 0) return; code = code.slice(end + 2); block = false }
      code = code.replace(/\/\*.*?\*\//g, '')
      const open = code.indexOf('/*'); if (open >= 0) { code = code.slice(0, open); block = true }
      code = code.replace(/\/\/.*$/, '')
      const m = code.match(nameRx)
      if (m) errors.push(`${path.relative(root, f)}:${i + 1}: ชื่อ widget "${m[1]}" ในโค้ด`)
    })
  }
}

// MARK: ผล

if (process.argv.includes('--usage')) {
  for (const [cat, rows] of Object.entries(report)) {
    console.log(`\n## ${cat}`)
    for (const [k, u] of rows) console.log(`  ${k}: ${u.join(' ')}`)
  }
}
if (errors.length) {
  console.error(errors.map((e) => '✗ ' + e).join('\n'))
  console.error(`\n${errors.length} error(s)`)
  process.exit(1)
}
console.log(`✓ ${specs.length} widget · ไม่มีชื่อ widget ในโค้ด 3 แพลตฟอร์ม · ทุกใบอ่านเฉพาะ field ใน Model ของหมวด · requires ตรง binding · removeBg ถูกที่`)
