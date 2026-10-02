package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.layout
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.LocalWidgetSurface
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.EdGrain
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PlatePatternLayer
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.SaleHereMark
import co.salehere.starcard.theme.Signature
import co.salehere.starcard.theme.StarLockup
import co.salehere.starcard.theme.SymbolIcon
import co.salehere.starcard.theme.TextFit
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.editor.dataValue
import kotlin.math.min

// MARK: - ตรารับรอง · Verified by Sale Here (= Views/Widgets/VerifiedSealWidget.swift)
//
// ใบที่ห้าของสำรับโปสเตอร์ และเป็นใบเดียวที่ **เนื้อหาคือคำรับรอง** ไม่ใช่ตัวเลขหรือรูป
// เจ้าของเป็นคน **หยิบคำรับรองมาวางเอง** เหมือนแขวนใบประกาศไว้ที่ผนังร้าน — มันจึงต้องสวยพอที่คนอยากแขวน
// ภาษาของใบนี้คือเอกสารมีค่า: **ลายกิโยเช่** · **เหรียญตราประทับ** · **ตัวอักษรวิ่งรอบตรา** — ทุกสีคิดจากเฉดของการ์ด
// (`VerifiedFacts` อยู่ใน theme/VerifiedFacts.kt · `VerifiedSeal`/`RingText`/`Guilloche`/`DotLeader` อยู่ใน WidgetKit.kt)

/** ค่าคงที่ของผัง — หน่วยเดียวกับ `WidgetKind.defaultSize` (366 × 232) */
object VS {
    const val w: Float = 366f
    const val h: Float = 232f
    const val pad: Float = 18f

    /** ศูนย์กลางเหรียญ วัดจากขอบซ้ายของผัง — เหรียญกินราว 45% ของแผ่น ตัวอักษรได้ที่เหลือ */
    const val medalX: Float = 94f
    /** รัศมีของวงตัวอักษร · เหรียญ · ลายกิโยเช่ (ใหญ่กว่าแผ่นโดยตั้งใจ ให้ขอบแผ่นตัด) */
    const val ringR: Float = 68f
    const val foilR: Float = 50f
    const val laceR: Float = 138f

    /** คอลัมน์ตัวอักษรเริ่มตรงไหน */
    const val colX: Float = 182f

    const val cap1: Float = 22f
    const val cap2: Float = 34f
}

// MARK: - วัสดุ

/** หมึกและแผ่นของใบนี้ — ทุกสีคิดจากเฉดของธีม (สูตรเดียวกับ `StatPosterSkin`) */
data class VerifiedSealSkin(
    var papered: Boolean,
    var plate: Color,
    var ink: Color,
    var soft: Color,
    var accent: Color,
    var hair: Color,
    /** สีของลายกิโยเช่ — หมึกเดียวกับตัวอักษรแต่จางจนเป็นผิวของแผ่น ไม่ใช่ลวดลาย */
    var lace: Color,
    /** สีที่ใช้เจาะเครื่องหมายถูกลงบนเหรียญ — สีของพื้นใต้เหรียญ */
    var punch: Color,
) {
    companion object {
        fun make(surface: WidgetSurface, theme: CardTheme, on: InkStyle): VerifiedSealSkin {
            if (surface != WidgetSurface.glass) {
                return VerifiedSealSkin(
                    papered = surface == WidgetSurface.pane, plate = Color.Transparent,
                    ink = on.text(0.95), soft = on.text(0.58),
                    accent = theme.accent, hair = on.line(0.24),
                    lace = on.line(if (on.isLight) 0.16 else 0.13),
                    punch = if (on.isLight) grey(0.97) else grey(0.10),
                )
            }
            val cream = PosterPlate.cream(theme)
            val plate = PosterPlate.plate(theme)
            return VerifiedSealSkin(
                papered = true, plate = plate,
                ink = cream, soft = cream.opacity(0.64),
                accent = theme.rawAccent, hair = cream.opacity(0.24),
                lace = cream.opacity(0.10), punch = plate,
            )
        }
    }
}

/** `.opacity(k)` ของ SwiftUI บนสีที่โปร่งอยู่แล้ว — **คูณ** กับความทึบเดิม */
private fun Color.scaledAlpha(k: Double): Color = copy(alpha = (alpha * k.toFloat()).coerceIn(0f, 1f))

/**
 * `.position(x:y:)` ของ SwiftUI — กินพื้นที่ที่ได้รับทั้งหมด แล้ววางจุดกลางของลูกไว้ที่ (x, y) หน่วยออกแบบ
 * ลูกได้ขนาดของตัวเองเต็ม ๆ (ลายกิโยเช่ใหญ่กว่าแผ่นโดยตั้งใจ)
 */
private fun Modifier.centerAt(x: Float, y: Float): Modifier = layout { measurable, constraints ->
    val p = measurable.measure(Constraints())
    val w = if (constraints.hasBoundedWidth) constraints.maxWidth else p.width
    val h = if (constraints.hasBoundedHeight) constraints.maxHeight else p.height
    layout(w, h) {
        p.place(x.dp.roundToPx() - p.width / 2, y.dp.roundToPx() - p.height / 2)
    }
}

