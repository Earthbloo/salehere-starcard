package co.salehere.starcard.ui.widgets

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.LruCache
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.rememberSeconds
import co.salehere.starcard.components.scrubVeil
import co.salehere.starcard.model.AudienceInsight
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.LocalPopSkin
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.VerifiedWork
import co.salehere.starcard.model.WidgetFamily
import co.salehere.starcard.model.WidgetKind
import co.salehere.starcard.model.contract
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.BrandIcon
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.Tinted
import co.salehere.starcard.theme.hsb
import co.salehere.starcard.theme.onLightSurface
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.theme.statNumber
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalPreviewStatic
import co.salehere.starcard.ui.LocalSampleData
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.dataValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import java.net.HttpURLConnection
import java.net.URL
import kotlin.math.max
import kotlin.math.min

// MARK: - Photos (= Views/Widgets/WidgetShared.swift)

/**
 * คลังรูปประกอบ — โหลดจาก Mock URL ของ SaleHere
 * วันที่ต่อ ImageKit จริง แทนที่แค่ object นี้จุดเดียว
 */
object PhotoLib {
    /** รูปโปรไฟล์ครีเอเตอร์ (star) */
    const val profile = "https://img.salehere.co.th/p/1200x0/2025/12/12/profilecreator0jpeg-cjhwjffusbti.jpg"
    /** รูปผลงาน (review) */
    val works = listOf(
        "https://img.salehere.co.th/p/600x0/2026/07/12/reviewtopic0jpeg-oosenzv18wzj.jpg",
        "https://img.salehere.co.th/p/600x0/2025/09/21/reviewtopic0jpeg-ope9b0rviyjx.jpg",
        "https://img.salehere.co.th/p/600x0/2025/10/15/reviewtopic0jpeg-xqf0qpdhwb6j.jpg",
    )

    const val count = 12

    /** ช่องรูปครีเอเตอร์ (1–3) — รูปโปรไฟล์ที่อัปโหลดจากหน้า "ข้อมูลของฉัน" จะมาแทนช่องพวกนี้ */
    fun isProfileSlot(i: Int): Boolean = (i % count) in 1..3

    /** index 1–3 = รูปครีเอเตอร์ (hero/avatar/polaroid) · ที่เหลือวนรูปผลงาน */
    fun url(i: Int): String {
        val n = i % count
        return if (n in 1..3) profile else works[n % works.size]
    }
}

/**
 * แคชรูปจาก Mock URL — โหลดครั้งเดียวแล้วใช้ร่วมกันทุกที่ (การ์ดจริง · พรีวิวใน gallery · thumb)
 * ไม่ใช้ Coil เพราะ `cached(url)` ต้องตอบทันทีแบบ synchronous — view ที่เกิดใหม่กลางอนิเมชันจะได้ไม่ค้างเป็นแผ่นเปล่า
 * โหลดใน scope ของตัวเอง — view ที่รอถูกถอดไปก็ไม่ทำให้การโหลดล้ม
 */
class ImageCache private constructor() {
    companion object {
        val shared: ImageCache by lazy { ImageCache() }
        /** ด้านยาวสูงสุดที่เก็บในแคช — รูปต้นทาง 1200px ไม่ต้องใหญ่กว่านี้บนการ์ด */
        private const val longSide = 1600
    }

    private val cache = object : LruCache<String, Bitmap>(64 * 1024 * 1024) {
        override fun sizeOf(key: String, value: Bitmap): Int = value.byteCount
    }
    private val inflight = HashMap<String, Deferred<Bitmap?>>()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    fun cached(url: String): Bitmap? = cache.get(url)

    suspend fun load(url: String): Bitmap? {
        cached(url)?.let { return it }
        val task = synchronized(inflight) {
            inflight.getOrPut(url) {
                scope.async {
                    val bmp = cached(url) ?: fetch(url)
                    if (bmp != null) cache.put(url, bmp)
                    synchronized(inflight) { inflight.remove(url) }
                    bmp
                }
            }
        }
        return task.await()
    }

    /** ลองสองรอบ — เน็ตสะดุดครั้งเดียวไม่ควรทำให้พรีวิวค้างสถานะล้มถาวร */
    private fun fetch(url: String): Bitmap? {
        repeat(2) {
            try {
                val conn = URL(url).openConnection() as HttpURLConnection
                conn.connectTimeout = 10_000
                conn.readTimeout = 15_000
                conn.instanceFollowRedirects = true
                val decoded = conn.inputStream.use { BitmapFactory.decodeStream(it) }
                conn.disconnect()
                if (decoded != null) return shrink(decoded)
            } catch (_: Exception) {
            }
        }
        return null
    }

