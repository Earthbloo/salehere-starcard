import SwiftUI

// MARK: - Domain (โครงตาม API เดิม — ยังไม่ต่อ backend)
//
// # กติกาของไฟล์นี้หลังรอบขยาย
//
// โมเดลชุดนี้ถูกขยายให้ครอบสเปกข้อมูล 5 หมวดที่แบรนด์ใช้ตัดสินใจจ้างจริง
// (ตัวตน · สถิติ/ผู้ชม · คลังผลงาน · ความน่าเชื่อถือ/ยอดขาย · ราคา/การรับงาน)
//
// กติกาข้อเดียวที่คุมทั้งไฟล์: **ฟิลด์ต้องผูกกับ "คำถามที่แบรนด์ถาม" ไม่ใช่ "ช่องที่กรอกได้"**
// ฟิลด์ไหนที่ครีเอเตอร์กรอกเองแล้วเสียน้ำหนักทันที (engagement · ยอดขาย · เวลาตอบกลับ · รีวิว)
// ถูกทำเครื่องหมายไว้ว่าต้องมาจากระบบเท่านั้น — วันต่อ backend ห้ามเปิดเป็นฟอร์มให้พิมพ์

enum SocialType: String, CaseIterable, Identifiable, Codable {
    // สองตัวท้ายมาจากฟอร์มสมัคร — ไม่มี API ให้ดึงยอด (ดู `SocialType.fetch` ใน `Intake.swift`)
    case instagram, tiktok, youtube, facebook, lemon8, x
    var id: String { rawValue }

    var name: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok:    return "TikTok"
        case .youtube:   return "YouTube"
        case .facebook:  return "Facebook"
        case .lemon8:    return "Lemon8"
        case .x:         return "X (Twitter)"
        }
    }
    /// โลโก้แบรนด์ของจริง ยกมาจาก asset ของแอปหลัก
    var icon: String {
        switch self {
        case .instagram: return SHIcon.instagram
        case .tiktok:    return SHIcon.tiktok
        case .youtube:   return SHIcon.youtube
        case .facebook:  return SHIcon.facebook
        case .lemon8:    return SHIcon.lemon8
        case .x:         return SHIcon.x
        }
    }
    var tint: Color {
        switch self {
        case .instagram: return Color(red: 0.91, green: 0.36, blue: 0.62)
        case .tiktok:    return Color(red: 0.20, green: 0.94, blue: 0.92)
        case .youtube:   return Color(red: 1.00, green: 0.32, blue: 0.30)
        case .facebook:  return Color(red: 0.36, green: 0.56, blue: 0.98)
        case .lemon8:    return Color(red: 1.00, green: 0.84, blue: 0.25)
        case .x:         return Color(red: 0.85, green: 0.85, blue: 0.88)
        }
    }
}

/// ตัวแปลงสตริงลิงก์ให้เป็น `URL` ที่เปิดได้จริง
///
/// ข้อมูลลิงก์ในระบบเขียนกันมาสองแบบ — เต็ม (`https://…`) กับย่อ (`tiktok.com/@x/7412`)
/// แบบย่อสร้าง `URL` ได้ก็จริงแต่ไม่มี scheme พอส่งให้ `openURL` แล้วเงียบ ไม่มีอะไรเกิดขึ้น
/// จุดเดียวที่เติม scheme ให้ทั้งแอปจึงอยู่ที่นี่ ไม่ใช่กระจายอยู่ตาม widget
enum Web {
    static func url(_ raw: String) -> URL? {
        let s = raw.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return nil }
        return URL(string: s.contains("://") ? s : "https://\(s)")
    }
}

extension SocialType {
    /// หน้าโปรไฟล์ที่เดาได้จาก handle — ตัวสำรองเมื่อยังไม่ได้เก็บลิงก์เต็มไว้
    func profileURL(handle: String) -> URL? {
        let h = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
        guard !h.isEmpty else { return nil }
        switch self {
        case .instagram: return Web.url("www.instagram.com/\(h)/")
        case .tiktok:    return Web.url("www.tiktok.com/@\(h)")
        case .youtube:   return Web.url("www.youtube.com/@\(h)")
        case .facebook:  return Web.url("www.facebook.com/\(h)")
        case .lemon8:    return Web.url("www.lemon8-app.com/@\(h)")
        case .x:         return Web.url("x.com/\(h)")
        }
    }
}

/// ค่าเฉลี่ยต่อคลิปแบบแยกชนิด — สเปก 2.2 Engagement Metrics Breakdown
///
/// **ต้องมาจาก OAuth เท่านั้น** ถ้าเปิดให้กรอกมือ ตัวเลขชุดนี้จะกลายเป็นคำโฆษณา
/// แล้วลากความน่าเชื่อของทั้งการ์ดลงไปด้วย (ความเสี่ยงข้อ 4 ในเอกสารคอนเซปต์)
struct EngageMix {
    let likes: Int
    let comments: Int
    let shares: Int
    /// ยอดบันทึก — ตัวที่สัมพันธ์กับ intent ซื้อมากที่สุดในสายบิวตี้/ไลฟ์สไตล์
    let saves: Int
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
    /// สเปก 2.2 — ค่าเฉลี่ยย่อยต่อคลิป
    let mix: EngageMix
    /// สเปก 2.2 Post Frequency — คลิปต่อสัปดาห์
    let postsPerWeek: Double
    /// สเปก 2.2 Average Engagement Rate รายช่อง
    let engagementRate: Double
    /// สเปก 2.1 — ลิงก์ตรงไปหน้าโปรไฟล์ของช่องนั้น
    /// ว่างได้ · ว่างเมื่อไหร่จะประกอบจาก handle ให้แทน ดีกว่ากดแล้วไม่มีอะไรเกิดขึ้น
    var profileUrl: String = ""
    /// ยอดนี้มาจากไหน — ของ mock คือเชื่อมบัญชีแล้วทั้งหมด · ของจากฟอร์มอาจเป็น "กรอกเอง"
    /// widget ที่โชว์ค่ารอง (วิว · ER) ต้องเช็คก่อน เพราะช่องที่กรอกเองไม่มีค่าพวกนั้นจริง
    var source: FollowerSource = .connected

