package co.salehere.starcard.model

import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import co.salehere.starcard.AppContext
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.SHIcon
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.util.Locale
import kotlin.math.max
import kotlin.math.roundToInt
import kotlin.properties.ReadWriteProperty
import kotlin.reflect.KProperty

// MARK: - flow ใหม่ "Unbox × StarCard" — state จำลองทั้งชุด (= StarFlow.swift · ถอดจาก unbox-mock/js/newflow.js 23 ก.ย. 2569)
//
// หลักคิดเดียวกับเว็บ: ไม่แก้หน้าเดิมของ Unbox แค่ "แทรกหน้ากรอกข้อมูล Star Profile" ก่อนถึงหน้าเดิม
// ทุกช่องดู `have`: มี = ไม่ถามซ้ำ · ไม่มี = โผล่ใน wizard · กรอกแล้วกลายเป็น "มี" งานถัดไปเติมให้เอง

private val legacyMediaKeys = setOf("photos", "works", "videos")

/** build ก่อนหน้าแยก photos/works/videos — รวมเป็น `media` ขั้นเดียว (ผู้ใช้ 24 ก.ย. 2569) · state เก่าที่จำไว้ยังอ่านได้ */
internal object StarDataKeySerializer : RawSerializer<StarDataKey>(
    "StarDataKey",
    { raw -> StarDataKey.from(raw) ?: if (raw in legacyMediaKeys) StarDataKey.media else null },
    { it.raw },
)

/** ช่องข้อมูลใน Star Profile ที่ flow ใหม่ถาม (ยืนยันตัวตนแยกเป็น `verify`) */
@Serializable(with = StarDataKeySerializer::class)
enum class StarDataKey(val raw: String) {
    kind("kind"), socials("socials"), categories("categories"), about("about"), media("media"), rate("rate"),
    insight("insight"), province("province"), availability("availability"), address("address"), bank("bank"),
    draftRounds("draftRounds");

    val id: String get() = raw

    /** ชื่อที่ใช้ในแผง lab และหน้า intro ของ wizard */
    val label: String get() = when (this) {
        kind -> "ประเภทครีเอเตอร์"
        socials -> "ช่องทางโซเชียล"
        categories -> "สายที่ใช่"
        about -> "แนะนำตัว"
        media -> "รูปและผลงาน"
        rate -> "เรทรับงาน"
        insight -> "ข้อมูลผู้ติดตาม"
        province -> "พื้นที่รับงาน"
        availability -> "วันเวลาว่างรับงาน"
        address -> "ที่อยู่รับของ"
        bank -> "บัญชีรับเงิน"
        draftRounds -> "รอบแก้งาน"
    }

    companion object {
        fun from(raw: String?): StarDataKey? = entries.firstOrNull { it.raw == raw }
    }
}

/** `UserVerifyStatus` ของแอปหลัก — ย่อเหลือสามค่าที่ flow ใช้ */
@Serializable
enum class VerifyStatus(val raw: String) {
    none("none"), waiting("waiting"), approved("approved");

    val label: String get() = when (this) {
        none -> "ยังไม่ได้ยืนยันตัวตน"
        waiting -> "รอทีมงานตรวจ"
        approved -> "ยืนยันตัวตนแล้ว"
    }

    companion object {
        fun from(raw: String?): VerifyStatus? = entries.firstOrNull { it.raw == raw }
    }
}

/** `BrandCampaignState` ของแอปหลัก — เฉพาะที่ happy case ผ่าน */
@Serializable
enum class CampaignPhase(val raw: String) {
    register("register"), registered("registered"), waitingAcceptQuota("waitingAcceptQuota"), acceptedQuota("acceptedQuota");

    companion object {
        fun from(raw: String?): CampaignPhase? = entries.firstOrNull { it.raw == raw }
    }
}

@Serializable
enum class OrderPhase(val raw: String) {
    preparing("preparing"), shipping("shipping"), delivered("delivered");

    val label: String get() = when (this) {
        preparing -> "กำลังจัดเตรียมพัสดุ"
        shipping -> "เช็กเลขติดตามพัสดุ"
        delivered -> "จัดส่งสำเร็จ"
    }

    companion object {
        fun from(raw: String?): OrderPhase? = entries.firstOrNull { it.raw == raw }
    }
}

internal object StarSocialSerializer : RawSerializer<StarSocial>("StarSocial", { StarSocial.from(it) }, { it.raw })

/** ช่องโซเชียลของผู้ใช้จำลอง (= `D.USER.socials` ของเว็บ) */
@Serializable(with = StarSocialSerializer::class)
sealed class StarSocial(val raw: String) {
    object instagram : StarSocial("instagram")
    object tiktok : StarSocial("tiktok")
    object facebook : StarSocial("facebook")
    object youtube : StarSocial("youtube")
    object x : StarSocial("x")
    object lemon8 : StarSocial("lemon8")

    val id: String get() = raw
    val ordinal: Int get() = entries.indexOf(this)

    val name: String get() = when (this) {
        instagram -> "Instagram"
        tiktok -> "TikTok"
        facebook -> "Facebook"
        youtube -> "YouTube"
        x -> "X"
        lemon8 -> "Lemon8"
    }

