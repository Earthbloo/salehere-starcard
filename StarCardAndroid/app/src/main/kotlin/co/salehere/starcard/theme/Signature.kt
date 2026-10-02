package co.salehere.starcard.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.ImageShader
import androidx.compose.ui.graphics.ShaderBrush
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.imageResource
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.offset
import androidx.compose.ui.unit.sp
import co.salehere.starcard.layout.PageLayout
import co.salehere.starcard.model.CardPage
import co.salehere.starcard.model.ClipInvocation
import co.salehere.starcard.model.Profile
import co.salehere.starcard.ui.widgets.VerifiedSeal
import co.salehere.starcard.ui.widgets.linkSlot
import kotlin.math.max
import kotlin.math.min

// MARK: - ลายเซ็นของผู้ออกบัตร (= Theme/Signature.swift)
//
// Sale Here ปรากฏในบทบาท "ผู้รับรอง" ไม่ใช่ผู้ออกแบบ — ไม่มีโลโก้ลอย ๆ กลางการ์ด และไม่มีที่ไหนใช้พื้นแดงเป็นค่าเริ่มต้น
// สามวง: วงใน (ตัวการ์ด — สีตามหมึก) · วงกลาง (เวที) · วงนอก (ของที่ส่งออก) — ยิ่งห่างจากตัวการ์ด ยิ่งพูดได้ดังขึ้น

object Signature {
    /** ดาวทอง = **สถานะ STAR** — ใช้กับความหมายนี้เท่านั้น ไม่ใช้ตกแต่ง */
    val gold: Color = SHColor.star
    /** แดงวงกลม = **ข้อเท็จจริงที่ Sale Here ออกให้** — ประทับได้เฉพาะชั้นหลักฐาน */
    val red: Color = SaleHereMarkColors.red
    /** เขียว = **ยืนยันตัวตนแล้ว (KYC)** */
    val green: Color = SHColor.success
    /** พื้นเวทีของแบรนด์ — มืดอมม่วงนิดหนึ่ง ไม่ใช่ดำโรงพิมพ์ */
    val stage: Color = rgb(0.047, 0.043, 0.058)

    /** วันที่ยืนยันตัวตน — ค่าจำลองจนกว่าจะต่อ `userVerify` ของจริง */
    const val verifiedOn = "12.09.69"

    /** ความสูงของแถบผู้ออกบัตร (หน่วยออกแบบ) — `PageLayout.content` กันพื้นที่ก้นหน้าไว้เท่านี้ */
    const val stripHeight: Float = 30f

    /** ที่อยู่ของการ์ด — โดเมนเดียวกับแอปหลัก */
    fun url(slug: String): String = "${ClipInvocation.host}/star/$slug"

    /** ฟอนต์โมโนของ "บรรทัดที่เครื่องอ่าน" — ที่อยู่ ซีเรียล วันที่ */
    fun mono(size: Float, weight: FontWeight = FontWeight.Medium): TextStyle = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontWeight = weight,
        fontSize = size.sp,
        platformStyle = ShPlatformStyle,
        lineHeightStyle = ShLineHeightStyle,
    )
}

/** หน้าตาของแถบผู้ออกบัตร — ทุกแบบพิมพ์สามอย่างเดียวกัน (ใคร · เมื่อไหร่ · ตรวจที่ไหน) */
enum class StripStyle(val raw: String) {
    /** บรรทัดเดียวใต้เส้นผม — ค่าเริ่มต้น */
    line("line"),
    /** รอยปรุ + พื้นจาง — สำหรับตระกูลโฟโต้การ์ด */
    ticket("ticket"),
    /** ไม่มีเส้นไม่มีพื้น — เบาสุด สำหรับใบที่รูปเต็มขอบ */
    ghost("ghost"),
    /** ตราปั๊มนูนสีเดียวกับการ์ด (ดู `SignatureEmboss`) */
    emboss("emboss"),
    /** ตราเดียวกันแต่ **พิมพ์ทึบด้วยหมึกของการ์ด** — ชื่อเคสคงเป็น `foil` เพราะเป็นค่าที่เขียนลงไฟล์การ์ดไปแล้ว */
    foil("foil");

    /** ลายเซ็นของใบนี้เป็นตรา (ปั๊มนูนหรือพิมพ์ทึบ) ไม่ใช่ตัวเขียนจาง */
    val isStamp: Boolean get() = this == emboss || this == foil

