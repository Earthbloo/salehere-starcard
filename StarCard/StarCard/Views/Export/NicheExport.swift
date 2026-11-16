#if DEBUG
import SwiftUI
import UIKit

// MARK: - ทุกใบหมวดสายงาน × ชุดสายงานทดสอบ × ตัวเลือก "สายที่แสดง"
//
// เปิดแอปด้วย `-exportNiche` → `Documents/Niche/<kind>__<case>.png` + cases.txt + done.txt
// ชุดสายงานครอบหมวดทางการครบ 18 ชื่อ (ชื่อสั้นแบบที่ขึ้นการ์ด) · 1–5 สาย (สูงสุดของฟอร์ม) · ซ่อนบางสายผ่าน `options.hide`
@MainActor
enum NicheExport {
    static let cases: [(name: String, cats: [String], hide: [String])] = [
        ("1cat", ["แม่และเด็ก"], []),
        ("2cat", ["เทคโนโลยี", "การศึกษา"], []),
        ("3cat", ["สัตว์เลี้ยง", "กีฬา", "การศึกษา"], []),
        ("5a", ["บิวตี้", "แฟชั่น", "อาหาร", "คาเฟ่", "ไลฟ์สไตล์"], []),
        ("5b", ["ท่องเที่ยว", "สุขภาพ", "แม่และเด็ก", "สัตว์เลี้ยง", "เทคโนโลยี"], []),
        ("5c", ["เกม", "บ้าน", "รถยนต์", "การเงิน", "การศึกษา"], []),
        ("5d", ["กีฬา", "บันเทิง", "อีเวนต์", "แม่และเด็ก", "เทคโนโลยี"], []),
        ("hide1st", ["บิวตี้", "แฟชั่น", "อาหาร", "คาเฟ่", "ไลฟ์สไตล์"], ["บิวตี้"]),
        ("hideMid2", ["บิวตี้", "แฟชั่น", "อาหาร", "คาเฟ่", "ไลฟ์สไตล์"], ["อาหาร", "คาเฟ่"]),
        ("hideTo2", ["บิวตี้", "แฟชั่น", "อาหาร", "คาเฟ่", "ไลฟ์สไตล์"], ["บิวตี้", "อาหาร", "ไลฟ์สไตล์"]),
    ]

    static func run(photos: PhotoStore) async {
        PhotoStore.exportPerson = ProcessInfo.processInfo.arguments.contains("-exportPerson")
        let fm = FileManager.default
        let dir = URL.documentsDirectory.appending(path: "Niche")
        try? fm.removeItem(at: dir)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        await withTaskGroup(of: Void.self) { g in
            for u in Set((0..<PhotoLib.count).map { PhotoLib.url($0) }) { g.addTask { _ = await ImageCache.shared.load(u) } }
        }
        let kinds = WidgetKind.allCases.filter { SpecCatalog.spec(for: $0)?.widget?.category == "tags" }
        var log = "kinds: \(kinds.map(\.rawValue).joined(separator: ","))\n"
        let m = WidgetMatrixExport.margin
        for c in cases {
            Profile.me.debugSetCategories(c.cats)
            log += "\(c.name): cats=\(c.cats.joined(separator: "|")) hide=\(c.hide.joined(separator: "|"))\n"
            for kind in kinds {
                var w = WidgetMatrixExport.baseInstance(kind)
                w.x = m; w.y = m
                if !c.hide.isEmpty { w.options[KitOpt.hide] = c.hide.sorted().joined(separator: ",") }
                // ถาดโชว์แถวไหม (ต้องมี ≥ minItems สาย) — จดไว้ให้ตรวจ
                let ctl = kind.controls.first { $0.opt == KitOpt.hide && $0.label == "สายที่แสดง" }
                if c.name == "1cat" || c.name == "2cat" {
                    log += "  tray \(kind.rawValue): \(ctl == nil ? "NO ROW" : (c.cats.count >= (ctl?.minItems ?? 0) ? "row" : "hidden(<min)"))\n"
                }
                let cfg = WidgetMatrixExport.Config(
                    id: kind.rawValue, kind: kind.rawValue, group: "niche", label: c.name,
                    page: .init(w: Double(w.w + m * 2), h: Double(w.h + m * 2), strip: false),
                    theme: WidgetMatrixExport.baseTheme, item: WidgetMatrixExport.itemSnapshot(w))
                if let ui = WidgetMatrixExport.render(cfg, photos: photos, scale: 2, sample: false) {
                    try? ui.pngData()?.write(to: dir.appending(path: "\(kind.rawValue)__\(c.name).png"))
                }
                await Task.yield()
            }
        }
        // env NICHE_GROW=kind,kind: ใบเดิมตอนผู้ใช้ลากขยาย (กว้าง × สูง) — 5 สายชื่อยาว
        if let grow = ProcessInfo.processInfo.environment["NICHE_GROW"] {
            let sizes: [(String, CGFloat, CGFloat)] = [("1x1", 1, 1), ("1x1.3", 1, 1.3), ("1x1.6", 1, 1.6), ("1x2", 1, 2), ("0.8x1.3", 0.8, 1.3)]
            for name in grow.split(separator: ",").map(String.init) {
                guard let kind = WidgetKind(rawValue: name) else { continue }
                for c in cases where c.name == "5b" || c.name == "5a" {
                    Profile.me.debugSetCategories(c.cats)
                    for (sn, fw, fh) in sizes {
                        var w = WidgetMatrixExport.baseInstance(kind)
                        w.x = m; w.y = m
                        w.w = (w.w * fw).rounded(); w.h = (w.h * fh).rounded()
                        log += "grow \(name) \(c.name) \(sn): \(Int(w.w))×\(Int(w.h))\n"
                        let cfg = WidgetMatrixExport.Config(
                            id: name, kind: name, group: "niche", label: sn,
                            page: .init(w: Double(w.w + m * 2), h: Double(w.h + m * 2), strip: false),
                            theme: WidgetMatrixExport.baseTheme, item: WidgetMatrixExport.itemSnapshot(w))
                        if let ui = WidgetMatrixExport.render(cfg, photos: photos, scale: 2, sample: false) {
                            try? ui.pngData()?.write(to: dir.appending(path: "grow-\(name)__\(c.name)__\(sn).png"))
                        }
                        await Task.yield()
                    }
                }
            }
        }
        Profile.me.debugSetCategories(nil)
        try? log.write(to: dir.appending(path: "cases.txt"), atomically: true, encoding: .utf8)
        try? "done".write(to: dir.appending(path: "done.txt"), atomically: true, encoding: .utf8)
        print("[niche] wrote → \(dir.path)")
    }
}
#endif
