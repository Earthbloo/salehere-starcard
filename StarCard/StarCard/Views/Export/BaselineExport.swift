#if DEBUG
import SwiftUI
import UIKit

// MARK: - ภาพก่อน/หลัง ของการย้ายนิสัย widget ไปไว้ใน JSON
//
// เปิดแอปด้วย `-exportBaseline` → `Documents/<BASELINE_OUT ?? Baseline>/`:
//   traits.json — นิสัยทุกชนิดที่แอปอ่าน (ตู้ · ถาด · พื้นผิว · ป้าย · ท่าเข้า · ลำดับตู้)
//   <kind>__<variant>.png — ใบเดียวผ่าน chrome จริง ทุกพื้นผิว × ขอบ · กระดาษ · คู่สี · ห้าสไตล์ · ลาย · ล็อก
//   done.txt เมื่อเสร็จ
// รันก่อนและหลังแก้ แล้วเทียบสองโฟลเดอร์ — ต้องเท่ากันทุกไฟล์ (ดู shared/docs/WIDGET-CATEGORY-PLAN.md ข้อ 9)
@MainActor
enum BaselineExport {
    static func motionName(_ s: EntranceStyle) -> String {
        let named: [(String, EntranceStyle)] = [("deep", .deep), ("mid", .mid), ("light", .light), ("anchored", .anchored)]
        for (n, e) in named where e.pose.dy == s.pose.dy && e.pose.scale == s.pose.scale && e.pose.rotY == s.pose.rotY {
            return n
        }
        return "?"
    }

    static func traits(_ k: WidgetKind) -> [String: Any] {
        var t: [String: Any] = [
            "title": k.title, "symbol": k.symbol,
            "size": [k.defaultSize.width, k.defaultSize.height],
            "family": k.family.rawValue, "trayGroup": k.family.trayGroup.rawValue,
            "group": k.group.rawValue, "tier": "\(k.tier)",
            "ownSurface": k.drawsOwnSurface, "surfaceChoice": k.usesSurfaceChoice,
            "surfaces": k.surfaceOptions.map(\.rawValue),
            "surfaceNames": Dictionary(uniqueKeysWithValues: WidgetSurface.allCases.map { ($0.rawValue, k.surfaceName($0)) }),
            "defaultSurface": k.defaultSurface.rawValue, "border": k.defaultBorder,
            "controls": k.controls.compactMap(\.opt), "photo": k.usesPhoto,
            "keepAspect": k.keepsDesignAspect, "fullBleed": k.isFullBleed, "resize": k.canResize,
            "kit": k.isKit, "pop": k.popSkin != nil,
            "skin": k.popSkin?.rawValue ?? "-", "kitTitle": k.kitTitle ?? "-",
            "stamp": k.stampFacts.map { "\($0)" } ?? "-",
            "motion": motionName(k.entranceStyle),
            "minSize": [PageLayout.minSize(for: k).width, PageLayout.minSize(for: k).height],
            "topic": k.family.topic.map { "\($0)" } ?? "-",
        ]
        if let o = k.stampOverlay { t["stampAt"] = ["\(o.tone)", o.top, o.trailing] }
        return t
    }

    static func run(photos: PhotoStore) async {
        let env = ProcessInfo.processInfo.environment
        let fm = FileManager.default
        let dir = URL.documentsDirectory.appending(path: env["BASELINE_OUT"] ?? "Baseline")
        try? fm.removeItem(at: dir)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        // นิสัย + ลำดับ
        var kinds = WidgetKind.allCases
        if let tb = WidgetKind(rawValue: "textBlock"), !kinds.contains(tb) { kinds.append(tb) }
        var all: [String: Any] = [:]
        for k in kinds { all[k.rawValue] = traits(k) }
        all["_order"] = WidgetKind.allCases.map(\.rawValue)
        all["_gallery"] = WidgetGallery.orderedKinds().map(\.rawValue)
        all["_pinned"] = PinnedSeal.kind?.rawValue ?? "-"
        if let data = try? JSONSerialization.data(withJSONObject: all, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: dir.appending(path: "traits.json"))
        }

        var urls = Set((0..<PhotoLib.count).map { PhotoLib.url($0) })
        for brand in Profile.me.shownTrack(.brand).brands { if let raw = brand.logo, let u = URL(string: raw) { urls.insert(u) } }
        await withTaskGroup(of: Void.self) { group in for u in urls { group.addTask { _ = await ImageCache.shared.load(u) } } }

