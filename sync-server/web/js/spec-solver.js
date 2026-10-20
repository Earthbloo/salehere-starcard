// ตัวคำนวณกล่องจากผัง — port ทีละบรรทัดของ layout/SpecSolver.kt (= Layout/SpecSolver.swift)
//
// เข้า: ผัง (`parseSpec`) + กล่องราก {width, height} (หน่วยออกแบบ) + แหล่งข้อมูล + ตัววัดข้อความ
// ออก: รายการกล่อง SpecBox {id, node, frame:{x,y,width,height}, text:{string,size,lines,slot}|null, item, depth}
//      ทุกโหนดที่ต้องวาด ตามลำดับวาด · ทุกกล่องปัด 2 ทศนิยม
//
// SpecDataSource = { text(slot, preset), list(name) → SpecItem[], flag(name), font(slot, face, size, weight) → SpecFont }
// SpecMeasurer   = { measure(text, font, width|null) → {w, h, lines}, lineHeight(font) }
// SpecFont       = { face, size, weight, tracking, kerning, italic, lineHeight }

import { SpecCondition, swiftDouble, swiftParseDouble } from './spec-model.js'

/** หนึ่งชิ้นในรายการ (`list`) — ค่าตามชื่อฟิลด์ · `i` = ลำดับ */
export class SpecItem {
  constructor(id, i, fields) { this.id = id; this.i = i; this.fields = fields }
  value(key) {
    if (key === 'i') return String(this.i)
    if (key === 'rank') return String(this.i + 1)
    if (key === 'rank2') return String(this.i + 1).padStart(2, '0')
    const v = this.fields[key]
    return v === undefined ? '' : v
  }
  copy(o) { return new SpecItem(o.id ?? this.id, o.i ?? this.i, o.fields ?? this.fields) }
}

/** ขั้นต่ำของตัวอักษรเมื่อผู้ใช้หดกรอบ — pt **บนการ์ด** (= `SpecLegibility`) */
export const SpecLegibility = {
  TITLE_FROM: 18, TITLE_MIN: 18, CONTENT_MIN: 12,
  STEPS: [1, 0.66, 0.33],
  IMAGE_KEEP: 0.6,
  target(design, role) {
    if (role === 'deco') return 0
    const title = role != null ? role === 'title' : design >= this.TITLE_FROM
    return Math.min(design, title ? this.TITLE_MIN : this.CONTENT_MIN)
  },
  floor(design, role, scale) {
    if (!(scale > 0 && scale < 1)) return 0
    return this.target(design, role) / scale
  },
}

const replaceAll = (s, a, b) => s.split(a).join(b)
const isPt = (l) => l && typeof l === 'object' && 'pt' in l
const ZERO_INSETS = { top: 0, right: 0, bottom: 0, left: 0 }
const hOf = (p) => p.left + p.right
const vOf = (p) => p.top + p.bottom
const rect = (x, y, width, height) => ({ x, y, width, height })

/** ปัด 2 ทศนิยมแบบ Swift `rounded()` (ครึ่งปัดออกจากศูนย์) */
export function r2(v) {
  const s = v * 100
  const r = s >= 0 ? Math.round(s) : -Math.round(-s)
  return r / 100 + 0 // +0 กัน -0
}

// ต้นไม้ที่ขยายแล้ว
class N {
  constructor(base, id, item, depth) {
    this.base = base; this.id = id; this.item = item; this.depth = depth
    this.node = base
    this.children = []
    this.frame = rect(0, 0, 0, 0)
    this.text = null
    this.overflow = 0
    this.textCache = new Map()
  }
}

export class SpecSolver {
  constructor(spec, box, data, measurer, renderScale = 1) {
    this.spec = spec; this.box = box; this.data = data; this.measurer = measurer; this.renderScale = renderScale
    this.scale = 1
    this.strength = 1
    this.lifted = false
  }

