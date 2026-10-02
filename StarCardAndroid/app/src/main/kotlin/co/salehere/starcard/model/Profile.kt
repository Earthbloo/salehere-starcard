package co.salehere.starcard.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.text.input.KeyboardType
import co.salehere.starcard.AppContext
import co.salehere.starcard.theme.VerifiedFacts
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

// MARK: - โปรไฟล์ที่แก้ได้จริง (= Profile.swift)
//
// ทุก widget เคยอ่าน `Mock.creator` ตรง ๆ — การ์ดจึงเป็นของนิรา ภัทรวดี เสมอ
// ไฟล์นี้คั่นระหว่าง widget กับข้อมูล: ฟิลด์ไหนที่เจ้าของการ์ดพิมพ์เองได้ จะอ่านผ่านตัวนี้แทน
//
// ที่เก็บเดียว — การ์ดกับฟอร์มอ่านเขียนก้อนเดียวกัน:
// * `values` / `list` / `notes` — ข้อความที่พิมพ์ · `intake` — ของจากฟอร์มที่ไม่ใช่ข้อความ ·
// * `creator` — โปรไฟล์ที่ **widget อ่าน** ประกอบจากสองก้อนบน + ข้อมูลระบบ
//
// singleton ไม่ใช่ CompositionLocal: widget อ่านค่าจาก 3 ที่ที่ไม่ได้อยู่ใต้ต้นไม้เดียวกัน
// (แคนวาส · พรีวิวในตู้ widget · ตัวเรนเดอร์รูปตอนแชร์) — `mutableStateOf` ทำให้ Compose ตามการอ่านได้เหมือน `@Observable`

/**
 * ช่องข้อความที่เจ้าของการ์ดพิมพ์เองได้
 * `raw` ตั้งให้ตรงกับ `key` ใน `FamilyContract.editable` เพื่อให้ mapping กับ API เป็น 1:1
 */
enum class ProfileField(val raw: String) {
    personName("name"), tagline("tagline"), about("about"), quote("quote"), handle("handle"),
    /** ข้อความอิสระของวิดเจ็ต `ข้อความ` — **ช่องเดียวที่เก็บต่อชิ้น ไม่ใช่ต่อการ์ด** (ดู `TextSlotID.widget`) */
    note("note"),
    /** ชื่อเล่นที่ขึ้นเป็นตัวยักษ์ทับภาพ — **ฟิลด์ของตัวเอง ไม่ใช่คำแรกของชื่อ** (ค่าตั้งต้นยังเป็นคำแรกของชื่อ) */
    nickname("nickname"),
    contactName("contactName"), role("role"), phone("phone"), email("email"), lineId("lineId"),
    /** สายงานที่พิมพ์เอง — เป็นรายการ จึงอ้างด้วย `index` เสมอ */
    categories("categories"),
    /** ชื่อรายการกับราคาในเรตการ์ด — รายการคู่ขนาน ลำดับที่ `i` ของสองช่องคือเรตอันเดียวกัน · เมื่อมีฟอร์มแล้ว = มุมมองของ `intake.rates` */
    rateLabels("rateLabels"), ratePrices("ratePrices"),
    /** พื้นที่รับงาน — จังหวัด/เมืองที่รับงานได้ (ป้ายชื่อสติกเกอร์) */
    workArea("workArea"),
    /** สัดส่วนร่างกาย — พิมพ์ค่าพร้อมหน่วยมาเลย ("48 กก." · "31 นิ้ว") ตามธรรมเนียมวงการ */
    weight("weight"), height("height"), bust("bust"), waist("waist"), hips("hips"), shoe("shoe");

    val isList: Boolean get() = listFields.contains(this)

    val isRate: Boolean get() = this == rateLabels || this == ratePrices

    /** ลบทิ้งเมื่อพิมพ์จนว่าง — จริงเฉพาะชิปสายงาน · เรตราคาต้องไม่ลบ เพราะสองรายการเดินคู่กันด้วย `index` */
    val deletesWhenEmpty: Boolean get() = this == categories

    /** ชื่อช่องที่โชว์บนแถบพิมพ์เหนือคีย์บอร์ด — ตรงกับ `label` ใน `FamilyContract.editable` */
    val label: String get() = when (this) {
        ProfileField.personName -> "ชื่อแสดงผล"
        ProfileField.note -> "ข้อความ"
        ProfileField.tagline -> "สายงาน"
        ProfileField.about -> "แนะนำตัว"
        ProfileField.quote -> "คำพูด"
        ProfileField.handle -> "ชื่อผู้ใช้"
        ProfileField.contactName -> "ชื่อผู้รับงาน"
        ProfileField.role -> "สถานะผู้รับงาน"
        ProfileField.phone -> "เบอร์โทร"
        ProfileField.email -> "อีเมล"
        ProfileField.lineId -> "ไลน์ไอดี"
        ProfileField.categories -> "สายงานที่พิมพ์เอง"
        ProfileField.nickname -> "ชื่อเล่น"
        ProfileField.rateLabels -> "ชื่อรายการ"
        ProfileField.ratePrices -> "ราคา"
        ProfileField.workArea -> "พื้นที่รับงาน"
        ProfileField.weight -> "น้ำหนัก"
        ProfileField.height -> "ส่วนสูง"
        ProfileField.bust -> "รอบอก"
        ProfileField.waist -> "เอว"
        ProfileField.hips -> "สะโพก"
        ProfileField.shoe -> "ขนาดรองเท้า"
    }

