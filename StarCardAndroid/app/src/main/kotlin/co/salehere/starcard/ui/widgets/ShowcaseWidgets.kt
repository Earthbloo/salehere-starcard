package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.layout
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.scrubLouver
import co.salehere.starcard.model.LocalWidgetSurface
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.PlatePatternLayer
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.TextFit
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.TextSlotStyle
import kotlin.math.max
import kotlin.math.min

// MARK: - แผ่นโชว์คลิป (= ShowcaseWidgets.swift)
//
// แผ่นพรีเซนต์ที่เจ้าของการ์ดส่งมา: หัวเรื่องนิตยสาร (`Recent` เซริฟเอียง คร่อมคำยักษ์ `VIDEOGRAPHY`)
// แล้วเครื่องสี่เครื่องเรียงหน้ากระดาน · ใต้แต่ละเครื่องคือชื่อลูกค้า — **ผัง สัดส่วน และวัสดุตามต้นฉบับ · ฟอนต์ของแอป**
// มีแผ่นรอง / ไม่มีแผ่นรอง เป็น **ปุ่มเดียวในถาด** — ถอดแผ่นแล้วหมึกพลิกไปใช้หมึกของการ์ด

/**
 * ผังของแผ่น — **หน่วย pt ที่ความกว้างออกแบบ 366** (ตรงกับ `WidgetKind.defaultSize`)
 * ผังเขียนเป็นตัวเลขจริงครั้งเดียวที่ขนาดนี้ แล้ว `PosterSheet` ย่อ/ขยายทั้งก้อนให้ตามกรอบ
 */
private object Reel {
    const val w: Float = 366f
    /** ความสูงของผัง — **หดลงจาก 284 หลังถอดคำบรรยายออก** · ที่ว่างถูกยกให้ตัวเครื่อง */
    const val h: Float = 254f

    // ขอบแคบกว่าเดิมทุกด้าน — แผ่นนี้ขายรูป ขอบคือที่ว่างที่กินพื้นที่รูปไปตรง ๆ
    const val pad: Float = 8f
    const val padTop: Float = 10f
    const val padBottom: Float = 9f

    /** เครื่องหนึ่งเครื่อง — สัดส่วน 1:1.87 ใกล้เคียงตัวเครื่องจริงที่ครอบจอ 9:19.5 · กว้าง = (366 − 8×2 − 7×3) ÷ 4 */
    const val phoneW: Float = 82f
    const val phoneH: Float = 153f
    const val gutter: Float = 7f
    /** ชื่อลูกค้ากว้างเท่าตัวเครื่อง — ไม่ล้นออกไปกินร่องระหว่างเครื่อง */
    const val capW: Float = 82f

    const val recentSize: Float = 19f
    const val recentBox: Float = 23f
    /** คำยักษ์ถูกวัดให้ **กว้างเท่านี้เสมอ** ไม่ว่าเจ้าของการ์ดจะพิมพ์คำไหนลงไป */
    const val titleWidth: Float = 252f
    const val titleCap: Float = 30f
    const val titleBox: Float = 36f
    /** คำเซริฟคร่อมคำยักษ์ตามต้นฉบับ — ไม่ใช่สองบรรทัดที่วางต่อกัน */
    const val titleOverlap: Float = 3f

    const val slots: Int = 4
}

/**
 * วัสดุของแผ่น — ตอบสองข้อพร้อมกัน: มีแผ่นรองไหม และ **หมึกเป็นของใคร**
 * ถ้าถอดแผ่นแล้วยังใช้หมึกครีมของแผ่น ตัวหนังสือจะหายไปทั้งใบบนการ์ดกระดาษ
 */
private data class ReelSkin(
    val sheet: Color,
    val papered: Boolean,
    val ink: Color,
    val inkSoft: Color,
    /** ตัวเครื่อง — บนแผ่นเข้มเป็นถ่านเกือบดำ · บนการ์ดมืดต้องยกขึ้นเป็นกราไฟต์ */
    val bezel: Color,
    val rim: Color,
)

