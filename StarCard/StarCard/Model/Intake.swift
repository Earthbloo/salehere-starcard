import SwiftUI
import PhosphorSwift

// MARK: - ข้อมูลจากฟอร์มสมัคร/แก้ไขโปรไฟล์
//
// # ทำไมมีไฟล์นี้ ทั้งที่ `Profile` มีอยู่แล้ว
//
// `Profile` เก็บ **ข้อความ** ที่แก้ได้บนตัวการ์ด (ชื่อ · สายงาน · เบอร์ · ราคา) ซึ่งพอสำหรับการ์ด
// แต่ฟอร์มสมัครมีของที่ไม่ใช่ข้อความ: ช่องทางพร้อมยอดผู้ติดตามและ *ที่มาของยอด* · ตารางเรท
// แพลตฟอร์ม×รูปแบบ · หมวดทางการ · วัน/เวลาที่รับงาน · ข้อมูลส่วนตัวที่ไม่ขึ้นการ์ด
//
// ไฟล์นี้คือรูปร่างของของพวกนั้น — เก็บใน `Profile.intake` ก้อนเดียว ทั้งฟอร์มและการ์ดอ่านที่เดียวกัน
// แก้บนการ์ดเห็นในฟอร์ม แก้ในฟอร์มเห็นบนการ์ด โดยไม่มีตัว "sync" แยกต่างหาก
//
// # สามสถานะของผู้ใช้ที่ต้องรองรับ
//
// * ยังไม่เคยกรอก — `Profile.intake == nil` การ์ดใช้ข้อมูลตัวอย่างไปก่อน
// * เคยกรอกแล้วในระบบเดิม — `importFromSystemProfile()` ยกของเดิมเข้ามา (ตอนนี้ mock แทน API)
// * ต้องอัปเดต — เปิดหน้า "ข้อมูลของฉัน" แก้ทีละส่วน บันทึกเองทุกจังหวะ

/// ยอดผู้ติดตามมาจากไหน — ตัวตัดสินว่าตัวเลขนี้ "ยืนยันแล้ว" หรือ "รอตรวจ"
///
/// ชั้นเดียวกับ `WidgetTier`: `connected`/`api` = ระบบดึงเอง แก้ไม่ได้ · `manual` = ผู้สมัครพิมพ์เอง
enum FollowerSource: String, Codable {
    case manual, connected, api

    var isVerified: Bool { self != .manual }

    var label: String {
        switch self {
        case .manual:    return "กรอกเอง · รอทีมงานตรวจสอบ"
        case .connected: return "ยืนยันแล้วผ่านการเชื่อมบัญชี"
        case .api:       return "ยืนยันอัตโนมัติจาก API"
        }
    }
}

/// สมัครในนามใคร — ตัวตั้งต้นของรูปแบบเรทและวิธีเรียกผู้รับงาน
enum CreatorKind: String, Codable, CaseIterable, Identifiable {
    case creator, page
    var id: String { rawValue }

    var title: String { self == .creator ? "Creator (บุคคล)" : "Page (เพจ)" }
    var detail: String {
        self == .creator ? "ตัวคุณเองเป็นคนสร้างคอนเทนต์" : "บริหารเพจ/สื่อในนามทีมหรือแบรนด์"
    }
    var icon: Ph { self == .creator ? .user : .browsers }
}

/// สถานะการตรวจของทีมงาน — ตราดาวบนการ์ดขึ้นเมื่อ `approved` เท่านั้น
enum ReviewStatus: String, Codable {
    case draft, pending, approved

    var label: String {
        switch self {
        case .draft:    return "ยังไม่ได้ส่งตรวจ"
        case .pending:  return "รอทีมงานตรวจสอบ"
        case .approved: return "เป็น STAR แล้ว"
        }
    }
}

/// ช่องทางหนึ่งช่อง — ลิงก์ · ยอด · ที่มาของยอด
struct SocialEntry: Codable, Identifiable, Equatable {
    var type: SocialType
    var link: String = ""
    var followers: Int = 0
    var source: FollowerSource = .manual
    /// ปิดไว้ = ไม่โชว์บนการ์ด แต่ **ข้อมูลยังอยู่** — ปิดแล้วเปิดใหม่ไม่ต้องกรอกซ้ำ
    var enabled: Bool = true

    var id: String { type.rawValue }
    var handle: String { type.handle(from: link) }
    var linkError: String? { type.linkError(link) }
    var isComplete: Bool { !link.isEmpty && linkError == nil && followers > 0 }
}

/// รูปแบบงานของแพลตฟอร์ม — `PLAT[].fmts` ของฟอร์มเว็บ: คีย์ · ชื่อ · ตัวคูณจากเรทฐาน · รูปแบบหลัก
struct PlatFormat: Identifiable, Equatable {
    let key: String
    let label: String
    /// ตัวคูณจากเรทฐานของแพลตฟอร์ม (`m`)
    let m: Double
    /// รูปแบบหลักที่ติ๊กให้ก่อนตอนรู้ยอดผู้ติดตาม (`def`)
    var isDefault = false
    /// รูปแบบกลางที่การ์ดและสูตรราคาตลาดใช้จัดกลุ่ม
    let generic: ContentFormat
    var id: String { key }
}

