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
