package co.salehere.starcard.ui.widgets

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import co.salehere.starcard.R
import co.salehere.starcard.components.LocalPageScrub
import co.salehere.starcard.components.Scrub
import co.salehere.starcard.components.scrubDolly
import co.salehere.starcard.model.Brand
import co.salehere.starcard.model.CutoutCache
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.PhotoStore
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.SubjectLift
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.Signature
import co.salehere.starcard.theme.TextAlignment
import co.salehere.starcard.theme.TextFit
import co.salehere.starcard.theme.mixed
import co.salehere.starcard.theme.onLightSurface
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalSlotTilt
import co.salehere.starcard.ui.LocalTextEditMode
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import co.salehere.starcard.ui.editor.dataValue
import java.util.UUID
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

// MARK: - ชิ้นส่วนที่ใช้ข้ามไฟล์ของสำรับ widget
//
// Swift วางของพวกนี้ไว้ในไฟล์ของสำรับที่เกิดก่อน (AboutWidgets · EditorialWidgets · CutoutWidgets ·
// StatPosterWidget · BookingWidgets · VerifiedSealWidget · ProofWidgets) แล้วสำรับอื่นยืมไปใช้
// ฝั่ง Kotlin รวมไว้ที่นี่ไฟล์เดียว — ไฟล์ของแต่ละสำรับ **ห้ามประกาศชื่อเหล่านี้ซ้ำ**

// ============================================================================================
// AboutWidgets.swift — FlowLayout · FlowChips
// ============================================================================================

/** เรียงชิปซ้าย→ขวา แล้วขึ้นบรรทัดใหม่เมื่อชนขอบ (= `FlowLayout: Layout`) — ชิปกว้างไม่เท่ากัน กริดคอลัมน์ใช้ไม่ได้ */
@Composable
fun FlowLayout(spacing: Float = 6f, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Layout(content, modifier) { measurables, constraints ->
        val gap = (spacing * density).toInt()
        val maxW = if (constraints.hasBoundedWidth) constraints.maxWidth else Int.MAX_VALUE
        val placeables = measurables.map { it.measure(Constraints()) }
        var x = 0; var y = 0; var lineH = 0
        val spots = ArrayList<Pair<Int, Int>>(placeables.size)
        var widest = 0
        for (pl in placeables) {
            if (x > 0 && x + pl.width > maxW) { x = 0; y += lineH + gap; lineH = 0 }
            spots += x to y
            x += pl.width + gap
            widest = max(widest, x - gap)
            lineH = max(lineH, pl.height)
        }
        val w = if (maxW == Int.MAX_VALUE) widest else maxW
        layout(w.coerceAtLeast(constraints.minWidth), (y + lineH).coerceAtLeast(constraints.minHeight)) {
            placeables.forEachIndexed { i, pl -> pl.placeRelative(spots[i].first, spots[i].second) }
        }
    }
}

/** ชิปรายการที่ขึ้นบรรทัดเอง (= `FlowChips`) */
@Composable
fun FlowChips(items: List<String>, spacing: Float = 6f, modifier: Modifier = Modifier, chip: @Composable (String) -> Unit) {
    FlowLayout(spacing, modifier) { items.forEach { chip(it) } }
}

// ============================================================================================
// EditorialWidgets.swift — Ed · EdSkin · EdHalftone · EdText · EdPhoto · EdPlace · EdSelectionHandles
// (EdGrain อยู่ใน theme/CardTheme.kt)
// ============================================================================================

/** สีของสำรับบรรณาธิการ — กระดาษ หมึก หมุด ไฮไลต์ (= `enum Ed`) */
object Ed {
    val cream = rgb(0.961, 0.949, 0.929)
    val creamWarm = rgb(0.949, 0.918, 0.859)
    val paper = rgb(0.937, 0.933, 0.925)
    val beige = rgb(0.906, 0.886, 0.839)

    val ink = rgb(0.105, 0.105, 0.110)
    val inkSoft = rgb(0.365, 0.357, 0.345)
    val brown = rgb(0.239, 0.188, 0.161)
    val red = rgb(0.647, 0.161, 0.129)

