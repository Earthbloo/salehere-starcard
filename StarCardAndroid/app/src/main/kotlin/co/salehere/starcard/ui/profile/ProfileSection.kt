package co.salehere.starcard.ui.profile

import androidx.compose.ui.graphics.Color
import co.salehere.starcard.model.Fmt
import co.salehere.starcard.model.IntakeCatalog
import co.salehere.starcard.model.PayKind
import co.salehere.starcard.model.PaymentInfo
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.SocialType
import co.salehere.starcard.model.shortName
import co.salehere.starcard.theme.Ph

// MARK: - ส่วนของ "ข้อมูลของฉัน" (= ProfileSection.swift)
//
// หน้าโปรไฟล์คือ hub ของส่วนที่แก้ทีละส่วนได้ตลอด (ผู้ใช้มาสามแบบ: ยังไม่เคยกรอก · เคยกรอกในระบบเดิม · ต้องอัปเดต)
//
// **ทุกขั้นและทุกช่องเป็นสำเนาของฟอร์มเว็บ `roojai-influencer-v16.1` (`var Q=[…]` + `SUB` + `PLAT` + `PAYDOC`) —
// ทีม MKT กำหนด ห้ามสลับลำดับ ห้ามเพิ่ม/ตัดช่อง:**
// type + chan → cats (+ fashion) → pay → terms (days→time · draft · limit · province)
// → person (name · basic · gender · religion · job→faculty/field) → consent → STAR Card

enum class ProfileSection(val raw: String) {
    channels("channels"), interests("interests"), payment("payment"), terms("terms"), person("person"), consent("consent");

    val id: String get() = raw

    val isRequired: Boolean get() = true

    /** ชื่อส่วน = `sec` ของฟอร์มเว็บ */
    val title: String get() = when (this) {
        channels -> "ช่องทางของฉัน"
        interests -> "สายที่ใช่"
        payment -> "การรับเงิน"
        terms -> "Vibe การทำงาน"
        person -> "ทำความรู้จักกัน"
        consent -> "ยืนยัน"
    }

    /** บรรทัดใต้คำถาม = `sub` ของฟอร์มเว็บ */
    val purpose: String get() = when (this) {
        channels -> "วางลิงก์ ระบบดึงยอดฟอลและจัดเรทให้"
        interests -> "เลือกได้สูงสุด ${IntakeCatalog.maxInterests} หมวด"
        payment -> "ตอนนี้ขอแค่บัญชีธนาคาร"
        terms -> "เพื่อส่งเฉพาะงานที่เข้ากับคุณ"
        person -> "ใช้ติดต่อกลับและทำสัญญา"
        consent -> "เราดูแลข้อมูลคุณตาม PDPA"
    }

    /** คำถามตัวใหญ่บนหัวขั้น = `q` ของฟอร์มเว็บ */
    val question: String get() = when (this) {
        channels -> "แปะวาร์ปช่องของคุณเลย 📱"
        interests -> "คุณเป็นครีเอเตอร์สายไหน? 🎨"
        payment -> "รับเงินยังไงดี?"
        terms -> "Vibe การทำงานของคุณ"
        person -> "ขอทำความรู้จักกันอีกนิด 🙌"
        consent -> "ขออนุญาตเก็บข้อมูลนะ"
    }

    val icon: Ph get() = when (this) {
        channels -> Ph.broadcast
        interests -> Ph.sparkle
        payment -> Ph.creditCard
        terms -> Ph.calendarDots
        person -> Ph.userCircle
        consent -> Ph.lock
    }

    // MARK: ตรวจ

