package co.salehere.starcard.model

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BlurMaskFilter
import android.graphics.ImageDecoder
import android.graphics.Paint
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.calculatePan
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.SnapshotStateMap
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.paint
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.painter.BitmapPainter
import androidx.compose.ui.input.pointer.PointerInputScope
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChanged
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.layout
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.offset
import co.salehere.starcard.AppContext
import co.salehere.starcard.theme.BackdropEffect
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.HSB
import co.salehere.starcard.theme.PhotoVeil
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.Tinted
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.theme.systemFont
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.LocalSlotRegistry
import co.salehere.starcard.ui.editor.PhotoSlotRect
import co.salehere.starcard.ui.widgets.ImageCache
import co.salehere.starcard.ui.widgets.PhotoLib
import co.salehere.starcard.ui.widgets.RemotePhoto
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt

// MARK: - คลังรูปของการ์ด (= Model/PhotoStore.swift)
//
// รูปที่ผู้ใช้อัปโหลดจะถูกใช้ก่อนเสมอ ถ้ายังไม่มีค่อยตกไปใช้รูปสังเคราะห์ที่แถมมา
// ทำให้ทดลอง layout ได้โดยไม่ต้องรอ asset จริง แล้ววันที่ต่อ ImageKit ก็แทนที่แค่ชั้นนี้

/**
 * การจัดกรอบรูปในช่องหนึ่งช่อง — เลื่อนและซูมหลังวางรูปเข้าไป
 *
 * ทุกช่องรูปครอบ **จากกึ่งกลางเสมอ** — ของสำคัญในรูปมักไม่อยู่กลางเฟรม ผู้ใช้ต้องเล็งเองได้
 * `dx`/`dy` คือสัดส่วนของ **ขนาดภาพที่เรนเดอร์จริง** ไม่ใช่พอยต์ — ยืดกรอบ widget ทีหลังจุดที่เล็งไว้ยังอยู่ตรงเดิม
 */
@Serializable
data class PhotoFit(
    val dx: Float = 0f,
    val dy: Float = 0f,
    /** ซูมเข้าอย่างเดียว (≥ 1) — ต่ำกว่า 1 เมื่อไหร่ภาพหดจนเห็นพื้นว่างในกรอบ */
    val zoom: Float = 1f,
) {
    val isIdentity: Boolean get() = this == identity

    companion object {
        val identity = PhotoFit()
    }
}

/** ที่อยู่ของช่องรูปหนึ่งช่อง — widget ไหน ช่องที่เท่าไหร่ */
data class PhotoSlotRef(val widget: UUID, val slot: Int)

class PhotoStore {
    private val _uploaded = mutableStateListOf<Bitmap>()
    val uploaded: List<Bitmap> get() = _uploaded
    /** ชื่อไฟล์ของรูปในคลังรวม เรียงคู่กับ `uploaded` — รูปไม่มีตัวตนในตัว ต้องมีชื่อไว้ลบถูกใบ */
    private val uploadedIDs = mutableListOf<UUID>()
    /** รูปพื้นหลังการ์ดที่ผู้ใช้อัปโหลดเอง — แยกจากคลังรูปเนื้อหา */
    private val _background = mutableStateOf<Bitmap?>(null)
    var background: Bitmap?
        get() = _background.value
        @JvmName("assignBackground") private set(v) { _background.value = v }
    /** รูปโปรไฟล์จากหน้า "ข้อมูลของฉัน" — ใช้แทนรูปครีเอเตอร์ตั้งต้นในช่อง 1–3 ของทุก widget (ดู `PhotoLib.isProfileSlot`) */
    private val _profile = mutableStateOf<Bitmap?>(null)
    val profile: Bitmap? get() = _profile.value
    /** นับทุกครั้งที่รูปโปรไฟล์เปลี่ยน — ดู `TemplateThumbs.stamp` */
    var profileRevision: Int = 0
        private set
    /** รูปหน้าสมุดบัญชีจากส่วน "การรับเงิน" — เอกสาร ไม่ใช่รูปการ์ด */
    private val _bookBank = mutableStateOf<Bitmap?>(null)
    var bookBank: Bitmap?
        get() = _bookBank.value
        @JvmName("assignBookBank") private set(v) { _bookBank.value = v }
    /**
     * รูปเฉพาะของ widget แต่ละตัว — ทับคลังรวมและรูปตั้งต้นของระบบ
     * เก็บเป็น "ช่องที่เท่าไหร่ของ widget ไหน" เพราะเบนโตะ/แถบภาพมีรูปหลายใบ ครีเอเตอร์ต้องชี้ได้ว่าจะเปลี่ยนใบไหน
     */
    private val _perWidget = mutableStateMapOf<UUID, Map<Int, Bitmap>>()
    val perWidget: Map<UUID, Map<Int, Bitmap>> get() = _perWidget
    /** การจัดกรอบของแต่ละช่อง — ว่างไว้แปลว่ายังเป็นครอปกลางเฟรมตามเดิม */
    private val _fits = mutableStateMapOf<UUID, Map<Int, PhotoFit>>()
    val fits: Map<UUID, Map<Int, PhotoFit>> get() = _fits
    /**
     * ช่องที่ถูก **ลบพื้นหลัง** แล้ว — เก็บผลไว้ต่างหาก ไม่ทับรูปต้นฉบับ
     * ปุ่มนี้ต้องกดคืนได้ทันทีโดยไม่ต้องอัปโหลดใหม่ และรูปต้นฉบับยังเป็นของที่ผู้ใช้เลือกมา
     */
    private val _lifted = mutableStateMapOf<UUID, Map<Int, Bitmap>>()
    val lifted: Map<UUID, Map<Int, Bitmap>> get() = _lifted
    /** ช่องที่กำลังคำนวณหน้ากากอยู่ — ปุ่มหมุนรอระหว่างนี้ และกดซ้ำไม่ได้ */
    var lifting: Set<PhotoSlotRef> by mutableStateOf(emptySet())
        private set
    /**
     * ช่องที่กำลังถูกจัดกรอบอยู่ · null = ไม่มีใครถูกจัด
     * อยู่ในสโตร์เพราะทั้งปุ่มบนตัวรูปและชั้นการ์ดที่วางแผ่นลากทับต้องอ่านค่าเดียวกัน
     */
    var framing: PhotoSlotRef? by mutableStateOf(null)
    /** ขนาดของช่องที่กำลังจัด (หน่วยการ์ด) — `PhotoFitSurface` รายงาน `PhotoFitCatcher` อ่าน · ไม่ถูกสังเกต */
    var framingSize: Size = Size.Zero

    // MARK: แก้แผนที่ซ้อน — Compose สังเกตได้ที่ระดับ widget (แผนที่ในถูกแทนทั้งก้อน)

    private fun <T> SnapshotStateMap<UUID, Map<Int, T>>.put(id: UUID, slot: Int, value: T?) {
        val old = this[id]
        if (value == null && old == null) return
        val inner = (old ?: emptyMap()).toMutableMap()
        if (value == null) inner.remove(slot) else inner[slot] = value
        if (inner.isEmpty()) remove(id) else this[id] = inner
    }