    val short: String get() = when (this) {
        instagram -> "IG"
        facebook -> "FB"
        else -> name
    }

    val icon: Int get() = when (this) {
        instagram -> SHIcon.instagram
        tiktok -> SHIcon.tiktok
        facebook -> SHIcon.facebook
        youtube -> SHIcon.youtube
        x -> SHIcon.x
        lemon8 -> SHIcon.lemon8
    }

    val handle: String get() = when (this) {
        instagram, tiktok -> "mae.review"
        youtube -> "maereview"
        else -> ""
    }

    val url: String get() = when (this) {
        instagram -> "https://instagram.com/mae.review"
        tiktok -> "https://tiktok.com/@mae.review"
        youtube -> "https://youtube.com/@maereview"
        else -> ""
    }

    val followers: Int get() = when (this) {
        instagram -> 24_800
        tiktok -> 86_200
        youtube -> 12_400
        else -> 0
    }

    /** รูปแบบคอนเทนต์ต่อช่อง — ตาม SocialPriceProfileView ของ salehere-ios */
    val formats: List<StarFormat> get() = when (this) {
        instagram, facebook -> listOf(StarFormat.shortVideo, StarFormat.photo)
        tiktok -> listOf(StarFormat.shortVideo)
        youtube -> listOf(StarFormat.shortVideo, StarFormat.longVideo)
        x -> listOf(StarFormat.shortVideo, StarFormat.seeding)
        lemon8 -> listOf(StarFormat.photo, StarFormat.shortVideo)
    }

    /** ช่องที่แนบข้อมูลผู้ติดตามได้ (SocialInsight) */
    val supportsInsight: Boolean get() = this == facebook || this == instagram || this == youtube || this == tiktok

    override fun toString(): String = raw

    companion object {
        val entries: List<StarSocial> by lazy { listOf(instagram, tiktok, facebook, youtube, x, lemon8) }
        fun from(raw: String?): StarSocial? = entries.firstOrNull { it.raw == raw }
    }
}

internal object StarFormatSerializer : RawSerializer<StarFormat>("StarFormat", { StarFormat.from(it) }, { it.raw })

@Serializable(with = StarFormatSerializer::class)
sealed class StarFormat(val raw: String) {
    object shortVideo : StarFormat("shortVideo")
    object photo : StarFormat("photo")
    object longVideo : StarFormat("longVideo")
    object seeding : StarFormat("seeding")

    val id: String get() = raw
    val ordinal: Int get() = entries.indexOf(this)

    val name: String get() = when (this) {
        shortVideo -> "Short Video"
        photo -> "Photo"
        longVideo -> "Long Video"
        seeding -> "Seeding"
    }

    val multiplier: Double get() = when (this) {
        shortVideo -> 1.0
        photo -> 0.8
        longVideo -> 1.4
        seeding -> 0.5
    }

    override fun toString(): String = raw

    companion object {
        val entries: List<StarFormat> by lazy { listOf(shortVideo, photo, longVideo, seeding) }
        fun from(raw: String?): StarFormat? = entries.firstOrNull { it.raw == raw }
    }
}

