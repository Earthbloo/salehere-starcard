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
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.BlurredEdgeTreatment
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.ArchShape
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.ScrubDigits
import co.salehere.starcard.components.WidgetLabel
import co.salehere.starcard.components.redacted
import co.salehere.starcard.components.scrubAperture
import co.salehere.starcard.components.scrubDolly
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.LocalWidgetEmboss
import co.salehere.starcard.model.LocalWidgetEmbossBlind
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.SocialProfile
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.BrandIcon
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.EmbossedLockup
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.StarSeal
import co.salehere.starcard.theme.SymbolIcon
import co.salehere.starcard.theme.Tinted
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalGhostData
import co.salehere.starcard.ui.LocalSlotTilt
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import co.salehere.starcard.ui.editor.dataValue
import co.salehere.starcard.ui.editor.editableSlot
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

// MARK: - สำรับ Gen Z (= Views/Widgets/GenZWidgets.swift)
//
// สี่แบบในไฟล์นี้ไม่ได้เพิ่ม "ข้อมูลใหม่" — ทุกตัวเล่าเรื่องเดียวกับแบบที่มีอยู่แล้วในตระกูลของมัน
// ที่ต่างคือ **สำเนียง**: ออร่า · การ์ดสรุปยอดปลายปี · สติปรูดจากตู้ถ่ายรูป · สติกเกอร์นูน
//
// 1. **หนึ่งแบบ หนึ่งวัสดุ** — ห้ามผสมสองวัสดุในตัวเดียว
// 2. **ท่าเปลี่ยนหน้าต้องมาจากวัสดุนั้น** — สติกเกอร์ต้อง *ลอก* · แผ่นภาพต้อง *ไถลออกจากช่องจ่าย* ทั้งแผ่น
// สีของวัสดุที่เป็น "ของจับต้องได้" ไม่ผูกกับ `cardInk` โดยตั้งใจ — โน้ตที่พลิกเป็นสีดำตามการ์ดเสียอุปมาไปทันที

/** วัสดุของสำรับนี้ — สีคงที่ ไม่พลิกตามหมึกการ์ด */
private object Vinyl {
    /** กระดาษโน้ตสีมัสตาร์ด */
    val sticky = rgb(1.00, 0.93, 0.62)
    val stickyDeep = rgb(0.98, 0.85, 0.44)
    /** กระดาษภาพจากตู้ถ่ายรูป */
    val photoPaper = rgb(0.98, 0.98, 0.97)
    /** หมึกดำอมม่วง — ดำสนิทบนสีสดอ่านแข็งเกินไป */
    val ink = rgb(0.10, 0.07, 0.14)
    val inkSoft = rgb(0.38, 0.33, 0.44)
    /** ปากกาไฮไลต์ */
    val marker = rgb(0.62, 0.96, 0.72)
}

// MARK: - 01 · ออร่า

/**
 * รูปโปรไฟล์ในซุ้มโค้ง ลอยอยู่กลางดวงแสงสามดวงที่เป็นสีของธีม
 * เทรนด์ 2026 · Aura photo — แสงรอบตัวคือบุคลิก ไม่ใช่ฉากหลัง จึงเป็น hero ที่ใช้ตัวหนังสือน้อยที่สุดในชุด
 *
 * ท่าเปลี่ยนหน้า "ออร่าหมุนสวนตัวคน" — ดวงแสงหมุนไปทางเดียวกับหน้าและบานออก ตัวคนถ่วงสวนทาง
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun HeroAura(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    BoxWithConstraints(modifier.fillMaxSize()) {
        val w = maxWidth.value
        val h = maxHeight.value
        // แถบชื่อกินที่คงที่ ที่เหลือเป็นของภาพทั้งหมด — ภาพคือพระเอกของ hero ทุกตัว
        val footer = min(78f, h * 0.26f)
        val stage = max(60f, h - footer)
        val archW = min(w * 0.68f, stage * 0.82f)

        Column(Modifier.wrapContentSize(Alignment.TopStart, unbounded = true)) {
            Box(Modifier.requiredSize(w.dp, stage.dp), contentAlignment = Alignment.Center) {
                AuraGlow(theme, w, stage)
                AuraArch(theme, archW, stage)
            }
            Box(Modifier.requiredSize(w.dp, footer.dp), contentAlignment = Alignment.TopStart) {
                AuraNameBlock(theme, w)
            }
        }
    }
}

/**
 * ดวงแสงสามดวง — สีธีมดิบสองดวง ขาวหนึ่งดวง
 * ใช้สีดิบ (`rawAccent`) เพราะดวงแสงคือ *แหล่งกำเนิดแสง* ไม่ใช่หมึกที่เขียนบนการ์ด
 */
