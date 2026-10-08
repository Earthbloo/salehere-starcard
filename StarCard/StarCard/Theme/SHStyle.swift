import SwiftUI

/// โทเคนสี Sale Here 2.0 — ยกมาจาก `SaleHere_2.0_Design_Guideline.md` ตรง ๆ ทุกค่า
///
/// # ขอบเขตการใช้
///
/// ใช้กับ **หน้าเครื่องมือฝั่งแอป** (คลังการ์ด · หน้าเลือกเทมเพลต) ให้หน้าตาเป็นเนื้อเดียว
/// กับแอป Sale Here หลักที่ StarCard จะไปเสียบอยู่ — พื้นสว่าง การ์ดขาว แดงเป็นสี action เดียว
///
/// **ห้ามใช้กับตัวการ์ดและห้องแต่ง** — การ์ดคือชิ้นงานของครีเอเตอร์ มีธีมของตัวเอง
/// และห้องแต่งเป็นสตูดิโอพื้นมืดโดยเจตนา (แคนวาสเด่นบนจอเข้ม แบบเดียวกับ Figma)
enum SHColor {
    // MARK: แดงแบรนด์ — สี action หลัก หนึ่งเดียวของทั้งแอป
    /// #ED1C24 · Primary CTA · Active · Highlight
    static let red = Color(red: 237 / 255, green: 28 / 255, blue: 36 / 255)
    /// #C81017 · Primary ตอนกด
    static let redPressed = Color(red: 200 / 255, green: 16 / 255, blue: 23 / 255)
    /// #FDE8E9 · พื้นแดงอ่อน — ใช้ได้กับ Badge เท่านั้น (สเปก 2.0 เลิกใช้กับปุ่มมี text)
    static let redSoft = Color(red: 253 / 255, green: 232 / 255, blue: 233 / 255)
    /// เขียว "ลงทะเบียนแล้ว" / "ผูกบัญชีแล้ว" ของแอปหลัก
    static let green = Color(red: 18 / 255, green: 183 / 255, blue: 106 / 255)
    static let greenSoft = Color(red: 231 / 255, green: 246 / 255, blue: 239 / 255)
    /// ส้ม "รอพิจารณา" ของแอปหลัก (การ์ดสถานะ waiting_approve ใน VerifyUserStatusView)
    static let orange = Color(red: 245 / 255, green: 140 / 255, blue: 22 / 255)
    static let orangeSoft = Color(red: 255 / 255, green: 243 / 255, blue: 229 / 255)

    // MARK: ตัวหนังสือ
    /// #16181D · text-primary
    static let ink = Color(red: 22 / 255, green: 24 / 255, blue: 29 / 255)
    /// #232323 · ชื่อการ์ด/สินค้า
    static let inkTitle = Color(red: 35 / 255, green: 35 / 255, blue: 35 / 255)
    /// #666666 · text-secondary
    static let textSecondary = Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255)
    /// #919191 · text-tertiary — metadata, placeholder
    static let textTertiary = Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255)
    /// #8A8A86 · แท็บที่ยังไม่ active
    static let tabInactive = Color(red: 138 / 255, green: 138 / 255, blue: 134 / 255)

    // MARK: พื้น
    /// #F7F8FA · bg-page
    static let page = Color(red: 247 / 255, green: 248 / 255, blue: 250 / 255)
    /// #FFFFFF · bg-surface — การ์ด/แผง
    static let surface = Color.white
    /// #F5F5F5 · bg-soft — บล็อกเบา ๆ (เช่นแถวลิงก์)
    static let soft = Color(red: 245 / 255, green: 245 / 255, blue: 245 / 255)

    // MARK: เส้น
    /// #E9E9E9 · stroke-default — ขอบการ์ด/ตัวคั่น
    static let stroke = Color(red: 233 / 255, green: 233 / 255, blue: 233 / 255)
    /// #D9D9D9 · stroke-strong
    static let strokeStrong = Color(red: 217 / 255, green: 217 / 255, blue: 217 / 255)

    // MARK: สถานะ
    /// #12B76A · success
    static let success = Color(red: 18 / 255, green: 183 / 255, blue: 106 / 255)
    /// #F6B800 · Star Icon (สเปก §9/§11) — ใช้เป็นสี "ใบหลัก/ติดดาว" บนพื้นมืด
    /// แดงสดบนดำอ่านเป็น error จึงยกหน้าที่บอกสถานะให้ทองดาวแทน — แดงเหลือไว้ที่ปุ่ม action เดียว
    static let star = Color(red: 246 / 255, green: 184 / 255, blue: 0)
}
