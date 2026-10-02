package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.offset
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.scrubLouver
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.LocalWidgetSurface
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.VerifiedWork
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.EdGrain
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.PlatePatternLayer
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.TextFit
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.EditableParagraph
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import kotlin.math.max
import kotlin.math.min

// MARK: - สำรับบรรณาธิการ (= Views/Widgets/EditorialWidgets.swift)
//
// แปลงตรงจากแผ่นตัวอย่างแปดใบที่เจ้าของการ์ดส่งมา — **ผัง สัดส่วน วัสดุ และสี ตามต้นฉบับ · ตัวอักษรใช้ฟอนต์ของแอป**
//
// สำรับนี้ **ตัวอักษรคือผัง** ไม่ใช่ข้อเท็จจริงของใคร — ทุกก้อนจึงเก็บ **ต่อชิ้น** ด้วย `ProfileField.note` + `index`
// และค่าตั้งต้นเดินทางมากับช่อง: หยิบออกจากตู้แล้วต้องเห็นแผ่นที่จัดเสร็จแล้ว ไม่ใช่กรอบเปล่า
//
// ทุกกรอบรูปประกาศ `photoSlot(n)` — เลขช่องไม่ซ้ำกันในใบเดียวกัน · ช่อง 1–3 รับรูปโปรไฟล์เป็นค่าตั้งต้น
//
// `Ed` · `EdSkin` · `EdHalftone` · `EdText` · `EdPhoto` · `EdPlace` · `EdSelectionHandles` อยู่ใน WidgetKit.kt
// · `EdGrain` อยู่ใน theme/CardTheme.kt

// MARK: - ชิ้นส่วนร่วมของไฟล์นี้

/** พื้นกระดาษ + ลายของแผ่น — สองชั้นล่างสุดของทุกใบในสำรับ (`skin.sheet` + `PlatePatternLayer`) */
@Composable
private fun EdSheetLayer(skin: EdSkin) {
    Box(Modifier.fillMaxSize().background(skin.sheet))
    PlatePatternLayer(sheet = skin.sheet)
}

/**
 * ระยะขอบติดลบแนวตั้ง (= `.padding(.vertical, -x)` / `VStack(spacing: -x)`) — Compose ห้าม padding ติดลบ
 * กล่องเตี้ยลงตามที่สั่ง แต่ตัวอักษรยังวาดเต็มตัว ล้นขึ้นบน/ลงล่างเท่าเดิม
 */
private fun Modifier.edBleed(top: Float, bottom: Float = top): Modifier = layout { measurable, constraints ->
    val t = top.dp.roundToPx()
    val b = bottom.dp.roundToPx()
    val p = measurable.measure(constraints.offset(vertical = t + b))
    layout(p.width, max(0, p.height - t - b)) { p.place(0, -t) }
}

/** ลดความอิ่มสีทั้งชั้น (= `.saturation(s)`) — วาดเนื้อหาลงเลเยอร์ที่มีฟิลเตอร์สี */
private fun Modifier.edSaturation(s: Float): Modifier = this.drawWithContent {
    val paint = Paint().apply {
        colorFilter = ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(s) })
    }
    drawIntoCanvas { canvas ->
        canvas.saveLayer(Rect(0f, 0f, size.width, size.height), paint)
        drawContent()
        canvas.restore()
    }
}

/** `.minimumScaleFactor(k)` ของ `Text` ธรรมดา (ไม่ใช่ช่องแก้ได้) */
private fun edShrink(size: Float, k: Float): TextAutoSize =
    TextAutoSize.StepBased(minFontSize = (size * k).sp, maxFontSize = size.sp, stepSize = 0.5.sp)

// MARK: - 1 · กำแพงโพลารอยด์

/** ที่แปะของใบหนึ่งใบบนผนัง — x/y/w/h เป็นสัดส่วนของแผ่น */
private data class WallPolaroidSpot(
    val x: Float, val y: Float, val w: Float, val h: Float,
    val tilt: Double,
    val pin: Color,
)

/**
 * ผังของผนัง **ตามจำนวนผลงานที่มีจริง** — ไม่วนของซ้ำให้ครบห้าใบ
 * (สองใบที่ชื่อแบรนด์กับยอดวิวชุดเดียวกันอ่านเป็นบั๊ก · ช่องโหว่ตรงมุมอ่านเป็นของที่โหลดไม่ครบ)
 * ทุกผัง: ไม่มีใบไหนตรง 0° · องศาไม่ซ้ำกัน · แถวบนจบก่อนแถวล่างเริ่ม
 */
private fun wallPolaroidSpots(n: Int): List<WallPolaroidSpot> = when (n) {
    0, 1 -> listOf(WallPolaroidSpot(0.300f, 0.120f, 0.400f, 0.700f, -2.0, Ed.pinRed))
    2 -> listOf(
        WallPolaroidSpot(0.070f, 0.140f, 0.360f, 0.620f, -2.6, Ed.pinRed),
        WallPolaroidSpot(0.545f, 0.175f, 0.360f, 0.620f, 2.4, Ed.pinYellow),
    )
    3 -> listOf(
        WallPolaroidSpot(0.150f, 0.005f, 0.345f, 0.470f, -2.6, Ed.pinRed),
        WallPolaroidSpot(0.520f, 0.015f, 0.350f, 0.470f, 2.4, Ed.pinYellow),
        WallPolaroidSpot(0.325f, 0.520f, 0.345f, 0.470f, -2.2, Ed.pinBlue),
    )
    4 -> listOf(
        WallPolaroidSpot(0.075f, 0.005f, 0.345f, 0.470f, -2.6, Ed.pinRed),
        WallPolaroidSpot(0.555f, 0.015f, 0.350f, 0.470f, 2.4, Ed.pinYellow),
        WallPolaroidSpot(0.075f, 0.505f, 0.345f, 0.470f, -3.0, Ed.pinBlue),
        WallPolaroidSpot(0.555f, 0.520f, 0.345f, 0.470f, 2.2, Ed.pinRed),
    )
    else -> listOf(
        WallPolaroidSpot(0.165f, 0.005f, 0.345f, 0.470f, -2.6, Ed.pinRed),
        WallPolaroidSpot(0.515f, 0.015f, 0.350f, 0.470f, 2.4, Ed.pinYellow),
        WallPolaroidSpot(0.040f, 0.505f, 0.330f, 0.470f, -3.4, Ed.pinYellow),
        WallPolaroidSpot(0.360f, 0.530f, 0.315f, 0.470f, 2.8, Ed.pinBlue),
        WallPolaroidSpot(0.655f, 0.525f, 0.330f, 0.470f, -1.8, Ed.pinRed),
    )
}

