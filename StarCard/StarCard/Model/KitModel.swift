import SwiftUI
import UIKit

// MARK: - ชุดห้าสไตล์ (Canva DAHXOY1w-iM หน้า 3–12)
//
// สิบหัวข้อ × ห้าสไตล์ = **ห้าสิบชนิด** — หน้าตาเป็นของชนิด (`widget.kit.look` ในไฟล์ผัง) ไม่ใช่ค่าที่เก็บในชิ้น
// (ผู้ใช้ 19 ต.ค. 2569: "มองเป็น 5 widget ... เอาเป็นคนละ widget ไปเลย" — เดิมหนึ่งชนิดต่อหัวข้อแล้วเก็บ style ในชิ้น)
// สลับหน้าตา = สลับชนิดในหมวดเดียวกัน (`swap`) — ตัวเลือกเนื้อหา/พื้น/มุมในชิ้นติดไปด้วย
//
// เป็นชุดใหม่ในตู้ — ของเดิม 87 ชิ้นอยู่ครบ (ผู้ใช้ 12 ต.ค. 2569) และถาดแต่งแบบใหม่
// (พื้นหลัง สีพื้น/ไล่สี/โปร่ง · ขอบ · มุม · สีขอบ) ใช้กับชุดนี้เท่านั้น ใบเดิมยังใช้ "กล่อง/ขอบ" เหมือนเดิม
//
// ข้อมูลที่ Star Profile ไม่มี (อีเมล · ไซซ์เสื้อ · ยอดวิวผลงาน · แพ็กเกจราคา) ถูกตัดออกจากชุดนี้ทั้งหมด

/// ห้าสไตล์ — ชื่อตามหน้าตา (เลข model ใน Canva สลับกันในบางหน้า)
enum KitStyle: String, CaseIterable, Codable, Identifiable {
    case purple, cream, gingham, night, mac
    var id: String { rawValue }

    var name: String {
        switch self {
        case .purple:  return "ม่วงสติกเกอร์"
        case .cream:   return "ครีมนุ่ม"
        case .gingham: return "กรอบตาราง"
        case .night:   return "กลางคืน"
        case .mac:     return "หน้าต่าง Mac"
        }
    }

    /// สีพื้นตั้งต้นของสไตล์ (hex)
    var fill: String {
        switch self {
        case .purple:  return "#B57EF7"
        case .cream:   return "#ECE8E2"
        case .gingham: return "#C9D4A6"
        case .night:   return "#0B0F14"
        case .mac:     return "#FAFAFA"
        }
    }

    /// โทนที่สไตล์นี้ดึงจาก **พื้นหลังการ์ด** — สีพื้นของ widget ไม่มีให้เลือกในถาด (ผู้ใช้ 12 ต.ค. 2569)
    /// เปลี่ยนพื้นหลังการ์ดแล้ว widget ทุกตัวเปลี่ยนตาม · แต่ละสไตล์ยังแยกออกด้วยน้ำหนักของโทน
    var cardToken: String {
        switch self {
        case .purple:  return "accent"   // สติกเกอร์ = สีสดของการ์ด
        case .cream:   return "card+2"   // ครีม = การ์ดแบบอ่อนมาก
        case .gingham: return "card+1"   // ผ้ากรอบ = การ์ดแบบอ่อนกลาง
        case .night:   return "card-3"   // กลางคืน = การ์ดแบบเข้มจัด (การ์ดสว่างก็ยังเป็นแผ่นมืด)
        case .mac:     return "card+3"   // หน้าต่าง = การ์ดเกือบขาว
        }
    }

    /// โทนของ **ขอบ** ที่ดึงจากพื้นหลังการ์ด — ไม่มีปุ่มเลือกสีขอบ (ผู้ใช้ 12 ต.ค. 2569: "ห้ามเลือกสีพื้นหรือสีขอบ เอาสีจากพื้นหลังเท่านั้น")
    var borderToken: String {
        switch self {
        case .purple:  return "card-3"   // เส้นหนา + เงาเยื้อง = การ์ดเข้มจัด
        case .cream:   return "card-1"
        case .gingham: return "card-3"   // เส้นของการ์ดขาวด้านใน
        case .night:   return "accent"   // มุมนีออน + ตัวเลข = สีเน้นของการ์ด
        case .mac:     return "card+2"   // เส้นบางรอบหน้าต่าง (เข้มกว่าตัวหน้าต่างนิดเดียว)
        }
    }

