package co.salehere.starcard.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.gestures.snapping.SnapLayoutInfoProvider
import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior
import androidx.compose.foundation.interaction.DragInteraction
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.LastBaseline
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.model.CardFormat
import co.salehere.starcard.model.CardLibrary
import co.salehere.starcard.model.CardPage
import co.salehere.starcard.model.CardRecord
import co.salehere.starcard.model.CardStore
import co.salehere.starcard.model.CardTemplate
import co.salehere.starcard.model.LocalClipInvocation
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.PhotoStore
import co.salehere.starcard.model.Profile
import co.salehere.starcard.theme.CardBackdrop
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHColor
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SignaturePattern
import co.salehere.starcard.theme.StarSeal
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.salehere.starflow.GL
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * หน้าของฉัน — **การ์ดทุกใบที่ทำไว้ เรียงเป็นสำรับปัดดูได้ ใบที่แสดงอยู่ติดป้ายชัด ๆ**
 *
 * 1. **ฉันทำไว้กี่แบบ หน้าตายังไง** — ทุกใบเป็นการ์ดจริงขนาดใหญ่ ปัดซ้ายขวาดูทีละใบ ใบข้าง ๆ โผล่ขอบ
 *    ท้ายสำรับคือใบเปล่าเส้นประ "สร้างใหม่" — วิธีเพิ่มอยู่ในที่เดียวกับของที่มี
 * 2. **ใบไหนที่คนเห็นอยู่** — ป้ายเขียว "กำลังแสดงอยู่" แปะบนตัวการ์ด + ขอบเรืองสีธีมของใบนั้น
 * 3. **นี่คือของฉัน** — หัวหน้าเป็นตัวตน และเวทีทั้งจออาบสีธีมของใบที่กำลังดู
 *
 * - onPreview: เปิดใบนั้นแบบที่แบรนด์เห็น — null = ไม่โชว์เมนูข้อนี้
 * - onProfile: เปิดหน้า "ข้อมูลของฉัน" — แตะที่รูป/ชื่อในหัว
 * - entryToken: ตัวนับ "กลับเข้าหน้านี้ใหม่" — ค่าเปลี่ยน = เล่นท่าเข้าฉากอีกครั้ง
 * - embedded: ฝังอยู่ในหน้า Star Profile — ไม่มีเวทีมืด ไม่มีหัวของตัวเอง ตัวหนังสือเป็นหมึกบนพื้นสว่าง
 * - sharedStage: พื้น/เวทีและหัววาดโดย shell แล้ว (`StarGround`/`StarHeader`) — หน้านี้โปร่งใส
 * - onFocusTheme: ธีมของใบที่อยู่กลางจอเปลี่ยน — ให้ดวงไฟของ shell เปลี่ยนสีตาม
 * - startAtLive: เปิดมาที่ใบที่กำลังแสดง (ไม่งั้นเปิดที่ใบที่แก้ล่าสุด)
 */