/**
 * ฟิล์มแปะกระจายบนผนังครีม · **ชื่อแบรนด์ทับขอบล่างของใบ · ยอดวิวกับ ER อยู่ใต้ใบ**
 *
 * หนึ่งใบ = ผลงานหนึ่งชิ้นที่แพลตฟอร์มยืนยันแล้ว ไม่ใช่คนหนึ่งคน
 * สามอย่างที่ทำให้มันเป็น "กำแพง": ใบเหลื่อมกัน · องศาไม่ซ้ำกันสักใบ · ชื่ออยู่บนผนัง ไม่ได้อยู่บนฟิล์ม
 * ท่าเปลี่ยนหน้า: ใบทยอยล้มลงตามลำดับที่กลับด้านเองตามทิศ (`Scrub.lead`)
 */
@Composable
fun WallPolaroid(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val skin = Ed.skin(surface, Ed.cream, cardInk, theme)

    // ห้าชิ้นล่าสุดพอสำหรับผนังหนึ่งบาน — ที่เหลืออยู่ในใบ "ผลงานยืนยัน" แบบอื่นของตระกูล
    val works = Profile.me.creator.track.works.take(5)
    val spots = wallPolaroidSpots(works.size)
    Box(modifier.size(size.width.dp, size.height.dp)) {
        EdSheetLayer(skin)
        if (skin.papered) EdGrain(count = 380, opacity = 0.05)

        works.forEachIndexed { i, work ->
            val s = spots[min(i, spots.size - 1)]
            EdPlace(s.x, s.y, s.w, s.h, size, tilt = s.tilt) {
                WallPolaroidCard(s, work, i, works.size, size, skin, cardInk, scrub.d, Modifier.linkSlot(work.postURL))
            }
        }
    }
}

@Composable
private fun WallPolaroidCard(
    c: WallPolaroidSpot, work: VerifiedWork, i: Int, n: Int, size: Size,
    skin: EdSkin, cardInk: InkStyle, d: Float, modifier: Modifier,
) {
    val lead = Scrub.lead(i, n, d, step = 0.1)
    // **ช่องฟิล์มเป็นแนวตั้ง 4:5 เสมอ** — ความสูงมาจากความกว้าง ไม่ใช่เศษส่วนของความสูงช่อง
    val w = c.w * size.width
    val rim = max(4f, w * 0.055f)
    val nameSize = max(12f, min(23f, w * 0.17f))
    // ระยะที่ชื่อ **ห้อยพ้นขอบล่างของใบ** — บรรทัดแรกนั่งบนขอบขาว บรรทัดที่สองอยู่นอกใบ
    val hang = nameSize * 0.95f
    val filmH = (w - rim * 2) * 1.25f + rim * 2.8f
    // **ย่อทั้งใบให้พอดีช่อง ไม่ใช่ปล่อยให้ล้น** — ย่อตามสัดส่วน โพลารอยด์ยังเป็นโพลารอยด์ แค่เล็กลง
    val natural = filmH + hang + nameSize * 0.35f + 24f
    val fit = min(1f, c.h * size.height / max(natural, 1f))
    val boxH = max(1f, c.h * size.height)
    Column(
        modifier
            .fillMaxWidth()
            .wrapContentHeight(Alignment.Top, unbounded = true)
            .heightIn(min = boxH.dp)
            .scrubLouver(d, lead = lead, angle = 44.0, shrink = 0.1f)
            .graphicsLayer {
                scaleX = fit
                scaleY = fit
                transformOrigin = TransformOrigin(0.5f, 0f)
            },
    ) {
        // ขอบขาวล่างหนากว่าอีกสามด้าน — และนั่นคือที่ที่ชื่อไปนั่งทับ
        Box(Modifier.fillMaxWidth().height(filmH.dp)) {
            WallPolaroidFilm(c, work.photo, rim)
            WallPolaroidBrand(work.brand, nameSize, w, skin, cardInk, Modifier.align(Alignment.BottomCenter))
        }
        // ที่ว่างสำหรับครึ่งล่างของชื่อที่ห้อยออกมา — overlay ไม่กินที่ในผัง ต้องกันเอง
        Spacer(Modifier.height((hang + nameSize * 0.35f).dp))
        WallPolaroidMeta(work, skin)
    }
}

@Composable
private fun WallPolaroidFilm(c: WallPolaroidSpot, slot: Int, rim: Float) {
    val shade = Color.Black.opacity(0.16)
    val pinShade = Color.Black.opacity(0.22)
    Box(Modifier.fillMaxSize()) {
        Box(
            Modifier
                .fillMaxSize()
                .shadow(7.dp, RectangleShape, clip = false, ambientColor = shade, spotColor = shade)
                .background(Color.White)
                .border(0.6.dp, Color.Black.opacity(0.06))
                .padding(start = rim.dp, top = rim.dp, end = rim.dp, bottom = (rim * 1.5f).dp),
        ) {
            EdPhoto(slot, depth = 8f, modifier = Modifier.fillMaxSize())
        }
        // หมุดกลมคาบขอบบนของใบ — ครึ่งบนอยู่บนผนัง ครึ่งล่างอยู่บนฟิล์ม
        Box(
            Modifier
                .align(Alignment.TopCenter)
                .offset(y = (-9).dp)
                .size(11.dp)
                .shadow(2.dp, CircleShape, clip = false, ambientColor = pinShade, spotColor = pinShade)
                .background(c.pin, CircleShape),
        )
    }
}

/**
 * ชื่อตัวใหญ่ที่ **คาบขอบล่างของฟิล์ม** และยื่นพ้นขอบทั้งด้านล่างและด้านข้าง (~16%)
 * — สิ่งเดียวที่ทำให้ตาอ่านว่าชื่อกับรูปเป็นของชิ้นเดียวกันที่ถูกแปะไว้
 * เงาขาวจาง ๆ กันไม่ให้ตัวที่ยื่นเลยขอบใบไปอยู่บนพื้นการ์ดหายไปครึ่งบรรทัด
 */
@Composable
private fun WallPolaroidBrand(brand: String, s: Float, w: Float, skin: EdSkin, cardInk: InkStyle, modifier: Modifier) {
    val density = LocalDensity.current.density
    val glow = (if (skin.papered) Color.White else cardInk.base).opacity(0.75)
    Text(
        brand,
        style = sh(s, SHFont.black).copy(
            letterSpacing = (-s * 0.03f).sp,
            textAlign = TextAlign.Center,
            shadow = Shadow(glow, Offset.Zero, 2.5f * density),
        ),
        color = skin.marker,
        maxLines = 2,
        autoSize = edShrink(s, 0.4f),
        modifier = modifier
            .offset(y = (s * 0.95f).dp)
            .requiredWidth((w * 1.16f).dp),
    )
}

