import UIKit

// MARK: - ลายพื้น (= `SpecPatternView` · drawPattern ใน spec-shapes.js · SpecPatterns.kt)
//
// ทุกลายเป็นเรขาคณิตล้วนจากพารามิเตอร์ชุดเดียว (`size` · `width` · `angle` · `color`/`color2`) — วาดลง CGContext
// ตัวเลขทุกตัวตรงกับฝั่ง SwiftUI ทีละบรรทัด (รวม LCG ของ `speckle` ที่ต้องได้จุดเดียวกันทุกแพลตฟอร์ม)

enum SpecRenderPatterns {
    /// รูปของลายขนาด `size` หน่วยออกแบบ ที่ความละเอียด `scale` พิกเซลต่อหน่วย (โปร่งนอกลาย)
    static func image(_ pat: SpecPattern, color: UIColor, color2: UIColor, size sz: CGSize, scale: CGFloat) -> UIImage? {
        guard sz.width >= 1, sz.height >= 1 else { return nil }
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = max(1, scale)
        fmt.opaque = false
        return UIGraphicsImageRenderer(size: sz, format: fmt).image { rc in
            draw(pat, color: color, color2: color2, size: sz, in: rc.cgContext)
        }
    }

    static func draw(_ pat: SpecPattern, color: UIColor, color2: UIColor, size sz: CGSize, in ctx: CGContext) {
        let s = CGFloat(pat.size ?? 12)
        let w = CGFloat(pat.width ?? max(1, s * 0.12))
        guard s > 0 else { return }
        switch pat.kind {
        case "gingham":
            // ผ้าตาราง: แถบแนวตั้ง + แนวนอนสีเดียวกันโปร่งครึ่งหนึ่ง ทับกันเป็นช่องเข้ม
            let band = s / 2
            ctx.setFillColor(color.withAlphaComponent(color.specAlpha * 0.45).cgColor)
            var x: CGFloat = 0
            while x < sz.width { ctx.fill(CGRect(x: x, y: 0, width: band, height: sz.height)); x += s }
            var y: CGFloat = 0
            while y < sz.height { ctx.fill(CGRect(x: 0, y: y, width: sz.width, height: band)); y += s }
        case "stripes", "lines":
            let a = CGFloat((pat.angle ?? (pat.kind == "stripes" ? 45 : 0)) * .pi / 180)
            let diag = hypot(sz.width, sz.height)
            ctx.saveGState()
            ctx.translateBy(x: sz.width / 2, y: sz.height / 2)
            ctx.rotate(by: a)
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(w)
            var d: CGFloat = -diag
            while d < diag { ctx.move(to: CGPoint(x: d, y: -diag)); ctx.addLine(to: CGPoint(x: d, y: diag)); d += s }
            ctx.strokePath()
            ctx.restoreGState()
        case "dots":
            ctx.setFillColor(color.cgColor)
            var y: CGFloat = s / 2
            while y < sz.height {
                var x: CGFloat = s / 2
                while x < sz.width { ctx.fillEllipse(in: CGRect(x: x - w / 2, y: y - w / 2, width: w, height: w)); x += s }
                y += s
            }
        case "grid":
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(w)
            var x: CGFloat = 0
            while x <= sz.width { ctx.move(to: CGPoint(x: x, y: 0)); ctx.addLine(to: CGPoint(x: x, y: sz.height)); x += s }
            var y: CGFloat = 0
            while y <= sz.height { ctx.move(to: CGPoint(x: 0, y: y)); ctx.addLine(to: CGPoint(x: sz.width, y: y)); y += s }
            ctx.strokePath()
        case "sprockets":
            // รูฟิล์ม: สี่เหลี่ยมมุมมนเรียงตามขอบบนและล่าง (สูง = width · กว้าง = size×0.55 · ระยะจากขอบ = angle)
            let hole = CGSize(width: s * 0.55, height: w)
            let inset = CGFloat(pat.angle ?? 4)
            ctx.setFillColor(color.cgColor)
            var x: CGFloat = s * 0.25
            while x + hole.width < sz.width {
                for y in [inset, sz.height - inset - hole.height] {
                    ctx.addPath(UIBezierPath(roundedRect: CGRect(x: x, y: y, width: hole.width, height: hole.height), cornerRadius: 1.5).cgPath)
                    ctx.fillPath()
                }
                x += s
            }
        case "rings":
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(w)
            var r = s
            let R = hypot(sz.width, sz.height) / 2
            while r < R { ctx.strokeEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)); r += s }
        case "speckle":
            // จุดสุ่มแบบกำหนด seed (LCG · UInt32 wrap) — ทุกแพลตฟอร์มได้จุดเดียวกัน
            var seed: UInt32 = 1_234_567
            func next() -> CGFloat { seed = seed &* 1_664_525 &+ 1_013_904_223; return CGFloat(seed % 10_000) / 10_000 }
            let n = Int((sz.width * sz.height) / (s * s))
            for _ in 0..<max(0, n) {
                let x = next() * sz.width, y = next() * sz.height, r = w * (0.5 + next())
                ctx.setFillColor((next() > 0.5 ? color : color2).cgColor)
                ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
            }
        case "barcode":
            let bars: [CGFloat] = [3, 1, 1, 2, 4, 1, 2, 3, 1, 1, 3, 2, 1, 4, 1, 2, 2, 1, 3, 1, 1, 2, 4, 1, 2, 1, 3]
            let unit = sz.width / bars.reduce(0, +)
            ctx.setFillColor(color.cgColor)
            var x: CGFloat = 0
            for (i, b) in bars.enumerated() {
                if i % 2 == 0 { ctx.fill(CGRect(x: x, y: 0, width: b * unit, height: sz.height)) }
                x += b * unit
            }
        case "guilloche":
            // ลายกิโยเช่: เส้นโค้งสองชุดรอบศูนย์กลาง (สูตรเดียวกับ `Guilloche` ของตรารับรอง)
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            let R = min(sz.width, sz.height) / 2
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(w * 0.5)
            let sets: [(Double, Double, Double, Int)] = [(16, 0.115, 0.86, 16), (9, 0.10, 0.60, 12)]
            for (n, amp, base, count) in sets {
                for k in 0..<count {
                    let phi = Double(k) / Double(count) * 2 * .pi / n
                    let steps = 420
                    for i in 0...steps {
                        let t = Double(i) / Double(steps) * 2 * .pi
                        let r = R * CGFloat(base + amp * cos(n * t + phi))
                        let pt = CGPoint(x: c.x + r * CGFloat(cos(t)), y: c.y + r * CGFloat(sin(t)))
                        if i == 0 { ctx.move(to: pt) } else { ctx.addLine(to: pt) }
                    }
                    ctx.strokePath()
                }
            }
        default:
            break
        }
    }

    // MARK: ลายแผ่นของถาด (= `PlatePatternLayer` · `BackdropStripes` · `BackdropDiamonds`)

    /// สีแถบของลายแผ่น = เฉดเข้มของแผ่นเอง (ผสมดำครึ่งหนึ่ง · สูตร `Color.mixed(with: .black, by: 0.5)`)
    static func plateBand(_ sheet: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        sheet.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r * 0.5, green: g * 0.5, blue: b * 0.5, alpha: 1)
    }

    static func plateImage(_ kind: SpecPlatePattern, sheet: UIColor, size sz: CGSize, scale: CGFloat) -> UIImage? {
        guard kind != .plain, sheet.specAlpha > 0.002, sz.width >= 1, sz.height >= 1 else { return nil }
        let band = plateBand(sheet)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = max(1, scale); fmt.opaque = false
        return UIGraphicsImageRenderer(size: sz, format: fmt).image { rc in
            let ctx = rc.cgContext
            ctx.setFillColor(band.cgColor)
            switch kind {
            case .plain: break
            case .stripe:
                let bw: CGFloat = 15
                var x = bw * 0.5
                while x < sz.width { ctx.fill(CGRect(x: x, y: 0, width: bw, height: sz.height)); x += bw * 2 }
            case .diamond:
                let w: CGFloat = 42, h = w * 1.75
                var y: CGFloat = 0
                while y <= sz.height + h / 2 {
                    var x: CGFloat = 0
                    while x <= sz.width + w / 2 {
                        ctx.move(to: CGPoint(x: x, y: y - h / 2))
                        ctx.addLine(to: CGPoint(x: x + w / 2, y: y))
                        ctx.addLine(to: CGPoint(x: x, y: y + h / 2))
                        ctx.addLine(to: CGPoint(x: x - w / 2, y: y))
                        ctx.closePath()
                        x += w
                    }
                    y += h
                }
                ctx.fillPath()
            }
        }
    }
}

extension UIColor {
    /// อัลฟาของสี (0 เมื่ออ่านไม่ได้)
    var specAlpha: CGFloat {
        var a: CGFloat = 0
        getRed(nil, green: nil, blue: nil, alpha: &a)
        return a
    }
}
