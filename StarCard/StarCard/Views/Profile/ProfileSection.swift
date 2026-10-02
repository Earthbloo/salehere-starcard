import SwiftUI
import PhosphorSwift

// MARK: - ส่วนของ "ข้อมูลของฉัน"
//
// หน้าโปรไฟล์คือ hub ของส่วนที่แก้ทีละส่วนได้ตลอด (ผู้ใช้มาสามแบบ: ยังไม่เคยกรอก · เคยกรอกในระบบเดิม · ต้องอัปเดต)
//
// **ทุกขั้นและทุกช่องเป็นสำเนาของฟอร์มเว็บ `roojai-influencer-v16.1` (`var Q=[…]` + `SUB` + `PLAT` + `PAYDOC`) —
// ทีม MKT กำหนด ห้ามสลับลำดับ ห้ามเพิ่ม/ตัดช่อง:**
// type + chan → cats (+ fashion) → pay → terms (days→time · draft · limit · province)
// → person (name · basic · gender · religion · job→faculty/field) → consent → STAR Card
// ทุกส่วนบังคับเหมือนเว็บ (ยกเว้น limit/province ที่เว็บก็ไม่บังคับ) · ช่องของการ์ด (ชื่อเล่น handle ฯลฯ) แก้บนการ์ดเท่านั้น

enum ProfileSection: String, CaseIterable, Identifiable, Hashable {
    case channels, interests, payment, terms, person, consent

    var id: String { rawValue }

    static let required: [ProfileSection] = allCases
    static let optional: [ProfileSection] = []

    var isRequired: Bool { true }

    /// ชื่อส่วน = `sec` ของฟอร์มเว็บ
    var title: String {
        switch self {
        case .channels:  return "ช่องทางของฉัน"
        case .interests: return "สายที่ใช่"
        case .payment:   return "การรับเงิน"
        case .terms:     return "Vibe การทำงาน"
        case .person:    return "ทำความรู้จักกัน"
        case .consent:   return "ยืนยัน"
        }
    }

    /// บรรทัดใต้คำถาม = `sub` ของฟอร์มเว็บ
    var purpose: String {
        switch self {
        case .channels:  return "วางลิงก์ ระบบดึงยอดฟอลและจัดเรทให้"
        case .interests: return "เลือกได้สูงสุด \(IntakeCatalog.maxInterests) หมวด"
        case .payment:   return "ตอนนี้ขอแค่บัญชีธนาคาร"
        case .terms:     return "เพื่อส่งเฉพาะงานที่เข้ากับคุณ"
        case .person:    return "ใช้ติดต่อกลับและทำสัญญา"
        case .consent:   return "เราดูแลข้อมูลคุณตาม PDPA"
        }
    }

    /// คำถามตัวใหญ่บนหัวขั้น = `q` ของฟอร์มเว็บ
    var question: String {
        switch self {
        case .channels:  return "แปะวาร์ปช่องของคุณเลย 📱"
        case .interests: return "คุณเป็นครีเอเตอร์สายไหน? 🎨"
        case .payment:   return "รับเงินยังไงดี?"
        case .terms:     return "Vibe การทำงานของคุณ"
        case .person:    return "ขอทำความรู้จักกันอีกนิด 🙌"
        case .consent:   return "ขออนุญาตเก็บข้อมูลนะ"
        }
    }

    var icon: Ph {
        switch self {
        case .channels:  return .broadcast
        case .interests: return .sparkle
        case .payment:   return .creditCard
        case .terms:     return .calendarDots
        case .person:    return .userCircle
        case .consent:   return .lock
        }
    }
}

/// สิ่งที่ยังขาดหนึ่งข้อ — ชี้ไปที่ช่อง (`field` = id ของ `PKField`/ตำแหน่งบนหน้า) เพื่อเลื่อนไปหาได้
struct ProfileIssue: Identifiable, Equatable {
    let field: String
    let message: String
    var id: String { field + "|" + message }
}

enum SectionStatus {
    case empty, partial, complete

    var label: String {
        switch self {
        case .empty:    return "ยังไม่ได้กรอก"
        case .partial:  return "ยังขาดอีกนิด"
        case .complete: return "ครบแล้ว"
        }
    }
    var color: Color {
        switch self {
        case .empty:    return PK.ink3
        case .partial:  return PK.warn
        case .complete: return PK.ok
        }
    }
    var symbol: Ph {
        switch self {
        case .empty:    return .circleDashed
        case .partial:  return .circleHalf
        case .complete: return .checkCircle
        }
    }
}

