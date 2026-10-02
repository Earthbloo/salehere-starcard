package co.salehere.starcard.model

import co.salehere.starcard.theme.Ph
import kotlinx.coroutines.delay
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.net.URI
import java.time.Instant
import java.time.LocalDate
import java.time.Period
import java.time.ZoneId
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

// MARK: - ข้อมูลจากฟอร์มสมัคร/แก้ไขโปรไฟล์ (= Intake.swift)
//
// `Profile` เก็บ **ข้อความ** ที่แก้ได้บนตัวการ์ด — แต่ฟอร์มสมัครมีของที่ไม่ใช่ข้อความ: ช่องทางพร้อมยอด ·
// ตารางเรท แพลตฟอร์ม×รูปแบบ · หมวดทางการ · วัน/เวลาที่รับงาน · ข้อมูลส่วนตัวที่ไม่ขึ้นการ์ด
// ไฟล์นี้คือรูปร่างของของพวกนั้น — เก็บใน `Profile.intake` ก้อนเดียว ทั้งฟอร์มและการ์ดอ่านที่เดียวกัน
//
// ทุก data class ในไฟล์นี้เป็น `val` ล้วน — แก้ผ่าน `copy(...)` ใน `Profile.updateIntake { d -> d.copy(...) }`
// (ค่าแบบ value semantics ของ Swift: แก้ในที่แล้ว `d != intake` จะไม่รู้ว่าเปลี่ยน และ Compose ไม่วาดใหม่)

/** ยอดผู้ติดตามมาจากไหน — ตัวตัดสินว่าตัวเลขนี้ "ยืนยันแล้ว" หรือ "รอตรวจ" */
@Serializable
enum class FollowerSource(val raw: String) {
    manual("manual"), connected("connected"), api("api");

    val isVerified: Boolean get() = this != manual

    val label: String get() = when (this) {
        manual -> "กรอกเอง · รอทีมงานตรวจสอบ"
        connected -> "ยืนยันแล้วผ่านการเชื่อมบัญชี"
        api -> "ยืนยันอัตโนมัติจาก API"
    }

    companion object {
        fun from(raw: String?): FollowerSource? = entries.firstOrNull { it.raw == raw }
    }
}

/** สมัครในนามใคร — ตัวตั้งต้นของรูปแบบเรทและวิธีเรียกผู้รับงาน */
@Serializable
enum class CreatorKind(val raw: String) {
    creator("creator"), page("page");

    val id: String get() = raw
    val title: String get() = if (this == creator) "Creator (บุคคล)" else "Page (เพจ)"
    val detail: String get() =
        if (this == creator) "ตัวคุณเองเป็นคนสร้างคอนเทนต์" else "บริหารเพจ/สื่อในนามทีมหรือแบรนด์"
    val icon: Ph get() = if (this == creator) Ph.user else Ph.browsers

    companion object {
        fun from(raw: String?): CreatorKind? = entries.firstOrNull { it.raw == raw }
    }
}

/** สถานะการตรวจของทีมงาน — ตราดาวบนการ์ดขึ้นเมื่อ `approved` เท่านั้น */
@Serializable
enum class ReviewStatus(val raw: String) {
    draft("draft"), pending("pending"), approved("approved");

    val label: String get() = when (this) {
        draft -> "ยังไม่ได้ส่งตรวจ"
        pending -> "รอทีมงานตรวจสอบ"
        approved -> "เป็น STAR แล้ว"
    }

    companion object {
        fun from(raw: String?): ReviewStatus? = entries.firstOrNull { it.raw == raw }
    }
}

/** ช่องทางหนึ่งช่อง — ลิงก์ · ยอด · ที่มาของยอด */
@Serializable
data class SocialEntry(
    val type: SocialType,
    val link: String = "",
    val followers: Int = 0,
    val source: FollowerSource = FollowerSource.manual,
    /** ปิดไว้ = ไม่โชว์บนการ์ด แต่ **ข้อมูลยังอยู่** — ปิดแล้วเปิดใหม่ไม่ต้องกรอกซ้ำ */
    val enabled: Boolean = true,
) {
    val id: String get() = type.raw
    val handle: String get() = type.handle(from = link)
    val linkError: String? get() = type.linkError(link)
    val isComplete: Boolean get() = link.isNotEmpty() && linkError == null && followers > 0
}

/** รูปแบบงานของแพลตฟอร์ม — `PLAT[].fmts` ของฟอร์มเว็บ: คีย์ · ชื่อ · ตัวคูณจากเรทฐาน · รูปแบบหลัก */
data class PlatFormat(
    val key: String,
    val label: String,
    /** ตัวคูณจากเรทฐานของแพลตฟอร์ม (`m`) */
    val m: Double,
    /** รูปแบบหลักที่ติ๊กให้ก่อนตอนรู้ยอดผู้ติดตาม (`def`) */
    val isDefault: Boolean = false,
    /** รูปแบบกลางที่การ์ดและสูตรราคาตลาดใช้จัดกลุ่ม */
    val generic: ContentFormat,
) {
    val id: String get() = key
}