/** แถวใน "เติมการ์ดให้เต็ม" (= `REVEAL_ROWS` ของเว็บ) — ลำดับตามที่แบรนด์ถามบ่อย */
data class StarRow(
    /** null = ยืนยันตัวตน (ดู `verify` แทน `have`) */
    val key: StarDataKey?,
    val icon: Ph,
    val title: String,
    val why: String,
) {
    val id: String get() = key?.raw ?: "kyc"

    /** กรอกแล้วไปขึ้นตรงไหนบนการ์ด (มุมมอง "การ์ด" ของ Star Profile) */
    val onCard: String get() = when (key) {
        null -> "ขึ้นตรา Verified บนการ์ด"
        StarDataKey.rate -> "ขึ้นป้ายราคาบนการ์ด"
        StarDataKey.about -> "ขึ้นบรรทัดแนะนำตัวใต้ชื่อ"
        StarDataKey.media -> "ขึ้นรูปหลัก กำแพงผลงาน และคลิปบนการ์ด"
        StarDataKey.insight -> "ขึ้นกราฟผู้ชมบนการ์ด"
        StarDataKey.province -> "ขึ้นป้ายพื้นที่รับงาน"
        StarDataKey.availability -> "ขึ้นวันว่างในส่วนรับงาน"
        StarDataKey.socials -> "ขึ้นยอดผู้ติดตามรายช่อง"
        StarDataKey.categories -> "ขึ้นชิปสายงานใต้ชื่อ"
        StarDataKey.bank, StarDataKey.draftRounds, StarDataKey.address -> "ไม่ขึ้นการ์ด · ใช้ตอนได้งาน"
        StarDataKey.kind -> "บอกแบรนด์ว่าคุยกับบุคคลหรือเพจ"
    }

    companion object {
        val all: List<StarRow> = listOf(
            StarRow(key = null, icon = Ph.sealCheck, title = "ยืนยันตัวตน", why = "ต้องผ่านก่อนแบรนด์เลือก · ขึ้นป้าย Verified"),
            StarRow(key = StarDataKey.rate, icon = Ph.coins, title = "เรทรับงาน", why = "แบรนด์ดูราคาก่อนคัดเลือก"),
            StarRow(key = StarDataKey.about, icon = Ph.textAlignLeft, title = "แนะนำตัว", why = "1 บรรทัดใต้ชื่อบนการ์ด"),
            StarRow(key = StarDataKey.media, icon = Ph.imageSquare, title = "รูปและผลงาน", why = "แบรนด์ดูหน้าตาและงานของคุณก่อนคัดเลือก"),
            StarRow(key = StarDataKey.insight, icon = Ph.usersThree, title = "ข้อมูลผู้ติดตาม", why = "แบรนด์เห็นว่าคนดูคุณเป็นใคร"),
            StarRow(key = StarDataKey.province, icon = Ph.mapPin, title = "พื้นที่รับงาน", why = "งานหน้าร้านใกล้คุณขึ้นก่อน"),
            StarRow(key = StarDataKey.availability, icon = Ph.calendarDots, title = "วันเวลาว่างรับงาน", why = "แบรนด์ดูวันว่างของคุณตอนคัดคน"),
            StarRow(key = StarDataKey.socials, icon = Ph.broadcast, title = "ช่องทางของฉัน", why = "ยอดผู้ติดตามขึ้นการ์ดอัตโนมัติ"),
            StarRow(key = StarDataKey.categories, icon = Ph.sparkle, title = "สายที่ใช่", why = "งานตรงสายขึ้นหน้าแรกให้"),
            StarRow(key = StarDataKey.bank, icon = Ph.bank, title = "การรับเงิน", why = "ค่าตัวเข้าบัญชีทันทีเมื่องานจบ"),
            StarRow(key = StarDataKey.draftRounds, icon = Ph.arrowsClockwise, title = "รอบแก้งาน", why = "ตกลงไว้ก่อน ไม่ต้องเถียงหน้างาน"),
            StarRow(key = StarDataKey.address, icon = Ph.`package`, title = "ที่อยู่รับของ", why = "ถามตอนได้งานแรก · รับของรีวิวได้เลย"),
        )
    }
}

internal object WizStepSerializer : RawSerializer<WizStep>("WizStep", { WizStep.from(it) }, { it.raw })

/** ขั้นของ wizard — `intro` มีเฉพาะตอนสมัคร · `kyc` = ยืนยันตัวตน (ออกไปทำแล้วกลับมา) */
@Serializable(with = WizStepSerializer::class)
sealed class WizStep(val raw: String) {
    object intro : WizStep("intro")
    object kind : WizStep("kind")
    object socials : WizStep("socials")
    object categories : WizStep("categories")
    object about : WizStep("about")
    object media : WizStep("media")
    object kyc : WizStep("kyc")
    object rate : WizStep("rate")
    object insight : WizStep("insight")
    object province : WizStep("province")
    object availability : WizStep("availability")
    object address : WizStep("address")
    object bank : WizStep("bank")
    object draftRounds : WizStep("draftRounds")

    val ordinal: Int get() = entries.indexOf(this)

    val dataKey: StarDataKey? get() = StarDataKey.from(raw)

    /** ข้ามได้ (ไม่บังคับ) */
    val optional: Boolean get() = this == insight

    val name: String get() = dataKey?.label ?: (if (this == kyc) "ยืนยันตัวตน" else "")

    /** ชื่อช่องบนการ์ดที่ยังว่าง (หน้า intro) */
    val ghost: String get() = when (this) {
        socials -> "ยอดผู้ติดตาม"
        categories -> "สายที่ใช่"
        about -> "แนะนำตัว"
        media -> "รูปและผลงาน"
        kyc -> "Verified"
        rate -> "เรทรับงาน"
        insight -> "ข้อมูลผู้ติดตาม"
        province -> "พื้นที่"
        availability -> "วันว่าง"
        else -> name
    }

    /** บรรทัดใต้หัวข้อ: "แบรนด์ใช้ข้อนี้ทำอะไร" + กติกาที่จำเป็นจริง ๆ (คั่นด้วย " · ") */
    val line: List<String> get() = when (this) {
        kind -> listOf("แบรนด์เห็นว่าคุยกับใคร", "เลือก 1 อย่าง")
        socials -> listOf("แบรนด์ดูข้อนี้ก่อนคัดเลือก", "ผูก 1 ช่องพอ")
        categories -> listOf("แบรนด์ใช้ตัดสินใจ", "เลือกได้ถึง 5")
        about -> listOf("แบรนด์อ่านความเป็นตัวคุณจากบรรทัดนี้")
        media -> listOf("แบรนด์ดูหน้าตาและงานก่อนคัดเลือก")
        kyc -> listOf("แบรนด์คัดเลือกคนที่ยืนยันแล้ว", "ส่งใบสมัครได้ระหว่างรอตรวจ")
        rate -> listOf("แบรนด์ดูราคาก่อนคัดเลือก", "ใส่ราคามาตรฐานให้แล้ว")
        insight -> listOf("แบรนด์ใช้คัดเลือกกลุ่มเป้าหมาย", "ทำช่องเดียวก็ได้")
        province -> listOf("แบรนด์ใช้คัดเลือกงานหน้าร้าน", "เลือกได้ถึง 3")
        availability -> listOf("แบรนด์ดูวันว่างตอนคัดเลือก")
        draftRounds -> listOf("ตกลงไว้ก่อน ไม่ต้องเถียงหน้างาน")
        else -> emptyList()
    }

