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
import co.salehere.starcard.model.LocalWidgetPattern
import co.salehere.starcard.model.LocalWidgetSurface
import co.salehere.starcard.model.SpecCatalog
import co.salehere.starcard.model.WidgetFamily
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
import co.salehere.starcard.ui.LocalSampleData
import co.salehere.starcard.ui.LocalWidgetRenderScale
import co.salehere.starcard.layout.ReplayData
import co.salehere.starcard.model.LocalKitConfig
import co.salehere.starcard.model.LocalSpecDataOverride
import co.salehere.starcard.model.StarFlow
import co.salehere.starcard.model.isKit
import co.salehere.starcard.theme.LocalSaleHereStamped
import co.salehere.starcard.theme.SaleHereByline
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.stampFacts
import co.salehere.starcard.theme.stampOverlay
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
 * ระยะขอบในของเนื้อหา (= `WidgetChrome.contentInset` ของ iOS · WIDGET-SPEC.md §2)
 * 12 เมื่อ chrome วาดแผ่น (glass/dim) หรือมีเส้นขอบ · 0 เมื่อ pane / fullBleed / ใบวาดพื้นเอง · ก้อนข้อความใช้ของมันเอง
 */
fun contentInset(kind: WidgetKind, surface: WidgetSurface, border: Boolean): Float {
    if (kind.isTextLayer) return TextBlockSpec.inset
    val pane = surface == WidgetSurface.pane
    val framed = pane || (!kind.drawsOwnSurface && surface != WidgetSurface.clear)
    val insetable = framed || (!kind.drawsOwnSurface && border)
    return if (pane || kind.isFullBleed || !insetable) 0f else 12f
}

/**
 * เปลือกของ widget หนึ่งตัว — พื้น · กระจก · ขอบ — ใช้ทั้งบนแคนวาสและตอนเรนเดอร์รูป (= WidgetChrome.swift)
 *
 * เนื้อหาข้างในไม่มีตัวรับทัชของตัวเองเลย ชั้นการ์ดเป็นคนวาง catcher ทับเองถ้าต้องการให้ลาก/เลือกได้
 * กรอบคือ **คอนเทนเนอร์** — ผังได้ที่กว้างขึ้นไปจัดเอง ตัวอักษรกับรูปไม่ถูกบีบ · ย่อทั้งก้อนเฉพาะตอนกรอบแคบกว่าผัง
 */
