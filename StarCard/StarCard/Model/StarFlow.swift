import SwiftUI
import PhosphorSwift

// MARK: - flow ใหม่ "Unbox × StarCard" — state จำลองทั้งชุด (ถอดจาก unbox-mock/js/newflow.js 23 ก.ย. 2569)
//
// หลักคิดเดียวกับเว็บ: ไม่แก้หน้าเดิมของ Unbox แค่ "แทรกหน้ากรอกข้อมูล Star Profile" ก่อนถึงหน้าเดิม
// ทุกช่องดู `have`: มี = ไม่ถามซ้ำ · ไม่มี = โผล่ใน wizard · กรอกแล้วกลายเป็น "มี" งานถัดไปเติมให้เอง
// ข้อมูลจริงยังไม่ผูกกับ `Profile.me` — เป็นธงจำลองเหมือนแผงควบคุมของเว็บ เพื่อเล่น flow ได้ครบก่อน

/// ช่องข้อมูลใน Star Profile ที่ flow ใหม่ถาม (ยืนยันตัวตนแยกเป็น `verify`)
enum StarDataKey: String, CaseIterable, Codable, Identifiable {
    case kind, socials, categories, about, media, rate, insight, province, availability, contact, address, bank, draftRounds, limits, religion
    var id: String { rawValue }

    /// build ก่อนหน้าแยก photos/works/videos — รวมเป็น `media` ขั้นเดียว (ผู้ใช้ 24 ก.ย. 2569) · state เก่าที่จำไว้ยังอ่านได้
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        if let k = StarDataKey(rawValue: raw) { self = k }
        else if ["photos", "works", "videos"].contains(raw) { self = .media }
        else { throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: raw)) }
    }

    /// ชื่อที่ใช้ในแผง lab และหน้า intro ของ wizard
    var label: String {
        switch self {
        case .kind: return "ประเภทครีเอเตอร์"
        case .socials: return "ช่องทางโซเชียล"
        case .categories: return "สายที่ใช่"
        case .about: return "แนะนำตัว"
        case .media: return "รูปและผลงาน"
        case .rate: return "เรทรับงาน"
        case .insight: return "ข้อมูลผู้ติดตาม"
        case .province: return "พื้นที่รับงาน"
        case .availability: return "วันเวลาว่างรับงาน"
        case .contact: return "ช่องทางติดต่อ"
        case .address: return "ที่อยู่รับของ"
        case .bank: return "บัญชีรับเงิน"
        case .draftRounds: return "รอบแก้งาน"
        case .limits: return "งานที่ขอผ่าน"
        case .religion: return "ศาสนา"
        }
    }
}

/// `UserVerifyStatus` ของแอปหลัก — ย่อเหลือสามค่าที่ flow ใช้
enum VerifyStatus: String, Codable, CaseIterable {
    case none, waiting, approved
    var label: String {
        switch self {
        case .none: return "ยังไม่ได้ยืนยันตัวตน"
        case .waiting: return "รอทีมงานตรวจ"
        case .approved: return "ยืนยันตัวตนแล้ว"
        }
    }
}

/// `BrandCampaignState` ของแอปหลัก — เฉพาะที่ happy case ผ่าน
enum CampaignPhase: String, Codable {
    case register, registered, waitingAcceptQuota, acceptedQuota
}

enum OrderPhase: String, Codable {
    case preparing, shipping, delivered
    var label: String {
        switch self {
        case .preparing: return "กำลังจัดเตรียมพัสดุ"
        case .shipping: return "เช็กเลขติดตามพัสดุ"
        case .delivered: return "จัดส่งสำเร็จ"
        }
    }
}

/// ช่องโซเชียลของผู้ใช้จำลอง (= `D.USER.socials` ของเว็บ)
enum StarSocial: String, CaseIterable, Codable, Identifiable {
    case instagram, tiktok, facebook, youtube, x, lemon8
    var id: String { rawValue }
    var name: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .facebook: return "Facebook"
        case .youtube: return "YouTube"
        case .x: return "X"
        case .lemon8: return "Lemon8"
        }
    }
    var short: String {
        switch self {
        case .instagram: return "IG"
        case .facebook: return "FB"
        default: return name
        }
    }
    var icon: String {
        switch self {
        case .instagram: return SHIcon.instagram
        case .tiktok: return SHIcon.tiktok
        case .facebook: return SHIcon.facebook
        case .youtube: return SHIcon.youtube
        case .x: return SHIcon.x
        case .lemon8: return SHIcon.lemon8
        }
    }
    /// รูปแบบคอนเทนต์ต่อช่อง — ตาม SocialPriceProfileView ของ salehere-ios
    var formats: [StarFormat] {
        switch self {
        case .instagram, .facebook: return [.shortVideo, .photo]
        case .tiktok: return [.shortVideo]
        case .youtube: return [.shortVideo, .longVideo]
        case .x: return [.shortVideo, .seeding]
        case .lemon8: return [.photo, .shortVideo]
        }
    }
    /// ลิงก์โปรไฟล์ (= `PLAT.re` / `.bad` / `.ph` ของฟอร์มเว็บ v16.1)
    var linkPattern: String {
        switch self {
        case .instagram: return #"^https?://(www\.)?instagram\.com/[A-Za-z0-9._]{1,30}/?(\?.*)?$"#
        case .tiktok: return #"^https?://(www\.)?tiktok\.com/@[A-Za-z0-9._]{1,30}/?(\?.*)?$"#
        case .facebook: return #"^https?://(www\.|web\.|m\.)?(facebook\.com|fb\.com)/([A-Za-z0-9.]{3,60}|profile\.php\?id=\d+)/?(\?.*)?$"#
        case .youtube: return #"^https?://(www\.|m\.)?youtube\.com/(@[A-Za-z0-9._-]{3,30}|channel/[A-Za-z0-9_-]{10,}|c/[A-Za-z0-9._-]+)/?(\?.*)?$"#
        case .x: return #"^https?://(www\.)?(x|twitter)\.com/[A-Za-z0-9_]{1,15}/?(\?.*)?$"#
        case .lemon8: return #"^https?://(www\.)?lemon8[\w.-]*/[@A-Za-z0-9._/-]+$"#
        }
    }
    /// ลิงก์โพสต์ ไม่ใช่โปรไฟล์
    var postPattern: String? {
        switch self {
        case .instagram: return #"/(p|reel|reels|stories|explore)/"#
        case .tiktok: return #"/(video|photo)/"#
        case .facebook: return #"/(posts|photo|videos|watch|groups)/"#
        case .youtube: return #"/(watch|shorts|live)|youtu\.be/"#
        case .x: return #"/status/"#
        case .lemon8: return nil
        }
    }
    var linkPlaceholder: String {
        switch self {
        case .instagram: return "instagram.com/username"
        case .tiktok: return "tiktok.com/@username"
        case .facebook: return "facebook.com/yourpage"
        case .youtube: return "youtube.com/@channel"
        case .x: return "x.com/username"
        case .lemon8: return "lemon8-app.com/@username"
        }
    }
    /// ลิงก์ mock ที่กรอกให้ตอนกด "เชื่อม" (ยังไม่มี OAuth) — ผ่าน `checkLink` เสมอ
    var mockLink: String {
        switch self {
        case .instagram: return "https://instagram.com/mintmint.review"
        case .tiktok: return "https://tiktok.com/@mintmint.review"
        case .facebook: return "https://facebook.com/mintmintreview"
        case .youtube: return "https://youtube.com/@mintmintreview"
        case .x: return "https://x.com/mintmint_review"
        case .lemon8: return "https://lemon8-app.com/@mintmint.review"
        }
    }
    /// ยอดผู้ติดตาม mock คู่กับ `mockLink` — ที่มาตาม `fetch` (เชื่อมบัญชี/ดึง API/กรอกเอง)
    var mockFollowers: Int {
        switch self {
        case .instagram: return 24_800
        case .tiktok: return 58_300
        case .facebook: return 12_400
        case .youtube: return 8_900
        case .x: return 3_200
        case .lemon8: return 6_700
        }
    }
    /// ยอดผู้ติดตามมาจากไหน (= `PLAT.fetch`): YouTube ดึงจาก API · IG/TikTok/FB เชื่อมบัญชีหรือกรอกเอง · X/Lemon8 กรอกเอง
    var fetch: String {
        switch self {
        case .youtube: return "api"
        case .instagram, .tiktok, .facebook: return "connect"
        case .x, .lemon8: return "manual"
        }
    }
    /// ตรวจลิงก์ (= `linkState` ของฟอร์มเว็บ) — ไม่มี https:// เติมให้
    func checkLink(_ raw: String) -> (ok: Bool, msg: String, url: String) {
        var v = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !v.isEmpty else { return (false, "", "") }
        if v.range(of: #"^https?://"#, options: [.regularExpression, .caseInsensitive]) == nil { v = "https://" + v }
        if let bad = postPattern, v.range(of: bad, options: [.regularExpression, .caseInsensitive]) != nil {
            return (false, "นี่คือลิงก์โพสต์ ไม่ใช่ลิงก์โปรไฟล์ — ใส่ลิงก์หน้าโปรไฟล์/ช่องแทน", v)
        }
        if v.range(of: linkPattern, options: [.regularExpression, .caseInsensitive]) == nil {
            return (false, "รูปแบบลิงก์ \(name) ไม่ถูกต้อง (ตัวอย่าง: \(linkPlaceholder))", v)
        }
        return (true, "", v)
    }
    /// ช่องที่แนบข้อมูลผู้ติดตามได้ (SocialInsight)
    var supportsInsight: Bool { [.facebook, .instagram, .youtube, .tiktok].contains(self) }
}