    override fun toString(): String = raw

    companion object {
        val entries: List<WizStep> by lazy { listOf(intro, kind, socials, categories, about, media, kyc, rate, insight,
            province, availability, address, bank, draftRounds) }
        fun from(raw: String?): WizStep? = entries.firstOrNull { it.raw == raw }
    }
}

@Serializable
enum class WizKind(val raw: String) {
    apply("apply"), accept("accept"), one("one");

    companion object {
        fun from(raw: String?): WizKind? = entries.firstOrNull { it.raw == raw }
    }
}

/** state กลางของ flow ใหม่ — ตัวเดียวทั้งแอปจำลอง จำลง prefs ให้เปิดแอปแล้วอยู่ที่เดิม (เหมือน localStorage ของเว็บ) */
class StarFlow private constructor() {

    /** stored property ที่ view อ่าน + `didSet { save() }` ของ iOS */
    private inner class Saved<T>(initial: T) : ReadWriteProperty<Any?, T> {
        private val state = mutableStateOf(initial)
        override fun getValue(thisRef: Any?, property: KProperty<*>): T = state.value
        override fun setValue(thisRef: Any?, property: KProperty<*>, value: T) {
            state.value = value
            save()
        }
    }

    private var loading = true

    /** ช่องที่ "มีแล้ว" ใน Star Profile */
    var have: Set<StarDataKey> by Saved(emptySet())
    var verify: VerifyStatus by Saved(VerifyStatus.none)
    var phase: CampaignPhase by Saved(CampaignPhase.register)
    var order: OrderPhase by Saved(OrderPhase.preparing)
    /** ส่งลิงก์รีวิวแล้ว (ขั้นสุดท้าย) — การ์ดขึ้นผลงาน 1 งาน */
    var reviewed: Boolean by Saved(false)
    /** ช่องโซเชียลที่ผูกไว้กับบัญชี Sale Here (ผูกไว้ก่อนแล้วก็ได้ แต่ยังไม่ขึ้นการ์ดจนกว่าจะติ๊ก `socials`) */
    var connected: Set<StarSocial> by Saved(setOf(StarSocial.instagram, StarSocial.tiktok, StarSocial.youtube))
    /** เคยเห็นหน้าการ์ดเกิดแล้ว — ครั้งถัดไปไม่เล่น motion ยาว */
    var revealSeen: Boolean by Saved(false)
    var consent: Boolean by Saved(false)
    var doneOpen: Boolean by mutableStateOf(false)
    /** ตู้ widget ขอให้พาไปดูงานที่เปิดรับ — พื้นที่การ์ดปิดตัว แล้ว shell สลับไปแท็บหน้าแรก */
    var jobsRequested: Boolean by mutableStateOf(false)

    // คำตอบที่กรอก (จำไว้ให้ wizard เปิดมาเห็นค่าเดิม)
    var about: String by Saved("ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่ร้านคาเฟ่น่ารักๆ")
    var categories: List<String> by Saved(listOf("👗 แฟชั่น", "☕️ คาเฟ่", "✈️ ท่องเที่ยว"))
    var provinces: List<String> by Saved(listOf("กรุงเทพมหานคร"))
    var availDays: String by Saved("ทุกวัน")
    /** Creator (บุคคล) / Page (เพจ) — ขั้น `type` ของฟอร์มเว็บ */
    var creatorKind: String by Saved("creator")
    /** รับเงินในนามบุคคล / นามบริษัท — `PAYDOC` ของฟอร์มเว็บ (หัก ณ ที่จ่าย 3% / 7%) */
    var payKind: String by Saved("person")
    var availTime: String by Saved("ตลอดวัน")
    var draftRounds: Int by Saved(2)
    var rates: Map<String, Int> by Saved(emptyMap())
    var insightSlots: Set<String> by Saved(emptySet())

    init {
        val d = AppContext.prefs.getString(storeKey, null)
        val s = d?.let { runCatching { json.decodeFromString(Snap.serializer(), it) }.getOrNull() }
        if (s != null) {
            have = s.have; verify = s.verify; phase = s.phase; order = s.order; reviewed = s.reviewed
            connected = s.connected; revealSeen = s.revealSeen; consent = s.consent
            about = s.about; categories = s.categories; provinces = s.provinces; availDays = s.availDays; availTime = s.availTime
            draftRounds = s.draftRounds; rates = s.rates; insightSlots = s.insightSlots
        }
        loading = false
    }

    // MARK: กติกา