@Composable
fun WidgetChrome(placed: Placed, theme: CardTheme, modifier: Modifier = Modifier, forceSample: Boolean = false) {
    val p = placed
    val ink = theme.inkStyle
    val kind = p.item.kind
    // `.pane` — กระจกของ chrome บนใบที่ปกติวาดวัสดุเอง: chrome เห็นเป็นกระจก · widget ได้รับ `.pane` ลงไปตรง ๆ
    val pane = p.item.surface == WidgetSurface.pane
    val surface = if (pane) WidgetSurface.glass else p.item.surface
    val innerSurface = p.item.surface
    // ก้อนข้อความ: กล่องคือตัวอักษรพอดี — ขอบชิด มุมเล็ก และ **ไม่ clip** เนื้อหา
    val isText = kind.isTextLayer
    val radius = if (isText) min(theme.radius, TextBlockSpec.radius) else theme.radius
    val shape: Shape = RoundedCornerShape(radius.dp)
    // ทุกชิ้นมีพื้น ยกเว้นของที่วาดพื้นของตัวเองอยู่แล้ว · "ไม่มีพื้น" = ไม่มีแผ่นให้วาด
    val framed = pane || (!kind.drawsOwnSurface && surface != WidgetSurface.clear)
    // ระยะขอบในมีได้เมื่อ **มีอะไรให้เว้นจาก** เท่านั้น (พื้นของ chrome หรือเส้นขอบ) — สูตรอยู่ที่ `contentInset`
    val inset: Float = contentInset(kind, p.item.surface, p.item.border)

    // กติกาเดียว · ทุกใบ · ไม่มีข้อยกเว้น (WIDGET-SPEC.md §2 · = WidgetChrome.swift):
    //   s   = min(W / w0, H / h0)   ← ย่อ/ขยายทั้งก้อนด้วยแกนที่คับสุด · ไม่บีบสักแกน
    //   box = (W / s, H / s)        ← กล่องผังในหน่วยออกแบบ · ผังจัดตัวเองลงใน box
    // `w0 × h0` = ขนาดอ้างอิงจากไฟล์ผัง (`WidgetSpec.design`) ไม่มีก็ `defaultSize` · ก้อนข้อความใบเดียวที่ไม่สเกล
    val frameW = max(p.frame.width, 1f)
    val frameH = max(p.frame.height, 1f)
    val design = SpecCatalog.spec(kind)?.design?.let { Size(it.w.toFloat(), it.h.toFloat()) } ?: kind.defaultSize
    val natural = max(design.width, 1f)
    val naturalH = max(design.height, 1f)
    val s = if (isText) 1f else min(frameW / natural, frameH / naturalH)
    // ผังถูกวางในหน่วย "ก่อนสเกล" แล้วค่อยคูณทั้งก้อน — กล่องจึงต้องหารกลับด้วย
    val layout = Size(frameW / s, frameH / s)

    val contentInk = if (framed) chromeInk(ink, surface, theme) else ink

    // หัวข้อ Star Profile ที่ใบนี้อ่านยังไม่ได้กรอก (= `missing` ของ iOS) · ตรารับรองล็อกจนกว่าการยืนยันตัวตนจะผ่าน
    val missing = kind.family.missing
    val sealLocked = kind.family == WidgetFamily.seal && missing
    // ป้าย Sale Here — ใบที่ถือข้อมูลซึ่งตรวจแล้ว · ใบที่ยังไม่มีข้อมูลไม่ได้ป้าย (= `stamped` ของ iOS)
    // ตอนส่งออกเทียบภาพ ค่านี้มาจากรอบวาดของ iOS (ธง `stamped` ที่ผังถาม) — ไม่ขึ้นกับข้อมูลบนเครื่องนี้
    val replayed = (LocalSpecDataOverride.current as? ReplayData)?.flags?.get("stamped")
    val stamped = replayed ?: (!missing && (kind.stampFacts?.verified ?: false))
    val sampleOuter = LocalSampleData.current

    val content: @Composable () -> Unit = {
        CompositionLocalProvider(
            LocalCardInk provides contentInk,
            LocalWidgetID provides p.item.id,
            LocalWidgetTextStyle provides p.item.textStyle,
            LocalWidgetSurface provides innerSurface,
            LocalWidgetBorder provides p.item.border,
            LocalWidgetPattern provides p.item.pattern,
            LocalSaleHereStamped provides stamped,
            LocalKitConfig provides p.item.kit,
            // แคตตาล็อก/ตัวส่งออกวาดใบเต็มด้วยชุดตัวอย่าง (= `forceSample` ของ iOS)
            LocalSampleData provides (forceSample || sampleOuter),
            LocalWidgetRenderScale provides s.toDouble(),
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
    // ชุดห้าสไตล์/สติกเกอร์วาดเส้นขอบของตัวเองในผัง (`"if": "bordered"`) — chrome ไม่วาดซ้ำ
    if (p.item.border && !kind.drawsOwnBorder) root = root.border(0.7.dp, ink.line(0.12), shape)
    val byline = if (stamped) kind.stampOverlay else null

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
        // ใบที่ไม่มีช่องหัวข้อ — ป้าย Verified by Sale Here มุมขวาบนด้านใน (= `WidgetKind.stampOverlay`)
        if (byline != null) {
            SaleHereByline(
                tint = contentInk.text(0.85), tone = byline.first,
                modifier = Modifier.align(Alignment.TopEnd).padding(top = byline.second.dp, end = byline.third.dp),
            )
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
