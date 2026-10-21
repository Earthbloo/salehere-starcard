package co.salehere.starcard.ui.salehere.starflow

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
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
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathMeasure
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.LastBaseline
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.AppContext
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.StageGlassPanel
import co.salehere.starcard.ui.dockPress
import co.salehere.starcard.ui.tap
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Locale
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cbrt
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

// MARK: - ST★R Insight — ใครมาดู Star Card ของฉัน (ผู้ใช้ 4 ต.ค. 2569) (= StarInsightPage.swift)
//
// หน้านี้มีแค่ 3 ก้อน เรียงเป็นกรวยเดียวจากบนลงล่าง: ยอดวิว (เลขเด่นตัวเดียว + กราฟเดียว) → กดเข้ามาดูการ์ด → แบรนด์สายไหน
// แล้วจบด้วยปุ่มชุดเดียวกับหน้า Star Card (แต่งการ์ด · แชร์) — ไม่มีกล่อง ไม่มีแท็บ ไม่มีตัวกรองนอกจากช่วงเวลา 2 ค่า
// โทน = ดำล้วน ตัวเลขขาว ตัวกราฟมีสี สีเดียวทั้งหน้า = สีของการ์ดใบที่แสดงอยู่ · เขียวใช้กับลูกศรขึ้นของ % เท่านั้น
// ตัวเลขทั้งหมดมาจาก `StarInsight.mock` — ยังไม่มีระบบนับยอดดูจริง (Android ไม่มี model/StarInsight.kt จึงอยู่ในไฟล์นี้)

// MARK: - ข้อมูลจำลอง (= Model/StarInsight.swift)

/** สถิติคนดู Star Card — **ข้อมูลจำลอง** ของต้นแบบ · ชื่อสายใช้ชุดเดียวกับ "สายที่ใช่" ของ Star Profile */
data class StarInsight(
    /** ยอดเห็นรายวัน (เก่า → ใหม่ · ตัวสุดท้าย = วันนี้) */
    val daily: List<Int>,
    /** ช่วงก่อนหน้าที่ยาวเท่ากัน — ไว้คิด % ขึ้น/ลง */
    val previousViews: Int,
    /** กดเข้ามาเปิดดูการ์ด */
    val opened: Int,
    /** แบรนด์ (คนละราย) ที่เปิดดู แยกตามสาย — เรียงมากไปน้อย ตัวท้าย = "อื่น ๆ" */
    val styles: List<Style>,
    /** ป้ายใต้กราฟ (ซ้าย → ขวา) */
    val axis: List<String>,
    /** ชื่อวันของแต่ละจุด — ไว้อ่านค่าตอนลากนิ้วบนกราฟ */
    val dayNames: List<String>,
    /** เหตุของวันที่ยอดสูงสุด (จากประวัติการแชร์การ์ด) */
    val peakNote: String,
    /** ของใหม่วันนี้ — เรื่องเดียวกับที่แจ้งเตือนบอก ("แบรนด์สายคาเฟ่ 3 รายดูการ์ดคุณ") */
    val today: Style? = null,
) {
    enum class Range(val raw: String) { week("7 วัน"), month("28 วัน") }

    data class Style(val name: String, val brands: Int)

    val views: Int get() = daily.sum()
    val change: Double get() = if (previousViews == 0) 0.0 else (views - previousViews).toDouble() / previousViews
    val openRate: Double get() = if (views == 0) 0.0 else opened.toDouble() / views
    val brands: Int get() = styles.sumOf { it.brands }
    val peakIndex: Int get() = daily.indices.maxByOrNull { daily[it] } ?: 0
    val isEmpty: Boolean get() = views == 0

    companion object {
        /** ยังไม่เคยมีคนเห็นเลยสักช่วง (ต่างจาก "ช่วงนี้ไม่มี" ที่ยังสลับไปดูช่วงอื่นได้) */
        val neverSeen: Boolean get() = Range.entries.all { mock(it).isEmpty }

        fun mock(r: Range): StarInsight {
            // ลองสถานะว่าง: prefs `insightEmpty` = "YES" → ยังไม่เคยมีคนเห็น · "week" → 7 วันล่าสุดเงียบ แต่ 28 วันมีข้อมูล
            val quiet = runCatching { AppContext.prefs.getString("insightEmpty", "") ?: "" }.getOrDefault("")
            if (quiet == "YES" || (quiet == "week" && r == Range.week)) return empty
            return when (r) {
                Range.week -> StarInsight(
                    daily = week, previousViews = 3_322, opened = 1_284,
                    styles = listOf(Style("คาเฟ่", 14), Style("บิวตี้", 9), Style("แฟชั่น", 6), Style("อื่น ๆ", 5)),
                    axis = listOf("จ", "อ", "พ", "พฤ", "ศ", "ส", "อา"),
                    dayNames = listOf("จันทร์", "อังคาร", "พุธ", "พฤหัสบดี", "ศุกร์", "เสาร์", "วันนี้"),
                    peakNote = "วันที่แชร์ลง IG Story",
                    today = Style("คาเฟ่", 3),
                )
                Range.month -> {
                    val d = listOf(
                        352, 371, 398, 420, 388, 365, 342, 377, 402, 431, 455, 418, 392, 380,
                        405, 428, 462, 480, 441, 423, 430,
                    ) + week
                    // วันนี้ = อาทิตย์ 4 ต.ค. 2569 → จุดแรก = จันทร์ 7 ก.ย.
                    val names = (0 until 28).map { i ->
                        if (i == 27) "วันนี้" else {
                            val day = 7 + i
                            if (day <= 30) "$day ก.ย." else "${day - 30} ต.ค."
                        }
                    }
                    StarInsight(
                        daily = d, previousViews = 10_400, opened = 3_870,
                        styles = listOf(Style("คาเฟ่", 43), Style("บิวตี้", 31), Style("แฟชั่น", 22), Style("อื่น ๆ", 16)),
                        axis = listOf("7 ก.ย.", "21 ก.ย.", "วันนี้"),
                        dayNames = names,
                        peakNote = "วันที่แชร์ลง IG Story",
                        today = Style("คาเฟ่", 3),
                    )
                }
            }
        }

        private val week = listOf(318, 362, 948, 622, 521, 468, 681)

        val empty = StarInsight(
            daily = List(7) { 0 }, previousViews = 0, opened = 0, styles = emptyList(),
            axis = emptyList(), dayNames = emptyList(), peakNote = "",
        )

        fun fmt(n: Int): String = String.format(Locale.US, "%,d", n)
    }
}