/**
 * สองบรรทัดใต้ชื่อแบรนด์ — **ผลของงาน แล้วค่อยชื่อแคมเปญ**
 * ไม่มี `EdText` สักบรรทัด: ตัวเลขชั้นหลักฐานเป็นของที่ระบบออกให้ เปิดให้พิมพ์ทับเมื่อไหร่ก็เลิกเป็นหลักฐาน
 */
@Composable
private fun WallPolaroidMeta(work: VerifiedWork, skin: EdSkin) {
    Column(
        Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(1.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            Fmt.compact(work.views) + " วิว · ER " + Fmt.pct(work.engagementRate),
            style = sh(7f, SHFont.bold).copy(textAlign = TextAlign.Center),
            color = skin.ink.opacity(0.85),
            maxLines = 1,
            softWrap = false,
            autoSize = edShrink(7f, 0.6f),
        )
        Text(
            work.campaign,
            style = sh(7f, SHFont.medium).copy(textAlign = TextAlign.Center),
            color = skin.inkSoft,
            maxLines = 2,
            autoSize = edShrink(7f, 0.6f),
        )
    }
}

// MARK: - 2 · ประโยคไฮไลต์

/**
 * สามบรรทัดบนกระดาษเทา · คำกลางถูก "เลือกอยู่" ในกล่องไฮไลต์ชมพู
 * ต้องมีครบสามอย่าง: ฟองแชตนำหน้าบรรทัดแรก · เส้นใต้ที่ลากเลยตัวอักษร · ประกายสองดวงข้างคำใหญ่
 */
@Composable
fun SayClarity(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val skin = Ed.skin(surface, Ed.paper, cardInk, theme)
    val big = min(58f, size.height * 0.33f)
    Box(modifier.size(size.width.dp, size.height.dp)) {
        EdSheetLayer(skin)
        if (skin.papered) EdGrain(count = 300, opacity = 0.045)

        Column(
            Modifier.fillMaxSize().padding(horizontal = (size.width * 0.075f).dp),
            verticalArrangement = Arrangement.spacedBy((size.height * 0.04f).dp, Alignment.CenterVertically),
            horizontalAlignment = Alignment.Start,
        ) {
            ClarityTopLine(size, skin, scrub.d)
            ClarityBigLine(big, scrub.d)
            EdText(
                2, "ไม่ใช่คิดไปเอง", "บรรทัดล่าง",
                TextSlotStyle(size = min(19f, size.height * 0.11f), weight = SHFont.regular,
                    color = skin.ink.opacity(0.9), tracking = -0.2f),
                modifier = Modifier.scrubVeil(scrub.d, lead = 0.06, drop = 22f, pull = 14f),
            )
        }
    }
}

@Composable
private fun ClarityTopLine(size: Size, skin: EdSkin, d: Float) {
    Row(
        Modifier.scrubVeil(d, lead = 0.24, drop = 20f, pull = 10f).fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ClarityBubble(size)
        EdText(
            0, "ลงมือทำแล้วได้", "บรรทัดบน",
            TextSlotStyle(size = min(23f, size.height * 0.135f), weight = SHFont.bold,
                color = skin.ink, tracking = -0.4f),
            // เส้นใต้ลากเลยตัวอักษร — ขีดที่คนขีดเอง ไม่ใช่ underline ของระบบ
            // วาดใต้ตัวอักษรในกรอบของมันเอง: กล่องตัวอักษรไทยเผื่อที่สระล่างไว้แล้ว ขีดจึงไม่หลุดกรอบ
            modifier = Modifier
                .weight(1f, fill = false)
                .drawBehind {
                    // `this.size` = กรอบของตัวอักษร (ไม่ใช่ `size` ของแผ่นที่ส่งเข้ามา)
                    val box = this.size
                    val bleed = 3.dp.toPx()
                    val thick = 2.dp.toPx()
                    drawRect(
                        skin.ink,
                        topLeft = Offset(-bleed, box.height - thick - 1.dp.toPx()),
                        size = Size(box.width + bleed * 2, thick),
                    )
                },
        )
    }
}

/** ฟองแชตสามจุด — วาดเอง ไม่ใช้อิโมจิ เพราะอิโมจิของระบบเปลี่ยนหน้าตาตามเวอร์ชัน */
@Composable
private fun ClarityBubble(size: Size) {
    val w = min(26f, size.height * 0.15f)
    val fill = grey(0.78)
    Box(Modifier.size(w.dp, (w * 0.76f).dp)) {
        Box(Modifier.fillMaxSize().background(fill, RoundedCornerShape((w * 0.42f).dp)))
        Row(
            Modifier.align(Alignment.Center),
            horizontalArrangement = Arrangement.spacedBy((w * 0.1f).dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            repeat(3) {
                Box(Modifier.size((w * 0.13f).dp).background(Color.White, CircleShape))
            }
        }
        Box(
            Modifier
                .align(Alignment.BottomStart)
                .offset((w * 0.16f).dp, (w * 0.13f).dp)
                .size((w * 0.22f).dp, (w * 0.2f).dp)
                .background(fill, Triangle),
        )
    }
}

@Composable
private fun ClarityBigLine(big: Float, d: Float) {
    Row(
        Modifier.scrubVeil(d, lead = 0.14, drop = 30f, pull = 12f).fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.weight(1f, fill = false).background(Ed.highlightPink.opacity(0.95))) {
            EdText(
                1, "ชัดเจน.", "คำที่เน้น",
                TextSlotStyle(size = big, weight = SHFont.black, color = Ed.ink, tracking = -big * 0.045f),
                // **ลบ** — กล่องของฟอนต์ไทยเผื่อที่ให้สระบน/ล่างไว้เสมอ ปล่อยตามนั้นแล้ว
                // แถบไฮไลต์จะสูงกว่าตัวอักษรเกือบเท่าตัว ซึ่งอ่านเป็นบล็อกสี ไม่ใช่ปากกาเน้นข้อความ
                modifier = Modifier
                    .edBleed(big * 0.085f)
                    .padding(horizontal = (big * 0.1f).dp),
            )
            EdSelectionHandles(Ed.handlePink, modifier = Modifier.matchParentSize())
        }
        Sparkle(
            tint = rgb(0.984, 0.855, 0.239),
            modifier = Modifier
                .offset(y = (-big * 0.34f).dp)
                .size((big * 0.52f).dp),
        )
    }
}

/** สามเหลี่ยมหางฟองแชต */
object Triangle : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline {
        val p = Path()
        p.moveTo(0f, size.height)
        p.lineTo(size.width, 0f)
        p.lineTo(size.width, size.height)
        p.close()
        return Outline.Generic(p)
    }
}