enum StarFormat: String, CaseIterable, Codable, Identifiable {
    case shortVideo, photo, longVideo, seeding
    var id: String { rawValue }
    var name: String {
        switch self {
        case .shortVideo: return "Short Video"
        case .photo: return "Photo"
        case .longVideo: return "Long Video"
        case .seeding: return "Seeding"
        }
    }
    var multiplier: Double {
        switch self {
        case .shortVideo: return 1
        case .photo: return 0.8
        case .longVideo: return 1.4
        case .seeding: return 0.5
        }
    }
}

/// แถวใน "เติมการ์ดให้เต็ม" (= `REVEAL_ROWS` ของเว็บ) — ลำดับตามที่แบรนด์ถามบ่อย
struct StarRow: Identifiable {
    /// nil = ยืนยันตัวตน (ดู `verify` แทน `have`)
    let key: StarDataKey?
    let icon: Ph
    let title: String
    let why: String
    var id: String { key?.rawValue ?? "kyc" }

    /// กรอกแล้วไปขึ้นตรงไหนบนการ์ด (มุมมอง "การ์ด" ของ Star Profile)
    var onCard: String {
        switch key {
        case nil: return "ขึ้นตรา Verified บนการ์ด"
        case .rate?: return "ขึ้นป้ายราคาบนการ์ด"
        case .about?: return "ขึ้นบรรทัดแนะนำตัวใต้ชื่อ"
        case .media?: return "ขึ้นรูปหลัก กำแพงผลงาน และคลิปบนการ์ด"
        case .insight?: return "ขึ้นกราฟผู้ชมบนการ์ด"
        case .province?: return "ขึ้นป้ายพื้นที่รับงาน"
        case .availability?: return "ขึ้นวันว่างในส่วนรับงาน"
        case .contact?: return "ขึ้น LINE · เบอร์ · เว็บไซต์บนการ์ด"
        case .socials?: return "ขึ้นยอดผู้ติดตามรายช่อง"
        case .categories?: return "ขึ้นชิปสายงานใต้ชื่อ"
        case .bank?, .draftRounds?, .address?: return "ไม่ขึ้นการ์ด · ใช้ตอนได้งาน"
        case .kind?: return "บอกแบรนด์ว่าคุยกับบุคคลหรือเพจ"
        case .limits?, .religion?: return "ไม่ขึ้นการ์ด · ใช้กรองงานที่ส่งให้คุณ"
        }
    }

    static let all: [StarRow] = [
        StarRow(key: nil, icon: .sealCheck, title: "ยืนยันตัวตน", why: "ต้องผ่านก่อนแบรนด์เลือก · ขึ้นป้าย Verified"),
        StarRow(key: .rate, icon: .coins, title: "เรทรับงาน", why: "แบรนด์ดูราคาก่อนคัดเลือก"),
        StarRow(key: .about, icon: .textAlignLeft, title: "แนะนำตัว", why: "1 บรรทัดใต้ชื่อบนการ์ด"),
        StarRow(key: .media, icon: .imageSquare, title: "รูปและผลงาน", why: "แบรนด์ดูหน้าตาและงานของคุณก่อนคัดเลือก"),
        StarRow(key: .insight, icon: .usersThree, title: "ข้อมูลผู้ติดตาม", why: "แบรนด์เห็นว่าคนดูคุณเป็นใคร"),
        StarRow(key: .province, icon: .mapPin, title: "พื้นที่รับงาน", why: "งานหน้าร้านใกล้คุณขึ้นก่อน"),
        StarRow(key: .availability, icon: .calendarDots, title: "วันเวลาว่างรับงาน", why: "แบรนด์ดูวันว่างของคุณตอนคัดคน"),
        StarRow(key: .contact, icon: .chatCircleText, title: "ช่องทางติดต่อ", why: "แบรนด์ทักคุณตรงนี้ · ขึ้นบนการ์ด"),
        StarRow(key: .socials, icon: .broadcast, title: "ช่องทางของฉัน", why: "ยอดผู้ติดตามขึ้นการ์ดอัตโนมัติ"),
        StarRow(key: .categories, icon: .sparkle, title: "สายที่ใช่", why: "งานตรงสายขึ้นหน้าแรกให้"),
        StarRow(key: .bank, icon: .bank, title: "การรับเงิน", why: "ค่าตัวเข้าบัญชีทันทีเมื่องานจบ"),
        StarRow(key: .draftRounds, icon: .arrowsClockwise, title: "รอบแก้งาน", why: "ตกลงไว้ก่อน ไม่ต้องเถียงหน้างาน"),
        StarRow(key: .address, icon: .package, title: "ที่อยู่รับของ", why: "ถามตอนได้งานแรก · รับของรีวิวได้เลย"),
        StarRow(key: .limits, icon: .prohibit, title: "งานที่ขอผ่าน", why: "งานแนวนี้จะไม่ถูกส่งมาให้คุณ"),
        StarRow(key: .religion, icon: .handsPraying, title: "ศาสนา", why: "กรองงานที่อาจขัดกับความเชื่อของคุณ"),
    ]
}

/// ขั้นของ wizard — `intro` มีเฉพาะตอนสมัคร · `kyc` = ยืนยันตัวตน (ออกไปทำแล้วกลับมา)
enum WizStep: String, Codable, Hashable {
    case intro, kind, socials, categories, about, media, kyc, rate, insight, province, availability, contact, address, bank, draftRounds, limits, religion