/** หนึ่งช่องในตารางเรท แพลตฟอร์ม × รูปแบบของแพลตฟอร์มนั้น — มีอยู่ = รับงานแบบนั้น */
@Serializable(with = RateCellSerializer::class)
data class RateCell(
    val platform: SocialType,
    /** คีย์รูปแบบตามแพลตฟอร์ม (`post`, `reels`, `short`, `dedicated` …) — ดู `SocialType.formats` */
    val formatKey: String,
    val price: Int = 0,
    /** ชื่อรายการที่ผู้ใช้ตั้งเองบนการ์ด — null = ใช้ชื่อมาตรฐาน "IG Reels" */
    val label: String? = null,
    /** ผู้ใช้แก้ราคาเองแล้ว — ปุ่ม "ใช้เรทแนะนำ" ห้ามทับ */
    val touched: Boolean = false,
) {
    val id: String get() = platform.raw + "." + formatKey
    val spec: PlatFormat? get() = platform.formats.firstOrNull { it.key == formatKey }
    /** รูปแบบกลาง — การ์ดกับ `Pricing` ยังจัดกลุ่มแบบนี้ */
    val format: ContentFormat get() = spec?.generic ?: ContentFormat.photo
    val defaultLabel: String get() = "${platform.shortName} ${spec?.label ?: formatKey}"
    val displayLabel: String get() = label?.takeIf { it.isNotEmpty() } ?: defaultLabel
}

/** รูปบนดิสก์ของ `RateCell` — คีย์ JSON เดิมของ iOS (`platform` `formatKey` `price` `label` `touched` + `format` ของข้อมูลเก่า) */
@Serializable
private class RateCellSurrogate(
    val platform: SocialType,
    val formatKey: String? = null,
    val price: Int = 0,
    val label: String? = null,
    val touched: Boolean = false,
    /** ข้อมูลเก่าเก็บ `format` (รูปแบบกลาง) — แปลงเป็นรูปแบบแรกของแพลตฟอร์มที่อยู่กลุ่มเดียวกัน */
    val format: ContentFormat? = null,
)

internal object RateCellSerializer : KSerializer<RateCell> {
    override val descriptor: SerialDescriptor = RateCellSurrogate.serializer().descriptor

    override fun serialize(encoder: Encoder, value: RateCell) {
        encoder.encodeSerializableValue(
            RateCellSurrogate.serializer(),
            RateCellSurrogate(value.platform, value.formatKey, value.price, value.label, value.touched),
        )
    }

    override fun deserialize(decoder: Decoder): RateCell {
        val s = decoder.decodeSerializableValue(RateCellSurrogate.serializer())
        val p = s.platform
        val key = s.formatKey
            ?: s.format?.let { g -> (p.formats.firstOrNull { it.generic == g } ?: p.defaultFormat).key }
            ?: p.defaultFormat.key
        return RateCell(platform = p, formatKey = key, price = s.price, label = s.label, touched = s.touched)
    }
}

/** วัน · เวลา · เงื่อนไขที่รับงาน */
@Serializable
data class Availability(
    /** 0 = อาทิตย์ … 6 = เสาร์ (ดัชนีเดียวกับ `WorkTime`) */
    val days: Set<Int> = emptySet(),
    val slots: Set<Int> = emptySet(),
    val draftRounds: Int? = null,
    val limits: List<String> = emptyList(),
    val otherLimit: String = "",
    val provinces: List<String> = emptyList(),
    /** `BookingState.raw` */
    val booking: String = BookingState.available.raw,
)

/** ข้อมูลส่วนตัวที่ใช้จับคู่งาน — **ไม่ขึ้นบนการ์ด** */
@Serializable
data class PersonalInfo(
    /** วันเกิด — epoch millis */
    val dob: Long? = null,
    val nationality: String = "ไทย",
    val gender: String = "",
    val religion: String = "",
    val job: String = "",
    val faculty: String = "",
    val field: String = "",
) {
    val age: Int? get() {
        val d = dob ?: return null
        val birth = Instant.ofEpochMilli(d).atZone(ZoneId.systemDefault()).toLocalDate()
        val a = Period.between(birth, LocalDate.now()).years
        return if (a in 0 until 120) a else null
    }
}

/** รับเงินในนามใคร — ข้อ `pay` ของฟอร์มเว็บ · ตัวกำหนดชุดช่องและอัตราหัก ณ ที่จ่าย (`PAY[...].wht`) */
@Serializable
enum class PayKind(val raw: String) {
    person("person"), company("company");

    val id: String get() = raw
    val title: String get() = if (this == person) "นามบุคคล" else "นามบริษัท"
    val detail: String get() = if (this == person) "รับเงินเข้าบัญชีชื่อคุณเอง" else "ออกในนามนิติบุคคล"
    val icon: Ph get() = if (this == person) Ph.user else Ph.buildings
    /** หัก ณ ที่จ่าย % — ค่าเดียวกับฟอร์มเว็บ (บุคคล 3 · นิติบุคคล 7) */
    val withholding: Int get() = if (this == person) 3 else 7
    /** เอกสารที่ **ยังไม่ต้องส่ง** — ขอตอนได้งานแรก */
    val later: List<String> get() =
        if (this == person) listOf("สำเนาบัตรประชาชน เซ็นรับรองสำเนาถูกต้อง")
        else listOf("หนังสือรับรองบริษัท อายุไม่เกิน 6 เดือน", "ภ.พ.20 (เฉพาะกรณีจด VAT)", "สำเนาบัตรประชาชนกรรมการผู้มีอำนาจ")

