@file:OptIn(ExperimentalLayoutApi::class)

package co.salehere.starcard.ui

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.VectorConverter
import androidx.compose.animation.core.animate
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.animateOffsetAsState
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.displayCutout
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imeAnimationTarget
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.union
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.BlurredEdgeTreatment
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusManager
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChange
import androidx.compose.ui.input.pointer.util.VelocityTracker
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.platform.SoftwareKeyboardController
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import androidx.core.view.WindowCompat
import co.salehere.starcard.AppContext
import co.salehere.starcard.components.GlassPanel
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.PageScrub
import co.salehere.starcard.components.SpringToken
import co.salehere.starcard.components.float
import co.salehere.starcard.components.pageChoreo
import co.salehere.starcard.components.pressTilt
import co.salehere.starcard.layout.PageLayout
import co.salehere.starcard.layout.Placed
import co.salehere.starcard.model.BackgroundPickButton
import co.salehere.starcard.model.CardFormat
import co.salehere.starcard.model.CardLibrary
import co.salehere.starcard.model.LabSync
import co.salehere.starcard.model.CardPage
import co.salehere.starcard.model.CardStore
import co.salehere.starcard.model.EditHistory
import co.salehere.starcard.model.LocalClipInvocation
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.PhotoFitCatcher
import co.salehere.starcard.model.PhotoFitSurface
import co.salehere.starcard.model.PhotoSlotButton
import co.salehere.starcard.model.PhotoSlotRef
import co.salehere.starcard.model.PhotoStore
import co.salehere.starcard.model.PlatePattern
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.StarFlow
import co.salehere.starcard.model.StarTopic
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.model.WidgetInstance
import co.salehere.starcard.model.WidgetKind
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.model.entranceStyle
import co.salehere.starcard.theme.BackdropDiamonds
import co.salehere.starcard.theme.BackdropEffect
import co.salehere.starcard.theme.BackdropGrid
import co.salehere.starcard.theme.BackdropStripes
import co.salehere.starcard.theme.BackdropStyle
import co.salehere.starcard.theme.CardBackdrop
import co.salehere.starcard.theme.CardInk
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.ColorDuo
import co.salehere.starcard.theme.HSB
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.MarbleVeins
import co.salehere.starcard.theme.Palette
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.SignatureEmboss
import co.salehere.starcard.theme.SignaturePattern
import co.salehere.starcard.theme.StarLockup
import co.salehere.starcard.theme.StripStyle
import co.salehere.starcard.theme.SymbolIcon
import co.salehere.starcard.theme.TextAlignment
import co.salehere.starcard.theme.TextFit
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.WidgetTextStyle
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.hsb
import co.salehere.starcard.theme.marbleInk
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.editor.CanvasTextField
import co.salehere.starcard.ui.editor.DockMainItem
import co.salehere.starcard.ui.editor.DockMode
import co.salehere.starcard.ui.editor.DockRow
import co.salehere.starcard.ui.editor.DockSegment
import co.salehere.starcard.ui.editor.DockSheet
import co.salehere.starcard.ui.editor.EditorDock
import co.salehere.starcard.ui.editor.LocalSlotRegistry
import co.salehere.starcard.ui.editor.PressDragCatcher
import co.salehere.starcard.ui.editor.SlotRegistry
import co.salehere.starcard.ui.editor.TextBlockWeight
import co.salehere.starcard.ui.editor.TextEditBar
import co.salehere.starcard.ui.editor.TextSlotDashes
import co.salehere.starcard.ui.editor.TextSlotRect
import co.salehere.starcard.ui.editor.TextTools
import co.salehere.starcard.ui.editor.WidgetGallery
import co.salehere.starcard.ui.editor.WidgetThumb
import co.salehere.starcard.ui.export.CardSharePreview
import co.salehere.starcard.ui.salehere.starflow.StarTopicFill
import co.salehere.starcard.ui.widgets.FlowLayout
import co.salehere.starcard.ui.widgets.TextBlockSpec
import co.salehere.starcard.ui.widgets.WidgetChrome
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.UUID
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

// MARK: - ห้องแต่งการ์ด (= Views/CardScreen.swift)
//
// การ์ดของตัวเองแต่งได้ตลอด — คลิปเท่านั้นที่ดูอย่างเดียว (`viewOnly`)
// หน้ากระดาษวาดใน **หน่วยออกแบบ** แล้วย่อทั้งผืนลงจอด้วย `graphicsLayer` · ทัชแปลงกลับด้วยสเกลเดียวกัน

/** ช่องว่างขั้นต่ำระหว่างการจัดผังใหม่สองครั้งระหว่างลาก (วินาที) — throttle ไม่ใช่ debounce */
private const val ReflowGap = 0.07

/** สีปุ่มของกล่องถามแบบ iOS */
private val AlertBlue = Color(0xFF0A84FF)

// MARK: - โหมดของแถบล่าง (S4 · `DockMode`) — ชื่อเคสอ้างที่นี่ที่เดียว

private val DockMain: DockMode get() = DockMode.Main
private val DockBackdrop: DockMode get() = DockMode.Backdrop
private val DockGallery: DockMode get() = DockMode.Gallery
private fun dockPiece(id: UUID): DockMode = DockMode.Piece(id)
private fun dockText(id: UUID): DockMode = DockMode.Text(id)

/** เลือกชิ้นอยู่ (ไม่ใช่โหมดพิมพ์) */
private val DockMode.isPiece: Boolean get() = selectedID != null && !isText

private fun sameDock(a: DockMode, b: DockMode): Boolean =
    if (a.selectedID != null || b.selectedID != null) a.selectedID == b.selectedID && a.isText == b.isText else a == b

private fun <T> segOpt(value: T, title: String): DockSegment.Option<T> = DockSegment.Option(value = value, title = title)

/**
 * ห้องแต่งการ์ด — หรือหน้าดูของคลิป (`viewOnly`)
 * - viewOnly: คลิปเปิดมาดูอย่างเดียว — ห้ามเข้าโหมดแต่ง / ตู้ widget / ลากวาง
 * - cardID: ใบในคลังที่ห้องนี้กำลังแก้ — งานทุกจังหวะบันทึกกลับใบนี้ · null = คลิปเปิดดูอย่างเดียว
 * - discardIfUntouched: การ์ดเพิ่งเกิดจากการแตะเทมเพลต — ออกโดยไม่เคยแตะแก้อะไรเลย = ทิ้งใบนี้
 * - format: รูปแบบการ์ด — ใช้เมื่อไม่ได้เปิดจากคลัง (ใบในคลังมีรูปแบบของมันเอง) · ห้ามเปลี่ยนระหว่างทาง
 * - onChangeFormat: ทางกลับไปคลังการ์ด — null = ไม่มีทางกลับ (คลิป)
 * - onClose: ปิดหน้าดู — มีเฉพาะตอนเปิดจากคลังเพื่อ "ดูแบบที่แบรนด์เห็น"
 */
@Composable
fun CardScreen(
    viewOnly: Boolean = false,
    cardID: String? = null,
    discardIfUntouched: Boolean = false,
    format: CardFormat = CardFormat.portfolio,
    onChangeFormat: (() -> Unit)? = null,
    onClose: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val state = remember {
        // เปิดจากคลัง = โหลดใบนั้นทั้งดุ้นตั้งแต่แรก — ไม่มีจังหวะที่หน้าตั้งต้นแวบขึ้นก่อน
        val record = cardID?.let { CardLibrary.shared.card(it) }
        val restored = record?.let { CardStore.restore(it.snapshot) }
        if (record != null && restored != null) {
            CardEditorState(
                viewOnly, cardID, discardIfUntouched, record.format,
                restored.pages, restored.theme, restored.index.coerceIn(0, max(0, restored.pages.size - 1)),
            )
        } else {
            CardEditorState(viewOnly, cardID, discardIfUntouched, format, format.starterPages, CardTheme(), 0)
        }
    }
    state.scope = rememberCoroutineScope()
    state.context = LocalContext.current
    state.photos = LocalPhotoStore.current
    state.measurer = TextFit.rememberMeasurer()
    state.keyboardController = LocalSoftwareKeyboardController.current
    state.focusManager = LocalFocusManager.current
    state.density = LocalDensity.current.density
    state.onChangeFormat = onChangeFormat
    state.onClose = onClose
    // โหมดลองทำ: อีกเครื่องแก้การ์ดใบนี้ → โหลดผังใหม่จากคลัง (= `.onChange(of: LabSync.shared.remoteStamp)`)
    val labStamp = LabSync.shared.remoteStamp
    LaunchedEffect(labStamp) { state.labStampChanged(labStamp) }
    val invocation = LocalClipInvocation.current
    val openRef = remember(state) { { url: String -> state.open(url) } }
    val backOn by remember(state) { derivedStateOf { state.backEnabled() } }

    // สิ่งที่อยู่หลังแถบสถานะคือเวทีมืด ไม่ใช่หน้าการ์ด จึงตรึงเป็นมืดเสมอ
    LightStatusIcons()
    BackHandler(enabled = backOn) { state.systemBack() }

    CompositionLocalProvider(LocalOpenURL provides openRef) {
        // เวทีมืดของแบรนด์ — ลายน้ำจาง ๆ คือลายเซ็นของสถานที่ ไม่ใช่ของการ์ด
        Box(modifier.fillMaxSize().background(grey(0.06))) {
            SignaturePattern(opacity = if (viewOnly) 0.065 else 0.04, modifier = Modifier.fillMaxSize())
            // ปิดการหลบคีย์บอร์ดอัตโนมัติ — ก้อนที่พิมพ์อยู่ถูกพาขึ้นมาเองที่ `showroom`
            BoxWithConstraints(
                Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.systemBars.union(WindowInsets.displayCutout)),
            ) {
                state.Stage(maxWidth.value, maxHeight.value)
            }

            // ชีต "ติดต่อ" ของหน้าดู
            StageSheet(visible = state.showContact, height = 214f, onDismiss = { state.showContact = false }) {
                ContactSheet(onPick = { url -> state.contactPicked(url) })
            }
            StageSheet(visible = state.showVerify, height = VerifySheet.height, onDismiss = { state.showVerify = false }) {
                VerifySheet(slug = invocation.slug)
            }
            // พิมพ์ผิดแล้วดีดกลับไปสีจริง — ตรงกว่าการขึ้นข้อความเตือนที่ต้องอ่านแล้วแก้เอง
            StageAlert(
                visible = state.hexPrompt,
                title = "สีพื้น",
                message = "พิมพ์รหัสสีหกหลัก เช่น #F11717",
                actionTitle = "ใช้สีนี้",
                cancelTitle = "ยกเลิก",
                onAction = { state.applyHex() },
                onDismiss = { state.hexPrompt = false },
                field = { state.HexPromptField() },
            )
            StageAlert(
                visible = state.askJobs,
                title = "ใบนี้ปลดล็อกเมื่อทำงานกับ Sale Here",
                message = "โลโก้แบรนด์และผลงานยืนยันมาจากงานที่ทำจบผ่าน Sale Here เท่านั้น รับงานแรกแล้วใบพวกนี้จะเปิดเอง",
                actionTitle = "ดูงานที่เปิดรับ",
                cancelTitle = "ไว้ก่อน",
                onAction = { StarFlow.shared.jobsRequested = true },
                onDismiss = { state.askJobs = false },
            )
            // เบราว์เซอร์ในแอป — ตัวชีตส่งลิงก์ออกไปแล้วปิดตัวเองทันที จึงไม่ต้องมีหน้าเต็มจอรอง
            val link = state.link
            if (link != null) {
                key(state.linkSeq) {
                    SafariSheet(url = link.url, tint = state.theme.accent, onDismiss = { state.link = null })
                }
            }
            FullCover(visible = state.showPreview, onBack = { state.showPreview = false }) {
                CardSharePreview(
                    pages = state.pages, theme = state.theme, pageSize = state.pageSize, format = state.format,
                    onDismiss = { state.showPreview = false },
                )
            }
            val req = rememberLast(state.topicFill)
            FullCover(visible = state.topicFill != null, onBack = { state.topicFill = null }) {
                if (req != null) {
                    StarTopicFill(steps = listOf(req.topic.step), onDone = { done -> state.topicFilled(req, done) })
                }
            }
        }
    }
}

/** คำขอจากตู้ widget: ใบ `kind` ต้องการหัวข้อ `topic` ที่ยังว่าง */
data class TopicFillRequest(val kind: WidgetKind, val topic: StarTopic) {
    val id: String get() = kind.raw
}

// MARK: - ข้อความชั่วคราวเหนือขอบล่าง

/**
 * ข้อความที่แอปพูดกับผู้ใช้ — **สามชนิด ต่างกันที่ว่าใครเป็นคนปิด**
 * รายงานสถานะหายเอง · คำสั่งที่ถูกปฏิเสธต้องค้างจนผู้ใช้ได้อ่านแน่ ๆ · ของที่กู้คืนได้ถือปุ่มหนึ่งปุ่ม
 */
private data class CardNotice(
    val text: String,
    val kind: Kind,
    val actionTitle: String? = null,
    val action: (() -> Unit)? = null,
) {
    enum class Kind {
        /** รายงานสถานะ — หายเอง ไม่รับทัช */
        status,
        /** คำสั่งถูกปฏิเสธ — ค้างจนผู้ใช้กดปิด */
        warning,
        /** ทำไปแล้วแต่กู้คืนได้ — ถือปุ่มหนึ่งปุ่ม */
        offer,
    }
}

// MARK: - ของเล็ก ๆ ที่ห้องแต่งใช้

private data class PressPoint(val id: UUID, val at: Offset)
private data class EditBox(val points: Float, val box: Size, val m: TextFit.Metrics)
private data class Showroom(val scale: Float, val dx: Float, val dy: Float)
private enum class ToneChoice { dark, light }
private enum class GripAxis { horizontal, vertical }

/** ตำแหน่งวาดของ tile หนึ่งตัว — สปริงของผังเดินที่นี่ (ตำแหน่งอ่านตอนวาง ขนาดอ่านตอนประกอบ) */
private class TileAnim(frame: Rect) {
    val pos = Animatable(frame.topLeft, Offset.VectorConverter)
    val size = Animatable(frame.size, Size.VectorConverter)
    /** เป้าล่าสุดเป็นกล่องตอนพิมพ์ไหม — พิมพ์ต่อเนื่อง = กล่องตามตัวอักษรทันที ไม่ผ่านสปริง */
    var typing = false
}

/** มุมบนซ้ายของ tile ในพิกเซลของราก — ใช้แปลงจุดที่นิ้วแตะเป็นพิกัดหน้า */
private class TileOrigin {
    var root: Offset = Offset.Zero
}

/** กรอบเลือกตัวล่าสุด — ให้กรอบไหลจากชิ้นเดิมไปชิ้นใหม่ */
private class SelMemo {
    var id: UUID? = null
    var rect: Rect = Rect.Zero
}

/** พิกัดราก → พิกัดหน้า (หน่วยออกแบบ) */
private fun SlotRegistry.pageOf(root: Offset): Offset {
    val s = if (scale > 0f) scale else 1f
    return Offset((root.x - origin.x) / s, (root.y - origin.y) / s)
}

/** `.rounded()` ของ Swift — ครึ่งปัดออกจากศูนย์ */
private fun swiftRound(v: Float): Float = if (v >= 0f) floor(v + 0.5f) else -floor(-v + 0.5f)

private fun autoShrink(size: Float, min: Float): TextAutoSize =
    TextAutoSize.StepBased(minFontSize = (size * min).sp, maxFontSize = size.sp, stepSize = 0.5.sp)

/** ค่าล่าสุดที่ไม่ว่าง — ของที่กำลังจางออกยังต้องวาดค่าเดิมอยู่ */
@Composable
private fun <T : Any> rememberLast(value: T?): T? {
    val holder = remember { arrayOfNulls<Any>(1) }
    if (value != null) holder[0] = value
    @Suppress("UNCHECKED_CAST")
    return holder[0] as T?
}

/** `strokeBorder` ของ SwiftUI — เส้นอยู่ด้านในขอบ */
private fun DrawScope.strokeBorder(color: Color, width: Float, radius: Float, dash: FloatArray? = null) {
    val half = width / 2f
    drawRoundRect(
        color = color,
        topLeft = Offset(half, half),
        size = Size(size.width - width, size.height - width),
        cornerRadius = CornerRadius(max(0f, radius - half), max(0f, radius - half)),
        style = Stroke(width = width, pathEffect = dash?.let { PathEffect.dashPathEffect(it) }),
    )
}

/**
 * ขนาดจริงของกล่องที่ถูกหมุนไป `tilt` องศา — ย้อนจากกรอบตรงที่ครอบมุมทั้งสี่
 * แก้สมการกรอบครอบกลับ: W = w·cos + h·sin · H = w·sin + h·cos
 */
private fun upright(bound: Size, tilt: Double): Size {
    if (tilt == 0.0) return bound
    val t = abs(tilt) * PI / 180.0
    val c = cos(t)
    val s = sin(t)
    // cos 2θ — แผ่นที่แปะเอียงไม่มีทางถึง 45° ถ้าถึงก็คืนกรอบครอบไปตามเดิม
    val d = c * c - s * s
    if (d <= 0.1) return bound
    return Size(
        max(0.0, (bound.width * c - bound.height * s) / d).toFloat(),
        max(0.0, (bound.height * c - bound.width * s) / d).toFloat(),
    )
}

private fun Context.findActivity(): Activity? {
    var c: Context? = this
    while (c is ContextWrapper) {
        if (c is Activity) return c
        c = c.baseContext
    }
    return null
}

/** เปิดแอปเจ้าของลิงก์ก่อน (IG · TikTok · YouTube · LINE · FB) — ไม่มีแอปนั้นคืน false */
private fun openInOwnerApp(context: Context, url: String): Boolean {
    if (Build.VERSION.SDK_INT < 30) return false
    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
        addCategory(Intent.CATEGORY_BROWSABLE)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REQUIRE_NON_BROWSER
    }
    return try {
        context.startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    }
}

/** สคีมที่เบราว์เซอร์ในแอปเปิดไม่ได้ (tel · mailto · deep link) — ส่งให้ระบบ */
private fun systemOpenURL(context: Context, url: String) {
    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    try {
        context.startActivity(intent)
    } catch (_: ActivityNotFoundException) {
    } catch (_: SecurityException) {
    }
}

/** แถบสถานะตัวสว่างบนเวทีมืด (= `.preferredColorScheme(.dark)`) */
@Composable
private fun LightStatusIcons() {
    val view = LocalView.current
    DisposableEffect(view) {
        val window = view.context.findActivity()?.window
        val ctl = window?.let { WindowCompat.getInsetsController(it, view) }
        val before = ctl?.isAppearanceLightStatusBars
        ctl?.isAppearanceLightStatusBars = false
        onDispose { if (ctl != null && before != null) ctl.isAppearanceLightStatusBars = before }
    }
}

// MARK: - สถานะของห้องแต่ง

