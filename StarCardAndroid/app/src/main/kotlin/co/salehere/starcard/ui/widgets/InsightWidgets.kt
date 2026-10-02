package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.WidgetLabel
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.AudienceInsight
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.Profile
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.Provenance
import co.salehere.starcard.theme.ProvenanceTag
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.SymbolIcon
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.editor.dataValue
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

// MARK: - สำรับ "ผู้ชม" (= InsightWidgets.swift)
//
// สเปกหมวด 2.3 — ผู้ชมเป็นใคร · สี่แบบในตระกูลเดียวกัน สลับกันได้
// สามแบบแรกเป็น **แผ่นข้อมูล** · แบบที่สี่เป็น **ประโยคเดียว** ที่ยุบทั้งสามชุดเหลือบรรทัดเดียว
// กติกา: **ทุกตัวเลขในนี้ครีเอเตอร์แก้ไม่ได้** — มาจาก OAuth เท่านั้น ห้ามเปิดเป็นฟอร์มให้พิมพ์เด็ดขาด

/** สีเพศ — คงที่ ไม่ผูกพาเลตต์ เพราะสามส่วนต้องแยกออกจากกันได้ทุกธีม */
private object Aud {
    val female = rgb(1.00, 0.55, 0.74)
    val male = rgb(0.51, 0.60, 1.00)
    val other = rgb(0.36, 0.90, 0.68)
}

// MARK: - 01 · สัดส่วนผู้ชม

/**
 * Gender Ratio — แถบเดียวสามส่วน อ่านจบก่อนตาจะเลื่อนไปที่อื่น
 * จงใจไม่ใช้โดนัท: ส่วนที่เล็กที่สุด (2%) บนวงกลมกลายเป็นเสี้ยวที่มองไม่เห็น — รูปทรงต้องเลือกจากข้อมูล
 * ท่าเปลี่ยนหน้า: แถบถูกกวาดคืนทีละส่วน (`Scrub.cell`) ส่วนที่อยู่ต้นทางหายก่อนเสมอ
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun AudienceSplitWidget(theme: CardTheme, modifier: Modifier = Modifier) {
    val d = LocalPageScrub.current.d
    val ink = LocalCardInk.current
    val a = Profile.me.creator.audience
    val parts = listOf(
        Triple("หญิง", a.female, Aud.female),
        Triple("ชาย", a.male, Aud.male),
        Triple("อื่น ๆ", a.other, Aud.other),
    )
    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(11.dp)) {
        WidgetLabel(
            text = "สัดส่วนผู้ชม",
            trailing = { ProvenanceTag(Provenance.Screenshot("12 ก.ย.")) },
            modifier = Modifier.fillMaxWidth().scrubVeil(d, lead = 0.38, drop = 20f, pull = 6f),
        )

        // แถบ
        BoxWithConstraints(Modifier.fillMaxWidth().height(13.dp)) {
            val w = maxWidth.value
            Row(
                Modifier.fillMaxSize(),
                horizontalArrangement = Arrangement.spacedBy(3.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                parts.forEachIndexed { i, p ->
                    val k = Scrub.cell(i, parts.size, d, spill = 0.9).toFloat()
                    Box(
                        Modifier
                            .graphicsLayer {
                                scaleX = k
                                transformOrigin = TransformOrigin(0f, 0.5f)
                                alpha = k
                            }
                            .width(max(5.0, (w - 6) * p.second / 100).toFloat().dp)
                            .fillMaxHeight()
                            .background(p.third, CircleShape),
                    )
                }
            }
        }

        // คำอธิบาย
        Row(
            Modifier.wrapContentWidth(Alignment.Start, unbounded = true),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            parts.forEachIndexed { i, p ->
                Row(
                    Modifier.scrubVeil(d, lead = Scrub.lead(i, parts.size, d, step = 0.07), drop = 20f, pull = 10f),
                    horizontalArrangement = Arrangement.spacedBy(5.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(Modifier.size(7.dp).background(p.third, CircleShape))
                    Text(
                        Fmt.pct(p.second), style = sh(14f, SHFont.heavy), color = ink.text(0.96),
                        maxLines = 1, softWrap = false, modifier = Modifier.dataValue(),
                    )
                    Text(
                        p.first, style = sh(10.5f, SHFont.medium), color = ink.text(0.46),
                        maxLines = 1, softWrap = false,
                    )
                }
            }
        }
    }
}

// MARK: - 02 · ช่วงอายุผู้ชม

/**
 * Age Distribution — แท่งนอนเรียง **ตามอายุ ไม่ใช่ตามขนาด**
 * ลำดับอายุคือข้อมูลในตัวมันเอง — แบรนด์อยากรู้ว่ากลุ่มนี้ "เอียงไปทางเด็ก" หรือ "เอียงไปทางผู้ใหญ่"
 * ท่าเปลี่ยนหน้า: แท่งหดกลับเข้าแกน
 */
