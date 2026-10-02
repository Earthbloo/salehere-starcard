package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.ScrubDigits
import co.salehere.starcard.components.WidgetLabel
import co.salehere.starcard.components.scrubLouver
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.SocialProfile
import co.salehere.starcard.theme.BrandIcon
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.Provenance
import co.salehere.starcard.theme.ProvenanceTag
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.editor.dataValue

// (= Views/Widgets/SocialWidgets.swift)

/**
 * ยอดผู้ติดตามแยกรายแพลตฟอร์ม พร้อมตัวเลขที่บอกคุณภาพของช่อง
 * ต้องแยกช่อง ไม่ใช่รวมเป็นตัวเลขเดียว เพราะแบรนด์เลือกช่องก่อนเลือกคน
 *
 * สามแถวเรียงลงได้ความกว้างเต็มการ์ดต่อหนึ่งช่อง ตัวเลขทุกตัวจึงเขียนเต็มได้
 * และ **ทุกค่ามีไอคอนกำกับ** — เลขลอย ๆ สามตัวในแถวเดียวไม่มีทางรู้ว่าตัวไหนคืออะไร
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun SocialChips(theme: CardTheme, width: Float, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val socials = Profile.me.creator.socials
    // แคบมากถึงจะยอมตัดค่ารองทิ้ง — ที่ความกว้างครึ่งการ์ดยังใส่ได้ครบ
    val tight = width < 190f

    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        WidgetLabel(
            text = "ผู้ติดตาม",
            trailing = { ProvenanceTag(kind = socials.provenance) },
            modifier = Modifier.scrubVeil(scrub.d, lead = 0.36, drop = 20f, pull = 6f),
        )

        Column(Modifier.weight(1f).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            socials.forEachIndexed { i, s ->
                Box(
                    Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .linkSlot(s.profileURL),
                    contentAlignment = Alignment.Center,
                ) {
                    SocialChipRow(s, i, socials.size, tight)
                }
            }
        }
    }
}

@Composable
private fun SocialChipRow(s: SocialProfile, i: Int, count: Int, tight: Boolean) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val lead = Scrub.lead(i, count, scrub.d, 0.09)

    Row(
        Modifier
            .fillMaxWidth()
            // กล่องไปทีหลังของข้างในเสมอ
            .scrubVeil(scrub.d, lead = lead + 0.16, drop = 34f, pull = 12f)
            .socialPlate(s, ink)
            .padding(horizontal = 11.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        SocialBadge(s, lead)

        Column(Modifier.weight(1f)) {
            ScrubDigits(
                text = Fmt.compact(s.followerCount), d = scrub.d,
                lead = lead + 0.04, step = 0.05, drop = 22f,
                style = sh(17f, SHFont.heavy), color = ink.text(0.98),
            )
            Text(
                s.type.name,
                style = sh(9.5f, SHFont.medium),
                color = ink.text(0.42),
                maxLines = 1,
                softWrap = false,
                autoSize = TextAutoSize.StepBased(minFontSize = (9.5f * 0.7f).sp, maxFontSize = 9.5.sp, stepSize = 0.5.sp),
                modifier = Modifier.scrubVeil(scrub.d, lead = lead, drop = 16f, pull = 8f),
            )
        }

        // `Spacer(minLength: 6)` — ช่องที่เหลือไปอยู่กับคอลัมน์ตัวเลขที่ชิดซ้ายอยู่แล้ว เหลือไว้แค่ระยะขั้นต่ำ
        Spacer(Modifier.width(6.dp))

        if (!tight && s.source.isVerified && s.avgViewCount > 0) {
            // ค่าที่บอก "คุณภาพของช่อง" — ไอคอนนำหน้าทุกตัว
            Row(horizontalArrangement = Arrangement.spacedBy(11.dp), verticalAlignment = Alignment.CenterVertically) {
                SocialMetric(Fmt.compact(s.avgViewCount), ink.text(0.55), ink, lead)
                // ER ใช้ "คำ" ไม่ใช่ไอคอน — หัวใจอ่านออกมาเป็น "ยอดไลก์" ซึ่งไม่ใช่สิ่งเดียวกัน
                SocialTagged("ER", Fmt.pct(s.engagementRate), s.type.tint, ink, lead + 0.03)
            }
        } else if (!tight) {
            // ยอดที่กรอกเองไม่มีวิว/ER จริง · เชื่อมแล้วแต่ยังไม่ซิงก์ก็ยังไม่มี — บอกตรง ๆ ว่ารออะไรอยู่ ไม่ใช่โชว์ 0
            Text(
                if (s.source.isVerified) "รอซิงก์ข้อมูล" else "รอเชื่อมบัญชี",
                style = sh(10f, SHFont.semibold),
                color = ink.text(0.42),
                maxLines = 1,
                softWrap = false,
                modifier = Modifier
                    .wrapContentSize()
                    .scrubVeil(scrub.d, lead = lead, drop = 18f, pull = 10f),
            )
        }
    }
}

/** ค่าที่มี "คำ" นำหน้าแทนไอคอน — ใช้กับค่าที่ไม่มีสัญลักษณ์สากล */
@Composable
private fun SocialTagged(label: String, value: String, tint: Color, ink: InkStyle, lead: Double) {
    val scrub = LocalPageScrub.current
    Row(
        Modifier
            .wrapContentSize()
            .scrubVeil(scrub.d, lead = lead, drop = 18f, pull = 10f),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            label,
            style = sh(9.5f, SHFont.black).copy(letterSpacing = 0.3.sp),
            color = tint.opacity(0.9),
            maxLines = 1,
            softWrap = false,
        )
        Text(
            value,
            style = sh(12f, SHFont.bold),
            color = ink.text(0.88),
            maxLines = 1,
            softWrap = false,
            modifier = Modifier.dataValue(),
        )
    }
}

