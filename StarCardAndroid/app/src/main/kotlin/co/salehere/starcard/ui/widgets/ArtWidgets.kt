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
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
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
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.layout
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.offset
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.ScrubDigits
import co.salehere.starcard.components.ScrubRunner
import co.salehere.starcard.components.redacted
import co.salehere.starcard.components.scrubAperture
import co.salehere.starcard.components.scrubDolly
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.BrandIcon
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.ProvenanceTag
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.StarSeal
import co.salehere.starcard.theme.SymbolIcon
import co.salehere.starcard.theme.Tinted
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.onLightSurface
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalGhostData
import co.salehere.starcard.ui.LocalSlotTilt
import co.salehere.starcard.ui.editor.EditableParagraph
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import co.salehere.starcard.ui.editor.dataValue
import co.salehere.starcard.ui.editor.editableSlot
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

// (= Views/Widgets/ArtWidgets.swift)
// widget ชุดนี้วาดพื้นหลังเอง ไม่ใช้กรอบกระจกกลาง (`WidgetKind.drawsOwnSurface`)
// เพื่อให้การ์ดไม่กลายเป็นตารางสี่เหลี่ยมมนเรียงกันทั้งหน้า

// MARK: - ภาพเต็มแบบนิตยสาร ชื่อล้นออกนอกกรอบภาพ

/**
 * # ท่าเปลี่ยนหน้า — "สามระนาบในกล่องเดียว"
 *
 * รูป · คำผี · ชื่อ เดินคนละอัตรา: รูปถ่วงตัวช้าที่สุด · คำผีวิ่งสวนทางเร็วที่สุด · ชื่อกับสายงานมุดใต้ขอบตัวเอง
 * ตาอ่านความลึกจาก **ความต่างของอัตรา** ไม่ใช่จากเงาหรือความจาง
 */