// MARK: - สี

object InsightInk {
    /**
     * สีของกราฟทั้งหน้า (เส้น · แถบเด่น · จุด) = **เฉดสีของการ์ดใบที่แสดงอยู่** ปรับความสว่าง/ความสดให้เท่ากันทุกเฉด
     * (OKLCH L 0.66 · C สูงสุดที่จอแสดงได้) — การ์ดโทนไม่มีสี (ดำ/ขาว/เทา) หรือยังไม่มีการ์ด = ฟ้า
     * ลองสีตายตัว: prefs `insightTint` = blue|green|violet|red
     */
    fun mark(theme: CardTheme?): Color {
        when (runCatching { AppContext.prefs.getString("insightTint", null) }.getOrNull()) {
            "blue" -> return blue
            "green" -> return rgb(31 / 255.0, 174 / 255.0, 110 / 255.0)    // #1FAE6E
            "violet" -> return rgb(146 / 255.0, 119 / 255.0, 242 / 255.0)  // #9277F2
            "red" -> return rgb(248 / 255.0, 69 / 255.0, 79 / 255.0)       // #F8454F
        }
        if (theme == null) return blue
        // เฉดของพื้นการ์ดก่อน (สีที่คนจำการ์ดใบนั้นได้) · พื้นไม่มีสี = ใช้เฉดของสีเน้น
        for (source in listOf(theme.backdropColors.top, theme.rawAccent)) {
            val lab = OKLab(source)
            if (lab.chroma >= 0.035) return OKLab.color(lightness = 0.66, chroma = 0.2, hue = lab.hue)
        }
        return blue
    }

    val blue = rgb(61 / 255.0, 141 / 255.0, 245 / 255.0)           // #3D8DF5
    val up = rgb(110 / 255.0, 231 / 255.0, 170 / 255.0)
    val soft = Color.White.opacity(0.74)
    val faint = Color.White.opacity(0.6)
    val rule = Color.White.opacity(0.13)
}

// MARK: - หน้า

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StarInsightPage(
    /** ธีมของการ์ดใบที่แสดงอยู่ — สีของกราฟ */
    theme: CardTheme?,
    onClose: () -> Unit,
    onEditCard: () -> Unit = {},
    onShare: () -> Unit = {},
    modifier: Modifier = Modifier,
) {
    var range by remember { mutableStateOf(StarInsight.Range.week) }
    /** 0…1 ของการวาดกราฟ/แถบ (= `drawn`) */
    val drawn = remember { Animatable(0f) }
    /** จุดที่นิ้วลากอยู่บนกราฟ — null = ไม่ได้ลาก (โชว์ป้ายวันที่ยอดสูงสุดแทน) */
    var scrub by remember { mutableStateOf<Int?>(null) }
    /** ข้อมูลชุดนี้ดึงมาเมื่อไหร่ — ลากหน้าลงเพื่อดึงใหม่ */
    var updated by remember { mutableLongStateOf(System.currentTimeMillis()) }
    var refreshing by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    val data = remember(range, updated) { StarInsight.mock(range) }
    val mark = remember(theme) { InsightInk.mark(theme) }

    suspend fun redraw() {
        scrub = null
        drawn.snapTo(0f)
        delay(120)
        drawn.animateTo(1f, tween(1100, easing = FlowEase))
    }
    LaunchedEffect(range) { redraw() }

    BackHandler { onClose() }

    Box(modifier.fillMaxSize()) {
        InsightGround()

        PullToRefreshBox(
            isRefreshing = refreshing,
            onRefresh = {
                // ลากลง = ดึงข้อมูลใหม่ (ต้นแบบ: หน่วงสั้น ๆ แล้ววาดกราฟใหม่ ข้อมูลชุดเดิม)
                Haptics.impact(Haptics.Style.medium)
                scope.launch {
                    refreshing = true
                    delay(700)
                    updated = System.currentTimeMillis()
                    refreshing = false
                    redraw()
                }
            },
            modifier = Modifier.fillMaxSize(),
        ) {
            Column(
                Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .statusBarsPadding()
                    .padding(bottom = 108.dp),
            ) {
                InsightHeader(range = range, onRange = { range = it })
                when {
                    StarInsight.neverSeen -> InsightEmpty(Modifier.padding(top = 72.dp))
                    data.isEmpty -> InsightQuietRange(range = range, onRange = { range = it }, modifier = Modifier.padding(top = 72.dp))
                    else -> Column(Modifier.padding(horizontal = 20.dp)) {
                        TodayLine(data, Modifier.padding(top = 14.dp))
                        InsightHero(data = data, range = range, updated = updated, modifier = Modifier.padding(top = 12.dp))
                        InsightChart(
                            data = data, mark = mark, drawn = { drawn.value }, scrub = scrub, onScrub = { scrub = it },
                            modifier = Modifier.fillMaxWidth().height(128.dp).padding(top = 8.dp),
                        )
                        InsightRule()
                        InsightOpens(data = data, mark = mark, drawn = { drawn.value })
                        InsightRule()
                        InsightBrands(data = data, mark = mark, drawn = { drawn.value })
                    }
                }
            }
        }

        // ปุ่มกลับ ‹ — กระจกโทนมืดบนเวทีดำ
        Row(Modifier.statusBarsPadding().padding(horizontal = 16.dp).padding(top = 8.dp)) {
            StageGlassPanel(
                radius = 22f,
                modifier = Modifier
                    .size(44.dp)
                    .semantics { contentDescription = "กลับ" }
                    .dockPress {
                        Haptics.impact(Haptics.Style.light)
                        onClose()
                    },
            ) {
                Box(Modifier.size(44.dp), contentAlignment = Alignment.Center) {
                    PIcon(Ph.caretLeft, size = 17f, weight = PhWeight.bold, tint = Color.White.opacity(0.92))
                }
            }
        }

        // ปัดจากขอบซ้าย = กลับ (ปุ่ม ‹ อยู่มุมบนที่นิ้วโป้งเอื้อมยาก)
        Box(
            Modifier
                .align(Alignment.CenterStart)
                .width(18.dp)
                .fillMaxHeight()
                .pointerInput(onClose) {
                    var dx = 0f
                    var startY = 0f
                    var lastY = 0f
                    detectHorizontalDragGestures(
                        onDragStart = { p -> dx = 0f; startY = p.y; lastY = p.y },
                        onDragEnd = { if (dx > 70.dp.toPx() && abs(lastY - startY) < 90.dp.toPx()) onClose() },
                        onHorizontalDrag = { change, amount -> dx += amount; lastY = change.position.y },
                    )
                },
        )

        InsightDock(
            empty = data.isEmpty, onEditCard = onEditCard, onShare = onShare,
            modifier = Modifier.align(Alignment.BottomCenter),
        )
    }
}

