// รูปร่างของกล่องและลายพื้น (= SpecShapes · SpecPatterns.kt) — เป็นสตริง path ของ SVG / วาดลง canvas
//
// รูปร่าง: `tag:16` · `heart` · `scallop:8` · `zigzag:10` · `circle` · ไม่ใส่ = สี่เหลี่ยมมุมมน

const f2 = (v) => +v.toFixed(3)

export function roundRectPath(w, h, r) {
  r = Math.max(0, Math.min(r, w / 2, h / 2))
  if (r <= 0) return `M0 0H${f2(w)}V${f2(h)}H0Z`
  return `M${f2(r)} 0H${f2(w - r)}A${f2(r)} ${f2(r)} 0 0 1 ${f2(w)} ${f2(r)}V${f2(h - r)}A${f2(r)} ${f2(r)} 0 0 1 ${f2(w - r)} ${f2(h)}H${f2(r)}A${f2(r)} ${f2(r)} 0 0 1 0 ${f2(h - r)}V${f2(r)}A${f2(r)} ${f2(r)} 0 0 1 ${f2(r)} 0Z`
}

/** path ของรูปร่างในกรอบ w×h · null = ใช้มุมมนธรรมดา (`corner`) */
export function shapePath(spec, w, h, corner) {
  if (!spec) return roundRectPath(w, h, corner)
  const [name, arg] = spec.split(':')
  const p = arg !== undefined ? Number(arg) : null
  switch (name) {
    case 'tag': {
      const cut = p ?? 16
      return `M${f2(cut)} 0H${f2(w)}V${f2(h)}H${f2(cut)}L0 ${f2(h - h * 0.3)}V${f2(h * 0.3)}Z`
    }
    case 'heart': {
      const mid = w / 2, P = (x, y) => `${f2(x)} ${f2(y)}`
      return `M${P(mid, h * 0.92)}C${P(w * 0.3, h * 0.72)} ${P(0, h * 0.55)} ${P(0, h * 0.33)}`
        + `C${P(0, h * 0.02)} ${P(w * 0.4, -h * 0.02)} ${P(mid, h * 0.2)}`
        + `C${P(w * 0.6, -h * 0.02)} ${P(w, h * 0.02)} ${P(w, h * 0.33)}`
        + `C${P(w, h * 0.55)} ${P(w * 0.7, h * 0.72)} ${P(mid, h * 0.92)}Z`
    }
    case 'scallop': {
      const petals = Math.trunc(p ?? 8), depth = 0.075
      const cx = w / 2, cy = h / 2, r0 = Math.min(w, h) / 2, steps = petals * 28
      let d = ''
      for (let i = 0; i <= steps; i++) {
        const t = i / steps * 2 * Math.PI
        const r = r0 * (1 - depth + depth * Math.cos(petals * t))
        d += `${i ? 'L' : 'M'}${f2(cx + r * Math.cos(t))} ${f2(cy + r * Math.sin(t))}`
      }
      return d + 'Z'
    }
    case 'zigzag': {
      const tooth = p ?? 10
      const n = Math.max(1, Math.round(w / tooth)), step = w / n
      let d = `M0 0L${f2(w)} 0`
      let x = w
      for (let i = 0; i < n; i++) { d += `L${f2(x - step / 2)} ${f2(h)}L${f2(x - step)} 0`; x -= step }
      return d + 'Z'
    }
    case 'circle': {
      const r = Math.min(w, h) / 2, cx = w / 2, cy = h / 2
      return `M${f2(cx - r)} ${f2(cy)}A${f2(r)} ${f2(r)} 0 1 0 ${f2(cx + r)} ${f2(cy)}A${f2(r)} ${f2(r)} 0 1 0 ${f2(cx - r)} ${f2(cy)}Z`
    }
    default: return roundRectPath(w, h, corner)
  }
}

export const BARCODE = [3, 1, 1, 2, 4, 1, 2, 3, 1, 1, 3, 2, 1, 4, 1, 2, 2, 1, 3, 1, 1, 2, 4, 1, 2, 1, 3]

