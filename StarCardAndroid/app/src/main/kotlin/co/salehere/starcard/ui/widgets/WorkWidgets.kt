package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.scrubAperture
import co.salehere.starcard.components.scrubDolly
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.VerifiedWork
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.BrandIcon
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.opacity
import kotlin.math.max
import kotlin.math.min

// widget กลุ่มนี้เป็น full-bleed — รูปต้องชนขอบกระจก ไม่มี padding รอบนอก (= Views/Widgets/WorkWidgets.swift)
//
// ทั้งสองตัวเป็น `EntranceStyle.anchored` ที่ระดับกรอบ — ท่าทั้งหมดอยู่ข้างใน
// เพราะของพวกนี้คือ "ผลงาน" ซึ่งเป็นพระเอกของการ์ด มันสมควรมีท่าเป็นของตัวเอง

// MARK: - ผลงานชิ้นเด่น

/**
 * ผังเบนโตะแบบมีพระเอก — ช่องใหญ่กินสองในสาม อีกสองช่องเล็กเรียงข้าง
 * ตระกูล `รูปผลงาน` ไม่มีตัวอักษร — เหลือโลโก้แพลตฟอร์มมุมล่างไว้ดวงเดียว (สัญลักษณ์ ไม่ใช่ข้อความ)
 *
 * ท่าเปลี่ยนหน้า "บานเกล็ดสามบานคนละความลึก" — ความลึกมาจาก **อัตราที่ภาพในช่องถ่วงตัว**:
 * ช่องใหญ่ถ่วงน้อย อ่านเป็นของไกล ช่องเล็กถ่วงมาก อ่านเป็นของใกล้
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun WorkFeatured(theme: CardTheme, modifier: Modifier = Modifier) {
    // ชิ้นที่ทำยอดสูงสุด — เหลือไว้เพื่อรู้ว่าโลโก้มุมล่างควรเป็นแพลตฟอร์มไหนเท่านั้น
    val hero: VerifiedWork? = Profile.me.creator.track.works.maxByOrNull { it.views }

    BoxWithConstraints(modifier.fillMaxSize()) {
        val w = maxWidth.value
        val h = maxHeight.value
        val gap = 8f
        val bigW = (w - gap) * 0.64f
        val smallW = w - bigW - gap
        val smallH = (h - gap) / 2f

        Row(horizontalArrangement = Arrangement.spacedBy(gap.dp)) {
            Box(
                Modifier
                    .size(bigW.dp, h.dp)
                    // ช่องพระเอก = ผลงานชิ้นที่ทำยอดสูงสุด · กดแล้วไปดูโพสต์จริงชิ้นนั้น
                    .linkSlot(hero?.postURL),
                contentAlignment = Alignment.BottomStart,
            ) {
                WorkFrame(4, w = bigW, h = h, radius = 20f, scrim = true, depth = 0.05f, i = 0)
                if (hero != null) {
                    WorkPlatformMark(hero, Modifier.padding(10.dp))
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(gap.dp)) {
                WorkFrame(5, w = smallW, h = smallH, radius = 15f, scrim = false, depth = 0.11f, i = 1)
                WorkFrame(6, w = smallW, h = smallH, radius = 15f, scrim = false, depth = 0.11f, i = 2)
            }
        }
    }
}

/** หนึ่งช่อง = บานเกล็ดหนึ่งบาน · `depth` คือระยะที่ภาพข้างในถ่วงสวนทางหน้า */
@Composable
private fun WorkFrame(index: Int, w: Float, h: Float, radius: Float, scrim: Boolean, depth: Float, i: Int) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val shape = RoundedCornerShape(radius.dp)
    Box(
        Modifier
            .size(w.dp, h.dp)
            .scrubAperture(scrub.d, lead = Scrub.lead(i, 3, scrub.d, 0.12), feather = 0.2f, dim = 0.55)
            .photoSlot(index)
            .border(0.5.dp, ink.line(0.13), shape)
            .clip(shape),
    ) {
        // zoom ต้องคุ้ม shift ไม่งั้นเห็นขอบว่างที่ริมภาพตอนสครับสุดทาง
        Box(Modifier.fillMaxSize().scrubDolly(scrub.d, shift = w * depth, zoom = depth * 2.4f)) {
            WidgetPhoto(index, Modifier.fillMaxSize())
        }
        if (scrim) {
            Box(
                Modifier
                    .fillMaxSize()
                    .background(Brush.verticalGradient(0.5f to Color.Transparent, 1f to Color.Black.opacity(0.55))),
            )
        }
    }
}