    companion object {
        fun from(raw: String?): PayKind? = entries.firstOrNull { it.raw == raw }
    }
}

/** บัญชีที่จะให้เงินเข้า — เก็บเลขบัญชี/เลขผู้เสียภาษีเป็นตัวเลขล้วน จัดรูปแบบตอนแสดง · รูปหน้าสมุดอยู่ใน `PhotoStore.bookBank` */
@Serializable
data class PaymentInfo(
    val kind: PayKind? = null,
    val bank: String = "",
    val accountNo: String = "",
    val accountName: String = "",
    val bookPhoto: Boolean = false,
    // เฉพาะนิติบุคคล
    val companyName: String = "",
    val taxId: String = "",
    val branch: String = "",
    val address: String = "",
    val signer: String = "",
    val vat: String = "",
) {
    companion object {
        /** xxx-x-xxxxx-x */
        fun formatAccount(digits: String): String {
            val out = StringBuilder()
            digits.filter { it.isDigit() }.take(10).forEachIndexed { i, ch ->
                if (i == 3 || i == 4 || i == 9) out.append("-")
                out.append(ch)
            }
            return out.toString()
        }
    }
}

@Serializable
data class IntakeData(
    val kind: CreatorKind? = null,
    val socials: List<SocialEntry> = emptyList(),
    /** หมวดทางการที่เลือก (สูงสุด `IntakeCatalog.maxInterests`) — ใช้จับคู่งาน จึงเลือกจากรายการเท่านั้น */
    val interests: List<String> = emptyList(),
    val rates: List<RateCell> = emptyList(),
    val availability: Availability = Availability(),
    val personal: PersonalInfo = PersonalInfo(),
    /** optional เพราะเพิ่มทีหลัง — ข้อมูลที่เซฟไว้ก่อนหน้าไม่มีคีย์นี้ ต้องถอดรหัสผ่าน */
    val payment: PaymentInfo? = null,
    /** epoch millis */
    val consentAt: Long? = null,
    val status: ReviewStatus = ReviewStatus.draft,
    /** epoch millis */
    val importedAt: Long? = null,
    /** ผ่านหน้ากรอกครั้งแรกครบ 4 ขั้นแล้ว — หลังจากนี้เข้าหน้า "ข้อมูลของฉัน" ได้ตรง ๆ */
    val firstRunDone: Boolean = false,
) {
    val enabledSocials: List<SocialEntry> get() = socials.filter { it.enabled }

    fun social(t: SocialType): SocialEntry? = socials.firstOrNull { it.type == t }
    fun rate(p: SocialType, f: ContentFormat): RateCell? = rates.firstOrNull { it.platform == p && it.format == f }
}

// MARK: - รายการตัวเลือกของฟอร์ม

object IntakeCatalog {
    const val maxInterests = 5
    const val maxProvinces = 3

    /** หมวดทางการ (= tuple `(icon:, name:)`) */
    data class Interest(val icon: String, val name: String)

    /** หมวดทางการ — ชุดเดียวกับฟอร์มสมัครฝั่งเว็บ */
    val interests: List<Interest> = listOf(
        Interest("💄", "บิวตี้"), Interest("👗", "แฟชั่น"), Interest("🍜", "อาหาร & เครื่องดื่ม"), Interest("☕️", "คาเฟ่"),
        Interest("✨", "ไลฟ์สไตล์"), Interest("✈️", "ท่องเที่ยว"), Interest("💪", "สุขภาพ & ออกกำลังกาย"), Interest("👶", "แม่และเด็ก"),
        Interest("🐶", "สัตว์เลี้ยง"), Interest("📱", "เทคโนโลยี & แกดเจ็ต"), Interest("🎮", "เกม"), Interest("🪴", "บ้าน & สวน"),
        Interest("🚗", "รถยนต์ & ยานยนต์"), Interest("💰", "การเงิน & การลงทุน"), Interest("📚", "การศึกษา"), Interest("⚽️", "กีฬา"),
        Interest("🎬", "บันเทิง & ดารา"), Interest("🎪", "อีเวนต์ & กิจกรรม"),
    )

    fun icon(interest: String): String = interests.firstOrNull { it.name == interest }?.icon ?: "✨"

    /** หมวดที่ทำให้ส่วน "สัดส่วน" เด่นขึ้นมา — แบรนด์แฟชั่นต้องรู้ไซซ์ก่อนส่งของ */
    const val fashion = "แฟชั่น"

    // MARK: Vibe การทำงาน — ข้อ `days` `time` `draft` `limit` ของฟอร์มเว็บ

    /** วันที่ว่างรับงาน — ข้อ `days` (ค่า · ชื่อ · คำอธิบาย · ไอคอน · ชุดวัน 0 = อาทิตย์) */
    data class DayOption(val value: String, val label: String, val detail: String, val icon: Ph, val days: Set<Int>) {
        val id: String get() = value
    }

    val dayOptions: List<DayOption> = listOf(
        DayOption(value = "ทุกวัน", label = "สะดวกทุกวัน", detail = "จันทร์ – อาทิตย์", icon = Ph.calendarDots, days = (0 until 7).toSet()),
        DayOption(value = "เสาร์–อาทิตย์", label = "เฉพาะเสาร์–อาทิตย์", detail = "วันหยุดสุดสัปดาห์", icon = Ph.sunHorizon, days = setOf(0, 6)),
        DayOption(value = "จันทร์–ศุกร์", label = "เฉพาะวันธรรมดา", detail = "จันทร์ – ศุกร์", icon = Ph.briefcase, days = (1..5).toSet()),
    )

