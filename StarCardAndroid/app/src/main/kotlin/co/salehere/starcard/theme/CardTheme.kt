package co.salehere.starcard.theme

import android.graphics.Bitmap
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.RenderEffect
import androidx.compose.ui.graphics.asComposeRenderEffect
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.LocalWidgetPattern
import co.salehere.starcard.model.PlatePattern
import java.util.Locale
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

// MARK: - ธีมของการ์ด (= Theme/CardTheme.swift ส่วนที่เหลือ — `CardInk` · `InkStyle` · `LocalCardInk` อยู่ใน Ink.kt
//         · `Color.onLightSurface` อยู่ใน ColorTools.kt)

/**
 * พาเลตต์ระดับการ์ด — widget เลือกได้แค่ "ตามธีม / เข้ม / อ่อน / เน้น"
 * ไม่เปิดให้ใส่ hex อิสระ เพื่อให้การ์ดกลมกลืนเสมอและ contrast ผ่านเกณฑ์
 */
enum class Palette(val raw: String) {
    // ไล่ตามวงล้อสี: น้ำเงิน → ฟ้า → เขียว → ม่วง → ชมพู → ส้ม → ทอง → เทา
    midnight("midnight"), sky("sky"), ocean("ocean"), mint("mint"), lime("lime"), lavender("lavender"),
    orchid("orchid"), rose("rose"), ruby("ruby"), coral("coral"), champagne("champagne"), noir("noir");

    /** `name` ของ Swift — `Enum.name` เป็น final ใน Kotlin จึงใช้ชื่อนี้ (เหมือน `CardInk.displayName`) */
    val displayName: String
        get() = when (this) {
            midnight -> "Midnight"
            sky -> "Sky"
            ocean -> "Ocean"
            mint -> "Mint"
            lime -> "Lime"
            lavender -> "Lavender"
            orchid -> "Orchid"
            rose -> "Rose"
            ruby -> "Ruby"
            coral -> "Coral"
            champagne -> "Champagne"
            noir -> "Noir"
        }

    val accent: Color
        get() = when (this) {
            midnight -> rgb(0.51, 0.60, 1.00)
            sky -> rgb(0.38, 0.66, 1.00)
            ocean -> rgb(0.32, 0.79, 0.95)
            mint -> rgb(0.36, 0.90, 0.68)
            lime -> rgb(0.72, 0.93, 0.40)
            lavender -> rgb(0.72, 0.63, 1.00)
            orchid -> rgb(0.93, 0.52, 0.98)
            rose -> rgb(1.00, 0.55, 0.74)
            ruby -> rgb(1.00, 0.42, 0.47)
            coral -> rgb(1.00, 0.60, 0.43)
            champagne -> rgb(0.93, 0.80, 0.55)
            noir -> rgb(0.84, 0.86, 0.90)
        }

    val accentSoft: Color
        get() = when (this) {
            midnight -> rgb(0.62, 0.78, 1.00)
            sky -> rgb(0.58, 0.80, 1.00)
            ocean -> rgb(0.46, 0.94, 0.88)
            mint -> rgb(0.63, 0.96, 0.80)
            lime -> rgb(0.85, 1.00, 0.62)
            lavender -> rgb(0.88, 0.74, 1.00)
            orchid -> rgb(1.00, 0.70, 1.00)
            rose -> rgb(1.00, 0.73, 0.85)
            ruby -> rgb(1.00, 0.63, 0.66)
            coral -> rgb(1.00, 0.77, 0.60)
            champagne -> rgb(1.00, 0.92, 0.74)
            noir -> rgb(0.62, 0.65, 0.72)
        }

    /** เฉดฐานของฉากหลัง (0…1 บนวงล้อสี) — เก็บเป็น hue ไม่ใช่ RGB สำเร็จรูป */
    val backdropHue: Double
        get() = when (this) {
            midnight -> 0.64
            sky -> 0.58
            ocean -> 0.54
            mint -> 0.42
            lime -> 0.24
            lavender -> 0.74
            orchid -> 0.82
            rose -> 0.93
            ruby -> 0.98
            coral -> 0.04
            champagne -> 0.10
            noir -> 0.62
        }

    /** อิ่มตัวฐาน — noir ต้องจืดกว่าตัวอื่นถึงจะยังเป็นโทนเทา */
    val backdropSaturation: Double get() = if (this == noir) 0.10 else 0.58

