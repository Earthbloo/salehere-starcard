package co.salehere.starcard.ui.export

import android.content.ClipData
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.rememberGraphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import co.salehere.starcard.AppContext
import co.salehere.starcard.layout.PageLayout
import co.salehere.starcard.model.CardFormat
import co.salehere.starcard.model.CardPage
import co.salehere.starcard.model.Profile
import co.salehere.starcard.theme.CardBackdrop
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.SaleHereMarkColors
import co.salehere.starcard.theme.Signature
import co.salehere.starcard.theme.SignatureEmboss
import co.salehere.starcard.theme.SignaturePattern
import co.salehere.starcard.theme.StarLockup
import co.salehere.starcard.theme.StripStyle
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalPageContentWidth
import co.salehere.starcard.ui.LocalPreviewStatic
import co.salehere.starcard.ui.LocalTextEditMode
import co.salehere.starcard.ui.editor.LocalSlotRegistry
import co.salehere.starcard.ui.glowShadow
import co.salehere.starcard.ui.widgets.ImageCache
import co.salehere.starcard.ui.widgets.PhotoLib
import co.salehere.starcard.ui.widgets.QRCode
import co.salehere.starcard.ui.widgets.VerifiedSeal
import co.salehere.starcard.ui.widgets.WidgetChrome
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/**
 * รูปที่ส่งออกจากการ์ด — "ฉบับเดินทาง": การ์ดวางบนเวทีของ Sale Here พร้อมแถบ QR (= `CardExport`)
 *
 * รูปที่ถูกแชร์คือจุดที่การ์ดอยู่ **ห่างจากแพลตฟอร์มที่สุด** — ฉบับเดินทางจึงมีสามอย่างที่ตัวการ์ดไม่มี:
 * เวทีที่มีลายน้ำ · แถบ QR ที่พากลับมาที่การ์ด · ตรา STAR · ตัวการ์ดข้างบนไม่ถูกแตะเลย
 *
 * * `.story` — 1080×1920 เสมอ · `.portfolio` — แถบ 3 หน้าบนเวที กว้างตามหน้า × 3 บวกขอบ
 *
 * Android ไม่มี `ImageRenderer` — วาดผ่าน `CardExport.Renderer` (composable นอกจอ) ลง `GraphicsLayer`
 * แล้ว `toImageBitmap()` · ไฟล์เขียนลง `cacheDir/export/` และแชร์ผ่าน `FileProvider`
 */
object CardExport {
    /** พื้นที่ออกแบบกว้าง 540pt และปลายทางคือ 1080px — สเกลจึงเป็น 2 พอดีสำหรับสตอรี่ */
    const val pixelWidth: Float = 1080f

    /** ผังของฉบับเดินทาง — ตัวเลขทั้งหมดในหน่วยออกแบบ */
    data class Travel(
        /** ขนาดผืนทั้งหมด */
        val canvas: Size,
        /** กรอบของตัวการ์ด (หลังย่อ) บนผืน */
        val card: Rect,
        /** สัดส่วนที่ย่อการ์ดลง */
        val scale: Float,
        /** กรอบของแถบ QR */
        val band: Rect,
        /** มุมของการ์ดบนเวที */
        val radius: Float,
    )

