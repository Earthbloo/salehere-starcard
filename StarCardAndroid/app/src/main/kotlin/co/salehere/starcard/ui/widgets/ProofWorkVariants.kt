package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.ScrubDigits
import co.salehere.starcard.components.VerifiedBadge
import co.salehere.starcard.components.WidgetLabel
import co.salehere.starcard.components.scrubDolly
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Brand
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.VerifiedWork
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.BrandIcon
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.EPChip
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import kotlin.math.max

// ผลงานที่ยืนยันแล้ว — ตั๋วผลงาน (= Views/Widgets/ProofWorkVariants.swift)
//
// ใช้ข้อมูลชุดเดียวกันเป๊ะกับ `ProofWork` และต้องบอกครบสี่สัญญาณ **โพสอะไร · ตอนไหน · แบรนด์ไหน · ได้ผลแค่ไหน**
// **กฎข้อแรกของชั้นนี้: รูปคือตัวนำ** — ช่องรูปต้องกินพื้นที่เกินครึ่งของ widget เสมอ
// สิ่งที่ทำให้ widget อ่านเป็น "ตาราง" คือ **จำนวนสไตล์ตัวอักษรที่ใช้พร้อมกัน** ไม่ใช่ปริมาณข้อมูล
// กติกาท่าประจำชั้นนี้: **หัวเรื่องกับตัวเลขคือสมอ** ไปทีหลังสุด กลับมาก่อนใคร

// MARK: - ชิ้นส่วนที่ใช้ร่วมกันทุกแบบ

/** หาแบรนด์จากชื่อในผลงาน — ชื่อต้องตรงกับรายการ `brands` ถึงจะได้โลโก้มาแสดง */
private fun brandOf(work: VerifiedWork): Brand? =
    Profile.me.creator.track.brands.firstOrNull { it.name == work.brand }

private val works: List<VerifiedWork> get() = Profile.me.creator.track.works

/** `.minimumScaleFactor(k)` */
private fun ticketShrink(size: Float, k: Float): TextAutoSize =
    TextAutoSize.StepBased(minFontSize = (size * k).sp, maxFontSize = size.sp, stepSize = 0.5.sp)

/**
 * "โพสอะไร" — ไอคอนแพลตฟอร์มสีจริงคู่ชื่อฟอร์แมต (แบรนด์ต้องรู้ทั้งคู่ถึงจะเทียบราคาได้)
 * - iconOnly: ซ่อนชื่อฟอร์แมตเมื่อช่องแคบเกินกว่าจะอ่านออก — เหลือไอคอนดีกว่าเหลือคำที่ถูกตัดครึ่ง
 */
@Composable
private fun PostTag(
    work: VerifiedWork,
    size: Float = 9f,
    tint: Color? = null,
    iconOnly: Boolean = false,
    modifier: Modifier = Modifier,
) {
    val ink = LocalCardInk.current
    Row(
        modifier.wrapContentSize(),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        BrandIcon(work.platform.icon, size = size * 1.15f)
        if (!iconOnly) {
            Text(
                work.format,
                style = sh(size, SHFont.semibold),
                color = tint ?: ink.text(0.6),
                maxLines = 1,
                softWrap = false,
            )
        }
    }
}

/**
 * ช่องรูปผลงานหนึ่งช่อง — ผูก `photoSlot` ให้เรียบร้อยเพื่อให้กดเปลี่ยนรูปได้ทุกแบบ
 * - dolly: ระยะถ่วงสวนทางหน้า — 0 คือไม่ถ่วง
 */
@Composable
private fun WorkPhoto(work: VerifiedWork, radius: Float = 10f, dolly: Float = 0f, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    Box(modifier.photoSlot(work.photo).clip(RoundedCornerShape(radius.dp))) {
        // zoom ต้องคุ้ม shift (0.16 ≥ 2 × 0.07) ไม่งั้นเห็นขอบว่างตอนถ่วง
        WidgetPhoto(
            work.photo,
            Modifier.fillMaxSize().scrubDolly(scrub.d, shift = dolly, zoom = if (dolly > 0f) 0.16f else 0f),
        )
    }
}

private val proofBadge: @Composable () -> Unit = { VerifiedBadge() }

/** หัวเรื่องมาตรฐานของชั้นหลักฐาน — ทุกแบบใช้ตัวเดียวกันเพื่อให้แบรนด์รู้ทันทีว่ากำลังดูอะไร */
@Composable
private fun ProofHeader(badge: Boolean = true, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    WidgetLabel(
        "ผลงานที่ยืนยันแล้ว",
        trailing = if (badge) proofBadge else null,
        modifier = modifier.scrubVeil(scrub.d, lead = 0.34, drop = 22f, pull = 6f),
    )
}

