package co.salehere.starcard.ui.profile

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.StartOffset
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.autofill.ContentType
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.BlurredEdgeTreatment
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.contentType
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntRect
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Popup
import androidx.compose.ui.window.PopupPositionProvider
import androidx.compose.ui.window.PopupProperties
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.theme.systemFont
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.dockPress
import co.salehere.starcard.ui.pkRowPress
import co.salehere.starcard.ui.tap
import kotlinx.coroutines.delay
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.exp
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import androidx.compose.ui.graphics.Shadow as TextShadow

// MARK: - ชุดชิ้นส่วนของหน้า "ข้อมูลของฉัน" (= ProfileKit.swift)
//
// # ทำไมไม่ใช้ Material
// ฟอร์มระบบบังคับฟอนต์และระยะของมันเอง — ชิ้นส่วนข้างล่างวาดเองทั้งหมดบน NotoSansThai
// ให้หน้าตาเป็นเนื้อเดียวกับฟอร์มเว็บที่ทีมออกแบบไว้ และเล่นสนุกได้ (อีโมจิ · สติกเกอร์ · สปริง)
//
// # กติกาของช่องกรอก (จากผล audit ฟอร์มเว็บ)
// * ทุกช่องมีป้ายชื่อ + ดาวบังคับ + ข้อผิดพลาด **ใต้ช่องนั้น** ไม่ใช่ท้ายหน้า
// * คีย์บอร์ดตรงชนิด (เบอร์ = แป้นตัวเลข · อีเมล = แป้นอีเมล ไม่ขึ้นตัวใหญ่)
// * ค่าที่พิมพ์บันทึกเองทุกจังหวะ — ไม่มีปุ่ม "บันทึก" ให้ลืมกด

object PK {
    // # โทเคนของ Sale Here (salehere-ios · `SearchRevampStyle` + `UIColor.Reds/Grays`) — แอปพี่น้องต้องพูดภาษาเดียวกัน
    // แดง #ED1C24 เหลือเป็น "จุด" ของแบรนด์: ป้ายเลขขั้น · ดาวบังคับ · ข้อผิดพลาด
    // เลือกแล้ว = พื้นเทาอ่อน + ขอบดำ + ตัวหนังสือดำหนา · ปุ่มหลัก = ถ่าน #2B2D33
    private fun hex(v: Long): Color = Color(0xFF000000L or (v and 0xFFFFFFL))

    val bg = hex(0xF9FAFB)
    /** ของที่ "เลือกแล้ว" — พื้นเทาอ่อน ขอบดำ ตัวหนังสือดำ */
    val pick = hex(0xF1F2F4)
    val onPick = hex(0x16181D)
    val pickLine = hex(0x16181D)
    /** ถ่าน — ปุ่มหลัก */
    val charcoal = hex(0x2B2D33)
    val card = Color.White
    val shadow = Color.Black.opacity(0.04)
    val surface = Color.White
    /** พื้นช่องกรอก = bgSecondary ของแอป */
    val fieldFill = hex(0xF3F4F6)
    val fieldFocus = hex(0xE5E7EB)
    val line = hex(0xE5E7EB)
    val line2 = hex(0xD1D5DB)
    // ตัวหนังสือ
    val ink = hex(0x16181D)
    val onInk = Color.White
    val muted = hex(0x666666)
    val hint = hex(0x919191)
    // แดงแบรนด์
    val red = hex(0xED1C24)
    val redDark = hex(0xC8161D)
    val redTint = hex(0xFDE8E9)
    val redTint2 = hex(0xF8B4B6)
    // ทอง CI — เฉพาะดาว STAR และการ์ดรางวัลหน้าจบ
    val gold = hex(0xFFC200)
    val gold2 = rgb(250.0 / 255, 224.0 / 255, 120.0 / 255)
    val goldInk = rgb(58.0 / 255, 26.0 / 255, 5.0 / 255)
    // สถานะ — ป้ายเล็ก ๆ ที่มีความหมายเท่านั้น
    val ok = rgb(0.16, 0.62, 0.37)
    val okTint = ok.opacity(0.12)
    val warn = rgb(0.92, 0.56, 0.08)
    val warnTint = warn.opacity(0.12)
    /** `.regular.tint(.white.opacity(0.7))` — Android ไม่มี Liquid Glass ใช้ม่านขาวขุ่น (ดู `Modifier.pkGlass`) */
    val glass = Color.White.opacity(0.7)
    val glassButton = Color.White.opacity(0.7)
    // ชื่อพาสเทลเดิม — ชี้ไปพื้นโปร่งเดียวกันหมด
    val peach = fieldFill
    val lavender = fieldFill
    val mint = fieldFill
    val sky = fieldFill
    val lemon = fieldFill
    val rose = fieldFill
    val aqua = fieldFill
    val sand = fieldFill

    // ชื่อเก่าที่ section ต่าง ๆ ยังเรียก
    val panel = surface
    val panelStrong = redTint
    val field = fieldFill
    val stroke = line2
    val ink2 = muted
    val ink3 = hint
    val err = red

    const val radius = 24f
    const val fieldRadius = 16f

    fun shape(r: Float = radius): RoundedCornerShape = RoundedCornerShape(r.dp)

    /** ป้าย STAR กับการ์ดรางวัลใช้ไล่สี — ปุ่มปกติเป็นแดงเรียบ */
    val redGradient: Brush get() = Brush.linearGradient(listOf(red, redDark))
    val goldGradient: Brush get() = Brush.horizontalGradient(listOf(gold2, gold))
}

// MARK: - พื้นผิว

/** กระจกของหน้านี้ (= `.glassEffect(PK.glass)`) — ม่านขาวขุ่น + ขอบแสงบาง + เงาจาง (ไม่มีเบลอพื้นหลังจริง) */
@Suppress("UNUSED_PARAMETER")
fun Modifier.pkGlass(shape: Shape, interactive: Boolean = false): Modifier = this
    .dropShadow(shape, Shadow(radius = 12.dp, color = Color.Black.opacity(0.07), offset = DpOffset(0.dp, 4.dp)))
    .background(PK.glass, shape)
    .border(0.8.dp, Brush.linearGradient(listOf(Color.White.opacity(0.95), Color.White.opacity(0.35))), shape)

/** พื้นของแผ่น/การ์ดในฟอร์ม (= `PKSurface`) — ขาว ขอบบาง เงาจาง */
fun Modifier.pkSurface(radius: Float = PK.radius): Modifier {
    val s = PK.shape(radius)
    return this
        .dropShadow(s, Shadow(radius = 3.dp, color = PK.shadow, offset = DpOffset(0.dp, 1.dp)))
        .background(PK.card, s)
        .border(1.dp, PK.line, s)
}

/** พื้นของแผ่น/การ์ดในฟอร์ม — ขาวลอยบนพื้นเทาด้วยเงาจาง ไม่มีกระจก */
@Composable
fun PKSurface(radius: Float = PK.radius, modifier: Modifier = Modifier) {
    Box(modifier.pkSurface(radius))
}

/** การ์ดขาวลอยบนเวทีสว่าง (= `PKSoftCard`) · `tint` = ส่วนที่ยังขาด: พื้นขาวอาบสีจาง ๆ ขอบสีเดียวกัน */
fun Modifier.pkSoftCard(radius: Float = 22f, tint: Color? = null): Modifier {
    val s = PK.shape(radius)
    var m = this
        .dropShadow(s, Shadow(radius = 14.dp, color = PK.shadow, offset = DpOffset(0.dp, 5.dp)))
        .background(PK.card, s)
    if (tint != null) m = m.background(tint.opacity(0.08), s).border(1.2.dp, tint.opacity(0.5), s)
    return m
}

/** การ์ดขาวลอยบนเวทีสว่าง — ไม่มีเส้นขอบเทา ใช้เงาฟุ้งแยกตัวแทน (วางเป็นพื้นด้วย `Modifier.matchParentSize()`) */
@Composable
fun PKSoftCard(radius: Float = 22f, tint: Color? = null, modifier: Modifier = Modifier) {
    Box(modifier.pkSoftCard(radius, tint))
}

/** ไอคอนในวงกลมพื้นจาง — แบนราบ ไม่มีเงา/ขอบ */
@Composable
fun PKSoftIcon(tint: Color? = null, modifier: Modifier = Modifier) {
    Box(modifier.background(tint?.opacity(0.14) ?: PK.ink.opacity(0.045), CircleShape))
}

