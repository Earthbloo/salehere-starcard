// กติกาของหน้า dev/text-slots.html + dev/editable.html — ข้อความแต่ละช่องมาจากไหน · แก้ได้ไหม · ผูกกับขั้นไหน
// และตัววาดใบเดี่ยว (ตัววาดเว็บจริง + ข้อมูล fixture ชุดเดียวกับ iOS) · กรอบของข้อความอ่านจาก `__spec` ที่ตัววาดติดไว้ทุกโหนด

import { parseSpec } from '../js/spec-model.js'
import { WebMeasurer, loadFonts } from '../js/measure.js'
import { ReplayData } from '../js/replay.js'
import { Profile, WebSpecData } from '../js/data.js'
import { mountWidget } from '../js/chrome.js'
import { paintBackdrop } from '../js/backdrop.js'
import { defaultChoice, themeOf } from '../js/backdrop-tray.js'

// ── ที่มาของข้อความ ────────────────────────────────────────────────
// typed = ผู้ใช้พิมพ์เองใน Star Profile · pick = เลือกจากตัวเลือกใน Star Profile
// sys = ระบบดึงมาเอง (social ที่ผูก · insight · แคมเปญ) แก้ไม่ได้ · fixed = คำของดีไซน์ แก้ไม่ได้
const KIND = {
  typed: { name: 'พิมพ์เองได้', cls: 'typed-c' },
  pick:  { name: 'เลือกได้',    cls: 'pick-c' },
  sys:   { name: 'ระบบดึงมา',   cls: 'sys-c' },
  fixed: { name: 'ตายตัว',      cls: 'fixed-c' },
}
const ORDER = ['typed', 'pick', 'sys', 'fixed']

// ช่องเดี่ยว (`slot`) → [ที่มา, แก้ที่ไหน]
const SLOT = {
  name: ['typed', 'ชื่อ'],
  nickname: ['typed', 'ชื่อ (คำแรก)'],
  contactName: ['typed', 'ชื่อ'],
  about: ['typed', 'แนะนำตัว'],
  phone: ['typed', 'ติดต่อ · เบอร์โทร'], 'stat:phoneFmt': ['typed', 'ติดต่อ · เบอร์โทร'],
  email: ['typed', 'ติดต่อ · อีเมล'],
  lineId: ['typed', 'ติดต่อ · LINE'], 'stat:lineFlow': ['typed', 'ติดต่อ · LINE'],
  website: ['typed', 'ติดต่อ · เว็บไซต์'], 'stat:site': ['typed', 'ติดต่อ · เว็บไซต์'],
  categories: ['pick', 'สายงาน / หมวดหมู่'],
  tagline: ['pick', 'สายงาน (ต่อกันอัตโนมัติ)'],
  workArea: ['pick', 'จังหวัดรับงาน (อันแรก)'],
  'stat:creatorKind': ['pick', 'บุคคล / เพจ'],
  rateLabels: ['pick', 'เรตราคา · ประเภทงาน'],
  ratePrices: ['typed', 'เรตราคา · ราคา'],
  handle: ['sys', 'จากลิงก์ social'],
  'stat:totalFollowers': ['sys', 'ผู้ติดตามรวม (ผูก social)'],
  'stat:avgViews': ['sys', 'ยอดวิวเฉลี่ย (ผูก social)'],
  'stat:socialCount': ['sys', 'จำนวน social'],
  'stat:brandCount': ['sys', 'แคมเปญ Sale Here'], 'stat:workCount': ['sys', 'แคมเปญ Sale Here'],
  'stat:rateCount': ['sys', 'นับจากเรตราคา'],
  'stat:cardURL': ['sys', 'ลิงก์การ์ด'], 'stat:year': ['sys', 'ปีปัจจุบัน'],
  'count:places': ['sys', 'insight · จังหวัด'], 'stat:placeCount': ['sys', 'insight · จังหวัด'],
}
// ช่องในรายการ (`$field` / `{field}`) → [ที่มา, แก้ที่ไหน] · '*' = ทุกช่องของรายการนั้น
const LIST = {
  socials: { '*': ['sys', 'ผูกบัญชี social'], handle: ['sys', 'จากลิงก์ social'], name: ['sys', 'ชื่อแพลตฟอร์ม'], platformName: ['sys', 'ชื่อแพลตฟอร์ม'] },
  categories: { '*': ['pick', 'สายงาน / หมวดหมู่'] },
  rates: { '*': ['typed', 'เรตราคา · ราคา'], label: ['pick', 'เรตราคา · ช่องทาง + ประเภทงาน'], platformName: ['pick', 'เรตราคา · ช่องทาง'], unit: ['fixed', 'หน่วยตามประเภทงาน'], format: ['pick', 'เรตราคา · ประเภทงาน'] },
  rateSocials: { '*': ['typed', 'เรตราคา · ราคา'], platformName: ['pick', 'เรตราคา · ช่องทาง'], name: ['pick', 'เรตราคา · ช่องทาง'] },
  body: { '*': ['typed', 'สัดส่วน'], label: ['fixed', 'ชื่อสัดส่วน'], unit: ['typed', 'สัดส่วน · หน่วย'], kind: ['fixed', 'ชื่อสัดส่วน'] },
  avail: { '*': ['pick', 'วันเวลารับงาน'] },
  areas: { '*': ['pick', 'จังหวัดรับงาน'] },
  contacts: { '*': ['typed', 'ติดต่อ'] },
  gender: { '*': ['sys', 'insight (อัปโหลดรูป)'] },
  ages: { '*': ['sys', 'insight (อัปโหลดรูป)'] },
  places: { '*': ['sys', 'insight (อัปโหลดรูป)'] },
  works: { '*': ['sys', 'แคมเปญ Sale Here'] },
  brands: { '*': ['sys', 'แคมเปญ Sale Here'] },
}