    val marker = rgb(0.145, 0.290, 0.776)
    val pinRed = rgb(0.878, 0.192, 0.153)
    val pinYellow = rgb(0.965, 0.773, 0.094)
    val pinBlue = rgb(0.231, 0.510, 0.878)

    val highlightPink = rgb(0.906, 0.780, 0.855)
    val handlePink = rgb(0.788, 0.404, 0.639)
    val highlightIris = rgb(0.725, 0.725, 0.941)
    val handleIris = rgb(0.188, 0.208, 0.808)
    val stepPink = rgb(0.937, 0.827, 0.914)

    /**
     * ขนาดตัวอักษรที่ทำให้คำนี้กว้าง `width` พอดี — ไม่เกิน `cap` ไม่ต่ำกว่า `floor` (= `Ed.fitted`)
     * วัดด้วยหมึกจริงที่ขนาดทดลอง 100 แล้วเทียบบัญญัติไตรยางศ์ · ต้องส่งตัววัดจาก `TextFit.rememberMeasurer()`
     */
    fun fitted(measurer: TextMeasurer, text: String, weight: FontWeight, face: CardFont = CardFont.noto,
               width: Float, cap: Float, floor: Float = 10f): Float {
        val probe = 100f
        val w = TextFit.metrics(measurer, text, face, weight, probe, TextAlignment.center).ink.width
        if (w <= 1f) return cap
        return max(floor, min(cap, probe * width / w))
    }

    /**
     * วัสดุของใบตามพื้นผิวที่เลือก (= `Ed.skin`) — มีกระดาษ · กระจกของ chrome (`.pane`) · ไม่มีพื้น
     * คู่สี: แผ่นเป็นสีเข้มของคู่ · หมึกเป็นสีอ่อนของคู่ ไม่ใช่กระดาษครีมที่เป็นสีที่สาม
     */
    fun skin(surface: WidgetSurface, paper: Color, ink: InkStyle, theme: CardTheme? = null,
             ghostOnPaper: Color = Color.White): EdSkin {
        if (surface == WidgetSurface.pane) {
            val onGlass = theme?.accent
            return EdSkin(sheet = Color.Transparent, papered = true,
                ink = ink.text(0.95), inkSoft = ink.text(0.55), ghost = ink.ghost(0.14),
                marker = onGlass ?: marker, red = onGlass ?: red)
        }
        if (surface != WidgetSurface.clear) {
            if (theme != null && theme.activeDuo != null) {
                val plate = PosterPlate.plate(theme)
                val cream = PosterPlate.cream(theme)
                return EdSkin(sheet = plate, papered = true,
                    ink = cream, inkSoft = cream.mixed(plate, 0.38), ghost = cream.opacity(0.16),
                    marker = cream, red = cream)
            }
            val onPaper = theme?.rawAccent?.onLightSurface()
            return EdSkin(sheet = paper, papered = true, ink = this.ink, inkSoft = this.inkSoft,
                ghost = ghostOnPaper, marker = onPaper ?: marker, red = onPaper ?: red)
        }
        val light = ink.isLight
        val onCard = theme?.accent
        return EdSkin(sheet = Color.Transparent, papered = false,
            ink = ink.text(0.95), inkSoft = ink.text(0.6), ghost = ink.ghost(0.22),
            marker = onCard ?: (if (light) marker else rgb(0.573, 0.714, 1.0)),
            red = onCard ?: (if (light) red else rgb(0.980, 0.451, 0.376)))
    }
}

/** หมึกและพื้นของใบในสำรับบรรณาธิการ (= `EdSkin`) */
data class EdSkin(
    /** พื้นกระดาษของใบ — `Transparent` เมื่อปิดพื้น */
    val sheet: Color,
    /** ยังมีกระดาษรองอยู่ไหม — เกล็ดกระดาษ เงา และเส้นขอบอ่านค่านี้ก่อนวาด */
    val papered: Boolean,
    val ink: Color,
    val inkSoft: Color,
    val ghost: Color,
    val marker: Color,
    val red: Color,
)