    /**
     * วางรูปลงช่อง `from` แล้วไหลต่อไปช่องถัดไปตามลำดับที่ widget วางไว้
     * เลือกมาใบเดียว = เปลี่ยนเฉพาะช่องนั้น · เลือกมาหลายใบ = ไล่เติมช่องที่เหลือให้ในทีเดียว
     */
    fun set(images: List<Bitmap>, from: Int, order: List<Int>, id: UUID) {
        val start = order.indexOf(from)
        if (start < 0) return
        images.forEachIndexed { k, image ->
            if (start + k !in order.indices) return@forEachIndexed
            val s = order[start + k]
            _perWidget.putSlot(id,s, image)
            write(image, slotURL(id, s))
            // รูปใหม่ = กรอบใหม่ · การเก็บค่าเลื่อนของรูปเก่าไว้ทำให้รูปที่เพิ่งวางเข้าไปเบี้ยวทันที
            _fits.putSlot(id,s, null)
            // และหน้ากากของรูปเก่าก็ใช้กับรูปใหม่ไม่ได้ — ต้องกดลบพื้นหลังใหม่ถ้าต้องการ
            if (_lifted[id]?.get(s) != null) {
                _lifted.putSlot(id,s, null)
                write(null, liftURL(id, s))
            }
        }
        saveManifest()
    }

    fun clear(id: UUID) {
        for (s in (_perWidget[id] ?: emptyMap()).keys) write(null, slotURL(id, s))
        for (s in (_lifted[id] ?: emptyMap()).keys) write(null, liftURL(id, s))
        _perWidget.remove(id)
        _fits.remove(id)
        _lifted.remove(id)
        saveManifest()
    }

    fun clear(slot: Int, id: UUID) {
        _perWidget.putSlot(id,slot, null)
        // คืนรูประบบ = คืนกรอบตั้งต้นด้วย ไม่งั้นรูปใหม่โผล่มาพร้อมกรอบของรูปเก่า
        _fits.putSlot(id,slot, null)
        // พื้นหลังที่ลบไว้เป็นของ *รูปใบนั้น* — คืนรูปเดิมแล้วหน้ากากของใบเก่าใช้ต่อไม่ได้
        _lifted.putSlot(id,slot, null)
        write(null, slotURL(id, slot))
        write(null, liftURL(id, slot))
        saveManifest()
        if (framing == PhotoSlotRef(id, slot)) framing = null
    }

    fun has(slot: Int, id: UUID): Boolean = _perWidget[id]?.get(slot) != null

    // MARK: จัดกรอบรูป

    fun fit(slot: Int, id: UUID?): PhotoFit {
        if (id == null) return PhotoFit.identity
        return _fits[id]?.get(slot) ?: PhotoFit.identity
    }

    fun setFit(f: PhotoFit, slot: Int, id: UUID) {
        _fits.putSlot(id,slot, f)
        // ถูกเรียกทุกเฟรมระหว่างลาก — รอให้นิ้วหยุดก่อนค่อยเขียน
        saveManifest(debounced = true)
    }

    fun resetFit(slot: Int, id: UUID) {
        _fits.putSlot(id,slot, null)
        saveManifest()
    }

    /**
     * รูปจริงในช่อง — ตัวจัดกรอบต้องรู้สัดส่วนของภาพถึงจะคำนวณขอบเขตการเลื่อนได้
     * ไล่ลำดับเดียวกับ `image(i, id)` เป๊ะ ๆ รวมถึงรูประบบที่แคชไว้แล้ว
     */
    fun uiImage(slot: Int, id: UUID): Bitmap? {
        _lifted[id]?.get(slot)?.let { return it }
        _perWidget[id]?.get(slot)?.let { return it }
        library(slot)?.let { return it }
        return ImageCache.shared.cached(PhotoLib.url(slot))
    }

    fun count(id: UUID): Int = _perWidget[id]?.size ?: 0

    // MARK: ลบพื้นหลัง

    fun hasLift(slot: Int, id: UUID): Boolean = _lifted[id]?.get(slot) != null

    fun isLifting(slot: Int, id: UUID): Boolean = lifting.contains(PhotoSlotRef(id, slot))

    /** รูปต้นฉบับของช่อง — **ไม่นับใบที่ลบพื้นหลังไปแล้ว** (ตัวที่ส่งไปแยกพื้นต้องมีพื้นหลัง) */
    private fun sourceImage(slot: Int, id: UUID): Bitmap? {
        _perWidget[id]?.get(slot)?.let { return it }
        library(slot)?.let { return it }
        return ImageCache.shared.cached(PhotoLib.url(slot))
    }

    /**
     * ยกตัวแบบออกจากพื้นหลังของช่องนี้ — คืน `false` เมื่อในรูปไม่มีวัตถุที่แยกได้
     * รูปต้นฉบับไม่ถูกแตะเลย กดคืนพื้นหลังได้ตลอดเวลาด้วย `dropLift` · เรียกจากเธรดหลัก
     */
    suspend fun liftBackground(slot: Int, id: UUID): Boolean {
        val ref = PhotoSlotRef(id, slot)
        if (lifting.contains(ref)) return false
        val source = sourceImage(slot, id) ?: return false
        lifting = lifting + ref
        val out = PhotoLift.lift(source)
        lifting = lifting - ref
        if (out == null) return false
        _lifted.putSlot(id,slot, out)
        write(out, liftURL(id, slot), png = true)
        saveManifest()
        return true
    }

    /** คืนพื้นหลังให้ช่องนี้ */
    fun dropLift(slot: Int, id: UUID) {
        _lifted.putSlot(id,slot, null)
        write(null, liftURL(id, slot))
        saveManifest()
    }

    val hasUploads: Boolean get() = uploaded.isNotEmpty()
    val count: Int get() = max(uploaded.size, PhotoLib.count)

    // MARK: ที่เก็บบนดิสก์
    //
    // รูปพื้นหลังอยู่บนดิสก์ ไม่ใช่แค่ในหน่วยความจำ — มันถูกอ้างจาก `CardTheme.backdrop == .photo` ที่เซฟไปแล้ว
    // รูปในช่อง widget ก็ต้องอยู่รอดข้ามการเปิดแอป — ไม่งั้นการ์ดที่ `CardStore` จำโครงไว้กลับมาพร้อมรูปตัวอย่างแทนรูปของเขา
    // ผูกกับ widget ด้วย `WidgetInstance.id` ซึ่ง `CardStore` เซฟไว้คงที่ข้ามการเปิดแอปแล้ว

    @Serializable
    private data class Manifest(
        val slots: Map<String, List<Int>> = emptyMap(),
        val lifts: Map<String, List<Int>> = emptyMap(),
        val fits: Map<String, Map<Int, PhotoFit>> = emptyMap(),
        val library: List<String> = emptyList(),
    )

