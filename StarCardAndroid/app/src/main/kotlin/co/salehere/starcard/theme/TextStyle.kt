package co.salehere.starcard.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFontFamilyResolver
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import co.salehere.starcard.model.ProfileField
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min

// MARK: - หน้าตาของตัวอักษรบนวิดเจ็ตข้อความ (= Theme/TextStyle.swift)
//
// สไตล์เก็บที่ "ชิ้น" ไม่ใช่ที่ "ตระกูล" — หน้าตาไม่ใช่เนื้อหา มันคือของชุดเดียวกับ `surface`/`border`
// ไม่เปิดให้ใส่ฟอนต์/สีอิสระ — ชุดที่ให้เลือกเป็น **โทเคน** ที่ถูกจูนมาแล้วทั้งพื้นมืดและพื้นกระดาษ

/**
 * ฟอนต์ที่เลือกได้ — ทุกตัวต้องอ่านภาษาไทยออก
 * `noto` กับ `mitr` มาในแอป · สุขุมวิท/ธนบุรี/กรุงเทพเป็นฟอนต์ของ iOS — Android ไม่มี จึงตกกลับไปที่ `noto` เสมอ
 */
enum class CardFont(val raw: String) {
    noto("noto"), mitr("mitr"), sukhumvit("sukhumvit"), thonburi("thonburi"), krungthep("krungthep"),
    rounded("rounded"), serif("serif");

    val displayName: String
        get() = when (this) {
            noto -> "มาตรฐาน"
            mitr -> "มิตร"
            sukhumvit -> "สุขุมวิท"
            thonburi -> "ธนบุรี"
            krungthep -> "กรุงเทพ"
            rounded -> "มน"
            serif -> "เซริฟ"
        }

    /** ฟอนต์นี้มีอยู่จริงบนเครื่องนี้ไหม — ตัวที่ไม่มีตกกลับไปที่ฟอนต์หลักของแอป (= `resolved`) */
    val isAvailable: Boolean get() = this == noto || this == mitr || this == rounded || this == serif

    /** ตระกูลฟอนต์ที่ใช้จริง — ที่หาไม่เจอตกกลับไป NotoSansThai เสมอ */
    val family: FontFamily
        get() = when (this) {
            mitr -> SHFont.mitr
            rounded -> FontFamily.SansSerif
            serif -> FontFamily.Serif
            noto, sukhumvit, thonburi, krungthep -> SHFont.family
        }

    /**
     * ฟอนต์ที่ขนาด/น้ำหนักนี้ — ใช้เป็น `style` ของ `Text`
     * มิตรมีน้ำหนักเดียว — หนาไม่ขึ้นดีกว่าตกไปฟอนต์อื่นกลางประโยค (iOS ก็ทิ้งน้ำหนักเหมือนกัน)
     */
    fun font(size: Float, weight: FontWeight = FontWeight.Normal): TextStyle = when (this) {
        mitr -> sh(size, FontWeight.Normal, family = SHFont.mitr)
        rounded -> systemFont(size, weight)
        serif -> systemFont(size, weight, serif = true)
        noto, sukhumvit, thonburi, krungthep -> sh(size, weight)
    }

