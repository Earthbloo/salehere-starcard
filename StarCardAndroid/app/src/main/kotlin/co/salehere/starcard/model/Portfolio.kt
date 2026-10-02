package co.salehere.starcard.model

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.webkit.MimeTypeMap
import androidx.compose.runtime.mutableStateListOf
import co.salehere.starcard.AppContext
import co.salehere.starcard.ui.widgets.PhotoLib
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

// MARK: - ผลงานของเจ้าของการ์ด (= Portfolio.swift)
//
// ของชุดเดียวกับหน้า "แก้ไขโปรไฟล์" ของแอป Sale Here เดิม: รูปโปรไฟล์ครีเอเตอร์ 3 ช่อง · รูปผลงาน · วิดีโอผลงาน
// เก็บลงดิสก์เพราะเป็น **ข้อมูลโปรไฟล์** — เจ้าของกรอกครั้งเดียวแล้วการ์ดทุกใบดึงไปใช้ ปิดแอปแล้วหายไม่ได้
// singleton ด้วยเหตุผลเดียวกับ `Profile.me` — ตัวเรนเดอร์รูปตอนแชร์สร้างต้นไม้ใหม่ทั้งก้อน

class Portfolio private constructor() {

    companion object {
        val shared: Portfolio by lazy { Portfolio() }

        const val creatorSlots = 3
        const val workMax = 10
        const val videoMax = 5
        /** เท่ากับขีดของแอป Sale Here เดิม */
        const val videoMaxMB = 100

        private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

        private val dir: File
            get() = File(AppContext.filesDir, "starcard-portfolio").also { it.mkdirs() }

        private fun file(name: String): File = File(dir, name)

        /** อ่านความยาว + เฟรมปกของไฟล์วิดีโอ (= `AVAssetImageGenerator`) */
        private suspend fun makeVideo(id: UUID, file: File): Video? = withContext(Dispatchers.IO) {
            val r = MediaMetadataRetriever()
            try {
                r.setDataSource(file.absolutePath)
                val ms = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
                val seconds = ms / 1000.0
                val atUs = (min(0.5, seconds / 2) * 1_000_000).toLong()
                val frame = r.getFrameAtTime(atUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC) ?: return@withContext null
                Video(id = id, file = file, thumb = frame.fitted(900f), duration = if (seconds.isFinite()) seconds else 0.0)
            } catch (e: Exception) {
                null
            } finally {
                runCatching { r.release() }
            }
        }
    }

    enum class VideoResult { added, tooBig, failed }

    data class Photo(val id: UUID, val image: Bitmap)

    data class Video(val id: UUID, val file: File, val thumb: Bitmap, val duration: Double)

    /** ช่องคงที่ 3 ช่อง — ว่างได้ทีละช่อง ลำดับช่องคือลำดับบนการ์ด */
    private val _creators = mutableStateListOf<Bitmap?>().apply { repeat(creatorSlots) { add(null) } }
    val creators: List<Bitmap?> get() = _creators

    private val _works = mutableStateListOf<Photo>()
    val works: List<Photo> get() = _works

    private val _videos = mutableStateListOf<Video>()
    val videos: List<Video> get() = _videos

    /** นับทุกครั้งที่รูป/วิดีโอเปลี่ยน — ให้รูปย่อเทมเพลตที่อบไว้รู้ว่าต้องอบใหม่ */
    var revision: Int = 0
        private set

    private val io = CoroutineScope(Dispatchers.IO)

    init { load() }

    private fun bump() { revision += 1 }

    // MARK: อ่านให้การ์ด

    /** รูปครีเอเตอร์ที่ใส่แล้ว เรียงตามช่อง — ใส่ไว้ใบเดียวก็วนใบเดียวให้ทั้งสามช่องบนการ์ด */
    val creatorImages: List<Bitmap> get() = _creators.filterNotNull()

    fun creatorImage(slot: Int): Bitmap? {
        val set = creatorImages
        if (set.isEmpty()) return null
        val n = slot % PhotoLib.count
        return set[max(0, n - 1) % set.size]
    }

