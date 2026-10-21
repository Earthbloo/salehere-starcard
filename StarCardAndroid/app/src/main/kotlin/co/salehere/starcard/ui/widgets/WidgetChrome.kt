package co.salehere.starcard.ui.widgets

import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.EaseOut
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.ui.geometry.Rect
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.SoftShadow
import co.salehere.starcard.components.float
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.StarTopic
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalGhostData
import co.salehere.starcard.ui.editor.LocalGhostKeepsText
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
fun WidgetChrome(
    placed: Placed,
    theme: CardTheme,
    modifier: Modifier = Modifier,
    forceSample: Boolean = false,
    /** ห้องแต่ง: ใบที่ข้อมูลยังไม่กรอกวาดด้วยชุดตัวอย่างใต้ชั้นเทา + ปุ่มปลดล็อกที่มุม (= `lockBadge` ของ iOS) */
    lockBadge: Boolean = false,
    /** รูปย่อที่เจ้าของเห็นเอง (คลัง · Star Profile): หน้าตาเดียวกับในห้องแต่ง แต่ **ไม่มีปุ่มปลดล็อก** (= `lockPreview`) */
    lockPreview: Boolean = false,
) {
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
    // ใบที่ล็อกในห้องแต่ง = วาดใบจริงด้วยชุดตัวอย่าง ให้เห็นว่ากรอกแล้วได้อะไร — ไม่ใช่กรอบเปล่ากับขีด "–"
    // (ผู้ใช้ 1 ต.ค. 2569) · ภาพที่แชร์/โหมดดูไม่ผ่านทางนี้ ยังเป็นป้ายรอข้อมูลเหมือนเดิม (= iOS `lockLook`/`sampled`)
    val lockLook = lockBadge || lockPreview
    val sampled = forceSample || sampleOuter || (lockLook && missing && Profile.me.lacks(kind.family))
    // กุญแจของตราที่ล็อกย่อตามใบ — ตราครึ่งหน้าบนสตอรี่ได้กุญแจเล็กลงตามส่วน
    val lockScale = max(0.7f, s)

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
            // แคตตาล็อก/ตัวส่งออกวาดใบเต็มด้วยชุดตัวอย่าง (= `forceSample` ของ iOS) · ใบที่ล็อกในห้องแต่งก็ชุดตัวอย่าง
            LocalSampleData provides sampled,
            LocalGhostData provides (missing && !sampled && !sealLocked),
            // หัวข้อที่แก้ได้บนการ์ดจริงยังอยู่ ขีด "–" เฉพาะค่าข้อมูล (= `ghostKeepsText` ของ iOS)
            LocalGhostKeepsText provides true,
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

    // เส้นขอบ/แผ่นเปลี่ยนแบบไหลเข้าหากัน (= iOS `withAnimation(Motion.flow)` ใน setSurface/setBorder)
    val borderColor by animateColorAsState(
        if (p.item.border && !kind.drawsOwnBorder) ink.line(0.12) else Color.Transparent,
        Motion.flow.spec(), label = "chromeBorder",
    )
    // ชุดห้าสไตล์/สติกเกอร์วาดเส้นขอบของตัวเองในผัง (`"if": "bordered"`) — chrome ไม่วาดซ้ำ (สีใส = ไม่เห็น)
    val root = modifier.size(frameW.dp, frameH.dp).border(0.7.dp, borderColor, shape)
    val byline = if (stamped) kind.stampOverlay else null
    val topic = kind.family.topic

    Box(root) {
        // แผ่นของ chrome อยู่หลังเนื้อหา — สลับพื้นแล้วแผ่นเก่าจางออก แผ่นใหม่จางเข้า ส่วนเนื้อหาวาดครั้งเดียว
        if (framed) {
            Crossfade(
                targetState = surface, modifier = Modifier.matchParentSize(),
                animationSpec = Motion.flow.float, label = "chromePlate",
            ) { sf ->
                when (sf) {
                    WidgetSurface.glass, WidgetSurface.pane -> {
                        // คู่สี: กระจกต้องไม่ย้อมสีเน้นของการ์ด — กระจกในงานสองสีคือ **เงาดำใส** ไม่ใช่สีที่สาม
                        val tinted = kind.tier == co.salehere.starcard.model.WidgetTier.verified && theme.activeDuo == null
                        GlassPanel(
                            tint = if (tinted) theme.accent else null,
                            tintStrength = if (tinted) 0.13 else 0.0,
                            // คู่สีไม่ต้องส่งม่านแยกแล้ว — ค่าที่ iOS วาดจริงบนคู่สีเท่ากับหมึกมืดทั่วไป (ดู GlassPanel)
                            veil = null,
                            radius = radius,
                            modifier = Modifier.fillMaxSize(),
                        ) {}
                    }
                    WidgetSurface.clear -> {}
                    WidgetSurface.dim -> {
                        // "เข้ม" = แผ่น **ทึบ 100%** — แผ่นทึบเปลี่ยนพื้นของตัวหนังสือทั้งดุ้น
                        Box(
                            Modifier
                                .fillMaxSize()
                                .shadow(
                                    elevation = (ink.liftRadius * 0.7f).dp, shape = shape, clip = false,
                                    ambientColor = ink.lift.opacity(0.6), spotColor = ink.lift.opacity(0.6),
                                )
                                .background(slab(theme), shape),
                        )
                    }
                }
            }
        }
        // ของที่วาดพื้นเอง — chrome ไม่ยุ่งกับมันเลย นอกจากกันของล้นกรอบ (สี่เหลี่ยมตรง ไม่ใช่มุมมน) · ก้อนข้อความไม่ clip
        Box(if (isText) Modifier else if (framed) Modifier.clip(shape) else Modifier.clip(RectangleShape)) { content() }

        // ใบที่ล็อก = สีของใบยังเต็ม มีแค่ชั้นเทาโปร่งทับ (ผู้ใช้ 1 ต.ค. 2569) · ตรารับรองที่ยังล็อกมีชั้นเทา **ทุกที่** รวมรูปที่แชร์
        if (missing && (lockLook || sealLocked) && !forceSample) {
            Box(Modifier.matchParentSize().background(WidgetChromeLock.veil, shape))
        }
        if (lockBadge && missing && topic != null) {
            // ปุ่มจริงของใบที่ล็อก — แตะรับที่ `CardScreen` ผ่าน `WidgetChromeLock.hitRect` (ชั้นนี้ไม่รับทัชเอง)
            LockCTA(
                title = when (topic) {
                    StarTopic.Verify -> "ยืนยันตัวตนเพื่อปลดล็อก"
                    StarTopic.Work -> "ทำงานจบ 1 งานเพื่อปลดล็อก"
                    else -> "กรอกข้อมูลเพื่อปลดล็อก"
                },
                modifier = Modifier.align(Alignment.TopEnd).padding(WidgetChromeLock.inset.dp),
            )
        } else if (sealLocked) {
            // นอกห้องแต่ง (หน้าดู · รูปที่แชร์) ไม่มีปุ่ม — กุญแจดวงเดียวพอ ของที่ดูเหมือนกดได้ห้ามอยู่ในรูป
            Box(
                Modifier
                    .align(Alignment.TopEnd)
                    .padding((WidgetChromeLock.inset * lockScale).dp)
                    .size((26f * lockScale).dp)
                    .background(Color.White, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                SFSymbol("lock.fill", size = 11f * lockScale, tint = WidgetChromeLock.ink, weight = PhWeight.fill)
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

/** ปุ่มปลดล็อกอยู่มุมขวาบนของใบ — ใช้ร่วมกับ `CardScreen` เพื่อรู้ว่าแตะโดนปุ่ม (= `WidgetChrome.lockHeight/lockInset/lockHitRect`) */
object WidgetChromeLock {
    const val height: Float = 30f
    const val inset: Float = 8f
    /** พื้นที่แตะของปุ่ม (พิกัดในใบ) — เผื่อขอบกว้างกว่าตัวปุ่มให้นิ้วแตะง่าย */
    fun hitRect(size: Size): Rect = Rect(size.width - 230f, 0f, size.width, inset + height + 10f)
    /** ชั้นเทาที่ทับใบซึ่งยังล็อกอยู่ (= `lockVeil` · white 0.22 @ 0.5) */
    val veil: Color = Color(0.22f, 0.22f, 0.22f, 0.5f)
    /** หมึกบนปุ่ม/กุญแจ (= `Color(red: 0.09, green: 0.09, blue: 0.11)`) */
    val ink: Color = rgb(0.09, 0.09, 0.11)
}

/**
 * ปุ่มปลดล็อกบนใบที่ยังไม่มีข้อมูล — ขาวทึบ (ดังกว่าใบที่หม่นอยู่ข้างหลัง) · กุญแจเปิด · ลูกศร = "กดได้" (= `LockCTA`)
 * วงแสงหายใจช้า ๆ รอบปุ่ม บอกว่าเป็นของที่ต้องแตะ ไม่ใช่ป้ายสถานะ (เฉพาะในห้องแต่ง) · ไม่รับทัชเอง
 */
@Composable
fun LockCTA(title: String, modifier: Modifier = Modifier) {
    val breathe = rememberInfiniteTransition(label = "lockBreathe")
    val t by breathe.animateFloat(
        initialValue = 0f, targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1600, easing = EaseOut), RepeatMode.Restart),
        label = "breathe",
    )
    Box(modifier) {
        SoftShadow(Color.Black.opacity(0.35), radius = 6f, y = 3f, shape = CircleShape, modifier = Modifier.matchParentSize())
        Box(
            Modifier
                .matchParentSize()
                .graphicsLayer { scaleX = 1f + 0.25f * t; scaleY = 1f + 0.25f * t }
                .border(2.dp, Color.White.opacity(0.7 * (1.0 - t)), CircleShape),
        )
        Row(
            Modifier
                .background(Color.White, CircleShape)
                .height(WidgetChromeLock.height.dp)
                .padding(start = 10.dp, end = 9.dp),
            horizontalArrangement = Arrangement.spacedBy(5.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            SFSymbol("lock.open.fill", size = 11f, tint = WidgetChromeLock.ink, weight = PhWeight.fill)
            Text(title, style = sh(11.5f, SHFont.bold), color = WidgetChromeLock.ink, maxLines = 1, softWrap = false)
            SFSymbol("chevron.right", size = 9f, tint = WidgetChromeLock.ink.opacity(0.55), weight = PhWeight.bold)
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