/**
 * สีกระดาษของแบบที่มีพื้นผิวเป็นของตัวเอง (ตั๋ว) (= `enum Paper`)
 * ไม่ผูกกับ `cardInk` โดยตั้งใจ — กระดาษพวกนี้ *คือ* พื้นผิวของตัวเอง
 */
private object TicketPaper {
    val cream = rgb(0.98, 0.96, 0.93)
    val creamDeep = rgb(0.95, 0.91, 0.86)
    val slip = rgb(0.97, 0.96, 0.93)
    val ink = rgb(0.09, 0.06, 0.13)
    val inkSoft = rgb(0.35, 0.31, 0.42)
    val stampGreen = rgb(0.05, 0.56, 0.45)
    val hot = rgb(0.77, 0.10, 0.31)
}

/**
 * ตัวเลขหลักฐานท้ายชิ้น — **ยอดวิวอย่างเดียว** (ER ยังอยู่ในโมเดล `work.engagementRate`)
 * ถอดทีละหลักตามนิ้ว ไม่ใช่จางหาย เพราะมันคือค่าที่นับได้ ไม่ใช่คำโปรย
 */
@Composable
private fun ProofFigures(
    work: VerifiedWork,
    size: Float = 13f,
    tint: Color,
    subTint: Color,
    lead: Double = 0.3,
    modifier: Modifier = Modifier,
) {
    val scrub = LocalPageScrub.current
    Column(modifier, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            // ตัวเดียวในบรรทัดนี้ จึงใหญ่ขึ้นได้โดยไม่ไปแย่งความสนใจกับใคร
            ScrubDigits(
                Fmt.compact(work.views), scrub.d, lead = lead, step = 0.05, drop = 20f,
                style = sh(size * 1.15f, SHFont.heavy), color = tint,
                modifier = Modifier.alignByBaseline(),
            )
            Text(
                "วิว",
                style = sh(size * 0.62f),
                color = subTint,
                maxLines = 1,
                softWrap = false,
                modifier = Modifier.alignByBaseline().scrubVeil(scrub.d, lead = lead - 0.04, drop = 18f, pull = 6f),
            )
        }

        // บันทึก/แชร์ เป็นไอคอน ไม่ใช่คำ — ยอดวิวบอกว่าคนเห็นเยอะแค่ไหน สองตัวนี้บอกว่าเห็นแล้วทำอะไรต่อ
        WorkDeepStats(work, size = size * 0.68f, tint = subTint, lead = max(0.0, lead - 0.08))
    }
}

// MARK: - 01 · ตั๋วผลงาน

/**
 * ผลงานคือตั๋วที่ **ฉีกแล้ว** — เข้างานจริง ไม่ใช่แค่จอง
 * รอยปรุกับรหัสตอนทำหน้าที่เป็นซีเรียล ซึ่งเป็นสิ่งที่ media kit ทำใน Canva ปลอมขึ้นมาไม่ได้
 *
 * # ท่าเปลี่ยนหน้า — "ฉีกตามรอยปรุ"
 * ครึ่งบน (รูป) กับครึ่งล่าง (ข้อมูล) ไถลสวนทางกันออกจากกันที่รอยปรุ
 */
@Composable
fun ProofTicket(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val list = works

    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        ProofHeader()

        BoxWithConstraints(Modifier.fillMaxWidth().weight(1f)) {
            val gap = 7f
            val n = max(1, list.size)
            val w = (maxWidth.value - gap * (n - 1)) / n
            val h = maxHeight.value
            // รูปคือตัวนำ — กิน 60% ของใบ · ส่วนท้ายตั๋วเหลือแค่สามบรรทัด (แบรนด์ · ชื่อ · ตัวเลข)
            val photoH = max(w * 0.9f, h * 0.58f)

            Row(
                horizontalArrangement = Arrangement.spacedBy(gap.dp),
                verticalAlignment = Alignment.Top,
            ) {
                list.forEachIndexed { i, work ->
                    TicketStub(
                        work, w, h, photoH,
                        lead = Scrub.lead(i, list.size, scrub.d, step = 0.1),
                        modifier = Modifier.linkSlot(work.postURL),
                    )
                }
            }
        }
    }
}