    companion object {
        private val backgroundURL: File get() = File(AppContext.filesDir, "starcard-backdrop.jpg")
        private val profileURL: File get() = File(AppContext.filesDir, "starcard-profile.jpg")
        private val bookBankURL: File get() = File(AppContext.filesDir, "starcard-bookbank.jpg")

        private val photoDir: File
            get() = File(AppContext.filesDir, "starcard-photos").also { runCatching { it.mkdirs() } }

        private fun slotURL(id: UUID, s: Int): File = File(photoDir, "slot-$id-$s.jpg")
        /** PNG ไม่ใช่ JPEG — รูปที่ลบพื้นหลังแล้วต้องเก็บความโปร่งใสไว้ */
        private fun liftURL(id: UUID, s: Int): File = File(photoDir, "lift-$id-$s.png")
        private fun libraryURL(id: UUID): File = File(photoDir, "lib-$id.jpg")
        private val manifestURL: File get() = File(photoDir, "manifest.json")

        /** คิวเขียนไฟล์ตัวเดียวแบบเรียงลำดับ — วางรูปแล้วกดคืนทันที การลบต้องไม่วิ่งแซงการเขียน */
        private val io = Executors.newSingleThreadExecutor { r ->
            Thread(r, "starcard.photos.io").apply { priority = Thread.NORM_PRIORITY - 1 }
        }.asCoroutineDispatcher()
        private val ioScope = CoroutineScope(SupervisorJob() + io)

        private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

        private fun atomicWrite(file: File, bytes: ByteArray) {
            runCatching {
                file.parentFile?.mkdirs()
                val tmp = File(file.path + ".tmp")
                tmp.writeBytes(bytes)
                if (!tmp.renameTo(file)) {
                    file.delete()
                    tmp.renameTo(file)
                }
            }
        }

        private fun readBitmap(file: File): Bitmap? =
            if (file.exists()) runCatching { BitmapFactory.decodeFile(file.path) }.getOrNull() else null

        private fun bake(effect: BackdropEffect, image: Bitmap): Bitmap? {
            if (effect != BackdropEffect.halftone) return null
            // ย่อก่อนอบ — จุดปะที่ความละเอียดกล้องคือจุดเล็กจนตาไม่อ่านว่าเป็นลาย เห็นเป็นภาพเทา ๆ
            val long = max(image.width, image.height)
            val k = min(1f, 1200f / max(long, 1))
            val w = max(1, (image.width * k).roundToInt())
            val h = max(1, (image.height * k).roundToInt())
            return runCatching {
                val small = if (k < 1f) Bitmap.createScaledBitmap(image, w, h, true) else image
                val px = IntArray(w * h)
                small.getPixels(px, 0, w, 0, 0, w, h)
                if (small !== image) small.recycle()

                // จอจุด (dot screen) — ช่องละ 8px จุดดำบนขาว รัศมีตามความมืดของช่อง (= CIDotScreen width 8, angle 0)
                val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                val canvas = android.graphics.Canvas(out)
                canvas.drawColor(android.graphics.Color.WHITE)
                val cell = 8
                val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = android.graphics.Color.BLACK
                    // sharpness 0.7 ของ CoreImage — ขอบจุดนุ่มลงนิดหน่อย
                    maskFilter = BlurMaskFilter(cell * 0.3f * 0.3f, BlurMaskFilter.Blur.NORMAL)
                }
                val maxR = cell * 0.5f * sqrt(2f)
                val cols = (w + cell - 1) / cell
                val rows = (h + cell - 1) / cell
                for (cy in 0 until rows) {
                    for (cx in 0 until cols) {
                        var sum = 0.0
                        var n = 0
                        for (y in (cy * cell) until min(h, (cy + 1) * cell)) {
                            for (x in (cx * cell) until min(w, (cx + 1) * cell)) {
                                val p = px[y * w + x]
                                sum += 0.299 * ((p shr 16) and 0xFF) + 0.587 * ((p shr 8) and 0xFF) + 0.114 * (p and 0xFF)
                                n += 1
                            }
                        }
                        if (n == 0) continue
                        val lum = (sum / n / 255.0).coerceIn(0.0, 1.0)
                        val r = ((1 - lum) * maxR).toFloat()
                        if (r > 0.15f) canvas.drawCircle(cx * cell + cell / 2f, cy * cell + cell / 2f, r, paint)
                    }
                }
                out
            }.getOrNull()
        }
    }

    private val main = Handler(Looper.getMainLooper())
    private var pendingSave: Runnable? = null

    private fun saveManifest(debounced: Boolean = false) {
        pendingSave?.let { main.removeCallbacks(it) }
        val job = Runnable { writeManifest() }
        pendingSave = job
        if (debounced) main.postDelayed(job, 400) else job.run()
    }

    private fun writeManifest() {
        val m = Manifest(
            slots = _perWidget.filterValues { it.isNotEmpty() }.entries.associate { (id, slots) -> id.toString() to slots.keys.toList() },
            lifts = _lifted.filterValues { it.isNotEmpty() }.entries.associate { (id, slots) -> id.toString() to slots.keys.toList() },
            fits = _fits.filterValues { it.isNotEmpty() }.entries.associate { (id, slots) -> id.toString() to slots },
            library = uploadedIDs.map { it.toString() },
        )
        val data = runCatching { json.encodeToString(m).toByteArray() }.getOrNull() ?: return
        val url = manifestURL
        // คิวเดียวกับไฟล์รูป — manifest ต้องไม่แซงหน้ารูปที่มันอ้างถึง
        ioScope.launch { atomicWrite(url, data) }
    }

    private fun loadWidgetPhotos() {
        val url = manifestURL
        if (!url.exists()) return
        val m = runCatching { json.decodeFromString<Manifest>(url.readText()) }.getOrNull() ?: return
        for ((key, slots) in m.slots) {
            val id = runCatching { UUID.fromString(key) }.getOrNull() ?: continue
            for (s in slots) readBitmap(slotURL(id, s))?.let { _perWidget.putSlot(id,s, it) }
        }
        for ((key, slots) in m.lifts) {
            val id = runCatching { UUID.fromString(key) }.getOrNull() ?: continue
            for (s in slots) readBitmap(liftURL(id, s))?.let { _lifted.putSlot(id,s, it) }
        }
        for ((key, slots) in m.fits) {
            val id = runCatching { UUID.fromString(key) }.getOrNull() ?: continue
            _fits[id] = slots
        }
        for (key in m.library) {
            val id = runCatching { UUID.fromString(key) }.getOrNull() ?: continue
            readBitmap(libraryURL(id))?.let {
                _uploaded.add(it)
                uploadedIDs.add(id)
            }
        }
    }

    init {
        // อ่านตอนเกิดเลย — `CardBackdrop` วาดในเฟรมแรกที่การ์ดขึ้น ถ้าโหลดทีหลังผู้ใช้จะเห็นพื้นกระพริบทุกครั้งที่เปิดแอป
        background = readBitmap(backgroundURL)
        _profile.value = readBitmap(profileURL)
        bookBank = readBitmap(bookBankURL)
        loadWidgetPhotos()
    }

    // MARK: รูปโปรไฟล์

    fun setProfile(image: Bitmap) {
        _profile.value = image
        profileRevision += 1
        write(image, profileURL)
    }

    fun clearProfile() {
        _profile.value = null
        profileRevision += 1
        write(null, profileURL)
    }

    // MARK: หน้าสมุดบัญชี

    fun setBookBank(image: Bitmap) {
        bookBank = image
        write(image, bookBankURL)
    }

    fun clearBookBank() {
        bookBank = null
        write(null, bookBankURL)
    }

    fun setBackground(image: Bitmap) {
        background = image
        baked.clear()
        lumas.clear()
        veils.clear()
        write(image, backgroundURL)
    }

    fun clearBackground() {
        background = null
        baked.clear()
        lumas.clear()
        veils.clear()
        write(null, backgroundURL)
    }

    /**
     * รูปพื้นหลังที่ผ่านเอฟเฟกต์แล้ว
     * ขาวดำกับเบลอไม่ผ่านทางนี้ — สองตัวนั้นทำสดได้ทุกเฟรม · จุดปะแพงเกินกว่าจะทำตอนวาด จึงอบครั้งเดียวแล้วแคชไว้
     */
    fun background(effect: BackdropEffect): Bitmap? {
        val base = background ?: return null
        if (!effect.isBaked) return base
        baked[effect.raw]?.let { return it }
        val made = bake(effect, base) ?: base
        baked[effect.raw] = made
        return made
    }

    /** แคชของที่อบแล้ว — **ห้ามให้ Compose สังเกต** เพราะมันถูกเขียนระหว่างวาด ไม่งั้นวนวาดใหม่ไม่จบ */
    private val baked = HashMap<String, Bitmap>()

    // MARK: ม่านกันตัวหนังสือจม (ดู `PhotoLuma`)

    /** แผนที่ความสว่างของรูปพื้นหลังต่อเอฟเฟกต์ — วัดครั้งเดียวต่อรูปต่อเอฟเฟกต์ */
    private val lumas = HashMap<BackdropEffect, PhotoLuma>()
    /** ม่านที่วาดแล้ว — ห้ามให้ Compose เห็นด้วยเหตุผลเดียวกับ `baked` */
    private val veils = HashMap<VeilKey, Bitmap>()

    private data class VeilKey(val effect: BackdropEffect, val spec: PhotoVeil)

    fun luma(effect: BackdropEffect): PhotoLuma? {
        lumas[effect]?.let { return it }
        val image = background(effect) ?: return null
        val made = PhotoLuma.measure(image, blurred = effect == BackdropEffect.blur) ?: return null
        lumas[effect] = made
        return made
    }

    /**
     * ม่านของรูปพื้นหลังตามธีม — null เมื่อยังไม่มีรูปของผู้ใช้
     * ทำใหม่ได้ทุกเฟรม ที่จำไว้มีไว้ให้การ์ดหลายใบที่ใช้ธีมเดียวกัน (คลัง · หน้าแชร์) ไม่ต้องทำซ้ำ
     */
    fun veil(effect: BackdropEffect, spec: PhotoVeil): Bitmap? {
        val key = VeilKey(effect, spec)
        veils[key]?.let { return it }
        val luma = luma(effect) ?: return null
        val made = luma.veilImage(luma.veil(spec), color = spec.color) ?: return null
        if (veils.size > 12) veils.clear()
        veils[key] = made
        return made
    }

    /** บีบอัดและเขียนนอกเธรดหลัก — รูปจากกล้องใบหนึ่งใช้เวลานานพอให้จังหวะที่แตะเลือกรูปสะดุด */
    private fun write(image: Bitmap?, url: File?, png: Boolean = false) {
        if (url == null) return
        ioScope.launch {
            if (image == null) {
                runCatching { url.delete() }
                return@launch
            }
            val data = (if (png) image.pngData() else image.diskData(0.9f)) ?: return@launch
            atomicWrite(url, data)
        }
    }

    fun add(images: List<Bitmap>) {
        for (image in images) {
            val id = UUID.randomUUID()
            _uploaded.add(image)
            uploadedIDs.add(id)
            write(image, libraryURL(id))
        }
        saveManifest()
    }

    fun remove(at: Int) {
        if (at !in _uploaded.indices) return
        _uploaded.removeAt(at)
        write(null, libraryURL(uploadedIDs.removeAt(at)))
        saveManifest()
    }

    fun clear() {
        uploadedIDs.forEach { write(null, libraryURL(it)) }
        _uploaded.clear()
        uploadedIDs.clear()
        saveManifest()
    }

    /**
     * รูป **ของผู้ใช้** ในช่องนี้ — ไม่รวมรูปตัวอย่างของระบบ
     * ตอบคำถาม "เจ้าของการ์ดใส่รูปมาหรือยัง" — ตระกูลคัตเอาต์ใช้แยกรูปตัวอย่างกับรูปจริงของเขา
     */
    fun userImage(slot: Int, id: UUID?): Bitmap? {
        if (id != null) _perWidget[id]?.get(slot)?.let { return it }
        return library(slot)
    }

    /**
     * รูปของเจ้าของการ์ดสำหรับช่องนี้ (ยังไม่นับรูปที่วางเฉพาะชิ้น)
     * ช่องครีเอเตอร์ (1–3): รูปโปรไฟล์ครีเอเตอร์ → รูปโปรไฟล์วงกลม · ช่องอื่น: คลังที่อัปโหลด → รูปผลงานจากหน้าแก้ไขโปรไฟล์
     * null = ยังไม่มีรูปของเจ้าของเลย ผู้เรียกตกไปใช้รูปตัวอย่าง
     */
    fun library(i: Int): Bitmap? {
        val folio = Portfolio.shared
        if (PhotoLib.isProfileSlot(i)) {
            folio.creatorImage(i)?.let { return it }
            profile?.let { return it }
        }
        if (_uploaded.isNotEmpty()) return _uploaded[i % _uploaded.size]
        return folio.workImage(i)
    }

    /** รูปวงกลมข้างชื่อ — รูปโปรไฟล์ก่อน ไม่มีค่อยใช้รูปช่องครีเอเตอร์แรก */
    @Composable
    fun avatar(modifier: Modifier = Modifier) {
        val p = profile
        if (p != null) BitmapFill(p, modifier) else image(1, null, modifier)
    }

    /**
     * รูปลำดับที่ i — ลำดับ: รูปที่ลบพื้นหลัง → รูปที่วางในช่องนี้ของ widget → คลังของเจ้าของ → รูปตั้งต้นจากระบบ
     * รูปไม่ถูก redact — ตู้ widget วาดใบที่ "ยังไม่มีข้อมูล" เป็นแท่ง แต่รูปต้องยังเป็นรูป
     * วาดแบบ fill โดยไม่ตัดขอบเอง (เหมือน `Image.resizable` + `.aspectRatio(.fill)`) — ผู้เรียก `.clip()` ที่กรอบเอง
     */
    @Composable
    fun image(i: Int, id: UUID? = null, modifier: Modifier = Modifier) {
        val cut = id?.let { _lifted[it]?.get(i) }
        val own = id?.let { _perWidget[it]?.get(i) }
        val bmp = cut ?: own ?: library(i)
        if (bmp != null) BitmapFill(bmp, modifier) else RemotePhoto(url = PhotoLib.url(i), modifier = modifier)
    }
}