    // พาเลตต์ = ปุ่มลัดที่เขียน hex (20 ต.ค. 2569 รอบ 3) — doc เก็บแค่ `colors.primary/secondary`
    // สองค่านี้คือพื้นที่สูตรเดิมเคยคิดให้ที่ความสว่าง 0.30 · ต้องตรงกับ `Palette` ของ iOS และ `PRESETS` ใน theme.js
    /** พื้นโทนมืดของพาเลตต์นี้ */
    val dark: Color
        get() = when (this) {
            midnight -> Color.hex(0x1A1F35); sky -> Color.hex(0x1A2835); ocean -> Color.hex(0x1A2E35)
            mint -> Color.hex(0x1A3528); lime -> Color.hex(0x29351A); lavender -> Color.hex(0x261A35)
            orchid -> Color.hex(0x321A35); rose -> Color.hex(0x351A25); ruby -> Color.hex(0x351A1E)
            coral -> Color.hex(0x35211A); champagne -> Color.hex(0x352A1A); noir -> Color.hex(0x343435)
        }
    /** พื้นโทนสว่างของพาเลตต์นี้ */
    val light: Color
        get() = when (this) {
            midnight -> Color.hex(0xEAECF7); sky -> Color.hex(0xEAF1F7); ocean -> Color.hex(0xEAF4F7)
            mint -> Color.hex(0xEAF7F1); lime -> Color.hex(0xF1F7EA); lavender -> Color.hex(0xF0EAF7)
            orchid -> Color.hex(0xF6EAF7); rose -> Color.hex(0xF7EAEF); ruby -> Color.hex(0xF7EAEB)
            coral -> Color.hex(0xF7EDEA); champagne -> Color.hex(0xF7F2EA); noir -> Color.hex(0xEFF1F7)
        }
    fun primary(light: Boolean): Color = if (light) this.light else dark

    companion object {
        fun from(raw: String?): Palette? = entries.firstOrNull { it.raw == raw }

        /** พาเลตต์ที่พื้นสีนี้เป็นของมัน (ไว้ไฮไลต์เม็ดในถาด) — null = สีของผู้ใช้เอง */
        fun matching(c: Color): Pair<Palette, Boolean>? {
            val hex = c.hexString
            for (p in entries) {
                if (p.dark.hexString == hex) return p to false
                if (p.light.hexString == hex) return p to true
            }
            return null
        }
    }
}

enum class CornerStyle(val raw: String) {
    soft("soft"), round("round"), pill("pill");

    val radius: Float
        get() = when (this) {
            soft -> 18f
            round -> 28f
            pill -> 38f
        }

    val displayName: String
        get() = when (this) {
            soft -> "คม"
            round -> "มน"
            pill -> "มนมาก"
        }

