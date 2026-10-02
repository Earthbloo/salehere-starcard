package co.salehere.starcard.ui

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BlurMaskFilter
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.ClipOp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.GlassPanel
import co.salehere.starcard.layout.PageLayout
import co.salehere.starcard.model.CardFormat
import co.salehere.starcard.model.CardPage
import co.salehere.starcard.model.CardTemplate
import co.salehere.starcard.model.CutoutCache
import co.salehere.starcard.model.DesignedTemplate
import co.salehere.starcard.model.PhotoStore
import co.salehere.starcard.model.Portfolio
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.SubjectLift
import co.salehere.starcard.theme.CardInk
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.CardBackdrop
import co.salehere.starcard.theme.SignatureEmboss
import co.salehere.starcard.theme.StripStyle
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.ui.editor.LocalSlotRegistry
import co.salehere.starcard.ui.export.CardPageCanvas
import co.salehere.starcard.ui.salehere.starflow.GL
import co.salehere.starcard.ui.widgets.ImageCache
import co.salehere.starcard.ui.widgets.PhotoLib
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.yield
import kotlin.math.max

// MARK: - พรีวิวการ์ดย่อส่วน — ใช้ร่วมกันทั้งหน้าเลือกเทมเพลตและคลังการ์ด (= Views/CardPreviews.swift)
//
// ทั้งสองหน้าต้องโชว์ "ของจริงย่อส่วน" ไม่ใช่รูปแคป — วาดด้วย widget ชุดเดียวกับการ์ดจริง
// ผ่าน `CardPageCanvas` ทุกครั้ง สิ่งที่เห็นจึงตรงกับสิ่งที่ได้เสมอ

/** ความสูงของแถบสามหน้า (= `CardStripPreview.height(width:gutter:margin:)`) */
object CardStripPreview {
    /**
     * ความสูงของแถบที่ความกว้างเท่านี้ — ผูกกับ `gutter`/`margin` เพราะกินความกว้างไปด้วย
     * ใครวาดกรอบรอไว้ต้องคิดจากสูตรเดียวกัน ไม่งั้นรูปถูกยืดผิดสัดส่วน
     */
    fun height(width: Float, gutter: Float = 0f, margin: Float = 0f): Float {
        val p = CardTemplate.previewPageSize(CardFormat.portfolio)
        return width * (p.height + margin * 2) / (p.width * 3 + gutter * 2 + margin * 2)
    }
}

/**
 * แถบสามหน้าต่อกันบนฉากหลังผืนเดียว — หน้าตาเดียวกับรูปที่แชร์ออกจริง (โครงเดียวกับตอน export)
 * - showsDividers: เส้นประบอกเขตหน้า — ภาษาหมายเหตุของแอป รูปแชร์จริงไม่มีเส้นนี้
 * - flat: ฉากหลังแบบเบา — ไล่เฉดแบนแทน `CardBackdrop` (กริดที่โชว์พรีวิวพร้อมกันหลายใบ)
 * - gutter: ช่องว่างระหว่างหน้า (หน่วยออกแบบ) — **0 = แถบต่อเนื่องเหมือนรูปที่แชร์ออกจริง**
 * - margin: ขอบรอบแถบ (หน่วยออกแบบ) — ใส่ค่าเมื่อแถบถูกโชว์ใหญ่เป็น "การ์ดทั้งใบ"
 * - cornerRadius: มุมมนของกรอบนอก (หน่วยจอ)
 */
