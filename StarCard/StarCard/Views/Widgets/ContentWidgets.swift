import SwiftUI

/// สายงานที่ครีเอเตอร์พิมพ์เอง
///
/// # ท่าเปลี่ยนหน้า — "ชิปปลิวออกข้าง"
///
/// จงใจให้ต่างจาก "หมวดหมู่ที่สนใจ" ซึ่งเป็นชุดชิปเหมือนกัน: ตัวนั้นชิป**ร่วงลง**
/// ตัวนี้ชิป**ปลิวออกข้าง**ไล่กัน สลับสองแบบในการ์ดใบเดียวแล้วยังอ่านเป็นภาษาเดียวกัน
/// เพราะทั้งคู่คือ "ชิ้นเล็กหลายชิ้นที่ไปทีละชิ้นตามทิศนิ้ว"
struct NicheTags: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    var body: some View {
        let items = Mock.creator.categories
        return VStack(alignment: .leading, spacing: 11) {
            WidgetLabel(text: "สายงาน")
                .scrubVeil(scrub.d, lead: 0.34, drop: 20, pull: 6)

            // ต้องใช้ FlowLayout — LazyVGrid แบ่งคอลัมน์กว้างเท่ากันตายตัว
            // ชิปสั้นอย่าง "บิวตี้" เลยถูกดันห่างจากตัวถัดไปจนอ่านเป็นตาราง ไม่ใช่แท็ก
            FlowLayout(spacing: 7) {
                ForEach(Array(items.enumerated()), id: \.element) { i, t in
                    Text(t)
                        .font(.sh(12, .semibold))
                        .foregroundStyle(ink.text(0.92))
                        .lineLimit(1)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(ink.fill(0.07)))
                        .overlay(Capsule().strokeBorder(ink.line(0.16), lineWidth: 0.6))
                        .scrubSlide(scrub.d, travel: 60 + CGFloat(i) * 10,
                                    lead: Scrub.lead(i, of: items.count, d: scrub.d, step: 0.06),
                                    fade: 0.55)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
