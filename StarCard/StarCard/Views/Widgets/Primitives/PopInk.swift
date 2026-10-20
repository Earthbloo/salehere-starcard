// ชิ้นส่วนกลางที่ตัววาดผัง (SpecPainter) และหน้าจออื่นเรียกใช้ — ไม่ผูกกับ widget ตัวใด
import SwiftUI


// MARK: - สำรับ "แผ่นสติกเกอร์"
//
// แปลงตรงจากไฟล์ดีไซน์ `template STAR CARD_1.svg` (กระดาษเทป) และ `_2.svg` (กระจกชมพู)
// ทั้งสองไฟล์คือ **ผังเดียวกัน 8 กล่อง** ต่างกันแค่วัสดุ — วิวจึงมี 8 ตัวเหมือนเดิม
// แต่ `WidgetKind` มี 16 ตัว (แปดหน้าที่ × สองวัสดุ) แล้วส่งวัสดุลงมาทาง `\.popSkin`
//
// เดิมวัสดุอ่านจากมุมของธีม ผลคือตู้วิดเจ็ตโชว์ได้ทีละวัสดุ แล้วอีกแบบหนึ่งหยิบไม่ได้เลย
// ตอนนี้วัสดุเป็นของชนิด — ตู้จึงวางฝาแฝดสองใบให้เลือกข้างกัน และคละวัสดุในการ์ดเดียวได้
//
// กติกาที่ยกมาจากสำรับ Gen Z:
// 1. **หนึ่งสกิน หนึ่งวัสดุ** — กระจก = กล่องขาวมุมมน เงานุ่ม ป้ายเม็ดยาชมพู ·
//    กระดาษ = กล่องขาวมุมเหลี่ยม เงาแข็ง ป้ายดำเอียง เทปกาว รูเจาะสมุด
// 2. **หมึกคงที่ ไม่พลิกตามหมึกการ์ด** — ตัวหนังสือบนกล่องขาวเป็นถ่านเสมอ
//    (เหตุผลเดียวกับกระดาษโน้ต: ฉลากที่พลิกเป็นขาวตามการ์ดไม่ใช่ฉลากอีกต่อไป)
// 3. สีชมพูของป้าย/ขอบ/ราคา = `theme.rawAccent` — เปลี่ยนพาเลตต์แล้วทั้งแผ่นเปลี่ยนตาม

enum Pop {
    typealias Skin = PopSkin

    /// **ค่าสำรองเท่านั้น** — วัสดุจริงมาจากชนิดของ widget (`WidgetKind.popSkin`) ทาง `\.popSkin`
    /// ตัวนี้เหลือไว้ให้พรีวิวที่วาดวิวตรง ๆ โดยไม่ผ่าน `WidgetBody` ยังได้หน้าตาที่เข้ากับธีม
    static func skin(_ t: CardTheme) -> Skin { t.corner == .soft ? .paper : .glass }

    /// ถ่านอมม่วง — ดำสนิทบนกล่องขาวชมพูอ่านแข็งเกินไป
    static let ink = Color(red: 0.11, green: 0.10, blue: 0.13)
    static let inkSoft = Color(red: 0.40, green: 0.37, blue: 0.43)
    static let paper = Color.white
    /// เส้นคั่นบนกระดาษ
    static let rule = Color(red: 0.84, green: 0.82, blue: 0.85)

    /// สีชมพูของแผ่น — สีเน้นดิบของธีม (ไม่ผ่านสูตรหมึก เพราะวางบนกล่องขาวของตัวเอง)
    static func pink(_ t: CardTheme) -> Color { t.rawAccent }
    static func pinkSoft(_ t: CardTheme) -> Color { t.rawAccentSoft }

    /// พื้นของแผ่นตามพื้นผิวที่ผู้ใช้เลือก (แผงกล่องเหลือสองแบบ: กระจก · เข้ม)
    ///
    /// สำรับนี้ต่างจากที่อื่นตรง **ตัวหนังสือเป็นถ่านคงที่** (ฉลากบนกล่องขาวไม่พลิกตามการ์ด)
    /// แผ่นของมันจึงพลิกเป็นถ่านทึบไม่ได้ — "เข้ม" ที่นี่จึงแปลว่า **ทึบ**: กล่องกระดาษที่ไม่มีอะไรทะลุ
    /// ส่วนกระจกคือ ~62% ที่เห็นกริดพื้นหลังทะลุตามไฟล์ดีไซน์ ความต่างที่ตาเห็นคือ "โปร่ง" กับ "ทึบ"
    static func sheetFill(_ s: WidgetSurface, skin: Skin, theme: CardTheme) -> Color {
        switch s {
        case .glass: return paper.opacity(skin == .glass ? 0.62 : 0.9)
        // สำรับนี้ไม่ให้เลือก "ไม่มีพื้น" (ดู `WidgetKind.surfaceOptions`) — ไฟล์เก่าที่เคยเก็บค่านั้น
        // ไว้ตกมาเป็นกล่องทึบ ไม่ใช่กล่องหาย
        case .dim, .clear, .pane: return paper
        }
    }
    static func sheetShadow(_ s: WidgetSurface, skin: Skin, theme: CardTheme) -> Color {
        skin == .glass ? pink(theme).opacity(0.35) : Color.black.opacity(0.22)
    }

    /// ความสูงของป้ายหัวข้อ — ครึ่งหนึ่งโผล่พ้นขอบบนของกล่อง
    static let labelHeight: CGFloat = 26
    /// ป้ายทรงแท็บกว้างของสามกล่องแถวล่าง
    static let labelHeightWide: CGFloat = 30

    /// ไอคอนประจำสายงาน — ป้ายในลิสต์ต้องมีรูปนำทุกบรรทัด
    static func nicheIcon(_ t: String) -> String {
        let s = t.lowercased()
        if s.contains("บิวตี้") || s.contains("สกินแคร์") || s.contains("เมคอัพ") || s.contains("beauty") {
            return "cylinder.split.1x2.fill"
        }
        if s.contains("ไลฟ์") || s.contains("life") { return "bubble.left.and.bubble.right.fill" }
        if s.contains("ออกกำลัง") || s.contains("ฟิต") || s.contains("fit") || s.contains("กีฬา") { return "dumbbell.fill" }
        if s.contains("คาเฟ่") || s.contains("cafe") || s.contains("กาแฟ") { return "house.fill" }
        if s.contains("อาหาร") || s.contains("food") { return "fork.knife" }
        if s.contains("แฟชั่น") || s.contains("fashion") { return "tshirt.fill" }
        if s.contains("ท่องเที่ยว") || s.contains("travel") { return "airplane" }
        if s.contains("แม่") || s.contains("เด็ก") { return "figure.and.child.holdinghands" }
        if s.contains("เกม") || s.contains("game") { return "gamecontroller.fill" }
        return "tag.fill"
    }
}
