package co.salehere.starcard.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.layout.positionInParent
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import co.salehere.starcard.AppContext
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.model.CardFormat
import co.salehere.starcard.model.CardPage
import co.salehere.starcard.model.CardTemplate
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.theme.CardBackdrop
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * หน้าเลือกสไตล์ — **ผนังโปสเตอร์: การ์ดหลายใบขนาดอ่านออกบนเวทีเดียวกัน ทุกใบเรืองแสงสีของตัวเอง**
 *
 * กริดสองคอลัมน์ + แท็บขีดใต้ คือหน้าตาของ "รายการไฟล์" · สำรับปัดทีละใบสวยแต่เห็นสไตล์เดียวต่อครั้ง
 * ผนังจึงเอาสองอย่างมารวมกัน: ของหลายใบพร้อมกันแบบกริด แต่ทุกใบเป็นวัตถุจริงบนเวทีมืดแบบสำรับ
 * เวทีอาบสีของใบที่อยู่ใกล้กลางจอที่สุด · แตะใบไหน = เริ่มแต่งใบนั้น
 * - onBack: ทางกลับไปคลังการ์ด — null เมื่อคลังยังว่าง (หน้านี้คือหน้าแรก ไม่มีที่ให้กลับ)
 */
@Composable
fun TemplatePicker(
    initialFormat: CardFormat = CardFormat.portfolio,
    onPick: (CardFormat, CardTemplate) -> Unit,
    onBack: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    var format by remember { mutableStateOf(initialFormat) }
    /** ใบที่อยู่ใกล้กลางจอที่สุด — เวทีอาบสีของใบนี้ */
    var nearest by remember { mutableStateOf<CardTemplate?>(null) }
    /** สวิตช์ท่าเข้าฉาก — หัวลงมา ใบถูกแปะขึ้นผนังทีละใบ */
    var appeared by remember { mutableStateOf(false) }
    val templates = remember { CardFormat.entries.associateWith { CardTemplate.all(it) } }
    val photos = LocalPhotoStore.current

    val list = templates[format].orEmpty()
    /** ธีมของเวที — ใบใกล้กลางจอ หรือใบแรกระหว่างผนังยังไม่รายงาน */
    val stageTheme = (nearest?.let { n -> list.firstOrNull { it.id == n.id } } ?: list.firstOrNull())?.theme ?: CardTheme()

    val header = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        appeared = true
        delay(80)
        header.animateTo(1f, Motion.settle.float)
    }
    LaunchedEffect(photos) { photos?.let { TemplateThumbs.shared.warm(it) } }

    Box(modifier.fillMaxSize()) {
        PickerStage(stageTheme)

        Column(
            Modifier
                .fillMaxSize()
                .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal)),
        ) {
            PickerHeader(
                format = format,
                onFormat = { f ->
                    if (f != format) {
                        Haptics.impact(Haptics.Style.light)
                        format = f
                    }
                },
                onBack = onBack,
                modifier = Modifier.graphicsLayer {
                    val p = header.value.coerceIn(0f, 1f)
                    alpha = p
                    translationY = -12f * (1f - header.value) * density
                },
            )

            // ผนังเกิดใหม่ทั้งผืนตอนสลับรูปแบบ — ผังคนละแบบ ระยะเลื่อนใช้ร่วมกันไม่ได้
            AnimatedContent(
                targetState = format,
                transitionSpec = {
                    (fadeIn(Motion.settle.float) + scaleIn(Motion.settle.float, initialScale = 0.96f)) togetherWith
                        fadeOut(Motion.settle.float)
                },
                label = "templateWall",
                modifier = Modifier.weight(1f).fillMaxWidth(),
            ) { f ->
                TemplateWall(
                    templates = templates[f].orEmpty(),
                    format = f,
                    appeared = appeared,
                    nearest = nearest,
                    onNearestChange = { nearest = it },
                    onPick = { picked -> onPick(f, picked) },
                )
            }
        }
    }
}

// MARK: - เวที