    /// ปลายทางที่ widget เอาไปผูกกับพื้นที่กด
    var profileURL: URL? { Web.url(profileUrl) ?? type.profileURL(handle: handle) }
}

struct RateItem: Identifiable {
    /// คงที่ต่อ "ช่องในตาราง" (แพลตฟอร์ม×รูปแบบ) — ไม่ใช่ UUID สุ่ม
    /// เพราะรายการถูกประกอบใหม่ทุกครั้งที่โปรไฟล์เปลี่ยน ถ้า id เปลี่ยนตาม `ForEach` จะสร้างแถวใหม่ทุกคีย์ที่พิมพ์
    var id: String { platform.rawValue + "." + (key.isEmpty ? format.rawValue : key) }
    let label: String
    /// ราคาที่ครีเอเตอร์ตั้งเอง
    let price: Int
    let unit: String
    let format: ContentFormat
    /// ช่องที่งานชิ้นนี้ลง — ใช้หายอดผู้ติดตามที่ถูกต้องมาคิดราคาตลาด
    /// (ราคา IG Reel ต้องคิดจากยอด IG ไม่ใช่ยอดรวมทุกช่อง)
    let platform: SocialType
    /// คีย์รูปแบบตามแพลตฟอร์ม (จากฟอร์ม) — ว่าง = รายการตัวอย่างที่ยังใช้รูปแบบกลาง
    var key: String = ""
}

// MARK: - เรตตลาด

/// คิด "ราคาที่ตลาดจ่าย" จากยอดผู้ติดตามและยอดวิวจริง
///
/// # ทำไมต้องคำนวณ ไม่ใช่ให้กรอก
///
/// `suggested*Price` ที่ API เดิมมีอยู่ ไม่มีใครรู้ว่าคำนวณจากอะไร — เอกสารคอนเซปต์
/// ระบุว่าต้อง audit ก่อนเปิดสู่สาธารณะ ตัวนี้เป็นสูตรที่ **เปิดให้ตรวจได้** แทน
///
/// # สูตร
///
/// ```
/// ฐาน  = max(ยอดผู้ติดตาม × เรตต่อคน, ยอดวิวเฉลี่ย × เรตต่อวิว)
/// ราคา = max(ค่าแรงขั้นต่ำ, ฐาน × ตัวคูณชนิดงาน × ตัวคูณคุณภาพผู้ชม)
/// ```
///
/// **ทำไมต้องมีสองฐาน** — ช่องส่วนใหญ่คนดู ≈ คนตาม ยอดฟอลจึงใช้แทน reach ได้
/// แต่ช่องที่คลิปวิ่งเกินฐานแฟน (earth.and.fairway: 115 ฟอล / 47.7K วิว) ฟอลจะโกหก
/// จนราคาที่คำนวณได้ต่ำกว่าราคาที่แบรนด์จ่ายจริงเป็นร้อยเท่า
///
/// **เรตต่อคนลดลงเมื่อช่องใหญ่ขึ้น** ซึ่งเป็นพฤติกรรมจริงของตลาด —
/// นาโนคิดหัวละแพงเพราะเข้าถึงลึก ส่วนเมกะคิดหัวละถูกเพราะขายปริมาณ
/// ถ้าใช้เรตเดียวตลอด ช่องล้านฟอลจะได้ราคาที่ไม่มีแบรนด์ไหนจ่าย
///
/// ตัวเลขทั้งชุดอยู่ในที่เดียว — วันที่ตลาดขยับ แก้ตารางนี้ตารางเดียวจบ
enum Pricing {
    /// เรตต่อผู้ติดตามหนึ่งคน (บาท) สำหรับคลิปสั้นหนึ่งชิ้น
    static func perFollower(_ n: Int) -> Double {
        switch n {
        case ..<10_000:   return 0.35   // นาโน — เข้าถึงลึก คิดหัวละแพงสุด
        case ..<50_000:   return 0.25   // ไมโคร
        case ..<100_000:  return 0.18
        case ..<500_000:  return 0.13   // แมโคร
        default:          return 0.10   // เมกะ — ขายปริมาณ คิดหัวละถูกสุด
        }
    }

    /// ตัวคูณตามชนิดงาน — เทียบกับคลิปสั้น = 1.0
    /// อ้างอิงจากแรงที่ใช้ผลิตกับอายุของคอนเทนต์ ไม่ใช่จากยอดวิว
    static func factor(_ f: ContentFormat) -> Double {
        switch f {
        case .shortVideo: return 1.0
        case .longVideo:  return 1.8    // ถ่ายนาน ตัดนาน แต่อยู่ในฟีดได้นานกว่า
        case .photo:      return 0.6
        case .seeding:    return 0.35   // สตอรี่/แชร์ — หายไปใน 24 ชม.
        }
    }