  expand(node, id, item, depth) {
    if (node.cond != null && !this.evaluate(node.cond, item)) return null
    const n = new N(node, id, item, depth)
    const name = node.list, tpl = node.each
    if (node.type === 'chips' && name != null && tpl != null) {
      let items = this.data.list(name)
      if (node.where != null) items = items.filter((it) => this.evaluate(node.where, it))
      if (node.sort != null) {
        const keys = node.sort.split(',').filter((k) => k.length).map((k) => {
          const parts = k.split(' ').filter((p) => p.length)
          return [parts[0] || '', parts.length > 1 && parts[1] === 'desc']
        })
        const before = (a, b) => {
          for (const [key, desc] of keys) {
            const av = a.value(key), bv = b.value(key)
            if (av === bv) continue
            const x = swiftParseDouble(av), y = swiftParseDouble(bv)
            let less
            if (x !== null && y !== null) {
              if (x === y) continue
              less = x < y
            } else less = av < bv
            return desc ? !less : less
          }
          return false
        }
        items = [...items].sort((a, b) => (before(a, b) ? -1 : before(b, a) ? 1 : 0))
        items = items.map((it, i) => it.copy({ i }))
      }
      if (node.group != null) {
        const seen = new Set()
        items = items.filter((it) => { const v = it.value(node.group); if (seen.has(v)) return false; seen.add(v); return true })
        items = items.map((it, i) => it.copy({ i }))
      }
      if (node.limit != null) items = items.slice(0, node.limit)
      // ค่าสรุปของรายการ (หลัง sort/limit): `<key>.max` · `<key>.sum` สำหรับฟิลด์ตัวเลข
      const maxes = new Map(), sums = new Map()
      for (const it of items) for (const [k, v] of Object.entries(it.fields)) {
        const d = swiftParseDouble(v)
        if (d === null) continue
        maxes.set(k, Math.max(maxes.has(k) ? maxes.get(k) : -Infinity, d))
        sums.set(k, (sums.get(k) || 0) + d)
      }
      items = items.map((it) => {
        const f = { ...it.fields }
        for (const [k, m] of maxes) { f[`${k}.max`] = swiftDouble(m); f[`${k}.sum`] = swiftDouble(sums.get(k) || 0) }
        return it.copy({ fields: f })
      })
      n.children = items.map((it, idx) => this.expand(tpl, `${id}/c${idx}`, it, depth + 1)).filter(Boolean)
    } else {
      n.children = (node.children || []).map((c, idx) => this.expand(c, `${id}/${idx}`, item, depth + 1)).filter(Boolean)
    }
    return n
  }

  /** `owner.verified` · `has:tagline` · `!has:about` · `list:socials>1` · `sample` · `$field` */
  evaluate(cond, item) {
    if (cond.includes('|')) return cond.split('|').filter((c) => c.length).some((c) => this.evaluate(c, item))
    if (cond.includes('&')) return cond.split('&').filter((c) => c.length).every((c) => this.evaluate(c, item))
    let c = cond.trim()
    let negate = false
    if (c.startsWith('!')) { negate = true; c = c.slice(1) }
    if (!c.startsWith('$') && c.includes('$') && item) {
      for (const [k, v] of Object.entries(item.fields)) c = replaceAll(c, `$${k}`, v)
      c = replaceAll(c, '$i', String(item.i))
    }
    let v
    if (c.startsWith('has:')) {
      v = this.resolveText(c.slice(4), item).length > 0
    } else if (c.startsWith('list:')) {
      const body = c.slice(5)
      const gt = body.indexOf('>'), eq = body.indexOf('=')
      const int = (s) => { const n = parseInt(s, 10); return /^[+-]?\d+$/.test(s) ? n : 0 }
      if (gt >= 0) v = this.data.list(body.slice(0, gt)).length > int(body.slice(gt + 1))
      else if (eq >= 0) v = this.data.list(body.slice(0, eq)).length === int(body.slice(eq + 1))
      else v = this.data.list(body).length > 0
    } else if (c.startsWith('$') && item) {
      const body = c.slice(1)
      const m = /(<=|>=|<|>)/.exec(body)
      if (m) {
        const key = body.slice(0, m.index), op = m[0]
        const rhs = swiftParseDouble(body.slice(m.index + op.length)) ?? 0
        const lhs = swiftParseDouble(item.value(key)) ?? 0
        v = op === '<' ? lhs < rhs : op === '<=' ? lhs <= rhs : op === '>' ? lhs > rhs : lhs >= rhs
      } else if (body.endsWith('=max')) {
        const k = body.slice(0, -4)
        v = item.value(k) === item.value(`${k}.max`) && item.value(k).length > 0
      } else if (body.endsWith('=first')) {
        v = item.i === 0
      } else {
        v = item.value(body).length > 0
      }
    } else {
      v = this.data.flag(c)
    }
    return negate ? !v : v
  }

