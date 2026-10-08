import SwiftUI
import PhosphorSwift

/// ฟอร์มสมัครเดิมของแอปหลัก (`UnboxRegister`) ตัวต่อตัว — บล็อก "ข้อมูลที่อยู่" กลับมาอยู่ที่นี่ (ผู้ใช้ 6 ต.ค. 2569: "ให้ flow ลงทะเบียนที่อยู่เป็นเหมือนเดิม
/// ไม่ต้องแทรกจังหวะตอบรับ") · ช่อง ลำดับ และป้ายตาม `UnboxRegisterViewController` + `Localized.strings`:
/// ชื่อ - นามสกุล · เบอร์โทรศัพท์ · (Line ID ของเรา) · รายละเอียดที่อยู่ · รหัสไปรษณีย์ → ตำบล/แขวง (เลือก) → อำเภอ/เขต + จังหวัด เติมให้
///
/// NOTE port (`createBrandCampaignApplication` — API เดิมครบ ไม่ต้องแก้):
///   ที่อยู่ 7 ช่องส่งเป็น `name, tel, address, province, district, subDistrict, zipcode` เหมือนเดิม (type non-null — พอดีกับฟอร์มนี้)
///   ตำบลจาก `getSubDistricts(zipcode)` · อำเภอ/จังหวัดจาก `getDistrictProvince(zipcode, subDistrict)` — ที่นี่จำลองด้วย `ZipBook`
///   ไม่มี arg `lineId` → Line ID ลง `creatorProfile.lineId` (`createOrUpdateCreatorProfile`) ก่อนแล้วค่อยยิงสมัคร
///   ลิงก์โซเชียล + ยอดผู้ติดตาม 6 ช่องส่งเหมือนเดิม (`facebook…lemon8`, `*Follower`) · คำถามแบรนด์ = `answers[{question, type, answer}]` เดิม
///
/// ข้อมูลติดต่อ · คำถามของแบรนด์ · การ์ดโซเชียล (+ insight) · ยินยอม · ปุ่มแดงเต็ม
struct RegisterFormPage: View {
    @Environment(StarFlow.self) private var flow
    let campaign: StarCampaign
    let onClose: () -> Void
    let onSubmit: () -> Void

    @State private var answers: [String: String] = [:]
    @State private var checks: Set<String> = []
    @State private var uploaded = false

