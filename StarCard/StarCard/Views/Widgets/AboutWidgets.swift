import SwiftUI

// widget กลุ่ม "เกี่ยวกับฉัน"
//
// "หมวดหมู่ที่สนใจ" เป็นชั้น connected — ค่ามาจากหน้าตั้งค่าโปรไฟล์
// แต่งหน้าตาได้ แต่แก้ค่าบนการ์ดไม่ได้ ไม่งั้นข้อมูลจะขัดกับระบบจับคู่งาน

// MARK: - แนะนำตัว

/// ย่อหน้าแนะนำตัว — ตัวเดียวในการ์ดที่ครีเอเตอร์พูดด้วยเสียงตัวเองล้วน ๆ
///
/// วางแบบ standfirst ของนิตยสาร: เส้นสีตั้งนำสายตา ข้อความเยื้องเข้ามา
///
/// # ท่าเปลี่ยนหน้า — "เส้นนำหดกลับ"
/// เส้นสีที่ยึดบล็อกทั้งก้อนหดขึ้นจากปลายล่างตามนิ้ว อ่านเป็นแถบความคืบหน้าของการปัด
/// แล้วยืดกลับลงมาตอนปัดกลับ — ตัวหนังสือมุดใต้ขอบตามทีหลัง
struct AboutText: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // เส้นนำ — จางลงตามความสูง ให้บล็อกดูละลายหายไปแทนที่จะจบห้วน ๆ
            ScrubReader(d: scrub.d) { d in
                let t = Scrub.ease(Scrub.t(d))
                Capsule()
                    .fill(LinearGradient(colors: [theme.accent, theme.accent.opacity(0.08)],
                                         startPoint: .top, endPoint: .bottom))
                    .scaleEffect(y: max(0, 1 - t), anchor: .top)
            }
            .frame(width: 2.5)

            VStack(alignment: .leading, spacing: 10) {
                Text("แนะนำตัว".uppercased())
                    .font(.sh(9.5, .semibold)).tracking(1.4)
                    .foregroundStyle(theme.accent.opacity(0.85))
                    .scrubVeil(scrub.d, lead: 0.3, drop: 18, pull: 6)

                // ย่อหน้ากินความสูงที่เหลือทั้งหมดแล้วตัดท้ายด้วย … เมื่อพิมพ์ยาวเกิน
                // แทน `Spacer` เดิมที่เคยดันบล็อกขึ้นบน — ตอนนี้ย่อหน้าเป็นตัวยืดเอง
                EditableParagraph(field: .about,
                                  style: .init(size: 14, color: ink.text(0.88), lineSpacing: 7))
                    .scrubVeil(scrub.d, lead: 0.06, drop: 34, pull: 16)

                // สายงาน — ฟิลด์ที่สองของสัญญาตระกูล `intro`
                // ทั้งสองแบบในตระกูลต้องมีเท่ากัน ไม่งั้นสลับแบบแล้วข้อมูลหาย
                Text(Profile.me.tagline)
                    .lineLimit(1).truncationMode(.tail)
                    .padding(.top, 2)
                    .editableText(.tagline, .init(size: 11, weight: .bold,
                                                  color: theme.accent.opacity(0.85)))
                    .scrubVeil(scrub.d, lead: 0, drop: 24, pull: 20)
            }
        }
    }
}

// MARK: - หมวดหมู่ที่สนใจ

/// หมวดหมู่ทางการของแพลตฟอร์ม — ต่างจาก "สายงาน" ที่ครีเอเตอร์พิมพ์เอง
/// ติดเครื่องหมายถูกไว้เพราะเป็นค่าที่ระบบใช้จับคู่งานจริง ไม่ใช่คำโปรยที่เขียนเอง
///
/// # ท่าเปลี่ยนหน้า — "ชิปร่วงทีละเม็ด"
/// ชิปมุดใต้บรรทัดของตัวเองไล่กันตามทิศ ไม่ใช่ทั้งกลุ่มเลื่อนเป็นแผ่นเดียว
struct InterestTags: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    var body: some View {
        let items = Profile.me.creator.interests
        return VStack(alignment: .leading, spacing: 11) {
            // หมวดหมู่ทางการมาจากโปรไฟล์ในระบบ — บอกที่มาด้วยป้าย ไม่ใช่ตราติ๊กที่ไม่รู้ว่าใครติ๊ก
            WidgetLabel(text: "หมวดหมู่ที่สนใจ",
                        trailing: AnyView(ProvenanceTag(kind: .profile)))
                .scrubVeil(scrub.d, lead: 0.34, drop: 20, pull: 6)

            FlowLayout(spacing: 7) {
                ForEach(Array(items.enumerated()), id: \.element) { i, name in
                    Text(name)
                        .font(.sh(12, .semibold))
                        .foregroundStyle(ink.text(0.95))
                        .lineLimit(1)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(
                            Capsule().fill(LinearGradient(
                                colors: [theme.accent.opacity(0.28), theme.accent.opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .overlay(Capsule().strokeBorder(theme.accent.opacity(0.34), lineWidth: 0.6))
                        // เรืองอ่อน ๆ ใต้ชิป ให้ลอยขึ้นจากพื้นการ์ดแทนที่จะแบนติดกัน
                        .shadow(color: theme.accent.opacity(0.22), radius: 8, y: 3)
                        .scrubVeil(scrub.d,
                                   lead: Scrub.lead(i, of: items.count, d: scrub.d, step: 0.07),
                                   drop: 26, pull: 10)
                }
            }
            .frame(maxHeight: .infinity, alignment: .leading)
        }
    }
}

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

struct FlowChips<Content: View>: View {
    let items: [String]
    var spacing: CGFloat = 6
    @ViewBuilder let chip: (String) -> Content

    var body: some View {
        FlowLayout(spacing: spacing) {
            ForEach(items, id: \.self) { chip($0) }
        }
    }
}
