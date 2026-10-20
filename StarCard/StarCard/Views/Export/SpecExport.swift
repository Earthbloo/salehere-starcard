import SwiftUI
import UIKit

#if DEBUG
// MARK: - ส่งออกผัง: รูปของทุกใบที่มีไฟล์ผัง + fixture ของตัวคำนวณ
//
// เปิดแอปด้วย `-exportSpecs` → `Documents/Specs/`:
//   cell-<kind>-<size>.png   — ใบที่วาดผ่าน `SpecPainter` ที่กรอบทดสอบแต่ละขนาด (เทียบกับ present/widget-sizes/ios)
//   fixtures/<kind>.json     — ผลของ `SpecSolver` (กล่องทุกโหนด · ขนาดตัวอักษร · จำนวนบรรทัด) ที่กรอบทดสอบทุกขนาด
//                               = **สัญญาข้ามแพลตฟอร์ม**: Android/Web รัน solver ของตัวเองกับผังเดียวกัน ต้องได้ตัวเลขชุดนี้
//   sheet.png                — ทุกใบ × ทุกขนาด ในแผ่นเดียว
@MainActor
enum SpecExport {
    static let folder = "Specs"

    /// ตัวจดของรอบวาดปัจจุบัน — ตั้งก่อนวาดหนึ่งช่อง · `SpecPainter` จดผลของตัวคำนวณ **ที่ใช้วาดจริง** ลงที่นี่
    nonisolated(unsafe) static var capture: Capture?

    final class Capture {
        var box: CGSize = .zero
        var boxes: [SpecBox] = []
        var measures: [FixtureMeasure] = []
        var lines: [FixtureLine] = []
        var data = FixtureData()
        var scale: CGFloat = 1
        var renderScale: CGFloat = 1
        var hits = 0
        func record(box: CGSize, boxes: [SpecBox], measures: [FixtureMeasure], lines: [FixtureLine], data: FixtureData, scale: CGFloat,
                    renderScale: CGFloat = 1) {
            self.box = box; self.boxes = boxes; self.measures = measures; self.lines = lines; self.data = data; self.scale = scale
            self.renderScale = renderScale
            hits += 1
        }
        func fixtureCase(_ probe: String) -> FixtureCase {
            FixtureCase(probe: probe, box: [Double(box.width), Double(box.height)], boxes: boxes.map {
                FixtureBox(id: $0.id, type: $0.node.type.rawValue,
                           x: SpecExport.r2($0.frame.minX), y: SpecExport.r2($0.frame.minY), w: SpecExport.r2($0.frame.width), h: SpecExport.r2($0.frame.height),
                           text: $0.text?.string, size: $0.text.map { SpecExport.r2($0.size) }, lines: $0.text?.lines, slot: $0.text?.slot)
            }, measures: measures, lineHeights: lines, scale: Double(scale), renderScale: Double(renderScale), data: data)
        }
    }

    /// กรอบทดสอบ (หน่วยออกแบบ) — ผังเดิม · สูงขึ้น · จัตุรัสเล็ก · จัตุรัสใหญ่ · แถบเตี้ย · แคบสูง
    static func probes(for spec: WidgetSpec) -> [(name: String, size: CGSize)] {
        let d = spec.design.cg
        return [("design", d),
                ("tall", CGSize(width: d.width, height: d.height * 2)),
                ("small", CGSize(width: 174, height: 174)),
                ("large", CGSize(width: 366, height: 366)),
                ("strip", CGSize(width: 366, height: max(60, d.height * 0.6))),
                ("narrow", CGSize(width: 240, height: d.height * 1.4))]
    }