    val displayName: String
        get() = when (this) {
            line -> "บรรทัด"
            ticket -> "ตั๋ว"
            ghost -> "โปร่ง"
            emboss -> "ปั๊มนูน"
            foil -> "พิมพ์"
        }

    companion object {
        fun from(raw: String?): StripStyle? = entries.firstOrNull { it.raw == raw }
    }
}

// MARK: - S2 · แถบผู้ออกบัตร

object IssuerStrip {
    /** ขนาดตรา = ขนาดไอคอนแท็บหน้าแรกของแอปหลัก (MediaBox ของ PDF คือ 34×24) */
    const val markHeight: Float = 24f
}

/**
 * ขอบล่างของทุกหน้า — ถอดไม่ได้ ย้ายไม่ได้ — **ลายเซ็นของผู้ออกบัตร**
 * ไวยากรณ์เดียวกับบัตรเครดิต: ซ้ายล่างคือชื่อผู้ถือบัตร ขวาล่างคือตราของผู้ออกบัตร (ตราจริงของแอป สีแดงแบรนด์เสมอ)
 */
@Composable
fun IssuerStrip(style: StripStyle, slug: String, width: Float, modifier: Modifier = Modifier) {
    val ink = LocalCardInk.current
    val verified = Profile.me.creator.verified
    val label = "@$slug ${if (verified) "ยืนยันยอดแล้ว" else "ยอดกรอกเอง รอตรวจสอบ"} · ออกโดย Sale Here STAR"
    Box(
        modifier
            .size(width.dp, Signature.stripHeight.dp)
            .semantics(mergeDescendants = true) { contentDescription = label },
    ) {
        // พื้น
        when (style) {
            // แผ่นจาง ๆ ใต้ลายเซ็น — พื้นมืดสว่างขึ้นนิด พื้นกระดาษเข้มลงนิด
            StripStyle.ticket -> Box(Modifier.fillMaxSize().background(ink.fill(0.06)))
            // เวทีมืดที่มีรูปพื้นหลัง — ตัวอักษรบรรทัดนี้ต้องมี scrim ของตัวเองเหมือนตัวอักษรบนรูปทุกตัว
            StripStyle.line, StripStyle.ghost, StripStyle.emboss, StripStyle.foil -> if (!ink.isLight) {
                Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.opacity(0.32)))))
            }
        }
        Row(
            Modifier.fillMaxSize().padding(horizontal = PageLayout.margin.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // ผู้ถือบัตร — ชื่อนูนซ้ายล่างเหมือนบัตร · ตราติ๊กสีแดงเดียวกับตราผู้ออก = รับรองโดยคนเดียวกัน
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "@$slug",
                    style = sh(10.5f, SHFont.semibold),
                    color = ink.text(if (style == StripStyle.ghost) 0.82 else 0.9),
                    maxLines = 1, softWrap = false, overflow = TextOverflow.Ellipsis,
                    autoSize = TextAutoSize.StepBased(minFontSize = 8.4.sp, maxFontSize = 10.5.sp, stepSize = 0.25.sp),
                )
                // ตราติ๊กขึ้นเมื่อทุกช่องยืนยันยอดผ่านการเชื่อมบัญชี/API — ยอดที่กรอกเองบอกตรง ๆ ว่ารอตรวจ
                Row(horizontalArrangement = Arrangement.spacedBy(3.5.dp), verticalAlignment = Alignment.CenterVertically) {
                    if (verified) {
                        SymbolIcon(SHIcon.sealCheck, size = 9f, tint = Signature.red)
                    } else {
                        PIcon(Ph.clock, size = 9f, tint = ink.text(0.5))
                    }
                    Text(
                        if (verified) "ยืนยันยอดแล้ว" else "ยอดกรอกเอง · รอตรวจสอบ",
                        style = sh(9f, SHFont.medium),
                        color = ink.text(0.58),
                        maxLines = 1, softWrap = false,
                    )
                }
            }
            Spacer(Modifier.weight(1f, fill = false))
            // ผู้ออกบัตร — ตราจริง ขนาดจริง สีจริง
            StarLockup(height = IssuerStrip.markHeight, tint = Signature.red)
        }
        // เส้นบน
        when (style) {
            // เส้นผมไล่จางจากซ้ายไปขวา — อยู่ใต้ชื่อผู้ถือบัตรแล้วละลายหายก่อนถึงตรา
            StripStyle.line -> Box(
                Modifier
                    .align(Alignment.TopCenter)
                    .fillMaxWidth()
                    .padding(horizontal = PageLayout.margin.dp)
                    .height(0.8.dp)
                    .background(Brush.horizontalGradient(listOf(ink.line(0.3), ink.line(0.04)))),
            )
            // ขอบตั๋ว — เส้นผมทึบเต็มความกว้าง
            StripStyle.ticket -> Box(Modifier.align(Alignment.TopCenter).fillMaxWidth().height(0.7.dp).background(ink.line(0.2)))
            StripStyle.ghost, StripStyle.emboss, StripStyle.foil -> Unit
        }
    }
}