    /** ช่วงเวลา (= tuple `(value:, label:, slots:)`) — ช่องของ `WorkTime.slotNames` ที่หมายถึง */
    data class TimeOption(val value: String, val label: String, val slots: Set<Int>)

    val timeOptions: List<TimeOption> = listOf(
        TimeOption("เช้า", "เช้า (9.00–12.00)", setOf(0)),
        TimeOption("บ่าย", "บ่าย (12.00–17.00)", setOf(1, 2)),
        TimeOption("เย็น", "เย็น (17.00 เป็นต้นไป)", setOf(3)),
        TimeOption("ตลอดวัน", "ตลอดวัน", setOf(0, 1, 2, 3)),
    )

    const val draftNote = "ถ้าแก้ครบรอบแล้วงานยังไม่ตรงบรีฟ?\n· งานที่ไม่ตรงบรีฟเดิม — ยังไม่นับเป็นรอบแก้ ครีเอเตอร์ปรับให้ตรงก่อน ไม่คิดเงินเพิ่ม\n· แบรนด์เพิ่มโจทย์ใหม่นอกบรีฟ — นับเป็นงานเพิ่ม คุยเรทกันใหม่ได้\n· ตกลงกันไม่ได้ — แจ้งทีม Sale Here เข้าไปช่วยดูให้ทั้งสองฝั่ง"

    const val noLimit = "ไม่มีข้อจำกัด"

    /** งานที่ขอผ่าน (= tuple `(label:, value:)`) — ชื่อบนชิป · ค่าที่เก็บ = ข้อความเต็มของฟอร์มเว็บ */
    data class LimitOption(val label: String, val value: String)

    /** งานที่ขอผ่าน — ข้อแรกตัดข้ออื่นทั้งหมด */
    val limits: List<LimitOption> = listOf(
        LimitOption("😄 รับได้หมดเลย", "ไม่มีข้อจำกัด"),
        LimitOption("💳 สินเชื่อ / คริปโต", "ไม่รับงานสินเชื่อ / คริปโต"),
        LimitOption("🍺 แอลกอฮอล์ / บุหรี่", "ไม่รับงานแอลกอฮอล์ / บุหรี่ / บุหรี่ไฟฟ้า"),
        LimitOption("💊 อาหารเสริม / ลดน้ำหนัก", "ไม่รับงานอาหารเสริม / ลดน้ำหนัก"),
        LimitOption("💉 ความงามเชิงการแพทย์", "ไม่รับงานความงามเชิงการแพทย์ (ศัลยกรรม / ฉีด)"),
    )
    const val otherLimitPlaceholder = "เช่น ไม่รับงานที่ต้องค้างคืนต่างจังหวัด"

    /** ไซซ์สำหรับสายแฟชั่น (= tuple `(field:, label:, placeholder:, unit:)`) — หน่วยที่ต่อท้ายให้การ์ด */
    data class FashionField(val field: ProfileField, val label: String, val placeholder: String, val unit: String)

    val fashionFields: List<FashionField> = listOf(
        FashionField(ProfileField.height, "ส่วนสูง (ซม.)", "165", "ซม."), FashionField(ProfileField.weight, "น้ำหนัก (กก.)", "50", "กก."),
        FashionField(ProfileField.bust, "รอบอก (นิ้ว)", "32", "นิ้ว"), FashionField(ProfileField.waist, "รอบเอว (นิ้ว)", "25", "นิ้ว"),
        FashionField(ProfileField.hips, "สะโพก (นิ้ว)", "35", "นิ้ว"), FashionField(ProfileField.shoe, "ไซซ์รองเท้า (ซม.)", "23", "ซม."),
    )

    val draftRounds = listOf(1, 2, 3)

    /** ธนาคาร — รายการเดียวกับ `BANKS` ของฟอร์มเว็บ */
    val banks = listOf("กสิกรไทย", "ไทยพาณิชย์", "กรุงเทพ", "กรุงไทย", "กรุงศรีอยุธยา", "ทหารไทยธนชาต (ttb)",
        "ออมสิน", "ธ.ก.ส.", "เกียรตินาคินภัทร", "ซีไอเอ็มบี ไทย", "ยูโอบี", "แลนด์ แอนด์ เฮ้าส์", "อื่น ๆ")
    val branches = listOf("สำนักงานใหญ่", "สาขาที่ 00001", "สาขาที่ 00002", "สาขาอื่น ๆ")
    val vatOptions = listOf("จดทะเบียน VAT (มี ภ.พ.20)", "ไม่ได้จดทะเบียน VAT")

    val genders = listOf("หญิง", "ชาย", "LGBTQ+", "ไม่ขอระบุ")
    val religions = listOf("พุทธ", "อิสลาม", "คริสต์", "ฮินดู", "อื่น ๆ / ไม่ระบุ")

    /** ข้อ `job` — ค่า `v` · ชื่อ · คำอธิบาย · ไอคอน */
    data class JobOption(val key: String, val title: String, val detail: String, val icon: Ph) {
        val id: String get() = key
    }