// MARK: เวที — ดำล้วน ไม่ย้อมสีธีมการ์ด · แสงขาวจางมากดวงเดียวหลังหัวกับเลขเด่น

@Composable
private fun InsightGround() {
    Canvas(Modifier.fillMaxSize()) {
        drawRect(Brush.verticalGradient(listOf(rgb(14 / 255.0, 14 / 255.0, 16 / 255.0), rgb(6 / 255.0, 6 / 255.0, 8 / 255.0))))
        // วงกลมขาว 380 เบลอ 120 โปร่ง 0.07 — จำลองด้วยไล่สีรัศมี
        val c = Offset(size.width * 0.16f, 170.dp.toPx())
        val r = (190f + 120f).dp.toPx()
        drawCircle(
            Brush.radialGradient(listOf(Color.White.opacity(0.07), Color.White.opacity(0.045), Color.Transparent), center = c, radius = r),
            radius = r, center = c,
        )
    }
}

// MARK: หัว: ST★R Insight + ช่วงเวลา (ตัวกรองเดียวของหน้า อยู่เหนือทุกอย่างที่มันคุม)

@Composable
private fun InsightHeader(range: StarInsight.Range, onRange: (StarInsight.Range) -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .padding(top = 50.dp)
            .height(64.dp),
        verticalAlignment = Alignment.Bottom,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(
            Modifier.semantics { contentDescription = "Star Insight"; heading() },
            horizontalArrangement = Arrangement.spacedBy(StarCaps.gapForSerif(46f).dp),
        ) {
            StarCaps(height = StarCaps.heightForSerif(46f), color = Color.White, modifier = Modifier.alignBy(LastBaseline))
            BasicText(
                "Insight", Modifier.alignBy(LastBaseline),
                style = GL.serif(46f).merge(TextStyle(brush = serifInkBrush(onDark = true))),
                maxLines = 1, softWrap = false,
            )
        }
        Spacer(Modifier.weight(1f))
        // ยังไม่เคยมีคนเห็น = ไม่มีช่วงให้เลือก · ช่วงนี้เงียบแต่ช่วงอื่นมี = ตัวเลือกต้องยังอยู่
        if (!StarInsight.neverSeen) RangeToggle(range, onRange, Modifier.padding(bottom = 5.dp))
    }
}

@Composable
private fun RangeToggle(range: StarInsight.Range, onRange: (StarInsight.Range) -> Unit, modifier: Modifier = Modifier) {
    StageGlassPanel(radius = 19f, modifier = modifier.border(0.6.dp, Color.White.opacity(0.2), CircleShape)) {
        Row(Modifier.padding(3.dp), horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            for (r in StarInsight.Range.entries) {
                val on = r == range
                Box(
                    Modifier
                        .semantics { contentDescription = "ช่วง ${r.raw}ล่าสุด" }
                        .tap {
                            if (!on) {
                                Haptics.impact(Haptics.Style.light)
                                onRange(r)
                            }
                        }
                        .height(32.dp)
                        .background(if (on) Color.White.opacity(0.94) else Color.Transparent, CircleShape)
                        .padding(horizontal = 11.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(r.raw, style = sh(13f, SHFont.bold), color = if (on) Color.Black.opacity(0.88) else Color.White.opacity(0.88), maxLines = 1, softWrap = false)
                }
            }
        }
    }
}

// MARK: ของใหม่วันนี้ — บรรทัดเดียว เรื่องเดียวกับข้อความแจ้งเตือน (ไม่มีอะไรใหม่ = ไม่มีบรรทัดนี้)

@Composable
private fun TodayLine(data: StarInsight, modifier: Modifier = Modifier) {
    val t = data.today ?: return
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(7.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(7.dp).background(InsightInk.up, CircleShape))
        Text(
            "วันนี้ แบรนด์สาย${t.name}เข้ามาดู ${t.brands} ราย",
            style = sh(13.5f, SHFont.semibold), color = Color.White.opacity(0.92), maxLines = 1, overflow = TextOverflow.Ellipsis,
        )
    }
}

// MARK: ก้อน 1 — ยอดวิว: เลขเด่นตัวเดียวของหน้า + เทียบช่วงก่อนหน้า

