import UIKit
import CoreImage

// MARK: - ตัววาดผัง (UIKit · iOS 16) — คู่ของ `SpecPainter` (SwiftUI) ที่วาดจากกล่องชุดเดียวกัน
//
// รู้จักของไม่กี่อย่าง — กล่องมุมมน · เส้น · ไล่สี · ลาย · ข้อความ · รูป · ไอคอน — และ **ไม่ตัดสินใจอะไร**
// ตำแหน่ง/ขนาด/ขนาดตัวอักษร/จำนวนบรรทัด มาจาก `SpecSolver` ทั้งหมด (WIDGET-SPEC.md §5–6)
// ทุกอย่างที่ขึ้นกับแอป (สี · ฟอนต์ · รูป · ไอคอน) ถามผ่าน `SpecRenderContext`
//
// ลำดับชั้นต่อโหนด = ของ SwiftUI ทีละบรรทัด: พื้น (ลายแผ่น → fill/ไล่สี → ลาย → เส้นขอบ · เงาของทั้งกลุ่ม) → ลูก →
// clip ของแม่พาลูกไปด้วย → opacity → หมุน (รอบกลางกล่อง)
//
// ไฟล์นี้ใช้เฉพาะ UIKit · CoreAnimation · CoreImage — คอมไพล์ที่ iOS 16.0 ได้ (ดู Packages/StarCardRender)

/// ต้นไม้จากรายการกล่องแบน — ลูกของ `r/0` คือ `r/0/<n>` และ `r/0/c<n>` (= `SpecTree` ของ SwiftUI)
struct SpecRenderTree {
    let root: SpecBox?
    let children: [String: [SpecBox]]
    init(_ boxes: [SpecBox]) {
        root = boxes.first { $0.id == "r" }
        var map: [String: [SpecBox]] = [:]
        for b in boxes where b.id != "r" {
            guard let cut = b.id.lastIndex(of: "/") else { continue }
            map[String(b.id[..<cut]), default: []].append(b)
        }
        children = map
    }
}

