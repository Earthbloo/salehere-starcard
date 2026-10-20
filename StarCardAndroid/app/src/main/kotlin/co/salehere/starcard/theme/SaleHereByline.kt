package co.salehere.starcard.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.unit.dp
import co.salehere.starcard.model.WidgetKind
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

// MARK: - "Verified by Sale Here" ที่เป็นส่วนหนึ่งของ widget (= `SaleHereByline` ใน Theme/SaleHereMarks.swift)
//
// ติ๊กแดงในดาวหยัก + "Verified by" + โลโก้กลมแดงของแอป · ไม่มีพื้นของตัวเองนอกจากแคปซูลจาง ๆ ตามพื้นใต้มัน

/** ใบนี้มีป้าย Sale Here (ข้อมูลตรวจแล้ว) — ป้าย Verified เดิมในหัวข้อหลบให้ (= `\.saleHereStamped`) */
val LocalSaleHereStamped = compositionLocalOf { false }

enum class BylineTone { ink, dark, light }

@Composable
fun SaleHereByline(tint: Color, size: Float = 8.5f, tone: BylineTone = BylineTone.ink, modifier: Modifier = Modifier) {
    val text = when (tone) {
        BylineTone.ink -> tint
        BylineTone.dark -> Color.White.opacity(0.92)
        BylineTone.light -> grey(0.1).opacity(0.85)
    }
    val fill = when (tone) {
        BylineTone.ink -> tint.opacity(0.12)
        BylineTone.dark -> Color.Black.opacity(0.38)
        BylineTone.light -> Color.White.opacity(0.92)
    }
    val stroke = when (tone) {
        BylineTone.ink -> tint.opacity(0.2)
        BylineTone.dark -> Color.White.opacity(0.22)
        BylineTone.light -> Color.Black.opacity(0.08)
    }
    Row(
        modifier
            .background(fill, CircleShape)
            .border(0.5.dp, stroke, CircleShape)
            .padding(start = (size * 0.42f).dp, end = (size * 0.3f).dp, top = (size * 0.26f).dp, bottom = (size * 0.26f).dp),
        horizontalArrangement = Arrangement.spacedBy((size * 0.38f).dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier.size((size * 1.45f).dp).drawBehind { drawPath(sealPath(this.size), SaleHereMarkColors.red) },
            contentAlignment = Alignment.Center,
        ) {
            PIcon(Ph.check, size = size * 0.78f, weight = PhWeight.bold, tint = Color.White)
        }
        Text("Verified by", style = sh(size, SHFont.semibold), color = text, maxLines = 1, softWrap = false)
        SaleHereMark(size = size * 1.7f)
    }
}

/** ดาวหยักสิบกลีบของติ๊กแดง (= `SealShape` ใน StarGlassKit.swift) */
private fun sealPath(s: Size, lobes: Int = 10): Path {
    val c = Offset(s.width / 2, s.height / 2)
    val outer = min(s.width, s.height) / 2
    val inner = outer * 0.8f
    fun pt(r: Float, a: Double) = Offset(c.x + r * cos(a).toFloat(), c.y + r * sin(a).toFloat())
    val step = 2 * PI / lobes
    val p = Path()
    for (i in 0 until lobes) {
        val a = i * step - PI / 2
        if (i == 0) pt(inner, a).let { p.moveTo(it.x, it.y) }
        val ctl = pt(outer * 1.12f, a + step / 2)
        val to = pt(inner, a + step)
        p.quadraticTo(ctl.x, ctl.y, to.x, to.y)
    }
    p.close()
    return p
}

// MARK: - ใครได้ป้าย (= `StampFacts` · `WidgetKind.stampFacts` · `stampOverlay` ใน Theme/SaleHereStamp.swift)

enum class StampFacts {
    followers, insight, work;
    /** ทุกตระกูลได้เครื่องหมายเมื่อใบนั้นปลดล็อกแล้ว */
    val verified: Boolean get() = true
}

/** widget ที่แสดงข้อมูลซึ่งมาจาก Sale Here (`widget.stamp`) — ตัวอื่นไม่ได้เครื่องหมาย */
val WidgetKind.stampFacts: StampFacts?
    get() = StampFacts.entries.firstOrNull { it.name == meta.stamp }

/** ป้ายมุมขวาบนที่ chrome วางให้ใบที่ไม่มีช่องหัวข้อ (`widget.stampAt`) — (โทน, ระยะบน, ระยะขวา) */
val WidgetKind.stampOverlay: Triple<BylineTone, Float, Float>?
    get() {
        val a = meta.stampAt ?: return null
        val tone = BylineTone.entries.firstOrNull { it.name == a.tone } ?: BylineTone.ink
        return Triple(tone, a.top.toFloat(), a.trailing.toFloat())
    }