@Composable
private fun TicketStub(work: VerifiedWork, w: Float, h: Float, photoH: Float, lead: Double, modifier: Modifier) {
    val scrub = LocalPageScrub.current
    // ล็อกความสูงเท่ากับที่ widget ได้จริง — ชื่อแคมเปญยาวไม่เท่ากันจะทำให้ตั๋วสูงไม่เท่าแล้วทะลุไปทับ widget ถัดไป
    Column(modifier.width(w.dp).height(h.dp).clip(RoundedCornerShape(9.dp))) {
        // ครึ่งบน — รูปกับรหัสตอน
        Box(
            Modifier
                .fillMaxWidth()
                .height(photoH.dp)
                .scrubSlide(scrub.d, travel = -14f, lead = lead, fade = 0.85),
        ) {
            WorkPhoto(work, radius = 0f, dolly = w * 0.06f, modifier = Modifier.fillMaxSize())
            // "โพสอะไร" ไปอยู่บนรูป — รูปกับแพลตฟอร์มเป็นเรื่องเดียวกัน และตั๋วได้บรรทัดคืนมาหนึ่งบรรทัด
            PostTag(
                work, size = 10f, iconOnly = true,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(5.dp)
                    .background(Color.Black.opacity(0.5), CircleShape)
                    .padding(4.dp),
            )
            EPChip(
                work.ep, tone = EPChip.Tone.ink, size = 8f,
                modifier = Modifier.align(Alignment.BottomStart).padding(5.dp),
            )
        }

        Perforation()

        // ครึ่งล่าง — สี่สัญญาณเรียงจากใครไปเท่าไหร่
        Column(
            Modifier
                .fillMaxWidth()
                .weight(1f)
                .scrubSlide(scrub.d, travel = 16f, lead = lead + 0.05, fade = 0.85)
                .background(Brush.verticalGradient(listOf(TicketPaper.cream, TicketPaper.creamDeep)))
                .padding(start = 8.dp, end = 8.dp, top = 6.dp, bottom = 9.dp),
        ) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(5.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                brandOf(work)?.let { BrandPlate(it, side = 15f) }
                Text(
                    work.brand,
                    style = sh(9f, SHFont.semibold),
                    color = TicketPaper.inkSoft,
                    maxLines = 1,
                    softWrap = false,
                    autoSize = ticketShrink(9f, 0.6f),
                )
            }

            Spacer(Modifier.height(5.dp))

            Text(
                work.campaign,
                style = sh(12.5f, SHFont.bold),
                color = TicketPaper.ink,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                autoSize = ticketShrink(12.5f, 0.7f),
                modifier = Modifier.fillMaxWidth(),
            )

            // ช่องไฟ 5 + ที่ว่างยืดได้ (อย่างน้อย 2) + 5 — เท่ากับ VStack(spacing: 5) ที่มี Spacer(minLength: 2)
            Spacer(Modifier.height(7.dp))
            Spacer(Modifier.weight(1f))
            Spacer(Modifier.height(5.dp))

            ProofFigures(
                work, size = 11.5f, tint = TicketPaper.ink, subTint = TicketPaper.inkSoft,
                modifier = Modifier
                    .fillMaxWidth()
                    .drawWithContent {
                        drawContent()
                        drawRect(TicketPaper.ink.opacity(0.14), size = Size(size.width, 0.6.dp.toPx()))
                    }
                    .padding(top = 5.dp),
            )
        }
    }
}

/**
 * รอยปรุ — เจาะรูจริงด้วย DstOut ไม่ใช่วาดวงกลมสีพื้นทับ
 * เพราะพื้นหลังการ์ดเป็นเกรเดียนต์ วงกลมสีเดียวจะเห็นเป็นจุดด่างทันที
 */
@Composable
private fun Perforation() {
    Canvas(
        Modifier
            .fillMaxWidth()
            .height(9.dp)
            .graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen),
    ) {
        val d = 5.dp.toPx()
        val cy = size.height / 2f
        val hair = 0.6.dp.toPx()
        drawRect(TicketPaper.creamDeep)
        drawRect(
            TicketPaper.ink.opacity(0.28),
            topLeft = Offset(d, cy - hair / 2f),
            size = Size(max(0f, size.width - 2f * d), hair),
        )
        drawCircle(Color.Black, radius = d / 2f, center = Offset(0f, cy), blendMode = BlendMode.DstOut)
        drawCircle(Color.Black, radius = d / 2f, center = Offset(size.width, cy), blendMode = BlendMode.DstOut)
    }
}