  resolveText(raw, item) {
    if (raw.startsWith('$') && item) return item.value(raw.slice(1))
    let s = raw
    if (item && s.includes('$i')) s = replaceAll(s, '$i', String(item.i))
    if (raw.startsWith('$') || raw.includes('{')) {
      if (item) {
        for (const [k, v] of Object.entries(item.fields)) s = replaceAll(s, `{${k}}`, v)
        s = replaceAll(s, '{i}', String(item.i))
      }
      return s
    }
    return this.data.text(s, null)
  }

  boundSlot(node, item) {
    const slot = node.slot
    if (slot == null) return null
    if (slot.startsWith('$')) return null
    if (item && slot.includes('$i')) return replaceAll(slot, '$i', String(item.i))
    return slot
  }

  stringOf(n) {
    const node = n.node
    let s = '', slot = null
    const sl = node.slot
    if (sl != null) {
      if (sl.startsWith('$')) s = n.item ? n.item.value(sl.slice(1)) : ''
      else { slot = this.boundSlot(node, n.item); s = this.data.text(slot ?? sl, node.preset ?? null) }
    }
    if (s === '' && node.text != null) s = this.resolveTemplate(node.text, n.item)
    if (s === '' && node.preset != null) s = node.preset
    if (node.textCase === 'upper') s = s.toUpperCase()
    else if (node.textCase === 'lower') s = s.toLowerCase()
    return [s, slot]
  }

  resolveTemplate(t, item) {
    if (!item || !(t.includes('{') || t.includes('$'))) return t
    let s = t
    const keys = [...Object.keys(item.fields), 'i', 'rank', 'rank2'].sort((a, b) => b.length - a.length)
    for (const k of keys) {
      const v = item.value(k)
      s = replaceAll(s, `{${k}}`, v)
      s = replaceAll(s, `$${k}`, v)
    }
    return s
  }

  baseSize(node) {
    let size = node.size ?? 14
    for (const r of node.sizeWhen || []) if (SpecCondition.box(r.when, this.box.width, this.box.height)) { size = r.size; break }
    return size
  }

  fontFor(n, size) {
    const node = n.node
    const f = this.data.font(this.boundSlot(node, n.item), node.face ?? 'body', size, node.weight ?? 400)
    return { ...f, tracking: node.tracking ?? 0, kerning: node.kerning ?? 0, italic: node.italic ?? false, lineHeight: node.lineHeight ?? 1 }
  }

  /** วัดข้อความในความกว้าง `width` (null = บรรทัดเดียวไม่จำกัด) — ย่อตาม `shrinkTo` จนลง `maxLines` */
  fitText(n, width) {
    const key = width ?? -1
    const hit = n.textCache.get(key)
    if (hit) return hit
    const [s, slot] = this.stringOf(n)
    const node = n.node
    const maxLines = node.maxLines ?? (width == null ? 1 : 0)
    const design = this.baseSize(node)
    const legible = this.legibleSize(node, design)
    if (legible > design) this.lifted = true
    let size = Math.max(design, legible)
    const floorSize = node.shrinkTo != null ? Math.min(node.shrinkTo, design) : design
    let out = { w: 0, h: 0, lines: 1 }
    const cap = node.growTo
    if (cap != null && width != null && s.length) {
      let grown = size
      while (grown + 1 <= cap) {
        const m = this.measurer.measure(s, this.fontFor(n, grown + 1), null)
        if (m.w > width + 0.01) break
        grown += 1
      }
      size = grown
    }
    for (;;) {
      const f = this.fontFor(n, size)
      if (!s.length) { out = { w: 0, h: this.measurer.lineHeight(f), lines: 1 }; break }
      const m = this.measurer.measure(s, f, width)
      out = m
      const overflowLines = maxLines > 0 && m.lines > maxLines
      const overflowWidth = width != null ? m.w > width + 0.01 : false
      if (!(overflowLines || overflowWidth) || size - 0.5 < floorSize) break
      size -= 0.5
    }
    let lines = out.lines
    if (maxLines > 0) lines = Math.min(lines, maxLines)
    const lh = this.measurer.lineHeight(this.fontFor(n, size))
    const h = !s.length ? lh : (lines === out.lines ? Math.max(out.h, lh) : lh * lines)
    const r = [{ width: width != null ? Math.min(out.w, width) : out.w, height: h }, { string: s, size, lines, slot }]
    n.textCache.set(key, r)
    return r
  }

