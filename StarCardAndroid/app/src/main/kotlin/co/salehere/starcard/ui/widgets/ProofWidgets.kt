package co.salehere.starcard.ui.widgets

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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.ScrubDigits
import co.salehere.starcard.components.ScrubRunner
import co.salehere.starcard.components.VerifiedBadge
import co.salehere.starcard.components.WidgetLabel
import co.salehere.starcard.components.scrubAperture
import co.salehere.starcard.components.scrubDolly
import co.salehere.starcard.components.scrubLouver
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Brand
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.VerifiedWork
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.BrandIcon
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.EPChip
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.editor.dataValue
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

// ชั้นหลักฐาน — ทุกตัวติด VerifiedBadge และล็อกขนาดไว้ (= Views/Widgets/ProofWidgets.swift)
// เหตุผล: แบรนด์เปิดการ์ด 30 ใบเพื่อเลือก 5 คน ถ้าหน้าตาไม่เหมือนกันเขาเทียบไม่ได้
//
// กติกาท่าประจำชั้นนี้: **หัวเรื่องกับตัวเลขคือสมอ** — ไปทีหลังสุด กลับมาก่อนใคร
// (`BrandPlate` อยู่ใน WidgetKit.kt)

/** `.minimumScaleFactor(k)` ของบรรทัดเดียว */
private fun proofShrink(size: Float, k: Float): TextAutoSize =
    TextAutoSize.StepBased(minFontSize = (size * k).sp, maxFontSize = size.sp, stepSize = 0.5.sp)

/**
 * ผลงานที่ระบบยืนยันตัวเลขให้ — ตัวเลขวิว/engagement ดึงมาจากโพสต์จริง ไม่ใช่ creator พิมพ์เอง
 *
 * # ท่าเปลี่ยนหน้า — "บานเกล็ด"
 * **ของไม่ขยับ ที่ขยับคือหน้าต่างที่มองมัน** — ช่องผลงานหุบไล่กันตามทิศนิ้ว รูปในบานถ่วงตัวสวนทางหน้า (ดอลลี่)
 * ตัวเลขวิวถูกถอดออกทีละหลัก · ชื่อแบรนด์ไปก่อน · ตัวเลขไปท้ายสุดและกลับมาก่อนใคร
 */
@Composable
fun ProofWork(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val works = Profile.me.creator.track.works

    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        // หัวเรื่องคือสมอของทั้งก้อน — ขยับทีหลังสุด กลับมาก่อนใคร
        WidgetLabel(
            "ผลงานที่ยืนยันแล้ว",
            trailing = { VerifiedBadge() },
            modifier = Modifier.scrubVeil(scrub.d, lead = 0.34, drop = 22f, pull = 6f),
        )

        BoxWithConstraints(Modifier.fillMaxWidth().weight(1f)) {
            val gap = 9f
            val n = max(1, works.size)
            val w = (maxWidth.value - gap * (n - 1)) / n

            Row(
                Modifier.fillMaxSize(),
                horizontalArrangement = Arrangement.spacedBy(gap.dp),
                verticalAlignment = Alignment.Top,
            ) {
                works.forEachIndexed { i, work ->
                    // ลำดับการหุบผูกกับ sign(d) ล้วน — บานที่หุบก่อนคือบานที่คลี่ทีหลัง
                    ProofWorkColumn(
                        work, w, theme,
                        Modifier
                            .fillMaxHeight()
                            .linkSlot(work.postURL)
                            .scrubAperture(
                                scrub.d,
                                lead = Scrub.lead(i, works.size, scrub.d, step = 0.13),
                                feather = 0.18f, dim = 0.55,
                            ),
                    )
                }
            }
        }
    }
}

/** หาแบรนด์จากชื่อในผลงาน — ชื่อต้องตรงกับรายการ `brands` ถึงจะได้โลโก้มาแสดง */
private fun proofBrand(name: String): Brand? =
    Profile.me.creator.track.brands.firstOrNull { it.name == name }

/**
 * ผลงานหนึ่งช่อง = บานเกล็ดหนึ่งบาน
 * สิ่งที่แบรนด์กวาดตาหาจริงมีสี่อย่าง: **รูป · แบรนด์ · วิว · บันทึก/แชร์** — ชื่อแคมเปญถูกตัดออก
 * รูปไม่ล็อกสัดส่วน แต่ **กินที่ทั้งหมดที่เหลือ**
 */
