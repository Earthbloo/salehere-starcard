import SwiftUI

// MARK: - Domain (โครงตาม API เดิม — ยังไม่ต่อ backend)

enum SocialType: String, CaseIterable, Identifiable {
    case instagram, tiktok, youtube, facebook
    var id: String { rawValue }

    var name: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok:    return "TikTok"
        case .youtube:   return "YouTube"
        case .facebook:  return "Facebook"
        }
    }
    /// โลโก้แบรนด์ของจริง ยกมาจาก asset ของแอปหลัก
    var icon: String {
        switch self {
        case .instagram: return SHIcon.instagram
        case .tiktok:    return SHIcon.tiktok
        case .youtube:   return SHIcon.youtube
        case .facebook:  return SHIcon.facebook
        }
    }
    var tint: Color {
        switch self {
        case .instagram: return Color(red: 0.91, green: 0.36, blue: 0.62)
        case .tiktok:    return Color(red: 0.20, green: 0.94, blue: 0.92)
        case .youtube:   return Color(red: 1.00, green: 0.32, blue: 0.30)
        case .facebook:  return Color(red: 0.36, green: 0.56, blue: 0.98)
        }
    }
}

struct SocialProfile: Identifiable {
    var id: String { type.rawValue }
    let type: SocialType
    let handle: String
    let followerCount: Int
    let avgEngagementCount: Int
    let avgViewCount: Int
    /// เวลาที่ระบบ sync ยอดล่าสุด — ตัวที่ทำให้การ์ด "ไม่มีวันเก่า"
    let syncedAgo: String
}

struct RateItem: Identifiable {
    let id = UUID()
    let label: String
    let price: Int
    let unit: String
    /// ราคาที่ระบบแนะนำ (`suggested*Price` ใน API เดิม)
    let suggested: Int
}

/// ประเภทคอนเทนต์ที่รับทำ — ชุดเดียวกับตัวเลือกในหน้าตั้งค่าโปรไฟล์
enum ContentFormat: String, CaseIterable, Identifiable {
    case photo, shortVideo, longVideo, seeding
    var id: String { rawValue }

    var name: String {
        switch self {
        case .photo:      return "Photo"
        case .shortVideo: return "Short Video"
        case .longVideo:  return "Long Video"
        case .seeding:    return "Seeding"
        }
    }
    var detail: String {
        switch self {
        case .photo:      return "ภาพนิ่งพร้อมแคปชั่นรีวิว"
        case .shortVideo: return "คลิปสั้นพร้อมแคปชั่น"
        case .longVideo:  return "คลิปยาวพร้อมแคปชั่น"
        case .seeding:    return "ข้อความ/รูปเพื่อแชร์รีวิว"
        }
    }
    var icon: String {
        switch self {
        case .photo:      return "photo.fill"
        case .shortVideo: return "play.rectangle.fill"
        case .longVideo:  return "video.fill"
        case .seeding:    return "arrowshape.turn.up.right.fill"
        }
    }
    /// สีประจำประเภท — ยกโทนมาจากหน้าเลือกในโปรไฟล์ ให้ผู้ใช้จำสีได้ตรงกัน
    var tint: Color {
        switch self {
        case .photo:      return Color(red: 0.58, green: 0.35, blue: 0.95)
        case .shortVideo: return Color(red: 0.93, green: 0.24, blue: 0.60)
        case .longVideo:  return Color(red: 0.16, green: 0.55, blue: 0.96)
        case .seeding:    return Color(red: 0.98, green: 0.58, blue: 0.18)
        }
    }
}

/// เวลาที่สะดวกรับงาน — เก็บเป็นดัชนี ให้ตรงกับตัวเลือกวัน/ช่วงเวลาในโปรไฟล์
struct WorkTime {
    /// 0 = อาทิตย์ … 6 = เสาร์
    let days: Set<Int>
    /// ดัชนีของ `slotNames`
    let slots: Set<Int>

    static let dayNames = ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"]
    static let slotNames = ["09.00–12.00", "12.00–14.00", "14.00–17.00", "17.00 เป็นต้นไป"]
    /// ชื่อย่อสำหรับแถบไทม์ไลน์ — ชื่อเต็มยาวเกินกว่าจะวางสี่ช่วงในแถวเดียว
    static let slotShort = ["09–12", "12–14", "14–17", "17 น.+"]

