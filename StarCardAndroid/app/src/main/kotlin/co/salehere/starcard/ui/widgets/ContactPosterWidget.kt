package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.layout
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.scrubDolly
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.LocalWidgetLiftsPhoto
import co.salehere.starcard.model.LocalWidgetSurface
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.EdGrain
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.PlatePatternLayer
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.SymbolIcon
import co.salehere.starcard.theme.hsb
import co.salehere.starcard.theme.mixed
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import kotlin.math.max
import kotlin.math.min

// MARK: - โปสเตอร์ติดต่อ (= Views/Widgets/ContactPosterWidget.swift)
//
// ใบที่ห้าของตระกูลคัตเอาต์ — แต่เป็น **ใบแรกของตระกูลที่อยู่หมวด "รับงาน"**
// หกแบบเดิมในตระกูล `contact` คือ *ป้ายข้อมูล* ไม่มีใบไหน **เป็นภาพ** ได้เลย
// ใบนี้ยุบ hero กับแถบติดต่อเป็นชิ้นเดียว: **คนยืนอยู่ในแผ่น ค่าติดต่อนั่งอยู่ข้างเขา**
//
// มีแค่ค่าติดต่อ ไม่มีชื่อ ไม่มีสายงาน — ตัวอักษรบนแผ่นมีสองชนิดเท่านั้น คือ **พาดหัว** กับ **ค่าที่ต้องก็อป**
// สีมาจากธีมของการ์ด ไม่ใช่จากต้นฉบับ — ทุกค่าคิดจาก `theme.backdropHue` ตัวเดียว

/**
 * ค่าคงที่ของผัง — **หน่วยเดียวกับ `WidgetKind.defaultSize`** (366 × 270)
 * เขียนเป็นตัวเลขคงที่ เพราะแผ่นย่อ/ขยายทั้งก้อนให้อยู่แล้ว ผังจึงเป็นจริงทุกขนาด
 */
object CP {
    const val w: Float = 366f
    // เตี้ยกว่ารอบแรก 30pt — ผังเดิมเหลือที่ว่างใต้แถวสุดท้ายเกือบหนึ่งในสามของแผ่น
    const val h: Float = 270f

    const val pad: Float = 22f
    /** พาดหัว — เล็กกว่ารอบแรกหนึ่งขั้น (27 → 22) เพราะคำเดียวกินความกว้างครึ่งแผ่นแล้ว */
    const val titleSize: Float = 22f

    // ── ชิปช่องทาง — ค่าแต่ละช่องนั่งใน **ชิป** ของตัวเอง ชิปหุ้มพอดีข้อความ ความยาวที่ต่างกันจึงไม่ทำให้ตัวอักษรหด
    /** ไอคอนนำหน้าในชิป */
    const val chipIcon: Float = 11.5f
    /** ขนาดของค่าที่ต้องก็อป — ใหญ่กว่าเดิมหนึ่งขั้นเต็ม เพราะมีพื้นชิปรองแล้ว */
    const val valueSize: Float = 13.5f
    const val chipPadH: Float = 12f
    const val chipPadV: Float = 7.5f
    /** ช่องไฟระหว่างไอคอนกับค่าในชิปเดียวกัน */
    const val gap: Float = 7f
    /** ระยะระหว่างชิป — แน่นพอให้สามอันอ่านเป็นก้อนเดียว */
    const val chipGap: Float = 9f
    /** ขอบบนของชิปใบแรก — ก้อนสามชิปอยู่กลางแผ่นค่อนลงล่าง */
    const val firstRow: Float = 96f

    /** ขอบซ้ายของตัวคน — ค่าติดต่อต้องจบก่อนถึงเส้นนี้เสมอ (ตัวอักษรที่ถูกไหล่กินอ่านเป็นผังที่พัง) */
    const val subjectEdge: Float = 206f
    /** ช่องยืนของคน วัดจาก **ขอบขวา** — กว้างคงที่ไม่ว่าแผ่นจะถูกลากให้กว้างแค่ไหน */
    const val subjectZone: Float = w - subjectEdge

