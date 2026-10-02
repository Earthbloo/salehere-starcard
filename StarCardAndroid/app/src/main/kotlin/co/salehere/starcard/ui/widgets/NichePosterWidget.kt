package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
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
import androidx.compose.runtime.key
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.layout
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.redacted
import co.salehere.starcard.components.scrubDolly
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.LocalWidgetLiftsPhoto
import co.salehere.starcard.model.LocalWidgetSurface
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.EdGrain
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.PlatePatternLayer
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.TextAlignment
import co.salehere.starcard.theme.TextFit
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalGhostData
import co.salehere.starcard.ui.LocalSlotTilt
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import co.salehere.starcard.ui.editor.editableSlot
import java.util.UUID
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

// MARK: - โปสเตอร์สายงาน (= Views/Widgets/NichePosterWidget.swift)
//
// ใบที่สี่ของตระกูลคัตเอาต์ — แปลงตรงจากแผ่น **MY Niche & SPECIALITIES** · ฟอนต์ใช้ของแอป
// เอาคำชุดเดียวกับชิปสายงานไป **ล้อมตัวคน** — จาก "เขาเลือกหมวดพวกนี้" เป็น "เขาทำงานพวกนี้อยู่"
//
// สามชั้นที่ต้องทับกันจริง:
// 1. **คำพาดหัวสองบรรทัด** กินเต็มความกว้าง — ชั้นหลังสุด
// 2. **ป้ายสองปีก** ซ้าย/ขวา ถอยเข้าหากลางแผ่นทีละแถวตามตัวคนที่กว้างขึ้นข้างล่าง
// 3. **คน** PNG พื้นหลังใสของเจ้าของการ์ด ยืนกลางช่องว่างที่สองปีกเปิดไว้ให้ — ชั้นหน้าสุด

/**
 * ค่าคงที่ของผัง — **หน่วยเดียวกับ `WidgetKind.defaultSize`** (366 × 221)
 * ทุกค่าคือระยะของต้นฉบับ (472 × 285) คูณ 0.775 ตรง ๆ ไม่มีค่าไหนถูกเดาขึ้นมาใหม่
 */
object NP {
    const val w: Float = 366f
    const val h: Float = 221f

    /** ขอบของแถวป้าย — แคบกว่าใบอื่นในตู้ ป้ายต้องเกือบชนขอบแผ่นแบบโปสเตอร์ */
    const val pad: Float = 12f
    /** ขอบของก้อนตัวอักษร — กว้างกว่าป้าย คำยักษ์จึงไม่ไปชนมุมมนของแผ่น */
    const val typePad: Float = 20f
    const val typeTop: Float = 14f
    /** เพดานของสองบรรทัด — บรรทัดล่างใหญ่กว่าชัดเจนตามต้นฉบับ */
    const val cap1: Float = 35f
    const val cap2: Float = 44f
    /** ความกว้างที่แต่ละบรรทัดถูก *จัดให้เต็ม* — **ไม่ใช่เต็มแผ่น** (ความต่างทำให้ก้อนพาดหัวเป็นรูปทรง) */
    const val line1W: Float = 0.74f
    const val line2W: Float = 0.86f

    /** **ช่องว่างกลางแผ่นที่ห้ามมีป้าย** — ที่ยืนของคน · ตัวเลขนี้คือหัวใจของผังทั้งใบ */
    const val clearW: Float = 134f
    /** ความกว้างสูงสุดของป้ายที่แถวบนสุด (แถวล่างได้น้อยลงตาม `arc`) */
    val colW: Float get() = (w - clearW) / 2 - pad

    /** แถบที่แถวป้ายนั่งอยู่ — แถวถูกจัดกลางแถบนี้ ไม่ใช่ไล่ลงจากขอบบน */
    const val bandTop: Float = 99f
    const val bandBottom: Float = 207f
    const val pitch: Float = 29f
    const val pillH: Float = 24f
    /** ขนาดตัวอักษรในป้าย — ขยายจาก 10 ของสไลด์ เพราะไทย 10pt บนการ์ดกว้าง ~360pt อ่านไม่ออก */
    const val pillFont: Float = 13f
    /** ระยะที่ป้ายแถวล่างสุดถอยเข้าหากลางแผ่น — ตามส่วนที่กว้างที่สุดของตัวคน */
    const val arc: Float = 42f
    /** สองปีก ปีกละสี่ — เกินจากนี้ผังของต้นฉบับไม่มีที่ให้ */
    const val maxRows: Int = 4