/// หนึ่งช่องในตารางเรท แพลตฟอร์ม × รูปแบบของแพลตฟอร์มนั้น — มีอยู่ = รับงานแบบนั้น
struct RateCell: Identifiable, Equatable {
    var platform: SocialType
    /// คีย์รูปแบบตามแพลตฟอร์ม (`post`, `reels`, `short`, `dedicated` …) — ดู `SocialType.formats`
    var formatKey: String
    var price: Int = 0
    /// ชื่อรายการที่ผู้ใช้ตั้งเองบนการ์ด — nil = ใช้ชื่อมาตรฐาน "IG Reels"
    var label: String? = nil
    /// ผู้ใช้แก้ราคาเองแล้ว — ปุ่ม "ใช้เรทแนะนำ" ห้ามทับ
    var touched: Bool = false

    init(platform: SocialType, formatKey: String, price: Int = 0, label: String? = nil, touched: Bool = false) {
        self.platform = platform
        self.formatKey = formatKey
        self.price = price
        self.label = label
        self.touched = touched
    }

    var id: String { platform.rawValue + "." + formatKey }
    var spec: PlatFormat? { platform.formats.first { $0.key == formatKey } }
    /// รูปแบบกลาง — การ์ดกับ `Pricing` ยังจัดกลุ่มแบบนี้
    var format: ContentFormat { spec?.generic ?? .photo }
    var defaultLabel: String { "\(platform.shortName) \(spec?.label ?? formatKey)" }
    var displayLabel: String { (label?.isEmpty == false ? label : nil) ?? defaultLabel }
}

extension RateCell: Codable {
    private enum CodingKeys: String, CodingKey { case platform, formatKey, price, label, touched, legacyFormat = "format" }

    /// ข้อมูลเก่าเก็บ `format` (รูปแบบกลาง) — แปลงเป็นรูปแบบแรกของแพลตฟอร์มที่อยู่กลุ่มเดียวกัน
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let p = try c.decode(SocialType.self, forKey: .platform)
        let key: String
        if let k = try c.decodeIfPresent(String.self, forKey: .formatKey) {
            key = k
        } else if let g = try c.decodeIfPresent(ContentFormat.self, forKey: .legacyFormat) {
            key = (p.formats.first { $0.generic == g } ?? p.defaultFormat).key
        } else {
            key = p.defaultFormat.key
        }
        self.init(platform: p, formatKey: key,
                  price: try c.decodeIfPresent(Int.self, forKey: .price) ?? 0,
                  label: try c.decodeIfPresent(String.self, forKey: .label),
                  touched: try c.decodeIfPresent(Bool.self, forKey: .touched) ?? false)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(platform, forKey: .platform)
        try c.encode(formatKey, forKey: .formatKey)
        try c.encode(price, forKey: .price)
        try c.encodeIfPresent(label, forKey: .label)
        try c.encode(touched, forKey: .touched)
    }
}

/// วัน · เวลา · เงื่อนไขที่รับงาน
struct Availability: Codable, Equatable {
    /// 0 = อาทิตย์ … 6 = เสาร์ (ดัชนีเดียวกับ `WorkTime`)
    var days: Set<Int> = []
    var slots: Set<Int> = []
    var draftRounds: Int? = nil
    var limits: [String] = []
    var otherLimit: String = ""
    var provinces: [String] = []
    /// `BookingState.rawValue`
    var booking: String = BookingState.available.rawValue
}

/// ข้อมูลส่วนตัวที่ใช้จับคู่งาน — **ไม่ขึ้นบนการ์ด**
struct PersonalInfo: Codable, Equatable {
    var dob: Date? = nil
    var nationality: String = "ไทย"
    var gender: String = ""
    var religion: String = ""
    var job: String = ""
    var faculty: String = ""
    var field: String = ""

    var age: Int? {
        guard let dob else { return nil }
        let a = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? -1
        return (0..<120).contains(a) ? a : nil
    }
}

/// รับเงินในนามใคร — ข้อ `pay` ของฟอร์มเว็บ · ตัวกำหนดชุดช่องและอัตราหัก ณ ที่จ่าย (`PAY[...].wht`)
enum PayKind: String, Codable, CaseIterable, Identifiable {
    case person, company
    var id: String { rawValue }

    var title: String { self == .person ? "นามบุคคล" : "นามบริษัท" }
    var detail: String { self == .person ? "รับเงินเข้าบัญชีชื่อคุณเอง" : "ออกในนามนิติบุคคล" }
    var icon: Ph { self == .person ? .user : .buildings }
    /// หัก ณ ที่จ่าย % — ค่าเดียวกับฟอร์มเว็บ (บุคคล 3 · นิติบุคคล 7)
    var withholding: Int { self == .person ? 3 : 7 }
    /// เอกสารที่ **ยังไม่ต้องส่ง** — ขอตอนได้งานแรก
    var later: [String] {
        self == .person
            ? ["สำเนาบัตรประชาชน เซ็นรับรองสำเนาถูกต้อง"]
            : ["หนังสือรับรองบริษัท อายุไม่เกิน 6 เดือน", "ภ.พ.20 (เฉพาะกรณีจด VAT)", "สำเนาบัตรประชาชนกรรมการผู้มีอำนาจ"]
    }
}