/** หนึ่งค่า = ไอคอน + ตัวเลข · ใช้กับค่าที่ไอคอนสื่อได้จริง (▶ = วิว) */
@Composable
private fun SocialMetric(value: String, tint: Color, ink: InkStyle, lead: Double) {
    val scrub = LocalPageScrub.current
    Row(
        Modifier
            .wrapContentSize()
            .scrubVeil(scrub.d, lead = lead, drop = 18f, pull = 10f),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ViewsPlayGlyph(size = 9f, tint = tint.copy(alpha = tint.alpha * 0.85f))
        Text(
            value,
            style = sh(12f, SHFont.bold),
            color = ink.text(0.88),
            maxLines = 1,
            softWrap = false,
            modifier = Modifier.dataValue(),
        )
    }
}

/**
 * ▶ ของยอดวิว (= `play.fill`) — วาดเอง เพราะตาราง SF→Phosphor แทน play ด้วยกล้องวิดีโอ ซึ่งอ่านเป็น "ช่องวิดีโอ" ไม่ใช่ "ยอดวิว"
 */
@Composable
private fun ViewsPlayGlyph(size: Float, tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier.size(size.dp)) {
        val s = this.size.width
        val p = Path().apply {
            moveTo(s * 0.2f, s * 0.1f)
            lineTo(s * 0.9f, s * 0.5f)
            lineTo(s * 0.2f, s * 0.9f)
            close()
        }
        drawPath(p, tint, style = Fill)
        drawPath(p, tint, style = Stroke(width = s * 0.1f, join = StrokeJoin.Round))
    }
}

/** ช่องไอคอนแพลตฟอร์ม — พื้นย้อมสีประจำแพลตฟอร์มบาง ๆ · พลิกเป็นบานพับตามนิ้ว */
@Composable
private fun SocialBadge(s: SocialProfile, lead: Double) {
    val scrub = LocalPageScrub.current
    val shape = RoundedCornerShape(9.dp)
    Box(
        Modifier
            .size(34.dp)
            .scrubLouver(scrub.d, lead = lead, angle = 70.0, shrink = 0.2f)
            .background(s.type.tint.opacity(0.16), shape)
            .border(0.6.dp, s.type.tint.opacity(0.28), shape),
        contentAlignment = Alignment.Center,
    ) {
        BrandIcon(s.type.icon, size = 17f)
    }
}

/**
 * แผ่นของหนึ่งช่องทาง — เทรนด์ 2026 · Surface elevation ในธีมมืดใช้ "ผิวสว่างขึ้น + เรืองแสงประจำแพลตฟอร์ม" แทนเงาดำ
 * พื้นกระดาษกลับกันเป๊ะ: ยกด้วยแผ่นขาวทึบ + เงาจริง ส่วนผิวสว่างขึ้นจะจมหายไปกับพื้น
 */
