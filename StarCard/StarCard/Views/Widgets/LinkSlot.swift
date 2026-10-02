import SwiftUI

/// ปลายทางของชิ้นส่วนหนึ่งใน widget — "กดตรงนี้แล้วออกไปที่ไหน"
///
/// เนื้อหาข้างใน widget ถูกปิด hit testing ไว้ทั้งก้อน (ดู `WidgetChrome`) และตัวรับทัชจริง
/// คือ `PressDragCatcher` ที่ชั้นการ์ดวางทับอีกที ปุ่มลิงก์จึงวางไว้ในตัว widget ไม่ได้เลย —
/// ต้อง **ประกาศกรอบขึ้นไป** ให้ชั้นการ์ดรู้ว่าพิกัดไหนของ widget ผูกกับ URL ไหน
/// แล้วชั้นการ์ดเป็นคนตัดสินตอนนิ้วแตะ ว่าจะเปิดลิงก์ (โหมดดู) หรือจะเลือก/ลาก (โหมดแต่ง)
///
/// เป็นกลไกเดียวกับ `PhotoSlotKey` และ `TextSlotKey` เป๊ะ ๆ ต่างแค่ปลายทางที่ทำ
struct LinkSlotAnchor: Equatable {
    let url: URL
    let bounds: Anchor<CGRect>
}

struct LinkSlotKey: PreferenceKey {
    static let defaultValue: [LinkSlotAnchor] = []
    static func reduce(value: inout [LinkSlotAnchor], nextValue: () -> [LinkSlotAnchor]) {
        value += nextValue()
    }
}

/// กรอบที่แปลงเป็นพิกัดจริงแล้ว — ชั้นการ์ดใช้เช็คว่านิ้วแตะโดนลิงก์ไหน
struct LinkSlotRect: Equatable {
    let url: URL
    let rect: CGRect
}

extension View {
    /// ประกาศว่ากรอบนี้กดแล้วไป `url` · ส่ง nil เมื่อชิ้นนั้นยังไม่มีปลายทาง (ก็แค่ไม่มีลิงก์)
    ///
    /// ติดไว้ที่ **กรอบนอกสุดของชิ้นหนึ่งชิ้น** (แถวหนึ่งแถว · การ์ดผลงานหนึ่งใบ)
    /// ไม่ใช่ที่ตัวอักษรข้างใน — พื้นที่กดต้องเท่าที่ตาเห็นว่าเป็นของชิ้นนั้น
    func linkSlot(_ url: URL?) -> some View {
        anchorPreference(key: LinkSlotKey.self, value: .bounds) { b in
            url.map { [LinkSlotAnchor(url: $0, bounds: b)] } ?? []
        }
    }
}

/// ทะเบียนกรอบลิงก์ของทุก widget บนหน้า
///
/// เป็นคลาสธรรมดา ไม่ใช่ `@Observable` ด้วยเหตุผลเดียวกับ `TextSlotBox` —
/// ค่านี้ถูกเขียนใหม่ทุกครั้งที่ผังขยับ แต่ไม่มีใครอ่านตอนวาด มีแต่ตอนนิ้วแตะ
final class LinkSlotBox {
    var rects: [UUID: [LinkSlotRect]] = [:]

    /// ลิงก์ที่นิ้วแตะโดน — ไล่จากท้ายลิสต์ขึ้นมา ชิ้นที่ประกาศทีหลังอยู่ชั้นบนกว่าเมื่อกรอบซ้อนกัน
    func hit(_ point: CGPoint, in widget: UUID) -> URL? {
        rects[widget]?.last { $0.rect.contains(point) }?.url
    }
}

// MARK: - ช่องข้อความที่มีปลายทางในตัว

extension ProfileField {
    /// ช่องที่ "ค่าของมันคือทางติดต่อ" — กดแล้วต้องไปถึงตัวคนได้ทันที ไม่ต้องก็อปไปวางเอง
    ///
    /// ประกาศที่นี่ที่เดียวแล้ว `.editableText` ติดลิงก์ให้เอง ทุก widget ที่โชว์ช่องเหล่านี้
    /// จึงกดได้ครบโดยไม่ต้องไล่ใส่ `.linkSlot` ทีละใบ · ชื่อ = โทรหาเจ้าของการ์ด
    var contactURL: URL? {
        let me = Profile.me
        switch self {
        case .lineId: return Contact.line(me.lineId)
        case .phone: return Contact.tel(me.phone)
        case .website: return Contact.web(me.website)
        default:                          return nil
        }
    }
}

enum Contact {
    static func tel(_ raw: String) -> URL? {
        let digits = raw.filter { $0.isNumber || $0 == "+" }
        return digits.isEmpty ? nil : URL(string: "tel:\(digits)")
    }

    /// พิมพ์มาไม่มี https:// ก็เปิดได้ — คนส่วนใหญ่พิมพ์แค่ "yourname.com"
    static func web(_ raw: String) -> URL? {
        let s = raw.trimmingCharacters(in: .whitespaces)
        guard s.contains(".") else { return nil }
        return URL(string: s.lowercased().hasPrefix("http") ? s : "https://\(s)")
    }

    static func mail(_ raw: String) -> URL? {
        let s = raw.trimmingCharacters(in: .whitespaces)
        return s.contains("@") ? URL(string: "mailto:\(s)") : nil
    }

    /// ไลน์ไอดีขึ้นต้น @ = บัญชีทางการ (`/R/ti/p/@id`) · ไอดีส่วนตัวต้องมี ~ นำหน้า
    /// ลิงก์ line.me เป็น universal link — มีแอป LINE ก็เด้งเข้าแอปตรงหน้าเพิ่มเพื่อน
    static func line(_ raw: String) -> URL? {
        let s = raw.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return nil }
        let path = s.hasPrefix("@") ? s : "~\(s)"
        let enc = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        return URL(string: "https://line.me/R/ti/p/\(enc)")
    }
}