// MARK: - ใบ

@Composable
fun VerifiedSealWidget(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    PosterSheet(
        design = Size(VS.w, VS.h),
        frame = size,
        modifier = modifier
            .linkSlot(VerifiedFacts.sheetURL)
            .clearAndSetSemantics { contentDescription = "Verified by Sale Here" },
    ) { box ->
        SealSheet(theme, box)
    }
}

@Composable
private fun SealSheet(theme: CardTheme, box: Size) {
    val scrub = LocalPageScrub.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val facts = VerifiedFacts.current
    val skin = VerifiedSealSkin.make(surface, theme, cardInk)
    val shape = RoundedCornerShape((if (skin.papered) min(theme.radius, 20f) else 0f).dp)
    // ของบนแผ่นกว้างเท่าผังเสมอแล้วจัดกลาง — ที่ว่างที่ได้มาคือขอบสองข้าง (ดู `PosterSheet`)
    val inset = (box.width - VS.w) / 2f
    val cy = box.height / 2f

    Box(Modifier.size(box.width.dp, box.height.dp).clip(shape)) {
        if (surface == WidgetSurface.glass) {
            Box(Modifier.matchParentSize().background(skin.plate))
            PlatePatternLayer(skin.plate, Modifier.matchParentSize())
            EdGrain(count = 280, opacity = 0.045, tint = Color.White, modifier = Modifier.matchParentSize())
        }

        // ── ลายกิโยเช่ · ศูนย์กลางเดียวกับเหรียญ ใหญ่กว่าแผ่นแล้วให้ขอบแผ่นตัด
        Guilloche(
            skin.lace,
            Modifier
                .centerAt(inset + VS.medalX, cy)
                .scrubSlide(scrub.d, travel = -VS.w * 0.10f, fade = 0.9, eased = false)
                .size((VS.laceR * 2f).dp),
        )

        SealMedal(facts, skin, Modifier.centerAt(inset + VS.medalX, cy))

        SealColumn(
            facts, skin,
            Modifier
                .offset(x = (inset + VS.colX).dp)
                .width((VS.w - VS.colX - VS.pad).dp)
                .fillMaxHeight(),
        )
    }
}

// MARK: เหรียญ

/** สามชั้นจากนอกเข้าใน — วงตัวอักษร · เส้นวง · เหรียญแปดกลีบ */
@Composable
private fun SealMedal(facts: VerifiedFacts, skin: VerifiedSealSkin, modifier: Modifier) {
    val scrub = LocalPageScrub.current
    val ring = "VERIFIED BY SALE HERE  ✦  IDENTITY  ✦  CHANNELS  ✦  NUMBERS  ✦  "
    // หมุนตามนิ้วตอนปัดหน้าเท่านั้น — ของที่ขยับไม่หยุดแย่งสายตาจากงานของเจ้าของ
    val spin = scrub.d * 70f

    Box(
        modifier
            .scrubSlide(scrub.d, travel = -VS.w * 0.04f, fade = 0.95, eased = false)
            .size(((VS.ringR + 12f) * 2f).dp),
        contentAlignment = Alignment.Center,
    ) {
        RingText(
            ring, radius = VS.ringR, size = 7.2f, color = skin.ink.scaledAlpha(0.78),
            modifier = Modifier.graphicsLayer { rotationZ = spin },
        )

        Box(Modifier.size(((VS.ringR - 9f) * 2f).dp).border(0.7.dp, skin.hair, CircleShape))
        Box(Modifier.size(((VS.ringR + 9f) * 2f).dp).border(0.7.dp, skin.hair.scaledAlpha(0.7), CircleShape))

        if (facts.verified) {
            VerifiedSeal(radius = VS.foilR, punch = skin.punch, tint = skin.ink)
        } else {
            // ยังไม่ครบ — เหรียญเป็นโครงเปล่า ไม่มีหมึก ไม่มีเครื่องหมายถูก
            val soft = skin.soft
            Canvas(Modifier.size((VS.foilR * 2f).dp)) {
                drawPath(
                    SealScallop().path(size),
                    soft,
                    style = Stroke(
                        width = 1.dp.toPx(),
                        pathEffect = PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(), 3.dp.toPx())),
                    ),
                )
            }
            PIcon(Ph.clock, size = 26f, tint = soft)
        }
    }
}

// MARK: คอลัมน์ตัวอักษร