    /**
     * ระยะถอยของแถวที่จุดกึ่งกลางอยู่สูง `y` — โค้งตาม **ตำแหน่งจริงบนแผ่น** ไม่ใช่ลำดับแถว
     * สิ่งที่ดันป้ายคือ *ตัวคน* ซึ่งอยู่ที่เดิมไม่ว่าจะมีกี่แถว
     */
    fun inset(atY: Float): Float {
        val t = min(1f, max(0f, (atY - h * 0.42f) / (h * 0.52f)))
        return arc * t.toDouble().pow(2.2).toFloat()
    }
}

/**
 * วัสดุและหมึกของใบนี้ — **ทุกสีคิดจากเฉดของธีม ไม่มีสีตายตัวสักสี**
 * เก็บ **ความสัมพันธ์** ของต้นฉบับไว้แทนตัวสี: แผ่นเข้มจัดอิ่มสี · หมึกเป็นครีมที่อมเฉดเดียวกัน
 */
data class NicheSkin(
    val papered: Boolean,
    val plate: Color,
    val ink: Color,
    val pillLine: Color,
    val pillFill: Color,
    /** เงาใต้ตัวคน — บนแผ่นพิมพ์ไม่มี · ตอนถอดแผ่นออกต้องมี เพราะพื้นข้างหลังกลายเป็นการ์ด */
    val shadow: Boolean,
) {
    companion object {
        fun make(surface: WidgetSurface, theme: CardTheme, on: InkStyle): NicheSkin {
            if (surface == WidgetSurface.pane) {
                return NicheSkin(
                    papered = true, plate = Color.Transparent,
                    ink = on.text(0.95), pillLine = on.line(0.26), pillFill = on.fill(0.06), shadow = false,
                )
            }
            if (surface != WidgetSurface.clear) {
                // สีแผ่นกับครีมมาจากสูตรกลางของตู้ (`PosterPlate`) — การ์ดที่วางหลายใบได้แผ่นสีเดียวกันเป๊ะ
                val cream = PosterPlate.cream(theme)
                return NicheSkin(
                    papered = true, plate = PosterPlate.plate(theme),
                    ink = cream, pillLine = cream.opacity(0.42), pillFill = cream.opacity(0.05), shadow = false,
                )
            }
            return NicheSkin(
                papered = false, plate = Color.Transparent,
                ink = on.text(0.95), pillLine = on.line(0.26), pillFill = on.fill(0.06), shadow = true,
            )
        }
    }
}

/** สองบรรทัดพาดหัวเป็นของ **ดีไซน์** ไม่ใช่ของโปรไฟล์ จึงเก็บต่อชิ้น */
private const val nicheLine1Preset = "MY Niche &"
private const val nicheLine2Preset = "SPECIALITIES"

@Composable
fun NichePosterWidget(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    // แผ่นต้องเต็มกรอบเสมอ — `NP.w × NP.h` เป็นแค่ *ขนาดต่ำสุด* ของผัง (ดู `PosterSheet`)
    PosterSheet(design = Size(NP.w, NP.h), frame = size, modifier = modifier) { box ->
        NicheSheet(theme, box)
    }
}

/** - box: ผังในหน่วยออกแบบที่ยืดเต็มกรอบแล้ว (≥ `NP.w × NP.h`) */
@Composable
private fun NicheSheet(theme: CardTheme, box: Size) {
    val store = LocalPhotoStore.current
    val wid = LocalWidgetID.current
    val liftsPhoto = LocalWidgetLiftsPhoto.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val skin = NicheSkin.make(surface, theme, cardInk)
    val plane = if (store != null) {
        cutoutPlane(store, 1, wid, liftsPhoto)
    } else {
        CutoutSample.image?.let { CutoutPlane.Subject(it, own = false) } ?: CutoutPlane.Framed
    }
    val lifting = store?.let { cutoutLifting(it, 1, wid, liftsPhoto) } ?: false
    // แท็กที่ได้ขึ้นแผ่นจริง — แปดใบ สองปีก ปีกละสี่ (ที่เหลือยังอยู่ครบใน `nicheTags`)
    val items = Profile.me.categories.take(NP.maxRows * 2)
    val shape = RoundedCornerShape((if (skin.papered) min(theme.radius, 20f) else 0f).dp)

    Box(Modifier.size(box.width.dp, box.height.dp).clip(shape)) {
        // ── แผ่น
        if (skin.papered) {
            Box(Modifier.matchParentSize().background(skin.plate))
            PlatePatternLayer(sheet = skin.plate, modifier = Modifier.matchParentSize())
            // เกล็ดจาง ๆ ชั้นเดียว — แผ่นสีเรียบล้วนที่ความกว้างเท่านี้อ่านเป็นรูปที่ยังโหลดไม่เสร็จ
            EdGrain(count = 260, opacity = 0.04, tint = Color.White, modifier = Modifier.matchParentSize())
        }

        // ── ชั้นหลัง: คำพาดหัวสองบรรทัด
        NicheHeadline(skin, box.width, wid)

        // ── ชั้นกลาง: สองปีก
        NicheWings(skin, items, box.width)

        // ── ชั้นหน้า: คน
        NicheSubject(plane, skin, box.width)

        // ป้ายสถานะไปอยู่ **ขวาบน** — ซ้ายบนของใบนี้คือตัวแรกของคำพาดหัว
        CutoutStatus(plane, theme, lifting = lifting, modifier = Modifier.align(Alignment.TopEnd).padding(9.dp))
    }
}