@Composable
fun CardStripPreview(
    pages: List<CardPage>,
    theme: CardTheme,
    width: Float,
    showsDividers: Boolean = true,
    flat: Boolean = false,
    gutter: Float = 0f,
    margin: Float = 0f,
    cornerRadius: Float = 10f,
    modifier: Modifier = Modifier,
) {
    val pageSize = CardTemplate.previewPageSize(CardFormat.portfolio)
    val sheet = Size(pageSize.width * 3 + gutter * 2 + margin * 2, pageSize.height + margin * 2)
    val s = width / sheet.width
    val pageRadius = gutter * 0.85f
    val blank = remember { CardPage() }

    Box(
        modifier
            .size(width.dp, (sheet.height * s).dp)
            .clip(RoundedCornerShape(cornerRadius.dp))
            .border(0.6.dp, Color.White.opacity(0.1), RoundedCornerShape(10.dp)),
    ) {
        ScaledSheet(sheet, s) {
            PreviewLocals(theme, pageSize) {
                PreviewGround(theme, flat)
                Row(Modifier.padding(margin.dp), horizontalArrangement = Arrangement.spacedBy(gutter.dp)) {
                    for (i in 0 until 3) {
                        val shape = RoundedCornerShape(pageRadius.dp)
                        // มุมมน + ขอบบาง เกิดเฉพาะตอนมีช่องว่าง — แถบต่อเนื่องต้องไม่มีรอยต่อ
                        // ขอบขาวจาง ๆ อ่านออกบนฉากหลังมืด · เงาอ่านออกบนฉากหลังสว่าง — ต้องมีทั้งคู่
                        val framed = if (gutter > 0f) {
                            Modifier
                                .glowShadow(Color.Black.opacity(0.38), gutter * 0.34f, gutter * 0.13f, pageRadius)
                                .clip(shape)
                                .border(1.4.dp, Color.White.opacity(0.14), shape)
                        } else {
                            Modifier.clip(shape)
                        }
                        CardPageCanvas(page = pages.getOrNull(i) ?: blank, size = pageSize, theme = theme, modifier = framed)
                    }
                }
                if (!flat && theme.strip.isStamp) {
                    SignatureEmboss(
                        light = theme.inkStyle.isLight, foil = theme.strip == StripStyle.foil, tint = theme.inkStyle.base,
                        pages = pages, pageSize = pageSize, margin = margin, gutter = gutter,
                    )
                }
            }
        }
        // ช่องว่างจริงพูดแทนเส้นประได้หมดแล้ว — วาดทั้งคู่จะกลายเป็นรอยต่อสองชั้น
        if (showsDividers && gutter == 0f) {
            val dashes = remember { VerticalDashes() }
            Canvas(Modifier.matchParentSize()) {
                val line = 0.7.dp.toPx()
                val spacer = (size.width - line * 2) / 3f
                for (i in 0 until 2) {
                    val left = spacer * (i + 1) + line * i
                    translate(left = left) {
                        drawPath(
                            dashes.path(Size(line, size.height)), Color.White.opacity(0.22),
                            style = Stroke(width = line, pathEffect = PathEffect.dashPathEffect(floatArrayOf(4.dp.toPx(), 4.dp.toPx()))),
                        )
                    }
                }
            }
        }
    }
}

/** หน้าเดียวเป็นเฟรมตั้ง — ใช้กับสตอรี่ (และหน้าเดี่ยวของพอร์ตถ้าต้องการ) · `flat` = เหตุผลเดียวกับ `CardStripPreview` */
@Composable
fun CardFramePreview(
    page: CardPage,
    theme: CardTheme,
    pageSize: Size,
    height: Float,
    cornerRadius: Float = 13f,
    flat: Boolean = false,
    modifier: Modifier = Modifier,
) {
    val s = height / pageSize.height
    val shape = RoundedCornerShape(cornerRadius.dp)
    Box(
        modifier
            .size((pageSize.width * s).dp, height.dp)
            .clip(shape)
            .border(0.6.dp, Color.White.opacity(0.1), shape),
    ) {
        ScaledSheet(pageSize, s) {
            PreviewLocals(theme, pageSize) {
                PreviewGround(theme, flat)
                CardPageCanvas(page = page, size = pageSize, theme = theme)
                if (!flat && theme.strip.isStamp) {
                    SignatureEmboss(
                        light = theme.inkStyle.isLight, foil = theme.strip == StripStyle.foil, tint = theme.inkStyle.base,
                        pages = listOf(page), pageSize = pageSize,
                    )
                }
            }
        }
    }
}

/** ผืนหน่วยออกแบบที่ถูกย่อด้วย `graphicsLayer` จากมุมซ้ายบน (= `.frame(sheet).scaleEffect(s).frame(scaled)`) */
@Composable
private fun ScaledSheet(sheet: Size, s: Float, content: @Composable BoxScope.() -> Unit) {
    Box(
        Modifier
            .wrapContentSize(Alignment.TopStart, unbounded = true)
            .requiredSize(sheet.width.dp, sheet.height.dp)
            .graphicsLayer {
                scaleX = s; scaleY = s
                transformOrigin = TransformOrigin(0f, 0f)
            },
        content = content,
    )
}

/**
 * environment ของพรีวิว — หมึกของการ์ด · ความกว้างเนื้อหา · **หยุดของที่วิ่งตามเวลา**
 * (จอโชว์พร้อมกันหลายใบ ปล่อยวิ่งแล้วแย่งเฟรมกันจนกระตุก) · ไม่มีช่องให้แตะ
 */
