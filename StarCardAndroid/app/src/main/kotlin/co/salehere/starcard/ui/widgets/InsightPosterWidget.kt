package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.ScrubDigits
import co.salehere.starcard.components.redacted
import co.salehere.starcard.components.scrubDolly
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.AudienceInsight
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.LocalWidgetSurface
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.BrandIcon
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.EdGrain
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.PlatePatternLayer
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.ShLineHeightStyle
import co.salehere.starcard.theme.ShPlatformStyle
import co.salehere.starcard.theme.TextFit
import co.salehere.starcard.theme.Tinted
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.onLightSurface
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalGhostData
import co.salehere.starcard.ui.LocalSlotTilt
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.TextSlotStyle
import co.salehere.starcard.ui.editor.dataValue
import co.salehere.starcard.ui.editor.editableSlot
import java.util.UUID
import kotlin.math.max
import kotlin.math.min

// MARK: - โปสเตอร์อินไซต์ (= InsightPosterWidget.swift)
//
// แปลงจากแผ่น **Público**: คำตัวเขียนยักษ์มุมซ้ายบน · คนยืนกลางแผ่น (PNG พื้นหลังใส)
// · แผ่นข้อมูลขาวลอยล้อมตัวคน ทับไหล่ ทับแขน — ไม่มีแผ่นรองข้างหลัง
// ใบเดียวในตระกูล `audience` ที่วาด **ทุกชุดพร้อมกัน** — การเข้าถึง · เพศ · อายุ · เมือง
// สามระนาบ: หลัง = คำตัวเขียน · กลาง = คน · หน้า = แผ่นข้อมูลสี่แผ่น (ทับขอบตัวคน ไม่ทับหน้า)
// ตัวเลขทุกตัวหนา heavy และใหญ่กว่าชื่อของมันเสมอ · ทุกตัวเลขมาจาก OAuth — ตอนนี้เป็น mock (`AudienceInsight.reach`)

/** ค่าคงที่ของผัง — **หน่วยเดียวกับ `WidgetKind.defaultSize`** (366 × 520) */
object IP {
    const val w: Float = 366f
    const val h: Float = 520f

    /** คำตัวเขียน */
    const val script: Float = 76f
    /** ตัวคนสูงกี่ส่วนของแผ่น — หัวต้องขึ้นไปชนคำตัวเขียนเหมือนต้นฉบับ */
    const val subject: Float = 0.88f

    /** แผ่นข้อมูล — กว้างไม่เกินนี้ ไม่งั้นสองฝั่งปิดตัวคนมิด */
    const val narrow: Float = 142f
    const val wide: Float = 152f

    const val title: Float = 13f
    const val label: Float = 12.5f
    const val value: Float = 15.5f
    const val hero: Float = 34f
}

/** หมึกของแผ่นข้อมูลขาว — คงที่ทุกธีม (= `Sheet` ของ Swift · เติม `IP` กันชื่อชนในแพ็กเกจเดียวกัน) */
private object IPSheet {
    val paper = Color.White
    val ink = grey(0.07)
    val soft = grey(0.42)
    val rail = grey(0.91)
    val up = rgb(0.07, 0.58, 0.30)
}

private const val scriptPreset = "Audience"

/** **สามอันดับแรกเท่านั้น เรียงจากมากไปน้อย** (ผู้ใช้สั่ง) — แผ่นเตี้ยลงจึงไม่บังหน้าคน */
private const val topN = 3

@Composable
fun InsightPosterWidget(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    PosterSheet(design = Size(IP.w, IP.h), frame = size, modifier = modifier) { box ->
        InsightSheet(theme, box)
    }
}

