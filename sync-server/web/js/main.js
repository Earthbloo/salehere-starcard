// เว็บดู Star Card (ดูอย่างเดียว) — อ่านการ์ดกับผัง widget ผ่าน GraphQL ที่เดียวกับแอป แล้ววาดด้วยกติกาเดียวกับ iOS
//
// ?api=<url ของ GraphQL> (ตั้งต้น /graphql ของ server นี้) · ดึงตอนเปิด/กลับมาที่แท็บ — การ์ด/ผังเปลี่ยนแล้ววาดใหม่เอง

import { parseSpec } from './spec-model.js'
import { makeTheme } from './theme.js'
import { WebMeasurer, loadFonts } from './measure.js'
import { Profile } from './data.js'
import { paintBackdrop, signatureCorner } from './backdrop.js'
import { mountWidget } from './chrome.js'
import { resolveKind, TEXT_LAYER } from './kinds.js'
import { solvePage } from './page.js'

const params = new URLSearchParams(location.search)
const API = params.get('api') || '/graphql'
const BASE = new URL('./', location.href).pathname

async function gql(query, variables = {}) {
  const r = await fetch(API, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ query, variables }) })
  const j = await r.json()
  if (j.errors) throw new Error(j.errors.map((e) => e.message).join('; '))
  return j.data
}

const Q_CARD = `query Card($id: ID) { starCard(id: $id) { id rev format theme pages { items { id kind x y w h surface border options } } owner notes photos backgroundImageId updatedAt updatedBy } }`
const Q_SPECS = `query Specs { widgetSpecsVersion widgetSpecs { kind json } }`

const state = { card: null, specs: null, specsVersion: null, rev: -1, mock: null }
const measurer = new WebMeasurer()

/**
 * ชิ้นหนึ่งในรูปที่ตัววาดใช้ — ฟิลด์หลัก + `options` (ค่าที่เลือกใน `widget.controls` · คีย์ = `opt`)
 * ไฟล์ก่อน 19 ต.ค. 2569 เก็บ `kit` `pattern` `pinned` แยกเป็นคีย์ — อ่านได้ทั้งสองแบบ
 */
function flatItem(it, popSkin = 'glass') {
  const raw = it.options || {}
  const legacyKit = raw.kit && typeof raw.kit === 'object' ? raw.kit : null
  const o = {}
  for (const [k, v] of Object.entries(raw)) if (v != null && typeof v !== 'object') o[k] = String(v)
  if (legacyKit) {
    Object.assign(o, legacyKit.opts || {})
    if (legacyKit.fill && legacyKit.fill !== 'solid') o.fill = legacyKit.fill
    if (legacyKit.corner && legacyKit.corner !== 'round') o.corner = legacyKit.corner
  }
  delete o.kit
  // หน้าตาตัวอักษรเป็นของชั้นข้อความเท่านั้น — ไฟล์เก่าเขียนคีย์พวกนี้ให้ทุกชิ้น
  const text = { face: o.face, tint: o.tint, align: o.align, points: o.points }
  if (it.kind !== TEXT_LAYER) for (const k of ['face', 'tint', 'scale', 'align', 'points']) delete o[k]
  // หน้าตาของชุดห้าสไตล์เป็นของชนิด — `style` ของไฟล์เก่าใช้แค่เลือกชนิดใหม่ที่ตรงกัน
  const kit = { fill: o.fill || 'solid', corner: o.corner || 'round', opts: o, style: legacyKit?.style }
  const kind = resolveKind(it.kind, legacyKit || (o.fill || o.corner ? kit : null), state.specs, popSkin)
  return {
    id: it.id, kind, x: it.x, y: it.y, w: it.w, h: it.h, surface: it.surface, border: it.border,
    options: o, kit, pattern: o.pattern || 'plain',
    // ตรึงก้นหน้า = ของชนิด (`widget.pinned`) ไม่ใช่ค่าในชิ้น
    pinned: !!state.specs[kind]?.widget?.pinned,
    // ชั้นข้อความ: หน้าตาตัวอักษรอยู่ใน `options`
    face: text.face, tint: text.tint, align: text.align, points: text.points != null ? Number(text.points) : undefined,
  }
}