    /** ประโยคชวนกรอก — ขึ้นบนการ์ดแทนช่องว่างเมื่อมีฟอร์มแล้วแต่ยังไม่ได้พิมพ์ช่องนี้ */
    val placeholder: String get() = when (this) {
        ProfileField.personName -> "ชื่อของคุณ"
        ProfileField.nickname -> "ชื่อเล่น"
        ProfileField.tagline -> "สายงานของคุณ"
        ProfileField.about -> "แนะนำตัวสั้น ๆ ให้แบรนด์รู้จัก"
        ProfileField.quote -> "ประโยคที่อยากบอกแบรนด์"
        ProfileField.handle -> "yourname"
        ProfileField.contactName -> "ชื่อผู้รับงาน"
        ProfileField.role -> "ติดต่อโดยตรง"
        ProfileField.phone -> "08x-xxx-xxxx"
        ProfileField.email -> "you@email.com"
        ProfileField.lineId -> "@lineid"
        ProfileField.workArea -> "จังหวัด / เมืองที่รับงาน"
        ProfileField.weight -> "— กก."
        ProfileField.height -> "— ซม."
        ProfileField.bust, ProfileField.waist, ProfileField.hips -> "— นิ้ว"
        ProfileField.shoe -> "— EU"
        ProfileField.note -> Profile.notePlaceholder
        ProfileField.categories, ProfileField.rateLabels, ProfileField.ratePrices -> ""
    }

    /** ย่อหน้าพิมพ์หลายบรรทัดได้ ที่เหลือบรรทัดเดียว */
    val isParagraph: Boolean get() = this == about || this == quote || this == note

    /** จำกัดความยาว — ค่าเดียวกับที่ `FamilyContract` ประกาศไว้ · ต้องบังคับฝั่ง API ด้วย */
    val limit: Int? get() = when (this) {
        ProfileField.personName, ProfileField.contactName, ProfileField.lineId, ProfileField.handle -> 40
        // ตัวยักษ์ทับภาพ — ยาวกว่านี้ต้องย่อจนอ่านไม่ออกก่อนถึงขอบ
        ProfileField.nickname -> 18
        ProfileField.rateLabels -> 24
        // หลักเดียวพอสำหรับราคางานจ้าง (สูงสุดหลักล้าน) — ยาวกว่านี้คือพิมพ์ผิด
        ProfileField.ratePrices -> 7
        ProfileField.tagline -> 100
        // เท่ากับ About Me ของแอป Sale Here — ข้อความเดียวกันต้องส่งกลับไปที่นั่นได้ไม่ถูกตัด
        ProfileField.about -> 200
        ProfileField.quote -> 120
        ProfileField.note -> 200
        ProfileField.role -> 60
        ProfileField.phone -> 20
        ProfileField.email -> 60
        ProfileField.categories -> 24
        ProfileField.workArea -> 30
        ProfileField.weight, ProfileField.height, ProfileField.bust, ProfileField.waist, ProfileField.hips, ProfileField.shoe -> 12
    }

    val keyboard: KeyboardType get() = when (this) {
        ProfileField.phone -> KeyboardType.Phone
        ProfileField.email -> KeyboardType.Email
        ProfileField.ratePrices -> KeyboardType.Number
        else -> KeyboardType.Text
    }

    companion object {
        private val listFields: Set<ProfileField> = setOf(categories, rateLabels, ratePrices)
        fun from(raw: String?): ProfileField? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * ที่อยู่ของช่องข้อความหนึ่งช่อง — ฟิลด์ + ลำดับ (ลำดับมีเฉพาะฟิลด์ที่เป็นรายการ)
 * เทียบเท่ากันด้วย `field` + `index` + `widget` เท่านั้น — `preset`/`hint` เป็นของดีไซน์ ไม่ใช่ตัวตนของช่อง
 */
data class TextSlotID(
    val field: ProfileField,
    /** ลำดับในรายการ — ฟิลด์รายการ (สายงาน · เรต) หรือ **ช่องอิสระช่องที่เท่าไหร่ของชิ้นนั้น** */
    val index: Int? = null,
    /** ชิ้นที่ข้อความก้อนนี้สังกัด — มีค่าเฉพาะช่องที่เก็บต่อชิ้น (ตอนนี้คือ `note` ตัวเดียว) · ช่องอื่นต้องเป็น null เสมอ */
    val widget: UUID? = null,
    /** ข้อความที่ดีไซน์ของ widget ใส่มาให้ตั้งแต่แรก — ขึ้นบนการ์ดจนกว่าเจ้าของจะพิมพ์ทับ (ไม่นับตอนเทียบว่าเป็นช่องเดียวกัน) */
    val preset: String = "",
    /** ชื่อช่องบนแถบพิมพ์ — null = ใช้ชื่อของฟิลด์ · ช่องอิสระหลายช่องในชิ้นเดียวต้องแยกกันออก */
    val hint: String? = null,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is TextSlotID) return false
        return field == other.field && index == other.index && widget == other.widget
    }

    override fun hashCode(): Int {
        var h = field.hashCode()
        h = 31 * h + (index ?: 0)
        h = 31 * h + (widget?.hashCode() ?: 0)
        return h
    }
}

/** ที่อยู่ของข้อความอิสระหนึ่งก้อน — ชิ้นไหน ช่องที่เท่าไหร่ (null = ก้อนข้อความที่มีช่องเดียว) */
private data class NoteKey(val widget: UUID, val index: Int?) {
    /** คีย์ที่เขียนลงไฟล์ — ช่องเดี่ยวยังเป็น uuid เปล่าเหมือนเดิม ไฟล์เก่าจึงอ่านได้ครบ */
    val stored: String get() = index?.let { "$widget#$it" } ?: widget.toString()

