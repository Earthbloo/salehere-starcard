import SwiftUI

// MARK: - ตรารับรองที่ตรึงไว้กับการ์ด
//
// # ทำไมมีใบที่ลบไม่ได้
//
// ตรารับรอง (`proofSeal`) คือคำยืนยันของ Sale Here ไม่ใช่ของตกแต่งของเจ้าของการ์ด —
// ถ้าเจ้าของถอดได้ คนดูจะแยกไม่ออกว่าการ์ดที่ไม่มีตราคือ "ยังไม่ผ่าน" หรือ "ถอดออกเอง"
// ทุกการ์ดจึงมีตรานี้หนึ่งใบ **ที่เดิมเสมอ** (ผู้ใช้ 1 ต.ค. 2569):
//
// * สตอรี่ (แนวตั้ง) — มุมขวาล่าง กว้างครึ่งหน้า
// * พอร์ต (แนวนอน 3 ช่อง) — ก้นช่องที่ 3 เต็มความกว้างช่อง
//
// ยังเป็น `WidgetInstance` จริงในหน้า (ไม่ใช่ชั้นลอยที่วาดทับ) — ผังจึงกันที่ให้มันเหมือนของทุกชิ้น
// รูปที่แชร์ · พรีวิวในคลัง · JSON ที่ซิงก์ เห็นมันทางเดียวกับ widget อื่นโดยไม่ต้องรู้จักเป็นพิเศษ
// สิ่งเดียวที่ต่างคือธง `pinned`: ห้องแต่งไม่ให้ลบ/ย้าย/ยืด และ `PageLayout` ให้ที่มันก่อนใคร
enum PinnedSeal {
    static let kind: WidgetKind = .proofSeal

    /// หน้าที่ตราอยู่ — หน้าสุดท้ายของรูปแบบนั้น
    static func page(for format: CardFormat) -> Int { format.pageCount - 1 }

    /// ตราใบใหม่ในขนาดและตำแหน่งของรูปแบบนั้น
    static func make(for format: CardFormat) -> WidgetInstance {
        var w = WidgetInstance(kind)
        w.pinned = true
        place(&w, format: format)
        return w
    }

    /// ตั้ง x · กว้าง · สูง ตามรูปแบบ — `y` ใส่ไว้ให้ไฟล์อ่านรู้เรื่องเท่านั้น ตอนวาดคิดจากก้นหน้าจริง
    private static func place(_ w: inout WidgetInstance, format: CardFormat) {
        let page = CardTemplate.previewPageSize(for: format)
        let box = PageLayout.content(page)
        switch format {
        case .story:
            // ครึ่งขวาของหน้า เว้นร่องกลางเท่าที่ระบบเว้นให้ของทุกชิ้น · ปัดลงขั้นสแนปให้ขอบตรงกับของข้าง ๆ
            let half = (box.width - PageLayout.gap) / 2
            w.w = (half / PageLayout.step).rounded(.down) * PageLayout.step
        case .portfolio:
            w.w = box.width
        }
        w.h = kind.height(forWidth: w.w)
        w.x = box.maxX - w.w
        w.y = box.maxY - w.h
    }

    /// ทำให้การ์ดมีตราที่ตรึงไว้ **หนึ่งใบพอดี ที่หน้าสุดท้าย** — เรียกซ้ำได้ ผลเท่าเดิม
    ///
    /// ตราเดิม (ถ้ามี) ถูกเก็บไว้ทั้งตัว — พื้น · ขอบ · ลาย ที่เจ้าของเลือกไว้ยังอยู่
    /// ที่ถูกตั้งใหม่มีแค่ขนาดกับตำแหน่ง ซึ่งไม่ใช่ของที่เจ้าของเลือกได้
    static func ensure(_ pages: inout [CardPage], format: CardFormat) {
        while pages.count < format.pageCount { pages.append(CardPage()) }
        let target = page(for: format)

        var seal = pages.flatMap(\.items).first { $0.pinned && $0.kind == kind } ?? make(for: format)
        place(&seal, format: format)
        for i in pages.indices { pages[i].items.removeAll(where: \.pinned) }
        pages[target].items.append(seal)
        makeRoom(&pages[target].items, page: CardTemplate.previewPageSize(for: format))
    }

    /// เปิดที่ให้ตรา — ของที่ตราลงไปทับ **ย้ายไปที่ว่าง** ไม่มีที่ว่างพอก็ **ย่อทั้งชิ้น** จนลงได้
    ///
    /// การ์ดที่แต่งไว้ก่อนมีตรามักมีของอยู่ตรงก้นหน้าพอดี ถ้าปล่อยให้ผังดันกันเอง หน้าที่เต็มอยู่แล้ว
    /// จะจบที่ของทับกัน (ดูทางออกสุดท้ายของ `PageLayout.slots`) · ย่อได้ถึงครึ่งเดียว ต่ำกว่านั้นคือเศษ —
    /// ชิ้นที่ยังไม่ลงถูกปล่อยไว้ที่เดิมให้เจ้าของจัดเอง (ผังจะไม่ซุกมันไว้ใต้ตรา)
    ///
    /// พอร์ตคิดด้วยความสูงหน้ามาตรฐาน: จอที่สูงกว่านั้นตราอยู่ต่ำลงอีก ที่ที่เปิดไว้จึงยังใช้ได้
    static func makeRoom(_ items: inout [WidgetInstance], page: CGSize) {
        guard let seal = items.first(where: \.pinned) else { return }
        let hole = PageLayout.pinnedFrame(seal, page: page).insetBy(dx: 0.5, dy: 0.5)
        let blocked = items.filter { !$0.pinned && PageLayout.clamp($0, page: page).intersects(hole) }
            .sorted { $0.y < $1.y }

        for b in blocked {
            guard let i = items.firstIndex(where: { $0.id == b.id }) else { continue }
            let others = items.filter { $0.id != b.id }
            var w = items[i]
            if let at = PageLayout.freeSpot(size: w.rect.size, page: page, avoiding: others) {
                w.x = at.x; w.y = at.y
                items[i] = w
                continue
            }
            // ก้อนข้อความไม่ย่อ — ความกว้างของมันคือตัวอักษร (ดู `CardScreen.fitTextBlock`)
            guard w.kind != .textBlock else { continue }
            let ratio = w.h / max(w.w, 1)
            let floor = max(PageLayout.minSize.width, PageLayout.snap(w.w * 0.5))
            var width = PageLayout.snap(w.w) - PageLayout.step
            while width >= floor {
                if let at = PageLayout.freeSpot(size: CGSize(width: width, height: width * ratio),
                                                page: page, avoiding: others) {
                    w.scale(toWidth: width)
                    w.x = at.x; w.y = at.y
                    items[i] = w
                    break
                }
                width -= PageLayout.step
            }
        }
    }
}