/** `@Environment(PhotoStore.self)` — ชั้นการ์ดใส่สโตร์ให้ · ผู้อ่านทำ `LocalPhotoStore.current ?: return` */
val LocalPhotoStore = staticCompositionLocalOf<PhotoStore?> { null }

/**
 * วาด Bitmap แบบ fill (ครอปจากกึ่งกลาง) เต็มกรอบที่ modifier ให้ — **ไม่ตัดขอบ** ส่วนที่ล้นวาดออกนอกกรอบ
 * เหมือน `Image.resizable().aspectRatio(.fill)` ของ SwiftUI: ผู้เรียกเป็นคนตัดด้วย `.clip()` และ `WidgetPhoto` เลื่อน/ซูมข้างในกรอบนั้นได้
 */
@Composable
internal fun BitmapFill(bitmap: Bitmap, modifier: Modifier = Modifier) {
    val painter = remember(bitmap) { BitmapPainter(bitmap.asImageBitmap()) }
    Box(modifier.paint(painter, contentScale = ContentScale.Crop))
}

/** ขนาดที่ภาพถูกวาดจริงในกรอบแบบ fill (ก่อนซูม) — คำนวณจากสัดส่วนของภาพกับกฎ `.fill` */
internal fun fillRenderedSize(imageWidth: Int, imageHeight: Int, frame: Size): Size {
    if (imageWidth <= 0 || imageHeight <= 0 || frame.width <= 0f || frame.height <= 0f) return frame
    val ia = imageWidth.toFloat() / imageHeight
    val sa = frame.width / frame.height
    return if (ia > sa) Size(frame.height * ia, frame.height) else Size(frame.width, frame.width / ia)
}

