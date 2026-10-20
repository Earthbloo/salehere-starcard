// ถาด "พื้นหลัง" ของแอปบนเว็บ (= `backdropTray` ใน Views/CardScreen.swift): แบบพื้น · สี (สีของฉัน + สำเร็จรูป) · โทน (เฉพาะคู่สี: เข้ม/อ่อน)
//
// ใช้ร่วมกันระหว่างหน้าทดสอบ (dev/gallery.html) กับแคตตาล็อก (shared/docs/widget-catalog.html)
// ค่าที่เลือก (`choice`) คือสิ่งที่ doc เก็บจริง: `colors.primary` / `colors.secondary` (hex) + แบบพื้น + โทน
// พาเลตต์/คู่สีสำเร็จรูปเป็นแค่ปุ่มลัดที่เขียน hex — API ไม่รู้จักชื่อพวกนั้น (20 ต.ค. 2569)

import { makeTheme, PRESETS, DUO_PRESETS, DEFAULT_PRIMARY, css, hexOf, hex, autoInkOf } from './theme.js'

/** ธีมตั้งต้นของตัวส่งออก iOS (`WidgetMatrixExport.baseTheme`) — ภาพ iOS ในแคตตาล็อก/ตู้คือธีมนี้ */
export const BASE = { colors: { primary: DEFAULT_PRIMARY }, ink: 'night', backdrop: 'solid' }
/** ลำดับคู่สีในถาด (= `ColorDuo.all`) */
export const DUO_IDS = ['indigo', 'ink', 'field', 'cocoa', 'teal', 'plum', 'merlot', 'cordovan', 'cobalt', 'clay', 'acid']

/** ค่าที่ผู้ใช้เลือก = ส่วนของ `theme` ใน doc ที่ถาดพื้นหลังแตะ · `secondary` มี = การ์ดสองสี */
export const defaultChoice = () => ({ backdrop: 'solid', primary: DEFAULT_PRIMARY, secondary: null, tone: 'dark' })
export const isDefault = (c) => c.backdrop === 'solid' && (c.primary || '').toUpperCase() === DEFAULT_PRIMARY && !c.secondary && c.tone === 'dark'
/** สรุปสั้น ๆ ไว้โชว์ว่าใบนี้ใช้สีอะไร */
export const describe = (c) => `${c.backdrop === 'gradient' ? 'ไล่เฉด' : 'สีเดียว'} · ${c.primary}${c.secondary ? ` + ${c.secondary} · ${c.tone === 'dark' ? 'เข้ม' : 'อ่อน'}` : ''}`

/** `theme` ของ doc จากค่าที่เลือก (= สิ่งที่ API เก็บ) — โทนของการ์ดสองสีอยู่ที่ลำดับสี ไม่ใช่ฟิลด์แยก */
export function docTheme(c) {
  const colors = { primary: c.primary }
  if (c.secondary) colors.secondary = c.secondary
  // คู่สี: โทน (เข้ม/อ่อน) = `ink` ตัดสินว่าสีไหนขึ้นเป็นพื้น · สีเดียว: ไม่มีโทน หมึกเลือกเองจากความสว่างของพื้น (= `autoInk`)
  return { colors, ink: c.secondary ? (c.tone === 'dark' ? 'night' : lightInkOf(c.primary)) : autoInkOf(c.primary), backdrop: c.backdrop }
}
/** ฝั่งสว่างของสีนี้ (= `CardTheme.lightInk`): พื้นที่ยังมีสีอยู่มากได้ถ่านอาบเฉด (mist) ไม่งั้นกระดาษ */
function lightInkOf(primary) { return makeTheme({ colors: { primary } }).lightInk }
/** ธีมจริงจากค่าที่เลือก */
export function themeOf(c) { return makeTheme(docTheme(c)) }

