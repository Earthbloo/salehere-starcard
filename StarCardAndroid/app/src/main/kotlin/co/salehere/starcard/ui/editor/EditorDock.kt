package co.salehere.starcard.ui.editor

import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.animate
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.util.VelocityTracker
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.layout
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.GlassPanel
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.dockPress
import co.salehere.starcard.ui.tap
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.UUID
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

// MARK: - แถบเครื่องมือล่าง (dock) กับถาดตัวเลือก (= Views/Editor/EditorDock.swift)
//
// กติกาสามข้อ: 1. แถบหลักมีสามปุ่ม (พื้นหลัง · ข้อความ · วิดเจ็ต) — โผล่เฉพาะตอนไม่มีอะไรเปิดอยู่
// 2. กดอะไรก็ตาม = แถบหลักหายไป มีชีตขึ้นมาแทน (หัวชีต: ‹ กับชื่อ) ทุกอย่างของเรื่องนั้นอยู่ในชีตใบเดียว
// 3. ‹ หรือแตะที่ว่างบนการ์ด = ปิดชีต กลับแถบหลัก
// dock กับถาดเป็นวิวธรรมดาในหน้าเดียวกับการ์ด (ไม่ใช่ชีตของระบบ) — ไม่มีปัญหาทัชเหลื่อม/ชีตซ้อนชีต

/** แถบล่างอยู่ที่ไหน — ค่าเดียวที่บอกว่าตอนนี้กำลังทำอะไรอยู่ */
sealed class DockMode {
    /** แถบหลัก — ยังไม่ได้เลือกอะไร */
    data object Main : DockMode()
    /** พื้นหลังของทั้งการ์ด (สี · รูป · โทน) */
    data object Backdrop : DockMode()
    /** ตู้วิดเจ็ต */
    data object Gallery : DockMode()
    /** ชิ้นที่เลือกอยู่ — ทุกชิ้นบนหน้ายังอยู่ที่เดิม */
    data class Piece(val id: UUID) : DockMode()
    /** กำลังพิมพ์ก้อนข้อความ — ชิ้นอื่นหลบ คีย์บอร์ดขึ้น */
    data class Text(val id: UUID) : DockMode()

    val selectedID: UUID?
        get() = when (this) {
            is Piece -> id
            is Text -> id
            else -> null
        }

    val isMain: Boolean get() = this is Main

    val isText: Boolean get() = this is Text

    /** ชื่อแบบ Swift (`.main` · `.piece(id)`) — ชี้ไปที่ case เดียวกัน */
    companion object {
        val main: DockMode get() = Main
        val backdrop: DockMode get() = Backdrop
        val gallery: DockMode get() = Gallery
        fun piece(id: UUID): DockMode = Piece(id)
        fun text(id: UUID): DockMode = Text(id)
    }
}

/** สามปุ่มของแถบหลัก */
enum class DockMainItem(val raw: String) {
    backdrop("backdrop"), text("text"), widget("widget");

    val id: String get() = raw

    val label: String
        get() = when (this) {
            backdrop -> "พื้นหลัง"
            text -> "ข้อความ"
            widget -> "วิดเจ็ต"
        }

    val symbol: String
        get() = when (this) {
            backdrop -> "paintpalette.fill"
            text -> "textformat"
            widget -> "plus.square.on.square"
        }