/** ประกายสี่แฉก — ดวงใหญ่กับดวงเล็กคู่กันเสมอ (ดวงเดียวอ่านเป็นดาว ไม่ใช่ประกาย) */
@Composable
fun Sparkle(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val s = min(size.width, size.height)
        val cx = size.width / 2
        val cy = size.height / 2
        val bigD = s * 0.72f
        val smallD = s * 0.38f
        drawPath(
            Star4.path(Size(bigD, bigD), Offset(cx - s * 0.1f - bigD / 2, cy + s * 0.06f - bigD / 2)),
            tint,
        )
        drawPath(
            Star4.path(Size(smallD, smallD), Offset(cx + s * 0.3f - smallD / 2, cy - s * 0.26f - smallD / 2)),
            tint,
        )
    }
}

/** ดาวสี่แฉกขอบโค้งเว้า */
object Star4 : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline =
        Outline.Generic(path(size))

    fun path(size: Size, origin: Offset = Offset.Zero): Path {
        val cx = origin.x + size.width / 2
        val cy = origin.y + size.height / 2
        val r = min(size.width, size.height) / 2
        val k = r * 0.30f
        return Path().apply {
            moveTo(cx, cy - r)
            quadraticTo(cx + k, cy - k, cx + r, cy)
            quadraticTo(cx + k, cy + k, cx, cy + r)
            quadraticTo(cx - k, cy + k, cx - r, cy)
            quadraticTo(cx - k, cy - k, cx, cy - r)
            close()
        }
    }
}

// MARK: - 3 · ปกผลงาน

/**
 * ปกนิตยสาร/ซีนหนึ่งหน้า — รูปเต็มแผ่น · หัวเรื่องคร่อมซ้ายขวา · แถบผลงานสี่ใบพาดกลาง · ชื่อย่อตัวยักษ์ปิดท้ายล่าง
 * หัวเรื่องแยกเป็นสองช่อง — แต่ละคำเกาะขอบของตัวเอง ช่องว่างตรงกลางจึงเป็นของผัง ไม่ใช่ของตัวอักษร
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun ZineCover(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    Box(modifier.size(size.width.dp, size.height.dp)) {
        ZineBackdrop(size)
        EdPlace(0.055f, 0.06f, 0.89f, 0.30f, size) { ZineHead(size, scrub.d) }
        EdPlace(0f, 0.455f, 1f, 0.26f, size) { ZineStrip(size, scrub.d) }
        EdPlace(0.055f, 0.775f, 0.89f, 0.205f, size, align = Alignment.BottomCenter) { ZineFooter(size, scrub.d) }
    }
}

/**
 * รูปพื้นเต็มแผ่น + ย้อมคราม + จุดฮาล์ฟโทน = ผิวของงานพิมพ์
 * ปกซีนคือ *งานพิมพ์สีเดียว* — ปล่อยสีจริงของรูปขึ้นมาแข่ง หัวเรื่องขาวจะอ่านไม่ออกทันที
 */
@Composable
private fun ZineBackdrop(size: Size) {
    val multiply = rgb(0.173, 0.314, 0.573).opacity(0.62)
    val screen = rgb(0.208, 0.376, 0.663).opacity(0.22)
    Box(Modifier.size(size.width.dp, size.height.dp)) {
        EdPhoto(
            2, depth = 14f,
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen)
                .drawWithContent {
                    drawContent()
                    drawRect(multiply, blendMode = BlendMode.Multiply)
                    drawRect(screen, blendMode = BlendMode.Screen)
                }
                .edSaturation(0.35f),
        )
        EdHalftone(step = 5f, dot = 1.4f, opacity = 0.16)
        Box(
            Modifier.fillMaxSize().background(
                Brush.verticalGradient(listOf(Color.Black.opacity(0.28), Color.Transparent, Color.Black.opacity(0.34))),
            ),
        )
    }
}

@Composable
private fun ZineHead(size: Size, d: Float) {
    val title = min(40f, size.width * 0.115f)
    Column(
        Modifier.fillMaxWidth().wrapContentHeight(Alignment.Top, unbounded = true),
        verticalArrangement = Arrangement.spacedBy((size.height * 0.03f).dp),
    ) {
        Row(
            Modifier.scrubVeil(d, lead = 0.2, drop = 30f, pull = 12f).fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            EdText(
                0, "ผลงาน", "หัวเรื่องซ้าย",
                TextSlotStyle(size = title, weight = SHFont.medium, color = Color.White, tracking = -0.5f),
                modifier = Modifier.weight(1f, fill = false).alignByBaseline(),
            )
            Spacer(Modifier.width(8.dp))
            EdText(
                1, "ที่ภูมิใจ", "หัวเรื่องขวา",
                TextSlotStyle(size = title, weight = SHFont.medium, color = Color.White,
                    align = TextAlign.End, tracking = -0.5f),
                modifier = Modifier.weight(1f, fill = false).alignByBaseline(),
            )
        }

        Row(
            Modifier.scrubVeil(d, lead = 0.08, drop = 22f, pull = 16f).fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Top,
        ) {
            Column(
                Modifier.weight(1f, fill = false),
                verticalArrangement = Arrangement.spacedBy((size.height * 0.018f).dp),
            ) {
                EdText(2, "โดย มินท์ ชนากานต์", "บรรทัดผู้ทำ", zineMeta(9f))
                EdText(3, "งานออกแบบตัวตนแบรนด์\nสายสตรีทแวร์ที่อบอุ่น", "คำอธิบายซ้าย", zineMeta(7.5f), lines = 3)
            }
            Spacer(Modifier.width(10.dp))
            EdText(
                4, "ครีเอเตอร์\nสายไลฟ์สไตล์", "คำอธิบายขวา", zineMeta(7.5f, TextAlign.End), lines = 3,
                modifier = Modifier.weight(1f, fill = false),
            )
        }
    }
}

/**
 * ตัวอักษรกำกับแบบซีน — ตัวเล็ก ระยะห่างกว้าง
 * (ต้นฉบับใช้ฟอนต์ mono · แอปมีฟอนต์เดียว จึงใช้ระยะห่างเป็นตัวเล่าจังหวะแทน)
 */
private fun zineMeta(s: Float, align: TextAlign = TextAlign.Start): TextSlotStyle =
    TextSlotStyle(size = s, weight = SHFont.semibold, color = Color.White.opacity(0.9), align = align,
        tracking = 1.4f, lineSpacing = 2f, uppercase = false)

/**
 * แถบผลงานสี่ใบพาดกลางหน้า — **การ์ดแยกใบ ไม่ใช่ฟิล์มสตริปแถบเดียว**
 * ช่องไฟกับความสูงที่ไม่เท่ากัน (ใบกลางเป็นกระดาษขาวสูงกว่าเพื่อน) คือสิ่งที่ทำให้อ่านเป็น "กองงานที่ถูกวางเรียง"
 */