    /// สรุปวันแบบสั้น — "ทุกวัน" · "จ–ศ" · หรือจำนวนวัน
    var daySummary: String {
        if isEveryDay { return "ทุกวัน" }
        let sorted = days.sorted()
        // ต่อเนื่องกันถึงเขียนเป็นช่วงได้ ไม่งั้นบอกจำนวนวันแทน
        let continuous = sorted.count > 1 && sorted.last! - sorted.first! == sorted.count - 1
        guard continuous, let f = sorted.first, let l = sorted.last else { return "\(days.count) วัน" }
        return "\(WorkTime.dayNames[f])–\(WorkTime.dayNames[l])"
    }

    var isEveryDay: Bool { days.count == WorkTime.dayNames.count }
    var isAnyTime: Bool { slots.count == WorkTime.slotNames.count }
}

/// แบรนด์ที่เคยร่วมงาน — logo เป็น Mock URL (optional เพราะไม่ใช่ทุกแบรนด์ที่มีโลโก้ในระบบ)
struct Brand: Identifiable {
    var id: String { name }
    let name: String
    let logo: String?

    /// ตัวย่อสำหรับแบรนด์ที่ยังไม่มีโลโก้
    var monogram: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 { return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased() }
        return String(name.prefix(2)).uppercased()
    }
}

/// ผลงานหนึ่งชิ้นที่ระบบยืนยันตัวเลขให้ — ไม่ใช่รูปที่ creator เลือกมาเอง
///
/// สี่สัญญาณที่ทุก widget ชั้นหลักฐานต้องบอกให้ครบ:
/// **โพสอะไร** (`platform` + `format`) · **ตอนไหน** (`ep`) · **ของแบรนด์ไหน** (`brand`) ·
/// **ได้ผลแค่ไหน** (`views` + `engagementRate`)
/// ขาดข้อไหนไปการ์ดจะแหว่งทันที เพราะแต่ละแบบวางสี่ตัวนี้คนละที่แต่ใช้ครบเท่ากัน
struct VerifiedWork: Identifiable {
    let id = UUID()
    let brand: String
    /// รหัสตอน — ทำหน้าที่เป็นซีเรียลของผลงาน ปลอมไม่ได้เพราะระบบออกให้
    let ep: String
    let campaign: String
    /// ลงที่ไหน — แบรนด์ถามข้อนี้ก่อนถามยอดวิวเสมอ
    let platform: SocialType
    /// ฟอร์แมตของโพสต์ ("คลิปยาว" · "Reel" · "Short")
    let format: String
    let views: Int
    let engagementRate: Double
    let photo: Int
}

/// ชั้นหลักฐาน — ข้อมูลที่แพลตฟอร์มออกให้ ผู้ใช้แก้ไม่ได้
struct TrackRecord {
    let delivered: Int
    let accepted: Int
    let brandCount: Int
    let brands: [Brand]
    let avgEngagementRate: Double
    let works: [VerifiedWork]
    var completionRate: Double { accepted == 0 ? 0 : Double(delivered) / Double(accepted) }
}

struct CreatorProfile {
    let name: String
    let handle: String
    let tagline: String
    let location: String
    let about: String
    let categories: [String]
    /// หมวดหมู่ทางการของแพลตฟอร์มที่ครีเอเตอร์เลือกไว้ — ต่างจาก `categories` ที่พิมพ์เอง
    let interests: [String]
    /// ประเภทคอนเทนต์ที่ถนัด
    let formats: [ContentFormat]
    let workTime: WorkTime
    let socials: [SocialProfile]
    let rates: [RateItem]
    let track: TrackRecord
    let availability: String
}

// MARK: - Mock

