package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.redacted
import co.salehere.starcard.components.scrubDolly
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.PhotoStore
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.StarSeal
import co.salehere.starcard.theme.Tinted
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalGhostData
import co.salehere.starcard.ui.LocalSlotTilt
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import co.salehere.starcard.ui.editor.editableSlot
import java.util.UUID
import kotlin.math.max
import kotlin.math.min

// MARK: - ตระกูลคัตเอาต์ (= Views/Widgets/CutoutWidgets.swift)
//
// ของใหม่ที่นี่คือ **กรอบหายไป** — พอรูปมีช่องอัลฟา คนจะ *ยืนอยู่บนการ์ด* ไม่ใช่อยู่ในกล่อง แล้วชื่อไปอยู่หลังไหล่ได้จริง
// สามระนาบ: 1. พื้น (ตัวอักษรยักษ์ · สีธีม · แสง) 2. คน (PNG ที่ผู้ใช้ตัดมา) 3. หน้า (แถบสี · ชื่อ · ตรายืนยัน)
// ตอนเลื่อนหน้า สามชั้นเดินคนละอัตรา — ตาอ่านความลึกจาก *ความต่างของอัตรา*
//
// `CutoutPlane` · `CutoutSample` · `cutoutPlane()` · `cutoutLifting()` · `CutoutSubject` · `CutoutStatus` อยู่ใน WidgetKit.kt
//
// # เวทีที่สูงกว่ากรอบ
// Swift วางแถวชื่อด้วย `.frame(w, h, .bottomLeading).padding(.bottom, x)` ใน `ZStack` แล้วครอบ `.frame(w, h)` —
// ZStack โตตามลูกที่สูงที่สุด (h + x) แล้วกรอบจัดทั้งก้อนไว้กลาง ทุกชั้นจึงถูกยกขึ้น x/2 · ที่นี่จำลองด้วย
// `requiredSize(w, สูงของเวที)` ที่จัดกลางในกรอบ w×h — ตำแหน่งจริงบนจอตรงกับ iOS ทุกชั้น

/** ช่องรูปของตระกูลนี้ — ไม่มีสโตร์ (พรีวิวนอกการ์ด) ก็ยังโชว์ท่าด้วยรูปตัวอย่าง เหมือนช่องที่ยังไม่มีรูปของเจ้าของ */
private fun cutoutPlaneOrSample(store: PhotoStore?, widget: UUID?): CutoutPlane =
    if (store != null) cutoutPlane(store, 1, widget)
    else CutoutSample.image?.let { CutoutPlane.Subject(it, own = false) } ?: CutoutPlane.Framed

// MARK: - 01 ชื่ออยู่หลังคน

/**
 * โปสเตอร์ชื่อ — ชื่อเล่นตัวยักษ์อยู่ **หลังไหล่** แถบสายงานพาด **หน้าอก**
 * สิ่งที่พิสูจน์ว่าคนอยู่ *ระหว่างชั้น* คือการมีของอีกชิ้นพาดทับเขา — แถบสายงานคือหลักฐานของความลึก
 *
 * # โหมดกรอบ (รูปทึบ)
 * ผังทั้งใบยังอยู่ครบ เปลี่ยนแค่ว่าคนอยู่ในแผ่นมนทางขวา — อ่านเป็นปกนิตยสารครึ่งหน้า ไม่ใช่สิ่งที่เหลือจากการล้มเหลว
 */