    val jobs: List<JobOption> = listOf(
        JobOption(key = "student", title = "นักเรียน / นักศึกษา", detail = "กำลังศึกษาอยู่", icon = Ph.student),
        JobOption(key = "work", title = "วัยทำงาน", detail = "พนักงาน/ฟรีแลนซ์/ธุรกิจ/ราชการ", icon = Ph.briefcase),
        JobOption(key = "other", title = "อื่น ๆ", detail = "แม่บ้าน / อินฟลูเอนเซอร์เต็มเวลา ฯลฯ", icon = Ph.sparkle),
    )
    val faculties = listOf("บริหารธุรกิจ / การจัดการ", "นิเทศ / สื่อสารมวลชน", "วิศวกรรมศาสตร์",
        "ไอที / วิทยาการคอมพิวเตอร์", "ครุศาสตร์ / ศึกษาศาสตร์", "อักษรศาสตร์ / มนุษยศาสตร์",
        "แพทย์ / พยาบาล / สาธารณสุข", "อื่น ๆ")
    val fields = listOf("การตลาด / โฆษณา", "ขาย / บริการลูกค้า", "ไอที / พัฒนาซอฟต์แวร์", "การเงิน / บัญชี",
        "ออกแบบ / ครีเอทีฟ", "การแพทย์ / สุขภาพ", "การศึกษา / ฝึกอบรม", "อื่น ๆ")

    val provinces = listOf("กรุงเทพมหานคร", "ทุกจังหวัด (งานออนไลน์)", "กระบี่", "กาญจนบุรี", "กาฬสินธุ์", "กำแพงเพชร",
        "ขอนแก่น", "จันทบุรี", "ฉะเชิงเทรา", "ชลบุรี", "ชัยนาท", "ชัยภูมิ", "ชุมพร", "เชียงราย", "เชียงใหม่", "ตรัง", "ตราด",
        "ตาก", "นครนายก", "นครปฐม", "นครพนม", "นครราชสีมา", "นครศรีธรรมราช", "นครสวรรค์", "นนทบุรี", "นราธิวาส", "น่าน",
        "บึงกาฬ", "บุรีรัมย์", "ปทุมธานี", "ประจวบคีรีขันธ์", "ปราจีนบุรี", "ปัตตานี", "พระนครศรีอยุธยา", "พะเยา", "พังงา",
        "พัทลุง", "พิจิตร", "พิษณุโลก", "เพชรบุรี", "เพชรบูรณ์", "แพร่", "ภูเก็ต", "มหาสารคาม", "มุกดาหาร", "แม่ฮ่องสอน",
        "ยโสธร", "ยะลา", "ร้อยเอ็ด", "ระนอง", "ระยอง", "ราชบุรี", "ลพบุรี", "ลำปาง", "ลำพูน", "เลย", "ศรีสะเกษ", "สกลนคร",
        "สงขลา", "สตูล", "สมุทรปราการ", "สมุทรสงคราม", "สมุทรสาคร", "สระแก้ว", "สระบุรี", "สิงห์บุรี", "สุโขทัย", "สุพรรณบุรี",
        "สุราษฎร์ธานี", "สุรินทร์", "หนองคาย", "หนองบัวลำภู", "อ่างทอง", "อำนาจเจริญ", "อุดรธานี", "อุตรดิตถ์", "อุทัยธานี",
        "อุบลราชธานี")

    /** ระดับตามยอดผู้ติดตามของ **ช่องเดียว** — วงการแบ่งกันต่อแพลตฟอร์ม ไม่ใช่ยอดรวมทุกช่อง */
    fun tier(n: Int): String = when {
        n < 10_000 -> "Nano"
        n < 50_000 -> "Micro"
        n < 500_000 -> "Mid-tier"
        else -> "Macro"
    }

    // MARK: เรทแนะนำ — สูตร `recoRate` ของฟอร์มเว็บ
    // CPM ต่อพันผู้ติดตาม ลดหลั่นตามช่วง (ถึง 1 หมื่น · 5 หมื่น · 5 แสน · เกินนั้น) · ขั้นต่ำต่อแพลตฟอร์ม · ปัดเป็นร้อย

    val followerBreaks = listOf(10_000, 50_000, 500_000)

    /** ผลของ `cpm(p)` (= tuple `(cpm:, min:)`) */
    data class Cpm(val cpm: List<Double>, val min: Int)

    fun cpm(p: SocialType): Cpm = when (p) {
        SocialType.instagram -> Cpm(listOf(90.0, 60.0, 40.0, 25.0), 500)
        SocialType.tiktok -> Cpm(listOf(100.0, 70.0, 45.0, 28.0), 600)
        SocialType.facebook -> Cpm(listOf(80.0, 55.0, 35.0, 20.0), 500)
        SocialType.youtube -> Cpm(listOf(250.0, 180.0, 120.0, 70.0), 2_000)
        SocialType.lemon8 -> Cpm(listOf(70.0, 45.0, 30.0, 18.0), 400)
        SocialType.x -> Cpm(listOf(60.0, 40.0, 25.0, 15.0), 400)
    }