/** เส้นประรอบกรอบมุมมน (= `.strokeBorder(style: StrokeStyle(dash:))`) */
fun Modifier.pkDashedBorder(width: Float, color: Color, radius: Float, dash: Float, gap: Float): Modifier =
    this.drawWithContent {
        drawContent()
        val w = width.dp.toPx()
        drawRoundRect(
            color = color,
            topLeft = Offset(w / 2, w / 2),
            size = Size(size.width - w, size.height - w),
            cornerRadius = CornerRadius(max(0f, radius.dp.toPx() - w / 2)),
            style = Stroke(width = w, pathEffect = PathEffect.dashPathEffect(floatArrayOf(dash.dp.toPx(), gap.dp.toPx()))),
        )
    }

/** ตัวย่อขนาดอัตโนมัติ (= `.minimumScaleFactor(k)`) */
fun pkAutoSize(size: Float, scale: Float): TextAutoSize =
    TextAutoSize.StepBased(minFontSize = (size * scale).sp, maxFontSize = size.sp, stepSize = 0.25.sp)

/** วงหมุนรอโหลด (= `ProgressView()`) — ซี่ 8 ซี่แบบ iOS */
@Composable
fun PKSpinner(diameter: Float = 20f, tint: Color = PK.ink, modifier: Modifier = Modifier) {
    val tr = rememberInfiniteTransition(label = "pkSpinner")
    val t by tr.animateFloat(0f, 8f, infiniteRepeatable(tween(800, easing = LinearEasing)), label = "spin")
    Canvas(modifier.size(diameter.dp)) {
        val step = floor(t).toInt() % 8
        val d = size.minDimension
        val r1 = d * 0.24f
        val r2 = d * 0.47f
        val sw = d * 0.09f
        for (i in 0 until 8) {
            val a = (i * 45.0 - 90.0) * PI / 180.0
            val k = (step - i + 8) % 8
            val alpha = 1f - k / 8f * 0.8f
            val dir = Offset(cos(a).toFloat(), sin(a).toFloat())
            drawLine(
                color = tint.opacity(alpha),
                start = center + dir * r1,
                end = center + dir * r2,
                strokeWidth = sw,
                cap = StrokeCap.Round,
            )
        }
    }
}

// MARK: - โฟกัส + ตำแหน่งช่อง (= `FocusState<String?>` + `ScrollViewReader` ids)

/**
 * id ของช่องที่กำลังพิมพ์ + ทะเบียนตำแหน่งบนหน้า — แทน `@FocusState` และ `.id(...)` ของ SwiftUI
 * `SectionScroll` ใช้ทะเบียนนี้เลื่อนไปหาช่องที่ validate ไม่ผ่านแล้วโฟกัสให้
 */
class PKFocus {
    /** = `focus.wrappedValue` */
    var current: String? by mutableStateOf(null)
    private val requesters = HashMap<String, FocusRequester>()
    internal val anchors = HashMap<String, LayoutCoordinates>()
    internal var clearer: () -> Unit = {}

    fun requester(id: String): FocusRequester = requesters.getOrPut(id) { FocusRequester() }

    /** `focus.wrappedValue = id` — id ที่ไม่ใช่ช่องพิมพ์ (กระเบื้อง · กล่องติ๊ก) ไม่มีผล เหมือน iOS */
    fun focus(id: String?) {
        if (id == null) {
            clear()
            return
        }
        val r = requesters[id] ?: return
        if (runCatching { r.requestFocus() }.isSuccess) current = id
    }

    /** `focus.wrappedValue = nil` — ปิดคีย์บอร์ด */
    fun clear() {
        current = null
        clearer()
    }

    fun anchor(id: String): LayoutCoordinates? = anchors[id]?.takeIf { it.isAttached }
}

@Composable
fun rememberPKFocus(): PKFocus {
    val fm = LocalFocusManager.current
    val f = remember { PKFocus() }
    f.clearer = { fm.clearFocus() }
    return f
}

/** ทะเบียนโฟกัสของหน้าที่กำลังวาด — `SectionScroll` ใส่ให้ ชิ้นที่มีแค่ `.id(...)` จดตำแหน่งผ่านตัวนี้ */
val LocalPKFocus = staticCompositionLocalOf<PKFocus?> { null }

/** `.id(id)` ของ SwiftUI — จดตำแหน่งไว้ให้ `SectionScroll` เลื่อนมาหา */
@Composable
fun Modifier.pkAnchor(id: String): Modifier {
    val f = LocalPKFocus.current ?: return this
    return this.onGloballyPositioned { f.anchors[id] = it }
}

/** รู้ว่าคีย์บอร์ดขึ้นอยู่ไหม (= `KeyboardWatcher`) — แถบปุ่มล่างต้องหลบ ไม่งั้นมันทับช่องที่กำลังพิมพ์ */
@Composable
fun keyboardVisible(): Boolean = WindowInsets.ime.getBottom(LocalDensity.current) > 0

/** แถบ "เสร็จ" เหนือคีย์บอร์ด (= `ToolbarItemGroup(placement: .keyboard)`) — แป้นตัวเลขไม่มีปุ่มปิดของตัวเอง */
@Composable
fun PKKeyboardDone(onDone: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier
            .fillMaxWidth()
            .background(PK.bg.opacity(0.97))
            .drawBehind { drawRect(PK.line, size = Size(size.width, 1.dp.toPx())) }
            .height(44.dp)
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Spacer(Modifier.weight(1f))
        Text(
            "เสร็จ", style = sh(15f, SHFont.bold), color = PK.ink,
            modifier = Modifier.tap(onClick = onDone).padding(horizontal = 8.dp, vertical = 8.dp),
        )
    }
}

// MARK: - แผ่น

/** การ์ดขาวหนึ่งเรื่อง — ขอบบาง เงาจาง ๆ หัวข้อทางซ้าย */
@Composable
fun PKPanel(
    title: String? = null,
    subtitle: String? = null,
    trailing: (@Composable () -> Unit)? = null,
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier.fillMaxWidth().pkSurface().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (title != null || subtitle != null) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.weight(1f).alignByBaseline(), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    if (title != null) Text(title, style = sh(16f, SHFont.bold), color = PK.ink)
                    if (subtitle != null) Text(subtitle, style = sh(12.5f, SHFont.medium), color = PK.muted)
                }
                if (trailing != null) Box(Modifier.alignByBaseline()) { trailing() }
            }
        }
        content()
    }
}

/** ป้ายหัวช่อง — ชื่อ + ดาวบังคับ + คำใบ้ทางขวา */
@Composable
fun PKLabel(text: String, required: Boolean = false, hint: String? = null, modifier: Modifier = Modifier) {
    Row(modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(text, style = sh(13f, SHFont.semibold), color = PK.muted)
        if (required) Text("*", style = sh(13f, SHFont.bold), color = PK.red)
        Spacer(Modifier.weight(1f))
        if (hint != null) {
            Text(hint, style = sh(11.5f, SHFont.medium), color = PK.hint, maxLines = 1, autoSize = pkAutoSize(11.5f, 0.8f))
        }
    }
}

// MARK: - ช่องพิมพ์

/**
 * ช่องพิมพ์เปล่า ๆ บนฟอนต์ของแอป — เก็บตำแหน่งเคอร์เซอร์เอง ค่าที่ผู้เรียกจัดรูปใหม่ (เลขบัญชีมีขีด) เคอร์เซอร์ไปท้ายเสมอ
 * ใช้ใน `PKField` และช่องราคาของตารางเรท
 */