/** จุดฮาล์ฟโทน — ตารางจุดบนปกซีน (= `EdHalftone`) */
@Composable
fun EdHalftone(step: Float = 5f, dot: Float = 1.5f, opacity: Double = 0.16, modifier: Modifier = Modifier) {
    Canvas(modifier.fillMaxSize()) {
        val st = step * density; val d = dot * density
        val c = Color.White.opacity(opacity)
        var y = 0f; var row = 0
        while (y < size.height) {
            var x = if (row % 2 == 0) 0f else st / 2
            while (x < size.width) {
                drawOval(c, topLeft = Offset(x, y), size = Size(d, d))
                x += st
            }
            y += st; row += 1
        }
    }
}

/**
 * ข้อความอิสระหนึ่งก้อนของสำรับบรรณาธิการ — ค่าตั้งต้นของดีไซน์ + ช่องแก้ที่ชั้นการ์ด (= `EdText`)
 * ถ้าเห็นตัวอักษรบนแผ่น แปลว่าแตะแล้วพิมพ์ทับได้เสมอ
 */
@Composable
fun EdText(slot: Int, preset: String, hint: String, style: TextSlotStyle, lines: Int = 1,
           minScale: Float = 0.62f, modifier: Modifier = Modifier) {
    val wid = LocalWidgetID.current
    EditableText(
        field = ProfileField.note, index = slot, widget = wid, preset = preset, hint = hint,
        style = style, text = Profile.me.note(wid, slot, preset),
        modifier = modifier, maxLines = lines, softWrap = lines > 1, autoSizeMin = minScale,
    )
}

/** ช่องรูปหนึ่งช่องของสำรับบรรณาธิการ — เต็มกรอบเสมอ · ขาวดำได้ · ประกาศช่องให้ปุ่มเปลี่ยนรูป (= `EdPhoto`) */
@Composable
fun EdPhoto(slot: Int, mono: Boolean = false, depth: Float = 10f, modifier: Modifier = Modifier) {
    val scrub = LocalPageScrub.current
    Box(modifier.clipToBounds().photoSlot(slot)) {
        Box(
            Modifier.fillMaxSize()
                .scrubDolly(scrub.d, shift = depth, zoom = 0.12f)
                .let { if (mono) it.grayscale() else it },
        ) { WidgetPhoto(slot, Modifier.fillMaxSize()) }
    }
}

/** ขาวดำทั้งชั้น (= `.grayscale(1)`) — วาดเนื้อหาลงเลเยอร์ที่มีฟิลเตอร์ลดความอิ่มสีเป็นศูนย์ */
fun Modifier.grayscale(): Modifier = this.drawWithContent {
    val paint = androidx.compose.ui.graphics.Paint().apply {
        colorFilter = ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0f) })
    }
    drawIntoCanvas { canvas ->
        canvas.saveLayer(androidx.compose.ui.geometry.Rect(0f, 0f, size.width, size.height), paint)
        drawContent()
        canvas.restore()
    }
}

/**
 * วางของหนึ่งชิ้นด้วยพิกัด **สัดส่วน** ของแผ่น (0…1) แล้วเอียงตามองศาที่ดีไซน์กำหนด (= `EdPlace`)
 * ส่งองศาลง `LocalSlotTilt` ด้วย — กรอบเส้นประของช่องข้อความข้างในจะได้เอียงตามแผ่น
 * ต้องวางใน `Box` ที่มีขนาด `size` (หน่วยออกแบบ)
 */
@Composable
fun EdPlace(x: Float, y: Float, w: Float, h: Float, size: Size, tilt: Double = 0.0,
            align: Alignment = Alignment.TopCenter, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    val bw = max(1f, w * size.width); val bh = max(1f, h * size.height)
    CompositionLocalProvider(LocalSlotTilt provides tilt) {
        Box(
            modifier
                .offset((x * size.width).dp, (y * size.height).dp)
                .size(bw.dp, bh.dp)
                .graphicsLayer { rotationZ = tilt.toFloat() },
            contentAlignment = align,
        ) { content() }
    }
}

