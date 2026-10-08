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
    /// สัดส่วน = `bodyMeasurement` ของ salehere-ios (น้ำหนัก ส่วนสูง รอบอก รอบเอว สะโพก รองเท้า) — กรอกเองใน Star Profile ไม่ถามใน flow สมัคร (ผู้ใช้ 6 ต.ค. 2569)
    case body
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
        case .media: return "เกี่ยวกับคุณ"
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
        case .body: return "สัดส่วน"
        }
    }
}

/// `UserVerifyStatus` ของแอปหลัก ตัวต่อตัว (API เดิม ไม่ต้องแก้):
/// none = ยังไม่มี record (`User.verifyStatus` nil) · waiting = `waiting_approve` · approved = `approved` · rejected = `reject`
/// NOTE port: `reject` มีจริงใน VerifyUser.graphql (`MyUserVerify.status/reason`) — เดิม prototype ไม่มี ทำให้คนที่โดนตีกลับเห็นแค่ "ยังไม่ได้ยืนยัน" ตลอด
enum VerifyStatus: String, Codable, CaseIterable {
    case none, waiting, approved, rejected
    var label: String {
        switch self {
        case .none: return "ยังไม่ได้ยืนยันตัวตน"
        case .waiting: return "รอทีมงานตรวจ"
        case .approved: return "ยืนยันตัวตนแล้ว"
        case .rejected: return "ไม่ผ่าน · ส่งใหม่ได้"
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
    /// ยอดผู้ติดตามมาจากไหน — ตาม `SocialConnectPage` ของ salehere-ios (API เดิมครบ ไม่ต้องแก้):
    /// FB = FBSDK OAuth (`facebookSocialEngagementPrice`) · IG/TikTok/X/YouTube = OAuth ของเซิร์ฟเวอร์ (`createSocialAuthorizeParams` → `socialEngagementPrice`)
    /// Lemon8 = วางลิงก์ + พิมพ์ยอดเอง (`SocialFollowerModal`) · ทุกช่องถ้า `isLoginSocialEnable == false` ตกไปวางลิงก์เหมือน Lemon8
    /// (เดิม X เป็น "manual" — แอปหลักมี OAuth ให้แล้ว เลยเปลี่ยนเป็น connect 6 ต.ค. 2569)
    var fetch: String {
        switch self {
        case .youtube: return "api"
        case .instagram, .tiktok, .facebook, .x: return "connect"
        case .lemon8: return "manual"
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
        case .body?: return "ขึ้นช่องสัดส่วนบนการ์ดสายแฟชั่น"
        }
    }

    /// = `StarProfileRow.all` ของ salehere-ios ตัวต่อตัว (7 ต.ค. 2569): 8 แถวแรก = 8 ข้อใน wizard ลำดับเดียวกัน · เรทอยู่ในแถวช่องทาง (ไม่มีแถวของตัวเอง)
    /// · ประเภทครีเอเตอร์มีแถวของตัวเอง · ยืนยันตัวตนท้ายสุด
    static let all: [StarRow] = [
        StarRow(key: .kind, icon: .user, title: "ประเภทครีเอเตอร์", why: "แบรนด์เห็นว่าคุยกับใคร"),
        StarRow(key: .socials, icon: .broadcast, title: "ช่องทางของฉัน", why: "ยอดผู้ติดตามขึ้นการ์ดอัตโนมัติ"),
        StarRow(key: .categories, icon: .sparkle, title: "สายที่ใช่", why: "งานตรงสายขึ้นหน้าแรกให้"),
        StarRow(key: .media, icon: .imageSquare, title: "เกี่ยวกับคุณ", why: "แบรนด์ดูหน้าตาและงานของคุณก่อนคัดเลือก"),
        StarRow(key: .province, icon: .mapPin, title: "พื้นที่รับงาน", why: "งานหน้าร้านใกล้คุณขึ้นก่อน"),
        StarRow(key: .availability, icon: .calendarDots, title: "วันเวลาว่างรับงาน", why: "แบรนด์ดูวันว่างของคุณตอนคัดคน"),
        StarRow(key: .contact, icon: .chatCircleText, title: "ช่องทางติดต่อ", why: "แบรนด์ทักคุณตรงนี้ · ขึ้นบนการ์ด"),
        StarRow(key: .about, icon: .textAlignLeft, title: "แนะนำตัว", why: "1 บรรทัดใต้ชื่อบนการ์ด"),
        StarRow(key: .insight, icon: .usersThree, title: "ข้อมูลผู้ติดตาม", why: "แบรนด์เห็นว่าคนดูคุณเป็นใคร"),
        StarRow(key: .bank, icon: .bank, title: "การรับเงิน", why: "ค่าตัวเข้าบัญชีทันทีเมื่องานจบ"),
        StarRow(key: .address, icon: .package, title: "ที่อยู่รับของ", why: "กรอกตอนลงทะเบียนกิจกรรม · แบรนด์ส่งของรีวิวได้เลย"),
        StarRow(key: .body, icon: .ruler, title: "สัดส่วน", why: "แบรนด์แฟชั่นดูไซซ์ก่อนส่งของ"),
        StarRow(key: nil, icon: .sealCheck, title: "ยืนยันตัวตน", why: "ต้องผ่านก่อนแบรนด์เลือกคุณ"),
    ]
}

/// ขั้นของ wizard — `intro` มีเฉพาะตอนสมัคร · `kyc` = ยืนยันตัวตน (ออกไปทำแล้วกลับมา)
enum WizStep: String, Codable, Hashable {
    case intro, kind, socials, categories, about, media, kyc, rate, insight, province, availability, contact, address, bank, draftRounds, limits, religion, body

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
    /// ข้ามได้ (ไม่บังคับ) — สัดส่วนกรอกเท่าที่สะดวก (salehere-ios ก็ไม่บังคับช่องไหน)
    var optional: Bool { self == .insight || self == .body }
    var name: String {
        switch self {
        case .socials: return "ช่องทางและเรท"
        // หน้าเดียว = แนะนำตัว + รูปโปรไฟล์ + ผลงาน + คลิป → ชื่อหัวข้อ "เกี่ยวกับคุณ" (ผู้ใช้ 7 ต.ค. 2569)
        case .media: return "เกี่ยวกับคุณ"
        default: return dataKey?.label ?? (self == .kyc ? "ยืนยันตัวตน" : "")
        }
    }
    /// ชื่อข้อ = ชื่อแถวในหน้า Star Profile = ชื่อช่องประบนการ์ดหน้า intro (`StarWizardStep.name` ของ salehere-ios) — ห้ามมีชื่อเล่นอื่น
    var rowName: String {
        switch self {
        case .kind: return "ประเภทครีเอเตอร์"
        case .socials, .rate, .insight: return "ช่องทางของฉัน"
        case .categories: return "สายที่ใช่"
        case .media, .about: return "เกี่ยวกับคุณ"
        case .province: return "พื้นที่รับงาน"
        case .availability: return "วันเวลาว่างรับงาน"
        case .contact: return "ช่องทางติดต่อ"
        case .address: return "ที่อยู่รับของ"
        case .bank: return "การรับเงิน"
        case .body: return "สัดส่วน"
        case .kyc: return "ยืนยันตัวตน"
        default: return name
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
        case .socials: return ["แบรนด์ดูข้อนี้ก่อนคัดเลือก", "ผูก 1 ช่องพอ", "ตั้งเรทได้ตอนเชื่อม"]
        // 3–5: ขั้นต่ำ 3 = กติกา welcome step "เลือกหมวดหมู่ที่คุณถนัดและสนใจ" ของ salehere-ios (เช็กฝั่ง client) · เพดาน 5 = ของเรา
        case .categories: return ["แบรนด์ใช้ตัดสินใจ", "เลือก 3–5 สาย"]
        case .about: return ["แบรนด์อ่านความเป็นตัวคุณจากบรรทัดนี้"]
        case .media: return ["แบรนด์ดูหน้าตาและงานก่อนคัดเลือก"]
        // ต้องผ่านก่อนสมัคร (ผู้ใช้ 6 ต.ค. 2569) = กติกาเดิมของแอปหลัก: welcome step 3 ติ๊กเฉพาะ `approved`
        case .kyc: return ["ต้องผ่านก่อนส่งใบสมัคร", "ทำครั้งเดียว ใช้ได้ทุกงาน"]
        case .rate: return ["แบรนด์ดูราคาก่อนคัดเลือก", "ใส่ราคามาตรฐานให้แล้ว"]
        case .insight: return ["แบรนด์ใช้คัดเลือกกลุ่มเป้าหมาย", "ทำช่องเดียวก็ได้"]
        case .province: return ["แบรนด์ใช้คัดเลือกงานหน้าร้าน", "เลือกได้ถึง 3"]
        case .availability: return ["แบรนด์ดูวันว่างตอนคัดเลือก"]
        case .contact: return ["แบรนด์ทักคุณตรงนี้", "ขึ้นบนการ์ด"]
        case .draftRounds: return ["ตกลงไว้ก่อน ไม่ต้องเถียงหน้างาน"]
        case .limits: return ["งานแนวนี้จะไม่ถูกส่งมาให้คุณ", "เลือกได้หลายข้อ"]
        case .religion: return ["กรองงานที่อาจขัดกับความเชื่อ", "ไม่ขึ้นการ์ด"]
        case .body: return ["แบรนด์แฟชั่นใช้เลือกไซซ์ของที่ส่ง", "กรอกเท่าที่สะดวก"]
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
    /// NOTE port: ไม่มี field นี้ฝั่ง server และไม่ต้องสร้าง — คำนวณจากของที่มีอยู่แล้ว:
    ///   socials = `socialProfiles` ไม่ว่าง · rate = ราคาใน `SocialProfileItem` > 0 · insight = `SocialProfileInsights.completed`
    ///   categories = `User.categories` ≥ 3 · about = `caption` ไม่ว่าง · media = `profileImages` 3 + `portfolio` ครบ
    ///   province/availability/contact = ช่องใน `UserCreatorProfile` · address = `myAddress` · bank = `CampaignPayoutProfiles` มีอย่างน้อย 1 · kind = ช่องใหม่ (ดู `creatorKind`)
    var have: Set<StarDataKey> = [] { didSet { save() } }
    var verify: VerifyStatus = .none {
        didSet {
            // วันที่ผ่าน KYC — ตราและใบรับรองบนการ์ดพิมพ์วันนี้ (เดิมเป็นค่าตายตัว "12.09.69")
            if verify == .approved { if verifiedAt == nil { verifiedAt = Date() } } else { verifiedAt = nil }
            save()
        }
    }
    var verifiedAt: Date? = nil { didSet { save() } }
    /// เหตุผลตีกลับจาก staff (= `UserVerify.reason` ข้อความอิสระ) · ว่าง = ไม่มี
    var verifyReason = "" { didSet { save() } }
    /// เวลาที่ส่งให้ทีมงานตรวจ — หน้ารอผลบอก "ส่งเมื่อ"
    var kycSentAt: Date? = nil { didSet { save() } }
    /// กิจกรรมที่ค้างสมัครเพราะติดด่านยืนยันตัวตน (ผู้ใช้ 6 ต.ค. 2569: ต้องผ่านก่อนถึงสมัครได้)
    /// ผ่านแล้ว push พากลับมาฟอร์มของใบนี้ · เก็บในเครื่อง ไม่แตะ API
    var pendingCampaign: String? = nil { didSet { save() } }
    /// Lab: ผลจำลองตอนจบหน้ากล้อง — "approved" = OCR ผ่าน อนุมัติทันที (เคสส่วนใหญ่) · "waiting" = AI อ่านไม่ผ่าน ตกไปกรอกมือ ส่งทีมงานตรวจ
    static var kycOutcome: String {
        get { UserDefaults.standard.string(forKey: "starflow.kycOutcome") ?? "approved" }
        set { UserDefaults.standard.set(newValue, forKey: "starflow.kycOutcome") }
    }
    /// เหตุผลตีกลับที่ staff ใช้บ่อย — เสนอเป็น preset ฝั่ง backend เพื่อให้แอป map เป็น hint ตอนถ่ายใหม่ได้
    static let rejectReasons = ["รูปบัตรไม่ชัด มองไม่เห็นเลขบัตรและวันหมดอายุ", "ใบหน้าไม่ตรงกับรูปบนบัตร"]
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
    /// = `caption` ("bio - บอกเล่าความเป็นตัวคุณ") บันทึกผ่าน `editProfileInfo` — API เดิม (`User.aboutMe` มีใน schema แต่แอปไม่ได้ใช้ ไม่ต้องไปแตะ)
    var about = "" { didSet { save() } }
    /// = `User.categories` (`setUserCategories`, CategoryV2) — API เดิม · NOTE port: 18 ชื่อใน `IntakeCatalog.interests` เป็นป้ายชั่วคราว ตัวจริงต้องดึงลิสต์จาก query `categories` แล้ว map id
    var categories: [String] = [] { didSet { save() } }
    var provinces: [String] = [] { didSet { save() } }
    var availDays = "" { didSet { save() } }
    /// Creator (บุคคล) / Page (เพจ) — ขั้น `type` ของฟอร์มเว็บ
    /// NOTE port (API ใหม่ 1 ช่อง — ข้อเดียวใน Star Profile ที่ salehere-ios/gateway ไม่มีที่เก็บ):
    /// เพิ่ม arg `creatorType: individual | page` ใน `createOrUpdateCreatorProfile` + ช่องเดียวใน `UserCreatorProfile`
    /// ทางเลี่ยงแบบไม่แตะ API: อนุมานจาก Facebook ที่ผูก (`profileType: page`) — แต่คนที่ไม่ผูก FB จะเป็น creator เสมอ ไม่แนะนำ
    var creatorKind = "creator" { didSet { save() } }
    /// รับเงินในนามบุคคล / นามบริษัท — `PAYDOC` ของฟอร์มเว็บ (หัก ณ ที่จ่าย 3% / 7%)
    var payKind = "person" { didSet { save() } }
    var availTime = "" { didSet { save() } }
    /// ช่วงว่างแยกรายวัน (ผู้ใช้ 2 ต.ค. 2569: "จ อ พ มันเลือกช่วงเวลาต่างกัน") — ชื่อย่อวัน → คีย์ช่วงเวลา (`daySlots`)
    /// เป็นตัวจริง · `availDays` (วันที่มีช่วง) และ `availTime` (รวมทุกช่วง) ตามมาเองให้ส่วนที่อ่านแบบเดิม
    var availWeek: [String: [String]] = [:] {
        didSet {
            availDays = IntakeCatalog.weekShort.filter { !(availWeek[$0] ?? []).isEmpty }.joined(separator: " ")
            availTime = StarFlow.slotText(Set(availWeek.values.joined()))
            save()
        }
    }
    /// ช่วงเวลาของวัน = `CreatorTimeSlots` ของ salehere-ios ตัวต่อตัว (gateway: slot_09_12 · slot_12_14 · slot_14_17 · slot_17_late)
    /// เดิมเป็น เช้า/บ่าย/เย็น — แอปหลักเป็นช่วงนาฬิกา (ผู้ใช้ 6 ต.ค. 2569) · ค่าที่เก็บ = คีย์ของ API · ป้าย = `slotLabel`
    static let daySlots = ["slot_09_12", "slot_12_14", "slot_14_17", "slot_17_late"]
    /// ชั่วโมงเริ่ม–จบของแต่ละช่วง (nil = เป็นต้นไป) — ใช้รวมช่วงติดกันเป็นช่วงเดียวตอนสรุป
    private static let slotHours: [String: (from: Int, to: Int?)] = ["slot_09_12": (9, 12), "slot_12_14": (12, 14), "slot_14_17": (14, 17), "slot_17_late": (17, nil)]
    /// ป้ายชิปของช่วง (= `displayText` ที่ gateway ส่งให้แอปหลัก ตัด "น." ให้สั้น)
    static func slotLabel(_ key: String) -> String {
        guard let h = slotHours[key] else { return key }
        return h.to.map { String(format: "%02d.00–%02d.00", h.from, $0) } ?? String(format: "%02d.00 เป็นต้นไป", h.from)
    }
    /// สรุปชุดช่วงเป็นคำเดียว: ครบ 4 = "ตลอดวัน" · ติดกันรวมเป็น "09.00–14.00" · ห่างกันคั่นด้วย " + " · ว่าง = ""
    static func slotText(_ keys: Set<String>) -> String {
        let picked = daySlots.filter(keys.contains)
        guard !picked.isEmpty else { return "" }
        guard picked.count < daySlots.count else { return "ตลอดวัน" }
        var runs: [(from: Int, to: Int?)] = []
        for k in picked {
            guard let h = slotHours[k] else { continue }
            if let last = runs.last, last.to == h.from { runs[runs.count - 1].to = h.to } else { runs.append(h) }
        }
        return runs.map { r in r.to.map { String(format: "%02d.00–%02d.00", r.from, $0) } ?? String(format: "%02d.00 เป็นต้นไป", r.from) }
            .joined(separator: " + ")
    }
    /// ค่าที่เก็บรุ่นก่อน (เช้า/บ่าย/เย็น) → คีย์ช่วงเวลาของแอปหลัก · คีย์ใหม่ผ่านตามเดิม
    static func migrateSlots(_ list: [String]) -> [String] {
        let map = ["เช้า": ["slot_09_12"], "บ่าย": ["slot_12_14", "slot_14_17"], "เย็น": ["slot_17_late"], "ตลอดวัน": daySlots]
        let keys = Set(list.flatMap { map[$0] ?? (daySlots.contains($0) ? [$0] : []) })
        return daySlots.filter(keys.contains)
    }
    /// "จ–ศ 17.00 เป็นต้นไป · ส–อา ตลอดวัน" — วันที่ช่วงเหมือนกันรวมเป็นกลุ่ม · ติดกันเขียนเป็นช่วง
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
            return "\(d) \(StarFlow.slotText(Set(g.slots)))"
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
    /// ช่องทางติดต่อ = `creatorProfile.tel / lineId / website` (API เดิม) — ส่ง `showTel/showLineId/showWebsite = true` เสมอ เพราะกติกาเรา "ขึ้นบนการ์ด"
    /// Line ID ที่กรอกตอนลงทะเบียนกิจกรรมก็ลงช่องนี้ (`createBrandCampaignApplication` ไม่มี arg lineId)
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
    /// NOTE port: = `SocialProfileInsights.gender/age/location[{label, percentage}]` (API เดิม) — ตัวอ่าน % ใช้ `analyzeSocialProfileInsight(socialType, insightType, imageUrl)` ของเซิร์ฟเวอร์
    /// Vision บนเครื่องเป็นแค่พรีวิวระหว่างอัปโหลด ไม่ใช่ตัวจริง · รองรับ FB/IG/YT/TikTok เท่ากับ `supportsInsight`
    var insightValues: [String: [InsightSeg]] = [:] { didSet { save() } }
    var addressInfo = StarAddress() { didSet { save() } }
    var bankInfo = StarBank() { didSet { save() } }
    /// สัดส่วน — กรอกเองใน Star Profile เท่านั้น (ผู้ใช้ 6 ต.ค. 2569) · ช่องและหน่วยตามหน้า "สัดส่วน" ของ salehere-ios
    var bodyInfo = StarBody() { didSet { save() } }

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

    /// รูปของคุณ · รูปผลงาน · วิดีโอ อย่างละ 1–3 (ผู้ใช้ 7 ต.ค. 2569) — เพดาน 3 อยู่ที่ `Portfolio.creatorSlots/workMax/videoMax`
    /// NOTE port: เกณฑ์โปรไฟล์ 100% เดิมของ gateway (user-creator-profile.type.js: รูป ≥3 · ผลงาน ≥2 · วิดีโอ ≥2) สูงกว่านี้ — ด่านสมัครเช็กฝั่ง client
    /// (`isStar`) จึงไม่ต้องแก้ API · salehere-ios จำกัด portfolio "ไม่เกิน 2 รูป + 2 คลิป" ฝั่ง client (`CreatorProfilePortfolioMainInteractor`) ต้องขยายเป็น 3
    static let minPhotos = 1
    static let minWorks = 1
    static let minVideos = 1

    /// การ์ดประกอบขึ้นได้เมื่อมี ประเภท + สายที่ใช่ + รูปและผลงาน — เป็นเรื่อง "มีของให้วาดการ์ด" ไม่ใช่สถานะ STAR (ดู `isStar`)
    var hasCard: Bool { have.contains(.kind) && have.contains(.categories) && have.contains(.media) }
    /// 8 ข้อที่แบรนด์ใช้คัดเลือก STAR — ลำดับเดียวกับ journey "รับของไปรีวิว" (ยืนยันตัวตนเป็นด่านสุดท้าย)
    /// ผู้ใช้ 6 ต.ค. 2569: ทุกทางเข้า (จากลิงก์/ลงทะเบียน · จากหน้า Star Profile) ต้องกรอก 8 ข้อนี้ก่อนเสมอ ครบ = เป็น STAR (motion "คุณเป็น STAR แล้ว") แล้วค่อยทำต่อ
    static let starSteps: [WizStep] = [.kind, .socials, .categories, .media, .province, .availability, .contact, .kyc]
    /// ข้อใน 8 ข้อที่ยังขาด (เรียงตามลำดับถาม) — ว่าง = เป็น STAR แล้ว
    var starMissing: [WizStep] { StarFlow.starSteps.filter(needs) }
    /// ผ่าน flow สมัครงานแล้ว (ส่งยืนยันตัวตนแล้ว) — ก่อนหน้านั้นยังไม่ใช่ STAR ข้ออื่นใน Star Profile ล็อกไว้
    var isMember: Bool { verify == .waiting || verify == .approved }   // ตีกลับ (`reject`) = ต้องส่งใหม่ นับเหมือนยังไม่ส่ง
    /// NOTE port (ไม่ต้องแก้ API): ด่าน "ครบ 100% ก่อนสมัคร" ของแอปหลักเช็กฝั่ง client ที่
    /// `ValidateRegisterSaleHereStarManagerInteractor.swift:22` (`percentTotal != 100` → เด้งไป onboarding)
    /// port = เปลี่ยนเงื่อนไขตรงนั้นเป็น `isStar` (ครบ 8 ข้อใน `starSteps`) · `profileProgress` ยังใช้โชว์ % ได้ตามเดิม
    /// ยังกรอกไม่ได้ — ก่อนเป็น STAR กรอกได้แค่ 8 ข้อที่แบรนด์ใช้คัดเลือก (ข้อที่กรอกแล้วไม่ล็อก)
    func locked(_ key: StarDataKey?) -> Bool {
        guard !isStar, !StarFlow.starSteps.contains(where: { key == nil ? $0 == .kyc : $0.keys.contains(key!) }) else { return false }
        return key.map { !has($0) } ?? true
    }
    var isVerified: Bool { verify == .approved }
    /// STAR = ครบ 8 ข้อที่แบรนด์ใช้คัดเลือก (รวมยืนยันตัวตนผ่าน) — ยังไม่ครบ = ยังไม่เป็น STAR แม้มีการ์ดแล้ว (ผู้ใช้ 6 ต.ค. 2569)
    /// มียศ STAR (`myProfile.userRank` มี `star`) — STAR เก่าที่ได้ยศจาก 3 ขั้นต้อนรับแบบเดิมเป็น STAR ต่อ แม้ 8 ข้อยังไม่ครบ (salehere-ios 7 ต.ค. 2569)
    /// ตั้งจากแผง lab เท่านั้น ("STAR เก่า") · ผู้ใช้ใหม่เป็น STAR เมื่อครบ 8 ข้อ
    var starRank = false { didSet { save() } }
    var isStar: Bool { starRank || starMissing.isEmpty }
    /// สถานะ C: เป็น STAR (มียศ) แต่ 8 ข้อยังไม่ครบ — ไม่มี % · banner "เติมข้อมูล STAR" · การ์ดทองกางพร้อมปุ่ม "เพิ่ม" · ด่านสมัครกิจกรรมบังคับกรอกก่อน
    var needsStarInfo: Bool { isStar && !starMissing.isEmpty }
    /// % ทางไปเป็น STAR = (8 − ข้อที่ขาด) ÷ 8 — banner กับหน้า Star Profile เลขเดียวกัน · โชว์เฉพาะก่อนเป็น STAR
    var starPct: Double { Double(StarFlow.starSteps.count - starMissing.count) / Double(StarFlow.starSteps.count) }
    /// เป็น STAR แล้ว (ครบ 8 ข้อ ไม่นับช่องทางที่เอาออกได้) = ข้อมูลที่กรอกแล้วลบไม่ได้ แก้ได้อย่างเดียว (ผู้ใช้ 7 ต.ค. 2569)
    /// รูป/คลิป = ปุ่ม "เปลี่ยน" แทนลบ · ช่องพิมพ์ที่เคยกรอกบันทึกเป็นค่าว่างไม่ได้ · ยกเว้นช่องทาง: เอาออกได้จนหมด
    /// → ไม่เป็น STAR จนกว่าจะเชื่อมใหม่ และลงทะเบียนงานถัดไปถามช่องทางอีกรอบ (`registerSteps`)
    var keepsData: Bool { isStar || starMissing.allSatisfy { $0 == .socials } }

    func has(_ k: StarDataKey) -> Bool { have.contains(k) }
    /// แถวช่องทาง = เชื่อมแล้ว + ตั้งเรทแล้ว (ขั้นเดียวกันใน wizard) — แถวเส้นประตรงกับ `starMissing` ทุกข้อ
    func done(_ row: StarRow) -> Bool {
        guard let key = row.key else { return isVerified }
        return key == .socials ? has(.socials) && has(.rate) : has(key)
    }

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
        // = 8 ข้อที่แบรนด์ใช้คัดเลือก (`starSteps`) — ครบแล้วค่อยไปฟอร์มสมัคร (ผู้ใช้ 6 ต.ค. 2569)
        starMissing
    }
    /// ข้อไม่บังคับ — ยังไม่กรอกก็ไม่ทำให้หน้าของมันโผล่ซ้ำ (ผู้ใช้ 1 ต.ค. 2569: "ไม่บังคับ = ไม่ถามซ้ำ") · เติมเองได้จากแถวใน Star Profile
    static let optionalKeys: Set<StarDataKey> = [.insight, .about, .body]
    /// ขั้นนี้ยังมีข้อบังคับที่ขาด (หน้าช่องทาง = ช่องทาง + เรท · หน้าผลงาน = รูปและผลงาน)
    func needs(_ s: WizStep) -> Bool {
        // ยืนยันตัวตนยังไม่ "ผ่าน" (รอตรวจ/ตีกลับด้วย) = ยังค้างเป็นด่านสุดท้ายก่อนฟอร์ม (ผู้ใช้ 6 ต.ค. 2569)
        s == .kyc ? !isVerified : s.keys.contains { !StarFlow.optionalKeys.contains($0) && !has($0) }
    }
    /// งานที่ขอผ่าน + ศาสนา อยู่ใน Star Profile เท่านั้น ไม่ถามใน flow Unbox (ผู้ใช้ 29 ก.ย. 2569)
    /// ขั้นที่ยังขาดทั้งหมดของ Star Profile — ทางเข้าจากหน้า Star Profile ("สมัครเป็น STAR · N ข้อ") พากด next จนหมดทุกข้อ
    /// รวมที่อยู่/บัญชี/รอบแก้ด้วย ปิดกลางทางได้ (ผู้ใช้ 24 ก.ย.) · ต่างจาก `registerSteps` ที่ถามแค่พอส่งใบสมัคร
    /// สัดส่วนถามต่อท้ายเฉพาะทางนี้ (ผู้ใช้ 6 ต.ค. 2569: "ถ้า journey จะมาสมัคร Star อยู่แล้วก็ให้กรอกไป แต่อันอื่นให้เข้ามากรอกเอง") — ไม่บังคับ ข้ามได้
    /// 8 ข้อก่อนเสมอ (ครบ = motion STAR กลางทาง) แล้วค่อยต่อ ที่อยู่ · บัญชี · สัดส่วน (ผู้ใช้ 6 ต.ค. 2569)
    var applySteps: [WizStep] {
        starMissing + [WizStep.address, .bank, .body].filter { $0 == .body ? !has(.body) : needs($0) }
    }
    /// ขั้นที่แทรกก่อนตอบรับ — ว่างแล้ว: ที่อยู่กรอกในฟอร์มสมัครเดิม (ผู้ใช้ 6 ต.ค. 2569) · บัญชีรับเงินฟอร์ม payout ของแอปหลักเก็บเอง (1 ต.ค.)
    /// กดตอบรับ = เข้าหน้าตอบรับเดิมทันที (`SaleHereShell` เปิด `.accept` เมื่อว่าง) · ที่อยู่ยังแก้ได้จาก Star Profile
    var acceptSteps: [WizStep] { [] }
    /// ข้อที่ขาดบนหน้าการ์ด (ไม่รวมยืนยันตัวตน ซึ่งเป็น flow แยก)
    var missingSteps: [WizStep] { missingSteps(from: nil) }
    /// ขั้นที่ยังขาดตามลำดับแถว (ยืนยันตัวตนท้ายสุด) — เริ่มจากแถวที่แตะ แล้ววนต่อให้ครบ (= `missingSteps(from:)` ของ salehere-ios)
    func missingSteps(from row: StarRow?) -> [WizStep] {
        var steps: [WizStep] = []
        for r in StarRow.all where !done(r) {
            let st = r.key.flatMap { WizStep(rawValue: $0.rawValue)?.page } ?? .kyc
            if !steps.contains(st) { steps.append(st) }
        }
        guard let row, let i = steps.firstIndex(of: row.key.flatMap { WizStep(rawValue: $0.rawValue)?.page } ?? .kyc) else { return steps }
        return Array(steps[i...] + steps[..<i])
    }
    /// "เติมข้อมูลต่อ" (หลัง STAR) = ข้อที่ขาดใน 8 ข้อก่อน แล้วข้อเสริมที่ขาด
    var fillMoreSteps: [WizStep] { starMissing + missingSteps.filter { !starMissing.contains($0) } }
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
        // ช่องที่แนบข้อมูลผู้ติดตามแล้ว "IG ✓" (= salehere-ios)
        case .insight:
            return StarSocial.allCases.filter { s in connected.contains(s) && insightValues.keys.contains { $0.hasPrefix(s.rawValue + "_") } }.map { "\($0.short) ✓" }
        case .province: return provinces.count > 2 ? Array(provinces.prefix(2)).map(shortProvince) + ["+\(provinces.count - 2)"] : provinces.map(shortProvince)
        case .availability: return availWeek.isEmpty ? [availDays, availTime] : availSummary
        case .contact: return [lineID.isEmpty ? "" : "LINE \(lineID)", phone, website].filter { !$0.isEmpty }
        // แถวช่องทางรวมเรท: ยอดผู้ติดตามต่อช่อง แล้วตามด้วยเรท (= salehere-ios)
        case .socials: return StarSocial.allCases.filter { connected.contains($0) }.map { "\($0.short) \(StarFlow.fmt(followers($0)))" }
            + (has(.rate) ? facts(StarRow(key: .rate, icon: .coins, title: "", why: "")) : [])
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
        case .body: return bodyInfo.facts
        }
    }
    private func shortProvince(_ p: String) -> String { p == "กรุงเทพมหานคร" ? "กรุงเทพฯ" : p.replacingOccurrences(of: " (ออนไลน์)", with: "") }

    // MARK: format ช่องทางติดต่อ — regex เดียวกับแอปหลัก (`validateLineId` / `validatePhoneNumber` / `isValidURL`)
    static func validLine(_ v: String) -> Bool { v.range(of: #"^@?[a-z0-9._-]{4,20}$"#, options: .regularExpression) != nil }
    static func validPhone(_ v: String) -> Bool { v.range(of: #"^(06|08|09)[0-9]{8}$"#, options: .regularExpression) != nil }
    /// เว็บไซต์ไม่มี https:// เติมให้เอง แล้วค่อยตรวจ
    static func normalizedWebsite(_ raw: String) -> String {
        let v = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !v.isEmpty else { return "" }
        return v.range(of: #"^https?://"#, options: [.regularExpression, .caseInsensitive]) == nil ? "https://" + v : v
    }
    static func validURL(_ v: String) -> Bool {
        guard let u = URL(string: v), let host = u.host, host.contains("."), !host.hasPrefix("."), !host.hasSuffix(".") else { return false }
        return true
    }
    /// เบอร์จากบัญชี/ที่อยู่ → เติมช่องเบอร์: "+66"/"66" แปลงเป็น "0" · ไม่ผ่าน format = ไม่เติม
    static func prefillPhone(_ raw: String) -> String? {
        var v = raw.filter { $0.isNumber || $0 == "+" }
        if v.hasPrefix("+66") { v = "0" + v.dropFirst(3) } else if v.hasPrefix("66") && v.count == 11 { v = "0" + v.dropFirst(2) }
        return validPhone(v) ? v : nil
    }

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
        Stage(id: 3, title: "ฟอร์มสมัครเดิม (ที่อยู่ 7 ช่องเหมือนแอปหลัก)", phase: .register, screen: .register),
        Stage(id: 4, title: "ลงทะเบียนสำเร็จ · dialog เดิม", phase: .registered, dialog: .registerSuccess),
        Stage(id: 5, title: "แบรนด์คัดคน · รอผล", phase: .registered),
        Stage(id: 6, title: "ได้รับเลือก · ปุ่มตอบรับ (เดิม)", phase: .waitingAcceptQuota),
        Stage(id: 7, title: "กดตอบรับ (ไม่แทรกอะไรแล้ว — ที่อยู่กรอกตอนสมัคร)", inserted: true, phase: .waitingAcceptQuota, screen: .wizard(.accept)),
        Stage(id: 8, title: "หน้าตอบรับเดิม (ที่อยู่จากฟอร์มสมัคร)", phase: .waitingAcceptQuota, screen: .accept),
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
        // ที่อยู่กลับไปอยู่ในฟอร์มสมัครเดิม (ขั้น 3) เหมือนแอปหลัก — ไม่แทรกตอนตอบรับแล้ว (ผู้ใช้ 6 ต.ค. 2569)
        Rule(key: .address, askAt: 3, needFrom: 4),
        // ถามที่ Star Profile เท่านั้น — ไม่มีขั้นไหนของ Unbox ต้องใช้
        // (บัญชีรับเงิน: ฟอร์มรับเงินของแอปหลักเก็บเอง ไม่แทรกถามตอนตอบรับ/ส่งลิงก์แล้ว — ผู้ใช้ 1 ต.ค. 2569)
        Rule(key: .bank, askAt: StarFlow.profileOnly, needFrom: 99),
        // สัดส่วน: ผู้ใช้เข้ามากรอกเองใน Star Profile (ผู้ใช้ 6 ต.ค. 2569)
        Rule(key: .body, askAt: StarFlow.profileOnly, needFrom: 99),
    ]
    /// `askAt` ของข้อที่ไม่มีใน flow Unbox (แผง lab เขียน "ถามที่ Star Profile")
    static let profileOnly = 99
    /// ข้อที่อยู่ใน Star Profile เท่านั้น ไม่ถามและไม่ชวนเติมใน flow Unbox (ผู้ใช้ 29 ก.ย. 2569 · สัดส่วน 6 ต.ค. 2569)
    static let profileOnlyKeys: Set<StarDataKey?> = [.limits, .religion, .body]
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
        /// ยศ STAR (STAR เก่า)
        var rank = false
    }

    static let cardKeys: Set<StarDataKey> = [.kind, .socials, .categories, .about, .media]
    static let mediaKeys: Set<StarDataKey> = [.media]
    static let applyKeys: Set<StarDataKey> = cardKeys.union(mediaKeys).union([.rate, .insight, .province, .availability, .contact])
    static let allKeys: Set<StarDataKey> = Set(StarDataKey.allCases)

    static let presets: [Preset] = [
        Preset(id: "new", title: "ผู้ใช้ใหม่ · ยังไม่มีอะไรเลย", have: [], verify: .none),
        Preset(id: "card", title: "มีการ์ดแล้ว · ยังไม่ยืนยันตัวตน", have: cardKeys, verify: .none),
        Preset(id: "cardWait", title: "มีการ์ด · KYC รอทีมงานตรวจ", have: cardKeys, verify: .waiting),
        // สถานะ C ของ salehere-ios: ได้ยศจาก 3 ขั้นต้อนรับแบบเดิม (ช่องทาง · สาย · ยืนยันตัวตน) แต่ 8 ข้อยังไม่ครบ
        Preset(id: "oldStar", title: "STAR เก่า · ข้อมูลยังไม่ครบ (สถานะ C)", have: [.socials, .rate, .categories], verify: .approved, rank: true),
        Preset(id: "apply", title: "STAR พร้อมสมัคร (ครบที่แบรนด์ถาม)", have: applyKeys, verify: .approved),
        Preset(id: "full", title: "ครบทุกอย่าง \(StarRow.all.count)/\(StarRow.all.count)", have: allKeys, verify: .approved),
        Preset(id: "registered", title: "สมัครแล้ว · รอผล (การ์ดยังขาด)", have: cardKeys.union(mediaKeys).union([.rate, .province, .availability, .contact]), verify: .waiting, phase: .registered),
        Preset(id: "selected", title: "ได้รับเลือก · รอตอบรับ (ยังไม่มีที่อยู่)", have: applyKeys, verify: .approved, phase: .waitingAcceptQuota),
        Preset(id: "working", title: "ตอบรับแล้ว · ของกำลังส่ง", have: allKeys.subtracting([.bank]), verify: .approved, phase: .acceptedQuota, order: .shipping),
        Preset(id: "linkTime", title: "ดราฟต์ผ่าน · รอส่งลิงก์", have: allKeys.subtracting([.bank]), verify: .approved, phase: .acceptedQuota, order: .delivered, draftApproved: true),
        Preset(id: "done", title: "ส่งรีวิวแล้ว · เสร็จสิ้น", have: allKeys, verify: .approved, phase: .acceptedQuota, order: .delivered, reviewed: true, draftApproved: true),
    ]

    func apply(_ p: Preset) {
        have = p.have; verify = p.verify; phase = p.phase; order = p.order; reviewed = p.reviewed; draftApproved = p.draftApproved
        starRank = p.rank
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
        if has(.address) && addressInfo.address.isEmpty { addressInfo = StarAddress(name: "Tarmjaipa", tel: "0891234567", address: "99/12 คอนโดลุมพินี ซ.สุขุมวิท 77", district: "สวนหลวง", province: "กรุงเทพมหานคร", zip: "10250", sub: "สวนหลวง") }
        if has(.bank) && bankInfo.no.isEmpty { bankInfo = StarBank(bank: "กสิกรไทย", no: "1234567890", name: "Tarmjaipa") }
        if has(.body) && !bodyInfo.filled { bodyInfo = StarBody.sample }
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
                if availWeek.isEmpty { availWeek = ["จ": ["slot_17_late"], "อ": ["slot_17_late"], "พ": ["slot_17_late"], "พฤ": ["slot_17_late"], "ศ": ["slot_17_late"], "ส": StarFlow.daySlots, "อา": StarFlow.daySlots] }
            case .contact:
                if lineID.isEmpty { lineID = "@maneerat.review" }
                if phone.isEmpty { phone = "0891234567" }
            case .address:
                if addressInfo.address.isEmpty { addressInfo = StarAddress(name: "มณีรัตน์ ใจดี", tel: "0891234567", address: "99/12 คอนโดลุมพินี ซ.สุขุมวิท 77", district: "สวนหลวง", province: "กรุงเทพมหานคร", zip: "10250", sub: "สวนหลวง") }
            case .bank:
                if bankInfo.no.isEmpty { bankInfo = StarBank(bank: "กสิกรไทย", no: "1234567890", name: "มณีรัตน์ ใจดี") }
            case .limits:
                if limits.isEmpty && limitOther.isEmpty { limits = ["ไม่มีข้อจำกัด"] }
            case .religion:
                if religion.isEmpty { religion = "พุทธ" }
            case .body:
                if !bodyInfo.filled { bodyInfo = StarBody.sample }
            case .kind, .kyc, .draftRounds, .intro: break
            }
        }
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
        verifyReason = ""; kycSentAt = nil; pendingCampaign = nil; starRank = false
        connected = []; revealSeen = false; consent = false; doneOpen = false
        rates = [:]; insightSlots = []; limits = []; limitOther = ""; religion = ""; lineID = ""; phone = ""; website = ""
        links = [:]; followerCounts = [:]; followerSources = [:]
        about = ""; categories = []; provinces = []; availDays = ""; availTime = ""; availWeek = [:]
        insightValues = [:]; addressInfo = StarAddress(); bankInfo = StarBank(); bodyInfo = StarBody(); verifiedAt = nil
        // ล้างจาก lab = ผู้ใช้ใหม่จริง ๆ — motion ได้เป็น STAR และ motion เปิด Star Card ครั้งแรกต้องเล่นใหม่
        // (เดิมล้างเฉพาะตอน isStar พลิกเป็น false — คนที่ยังไม่ยืนยันตัวตนจึงไม่เคยถูกล้าง)
        LevelUp.shared.sync(isStar: false, reduceMotion: false)
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
        // เพิ่ม 6 ต.ค. — สัดส่วน
        var bodyInfo: StarBody?
        var verifyReason: String?; var kycSentAt: Date?; var pendingCampaign: String?
        // เพิ่ม 7 ต.ค. — ยศ STAR (STAR เก่า)
        var starRank: Bool?
    }
    private static let storeKey = "starflow.v1"
    private var loading = true

    private init() {
        if let d = UserDefaults.standard.data(forKey: StarFlow.storeKey), let s = try? JSONDecoder().decode(Snap.self, from: d) {
            // 6 ต.ค. 2569: "รอตรวจ" กลับมาเป็นสถานะจริง (AI อ่านไม่ผ่าน → staff ตรวจ) — เลิกแปลง waiting → approved ตอนโหลด
            have = s.have; verify = s.verify
            phase = s.phase; order = s.order; reviewed = s.reviewed; draftApproved = s.draftApproved ?? s.reviewed
            connected = s.connected; revealSeen = s.revealSeen; consent = s.consent
            about = s.about; categories = s.categories; provinces = s.provinces; availDays = s.availDays; availTime = s.availTime
            draftRounds = s.draftRounds; rates = s.rates; insightSlots = s.insightSlots
            limits = s.limits ?? []; limitOther = s.limitOther ?? ""; religion = s.religion ?? ""; lineID = s.lineID ?? ""; phone = s.phone ?? ""; website = s.website ?? ""
            // ค่ารุ่นก่อน (วันชุดเดียว + ช่วงเดียว) → ตารางรายวัน · ช่วง เช้า/บ่าย/เย็น รุ่นก่อน → คีย์ช่วงเวลาของแอปหลัก (6 ต.ค.)
            if let w = s.availWeek {
                availWeek = w.reduce(into: [:]) { out, e in
                    let m = StarFlow.migrateSlots(e.value)
                    if !m.isEmpty { out[e.key] = m }
                }
            } else if !s.availDays.isEmpty {
                let slots = StarFlow.migrateSlots(s.availTime.split(separator: "+").map(String.init))
                let ds = IntakeCatalog.days(s.availDays).map { IntakeCatalog.weekShort[($0 + 6) % 7] }
                if !slots.isEmpty { availWeek = Dictionary(uniqueKeysWithValues: ds.map { ($0, slots) }) }
            }
            links = s.links ?? [:]; followerCounts = s.followerCounts ?? [:]; followerSources = s.followerSources ?? [:]
            verifiedAt = s.verifiedAt ?? (verify == .approved ? Date() : nil)
            insightValues = s.insightValues ?? [:]; addressInfo = s.addressInfo ?? StarAddress(); bankInfo = s.bankInfo ?? StarBank()
            bodyInfo = s.bodyInfo ?? StarBody()
            verifyReason = s.verifyReason ?? ""; kycSentAt = s.kycSentAt; pendingCampaign = s.pendingCampaign
            starRank = s.starRank ?? false
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
                     phone: phone, website: website, availWeek: availWeek, bodyInfo: bodyInfo,
                     verifyReason: verifyReason, kycSentAt: kycSentAt, pendingCampaign: pendingCampaign, starRank: starRank)
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
/// = `myAddress` / `createUserAddress` ของแอปหลัก (API เดิม ไม่ต้องแก้) — ทุกช่องบังคับฝั่ง server รวม อำเภอ+จังหวัด
/// `district`/`province` ไม่ให้พิมพ์: เติมเองจาก `getSubDistricts(zipcode)` → `getDistrictProvince(zipcode, subDistrict)` แบบเดียวกับ `UnboxAcceptingEditAddressView`
/// ตอนสมัครงาน (`createBrandCampaignApplication`) ส่งชุดนี้ซ้ำไปในช่อง address ของใบสมัครได้เลย — ดู NOTE ที่ `RegisterFormPage`
struct StarAddress: Codable, Equatable {
    var name = ""
    var tel = ""
    var address = ""
    var district = ""
    var province = ""
    var zip = ""
    var sub = ""
    var complete: Bool { !name.isEmpty && !tel.isEmpty && !address.isEmpty && !zip.isEmpty }
    /// ครบทั้ง 7 ช่องแบบที่ `createBrandCampaignApplication` / `createUserAddress` บังคับ
    var full: Bool { complete && !sub.isEmpty && !district.isEmpty && !province.isEmpty }
}

/// ตารางรหัสไปรษณีย์ย่อ (จำลอง `getSubDistricts` + `getDistrictProvince` ของ gateway) — พอให้ฟอร์มเล่นได้ ไม่ใช่ข้อมูลครบประเทศ
enum ZipBook {
    private static let book: [String: (district: String, province: String, subs: [String])] = [
        "10110": ("คลองเตย", "กรุงเทพมหานคร", ["คลองเตย", "คลองตัน", "พระโขนง"]),
        "10250": ("สวนหลวง", "กรุงเทพมหานคร", ["สวนหลวง", "อ่อนนุช"]),
        "10400": ("พญาไท", "กรุงเทพมหานคร", ["สามเสนใน", "ถนนพญาไท", "ทุ่งพญาไท"]),
        "10900": ("จตุจักร", "กรุงเทพมหานคร", ["จตุจักร", "ลาดยาว", "เสนานิคม", "จันทรเกษม", "จอมพล"]),
        "11000": ("เมืองนนทบุรี", "นนทบุรี", ["สวนใหญ่", "ตลาดขวัญ", "บางกระสอ", "ท่าทราย", "บางเขน"]),
        "50200": ("เมืองเชียงใหม่", "เชียงใหม่", ["ศรีภูมิ", "พระสิงห์", "หายยา", "ช้างม่อย", "ช้างคลาน"]),
    ]
    static func subs(_ zip: String) -> [String] { book[zip]?.subs ?? [] }
    static func place(_ zip: String, _ sub: String) -> (district: String, province: String)? {
        guard let b = book[zip], b.subs.contains(sub) else { return nil }
        return (b.district, b.province)
    }
}

/// สัดส่วน — `InputCreatorBodyMeasurement` ของ salehere-ios: น้ำหนัก (กก.) · ส่วนสูง (ซม.) · รอบอก/รอบเอว/สะโพก (นิ้ว หรือ ซม. เลือกได้ต่อช่อง) · รองเท้า (EU ครึ่งเบอร์ได้)
/// ทุกช่องไม่บังคับ · กรอกเองใน Star Profile เท่านั้น (ผู้ใช้ 6 ต.ค. 2569) · ค่าเก็บเป็นข้อความตัวเลขที่พิมพ์ ("" = ยังไม่กรอก)
struct StarBody: Codable, Equatable {
    var weight = ""
    var height = ""
    var chest = ""
    var waist = ""
    var hip = ""
    var shoe = ""
    /// หน่วยของรอบอก/รอบเอว/สะโพก — `CreatorMeasurementUnit` (inch · cm) · ค่าเริ่มต้นนิ้วเหมือนแอปหลัก
    var chestUnit = StarBody.inch
    var waistUnit = StarBody.inch
    var hipUnit = StarBody.inch
    static let inch = "นิ้ว"
    static let cm = "ซม."
    static let girthUnits = [inch, cm]

    var filled: Bool { ![weight, height, chest, waist, hip, shoe].allSatisfy(\.isEmpty) }
    /// ป้ายในแถว Star Profile: "165 ซม." · "50 กก." · "32-25-35 นิ้ว" (ถ้าหน่วยเดียวกันครบสามค่า) · "EU 38"
    var facts: [String] {
        var out: [String] = []
        if !height.isEmpty { out.append("\(height) \(StarBody.cm)") }
        if !weight.isEmpty { out.append("\(weight) กก.") }
        let girth = [(chest, chestUnit), (waist, waistUnit), (hip, hipUnit)]
        if girth.allSatisfy({ !$0.0.isEmpty }), Set(girth.map(\.1)).count == 1 {
            out.append("\(chest)-\(waist)-\(hip) \(chestUnit)")
        } else {
            for (v, u) in girth where !v.isEmpty { out.append("\(v) \(u)") }
        }
        if !shoe.isEmpty { out.append("EU \(shoe)") }
        return out
    }
    static let sample = StarBody(weight: "48", height: "165", chest: "32", waist: "25", hip: "35", shoe: "38")
}

/// บัญชีรับเงิน — `PAYDOC` ของฟอร์มเว็บ · ถามที่ Star Profile (flow งานไม่ถาม — ฟอร์มรับเงินของแอปหลักเก็บเอง)
///
/// NOTE port (API เดิม ไม่ต้องแก้): ชุดนี้ = `CampaignPayoutProfiles` / `CampaignPayoutSubmit` ของแอปหลัก ตัวต่อตัว
///   payKind person/company → `payoutType: individual | juristic` · bank → `bankName` (+`bankCode` จาก `WalletBankLists`)
///   no → `accountNumber` · name → `accountName` · shot → `bankBookCopyImage` · coName → `juristic.juristicName`
///   taxID → `juristic.juristicId` · branch → `juristic.officeType: headquarters | branch` · address → `juristic.juristicAddress` · vat → `isVat`
/// ของที่ฟอร์ม payout ถามแต่ Star Profile ไม่ถาม (ให้ฟอร์มเดิมถามตอนจ่ายจริง): สำเนาบัตร ปชช. · ที่อยู่ภาษี · ยินยอมหัก ณ ที่จ่าย · อีเมล
/// ตัด `signer` (ชื่อกรรมการ) ออก 6 ต.ค. 2569 — API ไม่มีช่อง (อ่านจาก `juristicCertificateImage` ด้วย OCR อยู่แล้ว)
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
    var vat = ""
    var shot = false
    func complete(company: Bool) -> Bool {
        let base = !bank.isEmpty && !no.isEmpty && !name.isEmpty
        return company ? base && !coName.isEmpty && !taxID.isEmpty : base
    }
}