/// บัญชีที่จะให้เงินเข้า — เก็บเลขบัญชี/เลขผู้เสียภาษีเป็นตัวเลขล้วน จัดรูปแบบตอนแสดง
/// ตัวรูปหน้าสมุดบัญชีอยู่ใน `PhotoStore.bookBank` — ที่นี่เก็บแค่ว่าแนบแล้ว
struct PaymentInfo: Codable, Equatable {
    var kind: PayKind? = nil
    var bank: String = ""
    var accountNo: String = ""
    var accountName: String = ""
    var bookPhoto: Bool = false
    // เฉพาะนิติบุคคล
    var companyName: String = ""
    var taxId: String = ""
    var branch: String = ""
    var address: String = ""
    var signer: String = ""
    var vat: String = ""

    /// xxx-x-xxxxx-x
    static func formatAccount(_ digits: String) -> String {
        var out = ""
        for (i, ch) in digits.filter(\.isNumber).prefix(10).enumerated() {
            if i == 3 || i == 4 || i == 9 { out.append("-") }
            out.append(ch)
        }
        return out
    }
}

struct IntakeData: Codable, Equatable {
    var kind: CreatorKind? = nil
    var socials: [SocialEntry] = []
    /// หมวดทางการที่เลือก (สูงสุด `IntakeCatalog.maxInterests`) — ใช้จับคู่งาน จึงเลือกจากรายการเท่านั้น
    var interests: [String] = []
    var rates: [RateCell] = []
    var availability = Availability()
    var personal = PersonalInfo()
    /// optional เพราะเพิ่มทีหลัง — ข้อมูลที่เซฟไว้ก่อนหน้าไม่มีคีย์นี้ ต้องถอดรหัสผ่าน
    var payment: PaymentInfo? = nil
    var consentAt: Date? = nil
    var status: ReviewStatus = .draft
    var importedAt: Date? = nil
    /// ผ่านหน้ากรอกครั้งแรกครบ 4 ขั้นแล้ว — หลังจากนี้เข้าหน้า "ข้อมูลของฉัน" ได้ตรง ๆ
    var firstRunDone: Bool = false

    var enabledSocials: [SocialEntry] { socials.filter(\.enabled) }

    func social(_ t: SocialType) -> SocialEntry? { socials.first { $0.type == t } }
    func rate(_ p: SocialType, _ f: ContentFormat) -> RateCell? {
        rates.first { $0.platform == p && $0.format == f }
    }
}

// MARK: - รายการตัวเลือกของฟอร์ม

enum IntakeCatalog {
    static let maxInterests = 5
    static let maxProvinces = 3

    /// หมวดทางการ — ชุดเดียวกับฟอร์มสมัครฝั่งเว็บ
    static let interests: [(icon: String, name: String)] = [
        ("💄", "บิวตี้"), ("👗", "แฟชั่น"), ("🍜", "อาหาร & เครื่องดื่ม"), ("☕️", "คาเฟ่"),
        ("✨", "ไลฟ์สไตล์"), ("✈️", "ท่องเที่ยว"), ("💪", "สุขภาพ & ออกกำลังกาย"), ("👶", "แม่และเด็ก"),
        ("🐶", "สัตว์เลี้ยง"), ("📱", "เทคโนโลยี & แกดเจ็ต"), ("🎮", "เกม"), ("🪴", "บ้าน & สวน"),
        ("🚗", "รถยนต์ & ยานยนต์"), ("💰", "การเงิน & การลงทุน"), ("📚", "การศึกษา"), ("⚽️", "กีฬา"),
        ("🎬", "บันเทิง & ดารา"), ("🎪", "อีเวนต์ & กิจกรรม"),
    ]
    static func icon(for interest: String) -> String {
        interests.first { $0.name == interest }?.icon ?? "✨"
    }
    /// ชื่อสั้นสำหรับชิปบนการ์ด — "อาหาร & เครื่องดื่ม" → "อาหาร"
    static func short(_ interest: String) -> String {
        interest.components(separatedBy: " & ").first ?? interest
    }
    /// จับคู่ชิปของ wizard ("👗 แฟชั่น" · "เทค") กับหมวดทางการ — ตัดอีโมจิ แล้วหาชื่อที่ซ้อนกัน
    static func official(_ chip: String) -> String? {
        let word = chip.split(separator: " ").filter { $0.unicodeScalars.contains { $0.properties.isAlphabetic } }
            .joined(separator: " ")
        guard !word.isEmpty else { return nil }
        return interests.first { $0.name == word }?.name
            ?? interests.first { $0.name.hasPrefix(word) || word.hasPrefix(short($0.name)) }?.name
            ?? interests.first { $0.name.contains(word) || word.contains($0.name) }?.name
    }
    /// ชื่อย่อ 7 วันของ wizard เรียง จ.→อา. (index 0 = จันทร์)
    static let weekShort = ["จ", "อ", "พ", "พฤ", "ศ", "ส", "อา"]
    /// ชุดวันจากป้ายที่ wizard ใช้ ("จ อ ส อา" · ค่าเก่า "ทุกวัน" · "ส.–อา." · "จ.–ศ.") หรือค่าเต็มของฟอร์มเว็บ
    static func days(_ label: String) -> Set<Int> {
        // แบบใหม่: "จ อ ส อา" — แปลงเป็นชุดวัน 0 = อาทิตย์
        let parts = label.split(separator: " ").map(String.init)
        if !parts.isEmpty, parts.allSatisfy(weekShort.contains) {
            return Set(parts.compactMap { weekShort.firstIndex(of: $0).map { ($0 + 1) % 7 } })
        }
        if let o = dayOptions.first(where: { $0.value == label }) { return o.days }
        if label.hasPrefix("ส") { return [0, 6] }
        if label.hasPrefix("จ") { return Set(1...5) }
        return Set(0..<7)
    }
    /// หมวดที่ทำให้ส่วน "สัดส่วน" เด่นขึ้นมา — แบรนด์แฟชั่นต้องรู้ไซซ์ก่อนส่งของ
    static let fashion = "แฟชั่น"