@Composable
private fun InsightSheet(theme: CardTheme, box: Size) {
    val photos = LocalPhotoStore.current
    val wid = LocalWidgetID.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val d = LocalPageScrub.current.d
    val a = Profile.me.creator.audience
    /** สีแท่ง/วง — สีเน้นของธีมที่จูนมาสำหรับพื้นขาว (แผ่นข้อมูลขาวเสมอ) */
    val bar = theme.rawAccent.onLightSurface()

    // หมึกของพื้น ใช้สูตรเดียวกับโปสเตอร์ผู้ติดตาม (ไม่มีพื้น = หมึกของการ์ด)
    val skin = StatPosterSkin.make(surface, theme, cardInk)
    val plane = if (photos != null) cutoutPlane(photos, 1, wid)
    else CutoutSample.image?.let { CutoutPlane.Subject(it, own = false) } ?: CutoutPlane.Framed
    val shape = RoundedCornerShape((if (skin.papered) min(theme.radius, 20f) else 0f).dp)

    Box(Modifier.size(box.width.dp, box.height.dp)) {
        Box(Modifier.fillMaxSize().clip(shape)) {
            if (skin.papered) {
                Box(Modifier.fillMaxSize().background(skin.plate))
                PlatePatternLayer(skin.plate, Modifier.fillMaxSize())
                EdGrain(count = 320, opacity = 0.04, tint = Color.White)
            }

            // ผังกว้างเท่าออกแบบเสมอ แล้วจัดกลางบนแผ่นที่กว้างขึ้น
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Box(Modifier.size(IP.w.dp, box.height.dp), contentAlignment = Alignment.TopStart) {
                    // ── หลัง: คำตัวเขียน
                    InsightScript(skin, wid, d)

                    // ── กลาง: คน
                    InsightSubject(plane, box.height, d)

                    // ── หน้า: แผ่นข้อมูล — ตำแหน่งเป็น padding ไม่ใช่ offset (ม่านของ `scrubVeil` ตัดที่กรอบของชิ้น)
                    // สองคอลัมน์สลับจังหวะกัน · เว้นแถบกลางให้หน้าคนโผล่เต็ม — คอลัมน์ขวาเริ่มใต้ระดับคาง
                    InsightPlace(0, x = 0f, y = 148f, w = IP.narrow, d = d) {
                        InsightBars("เมืองหลัก", top3(a.places.map { it.name to it.share }), bar, d)
                    }
                    InsightPlace(3, x = IP.w - IP.narrow, y = 176f, w = IP.narrow, d = d) {
                        InsightBars("ช่วงอายุ", top3(a.ages.map { it.label to it.share }), bar, d)
                    }
                    InsightPlace(1, x = 0f, y = 312f, w = IP.wide, d = d) {
                        InsightGender(a, bar, d)
                    }
                    InsightPlace(2, x = IP.w - IP.wide, y = 340f, w = IP.wide, d = d) {
                        InsightReach(a.reach, d)
                    }
                }
            }
        }
        CutoutStatus(plane, theme, modifier = Modifier.align(Alignment.TopEnd).padding(9.dp))
    }
}

// MARK: คำตัวเขียน

/**
 * คำเดียวตัวเขียนยักษ์ — ต้นฉบับคือ "Público" · พิมพ์ทับได้
 * ฟอนต์ตัวเขียนเป็นของดีไซน์ (Snell Roundhand บน iOS → ตระกูล cursive ของเครื่อง) จึงตั้งเอง
 * ถ้าผู้ใช้สั่งฟอนต์ในแผงข้อความ ฟอนต์นั้นมาก่อน
 */
@Composable
private fun InsightScript(skin: StatPosterSkin, wid: UUID?, d: Float) {
    val tune = LocalWidgetTextStyle.current
    val ink = LocalCardInk.current
    val accent = LocalCardAccent.current
    val tilt = LocalSlotTilt.current
    val ghost = LocalGhostData.current

    val text = Profile.me.note(wid, 1, preset = scriptPreset)
    val s = tune.scaled(IP.script, ProfileField.note, 1)
    val font = tune.face(ProfileField.note, 1)?.font(s, SHFont.regular) ?: scriptFont(s)
    val id = TextSlotID(field = ProfileField.note, index = 1, widget = wid, preset = scriptPreset, hint = "คำพาดหัว")
    val slotStyle = TextSlotStyle(
        size = IP.script, weight = SHFont.regular, color = skin.ink, align = TextAlign.Start, corner = 6f,
    ).tuned(tune, id, ink, accent).also { it.tilt = tilt }

    Box(
        Modifier
            .scrubSlide(d, travel = -IP.w * 0.26f, fade = 0.84, eased = false)
            .padding(start = 10.dp, top = 4.dp)
            .width((IP.w * 0.86f).dp),
        contentAlignment = Alignment.CenterStart,
    ) {
        Tinted(skin.ink) {
            Text(
                text,
                style = font,
                color = skin.ink,
                maxLines = 1,
                softWrap = false,
                autoSize = TextAutoSize.StepBased(minFontSize = (s * 0.4f).sp, maxFontSize = s.sp, stepSize = 0.5.sp),
                modifier = Modifier.editableSlot(id, slotStyle).redacted(ghost),
            )
        }
    }
}