@Composable
fun CardGallery(
    onCreate: () -> Unit,
    onOpen: (CardRecord) -> Unit,
    onPreview: ((CardRecord) -> Unit)? = null,
    onProfile: (() -> Unit)? = null,
    entryToken: Int = 0,
    embedded: Boolean = false,
    sharedStage: Boolean = false,
    onFocusTheme: ((CardTheme) -> Unit)? = null,
    startAtLive: Boolean = false,
    modifier: Modifier = Modifier,
) {
    val library = CardLibrary.shared
    /** สีตัวหนังสือรอบสำรับ — ขาวบนเวทีมืด · หมึกเมื่อฝังบนพื้นสว่าง */
    val fg = if (embedded) GL.ink else Color.White
    val invocation = LocalClipInvocation.current
    val photos = LocalPhotoStore.current
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val g = remember { GalleryState() }

    val records = library.records
    /** ใบที่แสดงอยู่ (ลิงก์ประจำตัวพาไป) — `displayOrder` เอาใบหลักขึ้นก่อนเสมอ */
    val published = library.displayOrder.firstOrNull()
    /** ใบในสำรับตามลำดับที่ตรึงไว้ */
    val deckRecords = g.order.mapNotNull { id -> records.firstOrNull { it.id == id } }
    /** ใบที่อยู่กลางจอตอนนี้ — null เมื่ออยู่ที่ใบเปล่า "สร้างใหม่" */
    val focused: CardRecord? = when (val f = g.focus) {
        null -> published
        CREATE_ID -> null
        else -> records.firstOrNull { it.id == f } ?: published
    }
    /** ใบที่เปิดมาเจอ — ใบที่แตะล่าสุด กลับจากห้องแต่งต้องเจอใบที่เพิ่งแก้ ไม่ใช่ต้องปัดหา */
    val initialFocusID: String? =
        if (startAtLive && published != null) published.id
        else records.maxByOrNull { it.updatedAt }?.id ?: published?.id
    fun themeOf(record: CardRecord?): CardTheme = record?.let { g.unpacked.restore(it)?.theme } ?: CardTheme()
    val stageTheme = themeOf(focused ?: published)

    /** จัดลำดับสำรับ — ครั้งแรกเรียงตามที่ตกลง หลังจากนั้นแค่เติมใบใหม่ท้ายสำรับ/ตัดใบที่ถูกลบ ไม่สลับที่ */
    fun syncOrder() {
        val now = library.records
        val ids = now.map { it.id }.toSet()
        var kept = g.order.filter { it in ids }
        kept = if (kept.isEmpty()) library.displayOrder.map { it.id } else kept + now.map { it.id }.filter { it !in kept }
        g.order = kept
    }

    // ท่าเข้าฉาก — สำรับลอยขึ้นมา หัวกับปุ่มตามมา
    val deckIn = remember { Animatable(0f) }
    val headerIn = remember { Animatable(0f) }
    val dockIn = remember { Animatable(0f) }
    LaunchedEffect(g.appeared) {
        if (!g.appeared) return@LaunchedEffect
        launch { deckIn.animateTo(1f, Motion.settle.float) }
        launch { delay(80); headerIn.animateTo(1f, Motion.settle.float) }
        launch { delay(140); dockIn.animateTo(1f, Motion.settle.float) }
    }

    LaunchedEffect(Unit) {
        syncOrder()
        // เปิดมาที่ใบที่แตะล่าสุด (ใบที่แสดงอยู่มีป้ายบนตัวมันเอง อยู่ตรงไหนของสำรับก็เห็น)
        if (g.focus == null) g.focus = initialFocusID
        g.appeared = true
    }
    var lastToken by remember { mutableIntStateOf(entryToken) }
    LaunchedEffect(entryToken) {
        if (entryToken == lastToken) return@LaunchedEffect
        lastToken = entryToken
        // หน้านี้ถูก mount ค้างไว้ — ขากลับเข้ามาต้องเล่นท่าเข้าฉากใหม่
        deckIn.snapTo(0f); headerIn.snapTo(0f); dockIn.snapTo(0f)
        g.appeared = false
        withFrameNanos { }
        g.appeared = true
    }
    val recordIDs = records.map { it.id }
    LaunchedEffect(recordIDs) { syncOrder() }
    val focusTheme by rememberUpdatedState(onFocusTheme)
    LaunchedEffect(g.focus) { focusTheme?.invoke(stageTheme) }
    // อุ่นรูปเทมเพลตล่วงหน้าตั้งแต่ยังอยู่หน้านี้ — กด + แล้วหน้าเลือกได้รูปพร้อมใช้ทันที
    LaunchedEffect(photos) { photos?.let { TemplateThumbs.shared.warm(it) } }

    BackHandler(enabled = g.sheetOpen) { g.sheetOpen = false }

    Box(modifier.fillMaxSize()) {
        // เวทีอาบสีของใบที่กำลังดู — ปัดไปใบไหนทั้งหน้าเปลี่ยนสีตาม (ใบเปล่าใช้สีของใบที่แสดงอยู่)
        if (embedded) {
            // แสงเรืองสีธีมของใบที่ดูอยู่ บนพื้นสว่างของ Star Profile — ไม่ใช่เวทีมืดทั้งจอ
            val glow by animateColorAsState(stageTheme.rawAccent.opacity(0.28), Motion.settle.spec(), label = "galleryGlow")
            Box(
                Modifier.matchParentSize().drawBehind {
                    val r = 320.dp.toPx()
                    drawRect(
                        Brush.radialGradient(
                            0f to glow, (20f / 320f) to glow, 1f to Color.Transparent,
                            center = Offset(size.width / 2f, size.height / 2f), radius = r,
                        ),
                    )
                },
            )
        } else if (!sharedStage) {
            GalleryStage(
                theme = stageTheme,
                modifier = Modifier.graphicsLayer { alpha = (0.55f + 0.45f * deckIn.value).coerceIn(0f, 1f) },
            )
        }

        if (library.isEmpty) {
            EmptyState(fg = fg, onCreate = onCreate, modifier = Modifier.align(Alignment.Center))
        } else {
            Column(
                Modifier
                    .fillMaxSize()
                    .then(if (embedded) Modifier else Modifier.windowInsetsPadding(WindowInsets.safeDrawing)),
            ) {
                if (!embedded) {
                    GalleryHeader(
                        sharedStage = sharedStage,
                        onProfile = onProfile,
                        cardCount = records.size,
                        photos = photos,
                        onCreate = onCreate,
                        // หัวอยู่เหนือขอบล้นของสำรับ — แตะปุ่มในหัวต้องถึงปุ่มเสมอ
                        modifier = Modifier.zIndex(1f).graphicsLayer {
                            alpha = headerIn.value.coerceIn(0f, 1f)
                            translationY = -12f * (1f - headerIn.value) * density
                        },
                    )
                }
                Deck(
                    g = g,
                    deckRecords = deckRecords,
                    focused = focused,
                    published = published,
                    publishedID = library.publishedID,
                    initialFocusID = initialFocusID,
                    embedded = embedded,
                    fg = fg,
                    onOpen = onOpen,
                    onPreview = onPreview,
                    onCreate = onCreate,
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .graphicsLayer {
                            // สำรับแกว่งเข้าที่รอบแกนตั้งของตัวเอง — อ่านเป็นของหนาที่มีด้าน ไม่ใช่ภาพแบนที่ถูกย่อ
                            val p = deckIn.value
                            val s = 0.94f + 0.06f * p
                            scaleX = s; scaleY = s
                            rotationY = 13f * (1f - p)
                            cameraDistance = 12f * density
                            alpha = p.coerceIn(0f, 1f)
                        },
                )
                GalleryDock(
                    record = focused,
                    publishedID = library.publishedID,
                    slug = invocation.slug,
                    themeOf = { themeOf(it) },
                    copied = g.copied,
                    fg = fg,
                    light = embedded,
                    onCopy = { url ->
                        copyPlainText(context, url)
                        Haptics.impact(Haptics.Style.light)
                        g.copied = true
                        scope.launch {
                            delay(1600)
                            g.copied = false
                        }
                    },
                    onShare = { url -> sharePlainText(context, url) },
                    onOpen = onOpen,
                    onPublish = { r -> library.setPublished(r.id) },
                    onMore = {
                        Haptics.impact(Haptics.Style.light)
                        g.mode = GallerySheetMode.menu
                        g.sheetOpen = true
                    },
                    onCreate = onCreate,
                    modifier = Modifier.graphicsLayer {
                        alpha = dockIn.value.coerceIn(0f, 1f)
                        translationY = 28f * (1f - dockIn.value) * density
                    },
                )
            }
        }

        // ชีตคำสั่งรองของใบ — ทำเองทั้งใบ (เมนูระบบบังคับฟอนต์ระบบ ปฏิเสธฟอนต์แอปทุกกรณี)
        GallerySheet(
            g = g,
            record = focused,
            onCopyLink = { r ->
                copyPlainText(context, library.url(r, invocation.slug))
                Haptics.impact(Haptics.Style.light)
                g.sheetOpen = false
            },
            onPreview = onPreview?.let { preview ->
                { r: CardRecord ->
                    Haptics.impact(Haptics.Style.light)
                    g.sheetOpen = false
                    preview(r)
                }
            },
            onDuplicate = { r ->
                val copy = library.duplicate(r.id)
                Haptics.impact(Haptics.Style.medium)
                g.sheetOpen = false
                // สำเนาโผล่ท้ายสำรับ — พาไปดูมัน ไม่งั้นกดแล้วเหมือนไม่มีอะไรเกิดขึ้น
                if (copy != null) {
                    scope.launch {
                        delay(350)
                        g.focus = copy.id
                    }
                }
            },
            onRename = { r ->
                library.rename(r.id, g.renameText)
                Haptics.impact(Haptics.Style.light)
                g.sheetOpen = false
            },
            onDelete = { r ->
                // ไปที่ใบที่เลื่อนเข้ามาแทนที่ (หรือใบก่อนหน้าถ้าลบใบท้าย) — ต้องเป็น id ใหม่เสมอ
                val i = g.order.indexOf(r.id).coerceAtLeast(0)
                val remaining = g.order.filter { it != r.id }
                library.delete(r.id)
                g.focus = if (i in remaining.indices) remaining[i] else remaining.lastOrNull() ?: CREATE_ID
                Haptics.impact(Haptics.Style.medium)
                g.sheetOpen = false
            },
        )
    }
}

// MARK: - สถานะของหน้า

private const val CREATE_ID = "__create__"
/** ช่องว่างระหว่างหน้า / ขอบรอบแถบของใบแนวนอน (หน่วยออกแบบ) */
private const val STRIP_GUTTER: Float = CardTemplate.thumbGutter
private const val STRIP_MARGIN: Float = CardTemplate.thumbGutter
/** ระยะห่างระหว่างใบในสำรับ */
private const val DECK_SPACING: Float = 12f
/** ระยะขั้นต่ำที่นับว่า "ตั้งใจพลิก" — กันนิ้วที่แค่แตะเฉียด ๆ หรือลากเอียงตอนเลื่อนขึ้นลง */
private const val DECK_FLIP: Float = 36f
/** อัตราหน่วง `.fast` ของ `UIScrollView` (0.99/ms) — ระยะที่แรงสะบัดพาไปต่อ = ความเร็ว × 0.099 วินาที */
private const val FAST_DECELERATION: Float = 0.099f
/** ขอบที่สำรับวาดล้นได้บน/ล่าง (ป้ายเหนือใบแนวนอน · แสงเรือง) — ไม่กินที่ในผัง */
private const val DECK_BLEED: Float = 48f

private enum class GallerySheetMode { menu, rename, confirmDelete }