    // MARK: Vibe การทำงาน — ข้อ `days` `time` `draft` `limit` ของฟอร์มเว็บ

    /// วันที่ว่างรับงาน — ข้อ `days` (ค่า · ชื่อ · คำอธิบาย · ไอคอน · ชุดวัน 0 = อาทิตย์)
    struct DayOption: Identifiable {
        let value: String, label: String, detail: String, icon: Ph, days: Set<Int>
        var id: String { value }
    }
    static let dayOptions: [DayOption] = [
        DayOption(value: "ทุกวัน", label: "สะดวกทุกวัน", detail: "จันทร์ – อาทิตย์", icon: .calendarDots, days: Set(0..<7)),
        DayOption(value: "เสาร์–อาทิตย์", label: "เฉพาะเสาร์–อาทิตย์", detail: "วันหยุดสุดสัปดาห์", icon: .sunHorizon, days: [0, 6]),
        DayOption(value: "จันทร์–ศุกร์", label: "เฉพาะวันธรรมดา", detail: "จันทร์ – ศุกร์", icon: .briefcase, days: Set(1...5)),
    ]
    /// ช่วงเวลา (ค่า · ชื่อ · ช่องของ `WorkTime.slotNames` ที่หมายถึง)
    static let timeOptions: [(value: String, label: String, slots: Set<Int>)] = [
        ("เช้า", "เช้า (9.00–12.00)", [0]),
        ("บ่าย", "บ่าย (12.00–17.00)", [1, 2]),
        ("เย็น", "เย็น (17.00 เป็นต้นไป)", [3]),
        ("ตลอดวัน", "ตลอดวัน", [0, 1, 2, 3]),
    ]
    static let draftNote = "ถ้าแก้ครบรอบแล้วงานยังไม่ตรงบรีฟ?\n· งานที่ไม่ตรงบรีฟเดิม — ยังไม่นับเป็นรอบแก้ ครีเอเตอร์ปรับให้ตรงก่อน ไม่คิดเงินเพิ่ม\n· แบรนด์เพิ่มโจทย์ใหม่นอกบรีฟ — นับเป็นงานเพิ่ม คุยเรทกันใหม่ได้\n· ตกลงกันไม่ได้ — แจ้งทีม Sale Here เข้าไปช่วยดูให้ทั้งสองฝั่ง"

    static let noLimit = "ไม่มีข้อจำกัด"
    /// งานที่ขอผ่าน (ชื่อบนชิป · ค่าที่เก็บ = ข้อความเต็มของฟอร์มเว็บ) — ข้อแรกตัดข้ออื่นทั้งหมด
    static let limits: [(label: String, value: String)] = [
        ("😄 รับได้หมดเลย", "ไม่มีข้อจำกัด"),
        ("💳 สินเชื่อ / คริปโต", "ไม่รับงานสินเชื่อ / คริปโต"),
        ("🍺 แอลกอฮอล์ / บุหรี่", "ไม่รับงานแอลกอฮอล์ / บุหรี่ / บุหรี่ไฟฟ้า"),
        ("💊 อาหารเสริม / ลดน้ำหนัก", "ไม่รับงานอาหารเสริม / ลดน้ำหนัก"),
        ("💉 ความงามเชิงการแพทย์", "ไม่รับงานความงามเชิงการแพทย์ (ศัลยกรรม / ฉีด)"),
    ]
    static let otherLimitPlaceholder = "เช่น ไม่รับงานที่ต้องค้างคืนต่างจังหวัด"

    /// ไซซ์สำหรับสายแฟชั่น — ข้อ `fashion` (ช่อง · ชื่อ · ตัวอย่าง · หน่วยที่ต่อท้ายให้การ์ด)
    static let fashionFields: [(field: ProfileField, label: String, placeholder: String, unit: String)] = [
        (.height, "ส่วนสูง (ซม.)", "165", "ซม."), (.weight, "น้ำหนัก (กก.)", "50", "กก."),
        (.bust, "รอบอก (นิ้ว)", "32", "นิ้ว"), (.waist, "รอบเอว (นิ้ว)", "25", "นิ้ว"),
        (.hips, "สะโพก (นิ้ว)", "35", "นิ้ว"), (.shoe, "ไซซ์รองเท้า (ซม.)", "23", "ซม."),
    ]

    static let draftRounds = [1, 2, 3]