    private fun shrink(b: Bitmap): Bitmap {
        val long = max(b.width, b.height)
        if (long <= longSide) return b
        val k = longSide.toFloat() / long
        val out = Bitmap.createScaledBitmap(b, max(1, (b.width * k).toInt()), max(1, (b.height * k).toInt()), true)
        if (out !== b) b.recycle()
        return out
    }
}

/** โลโก้จาก Mock URL — fit บนแผ่นขาว · ระหว่างโหลดปล่อยว่างให้แผ่นขาวเป็น placeholder */
@Composable
fun RemoteLogo(url: String, modifier: Modifier = Modifier) {
    // เช็คแคชตั้งแต่เกิด — view ที่ถูกสร้างใหม่กลางอนิเมชันวน (เช่นรางโลโก้) จะได้ไม่ค้างเป็นแผ่นเปล่า
    var ui by remember(url) { mutableStateOf(ImageCache.shared.cached(url)) }
    LaunchedEffect(url) {
        if (ui == null) ui = ImageCache.shared.load(url)
    }
    val bmp = ui
    if (bmp != null) {
        Image(bmp.asImageBitmap(), contentDescription = null, modifier = modifier.fillMaxSize(), contentScale = ContentScale.Fit)
    } else {
        Box(modifier.fillMaxSize())
    }
}