// MARK: - รูปในบริบทของ widget

/**
 * ประกาศว่ากรอบนี้คือช่องรูปหมายเลข `index` ของ widget (= `.photoSlot(n)`)
 * ติดไว้ที่ "กรอบของช่อง" ไม่ใช่ที่ตัวรูป เพราะรูปแบบ fill ล้นกรอบ ปุ่มจะไปเกาะนอกช่อง
 * รายงานเข้า `SlotRegistry` ของหน้า (พิกัดหน่วยออกแบบของหน้า) แทน anchor preference
 */
fun Modifier.photoSlot(index: Int): Modifier = composed {
    val reg = LocalSlotRegistry.current
    val id = LocalWidgetID.current
    if (reg == null || id == null) Modifier
    else Modifier.onGloballyPositioned { c ->
        reg.reportPhoto(id, PhotoSlotRect(index, reg.toPage(c.boundsInRoot())))
    }
}

/** รูปหนึ่งใบในบริบทของ widget — เลือกให้เองว่าใช้รูปของ widget นี้ ของการ์ด หรือของระบบ */
@Composable
fun WidgetPhoto(index: Int, modifier: Modifier = Modifier) {
    val store = LocalPhotoStore.current
    val wid = LocalWidgetID.current
    if (store == null) {
        RemotePhoto(url = PhotoLib.url(index), modifier = modifier)
        return
    }
    val f = store.fit(index, wid)
    // ภาพที่วาดจริง — `dx`/`dy` เป็นสัดส่วนของขนาดที่เรนเดอร์แบบ fill ไม่ใช่ขนาดกรอบ (ดู `PhotoFitCatcher.rendered`)
    val bmp = wid?.let { store.uiImage(index, it) } ?: store.library(index) ?: ImageCache.shared.cached(PhotoLib.url(index))
    val bw = bmp?.width ?: 0
    val bh = bmp?.height ?: 0
    // การเลื่อน/ซูมไม่แตะเลย์เอาต์ — กรอบยังรายงานขนาดเดิม ที่เปลี่ยนคือ *ตำแหน่งที่ภาพถูกวาด* เท่านั้น
    store.image(index, wid, modifier.graphicsLayer {
        val rendered = fillRenderedSize(bw, bh, size)
        scaleX = f.zoom
        scaleY = f.zoom
        translationX = f.dx * rendered.width
        translationY = f.dy * rendered.height
    })
}

// MARK: - โทนสีเด่นของภาพ

/**
 * รูปที่มีพื้นโปร่งเก็บเป็น PNG · ที่เหลือเป็น JPEG
 * JPEG ไม่มีช่องโปร่ง — PNG ตัดพื้นที่ผู้ใช้เตรียมมาเอง เซฟเป็น JPEG แล้วเปิดแอปรอบหน้าจะได้พื้นทึบกลับมาแทน
 * ชื่อไฟล์ยังลงท้าย .jpg ได้ `BitmapFactory` ดูชนิดจากเนื้อไฟล์ ไม่ได้ดูจากนามสกุล
 */
fun Bitmap.diskData(quality: Float): ByteArray? = runCatching {
    ByteArrayOutputStream().also { out ->
        if (hasAlpha()) compress(Bitmap.CompressFormat.PNG, 100, out)
        else compress(Bitmap.CompressFormat.JPEG, (quality * 100).roundToInt().coerceIn(0, 100), out)
    }.toByteArray()
}.getOrNull()

/** `pngData()` ของ UIImage */
internal fun Bitmap.pngData(): ByteArray? = runCatching {
    ByteArrayOutputStream().also { compress(Bitmap.CompressFormat.PNG, 100, it) }.toByteArray()
}.getOrNull()

/**
 * หาโทนสีเด่นของภาพ — คืน (hue, saturation, brightness) ให้ธีมทั้งการ์ดล้อตามพื้นหลัง
 * ย่อเหลือ 32×32 แล้วโหวตเป็นถัง hue 24 ช่อง ถ่วงน้ำหนักด้วยความสด×ความสว่าง — "สีที่รู้สึกเด่น" ไม่ใช่ค่าเฉลี่ยจืด ๆ
 * คืน null เมื่อภาพแทบไร้สี · iOS คืนแค่ (hue, saturation) — `b` แถมมาโดยไม่มีใครต้องใช้
 */
fun Bitmap.dominantTone(): HSB? {
    val side = 32
    val px = IntArray(side * side)
    val ok = runCatching {
        val small = Bitmap.createScaledBitmap(this, side, side, true)
        small.getPixels(px, 0, side, 0, 0, side, side)
        if (small !== this) small.recycle()
    }.isSuccess
    if (!ok) return null

    val weight = DoubleArray(24)
    val hueSum = DoubleArray(24)
    val satSum = DoubleArray(24)
    val briSum = DoubleArray(24)
    val hsv = FloatArray(3)
    for (p in px) {
        android.graphics.Color.RGBToHSV((p shr 16) and 0xFF, (p shr 8) and 0xFF, p and 0xFF, hsv)
        val h = hsv[0] / 360.0
        val s = hsv[1].toDouble()
        val v = hsv[2].toDouble()
        val w = s * v
        if (w <= 0.05) continue
        val k = min(23, (h * 24).toInt())
        weight[k] += w
        hueSum[k] += h * w
        satSum[k] += s * w
        briSum[k] += v * w
    }
    val top = weight.indices.maxByOrNull { weight[it] } ?: return null
    if (weight[top] <= 0.5) return null
    return HSB(hueSum[top] / weight[top], min(1.0, satSum[top] / weight[top]), min(1.0, briSum[top] / weight[top]))
}

// MARK: - ถอดรหัสรูปที่เลือก

/**
 * อ่านรูปจาก URI ของตัวเลือกรูป — ย่อให้ด้านยาว ≤ `maxSide` ตั้งแต่ตอนถอดรหัส (รูปกล้อง 12MP ไม่ควรอยู่ในหน่วยความจำเต็มใบ)
 * ใช้ `ImageDecoder` (หมุนตาม EXIF ให้ · software bitmap อ่านพิกเซลได้) · ต่ำกว่า API 28 ตกไป `BitmapFactory` ที่ไม่หมุนตาม EXIF
 */