    /// ธนาคาร — รายการเดียวกับ `BANKS` ของฟอร์มเว็บ
    static let banks = ["กสิกรไทย", "ไทยพาณิชย์", "กรุงเทพ", "กรุงไทย", "กรุงศรีอยุธยา", "ทหารไทยธนชาต (ttb)",
                        "ออมสิน", "ธ.ก.ส.", "เกียรตินาคินภัทร", "ซีไอเอ็มบี ไทย", "ยูโอบี", "แลนด์ แอนด์ เฮ้าส์", "อื่น ๆ"]
    static let branches = ["สำนักงานใหญ่", "สาขาที่ 00001", "สาขาที่ 00002", "สาขาอื่น ๆ"]
    static let vatOptions = ["จดทะเบียน VAT (มี ภ.พ.20)", "ไม่ได้จดทะเบียน VAT"]

    static let genders = ["หญิง", "ชาย", "LGBTQ+", "ไม่ขอระบุ"]
    static let religions = ["พุทธ", "อิสลาม", "คริสต์", "ฮินดู", "อื่น ๆ / ไม่ระบุ"]
    /// ข้อ `job` — ค่า `v` · ชื่อ · คำอธิบาย · ไอคอน
    struct JobOption: Identifiable {
        let key: String, title: String, detail: String, icon: Ph
        var id: String { key }
    }
    static let jobs: [JobOption] = [
        JobOption(key: "student", title: "นักเรียน / นักศึกษา", detail: "กำลังศึกษาอยู่", icon: .student),
        JobOption(key: "work", title: "วัยทำงาน", detail: "พนักงาน/ฟรีแลนซ์/ธุรกิจ/ราชการ", icon: .briefcase),
        JobOption(key: "other", title: "อื่น ๆ", detail: "แม่บ้าน / อินฟลูเอนเซอร์เต็มเวลา ฯลฯ", icon: .sparkle),
    ]
    static let faculties = ["บริหารธุรกิจ / การจัดการ", "นิเทศ / สื่อสารมวลชน", "วิศวกรรมศาสตร์",
                            "ไอที / วิทยาการคอมพิวเตอร์", "ครุศาสตร์ / ศึกษาศาสตร์", "อักษรศาสตร์ / มนุษยศาสตร์",
                            "แพทย์ / พยาบาล / สาธารณสุข", "อื่น ๆ"]
    static let fields = ["การตลาด / โฆษณา", "ขาย / บริการลูกค้า", "ไอที / พัฒนาซอฟต์แวร์", "การเงิน / บัญชี",
                         "ออกแบบ / ครีเอทีฟ", "การแพทย์ / สุขภาพ", "การศึกษา / ฝึกอบรม", "อื่น ๆ"]

    /// NOTE port: = `preferredProvinces: [String!]` ของ `createOrUpdateCreatorProfile` (API เดิม) · ลิสต์ตัวจริงดึงจาก `getProvinces`
    /// = `getProvinces` ของ salehere-ios — ไม่มี "ทุกจังหวัด (งานออนไลน์)" (เอาออก 7 ต.ค. 2569 ให้ตรงแอปหลัก)
    /// (ทางเลี่ยง: เก็บเป็น `preferredProvinces = []` แปลว่าออนไลน์ แต่จะแยกกับ "ยังไม่กรอก" ไม่ออก) · เพดาน 3 จังหวัดเป็นกติกาฝั่งเรา
    static let provinces = ["กรุงเทพมหานคร", "กระบี่", "กาญจนบุรี", "กาฬสินธุ์", "กำแพงเพชร",
        "ขอนแก่น", "จันทบุรี", "ฉะเชิงเทรา", "ชลบุรี", "ชัยนาท", "ชัยภูมิ", "ชุมพร", "เชียงราย", "เชียงใหม่", "ตรัง", "ตราด",
        "ตาก", "นครนายก", "นครปฐม", "นครพนม", "นครราชสีมา", "นครศรีธรรมราช", "นครสวรรค์", "นนทบุรี", "นราธิวาส", "น่าน",
        "บึงกาฬ", "บุรีรัมย์", "ปทุมธานี", "ประจวบคีรีขันธ์", "ปราจีนบุรี", "ปัตตานี", "พระนครศรีอยุธยา", "พะเยา", "พังงา",
        "พัทลุง", "พิจิตร", "พิษณุโลก", "เพชรบุรี", "เพชรบูรณ์", "แพร่", "ภูเก็ต", "มหาสารคาม", "มุกดาหาร", "แม่ฮ่องสอน",
        "ยโสธร", "ยะลา", "ร้อยเอ็ด", "ระนอง", "ระยอง", "ราชบุรี", "ลพบุรี", "ลำปาง", "ลำพูน", "เลย", "ศรีสะเกษ", "สกลนคร",
        "สงขลา", "สตูล", "สมุทรปราการ", "สมุทรสงคราม", "สมุทรสาคร", "สระแก้ว", "สระบุรี", "สิงห์บุรี", "สุโขทัย", "สุพรรณบุรี",
        "สุราษฎร์ธานี", "สุรินทร์", "หนองคาย", "หนองบัวลำภู", "อ่างทอง", "อำนาจเจริญ", "อุดรธานี", "อุตรดิตถ์", "อุทัยธานี",
        "อุบลราชธานี"]