/** ตัวเขียนของดีไซน์ — `Font.custom("SnellRoundhand")` · Android ใช้ตระกูล cursive ของระบบ */
private fun scriptFont(size: Float): TextStyle = TextStyle(
    fontFamily = FontFamily.Cursive,
    fontWeight = FontWeight.Normal,
    fontSize = size.sp,
    platformStyle = ShPlatformStyle,
    lineHeightStyle = ShLineHeightStyle,
)

// MARK: คน

@Composable
private fun InsightSubject(plane: CutoutPlane, h: Float, d: Float) {
    when (plane) {
        is CutoutPlane.Subject -> {
            // ยืนบนขอบล่างที่เห็นจริง กลางแผ่น · ไม่มีเงา — ฉากเดียวกับแผ่นข้อมูล
            Box(
                Modifier.offset(y = (h * 0.02f).dp).size(IP.w.dp, h.dp),
                contentAlignment = Alignment.BottomCenter,
            ) {
                CutoutSubject(
                    image = plane.image, height = h * IP.subject, d = d, drift = IP.w * 0.03f, shadow = false,
                    modifier = Modifier
                        .wrapContentSize(Alignment.BottomCenter, unbounded = true)
                        .photoSlot(1),
                )
            }
        }
        CutoutPlane.Framed -> {
            // รูปทึบ — แผ่นมนกลางแผ่นแทนคนยืน ผังที่เหลือไม่ขยับ
            Box(
                Modifier.offset(y = (-12).dp).size(IP.w.dp, h.dp),
                contentAlignment = Alignment.BottomCenter,
            ) {
                Box(
                    Modifier
                        .size((IP.w * 0.54f).dp, (h * 0.8f).dp)
                        .photoSlot(1)
                        .clip(RoundedCornerShape(18.dp)),
                ) {
                    WidgetPhoto(1, Modifier.fillMaxSize().scrubDolly(d, shift = IP.w * 0.04f, zoom = 0.12f))
                }
            }
        }
    }
}

// MARK: แผ่นข้อมูล

/** แผ่นขาวหนึ่งแผ่นที่ตำแหน่ง (x, y) ในหน่วยออกแบบ — สูงเท่าเนื้อหาพอดี */
@Composable
private fun InsightPlace(i: Int, x: Float, y: Float, w: Float, d: Float, content: @Composable () -> Unit) {
    val shape = RoundedCornerShape(10.dp)
    Box(
        Modifier
            .padding(start = x.dp, top = y.dp)
            .scrubVeil(d, lead = Scrub.lead(i, 4, d, step = 0.07), drop = 26f, pull = 10f)
            .width(w.dp)
            .background(IPSheet.paper, shape)
            .border(1.dp, Color.Black.opacity(0.08), shape)
            .padding(horizontal = 11.dp, vertical = 10.dp),
        contentAlignment = Alignment.TopStart,
    ) {
        content()
    }
}

@Composable
private fun InsightTitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text, style = sh(IP.title, SHFont.bold), color = IPSheet.ink,
        maxLines = 1, softWrap = false,
        autoSize = TextAutoSize.StepBased(minFontSize = (IP.title * 0.7f).sp, maxFontSize = IP.title.sp, stepSize = 0.5.sp),
        modifier = modifier,
    )
}

// ── การเข้าถึง