@Composable
private fun AuraGlow(theme: CardTheme, w: Float, h: Float) {
    val scrub = LocalPageScrub.current
    val r = min(w, h)
    val t = Scrub.ease(Scrub.t(scrub.d))
    val s = Scrub.dir(scrub.d)
    // ผืนวาดใหญ่กว่าเวที — ดวงแสงที่เยื้องออกไปกับรัศมีฟุ้งต้องไม่ถูกตัดขอบเป็นเส้นตรง
    val pad = r * 0.7f
    val a = theme.rawAccent.opacity(0.95)
    val b = theme.rawAccentSoft.opacity(0.9)
    val c = Color.White.opacity(0.45)
    Box(Modifier.requiredSize(w.dp, h.dp), contentAlignment = Alignment.Center) {
        Canvas(
            Modifier
                .requiredSize((w + pad * 2f).dp, (h + pad * 2f).dp)
                .graphicsLayer {
                    rotationZ = s * 34f * t
                    scaleX = 1f + 0.22f * t
                    scaleY = 1f + 0.22f * t
                    alpha = (0.9 * Scrub.fade(t, 0.72)).toFloat()
                }
                // ฟุ้งแรงพอให้ไม่เห็นขอบวงกลม แต่ไม่แรงจนสามดวงละลายเป็นดวงเดียว (ที่ r * 0.17 สีของธีมหายไปหมด)
                .blur((r * 0.13f).dp, BlurredEdgeTreatment.Unbounded),
        ) {
            val u = density
            val o = center
            drawCircle(a, radius = r * 0.39f * u, center = o + Offset(-r * 0.3f * u, -r * 0.2f * u))
            drawCircle(b, radius = r * 0.34f * u, center = o + Offset(r * 0.32f * u, r * 0.02f * u))
            drawCircle(c, radius = r * 0.21f * u, center = o + Offset(0f, r * 0.3f * u))
        }
    }
}

/** ตัวคนในซุ้มโค้ง — ทรงเดียวกับที่งานพอร์ตสายแฟชั่นใช้ ไม่ใช่วงกลม avatar */
@Composable
private fun AuraArch(theme: CardTheme, width: Float, height: Float) {
    val scrub = LocalPageScrub.current
    val shape = ArchShape(footRadius = 14f)
    val glow = theme.rawAccent.opacity(0.45)
    Box(Modifier.requiredSize(width.dp, (height * 0.92f).dp)) {
        Box(
            Modifier
                .fillMaxSize()
                .shadow(22.dp, shape, clip = false, ambientColor = glow, spotColor = glow)
                .photoSlot(1)
                .border(1.dp, Color.White.opacity(0.55), shape)
                .clip(shape),
        ) {
            Box(Modifier.fillMaxSize().scrubDolly(scrub.d, shift = width * 0.09f, zoom = 0.2f)) {
                WidgetPhoto(1, Modifier.fillMaxSize())
            }
        }
        AuraSparkle(size = 15f, lead = 0.06, modifier = Modifier.align(Alignment.TopEnd))
        AuraSparkle(size = 11f, lead = 0.2, modifier = Modifier.align(Alignment.BottomStart))
    }
}

