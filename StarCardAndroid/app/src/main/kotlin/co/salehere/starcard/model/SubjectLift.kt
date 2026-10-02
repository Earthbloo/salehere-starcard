package co.salehere.starcard.model

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import co.salehere.starcard.AppContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.IdentityHashMap

/**
 * ลบพื้นหลังให้ **อัตโนมัติ** — ตัวกลางระหว่างรูปทึบที่ผู้ใช้เลือกกับ widget ตระกูลคัตเอาต์ (= Model/SubjectLift.swift)
 *
 * ผูกกับ *ตัวรูป* ไม่ใช่กับ "widget ไหน ช่องไหน" — รูปใบเดียวโผล่ในสามโปสเตอร์พร้อมกันได้
 * เก็บผลลงดิสก์ด้วยลายนิ้วมือจากภาพย่อ (`fingerprint`) — Bitmap ที่อ่านจากไฟล์ใหม่ทุกรอบไม่มีตัวตนเดิมติดมา
 *
 * บน Android `PhotoLift.lift` ยังคืน `null` เสมอ (ไม่มี Apple Vision) — ตัวนี้จึงเป็น stub ที่ผ่านทุกขั้นเหมือน iOS
 * แต่ผลลงเอยเป็น `.framed` ทุกใบ · วันที่ต่อ ML Kit ไม่ต้องแตะไฟล์นี้
 */
class SubjectLift private constructor() {
    companion object {
        val shared: SubjectLift by lazy { SubjectLift() }

        private fun cacheURL(print: Long): File? {
            val dir = File(AppContext.app.cacheDir, "subject-lift")
            runCatching { dir.mkdirs() }
            return File(dir, java.lang.Long.toHexString(print) + ".png")
        }

        /**
         * ลายนิ้วมือของรูป: ย่อเหลือ 16×16 แล้ว FNV-1a ทับขนาดพิกเซลจริง
         * ไม่ใช้ `hashCode` — ตัวตนของ Bitmap เปลี่ยนทุกครั้งที่อ่านจากไฟล์ กุญแจจะไม่ตรงกับไฟล์ของรอบก่อน
         */
        private fun fingerprint(ui: Bitmap): Long? {
            val n = 16
            val px = IntArray(n * n)
            val ok = runCatching {
                val small = Bitmap.createScaledBitmap(ui, n, n, true)
                small.getPixels(px, 0, n, 0, 0, n, n)
                if (small !== ui) small.recycle()
            }.isSuccess
            if (!ok) return null
            var h = -0x340d631b7bdddcdbL // 0xcbf29ce484222325
            fun mix(b: Int) { h = (h xor (b.toLong() and 0xFF)) * 0x100000001b3L }
            for (p in px) {
                // ลำดับ RGBA เหมือน premultipliedLast ของ iOS
                mix((p shr 16) and 0xFF); mix((p shr 8) and 0xFF); mix(p and 0xFF); mix((p ushr 24) and 0xFF)
            }
            // width · height · orientation (Android หมุนให้ตอนถอดรหัสแล้ว = 0 เสมอ) เป็น 8 ไบต์ little-endian
            for (v in longArrayOf(ui.width.toLong(), ui.height.toLong(), 0L)) {
                for (i in 0 until 8) mix(((v ushr (i * 8)) and 0xFF).toInt())
            }
            return h
        }

        private suspend fun compute(ui: Bitmap): Cutout.Result {
            val print = withContext(Dispatchers.Default) { fingerprint(ui) }
            val url = print?.let { cacheURL(it) }
            if (url != null) {
                val hit = withContext(Dispatchers.IO) {
                    if (!url.exists()) return@withContext null
                    val img = runCatching { BitmapFactory.decodeFile(url.path) }.getOrNull() ?: return@withContext null
                    Cutout.trim(img)
                }
                if (hit != null) return hit
            }
            val out = PhotoLift.lift(ui) ?: return Cutout.Result.framed(ui)
            val r = withContext(Dispatchers.Default) { Cutout.trim(out) }
            // เก็บ *ใบที่ครอปแล้ว* — เล็กกว่าต้นฉบับมาก และอ่านกลับมาใช้ได้ทันที
            if (r.isCutout && url != null) {
                withContext(Dispatchers.IO) {
                    runCatching {
                        val bytes = ByteArrayOutputStream().also { r.image.compress(Bitmap.CompressFormat.PNG, 100, it) }.toByteArray()
                        val tmp = File(url.path + ".tmp")
                        tmp.writeBytes(bytes)
                        tmp.renameTo(url)
                    }
                }
            }
            return r
        }
    }

    private class Entry(
        /** ถือรูปต้นทางไว้ — กุญแจคือตัวตนของมัน ถ้าปล่อยให้หลุด ตัวตนเดิมอาจถูกรูปอื่นใช้ซ้ำ */
        val source: Bitmap,
    ) {
        var result: Cutout.Result? = null
        var running = true
        var job: Job? = null
    }

    private val entries = IdentityHashMap<Bitmap, Entry>()
    /** ตัวนับที่ widget อ่านไว้ — `Entry` เป็นคลาสธรรมดา การแก้ข้างในไม่ปลุกใคร */
    private var revision by mutableIntStateOf(0)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    /** ผลของรูปนี้ — `null` = ยังไม่เคยเริ่ม · `.framed` = ในรูปไม่มีตัวแบบให้ยก */
    fun result(image: Bitmap): Cutout.Result? {
        @Suppress("UNUSED_VARIABLE") val r = revision
        return entries[image]?.result
    }

    fun isRunning(image: Bitmap): Boolean {
        @Suppress("UNUSED_VARIABLE") val r = revision
        return entries[image]?.running ?: false
    }

    /** เริ่มยกตัวแบบ — เรียกจากตอนวาดได้ เพราะตัวแก้สถานะจริงถูกเลื่อนไปรอบถัดไปของเธรดหลัก */
    fun request(image: Bitmap) {
        if (entries[image] != null) return
        scope.launch { start(image) }
    }

    /** รอจนรูปนี้ลบพื้นหลังเสร็จ — สำหรับคนที่ต้องได้ผลก่อนวาด (รูปนิ่งของหน้าเทมเพลต) */
    suspend fun prepare(image: Bitmap) {
        withContext(Dispatchers.Main) { start(image) }
        entries[image]?.job?.join()
    }

    private fun start(ui: Bitmap) {
        if (entries[ui] != null) return
        val entry = Entry(ui)
        entries[ui] = entry
        revision += 1
        entry.job = scope.launch {
            entry.result = compute(ui)
            entry.running = false
            revision += 1
        }
    }
}