    /** ความกว้างที่ *ตัวอักษร* ในชิปมีจริง — หักพื้นชิปกับไอคอนออกจากช่องว่างถึงตัวคนแล้ว */
    val valueW: Float get() = subjectEdge - pad - (chipPadH * 2 + chipIcon + gap) - 6
}

/**
 * วัสดุและหมึกของใบนี้ — **ทุกสีคิดจากเฉดของธีม ไม่มีสีตายตัวสักสี**
 * แผ่นเป็นสีเรียบ ไม่ใช่ไล่เฉด — สีเดียวเรียบ ๆ ทำให้ใบนี้เป็น "บล็อกสีของธีม" ที่ไม่แย่งสายตา
 */
data class ContactPosterSkin(
    /** มีแผ่นรองไหม — เจ้าของการ์ดเลือกเองจากถาด */
    val papered: Boolean,
    val plate: Color,
    val ink: Color,
    /** พื้นของชิป — ทึบบนแผ่นสี (ตัวอักษรต้องตัดกับพื้นของตัวเอง ไม่ใช่กับแผ่น) */
    val chipFill: Color,
    val chipLine: Color,
    /** หมึกในชิป — เข้มเท่าแผ่นเมื่อชิปเป็นครีม */
    val chipInk: Color,
    val chipGlyph: Color,
    /** เงาใต้ตัวคน — บนแผ่นพิมพ์ไม่มี · ตอนถอดแผ่นออกต้องมี */
    val shadow: Boolean,
) {
    companion object {
        fun make(surface: WidgetSurface, theme: CardTheme, on: InkStyle): ContactPosterSkin {
            val h = theme.backdropHue
            if (surface == WidgetSurface.pane) {
                return ContactPosterSkin(
                    papered = true, plate = Color.Transparent, ink = on.text(0.95),
                    chipFill = on.fill(0.12), chipLine = on.line(0.26),
                    chipInk = on.text(0.95), chipGlyph = on.text(0.72), shadow = false,
                )
            }
            val duo = theme.activeDuo
            if (surface != WidgetSurface.clear && duo != null) {
                return ContactPosterSkin(
                    papered = true, plate = duo.dark, ink = duo.light,
                    chipFill = duo.light.opacity(0.94), chipLine = Color.Transparent,
                    chipInk = duo.dark, chipGlyph = duo.dark.mixed(duo.light, 0.30), shadow = false,
                )
            }
            if (surface != WidgetSurface.clear) {
                val cream = PosterPlate.cream(theme)
                return ContactPosterSkin(
                    papered = true,
                    // เข้มพอให้ครีมอ่านออกทุกพาเลตต์ และอิ่มพอให้ยังเป็น *สี* ไม่ใช่เทาที่อมสี
                    plate = hsb(h, 0.62, 0.34),
                    ink = cream,
                    // ชิปครีมทึบบนแผ่นเข้ม = คู่สีที่ตัดกันแรงที่สุดที่ใบนี้มีอยู่แล้ว
                    chipFill = cream.opacity(0.94),
                    chipLine = Color.Transparent,
                    chipInk = hsb(h, 0.78, 0.18),
                    chipGlyph = hsb(h, 0.66, 0.36),
                    shadow = false,
                )
            }
            // ไม่มีแผ่น — ทุกอย่างนั่งบนการ์ดตรง ๆ หมึกพลิกตามพื้นการ์ด · ชิปเป็นพื้นโปร่งที่มีเส้นขอบ
            return ContactPosterSkin(
                papered = false, plate = Color.Transparent, ink = on.text(0.95),
                chipFill = on.fill(0.12), chipLine = on.line(0.26),
                chipInk = on.text(0.95), chipGlyph = on.text(0.72), shadow = true,
            )
        }
    }
}

@Composable
fun ContactPosterWidget(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    // แผ่นต้องเต็มกรอบเสมอ — `CP.w × CP.h` เป็นแค่ *ขนาดต่ำสุด* ของผัง (ดู `PosterSheet`)
    PosterSheet(design = Size(CP.w, CP.h), frame = size, modifier = modifier) { box ->
        ContactPosterSheet(theme, box)
    }
}