@Composable
fun ArtPortrait(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val shape = RoundedCornerShape(22.dp)
    val ghost = min(66f, size.height * 0.26f)

    // เทรนด์ 2026 · Kinetic Typography — ตัวอักษรเป็นโครงสร้างของหน้า ไม่ใช่คำบรรยายใต้ภาพ
    Box(modifier.fillMaxSize().clip(shape)) {
        Box(Modifier.fillMaxSize().photoSlot(1)) {
            WidgetPhoto(1, Modifier.fillMaxSize().scrubDolly(scrub.d, shift = size.width * 0.06f, zoom = 0.16f))
        }

        // ม่านมืดหนาขึ้นช่วงท้าย — ของเดินเข้าเงาข้างเวทีก่อนออกจากฉาก
        val t = Scrub.ease(Scrub.t(scrub.d))
        Box(
            Modifier.fillMaxSize().drawBehind {
                drawRect(
                    Brush.verticalGradient(
                        listOf(
                            Color.Transparent,
                            Color.Black.opacity(0.2 + 0.25 * t),
                            Color.Black.opacity(0.86 + 0.14 * t),
                        ),
                        startY = this.size.height * (0.5f - 0.3f * t),
                        endY = this.size.height,
                    ),
                )
            },
        )

        Column(Modifier.align(Alignment.BottomStart).fillMaxWidth().padding(18.dp)) {
            Text(
                "STARCARD",
                style = sh(ghost, SHFont.black).copy(letterSpacing = (-ghost * 0.055f).sp),
                color = Color.White.opacity(0.13),
                maxLines = 1,
                softWrap = false,
                modifier = Modifier
                    // วิ่งสวนทางรูป — ชั้นที่ใกล้ตาที่สุดต้องเคลื่อนเร็วที่สุด
                    .scrubSlide(scrub.d, travel = -size.width * 0.34f, fade = 0.75, eased = false)
                    .offset(x = (-ghost * 0.06f).dp)
                    .wrapContentWidth(Alignment.Start, unbounded = true),
            )

            // ชื่อคือสมอ — หายทีหลังสุด กลับมาก่อนใคร
            // ดึงขึ้นชนคำผี **หลัง** veil — ถ้าดึงก่อน กรอบของ veil เตี้ยลงแล้วตัดหัวสระบน/วรรณยุกต์ไทยทิ้ง
            Row(
                Modifier
                    .topPull(ghost * 0.26f)
                    .scrubVeil(scrub.d, lead = 0.22, drop = 38f, pull = 10f)
                    .fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                EditableText(
                    field = ProfileField.personName,
                    style = TextSlotStyle(
                        size = min(34f, size.height * 0.145f), weight = SHFont.bold,
                        color = Color.White, tracking = -0.6f,
                    ),
                    modifier = Modifier.weight(1f, fill = false),
                )
                if (Profile.me.creator.verified) StarSeal(size = 12f)
            }

            Row(
                Modifier
                    .scrubVeil(scrub.d, lead = 0.05, drop = 24f, pull = 22f)
                    .padding(top = 9.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                // สีเน้นดิบ — ขีดนี้อยู่บนรูป ไม่ใช่บนพื้นการ์ด
                Box(Modifier.size(16.dp, 2.dp).background(theme.rawAccent, CircleShape))
                EditableText(
                    field = ProfileField.tagline,
                    style = TextSlotStyle(
                        size = 9f, weight = SHFont.semibold, color = Color.White.opacity(0.72),
                        tracking = 2.2f, uppercase = true,
                    ),
                    modifier = Modifier.weight(1f, fill = false),
                )
            }
        }
    }
}

/** `.padding(.top, -x)` — กรอบเตี้ยลง x แล้วของข้างในเลื่อนขึ้น x (ดึงบรรทัดขึ้นชนบรรทัดบน) */
private fun Modifier.topPull(pt: Float): Modifier = layout { measurable, constraints ->
    val px = pt.dp.roundToPx()
    val placeable = measurable.measure(constraints.offset(vertical = px))
    layout(placeable.width, max(0, placeable.height - px)) {
        placeable.place(0, -px)
    }
}

// MARK: - โพลารอยด์

/** กระดาษฟิล์ม — อุ่นกว่าขาวโรงพิมพ์นิดหนึ่ง ขาวสนิทอ่านเป็นพลาสติก ไม่ใช่ฟิล์ม */
private val polaroidPaper = rgb(0.97, 0.965, 0.95)
private val polaroidPaperEdge = rgb(0.91, 0.90, 0.88)
private val polaroidInk = rgb(0.13, 0.12, 0.15)

/**
 * ฟิล์มสำเร็จรูปหนึ่งใบ — ไม่ใช่ "กรอบสี่เหลี่ยมที่มีรูปอยู่ข้างใน"
 * การ์ดกินพื้นที่ทั้ง widget เสมอ · รูปยืดตามที่เหลือ · คางหนาตามสัดส่วนของใบ · เงานุ่มจริงพร้อมองศาเอียงเล็กน้อย
 *
 * # ท่าเปลี่ยนหน้า — "ภาพยังไม่ขึ้น"
 * ตอนหน้าเดินจากไป **สีถูกถอนออกจากภาพ** จนเหลือแผ่นฟิล์มขาวนวล ปัดกลับมามันก็ **ขึ้นภาพ** ให้ดูใหม่ทุกครั้ง
 */
@Composable
fun ArtPolaroid(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    // เว้นที่ให้เงาและองศาเอียง — ไม่เว้นแล้วมุมการ์ดจะโดนขอบ widget ตัด
    BoxWithConstraints(modifier.fillMaxSize().padding(horizontal = 8.dp, vertical = 7.dp)) {
        val box = Size(maxWidth.value, maxHeight.value)
        val t = Scrub.ease(Scrub.t(scrub.d))
        val s = Scrub.dir(scrub.d)
        PolaroidCard(
            theme, box, t, scrub.d,
            // เอียงตั้งต้นเล็กน้อยแล้วเอียงเพิ่มตามนิ้ว — ของที่วางบนโต๊ะไม่มีทางตรงเป๊ะ
            Modifier.graphicsLayer {
                rotationZ = -1.8f + s * 4.5f * t
                scaleX = 1f - 0.05f * t
                scaleY = 1f - 0.05f * t
                translationY = -8f * t * density
                alpha = Scrub.fade(t, 0.82).toFloat()
            },
        )
    }
}

@Composable
private fun PolaroidCard(theme: CardTheme, size: Size, t: Float, d: Float, modifier: Modifier) {
    // คางหนาตามสัดส่วนของใบ แต่มีเพดานทั้งสองทาง — ใบเตี้ยคางต้องไม่กินรูป ใบสูงคางต้องไม่ยืดจนเป็นแผ่นเปล่า
    val chin = min(64f, max(34f, size.height * 0.19f))
    val rim = max(7f, size.width * 0.045f)
    val shape = RoundedCornerShape(3.dp)
    val far = Color.Black.opacity(0.45)
    val near = Color.Black.opacity(0.2)
    Column(
        modifier
            .size(size.width.dp, size.height.dp)
            // เงานุ่มจริง ไม่ใช่บล็อกสี — ฟิล์มใบหนึ่งวางอยู่บนการ์ด ไม่ได้ถูกพิมพ์ลงไป
            .shadow(16.dp, shape, clip = false, ambientColor = far, spotColor = far)
            .shadow(3.dp, shape, clip = false, ambientColor = near, spotColor = near)
            .clip(shape)
            .background(Brush.linearGradient(listOf(polaroidPaper, polaroidPaperEdge), start = Offset.Zero, end = Offset.Infinite)),
    ) {
        PolaroidWindow(
            t, d,
            Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(start = rim.dp, end = rim.dp, top = rim.dp),
        )
        PolaroidChin(theme, chin, rim, d)
    }
}

/** ช่องฟิล์ม — ยืดเต็มที่ที่เหลือเสมอ ไม่ล็อกสัดส่วน */
@Composable
private fun PolaroidWindow(t: Float, d: Float, modifier: Modifier) {
    Box(
        modifier
            .photoSlot(2)
            // ช่องฟิล์มจมลงไปในกระดาษเล็กน้อย — เส้นเข้มบาง ๆ รอบช่องคือสิ่งที่บอกความลึกนั้น
            .border(0.8.dp, polaroidInk.opacity(0.16))
            .clipToBounds(),
    ) {
        // ถอนสีออกจนเหลือฟิล์มเปล่า — ความอิ่มสีกับคอนทราสต์ต้องเดินพร้อมกัน ไม่งั้นอ่านเป็น "ฟิลเตอร์ขาวดำ"
        WidgetPhoto(2, Modifier.fillMaxSize().filmUndeveloped(t).scrubDolly(d, shift = 14f, zoom = 0.18f))
        Box(Modifier.fillMaxSize().background(grey(0.94).opacity(0.72 * t)))
        // ประกายพลาสติกบนผิวฟิล์ม — เส้นเดียวพาดเฉียง อ่อนมากจนเห็นเฉพาะตอนตาไล่ผ่าน
        Box(
            Modifier.fillMaxSize().background(
                Brush.linearGradient(
                    0f to Color.White.opacity(0.14),
                    0.42f to Color.Transparent,
                    1f to Color.Transparent,
                    start = Offset.Zero,
                    end = Offset.Infinite,
                ),
            ),
        )
    }
}

/** คาง — ที่สำหรับ "ลายมือ" ของเจ้าของรูป */
@Composable
private fun PolaroidChin(theme: CardTheme, height: Float, rim: Float, d: Float) {
    Box(
        Modifier
            .scrubVeil(d, lead = 0.24, drop = 26f, pull = 8f)
            .fillMaxWidth()
            .height(height.dp)
            .padding(horizontal = rim.dp),
        contentAlignment = Alignment.CenterStart,
    ) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.Bottom,
        ) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
                    // น้ำหนักกลาง ตัวใหญ่กว่าแคปชัน — คนเขียนชื่อลงบนคางด้วยลายมือ ไม่ได้พิมพ์ฉลาก
                    EditableText(
                        field = ProfileField.personName,
                        style = TextSlotStyle(
                            size = min(15f, height * 0.34f), weight = SHFont.medium,
                            color = polaroidInk.opacity(0.9), tracking = 0.2f,
                        ),
                        modifier = Modifier.weight(1f, fill = false),
                    )
                    if (Profile.me.creator.verified) {
                        StarSeal(size = min(11f, height * 0.25f), tint = polaroidInk.opacity(0.9), punch = grey(0.97))
                    }
                }
                EditableText(
                    field = ProfileField.tagline,
                    style = TextSlotStyle(
                        size = min(9.5f, height * 0.22f), weight = SHFont.medium,
                        color = theme.rawAccent.onLightSurface(depth = 0.9),
                    ),
                )
            }
            SymbolIcon(SHIcon.star, size = min(13f, height * 0.3f), tint = polaroidInk.opacity(0.28))
        }
    }
}

