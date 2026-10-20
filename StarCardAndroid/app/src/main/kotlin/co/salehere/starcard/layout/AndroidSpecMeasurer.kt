package co.salehere.starcard.layout

import android.graphics.Paint
import android.graphics.Typeface
import android.text.TextPaint
import android.text.TextUtils
import androidx.compose.ui.text.font.FontWeight
import androidx.core.content.res.ResourcesCompat
import co.salehere.starcard.AppContext
import co.salehere.starcard.R
import kotlin.math.ceil
import kotlin.math.max

// MARK: - ตัววัดข้อความ (Android) (= `IOSSpecMeasurer` ท้าย Views/Widgets/SpecPainter.swift)
//
// # ทำไมไม่ใช้ TextMeasurer ของ Compose
//
// TextMeasurer วัดเป็น **พิกเซลเต็ม** ตามความหนาแน่นของจอ — ความกว้าง 0.38 dp หายไปทุกครั้งที่ปัด
// แล้วตัวคำนวณที่เทียบ `> width + 0.01` ก็ตัดสินใจคนละทางกับ iOS (CoreText วัดเป็นทศนิยม)
//
// ตัวนี้วัดแบบเดียวกับ iOS: ฟอนต์ **ไฟล์เดียวกัน** (res/font = Resources/Fonts) ที่ขนาดหน่วยออกแบบตรง ๆ
// (ไม่คูณความหนาแน่น) · ระยะรายตัวแปลงกลับเป็นหน่วยฟอนต์แล้วบวกแบบ CoreText (`advance`) · ตัดบรรทัดแบบโลภ (`breakParagraph`
// = CoreText word wrap) ไม่ตัดยัติภังค์ · ความกว้างปัดขึ้น 2 ทศนิยม · ความสูง = จำนวนบรรทัด × ความสูงบรรทัด
//
// ตัววาด (`SpecPainter`) ใช้ `breakLines` ตัวเดียวกันนี้ส่งบรรทัดที่ตัดแล้วให้ `Text` —
// บรรทัดที่วาดจึงเป็นบรรทัดที่วัดเสมอ ไม่ปล่อยให้ Compose ตัดบรรทัดเองอีกรอบ

/** น้ำหนัก 100–900 → `FontWeight` (= `Font.Weight.from`) */
fun weightOf(w: Int): FontWeight = when {
    w < 200 -> FontWeight.W100
    w < 300 -> FontWeight.W200
    w < 400 -> FontWeight.W300
    w < 500 -> FontWeight.W400
    w < 600 -> FontWeight.W500
    w < 700 -> FontWeight.W600
    w < 800 -> FontWeight.W700
    w < 900 -> FontWeight.W800
    else -> FontWeight.W900
}

/**
 * ไฟล์ฟอนต์ของน้ำหนักนี้ — ตารางเดียวกับ `SHFont.name` ของ iOS ผ่าน `Font.Weight.from`
 * (< 400 = Light · 400 Regular · 500 Medium · 600 SemiBold · 700 Bold · 800 ExtraBold · 900 Black)
 */
fun notoFontRes(weight: Int): Int = when {
    weight < 400 -> R.font.notosansthai_light
    weight < 500 -> R.font.notosansthai_regular
    weight < 600 -> R.font.notosansthai_medium
    weight < 700 -> R.font.notosansthai_semibold
    weight < 800 -> R.font.notosansthai_bold
    weight < 900 -> R.font.notosansthai_extrabold
    else -> R.font.notosansthai_black
}

object SpecTypefaces {
    private val cache = HashMap<Triple<String, Int, Boolean>, Typeface>()