@Composable
private fun SealColumn(facts: VerifiedFacts, skin: VerifiedSealSkin, modifier: Modifier) {
    val scrub = LocalPageScrub.current
    val measurer = TextFit.rememberMeasurer()
    val w = VS.w - VS.colX - VS.pad
    val l1 = if (facts.verified) "VERIFIED by" else "PENDING with"
    val fs1 = Ed.fitted(measurer, l1, SHFont.heavy, width = w * 0.74f, cap = VS.cap1, floor = 12f)

    Column(modifier.padding(top = 14.dp, bottom = 13.dp)) {
        // บรรทัดบนผสมสองฟอนต์ตามกติกาของสำรับ · บรรทัดล่างคือ **ตัวเขียน Sale Here ตัวจริง**
        // (ลายเซ็นต้องเป็นตัวจริง ไม่ใช่ตัวเลียน — ตัวเขียนนี้คือสิ่งที่คนเห็นในแอปทุกวัน)
        Column(
            Modifier.scrubSlide(scrub.d, travel = -VS.w * 0.22f, fade = 0.84, eased = false),
            verticalArrangement = Arrangement.spacedBy(1.dp),
        ) {
            Text(
                sealHeadline(l1),
                style = sh(fs1, SHFont.heavy),
                color = skin.ink,
                maxLines = 1,
                softWrap = false,
                autoSize = TextAutoSize.StepBased(
                    minFontSize = (fs1 * 0.5f).sp, maxFontSize = fs1.sp, stepSize = 0.5.sp,
                ),
            )
            SymbolIcon(SHIcon.wordmark, size = 62f, tint = skin.ink)
        }

        Box(
            Modifier
                .scrubVeil(scrub.d, lead = 0.1, drop = 14f, pull = 18f)
                .padding(top = 6.dp)
                .fillMaxWidth()
                .height(1.4.dp)
                .background(skin.accent),
        )

        Column(Modifier.padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            facts.core.forEach { r ->
                FactRow(r, skin, Modifier.scrubVeil(scrub.d, lead = 0.12 + r.id * 0.06, drop = 14f, pull = 10f))
            }
        }

        // `Spacer(minLength: 4)`
        Spacer(Modifier.height(4.dp))
        Spacer(Modifier.weight(1f))

        Row(
            Modifier.fillMaxWidth().scrubVeil(scrub.d, lead = 0.3, drop = 12f, pull = 8f),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.Bottom,
        ) {
            // วงแดงของผู้ออก — สีแบรนด์ที่เดียวบนแผ่น ตาจับได้จากภาพรวมว่าใบนี้ของ Sale Here
            SaleHereMark(size = 21f)
            Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
                Text(
                    "STAR CARD NO.",
                    style = Signature.mono(6f, FontWeight.SemiBold).copy(letterSpacing = 0.9.sp),
                    color = skin.soft.scaledAlpha(0.8),
                    maxLines = 1,
                    softWrap = false,
                )
                Text(
                    facts.serial,
                    style = Signature.mono(9f, FontWeight.Bold).copy(letterSpacing = 0.6.sp),
                    color = skin.soft,
                    maxLines = 1,
                    softWrap = false,
                    modifier = Modifier.dataValue(),
                )
            }
            Spacer(Modifier.weight(1f))
            // ตราจริง ขนาดใกล้ของจริง ย้อมหมึกของแผ่น — ผู้ออกคำรับรองเซ็นชื่อมุมขวาล่าง
            StarLockup(height = 20f, tint = skin.ink.scaledAlpha(0.92))
        }
    }
}

/** ชื่อข้อ ···· ค่า — เส้นจุดไข่ปลาแบบสารบัญ/ใบเสร็จ ตาวิ่งจากข้อไปหาวันที่ได้เอง */
@Composable
private fun FactRow(r: VerifiedFacts.Row, skin: VerifiedSealSkin, modifier: Modifier) {
    Row(modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(5.dp)) {
        Text(
            r.title,
            style = sh(10.5f, SHFont.semibold),
            color = if (r.ok) skin.ink else skin.soft,
            maxLines = 1,
            softWrap = false,
            modifier = Modifier.alignByBaseline(),
        )
        // ไม่มีเส้นฐานตัวอักษร — ขอบล่างของเส้นประเกาะเส้นฐานของแถว (เหมือน SwiftUI)
        DotLeader(skin.hair, Modifier.weight(1f).alignBy { it.measuredHeight })
        Text(
            r.value,
            style = Signature.mono(9f, FontWeight.SemiBold),
            color = if (r.ok) skin.soft else skin.accent,
            maxLines = 1,
            softWrap = false,
            modifier = Modifier.alignByBaseline().dataValue(),
        )
    }
}

/**
 * คำแรกหนา · ที่เหลือเซริฟเอียง (กติกาเดียวกับ `StatPosterWidget.mixedLine`)
 * พาดหัวใบนี้เป็นคำของผู้รับรอง จึงไม่ผ่านการปรับของเจ้าของการ์ด · ขนาดเป็น em ให้ย่อตามกล่องได้
 */
private fun sealHeadline(raw: String): AnnotatedString {
    val s = raw.trimStart(' ')
    val cut = s.indexOf(' ')
    val head = (if (cut < 0) s else s.substring(0, cut)).uppercase()
    val tail = if (cut < 0) "" else s.substring(cut + 1).trimStart(' ')
    val serif = CardFont.serif.family
    return buildAnnotatedString {
        withStyle(SpanStyle(letterSpacing = (-0.03).em)) { append(head) }
        if (tail.isNotEmpty()) {
            withStyle(
                SpanStyle(
                    fontFamily = serif, fontWeight = FontWeight.Normal,
                    fontStyle = FontStyle.Italic, fontSize = 1.06.em,
                ),
            ) { append(" $tail") }
        }
    }
}