    /** เรทฐานของแพลตฟอร์ม (รูปแบบหลัก m = 1) · 0 = ยังไม่รู้ยอดผู้ติดตาม */
    fun recoRate(p: SocialType, followers: Int): Int {
        if (followers <= 0) return 0
        val r = cpm(p)
        var sum = 0.0
        var prev = 0
        followerBreaks.forEachIndexed { i, b ->
            val part = max(0, min(followers, b) - prev)
            sum += part.toDouble() / 1_000 * r.cpm[i]
            prev = b
        }
        if (followers > prev) sum += (followers - prev).toDouble() / 1_000 * r.cpm[3]
        sum = max(sum, r.min.toDouble())
        return (sum / 100).roundToInt() * 100
    }

    /** เรทแนะนำของรูปแบบหนึ่ง = เรทฐาน × ตัวคูณ ปัดเป็นร้อย */
    fun reco(p: SocialType, followers: Int, format: PlatFormat): Int {
        val base = recoRate(p, followers)
        return if (base > 0) (base.toDouble() * format.m / 100).roundToInt() * 100 else 0
    }

    /** ต่ำกว่านี้ = "ต่ำกว่าที่คนอื่นรับ" · สูงกว่า `recoHigh` = "แบรนด์อาจต่อรอง" */
    fun recoLow(v: Int): Int = (v.toDouble() * 0.7 / 100).roundToInt() * 100
    fun recoHigh(v: Int): Int = (v.toDouble() * 1.4 / 100).roundToInt() * 100

    /** จำลองยอดที่ API/OAuth จะส่งกลับมา — **ใช้เฉพาะโปรโตไทป์** ยังไม่ได้ต่อของจริง (FNV-1a 32 บิต) */
    fun simulatedFollowers(seed: String): Int {
        var h = 2_166_136_261u
        for (b in seed.toByteArray(Charsets.UTF_8)) {
            h = h xor b.toUByte().toUInt()
            h *= 16_777_619u
        }
        return 2_400 + (h % 418_000u).toInt()
    }
}

// MARK: - ความรู้เรื่องลิงก์ของแต่ละแพลตฟอร์ม

enum class FetchMode {
    /** ดึงยอดจากลิงก์ได้เลย (YouTube Data API) */
    api,
    /** ต้องให้เจ้าของบัญชีกดอนุญาต (OAuth) */
    connect,
    /** ไม่มี API ให้ดึง — กรอกเองแล้วทีมงานตรวจ */
    manual,
}

val SocialType.shortName: String get() = when (this) {
    SocialType.instagram -> "IG"
    SocialType.tiktok -> "TikTok"
    SocialType.youtube -> "YouTube"
    SocialType.facebook -> "FB"
    SocialType.lemon8 -> "Lemon8"
    SocialType.x -> "X"
}

val SocialType.placeholderLink: String get() = when (this) {
    SocialType.instagram -> "https://instagram.com/username"
    SocialType.tiktok -> "https://tiktok.com/@username"
    SocialType.youtube -> "https://youtube.com/@channelname"
    SocialType.facebook -> "https://facebook.com/yourpage"
    SocialType.lemon8 -> "https://lemon8-app.com/@username"
    SocialType.x -> "https://x.com/username"
}

val SocialType.fetch: FetchMode get() = when (this) {
    SocialType.youtube -> FetchMode.api
    SocialType.instagram, SocialType.tiktok, SocialType.facebook -> FetchMode.connect
    SocialType.lemon8, SocialType.x -> FetchMode.manual
}

/** ทำไมช่องนี้ดึงเองได้/ไม่ได้ — โชว์ให้ผู้สมัครเข้าใจ ไม่ใช่ซ่อนไว้ในโค้ด */
val SocialType.fetchNote: String get() = when (this) {
    SocialType.instagram -> "ดึงยอดได้เฉพาะบัญชี Business/Creator ที่กดเชื่อมบัญชีแล้ว"
    SocialType.tiktok -> "ต้องล็อกอินอนุญาตก่อน ไม่มี API สาธารณะสำหรับลิงก์โปรไฟล์"
    SocialType.facebook -> "ยอดผู้ติดตามเพจต้องได้สิทธิ์จากแอดมินเพจก่อน"
    SocialType.youtube -> "ดึงจากลิงก์ช่องได้ทันที (ยอดที่ได้เป็นเลขปัดหลัก)"
    SocialType.lemon8 -> "ยังไม่เปิด API — กรอกเองแล้วทีมงานตรวจจากหน้าโปรไฟล์"
    SocialType.x -> "API เปิดเฉพาะแพ็กเกจเสียเงิน — กรอกเองไปก่อน"
}

