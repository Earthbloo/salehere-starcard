package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.WidgetLabel
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle

// (= Views/Widgets/ContentWidgets.swift)

/**
 * สายงานที่ครีเอเตอร์พิมพ์เอง
 *
 * ท่าเปลี่ยนหน้า "ชิปปลิวออกข้าง" — จงใจให้ต่างจาก "หมวดหมู่ที่สนใจ" ที่ชิป**ร่วงลง**
 * ตัวนี้ชิป**ปลิวออกข้าง**ไล่กัน สลับสองแบบในการ์ดใบเดียวแล้วยังอ่านเป็นภาษาเดียวกัน
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun NicheTags(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val items = Profile.me.categories

    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(11.dp)) {
        WidgetLabel(
            text = "สายงาน",
            modifier = Modifier.scrubVeil(scrub.d, lead = 0.34, drop = 20f, pull = 6f),
        )

        // ต้องใช้ FlowLayout — กริดคอลัมน์ตายตัวดันชิปสั้นห่างจากตัวถัดไปจนอ่านเป็นตาราง ไม่ใช่แท็ก
        Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.TopStart) {
            // ลบชิปออกหนึ่งใบแล้วลำดับที่เหลือเลื่อน — ผูก key กับลิสต์ให้สร้างใหม่ทั้งแถว ไม่งั้นชิปใบถัดไปจะถือ index เดิมแล้วแก้ผิดใบ
            key(items) {
                FlowLayout(spacing = 7f) {
                    items.forEachIndexed { i, t ->
                        Box(
                            Modifier
                                .scrubSlide(
                                    scrub.d,
                                    travel = 60f + i * 10f,
                                    lead = Scrub.lead(i, items.size, scrub.d, 0.06),
                                    fade = 0.55,
                                )
                                .background(ink.fill(0.07), CircleShape)
                                .border(0.6.dp, ink.line(0.16), CircleShape)
                                .padding(horizontal = 12.dp, vertical = 7.dp),
                        ) {
                            // ลบข้อความจนหมดแล้วปิดช่อง = เอาชิปใบนั้นออก (ดู `Profile.commit`)
                            EditableText(
                                field = ProfileField.categories,
                                index = i,
                                style = TextSlotStyle(size = 12f, weight = SHFont.semibold, color = ink.text(0.92), corner = 10f),
                                text = t,
                                maxLines = 1,
                            )
                        }
                    }
                }
            }
        }
    }
}
