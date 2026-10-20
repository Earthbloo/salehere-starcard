// คุณสมบัติของชนิด widget ที่ chrome กับแหล่งข้อมูลต้องรู้ (= WidgetKind ของ iOS/Android)
//
// **ไม่มีชื่อ widget ในไฟล์นี้** — ทุกคุณสมบัติอ่านจากบล็อก `widget` ของไฟล์ผัง (WIDGET-SPEC.md §1.5)
// ค่าที่ไม่ใส่ใช้ค่าของหมวด (`CATEGORY`) หรือกติกากลาง · ชั้นข้อความ (`textBlock`) ไม่ใช่ widget จึงไม่มีผัง

/** คีย์ของชั้นข้อความในไฟล์การ์ด (= `TextBlock.layerKey`) */
export const TEXT_LAYER = 'textBlock'
const TEXT_LAYER_META = { title: 'ข้อความ', category: 'text', ownSurface: true, resize: false, motion: 'light' }

/** ค่าตั้งต้นของหมวด (= `WidgetFamily.group` / `.tier`) */
const CATEGORY_TIER = { followers: 'connected', audience: 'connected', rate: 'connected', brand: 'verified', verified: 'verified', seal: 'verified' }

/** คุณสมบัติของชนิด `kind` จาก `spec.widget` */
export function kindInfo(kind, spec) {
  const isText = kind === TEXT_LAYER
  const meta = isText ? TEXT_LAYER_META : (spec?.widget || {})
  const family = meta.category || 'intro'
  const tier = meta.tier || CATEGORY_TIER[family] || 'personal'
  const at = meta.stampAt
  return {
    family,
    isKit: !!meta.kit,
    skin: meta.skin || null,
    drawsOwnSurface: !!meta.ownSurface,
    drawsOwnBorder: !!meta.ownBorder,
    isFullBleed: !!meta.fullBleed,
    verifiedTier: tier === 'verified',
    stampFacts: meta.stamp || null,
    stampOverlay: at ? [at.tone, at.top, at.trailing] : null,
    isText,
  }
}

/**
 * ชนิดที่วาดจริงของชิ้นในไฟล์ (= `WidgetKind.decode`) — ชื่อเก่าตกไปที่ใบที่ประกาศ `widget.replaces`
 * ชุดห้าสไตล์ก่อน 19 ต.ค. 2569 เป็นชนิดเดียวต่อหัวข้อ + `kit.style` ในชิ้น → ใบที่ `widget.kit.look` ตรงกัน
 */
export function resolveKind(kind, kit, specs, popSkin = 'glass') {
  if (kind === TEXT_LAYER || specs[kind]) return kind
  const look = kit ? (kit.style || 'purple') : null
  const all = Object.values(specs).filter((s) => s.widget?.replaces?.includes(kind))
  if (all.length) return (all.find((s) => (s.widget.kit?.look ?? null) === look) || all[0]).kind
  // สำรับสติกเกอร์ในไฟล์เก่าไม่มีวัสดุติดมากับชนิด — มาจากมุมของธีม (`corner == soft` → กระดาษ) (= `WidgetKind.decode`)
  const suffixed = kind + (popSkin === 'paper' ? 'Paper' : 'Glass')
  return specs[suffixed] ? suffixed : kind
}

/** ระยะขอบในของเนื้อหา (= `contentInset`) — 12 เมื่อ chrome วาดแผ่นหรือมีเส้นขอบ */
export function contentInset(info, surface, border) {
  if (info.isText) return 4
  const pane = surface === 'pane'
  const framed = pane || (!info.drawsOwnSurface && surface !== 'clear')
  const insetable = framed || (!info.drawsOwnSurface && border)
  return pane || info.isFullBleed || !insetable ? 0 : 12
}