    /// ตัวคูณคุณภาพผู้ชม — ฐานตลาดอยู่ที่ ER 4%
    /// ช่องที่คนดูมีส่วนร่วมสูงกว่าฐานควรได้ราคาสูงกว่า เพราะแบรนด์ได้ผลจริงมากกว่าที่ยอดฟอลบอก
    static func quality(_ er: Double) -> Double {
        min(1.35, max(0.85, 1 + (er - 4.0) / 20))
    }

    /// เรตต่อ "วิว" หนึ่งครั้ง (บาท) — เส้นทางที่สองของราคา
    ///
    /// เพิ่มเข้ามาเพราะโปรไฟล์แบบ earth.and.fairway ทำให้สูตรเดิมพัง:
    /// 115 ผู้ติดตาม แต่ 47.7K วิวใน 30 วัน (≈414× ต่อคนตาม) — คิดจากยอดฟอลอย่างเดียว
    /// ได้ราคา ฿40 ซึ่งปัดลงเป็น ฿0 บนการ์ด ทั้งที่แบรนด์จ่ายจริงหลักพัน
    ///
    /// ตลาดจ่ายค่า **สายตา** ไม่ใช่ค่าจำนวนคนกดตาม ยอดฟอลเป็นแค่ตัวแทนของสายตาที่ใช้ได้
    /// ตอนที่คนดู ≈ คนตาม พอ reach ฉีกจากฟอลเมื่อไหร่ ต้องคิดจาก reach ตรง ๆ
    static func perView(_ n: Int) -> Double {
        switch n {
        case ..<50_000:    return 0.28   // ช่องเล็กที่วิวพุ่ง — คนดูตั้งใจดู คิดต่อวิวแพงสุด
        case ..<200_000:   return 0.20
        case ..<1_000_000: return 0.14
        default:           return 0.10
        }
    }

    /// ค่าแรงผลิตขั้นต่ำต่อชิ้น — พื้นที่ราคาชนไม่ผ่าน
    ///
    /// ต่อให้ช่องเล็กแค่ไหน ไม่มีใครถ่าย–ตัด–ส่งงานหนึ่งชิ้นต่ำกว่าค่าแรงตัวเอง
    /// ถ้าไม่มีเส้นนี้ การ์ดของครีเอเตอร์ที่เพิ่งเริ่มจะขึ้น "ตลาดจ่าย ฿500" ซึ่งไม่ใช่ราคาที่มีอยู่จริง
    static func floorPrice(_ f: ContentFormat) -> Int {
        Int((3_000 * factor(f) / 500).rounded()) * 500
    }

    /// ราคาที่ตลาดจ่าย — ปัดเป็นหลักห้าร้อย เพราะไม่มีใครเสนอราคาเป็นหลักหน่วย
    ///
    /// คิดสองทางแล้วเอาทางที่สูงกว่า: ทางยอดฟอล (ช่องปกติ) กับทาง reach (ช่องที่วิวฉีกจากฟอล)
    static func suggested(followers: Int, views: Int, format: ContentFormat, er: Double) -> Int {
        let byFollower = Double(followers) * perFollower(followers)
        let byView     = Double(views) * perView(views)
        let raw = max(byFollower, byView) * factor(format) * quality(er)
        return max(floorPrice(format), Int((raw / 500).rounded()) * 500)
    }
}

/// สเปก 5.1 — แพ็กเกจจ้างงานหนึ่งชุด
///
/// ต่างจาก `RateItem` ตรงที่อันนั้นคือ "ราคาต่อชิ้น" ส่วนอันนี้คือ "ดีลที่ปิดได้ทั้งก้อน"
/// แบรนด์ที่เปิดการ์ดมาแล้วเห็นแพ็กเกจ ไม่ต้องบวกเลขเอง — เป็นจุดที่ตัดรอบเมลออกได้จริง
struct RatePackage: Identifiable {
    var id: String { name }
    let name: String
    let price: Int
    /// Deliverable Checklist — สิ่งที่จะได้รับ
    let deliverables: [String]
    /// Turnaround Time (วัน)
    let turnaroundDays: Int
    /// Free Revisions Limit
    let freeRevisions: Int
    /// แพ็กที่อยากให้เด่นในเมนู
    var featured: Bool = false
}

/// สเปก 5.2 — สิทธิ์และเงื่อนไขเพิ่มเติม
///
/// สี่บรรทัดนี้คือคำถามที่แบรนด์ต้องเมลกลับมาถามทุกครั้ง ถ้าอยู่บนการ์ดตั้งแต่แรก
/// การคุยงานจะสั้นลงหนึ่งรอบเต็ม ๆ
struct WorkTermsInfo {
    /// Ad Boosting Rate — "+30%" หรือ "฿8,000"
    let adBoost: String
    /// Commercial Rights Duration
    let commercialRights: String
    /// Exclusivity Fee & Terms
    let exclusivity: String
    /// Fast-Track Delivery Fee
    let rush: String
}

/// สเปก 5.3 — สถานะการรับงานปัจจุบัน
enum BookingState: String {
    case available, busy, fullyBooked

    var label: String {
        switch self {
        case .available:   return "ว่างรับงาน"
        case .busy:        return "คิวแน่น"
        case .fullyBooked: return "คิวเต็มแล้ว"
        }
    }
    /// สีสถานะ — คงที่ ไม่ผูกกับพาเลตต์ เพราะ "เขียว = ว่าง" เป็นภาษาสากลที่ห้ามเปลี่ยนตามธีม
    var tint: Color {
        switch self {
        case .available:   return Color(red: 0.36, green: 0.92, blue: 0.66)
        case .busy:        return Color(red: 1.00, green: 0.78, blue: 0.35)
        case .fullyBooked: return Color(red: 1.00, green: 0.45, blue: 0.50)
        }
    }
}