    /**
     * Typeface ของ face + น้ำหนักในผัง — face ที่ไม่รู้จักตกไป `noto` (= `CardFont(rawValue:) ?? .noto`)
     * `italic`: iOS ขอ trait เอียงจากฟอนต์ — Noto/มิตรไม่มีตัวเอียงจริง จึงตั้งตรงเหมือนเดิม
     */
    fun get(face: String, weight: Int, italic: Boolean = false): Typeface = synchronized(cache) {
        cache.getOrPut(Triple(face, weight, italic)) {
            val ctx = AppContext.app
            fun res(id: Int) = ResourcesCompat.getFont(ctx, id) ?: Typeface.DEFAULT
            when (face) {
                // มิตรมีน้ำหนักเดียว (iOS ทิ้งน้ำหนักเหมือนกัน)
                "mitr" -> res(R.font.mitr_regular)
                // noto และ face เก่าที่ถอดออกแล้ว (serif · rounded · sukhumvit …) ตกไป noto
                else -> res(notoFontRes(weight))
            }
        }
    }
}

class AndroidSpecMeasurer : SpecMeasurer {
    private val paintCache = HashMap<SpecFont, TextPaint>()
    private val lineCache = HashMap<SpecFont, Double>()

    companion object {
        /**
         * วัดที่ขนาด ×K แล้วหารกลับ — ที่ขนาดเล็ก (14 px) Skia ยัง hint ระยะของตัวอักษรเป็นพิกเซลเต็ม แม้ตั้ง LINEAR
         * ผลคือทุกคำกว้างกว่า CoreText ราว 0.9% (วัดจริง 7,681 ครั้ง) · ที่ ×64 ยังปัดตัวละไม่เกินหนึ่งพิกเซล (+0.02pt ต่อสองตัว)
         * HarfBuzz เก็บระยะรายตัวเป็นจุดตรึง 1/64 พิกเซล (ปัดลง) — ที่ ×1024 ยังขาดตัวละ ~0.00001pt ซึ่งพลิกการปัด 0.01
         * ของคำที่กว้างพอดีเส้นแบ่ง · ที่ ×16384 ขาดตัวละ < 0.000001pt (textSize×64 ยังอยู่ใน int32 ถึงตัวอักษร 2,000pt)
         */
        const val K = 16384.0
    }