function render() {
  const card = state.card
  const stage = document.getElementById('stage')
  stage.innerHTML = ''
  if (!card) { stage.innerHTML = '<p class="empty">ยังไม่มีการ์ด — เปิดโหมดลองทำในแอป หรือเรียก <code>saveStarCard</code></p>'; return }
  const theme = makeTheme(card.theme || {})
  const doc = { photos: card.photos || {}, owner: card.owner || {}, notes: card.notes || {} }
  const profile = new Profile(doc.owner, doc.notes)
  const popSkin = card.theme?.corner === 'soft' ? 'paper' : 'glass'   // ไฟล์ก่อน 19 ต.ค.: สำรับสติกเกอร์เอาวัสดุจากมุมของธีม
  const pages = card.pages.map((p) => p.items.map((it) => flatItem(it, popSkin)))
  const story = card.format === 'story'
  const pw = story ? 540 : 402
  // พอร์ต: แอปสูงตามจอ — เว็บใช้สัดส่วนตั้งต้นของแอป (กว้าง × 1.667 = `CardFormat.pageSize` เมื่อไม่รู้ขนาดจอ)
  const ph = story ? 960 : Math.round(pw * 1.667)
  const strip = document.createElement('div')
  strip.className = 'strip'
  strip.style.cssText = `width:${pw * pages.length}px;height:${ph}px`
  paintBackdrop(strip, theme, pw * pages.length, ph, { pageW: pw, backgroundURL: card.backgroundImageId ? imageURL(card.backgroundImageId) : null })
  if (!['emboss', 'foil'].includes(theme.strip)) signatureCorner(strip, theme, pw * pages.length, ph, BASE)
  const env = { doc, theme, profile, specs: state.specs, measurer, base: BASE, imageURL, mock: state.mock }
  pages.forEach((items, i) => {
    const page = document.createElement('div')
    page.className = 'page'
    page.style.cssText = `left:${i * pw}px;width:${pw}px;height:${ph}px`
    for (const p of solvePage(items, { width: pw, height: ph })) mountWidget(page, p.item, p.frame, env)
    strip.appendChild(page)
  })
  const fit = Math.min(1, (window.innerWidth - 32) / (pw * pages.length), 1)
  const wrap = document.createElement('div')
  wrap.className = 'fit'
  wrap.style.cssText = `width:${pw * pages.length * fit}px;height:${ph * fit}px`
  strip.style.transform = `scale(${fit})`
  wrap.appendChild(strip)
  stage.appendChild(wrap)
  document.getElementById('meta').textContent = `rev ${card.rev} · ${card.updatedBy || '—'} · ${card.format} · ${pages.flat().length} widget`
}

const imageURL = (id) => `/api/images/${id}`

async function tick() {
  try {
    const v = await gql('{ widgetSpecsVersion mockPhotos { version creators works } }')
    if (v.mockPhotos.version !== state.mock?.version) { state.mock = v.mockPhotos; state.rev = -1 }
    if (v.widgetSpecsVersion !== state.specsVersion) {
      const s = await gql(Q_SPECS)
      state.specs = Object.fromEntries(s.widgetSpecs.map((w) => [w.kind, parseSpec(w.json)]))
      state.specsVersion = s.widgetSpecsVersion
      state.rev = -1
    }
    const c = await gql(Q_CARD, { id: params.get('id') })
    if (!c.starCard || c.starCard.rev !== state.rev) {
      state.card = c.starCard
      state.rev = c.starCard?.rev ?? 0
      render()
    }
    document.body.classList.remove('offline')
  } catch (e) {
    document.body.classList.add('offline')
    document.getElementById('meta').textContent = 'ต่อ API ไม่ได้ — ' + e.message
  }
}

await loadFonts(`${BASE}fonts/`)
await tick()
// ดึงตอนเปิดหน้า · ตอนกลับมาที่แท็บ — ไม่ poll (เจ้าของใช้คนเดียว การ์ดเปลี่ยนตอนเขาแก้ในแอป)
addEventListener('focus', tick)
document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'visible') tick() })
let t = 0
addEventListener('resize', () => { clearTimeout(t); t = setTimeout(render, 150) })
