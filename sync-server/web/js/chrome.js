// เปลือกของ widget หนึ่งตัว (= WidgetChrome.swift · ui/widgets/WidgetChrome.kt)
//
// กติกาเดียว · ทุกใบ (WIDGET-SPEC.md §2):  s = min(W / w0, H / h0) · box = (W / s, H / s) · ระยะขอบใน 12 เมื่อมีแผ่น/ขอบ
// แผ่น: glass (ม่าน + กระจก) · dim (ถ่านทึบ) · pane (กระจกบนใบที่วาดวัสดุเอง) · clear (ไม่มี)

import { css, opacity, chromeInk, tokenColor, extraTokens, parseHex, mixed, BLACK, WHITE, grey, onLightSurface, PALETTES } from './theme.js'
import { kindInfo, contentInset, resolveKind, TEXT_LAYER } from './kinds.js'
import { SpecSolver } from './spec-solver.js'
import { paintWidget } from './spec-painter.js'
import { WebSpecData, photoFor } from './data.js'
import { specIcon, byline, el } from './spec-icons.js'
import { fontCSS } from './measure.js'

/** สีของช่องที่ผู้ใช้เลือก (= `TextTint.color`) */
function tintColor(tint, ink, accent) {
  switch (tint) {
    case 'ink': return ink.text(0.92)
    case 'soft': return ink.text(0.55)
    case 'accent': return accent
    case 'white': return WHITE
    case 'black': return grey(0.08)
  }
  const pal = { rose: 'rose', coral: 'coral', gold: 'champagne', mint: 'mint', sky: 'sky', lavender: 'lavender' }[tint]
  if (!pal) return null
  const c = PALETTES[pal].accent
  return ink.isLight ? onLightSurface(c) : c
}

/**
 * วางชิ้นหนึ่งลงหน้า — `frame` = กรอบที่ผังหน้าคิดให้แล้ว (หน่วยออกแบบของหน้า)
 * env = { doc, theme, profile, specs, measurer, base, imageURL }
 */
export function mountWidget(pageEl, item, frame, env) {
  const { theme } = env
  const kind = resolveKind(item.kind, item.kit, env.specs)
  const spec = env.specs[kind]
  if (!spec && kind !== TEXT_LAYER) return
  const info = kindInfo(kind, spec)
  const ink = theme.inkStyle
  const pane = item.surface === 'pane'
  const surface = pane ? 'glass' : (item.surface || 'glass')
  const isText = info.isText
  const radius = isText ? Math.min(theme.radius, 10) : theme.radius
  const framed = pane || (!info.drawsOwnSurface && surface !== 'clear')
  const inset = contentInset(info, item.surface || 'glass', !!item.border)
  const W = Math.max(frame.width, 1), H = Math.max(frame.height, 1)
  const design = spec ? spec.design : { w: W, h: H }
  const s = isText ? 1 : Math.min(W / Math.max(design.w, 1), H / Math.max(design.h, 1))
  const layout = { width: W / s, height: H / s }
  const contentInk = framed ? chromeInk(ink, surface, theme) : ink
  // ป้าย Sale Here — ใบที่ถือข้อมูลซึ่งตรวจแล้ว (เว็บไม่รู้สถานะหัวข้อของ Star Profile — ถือว่ากรอกแล้ว)
  const stamped = !!info.stampFacts

  const root = el('div', `position:absolute;left:${frame.x}px;top:${frame.y}px;width:${W}px;height:${H}px`)
  root.dataset.kind = kind
  let surfaceEl = root
  if (framed) {
    const sh = `border-radius:${radius}px;`
    if (surface === 'dim') {
      root.style.cssText += sh + `background:${css(theme.slab)};` + (ink.liftRadius ? `box-shadow:0 0 ${ink.liftRadius * 0.7 * 2}px ${css(opacity(ink.lift, 0.6))};` : '')
    } else {
      // กระจก — ม่านขาวขุ่น/ดำจางตามหมึก (คู่สี = ดำจาง) + Liquid Glass (เว็บ: เบลอพื้นหลังบาง ๆ + ขอบแสง)
      const veil = theme.activeDuo ? opacity(BLACK, 0.16) : ink.isLight ? opacity(WHITE, 0.58) : opacity(BLACK, 0.16)
      const tinted = info.verifiedTier && !theme.activeDuo
      root.style.cssText += sh + `background:${css(veil)};` + (tinted ? `background-image:linear-gradient(${css(opacity(theme.accent, 0.13))},${css(opacity(theme.accent, 0.13))});` : '')
        + 'backdrop-filter:blur(3px) saturate(1.25);-webkit-backdrop-filter:blur(3px) saturate(1.25);'
        + `box-shadow:${ink.liftRadius ? `0 6px ${ink.liftRadius * 2}px ${css(ink.lift)},` : ''}inset 0.6px 0.6px 0 rgba(255,255,255,0.28),inset -0.4px -0.4px 0 rgba(255,255,255,0.08);`
    }
    surfaceEl = el('div', `position:absolute;inset:0;overflow:hidden;border-radius:${radius}px`)
    root.appendChild(surfaceEl)
  } else {
    surfaceEl = el('div', `position:absolute;inset:0;${isText ? '' : 'overflow:hidden'}`)
    root.appendChild(surfaceEl)
  }
  if (item.border && !info.drawsOwnBorder) {
    root.appendChild(el('div', `position:absolute;inset:0;border-radius:${radius}px;box-shadow:inset 0 0 0 0.7px ${css(ink.line(0.12))};pointer-events:none`))
  }

  if (isText) {
    textBlock(surfaceEl, item, layout, contentInk, theme, env)
  } else {
    const scaled = el('div', `position:absolute;left:0;top:0;width:${layout.width}px;height:${layout.height}px;transform-origin:0 0;transform:scale(${s})`)
    const inner = el('div', `position:absolute;left:${inset}px;top:${inset}px;width:${layout.width - inset * 2}px;height:${layout.height - inset * 2}px`)
    scaled.appendChild(inner); surfaceEl.appendChild(scaled)
    const box = { width: Math.max(1, layout.width - inset * 2), height: Math.max(1, layout.height - inset * 2) }
    paintSpec(inner, item, spec, info, box, s, contentInk, theme, stamped, env)
  }

  if (stamped && info.stampOverlay) {
    const [tone, top, right] = info.stampOverlay
    const b = byline(css(contentInk.text(0.85)), 8.5, tone, env.base)
    b.style.position = 'absolute'; b.style.top = `${top}px`; b.style.right = `${right}px`
    root.appendChild(b)
  }
  pageEl.appendChild(root)
}