/** รูปแบบงานของแพลตฟอร์ม — `PLAT[].fmts` ของฟอร์มเว็บ ครบทุกคีย์ ชื่อ และตัวคูณ */
val SocialType.formats: List<PlatFormat> get() = when (this) {
    SocialType.instagram -> listOf(
        PlatFormat(key = "post", label = "ภาพลงฟีด (1–3 ภาพ)", m = 1.0, isDefault = true, generic = ContentFormat.photo),
        PlatFormat(key = "carousel", label = "อัลบั้มรีวิว (4–10 ภาพ)", m = 1.3, generic = ContentFormat.photo),
        PlatFormat(key = "reels", label = "Reels", m = 1.6, generic = ContentFormat.shortVideo),
        PlatFormat(key = "story", label = "Story (ชุด 3 สไลด์)", m = 0.5, generic = ContentFormat.photo),
        PlatFormat(key = "live", label = "IG Live", m = 2.2, generic = ContentFormat.longVideo))
    SocialType.tiktok -> listOf(
        PlatFormat(key = "short", label = "คลิปสั้น (ไม่เกิน 60 วิ)", m = 1.0, isDefault = true, generic = ContentFormat.shortVideo),
        PlatFormat(key = "long", label = "คลิปยาว (1–3 นาที)", m = 1.5, generic = ContentFormat.longVideo),
        PlatFormat(key = "series", label = "ซีรีส์ 3 คลิปต่อเนื่อง", m = 2.4, generic = ContentFormat.longVideo),
        PlatFormat(key = "live", label = "TikTok LIVE (1 ชม.)", m = 2.6, generic = ContentFormat.longVideo))
    SocialType.facebook -> listOf(
        PlatFormat(key = "post", label = "โพสต์ภาพ + แคปชัน", m = 1.0, isDefault = true, generic = ContentFormat.photo),
        PlatFormat(key = "album", label = "อัลบั้มรีวิว", m = 1.3, generic = ContentFormat.photo),
        PlatFormat(key = "reels", label = "Facebook Reels", m = 1.4, generic = ContentFormat.shortVideo),
        PlatFormat(key = "video", label = "วิดีโอยาว (3 นาทีขึ้นไป)", m = 1.8, generic = ContentFormat.longVideo),
        PlatFormat(key = "live", label = "Facebook Live", m = 2.2, generic = ContentFormat.longVideo))
    SocialType.youtube -> listOf(
        PlatFormat(key = "shorts", label = "YouTube Shorts", m = 0.5, generic = ContentFormat.shortVideo),
        PlatFormat(key = "integrated", label = "แทรกในคลิป (60–90 วิ)", m = 1.0, isDefault = true, generic = ContentFormat.longVideo),
        PlatFormat(key = "dedicated", label = "คลิปรีวิวเต็ม (Dedicated)", m = 1.8, generic = ContentFormat.longVideo))
    SocialType.lemon8 -> listOf(
        PlatFormat(key = "photo", label = "โพสต์ภาพ (Photo Set)", m = 1.0, isDefault = true, generic = ContentFormat.photo),
        PlatFormat(key = "review", label = "รีวิวยาว + แท็กสินค้า", m = 1.5, generic = ContentFormat.seeding))
    SocialType.x -> listOf(
        PlatFormat(key = "post", label = "โพสต์ + ภาพ", m = 1.0, isDefault = true, generic = ContentFormat.photo),
        PlatFormat(key = "thread", label = "เธรดรีวิว (3 โพสต์ขึ้นไป)", m = 1.7, generic = ContentFormat.seeding))
}

val SocialType.defaultFormat: PlatFormat get() = formats.firstOrNull { it.isDefault } ?: formats[0]

/** ดึงยอดได้แค่ไหน — คำสั้นในกล่อง "ช่องทางไหนดึงยอดอัตโนมัติได้จริงบ้าง" */
val SocialType.fetchLabel: String get() = when (fetch) {
    FetchMode.api -> "ดึงจากลิงก์ได้"
    FetchMode.connect -> "ต้องเชื่อมบัญชี"
    FetchMode.manual -> "กรอกเองเท่านั้น"
}

/** คำอธิบายเชิงเทคนิค — `PLAT[].api` ของฟอร์มเว็บ */
val SocialType.apiNote: String get() = when (this) {
    SocialType.instagram -> "Instagram Graph API — ดึงยอดผู้ติดตามได้เฉพาะบัญชี Business/Creator ที่กด \"เชื่อมบัญชี\" ให้สิทธิ์แล้วเท่านั้น ดึงจากลิงก์เปล่าไม่ได้"
    SocialType.tiktok -> "TikTok Login Kit / Display API — follower_count ต้องให้ผู้ใช้ล็อกอินอนุญาตก่อน ไม่มี endpoint สาธารณะสำหรับลิงก์โปรไฟล์"
    SocialType.facebook -> "Facebook Graph API — followers_count ของเพจต้องใช้ Page Access Token ที่แอดมินเพจกดอนุญาต ดึงจากลิงก์เพจเฉย ๆ ไม่ได้"
    SocialType.youtube -> "YouTube Data API v3 (channels.list · part=statistics) — ดึงจากลิงก์ช่องได้จริงด้วย API key ไม่ต้องให้เจ้าของอนุญาต แต่ subscriberCount ที่ได้เป็นเลขปัดหลัก และเป็น 0 ถ้าช่องซ่อนยอด"
    SocialType.lemon8 -> "ไม่มี Public API — Lemon8 ยังไม่เปิด developer platform ให้ดึงข้อมูลโปรไฟล์ ต้องให้ผู้สมัครกรอกเองและแนบภาพหน้าโปรไฟล์ยืนยัน"
    SocialType.x -> "X API v2 (users/by/username · public_metrics) — เปิดดูได้เฉพาะแพ็กเกจเสียเงิน (Basic ขึ้นไป) ไม่มีชั้นฟรี จึงใช้วิธีกรอกเองไปก่อน"
}

/** ลำดับที่โชว์ในฟอร์ม — ช่องที่คนไทยใช้รับงานมากสุดขึ้นก่อน */
val SocialType.formOrder: Int get() = when (this) {
    SocialType.instagram -> 0
    SocialType.tiktok -> 1
    SocialType.facebook -> 2
    SocialType.youtube -> 3
    SocialType.lemon8 -> 4
    SocialType.x -> 5
}

