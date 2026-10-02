package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.layout.layout
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.offset
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.scrubDolly
import co.salehere.starcard.components.scrubSlide
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.LocalWidgetEmboss
import co.salehere.starcard.model.LocalWidgetEmbossBlind
import co.salehere.starcard.model.LocalWidgetLiftsPhoto
import co.salehere.starcard.model.LocalWidgetSurface
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.EdGrain
import co.salehere.starcard.theme.EmbossedLockup
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.PlatePatternLayer
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.StarSeal
import co.salehere.starcard.theme.TextFit
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.hsb
import co.salehere.starcard.theme.mixed
import co.salehere.starcard.theme.onLightSurface
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import kotlin.math.max
import kotlin.math.min

// MARK: - โปสเตอร์พอร์ต (= Views/Widgets/PosterWidgets.swift)
//
// ใบที่สามของตระกูลคัตเอาต์ แปลงตรงจากโปสเตอร์พอร์ตโฟลิโอที่เจ้าของการ์ดส่งมา
// — **ผัง สัดส่วน วัสดุ สี ตามต้นฉบับ · ตัวอักษรใช้ฟอนต์ของแอป**
//
// สองใบแรกของตระกูลคือ **เวทีมืด** (มีไฟ มีเงา) · ใบนี้คือ **แผ่นที่ถูกพิมพ์** — ไม่มีไฟ ไม่มีเงา
// เงาใต้ตัวจึงถูก **ปิด** (เงาบนกระดาษอ่านเป็นสติกเกอร์) · ส่วน **รูปยังเป็นสีของมันเอง** — รูปคือตัวเขา
//
// ชั้นที่ต้องทับกันจริง: **คำยักษ์** เต็มความกว้าง (หลังสุด) → **คน** PNG พื้นหลังใสยืนคร่อมคำ
// ตัวคนล้นขอบล่าง (`bleed`) ตั้งแต่ต้น รอยตัดที่เอวจึงจบนอกแผ่น ไม่ต้องมีแถบมาบัง

/**
 * วัสดุและหมึกของใบนี้ — **ทุกสีคิดจากพื้นที่ตัวอักษรนั่งอยู่จริง ไม่มีสีตายตัวสักสี** (= `PosterSkin`)
 *
 * กติกาข้อเดียว: **ถามพื้นก่อนว่าเป็นใคร แล้วค่อยเลือกหมึก**
 * - มีกระดาษ → แผ่นสว่างที่อมเฉดของธีมไว้บาง ๆ · หมึกเฉดเดียวกันแต่เข้มจนอ่านออก
 * - ไม่มีกระดาษ → พื้นคือ *การ์ด* · หมึกจึงเป็นหมึกของการ์ด (`InkStyle` พลิกให้เองทั้งสองฝั่ง)
 */
data class PosterSkin(
    /** ยังมีกระดาษรองอยู่ไหม — เกล็ด เศษหนังสือพิมพ์ มุมมน และแถบฐาน อ่านค่านี้ก่อนวาด */
    val papered: Boolean,
    val sheet: Color,
    /** สีของคำพาดหัว บรรทัดนำ และเส้นคาดฐาน */
    val accent: Color,
    val ink: Color,
    val inkSoft: Color,
    /** หมึกของเศษหนังสือพิมพ์ */
    val news: Color,
) {
    companion object {
        fun make(surface: WidgetSurface, theme: CardTheme, on: InkStyle): PosterSkin {
            val hue = theme.backdropHue
            // บนกระจกของ chrome — ผังของแผ่นพิมพ์ทั้งชุด แต่ตัวแผ่นใส หมึกเป็นหมึกของการ์ด
            if (surface == WidgetSurface.pane) {
                return PosterSkin(
                    papered = true, sheet = Color.Transparent,
                    accent = theme.accent,
                    ink = on.text(0.95), inkSoft = on.text(0.55),
                    news = on.text(0.45),
                )
            }
            // # การ์ดคู่สี — แผ่นคือ **สีเข้มของคู่** ชุดเดียวกับโปสเตอร์สายงาน
            // แผ่นขาวใบเดียวบนหน้าที่มีแผ่นกรมท่าเรียงกันอ่านเป็น "สองระบบสีที่วางปนกัน"
            val duo = theme.activeDuo
            if (surface != WidgetSurface.clear && duo != null) {
                val plate = PosterPlate.plate(theme)
                val ink = PosterPlate.cream(theme)
                return PosterSkin(
                    papered = true, sheet = plate,
                    accent = ink, ink = ink,
                    inkSoft = ink.mixed(plate, 0.42),
                    news = duo.dark,
                )
            }
            if (surface != WidgetSurface.clear) {
                return PosterSkin(
                    papered = true,
                    // กระดาษอมเฉดของธีมไว้ **นิดเดียว** — ขาวสนิทอ่านเป็นพื้นแอป · ย้อมจนเห็นสีกลายเป็นแผ่นพลาสติก
                    sheet = hsb(hue, 0.045, 0.965),
                    accent = theme.rawAccent.onLightSurface(),
                    ink = hsb(hue, 0.16, 0.11),
                    inkSoft = hsb(hue, 0.10, 0.42),
                    news = hsb(hue, 0.12, 0.28),
                )
            }
            return PosterSkin(
                papered = false, sheet = Color.Transparent,
                accent = theme.accent,
                ink = on.text(0.95), inkSoft = on.text(0.55),
                news = Color.Transparent,
            )
        }
    }
}

