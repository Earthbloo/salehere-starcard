package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import co.salehere.starcard.theme.LocalScrapTone
import co.salehere.starcard.theme.mixed
import co.salehere.starcard.theme.opacity
import kotlin.math.max
import kotlin.math.roundToInt

// MARK: - สำรับสมุดสแครปบุ๊ก — ชิ้นส่วนร่วม (= Views/Widgets/ScrapbookKit.swift · เฉพาะของตกแต่งที่ตัววาดผังเรียกเป็น icon)
//
// แปลงจาก canvas "Pink Scrapbook Widgets" (30 ก.ย. 2569) — เอา *ภาษาภาพ* มา (กระดาษชมพู คลิปหนีบ เทปวาชิ)
// - **จบในรูปที่ export** — ไม่มีของที่ชวนให้กด (คนส่วนใหญ่ export รูป)
// - **โทนตามธีมของการ์ด** — สีของแผ่นกับสีเน้นมาจาก `ScrapTone` (theme/ScrapTone.kt) ผ่าน `LocalScrapTone`
//   **ของที่เป็นวัตถุ** (คลิป เทป บาร์โค้ด) ยังเป็นสีของจริง ไม่เปลี่ยนตามโทน
//
// ค่าทุกตัวเป็นหน่วยออกแบบ (pt = dp) — Canvas วาดเป็นพิกเซล จึงคูณ `density` ตอนวาด

/** หมึกบนกระดาษ (= `Scrap.ink`) — สีของวัตถุ ไม่เปลี่ยนตามธีม */
internal val scrapInk = Color(0xFF141414)

// MARK: - รูปทรง

/** ป้ายห้อยทรงตัดมุมซ้าย (ป้ายราคา/กระเป๋าเดินทาง) (= `TagShape`) · `cut` เป็น pt */
data class TagShape(val cut: Float = 16f) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline =
        Outline.Generic(path(size, with(density) { cut.dp.toPx() }))

    fun path(size: Size, cutPx: Float, origin: Offset = Offset.Zero): Path = Path().apply {
        val minX = origin.x; val minY = origin.y
        val maxX = origin.x + size.width; val maxY = origin.y + size.height
        val h = size.height
        moveTo(minX + cutPx, minY)
        lineTo(maxX, minY)
        lineTo(maxX, maxY)
        lineTo(minX + cutPx, maxY)
        lineTo(minX, maxY - h * 0.3f)
        lineTo(minX, minY + h * 0.3f)
        close()
    }
}

/** หัวใจ (= `ScrapHeart`) */
object ScrapHeart : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline =
        Outline.Generic(path(size))

    fun path(size: Size, origin: Offset = Offset.Zero): Path = Path().apply {
        val w = size.width; val h = size.height
        val minX = origin.x; val minY = origin.y
        val maxX = minX + w; val midX = minX + w / 2
        moveTo(midX, minY + h * 0.92f)
        cubicTo(minX + w * 0.3f, minY + h * 0.72f, minX, minY + h * 0.55f, minX, minY + h * 0.33f)
        cubicTo(minX, minY + h * 0.02f, minX + w * 0.4f, minY - h * 0.02f, midX, minY + h * 0.2f)
        cubicTo(minX + w * 0.6f, minY - h * 0.02f, maxX, minY + h * 0.02f, maxX, minY + h * 0.33f)
        cubicTo(maxX, minY + h * 0.55f, minX + w * 0.7f, minY + h * 0.72f, midX, minY + h * 0.92f)
        close()
    }
}

/** ขอบหยักฟันเลื่อยใต้ใบเสร็จ (= `ZigzagEdge`) · `tooth` เป็น pt */
data class ZigzagEdge(val tooth: Float = 10f) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline =
        Outline.Generic(path(size, with(density) { tooth.dp.toPx() }))

    fun path(size: Size, toothPx: Float, origin: Offset = Offset.Zero): Path = Path().apply {
        val minX = origin.x; val minY = origin.y
        val maxX = minX + size.width; val maxY = minY + size.height
        moveTo(minX, minY)
        lineTo(maxX, minY)
        val n = max(1, (size.width / toothPx).roundToInt())
        val step = size.width / n
        var x = maxX
        repeat(n) {
            lineTo(x - step / 2, maxY)
            lineTo(x - step, minY)
            x -= step
        }
        close()
    }
}