/// สเปก 1.3 — ช่องทางติดต่อ
///
/// สี่ฟิลด์นี้ถูกอ่านพร้อมกันเสมอ จึงเป็น "นามบัตรใบเดียว" ไม่ใช่สี่ widget
/// `role` สำคัญกว่าที่คิด — "คุยกับตัวจริงหรือผู้จัดการ" เปลี่ยนวิธีเปิดเรื่องของแบรนด์
struct ContactInfo {
    let name: String
    let role: String
    let phone: String
    let email: String
    let lineId: String
    /// Average Response Time — **ต้องคำนวณจากอินบ็อกซ์จริง** ไม่ใช่ให้กรอก
    let responseTime: String
}

/// สเปก 2.3 — ประชากรผู้ติดตาม
struct AudienceInsight {
    /// Gender Ratio (หญิง · ชาย · อื่น ๆ) รวมกันได้ 100
    let female: Double
    let male: Double
    let other: Double
    /// Age Distribution — เรียงตามอายุเสมอ ไม่เรียงตามขนาด เพราะลำดับอายุคือข้อมูลในตัวมันเอง
    let ages: [AgeBand]
    /// Top Locations พร้อมสัดส่วน
    let places: [PlaceShare]
    /// การเข้าถึงของช่วงเวลาเดียวกัน — ฐานที่ทำให้เปอร์เซ็นต์ข้างบนมีน้ำหนัก
    /// (**mock** — รอ OAuth Insights จริง)
    var reach: Reach = .none

    struct Reach {
        let platform: SocialType
        /// ช่วงเวลาที่นับ เช่น "30 วัน"
        let window: String
        /// Accounts Reached
        let accounts: Int
        /// เทียบช่วงก่อนหน้า (%)
        let delta: Double
        /// สัดส่วนคนที่ยังไม่ได้ติดตาม — "คนใหม่" ที่แบรนด์อยากได้
        let newShare: Double

        static let none = Reach(platform: .instagram, window: "", accounts: 0, delta: 0, newShare: 0)
    }

    struct AgeBand: Identifiable {
        var id: String { label }
        let label: String
        let share: Double
    }
    struct PlaceShare: Identifiable {
        var id: String { name }
        let name: String
        let share: Double
    }
}

/// สเปก 4.2 — ผลงานสร้างยอดขาย
///
/// **หมวดที่คู่แข่งลอกไม่ได้** — Modash/Heepsy เห็นแค่ข้อมูลสาธารณะ
/// ไม่มีวันรู้ว่าโค้ดถูกใช้จริงกี่ครั้งหรือปิดการขายไปเท่าไหร่
struct SalesRecord {
    /// โค้ดส่วนลดประจำตัว
    let code: String
    /// Promo Code Redemptions
    let redemptions: Int
    /// Outbound Link Clicks
    let clicks: Int
    /// Sales Generated Volume (บาท)
    let volume: Int
    /// Top Converting Category
    let topCategory: String
    /// จำนวนแคมเปญที่ข้อมูลชุดนี้มาจาก
    let campaigns: Int
}

/// สเปก 4.3 — คำรีวิวจากผู้ว่าจ้าง
///
/// `workRef` คือสิ่งที่ทำให้รีวิวนี้ต่างจากคำโปรยในเว็บทั่วไป — มันชี้กลับไปยังงานจริงในระบบได้
/// รีวิวที่อ้างอิงงานไม่ได้ ห้ามขึ้นการ์ด
struct ClientReview: Identifiable {
    var id: String { workRef }
    let reviewer: String
    let role: String
    let brand: String
    /// 1.0–5.0
    let rating: Double
    let text: String
    /// Reference Work ID — ตรงกับ `VerifiedWork.ep`
    let workRef: String
}

/// ประเภทคอนเทนต์ที่รับทำ — ชุดเดียวกับตัวเลือกในหน้าตั้งค่าโปรไฟล์
enum ContentFormat: String, CaseIterable, Identifiable, Codable {
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
    /// สเปก 4.1 Brand Industry Tag — เพิ่มเป็นฟิลด์ ไม่ใช่ widget แยก
    var industry: String = "Beauty"
    /// โลโก้จาก asset ในแอป (แคมเปญ mock) — ใช้เมื่อไม่มี `logo` URL
    var asset: String? = nil

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
    /// สเปก 3.1 Direct Post URL — ลิงก์ตรงไปยังโพสต์จริง
    var postUrl: String = ""
    /// สเปก 3.2 Deep-dive Performance
    var saves: Int = 0
    var shares: Int = 0
    /// ยอดไลก์/คอมเมนต์ของโพสต์นั้น — คู่กับแชร์คือสามตัวที่คนอ่านการ์ดคุ้นจากใต้โพสต์
    var likes: Int = 0
    var comments: Int = 0
    /// สเปก 3.2 Viral Tag — nil เมื่อยังไม่ถึงเกณฑ์
    var viralTag: String? = nil
    /// รูปปกจาก asset ในแอป (รูปปกแคมเปญ) — ใช้แทน `photo` เมื่อมี
    var cover: String? = nil
    /// สเปก 3.2 Concept Breakdown
    var concept: String = ""

