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
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.scrubAperture
import co.salehere.starcard.components.scrubDolly
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.VerifiedWork
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.BrandIcon
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

// MARK: - สำรับ "รูปผลงาน" รอบสอง — แปดสถานการณ์ของกองรูปเดียวกัน (= GalleryWidgets.swift)
//
// กติกาสามข้อของไฟล์นี้
// 1. **รูปคือเนื้อหา ที่เหลือคือกรอบ** — ทุกแบบต้องให้รูปกินพื้นที่เกิน 70%
// 2. **ห้ามมีตัวอักษรสักตัวในทั้งสำรับ** — ไอคอนกับโลโก้แพลตฟอร์มไม่นับเป็นตัวอักษร
// 3. **ท่าเปลี่ยนหน้าต้องมาจากวัสดุ** — ฟิล์มถูกดึงผ่านช่อง · กองรูปถูกลอกทีละใบ · สไลด์เลื่อนไปใบถัดไป

/**
 * วัสดุของสำรับนี้ — สีคงที่ ไม่พลิกตามหมึกการ์ด
 * กระดาษกับฟิล์มคือพื้นผิว *ของตัวมันเอง* ถ้าพลิกตามพื้นการ์ด อุปมา "ของที่จับต้องได้" หายทันที
 */
private object Snap {
    /** ขอบกระดาษอัดรูป */
    val paper = rgb(0.99, 0.99, 0.98)
    /** ฟิล์มเนกาทีฟ — ดำอมน้ำตาล ไม่ใช่ดำสนิท */
    val stock = rgb(0.09, 0.08, 0.09)
    val stockEdge = rgb(0.16, 0.15, 0.16)
    /** ตัวเลขขอบฟิล์ม */
    val filmMark = rgb(0.98, 0.62, 0.20)
    /** เทปกาววาชิ — โปร่งพอให้เห็นรูปข้างใต้ */
    val tape = rgb(1.00, 0.97, 0.86)
}

/**
 * ช่องรูปหนึ่งช่องของสำรับนี้ — clip + ขอบเส้นผม + `photoSlot` ครบในที่เดียว
 * - shift: ระยะถ่วงสวนทางหน้า เป็น pt
 * ขนาดมาจาก `modifier` ของผู้เรียก
 */
@Composable
private fun SnapCell(
    slot: Int,
    radius: Float = 14f,
    d: Float = 0f,
    shift: Float = 0f,
    zoom: Float = 0.16f,
    border: Boolean = true,
    modifier: Modifier = Modifier,
) {
    val ink = LocalCardInk.current
    val shape = if (radius >= 999f) CircleShape else RoundedCornerShape(radius.dp)
    Box(
        modifier
            .photoSlot(slot)
            .clip(shape)
            .let { if (border) it.border(0.6.dp, ink.line(0.12), shape) else it },
    ) {
        WidgetPhoto(slot, Modifier.fillMaxSize().scrubDolly(d, shift = shift, zoom = zoom))
    }
}

/** ผลงานชิ้นแรก — ใช้เป็นแหล่งตัวเลขของแบบที่จำลอง "หน้าตาตอนลงจริง" */
private val firstWork: VerifiedWork? get() = Profile.me.creator.track.works.firstOrNull()

// MARK: - 01 · บอร์ดพิน