/** - box: ผังในหน่วยออกแบบที่ยืดเต็มกรอบแล้ว (≥ `CP.w × CP.h`) */
@Composable
private fun ContactPosterSheet(theme: CardTheme, box: Size) {
    val store = LocalPhotoStore.current
    val wid = LocalWidgetID.current
    val liftsPhoto = LocalWidgetLiftsPhoto.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val skin = ContactPosterSkin.make(surface, theme, cardInk)
    val plane = if (store != null) {
        cutoutPlane(store, 1, wid, liftsPhoto)
    } else {
        CutoutSample.image?.let { CutoutPlane.Subject(it, own = false) } ?: CutoutPlane.Framed
    }
    val lifting = store?.let { cutoutLifting(it, 1, wid, liftsPhoto) } ?: false
    val layoutBox = Size(CP.w, box.height)

    Box(Modifier.size(box.width.dp, box.height.dp)) {
        // ไม่มีแผ่นก็ยังตัดขอบสี่เหลี่ยม (มุม 0) เหมือนต้นฉบับ
        Box(
            Modifier
                .matchParentSize()
                .clip(RoundedCornerShape((if (skin.papered) min(theme.radius, 22f) else 0f).dp)),
        ) {
            // ── พื้น: สีเดียวเรียบ ๆ
            if (skin.papered) {
                Box(Modifier.matchParentSize().background(skin.plate))
                PlatePatternLayer(sheet = skin.plate, modifier = Modifier.matchParentSize())
                // เกล็ดจาง ๆ ชั้นเดียว — เป็นผิวของกระดาษ ไม่ใช่การไล่เฉด แผ่นยังเป็นสีเดียวทั้งใบ
                EdGrain(count = 240, opacity = 0.04, tint = Color.White, modifier = Modifier.matchParentSize())
            }

            // ── ของบนแผ่น: **กว้างเท่าผังเสมอ แล้วจัดกลางบนแผ่นที่กว้างขึ้น**
            // พาดหัว · คน · ชิป เป็นก้อนเดียวที่จัดหน้ามาแล้ว — ที่ว่างที่ได้มาเป็นขอบสองข้าง ไม่ใช่ระยะในผัง
            Box(Modifier.matchParentSize(), contentAlignment = Alignment.TopCenter) {
                Box(Modifier.size(CP.w.dp, box.height.dp)) {
                    // ── ชั้นหลัง: พาดหัว
                    ContactHeadline(skin, CP.w)
                    // ── ชั้นกลาง: คน — ยืนอยู่บน *ขอบล่างที่เห็น* ไม่ใช่ที่เส้น 270 ของผังตั้งต้น
                    ContactSubject(plane, skin, layoutBox)
                    // ── ชั้นหน้า: ค่าติดต่อ — ค่าที่ต้องก็อปต้องไม่มีวันถูกบัง
                    ContactRows(skin, layoutBox)
                }
            }
        }
        CutoutStatus(plane, theme, lifting = lifting, modifier = Modifier.align(Alignment.TopEnd).padding(9.dp))
    }
}

// MARK: พาดหัว

/**
 * `Contact` / `ME` ชิดซ้ายบน สองบรรทัด — **คู่ตัวพิมพ์ ไม่ใช่คำเดียวหนาทึบ**
 * ไม่ใช่ช่องที่พิมพ์เองได้ — มันคือ *ชื่อของแผ่น* ไม่ใช่เนื้อหาของเจ้าของการ์ด
 * ผังเดียวกับหัวของ `ReelWidget`: คำนำเซอริฟเอียงตัวบางอยู่บน คำหลักหนาทึบตัวใหญ่อยู่ล่าง
 */
