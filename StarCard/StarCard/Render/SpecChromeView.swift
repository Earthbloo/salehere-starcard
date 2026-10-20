import UIKit

// MARK: - เปลือกของ widget (UIKit · iOS 16) — สูตรเดียวของ WIDGET-SPEC.md §2 + แผ่นแบบที่ iOS 16 วาดได้
//
//   s   = min(W / w0, H / h0)      ← ย่อ/ขยายทั้งก้อนด้วยแกนที่คับสุด
//   box = (W / s, H / s) − ระยะขอบใน ×2 ← กล่องผังในหน่วยออกแบบ · ระยะขอบใน 12 เมื่อมีแผ่น/ขอบ (ดู `contentInset`)
//
// แผ่น: glass = วัสดุเบลอของระบบ (`UIBlurEffect`) + ม่านขาวขุ่น/ดำจางตามหมึก (+ ย้อมสีเน้นบนชั้น verified) —
// Liquid Glass ของ iOS 26 ไม่มีบน 16.6 จึงเป็นของที่ยอมให้ต่าง (§6) · dim = ถ่านทึบ + เงายก · clear = ไม่มี · pane = glass
// ตัวเลขม่าน/หมึกชุดเดียวกับ `WidgetChrome.swift` — แอปส่งสีที่คิดแล้วมาใน `SpecChromeStyle`

/// นิสัยของชนิดที่ chrome ต้องรู้ (อ่านจากบล็อก `widget` ของผัง — `WidgetKind` ของแอป)
struct SpecChromeTraits {
    var drawsOwnSurface = false
    var drawsOwnBorder = false
    var isFullBleed = false
    var isTextLayer = false
    /// ชั้น verified — กระจกย้อมสีเน้น 13% (ยกเว้นการ์ดคู่สี)
    var verifiedTier = false
}

enum SpecChromeSurface: String { case glass, dim, clear, pane }

/// สี/ตัวเลขของธีมที่ chrome ใช้ — แอปเป็นคนคิด (หมึก · แผ่นเข้ม · สีเน้น · มุม)
struct SpecChromeStyle {
    var radius: CGFloat
    /// ม่านใต้กระจก — ขาวขุ่น 58% บนหมึกสว่าง · ดำจาง 16% บนหมึกมืด/คู่สี
    var veil: UIColor
    /// สีเน้นที่ย้อมกระจกชั้น verified (nil = ไม่ย้อม) — ความแรง 13% ใส่มาแล้ว
    var tint: UIColor?
    /// แผ่น "เข้ม" (`WidgetChrome.slab`)
    var slab: UIColor
    /// เงายกแผ่น — มีเฉพาะหมึกสว่าง (`InkStyle.lift` · `liftRadius`)
    var lift: UIColor
    var liftRadius: CGFloat
    var liftY: CGFloat
    /// เส้นขอบ 0.7pt (`ink.line(0.12)`)
    var line: UIColor
    /// วัสดุเบลอของกระจก
    var blur: UIBlurEffect.Style = .systemUltraThinMaterial
}

enum SpecChrome {
    static let textInset: CGFloat = 4
    static let textRadius: CGFloat = 10

    /// ระยะขอบในของเนื้อหา (= `WidgetChrome.contentInset`) — มีพื้นของ chrome หรือมีเส้นขอบ = 12 · pane / เต็มขอบ / วาดพื้นเอง = 0
    static func contentInset(_ t: SpecChromeTraits, surface: SpecChromeSurface, border: Bool) -> CGFloat {
        if t.isTextLayer { return textInset }
        let pane = surface == .pane
        let framed = pane || (!t.drawsOwnSurface && surface != .clear)
        let insetable = framed || (!t.drawsOwnSurface && border)
        return pane || t.isFullBleed || !insetable ? 0 : 12
    }

    /// สเกลทั้งก้อนกับกล่องผัง (หน่วยออกแบบ · ก่อนหักระยะขอบใน)
    static func layout(frame: CGSize, design: CGSize, isTextLayer: Bool) -> (scale: CGFloat, layout: CGSize) {
        let fw = max(frame.width, 1), fh = max(frame.height, 1)
        let s = isTextLayer ? 1 : min(fw / max(design.width, 1), fh / max(design.height, 1))
        return (s, CGSize(width: fw / s, height: fh / s))
    }
}

