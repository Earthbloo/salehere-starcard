#if DEBUG
import SwiftUI
import UIKit

// MARK: - เมทริกซ์ widget — วาดทุกชนิดในทุกตัวเลือกเป็น PNG (DEBUG เท่านั้น)
//
// เปิดแอปด้วย `-exportWidgetMatrix` → เขียน `Documents/WidgetMatrix/`:
//   matrix.json  — รายการ config ทั้งหมด (สัญญากับฝั่ง Android: item/theme คือ JSON ของ `CardSnapshot` ตรง ๆ)
//   <id>.png     — แต่ละ config ที่ @2x
//   log.txt      — ชนิดที่ข้าม · ช่องข้อความที่เจอต่อชนิด · ที่วาดไม่ออก · เวลา
//
// ใช้เทียบพิกเซล iOS ↔ Android: ฝั่ง Android อ่าน `matrix.json` ชุดเดียวกันแล้ววาดตาม
// **ไม่แตะวิธีวาดของ widget ตัวไหนเลย** — ใช้ `WidgetChrome` · `CardBackdrop` · `CardSheet` ตัวจริง
// ถ้าตั้ง env `MATRIX_COPY_TO` (ผ่าน `SIMCTL_CHILD_MATRIX_COPY_TO`) จะคัดลอก matrix.json ไปที่นั่นทันทีที่เขียนเสร็จ

@MainActor
enum WidgetMatrixExport {
    static let folder = "WidgetMatrix"
    /// id ตายตัวของชิ้นในทุก config — ไม่มีรูป/ข้อความเฉพาะชิ้นผูกอยู่ จึงได้ของตั้งต้นของแอป
    static let fixedID = UUID(uuidString: "0000000A-0000-4000-8000-000000000001")!
    static let margin: CGFloat = 12
    static let scale: CGFloat = 2
    /// `\.pageContentWidth` ของทุก config widget — ความกว้างเนื้อหาของหน้าสตอรี่ (540 − 18 × 2)
    ///
    /// ไม่ใช้ของหน้าเมทริกซ์เอง (`w + 24 − 36`) เพราะก้อนข้อความหดตัวอักษรตามค่านี้ —
    /// หน้าที่แคบเท่ากล่องจะบีบตัวอักษรที่วัดกล่องมาแล้วให้เล็กลงอีกรอบ
    static let contentWidth: CGFloat = PageLayout.content(CGSize(width: 540, height: 960)).width
    static let pageSeriesSize = CGSize(width: 240, height: 320)

    static let baseTheme = CardSnapshot.Theme(palette: "midnight", ink: "night", corner: "round",
                                              backdrop: "solid", brightness: 0.3, hueShift: 0,
                                              inkAuto: false, strip: "line")
    static let slotTints: [TextTint] = [.ink, .soft, .accent, .white, .rose, .gold]
    static let pageBackdrops: [BackdropStyle] = [.solid, .gradient, .grid, .stripe, .diamond, .glow, .marble]

    // MARK: รูปแบบไฟล์

    struct PageSpec: Encodable {
        var w: Double
        var h: Double
        var strip: Bool
    }

    struct Config: Encodable {
        var id: String
        var kind: String
        var group: String
        var label: String
        var page: PageSpec
        var theme: CardSnapshot.Theme
        var item: CardSnapshot.Item?