@Composable
private fun ZineStrip(size: Size, d: Float) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Row(
            Modifier.wrapContentSize(Alignment.Center, unbounded = true),
            horizontalArrangement = Arrangement.spacedBy((size.width * 0.014f).dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            ZineTile(4, w = 0.215f, h = 0.80f, tilt = -1.5, white = false, size = size, d = d)
            ZineTile(5, w = 0.245f, h = 0.95f, tilt = 1.0, white = false, size = size, d = d)
            ZineTile(6, w = 0.275f, h = 1.0f, tilt = 0.0, white = true, size = size, d = d)
            ZineTile(7, w = 0.235f, h = 0.86f, tilt = -1.0, white = false, size = size, d = d)
        }
    }
}

@Composable
private fun ZineTile(slot: Int, w: Float, h: Float, tilt: Double, white: Boolean, size: Size, d: Float) {
    val lead = (slot - 4) * 0.07
    val r = 7f
    val outer = RoundedCornerShape((if (white) r + 3 else r).dp)
    val shade = Color.Black.opacity(0.32)
    EdPhoto(
        slot, depth = 6f,
        modifier = Modifier
            .scrubLouver(d, lead = lead, angle = 50.0, shrink = 0.12f)
            .graphicsLayer { rotationZ = tilt.toFloat() }
            .shadow(9.dp, outer, clip = false, ambientColor = shade, spotColor = shade)
            .background(if (white) Color.White else Color.Transparent, outer)
            .padding(if (white) 5.dp else 0.dp)
            .size((w * size.width).dp, (h * size.height * 0.26f).dp)
            .clip(RoundedCornerShape(r.dp)),
    )
}

@Composable
private fun ZineFooter(size: Size, d: Float) {
    Column(
        Modifier.fillMaxWidth().wrapContentHeight(Alignment.Bottom, unbounded = true),
        verticalArrangement = Arrangement.spacedBy(4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            EdText(
                5, "salehere.co.th", "บรรทัดล่างซ้าย",
                TextSlotStyle(size = 9f, weight = SHFont.medium, color = Color.White.opacity(0.92)),
                modifier = Modifier.weight(1f, fill = false),
            )
            Spacer(Modifier.width(6.dp))
            EdText(
                6, "ผลงานที่คัดมา", "บรรทัดล่างขวา",
                TextSlotStyle(size = 9f, weight = SHFont.medium, color = Color.White.opacity(0.92),
                    align = TextAlign.End),
                modifier = Modifier.weight(1f, fill = false),
            )
        }
        EdText(
            7, "STAR", "ชื่อย่อตัวใหญ่",
            TextSlotStyle(size = min(46f, size.width * 0.135f), weight = SHFont.black, color = Color.White,
                align = TextAlign.Center, tracking = -1f),
            modifier = Modifier.scrubVeil(d, lead = 0.02, drop = 26f, pull = 10f).fillMaxWidth(),
        )
    }
}

// MARK: - 4 · หน้าแนะนำตัว

/**
 * หัวเรื่องตัวแดงยักษ์สองบรรทัดบนกระดาษครีม · รูปมุมขวา · ย่อหน้าแนะนำตัวใต้หัวเรื่อง
 * เส้นตั้งบาง ๆ สองเส้นยึดหน้าไว้ด้วยกัน — สายตาเดินจากบนลงล่างตามเส้น ไม่ใช่กระโดดหาของที่ใหญ่สุด
 * ย่อหน้าอ่านจากช่อง **แนะนำตัว** ของโปรไฟล์ (`about`) — ใบนี้กับ `แนะนำตัว` จึงสลับกันได้โดยไม่มีข้อความไหนหาย
 */
@Composable
fun AboutEditorial(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val widgetID = LocalWidgetID.current
    val measurer = TextFit.rememberMeasurer()
    val skin = Ed.skin(surface, Ed.creamWarm, cardInk, theme)

    // หัวเรื่องกินเต็มคอลัมน์ซ้าย (63% ของแผ่น) — บรรทัดที่ยาวกว่าเป็นตัวกำหนดขนาดของทั้งคู่
    // ทั้งสองบรรทัดจึงสูงเท่ากันเสมอ เหมือนหัวเรื่องที่ถูกจัดด้วยมือ
    val col = size.width * 0.63f
    val lineA = Profile.me.note(widgetID, 0, preset = "เกี่ยวกับ")
    val lineB = Profile.me.note(widgetID, 1, preset = "ฉัน.")
    val big = min(
        Ed.fitted(measurer, lineA, SHFont.black, width = col, cap = size.height * 0.26f),
        Ed.fitted(measurer, lineB, SHFont.black, width = col, cap = size.height * 0.26f),
    )
    Box(modifier.size(size.width.dp, size.height.dp)) {
        EdSheetLayer(skin)
        if (skin.papered) EdGrain(count = 320, opacity = 0.05, tint = Ed.brown)

        AboutEditorialRules(skin)
        EdPlace(0.055f, 0.055f, 0.66f, 0.44f, size, align = Alignment.TopStart) {
            AboutEditorialTitle(big, skin, scrub.d)
        }
        EdPlace(0.575f, 0.195f, 0.385f, 0.690f, size) {
            EdPhoto(
                1, depth = 10f,
                modifier = Modifier
                    .fillMaxSize()
                    .scrubLouver(scrub.d, lead = 0.1, angle = 40.0, shrink = 0.1f)
                    .shadow(10.dp, RoundedCornerShape(16.dp), clip = false,
                        ambientColor = Ed.brown.opacity(0.18), spotColor = Ed.brown.opacity(0.18))
                    .clip(RoundedCornerShape(16.dp)),
            )
        }
        EdPlace(0.055f, 0.620f, 0.50f, 0.350f, size, align = Alignment.TopStart) {
            AboutEditorialIntro(big, size, skin, scrub.d)
        }
    }
}

/** เส้นตั้งสองเส้น — เส้นบนห้อยจากขอบแผ่นลงมาหยุดที่หัวเรื่อง · เส้นล่างห้อยจากหัวเรื่องลงไปหาย่อหน้า */
@Composable
private fun AboutEditorialRules(skin: EdSkin) {
    val tint = skin.red.opacity(0.9)
    Canvas(Modifier.fillMaxSize()) {
        val line = 1.dp.toPx()
        drawRect(tint, topLeft = Offset(size.width * 0.545f, 0f), size = Size(line, size.height * 0.085f))
        drawRect(tint, topLeft = Offset(size.width * 0.235f, size.height * 0.455f), size = Size(line, size.height * 0.135f))
    }
}

