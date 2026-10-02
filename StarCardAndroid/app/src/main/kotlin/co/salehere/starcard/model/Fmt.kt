package co.salehere.starcard.model

import java.text.NumberFormat
import java.util.Locale
import kotlin.math.roundToInt

/** ตัวจัดรูปแบบตัวเลขบนการ์ด (= `Fmt` ท้าย MockData.swift) */
object Fmt {
    /** ย่อตัวเลข — ตัดทศนิยมทิ้งเมื่อเลขหน้าถึงหลักร้อย ("184K" ไม่ใช่ "184.0K") */
    fun compact(n: Int): String {
        fun trim(v: Double, suffix: String): String =
            if (v >= 100) "${v.roundToInt()}$suffix" else String.format(Locale.US, "%.1f%s", v, suffix)
        return when {
            n >= 1_000_000 -> trim(n / 1_000_000.0, "M")
            n >= 1_000 -> trim(n / 1_000.0, "K")
            else -> "$n"
        }
    }

    fun baht(n: Int): String = NumberFormat.getNumberInstance(Locale.US).format(n)

    /** เงินแบบย่อ — ใช้กับตัวเลขยอดขายที่ยาวเกินกว่าจะเขียนเต็มบนแผ่นเล็ก */
    fun money(n: Int): String = when {
        n >= 1_000_000 -> "฿" + String.format(Locale.US, "%.1fM", n / 1_000_000.0)
        n >= 100_000 -> "฿" + String.format(Locale.US, "%.0fK", n / 1_000.0)
        else -> "฿" + baht(n)
    }

    /** เปอร์เซ็นต์ — ตัด ".0" ทิ้งเพื่อให้แถวตัวเลขไม่เต้น */
    fun pct(v: Double): String {
        val s = String.format(Locale.US, "%.1f", v)
        return (if (s.endsWith(".0")) s.dropLast(2) else s) + "%"
    }

    /** `String(format: "%.1f", x)` แบบไม่ขึ้นกับ locale */
    fun f(v: Double, digits: Int = 1): String = String.format(Locale.US, "%.${digits}f", v)
    fun f(v: Float, digits: Int = 1): String = f(v.toDouble(), digits)
}