private class CardEditorState(
    val viewOnly: Boolean,
    val cardID: String?,
    val discardIfUntouched: Boolean,
    /** รูปแบบการ์ด — ทุกอย่างที่ผูกกับ "กี่หน้า" อ่านค่าจากตัวนี้ที่เดียว */
    val format: CardFormat,
    initialPages: List<CardPage>,
    initialTheme: CardTheme,
    initialIndex: Int,
) {
    // สิ่งแวดล้อมที่ใช้นอกรอบวาด — ใส่ใหม่ทุกรอบประกอบ
    lateinit var scope: CoroutineScope
    lateinit var context: Context
    lateinit var measurer: TextMeasurer
    var photos: PhotoStore? = null
    var keyboardController: SoftwareKeyboardController? = null
    var focusManager: FocusManager? = null
    var density: Float = 1f
    var onChangeFormat: (() -> Unit)? = null
    var onClose: (() -> Unit)? = null

    /** การ์ดของตัวเองแต่งได้ตลอด — ไม่มีโหมด "ดู" แยก (คลิปเท่านั้นที่ดูอย่างเดียว) */
    val isEditing: Boolean get() = !viewOnly

    /** พิธีเปิดของหน้าดู — การ์ดถูก "แจก" ลงบนเวที แล้วแถบผู้ออกบัตรปรากฏเป็นอย่างสุดท้าย */
    var dealt by mutableStateOf(false)
    var stripIn by mutableStateOf(false)
    /** ผู้ใช้แตะต้องใบนี้แล้วหรือยัง — ผัง/ธีมขยับ นับหมด (แค่ปัดดูหน้าไม่นับ) */
    var touched = false

    var pages by mutableStateOf(initialPages)
    var theme by mutableStateOf(initialTheme)

    /** แถบล่างอยู่ที่ไหน — ค่าเดียวที่บอกว่าตอนนี้กำลังทำอะไรอยู่ */
    var dock by mutableStateOf(DockMain)
    /** ความสูงของของที่อยู่ขอบล่าง (แถบ + ถาด) — วัดจากของจริง */
    var bottomUI by mutableFloatStateOf(0f)
    /** ความสูงของสองแถวเหนือแป้นพิมพ์ตอนพิมพ์ */
    var toolsH by mutableFloatStateOf(118f)
    /** ประวัติแก้ไขสำหรับ ↶ ↷ — ทุกตัวเลือกมีผลทันที นี่คือทางกลับทางเดียว */
    val history = EditHistory()
    /** ภาพนิ่งที่เพิ่งกู้คืนจากประวัติ — ห้ามบันทึกมันซ้ำเป็นจังหวะใหม่ */
    var applied: EditHistory.Snapshot? = null
    /** สีพื้นที่ผู้ใช้เคยตั้งเองล่าสุด — แตะสีสำเร็จรูปดูเล่นแล้วต้องกลับมาสีนี้ได้ */
    var myColor by mutableStateOf<HSB?>(null)
    /** จังหวะ "เปิดไฟ" ตอนเพิ่งเข้าโหมดแต่ง — กรอบประทุกชิ้นเข้มขึ้นชั่วครู่แล้วค่อยจางลง */
    var editReveal by mutableStateOf(false)
    var revealJob: Job? = null

    /** ตัวเลือกสีพื้นกางอยู่ไหม */
    var colorOpen by mutableStateOf(false)
    /** สิ่งที่กำลังพิมพ์ในช่อง hex — แยกจากธีมเพราะระหว่างพิมพ์ค่ายังอ่านไม่ออก */
    var hexDraft by mutableStateOf("")
    var hexPrompt by mutableStateOf(false)

    /** หน้าที่กำลังดูอยู่ */
    var index by mutableIntStateOf(initialIndex)
    /** ความคืบหน้าของการปัด -1…1 (ค่าโมเดล — ตัววาดคือ `deckPos`) */
    var swipe by mutableFloatStateOf(0f)
    /** การปัดครั้งนี้เป็นแนวนอนจริง — ตัดสินตอนนิ้วขยับ */
    var swipeArmed = false
    /** ตำแหน่งแผ่นในหน่วยช่อง = index + เศษของการปัด */
    val deckPos = Animatable(initialIndex.toFloat())

    /** ผังที่แคชไว้ของหน้าปัจจุบัน — ห้าม solve ใหม่ทุก touch event */
    var placed by mutableStateOf<List<Placed>>(emptyList())
    /** `placed` เป็นผังของหน้าไหน */
    var placedPage by mutableStateOf<UUID?>(null)
    /** สปริงของการจัดผังรอบล่าสุด — null = กระโดดเข้าที่ */
    var layoutSpring: SpringToken? = null
    /** ขนาดหน้าใน **หน่วยออกแบบ** */
    var pageSize by mutableStateOf(Size.Zero)
    /** อัตราย่อจากหน่วยออกแบบลงหน่วยจอ */
    var pageFit by mutableFloatStateOf(1f)
    var viewportW by mutableFloatStateOf(402f)
    var viewportH by mutableFloatStateOf(874f)
    var safeBottom by mutableFloatStateOf(0f)
    /** ความสูงปลายทางของคีย์บอร์ด (วัดจากก้นหน้าต่าง) */
    var keyboard by mutableFloatStateOf(0f)

    /** ข้อความบอกเหตุชั่วคราว */
    var notice by mutableStateOf<CardNotice?>(null)
    var noticeJob: Job? = null

    // การลาก
    var dragID by mutableStateOf<UUID?>(null)
    var dragStart by mutableStateOf(Rect.Zero)
    var dragTranslation by mutableStateOf(Offset.Zero)
    /** ตัวจับเวลาตอนลากค้างที่ขอบหน้า */
    var edgeFlip: Job? = null
    /** ช่องที่นิ้วชี้อยู่ตอนนี้ — ตัวขับ "ของอื่นหลบระหว่างที่นิ้วยังอยู่" */
    var dragOrigin by mutableStateOf<Offset?>(null)
    /** ความกว้างที่ถูกย่อให้พอดีช่องว่างตรงที่นิ้วชี้ — null = ใช้ความกว้างเดิม */
    var dragWidth by mutableStateOf<Float?>(null)
    var reflow: Job? = null
    var lastReflow = 0.0
    /** ตำแหน่งนิ้วภายใน widget ตอนเริ่มลาก */
    var dragGripX = 0f
    /** สำเนา widget ที่กำลังลาก — วาดชั้นลอยที่ระดับ deck ให้อยู่รอดข้ามการสลับหน้า */
    var dragItem by mutableStateOf<WidgetInstance?>(null)
    var dragOriginPage = 0
    var lifted by mutableStateOf(false)
    /** ความหมายของท่ากดค้างที่กำลังทำอยู่ — ล็อกไว้จนปล่อยนิ้ว */
    var pressMode: UUID? = null
    /** จุดที่นิ้วแตะบน widget ตัวที่กำลังกด — ขับการเอียง 3 มิติ */
    var pressPoint by mutableStateOf<PressPoint?>(null)

    var showPreview by mutableStateOf(false)
    var topicFill by mutableStateOf<TopicFillRequest?>(null)
    var askJobs by mutableStateOf(false)

    /** ทะเบียนกรอบของแต่ละหน้า — ไม่ใช่ state เพราะถูกเขียนทุกครั้งที่ผังขยับแต่อ่านเฉพาะตอนนิ้วแตะ */
    val registries = HashMap<UUID, SlotRegistry>()
    val tileAnims = HashMap<Pair<UUID, UUID>, TileAnim>()
    /** ลิงก์ที่กำลังเปิดอยู่ในเบราว์เซอร์ในแอป */
    var link by mutableStateOf<LinkTarget?>(null)
    var linkSeq by mutableIntStateOf(0)
    var showContact by mutableStateOf(false)
    var showVerify by mutableStateOf(false)

    // การปรับขนาด
    var resizeID by mutableStateOf<UUID?>(null)
    /** ระยะที่ลากเลยขีดจำกัดไปแล้ว — ขยับแค่กรอบ ไม่ขยับตัว widget */
    var overshoot by mutableStateOf(Offset.Zero)
    var overshootJob: Job? = null
    var resizeW = 0f
    var resizeH = 0f
    /** สเกลของชิ้นในโชว์รูม ณ วินาทีที่เริ่มลากหมุด — จับไว้ตอนเริ่ม ไม่อ่านสด */
    var resizeScale = 1f
    /** ขนาดตัวอักษรตอนเริ่มลากหมุดมุมของก้อนข้อความ */
    var resizePoints = 0f
    /** ข้ามการบันทึกประวัติ */
    var skipHistory = false
    /** ผ่านเฟรมแรกแล้ว — ของที่เกิดทีหลังจางเข้า */
    var booted = false

    // MARK: ค่าที่คิดจากสถานะ

    val selected: UUID? get() = dock.selectedID
    val multiPage: Boolean get() = pages.size > 1
    val current: CardPage? get() = pages.getOrNull(index)
    val selectedItem: WidgetInstance?
        get() {
            val id = selected ?: return null
            for (pg in pages) for (it in pg.items) if (it.id == id) return it
            return null
        }

    fun isTyping(id: UUID): Boolean = dock.isText && dock.selectedID == id

    fun registry(page: UUID): SlotRegistry = registries.getOrPut(page) { SlotRegistry() }

    fun tileAnim(page: UUID, p: Placed, drawn: Size): TileAnim =
        tileAnims.getOrPut(page to p.id) { TileAnim(Rect(p.frame.topLeft, drawn)) }

    /**
     * การ์ดไม่เหลือที่แม้แต่ของชิ้นเล็กที่สุดแล้วหรือยัง
     * วัดด้วย `PageLayout.minSize` — ตอบว่า "เต็ม" ได้ต่อเมื่อไม่มีอะไรลงได้เลยจริง ๆ
     */
    fun cardIsFull(): Boolean {
        if (pages.size < format.pageCount || pageSize == Size.Zero) return false
        return pages.none { pg -> PageLayout.freeSpot(PageLayout.minSize, pageSize, pg.items) != null }
    }

    /** ที่ว่างใต้แถบบนสำหรับแถบ Verified ของหน้าดู — มีเฉพาะการ์ดที่ได้ตราแล้ว */
    val verifyBandSpace: Float
        get() = if (viewOnly && VerifiedFacts.current.verified) VerifiedBand.height + 8f else 0f

    /** ความสูงของสิ่งที่บังจอด้านล่างอยู่ตอนนี้ — แถบ+ถาด **หรือ** แผ่นพิมพ์+คีย์บอร์ด */
    val bottomCover: Float
        get() {
            if (!isEditing) return 0f
            // ตอนพิมพ์คิดจาก **ความสูงปลายทาง** ของแป้นพิมพ์ ไม่ใช่ค่าที่วัดสด
            if (dock.isText) return max(0f, keyboard - safeBottom) + toolsH + 8f
            return bottomUI
        }

    /**
     * สเกลของการ์ด — ย่อเท่าที่จำเป็นให้ทั้งหน้าอยู่เหนือของที่บังอยู่ข้างล่าง
     * **ย่ออย่างเดียว ไม่ดัน** — ยึดหัวการ์ดไว้กับที่เสมอ
     */
    val editScale: Float
        get() {
            // โชว์รูมโชว์ชิ้นเดียว จึงไม่ต้องย่อทั้งหน้าให้พอดีช่องว่าง
            if (showroomID != null) return 1f
            val visible = viewportH - bottomCover - 74f - 8f
            val fit = visible / max(pageSize.height * pageFit, 1f)
            // แผ่นหลายช่องบนแถบหลักย่อไว้ไม่เกิน 0.9 — ขอบของช่องข้าง ๆ จะได้โผล่ทั้งสองข้าง
            val cap = if (multiPage && dock.isMain) 0.9f else 1f
            return min(cap, max(if (selected == null) 0.48f else 0.62f, fit))
        }

    /** สเกลรวมจากหน่วยออกแบบถึงหน่วยจอ — ย่อให้พอดีจอ **คูณ** ย่อเพื่อหลบชีตตอนแต่ง */
    val canvasScale: Float get() = (if (isEditing) editScale else viewScale) * pageFit

    /** หน้าดู: ย่อการ์ดลงพอให้ท้ายหน้าไม่ทับขอบล่างของการ์ด */
    val viewScale: Float
        get() {
            if (!viewOnly) return 1f
            val shown = pageSize.height * pageFit
            return max(0.6f, 1f - (52f + verifyBandSpace) / max(shown, 1f))
        }

    /** โหมดโชว์รูม — **เฉพาะตอนพิมพ์ก้อนข้อความ** ก้อนที่พิมพ์อยู่มายืนกลางที่ว่างเหนือคีย์บอร์ด */
    val showroomID: UUID? get() = if (dragID == null && dock.isText) dock.selectedID else null

    /** ท่าที่พา widget ตัวที่กำลังแต่งไปยืนกลางช่องว่างเหนือชีต — คิดในพิกัดหน้ากระดาษ */
    fun showroom(p: Placed): Showroom {
        if (showroomID != p.id) return Showroom(1f, 0f, 0f)
        val s = max(canvasScale, 0.01f)
        val band = max(140f, (viewportH - bottomCover - 74f - 16f) / s)
        // **ไม่ใช้ scale** — ตอนพิมพ์กล่องถูกวาดที่ขนาดแก้ไขตรง ๆ ตัวอักษรจึงคม
        val d = drawnSize(p)
        return Showroom(1f, pageSize.width / 2f - (p.frame.left + d.width / 2f), band / 2f - (p.frame.top + d.height / 2f))
    }

    /** ตัวที่กำลังแต่งขยายขึ้น · ตัวอื่นถอยลงเล็กน้อย */
    fun showroomScale(p: Placed): Float {
        val id = showroomID ?: return 1f
        return if (id == p.id) showroom(p).scale else 0.92f
    }

    /** ชิ้นอื่นตอนพิมพ์ — หรี่แค่พอให้ยังเห็นว่าก้อนจะกลับไปลงตรงไหน */
    fun showroomDim(p: Placed): Double {
        val id = showroomID ?: return 1.0
        return if (id == p.id) 1.0 else 0.6
    }

    /** ขนาดที่วาดจริงของ tile — ก้อนข้อความที่กำลังพิมพ์ใช้กล่องขนาดแก้ไข */
    fun drawnSize(p: Placed): Size = if (isTyping(p.id)) editBox(p).box else p.frame.size

    /**
     * กล่องตอนพิมพ์ — ตัวอักษรที่ **ขนาดแก้ไขมาตรฐานเดียวกันทุกก้อน** (`TextFit.editSize`)
     * ขนาดที่ตั้งไว้ (`points`) มีผลบนการ์ดเท่านั้น กด เสร็จ แล้วค่อยกลับไปขนาดนั้น
     */
    fun editBox(p: Placed): EditBox {
        val st = p.item.textStyle
        val raw = Profile.me.note(p.item.id)
        val text = if (raw.isEmpty() || raw == Profile.notePlaceholder) "พิมพ์ข้อความ" else raw
        val inset = TextBlockSpec.inset
        val maxW = PageLayout.content(pageSize).width - inset * 2f
        val pts = TextFit.capped(measurer, TextFit.editSize, text, st.face, TextBlockWeight, maxW)
        val m = TextFit.metrics(measurer, text, st.face, TextBlockWeight, pts, st.align)
        return EditBox(pts, Size(min(m.ink.width, maxW) + inset * 2f, m.ink.height + inset * 2f), m)
    }

    /** มุมของกรอบชิ้น — ก้อนข้อความมุมเล็ก */
    fun chromeRadius(kind: WidgetKind): Float =
        if (kind == WidgetKind.textBlock) min(theme.radius, TextBlockSpec.radius) else theme.radius

    // MARK: ทางเข้าเดียวของการเปลี่ยนสถานะ (= `onChange` ของ Swift)

    /** แก้หน้า — บันทึกประวัติ · เขียนกลับคลัง · จัดผังใหม่ · คืน false เมื่อไม่มีอะไรเปลี่ยน */
    fun setPages(new: List<CardPage>): Boolean {
        val old = pages
        if (new == old) return false
        pages = new
        touched = true
        rememberEdit(old, theme, changedPages = new)
        persist()
        // ระหว่างยืดขนาด ใช้สปริงที่ตอบไว — Motion.flow นุ่มเกินไป ขอบจะรั้งอยู่หลังนิ้ว
        resolve(if (resizeID == null) Motion.flow else Motion.snap)
        return true
    }

    @JvmName("updateTheme") fun setTheme(new: CardTheme) {
        val old = theme
        if (new == old) return
        theme = new
        touched = true
        rememberEdit(pages, old, changedTheme = new)
        persist()
    }

    @JvmName("updateDock") fun setDock(d: DockMode) {
        if (sameDock(dock, d)) return
        dock = d
        // ทางออกของการยืดที่ไม่ได้มาจากการปล่อยนิ้ว
        endResize()
        // กติกาเหล็ก: **ช่องพิมพ์มีอยู่ได้เฉพาะตอนมีชิ้นที่เลือกอยู่**
        if (d.selectedID == null) endTextEdit()
    }

    /** เปลี่ยนหน้า — แผ่นเลื่อนด้วย `spring` (null = กระโดด) */
    fun setIndex(i: Int, spring: SpringToken?) {
        val changed = i != index
        index = i
        deckTo(i.toFloat(), spring)
        if (!changed) return
        // เปลี่ยนหน้าเพราะลาก widget ข้ามหน้า — ตัวที่ลากยังต้องถูกเลือกอยู่
        if (dragID == null) {
            if (dock.isText) exitTextMode() else if (dock.isPiece) setDock(DockMain)
        }
        resolve(null)
        persist()
    }

    fun deckTo(target: Float, spring: SpringToken?) {
        scope.launch {
            if (spring == null) deckPos.snapTo(target) else deckPos.animateTo(target, spring.spec())
        }
    }

    // MARK: ประวัติ ↶ ↷

    fun snapshotNow(): EditHistory.Snapshot = EditHistory.Snapshot(pages, theme)

    /** บันทึกจังหวะแก้ไขลงประวัติ — ข้ามค่าที่เพิ่งกู้คืนมาเอง */
    private fun rememberEdit(
        pages: List<CardPage>,
        theme: CardTheme,
        changedPages: List<CardPage>? = null,
        changedTheme: CardTheme? = null,
    ) {
        // ระหว่างพิมพ์กล่องขยับทุกตัวอักษร — ทั้งรอบนับเป็นจังหวะเดียว (บันทึกไว้แล้วที่ `enterTextMode`)
        if (dock.isText || skipHistory) return
        applied?.let { a ->
            if (changedPages != null && changedPages == a.pages) return
            if (changedTheme != null && changedTheme == a.theme) return
        }
        history.record(EditHistory.Snapshot(pages, theme))
    }

    fun undo() {
        val s = history.undo(snapshotNow())
        if (s == null) {
            Haptics.rigid(); return
        }
        applySnapshot(s)
    }

    fun redo() {
        val s = history.redo(snapshotNow())
        if (s == null) {
            Haptics.rigid(); return
        }
        applySnapshot(s)
    }

    /** กู้คืนภาพนิ่ง — ของบนการ์ดไหลกลับด้วย `flow` ผู้ใช้จึงเห็นว่าอะไรเปลี่ยน */
    private fun applySnapshot(s: EditHistory.Snapshot) {
        applied = s
        endTextEdit()
        setPages(s.pages)
        setTheme(s.theme)
        setIndex(min(index, max(0, s.pages.size - 1)), Motion.flow)
        // ชิ้นที่เลือกอยู่อาจไม่มีในภาพนิ่งนั้น — แถบล่างต้องไม่ชี้ไปที่ของที่หายไป
        val id = selected
        if (id != null && s.pages.none { pg -> pg.items.any { it.id == id } }) setDock(DockMain)
        Haptics.light()
        scope.launch {
            delay(300)
            applied = null
        }
    }

    /** `remoteStamp` ที่ห้องนี้เห็นล่าสุด — `onChange` ของ iOS ไม่ยิงตอนเปิดหน้า จึงจำค่าตอนเกิดไว้ */
    private var labSeen = LabSync.shared.remoteStamp

    fun labStampChanged(stamp: Int) {
        if (stamp == labSeen) return
        labSeen = stamp
        reloadFromLab()
    }

    /** โหมดลองทำ: อีกเครื่องแก้การ์ดใบนี้ — โหลดผังใหม่จากคลัง ไม่นับเป็นงานแก้ของเครื่องนี้ (ไม่เข้า undo) */
    private fun reloadFromLab() {
        val id = cardID ?: return
        if (id != LabSync.shared.cardID) return
        val record = CardLibrary.shared.card(id) ?: return
        val r = CardStore.restore(record.snapshot) ?: return
        skipHistory = true
        endTextEdit()
        setPages(r.pages)
        setTheme(r.theme)
        setIndex(min(index, max(0, r.pages.size - 1)), Motion.flow)
        val sel = selected
        if (sel != null && r.pages.none { pg -> pg.items.any { it.id == sel } }) setDock(DockMain)
        skipHistory = false
    }

    // MARK: เปิดหน้า

    suspend fun onAppear() {
        // ก้อนข้อความจากไฟล์รุ่นก่อนยังมีกล่องขนาดตามใจ — จัดให้พอดีตัวอักษรตั้งแต่เปิด (ไม่นับเป็นจังหวะแก้ไข)
        if (isEditing) {
            skipHistory = true
            pages.flatMap { it.items }.filter { it.kind == WidgetKind.textBlock }.map { it.id }.forEach { fitTextBlock(it) }
            skipHistory = false
        }
        resolve(null)
        if (isEditing) {
            // เขียนใบกลับทันทีที่เปิด — ใบจากไฟล์รุ่นก่อนต้องได้ id ของชิ้นลงไฟล์ก่อนที่ผู้ใช้จะพิมพ์อะไรผูกกับมัน
            persist()
            theme.customColor?.let { myColor = it }
            hintOnce("dock", "แตะชิ้นบนการ์ดเพื่อแก้ · ปุ่มข้างล่างไว้เปลี่ยนพื้นหลังหรือเพิ่มของ")
            // กรอบเส้นประเข้มขึ้นตอนเข้า แล้วคลายลงเองใน 1.6 วิ
            editReveal = true
            revealJob?.cancel()
            revealJob = scope.launch {
                delay(1600)
                editReveal = false
            }
        }
        if (viewOnly) {
            // แจกการ์ดลงเวที แล้วค่อยให้แถบผู้ออกบัตรกับท้ายหน้าตามมา
            scope.launch {
                delay(80)
                dealt = true
            }
            scope.launch {
                delay(550)
                stripIn = true
            }
        }
        withFrameNanos { }
        booted = true
    }

    // MARK: State

    /** เขียนงานกลับใบในคลัง — คลิปไม่มีใบให้เขียน (`cardID` ว่าง) จึงเงียบไปเอง */
    fun persist() {
        val id = cardID ?: return
        CardLibrary.shared.save(id, pages, theme, index)
    }

    fun resolve(spring: SpringToken?) {
        val page = current
        if (page == null) {
            placed = emptyList(); placedPage = null; return
        }
        layoutSpring = spring
        placed = PageLayout.solve(layoutItems(page), pageSize, first = dragID)
        placedPage = page.id
    }

    /**
     * รายการที่ใช้คำนวณผัง — ระหว่างลาก ตัวที่ถูกจับถูก **ย้ายไปช่องที่นิ้วชี้อยู่ก่อน**
     * ข้อมูลจริงไม่ถูกแตะเลยจนกว่าจะปล่อยนิ้ว
     */
    private fun layoutItems(page: CardPage): List<WidgetInstance> {
        val id = dragID ?: return page.items
        val at = dragOrigin ?: return page.items
        val i = page.items.indexOfFirst { it.id == id }
        if (i < 0) return page.items
        val items = page.items.toMutableList()
        var w = items[i].copy(x = at.x, y = at.y)
        dragWidth?.let { w = w.copy(w = it) }
        items[i] = w
        return items
    }

    /**
     * ช่องปลายทางที่นิ้วชี้อยู่ **ณ วินาทีนี้** — คำนวณสด ไม่พึ่งค่าที่คอมมิตไว้
     * ใช้ทั้งตอนลาก (ผ่าน `hover`) และตอนปล่อยนิ้ว — สองที่ต้องคิดด้วยสูตรเดียวกัน
     */
    fun target(p: Placed): Rect? {
        if (pageSize.width <= 0f) return null
        val page = current ?: return null
        val t = dragTranslation
        val at = PageLayout.snap(Offset(dragStart.left + t.x, dragStart.top + t.y))
        var probe = p.item.copy(w = dragWidth ?: p.item.w, x = at.x, y = at.y)
        probe = probe.withRect(PageLayout.clamp(probe, pageSize))
        // ที่ว่างตรงนี้แคบกว่าตัวเอง → **ย่อทั้งชิ้น** ให้พอดีที่ · ยกเว้นก้อนข้อความ (ความกว้างของมันคือตัวอักษร)
        val room = PageLayout.freeWidth(
            from = probe.x, y = probe.y, height = probe.h, page = pageSize, avoiding = page.items, excluding = p.id,
        )
        val floor = PageLayout.minSize.width
        if (p.item.kind != WidgetKind.textBlock && room >= floor) {
            probe = probe.copy(w = min(p.item.w, max(floor, PageLayout.snap(room))))
        }
        return PageLayout.clamp(probe, pageSize)
    }

    /**
     * เปิดที่ให้ของที่กำลังลาก — **ระหว่างที่นิ้วยังไม่ปล่อย**
     * throttle ไม่ใช่ debounce: นัดที่ตั้งไว้แล้วห้ามยกเลิก และอ่านตำแหน่งนิ้วสด ๆ ตอนมันทำงาน
     */
    fun hover(p: Placed) {
        if (dragID != p.id) return
        val t = target(p) ?: return
        // ตรงกับที่คอมมิตไปแล้ว — ไม่มีอะไรต้องขยับ
        val d = dragOrigin
        if (d != null && abs(d.x - t.left) < 0.5f && abs(d.y - t.top) < 0.5f &&
            abs((dragWidth ?: p.item.w) - t.width) < 0.5f
        ) return
        // มีนัดที่ยังไม่ถึงคิว — ปล่อยให้มันเดิน
        if (reflow != null) return
        val wait = max(0.0, ReflowGap - (nowSeconds() - lastReflow))
        reflow = scope.launch {
            delay((wait * 1000).toLong())
            reflow = null
            // อ่านช่องปลายทาง **ตอนนี้** ไม่ใช่ตอนตั้งนัด
            if (dragID != p.id) return@launch
            val now = target(p) ?: return@launch
            lastReflow = nowSeconds()
            // สปริงตอบไว (snap) — ของที่หลบให้ต้องไปถึงที่ก่อนนิ้วจะเดินต่อ
            dragOrigin = now.topLeft
            dragWidth = now.width
            resolve(Motion.snap)
        }
    }

    private fun nowSeconds(): Double = System.nanoTime() / 1_000_000_000.0

    // MARK: ข้อความบนตัว widget

    /** เริ่มพิมพ์ช่องหนึ่ง — **ไม่แตะ `dock`** ชิ้นยังถูกเลือกอยู่ */
    fun beginTextEdit(slot: TextSlotRect, p: Placed) {
        if (selected != p.id) return
        if (Profile.me.editing == slot.id) return
        // ย้ายไปช่องใหม่ต้องเก็บค่าช่องเดิมก่อนเสมอ — แต่ปล่อยคีย์บอร์ดค้างไว้
        commitTextEdit()
        Profile.me.editing = slot.id
        Haptics.light()
    }

    /** ปิดช่องพิมพ์แล้วเก็บค่า **พร้อมหุบคีย์บอร์ด** — เรียกซ้ำได้ */
    fun endTextEdit() {
        keyboardController?.hide()
        focusManager?.clearFocus(force = true)
        commitTextEdit()
    }

    /** เก็บค่าช่องที่แก้อยู่โดย **ไม่แตะคีย์บอร์ด** — ใช้ตอนย้ายไปแก้ช่องอื่นต่อ */
    fun commitTextEdit() {
        val id = Profile.me.editing ?: return
        Profile.me.editing = null
        Profile.me.commit(id)
    }

    /** เลือกชิ้น = เข้าโหมดของชิ้นนั้น · null = กลับแถบหลัก — **เลือกแล้วทุกอย่างยังอยู่ที่เดิม** */
    fun select(id: UUID?) {
        endTextEdit()
        // เลือกตัวอื่นคือจบการเล็งรูปด้วย
        photos?.framing = null
        val target = if (id != null) dockPiece(id) else DockMain
        if (sameDock(dock, target)) return
        setDock(target)
        if (id != null) Haptics.light()
    }

    /** กลับแถบหลัก — ‹ · แตะที่ว่าง · เปลี่ยนหน้า ล้วนมาลงที่นี่ */
    fun goMain() {
        if (dock.isText) {
            exitTextMode(); return
        }
        if (dock.isMain) return
        select(null)
        Haptics.light()
    }

    /** เข้าโหมดพิมพ์ก้อนข้อความ — ก้อนยกขึ้นกลางที่ว่าง แป้นพิมพ์ขึ้นพร้อมแถวฟอนต์ */
    fun enterTextMode(id: UUID) {
        if (pages.none { pg -> pg.items.any { it.id == id && it.kind == WidgetKind.textBlock } }) return
        photos?.framing = null
        // หนึ่งรอบพิมพ์ = หนึ่งจังหวะใน ↶
        history.record(snapshotNow())
        setDock(dockText(id))
        Profile.me.editing = TextSlotID(field = ProfileField.note, widget = id)
        Haptics.light()
    }

    /** เสร็จ — เก็บข้อความ หุบคีย์บอร์ด ก้อนไหลกลับเข้าที่ แล้วกลับแถบหลัก (ท่าเดียวกับ IG) */
    fun exitTextMode() {
        if (!dock.isText) return
        val id = dock.selectedID ?: return
        endTextEdit()
        // ก้อนที่ว่างเปล่าตอนเสร็จหายไปเอง — อยากได้คืนมี ↶
        val empty = Profile.me.note(id) == Profile.notePlaceholder
        skipHistory = true
        if (empty) {
            setPages(pages.map { pg -> pg.copy(items = pg.items.filterNot { it.id == id }) })
        } else {
            fitTextBlock(id)
        }
        setDock(DockMain)
        skipHistory = false
        // ข้อความอยู่ใน `Profile` ไม่ใช่ใน `pages` — บันทึกใบเองตรงนี้
        persist()
        Haptics.light()
    }

    /** ปุ่ม "ข้อความ" บนแถบหลัก — วางก้อนใหม่แล้วเข้าโหมดพิมพ์ทันที */
    fun addText() {
        val id = addWidget(WidgetKind.textBlock) ?: return
        // ก้อนใหม่จัดกลางเหมือนข้อความบน Story
        updateItem(id) { it.copy(textStyle = it.textStyle.copy(align = TextAlignment.center)) }
        enterTextMode(id)
    }

    /**
     * กล่องของก้อนข้อความ **คือตัวอักษรพอดี** — ยึดขอบตามการจัดวาง (ลากหมุดมุมยึดมุมบนซ้ายเสมอ)
     */
    fun fitTextBlock(id: UUID, keepTopLeft: Boolean = false) {
        val pi = pages.indexOfFirst { pg -> pg.items.any { it.id == id } }
        if (pi < 0) return
        val orig = pages[pi].items.first { it.id == id }
        var w = orig
        val inset = TextBlockSpec.inset
        val content = PageLayout.content(pageSize)
        val text = Profile.me.note(id)
        val size = TextFit.capped(measurer, w.textStyle.points, text, w.textStyle.face, TextBlockWeight, content.width - inset * 2f)
        val m = TextFit.metrics(measurer, text, w.textStyle.face, TextBlockWeight, size, w.textStyle.align)
        // พอดี **หมึก** ถึงพอยต์ — ไม่ปัดเข้ากริด 6pt
        val newW = min(m.ink.width + inset * 2f, content.width)
        val newH = m.ink.height + inset * 2f
        val old = w.rect
        if (!keepTopLeft) {
            when (w.textStyle.align) {
                TextAlignment.leading -> {}
                TextAlignment.center -> w = w.copy(x = PageLayout.snap(old.center.x - newW / 2f))
                TextAlignment.trailing -> w = w.copy(x = PageLayout.snap(old.right - newW))
            }
        }
        w = w.copy(w = newW, h = newH)
        w = w.withRect(PageLayout.clamp(w.rect, pageSize, PageLayout.minSize(WidgetKind.textBlock)))
        if (w == orig) return
        val fitted = w
        updateItem(id) { fitted }
    }

    /** แก้ชิ้น `id` ที่หน้าไหนก็ได้ — คืน false เมื่อหาไม่เจอ */
    private fun updateItem(id: UUID, change: (WidgetInstance) -> WidgetInstance): Boolean {
        val pi = pages.indexOfFirst { pg -> pg.items.any { it.id == id } }
        if (pi < 0) return false
        setPages(pages.mapIndexed { i, pg ->
            if (i != pi) pg else pg.copy(items = pg.items.map { if (it.id == id) change(it) else it })
        })
        return true
    }

    /**
     * หยิบของออกจากตู้ → หา **หน้าที่ยังมีที่ว่างจริง** ให้มัน (หน้าปัจจุบันก่อน แล้ววนไปหน้าถัดไป)
     * ไม่มีหน้าไหนรับได้เลยก็ **เปิดหน้าใหม่** · ครบหน้าแล้วย่อให้พอดีที่ว่าง · ย่อสุดแล้วยังไม่ลง = บอกว่าเต็ม
     */
    fun addWidget(kind: WidgetKind): UUID? {
        if (index !in pages.indices) return null
        var w = WidgetInstance.make(kind)

        // ไล่จากหน้าที่เปิดอยู่ → ท้ายเล่ม → วนกลับมาหน้าแรก
        val order = (index until pages.size) + (0 until index)
        var dest: Int? = null
        for (p in order) {
            val at = PageLayout.freeSpot(Size(w.w, w.h), pageSize, pages[p].items) ?: continue
            w = w.copy(x = at.x, y = at.y)
            dest = p
            break
        }

        // ไม่มีที่เต็มขนาด และเปิดหน้าใหม่ไม่ได้ — **ย่อทั้งชิ้น** ทีละขั้นได้ถึง 60% ก่อนจะยอมแพ้
        var shrunk = false
        if (dest == null && pages.size >= format.pageCount) {
            val floor = max(PageLayout.minSize.width, PageLayout.snap(w.w * 0.6f))
            var width = w.w - PageLayout.step
            while (width >= floor) {
                val size = Size(width, w.h * width / max(w.w, 1f))
                val at = PageLayout.freeSpot(size, pageSize, pages[index].items)
                if (at != null) {
                    w = w.scale(toWidth = width).copy(x = at.x, y = at.y)
                    dest = index
                    shrunk = true
                    break
                }
                width -= PageLayout.step
            }
        }

        // ย่อสุดแล้วยังไม่ลง = **บอกว่าเต็ม** ไม่ใช่แอบเปิดหน้าใหม่ — ค้างไว้จนกดปิด
        if (dest == null && pages.size >= format.pageCount) {
            warn(
                if (format.pageCount == 1) "เพิ่มไม่ได้ · หน้าเต็มแล้ว — ย่อหรือเอาของออกก่อน"
                else "เพิ่ม${kind.title}ไม่ได้ · ครบ ${format.pageCount} หน้าและเต็มทุกหน้าแล้ว",
            )
            return null
        }

        val moved = dest?.let { it != index } ?: true
        val d = dest
        if (d != null) {
            // ต่อท้ายลิสต์ = ได้สิทธิ์ที่นั่งทีหลังสุดเวลาชนกัน ของใหม่จึงเป็นฝ่ายหลบ
            val placedW = w
            setPages(pages.mapIndexed { i, pg -> if (i == d) pg.copy(items = pg.items + placedW) else pg })
            if (d != index) setIndex(d, Motion.flow)
        } else {
            w = w.copy(x = PageLayout.margin, y = PageLayout.margin)
            setPages(pages + CardPage(items = listOf(w)))
            setIndex(pages.size - 1, Motion.flow)
        }
        // เลือกหลังเปลี่ยนหน้า — การเปลี่ยนหน้าล้างการเลือกทิ้ง
        select(w.id)
        Haptics.medium()
        // ของที่โผล่มาเล็กกว่าที่เห็นในตู้ต้องมีคำอธิบาย ไม่งั้นอ่านเป็น "แอปวางผิด"
        if (shrunk) {
            flash("ที่ว่างไม่พอขนาดเต็ม — ย่อให้พอดีแล้ว ลากหมุดมุมปรับต่อได้")
        } else if (moved && kind != WidgetKind.textBlock) {
            flash("หน้านี้เต็ม — เพิ่มไว้หน้า ${index + 1} แล้ว")
        }
        return w.id
    }

    // MARK: Drag

    fun beginDrag(p: Placed) {
        // คลิปเป็นตัวเปิดการ์ด — กดค้างแล้วห้ามลาก
        if (viewOnly) return
        endTextEdit()
        if (dragID != null) return
        val live = placed.firstOrNull { it.id == p.id } ?: return
        // **ไม่เลือกชิ้นตอนเริ่มลาก** — เลือก = ถาดของชิ้นโผล่ = การ์ดย่อใต้นิ้วกลางการลาก
        swipe = 0f
        deckTo(index.toFloat(), Motion.snap)
        dragID = p.id
        dragItem = live.item
        dragOriginPage = index
        dragStart = live.frame
        val pp = pressPoint
        dragGripX = if (pp != null && pp.id == p.id) pp.at.x else live.frame.width / 2f
        dragTranslation = Offset.Zero
        // เริ่มที่ตำแหน่งเดิมของมันเอง ผังจึงไม่ขยับตอนยกขึ้น
        dragOrigin = Offset(live.item.x, live.item.y)
        dragWidth = live.item.w
        Haptics.medium()
        lifted = true
    }

    fun endDrag(p: Placed) {
        if (dragID != p.id) return
        edgeFlip?.cancel(); edgeFlip = null
        reflow?.cancel(); reflow = null

        // ปล่อยนอกพื้นที่หน้า (เหนือชีต/พ้นขอบ) = วางไม่ได้ — เด้งกลับบ้านเดิม
        val t = dragTranslation
        val finger = Offset(dragStart.center.x + t.x, dragStart.center.y + t.y)
        val slack = 40f
        if (!(finger.x > -slack && finger.x < pageSize.width + slack &&
                finger.y > -slack && finger.y < pageSize.height + slack)
        ) {
            bounceBack(p); return
        }

        // **คำนวณสดตอนปล่อย ไม่ใช่ใช้ค่าที่คอมมิตไว้** — ลากเร็วแล้วปล่อยต้องไม่เด้งกลับที่เดิม
        val drop = target(p) ?: PageLayout.clamp(p.item, pageSize)

        // ปล่อยนิ้วบนหน้าอื่นที่ไม่ใช่หน้าต้นทาง — ย้าย item จริงตอนนี้ ต่อท้าย = ขึ้นชั้นบนสุด
        var next = pages
        val src = next.indexOfFirst { pg -> pg.items.any { it.id == p.id } }
        if (src >= 0 && src != index && index in next.indices) {
            val item = next[src].items.first { it.id == p.id }
            next = next.mapIndexed { i, pg ->
                when (i) {
                    src -> pg.copy(items = pg.items.filterNot { it.id == p.id })
                    index -> pg.copy(items = pg.items + item)
                    else -> pg
                }
            }
        }

        Haptics.medium()
        lifted = false
        dragID = null
        dragItem = null
        dragTranslation = Offset.Zero
        dragOrigin = null
        dragWidth = null
        if (index in next.indices) {
            // ความกว้างที่ถูกย่อให้พอดีที่คือความกว้างที่ผู้ใช้เห็นตอนปล่อย — เก็บไว้จริง
            var items = next[index].items.map {
                if (it.id == p.id) it.copy(x = drop.left, y = drop.top, w = drop.width) else it
            }
            // **คอมมิตผังทั้งหน้าให้ตรงกับที่ตาเห็นตอนปล่อย** — ไม่งั้นของที่เพิ่งลากขึ้นไปถูกดันกลับที่เดิม
            val settled = PageLayout.slots(items, pageSize, first = p.id)
            items = items.map { w -> settled[w.id]?.let { r -> w.copy(x = r.left, y = r.top) } ?: w }
            next = next.mapIndexed { i, pg -> if (i == index) pg.copy(items = items) else pg }
        }
        if (!setPages(next)) resolve(Motion.settle)
        // **วางแล้วแถบล่างอยู่ในสถานะเดิม** — ลากคือย้ายที่ ไม่ใช่เลือก
    }

    /** วางไม่ได้ — ชั้นลอย "สปริงเด้งกลับ" ไปที่บ้านของมัน · ค้าง dragID ไว้จนสปริงจบ */
    fun bounceBack(p: Placed) {
        reflow?.cancel(); reflow = null
        dragOrigin = null
        dragWidth = null
        // เหลือแค่พาหน้ากลับ ถ้าลากข้ามหน้าไปแล้ว
        if (index != dragOriginPage && dragOriginPage in pages.indices) {
            swipe = 0f
            setIndex(dragOriginPage, Motion.page)
        }
        // ผังที่ถูกดันไว้ระหว่างลากคลายกลับเอง
        resolve(Motion.flow)
        Haptics.rigid()
        val from = dragTranslation
        lifted = false
        scope.launch {
            animate(
                typeConverter = Offset.VectorConverter,
                initialValue = from,
                targetValue = Offset.Zero,
                animationSpec = SpringToken(320f, 18f).spec(),
            ) { v, _ -> if (dragID == p.id) dragTranslation = v }
        }
        // รอสปริงเข้าที่ก่อนค่อยสลับชั้นลอยเป็น tile จริง — สลับก่อนจะเห็นวูบ
        scope.launch {
            delay(450)
            if (dragID != p.id) return@launch
            dragID = null
            dragItem = null
        }
    }

    /** ลากค้างที่ขอบขวา = ไปหน้าถัดไป · ขอบซ้าย = หน้าก่อนหน้า · หน่วง 0.35 วิ */
    fun checkEdgeFlip(p: Placed, t: Offset) {
        val x = dragStart.left + dragGripX + t.x
        val margin = 30f
        val dir: Int? = if (x > pageSize.width - margin) 1 else if (x < margin) -1 else null
        if (dir == null || (index + dir) !in pages.indices) {
            edgeFlip?.cancel(); edgeFlip = null
            return
        }
        if (edgeFlip != null) return
        edgeFlip = scope.launch {
            delay(350)
            flipPage(p, dir)
        }
    }

    /** สลับหน้าที่แสดงระหว่างลาก — ห้ามย้ายข้อมูลตอนนี้เด็ดขาด (ย้ายจริงตอน endDrag) */
    private fun flipPage(p: Placed, dir: Int) {
        edgeFlip = null
        val target = index + dir
        if (dragID != p.id || target !in pages.indices) return
        // หน้าปลายทางไม่มีที่ว่างพอสำหรับชิ้นนี้ = **ห้ามข้ามไป** — สั่นแบบปฏิเสธแทน
        val size = Size(dragWidth ?: p.item.w, p.item.h)
        if (PageLayout.freeSpot(size, pageSize, pages[target].items) == null) {
            Haptics.rigid()
            return
        }
        swipe = 0f
        setIndex(target, Motion.page)
        Haptics.medium()
    }

    /** แรงต้านตอนลากเลยขีด — ยิ่งลากไกลยิ่งขยับน้อยลง แล้วตันที่ ~26pt */
    fun rubber(d: Float): Float {
        val cap = 26f
        return (1f - 1f / (abs(d) / cap + 1f)) * cap * (if (d < 0f) -1f else 1f)
    }

    // MARK: ตัวรับทัชของชิ้น (S4 `PressDragCatcher`)

    fun catcherBegan(p: Placed) {
        // ตอนพิมพ์ก้อนนี้อยู่ไม่มีผังให้ย้าย — กดค้างไม่ทำอะไร
        if (!isEditing || showroomID != null) return
        pressMode = p.id
        beginDrag(p)
    }

    /** `raw` = ระยะลากใน dp ของราก — หารสเกลของแคนวาสให้ widget วิ่งเท่านิ้วจริง */
    fun catcherChanged(p: Placed, raw: Size) {
        if (dragID != p.id) return
        val s = max(canvasScale, 0.01f)
        val scaled = Offset(raw.width / s, raw.height / s)
        dragTranslation = scaled
        hover(p)
        checkEdgeFlip(p, scaled)
    }

    fun catcherEnded(p: Placed) {
        if (pressMode == p.id) pressMode = null
        endDrag(p)
    }

    /**
     * แตะ = เลือก · แตะซ้ำบนชิ้นที่เลือกอยู่ = ลงมือกับข้อความ (ก้อนข้อความเข้าโหมดพิมพ์ · ชิ้นอื่นแตะช่องนั้น ๆ)
     * `at` = จุดในพิกัดของ tile (หน่วยออกแบบ)
     */
    fun catcherTap(p: Placed, at: Offset, reg: SlotRegistry, origin: TileOrigin) {
        val point = reg.pageOf(origin.root) + at
        // คลิป = การ์ดทำตัวเป็นการ์ดจริง — แตะช่องโซเชียลไปหน้าโปรไฟล์ แตะผลงานไปโพสต์นั้น
        if (!isEditing) {
            reg.hitLink(point, p.item.id)?.let { open(it) }
            return
        }
        // ก้อนข้อความ: แตะแรก = เลือก (ได้หมุดมุม · ลากย้ายได้) · แตะซ้ำ = พิมพ์
        if (p.item.kind == WidgetKind.textBlock) {
            if (selected == p.id) enterTextMode(p.id) else select(p.id)
            return
        }
        if (selected != p.id) {
            select(p.id); return
        }
        val hit = reg.hitText(point, p.item.id)
        if (hit != null) beginTextEdit(hit, p) else if (Profile.me.editing != null) endTextEdit()
    }

    fun catcherPress(p: Placed, at: Offset?) {
        if (at != null) {
            pressPoint = PressPoint(p.id, at)
        } else if (pressPoint?.id == p.id) {
            pressPoint = null
        }
    }

    // MARK: Handles

    /** หมุดขอบขวา — **ความกว้างอย่างเดียว** · `t` = ระยะลากในพิกัดหน้า */
    fun resizeWidth(p: Placed, t: Offset) {
        val item = pages.getOrNull(index)?.items?.firstOrNull { it.id == p.id } ?: return
        if (resizeID != p.id) {
            resizeID = p.id
            resizeW = item.w
            resizeScale = max(showroomScale(p), 0.01f)
        }
        // เพดานคือขอบขวาของหน้า
        val room = PageLayout.roomWidth(item.x, pageSize)
        val want = resizeW + t.x / resizeScale
        val cur = item.w
        // ฮิสเทอรีซิส — ต้องลากพ้นครึ่งขั้นไปอีกหน่อยจึงเปลี่ยน
        if (abs(want - cur) <= PageLayout.step * 0.6f) return
        val next = PageLayout.snap(min(max(want, PageLayout.minSize.width), room))
        if (abs(next - cur) > 0.5f) {
            updateItem(p.id) { it.copy(w = next) }
            Haptics.light()
        }
        // ลากเลยขีดแล้ว — ให้ "กรอบ" ยืดตามนิ้วแบบหนืด ตัว widget ไม่ขยับ
        val over = want - next
        overshootJob?.cancel()
        overshoot = overshoot.copy(x = if (abs(over) < 0.5f) 0f else rubber(over))
    }

    /** หมุดขอบล่าง — **ความสูงอย่างเดียว** */
    fun resizeHeight(p: Placed, t: Offset) {
        val item = pages.getOrNull(index)?.items?.firstOrNull { it.id == p.id } ?: return
        if (resizeID != p.id) {
            resizeID = p.id
            resizeH = item.h
            resizeScale = max(showroomScale(p), 0.01f)
        }
        val room = PageLayout.roomHeight(item.y, pageSize)
        val want = resizeH + t.y / resizeScale
        val cur = item.h
        if (abs(want - cur) <= PageLayout.step * 0.6f) return
        val next = PageLayout.snap(min(max(want, PageLayout.minSize.height), room))
        if (abs(next - cur) > 0.5f) {
            updateItem(p.id) { it.copy(h = next) }
            Haptics.light()
        }
        val over = want - next
        overshootJob?.cancel()
        overshoot = overshoot.copy(y = if (abs(over) < 0.5f) 0f else rubber(over))
    }

    /** หมุดมุมของก้อนข้อความ — ปรับ **ขนาดตัวอักษร** ตามแนวทแยง · มุมบนซ้ายนิ่ง */
    fun resizeCorner(p: Placed, t: Offset) {
        val item = pages.getOrNull(index)?.items?.firstOrNull { it.id == p.id } ?: return
        if (resizeID != p.id) {
            resizeID = p.id
            resizeW = item.w
            resizeH = item.h
            resizePoints = item.textStyle.points
            resizeScale = max(showroomScale(p), 0.01f)
        }
        // สัดส่วน = ระยะที่นิ้วเดินตามแนวทแยงของกล่องเดิม เทียบกับความยาวแนวทแยงนั้น
        val dx = t.x / resizeScale
        val dy = t.y / resizeScale
        val diag = max(hypot(resizeW, resizeH), 1f)
        val along = (dx * resizeW + dy * resizeH) / diag
        val k = max(0.15f, (diag + along) / diag)
        var want = min(max(resizePoints * k, TextFit.minSize), TextFit.maxSize)
        // ห้ามโตจนบรรทัดล้นหน้า — ตัวอักษรต้องเห็นครบเสมอ
        want = TextFit.capped(
            measurer, want, Profile.me.note(p.id), item.textStyle.face, TextBlockWeight,
            PageLayout.content(pageSize).width - TextBlockSpec.inset * 2f,
        )
        val cur = item.textStyle.points
        val r = swiftRound(want)
        if (abs(r - cur) < 1f) return
        updateItem(p.id) { it.copy(textStyle = it.textStyle.copy(points = r)) }
        fitTextBlock(p.id, keepTopLeft = true)
    }

    /** เลิกโหมดยืดขนาด — เรียกซ้ำได้ ไม่มีผลข้างเคียง (ล้างจากทางออกทุกทาง ไม่ใช่แค่ปล่อยนิ้ว) */
    fun endResize() {
        if (resizeID == null) return
        resizeID = null
        val from = overshoot
        overshootJob?.cancel()
        overshootJob = scope.launch {
            animate(
                typeConverter = Offset.VectorConverter,
                initialValue = from,
                targetValue = Offset.Zero,
                animationSpec = SpringToken(300f, 20f).spec(),
            ) { v, _ -> overshoot = v }
        }
    }

    // MARK: ปัดเปลี่ยนหน้า

    /** `t` = ระยะนิ้วในพิกัดของสำรับ (ก่อนย่อหลบชีต) */
    fun swipeChanged(t: Offset, width: Float) {
        // การ์ดหน้าเดียวไม่มีหน้าให้ไป — ห้ามแม้แต่หน่วงยาง
        if (!multiPage || dragID != null || resizeID != null) return
        // ยังไม่ติดแนวนอน = ต้องชัดว่าปัดซ้ายขวา
        if (!swipeArmed) {
            if (abs(t.x) <= abs(t.y) * 1.2f) return
            swipeArmed = true
        }
        // หักระยะ dead zone ออก ไม่งั้นพอ gesture ติดครั้งแรกหน้าจะกระโดดไป 12pt ทันที
        val raw = -t.x
        val dead = 12f
        val adjusted = if (raw > 0f) max(0f, raw - dead) else min(0f, raw + dead)
        var p = adjusted / max(width, 1f)
        // หน่วงยางที่หน้าแรกและหน้าสุดท้าย
        if ((index == 0 && p < 0f) || (index == pages.size - 1 && p > 0f)) p *= 0.32f
        swipe = max(-1f, min(1f, p))
        deckTo(index + swipe, null)
    }

    fun swipeEnded(predictedX: Float, width: Float) {
        val armed = swipeArmed
        swipeArmed = false
        if (!armed || !multiPage || dragID != null || resizeID != null) {
            swipe = 0f
            deckTo(index.toFloat(), Motion.page)
            return
        }
        val velocity = -predictedX / max(width, 1f)
        val target = when {
            swipe > 0.28f || velocity > 0.75f -> index + 1
            swipe < -0.28f || velocity < -0.75f -> index - 1
            else -> index
        }
        val next = max(0, min(pages.size - 1, target))
        if (next != index) Haptics.light()
        swipe = 0f
        setIndex(next, Motion.page)
    }

    /** กติกาข้อ 4: **แตะที่ว่าง = ‹** · ตอนพิมพ์ = เสร็จ */
    fun emptyTap() {
        if (!isEditing) return
        if (dock.isText) exitTextMode() else goMain()
    }

    /** ช่องข้าง ๆ ที่โผล่ให้เห็น แตะแล้วเลื่อนไปช่องนั้น */
    fun tapNeighbor(i: Int) {
        if (dragID != null) return
        Haptics.light()
        setIndex(i, Motion.page)
    }

    // MARK: แถบบน / แถบล่าง

    /** แชร์ — ชีตที่เปิดค้างจะบังหน้าตัวอย่าง หุบก่อนแล้วค่อยพาไป */
    fun share() {
        endTextEdit()
        photos?.framing = null
        setDock(DockMain)
        showPreview = true
        Haptics.light()
    }

    /** ทางกลับคลัง — ดูเฉย ๆ แล้วออก = ไม่เกิดการ์ด */
    fun leaveToLibrary(go: () -> Unit) {
        Haptics.light()
        val id = cardID
        if (discardIfUntouched && !touched && id != null) CardLibrary.shared.delete(id)
        go()
    }

    fun mainAction(item: DockMainItem) {
        when (item) {
            DockMainItem.backdrop -> {
                setDock(DockBackdrop)
                Haptics.light()
            }
            DockMainItem.text -> {
                if (cardIsFull()) {
                    warnFull(); return
                }
                addText()
            }
            DockMainItem.widget -> {
                if (cardIsFull()) {
                    warnFull(); return
                }
                setDock(DockGallery)
                Haptics.light()
            }
        }
    }

    /** ปุ่มเพิ่มจางอยู่แล้ว — แตะแล้วต้องได้คำอธิบาย ไม่ใช่ปุ่มตาย */
    fun warnFull() {
        warn(
            if (format.pageCount == 1) "หน้าเต็มแล้ว — เอาของออกหรือย่อของเดิมก่อนถึงจะเพิ่มได้"
            else "ครบ ${format.pageCount} หน้าและเต็มทุกหน้า — เอาของออกก่อนถึงจะเพิ่มได้",
        )
    }

    fun backEnabled(): Boolean =
        dock.isText || photos?.framing != null || (isEditing && !dock.isMain) ||
            (viewOnly && onClose != null) || (isEditing && onChangeFormat != null)

    /** ปุ่มย้อนของระบบ — จบสิ่งที่ทำอยู่ทีละชั้น แล้วค่อยออกจากห้อง */
    fun systemBack() {
        when {
            dock.isText -> exitTextMode()
            photos?.framing != null -> {
                photos?.framing = null
            }
            isEditing && !dock.isMain -> goMain()
            viewOnly -> onClose?.let {
                Haptics.light()
                it()
            }
            else -> onChangeFormat?.let { leaveToLibrary(it) }
        }
    }

    // MARK: ข้อความบอกเหตุ

    /** บอกสถานะ — หายเอง */
    fun flash(text: String) = show(CardNotice(text, CardNotice.Kind.status), 3.2)

    /** **คำสั่งถูกปฏิเสธ** — ค้างจนผู้ใช้ปิดเอง */
    fun warn(text: String) {
        Haptics.rigid()
        show(CardNotice(text, CardNotice.Kind.warning), null)
    }

    /** ยื่นทางกลับให้หนึ่งทาง — ใช้กับของที่ทำไปแล้วและกู้คืนได้ */
    fun offer(text: String, title: String, act: () -> Unit) =
        show(CardNotice(text, CardNotice.Kind.offer, actionTitle = title, action = act), 5.0)

    /** สอนท่าให้ครั้งเดียวในชีวิต — ตั้งธงว่าเห็นแล้วตั้งแต่ตอนขึ้น */
    fun hintOnce(key: String, text: String) {
        val flag = "starcard.hint.$key"
        val prefs = AppContext.prefs
        if (prefs.getBoolean(flag, false)) return
        prefs.edit().putBoolean(flag, true).apply()
        show(CardNotice(text, CardNotice.Kind.offer, actionTitle = "เข้าใจแล้ว", action = {}), null)
    }

    fun show(n: CardNotice, seconds: Double?) {
        noticeJob?.cancel()
        notice = n
        if (seconds == null) {
            noticeJob = null; return
        }
        noticeJob = scope.launch {
            delay((seconds * 1000).toLong())
            notice = null
        }
    }

    fun clearNotice() {
        noticeJob?.cancel()
        noticeJob = null
        notice = null
    }

    // MARK: ถาดของชิ้น

    fun setTextStyle(sel: WidgetInstance, change: (WidgetTextStyle) -> WidgetTextStyle) {
        // ไม่สั่นตรงนี้ — ชิปที่เรียกมาสั่นเองแล้ว
        updateItem(sel.id) { it.copy(textStyle = change(it.textStyle)) }
    }

    fun setPattern(sel: WidgetInstance, on: PlatePattern) {
        if (updateItem(sel.id) { it.copy(pattern = on) }) Haptics.light()
    }

    /** 0 = ฟอยล์ · 1 = ปั๊มนูน · 2 = ไม่มี */
    fun setEmboss(sel: WidgetInstance, mode: Int) {
        if (updateItem(sel.id) { it.copy(emboss = mode != 2, embossBlind = mode == 1) }) Haptics.light()
    }

    fun setLiftPhoto(sel: WidgetInstance, on: Boolean) {
        if (updateItem(sel.id) { it.copy(liftPhoto = on) }) Haptics.light()
    }

    fun setSurface(sel: WidgetInstance, s: WidgetSurface) {
        if (updateItem(sel.id) { it.copy(surface = s) }) Haptics.light()
    }

    fun setBorder(sel: WidgetInstance, on: Boolean) {
        if (updateItem(sel.id) { it.copy(border = on) }) Haptics.light()
    }

    /**
     * ลบ widget พร้อมยื่นทางกลับให้ห้าวินาที — "เลิกทำ" ไม่ใช่ "ยืนยันว่าจะลบ"
     * เก็บทั้งตัวและ **ที่นั่งเดิม** ไว้ — รูปกับข้อความของ widget ผูกกับ `id` ที่คงไว้
     */
    fun deleteWidget(sel: WidgetInstance) {
        val pi = pages.indexOfFirst { pg -> pg.items.any { it.id == sel.id } }
        if (pi < 0) return
        val ii = pages[pi].items.indexOfFirst { it.id == sel.id }
        val removed = pages[pi].items[ii]
        setPages(pages.mapIndexed { i, pg ->
            if (i == pi) pg.copy(items = pg.items.filterIndexed { j, _ -> j != ii }) else pg
        })
        // ปิดชีตด้วย — ชีตบังขอบล่างของจอพอดี ที่ที่แถบ "เลิกทำ" ยืนอยู่
        setDock(DockMain)
        Haptics.medium()
        offer("ลบ${sel.kind.title}แล้ว", "เลิกทำ") {
            val p = min(pi, pages.size - 1)
            setPages(pages.mapIndexed { i, pg ->
                if (i == p) pg.copy(items = pg.items.toMutableList().also { it.add(min(ii, it.size), removed) }) else pg
            })
            // พากลับไปหน้าที่มันเคยอยู่ด้วย
            setIndex(p, Motion.flow)
            setDock(dockPiece(removed.id))
            Haptics.light()
        }
    }

    /** สลับแบบโดยคงตำแหน่งเดิมไว้ · บีบขนาดให้เข้ากรอบของแบบใหม่ */
    fun swap(sel: WidgetInstance, kind: WidgetKind) {
        if (kind == sel.kind) return
        val found = updateItem(sel.id) { item ->
            // แบบใหม่มีสัดส่วนของตัวเอง — คงความกว้างไว้ แล้วให้ความสูงมาจากผังของแบบใหม่
            var w = item.copy(kind = kind).resetAspect()
            w = w.withRect(PageLayout.clamp(w, pageSize))
            // แบบใหม่บุคลิกต่างจากเดิม — กลับไปใช้พื้นตั้งต้นของมัน
            w.copy(surface = kind.defaultSurface, border = kind.defaultBorder)
        }
        if (found) Haptics.medium()
    }

    // MARK: ลิงก์

    /**
     * เปิดลิงก์ — ในแอปเป็นค่าตั้งต้น ออกนอกแอปเฉพาะที่เปิดในแอปไม่ได้
     * เว็บลิงก์ลองเปิด **แอปเจ้าของลิงก์ก่อน** ถ้าเครื่องไม่มีแอปนั้นค่อยเปิดเบราว์เซอร์ในแอป
     */
    fun open(url: String) {
        val uri = runCatching { Uri.parse(url) }.getOrNull() ?: return
        when (uri.scheme?.lowercase()) {
            // ปลายทางภายในแอป — widget ตรารับรองชี้มาที่แผ่นตรวจสอบ
            "starcard" -> {
                if (uri.host == "verified") showVerify = true
            }
            "http", "https" -> {
                if (!openInOwnerApp(context, url)) {
                    linkSeq += 1
                    link = LinkTarget(url = url)
                }
            }
            else -> systemOpenURL(context, url)
        }
    }

    fun contactPicked(url: String) {
        showContact = false
        // รอชีตลงก่อน — เบราว์เซอร์ในแอปเปิดทับชีตที่กำลังปิดไม่ขึ้น
        scope.launch {
            delay(350)
            open(url)
        }
    }

    fun topicFilled(req: TopicFillRequest, done: Boolean) {
        topicFill = null
        if (!done || !req.topic.filled) return
        // กรอกครบแล้ว = ใบที่แตะไว้ใช้ได้ทันที วางลงการ์ดให้เลย
        scope.launch {
            delay(450)
            addWidget(req.kind)
        }
    }

    /** ใช้สีจากช่อง hex — พิมพ์ผิดแล้วไม่มีอะไรเกิดขึ้น สีเดิมอยู่ครบ */
    fun applyHex() {
        val t = theme.setBackdropHex(hexDraft) ?: return
        setTheme(t)
        myColor = t.customColor
    }
}