// MARK: - S3 · ระบบตราสามดวง

/**
 * ตราข้างชื่อ = เป็น Sale Here STAR — เหรียญกลีบตัวเดียวกับแถบหน้าดู · widget ตรารับรอง · รูปส่งออก
 * **ตราเดียว ทุกที่ หมึกเดียวกับตัวอักษรข้าง ๆ**
 */
@Composable
fun StarSeal(
    size: Float = 11f,
    /** หมึกของตรา = **สีเดียวกับชื่อที่มันเกาะอยู่** */
    tint: Color = Color.White,
    /** สีของเครื่องหมายถูก — สีของพื้นใต้ชื่อ */
    punch: Color = grey(0.10),
    modifier: Modifier = Modifier,
) {
    val shade = Color.Black.opacity(0.35)
    VerifiedSeal(
        radius = size * 0.68f,
        punch = punch,
        tint = tint,
        compact = true,
        modifier = modifier
            .verifySlot()
            .semantics { contentDescription = "Verified by Sale Here" }
            .shadow(elevation = (size * 0.12f).dp, shape = CircleShape, clip = false, ambientColor = shade, spotColor = shade),
    )
}

// MARK: - S4 · ซีเรียลผลงาน

object EPChip {
    enum class Tone { ink, accent, light }
}

/** ชิปเลขตอน EP — จุดแดงของผู้ออก + ตัวเลขโมโน บนแผ่นเล็กมุมมน ทรงเดียวกันทุกที่ที่มันโผล่ */
@Composable
fun EPChip(
    ep: String,
    tone: EPChip.Tone = EPChip.Tone.ink,
    size: Float = 8f,
    accent: Color = Color.White,
    modifier: Modifier = Modifier,
) {
    val fg = when (tone) {
        EPChip.Tone.ink -> rgb(0.98, 0.96, 0.92)
        EPChip.Tone.accent -> Color.White
        EPChip.Tone.light -> Color.Black.opacity(0.85)
    }
    val bg = when (tone) {
        EPChip.Tone.ink -> rgb(0.09, 0.08, 0.10)
        EPChip.Tone.accent -> accent
        EPChip.Tone.light -> Color.White.opacity(0.92)
    }
    Row(
        modifier
            .background(bg, RoundedCornerShape((size * 0.55f).dp))
            .padding(horizontal = (size * 0.75f).dp, vertical = (size * 0.38f).dp),
        horizontalArrangement = Arrangement.spacedBy((size * 0.45f).dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size((size * 0.5f).dp).background(Signature.red, CircleShape))
        Text(
            ep,
            style = Signature.mono(size, FontWeight.Bold).copy(letterSpacing = 0.4.sp),
            color = fg,
            maxLines = 1, softWrap = false,
        )
    }
}

// MARK: - S5 · ป้ายที่มาของตัวเลข

/** ตัวเลขทุกตัวบนการ์ดบอกว่ามาจากไหน — ใช้คำเดิมทุกที่ ห้ามแปรผัน */
sealed class Provenance {
    /** ยืนยันโดย Sale Here (จากงานในระบบ) */
    object verified : Provenance()
    /** จากบัญชีที่เชื่อม · เวลาที่ sync ล่าสุด */
    data class Connected(val ago: String) : Provenance()
    /** จากสกรีนช็อต insight ที่ Star อัปโหลด · วันที่ */
    data class Screenshot(val date: String) : Provenance()
    /** จากโปรไฟล์ STAR (ค่าที่ระบบเก็บไว้) */
    object profile : Provenance()
    /** ตั้งเอง — ราคาและข้อความที่เจ้าของการ์ดพิมพ์ */
    object own : Provenance()
    /** ผู้สมัครกรอกยอดเอง ยังไม่ได้เชื่อมบัญชี */
    object manual : Provenance()

