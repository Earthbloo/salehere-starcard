package co.salehere.starcard.theme

import androidx.compose.ui.graphics.Color
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min

// เครื่องมือสีที่ทั้งแอปใช้ร่วมกัน — รวมส่วนขยายของ `Color` จาก ColorDuo.swift / CardTheme.swift / Legibility.swift

/** `Color(hue:saturation:brightness:)` ของ SwiftUI — hue 0…1 (ไม่ใช่องศา) */
fun hsb(hue: Double, saturation: Double, brightness: Double, alpha: Double = 1.0): Color {
    val h = (hue - floor(hue)).toFloat() * 360f
    return Color.hsv(h, saturation.coerceIn(0.0, 1.0).toFloat(), brightness.coerceIn(0.0, 1.0).toFloat(), alpha.toFloat())
}
fun hsb(hue: Float, saturation: Float, brightness: Float, alpha: Float = 1f): Color =
    hsb(hue.toDouble(), saturation.toDouble(), brightness.toDouble(), alpha.toDouble())

/** `Color(red:green:blue:)` ด้วยค่า 0…1 (Double) */
fun rgb(red: Double, green: Double, blue: Double, alpha: Double = 1.0): Color =
    Color(red.toFloat(), green.toFloat(), blue.toFloat(), alpha.toFloat())

/** `Color(white:)` */
fun grey(white: Double, alpha: Double = 1.0): Color = rgb(white, white, white, alpha)

/** `Color.hex(0xRRGGBB)` — คู่สีเก็บเป็นสีจริง ไม่ใช่ HSB */
fun Color.Companion.hex(v: Long): Color = Color(0xFF000000L or (v and 0xFFFFFF))

/**
 * `.opacity(x)` ของ SwiftUI — **คูณ** กับความทึบเดิม เหมือน SwiftUI (`Color.white.opacity(0.5).opacity(0.5)` = 0.25)
 * พอร์ตตรงตัวจาก Swift ได้เลย ไม่ต้องชดเชยเอง
 */
fun Color.opacity(a: Double): Color = copy(alpha = (alpha * a.toFloat()).coerceIn(0f, 1f))
fun Color.opacity(a: Float): Color = copy(alpha = (alpha * a).coerceIn(0f, 1f))

/** ผสมไปหาอีกสีตามสัดส่วน 0…1 — ผสมใน sRGB ตรง ๆ (= `Color.mixed(with:by:)`) */
fun Color.mixed(with: Color, by: Double): Color {
    val k = by.coerceIn(0.0, 1.0)
    val a = RGB(this); val b = RGB(with)
    return rgb(a.r + (b.r - a.r) * k, a.g + (b.g - a.g) * k, a.b + (b.b - a.b) * k, alpha.toDouble())
}

/** HSB ของสีนี้ (hue 0…1) — `UIColor.getHue` */
data class HSB(val h: Double, val s: Double, val b: Double)
fun Color.toHSB(): HSB {
    val r = red.toDouble(); val g = green.toDouble(); val bl = blue.toDouble()
    val mx = max(r, max(g, bl)); val mn = min(r, min(g, bl))
    val d = mx - mn
    val v = mx
    val s = if (mx <= 0.0) 0.0 else d / mx
    var h = 0.0
    if (d > 1e-9) {
        h = when (mx) {
            r -> ((g - bl) / d) % 6.0
            g -> (bl - r) / d + 2.0
            else -> (r - g) / d + 4.0
        } / 6.0
        if (h < 0) h += 1.0
    }
    return HSB(h, s, v)
}

/**
 * เวอร์ชันที่อ่านออกบนพื้นสว่าง — ลดความสว่าง เพิ่มความอิ่ม (= `Color.onLightSurface(depth:)`)
 * พาเลตต์ทั้งชุดถูกจูนมาสำหรับพื้นมืด เอาไปวางบนกระดาษขาวแล้วหายไปกับพื้นทันที
 */
fun Color.onLightSurface(depth: Double = 1.0): Color {
    val (h, s, b) = toHSB()
    val k = depth.coerceIn(0.0, 1.0)
    return hsb(h, min(1.0, s * (1.35 - 0.28 * (1 - k)) + 0.12), min(1.0, b * (0.60 + 0.26 * (1 - k))), alpha.toDouble())
}

/** `#RRGGBB` ของสีนี้ */
fun Color.toHexString(): String {
    val r = (red * 255).toInt().coerceIn(0, 255)
    val g = (green * 255).toInt().coerceIn(0, 255)
    val b = (blue * 255).toInt().coerceIn(0, 255)
    return String.format("#%02X%02X%02X", r, g, b)
}

/** ค่าที่ต่างกันน้อยกว่านี้ถือว่าสีเดียวกัน (เทียบ `sheet != .clear` ฯลฯ) */
fun Color.approx(other: Color): Boolean =
    abs(red - other.red) < 0.002f && abs(green - other.green) < 0.002f &&
        abs(blue - other.blue) < 0.002f && abs(alpha - other.alpha) < 0.002f

/** SwiftUI `Color.clear` */
val Color.Companion.Clear: Color get() = Transparent
