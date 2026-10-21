package co.salehere.starcard.ui.salehere.starflow

import android.content.Context
import android.content.Intent
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.BlurredEdgeTreatment
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.rememberGraphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
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
import co.salehere.starcard.model.Portfolio
import co.salehere.starcard.model.Profile
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHColor
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.CardFramePreview
import co.salehere.starcard.ui.CardStripPreview
import co.salehere.starcard.ui.TemplateThumbs
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.dockPress
import co.salehere.starcard.ui.widgets.ImageCache
import co.salehere.starcard.ui.widgets.PhotoLib
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.sin

// MARK: - Star Card บนหน้า Star Profile (ผู้ใช้ 24 ก.ย. 2569)
//
// ปุ่มสลับ ข้อมูล | การ์ด เลิกใช้แล้ว ("ไม่เวิค · เข้า Profile มาแล้วต้องรู้ว่ามีการ์ด") และลองมาแล้วที่ไม่ผ่าน:
// - เวทีการ์ดใหญ่บนสุด → "โครตแปลก · หน้านี้เน้นกรอกข้อมูล ข้อมูลหายไปหมด"
// - แถวแยกที่ย้อมพื้นด้วยสีการ์ดเบลอ → สีเข้มกลายเป็นม่วงน้ำตาลหม่น + กล่องขอบเหลืองสองก้อนแย่งกัน ("นี่สวยละหรอ")
// ตอนนี้: Star Card เป็นหมวดสุดท้ายในการ์ดข้อมูลใบเดิม (แบบเดียวกับหมวด "ช่องทาง") — วัตถุชิ้นเดียว วัสดุเดียวกับหน้า
// สีของการ์ดอยู่แค่ในรูปย่อที่คมชัด ไม่ย้อมอะไรรอบข้าง · แตะ = เปิดแบบที่แบรนด์เห็น (Profile preview)

/**
 * รูปนิ่งของการ์ดใบจริง — อบครั้งเดียว ไม่สร้าง widget สดบนหน้านี้ทุกครั้ง
 * Android: วาดพรีวิวจริงหนึ่งรอบลง `GraphicsLayer` ที่ไม่ขึ้นจอ แล้วเก็บเป็น `ImageBitmap` (แทน `ImageRenderer`)
 */
object StarCardImage {
    private val cache = mutableMapOf<String, ImageBitmap>()

    /** รุ่นของรูป — การ์ดถูกแก้ หรือข้อมูลที่ widget วาด (โปรไฟล์ · รูป · ผลงาน) เปลี่ยน = อบใหม่ */
    fun key(record: CardRecord, photos: PhotoStore?): String =
        "${record.id}-${record.updatedAt}-${Profile.me.revision}-${photos?.profileRevision ?: 0}-${Portfolio.shared.revision}"

    fun cached(key: String): ImageBitmap? = cache[key]

    fun store(key: String, image: ImageBitmap) { cache[key] = image }

    /** รอรูปตั้งต้นให้มาก่อน ไม่งั้นอบช่องว่างติดไปในรูป */
    suspend fun preload() {
        coroutineScope {
            (0 until PhotoLib.count).map { i -> async { ImageCache.shared.load(PhotoLib.url(i)) } }.awaitAll()
        }
    }

    /** ขนาดที่อบ (หน่วยจอ) — พอร์ตกว้าง 300 · สตอรี่สูง 220 (เท่า iOS) */
    fun bakeSize(format: CardFormat): androidx.compose.ui.geometry.Size = when (format) {
        CardFormat.portfolio -> {
            val g = CardTemplate.thumbGutter
            val p = CardTemplate.previewPageSize(CardFormat.portfolio)
            val w = 300f
            androidx.compose.ui.geometry.Size(w, w * (p.height + g * 2) / (p.width * 3 + g * 2 + g * 2))
        }
        CardFormat.story -> {
            val p = CardTemplate.previewPageSize(CardFormat.story)
            val h = 220f
            androidx.compose.ui.geometry.Size(h * p.width / p.height, h)
        }
    }
}

