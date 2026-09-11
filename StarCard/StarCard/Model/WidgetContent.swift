import SwiftUI

// MARK: - สัญญาข้อมูลของแต่ละตระกูล
//
// # ปัญหาที่ไฟล์นี้แก้
//
// widget บางตัวให้เจ้าของการ์ดพิมพ์ข้อความเองได้ ซึ่งแปลว่า **ข้อความนั้นต้องเก็บใน API**
// คำถามคือเก็บที่ระดับไหน — ถ้าเก็บต่อ "แบบ" (variant) จะเจอปัญหาสามข้อทันที:
//
// 1. สลับแบบแล้วข้อมูลหาย — ผู้ใช้พิมพ์คำโปรยไว้ใน `แนะนำตัว` แล้วกด "แบบอื่น" ไปเป็น
//    `โน้ตแปะ` ถ้าสองแบบเก็บคนละที่ คำโปรยที่พิมพ์ไว้จะหายไปเงียบ ๆ
// 2. schema บานตามจำนวนแบบ — 40 แบบ = 40 ก้อนข้อมูล ทั้งที่เนื้อหาจริงมีไม่กี่ชุด
// 3. เทียบการ์ดข้ามใบไม่ได้ — แบรนด์เปิดการ์ด 30 ใบเพื่อเลือก 5 คน ถ้าการ์ด A ใช้แบบที่มี
//    สายงาน แต่การ์ด B ใช้แบบที่ไม่มี เขาเทียบสองใบนี้ไม่ได้เลย
//
// # กติกาที่ใช้แก้
//
// **เก็บต่อ "ตระกูล" ไม่ใช่ต่อ "แบบ"** — หนึ่งตระกูล = หนึ่ง payload ที่ API คืนมาชุดเดียว
//
// สัญญาข้างล่างคือ **ชุดที่ API คืนมาเสมอ** ไม่ใช่ชุดที่ทุกแบบต้องวาดครบ —
// แบบหนึ่งจะเลือกวาดแค่บางฟิลด์ก็ได้ (เช่น `ผู้ติดตามแบบชิป` โชว์แค่ยอด ไม่โชว์ ER)
// สิ่งที่ห้ามคือ **แบบในตระกูลเดียวกันอ่านคนละ payload** เพราะนั่นทำให้ต้องเก็บสองก้อน
//
// การกด "แบบอื่น" จึงเปลี่ยนแค่ *วิธีวาด* ไม่ใช่ *ข้อมูลที่ต้องดึง* —
// เป็นการเปลี่ยน renderer บน payload ก้อนเดิม ซึ่งเป็นสิ่งเดียวที่ทำให้ฟีเจอร์นี้ถูก
//
// # ทำไมไม่แตกตระกูลย่อยเพิ่ม
//
// เคยคิดจะแยก "หมวดหมู่ทางการ" ออกจาก "สายงานที่พิมพ์เอง" เป็นคนละตระกูล เพราะอ่านคนละ array
// และเคยคิดจะแตก `audience` เป็นสามตระกูล (เพศ · อายุ · เมือง) ด้วยเหตุผลเดียวกัน
//
// ทั้งสองอย่างถูกยกเลิก — มันแก้ปัญหาที่ไม่มีอยู่จริง แล้วสร้างปัญหาที่มีจริงขึ้นมาแทน:
// ตระกูลเยอะขึ้น = ตู้ยาวขึ้น · คนใช้ต้องเรียนรู้คำศัพท์เพิ่ม · endpoint เพิ่ม
// ทั้งที่ payload ก้อนเดียวรับได้อยู่แล้ว **ให้ payload กว้าง ดีกว่าให้ตระกูลเยอะ**
//
// # รูปร่างที่ API เก็บจริง
//
// ```
// StarCard
// ├─ layout                          ← ตำแหน่ง/ขนาด/พื้นผิว เก็บต่อ "ชิ้น"
// │   └─ pages[].items[] { family, variant, col, row, cols, rows, surface, border }
// └─ content                         ← เนื้อหา เก็บต่อ "ตระกูล" ทั้งการ์ดมีชุดเดียว
//     ├─ hero    { name, tagline }
//     ├─ intro   { about }
//     ├─ tags    { items[] }
//     ├─ words   { quote }
//     └─ contact { name, role, phone, email, lineId }
// ```
//
// สังเกตว่า `content` **ไม่ผูกกับจำนวน widget บนการ์ด** — วาง hero สองตัวก็ยังใช้ชื่อเดียวกัน
// ซึ่งถูกต้อง เพราะการ์ดหนึ่งใบมีเจ้าของคนเดียว การให้พิมพ์ชื่อคนละอย่างสองที่คือบั๊ก ไม่ใช่ฟีเจอร์

