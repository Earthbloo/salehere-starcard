package co.salehere.starcard.model

import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlinx.serialization.EncodeDefault
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable

// MARK: - ชุดห้าสไตล์ (Canva DAHXOY1w-iM หน้า 3–12) (= Model/KitModel.swift)
//
// สิบหัวข้อ × ห้าสไตล์ — **หนึ่งชนิดต่อหัวข้อ** (`WidgetKind.kit…`) แล้วสไตล์เป็นค่าของชิ้น ไม่ใช่ชนิดแยก
// เพราะห้าสไตล์เล่าข้อมูลชุดเดียวกันเป๊ะ (ผู้ใช้ 12 ต.ค. 2569) · สลับสไตล์ = เปลี่ยนหน้าตาอย่างเดียว ข้อมูลไม่หาย

/** ห้าสไตล์ — ชื่อตามหน้าตา (เลข model ใน Canva สลับกันในบางหน้า) */
@Serializable
enum class KitStyle {
    purple, cream, gingham, night, mac;

    val raw: String get() = name
    val id: String get() = raw

    /** ชื่อไทยบนถาด (= `name` ของ Swift — `Enum.name` ของ Kotlin ถูกจองไว้) */
    val displayName: String
        get() = when (this) {
            purple -> "ม่วงสติกเกอร์"
            cream -> "ครีมนุ่ม"
            gingham -> "กรอบตาราง"
            night -> "กลางคืน"
            mac -> "หน้าต่าง Mac"
        }

    /** สีพื้นตั้งต้นของสไตล์ (hex) */
    val fill: String
        get() = when (this) {
            purple -> "#B57EF7"
            cream -> "#ECE8E2"
            gingham -> "#C9D4A6"
            night -> "#0B0F14"
            mac -> "#FAFAFA"
        }

    /** โทนที่สไตล์นี้ดึงจาก **พื้นหลังการ์ด** — สีพื้นของ widget ไม่มีให้เลือกในถาด (ผู้ใช้ 12 ต.ค. 2569) */
    val cardToken: String
        get() = when (this) {
            purple -> "accent"   // สติกเกอร์ = สีสดของการ์ด
            cream -> "card+2"    // ครีม = การ์ดแบบอ่อนมาก
            gingham -> "card+1"  // ผ้ากรอบ = การ์ดแบบอ่อนกลาง
            night -> "card-3"    // กลางคืน = การ์ดแบบเข้มจัด
            mac -> "card+3"      // หน้าต่าง = การ์ดเกือบขาว
        }

    /** โทนของ **ขอบ** ที่ดึงจากพื้นหลังการ์ด — ไม่มีปุ่มเลือกสีขอบ */
    val borderToken: String
        get() = when (this) {
            purple -> "card-3"   // เส้นหนา + เงาเยื้อง = การ์ดเข้มจัด
            cream -> "card-1"
            gingham -> "card-3"  // เส้นของการ์ดขาวด้านใน
            night -> "accent"    // มุมนีออน + ตัวเลข = สีเน้นของการ์ด
            mac -> "card+2"      // เส้นบางรอบหน้าต่าง
        }

    /** สีขอบเดิมตาม Canva — ใช้แค่ในพรีวิวที่ไม่มีธีม · การ์ดจริงใช้ `borderToken` */
    val border: String
        get() = when (this) {
            purple, gingham -> "#141414"
            cream -> "#2A2A2A"
            night -> "#5AC8F0"
            mac -> "#D4D4D8"
        }

    /** มีขอบตั้งแต่หยิบออกจากตู้ — ครีมนุ่มใน Canva ไม่มีขอบ */
    val bordered: Boolean get() = this != cream

    /** รัศมีของ "มน" — "เหลี่ยม" เป็น 3pt ทุกสไตล์ */
    val radius: Float
        get() = when (this) {
            purple -> 14f
            cream -> 20f
            gingham -> 20f
            night -> 16f
            mac -> 12f
        }