/**
 * สองคอลัมน์ความสูงไม่เท่ากัน — ผังเดียวกับบอร์ดที่คนรุ่นนี้เซฟรูปกันทุกวัน
 * ทุกใบเท่ากันในสายตา ต่างกันแค่สัดส่วนที่ถ่ายมา — ความรู้สึกที่ถูกต้องเวลาโชว์ "กองงานทั้งปี"
 * ท่าเปลี่ยนหน้า: คอลัมน์ซ้ายไหลลง ขวาไหลขึ้น แล้วแต่ละช่องหุบไล่กันจากฝั่งที่หน้ากำลังไป
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun GalleryMasonry(theme: CardTheme, modifier: Modifier = Modifier) {
    val d = LocalPageScrub.current.d
    val left = listOf(4, 5)
    val right = listOf(6, 7, 8)
    BoxWithConstraints(modifier.fillMaxSize()) {
        val gap = 7f
        val w = (maxWidth.value - gap) / 2
        val h = maxHeight.value
        Row(horizontalArrangement = Arrangement.spacedBy(gap.dp), verticalAlignment = Alignment.Top) {
            MasonryColumn(left, w, listOf(0.44f, 0.56f), h, gap, from = 0, drift = 16f, d = d)
            MasonryColumn(right, w, listOf(0.3f, 0.36f, 0.34f), h, gap, from = 2, drift = -16f, d = d)
        }
    }
}

/** คอลัมน์เดียว — `from` คือลำดับเริ่มต้นของช่องในขบวนรวม (ห้าช่องหุบไล่กันทั้งบอร์ด) */
@Composable
private fun MasonryColumn(
    slots: List<Int>, w: Float, ratios: List<Float>, h: Float, gap: Float, from: Int, drift: Float, d: Float,
) {
    val inner = h - gap * (slots.size - 1)
    Box(Modifier.size(w.dp, h.dp), contentAlignment = Alignment.TopStart) {
        // ไหลสวนกันตามแกนตั้ง — `scrubSlide` ทำได้แค่แกนนอน ท่านี้จึงเขียนเอง
        Column(
            Modifier.offset(y = (drift * Scrub.ease(Scrub.t(d))).dp),
            verticalArrangement = Arrangement.spacedBy(gap.dp),
        ) {
            slots.forEachIndexed { i, slot ->
                SnapCell(
                    slot, radius = 14f, d = d, shift = w * 0.06f, zoom = 0.18f,
                    modifier = Modifier
                        .scrubAperture(d, lead = Scrub.lead(from + i, 5, d, step = 0.09), feather = 0.22f, dim = 0.5)
                        .size(w.dp, (inner * ratios[i]).dp),
                )
            }
        }
    }
}

// MARK: - 02 · กองรูปซ้อน