// MARK: - เวที (= `body` ของ Swift ภายใน GeometryReader)

@Composable
private fun CardEditorState.Stage(width: Float, height: Float) {
    // พื้นที่ที่เหลือหลังเว้นแถบบนกับแถวล่าง — **ห้ามหักความสูงของแถบล่างออกจากกล่องนี้**
    // แถบล่างจัดการด้วยการ **ย่อ** (`editScale`) ไม่ใช่การเปลี่ยนขนาดหน้า
    val box = Size(width, height - 74f - 34f)
    val size = format.pageSize(box)
    val fit = format.fit(box)
    val d = LocalDensity.current
    val kb = WindowInsets.imeAnimationTarget.getBottom(d) / d.density
    val sb = WindowInsets.systemBars.getBottom(d) / d.density
    val statusTop = WindowInsets.statusBars.getTop(d) / d.density
    // เขียนก่อนอ่าน — ทุกอย่างในรอบวาดนี้เห็นค่าที่ตรงกับกล่องนี้
    if (pageSize != size) pageSize = size
    if (pageFit != fit) pageFit = fit
    if (viewportW != width) viewportW = width
    if (viewportH != height) viewportH = height
    if (keyboard != kb) keyboard = kb
    if (safeBottom != sb) safeBottom = sb

    LaunchedEffect(size) { resolve(null) }
    LaunchedEffect(Unit) { onAppear() }

    // เปลี่ยนโหมด = การ์ดย่อ/ขยายด้วยสปริงเดียวกับถาด
    val scaleK by animateFloatAsState(if (isEditing) editScale else viewScale, Motion.settle.float, label = "canvas")
    val dealK by animateFloatAsState(if (!viewOnly || dealt) 1f else 0f, Motion.settle.float, label = "deal")
    val stripK by animateFloatAsState(if (stripIn) 1f else 0f, Motion.settle.float, label = "strip")
    val band = verifyBandSpace

    Box(Modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize()) {
            // ช่องว่างใต้แถบบน **อยู่นอกก้อนที่ถูกย่อ** — ถ้าย่อไปด้วย หัวการ์ดจะมุดใต้แถบบน
            Spacer(Modifier.height((74f + band).dp))
            Column(
                Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    // พิธีเปิดของหน้าดู — การ์ดเลื่อนขึ้นมาวางบนเวที
                    .graphicsLayer {
                        val s = 0.94f + 0.06f * dealK
                        scaleX = s
                        scaleY = s
                        translationY = 44f * (1f - dealK) * density
                        alpha = dealK
                    }
                    // ย่อให้พอดีช่องเหนือแถบล่าง — **ย่ออย่างเดียว ไม่มีการดันขึ้น**
                    .graphicsLayer {
                        scaleX = scaleK
                        scaleY = scaleK
                        transformOrigin = TransformOrigin(0.5f, 0f)
                    },
            ) {
                Deck(size, fit, Modifier.weight(1f).fillMaxWidth())
                Spacer(Modifier.height(34.dp))
            }
        }

        // เงาไล่ใต้แถบบน — การ์ดที่มุดใต้แถบบนต้องอ่านเป็น "เลื่อนพ้นขอบ" ไม่ใช่ "ซ้อนกับปุ่ม"
        Box(
            Modifier
                .fillMaxWidth()
                .offset(y = (-statusTop).dp)
                .height((118f + statusTop).dp)
                .background(Brush.verticalGradient(listOf(grey(0.06), grey(0.06).opacity(0.0)))),
        )

        // ตอนพิมพ์ แถบบนหลบ — เหลือ "เสร็จ" มุมขวาบนตัวเดียว
        AnimatedVisibility(
            visible = dock.isText,
            modifier = Modifier.fillMaxWidth(),
            enter = fadeIn(Motion.settle.spec()),
            exit = fadeOut(Motion.settle.spec()),
        ) { TextTopBar() }
        AnimatedVisibility(
            visible = !dock.isText,
            modifier = Modifier.fillMaxWidth(),
            enter = fadeIn(Motion.settle.spec()),
            exit = fadeOut(Motion.settle.spec()),
        ) { TopBar() }

        // ข้อความบอกเหตุหลบตอนพิมพ์ด้วย
        if (!dock.isText) NoticeBar()

        // แถบล่างทั้งก้อน — อยู่นอกแคนวาสที่ถูกย่อ จึงไม่ขยับตามการ์ด
        if (isEditing) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.BottomCenter) { BottomChrome() }
        }

        // โหมดจัดรูป: ทั้งจอคือที่จับรูป — ทับถาดด้วย
        AnimatedVisibility(
            visible = isEditing && photos?.framing != null,
            modifier = Modifier.fillMaxSize(),
            enter = fadeIn(Motion.settle.spec()),
            exit = fadeOut(Motion.settle.spec()),
        ) { PhotoFitCatcher(theme = theme, scale = canvasScale) }

        // แถบ Verified ของหน้าดู — ใต้แถบบน นอกตัวการ์ด
        if (band > 0f) {
            Box(
                Modifier
                    .fillMaxWidth()
                    .graphicsLayer {
                        alpha = stripK
                        translationY = -10f * (1f - stripK) * density
                    }
                    .padding(horizontal = 20.dp)
                    .padding(top = 66.dp),
            ) { VerifiedBand(action = { showVerify = true }) }
        }

        // ท้ายหน้าดู — โครงของเวที
        if (viewOnly) {
            Box(
                Modifier
                    .fillMaxSize()
                    .graphicsLayer {
                        alpha = stripK
                        translationY = 16f * (1f - stripK) * density
                    },
                contentAlignment = Alignment.BottomCenter,
            ) { ViewerFooter() }
        }
    }
}

