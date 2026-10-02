package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
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
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.Measurable
import androidx.compose.ui.layout.Placeable
import androidx.compose.ui.layout.layout
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.ScrubDigits
import co.salehere.starcard.components.redacted
import co.salehere.starcard.components.scrubLouver
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.LocalWidgetEmboss
import co.salehere.starcard.model.LocalWidgetEmbossBlind
import co.salehere.starcard.model.LocalWidgetSurface
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.SocialProfile
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.theme.BrandIcon
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.EdGrain
import co.salehere.starcard.theme.EmbossedLockup
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.PlatePatternLayer
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.TextFit
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalGhostData
import co.salehere.starcard.ui.LocalSlotTilt
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import co.salehere.starcard.ui.editor.dataValue
import co.salehere.starcard.ui.editor.editableSlot
import java.util.UUID
import kotlin.math.max
import kotlin.math.min

// MARK: - โปสเตอร์ผู้ติดตาม (= Views/Widgets/StatPosterWidget.swift — `StatPosterSkin` อยู่ใน WidgetKit.kt)
//
// แปลงตรงจากแผ่น **SOCIAL MEDIA STATS** (พาดหัวยักษ์ + แถวตัวเลขคั่นด้วยเส้น)
// พาดหัวสองบรรทัดผสมสองฟอนต์ · เส้นคาด · แถวตัวเลข · เส้นปิด — **ไม่มีอย่างอื่นเลย**
//
// เอายอดรายช่องไปวางเป็น **แถวสถิติใต้พาดหัว** — ตัวเลขเรียงอยู่บนเส้นเดียวกัน
// ซึ่งเป็นสิ่งเดียวที่ทำให้สายตา **เทียบสามช่องพร้อมกัน** ได้ในวินาทีเดียว
// ตัวเลขสลับสี ไม่ใช่เพื่อสวย — สีที่สลับบอกตาว่า "ตัวไหนจบตรงไหน" แม้การ์ดถูกย่อเป็นพรีวิว

/**
 * ค่าคงที่ของผัง — **หน่วยเดียวกับ `WidgetKind.defaultSize`** (366 × 214)
 * เขียนเป็นตัวเลขคงที่ เพราะ `PosterSheet` ย่อ/ขยายทั้งก้อนให้อยู่แล้ว ผังจึงเป็นจริงทุกขนาด
 */
object SP {
    const val w: Float = 366f
    const val h: Float = 214f

    /** ขอบของทั้งแผ่น — เส้นคาดสองเส้นชนขอบนี้ ไม่ใช่ชนขอบแผ่น (โปสเตอร์ไม่ใช่ตาราง) */
    const val pad: Float = 18f
    const val top: Float = 18f
    const val bottom: Float = 16f

    /** เพดานของพาดหัวสองบรรทัด — บรรทัดล่างใหญ่กว่าชัดเจน */
    const val cap1: Float = 30f
    const val cap2: Float = 42f
    /** ความกว้างที่แต่ละบรรทัดถูก *จัดให้เต็ม* — **ไม่ใช่เต็มแผ่นทั้งคู่** (ก้อนพาดหัวจึงเป็นรูปทรง) */
    const val line1W: Float = 0.60f
    const val line2W: Float = 0.96f

    /** แถวสถิติ — **ไอคอนใหญ่กว่าตัวเลขโดยตั้งใจ** โลโก้ตอบ "ช่องไหน" ได้เร็วกว่าชื่อช่อง */
    const val icon: Float = 27f
    const val label: Float = 9.5f
}

/** พาดหัวเป็นของ **ดีไซน์** ไม่ใช่ของโปรไฟล์ จึงเก็บต่อชิ้นแบบเดียวกับสำรับบรรณาธิการ */
private const val statLine1Preset = "MY Social"
private const val statLine2Preset = "MEDIA STATS"

@Composable
fun StatPosterWidget(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    // แผ่นต้องเต็มกรอบเสมอ ทั้งกว้างและสูง ทุกเคส (ดู `PosterSheet`)
    PosterSheet(design = Size(SP.w, SP.h), frame = size, modifier = modifier) { box ->
        StatPosterSheet(theme, box)
    }
}