        enum CodingKeys: String, CodingKey { case id, kind, group, label, page, theme, item }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id)
            try c.encode(kind, forKey: .kind)
            try c.encode(group, forKey: .group)
            try c.encode(label, forKey: .label)
            try c.encode(page, forKey: .page)
            try c.encode(theme, forKey: .theme)
            if let item { try c.encode(item, forKey: .item) } else { try c.encodeNil(forKey: .item) }
        }
    }

    /// กติกาเรขาคณิตที่ทั้งสองฝั่งต้องทำเหมือนกัน — เขียนลงไฟล์ด้วย ฝั่ง Android ไม่ต้องเดา
    struct Rules: Encodable {
        var widgetPage = "page = (item.w + 2*margin) x (item.h + 2*margin) pt; the widget frame is exactly (item.x, item.y, item.w, item.h) = (margin, margin, w, h) — PageLayout.solve of a single in-bounds item returns its own rect (no clamp/push happens: every item is >= PageLayout.minSize)"
        var pixels = "png px = page pt * scale (2), sRGB 8-bit, opaque (no alpha)"
        var pageCornerRadius = 0
        var widgetStrip = "NOT drawn for widget configs: CardBackdrop(signed: false) (no SignatureCorner wordmark) and no SignatureEmboss overlay"
        var pageStrip = "page configs render CardSheet(format: .story, pageSize 240x320, pages: [empty]): CardBackdrop(signed: true) — strip line/ticket/ghost all draw the same SignatureCorner wordmark (side = min(w,h)*0.68, bottom-trailing, rotated -8deg about bottom-trailing, offset (side*0.12, side*0.06), opacity 0.17 on dark ink / 0.07 on light ink, tint = ink.base with gradient to 35% toward bottom-trailing); strip emboss/foil draw no wordmark and instead SignatureEmboss over the page (mark height h = max(20, minSide*(foil ? 0.070 : 0.058)), width h*34/24, centred at (w - minSide*0.042 - markW/2, h - minSide*0.034 - markH/2))"
        var backdrop = "CardBackdrop fills the whole page edge to edge (no inset), clipped to the page rect; widget configs use the config theme's backdrop (base: solid = theme.backdropColors.top)"
        var pageContentWidth = 504.0
        var pageContentWidthNote = "EnvironmentValues.pageContentWidth is fixed to 504 (story page 540 - 2*18) for every widget config; only TextBlock reads it (TextFit.capped maxWidth = 504 - 2*TextBlock.inset)"
        var environment = "cardInk = theme.inkStyle; colorScheme = theme.activeInk.isLight ? light : dark; previewStatic = true (time-driven motion frozen); textEditMode = false; sampleData = false (the widget may draw SystemPending when the device profile lacks that data — see log.txt); no animation transaction"
        var itemID = "0000000A-0000-4000-8000-000000000001 for every config — no per-widget photos or notes exist for it, so photo slots fall back to the device library / PhotoLib URLs and note slots to their preset (TextBlock: Profile.notePlaceholder)"
        var sizeWide = "w = round(defaultSize.w * 1.4), h unchanged"
        var sizeSmall = "target = max(PageLayout.minSize.width = 100, round(defaultSize.w * 0.7)); WidgetInstance.scale(toWidth: target) → h = max(1, round(target * h / w)); then h = max(h, PageLayout.minSize.height = 40)"
        var pattern = "pattern configs set surface = glass (the widget's own plate): the plate pattern (PlatePatternLayer) only draws on the own plate; on pane/clear the plate is transparent and the pattern is invisible (the app only offers the pattern row when surface == glass)"
        var textBlock = "TextBlock box is fitted like CardScreen.fitTextBlock with content width 504: size = TextFit.capped(points, text, face, .semibold, maxWidth: 504 - 8); m = TextFit.metrics(...); w = min(m.ink.width + 8, 504), h = m.ink.height + 8 (already baked into item.w/h). textBlock has no size group (canResize == false)"
        var glass = "SwiftUI .glassEffect is not captured by ImageRenderer — GlassPanel appears as its veil fill + shadow only"
        var renderer = "SwiftUI ImageRenderer, scale 2, isOpaque true; remote PhotoLib/brand-logo images preloaded into ImageCache before rendering; each kind gets one warm-up render before its configs"
    }

    struct Matrix: Encodable {
        var scale: Int
        var margin: Int
        var baseTheme: CardSnapshot.Theme
        var rules: Rules
        var configs: [Config]
    }

    // MARK: ตัวจด log

    final class Log {
        let url: URL
        private var lines: [String] = []
        init(url: URL) { self.url = url }
        func add(_ s: String) {
            lines.append(s)
            print("[matrix] " + s)
        }
        func flush() {
            try? (lines.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
        }
    }

    // MARK: ช่องข้อความที่ widget ประกาศ

    /// เก็บช่องข้อความจาก `TextSlotKey` ตอนวาดในโหมดแก้ข้อความ — ลำดับตามที่ widget ประกาศ
    final class SlotSink {
        private(set) var slots: [(key: String, name: String)] = []
        func take(_ anchors: [TextSlotAnchor]) {
            var seen = Set<String>()
            slots = anchors.compactMap { a in
                let k = WidgetTextStyle.slotKey(a.id.field, a.id.index)
                guard seen.insert(k).inserted else { return nil }
                return (k, a.id.hint ?? a.id.field.rawValue)
            }
        }
    }

    struct SlotProbe: ViewModifier {
        let sink: SlotSink?
        func body(content: Content) -> some View {
            content.backgroundPreferenceValue(TextSlotKey.self) { anchors in
                let _ = sink?.take(anchors)
                Color.clear
            }
        }
    }

    // MARK: สร้าง config

    static func configID(_ kind: String, _ label: String) -> String {
        let allowed = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        let l = label.replacingOccurrences(of: "=", with: "-")
        return kind + "__" + String(l.filter { allowed.contains($0) })
    }

    /// ภาพนิ่งของชิ้นเดียว — ผ่าน `CardStore.snapshot` ตัวจริง จึงเป็น JSON แบบเดียวกับที่การ์ดเก็บ
    static func itemSnapshot(_ w: WidgetInstance) -> CardSnapshot.Item {
        CardStore.snapshot(pages: [CardPage([w])], theme: CardTheme(), index: 0).pages[0].items[0]
    }

    /// กล่องของก้อนข้อความ = ตัวอักษรพอดี — สูตรเดียวกับ `CardScreen.fitTextBlock`
    static func fitTextBlock(_ w: inout WidgetInstance) {
        let inset = TextBlock.inset
        let text = Profile.me.note(w.id)
        let size = TextFit.capped(w.textStyle.points, text, face: w.textStyle.face,
                                  weight: TextBlock.weight, maxWidth: contentWidth - inset * 2)
        let m = TextFit.metrics(text, face: w.textStyle.face, weight: TextBlock.weight,
                                size: size, align: w.textStyle.align)
        w.w = min(m.ink.width + inset * 2, contentWidth)
        w.h = m.ink.height + inset * 2
    }

    static func baseInstance(_ kind: WidgetKind) -> WidgetInstance {
        let s = kind.defaultSize
        var w = WidgetInstance(kind, x: margin, y: margin, w: s.width, h: s.height, id: fixedID)
        if kind.isTextLayer { fitTextBlock(&w) }
        return w
    }

    static var themeVariants: [(String, CardSnapshot.Theme)] {
        func t(_ f: (inout CardSnapshot.Theme) -> Void) -> CardSnapshot.Theme {
            var x = baseTheme
            f(&x)
            return x
        }
        return [
            ("ink=paper", t { $0.ink = "paper" }),
            ("ink=mist", t { $0.ink = "mist" }),
            ("corner=soft", t { $0.corner = "soft" }),
            ("corner=pill", t { $0.corner = "pill" }),
            ("palette=rose", t { $0.palette = "rose" }),
            ("palette=champagne", t { $0.palette = "champagne" }),
            ("duo=indigo", t { $0.duo = "indigo"; $0.duoFlipped = false }),
            ("duo=indigo-flipped", t { $0.duo = "indigo"; $0.duoFlipped = true }),
        ]
    }

    static func configs(for kind: WidgetKind, slots: [String]) -> [Config] {
        var out: [Config] = []
        func add(_ group: String, _ label: String, theme: CardSnapshot.Theme = baseTheme,
                 _ change: (inout WidgetInstance) -> Void = { _ in }) {
            var w = baseInstance(kind)
            change(&w)
            if kind.isTextLayer { fitTextBlock(&w) }
            out.append(Config(id: configID(kind.rawValue, label), kind: kind.rawValue,
                              group: group, label: label,
                              page: PageSpec(w: Double(w.w + margin * 2), h: Double(w.h + margin * 2),
                                             strip: false),
                              theme: theme, item: itemSnapshot(w)))
        }

        add("base", "base")
        for s in kind.surfaceOptions where s != kind.defaultSurface {
            add("surface", "surface=\(s.rawValue)") { $0.surface = s }
        }
        let border = !kind.defaultBorder
        add("border", "border=\(border ? "on" : "off")") { $0.border = border }
        // ตัวเลือกแบบเลือกหนึ่งของไฟล์ผัง (`widget.controls` ชนิด segment) — ทุกค่าที่ไม่ใช่ค่าตั้งต้น
        for ctl in kind.controls where ctl.type == "segment" {
            guard let opt = ctl.opt else { continue }
            for v in (ctl.options ?? []).compactMap({ $0.first ?? nil }) {
                add(opt, "\(opt)=\(v)") { $0.surface = .glass; $0.options[opt] = v }
            }
        }
        for (label, theme) in themeVariants {
            add("theme", label, theme: theme)
        }
        if kind.canResize {
            add("size", "size=wide") { $0.w = ($0.w * 1.4).rounded() }
            add("size", "size=small") { w in
                let target = max(PageLayout.minSize.width, (w.w * 0.7).rounded())
                w.scale(toWidth: target)
                w.h = max(w.h, PageLayout.minSize.height)
            }
        }
        for key in slots {
            for f in CardFont.allCases {
                add("text", "slot=\(key)_font=\(f.rawValue)") { $0.textStyle.slotFaces[key] = f }
            }
            for z in [WidgetTextSize.xs, .xxl] {
                add("text", "slot=\(key)_size=\(z.rawValue)") { $0.textStyle.slotSizes[key] = z }
            }
            for c in slotTints {
                add("text", "slot=\(key)_color=\(c.rawValue)") { $0.textStyle.slotTints[key] = c }
            }
        }
        if kind.isTextLayer {
            for f in CardFont.allCases {
                add("textBlock", "face=\(f.rawValue)") { $0.textStyle.face = f }
            }
            for a in TextAlign.allCases {
                add("textBlock", "align=\(a.rawValue)") { $0.textStyle.align = a }
            }
            for p in [16, 48] {
                add("textBlock", "points=\(p)") { $0.textStyle.points = CGFloat(p) }
            }
        }
        return out
    }

    static func pageConfigs() -> [Config] {
        var out: [Config] = []
        func add(_ label: String, _ f: (inout CardSnapshot.Theme) -> Void) {
            var t = baseTheme
            f(&t)
            out.append(Config(id: configID("_page", label), kind: "_page", group: "page", label: label,
                              page: PageSpec(w: Double(pageSeriesSize.width), h: Double(pageSeriesSize.height),
                                             strip: true),
                              theme: t, item: nil))
        }
        for ink in ["night", "paper"] {
            for b in pageBackdrops {
                add("backdrop=\(b.rawValue)_ink=\(ink)") { $0.backdrop = b.rawValue; $0.ink = ink }
            }
        }
        for s in StripStyle.allCases {
            add("strip=\(s.rawValue)") { $0.strip = s.rawValue }
        }
        return out
    }

    // MARK: วาด

    /// ธีมจริงจาก JSON ของธีม — ผ่าน `CardStore.restore` ตัวเดียวกับที่เปิดการ์ด
    /// (restore ต้องมีชิ้นอย่างน้อยหนึ่งชิ้น จึงยัดชิ้นหลอกไว้แล้วเอาแค่ธีม)
    static func restoreTheme(_ t: CardSnapshot.Theme) -> CardTheme? {
        let dummy = itemSnapshot(WidgetInstance(.textLayer, id: fixedID))
        return CardStore.restore(CardSnapshot(pages: [.init(items: [dummy])], theme: t, index: 0))?.theme
    }

    static func render(_ cfg: Config, photos: PhotoStore, scale: CGFloat,
                       editMode: Bool = false, sink: SlotSink? = nil, sample: Bool = false) -> UIImage? {
        let page = CGSize(width: cfg.page.w, height: cfg.page.h)
        let content: AnyView
        if let item = cfg.item {
            let snap = CardSnapshot(pages: [.init(items: [item])], theme: cfg.theme, index: 0)
            guard let (pages, theme, _) = CardStore.restore(snap),
                  let w = pages.first?.items.first else { return nil }
            content = AnyView(MatrixWidgetPage(item: w, theme: theme, page: page, sample: sample)
                .environment(\.textEditMode, editMode)
                .modifier(SlotProbe(sink: sink)))
        } else {
            guard let theme = restoreTheme(cfg.theme) else { return nil }
            content = AnyView(CardSheet(pages: [CardPage()], theme: theme, pageSize: page, format: .story)
                .environment(\.previewStatic, true))
        }
        let renderer = ImageRenderer(content: content.environment(photos))
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage
    }

    /// ของที่ widget ใบนี้จะขึ้นแทนตัวจริงเพราะข้อมูลบนเครื่องยังว่าง (`WidgetBody.pending`)
    static func pendingNote(_ kind: WidgetKind) -> String? {
        let c = Profile.me.creator
        let sample = Profile.me.sampleFamilies
        switch kind.family {
        case .brand: return c.track.brands.isEmpty ? "SystemPending (no brands)" : nil
        case .verified: return c.track.works.isEmpty ? "SystemPending (no works)" : nil
        case .audience: return c.audience.isEmpty ? "SystemPending (no audience)" : nil
        case .followers: return sample.contains(.followers) ? "SystemPending (followers are sample)" : nil
        case .rate: return sample.contains(.rate) ? "SystemPending (rates are sample)" : nil
        default: return nil
        }
    }

    // MARK: ทั้งชุด

    static func run(photos: PhotoStore) async {
        let t0 = Date()
        let fm = FileManager.default
        let dir = URL.documentsDirectory.appending(path: folder)
        try? fm.removeItem(at: dir)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let log = Log(url: dir.appending(path: "log.txt"))
        log.add("widget matrix export — start \(ISO8601DateFormatter().string(from: t0))")
        log.add("device: \(UIDevice.current.name) · iOS \(UIDevice.current.systemVersion)")

        // 1) รูปจากเน็ตต้องอยู่ในแคชก่อน — `ImageRenderer` ไม่รัน `.task` รูปที่ยังไม่มาจะอบเป็นช่องว่างถาวร
        var urls = Set((0..<PhotoLib.count).map { PhotoLib.url($0) })
        for brand in Profile.me.creator.track.brands {
            if let raw = brand.logo, let u = URL(string: raw) { urls.insert(u) }
        }
        await withTaskGroup(of: Void.self) { group in
            for u in urls {
                group.addTask { _ = await ImageCache.shared.load(u) }
            }
        }
        let missing = urls.filter { ImageCache.shared.cached($0) == nil }
        log.add("preloaded \(urls.count - missing.count)/\(urls.count) remote images"
                + (missing.isEmpty ? "" : " — MISSING: " + missing.map(\.absoluteString).sorted().joined(separator: ", ")))

        log.flush()

        // 2) หาช่องข้อความของแต่ละชนิด — วาดใบตั้งต้นในโหมดแก้ข้อความแล้วเก็บ `TextSlotKey`
        let tDiscover = Date()
        var slotMap: [WidgetKind: [String]] = [:]
        var skipped: [(WidgetKind, String)] = []
        log.add("")
        log.add("== text slots (runtime TextSlotKey preference, textEditMode = true) ==")
        for kind in WidgetKind.allCases {
            guard let base = configs(for: kind, slots: []).first else { continue }
            let sink = SlotSink()
            guard render(base, photos: photos, scale: 1, editMode: true, sink: sink) != nil else {
                skipped.append((kind, "ImageRenderer returned nil"))
                continue
            }
            slotMap[kind] = sink.slots.map(\.key)
            let desc = sink.slots.map { $0.key == $0.name ? $0.key : "\($0.key) (\($0.name))" }
            log.add("\(kind.rawValue): \(desc.isEmpty ? "—" : desc.joined(separator: ", "))")
            await Task.yield()
        }
        log.add("slot discovery: \(Int(Date().timeIntervalSince(tDiscover) * 1000)) ms")

        log.add("")
        log.add("== data state (widgets that draw SystemPending instead of their design) ==")
        let pending = WidgetKind.allCases.compactMap { k in pendingNote(k).map { "\(k.rawValue): \($0)" } }
        log.add(pending.isEmpty ? "none" : pending.joined(separator: "\n"))

        log.add("")
        log.add("== skipped kinds ==")
        log.add(skipped.isEmpty ? "none" : skipped.map { "\($0.0.rawValue): \($0.1)" }.joined(separator: "\n"))
        let noSize = WidgetKind.allCases.filter { !$0.canResize }.map(\.rawValue)
        log.add("no size group (canResize == false): \(noSize.joined(separator: ", "))")

        // 3) matrix.json — เขียนก่อนเริ่มอบ ฝั่ง Android เริ่มได้ทันที
        var all: [Config] = []
        for kind in WidgetKind.allCases where slotMap[kind] != nil {
            all += configs(for: kind, slots: slotMap[kind] ?? [])
        }
        all += pageConfigs()
        var seen = Set<String>()
        let dupes = all.filter { !seen.insert($0.id).inserted }.map(\.id)
        if !dupes.isEmpty { log.add("DUPLICATE ids: \(dupes.joined(separator: ", "))") }

        let matrix = Matrix(scale: Int(scale), margin: Int(margin), baseTheme: baseTheme,
                            rules: Rules(), configs: all)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let matrixURL = dir.appending(path: "matrix.json")
        do {
            try enc.encode(matrix).write(to: matrixURL)
        } catch {
            log.add("FAILED to write matrix.json: \(error)")
        }
        if let target = ProcessInfo.processInfo.environment["MATRIX_COPY_TO"], !target.isEmpty {
            let dest = URL(fileURLWithPath: target)
            try? fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? fm.removeItem(at: dest)
            do { try fm.copyItem(at: matrixURL, to: dest); log.add("matrix.json copied → \(dest.path)") }
            catch { log.add("matrix.json copy → \(dest.path) failed: \(error.localizedDescription)") }
        }
        var perGroup: [String: Int] = [:]
        for c in all { perGroup[c.group, default: 0] += 1 }
        log.add("")
        log.add("== configs: \(all.count) total · kinds rendered \(slotMap.count)/\(WidgetKind.allCases.count) ==")
        log.add(perGroup.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: " · "))
        log.add("")
        log.add("== render ==")
        log.flush()

        // 4) อบทีละ config — ชนิดละหนึ่งรอบอุ่นเครื่องก่อน (รูป/หน้ากากที่ตัววาดขอระหว่างวาดครั้งแรก)
        let tRender = Date()
        var failures: [String] = []
        var groupMs: [String: Double] = [:]
        var lastKind = ""
        for (n, cfg) in all.enumerated() {
            if cfg.kind != lastKind {
                lastKind = cfg.kind
                _ = render(cfg, photos: photos, scale: scale)
                await Task.yield()
            }
            let t = Date()
            autoreleasepool {
                guard let ui = render(cfg, photos: photos, scale: scale), let cg = ui.cgImage else {
                    failures.append("\(cfg.id): render nil")
                    return
                }
                let wantW = Int((cfg.page.w * Double(scale)).rounded())
                let wantH = Int((cfg.page.h * Double(scale)).rounded())
                if cg.width != wantW || cg.height != wantH {
                    failures.append("\(cfg.id): size \(cg.width)x\(cg.height) px, expected \(wantW)x\(wantH)")
                }
                guard let png = ui.pngData() else {
                    failures.append("\(cfg.id): pngData nil")
                    return
                }
                do { try png.write(to: dir.appending(path: "\(cfg.id).png")) }
                catch { failures.append("\(cfg.id): write failed \(error.localizedDescription)") }
            }
            groupMs[cfg.group, default: 0] += Date().timeIntervalSince(t) * 1000
            if (n + 1) % 200 == 0 {
                log.add("progress \(n + 1)/\(all.count) · \(Int(Date().timeIntervalSince(tRender)))s")
                log.flush()
            }
            await Task.yield()
        }

        log.add("")
        log.add("== render failures ==")
        log.add(failures.isEmpty ? "none" : failures.joined(separator: "\n"))
        log.add("")
        log.add("== timing ==")
        log.add("render total \(Int(Date().timeIntervalSince(tRender)))s for \(all.count) configs")
        log.add(groupMs.sorted { $0.key < $1.key }
            .map { "\($0.key): \(Int($0.value)) ms (\(perGroup[$0.key] ?? 0) configs)" }
            .joined(separator: " · "))
        log.add("wall clock \(Int(Date().timeIntervalSince(t0)))s")
        log.add("DONE")
        log.flush()
    }
}