/**
 * ระยะบรรทัดจริงของหนังสือพิมพ์ย่อส่วน — **ค่าคงที่เป็น pt ไม่ใช่สัดส่วนของชิ้น**
 * สิ่งที่บอกตาว่า "นี่คือตัวหนังสือ" คือ *ความถี่* ไม่ใช่รูปร่างของแต่ละบรรทัด
 */
private const val PosterClippingLead = 3.1f

/**
 * เศษหนังสือพิมพ์ที่แปะเป็นฉากหลัง — **แถบตัวอักษร ไม่ใช่ตัวอักษรจริง** (= `PosterClipping`)
 * ข้อความจริงที่ 6pt อ่านไม่ออกอยู่ดี และรูปที่ export จะมีประโยคที่ไม่มีใครเขียนติดไปด้วย
 * - seed: เมล็ดคงที่ต่อชิ้น — ความยาวบรรทัดต้องไม่เปลี่ยนทุกครั้งที่วาดใหม่
 */
@Composable
fun PosterClipping(
    tint: Color = grey(0.2),
    opacity: Double = 0.42,
    seed: ULong = 0x9E3779B97F4A7C15uL,
    modifier: Modifier = Modifier,
) {
    Canvas(modifier.fillMaxSize()) {
        var s = seed
        fun rnd(): Float {
            s = s xor (s shl 13)
            s = s xor (s shr 7)
            s = s xor (s shl 17)
            return (s % 10_000uL).toFloat() / 10_000f
        }
        // คิดเป็น pt ของดีไซน์ แล้วคูณ density ตอนวาด
        val px = density
        val w = size.width / px
        val h = size.height / px
        val pad = min(7f, w * 0.08f)
        // สองคอลัมน์เมื่อชิ้นกว้างพอ — หน้าหนังสือพิมพ์ไม่มีคอลัมน์เดียวกว้างเต็มหน้า
        val cols = if (w - pad * 2 > 90f) 2 else 1
        val gutter = if (cols == 2) 7f else 0f
        val colW = (w - pad * 2 - gutter) / cols
        val head = min(h * 0.10f, 5.5f)

        // พาดหัวของเศษกระดาษ — แถบหนาบนสุด
        drawRect(
            tint.opacity(opacity * 1.15),
            topLeft = Offset(pad * px, pad * px),
            size = Size((w - pad * 2) * 0.72f * px, head * px),
        )

        for (c in 0 until cols) {
            val x = pad + c * (colW + gutter)
            var y = pad + head + 5f
            while (y < h - pad) {
                val ww = colW * (0.72f + rnd() * 0.28f)
                drawRect(
                    tint.opacity(opacity * (0.55 + rnd().toDouble() * 0.45)),
                    topLeft = Offset(x * px, y * px),
                    size = Size(ww * px, 1.1f * px),
                )
                y += PosterClippingLead
            }
        }
    }
}

// MARK: - โปสเตอร์พอร์ต

/** คำพาดหัว — ของ *ดีไซน์* ไม่ใช่ของโปรไฟล์ จึงเก็บต่อชิ้นแบบเดียวกับสำรับบรรณาธิการ */
private const val PortfolioHeadlinePreset = "PORTFOLIO"

/**
 * ระยะห่างติดลบเหนือคำพาดหัว (= `VStack(spacing: -x)`) — Compose ห้าม spacing/padding ติดลบ
 * กล่องเตี้ยลงด้านบนตามที่สั่ง แต่ตัวอักษรยังวาดเต็มตัว
 */
private fun Modifier.posterPullUp(pt: Float): Modifier = layout { measurable, constraints ->
    val t = pt.dp.roundToPx()
    val p = measurable.measure(constraints.offset(vertical = t))
    layout(p.width, max(0, p.height - t)) { p.place(0, -t) }
}

/**
 * โปสเตอร์พอร์ต — ชื่อเซอริฟเอียง + คำพาดหัวยักษ์ · คนยืนคร่อมคำ · ตราปั๊มนูนมุมขวาล่าง (= `ArtPortfolioPoster`)
 *
 * อ่านขนาดจากกรอบจริง ไม่ใช่ `size` ที่ส่งมา — ทุกระยะบนแผ่นคิดเป็น *สัดส่วน* ของกรอบ
 * ใบนี้จึงบอกระบบตามจริงว่า "ยืดหดได้ทุกขนาด" (หมุดย่อความสูงของการ์ดลากย่อลงได้)
 */