    fun workImage(slot: Int): Bitmap? =
        if (_works.isEmpty()) null else _works[slot % _works.size].image

    // MARK: เขียน

    fun setCreator(image: Bitmap, at: Int) {
        if (at !in _creators.indices) return
        val img = image.fitted()
        _creators[at] = img
        bump()
        write(img, file("creator-$at.jpg"))
    }

    fun clearCreator(at: Int) {
        if (at !in _creators.indices) return
        _creators[at] = null
        bump()
        write(null, file("creator-$at.jpg"))
    }

    fun addWorks(images: List<Bitmap>) {
        for (image in images.take(max(0, workMax - _works.size))) {
            val p = Photo(id = UUID.randomUUID(), image = image.fitted())
            _works.add(p)
            write(p.image, file("work-${p.id}.jpg"))
        }
        bump()
        persist()
    }

    fun replaceWork(id: UUID, with: Bitmap) {
        val i = _works.indexOfFirst { it.id == id }
        if (i < 0) return
        val p = Photo(id = id, image = with.fitted())
        _works[i] = p
        bump()
        write(p.image, file("work-$id.jpg"))
    }

    fun removeWork(id: UUID) {
        _works.removeAll { it.id == id }
        bump()
        write(null, file("work-$id.jpg"))
        persist()
    }

    /** รับไฟล์วิดีโอที่เลือกมา (Uri จากตัวเลือกสื่อ) — คัดลอกเข้าที่เก็บ ทำรูปปก แล้วจดลงรายการ */
    suspend fun addVideo(temp: Uri): VideoResult {
        if (_videos.size >= videoMax) return VideoResult.failed
        val resolver = AppContext.app.contentResolver
        val bytes = runCatching {
            resolver.openAssetFileDescriptor(temp, "r")?.use { it.length } ?: 0L
        }.getOrDefault(0L)
        if (bytes > videoMaxMB * 1_000_000L) {
            deleteIfFile(temp)
            return VideoResult.tooBig
        }
        val id = UUID.randomUUID()
        val ext = extensionOf(temp, resolver.getType(temp))
        val dest = file("video-$id.$ext")
        val copied = withContext(Dispatchers.IO) {
            runCatching {
                dest.delete()
                resolver.openInputStream(temp)?.use { input ->
                    FileOutputStream(dest).use { out -> input.copyTo(out) }
                } ?: throw IllegalStateException("no stream")
                deleteIfFile(temp)
                true
            }.getOrDefault(false)
        }
        if (!copied) return VideoResult.failed
        val v = makeVideo(id, dest)
        if (v == null) {
            dest.delete()
            return VideoResult.failed
        }
        _videos.add(v)
        bump()
        write(v.thumb, file("video-$id.jpg"))
        persist()
        return VideoResult.added
    }

    fun removeVideo(id: UUID) {
        val v = _videos.firstOrNull { it.id == id } ?: return
        _videos.removeAll { it.id == id }
        bump()
        runCatching { v.file.delete() }
        write(null, file("video-$id.jpg"))
        persist()
    }

    fun resetAll() {
        for (i in _creators.indices) clearCreator(i)
        for (w in _works.toList()) removeWork(w.id)
        for (v in _videos.toList()) removeVideo(v.id)
    }

    // MARK: ที่เก็บ

    @Serializable
    private data class Manifest(
        val works: List<String>,
        val videos: List<VideoEntry>,
    )

    @Serializable
    private data class VideoEntry(
        val id: String,
        val fileName: String,
        val duration: Double,
    )

    private fun persist() {
        val m = Manifest(works = _works.map { it.id.toString() },
            videos = _videos.map { VideoEntry(id = it.id.toString(), fileName = it.file.name, duration = it.duration) })
        val data = runCatching { json.encodeToString(Manifest.serializer(), m) }.getOrNull() ?: return
        io.launch { runCatching { file("manifest.json").writeText(data) } }
    }