/**
 * ภาพยังไม่ขึ้น (= `.saturation(1 − 0.95t).contrast(1 − 0.35t)`) — วาดทั้งชั้นผ่านเมทริกซ์สีเดียว
 * ความอิ่มสีก่อน แล้วคอนทราสต์รอบเทากลาง (ลำดับเดียวกับ SwiftUI)
 */
private fun Modifier.filmUndeveloped(t: Float): Modifier {
    if (t <= 0f) return this
    val sat = 1f - 0.95f * t
    val c = 1f - 0.35f * t
    val inv = 1f - sat
    val r = 0.213f * inv
    val g = 0.715f * inv
    val b = 0.072f * inv
    val off = 127.5f * (1f - c)
    val matrix = ColorMatrix(
        floatArrayOf(
            (r + sat) * c, g * c, b * c, 0f, off,
            r * c, (g + sat) * c, b * c, 0f, off,
            r * c, g * c, (b + sat) * c, 0f, off,
            0f, 0f, 0f, 1f, 0f,
        ),
    )
    val paint = Paint().apply { colorFilter = ColorFilter.colorMatrix(matrix) }
    return drawWithContent {
        drawIntoCanvas { canvas ->
            canvas.saveLayer(Rect(0f, 0f, size.width, size.height), paint)
            drawContent()
            canvas.restore()
        }
    }
}

// MARK: - เซลล์รูปมาตรฐานของกลุ่มผลงาน

/**
 * กระเบื้องรูปหนึ่งใบในผัง bento — มุมมน ขอบเส้นผม ไม่มีเงา ไม่เอียง
 * ความลึกของแต่ละช่องคุมด้วย `depth` (สัดส่วนของความกว้างช่องที่ภาพข้างในถ่วงตัวสวนทางหน้า)
 */
@Composable
private fun BentoCell(
    index: Int,
    radius: Float = 16f,
    d: Float = 0f,
    width: Float = 100f,
    depth: Float = 0f,
    modifier: Modifier = Modifier,
) {
    val ink = LocalCardInk.current
    val shape = RoundedCornerShape(radius.dp)
    Box(
        modifier
            .photoSlot(index)
            .border(0.6.dp, ink.line(0.12), shape)
            .clip(shape),
    ) {
        // zoom ต้องคุ้ม shift (≥ 2 × depth) ไม่งั้นเห็นขอบว่างที่ริมภาพ
        WidgetPhoto(index, Modifier.fillMaxSize().scrubDolly(d, shift = width * depth, zoom = max(0.12f, depth * 2.4f)))
    }
}

// MARK: - แถบภาพ