@Composable
private fun InsightReach(r: AudienceInsight.Reach, d: Float) {
    Column(Modifier.fillMaxWidth()) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            InsightTitle("การเข้าถึง · ${r.window}", Modifier.weight(1f))
            BrandIcon(r.platform.icon, size = 15f)
        }
        HeroDigits(Fmt.compact(r.accounts), d)
        Text(
            "บัญชีที่เห็น", style = sh(11.5f, SHFont.semibold), color = IPSheet.soft,
            maxLines = 1, softWrap = false, modifier = Modifier.padding(bottom = 6.dp),
        )
        Row(horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(
                "+${Fmt.pct(r.delta)}", style = sh(12f, SHFont.heavy), color = IPSheet.up,
                maxLines = 1, softWrap = false,
                modifier = Modifier
                    .background(IPSheet.up.opacity(0.12), CircleShape)
                    .padding(horizontal = 6.dp, vertical = 2.5.dp)
                    .dataValue(),
            )
            Text(
                "ใหม่ ${Fmt.pct(r.newShare)}", style = sh(12f, SHFont.bold), color = IPSheet.ink,
                maxLines = 1, softWrap = false,
                autoSize = TextAutoSize.StepBased(minFontSize = (12f * 0.7f).sp, maxFontSize = 12.sp, stepSize = 0.5.sp),
                modifier = Modifier.weight(1f, fill = false).dataValue(),
            )
        }
    }
}

/**
 * ตัวเลขยักษ์ที่ลอกทีละหลัก — `ScrubDigits` วาดทีละตัว `.minimumScaleFactor(0.6)` จึงคิดเอง:
 * วัดทั้งคำที่ขนาดเต็ม แล้วย่อลงตามที่ว่างจริง (ไม่ต่ำกว่า 60%)
 */
@Composable
private fun HeroDigits(text: String, d: Float) {
    val measurer = TextFit.rememberMeasurer()
    BoxWithConstraints(Modifier.fillMaxWidth()) {
        val avail = maxWidth.value
        val natural = remember(text, measurer) { measuredWidth(measurer, text, sh(IP.hero, SHFont.heavy)) }
        val k = if (natural > avail && natural > 0f) max(0.6f, avail / natural) else 1f
        ScrubDigits(
            text = text, d = d, lead = 0.06, step = 0.05, drop = 26f,
            style = sh(IP.hero * k, SHFont.heavy), color = IPSheet.ink,
            modifier = Modifier.dataValue(),
        )
    }
}

// ── เพศ

/**
 * สามส่วนเรียงจากมากไปน้อย — ส่วนใหญ่สุดได้สีเน้น ที่เหลือเป็นเทาเข้ม/อ่อน
 * (ไม่ผูกชมพู/ฟ้าตายตัว เพราะต้องเข้ากับทุกธีม และยังแยกกันออกทุกธีม)
 */
private fun genderParts(a: AudienceInsight, bar: Color): List<Triple<String, Double, Color>> {
    val raw = listOf("หญิง" to a.female, "ชาย" to a.male, "อื่น ๆ" to a.other).sortedByDescending { it.second }
    val tones = listOf(bar, grey(0.18), grey(0.72))
    return raw.mapIndexed { i, p -> Triple(p.first, p.second, tones[i]) }
}