    companion object {
        fun fromStored(stored: String): NoteKey? {
            val parts = stored.split("#", limit = 2)
            val id = runCatching { UUID.fromString(parts.firstOrNull() ?: "") }.getOrNull() ?: return null
            return NoteKey(id, if (parts.size > 1) parts[1].toIntOrNull() else null)
        }
    }
}

class Profile private constructor() {

    companion object {
        /** การ์ดใบเดียวต่อแอป — ยังไม่มีสถานะ "หลายการ์ด" จึงไม่ต้องมีตัวจัดการที่ซับซ้อนกว่านี้ */
        val me: Profile by lazy { Profile() }

        const val notePlaceholder = "แตะเพื่อพิมพ์ข้อความ"

        private const val key = "starcard.profile.v1"
        private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    }

    /** ช่องที่กำลังพิมพ์อยู่ — null คือไม่มีใครถูกแก้ · ทั้งตัว widget และชั้นการ์ดต้องอ่านค่าเดียวกัน */
    var editing: TextSlotID? by mutableStateOf(null)

    private val values = mutableStateMapOf<String, String>()
    private val list = mutableStateMapOf<ProfileField, List<String>>()
    /** ข้อความอิสระ — คีย์คือ id ของ widget (+ ช่องที่เท่าไหร่) ไม่ใช่ชื่อฟิลด์ (ดู `ProfileField.note`) */
    private val notes = mutableStateMapOf<NoteKey, String>()

    private val _intake = mutableStateOf<IntakeData?>(null)
    /** ข้อมูลจากฟอร์ม — null = ยังไม่เคยกรอก การ์ดใช้ `Mock.creator` เป็นตัวอย่างไปก่อน */
    var intake: IntakeData?
        get() = _intake.value
        private set(v) { _intake.value = v }

    private val _creator = mutableStateOf(CreatorProfile.empty)
    /** โปรไฟล์ที่ widget อ่าน — ประกอบใหม่ทุกครั้งที่อะไรเปลี่ยน · เป็น stored ไม่ใช่ computed เพราะประกอบ array ใหม่ทุกครั้งที่อ่าน */
    var creator: CreatorProfile
        get() = _creator.value
        private set(v) { _creator.value = v; revision += 1 }

    /** นับทุกครั้งที่โปรไฟล์เปลี่ยน — ให้ของที่อบเป็นรูปไว้ (รูปย่อเทมเพลต) รู้ว่าต้องอบใหม่ */
    var revision: Int = 0
        private set

    private val _sampleFamilies = mutableStateOf<Set<WidgetFamily>>(emptySet())
    /** ตระกูล widget ที่ตอนนี้แสดง **ข้อมูลตัวอย่าง** แทนของจริง (ยังไม่กรอก) — บนการ์ดจริงขึ้นป้ายรอกรอก */
    val sampleFamilies: Set<WidgetFamily> get() = _sampleFamilies.value

    private val scope = CoroutineScope(Dispatchers.Main)
    private var saveJob: Job? = null

    init {
        load()
        creator = buildCreator()
    }

    val hasIntake: Boolean get() = intake != null

    // MARK: อ่าน

    /** ค่าปัจจุบันของฟิลด์ — ตกไปใช้ค่าตั้งต้น (ตัวอย่าง หรือประโยคชวนกรอก) เมื่อยังไม่เคยแก้ */
    fun text(f: ProfileField, i: Int? = null): String {
        if (i != null) {
            val items = items(f)
            return if (i in items.indices) items[i] else ""
        }
        // ค่าว่างที่ค้างอยู่ (ปิดแอปกลางคันขณะช่องยังโฟกัส) นับว่ายังไม่กรอก — ไม่ใช่ชื่อว่างเปล่า
        val v = values[f.raw]
        if (!v.isNullOrEmpty()) return v
        return fallback(f)
    }

    /** มีค่าที่พิมพ์ไว้จริง (ไม่ใช่ว่าง) */
    private fun stored(f: ProfileField): String? = values[f.raw]?.takeIf { it.isNotEmpty() }

    fun items(f: ProfileField): List<String> {
        if (intake != null && f == ProfileField.rateLabels) return rateRows.map { it.label }
        if (intake != null && f == ProfileField.ratePrices) return rateRows.map { if (it.price > 0) it.price.toString() else "" }
        return list[f] ?: fallbackList(f)
    }

    /**
     * ค่าดิบสำหรับช่องพิมพ์ — ประโยคชวนกรอกต้องไม่โผล่ในช่องพิมพ์
     * ยังไม่มีฟอร์ม: ค่าตัวอย่างอยู่ในช่องให้แก้ทับได้ · มีฟอร์มแล้ว: ช่องที่ยังไม่พิมพ์ว่างจริง ๆ
     */
    fun raw(id: TextSlotID): String {
        if (id.field == ProfileField.note) {
            // ช่องที่ดีไซน์ใส่ข้อความมาให้ — ค่าตั้งต้นต้องอยู่ในช่องพิมพ์ด้วย
            return id.widget?.let { notes[NoteKey(it, id.index)] } ?: id.preset
        }
        val i = id.index
        if (i != null) {
            val items = items(id.field)
            return if (i in items.indices) items[i] else ""
        }
        values[id.field.raw]?.let { return it }
        return if (intake == null) fallback(id.field) else (derived(id.field) ?: "")
    }