/** หมุดจับของกล่องไฮไลต์ — เส้นตั้งที่ขอบกล่อง + จุดกลมที่ปลาย (= `EdSelectionHandles`) */
@Composable
fun EdSelectionHandles(tint: Color, dot: Float = 9f, line: Float = 1.4f, modifier: Modifier = Modifier) {
    Canvas(modifier.fillMaxSize()) {
        val l = line * density; val d = dot * density; val h = size.height
        // ซ้าย: เส้นเต็มสูง + จุดที่ปลายล่าง
        drawRect(tint, topLeft = Offset(0f, 0f), size = Size(l, h))
        drawCircle(tint, radius = d / 2, center = Offset(l / 2, h))
        // ขวา: เส้นเต็มสูง + จุดที่ปลายบน
        drawRect(tint, topLeft = Offset(size.width - l, 0f), size = Size(l, h))
        drawCircle(tint, radius = d / 2, center = Offset(size.width - l / 2, 0f))
    }
}

// ============================================================================================
// CutoutWidgets.swift — CutoutPlane · CutoutSample · cutoutPlane() · cutoutLifting() · CutoutSubject · CutoutStatus
// ============================================================================================

/** สิ่งที่ช่องรูปของตระกูลคัตเอาต์ได้มาจริง (= `enum CutoutPlane`) */
sealed class CutoutPlane {
    /** คนยืนอยู่บนการ์ด · `own` = รูปของเจ้าของการ์ดเอง (ไม่ใช่ตัวอย่างที่เราแถมให้ดูท่า) */
    data class Subject(val image: Bitmap, val own: Boolean) : CutoutPlane()
    /** รูปทึบ — กลับไปโหมดกรอบ **เงียบ ๆ** ไม่มีป้ายแดง ไม่มีข้อความเตือน */
    object Framed : CutoutPlane()

    val subject: Bitmap? get() = (this as? Subject)?.image
    val isSample: Boolean get() = this is Subject && !own
}

/** รูปตัวอย่างที่แถมมากับแอป — การ์ดเปล่าต้องโชว์ท่าคัตเอาต์ตั้งแต่วินาทีแรก (= `CutoutSample`) */
object CutoutSample {
    val image: Bitmap? by lazy {
        runCatching {
            BitmapFactory.decodeResource(co.salehere.starcard.AppContext.app.resources, R.drawable.cutout_sample)
        }.getOrNull()
    }
}

/**
 * `lift` = ชิ้นนี้ลบพื้นหลังให้เอง — รูปทึบถูกส่งเข้าตัวลบพื้นหลัง ระหว่างรอยังเป็นโหมดกรอบ (= `cutoutPlane`)
 * บน Android ตัวลบพื้นหลังยังเป็น stub — รูปทึบจึงเป็นโหมดกรอบเสมอ · PNG ใสยังเป็นคนยืนบนการ์ดได้
 */
fun cutoutPlane(store: PhotoStore, slot: Int, widget: UUID?, lift: Boolean = false): CutoutPlane {
    val ui = store.userImage(slot, widget)
        ?: return CutoutSample.image?.let { CutoutPlane.Subject(it, own = false) } ?: CutoutPlane.Framed
    val r = CutoutCache.shared.result(ui)
    if (r.isCutout) return CutoutPlane.Subject(r.image, own = true)
    if (!lift) return CutoutPlane.Framed
    val lifted = SubjectLift.shared.result(ui)
    if (lifted == null) {
        SubjectLift.shared.request(ui)
        return CutoutPlane.Framed
    }
    return if (lifted.isCutout) CutoutPlane.Subject(lifted.image, own = true) else CutoutPlane.Framed
}

/** ช่องนี้กำลังรอตัวลบพื้นหลังอยู่ไหม (= `cutoutLifting`) */
fun cutoutLifting(store: PhotoStore, slot: Int, widget: UUID?, lift: Boolean): Boolean {
    if (!lift) return false
    val ui = store.userImage(slot, widget) ?: return false
    return SubjectLift.shared.isRunning(ui)
}