    /** สีไม่สำคัญ — ใช้วัดอย่างเดียว · ขนาด = หน่วยออกแบบ × K */
    fun paint(f: SpecFont): TextPaint = paintCache.getOrPut(f) {
        TextPaint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG or Paint.LINEAR_TEXT_FLAG).apply {
            typeface = SpecTypefaces.get(f.face, f.weight, f.italic)
            textSize = (f.size * K).toFloat()
            // ระยะตัวอักษร (`tracking` + `kerning`) **ไม่ใส่ที่ paint** — letterSpacing ของ Android เว้นกลุ่มอักษรตัวสุดท้าย
            // แต่ CoreText ใส่ทุกกลุ่มรวมตัวท้าย (เทียบ 152 คำ: สูตร "กว้างปกติ + ระยะ × จำนวนกลุ่มอักษร" คลาดกลาง 0.005pt)
            // จึงบวกเองใน `advance`
        }
    }

    /**
     * ความสูงหนึ่งบรรทัดของฟอนต์ (ไม่คูณ `lineHeight` ของผัง) = ascent + descent + leading
     * ฟอนต์ที่ฝังมา: คิดจาก **หน่วยฟอนต์จำนวนเต็ม** (hhea) × size/1000 แบบ iOS — `fontMetrics` เป็น float ที่คลาดเศษ
     * แล้วไปพลิกการปัดครึ่ง (มิตร 15.5pt = 24.335 → iOS 24.34) · ตรงกับ iOS 179/179 ค่า
     */
    private fun rawLine(font: SpecFont): Double {
        val f = font.copy(lineHeight = 1.0)
        val fm = paint(f).fontMetrics
        val per = f.size * K / 1000.0
        val sc = f.size / 1000.0
        // ascent × sc + descent × sc + leading × sc (ทีละส่วน — 55pt ได้ 83.10 แบบ iOS ไม่ใช่ 83.11 ของผลรวมหน่วยก่อนคูณ)
        return Math.round(-fm.ascent / per) * sc + Math.round(fm.descent / per) * sc + Math.round(fm.leading / per) * sc
    }

    /** = `(ui.lineHeight * font.lineHeight * 100).rounded() / 100` */
    override fun lineHeight(font: SpecFont): Double = lineCache.getOrPut(font) {
        SpecSolver.r2(rawLine(font) * font.lineHeight)
    }

    /** บรรทัดของ `text` ในความกว้าง `width` (null = ไม่จำกัด · ตัดที่ขึ้นบรรทัดใหม่เท่านั้น) */
    fun breakLines(text: String, font: SpecFont, width: Double?): List<String> =
        layoutLines(text, font, width).map { it.text }

    /** หนึ่งบรรทัดที่ตัดแล้ว — ข้อความ + ความกว้าง (หน่วยออกแบบ ตามที่ iOS วัด) */
    private class Line(val text: String, val width: Double)

    /**
     * ระยะรายตัวของ **ทั้งย่อหน้า** — CoreText จัดรูปอักษรทั้งย่อหน้าก่อนแล้วค่อยตัดบรรทัด ระยะของตัวท้ายบรรทัด
     * จึงยังรวม kerning กับตัวแรกของบรรทัดถัดไป ("Tarmjaip|a" มิตร 29pt: 118.67 ไม่ใช่ 119.40 ของการจัดรูปทีละบรรทัด)
     */
    private fun shape(para: String, f: SpecFont): FloatArray {
        val widths = FloatArray(para.length)
        if (para.isNotEmpty()) paint(f).getTextWidths(para, 0, para.length, widths)
        return widths
    }

    /**
     * ความกว้างของ `para[a, b)` เป็น **หน่วยออกแบบ** — เลียนเลขคณิตของ CoreText ตัวต่อตัว
     *
     * CoreText บวกระยะรายตัว `หน่วยฟอนต์ × (size / 1000)` แบบ double ทีละตัว (ตัวคูณคิดก่อน — สูตรนี้ตรง 3,974/3,976 คำ)
     * แล้ว iOS ปัด `ceil(w × 100) / 100` · ผลรวม double มีเศษ (5.72+5.72+8.52+… = 27.890000000000004) และเศษนั้น
     * พลิกการปัดเป็น 27.90 ทั้งที่ค่าจริงคือ 27.89 — Android ต้องได้เศษเดียวกันถึงจะปัดตรงกัน
     * ระยะรายตัวจาก `getTextWidths` (หลังจัดรูป รวม kerning แล้ว) จึงถูกแปลงกลับเป็นหน่วยฟอนต์จำนวนเต็มก่อน
     * (ฟอนต์ที่แอปฝังมา Noto Sans Thai · Mitr ใช้ 1000 หน่วยต่อ em) · ระยะตัวอักษร (`tracking` + `kerning`)
     * บวกต่อท้ายทุกตัวยกเว้นเครื่องหมายที่ไม่กินที่ (Mn · Me — สระบน/ล่าง วรรณยุกต์ · 149 คำ คลาดไม่เกิน 0.011pt)
     */
    private fun advance(para: String, widths: FloatArray, a: Int, b: Int, f: SpecFont): Double {
        if (b <= a) return 0.0
        val sp = f.tracking + f.kerning
        val scale = f.size / 1000.0
        var sum = 0.0
        var i = a
        while (i < b) {
            val cp = Character.codePointAt(para, i)
            val n = Character.charCount(cp)
            var wk = 0.0
            for (j in 0 until n) wk += widths[i + j]
            sum += Math.round(wk / (f.size * K) * 1000.0) * scale
            if (sp != 0.0) {
                val t = Character.getType(cp)
                if (t != Character.NON_SPACING_MARK.toInt() && t != Character.ENCLOSING_MARK.toInt()) sum += sp
            }
            i += n
        }
        return sum
    }

    /**
     * ตัดบรรทัดแบบโลภของ CoreText — ไม่ใช้ LineBreaker ของ Android ตรง ๆ เพราะ minikin มีกติกาพิเศษ
     * ของอีเมล/URL (ตัดหลัง `.` `@` ใน "@maneerat.review") ซึ่ง CoreText ไม่มี
     *
     * จุดตัดคำจาก ICU (`BreakIterator` แบบบรรทัด · พจนานุกรมไทย) → เติมคำลงบรรทัดจนเกินความกว้าง
     * (ไม่นับช่องว่างที่ห้อยท้าย) · คำเดียวยาวกว่าบรรทัด → ตัดทีละกลุ่มอักษร (grapheme) ให้ได้มากที่สุด
     * ความกว้างของแต่ละบรรทัด **นับ** ช่องว่างท้ายบรรทัด (= `boundingRect` ของ iOS: ", " = 8.73 ·
     * "BY SALE␠" ที่ถูกตัดบรรทัด = 45.32 รวมช่องว่างและระยะตัวอักษรของมัน)
     */
    private fun breakParagraph(para: String, f: SpecFont, width: Double?): List<Line> {
        val widths = shape(para, f)
        fun w(a: Int, b: Int): Double = advance(para, widths, a, b, f)
        if (para.isEmpty() || width == null) return listOf(Line(para, w(0, para.length)))
        // พอดีบรรทัด = กว้างไม่เกินบรรทัดเลย (ไม่มีส่วนเผื่อ) — CoreText ไม่ยอมให้เกินแม้ 0.01
        val limit = width + 1e-9
        fun fits(a: Int, b: Int): Boolean {
            var e = b
            while (e > a && para[e - 1].isWhitespace()) e--
            return w(a, e) <= limit
        }
        val words = android.icu.text.BreakIterator.getLineInstance(android.icu.util.ULocale("th"))
        words.setText(para)
        val stops = ArrayList<Int>()
        var x = words.first()
        while (x != android.icu.text.BreakIterator.DONE) { if (x > 0) stops.add(x); x = words.next() }
        val chars = android.icu.text.BreakIterator.getCharacterInstance(android.icu.util.ULocale("th"))
        chars.setText(para)
        val lines = ArrayList<Line>()
        var start = 0
        while (start < para.length) {
            var end = -1
            for (st in stops) {
                if (st <= start) continue
                if (fits(start, st)) end = st else break
            }
            if (end < 0) {
                // คำแรกของบรรทัดยาวกว่าบรรทัด — ตัดทีละกลุ่มอักษร (อย่างน้อยหนึ่งกลุ่ม)
                var g = chars.following(start)
                end = g
                while (g != android.icu.text.BreakIterator.DONE && g <= para.length && fits(start, g)) { end = g; g = chars.following(g) }
            }
            lines.add(Line(para.substring(start, end), w(start, end)))
            start = end
        }
        return lines
    }

    /** ย่อหน้าตาม '\n' (CoreText ตัดที่ขึ้นบรรทัดใหม่เสมอ) แล้วตัดคำในแต่ละย่อหน้า */
    private fun layoutLines(text: String, font: SpecFont, width: Double?): List<Line> =
        text.split('\n').flatMap { breakParagraph(it, font, width) }

    override fun measure(text: String, font: SpecFont, width: Double?): Pair<FSize, Int> {
        val lines = layoutLines(text, font, width)
        val n = max(1, lines.size)
        val w = lines.maxOfOrNull { it.width } ?: 0.0
        // = `ceil(r.width * 100) / 100` ของ iOS (เศษของ double ใน `advance` ตรงกับ CoreText แล้ว จึงไม่ต้องเผื่อ)
        return FSize(ceil(w * 100) / 100, n * lineHeight(font)) to n
    }

    /**
     * บรรทัดที่ตัววาดแสดง — `lines` บรรทัดแรกตามที่วัด · ถ้ายังเหลือ บรรทัดสุดท้ายรวมส่วนที่เหลือแล้วตัดท้ายด้วย …
     * (= `.lineLimit(lines).truncationMode(.tail)` ของ SwiftUI)
     */
    fun displayLines(text: String, font: SpecFont, width: Double, lines: Int): List<String> {
        val all = breakLines(text, font, width)
        val keep = max(1, lines)
        if (all.size <= keep) return all.map { it.trimEnd() }
        val head = all.take(keep - 1).map { it.trimEnd() }
        val rest = all.drop(keep - 1).joinToString("") { it }.replace('\n', ' ').trimEnd()
        val tail = TextUtils.ellipsize(rest, paint(font), (width * K).toFloat(), TextUtils.TruncateAt.END).toString()
        return head + tail
    }
}
