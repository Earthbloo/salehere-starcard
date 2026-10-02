package co.salehere.starcard.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import co.salehere.starcard.theme.CardTheme

/**
 * ประวัติแก้ไขของการ์ดหนึ่งใบ — ภาพนิ่งของ `pages` + `theme` ต่อหนึ่งจังหวะ
 *
 * แถบเครื่องมือล่างไม่มีปุ่ม "ยกเลิก" — ทุกตัวเลือกมีผลบนการ์ดทันทีที่แตะ ทางกลับทางเดียวจึงเป็น ↶ ↷
 * ลากแถบสีหนึ่งครั้งเปลี่ยนค่าเป็นสิบ ๆ รอบ — การเปลี่ยนที่ติดกันภายใน `coalesce` จึงนับเป็นจังหวะเดียว
 *
 * (Swift เป็น struct ที่มี `mutating` — ฝั่งนี้เป็น class ที่แก้ตัวเองได้ · `past`/`future` เป็น state
 * ให้ Compose อ่าน `canUndo`/`canRedo` แล้ววาดปุ่มใหม่ได้)
 */
class EditHistory {
    data class Snapshot(val pages: List<CardPage>, val theme: CardTheme)

    var past: List<Snapshot> by mutableStateOf(emptyList())
        private set
    var future: List<Snapshot> by mutableStateOf(emptyList())
        private set
    /** เวลาบันทึกครั้งล่าสุด (epoch millis) */
    private var lastRecord: Long = 0

    val canUndo: Boolean get() = past.isNotEmpty()
    val canRedo: Boolean get() = future.isNotEmpty()

    /** บันทึกสถานะ **ก่อนเปลี่ยน** — เรียกจาก `onChange` โดยส่งค่าเก่าเข้ามา */
    fun record(before: Snapshot) {
        val now = System.currentTimeMillis()
        try {
            // แก้อะไรใหม่ = ทางไปข้างหน้าที่เคยย้อนไว้หมดความหมาย
            future = emptyList()
            if ((now - lastRecord) / 1000.0 < coalesce && past.isNotEmpty()) return
            var next = past + before
            if (next.size > cap) next = next.drop(1)
            past = next
        } finally {
            lastRecord = now
        }
    }

    fun undo(current: Snapshot): Snapshot? {
        val s = past.lastOrNull() ?: return null
        past = past.dropLast(1)
        future = future + current
        lastRecord = 0
        return s
    }

    fun redo(current: Snapshot): Snapshot? {
        val s = future.lastOrNull() ?: return null
        future = future.dropLast(1)
        past = past + current
        lastRecord = 0
        return s
    }

    companion object {
        /** วินาที — การเปลี่ยนที่ติดกันในช่วงนี้นับเป็นจังหวะเดียว */
        private const val coalesce: Double = 0.6
        private const val cap = 80
    }
}
