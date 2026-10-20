import SwiftUI

// MARK: - ลายพื้นของผัง (รายการปิด · ทุกแพลตฟอร์มวาดด้วยกติกาเดียวกัน — WIDGET-SPEC.md §6)
//
// ทุกลายเป็นเรขาคณิตล้วน (ไม่มีรูปบิตแมป) จึงวาดใหม่ได้ทุกแพลตฟอร์มจากพารามิเตอร์ชุดเดียว:
// `size` = ระยะซ้ำ (pt) · `width` = ความหนาเส้น/จุด · `angle` = องศาของเส้น · `color`/`color2`
struct SpecPatternView: View {
    let pattern: SpecPattern
    let color: Color
    let color2: Color

    var body: some View {
        Canvas { ctx, sz in
            let s = CGFloat(pattern.size ?? 12)
            let w = CGFloat(pattern.width ?? max(1, s * 0.12))
            switch pattern.kind {
            case "gingham":
                // ผ้าตาราง: แถบแนวตั้ง + แนวนอนสีเดียวกันโปร่ง ครึ่งหนึ่ง ทับกันเป็นช่องเข้ม
                let band = s / 2
                var x: CGFloat = 0
                while x < sz.width { ctx.fill(Path(CGRect(x: x, y: 0, width: band, height: sz.height)), with: .color(color.opacity(0.45))); x += s }
                var y: CGFloat = 0
                while y < sz.height { ctx.fill(Path(CGRect(x: 0, y: y, width: sz.width, height: band)), with: .color(color.opacity(0.45))); y += s }
            case "stripes", "lines":
                let a = Angle.degrees(pattern.angle ?? (pattern.kind == "stripes" ? 45 : 0)).radians
                let diag = hypot(sz.width, sz.height)
                var p = Path()
                var d: CGFloat = -diag
                while d < diag { p.move(to: CGPoint(x: d, y: -diag)); p.addLine(to: CGPoint(x: d, y: diag)); d += s }
                let t = CGAffineTransform(translationX: sz.width / 2, y: sz.height / 2).rotated(by: a)
                ctx.stroke(p.applying(t), with: .color(color), lineWidth: w)
            case "dots":
                var y: CGFloat = s / 2
                while y < sz.height { var x: CGFloat = s / 2
                    while x < sz.width { ctx.fill(Path(ellipseIn: CGRect(x: x - w / 2, y: y - w / 2, width: w, height: w)), with: .color(color)); x += s }
                    y += s }
            case "grid":
                var p = Path()
                var x: CGFloat = 0
                while x <= sz.width { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: sz.height)); x += s }
                var y: CGFloat = 0
                while y <= sz.height { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: sz.width, y: y)); y += s }
                ctx.stroke(p, with: .color(color), lineWidth: w)
            case "sprockets":
                // รูฟิล์ม: สี่เหลี่ยมมุมมนเรียงตามขอบบนและล่าง (สูง = width · กว้าง = size×0.55)
                let hole = CGSize(width: s * 0.55, height: w)
                let inset = CGFloat(pattern.angle ?? 4)   // ระยะจากขอบ (ยืม angle เป็นพารามิเตอร์ตัวที่สาม)
                var x: CGFloat = s * 0.25
                while x + hole.width < sz.width {
                    for y in [inset, sz.height - inset - hole.height] {
                        ctx.fill(Path(roundedRect: CGRect(x: x, y: y, width: hole.width, height: hole.height), cornerRadius: 1.5), with: .color(color))
                    }
                    x += s
                }
            case "rings":
                let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
                var r = s
                let R = hypot(sz.width, sz.height) / 2
                while r < R { ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(color), lineWidth: w); r += s }
            case "speckle":
                // จุดสุ่มแบบกำหนด seed (LCG) — ทุกแพลตฟอร์มได้จุดเดียวกัน
                var seed: UInt32 = 1_234_567
                func next() -> CGFloat { seed = seed &* 1_664_525 &+ 1_013_904_223; return CGFloat(seed % 10_000) / 10_000 }
                let n = Int((sz.width * sz.height) / (s * s))
                for _ in 0..<n {
                    let x = next() * sz.width, y = next() * sz.height, r = w * (0.5 + next())
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(next() > 0.5 ? color : color2))
                }
            case "barcode":
                let bars: [CGFloat] = [3, 1, 1, 2, 4, 1, 2, 3, 1, 1, 3, 2, 1, 4, 1, 2, 2, 1, 3, 1, 1, 2, 4, 1, 2, 1, 3]
                let unit = sz.width / bars.reduce(0, +)
                var x: CGFloat = 0
                for (i, b) in bars.enumerated() {
                    if i % 2 == 0 { ctx.fill(Path(CGRect(x: x, y: 0, width: b * unit, height: sz.height)), with: .color(color)) }
                    x += b * unit
                }
            case "guilloche":
                // ลายกิโยเช่: เส้นโค้งสองชุดรอบศูนย์กลาง (สูตรเดียวกับ `Guilloche` ของตรารับรอง)
                let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
                let R = min(sz.width, sz.height) / 2
                let sets: [(Double, Double, Double, Int)] = [(16, 0.115, 0.86, 16), (9, 0.10, 0.60, 12)]
                for (n, amp, base, count) in sets {
                    for k in 0..<count {
                        let phi = Double(k) / Double(count) * 2 * .pi / n
                        var p = Path()
                        let steps = 420
                        for i in 0...steps {
                            let t = Double(i) / Double(steps) * 2 * .pi
                            let r = R * CGFloat(base + amp * cos(n * t + phi))
                            let pt = CGPoint(x: c.x + r * CGFloat(cos(t)), y: c.y + r * CGFloat(sin(t)))
                            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                        }
                        ctx.stroke(p, with: .color(color), lineWidth: w * 0.5)
                    }
                }
            default:
                break
            }
        }
        .opacity(pattern.opacity ?? 1)
        .allowsHitTesting(false)
    }
}

/// รูปร่างของกล่อง — `shape` ในผัง: `tag:16` · `heart` · `scallop:8` · `zigzag:10` · ไม่ใส่ = สี่เหลี่ยมมุมมน
enum SpecShapes {
    static func make(_ spec: String?, corner: CGFloat) -> AnyShape {
        guard let spec else { return AnyShape(RoundedRectangle(cornerRadius: corner, style: .continuous)) }
        let parts = spec.split(separator: ":").map(String.init)
        let p = parts.count > 1 ? Double(parts[1]) : nil
        switch parts[0] {
        case "tag":     return AnyShape(TagShape(cut: CGFloat(p ?? 16)))
        case "heart":   return AnyShape(ScrapHeart())
        case "scallop": return AnyShape(SealScallop(petals: Int(p ?? 8)))
        case "zigzag":  return AnyShape(ZigzagEdge(tooth: CGFloat(p ?? 10)))
        case "circle":  return AnyShape(Circle())
        default:        return AnyShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
    }
}
