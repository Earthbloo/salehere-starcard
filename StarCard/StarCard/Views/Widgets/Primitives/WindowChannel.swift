// ชิ้นส่วนกลางที่ตัววาดผัง (SpecPainter) และหน้าจออื่นเรียกใช้ — ไม่ผูกกับ widget ตัวใด
import SwiftUI
import PhosphorSwift


private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}


// MARK: - ช่องที่เลือกโชว์

extension SocialType {
    /// ชื่อบนหน้าต่าง — ชื่อเต็มของแพลตฟอร์ม ("Instagram" ไม่ใช่ "IG") ยกเว้น X ที่วงเล็บยาวเกินบรรทัด
    var windowName: String { self == .x ? "X" : name }

    /// โลโก้ **เปลือย** สำหรับวางบนพื้นเรียบ — ต้นฉบับวางโน้ต TikTok ตัวเปล่า ไม่มีวงกลมรอง
    ///
    /// มีเฉพาะช่องที่โลโก้จริงไม่ใช่วงกลม (TikTok · X · YouTube) · ที่เหลือ (IG · Facebook · Lemon8)
    /// ตราวงกลมของแอปคือหน้าตาที่คนจำได้อยู่แล้ว จึงใช้ตัวเดิม (`badge == true` ย่อลงนิดหน่อย
    /// เพราะวงกลมทึบหนักตากว่าโลโก้เส้นที่ขนาดเท่ากัน)
    func glyph(night: Bool) -> (name: String, badge: Bool) {
        switch self {
        case .tiktok:  return (night ? "glyph-tiktok-night" : "glyph-tiktok", false)
        case .x:       return (night ? "glyph-x-night" : "glyph-x", false)
        case .youtube: return ("glyph-youtube", false)
        default:       return (icon, true)
        }
    }
}