/** ฉากหลังทั้งจอ = ฉากหลังของสไตล์ที่ใกล้กลางจอ หรี่ลงให้ใบจริงลอยเด่น — เลื่อนผ่านใบไหน ห้องเปลี่ยนสีตาม */
@Composable
private fun PickerStage(theme: CardTheme) {
    Crossfade(targetState = theme, animationSpec = Motion.settle.float, label = "pickerStage", modifier = Modifier.fillMaxSize()) { t ->
        Box(Modifier.fillMaxSize()) {
            CardBackdrop(theme = t, ignoreSafeArea = true)
            Box(
                Modifier.fillMaxSize().background(
                    Brush.verticalGradient(listOf(Color.Black.opacity(0.66), Color.Black.opacity(0.5), Color.Black.opacity(0.76))),
                ),
            )
        }
    }
}

// MARK: - หัว: กลับ + ชื่อหน้า + สวิตช์รูปแบบ

/** แถวบน: กลับ · ชื่อหน้า "Template" กลางจอ — แถวล่าง: สวิตช์รูปแบบเต็มคำ ไม่ถูกตัดเป็น "…" */
@Composable
private fun PickerHeader(
    format: CardFormat,
    onFormat: (CardFormat) -> Unit,
    onBack: (() -> Unit)?,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 6.dp, bottom = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.fillMaxWidth().height(40.dp), contentAlignment = Alignment.Center) {
            Text(
                "Template",
                style = sh(20f, SHFont.bold),
                color = Color.White,
                modifier = Modifier.semantics { heading() },
            )
            if (onBack != null) {
                StageGlassPanel(
                    radius = 20f,
                    modifier = Modifier
                        .align(Alignment.CenterStart)
                        .size(40.dp)
                        .semantics { contentDescription = "กลับไปคลังการ์ด" }
                        .dockPress {
                            Haptics.impact(Haptics.Style.light)
                            onBack()
                        },
                ) {
                    Box(Modifier.size(40.dp), contentAlignment = Alignment.Center) {
                        SFSymbol("chevron.left", size = 15f, tint = Color.White.opacity(0.92))
                    }
                }
            }
        }

        FormatSwitch(format = format, onFormat = onFormat)
    }
}

/**
 * สวิตช์รูปแบบ — แคปซูลกระจกสองช่อง แผ่นสว่างไหลไปช่องที่เลือก
 * ตัวเลือกสองทางบนกระจกคือภาษาเดียวกับแถบเครื่องมือในห้องแต่ง (แท็บขีดใต้แดงอ่านเป็นแอปข่าว)
 */