    /** ช่องนี้ยังแสดงประโยคชวนกรอกอยู่ — ใช้ตัดสินว่าจะจางลง/นับว่า "ยังขาด" */
    fun isPlaceholder(f: ProfileField): Boolean {
        if (intake == null) return false
        return stored(f) == null && derived(f) == null
    }

    /** ข้อความอิสระของชิ้นหนึ่ง — ชิ้นที่ยังไม่เคยพิมพ์ได้ประโยคชวนพิมพ์ไปก่อน (ไม่ใช่ค่าว่าง) */
    fun note(widget: UUID?, index: Int? = null, preset: String = ""): String {
        val v = widget?.let { notes[NoteKey(it, index)] }
            ?: return if (preset.isEmpty()) notePlaceholder else preset
        return v
    }

    val name: String get() = text(ProfileField.personName)
    val tagline: String get() = text(ProfileField.tagline)
    val about: String get() = text(ProfileField.about)
    val quote: String get() = text(ProfileField.quote)
    val handle: String get() = text(ProfileField.handle)
    val contactName: String get() = text(ProfileField.contactName)
    val role: String get() = text(ProfileField.role)
    val phone: String get() = text(ProfileField.phone)
    val email: String get() = text(ProfileField.email)
    val lineId: String get() = text(ProfileField.lineId)
    val categories: List<String> get() = items(ProfileField.categories)
    val nickname: String get() = text(ProfileField.nickname)

    // MARK: เรตราคา — ชื่อรายการกับราคาที่เจ้าของการ์ดตั้งเอง

    /** แถวเรตที่การ์ดวาด — โครงจากตารางในฟอร์ม หรือจากตัวอย่างเมื่อยังไม่มีฟอร์ม */
    val rateRows: List<RateItem> get() {
        val d = intake ?: return emptyList()
        return d.rates.map {
            RateItem(label = it.displayLabel, price = it.price, unit = it.format.unit,
                format = it.format, platform = it.platform, key = it.formatKey)
        }
    }

    /** ชื่อรายการของเรตลำดับที่ `i` */
    fun rateLabel(i: Int): String = text(ProfileField.rateLabels, i)

    /** ราคาของเรตลำดับที่ `i` — เก็บเป็นข้อความ แต่ผู้อ่านต้องได้ตัวเลขเสมอ (พิมพ์ค้างไว้ว่าง → 0) */
    fun ratePrice(i: Int): Int = text(ProfileField.ratePrices, i).filter { it.isDigit() }.toIntOrNull() ?: 0

    /** ตัวยักษ์บนแบบ `ArtTypeOver` — ชื่อเล่น · ค่าตั้งต้นคือคำแรกของชื่อ แต่แก้แยกได้ */
    val mark: String get() = nickname

    fun text(id: TextSlotID): String =
        if (id.field == ProfileField.note) note(id.widget, id.index, preset = id.preset)
        else text(id.field, id.index)

    // MARK: เขียน

    fun set(id: TextSlotID, raw: String) {
        val v = raw.take(id.field.limit ?: 500)
        if (id.field == ProfileField.note) {
            val w = id.widget ?: return
            notes[NoteKey(w, id.index)] = v
        } else if (id.index != null) {
            val i = id.index
            if (intake != null && id.field.isRate) {
                // ราคา/ชื่อบนการ์ดคือช่องในตารางของฟอร์ม — เขียนกลับไปที่นั่น ไม่มีสำเนาที่สอง
                updateIntake { d ->
                    if (i !in d.rates.indices) return@updateIntake d
                    val rates = d.rates.toMutableList()
                    rates[i] = if (id.field == ProfileField.ratePrices) {
                        rates[i].copy(price = v.filter { it.isDigit() }.toIntOrNull() ?: 0, touched = true)
                    } else {
                        rates[i].copy(label = v)
                    }
                    d.copy(rates = rates)
                }
                return
            }
            val items = items(id.field).toMutableList()
            if (i !in items.indices) return
            items[i] = v
            list[id.field] = items
        } else {
            values[id.field.raw] = v
        }
        creator = buildCreator()
        saveSoon()
    }

    /**
     * ช่องที่ถูกพิมพ์จนว่างเปล่า
     * - รายการ (ชิป): ลบชิปใบนั้นทิ้ง · - ฟิลด์เดี่ยว: คืนค่าตั้งต้น การ์ดจึงไม่มีบรรทัดว่างที่อธิบายไม่ได้
     */
    fun commit(id: TextSlotID) {
        val v = raw(id).trim()
        if (id.field == ProfileField.note) {
            val w = id.widget ?: return
            // ลบจนว่าง = คืนของตั้งต้น (ข้อความของดีไซน์ หรือประโยคชวนพิมพ์) ไม่ใช่เหลือชิ้นเปล่าที่มองไม่เห็นบนการ์ด
            val k = NoteKey(w, id.index)
            if (v.isEmpty()) notes.remove(k) else notes[k] = v
            save()
            return
        }
        val i = id.index
        if (i != null) {
            if (intake != null && id.field.isRate) {
                // ชื่อว่าง = กลับไปใช้ชื่อมาตรฐาน · ราคาว่าง = 0 ค้างไว้ (ไม่มีค่าตั้งต้นให้คืน)
                if (id.field == ProfileField.rateLabels) {
                    updateIntake { d ->
                        if (i !in d.rates.indices) return@updateIntake d
                        val rates = d.rates.toMutableList()
                        rates[i] = rates[i].copy(label = if (v.isEmpty()) null else v)
                        d.copy(rates = rates)
                    }
                }
                save()
                return
            }
            if (v.isEmpty()) {
                val items = items(id.field).toMutableList()
                if (i !in items.indices) { save(); return }
                if (id.field.deletesWhenEmpty) {
                    items.removeAt(i)
                } else {
                    // คืนค่าตั้งต้นแทนการลบ — ช่องที่หายไปทำให้รายการคู่ขนานเลื่อนสวมกันผิด
                    val base = fallbackList(id.field)
                    items[i] = if (i in base.indices) base[i] else ""
                }
                list[id.field] = items
            } else {
                val items = items(id.field).toMutableList()
                if (i !in items.indices) { save(); return }
                items[i] = v
                list[id.field] = items
            }
        } else if (v.isEmpty()) {
            values.remove(id.field.raw)
        } else {
            values[id.field.raw] = v
        }
        creator = buildCreator()
        save()
    }