    /// ปลายทางที่ widget เอาไปผูกกับพื้นที่กด — nil เมื่อผลงานชิ้นนั้นยังไม่มีลิงก์
    var postURL: URL? { Web.url(postUrl) }
}

/// ชั้นหลักฐาน — ข้อมูลที่แพลตฟอร์มออกให้ ผู้ใช้แก้ไม่ได้
struct TrackRecord {
    let delivered: Int
    let accepted: Int
    let brandCount: Int
    let brands: [Brand]
    let avgEngagementRate: Double
    let works: [VerifiedWork]
    /// สเปก 4.2 — ผลลัพธ์ยอดขายรวมทุกแคมเปญ
    let sales: SalesRecord
    /// สเปก 4.3 — คำรีวิวจากผู้ว่าจ้าง
    let reviews: [ClientReview]

    var completionRate: Double { accepted == 0 ? 0 : Double(delivered) / Double(accepted) }
    /// คะแนนเฉลี่ยจากรีวิวทั้งหมด
    var avgRating: Double {
        guard !reviews.isEmpty else { return 0 }
        return reviews.reduce(0) { $0 + $1.rating } / Double(reviews.count)
    }
}

struct CreatorProfile {
    let name: String
    let handle: String
    let tagline: String
    let location: String
    let about: String
    /// สเปก 1.1 Verified Status — เป็น "ตราที่ติดมากับชื่อ" ไม่ใช่ widget แยก
    /// ตราที่ผู้ใช้เลือกวางเองได้ อ่านออกมาเป็นตราที่จัดฉากได้
    let verified: Bool
    let categories: [String]
    /// หมวดหมู่ทางการของแพลตฟอร์มที่ครีเอเตอร์เลือกไว้ — ต่างจาก `categories` ที่พิมพ์เอง
    let interests: [String]
    /// สเปก 1.2 Content Style Tags — "เล่ายังไง" ต่างจาก `categories` ที่บอก "เรื่องอะไร"
    let styleTags: [String]
    /// ประเภทคอนเทนต์ที่ถนัด
    let formats: [ContentFormat]
    let workTime: WorkTime
    let socials: [SocialProfile]
    let rates: [RateItem]
    let packages: [RatePackage]
    let terms: WorkTermsInfo
    let contact: ContactInfo
    let audience: AudienceInsight
    let track: TrackRecord
    let availability: String
    let bookingState: BookingState

    // MARK: ค่าที่คำนวณให้ widget ใช้ร่วมกัน — ห้าม widget คำนวณเอง ไม่งั้นตัวเลขจะไม่ตรงกันข้ามใบ

    var totalFollowers: Int { socials.reduce(0) { $0 + $1.followerCount } }
    /// ยอดวิวเฉลี่ยถ่วงน้ำหนักตามขนาดช่อง — ค่าเฉลี่ยธรรมดาทำให้ช่องเล็กดึงเลขลงเกินจริง
    var avgViews: Int {
        guard totalFollowers > 0 else { return 0 }
        let sum = socials.reduce(0.0) { $0 + Double($1.avgViewCount) * Double($1.followerCount) }
        return Int(sum / Double(totalFollowers))
    }
    var postsPerWeek: Double { socials.reduce(0) { $0 + $1.postsPerWeek } }
    /// ราคาต่ำสุดในเรตการ์ด — ใช้กับ widget "เริ่มต้นที่"
    var startingPrice: Int { rates.map(\.price).min() ?? 0 }
    /// สัดส่วนผู้ติดตามรายช่อง เรียงจากมากไปน้อย
    var platformShare: [(social: SocialProfile, share: Double)] {
        let total = Double(max(1, totalFollowers))
        return socials
            .sorted { $0.followerCount > $1.followerCount }
            .map { ($0, Double($0.followerCount) / total) }
    }
    /// ค่าเฉลี่ยย่อยต่อคลิปรวมทุกช่อง
    var mix: EngageMix {
        EngageMix(likes: socials.reduce(0) { $0 + $1.mix.likes } / max(1, socials.count),
                  comments: socials.reduce(0) { $0 + $1.mix.comments } / max(1, socials.count),
                  shares: socials.reduce(0) { $0 + $1.mix.shares } / max(1, socials.count),
                  saves: socials.reduce(0) { $0 + $1.mix.saves } / max(1, socials.count))
    }
    /// ราคาที่ตลาดจ่ายสำหรับรายการนี้ — คิดจากยอดผู้ติดตามของ **ช่องที่งานชิ้นนี้ลง**
    func marketRate(for r: RateItem) -> Int {
        guard let s = socials.first(where: { $0.type == r.platform }) else { return r.price }
        return Pricing.suggested(followers: s.followerCount, views: s.avgViewCount,
                                 format: r.format, er: s.engagementRate)
    }

    /// ราคาเริ่มต้นของประเภทคอนเทนต์นั้น — nil เมื่อไม่รับทำ
    func price(for f: ContentFormat) -> Int? {
        guard formats.contains(f) else { return nil }
        return rates.filter { $0.format == f }.map(\.price).min()
    }
}

// MARK: - Mock

