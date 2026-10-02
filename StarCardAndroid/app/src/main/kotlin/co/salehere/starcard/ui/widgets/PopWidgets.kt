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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.key
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.ClipOp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.addOutline
import androidx.compose.ui.graphics.asAndroidPath
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.layout.layout
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.LocalPopSkin
import co.salehere.starcard.model.LocalWidgetBorder
import co.salehere.starcard.model.LocalWidgetSurface
import co.salehere.starcard.model.PopSkin
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.RateItem
import co.salehere.starcard.model.SocialProfile
import co.salehere.starcard.model.VerifiedWork
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.BrandIcon
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.CornerStyle
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.ProvenanceTag
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.SymbolIcon
import co.salehere.starcard.theme.TextFit
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.theme.systemFont
import co.salehere.starcard.ui.LocalSlotTilt
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import co.salehere.starcard.ui.editor.dataValue
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

// MARK: - สำรับ "แผ่นสติกเกอร์" (= Views/Widgets/PopWidgets.swift)
//
// แปลงตรงจากไฟล์ดีไซน์ `template STAR CARD_1.svg` (กระดาษเทป) และ `_2.svg` (กระจกชมพู)
// ทั้งสองไฟล์คือ **ผังเดียวกัน 8 กล่อง** ต่างกันแค่วัสดุ — วัสดุส่งลงมาทาง `LocalPopSkin`
//
// กติกาที่ยกมาจากสำรับ Gen Z:
// 1. **หนึ่งสกิน หนึ่งวัสดุ** — กระจก = กล่องขาวมุมมน เงานุ่ม ป้ายเม็ดยาชมพู ·
//    กระดาษ = กล่องขาวมุมเหลี่ยม เงาแข็ง ป้ายดำเอียง เทปกาว รูเจาะสมุด
// 2. **หมึกคงที่ ไม่พลิกตามหมึกการ์ด** — ตัวหนังสือบนกล่องขาวเป็นถ่านเสมอ
// 3. สีชมพูของป้าย/ขอบ/ราคา = `theme.rawAccent` — เปลี่ยนพาเลตต์แล้วทั้งแผ่นเปลี่ยนตาม

object Pop {
    /**
     * **ค่าสำรองเท่านั้น** — วัสดุจริงมาจากชนิดของ widget (`WidgetKind.popSkin`) ทาง `LocalPopSkin`
     * ตัวนี้เหลือไว้ให้พรีวิวที่วาดวิวตรง ๆ โดยไม่ผ่าน `WidgetBody` ยังได้หน้าตาที่เข้ากับธีม
     */
    fun skin(t: CardTheme): PopSkin = if (t.corner == CornerStyle.soft) PopSkin.paper else PopSkin.glass

    /** ถ่านอมม่วง — ดำสนิทบนกล่องขาวชมพูอ่านแข็งเกินไป */
    val ink = rgb(0.11, 0.10, 0.13)
    val inkSoft = rgb(0.40, 0.37, 0.43)
    val paper = Color.White
    /** เส้นคั่นบนกระดาษ */
    val rule = rgb(0.84, 0.82, 0.85)

    /** สีชมพูของแผ่น — สีเน้นดิบของธีม (ไม่ผ่านสูตรหมึก เพราะวางบนกล่องขาวของตัวเอง) */
    fun pink(t: CardTheme): Color = t.rawAccent
    fun pinkSoft(t: CardTheme): Color = t.rawAccentSoft

    /**
     * พื้นของแผ่นตามพื้นผิวที่ผู้ใช้เลือก (แผงกล่องเหลือสองแบบ: กระจก · เข้ม)
     * "เข้ม" ที่นี่แปลว่า **ทึบ** — กระจกคือ ~62% ที่เห็นกริดพื้นหลังทะลุตามไฟล์ดีไซน์
     */
    fun sheetFill(s: WidgetSurface, skin: PopSkin, theme: CardTheme): Color = when (s) {
        WidgetSurface.glass -> paper.opacity(if (skin == PopSkin.glass) 0.62 else 0.9)
        // สำรับนี้ไม่ให้เลือก "ไม่มีพื้น" — ไฟล์เก่าที่เคยเก็บค่านั้นไว้ตกมาเป็นกล่องทึบ ไม่ใช่กล่องหาย
        WidgetSurface.dim, WidgetSurface.clear, WidgetSurface.pane -> paper
    }

    @Suppress("UNUSED_PARAMETER")
    fun sheetShadow(s: WidgetSurface, skin: PopSkin, theme: CardTheme): Color =
        if (skin == PopSkin.glass) pink(theme).opacity(0.35) else Color.Black.opacity(0.22)

    /** ความสูงของป้ายหัวข้อ — ครึ่งหนึ่งโผล่พ้นขอบบนของกล่อง */
    const val labelHeight: Float = 26f
    /** ป้ายทรงแท็บกว้างของสามกล่องแถวล่าง */
    const val labelHeightWide: Float = 30f

    /** ไอคอนประจำสายงาน — ป้ายในลิสต์ต้องมีรูปนำทุกบรรทัด (ชื่อ SF Symbol) */
    fun nicheIcon(t: String): String {
        val s = t.lowercase()
        if (s.contains("บิวตี้") || s.contains("สกินแคร์") || s.contains("เมคอัพ") || s.contains("beauty")) {
            return "cylinder.split.1x2.fill"
        }
        if (s.contains("ไลฟ์") || s.contains("life")) return "bubble.left.and.bubble.right.fill"
        if (s.contains("ออกกำลัง") || s.contains("ฟิต") || s.contains("fit") || s.contains("กีฬา")) return "dumbbell.fill"
        if (s.contains("คาเฟ่") || s.contains("cafe") || s.contains("กาแฟ")) return "house.fill"
        if (s.contains("อาหาร") || s.contains("food")) return "fork.knife"
        if (s.contains("แฟชั่น") || s.contains("fashion")) return "tshirt.fill"
        if (s.contains("ท่องเที่ยว") || s.contains("travel")) return "airplane"
        if (s.contains("แม่") || s.contains("เด็ก")) return "figure.and.child.holdinghands"
        if (s.contains("เกม") || s.contains("game")) return "gamecontroller.fill"
        return "tag.fill"
    }
}

// MARK: - ชิ้นส่วนร่วม

/**
 * ป้ายหัวข้อ — ไอคอนในวงขาว + ชื่อหมวด
 * กระจก: เม็ดยาชมพู · กระดาษ: แถบดำมุมเล็กเอียงนิดหนึ่งเหมือนสติกเกอร์ที่แปะมือ
 * - wide: แถบกว้าง — สามกล่องแถวล่างในต้นฉบับใช้ป้ายทรง "แท็บ" กว้างเกือบเท่ากล่อง ตัวหนังสือใหญ่กว่า
 */