/** ประกายสี่แฉก (= `PicnicSparkle` ของ GinghamWidgets.swift — สำรับปิกนิกยังไม่ได้ port จึงอยู่ที่นี่) */
object PicnicSparkle : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline =
        Outline.Generic(path(size))

    fun path(size: Size, origin: Offset = Offset.Zero): Path = Path().apply {
        val cx = origin.x + size.width / 2; val cy = origin.y + size.height / 2
        val w = size.width / 2; val h = size.height / 2; val k = 0.16f
        moveTo(cx, cy - h)
        quadraticTo(cx + w * k, cy - h * k, cx + w, cy)
        quadraticTo(cx + w * k, cy + h * k, cx, cy + h)
        quadraticTo(cx - w * k, cy + h * k, cx - w, cy)
        quadraticTo(cx - w * k, cy - h * k, cx, cy - h)
        close()
    }
}

/** คลิปหนีบกระดาษเงิน (= `PaperClip`) — เส้นเปิด ใช้ stroke · กว้าง 30 หน่วย สูง 69 หน่วย */
object PaperClip : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline =
        Outline.Generic(path(size))

    fun path(size: Size, origin: Offset = Offset.Zero): Path = Path().apply {
        val s = size.width / 30f
        fun px(x: Float) = origin.x + x * s
        fun py(y: Float) = origin.y + y * s
        moveTo(px(20f), py(22f))
        lineTo(px(20f), py(62f))
        // โค้งล่าง: จาก 0° กวาดไป 180° ทวนเข็ม (clockwise: false ของ CG ในระบบ y-ลง = กวาดผ่านด้านล่าง)
        arcTo(Rect(px(13f) - 7 * s, py(62f) - 7 * s, px(13f) + 7 * s, py(62f) + 7 * s), 0f, 180f, false)
        lineTo(px(6f), py(14f))
        // โค้งบน: จาก 180° กวาดไป 0° ผ่านด้านบน
        arcTo(Rect(px(16f) - 10 * s, py(14f) - 10 * s, px(16f) + 10 * s, py(14f) + 10 * s), 180f, 180f, false)
        lineTo(px(26f), py(58f))
    }
}

// MARK: - ของตกแต่ง (วาดด้วยโค้ด — เปลี่ยนสีได้ คมทุกขนาดตอน export)

/** ประกายสี่แฉกลอยตัว (= `ScrapSpark`) */
@Composable
fun ScrapSpark(size: Float = 14f, color: Color = Color.White, modifier: Modifier = Modifier) {
    Canvas(modifier.size(size.dp)) {
        drawPath(PicnicSparkle.path(this.size), color)
    }
}

/** โบว์ — สองห่วง สองหาง ปมกลาง (= `ScrapBow`) · สีจากโทน */
@Composable
fun ScrapBow(width: Float = 30f, modifier: Modifier = Modifier) {
    val tone = LocalScrapTone.current
    val color = tone.band; val edge = tone.paperAccent
    Canvas(modifier.size(width.dp, (width * 0.75f).dp)) {
        val s = size.width / 64f
        fun x(v: Float) = v * s
        fun y(v: Float) = v * s
        val left = Path().apply {
            moveTo(x(32f), y(20f))
            cubicTo(x(24f), y(6f), x(6f), y(4f), x(6f), y(16f))
            cubicTo(x(6f), y(28f), x(24f), y(28f), x(32f), y(20f))
        }
        val right = Path().apply {
            moveTo(x(32f), y(20f))
            cubicTo(x(40f), y(6f), x(58f), y(4f), x(58f), y(16f))
            cubicTo(x(58f), y(28f), x(40f), y(28f), x(32f), y(20f))
        }
        val tails = Path().apply {
            moveTo(x(29f), y(22f)); lineTo(x(19f), y(44f)); lineTo(x(26f), y(41f)); lineTo(x(30f), y(47f)); close()
            moveTo(x(35f), y(22f)); lineTo(x(45f), y(44f)); lineTo(x(38f), y(41f)); lineTo(x(34f), y(47f)); close()
        }
        drawPath(tails, color.mixed(edge, 0.3))
        for (loop in listOf(left, right)) {
            drawPath(loop, color)
            drawPath(loop, edge, style = Stroke(width = 1.6f * s))
        }
        drawOval(edge, Offset(27f * s, 16f * s), Size(10f * s, 10f * s))
    }
}