/** - box: ผังในหน่วยออกแบบที่ยืดเต็มกรอบแล้ว (≥ `SP.w × SP.h`) */
@Composable
private fun StatPosterSheet(theme: CardTheme, box: Size) {
    val wid = LocalWidgetID.current
    val scrub = LocalPageScrub.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val embossed = LocalWidgetEmboss.current
    val embossBlind = LocalWidgetEmbossBlind.current
    val skin = StatPosterSkin.make(surface, theme, cardInk)
    val shape = RoundedCornerShape((if (skin.papered) min(theme.radius, 20f) else 0f).dp)

    Box(Modifier.size(box.width.dp, box.height.dp).clip(shape)) {
        // ── แผ่น
        if (skin.papered) {
            Box(Modifier.matchParentSize().background(skin.plate))
            PlatePatternLayer(sheet = skin.plate, modifier = Modifier.matchParentSize())
            // เกล็ดจาง ๆ ชั้นเดียว — แผ่นสีเรียบล้วนที่ความกว้างเท่านี้อ่านเป็นรูปที่ยังโหลดไม่เสร็จ
            EdGrain(count = 260, opacity = 0.04, tint = Color.White, modifier = Modifier.matchParentSize())
        }

        // ทั้งใบมีของอยู่สามอย่าง — พาดหัว · เส้น · ตัวเลข (บรรทัดเล็กสี่มุมจะแย่งสายตากับตัวเลข)
        Column(Modifier.fillMaxSize().padding(horizontal = SP.pad.dp)) {
            StatHeadline(skin, box.width, wid, Modifier.padding(top = SP.top.dp))

            // เส้นคาดใต้พาดหัว — หนากว่าเส้นล่างและเป็นสีเน้น เพราะมันคือ *ขอบล่างของพาดหัว*
            Box(
                Modifier
                    .scrubVeil(scrub.d, lead = 0.1, drop = 14f, pull = 18f)
                    .padding(top = 10.dp)
                    .fillMaxWidth()
                    .height(1.4.dp)
                    .background(skin.accent),
            )

            Spacer(Modifier.height(6.dp))
            Spacer(Modifier.weight(1f))

            StatPosterStats(skin)

            Spacer(Modifier.height(6.dp))
            Spacer(Modifier.weight(1f))

            // เส้นปิดแถว — ต้นฉบับมีเส้นประกบตัวเลขทั้งบนและล่าง แถวตัวเลขจึงเป็น *แถบ*
            Box(
                Modifier
                    .scrubVeil(scrub.d, lead = 0.16, drop = 14f, pull = 18f)
                    .padding(bottom = SP.bottom.dp)
                    .fillMaxWidth()
                    .height(0.8.dp)
                    .background(skin.hair),
            )
        }

        // ตราปั๊มนูนมุมขวาบน — ขึ้นเฉพาะเมื่อยอดทุกช่องมาจากแพลตฟอร์มจริง (ยอดกรอกเองไม่มีสิทธิ์ได้ตราของผู้ออก)
        if (embossed && VerifiedFacts.numbersVerified) {
            EmbossedLockup(
                height = if (embossBlind) 19f else 21f,
                light = if (surface == WidgetSurface.glass) false else cardInk.isLight,
                foil = !embossBlind,
                tint = skin.ink,
                modifier = Modifier.align(Alignment.TopEnd).padding(top = 13.dp, end = 15.dp),
            )
        }
    }
}

// MARK: พาดหัว

/**
 * สองบรรทัดกลางแผ่น — **แต่ละบรรทัดถูกจัดให้เต็มความกว้างของตัวเอง** (ดู `SP.line1W`)
 * บรรทัดบน: **คำแรกหนา ที่เหลือเซริฟเอียง** — ท่าเดียวกับโปสเตอร์สายงาน พิมพ์ทับได้ทั้งบรรทัดในช่องเดียว
 */