/**
 * ตัวคนบนการ์ด — ไม่มี clip ไม่มีกรอบ มีแค่เงาที่บอกว่ามันลอยอยู่เหนือพื้น (= `CutoutSubject`)
 * กว้างคิดจากสัดส่วนของรูปเอง · จัดรูปของเจ้าของ (ช่อง 1) ซูมยึด **เท้า**
 * - drift: ระยะที่ตัวคนถ่วงตัวเวลาเลื่อนหน้า — ชั้นกลาง น้อยกว่าพื้นและหน้าเสมอ
 * - shadow: โปสเตอร์กระดาษไม่มีเงา ตัวคนถูก *พิมพ์ลงบนแผ่น*
 */
@Composable
fun CutoutSubject(image: Bitmap, height: Float, d: Float, drift: Float, shadow: Boolean = true,
                  modifier: Modifier = Modifier) {
    val store = LocalPhotoStore.current
    val wid = LocalWidgetID.current
    val ar = if (image.height > 0) image.width.toFloat() / image.height else 0.7f
    val width = height * ar
    val fit = store?.fit(1, wid) ?: co.salehere.starcard.model.PhotoFit.identity
    val t = Scrub.ease(Scrub.t(d))
    val s = Scrub.dir(d)
    val bmp = remember(image) { image.asImageBitmap() }
    Box(modifier.size(width.dp, height.dp)) {
        // เงาสองชั้น: ชั้นกว้างคือระยะห่างจากพื้น ชั้นแคบคือจุดที่เท้าแตะ
        if (shadow) {
            Canvas(Modifier.fillMaxSize().graphicsLayer { alpha = Scrub.fade(t, 0.86).toFloat() }) {
                val footY = size.height
                drawOval(
                    Brush.radialGradient(listOf(Color.Black.opacity(0.35), Color.Transparent),
                        center = Offset(size.width / 2, footY), radius = size.width * 0.45f),
                    topLeft = Offset(size.width * 0.05f, footY - size.width * 0.12f),
                    size = Size(size.width * 0.9f, size.width * 0.24f),
                )
            }
        }
        Image(
            bmp, contentDescription = null, contentScale = ContentScale.FillBounds,
            filterQuality = FilterQuality.High,
            modifier = Modifier.fillMaxSize().graphicsLayer {
                val z = fit.zoom * (1 - 0.04f * t)
                scaleX = z; scaleY = z
                transformOrigin = TransformOrigin(0.5f, 1f)
                translationX = (fit.dx * width + s * drift * t) * density
                translationY = fit.dy * height * density
                alpha = Scrub.fade(t, 0.86).toFloat()
            },
        )
    }
}