@Composable
fun ArtNameBehind(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val photos = LocalPhotoStore.current
    val wid = LocalWidgetID.current
    val scrub = LocalPageScrub.current
    val shape = RoundedCornerShape(22.dp)
    val plane = cutoutPlaneOrSample(photos, wid)
    val w = size.width
    val h = size.height
    // ตัวยักษ์คิดจากด้านที่สั้นกว่า — กรอบที่ถูกลากให้เตี้ยจะได้ชื่อที่ยังอยู่ในใบ
    val fs = min(w * 0.33f, h * 0.29f)
    val barH = min(26f, max(17f, h * 0.05f))
    val barY = h * 0.66f
    // ลูกที่สูงที่สุดของ ZStack: แถวชื่อ (h + 5%) หรือวงแหวนหลังหัว (0.72w)
    val stageH = max(h * 1.05f, w * 0.72f)

    Box(
        modifier
            .size(w.dp, h.dp)
            .clip(shape)
            .background(grey(0.045)),
        contentAlignment = Alignment.Center,
    ) {
        Box(Modifier.requiredSize(w.dp, stageH.dp)) {
            // ── พื้น
            // แสงอุ่นอยู่หลังหัวพอดี ไม่ใช่กลางใบ — แยกหัวออกจากพื้นเข้มโดยไม่ต้องใส่เส้นขอบรอบตัวคน
            Box(
                Modifier.size(w.dp, h.dp).drawBehind {
                    drawRect(
                        Brush.radialGradient(
                            listOf(theme.rawAccent.opacity(0.26), Color.Transparent),
                            center = Offset(this.size.width * 0.62f, this.size.height * 0.16f),
                            radius = max(1f, (w * 0.72f).dp.toPx()),
                        ),
                    )
                },
            )
            Box(
                Modifier
                    .offset((w * 0.52f).dp, (h * 0.10f).dp)
                    .size((w * 0.72f).dp)
                    .border(1.dp, theme.rawAccent.opacity(0.26), CircleShape),
            )

            // พื้นวิ่งสวนทางแรงที่สุด — ชั้นที่ไกลตาที่สุดต้องเคลื่อนต่างจากชั้นกลางชัดที่สุด
            Column(
                Modifier
                    .scrubSlide(scrub.d, travel = -w * 0.30f, fade = 0.82, eased = false)
                    .padding(start = (w * 0.06f).dp, top = (h * 0.09f).dp)
                    .width((w * 0.92f).dp),
                verticalArrangement = Arrangement.spacedBy((fs * 0.10f).dp),
            ) {
                // bold ไม่ใช่ black — ที่น้ำหนักหนาสุด NotoSansThai วางสระบนชนวรรณยุกต์
                EditableText(
                    field = ProfileField.nickname,
                    style = TextSlotStyle(size = fs, weight = SHFont.bold, color = grey(0.97), tracking = -fs * 0.05f, corner = 6f),
                    autoSizeMin = 0.3f,
                )
                EditableText(
                    field = ProfileField.tagline,
                    style = TextSlotStyle(size = fs * 0.18f, weight = SHFont.bold, color = theme.rawAccent, tracking = fs * 0.025f),
                    autoSizeMin = 0.4f,
                )
            }

            // ── คน
            when (plane) {
                is CutoutPlane.Subject -> Box(
                    // ดันลงให้ขอบล่างของรูปตกนอกใบ — รอยตัดกลางลำตัวถ้าอยู่ *ในใบ* จะอ่านเป็นรูปครึ่งท่อนลอยอยู่
                    Modifier
                        .offset((-w * 0.01f).dp, (h * 0.05f).dp)
                        .size(w.dp, h.dp),
                    contentAlignment = Alignment.BottomEnd,
                ) {
                    // กรอบของ *ช่อง* เท่าตัวคนพอดี — ปุ่มเปลี่ยนรูปเกาะกรอบนี้ ไม่ใช่มุมขวาบนของทั้งใบ
                    CutoutSubject(
                        image = plane.image,
                        height = h * 0.86f,
                        d = scrub.d,
                        drift = w * 0.05f,
                        modifier = Modifier
                            .wrapContentSize(Alignment.BottomEnd, unbounded = true)
                            .photoSlot(1),
                    )
                }
                CutoutPlane.Framed -> Box(
                    Modifier
                        .offset((w * 0.03f).dp, (-h * 0.02f).dp)
                        .size(w.dp, h.dp),
                    contentAlignment = Alignment.BottomEnd,
                ) {
                    Box(
                        Modifier
                            .size((w * 0.56f).dp, (h * 0.76f).dp)
                            .photoSlot(1)
                            .clip(RoundedCornerShape(18.dp)),
                    ) {
                        WidgetPhoto(1, Modifier.fillMaxSize().scrubDolly(scrub.d, shift = w * 0.05f, zoom = 0.14f))
                    }
                }
            }

            // ── หน้า
            // แถบวิ่งไปทางเดียวกับหน้า เร็วกว่าคน — ชั้นที่ใกล้ตาที่สุด
            val t = Scrub.ease(Scrub.t(scrub.d))
            val s = Scrub.dir(scrub.d)
            Box(
                Modifier
                    .offset((s * w * 0.14f * t).dp, barY.dp)
                    .graphicsLayer { alpha = Scrub.fade(t, 0.8).toFloat() }
                    .size(w.dp, barH.dp)
                    .background(theme.rawAccent),
                contentAlignment = Alignment.CenterStart,
            ) {
                Text(
                    marqueeLine(),
                    style = sh(barH * 0.40f, SHFont.heavy).copy(letterSpacing = (barH * 0.14f).sp),
                    color = Color.Black.opacity(0.88),
                    maxLines = 1,
                    softWrap = false,
                    modifier = Modifier
                        .wrapContentWidth(Alignment.Start, unbounded = true)
                        .padding(start = (w * 0.06f).dp),
                )
            }

            Box(
                Modifier
                    .scrubVeil(scrub.d, lead = 0.22, drop = 30f, pull = 10f)
                    .padding(bottom = (h * 0.05f).dp)
                    .size(w.dp, h.dp),
                contentAlignment = Alignment.BottomStart,
            ) {
                Row(
                    Modifier
                        .fillMaxWidth()
                        .padding(horizontal = (w * 0.06f).dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    NameWithShadow(
                        field = ProfileField.personName,
                        style = TextSlotStyle(size = min(20f, h * 0.046f), weight = SHFont.bold, color = Color.White, tracking = -0.4f),
                        shadow = Color.Black.opacity(0.75),
                        radius = 9f,
                        y = 2f,
                        modifier = Modifier.weight(1f, fill = false),
                    )
                    if (Profile.me.creator.verified) StarSeal(size = 12f)
                }
            }

            CutoutStatus(plane, theme, modifier = Modifier.padding(9.dp))
        }
    }
}

/** สายงาน + พื้นที่ ต่อกันยาวพอให้แถบไม่มีที่ว่างตอนมันไถลออกไป */
private fun marqueeLine(): String {
    val area = Profile.me.creator.location
    val tagline = Profile.me.tagline
    val one = if (area.isEmpty()) tagline else "$tagline · $area"
    return List(3) { one.uppercase() }.joinToString(" · ")
}

/**
 * ช่องแก้ได้หนึ่งบรรทัดที่มีเงาฟุ้งใต้ตัวอักษร (= `.shadow(color:radius:y:)` ก่อน `.editableText`)
 * `EditableText` ไม่รับเงา จึงประกอบจากชิ้นเดียวกัน: สไตล์ที่ปรับแล้ว · ประกาศช่อง · แท่งว่างตอนไม่มีข้อมูล
 */
@Composable
private fun NameWithShadow(
    field: ProfileField,
    style: TextSlotStyle,
    shadow: Color,
    radius: Float,
    y: Float,
    modifier: Modifier = Modifier,
) {
    val id = TextSlotID(field = field)
    val slot = style.tuned(LocalWidgetTextStyle.current, id, LocalCardInk.current, LocalCardAccent.current)
    slot.tilt = LocalSlotTilt.current
    val ghost = LocalGhostData.current
    val density = LocalDensity.current.density
    val raw = Profile.me.text(id)
    val value = if (slot.uppercase) raw.uppercase() else raw
    Tinted(slot.color) {
        Text(
            value,
            style = slot.textStyle.copy(shadow = Shadow(shadow, Offset(0f, y * density), radius * density)),
            color = slot.color,
            maxLines = 1,
            softWrap = false,
            overflow = TextOverflow.Ellipsis,
            modifier = modifier.editableSlot(id, slot).redacted(ghost),
        )
    }
}

// MARK: - 03 ทะลุกรอบ

/**
 * การ์ดที่คนโผล่พ้นขอบ — หัวกับไหล่อยู่ **นอกกล่อง** ตัวอักษรยักษ์อยู่ **ในกล่อง หลังตัว**
 * กล่องยังอยู่เสมอ — รูปทึบก็แค่ไม่มีอะไรโผล่พ้นขอบ ผังไม่เปลี่ยนสักนิด (ตัวที่ปลอดภัยที่สุดในสองตัว)
 *
 * ตัวคนถูกตัดที่ **ขอบล่างของกล่อง** ไม่ใช่ที่ขอบ widget — ไม่งั้นขาจะยื่นลงไปทับชื่อใต้กล่อง
 * ส่วนขอบบนไม่ตัดเลย นั่นคือทั้งหมดที่ทำให้มัน "ทะลุ"
 */
@Composable
fun ArtBreakout(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val photos = LocalPhotoStore.current
    val wid = LocalWidgetID.current
    val scrub = LocalPageScrub.current
    val ink = LocalCardInk.current
    val plane = cutoutPlaneOrSample(photos, wid)
    val subject = plane.subject
    val w = size.width
    val h = size.height
    // แถบล่างกันไว้ให้ชื่อ · หัวต้องมีที่โผล่ข้างบนกล่อง
    val footer = min(58f, max(40f, h * 0.13f))
    val overhang = h * 0.17f
    val boxTop = overhang
    val boxH = max(0f, h - footer - overhang)
    val fs = min(w * 0.32f, boxH * 0.40f)
    // ลูกที่สูงที่สุดของ ZStack คือแถวชื่อ (h + 2.5%)
    val stageH = h * 1.025f

    Box(modifier.size(w.dp, h.dp), contentAlignment = Alignment.Center) {
        Box(Modifier.requiredSize(w.dp, stageH.dp)) {
            // ── กล่อง: พื้น + ตัวอักษรยักษ์
            Box(
                Modifier
                    .offset(y = boxTop.dp)
                    .photoSlot(1)
                    .size(w.dp, boxH.dp),
                contentAlignment = Alignment.Center,
            ) {
                Box(
                    Modifier
                        .size((w * 0.92f).dp, boxH.dp)
                        .clip(RoundedCornerShape(20.dp)),
                ) {
                    if (subject == null) {
                        // โหมดกรอบ — รูปคือเนื้อหา ไม่ใช่พื้นผิว (คนกด "เปลี่ยนแบบ" มาเจอตัวนี้ด้วยรูป JPEG ตลอดเวลา)
                        WidgetPhoto(1, Modifier.fillMaxSize().scrubDolly(scrub.d, shift = w * 0.04f, zoom = 0.12f))
                        // ดูโอโทนบาง ๆ ให้รูปเข้ากับธีม แล้วม่านล่างสำหรับตัวอักษร
                        Box(
                            Modifier.fillMaxSize().drawBehind {
                                drawRect(theme.rawAccent.opacity(0.22), blendMode = BlendMode.Overlay)
                            },
                        )
                        Box(
                            Modifier.fillMaxSize().background(
                                Brush.verticalGradient(
                                    listOf(Color.Transparent, Color.Black.opacity(0.30), Color.Black.opacity(0.88)),
                                ),
                            ),
                        )
                    } else {
                        Box(
                            Modifier.fillMaxSize().background(
                                Brush.linearGradient(
                                    listOf(theme.rawAccent.opacity(0.62), grey(0.06).opacity(0.90)),
                                    start = Offset.Zero,
                                    end = Offset.Infinite,
                                ),
                            ),
                        )
                    }

                    // ไม่มีตัวคนมาบัง ตัวอักษรก็ต้องลงไปนั่งบนม่านล่าง ไม่งั้นมันลอยกลางรูป
                    EditableText(
                        field = ProfileField.nickname,
                        style = TextSlotStyle(
                            size = fs, weight = SHFont.bold, color = Color.White.opacity(0.94),
                            tracking = -fs * 0.05f, corner = 6f,
                        ),
                        autoSizeMin = 0.3f,
                        modifier = Modifier
                            .scrubSlide(scrub.d, travel = -w * 0.24f, fade = 0.84, eased = false)
                            .padding(start = (w * 0.05f).dp, top = (boxH * (if (subject == null) 0.50f else 0.26f)).dp)
                            .width((w * 0.80f).dp),
                    )

                    Box(
                        Modifier
                            .padding(start = (w * 0.05f).dp)
                            .size((w * 0.86f).dp, (boxH * 0.94f).dp),
                        contentAlignment = Alignment.BottomStart,
                    ) {
                        Text(
                            "STAR CARD",
                            style = sh(8f, SHFont.semibold).copy(letterSpacing = 2.8.sp),
                            color = Color.White.opacity(0.55),
                            maxLines = 1,
                            softWrap = false,
                        )
                    }
                }
            }

            // ── คน: ไม่ตัดข้างบน · ตัดที่ขอบล่างของกล่องเท่านั้น
            if (subject != null) {
                Box(
                    Modifier
                        .size(w.dp, (boxTop + boxH).dp)
                        .clipToBounds(),
                    contentAlignment = Alignment.TopCenter,
                ) {
                    CutoutSubject(
                        image = subject,
                        height = boxH + overhang,
                        d = scrub.d,
                        drift = w * 0.035f,
                        modifier = Modifier
                            .wrapContentSize(Alignment.TopCenter, unbounded = true)
                            .offset(x = (w * 0.05f).dp),
                    )
                }
            }

            // ── ชื่อใต้กล่อง: นั่งบนพื้นการ์ด จึงพลิกตามหมึก ไม่ใช่ขาวตายตัว
            Box(
                Modifier
                    .padding(bottom = (h * 0.025f).dp)
                    .size(w.dp, h.dp),
                contentAlignment = Alignment.BottomStart,
            ) {
                Column(
                    Modifier
                        .fillMaxWidth()
                        .padding(horizontal = (w * 0.05f).dp),
                    verticalArrangement = Arrangement.spacedBy(3.dp),
                ) {
                    Row(
                        Modifier
                            .scrubVeil(scrub.d, lead = 0.24, drop = 24f, pull = 8f)
                            .fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        EditableText(
                            field = ProfileField.personName,
                            style = TextSlotStyle(size = min(19f, h * 0.045f), weight = SHFont.bold, color = ink.text(0.92), tracking = -0.4f),
                            modifier = Modifier.weight(1f, fill = false),
                        )
                        if (Profile.me.creator.verified) {
                            StarSeal(size = 11f, tint = ink.text(0.92), punch = if (ink.isLight) grey(0.97) else grey(0.10))
                        }
                    }
                    EditableText(
                        field = ProfileField.tagline,
                        style = TextSlotStyle(
                            size = 8.5f, weight = SHFont.semibold, color = ink.text(0.45),
                            tracking = 2f, uppercase = true,
                        ),
                        modifier = Modifier.scrubVeil(scrub.d, lead = 0.08, drop = 20f, pull = 18f),
                    )
                }
            }

            CutoutStatus(plane, theme, modifier = Modifier.padding(horizontal = (w * 0.05f).dp))
        }
    }
}