  fixed(l, avail) {
    if (isPt(l)) return l.pt
    if (l && typeof l === 'object' && 'pct' in l) return avail != null ? avail * l.pct / 100 : null
    return null
  }
  isFill(l) { return l === 'fill' }
  pad(node) { return node.pad || ZERO_INSETS }
  clampW(node, w) { let v = w; if (node.minW != null) v = Math.max(v, node.minW); if (node.maxW != null) v = Math.min(v, node.maxW); return Math.max(0, v) }
  clampH(node, h) { let v = h; if (node.minH != null) v = Math.max(v, node.minH); if (node.maxH != null) v = Math.min(v, node.maxH); return Math.max(0, v) }

  intrinsic(n, availW, availH) {
    const node = n.node
    const fw = this.fixed(node.w, availW), fh = this.fixed(node.h, availH)
    if (fw != null && fh != null) return { width: this.clampW(node, fw), height: this.clampH(node, fh) }
    const a = node.aspect
    if (a != null && a > 0) {
      if (fw != null) return { width: this.clampW(node, fw), height: this.clampH(node, fw / a) }
      if (fh != null) return { width: this.clampW(node, fh * a), height: this.clampH(node, fh) }
    }
    let size
    switch (node.type) {
      case 'text': {
        const w = fw ?? availW
        const [m] = this.fitText(n, w != null ? this.clampW(node, w) : null)
        size = { width: fw ?? m.width, height: fh ?? m.height }
        break
      }
      case 'icon': {
        const s = node.size ?? 16
        size = { width: fw ?? fh ?? s, height: fh ?? fw ?? s }
        break
      }
      case 'image': size = { width: fw ?? availW ?? 0, height: fh ?? availH ?? 0 }; break
      case 'rect': case 'spacer': size = { width: fw ?? 0, height: fh ?? 0 }; break
      case 'line': size = { width: fw ?? availW ?? 0, height: fh ?? 1 }; break
      default: {
        const p = this.pad(node)
        const innerW = (fw ?? availW) != null ? Math.max(0, (fw ?? availW) - hOf(p)) : null
        const innerH = (fh ?? availH) != null ? Math.max(0, (fh ?? availH) - vOf(p)) : null
        const c = this.contentSize(n, innerW, innerH)
        size = { width: fw ?? (c.width + hOf(p)), height: fh ?? (c.height + vOf(p)) }
      }
    }
    if (a != null && a > 0 && fw == null && fh == null) size = { width: size.width, height: size.width / a }
    return { width: this.clampW(node, size.width), height: this.clampH(node, size.height) }
  }

  chipsWrap(node) { return node.type === 'chips' && node.wrap !== false && node.direction !== 'col' }
  chipsCol(node) { return node.type === 'chips' && node.direction === 'col' }