@Composable
private fun PreviewLocals(theme: CardTheme, pageSize: Size, content: @Composable () -> Unit) {
    CompositionLocalProvider(
        LocalCardInk provides theme.inkStyle,
        LocalPageContentWidth provides PageLayout.content(pageSize).width,
        LocalPreviewStatic provides true,
        LocalTextEditMode provides false,
        LocalSlotRegistry provides null,
        content = content,
    )
}

@Composable
private fun PreviewGround(theme: CardTheme, flat: Boolean) {
    if (flat) {
        val c = theme.backdropColors
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(c.top, c.bottom))))
    } else {
        CardBackdrop(theme = theme, ignoreSafeArea = false, signed = true)
    }
}

// MARK: - รูปนิ่งของเทมเพลต

/**
 * แคชรูปนิ่งของพรีวิวเทมเพลต — **หน้าเลือกโชว์แค่รูป** widget จริงเกิดเฉพาะตอนเลือกแล้ว
 *
 * เทมเพลตจากการ์ดที่ออกแบบจริงมีรูปอบติดแอปมาแล้ว (`assets/designed_templates/<id>.png`)
 * Android ไม่มี `ImageRenderer` นอกจอ — ใบที่ไม่มีรูปอบ ผนังวาดพรีวิวสดแทน (`TemplateWall`)
 */
class TemplateThumbs private constructor() {
    companion object {
        val shared: TemplateThumbs by lazy { TemplateThumbs() }
    }

    /** รูปที่อบในแอป — Android ไม่อบ จึงว่างเสมอ (คง API ไว้ให้ตรงกับ iOS) */
    var images: Map<String, Bitmap> by mutableStateOf(emptyMap())
        private set

    /** ข้อมูลรุ่นที่แต่ละใบถูกเตรียมมา — ไม่ตรงกับ `stamp` ปัจจุบัน = ของนั้นเก่า */
    private val bakedStamp = HashMap<String, String>()
    private var warming = false

    /** รุ่นของข้อมูลที่ widget วาด — เปลี่ยนเมื่อโปรไฟล์ รูปโปรไฟล์ หรือผลงานเปลี่ยน */
    private fun stamp(photos: PhotoStore): String =
        "${Profile.me.revision}-${photos.profileRevision}-${Portfolio.shared.revision}"

    /** เทมเพลตจากการ์ดที่ออกแบบจริงมีรูปอบติดแอปมาแล้ว — โชว์รูปนั้น ไม่อบสดทับด้วยข้อมูลผู้ใช้ */
    fun image(id: String): Bitmap? = bundled[id] ?: images[id]

    private val bundled: Map<String, Bitmap> by lazy {
        DesignedTemplate.all.mapNotNull { d -> DesignedTemplate.preview(d.id)?.let { d.id to it } }.toMap()
    }

    /**
     * อุ่นของที่พรีวิวต้องใช้ — เรียกซ้ำได้ ปลอดภัย (ทำงานรอบเดียวต่อรุ่นข้อมูล)
     * รอรูปตั้งต้นให้ครบก่อน — พรีวิวสดตอนรูปยังไม่มาจะวาดช่องว่าง
     */
    suspend fun warm(photos: PhotoStore) {
        val now = stamp(photos)
        val all = CardFormat.entries.flatMap { CardTemplate.all(it) }.filter { bundled[it.id] == null }
        if (warming || all.none { bakedStamp[it.id] != now }) return
        warming = true
        try {
            // 1) รูปตั้งต้น + โลโก้แบรนด์
            val urls = LinkedHashSet<String>()
            for (i in 0 until PhotoLib.count) urls += PhotoLib.url(i)
            for (brand in Profile.me.creator.track.brands) brand.logo?.let { urls += it }
            coroutineScope { urls.map { u -> async { ImageCache.shared.load(u) } }.awaitAll() }

            // 1.5) ลบพื้นหลังรูปคนของโปสเตอร์ให้เสร็จก่อน (ดู `SubjectLift.prepare`)
            val person = photos.userImage(1, null)
            if (person != null && !CutoutCache.shared.result(person).isCutout) {
                SubjectLift.shared.prepare(person)
            }

            // 2) ทีละใบ เว้นจังหวะให้ UI หายใจ — ใบพวกนี้ผนังวาดสด จึงแค่จำว่าเตรียมจากข้อมูลรุ่นไหน
            for (format in CardFormat.entries) {
                for (template in CardTemplate.all(format)) {
                    if (bundled[template.id] != null || bakedStamp[template.id] == now) continue
                    bakedStamp[template.id] = now
                    yield()
                }
            }
        } finally {
            warming = false
        }
    }