private fun reelSkin(surface: WidgetSurface, theme: CardTheme, cardInk: InkStyle): ReelSkin {
    if (surface == WidgetSurface.pane) {
        // กระจกของ chrome เป็นพื้น — แผ่นใส แต่ผังยังเป็นแผ่นพิมพ์ใบเดิม
        return ReelSkin(
            sheet = Color.Transparent, papered = true,
            ink = cardInk.text(0.95), inkSoft = cardInk.text(0.55),
            bezel = if (cardInk.isLight) grey(0.10) else grey(0.16),
            rim = cardInk.line(0.22),
        )
    }
    if (surface != WidgetSurface.clear) {
        // แผ่นกับครีมมาจากสูตรกลางของตู้ — เฉดคือสีที่เจ้าของการ์ดเลือกไว้
        val cream = PosterPlate.cream(theme)
        return ReelSkin(
            sheet = PosterPlate.plate(theme), papered = true,
            ink = cream, inkSoft = cream.opacity(0.62),
            bezel = grey(0.07), rim = cream.opacity(0.16),
        )
    }
    // ถอดแผ่นแล้ว — ทุกอย่างพลิกไปใช้หมึกของการ์ด
    return ReelSkin(
        sheet = Color.Transparent, papered = false,
        ink = cardInk.text(0.95), inkSoft = cardInk.text(0.55),
        bezel = if (cardInk.isLight) grey(0.10) else grey(0.16),
        rim = cardInk.line(0.22),
    )
}

/**
 * คลิปล่าสุด — หัวเรื่องนิตยสาร + เครื่องสี่เครื่อง + ชื่อลูกค้าใต้แต่ละเครื่อง
 * สีของแผ่นคือ **สีที่เจ้าของการ์ดเลือก** (`PosterPlate`) — สูตรเดียวกับโปสเตอร์สายงาน ไม่งั้นการ์ดมีแผ่นสองเฉด
 * แผ่นต้องเต็มกรอบเสมอ — `Reel.w × Reel.h` เป็นแค่ *ขนาดต่ำสุด* ของผัง (ดู `PosterSheet`)
 */
@Composable
fun ReelShowcase(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val skin = reelSkin(surface, theme, cardInk)
    PosterSheet(design = Size(Reel.w, Reel.h), frame = size, modifier = modifier) { box ->
        ReelSheet(theme, skin, box)
    }
}

/** box: ผังในหน่วยออกแบบที่ยืดเต็มกรอบแล้ว (≥ `Reel.w × Reel.h`) — ก้อนเนื้อหากว้างเท่าผังเสมอแล้วจัดกลางบนแผ่น */
@Composable
private fun ReelSheet(theme: CardTheme, s: ReelSkin, box: Size) {
    val radius = min(theme.radius, 22f)
    val shape = RoundedCornerShape(radius.dp)
    Box(
        Modifier.size(box.width.dp, box.height.dp).clip(shape),
        contentAlignment = Alignment.Center,
    ) {
        if (s.papered) {
            Box(Modifier.fillMaxSize().background(s.sheet, shape))
            PlatePatternLayer(s.sheet, Modifier.fillMaxSize().clip(shape))
            // เส้นขอบในตามต้นฉบับ — บอกว่านี่คือ *แผ่นที่จัดหน้าแล้ว* ไม่ใช่กล่องพื้นหลัง
            Box(
                Modifier
                    .fillMaxSize()
                    .padding(5.dp)
                    .border(0.8.dp, s.rim, RoundedCornerShape(max(0f, radius - 5f).dp)),
            )
        }
        Column(
            Modifier
                .width(Reel.w.dp)
                .fillMaxHeight()
                .padding(start = Reel.pad.dp, end = Reel.pad.dp, top = Reel.padTop.dp, bottom = Reel.padBottom.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            ReelHeader(s)
            Spacer(Modifier.height(9.dp))
            Row(
                horizontalArrangement = Arrangement.spacedBy(Reel.gutter.dp),
                verticalAlignment = Alignment.Top,
            ) {
                for (i in 0 until Reel.slots) ReelColumn(s, i)
            }
        }
    }
}

// MARK: หัวเรื่อง

@Composable
private fun ReelHeader(s: ReelSkin) {
    val wid = LocalWidgetID.current
    val measurer = TextFit.rememberMeasurer()
    // คำยักษ์ถูกวัดจาก **ข้อความที่พิมพ์อยู่จริง** — พิมพ์ "PHOTOGRAPHY" แทนแล้วแถบต้องยังกว้างเท่าเดิม
    val title = Profile.me.note(wid, 1, preset = "VIDEOGRAPHY").uppercase()
    val titleSize = remember(title, measurer) {
        Ed.fitted(measurer, title, weight = SHFont.black, width = Reel.titleWidth, cap = Reel.titleCap, floor = 11f)
    }
    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(Modifier.height(Reel.recentBox.dp), contentAlignment = Alignment.Center) {
            EdText(
                slot = 0, preset = "Recent", hint = "คำนำหัว",
                style = TextSlotStyle(
                    size = Reel.recentSize, weight = SHFont.regular, face = CardFont.serif,
                    color = s.ink, align = TextAlign.Center, italic = true,
                ),
            )
        }
        Box(
            Modifier.pullUp(Reel.titleOverlap).height(Reel.titleBox.dp),
            contentAlignment = Alignment.Center,
        ) {
            EdText(
                slot = 1, preset = "VIDEOGRAPHY", hint = "หัวเรื่อง",
                style = TextSlotStyle(
                    size = titleSize, weight = SHFont.black, color = s.ink,
                    align = TextAlign.Center, tracking = 0.4f, uppercase = true,
                ),
            )
        }
    }
}