    companion object {
        fun from(raw: String?): CornerStyle? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * แบบของฉากหลัง — เรียงจากพื้นแบนไปหาพื้นที่มีของเยอะสุด แถวชิปในแผงอ่านตามลำดับนี้
 */
enum class BackdropStyle(val raw: String) {
    solid("solid"), gradient("gradient"), grid("grid"), stripe("stripe"), diamond("diamond"),
    glow("glow"), marble("marble"), photo("photo");

    val displayName: String
        get() = when (this) {
            gradient -> "ไล่เฉด"
            grid -> "ตาราง"
            stripe -> "ลายทาง"
            diamond -> "ข้าวหลามตัด"
            glow -> "ดวงแสง"
            solid -> "สีเดียว"
            marble -> "หินอ่อน"
            photo -> "รูป"
        }

    /** ชื่อ SF Symbol (วาดผ่าน `SFSymbol`) */
    val icon: String
        get() = when (this) {
            gradient -> "square.filled.and.line.vertical.and.square"
            grid -> "grid"
            stripe -> "rectangle.split.3x1.fill"
            diamond -> "diamond.fill"
            glow -> "sun.max.fill"
            solid -> "square.fill"
            marble -> "swirl.circle.righthalf.filled"
            photo -> "photo.fill"
        }

    companion object {
        fun from(raw: String?): BackdropStyle? = entries.firstOrNull { it.raw == raw }
        /** แบบที่แผงพื้นหลังเสนอ (20 ต.ค. 2569 — ผู้ใช้ตัดเหลือสองแบบ) · เคสอื่นคงไว้ให้การ์ดเก่ายังถอดรหัสและวาดได้ */
        val offered: List<BackdropStyle> = listOf(solid, gradient)
    }
}

/**
 * เอฟเฟกต์บนรูปพื้นหลัง — เครื่องมือ **ลดเสียงของรูป**
 * ขาวดำตัดสีที่ชนกับธีมทิ้ง · เบลอตัดรายละเอียด · จุดปะตัดทั้งสองอย่างแล้วเหลือเป็นลาย
 */
enum class BackdropEffect(val raw: String) {
    none("none"), mono("mono"), blur("blur"), halftone("halftone");

    val displayName: String
        get() = when (this) {
            none -> "ไม่มี"
            mono -> "ขาวดำ"
            blur -> "เบลอ"
            // ไม่ใช้คำว่า "ฮาล์ฟโทน" — ป้ายต้องบอกว่ากดแล้วเห็นอะไร ไม่ใช่ชื่อเทคนิคการพิมพ์
            halftone -> "จุดปะ"
        }

    /** ต้องอบไว้ก่อนไหม (ดู `PhotoStore.bake`) — ที่เหลือทำสด ๆ ได้ทุกเฟรม */
    val isBaked: Boolean get() = this == halftone

    companion object {
        fun from(raw: String?): BackdropEffect? = entries.firstOrNull { it.raw == raw }
    }
}

/** สองสีที่มีผลจริงของคู่สี — `bg` เป็นพื้น · `ink` เป็นหมึก (= tuple `duoColors` ของ Swift) */
data class DuoColors(val bg: Color, val ink: Color)

/** สองสีของฉากหลัง (= tuple `backdropColors` ของ Swift) */
data class BackdropColors(val top: Color, val bottom: Color)

/**
 * ธีมของการ์ดหนึ่งใบ — Swift `mutating func` กลายเป็นฟังก์ชันคืนสำเนา (`theme = theme.setDuo(d)`)
 */
data class CardTheme(
    /**
     * สีพื้นการ์ด — **ค่าเดียวที่ doc เก็บ** (`theme.colors.primary`) ทุกสีที่เหลือคิดจากสีนี้
     * พาเลตต์/คู่สีสำเร็จรูปเป็นแค่ปุ่มลัดที่เขียนค่านี้ (20 ต.ค. 2569 รอบ 3)
     */
    var primary: Color = Palette.midnight.dark,
    /** หมึกของการ์ดสองสี (`theme.colors.secondary`) — มี = การ์ดสองสี · primary เป็นพื้นเสมอ · สลับข้าง = สลับค่า */
    var secondary: Color? = null,
    /** พื้นผิวของการ์ด — เลือกโดยเจ้าของการ์ด ไม่ล้อ dark mode ของเครื่องผู้ดู */
    var ink: CardInk = CardInk.night,
    // `inkAuto` ถอดออก 20 ต.ค. 2569 — doc เก็บ `ink` ตรง ๆ เสมอ · เลือกสีเองเมื่อไหร่ `autoInk` เลือกฝั่งให้ทันทีตอนนั้น
    var corner: CornerStyle = CornerStyle.round,
    /** หน้าตาของแถบผู้ออกบัตรที่ขอบล่าง (ดู `IssuerStrip`) — ถอดไม่ได้ เลือกได้แค่แบบ */
    var strip: StripStyle = StripStyle.line,
    var backdrop: BackdropStyle = BackdropStyle.gradient,
    /** เอฟเฟกต์บนรูปพื้นหลัง — มีผลเฉพาะตอน `backdrop == .photo` */
    var photoEffect: BackdropEffect = BackdropEffect.none,
    /** แผ่นสีที่คลุมรูปไว้ 0…0.8 — ยิ่งมากรูปยิ่งจม ตัวหนังสือบนการ์ดยิ่งอ่านง่าย */
    var photoDim: Double = 0.42,
    /** รูปพื้นหลังเอียงไปทางสว่างแค่ไหน ในสายตาของตัวหนังสือ (−1…1) — null = ยังไม่เคยวัด */
    var photoLean: Double? = null,
    /** ธีมนี้ถูกวาดบนแผงเครื่องมือ (พื้นมืดคงที่) ไม่ใช่บนการ์ด — ดู `toolTheme` · ไม่ถูกเซฟ */
    var onStage: Boolean = false,
) {
    /** สีพื้นแยกเป็น HSB — ทุกสูตรของธีม (ไล่เฉด สีเน้น หมึกอาบเฉด) อ่านจากตรงนี้ */
    val primaryHSB: HSB get() = primary.toHSB()

    /** สีพื้นเป็นสีที่ผู้ใช้เลือกเอง (ไม่ตรงกับเม็ดสำเร็จรูปใด) — ถาดใช้ไฮไลต์เม็ด "สีของฉัน" */
    val hasCustomColor: Boolean get() = secondary == null && Palette.matching(primary) == null

    /** สองสีที่ **มีผลจริง** ตอนนี้ — พื้นเป็นรูปเมื่อไหร่คู่สีถอยให้รูปทั้งคู่ */
    val duoColors: DuoColors?
        get() {
            if (backdrop == BackdropStyle.photo) return null
            val s = secondary ?: return null
            // โทน (`ink`) เป็นเรื่องของการวาด ไม่ใช่ค่าสี: มืด = สีเข้มของคู่เป็นพื้น · สว่าง = สีอ่อนเป็นพื้น · doc ไม่สลับค่า
            val pDark = RGB(primary).luminance < RGB(s).luminance
            val dark = if (pDark) primary else s; val light = if (pDark) s else primary
            return if (ink.isLight) DuoColors(light, dark) else DuoColors(dark, light)
        }

    /** คู่สีที่มีผลจริงตอนนี้ **ตามบทบาทถาวร** (เข้ม/อ่อนตัดสินจากความสว่าง) — แผ่นทึบของ widget ต้องเข้มเสมอ */
    val activeDuo: ColorDuo?
        get() {
            val c = duoColors ?: return null
            val bgDark = RGB(c.bg).luminance < RGB(c.ink).luminance
            return ColorDuo(id = "custom", darkName = "", lightName = "",
                dark = if (bgDark) c.bg else c.ink, light = if (bgDark) c.ink else c.bg)
        }
    val duoDark: Color? get() = activeDuo?.dark
    val duoLight: Color? get() = activeDuo?.light
    /** สีอ่อนของคู่ขึ้นเป็นพื้นอยู่ไหม (= "โทนสว่าง" ของการ์ดสองสี) */
    val duoFlipped: Boolean get() = duoColors != null && ink.isLight

    /** การ์ดใบนี้ใช้คู่สีสำเร็จรูปคู่นี้อยู่ไหม (ไม่สนว่าพลิกข้าง) — ไว้ไฮไลต์เม็ดในถาด */
    fun matches(d: ColorDuo): Boolean {
        val s = secondary ?: return false
        return setOf(primary.hexString, s.hexString) == setOf(d.dark.hexString, d.light.hexString)
    }

    /** เลือกคู่สีสำเร็จรูป — ขึ้นข้างที่ตรงกับโทนของการ์ดตอนนั้น (การ์ดกระดาษได้พื้นสีอ่อนของคู่) */
    fun setDuo(d: ColorDuo): CardTheme {
        // เก็บคู่ตามที่นิยามไว้ (เข้ม · อ่อน) — โทนที่การ์ดเป็นอยู่ (`ink`) ตัดสินเองว่าสีไหนขึ้นเป็นพื้น
        val wasLight = activeInk.isLight
        return copy(primary = d.dark, secondary = d.light, ink = if (wasLight) lightInk else CardInk.night)
    }
    /** สลับข้างของการ์ดสองสี (แถวโทน) — `light` = สีอ่อนขึ้นเป็นพื้น · แตะแค่โทน ไม่แตะค่าสีใน doc */
    fun flipDuo(light: Boolean): CardTheme {
        secondary ?: return this
        return copy(ink = if (light) lightInk else CardInk.night)
    }
    /** เลือกพาเลตต์สำเร็จรูป — เม็ดเดียวมีสองเฉด: แตะครั้งแรก = เฉดเข้ม · แตะซ้ำเม็ดที่เลือกอยู่ = สลับเข้ม/อ่อน
     *  (แถวโทนมีเฉพาะคู่สีตั้งแต่ 20 ต.ค. 2569 — สีเดียวหมึกเลือกเองจาก `autoInk`) · ล้างคู่สี (= iOS `setPreset`) */
    fun setPreset(p: Palette): CardTheme {
        val cur = if (secondary == null) Palette.matching(primary) else null
        val light = if (cur?.first == p) !(cur.second) else false
        val t = copy(secondary = null, primary = p.primary(light))
        return t.copy(ink = t.autoInk)
    }

    /** สีที่ผู้ใช้เลือกเองตอนนี้ (HSB) — แผงใช้จำไว้เป็น "สีของฉัน" ก่อนสลับไปสีสำเร็จรูป */
    val customColor: HSB? get() = if (hasCustomColor) primaryHSB else null

    /** ความสว่างที่ตารับรู้ของสีพื้น (0…1 ตามสูตร WCAG) */
    private val primaryLuminance: Double get() = RGB(primary).luminance

    /**
     * หมึกที่ใช้จริง — **พื้นหลังเป็นรูปเมื่อไหร่ บังคับกลางคืนเสมอ**
     * โหมดอัตโนมัติคำนวณ contrast ของหมึกทั้งสองฝั่งกับพื้นจริงแล้วเลือกฝั่งที่ชนะ
     */
    val activeInk: CardInk
        get() {
            if (backdrop == BackdropStyle.photo) return CardInk.night
            // คู่สีตอบคำถามนี้ไปแล้วในตัวมันเอง: พื้นสว่างกว่าหมึก = ฝั่งสว่าง
            if (duoColors != null) return if (ink.isLight) lightInk else CardInk.night
            // ผู้ใช้เลือกได้แค่สองฝั่ง (มืด · สว่าง) — ฝั่งสว่างยังแยกกระดาษ/ใสใสตามความสดของพื้นเอง
            return if (ink.isLight) lightInk else CardInk.night
        }

    /** หมึกที่อ่านออกบนสีพื้นนี้ — ใช้ตอนผู้ใช้เลือกสีเองแล้วยังไม่ได้บอกโทน (= `autoInk` ของ iOS: contrast ทั้งสองฝั่ง เลือกฝั่งที่ชนะ) */
    val autoInk: CardInk
        get() {
            val l = primaryLuminance
            val withWhiteInk = 1.05 / (l + 0.05)
            val withDarkInk = (l + 0.05) / 0.07
            return if (withDarkInk > withWhiteInk) lightInk else CardInk.night
        }

    /** หน้าตาของฝั่งสว่าง — พื้นที่ยังมีสีอยู่มากต้องได้ถ่านที่อาบเฉดเดียวกัน */
    val lightInk: CardInk get() = if (primaryHSB.s >= 0.35) CardInk.mist else CardInk.paper

    val backdropHue: Double get() = primaryHSB.h

    /** ความสดของพื้นที่บีบไว้ 0.15…0.6 — ใช้กับลายทาง/สีเน้นดิบ ไม่ใช้กับตัวพื้น (พื้น = สีที่เลือกเป๊ะ) */
    private val backdropSat: Double get() = min(0.6, max(0.15, primaryHSB.s))

    /**
     * สองสีของฉากหลังหลังปรับความสว่างและโทนแล้ว
     * ฝั่งสว่างไม่ได้ใช้สูตรเดียวกันแล้วดันค่าขึ้น — **ความอิ่มตัวต้องกลับทิศ**
     */
    val backdropColors: BackdropColors
        get() {
            // คู่สีคือสีจริงที่เลือกมาแล้ว ห้ามผ่านสูตรไหนทั้งนั้น — ปลายล่างจึงเป็นแค่เงาของสีเดียวกัน
            duoColors?.let { c ->
                val inkDarker = RGB(c.ink).luminance < RGB(c.bg).luminance
                return BackdropColors(
                    c.bg,
                    if (inkDarker) c.bg.mixed(c.ink, 0.10) else c.bg.mixed(Color.Black, 0.26),
                )
            }
            // สีเดียว: พื้น = สีที่เลือกเป๊ะ · ปลายล่างเข้มลงเล็กน้อยพอให้ไล่เฉดยังมีทิศทาง แต่ยังอ่านเป็นสีเดียวกัน
            val p = primaryHSB
            return BackdropColors(primary, hsb(p.h, min(1.0, p.s * 1.06), p.b * 0.80))
        }

    /** สีของแถบในฉากหลังแบบ "ลายทาง" — เฉดเดียวกับพื้น ต่างกันแค่หนึ่งขั้นความสว่าง */
    val stripeInk: Color
        get() {
            duoColors?.let { c -> return c.ink.opacity(0.10) }
            val h = backdropHue
            return when (activeInk) {
                CardInk.night -> hsb(h, min(1.0, backdropSat + 0.1), 0.85).opacity(0.10)
                CardInk.paper -> hsb(h, 0.22, 0.58).opacity(0.13)
                CardInk.mist -> hsb(h, 0.40, 0.55).opacity(0.14)
            }
        }

    /** สีหมึกและโทเคนทั้งชุดของการ์ดใบนี้ */
    val inkStyle: InkStyle
        get() {
            // หมึกของคู่สีคือสีที่สองของคู่ตรง ๆ — ทั้งตัวหนังสือ เส้น แผ่น ใช้สีนี้หมดทั้งใบ
            duoColors?.let { c -> return InkStyle(activeInk, c.ink) }
            if (!activeInk.isLight) return InkStyle.night
            // ถ่านที่อาบเฉดของธีมไว้ — mist อาบเข้มกว่าเพราะพื้นมันมีสีมากกว่า
            val charcoal = hsb(
                backdropHue,
                if (activeInk == CardInk.mist) 0.38 else 0.26,
                if (activeInk == CardInk.mist) 0.155 else 0.135,
            )
            return InkStyle(activeInk, charcoal)
        }

    /**
     * สีเน้นบนพื้นการ์ด — ปรับตามหมึกเสมอ
     * คู่สีไม่มี "สีที่สาม" ให้เน้น — งานสองสีเน้นด้วยหมึกสีเดียวกับตัวหนังสือ
     */
    val accent: Color
        get() {
            duoColors?.let { c -> return c.ink }
            return if (activeInk.isLight) rawAccent.onLightSurface() else rawAccent
        }
    val accentSoft: Color
        get() {
            duoColors?.let { c -> return c.ink.mixed(c.bg, 0.34) }
            return if (activeInk.isLight) rawAccent.onLightSurface(depth = 0.35) else rawAccentSoft
        }

    /**
     * สีเน้นดิบของพาเลตต์ — จูนไว้สำหรับพื้นมืด · ใช้ตรง ๆ ได้เฉพาะของที่วางบน "รูป" เท่านั้น
     * คู่สี: ตัวดิบคือ **สีอ่อนของคู่เสมอ** ไม่ใช่หมึกของการ์ด
     */
    val rawAccent: Color
        get() {
            activeDuo?.let { d -> return d.light }
            val p = primaryHSB
            return hsb(p.h, min(0.72, max(0.35, p.s + 0.1)), 0.96)
        }
    val rawAccentSoft: Color
        get() {
            activeDuo?.let { d -> return d.light.mixed(d.dark, 0.30) }
            val p = primaryHSB
            val shifted = (p.h + 0.04) - floor(p.h + 0.04)
            return hsb(shifted, min(0.5, max(0.25, p.s)), 1.0)
        }

    /**
     * ธีมเวอร์ชันสำหรับ **แผงเครื่องมือ** — บังคับหมึกกลางคืนเสมอ
     * ทุกอย่างในชีตแต่งกับตู้ widget นั่งอยู่บนพื้นมืดคงที่ ไม่ใช่บนการ์ด
     */
    val toolTheme: CardTheme
        get() {
            // ต้องปิดโหมดอัตโนมัติด้วย ไม่งั้นการ์ดที่ตั้งสีพื้นสว่างไว้จะลากหมึกกระดาษเข้ามาในชีต
            var t = copy(ink = CardInk.night)
            // คู่สีที่วางสีอ่อนไว้เป็นพื้นจะลากหมึกเข้มเข้ามาในชีตที่พื้นมืดคงที่ — สลับข้างให้เฉพาะในชีต
            // คู่สี: `ink = night` ข้างบนทำให้สีเข้มของคู่ขึ้นเป็นพื้นในชีตแล้ว (ไม่ต้องสลับค่าสี)
            return t
        }

    val radius: Float get() = corner.radius

    // MARK: - สีพื้นเป็นเลขฐานสิบหก

    /** สีพื้นตอนนี้แยกเป็น HSB — อ่านจาก `backdropColors.top` เพื่อให้การ์ดที่ยังใช้พาเลตต์ตอบได้ว่าพื้นสีอะไร */
    val backdropHSB: HSB get() = backdropColors.top.toHSB()

    /** สีพื้นตอนนี้ในรูป `#RRGGBB` — ป้ายบนเม็ดสีของแผง */
    val backdropHex: String
        get() {
            val c = backdropColors.top
            fun ch(v: Float): Int = (max(0f, min(1f, v)) * 255f).roundToInt()
            return String.format(Locale.US, "#%02X%02X%02X", ch(c.red), ch(c.green), ch(c.blue))
        }

    /**
     * ตั้งสีพื้นจาก HSB — ทางเข้าเดียวของทั้งแถบสีและช่อง hex (ล้างคู่สี · พื้น = สีนี้เป๊ะ)
     */
    fun setBackdropColor(h: Double, s: Double, b: Double): CardTheme {
        val t = copy(secondary = null, primary = hsb(h - floor(h), min(1.0, max(0.0, s)), min(1.0, max(0.0, b))))
        return t.copy(ink = t.autoInk)
    }

    /** ล้างสีที่เลือกเอง/คู่สี กลับไปพาเลตต์ตั้งต้นตามโทนที่การ์ดเป็นอยู่ */
    fun clearBackdropColor(): CardTheme = setPreset(Palette.midnight)

    /** โทนที่ดูดจากรูปพื้นหลัง (เฉด + ความสด) — คงความสว่างเดิมของพื้นไว้ (ตอนพื้นเป็นรูป สีนี้ใช้แค่คิดสีเน้น/ลาย) */
    fun setBackdropTone(hue: Double?, sat: Double?): CardTheme {
        hue ?: return this
        val t = copy(secondary = null, primary = hsb(hue - floor(hue), min(0.6, max(0.15, sat ?: 0.5)), primaryHSB.b))
        return t.copy(ink = t.autoInk)
    }

    /** อ่านค่า `#RGB` หรือ `#RRGGBB` — คืน null เมื่ออ่านไม่ออก แล้วผู้เรียกคงสีเดิมไว้ */
    fun setBackdropHex(text: String): CardTheme? {
        val raw = text.trim().replace("#", "").uppercase(Locale.US)
        val digits = when (raw.length) {
            // ย่อสามหลักแบบ CSS — คนพิมพ์ `#FFF` แล้วคาดว่าจะได้ขาว ไม่ใช่ค่าที่อ่านไม่ออก
            3 -> raw.map { "$it$it" }.joinToString("")
            6 -> raw
            else -> return null
        }
        if (!digits.all { it in '0'..'9' || it in 'A'..'F' }) return null
        val v = digits.toLongOrNull(16) ?: return null
        val c = rgb(((v shr 16) and 0xFF) / 255.0, ((v shr 8) and 0xFF) / 255.0, (v and 0xFF) / 255.0)
        val (h, s, b) = c.toHSB()
        // สีเทาล้วนไม่มีเฉด — เก็บเฉดเดิมของการ์ดไว้แทน ตัวสีที่ได้ยังเป็นเทาเพราะความสดเป็น 0
        return setBackdropColor(if (s < 0.004) backdropHue else h, s, b)
    }
}

// MARK: - Backdrop

/**
 * ฉากหลังของการ์ด — มีดวงแสงนวลอยู่เสมอในทุกแบบ ยกเว้นแบบ "สีเดียว"
 * `ignoreSafeArea` คงไว้ให้ API ตรงกับ iOS — บน Android แผ่นเต็มพื้นที่ที่ผู้เรียกให้อยู่แล้ว (ไม่มี safe area ระดับ composable)
 * `signed` = เซ็นมุมขวาล่างด้วยโลโก้ Sale Here — **เปิดเฉพาะตอนเป็นฉากหลังของตัวการ์ด**
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun CardBackdrop(
    theme: CardTheme,
    ignoreSafeArea: Boolean = true,
    signed: Boolean = false,
    modifier: Modifier = Modifier,
) {
    // ดวงแสงใหญ่กว่าแผ่น — ตัดที่ขอบเสมอ ไม่งั้นมันดันผังทั้งแอป
    Box(modifier.fillMaxSize().clipToBounds()) {
        BackdropFills(theme)
        // ชั้นบนสุดของ "พื้น" — ใต้ widget ทุกชิ้นเสมอ · แบบปั๊มนูนวาดเหนือ widget (ดู `SignatureEmboss`)
        if (signed && !theme.strip.isStamp) {
            val ink = theme.inkStyle
            SignatureCorner(tint = ink.base, light = ink.isLight, modifier = Modifier.fillMaxSize())
        }
    }
}

@Composable
private fun BackdropFills(theme: CardTheme) {
    val c = theme.backdropColors
    val light = theme.activeInk.isLight
    Box(Modifier.fillMaxSize()) {
        when (theme.backdrop) {
            BackdropStyle.gradient -> {
                VerticalFill(c.top, c.bottom)
                Orbs(theme, 0.5)
            }

            BackdropStyle.grid -> {
                // ไล่เฉดเดิม + เส้นตารางจาง ๆ แบบกระดาษกราฟ — ขาวโปร่งบนพื้นสว่าง / ขาวจางกว่าบนเวทีมืด
                VerticalFill(c.top, c.bottom)
                BackdropGrid(line = Color.White.opacity(if (light) 0.55 else 0.09))
                Orbs(theme, 0.35)
            }

            BackdropStyle.stripe -> {
                // ลายทางสีเดียวกันสองเฉด (tone-on-tone) — เกล็ดกระดาษทำให้อ่านเป็นวัสดุ ไม่ใช่เวกเตอร์
                SolidFill(c.top)
                BackdropStripes(band = theme.stripeInk)
                EdGrain(count = 2400, opacity = if (light) 0.05 else 0.09, tint = if (light) Color.Black else Color.White)
            }

            BackdropStyle.diamond -> {
                // ข้าวหลามตัด (harlequin) — สูตรสีเดียวกับลายทาง: สองเฉดของสีเดียว
                SolidFill(c.top)
                BackdropDiamonds(band = theme.stripeInk)
                EdGrain(count = 2400, opacity = if (light) 0.05 else 0.09, tint = if (light) Color.Black else Color.White)
            }

            BackdropStyle.glow -> {
                // ฝั่งสว่างต้องไล่จากบนลงล่าง ไม่ใช่พื้นเดียวทับดวงแสง
                if (light) {
                    GradientFill(c.top, c.bottom, start = { Offset.Zero }, end = { Offset(it.width / 2f, it.height) })
                } else {
                    SolidFill(c.bottom)
                }
                Orbs(theme, 1.0)
            }

            BackdropStyle.solid -> SolidFill(c.top)

            BackdropStyle.marble -> {
                // แผ่นหินเอียงเฉียง ไม่ใช่ไล่บนลงล่าง — หินขัดเป็นแผ่นที่แสงตกเฉียง
                GradientFill(c.top, c.bottom, start = { Offset.Zero }, end = { Offset(it.width, it.height) })
                val m = theme.marbleInk
                MarbleVeins(vein = m.vein, bleed = m.bleed)
                Orbs(theme, 0.24)
            }

            BackdropStyle.photo -> {
                PhotoFill(theme, c, light)
                Orbs(theme, 0.35)
            }
        }
    }
}

/** รูปพื้นหลังที่ผู้ใช้อัปโหลดเอง — ขาวดำกับเบลอทำสดตรงนี้ · จุดปะถูกอบมาแล้วตั้งแต่ใน `PhotoStore` */
@Composable
private fun PhotoFill(theme: CardTheme, c: BackdropColors, light: Boolean) {
    val photos = LocalPhotoStore.current
    SolidFill(c.bottom)
    val bg: Bitmap? = photos?.background(theme.photoEffect)
    if (bg != null) {
        val image = remember(bg) { bg.asImageBitmap() }
        val mono = theme.photoEffect == BackdropEffect.mono
        val blurred = theme.photoEffect == BackdropEffect.blur
        Box(Modifier.fillMaxSize()) {
            Image(
                bitmap = image,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                colorFilter = if (mono) ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0f) }) else null,
                modifier = Modifier.fillMaxSize().blur(if (blurred) 26.dp else 0.dp),
            )
            SolidFill(c.top.opacity(theme.photoDim))
            GradientFill(
                Color.Transparent, c.bottom.opacity(0.5),
                start = { Offset(it.width / 2f, it.height / 2f) }, end = { Offset(it.width / 2f, it.height) },
            )
        }
    } else if (photos != null) {
        Box(Modifier.fillMaxSize().blur(60.dp).saturationLayer(1.2f)) {
            photos.image(0, modifier = Modifier.fillMaxSize())
        }
        SolidFill(c.top.opacity(if (light) 0.78 else 0.55))
    } else {
        VerticalFill(c.top, c.bottom)
    }
}