@Composable
private fun InsightHero(data: StarInsight, range: StarInsight.Range, updated: Long, modifier: Modifier = Modifier) {
    // ข้อมูลสดแค่ไหน — นับจากครั้งล่าสุดที่ดึง (ทุก 30 วิ = `TimelineView(.periodic(by: 30))`)
    var now by remember(updated) { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(updated) {
        while (true) {
            delay(30_000)
            now = System.currentTimeMillis()
        }
    }
    val m = ((now - updated) / 60_000L).toInt()
    val fresh = if (m < 1) "อัปเดตเมื่อสักครู่" else if (m < 60) "อัปเดต $m นาทีที่แล้ว" else "อัปเดต ${m / 60} ชม. ที่แล้ว"

    Column(
        modifier.semantics {
            contentDescription = "ยอดวิว ${range.raw}ล่าสุด ${data.views} ครั้ง" +
                (if (data.previousViews > 0) " " + DeltaLine.spoken(data.change, "${range.raw}ก่อน") else "")
        },
    ) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
            Text("ยอดวิว", style = sh(15f, SHFont.semibold), color = InsightInk.soft)
            Spacer(Modifier.weight(1f))
            Text(fresh, style = sh(12f, SHFont.medium), color = InsightInk.faint)
        }
        // เลขกับ % อยู่บรรทัดเดียวกัน (ViewThatFits ของ iOS ลงบรรทัดใหม่เมื่อไม่พอ — เลข 5 หลักพอทุกจอโทรศัพท์)
        Row(Modifier.offset(y = (-4).dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(
                StarInsight.fmt(data.views),
                style = sh(54f, SHFont.heavy).copy(letterSpacing = (-1).sp), color = Color.White,
                maxLines = 1, softWrap = false, modifier = Modifier.alignBy(LastBaseline),
            )
            if (data.previousViews > 0) {
                DeltaLine(change = data.change, baseline = "${range.raw}ก่อน", before = data.previousViews, now = data.views, modifier = Modifier.alignBy(LastBaseline))
            }
        }
    }
}

/**
 * ▲ 18% จาก 7 วันก่อน — ลูกศร + ตัวเลข + ช่วงที่เทียบ (ไม่ใช้สีอย่างเดียว) · ลดลง = สีกลาง ไม่ใช้แดง
 * ฐานเล็ก (ช่วงก่อนไม่ถึง 20 ครั้ง) % แกว่งจนไม่มีความหมาย — บอกเป็นจำนวนครั้งแทน
 */
@Composable
fun DeltaLine(change: Double, baseline: String, before: Int = 100, now: Int = 100, modifier: Modifier = Modifier) {
    val up = change >= 0
    val tint = if (up) InsightInk.up else InsightInk.soft
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
        PIcon(if (up) Ph.trendUp else Ph.trendDown, size = 14f, weight = PhWeight.bold, tint = tint)
        Text(
            if (before < 20) "${abs(now - before)} ครั้ง" else "${(abs(change) * 100).roundToInt()}%",
            style = sh(15f, SHFont.bold), color = tint,
        )
        Text("จาก $baseline", style = sh(14f, SHFont.medium), color = InsightInk.soft)
    }
}

object DeltaLine {
    fun spoken(change: Double, baseline: String): String =
        "${if (change >= 0) "เพิ่มขึ้น" else "ลดลง"} ${(abs(change) * 100).roundToInt()} เปอร์เซ็นต์ จาก $baseline"
}

// MARK: ก้อน 2 — กดเข้ามาดูการ์ด: จำนวน + สัดส่วนของยอดวิว

@Composable
private fun InsightOpens(data: StarInsight, mark: Color, drawn: () -> Float) {
    val pct = (data.openRate * 100).roundToInt()
    Column(
        Modifier.semantics {
            contentDescription = "กดเข้ามาดูการ์ด ${data.opened} ครั้ง" + (if (data.opened == 0) "" else " คิดเป็น $pct เปอร์เซ็นต์ของยอดวิว")
        },
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        RowHead("กดเข้ามาดูการ์ด", StarInsight.fmt(data.opened), "ครั้ง")
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
            // รางเป็นสีเดียวกับแถบแต่จางกว่า — อ่านเป็นส่วนของทั้งหมด
            Canvas(Modifier.weight(1f).height(8.dp)) {
                drawRoundRect(mark.opacity(0.24), cornerRadius = CornerRadius(size.height / 2f))
                val w = max(8.dp.toPx(), size.width * (data.openRate * drawn()).toFloat())
                drawRoundRect(mark, size = Size(w, size.height), cornerRadius = CornerRadius(size.height / 2f))
            }
            Text(
                if (data.opened == 0) "ยังไม่มีคนกดเข้ามา" else "$pct% ของยอดวิว",
                style = sh(13f, SHFont.medium), color = InsightInk.soft,
            )
        }
    }
}

// MARK: ก้อน 3 — แบรนด์สายไหน: หัวข้อคือข้อสรุป แถบเรียงมากไปน้อย เน้นแถวแรกแถวเดียว