internal suspend fun decodeBitmap(uri: Uri, maxSide: Int = 2048): Bitmap? = withContext(Dispatchers.IO) {
    val cr = AppContext.app.contentResolver
    runCatching {
        if (Build.VERSION.SDK_INT >= 28) {
            val src = ImageDecoder.createSource(cr, uri)
            ImageDecoder.decodeBitmap(src) { decoder, info, _ ->
                decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                decoder.isMutableRequired = false
                val w = info.size.width
                val h = info.size.height
                val k = maxSide.toFloat() / max(1, max(w, h))
                if (k < 1f) decoder.setTargetSize(max(1, (w * k).roundToInt()), max(1, (h * k).roundToInt()))
            }
        } else {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            cr.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
            var sample = 1
            while (max(bounds.outWidth, bounds.outHeight) / (sample * 2) >= maxSide) sample *= 2
            val opts = BitmapFactory.Options().apply { inSampleSize = sample }
            cr.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, opts) }
        }
    }.getOrNull()
}

private fun imagePickRequest(): PickVisualMediaRequest =
    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)

// MARK: - ปุ่มเปลี่ยนรูปรายช่อง

/** ด้านที่พื้นที่กดยื่นออกไปได้ (= `Edge.Set` ของ `HitArea`) */
private enum class HitEdge { top, leading, trailing, bottom }

/**
 * พื้นที่กดที่ยื่นออกจากกรอบเฉพาะด้านที่สั่ง (= `HitArea` + `.contentShape`)
 * ตาเห็นเท่าเดิม แต่นิ้วโดนเท่าปุ่มมาตรฐาน 44pt **บนจอ** — ด้านที่ไม่ยื่นยังได้ครึ่งหนึ่งของช่องไฟ 4pt ระหว่างปุ่ม
 * ห้ามยื่นเข้าหาปุ่มข้าง ๆ ไม่งั้นพื้นที่กดทับกัน แตะ "เปลี่ยนรูป" แล้วได้ "จัดรูป"
 */
private fun Modifier.hitReach(pad: Float, reach: Set<HitEdge>, interaction: MutableInteractionSource, onClick: () -> Unit): Modifier {
    val gap = 2f
    fun d(e: HitEdge): Float = if (e in reach) pad else gap
    val l = d(HitEdge.leading)
    val t = d(HitEdge.top)
    val r = d(HitEdge.trailing)
    val b = d(HitEdge.bottom)
    return this
        .layout { measurable, constraints ->
            val lp = (l * density).roundToInt()
            val tp = (t * density).roundToInt()
            val rp = (r * density).roundToInt()
            val bp = (b * density).roundToInt()
            val p = measurable.measure(constraints.offset(lp + rp, tp + bp))
            // รายงานขนาดเท่าตัวปุ่ม แล้ววางก้อนที่มีขอบกดให้ยื่นออกนอกกรอบ — Compose ไม่ตัดทัชตามกรอบแม่
            layout(max(0, p.width - lp - rp), max(0, p.height - tp - bp)) { p.place(-lp, -tp) }
        }
        .clickable(interactionSource = interaction, indication = null, onClick = onClick)
        .padding(start = l.dp, top = t.dp, end = r.dp, bottom = b.dp)
}

/**
 * ปุ่มกลม + คำกำกับใต้ปุ่ม (= `orb`)
 * ไอคอนสามตัวนี้ไม่มีตัวไหนอ่านออกด้วยตัวเอง — หนึ่งคำใต้ปุ่มถูกกว่าการให้เดาผิดแล้วต้อง undo
 * คำถูกซ่อนเมื่อช่องแคบ (`labelled == false`) — ป้ายที่ล้นออกนอกรูปอ่านยากกว่าไม่มีป้าย
 */
@Composable
private fun Orb(
    theme: CardTheme, symbol: String, label: String, tinted: Boolean, labelled: Boolean,
    hitPad: Float, reach: Set<HitEdge>, onClick: () -> Unit,
) {
    val interaction = remember { MutableInteractionSource() }
    val shadow = Color.Black.opacity(0.35)
    Column(
        Modifier.hitReach(hitPad, reach, interaction, onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.5.dp),
    ) {
        val fill = Modifier
            .size(25.dp)
            .shadow(5.dp, CircleShape, ambientColor = shadow, spotColor = shadow)
            .let {
                if (tinted) it.background(Brush.linearGradient(listOf(theme.accentSoft, theme.accent)), CircleShape)
                else it.background(Color.Black.opacity(0.55), CircleShape)
            }
            .border(0.5.dp, Color.White.opacity(0.28), CircleShape)
        Box(fill, contentAlignment = Alignment.Center) {
            SFSymbol(symbol, size = 10f, tint = if (tinted) Color.Black.opacity(0.85) else Color.White.opacity(0.9))
        }
        if (labelled) {
            Box(
                Modifier
                    .shadow(3.dp, CircleShape, ambientColor = shadow, spotColor = shadow)
                    .background(Color.Black.opacity(0.6), CircleShape)
                    .padding(horizontal = 4.5.dp, vertical = 1.5.dp),
            ) {
                Text(label, style = sh(8.5f, SHFont.semibold), color = Color.White.opacity(0.95), maxLines = 1, softWrap = false)
            }
        }
    }
}

/**
 * ปุ่มไอคอนประจำ "ช่องรูปหนึ่งช่อง" — ลอยอยู่มุมขวาบนของรูปใบนั้น
 * หนึ่งปุ่มต่อหนึ่งรูป ไม่ใช่หนึ่งปุ่มต่อ widget เพราะเบนโตะ/แถบภาพมีรูปหลายใบ · แตะที่ใบไหนก็ได้ใบนั้น
 *
 * `order` = ลำดับช่องทั้งหมดของ widget นี้ — ใช้ไล่เติมต่อเมื่อผู้ใช้เลือกมาหลายรูป
 * `labelled` = ช่องกว้างพอให้มีคำกำกับใต้ปุ่ม · `scale` = สเกลของการ์ดบนจอ ใช้ขยาย **พื้นที่กด** ให้ได้ขนาดนิ้วเสมอ
 */