/** ดวงแสงสองดวง — วาดเป็นไล่เฉดวงกลมแทน `Circle().blur()` เพราะ `Modifier.blur` ไม่ทำงานต่ำกว่า API 31 */
@Composable
private fun Orbs(theme: CardTheme, strength: Double) {
    // บนกระดาษ ดวงแสงกลายเป็น "รอยสีซึม" — ต้องเบาลงมาก ไม่งั้นอ่านเป็นคราบเปื้อน
    val k = if (theme.activeInk.isLight) strength * 0.34 else strength
    val a = theme.accent.opacity(0.5 * k)
    val b = theme.accentSoft.opacity(0.34 * k)
    Canvas(Modifier.fillMaxSize()) {
        val cx = size.width / 2f
        val cy = size.height / 2f
        glow(a, Offset(cx - 140.dp.toPx(), cy - 240.dp.toPx()), 220.dp.toPx(), 140.dp.toPx())
        glow(b, Offset(cx + 160.dp.toPx(), cy + 280.dp.toPx()), 190.dp.toPx(), 150.dp.toPx())
    }
}

/** วงกลมทึบรัศมี `radius` ที่ถูกเบลอ `blur` — ประมาณด้วยไล่เฉดวงกลมสามช่วง */
private fun DrawScope.glow(color: Color, center: Offset, radius: Float, blur: Float) {
    val outer = radius + blur
    val core = max(0f, radius - blur) / outer
    drawCircle(
        brush = Brush.radialGradient(
            0f to color,
            core to color,
            (core + 1f) / 2f to color.opacity(0.45f),
            1f to color.opacity(0f),
            center = center,
            radius = outer,
        ),
        radius = outer,
        center = center,
    )
}

