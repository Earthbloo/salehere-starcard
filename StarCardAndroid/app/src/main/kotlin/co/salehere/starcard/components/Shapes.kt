package co.salehere.starcard.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathOperation
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import co.salehere.starcard.theme.opacity
import kotlin.math.min

// MARK: - รูปทรงที่ไม่ใช่สี่เหลี่ยม (= Components/Shapes.swift)
//
// ค่าที่เป็นรัศมี (footRadius · notchRadius · corner) เป็นหน่วยออกแบบ (pt = dp) แปลงเป็นพิกเซลตอนวาด

/**
 * ทรงซุ้มโค้ง — ครึ่งวงกลมด้านบน ตัดตรงด้านล่าง
 * ภาษาของนิตยสารแฟชั่น ใช้กับรูปแล้วเปลี่ยนอารมณ์ทันทีจาก "ข้อมูล" เป็น "งาน"
 */
data class ArchShape(val footRadius: Float = 10f) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline {
        val w = size.width
        val h = size.height
        val foot = with(density) { footRadius.dp.toPx() }
        val arc = min(w / 2f, h * 0.62f)
        val p = Path()
        p.moveTo(0f, h - foot)
        p.lineTo(0f, arc)
        // จากซ้าย (180°) กวาดผ่านยอด (270°) ไปขวา (360°) — โค้งอยู่ด้านบน
        p.arcTo(Rect(w / 2f - arc, 0f, w / 2f + arc, arc * 2f), 180f, 180f, false)
        p.lineTo(w, h - foot)
        p.quadraticTo(w, h, w - foot, h)
        p.lineTo(foot, h)
        p.quadraticTo(0f, h, 0f, h - foot)
        p.close()
        return Outline.Generic(p)
    }
}

/** ทรงตั๋ว — บากครึ่งวงกลมสองข้าง ใช้กับการ์ดราคาแล้วอ่านออกทันทีว่า "นี่คือของที่ซื้อได้" */
data class TicketShape(
    val notchAt: Float = 0.62f,
    val notchRadius: Float = 11f,
    val corner: Float = 18f,
) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline {
        val r = with(density) { notchRadius.dp.toPx() }
        val c = with(density) { corner.dp.toPx() }
        val y = size.height * notchAt
        val body = Path().apply {
            addRoundRect(RoundRect(Rect(0f, 0f, size.width, size.height), CornerRadius(c, c)))
        }
        val cut = Path().apply {
            addOval(Rect(-r, y - r, r, y + r))
            addOval(Rect(size.width - r, y - r, size.width + r, y + r))
        }
        val out = Path().apply { op(body, cut, PathOperation.Difference) }
        return Outline.Generic(out)
    }
}

/** ทรงหยดน้ำ — ขอบมนไม่เท่ากันสี่มุม ให้ความรู้สึกออร์แกนิกแทนที่จะเป็นกล่อง */
data class BlobShape(val seed: Int = 0) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline {
        val k = ((seed % 4) + 4) % 4
        val radii = floatArrayOf(
            floatArrayOf(0.46f, 0.18f, 0.42f, 0.20f)[k],
            floatArrayOf(0.20f, 0.44f, 0.18f, 0.46f)[k],
            floatArrayOf(0.44f, 0.20f, 0.46f, 0.18f)[k],
            floatArrayOf(0.18f, 0.46f, 0.20f, 0.44f)[k],
        )
        val w = size.width
        val h = size.height
        val m = min(w, h)
        val p = Path()
        p.moveTo(m * radii[0], 0f)
        p.lineTo(w - m * radii[1], 0f)
        p.quadraticTo(w, 0f, w, m * radii[1])
        p.lineTo(w, h - m * radii[2])
        p.quadraticTo(w, h, w - m * radii[2], h)
        p.lineTo(m * radii[3], h)
        p.quadraticTo(0f, h, 0f, h - m * radii[3])
        p.lineTo(0f, m * radii[0])
        p.quadraticTo(0f, 0f, m * radii[0], 0f)
        p.close()
        return Outline.Generic(p)
    }
}

/** รูสเปอร์เก็ตของฟิล์ม */
@Composable
fun SprocketRow(count: Int = 12, modifier: Modifier = Modifier) {
    Row(modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(0.dp), verticalAlignment = Alignment.CenterVertically) {
        repeat(count) {
            Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                Box(
                    Modifier
                        .size(7.dp, 5.dp)
                        .background(Color.Black.opacity(0.55), RoundedCornerShape(1.6.dp)),
                )
            }
        }
    }
}

/** เทปกาวสำหรับรูปแบบโพลารอยด์ */
@Composable
fun TapeStrip(tint: Color = Color.White, modifier: Modifier = Modifier) {
    val shadow = Color.Black.opacity(0.25)
    Box(
        modifier
            .graphicsLayer { rotationZ = -7f }
            .size(62.dp, 20.dp)
            .shadow(3.dp, RectangleShape, clip = false, ambientColor = shadow, spotColor = shadow)
            .background(Brush.verticalGradient(listOf(tint.opacity(0.42), tint.opacity(0.26))))
            .border(0.5.dp, Color.White.opacity(0.25), RectangleShape),
    )
}
