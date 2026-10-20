// ผังหน้า (= layout/CardLayout.kt `PageLayout`) — วางทุกชิ้นตามพิกัดที่มันถือ แล้วดันลงจนไม่มีใครทับใคร

import { TEXT_LAYER } from './kinds.js'

const STEP = 6, MARGIN = 18, MIN = { width: 100, height: 40 }
const minSize = (kind) => (kind === TEXT_LAYER ? { width: 8, height: 8 } : MIN)

function clampRect(it, page) {
  const min = minSize(it.kind)
  const bw = Math.max(page.width, MIN.width), bh = Math.max(page.height, MIN.height)
  const w = Math.min(Math.max(it.w, min.width), bw), h = Math.min(Math.max(it.h, min.height), bh)
  return { x: Math.min(Math.max(it.x, 0), bw - w), y: Math.min(Math.max(it.y, 0), bh - h), width: w, height: h }
}
// ชิ้นที่ตรึงกับก้นหน้า (`pinned` = ตรารับรอง Sale Here) — x · กว้าง · สูง ตามที่ถือไว้ ส่วน y นั่งบนขอบกระดาษล่างเสมอ
// คิดจากก้นหน้าทุกครั้งแทนที่จะเชื่อ `y` ในไฟล์ เพราะหน้าพอร์ตสูงตามจอ (= `PageLayout.pinnedFrame`)
function pinnedFrame(it, page) {
  const r = clampRect(it, page)
  const bh = Math.max(page.height, MIN.height)
  r.y = Math.max(0, bh - MARGIN - r.height)
  return r
}
const clamp = (it, page) => (it.pinned ? pinnedFrame(it, page) : clampRect(it, page))
const overlaps = (a, b) => a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height
const stride = function* (from, through, by) { for (let i = 0; ; i++) { const v = from + i * by; if (v > through) return; yield v } }

export function solvePage(items, page) {
  const box = { x: 0, y: 0, width: Math.max(page.width, MIN.width), height: Math.max(page.height, MIN.height) }
  const polite = { x: MARGIN, y: MARGIN, width: Math.max(page.width - MARGIN * 2, MIN.width), height: Math.max(page.height - MARGIN * 2, MIN.height) }
  // ชิ้นที่ตรึงได้ที่ก่อนทุกคน — ของที่วางมาทับจึงเป็นฝ่ายหลบเสมอ
  const order = items.map((it, i) => [it, i]).sort((a, b) => (!!b[0].pinned - !!a[0].pinned) || a[0].y - b[0].y || a[0].x - b[0].x || a[1] - b[1])
  const taken = [], spot = new Map()
  // ชิ้นที่ตรึงถูกวางก่อนเสมอ จึงเป็นกรอบชุดแรกของ `taken`
  const pinnedCount = items.filter((it) => it.pinned).length
  const pins = () => taken.slice(0, pinnedCount)
  const free = (r) => {
    if (!(r.x >= box.x - 0.01 && r.y >= box.y - 0.01 && r.x + r.width <= box.x + box.width + 0.01 && r.y + r.height <= box.y + box.height + 0.01)) return false
    const p = { x: r.x + 0.5, y: r.y + 0.5, width: r.width - 1, height: r.height - 1 }
    return !taken.some((t) => overlaps(t, p))
  }
  for (const [it] of order) {
    const want = clamp(it, page)
    if (it.pinned) { taken.push(want); spot.set(it, want); continue }
    // ขอที่ทับชิ้นที่ตรึง = ได้ที่ **เหนือมันพอดี** — ไม่งั้นการดันลงไม่มีวันเจอที่ว่าง แล้วของกระโดดไปมุมบนซ้าย
    for (const pin of pins()) {
      if (!overlaps({ x: pin.x + 0.5, y: pin.y + 0.5, width: pin.width - 1, height: pin.height - 1 }, want)) continue
      const above = pin.y - want.height
      if (above >= box.y) want.y = above
    }
    let put = null
    for (let y = want.y; y + want.height <= box.y + box.height + 0.01; y += STEP) {
      const r = { ...want, y }
      if (free(r)) { put = r; break }
    }
    if (!put) {
      const sweep = want.width <= polite.width && want.height <= polite.height ? polite : box
      outer: for (const yy of stride(sweep.y, sweep.y + sweep.height - want.height, STEP * 4)) {
        for (const xx of stride(sweep.x, sweep.x + sweep.width - want.width, STEP * 4)) {
          const r = { ...want, x: xx, y: yy }
          if (free(r)) { put = r; break outer }
        }
      }
    }
    // หน้าเต็มจริง ๆ — ยอมทับที่ก้นหน้า แต่ **ห้ามซุกใต้ชิ้นที่ตรึง** (มันอยู่ชั้นบนสุดและย้ายไม่ได้)
    let floorY = box.y + box.height - want.height
    for (const pin of pins()) if (pin.x < want.x + want.width && pin.x + pin.width > want.x) floorY = Math.min(floorY, pin.y - want.height)
    const final = put ?? { ...want, y: Math.max(box.y, floorY) }
    taken.push(final)
    spot.set(it, final)
  }
  // ชิ้นที่ตรึงวาดทีหลังสุด = อยู่ชั้นบนสุด — ตรารับรองต้องไม่ใช่ฝ่ายที่ถูกบัง
  return [...items.filter((it) => !it.pinned), ...items.filter((it) => it.pinned)].map((it) => ({ item: it, frame: spot.get(it) || clamp(it, page) }))
}