@Composable
private fun SolidFill(color: Color) {
    Box(Modifier.fillMaxSize().background(color))
}

@Composable
private fun VerticalFill(top: Color, bottom: Color) {
    Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(top, bottom))))
}

/** ไล่เฉดที่จุดเริ่ม/จุดจบคิดจากขนาดจริง (topLeading → bottom ฯลฯ) */
@Composable
private fun GradientFill(top: Color, bottom: Color, start: (Size) -> Offset, end: (Size) -> Offset) {
    Box(
        Modifier.fillMaxSize().drawBehind {
            drawRect(Brush.linearGradient(listOf(top, bottom), start = start(size), end = end(size)))
        },
    )
}

/** `.saturation(k)` ของ SwiftUI — RenderEffect บน API 31+ · ต่ำกว่านั้นไม่ทำอะไร */
internal fun Modifier.saturationLayer(k: Float): Modifier = graphicsLayer {
    if (Build.VERSION.SDK_INT >= 31 && k != 1f) renderEffect = saturationEffect(k)
}

@RequiresApi(31)
private fun saturationEffect(k: Float): RenderEffect =
    android.graphics.RenderEffect.createColorFilterEffect(
        android.graphics.ColorMatrixColorFilter(android.graphics.ColorMatrix().apply { setSaturation(k) }),
    ).asComposeRenderEffect()