    companion object {
        fun from(raw: String?): DockMainItem? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * ม่านของกระจก `.regular` โหมดมืด — Android ไม่มีเบลอพื้นหลังจริง (PORTING §8)
 * ม่านจึงต้องทึบพอให้ตัวหนังสือขาวอ่านออกเมื่อการ์ดสว่างมุดอยู่ข้างใต้
 */
private val DockGlassVeil: Color = Color(0xFF1C1C1E).opacity(0.6)

/** ชื่อ SF ที่ตาราง `Symbols` ยังไม่มี — ชี้ไปหาคู่ในตารางที่ความหมายใกล้สุด (ไม่งั้นตกเป็นวงประ) */
private val dockSymbolAlias: Map<String, String> = mapOf(
    "square" to "square.fill",
)

@Composable
private fun DockSymbol(name: String, size: Float, tint: Color, modifier: Modifier = Modifier) {
    SFSymbol(dockSymbolAlias[name] ?: name, size = size, tint = tint, modifier = modifier)
}

/** แถบหลัก — แคปซูลกระจกใบเดียว สามปุ่ม */
@Composable
fun EditorDock(
    /** ปุ่มที่กดแล้วไม่เกิดผล (การ์ดเต็ม) — จาง แต่ยังกดได้เพื่อรับคำอธิบาย */
    dimmed: Set<DockMainItem> = emptySet(),
    onMain: (DockMainItem) -> Unit,
    modifier: Modifier = Modifier,
) {
    val h = 58f
    CompositionLocalProvider(LocalCardInk provides InkStyle.night) {
        GlassPanel(
            veil = DockGlassVeil,
            radius = h / 2f,
            modifier = modifier
                .padding(horizontal = 16.dp)
                .fillMaxWidth()
                .height(h.dp),
        ) {
            Row(
                Modifier
                    .fillMaxSize()
                    .padding(horizontal = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                DockMainItem.entries.forEach { item ->
                    val dim = item in dimmed
                    val tint = Color.White.opacity(if (dim) 0.32 else 0.92)
                    Column(
                        Modifier
                            .weight(1f)
                            .height(h.dp)
                            .dockPress { onMain(item) },
                        verticalArrangement = Arrangement.spacedBy(3.dp, Alignment.CenterVertically),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Box(Modifier.height(22.dp), contentAlignment = Alignment.Center) {
                            DockSymbol(item.symbol, size = 18f, tint = tint)
                        }
                        Text(
                            item.label,
                            style = sh(10.5f, SHFont.semibold),
                            color = tint,
                            maxLines = 1,
                            softWrap = false,
                        )
                    }
                }
            }
        }
    }
}

// MARK: - ชีต

/** ที่จำ `LayoutCoordinates` ของหัวชีต — ใช้แปลงนิ้วเป็นพิกัดราก (หัวชีตเลื่อนตามความสูงของชีตระหว่างลาก) */
private class DockSheetCoords {
    var coords: LayoutCoordinates? = null
}

/**
 * state ของการลากปรับความสูงชีต — ระดับ · ระยะลากสด · ความสูงตามธรรมชาติ · สปริงที่พาเข้าระดับ
 * `ease` = ส่วนต่างที่สปริงกำลังพากลับเข้าระดับ (= `withAnimation(Motion.settle)` ของ iOS)
 */
@Stable
private class DockSheetDrag(private val scope: CoroutineScope) {
    var viewport by mutableFloatStateOf(874f)
    var fill by mutableStateOf(false)
    /** ระดับที่ค้างอยู่ — เก็บเป็นลำดับ ไม่ใช่ความสูง เนื้อหาเปลี่ยน (แตะชิ้นอื่น) ระดับเดิมยังถูกความหมาย */
    var level by mutableStateOf<Int?>(null)
    /** ระยะลากสด (บวก = ขึ้น) */
    var drag by mutableFloatStateOf(0f)
    /** ความสูงตามธรรมชาติของเนื้อหา — ระดับ "พอดีเนื้อหา" */
    var natural by mutableFloatStateOf(0f)
    var ease by mutableFloatStateOf(0f)
    private var easeJob: Job? = null
    /** ส่วนต่างของสปริงที่ค้างอยู่ตอนนิ้วจับกลางทาง — ชีตไม่กระโดดตอนจับ */
    private var dragBase = 0f

    /** ความสูงของช่องเนื้อหาแต่ละระดับ จากเตี้ยไปสูง */
    val detents: List<Float>
        get() {
            val mid = viewport * 0.44f
            val tall = viewport * 0.64f
            if (fill) return listOf(0f, max(220f, viewport * 0.3f), max(260f, viewport * 0.5f), tall)
            // ระดับที่แทบไม่ต่างจากพอดีเนื้อหาไม่ต้องมี — ลากแล้วไม่เห็นอะไรเปลี่ยน
            return listOf(0f, natural) + listOf(mid, tall).filter { it > natural + 48f }
        }

    /** ระดับตั้งต้น — พอดีเนื้อหา หรือครึ่งจอสำหรับตู้ */
    val defaultLevel: Int get() = if (fill) 2 else 1

    val currentLevel: Int get() = min(level ?: defaultLevel, detents.size - 1)

    val collapsed: Boolean get() = currentLevel == 0 && drag <= 0f

    /** ความสูงช่องเนื้อหาตอนนี้ — ระดับ + ระยะลาก เลยขอบบนแล้วหน่วงแบบยาง */
    val liveHeight: Float
        get() {
            val d = detents
            val raw = d[currentLevel] + drag + ease
            val top = d.last()
            return if (raw > top) top + rubber(raw - top) else raw
        }

    /** ลากต่ำกว่าหุบ — ทั้งใบจมตามนิ้วแบบหนืด ปล่อยแล้วเด้งกลับ (ไม่ปิด) */
    val sink: Float
        get() {
            val h = liveHeight
            return if (h < 0f) rubber(-h) else 0f
        }

    fun beginDrag() {
        easeJob?.cancel()
        dragBase = ease
        ease = 0f
        drag = dragBase
    }

    /** `dy` = ระยะนิ้วตามแกนตั้ง (ลง = บวก) นับจากจุดที่แตะ */
    fun dragTo(dy: Float) {
        drag = dragBase - dy
    }

    /** ปล่อยนิ้ว — เลือกระดับจากจุดที่ชีตจะไหลไปถึง (รวมแรงเหวี่ยง) ไม่ใช่แค่จุดที่ปล่อย */
    fun settle(predicted: Float) {
        val d = detents
        val aim = d[currentLevel] + dragBase + predicted
        // ลงแรงแค่ไหนก็จบที่ "หุบ" — ลากลงไม่มีวันปิดชีต
        val target = d.indices.minByOrNull { abs(d[it] - aim) } ?: currentLevel
        if (target != currentLevel) Haptics.impact(Haptics.Style.light)
        goTo(target)
    }

    fun step(delta: Int) {
        goTo((currentLevel + delta).coerceIn(0, detents.size - 1))
    }

    fun goTo(target: Int) {
        val d = detents
        val from = d[currentLevel] + drag + ease
        level = target
        drag = 0f
        dragBase = 0f
        val to = d[currentLevel]
        easeJob?.cancel()
        ease = from - to
        easeJob = scope.launch {
            animate(ease, 0f, animationSpec = Motion.settle.float) { v, _ -> ease = v }
        }
    }

    /** สูตรเดียวกับ overscroll ของ UIScrollView — ยังลากได้ แต่ไม่ไปแล้ว */
    private fun rubber(x: Float): Float {
        val c = 0.55f
        val dd = 120f
        return (1f - 1f / (x * c / dd + 1f)) * dd
    }
}

/** แรงเหวี่ยงที่นับเป็นระยะไหลต่อ (วินาที) — `predictedEndTranslation` ≈ ระยะลาก + ความเร็ว × ค่านี้ */
private const val SheetFlingProjection = 0.25f

/**
 * ชีตของเรื่องหนึ่งเรื่อง — หัวมี ‹ กับชื่อ ข้างล่างคือตัวเลือกทั้งหมดของเรื่องนั้น · มาแทนแถบหลักทั้งใบ
 *
 * ชื่อคือ **เรื่อง** ไม่ใช่ชื่อแบบของชิ้น — "โปรไฟล์" ไม่ใช่ "ออร่า"
 * ขีดบนหัวชีต (ทั้งแถบหัว) ลากขึ้นลงได้ ปล่อยแล้วดีดเข้าระดับที่ใกล้สุด · **ลากลงไม่ปิดชีต** ต่ำสุดคือ "หุบ"
 * ปิดได้ทางเดียวคือ ‹ หรือแตะที่ว่างบนการ์ด
 * - viewport: ความสูงจอ — ใช้คิดระดับครึ่งจอ/สูง
 * - fill: เนื้อหาเลื่อนในตัวเอง ต้องได้ความสูงเต็มช่อง (ไม่ใช่สูงตามเนื้อหา)
 */
@Composable
fun DockSheet(
    title: String,
    symbol: String,
    viewport: Float = 874f,
    fill: Boolean = false,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val scope = rememberCoroutineScope()
    val st = remember { DockSheetDrag(scope) }
    st.viewport = viewport
    st.fill = fill
    val density = LocalDensity.current.density

    // เนื้อในชีตตามหลังตัวชีตมาหนึ่งจังหวะ — ชีตไหลขึ้นมาก่อน แล้วตัวเลือกค่อยลอยเข้าที่
    val settled = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(60)
        settled.animateTo(1f, Motion.settle.float)
    }

    val shape = RoundedCornerShape(26.dp)
    CompositionLocalProvider(LocalCardInk provides InkStyle.night) {
        Box(
            modifier
                .fillMaxWidth()
                .graphicsLayer { translationY = st.sink * density }
                .padding(horizontal = 12.dp),
        ) {
            GlassPanel(
                veil = DockGlassVeil,
                radius = 26f,
                // ม่านบางใต้เนื้อหา — กระจกล้วนโปร่งจนชิปจมเวลาการ์ดสว่างมุดอยู่ข้างใต้
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color.Black.opacity(0.26), shape),
            ) {
                Column(
                    Modifier
                        .fillMaxWidth()
                        .padding(start = 14.dp, end = 14.dp, bottom = 14.dp),
                ) {
                    DockSheetHeader(title = title, symbol = symbol, st = st, onBack = onBack)
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .clipToBounds()
                            .graphicsLayer {
                                val s = settled.value
                                // หุบลงไป เนื้อหาจางตามแทนที่จะโดนตัดเป็นเส้นคม
                                alpha = min(1f, max(0f, st.liveHeight) / 60f) * s.coerceIn(0f, 1f)
                                translationY = 14f * density * (1f - s)
                            }
                            .layout { measurable, constraints ->
                                if (fill) {
                                    val h = max(0f, st.liveHeight).dp.roundToPx()
                                    val p = measurable.measure(constraints.copy(minHeight = h, maxHeight = h))
                                    layout(p.width, h) { p.placeRelative(0, 0) }
                                } else {
                                    val p = measurable.measure(
                                        constraints.copy(minHeight = 0, maxHeight = Constraints.Infinity),
                                    )
                                    // ยังไม่ได้วัดเนื้อหา = ปล่อยสูงตามธรรมชาติ (เฟรมแรกไม่วูบเป็น 0)
                                    val h = if (st.natural == 0f) p.height else max(0f, st.liveHeight).dp.roundToPx()
                                    layout(p.width, h) { p.placeRelative(0, 0) }
                                }
                            },
                    ) {
                        Box(
                            if (fill) {
                                Modifier.fillMaxSize()
                            } else {
                                Modifier
                                    .fillMaxWidth()
                                    .onSizeChanged { st.natural = it.height / density }
                            },
                        ) { content() }
                    }
                }
            }
        }
    }
}

