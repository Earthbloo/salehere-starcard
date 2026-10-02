import SwiftUI
import PhosphorSwift

/// สายที่ใช่ — ข้อ `cats` (เลือกได้ 1–5 หมวด) + `fashion` (ไซซ์ ถามเฉพาะเมื่อเลือกแฟชั่น) ของฟอร์มเว็บ
struct InterestsSection: View {
    let showIssues: Bool
    @Binding var focusRequest: String?

    @FocusState private var focus: String?
    private var p: Profile { Profile.me }

    private var selected: [String] { p.intake?.interests ?? [] }
    private var full: Bool { selected.count >= IntakeCatalog.maxInterests }
    private var fashion: Bool { selected.contains(IntakeCatalog.fashion) }

    var body: some View {
        SectionScroll(focus: $focus, request: $focusRequest) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(selected.count)/\(IntakeCatalog.maxInterests)")
                    .font(.sh(12.5, .bold)).foregroundStyle(full ? PK.redDark : PK.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                // ตาราง 2 คอลัมน์ · ครบโควตาแล้ว ปุ่มที่เหลือจางและกดไม่ได้ — ไม่ใช่ดูกดได้แล้วเงียบ
                PKChoiceGrid(items: IntakeCatalog.interests.map(\.name),
                             label: { "\(IntakeCatalog.icon(for: $0)) \($0)" },
                             isOn: { selected.contains($0) },
                             isDim: { full && !selected.contains($0) }) { name in
                    Profile.me.updateIntake { d in
                        if d.interests.contains(name) { d.interests.removeAll { $0 == name } }
                        else if d.interests.count < IntakeCatalog.maxInterests { d.interests.append(name) }
                    }
                }
                if let e = sectionIssue(.interests, PField.interests, shown: showIssues) {
                    Text(e).font(.sh(11.5, .medium)).foregroundStyle(PK.err)
                }
            }
            .padding(.horizontal, 4)
            .id(PField.interests)

            // ข้อ `fashion` — `showIf: fashionOn`
            if fashion {
                PKPanel(title: "ขอไซซ์เสื้อผ้าหน่อยน้า 👗",
                        subtitle: "เฉพาะสายแฟชั่น ให้แบรนด์ส่งชุดได้ตรงไซซ์") {
                    ForEach(IntakeCatalog.fashionFields, id: \.field.rawValue) { f in
                        PKField(label: f.label, required: true, text: sizeBinding(f),
                                placeholder: f.placeholder, keyboard: .numberPad, noCorrect: true,
                                error: sectionIssue(.interests, PField.size(f.field), shown: showIssues),
                                id: PField.size(f.field), focus: $focus,
                                onCommit: { Profile.me.commit(TextSlotID(field: f.field)) })
                    }
                }
                .id(PField.fashion)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(Motion.settle, value: fashion)
    }

    /// ฟอร์มเก็บตัวเลขล้วน · การ์ดต้องการ "165 ซม." — ต่อหน่วยให้ตอนเขียน ตัดออกตอนอ่าน
    private func sizeBinding(_ f: (field: ProfileField, label: String, placeholder: String, unit: String)) -> Binding<String> {
        let store = p.binding(f.field)
        return Binding(get: { p.isPlaceholder(f.field) ? "" : store.wrappedValue.filter { $0.isNumber || $0 == "." } },
                       set: { v in
                           let n = v.filter { $0.isNumber || $0 == "." }
                           store.wrappedValue = n.isEmpty ? "" : "\(n) \(f.unit)"
                       })
    }
}