// MARK: - Deck

/**
 * สำรับ = **กระดาษแผ่นเดียวยาว 3 ช่อง** — ปัดแล้วทั้งแผ่นเลื่อน ไม่ใช่การ์ดสามใบสไลด์แยกกัน
 * ฉากหลังวาดครั้งเดียวคลุมทั้งแผ่นเหมือนรูปที่แชร์ · ตอนแต่งแผ่นถูกย่อลง ขอบของช่องข้าง ๆ จึงโผล่ให้เห็น
 */
@Composable
private fun CardEditorState.Deck(size: Size, fit: Float, modifier: Modifier) {
    val shown = Size(size.width * fit, size.height * fit)
    val inv = 1f / max(fit, 0.01f)
    val strip = Size(size.width * max(pages.size, 1), size.height)
    val paper = RoundedCornerShape((22f * inv).dp)
    val ink = theme.inkStyle
    val quiet by remember { derivedStateOf { abs(swipe) < 0.02f } }

    // หมึกของการ์ดครอบทั้งสำรับ — ไม่ครอบไปถึงแถบเครื่องมือกับชีตแต่ง
    CompositionLocalProvider(
        LocalCardInk provides ink,
        LocalPageContentWidth provides PageLayout.content(size).width,
    ) {
        Box(modifier.pageSwipe(this@Deck, size.width)) {
            // เวทีมืดรอบหน้าก็นับเป็นที่ว่าง — ชั้นรับแตะอยู่ **หลัง** ทุกชิ้น ไม่ใช่ตัวห่อ
            Box(Modifier.matchParentSize().emptyTap(this@Deck))
            Box(Modifier.align(Alignment.TopCenter).size(shown.width.dp, shown.height.dp)) {
                // หน้าต่างเท่า **หนึ่งช่อง** พอดี — ย่อพื้นที่ออกแบบทั้งผืนลงหน่วยจอ
                Box(
                    Modifier
                        .wrapContentSize(Alignment.TopStart, unbounded = true)
                        .requiredSize(size.width.dp, size.height.dp)
                        .graphicsLayer {
                            scaleX = fit
                            scaleY = fit
                            transformOrigin = TransformOrigin(0f, 0f)
                        },
                ) {
                    Box(
                        Modifier
                            .wrapContentSize(Alignment.TopStart, unbounded = true)
                            // เลื่อนทั้งแผ่นให้ช่องปัจจุบันมาอยู่ในหน้าต่าง
                            .offset { IntOffset((-deckPos.value * size.width * density).roundToInt(), 0) }
                            .requiredSize(strip.width.dp, strip.height.dp),
                    ) {
                        // ฉากหลัง **ผืนเดียวคลุมทั้งแผ่น** — มุมและเงาหารกลับด้วย fit ให้ที่ตาเห็นคงที่
                        Box(
                            Modifier
                                .matchParentSize()
                                .shadow(
                                    elevation = (26f * inv).dp, shape = paper, clip = false,
                                    ambientColor = Color.Black.opacity(0.5), spotColor = Color.Black.opacity(0.5),
                                )
                                .clip(paper),
                        ) { CardBackdrop(theme = theme, ignoreSafeArea = false, signed = true) }
                        // แตะที่ว่างบนกระดาษ — อยู่หลังทุกช่อง
                        Box(Modifier.matchParentSize().emptyTap(this@Deck))
                        // ทุกช่องอยู่ในต้นไม้ view ตลอด — gesture ที่ถือการลากข้ามช่องจึงไม่ตายกลางทาง
                        pages.forEachIndexed { i, page ->
                            key(page.id) { Sheet(page, i, size, interactive = i == index && quiet) }
                        }
                        // ตราปั๊มนูนกดลงบนแผ่นที่พิมพ์เสร็จแล้ว — เหนือ widget ทุกชิ้น ไม่กินทัช
                        if (theme.strip.isStamp) {
                            SignatureEmboss(
                                light = ink.isLight, foil = theme.strip == StripStyle.foil, tint = ink.base,
                                pages = pages, pageSize = size, modifier = Modifier.matchParentSize(),
                            )
                        }
                    }
                    // ชั้นลอยของตัวที่ลาก — อยู่ระดับหน้าต่าง ไม่ผูกกับช่องใดช่องหนึ่ง จึงลอยข้ามช่องได้
                    val item = dragItem
                    if (dragID != null && item != null) DragLayer(item)
                }
            }
        }
    }
}