/** ประกายที่มุมซุ้ม — หมุนสวนทางกันคนละดวงเพื่อไม่ให้อ่านเป็นไอคอนคู่แฝด */
@Composable
private fun AuraSparkle(size: Float, lead: Double, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val t = Scrub.ease(Scrub.t(scrub.d, lead))
    val dir = Scrub.dir(scrub.d)
    Box(
        modifier
            .padding(6.dp)
            .size(size.dp)
            .graphicsLayer {
                rotationZ = dir * 90f * t
                scaleX = 1f - 0.6f * t
                scaleY = 1f - 0.6f * t
                alpha = Scrub.fade(t, 0.5).toFloat()
            },
    ) {
        SymbolIcon(SHIcon.sparkle, size = size, tint = Color.White)
    }
}

@Composable
private fun AuraNameBlock(theme: CardTheme, w: Float) {
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    Column(
        Modifier
            .fillMaxWidth()
            .wrapContentHeight(Alignment.Top, unbounded = true)
            .padding(top = 10.dp),
        verticalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .scrubVeil(scrub.d, lead = 0.24, drop = 34f, pull = 8f),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            AuraName(theme, w, Modifier.weight(1f, fill = false))
            if (Profile.me.creator.verified) {
                StarSeal(size = 12f, tint = ink.text(0.98), punch = if (ink.isLight) grey(0.97) else grey(0.10))
            }
        }

        // เคยมีชิปยอดผู้ติดตามต่อท้าย — ถอดออกแล้ว: hero ตอบ "นี่คือใคร" ส่วนยอดผู้ติดตามมี widget ของตัวเอง
        EditableText(
            field = ProfileField.tagline,
            style = TextSlotStyle(size = 9f, weight = SHFont.semibold, color = ink.text(0.45), tracking = 1.8f, uppercase = true),
            maxLines = 1,
            modifier = Modifier.scrubVeil(scrub.d, lead = 0.06, drop = 24f, pull = 16f),
        )
    }
}

/**
 * ชื่อเป็นตัวอักษรไล่เฉด — เฉดของดีไซน์ยืนอยู่จนกว่าเจ้าของการ์ดจะเลือกสีให้ช่องนี้ (สีเดียวชนะเฉด)
 * kerning ไม่ใช่ tracking — tracking ตัดสระบน/วรรณยุกต์ไทยหลุดจากฐาน
 * ช่องพิมพ์รับสีเดียวได้ ไม่ใช่ไล่เฉด — ใช้สีต้นทางของเฉด ตอนพิมพ์จึงอ่านออกเท่าเดิม
 */
@Composable
private fun AuraName(theme: CardTheme, w: Float, modifier: Modifier = Modifier) {
    val ink = LocalCardInk.current
    val tune = LocalWidgetTextStyle.current
    val accent = LocalCardAccent.current
    val style = TextSlotStyle(size = min(28f, w * 0.105f), weight = SHFont.black, color = ink.text(0.98), tracking = -0.7f)
    val chosen = tune.color(ink.text(0.98), ProfileField.personName, ink = ink, accent = accent)
    if (chosen != null) {
        EditableText(field = ProfileField.personName, style = style, maxLines = 1, modifier = modifier)
        return
    }
    val id = TextSlotID(field = ProfileField.personName)
    val slot = style.tuned(tune, id, ink, accent)
    slot.tilt = LocalSlotTilt.current
    val ghost = LocalGhostData.current
    val brush = Brush.horizontalGradient(listOf(ink.text(0.98), theme.accent))
    Tinted(slot.color) {
        BasicText(
            Profile.me.name,
            style = slot.textStyle.copy(brush = brush),
            maxLines = 1,
            softWrap = false,
            overflow = TextOverflow.Ellipsis,
            modifier = modifier
                .editableSlot(id, slot)
                .redacted(ghost),
        )
    }
}

// MARK: - 02 · การ์ดสรุปยอด