    var body: some View {
        VStack(spacing: 0) {
            SHNavBar(title: "ลงทะเบียนร่วมกิจกรรม") {
                Color.clear.frame(width: 32, height: 32)
            } right: {
                SHBarIcon(icon: .x, action: onClose)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // = "ADDRESS_SESSION_LABEL" ของแอปหลัก — ชุดเดียวกับ `myAddress` จำไว้ใน `flow.addressInfo` งานถัดไปเติมให้เอง
                    SHSectionHeader(title: "ข้อมูลที่อยู่")
                    VStack(spacing: 14) {
                        SHFormField(label: "ชื่อ - นามสกุล", required: true, text: bind(\.name), placeholder: "กรอกชื่อ - นามสกุล")
                        SHFormField(label: "เบอร์โทรศัพท์", required: true, text: bind(\.tel), placeholder: "กรอกเบอร์โทรศัพท์", keyboard: .phonePad)
                        // Line ID ถามตอนลงทะเบียน (ผู้ใช้ 29 ก.ย. 2569) — จำไว้ใน StarFlow งานถัดไปเติมให้เอง
                        SHFormField(label: "Line ID", required: true, text: Binding(get: { flow.lineID }, set: { flow.lineID = $0 }), placeholder: "@yourlineid", keyboard: .asciiCapable)
                        SHFormField(label: "รายละเอียดที่อยู่", required: true, text: bind(\.address), placeholder: "บ้านเลขที่, ชื่อหมู่บ้าน, ห้อง, ชั้น, ถนน, ซอย", paragraph: true)
                        // รหัสไปรษณีย์เปลี่ยน = ล้างตำบล/อำเภอ/จังหวัด แล้วหาตำบลใหม่ (แอปหลัก: `getSubDistricts` หลังพิมพ์ครบ 0.5 วิ)
                        SHFormField(label: "รหัสไปรษณีย์", required: true, text: Binding(
                            get: { flow.addressInfo.zip },
                            set: { v in
                                let z = String(v.filter(\.isNumber).prefix(5))
                                guard z != flow.addressInfo.zip else { return }
                                flow.addressInfo.zip = z
                                flow.addressInfo.sub = ""; flow.addressInfo.district = ""; flow.addressInfo.province = ""
                                if let only = ZipBook.subs(z).count == 1 ? ZipBook.subs(z).first : nil { pickSub(only) }
                            }), placeholder: "ระบุรหัสไปรษณีย์", keyboard: .numberPad)
                        SHSelectField(label: "ตำบล/แขวง", required: true, text: Binding(get: { flow.addressInfo.sub }, set: pickSub),
                                      options: ZipBook.subs(flow.addressInfo.zip), placeholder: "ตำบล/แขวง")
                        // อำเภอ/จังหวัดเติมให้จากตำบล (แอปหลัก: `getDistrictProvince`) — ช่องยังพิมพ์ทับได้เผื่อรหัสที่ตารางจำลองไม่รู้จัก
                        SHFormField(label: "อำเภอ/เขต", required: true, text: bind(\.district), placeholder: "อำเภอ/เขต")
                        SHFormField(label: "จังหวัด", required: true, text: bind(\.province), placeholder: "จังหวัด")
                    }
                    .padding(16)
                    if !campaign.questions.isEmpty {
                        SHSectionHeader(title: "คำถาม")
                        VStack(alignment: .leading, spacing: 18) {
                            ForEach(campaign.questions) { q in question(q) }
                        }
                        .padding(16)
                    }
                    SHSectionHeader(title: "โซเชียลมีเดีย")
                    VStack(spacing: 10) {
                        HStack(alignment: .top, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                (Text("* ").foregroundStyle(SH.red) + Text("ลิงก์โซเชียลมีเดียที่ต้องการลงทะเบียน").foregroundStyle(SH.ink))
                                    .font(.sh(14, .semibold))
                                Text("(ผูกบัญชีอย่างน้อย 1 ช่องทางเพื่อส่งรีวิว)").font(.sh(12)).foregroundStyle(SH.muted)
                            }
                            Spacer()
                            Text("เพิ่ม/แก้ไขบัญชี").font(.sh(12, .semibold)).foregroundStyle(SH.red)
                                .padding(.horizontal, 10).frame(height: 30)
                                .overlay(Capsule().strokeBorder(SH.red, lineWidth: 1))
                        }
                        ForEach(StarSocial.allCases) { s in socialCard(s) }
                        consent
                    }
                    .padding(16)
                }
                .padding(.bottom, 24)
            }
            .background(.white)
            .scrollDismissesKeyboard(.interactively)
            VStack {
                // กดได้เมื่อยินยอม + Line ID + ที่อยู่ครบ 7 ช่อง (แอปหลัก `validateForm` เช็กทุกช่องบังคับก่อนส่ง)
                SHRedButton(title: "ลงทะเบียนร่วมกิจกรรม", icon: .notePencil,
                            enabled: flow.consent && !flow.lineID.trimmingCharacters(in: .whitespaces).isEmpty && flow.addressInfo.full, action: onSubmit)
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 8)
            .background(Color.white.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { SH.line.frame(height: 1) }
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear(perform: autofill)
    }

    /// กรอกตัวอย่างให้ (แผง lab) — คำตอบของแบรนด์ + Line ID
    /// ช่องที่อยู่ผูกกับ `flow.addressInfo` ตรง ๆ — ฟอร์มนี้คือที่เดียวที่กรอกที่อยู่ใน flow งาน (ตอบรับไม่ถามแล้ว)
    private func bind(_ kp: WritableKeyPath<StarAddress, String>) -> Binding<String> {
        Binding(get: { flow.addressInfo[keyPath: kp] }, set: { flow.addressInfo[keyPath: kp] = $0 })
    }

    /// เลือกตำบลแล้วอำเภอ/จังหวัดตามมา (= `getDistrictProvince` ของแอปหลัก)
    private func pickSub(_ s: String) {
        flow.addressInfo.sub = s
        if let p = ZipBook.place(flow.addressInfo.zip, s) { flow.addressInfo.district = p.district; flow.addressInfo.province = p.province }
    }