@Composable
private fun InsightBrands(data: StarInsight, mark: Color, drawn: () -> Float) {
    val top = data.styles.firstOrNull()
    val most = (top?.brands ?: 1).toDouble()
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        RowHead(top?.let { "แบรนด์สาย${it.name}ดูคุณมากที่สุด" } ?: "แบรนด์ที่ดูคุณ", "${data.brands}", "แบรนด์")
        // ตาราง 3 คอลัมน์: ชื่อสาย (กว้างเท่าชื่อยาวสุด) · แถบ · จำนวน (= `Grid`)
        BrandGrid(rows = data.styles.size, hSpacing = 12f, vSpacing = 10f) {
            data.styles.forEachIndexed { i, s ->
                Text(
                    s.name, style = sh(14f, if (i == 0) SHFont.semibold else SHFont.medium),
                    color = if (i == 0) Color.White else InsightInk.soft, maxLines = 1, softWrap = false,
                    modifier = Modifier.semantics { contentDescription = "สาย${s.name} ${s.brands} แบรนด์" },
                )
                Canvas(Modifier.fillMaxWidth().height(8.dp)) {
                    // โคนแถบเหลี่ยม ปลายมน — ทุกแถวโตจากเส้นฐานเดียวกัน
                    val w = max(4.dp.toPx(), size.width * (s.brands / most * drawn()).toFloat())
                    val path = Path().apply {
                        addRoundRect(
                            androidx.compose.ui.geometry.RoundRect(
                                Rect(0f, 0f, w, size.height),
                                topLeft = CornerRadius(1.dp.toPx()), bottomLeft = CornerRadius(1.dp.toPx()),
                                topRight = CornerRadius(4.dp.toPx()), bottomRight = CornerRadius(4.dp.toPx()),
                            ),
                        )
                    }
                    drawPath(path, if (i == 0) mark else Color.White.opacity(0.42))
                }
                Text("${s.brands}", style = sh(14f, SHFont.bold).tnum(), color = Color.White, textAlign = TextAlign.End, maxLines = 1, softWrap = false)
            }
        }
        if (top != null) {
            Text("ลองวางผลงาน${top.name}ไว้หน้าแรกของการ์ด", style = sh(13f, SHFont.medium), color = InsightInk.faint)
        } else {
            // มีคนเห็นแล้วแต่ยังไม่มีแบรนด์ — บอกตรง ๆ ไม่ปล่อยเป็นที่ว่าง
            Text("ยังไม่มีแบรนด์เข้ามาดูในช่วงนี้", style = sh(14f, SHFont.medium), color = InsightInk.soft)
        }
    }
}

/** ตาราง 3 คอลัมน์ (ชื่อ · แถบยืด · ตัวเลขชิดขวา) — คอลัมน์ชื่อ/ตัวเลขกว้างเท่าตัวที่กว้างสุด แถบได้ที่เหลือ */
@Composable
private fun BrandGrid(rows: Int, hSpacing: Float, vSpacing: Float, content: @Composable () -> Unit) {
    Layout(content, Modifier.fillMaxWidth()) { measurables, constraints ->
        if (rows == 0 || measurables.size < rows * 3) return@Layout layout(constraints.maxWidth, 0) {}
        val h = hSpacing.dp.roundToPx()
        val v = vSpacing.dp.roundToPx()
        val loose = Constraints()
        val names = (0 until rows).map { measurables[it * 3].measure(loose) }
        val counts = (0 until rows).map { measurables[it * 3 + 2].measure(loose) }
        val nameW = names.maxOf { it.width }
        val countW = counts.maxOf { it.width }
        val barW = (constraints.maxWidth - nameW - countW - 2 * h).coerceAtLeast(0)
        val bars = (0 until rows).map { measurables[it * 3 + 1].measure(Constraints.fixedWidth(barW)) }
        val rowH = (0 until rows).map { maxOf(names[it].height, bars[it].height, counts[it].height) }
        val total = rowH.sum() + v * (rows - 1)
        layout(constraints.maxWidth, total) {
            var y = 0
            for (i in 0 until rows) {
                val rh = rowH[i]
                names[i].placeRelative(0, y + (rh - names[i].height) / 2)
                bars[i].placeRelative(nameW + h, y + (rh - bars[i].height) / 2)
                counts[i].placeRelative(constraints.maxWidth - counts[i].width, y + (rh - counts[i].height) / 2)
                y += rh + v
            }
        }
    }
}

/** หัวของก้อน: ข้อความซ้าย · ตัวเลข + หน่วย ขวา (ตัวเลขทุกก้อนอยู่แนวเดียวกัน กวาดตาลงมาอ่านได้) */
@Composable
private fun RowHead(title: String, value: String, unit: String) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            title, style = sh(16f, SHFont.semibold), color = Color.White, maxLines = 1, overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f).alignBy(LastBaseline),
        )
        Text(value, style = sh(20f, SHFont.heavy).tnum(), color = Color.White, modifier = Modifier.alignBy(LastBaseline))
        Text(unit, style = sh(13f, SHFont.medium), color = InsightInk.soft, modifier = Modifier.offset(x = (-3).dp).alignBy(LastBaseline))
    }
}

@Composable
private fun InsightRule() {
    Box(Modifier.fillMaxWidth().padding(vertical = 13.dp).height(1.dp).background(InsightInk.rule))
}

// MARK: ยังไม่มีคนเห็น — บอกว่าต้องทำอะไร ไม่โชว์กราฟเปล่า

@Composable
private fun InsightEmpty(modifier: Modifier = Modifier) {
    Column(
        modifier.fillMaxWidth().padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            Modifier
                .padding(bottom = 6.dp)
                .size(72.dp)
                .background(Color.White.opacity(0.08), CircleShape)
                .border(0.8.dp, Color.White.opacity(0.16), CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            PIcon(Ph.chartLineUp, size = 30f, weight = PhWeight.bold, tint = Color.White)
        }
        Text("ยังไม่มีคนเห็นการ์ด", style = sh(20f, SHFont.bold), color = Color.White)
        Text(
            "แชร์ลิงก์การ์ดของคุณ\nยอดวิวและแบรนด์ที่เข้ามาดูจะขึ้นที่นี่",
            style = sh(15f).lineSpaced(4f), color = InsightInk.soft, textAlign = TextAlign.Center,
        )
    }
}