/** สถานะทั้งหน้า (= `@State` ของ `CardGallery`) + ผังสำรับล่าสุดที่ตัวปัดใช้ */
private class GalleryState {
    /** id ของใบที่อยู่กลางจอ — `CREATE_ID` คือใบเปล่า "สร้างใหม่" ท้ายสำรับ */
    var focus by mutableStateOf<String?>(null)
    /** ใบที่ตัวสำรับรายงานเองล่าสุด — แยก "นิ้วปัดมาถึง" ออกจาก "สั่งให้ไป" */
    var reported by mutableStateOf<String?>(null)
    /** สำรับถูกวางที่ใบตั้งต้นแล้ว — ก่อนนั้นห้ามฟังรายงาน/ห้ามสั่งเลื่อน */
    var landed by mutableStateOf(false)
    /** ลำดับใบในสำรับ — **ตรึงไว้ตลอดที่เปิดหน้านี้** ไม่จัดใหม่ตามใบที่แสดง */
    var order by mutableStateOf<List<String>>(emptyList())
    /** เพิ่งคัดลอกลิงก์ — โชว์ "คัดลอกแล้ว" ชั่วครู่ตรงแถบลิงก์ */
    var copied by mutableStateOf(false)
    var appeared by mutableStateOf(false)
    var sheetOpen by mutableStateOf(false)
    var mode by mutableStateOf(GallerySheetMode.menu)
    var renameText by mutableStateOf("")
    val unpacked = UnpackCache()

    // ผังสำรับล่าสุด (พิกเซล) — ค่าธรรมดา ไม่สั่งวาดใหม่
    var ids: List<String> = emptyList()
    var widthsPx: List<Int> = emptyList()
    var spacingPx: Int = 0
    var snap: DeckSnap = DeckSnap(emptyList(), 0f)
    /** ระยะเลื่อนตอนนิ้วเริ่มลาก — ใบตั้งต้นของการพลิก */
    var dragStart: Float? = null

    /** ระยะเลื่อนจริงของสำรับ (พิกเซล) นับจากหัวแถว */
    fun absolute(state: LazyListState): Float {
        val idx = state.firstVisibleItemIndex
        var run = 0
        for (k in 0 until min(idx, widthsPx.size)) run += widthsPx[k] + spacingPx
        return (run + state.firstVisibleItemScrollOffset).toFloat()
    }

    /** ระยะเลื่อน `x` → (ใบแรกที่เห็น, ระยะในใบนั้น) สำหรับ `scrollToItem` */
    fun position(x: Float): Pair<Int, Int> {
        var run = 0
        var j = 0
        while (j + 1 < widthsPx.size && run + widthsPx[j] + spacingPx <= x) {
            run += widthsPx[j] + spacingPx
            j++
        }
        return j to max(0, (x - run).roundToInt())
    }
}

/**
 * ภาพนิ่งที่แกะแล้วของแต่ละใบ — แกะครั้งเดียวต่อการแก้หนึ่งครั้ง (ผูกกับ `updatedAt`)
 * `CardPage` ได้ id ใหม่ทุกครั้งที่แกะ — แกะใหม่ทุกรอบที่หน้าวาด พรีวิวทุกใบจะถูกวาดใหม่หมดกลางการปัด
 * ไม่ใช่ state โดยตั้งใจ — เติมแคชระหว่างวาดต้องไม่สั่งให้วาดใหม่
 */
private class UnpackCache {
    private val store = HashMap<String, Pair<Long, CardStore.Restored?>>()

    fun restore(record: CardRecord): CardStore.Restored? {
        store[record.id]?.let { (stamp, value) -> if (stamp == record.updatedAt) return value }
        val value = CardStore.restore(record.snapshot)
        store[record.id] = record.updatedAt to value
        return value
    }
}

/**
 * ปัดหยุดให้ **กลางใบตรงกลางจอ** — ใบในสำรับกว้างไม่เท่ากัน (แนวนอนกว้าง · แนวตั้งแคบ)
 * ปัดทีละใบเสมอเหมือนสำรับไพ่ · ระยะทั้งหมดเป็นพิกเซล
 */
private class DeckSnap(widths: List<Float>, spacing: Float) {
    /** ระยะเลื่อนที่ทำให้แต่ละใบอยู่กลางจอ — ใบแรกคือ 0 เพราะหัวแถวเว้นไว้พอดีครึ่งที่เหลือของมัน */
    val stops: List<Float>

    init {
        val first = widths.firstOrNull() ?: 0f
        var run = 0f
        val out = ArrayList<Float>(widths.size)
        for (w in widths) {
            out += run + (w - first) / 2f
            run += w + spacing
        }
        stops = out
    }

    /** ใบที่ใกล้ระยะเลื่อนนี้ที่สุด */
    fun nearest(x: Float): Int = stops.indices.minByOrNull { abs(stops[it] - x) } ?: 0
}

/**
 * ตัวปัดของสำรับ (= `DeckSnap.updateTarget` + `FastDeceleration`)
 * ระยะที่ตั้งใจไป = ที่ลากมาแล้ว + แรงสะบัด — เกินเกณฑ์นิดเดียวก็พลิกใบ เหมือน paging
 */
private class DeckSnapProvider(
    private val g: GalleryState,
    private val list: LazyListState,
    private val flipPx: Float,
) : SnapLayoutInfoProvider {
    override fun calculateApproachOffset(velocity: Float, decayOffset: Float): Float = 0f

    override fun calculateSnapOffset(velocity: Float): Float {
        val snap = g.snap
        if (snap.stops.isEmpty()) return 0f
        val x = g.absolute(list)
        val from = snap.nearest(g.dragStart ?: x)
        val moved = (x + velocity * FAST_DECELERATION) - snap.stops[from]
        val step = if (moved > flipPx) 1 else if (moved < -flipPx) -1 else 0
        val target = snap.stops[(from + step).coerceIn(0, snap.stops.lastIndex)]
        return target - x
    }
}

/**
 * ขนาดของใบในสำรับ — **แต่ละใบเป็นทรงจริงของมัน**
 * แนวนอน (พอร์ต) คือแถบสามหน้าต่อกันกว้างเกือบเต็มจอ · แนวตั้ง (สตอรี่) คือเฟรม 9:16
 */
private data class DeckMetrics(val portrait: Size, val landscape: Size) {
    fun size(format: CardFormat): Size = if (format == CardFormat.portfolio) landscape else portrait
    /** มุมนอกของใบแนวนอนเล็กกว่า — ร่วมศูนย์กับมุมของหน้าข้างใน (มุมหน้า + ขอบ) */
    fun radius(format: CardFormat): Float = if (format == CardFormat.portfolio) 14f else 22f

    companion object {
        fun of(box: Size): DeckMetrics {
            val story = CardTemplate.previewPageSize(CardFormat.story)
            // แถวสูงได้เท่าที่เหลือหลังหักชื่อใบกับจุดบอกตำแหน่งใต้การ์ด
            val maxH = max(140f, box.height - 74f)
            val pw = min(box.width - 64f, maxH * story.width / story.height)
            // แนวนอนกว้างกว่าใบตั้ง — ของสามหน้าในจอแนวตั้งต้องได้ทุกพอยต์ที่มี ใบข้าง ๆ ยังโผล่ขอบ
            val lw = box.width - 44f
            return DeckMetrics(
                portrait = Size(pw, pw * story.height / story.width),
                landscape = Size(lw, CardStripPreview.height(lw, STRIP_GUTTER, STRIP_MARGIN)),
            )
        }
    }
}

/** วัดสูงเท่าแถว แต่วาด/ปัดได้เลยขอบบนล่างออกไป `bleed` — ป้ายเหนือใบกับแสงเรืองไม่ถูกตัด */
private fun Modifier.bleedHeight(rowH: Float, bleed: Float): Modifier = layout { measurable, constraints ->
    val bleedPx = bleed.dp.roundToPx()
    val rowPx = rowH.dp.roundToPx()
    val full = rowPx + bleedPx * 2
    val p = measurable.measure(constraints.copy(minHeight = full, maxHeight = full))
    layout(p.width, rowPx) { p.place(0, -bleedPx) }
}

// MARK: - เวที