/**
 * คอนแทกต์ชีตแนวนอน — สี่ช่องสัดส่วนพอร์เทรตเท่ากัน
 *
 * # ท่าเปลี่ยนหน้า — "ฟิล์มเดินผ่านช่องกล้อง"
 * แถบทั้งแถบเลื่อนไปหนึ่งเฟรมพอดีตามทิศนิ้ว ขณะที่หน้าต่างของแต่ละเฟรมหุบไล่กัน
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun ArtFilmstrip(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    BoxWithConstraints(modifier.fillMaxSize().clipToBounds()) {
        val n = 4
        val gap = 7f
        val fullW = maxWidth.value
        val fullH = maxHeight.value
        val w = max(0f, (fullW - gap * (n - 1)) / n)
        Row(
            Modifier
                .size(fullW.dp, fullH.dp)
                // เดินหนึ่งเฟรมพอดี — ระยะต้องเท่าช่อง+ร่อง ไม่งั้นอ่านเป็น "ไถล" ไม่ใช่ "เดินเฟรม"
                .scrubSlide(scrub.d, travel = w + gap, fade = 0.85),
            horizontalArrangement = Arrangement.spacedBy(gap.dp),
        ) {
            for (i in 0 until n) {
                BentoCell(
                    index = i + 6, radius = 13f, d = scrub.d, width = w, depth = 0.085f,
                    modifier = Modifier
                        .size(w.dp, fullH.dp)
                        .scrubAperture(scrub.d, lead = Scrub.lead(i, n, scrub.d, 0.1), feather = 0.22f, dim = 0.5),
                )
            }
        }
    }
}

// MARK: - คู่แนวตั้ง

/**
 * สองรูปแนวตั้งเคียงกัน — ช่องเท่ากันเป๊ะ ไม่มีช่องไหนเด่นกว่าช่องไหน
 * งานส่วนใหญ่ที่ครีเอเตอร์อยากโชว์คือ **สองชิ้นที่ดีที่สุด** และคลิปแนวตั้งคือสัดส่วนจริงของงาน
 *
 * # ท่าเปลี่ยนหน้า — "สองบานหุบสวนกัน"
 * หน้าต่างสองบานหุบไล่กันตามทิศนิ้ว และภาพข้างในถ่วงตัว **คนละทาง**
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun ArtPair(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    // [4, 6] ไม่ใช่ [4, 5] — slot 5 ตกรูปใบเดียวกับ workReel (index 8) วางคู่กันแล้วรูปจะซ้ำติดกัน
    val slots = listOf(4, 6)
    BoxWithConstraints(modifier.fillMaxSize()) {
        val gap = 8f
        val w = max(0f, (maxWidth.value - gap) / 2f)
        val h = maxHeight.value
        Row(horizontalArrangement = Arrangement.spacedBy(gap.dp)) {
            slots.forEachIndexed { i, slot ->
                PairCell(slot, i, slots.size, w, h, scrub.d)
            }
        }
    }
}

@Composable
private fun PairCell(slot: Int, i: Int, count: Int, w: Float, h: Float, d: Float) {
    val shape = RoundedCornerShape(16.dp)
    // ใบซ้ายถ่วงไปทางหนึ่ง ใบขวาถ่วงกลับ — เท่ากันทั้งคู่จะอ่านเป็นภาพเดียวที่ถูกเลื่อน
    val drift = if (i == 0) 0.09f else -0.09f
    Box(
        Modifier
            .size(w.dp, h.dp)
            .scrubAperture(d, lead = Scrub.lead(i, count, d, 0.12), feather = 0.22f, dim = 0.5)
            .photoSlot(slot)
            .border(0.7.dp, Color.White.opacity(0.14), shape)
            .clip(shape),
    ) {
        WidgetPhoto(slot, Modifier.fillMaxSize().scrubDolly(d, shift = w * drift, zoom = 0.24f))
    }
}

// MARK: - เบนโตะ

/**
 * ผังเบนโตะ — ช่องสูงหนึ่งช่อง + ช่องกว้างหนึ่งช่อง + ช่องเล็กสองช่อง
 *
 * # ท่าเปลี่ยนหน้า — "ความลึกผูกกับขนาดช่อง"
 * ช่องใหญ่ถ่วงตัวน้อยและหุบทีหลัง (ของไกล ใหญ่ หนัก) · ช่องเล็กถ่วงมากและหุบก่อน (ของใกล้ เบา)
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun ArtDuo(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    BoxWithConstraints(modifier.fillMaxSize()) {
        val gap = 8f
        val w = maxWidth.value
        val h = maxHeight.value
        val leftW = max(0f, (w - gap) * 0.56f)
        val rightW = max(0f, w - gap - leftW)
        val topH = max(0f, (h - gap) * 0.58f)
        val botH = max(0f, h - gap - topH)
        val smallW = max(0f, (rightW - gap) / 2f)

        Row(horizontalArrangement = Arrangement.spacedBy(gap.dp)) {
            BentoCell(
                index = 7, radius = 20f, d = scrub.d, width = leftW, depth = 0.05f,
                modifier = Modifier
                    .size(leftW.dp, h.dp)
                    .scrubAperture(scrub.d, lead = Scrub.lead(0, 4, scrub.d, 0.11), feather = 0.2f, dim = 0.55),
            )
            Column(verticalArrangement = Arrangement.spacedBy(gap.dp)) {
                BentoCell(
                    index = 8, radius = 18f, d = scrub.d, width = rightW, depth = 0.09f,
                    modifier = Modifier
                        .size(rightW.dp, topH.dp)
                        .scrubAperture(scrub.d, lead = Scrub.lead(1, 4, scrub.d, 0.11), feather = 0.2f, dim = 0.55),
                )
                Row(horizontalArrangement = Arrangement.spacedBy(gap.dp)) {
                    BentoCell(
                        index = 9, radius = 14f, d = scrub.d, width = smallW, depth = 0.14f,
                        modifier = Modifier
                            .size(smallW.dp, botH.dp)
                            .scrubAperture(scrub.d, lead = Scrub.lead(2, 4, scrub.d, 0.11), feather = 0.24f, dim = 0.55),
                    )
                    BentoCell(
                        index = 10, radius = 14f, d = scrub.d, width = smallW, depth = 0.14f,
                        modifier = Modifier
                            .size(smallW.dp, botH.dp)
                            .scrubAperture(scrub.d, lead = Scrub.lead(3, 4, scrub.d, 0.11), feather = 0.24f, dim = 0.55),
                    )
                }
            }
        }
    }
}

// MARK: - แถบวิ่ง

/**
 * # ท่าเปลี่ยนหน้า — "กรอตามนิ้ว"
 *
 * ของที่วิ่งอยู่แล้วตามเวลา พอโดนนิ้วลากจะ **เร่งไปข้างหน้า** ลากกลับก็ **กรอถอย**
 * ปล่อยแล้วสปริงพากลับเข้าจังหวะเดิม · เฉพาะชื่อแบรนด์ — แถบนี้อยู่ตระกูล `brand`
 */
