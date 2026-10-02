package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.GlassPanel
import co.salehere.starcard.layout.Placed
import co.salehere.starcard.model.LocalWidgetBorder
import co.salehere.starcard.model.LocalWidgetEmboss
import co.salehere.starcard.model.LocalWidgetEmbossBlind
import co.salehere.starcard.model.LocalWidgetLiftsPhoto
import co.salehere.starcard.model.LocalWidgetPattern
import co.salehere.starcard.model.LocalWidgetSurface
import co.salehere.starcard.model.WidgetKind
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.InkGround
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.CardInk
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.RGB
import co.salehere.starcard.theme.hsb
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.ui.LocalWidgetID
import kotlin.math.max
import kotlin.math.min

/**
 * ค่าคงที่ของก้อนข้อความ (= `TextBlock.inset/radius/weight` ใน TextWidgets.swift)
 * อยู่ที่นี่เพราะ chrome ต้องใช้ก่อนที่ตัวก้อนข้อความจะถูกวาด — `TextBlock(theme, size)` คือ composable ใน TextWidgets.kt
 */
object TextBlockSpec {
    /** ขอบในของกล่องข้อความ — กล่องคือตัวอักษรพอดี */
    const val inset: Float = 4f
    /** มุมเล็ก — กล่องของตัวอักษร ไม่ใช่แผ่นข้อมูล */
    const val radius: Float = 10f
}

/**
 * เปลือกของ widget หนึ่งตัว — พื้น · กระจก · ขอบ — ใช้ทั้งบนแคนวาสและตอนเรนเดอร์รูป (= WidgetChrome.swift)
 *
 * เนื้อหาข้างในไม่มีตัวรับทัชของตัวเองเลย ชั้นการ์ดเป็นคนวาง catcher ทับเองถ้าต้องการให้ลาก/เลือกได้
 * กรอบคือ **คอนเทนเนอร์** — ผังได้ที่กว้างขึ้นไปจัดเอง ตัวอักษรกับรูปไม่ถูกบีบ · ย่อทั้งก้อนเฉพาะตอนกรอบแคบกว่าผัง
 */