@Composable
fun PopLabel(theme: CardTheme, text: String, icon: String, wide: Boolean = false, modifier: Modifier = Modifier) {
    val skin = LocalPopSkin.current ?: Pop.skin(theme)
    val glass = skin == PopSkin.glass
    val h = if (wide) Pop.labelHeightWide else Pop.labelHeight
    val shape: Shape = when {
        glass && wide -> RoundedCornerShape(12.dp)
        glass -> CircleShape
        else -> RoundedCornerShape(3.dp)
    }
    val textSize = if (wide) 15f else 12.5f
    Row(
        modifier
            .graphicsLayer {
                rotationZ = if (skin == PopSkin.paper) -2f else 0f
                transformOrigin = TransformOrigin(0f, 1f)
            }
            .then(if (wide) Modifier.fillMaxWidth() else Modifier)
            .height(h.dp)
            .background(if (glass) Pop.pink(theme) else Pop.ink, shape)
            .padding(start = (if (wide) 8f else 5f).dp, end = 12.dp),
        horizontalArrangement = Arrangement.spacedBy((if (wide) 7f else 6f).dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        val d = if (wide) 20f else 17f
        Box(Modifier.size(d.dp).background(Color.White, CircleShape), contentAlignment = Alignment.Center) {
            PopGlyph(icon, size = if (wide) 11f else 9.5f, tint = if (glass) Pop.pink(theme) else Pop.ink)
        }
        Text(
            text,
            style = sh(textSize, SHFont.bold),
            color = Color.White,
            maxLines = 1,
            softWrap = false,
            autoSize = TextAutoSize.StepBased(minFontSize = (textSize * 0.7f).sp, maxFontSize = textSize.sp, stepSize = 0.5.sp),
        )
    }
}

/**
 * กล่องขาวของทุก widget ในสำรับ — ป้ายหัวข้อคร่อมขอบบนซ้าย
 * เว้นขอบนอก 4pt ไว้ให้เงา — `WidgetChrome` clip เนื้อหาเข้ากรอบ widget พอดี เงาที่ล้นออกจะหาย
 * - fold: มุมกระดาษพับที่ขอบขวาล่าง — ใช้เฉพาะสกินกระดาษกับกล่องที่ต้นฉบับพับ
 * - wide: ป้ายทรงแท็บกว้าง (ดู `PopLabel`)
 */
@Composable
fun PopSheet(
    theme: CardTheme,
    label: String? = null,
    icon: String = "star.fill",
    pad: Float = 10f,
    fold: Boolean = false,
    wide: Boolean = false,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val skin = LocalPopSkin.current ?: Pop.skin(theme)
    val surface = LocalWidgetSurface.current
    val border = LocalWidgetBorder.current
    val glass = skin == PopSkin.glass
    val r = if (glass) 20f else 5f
    val shape = RoundedCornerShape(r.dp)
    val lh = if (wide) Pop.labelHeightWide else Pop.labelHeight
    val top = if (label == null) 0f else lh / 2

    Box(modifier.fillMaxSize().padding(4.dp)) {
        Box(Modifier.fillMaxSize().padding(top = top.dp)) {
            Box(
                Modifier
                    .matchParentSize()
                    .softShadow(
                        Pop.sheetShadow(surface, skin, theme),
                        radius = if (glass) 9f else 5f, y = if (glass) 5f else 4f, shape = shape,
                    )
                    .background(Pop.sheetFill(surface, skin, theme), shape)
                    // กระจก: ประกายขอบบนบาง ๆ ให้แผ่นอ่านเป็นกระจก ไม่ใช่ขาวจาง
                    .then(
                        if (surface == WidgetSurface.glass) {
                            Modifier.border(
                                1.2.dp,
                                Brush.verticalGradient(listOf(Color.White.opacity(0.95), Color.White.opacity(0.25))),
                                shape,
                            )
                        } else Modifier,
                    )
                    .then(if (border) Modifier.border(1.6.dp, Pop.pink(theme), shape) else Modifier),
            ) {
                if (fold && skin == PopSkin.paper) PopFold(theme, modifier = Modifier.align(Alignment.BottomEnd))
            }
            Box(
                Modifier
                    .matchParentSize()
                    .clip(shape)
                    .padding(pad.dp)
                    .padding(top = (if (label == null) 0f else lh / 2 + 2).dp),
                contentAlignment = Alignment.TopStart,
            ) { content() }
        }
        if (label != null) {
            PopLabel(
                theme, label, icon, wide,
                Modifier
                    .align(Alignment.TopStart)
                    .padding(
                        start = (if (glass) (if (wide) 6f else 10f) else 8f).dp,
                        end = (if (wide) 14f else 0f).dp,
                    ),
            )
        }
    }
}

/**
 * แผ่นที่แปะเอียง — หมุนทั้งแผ่น แล้ว **ย่อให้มุมทั้งสี่ยังอยู่ในกรอบ widget**
 * บอกมุมลงไปทาง `LocalSlotTilt` ด้วย เส้นประของช่องข้อความบนแผ่นจะได้เอียงตาม
 * - degrees: องศา — บวก = ตามเข็ม
 */
@Composable
fun PopTilt(degrees: Double, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    BoxWithConstraints(modifier.fillMaxSize()) {
        val t = abs(degrees) * PI / 180
        val c = cos(t).toFloat()
        val s = sin(t).toFloat()
        val w = if (constraints.hasBoundedWidth) max(maxWidth.value, 1f) else 1f
        val h = if (constraints.hasBoundedHeight) max(maxHeight.value, 1f) else 1f
        val fit = min(w / (w * c + h * s), h / (w * s + h * c))
        CompositionLocalProvider(LocalSlotTilt provides degrees) {
            Box(
                Modifier
                    .size(w.dp, h.dp)
                    .graphicsLayer {
                        rotationZ = degrees.toFloat()
                        scaleX = fit
                        scaleY = fit
                    },
            ) { content() }
        }
    }
}

/**
 * มุมกระดาษพับ — บอกว่านี่คือแผ่นกระดาษ ไม่ใช่กล่อง
 * สามเหลี่ยมล่างขวา = พื้นการ์ดที่โผล่จากมุมที่ถูกพับออก · สามเหลี่ยมบนซ้าย = ด้านหลังของกระดาษที่พับขึ้นมา
 */
@Composable
fun PopFold(theme: CardTheme, size: Float = 16f, modifier: Modifier = Modifier) {
    val soft = Pop.pinkSoft(theme).opacity(0.85)
    Canvas(modifier.size(size.dp)) {
        val s = this.size.width
        val back = Path().apply { moveTo(0f, s); lineTo(s, 0f); lineTo(s, s); close() }
        drawPath(back, soft)
        val flap = Path().apply { moveTo(0f, s); lineTo(s, 0f); lineTo(0f, 0f); close() }
        drawNativeShadow(flap, Color.Black.opacity(0.18), 1.5f, -1f, -1f)
        drawPath(
            flap,
            Brush.linearGradient(listOf(rgb(0.97, 0.96, 0.97), rgb(0.80, 0.77, 0.80)), start = Offset.Zero, end = Offset(s, s)),
        )
    }
}

/** เทปกาวสีชมพูโปร่ง — แปะเฉียงบนมุมรูปในสกินกระดาษ */
@Composable
fun PopTape(theme: CardTheme, width: Float = 54f, modifier: Modifier = Modifier) {
    Box(
        modifier
            .size(width.dp, 13.dp)
            .background(Pop.pink(theme).opacity(0.62))
            .border(0.5.dp, Color.White.opacity(0.35)),
    )
}

/**
 * ป้าย VERIFIED BY SALE HERE — สีน้ำเงินคงที่ตามไฟล์ดีไซน์ ไม่ย้อมตามธีม
 * (ตราของผู้รับรองต้องเป็นสีของผู้รับรอง ไม่ใช่สีของการ์ดที่มันรับรองอยู่)
 */
@Composable
fun PopVerified(modifier: Modifier = Modifier) {
    val blue = rgb(0.16, 0.50, 0.90)
    val seal = rgb(0.42, 0.80, 0.98)
    Box(modifier.fillMaxWidth(), contentAlignment = Alignment.CenterStart) {
        Row(
            Modifier
                .background(
                    Brush.horizontalGradient(listOf(rgb(0.30, 0.66, 0.96), rgb(0.13, 0.40, 0.84))),
                    RoundedCornerShape(9.dp),
                )
                .padding(start = 3.dp, end = 8.dp, top = 3.dp, bottom = 3.dp),
            horizontalArrangement = Arrangement.spacedBy(5.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // ตราหยัก: ฟ้าอ่อนหยัก → วงขาว → เครื่องหมายถูกฟ้า (ตามไฟล์)
            Box(Modifier.size(36.dp), contentAlignment = Alignment.Center) {
                Canvas(Modifier.size(36.dp)) {
                    drawPath(SealScallop(petals = 12, depth = 0.055f).path(this.size), seal)
                }
                Box(Modifier.size(23.dp).background(Color.White, CircleShape))
                PopGlyph("checkmark", size = 13f, tint = blue)
            }
            Column {
                Text(
                    "VERIFIED",
                    style = sh(19f, SHFont.black).copy(letterSpacing = 0.2.sp),
                    color = Color.White, maxLines = 1, softWrap = false,
                    autoSize = TextAutoSize.StepBased(minFontSize = (19f * 0.6f).sp, maxFontSize = 19.sp, stepSize = 0.5.sp),
                )
                Text(
                    "BY SALE HERE",
                    style = sh(10f, SHFont.black).copy(letterSpacing = 0.3.sp),
                    color = Color.White, maxLines = 1, softWrap = false,
                    autoSize = TextAutoSize.StepBased(minFontSize = (10f * 0.6f).sp, maxFontSize = 10.sp, stepSize = 0.5.sp),
                    modifier = Modifier.pullUp(4f),
                )
            }
        }
    }
}

// MARK: - 01 · ป้ายชื่อ

/**
 * ชื่อตัวใหญ่ · รูปโปรไฟล์ · @handle + ประเภทบัญชี · พื้นที่รับงาน · ป้าย VERIFIED
 * กระจก: ทุกอย่างอยู่ในกล่องขาวใบเดียว · กระดาษ: ชื่อลอยบนการ์ด รูปแปะเทป ข้อมูลอยู่บนกระดาษโน้ตพับมุม
 */
@Composable
fun PopHero(theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val skin = LocalPopSkin.current ?: Pop.skin(theme)
    if (skin == PopSkin.glass) {
        PopSheet(theme, pad = 10f, modifier = modifier) { PopHeroInner(theme, size, skin) }
    } else {
        Box(modifier.fillMaxSize().padding(6.dp)) { PopHeroInner(theme, size, skin) }
    }
}

@Composable
private fun PopHeroInner(theme: CardTheme, size: Size, skin: PopSkin) {
    val paper = skin == PopSkin.paper
    // ชื่อกินเกือบเต็มความกว้างกล่องเหมือนต้นฉบับ — ชื่อยาวกว่านั้นย่อเองด้วย autoSize
    val nameSize = min(60f, size.width * 0.215f)
    Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        EditableText(
            field = ProfileField.personName,
            style = TextSlotStyle(size = nameSize, weight = SHFont.black, color = Pop.ink, tracking = -0.5f),
            modifier = Modifier.fillMaxWidth(),
            autoSizeMin = 0.5f,
        )

        Row(
            Modifier.fillMaxWidth().weight(1f),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.Top,
        ) {
            // รูปกิน 42% ของแถว — ที่เหลือเป็นคอลัมน์ข้อมูล (แบ่งครึ่งแล้วบรรทัด @handle ไม่พอ)
            PopPortrait(theme, skin, Modifier.width(((size.width - (if (paper) 12f else 28f) - 10f) * 0.42f).dp).fillMaxHeight())

            val noteShape = RoundedCornerShape(3.dp)
            Box(
                Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .then(
                        // กระดาษโน้ตพับมุม — ข้อมูลไม่ได้ลอยบนการ์ด มันเขียนอยู่บนกระดาษอีกแผ่น
                        if (paper) {
                            Modifier
                                .softShadow(Color.Black.opacity(0.2), 5f, y = 4f, shape = noteShape)
                                .background(Pop.paper, noteShape)
                        } else Modifier,
                    ),
            ) {
                Column(Modifier.fillMaxSize().padding(8.dp).padding(vertical = 2.dp)) {
                    // สัดส่วนตามไฟล์: บรรทัด @handle ใหญ่ ไอคอน IG เท่าตัวหนังสือ · ขีดคั่นบาง · คนกับ "บุคคล"
                    Row(
                        Modifier.fillMaxWidth().padding(top = 10.dp),
                        horizontalArrangement = Arrangement.spacedBy(5.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        BrandIcon(SHIcon.instagram, size = 15f)
                        EditableText(
                            field = ProfileField.handle,
                            style = TextSlotStyle(size = 11.5f, weight = SHFont.medium, color = Pop.ink),
                            text = "@" + Profile.me.handle,
                            modifier = Modifier.weight(1f, fill = false),
                            autoSizeMin = 0.55f,
                        )
                        Box(Modifier.size(0.8.dp, 15.dp).background(Pop.ink.opacity(0.5)))
                        PopGlyph("person.fill", size = 11f, tint = Pop.ink)
                        Text("บุคคล", style = sh(11.5f, SHFont.medium), color = Pop.ink, maxLines = 1, softWrap = false)
                    }

                    Spacer(Modifier.height(6.dp))
                    Spacer(Modifier.weight(1f))

                    Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
                        Row(Modifier.fillMaxWidth()) {
                            Text(
                                "พื้นที่รับงาน : ", style = sh(11f, SHFont.bold), color = Pop.ink,
                                maxLines = 1, softWrap = false, modifier = Modifier.alignByBaseline(),
                            )
                            EditableText(
                                field = ProfileField.workArea,
                                style = TextSlotStyle(size = 11f, weight = SHFont.regular, color = Pop.ink),
                                modifier = Modifier.alignByBaseline().weight(1f, fill = false),
                                autoSizeMin = 0.7f,
                            )
                        }
                        Box(Modifier.fillMaxWidth().height(1.dp).background(Pop.ink.opacity(0.85)))
                    }

                    Spacer(Modifier.height(6.dp))
                    Spacer(Modifier.weight(1f))

                    if (Profile.me.creator.verified) PopVerified()
                }
                if (paper) PopFold(theme, modifier = Modifier.align(Alignment.BottomEnd))
            }
        }
    }
}

/** รูปโปรไฟล์ — กระจก: มุมมน ขอบชมพูอ่อน · กระดาษ: รูปอัดขอบขาว แปะเทปเฉียงมุมบน */
@Composable
private fun PopPortrait(theme: CardTheme, skin: PopSkin, modifier: Modifier) {
    val paper = skin == PopSkin.paper
    val shape = RoundedCornerShape((if (paper) 2f else 14f).dp)
    Box(modifier.photoSlot(1)) {
        Box(
            Modifier
                .matchParentSize()
                .graphicsLayer { rotationZ = if (paper) -2f else 0f }
                .softShadow(if (paper) Color.Black.opacity(0.28) else Color.Transparent, 6f, y = 4f, shape = shape)
                .clip(shape)
                .border((if (paper) 5f else 2.5f).dp, if (paper) Color.White else Pop.pinkSoft(theme), shape),
        ) {
            WidgetPhoto(1, Modifier.fillMaxSize())
        }
        if (paper) {
            PopTape(
                theme,
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .offset((-18).dp, (-4).dp)
                    .graphicsLayer { rotationZ = -8f },
            )
        }
    }
}

// MARK: - 02 · หน้าต่างวิดีโอ

/**
 * เพลเยอร์แนวนอน — แถบชื่อ "Video" + จุดสามจุด · คลิป · ปุ่ม ⏮ ▶ ⏭ 🔊 (ตกแต่ง ไม่กดจริง)
 * กระจก: หน้าต่างขาว · กระดาษ: หน้าต่างดำเหมือนเครื่องเล่นพกพา
 */
@Composable
fun PopVideo(theme: CardTheme, modifier: Modifier = Modifier) {
    val skin = LocalPopSkin.current ?: Pop.skin(theme)
    val surface = LocalWidgetSurface.current
    val border = LocalWidgetBorder.current
    val work: VerifiedWork? = Profile.me.creator.track.works.firstOrNull()
    val dark = skin == PopSkin.paper
    val fg = if (dark) Color.White else Pop.ink
    val r = if (dark) 12f else 18f
    val bg = RoundedCornerShape(r.dp)
    val frame = RoundedCornerShape((if (dark) 9f else 12f).dp)

    Box(modifier.fillMaxSize().linkSlot(work?.postURL).padding(4.dp)) {
        Column(
            Modifier
                .fillMaxSize()
                .softShadow(
                    if (dark) Color.Black.opacity(0.28) else Pop.sheetShadow(surface, skin, theme),
                    radius = if (dark) 6f else 9f, y = 5f, shape = bg,
                )
                .background(if (dark) Pop.ink else Pop.sheetFill(surface, skin, theme), bg)
                .then(
                    if (!dark && surface == WidgetSurface.glass) {
                        Modifier.border(
                            1.2.dp,
                            Brush.verticalGradient(listOf(Color.White.opacity(0.95), Color.White.opacity(0.25))),
                            bg,
                        )
                    } else Modifier,
                )
                .then(if (border) Modifier.border(1.6.dp, Pop.pink(theme), bg) else Modifier),
        ) {
            Row(
                Modifier.fillMaxWidth().padding(start = 13.dp, end = 13.dp, top = 11.dp, bottom = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Video", style = sh(18f, SHFont.bold), color = fg, maxLines = 1, softWrap = false)
                Spacer(Modifier.weight(1f))
                PopGlyph("ellipsis", size = 19f, tint = fg, weight = PopGlyphWeight.bold)
            }

            Box(Modifier.weight(1f).fillMaxWidth().photoSlot(2).padding(horizontal = 10.dp)) {
                Box(Modifier.fillMaxSize().clip(frame)) { WidgetPhoto(2, Modifier.fillMaxSize()) }
                Box(
                    Modifier
                        .fillMaxSize()
                        .border(2.5.dp, if (dark) Color.White.opacity(0.9) else Pop.pink(theme).opacity(0.75), frame),
                )
            }

            Row(
                Modifier.fillMaxWidth().padding(start = 6.dp, end = 6.dp, top = 9.dp, bottom = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                listOf("backward.end.fill", "play.fill", "forward.end.fill", "speaker.wave.2.fill").forEach { n ->
                    Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                        PopGlyph(n, size = 14f, tint = fg)
                    }
                }
            }
        }
        // เส้นชมพูที่ขอบบนกลางหน้าต่าง — ตามไฟล์
        if (!dark) {
            Box(
                Modifier
                    .align(Alignment.TopCenter)
                    .padding(top = 4.dp)
                    .size(92.dp, 3.5.dp)
                    .background(Pop.pink(theme), CircleShape),
            )
        }
    }
}

// MARK: - 03 · ผู้ติดตามสามช่อง

/**
 * ยอดฟอล IG · TikTok · YouTube ตัวเลขยักษ์
 * กระจก: กล่องมนสามใบ + แถบไอคอน IG ตกแต่งใต้กล่อง · กระดาษ: วงกลมสามวงขอบชมพู
 */
@Composable
fun PopStats(theme: CardTheme, modifier: Modifier = Modifier) {
    val skin = LocalPopSkin.current ?: Pop.skin(theme)
    val glass = skin == PopSkin.glass
    val all = Profile.me.creator.socials
    val socials = all.take(3)
    PopSheet(theme, label = "ผู้ติดตาม", icon = "flag.fill", pad = if (glass) 7f else 8f, modifier = modifier) {
        Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Box(Modifier.fillMaxWidth().weight(1f)) {
                Row(
                    Modifier.fillMaxSize(),
                    horizontalArrangement = Arrangement.spacedBy((if (glass) 9f else 12f).dp),
                ) {
                    socials.forEach { s ->
                        key(s.id) {
                            PopStatTile(theme, skin, s, Modifier.weight(1f).fillMaxHeight().linkSlot(s.profileURL))
                        }
                    }
                }
                // ป้ายที่มาของยอด — แผ่นสติกเกอร์ใช้ถ่านคงที่บนกล่องขาว จึงใช้ป้ายฉบับพื้นมืดของตัวเอง
                ProvenanceTag(
                    kind = all.provenance,
                    onPhoto = true,
                    modifier = Modifier.align(Alignment.TopEnd).offset(2.dp, (-13).dp),
                )
            }

            if (glass) {
                // แถบไอคอน IG — ของตกแต่งที่บอกว่า "นี่คือหน้าจอโซเชียล" ไม่มีข้อมูล
                Row(
                    Modifier
                        .fillMaxWidth()
                        .background(Pop.paper.opacity(0.92), RoundedCornerShape(12.dp))
                        .padding(vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    listOf("house", "magnifyingglass", "camera", "person", "heart", "paperplane", "bookmark").forEach { n ->
                        Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                            PopGlyph(n, size = 19f, tint = Pop.ink, weight = PopGlyphWeight.light)
                        }
                    }
                }
            }
        }
    }
}

/** "184K" → ตัวเลขใหญ่ + หน่วยเล็กลงตามไฟล์ (หน่วยเป็น em จึงย่อพร้อมกันทั้งก้อน) */
private fun bigNumber(n: Int): AnnotatedString {
    val s = Fmt.compact(n)
    val last = s.lastOrNull()
    return buildAnnotatedString {
        if (last != null && last.isLetter()) {
            append(s.dropLast(1))
            withStyle(SpanStyle(fontSize = 0.68.em)) { append(last.toString()) }
        } else {
            append(s)
        }
    }
}

@Composable
private fun PopStatTile(theme: CardTheme, skin: PopSkin, s: SocialProfile, modifier: Modifier) {
    val glass = skin == PopSkin.glass
    val tileShape = RoundedCornerShape(11.dp)
    val soft = Pop.pinkSoft(theme)
    val circleFill = rgb(0.96, 0.95, 0.96)
    Box(
        modifier.then(
            if (glass) {
                Modifier
                    .background(Pop.paper, tileShape)
                    .border(2.dp, Pop.pink(theme).opacity(0.6), tileShape)
            } else {
                Modifier.drawBehind {
                    val rr = min(size.width, size.height) / 2
                    drawCircle(circleFill, rr, center)
                    val sw = 3.dp.toPx()
                    drawCircle(soft, rr - sw / 2, center, style = Stroke(sw))
                }
            },
        ),
        contentAlignment = Alignment.Center,
    ) {
        Column(Modifier.padding(horizontal = 6.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Row(horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
                BrandIcon(s.type.icon, size = 15f)
                Text(
                    s.type.name, style = sh(11.5f, SHFont.medium), color = Pop.ink, maxLines = 1, softWrap = false,
                    autoSize = TextAutoSize.StepBased(minFontSize = (11.5f * 0.7f).sp, maxFontSize = 11.5.sp, stepSize = 0.5.sp),
                )
            }
            val size = if (glass) 42f else 32f
            Text(
                bigNumber(s.followerCount),
                style = sh(size, SHFont.black).copy(letterSpacing = (-1.5f / size).em),
                color = Pop.ink,
                maxLines = 1,
                softWrap = false,
                autoSize = TextAutoSize.StepBased(minFontSize = (size * 0.5f).sp, maxFontSize = size.sp, stepSize = 0.5.sp),
                modifier = Modifier.pullUp(2f),
            )
        }
    }
}

// MARK: - 04 · ผลงานสามใบ

/** รูป 3 ใบ + ป้ายหมวด · กระจก: ชิปชมพูทับขอบล่างของรูป · กระดาษ: รูปอัดขอบขาว คำอยู่ที่คางล่าง */
@Composable
fun PopWork(theme: CardTheme, modifier: Modifier = Modifier) {
    val skin = LocalPopSkin.current ?: Pop.skin(theme)
    // ใต้รูปเป็น engagement ของโพสต์นั้น (ไลก์ · คอมเมนต์ · แชร์) แทนชื่อหมวด — ผูกกับผลงานจริงชิ้นที่ i
    val works = Profile.me.creator.track.works
    PopSheet(theme, label = "ผลงานที่ผ่านมา", icon = "rosette", pad = 10f, fold = true, modifier = modifier) {
        Row(
            Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.spacedBy((if (skin == PopSkin.glass) 9f else 8f).dp),
        ) {
            for (i in 0 until 3) {
                PopWorkCard(theme, skin, i, works, Modifier.weight(1f).fillMaxHeight())
            }
        }
    }
}

private val popWorkSlots = listOf(4, 5, 6)
private val popWorkTilts = listOf(-1.5f, 1f, -0.8f)

@Composable
private fun PopWorkCard(theme: CardTheme, skin: PopSkin, i: Int, works: List<VerifiedWork>, modifier: Modifier) {
    val slot = popWorkSlots[i]
    val url = works.getOrNull(i)?.postURL
    Box(modifier.photoSlot(slot).linkSlot(url)) {
        if (skin == PopSkin.glass) {
            val shape = RoundedCornerShape(10.dp)
            Box(Modifier.fillMaxSize().clip(shape)) { WidgetPhoto(slot, Modifier.fillMaxSize()) }
            Box(Modifier.fillMaxSize().border(2.5.dp, Pop.pink(theme).opacity(0.7), shape))
            Box(
                Modifier
                    .align(Alignment.BottomCenter)
                    .padding(start = 4.dp, end = 4.dp, bottom = 4.dp)
                    .fillMaxWidth()
                    .background(Pop.pink(theme).opacity(0.95), CircleShape)
                    .padding(horizontal = 5.dp, vertical = 4.dp),
            ) {
                PopEngage(works.getOrNull(i), tint = Color.White, size = 9f)
            }
        } else {
            val shape = RoundedCornerShape(1.5.dp)
            Column(
                Modifier
                    .fillMaxSize()
                    .graphicsLayer { rotationZ = popWorkTilts[i] }
                    .softShadow(Color.Black.opacity(0.22), 4f, y = 3f, shape = RectangleShape)
                    .background(Pop.paper)
                    .padding(4.dp),
            ) {
                Box(Modifier.weight(1f).fillMaxWidth().clip(shape)) { WidgetPhoto(slot, Modifier.fillMaxSize()) }
                PopEngage(
                    works.getOrNull(i), tint = Pop.ink, size = 9f,
                    modifier = Modifier.padding(vertical = 6.dp, horizontal = 2.dp),
                )
            }
        }
    }
}

/** ♥ ไลก์ · 💬 คอมเมนต์ · ↗ แชร์ ของโพสต์ชิ้นที่ i — ไอคอนแทนคำ เพราะกว้างแค่ ~100pt ต่อใบ */
@Composable
private fun PopEngage(w: VerifiedWork?, tint: Color, size: Float, modifier: Modifier = Modifier) {
    val auto = TextAutoSize.StepBased(minFontSize = (size * 0.6f).sp, maxFontSize = size.sp, stepSize = 0.25.sp)
    Box(modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        if (w != null) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                listOf(
                    "heart.fill" to w.likes,
                    "bubble.left.fill" to w.comments,
                    "arrowshape.turn.up.right.fill" to w.shares,
                ).forEach { (icon, n) ->
                    Row(
                        Modifier.weight(1f),
                        horizontalArrangement = Arrangement.spacedBy(2.dp, Alignment.CenterHorizontally),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        PopGlyph(icon, size = 7.5f, tint = tint)
                        Text(
                            Fmt.compact(n), style = sh(size, SHFont.bold), color = tint, maxLines = 1, softWrap = false,
                            autoSize = auto, modifier = Modifier.dataValue(),
                        )
                    }
                }
            }
        } else {
            // ยังไม่มีโพสต์จากระบบ — บอกว่ารอ ไม่โชว์ ♥0 💬0 ที่อ่านเป็น "ไม่มีใครสนใจ"
            Text("รอข้อมูลโพสต์", style = sh(size, SHFont.bold), color = tint, maxLines = 1, softWrap = false, autoSize = auto)
        }
    }
}

