package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.unit.dp
import co.salehere.starcard.model.SpecPattern
import co.salehere.starcard.theme.opacity
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

// MARK: - ลายพื้นของผัง (รายการปิด · ทุกแพลตฟอร์มวาดด้วยกติกาเดียวกัน — WIDGET-SPEC.md §6)
//
// ทุกลายเป็นเรขาคณิตล้วน (ไม่มีรูปบิตแมป) จึงวาดใหม่ได้ทุกแพลตฟอร์มจากพารามิเตอร์ชุดเดียว:
// `size` = ระยะซ้ำ (pt) · `width` = ความหนาเส้น/จุด · `angle` = องศาของเส้น · `color`/`color2`
//
// Canvas ของ Compose วาดเป็นพิกเซล — ค่าทุกตัวในผังเป็น pt (= dp) จึงคูณ `density` ก่อนวาด
// ให้เรขาคณิตเท่ากับ Canvas ของ SwiftUI ที่วาดเป็น pt ตรง ๆ

@Composable
fun SpecPatternView(pattern: SpecPattern, color: Color, color2: Color, modifier: Modifier = Modifier) {
    Canvas(modifier.alpha((pattern.opacity ?: 1.0).toFloat())) {
        val sz = size
        val d = density
        val s = (pattern.size ?: 12.0).toFloat() * d
        val w = (pattern.width?.toFloat()?.times(d)) ?: max(1f * d, s * 0.12f)
        when (pattern.kind) {
            "gingham" -> {
                // ผ้าตาราง: แถบแนวตั้ง + แนวนอนสีเดียวกันโปร่ง ครึ่งหนึ่ง ทับกันเป็นช่องเข้ม
                val band = s / 2
                val c = color.opacity(0.45)
                var x = 0f
                while (x < sz.width) { drawRect(c, Offset(x, 0f), Size(band, sz.height)); x += s }
                var y = 0f
                while (y < sz.height) { drawRect(c, Offset(0f, y), Size(sz.width, band)); y += s }
            }
            "stripes", "lines" -> {
                val a = (pattern.angle ?: (if (pattern.kind == "stripes") 45.0 else 0.0)).toFloat()
                val diag = hypot(sz.width, sz.height)
                val p = Path()
                var dd = -diag
                while (dd < diag) { p.moveTo(dd, -diag); p.lineTo(dd, diag); dd += s }
                // iOS: translate(center).rotated(by: a) — หมุนก่อนแล้วเลื่อนไปกลางกล่อง
                withTransform({ translate(sz.width / 2, sz.height / 2); rotate(a, Offset.Zero) }) {
                    drawPath(p, color, style = Stroke(width = w))
                }
            }
            "dots" -> {
                var y = s / 2
                while (y < sz.height) {
                    var x = s / 2
                    while (x < sz.width) { drawOval(color, Offset(x - w / 2, y - w / 2), Size(w, w)); x += s }
                    y += s
                }
            }
            "grid" -> {
                val p = Path()
                var x = 0f
                while (x <= sz.width) { p.moveTo(x, 0f); p.lineTo(x, sz.height); x += s }
                var y = 0f
                while (y <= sz.height) { p.moveTo(0f, y); p.lineTo(sz.width, y); y += s }
                drawPath(p, color, style = Stroke(width = w))
            }
            "sprockets" -> {
                // รูฟิล์ม: สี่เหลี่ยมมุมมนเรียงตามขอบบนและล่าง (สูง = width · กว้าง = size×0.55)
                val hole = Size(s * 0.55f, w)
                val inset = (pattern.angle ?: 4.0).toFloat() * d   // ระยะจากขอบ (ยืม angle เป็นพารามิเตอร์ตัวที่สาม)
                val r = CornerRadius(1.5f * d, 1.5f * d)
                var x = s * 0.25f
                while (x + hole.width < sz.width) {
                    for (y in floatArrayOf(inset, sz.height - inset - hole.height)) {
                        drawRoundRect(color, Offset(x, y), hole, r)
                    }
                    x += s
                }
            }
            "rings" -> {
                val c = Offset(sz.width / 2, sz.height / 2)
                var r = s
                val big = hypot(sz.width, sz.height) / 2
                while (r < big) { drawCircle(color, r, c, style = Stroke(width = w)); r += s }
            }
            "speckle" -> {
                // จุดสุ่มแบบกำหนด seed (LCG) — ทุกแพลตฟอร์มได้จุดเดียวกัน (เลขคณิต UInt32 wrap เหมือน Swift `&*` `&+`)
                var seed = 1_234_567L
                fun next(): Float {
                    seed = (seed * 1_664_525L + 1_013_904_223L) and 0xFFFF_FFFFL
                    return (seed % 10_000L).toFloat() / 10_000f
                }
                val n = ((sz.width * sz.height) / (s * s)).toInt()
                repeat(n) {
                    val x = next() * sz.width; val y = next() * sz.height; val r = w * (0.5f + next())
                    drawOval(if (next() > 0.5f) color else color2, Offset(x, y), Size(r, r))
                }
            }
            "barcode" -> {
                val bars = barcodeBars
                val unit = sz.width / bars.sum()
                var x = 0f
                bars.forEachIndexed { i, b ->
                    if (i % 2 == 0) drawRect(color, Offset(x, 0f), Size(b * unit, sz.height))
                    x += b * unit
                }
            }
            "guilloche" -> {
                // ลายกิโยเช่: เส้นโค้งสองชุดรอบศูนย์กลาง (สูตรเดียวกับ `Guilloche` ของตรารับรอง)
                val c = Offset(sz.width / 2, sz.height / 2)
                val big = min(sz.width, sz.height) / 2
                val sets = listOf(doubleArrayOf(16.0, 0.115, 0.86, 16.0), doubleArrayOf(9.0, 0.10, 0.60, 12.0))
                for (set in sets) {
                    val n = set[0]; val amp = set[1]; val base = set[2]; val count = set[3].toInt()
                    for (k in 0 until count) {
                        val phi = k.toDouble() / count * 2 * PI / n
                        val p = Path()
                        val steps = 420
                        for (i in 0..steps) {
                            val t = i.toDouble() / steps * 2 * PI
                            val r = big * (base + amp * cos(n * t + phi)).toFloat()
                            val px = c.x + r * cos(t).toFloat(); val py = c.y + r * sin(t).toFloat()
                            if (i == 0) p.moveTo(px, py) else p.lineTo(px, py)
                        }
                        drawPath(p, color, style = Stroke(width = w * 0.5f))
                    }
                }
            }
            else -> Unit
        }
    }
}

