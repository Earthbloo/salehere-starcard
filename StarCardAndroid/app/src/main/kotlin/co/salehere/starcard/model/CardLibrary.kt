package co.salehere.starcard.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import co.salehere.starcard.AppContext
import co.salehere.starcard.theme.CardTheme
import java.util.UUID
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer

// MARK: - คลังการ์ดหลายใบ (= Model/CardLibrary.swift)
//
// `CardStore` เกิดมาเพื่อกันงานหายระหว่างพัฒนา — หนึ่งช่องต่อรูปแบบ เลือกเทมเพลตใหม่คือทับทิ้ง
// แต่ use case จริงของครีเอเตอร์คือ **การ์ดหลายใบพร้อมกัน** — แต่ละใบมีลิงก์ของตัวเอง
// และมีใบเดียวที่เป็น "ใบหลัก" — ใบที่ลิงก์ประจำตัวชี้ไป
// ยังเป็นที่เก็บฝั่งเครื่อง (SharedPreferences) — ของจริงย้ายขึ้น API ได้ทั้งก้อน เพราะบันทึกด้วย `CardSnapshot`

/** การ์ดหนึ่งใบในคลัง (วันที่เป็น epoch millis — iOS เก็บเป็น `Date`) */
@Serializable
data class CardRecord(
    val id: String,
    var name: String,
    var formatRaw: String,
    var snapshot: CardSnapshot,
    var createdAt: Long,
    var updatedAt: Long,
) {
    val format: CardFormat get() = CardFormat.from(formatRaw) ?: CardFormat.portfolio

    /** ท้ายลิงก์เฉพาะใบ — สั้นพอพูดต่อโทรศัพท์ได้ ยาวพอไม่ชนกันในคลังเดียว */
    val shortID: String get() = id.take(6).lowercase()

    override fun equals(other: Any?): Boolean =
        other is CardRecord && other.id == id && other.updatedAt == updatedAt && other.name == name

    override fun hashCode(): Int {
        var h = id.hashCode()
        h = 31 * h + updatedAt.hashCode()
        h = 31 * h + name.hashCode()
        return h
    }
}

/** คลังการ์ดของเครื่องนี้ + ตัวชี้ว่าใบไหนคือใบหลัก */
class CardLibrary private constructor() {
    var records: List<CardRecord> by mutableStateOf(emptyList())
        private set

    /**
     * ใบที่ลิงก์ประจำตัว (`star/<handle>`) ชี้ไป — ใบเดียวเสมอ
     * เก็บเป็น id ไม่ใช่ index เพราะลำดับในคลังเปลี่ยนได้ตลอด (เรียงตามแก้ล่าสุด)
     */
    var publishedID: String? by mutableStateOf(null)
        private set

    val isEmpty: Boolean get() = records.isEmpty()

    /** เรียงโชว์: ใบหลักขึ้นก่อนเสมอ ที่เหลือใหม่สุดก่อน — ใบที่คนอื่นเห็นต้องหาเจอใน 0 วินาที */
    val displayOrder: List<CardRecord>
        get() = records.sortedWith { a, b ->
            when {
                a.id == publishedID && b.id != publishedID -> -1
                b.id == publishedID && a.id != publishedID -> 1
                else -> b.updatedAt.compareTo(a.updatedAt)
            }
        }

    init {
        load()
        migrateLegacyDrafts()
    }

    // MARK: อ่าน/เขียนดิสก์

    private fun load() {
        val d = AppContext.prefs
        d.getString(recordsKey, null)?.let { data ->
            runCatching { CardStore.json.decodeFromString(ListSerializer(CardRecord.serializer()), data) }
                .getOrNull()?.let { records = it }
        }
        publishedID = d.getString(publishedKey, null)
        // ตัวชี้ห้ามชี้ไปใบที่ไม่มีอยู่ — เกิดได้ตอนลบใบหลักแล้วแอปดับกลางทาง
        val p = publishedID
        if (p != null && records.none { it.id == p }) {
            publishedID = records.firstOrNull()?.id
        }
    }

    private fun persist() {
        val e = AppContext.prefs.edit()
        runCatching { CardStore.json.encodeToString(ListSerializer(CardRecord.serializer()), records) }
            .getOrNull()?.let { e.putString(recordsKey, it) }
        val p = publishedID
        if (p == null) e.remove(publishedKey) else e.putString(publishedKey, p)
        e.apply()
    }

    /**
     * ยกร่างเก่าจากระบบช่องเดียว (`CardStore`) เข้าคลัง — งานที่ค้างไว้ก่อนมีคลังต้องไม่หาย
     * ทำครั้งเดียวตอนคลังยังว่าง แล้วล้างช่องเก่าทิ้งกันไม่ให้ถูกยกซ้ำ
     */
    private fun migrateLegacyDrafts() {
        if (records.isNotEmpty()) return
        for (format in CardFormat.entries) {
            val saved = CardStore.load(format) ?: continue
            val record = record(
                name = "การ์ดของฉัน",
                format = format,
                pages = saved.pages, theme = saved.theme, index = saved.index,
            )
            records = records + record
            CardStore.clear(format)
        }
        if (publishedID == null) publishedID = records.firstOrNull()?.id
        if (records.isNotEmpty()) persist()
    }

    // MARK: คำสั่งหลัก