/// id ของช่อง — ใช้ทั้งโฟกัสคีย์บอร์ดและเป็นเป้าเลื่อนไปหาเมื่อ validate ไม่ผ่าน
enum PField {
    static let kind = "channels.kind"
    static func link(_ t: SocialType) -> String { "channels.\(t.rawValue).link" }
    static func followers(_ t: SocialType) -> String { "channels.\(t.rawValue).followers" }
    static func rates(_ t: SocialType) -> String { "channels.\(t.rawValue).rates" }
    static func price(_ t: SocialType, _ key: String) -> String { "channels.\(t.rawValue).rate.\(key)" }
    static let channelsAny = "channels.any"

    static let interests = "interests.list"
    static let fashion = "interests.fashion"
    static func size(_ f: ProfileField) -> String { "interests.size.\(f.rawValue)" }

    static let payKind = "payment.kind"
    static let bank = "payment.bank"
    static let accountNo = "payment.accountNo"
    static let accountName = "payment.accountName"
    static let bookPhoto = "payment.book"
    static let companyName = "payment.companyName"
    static let taxId = "payment.taxId"
    static let branch = "payment.branch"
    static let address = "payment.address"
    static let signer = "payment.signer"
    static let vat = "payment.vat"

    static let days = "terms.days"
    static let time = "terms.time"
    static let draft = "terms.draft"
    static let limits = "terms.limits"
    static let otherLimit = "terms.otherLimit"
    static let provinces = "terms.provinces"

    static let name = "person.name"
    static let phone = "person.phone"
    static let email = "person.email"
    static let line = "person.line"
    static let dob = "person.dob"
    static let nation = "person.nation"
    static let gender = "person.gender"
    static let religion = "person.religion"
    static let job = "person.job"
    static let faculty = "person.faculty"
    static let field = "person.field"

    static let consent = "consent.box"
}

// MARK: - ตรวจ

enum ProfileRules {
    static func validEmail(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return true }
        return t.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }
    static func validPhone(_ s: String) -> Bool {
        let digits = s.filter(\.isNumber)
        return s.trimmingCharacters(in: .whitespaces).isEmpty || (9...10).contains(digits.count)
    }
}