/** CSS ของถาด — ใส่ครั้งเดียวต่อหน้า (สีกลาง ๆ ให้เข้าได้ทั้งหน้ามืดและสว่าง) */
export const TRAY_CSS = `
.bt { display:flex; flex-direction:column; gap:8px; background:#1c1c22; color:#ddd; border-radius:12px; padding:10px 12px; font:12px system-ui,sans-serif; }
.bt .row { display:flex; align-items:center; gap:10px; flex-wrap:wrap; }
.bt .lbl { color:rgba(255,255,255,.45); font-size:10.5px; font-weight:600; min-width:34px; }
.bt .seg { display:inline-flex; background:rgba(255,255,255,.08); border-radius:999px; padding:2px; }
.bt .seg button { border:0; background:transparent; color:rgba(255,255,255,.78); font:600 12px system-ui; padding:5px 12px; border-radius:999px; cursor:pointer; }
.bt .seg button.on { background:rgba(255,255,255,.92); color:rgba(0,0,0,.86); }
.bt .dots { display:flex; gap:9px; align-items:center; overflow-x:auto; padding:3px 2px; scrollbar-width:none; }
.bt .dot { width:30px; height:30px; border-radius:50%; border:0.5px solid rgba(255,255,255,.2); cursor:pointer; flex:0 0 auto; padding:0; background:#888; transition:transform .15s; position:relative; }
.bt .dot.on { border:2px solid rgba(255,255,255,.95); transform:scale(1.1); }
.bt .dot.duo { background:linear-gradient(135deg, var(--a) 50%, var(--b) 50%); }
.bt .dot.my { background:rgba(255,255,255,.04); border:1px dashed rgba(255,255,255,.55); display:grid; place-items:center; font-size:13px; color:#fff; }
.bt .dot.my input { position:absolute; inset:0; opacity:0; width:100%; height:100%; cursor:pointer; }
.bt .vsep { width:1px; height:30px; background:rgba(255,255,255,.14); margin:0 4px; }
.bt .group { display:flex; flex-direction:column; gap:4px; min-width:0; }
.bt .group .lbl { min-width:0; }
.bt .hex { font:11px ui-monospace,monospace; color:rgba(255,255,255,.6); }
.bt .link { background:none; border:0; color:#9ab; font:11px system-ui; cursor:pointer; text-decoration:underline; padding:0; }
`

/**
 * วาดถาดหนึ่งชุดลง `host` — แก้ `choice` ตรง ๆ แล้วเรียก `onChange()` (ผู้เรียกวาดถาดใหม่เอง)
 * `opts.extra` = ปุ่มท้ายแถวโทน (ตั้งต้น · ตามหน้า)
 */