// MARK: เครื่องสี่เครื่อง

/**
 * ใต้เครื่องเหลือ **ชื่อลูกค้าอย่างเดียว** — คำบรรยาย 6.4pt ที่เคยอยู่ (ช่อง `6 + i`) เล็กเกินจะอ่าน
 * ข้อความเก่ายังอยู่ในโปรไฟล์ ไม่ได้ลบทิ้ง
 */
@Composable
private fun ReelColumn(s: ReelSkin, i: Int) {
    val d = LocalPageScrub.current.d
    // เครื่องซ้ายสุดออกเดินทางก่อนเสมอ ปัดกลับก็คลี่กลับตามลำดับตรงข้าม
    val lead = Scrub.lead(i, Reel.slots, d, step = 0.08)
    Column(
        Modifier
            .scrubLouver(d, lead = lead, angle = 38.0, shrink = 0.08f)
            .width(Reel.phoneW.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        ReelPhone(s, i)
        Spacer(Modifier.height(6.dp))
        Box(Modifier.width(Reel.capW.dp), contentAlignment = Alignment.TopCenter) {
            EdText(
                slot = 2 + i, preset = "ชื่อลูกค้า", hint = "ชื่อลูกค้าใบที่ ${i + 1}",
                style = TextSlotStyle(size = 9.5f, weight = SHFont.bold, color = s.ink, align = TextAlign.Center),
            )
        }
    }
}

/** ตัวเครื่อง — ขอบหนา 2.5 · จอมุมมนตามตัวเครื่อง · เกาะไดนามิกไอส์แลนด์ที่หัวจอ */
@Composable
private fun ReelPhone(s: ReelSkin, i: Int) {
    val shell = RoundedCornerShape(12.dp)
    val screen = RoundedCornerShape(9.5.dp)
    val shadow = Color.Black.opacity(if (s.papered) 0.45 else 0.3)
    Box(
        Modifier
            .size(Reel.phoneW.dp, Reel.phoneH.dp)
            .shadow(6.dp, shell, clip = false, ambientColor = shadow, spotColor = shadow)
            .background(s.bezel, shell)
            .border(0.8.dp, s.rim, shell),
        contentAlignment = Alignment.TopCenter,
    ) {
        EdPhoto(slot = 4 + i, depth = 8f, modifier = Modifier.fillMaxSize().padding(2.5.dp).clip(screen))
        // เกาะดำที่หัวจอ — ชิ้นเดียวที่ทำให้กรอบสี่เหลี่ยมอ่านออกว่าเป็น *เครื่อง*
        Box(
            Modifier
                .padding(top = 6.dp)
                .size(20.dp, 5.5.dp)
                .background(Color.Black.opacity(0.92), CircleShape),
        )
    }
}

/** `.padding(.top, -x)` — ดึงก้อนขึ้นไปทับของก่อนหน้า และหักความสูงออกจากผังเท่ากัน */
private fun Modifier.pullUp(pt: Float): Modifier = layout { measurable, constraints ->
    val px = pt.dp.roundToPx()
    val p = measurable.measure(constraints)
    layout(p.width, max(0, p.height - px)) { p.placeRelative(0, -px) }
}