/** สถานะของช่องรูป — ป้ายบอกสถานะอย่างเดียว โผล่เฉพาะตอนแต่งการ์ด (= `CutoutStatus`) */
@Composable
fun CutoutStatus(plane: CutoutPlane, theme: CardTheme, lifting: Boolean = false, modifier: Modifier = Modifier) {
    val editing = LocalTextEditMode.current
    val good = plane is CutoutPlane.Subject && plane.own
    val label: String = when {
        lifting -> "กำลังลบพื้นหลัง…"
        plane is CutoutPlane.Subject && plane.own -> "พื้นหลังใส"
        plane is CutoutPlane.Subject -> "รูปตัวอย่าง"
        else -> "ใส่รูปพื้นหลังใสได้อีกแบบ"
    }
    if (!editing) return
    val icon = if (good) "checkmark" else if (lifting) "hourglass" else "sparkles"
    val fg = if (good) Color.Black.opacity(0.85) else Color.White.opacity(0.9)
    Row(
        modifier
            .background(if (good) theme.accent else Color.Black.opacity(0.55), CircleShape)
            .border(0.5.dp, Color.White.opacity(if (good) 0.0 else 0.22), CircleShape)
            .padding(horizontal = 7.dp, vertical = 3.5.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        SFSymbol(icon, size = 7.5f, tint = fg)
        Text(label, style = sh(8.5f, FontWeight.SemiBold), color = fg, maxLines = 1)
    }
}

// ============================================================================================
// StatPosterWidget.swift — StatPosterSkin
// ============================================================================================

/** วัสดุและหมึกของโปสเตอร์สถิติ — ทุกสีคิดจากเฉดของธีม ไม่มีสีตายตัวสักสี (= `StatPosterSkin`) */
data class StatPosterSkin(
    val papered: Boolean,
    val plate: Color,
    val ink: Color,
    val soft: Color,
    /** สีของตัวเลขช่องคี่ และเส้นคาดใต้พาดหัว */
    val accent: Color,
    /** เส้นคั่นระหว่างช่อง และเส้นคาดเหนือฐาน */
    val hair: Color,
) {
    companion object {
        fun make(surface: WidgetSurface, theme: CardTheme, on: InkStyle): StatPosterSkin {
            if (surface == WidgetSurface.pane) {
                return StatPosterSkin(true, Color.Transparent, on.text(0.95), on.text(0.58), theme.accent, on.line(0.24))
            }
            if (surface != WidgetSurface.clear) {
                val cream = PosterPlate.cream(theme)
                // ดิบ ไม่ใช่ `theme.accent` — แผ่นนี้มืดเสมอ ไม่ว่าการ์ดจะเป็นกระดาษ
                return StatPosterSkin(true, PosterPlate.plate(theme), cream, cream.opacity(0.66),
                    theme.rawAccent, cream.opacity(0.24))
            }
            return StatPosterSkin(false, Color.Transparent, on.text(0.95), on.text(0.58), theme.accent, on.line(0.24))
        }
    }
}

// ============================================================================================
// BookingWidgets.swift — Deal · ContactLine · QRCode
// ============================================================================================

/** วัสดุของสำรับเรต — สีคงที่ ไม่พลิกตามหมึกการ์ด (= `enum Deal`) */
object Deal {
    /** หมึกดำอมม่วงบนวัสดุสีสด */
    val ink = rgb(0.10, 0.07, 0.14)
    val inkSoft = rgb(0.38, 0.33, 0.44)
    /** กระดาษบัตร */
    val card = rgb(0.98, 0.98, 0.97)
}

/** สามช่องทางติดต่อที่ทุกแบบในตระกูล `contact` ต้องแสดงเท่ากัน (= `ContactLine`) · `icon` คือชื่อ SF Symbol → `SFSymbol()` */
data class ContactLine(val label: String, val icon: String, val field: ProfileField) {
    companion object {
        val all: List<ContactLine> = listOf(
            ContactLine("โทร", "phone.fill", ProfileField.phone),
            ContactLine("อีเมล", "envelope.fill", ProfileField.email),
            ContactLine("LINE", "message.fill", ProfileField.lineId),
        )
    }
}

/** QR ของจริง — เรนเดอร์ครั้งเดียวแล้วแคชไว้ตามข้อความ · ขอบคม (ไม่ smooth) เพื่อให้สแกนได้ (= `QRCode`) */
@Composable
fun QRCode(text: String, tint: Color = Color.Black, modifier: Modifier = Modifier) {
    val bmp = remember(text) { QRCodeCache.render(text)?.asImageBitmap() }
    if (bmp != null) {
        Image(bmp, contentDescription = null, contentScale = ContentScale.Fit, filterQuality = FilterQuality.None,
            modifier = modifier)
    } else {
        Box(modifier)
    }
}

object QRCodeCache {
    private val cache = HashMap<String, Bitmap>()

    fun render(text: String): Bitmap? {
        cache[text]?.let { return it }
        return runCatching {
            val hints = mapOf(EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.M, EncodeHintType.MARGIN to 1)
            val m = QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, 0, 0, hints)
            val scale = 8
            val w = m.width * scale; val h = m.height * scale
            val px = IntArray(w * h)
            for (y in 0 until h) for (x in 0 until w) {
                px[y * w + x] = if (m[x / scale, y / scale]) 0xFF000000.toInt() else 0xFFFFFFFF.toInt()
            }
            Bitmap.createBitmap(px, w, h, Bitmap.Config.ARGB_8888)
        }.getOrNull()?.also { cache[text] = it }
    }
}

// ============================================================================================
// VerifiedSealWidget.swift — VerifiedSeal · MiniSeal · SealScallop · CheckStroke · RingText · Guilloche · DotLeader
// ============================================================================================