  contentSize(n, innerW, innerH) {
    const node = n.node
    const gap = node.gap ?? 0
    if (node.type === 'stack') {
      let w = 0, h = 0
      for (const c of n.children) {
        const s = this.intrinsic(c, innerW, innerH)
        w = Math.max(w, s.width + (c.node.dx ?? 0)); h = Math.max(h, s.height + (c.node.dy ?? 0))
      }
      return { width: w, height: h }
    }
    if (node.type === 'row' || node.type === 'chips') {
      if (this.chipsCol(node)) return this.colContent(n, innerW, gap)
      if ((node.wrap === true || this.chipsWrap(node)) && innerW != null) {
        const lines = this.wrapLines(n, innerW, gap)
        const h = lines.reduce((acc, l) => acc + l.height, 0) + gap * Math.max(0, lines.length - 1)
        const w = lines.length ? Math.max(...lines.map((l) => l.width)) : 0
        return { width: Math.min(w, innerW), height: h }
      }
      let w = 0, h = 0
      n.children.forEach((c, i) => {
        const s = this.intrinsic(c, null, innerH)
        w += s.width + (i > 0 ? gap : 0); h = Math.max(h, s.height)
      })
      return { width: w, height: h }
    }
    return this.colContent(n, innerW, gap)
  }

  colContent(n, innerW, gap) {
    let w = 0, h = 0
    n.children.forEach((c, i) => {
      const s = this.intrinsic(c, innerW, null)
      h += s.height + (i > 0 ? gap : 0); w = Math.max(w, s.width)
    })
    return { width: w, height: h }
  }

  wrapLines(n, width, gap) {
    const lines = []
    let cur = { items: [], width: 0, height: 0 }
    for (const c of n.children) {
      const s = this.intrinsic(c, width, null)
      const need = cur.items.length === 0 ? s.width : cur.width + gap + s.width
      if (cur.items.length && need > width + 0.01) { lines.push(cur); cur = { items: [], width: 0, height: 0 } }
      cur.items.push([c, s])
      cur.width = cur.items.length === 1 ? s.width : cur.width + gap + s.width
      cur.height = Math.max(cur.height, s.height)
    }
    if (cur.items.length) lines.push(cur)
    return lines
  }

  layout(n, frame) {
    n.frame = frame
    const node = n.node
    if (node.type === 'text') {
      const w = Math.max(0, frame.width)
      const [m, r] = this.fitText(n, w)
      n.text = r
      n.overflow = m.height - frame.height
      return
    }
    if (!n.children.length) return
    const p = this.pad(node)
    const inner = rect(frame.x + p.left, frame.y + p.top, Math.max(0, frame.width - hOf(p)), Math.max(0, frame.height - vOf(p)))
    const gap = node.gap ?? 0
    if (node.type === 'stack') this.layoutStack(n, inner)
    else if (node.type === 'row' || node.type === 'chips') {
      if (this.chipsCol(node)) this.layoutFlex(n, inner, gap, false)
      else if (node.wrap === true || this.chipsWrap(node)) this.layoutWrap(n, inner, gap)
      else this.layoutFlex(n, inner, gap, true)
    } else this.layoutFlex(n, inner, gap, false)
  }

  layoutStack(n, inner) {
    for (const c of n.children) {
      const cn = c.node
      const fw = this.fixed(cn.w, inner.width), fh = this.fixed(cn.h, inner.height)
      let s = this.intrinsic(c, inner.width, inner.height)
      if (this.isFill(cn.w) || (fw == null && cn.type !== 'text' && cn.type !== 'icon' && cn.aspect == null && cn.type !== 'rect')) s = { ...s, width: inner.width }
      if (this.isFill(cn.h) || (fh == null && (cn.type === 'image' || cn.type === 'col' || cn.type === 'row' || cn.type === 'stack') && cn.aspect == null)) s = { ...s, height: inner.height }
      if (cn.type === 'text' && fw == null) s = { width: inner.width, height: this.intrinsic(c, inner.width, inner.height).height }
      if (cn.type === 'rect' && fw == null && !this.isFill(cn.w)) s = { ...s, width: inner.width }
      if (cn.type === 'rect' && fh == null && !this.isFill(cn.h)) s = { ...s, height: inner.height }
      s = { width: Math.min(s.width, inner.width), height: Math.min(s.height, inner.height) }
      const [ax, ay] = this.placement(cn.place)
      const x = inner.x + (inner.width - s.width) * ax + (cn.dx ?? 0)
      const y = inner.y + (inner.height - s.height) * ay + (cn.dy ?? 0)
      this.layout(c, rect(x, y, s.width, s.height))
    }
  }