    /**
     * เปิดใบใหม่จากเทมเพลต — ตั้งชื่อตามเทมเพลตให้ก่อน
     * ใบแรกของคลังเป็นใบหลักอัตโนมัติ: ยังไม่มีใบอื่นให้เลือก และลิงก์ประจำตัวต้องมีปลายทางเสมอ
     */
    fun create(template: CardTemplate): CardRecord {
        val record = record(
            name = template.name,
            format = template.format,
            pages = template.makePages(), theme = template.theme, index = 0,
        )
        records = records + record
        if (publishedID == null) publishedID = record.id
        persist()
        return record
    }

    /** สำเนาไว้ลองแก้ — ทางที่ปลอดภัยของ "อยากลองเปลี่ยนโดยไม่แตะใบที่ส่งไปแล้ว" */
    fun duplicate(id: String): CardRecord? {
        val src = records.firstOrNull { it.id == id } ?: return null
        val copy = record(
            name = src.name + " (สำเนา)",
            format = src.format,
            pages = emptyList(), theme = CardTheme(), index = 0,
        ).copy(snapshot = src.snapshot)
        records = records + copy
        persist()
        return copy
    }

    fun card(id: String): CardRecord? = records.firstOrNull { it.id == id }

    /** บันทึกงานแก้ — จุดเดียวที่ห้องแต่งเขียนกลับ */
    fun save(id: String, pages: List<CardPage>, theme: CardTheme, index: Int) {
        val i = records.indexOfFirst { it.id == id }
        if (i < 0) return
        records = records.toMutableList().also { list ->
            list[i] = list[i].copy(
                snapshot = CardStore.snapshot(pages, theme, index),
                updatedAt = System.currentTimeMillis(),
            )
        }
        persist()
    }

    /** เปลี่ยนชื่อใบ — ชื่อคือเครื่องมือแยกใบตอนคลังโต ("ใบส่ง Cathy Doll" ต้องตั้งได้) */
    fun rename(id: String, to: String) {
        val trimmed = to.trim()
        if (trimmed.isEmpty()) return
        val i = records.indexOfFirst { it.id == id }
        if (i < 0) return
        records = records.toMutableList().also { list -> list[i] = list[i].copy(name = trimmed) }
        persist()
    }

    /** ตั้งใบหลัก — สลับตัวชี้เฉย ๆ ไม่มีอะไรถูกลบหรือทับ จึงไม่ต้องมีหน้าต่างยืนยัน */
    fun setPublished(id: String) {
        if (records.none { it.id == id }) return
        publishedID = id
        persist()
    }

    /** ลบใบ — ถ้าลบใบหลัก ตัวชี้ตกไปใบล่าสุดที่เหลือ ลิงก์ประจำตัวไม่มีวันชี้ไปความว่างเปล่า */
    fun delete(id: String) {
        records = records.filterNot { it.id == id }
        if (publishedID == id) publishedID = displayOrder.firstOrNull()?.id
        persist()
    }

    // MARK: โหมดลองทำ (ดู `LabSync`)

    /** ให้คลังเหลือใบเดียว = การ์ดกลาง · ใบอื่นไม่หายจริง อยู่ในข้อมูลที่ `LabMode` สำรองไว้ */
    fun labKeepOnly(id: String) {
        if (records.none { it.id == id }) return
        records = records.filter { it.id == id }
        publishedID = id
        persist()
    }

    /** ใส่การ์ดกลางที่รับมาจากเครื่องอื่น — มีใบอยู่แล้วทับใบนั้น ไม่มีสร้างใหม่ · คืน id ของใบ */
    fun labUpsert(id: String?, name: String, format: CardFormat, snapshot: CardSnapshot): String {
        val now = System.currentTimeMillis()
        val i = if (id != null) records.indexOfFirst { it.id == id } else -1
        val keep: CardRecord = if (i >= 0) {
            records[i].copy(name = name, formatRaw = format.raw, snapshot = snapshot, updatedAt = now)
        } else {
            CardRecord(
                id = UUID.randomUUID().toString(), name = name, formatRaw = format.raw,
                snapshot = snapshot, createdAt = now, updatedAt = now,
            )
        }
        records = listOf(keep)
        publishedID = keep.id
        persist()
        return keep.id
    }

    // MARK: ลิงก์

    /** ลิงก์ของใบนั้น — ใบหลักได้ลิงก์ประจำตัวสั้น ๆ ที่เหลือได้ลิงก์เฉพาะใบ */
    fun url(record: CardRecord, slug: String): String {
        val base = "https://${ClipInvocation.host}/star/$slug"
        return if (record.id == publishedID) base else "$base/c/${record.shortID}"
    }

    /** แบบสั้นไว้โชว์บนการ์ด — คนอ่านไม่ต้องเห็น https:// */
    fun urlDisplay(record: CardRecord, slug: String): String =
        url(record, slug).removePrefix("https://")

    companion object {
        val shared: CardLibrary by lazy { CardLibrary() }

        private const val recordsKey = "starcard.library.v1"
        private const val publishedKey = "starcard.library.published"

        // MARK: ประกอบ record

        private fun record(name: String, format: CardFormat, pages: List<CardPage>, theme: CardTheme, index: Int): CardRecord {
            val now = System.currentTimeMillis()
            return CardRecord(
                id = UUID.randomUUID().toString(),
                name = name,
                formatRaw = format.raw,
                snapshot = CardStore.snapshot(pages, theme, index),
                createdAt = now,
                updatedAt = now,
            )
        }
    }
}