    private func autofill() {
        // ชื่อ+เบอร์ แอปหลักเติมจากโปรไฟล์ให้เสมอ (ไม่ขึ้นกับสวิตช์ autofill)
        if flow.addressInfo.name.isEmpty { flow.addressInfo.name = "มณีรัตน์ ใจดี" }
        if flow.addressInfo.tel.isEmpty { flow.addressInfo.tel = "0891234567" }
        guard StarFlow.autofill else { return }
        if flow.lineID.isEmpty { flow.lineID = "@maneerat.review" }
        if flow.addressInfo.address.isEmpty {
            flow.addressInfo = StarAddress(name: flow.addressInfo.name, tel: flow.addressInfo.tel, address: "99/12 คอนโดลุมพินี ซ.สุขุมวิท 77",
                                           district: "สวนหลวง", province: "กรุงเทพมหานคร", zip: "10250", sub: "สวนหลวง")
        }
        for q in campaign.questions where answers[q.id] == nil {
            switch q.kind {
            case .text: answers[q.id] = "เคยรีวิวสกินแคร์ให้หลายแบรนด์ ผิวแพ้ง่าย ใช้จริงก่อนรีวิวทุกครั้ง"
            case .radio: answers[q.id] = q.options.first
            case .checkbox: if checks.isEmpty, let o = q.options.first { checks.insert(o) }
            case .upload: uploaded = true
            }
        }
    }