/// ใบหนึ่งใบ — ผังวางใน `box / k` แล้วย่อทั้งก้อนด้วย `k` (= `.frame(box / k).scaleEffect(k, anchor: .topLeading)`)
final class SpecWidgetView: UIView {
    /// - Parameters:
    ///   - boxes: ผลของ `SpecSolver.solve()`
    ///   - box: กล่องรากในหน่วยออกแบบ (ที่ chrome หักระยะขอบในแล้ว)
    ///   - fitScale: `solver.scale` (ขั้นย่อของ `fitScale` · 1 = ไม่ย่อ)
    ///   - pixelScale: พิกเซลต่อหน่วยออกแบบที่ใบนี้จะปรากฏจริง (สเกลจอ × สเกล chrome) — ความละเอียดของลาย/ไอคอนที่ rasterize
    init(boxes: [SpecBox], box: CGSize, fitScale k: CGFloat, context: SpecRenderContext, pixelScale: CGFloat = UIScreen.main.scale) {
        super.init(frame: CGRect(origin: .zero, size: box))
        isUserInteractionEnabled = false
        backgroundColor = .clear
        let tree = SpecRenderTree(boxes)
        guard let root = tree.root else { return }
        let painter = SpecLayerPainter(ctx: context, pixelScale: pixelScale * max(k, 0.01))
        let rv = painter.node(root, tree, origin: .zero)
        // ชั้นย่อแยกจากโหนดราก — รากอาจมี `rotate` ของตัวเอง (หมุนรอบกลาง) ซึ่งต้องไม่ปนกับการย่อจากมุมบนซ้าย
        let scaler = UIView(frame: CGRect(origin: .zero, size: root.frame.size))
        scaler.isUserInteractionEnabled = false
        scaler.addSubview(rv)
        scaler.layer.anchorPoint = .zero
        scaler.layer.position = .zero
        scaler.transform = CGAffineTransform(scaleX: k, y: k)
        addSubview(scaler)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

struct SpecLayerPainter {
    let ctx: SpecRenderContext
    /// พิกเซลต่อหน่วยผัง (รวมขั้นย่อ `k` แล้ว)
    let pixelScale: CGFloat

    // MARK: ต้นไม้

    /// กล่องของโหนดหนึ่ง + ลูกทั้งหมดซ้อนข้างใน (พิกัดลูกสัมพัทธ์กับแม่) — `clip`/`opacity`/`rotate` ของแม่พาลูกไปด้วย
    func node(_ b: SpecBox, _ t: SpecRenderTree, origin: CGPoint) -> UIView {
        let n = b.node
        let v = UIView(frame: CGRect(origin: origin, size: b.frame.size))
        v.isUserInteractionEnabled = false
        v.backgroundColor = .clear
        paint(b, into: v)
        for c in t.children[b.id] ?? [] {
            let o = CGPoint(x: c.frame.minX - b.frame.minX, y: c.frame.minY - b.frame.minY)
            v.addSubview(node(c, t, origin: o))
        }
        if n.clip == true { shape(n, b.frame.size).clip(v.layer) }
        if let o = n.opacity { v.alpha = CGFloat(o) }
        let rot = rotation(n, b.item)
        if rot != 0 { v.transform = CGAffineTransform(rotationAngle: CGFloat(rot * .pi / 180)) }
        return v
    }

    /// มุมของกล่อง ณ ขนาดจริง — `circle` = ครึ่งด้านสั้น (วงกลม/แคปซูล)
    private func corner(_ n: SpecNode, _ size: CGSize) -> CGFloat {
        n.circle == true ? min(size.width, size.height) / 2 : CGFloat(n.radius ?? 0)
    }
    private func shape(_ n: SpecNode, _ size: CGSize) -> SpecRenderShape {
        SpecRenderShape.make(n.shape, corner: corner(n, size))
    }
    private func rotation(_ n: SpecNode, _ item: SpecItem?) -> Double {
        if let c = n.rotateCycle, !c.isEmpty, let item { return c[item.i % c.count] }
        return n.rotate ?? 0
    }

    // MARK: primitive

    private func paint(_ b: SpecBox, into v: UIView) {
        let n = b.node
        switch n.type {
        case .col, .row, .stack, .chips, .spacer:
            background(n, item: b.item, into: v, defaultFill: nil)
        case .rect, .line:
            background(n, item: b.item, into: v, defaultFill: n.type == .line ? "ink@0.12" : nil)
        case .text:
            text(b, into: v)
        case .image:
            image(b, into: v)
        case .icon:
            icon(b, into: v)
        }
    }

    /// พื้น · ไล่สี · ลาย · เส้นขอบ · เงา ของกล่องหนึ่งใบ — ไม่มีค่าไหนตั้ง = ไม่วาดอะไร
    private func background(_ n: SpecNode, item: SpecItem?, into v: UIView, defaultFill: String?) {
        let size = v.bounds.size
        let bounds = v.bounds
        let sh = shape(n, size)
        if let pp = n.platePattern {
            // ลายแผ่นของถาด (ลายทาง · ข้าวหลามตัด) ตัดตามรูปร่าง — ไม่เลือก = `.plain` ไม่วาดอะไร
            if let img = SpecRenderPatterns.plateImage(ctx.platePattern, sheet: ctx.color(pp, item: item), size: size, scale: pixelScale) {
                let l = CALayer()
                l.frame = bounds
                l.contents = img.cgImage
                l.contentsScale = img.scale
                sh.clip(l)
                v.layer.addSublayer(l)
            }
        }
        let fill = (n.fillCycle.flatMap { c in item.map { c.isEmpty ? nil : c[$0.i % c.count] } ?? nil }) ?? n.fill ?? defaultFill
        guard fill != nil || n.gradient != nil || n.stroke != nil || n.pattern != nil else { return }

        // กลุ่มของพื้นทั้งก้อน — เงาคิดจากเนื้อที่วาดจริงของกลุ่ม (= `.compositingGroup().shadow`)
        let group = UIView(frame: bounds)
        group.isUserInteractionEnabled = false
        group.backgroundColor = .clear
        if let g = n.gradient {
            let gl = CAGradientLayer()
            gl.frame = bounds
            gl.colors = [ctx.color(g.from, item: item).cgColor, ctx.color(g.to, item: item).cgColor]
            let a = CGFloat(g.angle * .pi / 180)
            let dx = cos(a), dy = sin(a)
            gl.startPoint = CGPoint(x: 0.5 - dx / 2, y: 0.5 - dy / 2)
            gl.endPoint = CGPoint(x: 0.5 + dx / 2, y: 0.5 + dy / 2)
            sh.clip(gl)
            group.layer.addSublayer(gl)
        } else if let fill {
            group.layer.addSublayer(fillLayer(sh, bounds: bounds, color: ctx.color(fill, item: item)))
        }
        if let pat = n.pattern {
            if let img = SpecRenderPatterns.image(pat, color: ctx.color(pat.color, item: item), color2: ctx.color(pat.color2 ?? pat.color, item: item),
                                                  size: size, scale: pixelScale) {
                let l = CALayer()
                l.frame = bounds
                l.contents = img.cgImage
                l.contentsScale = img.scale
                l.opacity = Float(pat.opacity ?? 1)
                sh.clip(l)
                group.layer.addSublayer(l)
            }
        }
        if let s = n.stroke {
            group.layer.addSublayer(strokeLayer(sh, bounds: bounds, color: ctx.color(s.color, item: item), width: CGFloat(s.width), dash: s.dash))
        }
        if let s = n.shadow { apply(shadow: s, to: group.layer, item: item) }
        v.addSubview(group)
    }

    /// พื้นสีเดียวตามรูปร่าง — มุมมนใช้ `cornerRadius` + `.continuous` (squircle เท่า SwiftUI) · รูปอื่นเป็น path
    private func fillLayer(_ sh: SpecRenderShape, bounds: CGRect, color: UIColor) -> CALayer {
        switch sh {
        case .rounded(let r):
            let l = CALayer()
            l.frame = bounds
            l.backgroundColor = color.cgColor
            l.cornerRadius = max(0, min(r, bounds.width / 2, bounds.height / 2))
            l.cornerCurve = .continuous
            return l
        case .path:
            let l = CAShapeLayer()
            l.frame = bounds
            l.path = sh.path(in: bounds)
            l.fillColor = color.cgColor
            return l
        }
    }

    /// เส้นขอบด้านใน — ไม่มี dash: หนา 2× แล้ว clip (= iOS) ซึ่งมุมมนคือ `borderWidth` ของ layer พอดี · มี dash: หนาตามจริงแล้ว clip
    private func strokeLayer(_ sh: SpecRenderShape, bounds: CGRect, color: UIColor, width: CGFloat, dash: [Double]?) -> CALayer {
        if dash == nil, case .rounded(let r) = sh {
            let l = CALayer()
            l.frame = bounds
            l.borderColor = color.cgColor
            l.borderWidth = width
            l.cornerRadius = max(0, min(r, bounds.width / 2, bounds.height / 2))
            l.cornerCurve = .continuous
            return l
        }
        let l = CAShapeLayer()
        l.frame = bounds
        l.path = sh.path(in: bounds)
        l.fillColor = nil
        l.strokeColor = color.cgColor
        if let dash {
            l.lineWidth = width
            l.lineDashPattern = dash.map { NSNumber(value: $0) }
        } else {
            l.lineWidth = width * 2
        }
        let m = CAShapeLayer()
        m.frame = bounds
        m.path = sh.path(in: bounds)
        l.mask = m
        return l
    }

    /// เงา — sigma ของผัง → radius ของ SwiftUI (blur radius ≈ 2σ) · ให้ CoreAnimation เบลอจากเนื้อที่วาดจริง
    private func apply(shadow s: SpecShadow, to layer: CALayer, item: SpecItem?) {
        layer.shadowColor = ctx.color(s.color, item: item).cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: s.x, height: s.y)
        layer.shadowRadius = CGFloat(s.sigma) * 2
        layer.masksToBounds = false
    }

    // MARK: ข้อความ

    private func text(_ b: SpecBox, into v: UIView) {
        let n = b.node
        guard let r = b.text else { return }
        let weight = n.weight ?? 400
        let base = SpecFont(face: n.face ?? "noto", size: r.size, weight: weight,
                            tracking: CGFloat(n.tracking ?? 0), kerning: CGFloat(n.kerning ?? 0),
                            italic: n.italic ?? false, lineHeight: CGFloat(n.lineHeight ?? 1))
        let color = ctx.color(n.color ?? "ink", item: b.item)
        let align: NSTextAlignment = n.textAlign == "center" ? .center : n.textAlign == "right" ? .right : .left
        let lines = max(1, r.lines)
        // ระยะบรรทัดเพิ่ม = ความสูงบรรทัดของฟอนต์ × (lineHeight − 1) (= `lineSpacing` ของ SwiftUI)
        let spacing: CGFloat = {
            guard let lh = n.lineHeight, lh != 1 else { return 0 }
            return ctx.font(SpecFont(face: n.face ?? "body", size: r.size, weight: weight)).lineHeight * CGFloat(lh - 1)
        }()

        let label = SpecTextView(frame: v.bounds)
        label.lines = lines
        label.contentScale = pixelScale

        // พาดหัวสองเสียงของสำรับโปสเตอร์ (`mixHead`): คำแรกตามฟอนต์ของโหนด · ที่เหลือ noto บางเอียง ×1.04 · ย่อทั้งก้อนได้ถึงครึ่ง
        let parts = n.mixHead == true ? r.string.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true) : []
        if parts.count > 1 {
            let head = String(parts[0]), tail = " " + String(parts[1])
            var chosen: NSAttributedString? = nil
            var scale: CGFloat = 1
            while scale >= 0.5 {
                let a = NSMutableAttributedString()
                let hf = ctx.font(SpecFont(face: base.face, size: r.size * scale, weight: weight))
                a.append(NSAttributedString(string: head, attributes: attrs(font: hf, color: color, kern: base.kerning, tracking: 0, align: align, spacing: spacing)))
                let tf = ctx.font(SpecFont(face: "noto", size: r.size * 1.04 * scale, weight: 300, italic: true))
                a.append(NSAttributedString(string: tail, attributes: attrs(font: tf, color: color, kern: 0, tracking: 0, align: align, spacing: spacing)))
                chosen = a
                label.lineAdvance = hf.lineHeight + max(0, spacing)
                if fits(a, width: v.bounds.width, lines: lines, lineHeight: hf.lineHeight + max(0, spacing)) { break }
                scale -= 0.02
            }
            label.text = chosen
        } else {
            let f = ctx.font(base)
            label.lineAdvance = f.lineHeight + max(0, spacing)
            label.text = NSAttributedString(string: r.string, attributes: attrs(font: f, color: color, kern: base.kerning, tracking: base.tracking, align: align, spacing: spacing))
        }
        // เงา/เรืองแสงของตัวอักษร (ป้ายไฟ)
        if let s = n.shadow { apply(shadow: s, to: label.layer, item: b.item) }
        v.addSubview(label)
    }

