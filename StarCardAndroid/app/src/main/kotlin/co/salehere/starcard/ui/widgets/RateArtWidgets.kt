package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
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
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.ClipOp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.addOutline
import androidx.compose.ui.graphics.asAndroidPath
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.ScrubDigits
import co.salehere.starcard.components.redacted
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.RateItem
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalGhostData
import co.salehere.starcard.ui.LocalSlotTilt
import co.salehere.starcard.ui.editor.TextSlotStyle
import co.salehere.starcard.ui.editor.editableSlot
import kotlin.math.max

// MARK: - สำรับ "เรตราคาแบบศิลป์" (= Views/Widgets/RateArtWidgets.swift)
//
// ป้ายไฟ — หน้าตาเดียวที่เพิ่มเข้าตระกูล `rate` ต่อจากป้ายห้อยราคา (`RateTagsWidget`)
// payload ก้อนเดิมทั้งหมด สลับแบบแล้วไม่มีฟิลด์ไหนหาย
//
// กติกาสามข้อของสำรับ "ปิดดีล" ยกมาทั้งดุ้น (ดู `BookingWidgets`):
// 1. **หนึ่งแบบ หนึ่งวัสดุ** — ป้ายไฟคือแผ่นมืดกับหลอดเรืองแสง
// 2. **ท่าเปลี่ยนหน้าต้องมาจากวัสดุนั้น** — หลอดไฟดับไล่ทีละดวง
// 3. **ตัวเลขห้ามจางหาย** — ทุกราคาเดินผ่าน `DealPrice` ซึ่งบังคับมิเตอร์ (`ScrubDigits`) ให้

// MARK: - ชิ้นส่วนร่วม

/**
 * ราคาหนึ่งค่าพร้อมหน่วย — โครงกลางของตระกูล `rate`
 * ฿ อยู่นอกช่องที่แก้ได้ (กับดัก "฿฿35,000") · ช่องพิมพ์ประกาศที่กล่องรวม ไม่ใช่ที่มิเตอร์
 * - slotColor: สีของ *ช่องพิมพ์* — แยกจากสีที่วาด เพราะบางแบบไล่สีตามนิ้ว (ป้ายไฟ)
 * - glow / lit: แสงหลอดของป้ายไฟ (= `.shadow` สองชั้นที่ครอบราคาใน Swift) — ชั้นคมเป็นเงาตัวอักษร ชั้นฟุ้งวาดหลังกล่อง
 */
@Composable
private fun DealPrice(
    index: Int,
    unit: String,
    size: Float,
    weight: FontWeight = SHFont.black,
    color: Color = Deal.ink,
    unitColor: Color? = null,
    unitSize: Float? = null,
    slotColor: Color? = null,
    lead: Double = 0.0,
    step: Double = 0.035,
    glow: Color? = null,
    lit: Double = 1.0,
    modifier: Modifier = Modifier,
) {
    val scrub = LocalPageScrub.current
    // ราคาเป็นกล่องรวมสองก้อน (฿ + มิเตอร์ตัวเลข) — ฟอนต์กับสีจึงต้องใส่เอง
    val tune = LocalWidgetTextStyle.current
    val ink = LocalCardInk.current
    val accent = LocalCardAccent.current
    val ghost = LocalGhostData.current
    val density = LocalDensity.current

    val price = Profile.me.ratePrice(index)
    val drop = max(14f, size * 0.8f)
    val c = tune.color(color, ProfileField.ratePrices, index, ink, accent) ?: color
    val core = glow?.let { Shadow(it.opacity(0.85 * lit), Offset.Zero, with(density) { 7.dp.toPx() }) }
    var font = tune.font(size, weight, ProfileField.ratePrices, index)
    if (core != null) font = font.copy(shadow = core)
    var unitFont = sh(unitSize ?: max(8f, size * 0.34f), SHFont.bold)
    if (core != null) unitFont = unitFont.copy(shadow = core)
    val uSize = unitFont.fontSize.value
    val id = TextSlotID(field = ProfileField.ratePrices, index = index)
    val slot = tunedSlot(id, TextSlotStyle(size = size, weight = weight, color = slotColor ?: c, corner = 6f))

    Row(
        modifier.then(if (glow != null) Modifier.neonBloom(glow.opacity(0.45 * lit * 0.4), 17f) else Modifier),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        // ฿ อยู่นอกช่องที่แก้ได้ — ค่าที่เก็บเป็นตัวเลขล้วน (ดู `Profile.ratePrice`)
        Row(
            Modifier
                .alignByBaseline()
                // ช่องพิมพ์ประกาศที่กล่องรวม ไม่ใช่ที่มิเตอร์ — มิเตอร์แตกตัวอักษรเป็นชิ้นละตัว กรอบเล็กเกินจะแตะโดน
                .editableSlot(id, slot)
                .redacted(ghost),
        ) {
            Text(
                "฿", style = font, color = c, maxLines = 1, softWrap = false,
                modifier = Modifier.alignByBaseline().scrubVeil(scrub.d, lead = lead, drop = drop, pull = 0f),
            )
            ScrubDigits(
                text = Fmt.baht(price), d = scrub.d, lead = lead, step = step, drop = drop,
                style = font, color = c, modifier = Modifier.alignByBaseline(),
            )
        }
        Text(
            "/$unit",
            style = unitFont,
            color = unitColor ?: c.opacity(0.55),
            maxLines = 1,
            softWrap = false,
            autoSize = TextAutoSize.StepBased(minFontSize = (uSize * 0.6f).sp, maxFontSize = uSize.sp, stepSize = 0.25.sp),
            modifier = Modifier.alignByBaseline().scrubVeil(scrub.d, lead = lead, drop = 14f, pull = 4f),
        )
    }
}

