import SwiftUI

/// รูปแบบของการ์ด — ตัดสินว่า "กี่หน้า" และ "หน้าใหญ่เท่าไหร่"
///
/// # ทำไมเป็นโหมดที่เลือกก่อนเข้า ไม่ใช่สวิตช์ระหว่างทาง
///
/// สองแบบนี้ต่างกันที่ **จำนวนหน้า** ไม่ใช่แค่หน้าตา — ถ้าให้สลับกลางทาง
/// ระบบต้องตัดสินใจแทนผู้ใช้ว่าของอีกสองหน้าจะไปไหน ซึ่งไม่มีคำตอบที่ถูก
/// (ยัดรวมหน้าเดียวก็ล้น · ทิ้งก็คืองานหาย) เลือกตั้งแต่ต้นแล้วเก็บฉบับร่าง
/// **แยกช่องกัน** (ดู `CardStore`) จึงไม่มีของใครหาย และกลับไปแก้อีกใบได้ตลอด
enum CardFormat: String, CaseIterable, Identifiable, Codable {
    /// พอร์ตโฟลิโอ 3 หน้า — ปัดเปลี่ยนหน้าได้ · export เป็นแถบเดียวยาว
    case portfolio
    /// สตอรี่หน้าเดียว 9:16 — ทุกอย่างต้องจบในเฟรมเดียว เหมือนแต่ง Story
    case story

    var id: String { rawValue }

    /// จำนวนหน้าที่การ์ดแบบนี้มีได้ — สตอรี่คือ 1 และเพิ่มไม่ได้
    var pageCount: Int {
        switch self {
        case .portfolio: return 3
        case .story:     return 1
        }
    }

    /// ความกว้างของพื้นที่ออกแบบ — **ตัวนี้คือสิ่งที่ทำให้ขนาด widget เป็นพิกเซลจริง**
    ///
    /// ตรึงความกว้างไว้ แปลว่า "widget กว้าง 366" กว้างเท่ากันทุกเครื่องและในไฟล์ที่ export
    /// (เดิมความกว้างหน้ามาจากจอ ของชิ้นเดียวกันจึงกินสัดส่วนไม่เท่ากันบนแต่ละเครื่อง
    ///  โดยคนแต่งไม่มีทางรู้จนกว่าจะเห็นไฟล์ที่คนอื่นส่งออกมา)
    ///
    /// * พอร์ต 402 = ความกว้างหน้าเดิมบนเครื่องอ้างอิง — **ของทุกชิ้นจึงเท่าเดิมเป๊ะ**
    /// * สตอรี่ 540 = canvas ที่กว้างกว่า 34% โดยที่ widget ยังขนาด pt เท่าเดิมทุกตัว
    ///   ของชิ้นเดิมจึงกินแค่ 68% ของความกว้าง — ที่ว่างที่เหลือคือที่ของอีก 2–3 ชิ้น
    ///   และ 540×960 = 1080×1920 px ที่ @2x พอดี export ลงฟีดได้ 1:1
    var designWidth: CGFloat {
        switch self {
        case .portfolio: return 402
        case .story:     return 540
        }
    }

    /// ความสูงที่ล็อกไว้ — nil = **ยืดตามจอ** เหมือนเดิม
    ///
    /// สตอรี่ต้องล็อกเพราะปลายทางคือ 9:16 เป๊ะ ๆ ไม่ล็อกก็ถูกครอปตอนอัป
    /// ส่วนพอร์ตไม่มีอัตราส่วนปลายทาง — มันคือ "หน้าเต็มจอ" การล็อกความสูงมีแต่จะ
    /// ทำให้เกิดขอบดำบนเครื่องที่สัดส่วนไม่ตรง ซึ่งเป็นของที่ของเดิมไม่เคยมี
    var designHeight: CGFloat? {
        switch self {
        case .portfolio: return nil
        case .story:     return 960
        }
    }

    /// ขนาดหน้าใน **หน่วยออกแบบ** — ความกว้างตายตัวเสมอ ความสูงตามแบบ
    func pageSize(in box: CGSize) -> CGSize {
        let w = designWidth
        if let h = designHeight { return CGSize(width: w, height: h) }
        guard box.width > 1, box.height > 1 else { return CGSize(width: w, height: w * 1.667) }
        // แปลงความสูงที่จอให้มา เข้าหน่วยออกแบบด้วยอัตราส่วนความกว้าง
        return CGSize(width: w, height: box.height * w / box.width)
    }

    /// อัตราย่อจากหน่วยออกแบบ → หน่วยจอ
    func fit(in box: CGSize) -> CGFloat {
        let d = pageSize(in: box)
        guard d.width > 1, d.height > 1, box.width > 1, box.height > 1 else { return 1 }
        return min(box.width / d.width, box.height / d.height)
    }

    var title: String {
        switch self {
        case .portfolio: return "พอร์ตโฟลิโอ"
        case .story:     return "สตอรี่"
        }
    }

    var subtitle: String {
        switch self {
        case .portfolio: return "3 หน้า · เต็มจอ"
        case .story:     return "หน้าเดียว · 1080×1920"
        }
    }

    var blurb: String {
        switch self {
        case .portfolio: return "ใส่ได้ครบทั้งตัวตน สถิติ ผลงาน และราคา · แชร์เป็นแถบเดียวยาว"
        case .story:     return "จบในเฟรมเดียว ลงสตอรี่ได้เลย · แต่งเหมือนแต่ง Story"
        }
    }

    var icon: String {
        switch self {
        case .portfolio: return "rectangle.split.3x1"
        case .story:     return "rectangle.portrait"
        }
    }

    /// หน้าตั้งต้นของการ์ดแบบนี้
    var starterPages: [CardPage] {
        switch self {
        case .portfolio: return Mock.starterPages
        case .story:     return [Mock.storyPage]
        }
    }
}