@Composable
private fun InsightGender(a: AudienceInsight, bar: Color, d: Float) {
    val parts = genderParts(a, bar)
    val measurer = TextFit.rememberMeasurer()
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        InsightTitle("เพศ")
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
            InsightDonut(parts, d)
            BoxWithConstraints(Modifier.weight(1f)) {
                val avail = maxWidth.value
                Column {
                    parts.forEachIndexed { i, p ->
                        val pct = Fmt.pct(p.second)
                        val numSize = if (i == 0) 19f else IP.value
                        // `.lineLimit(1).minimumScaleFactor(0.7)` ทั้งแถว — ย่อตัวเลขกับชื่อพร้อมกันด้วยสัดส่วนเดียว
                        val k = remember(pct, p.first, numSize, avail, measurer) {
                            val need = measuredWidth(measurer, pct, sh(numSize, SHFont.heavy)) + 4f +
                                measuredWidth(measurer, p.first, sh(11f, SHFont.semibold))
                            if (need > avail && need > 0f) max(0.7f, avail / need) else 1f
                        }
                        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                pct, style = sh(numSize * k, SHFont.heavy),
                                color = if (i == 2) IPSheet.soft else IPSheet.ink,
                                maxLines = 1, softWrap = false,
                                modifier = Modifier.alignByBaseline().dataValue(),
                            )
                            Text(
                                p.first, style = sh(11f * k, SHFont.semibold), color = IPSheet.soft,
                                maxLines = 1, softWrap = false,
                                modifier = Modifier.alignByBaseline(),
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun InsightDonut(parts: List<Triple<String, Double, Color>>, d: Float) {
    val total = max(parts.sumOf { it.second }, 1.0)
    val gap = 0.012
    val t = Scrub.ease(Scrub.t(d, lead = 0.12))
    Canvas(Modifier.size(52.dp)) {
        val sw = 10.dp.toPx()
        val inset = 5.dp.toPx()
        val arc = Size(size.width - inset * 2, size.height - inset * 2)
        val origin = Offset(inset, inset)
        drawCircle(IPSheet.rail, radius = arc.width / 2, style = Stroke(width = sw))
        var start = 0.0
        parts.forEach { p ->
            val end = start + p.second / total
            // ส่วนที่เล็กมากยังต้องเห็นเป็นขีด — ช่องว่างกินได้ไม่เกินครึ่งของมัน
            val g = min(gap, (end - start) / 3)
            val from = start + g
            val to = max(start + g, end - g) * max(0.0, 1.0 - t)
            if (to > from) {
                drawArc(
                    p.third,
                    startAngle = (-90.0 + from * 360).toFloat(),
                    sweepAngle = ((to - from) * 360).toFloat(),
                    useCenter = false,
                    topLeft = origin,
                    size = arc,
                    style = Stroke(width = sw, cap = StrokeCap.Butt),
                )
            }
            start = end
        }
    }
}

// ── ช่วงอายุ · เมือง — แผ่นแท่งแบบต้นฉบับ: ชื่อซ้าย ตัวเลขขวา แท่งบนรางข้างใต้

private fun top3(rows: List<Pair<String, Double>>): List<Pair<String, Double>> =
    rows.sortedByDescending { it.second }.take(topN)

@Composable
private fun InsightBars(heading: String, rows: List<Pair<String, Double>>, bar: Color, d: Float) {
    val top = rows.maxOfOrNull { it.second } ?: 1.0
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        InsightTitle(heading)
        rows.forEachIndexed { i, r ->
            InsightBarRow(
                r.first, r.second, peak = r.second == top,
                lead = Scrub.lead(i, rows.size, d, step = 0.08), bar = bar, d = d,
            )
        }
    }
}

@Composable
private fun InsightBarRow(name: String, share: Double, peak: Boolean, lead: Double, bar: Color, d: Float) {
    val t = Scrub.ease(Scrub.t(d, lead))
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(1.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(
                name, style = sh(IP.label, SHFont.semibold), color = IPSheet.ink,
                maxLines = 1, softWrap = false,
                autoSize = TextAutoSize.StepBased(minFontSize = (IP.label * 0.7f).sp, maxFontSize = IP.label.sp, stepSize = 0.5.sp),
                modifier = Modifier.weight(1f).alignByBaseline(),
            )
            Spacer(Modifier.width(2.dp))
            Text(
                Fmt.pct(share), style = sh(IP.value, SHFont.heavy), color = IPSheet.ink,
                maxLines = 1, softWrap = false,
                modifier = Modifier.alignByBaseline().dataValue(),
            )
        }
        val fill = if (peak) bar else bar.opacity(0.55)
        Canvas(Modifier.fillMaxWidth().height(6.dp)) {
            val h = size.height
            drawRoundRect(IPSheet.rail, cornerRadius = CornerRadius(h / 2, h / 2))
            val w = max(4.dp.toPx(), size.width * (share / 100).toFloat() * max(0f, 1 - t))
            drawRoundRect(fill, size = Size(w, h), cornerRadius = CornerRadius(h / 2, h / 2))
        }
    }
}

/** ความกว้างของข้อความหนึ่งบรรทัดในหน่วยออกแบบ — ตัววัดของ `TextFit` ใช้ density 1 จึงได้ pt ตรง ๆ */
private fun measuredWidth(measurer: TextMeasurer, text: String, style: TextStyle): Float =
    measurer.measure(text, style, softWrap = false, maxLines = 1).size.width.toFloat()