/**
 * ชื่อรายการหนึ่งบรรทัด — ย่อลงเมื่อยาว **ไม่ตัดด้วย …**
 * ชื่องานที่ถูกตัดกลางคำทำให้ทั้งใบตอบไม่ได้ว่าราคานี้คือราคาของอะไร
 */
@Composable
private fun DealLabel(
    index: Int,
    size: Float = 9f,
    weight: FontWeight = SHFont.heavy,
    color: Color = Deal.ink,
    slotColor: Color? = null,
    tracking: Float = 0.8f,
    upper: Boolean = true,
    modifier: Modifier = Modifier,
) {
    // ป้ายนี้ตั้งสีเอง (สีที่วาดกับสีของช่องต่างกันโดยตั้งใจ) จึงต้องถามสีที่ผู้ใช้เลือกเอง
    val tune = LocalWidgetTextStyle.current
    val ink = LocalCardInk.current
    val accent = LocalCardAccent.current
    val ghost = LocalGhostData.current
    val raw = Profile.me.rateLabel(index)
    val id = TextSlotID(field = ProfileField.rateLabels, index = index)
    val slot = tunedSlot(
        id,
        TextSlotStyle(size = size, weight = weight, color = slotColor ?: color, tracking = tracking, uppercase = upper, corner = 4f),
    )
    val style = tune.font(size, weight, ProfileField.rateLabels, index).copy(letterSpacing = tracking.sp)
    val s = style.fontSize.value
    Text(
        if (upper) raw.uppercase() else raw,
        style = style,
        color = tune.color(color, ProfileField.rateLabels, index, ink, accent) ?: color,
        maxLines = 1,
        softWrap = false,
        autoSize = TextAutoSize.StepBased(minFontSize = (s * 0.5f).sp, maxFontSize = s.sp, stepSize = 0.25.sp),
        modifier = modifier.editableSlot(id, slot).redacted(ghost),
    )
}

/**
 * เส้นประแนวนอน — แถบทึบกว้าง `dash` เว้น `gap` เรียงจากซ้าย (สูงสุด 90 ขีด)
 * ไม่ใช่ stroke dash เพราะ dash ของ stroke จัดจังหวะประใหม่ทุกครั้งที่ความกว้างเปลี่ยน
 */