    /**
     * สตอรี่: ผืน 540×960 ตายตัว การ์ดลอยกลาง เว้นหัวท้ายให้พ้นแถบ UI ของ Instagram พอประมาณ
     * พอร์ต: ผืนกว้างเท่าแถบ 3 หน้าบวกขอบ สูงเท่าหน้าบวกแถบ QR
     */
    fun travel(pageSize: Size, format: CardFormat): Travel {
        val sheet = Size(pageSize.width * format.pageCount, pageSize.height)
        return when (format) {
            CardFormat.story -> {
                // ผืนสตอรี่ = ขนาดหน้าเป๊ะ ๆ — ทุก pt ที่ยกให้เวทีคือ pt ที่หายไปจากเนื้อการ์ด
                val canvas = Size(540f, 960f)
                val side = 12f
                val top = 12f
                val gap = 10f
                val bandH = 64f
                val bottom = 12f
                val box = Size(canvas.width - side * 2, canvas.height - top - gap - bandH - bottom)
                val s = min(box.width / max(sheet.width, 1f), box.height / max(sheet.height, 1f))
                val card = Size(sheet.width * s, sheet.height * s)
                val rect = Rect(Offset((canvas.width - card.width) / 2f, top + (box.height - card.height) / 2f), card)
                val band = Rect(Offset(rect.left, rect.bottom + gap), Size(card.width, bandH))
                Travel(canvas = canvas, card = rect, scale = s, band = band, radius = 26f * s)
            }
            CardFormat.portfolio -> {
                val s = 0.94f
                val card = Size(sheet.width * s, sheet.height * s)
                val margin = 28f
                // สูงพอให้ "Verified by Sale Here" อ่านออกตอนมองทั้งรูป — พอร์ตกว้างกว่าพันพอยต์ แถบ 64 เหลือเป็นเส้น
                val bandH = 112f
                val canvas = Size(card.width + margin * 2, margin + card.height + 16f + bandH + margin)
                val rect = Rect(Offset(margin, margin), card)
                val band = Rect(Offset(margin, rect.bottom + 16f), Size(card.width, bandH))
                Travel(canvas = canvas, card = rect, scale = s, band = band, radius = 22f * s)
            }
        }
    }

    /** สเกลของการเรนเดอร์ (พิกเซลต่อหน่วยออกแบบ) — คำนวณย้อนจากพิกเซลปลายทาง ไม่ใช่ตั้งเป็นค่าคงที่ */
    @Suppress("UNUSED_PARAMETER")
    fun scale(pageSize: Size, format: CardFormat): Float {
        if (pageSize.width <= 1f) return 2f
        return pixelWidth / pageSize.width
    }

    /**
     * ขนาดหน้าที่ใช้เรนเดอร์ — ปกติคือขนาดที่ผู้ใช้แต่งจริง
     * ที่ต้องมีทางสำรอง เพราะขนาดหน้ายังเป็นศูนย์อยู่หนึ่งเฟรมแรก ถ้าเผลอเรนเดอร์ตอนนั้นจะได้รูปเปล่า
     */
    fun resolvedPageSize(size: Size, format: CardFormat = CardFormat.portfolio): Size {
        if (size.width > 1f && size.height > 1f) return size
        val dm = AppContext.app.resources.displayMetrics
        val screen = Size(dm.widthPixels / dm.density, dm.heightPixels / dm.density)
        val box = Size(screen.width, max(screen.height - 74f - 34f, 1f))
        return format.pageSize(box)
    }

    /** รอรูปตั้งต้นและโลโก้แบรนด์ให้ครบก่อนเรนเดอร์ — รูปที่ยังไม่มาจะกลายเป็นช่องว่างติดไฟล์ */
    suspend fun preload() {
        val urls = LinkedHashSet<String>()
        for (i in 0 until PhotoLib.count) urls += PhotoLib.url(i)
        for (brand in Profile.me.creator.track.brands) brand.logo?.let { urls += it }
        coroutineScope { urls.map { u -> async { ImageCache.shared.load(u) } }.awaitAll() }
    }

    /**
     * เขียน JPEG ลงโฟลเดอร์ชั่วคราว (= `jpegFile`) — ชื่อไฟล์แยกตามแบบ ไม่งั้นสองแบบเขียนทับกัน
     * คืน null เมื่อเขียนไม่สำเร็จ · เรียกนอกเธรดหลัก
     */
    fun jpegFile(image: Bitmap, slug: String, format: CardFormat = CardFormat.portfolio): File? = runCatching {
        val dir = File(AppContext.app.cacheDir, "export").apply { mkdirs() }
        val file = File(dir, "StarCard-$slug-${format.raw}.jpg")
        FileOutputStream(file).use { out ->
            if (!image.compress(Bitmap.CompressFormat.JPEG, 92, out)) error("encode failed")
        }
        file
    }.getOrNull()

    /** เปิดชีตแชร์ของระบบพร้อมไฟล์รูป (= `ShareLink(item: fileURL, preview:)`) */
    fun share(context: Context, file: File, title: String) {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "image/jpeg"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TITLE, title)
            clipData = ClipData.newRawUri(title, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val chooser = Intent.createChooser(send, title)
        if (context !is android.app.Activity) chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        runCatching { context.startActivity(chooser) }
    }