        let m = WidgetMatrixExport.margin
        var paper = WidgetMatrixExport.baseTheme; paper.ink = "paper"
        var duo = WidgetMatrixExport.baseTheme; duo.duo = "indigo"; duo.duoFlipped = false
        let only = env["BASELINE_ONLY"].flatMap { $0.isEmpty ? nil : $0.split(separator: ",").map(String.init) }
        for kind in kinds {
            if let only, !only.contains(kind.rawValue) { continue }
            var cells: [(String, CardSnapshot.Theme, (inout WidgetInstance) -> Void, Bool)] = []
            let opts = kind.surfaceOptions.isEmpty ? [kind.defaultSurface] : kind.surfaceOptions
            for s in opts { for b in [false, true] {
                cells.append(("\(s.rawValue)\(b ? "+border" : "")", WidgetMatrixExport.baseTheme, { $0.surface = s; $0.border = b }, true))
            } }
            cells.append(("paper", paper, { _ in }, true))
            cells.append(("duo", duo, { _ in }, true))
            cells.append(("live", WidgetMatrixExport.baseTheme, { _ in }, false))
            if kind.controls.contains(where: { $0.opt == "pattern" }) { cells.append(("stripe", paper, { $0.pattern = .stripe }, true)) }
            for (name, theme, edit, sample) in cells {
                var w = WidgetMatrixExport.baseInstance(kind)
                w.x = m; w.y = m
                edit(&w)
                let cfg = WidgetMatrixExport.Config(
                    id: kind.rawValue, kind: kind.rawValue, group: "baseline", label: name,
                    page: .init(w: Double(w.w + m * 2), h: Double(w.h + m * 2), strip: false),
                    theme: theme, item: WidgetMatrixExport.itemSnapshot(w))
                if let ui = WidgetMatrixExport.render(cfg, photos: photos, scale: 1, sample: sample) {
                    try? ui.pngData()?.write(to: dir.appending(path: "\(kind.rawValue)__\(name).png"))
                }
                await Task.yield()
            }
        }
        try? "done".write(to: dir.appending(path: "done.txt"), atomically: true, encoding: .utf8)
        print("[baseline] wrote \(kinds.count) kinds → \(dir.path)")
    }
}
#endif