export function buildTray(host, choice, onChange, opts = {}) {
  host.innerHTML = ''
  host.classList.add('bt')
  const up = (v) => (v || '').toUpperCase()
  const seg = (options, value, pick) => {
    const s = document.createElement('div'); s.className = 'seg'
    for (const [v, title] of options) {
      const b = document.createElement('button'); b.type = 'button'; b.textContent = title; b.className = v === value ? 'on' : ''
      b.onclick = () => { pick(v); onChange() }
      s.appendChild(b)
    }
    return s
  }
  const row = (label, ...kids) => {
    const d = document.createElement('div'); d.className = 'row'
    if (label) { const l = document.createElement('span'); l.className = 'lbl'; l.textContent = label; d.appendChild(l) }
    kids.forEach((k) => d.appendChild(k))
    host.appendChild(d)
    return d
  }
  // แบบพื้น (`BackdropStyle.offered` = สีเดียว · ไล่เฉด)
  row('', seg([['solid', 'สีเดียว'], ['gradient', 'ไล่เฉด']], choice.backdrop, (v) => { choice.backdrop = v }))
  // สี — "สีของฉัน" ซ้าย · "สำเร็จรูป" ขวา (คู่สีมาก่อน แล้วค่อยสีเดี่ยว — เม็ดผ่าครึ่งบอกเองว่าเป็นคู่)
  const presetHex = new Set(Object.values(PRESETS).flatMap((p) => [p.dark, p.light]))
  const isMine = !choice.secondary && !presetHex.has(up(choice.primary))
  const my = document.createElement('div'); my.className = 'group'
  my.innerHTML = '<span class="lbl">สีของฉัน</span>'
  const myDots = document.createElement('div'); myDots.className = 'dots'
  const pick = document.createElement('button'); pick.type = 'button'; pick.className = 'dot my' + (isMine ? ' on' : ''); pick.title = 'เลือกสีเอง'
  pick.textContent = '✎'
  if (isMine) pick.style.background = choice.primary
  const input = document.createElement('input'); input.type = 'color'; input.value = choice.primary || DEFAULT_PRIMARY
  input.oninput = () => { choice.primary = input.value.toUpperCase(); choice.secondary = null; onChange() }
  pick.appendChild(input); myDots.appendChild(pick)
  const hexLbl = document.createElement('span'); hexLbl.className = 'hex'; hexLbl.textContent = choice.secondary ? `${choice.primary} + ${choice.secondary}` : choice.primary
  myDots.appendChild(hexLbl)
  my.appendChild(myDots)
  const sep = document.createElement('div'); sep.className = 'vsep'
  const presets = document.createElement('div'); presets.className = 'group'
  presets.innerHTML = '<span class="lbl">สำเร็จรูป</span>'
  const dots = document.createElement('div'); dots.className = 'dots'
  for (const id of DUO_IDS) {
    const d = DUO_PRESETS[id]
    const on = !!choice.secondary && new Set([up(choice.primary), up(choice.secondary)]).size === 2 && [d.dark, d.light].every((h) => [up(choice.primary), up(choice.secondary)].includes(h))
    const b = document.createElement('button'); b.type = 'button'; b.className = 'dot duo' + (on ? ' on' : '')
    // ซีกซ้าย = สีที่ขึ้นเป็นพื้นตามโทน (แค่การแสดงผล — ค่าใน doc คือคู่ตามนิยาม เข้ม · อ่อน)
    const flip = choice.tone === 'light'
    b.style.setProperty('--a', flip ? d.light : d.dark); b.style.setProperty('--b', flip ? d.dark : d.light)
    b.title = id
    // = `CardTheme.setDuo`: เก็บคู่ตามนิยาม ไม่สลับ · โทนอยู่ที่แถวโทน
    b.onclick = () => { choice.primary = d.dark; choice.secondary = d.light; onChange() }
    dots.appendChild(b)
  }
  for (const [name, p] of Object.entries(PRESETS)) {
    const on = !choice.secondary && (up(choice.primary) === p.dark || up(choice.primary) === p.light)
    const b = document.createElement('button'); b.type = 'button'; b.className = 'dot' + (on ? ' on' : '')
    b.style.background = `linear-gradient(135deg, ${p.accentSoft}, ${p.accent})`; b.title = name
    // พาเลตต์ = ปุ่มลัดเขียน hex: แตะครั้งแรก = เฉดเข้ม · แตะซ้ำเม็ดที่เลือกอยู่ = สลับเข้ม/อ่อน (= `CardTheme.setPreset`)
    b.onclick = () => { choice.primary = on && up(choice.primary) === p.dark ? p.light : p.dark; choice.secondary = null; onChange() }
    dots.appendChild(b)
  }
  presets.appendChild(dots)
  row('สี', my, sep, presets)
  // โทน — เฉพาะคู่สี (20 ต.ค. 2569): "อ่อน" = ยกสีอ่อนของคู่ขึ้นเป็นพื้น · แตะแค่ `ink` ไม่เขียนทับค่าสี · สีเดียวไม่มีแถวนี้
  const last = choice.secondary ? row('โทน', seg([['dark', 'เข้ม'], ['light', 'อ่อน']], choice.tone, (v) => { choice.tone = v })) : row('')
  if (opts.extra) { opts.extra.style.marginLeft = 'auto'; last.appendChild(opts.extra) }
  return host
}