@Composable
fun ArtPortfolioPoster(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    BoxWithConstraints(modifier.fillMaxSize()) {
        val w = max(1f, if (constraints.hasBoundedWidth) maxWidth.value else size.width)
        val h = max(1f, if (constraints.hasBoundedHeight) maxHeight.value else size.height)
        PortfolioPoster(theme, w, h)
    }
}

@Composable
private fun PortfolioPoster(theme: CardTheme, w: Float, h: Float) {
    val photos = LocalPhotoStore.current
    val wid = LocalWidgetID.current
    val liftsPhoto = LocalWidgetLiftsPhoto.current
    val scrub = LocalPageScrub.current
    val surface = LocalWidgetSurface.current
    val cardInk = LocalCardInk.current
    val embossed = LocalWidgetEmboss.current
    val embossBlind = LocalWidgetEmbossBlind.current
    val measurer = TextFit.rememberMeasurer()

    val skin = PosterSkin.make(surface, theme, cardInk)
    val plane: CutoutPlane = if (photos != null) {
        cutoutPlane(photos, 1, wid, lift = liftsPhoto)
    } else {
        // ไม่มีคลังรูป (พรีวิวนอกการ์ด) — ทางเดียวกับ "ยังไม่มีรูปของเจ้าของ": รูปตัวอย่าง หรือโหมดกรอบ
        CutoutSample.image?.let { CutoutPlane.Subject(it, own = false) } ?: CutoutPlane.Framed
    }
    val lifting = photos?.let { cutoutLifting(it, 1, wid, liftsPhoto) } ?: false
    val pad = w * 0.055f
    val headline = Profile.me.note(wid, 1, preset = PortfolioHeadlinePreset).uppercase()
    // คำพาดหัวต้องกิน **เต็มความกว้าง** เสมอ — ขนาดตายตัวทำให้คำสั้นลอยอยู่ครึ่งแผ่น และคำยาวถูกย่อจนจิ๋ว
    val fs = Ed.fitted(measurer, headline, SHFont.heavy, width = w - pad * 2, cap = h * 0.19f, floor = 16f)
    // ── ที่ยืนของตัวคน คิดจาก **ก้อนตัวอักษร** ไม่ใช่จากสัดส่วนของใบ
    // หัวคนตัดผ่านช่วงล่างของตัวอักษรเสมอ (~60% ของตัวพาดหัว) ไม่ว่ากรอบจะสูงเท่าไหร่
    val bleed = h * 0.05f
    val typeTop = h * 0.055f
    // บรรทัดชื่อเหนือพาดหัว: เซอริฟเอียงตัวบาง ดึงชิดคำพาดหัว
    val nameSize = fs * 0.42f
    val nameGap = -fs * 0.26f
    val subjectTop = typeTop + nameSize * 1.3f + nameGap + fs * 0.60f
    val subjectH = max(h * 0.4f, h + bleed - subjectTop)
    val shape = RoundedCornerShape(if (skin.papered) 18.dp else 0.dp)

    Box(Modifier.size(w.dp, h.dp).clip(shape)) {
        // ── กระดาษ
        if (skin.papered) {
            Box(Modifier.fillMaxSize().background(skin.sheet))
            PlatePatternLayer(sheet = skin.sheet)
            EdGrain(count = 320, opacity = 0.05, tint = Color.Black)
        }

        // ตราปั๊มนูน Sale Here STAR — มุมขวาล่าง ตำแหน่งผู้ออกบัตร · อยู่ **ใต้ตัวคน**
        // มันถูกกดลงบนแผ่นกระดาษ คนยืนอยู่หน้าแผ่น ลากคนมาทับเมื่อไหร่ตราก็แค่ถูกบัง
        if (embossed) {
            EmbossedLockup(
                height = max(20f, h * (if (embossBlind) 0.085f else 0.10f)),
                light = if (surface == WidgetSurface.glass) theme.activeDuo == null else cardInk.isLight,
                foil = !embossBlind,
                tint = skin.accent,
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(end = (pad * 0.9f).dp, bottom = (pad * 0.75f).dp),
            )
        }

        // ── ชั้นหลัง: ชื่อ + คำยักษ์ — ชื่อเจ้าของการ์ดอยู่ **กลาง** เหนือคำพาดหัว ดึงลงมาชิดจนเกือบแตะ
        // ชั้นหลังสุดวิ่งสวนแรงที่สุด — ตาอ่านความลึกจาก *ความต่างของอัตรา* ไม่ใช่จากระยะ
        Column(
            Modifier
                .scrubSlide(scrub.d, travel = -w * 0.26f, fade = 0.84, eased = false)
                .padding(start = pad.dp, top = (h * 0.055f).dp)
                .width((w - pad * 2).dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            // ตรายืนยันเกาะชื่อเหมือนทุกใบในตระกูลโปรไฟล์ (ชื่อ · ตรายืนยัน · สายงาน)
            Row(
                horizontalArrangement = Arrangement.spacedBy((nameSize * 0.28f).dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                EditableText(
                    field = ProfileField.personName,
                    style = TextSlotStyle(size = nameSize, weight = SHFont.regular, face = CardFont.serif,
                        color = skin.accent, italic = true),
                    autoSizeMin = 0.45f,
                    modifier = Modifier.weight(1f, fill = false),
                )
                if (Profile.me.creator.verified) {
                    StarSeal(
                        size = max(9f, nameSize * 0.5f),
                        tint = skin.accent,
                        punch = if (skin.papered && surface == WidgetSurface.glass) skin.sheet
                        else if (cardInk.isLight) grey(0.97) else grey(0.10),
                    )
                }
            }
            // heavy ไม่ใช่ black — ที่น้ำหนักหนาสุด NotoSansThai วางสระบนชนวรรณยุกต์
            EditableText(
                field = ProfileField.note,
                index = 1,
                widget = wid,
                preset = PortfolioHeadlinePreset,
                hint = "คำพาดหัว",
                style = TextSlotStyle(size = fs, weight = SHFont.heavy, color = skin.accent,
                    tracking = -fs * 0.045f, uppercase = true, corner = 6f),
                text = Profile.me.note(wid, 1, preset = PortfolioHeadlinePreset),
                autoSizeMin = 0.3f,
                modifier = Modifier.posterPullUp(-nameGap),
            )
        }

        // ── ชั้นกลาง: คน
        when (plane) {
            is CutoutPlane.Subject -> {
                // **อยู่กลางแผ่น** และสูงพอให้หัวแตะคำพาดหัวเท่านั้น — "อยู่หลังคำ" ต้องการแค่ **คาบเกี่ยว** ไม่ใช่กลืน
                // ล้นขอบล่างเล็กน้อย — รอยตัดที่เอวจะได้จบนอกแผ่น ไม่ใช่กลางแผ่น
                Box(
                    Modifier.fillMaxSize().offset(y = bleed.dp),
                    contentAlignment = Alignment.BottomCenter,
                ) {
                    CutoutSubject(
                        image = plane.image,
                        height = subjectH,
                        d = scrub.d,
                        drift = w * 0.04f,
                        shadow = false,
                        // กรอบของ *ช่อง* เท่าตัวคนพอดี — ปุ่มเปลี่ยนรูปเกาะกรอบนี้
                        modifier = Modifier
                            .wrapContentSize(Alignment.BottomCenter, unbounded = true)
                            .photoSlot(1),
                    )
                }
            }
            CutoutPlane.Framed -> PortfolioFramedPlate(w, top = subjectTop + fs * 0.45f, h = h, d = scrub.d)
        }

        // ป้ายสถานะไปอยู่ **ขวาบน** — ซ้ายบนของใบนี้คือบรรทัดชื่อ ป้ายจะทับมันพอดีทุกครั้งที่เข้าโหมดแต่ง
        CutoutStatus(
            plane, theme, lifting = lifting,
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding((pad * 0.7f).dp),
        )
    }
}

/**
 * โหมดกรอบ — รูปทึบถูก **พิมพ์เป็นบล็อก** ใต้คำพาดหัว โปสเตอร์ยังเป็นโปสเตอร์ใบเดิม
 * บล็อกลง **ชนขอบล่างของใบ** และอยู่กลางกรอบเหมือนตัวคัตเอาต์ · กรอบของช่อง (`photoSlot`) อยู่ตรงที่รูปถูกวาดจริง
 * เงาบาง ๆ รอบบล็อก — รูปพื้นหลังสว่างจะกลืนไปกับกระดาษจนอ่านไม่ออกว่าตรงไหนคือขอบรูป
 */
@Composable
private fun PortfolioFramedPlate(w: Float, top: Float, h: Float, d: Float) {
    val shade = Color.Black.opacity(0.13)
    Box(Modifier.size(w.dp, h.dp)) {
        Box(
            Modifier
                .align(Alignment.TopCenter)
                .offset(y = top.dp)
                .photoSlot(1)
                .shadow(10.dp, RectangleShape, clip = true, ambientColor = shade, spotColor = shade)
                .size((w * 0.70f).dp, max(40f, h - top).dp),
        ) {
            WidgetPhoto(1, Modifier.fillMaxSize().scrubDolly(d, shift = w * 0.04f, zoom = 0.12f))
        }
    }
}