/**
 * ฉากหลังทั้งจอ = ฉากหลังของใบที่ดูอยู่ หรี่ลงให้การ์ดจริงลอยเด่น
 * หรี่ไม่แรงเท่าเดิม — สีของธีมยังต้องอ่านออกว่าเป็นสีอะไร ไม่ใช่เทาเข้มเหมือนกันทุกใบ
 */
@Composable
private fun GalleryStage(theme: CardTheme, modifier: Modifier = Modifier) {
    Crossfade(targetState = theme, animationSpec = Motion.settle.float, label = "galleryStage", modifier = modifier.fillMaxSize()) { t ->
        Box(Modifier.fillMaxSize()) {
            CardBackdrop(theme = t, ignoreSafeArea = true)
            Box(
                Modifier.fillMaxSize().background(
                    Brush.verticalGradient(listOf(Color.Black.opacity(0.54), Color.Black.opacity(0.36), Color.Black.opacity(0.6))),
                ),
            )
            // ลายน้ำลายของแบรนด์บนเวที — จางพอให้ "รู้สึก" ไม่ใช่ "อ่าน"
            SignaturePattern(opacity = 0.06)
        }
    }
}

/** toggle ข้อมูล | การ์ด บนเวทีมืด — คู่กับตัวบนหน้า Star Profile ตำแหน่งเดียวกัน: ขวาบนข้างชื่อ */
@Composable
private fun PaneToggle(onProfile: () -> Unit, modifier: Modifier = Modifier) {
    StageGlassPanel(radius = 18f, modifier = modifier.border(0.6.dp, Color.White.opacity(0.2), CircleShape)) {
        Row(Modifier.padding(3.dp), horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            Box(
                Modifier
                    .height(30.dp)
                    .tap {
                        Haptics.impact(Haptics.Style.light)
                        onProfile()
                    }
                    .padding(horizontal = 12.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text("ข้อมูล", style = sh(13f, SHFont.bold), color = Color.White.opacity(0.85))
            }
            Box(
                Modifier
                    .height(30.dp)
                    .background(Color.White.opacity(0.92), CircleShape)
                    .padding(horizontal = 12.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text("การ์ด", style = sh(13f, SHFont.bold), color = Color.Black.opacity(0.88))
            }
        }
    }
}

// MARK: - หัว: ตัวตน

/** รูป · ชื่อ · ตรา · จำนวนใบ — หน้าตาของหน้าโปรไฟล์ที่ทุกคนคุ้น = "หน้านี้คือของฉัน" โดยไม่ต้องอ่าน */
@Composable
private fun GalleryHeader(
    sharedStage: Boolean,
    onProfile: (() -> Unit)?,
    cardCount: Int,
    photos: PhotoStore?,
    onCreate: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val density = LocalDensity.current.density
    Column(modifier.padding(top = 6.dp, bottom = 10.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        if (sharedStage) {
            // หัวร่วม (title + toggle) อยู่ที่ shell — เว้นที่ไว้ให้แถวตัวตนอยู่ใต้มัน
            Spacer(Modifier.height(108.dp))
        } else if (onProfile != null) {
            // หัวเดียวกับหน้า Star Profile: "Star Card" + toggle ข้อมูล | การ์ด ขวาบน
            val shadow = Shadow(Color.Black.opacity(0.35), Offset(0f, 8f * density), 12f * density)
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 20.dp),
                verticalAlignment = Alignment.Bottom,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                    BasicText(
                        "Star",
                        style = sh(30f, SHFont.heavy).merge(
                            TextStyle(color = Color.White, letterSpacing = (-0.8).sp, shadow = shadow),
                        ),
                        modifier = Modifier.alignBy(LastBaseline),
                    )
                    BasicText(
                        "Card",
                        style = GL.serif(40f).merge(
                            TextStyle(
                                brush = Brush.verticalGradient(listOf(Color.White, Color.White, rgb(232 / 255.0, 199 / 255.0, 102 / 255.0))),
                                shadow = shadow,
                            ),
                        ),
                        modifier = Modifier.alignBy(LastBaseline),
                    )
                }
                Spacer(Modifier.weight(1f))
                PaneToggle(onProfile = onProfile, modifier = Modifier.padding(bottom = 6.dp))
            }
        }
        IdentityRow(onProfile = onProfile, cardCount = cardCount, photos = photos, onCreate = onCreate)
    }
}

@Composable
private fun IdentityRow(onProfile: (() -> Unit)?, cardCount: Int, photos: PhotoStore?, onCreate: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 20.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // ตัวตนทั้งก้อนแตะได้ = เปิด "ข้อมูลของฉัน" — ที่เดียวกับที่ทุกการ์ดดึงข้อมูลตั้งต้นไป
        Row(
            Modifier
                .weight(1f, fill = false)
                .padding(end = 8.dp)
                .semantics { contentDescription = "ข้อมูลของฉัน" }
                .dockPress(enabled = onProfile != null) {
                    Haptics.impact(Haptics.Style.light)
                    onProfile?.invoke()
                },
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // รูปเดียวกับที่การ์ดใช้เป็นรูปโปรไฟล์ — เห็นหน้าตัวเองก่อนเห็นอะไร
            Box(
                Modifier
                    .size(46.dp)
                    .clip(CircleShape)
                    .background(Color.White.opacity(0.1))
                    .border(1.dp, Color.White.opacity(0.35), CircleShape),
            ) {
                photos?.avatar(Modifier.matchParentSize())
            }
            Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        Profile.me.name,
                        style = sh(17f, SHFont.bold),
                        color = Color.White,
                        maxLines = 1,
                        softWrap = false,
                        autoSize = TextAutoSize.StepBased(minFontSize = (17f * 0.8f).sp, maxFontSize = 17.sp, stepSize = 0.25.sp),
                        modifier = Modifier.weight(1f, fill = false),
                    )
                    if (Profile.me.creator.verified) {
                        // ดาวทอง = สถานะ STAR — ตราเดียวกับที่อยู่ข้างชื่อบนการ์ดทุกใบ
                        StarSeal(size = 13f)
                    }
                }
                Text(
                    "การ์ด $cardCount ใบ",
                    style = sh(12f, SHFont.medium),
                    color = Color.White.opacity(0.62),
                    maxLines = 1,
                    softWrap = false,
                )
            }
        }

        GlassCircle(symbol = "plus", label = "สร้างการ์ดใหม่", action = onCreate)
    }
}

@Composable
private fun GlassCircle(symbol: String, label: String, action: () -> Unit) {
    StageGlassPanel(
        radius = 20f,
        modifier = Modifier
            .size(40.dp)
            .semantics { contentDescription = label }
            .dockPress {
                Haptics.impact(Haptics.Style.light)
                action()
            },
    ) {
        Box(Modifier.size(40.dp), contentAlignment = Alignment.Center) {
            SFSymbol(symbol, size = 15f, tint = Color.White.opacity(0.92))
        }
    }
}

// MARK: - สำรับ