@Composable
fun PhotoSlotButton(
    theme: CardTheme,
    widgetID: UUID,
    slot: Int,
    order: List<Int>,
    labelled: Boolean = true,
    scale: Float = 1f,
    modifier: Modifier = Modifier,
) {
    val store = LocalPhotoStore.current ?: return
    val scope = rememberCoroutineScope()
    val isCustom = store.has(slot, widgetID)
    /** เลือกได้มากสุดเท่าจำนวนช่องที่เหลือนับจากช่องนี้ไป — เกินกว่านั้นก็ไม่มีที่ให้ลง */
    val room = order.indexOf(slot).let { if (it < 0) 1 else max(1, order.size - it) }
    /** ขอบกดรอบวงกลม 25pt ในหน่วยการ์ด — ให้รวมกันได้ 44pt บนจอ */
    val hitPad = max(4f, (44f / max(scale, 0.01f) - 25f) / 2f)

    val onPicked: (List<Uri>) -> Unit = { uris ->
        if (uris.isNotEmpty()) scope.launch {
            val images = uris.mapNotNull { decodeBitmap(it) }
            store.set(images, slot, order, widgetID)
            Haptics.impact(Haptics.Style.medium)
        }
    }
    val multi = rememberLauncherForActivityResult(ActivityResultContracts.PickMultipleVisualMedia(max(2, room))) { onPicked(it) }
    val single = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { onPicked(listOfNotNull(it)) }
    val pick: () -> Unit = { if (room > 1) multi.launch(imagePickRequest()) else single.launch(imagePickRequest()) }

    /** ช่องที่เปลี่ยนรูปไปแล้วค่อยมีปุ่มถอย — ช่องที่ยังเป็นรูประบบไม่มีอะไรให้คืน */
    val undoButton: @Composable () -> Unit = {
        if (isCustom) Orb(theme, "arrow.counterclockwise", "รูปเดิม", tinted = false, labelled = labelled, hitPad = hitPad,
            reach = setOf(HitEdge.top, HitEdge.leading)) {
            store.clear(slot, widgetID)
            Haptics.impact(Haptics.Style.light)
        }
    }
    /** จัดกรอบ — มีทุกช่องที่มีรูป ไม่ใช่เฉพาะรูปที่อัปโหลดเอง รูปตั้งต้นก็ถูกครอปจากกึ่งกลางเหมือนกัน */
    val framingButton: @Composable () -> Unit = {
        Orb(theme, "arrow.up.and.down.and.arrow.left.and.right", "จัดรูป", tinted = false, labelled = labelled, hitPad = hitPad,
            // มีปุ่มถอยอยู่ซ้าย (แถวมีป้าย) = ยื่นไปทางซ้ายไม่ได้
            reach = if (isCustom && labelled) setOf(HitEdge.bottom) else setOf(HitEdge.leading, HitEdge.bottom)) {
            store.framing = PhotoSlotRef(widgetID, slot)
            Haptics.impact(Haptics.Style.light)
        }
    }
    val pickerButton: @Composable () -> Unit = {
        Orb(theme, "photo.badge.plus.fill", "เปลี่ยนรูป", tinted = true, labelled = labelled, hitPad = hitPad,
            // มีปุ่มถอยอยู่บน (ช่องแคบเรียงสองแถว) = ยื่นขึ้นไม่ได้
            reach = if (isCustom && !labelled) setOf(HitEdge.trailing, HitEdge.bottom)
                    else setOf(HitEdge.top, HitEdge.trailing, HitEdge.bottom)) { pick() }
    }

    // **ช่องแคบเรียงสองแถว** — ปุ่มทั้งแถวในแถวเดียวกว้างกว่าช่องเล็กในเบนโตะ แถวที่ล้นจะไปทับปุ่มของช่องข้าง ๆ
    if (labelled) {
        Row(modifier, horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.Top) {
            undoButton(); framingButton(); pickerButton()
        }
    } else {
        Column(modifier, horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(4.dp)) {
            undoButton()
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.Top) {
                framingButton(); pickerButton()
            }
        }
    }
}

// MARK: - ปุ่มอัปโหลดพื้นหลัง

/** เลือกรูปพื้นหลังการ์ดหนึ่งรูป — ตั้งพื้นหลังแล้วส่งโทนสีเด่นกลับไปให้ธีมล้อตาม (`null` เมื่อภาพแทบไร้สี) */
@Composable
fun BackgroundPickButton(
    theme: CardTheme,
    /** แบบย่อ — ไอคอนล้วน สำหรับวางคู่แถบเลือกสีที่หัวชีต */
    compact: Boolean = false,
    modifier: Modifier = Modifier,
    onPicked: (HSB?) -> Unit,
) {
    val store = LocalPhotoStore.current ?: return
    val scope = rememberCoroutineScope()
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) scope.launch {
            val ui = decodeBitmap(uri) ?: return@launch
            val tone = withContext(Dispatchers.Default) { ui.dominantTone() }
            store.setBackground(ui)
            onPicked(tone)
            Haptics.impact(Haptics.Style.medium)
        }
    }
    val interaction = remember { MutableInteractionSource() }
    val hasBackground = store.background != null
    Row(
        modifier
            .clickable(interactionSource = interaction, indication = null) { launcher.launch(imagePickRequest()) }
            .background(Brush.horizontalGradient(listOf(theme.accentSoft, theme.accent)), CircleShape)
            .padding(horizontal = if (compact) 10.dp else 9.dp, vertical = if (compact) 7.dp else 6.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Tinted(Color.Black.opacity(0.85)) {
            SFSymbol(if (hasBackground) "photo.fill" else "photo.badge.plus.fill", size = if (compact) 11f else 10f)
            if (!compact) {
                // ป้ายบอกสิ่งที่จะเกิดขึ้น ไม่ใช่ชื่อของที่อยู่ปลายทาง
                Text(if (hasBackground) "เปลี่ยนรูป" else "เลือกรูป", style = sh(9.5f, SHFont.semibold),
                    color = Color.Black.opacity(0.85), maxLines = 1, softWrap = false)
            }
        }
    }
}

// MARK: - ปุ่มอัปโหลด