    /**
     * เซฟลงคลังรูปตรง ๆ — API 29+ ไม่ต้องขอสิทธิ์ (MediaStore · Pictures/StarCard)
     * เครื่องเก่ากว่านั้นต้องมีสิทธิ์เขียน ถ้าไม่มีคืน false ให้หน้าโชว์คำเตือน · เรียกนอกเธรดหลัก
     */
    fun saveToPhotos(context: Context, image: Bitmap, slug: String, format: CardFormat = CardFormat.portfolio): Boolean =
        runCatching {
            val resolver = context.contentResolver
            val name = "StarCard-$slug-${format.raw}-${System.currentTimeMillis()}.jpg"
            if (Build.VERSION.SDK_INT >= 29) {
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, name)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                    put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/StarCard")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }
                val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return@runCatching false
                val ok = resolver.openOutputStream(uri)?.use { image.compress(Bitmap.CompressFormat.JPEG, 92, it) } ?: false
                if (!ok) {
                    resolver.delete(uri, null, null)
                    return@runCatching false
                }
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                true
            } else {
                @Suppress("DEPRECATION")
                MediaStore.Images.Media.insertImage(resolver, image, name, null) != null
            }
        }.getOrDefault(false)

    /**
     * ตัวเรนเดอร์นอกจอ (= `CardExport.render`) — ประกอบฉบับเดินทางที่ความละเอียดปลายทาง
     * บันทึกลง `GraphicsLayer` (ไม่วาดบนจอ ไม่กินที่ในผัง) แล้วส่งรูปกลับทาง `onImage` ครั้งเดียว
     * รูปที่ได้เป็น ARGB_8888 ธรรมดา (บีบเป็น JPEG ได้) · null = เรนเดอร์ไม่สำเร็จ
     */
    @Composable
    fun Renderer(
        pages: List<CardPage>,
        theme: CardTheme,
        pageSize: Size,
        slug: String,
        format: CardFormat = CardFormat.portfolio,
        onImage: (Bitmap?) -> Unit,
    ) {
        val size = resolvedPageSize(pageSize, format)
        val t = travel(size, format)
        val k = scale(size, format)
        val layer = rememberGraphicsLayer()
        val deliver by rememberUpdatedState(onImage)
        var ready by remember { mutableStateOf(false) }
        val recorded = remember { BooleanArray(1) }

        LaunchedEffect(Unit) {
            runCatching { preload() }
            ready = true
        }
        if (!ready) return

        Box(
            Modifier
                .layout { measurable, _ ->
                    val w = ceil(t.canvas.width * k).toInt()
                    val h = ceil(t.canvas.height * k).toInt()
                    val p = measurable.measure(Constraints.fixed(w, h))
                    // ไม่กินที่ในผังของหน้า — วาดลงเลเยอร์อย่างเดียว
                    layout(0, 0) { p.place(0, 0) }
                }
                .drawWithContent {
                    layer.record { this@drawWithContent.drawContent() }
                    recorded[0] = true
                },
        ) {
            // หนึ่งหน่วยออกแบบ = k พิกเซล — ไม่มีการย่อ/ขยายซ้ำ ตัวหนังสือจึงคม
            CompositionLocalProvider(LocalDensity provides Density(k, 1f)) {
                ExportLocals {
                    TravelSheet(pages = pages, theme = theme, pageSize = size, format = format, slug = slug, travel = t)
                }
            }
        }

        LaunchedEffect(Unit) {
            // รอให้ผังนิ่งและรูปจากแคชถูกวาดครบก่อนถ่าย
            var frames = 0
            while (!recorded[0] && frames < 120) { withFrameNanos { }; frames++ }
            repeat(3) { withFrameNanos { } }
            delay(350)
            val bmp = runCatching {
                val shot = layer.toImageBitmap().asAndroidBitmap()
                withContext(Dispatchers.Default) {
                    if (shot.config == Bitmap.Config.ARGB_8888 && shot.isMutable) shot
                    else shot.copy(Bitmap.Config.ARGB_8888, false)
                }
            }.getOrNull()
            deliver(bmp)
        }
    }
}