/** การ์ดทุกใบเรียงแนวนอน ปัดทีละใบ ใบข้าง ๆ โผล่ขอบ — ท้ายสำรับคือใบเปล่า "สร้างใหม่" */
@Composable
private fun Deck(
    g: GalleryState,
    deckRecords: List<CardRecord>,
    focused: CardRecord?,
    published: CardRecord?,
    publishedID: String?,
    initialFocusID: String?,
    embedded: Boolean,
    fg: Color,
    onOpen: (CardRecord) -> Unit,
    onPreview: ((CardRecord) -> Unit)?,
    onCreate: () -> Unit,
    modifier: Modifier = Modifier,
) {
    BoxWithConstraints(modifier) {
        val box = Size(maxWidth.value, maxHeight.value)
        val m = DeckMetrics.of(box)
        val density = LocalDensity.current
        /** ใบเปล่า "สร้างใหม่" ใช้ทรงเดียวกับใบก่อนหน้ามัน — สำรับที่มีแต่แนวนอนจะไม่มีใบตั้งโผล่มาปิดท้าย */
        val createFormat = deckRecords.lastOrNull()?.format ?: CardFormat.portfolio
        val sizes = deckRecords.map { m.size(it.format) } + m.size(createFormat)
        val rowH = sizes.maxOf { it.height }
        val focusH = m.size(focused?.format ?: createFormat).height
        val ids = deckRecords.map { it.id } + CREATE_ID
        val widthsPx = sizes.map { with(density) { it.width.dp.roundToPx() } }
        val spacingPx = with(density) { DECK_SPACING.dp.roundToPx() }
        val snap = remember(widthsPx, spacingPx) { DeckSnap(widthsPx.map { it.toFloat() }, spacingPx.toFloat()) }
        g.ids = ids
        g.widthsPx = widthsPx
        g.spacingPx = spacingPx
        g.snap = snap

        val listState = rememberLazyListState()
        val flipPx = with(density) { DECK_FLIP.dp.toPx() }
        val provider = remember(listState, flipPx) { DeckSnapProvider(g, listState, flipPx) }
        val fling = rememberSnapFlingBehavior(provider)
        val scope = rememberCoroutineScope()
        val initial by rememberUpdatedState(initialFocusID)

        // ใบตั้งต้นของการพลิก = ใบที่อยู่กลางจอตอนนิ้วเริ่มลาก
        LaunchedEffect(listState) {
            listState.interactionSource.interactions.collect { i ->
                if (i is DragInteraction.Start) g.dragStart = g.absolute(listState)
            }
        }

        // ใบที่อยู่กลางจอตามระยะเลื่อนจริง — ชื่อ/สีเวที/ปุ่มเปลี่ยนตามตั้งแต่ระหว่างปัด
        LaunchedEffect(listState, ids, snap) {
            snapshotFlow {
                if (listState.layoutInfo.viewportSize.width > 0) snap.nearest(g.absolute(listState)) else -1
            }.distinctUntilChanged().collect { i ->
                if (i !in ids.indices) return@collect
                // ก่อนถึงใบตั้งต้น ระยะเลื่อนคือของที่ระบบวางเอง ไม่ใช่นิ้ว
                if (!g.landed) {
                    if (ids[i] == g.reported) g.landed = true
                    return@collect
                }
                g.reported = ids[i]
                if (g.focus != ids[i]) g.focus = ids[i]
            }
        }

        // วางที่ใบตั้งต้น — ทุกครั้งที่ใบชุดใหม่ถูกวัด จนกว่าจะถึงจริง
        LaunchedEffect(ids, snap) {
            if (g.landed) return@LaunchedEffect
            val target = g.focus ?: initial ?: return@LaunchedEffect
            val i = ids.indexOf(target)
            if (i < 0) return@LaunchedEffect
            g.reported = target
            if (g.focus != target) g.focus = target
            // วางทันทีไม่ไหล — สำรับกำลังค่อย ๆ ปรากฏอยู่แล้ว
            val (item, offset) = g.position(snap.stops[i])
            listState.scrollToItem(item, offset)
            g.landed = true
        }

        // สั่งไปใบไหน (จุด · ลบ · ทำสำเนา) เลื่อนไปจุดหยุดของใบนั้น
        LaunchedEffect(g.focus) {
            val f = g.focus ?: return@LaunchedEffect
            if (!g.landed || f == g.reported) return@LaunchedEffect
            scope.launch {
                // รอสำรับวัดใหม่ก่อน (หลังลบ/ทำสำเนา ความกว้างเปลี่ยน)
                withFrameNanos { }
                val i = g.ids.indexOf(f)
                if (i < 0) return@launch
                listState.animateScrollBy(g.snap.stops[i] - g.absolute(listState), Motion.page.float)
            }
        }

        Column(
            Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(14.dp, Alignment.CenterVertically),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            LazyRow(
                state = listState,
                modifier = Modifier.fillMaxWidth().bleedHeight(rowH, DECK_BLEED),
                // ใบแรก/ใบท้ายหยุดกลางจอได้ — เว้นหัวท้ายตามความกว้างของใบนั้นเอง
                contentPadding = PaddingValues(
                    start = ((box.width - sizes.first().width) / 2f).coerceAtLeast(0f).dp,
                    end = ((box.width - sizes.last().width) / 2f).coerceAtLeast(0f).dp,
                    top = DECK_BLEED.dp,
                    bottom = DECK_BLEED.dp,
                ),
                horizontalArrangement = Arrangement.spacedBy(DECK_SPACING.dp),
                verticalAlignment = Alignment.CenterVertically,
                flingBehavior = fling,
            ) {
                items(deckRecords, key = { it.id }) { record ->
                    DeckCard(
                        record = record,
                        restored = g.unpacked.restore(record),
                        size = m.size(record.format),
                        radius = m.radius(record.format),
                        live = record.id == publishedID,
                        embedded = embedded,
                        onOpen = onOpen,
                        onPreview = onPreview,
                    )
                }
                item(key = CREATE_ID) {
                    CreateCard(
                        size = m.size(createFormat),
                        radius = m.radius(createFormat),
                        fg = fg,
                        onCreate = onCreate,
                    )
                }
            }

            // ชื่อใบเกาะใต้ใบที่อยู่กลางจอ — ใบแนวนอนเตี้ยกว่า ชื่อจึงขยับขึ้นตาม
            val lift by animateFloatAsState(-(rowH - focusH) / 2f, Motion.settle.float, label = "captionLift")
            DeckCaption(
                all = g.order + CREATE_ID,
                focus = g.focus,
                published = published,
                focused = focused,
                fg = fg,
                onPick = { id ->
                    Haptics.impact(Haptics.Style.light)
                    g.focus = id
                },
                modifier = Modifier.offset(y = lift.dp),
            )
        }
    }
}