@Composable
fun PhotoUploadButton(theme: CardTheme, compact: Boolean = false, modifier: Modifier = Modifier) {
    val store = LocalPhotoStore.current ?: return
    val scope = rememberCoroutineScope()
    var loading by remember { mutableStateOf(false) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.PickMultipleVisualMedia(12)) { uris ->
        if (uris.isNotEmpty()) {
            loading = true
            scope.launch {
                val images = uris.mapNotNull { decodeBitmap(it) }
                store.add(images)
                loading = false
                Haptics.impact(Haptics.Style.medium)
            }
        }
    }
    val interaction = remember { MutableInteractionSource() }
    Row(
        modifier
            .clickable(interactionSource = interaction, indication = null) { launcher.launch(imagePickRequest()) }
            .background(Brush.horizontalGradient(listOf(theme.accentSoft, theme.accent)), CircleShape)
            .padding(horizontal = if (compact) 10.dp else 13.dp, vertical = 7.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Tinted(Color.Black.opacity(0.85)) {
            SFSymbol(if (loading) "arrow.triangle.2.circlepath" else "photo.badge.plus.fill", size = if (compact) 11f else 12f)
            if (!compact) {
                Text(if (store.hasUploads) "รูป ${store.uploaded.size}" else "อัปโหลดรูป",
                    style = systemFont(12f, SHFont.semibold), color = Color.Black.opacity(0.85), maxLines = 1, softWrap = false)
            }
        }
    }
}

// MARK: - แผ่นจัดกรอบรูป

/**
 * กรอบของช่องที่กำลังจัดอยู่ — **แค่หน้าตา** (เส้นสามส่วน + ขอบสีธีม) ไม่รับทัช
 * ท่าลาก/ถ่างอยู่ที่ `PhotoFitCatcher` ซึ่งคลุมทั้งจอ — แผ่นนี้เหลือหน้าที่เดียว: รายงานขนาดช่อง (หน่วยการ์ด) ให้ตัวคลุมจอ
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun PhotoFitSurface(theme: CardTheme, widgetID: UUID, slot: Int, size: Size, modifier: Modifier = Modifier) {
    val store = LocalPhotoStore.current
    LaunchedEffect(store, size) { store?.framingSize = size }
    val accent = theme.accent
    Box(
        modifier.fillMaxSize().drawBehind {
            val line = Color.White.opacity(0.35)
            val lw = 0.6.dp.toPx()
            for (i in 1..2) {
                val x = this.size.width * (i / 3f)
                drawRect(line, Offset(x - lw / 2, 0f), Size(lw, this.size.height))
                val y = this.size.height * (i / 3f)
                drawRect(line, Offset(0f, y - lw / 2), Size(this.size.width, lw))
            }
            val bw = 1.5.dp.toPx()
            drawRect(accent, Offset(bw / 2, bw / 2), Size(this.size.width - bw, this.size.height - bw), style = Stroke(bw))
        },
    )
}

/** ค่าคงที่ของ `PhotoFitCatcher` — ซูมได้มากแค่ไหน: ใหญ่เท่าที่ผู้ใช้อยากได้ ไม่ใช่ 3× ที่คิดแทนเขา */
object PhotoFitCatcher {
    const val maxZoom: Float = 8f
}

/**
 * ตัวรับนิ้วของโหมดจัดรูป — **คลุมทั้งจอ** ลากหรือถ่างตรงไหนก็ได้ (= `PhotoFitCatcher`)
 *
 * ต้องเข้าโหมดก่อน ไม่ใช่ลากได้เลย — ไม่งั้นท่า "กดค้างแล้วลากย้าย widget" ใช้ไม่ได้กับทุกตัวที่มีรูป
 * ระยะนิ้ววัดบนจอ แต่ช่องรูปอยู่ในการ์ดที่ถูกย่อ (`scale`) — หารกลับก่อนแปลงเป็นสัดส่วนของภาพ
 * เลื่อนได้ไกลสุดเท่าที่ **ภาพยังคลุมกรอบอยู่** — ช่องรูปที่มีขอบดำอ่านเป็นงานพัง ไม่ใช่งานที่ตั้งใจเว้น
 */
@Composable
fun PhotoFitCatcher(theme: CardTheme, scale: Float, modifier: Modifier = Modifier) {
    val store = LocalPhotoStore.current ?: return
    val density = LocalDensity.current.density
    val ref = store.framing
    val fit = if (ref != null) store.fit(ref.slot, ref.widget) else PhotoFit.identity

    /** ช่องนี้เป็น **คนที่ตัดพื้นแล้ว** ไหม — ตัวคัตเอาต์ถูกวาด *พอดีกรอบ* ส่วนล้นเป็นศูนย์ กฎ "ต้องคลุมกรอบ" จะล็อกมันตาย */
    fun isCutout(): Boolean {
        val r = store.framing ?: return false
        val img = store.userImage(r.slot, r.widget) ?: return true
        if (CutoutCache.shared.result(img).isCutout) return true
        return SubjectLift.shared.result(img)?.isCutout == true
    }

    /** ขนาดที่ภาพถูกวาดจริงในกรอบ (ก่อนซูม) — คำนวณจากสัดส่วนของภาพกับกฎ `.fill` */
    fun rendered(): Size {
        val size = store.framingSize
        val r = store.framing ?: return size
        if (isCutout()) return size
        val img = store.uiImage(r.slot, r.widget) ?: return size
        return fillRenderedSize(img.width, img.height, size)
    }

    /** หนีบค่า — คิดเป็นสัดส่วนของภาพ เพราะ `dx`/`dy` เก็บหน่วยนั้น */
    fun clamped(f: PhotoFit): PhotoFit {
        // ตัวคัตเอาต์: เลื่อนได้อิสระครึ่งกรอบทุกทิศ (ยิ่งซูมยิ่งไปได้ไกล) — ไกลกว่านั้นคนหลุดออกนอกใบ
        if (isCutout()) {
            val lim = 0.5f * max(1f, f.zoom)
            return f.copy(dx = min(lim, max(-lim, f.dx)), dy = min(lim, max(-lim, f.dy)))
        }
        // รูปในกรอบ: ภาพต้องคลุมกรอบเสมอ
        val size = store.framingSize
        val rd = rendered()
        val limX = max(0f, (f.zoom - size.width / max(1f, rd.width)) / 2)
        val limY = max(0f, (f.zoom - size.height / max(1f, rd.height)) / 2)
        return f.copy(dx = min(limX, max(-limX, f.dx)), dy = min(limY, max(-limY, f.dy)))
    }

    suspend fun PointerInputScope.gestures() {
        awaitEachGesture {
            awaitFirstDown()
            val start = store.framing
            val base = if (start != null) store.fit(start.slot, start.widget) else PhotoFit.identity
            var pan = Offset.Zero
            var mag = 1f
            do {
                val event = awaitPointerEvent()
                val r = store.framing
                if (r != null) {
                    val zoomChange = event.calculateZoom()
                    val panChange = event.calculatePan()
                    if (zoomChange != 1f || panChange != Offset.Zero) {
                        mag *= zoomChange
                        pan += panChange
                        val s = max(scale, 0.01f)
                        val rd = rendered()
                        val f = base.copy(
                            dx = base.dx + pan.x / density / s / max(1f, rd.width),
                            dy = base.dy + pan.y / density / s / max(1f, rd.height),
                            zoom = min(PhotoFitCatcher.maxZoom, max(if (isCutout()) 0.4f else 1f, base.zoom * mag)),
                        )
                        store.setFit(clamped(f), r.slot, r.widget)
                    }
                }
                event.changes.forEach { if (it.positionChanged()) it.consume() }
            } while (event.changes.any { it.pressed })
            Haptics.impact(Haptics.Style.light)
        }
    }

    Box(
        modifier
            .fillMaxSize()
            // โปร่งแต่ยังกินทัช — ปุ่มในแถบด้านล่างกินทัชของตัวเองก่อน จึงไม่เริ่มท่าลาก
            .pointerInput(store, scale) { gestures() },
        contentAlignment = Alignment.BottomCenter,
    ) {
        // MARK: แถบ "เสร็จ" — อยู่ในชั้นนี้ เพราะชั้นนี้ทับทุกอย่าง
        val resetInteraction = remember { MutableInteractionSource() }
        val doneInteraction = remember { MutableInteractionSource() }
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .padding(bottom = 8.dp)
                .border(0.6.dp, Color.White.opacity(0.1), CircleShape)
                .background(grey(0.09), CircleShape)
                .padding(horizontal = 16.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("ลากหรือถ่างนิ้วตรงไหนก็ได้", style = sh(11.5f, SHFont.medium), color = Color.White.opacity(0.75))
            Spacer(Modifier.weight(1f).widthIn(min = 6.dp))
            if (!fit.isIdentity && ref != null) {
                Box(
                    Modifier
                        .size(38.dp)
                        .clickable(interactionSource = resetInteraction, indication = null) {
                            store.resetFit(ref.slot, ref.widget)
                            Haptics.impact(Haptics.Style.light)
                        }
                        .background(Color.White.opacity(0.12), CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    SFSymbol("arrow.counterclockwise", size = 13f, tint = Color.White.opacity(0.9))
                }
            }
            Box(
                Modifier
                    .height(38.dp)
                    .clickable(interactionSource = doneInteraction, indication = null) {
                        store.framing = null
                        Haptics.impact(Haptics.Style.medium)
                    }
                    .background(Brush.horizontalGradient(listOf(theme.accentSoft, theme.accent)), CircleShape)
                    .padding(horizontal = 20.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text("เสร็จ", style = sh(14f, SHFont.semibold), color = Color.Black.opacity(0.85))
            }
        }
    }
}


/** อัปเดตช่องในแผนที่ซ้อน (widget → slot → value) โดยแทนที่แผนที่ชั้นในทั้งก้อน — Compose จึงเห็นการเปลี่ยนต่อ widget */
private fun <V : Any> androidx.compose.runtime.snapshots.SnapshotStateMap<UUID, Map<Int, V>>.putSlot(id: UUID, slot: Int, value: V?) {
    val inner = (this[id] ?: emptyMap()).toMutableMap()
    if (value == null) inner.remove(slot) else inner[slot] = value
    if (inner.isEmpty()) remove(id) else this[id] = inner
}