// MARK: คำพาดหัว

/**
 * สองบรรทัดกลางแผ่น — **แต่ละบรรทัดถูกจัดให้เต็มความกว้างของตัวเอง** (ดู `NP.line1W`)
 * บรรทัดบน: **คำแรกหนา ที่เหลือเซริฟเอียง** — พิมพ์ทับได้ทั้งบรรทัดในช่องเดียว แล้วหน้าตาสองท่อนยังอยู่
 */
@Composable
private fun NicheHeadline(skin: NicheSkin, w: Float, wid: UUID?) {
    val scrub = LocalPageScrub.current
    val tune = LocalWidgetTextStyle.current
    val measurer = TextFit.rememberMeasurer()
    val width = w - NP.typePad * 2
    val l1 = Profile.me.note(wid, 1, nicheLine1Preset)
    val l2 = Profile.me.note(wid, 2, nicheLine2Preset).uppercase()
    val fs1 = Ed.fitted(measurer, l1, SHFont.heavy, width = w * NP.line1W, cap = NP.cap1, floor = 13f)
    val fs2 = Ed.fitted(measurer, l2, SHFont.heavy, width = w * NP.line2W, cap = NP.cap2, floor = 13f)

    // ระยะระหว่างบรรทัดติดลบ 0.30 — หักที่ว่างที่ฟอนต์เผื่อไว้ แต่พาดหัวไทยยังมีที่ให้สระอยู่
    Column(
        Modifier
            // ชั้นหลังสุดวิ่งสวนแรงที่สุด — ตาอ่านความลึกจาก *ความต่างของอัตรา* ไม่ใช่จากระยะ
            .scrubSlide(scrub.d, travel = -NP.w * 0.26f, fade = 0.84, eased = false)
            .padding(start = NP.typePad.dp, end = NP.typePad.dp, top = NP.typeTop.dp)
            .width(width.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        NicheMixedLine(
            raw = l1, size = fs1, color = skin.ink,
            id = TextSlotID(field = ProfileField.note, index = 1, widget = wid, preset = nicheLine1Preset, hint = "พาดหัวบรรทัดบน"),
            style = TextSlotStyle(
                size = fs1, weight = SHFont.heavy, color = skin.ink, align = TextAlign.Center,
                tracking = -fs1 * 0.03f, corner = 6f,
            ),
        )
        // heavy ไม่ใช่ black — ที่น้ำหนักหนาสุด NotoSansThai วางสระบนชนวรรณยุกต์
        EditableText(
            field = ProfileField.note, index = 2, widget = wid, preset = nicheLine2Preset, hint = "พาดหัวบรรทัดล่าง",
            style = TextSlotStyle(
                size = fs2, weight = SHFont.heavy, color = skin.ink, align = TextAlign.Center,
                tracking = -tune.scaled(fs2, ProfileField.note, 2) * 0.03f, uppercase = true, corner = 6f,
            ),
            text = l2,
            modifier = Modifier.pullUp(fs1 * 0.30f),
            autoSizeMin = 0.4f,
        )
    }
}

/** คำแรกหนา · ที่เหลือเซริฟเอียง — ข้อความก้อนเดียวที่ย่อพร้อมกันทั้งบรรทัด (ท่อนหางเป็น em จึงย่อตาม) */
@Composable
private fun NicheMixedLine(raw: String, size: Float, color: Color, id: TextSlotID, style: TextSlotStyle) {
    val tune = LocalWidgetTextStyle.current
    val ghost = LocalGhostData.current
    val s = tune.scaled(size, ProfileField.note, 1)
    val trimmed = raw.trimStart(' ')
    val k = trimmed.indexOf(' ')
    val head = if (k < 0) trimmed else trimmed.substring(0, k)
    val tail = if (k < 0) "" else trimmed.substring(k + 1)
    // ฟอนต์ที่ผู้ใช้สั่งทับมาก่อนเซริฟของดีไซน์ — สั่งแล้วต้องได้ทั้งบรรทัด ไม่ใช่ครึ่งเดียว
    val tailFace = tune.face(ProfileField.note, 1) ?: CardFont.serif
    val text = buildAnnotatedString {
        withStyle(SpanStyle(letterSpacing = (-0.03f).em)) { append(head.uppercase()) }
        if (tail.isNotEmpty()) {
            // เซริฟที่ขนาดเท่ากันดู *เตี้ยกว่า* ตัวหนา (x-height ต่างกัน) — ชดเชยขึ้นเล็กน้อย
            withStyle(
                SpanStyle(
                    fontFamily = tailFace.family, fontWeight = FontWeight.Normal,
                    fontStyle = FontStyle.Italic, fontSize = 1.04f.em,
                ),
            ) { append(" $tail") }
        }
    }
    Text(
        text,
        style = tune.font(size, SHFont.heavy, ProfileField.note, 1),
        color = color,
        maxLines = 1,
        softWrap = false,
        autoSize = TextAutoSize.StepBased(minFontSize = (s * 0.4f).sp, maxFontSize = s.sp, stepSize = 0.5.sp),
        modifier = Modifier.editableSlot(id, tunedSlot(id, style)).redacted(ghost),
    )
}

// MARK: สองปีก

@Composable
private fun NicheWings(skin: NicheSkin, items: List<String>, w: Float) {
    val scrub = LocalPageScrub.current
    val measurer = TextFit.rememberMeasurer()
    val rows = min(NP.maxRows, (items.size + 1) / 2)
    val blockH = max(rows - 1, 0) * NP.pitch + NP.pillH
    val top = (NP.bandTop + NP.bandBottom) / 2 - blockH / 2

    // ลบแท็กออกหนึ่งใบแล้วลำดับที่เหลือเลื่อน — ผูก key กับลิสต์ ไม่งั้นป้ายใบถัดไปถือ index เดิมแล้วแก้ผิดใบ
    key(items) {
        Box(Modifier.size(w.dp, NP.h.dp)) {
            for (r in 0 until rows) {
                val y = top + r * NP.pitch
                val inset = NP.inset(atY = y + NP.pillH / 2)
                val lead = Scrub.lead(r, rows, scrub.d, step = 0.07)
                // แถวป้ายกว้างเท่า **ผัง** เสมอ แล้วจัดกลางในแผ่นที่กว้างขึ้น — ระยะจากตัวคนถึงป้ายจึงคงที่
                Box(
                    Modifier.offset(y = y.dp).size(w.dp, NP.pillH.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Row(
                        Modifier
                            .size(NP.w.dp, NP.pillH.dp)
                            .padding(horizontal = (NP.pad + inset).dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        items.getOrNull(2 * r)?.let { s ->
                            NichePill(s, 2 * r, skin, NP.colW - inset, lead, -NP.w * 0.2f, measurer)
                        }
                        Spacer(Modifier.weight(1f))
                        items.getOrNull(2 * r + 1)?.let { s ->
                            NichePill(s, 2 * r + 1, skin, NP.colW - inset, lead, NP.w * 0.2f, measurer)
                        }
                    }
                }
            }
        }
    }
}

/**
 * ป้ายหนึ่งใบ — **กว้างตามคำที่อยู่ข้างใน แต่ไม่เกินที่ว่างของแถวนั้น**
 * วัดเอง เพราะป้ายที่ยืดจนสุดเพดานทุกใบอ่านเป็นตาราง ไม่ใช่แท็ก
 */
@Composable
private fun NichePill(
    text: String,
    index: Int,
    skin: NicheSkin,
    maxW: Float,
    lead: Double,
    travel: Float,
    measurer: TextMeasurer,
) {
    val scrub = LocalPageScrub.current
    val sidePad = 10f
    val natural = TextFit.metrics(measurer, text, CardFont.noto, SHFont.semibold, NP.pillFont, TextAlignment.leading).ink.width
    val width = min(natural + sidePad * 2 + 2, max(maxW, 44f))
    Box(
        Modifier
            // ปีกซ้ายไปซ้าย ปีกขวาไปขวา — สองข้างแยกจากกันตอนเลื่อน แล้วหุบกลับมาหาคน
            .scrubSlide(scrub.d, travel = travel, lead = lead, fade = 0.55)
            .size(width.dp, NP.pillH.dp)
            .background(skin.pillFill, CircleShape)
            .border(0.8.dp, skin.pillLine, CircleShape)
            .padding(horizontal = sidePad.dp),
        contentAlignment = Alignment.Center,
    ) {
        // พื้นย่อสุดที่ยังอ่านออก 0.72 · ลบข้อความจนหมดแล้วปิดช่อง = เอาป้ายใบนั้นออก
        EditableText(
            field = ProfileField.categories, index = index,
            style = TextSlotStyle(size = NP.pillFont, weight = SHFont.semibold, color = skin.ink, corner = 12f),
            text = text,
            autoSizeMin = 0.72f,
        )
    }
}

// MARK: คน

@Composable
private fun NicheSubject(plane: CutoutPlane, skin: NicheSkin, w: Float) {
    val scrub = LocalPageScrub.current
    when (plane) {
        is CutoutPlane.Subject -> {
            // สูง 0.70 ของแผ่น — ขอบบนของหัวไปตกที่ขอบบนของคำยักษ์บรรทัดล่างพอดี บรรทัดบนจึงไม่ถูกบัง
            // เพดานความกว้าง: รูปทรงกว้าง (คนนั่ง · กางแขน) แปลง "กว้างได้แค่ไหน" กลับเป็น "สูงได้แค่ไหน"
            val ui = plane.image
            val ar = if (ui.height > 0) ui.width.toFloat() / ui.height else 0.7f
            val cap = NP.clearW * 1.08f / max(ar, 0.05f)
            val hh = min(NP.h * 0.70f, cap)
            Box(
                // ล้นขอบล่างเล็กน้อย — รอยตัดที่เอวจะได้จบนอกแผ่น ไม่ใช่กลางแผ่น
                Modifier.offset(y = (NP.h * 0.03f).dp).size(w.dp, NP.h.dp),
                contentAlignment = Alignment.BottomCenter,
            ) {
                CutoutSubject(
                    image = ui, height = hh, d = scrub.d, drift = NP.w * 0.035f, shadow = skin.shadow,
                    // กรอบของ *ช่อง* เท่าตัวคนพอดี — ปุ่มเปลี่ยนรูปเกาะกรอบนี้
                    modifier = Modifier.photoSlot(1),
                )
            }
        }
        CutoutPlane.Framed -> {
            // รูปทึบ — แผ่นยังเป็นแผ่นใบเดิม เปลี่ยนแค่ว่ารูปถูก **พิมพ์เป็นบล็อก** กลางช่องว่าง
            Box(
                Modifier.offset(y = (-NP.h * 0.045f).dp).size(w.dp, NP.h.dp),
                contentAlignment = Alignment.BottomCenter,
            ) {
                Box(
                    Modifier
                        .size((NP.clearW + 14f).dp, (NP.h - NP.bandTop + 24f).dp)
                        .photoSlot(1)
                        .clip(RoundedCornerShape(14.dp)),
                ) {
                    WidgetPhoto(1, Modifier.fillMaxSize().scrubDolly(scrub.d, shift = NP.w * 0.04f, zoom = 0.12f))
                }
            }
        }
    }
}

// MARK: - เครื่องมือ (ส่วนตัว)

/** สไตล์ช่องที่ผ่านฟอนต์/สี/ขนาดของเจ้าของการ์ดแล้ว — ส่งให้ `editableSlot` เหมือนที่ `EditableText` ทำ */
@Composable
private fun tunedSlot(id: TextSlotID, style: TextSlotStyle): TextSlotStyle {
    val s = style.tuned(LocalWidgetTextStyle.current, id, LocalCardInk.current, LocalCardAccent.current)
    s.tilt = LocalSlotTilt.current
    return s
}

/** VStack ที่ระยะติดลบ — ดึงชิ้นขึ้น `dy` pt และหักความสูงเท่ากันออกจากผัง */
private fun Modifier.pullUp(dy: Float): Modifier = layout { m, c ->
    val p = m.measure(c)
    val d = dy.dp.roundToPx()
    layout(p.width, max(0, p.height - d)) { p.place(0, -d) }
}