/** การ์ดหนึ่งใบในสำรับ — ใบที่แสดงอยู่มีป้ายเขียวบนตัวการ์ดและขอบเรืองสีธีมของมัน */
@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun DeckCard(
    record: CardRecord,
    restored: CardStore.Restored?,
    size: Size,
    radius: Float,
    live: Boolean,
    embedded: Boolean,
    onOpen: (CardRecord) -> Unit,
    onPreview: ((CardRecord) -> Unit)?,
) {
    val fallback = remember { CardTheme() }
    val theme = restored?.theme ?: fallback
    val pages = restored?.pages ?: emptyList()
    val blank = remember { CardPage() }
    val landscape = record.format == CardFormat.portfolio
    val shape = RoundedCornerShape(radius.dp)
    val accent = theme.rawAccent

    val glow by animateColorAsState(
        if (live) accent.opacity(0.45) else Color.Black.opacity(if (embedded) 0.22 else 0.5),
        Motion.settle.spec(), label = "cardGlow",
    )
    val glowRadius by animateFloatAsState(if (live) 30f else 24f, Motion.settle.float, label = "cardGlowRadius")
    val rim by animateColorAsState(if (live) accent.opacity(0.9) else Color.White.opacity(0.14), Motion.settle.spec(), label = "cardRim")
    val rimWidth by animateFloatAsState(if (live) 1.6f else 0.8f, Motion.settle.float, label = "cardRimWidth")
    val source = remember { MutableInteractionSource() }

    Box(
        Modifier
            .size(size.width.dp, size.height.dp)
            .glowShadow(glow, glowRadius, 14f, radius)
            .semantics { contentDescription = record.name + if (live) " · กำลังแสดงอยู่" else "" }
            .combinedClickable(
                interactionSource = source,
                indication = null,
                onClick = {
                    Haptics.impact(Haptics.Style.light)
                    onOpen(record)
                },
                // ทางลัดไว้เทส: กดค้างที่การ์ด = เปิดโหมดดู (หน้าเดียวกับ ⋯ › มุมมองแบรนด์)
                onLongClick = onPreview?.let { preview ->
                    {
                        Haptics.impact(Haptics.Style.medium)
                        preview(record)
                    }
                },
            ),
    ) {
        Box(
            Modifier
                .matchParentSize()
                .clip(shape)
                // สีธีมรองไว้ใต้พรีวิว — ระหว่างรูปในการ์ดยังโหลดไม่เสร็จ ใบไม่เป็นช่องโหว่ใส
                .background(Brush.verticalGradient(listOf(theme.backdropColors.top, theme.backdropColors.bottom))),
        ) {
            when (record.format) {
                // แนวนอน = ครบสามหน้าบนแผ่นเดียว — หน้าตาเดียวกับรูปที่แชร์ออกไปจริง
                CardFormat.portfolio -> CardStripPreview(
                    pages = pages, theme = theme, width = size.width, showsDividers = false,
                    gutter = STRIP_GUTTER, margin = STRIP_MARGIN, cornerRadius = radius,
                )
                CardFormat.story -> CardFramePreview(
                    page = pages.firstOrNull() ?: blank, theme = theme,
                    pageSize = CardTemplate.previewPageSize(CardFormat.story),
                    height = size.height, cornerRadius = radius,
                )
            }
        }
        Box(Modifier.matchParentSize().border(rimWidth.dp, rim, shape))

        // ป้ายบนตัวการ์ด ไม่ใช่ข้าง ๆ — เลื่อนผ่านเร็ว ๆ ก็ยังรู้ว่าใบนี้คือใบที่คนเห็น
        // ใบแนวนอนเตี้ย ป้ายวางบนตัวการ์ดจะทับหน้าแรกไปครึ่งหน้า — ย้ายไปเกาะเหนือขอบบนแทน
        AnimatedVisibility(
            visible = live,
            enter = scaleIn(Motion.settle.float, 0.6f, if (landscape) TransformOrigin(0f, 1f) else TransformOrigin(0f, 0f)) +
                fadeIn(Motion.settle.float),
            exit = scaleOut(Motion.settle.float, 0.6f, if (landscape) TransformOrigin(0f, 1f) else TransformOrigin(0f, 0f)) +
                fadeOut(Motion.settle.float),
            modifier = Modifier
                .align(Alignment.TopStart)
                .padding(if (landscape) 0.dp else 12.dp)
                .offset(y = if (landscape) (-40).dp else 0.dp),
        ) {
            LiveBadge()
        }
        // ป้ายรับรองเกาะเหนือขอบบนขวา คู่กับป้าย "กำลังแสดงอยู่" — อยู่นอกตัวการ์ด ไม่กินพื้นที่งานของเจ้าของ
        if (VerifiedFacts.current.verified) {
            VerifiedTab(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(if (landscape) 0.dp else 12.dp)
                    .offset(y = if (landscape) (-40).dp else 0.dp),
            )
        }
    }
}

@Composable
private fun LiveBadge() {
    Row(
        Modifier
            .background(Color.Black.opacity(0.62), CircleShape)
            .border(0.6.dp, Color.White.opacity(0.18), CircleShape)
            .padding(horizontal = 11.dp, vertical = 7.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(6.dp).background(SHColor.success, CircleShape))
        Text("กำลังแสดงอยู่", style = sh(11f, SHFont.bold), color = Color.White, maxLines = 1, softWrap = false)
    }
}

/** ใบเปล่าท้ายสำรับ — วิธีเพิ่มอยู่ในที่เดียวกับของที่มี ไม่ต้องไปหาปุ่มที่อื่น */
@Composable
private fun CreateCard(size: Size, radius: Float, fg: Color, onCreate: () -> Unit) {
    val shape = RoundedCornerShape(radius.dp)
    Box(
        Modifier
            .size(size.width.dp, size.height.dp)
            .background(fg.opacity(0.05), shape)
            .dashedRoundBorder(fg.opacity(0.28), 1.2f, 7f, 6f, radius)
            .semantics { contentDescription = "สร้างการ์ดใหม่" }
            .tap {
                Haptics.impact(Haptics.Style.medium)
                onCreate()
            },
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(
                Modifier
                    .size(56.dp)
                    .glowShadow(SHColor.red.opacity(0.4), 14f, 6f)
                    .background(SHColor.red, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                SFSymbol("plus", size = 22f, tint = Color.White)
            }
            Text("สร้างการ์ดใหม่", style = sh(14f, SHFont.semibold), color = fg.opacity(0.85))
            Text("เลือกจากเทมเพลต", style = sh(11.5f, SHFont.medium), color = fg.opacity(0.45))
        }
    }
}

/** ใต้สำรับ: ชื่อใบที่ดูอยู่ + จุดบอกตำแหน่งในสำรับ (จุดแยกกัน — เพราะนี่คือ **คนละใบ** จริง ๆ) */
@Composable
private fun DeckCaption(
    all: List<String>,
    focus: String?,
    published: CardRecord?,
    focused: CardRecord?,
    fg: Color,
    onPick: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val index = all.indexOf(focus ?: published?.id ?: "").coerceAtLeast(0)
    Column(
        modifier.padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Crossfade(
            targetState = (focused?.id ?: CREATE_ID) to (focused?.name ?: "สร้างการ์ดใหม่"),
            animationSpec = Motion.snap.float,
            label = "captionName",
        ) { (_, name) ->
            Text(
                name,
                style = sh(15f, SHFont.semibold),
                color = fg,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            all.forEachIndexed { i, id ->
                key(id) {
                    val active = i == index
                    // ช่อง "สร้างใหม่" ไม่ใช่การ์ด — เป็น + ไม่ใช่จุด จำนวนจุดจึงเท่ากับ "การ์ด N ใบ" ในหัว
                    if (id == CREATE_ID) {
                        Box(
                            Modifier.size(10.dp, 6.dp).tap { onPick(id) },
                            contentAlignment = Alignment.Center,
                        ) {
                            PIcon(
                                Ph.plus, size = 8f, weight = PhWeight.bold,
                                tint = fg.opacity(if (active) 0.95 else 0.4),
                                modifier = Modifier.wrapContentSize(unbounded = true),
                            )
                        }
                    } else {
                        val w by animateFloatAsState(if (active) 18f else 6f, Motion.snap.float, label = "dot")
                        val c by animateColorAsState(fg.opacity(if (active) 0.95 else 0.3), Motion.snap.spec(), label = "dotColor")
                        Box(
                            Modifier
                                .size(w.dp, 6.dp)
                                .background(c, CircleShape)
                                .tap { onPick(id) },
                        )
                    }
                }
            }
        }
    }
}

// MARK: - ล่าง: ปุ่มของใบที่ดูอยู่

@Composable
private fun GalleryDock(
    record: CardRecord?,
    publishedID: String?,
    slug: String,
    themeOf: (CardRecord) -> CardTheme,
    copied: Boolean,
    fg: Color,
    light: Boolean,
    onCopy: (String) -> Unit,
    onShare: (String) -> Unit,
    onOpen: (CardRecord) -> Unit,
    onPublish: (CardRecord) -> Unit,
    onMore: () -> Unit,
    onCreate: () -> Unit,
    modifier: Modifier = Modifier,
) {
    AnimatedContent(
        targetState = record,
        contentKey = { it?.id },
        transitionSpec = { fadeIn(Motion.settle.float) togetherWith fadeOut(Motion.settle.float) },
        label = "galleryDock",
        modifier = modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 10.dp, bottom = 8.dp),
    ) { r ->
        if (r != null) {
            val library = CardLibrary.shared
            val theme = themeOf(r)
            val live = r.id == publishedID
            val url = library.url(r, slug)
            val display = library.urlDisplay(r, slug)
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                // ทุกใบมีลิงก์ของตัวเอง คัดลอกได้หมด — แถบลิงก์จึงโชว์ทุกใบ ไม่ใช่เฉพาะใบที่แสดงอยู่
                LinkPill(display = display, copied = copied, fg = fg, light = light, onCopy = { onCopy(url) })
                Crossfade(targetState = live, animationSpec = Motion.settle.float, label = "dockButtons") { isLive ->
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                        if (isLive) {
                            PrimaryButton(Ph.pencilSimple, "แต่งการ์ด", tint = theme.rawAccent, modifier = Modifier.weight(1f)) { onOpen(r) }
                            SecondaryButton(Ph.shareNetwork, "แชร์", fg = fg, light = light, lift = true) { onShare(url) }
                        } else {
                            // ปุ่มหลักของใบที่ยังไม่แสดงคือ "ใช้ใบนี้" — ท่าที่คนมาหน้านี้เพื่อทำมากที่สุด
                            PrimaryButton(Ph.check, "ใช้ใบนี้", tint = theme.rawAccent, modifier = Modifier.weight(1f)) { onPublish(r) }
                            SecondaryButton(Ph.pencilSimple, "แต่ง", fg = fg, light = light) {
                                Haptics.impact(Haptics.Style.light)
                                onOpen(r)
                            }
                        }
                        // ⋯ อยู่ท้ายแถวปุ่มของใบ — เป็นคำสั่งของใบตรงหน้า จึงอยู่กับปุ่มของใบ ไม่ใช่มุมบน
                        MoreButton(fg = fg, light = light, onClick = onMore)
                    }
                }
            }
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Spacer(Modifier.height(42.dp))
                PrimaryButton(Ph.plus, "สร้างการ์ดใหม่", tint = SHColor.red, light = true, modifier = Modifier.fillMaxWidth()) { onCreate() }
            }
        }
    }
}