/** ปัดเปลี่ยนหน้า — ดูทัชทุกตัวแบบไม่แย่ง (= `simultaneousGesture`) */
private fun Modifier.pageSwipe(state: CardEditorState, width: Float): Modifier = pointerInput(state, width) {
    awaitEachGesture {
        val down = awaitFirstDown(requireUnconsumed = false, pass = PointerEventPass.Initial)
        val tracker = VelocityTracker()
        tracker.addPosition(down.uptimeMillis, down.position)
        val start = down.position
        var last = start
        var began = false
        while (true) {
            val ev = awaitPointerEvent(PointerEventPass.Initial)
            val ch = ev.changes.firstOrNull { it.id == down.id } ?: break
            last = ch.position
            if (!ch.pressed) break
            tracker.addPosition(ch.uptimeMillis, ch.position)
            val t = (ch.position - start) / density
            if (!began && t.getDistance() >= 12f) began = true
            if (began) state.swipeChanged(t, width)
        }
        if (began) {
            val v = tracker.calculateVelocity()
            val t = (last - start) / density
            // ระยะที่แผ่นจะไหลไปถึงถ้าปล่อยตอนนี้ (= `predictedEndTranslation`)
            state.swipeEnded(t.x + v.x / density * 0.25f, width)
        }
    }
}

private fun Modifier.emptyTap(state: CardEditorState): Modifier =
    pointerInput(state) { detectTapGestures(onTap = { state.emptyTap() }) }

// MARK: - หนึ่งช่องของแผ่น

@Composable
private fun CardEditorState.Sheet(page: CardPage, i: Int, size: Size, interactive: Boolean) {
    val current = i == index
    val reg = registry(page.id)
    // ผังที่หน่วงไว้ใช้ได้เฉพาะหน้าที่เป็นเจ้าของ — หน้าอื่นคำนวณสด (ได้ค่าเดียวกับที่ resolve กำลังจะเซ็ต)
    val fallback = remember(page.items, size) { PageLayout.solve(page.items, size) }
    val solved = if (placedPage == page.id) placed else fallback
    val ids = solved.map { it.id }.toSet()
    SideEffect { tileAnims.keys.removeAll { it.first == page.id && it.second !in ids } }

    Box(
        Modifier
            .offset(x = (i * size.width).dp)
            .requiredSize(size.width.dp, size.height.dp)
            // ช่องปัจจุบันอยู่บนสุด — หมุดที่ยื่นพ้นขอบช่องต้องไม่มุดใต้ช่องถัดไป
            .zIndex(if (current) 1f else 0f)
            .onGloballyPositioned { c ->
                val o = c.localToRoot(Offset.Zero)
                val e = c.localToRoot(Offset(c.size.width.toFloat(), 0f))
                reg.origin = o
                reg.scale = if (size.width > 0f) (e.x - o.x) / size.width else 1f
            },
    ) {
        CompositionLocalProvider(LocalSlotRegistry provides reg) {
            // กริดต่อช่อง — ตอนพิมพ์ (โชว์รูม) กริดคือบริบทของ "ทั้งแผ่น" ซึ่งตอนนั้นซ่อนอยู่
            AnimatedVisibility(
                visible = isEditing && showroomID == null,
                modifier = Modifier.matchParentSize(),
                enter = fadeIn(Motion.settle.spec()),
                exit = fadeOut(Motion.settle.spec()),
            ) { CanvasGrid(theme = theme, ink = theme.inkStyle, page = size, modifier = Modifier.fillMaxSize()) }

            if (isEditing && showroomID == null) {
                val line = theme.inkStyle.line(0.16)
                Box(
                    Modifier.matchParentSize().drawBehind {
                        strokeBorder(line, 0.8.dp.toPx(), 4.dp.toPx(), floatArrayOf(5.dp.toPx(), 5.dp.toPx()))
                    },
                )
            }

            solved.forEach { p -> key(p.id) { Tile(p, page, interactive, reg) } }

            // ม่านกระจกตอนพิมพ์ — อยู่ **ใต้** ก้อนที่พิมพ์ (300 < 400) แต่ **เหนือ** ทุกอย่างที่เหลือ
            AnimatedVisibility(
                visible = current && showroomID != null,
                modifier = Modifier.matchParentSize().zIndex(300f),
                enter = fadeIn(Motion.settle.spec()),
                exit = fadeOut(Motion.settle.spec()),
            ) { TypingVeil() }

            // กรอบเลือกอยู่ชั้นบนสุดของหน้า — หมุดปรับขนาดต้องไม่ถูกตัวที่อยู่หน้ากว่าทับ
            val sel = if (isEditing && current && dragID == null && showroomID == null) {
                solved.firstOrNull { it.id == selected }
            } else null
            if (sel != null) SelectionLayer(sel, tileAnim(page.id, sel, sel.frame.size), interactive)

            // ช่องข้าง ๆ ที่โผล่ให้เห็น แตะแล้วเลื่อนไปช่องนั้น — ของที่เห็นต้องไปถึงได้
            if (i != index) {
                Box(Modifier.matchParentSize().zIndex(600f).pointerInput(i) { detectTapGestures { tapNeighbor(i) } })
            }
        }
    }
}

// MARK: - Tile

@Composable
private fun CardEditorState.Tile(p: Placed, page: CardPage, interactive: Boolean, reg: SlotRegistry) {
    val pNow by rememberUpdatedState(p)
    val id = p.id
    val isSel = selected == id
    // ไม่ผูกกับ current — ระหว่างลากข้ามหน้า tile ต้นทางต้องซ่อนอยู่
    val isDrag = dragID == id
    val order = max(0, page.items.indexOfFirst { it.id == id })
    // โหมดดู: widget นิ่งสนิท — ไม่เอียงตามนิ้ว ไม่เรืองแสง
    val pp = pressPoint
    val touch = if (isEditing && pp != null && pp.id == id && dragID == null) pp.at else null
    val sid = showroomID
    val inShowroom = sid == id
    // ตัวที่ถูกหรี่ในโชว์รูมยังอยู่ในต้นไม้ view (ผังต้องนิ่ง) — แต่ต้องไม่รับทัช
    val hittable = sid == null || inShowroom

    // ก้อนข้อความที่กำลังพิมพ์วาดที่ **ขนาดแก้ไขมาตรฐาน** ไม่ใช่ขนาดบนการ์ด
    val drawn = drawnSize(p)
    val anim = tileAnim(page.id, p, drawn)
    LaunchedEffect(anim, p.frame.topLeft) {
        val spring = layoutSpring
        if (spring == null) anim.pos.snapTo(p.frame.topLeft) else anim.pos.animateTo(p.frame.topLeft, spring.spec())
    }
    LaunchedEffect(anim, drawn, inShowroom) {
        val spring: SpringToken? = when {
            inShowroom && anim.typing -> null
            inShowroom != anim.typing -> Motion.settle
            else -> layoutSpring
        }
        anim.typing = inShowroom
        if (spring == null) anim.size.snapTo(drawn) else anim.size.animateTo(drawn, spring.spec())
    }
    val sr = showroom(p)
    val srOffset = animateOffsetAsState(Offset(sr.dx, sr.dy), Motion.settle.spec(), label = "showroom")
    val srScale = animateFloatAsState(showroomScale(p), Motion.settle.float, label = "showroomScale")
    val srDim = animateFloatAsState(showroomDim(p).toFloat(), Motion.settle.float, label = "showroomDim")
    val pressK by animateFloatAsState(if (touch != null) 1f else 0f, Motion.snap.float, label = "press")
    val appear = remember { Animatable(if (booted) 0f else 1f) }
    LaunchedEffect(appear) { appear.animateTo(1f, Motion.flow.float) }
    // แบบเปลี่ยน = ช่องรูปชุดเก่าต้องหายจากทะเบียน (ก่อนผังรอบใหม่รายงานเข้ามา)
    val lastKind = remember { arrayOf(p.item.kind) }
    if (lastKind[0] != p.item.kind) {
        reg.photos.remove(id)
        lastKind[0] = p.item.kind
    }
    val origin = remember { TileOrigin() }
    val sz = anim.size.value
    val pd = Placed(p.item, Rect(p.frame.topLeft, sz))
    val shape = RoundedCornerShape(chromeRadius(p.item.kind).dp)
    val typing = isTyping(id)
    val accent = theme.accent
    val flat = p.item.surface == WidgetSurface.glass

    Box(
        Modifier
            .offset {
                val o = anim.pos.value + srOffset.value
                IntOffset((o.x * density).roundToInt(), (o.y * density).roundToInt())
            }
            // ลำดับในลิสต์คือชั้นซ้อนจริง — ยกเว้นในโชว์รูม ซึ่งตัวที่แต่งอยู่ต้องอยู่หน้าสุด
            .zIndex(if (inShowroom) 400f else order.toFloat())
            // ตอนพิมพ์: ก้อนที่พิมพ์ถูกยกขึ้นกลางที่ว่าง · ที่เหลือถอยออกแล้วหรี่ลง (**ไม่เบลอ**)
            .graphicsLayer {
                scaleX = srScale.value
                scaleY = srScale.value
                alpha = srDim.value * appear.value
            }
            .pageChoreo(p.item.kind.entranceStyle, order, 0f, flat = flat)
            .graphicsLayer { alpha = if (isDrag) 0f else 1f }
            .onGloballyPositioned { origin.root = it.localToRoot(Offset.Zero) }
            .size(sz.width.dp, sz.height.dp),
    ) {
        CompositionLocalProvider(
            // เส้นประรอบข้อความที่แก้ได้ขึ้นเฉพาะบนแคนวาสในโหมดแต่ง
            LocalTextEditMode provides (isEditing && interactive),
            LocalPageScrub provides PageScrub(d = 0f, order = order, flat = flat),
            LocalCanvasTyping provides typing,
        ) {
            WidgetChrome(
                placed = pd,
                theme = theme,
                modifier = Modifier
                    .shadow(
                        elevation = (24f * pressK).dp, shape = shape, clip = false,
                        ambientColor = accent.opacity(0.45 * pressK), spotColor = accent.opacity(0.45 * pressK),
                    )
                    .pressTilt(touch, sz.width, sz.height),
            )

            // คง catcher ไว้ขณะที่มันถือการลากอยู่ — ถอดตรงนี้แล้ว event ปล่อยนิ้วหาย
            if ((interactive || isDrag) && hittable) {
                PressDragCatcher(
                    // ชิ้นที่เลือกอยู่ลากได้ทันที (ตอนพิมพ์ไม่มีผังให้ย้าย จึงไม่เปิด)
                    immediate = isSel && !dock.isText,
                    onBegan = { catcherBegan(pNow) },
                    onChanged = { t -> catcherChanged(pNow, t) },
                    onEnded = { catcherEnded(pNow) },
                    onTap = { at -> catcherTap(pNow, at, reg, origin) },
                    onPress = { at -> catcherPress(pNow, at) },
                    modifier = Modifier.matchParentSize(),
                )
            }
            if (isEditing && !isSel) EditHairline(p.item.kind)
            // ปุ่มเปลี่ยนรูปอยู่บนตัวรูปเลย — **เฉพาะตัวที่ถูกเลือก**
            if (isEditing && interactive && isSel && hittable) PhotoSlotButtons(p, reg, origin, sz)
            // ก้อนข้อความไม่มีเส้นประชั้นใน — ทั้งก้อนคือช่องเดียว กรอบเลือกบอกอยู่แล้ว
            if (isEditing && interactive) {
                TextSlotLayer(p, reg, origin, sz, focused = isSel && p.item.kind != WidgetKind.textBlock)
            }
            // ช่องพิมพ์บนการ์ด — ทับตำแหน่งก้อนพอดี อยู่เหนือ catcher จึงรับทัชวางเคอร์เซอร์ได้
            if (typing) CanvasEditor(p)
        }
    }
}

/** กระจกฝ้าคลุมทั้งหน้าตอนพิมพ์ — มืดสำหรับหมึกกลางคืน สว่างสำหรับกระดาษ · ไม่กินทัช */
@Composable
private fun CardEditorState.TypingVeil() {
    val light = theme.inkStyle.isLight
    // มุมมนเฉพาะปลายกระดาษ — ช่องกลางของแผ่นต่อเนื่องไม่มีมุม
    val r = 22f / max(pageFit, 0.01f)
    val lead = if (index == 0) r else 0f
    val trail = if (index == pages.size - 1) r else 0f
    val shape = RoundedCornerShape(topStart = lead.dp, bottomStart = lead.dp, topEnd = trail.dp, bottomEnd = trail.dp)
    Box(
        Modifier
            .fillMaxSize()
            .background(if (light) Color.White.opacity(0.62) else Color.Black.opacity(0.42), shape)
            .background(if (light) Color.White.opacity(0.28) else Color.Black.opacity(0.30), shape),
    )
}

/** ช่องพิมพ์ทับก้อนข้อความ — ขนาดเท่ากล่องแก้ไข · เลื่อนให้ **หมึก** ชิดมุมบนซ้ายของกล่อง (หักขอบ) */
@Composable
private fun CardEditorState.CanvasEditor(p: Placed) {
    val e = editBox(p)
    CanvasTextField(
        id = TextSlotID(field = ProfileField.note, widget = p.item.id),
        style = p.item.textStyle,
        ink = theme.inkStyle,
        accent = theme.accent,
        size = e.points,
        modifier = Modifier
            .offset((TextBlockSpec.inset - e.m.ink.left).dp, (TextBlockSpec.inset - e.m.ink.top).dp)
            .size(e.m.typo.width.dp, e.m.typo.height.dp),
    )
}

/** กรอบประจำชิ้นในโหมดแต่ง — **เส้นประ ไม่ใช่เส้นจาง** · เข้มขึ้นชั่วครู่ตอนเพิ่งเข้า */
@Composable
private fun CardEditorState.EditHairline(kind: WidgetKind) {
    val k by animateFloatAsState(if (editReveal) 1f else 0f, Motion.settle.float, label = "reveal")
    val accent = theme.accent
    val r = chromeRadius(kind)
    Box(
        Modifier.fillMaxSize().drawBehind {
            strokeBorder(
                accent.opacity(0.42 + 0.43 * k),
                (1f + 0.4f * k).dp.toPx(),
                r.dp.toPx(),
                floatArrayOf(4.5.dp.toPx(), 3.5.dp.toPx()),
            )
        },
    )
}

/**
 * ปุ่มเปลี่ยนรูปหนึ่งปุ่มต่อหนึ่งช่องรูป — อ่านตำแหน่งช่องจากทะเบียนที่ตัว widget ประกาศไว้
 * เรียงบนลงล่าง ซ้ายไปขวา — ลำดับที่รูปจะไหลลงช่องเวลาเลือกมาทีเดียวหลายใบ
 */
@Composable
private fun CardEditorState.PhotoSlotButtons(p: Placed, reg: SlotRegistry, origin: TileOrigin, sz: Size) {
    val store = photos ?: return
    // ทะเบียนไม่ใช่ state — อ่านใหม่หลังผังรอบที่เพิ่งวางรายงานกรอบเข้ามา
    var tick by remember { mutableIntStateOf(0) }
    LaunchedEffect(sz, p.frame) {
        withFrameNanos { }
        withFrameNanos { }
        tick += 1
    }
    val slots = remember(tick) { reg.photos[p.item.id]?.toList() ?: emptyList() }
    if (slots.isEmpty()) return
    val o = reg.pageOf(origin.root)
    val sorted = slots
        .map { it.index to it.rect.translate(-o.x, -o.y) }
        .sortedWith { a, b ->
            if (a.second.top == b.second.top) a.second.left.compareTo(b.second.left) else a.second.top.compareTo(b.second.top)
        }
    val order = sorted.map { it.first }
    Box(Modifier.fillMaxSize()) {
        sorted.forEach { (slot, r) ->
            key(slot) {
                // ช่องที่กำลังจัดกรอบอยู่เปลี่ยนเป็นแผ่นลากทับทั้งช่อง — ปุ่มหายไปชั่วคราว
                if (store.framing == PhotoSlotRef(p.item.id, slot)) {
                    PhotoFitSurface(
                        theme = theme, widgetID = p.item.id, slot = slot, size = r.size,
                        modifier = Modifier.offset(r.left.dp, r.top.dp).size(r.width.dp, r.height.dp),
                    )
                } else {
                    // ชิดขวาบนของช่อง — ป้ายใต้ปุ่มกินราว 130pt ช่องที่แคบกว่านั้นเหลือแค่ไอคอน
                    Box(
                        Modifier.offset(r.left.dp, r.top.dp).size(r.width.dp, r.height.dp).padding(5.dp),
                        contentAlignment = Alignment.TopEnd,
                    ) {
                        PhotoSlotButton(
                            theme = theme, widgetID = p.item.id, slot = slot, order = order,
                            labelled = r.width >= 132f, scale = canvasScale,
                        )
                    }
                }
            }
        }
    }
}

/**
 * ชั้นข้อความที่แก้ได้ของ widget หนึ่งตัว — เส้นประรอบช่องที่แตะได้ (เฉพาะชิ้นที่โฟกัส) · กรอบทึบของช่องที่กำลังพิมพ์
 * ตัวรับทัชไม่อยู่ที่นี่ — ทะเบียนกรอบใช้ตัดสินตอน `onTap`
 */
@Composable
private fun CardEditorState.TextSlotLayer(p: Placed, reg: SlotRegistry, origin: TileOrigin, sz: Size, focused: Boolean) {
    var tick by remember { mutableIntStateOf(0) }
    val editing = Profile.me.editing
    LaunchedEffect(sz, p.frame, focused, editing) {
        withFrameNanos { }
        withFrameNanos { }
        tick += 1
    }
    val slots = remember(tick) { reg.text[p.item.id]?.toList() ?: emptyList() }
    val active = slots.firstOrNull { it.id == editing }
    if (!focused && active == null) return
    val o = reg.pageOf(origin.root)
    val accent = theme.accent
    Box(Modifier.fillMaxSize()) {
        if (focused) {
            slots.filter { it.id != active?.id }.forEachIndexed { i, slot ->
                key(i) {
                    val r = slot.rect.translate(-o.x, -o.y)
                    val box = upright(r.size, slot.style.tilt)
                    val w = box.width + 6f
                    val h = box.height + 6f
                    TextSlotDashes(
                        style = slot.style,
                        accent = accent,
                        modifier = Modifier
                            .offset((r.center.x - w / 2f).dp, (r.center.y - h / 2f).dp)
                            .size(w.dp, h.dp)
                            .rotate(slot.style.tilt.toFloat()),
                    )
                }
            }
        }
        // ช่องที่กำลังพิมพ์ — กรอบทึบ + พื้นจาง บอกว่าตัวอักษรที่วิ่งอยู่คือก้อนนี้
        if (active != null) {
            val r = active.rect.translate(-o.x, -o.y)
            val box = upright(r.size, active.style.tilt)
            val w = box.width + 8f
            val h = box.height + 8f
            val shape = RoundedCornerShape((active.style.corner + 3f).dp)
            Box(
                Modifier
                    .offset((r.center.x - w / 2f).dp, (r.center.y - h / 2f).dp)
                    .size(w.dp, h.dp)
                    .rotate(active.style.tilt.toFloat())
                    .background(accent.opacity(0.18), shape)
                    .border(1.2.dp, accent, shape),
            )
        }
    }
}

// MARK: - กรอบเลือก + หมุด