/**
 * ยอดผู้ติดตามในหน้าตาของ "สรุปประจำปี" — บล็อกสีทึบ ตัวเลขยักษ์ อันดับเรียงลงมา
 * คนรุ่นนี้อ่านออกทันทีว่าเป็น **สรุปที่ระบบคำนวณให้** ไม่ใช่ตัวเลขที่เจ้าตัวพิมพ์เอง (ชั้น connected — ยอดมาจาก OAuth)
 *
 * ท่าเปลี่ยนหน้า "สรุปถูกปิดทีละอันดับ" — ตัวเลขรวมถอดทีละหลัก อันดับดับไล่จากท้ายขึ้นหัว ปีที่เป็นเงาไถลสวนทาง
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun StatWrapped(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val embossed = LocalWidgetEmboss.current
    val embossBlind = LocalWidgetEmbossBlind.current
    val socials = Profile.me.creator.socials
    val ranked = socials.sortedByDescending { it.followerCount }
    val total = socials.sumOf { it.followerCount }
    val shape = RoundedCornerShape(20.dp)

    BoxWithConstraints(modifier.fillMaxSize()) {
        val w = maxWidth.value
        // ปีเงาเกาะมุมบนขวา — มุมเดียวที่ว่างจริง เพราะตัวเลขรวมชิดซ้ายและอันดับอยู่ล่าง
        Box(Modifier.fillMaxSize().clip(shape)) {
            // บล็อกสีดิบ — ตัวมันเองคือพื้นผิว จึงไม่พลิกตามหมึกการ์ด
            Box(
                Modifier
                    .fillMaxSize()
                    .background(
                        Brush.linearGradient(listOf(theme.rawAccentSoft, theme.rawAccent), start = Offset.Zero, end = Offset.Infinite),
                    ),
            )

            Text(
                "2026",
                style = sh(min(96f, w * 0.34f), SHFont.black),
                color = Vinyl.ink.opacity(0.11),
                maxLines = 1,
                softWrap = false,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .scrubSlide(scrub.d, travel = -w * 0.4f, fade = 0.8, eased = false)
                    .offset(22.dp, (-14).dp)
                    .graphicsLayer { rotationZ = -7f }
                    .wrapContentSize(Alignment.TopEnd, unbounded = true),
            )

            Column(Modifier.fillMaxSize().padding(16.dp)) {
                Text(
                    "สรุปผู้ติดตามของคุณ".uppercase(),
                    style = sh(9f, SHFont.heavy).copy(letterSpacing = 1.6.sp),
                    color = Vinyl.ink.opacity(0.55),
                    maxLines = 1,
                    softWrap = false,
                    autoSize = TextAutoSize.StepBased(minFontSize = (9f * 0.7f).sp, maxFontSize = 9.sp, stepSize = 0.5.sp),
                    modifier = Modifier.scrubVeil(scrub.d, lead = 0.34, drop = 18f, pull = 6f),
                )

                ScrubDigits(
                    text = Fmt.compact(total), d = scrub.d,
                    lead = 0.26, step = 0.06, drop = min(58f, w * 0.2f),
                    style = sh(min(50f, w * 0.175f), SHFont.black), color = Vinyl.ink,
                    modifier = Modifier.padding(top = 2.dp),
                )

                Spacer(Modifier.height(6.dp))
                Spacer(Modifier.weight(1f))

                WrappedShare(ranked, total, width = w - 32f, modifier = Modifier.padding(bottom = 10.dp))

                Column {
                    ranked.forEachIndexed { i, s ->
                        WrappedRow(
                            s, rank = i + 1,
                            lead = Scrub.lead(i, ranked.size, scrub.d, 0.08),
                            modifier = Modifier.linkSlot(s.profileURL),
                        )
                    }
                }
            }

            // ตราปั๊มนูนบนบล็อกสี — "สรุปที่ระบบคำนวณให้" ต้องมีชื่อผู้คำนวณ · ขึ้นเมื่อยอดมาจากแพลตฟอร์มจริงเท่านั้น
            // อยู่ขวากลาง ใต้เลขปีที่เป็นเงา เหนือแถวอันดับ — ที่เดียวของใบนี้ที่ไม่มีตัวอักษรให้ชน
            if (embossed && VerifiedFacts.numbersVerified) {
                EmbossedLockup(
                    height = if (embossBlind) 20f else 22f,
                    light = true,
                    foil = !embossBlind,
                    tint = Vinyl.ink.opacity(0.8),
                    modifier = Modifier
                        .align(Alignment.CenterEnd)
                        .offset(y = (-16).dp)
                        .padding(end = 16.dp),
                )
            }
        }
    }
}

/**
 * สัดส่วนของแต่ละช่องทางในยอดรวม — แถบเดียวไม่มีตัวเลขกำกับ ตอบคำถาม "หนักไปทางไหน"
 * ใช้เฉดของหมึกไล่กัน ไม่ใช่สีประจำแพลตฟอร์ม — บล็อกนี้เป็นวัสดุเดียว ห้ามมีสีที่สี่
 * ท่า: ช่องดับไล่จากฝั่งที่หน้ากำลังไป (`Scrub.cell`) เหมือนตารางเวลารับงาน
 */