/** ช่วงที่เลือกเงียบ แต่ช่วงอื่นมีข้อมูล — บอกว่าช่วงไหน แล้วพาไปช่วงที่มี */
@Composable
private fun InsightQuietRange(range: StarInsight.Range, onRange: (StarInsight.Range) -> Unit, modifier: Modifier = Modifier) {
    val other = StarInsight.Range.entries.firstOrNull { !StarInsight.mock(it).isEmpty }
    Column(
        modifier.fillMaxWidth().padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text("${range.raw}ล่าสุดยังไม่มีคนเห็นการ์ด", style = sh(20f, SHFont.bold), color = Color.White, textAlign = TextAlign.Center)
        Text("แชร์การ์ดอีกรอบ ยอดวิวจะกลับมาขึ้นที่นี่", style = sh(15f), color = InsightInk.soft)
        if (other != null) {
            StageGlassPanel(
                radius = 22f,
                modifier = Modifier.padding(top = 8.dp).dockPress {
                    Haptics.impact(Haptics.Style.light)
                    onRange(other)
                },
            ) {
                Box(Modifier.height(44.dp).padding(horizontal = 18.dp), contentAlignment = Alignment.Center) {
                    Text("ดู ${other.raw}", style = sh(14f, SHFont.bold), color = Color.White)
                }
            }
        }
    }
}

// MARK: ปุ่มล่าง — ชุดเดียวกับหน้า Star Card (ปุ่มหลักทึบ · แชร์เป็นกระจก)

@Composable
private fun InsightDock(empty: Boolean, onEditCard: () -> Unit, onShare: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier
            .fillMaxWidth()
            .background(Brush.verticalGradient(listOf(Color.Black.opacity(0.0), Color.Black.opacity(0.7))))
            .padding(horizontal = 20.dp)
            .padding(top = 28.dp, bottom = 8.dp)
            .navigationBarsPadding(),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (empty) {
            DockPrimary(Ph.share, "แชร์การ์ด", onShare, Modifier.weight(1f))
        } else {
            DockPrimary(Ph.pencilSimple, "แต่งการ์ด", onEditCard, Modifier.weight(1f))
            StageGlassPanel(
                radius = 26f,
                modifier = Modifier
                    .semantics { contentDescription = "แชร์การ์ด" }
                    .dockPress {
                        Haptics.impact(Haptics.Style.light)
                        onShare()
                    },
            ) {
                Row(
                    Modifier.height(52.dp).padding(horizontal = 22.dp),
                    horizontalArrangement = Arrangement.spacedBy(7.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    PIcon(Ph.share, size = 14f, weight = PhWeight.bold, tint = Color.White.opacity(0.92), modifier = Modifier.offset(y = (-1).dp))
                    Text("แชร์", style = sh(15f, SHFont.semibold), color = Color.White.opacity(0.92))
                }
            }
        }
    }
}

@Composable
private fun DockPrimary(icon: Ph, title: String, action: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier
            .dockPress {
                Haptics.impact(Haptics.Style.medium)
                action()
            }
            .height(52.dp)
            .background(Color.White.opacity(0.94), CircleShape),
        horizontalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PIcon(icon, size = 14f, weight = PhWeight.bold, tint = Color.Black.opacity(0.88))
        Text(title, style = sh(15f, SHFont.bold), color = Color.Black.opacity(0.88))
    }
}

// MARK: - กราฟยอดวิวรายวัน

/** เส้นโค้งผ่านทุกจุดแบบไม่โด่งเกินค่าจริง (monotone cubic) · แกนตั้งเริ่มที่ 0 เสมอ — พื้นที่ใต้เส้นจึงบอกปริมาณจริง (= `TrendShape`) */
object TrendShape {
    fun points(values: List<Int>, r: Rect): List<Offset> {
        if (values.size <= 1) return emptyList()
        val hi = max(1.0, (values.maxOrNull() ?: 1).toDouble())
        return values.mapIndexed { i, v ->
            Offset(r.left + r.width * i / (values.size - 1), r.bottom - r.height * (v / hi).toFloat())
        }
    }

    fun path(values: List<Int>, r: Rect, closed: Boolean = false): Path {
        val p = points(values, r)
        val path = Path()
        if (p.size <= 1) return path
        val n = p.size
        // ความชันของแต่ละช่วง แล้วเฉลี่ยเป็นความชันที่จุด — ช่วงที่เปลี่ยนทิศ = 0 (ยอด/ก้นไม่โด่ง)
        val d = FloatArray(n - 1) { (p[it + 1].y - p[it].y) / (p[it + 1].x - p[it].x) }
        val m = FloatArray(n)
        m[0] = d[0]; m[n - 1] = d[n - 2]
        for (i in 1 until n - 1) m[i] = if (d[i - 1] * d[i] <= 0f) 0f else (d[i - 1] + d[i]) / 2f
        for (i in 0 until n - 1) {
            if (d[i] == 0f) continue
            val a = m[i] / d[i]; val b = m[i + 1] / d[i]; val s = a * a + b * b
            if (s > 9f) { val t = 3f / sqrt(s); m[i] = t * a * d[i]; m[i + 1] = t * b * d[i] }
        }
        path.moveTo(p[0].x, p[0].y)
        for (i in 0 until n - 1) {
            val dx = (p[i + 1].x - p[i].x) / 3f
            path.cubicTo(p[i].x + dx, p[i].y + m[i] * dx, p[i + 1].x - dx, p[i + 1].y - m[i + 1] * dx, p[i + 1].x, p[i + 1].y)
        }
        if (closed) {
            path.lineTo(r.right, r.bottom)
            path.lineTo(r.left, r.bottom)
            path.close()
        }
        return path
    }
}