    /** การ์ดเกิดจากสิ่งที่มีอยู่แล้ว (ช่องโซเชียล + สายที่ใช่) — ไม่มี "ระดับ": มีการ์ด = เป็น STAR แล้ว */
    val hasCard: Boolean get() = have.contains(StarDataKey.socials) && have.contains(StarDataKey.categories)
    val isVerified: Boolean get() = verify == VerifyStatus.approved
    /** STAR เต็มตัว = การ์ด + ยืนยันตัวตนผ่าน */
    val isStar: Boolean get() = hasCard && isVerified

    fun has(k: StarDataKey): Boolean = have.contains(k)
    fun done(row: StarRow): Boolean = row.key?.let { has(it) } ?: isVerified

    /**
     * ขั้นที่ต้องมีก่อน "ส่งใบสมัคร" — แค่พอให้การ์ดเกิด ที่เหลือเติมทีหลังระหว่างรอผล
     * = ฟอร์มสมัครเดิมถาม: ประเภท · ช่องทาง · สาย · รูปและผลงาน · ยืนยันตัวตน · เรทต่อรูปแบบ · ข้อมูลผู้ติดตาม (ข้ามได้)
     */
    val registerSteps: List<WizStep> get() =
        listOf(WizStep.kind, WizStep.socials, WizStep.categories, WizStep.media, WizStep.kyc, WizStep.rate, WizStep.insight)
            .filter { if (it == WizStep.kyc) verify == VerifyStatus.none else !has(it.dataKey!!) }

    /** ขั้นที่ยังขาดทั้งหมดของ Star Profile — ทางเข้าจากหน้า Star Profile ("สมัครเป็น STAR · N ข้อ") · รวมที่อยู่/บัญชี/รอบแก้ด้วย */
    val applySteps: List<WizStep> get() {
        val all = listOf(WizStep.kind, WizStep.socials, WizStep.categories, WizStep.about, WizStep.media, WizStep.kyc, WizStep.rate,
            WizStep.insight, WizStep.province, WizStep.availability, WizStep.address, WizStep.bank, WizStep.draftRounds)
        return all.filter { if (it == WizStep.kyc) verify == VerifyStatus.none else !has(it.dataKey!!) }
    }

    /** ขั้นที่ยังขาดก่อนตอบรับ (ถามตอนได้งานแล้วเท่านั้น) */
    val acceptSteps: List<WizStep> get() =
        listOf(WizStep.address, WizStep.bank, WizStep.draftRounds).filter { !has(it.dataKey!!) }

    /** ข้อที่ขาดบนหน้าการ์ด (ไม่รวมยืนยันตัวตน ซึ่งเป็น flow แยก) */
    val missingSteps: List<WizStep> get() = StarRow.all.mapNotNull { r ->
        val k = r.key ?: return@mapNotNull null
        if (has(k)) return@mapNotNull null
        WizStep.from(k.raw)
    }

    val doneCount: Int get() = StarRow.all.count { done(it) }
    val pct: Double get() = doneCount.toDouble() / StarRow.all.size.toDouble()

    /** ค่าที่กรอกไว้ของแถว — ป้ายชิ้นละค่า (= `r.done(s)` ของเว็บ) */
    fun facts(row: StarRow): List<String> {
        val key = row.key ?: return listOf("Verified")
        return when (key) {
            StarDataKey.kind -> listOf(if (creatorKind == "page") "Page (เพจ)" else "Creator (บุคคล)")
            StarDataKey.rate -> listOf("IG ฿3,000", "TikTok ฿10,300", "+3 รูปแบบ")
            StarDataKey.about -> listOf(about.take(28) + (if (about.length > 28) "…" else ""))
            StarDataKey.media -> {
                val f = Portfolio.shared
                listOf("รูป ${max(f.creatorImages.size, minPhotos)}", "ผลงาน ${max(f.works.size, minWorks)}", "คลิป ${max(f.videos.size, minVideos)}")
            }
            StarDataKey.insight -> listOf("หญิง 68%", "25–34 ปี", "กรุงเทพฯ")
            StarDataKey.province ->
                if (provinces.size > 2) provinces.take(2).map { shortProvince(it) } + listOf("+${provinces.size - 2}")
                else provinces.map { shortProvince(it) }
            StarDataKey.availability -> listOf(availDays, availTime)
            StarDataKey.socials -> StarSocial.entries.filter { connected.contains(it) }.map { "${it.short} ${fmt(it.followers)}" }
            StarDataKey.categories -> categories.map { it.split(" ").filter { p -> p.isNotEmpty() }.drop(1).joinToString(" ") }
            StarDataKey.bank -> if (payKind == "company") listOf("นามบริษัท", "กสิกรไทย", "···7890") else listOf("นามบุคคล", "กสิกรไทย", "···7890")
            StarDataKey.draftRounds -> listOf("แก้ $draftRounds รอบ")
            StarDataKey.address -> listOf("กรุงเทพฯ 10250")
        }
    }

    private fun shortProvince(p: String): String =
        if (p == "กรุงเทพมหานคร") "กรุงเทพฯ" else p.replace(" (ออนไลน์)", "")

    /** ราคาแนะนำจากยอดผู้ติดตาม (= `suggestPrice` ของเว็บ) */
    fun suggestedRate(s: StarSocial, f: StarFormat): Int =
        max(500, (s.followers.toDouble() / 1000 * 120 * f.multiplier / 100).roundToInt() * 100)