/**
 * สามใบซ้อนกันแบบไพ่ที่เพิ่งคลี่ — ใบบนสุดคือใบที่อยากให้เห็น อีกสองใบคือคำสัญญาว่ายังมีอีก
 * แบบที่ควรหยิบตอน **มีรูปดีจริงแค่ไม่กี่ใบ** — ตาอ่านใบล่างเป็น *ความหนา* ไม่ใช่ *เนื้อหา*
 * ท่าเปลี่ยนหน้า: ใบบนหมุนออกแล้วไถลตามทิศนิ้ว ขณะที่สองใบล่าง **ตั้งตรงขึ้นและโตขึ้น**
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun GalleryStack(theme: CardTheme, modifier: Modifier = Modifier) {
    val d = LocalPageScrub.current.d
    // ใบล่างสุดอยู่ต้นลิสต์ — วาดตามลำดับ จึงได้ใบแรกอยู่หลังสุด
    val slots = listOf(6, 5, 4)
    val angles = listOf(-8.0, 4.5, -1.5)
    BoxWithConstraints(modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        val w = maxWidth.value
        val h = maxHeight.value
        val cardW = min(w * 0.78f, h * 0.74f)
        val cardH = min(h * 0.94f, cardW * 1.3f)
        slots.forEachIndexed { i, slot ->
            StackCard(slot, i, slots.size, angles[i], cardW, cardH, d)
        }
    }
}

@Composable
private fun StackCard(slot: Int, i: Int, count: Int, angle: Double, w: Float, h: Float, d: Float) {
    // ใบบนสุด = ตัวสุดท้ายในลิสต์
    val isTop = i == count - 1
    val rest = (count - 1 - i).toFloat()   // 2, 1, 0 นับจากใบล่างสุด
    val t = Scrub.ease(Scrub.t(d, lead = if (isTop) 0.0 else 0.12))
    val s = Scrub.dir(d).toDouble()
    // ใบล่างตั้งตรงขึ้นเมื่อใบบนกำลังไป — กองที่บางลงต้องเรียงตัวใหม่เสมอ
    val rot = if (isTop) angle + s * 22 * t else angle * (1 - 0.75 * t)
    val ox = if (isTop) s.toFloat() * w * 0.5f * t else rest * 3 * (1 - t)
    val oy = rest * 5 * (1 - t)
    val sc = if (isTop) 1 - 0.1f * t else 1 - 0.05f * rest + 0.05f * rest * t
    val a = if (isTop) Scrub.fade(t, after = 0.45).toFloat() else 1f
    val shape = RoundedCornerShape(14.dp)
    val shadow = Color.Black.opacity(0.34)
    Box(
        Modifier
            .graphicsLayer {
                rotationZ = rot.toFloat()
                scaleX = sc
                scaleY = sc
                // `.offset` ของ SwiftUI อยู่ก่อน `.scaleEffect` — ระยะเลื่อนจึงถูกย่อตามไปด้วย
                translationX = ox * sc * density
                translationY = oy * sc * density
                alpha = a
            }
            .shadow((10 - rest * 2).dp, shape, clip = false, ambientColor = shadow, spotColor = shadow)
            .background(Snap.paper, shape)
            .clip(shape)
            .padding(5.dp),
    ) {
        SnapCell(
            slot, radius = 10f, d = d, shift = if (isTop) 14f else 0f, zoom = 0.16f, border = false,
            modifier = Modifier.size(w.dp, h.dp),
        )
    }
}

// MARK: - 03 · โมเสก

/**
 * เก้าช่องเท่ากันเป๊ะ — คอนแทกต์ชีตที่หนาแน่นที่สุดในตู้ · ความหนาแน่นคือสาร
 * ช่องเล็กจึงต้อง **ไม่มีขอบ** และร่องแคบ (4pt) — ขอบเส้นผมเก้าเส้นอ่านเป็นตารางสเปรดชีตทันที
 * ท่าเปลี่ยนหน้า: ดับไล่ตามแนวทแยง (แถว+คอลัมน์) — เส้นทางที่ตาอ่านกริดอยู่แล้ว
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun GalleryMosaic(theme: CardTheme, modifier: Modifier = Modifier) {
    val d = LocalPageScrub.current.d
    val slots = listOf(4, 5, 6, 7, 8, 9, 10, 11, 0)
    BoxWithConstraints(modifier.fillMaxSize()) {
        val gap = 4f
        val w = (maxWidth.value - gap * 2) / 3
        val h = (maxHeight.value - gap * 2) / 3
        Column(verticalArrangement = Arrangement.spacedBy(gap.dp)) {
            for (r in 0 until 3) {
                Row(horizontalArrangement = Arrangement.spacedBy(gap.dp)) {
                    for (c in 0 until 3) {
                        MosaicTile(slots[r * 3 + c], diag = r + c, w = w, h = h, d = d)
                    }
                }
            }
        }
    }
}

/** หนึ่งช่อง — `diag` คือลำดับบนแนวทแยง (0…4) ใช้เป็นลำดับในขบวนดับ */
@Composable
private fun MosaicTile(slot: Int, diag: Int, w: Float, h: Float, d: Float) {
    val k = Scrub.cell(diag, 5, d, spill = 1.6).toFloat()
    SnapCell(
        slot, radius = 7f, d = d, shift = w * 0.1f, zoom = 0.22f, border = false,
        modifier = Modifier
            .graphicsLayer {
                val s = 0.86f + 0.14f * k
                scaleX = s
                scaleY = s
                alpha = k
            }
            .size(w.dp, h.dp),
    )
}

// MARK: - 04 · โพสต์โซเชียล