enum Mock {
    static let creator = CreatorProfile(
        name: "นิรา ภัทรวดี",
        handle: "nira.beauty",
        tagline: "Beauty & Skincare Creator",
        location: "กรุงเทพฯ",
        about: "รีวิวสกินแคร์และเมคอัพแบบตรงไปตรงมา เน้นผิวแพ้ง่าย ถ่ายเองตัดเองทุกคลิป",
        categories: ["บิวตี้", "สกินแคร์", "เมคอัพ", "ผิวแพ้ง่าย"],
        interests: ["ความงามและสุขภาพ", "แฟชั่นและช้อปปิ้ง", "แม่และเด็ก", "ท่องเที่ยว"],
        formats: [.photo, .shortVideo, .seeding],
        // รับ จ–ส · เว้นช่วงพักเที่ยง — ตั้งใจไม่ให้เต็มทุกช่อง จะได้เห็นว่า widget อ่านค่าจริง
        workTime: WorkTime(days: [1, 2, 3, 4, 5, 6], slots: [0, 2, 3]),
        socials: [
            .init(type: .instagram, handle: "@nira.beauty", followerCount: 184_000,
                  avgEngagementCount: 8_600, avgViewCount: 92_000, syncedAgo: "2 ชม."),
            .init(type: .tiktok,    handle: "@nirabeauty",  followerCount: 320_500,
                  avgEngagementCount: 26_100, avgViewCount: 128_000, syncedAgo: "2 ชม."),
            .init(type: .youtube,   handle: "@niraskin",    followerCount: 41_200,
                  avgEngagementCount: 1_900, avgViewCount: 22_400, syncedAgo: "5 ชม."),
        ],
        rates: [
            .init(label: "TikTok Video",  price: 35_000, unit: "คลิป", suggested: 38_000),
            .init(label: "IG Reel",       price: 25_000, unit: "คลิป", suggested: 27_500),
            .init(label: "IG Story x3",   price: 12_000, unit: "ชุด",  suggested: 12_000),
            .init(label: "รีวิวลงบล็อก",   price: 18_000, unit: "ชิ้น", suggested: 16_000),
        ],
        track: TrackRecord(
            delivered: 24, accepted: 24, brandCount: 12,
            brands: [
                .init(name: "Sivanna Colors", logo: "https://img.salehere.co.th/p/300x0/2025/05/07/fe0pah3cmv3g.jpg"),
                .init(name: "Scotch",         logo: "https://img.salehere.co.th/p/300x0/2023/12/06/yy7womguuk9w.jpg"),
                .init(name: "BioActive+",     logo: "https://img.salehere.co.th/p/300x0/2019/12/20/oosmvnoxfb8m.jpg"),
                .init(name: "Cathy Doll",     logo: "https://cathydoll.me/cdn/shop/files/New_CD_LOGO_2018.png?v=1669460778&width=600"),
                .init(name: "Srichand",       logo: "https://srichand.co.th/wp-content/uploads/2025/12/square-big-logo.jpg"),
                .init(name: "Mistine",        logo: "https://www.mistine.co.th/pic/logo.png"),
                // อีกหกแบรนด์ที่ระบบมีชื่อแต่ยังไม่มีไฟล์โลโก้ — ตกไปใช้แผ่นโมโนแกรมของ `BrandPlate`
                // เดิมรายชื่อมีแค่ 6 ทั้งที่ `brandCount` บอก 12 แบบที่โชว์ครบทุกใบจึงโป๊ะทันที
                // (หัวข้อว่า 12 แต่นับกระเบื้องได้ 6) — ของจริงก็มีทั้งแบรนด์ที่มีโลโก้และไม่มีอยู่แล้ว
                .init(name: "Oriental Princess", logo: nil),
                .init(name: "Beauty Buffet",     logo: nil),
                .init(name: "Snail White",       logo: nil),
                .init(name: "Karmart",           logo: nil),
                .init(name: "Wuttisak",          logo: nil),
                .init(name: "4U2",               logo: nil),
            ],
            avgEngagementRate: 6.4,
            works: [
                // photo index 0/4/5 → วนรูปผลงานคนละรูป (1–3 สงวนไว้เป็นรูปโปรไฟล์)
                // ชื่อแบรนด์ต้องตรงกับรายการ `brands` เป๊ะ ๆ — widget ใช้ชื่อนี้ไปหาโลโก้มาแสดง
                .init(brand: "Sivanna Colors", ep: "EP.1335", campaign: "Ballet Dream",
                      platform: .tiktok,    format: "คลิปยาว", views: 1_240_000, engagementRate: 6.8, photo: 0),
                .init(brand: "Cathy Doll",     ep: "EP.1206", campaign: "Glow Serum Launch",
                      platform: .instagram, format: "Reel",    views: 820_000,   engagementRate: 7.4, photo: 4),
                .init(brand: "Srichand",       ep: "EP.1189", campaign: "Oil Control Challenge",
                      platform: .youtube,   format: "Short",   views: 615_000,   engagementRate: 5.9, photo: 5),
            ]
        ),
        availability: "ว่างรับงาน ก.ย. – ต.ค."
    )