// MARK: - 05 · ใบเรตราคา

/**
 * ราคาต่อคลิปต่อแพลตฟอร์ม — โลโก้ซ้าย ราคาชมพูขวา คั่นเส้นประ
 * กระจก: กระดาษพับมุม · กระดาษ: หน้าสมุดเจาะรู ราคาไฮไลต์บล็อกชมพู
 * ใบเรตราคาถูกแปะเอียง — กระจก (`_2.svg`) ทวนเข็ม 7.18° · กระดาษ (`_1.svg`) ตามเข็ม 6.1°
 */
@Composable
fun PopRate(theme: CardTheme, modifier: Modifier = Modifier) {
    val skin = LocalPopSkin.current ?: Pop.skin(theme)
    val paper = skin == PopSkin.paper
    val rates = Profile.me.creator.rates.take(2)
    PopTilt(degrees = if (skin == PopSkin.glass) -7.18 else 6.1, modifier = modifier) {
        Box(Modifier.fillMaxSize()) {
            PopSheet(theme, label = "เรตราคา", icon = "tag.fill", pad = 8f, fold = false) {
                Column(Modifier.fillMaxSize().padding(start = (if (paper) 10f else 0f).dp)) {
                    rates.forEachIndexed { i, r ->
                        key(r.id) {
                            Box(Modifier.fillMaxWidth().weight(1f)) {
                                PopRateRow(theme, skin, r, i, Modifier.fillMaxSize())
                                if (i > 0) PopDashes(Modifier.align(Alignment.TopCenter))
                            }
                        }
                    }
                }
            }
            if (paper) {
                // รูเจาะสมุด — เรียงตามขอบซ้ายของแผ่น
                val hole = rgb(0.90, 0.88, 0.90)
                Column(
                    Modifier
                        .align(Alignment.CenterStart)
                        .padding(start = 9.dp, top = (Pop.labelHeight / 2 + 8).dp),
                    verticalArrangement = Arrangement.spacedBy(9.dp),
                ) {
                    repeat(7) {
                        Box(
                            Modifier
                                .size(7.dp)
                                .background(hole, CircleShape)
                                .border(0.5.dp, Color.Black.opacity(0.12), CircleShape),
                        )
                    }
                }
            }
            if (skin == PopSkin.glass) {
                PopFold(theme, size = 22f, modifier = Modifier.align(Alignment.BottomEnd).padding(4.dp))
            }
        }
    }
}