@Composable
private fun ContactHeadline(skin: ContactPosterSkin, w: Float) {
    val scrub = LocalPageScrub.current
    Column(
        Modifier
            // ชั้นหลังสุดวิ่งสวนแรงที่สุด — ตาอ่านความลึกจาก *ความต่างของอัตรา* ไม่ใช่จากระยะ
            .scrubSlide(scrub.d, travel = -CP.w * 0.26f, fade = 0.84, eased = false)
            .padding(start = CP.pad.dp, top = (CP.pad * 0.8f).dp)
            .width((w - CP.pad * 2).dp),
    ) {
        Text(
            "Contact",
            style = CardFont.serif.font(CP.titleSize * 0.95f, SHFont.regular).copy(fontStyle = FontStyle.Italic),
            color = skin.ink,
            maxLines = 1,
            softWrap = false,
        )
        Text(
            "ME",
            style = sh(CP.titleSize * 1.5f, SHFont.black).copy(letterSpacing = 0.4.sp),
            color = skin.ink,
            maxLines = 1,
            softWrap = false,
            modifier = Modifier.pullUp(CP.titleSize * 0.3f),
        )
    }
}

// MARK: ค่าติดต่อ

/**
 * สามช่องทางของตระกูล (`ContactLine.all`) — **ชิปละหนึ่งช่องทาง** ไม่มีป้ายกำกับ (ไอคอนบอกเรื่องเดียวกันอยู่แล้ว)
 * ชิปหุ้ม **พอดีข้อความ** ไม่ใช่คอลัมน์กว้างเท่ากัน · ระยะมาจาก padding/spacing ของผัง ไม่ใช่ `offset`
 * (หน้ากากของ `scrubVeil` เป็นกรอบผังของชิ้น — ชิ้นที่ถูกเลื่อนไปวาดที่อื่นจะถูกตัดทิ้งทั้งแถว)
 */