/** ปุ่มหลักปุ่มเดียวของแถบล่าง — สีเน้นของใบที่ดูอยู่ ทั้งหน้าจึงพูดสีเดียวกัน */
@Composable
private fun PrimaryButton(
    icon: Ph,
    title: String,
    tint: Color,
    light: Boolean = false,
    modifier: Modifier = Modifier,
    action: () -> Unit,
) {
    val fg = if (light) Color.White else Color.Black.opacity(0.86)
    StageGlassPanel(
        radius = 26f,
        tint = tint,
        modifier = modifier
            .height(52.dp)
            .dockPress {
                Haptics.impact(Haptics.Style.medium)
                action()
            },
    ) {
        Row(
            Modifier.fillMaxWidth().height(52.dp),
            horizontalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PIcon(icon, size = 14f, weight = PhWeight.bold, tint = fg)
            Text(title, style = sh(15f, SHFont.bold), color = fg, maxLines = 1, softWrap = false)
        }
    }
}

@Composable
private fun SecondaryButton(icon: Ph, title: String, fg: Color, light: Boolean, lift: Boolean = false, action: () -> Unit) {
    StageGlassPanel(
        radius = 26f,
        light = light,
        modifier = Modifier.height(52.dp).dockPress { action() },
    ) {
        Row(
            Modifier.height(52.dp).padding(horizontal = 22.dp),
            horizontalArrangement = Arrangement.spacedBy(7.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PIcon(icon, size = 14f, weight = PhWeight.bold, tint = fg, modifier = Modifier.offset(y = if (lift) (-1).dp else 0.dp))
            Text(title, style = sh(15f, SHFont.semibold), color = fg, maxLines = 1, softWrap = false)
        }
    }
}

/** ⋯ ของใบที่ดูอยู่ — วงกลมสูงเท่าปุ่มในแถว */
@Composable
private fun MoreButton(fg: Color, light: Boolean, onClick: () -> Unit) {
    StageGlassPanel(
        radius = 26f,
        light = light,
        modifier = Modifier
            .size(52.dp)
            .semantics { contentDescription = "ตัวเลือกของการ์ดใบนี้" }
            .dockPress { onClick() },
    ) {
        Row(
            Modifier.size(52.dp),
            horizontalArrangement = Arrangement.spacedBy(3.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            repeat(3) { Box(Modifier.size(4.dp).background(fg, CircleShape)) }
        }
    }
}

/** ลิงก์ของฉัน — แตะทั้งแถบ = คัดลอก · ลิงก์คือของที่ส่งให้แบรนด์ จึงอยู่ติดปุ่ม ไม่ซ่อนในเมนู */
@Composable
private fun LinkPill(display: String, copied: Boolean, fg: Color, light: Boolean, onCopy: () -> Unit) {
    val tint = if (copied) SHColor.success else fg.opacity(0.9)
    StageGlassPanel(
        radius = 21f,
        light = light,
        modifier = Modifier
            .fillMaxWidth()
            .height(42.dp)
            .semantics { contentDescription = if (copied) "คัดลอกลิงก์แล้ว" else "คัดลอกลิงก์ของฉัน" }
            .dockPress { onCopy() },
    ) {
        Row(
            Modifier.fillMaxWidth().height(42.dp).padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Crossfade(targetState = copied, animationSpec = Motion.settle.float, label = "linkIcon") { done ->
                PIcon(if (done) Ph.check else Ph.link, size = 11f, weight = PhWeight.bold, tint = tint)
            }
            Text(
                if (copied) "คัดลอกลิงก์แล้ว" else display,
                style = sh(12.5f, SHFont.semibold),
                color = tint,
                maxLines = 1,
                overflow = TextOverflow.MiddleEllipsis,
                modifier = Modifier.weight(1f),
            )
            if (!copied) {
                Text("คัดลอก", style = sh(11f, SHFont.semibold), color = fg.opacity(0.55), maxLines = 1, softWrap = false)
            }
        }
    }
}

// MARK: - ชีตคำสั่งรอง (ฟอนต์แอปทุกตัวอักษร)

@Composable
private fun GallerySheet(
    g: GalleryState,
    record: CardRecord?,
    onCopyLink: (CardRecord) -> Unit,
    onPreview: ((CardRecord) -> Unit)?,
    onDuplicate: (CardRecord) -> Unit,
    onRename: (CardRecord) -> Unit,
    onDelete: (CardRecord) -> Unit,
) {
    val shown = g.sheetOpen && record != null
    // ใบที่ชีตพูดถึง — ค้างไว้ระหว่างชีตกำลังลง แม้ใบกลางจอจะเปลี่ยนไปแล้ว
    val held = remember { arrayOfNulls<CardRecord>(1) }
    if (shown) held[0] = record

    Box(Modifier.fillMaxSize()) {
        AnimatedVisibility(visible = shown, enter = fadeIn(Motion.settle.float), exit = fadeOut(Motion.settle.float)) {
            Box(Modifier.fillMaxSize().background(Color.Black.opacity(0.35)).tap { g.sheetOpen = false })
        }
        AnimatedVisibility(
            visible = shown,
            enter = slideInVertically(Motion.settle.spec()) { it },
            exit = slideOutVertically(Motion.settle.spec()) { it },
            modifier = Modifier.align(Alignment.BottomCenter).imePadding(),
        ) {
            val r = held[0] ?: return@AnimatedVisibility
            val detent by animateFloatAsState(if (g.mode == GallerySheetMode.menu) 340f else 252f, Motion.settle.float, label = "sheetDetent")
            val sheetShape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)
            Column(
                Modifier
                    .fillMaxWidth()
                    .clip(sheetShape)
                    // มืดแบบเดียวกับชีตเครื่องมือในห้องแต่ง — เครื่องมือมืดเสมอ
                    .background(grey(0.16).opacity(0.94))
                    .background(grey(0.07).opacity(0.5))
                    .tap { }
                    .windowInsetsPadding(WindowInsets.navigationBars),
            ) {
                Box(Modifier.fillMaxWidth().padding(top = 5.dp), contentAlignment = Alignment.Center) {
                    Box(Modifier.size(36.dp, 5.dp).background(Color.White.opacity(0.3), CircleShape))
                }
                // ความสูงตามจุดหยุดของชีต — เนื้อหายาวกว่านั้นชีตสูงตาม (ไม่มีการลากขยายแบบ iOS)
                Box(Modifier.fillMaxWidth().heightIn(min = (detent - 10f).dp)) {
                    SheetContent(
                        g = g, record = r, onCopyLink = onCopyLink, onPreview = onPreview,
                        onDuplicate = onDuplicate, onRename = onRename, onDelete = onDelete,
                    )
                }
            }
        }
    }
}

@Composable
private fun SheetContent(
    g: GalleryState,
    record: CardRecord,
    onCopyLink: (CardRecord) -> Unit,
    onPreview: ((CardRecord) -> Unit)?,
    onDuplicate: (CardRecord) -> Unit,
    onRename: (CardRecord) -> Unit,
    onDelete: (CardRecord) -> Unit,
) {
    Column(
        Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 14.dp, bottom = 14.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        when (g.mode) {
            GallerySheetMode.menu -> {
                Text(
                    record.name,
                    style = sh(15f, SHFont.semibold),
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.padding(top = 4.dp),
                )
                // ลิงก์ของใบนี้ — ใบรองมีลิงก์เฉพาะใบของตัวเอง (ส่งใบไหนให้แบรนด์ไหนก็เลือกเอา)
                SheetRow(Ph.link, "คัดลอกลิงก์") { onCopyLink(record) }
                // เห็นสิ่งที่แบรนด์เห็นเมื่อกดลิงก์ — เวที ตรา และแถบผู้ออกบัตร ก่อนส่งจริง
                if (onPreview != null) SheetRow(Ph.eye, "มุมมองแบรนด์") { onPreview(record) }
                SheetRow(Ph.pencilSimple, "เปลี่ยนชื่อ") {
                    g.renameText = record.name
                    g.mode = GallerySheetMode.rename
                }
                SheetRow(Ph.browsers, "ทำสำเนา") { onDuplicate(record) }
                SheetRow(Ph.x, "ลบการ์ด", destructive = true) { g.mode = GallerySheetMode.confirmDelete }
            }

            GallerySheetMode.rename -> {
                Text("เปลี่ยนชื่อการ์ด", style = sh(15f, SHFont.semibold), color = Color.White, modifier = Modifier.padding(top = 4.dp))
                Text("ตั้งชื่อให้จำง่าย เช่น \"ใบส่งสายบิวตี้\"", style = sh(11.5f, SHFont.medium), color = Color.White.opacity(0.45))
                BasicTextField(
                    value = g.renameText,
                    onValueChange = { g.renameText = it },
                    singleLine = true,
                    textStyle = sh(14.5f, SHFont.semibold).merge(TextStyle(color = Color.White)),
                    cursorBrush = SolidColor(Color.White),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                    keyboardActions = KeyboardActions(onDone = { onRename(record) }),
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color.White.opacity(0.08), RoundedCornerShape(12.dp))
                        .padding(horizontal = 14.dp, vertical = 11.dp),
                    decorationBox = { field ->
                        Box {
                            if (g.renameText.isEmpty()) {
                                Text("ชื่อการ์ด", style = sh(14.5f, SHFont.semibold), color = Color.White.opacity(0.3))
                            }
                            field()
                        }
                    },
                )
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    SheetPill("ยกเลิก", modifier = Modifier.weight(1f)) { g.sheetOpen = false }
                    SheetPill("บันทึก", prominent = true, modifier = Modifier.weight(1f)) { onRename(record) }
                }
            }

            GallerySheetMode.confirmDelete -> {
                Text(
                    "ลบ \"${record.name}\"?",
                    style = sh(15f, SHFont.semibold),
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.MiddleEllipsis,
                    modifier = Modifier.padding(top = 4.dp),
                )
                Text("ลิงก์ของใบนี้จะใช้ไม่ได้อีก และกู้คืนไม่ได้", style = sh(11.5f, SHFont.medium), color = Color.White.opacity(0.45))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    SheetPill("เก็บไว้", modifier = Modifier.weight(1f)) { g.sheetOpen = false }
                    SheetPill("ลบการ์ดนี้", destructive = true, modifier = Modifier.weight(1f)) { onDelete(record) }
                }
            }
        }
    }
}