@Composable
fun TypeMarquee(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val density = LocalDensity.current.density
    /** ความกว้างของเนื้อหาหนึ่งชุด — วัดจากของจริง ไม่เดาเป็นค่าคงที่ */
    var runW by remember { mutableStateOf(1f) }
    val words = Profile.me.creator.track.brands.map { it.name }

    Box(
        modifier
            .fillMaxSize()
            .padding(vertical = 3.dp)
            .graphicsLayer { rotationZ = -0.8f },
    ) {
        // ชุดวัดขนาด — ซ่อนไว้แต่ยังถูกจัดวางจริง จึงได้ความกว้างที่ตรงกับของที่วาด
        MarqueeRow(
            words, ink, theme,
            Modifier
                .align(Alignment.CenterStart)
                .wrapContentWidth(Alignment.Start, unbounded = true)
                .alpha(0f)
                .onSizeChanged { px ->
                    val w = px.width / density
                    if (w > 1f) runW = w
                },
        )
        // รางวิ่งไม่นับขนาดของตัวเองเข้าไปในกล่อง — กล่องเท่า widget แล้วตัดขอบ
        Box(
            Modifier
                .matchParentSize()
                .background(theme.accent.opacity(0.1))
                .clipToBounds(),
            contentAlignment = Alignment.CenterStart,
        ) {
            ScrubRunner(
                d = scrub.d, runWidth = runW, period = 16.0, pull = 0.42,
                active = abs(scrub.d) < 1.05f, copies = 3,
                modifier = Modifier.wrapContentWidth(Alignment.Start, unbounded = true),
            ) {
                MarqueeRow(words, ink, theme)
            }
        }
        Box(Modifier.align(Alignment.TopStart).fillMaxWidth().height(0.5.dp).background(ink.line(0.12)))
        Box(Modifier.align(Alignment.BottomStart).fillMaxWidth().height(0.5.dp).background(ink.line(0.12)))
    }
}

/** หนึ่งชุดของแถบวิ่ง — ระยะคั่นท้ายชุดกันชุดถัดไปติดกันจนอ่านเป็นคำเดียว */
@Composable
private fun MarqueeRow(words: List<String>, ink: InkStyle, theme: CardTheme, modifier: Modifier = Modifier) {
    Row(
        modifier.padding(end = 22.dp),
        horizontalArrangement = Arrangement.spacedBy(22.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        words.forEach { w ->
            Text(w.uppercase(), style = sh(15f, SHFont.bold), color = ink.text(0.9), maxLines = 1, softWrap = false)
            AsteriskMark(side = 9f, tint = theme.accent)
        }
    }
}

/** ดอกจันคั่นชื่อแบรนด์ (= `Image(systemName: "asterisk")` ที่ `.sh(9, .black)`) — หกแฉกเส้นหนาปลายมน */
@Composable
private fun AsteriskMark(side: Float, tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier.size(side.dp)) {
        val c = center
        val r = this.size.minDimension * 0.42f
        val stroke = this.size.minDimension * 0.19f
        for (k in 0 until 3) {
            val a = PI / 2 + k * PI / 3
            val dx = (cos(a) * r).toFloat()
            val dy = (sin(a) * r).toFloat()
            drawLine(tint, Offset(c.x - dx, c.y - dy), Offset(c.x + dx, c.y + dy), strokeWidth = stroke, cap = StrokeCap.Round)
        }
    }
}

// MARK: - คำพูดตัวใหญ่

/**
 * # ท่าเปลี่ยนหน้า — "แสงกวาด"
 *
 * ตัวหนังสือไม่ได้ถูกดันออกไป แต่ **ขอบแสงเดินผ่านมันไป** ตามทิศนิ้ว
 * อ่านออกมาเป็นสปอตไลต์ที่กวาดข้ามเวที ไม่ใช่สไลด์ที่ถูกเปลี่ยน
 */
