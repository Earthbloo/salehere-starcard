package co.salehere.starcard.model

import android.graphics.Bitmap
import co.salehere.starcard.theme.Legibility
import co.salehere.starcard.theme.PhotoVeil
import co.salehere.starcard.theme.RGB
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * แผนที่ความสว่างของรูปพื้นหลัง — ตัดสินว่าม่านต้องหนาแค่ไหน ตรงไหน และหมึกฝั่งไหนเสียรูปน้อยกว่า
 * (= `PhotoLuma` ใน Theme/Legibility.swift)
 *
 * ม่านไม่เท่ากันทั้งผืน — หนาเฉพาะช่องที่หมึกจะแพ้ ส่วนที่เหลือบางเท่าที่ผู้ใช้ตั้งไว้
 * เก็บเป็นกริดในพิกัดของตัวรูป — ยืดทับด้วยกรอบเดียวกับรูปแล้วตรงกันเป๊ะไม่ว่ารูปจะถูกครอปยังไง
 */
class PhotoLuma(
    /** ขนาดของรูปที่ย่อมาวัด (พิกเซล) */
    val width: Int,
    val height: Int,
    /** จำนวนช่องของกริด */
    val cols: Int,
    val rows: Int,
    /** ความสว่างของจุดที่สว่างที่สุดราวหนึ่งในสิบของแต่ละช่อง — จุดที่ตัวขาวแพ้ */
    val hi: DoubleArray,
    /** ของจุดที่มืดที่สุดราวหนึ่งในสิบ — จุดที่ตัวเข้มแพ้ */
    val lo: DoubleArray,
) {
    companion object {
        /** ด้านยาวของรูปที่ย่อมาวัด — ละเอียดพอเห็นลายของรูป แต่วัดเสร็จในเสี้ยวของเฟรม */
        private const val long = 160
        /** ด้านของช่องหนึ่งช่อง (พิกเซลของรูปที่ย่อ) */
        private const val cell = 8
        /** ม่านทึบได้มากสุดเท่านี้ — รูปต้องยังเหลือให้เห็นว่าเป็นรูป */
        private const val ceiling = 0.92

        /** วัดรูปหนึ่งใบ — `blurred` คือรูปนี้จะถูกเบลอตอนวาด จึงต้องเกลี่ยก่อนวัด */
        fun measure(image: Bitmap, blurred: Boolean): PhotoLuma? {
            val sw = image.width
            val sh = image.height
            if (sw <= 0 || sh <= 0) return null
            val k = long.toDouble() / max(sw, sh)
            val w = max(cell, (sw * k).roundToInt())
            val h = max(cell, (sh * k).roundToInt())
            val px = IntArray(w * h)
            val ok = runCatching {
                val small = Bitmap.createScaledBitmap(image, w, h, true)
                small.getPixels(px, 0, w, 0, 0, w, h)
                if (small !== image) small.recycle()
            }.isSuccess
            if (!ok) return null

            val table = DoubleArray(256) { Legibility.linear(it / 255.0) }
            var lum = DoubleArray(w * h)
            for (i in 0 until w * h) {
                val p = px[i]
                lum[i] = 0.2126 * table[(p shr 16) and 0xFF] +
                    0.7152 * table[(p shr 8) and 0xFF] +
                    0.0722 * table[p and 0xFF]
            }
            if (blurred) {
                // เบลอของการ์ดราวห้าเปอร์เซ็นต์ของด้านสั้น — กล่องสองรอบใกล้เคียงเกาส์พอ
                val r = max(1, min(w, h) / 20)
                lum = boxBlur(boxBlur(lum, w, h, r), w, h, r)
            }

            val cols = (w + cell - 1) / cell
            val rows = (h + cell - 1) / cell
            val hi = DoubleArray(cols * rows)
            val lo = DoubleArray(cols * rows)
            val bucket = DoubleArray(cell * cell)
            for (cy in 0 until rows) {
                for (cx in 0 until cols) {
                    var n = 0
                    for (y in (cy * cell) until min(h, (cy + 1) * cell)) {
                        for (x in (cx * cell) until min(w, (cx + 1) * cell)) {
                            bucket[n++] = lum[y * w + x]
                        }
                    }
                    java.util.Arrays.sort(bucket, 0, n)
                    hi[cy * cols + cx] = bucket[min(n - 1, (n * 0.9).toInt())]
                    lo[cy * cols + cx] = bucket[min(n - 1, (n * 0.1).toInt())]
                }
            }
            return PhotoLuma(w, h, cols, rows, hi, lo)
        }

        private fun boxBlur(v: DoubleArray, w: Int, h: Int, r: Int): DoubleArray {
            val tmp = v.copyOf()
            val out = v.copyOf()
            for (y in 0 until h) {
                for (x in 0 until w) {
                    var s = 0.0
                    var n = 0.0
                    for (xx in max(0, x - r)..min(w - 1, x + r)) { s += v[y * w + xx]; n += 1 }
                    tmp[y * w + x] = s / n
                }
            }
            for (y in 0 until h) {
                for (x in 0 until w) {
                    var s = 0.0
                    var n = 0.0
                    for (yy in max(0, y - r)..min(h - 1, y + r)) { s += tmp[yy * w + x]; n += 1 }
                    out[y * w + x] = s / n
                }
            }
            return out
        }
    }

    /** ความทึบของม่านในแต่ละช่อง — ทึบอย่างน้อย `minimum` ทั้งภาพ แล้วหนาขึ้นเฉพาะช่องที่หมึกจะแพ้ */
    fun veil(spec: PhotoVeil): DoubleArray {
        // ความสว่างที่พื้นต้องไม่เกิน (หมึกขาว) หรือต้องไม่ต่ำกว่า (หมึกเข้ม) ถึงจะได้ contrast ตามเป้า
        val goal = if (spec.lightInk) (spec.ink + 0.05) / spec.target - 0.05
                   else spec.target * (spec.ink + 0.05) - 0.05
        val c = Legibility.encoded(goal)
        val v = Legibility.encoded(spec.color.luminance)
        val a = DoubleArray(cols * rows)
        for (i in a.indices) {
            val g = Legibility.encoded(if (spec.lightInk) hi[i] else lo[i])
            var need = 0.0
            if (spec.lightInk && g > c) {
                need = if (v < c) (g - c) / (g - v) else 1.0
            } else if (!spec.lightInk && g < c) {
                need = if (v > c) (c - g) / (v - g) else 1.0
            }
            a[i] = min(ceiling, max(spec.minimum, need))
        }
        return smoothed(a)
    }

    /**
     * หมึกฝั่งไหนเสียรูปน้อยกว่า (−1…1) — บวก = รูปสว่าง หมึกเข้มต้องการม่านบางกว่า
     * เทียบ "ม่านเฉลี่ยที่ต้องใช้" ของสองฝั่ง ไม่ใช่ความสว่างเฉลี่ยของรูป
     */
    val lean: Double
        get() {
            val forWhite = veil(PhotoVeil(lightInk = true, ink = 1.0, color = RGB(0.1, 0.1, 0.12), minimum = 0.0))
            val forDark = veil(PhotoVeil(lightInk = false, ink = 0.015, color = RGB(0.95, 0.94, 0.92), minimum = 0.0))
            val n = max(1, forWhite.size).toDouble()
            return (forWhite.sum() - forDark.sum()) / n
        }

    /**
     * ม่านเป็นภาพสีเดียวทั้งผืน ต่างกันแค่ความทึบ — ขนาดเท่ารูปที่ย่อมาวัด ยืดเต็มกรอบรูปพื้นหลังแล้วตรงกันพอดี
     * ไล่ค่าระหว่างกึ่งกลางช่องเอง (bilinear) ก่อนส่งให้ยืดต่อ — กริดดิบถูกยืดตรง ๆ จะเห็นเป็นลายข้าวหลามตัด
     */
    fun veilImage(alpha: DoubleArray, color: RGB): Bitmap? {
        val w = width
        val h = height
        val cellD = cell.toDouble()
        if (alpha.size != cols * rows) return null
        val px = IntArray(w * h)
        val cr = (color.r * 255).roundToInt().coerceIn(0, 255)
        val cg = (color.g * 255).roundToInt().coerceIn(0, 255)
        val cb = (color.b * 255).roundToInt().coerceIn(0, 255)
        fun axis(p: Int, count: Int): Triple<Int, Int, Double> {
            val f = (p + 0.5) / cellD - 0.5
            val i0 = min(count - 1, max(0, floor(f).toInt()))
            return Triple(i0, min(count - 1, i0 + 1), min(1.0, max(0.0, f - i0)))
        }
        for (y in 0 until h) {
            val (y0, y1, ty) = axis(y, rows)
            for (x in 0 until w) {
                val (x0, x1, tx) = axis(x, cols)
                val top = alpha[y0 * cols + x0] * (1 - tx) + alpha[y0 * cols + x1] * tx
                val bottom = alpha[y1 * cols + x0] * (1 - tx) + alpha[y1 * cols + x1] * tx
                val a = top * (1 - ty) + bottom * ty
                val ai = (a * 255).roundToInt().coerceIn(0, 255)
                // Android รับสีแบบไม่ premultiply แล้วคูณให้เอง — จึงใส่สีตรง ๆ ไม่ต้องคูณ alpha
                px[y * w + x] = (ai shl 24) or (cr shl 16) or (cg shl 8) or cb
            }
        }
        return runCatching { Bitmap.createBitmap(px, w, h, Bitmap.Config.ARGB_8888) }.getOrNull()
    }

    /**
     * ขยายม่านออกหนึ่งช่องแล้วเกลี่ย — ตัวหนังสือที่คร่อมขอบช่องสว่างต้องได้ม่านเต็ม และขอบม่านต้องไม่เห็นเป็นขั้น
     * ขยายก่อนเกลี่ยเสมอ: การเกลี่ยจึงไม่กินยอดของช่องที่หนาที่สุดลง
     */
    private fun smoothed(a: DoubleArray): DoubleArray {
        val grown = a.copyOf()
        for (y in 0 until rows) {
            for (x in 0 until cols) {
                var m = 0.0
                for (yy in max(0, y - 1)..min(rows - 1, y + 1)) {
                    for (xx in max(0, x - 1)..min(cols - 1, x + 1)) m = max(m, a[yy * cols + xx])
                }
                grown[y * cols + x] = m
            }
        }
        val k = doubleArrayOf(1.0, 2.0, 1.0)
        val out = grown.copyOf()
        for (y in 0 until rows) {
            for (x in 0 until cols) {
                var s = 0.0
                var n = 0.0
                for (j in -1..1) {
                    for (i in -1..1) {
                        val yy = y + j
                        val xx = x + i
                        if (yy < 0 || yy >= rows || xx < 0 || xx >= cols) continue
                        val wgt = k[j + 1] * k[i + 1]
                        s += grown[yy * cols + xx] * wgt
                        n += wgt
                    }
                }
                out[y * cols + x] = s / n
            }
        }
        return out
    }
}
