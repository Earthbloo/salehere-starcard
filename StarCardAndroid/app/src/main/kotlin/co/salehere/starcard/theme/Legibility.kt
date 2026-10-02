package co.salehere.starcard.theme

import androidx.compose.ui.graphics.Color
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

// MARK: - ตัวหนังสือต้องอ่านออกเสมอ (= Legibility.swift — เฉพาะส่วนคณิต · `PhotoLuma` อยู่ใน PhotoLuma.kt ของ model)
//
// กติกาข้อเดียว: สีที่เลือกคือ "คำขอ" — ระบบส่งสีที่ใกล้ที่สุดที่ยังอ่านออก
// เก็บเฉดไว้ ขยับแค่ความสว่าง · เกณฑ์คือ contrast ของ WCAG (ตัวหนังสือ 4.5:1 · ตัวใหญ่/ไอคอน 3:1)

object Legibility {
    /** ตัวหนังสือทั่วไป — WCAG AA */
    const val body: Double = 4.5
    /** ตัวใหญ่ · ไอคอน — WCAG AA ของตัวใหญ่ */
    const val large: Double = 3.0
    /** หมึกเต็มแรงบนรูป — ม่านถูกคำนวณให้ได้อย่างน้อยเท่านี้ในทุกช่องของรูป */
    const val photo: Double = 6.0
    /** ช่วงพื้นที่ตัวหนังสือเชื่อได้บนรูป — หย่อนกว่า `photo` ราวหนึ่งในสิบ */
    const val photoBound: Double = photo * 0.9

    /** sRGB (0…1) → ความสว่างเชิงเส้น */
    fun linear(v: Double): Double {
        val x = v.coerceIn(0.0, 1.0)
        return if (x <= 0.04045) x / 12.92 else ((x + 0.055) / 1.055).pow(2.4)
    }

    /** ความสว่างเชิงเส้น → sRGB */
    fun encoded(l: Double): Double {
        val x = l.coerceIn(0.0, 1.0)
        return if (x <= 0.0031308) x * 12.92 else 1.055 * x.pow(1 / 2.4) - 0.055
    }

    /** อัตราส่วน contrast ของ WCAG จากความสว่างสองค่า */
    fun ratio(a: Double, b: Double): Double = (max(a, b) + 0.05) / (min(a, b) + 0.05)

    /** เกณฑ์ของตัวหนังสือตามน้ำหนักที่ widget ขอ (`ink.text(l)`) */
    fun target(emphasis: Double): Double = when {
        emphasis >= 0.4 -> body
        emphasis >= 0.28 -> large
        else -> 1.0
    }

    /** ความสว่างหลังวางสีความสว่าง `top` ทึบ `alpha` ทับพื้นความสว่าง `under` — ผสมใน sRGB */
    fun composite(top: Double, alpha: Double, over: Double): Double {
        val a = alpha.coerceIn(0.0, 1.0)
        return linear(encoded(over) * (1 - a) + encoded(top) * a)
    }

    /**
     * ความทึบต่ำสุดของหมึกความสว่าง `ink` บนพื้นความสว่าง `ground` ที่ให้ contrast ถึง `target`
     * คืน 1 เมื่อทึบเต็มที่แล้วก็ยังไม่ถึง
     */
    fun alpha(ink: Double, over: Double, target: Double): Double {
        if (target <= 1) return 0.0
        val g = encoded(over); val b = encoded(ink)
        if (abs(b - g) <= 0.0001) return 1.0
        val goal: Double
        if (ink > over) {
            goal = target * (over + 0.05) - 0.05
            if (goal >= ink) return 1.0
        } else {
            goal = (over + 0.05) / target - 0.05
            if (goal <= ink) return 1.0
        }
        return ((encoded(goal) - g) / (b - g)).coerceIn(0.0, 1.0)
    }
}

// MARK: - สีเป็นตัวเลข

/** สี sRGB สามช่อง (0…1) — คิด contrast ได้โดยไม่ต้องวนผ่าน `Color` ทุกครั้ง */
data class RGB(val r: Double, val g: Double, val b: Double) {
    constructor(color: Color) : this(color.red.toDouble(), color.green.toDouble(), color.blue.toDouble())

    companion object {
        val white = RGB(1.0, 1.0, 1.0)
        val black = RGB(0.0, 0.0, 0.0)

        /** จาก HSB แบบเดียวกับ `hsb()` — ธีมเก็บสีพื้นเป็น HSB */
        fun fromHSB(hue: Double, saturation: Double, brightness: Double): RGB {
            val h6 = (hue - kotlin.math.floor(hue)) * 6
            val s = saturation.coerceIn(0.0, 1.0); val v = brightness.coerceIn(0.0, 1.0)
            val c = v * s
            val x = c * (1 - abs(h6 % 2 - 1))
            val m = v - c
            return when (h6.toInt()) {
                0 -> RGB(c + m, x + m, m)
                1 -> RGB(x + m, c + m, m)
                2 -> RGB(m, c + m, x + m)
                3 -> RGB(m, x + m, c + m)
                4 -> RGB(x + m, m, c + m)
                else -> RGB(c + m, m, x + m)
            }
        }
    }