/// หน้าเมทริกซ์ของ widget หนึ่งชิ้น — ฉากหลังจริง + `WidgetChrome` จริง วางแบบเดียวกับ `CardPageCanvas`
///
/// ต่างจาก `CardFramePreview` สามข้อ (ตั้งใจ): ไม่มีแถบผู้ออกบัตร (`signed: false` · ไม่มี `SignatureEmboss`)
/// ไม่มีเส้นขอบ/มุมมนของพรีวิว และ `pageContentWidth` ตรึงไว้ที่หน้าสตอรี่ (ดู `WidgetMatrixExport.contentWidth`)
private struct MatrixWidgetPage: View {
    let item: WidgetInstance
    let theme: CardTheme
    let page: CGSize
    var sample = false

    var body: some View {
        // วางตรง ๆ ที่กรอบของชิ้น — ไม่ผ่าน `PageLayout.solve` ซึ่งปัดเข้าสามขนาด *ของหน้าเมทริกซ์* (ที่เล็กกว่าหน้าจริง)
        let solved = [Placed(item: item, frame: item.rect)]
        ZStack {
            CardBackdrop(theme: theme, ignoreSafeArea: false, signed: false)
            ZStack {
                ForEach(solved) { p in
                    WidgetChrome(placed: p, theme: theme, forceSample: sample)
                        .frame(width: p.frame.width, height: p.frame.height)
                        .position(x: p.frame.midX, y: p.frame.midY)
                }
            }
            .frame(width: page.width, height: page.height, alignment: .topLeading)
            .environment(\.cardInk, theme.inkStyle)
            .environment(\.pageContentWidth, WidgetMatrixExport.contentWidth)
        }
        .frame(width: page.width, height: page.height)
        .clipped()
        .environment(\.cardInk, theme.inkStyle)
        .environment(\.colorScheme, theme.activeInk.isLight ? .light : .dark)
        .environment(\.previewStatic, true)
        .transaction { $0.animation = nil }
    }
}

