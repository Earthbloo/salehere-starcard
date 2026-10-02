import SwiftUI

/// กิจกรรม Sale Here STAR หนึ่งรายการ — ข้อมูลจำลองตามหน้าจอแอป Sale Here จริง (22 ก.ย. 2569)
///
/// ฝั่งแอปหลักดึงจาก `BrandCampaignDetails` (GraphQL) — ที่นี่ mock ไว้ให้ต่อ flow ใหม่ได้ก่อน
/// ไม่ผูกกับ `Profile`/`CardLibrary` เพราะเป็นของฝั่ง Sale Here ไม่ใช่ของ Star Card
/// คำถามเพิ่มของแบรนด์ในฟอร์มสมัคร (`UnboxRegister` questions)
struct CampaignQuestion: Hashable, Identifiable {
    enum Kind: Hashable { case text, radio, checkbox, upload }
    let kind: Kind
    let q: String
    var options: [String] = []
    var id: String { q }
}

struct StarCampaign: Identifiable, Hashable {
    static func == (a: StarCampaign, b: StarCampaign) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }

    let id: String
    /// เลข EP ที่แอปหลักโชว์หน้าชื่อ เช่น "EP.1585"
    let episode: String
    let title: String
    let brand: String
    /// ชื่อ asset โลโก้แบรนด์ (วงกลม)
    let logo: String
    /// ชื่อ asset รูปปก
    let cover: String
    let dateRange: String
    /// วิธีการร่วมกิจกรรม — ย่อหน้าเดียวแบบแอปหลัก
    let howTo: String
    /// เหลือเวลาลงทะเบียนอีกกี่วินาที นับจากตอนเปิดแอป · nil = หมดเวลาแล้ว
    let registerSecondsLeft: TimeInterval?

    // ข้อมูลที่ฟอร์มสมัคร / หน้าตอบรับ / flow ใหม่ใช้ (= `CAMPAIGNS[].*` ของ unbox-mock)
    var reward = ""
    var quota = 20
    var registered = 0
    var socialChannels: [StarSocial] = [.instagram]
    var contentTypes: [String] = ["Photo"]
    var timeline: [(String, String)] = []
    var questions: [CampaignQuestion] = []
    var acceptQuestions: [CampaignQuestion] = []
    /// ค่าตัว (บาท) · 0 = ได้ของอย่างเดียว
    var fee = 0

    var isOpen: Bool { registerSecondsLeft != nil }
    var headline: String { "\(episode) \(title)" }

    /// เส้นตายลงทะเบียน — ตรึงไว้ตอนโหลดข้อมูล นาฬิกาหน้ารายละเอียดนับถอยหลังจากค่านี้
    let deadline: Date?

    init(id: String, episode: String, title: String, brand: String, logo: String, cover: String,
         dateRange: String, howTo: String, registerSecondsLeft: TimeInterval?,
         reward: String = "", quota: Int = 20, registered: Int = 0,
         socialChannels: [StarSocial] = [.instagram], contentTypes: [String] = ["Photo"],
         timeline: [(String, String)] = [], questions: [CampaignQuestion] = [], acceptQuestions: [CampaignQuestion] = [],
         fee: Int = 0) {
        self.id = id; self.episode = episode; self.title = title; self.brand = brand
        self.logo = logo; self.cover = cover; self.dateRange = dateRange; self.howTo = howTo
        self.registerSecondsLeft = registerSecondsLeft
        self.deadline = registerSecondsLeft.map { Date().addingTimeInterval($0) }
        self.reward = reward; self.quota = quota; self.registered = registered
        self.socialChannels = socialChannels; self.contentTypes = contentTypes; self.timeline = timeline
        self.questions = questions; self.acceptQuestions = acceptQuestions; self.fee = fee
    }

    static let mock: [StarCampaign] = [
        StarCampaign(
            id: "1585", episode: "EP.1585",
            title: "WONDER ONE Music Festival 2027 รวมพลสายคอนเสิร์ต ท่ามกลางบรรยากาศธรรมชาติริมทะเลสาบ",
            brand: "WONDER ONE", logo: "mock-logo-wonder", cover: "mock-cover-wonder",
            dateRange: "21 ก.ย. 69 - 28 ก.ย. 69",
            howTo: "จัดเต็มความสนุกตั้งแต่เที่ยงวันยันเที่ยงคืนกับ 5 WONDERS ทั้งวิวธรรมชาติ ร้านเด็ดกว่า 30 ร้าน โซนถ่ายรูปสุดฮิป 🎡 และคอนเสิร์ตสุดอลังการจาก 7 ศิลปินฮอต JEFF SATUR, NONT TANONT, PiXXiE, MILLI, SLOT MACHINE, TIMETHAI และ RISA NARISA 🎶🔥 ปิดท้ายค่ำคืนด้วยงานไฟ Immersive Light สุดว้าว พร้อมที่จอดรถเพียบและห้องน้ำสะอาดติดสปีด 🚗 บัตร Early Bird มาพร้อมสิทธิพิเศษ จองก่อนได้ราคาดีกว่า แล้วเจอกันที่ริมทะเลสาบ!",
            registerSecondsLeft: 14 * 3600 + 59 * 60 + 48,
            reward: "บัตร Early Bird 2 ใบ + ชุด Merchandise", quota: 20, registered: 184,
            socialChannels: [.instagram, .tiktok], contentTypes: ["Photo", "Short Video"],
            timeline: [("ลงทะเบียน", "21 – 28 ก.ย. 69"), ("ประกาศผล", "30 ก.ย. 69"), ("ตอบรับกิจกรรม", "30 ก.ย. – 2 ต.ค. 69"),
                       ("จัดส่งสินค้า", "3 ต.ค. 69"), ("ส่งดราฟต์รีวิว", "5 – 12 ต.ค. 69"), ("ส่งลิงก์รีวิว", "13 – 20 ต.ค. 69")],
            questions: [
                CampaignQuestion(kind: .text, q: "ทำไมคุณถึงอยากไปงานนี้? (สั้น ๆ)"),
                CampaignQuestion(kind: .radio, q: "เคยไปเทศกาลดนตรีมาก่อนไหม", options: ["เคย", "ไม่เคย"]),
                CampaignQuestion(kind: .checkbox, q: "ศิลปินที่คุณตั้งใจไปดู", options: ["JEFF SATUR", "NONT TANONT", "PiXXiE", "MILLI", "SLOT MACHINE", "TIMETHAI", "RISA NARISA"]),
                CampaignQuestion(kind: .upload, q: "แนบตัวอย่างคอนเทนต์สายคอนเสิร์ตของคุณ"),
            ],
            acceptQuestions: [CampaignQuestion(kind: .radio, q: "สะดวกไปงานวันไหน", options: ["เสาร์ 4 ต.ค.", "อาทิตย์ 5 ต.ค.", "ทั้งสองวัน"])],
            fee: 3000
        ),
        StarCampaign(
            id: "1569", episode: "EP.1569",
            title: "Thymora ผลิตภัณฑ์สมุนไทยบำรุงผิว บอกลาปัญหาผิวและเส้นผม",
            brand: "Thymora", logo: "mock-logo-thymora", cover: "mock-cover-thymora",
            dateRange: "26 ส.ค. 69 - 30 ก.ย. 69",
            howTo: "รับผลิตภัณฑ์ Thymora ชุดบำรุงผิวและเส้นผมจากสมุนไพรไทย ทดลองใช้จริง 14 วัน แล้วรีวิวประสบการณ์ผ่านช่องทางของคุณ พร้อมแนบรูปก่อน-หลังใช้ และติดแฮชแท็ก #Thymora #SaleHereSTAR ในโพสต์ ทีมงานคัดเลือกรีวิวคุณภาพเพื่อรับของรางวัลเพิ่มเติม",
            registerSecondsLeft: 8 * 24 * 3600 + 3 * 3600 + 12 * 60 + 5,
            reward: "ชุดผลิตภัณฑ์ Thymora มูลค่า 1,890 บาท", quota: 50, registered: 412,
            socialChannels: [.instagram], contentTypes: ["Photo"],
            timeline: [("ลงทะเบียน", "26 ส.ค. – 30 ก.ย. 69"), ("ประกาศผล", "2 ต.ค. 69"), ("ตอบรับกิจกรรม", "2 – 4 ต.ค. 69"),
                       ("จัดส่งสินค้า", "6 ต.ค. 69"), ("ส่งดราฟต์รีวิว", "20 – 27 ต.ค. 69"), ("ส่งลิงก์รีวิว", "28 ต.ค. – 4 พ.ย. 69")],
            questions: [CampaignQuestion(kind: .radio, q: "สภาพผิวของคุณ", options: ["ผิวมัน", "ผิวแห้ง", "ผิวผสม", "ผิวแพ้ง่าย"])]
        ),
        StarCampaign(
            id: "1571", episode: "EP.1571",
            title: "Terminal 21 เช็คอินคาเฟ่ลับ 5 ชั้น เก็บครบทุกมุมถ่ายรูป",
            brand: "Terminal 21", logo: "ph03", cover: "ph02",
            dateRange: "14 ก.ย. 69 - 20 ก.ย. 69",
            howTo: "เดินเก็บคาเฟ่ลับใน Terminal 21 ให้ครบ 5 ร้าน ถ่ายรูปกับมุมประจำชั้น แล้วโพสต์รีวิวแบบ carousel อย่างน้อย 5 รูป พร้อมพิกัดร้านและเมนูแนะนำ",
            registerSecondsLeft: nil,
            reward: "Gift Voucher 1,000 บาท", quota: 30, socialChannels: [.instagram, .lemon8], fee: 1500
        ),
    ]
}