/**
 * โลโก้แพลตฟอร์มบนช่องพระเอก — ชิ้นเดียวที่เหลือจากป้ายหลักฐานเดิม
 * อยู่ **นอกม่าน** ของท่าเปลี่ยนหน้าจงใจ (หายช้าสุด กลับมาก่อน) — มันบอกว่ารูปนี้คือของที่ถูกลงไปแล้วบนช่องจริง
 */
@Composable
private fun WorkPlatformMark(work: VerifiedWork, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    Box(
        modifier
            .scrubVeil(scrub.d, lead = 0.4, drop = 22f, pull = 8f)
            .background(Color.Black.opacity(0.45), CircleShape)
            .border(0.5.dp, Color.White.opacity(0.14), CircleShape)
            .padding(6.dp),
    ) {
        BrandIcon(work.platform.icon, size = 13f)
    }
}

// MARK: - คลิปแนวตั้ง

/**
 * คลิปหนึ่งชิ้นเต็มกรอบ พร้อมปุ่มเล่นกลางภาพ — เหลือโลโก้แพลตฟอร์มดวงเดียว (ดู `WorkFeatured`)
 *
 * ท่าเปลี่ยนหน้า "หัวอ่านวิดีโอ" — **ปุ่มเล่นแปลงร่างเป็นวงแหวนกรอ** ที่เติมตามระยะนิ้ว
 * และไอคอนกลางเปลี่ยนเป็นลูกศรกรอหน้า/กรอหลังตามทิศที่ปัด
 */
@Composable
fun WorkReel(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    // ผูกกับผลงานจริงชิ้นแรก — เหลือไว้เพื่อรู้ว่าโลโก้มุมล่างเป็นแพลตฟอร์มไหน
    val work: VerifiedWork? = Profile.me.creator.track.works.firstOrNull()
    val shape = RoundedCornerShape(20.dp)
    val t = Scrub.ease(Scrub.t(scrub.d))

    Box(
        modifier
            .fillMaxSize()
            // ทั้งใบคือคลิปหนึ่งคลิป — กดตรงไหนก็คือกดคลิปนั้น
            .linkSlot(work?.postURL)
            .photoSlot(8)
            .border(0.6.dp, ink.line(0.12), shape)
            .clip(shape),
    ) {
        Box(Modifier.fillMaxSize().scrubDolly(scrub.d, shift = 24f, zoom = 0.2f)) {
            WidgetPhoto(8, Modifier.fillMaxSize())
        }

        // เงามืดด้านล่างไหลสูงขึ้นตามนิ้ว — เวทีหรี่ลงก่อนของจะออกจากฉาก
        val shade = Color.Black.opacity(0.62 + 0.3 * t)
        Box(
            Modifier
                .fillMaxSize()
                .drawBehind {
                    drawRect(
                        Brush.verticalGradient(
                            listOf(Color.Transparent, shade),
                            startY = size.height * (0.5f - 0.42f * t),
                            endY = size.height,
                        ),
                    )
                },
        )

        if (work != null) {
            Box(
                Modifier
                    .align(Alignment.BottomStart)
                    .scrubVeil(scrub.d, lead = 0.36, drop = 26f, pull = 10f)
                    .padding(12.dp)
                    .background(Color.Black.opacity(0.42), CircleShape)
                    .border(0.5.dp, Color.White.opacity(0.14), CircleShape)
                    .padding(6.dp),
            ) {
                BrandIcon(work.platform.icon, size = 13f)
            }
        }

        // สีเน้นดิบ ไม่ใช่สีที่ปรับตามหมึก — วงแหวนนั่งอยู่บนรูป ไม่ใช่บนพื้นการ์ด
        SeekRing(d = scrub.d, tint = theme.rawAccent, modifier = Modifier.align(Alignment.Center))
    }
}

/**
 * ปุ่มเล่นที่กลายเป็นหัวอ่าน — วงแหวนเติมตาม |d| · ไอคอนสลับเป็นลูกศรกรอตาม sign(d)
 * (`d` ถูกสปริงของหน้าไล่อยู่แล้ว ปล่อยนิ้วแล้ววงแหวนจึงไหลกลับเอง ไม่กระโดด)
 */