// MARK: - เมทริกซ์สามขนาด — ทุกชนิด × ทุกขนาดที่รับได้ × สองรูปแบบหน้า (DEBUG เท่านั้น)
//
// เปิดแอปด้วย `-exportShapeMatrix` → `Documents/ShapeMatrix/`:
//   <kind>.png   — แถบของชนิดนั้น: สตอรี่ (เล็ก · แนวนอน · ใหญ่) แล้วพอร์ต (เล็ก · แนวนอน · ใหญ่) เฉพาะที่รับได้
//   sheet-N.png  — แถบ 8 ชนิดต่อแผ่น ไว้เปิดดูทีเดียว
//   shapes.txt   — ชนิด → ขนาดที่รับได้
@MainActor
enum ShapeMatrixExport {
    static let folder = "ShapeMatrix"
    static let pages: [(String, CGSize)] = [("story", CardTemplate.previewPageSize(for: .story)),
                                           ("port", CardTemplate.previewPageSize(for: .portfolio))]

    /// สามกรอบทดสอบต่อหน้า — ครึ่ง×ครึ่ง · เต็ม×ครึ่ง · เต็ม×เต็ม (ความกว้างหน้าหักขอบกระดาษ)
    /// ไม่ใช่ "ขนาดของระบบ" อีกแล้ว (ผู้ใช้ 13 ต.ค. 2569 ดึก: resize อิสระ) — แค่สามจุดไว้ส่องว่าผังจัดตัวเองได้
    static func probeSizes(_ page: CGSize) -> [(name: String, size: CGSize)] {
        let full = PageLayout.content(page).width
        let half = ((full - PageLayout.gap) / 2).rounded(.down)
        return [("เล็ก", CGSize(width: half, height: half)),
                ("แนวนอน", CGSize(width: full, height: half)),
                ("ใหญ่", CGSize(width: full, height: full))]
    }