    @ViewBuilder
    private func question(_ q: CampaignQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            (Text("* ").foregroundStyle(SH.red) + Text(q.q).foregroundStyle(SH.ink)).font(.sh(14, .semibold))
            switch q.kind {
            case .text:
                SHFormField(label: "", text: Binding(get: { answers[q.id] ?? "" }, set: { answers[q.id] = $0 }), placeholder: "กรอกคำตอบ", paragraph: true)
            case .radio:
                Menu {
                    ForEach(q.options, id: \.self) { o in Button(o) { answers[q.id] = o } }
                } label: {
                    HStack {
                        Text(answers[q.id] ?? "เลือกคำตอบ").font(.sh(15)).foregroundStyle(answers[q.id] == nil ? SH.hint : SH.ink)
                        Spacer()
                        PIcon(.caretDown, size: 14).foregroundStyle(SH.hint)
                    }
                    .padding(.horizontal, 14).frame(height: 46)
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(SH.line, lineWidth: 1))
                }
            case .checkbox:
                Text("เลือกได้มากกว่า 1 ตัวเลือก").font(.sh(12)).foregroundStyle(SH.muted)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(q.options, id: \.self) { o in
                        let on = checks.contains(o)
                        Button {
                            Haptics.impact(.light)
                            if on { checks.remove(o) } else { checks.insert(o) }
                        } label: {
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous).fill(on ? SH.red : .white)
                                    .frame(width: 20, height: 20)
                                    .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(on ? SH.red : SH.line, lineWidth: 1.2))
                                    .overlay { if on { PIcon(.check, size: 12).foregroundStyle(.white) } }
                                Text(o).font(.sh(14)).foregroundStyle(SH.ink)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .upload:
                HStack(spacing: 10) {
                    if uploaded {
                        Image("ph03").resizable().aspectRatio(contentMode: .fill).frame(width: 84, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    Button {
                        Haptics.impact(.light)
                        uploaded = true
                    } label: {
                        VStack(spacing: 4) {
                            PIcon(.plus, size: 20)
                            Text("เพิ่มรูป").font(.sh(12, .semibold))
                        }
                        .foregroundStyle(SH.muted)
                        .frame(width: 84, height: 84)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(SH.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func socialCard(_ s: StarSocial) -> some View {
        let on = flow.connected.contains(s)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if on {
                    SHAvatar(size: 44).overlay(Circle().strokeBorder(SH.line, lineWidth: 1))
                } else {
                    Image(s.icon).resizable().aspectRatio(contentMode: .fit).frame(width: 44, height: 44).clipShape(Circle())
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(on ? flow.handle(s) : s.name.uppercased()).font(.sh(14, .bold)).foregroundStyle(SH.ink)
                    if on { Text(flow.link(s)).font(.sh(11)).foregroundStyle(SH.muted).lineLimit(1) }
                }
                Spacer()
                Text(on ? "ผูกบัญชีแล้ว" : "ยังไม่ได้ผูกบัญชี").font(.sh(11, .semibold))
                    .foregroundStyle(on ? SHColor.green : SH.muted)
                    .padding(.horizontal, 8).frame(height: 24)
                    .background(Capsule().fill(on ? SHColor.greenSoft : SH.page))
            }
            if on {
                HStack(spacing: 4) {
                    PIcon(.usersThree, size: 14, weight: .regular)
                    Text("\(StarFlow.fmt(flow.followers(s))) ผู้ติดตาม").font(.sh(12, .medium))
                }
                .foregroundStyle(SH.muted)
                if s.supportsInsight {
                    let n = ["gender", "age", "location"].filter { flow.insightSlots.contains("\(s.rawValue)_\($0)") }.count
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("ข้อมูลผู้ติดตาม").font(.sh(13, .semibold)).foregroundStyle(SH.ink)
                                if n >= 3 { PIcon(.checkCircle, size: 16, weight: .fill).foregroundStyle(SHColor.green) }
                                else { Text("\(n)/3").font(.sh(11, .bold)).foregroundStyle(n > 0 ? SH.amber : SH.muted).padding(.horizontal, 6).frame(height: 18).background(Capsule().fill(SH.page)) }
                            }
                            Text(n >= 3 ? "อัปเดตล่าสุด 12 ก.ย. 69" : "อัปโหลดรูป Insight เพศ / ช่วงอายุ / พื้นที่ยอดนิยม")
                                .font(.sh(11)).foregroundStyle(n > 0 && n < 3 ? SH.amber : SH.muted)
                        }
                        Spacer()
                        Text(n >= 3 ? "อัปเดตข้อมูล" : "เพิ่มข้อมูล").font(.sh(12, .semibold))
                            .foregroundStyle(n >= 3 ? SH.red : .white)
                            .padding(.horizontal, 10).frame(height: 30)
                            .background(Capsule().fill(n >= 3 ? .white : SH.red))
                            .overlay(Capsule().strokeBorder(SH.red, lineWidth: 1))
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(SH.page))
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(on ? SHColor.green.opacity(0.5) : SH.line, lineWidth: 1))
    }

    private var consent: some View {
        Button {
            Haptics.impact(.light)
            flow.consent.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 4, style: .continuous).fill(flow.consent ? SH.red : .white)
                    .frame(width: 22, height: 22)
                    .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(flow.consent ? SH.red : SH.line, lineWidth: 1.2))
                    .overlay { if flow.consent { PIcon(.check, size: 13).foregroundStyle(.white) } }
                VStack(alignment: .leading, spacing: 4) {
                    Text("ฉันยอมรับข้อกำหนดและเงื่อนไข").font(.sh(14, .bold)).foregroundStyle(SH.ink)
                    Text("ฉันยินยอมที่จะโพสต์รีวิวสินค้า และเปิดเป็นสาธารณะ ตามช่องทางโซเชียลมีเดียที่ลงทะเบียนไว้ภายหลังจากได้รับกล่อง Unbox หากไม่ได้รีวิวตามเวลาที่กำหนด ฉันจะถูกตัดสิทธิ์และไม่สามารถลงทะเบียนเข้าร่วมกิจกรรม ‘Sale Here UNBOX’ ได้อีกในครั้งต่อไป")
                        .font(.sh(12)).foregroundStyle(SH.muted).lineSpacing(3)
                }
            }
            .padding(.top, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// หัวข้อหมวดในฟอร์มของแอปหลัก — แถบเทาอ่อน ตัวหนา
struct SHSectionHeader: View {
    let title: String
    var body: some View {
        Text(title).font(.sh(15, .bold)).foregroundStyle(SH.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).frame(height: 40)
            .background(SH.page)
    }
}

/// ช่องกรอกของแอปหลัก — ป้ายด้านบน (ดอกจันแดง) + กล่องขอบเทา
struct SHFormField: View {
    let label: String
    var required = false
    @Binding var text: String
    var placeholder = ""
    var keyboard: UIKeyboardType = .default
    var paragraph = false
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !label.isEmpty {
                (Text(required ? "* " : "").foregroundStyle(SH.red) + Text(label).foregroundStyle(SH.ink)).font(.sh(14, .semibold))
            }
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(SH.hint), axis: paragraph ? .vertical : .horizontal)
                .font(.sh(15)).foregroundStyle(SH.ink).tint(SH.red)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .asciiCapable ? .never : nil)
                .autocorrectionDisabled(keyboard == .asciiCapable)
                .lineLimit(paragraph ? 3...6 : 1...1)
                .focused($focused)
                .padding(.horizontal, 14).padding(.vertical, paragraph ? 12 : 0)
                .frame(minHeight: 46)
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(focused ? SH.red : SH.line, lineWidth: 1))
        }
    }
}