    fun rate(s: StarSocial, f: StarFormat): Int = rates["${s.raw}_${f.raw}"] ?: suggestedRate(s, f)
    fun setRate(s: StarSocial, f: StarFormat, v: Int) { rates = rates + ("${s.raw}_${f.raw}" to v) }

    // MARK: แผง lab — ขั้นทั้งหมดของ happy case + กติกาติ๊กข้อมูล (= `STAGES`/`DATA_RULES` ของเว็บ)

    data class Stage(
        val id: Int,
        val title: String,
        /** หน้าแทรกของ flow ใหม่ (ป้าย "แทรก" สีแดงในแผง) · false = หน้าเดิมของ Unbox */
        val inserted: Boolean = false,
        val phase: CampaignPhase,
        val order: OrderPhase = OrderPhase.preparing,
        val reviewed: Boolean = false,
        /** หน้าที่ต้องเปิดเมื่อกระโดดมาขั้นนี้ */
        val screen: FlowScreen? = null,
        val dialog: FlowDialog? = null,
        /** หน้าเดิมที่ยังไม่ได้จำลองในแอป — บอกผ่าน toast */
        val note: String? = null,
    )

    /** ข้อมูลไหนถูกถามที่ขั้นไหน และต้องมีตั้งแต่ขั้นไหน (= `DATA_RULES`) */
    data class Rule(val key: StarDataKey?, val askAt: Int, val needFrom: Int)

    /** ขั้นปัจจุบัน (อนุมานจาก state + หน้าที่เปิดอยู่) */
    fun stageIndex(screen: FlowScreen?, dialog: FlowDialog?): Int {
        if (reviewed) return 13
        if (phase == CampaignPhase.acceptedQuota) return if (order == OrderPhase.delivered) 10 else 9
        if (screen == FlowScreen.Accept) return 8
        if (screen == FlowScreen.Wizard(WizKind.accept)) return 7
        if (phase == CampaignPhase.waitingAcceptQuota) return 6
        if (phase == CampaignPhase.registered) return if (dialog == FlowDialog.registerSuccess) 4 else 5
        if (screen == FlowScreen.Register) return 3
        if (screen == FlowScreen.Reveal) return 2
        if (screen is FlowScreen.Wizard) return 1
        return 0
    }

    /** กระโดดไปขั้น `i` — ขั้นก่อนหน้าติ๊กข้อมูลให้เอง · คืนหน้า/dialog ที่ต้องเปิด */
    fun goto(i: Int): Pair<FlowScreen?, FlowDialog?> {
        val st = stages[i]
        val h = mutableSetOf<StarDataKey>()
        var v = VerifyStatus.none
        for (r in rules) {
            if (i < r.needFrom) continue
            val k = r.key
            if (k != null) h.add(k) else v = VerifyStatus.approved
        }
        have = h; verify = v
        phase = st.phase; order = st.order; reviewed = st.reviewed
        consent = i >= 3
        if (i >= 2) connected = connected + StarSocial.instagram
        if (i == 2) revealSeen = false
        return st.screen to st.dialog
    }

    /**
     * ติ๊กข้อมูลเข้า/ออกจากแผง — ติ๊กออกตอนอยู่ขั้นที่ต้องมีแล้ว = ย้อน state กลับไปขั้นที่ขอข้อมูลนั้น
     * คืนขั้นที่ย้อนกลับไป (null = ไม่ต้องย้อน)
     */
    fun tick(key: StarDataKey?, on: Boolean, stage: Int): Int? {
        if (key != null) { have = if (on) have + key else have - key }
        else verify = if (on) VerifyStatus.approved else VerifyStatus.none
        if (on) return null
        val r = rule(key) ?: return null
        if (stage < r.needFrom) return null
        return r.askAt
    }

    // MARK: ฉากสำเร็จรูป (= `NEW_PRESETS`/`PRESETS` ของเว็บ) — ตั้ง state ทั้งชุดในคลิกเดียว

    data class Preset(
        val id: String,
        val title: String,
        val have: Set<StarDataKey>,
        val verify: VerifyStatus,
        val phase: CampaignPhase = CampaignPhase.register,
        val order: OrderPhase = OrderPhase.preparing,
        val reviewed: Boolean = false,
    )

    fun apply(p: Preset) {
        have = p.have; verify = p.verify; phase = p.phase; order = p.order; reviewed = p.reviewed
        consent = p.phase != CampaignPhase.register
        if (p.have.isNotEmpty()) connected = connected + StarSocial.instagram
        if (p.have.contains(StarDataKey.insight)) insightSlots = setOf("instagram_gender", "instagram_age", "instagram_location")
        doneOpen = false
    }

    /** ติ๊กข้อมูลให้ครบทุกช่อง (ไม่แตะสถานะงาน) */
    fun fillAll() {
        have = allKeys
        if (verify == VerifyStatus.none) verify = VerifyStatus.approved
        connected = connected + StarSocial.instagram
        insightSlots = setOf("instagram_gender", "instagram_age", "instagram_location")
    }

