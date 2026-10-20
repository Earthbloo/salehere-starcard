// ชิ้นส่วนกลางที่ตัววาดผัง (SpecPainter) และหน้าจออื่นเรียกใช้ — ไม่ผูกกับ widget ตัวใด
import SwiftUI


// MARK: - ชิปที่ขึ้นบรรทัดเอง

/// เรียงชิปซ้าย→ขวา แล้วขึ้นบรรทัดใหม่เมื่อชนขอบ
///
/// ใช้ `Layout` ของจริงแทน LazyVGrid เพราะชิปกว้างไม่เท่ากัน — กริดคอลัมน์ตายตัว
/// จะทิ้งช่องว่างข้างชิปสั้น ๆ จนอ่านเป็นตารางแทนที่จะเป็นแท็ก
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0, x + s.width > maxW {
                x = 0; y += lineH + spacing; lineH = 0
            }
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
        return CGSize(width: maxW == .infinity ? x : maxW, height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > bounds.minX, x + s.width > bounds.maxX {
                x = bounds.minX; y += lineH + spacing; lineH = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
    }
}