    /// ระดับตามยอดผู้ติดตามของ **ช่องเดียว** — วงการแบ่งกันต่อแพลตฟอร์ม ไม่ใช่ยอดรวมทุกช่อง
    static func tier(_ n: Int) -> String {
        switch n {
        case ..<10_000:   return "Nano"
        case ..<50_000:   return "Micro"
        case ..<500_000:  return "Mid-tier"
        default:          return "Macro"
        }
    }

    // MARK: เรทแนะนำ — สูตร `recoRate` ของฟอร์มเว็บ
    // CPM ต่อพันผู้ติดตาม ลดหลั่นตามช่วง (ถึง 1 หมื่น · 5 หมื่น · 5 แสน · เกินนั้น) · ขั้นต่ำต่อแพลตฟอร์ม · ปัดเป็นร้อย

    static let followerBreaks = [10_000, 50_000, 500_000]

    static func cpm(_ p: SocialType) -> (cpm: [Double], min: Int) {
        switch p {
        case .instagram: return ([90, 60, 40, 25], 500)
        case .tiktok:    return ([100, 70, 45, 28], 600)
        case .facebook:  return ([80, 55, 35, 20], 500)
        case .youtube:   return ([250, 180, 120, 70], 2_000)
        case .lemon8:    return ([70, 45, 30, 18], 400)
        case .x:         return ([60, 40, 25, 15], 400)
        }
    }

    /// เรทฐานของแพลตฟอร์ม (รูปแบบหลัก m = 1) · 0 = ยังไม่รู้ยอดผู้ติดตาม
    static func recoRate(_ p: SocialType, followers: Int) -> Int {
        guard followers > 0 else { return 0 }
        let r = cpm(p)
        var sum = 0.0
        var prev = 0
        for (i, b) in followerBreaks.enumerated() {
            let part = max(0, min(followers, b) - prev)
            sum += Double(part) / 1_000 * r.cpm[i]
            prev = b
        }
        if followers > prev { sum += Double(followers - prev) / 1_000 * r.cpm[3] }
        sum = max(sum, Double(r.min))
        return Int((sum / 100).rounded()) * 100
    }

    /// เรทแนะนำของรูปแบบหนึ่ง = เรทฐาน × ตัวคูณ ปัดเป็นร้อย
    static func reco(_ p: SocialType, followers: Int, format f: PlatFormat) -> Int {
        let base = recoRate(p, followers: followers)
        return base > 0 ? Int((Double(base) * f.m / 100).rounded()) * 100 : 0
    }
    /// ต่ำกว่านี้ = "ต่ำกว่าที่คนอื่นรับ" · สูงกว่า `recoHigh` = "แบรนด์อาจต่อรอง"
    static func recoLow(_ v: Int) -> Int { Int((Double(v) * 0.7 / 100).rounded()) * 100 }
    static func recoHigh(_ v: Int) -> Int { Int((Double(v) * 1.4 / 100).rounded()) * 100 }

    /// จำลองยอดที่ API/OAuth จะส่งกลับมา — **ใช้เฉพาะโปรโตไทป์** ยังไม่ได้ต่อของจริง
    static func simulatedFollowers(seed: String) -> Int {
        var h: UInt32 = 2_166_136_261
        for u in seed.utf8 { h ^= UInt32(u); h = h &* 16_777_619 }
        return 2_400 + Int(h % 418_000)
    }
}

// MARK: - ความรู้เรื่องลิงก์ของแต่ละแพลตฟอร์ม

enum FetchMode {
    /// ดึงยอดจากลิงก์ได้เลย (YouTube Data API)
    case api
    /// ต้องให้เจ้าของบัญชีกดอนุญาต (OAuth)
    case connect
    /// ไม่มี API ให้ดึง — กรอกเองแล้วทีมงานตรวจ
    case manual
}

extension SocialType {
    var shortName: String {
        switch self {
        case .instagram: return "IG"
        case .tiktok:    return "TikTok"
        case .youtube:   return "YouTube"
        case .facebook:  return "FB"
        case .lemon8:    return "Lemon8"
        case .x:         return "X"
        }
    }

    var placeholderLink: String {
        switch self {
        case .instagram: return "https://instagram.com/username"
        case .tiktok:    return "https://tiktok.com/@username"
        case .youtube:   return "https://youtube.com/@channelname"
        case .facebook:  return "https://facebook.com/yourpage"
        case .lemon8:    return "https://lemon8-app.com/@username"
        case .x:         return "https://x.com/username"
        }
    }

    var fetch: FetchMode {
        switch self {
        case .youtube:                          return .api
        case .instagram, .tiktok, .facebook:    return .connect
        case .lemon8, .x:                       return .manual
        }
    }

    /// ทำไมช่องนี้ดึงเองได้/ไม่ได้ — โชว์ให้ผู้สมัครเข้าใจ ไม่ใช่ซ่อนไว้ในโค้ด
    var fetchNote: String {
        switch self {
        case .instagram: return "ดึงยอดได้เฉพาะบัญชี Business/Creator ที่กดเชื่อมบัญชีแล้ว"
        case .tiktok:    return "ต้องล็อกอินอนุญาตก่อน ไม่มี API สาธารณะสำหรับลิงก์โปรไฟล์"
        case .facebook:  return "ยอดผู้ติดตามเพจต้องได้สิทธิ์จากแอดมินเพจก่อน"
        case .youtube:   return "ดึงจากลิงก์ช่องได้ทันที (ยอดที่ได้เป็นเลขปัดหลัก)"
        case .lemon8:    return "ยังไม่เปิด API — กรอกเองแล้วทีมงานตรวจจากหน้าโปรไฟล์"
        case .x:         return "API เปิดเฉพาะแพ็กเกจเสียเงิน — กรอกเองไปก่อน"
        }
    }