function paintSpec(host, item, spec, info, box, s, ink, theme, stamped, env) {
  const surface = item.surface || 'glass'
  // หน้าตาเป็นของชนิด (`widget.kit.look`) ไม่ใช่ค่าในชิ้น
  const kit = { ...(item.kit || {}), style: spec.widget?.kit?.look || 'purple' }
  const ex = extraTokens(theme, ink, surface, info.skin, kit, !!item.border)
  const accent = theme.accent
  // `env.makeData` = แหล่งข้อมูลที่ส่งมาแทน (หน้าทดสอบเล่นคำตอบของ iOS ซ้ำ)
  const data = env.makeData ? env.makeData(item) : new WebSpecData({
    profile: env.profile, item, sample: false, inkLight: ink.isLight, surface, duo: !!theme.activeDuo,
    stamped, cutout: false, kitDark: ex.look.dark,
  })
  const solver = new SpecSolver(spec, box, data, env.measurer, s)
  const boxes = solver.solve()
  const colorObj = (token, it) => {
    if (token.startsWith('$') && it) {
      let name = token.slice(1), alpha = ''
      const at = name.indexOf('@')
      if (at >= 0) { alpha = name.slice(at); name = name.slice(0, at) }
      token = it.value(name) + alpha
    }
    return tokenColor(token, ink, accent, theme, ex.map)
  }
  const socials = data.socials || []
  const prov = socials.length && socials.every((x) => x.source !== 'manual')
    ? { type: 'connected', ago: socials[0].syncedAgo || 'วันนี้' } : { type: 'manual', label: 'กรอกเอง · รอตรวจสอบ' }
  const ctx = {
    base: env.base,
    measurer: env.measurer,
    fontCSS,
    css,
    color: (t, it) => css(colorObj(t, it)),
    colorObj,
    mixDark: (c) => mixed(c, BLACK, 0.5),
    platePattern: item.pattern || 'plain',
    photo: (slot) => photoFor(env.doc, slot, item.id, env.imageURL, env.mock),
    icon: (o) => specIcon({ ...o, ink, accent: css(accent), stamped, handle: env.profile.text('handle'), provenance: prov, scrap: theme.scrap, base: env.base }),
  }
  paintWidget(host, boxes, solver.scale, ctx)
}

/** ก้อนข้อความ (= `TextBlock`) — ตัวอักษรของผู้ใช้ตรง ๆ บนการ์ด */
function textBlock(host, item, layout, ink, theme, env) {
  const text = env.profile.note(item.id, null, '') || 'แตะเพื่อพิมพ์ข้อความ'
  const face = item.face || 'noto'
  const fc = fontCSS(face, 600, false)
  const tint = tintColor(item.tint || 'ink', ink, theme.accent) || ink.text(0.92)
  const align = item.align === 'center' ? 'center' : item.align === 'trailing' ? 'right' : 'left'
  host.appendChild(el('div', `position:absolute;left:4px;top:4px;right:4px;white-space:pre;text-align:${align};color:${css(tint)};`
    + `font-family:${fc.family};font-weight:${fc.weight};font-size:${item.points || 28}px;line-height:1.25`, '')).textContent = text
}

export { parseHex }