/// ช่องเลือก (= `BaseSelectViewV2` ของแอปหลัก) — รายการว่าง (รหัสที่ตารางจำลองไม่รู้จัก) ให้พิมพ์เองแทน
struct SHSelectField: View {
    let label: String
    var required = false
    @Binding var text: String
    var options: [String]
    var placeholder = ""
    var body: some View {
        if options.isEmpty {
            SHFormField(label: label, required: required, text: $text, placeholder: placeholder)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                (Text(required ? "* " : "").foregroundStyle(SH.red) + Text(label).foregroundStyle(SH.ink)).font(.sh(14, .semibold))
                Menu {
                    ForEach(options, id: \.self) { o in Button(o) { text = o } }
                } label: {
                    HStack {
                        Text(text.isEmpty ? placeholder : text).font(.sh(15)).foregroundStyle(text.isEmpty ? SH.hint : SH.ink)
                        Spacer()
                        PIcon(.caretDown, size: 14).foregroundStyle(SH.hint)
                    }
                    .padding(.horizontal, 14).frame(height: 46)
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(SH.line, lineWidth: 1))
                    .contentShape(Rectangle())
                }
            }
        }
    }
}

/// dialog "ลงทะเบียนสำเร็จ" ของแอปหลัก (`AnimatedConfirmDialog`) — ชวนยืนยันตัวตนถ้ายังไม่ผ่าน
struct RegisterSuccessDialog: View {
    @Environment(StarFlow.self) private var flow
    let onClose: () -> Void
    let onKyc: () -> Void
    @State private var pop = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 12) {
                ZStack {
                    Circle().fill(SHColor.greenSoft).frame(width: 96, height: 96)
                    Circle().fill(SHColor.green).frame(width: 72, height: 72)
                    PIcon(.check, size: 36).foregroundStyle(.white)
                }
                .scaleEffect(pop ? 1 : 0.4).opacity(pop ? 1 : 0)
                .padding(.top, 6)
                Text("ลงทะเบียนสำเร็จ").font(.sh(19, .bold)).foregroundStyle(SH.ink)
                Text("ผู้ที่ผ่านการคัดเลือกจะได้รับการแจ้งเตือน\nให้ยืนยันสิทธิ์ผ่านแอปฯ Sale Here")
                    .font(.sh(14)).foregroundStyle(SH.muted).multilineTextAlignment(.center).lineSpacing(3)
                // ยืนยันตัวตนไปแล้ว (ผ่านหรือรอตรวจ) = ไม่ชวนซ้ำ (ผู้ใช้ 24 ก.ย.)
                let kycDone = flow.isMember   // ตีกลับ (`reject`) = ชวนทำใหม่
                if !kycDone {
                    Text("*กรุณายืนยันตัวตน เพื่อความรวดเร็ว ในการผ่านการคัดเลือก!!")
                        .font(.sh(12, .semibold)).foregroundStyle(SH.red).multilineTextAlignment(.center)
                } else if flow.verify == .waiting {
                    Text("ส่งยืนยันตัวตนแล้ว · ทีมงานตรวจภายใน 1–3 วันทำการ")
                        .font(.sh(12, .semibold)).foregroundStyle(SH.muted).multilineTextAlignment(.center)
                }
                VStack(spacing: 8) {
                    if kycDone {
                        SHRedButton(title: "แชร์กิจกรรมนี้", icon: .shareFat, height: 46, action: onClose)
                    } else {
                        Button {
                            Haptics.impact(.light)
                            onClose()
                        } label: {
                            HStack(spacing: 8) { PIcon(.shareFat, size: 18, weight: .regular); Text("แชร์กิจกรรมนี้").font(.sh(15, .semibold)) }
                                .foregroundStyle(SH.ink).frame(maxWidth: .infinity).frame(height: 46)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(PK.fieldFill))
                        }
                        .buttonStyle(.plain)
                        SHRedButton(title: "ยืนยันตัวตน", icon: .identificationCard, height: 46, action: onKyc)
                    }
                }
                .padding(.top, 6)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
            .overlay(alignment: .topTrailing) {
                Button { onClose() } label: {
                    PIcon(.x, size: 16).foregroundStyle(SH.muted).frame(width: 36, height: 36).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 30)
        }
        .transition(.opacity)
        .onAppear { withAnimation(Motion.lift.delay(0.1)) { pop = true } }
    }
}