    /** สิ่งที่ยังขาดของส่วนนี้ — ว่าง = ผ่าน · กติกาเดียวกับ `validate()`/`platValid()`/`groupValid()` ของฟอร์มเว็บ */
    fun issues(p: Profile): List<ProfileIssue> {
        val d = p.intake ?: return emptyList()
        val out = mutableListOf<ProfileIssue>()
        when (this) {
            channels -> {
                if (d.kind == null) out.add(ProfileIssue(PField.kind, "เลือกว่าคุณเป็น Creator หรือ Page"))
                val on = d.enabledSocials
                if (on.isEmpty()) {
                    out.add(ProfileIssue(PField.channelsAny, "เลือกอย่างน้อย 1 ช่องทางเพื่อไปต่อ"))
                }
                for (e in on) {
                    val err = e.linkError
                    if (e.link.isBlank()) {
                        out.add(ProfileIssue(PField.link(e.type), "ใส่ลิงก์โปรไฟล์ ${e.type.name}"))
                    } else if (err != null) {
                        out.add(ProfileIssue(PField.link(e.type), "${e.type.name}: $err"))
                    }
                    if (e.followers <= 0) {
                        out.add(ProfileIssue(PField.followers(e.type), "ใส่ยอดผู้ติดตาม ${e.type.name}"))
                    }
                    if (d.rates.none { it.platform == e.type && it.price > 0 }) {
                        out.add(ProfileIssue(PField.rates(e.type), "ตั้งเรทอย่างน้อย 1 รูปแบบของ ${e.type.name}"))
                    }
                }
            }
            interests -> {
                if (d.interests.isEmpty()) out.add(ProfileIssue(PField.interests, "เลือกสายงานอย่างน้อย 1 หมวด"))
                if (d.interests.contains(IntakeCatalog.fashion)) {
                    for (f in IntakeCatalog.fashionFields) {
                        if (p.isPlaceholder(f.field)) out.add(ProfileIssue(PField.size(f.field), "ใส่${f.label}"))
                    }
                }
            }
            payment -> {
                val y = d.payment ?: PaymentInfo()
                val kind = y.kind
                if (kind == null) {
                    out.add(ProfileIssue(PField.payKind, "เลือกว่ารับเงินในนามบุคคลหรือบริษัท"))
                } else {
                    if (kind == PayKind.company) {
                        if (y.companyName.isBlank()) out.add(ProfileIssue(PField.companyName, "ใส่ชื่อนิติบุคคล"))
                        if (y.taxId.length != 13) out.add(ProfileIssue(PField.taxId, "เลขประจำตัวผู้เสียภาษีต้องมี 13 หลัก"))
                        if (y.branch.isEmpty()) out.add(ProfileIssue(PField.branch, "เลือกสำนักงานใหญ่หรือสาขา"))
                        if (y.address.isBlank()) out.add(ProfileIssue(PField.address, "ใส่ที่อยู่ตามหนังสือรับรอง"))
                        if (y.signer.isBlank()) out.add(ProfileIssue(PField.signer, "ใส่ชื่อกรรมการผู้มีอำนาจลงนาม"))
                        if (y.vat.isEmpty()) out.add(ProfileIssue(PField.vat, "เลือกว่าจดทะเบียน VAT หรือไม่"))
                    }
                    if (y.bank.isEmpty()) out.add(ProfileIssue(PField.bank, "เลือกธนาคาร"))
                    if (y.accountNo.length != 10) out.add(ProfileIssue(PField.accountNo, "เลขที่บัญชีต้องมี 10 หลัก"))
                    if (y.accountName.isBlank()) out.add(ProfileIssue(PField.accountName, "ใส่ชื่อบัญชี"))
                    if (!y.bookPhoto) out.add(ProfileIssue(PField.bookPhoto, "ถ่ายหน้าสมุดบัญชี"))
                }
            }
            terms -> {
                val a = d.availability
                if (a.days.isEmpty()) out.add(ProfileIssue(PField.days, "เลือกวันที่ว่างรับงาน"))
                else if (a.slots.isEmpty()) out.add(ProfileIssue(PField.time, "เลือกช่วงเวลาของวัน"))
                if (a.draftRounds == null) out.add(ProfileIssue(PField.draft, "เลือกจำนวนรอบที่แก้งานให้ได้"))
            }
            person -> {
                if (p.isPlaceholder(ProfileField.personName)) out.add(ProfileIssue(PField.name, "ใส่ชื่อ–นามสกุลจริง"))
                val phone = if (p.isPlaceholder(ProfileField.phone)) "" else p.phone
                val email = if (p.isPlaceholder(ProfileField.email)) "" else p.email
                val line = if (p.isPlaceholder(ProfileField.lineId)) "" else p.lineId
                if (phone.isEmpty()) out.add(ProfileIssue(PField.phone, "ใส่เบอร์โทรศัพท์"))
                else if (!ProfileRules.validPhone(phone)) out.add(ProfileIssue(PField.phone, "เบอร์โทรต้องมี 9–10 หลัก"))
                if (email.isEmpty()) out.add(ProfileIssue(PField.email, "ใส่อีเมล"))
                else if (!ProfileRules.validEmail(email)) out.add(ProfileIssue(PField.email, "รูปแบบอีเมลไม่ถูกต้อง"))
                if (line.isEmpty()) out.add(ProfileIssue(PField.line, "ใส่ Line ID"))
                val b = d.personal
                if (b.dob == null) out.add(ProfileIssue(PField.dob, "เลือกวันเกิด"))
                if (b.nationality.isBlank()) out.add(ProfileIssue(PField.nation, "ใส่สัญชาติ"))
                if (b.gender.isEmpty()) out.add(ProfileIssue(PField.gender, "เลือกเพศ"))
                if (b.religion.isEmpty()) out.add(ProfileIssue(PField.religion, "เลือกศาสนา"))
                if (b.job.isEmpty()) out.add(ProfileIssue(PField.job, "เลือกว่าตอนนี้ทำอะไรอยู่"))
                else if (b.job == "student" && b.faculty.isEmpty()) out.add(ProfileIssue(PField.faculty, "เลือกคณะที่เรียน"))
                else if (b.job == "work" && b.field.isEmpty()) out.add(ProfileIssue(PField.field, "เลือกสายงานที่ทำ"))
            }
            consent -> {
                if (d.consentAt == null) out.add(ProfileIssue(PField.consent, "กดยินยอมก่อนนะ แล้วไปต่อได้เลย"))
            }
        }
        return out
    }

