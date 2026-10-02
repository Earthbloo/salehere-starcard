package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.legibilityHalo
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Profile
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.TextAlignment
import co.salehere.starcard.theme.TextFit
import co.salehere.starcard.ui.LocalCanvasTyping
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalPageContentWidth
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.TextBlockWeight

// MARK: - ข้อความล้วน (= Views/Widgets/TextWidgets.swift)
//
// ทุกใบในตู้ตอบ *คำถามที่รู้ล่วงหน้า* — ใบนี้มีข้อเดียว: **ตัวอักษรที่เจ้าของการ์ดคุมได้ทั้งหมด** ไม่มีของแถมสักชิ้น
// ฟอนต์ · สี · การจัดวาง เก็บใน `WidgetInstance.textStyle` · **ขนาดปรับที่หมุดมุมของกล่อง** (`points`)
// **ไม่ตัดบรรทัดเอง** — บรรทัดใหม่มีเฉพาะที่ผู้ใช้กด Return · ยาวจนล้นหน้าค่อยหดขนาดให้ชั่วคราว (ดู `TextFit`)
// ท่าเปลี่ยนหน้า "บรรทัดมุดใต้ขอบตัวเอง" — ท่าเดียวกับข้อความก้อนอื่นทั้งการ์ด (`scrubVeil`) โดยตั้งใจ
//
// ค่าคงที่ `TextBlock.inset/radius` อยู่ใน `TextBlockSpec` (WidgetChrome.kt) · `TextBlock.weight` = `TextBlockWeight` (TextTools.kt)

/** ตัวอย่างในตู้ — สองบรรทัดที่บอกว่าใบนี้ทำอะไรได้ โดยไม่ต้องมีป้ายกำกับ */
private const val TextBlockSample = "เขียนอะไรก็ได้\nยืดกล่องแล้วตัวอักษรโตตาม"

/** เกณฑ์ตัวใหญ่ของ WCAG (ราว 18pt ตัวหนา) — ตัวขนาดนี้ขึ้นไปอ่านออกที่ contrast 3:1 (= `TextBlock.isLarge`) */
private fun textBlockIsLarge(points: Float): Boolean = points >= 20f

/**
 * ข้อความอิสระหนึ่งก้อน — ทั้งใบคือตัวอักษรที่แก้ได้ก้อนเดียว
 * ข้อความเก็บต่อ **ชิ้น** ไม่ใช่ต่อตระกูล (ดู `ProfileField.note`) — id ของชิ้นมาทาง `LocalWidgetID`
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun TextBlock(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val accent = LocalCardAccent.current
    val wid = LocalWidgetID.current
    val spec = LocalWidgetTextStyle.current
    // กำลังถูกพิมพ์บนการ์ดอยู่ — ตัวอักษรหลบให้ `CanvasTextField` ที่ทับตำแหน่งเดียวกันพอดี
    val typing = LocalCanvasTyping.current
    val pageW = LocalPageContentWidth.current
    val density = LocalDensity.current.density
    val measurer = TextFit.rememberMeasurer()

    val text = if (wid == null) TextBlockSample else Profile.me.note(wid)

    // ขนาดที่ใช้จริง — ตามที่ตั้ง เว้นแต่บรรทัดยาวเกิน **หน้า** จึงหดพอดี
    // คิดจากความกว้างหน้า ไม่ใช่ความกว้างกล่อง — กล่องถูกคิดจากตัวเลขนี้อีกที ถ้าย้อนกลับไปพึ่งกล่องจะวนเป็นงู
    val fitted = TextFit.capped(measurer, spec.points, text, spec.face, TextBlockWeight, pageW - TextBlockSpec.inset * 2)

    val large = textBlockIsLarge(fitted)
    // สีที่เลือกคือคำขอ — สีที่วาดคือเวอร์ชันที่อ่านออกบนพื้นการ์ดตอนนี้ (ดู `TextTint.color`)
    val color = spec.tint.color(ink, accent, large)
    val halo = spec.tint.halo(ink, large)
    val style = spec.face.font(fitted, TextBlockWeight).legibilityHalo(halo, fitted, density)
    val gap = fitted * TextFit.spacing

    Box(
        modifier
            .fillMaxSize()
            .scrubVeil(scrub.d, lead = 0.1, drop = 26f, pull = 12f),
    ) {
        if (typing) {
            // ช่องพิมพ์บนการ์ด *คือ* ตัวอักษรตอนนี้ — วาดซ้ำจะเห็นสองชั้นเหลื่อมกัน
        } else if (wid == null) {
            // พรีวิวในตู้ — ไม่มีกล่องที่วัดจากหมึก แค่วางกลางช่องให้ดูออกว่าเป็นอะไร
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                TextBlockLines(
                    text = text, style = style, color = color, gap = gap, align = spec.align,
                    modifier = Modifier.wrapContentSize(Alignment.Center, unbounded = true),
                )
            }
        } else {
            val m = TextFit.metrics(measurer, text, spec.face, TextBlockWeight, fitted, spec.align)
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.TopStart) {
                // กล่องถูกวัดจาก **หมึก** (ดู `TextFit.metrics`) — เลื่อน line box ให้หมึกชิดมุมบนซ้ายพอดี
                // ห้ามตัดบรรทัดเอง — ทั้งสองแกนคงขนาดธรรมชาติ บรรทัดใหม่มีเฉพาะที่พิมพ์ไว้
                Box(
                    Modifier
                        .offset((-m.ink.left).dp, (-m.ink.top).dp)
                        .wrapContentSize(Alignment.TopStart, unbounded = true)
                        .requiredSize(m.typo.width.dp, m.typo.height.dp),
                    contentAlignment = Alignment.TopStart,
                ) {
                    TextBlockLines(
                        text = text, style = style, color = color, gap = gap, align = spec.align,
                        modifier = Modifier.fillMaxSize(),
                    )
                }
            }
        }
    }
}

/**
 * วางทีละบรรทัดตามที่ `TextFit.metrics` วัด — กล่องบรรทัดธรรมชาติ คั่นด้วย `gap` จัดวางในความกว้างของบรรทัดที่ยาวที่สุด
 * (= `Text.lineSpacing(fitted * TextFit.spacing).fixedSize()` — วาดแยกบรรทัดให้ตรงกับกล่องที่ชั้นการ์ดคิดไว้ทุกพิกเซล)
 */
@Composable
private fun TextBlockLines(
    text: String,
    style: TextStyle,
    color: Color,
    gap: Float,
    align: TextAlignment,
    modifier: Modifier = Modifier,
) {
    val lines = if (text.isEmpty()) listOf(" ") else text.split("\n")
    val horizontal = when (align) {
        TextAlignment.leading -> Alignment.Start
        TextAlignment.center -> Alignment.CenterHorizontally
        TextAlignment.trailing -> Alignment.End
    }
    Column(modifier, verticalArrangement = Arrangement.spacedBy(gap.dp), horizontalAlignment = horizontal) {
        lines.forEach { l ->
            Text(
                if (l.isEmpty()) " " else l,
                style = style.copy(textAlign = align.text),
                color = color,
                maxLines = 1,
                softWrap = false,
            )
        }
    }
}