#if DEBUG
/// `-benchKinds` — เวลาของงานที่ถาดทำทุกเฟรมตอนลาก/ยืด (แถว "แบบ" = `allCases` สามรอบ + property ของทุกชิ้น)
@MainActor
enum KindBench {
    static func run(photos: PhotoStore) async {
        // env BENCH_RENDER=a,b: วาดใบเต็ม (chrome + ตัววาดผัง) 20 ขนาดไล่กัน — แทนเฟรมตอนยืดกรอบ
        if let list = ProcessInfo.processInfo.environment["BENCH_RENDER"] {
            var urls = Set((0..<PhotoLib.count).map { PhotoLib.url($0) })
            for brand in Profile.me.shownTrack(.brand).brands { if let raw = brand.logo, let u = URL(string: raw) { urls.insert(u) } }
            await withTaskGroup(of: Void.self) { g in for u in urls { g.addTask { _ = await ImageCache.shared.load(u) } } }
            for name in list.split(separator: ",").map(String.init) {
                guard let kind = WidgetKind(rawValue: name) else { continue }
                var total = 0.0
                for pass in 0..<2 {
                    let t0 = CFAbsoluteTimeGetCurrent()
                    for i in 0..<20 {
                        var w = WidgetMatrixExport.baseInstance(kind)
                        let m = WidgetMatrixExport.margin
                        w.x = m; w.y = m
                        w.w = (w.w * (1 - CGFloat(i) * 0.013)).rounded()
                        let cfg = WidgetMatrixExport.Config(
                            id: name, kind: name, group: "bench", label: "\(i)",
                            page: .init(w: Double(w.w + m * 2), h: Double(w.h + m * 2), strip: false),
                            theme: WidgetMatrixExport.baseTheme, item: WidgetMatrixExport.itemSnapshot(w))
                        _ = WidgetMatrixExport.render(cfg, photos: photos, scale: 1, sample: true)
                    }
                    if pass == 1 { total = (CFAbsoluteTimeGetCurrent() - t0) * 1000 / 20 }
                }
                print("[bench] render \(name): \(String(format: "%.1f", total)) ms/เฟรม")
            }
            print("[bench] render done")
            return
        }
        // env BENCH_KIND=<kind>: วนคำนวณใบเดียวยาว ๆ ให้ `sample` จับ
        if let only = ProcessInfo.processInfo.environment["BENCH_KIND"], let spec = SpecCatalog.spec(named: only) {
            let d = spec.design.cg
            let data = IOSSpecData(sample: true, widget: nil)
            for i in 0..<3000 {
                let f = 1 - CGFloat(i) * 0.0001
                _ = SpecSolver(spec: spec, box: CGSize(width: d.width * f, height: d.height), data: data,
                               measurer: IOSSpecMeasurer.shared, renderScale: 1).solve()
            }
            print("[bench] loop done")
            return
        }
        func time(_ label: String, _ n: Int, _ body: () -> Void) {
            let t0 = CFAbsoluteTimeGetCurrent()
            for _ in 0..<n { body() }
            print("[bench] \(label): \(String(format: "%.3f", (CFAbsoluteTimeGetCurrent() - t0) * 1000 / Double(n))) ms/รอบ")
        }
        let names = SpecCatalog.all.map(\.kind)
        // แบบก่อนแก้: ทุกครั้งดึง WidgetSpec ทั้งก้อนจากแคชผัง แล้วเรียงใหม่
        time("allCases ไม่แคช ×3 (แบบเดิม)", 50) {
            for _ in 0..<3 {
                let ks = names.filter { SpecCatalog.spec(named: $0)?.widget != nil }.sorted()
                _ = ks.sorted { (SpecCatalog.spec(named: $0)?.widget?.order ?? .max) < (SpecCatalog.spec(named: $1)?.widget?.order ?? .max) }
            }
        }
        time("allCases แคช ×3", 50) { for _ in 0..<3 { _ = WidgetKind.allCases.filter { $0.family == .hero } } }
        let kinds = WidgetKind.allCases
        // ตัวคำนวณผังต่อเฟรมตอนยืด: ขนาดกรอบเปลี่ยนทุกเฟรม = คิดใหม่ทั้งใบ (แคชจำตามขนาด) — 40 ขนาดไล่จาก 100% → 60% ของผัง
        var rows: [(String, Double)] = []
        for k in kinds {
            guard let spec = SpecCatalog.spec(for: k) else { continue }
            let d = spec.design.cg
            let data = IOSSpecData(sample: true, widget: nil)
            let t0 = CFAbsoluteTimeGetCurrent()
            for i in 0..<40 {
                let f = 1 - CGFloat(i) * 0.01
                _ = SpecSolver(spec: spec, box: CGSize(width: d.width * f, height: d.height), data: data,
                               measurer: IOSSpecMeasurer.shared, renderScale: 1).solve()
            }
            rows.append((k.rawValue, (CFAbsoluteTimeGetCurrent() - t0) * 1000 / 40))
        }
        for (k, ms) in rows.sorted(by: { $0.1 > $1.1 }).prefix(15) { print("[bench] solve \(k): \(String(format: "%.2f", ms)) ms/เฟรม") }
        time("property 15 ตัว × ทุกชนิด", 50) {
            for k in kinds {
                _ = (k.drawsOwnSurface, k.isFullBleed, k.family, k.tier, k.stampFacts,
                     k.stampOverlay, k.drawsOwnBorder, k.defaultSize, k.canResize, k.isKit, k.popSkin, k.surfaceOptions, k.symbol)
            }
        }
    }
}
#endif


#if DEBUG
/// env `HITCH=1` — นับเฟรมที่ช้ากว่างบ (CADisplayLink) พิมพ์สรุปทุก 3 วิที่มีการขยับ
final class HitchMonitor: NSObject {
    static let shared = HitchMonitor()
    static var solveMs = 0.0
    static var solves = 0
    static var paints = 0
    private var link: CADisplayLink?
    private var last: CFTimeInterval = 0
    private var gaps: [Double] = []
    private var windowStart: CFTimeInterval = 0
    func start() {
        guard ProcessInfo.processInfo.environment["HITCH"] != nil, link == nil else { return }
        let l = CADisplayLink(target: self, selector: #selector(tick(_:)))
        l.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        l.add(to: .main, forMode: .common)
        link = l
    }
    @objc private func tick(_ l: CADisplayLink) {
        let now = l.timestamp
        if last > 0 {
            let gap = (now - last) * 1000
            gaps.append(gap)
            if gap > 30 { print("[hitch] slow frame \(String(format: "%.0f", gap))ms · solve \(String(format: "%.1f", Self.solveMs))ms × \(Self.solves) · painter body × \(Self.paints)") }
        }
        Self.solveMs = 0; Self.solves = 0; Self.paints = 0
        last = now
        if windowStart == 0 { windowStart = now }
        if now - windowStart >= 3 {
            let budget = (l.targetTimestamp - l.timestamp) * 1000
            let slow = gaps.filter { $0 > budget * 1.5 }
            let worst = gaps.max() ?? 0
            print("[hitch] frames \(gaps.count) budget \(String(format: "%.1f", budget))ms slow \(slow.count) worst \(String(format: "%.1f", worst))ms lostTime \(String(format: "%.0f", slow.reduce(0, +) - Double(slow.count) * budget))ms")
            gaps.removeAll(); windowStart = now
        }
    }
}
#endif