/** แถบตั้งของฉากหลังแบบ "ลายทาง" — กว้างเท่ากันทั้งแถบสีและช่องว่าง (หน่วยออกแบบ = dp) */
@Composable
fun BackdropStripes(band: Color, width: Float = 15f, modifier: Modifier = Modifier) {
    Canvas(modifier.fillMaxSize()) {
        val w = width.dp.toPx()
        var x = w * 0.5f
        while (x < size.width) {
            drawRect(band, topLeft = Offset(x, 0f), size = Size(w, size.height))
            x += w * 2f
        }
    }
}

/**
 * ลายบน **แผ่นทึบของ widget** — ผู้ใช้เลือกรายชิ้นในถาด (`WidgetInstance.pattern`)
 * ลายเป็น **เฉดเข้มของแผ่นเอง** ทึบทั้งชิ้น · แผ่นใสไม่วาด เพราะไม่มีแผ่นให้ลาย
 */
@Composable
fun PlatePatternLayer(sheet: Color, modifier: Modifier = Modifier) {
    val pattern = LocalWidgetPattern.current
    val band = sheet.mixed(Color.Black, 0.5)
    if (!sheet.approx(Color.Transparent)) {
        when (pattern) {
            PlatePattern.plain -> Unit
            PlatePattern.stripe -> BackdropStripes(band = band, modifier = modifier)
            PlatePattern.diamond -> BackdropDiamonds(band = band, modifier = modifier)
        }
    }
}