@Composable
fun TypeQuote(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val shape = RoundedCornerShape(22.dp)
    val t = Scrub.ease(Scrub.t(scrub.d))
    val s = Scrub.dir(scrub.d)
    // ขอบแสงเริ่มที่ตำแหน่งเดิมเสมอตอน t = 0 (ทั้งสองทิศ) แล้วเดินออกไปตามทิศ
    val head = 0.86f - s * 1.55f * t
    val dim = 0.5 * (max(0f, t - 0.6f) / 0.4f)

    Box(modifier.fillMaxSize(), contentAlignment = Alignment.CenterStart) {
        Box(Modifier.fillMaxSize().photoSlot(1).clip(shape)) {
            WidgetPhoto(1, Modifier.fillMaxSize().scrubDolly(scrub.d, shift = size.width * 0.06f, zoom = 0.16f))
            Box(
                Modifier.fillMaxSize().background(
                    Brush.horizontalGradient(
                        0f to Color.Black.opacity(0.84),
                        (head - 0.34f).coerceIn(0f, 1f) to Color.Black.opacity(0.84),
                        (head + 0.34f).coerceIn(0f, 1f) to Color.Black.opacity(0.12),
                        1f to Color.Black.opacity(0.12),
                    ),
                ),
            )
            if (dim > 0.0) Box(Modifier.fillMaxSize().background(Color.Black.opacity(dim)))
        }

        Column(
            Modifier
                .fillMaxHeight()
                .widthIn(max = (size.width * 0.68f).dp)
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            QuoteMark(side = 22f, tint = theme.rawAccent, modifier = Modifier.scrubVeil(scrub.d, lead = 0.02, drop = 22f, pull = 20f))
            // คำพูดกินความสูงที่เหลือแล้วตัดท้ายด้วย … — กรอบเป็นคนบอกว่าอ่านได้กี่บรรทัด
            EditableParagraph(
                field = ProfileField.quote,
                style = TextSlotStyle(
                    size = min(24f, size.width * 0.072f), weight = SHFont.semibold,
                    color = Color.White, lineSpacing = 5f,
                ),
                modifier = Modifier
                    .weight(1f)
                    .scrubVeil(scrub.d, lead = 0.14, drop = 40f, pull = 12f),
            )
            // ขีดนำหน้าเป็นเครื่องหมายอ้างคำพูด ไม่ใช่ส่วนหนึ่งของชื่อ — แยกออกจากช่องที่แก้ได้
            Row(
                Modifier.scrubVeil(scrub.d, lead = 0.3, drop = 22f, pull = 6f),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("—", style = sh(10.5f, SHFont.medium), color = theme.rawAccent, maxLines = 1, softWrap = false)
                EditableText(
                    field = ProfileField.personName,
                    style = TextSlotStyle(size = 10.5f, weight = SHFont.medium, color = theme.rawAccent, tracking = 1.2f),
                    modifier = Modifier.weight(1f, fill = false),
                )
            }
        }
    }
}

/** เครื่องหมายเปิดคำพูด (= `Image(systemName: "quote.opening")` ที่ 22pt) — หัวกลมสองหัว หางชี้ขึ้นขวา */
@Composable
private fun QuoteMark(side: Float, tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier.size((side * 0.9f).dp, (side * 0.7f).dp)) {
        val fw = this.size.width
        val fh = this.size.height
        val mw = fw * 0.44f
        val r = mw / 2f
        for (x0 in floatArrayOf(0f, fw - mw)) {
            val tail = Path().apply {
                moveTo(x0, fh - r)
                cubicTo(x0, fh * 0.38f, x0 + mw * 0.30f, fh * 0.08f, x0 + mw * 0.92f, 0f)
                lineTo(x0 + mw, fh * 0.14f)
                cubicTo(x0 + mw * 0.56f, fh * 0.24f, x0 + mw * 0.42f, fh * 0.40f, x0 + mw * 0.52f, fh - 2f * r + r * 0.15f)
                close()
            }
            drawPath(tail, tint)
            drawCircle(tint, radius = r, center = Offset(x0 + r, fh - r))
        }
    }
}

// MARK: - ตัวเลขยักษ์ ไม่มีกรอบ

/**
 * # ท่าเปลี่ยนหน้า — "มิเตอร์"
 *
 * ตัวเลขคือหลักฐาน มันไม่ควรจางหายแบบข้อความ — มันถูก **ถอดออกทีละหลัก** จากฝั่งที่หน้ากำลังไป
 * แล้วประกอบกลับตามลำดับตรงข้ามตอนปัดกลับ
 */