    /** มีอะไรกรอกไว้บ้างแล้วไหม — แยก "ยังไม่แตะ" ออกจาก "แตะแล้วแต่ไม่ครบ" */
    private fun touched(p: Profile): Boolean {
        val d = p.intake ?: return false
        return when (this) {
            channels -> d.socials.isNotEmpty() || d.kind != null
            interests -> d.interests.isNotEmpty()
            payment -> d.payment?.let { it.kind != null || it.bank.isNotEmpty() || it.accountNo.isNotEmpty() } ?: false
            terms -> {
                val a = d.availability
                a.days.isNotEmpty() || a.slots.isNotEmpty() || a.draftRounds != null || a.limits.isNotEmpty() || a.provinces.isNotEmpty()
            }
            person -> {
                val b = d.personal
                !p.isPlaceholder(ProfileField.personName) || !p.isPlaceholder(ProfileField.phone) ||
                    !p.isPlaceholder(ProfileField.email) || !p.isPlaceholder(ProfileField.lineId) ||
                    b.dob != null || b.gender.isNotEmpty() || b.religion.isNotEmpty() || b.job.isNotEmpty()
            }
            consent -> d.consentAt != null
        }
    }

    fun status(p: Profile): SectionStatus {
        if (p.intake == null) return SectionStatus.empty
        if (issues(p).isEmpty()) return SectionStatus.complete
        return if (touched(p)) SectionStatus.partial else SectionStatus.empty
    }

    /**
     * ค่าที่กรอกไว้จริงของส่วนนี้ — แถวใน hub เอาไปทำป้ายชิ้นละค่า ไม่ใช่ประโยคยาวบรรทัดเดียว
     * (ข้อความรวดเดียวสแกนยาก ตาต้องไล่อ่านทีละคำกว่าจะรู้ว่ากรอกอะไรไว้)
     */
    fun facts(p: Profile): List<String> {
        val d = p.intake ?: return emptyList()
        return when (this) {
            channels -> {
                val on = d.enabledSocials.filter { it.followers > 0 }
                if (on.isEmpty()) listOfNotNull(d.kind?.title)
                else on.map { "${it.type.shortName} ${Fmt.compact(it.followers)}" }
            }
            interests -> {
                if (d.interests.isEmpty()) emptyList()
                else {
                    val parts = d.interests.toMutableList()
                    if (d.interests.contains(IntakeCatalog.fashion) && !p.isPlaceholder(ProfileField.height)) {
                        parts.add(p.text(ProfileField.height))
                    }
                    parts
                }
            }
            payment -> {
                val y = d.payment
                val kind = y?.kind
                if (y == null || kind == null) emptyList()
                else {
                    val parts = mutableListOf(kind.title)
                    if (y.bank.isNotEmpty()) parts.add(y.bank)
                    if (y.accountNo.length >= 4) parts.add("···${y.accountNo.takeLast(4)}")
                    parts
                }
            }
            terms -> {
                val a = d.availability
                val parts = mutableListOf<String>()
                IntakeCatalog.dayOptions.firstOrNull { it.days == a.days }?.let { parts.add(it.value) }
                IntakeCatalog.timeOptions.firstOrNull { it.slots == a.slots }?.let { parts.add(it.value) }
                a.draftRounds?.let { parts.add("แก้ $it รอบ") }
                // ชื่อจังหวัดยาวกินที่ป้ายอื่นหมด — เกินหนึ่งจังหวัดบอกเป็นจำนวนพอ
                if (a.provinces.size == 1) parts.add(a.provinces[0])
                else if (a.provinces.size > 1) parts.add("${a.provinces.size} จังหวัด")
                parts
            }
            person -> {
                val parts = mutableListOf<String>()
                if (!p.isPlaceholder(ProfileField.personName)) parts.add(p.name)
                d.personal.age?.let { parts.add("$it ปี") }
                if (d.personal.gender.isNotEmpty()) parts.add(d.personal.gender)
                parts
            }
            consent -> if (d.consentAt == null) emptyList() else listOf("ยินยอมแล้ว")
        }
    }