/**
 * รูปหนึ่งใบในกรอบที่มันถูกโพสต์จริง — หัวโพสต์ · รูป · แถวปฏิสัมพันธ์
 * แบรนด์เห็นกรอบโพสต์แล้วอ่านทันทีว่า "นี่คือของที่ลงไปแล้ว" · ไม่มีตัวอักษรสักตัว เหลือรูปกับสัญลักษณ์ของแพลตฟอร์ม
 * ท่าเปลี่ยนหน้า: หัวกับแถวล่างมุดหายก่อน (ของรอบนอกไปก่อนเสมอ) แล้วรูปค่อยหุบตามทีหลัง
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun GalleryPost(theme: CardTheme, modifier: Modifier = Modifier) {
    val d = LocalPageScrub.current.d
    val ink = LocalCardInk.current
    val work = firstWork
    Column(
        modifier.fillMaxSize().linkSlot(work?.postURL),
        verticalArrangement = Arrangement.spacedBy(9.dp),
    ) {
        // หัวโพสต์ — รูปโปรไฟล์กลม + โลโก้แพลตฟอร์ม · ที่ว่างตรงกลางปล่อยไว้เฉย ๆ
        Row(
            Modifier.fillMaxWidth().scrubVeil(d, lead = 0.3, drop = 18f, pull = 10f),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            SnapCell(
                3, radius = 999f, d = d, shift = 0f, zoom = 0f, border = false,
                modifier = Modifier.size(26.dp).border(0.6.dp, ink.line(0.2), CircleShape),
            )
            Spacer(Modifier.weight(1f))
            if (work != null) BrandIcon(work.platform.icon, size = 13f)
        }

        SnapCell(
            4, radius = 14f, d = d, shift = 20f, zoom = 0.18f,
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
                .scrubAperture(d, lead = 0.16, feather = 0.2f, dim = 0.5),
        )

        // แถวล่าง — ไอคอนปฏิสัมพันธ์ซ้าย · ที่คั่นขวา · ไม่มีตัวเลข: อยู่เพื่อบอกว่า *นี่คือกรอบของโพสต์*
        val tint = ink.text(0.55)
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            for (i in 0 until 3) {
                Box(Modifier.scrubVeil(d, lead = 0.24 + i * 0.04, drop = 16f, pull = 10f)) {
                    when (i) {
                        0 -> PostGlyph(heart = true, tint = tint)
                        1 -> PIcon(Ph.chatCircle, size = 13f, weight = PhWeight.regular, tint = tint)
                        else -> PIcon(Ph.paperPlaneTilt, size = 13f, weight = PhWeight.regular, tint = tint)
                    }
                }
            }
            Spacer(Modifier.weight(1f))
            Box(Modifier.scrubVeil(d, lead = 0.36, drop = 16f, pull = 10f)) {
                PostGlyph(heart = false, tint = tint)
            }
        }
    }
}

/**
 * หัวใจ / ที่คั่นแบบเส้น (SF `heart` · `bookmark`) — ชุด Phosphor ของแอปไม่มีสองตัวนี้ จึงวาดเส้นเอง
 */