/** ฉบับเดินทางทั้งผืน — เวที · การ์ด · แถบ QR */
@Composable
private fun TravelSheet(
    pages: List<CardPage>,
    theme: CardTheme,
    pageSize: Size,
    format: CardFormat,
    slug: String,
    travel: CardExport.Travel,
) {
    val t = travel
    val accent = theme.rawAccent
    Box(
        Modifier
            .size(t.canvas.width.dp, t.canvas.height.dp)
            .clipToBounds()
            .background(Signature.stage),
    ) {
        // เวที — มืดอมม่วง ลายน้ำจาง และแสงของสีธีมจาง ๆ ด้านบนให้การ์ดไม่ลอยอยู่ในความว่าง
        SignaturePattern(opacity = 0.08, scale = 0.34f)
        Box(
            Modifier.matchParentSize().drawBehind {
                drawRect(
                    Brush.radialGradient(
                        listOf(accent.opacity(0.22), Color.Transparent),
                        center = Offset(size.width * 0.5f, size.height * 0.12f),
                        radius = max(1f, size.width * 0.9f),
                    ),
                )
            },
        )

        // เงาของการ์ดวาดบนแผ่นทึบ **ใต้** การ์ด ไม่ใช่บนตัวการ์ด — การ์ดหมึกสว่างจะไม่มีวงดำล้อมทุกกล่อง
        Box(
            Modifier
                .offset(t.card.left.dp, t.card.top.dp)
                .size(t.card.width.dp, t.card.height.dp)
                .glowShadow(Color.Black.opacity(0.55), 26f, 14f, t.radius)
                .background(Signature.stage, RoundedCornerShape(t.radius.dp)),
        )

        Box(
            Modifier
                .offset(t.card.left.dp, t.card.top.dp)
                .size(t.card.width.dp, t.card.height.dp),
        ) {
            Box(
                Modifier
                    .wrapContentSize(Alignment.TopStart, unbounded = true)
                    .requiredSize((pageSize.width * format.pageCount).dp, pageSize.height.dp)
                    .graphicsLayer {
                        scaleX = t.scale; scaleY = t.scale
                        transformOrigin = TransformOrigin(0f, 0f)
                    }
                    .clip(RoundedCornerShape((t.radius / t.scale).dp)),
            ) {
                CardSheet(pages = pages, theme = theme, pageSize = pageSize, format = format)
            }
        }

        TravelBand(
            slug = slug,
            modifier = Modifier
                .offset(t.band.left.dp, t.band.top.dp)
                .size(t.band.width.dp, t.band.height.dp),
        )
    }
}

/** ชนิดของก้อนขวาในแถบ (= `TravelBand.Mark`) */
object TravelBand {
    /** สามภาษาของ "ใครรับรอง" ที่ลองบนโต๊ะตรวจงาน */
    enum class Mark(val raw: String) {
        /** ป้าย VERIFIED BY SALE HERE **ตัวจริงของแอปหลัก** */
        pill("pill"),
        /** ป้ายเดียวกันแต่ขาวสีเดียว บนแคปซูลโปร่ง — กลืนกับเวทีของเรา */
        mono("mono"),
        /** ไวยากรณ์บัตรเครดิต — ตรา STAR แดงของแอป + บรรทัด VERIFIED เล็ก */
        lockup("lockup");

        companion object {
            fun from(raw: String?): Mark? = entries.firstOrNull { it.raw == raw }

            /** iOS อ่าน `-bandMark pill|mono|lockup` จาก launch argument — Android ไม่มี จึงเป็นค่าตั้งต้นเสมอ */
            val fromLaunch: Mark? get() = null
        }
    }
}

/**
 * แถบใต้การ์ดบนรูปที่ส่งออก — QR · ที่อยู่ · ตรา STAR
 * ดังได้ถึงขั้น 4 บนบันไดความดัง เพราะที่นี่ไม่มีโครงของเราช่วยบอก และไม่ได้อยู่บนตัวการ์ด
 */
