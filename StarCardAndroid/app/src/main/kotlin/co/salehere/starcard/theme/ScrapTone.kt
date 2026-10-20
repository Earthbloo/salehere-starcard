package co.salehere.starcard.theme

import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.graphics.Color
import kotlin.math.max
import kotlin.math.min

// MARK: - โทนของสำรับสแครปบุ๊ก (= `struct ScrapTone` ใน Views/Widgets/ScrapbookKit.swift — เฉพาะโทน ไม่รวมตัววาด)
//
// สีของแผ่นกับสีเน้นทั้งหมดมาจาก `ScrapTone` — เฉดจากสีเน้นของธีม · ความมืด/สว่างจากหมึกของการ์ด ·
// การ์ดคู่สีได้แค่สองสีของคู่ (ผู้ใช้ 1 ต.ค. 2569: "ต้องปรับโทนสีได้ตาม THEME โทนมืดโทนสว่าง")

/**
 * สีของสำรับที่ขึ้นกับธีม — **คิดครั้งเดียวต่อธีม** แล้วส่งลงทาง `LocalScrapTone`
 * ตั้งชื่อตาม *ที่ที่สีไปนั่ง*: `accent` คือเสียงชมพูบนแผ่น · `paperAccent` คือเสียงเดียวกันบนกระดาษขาวของวัตถุ
 */
class ScrapTone private constructor(
    /** แผ่นมืดไหม */
    val dark: Boolean,
    /** แผ่น · จุดเนื้อกระดาษ (สีกับความทึบ) */
    val paper: Color,
    val speck: Color,
    val speckAlpha: Double,
    /** ตัวหนังสือที่นั่งบนแผ่นตรง ๆ · ตัวรอง */
    val ink: Color,
    val soft: Color,
    /** เสียงที่สองบนแผ่น · ตัวเลขเด่นบนแผ่น */
    val accent: Color,
    val strong: Color,
    /** เสียงที่สอง · ตัวเลขเด่น — บนกระดาษขาวของวัตถุ (อ่านออกบนพื้นสว่างเสมอ) */
    val paperAccent: Color,
    val paperStrong: Color,
    /** แถบหัวข้อ · ชมพูกลางของป้าย/กล่อง · พื้นอ่อนในวัตถุ */
    val band: Color,
    val mid: Color,
    val blush: Color,
    /** เงาของของที่ลอยบนแผ่น — อาบเฉดของแผ่น */
    val shade: Color,
) {
    companion object {
        /** หมึกบนกระดาษของวัตถุ (= `Scrap.ink` ใน ScrapbookKit.swift) */
        private val scrapInk: Color = Color.hex(0x141414)

        /** = `init(_ theme: CardTheme)` ของ Swift */
        operator fun invoke(theme: CardTheme): ScrapTone {
            val duo = theme.duoColors
            if (duo != null) {
                // การ์ดคู่สี — สองสีของคู่เท่านั้น ใส่สีที่สามเมื่อไหร่งานสองสีพังตรงนั้น
                val bg = duo.bg; val fg = duo.ink
                val light = theme.duoLight ?: fg; val deep = theme.duoDark ?: bg
                return ScrapTone(
                    dark = RGB(bg).luminance < RGB(fg).luminance,
                    paper = bg.mixed(fg, 0.07),
                    speck = fg,
                    speckAlpha = 0.08,
                    ink = fg,
                    soft = fg.mixed(bg, 0.35),
                    accent = fg,
                    strong = fg,
                    paperAccent = deep,
                    paperStrong = deep,
                    band = light.mixed(deep, 0.18),
                    mid = light.mixed(deep, 0.32),
                    blush = light.mixed(deep, 0.08),
                    shade = deep,
                )
            }
            // เฉดจากสีเน้นของธีม · ความสดถ่วงตามสีเน้น (ธีมเทา ๆ ได้แผ่นเทา ๆ ไม่ใช่ชมพูหวาน)
            val hsbv = theme.rawAccent.toHSB()
            val h = hsbv.h
            val k = min(1.2, max(0.3, hsbv.s / 0.49))
            fun c(s: Double, v: Double): Color = hsb(h, min(1.0, s * k), v)

            val dark = !theme.activeInk.isLight
            val paperAccent = c(0.49, 0.86)
            val paperStrong = c(0.67, 0.76)
            val blush = c(0.10, 0.985)
            return if (dark) {
                // สว่างกว่าพื้นการ์ดกลางคืนหนึ่งขั้นเสมอ — มืดเท่ากันแล้วขอบแผ่นหายไปกับการ์ด
                ScrapTone(
                    dark = true,
                    paper = c(0.42, 0.31),
                    speck = Color.White,
                    speckAlpha = 0.06,
                    ink = hsb(h, 0.04, 0.98),
                    soft = c(0.16, 0.80),
                    accent = c(0.40, 0.98),
                    strong = c(0.45, 1.0),
                    paperAccent = paperAccent,
                    paperStrong = paperStrong,
                    band = c(0.30, 0.95),
                    mid = c(0.36, 0.88),
                    blush = blush,
                    shade = Color.Black,
                )
            } else {
                ScrapTone(
                    dark = false,
                    paper = c(0.16, 0.965),
                    speck = c(0.58, 0.75),
                    speckAlpha = 0.10,
                    ink = scrapInk,
                    soft = c(0.30, 0.48),
                    accent = c(0.49, 0.89),
                    strong = c(0.67, 0.79),
                    paperAccent = paperAccent,
                    paperStrong = paperStrong,
                    band = c(0.28, 0.96),
                    mid = c(0.33, 0.94),
                    blush = blush,
                    shade = c(0.71, 0.55),
                )
            }
        }

        /** ค่าตั้งต้นเมื่อไม่มีใครส่งโทนลงมา (พรีวิว) — โทนชมพูสว่างของต้นฉบับ */
        val fallback: ScrapTone by lazy { ScrapTone(CardTheme()) }
    }
}

/** โทนของสำรับสแครปบุ๊กที่กำลังวาด (= `\.scrapTone`) */
val LocalScrapTone = compositionLocalOf { ScrapTone.fallback }