    /** เพิ่มชิปสายงานที่พิมพ์เอง */
    fun appendCategory(v: String) {
        val t = v.trim()
        if (t.isEmpty()) return
        val items = items(ProfileField.categories).toMutableList()
        if (items.contains(t)) return
        items.add(t.take(ProfileField.categories.limit ?: 24))
        list[ProfileField.categories] = items
        creator = buildCreator()
        save()
    }

    fun removeCategory(v: String) {
        val items = items(ProfileField.categories).toMutableList()
        items.removeAll { it == v }
        list[ProfileField.categories] = items
        creator = buildCreator()
        save()
    }

    /** ล้างของที่แก้ไว้ทั้งหมด — กลับไปเป็นโปรไฟล์ตั้งต้น (รวมข้อมูลฟอร์ม) */
    fun resetAll() {
        values.clear()
        list.clear()
        notes.clear()
        intake = null
        editing = null
        creator = buildCreator()
        save()
    }

    val isCustomised: Boolean get() = values.isNotEmpty() || list.isNotEmpty() || notes.isNotEmpty() || intake != null

    // MARK: ฟอร์ม

    /**
     * แก้ข้อมูลฟอร์ม — **ทุกทางที่แก้ `intake` ต้องผ่านตรงนี้** การ์ดถึงจะเห็นและถูกบันทึก
     * `IntakeData` เป็น data class ที่ `val` ล้วน — lambda คืนสำเนาที่แก้แล้ว (`d.copy(...)`)
     */
    fun updateIntake(mutate: (IntakeData) -> IntakeData) {
        val cur = intake ?: return
        val d = mutate(cur)
        if (d == cur) return
        intake = d
        creator = buildCreator()
        saveSoon()
    }

    /** เริ่มกรอกครั้งแรก — สลับจากโหมดตัวอย่างมาเป็นข้อมูลของตัวเอง · ข้อความที่เคยแก้บนการ์ดไว้ยังอยู่ */
    fun beginIntake() {
        if (intake != null) return
        intake = IntakeData()
        creator = buildCreator()
        save()
    }

    /** ยกข้อมูลจากโปรไฟล์ STAR เดิมในระบบเข้ามา — **ตอนนี้ใช้ mock แทน API** (`ProfileCreator` query) */
    fun importFromSystemProfile() {
        val m = Mock.creator
        val socials = m.socials.map {
            SocialEntry(type = it.type,
                link = if (it.profileUrl.isEmpty()) (it.type.profileURL(it.handle) ?: "") else it.profileUrl,
                followers = it.followerCount, source = FollowerSource.connected)
        }
        // หมวดในระบบเดิมสะกดไม่ตรงรายการทางการของฟอร์ม — จับคู่คำที่ซ้อนกัน ไม่บังคับต้องตรงเป๊ะ
        val names = IntakeCatalog.interests.map { it.name }
        val picked = mutableListOf<String>()
        for (c in m.categories + m.interests) {
            val hit = names.firstOrNull { it == c || it.contains(c) || c.contains(it) }
            if (hit != null && !picked.contains(hit)) picked.add(hit)
        }
        val rates = m.rates.map { r ->
            RateCell(platform = r.platform,
                formatKey = (r.platform.formats.firstOrNull { it.generic == r.format } ?: r.platform.defaultFormat).key,
                price = r.price, label = r.label, touched = true)
        }
        val now = System.currentTimeMillis()
        val d = IntakeData(
            kind = CreatorKind.creator,
            socials = socials,
            interests = picked.take(IntakeCatalog.maxInterests),
            rates = rates,
            availability = Availability(days = m.workTime.days, slots = m.workTime.slots, draftRounds = 2,
                limits = emptyList(), otherLimit = "", provinces = listOf(m.location),
                booking = m.bookingState.raw),
            consentAt = now,
            status = ReviewStatus.approved,
            importedAt = now,
            firstRunDone = true,
        )

        values[ProfileField.personName.raw] = m.name
        values[ProfileField.tagline.raw] = m.tagline
        values[ProfileField.about.raw] = m.about
        values[ProfileField.handle.raw] = m.handle
        values[ProfileField.contactName.raw] = m.contact.name
        values[ProfileField.role.raw] = m.contact.role
        values[ProfileField.phone.raw] = m.contact.phone
        values[ProfileField.email.raw] = m.contact.email
        values[ProfileField.lineId.raw] = m.contact.lineId
        values[ProfileField.workArea.raw] = m.location
        list[ProfileField.categories] = m.categories

        intake = d
        creator = buildCreator()
        save()
    }

