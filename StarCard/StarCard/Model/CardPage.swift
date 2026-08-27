import SwiftUI

/// หนึ่งหน้ากระดาษ A4 ในพอร์ตโฟลิโอ
///
/// พอร์ตจริงไม่เคยจบในหน้าเดียว — หน้าแรกขายตัวตน หน้าถัดไปคือผลงาน แล้วปิดด้วยราคา/ติดต่อ
/// เก็บ items แยกต่อหน้า ไม่ใช่ลิสต์เดียวแล้วให้ระบบตัดหน้าเอง เพราะผู้ใช้ต้องคุมได้ว่าอะไรอยู่หน้าไหน
struct CardPage: Identifiable, Equatable {
    let id = UUID()
    var items: [WidgetInstance]

    init(_ items: [WidgetInstance] = []) { self.items = items }

    var usedRows: Int { PageLayout.usedRows(items) }
    var isOverflowing: Bool { usedRows > PageLayout.rows }
    var freeRows: Int { max(0, PageLayout.rows - usedRows) }
}