/** คลิปหนีบกระดาษดำ — ลวดเงินสองเส้น + ตัวหนีบคางหมู (= `BinderClip`) */
@Composable
fun BinderClip(width: Float = 34f, modifier: Modifier = Modifier) {
    val shade = Color.Black.opacity(0.18)
    Canvas(
        modifier
            .size(width.dp, (width * 66f / 68f).dp)
            .shadow(2.dp, RectangleShape, clip = false, ambientColor = shade, spotColor = shade),
    ) {
        val s = size.width / 68f
        fun x(v: Float) = v * s
        fun y(v: Float) = v * s
        val wire = Path().apply {
            moveTo(x(20f), y(36f)); lineTo(x(25f), y(8f))
            quadraticTo(x(34f), y(1f), x(43f), y(8f)); lineTo(x(48f), y(36f))
        }
        drawPath(wire, Color(0xFFC3C7CF), style = Stroke(width = 3.2f * s, cap = StrokeCap.Round))
        val inner = Path().apply {
            moveTo(x(26f), y(36f)); lineTo(x(29f), y(14f))
            quadraticTo(x(34f), y(10f), x(39f), y(14f)); lineTo(x(42f), y(36f))
        }
        drawPath(inner, Color(0xFF9EA3AC), style = Stroke(width = 2.4f * s, cap = StrokeCap.Round))
        val body = Path().apply {
            moveTo(x(8f), y(34f)); lineTo(x(60f), y(34f))
            lineTo(x(56f), y(62f)); lineTo(x(12f), y(62f)); close()
        }
        drawPath(body, Color(0xFF161616))
        val shine = Path().apply { moveTo(x(12f), y(38f)); lineTo(x(56f), y(38f)) }
        drawPath(shine, Color(0xFF4A4A4A), style = Stroke(width = 2f * s))
    }
}

/** คลิปหนีบกระดาษเงิน วาดเป็นเส้น (= `PaperClip().stroke(color, lineWidth:)`) · `lineWidth` เป็น pt */
@Composable
fun PaperClipView(color: Color, lineWidth: Float = 1.6f, modifier: Modifier = Modifier) {
    Canvas(modifier.fillMaxSize()) {
        drawPath(PaperClip.path(size), color, style = Stroke(width = lineWidth * density))
    }
}

/** เทปวาชิ — ลายทางขาวชมพูโปร่ง (= `WashiTape`) · ลายแถบ 4.5 pt */
@Composable
fun WashiTape(width: Float = 55f, height: Float = 15f, tint: Color = Color.White, modifier: Modifier = Modifier) {
    val tone = LocalScrapTone.current
    val stripe = tone.band
    val shade = tone.shade.opacity(0.14)
    Canvas(
        modifier
            .size(width.dp, height.dp)
            .shadow(1.dp, RectangleShape, clip = false, ambientColor = shade, spotColor = shade),
    ) {
        val band = 4.5f * density
        var x = 0f
        var odd = false
        while (x < size.width) {
            drawRect(if (odd) stripe.opacity(0.62) else tint.opacity(0.72), Offset(x, 0f), Size(band, size.height))
            x += band
            odd = !odd
        }
    }
}

/** บาร์โค้ด — แท่งกว้างแคบไม่ซ้ำจังหวะ (= `ScrapBarcode`) · ตารางเดียวกับลาย `barcode` ของผัง */
@Composable
fun ScrapBarcode(color: Color = scrapInk, modifier: Modifier = Modifier) {
    Canvas(modifier.fillMaxSize()) {
        val bars = barcodeBars
        val unit = size.width / bars.sum()
        var x = 0f
        bars.forEachIndexed { i, b ->
            if (i % 2 == 0) drawRect(color, Offset(x, 0f), Size(b * unit, size.height))
            x += b * unit
        }
    }
}

/** จุดสามสีบนแถบหัวหน้าต่าง — **สีของโทน** ไม่ใช่แดงเหลืองเขียวของ macOS (= `ScrapWindowDots`) · 26×6 */
@Composable
fun ScrapWindowDots(modifier: Modifier = Modifier) {
    val tone = LocalScrapTone.current
    Row(modifier.width(26.dp).height(6.dp), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        Box(Modifier.size(6.dp).background(tone.paperAccent, CircleShape))
        Box(Modifier.size(6.dp).background(tone.mid, CircleShape))
        Box(Modifier.size(6.dp).background(tone.band, CircleShape))
    }
}