enum Mock {
    static let creator = CreatorProfile(
        name: "นิรา ภัทรวดี",
        handle: "nira.beauty",
        tagline: "Beauty & Skincare Creator",
        location: "กรุงเทพมหานคร",
        about: "รีวิวสกินแคร์และเมคอัพแบบตรงไปตรงมา เน้นผิวแพ้ง่าย ถ่ายเองตัดเองทุกคลิป",
        verified: true,
        // สายงานชุดเดียวกับเทมเพลต STAR CARD_1/_2 — แต่ละหมวดมีไอคอนประจำ (ดู `Pop.nicheIcon`)
        categories: ["บิวตี้", "ไลฟ์สไตล์", "ออกกำลังกาย", "คาเฟ่"],
        interests: ["ความงามและสุขภาพ", "แฟชั่นและช้อปปิ้ง", "แม่และเด็ก", "ท่องเที่ยว"],
        styleTags: ["อ้างอิงวิจัย", "รีวิวยาว 30 วัน", "How-to", "ก่อน–หลัง", "โทนใส สว่าง"],
        formats: [.photo, .shortVideo, .seeding],
        // รับ จ–ส · เว้นช่วงพักเที่ยง — ตั้งใจไม่ให้เต็มทุกช่อง จะได้เห็นว่า widget อ่านค่าจริง
        workTime: WorkTime(days: [1, 2, 3, 4, 5, 6], slots: [0, 2, 3]),
        socials: [
            .init(type: .instagram, handle: "@nira.beauty", followerCount: 184_000,
                  avgEngagementCount: 8_600, avgViewCount: 92_000, syncedAgo: "2 ชม.",
                  mix: EngageMix(likes: 6_400, comments: 480, shares: 910, saves: 2_180),
                  postsPerWeek: 1.5, engagementRate: 4.7,
                  profileUrl: "https://www.instagram.com/jenaissante/"),
            .init(type: .tiktok,    handle: "@nirabeauty",  followerCount: 320_500,
                  avgEngagementCount: 26_100, avgViewCount: 128_000, syncedAgo: "2 ชม.",
                  mix: EngageMix(likes: 18_400, comments: 1_210, shares: 3_860, saves: 6_530),
                  postsPerWeek: 2.5, engagementRate: 8.1,
                  profileUrl: "https://www.tiktok.com/@le_sserafim"),
            .init(type: .youtube,   handle: "@niraskin",    followerCount: 41_200,
                  avgEngagementCount: 1_900, avgViewCount: 22_400, syncedAgo: "5 ชม.",
                  mix: EngageMix(likes: 1_420, comments: 260, shares: 140, saves: 380),
                  postsPerWeek: 0.5, engagementRate: 4.6,
                  profileUrl: "https://www.youtube.com/@happyhittergolf"),
        ],
        rates: [
            .init(label: "TikTok Video", price: 35_000, unit: "คลิป", format: .shortVideo, platform: .tiktok),
            .init(label: "IG Reel",      price: 25_000, unit: "คลิป", format: .shortVideo, platform: .instagram),
            .init(label: "IG Story x3",  price: 12_000, unit: "ชุด",  format: .seeding,    platform: .instagram),
            .init(label: "รีวิวลงบล็อก",   price: 18_000, unit: "ชิ้น", format: .photo,      platform: .instagram),
        ],
        packages: [
            .init(name: "Launch Set",
                  price: 58_000,
                  deliverables: ["TikTok Video ×1", "IG Reel ×1", "IG Story ×3"],
                  turnaroundDays: 7, freeRevisions: 2, featured: true),
            .init(name: "Single Clip",
                  price: 35_000,
                  deliverables: ["TikTok Video ×1", "แคปชั่นพร้อมโพสต์"],
                  turnaroundDays: 5, freeRevisions: 1),
            .init(name: "Long Review",
                  price: 92_000,
                  deliverables: ["รีวิวยาว 30 วัน", "คลิปสรุป ×2", "อัลบั้มก่อน–หลัง"],
                  turnaroundDays: 35, freeRevisions: 2),
        ],
        terms: WorkTermsInfo(
            adBoost: "+30%",
            commercialRights: "6 เดือน",
            exclusivity: "฿15,000 / 3 เดือน",
            rush: "+20% (ส่งใน 3 วัน)"
        ),
        contact: ContactInfo(
            name: "นิรา ภัทรวดี",
            role: "ติดต่อโดยตรง · ไม่ผ่านผู้จัดการ",
            phone: "081-234-5678",
            email: "nira@beautyworks.co",
            lineId: "@nirabeauty",
            responseTime: "ภายใน 3 ชม."
        ),
        audience: AudienceInsight(
            female: 78, male: 20, other: 2,
            ages: [
                .init(label: "18–24", share: 27),
                .init(label: "25–34", share: 41),
                .init(label: "35–44", share: 22),
                .init(label: "45+",   share: 10),
            ],
            places: [
                .init(name: "กรุงเทพฯ",  share: 34),
                .init(name: "ชลบุรี",    share: 9),
                .init(name: "เชียงใหม่", share: 7),
                .init(name: "ขอนแก่น",   share: 5),
            ],
            reach: .init(platform: .instagram, window: "30 วัน",
                         accounts: 184_200, delta: 14.4, newShare: 93.4)
        ),
        track: TrackRecord(
            delivered: 24, accepted: 24, brandCount: 6,
            brands: [
                .init(name: "Sivanna Colors", logo: "https://img.salehere.co.th/p/300x0/2025/05/07/fe0pah3cmv3g.jpg", industry: "Cosmetics"),
                .init(name: "Scotch",         logo: "https://img.salehere.co.th/p/300x0/2023/12/06/yy7womguuk9w.jpg", industry: "Supplement"),
                .init(name: "BioActive+",     logo: "https://img.salehere.co.th/p/300x0/2019/12/20/oosmvnoxfb8m.jpg", industry: "Supplement"),
                .init(name: "Cathy Doll",     logo: "https://cathydoll.me/cdn/shop/files/New_CD_LOGO_2018.png?v=1669460778&width=600", industry: "Skincare"),
                .init(name: "Srichand",       logo: "https://srichand.co.th/wp-content/uploads/2025/12/square-big-logo.jpg", industry: "Cosmetics"),
                .init(name: "Mistine",        logo: "https://www.mistine.co.th/pic/logo.png", industry: "Cosmetics"),
            ],
            avgEngagementRate: 6.4,
            works: [
                // photo index 0/4/5 → วนรูปผลงานคนละรูป (1–3 สงวนไว้เป็นรูปโปรไฟล์)
                // ชื่อแบรนด์ต้องตรงกับรายการ `brands` เป๊ะ ๆ — widget ใช้ชื่อนี้ไปหาโลโก้มาแสดง
                .init(brand: "Sivanna Colors", ep: "EP.1335", campaign: "Ballet Dream",
                      platform: .tiktok,    format: "คลิปยาว", views: 1_240_000, engagementRate: 6.8, photo: 0,
                      postUrl: "https://salehere.co.th/review/374da1f0df0a4adab668431cc5f4206a",
                      saves: 42_600, shares: 18_900, likes: 84_200, comments: 1_930, viralTag: "1M+ Views",
                      concept: "เปิดด้วยผิวจริงวันแพ้ ไม่รีทัช แล้วค่อยเข้าสินค้าในวินาทีที่ 8"),
                .init(brand: "Cathy Doll",     ep: "EP.1206", campaign: "Glow Serum Launch",
                      platform: .instagram, format: "Reel",    views: 820_000,   engagementRate: 7.4, photo: 4,
                      postUrl: "https://salehere.co.th/review/374da1f0df0a4adab668431cc5f4206a",
                      saves: 31_200, shares: 9_400, likes: 52_600, comments: 1_240, viralTag: "High Conversion",
                      concept: "ถ่ายก่อน–หลัง 14 วันในแสงเดียวกันทุกเฟรม ตัดสลับให้เห็นผลในคลิปเดียว"),
                .init(brand: "Srichand",       ep: "EP.1189", campaign: "Oil Control Challenge",
                      platform: .youtube,   format: "Short",   views: 615_000,   engagementRate: 5.9, photo: 5,
                      postUrl: "https://salehere.co.th/review/374da1f0df0a4adab668431cc5f4206a",
                      saves: 18_700, shares: 6_100, likes: 31_800, comments: 760, viralTag: nil,
                      concept: "ทดสอบคุมมันกลางแดด 8 ชม. ถ่ายทุกชั่วโมงด้วยกล้องตัวเดิม"),
                // สองชิ้นนี้เติมเข้ามาให้ครบห้า — ใบที่วางผลงานเป็น "กอง" (กำแพงโพลารอยด์ ·
                // ชั้นวาง · ซีน) ออกแบบผังไว้ห้าช่อง สามชิ้นทำให้เห็นแค่ครึ่งผัง
                .init(brand: "Mistine",        ep: "EP.1142", campaign: "Sunscreen Everyday",
                      platform: .tiktok,    format: "คลิปสั้น", views: 486_000,   engagementRate: 6.2, photo: 6,
                      postUrl: "https://salehere.co.th/review/374da1f0df0a4adab668431cc5f4206a",
                      saves: 14_300, shares: 5_400, likes: 27_900, comments: 640, viralTag: nil,
                      concept: "ทากันแดดซ้ำระหว่างวันจริงในออฟฟิศ ไม่จัดฉาก ถ่ายด้วยมือถือ"),
                .init(brand: "Scotch",         ep: "EP.1098", campaign: "Collagen 30 Days",
                      platform: .instagram, format: "Reel",    views: 352_000,   engagementRate: 8.1, photo: 7,
                      postUrl: "https://salehere.co.th/review/374da1f0df0a4adab668431cc5f4206a",
                      saves: 21_500, shares: 4_200, likes: 24_100, comments: 1_080, viralTag: "High Save Rate",
                      concept: "ไดอารี่ 30 วัน ถ่ายหน้าเปล่าเวลาเดิมทุกเช้า ตัดรวมเป็นคลิปเดียว"),
            ],
            sales: SalesRecord(
                code: "NIRA10",
                redemptions: 1_842,
                clicks: 24_600,
                volume: 2_140_000,
                topCategory: "เซรั่มบำรุงผิวหน้า",
                campaigns: 8
            ),
            reviews: [
                .init(reviewer: "แคทรียา ส.", role: "Brand Manager", brand: "Cathy Doll",
                      rating: 5.0,
                      text: "ส่งงานก่อนเดดไลน์ทุกชิ้น สคริปต์เข้าใจสินค้าจริงไม่ต้องแก้เลย คลิปเดียวทำยอดพรีออเดอร์หมดล็อตใน 2 วัน",
                      workRef: "EP.1206"),
                .init(reviewer: "ธนวัฒน์ ก.", role: "Marketing Lead", brand: "Sivanna Colors",
                      rating: 5.0,
                      text: "กล้าพูดข้อเสียสินค้าตรง ๆ ซึ่งกลับทำให้คอมเมนต์เชื่อมากกว่าทุกคลิปที่เคยจ้างมา",
                      workRef: "EP.1335"),
                .init(reviewer: "พิมพ์ชนก ว.", role: "Founder", brand: "Srichand",
                      rating: 4.5,
                      text: "ทำการบ้านมาดีมาก ถามข้อมูลส่วนผสมละเอียดกว่าทีมเราเองอีก",
                      workRef: "EP.1189"),
            ]
        ),
        availability: "ว่างรับงาน ก.ย. – ต.ค.",
        bookingState: .available
    )