    private func attrs(font: UIFont, color: UIColor, kern: CGFloat, tracking: CGFloat, align: NSTextAlignment, spacing: CGFloat) -> [NSAttributedString.Key: Any] {
        let para = NSMutableParagraphStyle()
        para.alignment = align
        para.lineSpacing = max(0, spacing)
        para.lineBreakMode = .byWordWrapping
        var a: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: para]
        if kern != 0 { a[.kern] = kern }
        if tracking != 0 { a[.tracking] = tracking }
        return a
    }

    /// ข้อความลง `lines` บรรทัดในความกว้างนี้ไหม (= เกณฑ์ที่ `minimumScaleFactor` ของ SwiftUI ใช้ย่อ)
    private func fits(_ a: NSAttributedString, width: CGFloat, lines: Int, lineHeight: CGFloat) -> Bool {
        let r = a.boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
                               options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        if lines == 1 {
            let one = a.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            return one.width <= width + 0.01
        }
        return r.height <= CGFloat(lines) * lineHeight + 0.5
    }

    // MARK: รูป

    private func image(_ b: SpecBox, into v: UIView) {
        let n = b.node
        let f = v.bounds
        let sh = shape(n, f.size)
        let slot = n.photoRef.flatMap { r in r.hasPrefix("$") ? Int(b.item?.value(String(r.dropFirst())) ?? "") : Int(r) }
            ?? n.photo ?? Int(b.item?.value("photo") ?? "") ?? 0
        // `src`: รูปจาก asset ของแอป (`"$cover"` = ปกผลงาน) — ว่าง = ช่องรูปของชิ้นตามเดิม
        let src = n.src.map { $0.hasPrefix("$") ? (b.item?.value(String($0.dropFirst())) ?? "") : $0 } ?? ""
        let contain = n.fit == "contain"

        let container = UIView(frame: f)
        container.isUserInteractionEnabled = false
        let clipView = UIView(frame: f)
        clipView.isUserInteractionEnabled = false
        sh.clip(clipView.layer)

        var photo: SpecRenderPhoto? = nil
        var fitContain = contain
        if !src.isEmpty, let ui = ctx.asset(src) {
            photo = SpecRenderPhoto(image: ui)
        } else if src.hasPrefix("http") {
            // โลโก้จากเน็ต — `scaledToFit` เสมอ
            if let ui = ctx.remote(src) { photo = SpecRenderPhoto(image: ui); fitContain = true }
        } else {
            photo = ctx.photo(slot: slot)
        }
        if let p = photo {
            let rect = Self.imageRect(image: p.image.size, in: f.size, contain: fitContain, dx: p.dx, dy: p.dy, zoom: p.zoom)
            // ย่อรูปใหญ่ลงเท่าพิกเซลที่จะวาดจริงก่อน (เฉลี่ยพื้นที่แบบ mipmap) — ตัวย่อของ CoreAnimation/CoreGraphics ตอนวาดตรง ๆ
            // ไม่มี mipmap รูปที่ย่อหลายเท่าจึงเป็นเม็ดหยาบ ต่างจาก SwiftUI · ขาวดำทำหลังย่อ (รูปเล็กกว่า)
            var img = Self.downsampled(p.image, toFit: CGSize(width: rect.width * pixelScale, height: rect.height * pixelScale))
            if n.mono == true { img = Self.grayscale(img) }
            let iv = UIImageView(image: img)
            iv.contentMode = .scaleToFill
            iv.layer.minificationFilter = .trilinear
            iv.layer.magnificationFilter = .linear
            iv.frame = rect
            clipView.addSubview(iv)
        }
        container.addSubview(clipView)
        if let s = n.stroke {
            container.layer.addSublayer(strokeLayer(sh, bounds: f, color: ctx.color(s.color, item: nil), width: CGFloat(s.width), dash: nil))
        }
        if let s = n.shadow { apply(shadow: s, to: container.layer, item: nil) }
        v.addSubview(container)
    }

    /// กรอบของรูปในช่อง — cover/contain รอบกลาง แล้ว `zoom` รอบกลาง + เลื่อน `dx/dy` × ขนาดที่วาด (= `WidgetPhoto.visualEffect`)
    static func imageRect(image: CGSize, in box: CGSize, contain: Bool, dx: CGFloat, dy: CGFloat, zoom: CGFloat) -> CGRect {
        guard image.width > 0, image.height > 0 else { return .zero }
        let k = contain ? min(box.width / image.width, box.height / image.height)
                        : max(box.width / image.width, box.height / image.height)
        let drawn = CGSize(width: image.width * k, height: image.height * k)
        let z = max(zoom, 0.01)
        let size = CGSize(width: drawn.width * z, height: drawn.height * z)
        return CGRect(x: box.width / 2 - size.width / 2 + dx * drawn.width,
                      y: box.height / 2 - size.height / 2 + dy * drawn.height,
                      width: size.width, height: size.height)
    }

    /// ย่อรูปให้ไม่เกิน `px` พิกเซล (คงสัดส่วน · คุณภาพสูง) — ไม่ขยาย
    static func downsampled(_ img: UIImage, toFit px: CGSize) -> UIImage {
        let w = img.size.width * img.scale, h = img.size.height * img.scale
        guard px.width >= 1, px.height >= 1, w > px.width * 1.05 || h > px.height * 1.05 else { return img }
        let k = min(px.width / w, px.height / h)
        let target = CGSize(width: max(1, (w * k).rounded()), height: max(1, (h * k).rounded()))
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1; fmt.opaque = false
        return UIGraphicsImageRenderer(size: target, format: fmt).image { rc in
            rc.cgContext.interpolationQuality = .high
            img.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    /// ทำงานในปริภูมิ sRGB ที่เข้ารหัสแล้ว (ไม่ใช่ linear ที่ CoreImage ใช้ตั้งต้น) — `.grayscale(1)` ของ SwiftUI คูณเมทริกซ์บนค่าพิกเซลตรง ๆ
    private static let ciContext = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any])
    /// ขาวดำ (= `.grayscale(1)` ของ SwiftUI) — ความสว่าง Rec.709 (0.2126 · 0.7152 · 0.0722) บนค่า sRGB ที่เข้ารหัสแล้ว ทุกช่องสีเท่ากัน
    static func grayscale(_ img: UIImage) -> UIImage {
        guard let ci = CIImage(image: img), let f = CIFilter(name: "CIColorMatrix") else { return img }
        f.setValue(ci, forKey: kCIInputImageKey)
        let luma = CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0)
        f.setValue(luma, forKey: "inputRVector")
        f.setValue(luma, forKey: "inputGVector")
        f.setValue(luma, forKey: "inputBVector")
        guard let out = f.outputImage, let cg = ciContext.createCGImage(out, from: out.extent) else { return img }
        return UIImage(cgImage: cg, scale: img.scale, orientation: img.imageOrientation)
    }

    // MARK: ไอคอน

    private func icon(_ b: SpecBox, into v: UIView) {
        let n = b.node
        let name = n.icon.map { $0.hasPrefix("$") ? (b.item?.value(String($0.dropFirst())) ?? "") : $0 } ?? ""
        let tint = n.tint.map { ctx.color($0, item: b.item) }
        let f = v.bounds
        let req = SpecIconRequest(name: name, size: f.size, tint: tint, text: n.text, pointSize: n.size.map { CGFloat($0) }, pixelScale: pixelScale)
        guard let iv = ctx.icon(req) else { return }
        iv.frame = f
        iv.isUserInteractionEnabled = false
        let holder = UIView(frame: f)
        holder.isUserInteractionEnabled = false
        SpecRenderShape.rounded(corner(n, f.size)).clip(holder.layer)
        holder.addSubview(iv)
        v.addSubview(holder)
    }
}

