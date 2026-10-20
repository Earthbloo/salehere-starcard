import SwiftUI
import UIKit
import PhosphorSwift

#if DEBUG
// MARK: - A/B ตัววาด SwiftUI (ต้นแบบ) กับ UIKit (`Render/` · iOS 16) จากกล่องชุดเดียวกัน
//
// เปิดแอปด้วย `-exportRenderAB -exportPerson` → `Documents/RenderAB/{swiftui,uikit}/`:
//   cell-<kind>-<probe>.png  — ใบเดียวกัน กรอบเดียวกัน กล่องเดียวกัน (จดจากรอบวาดของ SwiftUI ด้วย `SpecExport.capture`)
//                              วาดด้วยตัววาดคนละตัว · พื้นโปร่ง · ไม่มีแผ่น chrome (พื้นผิว `.clear` ไม่มีขอบ) จึงเทียบ *painter* ล้วน ๆ
//   fixtures/<kind>.json     — กล่องที่ใช้ (เท่ากันทั้งสองฝั่งโดยนิยาม) ให้ `present/spec-parity/compare.py` อ่านได้
// แล้ว `present/render-ab/run.sh <udid>` ดึงออกมาเทียบพิกเซลทีละใบ → report.html
@MainActor
enum RenderABExport {
    static let folder = "RenderAB"

    static func run(photos: PhotoStore) async {
        let fm = FileManager.default
        let root = URL.documentsDirectory.appending(path: folder)
        try? fm.removeItem(at: root)
        let dirA = root.appending(path: "swiftui"), dirB = root.appending(path: "uikit")
        for d in [dirA, dirB] { try? fm.createDirectory(at: d.appending(path: "fixtures"), withIntermediateDirectories: true) }
        // รูปจากเน็ตต้องอยู่ในแคชก่อน — ทั้งสองฝั่งอ่านแคชเดียวกัน
        var urls = Set((0..<PhotoLib.count).map { PhotoLib.url($0) })
        for brand in Profile.me.shownTrack(.brand).brands { if let raw = brand.logo, let u = URL(string: raw) { urls.insert(u) } }
        await withTaskGroup(of: Void.self) { group in for u in urls { group.addTask { _ = await ImageCache.shared.load(u) } } }

        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        var kinds = 0, cells = 0
        for spec in SpecCatalog.all {
            guard let kind = WidgetKind(rawValue: spec.kind), !kind.isTextLayer else { continue }
            var cases: [SpecExport.FixtureCase] = []
            for p in SpecExport.probes(for: spec) {
                // ชิ้นที่ไม่มีแผ่นและไม่มีขอบ — chrome ไม่วาดอะไร เหลือแต่ painter
                var w = WidgetMatrixExport.baseInstance(kind)
                w.x = 0; w.y = 0
                w.rect.size = p.size
                w.surface = .clear
                w.border = false
                let snap = CardSnapshot(pages: [.init(items: [WidgetMatrixExport.itemSnapshot(w)])], theme: WidgetMatrixExport.baseTheme, index: 0)
                guard let (pages, theme, _) = CardStore.restore(snap), let item = pages.first?.items.first else { continue }
                let frame = CGRect(origin: .zero, size: p.size)

                // A — SwiftUI ผ่าน chrome จริง · จดกล่องที่ solver ให้ในรอบนี้
                let cap = SpecExport.Capture(); SpecExport.capture = cap
                let a = renderSwiftUI(item: item, theme: theme, frame: frame, photos: photos)
                SpecExport.capture = nil
                guard cap.hits > 0, let a else { continue }

                // B — UIKit จากกล่องชุดเดียวกัน
                let s = min(p.size.width / spec.design.w, p.size.height / spec.design.h)
                let inset = WidgetChrome.contentInset(kind: kind, surface: item.surface, border: item.border)
                let ctx = AppRenderContext(kind: kind, item: item, theme: theme, photos: photos, sample: true)
                let widget = SpecWidgetView(boxes: cap.boxes, box: cap.box, fitScale: cap.scale, context: ctx, pixelScale: 2 * s)
                let b = renderUIKit(widget: widget, frame: frame, layout: CGSize(width: p.size.width / s, height: p.size.height / s), inset: inset, scale: s,
                                    overlay: ctx.stampOverlay())

                try? a.pngData()?.write(to: dirA.appending(path: "cell-\(kind.rawValue)-\(p.name).png"))
                try? b.pngData()?.write(to: dirB.appending(path: "cell-\(kind.rawValue)-\(p.name).png"))
                cases.append(cap.fixtureCase(p.name))
                cells += 1
                await Task.yield()
            }
            let fx = SpecExport.Fixture(kind: spec.kind, design: [spec.design.w, spec.design.h], inset: 0, cases: cases)
            if let d = try? enc.encode(fx) {
                try? d.write(to: dirA.appending(path: "fixtures/\(spec.kind).json"))
                try? d.write(to: dirB.appending(path: "fixtures/\(spec.kind).json"))
            }
            kinds += 1
        }
        try? "done \(kinds) kinds \(cells) cells\n".write(to: root.appending(path: "DONE.txt"), atomically: true, encoding: .utf8)
        print("[render-ab] wrote \(kinds) kinds · \(cells) cells → \(root.path)")
    }