/** กราฟเดียวของหน้า — เส้นเดียว สีเดียว ป้ายสองจุด (วันที่ยอดสูงสุด + วันนี้) · แตะหรือกดค้างแล้วลากเพื่ออ่านค่ารายวัน */
@Composable
fun InsightChart(
    data: StarInsight,
    mark: Color,
    drawn: () -> Float,
    scrub: Int?,
    onScrub: (Int?) -> Unit,
    modifier: Modifier = Modifier,
) {
    /** ที่ว่างเหนือกราฟสำหรับป้าย · ใต้กราฟสำหรับป้ายแกนนอน */
    val top = 30f
    val labels = 22f
    val tagHalf = 104f
    val scope = rememberCoroutineScope()
    /** นิ้วกดค้างอยู่บนกราฟ (กำลังไล่ดูทีละวัน) */
    var pressing by remember { mutableStateOf(false) }
    var tapToken by remember { mutableIntStateOf(0) }

    BoxWithConstraints(
        modifier.semantics {
            contentDescription = "กราฟยอดวิวรายวัน สูงสุด ${data.dayNames.getOrNull(data.peakIndex) ?: ""} ${data.daily.getOrNull(data.peakIndex) ?: 0} ครั้ง ${data.peakNote} · วันนี้ ${data.daily.lastOrNull() ?: 0} ครั้ง"
        },
    ) {
        val w = maxWidth.value
        val h = maxHeight.value
        val plot = Rect(5f, top, w - 5f, h - labels)
        val pts = remember(data, w, h) { TrendShape.points(data.daily, plot) }
        val peak = data.peakIndex
        val last = data.daily.size - 1
        val focus = scrub ?: peak
        val density = LocalDensity.current.density

        fun indexAt(xPx: Float): Int {
            val x = xPx / density
            val t = (x - plot.left) / max(1f, plot.width)
            return min(max((t * last).roundToInt(), 0), last)
        }

        Canvas(
            Modifier
                .fillMaxSize()
                // แตะ = ดูค่าของวันนั้นครู่หนึ่ง · กดค้างแล้วลาก = ไล่ดูทีละวัน — ทั้งกราฟคือพื้นที่แตะ ไม่ต้องเล็งเส้น
                .pointerInput(data) {
                    detectTapGestures { p ->
                        val i = indexAt(p.x)
                        Haptics.impact(Haptics.Style.light)
                        val next = if (scrub == i) null else i
                        onScrub(next)
                        if (next == null) return@detectTapGestures
                        val token = ++tapToken
                        scope.launch {
                            delay(2500)
                            if (token == tapToken && !pressing) onScrub(null)
                        }
                    }
                }
                .pointerInput(data) {
                    detectDragGesturesAfterLongPress(
                        onDragStart = { p ->
                            pressing = true
                            val i = indexAt(p.x)
                            if (i != scrub) Haptics.impact(Haptics.Style.light)
                            onScrub(i)
                        },
                        onDragEnd = { pressing = false; onScrub(null) },
                        onDragCancel = { pressing = false; onScrub(null) },
                        onDrag = { change, _ ->
                            change.consume()
                            val i = indexAt(change.position.x)
                            if (i != scrub) {
                                Haptics.impact(Haptics.Style.light)
                                onScrub(i)
                            }
                        },
                    )
                },
        ) {
            val d = density
            val k = drawn().coerceIn(0f, 1f)
            val plotPx = Rect(plot.left * d, plot.top * d, plot.right * d, plot.bottom * d)
            // เส้นฐาน (0) เส้นเดียว — ไม่มีตาราง
            drawRect(Color.White.opacity(0.16), topLeft = Offset(0f, plotPx.bottom), size = Size(size.width, 1f * d))
            if (pts.size > 1) {
                val area = TrendShape.path(data.daily, plotPx, closed = true)
                drawPath(area, Brush.verticalGradient(listOf(mark.opacity(0.32), mark.opacity(0.0)), startY = plotPx.top, endY = plotPx.bottom), alpha = k)
                val line = TrendShape.path(data.daily, plotPx)
                val measure = PathMeasure().apply { setPath(line, false) }
                val seg = Path()
                if (k > 0f) measure.getSegment(0f, measure.length * k, seg, true)
                drawPath(seg, mark, style = Stroke(width = 2.5f * d, cap = StrokeCap.Round, join = StrokeJoin.Round))

                fun dot(p: Offset) {
                    drawCircle(rgb(10 / 255.0, 10 / 255.0, 12 / 255.0), radius = 6.5f * d, center = p, alpha = k)
                    drawCircle(mark, radius = 4.5f * d, center = p, alpha = k)
                }
                val fp = Offset(pts[focus].x * d, pts[focus].y * d)
                if (scrub != null) {
                    // เส้นนำสายตาตอนลากนิ้ว: จากป้ายลงมาถึงเส้นฐาน
                    drawRect(
                        Color.White.opacity(0.28), topLeft = Offset(fp.x - 0.5f * d, (top - 4f) * d),
                        size = Size(1f * d, plotPx.bottom - (top - 4f) * d), alpha = k,
                    )
                } else if (last != peak) {
                    dot(Offset(pts[last].x * d, pts[last].y * d))
                }
                dot(fp)
            }
        }

        if (pts.size > 1) {
            val fade = Modifier.graphicsLayer { alpha = drawn().coerceIn(0f, 1f) }
            // ค่าของวันนี้ — จุดที่สองที่มีตัวเลขกำกับ (ยอดสูงสุด + วันนี้) พอให้กะสเกลของเส้นได้โดยไม่ต้องมีแกนตั้ง
            if (scrub == null && last != peak && pts[last].y - 16f > top - 2f) {
                Text(
                    StarInsight.fmt(data.daily[last]), style = sh(13f, SHFont.bold), color = Color.White, maxLines = 1, softWrap = false,
                    modifier = fade.centeredAt(w - 18f, pts[last].y - 16f),
                )
            }
            // ป้ายค่าบรรทัดเดียว: "948 · วันที่แชร์ลง IG Story" · ตอนลากนิ้ว = "622 · พฤหัสบดี"
            Row(
                fade.centeredAt(min(max(pts[focus].x, tagHalf), w - tagHalf), top / 2f - 5f).width((tagHalf * 2).dp),
                horizontalArrangement = Arrangement.spacedBy(5.dp, Alignment.CenterHorizontally),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(StarInsight.fmt(data.daily[focus]), style = sh(14f, SHFont.heavy), color = Color.White, maxLines = 1, softWrap = false)
                Text("·", style = sh(13f, SHFont.medium), color = InsightInk.faint)
                Text(
                    if (scrub == null) data.peakNote else data.dayNames.getOrElse(focus) { "" },
                    style = sh(13f, SHFont.medium), color = InsightInk.soft, maxLines = 1, softWrap = false,
                )
            }
        }
        // ป้ายแกนนอน: หัว-ท้ายชิดขอบ ที่เหลือกระจายเท่ากัน
        Row(
            Modifier.align(Alignment.BottomStart).offset(x = 1.dp, y = (-2).dp).width((w - 2f).dp),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            for (l in data.axis) Text(l, style = sh(12f, SHFont.medium), color = InsightInk.faint, maxLines = 1, softWrap = false)
        }
    }
}