@Composable
fun WidgetChrome(placed: Placed, theme: CardTheme, modifier: Modifier = Modifier) {
    val p = placed
    val ink = theme.inkStyle
    val kind = p.item.kind
    // `.pane` — กระจกของ chrome บนใบที่ปกติวาดวัสดุเอง: chrome เห็นเป็นกระจก · widget ได้รับ `.pane` ลงไปตรง ๆ
    val pane = p.item.surface == WidgetSurface.pane
    val surface = if (pane) WidgetSurface.glass else p.item.surface
    val innerSurface = p.item.surface
    // ก้อนข้อความ: กล่องคือตัวอักษรพอดี — ขอบชิด มุมเล็ก และ **ไม่ clip** เนื้อหา
    val isText = kind == WidgetKind.textBlock
    val radius = if (isText) min(theme.radius, TextBlockSpec.radius) else theme.radius
    val shape: Shape = RoundedCornerShape(radius.dp)
    // ทุกชิ้นมีพื้น ยกเว้นของที่วาดพื้นของตัวเองอยู่แล้ว · "ไม่มีพื้น" = ไม่มีแผ่นให้วาด
    val framed = pane || (!kind.drawsOwnSurface && surface != WidgetSurface.clear)
    // ระยะขอบในมีได้เมื่อ **มีอะไรให้เว้นจาก** เท่านั้น (พื้นของ chrome หรือเส้นขอบ)
    val insetable = framed || (!kind.drawsOwnSurface && p.item.border)
    // `.pane` ไม่เว้นระยะขอบใน — กรอบของเนื้อหาต้องเท่ากับตอน "มีพื้น" เป๊ะ
    val inset: Float = when {
        isText -> TextBlockSpec.inset
        pane || kind.isFullBleed || !insetable -> 0f
        else -> 12f
    }

    val frameW = max(p.frame.width, 1f)
    val frameH = max(p.frame.height, 1f)
    val natural = max(kind.defaultSize.width, 1f)
    // เพดานเดียวที่ยังสเกลอยู่คือ **ตอนกรอบแคบกว่าผัง** — เป็นทางกันล้น ไม่ใช่วิธีจัดผัง
    val s = if (isText) 1f else min(1f, frameW / natural)
    // ผังถูกวางในหน่วย "ก่อนย่อ" แล้วค่อยหดทั้งก้อน — ความสูงจึงต้องหารกลับด้วย
    val layout = Size(frameW / s, frameH / s)

    val contentInk = if (framed) chromeInk(ink, surface, theme) else ink

    val content: @Composable () -> Unit = {
        CompositionLocalProvider(
            LocalCardInk provides contentInk,
            LocalWidgetID provides p.item.id,
            LocalWidgetTextStyle provides p.item.textStyle,
            LocalWidgetSurface provides innerSurface,
            LocalWidgetBorder provides p.item.border,
            LocalWidgetPattern provides p.item.pattern,
            LocalWidgetLiftsPhoto provides (kind.liftsSubject && p.item.liftPhoto),
            LocalWidgetEmboss provides (kind.takesEmboss && p.item.emboss),
            LocalWidgetEmbossBlind provides p.item.embossBlind,
        ) {
            Box(
                Modifier
                    .size(frameW.dp, frameH.dp)
                    .let { if (isText) it else it.clipToBounds() },
                contentAlignment = Alignment.TopStart,
            ) {
                Box(
                    Modifier
                        .wrapContentSize(Alignment.TopStart, unbounded = true)
                        .requiredSize(layout.width.dp, layout.height.dp)
                        .graphicsLayer {
                            scaleX = s; scaleY = s
                            transformOrigin = TransformOrigin(0f, 0f)
                        }
                        .padding(inset.dp),
                ) {
                    // ส่งขนาดผังทั้งก้อน (ก่อนหักขอบใน) — ตรงกับ Swift ที่ส่ง `size: layout` แล้วค่อย `.padding(inset)`
                    WidgetBody(kind, theme, layout)
                }
            }
        }
    }

    var root = modifier.size(frameW.dp, frameH.dp)
    if (p.item.border && !kind.isPop) root = root.border(0.7.dp, ink.line(0.12), shape)

    Box(root) {
        if (!framed) {
            // ของที่วาดพื้นเอง — chrome ไม่ยุ่งกับมันเลย นอกจากกันของล้นกรอบ (สี่เหลี่ยมตรง ไม่ใช่มุมมน)
            Box(if (isText) Modifier else Modifier.clip(RectangleShape)) { content() }
        } else {
            when (surface) {
                WidgetSurface.glass, WidgetSurface.pane -> {
                    // คู่สี: กระจกต้องไม่ย้อมสีเน้นของการ์ด — กระจกในงานสองสีคือ **เงาดำใส** ไม่ใช่สีที่สาม
                    val tinted = kind.tier == co.salehere.starcard.model.WidgetTier.verified && theme.activeDuo == null
                    GlassPanel(
                        tint = if (tinted) theme.accent else null,
                        tintStrength = if (tinted) 0.13 else 0.0,
                        veil = if (theme.activeDuo == null) null else Color.Black.opacity(0.16),
                        radius = radius,
                    ) {
                        Box(if (isText) Modifier else Modifier.clip(shape)) { content() }
                    }
                }
                WidgetSurface.clear -> Box(if (isText) Modifier else Modifier.clip(shape)) { content() }
                WidgetSurface.dim -> {
                    // "เข้ม" = แผ่น **ทึบ 100%** — แผ่นทึบเปลี่ยนพื้นของตัวหนังสือทั้งดุ้น
                    Box(
                        Modifier
                            .shadow(
                                elevation = (ink.liftRadius * 0.7f).dp, shape = shape, clip = false,
                                ambientColor = ink.lift.opacity(0.6), spotColor = ink.lift.opacity(0.6),
                            )
                            .background(slab(theme), shape)
                            .let { if (isText) it else it.clip(shape) },
                    ) { content() }
                }
            }
        }
    }
}

/**
 * แผ่น "เข้ม" — ถ่านทึบที่อาบเฉดของธีมไว้ (= `WidgetChrome.slab`)
 * ไม่ใช่ดำสนิท: ดำ 100% บนการ์ดมืดอ่านเป็น "รูที่เจาะทะลุการ์ด"
 */
fun slab(theme: CardTheme): Color {
    theme.duoDark?.let { return it }
    return hsb(theme.backdropHue, 0.30, 0.10)
}

/** หมึกบนแผ่นแต่ละแบบ — ตัวเลขชุดเดียวกับที่วาดแผ่นข้างบน (และใน `GlassPanel`) */
private fun chromeInk(ink: InkStyle, surface: WidgetSurface, theme: CardTheme): InkStyle = when (surface) {
    WidgetSurface.clear -> ink
    WidgetSurface.glass, WidgetSurface.pane -> {
        if (theme.activeDuo != null) ink.covered(0.0, 0.16)
        else if (ink.isLight) ink.covered(1.0, 0.58) else ink.covered(0.0, 0.16)
    }
    WidgetSurface.dim -> {
        val lum = RGB(slab(theme)).luminance
        InkStyle(CardInk.night, theme.duoLight ?: Color.White, InkGround.of(lum, lum))
    }
}
