package co.salehere.starcard.layout

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import co.salehere.starcard.model.WidgetInstance
import co.salehere.starcard.model.WidgetKind
import java.util.UUID
import kotlin.math.floor

/** ตำแหน่งที่คำนวณแล้วของ widget หนึ่งตัว — พิกัดในหน่วยออกแบบ อ้างมุมบนซ้ายของหน้า */
data class Placed(val item: WidgetInstance, val frame: Rect) {
    val id: UUID get() = item.id
}

/** `CGRect(x:y:width:height:)` — Compose `Rect` รับขอบซ้าย/บน/ขวา/ล่าง */
internal fun rect(x: Float, y: Float, width: Float, height: Float): Rect = Rect(x, y, x + width, y + height)

/** `.rounded()` ของ Swift — ครึ่งปัดออกจากศูนย์ (Kotlin `roundToInt` ปัดครึ่งขึ้นบวก ซึ่งต่างกันที่ค่าลบ) */
private fun rounded(v: Float): Float = if (v >= 0f) floor(v + 0.5f) else -floor(-v + 0.5f)

/**
 * ผังหน้าแบบ **พิกเซล** — วาง/ยืดได้อิสระในหน่วยออกแบบ ไม่มีคอลัมน์และแถวอีกแล้ว
 *
 * กริด 6 คอลัมน์เป็นหน่วย **สัมพัทธ์** — ขนาดของ widget ไม่ใช่ของที่คนแต่งคุมได้จริง
 * พอพื้นที่ออกแบบถูกตรึงเป็น 540pt ทุกเครื่อง หน่วยที่ถูกต้องจึงเป็น **pt ตรง ๆ**
 *
 * กติกาที่ยังอยู่เหมือนเดิม: ของต้อง **อยู่ในหน้า** และ **ห้ามทับกัน**
 */
object PageLayout {
    /**
     * ขั้นการสแนปตอนลาก/ยืด — 6pt ในหน่วยออกแบบ = 12px ที่ @2x
     * ละเอียดพอให้รู้สึกว่าวางได้อิสระ แต่ยังหยาบพอให้ของสองชิ้นที่ "ตั้งใจให้ตรงกัน" ลงมาตรงกันจริง
     */
    const val step: Float = 6f

    /**
     * ขอบกระดาษ — ระยะที่ระบบ **เว้นให้เอง** ตอนวางของใหม่
     * 18 คือค่าเดียวกับที่พอร์ตเคยได้จากสูตรสัดส่วน (0.045 × 402)
     * **ไม่ใช่กำแพง** — ผู้ใช้ลากและยืดข้ามมันไปจนสุดขอบหน้าได้ (ดู `bounds`)
     */
    const val margin: Float = 18f

    /**
     * ระยะเว้นที่ระบบใช้ **ตอนหาที่วางให้อัตโนมัติ** เท่านั้น
     * ผู้ใช้จะลากให้ชิดกว่านี้เองก็ได้ — นี่ไม่ใช่กติกา แค่รสนิยมตอนวางแทน
     */
    const val gap: Float = 10f

    /** เล็กสุดที่ยังเป็นของที่อ่านออก ไม่ใช่เศษ (100 ≈ ความกว้างที่ widget แคบสุดในตู้ใช้อยู่จริง) */
    val minSize: Size = Size(100f, 40f)

    /**
     * เล็กสุด **ต่อชนิด** — ก้อนข้อความคือตัวอักษรพอดี (ดู `CardScreen.fitTextBlock`)
     * ตัวอักษร 9pt ได้กล่องราว 40×15 ถ้าบังคับ 100×40 เท่าวิดเจ็ตอื่น กล่องจะใหญ่กว่าตัวอักษรสามเท่า
     */
    fun minSize(kind: WidgetKind): Size = if (kind == WidgetKind.textBlock) Size(8f, 8f) else minSize

    // MARK: - ขอบเขตของหน้า

    /**
     * **เพดานจริงของหน้า** — ทั้งแผ่น ไม่หักขอบ
     * ขอบกระดาษยังอยู่ แต่ย้ายไปเป็น *ค่าตั้งต้นตอนระบบวางของให้* (`content`) แทนที่จะเป็นกำแพง —
     * ของที่แอปวางเองยังเว้นขอบสวยเหมือนเดิม ส่วนคนที่อยากได้ full-bleed ก็ลากไปชนขอบได้
     */
    fun bounds(page: Size): Rect =
        rect(0f, 0f, maxOf(page.width, minSize.width), maxOf(page.height, minSize.height))

    /**
     * พื้นที่ที่ระบบใช้ **ตอนหาที่วางให้อัตโนมัติ** (หักขอบกระดาษแล้ว)
     * ขอบเท่ากันทั้งสี่ด้าน — แถบผู้ออกบัตรถูกถอดออกจากการ์ดแล้ว ก้นหน้าจึงไม่ต้องกันที่ให้ใคร
     */
    fun content(page: Size): Rect =
        rect(margin, margin, maxOf(page.width - margin * 2, minSize.width), maxOf(page.height - margin * 2, minSize.height))