@Composable
private fun StatHeadline(skin: StatPosterSkin, w: Float, wid: UUID?, modifier: Modifier) {
    val scrub = LocalPageScrub.current
    val tune = LocalWidgetTextStyle.current
    val measurer = TextFit.rememberMeasurer()
    val l1 = Profile.me.note(wid, 1, statLine1Preset)
    val l2 = Profile.me.note(wid, 2, statLine2Preset).uppercase()
    val fs1 = Ed.fitted(measurer, l1, SHFont.heavy, width = w * SP.line1W, cap = SP.cap1, floor = 12f)
    val fs2 = Ed.fitted(measurer, l2, SHFont.heavy, width = w * SP.line2W, cap = SP.cap2, floor = 13f)

    // ระยะระหว่างบรรทัดติดลบ — หักที่ว่างที่ NotoSansThai เผื่อไว้ให้สระบน/วรรณยุกต์
    Column(
        modifier
            .fillMaxWidth()
            // ชั้นหลังสุดวิ่งสวนแรงที่สุด — ตาอ่านความลึกจาก *ความต่างของอัตรา* ไม่ใช่จากระยะ
            .scrubSlide(scrub.d, travel = -SP.w * 0.26f, fade = 0.84, eased = false),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        StatMixedLine(
            raw = l1, size = fs1, color = skin.ink,
            id = TextSlotID(field = ProfileField.note, index = 1, widget = wid, preset = statLine1Preset, hint = "พาดหัวบรรทัดบน"),
            style = TextSlotStyle(
                size = fs1, weight = SHFont.heavy, color = skin.ink, align = TextAlign.Center,
                tracking = -fs1 * 0.03f, corner = 6f,
            ),
        )
        // heavy ไม่ใช่ black — ที่น้ำหนักหนาสุด NotoSansThai วางสระบนชนวรรณยุกต์
        EditableText(
            field = ProfileField.note, index = 2, widget = wid, preset = statLine2Preset, hint = "พาดหัวบรรทัดล่าง",
            style = TextSlotStyle(
                size = fs2, weight = SHFont.heavy, color = skin.ink, align = TextAlign.Center,
                tracking = -tune.scaled(fs2, ProfileField.note, 2) * 0.035f, uppercase = true, corner = 6f,
            ),
            text = l2,
            modifier = Modifier.pullUp(fs1 * 0.30f),
            autoSizeMin = 0.4f,
        )
    }
}

/**
 * คำแรกหนา · ที่เหลือเซริฟเอียง — ข้อความก้อนเดียวที่ย่อพร้อมกันทั้งบรรทัด (ท่อนหางเป็น em จึงย่อตาม)
 * เซริฟที่ขนาดเท่ากันดู *เตี้ยกว่า* ตัวหนา — ชดเชยขึ้น 4% · ฟอนต์ที่ผู้ใช้สั่งทับมาก่อนเซริฟของดีไซน์
 */