/** ขีดลาก + ‹ + ชื่อ — ทั้งแถบคือที่จับ */
@Composable
private fun DockSheetHeader(title: String, symbol: String, st: DockSheetDrag, onBack: () -> Unit) {
    val handle by animateColorAsState(
        Color.White.opacity(if (st.drag == 0f) 0.3 else 0.55), Motion.snap.spec(), label = "sheetHandle",
    )
    val bottom by animateFloatAsState(if (st.collapsed) 0f else 12f, Motion.settle.float, label = "sheetHeaderPad")
    val ref = remember { DockSheetCoords() }

    Column(
        Modifier
            .fillMaxWidth()
            .onGloballyPositioned { ref.coords = it }
            .pointerInput(st) {
                awaitEachGesture {
                    // ปุ่ม ‹ รับแตะของมันเองก่อน
                    val down = awaitFirstDown(requireUnconsumed = true)
                    val pid = down.id
                    fun root(o: Offset): Offset = ref.coords?.takeIf { it.isAttached }?.localToRoot(o) ?: o
                    val start = root(down.position)
                    val tracker = VelocityTracker()
                    tracker.addPosition(down.uptimeMillis, start)
                    val slop = 4.dp.toPx()
                    var dragging = false
                    var dy = 0f
                    var done = false
                    while (true) {
                        val ev = awaitPointerEvent()
                        val ch = ev.changes.firstOrNull { it.id == pid } ?: break
                        val r = root(ch.position)
                        tracker.addPosition(ch.uptimeMillis, r)
                        dy = (r.y - start.y) / density
                        if (!ch.pressed) {
                            ch.consume()
                            if (dragging) {
                                val vy = tracker.calculateVelocity().y / density
                                st.settle(predicted = -(dy + vy * SheetFlingProjection))
                            } else if (st.currentLevel == 0) {
                                // หุบอยู่ แตะหัวชีต = กางกลับระดับตั้งต้น
                                Haptics.impact(Haptics.Style.light)
                                st.goTo(st.defaultLevel)
                            }
                            done = true
                            break
                        }
                        if (!dragging && (r - start).getDistance() > slop) {
                            dragging = true
                            st.beginDrag()
                        }
                        if (dragging) {
                            ch.consume()
                            st.dragTo(dy)
                        }
                    }
                    if (dragging && !done) st.settle(predicted = -dy)
                }
            }
            .semantics {
                customActions = listOf(
                    CustomAccessibilityAction("ขยายชีต") { st.step(1); true },
                    CustomAccessibilityAction("ย่อชีต") { st.step(-1); true },
                )
            }
            .padding(bottom = bottom.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            Modifier
                .padding(top = 7.dp)
                .size(36.dp, 5.dp)
                .background(handle, CircleShape),
        )

        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                Modifier
                    .dockPress(onClick = onBack)
                    .size(36.dp)
                    .background(Color.White.opacity(0.1), CircleShape)
                    .semantics {
                        contentDescription = "กลับ"
                        role = Role.Button
                    },
                contentAlignment = Alignment.Center,
            ) {
                SFSymbol("chevron.left", size = 15f, tint = Color.White.opacity(0.92))
            }

            // ชื่อเปลี่ยน (แตะชิ้นอื่น) = crossfade ไม่ใช่กระโดด
            Crossfade(
                targetState = title,
                modifier = Modifier.weight(1f),
                animationSpec = Motion.snap.spec(),
                label = "sheetTitle",
            ) { t ->
                Row(
                    horizontalArrangement = Arrangement.spacedBy(7.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    DockSymbol(symbol, size = 14f, tint = Color.White.opacity(0.94 * 0.8))
                    Text(
                        t,
                        style = sh(15f, SHFont.semibold),
                        color = Color.White.opacity(0.94),
                        maxLines = 1,
                        softWrap = false,
                        autoSize = TextAutoSize.StepBased(
                            minFontSize = (15f * 0.7f).sp, maxFontSize = 15.sp, stepSize = 0.5.sp,
                        ),
                        modifier = Modifier.weight(1f, fill = false),
                    )
                }
            }
        }
    }
}