/** กรอบเลือก + หมุดปรับขนาด — วาดที่ชั้นบนสุดของหน้า จึงไม่ถูก widget ที่ทับอยู่กลืน */
@Composable
private fun CardEditorState.SelectionLayer(sel: Placed, anim: TileAnim, interactive: Boolean) {
    val memo = remember { SelMemo() }
    val hPos = remember { Animatable(Offset.Zero, Offset.VectorConverter) }
    val hSize = remember { Animatable(Offset.Zero, Offset.VectorConverter) }
    val fade = remember { Animatable(0f) }
    LaunchedEffect(fade) { fade.animateTo(1f, Motion.settle.float) }
    val pos = anim.pos.value
    val sz = anim.size.value
    // ให้กรอบไหลจาก widget เดิมไปตัวใหม่ แทนที่จะกระพริบหายแล้วโผล่
    val from = if (memo.id != null && memo.id != sel.id) memo.rect else null
    LaunchedEffect(sel.id) {
        if (from != null) {
            hPos.snapTo(from.topLeft - pos)
            hSize.snapTo(Offset(from.width - sz.width, from.height - sz.height))
            launch { hPos.animateTo(Offset.Zero, Motion.settle.spec()) }
            hSize.animateTo(Offset.Zero, Motion.settle.spec())
        }
    }
    SideEffect {
        memo.id = sel.id
        memo.rect = Rect(pos, sz)
    }
    val w = sz.width + hSize.value.x
    val h = sz.height + hSize.value.y
    val ov = if (resizeID == sel.id) overshoot else Offset.Zero
    val accent = theme.accent
    val radius = chromeRadius(sel.item.kind)
    val kind = sel.item.kind

    Box(
        Modifier
            .offset {
                val o = pos + hPos.value
                IntOffset((o.x * density).roundToInt(), (o.y * density).roundToInt())
            }
            .zIndex(500f)
            .graphicsLayer { alpha = fade.value }
            // ยืดเฉพาะกรอบ ไม่แตะตัว widget
            .size(max(0f, w + ov.x).dp, max(0f, h + ov.y).dp),
    ) {
        Box(
            Modifier
                .wrapContentSize(Alignment.TopStart, unbounded = true)
                .requiredSize(max(0f, w).dp, max(0f, h).dp),
        ) {
            Box(
                Modifier
                    .matchParentSize()
                    .blur(5.dp, BlurredEdgeTreatment.Unbounded)
                    .drawBehind { strokeBorder(accent.opacity(0.18), 7.dp.toPx(), radius.dp.toPx()) },
            )
            Box(Modifier.matchParentSize().drawBehind { strokeBorder(accent, 1.5.dp.toPx(), radius.dp.toPx()) })
            // จุดมุมสี่จุดบอกว่า "ขอบลากได้" — ก้อนข้อความไม่มีหมุดขอบ
            if (kind != WidgetKind.textBlock) {
                listOf(Offset(0f, 0f), Offset(w, 0f), Offset(0f, h), Offset(w, h)).forEach { c ->
                    Box(
                        Modifier
                            .offset((c.x - 4f).dp, (c.y - 4f).dp)
                            .size(8.dp)
                            .shadow(3.dp, CircleShape, clip = false, ambientColor = Color.Black.opacity(0.4), spotColor = Color.Black.opacity(0.4))
                            .background(Color.White, CircleShape)
                            .border(1.6.dp, accent, CircleShape),
                    )
                }
            }
            // **สองหมุด หนึ่งความหมายต่อหมุด** — ขอบขวา = กว้าง · ขอบล่าง = สูง
            if (interactive && kind.canResize) {
                WidthHandle(sel, Modifier.align(Alignment.CenterEnd))
                HeightHandle(sel, Modifier.align(Alignment.BottomCenter))
            }
            // ก้อนข้อความยังมีหมุดมุม — แต่ของมันปรับ *ขนาดตัวอักษร* แล้วกล่องวิ่งตามตัวอักษร
            if (interactive && kind == WidgetKind.textBlock) CornerHandle(sel, Modifier.align(Alignment.BottomEnd))
        }
    }
}

/** ลากหมุด — ระยะสะสมในพิกัดหน้า (ไม่ใช่ของหมุด ซึ่งเกาะขอบที่กำลังยืดอยู่) */
private fun Modifier.handleDrag(key: Any, onDrag: (Offset) -> Unit, onEnd: () -> Unit): Modifier =
    pointerInput(key) {
        awaitEachGesture {
            val down = awaitFirstDown(requireUnconsumed = false)
            down.consume()
            var total = Offset.Zero
            var moved = false
            while (true) {
                val ev = awaitPointerEvent()
                val ch = ev.changes.firstOrNull { it.id == down.id } ?: break
                if (!ch.pressed) break
                val d = ch.positionChange()
                if (d != Offset.Zero) {
                    total += d / density
                    if (!moved && total.getDistance() >= 1f) moved = true
                    if (moved) onDrag(total)
                    ch.consume()
                }
            }
            if (moved) onEnd()
        }
    }

/** หมุดขอบขวา — นั่งนอกกรอบ 11pt ไม่ใช่คร่อมขอบ */
@Composable
private fun CardEditorState.WidthHandle(p: Placed, modifier: Modifier) {
    val pNow by rememberUpdatedState(p)
    HandleGrip(
        theme = theme,
        axis = GripAxis.horizontal,
        modifier = modifier
            .offset(x = 20.dp)
            .handleDrag(p.id, onDrag = { t -> resizeWidth(pNow, t) }, onEnd = {
                endResize()
                Haptics.medium()
            }),
    )
}

/** หมุดขอบล่าง — **ความสูงอย่างเดียว** */
@Composable
private fun CardEditorState.HeightHandle(p: Placed, modifier: Modifier) {
    val pNow by rememberUpdatedState(p)
    HandleGrip(
        theme = theme,
        axis = GripAxis.vertical,
        modifier = modifier
            .offset(y = 20.dp)
            .handleDrag(p.id, onDrag = { t -> resizeHeight(pNow, t) }, onEnd = {
                endResize()
                Haptics.medium()
            }),
    )
}

/** หมุดมุมของก้อนข้อความ — นั่ง **นอก** มุมกล่อง (ศูนย์กลางเลยมุมออกไป 8pt) ไม่ทับตัวอักษร */
@Composable
private fun CardEditorState.CornerHandle(p: Placed, modifier: Modifier) {
    val pNow by rememberUpdatedState(p)
    CornerGrip(
        accent = theme.accent,
        modifier = modifier
            .offset(30.dp, 30.dp)
            .handleDrag(p.id, onDrag = { t -> resizeCorner(pNow, t) }, onEnd = {
                endResize()
                Haptics.medium()
            }),
    )
}

/** หน้าตาของหมุดมุม — วงขาวกับลูกศรทแยง */
@Composable
private fun CornerGrip(accent: Color, modifier: Modifier = Modifier) {
    Box(modifier.size(44.dp), contentAlignment = Alignment.Center) {
        Box(
            Modifier
                .size(22.dp)
                .shadow(3.dp, CircleShape, clip = false, ambientColor = Color.Black.opacity(0.4), spotColor = Color.Black.opacity(0.4))
                .background(Color.White, CircleShape)
                .border(1.6.dp, accent, CircleShape),
        )
        SFSymbol("arrow.up.left.and.arrow.down.right", size = 10f, tint = accent)
    }
}

/** ชั้นลอยของตัวที่ลาก — ยกขึ้น 1.05 พร้อมเงา · ไม่รับทัช */
@Composable
private fun CardEditorState.DragLayer(item: WidgetInstance) {
    val k by animateFloatAsState(if (lifted) 1f else 0f, Motion.lift.float, label = "lift")
    val start = dragStart
    val shape = RoundedCornerShape(chromeRadius(item.kind).dp)
    Box(
        Modifier
            .offset {
                val t = dragTranslation
                IntOffset(((start.left + t.x) * density).roundToInt(), ((start.top + t.y) * density).roundToInt())
            }
            .zIndex(200f)
            .graphicsLayer {
                val s = 1f + 0.05f * k
                scaleX = s
                scaleY = s
            }
            .shadow(
                elevation = (30f * k).dp, shape = shape, clip = false,
                ambientColor = Color.Black.opacity(0.55 * k), spotColor = Color.Black.opacity(0.55 * k),
            )
            .size(start.width.dp, start.height.dp)
            .border(1.5.dp, theme.accent, shape),
    ) {
        CompositionLocalProvider(LocalSlotRegistry provides null, LocalTextEditMode provides false) {
            WidgetChrome(placed = Placed(item, start), theme = theme)
        }
    }
}

// MARK: - Chrome (แถบบน)

/** กระจกของเวที (= `.glassEffect(.regular…)`) — แผงเครื่องมือนั่งบนเวทีมืด ไม่ใช่บนการ์ด */
@Composable
private fun StageGlass(radius: Float, tint: Color? = null, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalCardInk provides InkStyle.night) {
        GlassPanel(
            tint = tint,
            tintStrength = if (tint != null) 0.88 else 0.16,
            veil = Color.White.opacity(0.10),
            radius = radius,
            interactive = true,
            modifier = modifier,
            content = content,
        )
    }
}

/**
 * แถบบน — **สามคอลัมน์กว้างเท่ากัน** ตัวบอกช่องจึงอยู่กลางจอเป๊ะ
 * ซ้าย = ของรอง (กลับคลัง · ↶ ↷) · ขวา = **ปุ่มเดียว** คือแชร์ เป็นวงกลมทึบสีเน้น
 */
@Composable
private fun CardEditorState.TopBar() {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 15.dp)
            .padding(top = 4.dp)
            .padding(horizontal = 14.dp, vertical = 9.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            Modifier.weight(1f),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (viewOnly) {
                onClose?.let { CloseButton(it) }
                StageMark()
            } else {
                val go = onChangeFormat
                // ทางกลับคลัง — โผล่เฉพาะแถบหลัก
                AnimatedVisibility(
                    visible = dock.isMain && go != null,
                    enter = fadeIn(Motion.settle.spec()) + scaleIn(Motion.settle.spec(), initialScale = 0.8f),
                    exit = fadeOut(Motion.settle.spec()) + scaleOut(Motion.settle.spec(), targetScale = 0.8f),
                ) { if (go != null) LibraryButton(go) }
                UndoRedo()
            }
        }
        if (multiPage) PageDots()
        Row(Modifier.weight(1f), horizontalArrangement = Arrangement.End) {
            // โหมดดูไม่มีปุ่มขอใบเสนอราคา — แชร์ย้ายมาขวาแทน
            ShareButton(prominent = !viewOnly)
        }
    }
}

/** ทางกลับคลัง — ไอคอนคลัง ไม่ใช่ ‹ (‹ บนจอต้องมีตัวเดียวคือตัวที่หัวชีต) */
@Composable
private fun CardEditorState.LibraryButton(go: () -> Unit) {
    StageGlass(radius = 20f, modifier = Modifier.dockPress { leaveToLibrary(go) }) {
        Box(Modifier.size(40.dp).semantics { contentDescription = "กลับคลังการ์ด" }, contentAlignment = Alignment.Center) {
            SFSymbol("square.grid.2x2", size = 15f, tint = Color.White.opacity(0.92))
        }
    }
}

/** ปิดหน้าดู — โผล่เฉพาะตอนเปิดจากคลัง ("ดูแบบที่แบรนด์เห็น") */
@Composable
private fun CloseButton(action: () -> Unit) {
    StageGlass(radius = 20f, modifier = Modifier.dockPress {
        Haptics.light()
        action()
    }) {
        Box(Modifier.size(40.dp).semantics { contentDescription = "ปิด" }, contentAlignment = Alignment.Center) {
            SFSymbol("xmark", size = 14f, tint = Color.White.opacity(0.92))
        }
    }
}

/** ตราของเวที — มุมซ้ายบนของหน้าดู · มันบอกว่า "ที่นี่คือ Sale Here" ไม่ได้บอกว่าการ์ดเป็นของใคร */
@Composable
private fun StageMark() {
    StageGlass(radius = 20f) {
        Box(Modifier.height(40.dp).padding(horizontal = 13.dp), contentAlignment = Alignment.Center) {
            StarLockup(height = 13f, tint = Color.White.opacity(0.92))
        }
    }
}

/** ท้ายหน้าดู — ปุ่ม "ติดต่อ" ปุ่มเดียว · แคปซูลกระจกสูง 54 */
@Composable
private fun CardEditorState.ViewerFooter() {
    StageGlass(
        radius = 27f,
        modifier = Modifier
            .padding(horizontal = 20.dp)
            .padding(bottom = 10.dp)
            .dockPress {
                Haptics.medium()
                showContact = true
            },
    ) {
        Row(
            Modifier.fillMaxWidth().height(54.dp).semantics { contentDescription = "ติดต่อ" },
            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            SymbolIcon(SHIcon.addressBook, size = 18f, tint = Color.White)
            Text("ติดต่อ", style = sh(15f, SHFont.semibold), color = Color.White)
        }
    }
}

/** มุมขวาบนตอนพิมพ์ — คำเดียว ไม่มีกระจก ไม่มีอะไรแย่งตาจากตัวอักษร */
@Composable
private fun CardEditorState.TextTopBar() {
    Row(Modifier.fillMaxWidth().padding(horizontal = 10.dp).padding(top = 4.dp)) {
        Spacer(Modifier.weight(1f))
        Box(Modifier.dockPress { exitTextMode() }.padding(horizontal = 14.dp, vertical = 10.dp)) {
            Text("เสร็จ", style = sh(16f, SHFont.bold), color = Color.White)
        }
    }
}

/** ↶ ↷ ในแคปซูลเดียว — ปุ่มที่ย้อนไม่ได้ไม่ได้หายไป แค่จาง */
@Composable
private fun CardEditorState.UndoRedo() {
    val undoA by animateFloatAsState(if (history.canUndo) 1f else 0.32f, Motion.snap.float, label = "undo")
    val redoA by animateFloatAsState(if (history.canRedo) 1f else 0.32f, Motion.snap.float, label = "redo")
    val tint = Color.White.opacity(0.9)
    StageGlass(radius = 20f) {
        Row(Modifier.padding(horizontal = 2.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(38.dp, 40.dp).alpha(undoA).tap { undo() }.semantics { contentDescription = "เลิกทำ" },
                contentAlignment = Alignment.Center,
            ) {
                // ไอคอนวนตามเข็มกลับด้าน = ทวนเข็ม
                SFSymbol("arrow.uturn.backward", size = 13f, tint = tint, modifier = Modifier.graphicsLayer { scaleX = -1f })
            }
            Box(Modifier.size(1.dp, 14.dp).background(Color.White.opacity(0.18)))
            Box(
                Modifier.size(38.dp, 40.dp).alpha(redoA).tap { redo() }.semantics { contentDescription = "ทำซ้ำ" },
                contentAlignment = Alignment.Center,
            ) {
                SFSymbol("arrow.uturn.forward", size = 13f, tint = tint)
            }
        }
    }
}

/** ตัวบอกช่อง — **สามช่องติดกันเป็นแถบเดียว** ไม่ใช่จุดสามจุด · แตะช่องไหนเลื่อนไปช่องนั้น */
@Composable
private fun CardEditorState.PageDots() {
    Row(
        Modifier.semantics { contentDescription = "ช่อง ${index + 1} จาก ${pages.size}" },
        horizontalArrangement = Arrangement.spacedBy(1.dp),
    ) {
        pages.forEachIndexed { i, page ->
            key(page.id) {
                val on = i == index
                val first = i == 0
                val last = i == pages.size - 1
                val shape = RoundedCornerShape(
                    topStart = if (first) 3.dp else 0.dp, bottomStart = if (first) 3.dp else 0.dp,
                    topEnd = if (last) 3.dp else 0.dp, bottomEnd = if (last) 3.dp else 0.dp,
                )
                val fill by animateColorAsState(
                    if (on) Color.White.opacity(0.95) else Color.White.opacity(0.2), Motion.snap.spec(), label = "dot",
                )
                val rim by animateColorAsState(Color.White.opacity(if (on) 0.0 else 0.4), Motion.snap.spec(), label = "dotRim")
                Box(
                    Modifier.size(12.dp, 30.dp).tap {
                        setIndex(i, Motion.page)
                        Haptics.light()
                    },
                    contentAlignment = Alignment.Center,
                ) {
                    Box(Modifier.size(11.dp, 18.dp).background(fill, shape).border(0.6.dp, rim, shape))
                }
            }
        }
    }
}

/** ปุ่มเด่นปุ่มเดียวบนแถบบน — แชร์คือเป้าหมายของทั้งหน้า */
@Composable
private fun CardEditorState.ShareButton(prominent: Boolean) {
    StageGlass(radius = 20f, tint = if (prominent) theme.rawAccent else null, modifier = Modifier.dockPress { share() }) {
        Box(Modifier.size(40.dp).semantics { contentDescription = "แชร์การ์ด" }, contentAlignment = Alignment.Center) {
            // ยกขึ้นหนึ่งพอยต์เพราะน้ำหนักของรูปอยู่ด้านล่าง
            SFSymbol(
                "square.and.arrow.up", size = 16f,
                tint = if (prominent) Color.Black.opacity(0.85) else Color.White.opacity(0.92),
                modifier = Modifier.offset(y = (-1).dp),
            )
        }
    }
}

// MARK: - แถบล่าง

/**
 * ก้อนขอบล่างทั้งก้อน — dock + ถาด หรือแผ่นพิมพ์เหนือคีย์บอร์ด · ความสูงส่งให้ `bottomUI`
 * ซ้อนกัน — สลับแถบหลัก ↔ ชีต แล้วของเก่าจางออก ของใหม่จางเข้า **ทับกัน**
 */
@Composable
private fun CardEditorState.BottomChrome() {
    val sel = selectedItem
    val editingID = Profile.me.editing
    val showTools = dock.isText && sel != null
    val showBar = !showTools && editingID != null
    val rest = !showTools && !showBar
    val showMain = rest && dock.isMain
    val showBackdrop = rest && dock == DockBackdrop
    val showGallery = rest && dock == DockGallery
    val showPiece = rest && dock.isPiece && sel != null
    val toolsSel = rememberLast(if (showTools) sel else null)
    val barID = rememberLast(if (showBar) editingID else null)
    val pieceSel = rememberLast(if (showPiece) sel else null)
    val full = remember(pages, pageSize) { cardIsFull() }
    // แผ่นพิมพ์ต้องนั่งบนคีย์บอร์ดพอดี — กรอบคีย์บอร์ดวัดจากก้นหน้าต่าง แต่ก้อนนี้อยู่เหนือแถบระบบแล้ว
    val pad = if (editingID != null || dock.isText) max(0f, keyboard - safeBottom) else 6f
    val s = Motion.settle
    val nudge = (24f * density).roundToInt()

    Box(
        Modifier
            .fillMaxWidth()
            .onSizeChanged { bottomUI = it.height / density }
            .padding(bottom = pad.dp),
        contentAlignment = Alignment.BottomCenter,
    ) {
        AnimatedVisibility(
            visible = showTools,
            enter = slideInVertically(s.spec()) { it } + fadeIn(s.spec()),
            exit = slideOutVertically(s.spec()) { it } + fadeOut(s.spec()),
        ) {
            val t = toolsSel
            if (t != null) {
                TextTools(
                    theme = theme,
                    style = t.textStyle,
                    onStyle = { change -> setTextStyle(t, change) },
                    onDelete = {
                        endTextEdit()
                        deleteWidget(t)
                    },
                    modifier = Modifier.onSizeChanged { toolsH = it.height / density },
                )
            }
        }
        AnimatedVisibility(
            visible = showBar,
            enter = slideInVertically(s.spec()) { it } + fadeIn(s.spec()),
            exit = slideOutVertically(s.spec()) { it } + fadeOut(s.spec()),
        ) {
            val id = barID
            if (id != null) {
                // เครื่องมือของ **ช่องที่กำลังแก้** — ฟอนต์ สี ขนาด เก็บที่ชิ้นที่ถูกเลือกอยู่
                val item = selectedItem
                val onStyle: (((WidgetTextStyle) -> WidgetTextStyle) -> Unit)? = if (item != null) {
                    { change: (WidgetTextStyle) -> WidgetTextStyle -> setTextStyle(item, change) }
                } else {
                    null
                }
                TextEditBar(id = id, theme = theme, style = item?.textStyle, onStyle = onStyle, onDone = { endTextEdit() })
            }
        }
        // แถบหลักเข้า/ออก — ขยับนิดเดียวพอ มันคือของที่ "หลบ" ให้ชีต
        AnimatedVisibility(
            visible = showMain,
            enter = slideInVertically(s.spec()) { nudge } + fadeIn(s.spec()),
            exit = slideOutVertically(s.spec()) { nudge } + fadeOut(s.spec()),
        ) {
            EditorDock(
                dimmed = if (full) setOf(DockMainItem.text, DockMainItem.widget) else emptySet(),
                onMain = { mainAction(it) },
            )
        }
        // ชีตเข้า/ออก — **ไหลขึ้นมาจากขอบล่างทั้งใบ** เหมือน bottom sheet จริง
        AnimatedVisibility(
            visible = showBackdrop,
            enter = slideInVertically(s.spec()) { it } + fadeIn(s.spec()),
            exit = slideOutVertically(s.spec()) { it } + fadeOut(s.spec()),
        ) {
            DockSheet(title = "พื้นหลัง", symbol = "paintpalette.fill", viewport = viewportH, onBack = { goMain() }) {
                BackdropTray()
            }
        }
        AnimatedVisibility(
            visible = showGallery,
            enter = slideInVertically(s.spec()) { it } + fadeIn(s.spec()),
            exit = slideOutVertically(s.spec()) { it } + fadeOut(s.spec()),
        ) {
            DockSheet(title = "เพิ่มวิดเจ็ต", symbol = "plus.square.on.square", viewport = viewportH, fill = true, onBack = { goMain() }) {
                GalleryTray(full)
            }
        }
        AnimatedVisibility(
            visible = showPiece,
            enter = slideInVertically(s.spec()) { it } + fadeIn(s.spec()),
            exit = slideOutVertically(s.spec()) { it } + fadeOut(s.spec()),
        ) {
            val p = pieceSel
            if (p != null) {
                // หัวชีต — ชื่อ **เรื่อง** (หมวดของชิ้น) ไม่ใช่ชื่อแบบ
                DockSheet(title = p.kind.family.label, symbol = p.kind.symbol, viewport = viewportH, onBack = { goMain() }) {
                    PieceTray(p)
                }
            }
        }
    }
}

/** แถบข้อความชั่วคราวเหนือขอบล่าง — ชนิดรายงานสถานะไม่รับสัมผัส */
@Composable
private fun CardEditorState.NoticeBar() {
    val n = notice
    val shown = rememberLast(n)
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.BottomCenter) {
        AnimatedVisibility(
            visible = n != null,
            enter = slideInVertically(Motion.snap.spec()) { it } + fadeIn(Motion.snap.spec()),
            exit = slideOutVertically(Motion.snap.spec()) { it } + fadeOut(Motion.snap.spec()),
        ) {
            val m = n ?: shown ?: return@AnimatedVisibility
            Row(
                Modifier
                    .padding(horizontal = 24.dp)
                    .padding(bottom = ((if (isEditing) bottomUI else 0f) + 12f).dp)
                    .background(Color.Black.opacity(0.72), RoundedCornerShape(percent = 50))
                    .padding(horizontal = 16.dp, vertical = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    m.text,
                    style = sh(12.5f, SHFont.semibold),
                    color = Color.White.opacity(0.94),
                    textAlign = TextAlign.Start,
                    modifier = Modifier.weight(1f, fill = false),
                )
                val title = m.actionTitle
                val act = m.action
                if (title != null && act != null) {
                    Box(Modifier.tap {
                        clearNotice()
                        act()
                    }) {
                        Text(title, style = sh(12.5f, SHFont.bold), color = theme.rawAccent)
                    }
                } else if (m.kind == CardNotice.Kind.warning) {
                    Box(Modifier.size(22.dp).tap { clearNotice() }, contentAlignment = Alignment.Center) {
                        SFSymbol("xmark", size = 10f, tint = Color.White.opacity(0.55))
                    }
                }
            }
        }
    }
}

// MARK: - หัวข้อและตัวเลือกในชีต

