import SwiftUI
import UIKit

// MARK: - คู่สี

/// คู่สีสำเร็จ — "การ์ดใบนี้พิมพ์ด้วยหมึกสีอะไร บนกระดาษสีอะไร"
///
/// ต่างจาก `Palette` ตรงที่พาเลตต์ให้แค่ **เฉด** แล้วปล่อยให้สูตรของหมึกคิดพื้นกับตัวหนังสือต่อเอง
/// ผลคือพื้นได้สีของธีมจริง แต่ตัวหนังสือเป็นขาวหรือถ่านเสมอ — ปลอดภัยทุกใบ แต่ไม่มีวันได้หน้าตา
/// แบบโปสเตอร์ที่คนบันทึกเก็บไว้ ซึ่ง "ครีมบนกรมท่า" คือตัวงาน ไม่ใช่ฉากหลังของงาน
///
/// คู่สีจึงเป็นสีจริงสองสีที่ถูกเลือกมาคู่กัน **ไม่ผ่านสูตรไหนทั้งนั้น** — สีหนึ่งเป็นพื้น อีกสีเป็นหมึก
/// ทั้งตัวหนังสือ เส้น แผ่น และสีเน้นทั้งใบใช้สีหมึกตัวเดียวกันหมด การ์ดจึงอ่านเป็นงานสองสีจริง ๆ
///
/// สลับข้างได้ด้วยแถว "โทน" ที่มีอยู่แล้ว (มืด = สีเข้มเป็นพื้น · สว่าง = สีอ่อนเป็นพื้น)
/// ไม่มีปุ่มสลับเพิ่ม เพราะคำถามมันคือคำถามเดียวกับโทนอยู่แล้ว แค่คราวนี้คำตอบมีสีของมันเอง
struct ColorDuo: Identifiable, Equatable {
    let id: String
    /// ชื่อของสองสี — ใช้กับ VoiceOver และเวลาพูดถึงคู่นี้ในหน้าอื่น
    let darkName: String
    let lightName: String
    /// สองสีของคู่ · ฝั่งไหนขึ้นเป็นพื้นตัดสินที่ `CardTheme.duoFlipped`
    let dark: Color
    let light: Color

    /// คู่สีทั้งหมด — เรียงจากคู่ที่สุภาพที่สุดไปหาคู่ที่ดังที่สุด
    ///
    /// ไม่ได้สุ่มมาจากวงล้อสี ทุกคู่เป็นคู่ที่ใช้กันจริงในงานพิมพ์: เข้มจัดหนึ่งตัว อ่อนอุ่นหนึ่งตัว
    /// ค่าคอนทราสต์ของทุกคู่เกิน 7:1 ทั้งสองทิศ — สลับข้างแล้วยังอ่านออกเท่าเดิม
    static let all: [ColorDuo] = [
        ColorDuo(id: "indigo", darkName: "Midnight Indigo", lightName: "Vanilla Cream",
                 dark: .hex(0x282B4A), light: .hex(0xEEEBDA)),
        ColorDuo(id: "ink",    darkName: "Ink",             lightName: "Bone",
                 dark: .hex(0x14161A), light: .hex(0xF1EEE6)),
        ColorDuo(id: "field",  darkName: "Feldgrau",        lightName: "Wheat",
                 dark: .hex(0x3A4B41), light: .hex(0xE6CFA7)),
        ColorDuo(id: "cocoa",  darkName: "Chocolate",       lightName: "Sand",
                 dark: .hex(0x3E000C), light: .hex(0xFFECD1)),
        ColorDuo(id: "teal",   darkName: "Deep Teal",       lightName: "Peach",
                 dark: .hex(0x0E3B3E), light: .hex(0xF7CBA7)),
        ColorDuo(id: "plum",   darkName: "Plum",            lightName: "Lilac",
                 dark: .hex(0x2B1A47), light: .hex(0xE6D8FF)),
        ColorDuo(id: "merlot", darkName: "Merlot",          lightName: "Blush",
                 dark: .hex(0x4A1B2F), light: .hex(0xF6D9DE)),
        ColorDuo(id: "cordovan", darkName: "Cordovan",      lightName: "Old Lace",
                 dark: .hex(0x8C2F39), light: .hex(0xFFF6E7)),
        ColorDuo(id: "cobalt", darkName: "Cobalt",          lightName: "Butter",
                 dark: .hex(0x17307E), light: .hex(0xFFE08A)),
        ColorDuo(id: "clay",   darkName: "Terracotta",      lightName: "Oat",
                 dark: .hex(0x8E3620), light: .hex(0xF3E3D0)),
        ColorDuo(id: "acid",   darkName: "Charcoal",        lightName: "Acid",
                 dark: .hex(0x17181C), light: .hex(0xD8FF3E))
    ]

    static func find(_ id: String) -> ColorDuo? { all.first { $0.id == id } }
}

// MARK: - เครื่องมือสี

extension Color {
    /// สีจากเลขฐานสิบหกแบบ `0xRRGGBB` — คู่สีเก็บเป็นสีจริง ไม่ใช่ HSB
    /// เพราะค่าที่เลือกไว้แล้วห้ามขยับตามสูตรไหนอีก
    static func hex(_ v: UInt32) -> Color {
        Color(red: Double((v >> 16) & 0xFF) / 255,
              green: Double((v >> 8) & 0xFF) / 255,
              blue: Double(v & 0xFF) / 255)
    }

    /// ผสมไปหาอีกสีตามสัดส่วน 0…1 — ผสมใน sRGB ตรง ๆ
    ///
    /// ใช้กับระยะสั้น ๆ เท่านั้น (ปลายไล่เฉด · สีเน้นที่อ่อนลง) ซึ่งเป็นช่วงที่ตาแยกไม่ออกอยู่แล้ว
    /// ว่าผสมในปริภูมิไหน — และมันคือปริภูมิเดียวกับที่ `LinearGradient` ใช้ไล่ต่อจากตรงนั้น
    func mixed(with other: Color, by t: Double) -> Color {
        let k = min(1, max(0, t))
        let a = RGB(self), b = RGB(other)
        return Color(red: a.r + (b.r - a.r) * k,
                     green: a.g + (b.g - a.g) * k,
                     blue: a.b + (b.b - a.b) * k)
    }
}