    struct FixtureBox: Encodable {
        var id: String; var type: String
        var x: Double; var y: Double; var w: Double; var h: Double
        var text: String?; var size: Double?; var lines: Int?; var slot: String?
    }
    struct FixtureMeasure: Encodable {
        var t: String; var face: String; var size: Double; var weight: Int; var tracking: Double; var kerning: Double
        var lineHeight: Double; var width: Double?; var w: Double; var h: Double; var lines: Int
    }
    struct FixtureCase: Encodable {
        var probe: String; var box: [Double]; var boxes: [FixtureBox]
        /// ทุกครั้งที่ตัวคำนวณถามตัววัดข้อความ (ลำดับตามจริง) — แพลตฟอร์มอื่นใช้ค่านี้แทนตัววัดของตัวเองเพื่อทดสอบอัลกอริทึมล้วน ๆ
        var measures: [FixtureMeasure] = []
        /// ทุกคำถามความสูงบรรทัด (ไม่ซ้ำ) — `face/size/weight/lineHeight` → ค่าที่ตอบ
        var lineHeights: [FixtureLine] = []
        /// ขั้นย่อที่ `fitScale` เลือก (1 = ไม่ย่อ)
        var scale: Double = 1
        /// สเกลของ chrome ตอนวาดจริง — ตัวคำนวณใช้คิดขั้นต่ำที่อ่านออก (`SpecLegibility`)
        var renderScale: Double = 1
        /// ทุกคำตอบที่แหล่งข้อมูลให้ตัวคำนวณ — แพลตฟอร์มอื่นเล่นซ้ำแทนข้อมูลของตัวเอง (ทดสอบอัลกอริทึมล้วน ๆ)
        /// และใช้เทียบว่าแหล่งข้อมูลของตัวเองตอบตรงกับ iOS ทุกข้อ
        var data: FixtureData = FixtureData()
    }
    struct FixtureLine: Encodable { var face: String; var size: Double; var weight: Int; var lineHeight: Double; var italic: Bool; var v: Double }
    struct FixtureText: Encodable { var slot: String; var preset: String?; var v: String }
    struct FixtureItem: Encodable { var id: String; var i: Int; var fields: [String: String] }
    struct FixtureFont: Encodable {
        var slot: String?; var face: String; var size: Double; var weight: Int
        /// ผลหลังผ่านที่ผู้ใช้ตั้งให้ช่อง
        var outFace: String; var outSize: Double; var outWeight: Int
    }
    struct FixtureData: Encodable {
        var texts: [FixtureText] = []
        var lists: [String: [FixtureItem]] = [:]
        var flags: [String: Bool] = [:]
        var fonts: [FixtureFont] = []
    }

    /// แหล่งข้อมูลที่จดทุกคำถาม — คำตอบมาจาก `IOSSpecData` จริง
    final class RecordingData: SpecDataSource {
        let base: IOSSpecData
        var log = FixtureData()
        private var seenTexts = Set<String>(), seenFonts = Set<String>()
        init(_ base: IOSSpecData) { self.base = base }
        func text(slot: String, preset: String?) -> String {
            let v = base.text(slot: slot, preset: preset)
            if seenTexts.insert(slot + "\u{1}" + (preset ?? "\u{2}")).inserted { log.texts.append(FixtureText(slot: slot, preset: preset, v: v)) }
            return v
        }
        func list(_ name: String) -> [SpecItem] {
            let v = base.list(name)
            if log.lists[name] == nil { log.lists[name] = v.map { FixtureItem(id: $0.id, i: $0.i, fields: $0.fields) } }
            return v
        }
        func flag(_ name: String) -> Bool {
            let v = base.flag(name)
            log.flags[name] = v
            return v
        }
        func font(slot: String?, face: String, size: CGFloat, weight: Int) -> SpecFont {
            let f = base.font(slot: slot, face: face, size: size, weight: weight)
            if seenFonts.insert("\(slot ?? "\u{2}")|\(face)|\(size)|\(weight)").inserted {
                log.fonts.append(FixtureFont(slot: slot, face: face, size: Double(size), weight: weight,
                                             outFace: f.face, outSize: Double(f.size), outWeight: f.weight))
            }
            return f
        }
    }

    /// ตัววัดที่จดทุกคำถาม — ค่าที่ตอบมาจาก `IOSSpecMeasurer` จริง
    final class RecordingMeasurer: SpecMeasurer {
        let base = IOSSpecMeasurer.shared
        var log: [FixtureMeasure] = []
        var lines: [FixtureLine] = []
        private var seen = Set<SpecFont>()
        func lineHeight(_ font: SpecFont) -> CGFloat {
            let v = base.lineHeight(font)
            if seen.insert(font).inserted {
                lines.append(FixtureLine(face: font.face, size: Double(font.size), weight: font.weight,
                                         lineHeight: Double(font.lineHeight), italic: font.italic, v: Double(v)))
            }
            return v
        }
        func measure(_ text: String, font: SpecFont, width: CGFloat?) -> (size: CGSize, lines: Int) {
            let r = base.measure(text, font: font, width: width)
            log.append(FixtureMeasure(t: text, face: font.face, size: Double(font.size), weight: font.weight,
                                      tracking: Double(font.tracking), kerning: Double(font.kerning), lineHeight: Double(font.lineHeight),
                                      width: width.map { Double($0) }, w: Double(r.size.width), h: Double(r.size.height), lines: r.lines))
            return r
        }
    }
    struct Fixture: Encodable {
        var kind: String; var design: [Double]
        var rule = "s = min(W/w0, H/h0); box = (W/s - 2*inset, H/s - 2*inset); inset = chrome content inset (12 when the chrome draws a plate or border, else 0); boxes below are in box units"
        var inset: Double
        var cases: [FixtureCase]
    }