/** กลีบแปดกลีบ ทรงเดียวกับตราเขียวของแอปหลัก (= `SealScallop`) */
data class SealScallop(val petals: Int = 8, val depth: Float = 0.075f) : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline =
        Outline.Generic(path(size))

    fun path(size: Size, origin: Offset = Offset.Zero): Path {
        val c = Offset(origin.x + size.width / 2, origin.y + size.height / 2)
        val r0 = min(size.width, size.height) / 2
        val steps = petals * 28
        val p = Path()
        for (i in 0..steps) {
            val t = i.toDouble() / steps * 2 * PI
            val r = r0 * (1 - depth + depth * cos(petals * t).toFloat())
            val x = c.x + r * cos(t).toFloat(); val y = c.y + r * sin(t).toFloat()
            if (i == 0) p.moveTo(x, y) else p.lineTo(x, y)
        }
        p.close()
        return p
    }
}

/** เครื่องหมายถูก (= `CheckStroke`) — เส้นเปิด วาดด้วย stroke */
object CheckStroke {
    fun path(w: Float, h: Float, origin: Offset = Offset.Zero): Path = Path().apply {
        moveTo(origin.x, origin.y + h * 0.55f)
        lineTo(origin.x + w * 0.36f, origin.y + h)
        lineTo(origin.x + w, origin.y)
    }
}

/**
 * เหรียญรับรองแปดกลีบ — **หมึกสีเดียว** ของพื้นที่ที่มันนั่งอยู่ เครื่องหมายถูกเจาะทะลุถึงสีพื้น (= `VerifiedSeal`)
 * - punch: สีที่ใช้เจาะเครื่องหมายถูก — สีของพื้นใต้เหรียญ
 * - tint: หมึกของเหรียญ — สีเดียวกับตัวอักษรที่อยู่ข้าง ๆ
 * - compact: ตัวจิ๋ว — ตัดเส้นประในกับเงาออก
 */