function classify(node, list) {
  const slot = node.slot
  if (slot && slot.startsWith('$')) return fromList(list, slot.slice(1), slot)
  if (slot) {
    const key = slot.replace(/#.*$/, '')
    const hit = SLOT[slot] || SLOT[key] || (key.startsWith('stat:reach') ? ['sys', 'insight · การเข้าถึง'] : null)
    return hit ? { k: hit[0], where: hit[1], ref: slot } : { k: 'sys', where: 'ระบบ', ref: slot }
  }
  const t = node.text || node.preset || ''
  if (t.startsWith('$')) return fromList(list, t.slice(1), t)
  const m = t.match(/\{(\w+)\}/)
  if (m && m[1] !== 'i') return fromList(list, m[1], t)
  return { k: 'fixed', where: 'คำของดีไซน์', ref: t ? `"${t}"` : '' }
}
function fromList(list, field, ref) {
  const L = LIST[list] || {}
  const hit = L[field] || L['*'] || ['sys', 'ระบบ']
  return { k: hit[0], where: hit[1], ref: `${list || '?'}.${field}` }
}

// ── โจทย์ใหม่ ─────────────────────────────────────────────────────
// แก้ได้เฉพาะคำตายตัวของดีไซน์ · ข้อมูลจาก Star Profile ล็อกหมด
const VERDICT = {
  edit:  { name: 'แก้ได้',                 cls: 'edit-c' },
  lock:  { name: 'คำตายตัว · ล็อก',        cls: 'lock-c' },
  brand: { name: 'Sale Here / ระบบ · ล็อก',      cls: 'brand-c' },
  data:  { name: 'ข้อมูล Star Profile · ล็อก', cls: 'data-c' },
}
const VORDER = ['edit', 'lock', 'brand', 'data']
/** หมวดที่ล็อกทั้งใบ (แม้หัวข้อ) */
// 19 พ.ย. 2569 — คำตายตัวไหนควรแก้ได้ คิดจากมุมครีเอเตอร์ที่เข้ามาแต่งการ์ด:
//   แก้ได้  = เสียงของครีเอเตอร์ — หัวข้อของใบ + คำโปรย/ชวนคุย (อยากใช้ภาษาตัวเอง · ไทย/อังกฤษ · สายงานตัวเอง)
//   ล็อก    = คำที่บอกว่าข้อมูลคืออะไร (แก้แล้วตัวเลข/ข้อมูลข้าง ๆ สื่อผิด) · ตัวอักษรในโลโก้ · ตัวตน Sale Here · ข้อความระบบ
// คำใหม่ที่ไม่อยู่ในรายการ = "ยังไม่ได้จัด" (ล็อกไว้ก่อน ให้คนตัดสิน)
const LOCKED_CAT = {}
const SYMBOL = /^[\s@·\/,:–\-]*$/
const norm = (t) => t.trim().replace(/\s*:$/, '')
const TITLE = new Set(['รู้จักฉัน', 'เกี่ยวกับ', 'ฉัน.', 'about', 'me.', 'แนะนำตัว', 'About Me', 'รู้จัก', 'ตัวฉัน', 'ข้อมูล', 'ของฉัน',
  'PORTFOLIO', 'รูปโปรไฟล์', 'ครีเอเตอร์', 'Audience', 'Insight', 'สถิติ', 'ผู้ชม', 'สัดส่วน', 'สายงาน', 'MY Niche &', 'SPECIALITIES',
  'สายที่', 'ใช่', 'เรทรับงาน', 'เรตราคา', 'Social Media', 'MY Social', 'MEDIA STATS', 'SOCIAL CHANNEL', 'ฟีด',
  'วันเวลาและพื้นที่รับงาน', 'ช่องทางติดต่อ', 'Contact', 'ME', 'รูปผลงาน', 'Video', 'ผลงานที่ผ่านมา', 'ผลงาน', 'ล่าสุด', 'Recent', 'VIDEOGRAPHY'])
const VOICE = new Set(['รู้จักฉัน —', 'ยินดีที่ได้รู้จัก!', 'nice to meet you!', 'ทักมาทางไลน์', 'มาทำงาน', 'ด้วยกันนะ', 'สแกนเพื่อดูการ์ดเต็ม',
  'สแกนดูการ์ด', 'ใหม่!', 'เป็นครีเอเตอร์ในแบบของคุณ', 'สิ่งที่อยากบอกตัวเองตอนเริ่มต้น'])
const LABEL = new Set(['ช่วงอายุผู้ชม', 'สัดส่วนผู้ชม', 'ผู้ชมอยู่ที่ไหน', 'คนที่ตามฉันส่วนใหญ่คือ', 'อันดับ 1–', 'เมืองหลัก', 'ช่วงอายุ', 'เพศ', 'อายุ',
  'เมือง', 'เมืองหลักของผู้ติดตาม', 'อายุหลักของผู้ชม', 'เมืองหลักของผู้ชม', 'ผู้หญิง', 'LINE', 'โทร', 'เว็บ', 'เว็บไซต์', 'วันที่สะดวกรับงาน',
  'พื้นที่รับงาน', 'Short Video', 'Photo', 'Long Video', 'SHORT VIDEO', 'PHOTO', '/โพสต์', 'ผู้ติดตาม', 'ผู้ติดตามรวมทุกช่องทาง', 'วิว',
  'ชื่อเล่น', 'อยู่', 'สาย'])
const BRAND = new Set(['STAR', 'STAR · SALE HERE', 'salehere.co.th/star/', 'ผลงานที่ยืนยันแล้ว'])
const SYSTEM = new Set(['0', 'ข้อมูลตัวอย่าง', 'รอข้อมูลโพสต์'])
/** กลุ่มของคำตายตัว (ใช้ทำตารางสรุป) */
const GROUP = {
  title: { name: 'หัวข้อของใบ', edit: true },
  voice: { name: 'คำโปรย / ชวนคุย', edit: true },
  label: { name: 'ป้ายบอกว่าข้อมูลคืออะไร', edit: false },
  logo:  { name: 'ตัวอักษรในโลโก้', edit: false },
  brand: { name: 'Sale Here / ตรารับรอง', edit: false },
  system:{ name: 'ข้อความระบบตอนไม่มีข้อมูล', edit: false },
  todo:  { name: 'ยังไม่ได้จัด (เป็นหัวข้อแต่ผังไม่ได้ใส่ editable)', edit: false },
}
function groupOf(s, cat) {
  const raw = s.value.trim(), t = norm(raw)
  if (s.role === 'deco') return 'logo'
  if (cat === 'seal' || BRAND.has(raw)) return 'brand'
  if (SYSTEM.has(raw)) return 'system'
  if (s.inItem || LABEL.has(t)) return 'label'
  if (VOICE.has(raw)) return 'voice'
  if (TITLE.has(raw)) return 'title'
  return 'todo'
}
function propose(s, cat) {
  if (s.k !== 'fixed') return { v: 'data', why: 'มาจาก Star Profile / ระบบ' }
  if (!s.ref.startsWith('"')) return { v: 'data', why: 'ป้ายที่ระบบสร้างจากรายการข้อมูล' }
  if (SYMBOL.test(s.value.trim())) return null                     // สัญลักษณ์ · ไม่นับ
  // แก้ได้หรือไม่ = `editable` ในผัง (ที่มาจริง) · กลุ่มจากรายการคำ ใช้แค่บอกเหตุผล
  let g = groupOf(s, cat)
  if (s.editable && !GROUP[g].edit) g = 'title'
  if (!s.editable && GROUP[g].edit) g = 'todo'
  return { v: s.editable ? 'edit' : g === 'brand' || g === 'system' ? 'brand' : 'lock', g, why: GROUP[g].name }
}

// ── ผูกกับขั้นของ Star Profile (= rowOf ใน shared/tools/check-widgets.mjs) ─────
// ลำดับ = ลำดับแถวในหน้า Star Profile (STAR-CARD-LOCK.md §2)
const STEP = {
  kind:         { name: 'ประเภทครีเอเตอร์', c: '#0EA5E9' },
  socials:      { name: 'ช่องทางของฉัน',    c: '#EC4899' },
  rate:         { name: 'เรทรับงาน',         c: '#E11D48' },
  categories:   { name: 'สายที่ใช่',          c: '#D97706' },
  about:        { name: 'เกี่ยวกับคุณ',       c: '#059669' },
  provinces:    { name: 'พื้นที่รับงาน',      c: '#65A30D' },
  availability: { name: 'วันเวลาว่างรับงาน',  c: '#0D9488' },
  contact:      { name: 'ช่องทางติดต่อ',      c: '#2563EB' },
  insight:      { name: 'ข้อมูลผู้ติดตาม',    c: '#7C3AED' },
  body:         { name: 'สัดส่วน',            c: '#C026D3' },
  kyc:          { name: 'ยืนยันตัวตน',        c: '#DC2626' },
  work:         { name: 'ผลงานกับ Sale Here', c: '#EA580C' },
  account:      { name: 'ข้อมูลบัญชี (ไม่ล็อก)', c: '#64748B' },
}
const SORDER = Object.keys(STEP)
/** ช่องในขั้นที่รวมหลายอย่าง — บอกว่าเป็นส่วนไหนของขั้น */
const SUB = {
  about: 'แนะนำตัว', phone: 'เบอร์โทร', 'stat:phoneFmt': 'เบอร์โทร', lineId: 'LINE', 'stat:lineFlow': 'LINE',
  website: 'เว็บไซต์ (ไม่อยู่ในเงื่อนไขติ๊ก)', 'stat:site': 'เว็บไซต์ (ไม่อยู่ในเงื่อนไขติ๊ก)', email: 'อีเมล (ไม่อยู่ในเงื่อนไขติ๊ก)',
  tagline: 'ต่อจากสายที่เลือก', workArea: 'จังหวัดแรก', handle: 'จากลิงก์ social', name: 'ชื่อบัญชี', nickname: 'คำแรกของชื่อ',
}
function stepOf(s) {
  if (s.k === 'fixed' && !s.ref.includes('.')) return null
  const r = s.ref.replace(/^\$/, '').replace(/#.*$/, '')
  if (/^(name|handle|nickname|contactName)$/.test(r) || r === 'stat:cardURL') return 'account'
  if (/^(tagline|categories)/.test(r)) return 'categories'
  if (/^(workArea|areas)/.test(r)) return 'provinces'
  if (r === 'stat:creatorKind') return 'kind'
  if (/^about/.test(r)) return 'about'
  if (/^socials|stat:totalFollowers|count:socials|stat:avgViews|stat:socialCount/.test(r)) return 'socials'
  if (/^(rates|rateSocials|rateLabels|ratePrices)|stat:rateCount/.test(r)) return 'rate'
  if (/^(gender|ages|places)|stat:reach|count:places|stat:placeCount/.test(r)) return 'insight'
  if (/^(brands|works)|stat:(brandCount|workCount)/.test(r)) return 'work'
  if (/^(phone|email|lineId|website|contacts)|stat:(phoneFmt|site|lineFlow)/.test(r)) return 'contact'
  if (/^avail/.test(r)) return 'availability'
  if (/^body/.test(r)) return s.k === 'fixed' ? null : 'body'
  return null
}


const CAT = [
  ['hero', 'โปรไฟล์'], ['intro', 'แนะนำตัว'], ['tags', 'หมวดหมู่'], ['followers', 'ผู้ติดตาม'], ['audience', 'ผู้ชม'],
  ['body', 'สัดส่วน'], ['rate', 'เรตราคา'], ['availability', 'วันเวลาและพื้นที่'], ['contact', 'ติดต่อ'],
  ['verified', 'ผลงานยืนยัน'], ['photo', 'รูปผลงาน'], ['showcase', 'แผ่นโชว์ผลงาน'], ['seal', 'ตรารับรอง'],
]

/** โหลดผัง + ฟอนต์ + fixture แล้วคืนตัววาด — `render(host, kind)` · `collect(host)` → ช่องข้อความ · `fit(stage, host, w, h)` */
export async function loadStage() {
  // ── วาด ────────────────────────────────────────────────────────────
  await loadFonts('../fonts/')
  const r = await fetch('/graphql', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ query: '{ widgetSpecs { kind json } }' }) })
  const specs = Object.fromEntries((await r.json()).data.widgetSpecs.map((s) => [s.kind, parseSpec(s.json)]))
  const measurer = new WebMeasurer()
  const theme = themeOf(defaultChoice())
  const M = 12
  const fixtures = {}
  await Promise.all(Object.keys(specs).map(async (k) => {
    const fx = await fetch(`../fixtures/fixtures/${k}.json`).then((x) => (x.ok ? x.json() : null)).catch(() => null)
    fixtures[k] = fx?.cases.find((x) => x.probe === 'design') || null
  }))

  /** วาดใบหนึ่งลง `host` ขนาดจริง แล้วคืนช่องข้อความ [{k, where, ref, value, rect}] */
  function render(host, kind) {
    const spec = specs[kind]
    const W = spec.design.w, H = spec.design.h
    host.dataset.kind = kind
    host.style.cssText = `position:relative;width:${W + M * 2}px;height:${H + M * 2}px;overflow:hidden`
    paintBackdrop(host, theme, W + M * 2, H + M * 2)
    const profile = new Profile({}, {})
    const fallback = new WebSpecData({ profile, item: {}, sample: true, surface: 'glass' })
    const fc = fixtures[kind]
    const item = { id: '00000000-0000-0000-0000-000000000000', kind, x: M, y: M, w: W, h: H, surface: 'glass', border: false }
    const env = { doc: { photos: {}, owner: {}, notes: {} }, theme, profile, specs, measurer, base: '../', imageURL: (id) => `/api/images/${id}`,
      makeData: fc ? () => new ReplayData(fc.data, fallback) : () => fallback }
    try { mountWidget(host, item, { x: M, y: M, width: W, height: H }, env) } catch (e) { host.insertAdjacentHTML('beforeend', `<pre style="color:#f77">${e.message}</pre>`) }
    return host
  }

  function collect(host) {
    const base = host.getBoundingClientRect()
    const sx = base.width / host.offsetWidth || 1
    const out = []
    for (const d of host.querySelectorAll('div')) {
      const b = d.__spec
      if (!b || b.node.type !== 'text' || !b.text || !b.text.string.trim()) continue
      let list = null
      for (let p = d.parentElement; p && p !== host; p = p.parentElement) if (p.__spec?.node?.list) { list = p.__spec.node.list; break }
      const rc = d.getBoundingClientRect()
      if (rc.width < 0.5 || rc.height < 0.5) continue
      out.push({ ...classify(b.node, list), value: b.text.string, inItem: !!b.item, nodeId: b.node.id || '', role: b.node.role || '', editable: !!b.node.editable,
        rect: { x: (rc.left - base.left) / sx, y: (rc.top - base.top) / sx, w: rc.width / sx, h: rc.height / sx } })
    }
    // อ่านเรียงบน→ล่าง ซ้าย→ขวา
    out.sort((a, b) => (Math.abs(a.rect.y - b.rect.y) > 4 ? a.rect.y - b.rect.y : a.rect.x - b.rect.x))
    out.forEach((s, i) => (s.n = i + 1))
    const cat = specs[host.dataset.kind]?.widget?.category || 'intro'
    out.forEach((s) => { s.p = propose(s, cat); s.step = stepOf(s); s.sub = SUB[s.ref.replace(/#.*$/, '')] || '' })
    return out
  }


  /** ใส่ใบขนาดจริงลงกรอบ `box` ย่อให้พอดี */
  function fit(stage, inner, maxW, maxH) {
    const w = inner.offsetWidth, h = inner.offsetHeight
    const s = Math.min(maxW / w, maxH / h, 1.6)
    const sc = document.createElement('div'); sc.className = 'scaler'
    sc.style.cssText = `width:${w}px;height:${h}px;transform:scale(${s})`
    stage.style.width = `${w * s}px`; stage.style.height = `${h * s}px`
    stage.style.justifyContent = 'flex-start'; stage.style.alignItems = 'flex-start'
    sc.appendChild(inner); stage.appendChild(sc)
  }

  return { specs, render, collect, fit }
}

export { GROUP, KIND, ORDER, SLOT, LIST, classify, VERDICT, VORDER, LOCKED_CAT, propose, STEP, SORDER, SUB, stepOf, CAT }