private fun Modifier.socialPlate(s: SocialProfile, ink: InkStyle): Modifier {
    val shape = RoundedCornerShape(15.dp)
    val glow = s.type.tint.opacity(if (ink.isLight) 0.16 else 0.28)
    // `ink.lift.opacity(0.5)` ของ SwiftUI คูณความทึบเดิม — พื้นมืด lift ใส (ไม่มีเงา) · พื้นกระดาษดำ 0.18 → 0.09
    val lift = ink.lift.copy(alpha = ink.lift.alpha * 0.5f)
    val fill = if (ink.isLight) listOf(Color.White.opacity(0.92), Color.White.opacity(0.7))
    else listOf(Color.White.opacity(0.1), Color.White.opacity(0.045))
    return this
        .shadow((ink.liftRadius * 0.6f).dp, shape, clip = false, ambientColor = lift, spotColor = lift)
        .shadow(10.dp, shape, clip = false, ambientColor = glow, spotColor = glow)
        .background(Brush.verticalGradient(fill), shape)
        .border(
            0.8.dp,
            Brush.linearGradient(listOf(s.type.tint.opacity(0.4), ink.line(0.06)), start = Offset.Zero, end = Offset.Infinite),
            shape,
        )
}

// MARK: - ผู้ติดตามแบบชิป

/**
 * สามช่องทางเรียงข้างกัน — **ยอดฟอลโลว์อย่างเดียว ไม่มีค่ารอง**
 * แถวตอบคำถาม "ช่องไหนดี" (มี ER กับยอดวิว) · ชิปตอบคำถาม "มีช่องอะไรบ้าง"
 *
 * ท่าเปลี่ยนหน้า "ตัวเลขไปก่อน การ์ดไปทีหลัง" — ยอดถูกถอดออกทีละหลักก่อน แล้วแผ่นทั้งใบถึงค่อยมุดใต้ขอบตามไป
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun SocialTiles(theme: CardTheme, width: Float, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val socials = Profile.me.creator.socials

    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        WidgetLabel(
            text = "ผู้ติดตาม",
            trailing = { ProvenanceTag(kind = socials.provenance) },
            modifier = Modifier.scrubVeil(scrub.d, lead = 0.36, drop = 20f, pull = 6f),
        )

        Row(
            Modifier.weight(1f).fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            socials.forEachIndexed { i, s ->
                val lead = Scrub.lead(i, socials.size, scrub.d, 0.09)
                Row(
                    Modifier
                        .weight(1f)
                        .heightIn(max = 64.dp)
                        .fillMaxHeight()
                        .linkSlot(s.profileURL)
                        // กล่องไปทีหลังของข้างในเสมอ
                        .scrubVeil(scrub.d, lead = lead + 0.16, drop = 34f, pull = 12f)
                        .socialPlate(s, ink)
                        .padding(horizontal = 10.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(9.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    SocialBadge(s, lead)
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                        ScrubDigits(
                            text = Fmt.compact(s.followerCount), d = scrub.d,
                            lead = lead + 0.04, step = 0.05, drop = 22f,
                            style = sh(16f, SHFont.bold), color = ink.text(0.98),
                        )
                        Text(
                            s.type.name,
                            style = sh(9f, SHFont.medium),
                            color = ink.text(0.42),
                            maxLines = 1,
                            softWrap = false,
                            autoSize = TextAutoSize.StepBased(minFontSize = (9f * 0.7f).sp, maxFontSize = 9.sp, stepSize = 0.5.sp),
                            modifier = Modifier.scrubVeil(scrub.d, lead = lead, drop = 16f, pull = 8f),
                        )
                    }
                }
            }
        }
    }
}

// MARK: - ที่มาของยอดทั้งชุด

/**
 * ป้ายที่มาของ widget ผู้ติดตาม — ทุกช่องยืนยันแล้วถึงจะได้ป้ายเขียว (= `Array<SocialProfile>.provenance`)
 * มีช่องที่กรอกเองปนอยู่แม้ช่องเดียว ป้ายต้องบอกว่า "รอตรวจสอบ" (ป้ายเขียวคลุมเลขที่ยังไม่ตรวจ = การ์ดโกหก)
 */
val List<SocialProfile>.provenance: Provenance
    get() {
        // โต๊ะตรวจงานบังคับสถานะ "ยอดจากแพลตฟอร์ม" ได้ (ดู `VerifiedFacts.labForce`)
        if (VerifiedFacts.labForce && isNotEmpty()) return Provenance.Connected(firstOrNull()?.syncedAgo ?: "2 ชม.")
        if (isEmpty() || !all { it.source.isVerified }) return Provenance.manual
        return Provenance.Connected(firstOrNull()?.syncedAgo ?: "วันนี้")
    }