/**
 * หมวด "Star Card" ท้ายการ์ดข้อมูล — หัว "ST★R *Card*" + รูปย่อตามแนวจริงติดป้าย "กำลังแสดงอยู่" + ปุ่ม ดูการ์ด + ไอคอนแชร์
 * ไม่มีชื่อการ์ด (ผู้ใช้ 24 ก.ย. 2569: "ดูการ์ด แชร์การ์ดต้องมี ชื่อไม่ต้องมี") · ดูการ์ด/แตะรูป = หน้า Star Card ของฉัน
 * - isDefault: การ์ดตั้งต้นที่ทุกคนมี — ยังไม่เปิดใช้: ป้าย "รอคุณเปิด" · ไม่มีแชร์ · ปุ่มชวนเข้าไปดู
 * - published: ยังไม่ได้เป็น STAR = การ์ดยังไม่ได้แสดงให้ใครเห็น — ไม่ขึ้นป้าย "กำลังแสดงอยู่" และไม่มีปุ่มแชร์ (audit 29 ก.ย. 2569)
 * - onInsight: ปุ่มเล็กใต้ปุ่ม "ดูการ์ด" (ไอคอนกราฟ + ยอดวิว) → หน้า ST★R Insight · null = ไม่มีปุ่ม (เฉพาะใบที่เผยแพร่แล้ว)
 * - onPickTemplate: ยังไม่เคยเปิดการ์ด: โชว์ `ActivateTease` แทนแถวรูปย่อ · null = ใช้หน้าตาเดิม (รูปย่อ + ปุ่ม)
 */
