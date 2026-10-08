import Foundation

/// สถิติคนดู Star Card — **ข้อมูลจำลอง** ของต้นแบบ (ยังไม่มีระบบเก็บยอดดูจริงในทุก repo, ดู return-loop proposal 14 ก.ย. 2569)
///
/// ตอบ 3 คำถามของเจ้าของการ์ด เรียงเป็นกรวยเดียว (ผู้ใช้ 4 ต.ค. 2569): มีคนเห็นเท่าไหร่ → กดเข้ามาดูการ์ดเท่าไหร่ → เป็นแบรนด์สายไหน
/// ชื่อสายใช้ชุดเดียวกับ "สายที่ใช่" ของ Star Profile
struct StarInsight {
    enum Range: String, CaseIterable, Identifiable {
        case week = "7 วัน", month = "28 วัน"
        var id: String { rawValue }
    }

    struct Style: Identifiable {
        let name: String
        let brands: Int
        var id: String { name }
    }

    /// ยอดเห็นรายวัน (เก่า → ใหม่ · ตัวสุดท้าย = วันนี้)
    let daily: [Int]
    /// ช่วงก่อนหน้าที่ยาวเท่ากัน — ไว้คิด % ขึ้น/ลง
    let previousViews: Int
    /// กดเข้ามาเปิดดูการ์ด
    let opened: Int
    /// แบรนด์ (คนละราย) ที่เปิดดู แยกตามสาย — เรียงมากไปน้อย ตัวท้าย = "อื่น ๆ"
    let styles: [Style]
    /// ป้ายใต้กราฟ (ซ้าย → ขวา)
    let axis: [String]
    /// ชื่อวันของแต่ละจุด — ไว้อ่านค่าตอนลากนิ้วบนกราฟ
    let dayNames: [String]
    /// เหตุของวันที่ยอดสูงสุด (จากประวัติการแชร์การ์ด)
    let peakNote: String
    /// ของใหม่วันนี้ — เรื่องเดียวกับที่แจ้งเตือนบอก ("แบรนด์สายคาเฟ่ 3 รายดูการ์ดคุณ") แตะเข้ามาต้องเจอเรื่องนั้นก่อน
    var today: Style? = nil

    var views: Int { daily.reduce(0, +) }
    var change: Double { previousViews == 0 ? 0 : Double(views - previousViews) / Double(previousViews) }
    var openRate: Double { views == 0 ? 0 : Double(opened) / Double(views) }
    var brands: Int { styles.reduce(0) { $0 + $1.brands } }
    var peakIndex: Int { daily.indices.max { daily[$0] < daily[$1] } ?? 0 }
    var isEmpty: Bool { views == 0 }

    /// ยังไม่เคยมีคนเห็นเลยสักช่วง (ต่างจาก "ช่วงนี้ไม่มี" ที่ยังสลับไปดูช่วงอื่นได้)
    static var neverSeen: Bool { Range.allCases.allSatisfy { mock($0).isEmpty } }

    static func mock(_ r: Range) -> StarInsight {
        // ลองสถานะว่าง: `-insightEmpty YES` = ยังไม่เคยมีคนเห็น · `-insightEmpty week` = 7 วันล่าสุดเงียบ แต่ 28 วันมีข้อมูล
        let quiet = UserDefaults.standard.string(forKey: "insightEmpty") ?? ""
        if quiet == "YES" || (quiet == "week" && r == .week) { return .empty }
        switch r {
        case .week:
            return StarInsight(daily: week, previousViews: 3_322, opened: 1_284,
                               styles: [Style(name: "คาเฟ่", brands: 14), Style(name: "บิวตี้", brands: 9),
                                        Style(name: "แฟชั่น", brands: 6), Style(name: "อื่น ๆ", brands: 5)],
                               axis: ["จ", "อ", "พ", "พฤ", "ศ", "ส", "อา"],
                               dayNames: ["จันทร์", "อังคาร", "พุธ", "พฤหัสบดี", "ศุกร์", "เสาร์", "วันนี้"],
                               peakNote: "วันที่แชร์ลง IG Story",
                               today: Style(name: "คาเฟ่", brands: 3))
        case .month:
            let d = [352, 371, 398, 420, 388, 365, 342, 377, 402, 431, 455, 418, 392, 380,
                     405, 428, 462, 480, 441, 423, 430] + week
            // วันนี้ = อาทิตย์ 4 ต.ค. 2569 → จุดแรก = จันทร์ 7 ก.ย.
            let names = (0..<28).map { i -> String in
                if i == 27 { return "วันนี้" }
                let day = 7 + i
                return day <= 30 ? "\(day) ก.ย." : "\(day - 30) ต.ค."
            }
            return StarInsight(daily: d, previousViews: 10_400, opened: 3_870,
                               styles: [Style(name: "คาเฟ่", brands: 43), Style(name: "บิวตี้", brands: 31),
                                        Style(name: "แฟชั่น", brands: 22), Style(name: "อื่น ๆ", brands: 16)],
                               axis: ["7 ก.ย.", "21 ก.ย.", "วันนี้"],
                               dayNames: names,
                               peakNote: "วันที่แชร์ลง IG Story",
                               today: Style(name: "คาเฟ่", brands: 3))
        }
    }

    private static let week = [318, 362, 948, 622, 521, 468, 681]

    static let empty = StarInsight(daily: Array(repeating: 0, count: 7), previousViews: 0, opened: 0, styles: [],
                                   axis: [], dayNames: [], peakNote: "")

    static func fmt(_ n: Int) -> String { n.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US"))) }
}