    var dataKey: StarDataKey? { StarDataKey(rawValue: rawValue) }
    /// ช่องทาง · เรท · insight อยู่หน้าเดียวกัน (ผู้ใช้ 29 ก.ย. 2569) — เรท/insight ไปเปิดหน้า `socials`
    /// แนะนำตัว + รูปและผลงาน = หน้าเดียว (ผู้ใช้ 29 ก.ย. 2569) — แนะนำตัวไม่บังคับ
    var page: WizStep {
        switch self {
        case .rate, .insight: return .socials
        case .about: return .media
        default: return self
        }
    }
    /// ข้อมูลที่หน้านี้เก็บ (หน้าช่องทางเก็บ 3 อย่าง · หน้าผลงานเก็บ 2 อย่าง)
    var keys: [StarDataKey] {
        switch self {
        case .socials: return [.socials, .rate, .insight]
        case .media: return [.media, .about]
        default: return dataKey.map { [$0] } ?? []
        }
    }
    /// รวมขั้นที่อยู่หน้าเดียวกัน เรียงตามที่เจอครั้งแรก
    static func pages(_ list: [WizStep]) -> [WizStep] {
        list.reduce(into: []) { out, s in if !out.contains(s.page) { out.append(s.page) } }
    }
    /// ข้ามได้ (ไม่บังคับ)
    var optional: Bool { self == .insight }
    var name: String {
        switch self {
        case .socials: return "ช่องทางและเรท"
        case .media: return "แนะนำตัวและผลงาน"
        default: return dataKey?.label ?? (self == .kyc ? "ยืนยันตัวตน" : "")
        }
    }
    /// ชื่อช่องบนการ์ดที่ยังว่าง (หน้า intro)
    var ghost: String {
        switch self {
        case .socials: return "ยอดผู้ติดตาม"
        case .categories: return "สายที่ใช่"
        case .about: return "แนะนำตัว"
        case .media: return "รูปและผลงาน"
        case .kyc: return "Verified"
        case .rate: return "เรทรับงาน"
        case .insight: return "ข้อมูลผู้ติดตาม"
        case .province: return "พื้นที่"
        case .availability: return "วันว่าง"
        case .contact: return "ช่องทางติดต่อ"
        default: return name
        }
    }
    /// บรรทัดใต้หัวข้อ: "แบรนด์ใช้ข้อนี้ทำอะไร" + กติกาที่จำเป็นจริง ๆ (คั่นด้วย " · ")
    var line: [String] {
        switch self {
        case .kind: return ["แบรนด์เห็นว่าคุยกับใคร", "เลือก 1 อย่าง"]
        case .socials: return ["แบรนด์ดูข้อนี้ก่อนคัดเลือก", "ผูก 1 ช่องพอ", "เรทใส่ให้แล้ว"]
        case .categories: return ["แบรนด์ใช้ตัดสินใจ", "เลือกได้ถึง 5"]
        case .about: return ["แบรนด์อ่านความเป็นตัวคุณจากบรรทัดนี้"]
        case .media: return ["แบรนด์ดูหน้าตาและงานก่อนคัดเลือก"]
        case .kyc: return ["แบรนด์คัดเลือกคนที่ยืนยันแล้ว", "ส่งใบสมัครได้ระหว่างรอตรวจ"]
        case .rate: return ["แบรนด์ดูราคาก่อนคัดเลือก", "ใส่ราคามาตรฐานให้แล้ว"]
        case .insight: return ["แบรนด์ใช้คัดเลือกกลุ่มเป้าหมาย", "ทำช่องเดียวก็ได้"]
        case .province: return ["แบรนด์ใช้คัดเลือกงานหน้าร้าน", "เลือกได้ถึง 3"]
        case .availability: return ["แบรนด์ดูวันว่างตอนคัดเลือก"]
        case .contact: return ["แบรนด์ทักคุณตรงนี้", "ขึ้นบนการ์ด"]
        case .draftRounds: return ["ตกลงไว้ก่อน ไม่ต้องเถียงหน้างาน"]
        case .limits: return ["งานแนวนี้จะไม่ถูกส่งมาให้คุณ", "เลือกได้หลายข้อ"]
        case .religion: return ["กรองงานที่อาจขัดกับความเชื่อ", "ไม่ขึ้นการ์ด"]
        default: return []
        }
    }
}

enum WizKind: String, Codable { case apply, accept, one }

/// state กลางของ flow ใหม่ — ตัวเดียวทั้งแอปจำลอง จำลง UserDefaults ให้เปิดแอปแล้วอยู่ที่เดิม (เหมือน localStorage ของเว็บ)
@Observable
final class StarFlow {
    static let shared = StarFlow()

    /// ช่องที่ "มีแล้ว" ใน Star Profile
    var have: Set<StarDataKey> = [] { didSet { save() } }
    var verify: VerifyStatus = .none {
        didSet {
            // วันที่ผ่าน KYC — ตราและใบรับรองบนการ์ดพิมพ์วันนี้ (เดิมเป็นค่าตายตัว "12.09.69")
            if verify == .approved { if verifiedAt == nil { verifiedAt = Date() } } else { verifiedAt = nil }
            save()
        }
    }
    var verifiedAt: Date? = nil { didSet { save() } }
    var phase: CampaignPhase = .register { didSet { save() } }
    var order: OrderPhase = .preparing { didSet { save() } }
    /// ส่งลิงก์รีวิวแล้ว (ขั้นสุดท้าย) — การ์ดขึ้นผลงาน 1 งาน
    var reviewed = false { didSet { save() } }
    /// ดราฟต์ผ่านแล้ว เปิดให้ส่งลิงก์รีวิว — หน้ากิจกรรมขึ้นปุ่ม "ส่งลิงก์รีวิว" (แอปจำลองไม่มีหน้าดราฟต์ ตั้งจากแผง lab ขั้น 12)
    var draftApproved = false { didSet { save() } }
    /// ช่องโซเชียลที่ผูกไว้กับบัญชี Sale Here (ผูกไว้ก่อนแล้วก็ได้ แต่ยังไม่ขึ้นการ์ดจนกว่าจะติ๊ก `socials`)
    var connected: Set<StarSocial> = [] { didSet { save() } }
    /// เคยเห็นหน้าการ์ดเกิดแล้ว — ครั้งถัดไปไม่เล่น motion ยาว
    var revealSeen = false { didSet { save() } }
    var consent = false { didSet { save() } }
    var doneOpen = false
    /// ตู้ widget ขอให้พาไปดูงานที่เปิดรับ (ใบแบรนด์/ผลงานยืนยันยังล็อก) — พื้นที่การ์ดปิดตัว แล้ว shell สลับไปแท็บหน้าแรก
    var jobsRequested = false

    // คำตอบที่กรอก (จำไว้ให้ wizard เปิดมาเห็นค่าเดิม)
    var about = "" { didSet { save() } }
    var categories: [String] = [] { didSet { save() } }
    var provinces: [String] = [] { didSet { save() } }
    var availDays = "" { didSet { save() } }
    /// Creator (บุคคล) / Page (เพจ) — ขั้น `type` ของฟอร์มเว็บ
    var creatorKind = "creator" { didSet { save() } }
    /// รับเงินในนามบุคคล / นามบริษัท — `PAYDOC` ของฟอร์มเว็บ (หัก ณ ที่จ่าย 3% / 7%)
    var payKind = "person" { didSet { save() } }
    var availTime = "" { didSet { save() } }
    /// ช่วงว่างแยกรายวัน (ผู้ใช้ 2 ต.ค. 2569: "จ อ พ มันเลือกช่วงเวลาต่างกัน") — ชื่อย่อวัน → ช่วง (เช้า/บ่าย/เย็น)
    /// เป็นตัวจริง · `availDays` (วันที่มีช่วง) และ `availTime` (รวมทุกช่วง) ตามมาเองให้ส่วนที่อ่านแบบเดิม
    var availWeek: [String: [String]] = [:] {
        didSet {
            availDays = IntakeCatalog.weekShort.filter { !(availWeek[$0] ?? []).isEmpty }.joined(separator: " ")
            let all = Set(availWeek.values.joined())
            availTime = all.count == StarFlow.daySlots.count ? "ตลอดวัน" : StarFlow.daySlots.filter(all.contains).joined(separator: "+")
            save()
        }
    }
    static let daySlots = ["เช้า", "บ่าย", "เย็น"]
    /// "จ–ศ เย็น · ส–อา ตลอดวัน" — วันที่ช่วงเหมือนกันรวมเป็นกลุ่ม · ติดกันเขียนเป็นช่วง
    var availSummary: [String] {
        let days = IntakeCatalog.weekShort
        var groups: [(slots: [String], days: [Int])] = []
        for (i, d) in days.enumerated() {
            let s = StarFlow.daySlots.filter { (availWeek[d] ?? []).contains($0) }
            guard !s.isEmpty else { continue }
            if let g = groups.firstIndex(where: { $0.slots == s }) { groups[g].days.append(i) } else { groups.append((s, [i])) }
        }
        return groups.map { g in
            let run = g.days.count > 2 && g.days.last! - g.days.first! == g.days.count - 1
            let d = run ? "\(days[g.days.first!])–\(days[g.days.last!])" : g.days.map { days[$0] }.joined(separator: " ")
            let t = g.slots.count == StarFlow.daySlots.count ? "ตลอดวัน" : g.slots.joined(separator: "+")
            return "\(d) \(t)"
        }
    }
    var draftRounds = 2 { didSet { save() } }
    var rates: [String: Int] = [:] { didSet { save() } }
    var insightSlots: Set<String> = [] { didSet { save() } }
    /// งานที่ขอผ่าน = `SUB.limit` ของฟอร์มเว็บ (ค่า `v` ของแต่ละข้อ · "ไม่มีข้อจำกัด" เลือกได้ข้อเดียว) + ข้อความ "อื่น ๆ"
    var limits: [String] = [] { didSet { save() } }
    var limitOther = "" { didSet { save() } }
    /// `SUB.religion` ของฟอร์มเว็บ — ข้อมูลอ่อนไหว ไม่ขึ้นการ์ด
    var religion = "" { didSet { save() } }
    /// Line ID กรอกในกล่องติดต่อของฟอร์มสมัคร แล้วจำไว้ให้งานถัดไป (`SUB.name.line` ของฟอร์มเว็บ)
    var lineID = "" { didSet { save() } }
    /// เบอร์ + เว็บไซต์ — ขั้น "ช่องทางติดต่อ" (ผู้ใช้ 2 ต.ค. 2569) ขึ้นบนการ์ดคู่กับ LINE
    var phone = "" { didSet { save() } }
    var website = "" { didSet { save() } }
    /// ลิงก์โปรไฟล์ + ยอดผู้ติดตามที่กรอกตอนเชื่อมช่อง (ไม่มี = ใช้ค่าจำลองของ `StarSocial`)
    var links: [String: String] = [:] { didSet { save() } }
    var followerCounts: [String: Int] = [:] { didSet { save() } }
    /// ยอดมาจากไหน: api (YouTube ดึงเอง) · connect (เชื่อมบัญชี) · manual (กรอกเอง รอทีมงานตรวจ)
    var followerSources: [String: String] = [:] { didSet { save() } }
    func followers(_ s: StarSocial) -> Int { followerCounts[s.rawValue] ?? 0 }
    func link(_ s: StarSocial) -> String { links[s.rawValue] ?? "" }
    /// ชื่อผู้ใช้ที่อ่านจากลิงก์ที่ผู้ใช้วางเอง — ไม่มีลิงก์ = ว่าง
    func handle(_ s: StarSocial) -> String { SocialType(rawValue: s.rawValue)?.handle(from: link(s)) ?? "" }