@Composable
fun StarCardSection(
    record: CardRecord,
    isDefault: Boolean = false,
    published: Boolean = true,
    onOpen: () -> Unit,
    onInsight: (() -> Unit)? = null,
    onPickTemplate: ((CardTemplate) -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val photos = LocalPhotoStore.current
    val invocation = LocalClipInvocation.current
    val context = LocalContext.current
    val key = StarCardImage.key(record, photos)
    var image by remember(key) { mutableStateOf(StarCardImage.cached(key)) }

    Column(
        modifier
            .fillMaxWidth()
            .topHairline(GL.ink.opacity(0.08))
            .padding(top = 10.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        // หัวหมวด = หัวหน้าย่อส่วน: ตรา ST★R + "Card" serif เอียงไล่หมึก→ทอง (ตราแทนคำ Star ตั้งแต่ 30 ก.ย. 2569)
        Row(horizontalArrangement = Arrangement.spacedBy(StarCaps.gapForSerif(22f).dp)) {
            StarCaps(height = StarCaps.heightForSerif(22f), color = GL.ink, modifier = Modifier.alignByBaseline())
            BasicText(
                "Card", Modifier.alignByBaseline(),
                style = GL.serif(22f).copy(brush = Brush.verticalGradient(listOf(GL.ink, GL.ink, GL.goldInk))),
                maxLines = 1, softWrap = false,
            )
            if (isDefault) {
                Text(
                    if (onPickTemplate != null) "รอคุณเปิดใช้งาน" else "ของคุณพร้อมแล้ว · เปิดดูได้เลย",
                    style = sh(12f), color = GL.muted, maxLines = 1, softWrap = false,
                    modifier = Modifier.padding(start = 4.dp).alignByBaseline(),
                )
            }
        }
        if (isDefault && onPickTemplate != null) {
            // ยังไม่เคยเปิดการ์ด = โชว์แบบให้ดูก่อน: พัด 3 ใบค่อย ๆ เปลี่ยน แตะใบไหนก็เริ่มจากใบนั้น (feedback 5 ต.ค. 2569)
            // เคยเปิดแล้ว = แถวเดิม (รูปย่อใบที่แสดงอยู่ + ดูการ์ด + แชร์ + ยอดวิว)
            ActivateTease(onOpen = onOpen)
        } else {
            Row(
                Modifier.padding(top = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(
                    Modifier.dockPress {
                        Haptics.impact(Haptics.Style.light)
                        onOpen()
                    },
                ) {
                    CardThumbnail(record = record, key = key, image = image, isDefault = isDefault, published = published, onBaked = { image = it })
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    // ดูการ์ด = ปุ่มหลักของหมวด · แชร์ = ไอคอนเล็กข้าง ๆ (ผู้ใช้ 24 ก.ย. 2569: "ความสำคัญเท่ากันเลยหรอ")
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                        SectionPill(
                            if (isDefault) "เปิดการ์ดของฉัน" else "ดูการ์ด",
                            if (isDefault) Ph.sparkle else Ph.eye,
                            dark = isDefault, action = onOpen, modifier = Modifier.weight(1f),
                        )
                        if (!isDefault && published) {
                            Box(
                                Modifier
                                    .semantics { contentDescription = "แชร์การ์ด" }
                                    .dockPress {
                                        Haptics.impact(Haptics.Style.light)
                                        ShareSheet.present(context, CardLibrary.shared.url(record, slug = invocation.slug))
                                    }
                                    .size(36.dp)
                                    .background(Color.White.opacity(0.85), CircleShape)
                                    .border(1.dp, GL.ink.opacity(0.1), CircleShape),
                                contentAlignment = Alignment.Center,
                            ) {
                                PIcon(Ph.shareNetwork, size = 15f, weight = PhWeight.bold, tint = GL.ink)
                            }
                        }
                    }
                    // ยอดวิว → ST★R Insight อยู่ใต้ปุ่มดูการ์ด (ผู้ใช้ 4 ต.ค. 2569: "ปุ่มไว้ข้างล่างดู card")
                    if (onInsight != null && published && !isDefault) InsightChip(onOpen = onInsight)
                }
            }
        }
    }
}

/** สูงเท่ากันทุกใบ กว้างตามแนว — แนวนอนเป็นแถบกว้าง แนวตั้งเป็นแผ่นแคบ */
@Composable
private fun CardThumbnail(
    record: CardRecord,
    key: String,
    image: ImageBitmap?,
    isDefault: Boolean,
    published: Boolean,
    onBaked: (ImageBitmap) -> Unit,
) {
    val thumbW = if (record.format == CardFormat.portfolio) 116f else 40f
    val thumbH = 70f
    val shown by animateFloatAsState(if (image != null) 1f else 0f, Motion.settle.float, label = "thumbIn")
    Box(Modifier.size(thumbW.dp, thumbH.dp), contentAlignment = Alignment.Center) {
        if (image == null) {
            Box(Modifier.size(thumbW.dp, thumbH.dp).background(GL.ink.opacity(0.06), RoundedCornerShape(6.dp)))
            StarCardBake(record = record, key = key, onBaked = onBaked)
        } else {
            val bake = StarCardImage.bakeSize(record.format)
            val fit = minOf(thumbW / bake.width, thumbH / bake.height)
            val w = bake.width * fit
            val h = bake.height * fit
            Image(
                image, contentDescription = null, contentScale = ContentScale.Fit,
                modifier = Modifier
                    .size(w.dp, h.dp)
                    .graphicsLayer { alpha = shown.coerceIn(0f, 1f) }
                    .glShadow(GL.ink.opacity(0.18), 5f, 3f, corner = 14f * fit),
            )
        }
        // ป้ายเดียวกับใบที่เผยแพร่อยู่ในคลัง — เกาะมุมซ้ายบนของรูป (การ์ดตั้งต้น = จุดทอง "รอคุณเปิด")
        if (isDefault || published) {
            Row(
                Modifier
                    .align(Alignment.TopStart)
                    .offset((-5).dp, (-9).dp)
                    .wrapContentSize(unbounded = true, align = Alignment.TopStart)
                    .height(18.dp)
                    .background(Color.Black.opacity(0.62), CircleShape)
                    .border(0.6.dp, Color.White.opacity(0.25), CircleShape)
                    .padding(horizontal = 7.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.size(5.dp).background(if (isDefault) GL.gold else SHColor.success, CircleShape))
                Text(
                    if (isDefault) "รอคุณเปิด" else "กำลังแสดงอยู่",
                    style = sh(9.5f, SHFont.bold), color = Color.White, maxLines = 1, softWrap = false,
                )
            }
        }
    }
}

/**
 * อบรูปย่อ — วาดพรีวิวจริงลงเลเยอร์ที่ไม่ขึ้นจอ (ไม่กินที่ในผัง) รอให้รูปตั้งต้นโหลดครบแล้วค่อยถ่ายเป็นรูปนิ่ง
 * (= `StarCardImage.bake` ที่ใช้ `ImageRenderer`)
 */
@Composable
private fun StarCardBake(record: CardRecord, key: String, onBaked: (ImageBitmap) -> Unit) {
    val restored = remember(record.snapshot) { CardStore.restore(record.snapshot) } ?: return
    var ready by remember(key) { mutableStateOf(false) }
    val layer = rememberGraphicsLayer()
    LaunchedEffect(key) {
        StarCardImage.preload()
        ready = true
    }
    if (!ready) return
    val bake = StarCardImage.bakeSize(record.format)
    Box(Modifier.size(0.dp)) {
        Box(
            Modifier
                .wrapContentSize(unbounded = true, align = Alignment.TopStart)
                .requiredSize(bake.width.dp, bake.height.dp)
                // บันทึกลงเลเยอร์อย่างเดียว ไม่วาดขึ้นจอ
                .drawWithContent { layer.record { this@drawWithContent.drawContent() } },
        ) {
            when (record.format) {
                CardFormat.portfolio -> CardStripPreview(
                    pages = restored.pages, theme = restored.theme, width = bake.width, showsDividers = false,
                    gutter = CardTemplate.thumbGutter, margin = CardTemplate.thumbGutter, cornerRadius = 14f,
                )
                CardFormat.story -> CardFramePreview(
                    page = restored.pages.firstOrNull() ?: CardPage(), theme = restored.theme,
                    pageSize = CardTemplate.previewPageSize(CardFormat.story), height = bake.height, cornerRadius = 14f,
                )
            }
        }
    }
    LaunchedEffect(key, ready) {
        // ให้พรีวิวได้วาดครบสักสองสามเฟรม (รูปในแคชขึ้นแล้ว) ก่อนถ่าย
        repeat(3) { withFrameNanos { } }
        delay(250)
        val bmp = runCatching { layer.toImageBitmap() }.getOrNull() ?: return@LaunchedEffect
        StarCardImage.store(key, bmp)
        onBaked(bmp)
    }
}

@Composable
private fun SectionPill(title: String, icon: Ph, dark: Boolean, action: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier
            .dockPress {
                Haptics.impact(Haptics.Style.light)
                action()
            }
            .height(36.dp)
            .clip(CircleShape)
            .background(if (dark) GL.ink else Color.White.opacity(0.85))
            .border(1.dp, if (dark) Color.Transparent else GL.ink.opacity(0.1), CircleShape),
        horizontalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PIcon(icon, size = 14f, weight = PhWeight.bold, tint = if (dark) Color.White else GL.ink)
        Text(title, style = sh(13.5f, SHFont.bold), color = if (dark) Color.White else GL.ink)
    }
}

/**
 * การ์ดที่ยังไม่ได้เปิดใช้งาน — โชว์แบบการ์ดให้ดูเฉย ๆ เป็นพัด 3 ใบ ค่อย ๆ เปลี่ยน แล้วมีปุ่ม "เปิดใช้งาน" (= `ActivateTease`)
 *
 * พัด 3 ใบ (ใบหน้า + ใบซ้อนหลังสองใบ) โชว์ทีละชุด แนวเดียวกันทั้งชุด — ชุดแนวตั้ง (Story) สลับกับชุดแนวนอน (Portfolio)
 * เปลี่ยนชุด = จางสลับทั้งพัด 0.75 วิ ค้าง 2.6 วิ · ชุดที่ซ่อนอยู่เลื่อนแบบของตัวเองไปหนึ่งใบระหว่างที่มองไม่เห็น
 * พัดลอยขึ้นลงเบา ๆ · ใบหน้าเอียงซ้ายขวาช้า ๆ · แสงกวาดผ่านใบหน้านาน ๆ ครั้ง · พัดกางออกตอนชุดใหม่จางเข้า · เงาพื้นหายใจตามการลอย
 * ปุ่มขาวนิ่ง · แตะการ์ดหรือปุ่ม = เปิด Star Card ตาม flow เดิม
 */
@Composable
private fun ActivateTease(onOpen: () -> Unit) {
    val talls = remember { CardTemplate.all(CardFormat.story) }
    val wides = remember { CardTemplate.all(CardFormat.portfolio) }
    var showWide by remember { mutableStateOf(false) }
    var tall by remember { mutableIntStateOf(0) }
    var wide by remember { mutableIntStateOf(0) }
    /** 0 = ชุดแนวตั้งโชว์ · 1 = ชุดแนวนอนโชว์ — จางสลับ 0.75 วิ */
    val swap = remember { Animatable(0f) }
    /** เวลา (วินาที) สำหรับท่าเอียง/แสงกวาด */
    var t by remember { mutableFloatStateOf(0f) }

    val animate = talls.isNotEmpty() && wides.isNotEmpty()
    // ลอยขึ้นลง 2.8 วิ ไป-กลับ (= `float` toggle กับ easeInOut.repeatForever)
    val floatT by rememberInfiniteTransition(label = "teaseFloat").animateFloat(
        0f, 1f, infiniteRepeatable(tween(2800, easing = EaseInOut), RepeatMode.Reverse), label = "float",
    )
    LaunchedEffect(animate) {
        if (!animate) return@LaunchedEffect
        launch {
            val start = withFrameNanos { it }
            while (true) withFrameNanos { now -> t = (now - start) / 1_000_000_000f }
        }
        while (true) {
            delay(2600)
            showWide = !showWide
            launch { swap.animateTo(if (showWide) 1f else 0f, tween(750, easing = EaseInOut)) }
            // รอให้จางสลับจบ แล้วเลื่อนแบบของชุดที่เพิ่งถูกซ่อน (มองไม่เห็นตอนเปลี่ยน)
            delay(850)
            if (showWide) tall = (tall + 1) % talls.size else wide = (wide + 1) % wides.size
        }
    }

    val tallOn = !(showWide && wides.isNotEmpty())
    val wideOn = showWide || talls.isEmpty()
    val floatY = 3f + (-4f - 3f) * (if (animate) floatT else 0f)

    Column(Modifier.fillMaxWidth().padding(top = 4.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Box(
            Modifier
                .fillMaxWidth()
                .height(226.dp)
                .semantics { contentDescription = "Star Card ยังไม่ได้เปิดใช้งาน ตัวอย่างแบบการ์ดแนวตั้งและแนวนอน" }
                .dockPress {
                    Haptics.impact(Haptics.Style.medium)
                    onOpen()
                }
                .graphicsLayer { translationY = floatY * density },
            contentAlignment = Alignment.Center,
        ) {
            // เงาพื้นหายใจตามการลอย
            Box(
                Modifier
                    .offset(y = 106.dp)
                    .graphicsLayer { scaleX = 1.04f + (0.9f - 1.04f) * (if (animate) floatT else 0f) }
                    .size(190.dp, 18.dp)
                    .blur(10.dp, BlurredEdgeTreatment.Unbounded)
                    .background(GL.ink.opacity(0.05), CircleShape),
            )
            if (talls.isNotEmpty()) {
                val k = if (animate) 1f - swap.value else 1f
                TeaseFan(
                    list = talls, front = tall, w = 110f, h = 196f,
                    backs = listOf(FanBack(-44f, 10f, -11f, 0.86f), FanBack(42f, 8f, 9f, 0.9f)),
                    spread = 0.5f + 0.5f * k, t = t, sweepOn = tallOn,
                    modifier = Modifier.graphicsLayer { alpha = k; val s = 0.95f + 0.05f * k; scaleX = s; scaleY = s },
                )
            }
            if (wides.isNotEmpty()) {
                val k = if (animate) swap.value else 1f
                TeaseFan(
                    list = wides, front = wide, w = 232f, h = 128f,
                    backs = listOf(FanBack(-22f, 22f, -7f, 0.9f), FanBack(22f, -20f, 6f, 0.93f)),
                    spread = 0.5f + 0.5f * k, t = t, sweepOn = wideOn,
                    modifier = Modifier.graphicsLayer { alpha = k; val s = 0.95f + 0.05f * k; scaleX = s; scaleY = s },
                )
            }
        }

        Row(
            Modifier
                .fillMaxWidth()
                .dockPress {
                    Haptics.impact(Haptics.Style.medium)
                    onOpen()
                }
                .height(46.dp)
                .background(Color.White, CircleShape)
                .border(1.dp, GL.ink.opacity(0.14), CircleShape),
            horizontalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PIcon(Ph.sparkle, size = 15f, weight = PhWeight.bold, tint = GL.ink)
            Text("เปิดใช้งาน", style = sh(15f, SHFont.bold), color = GL.ink)
        }
    }
}

/** ใบซ้อนหลัง: (x, y, องศา, สเกล) ไกลสุดก่อน */
private data class FanBack(val x: Float, val y: Float, val deg: Float, val scale: Float)

/**
 * พัดแนวเดียว 3 ใบ: ใบซ้อนหลังสองใบ (แบบถัด ๆ ไป วนซ้ำถ้ามีไม่ถึงสาม) + ใบหน้า
 * `spread` 1 = ชุดนี้กำลังโชว์ (ใบหลังกางเต็ม) · 0.5 = หุบเข้าหาใบหน้า แล้วกางออกตอนจางเข้า
 */
@Composable
private fun TeaseFan(
    list: List<CardTemplate>,
    front: Int,
    w: Float,
    h: Float,
    backs: List<FanBack>,
    spread: Float,
    t: Float,
    sweepOn: Boolean,
    modifier: Modifier = Modifier,
) {
    val sway = sin(t * 0.7f)
    val sweep = (t % 3.4f) / 3.4f
    Box(modifier, contentAlignment = Alignment.Center) {
        backs.forEachIndexed { k, b ->
            val sign = if (b.deg < 0f) -1f else 1f
            TeaseFace(
                list[(front + backs.size - k) % list.size], w, h,
                // ใบหลังมืดลงนิด (= `.brightness(-0.03 × ลำดับ)`)
                dim = 0.03f * (backs.size - k),
                modifier = Modifier
                    .graphicsLayer {
                        translationX = (b.x * spread - sway * 2f) * density
                        translationY = (b.y * spread) * density
                        rotationZ = b.deg * spread - sway * 1.3f * sign
                        scaleX = b.scale; scaleY = b.scale
                    }
                    .glShadow(GL.ink.opacity(0.11), 6f, 4f, corner = 12f),
            )
        }
        TeaseFace(
            list[front % list.size], w, h,
            sweep = if (sweepOn && sweep < 0.18f) (sweep / 0.18f).coerceAtMost(1f) else null,
            modifier = Modifier
                .graphicsLayer {
                    rotationY = sway * 5f
                    rotationX = sway * 5f * 0.15f
                    cameraDistance = 12f * density
                }
                .glShadow(GL.ink.opacity(0.18), 12f, 9f, corner = 12f)
                .border(1.dp, Color.White.opacity(0.85), RoundedCornerShape(12.dp)),
        )
    }
}

/** หน้าการ์ดหนึ่งใบในพัด — รูปอบของเทมเพลต (ไม่มี = หมึกจาง) · `sweep` = ตำแหน่งแสงกวาด 0…1 (null = ไม่มีแสง) */
@Composable
private fun TeaseFace(template: CardTemplate, w: Float, h: Float, dim: Float = 0f, sweep: Float? = null, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(12.dp)
    val bitmap = remember(template.id) { TemplateThumbs.shared.image(template.id)?.asImageBitmap() }
    Box(modifier.size(w.dp, h.dp).clip(shape).background(GL.ink.opacity(0.08))) {
        if (bitmap != null) {
            Image(bitmap, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
        }
        if (dim > 0f) Box(Modifier.fillMaxSize().background(Color.Black.opacity(dim)))
        if (sweep != null) {
            // แสงกวาดผ่านใบหน้านาน ๆ ครั้ง: แถบขาวโปร่ง 0.2 กว้าง 40% เอียง 18° วิ่งจากซ้ายไปขวา (= `.blendMode(.plusLighter)`)
            Canvas(Modifier.fillMaxSize()) {
                val bw = size.width * 0.4f
                val x = -size.width + size.width * 2f * sweep
                rotate(18f) {
                    drawRect(
                        Brush.horizontalGradient(listOf(Color.Transparent, Color.White.opacity(0.2), Color.Transparent), startX = x, endX = x + bw),
                        topLeft = Offset(x, -size.height), size = Size(bw, size.height * 3f),
                        blendMode = BlendMode.Plus,
                    )
                }
            }
        }
    }
}

/** แผ่นแชร์ของระบบ (= `UIActivityViewController`) — Android ใช้ `ACTION_SEND` + ตัวเลือกแอป */
object ShareSheet {
    fun present(context: Context, url: String) {
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, url)
        }
        val chooser = Intent.createChooser(send, null)
        if (context !is android.app.Activity) chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        runCatching { context.startActivity(chooser) }
    }
}