@Composable
fun StatGiant(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val shape = RoundedCornerShape(22.dp)
    val fs = min(58f, size.width * 0.235f)
    val socials = Profile.me.creator.socials
    val total = socials.sumOf { it.followerCount }
    val t = Scrub.ease(Scrub.t(scrub.d))
    // ขอบแสงของกระจก — สูตรเดียวกับ `GlassPanel`
    val rim = Brush.linearGradient(
        0f to Color.White.opacity(0.35),
        0.6f to Color.White.opacity(0.0),
        start = Offset.Zero,
        end = Offset.Infinite,
    )

    Box(modifier.fillMaxSize()) {
        // ตัวเลขวางบนภาพผลงานจริง น่าเชื่อกว่าลอยอยู่บนพื้นเปล่า
        Box(Modifier.fillMaxSize().photoSlot(3).clip(shape)) {
            WidgetPhoto(3, Modifier.fillMaxSize().scrubDolly(scrub.d, shift = size.width * 0.055f, zoom = 0.15f))
            Box(
                Modifier.fillMaxSize().background(
                    Brush.verticalGradient(listOf(Color.Black.opacity(0.2), Color.Black.opacity(0.8 + 0.2 * t))),
                ),
            )
        }

        Column(Modifier.fillMaxSize().padding(18.dp)) {
            // หัวเรื่องอยู่ **เหนือ** ตัวเลข — เอาคำขึ้นก่อนแล้วตาอ่านรอบเดียวจบ
            Row(
                Modifier
                    .scrubVeil(scrub.d, lead = 0.34, drop = 20f, pull = 8f)
                    .fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    "ผู้ติดตามรวมทุกช่องทาง",
                    style = sh(11f, SHFont.bold).copy(letterSpacing = 0.6.sp),
                    color = Color.White.opacity(0.72),
                    maxLines = 1,
                    softWrap = false,
                    autoSize = TextAutoSize.StepBased(minFontSize = (11f * 0.6f).sp, maxFontSize = 11.sp, stepSize = 0.5.sp),
                    modifier = Modifier.weight(1f),
                )
                // ป้ายเดียวกับ `ผู้ติดตามแบบแถว` ฉบับบนรูปถ่าย — ตัวเลขบนรูปต้องบอกที่มา
                ProvenanceTag(kind = Profile.me.creator.socials.provenance, onPhoto = true)
            }

            ScrubDigits(
                text = Fmt.compact(total),
                d = scrub.d,
                lead = 0.24,
                step = 0.06,
                drop = fs * 1.15f,
                style = sh(fs, SHFont.black),
                color = Color.White,
                modifier = Modifier
                    .padding(top = 2.dp)
                    .gradientInk(
                        Brush.linearGradient(listOf(Color.White, theme.rawAccentSoft), start = Offset.Zero, end = Offset.Infinite),
                    ),
            )

            Spacer(Modifier.height(8.dp))
            Spacer(Modifier.weight(1f))

            // แต่ละช่องเป็นชิปกระจกของตัวเอง ไม่ใช่ไอคอนกับเลขลอย ๆ ต่อกัน
            Row(
                Modifier
                    .fillMaxWidth()
                    .wrapContentWidth(Alignment.Start, unbounded = true),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                socials.forEachIndexed { i, s ->
                    Row(
                        Modifier
                            .linkSlot(s.profileURL)
                            .scrubVeil(scrub.d, lead = Scrub.lead(i, socials.size, scrub.d, 0.06), drop = 26f, pull = 10f)
                            // ม่านมืดบาง ๆ ใต้เนื้อหาให้ตัวเลขติดตา + ขอบแสงของกระจก
                            .background(Color.Black.opacity(0.2), CircleShape)
                            .border(0.6.dp, rim, CircleShape)
                            .padding(horizontal = 10.dp, vertical = 6.dp),
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        BrandIcon(s.type.icon, size = 17f)
                        Text(
                            Fmt.compact(s.followerCount),
                            style = sh(14f, SHFont.heavy),
                            color = Color.White,
                            maxLines = 1,
                            softWrap = false,
                            modifier = Modifier.dataValue(),
                        )
                    }
                }
            }
        }
    }
}

/** `.foregroundStyle(gradient)` บนทั้งก้อน — วาดหมึกขาวก่อน แล้วย้อมด้วยไล่เฉดเฉพาะที่มีหมึก */
private fun Modifier.gradientInk(brush: Brush): Modifier =
    graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen)
        .drawWithContent {
            drawContent()
            drawRect(brush, blendMode = BlendMode.SrcIn)
        }

// MARK: - ตัวอักษรใหญ่คร่อมขอบภาพ