@Composable
private fun AboutEditorialTitle(big: Float, skin: EdSkin, d: Float) {
    Column(
        Modifier
            .wrapContentHeight(Alignment.Top, unbounded = true)
            .scrubVeil(d, lead = 0.22, drop = 38f, pull = 10f),
        horizontalAlignment = Alignment.Start,
    ) {
        EdText(
            0, "เกี่ยวกับ", "หัวเรื่องบรรทัดบน",
            TextSlotStyle(size = big, weight = SHFont.black, color = skin.red, tracking = -big * 0.05f),
        )
        // บรรทัดล่างดึงขึ้นมาชิด (= `VStack(spacing: -big * 0.26)`)
        EdText(
            1, "ฉัน.", "หัวเรื่องบรรทัดล่าง",
            TextSlotStyle(size = big, weight = SHFont.black, color = skin.red, tracking = -big * 0.05f),
            modifier = Modifier.edBleed(top = big * 0.26f, bottom = 0f),
        )
    }
}

@Composable
private fun AboutEditorialIntro(big: Float, size: Size, skin: EdSkin, d: Float) {
    Column(
        Modifier.fillMaxSize().scrubVeil(d, lead = 0.04, drop = 24f, pull = 16f),
        verticalArrangement = Arrangement.spacedBy((size.height * 0.022f).dp),
        horizontalAlignment = Alignment.Start,
    ) {
        EdText(
            2, "ยินดีที่ได้รู้จัก!", "หัวข้อย่อย",
            TextSlotStyle(size = min(17f, big * 0.30f), weight = SHFont.bold, color = skin.ink, tracking = -0.3f),
        )
        EditableParagraph(
            field = ProfileField.about,
            style = TextSlotStyle(size = 8.5f, weight = SHFont.regular, color = skin.ink.opacity(0.85), lineSpacing = 2.8f),
            modifier = Modifier.weight(1f),
        )
    }
}

// MARK: - 5 · บอร์ดรูปติดหมุด

/** รูปเล็กห้าใบรอบรูปใหญ่ (สัดส่วนของแผ่น) */
private data class WallMemoryPin(
    val x: Float, val y: Float, val w: Float, val h: Float,
    val tilt: Double,
    val slot: Int,
)

/** ใบเล็กเบียดเข้าหาใบกลางจนขอบเหลื่อมกัน — บอร์ดรูปคือของที่ถูกติดทับกันไปเรื่อย ๆ ไม่ใช่กริดที่เว้นระยะเท่ากัน */
private val wallMemoryPins = listOf(
    WallMemoryPin(0.040f, 0.225f, 0.215f, 0.205f, -6.0, 4),
    WallMemoryPin(0.020f, 0.500f, 0.225f, 0.215f, 5.0, 5),
    WallMemoryPin(0.755f, 0.215f, 0.215f, 0.210f, 6.0, 6),
    WallMemoryPin(0.745f, 0.480f, 0.230f, 0.220f, -5.0, 7),
    WallMemoryPin(0.615f, 0.680f, 0.225f, 0.205f, 4.0, 8),
)

/**
 * รูปใหญ่กลางบอร์ด · รูปเล็กห้าใบติดหมุดแดงรอบ ๆ · ลายมือคร่อมบนล่าง — รูปสีจริงทั้งบอร์ด
 * ไม่ล้างสี: รูปของครีเอเตอร์คือสิ่งที่เขาเลือกมาอวด · สิ่งที่มัดหกใบเป็นชุดเดียวกันคือ *ของบนบอร์ด*
 * (ขอบกระดาษอัดรูปขาวเท่ากัน · หมุดแดงดวงเดียวกัน · องศาคนละองศา · พื้นกระดาษเดียวกัน)
 */
@Composable
fun WallMemory(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val skin = Ed.skin(surface, Ed.paper, cardInk, theme)
    Box(modifier.size(size.width.dp, size.height.dp)) {
        EdSheetLayer(skin)
        if (skin.papered) EdGrain(count = 340, opacity = 0.05)

        EdPlace(0.13f, 0.055f, 0.74f, 0.10f, size, tilt = -1.2) {
            EdText(
                0, "เป็นครีเอเตอร์ในแบบของคุณ", "ลายมือบรรทัดบน",
                TextSlotStyle(size = min(17f, size.width * 0.05f), weight = SHFont.light, color = skin.ink,
                    align = TextAlign.Center, tracking = 0.4f),
                modifier = Modifier
                    .fillMaxWidth()
                    .wrapContentHeight(Alignment.Top, unbounded = true)
                    .scrubVeil(scrub.d, lead = 0.26, drop = 18f, pull = 10f),
            )
        }

        EdPlace(0.215f, 0.155f, 0.575f, 0.600f, size, tilt = -0.8) { WallMemoryHero(scrub.d) }

        wallMemoryPins.forEachIndexed { i, p ->
            EdPlace(p.x, p.y, p.w, p.h, size, tilt = p.tilt) { WallMemorySnapshot(p, i, scrub.d) }
        }

        EdPlace(0.16f, 0.855f, 0.70f, 0.11f, size, tilt = -3.0) {
            EdText(
                1, "สิ่งที่อยากบอกตัวเองตอนเริ่มต้น", "ลายมือบรรทัดล่าง",
                TextSlotStyle(size = min(14f, size.width * 0.042f), weight = SHFont.light,
                    color = skin.ink.opacity(0.9), align = TextAlign.Center, tracking = 0.3f),
                lines = 2,
                modifier = Modifier
                    .fillMaxWidth()
                    .wrapContentHeight(Alignment.Top, unbounded = true)
                    .scrubVeil(scrub.d, lead = 0.02, drop = 18f, pull = 12f),
            )
        }
    }
}

/** รูปใหญ่กลางบอร์ด — กระดาษอัดรูปขอบหนา ไม่มีหมุด (มันถูก *วาง* ไว้ ส่วนใบเล็กถูก *ติด*) */
@Composable
private fun WallMemoryHero(d: Float) {
    val shade = Color.Black.opacity(0.12)
    Box(
        Modifier
            .fillMaxSize()
            .scrubLouver(d, lead = 0.16, angle = 38.0, shrink = 0.08f)
            .shadow(9.dp, RectangleShape, clip = false, ambientColor = shade, spotColor = shade)
            .background(Color.White)
            .padding(7.dp),
    ) {
        EdPhoto(1, depth = 12f, modifier = Modifier.fillMaxSize())
    }
}

