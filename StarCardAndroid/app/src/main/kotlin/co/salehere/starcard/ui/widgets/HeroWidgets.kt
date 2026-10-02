package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.StarLockup
import co.salehere.starcard.theme.StarSeal
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import kotlin.math.max

// MARK: - Minimal (ชื่อตัวใหญ่ ไม่มีรูป) (= Views/Widgets/HeroWidgets.swift)

/**
 * # ท่าเปลี่ยนหน้า — "ตัวอักษรคลี่ออกจากกัน"
 *
 * widget ตัวหนังสือล้วนไม่มีรูปให้ดอลลี่และไม่มีช่องให้หุบ ท่าจึงต้องอยู่ในตัวอักษรเอง:
 * **ระยะห่างตัวอักษรคลายออกตามนิ้ว** ก่อนบรรทัดจะมุดใต้ขอบ — ชื่อคลายตัวออกแล้วค่อยจากไป
 */
@Composable
fun HeroMinimal(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val nameSize = if (size.width < 260f) 30f else 40f

    // เทรนด์ 2026 · Oversized editorial type — ชื่อคือพระเอก ตัวหนาเต็มที่ ระยะตัวอักษรบีบ
    // คู่กับบรรทัดเล็กที่ปล่อย tracking กว้าง ให้คอนทราสต์ของ "ก้อนใหญ่ปะทะเส้นบาง"
    // จัดกลางแนวตั้ง — ตอนถูกยืดสูงกว่าข้อความ ช่องว่างแบ่งบนล่างเท่ากัน ไม่กองอยู่ท้ายกล่อง
    Column(
        modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.Start,
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(7.dp), verticalAlignment = Alignment.CenterVertically) {
            val lineT = Scrub.ease(Scrub.t(scrub.d, 0.05))
            Box(Modifier.size(14.dp, 2.dp), contentAlignment = Alignment.CenterStart) {
                Box(Modifier.size(max(0f, 14f * (1f - lineT)).dp, 2.dp).background(theme.accent, CircleShape))
            }
            // ชื่อโปรแกรมตัวจริง ไม่ใช่คำว่า STARCARD — บรรทัดนี้คือที่ที่การ์ดบอกว่าใครออกให้
            StarLockup(
                height = 12f,
                tint = theme.accent.opacity(0.95),
                modifier = Modifier.scrubVeil(scrub.d, lead = 0.06, drop = 16f, pull = 14f),
            )
            // ตรายืนยันตัวตนติดมากับชื่อเสมอ ไม่ใช่ widget แยก
            if (Profile.me.creator.verified) {
                StarSeal(
                    size = 11f,
                    tint = theme.accent.opacity(0.95),
                    modifier = Modifier.scrubVeil(scrub.d, lead = 0.04, drop = 14f, pull = 10f),
                )
            }
        }

        // บีบอยู่ตอนนิ่ง แล้วคลายออกตอนจากไป · ยาวเกินสองบรรทัดตัดด้วย … ไม่ดัน widget ให้สูงขึ้น
        val t = Scrub.ease(Scrub.t(scrub.d, 0.1))
        EditableText(
            field = ProfileField.personName,
            style = TextSlotStyle(size = nameSize, weight = SHFont.black, color = ink.text(0.98), tracking = -1f + 9f * t),
            maxLines = 2,
            softWrap = true,
            modifier = Modifier
                .scrubVeil(scrub.d, lead = 0.24, drop = 44f, pull = 8f)
                .fillMaxWidth(),
        )

        EditableText(
            field = ProfileField.tagline,
            style = TextSlotStyle(
                size = 9.5f, weight = SHFont.semibold, color = ink.text(0.45),
                tracking = 2f, uppercase = true,
            ),
            modifier = Modifier.scrubVeil(scrub.d, lead = 0.02, drop = 22f, pull = 18f),
        )
    }
}