  placement(place) {
    if (place == null) return [0, 0]
    let ax = 0, ay = 0
    const parts = place.split('-').filter((p) => p.length)
    for (const p of parts) {
      if (p === 'top') ay = 0
      else if (p === 'bottom') ay = 1
      else if (p === 'left') ax = 0
      else if (p === 'right') ax = 1
      else if (p === 'center') {
        if (parts.length === 1) { ax = 0.5; ay = 0.5 } else if (parts[0] === p) ay = 0.5; else ax = 0.5
      }
    }
    if (parts.length === 1 && parts[0] === 'center') return [0.5, 0.5]
    return [ax, ay]
  }

  layoutWrap(n, inner, gap) {
    const lines = this.wrapLines(n, inner.width, gap)
    const totalH = lines.reduce((acc, l) => acc + l.height, 0) + gap * Math.max(0, lines.length - 1)
    const [y0, stepExtra] = this.mainOffset(n.node.justify, inner.height - totalH, lines.length)
    let y = inner.y + y0
    for (const line of lines) {
      const freeW = inner.width - line.width
      const [x0, extra] = this.mainOffset(n.node.justify, freeW, line.items.length)
      let x = inner.x + x0
      for (const [c, s] of line.items) {
        const ay = this.crossOffset(c.node.alignSelf ?? n.node.align ?? 'start', line.height - s.height)
        this.layout(c, rect(x, y + ay, s.width, s.height))
        x += s.width + gap + extra
      }
      y += line.height + gap + stepExtra
    }
  }

  mainOffset(j, free, count) {
    const f = Math.max(0, free)
    switch (j ?? 'start') {
      case 'center': return [f / 2, 0]
      case 'end': return [f, 0]
      case 'between': return [0, count > 1 ? f / (count - 1) : 0]
      case 'around': { const b = f / Math.max(count, 1); return [b / 2, b] }
      default: return [0, 0]
    }
  }

  crossOffset(a, free) {
    if (a === 'center') return Math.max(0, free) / 2
    if (a === 'end') return Math.max(0, free)
    return 0
  }

