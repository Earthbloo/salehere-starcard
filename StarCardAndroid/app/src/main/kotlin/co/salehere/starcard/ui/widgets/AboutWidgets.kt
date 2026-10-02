package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.WidgetLabel
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.Provenance
import co.salehere.starcard.theme.ProvenanceTag
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.editor.EditableParagraph
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import kotlin.math.max

// widget กลุ่ม "เกี่ยวกับฉัน" (= Views/Widgets/AboutWidgets.swift)
//
// "หมวดหมู่ที่สนใจ" เป็นชั้น connected — ค่ามาจากหน้าตั้งค่าโปรไฟล์
// แต่งหน้าตาได้ แต่แก้ค่าบนการ์ดไม่ได้ ไม่งั้นข้อมูลจะขัดกับระบบจับคู่งาน
// (`FlowLayout` · `FlowChips` ของไฟล์นี้อยู่ใน WidgetKit.kt)

// MARK: - แนะนำตัว

/**
 * ย่อหน้าแนะนำตัว — ตัวเดียวในการ์ดที่ครีเอเตอร์พูดด้วยเสียงตัวเองล้วน ๆ
 * วางแบบ standfirst ของนิตยสาร: เส้นสีตั้งนำสายตา ข้อความเยื้องเข้ามา
 *
 * ท่าเปลี่ยนหน้า "เส้นนำหดกลับ" — เส้นสีหดขึ้นจากปลายล่างตามนิ้ว ตัวหนังสือมุดใต้ขอบตามทีหลัง
 */
@Composable
fun AboutText(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val t = Scrub.ease(Scrub.t(scrub.d))

    Row(modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.Top) {
        // เส้นนำ — จางลงตามความสูง ให้บล็อกดูละลายหายไปแทนที่จะจบห้วน ๆ
        Box(
            Modifier
                .width(2.5.dp)
                .fillMaxHeight()
                .graphicsLayer {
                    scaleY = max(0f, 1f - t)
                    transformOrigin = TransformOrigin(0.5f, 0f)
                }
                .background(Brush.verticalGradient(listOf(theme.accent, theme.accent.opacity(0.08))), CircleShape),
        )

        Column(Modifier.weight(1f).fillMaxHeight(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(
                "แนะนำตัว".uppercase(),
                style = sh(9.5f, SHFont.semibold).copy(letterSpacing = 1.4.sp),
                color = theme.accent.opacity(0.85),
                maxLines = 1,
                softWrap = false,
                modifier = Modifier.scrubVeil(scrub.d, lead = 0.3, drop = 18f, pull = 6f),
            )

            // ย่อหน้ากินความสูงที่เหลือทั้งหมดแล้วตัดท้ายด้วย … เมื่อพิมพ์ยาวเกิน
            EditableParagraph(
                field = ProfileField.about,
                style = TextSlotStyle(size = 14f, color = ink.text(0.88), lineSpacing = 7f),
                modifier = Modifier
                    .weight(1f)
                    .scrubVeil(scrub.d, lead = 0.06, drop = 34f, pull = 16f),
            )

            // สายงาน — ฟิลด์ที่สองของสัญญาตระกูล `intro` · ทั้งสองแบบในตระกูลต้องมีเท่ากัน ไม่งั้นสลับแบบแล้วข้อมูลหาย
            EditableText(
                field = ProfileField.tagline,
                style = TextSlotStyle(size = 11f, weight = SHFont.bold, color = theme.accent.opacity(0.85)),
                text = Profile.me.tagline,
                maxLines = 1,
                modifier = Modifier
                    .scrubVeil(scrub.d, lead = 0.0, drop = 24f, pull = 20f)
                    .padding(top = 2.dp),
            )
        }
    }
}

// MARK: - หมวดหมู่ที่สนใจ

/**
 * หมวดหมู่ทางการของแพลตฟอร์ม — ต่างจาก "สายงาน" ที่ครีเอเตอร์พิมพ์เอง
 * ติดป้ายที่มาเพราะเป็นค่าที่ระบบใช้จับคู่งานจริง ไม่ใช่คำโปรยที่เขียนเอง
 *
 * ท่าเปลี่ยนหน้า "ชิปร่วงทีละเม็ด" — ชิปมุดใต้บรรทัดของตัวเองไล่กันตามทิศ ไม่ใช่ทั้งกลุ่มเลื่อนเป็นแผ่นเดียว
 */
@Composable
fun InterestTags(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val items = Profile.me.creator.interests

    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(11.dp)) {
        // หมวดหมู่ทางการมาจากโปรไฟล์ในระบบ — บอกที่มาด้วยป้าย ไม่ใช่ตราติ๊กที่ไม่รู้ว่าใครติ๊ก
        WidgetLabel(
            text = "หมวดหมู่ที่สนใจ",
            trailing = { ProvenanceTag(kind = Provenance.profile) },
            modifier = Modifier.scrubVeil(scrub.d, lead = 0.34, drop = 20f, pull = 6f),
        )

        Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.CenterStart) {
            FlowLayout(spacing = 7f) {
                items.forEachIndexed { i, name ->
                    val glow = theme.accent.opacity(0.22)
                    Text(
                        name,
                        style = sh(12f, SHFont.semibold),
                        color = ink.text(0.95),
                        maxLines = 1,
                        softWrap = false,
                        modifier = Modifier
                            .scrubVeil(scrub.d, lead = Scrub.lead(i, items.size, scrub.d, 0.07), drop = 26f, pull = 10f)
                            // เรืองอ่อน ๆ ใต้ชิป ให้ลอยขึ้นจากพื้นการ์ดแทนที่จะแบนติดกัน
                            .shadow(8.dp, CircleShape, clip = false, ambientColor = glow, spotColor = glow)
                            .background(
                                Brush.linearGradient(
                                    listOf(theme.accent.opacity(0.28), theme.accent.opacity(0.1)),
                                    start = Offset.Zero, end = Offset.Infinite,
                                ),
                                CircleShape,
                            )
                            .border(0.6.dp, theme.accent.opacity(0.34), CircleShape)
                            .padding(horizontal = 12.dp, vertical = 7.dp),
                    )
                }
            }
        }
    }
}