    /// ฝั่ง SwiftUI — `WidgetChrome` ตัวจริงกับ environment เดียวกับหน้าส่งออก (`MatrixWidgetPage`) · พื้นโปร่ง
    private static func renderSwiftUI(item: WidgetInstance, theme: CardTheme, frame: CGRect, photos: PhotoStore) -> UIImage? {
        let placed = Placed(item: item, frame: frame)
        let view = WidgetChrome(placed: placed, theme: theme, forceSample: true)
            .frame(width: frame.width, height: frame.height)
            .environment(\.cardInk, theme.inkStyle)
            .environment(\.colorScheme, theme.activeInk.isLight ? .light : .dark)
            .environment(\.previewStatic, true)
            .environment(photos)
            .transaction { $0.animation = nil }
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        renderer.isOpaque = false
        return renderer.uiImage
    }

    /// ฝั่ง UIKit — ท่าเดียวกับ chrome ที่พื้นผิว `.clear`: เนื้อหาที่ (inset, inset) ในกล่อง layout แล้วคูณ s ทั้งก้อน · ตัดที่กรอบ
    private static func renderUIKit(widget: UIView, frame: CGRect, layout: CGSize, inset: CGFloat, scale s: CGFloat,
                                    overlay: (image: UIImage, top: CGFloat, trailing: CGFloat)?) -> UIImage {
        let outer = UIView(frame: frame)
        outer.backgroundColor = .clear
        outer.clipsToBounds = true
        let scaled = UIView(frame: CGRect(origin: .zero, size: layout))
        widget.frame.origin = CGPoint(x: inset, y: inset)
        scaled.addSubview(widget)
        scaled.layer.anchorPoint = .zero
        scaled.layer.position = .zero
        scaled.transform = CGAffineTransform(scaleX: s, y: s)
        outer.addSubview(scaled)
        // ป้าย Verified by Sale Here มุมขวาบน (= `.overlay(alignment: .topTrailing)` ของ chrome — พิกัดกรอบ ไม่สเกล)
        if let o = overlay {
            let iv = UIImageView(image: o.image)
            let size = CGSize(width: o.image.size.width, height: o.image.size.height)
            iv.frame = CGRect(x: frame.width - o.trailing - size.width, y: o.top, width: size.width, height: size.height)
            outer.addSubview(iv)
        }
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2; fmt.opaque = false
        return UIGraphicsImageRenderer(size: frame.size, format: fmt).image { rc in
            outer.layer.render(in: rc.cgContext)
        }
    }
}