extension ProfileSection {
    /// สิ่งที่ยังขาดของส่วนนี้ — ว่าง = ผ่าน · กติกาเดียวกับ `validate()`/`platValid()`/`groupValid()` ของฟอร์มเว็บ
    func issues(_ p: Profile) -> [ProfileIssue] {
        guard let d = p.intake else { return [] }
        var out: [ProfileIssue] = []
        switch self {
        case .channels:
            if d.kind == nil { out.append(.init(field: PField.kind, message: "เลือกว่าคุณเป็น Creator หรือ Page")) }
            let on = d.enabledSocials
            if on.isEmpty {
                out.append(.init(field: PField.channelsAny, message: "เลือกอย่างน้อย 1 ช่องทางเพื่อไปต่อ"))
            }
            for e in on {
                if e.link.trimmingCharacters(in: .whitespaces).isEmpty {
                    out.append(.init(field: PField.link(e.type), message: "ใส่ลิงก์โปรไฟล์ \(e.type.name)"))
                } else if let err = e.linkError {
                    out.append(.init(field: PField.link(e.type), message: "\(e.type.name): \(err)"))
                }
                if e.followers <= 0 {
                    out.append(.init(field: PField.followers(e.type), message: "ใส่ยอดผู้ติดตาม \(e.type.name)"))
                }
                if !d.rates.contains(where: { $0.platform == e.type && $0.price > 0 }) {
                    out.append(.init(field: PField.rates(e.type), message: "ตั้งเรทอย่างน้อย 1 รูปแบบของ \(e.type.name)"))
                }
            }
        case .interests:
            if d.interests.isEmpty { out.append(.init(field: PField.interests, message: "เลือกสายงานอย่างน้อย 1 หมวด")) }
            if d.interests.contains(IntakeCatalog.fashion) {
                for f in IntakeCatalog.fashionFields where p.isPlaceholder(f.field) {
                    out.append(.init(field: PField.size(f.field), message: "ใส่\(f.label)"))
                }
            }
        case .payment:
            let y = d.payment ?? PaymentInfo()
            guard let kind = y.kind else {
                out.append(.init(field: PField.payKind, message: "เลือกว่ารับเงินในนามบุคคลหรือบริษัท"))
                break
            }
            if kind == .company {
                if y.companyName.trimmingCharacters(in: .whitespaces).isEmpty { out.append(.init(field: PField.companyName, message: "ใส่ชื่อนิติบุคคล")) }
                if y.taxId.count != 13 { out.append(.init(field: PField.taxId, message: "เลขประจำตัวผู้เสียภาษีต้องมี 13 หลัก")) }
                if y.branch.isEmpty { out.append(.init(field: PField.branch, message: "เลือกสำนักงานใหญ่หรือสาขา")) }
                if y.address.trimmingCharacters(in: .whitespaces).isEmpty { out.append(.init(field: PField.address, message: "ใส่ที่อยู่ตามหนังสือรับรอง")) }
                if y.signer.trimmingCharacters(in: .whitespaces).isEmpty { out.append(.init(field: PField.signer, message: "ใส่ชื่อกรรมการผู้มีอำนาจลงนาม")) }
                if y.vat.isEmpty { out.append(.init(field: PField.vat, message: "เลือกว่าจดทะเบียน VAT หรือไม่")) }
            }
            if y.bank.isEmpty { out.append(.init(field: PField.bank, message: "เลือกธนาคาร")) }
            if y.accountNo.count != 10 { out.append(.init(field: PField.accountNo, message: "เลขที่บัญชีต้องมี 10 หลัก")) }
            if y.accountName.trimmingCharacters(in: .whitespaces).isEmpty { out.append(.init(field: PField.accountName, message: "ใส่ชื่อบัญชี")) }
            if !y.bookPhoto { out.append(.init(field: PField.bookPhoto, message: "ถ่ายหน้าสมุดบัญชี")) }
        case .terms:
            let a = d.availability
            if a.days.isEmpty { out.append(.init(field: PField.days, message: "เลือกวันที่ว่างรับงาน")) }
            else if a.slots.isEmpty { out.append(.init(field: PField.time, message: "เลือกช่วงเวลาของวัน")) }
            if a.draftRounds == nil { out.append(.init(field: PField.draft, message: "เลือกจำนวนรอบที่แก้งานให้ได้")) }
        case .person:
            if p.isPlaceholder(.name) { out.append(.init(field: PField.name, message: "ใส่ชื่อ–นามสกุลจริง")) }
            let phone = p.isPlaceholder(.phone) ? "" : p.phone
            let email = p.isPlaceholder(.email) ? "" : p.email
            let line = p.isPlaceholder(.lineId) ? "" : p.lineId
            if phone.isEmpty { out.append(.init(field: PField.phone, message: "ใส่เบอร์โทรศัพท์")) }
            else if !ProfileRules.validPhone(phone) { out.append(.init(field: PField.phone, message: "เบอร์โทรต้องมี 9–10 หลัก")) }
            if email.isEmpty { out.append(.init(field: PField.email, message: "ใส่อีเมล")) }
            else if !ProfileRules.validEmail(email) { out.append(.init(field: PField.email, message: "รูปแบบอีเมลไม่ถูกต้อง")) }
            if line.isEmpty { out.append(.init(field: PField.line, message: "ใส่ Line ID")) }
            let b = d.personal
            if b.dob == nil { out.append(.init(field: PField.dob, message: "เลือกวันเกิด")) }
            if b.nationality.trimmingCharacters(in: .whitespaces).isEmpty { out.append(.init(field: PField.nation, message: "ใส่สัญชาติ")) }
            if b.gender.isEmpty { out.append(.init(field: PField.gender, message: "เลือกเพศ")) }
            if b.religion.isEmpty { out.append(.init(field: PField.religion, message: "เลือกศาสนา")) }
            if b.job.isEmpty { out.append(.init(field: PField.job, message: "เลือกว่าตอนนี้ทำอะไรอยู่")) }
            else if b.job == "student", b.faculty.isEmpty { out.append(.init(field: PField.faculty, message: "เลือกคณะที่เรียน")) }
            else if b.job == "work", b.field.isEmpty { out.append(.init(field: PField.field, message: "เลือกสายงานที่ทำ")) }
        case .consent:
            if d.consentAt == nil { out.append(.init(field: PField.consent, message: "กดยินยอมก่อนนะ แล้วไปต่อได้เลย")) }
        }
        return out
    }

