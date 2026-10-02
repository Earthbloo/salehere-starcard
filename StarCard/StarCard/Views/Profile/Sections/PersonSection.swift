import SwiftUI
import PhosphorSwift

/// ทำความรู้จักกัน — ข้อ `person` (group) ของฟอร์มเว็บ: name · basic · gender · religion · job → faculty/field
struct PersonSection: View {
    let showIssues: Bool
    @Binding var focusRequest: String?

    @FocusState private var focus: String?
    private var p: Profile { Profile.me }
    private var info: PersonalInfo { p.intake?.personal ?? PersonalInfo() }

    private func err(_ f: String) -> String? { sectionIssue(.person, f, shown: showIssues) }
    private func update(_ f: (inout PersonalInfo) -> Void) { Profile.me.updateIntake { f(&$0.personal) } }

    /// วันเกิดต้องอยู่ในอดีตและอายุถึงเกณฑ์ — ปิดทางเลือกปีผิดตั้งแต่ตัวเลือก ไม่ใช่มาบอกทีหลัง
    private var dobRange: ClosedRange<Date> {
        let cal = Calendar.current
        let hi = cal.date(byAdding: .year, value: -13, to: Date()) ?? Date()
        let lo = cal.date(byAdding: .year, value: -90, to: Date()) ?? Date()
        return lo...hi
    }

    var body: some View {
        SectionScroll(focus: $focus, request: $focusRequest) {
            // `name` — ทั้ง 4 ช่องบังคับเหมือนเว็บ
            PKPanel(title: "ติดต่อคุณได้ทางไหน?") {
                PKField(label: "ชื่อ–นามสกุลจริง", required: true, text: p.binding(.name),
                        placeholder: "เช่น สมหญิง ใจดี", contentType: .name, error: err(PField.name),
                        limit: ProfileField.name.limit, id: PField.name, focus: $focus,
                        onCommit: { Profile.me.commit(TextSlotID(field: .name)) })
                PKField(label: "เบอร์โทรศัพท์", required: true, text: p.binding(.phone),
                        placeholder: "08x-xxx-xxxx", keyboard: .phonePad, contentType: .telephoneNumber,
                        autocap: .never, noCorrect: true, error: err(PField.phone),
                        id: PField.phone, focus: $focus,
                        onCommit: { Profile.me.commit(TextSlotID(field: .phone)) })
                PKField(label: "อีเมล", required: true, text: p.binding(.email), placeholder: "you@email.com",
                        keyboard: .emailAddress, contentType: .emailAddress,
                        autocap: .never, noCorrect: true, error: err(PField.email),
                        id: PField.email, focus: $focus,
                        onCommit: { Profile.me.commit(TextSlotID(field: .email)) })
                PKField(label: "Line ID", required: true, text: p.binding(.lineId), placeholder: "@yourlineid",
                        autocap: .never, noCorrect: true, error: err(PField.line),
                        limit: ProfileField.lineId.limit, id: PField.line, focus: $focus,
                        onCommit: { Profile.me.commit(TextSlotID(field: .lineId)) })
            }

            // `basic`
            PKPanel(title: "ข้อมูลพื้นฐาน") {
                VStack(alignment: .leading, spacing: 7) {
                    PKLabel(text: "วันเกิด", required: true, hint: info.age.map { "อายุ \($0) ปี" })
                    // ยังไม่เลือก = ช่องว่างจริง ๆ — DatePicker โชว์วันที่ตั้งต้นเสมอ ผู้ใช้เลยนึกว่ากรอกแล้วแต่โดนเตือน "เลือกวันเกิด"
                    Group {
                        if info.dob == nil {
                            Button {
                                Haptics.impact(.light)
                                update { $0.dob = Calendar.current.date(byAdding: .year, value: -25, to: Date()) }
                            } label: {
                                HStack {
                                    Text("เลือกวันเกิด").font(.sh(16)).foregroundStyle(PK.hint)
                                    Spacer(minLength: 0)
                                    PIcon(.calendarDots, size: 15).foregroundStyle(PK.hint)
                                }
                                .padding(.horizontal, 5)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            DatePicker("", selection: dobBinding, in: dobRange, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(PK.red)
                                .environment(\.locale, Locale(identifier: "th_TH"))
                        }
                    }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10).frame(minHeight: 46)
                        .background(PK.shape(PK.fieldRadius).fill(PK.fieldFill))
                        .overlay(PK.shape(PK.fieldRadius).strokeBorder(err(PField.dob) != nil ? PK.red : .clear, lineWidth: 1.6))
                    if let e = err(PField.dob) { errorText(e) }
                }
                .id(PField.dob)
                PKField(label: "สัญชาติ", required: true, text: nationBinding, placeholder: "ไทย",
                        error: err(PField.nation), id: PField.nation, focus: $focus)
            }

            // `gender`
            PKPanel(title: "เพศ") {
                PKChoiceGrid(items: IntakeCatalog.genders, label: { $0 }, isOn: { info.gender == $0 }) { g in
                    update { $0.gender = g }
                }
                if let e = err(PField.gender) { errorText(e) }
            }
            .id(PField.gender)

            // `religion`
            PKPanel(title: "นับถือศาสนาอะไร?", subtitle: "ใช้กรองงานที่ขัดกับความเชื่อ") {
                PKChoiceGrid(items: IntakeCatalog.religions, label: { $0 }, isOn: { info.religion == $0 }) { r in
                    update { $0.religion = r }
                }
                if let e = err(PField.religion) { errorText(e) }
            }
            .id(PField.religion)

            // `job` → `faculty` / `field`
            PKPanel(title: "ตอนนี้ทำอะไรอยู่?") {
                PKTileGrid(items: IntakeCatalog.jobs) { j in
                    PKTile(icon: j.icon, title: j.title, detail: j.detail, on: info.job == j.key) {
                        update { d in
                            d.job = j.key
                            if d.job != "student" { d.faculty = "" }
                            if d.job != "work" { d.field = "" }
                        }
                    }
                }
                if let e = err(PField.job) { errorText(e) }
                if info.job == "student" {
                    VStack(alignment: .leading, spacing: 8) {
                        PKLabel(text: "เรียนคณะอะไร?", required: true)
                        PKChoiceGrid(items: IntakeCatalog.faculties, label: { $0 }, isOn: { info.faculty == $0 }) { f in
                            update { $0.faculty = f }
                        }
                        if let e = err(PField.faculty) { errorText(e) }
                    }
                    .id(PField.faculty)
                } else if info.job == "work" {
                    VStack(alignment: .leading, spacing: 8) {
                        PKLabel(text: "ทำงานสายไหน?", required: true)
                        PKChoiceGrid(items: IntakeCatalog.fields, label: { $0 }, isOn: { info.field == $0 }) { f in
                            update { $0.field = f }
                        }
                        if let e = err(PField.field) { errorText(e) }
                    }
                    .id(PField.field)
                }
            }
            .id(PField.job)
            .animation(Motion.settle, value: info.job)
        }
    }

    private var dobBinding: Binding<Date> {
        Binding(get: { info.dob ?? (Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()) },
                set: { v in update { $0.dob = v } })
    }
    private var nationBinding: Binding<String> {
        Binding(get: { info.nationality }, set: { v in update { $0.nationality = v } })
    }

    private func errorText(_ e: String) -> some View {
        Text(e).font(.sh(11.5, .medium)).foregroundStyle(PK.err)
    }
}