    /// สีขอบเดิมตาม Canva — ใช้แค่ในพรีวิวที่ไม่มีธีม · การ์ดจริงใช้ `borderToken`
    var border: String {
        switch self {
        case .purple, .gingham: return "#141414"
        case .cream:   return "#2A2A2A"
        case .night:   return "#5AC8F0"
        case .mac:     return "#D4D4D8"
        }
    }

    /// มีขอบตั้งแต่หยิบออกจากตู้ — ครีมนุ่มใน Canva ไม่มีขอบ
    var bordered: Bool { self != .cream }

    /// รัศมีของ "มน" — "เหลี่ยม" เป็น 3pt ทุกสไตล์
    var radius: CGFloat {
        switch self {
        case .purple:  return 14
        case .cream:   return 20
        case .gingham: return 20
        case .night:   return 16
        case .mac:     return 12
        }
    }
}

/// พื้นหลัง — สามแบบตาม Canva หน้า 1
enum KitFill: String, CaseIterable, Codable {
    case solid, gradient, clear
    var name: String {
        switch self {
        case .solid:    return "ทึบ"
        case .gradient: return "ไล่สี"
        case .clear:    return "โปร่ง"
        }
    }
}

/// ทรงมุม — สองแบบเท่านั้น (Canva: ตัดการปรับองศาออกเพื่อความง่าย)
enum KitCorner: String, CaseIterable, Codable {
    case round, square
    var name: String { self == .round ? "มน" : "เหลี่ยม" }
}

/// หน้าตาและตัวเลือกเนื้อหาของชิ้นในชุดห้าสไตล์ — เก็บต่อชิ้น (วางสองใบแล้วแต่งคนละแบบได้)
///
/// เปิด/ปิดเส้นขอบใช้ `WidgetInstance.border` ตัวเดิม · ที่นี่เก็บเฉพาะของที่ชุดเดิมไม่มี
struct KitConfig: Codable, Equatable {
    /// หน้าตา — **มาจากชนิด** (`WidgetKind.kitStyle`) เติมตอนวาด (`looking(_:)`) · ไม่เขียนลงไฟล์
    /// ไฟล์ก่อน 19 ต.ค. 2569 ยังมีคีย์นี้ — อ่านไว้ให้ `CardStore.restore` เลือกชนิดใหม่ที่ตรงหน้าตาเดิม
    var style: KitStyle = .purple
    var fill: KitFill = .solid
    /// nil = สีพื้นตั้งต้นของสไตล์
    var fillHex: String? = nil
    var corner: KitCorner = .round
    /// nil = สีขอบตั้งต้นของสไตล์
    var borderHex: String? = nil
    /// ตัวเลือกเนื้อหาของหัวข้อ — คีย์ดูที่ `KitOpt`
    var opts: [String: String] = [:]

    var fillColor: String { fillHex ?? style.fill }
    /// สีพื้นที่ใช้วาดจริง — มาจากพื้นหลังการ์ดตามโทนของสไตล์เสมอ (`KitStyle.cardToken`)
    /// `fillHex` ที่ค้างในไฟล์รุ่นก่อนไม่ถูกใช้แล้ว — ไม่มีปุ่มให้แก้ จึงต้องไม่มีผล
    func fillColor(_ theme: CardTheme) -> String { KitColor.resolve(style.cardToken, theme) }
    /// ชุดเดียวกันที่สีพื้นถูกแปลงเป็น hex แล้ว — ส่งต่อให้ `KitLook`
    func resolved(_ theme: CardTheme) -> KitConfig {
        var c = self
        c.fillHex = fillColor(theme)
        // สีขอบก็มาจากพื้นหลังการ์ดเหมือนกัน — `borderHex` ในไฟล์รุ่นก่อนไม่ถูกใช้แล้ว
        c.borderHex = KitColor.resolve(style.borderToken, theme)
        return c
    }
    var borderColor: String { borderHex ?? style.border }

    // MARK: ตัวเลือกเนื้อหา