@Composable
fun PKTextInput(
    text: String,
    onTextChange: (String) -> Unit,
    style: TextStyle,
    color: Color = PK.ink,
    placeholder: String = "",
    placeholderStyle: TextStyle = style,
    placeholderColor: Color = PK.hint.opacity(0.75),
    keyboard: KeyboardType = KeyboardType.Text,
    autocap: KeyboardCapitalization = KeyboardCapitalization.Sentences,
    noCorrect: Boolean = false,
    paragraph: Boolean = false,
    textAlign: TextAlign = TextAlign.Start,
    onDone: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val done = onDone
    var local by remember { mutableStateOf(TextFieldValue(text, TextRange(text.length))) }
    val value = if (local.text == text) local else TextFieldValue(text, TextRange(text.length))
    BasicTextField(
        value = value,
        onValueChange = { v ->
            local = v
            if (v.text != text) onTextChange(v.text)
        },
        modifier = modifier,
        textStyle = style.copy(color = color, textAlign = textAlign),
        keyboardOptions = KeyboardOptions(
            capitalization = autocap,
            autoCorrectEnabled = !noCorrect,
            keyboardType = keyboard,
            imeAction = if (paragraph) ImeAction.Default else ImeAction.Done,
        ),
        keyboardActions = done?.let { f -> KeyboardActions(onDone = { f() }) } ?: KeyboardActions(),
        singleLine = !paragraph,
        maxLines = if (paragraph) 5 else 1,
        minLines = if (paragraph) 2 else 1,
        cursorBrush = SolidColor(color),
        decorationBox = { inner ->
            Box(contentAlignment = if (textAlign == TextAlign.End) Alignment.CenterEnd else Alignment.CenterStart) {
                if (value.text.isEmpty() && placeholder.isNotEmpty()) {
                    Text(
                        placeholder, style = placeholderStyle.copy(textAlign = textAlign), color = placeholderColor,
                        maxLines = if (paragraph) 5 else 1, overflow = TextOverflow.Ellipsis,
                    )
                }
                inner()
            }
        },
    )
}

/**
 * ช่องพิมพ์หนึ่งช่อง — ป้าย · ช่อง · ข้อผิดพลาดใต้ช่อง
 * `id` ใช้สองอย่าง: โฟกัสคีย์บอร์ด และเป็นเป้าให้ `SectionScroll` เลื่อนมาหาเมื่อ validate ไม่ผ่าน
 */
@Composable
fun PKField(
    label: String,
    required: Boolean = false,
    text: String,
    onTextChange: (String) -> Unit,
    placeholder: String = "",
    keyboard: KeyboardType = KeyboardType.Text,
    contentType: ContentType? = null,
    autocap: KeyboardCapitalization = KeyboardCapitalization.Sentences,
    noCorrect: Boolean = false,
    paragraph: Boolean = false,
    error: String? = null,
    hint: String? = null,
    limit: Int? = null,
    leading: String? = null,
    id: String,
    focus: PKFocus,
    onCommit: () -> Unit = {},
    modifier: Modifier = Modifier,
) {
    val isFocused = focus.current == id
    val had = remember { booleanArrayOf(false) }
    val shape = PK.shape(PK.fieldRadius)
    val fill by animateColorAsState(if (isFocused) PK.fieldFocus else PK.fieldFill, Motion.snap.spec(), label = "fieldFill")
    val stroke by animateColorAsState(
        if (error != null) PK.red else if (isFocused) PK.ink else PK.ink.opacity(0.0), Motion.snap.spec(), label = "fieldStroke",
    )
    // ตัวนับโผล่ตอนใกล้เต็มเท่านั้น — "0/40" บนทุกช่องคือเสียงรบกวน ไม่ใช่ข้อมูล
    val counter = limit?.takeIf { text.length * 10 >= it * 7 }?.let { "${text.length}/$it" }
    // ข้อความล่าสุดค้างไว้ให้จางออกได้ทั้งประโยค
    val lastError = remember { arrayOf(error ?: "") }
    if (error != null) lastError[0] = error

    Column(
        modifier
            .fillMaxWidth()
            .onGloballyPositioned { focus.anchors[id] = it }
            .pointerInput(id) { detectTapGestures { focus.focus(id) } },
        verticalArrangement = Arrangement.spacedBy(5.dp),
    ) {
        if (label.isNotEmpty()) PKLabel(text = label, required = required, hint = counter ?: hint)

        Row(
            Modifier
                .fillMaxWidth()
                .heightIn(min = 46.dp)
                // filled ไม่มีขอบตอนปกติ — ช่องที่ "จม" ลงไปอ่านเป็นแอป
                .background(fill, shape)
                .border(1.6.dp, stroke, shape)
                .padding(horizontal = 15.dp, vertical = if (paragraph) 11.dp else 0.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (leading != null) {
                // ป้ายนำหน้าห้ามตกบรรทัด — ช่องพิมพ์ต่างหากที่ต้องยอมหด
                Text(leading, style = sh(15.5f, SHFont.semibold), color = PK.hint, maxLines = 1, softWrap = false)
            }
            var fm = Modifier
                .weight(1f)
                .focusRequester(focus.requester(id))
                .onFocusChanged { st ->
                    if (st.isFocused) focus.current = id
                    else if (focus.current == id) focus.current = null
                    if (had[0] && !st.isFocused) onCommit()
                    had[0] = st.isFocused
                }
            val ct = contentType
            if (ct != null) fm = fm.semantics { this.contentType = ct }
            PKTextInput(
                text = text,
                onTextChange = onTextChange,
                style = sh(16f),
                color = PK.ink,
                placeholder = placeholder,
                keyboard = keyboard,
                autocap = autocap,
                noCorrect = noCorrect,
                paragraph = paragraph,
                onDone = if (paragraph) null else ({ focus.clear() }),
                modifier = fm,
            )
            if (text.isNotEmpty() && isFocused) {
                Box(Modifier.tap {
                    onTextChange("")
                    Haptics.light()
                }) {
                    PIcon(Ph.xCircle, size = 17f, weight = PhWeight.fill, tint = PK.line2)
                }
            }
        }

        AnimatedVisibility(visible = error != null, enter = fadeIn(Motion.snap.spec()), exit = fadeOut(Motion.snap.spec())) {
            PKErrorLine(lastError[0])
        }
    }
}

/** ข้อผิดพลาดใต้ช่อง — ไอคอนเตือน + ข้อความแดง */
@Composable
fun PKErrorLine(text: String, modifier: Modifier = Modifier) {
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
        PIcon(Ph.warningCircle, size = 12f, weight = PhWeight.fill, tint = PK.red)
        Text(text, style = sh(12f, SHFont.medium), color = PK.red)
    }
}

/**
 * ช่องเลือกจากรายการ — หน้าตาเหมือน `PKField` แต่แตะแล้วเป็นเมนู
 * ใช้กับรายการยาวที่ชิปจะกินทั้งจอ (เช่น ธนาคาร 13 แห่ง)
 */
@Composable
fun PKSelect(
    label: String,
    required: Boolean = false,
    options: List<String>,
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String = "เลือก…",
    error: String? = null,
    id: String,
    modifier: Modifier = Modifier,
) {
    var open by remember { mutableStateOf(false) }
    var width by remember { mutableIntStateOf(0) }
    val shape = PK.shape(PK.fieldRadius)
    val density = LocalDensity.current
    Column(modifier.fillMaxWidth().pkAnchor(id), verticalArrangement = Arrangement.spacedBy(7.dp)) {
        PKLabel(text = label, required = required)
        Box {
            Row(
                Modifier
                    .fillMaxWidth()
                    .heightIn(min = 46.dp)
                    .onSizeChanged { width = it.width }
                    .background(PK.fieldFill, shape)
                    .border(1.6.dp, if (error != null) PK.red else PK.red.opacity(0.0), shape)
                    .tap { open = true }
                    .padding(horizontal = 15.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    if (value.isEmpty()) placeholder else value,
                    style = sh(16f),
                    color = if (value.isEmpty()) PK.hint.opacity(0.75) else PK.ink,
                    maxLines = 1, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )
                PIcon(Ph.caretUpDown, size = 13f, tint = PK.hint)
            }
            if (open) {
                val gap = with(density) { 6.dp.roundToPx() }
                Popup(
                    popupPositionProvider = PKMenuPosition(gap),
                    onDismissRequest = { open = false },
                    properties = PopupProperties(focusable = true),
                ) {
                    PKMenuList(
                        options = options,
                        value = value,
                        width = with(density) { width.toDp() },
                        onPick = { o ->
                            Haptics.light()
                            onValueChange(o)
                            open = false
                        },
                    )
                }
            }
        }
        if (error != null) PKErrorLine(error)
    }
}

/** ตำแหน่งเมนูของ `PKSelect` — ใต้ช่องถ้าพอ ไม่พอขึ้นเหนือช่อง */
private class PKMenuPosition(private val gap: Int) : PopupPositionProvider {
    override fun calculatePosition(anchorBounds: IntRect, windowSize: IntSize, layoutDirection: LayoutDirection, popupContentSize: IntSize): IntOffset {
        val x = anchorBounds.left.coerceIn(0, max(0, windowSize.width - popupContentSize.width))
        val below = anchorBounds.bottom + gap
        val y = if (below + popupContentSize.height <= windowSize.height) below
        else max(0, anchorBounds.top - gap - popupContentSize.height)
        return IntOffset(x, y)
    }
}