@Composable
private fun StatMixedLine(raw: String, size: Float, color: Color, id: TextSlotID, style: TextSlotStyle) {
    val tune = LocalWidgetTextStyle.current
    val ghost = LocalGhostData.current
    val s = tune.scaled(size, ProfileField.note, 1)
    val trimmed = raw.trimStart(' ')
    val k = trimmed.indexOf(' ')
    val head = if (k < 0) trimmed else trimmed.substring(0, k)
    val tail = if (k < 0) "" else trimmed.substring(k + 1)
    val tailFace = tune.face(ProfileField.note, 1) ?: CardFont.serif
    val text = buildAnnotatedString {
        withStyle(SpanStyle(letterSpacing = (-0.03f).em)) { append(head.uppercase()) }
        if (tail.isNotEmpty()) {
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

// MARK: แถวสถิติ

/**
 * ทุกช่องกว้างเท่ากันและคั่นด้วยเส้นตั้ง — **ความกว้างเท่ากันคือสิ่งที่ทำให้มันเทียบกันได้**
 * เส้นคั่นสูงเท่าช่องที่สูงที่สุด (หัก 3pt บนล่าง) — จัดผังเองเพราะ `Row` ไม่มี "สูงเท่าพี่น้อง"
 */
@Composable
private fun StatPosterStats(skin: StatPosterSkin) {
    val scrub = LocalPageScrub.current
    val socials = Profile.me.creator.socials
    val n = max(socials.size, 1)
    // ตัวเลขเล็กลงเมื่อช่องเยอะ — ที่หกช่อง ช่องหนึ่งกว้างราว 55pt ซึ่งตัวเลข 22pt ล้นแน่
    val numSize = if (n >= 5) 16f else if (n == 4) 19f else 22f

    // ลบช่องออกหนึ่งช่องแล้วลำดับที่เหลือเลื่อน — ผูก key กับลิสต์ให้สร้างใหม่ทั้งชุด
    key(socials.map { it.id }) {
        Layout(
            content = {
                socials.forEachIndexed { i, s ->
                    if (i > 0) {
                        Box(
                            Modifier
                                .scrubVeil(scrub.d, lead = 0.2, drop = 10f, pull = 14f)
                                .padding(vertical = 3.dp)
                                .background(skin.hair),
                        )
                    }
                    Box(Modifier.linkSlot(s.profileURL), contentAlignment = Alignment.TopCenter) {
                        StatPosterColumn(s, i, n, skin, numSize)
                    }
                }
            },
            modifier = Modifier.fillMaxWidth(),
        ) { measurables, constraints ->
            val count = socials.size
            if (count == 0) return@Layout layout(constraints.minWidth, 0) {}
            val w = if (constraints.hasBoundedWidth) constraints.maxWidth else constraints.minWidth
            val hair = max(1, 0.8.dp.roundToPx())
            val colW = max(0, (w - (count - 1) * hair) / count)
            val cols = ArrayList<Placeable>(count)
            val divs = ArrayList<Measurable>(count)
            measurables.forEachIndexed { k, m ->
                if (k % 2 == 0) {
                    cols += m.measure(Constraints(minWidth = colW, maxWidth = colW, minHeight = 0, maxHeight = constraints.maxHeight))
                } else {
                    divs += m
                }
            }
            val h = cols.maxOfOrNull { it.height } ?: 0
            val divPlaced = divs.map { it.measure(Constraints.fixed(hair, h)) }
            layout(w, h) {
                var x = 0
                cols.forEachIndexed { i, p ->
                    if (i > 0) {
                        divPlaced[i - 1].place(x, 0)
                        x += hair
                    }
                    p.place(x, (h - p.height) / 2)
                    x += colW
                }
            }
        }
    }
}

@Composable
private fun StatPosterColumn(s: SocialProfile, i: Int, n: Int, skin: StatPosterSkin, numSize: Float) {
    val scrub = LocalPageScrub.current
    val lead = Scrub.lead(i, n, scrub.d, step = 0.08)
    // สลับสีทีละช่อง ตามต้นฉบับ — ช่องแรกได้สีเน้น
    val tint = if (i % 2 == 0) skin.accent else skin.ink

    Column(
        Modifier.padding(horizontal = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(5.dp),
    ) {
        // โลโก้คงสีต้นฉบับของแพลตฟอร์ม ไม่ย้อมตามแผ่น — มันคือ *ตรา* ไม่ใช่ไอคอนของระบบ
        BrandIcon(s.type.icon, size = SP.icon, modifier = Modifier.scrubLouver(scrub.d, lead = lead, angle = 70.0, shrink = 0.2f))

        // ตัวเลขคือหลักฐาน มันถูกถอดออกทีละหลัก ไม่ใช่จางหายทั้งก้อน
        ScrubDigits(
            text = Fmt.compact(s.followerCount), d = scrub.d, lead = lead + 0.04, step = 0.05, drop = 24f,
            style = sh(numSize, SHFont.heavy), color = tint, modifier = Modifier.dataValue(),
        )

        Text(
            s.type.name,
            style = sh(SP.label, SHFont.semibold).copy(letterSpacing = (SP.label * 0.1f).sp),
            color = skin.soft,
            maxLines = 1,
            softWrap = false,
            autoSize = TextAutoSize.StepBased(minFontSize = (SP.label * 0.6f).sp, maxFontSize = SP.label.sp, stepSize = 0.25.sp),
            modifier = Modifier.scrubVeil(scrub.d, lead = lead, drop = 14f, pull = 8f),
        )
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