    static func run(photos: PhotoStore) async {
        let fm = FileManager.default
        let dir = URL.documentsDirectory.appending(path: folder)
        try? fm.removeItem(at: dir)
        try? fm.createDirectory(at: dir.appending(path: "fixtures"), withIntermediateDirectories: true)
        var urls = Set((0..<PhotoLib.count).map { PhotoLib.url($0) })
        for brand in Profile.me.shownTrack(.brand).brands { if let raw = brand.logo, let u = URL(string: raw) { urls.insert(u) } }
        await withTaskGroup(of: Void.self) { group in for u in urls { group.addTask { _ = await ImageCache.shared.load(u) } } }

        let m = WidgetMatrixExport.margin
        var rows: [UIImage] = []
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        for spec in SpecCatalog.all {
            guard let kind = WidgetKind(rawValue: spec.kind) else { continue }
            var data = IOSSpecData(sample: true, widget: WidgetMatrixExport.fixedID)
            data.kitDark = spec.widget?.on == "dark"   // = ตัววาดจริง (`kit.dark` = ใบนั่งบนแผ่นเข้ม)
            var cells: [UIImage] = []
            var cases: [FixtureCase] = []
            for p in probes(for: spec) {
                // รูป — ผ่าน chrome จริง (สูตรเดียว + แผ่น + ขอบ)
                var w = WidgetMatrixExport.baseInstance(kind)
                w.x = m; w.y = m
                w.rect.size = p.size
                let cfg = WidgetMatrixExport.Config(
                    id: kind.rawValue, kind: kind.rawValue, group: "spec", label: p.name,
                    page: .init(w: Double(w.w + m * 2), h: Double(w.h + m * 2), strip: false),
                    theme: WidgetMatrixExport.baseTheme, item: WidgetMatrixExport.itemSnapshot(w))
                let cap = Capture(); capture = cap
                if let ui = WidgetMatrixExport.render(cfg, photos: photos, scale: 2, sample: true) {
                    cells.append(ui)
                    try? ui.pngData()?.write(to: dir.appending(path: "cell-\(kind.rawValue)-\(p.name).png"))
                }
                capture = nil
                if cap.hits > 0 { cases.append(cap.fixtureCase(p.name)); await Task.yield(); continue }
                // (ไม่ได้วาดผ่านผัง — สำรองด้วยตัวคำนวณตรง ๆ) fixture — กล่องรากตามสูตรเดียว แล้วให้ solver จัด
                let s = min(p.size.width / spec.design.w, p.size.height / spec.design.h)
                let inset = WidgetChrome.contentInset(kind: kind, surface: w.surface, border: w.border)
                let box = CGSize(width: p.size.width / s - inset * 2, height: p.size.height / s - inset * 2)
                let rec = RecordingMeasurer()
                let rdata = RecordingData(data)
                let solver = SpecSolver(spec: spec, box: box, data: rdata, measurer: rec, renderScale: s)
                let boxes = solver.solve()
                cases.append(FixtureCase(probe: p.name, box: [r2(box.width), r2(box.height)], boxes: boxes.map {
                    FixtureBox(id: $0.id, type: $0.node.type.rawValue,
                               x: r2($0.frame.minX), y: r2($0.frame.minY), w: r2($0.frame.width), h: r2($0.frame.height),
                               text: $0.text?.string, size: $0.text.map { r2($0.size) }, lines: $0.text?.lines, slot: $0.text?.slot)
                }, measures: rec.log, lineHeights: rec.lines, scale: Double(solver.scale), renderScale: Double(s), data: rdata.log))
                await Task.yield()
            }
            let base = WidgetMatrixExport.baseInstance(kind)
            let fx = Fixture(kind: spec.kind, design: [spec.design.w, spec.design.h],
                             inset: Double(WidgetChrome.contentInset(kind: kind, surface: base.surface, border: base.border)), cases: cases)
            if let d = try? enc.encode(fx) { try? d.write(to: dir.appending(path: "fixtures/\(spec.kind).json")) }
            rows.append(ShapeMatrixExport.compose(cells, title: spec.kind))
        }
        if !rows.isEmpty {
            try? ShapeMatrixExport.stack(rows).pngData()?.write(to: dir.appending(path: "sheet.png"))
        }
        print("[specs] wrote \(rows.count) kinds → \(dir.path)")
    }

    nonisolated static func r2(_ v: CGFloat) -> Double { (Double(v) * 100).rounded() / 100 }
}
#endif