@Composable
private fun PKMenuList(options: List<String>, value: String, width: androidx.compose.ui.unit.Dp, onPick: (String) -> Unit) {
    val shape = PK.shape(14f)
    Column(
        Modifier
            .width(width)
            .heightIn(max = 320.dp)
            .dropShadow(shape, Shadow(radius = 24.dp, color = Color.Black.opacity(0.16), offset = DpOffset(0.dp, 8.dp)))
            .background(Color.White, shape)
            .border(0.5.dp, PK.line, shape)
            .clip(shape)
            .verticalScroll(rememberScrollState()),
    ) {
        options.forEachIndexed { i, o ->
            if (i > 0) Box(Modifier.fillMaxWidth().padding(start = 40.dp).height(0.5.dp).background(PK.line))
            Row(
                Modifier.fillMaxWidth().pkRowPress { onPick(o) }.padding(horizontal = 14.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.size(16.dp), contentAlignment = Alignment.Center) {
                    if (o == value) PIcon(Ph.check, size = 14f, weight = PhWeight.bold, tint = PK.ink)
                }
                Text(o, style = sh(15.5f), color = PK.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

// MARK: - ตัวเลือก

/** ปุ่มตัวเลือกหนึ่งปุ่ม — แคปซูลกว้างเต็มช่อง เลือกแล้วพื้นเทา ขอบดำ · จางเมื่อครบโควตา */
@Composable
fun PKChoice(label: String, on: Boolean = false, dim: Boolean = false, modifier: Modifier = Modifier, action: () -> Unit) {
    var bumps by remember { mutableIntStateOf(0) }
    val fill by animateColorAsState(if (on) PK.pick else PK.card, Motion.snap.spec(), label = "choiceFill")
    val edge by animateColorAsState(if (on) PK.pickLine else PK.line, Motion.snap.spec(), label = "choiceEdge")
    Box(
        modifier
            .pkBump(bumps)
            .dockPress {
                if (dim) {
                    Haptics.rigid()
                    return@dockPress
                }
                Haptics.light()
                bumps += 1
                action()
            }
            .semantics { selected = on }
            .alpha(if (dim) 0.4f else 1f)
            .fillMaxWidth()
            .heightIn(min = 40.dp)
            // ยังไม่เลือก = ขาวเส้นบาง ใช้ได้ทั้งบนพื้นเทาและในการ์ดขาว
            .background(fill, CircleShape)
            .border(if (on) 1.5.dp else 1.dp, edge, CircleShape)
            .padding(horizontal = 12.dp, vertical = 4.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            style = sh(13.5f, if (on) SHFont.bold else SHFont.semibold),
            color = if (on) PK.onPick else PK.ink.opacity(0.85),
            textAlign = TextAlign.Center,
            maxLines = 2,
            autoSize = pkAutoSize(13.5f, 0.8f),
        )
    }
}

/** ตารางปุ่มตัวเลือก 2 คอลัมน์ กว้างเท่ากันทุกปุ่ม — ใช้กับทุกคำถามที่เลือกจากรายการ */
@Composable
fun <Item> PKChoiceGrid(
    items: List<Item>,
    label: (Item) -> String,
    isOn: (Item) -> Boolean,
    isDim: (Item) -> Boolean = { false },
    modifier: Modifier = Modifier,
    action: (Item) -> Unit,
) {
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        items.chunked(2).forEach { row ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                row.forEach { item ->
                    PKChoice(label = label(item), on = isOn(item), dim = isDim(item), modifier = Modifier.weight(1f)) { action(item) }
                }
                if (row.size == 1) Spacer(Modifier.weight(1f))
            }
        }
    }
}

/** ตารางกระเบื้อง 2 คอลัมน์ — จำนวนคี่ ใบสุดท้ายอยู่ซ้ายขนาดเท่าใบอื่น · สองใบในแถวสูงเท่ากัน */
@Composable
fun <Item> PKTileGrid(items: List<Item>, modifier: Modifier = Modifier, tile: @Composable (Item) -> Unit) {
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        items.chunked(2).forEach { row ->
            Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                row.forEach { item ->
                    Box(Modifier.weight(1f).fillMaxHeight()) { tile(item) }
                }
                if (row.size == 1) Spacer(Modifier.weight(1f))
            }
        }
    }
}

/**
 * ชิปเลือก — ขาวขอบบาง · เลือกแล้วพื้นหมึก ตัวขาว
 * จางและกดไม่ได้เมื่อครบโควตา — ไม่ใช่ดูกดได้แล้วเงียบ · `plus` = + หน้าชื่อ เลือกแล้วเป็น ✓
 */
@Composable
fun PKChip(
    label: String,
    on: Boolean = false,
    dim: Boolean = false,
    tint: Color = PK.red,
    plus: Boolean = false,
    modifier: Modifier = Modifier,
    action: () -> Unit,
) {
    var bumps by remember { mutableIntStateOf(0) }
    val brand = tint == PK.red
    val fg = if (on) (if (brand) PK.onInk else tint) else PK.ink.opacity(if (dim) 0.3 else 0.8)
    val bg by animateColorAsState(
        if (on) (if (brand) PK.ink else tint.opacity(0.16)) else PK.surface.opacity(if (dim) 0.5 else 1.0),
        Motion.snap.spec(), label = "chipBg",
    )
    val edge = if (on) (if (brand) PK.ink else tint) else PK.line2
    Row(
        modifier
            .pkBump(bumps)
            .dockPress {
                if (dim) {
                    Haptics.rigid()
                    return@dockPress
                }
                Haptics.light()
                bumps += 1
                action()
            }
            .semantics { selected = on }
            .background(bg, CircleShape)
            .border(if (on) 1.5.dp else 1.2.dp, edge, CircleShape)
            .padding(horizontal = 15.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (plus) PIcon(if (on) Ph.check else Ph.plus, size = 11f, tint = fg)
        Text(label, style = sh(14f, if (on) SHFont.bold else SHFont.medium), color = fg, maxLines = 1)
    }
}

/**
 * การ์ดตัวเลือกแบบกระเบื้อง — ไอคอนเล็กซ้าย · ชื่อ · คำอธิบายสั้น
 * ยังไม่เลือก = ขาวขอบบาง · เลือกแล้ว = พื้นเทาขอบดำ (ไม่มีวงติ๊ก — พื้นก็บอกอยู่แล้ว)
 */
@Composable
fun PKTile(icon: Ph, title: String, detail: String? = null, on: Boolean = false, modifier: Modifier = Modifier, action: () -> Unit) {
    var bumps by remember { mutableIntStateOf(0) }
    val shape = PK.shape(16f)
    val fill by animateColorAsState(if (on) PK.pick else PK.card, Motion.snap.spec(), label = "tileFill")
    Row(
        modifier
            .pkBump(bumps)
            .dockPress {
                Haptics.light()
                bumps += 1
                action()
            }
            .semantics { selected = on }
            .fillMaxWidth()
            .fillMaxHeight()
            .background(fill, shape)
            .border(if (on) 1.5.dp else 1.dp, if (on) PK.pickLine else PK.line, shape)
            .padding(11.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier.size(36.dp).background(if (on) Color.White else PK.fieldFill, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            PIcon(icon, size = 17f, weight = if (on) PhWeight.fill else PhWeight.regular, tint = if (on) PK.onPick else PK.ink)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(title, style = sh(14f, SHFont.bold), color = if (on) PK.onPick else PK.ink, maxLines = 2, overflow = TextOverflow.Ellipsis)
            if (detail != null) {
                Text(
                    detail, style = sh(11f, SHFont.medium), color = if (on) PK.onPick.opacity(0.75) else PK.muted,
                    maxLines = 2, overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

// MARK: - แถบปุ่มล่าง

/**
 * พื้นแถบปุ่มล่าง (= `PKBottomBar`) — ม่านไล่ขึ้น 44pt เหนือแถบ แล้วทึบ 0.94 ถึงขอบจอ
 * ผู้เรียกใส่ `navigationBarsPadding()` **หลัง** ตัวนี้ ให้พื้นลากลงไปใต้แถบระบบด้วย
 */
fun Modifier.pkBottomBar(): Modifier = this.drawBehind {
    val fade = 44.dp.toPx()
    drawRect(
        brush = Brush.verticalGradient(listOf(PK.bg.opacity(0.0), PK.bg.opacity(0.94)), startY = -fade, endY = 0f),
        topLeft = Offset(0f, -fade),
        size = Size(size.width, fade),
    )
    drawRect(PK.bg.opacity(0.94), size = size)
}

/** แถบปุ่มล่างแบบกล่อง — ใส่พื้นของ `pkBottomBar()` ให้เนื้อหาข้างใน */
@Composable
fun PKBottomBar(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Box(modifier.pkBottomBar()) { content() }
}

// MARK: - จังหวะ

/** ค่าในช่วงเวลาหนึ่งของคีย์เฟรม — ไล่แบบนุ่ม (smoothstep) ระหว่างจุด */
private fun keyframe(t: Float, times: FloatArray, values: FloatArray): Float {
    if (t <= times[0]) return values[0]
    for (i in 1 until times.size) {
        if (t <= times[i]) {
            val u = (t - times[i - 1]) / (times[i] - times[i - 1])
            val s = u * u * (3 - 2 * u)
            return values[i - 1] + (values[i] - values[i - 1]) * s
        }
    }
    return values.last()
}

/** เด้งนิดเดียวตอนถูกแตะ (= `PKBump`) — 1.06 ใน 0.12 วิ แล้วเด้งกลับ 1.0 */
@Composable
fun Modifier.pkBump(trigger: Int): Modifier {
    val t = remember { Animatable(1f) }
    LaunchedEffect(trigger) {
        if (trigger == 0) return@LaunchedEffect
        t.snapTo(0f)
        t.animateTo(1f, tween(420, easing = LinearEasing))
    }
    return this.graphicsLayer {
        val sec = t.value * 0.42f
        val s = if (sec < 0.12f) {
            val u = sec / 0.12f
            1f + 0.06f * (1f - (1f - u) * (1f - u))
        } else {
            val u = (sec - 0.12f) / 0.30f
            1f + 0.06f * exp(-4f * u) * cos(3f * PI.toFloat() * u)
        }
        scaleX = s
        scaleY = s
    }
}

/** เด้งนิดเดียวตอนถูกแตะ — แบบกล่อง */
@Composable
fun PKBump(trigger: Int, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Box(modifier.pkBump(trigger)) { content() }
}

/** ไหลเข้าที่ทีละชิ้น (= `PKReveal`) — จาง + ลอยขึ้น 18pt หน่วงตามลำดับ */
@Composable
fun Modifier.pkReveal(index: Int): Modifier {
    val p = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(((0.05 + Motion.stagger(index, step = 0.06, cap = 0.4)) * 1000).toLong())
        p.animateTo(1f, Motion.settle.float)
    }
    return this.graphicsLayer {
        alpha = p.value.coerceIn(0f, 1f)
        translationY = (1f - p.value) * 18.dp.toPx()
    }
}

/** ไหลเข้าที่ทีละชิ้น — แบบกล่อง */
@Composable
fun PKReveal(index: Int, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Box(modifier.pkReveal(index)) { content() }
}

/** การ์ดตัวเลือกใหญ่ — ไอคอนในกล่อง · ชื่อ · คำอธิบาย · ติ๊ก (= `.opt` ของเว็บ) */
@Composable
fun PKOptionCard(icon: Ph, title: String, detail: String? = null, on: Boolean = false, modifier: Modifier = Modifier, action: () -> Unit) {
    val shape = PK.shape(PK.fieldRadius)
    Row(
        modifier
            .dockPress {
                Haptics.light()
                action()
            }
            .semantics { selected = on }
            .fillMaxWidth()
            .background(PK.surface, shape)
            .border(if (on) 1.8.dp else 1.2.dp, if (on) PK.ink else PK.line, shape)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(44.dp).background(PK.fieldFill, PK.shape(12f)), contentAlignment = Alignment.Center) {
            PIcon(icon, size = 20f, weight = PhWeight.fill, tint = PK.ink)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(title, style = sh(15f, SHFont.bold), color = PK.ink)
            if (detail != null) Text(detail, style = sh(12f, SHFont.medium), color = PK.muted)
        }
        Box(
            Modifier
                .size(22.dp)
                .background(if (on) PK.ink else PK.ink.opacity(0.0), CircleShape)
                .border(1.5.dp, if (on) PK.ink else PK.line2, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            if (on) PIcon(Ph.check, size = 10f, tint = PK.onInk)
        }
    }
}

/** สวิตช์ปิด/เปิด แบบแถว — ป้ายซ้าย สวิตช์ขวา */
@Composable
fun PKToggleRow(label: String, detail: String? = null, on: Boolean, onOnChange: (Boolean) -> Unit, modifier: Modifier = Modifier) {
    val k by animateFloatAsState(if (on) 1f else 0f, Motion.snap.float, label = "toggle")
    Row(
        modifier.fillMaxWidth().tap { onOnChange(!on) }.semantics { selected = on },
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(label, style = sh(14.5f, SHFont.semibold), color = PK.ink)
            if (detail != null) Text(detail, style = sh(12f, SHFont.medium), color = PK.muted)
        }
        Box(
            Modifier.size(51.dp, 31.dp).background(lerp(PK.ink.opacity(0.12), PK.ink, k), CircleShape),
            contentAlignment = Alignment.CenterStart,
        ) {
            Box(
                Modifier
                    .offset(x = (2f + 20f * k).dp)
                    .size(27.dp)
                    .dropShadow(CircleShape, Shadow(radius = 4.dp, color = Color.Black.opacity(0.15), offset = DpOffset(0.dp, 2.dp)))
                    .background(Color.White, CircleShape),
            )
        }
    }
}

// MARK: - ปุ่ม

/** ปุ่มหลักปุ่มเดียวของหน้า — แคปซูลถ่าน ตัวหนังสือขาว · กดไม่ได้ = จาง + สั่นแข็ง */
@Composable
fun PKPrimaryButton(
    title: String,
    symbol: Ph? = null,
    tint: Color = PK.charcoal,
    enabled: Boolean = true,
    modifier: Modifier = Modifier,
    action: () -> Unit,
) {
    val a by animateFloatAsState(if (enabled) 1f else 0.4f, Motion.snap.float, label = "primaryAlpha")
    Row(
        modifier
            .fillMaxWidth()
            .height(54.dp)
            .dockPress {
                if (!enabled) {
                    Haptics.rigid()
                    return@dockPress
                }
                Haptics.medium()
                action()
            }
            .alpha(a)
            .background(tint, CircleShape)
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title, style = sh(16f, SHFont.bold), color = Color.White, maxLines = 1, overflow = TextOverflow.Ellipsis)
        if (symbol != null) PIcon(symbol, size = 15f, tint = Color.White)
    }
}

/** ปุ่มรอง — ขาว ขอบบาง (= `.btn` ของเว็บ) */
@Composable
fun PKSecondaryButton(title: String, symbol: Ph? = null, height: Float = 50f, modifier: Modifier = Modifier, action: () -> Unit) {
    Row(
        modifier
            .fillMaxWidth()
            .height(height.dp)
            .dockPress {
                Haptics.light()
                action()
            }
            .background(PK.card, CircleShape)
            .border(1.dp, PK.line2, CircleShape)
            .padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (symbol != null) PIcon(symbol, size = 14f, tint = PK.ink)
        Text(title, style = sh(14.5f, SHFont.semibold), color = PK.ink, maxLines = 1)
    }
}

/** ปุ่มกลม — กลับ/ปิด/เพิ่ม · กระจกขาว */
@Composable
fun PKCircleButton(symbol: Ph, label: String, modifier: Modifier = Modifier, action: () -> Unit) {
    Box(
        modifier
            .size(40.dp)
            .dockPress {
                Haptics.light()
                action()
            }
            .semantics { contentDescription = label }
            .pkGlass(CircleShape, interactive = true),
        contentAlignment = Alignment.Center,
    ) {
        PIcon(symbol, size = 16f, tint = PK.ink)
    }
}

// MARK: - ป้าย

/** ป้าย "✦ SALE HERE STAR" — แดง ตัวหนังสือขาวถ่างระยะ · ห้ามหักบรรทัด */
@Composable
fun PKStarBadge(size: Float = 11f, modifier: Modifier = Modifier) {
    Text(
        "✦ SALE HERE STAR",
        style = sh(size, SHFont.bold).copy(letterSpacing = 1.6.sp),
        color = Color.White,
        maxLines = 1,
        softWrap = false,
        modifier = modifier.background(PK.red, CircleShape).padding(horizontal = 14.dp, vertical = 7.dp),
    )
}

/** ป้ายสถานะ · `solid` = พื้นทึบตัวขาว ใช้กับสถานะที่ต้องเห็นจากไกล */
@Composable
fun PKStatusPill(text: String, color: Color = PK.muted, symbol: Ph? = null, solid: Boolean = false, modifier: Modifier = Modifier) {
    val fg = if (solid) Color.White else color
    Row(
        modifier
            .background(if (solid) color else color.opacity(0.11), CircleShape)
            .border(0.8.dp, color.opacity(if (solid) 0.0 else 0.28), CircleShape)
            .padding(horizontal = 10.dp, vertical = 5.dp),
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (symbol != null) PIcon(symbol, size = 10f, tint = fg)
        Text(text, style = sh(11.5f, SHFont.bold), color = fg, maxLines = 1, softWrap = false)
    }
}

/** ติ๊กถูกของส่วนที่ครบแล้ว — วงกลมเขียวทึบ ถูกขาวข้างใน (เห็นจากหางตาว่าผ่านแล้ว) */
@Composable
fun PKDoneDot(size: Float = 19f, modifier: Modifier = Modifier) {
    Box(
        modifier.size(size.dp).background(PK.ok, CircleShape).semantics { contentDescription = "ครบแล้ว" },
        contentAlignment = Alignment.Center,
    ) {
        PIcon(Ph.check, size = size * 0.55f, weight = PhWeight.bold, tint = Color.White)
    }
}

/**
 * ค่าที่กรอกไว้ของแถวหนึ่ง — ป้ายชิ้นละค่า ไม่ใช่ประโยคยาวคั่นด้วยจุด
 * เกิน `max` ป้ายบอกจำนวนที่เหลือแทน เพื่อให้ทุกแถวสูงเท่ากันและไม่มีป้ายไหนโดนตัดครึ่ง
 */
@Composable
fun PKFactStrip(facts: List<String>, max: Int = 3, modifier: Modifier = Modifier) {
    val shown = facts.take(max)
    val rest = facts.size - shown.size
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(3.dp), verticalAlignment = Alignment.CenterVertically) {
        Row(Modifier.weight(1f, fill = false), horizontalArrangement = Arrangement.spacedBy(3.dp), verticalAlignment = Alignment.CenterVertically) {
            shown.forEach { f ->
                // ป้ายสุดท้ายยาวกว่าที่เหลือได้เสมอ — ย่อตัวอักษรนิดเดียวดีกว่าตัดคำทิ้ง
                Text(
                    f,
                    style = sh(10.5f, SHFont.medium),
                    color = PK.ink.opacity(0.66),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    autoSize = pkAutoSize(10.5f, 0.8f),
                    modifier = Modifier.background(PK.ink.opacity(0.05), CircleShape).padding(horizontal = 7.dp, vertical = 3.dp),
                )
            }
        }
        if (rest > 0) {
            Text("+$rest", style = sh(10f, SHFont.bold), color = PK.hint, maxLines = 1, softWrap = false)
        }
    }
}

/** สรุปสิ่งที่ยังขาด — ขึ้นเหนือปุ่มถัดไปเมื่อกดแล้วไม่ผ่าน · แตะบรรทัดไหนเลื่อนไปช่องนั้น */
@Composable
fun PKIssueBox(issues: List<ProfileIssue>, onTap: (ProfileIssue) -> Unit = {}, modifier: Modifier = Modifier) {
    val shape = PK.shape(14f)
    Column(
        modifier
            .fillMaxWidth()
            .background(PK.redTint, shape)
            .border(1.dp, PK.redTint2, shape)
            .padding(13.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            PIcon(Ph.warning, size = 12f, weight = PhWeight.fill, tint = PK.red)
            Text("ยังขาดอีก ${issues.size} อย่าง", style = sh(13f, SHFont.bold), color = PK.red)
        }
        issues.forEach { i ->
            Row(
                Modifier.fillMaxWidth().tap { onTap(i) },
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("·", style = sh(12.5f, SHFont.bold), color = PK.redDark)
                Text(i.message, style = sh(12.5f, SHFont.medium), color = PK.redDark, modifier = Modifier.weight(1f))
                PIcon(Ph.arrowUpRight, size = 10f, tint = PK.redDark)
            }
        }
    }
}

/** ข้อความช่วยสั้น ๆ — พื้นเทาอ่อน ไอคอนนำหน้า (= `.autonote`/`.note` ของเว็บ) */
@Composable
fun PKNote(text: String, symbol: Ph = Ph.info, color: Color = PK.muted, modifier: Modifier = Modifier) {
    Row(
        modifier.fillMaxWidth().background(PK.fieldFill, PK.shape(14f)).padding(horizontal = 12.dp, vertical = 9.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.Top,
    ) {
        PIcon(symbol, size = 13f, tint = color, modifier = Modifier.padding(top = 3.dp))
        Text(text, style = sh(12.5f, SHFont.medium), color = color)
    }
}

// MARK: - หัวจอ + ขั้นตอน

/** หัวจอของหน้าในกลุ่มนี้ — ปุ่มซ้าย · ชื่อกลาง · ปุ่มขวา (ว่างได้) */
@Composable
fun PKHeader(
    title: String,
    subtitle: String? = null,
    leftSymbol: Ph = Ph.caretLeft,
    leftLabel: String = "กลับ",
    onLeft: () -> Unit,
    right: (@Composable () -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier.fillMaxWidth().padding(start = 20.dp, end = 20.dp, top = 6.dp, bottom = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PKCircleButton(symbol = leftSymbol, label = leftLabel, action = onLeft)
        Column(Modifier.weight(1f).padding(horizontal = 4.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(title, style = sh(17f, SHFont.bold), color = PK.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
            if (subtitle != null) Text(subtitle, style = sh(12f, SHFont.medium), color = PK.muted, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        if (right != null) right() else Spacer(Modifier.size(40.dp))
    }
}

/**
 * แถบขั้นแบบสะสมตรา (ผู้ใช้เลือก 19 ก.ย. จาก prototype 3 แบบ · "Stamp Row")
 * หนึ่งเหรียญ = หนึ่งส่วน ร้อยด้วยเส้นเดียว · เส้นเข้มถึงเหรียญที่อยู่ = เดินมาถึงไหนแล้ว
 * ครบส่วนไหน = เหรียญนั้น "ประทับตรา" · แตะเหรียญเพื่อกระโดดไปส่วนนั้น
 */
@Composable
fun PKStampRow(
    current: Int,
    /** 0…1 ต่อส่วน */
    fill: List<Float>,
    icons: List<Ph>,
    titles: List<String>,
    /** เพิ่มขึ้นทุกครั้งที่กด "ถัดไป" ทั้งที่ยังไม่ครบ — เหรียญที่อยู่ส่ายหัว */
    nudge: Int = 0,
    onTap: (Int) -> Unit = {},
    modifier: Modifier = Modifier,
) {
    val coin = 32f
    val stamps = remember { mutableStateMapOf<Int, Int>() }
    val shakes = remember { mutableStateMapOf<Int, Int>() }
    val prevFill = remember { arrayOf(fill) }
    val prevCurrent = remember { intArrayOf(current) }
    val prevNudge = remember { intArrayOf(nudge) }

    LaunchedEffect(current) {
        if (prevCurrent[0] != current) {
            prevCurrent[0] = current
            Haptics.impact(Haptics.Style.soft)
        }
    }
    LaunchedEffect(nudge) {
        if (prevNudge[0] != nudge) {
            prevNudge[0] = nudge
            shakes[current] = (shakes[current] ?: 0) + 1
        }
    }
    LaunchedEffect(fill) {
        val old = prevFill[0]
        prevFill[0] = fill
        if (old.size != fill.size) return@LaunchedEffect
        val i = fill.indices.firstOrNull { fill[it] >= 1f && old[it] < 1f }
        if (i != null) {
            stamps[i] = (stamps[i] ?: 0) + 1
            Haptics.medium()
        } else if (fill.indices.any { fill[it] > old[it] }) {
            Haptics.impact(Haptics.Style.soft)
        }
    }

    val lineK by animateFloatAsState(current.toFloat(), spring(dampingRatio = 0.7f, stiffness = 195f), label = "stampLine")

    BoxWithConstraints(modifier.fillMaxWidth().height(44.dp)) {
        val w = maxWidth.value
        val n = max(fill.size, 2)
        // เผื่อวงรอบของเหรียญที่อยู่ (ใหญ่ขึ้น 1.14 เท่า) ไม่ให้ล้นขอบ
        val inset = (coin + 8f) * 1.14f / 2f + 1f
        val span = max(0f, w - inset * 2f)
        Box(Modifier.offset(x = inset.dp, y = 21.dp).size(span.dp, 2.dp).background(PK.line, CircleShape))
        Box(
            Modifier
                .offset(x = inset.dp, y = 21.dp)
                .size(max(0f, span * lineK / (n - 1)).dp, 2.dp)
                .background(PK.charcoal, CircleShape),
        )
        fill.indices.forEach { i ->
            val cx = inset + span * i / (n - 1)
            StampCoin(
                i = i,
                current = current,
                fill = fill[i],
                icon = icons.getOrElse(i) { Ph.circleDashed },
                title = titles.getOrElse(i) { "" },
                coin = coin,
                stamp = stamps[i] ?: 0,
                shake = shakes[i] ?: 0,
                onTap = onTap,
                modifier = Modifier.offset(x = (cx - (coin + 12f) / 2f).dp, y = (22f - (coin + 12f) / 2f).dp),
            )
        }
    }
}

@Composable
private fun StampCoin(
    i: Int,
    current: Int,
    fill: Float,
    icon: Ph,
    title: String,
    coin: Float,
    stamp: Int,
    shake: Int,
    onTap: (Int) -> Unit,
    modifier: Modifier,
) {
    val here = i == current
    val done = fill >= 1f
    val stampSpring = spring<Float>(dampingRatio = 0.62f, stiffness = 195f)
    val f by animateFloatAsState(fill, stampSpring, label = "coinFill")
    val hereK by animateFloatAsState(if (here) 1.14f else 1f, spring(dampingRatio = 0.7f, stiffness = 195f), label = "coinHere")
    val doneK by animateFloatAsState(if (done) 1f else 0.01f, stampSpring, label = "coinDone")
    val face by animateColorAsState(if (done) PK.charcoal else Color.White, spring(dampingRatio = 0.62f, stiffness = 195f), label = "coinFace")
    val stampT = remember { Animatable(1f) }
    val shakeT = remember { Animatable(1f) }
    LaunchedEffect(stamp) {
        if (stamp == 0) return@LaunchedEffect
        stampT.snapTo(0f)
        stampT.animateTo(1f, tween(620, easing = LinearEasing))
    }
    LaunchedEffect(shake) {
        if (shake == 0) return@LaunchedEffect
        shakeT.snapTo(0f)
        shakeT.animateTo(1f, tween(350, easing = LinearEasing))
    }

    Box(
        modifier
            .size((coin + 12f).dp)
            .graphicsLayer {
                // ปั๊มตรา: พุ่งขึ้น เอียง แล้วกดลง · ส่ายหัวเมื่อกดถัดไปทั้งที่ยังไม่ครบ
                val sec = stampT.value * 0.62f
                val pump = keyframe(sec, floatArrayOf(0f, 0.18f, 0.32f, 0.62f), floatArrayOf(1f, 1.3f, 0.94f, 1f))
                val tilt = keyframe(sec, floatArrayOf(0f, 0.18f, 0.32f, 0.52f), floatArrayOf(0f, -10f, 3f, 0f))
                val shx = keyframe(shakeT.value * 0.35f, floatArrayOf(0f, 0.07f, 0.14f, 0.21f, 0.28f, 0.35f), floatArrayOf(0f, -5f, 5f, -3f, 3f, 0f))
                scaleX = hereK * pump
                scaleY = hereK * pump
                rotationZ = tilt
                translationX = shx.dp.toPx()
            }
            .tap { if (!here) onTap(i) }
            .semantics {
                contentDescription = title
                stateDescription = if (done) "ครบแล้ว" else if (here) "ส่วนที่กำลังกรอก" else ""
            },
        contentAlignment = Alignment.Center,
    ) {
        Box(Modifier.size(coin.dp), contentAlignment = Alignment.Center) {
            // วงรอบกว้างกว่าเหรียญ — ล็อกขนาดเหรียญไว้ ไม่ให้พื้นขยายตามวง
            Box(
                Modifier
                    .matchParentSize()
                    .background(face, CircleShape)
                    .then(if (!done && !here) Modifier.border(1.5.dp, PK.line, CircleShape) else Modifier),
            )
            PIcon(
                icon, size = 15f,
                weight = if (done || here) PhWeight.bold else PhWeight.regular,
                tint = if (done) Color.White else if (here) PK.ink else PK.ink.opacity(0.36),
            )
            if (here) {
                // วงรอบบอก "ส่วนนี้กรอกไปเท่าไหร่" — ปิดวงเมื่อครบ
                Canvas(Modifier.requiredSize((coin + 8f).dp)) {
                    val sw = 2.5.dp.toPx()
                    val inset = sw / 2
                    val arcSize = Size(size.width - sw, size.height - sw)
                    drawCircle(PK.ink.opacity(0.08), radius = (size.minDimension - sw) / 2, style = Stroke(sw))
                    drawArc(
                        color = PK.charcoal,
                        startAngle = -90f,
                        sweepAngle = 360f * max(0.06f, min(1f, f)),
                        useCenter = false,
                        topLeft = Offset(inset, inset),
                        size = arcSize,
                        style = Stroke(sw, cap = StrokeCap.Round),
                    )
                }
            }
            // เขียว = ครบ ความหมายเดียวกับจุดเขียวบน hub
            Box(
                Modifier
                    .align(Alignment.BottomEnd)
                    .offset(x = (if (here) 6f else 3f).dp, y = (if (here) 6f else 3f).dp)
                    .size(14.dp)
                    .graphicsLayer {
                        scaleX = doneK
                        scaleY = doneK
                        alpha = if (done) doneK.coerceIn(0f, 1f) else 0f
                    }
                    .background(PK.ok, CircleShape)
                    .border(1.5.dp, Color.White, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                PIcon(Ph.check, size = 7.5f, weight = PhWeight.bold, tint = Color.White)
            }
        }
    }
}

// MARK: - จัดชิปหลายบรรทัด

/** เรียงของหลายชิ้นซ้ายไปขวา ล้นแล้วขึ้นบรรทัดใหม่ — ใช้กับกลุ่มชิป (= `PKWrap: Layout`) */
@Composable
fun PKWrap(spacing: Float = 8f, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Layout(content = content, modifier = modifier) { measurables, constraints ->
        val gap = spacing.dp.roundToPx()
        val width = if (constraints.hasBoundedWidth) constraints.maxWidth else Constraints.Infinity
        val placeables = measurables.map { it.measure(Constraints(maxWidth = width)) }
        var x = 0
        var y = 0
        var rowH = 0
        val spots = ArrayList<IntOffset>(placeables.size)
        for (p in placeables) {
            if (x > 0 && x + p.width > width) {
                x = 0
                y += rowH + gap
                rowH = 0
            }
            spots.add(IntOffset(x, y))
            x += p.width + gap
            rowH = max(rowH, p.height)
        }
        val w = if (width == Constraints.Infinity) max(0, x - gap) else width
        val h = y + rowH
        layout(w.coerceIn(constraints.minWidth, constraints.maxWidth), h.coerceIn(constraints.minHeight, constraints.maxHeight)) {
            placeables.forEachIndexed { i, p -> p.placeRelative(spots[i].x, spots[i].y) }
        }
    }
}

// MARK: - ของเล่น Gen Z

/** อีโมจิลอยขึ้นลงช้า ๆ — สำเนาของ `.f3d` บนหน้าต้อนรับของเว็บ */
@Composable
fun PKFloatingEmoji(
    emoji: String,
    size: Float = 38f,
    duration: Double = 6.0,
    delay: Double = 0.0,
    tilt: Double = -8.0,
    modifier: Modifier = Modifier,
) {
    val tr = rememberInfiniteTransition(label = "floatingEmoji")
    val k by tr.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            tween((duration * 1000).toInt(), easing = CubicBezierEasing(0.42f, 0f, 0.58f, 1f)),
            RepeatMode.Reverse,
            initialStartOffset = StartOffset((delay * 1000).toInt()),
        ),
        label = "float",
    )
    val density = LocalDensity.current.density
    Text(
        emoji,
        style = systemFont(size).copy(
            shadow = TextShadow(Color.Black.opacity(0.08), Offset(0f, 6f * density), 6f * density),
        ),
        maxLines = 1,
        softWrap = false,
        modifier = modifier.graphicsLayer {
            rotationZ = (-tilt + (tilt * 2) * k).toFloat()
            translationY = (9f - 18f * k).dp.toPx()
        },
    )
}

// MARK: - สีประจำส่วน

/** พาสเทลของช่องนี้บน quest board — จำได้ด้วยสีก่อนอ่านชื่อ */
val ProfileSection.tint: Color get() = when (this) {
    ProfileSection.channels -> PK.lavender
    ProfileSection.interests -> PK.mint
    ProfileSection.payment -> PK.lemon
    ProfileSection.terms -> PK.aqua
    ProfileSection.person -> PK.peach
    ProfileSection.consent -> PK.sand
}

/** อีโมจิ = `emo` ของฟอร์มเว็บ */
val ProfileSection.emoji: String get() = when (this) {
    ProfileSection.channels -> "📱"
    ProfileSection.interests -> "✨"
    ProfileSection.payment -> "💸"
    ProfileSection.terms -> "🗓️"
    ProfileSection.person -> "🙌"
    ProfileSection.consent -> "🔒"
}

/** วงแหวนความคืบหน้า — ตัวเลขตรงกลาง · ครบแล้วเป็นติ๊ก (หมึกล้วน — เขียวสงวนไว้ให้ป้าย "ครบแล้ว") */
@Composable
fun PKRing(done: Int, total: Int, size: Float = 64f, modifier: Modifier = Modifier) {
    val frac = if (total == 0) 0f else done.toFloat() / total.toFloat()
    val complete = done >= total && total > 0
    val shown by animateFloatAsState(frac, Motion.settle.float, label = "ring")
    Box(modifier.size(size.dp), contentAlignment = Alignment.Center) {
        Canvas(Modifier.matchParentSize()) {
            val sw = 6.dp.toPx()
            val arc = Size(this.size.width - sw, this.size.height - sw)
            drawCircle(PK.ink.opacity(0.08), radius = (this.size.minDimension - sw) / 2, style = Stroke(sw))
            drawArc(
                PK.ink, startAngle = -90f, sweepAngle = 360f * shown, useCenter = false,
                topLeft = Offset(sw / 2, sw / 2), size = arc, style = Stroke(sw, cap = StrokeCap.Round),
            )
        }
        if (complete) PIcon(Ph.check, size = size * 0.34f, tint = PK.ink)
        else Text("$done/$total", style = sh(size * 0.24f, SHFont.black), color = PK.ink)
    }
}

// MARK: - พื้นบัตร STAR

/**
 * พื้นบัตร STAR — เหลืองเนยโฮโลแบบ Y2K + **ดาวดวงโต** ไหลพ้นขอบขวา + ประกายเล็ก ๆ
 * พื้นหลังต้องบอกเองว่า "นี่คือ STAR" ด้วยดาว ไม่ใช่โลโก้ (ผู้ใช้ 19 ก.ย.: เอาแค่ไอคอนดาว)
 * Android ไม่มี MeshGradient — ไล่สีทีละแถบแนวนอนจากตาราง 3×3 เดียวกัน
 */
@Composable
fun PKWarmMesh(modifier: Modifier = Modifier) {
    val star = painterResource(Ph.star.fill)
    val sparkle = painterResource(Ph.sparkle.fill)
    Box(modifier.fillMaxSize()) {
        Canvas(Modifier.matchParentSize()) { drawWarmMesh() }
        // เงาดาว — ส้มจางฟุ้ง
        Canvas(Modifier.matchParentSize().blur(14.dp, BlurredEdgeTreatment.Unbounded)) {
            val h = size.height * 1.15f
            starFrame(h, dy = 6.dp.toPx()) {
                with(star) { draw(Size(h, h), colorFilter = ColorFilter.tint(rgb(1.0, 0.62, 0.10).opacity(0.35))) }
            }
        }
        // แสงเรืองรอบประกาย
        Canvas(Modifier.matchParentSize().blur(3.dp, BlurredEdgeTreatment.Unbounded)) {
            sparkles { s -> with(sparkle) { draw(Size(s, s), colorFilter = ColorFilter.tint(rgb(1.0, 0.70, 0.20).opacity(0.7))) } }
        }
        Canvas(Modifier.matchParentSize()) {
            val h = size.height * 1.15f
            starFrame(h, dy = 0f) {
                // ดาวดวงโต — เนยไล่ส้ม มีแสงขาวด้านบนให้ดูมันวาวเหมือนสติกเกอร์
                gradientPainter(star, h, Brush.linearGradient(listOf(rgb(1.0, 0.88, 0.30), rgb(1.0, 0.66, 0.20)), start = Offset.Zero, end = Offset(h, h)))
                gradientPainter(star, h, Brush.verticalGradient(listOf(Color.White.opacity(0.55), Color.White.opacity(0.0)), startY = 0f, endY = h / 2))
            }
            sparkles { s -> with(sparkle) { draw(Size(s, s), colorFilter = ColorFilter.tint(Color.White)) } }
        }
    }
}

private val meshColors: List<List<Color>> = listOf(
    listOf(rgb(1.00, 0.91, 0.55), rgb(1.00, 0.95, 0.68), rgb(1.00, 0.88, 0.70)),
    listOf(rgb(0.97, 0.98, 0.72), rgb(1.00, 0.97, 0.80), rgb(1.00, 0.90, 0.62)),
    listOf(rgb(1.00, 0.96, 0.84), rgb(1.00, 0.93, 0.66), rgb(1.00, 0.84, 0.58)),
)
/** แถวกลางของแต่ละคอลัมน์ — จุดกลางของตารางเลื่อนขึ้นไป 0.45 เหมือนต้นฉบับ */
private val meshMid = floatArrayOf(0.5f, 0.45f, 0.5f)

private fun DrawScope.drawWarmMesh() {
    val strips = 40
    for (s in 0 until strips) {
        val y0 = size.height * s / strips
        val y1 = size.height * (s + 1) / strips
        val t = (s + 0.5f) / strips
        val cols = (0..2).map { c ->
            val mid = meshMid[c]
            if (t <= mid) lerp(meshColors[0][c], meshColors[1][c], t / mid)
            else lerp(meshColors[1][c], meshColors[2][c], (t - mid) / (1f - mid))
        }
        drawRect(
            brush = Brush.horizontalGradient(cols, startX = 0f, endX = size.width),
            topLeft = Offset(0f, y0),
            size = Size(size.width, y1 - y0 + 1f),
        )
    }
}

/** กรอบของดาวดวงโต — จุดกลางอยู่ที่ (กว้าง − h·0.36, สูง·0.58) หมุน 14° */
private inline fun DrawScope.starFrame(h: Float, dy: Float, block: DrawScope.() -> Unit) {
    val cx = size.width - h * 0.36f
    val cy = size.height * 0.58f + dy
    rotate(14f, pivot = Offset(cx, cy)) {
        translate(cx - h / 2, cy - h / 2) { block() }
    }
}

private inline fun DrawScope.sparkles(item: DrawScope.(Float) -> Unit) {
    val spots = listOf(Triple(0.56f, 0.22f, 14f), Triple(0.66f, 0.80f, 9f), Triple(0.52f, 0.62f, 7f))
    for ((fx, fy, pt) in spots) {
        val s = pt.dp.toPx()
        translate(size.width * fx - s / 2, size.height * fy - s / 2) { item(s) }
    }
}

/** วาดไอคอนแล้วระบายด้วยไล่สี (= `.foregroundStyle(LinearGradient)`) */
private fun DrawScope.gradientPainter(painter: Painter, side: Float, brush: Brush) {
    val canvas = drawContext.canvas
    canvas.saveLayer(Rect(0f, 0f, side, side), Paint())
    with(painter) { draw(Size(side, side), colorFilter = ColorFilter.tint(Color.White)) }
    drawRect(brush, size = Size(side, side), blendMode = BlendMode.SrcIn)
    canvas.restore()
}