  layoutFlex(n, inner, gap, row) {
    const kids = n.children
    if (!kids.length) return
    const mainAvail = row ? inner.width : inner.height
    const crossAvail = row ? inner.height : inner.width
    const ks = []
    for (const c of kids) {
      const node = c.node
      const mainLen = row ? node.w : node.h
      const crossLen = row ? node.h : node.w
      const align = node.alignSelf ?? n.node.align ?? 'stretch'
      const stretch = align === 'stretch' && this.fixed(crossLen, crossAvail) == null && !this.isFill(crossLen) && node.aspect == null
      const fc = this.fixed(crossLen, crossAvail)
      let cross = fc != null ? fc
        : (this.isFill(crossLen) || stretch) ? crossAvail
          : row ? this.intrinsic(c, null, crossAvail).height : this.intrinsic(c, crossAvail, null).width
      cross = row ? this.clampH(node, Math.min(cross, crossAvail)) : this.clampW(node, Math.min(cross, crossAvail))
      let grow = node.grow ?? 0
      let basis
      const pct = node.pct, item = c.item
      const fm = this.fixed(mainLen, mainAvail)
      const a = node.aspect
      if (pct != null && item) {
        const byMax = pct.endsWith('/max'), bySum = pct.endsWith('/sum')
        const key = (byMax || bySum ? pct.slice(0, -4) : pct).replace(/^\$+/, '')
        const v = swiftParseDouble(item.value(key)) ?? 0
        let denom = 100
        if (byMax) denom = Math.max(1e-9, swiftParseDouble(item.value(`${key}.max`)) ?? 1)
        if (bySum) denom = Math.max(1e-9, swiftParseDouble(item.value(`${key}.sum`)) ?? 1)
        basis = Math.max(0, mainAvail - gap * (kids.length - 1)) * Math.min(Math.max(v / denom, 0), 1)
      } else if (fm != null) basis = fm
      else if (this.isFill(mainLen)) { basis = 0; grow = Math.max(grow, 1) }
      else if (a != null && a > 0) basis = row ? cross * a : cross / a
      else {
        const s = row ? this.intrinsic(c, null, cross) : this.intrinsic(c, cross, null)
        basis = row ? s.width : s.height
      }
      const defaultShrink = (fm != null || node.pct != null) ? 0
        : ['text', 'col', 'row', 'chips', 'stack', 'spacer'].includes(node.type) ? 1 : 0
      const shrink = node.shrink ?? defaultShrink
      const minMain = (row ? node.minW : node.minH) ?? 0
      const maxMain = (row ? node.maxW : node.maxH) ?? Infinity
      ks.push({ basis: Math.min(Math.max(basis, minMain), maxMain), cross, grow, shrink, minMain, maxMain })
    }
    const gaps = gap * (kids.length - 1)
    const sizes = ks.map((k) => k.basis)
    let free = mainAvail - gaps - sizes.reduce((a, b) => a + b, 0)
    if (free > 0) {
      const active = new Set(ks.map((_, i) => i).filter((i) => ks[i].grow > 0))
      let guard = 0
      while (free > 0.001 && active.size && guard < 8) {
        let total = 0
        for (const i of active) total += ks[i].grow
        let used = 0
        for (const i of [...active]) {
          const add = free * ks[i].grow / total
          const want = sizes[i] + add
          if (want >= ks[i].maxMain) { used += ks[i].maxMain - sizes[i]; sizes[i] = ks[i].maxMain; active.delete(i) }
          else { sizes[i] = want; used += add }
        }
        free -= used; guard += 1
      }
    } else if (free < 0) {
      let deficit = -free
      const active = new Set(ks.map((_, i) => i).filter((i) => ks[i].shrink > 0 && sizes[i] > ks[i].minMain))
      let guard = 0
      while (deficit > 0.001 && active.size && guard < 8) {
        let weight = 0
        for (const i of active) weight += ks[i].shrink * ks[i].basis
        if (!(weight > 0)) break
        let took = 0
        for (const i of [...active]) {
          const cut = deficit * ks[i].shrink * ks[i].basis / weight
          const want = sizes[i] - cut
          if (want <= ks[i].minMain) { took += sizes[i] - ks[i].minMain; sizes[i] = ks[i].minMain; active.delete(i) }
          else { sizes[i] = want; took += cut }
        }
        deficit -= took; guard += 1
      }
    }
    const used = sizes.reduce((a, b) => a + b, 0) + gaps
    const [off0, offStep] = this.mainOffset(n.node.justify, mainAvail - used, kids.length)
    let cursor = (row ? inner.x : inner.y) + off0
    kids.forEach((c, i) => {
      const main = Math.max(0, sizes[i])
      const cross = ks[i].cross
      const align = c.node.alignSelf ?? n.node.align ?? 'stretch'
      const co = this.crossOffset(align, crossAvail - cross)
      const f = row ? rect(cursor, inner.y + co, main, cross) : rect(inner.x + co, cursor, cross, main)
      this.layout(c, f)
      cursor += main + gap + offStep
    })
  }

  selectRoot() {
    for (const v of this.spec.variants || []) {
      const ok = v.when.split('&').filter((p) => p.length).every((part) => {
        const e = part.trim()
        const key = /^[A-Za-z]*/.exec(e)[0]
        return ['w', 'h', 'ratio'].includes(key) ? SpecCondition.box(e, this.box.width, this.box.height) : this.evaluate(e, null)
      })
      if (ok) return v.root
    }
    return this.spec.root
  }

  prepare(n) {
    n.textCache.clear()
    let g = 1
    if (n.base.type === 'text') {
      const design = this.baseSize(n.base)
      const legible = this.legibleSize(n.base, design)
      g = design > 0 ? Math.max(design, legible) / design : 1
    } else {
      for (const c of n.children) if (c.base.type === 'text') g = Math.max(g, this.prepare(c))
      for (const c of n.children) if (c.base.type !== 'text') this.prepare(c)
    }
    n.node = g > 1 ? this.grown(n.base, g) : n.base
    return n.base.type === 'text' ? g : 1
  }

