import SwiftUI
import PhosphorSwift

/// Vibe การทำงาน — ข้อ `terms` (group) ของฟอร์มเว็บ: days → time · draft · limit · province
struct TermsSection: View {
    let showIssues: Bool
    @Binding var focusRequest: String?

    @FocusState private var focus: String?
    @State private var otherOn = false
    private var p: Profile { Profile.me }
    private var a: Availability { p.intake?.availability ?? Availability() }

    private func err(_ f: String) -> String? { sectionIssue(.terms, f, shown: showIssues) }
    private func update(_ f: (inout Availability) -> Void) { Profile.me.updateIntake { f(&$0.availability) } }

    private var dayChoice: String? { IntakeCatalog.dayOptions.first { $0.days == a.days }?.value }
    private var timeChoice: String? { IntakeCatalog.timeOptions.first { $0.slots == a.slots }?.value }

    var body: some View {
        SectionScroll(focus: $focus, request: $focusRequest) {
            days
            draft
            limits
            provinces
        }
        .onAppear { otherOn = !a.otherLimit.isEmpty }
    }

    // MARK: `days` → `time`

    private var days: some View {
        PKPanel(title: "ว่างรับงานวันไหน?") {
            PKTileGrid(items: IntakeCatalog.dayOptions) { o in
                PKTile(icon: o.icon, title: o.label, detail: o.detail, on: dayChoice == o.value) {
                    update { $0.days = o.days }
                }
            }
            if let e = err(PField.days) { errorText(e) }
            if dayChoice != nil {
                VStack(alignment: .leading, spacing: 8) {
                    PKLabel(text: "ช่วงไหนของวัน?", required: true)
                    PKChoiceGrid(items: IntakeCatalog.timeOptions.map(\.value),
                                 label: { v in IntakeCatalog.timeOptions.first { $0.value == v }?.label ?? v },
                                 isOn: { timeChoice == $0 }) { v in
                        if let o = IntakeCatalog.timeOptions.first(where: { $0.value == v }) { update { $0.slots = o.slots } }
                    }
                    if let e = err(PField.time) { errorText(e) }
                }
                .id(PField.time)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .id(PField.days)
        .animation(Motion.settle, value: dayChoice)
    }

    // MARK: `draft`

    private var draft: some View {
        PKPanel(title: "แก้งานให้ได้กี่รอบ?", subtitle: "ไม่นับกรณีงานไม่ตรงบรีฟ") {
            PKChoiceGrid(items: IntakeCatalog.draftRounds, label: { "\($0) ครั้ง" },
                         isOn: { a.draftRounds == $0 }) { n in update { $0.draftRounds = n } }
            if let e = err(PField.draft) { errorText(e) }
        }
        .id(PField.draft)
    }

    // MARK: `limit` (chipsother)

    private var limits: some View {
        PKPanel(title: "มีงานแนวไหนที่ขอผ่านไหม? 🙅‍♀️", subtitle: "เลือกได้หลายข้อ") {
            // ปุ่มสุดท้าย "อื่น ๆ" เปิดช่องพิมพ์ (= `otherOn` ของเว็บ)
            PKChoiceGrid(items: IntakeCatalog.limits.map(\.value) + [Self.otherKey],
                         label: { v in v == Self.otherKey ? "✏️ อื่น ๆ (ระบุเอง)" : (IntakeCatalog.limits.first { $0.value == v }?.label ?? v) },
                         isOn: { v in v == Self.otherKey ? otherOn : a.limits.contains(v) }) { v in
                if v == Self.otherKey {
                    withAnimation(Motion.settle) { otherOn.toggle() }
                    if !otherOn { update { $0.otherLimit = "" } }
                    return
                }
                update { av in
                    if av.limits.contains(v) {
                        av.limits.removeAll { $0 == v }
                    } else if v == IntakeCatalog.noLimit {
                        // "รับได้หมดเลย" ตัดข้ออื่นทั้งหมด (= `excl`)
                        av.limits = [v]
                    } else {
                        av.limits.removeAll { $0 == IntakeCatalog.noLimit }
                        av.limits.append(v)
                    }
                }
            }
            if otherOn {
                PKField(label: "ระบุข้อจำกัดเพิ่มเติม", text: otherBinding,
                        placeholder: IntakeCatalog.otherLimitPlaceholder,
                        id: PField.otherLimit, focus: $focus)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .id(PField.limits)
    }

    private static let otherKey = "__other"

    private var otherBinding: Binding<String> {
        Binding(get: { a.otherLimit }, set: { v in update { $0.otherLimit = v } })
    }

    // MARK: `province`

    private var provinces: some View {
        PKPanel(title: "อยู่จังหวัดไหน / ไปถึงไหนได้บ้าง?") {
            PKSelect(label: "จังหวัด", options: IntakeCatalog.provinces.filter { !a.provinces.contains($0) },
                     value: addBinding, placeholder: "เพิ่มจังหวัด…", id: PField.provinces)
            if !a.provinces.isEmpty {
                PKWrap(spacing: 8) {
                    ForEach(a.provinces, id: \.self) { pv in
                        HStack(spacing: 5) {
                            Text(pv).font(.sh(13, .semibold))
                            PIcon(.x, size: 10)
                        }
                        .foregroundStyle(PK.onPick)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Capsule().fill(PK.pick))
                        .overlay(Capsule().strokeBorder(PK.pickLine, lineWidth: 1.5))
                        .onTapGesture {
                            Haptics.impact(.light)
                            update { $0.provinces.removeAll { $0 == pv } }
                        }
                    }
                }
            }
            Text("เลือกได้สูงสุด \(IntakeCatalog.maxProvinces) จังหวัด")
                .font(.sh(11.5, .medium))
                .foregroundStyle(a.provinces.count >= IntakeCatalog.maxProvinces ? PK.warn : PK.hint)
        }
    }

    /// เมนูเพิ่มจังหวัด — เลือกแล้วเพิ่มเข้าชิป ตัวเมนูกลับเป็นว่างเสมอ (= `provSel`)
    private var addBinding: Binding<String> {
        Binding(get: { "" }, set: { v in
            guard !v.isEmpty else { return }
            update { av in
                guard !av.provinces.contains(v), av.provinces.count < IntakeCatalog.maxProvinces else { return }
                av.provinces.append(v)
            }
        })
    }

    private func errorText(_ e: String) -> some View {
        Text(e).font(.sh(11.5, .medium)).foregroundStyle(PK.err)
    }
}