    /** ปัดค่าลงขั้นสแนปที่ใกล้ที่สุด */
    fun snap(v: Float): Float = rounded(v / step) * step

    fun snap(p: Offset): Offset = Offset(snap(p.x), snap(p.y))

    /**
     * รูดกรอบให้อยู่ในหน้าเสมอ — จำกัด**ขนาด**ก่อน แล้วค่อยรูด**ตำแหน่ง**
     * ลำดับนี้สำคัญ: ถ้ารูดตำแหน่งก่อน ของที่ใหญ่เกินหน้าจะถูกดันไปติดขอบซ้ายบน แล้วค่อยถูกหั่นขนาด
     */
    fun clamp(r: Rect, page: Size, min: Size = minSize): Rect {
        val box = bounds(page)
        val w = minOf(maxOf(r.width, min.width), box.width)
        val h = minOf(maxOf(r.height, min.height), box.height)
        return rect(
            minOf(maxOf(r.left, box.left), box.right - w),
            minOf(maxOf(r.top, box.top), box.bottom - h),
            w, h,
        )
    }

    /** รูดกรอบของ *ชิ้น* เข้าหน้า — กรอบยืดอิสระแล้ว จึงรูดทีละแกนตามกติกาของหน้า */
    fun clamp(item: WidgetInstance, page: Size): Rect = clamp(item.rect, page, minSize(item.kind))

    /**
     * ขนาดที่ยังยืดได้จากมุมนั้นไปทางขวา / ลงล่าง — ใช้จำกัดตอนลากหมุด
     * เพดานคือ **ขอบหน้า** ไม่ใช่ขอบกระดาษ หมุดจึงลากจนภาพเต็มขอบได้
     */
    fun roomWidth(from: Float, page: Size): Float = maxOf(minSize.width, bounds(page).right - from)
    fun roomHeight(from: Float, page: Size): Float = maxOf(minSize.height, bounds(page).bottom - from)

    // MARK: - วางในหนึ่งหน้า

    /**
     * วางทุกตัวตามพิกัดที่มันถือไว้ **แล้วดันลงจนไม่มีใครทับใคร**
     * พิกัดที่ถูกดัน **ไม่ถูกเขียนกลับลงตัว item** โดยตั้งใจ — ย้ายตัวที่ขวางออกเมื่อไหร่ ของที่ถูกดันก็เด้งกลับขึ้นที่เดิมเอง
     *
     * @param first id ของตัวที่ต้อง **ได้ที่ที่มันขอก่อนใคร** — ใช้ตอนลาก: ตัวที่นิ้วจับต้องชนะเสมอ
     */
    fun solve(items: List<WidgetInstance>, page: Size, first: UUID? = null): List<Placed> {
        if (!(page.width > 0 && page.height > 0)) return emptyList()
        val spot = slots(items, page, first)
        return items.map { Placed(item = it, frame = spot[it.id] ?: clamp(it, page)) }
    }