/** ตารางแท่งบาร์โค้ด — ชุดเดียวกับ `ScrapBarcode` และ iOS (กว้างแคบไม่ซ้ำจังหวะ) */
internal val barcodeBars: FloatArray =
    floatArrayOf(3f, 1f, 1f, 2f, 4f, 1f, 2f, 3f, 1f, 1f, 3f, 2f, 1f, 4f, 1f, 2f, 2f, 1f, 3f, 1f, 1f, 2f, 4f, 1f, 2f, 1f, 3f)

/** รูปร่างของกล่อง — `shape` ในผัง: `tag:16` · `heart` · `scallop:8` · `zigzag:10` · ไม่ใส่ = สี่เหลี่ยมมุมมน */
object SpecShapes {
    fun make(spec: String?, corner: Float): Shape {
        if (spec == null) return RoundedCornerShape(corner.dp)
        val parts = spec.split(":")
        val p = if (parts.size > 1) parts[1].toDoubleOrNull() else null
        return when (parts[0]) {
            "tag" -> TagShape(cut = (p ?: 16.0).toFloat())
            "heart" -> ScrapHeart
            "scallop" -> SealScallop(petals = (p ?: 8.0).toInt())
            "zigzag" -> ZigzagEdge(tooth = (p ?: 10.0).toFloat())
            "circle" -> CircleShape
            else -> RoundedCornerShape(corner.dp)
        }
    }
}