/** หัวข้อของแต่ละเรื่องในชีต — ชิดซ้าย ตัวใหญ่ ทุกเรื่องใช้ตัวเดียวกัน */
@Composable
private fun SectionTitle(text: String) {
    Text(
        text,
        style = sh(13.5f, SHFont.semibold),
        color = Color.White.opacity(0.72),
        maxLines = 1,
        softWrap = false,
        autoSize = autoShrink(13.5f, 0.7f),
        modifier = Modifier.fillMaxWidth(),
    )
}

/** เรื่องหนึ่งเรื่องในชีต — หัวข้อชิดซ้าย แล้วตัวเลือกอยู่ใต้หัวข้อ */
@Composable
private fun Section(title: String, content: @Composable () -> Unit) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        SectionTitle(title)
        content()
    }
}

/** เปลือกของตัวเลือกหนึ่งตัว — ตัวอย่างจริงนำหน้า ชื่อตามหลัง */
@Composable
private fun OptionChip(name: String, on: Boolean, modifier: Modifier = Modifier, preview: @Composable () -> Unit) {
    val previewShape = RoundedCornerShape(3.5.dp)
    Row(
        modifier
            .background(if (on) Color.White.opacity(0.92) else Color.White.opacity(0.08), RoundedCornerShape(9.dp))
            .padding(horizontal = 6.dp, vertical = 4.5.dp),
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(24.dp, 17.dp).clip(previewShape).border(0.5.dp, Color.White.opacity(0.22), previewShape)) {
            preview()
        }
        Text(
            name,
            style = sh(9.5f, SHFont.semibold),
            color = if (on) Color.Black.opacity(0.85) else Color.White.opacity(0.7),
            maxLines = 1,
            softWrap = false,
        )
    }
}

// MARK: - ถาดพื้นหลัง

/**
 * ถาดพื้นหลัง — เห็นครบไม่ต้องเลื่อน: แบบพื้น · สี (หรือรูป) · โทน
 * เลือกรูปเมื่อไหร่ แถวสีกลายเป็นแถวรูป และโทนถูกล็อก — แถวโทนไม่หาย แค่จางลง
 */
@Composable
private fun CardEditorState.BackdropTray() {
    val store = photos
    val isPhoto = theme.backdrop == BackdropStyle.photo
    val hasBg = store?.background != null
    Column(
        Modifier.fillMaxWidth().animateContentSize(Motion.settle.spec()),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        // ขึ้นบรรทัดเองเมื่อชิปเต็มแถว — แต่ถาดนี้ห้ามเลื่อน: แบบพื้นที่มองไม่เห็นคือแบบที่ไม่มีใครกด
        FlowLayout(spacing = 7f, modifier = Modifier.fillMaxWidth()) {
            BackdropStyle.entries.forEach { st ->
                OptionChip(
                    st.displayName,
                    on = theme.backdrop == st,
                    modifier = Modifier.tap {
                        var t = theme.copy(backdrop = st)
                        // หมึกของพื้นรูปตัดสินจากรูปจริง — วัดในจังหวะเดียวกับที่สลับ
                        if (st == BackdropStyle.photo) t = t.copy(photoLean = store?.luma(t.photoEffect)?.lean)
                        setTheme(t)
                        Haptics.light()
                    },
                ) { BackdropSwatch(theme, st) }
            }
        }

        if (isPhoto) {
            BackdropPhotoSource()
            // เอฟเฟกต์กับความจางมีความหมายก็ต่อเมื่อมีรูปของผู้ใช้อยู่จริง
            if (hasBg) {
                DockRow(label = "เอฟเฟกต์") {
                    DockSegment(
                        options = BackdropEffect.entries.map { segOpt(it, it.displayName) },
                        selection = theme.photoEffect,
                        onPick = { fx ->
                            // เบลอ/จุดปะเปลี่ยนความสว่างของรูปจริง — หมึกที่เหมาะอาจเปลี่ยนฝั่งตาม
                            setTheme(theme.copy(photoEffect = fx, photoLean = store?.luma(fx)?.lean))
                            Haptics.light()
                        },
                    )
                }
                DockRow(label = "ความจาง") {
                    TrackSlider(
                        value = theme.photoDim / 0.8,
                        tint = theme.rawAccent,
                        onChange = { v -> setTheme(theme.copy(photoDim = min(0.8, max(0.0, v * 0.8)))) },
                    )
                }
            }
        } else {
            ColorRow()
            AnimatedVisibility(
                visible = colorOpen,
                enter = fadeIn(Motion.settle.spec()) + expandVertically(Motion.settle.spec()) +
                    slideInVertically(Motion.settle.spec()) { (-8f * density).roundToInt() },
                exit = fadeOut(Motion.settle.spec()) + shrinkVertically(Motion.settle.spec()) +
                    slideOutVertically(Motion.settle.spec()) { (-8f * density).roundToInt() },
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    val cur = theme.backdropHSB
                    SpectrumPicker(hue = cur.h, sat = cur.s, bri = cur.b, onChange = { h, s, b ->
                        setTheme(theme.setBackdropColor(h, s, b))
                        myColor = HSB(h, s, b)
                    })
                    HexField()
                }
            }
        }

        // มุมกับแถบผู้ออกบัตรไม่ใช่ของที่ต้องถาม — ค่าตั้งต้นของธีมตัดสินให้
        ToneRow()
        SignatureRow()
    }
}

/** แถวสี — "สีของฉัน" ซ้าย (ตัวเลือกสีเอง + สีที่เคยตั้ง) · "สำเร็จรูป" ขวา */
@Composable
private fun CardEditorState.ColorRow() {
    Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("สีของฉัน", style = sh(10.5f, SHFont.semibold), color = Color.White.opacity(0.45))
            Row(horizontalArrangement = Arrangement.spacedBy(9.dp), verticalAlignment = Alignment.CenterVertically) {
                // ตัวเลือกสีเอง — กางแถบสเปกตรัมใต้แถวนี้ (ถาดยืด ไม่ใช่สลับหน้า)
                val open = colorOpen
                Box(
                    Modifier
                        .size(30.dp)
                        .tap {
                            colorOpen = !colorOpen
                            Haptics.light()
                        }
                        .semantics { contentDescription = "เลือกสีเอง" }
                        .background(Color.White.opacity(if (open) 0.2 else 0.04), CircleShape)
                        .drawBehind {
                            val sw = 1.dp.toPx()
                            drawCircle(
                                Color.White.opacity(0.55),
                                radius = size.minDimension / 2f - sw / 2f,
                                style = Stroke(sw, pathEffect = PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(), 2.5.dp.toPx()))),
                            )
                        },
                    contentAlignment = Alignment.Center,
                ) { SFSymbol("eyedropper", size = 11f, tint = Color.White.opacity(0.85)) }

                val c = myColor
                if (c != null) {
                    val active = theme.hasCustomColor
                    val sc by animateFloatAsState(if (active) 1.1f else 1f, Motion.snap.float, label = "myColor")
                    Box(
                        Modifier
                            .size(30.dp)
                            .graphicsLayer {
                                scaleX = sc
                                scaleY = sc
                            }
                            .tap {
                                setTheme(theme.setBackdropColor(c.h, c.s, c.b))
                                Haptics.light()
                            }
                            .semantics { contentDescription = "สีของฉัน" }
                            .background(hsb(c.h, c.s, c.b), CircleShape)
                            .border(if (active) 2.dp else 0.5.dp, Color.White.opacity(if (active) 0.95 else 0.25), CircleShape),
                    )
                }
            }
        }
        Box(Modifier.padding(top = 20.dp).size(1.dp, 30.dp).background(Color.White.opacity(0.14)))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("สำเร็จรูป", style = sh(10.5f, SHFont.semibold), color = Color.White.opacity(0.45))
            PalettePresets()
        }
    }
}

