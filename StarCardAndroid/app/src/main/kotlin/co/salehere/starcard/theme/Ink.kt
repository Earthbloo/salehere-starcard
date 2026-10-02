package co.salehere.starcard.theme

import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.graphics.Color
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

// MARK: - หมึกของการ์ด (= ส่วนต้นของ CardTheme.swift: `CardInk` · `InkStyle` · `cardInk` environment)

/**
 * พื้นผิวของการ์ด — "การ์ดใบนี้เขียนด้วยหมึกอะไรบนกระดาษอะไร"
 * ไม่ผูกกับ dark mode ของเครื่องผู้ดู — เป็นการตัดสินใจของเจ้าของการ์ด
 */
enum class CardInk(val raw: String, val displayName: String, val icon: String) {
    /** เวทีมืด — รูปคือแหล่งกำเนิดแสง */
    night("night", "กลางคืน", "moon.stars.fill"),
    /** กระดาษขาวนวล เป็นกลาง */
    paper("paper", "กระดาษ", "doc.plaintext.fill"),
    /** กระดาษที่อาบสีธีมบาง ๆ — โทน "ใสใส" */
    mist("mist", "ใสใส", "drop.fill");

    val isLight: Boolean get() = this != night

    companion object {
        fun from(raw: String?): CardInk? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * ชุดสีที่ใช้ "บนพื้นการ์ด" — ตัวหนังสือที่วางบน **รูป** ต้องเป็นสีขาวเสมอทุกหมึก (มี scrim ดำรอง)
 * ขาวบนดำกับดำบนขาวไม่ได้ให้น้ำหนักเท่ากันที่ค่า alpha เดียวกัน — ทุกฟังก์ชันจึงมีเส้นโค้งของตัวเอง
 */
data class InkStyle(
    val ink: CardInk,
    /** สีหมึก — ฝั่งสว่างเป็นถ่านที่อาบเฉดของธีม ไม่ใช่ดำสนิท */
    val base: Color,
    /** พื้นใต้ตัวหนังสือ — ตัวหนังสือทุกระดับถูกยันให้อ่านออกบนพื้นช่วงนี้ (ดู `text`) */
    val ground: InkGround = InkGround.stage,
) {
    /** ความสว่างของหมึกเต็มแรง — คิดครั้งเดียวตอนสร้าง */
    private val baseLuminance: Double = RGB(base).luminance

    val isLight: Boolean get() = ink.isLight

    /**
     * ตัวหนังสือ — `l` คือน้ำหนักชุดเดียวกับที่เคยเขียน `.white.opacity(l)`
     * ความทึบที่ออกแบบไว้คือขั้นต่ำของหน้าตา: บนพื้นกลาง ๆ ถูกดันขึ้นจนได้เกณฑ์ของระดับนั้น
     */
    fun text(l: Double): Color {
        val designed = if (isLight) min(0.94, max(0.0, l).pow(0.85)) else l
        val needed = Legibility.alpha(baseLuminance, if (isLight) ground.lo else ground.hi, Legibility.target(l))
        return base.opacity(min(1.0, max(designed, needed)))
    }
    fun text(l: Float): Color = text(l.toDouble())

    /** หมึกชุดเดียวกันบนแผ่นของ widget — แผ่นเปลี่ยนพื้นใต้ตัวหนังสือ */
    fun covered(panel: Double, alpha: Double): InkStyle = copy(ground = ground.covered(panel, alpha))

    /** แผ่นที่ย้อมด้วยหมึกของการ์ดเอง (แผ่นเข้มบนกระดาษ) */
    fun coveredByInk(alpha: Double): InkStyle = covered(baseLuminance, alpha)

    /** ตัวอักษร/สัญลักษณ์ที่ตั้งใจให้เป็นเงา — พื้นสว่างต้องจางกว่าพื้นมืดมาก */
    fun ghost(l: Double): Color = if (!isLight) base.opacity(l) else base.opacity(l * 0.5)
    fun ghost(l: Float): Color = ghost(l.toDouble())

    /** เส้นผม · ขอบ */
    fun line(l: Double): Color = if (!isLight) base.opacity(l) else base.opacity(min(0.6, l * 0.8))
    fun line(l: Float): Color = line(l.toDouble())

    /** พื้นแผ่นบาง ๆ ที่ต้องแยกตัวจากฉากหลัง */
    fun fill(l: Double): Color = if (!isLight) base.opacity(l) else base.opacity(min(0.5, l * 0.8))
    fun fill(l: Float): Color = fill(l.toDouble())

    /** ชั้นความสูง — พื้นมืดใช้แสง · พื้นสว่างใช้เงา (เงาเป็นดำเสมอ) */
    val lift: Color get() = if (isLight) Color.Black.opacity(0.18) else Color.Transparent
    val liftRadius: Float get() = if (isLight) 14f else 0f

    companion object {
        val night = InkStyle(CardInk.night, Color.White)
    }
}

/** หมึกของพื้นที่ชิ้นนี้นั่งอยู่จริง — ค่าเริ่มต้นคือกลางคืน (พรีวิวในตู้ widget อยู่บนชีตมืด) */
val LocalCardInk = compositionLocalOf { InkStyle.night }