// MARK: - adapter ของต้นแบบ: ธีม SwiftUI → สิ่งที่ตัววาด UIKit ขอ
//
// = ค่าชุดเดียวกับที่ `SpecPainter` (SwiftUI) ใช้: token สีจาก `SpecColor.resolve` + `extraTokens` · ฟอนต์จาก `IOSSpecMeasurer` ·
// รูปจาก `PhotoStore` · ไอคอนที่วาดด้วยโค้ด rasterize จาก view เดิม (salehere-ios จะวาดของตัวเองด้วย UIKit/asset)
@MainActor
final class AppRenderContext: SpecRenderContext {
    let kind: WidgetKind
    let theme: CardTheme
    let ink: InkStyle
    let accent: Color
    let kit: KitConfig
    let border: Bool
    let surface: WidgetSurface
    let stamped: Bool
    let sample: Bool
    let wid: UUID
    let pattern: PlatePattern
    let photos: PhotoStore

    init(kind: WidgetKind, item: WidgetInstance, theme: CardTheme, photos: PhotoStore, sample: Bool) {
        self.kind = kind; self.theme = theme; self.photos = photos; self.sample = sample
        // พื้นผิว `.clear` = ไม่มีแผ่น → หมึกของการ์ดตรง ๆ (ตรงกับ `framed == false` ใน WidgetChrome)
        ink = theme.inkStyle
        accent = theme.accent
        kit = item.kit.looking(kind)
        border = item.border
        surface = item.surface
        wid = item.id
        pattern = item.pattern
        let missing = kind.family.missing
        stamped = !missing && (kind.stampFacts?.verified ?? false)
    }

    /// = `SpecPainter.extraTokens`
    private lazy var extra: [String: Color] = {
        let look = KitLook(kit.resolved(theme), border: border, cardDark: !ink.isLight)
        let t = ScrapTone(theme)
        let ed = Ed.skin(surface, paper: Ed.paper, ink: ink, theme: theme)
        return [
            "kit.fill": Color(kitHex: look.fillHex), "kit.border": look.borderColor, "kit.ink": look.ink, "kit.mut": look.mut,
            "kit.accent": look.accent, "kit.title": look.title, "kit.block": look.blockFill,
            "scrap.paper": t.paper, "scrap.ink": t.ink, "scrap.soft": t.soft, "scrap.accent": t.accent, "scrap.strong": t.strong,
            "scrap.paperAccent": t.paperAccent, "scrap.paperStrong": t.paperStrong, "scrap.band": t.band, "scrap.mid": t.mid,
            "scrap.blush": t.blush, "scrap.shade": t.shade, "scrap.speck": t.speck,
            "rawAccent": theme.rawAccent, "rawAccentSoft": theme.rawAccentSoft,
            "plate": PosterPlate.plate(theme), "plateInk": PosterPlate.cream(theme),
            "accentPaper": theme.rawAccent.onLightSurface(),
            "ed.sheet": ed.sheet, "ed.ink": ed.ink, "ed.inkSoft": ed.inkSoft, "ed.ghost": ed.ghost, "ed.marker": ed.marker, "ed.red": ed.red,
            "pop.ink": Pop.ink, "pop.inkSoft": Pop.inkSoft, "pop.rule": Pop.rule, "pop.paper": Pop.paper,
            "pop.sheet": Pop.sheetFill(surface, skin: kind.popSkin ?? .glass, theme: theme),
            "pop.shadow": Pop.sheetShadow(surface, skin: kind.popSkin ?? .glass, theme: theme),
        ]
    }()

    private func swiftColor(_ token: String) -> Color {
        SpecColor.resolve(token, ink: ink, accent: accent, theme: theme, extra: extra)
    }
    private func swiftColor(_ token: String, item: SpecItem?) -> Color {
        guard token.hasPrefix("$"), let item else { return swiftColor(token) }
        var name = String(token.dropFirst()); var alpha = ""
        if let at = name.firstIndex(of: "@") { alpha = String(name[at...]); name = String(name[..<at]) }
        return swiftColor(item.value(name) + alpha)
    }