@Composable
private fun ProofWorkColumn(work: VerifiedWork, w: Float, theme: CardTheme, modifier: Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val shape = RoundedCornerShape(12.dp)

    Column(modifier.width(w.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Box(Modifier.width(w.dp).weight(1f).photoSlot(work.photo)) {
            Box(Modifier.matchParentSize().clip(shape)) {
                // ถ่วงสวนทางหน้า · zoom ต้องคุ้ม shift (0.16 ≥ 2 × 0.07) ไม่งั้นเห็นขอบว่าง
                WidgetPhoto(
                    work.photo,
                    Modifier.fillMaxSize().scrubDolly(scrub.d, shift = w * 0.07f, zoom = 0.16f),
                )
            }
            Box(Modifier.matchParentSize().border(0.5.dp, ink.line(0.1), shape))

            // ป้ายการันตีผลงาน — ติดเฉพาะชิ้นที่ถึงเกณฑ์จริง ไม่ใช่ทุกชิ้น
            val tag = work.viralTag
            if (tag != null) {
                Text(
                    tag,
                    style = sh(8.5f, SHFont.heavy),
                    color = Color.White,
                    maxLines = 1,
                    softWrap = false,
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .scrubVeil(scrub.d, lead = 0.2, drop = 16f, pull = 8f)
                        .padding(7.dp)
                        .background(theme.rawAccent.opacity(0.92), CircleShape)
                        .padding(horizontal = 7.dp, vertical = 3.5.dp),
                )
            }
            // ซีเรียลของงาน — เลขตอนที่ระบบออกให้ อยู่มุมล่างของรูปทุกชิ้นทุกแบบ
            EPChip(
                work.ep, tone = EPChip.Tone.ink, size = 7.5f,
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .scrubVeil(scrub.d, lead = 0.22, drop = 14f, pull = 8f)
                    .padding(6.dp),
            )
        }

        // แบรนด์เจ้าของงาน — โลโก้จริงคู่ชื่อ · ปิดท้ายด้วยไอคอนแพลตฟอร์ม ("ลงที่ไหน" มาก่อนยอดวิวเสมอ)
        Row(
            Modifier.fillMaxWidth().scrubVeil(scrub.d, lead = 0.04, drop = 26f, pull = 12f),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            proofBrand(work.brand)?.let { BrandPlate(it, side = 20f) }
            Text(
                work.brand,
                style = sh(10f, SHFont.semibold),
                color = ink.text(0.72),
                maxLines = 1,
                softWrap = false,
                autoSize = proofShrink(10f, 0.6f),
                modifier = Modifier.weight(1f),
            )
            Spacer(Modifier.width(3.dp))
            BrandIcon(work.platform.icon, size = 11f)
        }

        // หลักฐานไปท้ายสุด กลับมาก่อนใคร — และไปแบบ "ถอดทีละหลัก" ไม่ใช่จางหาย
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            ScrubDigits(
                Fmt.compact(work.views), scrub.d, lead = 0.3, step = 0.05, drop = 20f,
                style = sh(19f, SHFont.heavy), color = ink.text(0.98),
                modifier = Modifier.alignByBaseline(),
            )
            Text(
                "วิว",
                style = sh(9.5f),
                color = ink.text(0.42),
                maxLines = 1,
                softWrap = false,
                modifier = Modifier.alignByBaseline().scrubVeil(scrub.d, lead = 0.26, drop = 18f, pull = 6f),
            )
        }

        // บรรทัดรอง ไม่ใช่บรรทัดคู่ — วางใต้ยอดวิวและเล็กกว่าชัดเจน
        WorkDeepStats(work, size = 9.5f, tint = ink.text(0.52))
    }
}

// MARK: - แบรนด์: หลายหน้าตาให้เลือก
//
// แต่ละตัวเล่นคนละจังหวะ: แผงครบ (เห็นทุกแบรนด์) · ราง (เลื่อนเอง) · เหรียญ (แถวเดียว อ่านจบในจังหวะเดียว)

