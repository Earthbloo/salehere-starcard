package co.salehere.starcard.theme

import androidx.compose.ui.graphics.Color

/// โทเคนสี Sale Here 2.0 — ยกมาจาก `SaleHere_2.0_Design_Guideline.md` ตรง ๆ ทุกค่า (= SHStyle.swift)
///
/// ใช้กับ **หน้าเครื่องมือฝั่งแอป** (คลังการ์ด · หน้าเลือกเทมเพลต) เท่านั้น —
/// **ห้ามใช้กับตัวการ์ดและห้องแต่ง** การ์ดมีธีมของตัวเอง (ดู `CardTheme`)
object SHColor {
    // แดงแบรนด์ — สี action หลัก หนึ่งเดียวของทั้งแอป
    /** #ED1C24 · Primary CTA · Active · Highlight */
    val red = Color(0xFFED1C24)
    /** #C81017 · Primary ตอนกด */
    val redPressed = Color(0xFFC81017)
    /** #FDE8E9 · พื้นแดงอ่อน — Badge เท่านั้น */
    val redSoft = Color(0xFFFDE8E9)
    /** เขียว "ลงทะเบียนแล้ว" / "ผูกบัญชีแล้ว" ของแอปหลัก */
    val green = Color(0xFF12B76A)
    val greenSoft = Color(0xFFE7F6EF)

    // ตัวหนังสือ
    /** #16181D · text-primary */
    val ink = Color(0xFF16181D)
    /** #232323 · ชื่อการ์ด/สินค้า */
    val inkTitle = Color(0xFF232323)
    /** #666666 · text-secondary */
    val textSecondary = Color(0xFF666666)
    /** #919191 · text-tertiary — metadata, placeholder */
    val textTertiary = Color(0xFF919191)
    /** #8A8A86 · แท็บที่ยังไม่ active */
    val tabInactive = Color(0xFF8A8A86)

    // พื้น
    /** #F7F8FA · bg-page */
    val page = Color(0xFFF7F8FA)
    /** #FFFFFF · bg-surface */
    val surface = Color.White
    /** #F5F5F5 · bg-soft */
    val soft = Color(0xFFF5F5F5)

    // เส้น
    /** #E9E9E9 · stroke-default */
    val stroke = Color(0xFFE9E9E9)
    /** #D9D9D9 · stroke-strong */
    val strokeStrong = Color(0xFFD9D9D9)

    // สถานะ
    /** #12B76A · success */
    val success = Color(0xFF12B76A)
    /** #F6B800 · Star Icon — สี "ใบหลัก/ติดดาว" บนพื้นมืด */
    val star = Color(0xFFF6B800)
}