/** เม็ดสีสำเร็จรูป — **คู่สีมาก่อน แล้วค่อยเป็นสีเดี่ยว** อยู่ในแถวเดียวกัน */
@Composable
private fun CardEditorState.PalettePresets() {
    Row(
        Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(vertical = 3.dp, horizontal = 2.dp),
        horizontalArrangement = Arrangement.spacedBy(9.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ColorDuo.all.forEach { d ->
            key(d.id) {
                val on = theme.duoID == d.id
                DuoDot(
                    duo = d,
                    flipped = on && theme.duoFlipped,
                    on = on,
                    modifier = Modifier
                        .tap {
                            // สีที่ตั้งเองต้องยังกดกลับได้ — คู่สีก็คือการลองดู
                            theme.customColor?.let { myColor = it }
                            setTheme(theme.setDuo(d))
                            Haptics.light()
                        }
                        .semantics { contentDescription = "${d.darkName} กับ ${d.lightName}" },
                )
            }
        }
        Palette.entries.forEach { p ->
            key(p) {
                val active = theme.palette == p && !theme.hasCustomColor && theme.duoID == null
                val sc by animateFloatAsState(if (active) 1.1f else 1f, Motion.snap.float, label = "palette")
                Box(
                    Modifier
                        .size(30.dp)
                        .graphicsLayer {
                            scaleX = sc
                            scaleY = sc
                        }
                        .tap {
                            // จำสีที่ตั้งเองไว้ก่อน — สีสำเร็จรูปคือการลองดู ไม่ใช่การทิ้งของเดิม
                            theme.customColor?.let { myColor = it }
                            setTheme(theme.copy(palette = p).clearBackdropColor())
                            Haptics.light()
                        }
                        .background(
                            Brush.linearGradient(listOf(p.accentSoft, p.accent), start = Offset.Zero, end = Offset.Infinite),
                            CircleShape,
                        )
                        .border(if (active) 2.dp else 0.5.dp, Color.White.opacity(if (active) 0.95 else 0.2), CircleShape),
                )
            }
        }
    }
}

/** ช่องพิมพ์รหัสสี — แตะแล้วขึ้นกล่องถาม ไม่ใช่ช่องพิมพ์ที่ฝังอยู่ในถาด */
@Composable
private fun CardEditorState.HexField() {
    Row(
        Modifier
            .fillMaxWidth()
            .background(Color.White.opacity(0.08), RoundedCornerShape(8.dp))
            .tap {
                // เปิดมาเป็นช่องว่าง โดยเอาสีปัจจุบันไปเป็นตัวอย่างในช่องแทน
                hexDraft = ""
                hexPrompt = true
                Haptics.light()
            }
            .padding(horizontal = 9.dp, vertical = 7.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("HEX", style = sh(9.5f, SHFont.semibold), color = Color.White.opacity(0.45))
        Text(
            theme.backdropHex,
            style = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.SemiBold, fontSize = 12.sp),
            color = Color.White.opacity(0.9),
        )
        Spacer(Modifier.weight(1f))
        SFSymbol("pencil", size = 9.5f, tint = Color.White.opacity(0.45))
    }
}

/** ช่องกรอกในกล่องถามสีพื้น — ตัวอย่างในช่องคือสีปัจจุบัน */
@Composable
private fun CardEditorState.HexPromptField() {
    val focus = remember { FocusRequester() }
    LaunchedEffect(focus) { runCatching { focus.requestFocus() } }
    val shape = RoundedCornerShape(7.dp)
    BasicTextField(
        value = hexDraft,
        onValueChange = { hexDraft = it },
        singleLine = true,
        textStyle = sh(14f).copy(color = Color.White),
        cursorBrush = SolidColor(Color.White),
        keyboardOptions = KeyboardOptions(
            capitalization = KeyboardCapitalization.Characters,
            autoCorrectEnabled = false,
            imeAction = ImeAction.Done,
        ),
        keyboardActions = KeyboardActions(onDone = {
            applyHex()
            hexPrompt = false
        }),
        modifier = Modifier
            .padding(top = 12.dp)
            .fillMaxWidth()
            .background(grey(0.10), shape)
            .border(0.5.dp, Color.White.opacity(0.15), shape)
            .padding(horizontal = 8.dp, vertical = 7.dp)
            .focusRequester(focus),
        decorationBox = { inner ->
            Box(contentAlignment = Alignment.CenterStart) {
                if (hexDraft.isEmpty()) Text(theme.backdropHex, style = sh(14f), color = Color.White.opacity(0.3))
                inner()
            }
        },
    )
}

/** ลายเซ็น Sale Here บนตัวการ์ด — ถอดไม่ได้ แต่เลือกได้ว่าเป็นตัวเขียนจางหรือตรา */
@Composable
private fun CardEditorState.SignatureRow() {
    val opts = listOf(
        segOpt(StripStyle.line, "ตัวเขียน"),
        segOpt(StripStyle.foil, "พิมพ์"),
        segOpt(StripStyle.emboss, "ปั๊มนูน"),
    )
    DockRow(label = "ลายเซ็น") {
        DockSegment(
            options = opts,
            selection = if (theme.strip.isStamp) theme.strip else StripStyle.line,
            onPick = { c ->
                setTheme(theme.copy(strip = c))
                Haptics.light()
            },
        )
    }
}

/**
 * โทนหมึก — เหลือสองฝั่ง: มืด · สว่าง
 * พื้นเป็นรูป = ล็อกกลางคืน แถวยังอยู่แต่จาง แตะแล้วบอกเหตุผล
 */
@Composable
private fun CardEditorState.ToneRow() {
    val locked = theme.backdrop == BackdropStyle.photo
    val sel = if (theme.activeInk.isLight) ToneChoice.light else ToneChoice.dark
    val opts = listOf(segOpt(ToneChoice.dark, "มืด"), segOpt(ToneChoice.light, "สว่าง"))
    DockRow(label = "โทน", dim = locked) {
        DockSegment(
            options = opts,
            selection = if (locked) ToneChoice.dark else sel,
            dim = locked,
            onPick = { c ->
                if (locked) {
                    flash("พื้นเป็นรูป — โทนล็อกเป็นกลางคืนให้ตัวหนังสืออ่านออกบนรูปทุกแบบ")
                    Haptics.rigid()
                } else if (theme.duoColors != null) {
                    // คู่สีมีสองสีอยู่แล้ว — "สว่าง" แปลว่ายกสีอ่อนของคู่ขึ้นมาเป็นพื้น
                    setTheme(theme.copy(duoFlipped = c == ToneChoice.light))
                    Haptics.light()
                } else {
                    setTheme(theme.copy(inkAuto = false, ink = if (c == ToneChoice.dark) CardInk.night else theme.lightInk))
                    Haptics.light()
                }
            },
        )
    }
}

// MARK: รูปพื้นหลัง

@Composable
private fun CardEditorState.BackdropPhotoSource() {
    val store = photos
    val bg = store?.background
    DockRow(label = "รูป") {
        Row(horizontalArrangement = Arrangement.spacedBy(9.dp), verticalAlignment = Alignment.CenterVertically) {
            val shape = RoundedCornerShape(7.dp)
            Box(
                Modifier
                    .size(33.dp, 42.dp)
                    .clip(shape)
                    .background(Color.White.opacity(0.08))
                    .border(0.5.dp, Color.White.opacity(0.18), shape),
                contentAlignment = Alignment.Center,
            ) {
                if (bg != null) {
                    Image(bg.asImageBitmap(), contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
                } else {
                    SFSymbol("photo", size = 12f, tint = Color.White.opacity(0.35))
                }
            }

            BackgroundPickButton(theme = theme.toolTheme, onPicked = { tone ->
                // โทนที่ดูดจากรูปเป็นแค่เฉด ไม่ใช่สีพื้นจริง — ล้างความสว่างที่เคยตั้งเอง
                setTheme(theme.copy(backdrop = BackdropStyle.photo, customHue = tone?.h, customSat = tone?.s, customBri = null))
            })

            // ใส่รูปแล้วไม่ชอบต้องมีทางกลับที่เห็นอยู่ตรงนั้น — เอารูปออกแล้วพาไปพื้นไล่เฉดด้วย
            AnimatedVisibility(
                visible = bg != null,
                enter = scaleIn(Motion.settle.spec()) + fadeIn(Motion.settle.spec()),
                exit = scaleOut(Motion.settle.spec()) + fadeOut(Motion.settle.spec()),
            ) {
                Box(
                    Modifier
                        .tap {
                            store?.clearBackground()
                            setTheme(
                                theme.copy(backdrop = BackdropStyle.gradient).clearBackdropColor()
                                    .copy(photoEffect = BackdropEffect.none),
                            )
                            Haptics.medium()
                        }
                        .background(Color.White.opacity(0.08), CircleShape)
                        .padding(horizontal = 10.dp, vertical = 6.dp),
                ) {
                    Text("เอาออก", style = sh(9.5f, SHFont.semibold), color = Color.White.opacity(0.7))
                }
            }
            Spacer(Modifier.weight(1f))
        }
    }
}

// MARK: - ถาดตู้ / ถาดของชิ้น

/** ตู้วิดเจ็ตในถาด — ความสูงมาจากระดับของชีต ตัวตู้เลื่อนเองข้างใน */
@Composable
private fun CardEditorState.GalleryTray(full: Boolean) {
    Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        // บอกตั้งแต่เปิดตู้ ไม่ใช่รอให้เลือกจนจบแล้วค่อยปฏิเสธ
        if (full) GalleryFullBanner()
        WidgetGallery(
            theme = theme.toolTheme,
            onAdd = { kind -> addWidget(kind) },
            onFill = { kind, topic ->
                // ยังไม่มีข้อมูลของหัวข้อนั้น → พาไปกรอกข้อเดียว · ผลงานกับ Sale Here กรอกเองไม่ได้ ต้องไปรับงาน
                if (topic.fillable) {
                    topicFill = TopicFillRequest(kind, topic)
                } else {
                    askJobs = true
                }
            },
            onClose = null,
            showsBar = false,
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
private fun CardEditorState.GalleryFullBanner() {
    Row(
        Modifier
            .fillMaxWidth()
            .background(Color.White.opacity(0.08), RoundedCornerShape(12.dp))
            .padding(horizontal = 14.dp, vertical = 11.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        SFSymbol("tray.full.fill", size = 13f, tint = Color.White.opacity(0.9))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("การ์ดเต็มแล้ว", style = sh(12.5f, SHFont.semibold), color = Color.White.opacity(0.9))
            Text(
                if (format.pageCount == 1) "หน้านี้ไม่เหลือที่ว่าง — เอาของออกหรือย่อของเดิมก่อนถึงจะเพิ่มได้"
                else "ครบ ${format.pageCount} หน้าและไม่เหลือที่ว่าง — เอาของออกก่อนถึงจะเพิ่มได้",
                style = sh(10.5f, SHFont.medium),
                color = Color.White.opacity(0.55),
            )
        }
    }
}

/**
 * เนื้อในชีตของชิ้นที่เลือก — แบบอื่น (ถ้ามี) · กล่อง · ขอบ · แถวท้ายเป็นวิธีใช้กับปุ่มลบ
 * ก้อนข้อความไม่มีกล่อง/ขอบ เหลือแค่แถวท้าย
 */
@Composable
private fun CardEditorState.PieceTray(sel: WidgetInstance) {
    val isText = sel.kind == WidgetKind.textBlock
    val resizable = sel.kind.canResize
    val hint = when {
        isText -> "แตะซ้ำเพื่อพิมพ์ · ลากเพื่อย้าย · หมุดมุมย่อขยาย"
        resizable -> "หมุดข้างยืดกว้าง/สูง · หมุดมุมย่อขยายทั้งชิ้น · แตะตัวอักษรเพื่อแก้"
        else -> "ลากเพื่อย้าย · ขนาดล็อก หลักฐานต้องเทียบกันได้"
    }
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        if (!isText) {
            VariantsRow(sel)
            // กล่องเหลือสองแบบ: เข้ม หรือ กระจก — ชิ้นที่วาดวัสดุของตัวเองไม่มีแถวนี้
            if (sel.kind.usesSurfaceChoice) {
                DockRow(label = "กล่อง") {
                    DockSegment(
                        options = sel.kind.surfaceOptions.map { segOpt(it, sel.kind.surfaceName(it)) },
                        selection = sel.surface,
                        onPick = { setSurface(sel, it) },
                    )
                }
            }
            // ลายทางบนแผ่น — มีเฉพาะตอนแผ่นของมันยังอยู่
            if (sel.kind.takesPattern && sel.surface == WidgetSurface.glass) {
                DockRow(label = "ลาย") {
                    DockSegment(
                        options = PlatePattern.entries.map { segOpt(it, it.displayName) },
                        selection = sel.pattern,
                        onPick = { setPattern(sel, it) },
                    )
                }
            }
            // รูปคน: ลบพื้นหลังให้เอง (ตั้งต้น) หรือคงรูปเต็มไว้ในกรอบ
            if (sel.kind.liftsSubject) {
                DockRow(label = "พื้นหลังรูป") {
                    DockSegment(
                        options = listOf(segOpt(true, "ลบออก"), segOpt(false, "คงไว้")),
                        selection = sel.liftPhoto,
                        onPick = { setLiftPhoto(sel, it) },
                    )
                }
            }
            // ตราปั๊มนูน Sale Here STAR บนแผ่นของใบนี้ — ปิดได้รายชิ้น
            if (sel.kind.takesEmboss) {
                DockRow(label = "ตรา") {
                    DockSegment(
                        options = listOf(segOpt(0, "พิมพ์"), segOpt(1, "ปั๊มนูน"), segOpt(2, "ไม่มี")),
                        selection = if (!sel.emboss) 2 else if (sel.embossBlind) 1 else 0,
                        onPick = { setEmboss(sel, it) },
                    )
                }
            }
            DockRow(label = "ขอบ") {
                DockSegment(
                    options = listOf(segOpt(true, "มีขอบ"), segOpt(false, "ไม่มีขอบ")),
                    selection = sel.border,
                    onPick = { setBorder(sel, it) },
                )
            }
        }
        // แถวท้าย: ท่าที่ใช้กับชิ้นนี้ (เงียบ ๆ) + ลบ — ลบเป็นตัวหนังสือแดงในแคปซูลจาง ไม่ใช่ปุ่มแดงทึบ
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            Row(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
                SFSymbol(if (isText) "hand.tap" else if (resizable) "hand.draw" else "lock", size = 9.5f, tint = Color.White.opacity(0.4))
                Text(
                    hint,
                    style = sh(10.5f, SHFont.medium),
                    color = Color.White.opacity(0.4),
                    maxLines = 1,
                    softWrap = false,
                    autoSize = autoShrink(10.5f, 0.65f),
                    modifier = Modifier.weight(1f, fill = false),
                )
            }
            val red = rgb(1.0, 0.5, 0.45)
            Row(
                Modifier
                    .dockPress { deleteWidget(sel) }
                    .semantics { contentDescription = "ลบ${sel.kind.title}" }
                    .background(Color.White.opacity(0.08), CircleShape)
                    .height(34.dp)
                    .padding(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(5.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                SFSymbol("trash", size = 12f, tint = red)
                Text("ลบ", style = sh(12f, SHFont.semibold), color = red)
            }
        }
    }
}

/** แบบอื่นในตระกูลเดียวกัน — ชิ้นที่มีแบบเดียวไม่มีแถวนี้เลย ไม่ใช่แถวว่าง */
@Composable
private fun CardEditorState.VariantsRow(sel: WidgetInstance) {
    val siblings = WidgetKind.entries.filter { it.family == sel.kind.family }
    if (siblings.size <= 1) return
    Row(
        Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(vertical = 2.dp, horizontal = 1.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.Top,
    ) {
        siblings.forEach { k ->
            key(k) {
                val active = k == sel.kind
                Column(Modifier.tap { swap(sel, k) }, verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    WidgetThumb(
                        kind = k,
                        theme = theme.toolTheme,
                        width = 92f,
                        modifier = Modifier.border(
                            if (active) 2.dp else 0.6.dp,
                            if (active) theme.rawAccent else Color.White.opacity(0.14),
                            RoundedCornerShape(12.dp),
                        ),
                    )
                    Text(
                        k.title,
                        style = sh(9.5f, if (active) SHFont.semibold else SHFont.regular),
                        color = if (active) Color.White else Color.White.opacity(0.5),
                        maxLines = 1,
                        softWrap = false,
                        textAlign = TextAlign.Center,
                        autoSize = autoShrink(9.5f, 0.7f),
                        modifier = Modifier.width(92.dp),
                    )
                }
            }
        }
    }
}

// MARK: - ชีต / กล่องถาม / หน้าเต็มจอ

/** ชีตครึ่งล่างบนเวทีมืด (= `.sheet` + `presentationDetents`) — ลากลงหรือแตะม่านเพื่อปิด */
@Composable
private fun StageSheet(visible: Boolean, height: Float?, onDismiss: () -> Unit, content: @Composable () -> Unit) {
    BackHandler(enabled = visible, onBack = onDismiss)
    Box(Modifier.fillMaxSize()) {
        AnimatedVisibility(
            visible = visible,
            modifier = Modifier.matchParentSize(),
            enter = fadeIn(Motion.settle.spec()),
            exit = fadeOut(Motion.settle.spec()),
        ) {
            Box(Modifier.fillMaxSize().background(Color.Black.opacity(0.35)).pointerInput(Unit) { detectTapGestures { onDismiss() } })
        }
        AnimatedVisibility(
            visible = visible,
            modifier = Modifier.align(Alignment.BottomCenter),
            enter = slideInVertically(Motion.settle.spec()) { it },
            exit = slideOutVertically(Motion.settle.spec()) { it },
        ) {
            val drag = remember { Animatable(0f) }
            val scope = rememberCoroutineScope()
            val shape = RoundedCornerShape(topStart = 26.dp, topEnd = 26.dp)
            var m = Modifier
                .fillMaxWidth()
                .graphicsLayer { translationY = drag.value }
                .background(grey(0.09), shape)
                .pointerInput(Unit) {
                    detectVerticalDragGestures(
                        onDragEnd = {
                            if (drag.value > 90f * density) {
                                onDismiss()
                                scope.launch {
                                    delay(400)
                                    drag.snapTo(0f)
                                }
                            } else {
                                scope.launch { drag.animateTo(0f, Motion.settle.float) }
                            }
                        },
                        onDragCancel = { scope.launch { drag.animateTo(0f, Motion.settle.float) } },
                    ) { _, dy -> scope.launch { drag.snapTo(max(0f, drag.value + dy)) } }
                }
                .windowInsetsPadding(WindowInsets.navigationBars)
            if (height != null) m = m.height(height.dp)
            Box(m) {
                content()
                Box(
                    Modifier
                        .align(Alignment.TopCenter)
                        .padding(top = 5.dp)
                        .size(36.dp, 5.dp)
                        .background(Color.White.opacity(0.3), CircleShape),
                )
            }
        }
    }
}

/** กล่องถามแบบ iOS บนพื้นมืด (= `.alert`) — ปุ่มยกเลิกซ้าย · ปุ่มทำขวา */
@Composable
private fun StageAlert(
    visible: Boolean,
    title: String,
    message: String,
    actionTitle: String,
    cancelTitle: String,
    onAction: () -> Unit,
    onDismiss: () -> Unit,
    field: (@Composable () -> Unit)? = null,
) {
    BackHandler(enabled = visible, onBack = onDismiss)
    AnimatedVisibility(
        visible = visible,
        enter = fadeIn(Motion.snap.spec()),
        exit = fadeOut(Motion.snap.spec()),
    ) {
        Box(
            Modifier
                .fillMaxSize()
                .background(Color.Black.opacity(0.42))
                .pointerInput(Unit) { awaitPointerEventScope { while (true) awaitPointerEvent() } }
                .imePadding(),
            contentAlignment = Alignment.Center,
        ) {
            val shape = RoundedCornerShape(14.dp)
            Column(Modifier.width(270.dp).clip(shape).background(grey(0.17))) {
                Column(
                    Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 19.dp, bottom = 16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Text(title, style = sh(17f, SHFont.semibold), color = Color.White, textAlign = TextAlign.Center)
                    Text(message, style = sh(13f), color = Color.White.opacity(0.85), textAlign = TextAlign.Center)
                    field?.invoke()
                }
                Box(Modifier.fillMaxWidth().height(0.5.dp).background(Color.White.opacity(0.15)))
                Row(Modifier.fillMaxWidth().height(44.dp)) {
                    Box(Modifier.weight(1f).fillMaxHeight().tap { onDismiss() }, contentAlignment = Alignment.Center) {
                        Text(cancelTitle, style = sh(17f, SHFont.semibold), color = AlertBlue, maxLines = 1)
                    }
                    Box(Modifier.width(0.5.dp).fillMaxHeight().background(Color.White.opacity(0.15)))
                    Box(
                        Modifier.weight(1f).fillMaxHeight().tap {
                            onAction()
                            onDismiss()
                        },
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(actionTitle, style = sh(17f), color = AlertBlue, maxLines = 1, autoSize = autoShrink(17f, 0.7f))
                    }
                }
            }
        }
    }
}

/** หน้าเต็มจอ (= `.fullScreenCover`) — ไหลขึ้นจากขอบล่าง · `LocalDismiss` ปิดมัน */
@Composable
private fun FullCover(visible: Boolean, onBack: () -> Unit, content: @Composable () -> Unit) {
    BackHandler(enabled = visible, onBack = onBack)
    AnimatedVisibility(
        visible = visible,
        enter = slideInVertically(Motion.page.spec()) { it },
        exit = slideOutVertically(Motion.page.spec()) { it },
    ) {
        Box(Modifier.fillMaxSize().pointerInput(Unit) { awaitPointerEventScope { while (true) awaitPointerEvent() } }) {
            CompositionLocalProvider(LocalDismiss provides onBack) { content() }
        }
    }
}

// MARK: - Spectrum picker

/**
 * แถบเลือกสี — ลากบนสเปกตรัมเลือกเฉด · แถบล่างปรับความสด · แถบที่สามปรับความสว่าง
 * ฝังในแผงแทนตัวเลือกสีของระบบ — การ์ดเปลี่ยนสีให้เห็นสด ๆ ทุกเฟรมระหว่างลาก
 */
@Composable
private fun SpectrumPicker(
    hue: Double,
    sat: Double,
    bri: Double,
    onChange: (Double, Double, Double) -> Unit,
    modifier: Modifier = Modifier,
) {
    // ความกว้างวัดจากตัวแถวเอง ไม่ใช่ตัวห่อ — ที่รับทัชกับที่วาดเป็นก้อนเดียวกัน
    var width by remember { mutableFloatStateOf(0f) }
    val density = LocalDensity.current.density
    val h by rememberUpdatedState(hue)
    val s by rememberUpdatedState(sat)
    val b by rememberUpdatedState(bri)
    val change by rememberUpdatedState(onChange)
    val knobColor = hsb(hue, sat, max(0.06, bri))
    Column(
        modifier.fillMaxWidth().onSizeChanged { width = it.width / density },
        verticalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        SpectrumBar(
            colors = (0..12).map { hsb(it / 12.0, 0.9, 1.0) },
            value = hue, knobColor = knobColor, width = width,
        ) { v -> change(v, s, b) }
        // แถบความสดวาดที่ความสว่างอย่างน้อย 0.45 — พื้นเกือบดำแล้วแถบต้องยังอ่านออก
        SpectrumBar(
            colors = listOf(hsb(hue, 0.04, max(0.45, bri)), hsb(hue, 1.0, max(0.45, bri))),
            value = sat, knobColor = knobColor, width = width,
        ) { v -> change(h, v, b) }
        SpectrumBar(
            colors = listOf(hsb(hue, sat, 0.02), hsb(hue, sat, 1.0)),
            value = bri, knobColor = knobColor, width = width,
        ) { v -> change(h, s, max(0.02, v)) }
    }
}

@Composable
private fun SpectrumBar(colors: List<Color>, value: Double, knobColor: Color, width: Float, set: (Double) -> Unit) {
    val knob = 20f
    val setNow by rememberUpdatedState(set)
    val widthNow by rememberUpdatedState(width)
    Box(
        Modifier
            .fillMaxWidth()
            .height(26.dp)
            // กินทัชเอง ไม่งั้นชีตที่เลื่อนได้แย่ง pan ไปหมด
            .pointerInput(Unit) {
                awaitEachGesture {
                    val down = awaitFirstDown()
                    down.consume()
                    // หักครึ่งปุ่มออก ให้จุดที่นิ้วแตะตรงกับกึ่งกลางปุ่มพอดี
                    fun emit(x: Float) {
                        val v = (x / density - knob / 2f) / max(widthNow - knob, 1f)
                        setNow(min(1.0, max(0.0, v.toDouble())))
                    }
                    emit(down.position.x)
                    while (true) {
                        val ev = awaitPointerEvent()
                        val ch = ev.changes.firstOrNull { it.id == down.id } ?: break
                        if (!ch.pressed) break
                        ch.consume()
                        emit(ch.position.x)
                    }
                    Haptics.light()
                }
            },
        contentAlignment = Alignment.CenterStart,
    ) {
        Box(
            Modifier
                .fillMaxWidth()
                .height(16.dp)
                .background(Brush.horizontalGradient(colors), CircleShape)
                .border(0.5.dp, Color.White.opacity(0.16), CircleShape),
        )
        // ปุ่มจับเป็นสีจริงที่กำลังจะได้ ไม่ใช่สีเต็มความสว่างเสมอ
        Box(
            Modifier
                .offset(x = (min(max(value, 0.0), 1.0).toFloat() * max(width - knob, 0f)).dp)
                .size(knob.dp)
                .shadow(3.dp, CircleShape, clip = false, ambientColor = Color.Black.opacity(0.35), spotColor = Color.Black.opacity(0.35))
                .background(knobColor, CircleShape)
                .border(2.dp, Color.White, CircleShape),
        )
    }
}

/** แถบลากค่าเดียว 0…1 — โครงเดียวกับแถบใน `SpectrumPicker` · ส่วนที่ผ่านมาแล้วเป็นสีเน้น */
@Composable
private fun TrackSlider(value: Double, tint: Color = Color.White, onChange: (Double) -> Unit, modifier: Modifier = Modifier) {
    var width by remember { mutableFloatStateOf(0f) }
    val knob = 20f
    val density = LocalDensity.current.density
    val change by rememberUpdatedState(onChange)
    val widthNow by rememberUpdatedState(width)
    val k = min(1.0, max(0.0, value)).toFloat()
    Box(
        modifier
            .fillMaxWidth()
            .height(26.dp)
            .onSizeChanged { width = it.width / density }
            .pointerInput(Unit) {
                awaitEachGesture {
                    val down = awaitFirstDown()
                    down.consume()
                    fun emit(x: Float) {
                        val v = (x / density - knob / 2f) / max(widthNow - knob, 1f)
                        change(min(1.0, max(0.0, v.toDouble())))
                    }
                    emit(down.position.x)
                    while (true) {
                        val ev = awaitPointerEvent()
                        val ch = ev.changes.firstOrNull { it.id == down.id } ?: break
                        if (!ch.pressed) break
                        ch.consume()
                        emit(ch.position.x)
                    }
                    Haptics.light()
                }
            },
        contentAlignment = Alignment.CenterStart,
    ) {
        Box(Modifier.fillMaxWidth().height(6.dp).background(Color.White.opacity(0.12), CircleShape))
        Box(Modifier.width((k * max(width - knob, 0f) + knob / 2f).dp).height(6.dp).background(tint.opacity(0.9), CircleShape))
        Box(
            Modifier
                .offset(x = (k * max(width - knob, 0f)).dp)
                .size(knob.dp)
                .shadow(3.dp, CircleShape, clip = false, ambientColor = Color.Black.opacity(0.35), spotColor = Color.Black.opacity(0.35))
                .background(Color.White, CircleShape),
        )
    }
}

/** ตัวอย่างย่อของเอฟเฟกต์หนึ่งแบบ — **รูปจริงของผู้ใช้ ผ่านเอฟเฟกต์จริง** */
@Composable
private fun PhotoEffectSwatch(theme: CardTheme, effect: BackdropEffect, modifier: Modifier = Modifier) {
    val photos = LocalPhotoStore.current
    Box(modifier.fillMaxSize().clipToBounds().background(theme.backdropColors.bottom)) {
        val bg = photos?.background(effect)
        if (bg != null) {
            Image(
                bg.asImageBitmap(),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                colorFilter = if (effect == BackdropEffect.mono) ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0f) }) else null,
                // รัศมีเบลอต้องย่อตามกรอบ — ใช้ 26 เท่าของจริงในกรอบ 24pt แล้วเละเป็นสีเดียว
                modifier = Modifier.fillMaxSize().then(if (effect == BackdropEffect.blur) Modifier.blur(3.dp) else Modifier),
            )
        }
    }
}

// MARK: - Canvas grid

/**
 * จุดปะคือ "กริดจริง" ไม่ใช่ลายตกแต่ง — ระยะห่างจุดคือขั้นที่ widget สแนปได้จริง
 * - ink: จุดกริดอยู่บนหน้ากระดาษ จึงต้องพลิกตามหมึกเหมือนทุกอย่างบนการ์ด
 * - page: พิกัดอ้างมุมบนซ้ายของหน้ากระดาษ
 */
@Suppress("UNUSED_PARAMETER")
@Composable
private fun CanvasGrid(theme: CardTheme, ink: InkStyle = InkStyle.night, page: Size, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val box = PageLayout.content(page)
        if (box.width <= 0f || box.height <= 0f) return@Canvas
        // วาดทุก 2 ขั้น — ขั้นละ 6pt ถี่เกินกว่าจะอ่านเป็นกริด
        val pitch = PageLayout.step * 2f
        // จุดเน้นทุก 5 ช่วง — ตัวช่วยกะระยะแบบไม้บรรทัด
        val major = 5
        val big = 2.2f
        val small = 1.4f
        val strongColor = ink.line(0.18)
        val weakColor = ink.line(0.07)
        val d = density
        var iy = 0
        var y = box.top
        while (y <= box.bottom + 1f) {
            var ix = 0
            var x = box.left
            while (x <= box.right + 1f) {
                val strong = ix % major == 0 && iy % major == 0
                val r = (if (strong) big else small) / 2f
                drawCircle(if (strong) strongColor else weakColor, radius = r * d, center = Offset(x * d, y * d))
                x += pitch
                ix += 1
            }
            y += pitch
            iy += 1
        }
    }
}

// MARK: - Handle

/** หมุดขอบ — แคปซูลขาว · พื้นที่กดเผื่อรอบละ 9pt (คู่กับการดันหมุดออกนอกกรอบ 11pt) */
@Composable
private fun HandleGrip(theme: CardTheme, axis: GripAxis, modifier: Modifier = Modifier) {
    val w = if (axis == GripAxis.horizontal) 6f else 32f
    val h = if (axis == GripAxis.horizontal) 32f else 6f
    Box(modifier.padding(9.dp)) {
        Box(
            Modifier
                .size(w.dp, h.dp)
                .shadow(5.dp, CircleShape, clip = false, ambientColor = Color.Black.opacity(0.5), spotColor = Color.Black.opacity(0.5))
                .background(Color.White, CircleShape)
                .border(1.4.dp, theme.accent, CircleShape),
        )
    }
}

// MARK: - ตัวอย่างย่อของตัวเลือกธีม

/** ตัวอย่างย่อของ "โทน" หนึ่งแบบ — ฉากหลังจริง + แผ่นการ์ดจริง + สีหมึกจริง */
@Composable
private fun InkSwatch(theme: CardTheme, ink: CardInk, modifier: Modifier = Modifier) {
    // ตัวอย่างต้องโชว์หมึกที่ชิปนี้แทน — ปิดโหมดอัตโนมัติ · พื้นรูปบังคับหมึกกลางคืน สลับเป็นไล่เฉด
    var t = theme.copy(ink = ink, inkAuto = false)
    if (t.backdrop == BackdropStyle.photo) t = t.copy(backdrop = BackdropStyle.gradient)
    val c = t.backdropColors
    val s = t.inkStyle
    val shape = RoundedCornerShape(3.dp)
    Box(modifier.fillMaxSize().background(Brush.verticalGradient(listOf(c.top, c.bottom)))) {
        Box(
            Modifier
                .fillMaxSize()
                .padding(2.5.dp)
                .background(if (s.isLight) Color.White.opacity(0.64) else Color.White.opacity(0.12), shape)
                .border(0.5.dp, s.line(0.22), shape),
            contentAlignment = Alignment.CenterStart,
        ) {
            // สามบรรทัดจำลอง — เส้นบางและระยะห่างคุมเป็นสัดส่วนของกรอบ
            Column(Modifier.padding(start = 3.dp), verticalArrangement = Arrangement.spacedBy(1.6.dp)) {
                Box(Modifier.size(5.dp, 1.8.dp).background(t.accent, CircleShape))
                Box(Modifier.size(12.dp, 2.2.dp).background(s.text(0.82), CircleShape))
                Box(Modifier.size(8.dp, 1.8.dp).background(s.text(0.36), CircleShape))
            }
        }
    }
}

/** เม็ดสีของคู่สีหนึ่งคู่ — ซีกซ้ายคือสีพื้น ซีกขวาคือสีหมึก · สลับข้างที่แถวโทนแล้วสองซีกสลับตาม */
@Composable
private fun DuoDot(duo: ColorDuo, flipped: Boolean, on: Boolean, modifier: Modifier = Modifier) {
    val bg = if (flipped) duo.light else duo.dark
    val ink = if (flipped) duo.dark else duo.light
    val sc by animateFloatAsState(if (on) 1.1f else 1f, Motion.snap.float, label = "duo")
    Box(
        modifier
            .size(30.dp)
            .graphicsLayer {
                scaleX = sc
                scaleY = sc
            }
            .clip(CircleShape)
            .background(ink)
            .border(if (on) 2.dp else 0.5.dp, Color.White.opacity(if (on) 0.95 else 0.2), CircleShape),
    ) {
        Box(Modifier.width(15.dp).fillMaxHeight().background(bg))
    }
}

/** ตัวอย่างย่อของ "ฉากหลัง" หนึ่งแบบ — ใช้สีและชั้นเดียวกับ `CardBackdrop` */
@Composable
private fun BackdropSwatch(theme: CardTheme, style: BackdropStyle, modifier: Modifier = Modifier) {
    val photos = LocalPhotoStore.current
    val t = theme.copy(backdrop = style)
    val c = t.backdropColors
    Box(modifier.fillMaxSize().clipToBounds()) {
        when (style) {
            BackdropStyle.gradient ->
                Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(c.top, c.bottom))))
            BackdropStyle.grid -> {
                Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(c.top, c.bottom))))
                BackdropGrid(line = Color.White.opacity(if (t.activeInk.isLight) 0.6 else 0.12), step = 6f, modifier = Modifier.fillMaxSize())
            }
            BackdropStyle.stripe -> {
                Box(Modifier.fillMaxSize().background(c.top))
                BackdropStripes(band = t.stripeInk, width = 3f, modifier = Modifier.fillMaxSize())
            }
            BackdropStyle.diamond -> {
                Box(Modifier.fillMaxSize().background(c.top))
                BackdropDiamonds(band = t.stripeInk, width = 8f, modifier = Modifier.fillMaxSize())
            }
            BackdropStyle.glow -> {
                Box(Modifier.fillMaxSize().background(c.bottom))
                // ดวงแสงย่อ — ต้องเบลอน้อยกว่าของจริงตามสัดส่วน ไม่งั้นเละเป็นสีเดียว
                Box(
                    Modifier
                        .align(Alignment.Center)
                        .offset((-6).dp, (-5).dp)
                        .size(16.dp)
                        .blur(6.dp, BlurredEdgeTreatment.Unbounded)
                        .background(t.accent.opacity(0.75), CircleShape),
                )
                Box(
                    Modifier
                        .align(Alignment.Center)
                        .offset(7.dp, 6.dp)
                        .size(14.dp)
                        .blur(6.dp, BlurredEdgeTreatment.Unbounded)
                        .background(t.accentSoft.opacity(0.5), CircleShape),
                )
            }
            BackdropStyle.solid -> Box(Modifier.fillMaxSize().background(c.top))
            BackdropStyle.marble -> {
                Box(
                    Modifier.fillMaxSize().background(
                        Brush.linearGradient(listOf(c.top, c.bottom), start = Offset.Zero, end = Offset.Infinite),
                    ),
                )
                // ลายเดียวกับของจริงแต่ต้องดันความหนาขึ้น — ที่ 24×17pt เส้นตามสัดส่วนจริงบางจนหายไปหมด
                val m = t.marbleInk
                MarbleVeins(vein = m.vein, bleed = m.bleed, lineScale = 3.6f, modifier = Modifier.fillMaxSize())
            }
            BackdropStyle.photo -> {
                Box(Modifier.fillMaxSize().background(c.bottom))
                val bg = photos?.background
                if (bg != null) {
                    Image(bg.asImageBitmap(), contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
                    Box(Modifier.fillMaxSize().background(c.top.opacity(if (theme.activeInk.isLight) 0.6 else 0.35)))
                } else if (photos != null) {
                    photos.image(0, modifier = Modifier.fillMaxSize().blur(4.dp))
                    Box(Modifier.fillMaxSize().background(c.bottom.opacity(0.45)))
                }
            }
        }
    }
}