@Composable
fun TravelBand(
    slug: String,
    mark: TravelBand.Mark = TravelBand.Mark.fromLaunch ?: TravelBand.Mark.pill,
    modifier: Modifier = Modifier,
) {
    BoxWithConstraints(modifier) {
        // ทุกขนาดคิดจากความสูงของแถบ — พอร์ตสามหน้ากว้างกว่าสตอรี่สองเท่า แถบของมันจึงสูงกว่า
        val k = maxHeight.value / 62f
        TravelBandBody(slug = slug, mark = mark, k = k)
    }
}

@Composable
private fun TravelBandBody(slug: String, mark: TravelBand.Mark, k: Float) {
    val verified = VerifiedFacts.current.verified
    val shape = RoundedCornerShape((18f * k).dp)
    Box(
        Modifier
            .fillMaxSize()
            .background(Color.White.opacity(0.07), shape)
            .border(0.7.dp, Color.White.opacity(0.12), shape),
    ) {
        Box(Modifier.matchParentSize().clip(shape)) {
            SignaturePattern(opacity = 0.08, scale = 0.22f)
        }
        Row(
            Modifier.fillMaxSize().padding(horizontal = (14f * k).dp),
            horizontalArrangement = Arrangement.spacedBy((13f * k).dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            QRCode(
                text = "https://${Signature.url(slug)}",
                modifier = Modifier
                    .size((46f * k).dp)
                    .background(Color.White, RoundedCornerShape((8f * k).dp))
                    .padding((4f * k).dp),
            )

            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy((3f * k).dp)) {
                // ไวยากรณ์เดียวกับ QR บนสลิปโอนเงิน — สแกนแล้วได้คำตอบว่าของจริงไหม
                Text(
                    if (verified) "สแกนเพื่อตรวจสอบ" else "สแกนดูการ์ดเต็ม",
                    style = sh(13f * k, SHFont.semibold),
                    color = Color.White,
                    maxLines = 1,
                    softWrap = false,
                )
                val mono = Signature.mono(9.5f * k).copy(letterSpacing = 0.3.sp)
                Text(
                    Signature.url(slug),
                    style = mono,
                    color = Color.White.opacity(0.66),
                    maxLines = 1,
                    softWrap = false,
                    autoSize = TextAutoSize.StepBased(
                        minFontSize = (9.5f * k * 0.7f).sp, maxFontSize = (9.5f * k).sp, stepSize = 0.25.sp,
                    ),
                )
            }

            Spacer(Modifier.width((8f * k).dp))
            // ขวาสุด — **ของชิ้นเดียว** ที่บอกว่าใครรับรอง (ผู้ใช้: สามชิ้นอัดกัน "โครตจะไม่สวย")
            BandTrailing(mark = mark, k = k, verified = verified)
        }
    }
}