/** เส้นประใต้แถว — แถบ 3pt เว้น 3pt สูงสุด 30 ขีดจากซ้าย (= มาสก์แถบทึบของ Swift) */
@Composable
private fun PopDashes(modifier: Modifier = Modifier) {
    val c = Pop.ink.opacity(0.5)
    Canvas(modifier.fillMaxWidth().height(0.8.dp)) {
        val dash = 3.dp.toPx()
        val step = 6.dp.toPx()
        for (k in 0 until 30) {
            val x = k * step
            if (x >= size.width) break
            drawRect(c, topLeft = Offset(x, 0f), size = Size(min(dash, size.width - x), size.height))
        }
    }
}

@Composable
private fun PopRateRow(theme: CardTheme, skin: PopSkin, r: RateItem, i: Int, modifier: Modifier) {
    val paper = skin == PopSkin.paper
    val price = Profile.me.ratePrice(i)
    Row(
        modifier.padding(vertical = 3.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(
            Modifier.width(50.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(1.dp),
        ) {
            BrandIcon(r.platform.icon, size = 34f)
            EditableText(
                field = ProfileField.rateLabels, index = i,
                style = TextSlotStyle(size = 8f, weight = SHFont.medium, color = Pop.ink),
                autoSizeMin = 0.7f,
            )
        }

        Spacer(Modifier.weight(1f))

        Column(horizontalAlignment = Alignment.End) {
            Row(
                Modifier
                    .then(if (paper) Modifier.background(Pop.pinkSoft(theme).opacity(0.9), RoundedCornerShape(2.dp)) else Modifier)
                    .padding(horizontal = (if (paper) 4f else 0f).dp),
            ) {
                Text(
                    "฿",
                    style = sh(21f, SHFont.black).copy(letterSpacing = (-0.8).sp),
                    color = if (skin == PopSkin.glass) Pop.pink(theme) else Pop.ink,
                    maxLines = 1, softWrap = false,
                    modifier = Modifier.alignByBaseline(),
                )
                EditableText(
                    field = ProfileField.ratePrices, index = i,
                    style = TextSlotStyle(size = 21f, weight = SHFont.black, color = Pop.ink, tracking = -0.8f),
                    text = Fmt.baht(price),
                    modifier = Modifier.alignByBaseline(),
                    autoSizeMin = 0.55f,
                )
            }
            Text(
                "/${r.unit}", style = sh(9f, SHFont.semibold), color = Pop.ink, maxLines = 1, softWrap = false,
                modifier = Modifier.pullUp(4f),
            )
        }
    }
}

// MARK: - 06 · สายงานแบบลิสต์

/** สายงานเรียงลง ไอคอนนำหน้า คั่นเส้นบาง — อ่านเป็นเมนู ไม่ใช่ชิป */
@Composable
fun PopNiche(theme: CardTheme, modifier: Modifier = Modifier) {
    val items = Profile.me.categories.take(5)
    PopSheet(
        theme, label = "สายงาน", icon = "list.bullet.clipboard.fill", pad = 8f, fold = true, wide = true,
        modifier = modifier,
    ) {
        key(items) {
            Column(Modifier.fillMaxSize()) {
                items.forEachIndexed { i, t ->
                    Box(Modifier.fillMaxWidth().weight(1f)) {
                        Row(
                            Modifier.fillMaxSize().padding(horizontal = 4.dp),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Box(Modifier.width(26.dp), contentAlignment = Alignment.Center) {
                                PopGlyph(Pop.nicheIcon(t), size = 17f, tint = Pop.ink)
                            }
                            EditableText(
                                field = ProfileField.categories, index = i,
                                style = TextSlotStyle(size = 14f, weight = SHFont.medium, color = Pop.ink),
                                text = t,
                                autoSizeMin = 0.7f,
                            )
                        }
                        if (i < items.size - 1) {
                            Box(Modifier.align(Alignment.BottomCenter).fillMaxWidth().height(0.8.dp).background(Pop.rule))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 07 · สัดส่วน

private val popBodyRows: List<Pair<String, ProfileField>> = listOf(
    "น้ำหนัก" to ProfileField.weight, "ส่วนสูง" to ProfileField.height, "รอบอก" to ProfileField.bust,
    "เอว" to ProfileField.waist, "สะโพก" to ProfileField.hips, "ขนาดรองเท้า" to ProfileField.shoe,
)

/** น้ำหนัก · ส่วนสูง · รอบอก · เอว · สะโพก · ขนาดรองเท้า — สองคอลัมน์ คั่นด้วย ":" */
@Composable
fun PopBody(theme: CardTheme, modifier: Modifier = Modifier) {
    val measurer = TextFit.rememberMeasurer()
    // คอลัมน์ป้ายกว้างเท่าป้ายที่ยาวที่สุด (= `Grid` ของ SwiftUI)
    val labelW = remember(measurer) {
        ceil(popBodyRows.maxOf { TextFit.natural(measurer, it.first, CardFont.noto, SHFont.medium, 12.5f).width })
    }
    PopSheet(theme, label = "สัดส่วน", icon = "star.fill", pad = 9f, fold = true, wide = true, modifier = modifier) {
        Column(Modifier.fillMaxSize().padding(horizontal = 3.dp)) {
            popBodyRows.forEach { (label, field) ->
                Row(
                    Modifier.fillMaxWidth().weight(1f),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        label, style = sh(12.5f, SHFont.medium), color = Pop.ink, maxLines = 1, softWrap = false,
                        autoSize = TextAutoSize.StepBased(minFontSize = (12.5f * 0.7f).sp, maxFontSize = 12.5.sp, stepSize = 0.5.sp),
                        modifier = Modifier.width(labelW.dp),
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                        Text(
                            ":", style = sh(12.5f, SHFont.medium), color = Pop.ink, maxLines = 1,
                            modifier = Modifier.alignByBaseline(),
                        )
                        EditableText(
                            field = field,
                            style = TextSlotStyle(size = 12.5f, weight = SHFont.medium, color = Pop.ink),
                            modifier = Modifier.alignByBaseline(),
                            autoSizeMin = 0.7f,
                        )
                    }
                }
            }
        }
    }
}

// MARK: - 08 · ช่องทางติดต่อสามแถว

/** โทร · อีเมล · LINE — แต่ละช่องเป็นเม็ดยาขาวขอบชมพู (กระจก) หรือกล่องขอบเทา (กระดาษ) */
@Composable
fun PopContact(theme: CardTheme, modifier: Modifier = Modifier) {
    val skin = LocalPopSkin.current ?: Pop.skin(theme)
    val glass = skin == PopSkin.glass
    val shape = if (glass) CircleShape else RoundedCornerShape(4.dp)
    PopSheet(theme, label = "ช่องทางติดต่อ", icon = "person.fill", pad = 8f, wide = true, modifier = modifier) {
        Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            ContactLine.all.forEach { l ->
                Row(
                    Modifier
                        .fillMaxWidth()
                        .weight(1f)
                        .linkSlot(l.field.contactURL)
                        .background(Pop.paper, shape)
                        .border(
                            (if (glass) 2f else 0.8f).dp,
                            if (glass) Pop.pink(theme).opacity(0.6) else Pop.rule,
                            shape,
                        )
                        .padding(start = 5.dp, end = 8.dp, top = 4.dp, bottom = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    PopContactBadge(l)
                    EditableText(
                        field = l.field,
                        style = TextSlotStyle(size = 12f, weight = SHFont.medium, color = Pop.ink),
                        autoSizeMin = 0.6f,
                    )
                }
            }
        }
    }
}

/** ไอคอนช่องทาง — โทร/อีเมลวงดำ · LINE วงเขียวของแบรนด์ */
@Composable
private fun PopContactBadge(l: ContactLine) {
    val isLine = l.field == ProfileField.lineId
    Box(
        Modifier.size(23.dp).background(if (isLine) rgb(0.02, 0.78, 0.33) else Pop.ink, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        if (isLine) {
            Text("LINE", style = systemFont(6.5f, SHFont.black), color = Color.White, maxLines = 1, softWrap = false)
        } else {
            PopGlyph(l.icon, size = 10.5f, tint = Color.White)
        }
    }
}

// MARK: - เครื่องมือวาดของสำรับนี้ (ส่วนตัว)

/** VStack ที่ระยะติดลบ — ดึงชิ้นขึ้น `dy` pt และหักความสูงเท่ากันออกจากผัง */
private fun Modifier.pullUp(dy: Float): Modifier = layout { m, c ->
    val p = m.measure(c)
    val d = dy.dp.roundToPx()
    layout(p.width, max(0, p.height - d)) { p.place(0, -d) }
}

/**
 * เงาแบบ `.shadow(color:radius:x:y:)` ของ SwiftUI — เบลอจริงด้วย `setShadowLayer`
 * เจาะรูปทรงของตัวเองออกก่อน เงาจึงไม่ทะลุขึ้นมาใต้แผ่นกระจกที่โปร่ง
 */
private fun Modifier.softShadow(color: Color, radius: Float, x: Float = 0f, y: Float = 0f, shape: Shape): Modifier =
    if (color.alpha <= 0f) this else drawBehind {
        val path = Path().apply { addOutline(shape.createOutline(size, layoutDirection, this@drawBehind)) }
        clipPath(path, ClipOp.Difference) {
            drawNativeShadow(path, color, radius, x, y)
        }
    }

/** วาดรูปทรงพร้อมเงาเบลอ (ตัวรูปทรงถูกคลุมหรือเจาะทิ้งโดยผู้เรียก) */
private fun DrawScope.drawNativeShadow(path: Path, color: Color, radius: Float, x: Float, y: Float) {
    drawIntoCanvas { canvas ->
        val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color.toArgb()
            setShadowLayer(max(0.1f, radius.dp.toPx()), x.dp.toPx(), y.dp.toPx(), color.toArgb())
        }
        canvas.nativeCanvas.drawPath(path.asAndroidPath(), paint)
    }
}

/** น้ำหนักเส้นของไอคอน — `.light` · `.regular` · `.bold` (heavy/black ใช้ bold) */
private enum class PopGlyphWeight { light, regular, bold }

/**
 * `Image(systemName:)` ของสำรับนี้ — ชื่อ SF ที่ตารางกลางไม่มีคู่ (หรือคู่ผิดความหมาย) วาดเองให้ตรงรูป
 * ขนาดคือขนาดฟอนต์ของ SF — กล่องไอคอนใหญ่กว่า 15% ให้ตัวรูปสูงเท่าสัญลักษณ์ของ iOS
 */
@Composable
private fun PopGlyph(name: String, size: Float, tint: Color, weight: PopGlyphWeight = PopGlyphWeight.bold, modifier: Modifier = Modifier) {
    val box = size * 1.15f
    val line = if (weight == PopGlyphWeight.bold) PhWeight.bold else PhWeight.regular
    val ph: Pair<Ph, PhWeight>? = when (name) {
        "house" -> Ph.house to line
        "house.fill" -> Ph.house to PhWeight.fill
        "camera" -> Ph.camera to line
        "person" -> Ph.user to line
        "person.fill" -> Ph.user to PhWeight.fill
        "paperplane" -> Ph.paperPlaneTilt to line
        "airplane" -> Ph.paperPlaneTilt to PhWeight.fill
        "star.fill" -> Ph.star to PhWeight.fill
        "rosette" -> Ph.sealCheck to PhWeight.fill
        "list.bullet.clipboard.fill" -> Ph.clipboardText to PhWeight.fill
        "checkmark" -> Ph.check to PhWeight.bold
        "bubble.left.fill", "message.fill" -> Ph.chatCircle to PhWeight.fill
        "bubble.left.and.bubble.right.fill" -> Ph.chatCircleText to PhWeight.fill
        "arrowshape.turn.up.right.fill" -> Ph.shareFat to PhWeight.fill
        "figure.and.child.holdinghands" -> Ph.usersThree to PhWeight.fill
        "gamecontroller.fill" -> Ph.headset to PhWeight.fill
        else -> null
    }
    when {
        ph != null -> PIcon(ph.first, size = box, weight = ph.second, tint = tint, modifier = modifier)
        name == "heart.fill" -> SymbolIcon(SHIcon.heart, size = box, tint = tint, modifier = modifier)
        name == "phone.fill" -> SymbolIcon(SHIcon.phoneCall, size = box, tint = tint, modifier = modifier)
        name in drawnGlyphs -> {
            val sw = when (weight) {
                PopGlyphWeight.light -> 0.055f
                PopGlyphWeight.regular -> 0.075f
                PopGlyphWeight.bold -> 0.1f
            }
            Canvas(modifier.size(box.dp).graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen)) {
                drawGlyph(name, tint, sw)
            }
        }
        else -> SFSymbol(name, size = box, tint = tint, modifier = modifier)
    }
}

private val drawnGlyphs = setOf(
    "heart", "bookmark", "magnifyingglass", "ellipsis", "play.fill", "backward.end.fill", "forward.end.fill",
    "speaker.wave.2.fill", "flag.fill", "tag.fill", "dumbbell.fill", "cylinder.split.1x2.fill", "fork.knife",
    "tshirt.fill", "envelope.fill",
)

/** รูปไอคอนในกรอบหน่วย 0…1 — เส้นกว้าง `w` (สัดส่วนของกรอบ) */
private fun DrawScope.drawGlyph(name: String, c: Color, w: Float) {
    val g = size.minDimension
    val ox = (size.width - g) / 2f
    val oy = (size.height - g) / 2f
    fun p(x: Float, y: Float) = Offset(ox + x * g, oy + y * g)
    fun poly(vararg xy: Float): Path = Path().apply {
        moveTo(ox + xy[0] * g, oy + xy[1] * g)
        var k = 2
        while (k + 1 < xy.size) { lineTo(ox + xy[k] * g, oy + xy[k + 1] * g); k += 2 }
        close()
    }
    fun rr(x: Float, y: Float, rw: Float, rh: Float, r: Float) =
        drawRoundRect(c, topLeft = p(x, y), size = Size(rw * g, rh * g), cornerRadius = CornerRadius(r * g, r * g))
    val sw = w * g
    val stroke = Stroke(width = sw, cap = StrokeCap.Round, join = StrokeJoin.Round)
    when (name) {
        "heart" -> {
            val a = p(0.5f, 0.84f)
            val path = Path().apply {
                moveTo(a.x, a.y)
                p(0.2f, 0.64f).let { c1 -> p(0.06f, 0.46f).let { c2 -> p(0.1f, 0.3f).let { e -> cubicTo(c1.x, c1.y, c2.x, c2.y, e.x, e.y) } } }
                p(0.14f, 0.14f).let { c1 -> p(0.38f, 0.1f).let { c2 -> p(0.5f, 0.27f).let { e -> cubicTo(c1.x, c1.y, c2.x, c2.y, e.x, e.y) } } }
                p(0.62f, 0.1f).let { c1 -> p(0.86f, 0.14f).let { c2 -> p(0.9f, 0.3f).let { e -> cubicTo(c1.x, c1.y, c2.x, c2.y, e.x, e.y) } } }
                p(0.94f, 0.46f).let { c1 -> p(0.8f, 0.64f).let { c2 -> cubicTo(c1.x, c1.y, c2.x, c2.y, a.x, a.y) } }
                close()
            }
            drawPath(path, c, style = stroke)
        }
        "bookmark" -> drawPath(poly(0.26f, 0.12f, 0.74f, 0.12f, 0.74f, 0.88f, 0.5f, 0.7f, 0.26f, 0.88f), c, style = stroke)
        "magnifyingglass" -> {
            drawCircle(c, radius = 0.27f * g, center = p(0.42f, 0.42f), style = stroke)
            drawLine(c, p(0.62f, 0.62f), p(0.87f, 0.87f), strokeWidth = sw * 1.3f, cap = StrokeCap.Round)
        }
        "ellipsis" -> listOf(0.18f, 0.5f, 0.82f).forEach { x -> drawCircle(c, radius = 0.1f * g, center = p(x, 0.5f)) }
        "play.fill" -> drawPath(poly(0.26f, 0.14f, 0.86f, 0.5f, 0.26f, 0.86f), c)
        "backward.end.fill" -> {
            rr(0.14f, 0.18f, 0.11f, 0.64f, 0.03f)
            drawPath(poly(0.86f, 0.18f, 0.86f, 0.82f, 0.3f, 0.5f), c)
        }
        "forward.end.fill" -> {
            drawPath(poly(0.14f, 0.18f, 0.14f, 0.82f, 0.7f, 0.5f), c)
            rr(0.75f, 0.18f, 0.11f, 0.64f, 0.03f)
        }
        "speaker.wave.2.fill" -> {
            drawPath(poly(0.06f, 0.38f, 0.22f, 0.38f, 0.44f, 0.18f, 0.44f, 0.82f, 0.22f, 0.62f, 0.06f, 0.62f), c)
            val wave = Stroke(width = 0.075f * g, cap = StrokeCap.Round)
            for (r in listOf(0.16f, 0.3f)) {
                drawArc(c, startAngle = -45f, sweepAngle = 90f, useCenter = false,
                    topLeft = p(0.44f - r, 0.5f - r), size = Size(2 * r * g, 2 * r * g), style = wave)
            }
        }
        "flag.fill" -> {
            drawLine(c, p(0.2f, 0.08f), p(0.2f, 0.92f), strokeWidth = 0.09f * g, cap = StrokeCap.Round)
            val s0 = p(0.2f, 0.12f)
            val path = Path().apply {
                moveTo(s0.x, s0.y)
                p(0.38f, 0.04f).let { c1 -> p(0.56f, 0.22f).let { c2 -> p(0.84f, 0.12f).let { e -> cubicTo(c1.x, c1.y, c2.x, c2.y, e.x, e.y) } } }
                p(0.84f, 0.56f).let { lineTo(it.x, it.y) }
                p(0.56f, 0.66f).let { c1 -> p(0.38f, 0.48f).let { c2 -> p(0.2f, 0.56f).let { e -> cubicTo(c1.x, c1.y, c2.x, c2.y, e.x, e.y) } } }
                close()
            }
            drawPath(path, c)
        }
        "tag.fill" -> {
            val path = poly(0.06f, 0.5f, 0.36f, 0.18f, 0.94f, 0.18f, 0.94f, 0.82f, 0.36f, 0.82f).apply {
                fillType = PathFillType.EvenOdd
                addOval(Rect(p(0.32f, 0.5f), 0.07f * g))
            }
            drawPath(path, c)
        }
        "dumbbell.fill" -> {
            drawRect(c, topLeft = p(0.2f, 0.45f), size = Size(0.6f * g, 0.1f * g))
            rr(0.12f, 0.26f, 0.12f, 0.48f, 0.03f)
            rr(0.76f, 0.26f, 0.12f, 0.48f, 0.03f)
            rr(0.04f, 0.36f, 0.08f, 0.28f, 0.03f)
            rr(0.88f, 0.36f, 0.08f, 0.28f, 0.03f)
        }
        "cylinder.split.1x2.fill" -> {
            rr(0.3f, 0.08f, 0.4f, 0.38f, 0.1f)
            rr(0.3f, 0.52f, 0.4f, 0.4f, 0.06f)
        }
        "fork.knife" -> {
            val tine = 0.06f * g
            listOf(0.2f, 0.29f, 0.38f).forEach { x -> drawLine(c, p(x, 0.1f), p(x, 0.34f), strokeWidth = tine, cap = StrokeCap.Round) }
            val b0 = p(0.2f, 0.34f); val bc = p(0.29f, 0.5f); val b1 = p(0.38f, 0.34f)
            drawPath(Path().apply { moveTo(b0.x, b0.y); quadraticTo(bc.x, bc.y, b1.x, b1.y) }, c,
                style = Stroke(width = tine, cap = StrokeCap.Round))
            drawLine(c, p(0.29f, 0.44f), p(0.29f, 0.9f), strokeWidth = 0.09f * g, cap = StrokeCap.Round)
            val k0 = p(0.64f, 0.08f)
            val blade = Path().apply {
                moveTo(k0.x, k0.y)
                p(0.82f, 0.16f).let { c1 -> p(0.84f, 0.42f).let { c2 -> p(0.74f, 0.52f).let { e -> cubicTo(c1.x, c1.y, c2.x, c2.y, e.x, e.y) } } }
                p(0.64f, 0.52f).let { lineTo(it.x, it.y) }
                close()
            }
            drawPath(blade, c)
            drawLine(c, p(0.69f, 0.5f), p(0.69f, 0.9f), strokeWidth = 0.1f * g, cap = StrokeCap.Round)
        }
        "tshirt.fill" -> drawPath(
            poly(0.34f, 0.12f, 0.5f, 0.2f, 0.66f, 0.12f, 0.94f, 0.3f, 0.84f, 0.48f, 0.72f, 0.42f,
                0.72f, 0.9f, 0.28f, 0.9f, 0.28f, 0.42f, 0.16f, 0.48f, 0.06f, 0.3f),
            c,
        )
        "envelope.fill" -> {
            rr(0.06f, 0.2f, 0.88f, 0.6f, 0.08f)
            val f0 = p(0.1f, 0.26f); val f1 = p(0.5f, 0.56f); val f2 = p(0.9f, 0.26f)
            drawPath(
                Path().apply { moveTo(f0.x, f0.y); lineTo(f1.x, f1.y); lineTo(f2.x, f2.y) }, Color.Black,
                style = Stroke(width = 0.07f * g, cap = StrokeCap.Round, join = StrokeJoin.Round), blendMode = BlendMode.Clear,
            )
        }
    }
}
