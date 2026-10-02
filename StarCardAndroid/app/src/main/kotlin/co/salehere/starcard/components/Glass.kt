package co.salehere.starcard.components

import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SaleHereMark
import co.salehere.starcard.theme.Tinted
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.widgets.linkSlot
import kotlin.math.max
import kotlin.math.min

// MARK: - แผ่นกระจกมาตรฐานของการ์ด (= Components/Glass.swift)
//
// Android ไม่มี Liquid Glass — แผ่นนี้คือกระจกฝ้า: ม่านขาวขุ่น/ดำจางตามหมึก + เส้นขอบแสงบาง ๆ + ชั้นความสูง
// ไม่พยายามเบลอพื้นหลังจริง (ดู PORTING §8)

/**
 * แผ่นกระจกมาตรฐานของการ์ด
 *
 * ฝั่งกระดาษม่านต้องเป็น "ขาวขุ่น" ไม่ใช่ "ดำจาง" — กระจกฝ้าสีขาวคือหน้าตาของกระจกบนพื้นสว่างจริง ๆ
 * ถ้าใช้ดำจางบนกระดาษ แผ่นจะกลายเป็นรอยเปื้อนเทาที่ดูสกปรก
 * - veil: คู่สีส่งสีเข้มของคู่เข้ามาแทน เพราะการ์ดสองสีต้องไม่มีแผ่นสีที่สามโผล่มา
 * - interactive: คงไว้ให้ API ตรงกับ iOS (ไม่มีผลบน Android)
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun GlassPanel(
    tint: Color? = null,
    tintStrength: Double = 0.16,
    veil: Color? = null,
    radius: Float = 28f,
    interactive: Boolean = false,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val ink = LocalCardInk.current
    val shape = RoundedCornerShape(radius.dp)
    val fill = veil ?: (if (ink.isLight) Color.White.opacity(0.58) else Color.Black.opacity(0.16))
    var m = modifier
    // พื้นมืดยกแผ่นด้วยแสง · พื้นสว่างยกแผ่นด้วยเงา
    if (ink.liftRadius > 0f) {
        m = m.shadow(ink.liftRadius.dp, shape, clip = false, ambientColor = ink.lift, spotColor = ink.lift)
    }
    m = m.background(fill, shape)
    if (tint != null) m = m.background(tint.opacity(tintStrength), shape)
    // ขอบแสง — สว่างมุมบนซ้ายแล้วจางหายไปทางล่างขวา เหมือน rim light ของกระจก
    m = m.border(
        0.6.dp,
        Brush.linearGradient(
            0f to Color.White.opacity(0.35), 0.6f to Color.White.opacity(0.0),
            start = Offset.Zero, end = Offset.Infinite,
        ),
        shape,
    )
    Box(m) { content() }
}

// MARK: - Small parts

/**
 * ป้าย "ยืนยันโดย SaleHere" — ติดเฉพาะ widget ชั้นหลักฐาน
 * ต้องมีชื่อผู้ออก (โลโก้จริง คงสีแบรนด์) และประโยคที่บอกความสัมพันธ์ (Verified by)
 * ตราปิดท้ายบรรทัด ไม่ใช่นำหน้า — ประโยคอ่านจบแล้วสายตาไปหยุดที่ *ใครเป็นคนยืนยัน*
 */