    /// การ์ดเริ่มต้น — ผสมทั้ง 3 ชั้นให้เห็นความต่างตั้งแต่เปิดแอป
    /// พอร์ต 3 หน้า — ตัวตน · ผลงาน · ราคาและติดต่อ
    /// หน่วยแถว = จุด dot grid (36 แถว/หน้า) — สองหน้าแรกใช้ครบพอดี ไม่เหลือที่ว่างท้ายหน้า
    static let starterPages: [CardPage] = [
        CardPage([                                                  // 18 + 3 + 15 = 36
            WidgetInstance(.artTypeOver,  cols: 6, rows: 18),
            WidgetInstance(.typeMarquee,  cols: 6, rows: 3),
            WidgetInstance(.proofWork,    cols: 6, rows: 15),
        ]),
        CardPage([                                                  // 15 + 9 + 12 = 36
            WidgetInstance(.artDuo,       cols: 6, rows: 15),
            WidgetInstance(.artFilmstrip, cols: 6, rows: 9),
            WidgetInstance(.typeQuote,    cols: 6, rows: 12),
        ]),
        CardPage([                                                  // 9 + 6 = 15 (เหลือที่ว่างท้ายหน้า — ตั้งใจ)
            WidgetInstance(.statGiant,    cols: 6, rows: 9),
            WidgetInstance(.proofBrands,  cols: 6, rows: 6),
        ]),
    ]

    /// ตู้รางวัล — ทุก widget ที่ปลดล็อกแล้ว
    ///
    /// ตระกูล `.verified` ถูกกันออกไปอยู่ใน `lockedTeasers` ทั้งตระกูล ไม่ใช่แค่ `proofWork` ตัวเดียว
    /// เพราะทุกแบบในตระกูลนี้เล่าเรื่องเดียวกันคือ "ผลงานที่ส่งจริง" — ถ้าปล่อยแบบใดแบบหนึ่งหลุดเข้าตู้
    /// กติกา "ต้องได้มาก่อนถึงวางได้" จะรั่วทันที
    static var catalog: [CatalogEntry] {
        WidgetKind.allCases
            .filter { DebugFlags.unlockVerified || $0.family != .verified }
            .map { CatalogEntry(kind: $0) }
    }

    /// widget ที่ยังปลดล็อกไม่ได้ — หัวใจของกลไก "ต้องได้มาก่อนถึงวางได้"
    static var lockedTeasers: [CatalogEntry] {
        guard !DebugFlags.unlockVerified else { return [] }
        return WidgetKind.allCases
            .filter { $0.family == .verified }
            .map { CatalogEntry(kind: $0, unlocked: false, requirement: "ส่งงานผ่านระบบ 3 ชิ้น") }
    }
}

// MARK: - Debug

/// สวิตช์สำหรับตอนพัฒนาเท่านั้น — ไม่ได้แก้กติกาโปรดักต์
///
/// เปิดแล้ว widget ชั้นหลักฐานจะกดเพิ่มจากตู้ได้ทันที เพื่อให้ดู/เทียบหน้าตาทั้งตระกูลได้
/// โดยไม่ต้องมีข้อมูลงานจริง 3 ชิ้น · ของจริงยังต้องส่งงานก่อนเสมอ
/// สวิตช์ในหน้าตู้ถูกครอบ `#if DEBUG` ไว้ จึงไม่มีทางโผล่ในบิลด์ที่ปล่อยจริง
enum DebugFlags {
    static let unlockVerifiedKey = "debug.unlockVerifiedWidgets"

    static var unlockVerified: Bool {
        get { UserDefaults.standard.bool(forKey: unlockVerifiedKey) }
        set { UserDefaults.standard.set(newValue, forKey: unlockVerifiedKey) }
    }
}

// MARK: - Format

enum Fmt {
    /// ย่อตัวเลข — ตัดทศนิยมทิ้งเมื่อเลขหน้าถึงหลักร้อย ("184K" ไม่ใช่ "184.0K")
    static func compact(_ n: Int) -> String {
        func trim(_ v: Double, _ suffix: String) -> String {
            v >= 100 ? "\(Int(v.rounded()))\(suffix)" : String(format: "%.1f%@", v, suffix)
        }
        switch n {
        case 1_000_000...: return trim(Double(n) / 1_000_000, "M")
        case 1_000...:     return trim(Double(n) / 1_000, "K")
        default:           return "\(n)"
        }
    }

    static func baht(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