@Composable
private fun FormatSwitch(format: CardFormat, onFormat: (CardFormat) -> Unit) {
    val density = LocalDensity.current.density
    /** กรอบของแต่ละช่องในแถว (หน่วยออกแบบ) — แผ่นเลือกไหลจากช่องเดิมไปช่องใหม่ */
    val slots = remember { mutableStateMapOf<CardFormat, Pair<Float, Float>>() }
    val x = remember { Animatable(0f) }
    val w = remember { Animatable(0f) }
    var placed by remember { mutableStateOf(false) }
    val target = slots[format]
    LaunchedEffect(target) {
        val t = target ?: return@LaunchedEffect
        if (!placed) {
            x.snapTo(t.first); w.snapTo(t.second); placed = true
        } else {
            launch { x.animateTo(t.first, Motion.settle.float) }
            w.animateTo(t.second, Motion.settle.float)
        }
    }

    StageGlassPanel(radius = 22f) {
        Box(Modifier.padding(3.dp)) {
            if (placed) {
                Box(
                    Modifier
                        .graphicsLayer { translationX = x.value * density }
                        .size(w.value.dp, 38.dp)
                        .background(Color.White.opacity(0.17), CircleShape),
                )
            }
            Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                for (f in CardFormat.entries) {
                    val active = f == format
                    val tint = if (active) Color.White else Color.White.opacity(0.55)
                    Row(
                        Modifier
                            .height(38.dp)
                            .onGloballyPositioned { c ->
                                slots[f] = (c.positionInParent().x / density) to (c.size.width / density)
                            }
                            .semantics { contentDescription = "${f.title} · ${f.subtitle}" }
                            .tap {
                                if (!active) onFormat(f)
                            }
                            .padding(horizontal = 16.dp),
                        horizontalArrangement = Arrangement.spacedBy(7.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        FormatGlyph(f, tint)
                        Text(
                            if (f == CardFormat.portfolio) "แนวนอน" else "แนวตั้ง",
                            style = sh(13.5f, if (active) SHFont.bold else SHFont.semibold),
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

/** รูปทรงผลลัพธ์ย่อจิ๋ว — แถบสามหน้า / เฟรมตั้ง */
@Composable
private fun FormatGlyph(f: CardFormat, tint: Color) {
    when (f) {
        CardFormat.portfolio -> Row(horizontalArrangement = Arrangement.spacedBy(1.5.dp)) {
            repeat(3) { Box(Modifier.size(4.dp, 13.dp).background(tint, RoundedCornerShape(1.2.dp))) }
        }
        CardFormat.story -> Box(Modifier.size(9.dp, 15.dp).background(tint, RoundedCornerShape(2.dp)))
    }
}

// MARK: - ผนัง

/** ผังของผนัง (= static ของ `TemplateWall`) */
object TemplateWall {
    const val sidePadding: Float = 20f
    const val gutter: Float = 14f
    const val rowSpacing: Float = 18f
    /** คอลัมน์ขวาเยื้องลงเท่านี้ — ผนังโปสเตอร์ ไม่ใช่ตาราง */
    const val stagger: Float = 56f
    internal const val topPadding: Float = 14f
    internal const val bottomPadding: Float = 28f

    /** จอที่แอปแสดงอยู่ (= `UIScreen`) — ขนาดเป็นหน่วยออกแบบ (dp) · `scale` = พิกเซลต่อหน่วย */
    data class Screen(val bounds: Size, val scale: Float)

    val screen: Screen?
        get() = runCatching {
            val dm = AppContext.app.resources.displayMetrics
            Screen(Size(dm.widthPixels / dm.density, dm.heightPixels / dm.density), dm.density)
        }.getOrNull()

    /** ขนาดของใบบนผนัง — **ที่เดียว**ที่ตัดสินทั้งผังของผนังและขนาดของรูปพรีวิว */
    fun cardSize(format: CardFormat): Size {
        val width = min(screen?.bounds?.width ?: 402f, 480f)
        return when (format) {
            CardFormat.story -> {
                val w = floor((width - sidePadding * 2 - gutter) / 2f)
                Size(w, (w * 960f / 540f).roundToInt().toFloat())
            }
            CardFormat.portfolio -> {
                val w = width - sidePadding * 2
                Size(w, CardStripPreview.height(w, CardTemplate.thumbGutter, CardTemplate.thumbGutter).roundToInt().toFloat())
            }
        }
    }

    /** มุมนอกของใบแนวนอนเล็กกว่า — ร่วมศูนย์กับมุมของหน้าข้างใน (เหตุผลเดียวกับสำรับในคลัง) */
    fun radius(format: CardFormat): Float = if (format == CardFormat.story) 18f else 14f

    /** จุดกึ่งกลางแนวตั้งของใบ `i` ในพิกัดเนื้อหา — สูตรเดียวกับที่ผังวางจริง */
    internal fun centerY(i: Int, size: Size, format: CardFormat): Float {
        val step = size.height + rowSpacing
        return when (format) {
            CardFormat.story -> topPadding + (i / 2) * step + (if (i % 2 == 1) stagger else 0f) + size.height / 2f
            CardFormat.portfolio -> topPadding + i * step + size.height / 2f
        }
    }
}

/**
 * ผนังสไตล์ — ทุกใบเป็นวัตถุจริงขนาดอ่านออก เรืองแสงสีธีมของตัวเอง เลื่อนดูได้ทั้งผืน แตะใบไหน = เลือกใบนั้น
 *
 * ใบตั้งเรียงสองคอลัมน์ คอลัมน์ขวาเยื้องลงครึ่งก้าว — สายตาไล่เป็นซิกแซกเหมือนกวาดดูโปสเตอร์บนผนัง
 * ใบที่กำลังพ้นขอบบนล่างเอียงหนีและจางลง — ผนังโค้งออกจากสายตา ไม่ใช่รายการที่ถูกตัดขอบ
 */
@Composable
fun TemplateWall(
    templates: List<CardTemplate>,
    format: CardFormat,
    appeared: Boolean,
    nearest: CardTemplate?,
    onNearestChange: (CardTemplate?) -> Unit,
    onPick: (CardTemplate) -> Unit,
    modifier: Modifier = Modifier,
) {
    val size = TemplateWall.cardSize(format)
    val scroll = rememberScrollState()
    val density = LocalDensity.current.density
    var viewportH by remember { mutableFloatStateOf(0f) }
    /** ขอบบน/ล่างของช่องมองในพิกัดราก (px) — ใบใช้หาว่ากำลังพ้นขอบแค่ไหน */
    var viewTop by remember { mutableFloatStateOf(0f) }
    val report by rememberUpdatedState(onNearestChange)
    val current by rememberUpdatedState(nearest)

    // ใบที่ใกล้กลางจอที่สุด — เวทีอาบสีของมัน (ผังคงที่ คำนวณจากระยะเลื่อนได้ตรง ๆ ไม่ต้องวัดทีละใบ)
    LaunchedEffect(templates, format, size) {
        snapshotFlow {
            if (templates.isEmpty() || viewportH <= 0f) -1
            else {
                val midY = (scroll.value + viewportH / 2f) / density
                templates.indices.minByOrNull { abs(TemplateWall.centerY(it, size, format) - midY) } ?: 0
            }
        }.distinctUntilChanged().collect { i ->
            if (i in templates.indices && current?.id != templates[i].id) report(templates[i])
        }
    }

    Box(
        modifier
            .fillMaxSize()
            .onGloballyPositioned { c ->
                viewTop = c.positionInRoot().y
                viewportH = c.size.height.toFloat()
            }
            .onSizeChanged { viewportH = it.height.toFloat() }
            // ขอบบนล่างของผนังจางเข้าไปในเวทีแทนการตัดตรง ๆ
            .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
            .drawWithContent {
                drawContent()
                drawRect(
                    Brush.verticalGradient(
                        0f to Color.Transparent, 0.035f to Color.Black, 0.965f to Color.Black, 1f to Color.Transparent,
                    ),
                    blendMode = BlendMode.DstIn,
                )
            },
    ) {
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(scroll)
                .padding(horizontal = TemplateWall.sidePadding.dp)
                .padding(top = TemplateWall.topPadding.dp, bottom = TemplateWall.bottomPadding.dp)
                .navigationBarsPadding(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            val card: @Composable (Int) -> Unit = { i ->
                WallCard(
                    template = templates[i],
                    index = i,
                    size = size,
                    radius = TemplateWall.radius(format),
                    format = format,
                    appeared = appeared,
                    viewTop = { viewTop },
                    viewBottom = { viewTop + viewportH },
                    onPick = onPick,
                )
            }
            if (format == CardFormat.story) {
                Row(horizontalArrangement = Arrangement.spacedBy(TemplateWall.gutter.dp), verticalAlignment = Alignment.Top) {
                    Column(verticalArrangement = Arrangement.spacedBy(TemplateWall.rowSpacing.dp)) {
                        for (i in templates.indices step 2) card(i)
                    }
                    Column(
                        Modifier.padding(top = TemplateWall.stagger.dp),
                        verticalArrangement = Arrangement.spacedBy(TemplateWall.rowSpacing.dp),
                    ) {
                        for (i in 1 until templates.size step 2) card(i)
                    }
                }
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(TemplateWall.rowSpacing.dp)) {
                    for (i in templates.indices) card(i)
                }
            }
        }
    }
}

/** ใบหนึ่งใบ — รูปจริง + แสงสีธีมส่องจากด้านหลัง */
@Composable
private fun WallCard(
    template: CardTemplate,
    index: Int,
    size: Size,
    radius: Float,
    format: CardFormat,
    appeared: Boolean,
    viewTop: () -> Float,
    viewBottom: () -> Float,
    onPick: (CardTemplate) -> Unit,
) {
    val shape = RoundedCornerShape(radius.dp)
    val accent = template.theme.rawAccent
    val density = LocalDensity.current.density
    var top by remember { mutableFloatStateOf(0f) }
    var measured by remember { mutableStateOf(false) }

    // ท่าเข้าฉาก: ใบถูกแปะขึ้นผนังทีละใบ (ผนังที่เกิดตอนสลับรูปแบบ ใบอยู่ที่แล้ว)
    val enter = remember { Animatable(if (appeared) 1f else 0f) }
    LaunchedEffect(appeared) {
        if (appeared && enter.value < 1f) {
            delay(((0.12 + Motion.stagger(index, step = 0.055)) * 1000).toLong())
            enter.animateTo(1f, Motion.settle.float)
        }
    }

    val blank = remember { CardPage() }
    val thumb = TemplateThumbs.shared.image(template.id)
    val bitmap = remember(thumb) { thumb?.asImageBitmap() }

    Box(
        Modifier
            .onGloballyPositioned { c ->
                top = c.positionInRoot().y
                measured = true
            }
            .graphicsLayer {
                // ใบที่กำลังพ้นขอบบนล่างเอียงหนีและจางลง — ผนังโค้งออกจากสายตา
                val h = size.height * density
                val phase = if (!measured || h <= 0f) 0f else {
                    val t = top; val b = top + h
                    when {
                        t < viewTop() -> -min(1f, (viewTop() - t) / h)
                        b > viewBottom() -> min(1f, (b - viewBottom()) / h)
                        else -> 0f
                    }
                }
                val e = enter.value
                val s = 1f - 0.06f * abs(phase)
                scaleX = s; scaleY = s
                rotationX = -10f * phase
                cameraDistance = 10f * density
                alpha = ((1f - 0.45f * abs(phase)) * e).coerceIn(0f, 1f)
                translationY = 22f * (1f - e) * density
            }
            .semantics { contentDescription = "${template.name} — ${template.blurb}" }
            .dockPress {
                Haptics.impact(Haptics.Style.medium)
                onPick(template)
            }
            // แสงสีธีมของใบเองส่องออกมาด้านหลัง — ผนังทั้งผืนพูดเรื่องความหลากหลายด้วยสี
            .glowShadow(accent.opacity(0.42), 26f, 12f, radius)
            .size(size.width.dp, size.height.dp)
            .clip(shape)
            // สีธีมรองไว้ใต้รูป — ระหว่างรูปกำลังโหลด ใบไม่เป็นช่องโหว่ใส
            .background(Brush.verticalGradient(listOf(template.theme.backdropColors.top, template.theme.backdropColors.bottom)))
            .border(0.8.dp, Color.White.opacity(0.16), shape),
    ) {
        if (bitmap != null) {
            Image(bitmap, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
        } else {
            // ไม่มีรูปอบติดแอป — วาดพรีวิวสด (Android ไม่มี `ImageRenderer`)
            val pages = remember(template.id) { template.makePages() }
            when (format) {
                CardFormat.portfolio -> CardStripPreview(
                    pages = pages, theme = template.theme, width = size.width, showsDividers = false,
                    gutter = CardTemplate.thumbGutter, margin = CardTemplate.thumbGutter, cornerRadius = radius,
                )
                CardFormat.story -> CardFramePreview(
                    page = pages.firstOrNull() ?: blank,
                    theme = template.theme,
                    pageSize = CardTemplate.previewPageSize(CardFormat.story),
                    height = size.height,
                    cornerRadius = radius,
                )
            }
        }
    }
}