    fun reset() {
        have = emptySet(); verify = VerifyStatus.none; phase = CampaignPhase.register; order = OrderPhase.preparing; reviewed = false
        connected = setOf(StarSocial.instagram, StarSocial.tiktok, StarSocial.youtube); revealSeen = false; consent = false; doneOpen = false
        rates = emptyMap(); insightSlots = emptySet()
    }

    // MARK: จำลงเครื่อง

    @Serializable
    private data class Snap(
        val have: Set<StarDataKey>, val verify: VerifyStatus, val phase: CampaignPhase, val order: OrderPhase,
        val reviewed: Boolean, val connected: Set<StarSocial>, val revealSeen: Boolean, val consent: Boolean,
        val about: String, val categories: List<String>, val provinces: List<String>, val availDays: String, val availTime: String,
        val draftRounds: Int, val rates: Map<String, Int>, val insightSlots: Set<String>,
    )

    private fun save() {
        if (loading) return
        val s = Snap(have = have, verify = verify, phase = phase, order = order, reviewed = reviewed, connected = connected,
            revealSeen = revealSeen, consent = consent, about = about, categories = categories, provinces = provinces,
            availDays = availDays, availTime = availTime, draftRounds = draftRounds, rates = rates, insightSlots = insightSlots)
        val d = runCatching { json.encodeToString(Snap.serializer(), s) }.getOrNull() ?: return
        AppContext.prefs.edit().putString(storeKey, d).apply()
    }