@Composable
private fun ContactRows(skin: ContactPosterSkin, box: Size) {
    val scrub = LocalPageScrub.current
    val lines = ContactLine.all
    Column(
        Modifier
            .size(box.width.dp, box.height.dp)
            .padding(start = CP.pad.dp, top = CP.firstRow.dp),
        verticalArrangement = Arrangement.spacedBy(CP.chipGap.dp),
    ) {
        lines.forEachIndexed { i, l ->
            Row(
                Modifier
                    // ชิปมุดใต้ขอบไล่ทีละอัน — ภาษาเดียวกับอีกหกแบบในตระกูล
                    .scrubVeil(scrub.d, lead = Scrub.lead(i, lines.size, scrub.d, step = 0.08), drop = 26f, pull = 12f)
                    .linkSlot(l.field.contactURL)
                    .background(skin.chipFill, CircleShape)
                    .border(0.8.dp, skin.chipLine, CircleShape)
                    .padding(horizontal = CP.chipPadH.dp, vertical = CP.chipPadV.dp),
                horizontalArrangement = Arrangement.spacedBy(CP.gap.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                ContactChipGlyph(l.icon, CP.chipIcon, skin.chipGlyph)
                EditableText(
                    field = l.field,
                    style = TextSlotStyle(size = CP.valueSize, weight = SHFont.semibold, color = skin.chipInk, corner = 999f),
                    modifier = Modifier.widthIn(max = CP.valueW.dp),
                    autoSizeMin = 0.8f,
                )
            }
        }
    }
}

// MARK: คน

/**
 * ตัวคนชิดขวา ล้นขอบล่างและขอบขวาเล็กน้อย — ต้นฉบับครอปแบบนั้น
 * รอยตัดที่เอวของ PNG ส่วนใหญ่ต้องตกนอกแผ่น · เงาถูกปิดบนแผ่นพิมพ์
 * - box: ผังจริงของแผ่น — ทุกระยะของชั้นนี้คิดจากค่านี้ ไม่ใช่จาก `CP.w × CP.h`
 */
@Composable
private fun ContactSubject(plane: CutoutPlane, skin: ContactPosterSkin, box: Size) {
    val scrub = LocalPageScrub.current
    when (plane) {
        is CutoutPlane.Subject -> {
            // 0.80 ไม่ใช่เต็มใบ — หัวต้องจบ *ใต้* พาดหัว · **รูปไม่ถูกย้อมสีใด ๆ** (ผิวคนต้องไม่เพี้ยน)
            Box(
                Modifier
                    .offset((CP.w * 0.045f).dp, (box.height * 0.035f).dp)
                    .size(box.width.dp, box.height.dp),
                contentAlignment = Alignment.BottomEnd,
            ) {
                CutoutSubject(
                    image = plane.image, height = box.height * 0.80f, d = scrub.d,
                    drift = CP.w * 0.035f, shadow = skin.shadow,
                    // กรอบของ *ช่อง* เท่าตัวคนพอดี — ปุ่มเปลี่ยนรูปเกาะกรอบนี้
                    modifier = Modifier.photoSlot(1),
                )
            }
        }
        CutoutPlane.Framed -> {
            // รูปทึบ — กลับไปโหมดกรอบ **เงียบ ๆ** แผ่นมนทางขวา · ผังที่เหลือไม่ขยับสักนิด
            Box(
                Modifier
                    .offset((-CP.pad * 0.6f).dp, (-CP.pad * 0.7f).dp)
                    .size(box.width.dp, box.height.dp),
                contentAlignment = Alignment.BottomEnd,
            ) {
                Box(
                    Modifier
                        .size((CP.subjectZone - 6f).dp, (box.height * 0.62f).dp)
                        .photoSlot(1)
                        .clip(RoundedCornerShape(16.dp)),
                ) {
                    WidgetPhoto(1, Modifier.fillMaxSize().scrubDolly(scrub.d, shift = CP.w * 0.04f, zoom = 0.12f))
                }
            }
        }
    }
}

// MARK: - เครื่องมือ (ส่วนตัว)

/** VStack ที่ระยะติดลบ (= `.padding(.top, -x)`) — ดึงชิ้นขึ้น `dy` pt และหักความสูงเท่ากันออกจากผัง */
private fun Modifier.pullUp(dy: Float): Modifier = layout { m, c ->
    val p = m.measure(c)
    val d = dy.dp.roundToPx()
    layout(p.width, max(0, p.height - d)) { p.place(0, -d) }
}

/**
 * ไอคอนช่องทางในชิป (`Image(systemName:)` ขนาดฟอนต์ `size`) — สามชื่อของ `ContactLine`
 * ตารางกลางไม่มีคู่ที่ตรงความหมาย จึงเลือก/วาดเอง · กล่องใหญ่กว่าขนาดฟอนต์ 15% ให้สูงเท่าสัญลักษณ์ของ iOS
 */
@Composable
private fun ContactChipGlyph(name: String, size: Float, tint: Color) {
    val box = size * 1.15f
    when (name) {
        "phone.fill" -> SymbolIcon(SHIcon.phoneCall, size = box, tint = tint)
        "message.fill" -> PIcon(Ph.chatCircle, size = box, weight = PhWeight.fill, tint = tint)
        "envelope.fill" -> Canvas(Modifier.size(box.dp).graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen)) {
            val g = this.size.minDimension
            val ox = (this.size.width - g) / 2f
            val oy = (this.size.height - g) / 2f
            fun p(x: Float, y: Float) = Offset(ox + x * g, oy + y * g)
            drawRoundRect(tint, topLeft = p(0.06f, 0.2f), size = Size(0.88f * g, 0.6f * g), cornerRadius = CornerRadius(0.08f * g, 0.08f * g))
            val f0 = p(0.1f, 0.26f)
            val f1 = p(0.5f, 0.56f)
            val f2 = p(0.9f, 0.26f)
            drawPath(
                Path().apply { moveTo(f0.x, f0.y); lineTo(f1.x, f1.y); lineTo(f2.x, f2.y) }, Color.Black,
                style = Stroke(width = 0.07f * g, cap = StrokeCap.Round, join = StrokeJoin.Round), blendMode = BlendMode.Clear,
            )
        }
        else -> SFSymbol(name, size = box, tint = tint)
    }
}