@Composable
fun AudienceAgeWidget(theme: CardTheme, modifier: Modifier = Modifier) {
    val d = LocalPageScrub.current.d
    val bands = Profile.me.creator.audience.ages
    val top = bands.maxOfOrNull { it.share } ?: 1.0
    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        WidgetLabel(
            text = "ช่วงอายุผู้ชม",
            trailing = { ProvenanceTag(Provenance.Screenshot("12 ก.ย.")) },
            modifier = Modifier.fillMaxWidth().scrubVeil(d, lead = 0.38, drop = 20f, pull = 6f),
        )
        Column(Modifier.fillMaxWidth().weight(1f)) {
            bands.forEachIndexed { i, b ->
                AgeRow(
                    theme, b, top, lead = Scrub.lead(i, bands.size, d, step = 0.08), d = d,
                    modifier = Modifier.fillMaxWidth().weight(1f),
                )
            }
        }
    }
}

@Composable
private fun AgeRow(
    theme: CardTheme, b: AudienceInsight.AgeBand, top: Double, lead: Double, d: Float, modifier: Modifier,
) {
    val ink = LocalCardInk.current
    // กลุ่มใหญ่ที่สุดได้สีธีมเต็ม ที่เหลือจางลง — คำตอบต้องเด่นกว่าบริบทเสมอ
    val peak = b.share == top
    val t = Scrub.ease(Scrub.t(d, lead))
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(
            b.label, style = sh(11f, SHFont.semibold), color = ink.text(if (peak) 0.9 else 0.5),
            maxLines = 1, softWrap = false, overflow = TextOverflow.Ellipsis,
            modifier = Modifier.width(42.dp),
        )

        val rail = ink.fill(0.07)
        val soft = theme.accentSoft
        val strong = theme.accent
        Canvas(Modifier.weight(1f).height(9.dp)) {
            val h = size.height
            drawRoundRect(rail, cornerRadius = CornerRadius(h / 2, h / 2))
            val w = size.width * (b.share / max(1.0, top)).toFloat() * max(0f, 1 - t)
            if (w > 0f) {
                val brush = if (peak) Brush.horizontalGradient(listOf(soft, strong), startX = 0f, endX = w)
                else SolidColor(strong.opacity(0.34))
                val r = min(w, h) / 2
                drawRoundRect(brush, size = Size(w, h), cornerRadius = CornerRadius(r, r))
            }
        }

        // ตัวเลขได้ความกว้างตามตัวจริงเสมอ — "22.4%" ที่ถูกตัดเป็น "22…" แย่กว่าคอลัมน์ไม่ตรงกัน
        Box(
            Modifier
                .scrubVeil(d, lead = lead, drop = 16f, pull = 6f)
                .widthIn(min = 38.dp),
            contentAlignment = Alignment.CenterEnd,
        ) {
            Text(
                Fmt.pct(b.share), style = sh(12.5f, SHFont.heavy), color = ink.text(if (peak) 0.98 else 0.55),
                maxLines = 1, softWrap = false, modifier = Modifier.dataValue(),
            )
        }
    }
}

