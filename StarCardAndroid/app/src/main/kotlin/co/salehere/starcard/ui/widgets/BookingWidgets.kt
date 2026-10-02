package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.ScrubDigits
import co.salehere.starcard.components.WidgetLabel
import co.salehere.starcard.components.redacted
import co.salehere.starcard.components.scrubAperture
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.RateItem
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalGhostData
import co.salehere.starcard.ui.LocalSlotTilt
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import co.salehere.starcard.ui.editor.editableSlot
import kotlin.math.max
import kotlin.math.min

// MARK: - สำรับ "ปิดดีล" (= Views/Widgets/BookingWidgets.swift)
//
// ไฟล์นี้ตอบคำถามที่ตู้เดิมไม่มีใครตอบ: **จ้างยังไง เท่าไหร่ ติดต่อใคร** (สเปกหมวด 1.3 · 5.1)
// 1. **หนึ่งแบบ หนึ่งวัสดุ** — ป้ายห้อยราคา · นามบัตร · บัตรกระดาษ
// 2. **ท่าเปลี่ยนหน้าต้องมาจากวัสดุนั้น** — ป้ายต้องแกว่งรอบรูเจาะ บัตรต้องถูกพลิกเก็บ
// 3. **ตัวเลขห้ามจางหาย** — ราคาทุกตัวใช้มิเตอร์ถอดทีละหลัก (`ScrubDigits`)
// (`Deal` · `ContactLine` · `QRCode` อยู่ใน WidgetKit.kt)

/** `.minimumScaleFactor(k)` */
private fun dealShrink(size: Float, k: Float): TextAutoSize =
    TextAutoSize.StepBased(minFontSize = (size * k).sp, maxFontSize = size.sp, stepSize = 0.5.sp)

/**
 * แถวแนวนอนที่แบ่งความกว้างแบบ `HStack` ของ SwiftUI — ของที่สั้นได้ขนาดตัวเองก่อน
 * ที่เหลือแบ่งเท่า ๆ กันให้ตัวที่ยาว (ถูกตัดท้ายด้วย …) · ลูกทุกตัวจัดกลางแนวตั้ง · เต็มกรอบที่ได้รับ
 */
@Composable
private fun FairRow(spacing: Float, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Layout(content, modifier) { measurables, constraints ->
        val gap = spacing.dp.roundToPx()
        val boundedW = constraints.hasBoundedWidth
        val probeH = if (constraints.hasBoundedHeight) constraints.maxHeight else Constraints.Infinity
        val ideal = measurables.map { it.maxIntrinsicWidth(probeH) }
        val widths = IntArray(measurables.size)
        if (!boundedW) {
            ideal.forEachIndexed { i, w -> widths[i] = w }
        } else {
            var left = max(0, constraints.maxWidth - gap * max(0, measurables.size - 1))
            var n = measurables.size
            for (i in ideal.indices.sortedBy { ideal[it] }) {
                val share = if (n > 0) left / n else 0
                widths[i] = min(ideal[i], share)
                left -= widths[i]
                n -= 1
            }
        }
        val placeables = measurables.mapIndexed { i, m ->
            m.measure(Constraints(minWidth = 0, maxWidth = widths[i], minHeight = 0, maxHeight = probeH))
        }
        val contentW = placeables.sumOf { it.width } + gap * max(0, placeables.size - 1)
        val contentH = placeables.maxOfOrNull { it.height } ?: 0
        val w = if (boundedW) constraints.maxWidth else max(constraints.minWidth, contentW)
        val h = if (constraints.hasBoundedHeight) constraints.maxHeight else max(constraints.minHeight, contentH)
        layout(w, h) {
            var x = 0
            placeables.forEach { p ->
                p.place(x, (h - p.height) / 2)
                x += p.width + gap
            }
        }
    }
}

// MARK: - 01 · ป้ายราคา

/** องศาเอียงตั้งต้น — คงที่ ไม่สุ่ม การ์ดใบเดิมต้องหน้าตาเหมือนเดิมทุกครั้งที่เปิด (กติกาเดียวกับ `StickerTags`) */
private val rateTilt: List<Double> = listOf(-2.6, 2.0)