    func color(_ token: String, item: SpecItem?) -> UIColor { UIColor(swiftColor(token, item: item)) }
    func font(_ f: SpecFont) -> UIFont { IOSSpecMeasurer.shared.uiFont(f) }
    func lineHeight(_ f: SpecFont) -> CGFloat { IOSSpecMeasurer.shared.lineHeight(f) }

    /// ลำดับรูปเดียวกับ `PhotoStore.image(_:for:)`: รูปของชิ้น → คลังของการ์ด → รูปตั้งต้นของระบบ (จากแคช)
    func photo(slot: Int) -> SpecRenderPhoto? {
        let img = photos.uiImage(slot: slot, for: wid) ?? photos.library(slot) ?? ImageCache.shared.cached(PhotoLib.url(slot))
        guard let img else { return nil }
        let f = photos.fit(slot: slot, for: wid)
        return SpecRenderPhoto(image: img, dx: f.dx, dy: f.dy, zoom: f.zoom)
    }
    func asset(_ name: String) -> UIImage? { UIImage(named: name) }
    func remote(_ url: String) -> UIImage? { URL(string: url).flatMap { ImageCache.shared.cached($0) } }
    var platePattern: SpecPlatePattern { SpecPlatePattern(rawValue: pattern.rawValue) ?? .plain }

    /// ป้าย Verified by Sale Here ที่ chrome วางทับมุมขวาบนของใบที่ไม่มีช่องหัวข้อ (`WidgetKind.stampOverlay`) — ของ chrome ไม่ใช่ painter
    func stampOverlay() -> (image: UIImage, top: CGFloat, trailing: CGFloat)? {
        guard stamped, let o = kind.stampOverlay else { return nil }
        let v = SaleHereByline(tint: ink.text(0.85), tone: o.tone)
            .environment(\.cardInk, ink)
            .environment(\.colorScheme, theme.activeInk.isLight ? .light : .dark)
        let renderer = ImageRenderer(content: v)
        renderer.scale = 2
        renderer.isOpaque = false
        guard let img = renderer.uiImage else { return nil }
        return (img, o.top, o.trailing)
    }

    /// ไอคอนตามชื่อ (§6) — view ชุดเดียวกับ `SpecPainter.icon` rasterize ที่ความละเอียดที่จะปรากฏจริง
    func icon(_ r: SpecIconRequest) -> UIView? {
        guard let v = iconView(r) else { return nil }
        let host = v
            .frame(width: r.size.width, height: r.size.height)
            .environment(\.cardInk, ink)
            .environment(\.cardAccent, accent)
            .environment(\.saleHereStamped, stamped)
            .environment(\.kitConfig, kit)
            .environment(\.widgetSurface, surface)
            .environment(\.widgetBorder, border)
            .environment(\.sampleData, sample)
            .environment(\.widgetID, wid)
            .environment(\.colorScheme, theme.activeInk.isLight ? .light : .dark)
            .transaction { $0.animation = nil }
        let renderer = ImageRenderer(content: host)
        renderer.scale = max(1, r.pixelScale)
        renderer.isOpaque = false
        guard let img = renderer.uiImage else { return nil }
        let iv = UIImageView(image: img)
        iv.contentMode = .scaleToFill
        return iv
    }