    // MARK: ข้อมูลที่ผู้ใช้กรอกเอง (1 ต.ค. 2569: ไม่มีค่าตัวอย่างเติมให้ล่วงหน้า — ทุกอย่างมาจากที่ผู้ใช้พิมพ์ใน Star Profile)

    /// ตัวเลขผู้ติดตามที่อ่านจากหน้า Insights ของแต่ละช่อง — คีย์ "<ช่อง>_<gender|age|location>"
    var insightValues: [String: [InsightSeg]] = [:] { didSet { save() } }
    var addressInfo = StarAddress() { didSet { save() } }
    var bankInfo = StarBank() { didSet { save() } }

    /// ผู้ชมที่การ์ดวาด — รวมจากช่องแรกที่กรอกแต่ละหัวข้อ · ยังไม่กรอก = ว่าง (widget ขึ้น "รอข้อมูล")
    func audience() -> AudienceInsight {
        guard has(.insight) else { return .empty }
        let socials = StarSocial.allCases.filter { connected.contains($0) }
        func segs(_ k: String) -> [InsightSeg] {
            for s in socials { if let v = insightValues["\(s.rawValue)_\(k)"], !v.isEmpty { return v } }
            return []
        }
        let g = segs("gender")
        func pct(_ prefix: String) -> Double { g.first { $0.label.hasPrefix(prefix) }?.pct ?? 0 }
        return AudienceInsight(female: pct("หญิง"), male: pct("ชาย"), other: pct("อื่น"),
                               ages: segs("age").map { .init(label: $0.label, share: $0.pct) },
                               places: segs("location").map { .init(name: $0.label, share: $0.pct) })
    }

    // MARK: กติกา

    /// ขั้นต่ำของรูป/วิดีโอ = เกณฑ์โปรไฟล์ 100% เดิม (gateway user-creator-profile.type.js: รูป ≥3 · ผลงาน ≥2 · วิดีโอ ≥2)
    static let minPhotos = Portfolio.creatorSlots
    static let minWorks = 2
    static let minVideos = 2

    /// การ์ดเกิดจากสิ่งที่มีอยู่แล้ว (ช่องโซเชียล + สายที่ใช่) — ไม่มี "ระดับ": มีการ์ด = เป็น STAR แล้ว
    /// การ์ดเกิดเมื่อมีสายที่ใช่ + รูปและผลงาน (ผู้ใช้ 29 ก.ย. 2569: ทาง Star Profile ถามแค่ 2 อย่างนี้ การ์ดเกิดเลยแม้ยังไม่มีช่องทาง)
    var hasCard: Bool { have.contains(.kind) && have.contains(.categories) && have.contains(.media) }
    /// ผ่าน flow สมัครงานแล้ว (ส่งยืนยันตัวตนแล้ว) — ก่อนหน้านั้นยังไม่ใช่ STAR ข้ออื่นใน Star Profile ล็อกไว้
    var isMember: Bool { verify != .none }
    /// ข้อที่กรอกจาก Star Profile ได้ตั้งแต่ยังไม่เป็น STAR
    static let openKeys: Set<StarDataKey?> = [.kind, .categories, .media, .about]
    /// ยังกรอกไม่ได้ — ปลดล็อกเมื่อสมัครงาน (ข้อที่กรอกแล้วไม่ล็อก)
    func locked(_ key: StarDataKey?) -> Bool {
        guard !isMember, !StarFlow.openKeys.contains(key) else { return false }
        return key.map { !has($0) } ?? true
    }
    /// ทางเข้า Star Profile ตอนยังไม่มีการ์ด = ถามแค่ Creator/Page + สายที่ใช่ + รูปและผลงาน (ผู้ใช้ 29 ก.ย. 2569)
    var cardSteps: [WizStep] { [WizStep.kind, .categories, .media].filter { !has($0.dataKey!) } }
    var isVerified: Bool { verify == .approved }
    /// STAR เต็มตัว = การ์ด + ยืนยันตัวตนผ่าน
    var isStar: Bool { hasCard && isVerified }

    func has(_ k: StarDataKey) -> Bool { have.contains(k) }
    func done(_ row: StarRow) -> Bool { row.key.map(has) ?? isVerified }

    /// ขั้นที่ต้องมีก่อน "ส่งใบสมัคร" — แค่พอให้การ์ดเกิด (ช่องทาง · สาย · แนะนำตัว) ที่เหลือเติมทีหลังระหว่างรอผล
    /// (ผู้ใช้ 24 ก.ย. 2569: "flow ลงทะเบียน Unbox ยังไม่ให้กรอกหมด เอาแค่เท่าที่ส่งลงทะเบียนได้") · KYC ชวนใน dialog สำเร็จเหมือนแอปเดิม
    var registerSteps: [WizStep] {
        // = ฟอร์มสมัครเดิมถาม: ประเภท · ช่องทาง · สาย · เรทต่อรูปแบบ · ข้อมูลผู้ติดตาม (ข้ามได้)
        // แนะนำตัว/พื้นที่/วันว่างไม่จำเป็นต่อการลงทะเบียน — ค่อยเติมทีหลัง (ผู้ใช้ 24 ก.ย.)
        // ยืนยันตัวตนต้องทำก่อนส่งใบสมัคร (ผู้ใช้ 24 ก.ย.) — ส่งได้ระหว่างรอทีมงานตรวจ
        // รูปและผลงาน (รูปของฉัน · รูปผลงาน · วิดีโอ ในขั้นเดียว) = ต้องมีก่อนเป็น STAR (ผู้ใช้ 24 ก.ย.: "ขาลงทะเบียนก็ต้องกรอก")
        // ช่องทาง + เรท + ข้อมูลผู้ติดตาม = หน้าเดียว (ผู้ใช้ 29 ก.ย. 2569)
        // หน้าผลงานนับแค่รูป/คลิป — แนะนำตัวไม่บังคับตอนลงทะเบียน (ผู้ใช้ 24 ก.ย. "เอา about ออกไปก่อน")
        // พื้นที่รับงาน + วันเวลาว่าง ต้องถามก่อนลงทะเบียน (ผู้ใช้ 29 ก.ย. 2569) · ช่องทางติดต่อต่อท้ายวันว่าง (ผู้ใช้ 2 ต.ค. 2569)
        [WizStep.kind, .socials, .categories, .media, .province, .availability, .contact, .kyc].filter(needs)
    }
    /// ข้อไม่บังคับ — ยังไม่กรอกก็ไม่ทำให้หน้าของมันโผล่ซ้ำ (ผู้ใช้ 1 ต.ค. 2569: "ไม่บังคับ = ไม่ถามซ้ำ") · เติมเองได้จากแถวใน Star Profile
    static let optionalKeys: Set<StarDataKey> = [.insight, .about]
    /// ขั้นนี้ยังมีข้อบังคับที่ขาด (หน้าช่องทาง = ช่องทาง + เรท · หน้าผลงาน = รูปและผลงาน)
    func needs(_ s: WizStep) -> Bool {
        s == .kyc ? verify == .none : s.keys.contains { !StarFlow.optionalKeys.contains($0) && !has($0) }
    }
    /// งานที่ขอผ่าน + ศาสนา อยู่ใน Star Profile เท่านั้น ไม่ถามใน flow Unbox (ผู้ใช้ 29 ก.ย. 2569)
    /// ขั้นที่ยังขาดทั้งหมดของ Star Profile — ทางเข้าจากหน้า Star Profile ("สมัครเป็น STAR · N ข้อ") พากด next จนหมดทุกข้อ
    /// รวมที่อยู่/บัญชี/รอบแก้ด้วย ปิดกลางทางได้ (ผู้ใช้ 24 ก.ย.) · ต่างจาก `registerSteps` ที่ถามแค่พอส่งใบสมัคร
    var applySteps: [WizStep] {
        let all: [WizStep] = [.kind, .socials, .categories, .media, .kyc, .province, .availability, .contact, .address, .bank, .draftRounds, .limits, .religion]
        return all.filter(needs)
    }
    /// ขั้นที่ยังขาดก่อนตอบรับ (ถามตอนได้งานแล้วเท่านั้น)
    /// บัญชีรับเงินไม่ถามใน flow งาน — ฟอร์มรับเงินของแอปหลักเก็บเองอยู่แล้ว (ผู้ใช้ 1 ต.ค. 2569) · ยังกรอกได้จาก Star Profile
    var acceptSteps: [WizStep] {
        [WizStep.address, .draftRounds].filter { !has($0.dataKey!) }
    }
    /// ข้อที่ขาดบนหน้าการ์ด (ไม่รวมยืนยันตัวตน ซึ่งเป็น flow แยก)
    var missingSteps: [WizStep] {
        WizStep.pages(StarRow.all.compactMap { r -> WizStep? in
            guard let k = r.key, !has(k) else { return nil }
            return WizStep(rawValue: k.rawValue)
        })
    }
    var doneCount: Int { StarRow.all.filter(done).count }
    var pct: Double { Double(doneCount) / Double(StarRow.all.count) }