@Composable
private fun BandTrailing(mark: TravelBand.Mark, k: Float, verified: Boolean) {
    when (mark) {
        TravelBand.Mark.pill -> {
            if (verified) {
                VerifiedPillImage(height = 36f * k, label = "Verified by Sale Here")
            } else {
                StarLockup(height = 28f * k, tint = SaleHereMarkColors.red)
            }
        }
        TravelBand.Mark.mono -> {
            val capsule = CircleShape
            Row(
                Modifier
                    .background(Color.White.opacity(0.10), capsule)
                    .border((0.8f * k).dp, Color.White.opacity(0.35), capsule)
                    .padding(start = (9f * k).dp, end = (13f * k).dp, top = (8f * k).dp, bottom = (8f * k).dp),
                horizontalArrangement = Arrangement.spacedBy((7f * k).dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                VerifiedSeal(radius = 8.5f * k, punch = Signature.stage, compact = true)
                Text(
                    if (verified) "VERIFIED BY SALE HERE" else "STAR CARD BY SALE HERE",
                    style = sh(10.5f * k, SHFont.heavy).copy(letterSpacing = (0.6f * k).sp),
                    color = Color.White,
                    maxLines = 1,
                    softWrap = false,
                )
            }
        }
        TravelBand.Mark.lockup -> {
            Row(horizontalArrangement = Arrangement.spacedBy((10f * k).dp), verticalAlignment = Alignment.CenterVertically) {
                if (verified) {
                    Row(horizontalArrangement = Arrangement.spacedBy((4f * k).dp), verticalAlignment = Alignment.CenterVertically) {
                        VerifiedSeal(radius = 6f * k, punch = Signature.stage, compact = true)
                        Text(
                            "VERIFIED",
                            style = Signature.mono(8f * k, SHFont.bold).copy(letterSpacing = (1.4f * k).sp),
                            color = Color.White.opacity(0.85),
                            maxLines = 1,
                            softWrap = false,
                        )
                    }
                }
                StarLockup(height = 32f * k, tint = SaleHereMarkColors.red)
            }
        }
    }
}

/** ป้าย VERIFIED BY SALE HERE ตัวจริง (PNG สีต้นฉบับ) สูงเท่านี้ กว้างตามสัดส่วนรูป */
@Composable
internal fun VerifiedPillImage(height: Float, label: String?, modifier: Modifier = Modifier) {
    val painter = painterResource(SHIcon.verifiedPill)
    val intrinsic = painter.intrinsicSize
    val ratio = if (intrinsic.width > 0f && intrinsic.height > 0f && intrinsic.width.isFinite()) intrinsic.width / intrinsic.height else 3.4f
    Image(
        painter = painter,
        contentDescription = label,
        contentScale = ContentScale.Fit,
        modifier = modifier.height(height.dp).aspectRatio(ratio),
    )
}

/** แผ่นการ์ดทั้งใบ — ฉากหลังผืนเดียว แล้ววางหน้าเรียงกันข้างบน (ใช้ทั้งฉบับเดินทางและพรีวิว) */
@Composable
fun CardSheet(
    pages: List<CardPage>,
    theme: CardTheme,
    pageSize: Size,
    format: CardFormat,
    modifier: Modifier = Modifier,
) {
    val blank = remember { CardPage() }
    Box(
        modifier
            .size((pageSize.width * format.pageCount).dp, pageSize.height.dp)
            .clipToBounds(),
    ) {
        CompositionLocalProvider(LocalCardInk provides theme.inkStyle) {
            CardBackdrop(theme = theme, ignoreSafeArea = false, signed = true)
            Row {
                for (i in 0 until format.pageCount) {
                    CardPageCanvas(page = pages.getOrNull(i) ?: blank, size = pageSize, theme = theme)
                }
            }
            // ตราปั๊มนูนกดลงบนแผ่นที่พิมพ์เสร็จแล้ว — เหนือ widget ทุกชิ้น (ดู `SignatureEmboss`)
            if (theme.strip.isStamp) {
                SignatureEmboss(
                    light = theme.inkStyle.isLight, foil = theme.strip == StripStyle.foil,
                    tint = theme.inkStyle.base, pages = pages, pageSize = pageSize,
                )
            }
        }
    }
}

/**
 * หนึ่งหน้าของการ์ดแบบนิ่ง — เฉพาะ widget ไม่มีฉากหลังของตัวเอง
 * พรีวิวในคลัง รูปเทมเพลต และรูปที่ส่งออก ผ่านตัวนี้ทั้งหมด สิ่งที่เห็นจึงตรงกับสิ่งที่ได้
 */
@Composable
fun CardPageCanvas(
    page: CardPage,
    size: Size,
    theme: CardTheme,
    modifier: Modifier = Modifier,
) {
    val solved = remember(page.items, size) { PageLayout.solve(page.items, size) }
    CompositionLocalProvider(
        LocalCardInk provides theme.inkStyle,
        LocalPageContentWidth provides PageLayout.content(size).width,
    ) {
        Box(modifier.size(size.width.dp, size.height.dp)) {
            for (p in solved) {
                key(p.id) {
                    WidgetChrome(
                        placed = p,
                        theme = theme,
                        modifier = Modifier.offset(p.frame.left.dp, p.frame.top.dp),
                    )
                }
            }
        }
    }
}

/** environment ของงานส่งออก — นิ่ง ไม่มีช่องให้แตะ (= `.transaction { $0.animation = nil }`) */
@Composable
internal fun ExportLocals(content: @Composable () -> Unit) {
    CompositionLocalProvider(
        LocalPreviewStatic provides true,
        LocalTextEditMode provides false,
        LocalSlotRegistry provides null,
        content = content,
    )
}