/** ข้าวหลามตัดแบบ harlequin — สัดส่วนสูง:กว้าง ≈ 1.75 ที่แบนกว่านี้อ่านเป็นตารางเอียง */
@Composable
fun BackdropDiamonds(band: Color, width: Float = 42f, modifier: Modifier = Modifier) {
    Canvas(modifier.fillMaxSize()) {
        val w = width.dp.toPx()
        val h = w * 1.75f
        val p = Path()
        var y = 0f
        while (y <= size.height + h / 2f) {
            var x = 0f
            while (x <= size.width + w / 2f) {
                p.moveTo(x, y - h / 2f)
                p.lineTo(x + w / 2f, y)
                p.lineTo(x, y + h / 2f)
                p.lineTo(x - w / 2f, y)
                p.close()
                x += w
            }
            y += h
        }
        drawPath(p, band)
    }
}

/** เส้นตารางของฉากหลังแบบ "ตาราง" — ระยะคงที่ในหน่วยออกแบบ ทุกเครื่องและไฟล์ที่ส่งออกได้ตารางถี่เท่ากัน */
@Composable
fun BackdropGrid(line: Color, step: Float = 22f, modifier: Modifier = Modifier) {
    Canvas(modifier.fillMaxSize()) {
        val s = step.dp.toPx()
        val stroke = 0.8.dp.toPx()
        var x = 0f
        while (x <= size.width) {
            drawLine(line, Offset(x, 0f), Offset(x, size.height), strokeWidth = stroke)
            x += s
        }
        var y = 0f
        while (y <= size.height) {
            drawLine(line, Offset(0f, y), Offset(size.width, y), strokeWidth = stroke)
            y += s
        }
    }
}

/**
 * เกล็ดกระดาษ — จุดสุ่มจาง ๆ (= `EdGrain` ใน Views/Widgets/EditorialWidgets.swift)
 * สุ่มด้วยเมล็ดคงที่ (xorshift) ลายจึงเหมือนเดิมทุกครั้งที่วาดใหม่
 */
@Composable
fun EdGrain(count: Int = 420, opacity: Double = 0.05, tint: Color = Color.Black, modifier: Modifier = Modifier) {
    Canvas(modifier.fillMaxSize()) {
        var seed = 0x9E3779B97F4A7C15uL
        fun rnd(): Float {
            seed = seed xor (seed shl 13)
            seed = seed xor (seed shr 7)
            seed = seed xor (seed shl 17)
            return (seed % 10_000uL).toFloat() / 10_000f
        }
        val px = density
        repeat(count) {
            val x = rnd() * size.width
            val y = rnd() * size.height
            val d = (0.6f + rnd() * 1.1f) * px
            val a = opacity * (0.4 + rnd().toDouble() * 0.6)
            drawOval(tint.opacity(a), topLeft = Offset(x, y), size = Size(d, d))
        }
    }
}