    /// มีอะไรกรอกไว้บ้างแล้วไหม — แยก "ยังไม่แตะ" ออกจาก "แตะแล้วแต่ไม่ครบ"
    private func touched(_ p: Profile) -> Bool {
        guard let d = p.intake else { return false }
        switch self {
        case .channels:  return !d.socials.isEmpty || d.kind != nil
        case .interests: return !d.interests.isEmpty
        case .payment:   return d.payment.map { $0.kind != nil || !$0.bank.isEmpty || !$0.accountNo.isEmpty } ?? false
        case .terms:
            let a = d.availability
            return !a.days.isEmpty || !a.slots.isEmpty || a.draftRounds != nil || !a.limits.isEmpty || !a.provinces.isEmpty
        case .person:
            let b = d.personal
            return !p.isPlaceholder(.name) || !p.isPlaceholder(.phone) || !p.isPlaceholder(.email) || !p.isPlaceholder(.lineId)
                || b.dob != nil || !b.gender.isEmpty || !b.religion.isEmpty || !b.job.isEmpty
        case .consent:   return d.consentAt != nil
        }
    }

    func status(_ p: Profile) -> SectionStatus {
        guard p.intake != nil else { return .empty }
        if issues(p).isEmpty { return .complete }
        return touched(p) ? .partial : .empty
    }

    /// ค่าที่กรอกไว้จริงของส่วนนี้ — แถวใน hub เอาไปทำป้ายชิ้นละค่า ไม่ใช่ประโยคยาวบรรทัดเดียว
    /// (ข้อความรวดเดียวสแกนยาก ตาต้องไล่อ่านทีละคำกว่าจะรู้ว่ากรอกอะไรไว้)
    func facts(_ p: Profile) -> [String] {
        guard let d = p.intake else { return [] }
        switch self {
        case .channels:
            let on = d.enabledSocials.filter { $0.followers > 0 }
            guard !on.isEmpty else { return [d.kind?.title].compactMap { $0 } }
            return on.map { "\($0.type.shortName) \(Fmt.compact($0.followers))" }
        case .interests:
            guard !d.interests.isEmpty else { return [] }
            var parts = d.interests
            if d.interests.contains(IntakeCatalog.fashion), !p.isPlaceholder(.height) { parts.append(p.text(.height)) }
            return parts
        case .payment:
            guard let y = d.payment, let kind = y.kind else { return [] }
            var parts = [kind.title]
            if !y.bank.isEmpty { parts.append(y.bank) }
            if y.accountNo.count >= 4 { parts.append("···\(y.accountNo.suffix(4))") }
            return parts
        case .terms:
            let a = d.availability
            var parts: [String] = []
            if let day = IntakeCatalog.dayOptions.first(where: { $0.days == a.days }) { parts.append(day.value) }
            if let t = IntakeCatalog.timeOptions.first(where: { $0.slots == a.slots }) { parts.append(t.value) }
            if let n = a.draftRounds { parts.append("แก้ \(n) รอบ") }
            // ชื่อจังหวัดยาวกินที่ป้ายอื่นหมด — เกินหนึ่งจังหวัดบอกเป็นจำนวนพอ
            if a.provinces.count == 1 { parts.append(a.provinces[0]) }
            else if a.provinces.count > 1 { parts.append("\(a.provinces.count) จังหวัด") }
            return parts
        case .person:
            var parts: [String] = []
            if !p.isPlaceholder(.name) { parts.append(p.name) }
            if let a = d.personal.age { parts.append("\(a) ปี") }
            if !d.personal.gender.isEmpty { parts.append(d.personal.gender) }
            return parts
        case .consent:
            return d.consentAt == nil ? [] : ["ยินยอมแล้ว"]
        }
    }
}

extension Profile {
    /// ส่วนจำเป็นครบทุกส่วน — พร้อมสร้างการ์ด/ส่งตรวจ
    var requiredComplete: Bool {
        intake != nil && ProfileSection.required.allSatisfy { $0.issues(self).isEmpty }
    }
    var requiredDoneCount: Int {
        ProfileSection.required.filter { $0.status(self) == .complete }.count
    }
}