/** `.position(x:y:)` — วางให้จุดกึ่งกลางของชิ้นอยู่ที่ (x, y) หน่วยออกแบบ ในกล่องแม่ (ชิ้นไม่กินที่ในผัง) */
private fun Modifier.centeredAt(x: Float, y: Float): Modifier = layout { measurable, _ ->
    val p = measurable.measure(Constraints())
    layout(0, 0) {
        p.placeRelative((x.dp.toPx() - p.width / 2f).roundToInt(), (y.dp.toPx() - p.height / 2f).roundToInt())
    }
}

// MARK: - สีในระบบ OKLab — ไว้ดึง "เฉดสี" ของการ์ดมาใช้ที่ความสว่างเดียวกันทุกเฉด

class OKLab(c: Color) {
    val l: Double
    val a: Double
    val b: Double
    val chroma: Double get() = sqrt(a * a + b * b)
    val hue: Double get() = atan2(b, a)

    init {
        fun lin(v: Double) = if (v <= 0.04045) v / 12.92 else ((v + 0.055) / 1.055).pow(2.4)
        val r = lin(c.red.toDouble()); val g = lin(c.green.toDouble()); val bl = lin(c.blue.toDouble())
        val l_ = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * bl)
        val m_ = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * bl)
        val s_ = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * bl)
        l = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
        a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
        b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    }

    companion object {
        /** สีจากความสว่าง + ความสด + เฉด — ความสดเกินที่จอแสดงได้ = ลดลงทีละน้อยจนอยู่ในช่วง sRGB */
        fun color(lightness: Double, chroma: Double, hue: Double): Color {
            fun gam(v: Double) = if (v <= 0.0031308) 12.92 * v else 1.055 * v.pow(1 / 2.4) - 0.055
            var c = chroma
            while (c > 0) {
                val a = c * cos(hue); val b = c * sin(hue)
                val l_ = (lightness + 0.3963377774 * a + 0.2158037573 * b).pow(3)
                val m_ = (lightness - 0.1055613458 * a - 0.0638541728 * b).pow(3)
                val s_ = (lightness - 0.0894841775 * a - 1.2914855480 * b).pow(3)
                val r = 4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_
                val g = -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_
                val bl = -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_
                if (r in 0.0..1.0 && g in 0.0..1.0 && bl in 0.0..1.0) return rgb(gam(r), gam(g), gam(bl))
                c -= 0.01
            }
            return rgb(lightness, lightness, lightness)
        }
    }
}

// MARK: - ปุ่มเข้า ST★R Insight บนหน้า Star Profile

/**
 * ปุ่มเล็กใต้ปุ่ม "ดูการ์ด" ในหมวด ST★R Card — ไอคอนกราฟ + ยอดวิวตัวเล็ก (ผู้ใช้ 4 ต.ค. 2569: แถบกราฟเต็มแถว
 * "ใหญ่ไปสำหรับหน้า Profile เอาแค่ปุ่มไป และตัวเลขเล็กๆพอ" แล้ว "ปุ่มไว้ข้างล่างดู card") · วัสดุเดียวกับปุ่มในหมวดนั้น
 */
@Composable
fun InsightChip(onOpen: () -> Unit, modifier: Modifier = Modifier) {
    val data = remember { StarInsight.mock(StarInsight.Range.week) }
    Box(
        modifier
            .fillMaxWidth()
            .semantics { contentDescription = if (data.isEmpty) "ดูสถิติคนดูการ์ด" else "ดูสถิติ ยอดวิว 7 วันล่าสุด ${data.views} ครั้ง" }
            .dockPress {
                Haptics.impact(Haptics.Style.light)
                onOpen()
            },
    ) {
        // (iOS ยืดพื้นที่แตะลงล่างอีก 10 โดยไม่ดันความสูงของหมวด — Android แตะได้แค่ตัวแคปซูล 32)
        Row(
            Modifier
                .fillMaxWidth()
                .height(32.dp)
                .background(Color.White.opacity(0.85), CircleShape)
                .border(1.dp, GL.ink.opacity(0.1), CircleShape),
            horizontalArrangement = Arrangement.spacedBy(5.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PIcon(Ph.chartLineUp, size = 13f, weight = PhWeight.bold, tint = GL.ink)
            if (data.isEmpty) {
                Text("สถิติ", style = sh(12.5f, SHFont.bold), color = GL.ink)
            } else {
                Text(StarInsight.fmt(data.views), style = sh(12.5f, SHFont.bold).tnum(), color = GL.ink)
                Text("วิว", style = sh(12f, SHFont.medium), color = GL.muted)
            }
            PIcon(Ph.caretRight, size = 9f, weight = PhWeight.bold, tint = GL.hint)
        }
    }
}