@Suppress("unused")
@Composable
private fun DashRule(color: Color, dash: Float = 2f, gap: Float = 3f, modifier: Modifier = Modifier) {
    Canvas(modifier.fillMaxWidth().height(0.9.dp)) {
        val d = dash.dp.toPx()
        val step = (dash + gap).dp.toPx()
        for (k in 0 until 90) {
            val x = k * step
            if (x >= size.width) break
            drawRect(color, topLeft = Offset(x, 0f), size = Size(minOf(d, size.width - x), size.height))
        }
    }
}

// MARK: - 01 · ป้ายไฟ

/**
 * ป้ายไฟนีออนหน้าร้าน — แผ่นมืด หลอดเรืองแสงสีธีม ตัวเลขคือหลอด
 * **มันคือเรตตัวเดียวในตู้ที่เป็นของมืด** — สำหรับการ์ดสายกลางคืน/สายอีเวนต์ที่ทั้งใบเป็นพื้นมืด
 * สามบรรทัดพอ — สี่บรรทัดขึ้นไปอ่านเป็นจอ LED ไม่ใช่ป้ายหน้าร้าน
 *
 * ท่าเปลี่ยนหน้า "หลอดดับไล่ทีละดวง" — ความสว่างเป็นฟังก์ชันของระยะหน้าล้วน ๆ ไม่ใช่ไทม์เมอร์กะพริบ
 */
@Composable
fun RateNeonWidget(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val rates = Profile.me.creator.rates.take(3)
    // สีหลอด — ใช้สีดิบเสมอ ป้ายไฟคือ *แสงที่เปล่งออกมา* ไม่ใช่หมึกที่พลิกตามพื้นการ์ด
    val glow = theme.rawAccent
    val shape = RoundedCornerShape(18.dp)

    Column(
        modifier
            .fillMaxSize()
            .neonShadow(Color.Black.opacity(0.42), 14f, y = 8f, shape = shape)
            .background(rgb(0.055, 0.045, 0.088), shape)
            // แสงที่ผนังรับไว้ — ป้ายไฟจริงย้อมพื้นรอบตัวมันเสมอ
            .drawBehind {
                val r = 280.dp.toPx()
                val wall = glow.opacity(0.24)
                drawRoundRect(
                    brush = Brush.radialGradient(
                        0f to wall, (2f / 280f) to wall, 1f to Color.Transparent,
                        center = Offset(size.width * 0.14f, -size.height * 0.05f),
                        radius = r,
                    ),
                    cornerRadius = CornerRadius(18.dp.toPx(), 18.dp.toPx()),
                )
            }
            // หลอดขอบ — ไม่ clip ทับ ไม่งั้นแสงที่ล้นออกนอกขอบถูกตัดจนเหลือแค่เส้นสี
            .neonRim(glow.opacity(0.5), glow.opacity(0.65 * 0.5), corner = 18f, width = 1f, radius = 6f)
            .padding(horizontal = 16.dp, vertical = 14.dp),
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .scrubVeil(scrub.d, lead = 0.48, drop = 14f, pull = 4f)
                .padding(bottom = 11.dp),
            horizontalArrangement = Arrangement.spacedBy(7.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Canvas(Modifier.size(5.dp)) {
                drawIntoCanvas { canvas ->
                    val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
                        this.color = glow.toArgb()
                        setShadowLayer(5.dp.toPx(), 0f, 0f, glow.toArgb())
                    }
                    canvas.nativeCanvas.drawCircle(size.width / 2, size.height / 2, size.minDimension / 2, paint)
                }
            }
            Text(
                "เรตราคา",
                style = sh(9f, SHFont.heavy).copy(letterSpacing = 2.6.sp),
                color = Color.White.opacity(0.6),
                maxLines = 1,
                softWrap = false,
            )
        }

        Column(Modifier.fillMaxWidth().weight(1f)) {
            rates.forEachIndexed { i, r ->
                key(r.id) {
                    Box(Modifier.fillMaxWidth().weight(1f), contentAlignment = Alignment.CenterStart) {
                        NeonTube(r, i, rates.size, glow)
                    }
                }
            }
        }
    }
}