    val label: String
        get() = when (this) {
            verified -> "ยืนยันโดย Sale Here"
            is Connected -> "จากบัญชีที่เชื่อม · $ago"
            is Screenshot -> "จากสกรีนช็อต · $date"
            profile -> "จากโปรไฟล์ STAR"
            own -> "ตั้งเอง"
            manual -> "กรอกเอง · รอตรวจสอบ"
        }
}

/**
 * ป้ายที่มาของตัวเลข — `onPhoto`: บนรูปถ่ายหมึกของการ์ดใช้ไม่ได้ ป้ายต้องเป็นขาวบนแผ่นมืดของตัวเอง
 */
@Composable
fun ProvenanceTag(kind: Provenance, onPhoto: Boolean = false, modifier: Modifier = Modifier) {
    val ink = LocalCardInk.current
    if (kind is Provenance.Connected) {
        VerifiedPill(kind.ago, ink, onPhoto, modifier)
    } else {
        PlainTag(kind, ink, onPhoto, modifier)
    }
}

/** ยอดจากบัญชีที่เชื่อม = แถบ Verified ฉบับย่อ: เหรียญรับรองตัวเดียวกับหน้าดูและรูปส่งออก · คำเต็ม · เวลาที่ดึง */
@Composable
private fun VerifiedPill(ago: String, ink: InkStyle, onPhoto: Boolean, modifier: Modifier) {
    val fg = if (onPhoto) Color.White.opacity(0.92) else ink.text(0.86)
    Row(
        modifier
            .verifySlot()
            .background(if (onPhoto) Color.Black.opacity(0.34) else ink.fill(0.12), CircleShape)
            .border(0.5.dp, if (onPhoto) Color.White.opacity(0.22) else ink.line(0.16), CircleShape)
            .padding(start = 3.dp, end = 7.dp, top = 2.5.dp, bottom = 2.5.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        VerifiedSeal(
            radius = 5.5f,
            punch = if (onPhoto || !ink.isLight) grey(0.12) else grey(0.97),
            tint = if (onPhoto) Color.White else ink.text(0.86),
            compact = true,
        )
        // เวลาที่ดึงยอดต่อท้ายเฉพาะตอนเป็นเวลาจริง ("2 ชม.") — ค่าที่เป็นประโยคทำให้ป้ายล้นขอบ widget
        val text = buildAnnotatedString {
            withStyle(SpanStyle(fontSize = 8.5.sp, fontWeight = SHFont.bold)) { append("Verified") }
            if (ago.any { it.isDigit() }) {
                withStyle(SpanStyle(fontSize = 8.sp, fontWeight = SHFont.medium)) { append(" · $ago") }
            }
        }
        Text(text, style = sh(8.5f, SHFont.bold), color = fg, maxLines = 1, softWrap = false)
    }
}

@Composable
private fun PlainTag(kind: Provenance, ink: InkStyle, onPhoto: Boolean, modifier: Modifier) {
    val fg = if (onPhoto) Color.White.opacity(0.8) else ink.text(0.62)
    Row(
        modifier
            // ยอดที่ยังกรอกเองก็เปิดแผ่นเดียวกัน — แผ่นบอกตรง ๆ ว่าข้อไหนยังรอ
            .verifySlot(kind == Provenance.manual || kind == Provenance.verified)
            .background(if (onPhoto) Color.Black.opacity(0.3) else ink.fill(0.10), CircleShape)
            .border(0.5.dp, if (onPhoto) Color.White.opacity(0.18) else ink.line(0.14), CircleShape)
            .padding(horizontal = 6.dp, vertical = 2.5.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Tinted(fg) {
            when (kind) {
                Provenance.verified -> SaleHereMark(size = 9f)
                is Provenance.Connected -> Box(Modifier.size(4.5.dp).background(Signature.green, CircleShape))
                is Provenance.Screenshot -> SFSymbol("camera.viewfinder", size = 7.5f)
                Provenance.profile -> SymbolIcon(SHIcon.starFill, size = 7f, tint = Signature.gold)
                Provenance.own -> SFSymbol("pencil", size = 7.5f)
                Provenance.manual -> SFSymbol("clock", size = 7.5f)
            }
            Text(kind.label, style = sh(8f, SHFont.semibold), color = fg, maxLines = 1, softWrap = false)
        }
    }
}

/**
 * ตราทุกดวงแตะแล้วได้คำตอบเดียวกัน — เปิดแผ่นตรวจสอบ (`VerifySheet`) ในหน้าดู
 * ขยายพื้นที่แตะรอบตัวตรา 8pt แล้วหักคืน ผังจึงไม่ขยับ (= `padding(8).linkSlot(url).padding(-8)`)
 * ลำดับ modifier ของ Compose กลับด้านกับ SwiftUI: ตัวนอกสุดคือหักคืน · ช่องลิงก์วัดที่ขนาดบวก 8 · ตัวในสุดคือขยาย
 */
@Composable
fun Modifier.verifySlot(on: Boolean = true): Modifier =
    this.negativePadding(8f).linkSlot(if (on) VerifiedFacts.sheetURL else null).padding(8.dp)

/** `.padding(-x)` ของ SwiftUI — รายงานขนาดเล็กกว่าลูก 2x แล้ววางลูกเลยขอบไป x (Compose ไม่รับ padding ติดลบ) */
internal fun Modifier.negativePadding(all: Float): Modifier = layout { measurable, constraints ->
    val px = all.dp.roundToPx()
    val placeable = measurable.measure(constraints.offset(horizontal = 2 * px, vertical = 2 * px))
    layout(max(0, placeable.width - 2 * px), max(0, placeable.height - 2 * px)) {
        placeable.place(-px, -px)
    }
}

// MARK: - S6 · ลายน้ำแบบลวดลาย

/**
 * ลาย Sale Here ซ้ำ ๆ แบบกระดาษหนังสือเดินทาง — ใช้บนเวทีและของที่ส่งออก **ไม่ใช้บนตัวการ์ด**
 * `scale` คือสัดส่วนของรูปในหน่วยออกแบบ (PNG nodpi 1px = 1pt)
 */
@Composable
fun SignaturePattern(opacity: Double = 0.045, scale: Float = 0.32f, modifier: Modifier = Modifier) {
    val bmp = ImageBitmap.imageResource(SHIcon.watermark)
    val density = LocalDensity.current.density
    val brush = remember(bmp, scale, density) {
        val shader = ImageShader(bmp, TileMode.Repeated, TileMode.Repeated)
        shader.setLocalMatrix(android.graphics.Matrix().apply { setScale(scale * density, scale * density) })
        ShaderBrush(shader)
    }
    Box(modifier.fillMaxSize().drawBehind { drawRect(brush, alpha = opacity.toFloat()) })
}

// MARK: - S6.5 · ลายเซ็นมุมการ์ด

/**
 * โลโก้ Sale Here ตัวโตมุมขวาล่าง **ของตัวการ์ด** — จาง ล้นพ้นขอบแผ่นแล้วถูกขอบตัด
 * สีของลายน้ำ = หมึกของการ์ดใบนั้น (ไม่ใช่แดงแบรนด์ · ไม่ใช่ขาวทุกใบ) · ขนาดอิง **ด้านสั้น** ของแผ่น
 */
@Composable
fun SignatureCorner(
    /** หมึกของการ์ดใบนั้น — ขาวบนใบมืด · ถ่านอาบเฉดธีมบนใบสว่าง */
    tint: Color = Color.White,
    /** หมึกเป็นฝั่งสว่างไหม (= การ์ดพื้นสว่าง) */
    light: Boolean = false,
    /** ความแรงเทียบค่ามาตรฐาน (1 = มาตรฐาน) */
    strength: Double = 1.0,
    modifier: Modifier = Modifier,
) {
    /** สัดส่วนกับ **ด้านสั้น** ของแผ่น */
    val span = 0.68f
    /** ส่วนที่ยอมให้ไหลพ้นขอบ (เทียบกับตัวมันเอง) */
    val bleedX = 0.12f
    val bleedY = 0.06f
    val alpha = ((if (light) 0.07 else 0.17) * strength).toFloat()

    BoxWithConstraints(modifier.fillMaxSize()) {
        val side = (if (maxWidth < maxHeight) maxWidth else maxHeight) * span
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.BottomEnd) {
            Icon(
                painter = painterResource(SHIcon.wordmark),
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier
                    .size(side)
                    .graphicsLayer {
                        // ลายเซ็นคนเขียนไม่เคยตรงกับขอบกระดาษ
                        rotationZ = -8f
                        transformOrigin = TransformOrigin(1f, 1f)
                        translationX = side.toPx() * bleedX
                        translationY = side.toPx() * bleedY
                        this.alpha = alpha
                        compositingStrategy = CompositingStrategy.Offscreen
                    }
                    // ไล่จางไปทางมุมที่มันไหลออกนอกแผ่น — ส่วนที่คมที่สุดอยู่ในแผ่นเสมอ
                    .drawWithContent {
                        drawContent()
                        drawRect(
                            Brush.linearGradient(listOf(tint, tint.opacity(0.35)), start = Offset.Zero, end = Offset(size.width, size.height)),
                            blendMode = BlendMode.SrcIn,
                        )
                    },
            )
        }
    }
}

// MARK: - S6.6 · ตราปั๊มนูน

/**
 * ตรา Sale Here STAR **ปั๊มนูนสีเดียวกับการ์ด** — ไม่มีสีของตัวเองเลยสักสี
 * วาดแค่ขอบสว่างบนซ้ายกับเงาล่างขวา แล้ว **เจาะตัวตราออก** เนื้อของตราจึงโปร่ง เห็นพื้นของการ์ดตรง ๆ
 */
@Composable
fun EmbossedLockup(
    height: Float = 26f,
    /** การ์ดพื้นสว่างไหม — พื้นสว่างเงาต้องทำงานหนักกว่าแสง */
    light: Boolean = false,
    /** **พิมพ์ทึบ** ด้วยหมึกของแผ่นแทนปั๊มนูนเปล่า (ชื่อยังเป็น `foil` เพราะค่าในไฟล์การ์ดคือ "foil") */
    foil: Boolean = false,
    /** หมึกของตราพิมพ์ — **สีเดียวกับพาดหัวของแผ่นนั้น** */
    tint: Color = Color.White,
    modifier: Modifier = Modifier,
) {
    if (foil) {
        // ตราพิมพ์สีเดียว — หมึกเดียวกับพาดหัวอ่านออกชัดเท่าพาดหัว แต่ไม่เพิ่มสีใหม่ให้งานของเขาสักสี
        LockupMark(height, tint.opacity(0.92), modifier.semantics { contentDescription = "Sale Here STAR" })
    } else {
        val depth = max(0.6f, height * 0.030f)
        Box(modifier.semantics { contentDescription = "Sale Here STAR" }) {
            Box(Modifier.graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen)) {
                LockupMark(height, Color.White.opacity(if (light) 0.72 else 0.42), Modifier.offset((-depth).dp, (-depth).dp))
                LockupMark(height, Color.Black.opacity(if (light) 0.36 else 0.62), Modifier.offset(depth.dp, (depth * 1.15f).dp))
                // เจาะเนื้อตราออก — เหลือแต่เสี้ยวแสงกับเสี้ยวเงารอบขอบ
                LockupMark(
                    height, Color.Black,
                    Modifier.graphicsLayer {
                        blendMode = BlendMode.DstOut
                        compositingStrategy = CompositingStrategy.Offscreen
                    },
                )
            }
            // เนื้อตรานูนขึ้นนิดเดียว — พอให้ตาจับรูปทรงได้บนพื้นเรียบ
            LockupMark(height, (if (light) Color.Black else Color.White).opacity(if (light) 0.045 else 0.06))
        }
    }
}