    /// ค่าที่กรอกไว้ของแถว — ป้ายชิ้นละค่า (= `r.done(s)` ของเว็บ)
    func facts(_ row: StarRow) -> [String] {
        guard let key = row.key else { return ["Verified"] }
        switch key {
        case .kind: return [creatorKind == "page" ? "Page (เพจ)" : "Creator (บุคคล)"]
        case .rate:
            // เรทจริงที่ตั้งไว้ (ช่องแรก × รูปแบบแรก) — ตัวเลขชุดเดียวกับใบเรทบนการ์ด ไม่ใช่ค่าตายตัว
            let list = StarSocial.allCases.filter { connected.contains($0) }
            let shown = list.prefix(2).compactMap { s -> String? in
                guard let f = s.formats.first else { return nil }
                return "\(s.short) ฿\(rate(s, f).formatted())"
            }
            let more = list.reduce(0) { $0 + $1.formats.count } - min(2, list.count)
            return shown + (more > 0 ? ["+\(more) รูปแบบ"] : [])
        case .about: return [String(about.prefix(28)) + (about.count > 28 ? "…" : "")]
        case .media:
            let f = Portfolio.shared
            return ["รูป \(f.creatorImages.count)", "ผลงาน \(f.works.count)", "คลิป \(f.videos.count)"]
        case .insight:
            let a = audience()
            let top = [("หญิง", a.female), ("ชาย", a.male), ("อื่น ๆ", a.other)].max { $0.1 < $1.1 }
            return [top.flatMap { $0.1 > 0 ? "\($0.0) \(Int($0.1))%" : nil },
                    a.ages.max { $0.share < $1.share }?.label,
                    a.places.max { $0.share < $1.share }?.name].compactMap { $0 }
        case .province: return provinces.count > 2 ? Array(provinces.prefix(2)).map(shortProvince) + ["+\(provinces.count - 2)"] : provinces.map(shortProvince)
        case .availability: return availWeek.isEmpty ? [availDays, availTime] : availSummary
        case .contact: return [lineID.isEmpty ? "" : "LINE \(lineID)", phone, website].filter { !$0.isEmpty }
        case .socials: return StarSocial.allCases.filter { connected.contains($0) }.map { "\($0.short) \(StarFlow.fmt(followers($0)))" }
        case .categories: return categories.map { $0.split(separator: " ").dropFirst().joined(separator: " ") }
        case .bank:
            let last = String(bankInfo.no.filter(\.isNumber).suffix(4))
            return [payKind == "company" ? "นามบริษัท" : "นามบุคคล", bankInfo.bank, last.isEmpty ? "" : "···" + last].filter { !$0.isEmpty }
        case .draftRounds: return ["แก้ \(draftRounds) รอบ"]
        case .address: return [[addressInfo.sub, addressInfo.zip].filter { !$0.isEmpty }.joined(separator: " ")].filter { !$0.isEmpty }
        case .limits:
            let l = limits.map { $0.replacingOccurrences(of: "ไม่รับงาน", with: "").trimmingCharacters(in: .whitespaces) }
                + (limitOther.isEmpty ? [] : [limitOther])
            return l == ["ไม่มีข้อจำกัด"] ? ["รับได้หมด"] : l.count > 2 ? Array(l.prefix(2)) + ["+\(l.count - 2)"] : l
        case .religion: return [religion.isEmpty ? "ไม่ระบุ" : religion]
        }
    }
    private func shortProvince(_ p: String) -> String { p == "กรุงเทพมหานคร" ? "กรุงเทพฯ" : p.replacingOccurrences(of: " (ออนไลน์)", with: "") }

    /// ราคาแนะนำจากยอดผู้ติดตาม (= `suggestPrice` ของเว็บ)
    func suggestedRate(_ s: StarSocial, _ f: StarFormat) -> Int {
        StarFlow.suggest(followers(s), f)
    }
    static func suggest(_ followers: Int, _ f: StarFormat) -> Int {
        max(500, Int((Double(followers) / 1000 * 120 * f.multiplier / 100).rounded()) * 100)
    }
    func rate(_ s: StarSocial, _ f: StarFormat) -> Int { rates["\(s.rawValue)_\(f.rawValue)"] ?? suggestedRate(s, f) }
    func setRate(_ s: StarSocial, _ f: StarFormat, _ v: Int) { rates["\(s.rawValue)_\(f.rawValue)"] = v }

    static func fmt(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fK", Double(n) / 1_000).replacingOccurrences(of: ".0K", with: "K") }
        return String(n)
    }

    // MARK: แผง lab — ขั้นทั้งหมดของ happy case + กติกาติ๊กข้อมูล (= `STAGES`/`DATA_RULES` ของเว็บ)

    struct Stage: Identifiable {
        let id: Int
        let title: String
        /// หน้าแทรกของ flow ใหม่ (ป้าย "แทรก" สีแดงในแผง) · false = หน้าเดิมของ Unbox
        var inserted = false
        let phase: CampaignPhase
        var order: OrderPhase = .preparing
        var reviewed = false
        var draftApproved = false
        /// หน้าที่ต้องเปิดเมื่อกระโดดมาขั้นนี้
        var screen: FlowScreen? = nil
        var dialog: FlowDialog? = nil
        /// หน้าเดิมที่ยังไม่ได้จำลองในแอป — บอกผ่าน toast
        var note: String? = nil
    }