/** แถวคำสั่งในชีต — ไอคอน + ตัวหนังสือฟอนต์แอป บนแผ่นจาง ๆ */
@Composable
private fun SheetRow(icon: Ph, title: String, destructive: Boolean = false, action: () -> Unit) {
    val tint = if (destructive) SHColor.red else Color.White.opacity(0.9)
    Row(
        Modifier
            .fillMaxWidth()
            .background(Color.White.opacity(0.06), RoundedCornerShape(12.dp))
            .tap { action() }
            .padding(horizontal = 14.dp, vertical = 13.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.width(22.dp), contentAlignment = Alignment.Center) {
            PIcon(icon, size = 15f, weight = PhWeight.bold, tint = tint)
        }
        Text(title, style = sh(14.5f, SHFont.semibold), color = tint, modifier = Modifier.weight(1f))
    }
}

/** ปุ่มแคปซูลคู่ท้ายชีต — ยืนยัน/ยกเลิก */
@Composable
private fun SheetPill(
    title: String,
    prominent: Boolean = false,
    destructive: Boolean = false,
    modifier: Modifier = Modifier,
    action: () -> Unit,
) {
    Box(
        modifier
            .background(
                when {
                    destructive -> SHColor.red
                    prominent -> Color.White.opacity(0.18)
                    else -> Color.White.opacity(0.08)
                },
                CircleShape,
            )
            .tap { action() }
            .padding(vertical = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            title,
            style = sh(13.5f, SHFont.semibold),
            color = if (destructive || prominent) Color.White else Color.White.opacity(0.75),
        )
    }
}

// MARK: - คลังว่าง

/** ปกติจะไม่เห็น — คลังว่างแล้ว shell พาไปเลือกเทมเพลตเอง · มีไว้กันจอว่างระหว่างสลับ */
@Composable
private fun EmptyState(fg: Color, onCreate: () -> Unit, modifier: Modifier = Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
        SFSymbol("rectangle.stack.badge.plus", size = 40f, tint = fg.opacity(0.35))
        Text("ยังไม่มีการ์ด", style = sh(16f, SHFont.semibold), color = fg.opacity(0.85))
        Box(
            Modifier
                .padding(top = 6.dp)
                .background(SHColor.red, RoundedCornerShape(10.dp))
                .tap {
                    Haptics.impact(Haptics.Style.medium)
                    onCreate()
                }
                .padding(horizontal = 22.dp, vertical = 11.dp),
        ) {
            Text("เลือกเทมเพลต", style = sh(13.5f, SHFont.semibold), color = Color.White)
        }
    }
}