    /** ความสว่างที่ตารับรู้ (WCAG relative luminance) */
    val luminance: Double
        get() = 0.2126 * Legibility.linear(r) + 0.7152 * Legibility.linear(g) + 0.0722 * Legibility.linear(b)

    val color: Color get() = rgb(r, g, b)

    /** ไล่เข้าหาอีกสี `t` (0…1) */
    fun mixed(o: RGB, t: Double): RGB = RGB(r + (o.r - r) * t, g + (o.g - g) * t, b + (o.b - b) * t)

    /** สีนี้ทึบ `alpha` วางทับสี `under` */
    fun over(under: RGB, alpha: Double): RGB = under.mixed(this, alpha)

    /**
     * สีเดิมที่ขยับความสว่างจนอ่านออกบน `ground` — ไม่ผ่านอยู่แล้วก็คืนตัวเดิม
     * ลองทั้งสองทาง ใช้ทางที่หมึกของการ์ดไป (`prefersLight`) ก่อน
     */
    fun legible(ground: InkGround, target: Double, prefersLight: Boolean): RGB {
        if (ground.contrast(luminance) >= target) return this
        val up = pushed(white, ground, target)
        val down = pushed(black, ground, target)
        val (first, second) = if (prefersLight) up to down else down to up
        if (first.second >= target) return first.first
        if (second.second >= target) return second.first
        return if (first.second >= second.second) first.first else second.first
    }

    /** ไล่เข้าหา `end` น้อยที่สุดเท่าที่ถึงเกณฑ์ — ไปสุดทางแล้วยังไม่ถึงก็คืนปลายทาง */
    private fun pushed(end: RGB, ground: InkGround, target: Double): Pair<RGB, Double> {
        val full = ground.contrast(end.luminance)
        if (full < target) return end to full
        var lo = 0.0; var hi = 1.0
        repeat(16) {
            val t = (lo + hi) / 2
            if (ground.contrast(mixed(end, t).luminance) >= target) hi = t else lo = t
        }
        val c = mixed(end, hi)
        return c to ground.contrast(c.luminance)
    }
}

/** สีนี้เวอร์ชันที่อ่านออกบนพื้น — ดู `RGB.legible` */
fun Color.legible(ground: InkGround, target: Double = Legibility.body, prefersLight: Boolean): Color {
    val c = RGB(this)
    val out = c.legible(ground, target, prefersLight)
    return if (out == c) this else out.color.copy(alpha = alpha)
}

// MARK: - พื้นใต้ตัวหนังสือ

/**
 * ช่วงความสว่างของสิ่งที่อยู่ใต้ตัวหนังสือ — หมึกสว่างแพ้ที่จุด **สว่างสุด** · หมึกเข้มแพ้ที่จุด **มืดสุด**
 */
data class InkGround(val lo: Double, val hi: Double) {
    companion object {
        fun of(lo: Double, hi: Double) = InkGround(min(lo, hi), max(lo, hi))
        fun of(tones: List<RGB>): InkGround {
            val l = tones.map { it.luminance }
            return of(l.minOrNull() ?: 0.0, l.maxOrNull() ?: 0.0)
        }
        /** พื้นของแผงเครื่องมือ (มืดคงที่) — ค่าตั้งต้นของทุกอย่างที่ไม่ได้อยู่บนการ์ด */
        val stage = InkGround(0.002, 0.03)
    }

    /** contrast ที่แย่ที่สุดของสีทึบความสว่าง `lum` บนพื้นช่วงนี้ — อยู่ในช่วงเดียวกับพื้นคือ 1 */
    fun contrast(lum: Double): Double = when {
        lum >= hi -> Legibility.ratio(lum, hi)
        lum <= lo -> Legibility.ratio(lum, lo)
        else -> 1.0
    }

    /** พื้นเดียวกันหลังมีแผ่นสีความสว่าง `panel` ทึบ `alpha` วางทับ (แผ่นของ widget) */
    fun covered(panel: Double, alpha: Double): InkGround {
        if (alpha <= 0) return this
        return of(Legibility.composite(panel, alpha, lo), Legibility.composite(panel, alpha, hi))
    }
}

/** สิ่งที่ม่านบนรูปต้องรู้ — มาจากธีม (ดู `CardTheme.photoVeil`) */
data class PhotoVeil(
    /** หมึกของการ์ดเป็นฝั่งสว่าง (ตัวขาว) — ม่านต้องกดจุดสว่างของรูปลง */
    val lightInk: Boolean,
    /** ความสว่างของหมึกเต็มแรง */
    val ink: Double,
    /** สีม่าน — สีบนของฉากหลังตามหมึก */
    val color: RGB,
    /** ความจางที่ผู้ใช้ตั้ง — ม่านบางกว่านี้ไม่ได้ทั้งภาพ */
    val minimum: Double,
    val target: Double = Legibility.photo,
)