    /**
     * iOS (DEBUG): ยกการ์ดทุกใบในคลังออกมาเป็นเทมเพลต (`-exportDesignedTemplates`)
     * Android ไม่มี launch argument และไม่มี `ImageRenderer` — รูปเทมเพลตมาจากฝั่ง iOS เท่านั้น
     */
    @Suppress("UNUSED_PARAMETER", "RedundantSuspendModifier")
    suspend fun exportDesigned(photos: PhotoStore) {}
}

/** เส้นตั้งเส้นเดียว — มีไว้ให้ stroke ด้วย dash ได้ (สี่เหลี่ยมจะ dash รอบกรอบ ไม่ใช่เส้นเดี่ยว) */
class VerticalDashes : Shape {
    fun path(size: Size): Path = Path().apply {
        moveTo(size.width / 2f, 0f)
        lineTo(size.width / 2f, size.height)
    }

    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline =
        Outline.Generic(path(size))
}

// MARK: - ตัวช่วยร่วมของหน้าคลัง/เลือกเทมเพลต/ส่งออก (internal)

/**
 * `.shadow(color:radius:y:)` ของ SwiftUI — เงาฟุ้ง/แสงเรืองรอบรูปทรง วาด **เฉพาะนอกรูปทรง**
 * `corner` = null → แคปซูล/วงกลม
 */
internal fun Modifier.glowShadow(color: Color, radius: Float, y: Float = 0f, corner: Float? = null): Modifier =
    if (color.alpha <= 0f || radius <= 0f) this else drawWithCache {
        val cr = corner?.dp?.toPx() ?: (size.minDimension / 2f)
        val outline = Path().apply { addRoundRect(RoundRect(Rect(Offset.Zero, size), CornerRadius(cr))) }
        val paint = android.graphics.Paint().apply {
            isAntiAlias = true
            this.color = color.toArgb()
            maskFilter = BlurMaskFilter(max(0.5f, radius.dp.toPx()), BlurMaskFilter.Blur.NORMAL)
        }
        val dy = y.dp.toPx()
        onDrawBehind {
            clipPath(outline, ClipOp.Difference) {
                drawIntoCanvas { it.nativeCanvas.drawRoundRect(0f, dy, size.width, size.height + dy, cr, cr, paint) }
            }
        }
    }

/** `.overlay(shape.strokeBorder(style: StrokeStyle(lineWidth:, dash:)))` — เส้นประด้านในรูปทรง */
internal fun Modifier.dashedRoundBorder(color: Color, width: Float, dash: Float, gap: Float, radius: Float): Modifier =
    drawWithContent {
        drawContent()
        val w = width.dp.toPx()
        val half = w / 2f
        val r = max(0f, minOf(radius.dp.toPx(), size.minDimension / 2f) - half)
        drawRoundRect(
            color = color,
            topLeft = Offset(half, half),
            size = Size(size.width - w, size.height - w),
            cornerRadius = CornerRadius(r),
            style = Stroke(width = w, pathEffect = PathEffect.dashPathEffect(floatArrayOf(dash.dp.toPx(), gap.dp.toPx()))),
        )
    }

/**
 * `.glassEffect(.regular[.tint(c)], in: shape)` บนเวทีของคลัง/หน้าเลือก — กระจกฝ้า (ดู PORTING §8)
 * `light` = เวทีสว่าง (ฝังในหน้า Star Profile) · `tint` = กระจกย้อมสีเน้น (ปุ่มหลัก)
 */
@Composable
internal fun StageGlassPanel(
    radius: Float,
    light: Boolean = false,
    tint: Color? = null,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val ink = if (light) InkStyle(CardInk.paper, GL.ink) else InkStyle.night
    CompositionLocalProvider(LocalCardInk provides ink) {
        GlassPanel(
            tint = tint,
            tintStrength = if (tint != null) 0.88 else 0.16,
            veil = if (light) null else Color.White.opacity(0.10),
            radius = radius,
            interactive = true,
            modifier = modifier,
            content = content,
        )
    }
}

/** `UIPasteboard.general.string = text` */
internal fun copyPlainText(context: Context, text: String) {
    val cm = context.getSystemService(ClipboardManager::class.java) ?: return
    cm.setPrimaryClip(ClipData.newPlainText("StarCard", text))
}

/** `ShareLink(item: url)` — ชีตแชร์ของระบบ */
internal fun sharePlainText(context: Context, text: String) {
    val send = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, text)
    }
    val chooser = Intent.createChooser(send, null)
    if (context !is android.app.Activity) chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    runCatching { context.startActivity(chooser) }
}