    func list(_ k: String) -> Set<String> {
        Set((opts[k] ?? "").split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }
    mutating func setList(_ k: String, _ v: Set<String>) {
        opts[k] = v.isEmpty ? nil : v.sorted().joined(separator: ",")
    }
    func flag(_ k: String, default d: Bool) -> Bool {
        opts[k].map { $0 == "1" } ?? d
    }
    func int(_ k: String, default d: Int) -> Int {
        opts[k].flatMap(Int.init) ?? d
    }

    /// ชุดเดียวกันในหน้าตาของชนิด `kind`
    func looking(_ kind: WidgetKind) -> KitConfig {
        var c = self
        c.style = kind.kitStyle
        return c
    }

    private enum CodingKeys: String, CodingKey { case style, fill, fillHex, corner, borderHex, opts }

    init(style: KitStyle = .purple, fill: KitFill = .solid, fillHex: String? = nil, corner: KitCorner = .round,
         borderHex: String? = nil, opts: [String: String] = [:]) {
        self.style = style; self.fill = fill; self.fillHex = fillHex; self.corner = corner
        self.borderHex = borderHex; self.opts = opts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        style = try c.decodeIfPresent(KitStyle.self, forKey: .style) ?? .purple
        fill = try c.decodeIfPresent(KitFill.self, forKey: .fill) ?? .solid
        fillHex = try c.decodeIfPresent(String.self, forKey: .fillHex)
        corner = try c.decodeIfPresent(KitCorner.self, forKey: .corner) ?? .round
        borderHex = try c.decodeIfPresent(String.self, forKey: .borderHex)
        opts = try c.decodeIfPresent([String: String].self, forKey: .opts) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(fill, forKey: .fill)
        try c.encodeIfPresent(fillHex, forKey: .fillHex)
        try c.encode(corner, forKey: .corner)
        try c.encodeIfPresent(borderHex, forKey: .borderHex)
        try c.encode(opts, forKey: .opts)
    }
}

/// คีย์ของตัวเลือกเนื้อหา — ชุด "hide" เก็บของที่ **ซ่อน** ไม่ใช่ของที่โชว์
/// ช่องทาง/สายงานที่เพิ่มทีหลังใน Star Profile จึงขึ้นการ์ดเอง ไม่ต้องกลับมาติ๊ก
enum KitOpt {
    static let hide = "hide"
    static let mode = "mode"
    static let count = "count"
    static let caption = "cap"
    static let qr = "qr"
}

// MARK: - สีจาก hex

extension Color {
    /// "#RRGGBB" → Color · ค่าผิดรูปแบบได้เทา (ไม่ใช่ crash)
    init(kitHex hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let n = UInt64(s, radix: 16) ?? 0x888888
        self.init(red: Double((n >> 16) & 0xFF) / 255,
                  green: Double((n >> 8) & 0xFF) / 255,
                  blue: Double(n & 0xFF) / 255)
    }
}

enum KitColor {
    /// ความสว่างที่ตารับรู้ 0…1 — ใช้ตัดสินว่าพื้นนี้ต้องใช้หมึกขาวหรือดำ
    static func lum(_ hex: String) -> Double {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let n = UInt64(s, radix: 16) ?? 0x888888
        let r = Double((n >> 16) & 0xFF), g = Double((n >> 8) & 0xFF), b = Double(n & 0xFF)
        return (0.299 * r + 0.587 * g + 0.114 * b) / 255
    }
    static func dark(_ hex: String) -> Bool { lum(hex) < 0.45 }

    /// ผสมสีไปทางขาว (t > 0) หรือดำ (t < 0)
    static func shade(_ hex: String, _ t: Double) -> Color {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let n = UInt64(s, radix: 16) ?? 0x888888
        let c = [Double((n >> 16) & 0xFF), Double((n >> 8) & 0xFF), Double(n & 0xFF)].map { $0 / 255 }
        let to: Double = t >= 0 ? 1 : 0
        let k = abs(t)
        let m = c.map { $0 + (to - $0) * k }
        return Color(red: m[0], green: m[1], blue: m[2])
    }

