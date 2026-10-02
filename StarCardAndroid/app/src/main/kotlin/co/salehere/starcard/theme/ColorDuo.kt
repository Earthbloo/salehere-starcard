package co.salehere.starcard.theme

import androidx.compose.ui.graphics.Color

// MARK: - คู่สี (= Theme/ColorDuo.swift · `Color.hex` / `Color.mixed` อยู่ใน ColorTools.kt แล้ว)

/**
 * คู่สีสำเร็จ — "การ์ดใบนี้พิมพ์ด้วยหมึกสีอะไร บนกระดาษสีอะไร"
 * ต่างจาก `Palette` ตรงที่พาเลตต์ให้แค่เฉดแล้วปล่อยให้สูตรของหมึกคิดต่อ · คู่สีคือสีจริงสองสี **ไม่ผ่านสูตรไหนทั้งนั้น**
 * สลับข้างได้ด้วยแถว "โทน" ที่มีอยู่แล้ว (มืด = สีเข้มเป็นพื้น · สว่าง = สีอ่อนเป็นพื้น)
 */
data class ColorDuo(
    val id: String,
    /** ชื่อของสองสี — ใช้กับ TalkBack และเวลาพูดถึงคู่นี้ในหน้าอื่น */
    val darkName: String,
    val lightName: String,
    /** สองสีของคู่ · ฝั่งไหนขึ้นเป็นพื้นตัดสินที่ `CardTheme.duoFlipped` */
    val dark: Color,
    val light: Color,
) {
    companion object {
        /**
         * คู่สีทั้งหมด — เรียงจากคู่ที่สุภาพที่สุดไปหาคู่ที่ดังที่สุด
         * ทุกคู่เป็นคู่ที่ใช้กันจริงในงานพิมพ์ · contrast เกิน 7:1 ทั้งสองทิศ
         */
        val all: List<ColorDuo> = listOf(
            ColorDuo(id = "indigo", darkName = "Midnight Indigo", lightName = "Vanilla Cream",
                dark = Color.hex(0x282B4A), light = Color.hex(0xEEEBDA)),
            ColorDuo(id = "ink", darkName = "Ink", lightName = "Bone",
                dark = Color.hex(0x14161A), light = Color.hex(0xF1EEE6)),
            ColorDuo(id = "field", darkName = "Feldgrau", lightName = "Wheat",
                dark = Color.hex(0x3A4B41), light = Color.hex(0xE6CFA7)),
            ColorDuo(id = "cocoa", darkName = "Chocolate", lightName = "Sand",
                dark = Color.hex(0x3E000C), light = Color.hex(0xFFECD1)),
            ColorDuo(id = "teal", darkName = "Deep Teal", lightName = "Peach",
                dark = Color.hex(0x0E3B3E), light = Color.hex(0xF7CBA7)),
            ColorDuo(id = "plum", darkName = "Plum", lightName = "Lilac",
                dark = Color.hex(0x2B1A47), light = Color.hex(0xE6D8FF)),
            ColorDuo(id = "merlot", darkName = "Merlot", lightName = "Blush",
                dark = Color.hex(0x4A1B2F), light = Color.hex(0xF6D9DE)),
            ColorDuo(id = "cordovan", darkName = "Cordovan", lightName = "Old Lace",
                dark = Color.hex(0x8C2F39), light = Color.hex(0xFFF6E7)),
            ColorDuo(id = "cobalt", darkName = "Cobalt", lightName = "Butter",
                dark = Color.hex(0x17307E), light = Color.hex(0xFFE08A)),
            ColorDuo(id = "clay", darkName = "Terracotta", lightName = "Oat",
                dark = Color.hex(0x8E3620), light = Color.hex(0xF3E3D0)),
            ColorDuo(id = "acid", darkName = "Charcoal", lightName = "Acid",
                dark = Color.hex(0x17181C), light = Color.hex(0xD8FF3E)),
        )

        fun find(id: String): ColorDuo? = all.firstOrNull { it.id == id }
    }
}