/**
 * เรตราคาชุดเดียวกับเมนู แต่เป็น **ป้ายห้อยราคาในร้าน** — กระดาษแข็งใบละหนึ่งเรต
 * ป้ายราคาอ่านเป็น *ของ* — ตาจับตัวเลขก่อนแล้วค่อยย้อนขึ้นไปอ่านว่าราคาอะไร
 * ฟิลด์ครบชุดตามสัญญาของตระกูล `rate`: ชื่อรายการ · ราคา · หน่วย
 *
 * # ท่าเปลี่ยนหน้า — "ป้ายแกว่งรอบรูเจาะแล้วร่วง"
 * จุดหมุนอยู่ที่ **รูเจาะ** ไม่ใช่กลางใบ · ราคาไม่จางตามใบ แต่ถูกถอดทีละหลักด้วยมิเตอร์
 */
@Composable
fun RateTagsWidget(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    // **สองใบเท่านั้น** — ป้ายคือของที่ตาจับทีละใบ ไม่ใช่ตารางที่ไล่อ่านจนจบ
    val rates = Profile.me.creator.rates.take(2)

    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(9.dp)) {
        WidgetLabel("เรตราคา", modifier = Modifier.scrubVeil(scrub.d, lead = 0.42, drop = 20f, pull = 6f))

        BoxWithConstraints(Modifier.fillMaxWidth().weight(1f)) {
            // สองใบต่อแถวเมื่อกว้างพอ · แคบกว่านั้นเรียงเดี่ยว — ป้ายที่แคบกว่า ~120pt ตัวเลขจะแพ้หัวป้าย
            val gw = maxWidth.value
            val cols = if (gw >= 250f) 2 else 1
            val gap = 9f
            val tagW = (gw - gap * (cols - 1)) / cols
            // ซอยเป็นแถวโดยยังถือ index เดิมไว้ — ลำดับของท่าต้องนับจากทั้งแผง ไม่ใช่นับใหม่ทุกแถว
            val rows = rates.withIndex().toList().chunked(cols)

            Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(gap.dp)) {
                rows.forEach { row ->
                    Row(Modifier.fillMaxWidth().weight(1f), horizontalArrangement = Arrangement.spacedBy(gap.dp)) {
                        row.forEach { e -> RateTag(e.value, e.index, rates.size, tagW, theme) }
                        // ช่องว่างของแถวสุดท้ายที่ไม่เต็ม — ไม่งั้นป้ายใบเดียวจะยืดกินทั้งแถว
                        if (row.size < cols) Spacer(Modifier.width(tagW.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun RateTag(r: RateItem, i: Int, count: Int, width: Float, theme: CardTheme) {
    val scrub = LocalPageScrub.current
    val lead = Scrub.lead(i, count, scrub.d, step = 0.07)
    val t = Scrub.ease(Scrub.t(scrub.d, lead))
    val s = Scrub.dir(scrub.d)
    val tilt = rateTilt[i % rateTilt.size]
    RateFace(
        r, i, width, lead, theme,
        Modifier
            .width(width.dp)
            .fillMaxHeight()
            .graphicsLayer {
                rotationZ = (tilt + s * 15.0 * t).toFloat()
                // แกว่งรอบรูเจาะ ไม่ใช่กลางใบ
                transformOrigin = TransformOrigin(0.1f, 0.14f)
                translationY = 30f * t * density
                alpha = Scrub.fade(t, 0.74).toFloat()
            },
    )
}

@Suppress("UNUSED_PARAMETER")
@Composable
private fun RateFace(r: RateItem, i: Int, width: Float, lead: Double, theme: CardTheme, modifier: Modifier) {
    val scrub = LocalPageScrub.current
    // ราคาบนป้ายเป็นกล่องรวมสองก้อน (฿ + มิเตอร์) — อ่านสไตล์ของช่องเอง แล้วประกาศช่องที่กล่องรวม
    val tune = LocalWidgetTextStyle.current
    val slotInk = LocalCardInk.current
    val accent = LocalCardAccent.current
    val ghost = LocalGhostData.current

    // ตัวเลขโตตามใบ แต่มีเพดานทั้งบนและล่าง — ป้ายที่ตัวเลขล้นขอบอ่านเป็นงานพัง ไม่ใช่งานกล้า
    val priceSize = min(30f, max(13f, width * 0.16f))
    val price = Profile.me.ratePrice(i)
    val priceInk = tune.color(Deal.ink, ProfileField.ratePrices, i, slotInk, accent) ?: Deal.ink
    val priceFont = tune.font(priceSize, SHFont.black, ProfileField.ratePrices, i)
    val slot = TextSlotID(ProfileField.ratePrices, index = i)
    val slotStyle = TextSlotStyle(size = priceSize, weight = SHFont.black, color = Deal.ink, corner = 6f)
        .tuned(tune, slot, slotInk, accent)
        .also { it.tilt = LocalSlotTilt.current }
    val shape = RoundedCornerShape(13.dp)
    val shade = Color.Black.opacity(0.32)

    Column(
        modifier
            .fillMaxHeight()
            .shadow(9.dp, shape, clip = false, ambientColor = shade, spotColor = shade)
            .clip(shape)
            .background(Deal.card),
    ) {
        RateHead(i, theme)

        Column(
            Modifier
                .fillMaxWidth()
                .weight(1f)
                .padding(start = 10.dp, end = 10.dp, top = 7.dp, bottom = 9.dp),
        ) {
            // `Spacer(minLength: 2)` + ช่องไฟ 2
            Spacer(Modifier.height(2.dp))
            Spacer(Modifier.weight(1f))
            Spacer(Modifier.height(2.dp))

            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                // ฿ อยู่นอกช่องที่แก้ได้ — ค่าที่เก็บคือตัวเลขล้วน (ดู `Profile.ratePrice`)
                Row(Modifier.alignByBaseline().editableSlot(slot, slotStyle).redacted(ghost)) {
                    Text(
                        "฿",
                        style = priceFont,
                        color = priceInk,
                        maxLines = 1,
                        softWrap = false,
                        modifier = Modifier.alignByBaseline()
                            .scrubVeil(scrub.d, lead = lead + 0.05, drop = 22f, pull = 0f),
                    )
                    ScrubDigits(
                        Fmt.baht(price), scrub.d, lead = lead + 0.05, step = 0.035, drop = 22f,
                        style = priceFont, color = priceInk,
                        modifier = Modifier.alignByBaseline(),
                    )
                }
                // หน่วยยอมย่อ/ถูกบีบก่อนราคาเสมอ (= `layoutPriority(-1)`)
                Text(
                    "/${r.unit}",
                    style = sh(9.5f, SHFont.bold),
                    color = Deal.inkSoft,
                    maxLines = 1,
                    softWrap = false,
                    autoSize = dealShrink(9.5f, 0.6f),
                    modifier = Modifier.alignByBaseline().scrubVeil(scrub.d, lead = lead, drop = 14f, pull = 4f),
                )
            }
        }
    }
}

/**
 * หัวป้าย — แถบสีธีมที่มีรูเจาะกับชื่อรายการ
 * ใช้สีดิบ (`rawAccent`) — แถบสีคือ *สีที่พิมพ์ลงบนกระดาษ* ไม่ใช่หมึกที่พลิกตามพื้นการ์ด
 */
@Composable
private fun RateHead(i: Int, theme: CardTheme) {
    Row(
        Modifier
            .fillMaxWidth()
            .background(Brush.horizontalGradient(listOf(theme.rawAccent, theme.rawAccentSoft)))
            .padding(horizontal = 9.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // รูเจาะ — จุดที่ป้ายห้อยอยู่ และเป็นจุดหมุนของท่าแกว่ง
        Box(
            Modifier
                .size(7.dp)
                .background(Deal.ink.opacity(0.3), CircleShape)
                .border(0.8.dp, Color.White.opacity(0.45), CircleShape),
        )
        // ชื่อรายการยาวเกินหัวป้าย **ย่อลง ไม่ตัดด้วย …** — ชื่องานที่ถูกตัดกลางคำตอบไม่ได้ว่าราคานี้ของอะไร
        EditableText(
            field = ProfileField.rateLabels,
            index = i,
            style = TextSlotStyle(
                size = 9f, weight = SHFont.heavy, color = Deal.ink.opacity(0.88),
                tracking = 0.8f, uppercase = true, corner = 4f,
            ),
            autoSizeMin = 0.5f,
        )
    }
}

// MARK: - 07 · นามบัตร

/**
 * สเปก 1.3 — เบอร์ · อีเมล · ไลน์ — สามฟิลด์นี้ถูกอ่านพร้อมกันเสมอ จึงเป็นบัตรใบเดียว
 * ไม่มีแถบหัวบัตร: รูปกับชื่อซ้ำกับ hero · สิ่งเดียวที่บัตรนี้ส่งมอบคือ **ค่าที่ต้องก็อปไปใช้**
 *
 * # ท่าเปลี่ยนหน้า — "บรรทัดติดต่อถูกปิดทีละช่อง"
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun ContactCardWidget(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val lines = ContactLine.all

    Column(modifier.fillMaxSize()) {
        lines.forEachIndexed { i, l ->
            Row(
                Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .linkSlot(l.field.contactURL)
                    .scrubVeil(
                        scrub.d, lead = Scrub.lead(i, lines.size, scrub.d, step = 0.08),
                        drop = 22f, pull = 12f,
                    ),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    l.label,
                    style = sh(10.5f, SHFont.semibold),
                    color = ink.text(0.42),
                    maxLines = 1,
                    softWrap = false,
                    modifier = Modifier.width(38.dp),
                )
                EditableText(
                    field = l.field,
                    style = TextSlotStyle(size = 13f, weight = SHFont.bold, color = ink.text(0.95)),
                )
            }
        }
    }
}

// MARK: - 08 · คิวอาร์การ์ด

/**
 * บัตรกระดาษพร้อม QR จริง — สแกนแล้วเปิดการ์ดใบนี้ได้
 * ทางเดียวที่การ์ดข้ามจากหน้าจอไปอยู่บนของพิมพ์ได้โดยไม่ตาย — QR ปลอมบนบัตรที่ขาย "ของจริงตรวจสอบได้" คือความขัดแย้ง
 *
 * # ท่าเปลี่ยนหน้า — "บัตรถูกพลิกเก็บ"
 */
@Composable
fun ContactQRWidget(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val link = "https://salehere.co.th/star/${Profile.me.handle}"
    val t = Scrub.ease(Scrub.t(scrub.d))
    val s = Scrub.dir(scrub.d)
    val verified = VerifiedFacts.current.verified
    val shape = RoundedCornerShape(16.dp)
    val shade = Color.Black.opacity(0.35)

    Box(
        modifier
            .fillMaxSize()
            .graphicsLayer {
                rotationY = -s * 58f * t
                // perspective 0.5 ของ SwiftUI = กล้องถอยห่างเป็นสองเท่า
                cameraDistance = 16f * density
                val k = 1f - 0.1f * t
                scaleX = k
                scaleY = k
                alpha = Scrub.fade(t, 0.7).toFloat()
            }
            .shadow(12.dp, shape, clip = false, ambientColor = shade, spotColor = shade)
            .clip(shape)
            .background(Deal.card),
    ) {
        Column(
            Modifier.fillMaxSize().padding(13.dp),
            verticalArrangement = Arrangement.spacedBy(9.dp, Alignment.CenterVertically),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            QRCode(
                link, tint = Deal.ink,
                modifier = Modifier
                    .weight(1f, fill = false)
                    .scrubAperture(scrub.d, lead = 0.1, feather = 0.2f, dim = 0.35)
                    .widthIn(max = 118.dp)
                    .aspectRatio(1f),
            )

            Column(
                Modifier.scrubVeil(scrub.d, lead = 0.28, drop = 16f, pull = 6f),
                verticalArrangement = Arrangement.spacedBy(1.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                // ตัว @ ไม่ใช่ส่วนหนึ่งของค่า — แยกออกจากช่องที่แก้ได้ ไม่งั้นพิมพ์แล้วได้ "@@nira"
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("@", style = sh(11.5f, SHFont.heavy), color = Deal.ink, maxLines = 1, softWrap = false)
                    EditableText(
                        field = ProfileField.handle,
                        style = TextSlotStyle(size = 11.5f, weight = SHFont.heavy, color = Deal.ink),
                    )
                }
                // ไวยากรณ์เดียวกับ QR บนสลิปโอนเงิน — สแกนแล้วได้คำตอบว่าการ์ดใบนี้ของจริงไหม
                Row(
                    horizontalArrangement = Arrangement.spacedBy(3.5.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    if (verified) {
                        VerifiedSeal(radius = 5f, punch = Deal.card, tint = Deal.inkSoft, compact = true)
                    }
                    Text(
                        if (verified) "สแกนเพื่อตรวจสอบ" else "สแกนเพื่อดูการ์ดเต็ม",
                        style = sh(8.5f, SHFont.semibold),
                        color = Deal.inkSoft,
                        maxLines = 1,
                        softWrap = false,
                        autoSize = dealShrink(8.5f, 0.7f),
                    )
                }
            }
        }
        // แถบสีธีมที่หัวบัตร — ที่เดียวที่บัตรกระดาษยอมรับสีของการ์ด (มุมบนโค้งตามบัตรที่ clip ไว้แล้ว)
        Box(
            Modifier
                .align(Alignment.TopCenter)
                .fillMaxWidth()
                .height(5.dp)
                .background(theme.rawAccent),
        )
    }
}

// MARK: - 09 · แถบติดต่อ

/**
 * ช่องทางติดต่อทั้งหมดในบรรทัดเดียว — ตัวมินิมอลที่สุดในตระกูล
 * ไม่มีกรอบ ไม่มีป้ายกำกับ ไม่มีไอคอน เหลือแค่ค่าจริงคั่นด้วยจุด
 *
 * # ท่าเปลี่ยนหน้า — "บรรทัดไถลออกข้าง"
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun ContactBarWidget(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val lines = ContactLine.all

    FairRow(spacing = 9f, modifier = modifier.fillMaxSize()) {
        lines.forEachIndexed { i, l ->
            if (i > 0) {
                Box(Modifier.size(2.5.dp).background(ink.text(0.22), CircleShape))
            }
            EditableText(
                field = l.field,
                style = TextSlotStyle(size = 12f, weight = SHFont.semibold, color = ink.text(0.78)),
                modifier = Modifier.scrubSlide(
                    scrub.d, travel = 50f + i * 16f,
                    lead = Scrub.lead(i, lines.size, scrub.d, step = 0.07),
                    fade = 0.55,
                ),
            )
        }
    }
}

// MARK: - 10 · สามบรรทัด

/**
 * ช่องทางติดต่อเรียงเป็นสามบรรทัด มีเส้นคั่นบาง ๆ — เหลือเฉพาะ *ค่าที่ต้องก็อป*
 * เหมาะกับการ์ดที่มี hero อยู่ข้างบนแล้ว — ชื่อกับรูปถูกเล่าไปแล้วหนึ่งรอบ
 *
 * # ท่าเปลี่ยนหน้า — "บรรทัดมุดใต้ขอบทีละบรรทัด"
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun ContactStackWidget(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val lines = ContactLine.all
    val hair = ink.line(0.1)

    Column(modifier.fillMaxSize()) {
        lines.forEachIndexed { i, l ->
            Row(
                Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .scrubVeil(
                        scrub.d, lead = Scrub.lead(i, lines.size, scrub.d, step = 0.08),
                        drop = 24f, pull = 12f,
                    )
                    .drawWithContent {
                        drawContent()
                        if (i > 0) drawRect(hair, size = Size(size.width, 0.7.dp.toPx()))
                    },
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    l.label,
                    style = sh(10.5f, SHFont.semibold),
                    color = ink.text(0.4),
                    maxLines = 1,
                    softWrap = false,
                    modifier = Modifier.width(40.dp),
                )
                EditableText(
                    field = l.field,
                    style = TextSlotStyle(size = 14f, weight = SHFont.bold, color = ink.text(0.94)),
                )
            }
        }
    }
}

// MARK: - 11 · ไลน์ตัวใหญ่

/**
 * ช่องทางเดียวตัวใหญ่ — ไลน์ เพราะดีลในไทยจบที่ไลน์เกือบทั้งหมด
 * การ์ดที่ให้สามช่องทางเท่า ๆ กันคือการ์ดที่ไม่ได้บอกว่า *ควรทักช่องไหน*
 *
 * # ท่าเปลี่ยนหน้า — "ตัวอักษรคลายตัวออก" (ภาษาเดียวกับ `heroMinimal`)
 */
@Composable
fun ContactLineWidget(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val c = Profile.me.creator.contact
    val lineSize = min(32f, size.width * 0.1f)
    // บีบอยู่ตอนนิ่ง แล้วคลายออกตอนจากไป
    val t = Scrub.ease(Scrub.t(scrub.d, 0.16))

    Column(modifier.fillMaxSize()) {
        Text(
            "ทักมาทางไลน์",
            style = sh(10.5f, SHFont.bold).copy(letterSpacing = 1.2.sp),
            color = theme.accent.opacity(0.9),
            maxLines = 1,
            softWrap = false,
            modifier = Modifier.scrubVeil(scrub.d, lead = 0.4, drop = 16f, pull = 6f),
        )

        Spacer(Modifier.height(3.dp))

        EditableText(
            field = ProfileField.lineId,
            style = TextSlotStyle(
                size = lineSize, weight = SHFont.black, color = ink.text(0.97),
                tracking = -0.8f + 8f * t,
            ),
            modifier = Modifier.scrubVeil(scrub.d, lead = 0.24, drop = 40f, pull = 8f),
        )

        // ช่องไฟ 3 + `Spacer(minLength: 4)` + ช่องไฟ 3
        Spacer(Modifier.height(10.dp))
        Spacer(Modifier.weight(1f))

        // เวลาตอบกลับมาจากอินบ็อกซ์จริง แก้ไม่ได้ · สถานะผู้รับงานพิมพ์เองได้ — แยกเป็นสองก้อน
        Row(
            Modifier.scrubVeil(scrub.d, lead = 0.0, drop = 20f, pull = 16f),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (c.responseTime.isNotEmpty()) {
                Text(
                    "ตอบกลับ ${c.responseTime} ·",
                    style = sh(10.5f, SHFont.medium),
                    color = ink.text(0.42),
                    maxLines = 1,
                    softWrap = false,
                )
            }
            EditableText(
                field = ProfileField.role,
                style = TextSlotStyle(size = 10.5f, weight = SHFont.medium, color = ink.text(0.42)),
            )
        }
    }
}

// MARK: - 12 · ชิปช่องทาง

/**
 * สามช่องทางเป็นชิปเรียง ขึ้นบรรทัดเองเมื่อแคบ — กึ่งกลางระหว่างแถบบรรทัดเดียวกับนามบัตร
 * มีขอบเขตของแต่ละช่องทางให้ตาจับได้ แต่ยังไม่มีพื้นทึบให้อ่านเป็นตาราง
 *
 * # ท่าเปลี่ยนหน้า — "ชิปปลิวออกข้างทีละใบ"
 */
@Composable
fun ContactChipsWidget(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val lines = ContactLine.all

    FlowLayout(spacing = 8f, modifier = modifier.fillMaxSize()) {
        lines.forEachIndexed { i, l ->
            Row(
                Modifier
                    .scrubSlide(
                        scrub.d, travel = 60f + i * 14f,
                        lead = Scrub.lead(i, lines.size, scrub.d, step = 0.07),
                        fade = 0.55,
                    )
                    .border(0.8.dp, ink.line(0.18), CircleShape)
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                SFSymbol(l.icon, size = 10f, tint = theme.accent)
                EditableText(
                    field = l.field,
                    style = TextSlotStyle(size = 12f, weight = SHFont.semibold, color = ink.text(0.9), corner = 10f),
                )
            }
        }
    }
}