    /**
     * เติมข้อมูลตัวอย่างครบทุกช่อง — **สำหรับทดสอบ** เดิน flow ได้โดยไม่ต้องพิมพ์
     * ชุดเดียวกับ demo ของฟอร์มเว็บ (มณีรัตน์ ใจดี / mae.review) · สถานะยังเป็น draft และ **ไม่ติ๊กยินยอมให้**
     */
    fun fillSample() {
        val base = intake ?: IntakeData()
        val interests = listOf("แฟชั่น", "คาเฟ่", "ท่องเที่ยว")
        // ปีเป็น ค.ศ. เสมอ (1998-04-12) — ปฏิทินไทยของเครื่องต้องไม่ทำให้กลายเป็นปี 1455
        val dob = LocalDate.of(1998, 4, 12).atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val d = base.copy(
            kind = CreatorKind.creator,
            socials = listOf(
                SocialEntry(type = SocialType.instagram, link = "instagram.com/mae.review", followers = 24_800, source = FollowerSource.connected),
                SocialEntry(type = SocialType.tiktok, link = "tiktok.com/@mae.review", followers = 86_200, source = FollowerSource.manual),
                SocialEntry(type = SocialType.youtube, link = "youtube.com/@maereview", followers = 12_400, source = FollowerSource.api),
            ),
            interests = interests,
            // ชุดเดียวกับ Shift+D ของฟอร์มเว็บ
            rates = listOf(
                RateCell(platform = SocialType.instagram, formatKey = "post", price = 1_800, touched = true),
                RateCell(platform = SocialType.instagram, formatKey = "carousel", price = 2_300, touched = true),
                RateCell(platform = SocialType.instagram, formatKey = "reels", price = 2_900, touched = true),
                RateCell(platform = SocialType.tiktok, formatKey = "short", price = 5_400, touched = true),
                RateCell(platform = SocialType.tiktok, formatKey = "long", price = 8_100, touched = true),
                RateCell(platform = SocialType.tiktok, formatKey = "live", price = 14_000, touched = true),
                RateCell(platform = SocialType.youtube, formatKey = "integrated", price = 2_900, touched = true),
                RateCell(platform = SocialType.youtube, formatKey = "dedicated", price = 5_200, touched = true),
            ),
            availability = Availability(days = (0 until 7).toSet(), slots = setOf(1, 2), draftRounds = 2,
                limits = listOf("ไม่รับงานแอลกอฮอล์ / บุหรี่ / บุหรี่ไฟฟ้า", "ไม่รับงานสินเชื่อ / คริปโต"),
                otherLimit = "ไม่รับงานที่ต้องค้างคืนต่างจังหวัด",
                provinces = listOf("กรุงเทพมหานคร", "นนทบุรี"),
                booking = BookingState.available.raw),
            personal = PersonalInfo(dob = dob, nationality = "ไทย",
                gender = "หญิง", religion = "พุทธ", job = "work", faculty = "",
                field = "การตลาด / โฆษณา"),
            payment = PaymentInfo(kind = PayKind.person, bank = "กสิกรไทย", accountNo = "1234567890",
                accountName = "มณีรัตน์ ใจดี", bookPhoto = true),
            status = ReviewStatus.draft,
            firstRunDone = false,
        )

        val sample: Map<ProfileField, String> = mapOf(
            ProfileField.personName to "มณีรัตน์ ใจดี", ProfileField.nickname to "เมย์", ProfileField.tagline to "Fashion & Café Creator",
            ProfileField.about to "รีวิวแฟชั่นและคาเฟ่แบบใช้จริง ถ่ายเองตัดเองทุกคลิป เน้นลุคใส่ได้ทุกวัน",
            ProfileField.handle to "mae.review", ProfileField.contactName to "มณีรัตน์ ใจดี", ProfileField.role to "ติดต่อโดยตรง · ไม่ผ่านผู้จัดการ",
            ProfileField.phone to "0812345678", ProfileField.email to "mae@salehere.co.th", ProfileField.lineId to "@maereview",
            ProfileField.workArea to "กรุงเทพมหานคร", ProfileField.quote to "ไม่รีวิวของที่ตัวเองไม่ใช้จริง",
            ProfileField.weight to "48 กก.", ProfileField.height to "165 ซม.", ProfileField.bust to "32 นิ้ว", ProfileField.waist to "25 นิ้ว",
            ProfileField.hips to "35 นิ้ว", ProfileField.shoe to "23 ซม.",
        )
        for ((f, v) in sample) values[f.raw] = v
        list[ProfileField.categories] = interests

        intake = d
        creator = buildCreator()
        save()
    }

    // MARK: ประกอบโปรไฟล์ที่ widget อ่าน