/// ชนิดของช่องกรอก — ตัวกำหนดคีย์บอร์ด การตรวจค่า และหน้าตาของช่องในชีตแต่ง
enum FieldKind {
    case line          // บรรทัดเดียว
    case paragraph     // ย่อหน้า
    case list          // รายการคำ (ชิป)
    case phone, email
}

/// หนึ่งช่องที่เจ้าของการ์ดพิมพ์เองได้
///
/// `key` คือคีย์ที่ API เก็บจริง — ตั้งให้ตรงกับชื่อฟิลด์ใน `CreatorProfile`
/// เพื่อให้ mapping ระหว่างแอปกับ backend เป็น 1:1 ไม่ต้องมีตารางแปลงชื่อ
struct EditableField: Identifiable {
    var id: String { key }
    let key: String
    let label: String
    let kind: FieldKind
    /// จำกัดความยาว — nil = ไม่จำกัด · ค่านี้ต้องบังคับทั้งฝั่งแอปและฝั่ง API
    let limit: Int?

    init(_ key: String, _ label: String, _ kind: FieldKind, limit: Int? = nil) {
        self.key = key
        self.label = label
        self.kind = kind
        self.limit = limit
    }
}

/// สัญญาของหนึ่งตระกูล — **ทุกแบบในตระกูลต้องใช้ฟิลด์ชุดนี้ครบเท่ากัน**
struct FamilyContract {
    /// ฟิลด์ที่เจ้าของการ์ดพิมพ์เอง — เก็บใน API ต่อตระกูล
    let editable: [EditableField]
    /// ฟิลด์ที่ระบบออกให้ — **ห้ามมีช่องกรอกเด็ดขาด**
    ///
    /// ถ้าเปิดให้กรอก ตัวเลขจะกลายเป็นคำโฆษณา แล้วลากความน่าเชื่อของทั้งการ์ดลงไปด้วย
    /// (ความเสี่ยงข้อ 4 ในเอกสารคอนเซปต์ — engagement ที่กรอกมือ = ปลอมได้ = พังทั้งคอนเซปต์)
    let system: [String]
    /// ที่มาของฟิลด์ระบบ — ใช้ตัดสินว่าต่อ backend ตัวไหนก่อน
    let source: Source

    enum Source: String {
        case none = "—"
        case profile = "โปรไฟล์ในระบบ"
        case oauth = "OAuth ของแพลตฟอร์ม"
        case campaign = "ประวัติแคมเปญในระบบ"
        case inbox = "อินบ็อกซ์ในระบบ"
    }
}