/** ตราจริงของแอป (`ic-salehere-star-outline`) สัดส่วน 34×24 — ย้อมสีเดียว */
@Composable
private fun LockupMark(height: Float, tint: Color, modifier: Modifier = Modifier) {
    Icon(
        painter = painterResource(SHIcon.star),
        contentDescription = null,
        tint = tint,
        modifier = modifier.height(height.dp).aspectRatio(34f / 24f),
    )
}

/** มุมที่ปั๊ม — หน้าที่ i และจุดกึ่งกลางของตรา (หน่วยออกแบบของหน้านั้น) */
data class EmbossSpot(val page: Int, val center: Offset)

object SignatureEmboss {
    /** มุมที่จะปั๊ม — null = การ์ดใบนี้มีใบที่ปั๊มตราของตัวเองแล้ว */
    fun spot(pages: List<CardPage>, pageSize: Size, mark: Size, inset: Size): EmbossSpot? {
        if (pages.any { p -> p.items.any { it.kind.takesEmboss && it.emboss } }) return null

        val y = pageSize.height - inset.height - mark.height / 2f
        val right = Offset(pageSize.width - inset.width - mark.width / 2f, y)
        val left = Offset(inset.width + mark.width / 2f, y)

        for (i in pages.indices.reversed()) {
            val photos = PageLayout.solve(pages[i].items, pageSize)
                .filter { it.item.kind.usesPhoto || it.item.kind.isFullBleed }
                .map { it.frame }
            for (c in listOf(right, left)) {
                val r = Rect(
                    c.x - mark.width / 2f, c.y - mark.height / 2f,
                    c.x + mark.width / 2f, c.y + mark.height / 2f,
                ).inflate(4f)
                if (photos.none { it.overlaps(r) }) return EmbossSpot(i, c)
            }
        }
        return EmbossSpot(max(0, pages.size - 1), right)
    }
}