    private fun buildCreator(): CreatorProfile {
        val d = intake ?: run {
            // ยังไม่มีข้อมูลเลย = ใช้ชุดตัวอย่างทั้งชุด แต่จำไว้ว่าเป็นตัวอย่าง
            _sampleFamilies.value = setOf(WidgetFamily.followers, WidgetFamily.rate, WidgetFamily.audience, WidgetFamily.brand, WidgetFamily.verified)
            return Mock.creator
        }
        // ช่องที่ยังไม่มียอดไม่ขึ้นการ์ด — "Instagram 0" อ่านเป็นข้อมูลผิด ไม่ใช่ข้อมูลที่ยังไม่กรอก
        val socials: List<SocialProfile> = d.enabledSocials
            .filter { it.followers > 0 }
            .sortedBy { it.type.formOrder }
            .map { e ->
                // วิว/ER/mix ต้องมาจาก OAuth หรือ API จริงเท่านั้น — ยังไม่ต่อ = 0 แล้ว widget บอกว่า "รอซิงก์"
                SocialProfile(type = e.type, handle = "@" + e.handle, followerCount = e.followers,
                    avgEngagementCount = 0, avgViewCount = 0,
                    syncedAgo = if (e.source.isVerified) "เชื่อมบัญชีแล้ว" else "กรอกเอง",
                    mix = EngageMix(likes = 0, comments = 0, shares = 0, saves = 0),
                    postsPerWeek = 0.0, engagementRate = 0.0,
                    profileUrl = e.link, source = e.source)
            }
        // ช่องทาง/เรทยังว่าง → ยืมตัวอย่างมาวาดก่อน (ป้ายรอกรอกบนการ์ดจริงดูจาก `sampleFamilies`)
        val sample = mutableSetOf(WidgetFamily.audience, WidgetFamily.brand, WidgetFamily.verified)
        val rows = rateRows
        val shownSocials: List<SocialProfile> = if (socials.isEmpty()) { sample.add(WidgetFamily.followers); Mock.creator.socials } else socials
        val shownRates: List<RateItem> = if (rows.isEmpty()) { sample.add(WidgetFamily.rate); Mock.creator.rates } else rows
        _sampleFamilies.value = sample
        val formats = ContentFormat.entries.filter { f -> d.rates.any { it.format == f } }
        val a = d.availability
        val state = BookingState.from(a.booking) ?: BookingState.available
        val workTime = WorkTime(days = a.days, slots = a.slots)
        val availability = if (a.days.isEmpty()) state.label else "${state.label} · ${workTime.daySummary}"

        return CreatorProfile(
            name = name, handle = handle, tagline = tagline, location = text(ProfileField.workArea), about = about,
            // ตราดาว = ทุกช่องที่เปิดไว้ยืนยันยอดผ่านการเชื่อมบัญชี/API แล้ว · `-labVerified` บังคับสถานะยืนยันครบ
            verified = VerifiedFacts.labForce || (socials.isNotEmpty() && socials.all { it.source.isVerified }),
            categories = categories, interests = d.interests, styleTags = emptyList(), formats = formats,
            workTime = workTime, socials = shownSocials, rates = shownRates,
            // แพ็กเกจ/เงื่อนไขไม่มีในฟอร์มเว็บ · เวลาตอบกลับ ผู้ชม ผลงานยืนยัน มาจากระบบเท่านั้น — ยังไม่ต่อ backend = ว่าง
            packages = emptyList(), terms = WorkTermsInfo.empty,
            contact = ContactInfo(name = contactName, role = role, phone = phone, email = email, lineId = lineId,
                responseTime = ""),
            // **ผู้ชมยืมของตัวอย่างมาใช้ก่อน** — OAuth Insights ยังไม่ต่อ · **ลบบรรทัดนี้ทิ้งวันที่ต่อ OAuth เสร็จ**
            audience = Mock.creator.audience,
            // **ผลงานยืนยันยืมของตัวอย่างมาใช้ก่อน** — ชั้นหลักฐานยังไม่มี endpoint ในแอป · **ลบบรรทัดนี้ทิ้งวันที่ต่อ backend เสร็จ**
            track = Mock.creator.track,
            availability = availability, bookingState = state)
    }

    // MARK: ค่าตั้งต้น

    /** ยังไม่กรอก = คำใบ้ภาษาไทยของช่องนั้น ไม่ใช่ข้อมูลตัวอย่าง — ทั้งก่อนและหลังมี `intake` */
    private fun fallback(f: ProfileField): String = derived(f) ?: f.placeholder

    /** ค่าที่ "รู้ได้เอง" จากช่องอื่นที่กรอกแล้ว — ยังไม่ต้องถามซ้ำ */
    private fun derived(f: ProfileField): String? {
        val d = intake ?: return null
        return when (f) {
            ProfileField.handle -> d.enabledSocials.map { it.handle }.firstOrNull { it.isNotEmpty() }
            ProfileField.contactName -> stored(ProfileField.personName)
            ProfileField.nickname -> {
                val n = stored(ProfileField.personName) ?: return null
                n.split(" ").firstOrNull { it.isNotEmpty() } ?: n
            }
            ProfileField.workArea -> d.availability.provinces.firstOrNull()
            ProfileField.note -> notePlaceholder
            else -> null
        }
    }

    private fun fallbackList(f: ProfileField): List<String> {
        // สายงานบนการ์ดเริ่มจากหมวดทางการที่เลือกในฟอร์ม จนกว่าจะพิมพ์ชิปเอง · ยังไม่กรอก = ว่าง
        val d = intake ?: return emptyList()
        return if (f == ProfileField.categories) d.interests else emptyList()
    }

    // MARK: จำข้ามการเปิดแอป

    @Serializable
    private data class Snapshot(
        val values: Map<String, String>,
        val list: Map<String, List<String>>,
        /** ข้อความอิสระต่อชิ้น — คีย์เป็น uuid (+ `#ช่อง` ถ้าชิ้นนั้นมีหลายช่อง) · ไฟล์เก่าไม่มีคีย์นี้ */
        val notes: Map<String, String>? = null,
        /** ข้อมูลฟอร์ม — ไฟล์รุ่นก่อนไม่มี = ยังไม่เคยกรอก */
        val intake: IntakeData? = null,
        val version: Int = 2,
    )

    private fun save() {
        saveJob?.cancel()
        val snap = Snapshot(values = values.toMap(),
            list = list.entries.associate { it.key.raw to it.value },
            notes = notes.entries.associate { it.key.stored to it.value },
            intake = intake)
        val data = runCatching { json.encodeToString(Snapshot.serializer(), snap) }.getOrNull() ?: return
        AppContext.prefs.edit().putString(key, data).apply()
    }