/**
 * แผงโลโก้ครบทุกใบ — **แบบเดียวในตระกูลที่ไม่มี "+N"** (แบรนด์ต้องเห็นทุกใบถึงจะรู้ว่ามีคู่แข่งอยู่ไหม)
 * วางเป็นคอนแทกต์ชีต: ช่องชนกันสนิท คั่นด้วยเส้นผม · ทุกแบรนด์เท่ากันหมด
 *
 * # ท่าเปลี่ยนหน้า — "ไฟดับเป็นคลื่นทแยง" (แถว + คอลัมน์) ไม่ใช่ไล่ทีละใบ
 */
@Composable
fun ProofBrandGrid(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val t = Profile.me.creator.track

    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        WidgetLabel(
            "ร่วมงานกับ ${t.brandCount} แบรนด์",
            trailing = { VerifiedBadge() },
            modifier = Modifier.scrubVeil(scrub.d, lead = 0.36, drop = 22f, pull = 6f),
        )

        BoxWithConstraints(Modifier.fillMaxWidth().weight(1f)) {
            val gw = maxWidth.value
            val gh = maxHeight.value
            // สี่คอลัมน์เมื่อเต็มความกว้างการ์ด · สามเมื่อถูกย่อ — ห้าขึ้นไปโลโก้เล็กเกินกว่าตาจะแยกแบรนด์
            val cols = if (gw > 300f) 4 else 3
            val rows = max(1, ceil(t.brands.size.toDouble() / cols).toInt())
            val cw = gw / cols
            val ch = min(cw, gh / rows)

            Column(Modifier.width(gw.dp).align(Alignment.TopStart)) {
                for (r in 0 until rows) {
                    Row {
                        for (c in 0 until cols) {
                            BrandGridCell(t.brands, r, c, cols, rows, cw, ch, scrub.d, ink)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun BrandGridCell(
    brands: List<Brand>, row: Int, col: Int, cols: Int, rows: Int,
    w: Float, h: Float, d: Float, ink: InkStyle,
) {
    val i = row * cols + col
    // คลื่นทแยง: ช่องที่อยู่บนเส้นทแยงเดียวกันดับพร้อมกัน
    val a = Scrub.cell(row + col, cols + rows - 1, d, spill = 1.6).toFloat()
    val hair = ink.line(0.1)
    Box(
        Modifier
            .size(w.dp, h.dp)
            // เส้นผมเฉพาะขอบใน — ขอบนอกปล่อยว่างไว้ให้แผงลอยอยู่บนการ์ด ไม่ใช่กล่องที่มีกรอบ
            .drawWithContent {
                drawContent()
                val px = 0.5.dp.toPx()
                if (col > 0 && i < brands.size) drawRect(hair, size = Size(px, size.height))
                if (row > 0) drawRect(hair, size = Size(size.width, px))
            },
        contentAlignment = Alignment.Center,
    ) {
        if (i < brands.size) {
            BrandPlate(
                brands[i], side = min(w, h) * 0.72f,
                modifier = Modifier.graphicsLayer {
                    alpha = a
                    val s = 0.72f + 0.28f * a
                    scaleX = s
                    scaleY = s
                },
            )
        }
    }
}

/**
 * รางโลโก้เลื่อนเอง — วนไม่รู้จบ ให้การ์ดมีความเคลื่อนไหวโดยไม่กินพื้นที่
 *
 * # ท่าเปลี่ยนหน้า — "กรอตามนิ้ว"
 * รางวิ่งอยู่แล้วตามเวลา ตอนปัดมันเร่ง/ถอยตามนิ้ว (ขับด้วย `ScrubRunner` นาฬิกาต่อเฟรม)
 */
@Composable
fun ProofBrandRail(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val t = Profile.me.creator.track

    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        WidgetLabel(
            "ร่วมงานกับ ${t.brandCount} แบรนด์",
            trailing = { VerifiedBadge() },
            modifier = Modifier.scrubVeil(scrub.d, lead = 0.36, drop = 20f, pull = 6f),
        )

        BoxWithConstraints(Modifier.fillMaxWidth().weight(1f)) {
            val gw = maxWidth.value
            val gh = maxHeight.value
            val side = min(gh, 44f)
            val gap = 8f
            val runWidth = (side + gap) * t.brands.size
            // สำเนาต้องพอคลุมความกว้างกล่อง + หนึ่งชุดที่กำลังเลื่อนออก
            val copies = max(3, ceil(gw / max(runWidth, 1f)).toInt() + 1)

            Box(
                Modifier
                    .size(gw.dp, gh.dp)
                    // ขอบซ้าย-ขวาจางลง ให้โลโก้ "ไหลเข้า-ออก" แทนที่จะโดนตัดกลางตัว
                    .graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen)
                    .drawWithContent {
                        drawContent()
                        drawRect(
                            Brush.horizontalGradient(
                                0f to Color.Transparent, 0.06f to Color.Black,
                                0.94f to Color.Black, 1f to Color.Transparent,
                            ),
                            blendMode = BlendMode.DstIn,
                        )
                    }
                    .clipToBounds(),
                contentAlignment = Alignment.CenterStart,
            ) {
                ScrubRunner(
                    d = scrub.d, runWidth = runWidth,
                    period = t.brands.size * 2.2,
                    pull = 0.5,
                    // นอกระยะแล้วหยุดตีเฟรม — ไม่งั้นหน้าที่มองไม่เห็นยังกิน CPU ทุกเฟรม
                    active = abs(scrub.d) < 1.05f,
                    copies = copies,
                    modifier = Modifier.wrapContentWidth(Alignment.Start, unbounded = true),
                ) {
                    Row(
                        Modifier.padding(end = gap.dp),
                        horizontalArrangement = Arrangement.spacedBy(gap.dp),
                    ) {
                        t.brands.forEach { brand -> BrandPlate(brand, side = side) }
                    }
                }
            }
        }
    }
}

/**
 * เหรียญโลโก้ — วงกลมมีขอบ เรียงเป็นแถวเดียวแนวนอน (แถบ "trusted by" ของเว็บแบรนด์)
 * วงกลมต้องมีพื้นขาว: โลโก้ถูกออกแบบมาให้ยืนบนขาว — PNG หมึกเข้มบนการ์ดมืดจะหายไปทั้งใบ
 *
 * # ท่าเปลี่ยนหน้า — "เหรียญพลิกไล่แถว"
 */
@Composable
fun ProofBrandCoins(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val t = Profile.me.creator.track

    Column(
        modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        CoinsCaption(t.brandCount, ink)

        BoxWithConstraints(Modifier.fillMaxWidth().weight(1f), contentAlignment = Alignment.Center) {
            val gw = maxWidth.value
            val gh = maxHeight.value
            // เหรียญคือวงกลม — รูปทรงไม่เปลี่ยนตามกรอบ ที่เปลี่ยนคือ *จำนวนที่ลงในแถว*
            val cap = min(gh, 58f)
            val d = max(18f, min(cap, (gw - cap * 0.11f) / 2f))
            val gap = max(4f, d * 0.11f)
            // จำนวนวงที่ลงในความกว้างนี้จริง ๆ — เหลือที่ไม่พอก็ตัด ไม่บีบวงให้เล็กลง
            val fit = max(1, ((gw + gap) / (d + gap)).toInt())
            val overflow = t.brands.size > fit
            // เหลือที่ให้วง "+N" หนึ่งช่องเสมอเมื่อโชว์ไม่ครบ — ไม่งั้นคนอ่านนึกว่านี่คือแบรนด์ทั้งหมด
            val shown = t.brands.take(if (overflow) max(1, fit - 1) else fit)
            val extra = t.brandCount - shown.size
            val slots = shown.size + (if (extra > 0) 1 else 0)
            // แถวกินเต็มความกว้างเสมอ — เหรียญคือเนื้อหาของใบนี้ ไม่ใช่ของประดับที่เกาะกลาง
            val spread = if (slots > 1) min(d * 0.7f, max(gap, (gw - d * slots) / (slots - 1))) else gap

            Row(
                horizontalArrangement = Arrangement.spacedBy(spread.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                shown.forEachIndexed { i, brand ->
                    BrandCoin(
                        brand, d, theme, ink,
                        Modifier.scrubLouver(
                            scrub.d, lead = Scrub.lead(i, slots, scrub.d, step = 0.09),
                            angle = 66.0, shrink = 0.14f,
                        ),
                    )
                }
                if (extra > 0) {
                    MoreCoin(
                        extra, d, ink,
                        Modifier.scrubLouver(
                            scrub.d, lead = Scrub.lead(shown.size, slots, scrub.d, step = 0.09),
                            angle = 66.0, shrink = 0.14f,
                        ),
                    )
                }
            }
        }
    }
}

/**
 * บรรทัดกำกับ — **เล็กและเงียบโดยตั้งใจ**
 * คำถามที่คนถือมาคือ "ใครบ้าง" ไม่ใช่ "กี่เจ้า" — ตัวเลขจำนวนจึงเป็นคำกำกับของแถว ไม่ใช่เนื้อหาของแถว
 */
@Composable
private fun CoinsCaption(count: Int, ink: InkStyle) {
    val scrub = LocalPageScrub.current
    val body = sh(10.5f, SHFont.bold)
    val tint = ink.text(0.72)
    Box(Modifier.fillMaxWidth()) {
        Row(
            Modifier
                .align(Alignment.Center)
                .padding(horizontal = 74.dp)
                .scrubVeil(scrub.d, lead = 0.38, drop = 14f, pull = 6f),
            horizontalArrangement = Arrangement.spacedBy(5.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                "Trusted by",
                style = CardFont.serif.font(10.5f, FontWeight.Normal).copy(fontStyle = FontStyle.Italic),
                color = ink.text(0.48),
                maxLines = 1,
                softWrap = false,
            )
            // ตัวเลขยังถอดทีละหลัก — มันคือค่าที่นับได้ ต่อให้ตัวเล็กลงก็ยังเป็นค่า ไม่ใช่คำโปรย
            ScrubDigits("$count", scrub.d, lead = 0.34, step = 0.04, drop = 12f, style = body, color = tint)
            Text("แบรนด์", style = body, color = tint, maxLines = 1, softWrap = false)
        }
        // ป้ายวางทับขอบขวาแบบ overlay — ไม่ดันความสูงของบรรทัดกำกับ
        Box(Modifier.matchParentSize(), contentAlignment = Alignment.CenterEnd) {
            VerifiedBadge(
                Modifier
                    .wrapContentHeight(unbounded = true)
                    .scrubVeil(scrub.d, lead = 0.44, drop = 14f, pull = 6f),
            )
        }
    }
}

/** เหรียญหนึ่งใบ — พื้นขาว · โลโก้เว้นขอบใน · วงขอบไล่เฉดจากสีธีมไปหาเส้นผม */
@Composable
private fun BrandCoin(brand: Brand, d: Float, theme: CardTheme, ink: InkStyle, modifier: Modifier) {
    // พื้นมืดลดความขาวลงนิดเดียวให้วงไม่แผดกว่าตัวการ์ด · พื้นกระดาษใช้ขาวเต็ม
    val fill = if (ink.isLight) Color.White else Color.White.opacity(0.93)
    Box(
        modifier
            .size(d.dp)
            .clip(CircleShape)
            .background(fill)
            .border(
                max(1.2f, d * 0.042f).dp,
                Brush.linearGradient(
                    listOf(theme.accent.opacity(0.75), ink.line(0.22)),
                    start = Offset.Zero, end = Offset.Infinite,
                ),
                CircleShape,
            ),
        contentAlignment = Alignment.Center,
    ) {
        val logo = brand.logo
        if (logo != null) {
            // เว้นขอบในบางที่สุดที่ยังไม่ชนขอบวง — โลโก้คือเนื้อหา ขาวรอบ ๆ คือที่ว่าง
            RemoteLogo(logo, Modifier.padding((d * 0.07f).dp).dataValue())
        } else {
            Text(
                brand.monogram,
                style = sh(d * 0.3f, SHFont.heavy),
                color = Color.Black.opacity(0.5),
                maxLines = 1,
                softWrap = false,
                modifier = Modifier.dataValue(),
            )
        }
    }
}

/** วงปิดท้าย — ไม่ใช่เหรียญ จึงไม่ได้พื้นขาว ต่างกันชัดว่านี่คือ *จำนวนที่เหลือ* */
@Composable
private fun MoreCoin(extra: Int, d: Float, ink: InkStyle, modifier: Modifier) {
    Box(
        modifier
            .size(d.dp)
            .background(ink.fill(0.08), CircleShape)
            .border(max(1f, d * 0.03f).dp, ink.line(0.2), CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            "+$extra",
            style = sh(d * 0.3f, SHFont.bold),
            color = ink.text(0.68),
            maxLines = 1,
            softWrap = false,
        )
    }
}