@Composable
private fun NeonTube(r: RateItem, i: Int, count: Int, glow: Color) {
    val scrub = LocalPageScrub.current
    val lead = Scrub.lead(i, count, scrub.d, step = 0.09)
    val lit = 1.0 - Scrub.ease(Scrub.t(scrub.d, lead)).toDouble()
    Column(Modifier.fillMaxWidth()) {
        DealLabel(
            index = i, size = 8.5f, weight = SHFont.heavy,
            color = glow.opacity(0.3 + 0.6 * lit),
            slotColor = glow, tracking = 2.2f,
        )
        // เรืองสองชั้น: ไส้หลอดแคบ ๆ กับแสงฟุ้งกว้าง — ชั้นเดียวได้แค่ตัวหนังสือมีขอบเบลอ
        Row(Modifier.fillMaxWidth()) {
            DealPrice(
                index = i, unit = r.unit, size = 26f, weight = SHFont.black,
                color = Color.White.opacity(0.22 + 0.78 * lit),
                unitColor = Color.White.opacity(0.18 + 0.32 * lit),
                unitSize = 9f, slotColor = Color.White, lead = lead + 0.02,
                glow = glow, lit = lit,
            )
        }
    }
}

// MARK: - เครื่องมือวาด (ส่วนตัว)

/** สไตล์ช่องที่ผ่านฟอนต์/สี/ขนาดของเจ้าของการ์ดแล้ว — ส่งให้ `editableSlot` เหมือนที่ `EditableText` ทำ */
@Composable
private fun tunedSlot(id: TextSlotID, style: TextSlotStyle): TextSlotStyle {
    val s = style.tuned(LocalWidgetTextStyle.current, id, LocalCardInk.current, LocalCardAccent.current)
    s.tilt = LocalSlotTilt.current
    return s
}

/** แสงฟุ้งรอบกล่อง (= `.shadow(radius: 17)` ชั้นนอก) — วงรีไล่จางจากกลางกล่องออกไป `spread` pt */
private fun Modifier.neonBloom(color: Color, spread: Float): Modifier =
    if (color.alpha <= 0.004f) this else drawBehind {
        val s = spread.dp.toPx()
        val w = size.width + s * 2
        val h = size.height + s * 2
        val r = h / 2f
        scale(scaleX = w / h, scaleY = 1f, pivot = center) {
            drawCircle(
                Brush.radialGradient(listOf(color, color.copy(alpha = 0f)), center = center, radius = r),
                radius = r, center = center,
            )
        }
    }

/** เส้นขอบเรืองแสง (= `strokeBorder` + `.shadow(radius:)`) — เงาเบลอของเส้นด้วย `setShadowLayer` */
private fun Modifier.neonRim(color: Color, glow: Color, corner: Float, width: Float, radius: Float): Modifier = drawWithContent {
    drawContent()
    val sw = width.dp.toPx()
    val r = corner.dp.toPx()
    drawIntoCanvas { canvas ->
        val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
            style = android.graphics.Paint.Style.STROKE
            strokeWidth = sw
            this.color = color.toArgb()
            setShadowLayer(radius.dp.toPx(), 0f, 0f, glow.toArgb())
        }
        canvas.nativeCanvas.drawRoundRect(sw / 2, sw / 2, size.width - sw / 2, size.height - sw / 2, r - sw / 2, r - sw / 2, paint)
    }
}

/** เงาแบบ `.shadow(color:radius:x:y:)` ของ SwiftUI — เจาะรูปทรงของตัวเองออก เงาจึงไม่ทะลุใต้แผ่น */
private fun Modifier.neonShadow(color: Color, radius: Float, x: Float = 0f, y: Float = 0f, shape: Shape): Modifier =
    if (color.alpha <= 0f) this else drawBehind {
        val path = Path().apply { addOutline(shape.createOutline(size, layoutDirection, this@drawBehind)) }
        clipPath(path, ClipOp.Difference) {
            drawIntoCanvas { canvas ->
                val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
                    this.color = color.toArgb()
                    setShadowLayer(max(0.1f, radius.dp.toPx()), x.dp.toPx(), y.dp.toPx(), color.toArgb())
                }
                canvas.nativeCanvas.drawPath(path.asAndroidPath(), paint)
            }
        }
    }
