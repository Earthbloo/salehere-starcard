import SwiftUI

/// ตำแหน่งที่คำนวณแล้วของ widget หนึ่งตัว (พิกัดรวมทุกหน้า)
struct Placed: Identifiable, Equatable {
    var id: UUID { item.id }
    let item: WidgetInstance
    /// พิกัดอ้างอิงมุมบนซ้ายของหน้ากระดาษ
    let frame: CGRect
}

/// ผังหน้าเต็มจอ
///
/// เดิมบังคับอัตราส่วน A4 แล้วเหลือขอบดำบนล่าง — ตอนนี้ให้หน้ากินพื้นที่ทั้งหมดที่มี
/// จำนวนแถวขยับจาก 9 เป็น 12 เพื่อให้ช่องยังใกล้สี่เหลี่ยมจัตุรัส ไม่ยืดเป็นแท่งสูง
enum PageLayout {
    static let cols = 6
    /// ซอยละเอียด 36 แถว — หนึ่งแถว ≈ ระยะจุดปะหนึ่งจุด (~20pt)
    /// จุดบนฉากหลังคือกริดจริงแบบ Figma: ปรับสูง/เว้น/ลาก ขยับทีละจุด
    static let rows = 36

    /// สัดส่วนเทียบความกว้างหน้า
    private static let marginRatio: CGFloat = 0.045
    private static let gutterRatio: CGFloat = 0.019

    static func margin(_ w: CGFloat) -> CGFloat { w * marginRatio }
    static func gutter(_ w: CGFloat) -> CGFloat { w * gutterRatio }

    static func cell(_ size: CGSize) -> CGSize {
        let m = margin(size.width), g = gutter(size.width)
        return CGSize(
            width: (size.width - m * 2 - g * CGFloat(cols - 1)) / CGFloat(cols),
            height: (size.height - m * 2 - g * CGFloat(rows - 1)) / CGFloat(rows)
        )
    }

    static func size(cols c: Int, rows r: Int, page: CGSize) -> CGSize {
        let cell = cell(page), g = gutter(page.width)
        return CGSize(width: cell.width * CGFloat(c) + g * CGFloat(c - 1),
                      height: cell.height * CGFloat(r) + g * CGFloat(r - 1))
    }

    // MARK: - จัดเรียงในหนึ่งหน้า

    /// ไหลจากซ้ายไปขวา บนลงล่าง · พิกัดอ้างอิงมุมบนซ้ายของหน้า
    static func solve(_ items: [WidgetInstance], page: CGSize) -> [Placed] {
        guard page.width > 0, page.height > 0 else { return [] }
        let m = margin(page.width), g = gutter(page.width), cell = cell(page)

        var placed: [Placed] = []
        var row = 0, col = 0, rowTallest = 0

        for item in items {
            let c = min(max(item.cols, 1), cols)
            let r = min(max(item.rows, 1), rows)
            let breath = min(max(item.gap, 0), rows)

            // ตัวที่ขอเว้นบนต้องขึ้นแถวใหม่เสมอ — เว้นกลางแถวไม่มีความหมาย
            if col + c > cols || (breath > 0 && col > 0) {
                row += max(rowTallest, 1); col = 0; rowTallest = 0
            }
            if col == 0 { row += breath }

            let x = m + CGFloat(col) * (cell.width + g)
            let y = m + CGFloat(row) * (cell.height + g)
            let s = size(cols: c, rows: r, page: page)
            placed.append(Placed(item: item, frame: CGRect(origin: CGPoint(x: x, y: y), size: s)))

            col += c
            rowTallest = max(rowTallest, r)
        }
        return placed
    }

    /// จำนวนแถวที่ใช้ไปแล้ว — ใช้เตือนเมื่อของล้นหน้า
    static func usedRows(_ items: [WidgetInstance]) -> Int {
        var row = 0, col = 0, tallest = 0
        for item in items {
            let c = min(max(item.cols, 1), cols)
            let breath = min(max(item.gap, 0), rows)
            if col + c > cols || (breath > 0 && col > 0) { row += max(tallest, 1); col = 0; tallest = 0 }
            if col == 0 { row += breath }
            col += c
            tallest = max(tallest, min(max(item.rows, 1), rows))
        }
        return row + tallest
    }

    /// หา index ที่ควรแทรก — เดินตามลำดับ flow นับตัวที่อยู่ "ก่อน" จุดนิ้ว
    ///
    /// - Parameter baseline: ผังของ widget ตัวอื่น คำนวณครั้งเดียวตอนเริ่มลาก ต้องคงที่ตลอด
    ///   ไม่งั้นจะเกิดวงจรป้อนกลับ: ย้าย → ผังเปลี่ยน → index เปลี่ยน → ย้ายกลับ → สั่นไม่จบ
    static func insertionIndex(for point: CGPoint, in baseline: [Placed]) -> Int {
        var idx = 0
        for p in baseline {
            let comesBefore: Bool
            if point.y > p.frame.maxY {
                comesBefore = true
            } else if point.y < p.frame.minY {
                comesBefore = false
            } else {
                comesBefore = point.x > p.frame.midX
            }
            if comesBefore { idx += 1 } else { break }
        }
        return idx
    }
}