@Composable
private fun WrappedShare(ranked: List<SocialProfile>, total: Int, width: Float, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    Row(
        modifier
            .fillMaxWidth()
            .height(7.dp),
        horizontalArrangement = Arrangement.spacedBy(3.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ranked.forEachIndexed { i, s ->
            val ratio = if (total > 0) s.followerCount.toFloat() / total.toFloat() else 0f
            val a = Scrub.cell(i, ranked.size, scrub.d, spill = 0.8).toFloat()
            Box(
                Modifier
                    .width(max(6f, (width - 6f) * ratio).dp)
                    .fillMaxHeight()
                    .graphicsLayer {
                        scaleX = a
                        transformOrigin = TransformOrigin(0f, 0.5f)
                        alpha = a
                    }
                    .background(Vinyl.ink.opacity(0.85 - i * 0.26), CircleShape),
            )
        }
    }
}

@Composable
private fun WrappedRow(s: SocialProfile, rank: Int, lead: Double, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val line = Vinyl.ink.opacity(0.13)
    Row(
        modifier
            .fillMaxWidth()
            .scrubVeil(scrub.d, lead = lead, drop = 26f, pull = 12f)
            .drawWithContent {
                drawContent()
                drawRect(line, size = Size(size.width, 0.8.dp.toPx()))
            }
            .padding(vertical = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(9.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            String.format(Locale.US, "%02d", rank),
            style = sh(11f, SHFont.black),
            color = Vinyl.ink.opacity(0.4),
            maxLines = 1,
            softWrap = false,
            modifier = Modifier.dataValue(),
        )
        BrandIcon(s.type.icon, size = 14f)
        Text(
            s.type.name,
            style = sh(12f, SHFont.bold),
            color = Vinyl.ink,
            maxLines = 1,
            softWrap = false,
            autoSize = TextAutoSize.StepBased(minFontSize = (12f * 0.6f).sp, maxFontSize = 12.sp, stepSize = 0.5.sp),
            modifier = Modifier.weight(1f),
        )
        Spacer(Modifier.width(4.dp))
        Text(
            Fmt.compact(s.followerCount),
            style = sh(12.5f, SHFont.heavy),
            color = Vinyl.ink,
            maxLines = 1,
            softWrap = false,
            modifier = Modifier.dataValue(),
        )
    }
}

// MARK: - 03 · ตู้ถ่ายรูป

/**
 * สี่เฟรมบนกระดาษแผ่นเดียว — สติปรูดจากตู้ถ่ายรูป
 * ต่างจาก `ArtFilmstrip` (คอนแทกต์ชีตของช่างภาพ) ตรงที่ตัวนี้คือ *ของที่ถืออยู่ในมือ* — มีขอบกระดาษ มีสติกเกอร์แปะทับขอบ
 *
 * ท่าเปลี่ยนหน้า "แผ่นถูกดึงออกจากช่องจ่าย" — ทั้งแผ่นไถลออกพร้อมเอียงเพิ่ม หน้าต่างแต่ละเฟรมหุบไล่กัน
 */
@Composable
fun ArtPhotobooth(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val slots = listOf(6, 7, 8, 9)

    BoxWithConstraints(modifier.fillMaxSize()) {
        val gap = 5f
        val pad = 8f
        val n = slots.size
        val fw = (maxWidth.value - pad * 2f - gap * (n - 1)) / n
        val t = Scrub.ease(Scrub.t(scrub.d))
        val s = Scrub.dir(scrub.d)

        Box(
            Modifier
                .fillMaxSize()
                .graphicsLayer {
                    rotationZ = -2f + s * 5f * t
                    scaleX = 1f - 0.05f * t
                    scaleY = 1f - 0.05f * t
                },
        ) {
            BoothStrip(theme, slots, fw, gap, pad)
        }
    }
}

@Composable
private fun BoothStrip(theme: CardTheme, slots: List<Int>, fw: Float, gap: Float, pad: Float) {
    val scrub = LocalPageScrub.current
    val shape = RoundedCornerShape(6.dp)
    val shade = Color.Black.opacity(0.4)
    Box(Modifier.fillMaxSize()) {
        Column(
            Modifier
                .fillMaxSize()
                .shadow(12.dp, shape, clip = false, ambientColor = shade, spotColor = shade)
                .background(Vinyl.photoPaper, shape)
                .clip(shape)
                .padding(pad.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Row(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(gap.dp)) {
                slots.forEachIndexed { i, slot ->
                    BoothFrame(slot, fw, i, slots.size, Modifier.fillMaxHeight())
                }
            }

            // แถบขาวใต้รูป — ตระกูล `รูปผลงาน` ห้ามมีตัวอักษร · เหลือดาวดวงเล็กไว้ดวงเดียว (สตริปจริงมีมาร์กของตู้เสมอ)
            Row(
                Modifier
                    .fillMaxWidth()
                    .height(10.dp)
                    .scrubVeil(scrub.d, lead = 0.32, drop = 14f, pull = 8f),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                SymbolIcon(SHIcon.star, size = 9f, tint = Vinyl.ink.opacity(0.45))
            }
        }
        BoothHeart(theme, Modifier.align(Alignment.TopEnd))
    }
}

@Composable
private fun BoothFrame(slot: Int, w: Float, i: Int, count: Int, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val shape = RoundedCornerShape(4.dp)
    Box(
        modifier
            .width(w.dp)
            .scrubAperture(scrub.d, lead = Scrub.lead(i, count, scrub.d, 0.1), feather = 0.24f, dim = 0.5)
            .photoSlot(slot)
            .clip(shape),
    ) {
        Box(Modifier.fillMaxSize().scrubDolly(scrub.d, shift = w * 0.07f, zoom = 0.16f)) {
            WidgetPhoto(slot, Modifier.fillMaxSize())
        }
    }
}

/**
 * สติกเกอร์แปะทับขอบกระดาษ — วางคร่อมขอบ ไม่ใช่วางข้างใน
 * ของที่ล้นออกนอกกรอบคือสิ่งที่ทำให้แผ่นอ่านเป็นของจริง ไม่ใช่ภาพประกอบที่ถูกจัดวาง
 */
@Composable
private fun BoothHeart(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val t = Scrub.ease(Scrub.t(scrub.d, 0.16))
    val dir = Scrub.dir(scrub.d)
    val shade = Color.Black.opacity(0.3)
    Box(
        modifier
            .offset(9.dp, (-9).dp)
            .size(24.dp)
            .graphicsLayer {
                rotationZ = 12f + dir * 40f * t
                scaleX = 1f - 0.5f * t
                scaleY = 1f - 0.5f * t
                alpha = Scrub.fade(t, 0.55).toFloat()
            }
            .shadow(4.dp, CircleShape, clip = false, ambientColor = shade, spotColor = shade)
            .background(theme.rawAccent, CircleShape)
            .border(1.5.dp, Color.White.opacity(0.9), CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        SymbolIcon(SHIcon.heart, size = 12f, tint = Color.White)
    }
}

// MARK: - 04 · สติกเกอร์สายงาน

/** องศาเอียงตั้งต้น — คงที่ ไม่สุ่ม การ์ดใบเดิมต้องหน้าตาเหมือนเดิมทุกครั้งที่เปิด */
private val StickerTilt = listOf(-4.0, 2.5, -1.5, 3.5, -2.5)

/**
 * สายงานเดิม แต่เป็นสติกเกอร์ไวนิลนูน — ขอบขาวหนา เงาจริง เอียงคนละองศา
 * สติกเกอร์ที่เอียงไม่เท่ากันอ่านออกมาเป็น *ของที่เจ้าตัวเลือกเอง* — ความหมายที่ถูกต้องของ widget ตัวนี้
 *
 * ท่าเปลี่ยนหน้า "ลอกทีละใบ" — สติกเกอร์หมุนขึ้นแล้วหดหายไล่กัน ของที่ *ถูกลอก* ต้องหมุนออกจากผิวเสมอ
 */
@Composable
fun StickerTags(theme: CardTheme, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    val items = Profile.me.categories

    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        WidgetLabel(
            text = "สายงาน",
            modifier = Modifier.scrubVeil(scrub.d, lead = 0.34, drop = 20f, pull = 6f),
        )

        Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.TopStart) {
            key(items) {
                FlowLayout(spacing = 10f) {
                    items.forEachIndexed { i, name ->
                        Sticker(theme, name, i, items.size)
                    }
                }
            }
        }
    }
}

@Composable
private fun Sticker(theme: CardTheme, name: String, i: Int, total: Int) {
    val scrub = LocalPageScrub.current
    val t = Scrub.ease(Scrub.t(scrub.d, Scrub.lead(i, total, scrub.d, 0.08)))
    val s = Scrub.dir(scrub.d)
    val shape = CircleShape
    val shade = Color.Black.opacity(0.32)
    // สามสีวนกัน — สีเดียวทั้งชุดอ่านเป็นแท็ก ไม่ใช่สติกเกอร์ที่สะสมมาคนละที่
    val fill: Modifier = when (i % 3) {
        0 -> Modifier.background(
            Brush.linearGradient(listOf(theme.rawAccent, theme.rawAccentSoft), start = Offset.Zero, end = Offset.Infinite),
            shape,
        )
        1 -> Modifier.background(Color.White, shape)
        else -> Modifier.background(Vinyl.marker, shape)
    }
    val tilt = StickerTilt[i % StickerTilt.size]

    Row(
        Modifier
            .graphicsLayer {
                rotationZ = (tilt + s * 26f * t).toFloat()
                scaleX = 1f - 0.45f * t
                scaleY = 1f - 0.45f * t
                translationY = -18f * t * density
                alpha = Scrub.fade(t, 0.6).toFloat()
            }
            .shadow(5.dp, shape, clip = false, ambientColor = shade, spotColor = shade)
            .then(fill)
            // ขอบขาวหนาคือสิ่งเดียวที่แยก "สติกเกอร์ที่ตัดมาแปะ" ออกจาก "ชิปในฟอร์ม"
            .border(2.5.dp, Color.White, shape)
            .padding(horizontal = 13.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (i % 2 == 0) {
            SymbolIcon(SHIcon.starFill, size = 9f, tint = Vinyl.ink.opacity(0.7))
        }
        // ลบข้อความจนหมดแล้วปิดช่อง = ลอกสติกเกอร์ใบนั้นทิ้ง (ดู `Profile.commit`)
        EditableText(
            field = ProfileField.categories,
            index = i,
            style = TextSlotStyle(size = 13f, weight = SHFont.heavy, color = Vinyl.ink, corner = 10f),
            text = name,
            maxLines = 1,
        )
    }
}