    companion object {
        val required: List<ProfileSection> = entries.toList()
        val optional: List<ProfileSection> = emptyList()

        fun from(raw: String?): ProfileSection? = entries.firstOrNull { it.raw == raw }
    }
}

/** สิ่งที่ยังขาดหนึ่งข้อ — ชี้ไปที่ช่อง (`field` = id ของ `PKField`/ตำแหน่งบนหน้า) เพื่อเลื่อนไปหาได้ */
data class ProfileIssue(val field: String, val message: String) {
    val id: String get() = "${this.field}|$message"
}

enum class SectionStatus {
    empty, partial, complete;

    val label: String get() = when (this) {
        empty -> "ยังไม่ได้กรอก"
        partial -> "ยังขาดอีกนิด"
        complete -> "ครบแล้ว"
    }

    val color: Color get() = when (this) {
        empty -> PK.ink3
        partial -> PK.warn
        complete -> PK.ok
    }

    val symbol: Ph get() = when (this) {
        empty -> Ph.circleDashed
        partial -> Ph.circleHalf
        complete -> Ph.checkCircle
    }
}

/** id ของช่อง — ใช้ทั้งโฟกัสคีย์บอร์ดและเป็นเป้าเลื่อนไปหาเมื่อ validate ไม่ผ่าน */
object PField {
    const val kind = "channels.kind"
    fun link(t: SocialType): String = "channels.${t.raw}.link"
    fun followers(t: SocialType): String = "channels.${t.raw}.followers"
    fun rates(t: SocialType): String = "channels.${t.raw}.rates"
    fun price(t: SocialType, key: String): String = "channels.${t.raw}.rate.$key"
    const val channelsAny = "channels.any"

    const val interests = "interests.list"
    const val fashion = "interests.fashion"
    fun size(f: ProfileField): String = "interests.size.${f.raw}"

    const val payKind = "payment.kind"
    const val bank = "payment.bank"
    const val accountNo = "payment.accountNo"
    const val accountName = "payment.accountName"
    const val bookPhoto = "payment.book"
    const val companyName = "payment.companyName"
    const val taxId = "payment.taxId"
    const val branch = "payment.branch"
    const val address = "payment.address"
    const val signer = "payment.signer"
    const val vat = "payment.vat"

    const val days = "terms.days"
    const val time = "terms.time"
    const val draft = "terms.draft"
    const val limits = "terms.limits"
    const val otherLimit = "terms.otherLimit"
    const val provinces = "terms.provinces"

    const val name = "person.name"
    const val phone = "person.phone"
    const val email = "person.email"
    const val line = "person.line"
    const val dob = "person.dob"
    const val nation = "person.nation"
    const val gender = "person.gender"
    const val religion = "person.religion"
    const val job = "person.job"
    const val faculty = "person.faculty"
    const val field = "person.field"

    const val consent = "consent.box"
}

// MARK: - ตรวจ

object ProfileRules {
    private val emailPattern = Regex("""^[^\s@]+@[^\s@]+\.[^\s@]+$""")

    fun validEmail(s: String): Boolean {
        val t = s.trim()
        if (t.isEmpty()) return true
        return emailPattern.matches(t)
    }

    fun validPhone(s: String): Boolean {
        val digits = s.count { it.isDigit() }
        return s.isBlank() || digits in 9..10
    }
}

/** ส่วนจำเป็นครบทุกส่วน — พร้อมสร้างการ์ด/ส่งตรวจ */
val Profile.requiredComplete: Boolean
    get() = intake != null && ProfileSection.required.all { it.issues(this).isEmpty() }

val Profile.requiredDoneCount: Int
    get() = ProfileSection.required.count { it.status(this) == SectionStatus.complete }