/// ใบหนึ่งใบพร้อมเปลือก — `content` คือ view ขนาดกล่องผัง (`SpecWidgetView`) ที่สร้างจากกล่องของ solver แล้ว
final class SpecChromeView: UIView {
    /// - Parameters:
    ///   - frame: กรอบของชิ้นบนหน้า (หน่วยออกแบบของหน้า)
    ///   - design: `WidgetSpec.design`
    ///   - content: ใบที่วาดแล้วในหน่วยผัง (ขนาด = `layout − inset×2`)
    init(frame: CGRect, design: CGSize, traits: SpecChromeTraits, surface rawSurface: SpecChromeSurface, border: Bool,
         style: SpecChromeStyle, content: UIView) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        let pane = rawSurface == .pane
        let surface: SpecChromeSurface = pane ? .glass : rawSurface
        let isText = traits.isTextLayer
        let radius = isText ? min(style.radius, SpecChrome.textRadius) : style.radius
        let framed = pane || (!traits.drawsOwnSurface && surface != .clear)
        let inset = SpecChrome.contentInset(traits, surface: rawSurface, border: border)
        let (s, layout) = SpecChrome.layout(frame: frame.size, design: design, isTextLayer: isText)

        // แผ่น
        let plate = UIView(frame: bounds)
        plate.isUserInteractionEnabled = false
        if framed {
            switch surface {
            case .glass, .pane:
                let blur = UIVisualEffectView(effect: UIBlurEffect(style: style.blur))
                blur.frame = bounds
                let veil = UIView(frame: bounds)
                veil.backgroundColor = style.veil
                blur.contentView.addSubview(veil)
                if let t = style.tint {
                    let tv = UIView(frame: bounds)
                    tv.backgroundColor = t
                    blur.contentView.addSubview(tv)
                }
                blur.layer.cornerRadius = radius
                blur.layer.cornerCurve = .continuous
                blur.clipsToBounds = true
                plate.addSubview(blur)
                if style.liftRadius > 0 {
                    plate.layer.shadowColor = style.lift.cgColor
                    plate.layer.shadowOpacity = 1
                    plate.layer.shadowRadius = style.liftRadius
                    plate.layer.shadowOffset = CGSize(width: 0, height: style.liftY)
                }
            case .dim:
                let slab = UIView(frame: bounds)
                slab.backgroundColor = style.slab
                slab.layer.cornerRadius = radius
                slab.layer.cornerCurve = .continuous
                plate.addSubview(slab)
                plate.layer.shadowColor = style.lift.withAlphaComponent(style.lift.specAlpha * 0.6).cgColor
                plate.layer.shadowOpacity = 1
                plate.layer.shadowRadius = style.liftRadius * 0.7
                plate.layer.shadowOffset = CGSize(width: 0, height: 4)
            case .clear:
                break
            }
        }
        addSubview(plate)

        // เนื้อหา — วางในหน่วยผังที่ (inset, inset) แล้วคูณ s ทั้งก้อนจากมุมบนซ้าย
        let scaled = UIView(frame: CGRect(origin: .zero, size: layout))
        scaled.isUserInteractionEnabled = false
        content.frame.origin = CGPoint(x: inset, y: inset)
        scaled.addSubview(content)
        scaled.layer.anchorPoint = .zero
        scaled.layer.position = .zero
        scaled.transform = CGAffineTransform(scaleX: s, y: s)
        let clipper = UIView(frame: bounds)
        clipper.isUserInteractionEnabled = false
        clipper.addSubview(scaled)
        if !isText {
            if framed {
                clipper.layer.cornerRadius = radius
                clipper.layer.cornerCurve = .continuous
            }
            clipper.clipsToBounds = true
        }
        addSubview(clipper)

        if border && !traits.drawsOwnBorder {
            let b = CALayer()
            b.frame = bounds
            b.borderColor = style.line.cgColor
            b.borderWidth = 0.7
            b.cornerRadius = radius
            b.cornerCurve = .continuous
            layer.addSublayer(b)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}
