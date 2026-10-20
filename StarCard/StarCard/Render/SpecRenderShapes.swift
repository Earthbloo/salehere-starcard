import UIKit

// MARK: - รูปร่างของกล่อง (= `SpecShapes` · spec-shapes.js · SpecPatterns.kt)
//
// `shape` ในผัง: `tag:16` · `heart` · `scallop:8` · `zigzag:10` · `circle` · ไม่ใส่ = สี่เหลี่ยมมุมมน
// สี่เหลี่ยมมุมมนของ SwiftUI เป็น `.continuous` (squircle) — ฝั่ง CoreAnimation ใช้ `cornerCurve = .continuous`
// กับ `cornerRadius` ได้ผลเดียวกันโดยไม่ต้องมี path (ดู `SpecRenderShape.apply`)

enum SpecRenderShape {
    /// มุมมน (squircle) รัศมี `r` — วาดด้วย `cornerRadius` ของ layer
    case rounded(CGFloat)
    /// path อิสระ (tag · heart · scallop · zigzag · circle)
    case path((CGRect) -> CGPath)

    static func make(_ spec: String?, corner: CGFloat) -> SpecRenderShape {
        guard let spec else { return .rounded(corner) }
        let parts = spec.split(separator: ":").map(String.init)
        let p = parts.count > 1 ? Double(parts[1]) : nil
        switch parts[0] {
        case "tag":     return .path { Self.tag($0, cut: CGFloat(p ?? 16)) }
        case "heart":   return .path { Self.heart($0) }
        case "scallop": return .path { Self.scallop($0, petals: Int(p ?? 8)) }
        case "zigzag":  return .path { Self.zigzag($0, tooth: CGFloat(p ?? 10)) }
        case "circle":  return .path { CGPath(ellipseIn: Self.square($0), transform: nil) }
        default:        return .rounded(corner)
        }
    }

    /// path ของรูปร่างในกรอบ — มุมมนใช้ `UIBezierPath` (มุมกลม ไม่ใช่ squircle · ใช้เฉพาะที่ต้องมี path เช่นเส้นประ)
    func path(in rect: CGRect) -> CGPath {
        switch self {
        case .rounded(let r):
            let rr = max(0, min(r, rect.width / 2, rect.height / 2))
            return UIBezierPath(roundedRect: rect, cornerRadius: rr).cgPath
        case .path(let f):
            return f(rect)
        }
    }

    /// ตัด `layer` เข้ารูป — มุมมน: `cornerRadius` + `.continuous` (เท่า SwiftUI) · รูปอื่น: mask ด้วย path
    func clip(_ layer: CALayer) {
        switch self {
        case .rounded(let r):
            layer.cornerRadius = max(0, min(r, layer.bounds.width / 2, layer.bounds.height / 2))
            layer.cornerCurve = .continuous
            layer.masksToBounds = true
            layer.mask = nil
        case .path:
            layer.cornerRadius = 0
            layer.masksToBounds = false
            let m = CAShapeLayer()
            m.frame = layer.bounds
            m.path = path(in: layer.bounds)
            layer.mask = m
        }
    }

    // MARK: path จริง (สูตรเดียวกับ Shape ของ SwiftUI ทีละจุด)

    private static func square(_ r: CGRect) -> CGRect {
        let s = min(r.width, r.height)
        return CGRect(x: r.midX - s / 2, y: r.midY - s / 2, width: s, height: s)
    }

    static func tag(_ r: CGRect, cut: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: r.minX + cut, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + cut, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - r.height * 0.3))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.3))
        p.closeSubpath()
        return p
    }

    static func heart(_ r: CGRect) -> CGPath {
        let w = r.width, h = r.height
        let p = CGMutablePath()
        p.move(to: CGPoint(x: r.midX, y: r.minY + h * 0.92))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.33),
                   control1: CGPoint(x: r.minX + w * 0.3, y: r.minY + h * 0.72),
                   control2: CGPoint(x: r.minX, y: r.minY + h * 0.55))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.2),
                   control1: CGPoint(x: r.minX, y: r.minY + h * 0.02),
                   control2: CGPoint(x: r.minX + w * 0.4, y: r.minY - h * 0.02))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.33),
                   control1: CGPoint(x: r.minX + w * 0.6, y: r.minY - h * 0.02),
                   control2: CGPoint(x: r.maxX, y: r.minY + h * 0.02))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.92),
                   control1: CGPoint(x: r.maxX, y: r.minY + h * 0.55),
                   control2: CGPoint(x: r.minX + w * 0.7, y: r.minY + h * 0.72))
        p.closeSubpath()
        return p
    }

    static func scallop(_ rect: CGRect, petals: Int, depth: CGFloat = 0.075) -> CGPath {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let R = min(rect.width, rect.height) / 2
        let steps = max(1, petals) * 28
        let p = CGMutablePath()
        for i in 0...steps {
            let t = Double(i) / Double(steps) * 2 * .pi
            let r = R * (1 - depth + depth * CGFloat(cos(Double(petals) * t)))
            let pt = CGPoint(x: c.x + r * CGFloat(cos(t)), y: c.y + r * CGFloat(sin(t)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    static func zigzag(_ r: CGRect, tooth: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        let n = max(1, Int((r.width / max(tooth, 0.01)).rounded()))
        let step = r.width / CGFloat(n)
        var x = r.maxX
        for _ in 0..<n {
            p.addLine(to: CGPoint(x: x - step / 2, y: r.maxY))
            p.addLine(to: CGPoint(x: x - step, y: r.minY))
            x -= step
        }
        p.closeSubpath()
        return p
    }
}