// MARK: - 03 · ผู้ชมอยู่ที่ไหน

/**
 * Top Locations — อันดับพร้อมสัดส่วน
 * ตัวเลขนำหน้า (01 · 02) ใช้ได้ที่นี่เพราะมัน**คืออันดับจริง** ไม่ใช่เลขประดับ
 * ท่าเปลี่ยนหน้า: อันดับถูกปิดไล่จากท้าย
 */
@Composable
fun AudienceMapWidget(theme: CardTheme, modifier: Modifier = Modifier) {
    val d = LocalPageScrub.current.d
    val places = Profile.me.creator.audience.places
    val top = places.maxOfOrNull { it.share } ?: 1.0
    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(9.dp)) {
        WidgetLabel(
            text = "ผู้ชมอยู่ที่ไหน",
            trailing = {
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                    SymbolIcon(SHIcon.mapPin, size = 10f, tint = theme.accent)
                    Text(
                        "อันดับ 1–${places.size}", style = sh(9.5f, SHFont.bold), color = theme.accent,
                        maxLines = 1, softWrap = false,
                    )
                }
            },
            modifier = Modifier.fillMaxWidth().scrubVeil(d, lead = 0.38, drop = 20f, pull = 6f),
        )
        Column(Modifier.fillMaxWidth().weight(1f)) {
            places.forEachIndexed { i, p ->
                PlaceRow(
                    theme, p, rank = i + 1, top = top, lead = Scrub.lead(i, places.size, d, step = 0.08), d = d,
                    modifier = Modifier.fillMaxWidth().weight(1f),
                )
            }
        }
    }
}

@Composable
private fun PlaceRow(
    theme: CardTheme, p: AudienceInsight.PlaceShare, rank: Int, top: Double, lead: Double, d: Float, modifier: Modifier,
) {
    val ink = LocalCardInk.current
    val t = Scrub.ease(Scrub.t(d, lead))
    val fill = theme.accent.opacity(if (rank == 1) 0.2 else 0.09)
    Box(modifier, contentAlignment = Alignment.CenterStart) {
        // แถบสัดส่วนอยู่ "หลังตัวหนังสือ" ไม่ใช่ข้าง ๆ — แถวจึงอ่านเป็นรายการ ไม่ใช่ตาราง
        Canvas(Modifier.fillMaxSize()) {
            val w = size.width * (p.share / max(1.0, top)).toFloat() * max(0f, 1 - t)
            if (w > 0f) {
                val r = min(7.dp.toPx(), min(w, size.height) / 2)
                drawRoundRect(fill, size = Size(w, size.height), cornerRadius = CornerRadius(r, r))
            }
        }

        Row(
            Modifier
                .fillMaxWidth()
                .scrubVeil(d, lead = lead, drop = 22f, pull = 10f)
                .padding(horizontal = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                String.format(Locale.US, "%02d", rank), style = sh(10f, SHFont.black), color = ink.text(0.32),
                maxLines = 1, softWrap = false, modifier = Modifier.dataValue(),
            )
            Text(
                p.name, style = sh(13f, SHFont.bold), color = ink.text(0.94),
                maxLines = 1, softWrap = false,
                autoSize = TextAutoSize.StepBased(minFontSize = (13f * 0.7f).sp, maxFontSize = 13.sp, stepSize = 0.5.sp),
                modifier = Modifier.weight(1f),
            )
            Spacer(Modifier.width(4.dp))
            Text(
                Fmt.pct(p.share), style = sh(13f, SHFont.heavy), color = ink.text(0.94),
                maxLines = 1, softWrap = false, modifier = Modifier.dataValue(),
            )
        }
    }
}