    static func run(photos: PhotoStore) async {
        let fm = FileManager.default
        let dir = URL.documentsDirectory.appending(path: folder)
        try? fm.removeItem(at: dir)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        PhotoStore.exportPerson = ProcessInfo.processInfo.arguments.contains("-exportPerson")
        defer { PhotoStore.exportPerson = false }
        let m = WidgetMatrixExport.margin
        var lines: [String] = []
        var strips: [(String, UIImage)] = []
        // รูปจากเน็ตต้องอยู่ในแคชก่อน — `ImageRenderer` ไม่รัน `.task` (โลโก้แบรนด์ในใบแรก ๆ จะว่าง)
        var urls = Set((0..<PhotoLib.count).map { PhotoLib.url($0) })
        for brand in Profile.me.shownTrack(.brand).brands { if let raw = brand.logo, let u = URL(string: raw) { urls.insert(u) } }
        await withTaskGroup(of: Void.self) { group in for u in urls { group.addTask { _ = await ImageCache.shared.load(u) } } }

        for kind in WidgetKind.allCases where kind.canResize {
            lines.append("\(kind.rawValue): small · wide · large · default=\(Int(kind.defaultSize.width))×\(Int(kind.defaultSize.height))")
            var cells: [UIImage] = []
            for (_, page) in pages {
                for (si, shape) in probeSizes(page).enumerated() {
                    var w = WidgetMatrixExport.baseInstance(kind)
                    w.x = m; w.y = m
                    w.rect.size = shape.size
                    let cfg = WidgetMatrixExport.Config(
                        id: kind.rawValue, kind: kind.rawValue, group: "shape", label: shape.name,
                        page: .init(w: Double(w.w + m * 2), h: Double(w.h + m * 2), strip: false),
                        theme: WidgetMatrixExport.baseTheme, item: WidgetMatrixExport.itemSnapshot(w))
                    _ = WidgetMatrixExport.render(cfg, photos: photos, scale: 1, sample: true)
                    if let ui = WidgetMatrixExport.render(cfg, photos: photos, scale: 1, sample: true) { cells.append(ui) }
                    // ใบเดี่ยว @2x ต่อ ชนิด × ขนาด × หน้า — เอาไปวางเทียบกับแบบ HTML (present/widget-sizes)
                    if let ui2 = WidgetMatrixExport.render(cfg, photos: photos, scale: 2, sample: true) {
                        let pageName = page.width > 500 ? "story" : "port"
                        let sizeName = ["small", "wide", "large"][si]
                        try? ui2.pngData()?.write(to: dir.appending(path: "cell-\(kind.rawValue)-\(sizeName)-\(pageName).png"))
                    }
                    await Task.yield()
                }
            }
            let strip = compose(cells, title: kind.rawValue + "  [เล็ก·แนวนอน·ใหญ่]")
            strips.append((kind.rawValue, strip))
            try? strip.pngData()?.write(to: dir.appending(path: "\(kind.rawValue).png"))
        }
        for (n, chunk) in stride(from: 0, to: strips.count, by: 8).enumerated() {
            let sheet = stack(Array(strips[chunk..<min(chunk + 8, strips.count)]).map(\.1))
            try? sheet.pngData()?.write(to: dir.appending(path: "sheet-\(n).png"))
        }
        try? (lines.joined(separator: "\n") + "\n").write(to: dir.appending(path: "shapes.txt"), atomically: true, encoding: .utf8)
        print("[shapes] wrote \(strips.count) strips → \(dir.path)")
    }