    /// ขั้นทั้ง 15 ของ happy case (= `STAGES` ของ unbox-mock/newflow.js + ช่วงส่งลิงก์ 1 ต.ค. 2569) — ลำดับเดียว กดเพื่อกระโดด · id = ลำดับในอาร์เรย์
    static let stages: [Stage] = [
        Stage(id: 0, title: "เห็นงาน · หน้ากิจกรรม", phase: .register),
        Stage(id: 1, title: "แทรก: ข้อมูลของคุณ (ก่อนสมัคร)", inserted: true, phase: .register, screen: .wizard(.apply)),
        Stage(id: 2, title: "แทรก: การ์ดเกิด (โชว์ครั้งแรกครั้งเดียว)", inserted: true, phase: .register, screen: .reveal),
        Stage(id: 3, title: "ฟอร์มสมัครเดิม (ไม่แก้)", phase: .register, screen: .register),
        Stage(id: 4, title: "ลงทะเบียนสำเร็จ · dialog เดิม", phase: .registered, dialog: .registerSuccess),
        Stage(id: 5, title: "แบรนด์คัดคน · รอผล", phase: .registered),
        Stage(id: 6, title: "ได้รับเลือก · ปุ่มตอบรับ (เดิม)", phase: .waitingAcceptQuota),
        Stage(id: 7, title: "กดตอบรับ → แทรก: ข้อมูลก่อนตอบรับ", inserted: true, phase: .waitingAcceptQuota, screen: .wizard(.accept)),
        Stage(id: 8, title: "หน้าตอบรับเดิม (ที่อยู่เติมให้)", phase: .waitingAcceptQuota, screen: .accept),
        Stage(id: 9, title: "ตอบรับแล้ว · รอของ", phase: .acceptedQuota, order: .shipping),
        Stage(id: 10, title: "ของถึง · สร้างดราฟต์ (เดิม)", phase: .acceptedQuota, order: .delivered, note: "หน้าสร้างดราฟต์ = หน้าเดิมของแอปหลัก ยังไม่ได้จำลอง"),
        Stage(id: 11, title: "ส่งดราฟต์ · รอตรวจ (เดิม)", phase: .acceptedQuota, order: .delivered, note: "หน้าดราฟต์รอตรวจ = หน้าเดิมของแอปหลัก ยังไม่ได้จำลอง"),
        Stage(id: 12, title: "ดราฟต์ผ่าน · ปุ่มส่งลิงก์ (เดิม)", phase: .acceptedQuota, order: .delivered, draftApproved: true),
        Stage(id: 13, title: "หน้าส่งลิงก์เดิม", phase: .acceptedQuota, order: .delivered, draftApproved: true, screen: .link),
        Stage(id: 14, title: "ส่งลิงก์แล้ว · จบ (หน้ากิจกรรมเดิม)", phase: .acceptedQuota, order: .delivered, reviewed: true, draftApproved: true),
    ]

    /// ข้อมูลไหนถูกถามที่ขั้นไหน และต้องมีตั้งแต่ขั้นไหน (= `DATA_RULES`)
    struct Rule { let key: StarDataKey?; let askAt: Int; let needFrom: Int }
    static let rules: [Rule] = [
        Rule(key: .kind, askAt: 1, needFrom: 2), Rule(key: .socials, askAt: 1, needFrom: 2), Rule(key: .categories, askAt: 1, needFrom: 2), Rule(key: .about, askAt: 2, needFrom: 99),
        Rule(key: .media, askAt: 1, needFrom: 2),
        Rule(key: nil, askAt: 1, needFrom: 2), Rule(key: .rate, askAt: 1, needFrom: 2), Rule(key: .insight, askAt: 1, needFrom: 99), Rule(key: .province, askAt: 1, needFrom: 2), Rule(key: .availability, askAt: 1, needFrom: 2), Rule(key: .contact, askAt: 1, needFrom: 2),
        Rule(key: .address, askAt: 7, needFrom: 8), Rule(key: .draftRounds, askAt: 7, needFrom: 8),
        // ถามที่ Star Profile เท่านั้น — ไม่มีขั้นไหนของ Unbox ต้องใช้
        // (บัญชีรับเงิน: ฟอร์มรับเงินของแอปหลักเก็บเอง ไม่แทรกถามตอนตอบรับ/ส่งลิงก์แล้ว — ผู้ใช้ 1 ต.ค. 2569)
        Rule(key: .bank, askAt: StarFlow.profileOnly, needFrom: 99),
        Rule(key: .limits, askAt: StarFlow.profileOnly, needFrom: 99), Rule(key: .religion, askAt: StarFlow.profileOnly, needFrom: 99),
    ]
    /// `askAt` ของข้อที่ไม่มีใน flow Unbox (แผง lab เขียน "ถามที่ Star Profile")
    static let profileOnly = 99
    /// ข้อที่อยู่ใน Star Profile เท่านั้น ไม่ถามและไม่ชวนเติมใน flow Unbox (ผู้ใช้ 29 ก.ย. 2569)
    static let profileOnlyKeys: Set<StarDataKey?> = [.limits, .religion]
    static func rule(for key: StarDataKey?) -> Rule? { rules.first { $0.key == key } }

    /// ขั้นปัจจุบัน (อนุมานจาก state + หน้าที่เปิดอยู่)
    func stageIndex(screen: FlowScreen?, dialog: FlowDialog?) -> Int {
        if reviewed { return 14 }
        if case .link = screen { return 13 }
        if phase == .acceptedQuota { return draftApproved ? 12 : order == .delivered ? 10 : 9 }
        if case .accept = screen { return 8 }
        if case .wizard(.accept) = screen { return 7 }
        if phase == .waitingAcceptQuota { return 6 }
        if phase == .registered { return dialog == .registerSuccess ? 4 : 5 }
        if case .register = screen { return 3 }
        if case .reveal = screen { return 2 }
        if case .wizard = screen { return 1 }
        return 0
    }

    /// กระโดดไปขั้น `i` — ขั้นก่อนหน้าติ๊กข้อมูลให้เอง · คืนหน้า/dialog ที่ต้องเปิด
    func goto(_ i: Int) -> (FlowScreen?, FlowDialog?) {
        let st = StarFlow.stages[i]
        var h: Set<StarDataKey> = []
        var v: VerifyStatus = .none
        for r in StarFlow.rules where i >= r.needFrom {
            if let k = r.key { h.insert(k) } else { v = .approved }
        }
        have = h; verify = v
        phase = st.phase; order = st.order; reviewed = st.reviewed; draftApproved = st.draftApproved
        consent = i >= 3
        labSample()
        if i == 2 { revealSeen = false }
        return (st.screen, st.dialog)
    }

    /// ติ๊กข้อมูลเข้า/ออกจากแผง — ติ๊กออกตอนอยู่ขั้นที่ต้องมีแล้ว = ย้อน state กลับไปขั้นที่ขอข้อมูลนั้น
    /// คืนขั้นที่ย้อนกลับไป (nil = ไม่ต้องย้อน)
    func tick(_ key: StarDataKey?, on: Bool, stage: Int) -> Int? {
        if let key { if on { have.insert(key) } else { have.remove(key) } }
        else { verify = on ? .approved : .none }
        guard !on, let r = StarFlow.rule(for: key), stage >= r.needFrom else { return nil }
        return r.askAt
    }

    // MARK: ฉากสำเร็จรูป (= `NEW_PRESETS`/`PRESETS` ของเว็บ) — ตั้ง state ทั้งชุดในคลิกเดียว

    struct Preset: Identifiable {
        let id: String
        let title: String
        let have: Set<StarDataKey>
        let verify: VerifyStatus
        var phase: CampaignPhase = .register
        var order: OrderPhase = .preparing
        var reviewed = false
        var draftApproved = false
    }

    static let cardKeys: Set<StarDataKey> = [.kind, .socials, .categories, .about, .media]
    static let mediaKeys: Set<StarDataKey> = [.media]
    static let applyKeys: Set<StarDataKey> = cardKeys.union(mediaKeys).union([.rate, .insight, .province, .availability, .contact])
    static let allKeys: Set<StarDataKey> = Set(StarDataKey.allCases)