    companion object {
        val shared: StarFlow by lazy { StarFlow() }

        private const val storeKey = "starflow.v1"
        private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

        /** ขั้นต่ำของรูป/วิดีโอ = เกณฑ์โปรไฟล์ 100% เดิม (gateway user-creator-profile.type.js: รูป ≥3 · ผลงาน ≥2 · วิดีโอ ≥2) */
        val minPhotos: Int = Portfolio.creatorSlots
        const val minWorks = 2
        const val minVideos = 2

        fun fmt(n: Int): String {
            if (n >= 1_000_000) return String.format(Locale.US, "%.1fM", n / 1_000_000.0)
            if (n >= 1_000) return String.format(Locale.US, "%.1fK", n / 1_000.0).replace(".0K", "K")
            return n.toString()
        }

        /** ขั้นทั้ง 14 ของ happy case (= `STAGES` ของ unbox-mock/newflow.js) — ลำดับเดียว กดเพื่อกระโดด */
        val stages: List<Stage> = listOf(
            Stage(id = 0, title = "เห็นงาน · หน้ากิจกรรม", phase = CampaignPhase.register),
            Stage(id = 1, title = "แทรก: ข้อมูลของคุณ (ก่อนสมัคร)", inserted = true, phase = CampaignPhase.register, screen = FlowScreen.Wizard(WizKind.apply)),
            Stage(id = 2, title = "แทรก: การ์ดเกิด (โชว์ครั้งแรกครั้งเดียว)", inserted = true, phase = CampaignPhase.register, screen = FlowScreen.Reveal),
            Stage(id = 3, title = "ฟอร์มสมัครเดิม (ไม่แก้)", phase = CampaignPhase.register, screen = FlowScreen.Register),
            Stage(id = 4, title = "ลงทะเบียนสำเร็จ · dialog เดิม", phase = CampaignPhase.registered, dialog = FlowDialog.registerSuccess),
            Stage(id = 5, title = "แบรนด์คัดคน · รอผล", phase = CampaignPhase.registered),
            Stage(id = 6, title = "ได้รับเลือก · ปุ่มตอบรับ (เดิม)", phase = CampaignPhase.waitingAcceptQuota),
            Stage(id = 7, title = "กดตอบรับ → แทรก: ข้อมูลก่อนตอบรับ", inserted = true, phase = CampaignPhase.waitingAcceptQuota, screen = FlowScreen.Wizard(WizKind.accept)),
            Stage(id = 8, title = "หน้าตอบรับเดิม (ที่อยู่เติมให้)", phase = CampaignPhase.waitingAcceptQuota, screen = FlowScreen.Accept),
            Stage(id = 9, title = "ตอบรับแล้ว · รอของ", phase = CampaignPhase.acceptedQuota, order = OrderPhase.shipping),
            Stage(id = 10, title = "ของถึง · สร้างดราฟต์ (เดิม)", phase = CampaignPhase.acceptedQuota, order = OrderPhase.delivered, note = "หน้าสร้างดราฟต์ = หน้าเดิมของแอปหลัก ยังไม่ได้จำลอง"),
            Stage(id = 11, title = "ส่งดราฟต์ · รอตรวจ (เดิม)", phase = CampaignPhase.acceptedQuota, order = OrderPhase.delivered, note = "หน้าดราฟต์รอตรวจ = หน้าเดิมของแอปหลัก ยังไม่ได้จำลอง"),
            Stage(id = 12, title = "ดราฟต์ผ่าน · ส่งลิงก์ (เดิม)", phase = CampaignPhase.acceptedQuota, order = OrderPhase.delivered, note = "หน้าส่งลิงก์รีวิว = หน้าเดิมของแอปหลัก ยังไม่ได้จำลอง"),
            Stage(id = 13, title = "ส่งลิงก์แล้ว · จบ (หน้ากิจกรรมเดิม)", phase = CampaignPhase.acceptedQuota, order = OrderPhase.delivered, reviewed = true),
        )

        val rules: List<Rule> = listOf(
            Rule(key = StarDataKey.kind, askAt = 1, needFrom = 2), Rule(key = StarDataKey.socials, askAt = 1, needFrom = 2),
            Rule(key = StarDataKey.categories, askAt = 1, needFrom = 2), Rule(key = StarDataKey.about, askAt = 2, needFrom = 99),
            Rule(key = StarDataKey.media, askAt = 1, needFrom = 2),
            Rule(key = null, askAt = 1, needFrom = 2), Rule(key = StarDataKey.rate, askAt = 1, needFrom = 2),
            Rule(key = StarDataKey.insight, askAt = 1, needFrom = 99), Rule(key = StarDataKey.province, askAt = 2, needFrom = 99),
            Rule(key = StarDataKey.availability, askAt = 2, needFrom = 99),
            Rule(key = StarDataKey.address, askAt = 7, needFrom = 8), Rule(key = StarDataKey.bank, askAt = 7, needFrom = 8),
            Rule(key = StarDataKey.draftRounds, askAt = 7, needFrom = 8),
        )

        fun rule(key: StarDataKey?): Rule? = rules.firstOrNull { it.key == key }

        val cardKeys: Set<StarDataKey> = setOf(StarDataKey.kind, StarDataKey.socials, StarDataKey.categories, StarDataKey.about)
        val mediaKeys: Set<StarDataKey> = setOf(StarDataKey.media)
        val applyKeys: Set<StarDataKey> = cardKeys + mediaKeys + setOf(StarDataKey.rate, StarDataKey.insight, StarDataKey.province, StarDataKey.availability)
        val allKeys: Set<StarDataKey> = StarDataKey.entries.toSet()

        val presets: List<Preset> = listOf(
            Preset(id = "new", title = "ผู้ใช้ใหม่ · ยังไม่มีอะไรเลย", have = emptySet(), verify = VerifyStatus.none),
            Preset(id = "card", title = "มีการ์ดแล้ว · ยังไม่ยืนยันตัวตน", have = cardKeys, verify = VerifyStatus.none),
            Preset(id = "cardWait", title = "มีการ์ด · KYC รอทีมงานตรวจ", have = cardKeys, verify = VerifyStatus.waiting),
            Preset(id = "apply", title = "STAR พร้อมสมัคร (ครบที่แบรนด์ถาม)", have = applyKeys, verify = VerifyStatus.approved),
            Preset(id = "full", title = "ครบทุกอย่าง ${StarRow.all.size}/${StarRow.all.size}", have = allKeys, verify = VerifyStatus.approved),
            Preset(id = "registered", title = "สมัครแล้ว · รอผล (การ์ดยังขาด)", have = cardKeys + mediaKeys + setOf(StarDataKey.rate), verify = VerifyStatus.waiting, phase = CampaignPhase.registered),
            Preset(id = "selected", title = "ได้รับเลือก · รอตอบรับ (ยังไม่มีที่อยู่/บัญชี)", have = applyKeys, verify = VerifyStatus.approved, phase = CampaignPhase.waitingAcceptQuota),
            Preset(id = "working", title = "ตอบรับแล้ว · ของกำลังส่ง", have = allKeys, verify = VerifyStatus.approved, phase = CampaignPhase.acceptedQuota, order = OrderPhase.shipping),
            Preset(id = "done", title = "ส่งรีวิวแล้ว · เสร็จสิ้น", have = allKeys, verify = VerifyStatus.approved, phase = CampaignPhase.acceptedQuota, order = OrderPhase.delivered, reviewed = true),
        )
    }
}

/** `@Environment(StarFlow.self)` — ค่าตั้งต้นคือ singleton จึงไม่ต้อง provide ก็อ่านได้ */
val LocalStarFlow = compositionLocalOf { StarFlow.shared }

/** หน้าของ flow ใหม่ที่เปิดทับแอปจำลอง (= `s.screen` ของเว็บ เฉพาะหน้าที่แทรก + หน้าเดิมที่มันพาไป) */
sealed class FlowScreen {
    data class Wizard(val kind: WizKind) : FlowScreen()
    /** การ์ดเพิ่งเกิด — "คุณเป็น STAR แล้ว" → ฟอร์มสมัคร */
    object Reveal : FlowScreen()
    /** ฟอร์มสมัครเดิม (flow ใหม่ตัดช่องที่อยู่ออก) */
    object Register : FlowScreen()
    /** หน้าตอบรับเดิม */
    object Accept : FlowScreen()
    /** Star Profile ถาวร (ปุ่ม "โปรไฟล์ครีเอเตอร์") */
    object StarProfile : FlowScreen()
    /** ยืนยันตัวตน (KYC จำลอง) */
    object Kyc : FlowScreen()
}

enum class FlowDialog {
    registerSuccess,
    wizExit,
    acceptConfirm,
    declineConfirm,
}