    /// การ์ดเริ่มต้น — พอร์ต 3 หน้า: ตัวตน · ขนาดและผู้ชม · ราคาและติดต่อ
    ///
    /// หน่วยพิกัด = **pt บนพื้นที่ออกแบบกว้าง 402** · `y` คือขอบบนของตัวนั้น
    /// ผังบอกแค่ `x`, `y`, `w` — **ความสูงมาจากสัดส่วนของชนิด** (ดู `WidgetKind.aspect`)
    /// จำนวนชิ้นต่อหน้าจึงถูกกำหนดด้วยความสูงที่ชิ้นเหล่านั้นกินจริง ไม่ใช่ด้วยการบีบให้พอ
    static let starterPages: [CardPage] = [
        CardPage([
            WidgetInstance(.artTypeOver,  x:  18, y:  18, w: 366),
            WidgetInstance(.typeMarquee,  x:  18, y: 426, w: 366),
            WidgetInstance(.artFilmstrip, x:  18, y: 513, w: 366),
        ]),
        CardPage([
            WidgetInstance(.proofWork, x:  18, y:  36, w: 366),
            WidgetInstance(.statGiant, x:  18, y: 387, w: 366),
        ]),
        CardPage([
            WidgetInstance(.rateTags,    x:  18, y:  18, w: 366),
            WidgetInstance(.contactCard, x:  18, y: 310, w: 366),
            WidgetInstance(.socialTiles, x:  18, y: 495, w: 366),
        ]),
    ]