@Composable
fun VerifiedSeal(radius: Float, punch: Color, tint: Color = Color.White, compact: Boolean = false,
                 modifier: Modifier = Modifier) {
    val d = radius * 2
    val shape = SealScallop()
    Canvas(
        modifier
            .size(d.dp)
            .let {
                if (compact) it
                else it.shadow(6.dp, shape, clip = false, ambientColor = Color.Black.opacity(0.30), spotColor = Color.Black.opacity(0.30))
            },
    ) {
        val px = size.width
        drawPath(shape.path(size), tint)
        if (!compact) {
            // ผิวโค้งนิดเดียว — ครึ่งบนสว่างกว่าครึ่งล่าง ให้เหรียญเป็นของนูน
            drawPath(shape.path(size), Brush.verticalGradient(listOf(Color.White.opacity(0.22), Color.Black.opacity(0.10))))
            val inner = px * 0.80f
            val o = (px - inner) / 2
            drawPath(shape.path(Size(inner, inner), Offset(o, o)), punch.opacity(0.45),
                style = Stroke(width = 0.7f * density, pathEffect = PathEffect.dashPathEffect(floatArrayOf(1.2f * density, 2.4f * density))))
        }
        val cw = px * 0.44f; val ch = px * 0.34f
        drawPath(CheckStroke.path(cw, ch, Offset((px - cw) / 2, (px - ch) / 2)), punch,
            style = Stroke(width = px * 0.105f, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

/** ตราเขียวตัวเล็กสำหรับแถวรายการ — วาดเอง เพราะไอคอนย้อมสีแล้วเครื่องหมายถูกหายไปทั้งดวง (= `MiniSeal`) */
@Composable
fun MiniSeal(size: Float = 18f, color: Color = Signature.green, modifier: Modifier = Modifier) {
    Canvas(modifier.size(size.dp)) {
        val px = this.size.width
        drawPath(SealScallop().path(this.size), color)
        val cw = px * 0.42f; val ch = px * 0.32f
        drawPath(CheckStroke.path(cw, ch, Offset((px - cw) / 2, (px - ch) / 2)), Color.White,
            style = Stroke(width = px * 0.12f, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

/** ตัวอักษรวิ่งรอบวง — ฟอนต์โมโนจึงแบ่งมุมเท่ากันได้โดยไม่ต้องวัดทีละตัว (= `RingText`) */
@Composable
fun RingText(text: String, radius: Float, size: Float = 7f, color: Color = Color.White, modifier: Modifier = Modifier) {
    val measurer = rememberTextMeasurer()
    val style = Signature.mono(size, FontWeight.Bold)
    val chars = text.toList()
    val box = radius * 2 + size * 2
    Canvas(modifier.size(box.dp)) {
        val c = Offset(this.size.width / 2, this.size.height / 2)
        chars.forEachIndexed { i, ch ->
            val layout = measurer.measure(ch.toString(), style)
            val deg = i.toFloat() / chars.size * 360f
            rotate(deg, pivot = c) {
                drawText(layout, color = color,
                    topLeft = Offset(c.x - layout.size.width / 2f, c.y - radius * density - layout.size.height / 2f))
            }
        }
    }
}

/** ลายกิโยเช่ — เส้นคลื่นปิดวงซ้อนกันสองชุด (ลายเดียวกับที่พิมพ์กันปลอมบนธนบัตร) (= `Guilloche`) */
@Composable
fun Guilloche(color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier.fillMaxSize()) {
        val c = Offset(size.width / 2, size.height / 2)
        val r0 = min(size.width, size.height) / 2
        // (จำนวนคลื่น · ความสูงคลื่น · รัศมีฐาน · จำนวนเส้น)
        val sets = listOf(doubleArrayOf(16.0, 0.115, 0.86, 16.0), doubleArrayOf(9.0, 0.10, 0.60, 12.0))
        for (set in sets) {
            val n = set[0]; val amp = set[1]; val base = set[2]; val count = set[3].toInt()
            for (k in 0 until count) {
                val phi = k.toDouble() / count * 2 * PI / n
                val p = Path()
                val steps = 420
                for (i in 0..steps) {
                    val t = i.toDouble() / steps * 2 * PI
                    val r = r0 * (base + amp * sin(n * (t + phi))).toFloat()
                    val x = c.x + r * cos(t).toFloat(); val y = c.y + r * sin(t).toFloat()
                    if (i == 0) p.moveTo(x, y) else p.lineTo(x, y)
                }
                p.close()
                drawPath(p, color, style = Stroke(width = 0.5f * density))
            }
        }
    }
}

/** เส้นจุดไข่ปลาที่ยืดเต็มช่องว่างระหว่างชื่อข้อกับค่า (= `DotLeader`) — ใช้ใน `Row` ด้วย `Modifier.weight(1f)` */
@Composable
fun DotLeader(color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier.fillMaxWidth().height(10.dp)) {
        val y = size.height - 2.5f * density
        drawLine(color, Offset(0f, y), Offset(size.width, y), strokeWidth = 1f * density, cap = StrokeCap.Round,
            pathEffect = PathEffect.dashPathEffect(floatArrayOf(0.1f * density, 3.4f * density)))
    }
}

// ============================================================================================
// ProofWidgets.swift — BrandPlate
// ============================================================================================

/**
 * โลโก้แบรนด์ล้วน ๆ — ไม่มีแผ่นรองและไม่มีกรอบ (= `BrandPlate`)
 * ไม่มีไฟล์โลโก้ถึงจะเหลือแผ่นโมโนแกรม (ไล่เฉด + เส้นขอบ ถอยไปเป็นแถวหลัง)
 */
@Composable
fun BrandPlate(brand: Brand, side: Float, modifier: Modifier = Modifier) {
    val ink = LocalCardInk.current
    val shape = RoundedCornerShape((side * 0.22f).dp)
    Box(modifier.size(side.dp), contentAlignment = Alignment.Center) {
        val logo = brand.logo
        if (logo != null) {
            RemoteLogo(logo, Modifier.fillMaxSize().dataValue().clip(shape))
        } else {
            Box(
                Modifier.fillMaxSize()
                    .background(Brush.linearGradient(listOf(ink.fill(0.13), ink.fill(0.05))), shape)
                    .border(0.6.dp, ink.line(0.14), shape),
                contentAlignment = Alignment.Center,
            ) {
                Text(brand.monogram, style = sh(side * 0.31f, FontWeight.ExtraBold), color = ink.text(0.6))
            }
        }
    }
}