/** หนึ่งแถวในถาด — ป้ายสั้น ๆ ทางซ้าย ตัวเลือกทางขวา */
@Composable
fun DockRow(
    label: String,
    dim: Boolean = false,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Row(
        modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            label,
            style = sh(11.5f, SHFont.semibold),
            color = Color.White.opacity(if (dim) 0.28 else 0.5),
            maxLines = 1,
            softWrap = false,
            autoSize = TextAutoSize.StepBased(minFontSize = (11.5f * 0.8f).sp, maxFontSize = 11.5.sp, stepSize = 0.5.sp),
            modifier = Modifier.width(40.dp),
        )
        Box(Modifier.weight(1f), contentAlignment = Alignment.CenterStart) { content() }
    }
}

/** ชนิดของตัวเลือกใน `DockSegment` (= `DockSegment<T>.Option` ของ Swift) */
object DockSegment {
    /** หนึ่งช่อง — มี `symbol` = แสดงไอคอนแทนชื่อ */
    data class Option<T>(val value: T, val title: String, val symbol: String? = null)
}

/** ชื่อสั้นของ `DockSegment.Option` */
typealias DockSegmentOption<T> = DockSegment.Option<T>

/** ตัวเลือกแบบแบ่งช่อง — ไฮไลต์ **ไหล** ไปช่องที่แตะ ไม่กระพริบหายแล้วโผล่ */
@Composable
fun <T> DockSegment(
    options: List<DockSegment.Option<T>>,
    selection: T,
    dim: Boolean = false,
    onPick: (T) -> Unit,
    modifier: Modifier = Modifier,
) {
    val idx = options.indexOfFirst { it.value == selection }
    // ไม่มีช่องไหนถูกเลือก = ไฮไลต์จางหาย แต่จำที่เดิมไว้ ไม่ไหลกลับไปช่องแรก
    val last = remember { intArrayOf(0) }
    if (idx >= 0) last[0] = idx
    val pos by animateFloatAsState(last[0].toFloat(), Motion.snap.float, label = "segmentPos")
    val shown by animateFloatAsState(if (idx >= 0) 1f else 0f, Motion.snap.float, label = "segmentShown")
    val highlight = Color.White.opacity(if (dim) 0.35 else 0.92)
    val count = options.size

    Row(
        modifier
            .fillMaxWidth()
            .background(Color.Black.opacity(0.28), CircleShape)
            .padding(3.dp)
            .drawBehind {
                if (count == 0 || shown <= 0f) return@drawBehind
                val gap = 2.dp.toPx()
                val w = (size.width - gap * (count - 1)) / count
                drawRoundRect(
                    color = highlight.copy(alpha = highlight.alpha * shown.coerceIn(0f, 1f)),
                    topLeft = Offset(pos * (w + gap), 0f),
                    size = Size(w, size.height),
                    cornerRadius = CornerRadius(size.height / 2f, size.height / 2f),
                )
            },
        horizontalArrangement = Arrangement.spacedBy(2.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        options.forEach { o ->
            val on = o.value == selection
            val fg by animateColorAsState(
                if (on) Color.Black.opacity(0.86) else Color.White.opacity(if (dim) 0.32 else 0.74),
                Motion.snap.spec(),
                label = "segmentFg",
            )
            Box(
                Modifier
                    .weight(1f)
                    .height(30.dp)
                    .tap { onPick(o.value) },
                contentAlignment = Alignment.Center,
            ) {
                val s = o.symbol
                if (s != null) {
                    DockSymbol(s, size = 12f, tint = fg)
                } else {
                    Text(
                        o.title,
                        style = sh(11.5f, SHFont.semibold),
                        color = fg,
                        maxLines = 1,
                        softWrap = false,
                        autoSize = TextAutoSize.StepBased(
                            minFontSize = (11.5f * 0.7f).sp, maxFontSize = 11.5.sp, stepSize = 0.5.sp,
                        ),
                    )
                }
            }
        }
    }
}
