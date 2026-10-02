package co.salehere.starcard.model

import android.graphics.Bitmap
import androidx.compose.ui.geometry.Rect
import java.util.IdentityHashMap
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * รูปที่ผู้ใช้ "ลบพื้นหลังมาแล้ว" — วัตถุดิบของ widget ตระกูลคัตเอาต์ (= Model/Cutout.swift)
 *
 * แอปไม่ตัดรูปให้ — ไฟล์นี้มีหน้าที่แค่สองข้อ:
 * 1. ตอบว่ารูปใบนี้ตัดมาจริงไหม (alpha channel อย่างเดียวไม่พอ — ใช้ "ขอบนอกใสเป็นส่วนใหญ่ไหม")
 * 2. ครอปที่ว่างใสรอบตัวทิ้ง — เครื่องมือตัดพื้นหลังคืนภาพขนาดเท่าต้นฉบับ คนจึงลอยเล็กจิ๋วกลางกรอบ
 */
object Cutout {

    /** ผลการตรวจรูปหนึ่งใบ */
    class Result(
        /** รูปที่ครอปขอบใสออกแล้ว — ถ้าไม่ใช่รูปตัด จะเป็นใบเดิมไม่ถูกแตะ */
        val image: Bitmap,
        /** ตัดพื้นหลังมาจริงไหม — `false` แปลว่า widget ต้องไปโหมดกรอบ */
        val isCutout: Boolean,
    ) {
        companion object {
            fun framed(ui: Bitmap): Result = Result(ui, false)
        }
    }

    // MARK: เกณฑ์

    /** ด้านของกริดที่ใช้สแกน — ไม่ต้องอ่านทุกพิกเซลของรูป 12MP เพื่อตอบคำถามสองข้อนี้ */
    private const val grid = 96
    /** อัลฟาต่ำกว่านี้ถือว่าใส (ไม่ใช่ 0 — ขอบที่ถูก antialias มีค่าเศษติดมาเสมอ) */
    private const val clearLevel = 16
    /** ต้องมีพื้นที่ใสอย่างน้อยเท่านี้ถึงจะเรียกว่ารูปตัด */
    private const val minClearRatio = 0.12
    /** ด้านของหย่อมมุมที่เอามาตรวจ — กี่ส่วนของด้านภาพ */
    private const val cornerPatch = 0.14
    /** สี่มุมรวมกันต้องใสอย่างน้อยเท่านี้ */
    private const val cornerClearRatio = 0.55
    /** ตัวแบบต้องกินพื้นที่อย่างน้อยเท่านี้ — ต่ำกว่านี้คือเศษขยะ ไม่ใช่คน */
    private const val minSubjectRatio = 0.02
    /** เผื่อขอบรอบตัวแบบตอนครอป — เงาและเส้นผมที่จางมากอยู่นอกกริดหยาบ ๆ ได้ */
    private const val padRatio = 0.015f

    // MARK: ทางเข้า

    fun inspect(ui: Bitmap): Result {
        if (!hasAlphaChannel(ui)) return Result.framed(ui)
        val a = alphaGrid(ui) ?: return Result.framed(ui)
        if (!looksCut(a)) return Result.framed(ui)
        val box = subjectBox(a) ?: return Result.framed(ui)
        val out = crop(ui, box) ?: return Result.framed(ui)
        // กันภาพที่ครอปแล้วเหลือเศษ — ถ้าปล่อยผ่าน widget จะยืดของกว้าง 3 พิกเซลเต็มกรอบ
        if (out.width < 24 || out.height < 24) return Result.framed(ui)
        return Result(out, true)
    }

    /**
     * ครอปรูปที่ **รู้อยู่แล้วว่าตัดมา** (ผลของ `PhotoLift`) — ข้ามเกณฑ์ `looksCut`
     * คนครึ่งตัวที่กินเต็มเฟรมจะชนมุมล่างทั้งสองมุมแล้วตกเกณฑ์มุมใส
     */
    fun trim(ui: Bitmap): Result {
        val a = alphaGrid(ui) ?: return Result.framed(ui)
        val box = subjectBox(a) ?: return Result.framed(ui)
        val out = crop(ui, box) ?: return Result.framed(ui)
        if (out.width < 24 || out.height < 24) return Result.framed(ui)
        return Result(out, true)
    }

    // MARK: ขั้นตอน
    //
    // `upright` ของ iOS ไม่จำเป็น — Bitmap ของ Android ไม่มี orientation แยก (ImageDecoder หมุนให้ตอนถอดรหัส)

    private fun hasAlphaChannel(b: Bitmap): Boolean = b.hasAlpha()