@Composable
private fun WallMemorySnapshot(p: WallMemoryPin, i: Int, d: Float) {
    val lead = Scrub.lead(i, wallMemoryPins.size, d, step = 0.08)
    val shade = Color.Black.opacity(0.14)
    val pinShade = Color.Black.opacity(0.28)
    Box(Modifier.fillMaxSize().scrubLouver(d, lead = lead, angle = 46.0, shrink = 0.12f)) {
        Box(
            Modifier
                .fillMaxSize()
                .shadow(5.dp, RectangleShape, clip = false, ambientColor = shade, spotColor = shade)
                .background(Color.White)
                .padding(4.dp),
        ) {
            EdPhoto(p.slot, depth = 6f, modifier = Modifier.fillMaxSize())
        }
        Box(
            Modifier
                .offset(5.dp, 5.dp)
                .size(8.dp)
                .shadow(1.5.dp, CircleShape, clip = false, ambientColor = pinShade, spotColor = pinShade)
                .background(Ed.pinRed, CircleShape),
        )
    }
}

// MARK: - 6 · ประโยคขายงาน

/**
 * สามบรรทัดชิดซ้าย · บรรทัดสุดท้ายอยู่ในกล่องไฮไลต์ม่วงพร้อมหมุดจับ
 * ฝาแฝดของ `ประโยคไฮไลต์` — ตัวนั้นเน้น *คำ* เดียวตัวยักษ์ ตัวนี้เน้น *ทั้งวลี* ใช้กับประโยคขายงานยาว ๆ ได้
 */
@Composable
fun SayPitch(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    // หมึกของใบนี้เป็นน้ำตาลเข้ม ไม่ใช่ถ่าน — ตอนมีกระดาษจึงใช้ `Ed.brown` แทนหมึกมาตรฐาน
    val skin = Ed.skin(surface, Ed.cream, cardInk, theme).let { if (it.papered) it.copy(ink = Ed.brown) else it }
    val s = min(30f, size.height * 0.185f)
    Box(modifier.size(size.width.dp, size.height.dp)) {
        EdSheetLayer(skin)
        if (skin.papered) EdGrain(count = 260, opacity = 0.05, tint = Ed.brown)

        Column(
            Modifier.fillMaxSize().padding(horizontal = (size.width * 0.075f).dp),
            verticalArrangement = Arrangement.spacedBy((size.height * 0.018f).dp, Alignment.CenterVertically),
            horizontalAlignment = Alignment.Start,
        ) {
            EdText(
                0, "แบรนด์ของคุณ", "บรรทัดที่ 1",
                TextSlotStyle(size = s, weight = SHFont.bold, color = skin.ink, tracking = -0.6f),
                modifier = Modifier.scrubVeil(scrub.d, lead = 0.24, drop = 22f, pull = 10f),
            )
            EdText(
                1, "ควรได้", "บรรทัดที่ 2",
                TextSlotStyle(size = s, weight = SHFont.bold, color = skin.ink, tracking = -0.6f),
                modifier = Modifier.scrubVeil(scrub.d, lead = 0.14, drop = 22f, pull = 12f),
            )
            SayPitchHighlighted(s, size, scrub.d)
        }
    }
}

@Composable
private fun SayPitchHighlighted(s: Float, size: Size, d: Float) {
    Row(
        Modifier
            .scrubVeil(d, lead = 0.04, drop = 26f, pull = 14f)
            .padding(top = (size.height * 0.01f).dp)
            .fillMaxWidth(),
    ) {
        Box(Modifier.weight(1f, fill = false).background(Ed.highlightIris.opacity(0.88))) {
            EdText(
                2, "คอนเทนต์ที่ดีกว่า", "วลีที่เน้น",
                TextSlotStyle(size = s, weight = SHFont.bold, color = rgb(0.169, 0.157, 0.396), tracking = -0.6f),
                // ลบด้วยเหตุผลเดียวกับใบ `ประโยคไฮไลต์` — กล่องฟอนต์ไทยสูงกว่าตัวอักษรมาก
                modifier = Modifier
                    .edBleed(s * 0.06f)
                    .padding(horizontal = (s * 0.13f).dp),
            )
            EdSelectionHandles(Ed.handleIris, dot = 10f, modifier = Modifier.matchParentSize())
        }
    }
}

// MARK: - 7 · การ์ดขั้นตอน

private data class FlowCardStep(
    val x: Float, val y: Float, val w: Float, val h: Float,
    val tilt: Double,
    val label: String,
    val title: String,
    val no: String,
)

private val flowCardSteps = listOf(
    FlowCardStep(0.13f, 0.035f, 0.31f, 0.205f, -4.0, "ยินดีที่ได้รู้จัก", "ทำความรู้จัก", "1"),
    FlowCardStep(0.545f, 0.095f, 0.325f, 0.200f, 3.0, "เริ่มกันเลย", "เปิดโปรเจกต์", "2"),
    FlowCardStep(0.245f, 0.300f, 0.455f, 0.215f, -6.0, "ทุกอย่างเริ่มที่ไอเดีย", "วางคอนเซปต์", "3"),
    FlowCardStep(0.055f, 0.560f, 0.355f, 0.205f, 4.0, "ลงมือสร้าง", "ถ่ายทำ", "4"),
    FlowCardStep(0.585f, 0.575f, 0.345f, 0.205f, -3.0, "ส่งมอบ", "ตัดต่อ & ส่งงาน", "5"),
    FlowCardStep(0.275f, 0.775f, 0.330f, 0.195f, 5.0, "ยังไม่จบแค่นี้", "ดูแลต่อ", "6"),
)

/**
 * การ์ดขาวหกใบวางเฉียงทับกัน · คำกำกับเล็ก ชื่อขั้นตอนตัวใหญ่ และเลขในวงกลมที่ห้อยปลายเส้นจากมุมบนขวา
 * เลขแขวน *นอก* การ์ด — อ่านเป็น "ลำดับของกระบวนการ" ไม่ใช่ "หมายเลขของกล่อง"
 * การ์ดหกใบเป็นกระดาษขาวของมันเอง — ปิดพื้นแล้วหายแค่ *พื้นรอง* ตัวอักษรบนการ์ดจึงเป็นถ่านเสมอ
 */
@Composable
fun FlowCards(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val skin = Ed.skin(surface, Ed.paper, cardInk, theme)
    Box(modifier.size(size.width.dp, size.height.dp)) {
        EdSheetLayer(skin)
        if (skin.papered) EdGrain(count = 280, opacity = 0.04)

        flowCardSteps.forEachIndexed { i, s ->
            EdPlace(s.x, s.y, s.w, s.h, size, tilt = s.tilt) { FlowCard(s, i, size, skin, scrub.d) }
        }
    }
}