/** ลายพื้น (= `SpecPatternView`) ลง canvas ขนาด w×h หน่วยออกแบบ ที่ความละเอียด `px` ต่อหน่วย */
export function drawPattern(ctx, pat, color, color2, w, h) {
  const s = pat.size ?? 12
  const lw = pat.width ?? Math.max(1, s * 0.12)
  ctx.globalAlpha = pat.opacity ?? 1
  switch (pat.kind) {
    case 'gingham': {
      const band = s / 2
      ctx.fillStyle = color
      ctx.globalAlpha *= 0.45 // `color.opacity(0.45)` — css ของสีถูกคูณด้วย globalAlpha
      for (let x = 0; x < w; x += s) ctx.fillRect(x, 0, band, h)
      for (let y = 0; y < h; y += s) ctx.fillRect(0, y, w, band)
      break
    }
    case 'stripes': case 'lines': {
      const a = (pat.angle ?? (pat.kind === 'stripes' ? 45 : 0)) * Math.PI / 180
      const diag = Math.hypot(w, h)
      ctx.save(); ctx.translate(w / 2, h / 2); ctx.rotate(a)
      ctx.strokeStyle = color; ctx.lineWidth = lw
      ctx.beginPath()
      for (let d = -diag; d < diag; d += s) { ctx.moveTo(d, -diag); ctx.lineTo(d, diag) }
      ctx.stroke(); ctx.restore()
      break
    }
    case 'dots': {
      ctx.fillStyle = color
      for (let y = s / 2; y < h; y += s) for (let x = s / 2; x < w; x += s) { ctx.beginPath(); ctx.ellipse(x, y, lw / 2, lw / 2, 0, 0, 7); ctx.fill() }
      break
    }
    case 'grid': {
      ctx.strokeStyle = color; ctx.lineWidth = lw; ctx.beginPath()
      for (let x = 0; x <= w; x += s) { ctx.moveTo(x, 0); ctx.lineTo(x, h) }
      for (let y = 0; y <= h; y += s) { ctx.moveTo(0, y); ctx.lineTo(w, y) }
      ctx.stroke()
      break
    }
    case 'sprockets': {
      const hw = s * 0.55, hh = lw, inset = pat.angle ?? 4
      ctx.fillStyle = color
      for (let x = s * 0.25; x + hw < w; x += s) {
        for (const y of [inset, h - inset - hh]) { ctx.beginPath(); ctx.roundRect(x, y, hw, hh, 1.5); ctx.fill() }
      }
      break
    }
    case 'rings': {
      ctx.strokeStyle = color; ctx.lineWidth = lw
      const big = Math.hypot(w, h) / 2
      for (let r = s; r < big; r += s) { ctx.beginPath(); ctx.arc(w / 2, h / 2, r, 0, 7); ctx.stroke() }
      break
    }
    case 'speckle': {
      // จุดสุ่มแบบกำหนด seed (LCG · UInt32 wrap) — ทุกแพลตฟอร์มได้จุดเดียวกัน
      let seed = 1234567
      const next = () => { seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0; return (seed % 10000) / 10000 }
      const n = Math.trunc((w * h) / (s * s))
      for (let i = 0; i < n; i++) {
        const x = next() * w, y = next() * h, r = lw * (0.5 + next())
        ctx.fillStyle = next() > 0.5 ? color : color2
        ctx.beginPath(); ctx.ellipse(x + r / 2, y + r / 2, r / 2, r / 2, 0, 0, 7); ctx.fill()
      }
      break
    }
    case 'barcode': {
      const unit = w / BARCODE.reduce((a, b) => a + b, 0)
      let x = 0
      ctx.fillStyle = color
      BARCODE.forEach((b, i) => { if (i % 2 === 0) ctx.fillRect(x, 0, b * unit, h); x += b * unit })
      break
    }
    case 'guilloche': {
      const cx = w / 2, cy = h / 2, big = Math.min(w, h) / 2
      ctx.strokeStyle = color; ctx.lineWidth = lw * 0.5
      for (const [n, amp, base, count] of [[16, 0.115, 0.86, 16], [9, 0.10, 0.60, 12]]) {
        for (let k = 0; k < count; k++) {
          const phi = k / count * 2 * Math.PI / n
          ctx.beginPath()
          for (let i = 0; i <= 420; i++) {
            const t = i / 420 * 2 * Math.PI
            const r = big * (base + amp * Math.cos(n * t + phi))
            const x = cx + r * Math.cos(t), y = cy + r * Math.sin(t)
            if (i) ctx.lineTo(x, y); else ctx.moveTo(x, y)
          }
          ctx.stroke()
        }
      }
      break
    }
  }
  ctx.globalAlpha = 1
}

/** ลายแผ่นของถาด (ลายทาง · ข้าวหลามตัด) ด้วยสีแถบ `band` (= `BackdropStripes` · `BackdropDiamonds`) */
export function drawPlatePattern(ctx, kind, band, w, h) {
  ctx.fillStyle = band
  if (kind === 'stripe') {
    const bw = 15
    for (let x = bw * 0.5; x < w; x += bw * 2) ctx.fillRect(x, 0, bw, h)
  } else if (kind === 'diamond') {
    const dw = 42, dh = dw * 1.75
    ctx.beginPath()
    for (let y = 0; y <= h + dh / 2; y += dh) for (let x = 0; x <= w + dw / 2; x += dw) {
      ctx.moveTo(x, y - dh / 2); ctx.lineTo(x + dw / 2, y); ctx.lineTo(x, y + dh / 2); ctx.lineTo(x - dw / 2, y); ctx.closePath()
    }
    ctx.fill()
  }
}

/** canvas ขนาด w×h หน่วยออกแบบ ที่คมพอสำหรับการย่อ/ขยายของการ์ด */
export function makeCanvas(w, h, draw, density = 3) {
  const c = document.createElement('canvas')
  c.width = Math.max(1, Math.ceil(w * density))
  c.height = Math.max(1, Math.ceil(h * density))
  c.style.cssText = `position:absolute;left:0;top:0;width:${w}px;height:${h}px;pointer-events:none`
  const ctx = c.getContext('2d')
  ctx.scale(density, density)
  draw(ctx)
  return c
}