    /**
     * อ่าน alpha ลงกริดเล็ก — แถวที่ 0 คือ **ขอบบน** ของภาพ (ต่างจาก CGContext ของ iOS ที่แกน y ชี้ขึ้น)
     * ห้าม interpolate — การเฉลี่ยจะลากพิกเซลใสกับทึบมาผสมกัน แล้วขอบนอกของรูปตัดกลายเป็นครึ่งทึบทั้งวง
     */
    private fun alphaGrid(b: Bitmap): IntArray? {
        val n = grid
        val px = IntArray(n * n)
        val ok = runCatching {
            val small = Bitmap.createScaledBitmap(b, n, n, false)
            small.getPixels(px, 0, n, 0, 0, n, n)
            if (small !== b) small.recycle()
        }.isSuccess
        if (!ok) return null
        val a = IntArray(n * n)
        for (i in 0 until n * n) a[i] = (px[i] ushr 24) and 0xFF
        return a
    }

    /**
     * รูปใบนี้ถูกตัดพื้นหลังมาไหม — สองเกณฑ์ที่รูปถ่ายเต็มเฟรมไม่มีวันผ่านทั้งคู่:
     * **มีพื้นที่ใสจริงพอสมควร** และ **มุมส่วนใหญ่ว่าง** (ตัวแบบชนขอบได้ แต่ไม่มีทางเต็มทั้งสี่มุมพร้อมกัน)
     */
    private fun looksCut(a: IntArray): Boolean {
        val n = grid
        var clear = 0
        for (v in a) if (v < clearLevel) clear += 1
        if (clear.toDouble() / (n * n) < minClearRatio) return false

        val c = max(2, (n * cornerPatch).toInt())
        var total = 0
        var open = 0
        for ((ox, oy) in listOf(0 to 0, (n - c) to 0, 0 to (n - c), (n - c) to (n - c))) {
            for (y in oy until (oy + c)) {
                for (x in ox until (ox + c)) {
                    total += 1
                    if (a[y * n + x] < clearLevel) open += 1
                }
            }
        }
        if (total <= 0) return false
        return open.toDouble() / total >= cornerClearRatio
    }

    /** กรอบของส่วนที่ทึบ — คืนเป็นสัดส่วน 0–1 ของภาพ แกน y ชี้ลงจากขอบบน */
    private fun subjectBox(a: IntArray): Rect? {
        val n = grid
        var minX = n
        var maxX = -1
        var minY = n
        var maxY = -1
        var solid = 0
        for (y in 0 until n) {
            for (x in 0 until n) {
                if (a[y * n + x] < clearLevel) continue
                solid += 1
                if (x < minX) minX = x
                if (x > maxX) maxX = x
                if (y < minY) minY = y
                if (y > maxY) maxY = y
            }
        }
        if (maxX < minX || maxY < minY || solid.toDouble() / (n * n) < minSubjectRatio) return null
        val s = n.toFloat()
        return Rect(
            left = minX / s,
            top = minY / s,
            right = (maxX + 1) / s,
            bottom = (maxY + 1) / s,
        )
    }

    /**
     * ครอปตามสัดส่วนที่ได้ — เผื่อขอบเล็กน้อยแล้วรูดกลับเข้าในภาพเสมอ
     * กรอบที่กินเกือบทั้งใบอยู่แล้วไม่ครอป — ครอปไป 1–2% ไม่ได้อะไรนอกจากภาพใหม่อีกใบในหน่วยความจำ
     */
    private fun crop(b: Bitmap, box: Rect): Bitmap? {
        if (box.width >= 0.97f && box.height >= 0.97f) return b
        val w = b.width.toFloat()
        val h = b.height.toFloat()
        val pad = max(box.width * w, box.height * h) * padRatio
        val left = max(0f, box.left * w - pad)
        val top = max(0f, box.top * h - pad)
        val right = min(w, box.right * w + pad)
        val bottom = min(h, box.bottom * h + pad)
        val x = floor(left).toInt()
        val y = floor(top).toInt()
        val cw = min(b.width - x, (right - left).roundToInt())
        val ch = min(b.height - y, (bottom - top).roundToInt())
        if (cw < 1 || ch < 1) return null
        return runCatching { Bitmap.createBitmap(b, x, y, cw, ch) }.getOrNull()
    }
}

// MARK: - แคชผลการตรวจ

/**
 * ผลการตรวจของรูปแต่ละใบ — คิดครั้งเดียวต่อหนึ่งใบ
 * **ไม่ใช่ state ที่ Compose สังเกต** ตั้งใจ: ถูกอ่านระหว่างวาดแล้วเขียนแคชกลับทันที ถ้าสังเกตได้จะวนวาดใหม่ไม่จบ
 */
class CutoutCache private constructor() {
    companion object {
        val shared: CutoutCache by lazy { CutoutCache() }
    }

    /** กุญแจคือตัวตนของ Bitmap (= `ObjectIdentifier`) ไม่ใช่ค่าพิกเซล */
    private val store = IdentityHashMap<Bitmap, Cutout.Result>()

    fun result(image: Bitmap): Cutout.Result {
        store[image]?.let { return it }
        val r = Cutout.inspect(image)
        store[image] = r
        return r
    }
}