    /// เรียงช่องในแถวเดียว พร้อมชื่อชนิดบนหัว
    static func compose(_ cells: [UIImage], title: String) -> UIImage {
        let gap: CGFloat = 10, head: CGFloat = 22
        let w = cells.reduce(gap) { $0 + $1.size.width + gap }
        let h = (cells.map(\.size.height).max() ?? 0) + gap * 2 + head
        let f = UIGraphicsImageRendererFormat(); f.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: max(w, 200), height: h), format: f).image { ctx in
            UIColor(white: 0.12, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: max(w, 200), height: h)))
            (title as NSString).draw(at: CGPoint(x: gap, y: 4), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 13), .foregroundColor: UIColor.white])
            var x = gap
            for c in cells {
                c.draw(at: CGPoint(x: x, y: head + gap))
                x += c.size.width + gap
            }
        }
    }

    static func stack(_ strips: [UIImage]) -> UIImage {
        let w = strips.map(\.size.width).max() ?? 1
        let h = strips.reduce(0) { $0 + $1.size.height }
        let f = UIGraphicsImageRendererFormat(); f.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: f).image { ctx in
            UIColor(white: 0.12, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            var y: CGFloat = 0
            for s in strips { s.draw(at: CGPoint(x: 0, y: y)); y += s.size.height }
        }
    }
}
#endif