/** รูปจาก Mock URL — เต็มกรอบที่ถูกเสนอเสมอ ผู้เรียกเป็นคน clip เอง */
@Composable
fun RemotePhoto(url: String, modifier: Modifier = Modifier) {
    val ink = LocalCardInk.current
    var ui by remember(url) { mutableStateOf(ImageCache.shared.cached(url)) }
    LaunchedEffect(url) {
        if (ui == null) ui = ImageCache.shared.load(url)
    }
    val bmp = ui
    Box(modifier.fillMaxSize()) {
        if (bmp != null) {
            Image(bmp.asImageBitmap(), contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
        } else {
            // ช่องว่างระหว่างโหลด — พื้นมืดใช้ขาวจาง พื้นกระดาษต้องใช้หมึกจาง ไม่งั้นช่องรูปหายไปกับพื้น
            // แถบแสงกวาดบอกว่า "กำลังมา" — วิ่งเฉพาะระหว่างโหลด พอรูปมาก็ดับตัวเอง
            val previewStatic = LocalPreviewStatic.current
            val clock = rememberSeconds(!previewStatic)
            val t = ((clock % 1.4) / 1.4).toFloat()
            val fill = ink.fill(0.09)
            val sweep = ink.fill(0.1)
            Box(
                Modifier
                    .fillMaxSize()
                    .background(fill)
                    .clipToBounds()
                    .drawBehind {
                        val w = size.width
                        val bw = w * 0.7f
                        val x = w * (t * 2f - 1f)
                        drawRect(
                            Brush.horizontalGradient(listOf(Color.Transparent, sweep, Color.Transparent), startX = x, endX = x + bw),
                            topLeft = Offset(x, 0f),
                            size = Size(bw, size.height),
                        )
                    },
            )
        }
    }
}

/** กระเบื้องรูปหนึ่งช่อง — จัดการ crop + ขอบ + scrim ไว้ที่เดียว */
@Composable
fun PhotoTile(
    index: Int,
    radius: Float = 10f,
    scrim: Boolean = false,
    badge: String? = null,
    modifier: Modifier = Modifier,
) {
    val ink = LocalCardInk.current
    val shape = RoundedCornerShape(radius.dp)
    val store = LocalPhotoStore.current
    val wid = LocalWidgetID.current
    Box(
        modifier
            .fillMaxSize()
            .photoSlot(index)
            .border(0.5.dp, ink.line(0.13), shape)
            .clip(shape),
    ) {
        if (store != null) {
            // การจัดวางในกรอบ (ซูม/เลื่อน) ไม่แตะเลย์เอาต์ — เปลี่ยนแค่ *ตำแหน่งที่วาด* (= `WidgetPhoto`)
            val f = store.fit(index, wid)
            store.image(
                index, wid,
                Modifier.fillMaxSize().graphicsLayer {
                    scaleX = f.zoom
                    scaleY = f.zoom
                    translationX = f.dx * size.width
                    translationY = f.dy * size.height
                },
            )
        } else {
            RemotePhoto(PhotoLib.url(index), Modifier.fillMaxSize())
        }
        if (scrim) {
            Box(
                Modifier
                    .fillMaxSize()
                    .background(Brush.verticalGradient(0.5f to Color.Transparent, 1f to Color.Black.opacity(0.55))),
            )
        }
        if (badge != null) {
            Box(Modifier.align(Alignment.BottomStart).padding(7.dp)) {
                Tinted(Color.White.opacity(0.95)) {
                    Row(
                        Modifier
                            .background(Color.Black.opacity(0.42), CircleShape)
                            .padding(horizontal = 6.dp, vertical = 3.dp),
                        horizontalArrangement = Arrangement.spacedBy(3.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        SFSymbol("play.fill", size = 7f)
                        Text(badge, style = sh(9f, SHFont.semibold), maxLines = 1, softWrap = false)
                    }
                }
            }
        }
    }
}

/**
 * ยอดบันทึกกับยอดแชร์ของผลงานหนึ่งชิ้น — **ไอคอนแทนคำ**
 * คำกินความกว้างเกือบเท่ายอดวิวทั้งที่เป็นบรรทัดรอง · ไอคอนกินที่หนึ่งในสี่และคนรุ่นนี้อ่านออกโดยไม่ต้องมีคำ
 * สองค่านี้ต้องมีครบทุกแบบในชั้นหลักฐาน — บันทึก/แชร์บอกว่า "คนเห็นแล้วทำอะไรต่อ"
 */
@Composable
fun WorkDeepStats(
    work: VerifiedWork,
    size: Float = 9f,
    tint: Color,
    lead: Double = 0.22,
    modifier: Modifier = Modifier,
) {
    val scrub = LocalPageScrub.current
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
        DeepStat("bookmark.fill", work.saves, 0, size, tint, lead, scrub.d)
        DeepStat("arrowshape.turn.up.right.fill", work.shares, 1, size, tint, lead, scrub.d)
        Spacer(Modifier.weight(1f, fill = false))
    }
}

@Composable
private fun DeepStat(icon: String, value: Int, i: Int, size: Float, tint: Color, lead: Double, d: Float) {
    Row(
        Modifier
            .wrapContentSize()
            .scrubVeil(d, lead = lead + i * 0.05, drop = 16f, pull = 10f),
        horizontalArrangement = Arrangement.spacedBy(3.5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        SFSymbol(icon, size = size * 0.92f, tint = tint)
        Text(
            Fmt.compact(value),
            style = sh(size, SHFont.bold),
            color = tint,
            maxLines = 1,
            softWrap = false,
            autoSize = TextAutoSize.StepBased(minFontSize = (size * 0.65f).sp, maxFontSize = size.sp, stepSize = 0.5.sp),
            modifier = Modifier.dataValue(),
        )
    }
}

// MARK: - Dispatcher

/**
 * แผ่นโปสเตอร์สีธีม — **สูตรเดียวของทั้งตู้**
 * ใบที่เป็น "แผ่นพิมพ์" วาดแผ่นของตัวเอง — สีจึงต้องมาจากที่นี่ที่เดียว ไม่งั้นการ์ดใบเดียวมีแผ่นสองเฉดที่ไม่ตรงกัน
 * **เฉดมาจากสีที่เจ้าของการ์ดเลือก** (`backdropHue`) ส่วนความสด/ความสว่างถูกตรึงไว้ที่ค่าของ *แผ่นพิมพ์*
 */
object PosterPlate {
    /** แผ่นเข้มอิ่มสีตามเฉดของการ์ด — คู่สีมีสีเข้มของมันเองอยู่แล้ว */
    fun plate(theme: CardTheme): Color = theme.duoDark ?: hsb(theme.backdropHue, 0.60, 0.255)

    /** ครีมที่อมเฉดเดียวกับแผ่น — ขาวสนิทบนแผ่นเข้มอ่านเป็นตัวอักษรของระบบ ไม่ใช่หมึกของงาน */
    fun cream(theme: CardTheme): Color = theme.duoLight ?: hsb(theme.backdropHue, 0.085, 0.95)
}

/**
 * แผ่นที่จัดหน้ามาแล้ว — **พื้นเต็มกรอบเสมอ ทุกเคส ไม่มีข้อยกเว้น**
 *
 * - **สเกล** (`k`) มาจากแกนที่คับที่สุด — ของข้างในจึงไม่ถูกบีบสักแกน
 * - **ผัง** (`size`) ยืดในหน่วยออกแบบจนคูณ `k` แล้วเท่ากรอบเป๊ะ *ทั้งสองแกน*
 * ผลคือ `box.width * k == frame.width` และ `box.height * k == frame.height` เสมอ — แผ่นเต็มกรอบทุกกรณี
 * ส่วนที่ได้เพิ่มมาเป็น *พื้นที่ของผัง* ที่ใบนั้นเอาไปกระจายเอง ไม่ใช่รูปที่ถูกดึงให้ยาว
 * - design: ขนาดอ้างอิงของผัง — ความกว้าง/สูงต่ำสุดในหน่วยออกแบบ
 * - frame: กรอบจริงที่ชิ้นนี้ได้รับ (`WidgetBody.size`)
 * - content: รับผังในหน่วยออกแบบที่ยืดแล้ว — ใบนั้นต้องวาดให้เต็มขนาดนี้ ไม่ใช่เต็ม `design`
 */
@Composable
fun PosterSheet(
    design: Size,
    frame: Size,
    modifier: Modifier = Modifier,
    content: @Composable (Size) -> Unit,
) {
    val fw = max(frame.width, 1f)
    val fh = max(frame.height, 1f)
    val k = max(min(fw / max(design.width, 1f), fh / max(design.height, 1f)), 0.01f)
    val box = Size(max(design.width, fw / k), max(design.height, fh / k))
    Box(modifier.requiredSize(fw.dp, fh.dp), contentAlignment = Alignment.TopStart) {
        Box(
            Modifier
                // ผังใหญ่กว่ากรอบได้ (ก่อนย่อ) — ต้องวัดแบบไม่จำกัดแล้วเกาะมุมบนซ้าย ไม่ใช่ถูกจับไปไว้กลาง
                .wrapContentSize(Alignment.TopStart, unbounded = true)
                .graphicsLayer {
                    scaleX = k
                    scaleY = k
                    transformOrigin = TransformOrigin(0f, 0f)
                }
                .requiredSize(box.width.dp, box.height.dp),
            contentAlignment = Alignment.TopStart,
        ) {
            content(box)
        }
    }
}

/** ผู้ชมยังว่างเปล่า (= `AudienceInsight.isEmpty` ใน Profile.swift) — คิดจากฟิลด์ตรง ๆ */
private fun audienceIsEmpty(a: AudienceInsight): Boolean =
    a.ages.isEmpty() && a.places.isEmpty() && a.female + a.male + a.other == 0.0

/**
 * ตัวจ่ายงานของตู้ — เลือกใบตามชนิด · ส่งสีเน้นและวัสดุลงไปทาง CompositionLocal
 *
 * หมึกที่ใช้คือของ *พื้นที่ชิ้นนี้นั่งอยู่จริง* ไม่ใช่ของการ์ดทั้งใบ (ดู `WidgetChrome`)
 * ตระกูลที่ต้องใช้ข้อมูลจากระบบหรือข้อมูลที่ยังไม่ได้กรอก — ว่าง = บอกตรง ๆ ไม่วาดของปลอม
 * ตู้ widget (`LocalSampleData`) วาดใบเต็ม ๆ ด้วยข้อมูลตัวอย่างเสมอ ไม่ขึ้นป้ายรอกรอกแทนใบ
 */
@Composable
fun WidgetBody(kind: WidgetKind, theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val ink = LocalCardInk.current
    val sampleOK = LocalSampleData.current

    val pending: String? = if (sampleOK) null else {
        val c = Profile.me.creator
        val sample = Profile.me.sampleFamilies
        // เว้นวรรคเมื่อชื่อแหล่งขึ้นต้นด้วยตัวละติน ("รอ OAuth …") — ตัวไทยติดกันได้ ("รอประวัติแคมเปญ…")
        val src = kind.family.contract.source.raw
        val source = if (src.firstOrNull()?.let { it.code < 128 } == true) " $src" else src
        when (kind.family) {
            WidgetFamily.brand -> if (c.track.brands.isEmpty()) "แบรนด์ที่เคยร่วมงาน — รอ$source" else null
            WidgetFamily.verified -> if (c.track.works.isEmpty()) "ผลงานยืนยัน — รอ$source" else null
            WidgetFamily.audience -> if (audienceIsEmpty(c.audience)) "ข้อมูลผู้ชม — รอ$source" else null
            WidgetFamily.followers -> if (WidgetFamily.followers in sample) "ยังไม่ใส่ช่องทาง — กรอกใน Star Profile" else null
            WidgetFamily.rate -> if (WidgetFamily.rate in sample) "ยังไม่ตั้งเรท — กรอกใน Star Profile" else null
            else -> null
        }
    }

    CompositionLocalProvider(
        // สีเน้นคิดจากพื้นที่ชิ้นนี้นั่งอยู่ ไม่ใช่จากหมึกของการ์ด — บนแผ่นเข้มทึบที่วางบนการ์ดกระดาษ
        // สีเน้นแบบ "ย้อมให้เข้มพอสำหรับพื้นขาว" จะจมหายไปกับแผ่น ต้องใช้ตัวดิบที่จูนมาสำหรับพื้นมืด
        LocalCardAccent provides (if (ink.isLight) theme.rawAccent.onLightSurface() else theme.rawAccent),
        // วัสดุของแผ่นสติกเกอร์ — ชิ้นส่วนร่วมอยู่ลึกหลายชั้น ส่งทาง CompositionLocal แล้วทั้งกิ่งได้พร้อมกัน
        LocalPopSkin provides kind.popSkin,
    ) {
        Box(modifier.fillMaxSize(), contentAlignment = Alignment.TopStart) {
            if (pending != null) {
                SystemPending(text = pending, family = kind.family)
            } else {
                when (kind) {
                    WidgetKind.artPortrait -> ArtPortrait(theme, size)
                    WidgetKind.artTypeOver -> ArtTypeOver(theme, size)
                    WidgetKind.artNameBehind -> ArtNameBehind(theme, size)
                    WidgetKind.artBreakout -> ArtBreakout(theme, size)
                    WidgetKind.artPortfolio -> ArtPortfolioPoster(theme, size)
                    WidgetKind.artPolaroid -> ArtPolaroid(theme)
                    WidgetKind.heroMinimal -> HeroMinimal(theme, size)
                    WidgetKind.aboutText -> AboutText(theme)
                    WidgetKind.interestTags -> InterestTags(theme)
                    WidgetKind.proofBrandGrid -> ProofBrandGrid(theme)
                    WidgetKind.proofBrandRail -> ProofBrandRail(theme)
                    WidgetKind.proofBrandCoins -> ProofBrandCoins(theme)
                    WidgetKind.proofWork -> ProofWork(theme)
                    WidgetKind.proofTicket -> ProofTicket(theme)
                    WidgetKind.statGiant -> StatGiant(theme, size)
                    WidgetKind.socialChips -> SocialChips(theme, size.width)
                    WidgetKind.socialTiles -> SocialTiles(theme, size.width)
                    // โปสเตอร์ผู้ติดตาม — ผังของมันเป็น *แผ่น* จึงรับขนาดเต็มไปคำนวณเองทั้งใบ
                    WidgetKind.statPoster -> StatPosterWidget(theme, size)
                    WidgetKind.artFilmstrip -> ArtFilmstrip(theme)
                    WidgetKind.artDuo -> ArtDuo(theme)
                    WidgetKind.artPair -> ArtPair(theme)
                    WidgetKind.workFeatured -> WorkFeatured(theme)
                    WidgetKind.workReel -> WorkReel(theme)
                    // สำรับกองรูป
                    WidgetKind.galleryStack -> GalleryStack(theme)
                    WidgetKind.galleryCarousel -> GalleryCarousel(theme)
                    WidgetKind.galleryMasonry -> GalleryMasonry(theme)
                    WidgetKind.galleryMosaic -> GalleryMosaic(theme)
                    WidgetKind.galleryPost -> GalleryPost(theme)
                    WidgetKind.galleryStory -> GalleryStory(theme)
                    WidgetKind.galleryFilm -> GalleryFilm(theme)
                    WidgetKind.galleryTape -> GalleryTape(theme)
                    // แผ่นโชว์คลิป
                    WidgetKind.reelShowcase -> ReelShowcase(theme, size)
                    WidgetKind.typeMarquee -> TypeMarquee(theme)
                    WidgetKind.typeQuote -> TypeQuote(theme, size)
                    WidgetKind.textBlock -> TextBlock(theme, size)
                    WidgetKind.nicheTags -> NicheTags(theme)
                    // โปสเตอร์สายงาน
                    WidgetKind.nichePoster -> NichePosterWidget(theme, size)
                    WidgetKind.heroAura -> HeroAura(theme, size)
                    WidgetKind.statWrapped -> StatWrapped(theme, size)
                    WidgetKind.artPhotobooth -> ArtPhotobooth(theme)
                    WidgetKind.stickerTags -> StickerTags(theme)
                    // สำรับรอบสอง — เรตราคาและช่องทางติดต่อ
                    WidgetKind.rateTags -> RateTagsWidget(theme)
                    WidgetKind.rateNeon -> RateNeonWidget(theme)
                    WidgetKind.contactCard -> ContactCardWidget(theme)
                    WidgetKind.contactQR -> ContactQRWidget(theme)
                    WidgetKind.contactBar -> ContactBarWidget(theme)
                    WidgetKind.contactStack -> ContactStackWidget(theme)
                    WidgetKind.contactLine -> ContactLineWidget(theme, size)
                    WidgetKind.contactChips -> ContactChipsWidget(theme)
                    // โปสเตอร์ติดต่อ
                    WidgetKind.contactPoster -> ContactPosterWidget(theme, size)
                    WidgetKind.proofSeal -> VerifiedSealWidget(theme, size)
                    // ประชากรผู้ติดตาม
                    WidgetKind.audienceLine -> AudienceLineWidget(theme, size)
                    WidgetKind.audienceSplit -> AudienceSplitWidget(theme)
                    WidgetKind.audienceAge -> AudienceAgeWidget(theme)
                    WidgetKind.audiencePoster -> InsightPosterWidget(theme, size)
                    WidgetKind.audienceMap -> AudienceMapWidget(theme)
                    // สำรับแผ่นสติกเกอร์ — วัสดุส่งลงไปทาง `LocalPopSkin`
                    WidgetKind.popHeroPaper, WidgetKind.popHeroGlass -> PopHero(theme, size)
                    WidgetKind.popVideoPaper, WidgetKind.popVideoGlass -> PopVideo(theme)
                    WidgetKind.popStatsGlass -> PopStats(theme)
                    WidgetKind.popWorkPaper, WidgetKind.popWorkGlass -> PopWork(theme)
                    WidgetKind.popRatePaper, WidgetKind.popRateGlass -> PopRate(theme)
                    WidgetKind.popNichePaper, WidgetKind.popNicheGlass -> PopNiche(theme)
                    WidgetKind.popBodyPaper, WidgetKind.popBodyGlass -> PopBody(theme)
                    WidgetKind.popContactPaper, WidgetKind.popContactGlass -> PopContact(theme)
                    // สำรับบรรณาธิการ
                    WidgetKind.wallPolaroid -> WallPolaroid(theme, size)
                    WidgetKind.wallMemory -> WallMemory(theme, size)
                    WidgetKind.zineCover -> ZineCover(theme, size)
                    WidgetKind.aboutEditorial -> AboutEditorial(theme, size)
                    WidgetKind.aboutBehind -> AboutBehind(theme, size)
                    WidgetKind.sayClarity -> SayClarity(theme, size)
                    WidgetKind.sayPitch -> SayPitch(theme, size)
                    WidgetKind.flowCards -> FlowCards(theme, size)
                }
            }
        }
    }
}

// MARK: - Shared parts

@Composable
fun AvatarOrb(theme: CardTheme, size: Float = 74f, usePhoto: Boolean = true, modifier: Modifier = Modifier) {
    val shadow = Color.Black.opacity(0.4)
    Box(
        modifier
            .size(size.dp)
            .shadow(12.dp, CircleShape, clip = false, ambientColor = shadow, spotColor = shadow)
            .border(1.dp, Color.White.opacity(0.3), CircleShape),
    ) {
        if (usePhoto) {
            RemotePhoto(PhotoLib.url(3), Modifier.fillMaxSize().clip(CircleShape))
        } else {
            Box(
                Modifier
                    .fillMaxSize()
                    .background(
                        Brush.linearGradient(listOf(theme.accentSoft, theme.accent), start = Offset.Zero, end = Offset.Infinite),
                        CircleShape,
                    ),
            )
        }
        Box(
            Modifier
                .fillMaxSize()
                .clip(CircleShape)
                .drawBehind {
                    drawCircle(
                        Brush.radialGradient(
                            listOf(Color.White.opacity(0.28), Color.Transparent),
                            center = Offset(this.size.width * 0.3f, this.size.height * 0.2f),
                            radius = this.size.width * 0.62f,
                        ),
                    )
                },
        )
    }
}

@Composable
fun StatColumn(
    value: String,
    label: String,
    /** null = ใช้สีหมึกของการ์ด */
    tint: Color? = null,
    compact: Boolean = false,
    modifier: Modifier = Modifier,
) {
    val ink = LocalCardInk.current
    val big = if (compact) 20f else 23f
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(2.dp), horizontalAlignment = Alignment.Start) {
        Text(
            value,
            style = statNumber(big),
            color = tint ?: ink.text(0.98),
            maxLines = 1,
            softWrap = false,
            autoSize = TextAutoSize.StepBased(minFontSize = (big * 0.55f).sp, maxFontSize = big.sp, stepSize = 0.5.sp),
            modifier = Modifier.dataValue(),
        )
        Text(
            label,
            style = sh(10f, SHFont.medium),
            color = ink.text(0.5),
            maxLines = 1,
            softWrap = false,
            autoSize = TextAutoSize.StepBased(minFontSize = (10f * 0.65f).sp, maxFontSize = 10.sp, stepSize = 0.5.sp),
        )
    }
}

/** ชิปตัวเลขผู้ติดตามเล็ก ๆ ที่ใช้ซ้ำในหลาย hero variant */
@Composable
fun FollowerPills(limit: Int = 3, modifier: Modifier = Modifier) {
    val ink = LocalCardInk.current
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(7.dp), verticalAlignment = Alignment.CenterVertically) {
        Profile.me.creator.socials.take(limit).forEach { s ->
            Tinted(ink.text(0.9)) {
                Row(
                    Modifier
                        .linkSlot(s.profileURL)
                        .background(ink.fill(0.14), CircleShape)
                        .border(0.5.dp, ink.line(0.16), CircleShape)
                        .padding(horizontal = 8.dp, vertical = 4.5.dp),
                    horizontalArrangement = Arrangement.spacedBy(5.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    BrandIcon(s.type.icon, size = 9.5f * 1.15f)
                    Text(
                        Fmt.compact(s.followerCount),
                        style = sh(11f, SHFont.bold),
                        maxLines = 1,
                        softWrap = false,
                        modifier = Modifier.dataValue(),
                    )
                }
            }
        }
        Spacer(Modifier.weight(1f, fill = false))
    }
}

// MARK: - ช่องที่รอข้อมูล

/**
 * แทนที่ widget ทั้งชิ้นเมื่อข้อมูลของตระกูลนั้นยังไม่มี — กรอบประ ไอคอน และบอกว่ารออะไร
 * (ไม่วาดเลข 0 หรือแบรนด์ตัวอย่าง: การ์ดที่โชว์ของปลอมคือการ์ดโกหก)
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun SystemPending(text: String, family: WidgetFamily, modifier: Modifier = Modifier) {
    val ink = LocalCardInk.current
    val stroke = ink.text(0.18)
    Column(
        modifier
            .fillMaxSize()
            .drawBehind {
                val sw = 1.dp.toPx()
                val r = 14.dp.toPx()
                drawRoundRect(
                    stroke,
                    topLeft = Offset(sw / 2f, sw / 2f),
                    size = Size(size.width - sw, size.height - sw),
                    cornerRadius = CornerRadius(r, r),
                    style = Stroke(width = sw, pathEffect = PathEffect.dashPathEffect(floatArrayOf(5.dp.toPx(), 4.dp.toPx()))),
                )
            }
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        PIcon(Ph.hourglass, size = 16f, tint = ink.text(0.35))
        Text(
            text,
            style = sh(10.5f, SHFont.semibold),
            color = ink.text(0.45),
            textAlign = TextAlign.Center,
            maxLines = 3,
            overflow = TextOverflow.Ellipsis,
            autoSize = TextAutoSize.StepBased(minFontSize = (10.5f * 0.8f).sp, maxFontSize = 10.5.sp, stepSize = 0.5.sp),
        )
    }
}