    static let presets: [Preset] = [
        Preset(id: "new", title: "ผู้ใช้ใหม่ · ยังไม่มีอะไรเลย", have: [], verify: .none),
        Preset(id: "card", title: "มีการ์ดแล้ว · ยังไม่ยืนยันตัวตน", have: cardKeys, verify: .none),
        Preset(id: "cardWait", title: "มีการ์ด · KYC รอทีมงานตรวจ", have: cardKeys, verify: .waiting),
        Preset(id: "apply", title: "STAR พร้อมสมัคร (ครบที่แบรนด์ถาม)", have: applyKeys, verify: .approved),
        Preset(id: "full", title: "ครบทุกอย่าง \(StarRow.all.count)/\(StarRow.all.count)", have: allKeys, verify: .approved),
        Preset(id: "registered", title: "สมัครแล้ว · รอผล (การ์ดยังขาด)", have: cardKeys.union(mediaKeys).union([.rate, .province, .availability, .contact]), verify: .waiting, phase: .registered),
        Preset(id: "selected", title: "ได้รับเลือก · รอตอบรับ (ยังไม่มีที่อยู่/รอบแก้งาน)", have: applyKeys, verify: .approved, phase: .waitingAcceptQuota),
        Preset(id: "working", title: "ตอบรับแล้ว · ของกำลังส่ง", have: allKeys.subtracting([.bank]), verify: .approved, phase: .acceptedQuota, order: .shipping),
        Preset(id: "linkTime", title: "ดราฟต์ผ่าน · รอส่งลิงก์", have: allKeys.subtracting([.bank]), verify: .approved, phase: .acceptedQuota, order: .delivered, draftApproved: true),
        Preset(id: "done", title: "ส่งรีวิวแล้ว · เสร็จสิ้น", have: allKeys, verify: .approved, phase: .acceptedQuota, order: .delivered, reviewed: true, draftApproved: true),
    ]

    func apply(_ p: Preset) {
        have = p.have; verify = p.verify; phase = p.phase; order = p.order; reviewed = p.reviewed; draftApproved = p.draftApproved
        consent = p.phase != .register
        labSample()
        doneOpen = false
    }

    /// ติ๊กข้อมูลให้ครบทุกช่อง (ไม่แตะสถานะงาน)
    func fillAll() {
        have = StarFlow.allKeys
        if verify == .none { verify = .approved }
        labSample()
    }

    /// ค่าตัวอย่างสำหรับ **แผง lab เท่านั้น** — กระโดดขั้นแล้วหัวข้อที่ติ๊กว่า "มี" ต้องมีค่าให้การ์ดวาด
    /// flow จริงไม่เรียกตัวนี้: ผู้ใช้กรอกเองทุกช่อง (1 ต.ค. 2569)
    private func labSample() {
        if has(.socials) && connected.isEmpty {
            connected = [.instagram, .tiktok, .youtube]
            links = ["instagram": "https://instagram.com/mae.review", "tiktok": "https://tiktok.com/@mae.review", "youtube": "https://youtube.com/@maereview"]
            followerCounts = ["instagram": 24_800, "tiktok": 86_200, "youtube": 12_400]
            followerSources = ["instagram": "connect", "tiktok": "connect", "youtube": "api"]
        }
        if has(.categories) && categories.isEmpty { categories = ["👗 แฟชั่น", "☕️ คาเฟ่", "✈️ ท่องเที่ยว"] }
        if has(.about) && about.isEmpty { about = "ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่ร้านคาเฟ่น่ารักๆ" }
        if has(.province) && provinces.isEmpty { provinces = ["กรุงเทพมหานคร"] }
        if has(.availability) && availDays.isEmpty { availWeek = Dictionary(uniqueKeysWithValues: IntakeCatalog.weekShort.map { ($0, StarFlow.daySlots) }) }
        if has(.contact) && phone.isEmpty { phone = "0891234567"; if lineID.isEmpty { lineID = "@maneerat.review" } }
        if has(.insight) && insightValues.isEmpty {
            insightSlots = ["instagram_gender", "instagram_age", "instagram_location"]
            insightValues = ["instagram_gender": [.init(label: "หญิง", pct: 68), .init(label: "ชาย", pct: 30), .init(label: "อื่น ๆ", pct: 2)],
                             "instagram_age": [.init(label: "18–24 ปี", pct: 31), .init(label: "25–34 ปี", pct: 42), .init(label: "35–44 ปี", pct: 17)],
                             "instagram_location": [.init(label: "กรุงเทพ", pct: 35), .init(label: "เชียงใหม่", pct: 9), .init(label: "ชลบุรี", pct: 7)]]
        }
        if has(.address) && addressInfo.address.isEmpty { addressInfo = StarAddress(name: "Tarmjaipa", tel: "0891234567", address: "99/12 คอนโดลุมพินี ซ.สุขุมวิท 77", zip: "10250", sub: "สวนหลวง") }
        if has(.bank) && bankInfo.no.isEmpty { bankInfo = StarBank(bank: "กสิกรไทย", no: "1234567890", name: "Tarmjaipa") }
        if has(.limits) { sampleProfileOnly() }
    }

    // MARK: กรอกตัวอย่างให้ (ทดสอบ flow) — เปิดจากแผง lab · เปิดอยู่ = wizard เปิดมาช่องว่างมีค่าแล้ว กดถัดไปได้เลย
    // ไม่ติ๊ก `have` ให้ — ยังต้องกดผ่านทุกหน้าเหมือนผู้ใช้จริง แค่ไม่ต้องพิมพ์ (ผู้ใช้ 2 ต.ค. 2569)