    /// การ์ดเริ่มต้นแบบสตอรี่ — หน้าเดียว 540×960 (= 1080×1920 px)
    ///
    /// # ทำไม widget ขนาดเท่ากับบนพอร์ตเป๊ะ
    ///
    /// สตอรี่มีแคนวาสกว้างกว่าพอร์ต 34% (540 เทียบ 402) — และเพราะสัดส่วนของทุกชิ้นล็อก
    /// ชิ้นที่กว้างขึ้นก็ **ใหญ่ขึ้นทั้งใบ** ไม่ใช่แค่ถ่างออก ผังของสตอรี่จึงเป็นของตัวเอง:
    /// ฮีโร่คู่กับเฟรมสตอรี่แนวตั้ง แล้วไล่ตัวเลข/ราคา/ช่องทางเป็นสองคอลัมน์
    ///
    /// เรียงตามลำดับที่คนอ่านตัดสินใจ: **นี่ใคร → ทำแนวไหน → ตัวใหญ่แค่ไหน →
    /// อยู่ช่องทางไหน → ใครเคยจ้าง → เริ่มที่เท่าไหร่**
    static let storyPage = CardPage([
        WidgetInstance(.artTypeOver,    x:  18, y:  18, w: 360),
        WidgetInstance(.galleryStory,   x: 392, y:  18, w: 130),
        WidgetInstance(.typeMarquee,    x:  18, y: 425, w: 504),
        WidgetInstance(.statGiant,      x:  18, y: 534, w: 245),
        WidgetInstance(.rateTags,       x: 277, y: 534, w: 245),
        WidgetInstance(.proofBrandRail, x:  18, y: 718, w: 245),
        WidgetInstance(.socialTiles,    x: 277, y: 718, w: 245),
        WidgetInstance(.contactBar,     x:  18, y: 842, w: 504),
    ])

    /// ตู้รางวัล — ทุก widget ที่เพิ่มได้
    ///
    /// ตอนนี้ชั้นหลักฐานปลดล็อกชั่วคราว (กติกา "ส่งงาน 3 ชิ้น" ถูกพักไว้)
    /// `lockedTeasers` ยังอยู่เพื่อเอาล็อกกลับมาได้โดยไม่ต้องรื้อตู้
    static var catalog: [CatalogEntry] {
        WidgetKind.allCases.map { CatalogEntry(kind: $0) }
    }

    /// widget ที่ยังปลดล็อกไม่ได้ — ตอนนี้ว่าง เพราะพักเงื่อนไขส่งงานไว้ก่อน
    static var lockedTeasers: [CatalogEntry] { [] }
}

// MARK: - Debug

/// สวิตช์สำหรับตอนพัฒนา — ตอนนี้ชั้นหลักฐานปลดล็อกอยู่แล้ว (กติกาส่งงาน 3 ชิ้นถูกพัก)
/// เก็บคีย์ไว้เพื่อเอาล็อกกลับมาโดยไม่ต้องยัด UserDefaults ใหม่
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

    /// เงินแบบย่อ — ใช้กับตัวเลขยอดขายที่ยาวเกินกว่าจะเขียนเต็มบนแผ่นเล็ก
    static func money(_ n: Int) -> String {
        switch n {
        case 1_000_000...: return "฿" + String(format: "%.1fM", Double(n) / 1_000_000)
        case 100_000...:   return "฿" + String(format: "%.0fK", Double(n) / 1_000)
        default:           return "฿" + baht(n)
        }
    }

    /// เปอร์เซ็นต์ — ตัด ".0" ทิ้งเพื่อให้แถวตัวเลขไม่เต้น
    static func pct(_ v: Double) -> String {
        v == v.rounded() ? "\(Int(v))%" : String(format: "%.1f%%", v)
    }
}