  legibleSize(node, design) {
    const f = SpecLegibility.floor(design, node.role, this.renderScale * this.scale)
    return f > design ? design + (f - design) * this.strength : 0
  }

  grown(b, g) {
    const pt = (l) => (isPt(l) ? { pt: l.pt * g } : l)
    const m = (v) => (v != null ? v * g : v)
    return { ...b, w: pt(b.w), h: pt(b.h), minW: m(b.minW), maxW: m(b.maxW), minH: m(b.minH), maxH: m(b.maxH) }
  }

  run(root) {
    let b = this.box
    this.scale = 1
    this.lifted = false
    this.prepare(root)
    const steps = this.spec.fitScale
    if (steps && steps.length) {
      let chosen = false
      for (let i = 0; i < steps.length; i++) {
        const k = steps[i]
        if (!(k > 0)) continue
        this.scale = k; this.prepare(root)
        const kb = { width: this.box.width / k, height: this.box.height / k }
        const need = this.intrinsic(root, kb.width, null).height
        if (need <= kb.height + 0.5 || i === steps.length - 1) { b = kb; chosen = true; break }
      }
      if (!chosen) { this.scale = 1; this.prepare(root) }
    }
    this.layout(root, rect(0, 0, b.width, b.height))
  }

  collisions(root) {
    const out = new Set()
    const texts = []
    const walk = (n, parent) => {
      if (parent) {
        const a = n.frame, b = parent.frame
        if (a.x < b.x - 1 || a.y < b.y - 1 || a.x + a.width > b.x + b.width + 1 || a.y + a.height > b.y + b.height + 1) out.add('out:' + n.id)
      }
      if (n.text && n.text.string.length) texts.push(n)
      n.children.forEach((c) => walk(c, n))
    }
    walk(root, null)
    for (let i = 0; i < texts.length; i++) for (let j = i + 1; j < texts.length; j++) {
      const a = texts[i].frame, b = texts[j].frame
      const w = Math.min(a.x + a.width, b.x + b.width) - Math.max(a.x, b.x)
      const h = Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y)
      if (w > 1 && h > 1) out.add('hit:' + texts[i].id + '|' + texts[j].id)
    }
    return out
  }

  texts(n, out) {
    if (n.node.type === 'image' || n.node.type === 'icon') {
      out.set(n.id, { size: Math.min(n.frame.width, n.frame.height) * this.scale * this.renderScale, overflow: false, target: 0, image: true })
    }
    if (n.text) {
      const t = n.text
      out.set(n.id, { size: t.size * this.scale * this.renderScale, overflow: n.overflow > Math.max(0.5, t.size * 0.3),
        target: SpecLegibility.target(this.baseSize(n.base), n.base.role), image: false })
    }
    n.children.forEach((c) => this.texts(c, out))
  }

  solve() {
    const root = this.expand(this.selectRoot(), 'r', null, 0)
    if (!root) return []
    this.strength = 1
    this.run(root)
    if (this.lifted) {
      this.strength = 0
      this.run(root)
      const base = new Map()
      this.texts(root, base)
      const baseHits = this.collisions(root)
      let ok = false
      for (const t of SpecLegibility.STEPS) {
        this.strength = t
        this.run(root)
        const now = new Map()
        this.texts(root, now)
        ok = [...now].every(([id, v]) => {
          const o = base.get(id)
          if (!o) return true
          if (v.image) return v.size >= o.size * SpecLegibility.IMAGE_KEEP - 0.01
          return v.size >= Math.min(o.size, v.target) - 0.01 && (!v.overflow || o.overflow)
        })
        if (ok) { const hits = this.collisions(root); ok = [...hits].every((h) => baseHits.has(h)) }
        if (ok) break
      }
      if (!ok) { this.strength = 0; this.run(root) }
    }
    const out = []
    const walk = (n) => {
      out.push({ id: n.id, node: n.node, frame: rect(r2(n.frame.x), r2(n.frame.y), r2(n.frame.width), r2(n.frame.height)),
        text: n.text, item: n.item, depth: n.depth })
      n.children.forEach(walk)
    }
    walk(root)
    return out
  }
}