    /// สีพื้นที่ให้เลือกในถาด — **มาจากพื้นหลังการ์ด** ไม่ใช่ชุดสีตายตัว (ผู้ใช้ 12 ต.ค. 2569)
    ///
    /// เก็บเป็น *โทเคน* ("card", "card+1" …) ไม่ใช่ hex — เปลี่ยนพื้นหลังการ์ดทีหลัง widget เปลี่ยนตามเอง
    /// ลำดับ: สีพื้นการ์ด · อ่อนลงสองขั้น · เข้มขึ้นสองขั้น · สีล่างของไล่สี · สีเน้น · คู่สี (ถ้ามี)
    static func cardFills(_ theme: CardTheme) -> [String] {
        var out = ["card", "card+1", "card+2", "card-1", "card-2", "card2", "accent"]
        if theme.activeDuo != nil { out += ["duoDark", "duoLight"] }
        // ตัดตัวที่ได้สีซ้ำกัน (การ์ดสีเดียวไม่มีไล่สี · สีเน้นตรงกับพื้น)
        var seen = Set<String>()
        return out.filter { seen.insert(resolve($0, theme).uppercased()).inserted }
    }

    /// โทเคน → hex ตามธีมของการ์ดตอนนี้ · hex ตรง ๆ (ไฟล์เก่า) ผ่านไปเหมือนเดิม
    static func resolve(_ token: String, _ theme: CardTheme) -> String {
        if token.hasPrefix("#") { return token }
        let card = hex(theme.backdropColors.top)
        switch token {
        case "card":     return card
        case "card+1":   return hex(shade(card, 0.35))
        case "card+2":   return hex(shade(card, 0.72))
        case "card+3":   return hex(shade(card, 0.92))
        case "card-1":   return hex(shade(card, -0.35))
        case "card-2":   return hex(shade(card, -0.62))
        case "card-3":   return hex(shade(card, -0.84))
        case "card2":    return hex(theme.backdropColors.bottom)
        case "accent":   return hex(theme.rawAccent)
        case "duoDark":  return theme.duoDark.map(hex) ?? card
        case "duoLight": return theme.duoLight.map(hex) ?? card
        default:         return card
        }
    }

    static func hex(_ c: Color) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(c).getRed(&r, green: &g, blue: &b, alpha: &a)
        func n(_ v: CGFloat) -> Int { Int(round(max(0, min(1, v)) * 255)) }
        return String(format: "#%02X%02X%02X", n(r), n(g), n(b))
    }
    /// สีขอบที่ให้เลือก
    static let borders = ["#141414", "#FFFFFF", "#5AC8F0", "#E5322D", "#D4D4D8", "#B57EF7"]
}

// MARK: - ส่งลงไปทาง environment

private struct KitConfigKey: EnvironmentKey {
    static let defaultValue = KitConfig()
}

extension EnvironmentValues {
    /// หน้าตาของชิ้นในชุดห้าสไตล์ที่กำลังวาด — ตั้งที่ `WidgetChrome`
    var kitConfig: KitConfig {
        get { self[KitConfigKey.self] }
        set { self[KitConfigKey.self] = newValue }
    }
    /// true เฉพาะตอน `KitMeasure` วัดความสูงตั้งต้น — รูปโปรไฟล์ขอขนาดตามความกว้าง (ไม่ใช่ค่าคงที่)
    /// ตอนวาดจริงยังรายงานขนาดอ้างอิงเดิม ไม่งั้นใบที่วางไว้แล้วจะถูกย่อทั้งก้อน (ViewThatFits เทียบกับขนาดอ้างอิง)
    var kitMeasuring: Bool {
        get { self[KitMeasuringKey.self] }
        set { self[KitMeasuringKey.self] = newValue }
    }
}

private struct KitMeasuringKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    /// กรอบแนวนอน (กว้างเกินสูงชัด ๆ) — ผลงานเรียง 3 คอลัมน์แถวเดียวแทน 2 คอลัมน์หลายแถว
    var kitWide: Bool {
        get { self[KitWideKey.self] }
        set { self[KitWideKey.self] = newValue }
    }
}
private struct KitWideKey: EnvironmentKey { static let defaultValue = false }

// MARK: - ชนิดในชุด

extension WidgetKind {
    /// ชุดห้าสไตล์ (`widget.kit`) — เช็คทีเดียวแทนไล่ทุก switch
    var isKit: Bool { meta.kit != nil }

    /// หน้าตาของใบ (`widget.kit.look`) — ไม่ใส่ = ม่วง
    var kitStyle: KitStyle { meta.kit?.look.flatMap(KitStyle.init(rawValue:)) ?? .purple }

    /// หัวข้อตั้งต้นตาม Canva = ชื่อในตู้ — ผู้ใช้แตะแก้ได้ (เก็บต่อชิ้นที่ `.note` ช่อง 1)
    var kitTitle: String? { isKit ? title : nil }

}