/**
 * ลายเซ็นแบบปั๊มนูนของตัวการ์ด — มุมล่างของแผ่น **เหนือ widget ทุกชิ้น**
 * 1. **ไม่ปั๊มซ้ำ** เมื่อมีใบที่ปั๊มตราบนแผ่นของตัวเองอยู่แล้ว · 2. **ไม่ทับรูป** — ไล่หามุมล่างที่ไม่มี widget รูปอยู่ใต้มัน
 */
@Composable
fun SignatureEmboss(
    light: Boolean = false,
    foil: Boolean = false,
    /** หมึกของตราพิมพ์ — หมึกของการ์ดใบนั้น */
    tint: Color = Color.White,
    /** หน้าของการ์ด — ว่าง = ไม่มีข้อมูลผัง (โต๊ะตรวจงาน) วางขวาล่างตรง ๆ */
    pages: List<CardPage> = emptyList(),
    pageSize: Size = Size.Zero,
    /** ขอบนอกกับร่องคั่นหน้า — พรีวิวในคลังวางสามหน้าห่างกัน */
    margin: Float = 0f,
    gutter: Float = 0f,
    modifier: Modifier = Modifier,
) {
    BoxWithConstraints(modifier.fillMaxSize()) {
        val side = min(maxWidth.value, maxHeight.value)
        // ตราพิมพ์ต้องใหญ่พอจะอ่านออกตอนย่อทั้งใบ · ปั๊มนูนเล็กกว่าได้เพราะมันตั้งใจเงียบ
        val h = max(20f, side * (if (foil) 0.070f else 0.058f))
        val mark = Size(h * 34f / 24f, h)
        val inset = Size(side * 0.042f, side * 0.034f)

        if (pages.isEmpty() || pageSize.width < 1f) {
            EmbossedLockup(
                height = h, light = light, foil = foil, tint = tint,
                modifier = Modifier.align(Alignment.BottomEnd).padding(end = inset.width.dp, bottom = inset.height.dp),
            )
        } else {
            val spot = SignatureEmboss.spot(pages, pageSize, mark, inset)
            if (spot != null) {
                val cx = margin + spot.page * (pageSize.width + gutter) + spot.center.x
                val cy = margin + spot.center.y
                EmbossedLockup(
                    height = h, light = light, foil = foil, tint = tint,
                    modifier = Modifier.offset((cx - mark.width / 2f).dp, (cy - mark.height / 2f).dp),
                )
            }
        }
    }
}

// MARK: - S7 · ตราของเวที

/** ตรา "Sale Here STAR" สำหรับโครงของเวที — ย้อมสีเดียว บนเวทีมันคือป้ายของสถานที่ ไม่ใช่โลโก้สีแบรนด์ */
@Composable
fun StarLockup(height: Float = 14f, tint: Color = Color.White, modifier: Modifier = Modifier) {
    Icon(
        painter = painterResource(SHIcon.star),
        contentDescription = "Sale Here STAR",
        tint = tint,
        modifier = modifier.height(height.dp).aspectRatio(34f / 24f),
    )
}
