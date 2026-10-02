package co.salehere.starcard.ui.salehere.starflow

import android.content.Context
import android.content.Intent
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
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
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.rememberGraphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
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
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.dockPress
import co.salehere.starcard.ui.widgets.ImageCache
import co.salehere.starcard.ui.widgets.PhotoLib
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay

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
 * หมวด "Star Card" ท้ายการ์ดข้อมูล — หัว "Star *Card*" + รูปย่อตามแนวจริงติดป้าย "กำลังแสดงอยู่" + ปุ่ม ดูการ์ด + ไอคอนแชร์
 * ไม่มีชื่อการ์ด (ผู้ใช้ 24 ก.ย. 2569: "ดูการ์ด แชร์การ์ดต้องมี ชื่อไม่ต้องมี") · ดูการ์ด/แตะรูป = หน้า Star Card ของฉัน
 */
@Composable
fun StarCardSection(record: CardRecord, onOpen: () -> Unit, modifier: Modifier = Modifier) {
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
        // หัวหมวด = หัวหน้าย่อส่วน: "Star" หนา + "Card" serif เอียงไล่หมึก→ทอง
        Row(horizontalArrangement = Arrangement.spacedBy(5.dp)) {
            Text(
                "Star", style = sh(17f, SHFont.heavy).copy(letterSpacing = (-0.4f).sp), color = GL.ink,
                modifier = Modifier.alignByBaseline(),
            )
            BasicText(
                "Card", Modifier.alignByBaseline(),
                style = GL.serif(22f).copy(brush = Brush.verticalGradient(listOf(GL.ink, GL.ink, GL.goldInk))),
                maxLines = 1, softWrap = false,
            )
        }
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
                CardThumbnail(record = record, key = key, image = image, onBaked = { image = it })
            }
            // ดูการ์ด = ปุ่มหลักของหมวด · แชร์ = ไอคอนเล็กข้าง ๆ (ผู้ใช้ 24 ก.ย. 2569: "ความสำคัญเท่ากันเลยหรอ")
            Row(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                SectionPill("ดูการ์ด", Ph.eye, dark = false, action = onOpen, modifier = Modifier.weight(1f))
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
    }
}

/** สูงเท่ากันทุกใบ กว้างตามแนว — แนวนอนเป็นแถบกว้าง แนวตั้งเป็นแผ่นแคบ */
@Composable
private fun CardThumbnail(record: CardRecord, key: String, image: ImageBitmap?, onBaked: (ImageBitmap) -> Unit) {
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
        // ป้ายเดียวกับใบที่เผยแพร่อยู่ในคลัง — เกาะมุมซ้ายบนของรูป
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
            Box(Modifier.size(5.dp).background(SHColor.success, CircleShape))
            Text("กำลังแสดงอยู่", style = sh(9.5f, SHFont.bold), color = Color.White, maxLines = 1, softWrap = false)
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