extension WidgetFamily {
    /// สัญญาข้อมูลของตระกูลนี้
    ///
    /// อ่านคู่กับคอมเมนต์บน `WidgetFamily` — ตัวนั้นบอก *กติกา* ตัวนี้บอก *ค่าจริง*
    var contract: FamilyContract {
        switch self {
        case .hero:
            // ตรายืนยันไม่ใช่ฟิลด์ที่แก้ได้ — มันคือสถานะที่ระบบออกให้ ติดมากับชื่อเสมอ
            // ชื่อเล่นเป็นช่องของตัวเอง ไม่ใช่คำแรกของชื่อ — ตัวยักษ์บน `ตัวอักษรทับภาพ`
            // ต้องตั้งได้เองโดยไม่ต้องไปแก้ชื่อจริงทั้งชื่อ
            return .init(editable: [.init("name", "ชื่อแสดงผล", .line, limit: 40),
                                    .init("nickname", "ชื่อเล่น", .line, limit: 18),
                                    .init("tagline", "สายงาน", .line, limit: 100)],
                         system: ["verified"], source: .profile)

        case .intro:
            return .init(editable: [.init("about", "แนะนำตัว", .paragraph, limit: 240),
                                    .init("tagline", "สายงาน", .line, limit: 100)],
                         system: [], source: .none)

        case .tags:
            // สอง array อยู่ใน payload เดียวกัน — `สายงาน`/`สติกเกอร์` วาดตัวที่พิมพ์เอง
            // ส่วน `หมวดหมู่ที่สนใจ` วาดตัวที่ระบบมี ทั้งสามแบบดึงก้อนเดียวกัน
            //
            // หมวดหมู่ทางการเป็น system ไม่ใช่ editable เพราะค่านี้ถูกใช้จับคู่งานจริง
            // ถ้าพิมพ์อิสระได้ ระบบจับคู่ไม่ได้
            return .init(editable: [.init("categories", "สายงานที่พิมพ์เอง", .list, limit: 8)],
                         system: ["interests"], source: .profile)

        case .words:
            return .init(editable: [.init("quote", "คำพูด", .line, limit: 120)],
                         system: [], source: .none)

        case .text:
            // **ข้อยกเว้นข้อเดียวของกติกา "เก็บต่อตระกูล"**
            //
            // ตระกูลอื่นเก็บต่อตระกูลได้เพราะฟิลด์ของมันเป็นข้อเท็จจริงของเจ้าของการ์ด —
            // ชื่อ · สายงาน · เบอร์โทร มีคำตอบเดียวต่อการ์ดหนึ่งใบเสมอ
            // แต่ "ข้อความอิสระ" ไม่ใช่ข้อเท็จจริง มันคือ *ของตกแต่งที่มีตัวอักษร*
            // วางสองก้อนบนหน้าเดียวแล้วต้องพิมพ์คนละเรื่องเป็นการใช้งานปกติ ไม่ใช่กรณีขอบ
            //
            // ค่าจึงเก็บ **ต่อชิ้น** โดยอ้างด้วย id ของ widget (ดู `Profile.notes`)
            // ซึ่งแปลว่าฝั่ง API ต้องเก็บมันไว้กับ layout ของชิ้นนั้น ไม่ใช่ในก้อน `content`
            return .init(editable: [.init("note", "ข้อความ", .paragraph, limit: 200)],
                         system: [], source: .none)

        case .contact:
            return .init(editable: [.init("contactName", "ชื่อผู้รับงาน", .line, limit: 40),
                                    .init("role", "สถานะผู้รับงาน", .line, limit: 60),
                                    .init("phone", "เบอร์โทร", .phone),
                                    .init("email", "อีเมล", .email),
                                    .init("lineId", "ไลน์ไอดี", .line, limit: 40)],
                         // เวลาตอบกลับต้องคำนวณจากอินบ็อกซ์จริง ให้กรอกเองเมื่อไหร่มันคือคำโฆษณา
                         system: ["responseTime"], source: .inbox)

        case .rate:
            // ราคาผู้ใช้ตั้งเอง แต่ "ราคาที่ตลาดจ่าย" มาจากระบบ — สองค่านี้ต้องอยู่คู่กันเสมอ
            // ถ้าโชว์แต่ราคาที่ตั้งเอง การ์ดใบนี้ก็ไม่ต่างจาก media kit ที่ทำใน Canva
            // สองรายการคู่ขนาน — ลำดับที่ i ของทั้งสองคือเรตอันเดียวกัน
            // (เก็บแยกเพราะช่องพิมพ์หนึ่งช่อง = ค่าหนึ่งค่า ไม่ใช่ทั้ง object)
            return .init(editable: [.init("rateLabels", "ชื่อรายการ", .list, limit: 24),
                                    .init("ratePrices", "ราคา", .list, limit: 7)],
                         system: ["marketRate"], source: .profile)

        case .followers:
            // แบบชิปกับการ์ดสรุปยอดวาดแค่ยอดฟอลโลว์ — ไม่ผิดสัญญา เพราะ payload เดียวกัน
            // แค่วาดไม่ครบ ซึ่งเป็นสิทธิ์ของแต่ละแบบ
            return .init(editable: [],
                         system: ["socials.followerCount", "socials.avgViewCount",
                                  "socials.engagementRate", "socials.syncedAgo"],
                         source: .oauth)

        case .audience:
            // `ประโยคเดียว` วาดครบสามชุด · อีกสามแบบวาดชุดละอย่าง — payload เดียวกันทั้งหมด
            // จึงสลับแบบได้โดยไม่ต้องดึงข้อมูลใหม่ และไม่ต้องแตกเป็นสามตระกูล
            //
            // สี่ตัวท้ายคือ **บรรทัดที่มา** ที่ทุกแบบต้องวาด (ดู `AudienceBasis`) —
            // ช่อง · ช่วงเวลา · คนดูทั้งหมด · คนดูใหม่ ตัดตัวไหนออกเปอร์เซ็นต์ที่เหลือก็ลอย
            return .init(editable: [],
                         system: ["audience.gender", "audience.ages", "audience.places",
                                  "audience.platform", "audience.window",
                                  "audience.totalViewers", "audience.newViewers"],
                         source: .oauth)

        case .brand:
            return .init(editable: [],
                         system: ["track.brands", "track.brandCount"], source: .campaign)

        case .verified:
            return .init(editable: [],
                         system: ["works.photo", "works.brand", "works.platform",
                                  "works.views", "works.saves", "works.shares",
                                  "works.viralTag"],
                         source: .campaign)

        case .photo:
            // รูปเก็บเป็น asset id ต่อ "ช่อง" ของ widget — ดูรายละเอียดที่ `PhotoStore`
            return .init(editable: [.init("photos", "รูปผลงาน", .list)],
                         system: [], source: .none)
        }
    }
}