    /** บันทึกหลังหยุดพิมพ์ครู่หนึ่ง — ทุกตัวอักษรในฟอร์มต้องไม่หายถ้าแอปถูกปิดกลางคัน แต่ก็ไม่ต้องเขียนดิสก์ทุกคีย์ */
    private fun saveSoon() {
        saveJob?.cancel()
        saveJob = scope.launch {
            delay(350)
            save()
        }
    }

    private fun load() {
        val data = AppContext.prefs.getString(key, null) ?: return
        val snap = runCatching { json.decodeFromString(Snapshot.serializer(), data) }.getOrNull() ?: return
        values.clear()
        values.putAll(snap.values)
        // คีย์ที่ถูกถอดออกไปแล้วจะแปลงกลับไม่ได้ — ข้ามคีย์นั้น ไม่ใช่ทิ้งทั้งโปรไฟล์
        for ((k, v) in snap.list) {
            ProfileField.from(k)?.let { list[it] = v }
        }
        for ((k, v) in snap.notes ?: emptyMap()) {
            NoteKey.fromStored(k)?.let { notes[it] = v }
        }
        _intake.value = snap.intake
    }

    // MARK: - โหมดลองทำ (ดู `LabSync`)

    /** ข้อความอิสระของชิ้นบนการ์ดใบนั้น — คีย์เดียวกับที่เขียนลงไฟล์ (`NoteKey.stored`) */
    fun labNotes(widgets: Set<UUID>): Map<String, String> =
        notes.entries.filter { it.key.widget in widgets }.associate { it.key.stored to it.value }

    /** ข้อมูลเจ้าของการ์ดที่การ์ดอ่าน (= tuple ของ iOS) */
    data class LabOwnerText(val values: Map<String, String>, val list: Map<String, List<String>>, val intake: IntakeData?)

    /** ข้อมูลเจ้าของการ์ดที่การ์ดอ่าน — ชุดเดียวกับที่เขียนลงดิสก์ (`Snapshot`) ยกเว้นข้อความรายชิ้น */
    fun labOwner(): LabOwnerText =
        LabOwnerText(values.toMap(), list.entries.associate { it.key.raw to it.value }, intake)

    /** ทับข้อมูลเจ้าของการ์ดด้วยชุดที่รับมาจากอีกเครื่อง — คีย์รายการที่เครื่องนี้ไม่รู้จักถูกข้าม (เหมือนตอนโหลดดิสก์) */
    fun applyLabOwner(values: Map<String, String>, list: Map<String, List<String>>, intake: IntakeData?) {
        this.values.clear()
        this.values.putAll(values)
        this.list.clear()
        for ((k, v) in list) {
            ProfileField.from(k)?.let { this.list[it] = v }
        }
        this.intake = intake
        creator = buildCreator()
        save()
    }

    /** ทับข้อความของชิ้นบนการ์ดใบนั้นด้วยชุดที่รับมา — ชิ้นที่ไม่มีในชุดถูกลบ (คืนข้อความตั้งต้น) */
    fun applyLabNotes(incoming: Map<String, String>, widgets: Set<UUID>) {
        notes.keys.filter { it.widget in widgets }.forEach { notes.remove(it) }
        for ((k, v) in incoming) {
            NoteKey.fromStored(k)?.let { notes[it] = v }
        }
        save()
    }
}

// MARK: - ค่าว่างของข้อมูลระบบ

private val creatorEmpty: CreatorProfile by lazy {
    CreatorProfile(
        name = "", handle = "", tagline = "", location = "", about = "",
        verified = false, categories = emptyList(), interests = emptyList(), styleTags = emptyList(), formats = emptyList(),
        workTime = WorkTime(days = emptySet(), slots = emptySet()), socials = emptyList(), rates = emptyList(),
        packages = emptyList(), terms = WorkTermsInfo.empty,
        contact = ContactInfo(name = "", role = "", phone = "", email = "", lineId = "", responseTime = ""),
        audience = AudienceInsight.empty, track = TrackRecord.empty,
        availability = "", bookingState = BookingState.available)
}

/** การ์ดที่ยังไม่มีข้อมูลจากระบบ — ทุกช่องว่างจริง ไม่ใช่ตัวอย่าง (widget อ่านแล้วโชว์ "รอข้อมูลจากระบบ") */
val CreatorProfile.Companion.empty: CreatorProfile get() = creatorEmpty

private val workTermsEmpty = WorkTermsInfo(adBoost = "", commercialRights = "", exclusivity = "", rush = "")
val WorkTermsInfo.Companion.empty: WorkTermsInfo get() = workTermsEmpty

private val audienceEmpty = AudienceInsight(female = 0.0, male = 0.0, other = 0.0, ages = emptyList(), places = emptyList())
val AudienceInsight.Companion.empty: AudienceInsight get() = audienceEmpty
val AudienceInsight.isEmpty: Boolean get() = ages.isEmpty() && places.isEmpty() && female + male + other == 0.0

private val trackEmpty = TrackRecord(delivered = 0, accepted = 0, brandCount = 0, brands = emptyList(), avgEngagementRate = 0.0,
    works = emptyList(), sales = SalesRecord(code = "", redemptions = 0, clicks = 0, volume = 0,
        topCategory = "", campaigns = 0),
    reviews = emptyList())
val TrackRecord.Companion.empty: TrackRecord get() = trackEmpty