    /// ลำดับที่โชว์ในฟอร์ม — ช่องที่คนไทยใช้รับงานมากสุดขึ้นก่อน
    /// รูปแบบงานของแพลตฟอร์ม — `PLAT[].fmts` ของฟอร์มเว็บ ครบทุกคีย์ ชื่อ และตัวคูณ
    var formats: [PlatFormat] {
        switch self {
        case .instagram: return [
            PlatFormat(key: "post", label: "ภาพลงฟีด (1–3 ภาพ)", m: 1, isDefault: true, generic: .photo),
            PlatFormat(key: "carousel", label: "อัลบั้มรีวิว (4–10 ภาพ)", m: 1.3, generic: .photo),
            PlatFormat(key: "reels", label: "Reels", m: 1.6, generic: .shortVideo),
            PlatFormat(key: "story", label: "Story (ชุด 3 สไลด์)", m: 0.5, generic: .photo),
            PlatFormat(key: "live", label: "IG Live", m: 2.2, generic: .longVideo)]
        case .tiktok: return [
            PlatFormat(key: "short", label: "คลิปสั้น (ไม่เกิน 60 วิ)", m: 1, isDefault: true, generic: .shortVideo),
            PlatFormat(key: "long", label: "คลิปยาว (1–3 นาที)", m: 1.5, generic: .longVideo),
            PlatFormat(key: "series", label: "ซีรีส์ 3 คลิปต่อเนื่อง", m: 2.4, generic: .longVideo),
            PlatFormat(key: "live", label: "TikTok LIVE (1 ชม.)", m: 2.6, generic: .longVideo)]
        case .facebook: return [
            PlatFormat(key: "post", label: "โพสต์ภาพ + แคปชัน", m: 1, isDefault: true, generic: .photo),
            PlatFormat(key: "album", label: "อัลบั้มรีวิว", m: 1.3, generic: .photo),
            PlatFormat(key: "reels", label: "Facebook Reels", m: 1.4, generic: .shortVideo),
            PlatFormat(key: "video", label: "วิดีโอยาว (3 นาทีขึ้นไป)", m: 1.8, generic: .longVideo),
            PlatFormat(key: "live", label: "Facebook Live", m: 2.2, generic: .longVideo)]
        case .youtube: return [
            PlatFormat(key: "shorts", label: "YouTube Shorts", m: 0.5, generic: .shortVideo),
            PlatFormat(key: "integrated", label: "แทรกในคลิป (60–90 วิ)", m: 1, isDefault: true, generic: .longVideo),
            PlatFormat(key: "dedicated", label: "คลิปรีวิวเต็ม (Dedicated)", m: 1.8, generic: .longVideo)]
        case .lemon8: return [
            PlatFormat(key: "photo", label: "โพสต์ภาพ (Photo Set)", m: 1, isDefault: true, generic: .photo),
            PlatFormat(key: "review", label: "รีวิวยาว + แท็กสินค้า", m: 1.5, generic: .seeding)]
        case .x: return [
            PlatFormat(key: "post", label: "โพสต์ + ภาพ", m: 1, isDefault: true, generic: .photo),
            PlatFormat(key: "thread", label: "เธรดรีวิว (3 โพสต์ขึ้นไป)", m: 1.7, generic: .seeding)]
        }
    }
    var defaultFormat: PlatFormat { formats.first { $0.isDefault } ?? formats[0] }

    /// ดึงยอดได้แค่ไหน — คำสั้นในกล่อง "ช่องทางไหนดึงยอดอัตโนมัติได้จริงบ้าง"
    var fetchLabel: String {
        switch fetch {
        case .api:     return "ดึงจากลิงก์ได้"
        case .connect: return "ต้องเชื่อมบัญชี"
        case .manual:  return "กรอกเองเท่านั้น"
        }
    }
    /// คำอธิบายเชิงเทคนิค — `PLAT[].api` ของฟอร์มเว็บ
    var apiNote: String {
        switch self {
        case .instagram: return "Instagram Graph API — ดึงยอดผู้ติดตามได้เฉพาะบัญชี Business/Creator ที่กด \"เชื่อมบัญชี\" ให้สิทธิ์แล้วเท่านั้น ดึงจากลิงก์เปล่าไม่ได้"
        case .tiktok:    return "TikTok Login Kit / Display API — follower_count ต้องให้ผู้ใช้ล็อกอินอนุญาตก่อน ไม่มี endpoint สาธารณะสำหรับลิงก์โปรไฟล์"
        case .facebook:  return "Facebook Graph API — followers_count ของเพจต้องใช้ Page Access Token ที่แอดมินเพจกดอนุญาต ดึงจากลิงก์เพจเฉย ๆ ไม่ได้"
        case .youtube:   return "YouTube Data API v3 (channels.list · part=statistics) — ดึงจากลิงก์ช่องได้จริงด้วย API key ไม่ต้องให้เจ้าของอนุญาต แต่ subscriberCount ที่ได้เป็นเลขปัดหลัก และเป็น 0 ถ้าช่องซ่อนยอด"
        case .lemon8:    return "ไม่มี Public API — Lemon8 ยังไม่เปิด developer platform ให้ดึงข้อมูลโปรไฟล์ ต้องให้ผู้สมัครกรอกเองและแนบภาพหน้าโปรไฟล์ยืนยัน"
        case .x:         return "X API v2 (users/by/username · public_metrics) — เปิดดูได้เฉพาะแพ็กเกจเสียเงิน (Basic ขึ้นไป) ไม่มีชั้นฟรี จึงใช้วิธีกรอกเองไปก่อน"
        }
    }