    static var autofill: Bool {
        get { UserDefaults.standard.object(forKey: "starflow.autofill") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "starflow.autofill") }
    }

    /// เติมค่าตัวอย่างให้ช่องที่ยังว่างของขั้นที่ wizard จะถาม
    @MainActor
    func autofill(_ steps: [WizStep]) {
        guard StarFlow.autofill else { return }
        for s in steps {
            switch s {
            case .socials, .rate, .insight:
                // ช่องที่เชื่อมไว้แล้วแต่ยอด/ลิงก์ว่าง (state เก่า) ก็เติมด้วย
                let pick = connected.isEmpty ? [.instagram, .tiktok, .youtube] : StarSocial.allCases.filter { connected.contains($0) }
                for c in pick where followers(c) == 0 || link(c).isEmpty {
                    links[c.rawValue] = c.mockLink
                    followerCounts[c.rawValue] = c.mockFollowers
                    followerSources[c.rawValue] = c.fetch
                    for f in c.formats { setRate(c, f, StarFlow.suggest(c.mockFollowers, f)) }
                }
                if connected.isEmpty { connected = Set(pick) }
                for c in connected where c.supportsInsight {
                    for (k, v) in StarFlow.sampleInsight where insightValues["\(c.rawValue)_\(k)"] == nil {
                        insightValues["\(c.rawValue)_\(k)"] = v
                        insightSlots.insert("\(c.rawValue)_\(k)")
                    }
                }
            case .categories:
                if categories.isEmpty { categories = ["👗 แฟชั่น", "☕️ คาเฟ่", "✈️ ท่องเที่ยว"] }
            case .about, .media:
                if about.isEmpty { about = "ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่ร้านคาเฟ่น่ารักๆ" }
                if s == .media { Task { await Portfolio.shared.fillSample() } }
            case .province:
                if provinces.isEmpty { provinces = ["กรุงเทพมหานคร", "นนทบุรี"] }
            case .availability:
                if availWeek.isEmpty { availWeek = ["จ": ["เย็น"], "อ": ["เย็น"], "พ": ["เย็น"], "พฤ": ["เย็น"], "ศ": ["เย็น"], "ส": StarFlow.daySlots, "อา": StarFlow.daySlots] }
            case .contact:
                if lineID.isEmpty { lineID = "@maneerat.review" }
                if phone.isEmpty { phone = "0891234567" }
            case .address:
                if addressInfo.address.isEmpty { addressInfo = StarAddress(name: "มณีรัตน์ ใจดี", tel: "0891234567", address: "99/12 คอนโดลุมพินี ซ.สุขุมวิท 77", zip: "10250", sub: "สวนหลวง") }
            case .bank:
                if bankInfo.no.isEmpty { bankInfo = StarBank(bank: "กสิกรไทย", no: "1234567890", name: "มณีรัตน์ ใจดี") }
            case .limits:
                if limits.isEmpty && limitOther.isEmpty { limits = ["ไม่มีข้อจำกัด"] }
            case .religion:
                if religion.isEmpty { religion = "พุทธ" }
            case .kind, .kyc, .draftRounds, .intro: break
            }
        }
        if lineID.isEmpty { lineID = "@maneerat.review" }
    }

    static let sampleInsight: [String: [InsightSeg]] = [
        "gender": [.init(label: "หญิง", pct: 68), .init(label: "ชาย", pct: 30), .init(label: "อื่น ๆ", pct: 2)],
        "age": [.init(label: "18–24 ปี", pct: 31), .init(label: "25–34 ปี", pct: 42), .init(label: "35–44 ปี", pct: 17)],
        "location": [.init(label: "กรุงเทพ", pct: 35), .init(label: "เชียงใหม่", pct: 9), .init(label: "ชลบุรี", pct: 7)],
    ]

    /// ค่าตัวอย่างของข้อที่ถามแค่ใน Star Profile — ติ๊กจากแผง lab แล้วแถวไม่ว่าง
    private func sampleProfileOnly() {
        if limits.isEmpty && limitOther.isEmpty { limits = ["ไม่มีข้อจำกัด"] }
        if religion.isEmpty { religion = "พุทธ" }
    }

    func reset() {
        have = []; verify = .none; phase = .register; order = .preparing; reviewed = false; draftApproved = false
        connected = []; revealSeen = false; consent = false; doneOpen = false
        rates = [:]; insightSlots = []; limits = []; limitOther = ""; religion = ""; lineID = ""; phone = ""; website = ""
        links = [:]; followerCounts = [:]; followerSources = [:]
        about = ""; categories = []; provinces = []; availDays = ""; availTime = ""; availWeek = [:]
        insightValues = [:]; addressInfo = StarAddress(); bankInfo = StarBank(); verifiedAt = nil
    }

    // MARK: จำลงเครื่อง

    private struct Snap: Codable {
        var have: Set<StarDataKey>; var verify: VerifyStatus; var phase: CampaignPhase; var order: OrderPhase
        var reviewed: Bool; var connected: Set<StarSocial>; var revealSeen: Bool; var consent: Bool
        var about: String; var categories: [String]; var provinces: [String]; var availDays: String; var availTime: String
        var draftRounds: Int; var rates: [String: Int]; var insightSlots: Set<String>
        // เพิ่ม 29 ก.ย. — optional ให้ state ที่จำไว้ก่อนหน้ายังอ่านได้
        var limits: [String]?; var limitOther: String?; var religion: String?; var lineID: String?
        var links: [String: String]?; var followerCounts: [String: Int]?; var followerSources: [String: String]?
        var verifiedAt: Date?
        var insightValues: [String: [InsightSeg]]?; var addressInfo: StarAddress?; var bankInfo: StarBank?
        // เพิ่ม 1 ต.ค. — state เก่าไม่มีค่านี้: งานที่ส่งลิงก์แล้วนับว่าดราฟต์ผ่านแล้ว
        var draftApproved: Bool?
        // เพิ่ม 2 ต.ค. — ขั้นช่องทางติดต่อ
        var phone: String?; var website: String?; var availWeek: [String: [String]]?
    }
    private static let storeKey = "starflow.v1"
    private var loading = true

    private init() {
        if let d = UserDefaults.standard.data(forKey: StarFlow.storeKey), let s = try? JSONDecoder().decode(Snap.self, from: d) {
            // "รอทีมงานตรวจ" ไม่มีแล้ว — ยืนยันตัวตนเสร็จ = ผ่านทันที · ค่าที่ค้างจากรุ่นก่อนนับเป็นผ่าน
            have = s.have; verify = s.verify == .waiting ? .approved : s.verify
            phase = s.phase; order = s.order; reviewed = s.reviewed; draftApproved = s.draftApproved ?? s.reviewed
            connected = s.connected; revealSeen = s.revealSeen; consent = s.consent
            about = s.about; categories = s.categories; provinces = s.provinces; availDays = s.availDays; availTime = s.availTime
            draftRounds = s.draftRounds; rates = s.rates; insightSlots = s.insightSlots
            limits = s.limits ?? []; limitOther = s.limitOther ?? ""; religion = s.religion ?? ""; lineID = s.lineID ?? ""; phone = s.phone ?? ""; website = s.website ?? ""
            // ค่ารุ่นก่อน (วันชุดเดียว + ช่วงเดียว) → ตารางรายวัน
            if let w = s.availWeek { availWeek = w }
            else if !s.availDays.isEmpty {
                let slots = s.availTime == "ตลอดวัน" ? StarFlow.daySlots : StarFlow.daySlots.filter { s.availTime.contains($0) }
                let ds = IntakeCatalog.days(s.availDays).map { IntakeCatalog.weekShort[($0 + 6) % 7] }
                if !slots.isEmpty { availWeek = Dictionary(uniqueKeysWithValues: ds.map { ($0, slots) }) }
            }
            links = s.links ?? [:]; followerCounts = s.followerCounts ?? [:]; followerSources = s.followerSources ?? [:]
            verifiedAt = s.verifiedAt ?? (verify == .approved ? Date() : nil)
            insightValues = s.insightValues ?? [:]; addressInfo = s.addressInfo ?? StarAddress(); bankInfo = s.bankInfo ?? StarBank()
        }
        loading = false
    }

    private func save() {
        guard !loading else { return }
        let s = Snap(have: have, verify: verify, phase: phase, order: order, reviewed: reviewed, connected: connected,
                     revealSeen: revealSeen, consent: consent, about: about, categories: categories, provinces: provinces,
                     availDays: availDays, availTime: availTime, draftRounds: draftRounds, rates: rates, insightSlots: insightSlots,
                     limits: limits, limitOther: limitOther, religion: religion, lineID: lineID,
                     links: links, followerCounts: followerCounts, followerSources: followerSources, verifiedAt: verifiedAt,
                     insightValues: insightValues, addressInfo: addressInfo, bankInfo: bankInfo, draftApproved: draftApproved,
                     phone: phone, website: website, availWeek: availWeek)
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: StarFlow.storeKey) }
        // การ์ดอ่านจาก `Profile.me` — ทุกครั้งที่ Star Profile เปลี่ยน ส่งคำตอบไปให้การ์ดทันที (ไม่มีตัว sync แยกที่ต้องจำเรียก)
        Profile.me.sync(from: self)
    }
}

/// หน้าของ flow ใหม่ที่เปิดทับแอปจำลอง (= `s.screen` ของเว็บ เฉพาะหน้าที่แทรก + หน้าเดิมที่มันพาไป)
enum FlowScreen: Equatable {
    case wizard(WizKind)
    /// การ์ดเพิ่งเกิด — "คุณเป็น STAR แล้ว" → ฟอร์มสมัคร
    case reveal
    /// ฟอร์มสมัครเดิม (flow ใหม่ตัดช่องที่อยู่ออก)
    case register
    /// หน้าตอบรับเดิม
    case accept
    /// หน้าส่งลิงก์รีวิวเดิม (`ApproveLinkPage`)
    case link
    /// Star Profile ถาวร (ปุ่ม "โปรไฟล์ครีเอเตอร์")
    case starProfile
    /// ยืนยันตัวตน (KYC จำลอง)
    case kyc
}

enum FlowDialog: Equatable {
    case registerSuccess
    case wizExit
    case acceptConfirm
    case declineConfirm
}


/// หนึ่งแท่งของข้อมูลผู้ติดตาม (ป้าย + เปอร์เซ็นต์) ที่ผู้ใช้อ่านจากหน้า Insights มากรอก
struct InsightSeg: Codable, Hashable {
    var label: String
    var pct: Double
}

/// ที่อยู่รับของ — ถามตอนตอบรับงาน
struct StarAddress: Codable, Equatable {
    var name = ""
    var tel = ""
    var address = ""
    var zip = ""
    var sub = ""
    var complete: Bool { !name.isEmpty && !tel.isEmpty && !address.isEmpty && !zip.isEmpty }
}

/// บัญชีรับเงิน — `PAYDOC` ของฟอร์มเว็บ · ถามที่ Star Profile (flow งานไม่ถาม — ฟอร์มรับเงินของแอปหลักเก็บเอง)
struct StarBank: Codable, Equatable {
    var bank = ""
    /// ธนาคารที่เลือกได้ในช่อง "ธนาคาร"
    static let banks = ["กสิกรไทย", "ไทยพาณิชย์", "กรุงเทพ", "กรุงไทย", "กรุงศรีอยุธยา", "ทหารไทยธนชาต (ttb)",
                        "ออมสิน", "ธ.ก.ส.", "ยูโอบี", "ซีไอเอ็มบี ไทย", "เกียรตินาคินภัทร", "แลนด์ แอนด์ เฮ้าส์"]
    var no = ""
    var name = ""
    var coName = ""
    var taxID = ""
    var branch = ""
    var address = ""
    var signer = ""
    var vat = ""
    var shot = false
    func complete(company: Bool) -> Bool {
        let base = !bank.isEmpty && !no.isEmpty && !name.isEmpty
        return company ? base && !coName.isEmpty && !taxID.isEmpty : base
    }
}