@Composable
fun VerifiedBadge(modifier: Modifier = Modifier) {
    val ink = LocalCardInk.current
    Tinted(ink.text(0.92)) {
        Row(
            modifier
                // แตะป้ายแล้วต้องมีคำตอบ — เปิดแผ่นตรวจสอบเดียวกับตราทุกดวง (= `verifySlot`, เผื่อขอบ 8pt)
                .linkSlot(VerifiedFacts.sheetURL, slop = 8f)
                .background(ink.fill(0.16), CircleShape)
                .border(0.5.dp, ink.line(0.22), CircleShape)
                .padding(start = 8.dp, end = 4.dp, top = 3.dp, bottom = 3.dp),
            horizontalArrangement = Arrangement.spacedBy(5.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("Verified by", style = sh(8f, SHFont.semibold), maxLines = 1, softWrap = false)
            SaleHereMark(size = 14f)
        }
    }
}

/**
 * หัวข้อของ widget — ทิ้งแถบตั้ง แล้วให้เส้นไหลจากท้ายคำไปจนสุดขอบแทน (ท่าของหัวเรื่องในนิตยสาร ไม่ใช่ของฟอร์ม)
 * ขนาด 13.5 เพราะหัวข้อคือ *บริบท* ไม่ใช่ *เนื้อหา* — ของที่ควรดังที่สุดใน widget คือตัวเลขกับรูป
 */
@Composable
fun WidgetLabel(text: String, trailing: (@Composable () -> Unit)? = null, modifier: Modifier = Modifier) {
    val ink = LocalCardInk.current
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(
            text,
            style = sh(13.5f, SHFont.bold),
            color = ink.text(0.88),
            maxLines = 1,
            softWrap = false,
            autoSize = TextAutoSize.StepBased(minFontSize = (13.5f * 0.7f).sp, maxFontSize = 13.5.sp, stepSize = 0.5.sp),
        )
        // เส้นไหลจากท้ายคำไปจนสุด — ไล่จางออกไป ไม่ใช่เส้นทึบยาวเท่ากันตลอด
        Box(
            Modifier
                .weight(1f)
                .height(0.8.dp)
                .background(Brush.horizontalGradient(listOf(ink.line(0.2), ink.line(0.04)))),
        )
        if (trailing != null) trailing()
    }
}

/** ตัวบอกความสด — "sync 2 ชม." คือจุดขายที่ PDF ทำไม่ได้ */
@Composable
fun SyncDot(ago: String, modifier: Modifier = Modifier) {
    val ink = LocalCardInk.current
    val pulse = rememberInfiniteTransition(label = "syncDot")
    val t by pulse.animateFloat(
        initialValue = 0f, targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1400, easing = EaseInOut), RepeatMode.Reverse),
        label = "pulse",
    )
    val dot = if (ink.isLight) rgb(0.10, 0.62, 0.36) else rgb(0.35, 0.95, 0.6)
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(
            Modifier
                .size(5.dp)
                .graphicsLayer {
                    scaleX = 1f + 0.5f * t
                    scaleY = 1f + 0.5f * t
                    alpha = 1f - 0.6f * t
                }
                .background(dot, CircleShape),
        )
        Text("sync $ago", style = sh(9f, SHFont.medium), color = ink.text(0.42), maxLines = 1, softWrap = false)
    }
}

// MARK: - Helpers

/**
 * `.redacted(reason: .placeholder)` — ซ่อนเนื้อหาแล้ววาดแท่งมนสี `LocalContentColor` จาง ๆ ทับเท่ากล่องเดิม
 * ใช้กับ "ค่าข้อมูลของผู้ใช้" ในโหมดพรีวิวไม่มีข้อมูล (ดู `Modifier.dataValue`)
 */
fun Modifier.redacted(on: Boolean): Modifier = if (!on) this else composed {
    val bar = LocalContentColor.current.opacity(0.25)
    drawWithContent {
        val r = min(size.height * 0.3f, 6.dp.toPx())
        drawRoundRect(bar, cornerRadius = CornerRadius(r, r))
    }
}

/**
 * เงากันจมรอบตัวอักษร (= `legibilityHalo` ใน Theme/Legibility.swift)
 *
 * iOS ซ้อนเงาสองชั้น (ชั้นในคม · ชั้นนอกฟุ้ง) — `TextStyle` มีเงาได้ชั้นเดียว จึงเอาชั้นที่กว้างกว่าไว้
 * เหมือนที่ช่องพิมพ์ `UITextView` ทำ · `size` คือขนาดตัวอักษร (pt) · `density` แปลงรัศมีเป็นพิกเซล
 */
fun TextStyle.legibilityHalo(color: Color?, size: Float, density: Float = 1f): TextStyle =
    if (color == null) this
    else copy(shadow = Shadow(color = color, offset = Offset.Zero, blurRadius = max(2f, size * 0.14f) * density))