/// กล่องข้อความที่วาดเองจากขอบบน (= `Text` ใน `.frame(alignment: .top*)` + `.fixedSize(vertical: true)`):
/// `UILabel` จัดกลางแนวตั้งเสมอและขยับบรรทัดแรกเมื่อมี `lineSpacing`/ข้อความล้นกล่อง — วาดด้วย `NSStringDrawing` ตรง ๆ
/// บรรทัดแรกจึงอยู่ที่ขอบบนของกล่องเหมือน SwiftUI · ตัดท้ายด้วย … ที่บรรทัดที่ `lines` (`truncatesLastVisibleLine`)
final class SpecTextView: UIView {
    var text: NSAttributedString? { didSet { setNeedsDisplay() } }
    var lines = 1
    /// ความสูงหนึ่งบรรทัดรวมระยะเพิ่ม — เพดานของพื้นที่วาด = `lines × lineAdvance`
    var lineAdvance: CGFloat = 0
    var contentScale: CGFloat = UIScreen.main.scale { didSet { layer.contentsScale = max(1, contentScale) } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func draw(_ rect: CGRect) {
        guard let text else { return }
        let cap = lineAdvance > 0 ? CGFloat(lines) * lineAdvance + 0.5 : CGFloat.greatestFiniteMagnitude
        text.draw(with: CGRect(x: 0, y: 0, width: bounds.width, height: cap),
                  options: [.usesLineFragmentOrigin, .usesFontLeading, .truncatesLastVisibleLine], context: nil)
    }
}