    companion object {
        fun from(raw: String?): KitStyle? = entries.firstOrNull { it.raw == raw }
    }
}

/** พื้นหลัง — สามแบบตาม Canva หน้า 1 */
@Serializable
enum class KitFill {
    solid, gradient, clear;

    val raw: String get() = name
    val displayName: String
        get() = when (this) {
            solid -> "ทึบ"
            gradient -> "ไล่สี"
            clear -> "โปร่ง"
        }

    companion object {
        fun from(raw: String?): KitFill? = entries.firstOrNull { it.raw == raw }
    }
}

/** ทรงมุม — สองแบบเท่านั้น */
@Serializable
enum class KitCorner {
    round, square;

    val raw: String get() = name
    val displayName: String get() = if (this == round) "มน" else "เหลี่ยม"

    companion object {
        fun from(raw: String?): KitCorner? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * หน้าตาและตัวเลือกเนื้อหาของชิ้นในชุดห้าสไตล์ — เก็บต่อชิ้น (วางสองใบแล้วแต่งคนละแบบได้)
 * เปิด/ปิดเส้นขอบใช้ `WidgetInstance.border` ตัวเดิม · ที่นี่เก็บเฉพาะของที่ชุดเดิมไม่มี
 */
@OptIn(ExperimentalSerializationApi::class)
@Serializable
data class KitConfig(
    /**
     * หน้าตา — **มาจากชนิด** (`WidgetKind.kitStyle`) เติมตอนวาด (`looking`) · ไม่เขียนลงไฟล์ (ค่าตั้งต้น = ไม่เขียน)
     * ไฟล์ก่อน 19 ต.ค. 2569 ยังมีคีย์นี้ — อ่านไว้ให้ `CardStore.restore` เลือกชนิดใหม่ที่ตรงหน้าตาเดิม
     */
    @EncodeDefault(EncodeDefault.Mode.NEVER)
    var style: KitStyle = KitStyle.purple,
    var fill: KitFill = KitFill.solid,
    /** null = สีพื้นตั้งต้นของสไตล์ */
    var fillHex: String? = null,
    var corner: KitCorner = KitCorner.round,
    /** null = สีขอบตั้งต้นของสไตล์ */
    var borderHex: String? = null,
    /** ตัวเลือกเนื้อหาของหัวข้อ — คีย์ดูที่ `KitOpt` */
    var opts: Map<String, String> = emptyMap(),
) {
    val fillColor: String get() = fillHex ?: style.fill

    /** สีพื้นที่ใช้วาดจริง — มาจากพื้นหลังการ์ดตามโทนของสไตล์เสมอ (`KitStyle.cardToken`) · `fillHex` ในไฟล์รุ่นก่อนไม่ถูกใช้แล้ว */
    fun fillColor(theme: CardTheme): String = KitColor.resolve(style.cardToken, theme)

    /** ชุดเดียวกันที่สีพื้น/สีขอบถูกแปลงเป็น hex แล้ว — ส่งต่อให้ `KitLook` */
    fun resolved(theme: CardTheme): KitConfig =
        copy(fillHex = fillColor(theme), borderHex = KitColor.resolve(style.borderToken, theme))

    val borderColor: String get() = borderHex ?: style.border

    // MARK: ตัวเลือกเนื้อหา

    fun list(k: String): Set<String> =
        (opts[k] ?: "").split(",").filter { it.isNotEmpty() }.toSet()

    /** = `mutating func setList` ของ Swift — คืนสำเนา */
    fun setList(k: String, v: Set<String>): KitConfig {
        val m = opts.toMutableMap()
        if (v.isEmpty()) m.remove(k) else m[k] = v.sorted().joinToString(",")
        return copy(opts = m)
    }

    fun flag(k: String, default: Boolean): Boolean = opts[k]?.let { it == "1" } ?: default

    fun int(k: String, default: Int): Int = opts[k]?.toIntOrNull() ?: default
}

/** คีย์ของตัวเลือกเนื้อหา — ชุด "hide" เก็บของที่ **ซ่อน** ไม่ใช่ของที่โชว์ */
object KitOpt {
    const val hide = "hide"
    const val chan = "chan"
    const val mode = "mode"
    const val count = "count"
    const val caption = "cap"
    const val qr = "qr"
}

// MARK: - สีจาก hex

private fun hexInt(hex: String): Long = hex.trim('#').toLongOrNull(16) ?: 0x888888L

/** "#RRGGBB" → Color · ค่าผิดรูปแบบได้เทา (= `Color(kitHex:)`) */
fun Color.Companion.kitHex(hex: String): Color {
    val n = hexInt(hex)
    return rgb(((n shr 16) and 0xFF) / 255.0, ((n shr 8) and 0xFF) / 255.0, (n and 0xFF) / 255.0)
}

object KitColor {
    /** ความสว่างที่ตารับรู้ 0…1 — ใช้ตัดสินว่าพื้นนี้ต้องใช้หมึกขาวหรือดำ */
    fun lum(hex: String): Double {
        val n = hexInt(hex)
        val r = ((n shr 16) and 0xFF).toDouble(); val g = ((n shr 8) and 0xFF).toDouble(); val b = (n and 0xFF).toDouble()
        return (0.299 * r + 0.587 * g + 0.114 * b) / 255
    }
    fun dark(hex: String): Boolean = lum(hex) < 0.45

    /** ผสมสีไปทางขาว (t > 0) หรือดำ (t < 0) */
    fun shade(hex: String, t: Double): Color {
        val n = hexInt(hex)
        val c = listOf(((n shr 16) and 0xFF).toDouble(), ((n shr 8) and 0xFF).toDouble(), (n and 0xFF).toDouble()).map { it / 255 }
        val to = if (t >= 0) 1.0 else 0.0
        val k = abs(t)
        val m = c.map { it + (to - it) * k }
        return rgb(m[0], m[1], m[2])
    }

    /**
     * สีพื้นที่ให้เลือกในถาด — **มาจากพื้นหลังการ์ด** ไม่ใช่ชุดสีตายตัว (ผู้ใช้ 12 ต.ค. 2569)
     * เก็บเป็น *โทเคน* ("card", "card+1" …) ไม่ใช่ hex — เปลี่ยนพื้นหลังการ์ดทีหลัง widget เปลี่ยนตามเอง
     */
    fun cardFills(theme: CardTheme): List<String> {
        var out = listOf("card", "card+1", "card+2", "card-1", "card-2", "card2", "accent")
        if (theme.activeDuo != null) out = out + listOf("duoDark", "duoLight")
        // ตัดตัวที่ได้สีซ้ำกัน (การ์ดสีเดียวไม่มีไล่สี · สีเน้นตรงกับพื้น)
        val seen = mutableSetOf<String>()
        return out.filter { seen.add(resolve(it, theme).uppercase()) }
    }

    /** โทเคน → hex ตามธีมของการ์ดตอนนี้ · hex ตรง ๆ (ไฟล์เก่า) ผ่านไปเหมือนเดิม */
    fun resolve(token: String, theme: CardTheme): String {
        if (token.startsWith("#")) return token
        val card = hex(theme.backdropColors.top)
        return when (token) {
            "card" -> card
            "card+1" -> hex(shade(card, 0.35))
            "card+2" -> hex(shade(card, 0.72))
            "card+3" -> hex(shade(card, 0.92))
            "card-1" -> hex(shade(card, -0.35))
            "card-2" -> hex(shade(card, -0.62))
            "card-3" -> hex(shade(card, -0.84))
            "card2" -> hex(theme.backdropColors.bottom)
            "accent" -> hex(theme.rawAccent)
            "duoDark" -> theme.duoDark?.let { hex(it) } ?: card
            "duoLight" -> theme.duoLight?.let { hex(it) } ?: card
            else -> card
        }
    }

    fun hex(c: Color): String {
        fun n(v: Float): Int = (v.coerceIn(0f, 1f) * 255).roundToInt()
        return "#%02X%02X%02X".format(n(c.red), n(c.green), n(c.blue))
    }

    /** สีขอบที่ให้เลือก */
    val borders = listOf("#141414", "#FFFFFF", "#5AC8F0", "#E5322D", "#D4D4D8", "#B57EF7")
}

// MARK: - ส่งลงไปทาง CompositionLocal (= `EnvironmentValues` ของ iOS)

/** หน้าตาของชิ้นในชุดห้าสไตล์ที่กำลังวาด — ตั้งที่ `WidgetChrome` (= `\.kitConfig`) */
val LocalKitConfig = compositionLocalOf { KitConfig() }

/** true เฉพาะตอน `KitMeasure` วัดความสูงตั้งต้น — รูปโปรไฟล์ขอขนาดตามความกว้าง (= `\.kitMeasuring`) */
val LocalKitMeasuring = compositionLocalOf { false }

/** กรอบแนวนอน (กว้างเกินสูงชัด ๆ) — ผลงานเรียง 3 คอลัมน์แถวเดียวแทน 2 คอลัมน์หลายแถว (= `\.kitWide`) */
val LocalKitWide = compositionLocalOf { false }

// MARK: - ชนิดในชุด

/** ชุดห้าสไตล์ (`widget.kit`) — เช็คทีเดียวแทนไล่ทุก switch */
val WidgetKind.isKit: Boolean get() = meta.kit != null

/** หน้าตาของใบ (`widget.kit.look`) — ไม่ใส่ = ม่วง */
val WidgetKind.kitStyle: KitStyle get() = KitStyle.from(meta.kit?.look) ?: KitStyle.purple

/** ชุดเดียวกันในหน้าตาของชนิด `kind` */
fun KitConfig.looking(kind: WidgetKind): KitConfig = copy(style = kind.kitStyle)

/** หัวข้อตั้งต้นตาม Canva = ชื่อในตู้ — ผู้ใช้แตะแก้ได้ (เก็บต่อชิ้นที่ `.note` ช่อง 1) */
val WidgetKind.kitTitle: String? get() = if (isKit) title else null

/** แถวเนื้อหาในถาดของชุด (`widget.kit.controls`) */

// MARK: - หน้าตาที่คำนวณแล้วของชิ้นหนึ่ง (= `struct KitLook` ต้นไฟล์ Views/Widgets/KitWidgets.swift — เฉพาะคณิตสี)

class KitLook(c: KitConfig, border: Boolean, cardDark: Boolean) {
    val style: KitStyle = c.style
    val fill: KitFill = c.fill
    val fillHex: String = c.fillColor
    val bordered: Boolean = border
    val borderHex: String = c.borderColor
    val square: Boolean = c.corner == KitCorner.square && border
    /** พื้นใต้เนื้อหามืด — ตัดสินสีหมึกทั้งใบ · กรอบตาราง: เนื้อหาอยู่บนการ์ดขาวด้านในเสมอ · โปร่ง = ตามพื้นการ์ด */
    val dark: Boolean =
        if (c.style == KitStyle.gingham) false else (if (c.fill == KitFill.clear) cardDark else KitColor.dark(c.fillColor))

    val radius: Float get() = if (square) 3f else style.radius
    val ink: Color get() = if (dark) grey(0.96) else rgb(0.08, 0.08, 0.09)
    val mut: Color get() = if (dark) Color.White.opacity(0.6) else Color.Black.opacity(0.52)
    val borderColor: Color get() = Color.kitHex(borderHex)

    /** สีตัวเลขเด่น — กลางคืนใช้สีขอบ · Mac ใช้น้ำเงินของระบบ · ที่เหลือใช้หมึก */
    val accent: Color
        get() = when (style) {
            // พื้นสว่าง + ขอบสีอ่อน (ฟ้านีออนบนเหลือง) = ตัวเลขอ่านไม่ออก → ใช้สีขอบเฉดเข้มแทน
            KitStyle.night ->
                if (bordered) (if (dark || KitColor.lum(borderHex) < 0.5) borderColor else KitColor.shade(borderHex, -0.55))
                else (if (dark) Color.kitHex("#5AC8F0") else Color.kitHex("#0E7FB0"))
            KitStyle.mac -> if (dark) Color.kitHex("#6AA8FF") else Color.kitHex("#2F6FE4")
            else -> ink
        }

    /** สีหัวข้อที่ระบบแนะนำ — ผู้ใช้เลือกทับได้ในแถบแก้ข้อความ */
    val title: Color
        get() = when (style) {
            KitStyle.gingham -> rgb(0.07, 0.07, 0.07)
            KitStyle.cream -> if (dark) ink else rgb(0.17, 0.17, 0.17)
            KitStyle.mac -> if (dark) grey(0.9) else grey(0.29)
            else -> ink
        }

    /** พื้นของแผ่น (= `AnyShapeStyle` ของ Swift → `Brush`) */
    val background: Brush
        get() = when (fill) {
            KitFill.solid -> SolidColor(Color.kitHex(fillHex))
            KitFill.gradient -> Brush.linearGradient(
                colors = listOf(KitColor.shade(fillHex, 0.25), KitColor.shade(fillHex, -0.22)),
                start = Offset.Zero, end = Offset.Infinite,
            )
            KitFill.clear -> SolidColor(Color.Transparent)
        }

    /** กล่องย่อยข้างในแผ่น — แต่ละสไตล์ตีความไม่เหมือนกัน */
    val blockFill: Color
        get() = when (style) {
            KitStyle.purple -> Color.White
            KitStyle.cream ->
                if (fill == KitFill.clear) (if (dark) Color.White.opacity(0.08) else Color.White.opacity(0.7))
                else (if (dark) KitColor.shade(fillHex, 0.08) else KitColor.shade(fillHex, 0.55))
            KitStyle.gingham -> grey(0.95)
            KitStyle.night -> if (dark) Color.White.opacity(0.035) else Color.Black.opacity(0.04)
            KitStyle.mac -> if (dark) Color.White.opacity(0.08) else grey(0.93)
        }
    val blockLine: Color
        get() = when (style) {
            KitStyle.night -> if (bordered) borderColor.opacity(0.3) else (if (dark) Color.White.opacity(0.1) else Color.Black.opacity(0.1))
            else -> Color.Black.opacity(0.08)
        }
    /** หมึกในกล่องย่อย — ม่วงสติกเกอร์มีกล่องขาวเสมอ หมึกในกล่องจึงเป็นถ่านทุกพื้น */
    val blockInk: Color get() = if (style == KitStyle.purple || style == KitStyle.gingham) rgb(0.08, 0.08, 0.09) else ink
    val blockMut: Color get() = if (style == KitStyle.purple || style == KitStyle.gingham) Color.Black.opacity(0.52) else mut
    val hair: Color get() = if (dark) Color.White.opacity(0.1) else Color.Black.opacity(0.09)
}

/** ไอคอนต่อสายงาน — = `KitNiche` ของ iOS (Views/Widgets/Primitives/KitLook.swift) */
object KitNiche {
    /** ตัดอีโมจิหน้าชื่อหมวด ("👗 แฟชั่น" → "แฟชั่น") — Canva แสดงคำล้วน ไอคอนมาจากสไตล์ */
    fun clean(c: String): String {
        var i = 0
        while (i < c.length) {
            val cp = c.codePointAt(i)
            if (Character.isLetter(cp) && cp < 0x2000) break
            i += Character.charCount(cp)
        }
        return c.substring(i).trim()
    }
}