    companion object {
        fun from(raw: String?): CardFont? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * สีตัวอักษร — โทเคน ไม่ใช่ hex อิสระ
 * สามตัวแรกล้อการ์ด (พลิกตามหมึกให้เอง) · ที่เหลือเป็นสีคงที่ที่ถูกดันลงมาให้อ่านออกบนกระดาษด้วย `onLightSurface()`
 */
enum class TextTint(val raw: String) {
    ink("ink"), soft("soft"), accent("accent"), white("white"), black("black"),
    rose("rose"), coral("coral"), gold("gold"), mint("mint"), sky("sky"), lavender("lavender");

    val displayName: String
        get() = when (this) {
            ink -> "ตามหมึก"
            soft -> "จาง"
            accent -> "สีเน้น"
            white -> "ขาว"
            black -> "ดำ"
            rose -> "ชมพู"
            coral -> "ส้ม"
            gold -> "ทอง"
            mint -> "เขียว"
            sky -> "ฟ้า"
            lavender -> "ม่วง"
        }

    /** สีดิบของโทเคนที่เป็นสีคงที่ — ใช้ทั้งตอนวาดจริงและตอนวาดวงกลมในแผงเลือก (= `raw` ของ Swift · ชื่อชนกับ `raw: String`) */
    private val rawColor: Color?
        get() = when (this) {
            white -> Color.White
            black -> grey(0.08)
            rose -> Palette.rose.accent
            coral -> Palette.coral.accent
            gold -> Palette.champagne.accent
            mint -> Palette.mint.accent
            sky -> Palette.sky.accent
            lavender -> Palette.lavender.accent
            else -> null
        }

    /**
     * สีที่วาดจริงบนการ์ด — **อ่านออกบนพื้นเสมอ** (ดู Legibility.kt)
     * - `large`: ตัวอักษรใหญ่พอให้ใช้เกณฑ์ตัวใหญ่ (3:1)
     */
    fun color(ink: InkStyle, accent: Color, large: Boolean = false): Color {
        val target = if (large) Legibility.large else Legibility.body
        return when (this) {
            TextTint.ink -> ink.text(0.92)
            soft -> ink.text(0.55)
            TextTint.accent -> accent.legible(ink.ground, target, !ink.isLight)
            else -> {
                val c = rawColor ?: return ink.text(0.92)
                // ขาว/ดำเลือกมาเพื่อ "ขาว" หรือ "ดำ" จริง ๆ — ห้ามขยับสี · อ่านออกได้ด้วยเงากันจมแทน (ดู `halo`)
                if (this == white || this == black) return c
                (if (ink.isLight) c.onLightSurface() else c).legible(ink.ground, target, !ink.isLight)
            }
        }
    }

    /**
     * เงากันจมของขาว/ดำที่ผู้ใช้เลือกเจาะจง — null เมื่ออ่านออกอยู่แล้ว
     * ยิ่งจมมากเงายิ่งเข้ม · การ์ดพื้นมืดที่ใช้ตัวขาวจึงหน้าตาเหมือนเดิมทุกประการ
     */
    fun halo(ink: InkStyle, large: Boolean = false): Color? {
        if (this != white && this != black) return null
        val c = rawColor ?: return null
        val target = if (large) Legibility.large else Legibility.body
        val have = ink.ground.contrast(RGB(c).luminance)
        if (have >= target) return null
        val short = min(1.0, (target - have) / (target - 1))
        return (if (this == white) Color.Black else Color.White).opacity(0.3 + 0.45 * short)
    }

    /** สีที่โชว์ในแผงเครื่องมือ (พื้นมืดคงที่) — สามตัวแรกไม่มีสีของตัวเอง จึงต้องยืมของธีมมา */
    fun swatch(accent: Color): Color = when (this) {
        ink -> Color.White
        soft -> Color.White.opacity(0.45)
        TextTint.accent -> accent
        else -> rawColor ?: Color.White
    }

    companion object {
        fun from(raw: String?): TextTint? = entries.firstOrNull { it.raw == raw }
    }
}

/** ขนาดตัวอักษร — สี่ขั้น ไม่ใช่สไลเดอร์ต่อเนื่อง · ขั้นบันไดคุมสัดส่วนทั้งการ์ดไว้ได้ */
enum class TextScale(val raw: String) {
    small("small"), medium("medium"), large("large"), huge("huge");

    val displayName: String
        get() = when (this) {
            small -> "เล็ก"
            medium -> "กลาง"
            large -> "ใหญ่"
            huge -> "ยักษ์"
        }

    val size: Float
        get() = when (this) {
            small -> 13f
            medium -> 17f
            large -> 26f
            huge -> 40f
        }

    /** น้ำหนักไต่ตามขนาด — ตัวเล็กบางเกินไปอ่านไม่ออก ตัวยักษ์ที่บางอ่านเป็นหัวเรื่อง */
    val weight: FontWeight
        get() = when (this) {
            small, medium -> SHFont.medium
            large -> SHFont.semibold
            huge -> SHFont.bold
        }

    /** ระยะบรรทัด — ตัวใหญ่ต้องการช่องไฟเป็นสัดส่วนที่น้อยลง */
    val lineSpacing: Float
        get() = when (this) {
            small -> 4f
            medium -> 5f
            large -> 4f
            huge -> 0f
        }

    companion object {
        fun from(raw: String?): TextScale? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * การจัดวางข้อความ (= `TextAlign` ของ Swift — เปลี่ยนชื่อเพราะชนกับ `androidx.compose.ui.text.style.TextAlign`)
 */
enum class TextAlignment(val raw: String) {
    leading("leading"), center("center"), trailing("trailing");

    val displayName: String
        get() = when (this) {
            leading -> "ซ้าย"
            center -> "กลาง"
            trailing -> "ขวา"
        }

    /** ชื่อ SF Symbol (วาดผ่าน `SFSymbol`) */
    val icon: String
        get() = when (this) {
            leading -> "text.alignleft"
            center -> "text.aligncenter"
            trailing -> "text.alignright"
        }

    /** `multilineTextAlignment` → `textAlign` ของ `Text` */
    val text: androidx.compose.ui.text.style.TextAlign
        get() = when (this) {
            leading -> androidx.compose.ui.text.style.TextAlign.Start
            center -> androidx.compose.ui.text.style.TextAlign.Center
            trailing -> androidx.compose.ui.text.style.TextAlign.End
        }

    /** จุดยึดในกรอบ — ชิดบนเสมอ */
    val frame: Alignment
        get() = when (this) {
            leading -> Alignment.TopStart
            center -> Alignment.TopCenter
            trailing -> Alignment.TopEnd
        }

    /** จุดยึดในกล่อง — กลางแนวตั้งเสมอ (กล่องที่สูงกว่าข้อความต้องอ่านเป็น "จงใจเว้น") */
    val centered: Alignment
        get() = when (this) {
            leading -> Alignment.CenterStart
            center -> Alignment.Center
            trailing -> Alignment.CenterEnd
        }

    companion object {
        fun from(raw: String?): TextAlignment? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * ขั้นขนาดตัวอักษร **ของช่องหนึ่งช่อง** — คูณกับขนาดที่ดีไซน์ตั้งไว้ให้ช่องนั้น
 * เป็นตัวคูณ ไม่ใช่ pt เพราะ `M` ต้องแปลว่า *ขนาดที่ดีไซน์ตั้งใจ* เสมอ ไม่ว่าจะเป็นชื่อ 28pt หรือสายงาน 9.5pt
 */
enum class WidgetTextSize(val raw: String) {
    xs("xs"), s("s"), m("m"), l("l"), xl("xl"), xxl("xxl");

    /** ป้ายบนถาด — สั้นพอให้หกขั้นอยู่ในแถวเดียว */
    val label: String get() = raw.uppercase()

    /** ช่วงกว้างจริง — ไล่แบบเรขาคณิต (คูณ ~1.3 ต่อขั้น) สายตาจึงอ่านออกว่าทุกขั้นเป็นคนละขนาด */
    val factor: Float
        get() = when (this) {
            xs -> 0.60f
            s -> 0.78f
            m -> 1.00f
            l -> 1.30f
            xl -> 1.70f
            xxl -> 2.20f
        }

    companion object {
        fun from(raw: String?): WidgetTextSize? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * หน้าตาตัวอักษรของ widget หนึ่งชิ้น — เก็บอยู่ใน `WidgetInstance` คู่กับ `surface`/`border`
 * สามชุด `slot*` เก็บ "เฉพาะช่องที่ถูกสั่งทับ" — ไม่มีคีย์ = **ตามที่ดีไซน์เลือกไว้**
 */
data class WidgetTextStyle(
    val face: CardFont = CardFont.noto,
    val tint: TextTint = TextTint.ink,
    /** ขั้นขนาดแบบเก่า — เหลือไว้อ่านไฟล์รุ่นก่อน (ดู `CardStore`) ตัววาดไม่ใช้แล้ว */
    val scale: TextScale = TextScale.medium,
    val align: TextAlignment = TextAlignment.leading,
    /** ขนาดตัวอักษรของก้อนข้อความ (pt) — ปรับต่อเนื่องด้วยหมุดมุม ไม่ใช่ขั้นบันได */
    val points: Float = 28f,
    val slotFaces: Map<String, CardFont> = emptyMap(),
    val slotTints: Map<String, TextTint> = emptyMap(),
    /** ขั้นขนาด **ของแต่ละช่อง** — ไม่มีคีย์ = `m` (ขนาดที่ดีไซน์ตั้งไว้) */
    val slotSizes: Map<String, WidgetTextSize> = emptyMap(),
) {
    fun size(field: ProfileField, index: Int? = null): WidgetTextSize =
        slotSizes[slotKey(field, index)] ?: WidgetTextSize.m

    /** `null` = ตามดีไซน์ */
    fun face(field: ProfileField, index: Int? = null): CardFont? =
        slotFaces[slotKey(field, index)]

    /** `null` = ตามดีไซน์ */
    fun tint(field: ProfileField, index: Int? = null): TextTint? =
        slotTints[slotKey(field, index)]

    /** ฟอนต์จริงของช่องที่ดีไซน์สั่งมาเป็น `size`/`weight` — ผ่านฟอนต์และขั้นขนาดของช่องนั้นแล้ว */
    fun font(
        size: Float,
        weight: FontWeight = FontWeight.Normal,
        field: ProfileField,
        index: Int? = null,
    ): TextStyle = (face(field, index) ?: CardFont.noto).font(scaled(size, field, index), weight)

    /** สีของช่องนั้น — คืนสีที่ดีไซน์ตั้งไว้ (null) ถ้าเจ้าของการ์ดยังไม่ได้เลือกสีให้ช่องนี้ */
    @Suppress("UNUSED_PARAMETER")
    fun color(
        design: Color,
        field: ProfileField,
        index: Int? = null,
        ink: InkStyle,
        accent: Color,
    ): Color? = tint(field, index)?.color(ink, accent)

    /** ขนาดหลังคูณขั้นของช่องนั้น — คุมปลายทั้งสองข้างไว้ (ล่าง 6pt · บน 160pt) */
    fun scaled(size: Float, field: ProfileField, index: Int? = null): Float =
        min(max(size * this.size(field, index).factor, 6f), 160f)

    companion object {
        /** คีย์ของช่องหนึ่งช่องในชิ้น — ฟิลด์ + ลำดับ */
        fun slotKey(field: ProfileField, index: Int? = null): String =
            if (index != null) "${field.raw}#$index" else field.raw
    }
}

/**
 * สไตล์ตัวอักษรของชิ้นที่กำลังวาดอยู่ — ส่งลงมาจาก `WidgetChrome` ทางเดียวกับ `LocalWidgetID` (= `\.widgetTextStyle`)
 * พรีวิวในตู้กับ thumb ไม่มีชิ้นจริงให้อ่าน จึงได้ค่าตั้งต้นไป
 */
val LocalWidgetTextStyle = compositionLocalOf { WidgetTextStyle() }

// MARK: - ตัวอักษรขยายเต็มกล่อง

/**
 * วัดก้อนข้อความ — **ไม่ตัดบรรทัดเอง** บรรทัดใหม่มีเฉพาะที่ผู้ใช้กด Return
 * วัดด้วย `TextMeasurer` ตัวเดียวกับที่ `Text` ใช้วาง — ใช้ตัวจาก `rememberMeasurer()` (density 1) ผลจึงเป็นหน่วยออกแบบตรง ๆ
 */
object TextFit {
    /** ช่องไฟระหว่างบรรทัดเป็นสัดส่วนของขนาด */
    const val spacing: Float = 0.10f
    const val minSize: Float = 9f
    const val maxSize: Float = 200f
    /** ขนาดตอนพิมพ์ — **เท่ากันทุกก้อน** ไม่ว่าบนการ์ดจะย่อไว้จิ๋วหรือขยายไว้ยักษ์ (ท่าเดียวกับ Story) */
    const val editSize: Float = 28f

    data class Metrics(
        /** กล่องตามตัวพิมพ์ (line box) — สูงตามฟอนต์ เผื่อสระบน/ล่างไว้เสมอแม้ไม่มี */
        val typo: Size,
        /** กล่องตาม **หมึก** ในพิกัดของ `typo` (จุดกำเนิดมุมบนซ้าย) — Compose ให้แค่กรอบบรรทัด จึงเป็นสหภาพของกรอบบรรทัด */
        val ink: Rect,
    )

    /**
     * ตัววัดที่ density = 1 · fontScale = 1 — px ที่วัดได้ = pt ของดีไซน์ (แอปตรึง fontScale ไว้ที่รากอยู่แล้ว)
     * ส่ง `rememberTextMeasurer()` ธรรมดามาแทนเมื่อไหร่ ผลจะเป็น px ของเครื่อง
     */
    @Composable
    fun rememberMeasurer(): TextMeasurer {
        val resolver = LocalFontFamilyResolver.current
        return remember(resolver) { TextMeasurer(resolver, Density(1f, 1f), LayoutDirection.Ltr, cacheSize = 32) }
    }

    private class LineBox(val w: Float, val h: Float, val ink: Rect?)

    /**
     * วัดสองกล่อง — วางบรรทัดแบบเดียวกับที่ `Text` วาง: สูงตามฟอนต์ · คั่นด้วย `spacing`
     * บรรทัดสั้นเลื่อนตามการจัดวางในความกว้างของบรรทัดที่ยาวที่สุด
     */
    fun metrics(
        measurer: TextMeasurer,
        text: String,
        face: CardFont,
        weight: FontWeight,
        size: Float,
        align: TextAlignment,
    ): Metrics {
        val style = face.font(size, weight)
        val gap = size * spacing
        val lines = if (text.isEmpty()) listOf(" ") else text.split("\n")
        val rows = ArrayList<LineBox>(lines.size)
        var maxW = 0f
        for (l in lines) {
            val r = measurer.measure(
                text = AnnotatedString(if (l.isEmpty()) " " else l),
                style = style,
                softWrap = false,
                maxLines = 1,
                constraints = Constraints(),
            )
            val w = r.size.width.toFloat()
            val top = r.getLineTop(0)
            val bottom = r.getLineBottom(0)
            val left = r.getLineLeft(0)
            val right = r.getLineRight(0)
            val ink = if (right > left && bottom > top) Rect(left, top, right, bottom) else null
            rows += LineBox(w, bottom - top, ink)
            maxW = max(maxW, w)
        }
        val typoW = ceil(maxW)
        var y = 0f
        var ink: Rect? = null
        rows.forEachIndexed { i, r ->
            val x0 = when (align) {
                TextAlignment.leading -> 0f
                TextAlignment.center -> (typoW - r.w) / 2f
                TextAlignment.trailing -> typoW - r.w
            }
            r.ink?.let { b ->
                val rect = Rect(x0 + b.left, y + b.top, x0 + b.right, y + b.bottom)
                ink = ink?.let { union(it, rect) } ?: rect
            }
            y += r.h + (if (i < rows.size - 1) gap else 0f)
        }
        val typo = Size(typoW, ceil(y))
        // ช่องว่างล้วนไม่มีหมึก — ตกไปใช้ line box ไม่งั้นกล่องยุบเหลือศูนย์
        val box = ink ?: Rect(0f, 0f, typo.width, typo.height)
        return Metrics(typo, Rect(floor(box.left), floor(box.top), ceil(box.right), ceil(box.bottom)))
    }

    /** ขนาดธรรมชาติของข้อความที่ขนาดฟอนต์หนึ่ง — ไม่จำกัดความกว้าง ไม่ตัดบรรทัด (line box) */
    fun natural(measurer: TextMeasurer, text: String, face: CardFont, weight: FontWeight, size: Float): Size =
        metrics(measurer, text, face, weight, size, TextAlignment.leading).typo

    /**
     * ขนาดที่ใช้จริง — เท่าที่ตั้งไว้ เว้นแต่บรรทัดที่ยาวที่สุดจะล้น `maxWidth` แล้วจึงหดลงพอดี
     * ล้นหน้าคือกรณีเดียวที่ระบบแตะขนาดแทนผู้ใช้ — และแตะแค่ชั่วคราว
     */
    fun capped(
        measurer: TextMeasurer,
        points: Float,
        text: String,
        face: CardFont,
        weight: FontWeight,
        maxWidth: Float,
    ): Float {
        val p = min(max(points, minSize), maxSize)
        if (maxWidth <= 4f) return p
        val w = natural(measurer, text, face, weight, p).width
        if (w <= maxWidth) return p
        return max(minSize, floor(p * maxWidth / w))
    }

    private fun union(a: Rect, b: Rect): Rect =
        Rect(min(a.left, b.left), min(a.top, b.top), max(a.right, b.right), max(a.bottom, b.bottom))
}