    var formOrder: Int {
        switch self {
        case .instagram: return 0
        case .tiktok:    return 1
        case .facebook:  return 2
        case .youtube:   return 3
        case .lemon8:    return 4
        case .x:         return 5
        }
    }

    private var linkPattern: String {
        switch self {
        case .instagram: return #"^https?://(www\.)?instagram\.com/[A-Za-z0-9._]{1,30}/?(\?.*)?$"#
        case .tiktok:    return #"^https?://(www\.)?tiktok\.com/@[A-Za-z0-9._]{1,30}/?(\?.*)?$"#
        case .facebook:  return #"^https?://(www\.|web\.|m\.)?(facebook\.com|fb\.com)/([A-Za-z0-9.]{3,60}|profile\.php\?id=\d+)/?(\?.*)?$"#
        case .youtube:   return #"^https?://(www\.)?youtube\.com/(@[A-Za-z0-9._-]{3,30}|channel/UC[\w-]{22}|c/[A-Za-z0-9._-]+)/?(\?.*)?$"#
        case .lemon8:    return #"^https?://(www\.)?lemon8[\w.-]*/[@A-Za-z0-9._/-]+$"#
        case .x:         return #"^https?://(www\.)?(x|twitter)\.com/[A-Za-z0-9_]{1,15}/?(\?.*)?$"#
        }
    }

    /// ลิงก์โพสต์ที่คนชอบวางผิด — บอกให้ชัดว่าต้องการหน้าโปรไฟล์ ไม่ใช่ "รูปแบบไม่ถูกต้อง" ลอย ๆ
    private var postPattern: String? {
        switch self {
        case .instagram: return #"/(p|reel|reels|stories|explore)/"#
        case .tiktok:    return #"/(video|photo)/"#
        case .facebook:  return #"/(posts|photo|videos|watch|groups)/"#
        case .youtube:   return #"/(watch|shorts|playlist)"#
        case .x:         return #"/status/"#
        case .lemon8:    return nil
        }
    }

    /// ทำให้เป็น URL เต็ม — ผู้ใช้วาง `tiktok.com/@x` มาก็ต้องผ่าน
    func normalizedLink(_ raw: String) -> String {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return "" }
        return s.lowercased().hasPrefix("http") ? s : "https://" + s
    }

    /// ข้อความผิดพลาดของลิงก์ — nil = ใช้ได้ (หรือยังว่าง — ความว่างเป็นเรื่องของ "ต้องกรอก" ไม่ใช่ "ผิด")
    func linkError(_ raw: String) -> String? {
        let s = normalizedLink(raw)
        guard !s.isEmpty else { return nil }
        if let bad = postPattern, Self.matches(bad, in: s, whole: false) {
            return "นี่คือลิงก์โพสต์ ไม่ใช่ลิงก์โปรไฟล์ — ใส่ลิงก์หน้าโปรไฟล์/ช่องแทน"
        }
        if !Self.matches(linkPattern, in: s, whole: true) {
            return "รูปแบบลิงก์ \(name) ไม่ถูกต้อง (ตัวอย่าง: \(placeholderLink))"
        }
        return nil
    }

    /// ชื่อผู้ใช้จากลิงก์ — ใช้เป็น handle ตั้งต้นของการ์ด
    func handle(from raw: String) -> String {
        let s = normalizedLink(raw)
        guard let url = URL(string: s) else { return "" }
        let parts = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        guard let first = parts.first else { return "" }
        var h = first
        if (h == "channel" || h == "c"), parts.count > 1 { h = parts[1] }
        if self == .lemon8, let at = parts.last(where: { $0.hasPrefix("@") }) { h = at }
        if h.hasPrefix("@") { h.removeFirst() }
        return h
    }

    private static func matches(_ pattern: String, in s: String, whole: Bool) -> Bool {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return false }
        let range = NSRange(s.startIndex..., in: s)
        guard let m = re.firstMatch(in: s, options: [], range: range) else { return false }
        return whole ? m.range == range : true
    }
}

extension ContentFormat {
    /// ชื่อไทยสั้น ๆ สำหรับฟอร์มและชื่อรายการมาตรฐานบนการ์ด
    var title: String {
        switch self {
        case .photo:      return "ภาพนิ่ง"
        case .shortVideo: return "คลิปสั้น"
        case .longVideo:  return "คลิปยาว"
        case .seeding:    return "แชร์ / Story"
        }
    }
    var unit: String {
        switch self {
        case .photo:      return "ชิ้น"
        case .shortVideo: return "คลิป"
        case .longVideo:  return "คลิป"
        case .seeding:    return "ชุด"
        }
    }
}