@Composable
private fun SeekRing(d: Float, tint: Color, modifier: Modifier = Modifier) {
    val t = Scrub.ease(Scrub.t(d))
    val back = d > 0
    Box(
        modifier
            .size(44.dp)
            .graphicsLayer {
                scaleX = 1f - 0.12f * t
                scaleY = 1f - 0.12f * t
                alpha = Scrub.fade(t, 0.8).toFloat()
            }
            .drawBehind {
                val r = size.minDimension / 2f
                // วัสดุฝ้าบาง ๆ (= `.ultraThinMaterial`) — ม่านเทาใสบนรูป
                drawCircle(Color.Black.opacity(0.22), radius = r)
                drawCircle(Color.White.opacity(0.14), radius = r)
                val rim = 1.4.dp.toPx()
                drawCircle(Color.White.opacity(0.16), radius = r - rim / 2f, style = Stroke(rim))
                if (t > 0f) {
                    val inset = 1.4.dp.toPx()
                    drawArc(
                        tint,
                        startAngle = -90f,
                        sweepAngle = 360f * t,
                        useCenter = false,
                        topLeft = Offset(inset, inset),
                        size = Size(size.width - inset * 2f, size.height - inset * 2f),
                        style = Stroke(width = 2.6.dp.toPx(), cap = StrokeCap.Round),
                    )
                }
            },
        contentAlignment = Alignment.Center,
    ) {
        // ปุ่มเล่นจางออกให้ลูกศรกรอเข้ามาแทน — ของสองชิ้นสลับที่กันในวงเดียว
        ReelGlyph(
            forward = null,
            size = 15f,
            tint = Color.White,
            modifier = Modifier
                .offset(x = 1.5.dp)
                .graphicsLayer {
                    alpha = (1f - min(1f, t * 2.2f))
                    scaleX = 1f - 0.3f * t
                    scaleY = 1f - 0.3f * t
                },
        )
        ReelGlyph(
            forward = !back,
            size = 13f,
            tint = tint,
            modifier = Modifier.graphicsLayer {
                alpha = max(0f, t * 2.2f - 0.9f).coerceAtMost(1f)
                scaleX = 0.6f + 0.4f * t
                scaleY = 0.6f + 0.4f * t
            },
        )
    }
}

/**
 * สัญลักษณ์ของหัวอ่าน — `forward = null` คือปุ่มเล่น (▶ = `play.fill`) · true/false คือกรอหน้า/กรอหลัง (`forward.fill`/`backward.fill`)
 * วาดเอง เพราะตาราง SF→Phosphor ไม่มีรูปสามเหลี่ยมเล่น/กรอ — ไอคอนแทนที่ผิดความหมายจะทำให้ท่านี้ไม่อ่านเป็น "seek"
 */
@Composable
private fun ReelGlyph(forward: Boolean?, size: Float, tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier.size(size.dp)) {
        val s = this.size.width
        val join = Stroke(width = s * 0.1f, join = StrokeJoin.Round)
        fun tri(x0: Float, x1: Float, y0: Float, y1: Float, pointRight: Boolean) {
            val p = Path().apply {
                if (pointRight) {
                    moveTo(x0, y0); lineTo(x1, (y0 + y1) / 2f); lineTo(x0, y1)
                } else {
                    moveTo(x1, y0); lineTo(x0, (y0 + y1) / 2f); lineTo(x1, y1)
                }
                close()
            }
            drawPath(p, tint, style = Fill)
            drawPath(p, tint, style = join)
        }
        when (forward) {
            null -> tri(s * 0.2f, s * 0.9f, s * 0.1f, s * 0.9f, pointRight = true)
            true -> {
                tri(s * 0.04f, s * 0.5f, s * 0.2f, s * 0.8f, pointRight = true)
                tri(s * 0.5f, s * 0.96f, s * 0.2f, s * 0.8f, pointRight = true)
            }
            false -> {
                tri(s * 0.04f, s * 0.5f, s * 0.2f, s * 0.8f, pointRight = false)
                tri(s * 0.5f, s * 0.96f, s * 0.2f, s * 0.8f, pointRight = false)
            }
        }
    }
}