@Composable
private fun PostGlyph(heart: Boolean, tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier.size(if (heart) 14.dp else 10.dp, 13.dp)) {
        val sw = 1.3.dp.toPx()
        val l = sw / 2
        val t = sw / 2
        val w = size.width - sw
        val h = size.height - sw
        fun x(f: Float) = l + w * f
        fun y(f: Float) = t + h * f
        val p = Path()
        if (heart) {
            p.moveTo(x(0.5f), y(1f))
            p.cubicTo(x(0.22f), y(0.78f), x(0f), y(0.56f), x(0f), y(0.3f))
            p.cubicTo(x(0f), y(0.12f), x(0.13f), y(0f), x(0.28f), y(0f))
            p.cubicTo(x(0.38f), y(0f), x(0.46f), y(0.06f), x(0.5f), y(0.15f))
            p.cubicTo(x(0.54f), y(0.06f), x(0.62f), y(0f), x(0.72f), y(0f))
            p.cubicTo(x(0.87f), y(0f), x(1f), y(0.12f), x(1f), y(0.3f))
            p.cubicTo(x(1f), y(0.56f), x(0.78f), y(0.78f), x(0.5f), y(1f))
        } else {
            p.moveTo(x(0f), y(1f))
            p.lineTo(x(0f), y(0.12f))
            p.quadraticTo(x(0f), y(0f), x(0.16f), y(0f))
            p.lineTo(x(0.84f), y(0f))
            p.quadraticTo(x(1f), y(0f), x(1f), y(0.12f))
            p.lineTo(x(1f), y(1f))
            p.lineTo(x(0.5f), y(0.74f))
        }
        p.close()
        drawPath(p, tint, style = Stroke(width = sw, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

// MARK: - 05 · สตอรี่

/**
 * เฟรม 9:16 พร้อมแถบความคืบหน้าด้านบน — แบบเดียวในตู้ที่ **สัดส่วนเป็นสาร**
 * ท่าเปลี่ยนหน้า: แถบช่องที่สองเติมตามระยะนิ้วจริง ๆ แล้วพอเต็มก็ข้ามไปช่องที่สาม — การปัดคือการ *ดูต่อ*
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun GalleryStory(theme: CardTheme, modifier: Modifier = Modifier) {
    val d = LocalPageScrub.current.d
    val shape = RoundedCornerShape(20.dp)
    Box(modifier.fillMaxSize().photoSlot(5).clip(shape)) {
        WidgetPhoto(5, Modifier.fillMaxSize().scrubDolly(d, shift = 26f, zoom = 0.22f))

        Box(
            Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        listOf(Color.Black.opacity(0.55), Color.Transparent, Color.Transparent, Color.Black.opacity(0.62)),
                    ),
                ),
        )

        Column(Modifier.fillMaxSize().padding(9.dp)) {
            StoryBars(d)
            StoryHead(d)
            Spacer(Modifier.weight(1f))
            StoryFoot(d)
        }
    }
}

/** แถบความคืบหน้าสามช่อง — ช่องแรกดูจบแล้ว ช่องที่สองกำลังเดิน ช่องที่สามยังไม่ถึง */
@Composable
private fun StoryBars(d: Float) {
    val t = Scrub.ease(Scrub.t(d))
    Row(Modifier.fillMaxWidth().height(2.5.dp), horizontalArrangement = Arrangement.spacedBy(3.dp)) {
        for (i in 0 until 3) {
            Box(Modifier.weight(1f).fillMaxHeight().background(Color.White.opacity(0.28), CircleShape)) {
                Box(
                    Modifier
                        .fillMaxHeight()
                        .fillMaxWidth(storyFill(i, t))
                        .background(Color.White.opacity(0.95), CircleShape),
                )
            }
        }
    }
}

/** สัดส่วนที่เติมของแถบที่ `i` — ช่องก่อนหน้าเต็มเสมอ ช่องปัจจุบันเดินตามนิ้ว */
private fun storyFill(i: Int, t: Float): Float = when (i) {
    0 -> 1f
    1 -> min(1f, t * 2)
    else -> max(0f, t * 2 - 1)
}

/** หัวสตอรี่ — วงกลมรูปโปรไฟล์ที่มีขอบขาว ไม่มีชื่อกำกับ */
@Composable
private fun StoryHead(d: Float) {
    Row(
        Modifier
            .fillMaxWidth()
            .scrubVeil(d, lead = 0.3, drop = 16f, pull = 10f)
            .padding(top = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        SnapCell(
            3, radius = 999f, d = d, shift = 0f, zoom = 0f, border = false,
            modifier = Modifier.size(22.dp).border(1.2.dp, Color.White.opacity(0.85), CircleShape),
        )
    }
}

/** แถบล่าง — ป้าย "ปัดขึ้น" ที่เป็นลูกศรล้วน · สัญลักษณ์เดียวที่ทำให้เฟรมนี้ยังอ่านเป็นสตอรี่ */
@Composable
private fun StoryFoot(d: Float) {
    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        Box(
            Modifier
                .scrubVeil(d, lead = 0.34, drop = 20f, pull = 8f)
                .background(Color.Black.opacity(0.42), CircleShape)
                .border(0.5.dp, Color.White.opacity(0.14), CircleShape)
                .padding(horizontal = 9.dp, vertical = 5.dp),
        ) {
            // `chevron.up` — ลูกศรลงของ Phosphor กลับหัว (ตาราง SF → Phosphor ให้ caret-up-down ซึ่งเป็นสองหัว)
            PIcon(
                Ph.caretDown, size = 11f, weight = PhWeight.bold, tint = Color.White.opacity(0.9),
                modifier = Modifier.graphicsLayer { rotationZ = 180f },
            )
        }
    }
}

// MARK: - 06 · ฟิล์ม 35 มม.

/**
 * สามเฟรมบนฟิล์มเนกาทีฟ — รูพรุนสองแถว ขีดส้มริมขอบ เอียงเล็กน้อย · *ฟิล์มจริงที่ยกขึ้นส่องไฟ*
 * ท่าเปลี่ยนหน้า: ทั้งม้วนเดินไปหนึ่งเฟรมพอดี (ระยะ = ความกว้างเฟรม + ร่อง) ขณะที่หน้าต่างแต่ละเฟรมหุบไล่กัน
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun GalleryFilm(theme: CardTheme, modifier: Modifier = Modifier) {
    val d = LocalPageScrub.current.d
    val slots = listOf(4, 5, 6)
    BoxWithConstraints(modifier.fillMaxSize()) {
        val fullW = maxWidth.value
        val fullH = maxHeight.value
        val pad = 5f
        val gap = 4f
        val hole = max(4.5f, fullH * 0.1f)
        val n = slots.size
        val fw = (fullW - pad * 2 - gap * (n - 1)) / n
        val shape = RoundedCornerShape(4.dp)
        val shadow = Color.Black.opacity(0.35)

        Column(
            Modifier
                .size(fullW.dp, fullH.dp)
                .graphicsLayer { rotationZ = -1.2f }
                .shadow(10.dp, shape, clip = false, ambientColor = shadow, spotColor = shadow)
                .background(Brush.verticalGradient(listOf(Snap.stockEdge, Snap.stock, Snap.stockEdge)), shape)
                .clip(shape)
                .padding(pad.dp),
            verticalArrangement = Arrangement.spacedBy(3.dp),
        ) {
            Sprockets(hole, d)
            Row(
                Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    // เดินหนึ่งเฟรมพอดี — สั้นกว่านี้อ่านเป็น "ไถล" ไม่ใช่ "เดินเฟรม"
                    .scrubSlide(d, travel = fw + gap, fade = 0.85),
                horizontalArrangement = Arrangement.spacedBy(gap.dp),
            ) {
                slots.forEachIndexed { i, slot ->
                    SnapCell(
                        slot, radius = 3f, d = d, shift = fw * 0.09f, zoom = 0.2f, border = false,
                        modifier = Modifier
                            .scrubAperture(d, lead = Scrub.lead(i, n, d, step = 0.1), feather = 0.22f, dim = 0.5)
                            .width(fw.dp)
                            .fillMaxHeight(),
                    )
                }
            }
            Sprockets(hole, d)
        }
    }
}

/**
 * แถวรูพรุน — รูขนาดคงที่แล้วปล่อยให้จำนวนวิ่งตามความกว้าง (ฟิล์มจริงระยะรูคงที่เสมอ)
 * ขีดส้มริมขอบ — ที่เดิมของเลขขอบฟิล์ม เก็บ *สี* ของฟิล์มไว้โดยไม่ต้องมีตัวหนังสือ
 */
@Composable
private fun Sprockets(h: Float, d: Float) {
    Box(Modifier.fillMaxWidth().height(h.dp)) {
        Canvas(Modifier.fillMaxSize()) {
            val step = (h * 1.55f).dp.toPx()
            val n = max(3, (size.width / step).toInt())
            val hw = (h * 0.72f).dp.toPx()
            val hh = (h * 0.62f).dp.toPx()
            val r = 1.4.dp.toPx()
            for (k in 0 until n) {
                val cx = step * k + step / 2
                drawRoundRect(
                    Color.Black.opacity(0.55),
                    topLeft = Offset(cx - hw / 2, (size.height - hh) / 2),
                    size = Size(hw, hh),
                    cornerRadius = CornerRadius(r, r),
                )
            }
        }
        Box(
            Modifier
                .align(Alignment.CenterEnd)
                .scrubVeil(d, lead = 0.36, drop = 10f, pull = 6f)
                .size((h * 1.6f).dp, (h * 0.22f).dp)
                .background(Snap.filmMark.opacity(0.9), CircleShape),
        )
    }
}

// MARK: - 07 · เทปกาว

/** ช่อง · จุดกลาง (สัดส่วนของกรอบ) · องศา · ความกว้าง (สัดส่วน) */
private data class TapePiece(val slot: Int, val x: Float, val y: Float, val rot: Double, val w: Float)

/** องศาเอียงต้องไม่เท่ากันสักใบ และต้องไม่หารลงตัว — เอียงเท่ากันทุกใบอ่านเป็น "เอฟเฟกต์" ทันที */
private val tapePieces = listOf(
    TapePiece(4, 0.31f, 0.46f, -7.5, 0.50f),
    TapePiece(5, 0.70f, 0.36f, 5.0, 0.42f),
    TapePiece(6, 0.62f, 0.74f, -2.5, 0.40f),
)

/** เทปคาดหัวใบ — วางคร่อมขอบ ไม่ใช่วางข้างใน */
private const val washiHeight = 13f

/**
 * สามใบวางทับกันแบบแปะบนโต๊ะ — เอียงคนละองศา มีเทปวาชิคาดหัว · อ่านเป็นมู้ดบอร์ดของเจ้าตัว
 * ท่าเปลี่ยนหน้า: แต่ละใบหมุนขึ้นแล้วลอยออกไล่กัน — ของที่ *ถูกแปะ* ต้องหมุนออกจากผิวเสมอ
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun GalleryTape(theme: CardTheme, modifier: Modifier = Modifier) {
    val d = LocalPageScrub.current.d
    BoxWithConstraints(modifier.fillMaxSize()) {
        val box = Size(maxWidth.value, maxHeight.value)
        tapePieces.forEachIndexed { i, p -> TapeCard(p, i, box, d) }
    }
}

@Composable
private fun TapeCard(p: TapePiece, i: Int, box: Size, d: Float) {
    val pw = box.width * p.w
    val ph = min(pw * 1.25f, box.height * 0.72f)
    val t = Scrub.ease(Scrub.t(d, lead = Scrub.lead(i, tapePieces.size, d, step = 0.11)))
    val s = Scrub.dir(d)
    val fw = pw + 30
    val fh = ph + 30
    val shape = RoundedCornerShape(5.dp)
    val shadow = Color.Black.opacity(0.3)
    Box(
        Modifier
            .offset((box.width * p.x - fw / 2).dp, (box.height * p.y - fh / 2).dp)
            .size(fw.dp, fh.dp),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier.graphicsLayer {
                rotationZ = (p.rot + s * 16 * t).toFloat()
                val k = 1 - 0.16f * t
                scaleX = k
                scaleY = k
                alpha = Scrub.fade(t, after = 0.5).toFloat()
            },
        ) {
            Box(
                Modifier
                    .shadow(8.dp, shape, clip = false, ambientColor = shadow, spotColor = shadow)
                    .background(Snap.paper, shape)
                    .clip(shape)
                    .padding(4.dp),
            ) {
                SnapCell(
                    p.slot, radius = 3f, d = d, shift = pw * 0.06f, zoom = 0.16f, border = false,
                    modifier = Modifier.size(pw.dp, ph.dp),
                )
            }
            // ของที่ล้นออกนอกกรอบคือสิ่งที่ทำให้แผ่นอ่านเป็นของจริง
            Washi(pw * 0.52f, Modifier.align(Alignment.TopCenter))
        }
    }
}

@Composable
private fun Washi(width: Float, modifier: Modifier = Modifier) {
    Box(
        modifier
            .offset(y = (-washiHeight * 0.45f).dp)
            .graphicsLayer { rotationZ = -3f }
            .size(width.dp, washiHeight.dp)
            .background(Snap.tape.opacity(0.72))
            .border(0.5.dp, Color.White.opacity(0.5)),
    )
}

// MARK: - 08 · สไลด์การ์ด

/**
 * การ์ดใบใหญ่หนึ่งใบ กับใบถัดไปโผล่มาให้เห็นครึ่งเดียว + จุดบอกตำแหน่ง
 * **อยากให้คนดูทีละใบ แต่ต้องรู้ว่ายังมีอีก** — ใบที่โผล่มาครึ่งใบคือสิ่งเดียวที่บอกว่าต้องเลื่อนต่อ
 * ท่าเปลี่ยนหน้า: รางเลื่อนไปหนึ่งใบพอดีตามทิศนิ้ว และ **จุดบอกตำแหน่งเดินตามไปด้วย**
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun GalleryCarousel(theme: CardTheme, modifier: Modifier = Modifier) {
    val d = LocalPageScrub.current.d
    val ink = LocalCardInk.current
    val slots = listOf(4, 5, 6)
    BoxWithConstraints(modifier.fillMaxSize()) {
        val w = maxWidth.value
        val h = maxHeight.value
        val gap = 8f
        val cardW = w * 0.84f
        val dots = 16f
        val t = Scrub.ease(Scrub.t(d))
        // ตำแหน่งบนรางเป็นทศนิยม — ใช้ทั้งเลื่อนราง ย่อ/ขยายใบ และเดินจุด
        val pos = if (Scrub.dir(d) > 0) t else -t

        Column(
            Modifier.size(w.dp, h.dp).clipToBounds(),
            verticalArrangement = Arrangement.spacedBy(7.dp),
        ) {
            Box(
                Modifier
                    .offset(x = (-pos * (cardW + gap)).dp)
                    .size(w.dp, (h - dots).dp),
            ) {
                Row(
                    Modifier.wrapContentWidth(Alignment.Start, unbounded = true),
                    horizontalArrangement = Arrangement.spacedBy(gap.dp),
                ) {
                    slots.forEachIndexed { i, slot ->
                        // ใบที่อยู่ตรงตำแหน่งปัจจุบันเต็มขนาด ใบข้าง ๆ ย่อ — ระยะห่างเป็นตัวคุม ไม่ใช่ลำดับ
                        val far = min(1f, abs(i - pos))
                        SnapCell(
                            slot, radius = 16f, d = d, shift = cardW * 0.07f, zoom = 0.2f,
                            modifier = Modifier
                                .graphicsLayer {
                                    val k = 1 - 0.07f * far
                                    scaleX = k
                                    scaleY = k
                                    alpha = 1 - 0.35f * far
                                }
                                .size(cardW.dp, (h - dots).dp),
                        )
                    }
                }
            }

            // จุดบอกตำแหน่ง — จุดที่ active ยืดเป็นขีด แล้วยืด/หดไล่ตามตำแหน่งบนราง
            Row(
                Modifier.fillMaxWidth().height((dots - 7).dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp, Alignment.CenterHorizontally),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                slots.indices.forEach { i ->
                    val k = max(0f, 1 - abs(i - pos))
                    Box(
                        Modifier
                            .size((5 + 9 * k).dp, 5.dp)
                            .background(ink.text(0.25 + 0.6 * k), CircleShape),
                    )
                }
            }
        }
    }
}