    /**
     * กรอบที่แต่ละตัว **ได้จริง** หลังดันกันแล้ว — แยกจาก `solve` เพราะมีสองคนใช้
     * `solve` ใช้ตอนวาด ส่วน `CardScreen.endDrag` ใช้ตอนปล่อยนิ้วเพื่อเขียนผลกลับลงข้อมูลจริง
     */
    fun slots(items: List<WidgetInstance>, page: Size, first: UUID? = null): Map<UUID, Rect> {
        // กำแพงคือขอบหน้า — ของที่ผู้ใช้ลากไปชนขอบต้อง **อยู่ที่เดิม** ไม่ใช่ถูกดีดกลับเข้าขอบกระดาษ
        val box = bounds(page)
        // ส่วนตอนที่ระบบเป็นคนหาที่ให้ ยังเว้นขอบกระดาษเหมือนเดิม (ดู `margin`)
        val polite = content(page)
        val order = items.withIndex().sortedWith { a, b ->
            if (first != null) {
                if (a.value.id == first && b.value.id != first) return@sortedWith -1
                if (b.value.id == first && a.value.id != first) return@sortedWith 1
            }
            if (a.value.y != b.value.y) return@sortedWith a.value.y.compareTo(b.value.y)
            if (a.value.x != b.value.x) return@sortedWith a.value.x.compareTo(b.value.x)
            // ลำดับในลิสต์เป็นตัวตัดสินสุดท้าย — ผลลัพธ์จึงคงที่ทุกครั้งที่คำนวณใหม่
            a.index.compareTo(b.index)
        }

        val taken = mutableListOf<Rect>()
        val spot = mutableMapOf<UUID, Rect>()

        // หดเข้ามาครึ่งจุดก่อนเทียบ — ของที่ขอบชนกันพอดีไม่ใช่ของที่ทับกัน
        fun free(r: Rect): Boolean {
            if (!(r.left >= box.left - 0.01f && r.top >= box.top - 0.01f &&
                    r.right <= box.right + 0.01f && r.bottom <= box.bottom + 0.01f)) return false
            val probe = r.deflate(0.5f)
            return taken.none { it.overlaps(probe) }
        }

        for ((_, item) in order) {
            val want = clamp(item, page)
            var put: Rect? = null

            // 1) ดันลงตรง ๆ ในแนวเดิม — ท่าปกติ ของขยับน้อยที่สุด
            var y = want.top
            while (y + want.height <= box.bottom + 0.01f) {
                val r = rect(want.left, y, want.width, want.height)
                if (free(r)) { put = r; break }
                y += step
            }

            // 2) แนวเดิมเต็มถึงก้นหน้าแล้ว — กวาดหาที่ว่างแรกทั้งหน้า บนลงล่าง ซ้ายไปขวา
            //    กวาดหยาบกว่าขั้นสแนป (4 เท่า) เพราะขั้นนี้วิ่งระหว่างลาก
            if (put == null) {
                val coarse = step * 4
                // ตัวที่ใหญ่เกินกรอบสุภาพ (เช่นใบที่ยืดเต็มขอบ) ต้องกวาดทั้งหน้า
                val sweep = if (want.width <= polite.width && want.height <= polite.height) polite else box
                outer@ for (yy in strideThrough(sweep.top, sweep.bottom - want.height, coarse)) {
                    for (xx in strideThrough(sweep.left, sweep.right - want.width, coarse)) {
                        val r = rect(xx, yy, want.width, want.height)
                        if (free(r)) { put = r; break@outer }
                    }
                }
            }

            // 3) หน้าเต็มจริง ๆ — ยอมทับที่ก้นหน้า ดีกว่าดันหลุดออกนอกหน้าซึ่งพิมพ์ไม่ติด
            val final = put ?: rect(want.left, box.bottom - want.height, want.width, want.height)
            taken.add(final)
            spot[item.id] = final
        }

        return spot
    }

    /**
     * ความกว้างที่ยัง **ว่างจริง** จากจุดนั้นไปทางขวา ตลอดช่วงความสูงนั้น
     * ผู้ใช้ย่อ widget ตัวแรกเหลือครึ่งหน้า แล้วลากตัวที่สองไปวางข้าง ๆ — ต้อง **วางคู่กันได้** ทั้งที่ที่ว่างมีอยู่จริง
     */
    fun freeWidth(from: Float, y: Float, height: Float, page: Size, avoiding: List<WidgetInstance>, excluding: UUID?): Float {
        val box = bounds(page)
        val top = minOf(maxOf(y, box.top), box.bottom - minOf(height, box.height))
        val band = rect(box.left, top, box.width, minOf(height, box.height))
        var limit = box.right
        for (item in avoiding) {
            if (item.id == excluding) continue
            val r = clamp(item, page)
            if (!(r.top < band.bottom - 0.5f && r.bottom > band.top + 0.5f)) continue
            if (r.left >= from - 0.5f) limit = minOf(limit, r.left)
        }
        return maxOf(0f, limit - from)
    }

    /**
     * ที่ว่างแรกที่ของขนาดนี้ลงได้โดยไม่ทับใคร — ไล่บนลงล่าง ซ้ายไปขวา เว้นระยะ `gap`
     * คืน null เมื่อหน้าไม่เหลือที่พอ — **ผู้เรียกต้องไม่ยัดของลงหน้านั้นต่อ**
     */
    fun freeSpot(size: Size, page: Size, avoiding: List<WidgetInstance>): Offset? {
        val box = content(page)
        val w = minOf(maxOf(size.width, minSize.width), box.width)
        val h = minOf(maxOf(size.height, minSize.height), box.height)
        val taken = avoiding.map { clamp(it, page).inflate(gap / 2) }

        for (y in strideThrough(box.top, box.bottom - h, step)) {
            for (x in strideThrough(box.left, box.right - w, step)) {
                val r = rect(x, y, w, h)
                if (taken.none { it.overlaps(r) }) return Offset(x, y)
            }
        }
        return null
    }

    /** `stride(from:through:by:)` ของ Swift — คิดจาก `from + i·by` ไม่สะสมค่าลอย · ว่างเมื่อ `through < from` */
    private fun strideThrough(from: Float, through: Float, by: Float): Sequence<Float> = sequence {
        if (by <= 0f || through < from) return@sequence
        var i = 0
        while (true) {
            val v = from + i * by
            if (v > through) break
            yield(v)
            i++
        }
    }
}