@Composable
private fun FlowCard(s: FlowCardStep, i: Int, size: Size, skin: EdSkin, d: Float) {
    val lead = Scrub.lead(i, flowCardSteps.size, d, step = 0.08)
    val big = min(21f, s.w * size.width * 0.17f)
    val shape = RoundedCornerShape(9.dp)
    val shade = Color.Black.opacity(0.10)
    Box(Modifier.fillMaxSize().scrubLouver(d, lead = lead, angle = 42.0, shrink = 0.1f)) {
        Column(
            Modifier
                .fillMaxSize()
                .shadow(6.dp, shape, clip = false, ambientColor = shade, spotColor = shade)
                .background(Color.White, shape)
                .border(0.7.dp, Ed.ink.opacity(0.22), shape)
                .padding(horizontal = 10.dp, vertical = 9.dp),
            verticalArrangement = Arrangement.spacedBy(3.dp),
            horizontalAlignment = Alignment.Start,
        ) {
            EdText(
                i, s.label, "คำกำกับขั้นที่ ${s.no}",
                TextSlotStyle(size = 7f, weight = SHFont.medium, color = Ed.inkSoft),
            )
            EdText(
                6 + i, s.title, "ชื่อขั้นที่ ${s.no}",
                TextSlotStyle(size = big, weight = SHFont.regular, color = Ed.ink, tracking = -0.5f),
            )
        }
        FlowCardBadge(s, i, skin, Modifier.align(Alignment.TopEnd))
    }
}

/** เลขในวงกลมที่ห้อยจากมุมบนขวาด้วยเส้นเฉียงเส้นเดียว */
@Composable
private fun FlowCardBadge(s: FlowCardStep, i: Int, skin: EdSkin, modifier: Modifier) {
    val d = 19f
    Box(
        modifier
            .offset((d * 0.45f).dp, (-d * 0.45f).dp)
            .size(d.dp, 26.dp),
        contentAlignment = Alignment.Center,
    ) {
        // เส้นห้อยอยู่บน *พื้นรอง* ไม่ใช่บนการ์ดขาว — ปิดพื้นแล้วมันต้องพลิกตามหมึกของการ์ด
        Box(
            Modifier
                .offset((-9).dp, 9.dp)
                .graphicsLayer { rotationZ = 38f }
                .size(0.7.dp, 26.dp)
                .background(skin.ink.opacity(0.45)),
        )
        Box(Modifier.size(d.dp).background(Ed.stepPink, CircleShape), contentAlignment = Alignment.Center) {
            EdText(
                12 + i, s.no, "เลขขั้นที่ ${s.no}",
                TextSlotStyle(size = 9f, weight = SHFont.semibold, color = Ed.ink, align = TextAlign.Center),
            )
        }
    }
}

// MARK: - 8 · ชื่อหลังภาพ

/**
 * คำยักษ์พาดเต็มความกว้าง โดยมีภาพตัดขาวดำยืนทับอยู่ข้างหน้า · บรรทัดกำกับด้านบน · ย่อหน้าแนะนำตัวข้างภาพ
 * ความลึกมาจากการทับ ไม่ใช่จากเงา — ใส่เงาเพิ่มมันจะอ่านเป็นสติกเกอร์ที่แปะทับ
 * คำยักษ์เป็นสีขาวบนเบจ — พอปิดพื้น มันต้องกลายเป็น "เงาของหมึกการ์ด" ไม่งั้นหายไปทั้งคำ
 */
@Composable
fun AboutBehind(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val widgetID = LocalWidgetID.current
    val measurer = TextFit.rememberMeasurer()
    val skin = Ed.skin(surface, Ed.beige, cardInk, theme)

    // คำยักษ์ **กินเต็มความกว้างแผ่นเสมอ** — คำสั้นที่ขนาดตายตัวจะซ่อนอยู่หลังภาพจนหมด
    val word = Profile.me.note(widgetID, 1, preset = "รู้จักฉัน")
    val big = Ed.fitted(measurer, word, SHFont.black, width = size.width * 0.92f, cap = size.height * 0.30f)
    Box(modifier.size(size.width.dp, size.height.dp)) {
        EdSheetLayer(skin)
        if (skin.papered) EdGrain(count = 320, opacity = 0.05, tint = Ed.brown)

        EdPlace(0.08f, 0.045f, 0.84f, 0.055f, size) {
            EdText(
                0, "หลงใหลการเล่าเรื่อง ภาพ และงานคราฟต์", "บรรทัดบนสุด",
                TextSlotStyle(size = 7f, weight = SHFont.semibold, color = skin.inkSoft,
                    align = TextAlign.Center, tracking = 1.8f),
                modifier = Modifier
                    .fillMaxWidth()
                    .wrapContentHeight(Alignment.Top, unbounded = true)
                    .scrubVeil(scrub.d, lead = 0.28, drop = 14f, pull = 8f),
            )
        }

        EdPlace(0.04f, 0.115f, 0.92f, 0.24f, size) {
            EdText(
                1, "รู้จักฉัน", "คำยักษ์",
                TextSlotStyle(size = big, weight = SHFont.black, color = skin.ghost,
                    align = TextAlign.Center, tracking = -big * 0.02f),
                modifier = Modifier
                    .fillMaxWidth()
                    .wrapContentHeight(Alignment.Top, unbounded = true)
                    .scrubVeil(scrub.d, lead = 0.18, drop = 30f, pull = 10f),
            )
        }

        // ภาพตัด — ไม่มีกรอบ ไม่มีเงา ชนก้นแผ่นเหมือนคนยืนอยู่บนพื้น
        EdPlace(0.185f, 0.185f, 0.370f, 0.815f, size, align = Alignment.BottomCenter) {
            EdPhoto(
                1, mono = true, depth = 8f,
                modifier = Modifier
                    .fillMaxSize()
                    .scrubLouver(scrub.d, lead = 0.1, angle = 34.0, shrink = 0.08f, flat = true),
            )
        }
        EdPlace(0.575f, 0.395f, 0.385f, 0.545f, size, align = Alignment.TopStart) {
            AboutBehindBlurb(skin, scrub.d)
        }
    }
}

@Composable
private fun AboutBehindBlurb(skin: EdSkin, d: Float) {
    Column(
        Modifier.fillMaxSize().scrubVeil(d, lead = 0.02, drop = 22f, pull = 14f),
        verticalArrangement = Arrangement.spacedBy(5.dp),
        horizontalAlignment = Alignment.Start,
    ) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            EdText(
                2, "รู้จักฉัน —", "หัวย่อหน้า",
                TextSlotStyle(size = 9f, weight = SHFont.bold, color = skin.ink),
            )
            EditableText(
                field = ProfileField.personName,
                style = TextSlotStyle(size = 9f, weight = SHFont.bold, color = skin.ink),
                autoSizeMin = 0.7f,
                modifier = Modifier.weight(1f, fill = false),
            )
        }
        EditableParagraph(
            field = ProfileField.about,
            style = TextSlotStyle(size = 8f, weight = SHFont.regular, color = skin.ink.opacity(0.88), lineSpacing = 2.4f),
            modifier = Modifier.weight(1f),
        )
    }
}