private val SocialType.linkPattern: String get() = when (this) {
    SocialType.instagram -> """^https?://(www\.)?instagram\.com/[A-Za-z0-9._]{1,30}/?(\?.*)?$"""
    SocialType.tiktok -> """^https?://(www\.)?tiktok\.com/@[A-Za-z0-9._]{1,30}/?(\?.*)?$"""
    SocialType.facebook -> """^https?://(www\.|web\.|m\.)?(facebook\.com|fb\.com)/([A-Za-z0-9.]{3,60}|profile\.php\?id=\d+)/?(\?.*)?$"""
    SocialType.youtube -> """^https?://(www\.)?youtube\.com/(@[A-Za-z0-9._-]{3,30}|channel/UC[\w-]{22}|c/[A-Za-z0-9._-]+)/?(\?.*)?$"""
    SocialType.lemon8 -> """^https?://(www\.)?lemon8[\w.-]*/[@A-Za-z0-9._/-]+$"""
    SocialType.x -> """^https?://(www\.)?(x|twitter)\.com/[A-Za-z0-9_]{1,15}/?(\?.*)?$"""
}

/** ลิงก์โพสต์ที่คนชอบวางผิด — บอกให้ชัดว่าต้องการหน้าโปรไฟล์ ไม่ใช่ "รูปแบบไม่ถูกต้อง" ลอย ๆ */
private val SocialType.postPattern: String? get() = when (this) {
    SocialType.instagram -> """/(p|reel|reels|stories|explore)/"""
    SocialType.tiktok -> """/(video|photo)/"""
    SocialType.facebook -> """/(posts|photo|videos|watch|groups)/"""
    SocialType.youtube -> """/(watch|shorts|playlist)"""
    SocialType.x -> """/status/"""
    SocialType.lemon8 -> null
}

/** ทำให้เป็น URL เต็ม — ผู้ใช้วาง `tiktok.com/@x` มาก็ต้องผ่าน */
fun SocialType.normalizedLink(raw: String): String {
    val s = raw.trim()
    if (s.isEmpty()) return ""
    return if (s.lowercase().startsWith("http")) s else "https://$s"
}

/** ข้อความผิดพลาดของลิงก์ — null = ใช้ได้ (หรือยังว่าง — ความว่างเป็นเรื่องของ "ต้องกรอก" ไม่ใช่ "ผิด") */
fun SocialType.linkError(raw: String): String? {
    val s = normalizedLink(raw)
    if (s.isEmpty()) return null
    val bad = postPattern
    if (bad != null && regexMatches(bad, s, whole = false)) {
        return "นี่คือลิงก์โพสต์ ไม่ใช่ลิงก์โปรไฟล์ — ใส่ลิงก์หน้าโปรไฟล์/ช่องแทน"
    }
    if (!regexMatches(linkPattern, s, whole = true)) {
        return "รูปแบบลิงก์ $name ไม่ถูกต้อง (ตัวอย่าง: $placeholderLink)"
    }
    return null
}

/** ชื่อผู้ใช้จากลิงก์ — ใช้เป็น handle ตั้งต้นของการ์ด */
fun SocialType.handle(from: String): String {
    val s = normalizedLink(from)
    if (s.isEmpty()) return ""
    val uri = runCatching { URI(s) }.getOrNull() ?: return ""
    val parts = (uri.path ?: "").split("/").filter { it.isNotEmpty() && it != "/" }
    val first = parts.firstOrNull() ?: return ""
    var h = first
    if ((h == "channel" || h == "c") && parts.size > 1) h = parts[1]
    if (this == SocialType.lemon8) parts.lastOrNull { it.startsWith("@") }?.let { h = it }
    if (h.startsWith("@")) h = h.drop(1)
    return h
}

private fun regexMatches(pattern: String, s: String, whole: Boolean): Boolean {
    val re = runCatching { Regex(pattern, RegexOption.IGNORE_CASE) }.getOrNull() ?: return false
    return if (whole) re.matchEntire(s) != null else re.containsMatchIn(s)
}

/**
 * จำลองเครือข่ายของ `ChannelsSection` (YouTube Data API 700ms · OAuth 800ms) — คืนยอดผู้ติดตามจำลองจาก seed
 * **ใช้เฉพาะโปรโตไทป์** — ตัวเรียกเป็นคนเขียนผลลง `Profile.me.updateIntake` เอง เหมือนฝั่ง iOS
 */
internal suspend fun SocialType.simulateFetch(seed: String): Int {
    delay(if (fetch == FetchMode.api) 700L else 800L)
    return IntakeCatalog.simulatedFollowers(seed)
}

/** ชื่อไทยสั้น ๆ สำหรับฟอร์มและชื่อรายการมาตรฐานบนการ์ด */
val ContentFormat.title: String get() = when (this) {
    ContentFormat.photo -> "ภาพนิ่ง"
    ContentFormat.shortVideo -> "คลิปสั้น"
    ContentFormat.longVideo -> "คลิปยาว"
    ContentFormat.seeding -> "แชร์ / Story"
}

val ContentFormat.unit: String get() = when (this) {
    ContentFormat.photo -> "ชิ้น"
    ContentFormat.shortVideo -> "คลิป"
    ContentFormat.longVideo -> "คลิป"
    ContentFormat.seeding -> "ชุด"
}