// MARK: - 04 · ประโยคเดียว

/**
 * ผู้ชมทั้งชุดยุบเหลือ **ประโยคเดียวที่พิมพ์ใหญ่** — เพศ อายุ เมือง เรียงเป็นสามคำ
 * เปอร์เซ็นต์ถูกลดชั้นเป็นบรรทัดจิ๋วท้ายก้อน (หลักฐานประกอบ ไม่ใช่คำตอบ) · สามค่าคำนวณจากข้อมูลจริงทุกครั้ง
 * ท่าเปลี่ยนหน้า: ระยะตัวอักษรคลายออกก่อนบรรทัดจะมุดใต้ขอบ
 */
@Composable
fun AudienceLineWidget(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val d = LocalPageScrub.current.d
    val ink = LocalCardInk.current
    val a = Profile.me.creator.audience
    val all = listOf("ผู้หญิง" to a.female, "ผู้ชาย" to a.male, "เพศอื่น" to a.other)
    val gender = all.maxByOrNull { it.second } ?: all[0]
    val age = a.ages.maxByOrNull { it.share }
    val place = a.places.maxByOrNull { it.share }
    // ขนาดคำนวณจากความกว้างจริง ไม่ตั้งค่าคงที่ — widget ตัวนี้ถูกย่อครึ่งได้
    val big = min(30f, size.width * 0.093f)

    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(1.dp)) {
        Text(
            "คนที่ตามฉันส่วนใหญ่คือ", style = sh(11.5f, SHFont.semibold), color = ink.text(0.45),
            maxLines = 1, softWrap = false,
            autoSize = TextAutoSize.StepBased(minFontSize = (11.5f * 0.7f).sp, maxFontSize = 11.5.sp, stepSize = 0.5.sp),
            modifier = Modifier
                .scrubVeil(d, lead = 0.42, drop = 18f, pull = 6f)
                .padding(bottom = 7.dp),
        )

        AudLine(gender.first, big, ink.text(0.96), 0, d)
        if (age != null) AudLine("อายุ ${age.label}", big, theme.accent, 1, d)
        if (place != null) AudLine("ใน${place.name}", big, ink.text(0.96), 2, d)

        // `Spacer(minLength: 6)` — ระยะขั้นต่ำ 5 + ระยะห่างของคอลัมน์ 1 = 6
        Spacer(Modifier.height(5.dp))
        Spacer(Modifier.weight(1f))

        Text(
            "${Fmt.pct(gender.second)} · ${Fmt.pct(age?.share ?: 0.0)} · ${Fmt.pct(place?.share ?: 0.0)} ตามลำดับ",
            style = sh(10f, SHFont.medium), color = ink.text(0.34),
            maxLines = 1, softWrap = false,
            autoSize = TextAutoSize.StepBased(minFontSize = (10f * 0.65f).sp, maxFontSize = 10.sp, stepSize = 0.5.sp),
            modifier = Modifier
                .padding(top = 3.dp)
                .scrubVeil(d, lead = 0.0, drop = 18f, pull = 16f),
        )
    }
}

@Composable
private fun AudLine(text: String, size: Float, tint: Color, i: Int, d: Float) {
    val lead = Scrub.lead(i, 3, d, step = 0.09)
    val t = Scrub.ease(Scrub.t(d, lead))
    Text(
        text,
        // บีบอยู่ตอนนิ่ง แล้วคลายออกตอนจากไป
        style = sh(size, SHFont.black).copy(letterSpacing = (-0.8f + 7f * t).sp),
        color = tint,
        maxLines = 1,
        softWrap = false,
        autoSize = TextAutoSize.StepBased(minFontSize = (size * 0.55f).sp, maxFontSize = size.sp, stepSize = 0.5.sp),
        modifier = Modifier.scrubVeil(d, lead = lead + 0.1, drop = size * 1.3f, pull = 8f),
    )
}