    private func iconView(_ r: SpecIconRequest) -> AnyView? {
        let name = r.name
        let tint = r.tint.map { Color($0) }
        let f = r.size
        func c(_ t: String) -> Color { swiftColor(t) }
        switch name {
        case "qr":
            return AnyView(QRCode(text: "https://salehere.co.th/star/\(Profile.me.handle)", tint: tint ?? c("ink")).aspectRatio(1, contentMode: .fit))
        case "provenance", "provenance:profile":
            return AnyView(ProvenanceTag(kind: .profile).fixedSize())
        case "provenance:socials":
            return AnyView(ProvenanceTag(kind: Profile.me.shownSocials.provenance).fixedSize())
        case "provenance:photo":
            return AnyView(ProvenanceTag(kind: Profile.me.shownSocials.provenance, onPhoto: true).fixedSize())
        case "provenance:screenshot":
            return AnyView(ProvenanceTag(kind: .screenshot("12 ก.ย.")).fixedSize())
        case "byline", "byline:dark", "byline:light":
            return AnyView(SaleHereByline(tint: tint ?? c("ink@0.9"), size: max(6, f.height * 0.45),
                                          tone: name == "byline:dark" ? .dark : name == "byline:light" ? .light : .ink).fixedSize())
        case "verifiedBadge":
            return AnyView(VerifiedBadge().fixedSize())
        case "verifiedSeal":
            return AnyView(VerifiedSeal(radius: min(f.width, f.height) / 2, punch: ink.isLight ? .white : Color(white: 0.1), tint: tint ?? c("ink"), compact: false))
        case "guilloche":
            return AnyView(Guilloche(color: tint ?? c("ink@0.2")))
        case "ringText":
            let size = r.pointSize ?? 7
            return AnyView(RingText(text: r.text ?? "", radius: min(f.width, f.height) / 2 - size, size: size, color: tint ?? c("ink")))
        case "washi":
            return AnyView(WashiTape(width: f.width, height: f.height, tint: tint ?? .white))
        case "binderClip":
            return AnyView(BinderClip(width: f.width))
        case "paperClip":
            return AnyView(PaperClip().stroke(tint ?? c("ink@0.6"), lineWidth: 1.6))
        case "barcode":
            return AnyView(ScrapBarcode(color: tint ?? c("ink")))
        case "bow":
            return AnyView(ScrapBow(width: f.width))
        case "spark":
            return AnyView(ScrapSpark(size: min(f.width, f.height), color: tint ?? .white))
        case "windowDots":
            return AnyView(ScrapWindowDots())
        case "embossedLockup":
            return AnyView(EmbossedLockup(height: f.height, light: ink.isLight, foil: false, tint: tint ?? c("ink@0.8")))
        case "starLockup":
            return AnyView(StarLockup(height: f.height, tint: tint ?? c("accent")))
        case "starSeal":
            return AnyView(StarSeal(size: min(f.width, f.height), tint: tint ?? c("accent"), punch: ink.isLight ? .white : Color(white: 0.1)))
        case "saleHereStar":
            return AnyView(Image(SHIcon.star).renderingMode(.template).resizable().scaledToFit().foregroundStyle(tint ?? c("ink")))
        default:
            if name.hasPrefix("url:") || name.hasPrefix("http") {
                let u = name.hasPrefix("url:") ? String(name.dropFirst(4)) : name
                guard let ui = remote(u) else { return nil }
                return AnyView(Image(uiImage: ui).resizable().scaledToFit())
            }
            if name.hasPrefix("ph:") {
                let short = String(name.dropFirst(3))
                if UIImage(named: "ph-" + short) != nil {
                    return AnyView(Image("ph-" + short).renderingMode(.template).resizable().scaledToFit().foregroundStyle(tint ?? c("ink")))
                }
                if let ph = Ph(rawValue: short.replacingOccurrences(of: "-fill", with: "")) {
                    return AnyView(PIcon(ph, size: min(f.width, f.height), weight: short.hasSuffix("-fill") ? .fill : .bold).foregroundStyle(tint ?? c("ink")))
                }
                return nil
            }
            if name.hasPrefix("sh:") {
                let asset = SHIcon.named(String(name.dropFirst(3)))
                if let tint { return AnyView(Image(asset).renderingMode(.template).resizable().scaledToFit().foregroundStyle(tint)) }
                return AnyView(Image(asset).renderingMode(.original).resizable().scaledToFit())
            }
            if !name.isEmpty {
                if let tint { return AnyView(Image(name).renderingMode(.template).resizable().scaledToFit().foregroundStyle(tint)) }
                return AnyView(Image(name).renderingMode(.original).resizable().scaledToFit())
            }
            return nil
        }
    }
}
#endif