    /** อ่านตอนเกิดเลย — การ์ดวาดเฟรมแรกด้วยรูปของเจ้าของ ไม่ใช่รูปตัวอย่างแล้วกระพริบเปลี่ยน */
    private fun load() {
        for (i in _creators.indices) {
            _creators[i] = decode(file("creator-$i.jpg"))
        }
        val manifest = file("manifest.json")
        if (!manifest.exists()) return
        val m = runCatching { json.decodeFromString(Manifest.serializer(), manifest.readText()) }.getOrNull() ?: return
        _works.clear()
        _works.addAll(m.works.mapNotNull { raw ->
            val id = runCatching { UUID.fromString(raw) }.getOrNull() ?: return@mapNotNull null
            decode(file("work-$id.jpg"))?.let { Photo(id = id, image = it) }
        })
        _videos.clear()
        _videos.addAll(m.videos.mapNotNull { e ->
            val id = runCatching { UUID.fromString(e.id) }.getOrNull() ?: return@mapNotNull null
            val f = file(e.fileName)
            if (!f.exists()) return@mapNotNull null
            val thumb = decode(file("video-$id.jpg")) ?: return@mapNotNull null
            Video(id = id, file = f, thumb = thumb, duration = e.duration)
        })
    }

    private fun decode(f: File): Bitmap? =
        if (f.exists()) runCatching { BitmapFactory.decodeFile(f.absolutePath) }.getOrNull() else null

    private fun write(image: Bitmap?, to: File) {
        io.launch {
            if (image == null) {
                runCatching { to.delete() }
                return@launch
            }
            runCatching {
                val tmp = File(to.parentFile, to.name + ".tmp")
                FileOutputStream(tmp).use { out -> image.diskCompress(out, 88) }
                if (!tmp.renameTo(to)) { to.delete(); tmp.renameTo(to) }
            }
        }
    }

    private fun deleteIfFile(uri: Uri) {
        if (uri.scheme == "file") uri.path?.let { runCatching { File(it).delete() } }
    }

    private fun extensionOf(uri: Uri, mime: String?): String {
        val fromMime = mime?.let { MimeTypeMap.getSingleton().getExtensionFromMimeType(it) }
        if (!fromMime.isNullOrEmpty()) return fromMime
        val last = uri.lastPathSegment ?: ""
        val dot = last.lastIndexOf('.')
        val fromName = if (dot >= 0 && dot < last.length - 1) last.substring(dot + 1) else ""
        return if (fromName.isNotEmpty() && fromName.length <= 5) fromName else "mp4"
    }
}

// MARK: - รับวิดีโอจากตัวเลือกสื่อ

/** วิดีโอที่เลือกจากคลังรูป — ระบบให้ Uri ชั่วคราว จึงต้องคัดลอกเข้าที่เก็บก่อน (`Portfolio.addVideo`) */
data class PickedMovie(val uri: Uri)

/** ย่อด้านยาวให้ไม่เกิน `side` — รูปจากกล้องสิบกว่าล้านพิกเซลสิบใบคือหน่วยความจำหลายร้อย MB */
fun Bitmap.fitted(side: Float = 1600f): Bitmap {
    val long = max(width, height).toFloat()
    if (long <= side) return this
    val k = side / long
    val w = max(1, (width * k).roundToInt())
    val h = max(1, (height * k).roundToInt())
    return Bitmap.createScaledBitmap(this, w, h, true)
}

/** เขียนเป็น JPEG เมื่อไม่มีช่องโปร่งใส ไม่งั้น PNG — ชื่อไฟล์ยังลงท้าย .jpg ได้ `BitmapFactory` ดูชนิดจากเนื้อไฟล์ */
private fun Bitmap.diskCompress(out: FileOutputStream, quality: Int) {
    if (hasAlpha()) compress(Bitmap.CompressFormat.PNG, 100, out)
    else compress(Bitmap.CompressFormat.JPEG, quality, out)
}