/**
 * ชื่อตัวใหญ่วางคร่อมขอบล่างของภาพ — ครึ่งบนอยู่บนภาพเป็นสีขาว ครึ่งล่างพ้นภาพเป็นสีธีม
 *
 * # ท่าเปลี่ยนหน้า — "ตัวอักษรจมผ่านขอบภาพ"
 * เส้นแบ่งสองสีคือขอบล่างของภาพ ตอนปัด **เส้นแบ่งไหลขึ้น** พร้อมตัวอักษรไถลสวนทางรูป
 * ตัวยักษ์ = **ชื่อเล่น** ที่น้ำหนัก bold (black ทำสระบน-ล่างไทยชนกัน)
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun ArtTypeOver(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    // ชื่อยักษ์ถูกวาดสองชั้น จึงต้องตั้งฟอนต์/สีเอง ไม่ใช่รอให้ตัวประกาศช่องใส่ให้
    val tune = LocalWidgetTextStyle.current
    val accent = LocalCardAccent.current
    val ghostData = LocalGhostData.current
    val tilt = LocalSlotTilt.current
    val mark = Profile.me.nickname

    BoxWithConstraints(modifier.fillMaxSize()) {
        val w = maxWidth.value
        val h = maxHeight.value
        // คำนวณย้อนจากขอบล่างขึ้นมา · ย่อกว่าตอนใช้โรมัน 12% — ไทยกินความสูงมากกว่าเพราะมีชั้นสระบน
        val fs = min(w * 0.235f, h * 0.235f) * 0.88f
        val footer = 46f            // ชื่อไทย + บรรทัดสายงาน
        val photoH = max(0f, h - footer - fs * 0.10f)
        // NotoSansThai เผื่อที่ให้สระบน-ล่าง ต้องหักด้วย ascent จริง
        val baseline = photoH - fs * 1.16f
        // ชื่อเล่นยาวไม่ตัดด้วย … แต่ **ย่อขนาดลงจนพอดีความกว้าง**
        val markW = w * 0.94f

        val id = TextSlotID(field = ProfileField.nickname)
        val scaled = tune.scaled(fs, ProfileField.nickname)
        val giant = tune.font(fs, SHFont.bold, ProfileField.nickname).copy(letterSpacing = (-scaled * 0.02f).sp)
        val fit = TextAutoSize.StepBased(minFontSize = (scaled * 0.28f).sp, maxFontSize = scaled.sp, stepSize = 0.5.sp)
        val slot = TextSlotStyle(size = fs, weight = SHFont.bold, color = Color.White, tracking = -fs * 0.02f, corner = 6f)
            .tuned(tune, id, ink, accent)
            .also { it.tilt = tilt }
        val topColor = tune.color(Color.White, ProfileField.nickname, ink = ink, accent = accent) ?: Color.White

        Box(Modifier.size(w.dp, h.dp)) {
            val photoShape = RoundedCornerShape(20.dp)
            Box(Modifier.size(w.dp, photoH.dp).photoSlot(1).clip(photoShape)) {
                WidgetPhoto(1, Modifier.fillMaxSize().scrubDolly(scrub.d, shift = w * 0.05f, zoom = 0.14f))
                Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0.5f to Color.Transparent, 1f to Color.Black.opacity(0.45))))
            }

            val t = Scrub.ease(Scrub.t(scrub.d))
            val s = Scrub.dir(scrub.d)
            // เส้นแบ่งไหลขึ้น — ตัวอักษรจึงเปลี่ยนเป็นสีธีมจากล่างขึ้นบน
            val cut = max(0f, photoH - fs * 0.75f * t)
            val slide = -s * w * 0.12f * t
            val at = Modifier.offset((w * 0.03f + slide).dp, baseline.dp).width(markW.dp)
            Box(Modifier.fillMaxSize().graphicsLayer { alpha = Scrub.fade(t, 0.82).toFloat() }) {
                // ชั้นล่าง: ส่วนที่พ้นภาพลงมา (ซ่อนตอนไม่มีข้อมูล — ไม่งั้นชื่อจริงโผล่ใต้แท่งว่าง)
                if (!ghostData) {
                    Text(mark, style = giant, color = theme.accent, maxLines = 1, softWrap = false, autoSize = fit, modifier = at)
                }
                // ชั้นบน: ส่วนที่ทับอยู่บนภาพ — ตัดด้วยเส้นแบ่งที่เคลื่อนได้ · ประกาศช่องพิมพ์ที่ชั้นนี้ชั้นเดียว
                Box(
                    Modifier.fillMaxSize().drawWithContent {
                        clipRect(0f, 0f, markW.dp.toPx(), cut.dp.toPx()) { this@drawWithContent.drawContent() }
                    },
                ) {
                    Tinted(topColor) {
                        Text(
                            mark, style = giant, color = topColor, maxLines = 1, softWrap = false, autoSize = fit,
                            modifier = at.editableSlot(id, slot).redacted(ghostData),
                        )
                    }
                }
            }

            // บล็อกนี้อยู่ "ใต้" รูป จึงนั่งบนพื้นการ์ด ไม่ใช่บน scrim — ต้องพลิกตามหมึก
            // ยึดกับแถบล่างที่กันไว้ ไม่ผูกกับ baseline ของตัวยักษ์
            Column(
                Modifier
                    .offset((w * 0.035f).dp, (h - footer + 2f).dp)
                    .fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                Row(
                    Modifier
                        .scrubVeil(scrub.d, lead = 0.24, drop = 24f, pull = 8f)
                        .fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(5.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    EditableText(
                        field = ProfileField.personName,
                        style = TextSlotStyle(size = 14f, weight = SHFont.semibold, color = ink.text(0.9)),
                        modifier = Modifier.weight(1f, fill = false),
                    )
                    // ตรายืนยันเกาะชื่อ ไม่ใช่ widget แยก
                    if (Profile.me.creator.verified) {
                        StarSeal(size = 10f, tint = ink.text(0.9), punch = if (ink.isLight) grey(0.97) else grey(0.10))
                    }
                }
                // hero บอกแค่ "นี่คือใคร" — ยอดผู้ติดตามกับพื้นที่รับงานมี widget ของตัวเองอยู่แล้ว
                EditableText(
                    field = ProfileField.tagline,
                    style = TextSlotStyle(
                        size = 8.5f, weight = SHFont.semibold, color = ink.text(0.45),
                        tracking = 2f, uppercase = true,
                    ),
                    modifier = Modifier.scrubVeil(scrub.d, lead = 0.08, drop = 20f, pull = 18f),
                )
            }
        }
    }
}
