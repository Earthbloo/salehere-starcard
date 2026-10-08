import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import PhosphorSwift

/// หน้าแทรก = wizard "หนึ่งคำถามต่อหนึ่งหน้า" (= `wizard()` ใน newflow.js)
///
/// หัวข้อ 1 บรรทัด · ชิปบอกว่าแบรนด์ใช้ข้อนี้ทำอะไร · ช่องกรอกเดียว · ปุ่มถัดไป · แถบความคืบหน้า
/// ขั้นที่มีข้อมูลแล้วไม่โผล่เลย · หน้าสุดท้ายปุ่มบอกปลายทาง (ฟอร์มสมัคร / หน้าตอบรับ / การ์ด)
struct StarWizard: View {
    @Environment(StarFlow.self) private var flow
    let kind: WizKind
    let campaign: StarCampaign
    @State var steps: [WizStep]
    /// ข้อที่ผู้เรียกขอจริง ก่อนรวมเป็นหน้า — หน้ารวม (ช่องทาง+เรท+insight · แนะนำตัว+ผลงาน) วาดเฉพาะส่วนที่ขอ
    /// "เติมข้อมูลต่อ" ส่งมาแค่ข้อที่ยังขาด จึงเห็นแค่ช่องที่ยังไม่กรอก (ผู้ใช้ 1 ต.ค. 2569)
    private let asked: Set<WizStep>
    /// จบ wizard — `madeCard` = รอบนี้เพิ่งประกอบการ์ดขึ้นมา (ไปหน้าการ์ดเกิดก่อนฟอร์มสมัคร)
    let onFinish: (_ madeCard: Bool) -> Void
    /// กด ✕ ที่ขั้นแรก — ผู้เรียกเปิด dialog "เก็บไว้ทำต่อทีหลังไหม" (ส่งจำนวนที่ทำแล้ว/ทั้งหมดไปให้)
    let onExit: (_ done: Int, _ total: Int) -> Void
    /// ออกไปยืนยันตัวตนจริง แล้วเรียก completion ตอนกลับมา
    let onKyc: (@escaping () -> Void) -> Void
    /// ข้อนี้ทำให้ครบ 8 ข้อพอดี = ได้เป็น STAR กลางทาง — shell เล่น motion "คุณเป็น STAR แล้ว" แล้ว wizard ค่อยไปข้อถัดไปใต้ motion
    let onStar: () -> Void
    /// toast ของผู้เรียก
    let toast: (String) -> Void

    @State private var i = 0
    /// แผงล่างของหน้าช่องทาง (แก้เรท / แนบ insight) — วาดเองใน wizard เพราะ `.sheet` ไม่เปิดในหน้าที่ shell สลับ `.id`
    @State private var editing: StarSocial?
    @State private var insightFor: StarSocial?
    /// ช่องสัดส่วนที่กำลังหมุนเลือก (wheel picker ค่า + หน่วย ต่อช่อง = MultiWheelPickerModal ของ salehere-ios)
    @State private var bodyPick: BodyField?
    @State private var err: String?
    @State private var shakes = 0
    /// ค่าช่องพิมพ์ตอนเปิด wizard (ก่อนกรอกตัวอย่าง) — เป็น STAR แล้วบันทึกช่องที่เคยกรอกเป็นค่าว่างไม่ได้ (`StarFlow.keepsData`)
    @State private var before: [String: String] = [:]
    /// error ที่ช่อง (ไม่ใช่หัวหน้า) + ช่องที่ต้องเลื่อนไปให้เห็น
    @State private var errors = WzErrors()
    @State private var scrollTo: String?
    /// สภาพตอนเปิด wizard (= `initialSnapshot` ของ salehere-ios): เป็น STAR อยู่แล้วไหม · ข้อไหนใน 8 ข้อที่ขาดอยู่
    @State private var startStar = StarFlow.shared.isStar
    @State private var startMissing = StarFlow.shared.starMissing

    init(kind: WizKind, campaign: StarCampaign, steps: [WizStep],
         onFinish: @escaping (Bool) -> Void, onExit: @escaping (Int, Int) -> Void,
         onKyc: @escaping (@escaping () -> Void) -> Void, onStar: @escaping () -> Void = {}, toast: @escaping (String) -> Void,
         start: Int = 0) {
        self.kind = kind; self.campaign = campaign; _steps = State(initialValue: WizStep.pages(steps))
        // เปิดที่ข้อ `start` — ใช้แค่ทางลัดแคปจอ (`-shot wiz:…`)
        _i = State(initialValue: start)
        self.asked = Set(steps)
        self.onFinish = onFinish; self.onExit = onExit; self.onKyc = onKyc; self.onStar = onStar; self.toast = toast
    }

    private var real: [WizStep] { steps.filter { $0 != .intro } }
    private var step: WizStep? { steps.indices.contains(i) ? steps[i] : nil }
    private var isLast: Bool { i == steps.count - 1 }
    /// ลำดับข้อ (ไม่นับ intro)
    private var n: Int { steps.prefix(i + 1).filter { $0 != .intro }.count }
    /// หน้าช่องทางนับว่าทำแล้วเมื่อมีช่องทาง + เรท (ข้อมูลผู้ติดตามไม่บังคับ)
    private func stepDone(_ s: WizStep) -> Bool {
        if s == .kyc { return flow.isVerified }
        if s == .socials { return flow.has(.socials) && flow.has(.rate) }
        return s.dataKey.map(flow.has) ?? false
    }

    var body: some View {
        ZStack {
            GL.bg.ignoresSafeArea()
            if let step {
                if step == .intro { intro } else { page(step) }
            } else {
                empty
            }
            if let s = editing {
                BottomPanel(close: { closePanel() }) { ChannelSheet(social: s) { fresh in afterChannel(s, fresh: fresh) } }
                    .zIndex(2)
            }
            if let s = insightFor {
                BottomPanel(close: { closePanel() }) { InsightPanel(social: s) { closePanel() } }
                    .zIndex(2)
            }
            if let f = bodyPick {
                BottomPanel(close: { bodyPick = nil }) { BodyWheelSheet(field: f) { bodyPick = nil } }
                    .zIndex(2)
            }
        }
        .animation(Motion.settle, value: editing)
        .animation(Motion.settle, value: insightFor)
        .animation(Motion.settle, value: bodyPick)
        .preferredColorScheme(.light)
        .onAppear {
            before = Dictionary(Self.kept(flow).values.joined().map { ($0.key, $0.value) }, uniquingKeysWith: { a, _ in a })
            flow.autofill(Array(asked))
        }
    }

    // MARK: หน้าแรกก่อนสมัคร = "สมัครเป็น STAR" (1 เหตุผล + 1 ภาพ + 1 ปุ่ม) (= `wizIntro`)

    private var intro: some View {
        // ยังไม่เป็น STAR (ยังไม่ครบ 8 ข้อ) = หัว "สมัครเป็น STAR ก่อน" เสมอ — ไม่ใช่แค่ยังไม่มีการ์ด (ผู้ใช้ 6 ต.ค. 2569)
        let rest = real, card = flow.isStar
        return ZStack {
            GlassOrbs()
            VStack(spacing: 0) {
                HStack {
                    // ✕ หน้า intro = ออกเงียบ ๆ (ยังไม่ได้ทำอะไร ไม่ถาม "เก็บไว้ทำต่อไหม") — salehere-ios
                    GlassCircleButton(symbol: .x, size: 40) { onExit(0, 0) }
                    Spacer()
                    // "สมัคร {ชื่อกิจกรรม}" ทั้งสถานะ A และ C (= `STAR_INTRO_CONTEXT`)
                    Text("สมัคร \(campaign.title)").font(.sh(12.5, .semibold)).foregroundStyle(PK.hint).lineLimit(1)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20).padding(.top, 6)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if card {
                            // เป็น STAR แล้ว — หน้านี้ไม่ใช่เรื่องการ์ด แต่เป็นสิ่งที่แบรนด์ขอดูก่อนคัดเลือก (ผู้ใช้ 24 ก.ย. 2569)
                            GlassTitle(words: [("แบรนด์ขอข้อมูลเพิ่ม", false)], small: true)
                            Text("ใช้คัดเลือกผู้สมัคร · ส่งครบแล้วค่อยไปฟอร์มสมัคร")
                                .font(.sh(14)).foregroundStyle(GL.muted).multilineTextAlignment(.center)
                                .padding(.top, 10)
                            // การ์ดเดียวกับสถานะ A + ช่องประ 1 ช่องต่อ 1 ข้อที่ขาด (salehere-ios) — ต่างแค่หัวกับปุ่ม
                            StarGlassCard(compact: true, ghosts: rest)
                                .padding(.top, 26)
                                .modifier(PKReveal(index: 1))
                        } else {
                            GlassTitle(words: [("สมัครเป็น", false), ("STAR", true), ("ก่อน", false)], small: true)
                            StarText("งานนี้รับเฉพาะ STAR · ทำครั้งเดียว ใช้ได้ทุกงาน", size: 14, weight: .regular, color: GL.muted)
                                .padding(.top, 10)
                            StarGlassCard(compact: true, ghosts: rest)
                                .padding(.top, 26)
                                .modifier(PKReveal(index: 1))
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 30).padding(.bottom, 16)
                }
                PKPrimaryButton(title: card ? "เติมข้อมูล · \(rest.count) ข้อ" : "สมัครเป็น STAR · \(rest.count) ข้อ", symbol: .arrowRight) { next() }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 20)
            }
        }
    }

    // MARK: หน้าคำถาม

    private func page(_ step: WizStep) -> some View {
        let total = real.count
        return VStack(spacing: 0) {
            HStack {
                PKCircleButton(symbol: i > 0 ? .caretLeft : .x, label: i > 0 ? "ย้อนกลับ" : "ปิด") {
                    if i > 0 { withAnimation(Motion.snap) { i -= 1; err = nil; errors.reset() } }
                    else { onExit(real.filter(stepDone).count, total) }
                }
                Spacer()
                StarText(context, size: 12.5, weight: .semibold, color: PK.hint)
                Spacer()
                HStack(spacing: 8) {
                    Text(total > 1 ? "\(n)/\(total)" : "").font(.sh(12.5, .bold)).foregroundStyle(GL.ink).monospacedDigit()
                    if i > 0 {
                        // ออกได้ทุกขั้น ไม่ต้องถอยกลับไปหา ✕ ที่ขั้นแรก (audit ข้อ 5) — dialog "เก็บไว้ทำต่อ" ตัวเดิม
                        PKCircleButton(symbol: .x, label: "ปิด") { onExit(real.filter(stepDone).count, total) }
                    }
                }
                .frame(minWidth: 40, alignment: .trailing)
            }
            .padding(.horizontal, 20).padding(.top, 6)
            if !(kind == .one && total < 2) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(PK.line)
                        Capsule().fill(PK.charcoal).frame(width: g.size.width * CGFloat(n) / CGFloat(max(1, total)))
                            .animation(Motion.settle, value: n)
                    }
                }
                .frame(height: 3).padding(.horizontal, 20).padding(.top, 10)
            }
            ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(heading(step)).font(.sh(24, .heavy)).foregroundStyle(GL.ink).lineSpacing(4)
                    if !lines(step).isEmpty {
                        NudgeChips(lines: lines(step)).padding(.top, 8).padding(.bottom, 20)
                    } else {
                        Text(purpose(step)).font(.sh(14)).foregroundStyle(PK.muted).padding(.top, 6).padding(.bottom, 22)
                    }
                    if let err {
                        Text(err).font(.sh(13, .semibold)).foregroundStyle(PK.red).padding(.bottom, 14)
                            .transition(.opacity)
                    }
                    control(step)
                        .environment(errors)
                        .modifier(WzShake(trigger: shakes))
                }
                .padding(.horizontal, 20).padding(.top, 28).padding(.bottom, 16)
                .id(step)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            }
            .scrollDismissesKeyboard(.interactively)
            // ช่องแรกที่ผิดเลื่อนมากลางจอ
            .onChange(of: scrollTo) { _, k in
                guard let k else { return }
                withAnimation(Motion.settle) { proxy.scrollTo("wz:" + k, anchor: .center) }
                scrollTo = nil
            }
            }
            VStack(spacing: 8) {
                PKPrimaryButton(title: buttonLabel, symbol: .arrowRight) { next() }
                if step.optional {
                    GlassLink(title: "ข้ามไว้ก่อน") { skip() }
                }
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 20)
        }
    }

    /// ผูกช่องใหม่เสร็จ → พาไปแนบข้อมูลผู้ติดตามของช่องนั้นต่อทันที (ผู้ใช้ 1 ต.ค. 2569: "insight ดูไม่สำคัญ ผูกเสร็จพาไปต่อเลย")
    private func afterChannel(_ s: StarSocial, fresh: Bool) {
        closePanel()
        if flow.connected.isEmpty { return }
        guard fresh, s.supportsInsight else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { insightFor = s }
    }

    private func closePanel() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        editing = nil; insightFor = nil
    }

    private var empty: some View {
        VStack(spacing: 0) {
            HStack { PKCircleButton(symbol: .x, label: "ปิด") { onExit(0, 0) }; Spacer() }.padding(.horizontal, 20).padding(.top, 6)
            Spacer()
            Text("ข้อมูลครบแล้ว").font(.sh(24, .heavy)).foregroundStyle(GL.ink)
            Spacer()
            PKPrimaryButton(title: kind == .apply ? "ไปฟอร์มสมัคร" : kind == .one ? "กลับ" : "ไปหน้าตอบรับ", symbol: .arrowRight) { finish() }
                .padding(.horizontal, 20).padding(.bottom, 20)
        }
    }

    private var context: String {
        switch kind {
        case .one: return flow.isStar ? "เติมข้อมูล" : "สมัครเป็น STAR"
        case .apply: return flow.isStar ? "ข้อมูล STAR · ก่อนสมัคร \(campaign.episode)" : "สมัครเป็น STAR · \(campaign.episode)"
        case .accept: return "ข้อมูล STAR · ก่อนตอบรับ \(campaign.episode)"
        }
    }

    private var buttonLabel: String {
        // เป็นเรื่องข้อมูล ไม่ใช่การ์ด (ผู้ใช้ 29 ก.ย. 2569) — บางข้อไม่ขึ้นการ์ดด้วยซ้ำ
        // ติดด่านยืนยันตัวตน (รอตรวจ/ตีกลับ) = ไปต่อไม่ได้ ปิดเก็บคำตอบไว้ก่อน — มาก่อน "บันทึก" ของ wizard ข้อเดียว
        if step == .kyc, flow.verify == .waiting || flow.verify == .rejected { return "ปิดไว้ก่อน" }
        if kind == .one && isLast { return "บันทึก" }
        if isLast {
            switch kind {
            case .apply: return "ไปฟอร์มสมัคร"
            case .accept: return "ไปหน้าตอบรับ"
            case .one: return "ไปการ์ดของคุณ"
            }
        }
        return "ถัดไป"
    }

    private func heading(_ s: WizStep) -> String {
        switch s {
        case .kind: return "คุณเป็นแบบไหน? 🙋"
        case .socials where !asked.contains(.socials):
            return asked.contains(.rate) ? "เรทรับงานของคุณ 💸" : "ข้อมูลผู้ติดตามของคุณ 📊"
        case .socials: return "แปะวาร์ปช่องของคุณเลย 📱"
        case .categories: return "คุณเป็นครีเอเตอร์สายไหน? 🎨"
        case .about: return "แนะนำตัวสั้น ๆ ✍️"
        case .media: return "เกี่ยวกับคุณ 📸"
        case .rate: return "เรทรับงานของคุณ 💸"
        case .insight: return "ข้อมูลผู้ติดตามของคุณ 📊"
        case .province: return "อยู่จังหวัดไหน / ไปถึงไหนได้บ้าง? 📍"
        case .availability: return "ว่างรับงานวันไหน? 📅"
        case .contact: return "ให้แบรนด์ทักทางไหน? 💬"
        case .address: return "ส่งของไปที่ไหน? 📦"
        case .bank: return "รับเงินในนามใคร? 🏦"
        case .draftRounds: return "แก้งานให้ได้กี่รอบ?"
        case .limits: return "มีงานแนวไหนที่ขอผ่านไหม? 🙅‍♀️"
        case .religion: return "นับถือศาสนาอะไร?"
        case .body: return "สัดส่วนของคุณ 📏"
        case .kyc:
            switch flow.verify {
            case .approved: return "ยืนยันตัวตนแล้ว 🪪"
            case .waiting: return "ทีมงานกำลังตรวจเอกสาร 🪪"
            case .rejected: return "เอกสารยังไม่ผ่าน 🪪"
            case .none: return "ยืนยันตัวตนก่อนสมัคร 🪪"
            }
        case .intro: return ""
        }
    }

    private func purpose(_ s: WizStep) -> String {
        switch s {
        case .address: return "ของรางวัลจะส่งมาที่นี่ · กรอกครั้งเดียว"
        // จาก Star Profile (`.one`) ไม่ได้ผูกกับงานไหน — ไม่อ้างค่าตัวของงาน
        case .bank: return "ใช้กับทุกงานที่มีค่าตัว"
        case .kyc:
            switch flow.verify {
            case .approved: return "ป้าย Verified จะขึ้นบนการ์ดของคุณ"
            case .waiting: return "ทีมงานแจ้งผลภายใน 3 วันทำการ · ผ่านแล้วเราจะเตือนให้กลับมาสมัครต่อ"
            case .rejected: return "ส่งใหม่ได้เลย · ผ่านแล้วค่อยสมัครต่อ"
            case .none: return "ต้องผ่านก่อนส่งใบสมัคร · ถ่ายบัตรประชาชน + ใบหน้า ทำครั้งเดียวใช้ได้ทุกงาน"
            }
        default: return ""
        }
    }

    /// ชิปใต้หัวข้อ — หน้ารวมที่มาเติมแค่บางส่วน ใช้ชิปของส่วนนั้น
    private func lines(_ s: WizStep) -> [String] {
        if s == .socials && !asked.contains(.socials) { return (asked.contains(.rate) ? WizStep.rate : .insight).line }
        // ขั้น KYC ตอนรอตรวจ/ตีกลับ = ชิปชุดเดียวกับหน้าสถานะ
        if s == .kyc, flow.verify == .waiting { return ["แจ้งผลภายใน 3 วันทำการ", "คำตอบที่กรอกไว้ยังอยู่ครบ"] }
        if s == .kyc, flow.verify == .rejected { return ["ส่งใหม่ได้เลย ไม่ต้องรอ", "คำตอบที่กรอกไว้ยังอยู่ครบ"] }
        return s.line
    }

    /// แนะนำตัวขึ้นเมื่อขอข้อนี้ หรือยังไม่เคยกรอก (ขั้นสมัครส่งมาแค่ `.media` แต่ยังถามแนะนำตัวในหน้าเดียวกัน)
    /// เข้าจากแถวใน Star Profile (`.one`) = หน้าเต็มเสมอ: แนะนำตัว + รูป · ผลงาน · คลิป ไม่ว่าจะแตะแถว "แนะนำตัว" หรือ "รูปและผลงาน"
    /// (ผู้ใช้ 7 ต.ค. 2569: "อยู่ใน UI เดียวกัน แต่พอเข้าจากหัวข้อมันแยกกันทำไม")
    /// หน้า "เกี่ยวกับคุณ" = แนะนำตัว + รูป · ผลงาน · คลิป ครบเสมอ ไม่ว่าเข้าจากทางไหน (salehere-ios `showAbout` = true)
    private let showAbout = true
    private let withMedia = true

    @ViewBuilder
    private func control(_ s: WizStep) -> some View {
        switch s {
        case .kind: WzKind()
        // ช่องทางครบแล้ว (มาเติมแค่เรท/insight) = ไม่โชว์แถวช่องที่ยังไม่เชื่อม
        case .socials, .rate, .insight: WzChannels(editing: $editing, insightFor: $insightFor, connectable: asked.contains(.socials))
        case .categories: WzCategories()
        case .about, .media:
            // แนะนำตัว (ไม่บังคับ) อยู่บนสุด ต่อด้วยรูป · ผลงาน · คลิป
            VStack(alignment: .leading, spacing: 22) {
                if showAbout {
                    VStack(alignment: .leading, spacing: 10) {
                        if withMedia {
                            HStack(spacing: 6) {
                                Text("แนะนำตัว").font(.sh(15, .bold)).foregroundStyle(GL.ink)
                                Text("ไม่บังคับ").font(.sh(11, .semibold)).foregroundStyle(PK.muted)
                                    .padding(.horizontal, 7).frame(height: 18).background(Capsule().fill(PK.fieldFill))
                            }
                        }
                        WzAbout(minHeight: 84)
                    }
                }
                if withMedia { WzMediaAll(onError: fail) }
            }
        case .kyc: WzKyc(start: startKyc, toast: toast)
        case .province: WzProvince()
        case .availability: WzAvailability()
        case .contact: WzContact()
        case .address: WzAddress()
        case .bank: WzBank()
        case .draftRounds: WzDraftRounds()
        case .limits: WzLimits()
        case .religion: WzReligion()
        case .body: WzBody(pick: $bodyPick)
        case .intro: EmptyView()
        }
    }

    // MARK: ลอจิก (= `Ac.wizNext` / `wizSkip` / `wizKyc`)

    private func next() {
        guard let step else { finish(); return }
        let wasStar = flow.isStar
        if step == .socials, flow.connected.isEmpty {
            // เป็น STAR แล้วเอาช่องทางออกได้หมด (ผู้ใช้ 7 ต.ค. 2569) — บันทึกได้เลย ลงทะเบียนงานถัดไปค่อยถามใหม่
            // เอาออกจนหมดได้เฉพาะตอนแก้ · เข้ามาเพราะข้อนี้ขาด (รวม STAR เก่าที่ถูกบังคับเติม) = ต้องเชื่อมก่อน (salehere-ios)
            guard flow.keepsData, !startMissing.contains(.socials) else { fail("เชื่อมอย่างน้อย 1 ช่อง"); return }
            flow.have.subtract([.socials, .rate, .insight])
            err = nil; advance(); return
        }
        if flow.keepsData, let gone = Self.kept(flow)[step]?.first(where: { k in
            !(before[k.key] ?? "").trimmingCharacters(in: .whitespaces).isEmpty && k.value.trimmingCharacters(in: .whitespaces).isEmpty
        }) {
            failAt([(gone.key, "\(gone.name)ลบไม่ได้ · แก้เป็นข้อมูลใหม่ได้")]); return
        }
        // ด่านแข็ง (ผู้ใช้ 6 ต.ค. 2569): ต้อง "ผ่าน" ก่อนถึงไปฟอร์มได้ · รอตรวจ/ตีกลับ = ปุ่มกลายเป็น "ปิดไว้ก่อน" เก็บคำตอบไว้ครบ
        if step == .kyc, !flow.isVerified {
            // "ปิดไว้ก่อน" = ปิดเงียบ ๆ กลับหน้าเดิม (ส่ง done = total → Shell ออกเลย ไม่ถาม "เก็บไว้ทำต่อไหม" เพราะไม่มีอะไรให้ทำต่อระหว่างรอ)
            if flow.verify == .waiting || flow.verify == .rejected { onExit(steps.count, steps.count); return }
            fail("ยืนยันตัวตนก่อน แล้วไปต่อได้เลย"); return
        }
        if step == .media, withMedia, !WzMediaAll.lack().isEmpty { failAt(WzMediaAll.lack().map { ("media:\($0.kind)", "ยังขาด \($0.text)") }); return }
        if step == .media, !flow.about.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { flow.have.insert(.about) }
        // ขั้นต่ำ 3 = กติกา welcome step ของ salehere-ios (`CategoriesSelectorPageViewController`) — ใช้เท่ากันจะได้ไม่ต้องแก้ด่านเดิม
        if step == .categories, flow.categories.count < 3 { fail("เลือกอย่างน้อย 3 สาย"); return }
        if step == .province, flow.provinces.isEmpty { fail("เลือกอย่างน้อย 1 จังหวัด"); return }
        if step == .availability, flow.availDays.isEmpty { fail("เลือกช่วงที่ว่างอย่างน้อย 1 ช่อง"); return }
        if step == .contact {
            // ตรวจทั้ง 3 ช่องรอบเดียว error ขึ้นใต้ช่อง · ว่างทั้งคู่ = LINE ขอบแดง + ข้อความใต้ช่องเบอร์ · แก้ช่องไหนหายเฉพาะช่องนั้น (salehere-ios)
            let line = flow.lineID.trimmingCharacters(in: .whitespaces), tel = flow.phone.trimmingCharacters(in: .whitespaces)
            if line.isEmpty && tel.isEmpty { failAt([("LINE ID", ""), ("เบอร์โทร", "ใส่ LINE ID หรือเบอร์อย่างน้อย 1 ช่อง")]); return }
            let web = StarFlow.normalizedWebsite(flow.website)
            var bad: [(String, String)] = []
            if !line.isEmpty, !StarFlow.validLine(line) { bad.append(("LINE ID", "LINE ID ไม่ถูกต้อง")) }
            if !tel.isEmpty, !StarFlow.validPhone(tel) { bad.append(("เบอร์โทร", "เบอร์โทรศัพท์ไม่ถูกต้อง")) }
            if !web.isEmpty, !StarFlow.validURL(web) { bad.append(("เว็บไซต์ · ไม่บังคับ", "เว็บไซต์ไม่ถูกต้อง")) }
            guard bad.isEmpty else { failAt(bad); return }
            flow.website = web
        }
        if step == .address {
            // ครบ 7 ช่องแบบที่ `createUserAddress` บังคับ · รหัสไปรษณีย์ต้อง 5 หลัก (salehere-ios)
            let a = flow.addressInfo
            var bad = Self.empty([("ชื่อ–นามสกุล", a.name), ("เบอร์โทรศัพท์", a.tel), ("ที่อยู่", a.address)])
            if a.zip.count != 5 { bad.append(("รหัสไปรษณีย์", a.zip.isEmpty ? "ยังไม่ได้กรอก" : "รหัสไปรษณีย์ต้องมี 5 หลัก")) }
            bad += Self.empty([("ตำบล/แขวง", a.sub), ("อำเภอ/เขต", a.district), ("จังหวัด", a.province)])
            guard bad.isEmpty else { failAt(bad); return }
        }
        if step == .bank, !flow.bankInfo.complete(company: flow.payKind == "company") {
            let b = flow.bankInfo, co = flow.payKind == "company"
            failAt(Self.empty((co ? [("ชื่อนิติบุคคล", b.coName), ("เลขประจำตัวผู้เสียภาษี (13 หลัก)", b.taxID)] : [])
                              + [("ธนาคาร", b.bank), ("เลขที่บัญชี", b.no), ("ชื่อบัญชี", b.name)])); return
        }
        if step == .limits, flow.limits.isEmpty, flow.limitOther.trimmingCharacters(in: .whitespaces).isEmpty { fail("เลือกอย่างน้อย 1 ข้อ"); return }
        if step == .religion, flow.religion.isEmpty { fail("เลือก 1 ข้อ"); return }
        err = nil; errors.reset()
        if step == .intro { withAnimation(Motion.settle) { i += 1 }; return }
        if step == .body {
            // ไม่บังคับ: กรอกอย่างน้อย 1 ช่อง = มีแล้ว · ล้างหมดแล้วบันทึก = กลับเป็นยังไม่มี
            if flow.bodyInfo.filled { flow.have.insert(.body) } else { flow.have.remove(.body) }
            advance(); return
        }
        if step == .socials {
            // หน้าเดียว = ช่องทาง + เรท (ใส่ราคามาตรฐานให้แล้ว) + ข้อมูลผู้ติดตาม (ไม่บังคับ)
            flow.have.formUnion([.socials, .rate])
            if !flow.insightSlots.isEmpty { flow.have.insert(.insight) }
        } else if let k = step.dataKey { flow.have.insert(k) }
        // ข้อนี้ปิด 8 ข้อพอดี = เพิ่งเป็น STAR → motion ทับ wizard แล้วข้อถัดไปโผล่ใต้ motion (salehere-ios `celebrateIfJustBecameStar`)
        // ทางสมัครกิจกรรมได้หน้า "คุณเป็น STAR แล้ว" แทน · เป็นข้อสุดท้าย = หน้า Star Profile ฉลองตอนกลับไป
        if !wasStar && flow.isStar && kind != .apply && !isLast { onStar() }
        advance()
    }

    private func skip() {
        err = nil
        advance()
    }

    /// ช่องพิมพ์ที่กันไม่ให้ล้างทิ้งหลังเป็น STAR ต่อขั้น — key = คีย์ error ของช่อง (ป้าย) · name = ชื่อในข้อความ · = `KEPT` ของ desktop
    private static func kept(_ f: StarFlow) -> [WizStep: [(key: String, name: String, value: String)]] {
        // เฉพาะแนะนำตัว + ช่องทางติดต่อ (salehere-ios) — สัดส่วนไม่บังคับ ล้างได้
        [.media: [("แนะนำตัว", "แนะนำตัว", f.about)],
         .contact: [("LINE ID", "LINE ID ", f.lineID), ("เบอร์โทร", "เบอร์โทร", f.phone), ("เว็บไซต์ · ไม่บังคับ", "เว็บไซต์", f.website)]]
    }

    private func advance() {
        errors.reset()
        if i < steps.count - 1 { withAnimation(Motion.settle) { i += 1 } } else { finish() }
    }

    /// error ที่ช่อง — คู่ (คีย์ช่อง, ข้อความ) เรียงตามที่เห็นบนจอ · เลื่อนไปช่องแรก
    private func failAt(_ items: [(String, String)], link: [String] = []) {
        guard !items.isEmpty else { return }
        withAnimation(Motion.snap) { err = nil; errors.set(items, link: link) }
        scrollTo = items[0].0
        shakes += 1
        Haptics.rigid()
    }

    /// ช่องที่ยังว่าง → (ป้ายช่อง, "ยังไม่ได้กรอก")
    private static func empty(_ fields: [(String, String)]) -> [(String, String)] {
        fields.filter { $0.1.trimmingCharacters(in: .whitespaces).isEmpty }.map { ($0.0, "ยังไม่ได้กรอก") }
    }

    private func fail(_ msg: String) {
        errors.reset()
        withAnimation(Motion.snap) { err = msg }
        shakes += 1
        Haptics.rigid()
    }

    private func finish() {
        // หน้า "คุณเป็น STAR แล้ว" เฉพาะคนที่เพิ่งเป็น STAR ใน wizard รอบนี้ (ทางสมัครกิจกรรม) — STAR เก่าที่เติมครบไม่มีหน้านี้
        let madeCard = kind == .apply && !startStar && flow.isStar
        onFinish(madeCard)
    }

    /// ออกไปทำ KYC จริงแล้วกลับมา — ไปคำถามถัดไปเลย ไม่ต้องกดผ่านหน้า "ยืนยันตัวตนแล้ว" อีก
    /// ไม่ตัดขั้นทิ้ง (1 ต.ค. 2569): ตัวนับเดินต่อ 5/12 → 6/12 · เป็นข้อสุดท้ายก็จบ wizard เลย
    /// (เดิมตัดขั้นแล้วตัวนับหด 5/12 → 5/11 และข้อสุดท้ายเด้งกลับไปหน้าก่อนหน้า)
    private func startKyc() {
        let wasStar = flow.isStar
        onKyc {
            guard flow.verify != .none else { return }
            err = nil
            // ผ่านทันที = ไปต่อ · ส่งทีมงานตรวจ = ค้างที่ขั้นนี้ให้เห็นการ์ดรอผล (ปุ่มกลายเป็น "ปิดไว้ก่อน")
            guard flow.isVerified else { return }
            // ยืนยันตัวตนปิด 8 ข้อพอดี = เป็น STAR แล้ว → motion ก่อน (ปิดจอทึบ) แล้วข้อถัดไป/หน้าถัดไปค่อยโผล่
            // (เดิมฉลองเฉพาะตอน KYC เป็นข้อสุดท้ายผ่าน `finishWizard` — ทางโปรไฟล์ที่ยังมีที่อยู่/บัญชี/สัดส่วนต่อจึงไม่เคยเล่น)
            if !wasStar && flow.isStar && kind != .apply && !isLast { onStar() }
            if !isLast { toast("ยืนยันตัวตนแล้ว · ไปต่อได้เลย") }
            advance()
        }
    }
}

// MARK: - ช่องกรอกของแต่ละขั้น (= `WZ[key].body`)

/// ช่องทาง · เรท · ข้อมูลผู้ติดตาม ในหน้าเดียว (ผู้ใช้ 29 ก.ย. 2569) — แบบ A "สรุปก่อน แก้ทีหลัง"
/// การ์ดละช่อง: บน = ยอด + สรุปเรท (แตะเพื่อปรับ) · ล่าง = แถบข้อมูลผู้ติดตามของช่องนั้น (= `SocialInsightRowView` ของ salehere-ios)
/// insight ต่อ social เหมือนแอปหลัก: เฉพาะ FB/IG/TikTok/YouTube · 0/3 → n/3 → ✓ · ไม่บังคับ
private struct WzChannels: View {
    @Environment(StarFlow.self) private var flow
    @Binding var editing: StarSocial?
    @Binding var insightFor: StarSocial?
    /// false = โชว์เฉพาะช่องที่เชื่อมแล้ว (มาเติมเรท/ข้อมูลผู้ติดตาม ไม่ได้มาเชื่อมช่องใหม่)
    var connectable = true
    /// ช่องที่กด "เอาออก" — รอยืนยัน "ยกเลิกการผูกบัญชี"
    @State private var removing: StarSocial?

    /// ทุกช่องมีที่ของตัวเองบนหน้า ลำดับคงที่ — ยังไม่เชื่อม = แถวสั้นพร้อมปุ่มเชื่อม · เชื่อมแล้วขยายเป็นการ์ดเต็มตรงที่เดิม (ผู้ใช้ 29 ก.ย. 2569)
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(StarSocial.allCases) { s in
                if flow.connected.contains(s) { card(s) } else if connectable { connectRow(s) }
            }
        }
        .confirmationDialog("ยกเลิกการผูกบัญชี", isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } }),
                            titleVisibility: .visible) {
            Button("ยืนยัน", role: .destructive) {
                if let s = removing {
                    withAnimation(Motion.settle) { _ = flow.connected.remove(s) }
                    // ไม่มีช่องทาง = ข้อ "ช่องทางของฉัน" กลับเป็นยังไม่มี
                    if flow.connected.isEmpty { flow.have.subtract([.socials, .rate, .insight]) }
                }
                removing = nil
            }
            Button("ยกเลิก", role: .cancel) { removing = nil }
        }
    }

    /// ยังไม่เชื่อม = กรอบประ ไม่มีพื้น ชื่อสีเทา (โลโก้สีจริง) — กวาดตาแยกจากการ์ดที่เชื่อมแล้ว (ขาว ขอบทึบ) ได้ทันที (ผู้ใช้ 29 ก.ย. 2569)
    /// แตะได้ทั้งแถว
    private func connectRow(_ s: StarSocial) -> some View {
        Button {
            Haptics.impact(.light)
            editing = s
        } label: {
            HStack(spacing: 12) {
                // โลโก้คงสีของแบรนด์ไว้ (ผู้ใช้ 29 ก.ย. 2569: "icon ต้องสีมัน ไม่ต้องเทา") — ความจางอยู่ที่กรอบประกับชื่อ
                Image(s.icon).resizable().aspectRatio(contentMode: .fit).frame(width: 30, height: 30).clipShape(Circle())
                    .frame(width: 36, height: 36)
                Text(s.name).font(.sh(15, .semibold)).foregroundStyle(PK.hint)
                Spacer(minLength: 6)
                HStack(spacing: 4) {
                    PIcon(.plus, size: 12)
                    Text("เชื่อม").font(.sh(13, .bold))
                }
                .foregroundStyle(GL.ink)
                .padding(.horizontal, 14).frame(height: 32)
                .background(Capsule().fill(.white))
                .overlay(Capsule().strokeBorder(PK.line, lineWidth: 1))
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .overlay(PK.shape(16).strokeBorder(PK.line2, style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])))
            .contentShape(PK.shape(16))
        }
        .buttonStyle(.plain)
    }

    /// บน = ยอด + สรุปเรท + ยกเลิกผูกบัญชี (แทน >) · ล่าง = ปรับราคา (ผู้ใช้ 8 ต.ค. 2569 · salehere-ios)
    private func card(_ s: StarSocial) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button {
                    Haptics.impact(.light)
                    editing = s
                } label: {
                    HStack(spacing: 12) {
                        Image(s.icon).resizable().aspectRatio(contentMode: .fit).frame(width: 36, height: 36).clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(s.name) · \(StarFlow.fmt(flow.followers(s)))").font(.sh(15, .bold)).foregroundStyle(GL.ink).lineLimit(1)
                            Text(summary(s)).font(.sh(12.5)).foregroundStyle(PK.muted).lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // ก่อนเป็น STAR ต้องเหลืออย่างน้อย 1 ช่อง · เป็นแล้วเอาออกได้จนหมด — salehere-ios
                if flow.connected.count > 1 || flow.keepsData {
                    Button {
                        Haptics.impact(.light)
                        removing = s
                    } label: {
                        Text("ยกเลิกผูกบัญชี").font(.sh(12, .semibold)).foregroundStyle(PK.muted).underline()
                            .lineLimit(1).fixedSize()
                            .padding(.vertical, 4).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            HStack {
                Spacer()
                Button {
                    Haptics.impact(.light)
                    editing = s
                } label: {
                    Text("ปรับราคา").font(.sh(12.5, .semibold)).foregroundStyle(GL.ink).underline()
                        .padding(.vertical, 4).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14).padding(.bottom, 8)
            if s.supportsInsight { insightStrip(s) }
        }
        .background(PK.shape(16).fill(.white))
        .overlay(PK.shape(16).strokeBorder(PK.line, lineWidth: 1))
    }

    /// แถบข้อมูลผู้ติดตามใต้การ์ด — สถานะ 0/3 · n/3 · ✓ + ปุ่มเพิ่ม/อัปเดต (สำเนาตาราง state ของ SocialInsightRowView)
    private func insightStrip(_ s: StarSocial) -> some View {
        let n = InsightMock.count(flow, s)
        return Button {
            Haptics.impact(.light)
            insightFor = s
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("ข้อมูลผู้ติดตาม").font(.sh(13, .bold)).foregroundStyle(GL.ink)
                        InsightBadge(n: n)
                    }
                    Text(n == 3 ? "อัปเดตล่าสุด \(InsightMock.today)" : "ไม่บังคับ · แบรนด์เห็นกลุ่มคนดูของคุณ")
                        .font(.sh(12)).foregroundStyle(n > 0 && n < 3 ? PK.warn : PK.muted).lineLimit(1)
                }
                Spacer(minLength: 6)
                // ไม่บังคับ = ปุ่มเงียบ (แอปหลักใช้ปุ่มแดงทึบ แต่ในหน้านี้จะดังกว่าปุ่มถัดไป)
                Text(n == 3 ? "อัปเดต" : n > 0 ? "แนบต่อ" : "+ เพิ่ม").font(.sh(12.5, .bold))
                    .foregroundStyle(GL.ink)
                    .padding(.horizontal, 12).frame(height: 30)
                    .background(Capsule().fill(n == 3 ? .white : PK.fieldFill))
                    .overlay(Capsule().strokeBorder(n == 3 ? PK.line : .clear, lineWidth: 1))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .overlay(alignment: .top) {
                Line().stroke(PK.line2, style: StrokeStyle(lineWidth: 1, dash: [4, 3])).frame(height: 1).padding(.horizontal, 14)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// เรท 2 รูปแบบแรก + "+N"
    private func summary(_ s: StarSocial) -> String {
        let parts = s.formats.prefix(2).map { "\($0.name) ฿\(flow.rate(s, $0).formatted())" }
        return parts.joined(separator: " · ") + (s.formats.count > 2 ? " · +\(s.formats.count - 2)" : "")
    }

}

private struct Line: Shape {
    func path(in r: CGRect) -> Path { Path { p in p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: r.width, y: 0)) } }
}

/// 0/3 เทา · n/3 ส้ม · ✓ เขียว
private struct InsightBadge: View {
    let n: Int
    var body: some View {
        Group {
            if n == 3 {
                PIcon(.check, size: 11).foregroundStyle(.white).frame(width: 18, height: 18).background(Circle().fill(GL.green))
            } else {
                Text("\(n)/3").font(.sh(11, .bold)).monospacedDigit()
                    .foregroundStyle(n > 0 ? PK.warn : PK.muted)
                    .padding(.horizontal, 7).frame(height: 18)
                    .background(Capsule().fill(n > 0 ? PK.warnTint : PK.fieldFill))
            }
        }
    }
}

/// ข้อมูลจำลองของ insight (ของจริง = ผล `analyzeSocialProfileInsight` ต่อภาพ)
enum InsightMock {
    static let slots: [(key: String, title: String, icon: Ph, segs: [(String, Double)])] = [
        // `segs` = ป้ายของแต่ละหัวข้อ — ตัวเลขจริงอ่านจากรูปแคปหน้า Insights ที่ผู้ใช้อัปโหลด (`InsightReader`)
        ("gender", "เพศ", .genderIntersex, [("หญิง", 0), ("ชาย", 0), ("อื่น ๆ", 0)]),
        ("age", "ช่วงอายุ", .cake, [("18–24 ปี", 0), ("25–34 ปี", 0), ("35–44 ปี", 0), ("45+ ปี", 0)]),
        ("location", "พื้นที่ยอดนิยม", .mapPin, [("", 0), ("", 0), ("", 0)]),
    ]
    static func id(_ s: StarSocial, _ k: String) -> String { "\(s.rawValue)_\(k)" }
    static func count(_ f: StarFlow, _ s: StarSocial) -> Int { slots.filter { f.insightSlots.contains(id(s, $0.key)) }.count }
    static var today: String {
        let d = DateFormatter()
        d.locale = Locale(identifier: "th_TH"); d.calendar = Calendar(identifier: .buddhist); d.dateFormat = "d MMM yyyy"
        return d.string(from: Date())
    }
    /// ชื่อแอปที่ต้องเปิด + ทางเข้าหน้าสถิติ (fallback steps ของ SocialInsightHowToView ย่อเป็นบรรทัดเดียว)
    static func app(_ s: StarSocial) -> String { s == .youtube ? "YouTube Studio" : s.name }
    static func path(_ s: StarSocial) -> String {
        switch s {
        case .facebook: return "เพจ → Professional dashboard → ข้อมูลเชิงลึก → ผู้ติดตาม"
        case .instagram: return "โปรไฟล์ → Professional dashboard → ข้อมูลเชิงลึก → ผู้ติดตามทั้งหมด"
        case .tiktok: return "โปรไฟล์ → ☰ → เครื่องมือครีเอเตอร์ → ข้อมูลวิเคราะห์ → ผู้ติดตาม"
        case .youtube: return "ข้อมูลวิเคราะห์ → แท็บผู้ชม"
        default: return ""
        }
    }
    static func deepLink(_ s: StarSocial) -> (String, String) {
        switch s {
        case .facebook: return ("fb://", "https://facebook.com")
        case .instagram: return ("instagram://app", "https://instagram.com")
        case .tiktok: return ("snssdk1233://", "https://tiktok.com")
        default: return ("ytstudio://", "https://studio.youtube.com")
        }
    }
}

/// เชื่อม/แก้ช่องเดียว = แถวช่องทางของฟอร์มเว็บ v16.1 (`platrate`): วางลิงก์โปรไฟล์ → ยอดผู้ติดตาม → เรทต่อรูปแบบ
/// ยอด: YouTube ดึงเองจาก API · ช่องอื่นกรอกเอง (ปุ่มเชื่อมบัญชีถอดออกจนกว่าจะต่อ OAuth จริง) — เรทเติมจากยอดให้ แก้ได้ เตือนเมื่อต่างเกิน 30%
/// ค่าทั้งหมดเป็นร่าง กด "เชื่อมช่องนี้"/"บันทึก" ถึงจะเข้า Star Profile
private struct ChannelSheet: View {
    @Environment(StarFlow.self) private var flow
    let social: StarSocial
    /// true = เพิ่งผูกช่องใหม่
    let done: (Bool) -> Void

    @State private var isNew = true
    @State private var link = ""
    @State private var followers = 0
    @State private var source = ""
    @State private var rates: [StarFormat: Int] = [:]
    @State private var err: String?
    @State private var loaded = false
    @FocusState private var linkFocused: Bool

    private var check: (ok: Bool, msg: String, url: String) { social.checkLink(link) }

    var body: some View {
        let s = social
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(s.icon).resizable().aspectRatio(contentMode: .fit).frame(width: 36, height: 36).clipShape(Circle())
                Text(isNew ? "เชื่อม \(s.name)" : s.name).font(.sh(18, .heavy)).foregroundStyle(GL.ink)
                Spacer()
            }
            .padding(.bottom, 16)

            label("ลิงก์โปรไฟล์")
            linkField
            if !check.ok, !check.msg.isEmpty, !linkFocused {
                Text(check.msg).font(.sh(12, .semibold)).foregroundStyle(PK.red).padding(.top, 5)
            }

            if check.ok {
                followerBlock.padding(.top, 14)
            }
            if check.ok && followers > 0 {
                label("เรทต่อโพสต์").padding(.top, 14)
                VStack(spacing: 12) {
                    ForEach(s.formats) { f in
                        let reco = StarFlow.suggest(followers, f), v = rates[f] ?? reco
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(f.name).font(.sh(14.5, .semibold)).foregroundStyle(GL.ink)
                                    Text("แนะนำ ฿\(reco.formatted())").font(.sh(12)).foregroundStyle(PK.hint)
                                }
                                Spacer()
                                RateInput(value: Binding(get: { rates[f] ?? StarFlow.suggest(followers, f) }, set: { rates[f] = $0 }))
                            }
                            if let warn = deviation(v, reco) {
                                Text(warn).font(.sh(12, .semibold)).foregroundStyle(PK.warn)
                            }
                        }
                    }
                }
                HStack {
                    Button {
                        Haptics.impact(.light)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        rates = [:]
                    } label: {
                        HStack(spacing: 5) { PIcon(.arrowsClockwise, size: 13); Text("ใช้เรทแนะนำ").font(.sh(13, .semibold)) }
                            .foregroundStyle(GL.ink).padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    // เอาช่องออก ย้ายไปลิงก์ "เอาออก" ใต้การ์ดช่อง (salehere-ios)
                }
                .padding(.top, 6)
            }
            if let err { Text(err).font(.sh(12.5, .semibold)).foregroundStyle(PK.red).padding(.top, 8) }
            PKPrimaryButton(title: isNew ? "เชื่อมช่องนี้" : "บันทึก", action: save).padding(.top, 12)
        }
        .animation(Motion.snap, value: check.ok)
        .animation(Motion.snap, value: followers > 0)
        .onAppear(perform: load)
    }

    private func label(_ t: String) -> some View {
        Text(t).font(.sh(13, .bold)).foregroundStyle(GL.ink).padding(.bottom, 6)
    }

    private var linkField: some View {
        HStack(spacing: 8) {
            TextField("", text: $link, prompt: Text(social.linkPlaceholder).foregroundStyle(PK.hint))
                .font(.sh(15)).foregroundStyle(GL.ink).tint(GL.ink)
                .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                .focused($linkFocused)
                .onChange(of: link) { _, _ in err = nil; autoFetch() }
            if check.ok {
                PIcon(.check, size: 14).foregroundStyle(GL.greenInk)
            } else {
                // ปุ่มวางของระบบ — ไม่ขึ้นกล่อง "อนุญาตให้วาง" ทุกครั้งแบบอ่าน UIPasteboard เอง
                PasteButton(payloadType: String.self) { items in
                    if let p = items.first { Task { @MainActor in link = p } }
                }
                .labelStyle(.titleOnly).buttonBorderShape(.capsule).controlSize(.small).tint(GL.ink)
            }
        }
        .padding(.leading, 14).padding(.trailing, 8).frame(height: 48)
        .background(PK.shape(14).fill(.white))
        .overlay(PK.shape(14).strokeBorder(linkFocused ? GL.ink : (!check.ok && !check.msg.isEmpty ? PK.red : PK.line), lineWidth: 1))
    }

    /// ยอดผู้ติดตามตาม `fetch` ของช่อง (= `folBlock` ของฟอร์มเว็บ)
    @ViewBuilder
    private var followerBlock: some View {
        label("ยอดผู้ติดตาม")
        if social.fetch == "api", source == "api", followers > 0 {
            note(ok: true, "\(StarFlow.fmt(followers)) ผู้ติดตาม · ดึงจาก YouTube อัตโนมัติ")
        } else {
            // ช่องกรอกอย่างเดียว — ปุ่ม "เชื่อมบัญชี" ถอดออกจนกว่าจะต่อ OAuth จริง (ผู้ใช้ 1 ต.ค. 2569:
            // "เชื่อมบัญชีไร ให้ user กรอกไปก่อน") · ค่าที่เคยกด "เชื่อมแล้ว" ไว้แก้ทับได้ แล้วกลับเป็นกรอกเอง
            HStack {
                TextField("", text: Binding(get: { followers > 0 ? String(followers) : "" },
                                            set: { followers = Int($0.filter(\.isNumber)) ?? 0; source = "manual"; err = nil }),
                          prompt: Text("เช่น 24800").foregroundStyle(PK.hint))
                    .font(.sh(15)).foregroundStyle(GL.ink).tint(GL.ink).keyboardType(.numberPad)
            }
            .padding(.horizontal, 14).frame(height: 44)
            .background(PK.shape(14).fill(.white))
            .overlay(PK.shape(14).strokeBorder(PK.line, lineWidth: 1))
            if source == "connect" {
                note(ok: true, "ยืนยันแล้วผ่านการเชื่อมบัญชี")
            } else if followers > 0 {
                note(ok: false, "กรอกเอง — ทีมงานตรวจสอบก่อนขึ้นการ์ด")
            }
        }
    }

    private func note(ok: Bool, _ t: String) -> some View {
        HStack(spacing: 5) {
            PIcon(ok ? .check : .info, size: 12)
            Text(t).font(.sh(12))
        }
        .foregroundStyle(ok ? GL.greenInk : PK.muted).padding(.top, 5)
    }

    /// YouTube: ลิงก์ถูกแล้วดึงยอดเอง (จำลอง)
    private func autoFetch() {
        guard social.fetch == "api" else { return }
        // ยังไม่ต่อ YouTube API — ผู้ใช้กรอกยอดเอง (ที่มา "api" ไว้ใช้วันที่ต่อจริง)
        if !check.ok { followers = 0 }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        isNew = !flow.connected.contains(social)
        if !isNew {
            link = flow.link(social)
            followers = flow.followers(social)
            source = flow.followerSources[social.rawValue] ?? (social.fetch == "manual" ? "manual" : social.fetch)
            for f in social.formats where flow.rates["\(social.rawValue)_\(f.rawValue)"] != nil { rates[f] = flow.rate(social, f) }
        } else {
            // mock: เชื่อมใหม่ = ลิงก์ + ยอด + บัญชีเชื่อมไว้ให้แล้ว
            link = social.mockLink
            followers = social.mockFollowers
            source = social.fetch
        }
    }

    private func save() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        guard check.ok else { err = check.msg.isEmpty ? "วางลิงก์โปรไฟล์ \(social.name) ก่อน" : check.msg; Haptics.rigid(); return }
        guard followers > 0 else { err = "ใส่ยอดผู้ติดตามก่อน"; Haptics.rigid(); return }
        let s = social
        flow.links[s.rawValue] = check.url
        flow.followerCounts[s.rawValue] = followers
        flow.followerSources[s.rawValue] = source
        for f in s.formats { flow.setRate(s, f, rates[f] ?? StarFlow.suggest(followers, f)) }
        if isNew { withAnimation(Motion.snap) { _ = flow.connected.insert(s) } }
        done(isNew)
    }

    private func deviation(_ v: Int, _ reco: Int) -> String? {
        guard reco > 0, v > 0 else { return nil }
        let d = Double(v - reco) / Double(reco)
        guard abs(d) > 0.3 else { return nil }
        return d < 0 ? "ต่ำกว่าเรทแนะนำ \(Int((-d * 100).rounded()))% · แบรนด์อาจมองว่างานไม่เต็มที่"
                     : "สูงกว่าเรทแนะนำ \(Int((d * 100).rounded()))% · อาจถูกเลือกน้อยลง"
    }
}

/// กรอกข้อมูลผู้ติดตามของ "ช่องเดียว" (= แท็บหนึ่งของ SocialInsightPage ใน salehere-ios)
/// 3 ขั้น (เปิดแอป → เข้าหน้าผู้ติดตาม → อ่านตัวเลขมากรอก) + 3 ช่อง เพศ · ช่วงอายุ · พื้นที่ แต่ละช่องบันทึกเมื่อกด "บันทึก"
/// ไม่มีตัวเลขตัวอย่าง — ทุกค่ามาจากที่ผู้ใช้พิมพ์ (1 ต.ค. 2569) · ของจริง = แนบภาพแล้วระบบอ่านให้
private struct InsightPanel: View {
    @Environment(StarFlow.self) private var flow
    @Environment(\.openURL) private var openURL
    let social: StarSocial
    let done: () -> Void
    /// ช่องที่กำลังแก้ตัวเลข (หลังอัปโหลดแล้วเท่านั้น — อ่านผิดค่อยแก้)
    @State private var editing: String? = nil
    @State private var draft: [InsightSeg] = []
    @State private var err: String? = nil
    /// ช่องที่กำลังอ่านรูป
    @State private var reading: Set<String> = []
    /// อ่านไม่ออก — ข้อความต่อช่อง
    @State private var failed: [String: String] = [:]
    /// รูปแคปหน้าจอที่อัปโหลด (โหลดจากไฟล์ตอนเปิด + รูปใหม่ในรอบนี้)
    @State private var shots: [String: UIImage] = [:]

    var body: some View {
        let s = social, n = InsightMock.count(flow, s)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(s.icon).resizable().aspectRatio(contentMode: .fit).frame(width: 30, height: 30).clipShape(Circle())
                Text("ข้อมูลผู้ติดตาม").font(.sh(19, .heavy)).foregroundStyle(GL.ink)
                InsightBadge(n: n)
                Spacer()
            }
            steps.padding(.top, 14)
            VStack(spacing: 10) {
                ForEach(InsightMock.slots, id: \.key) { slot in slotRow(slot) }
            }
            .padding(.top, 14)
            PKPrimaryButton(title: n == 3 ? "เสร็จ" : "ไว้ทำต่อทีหลัง", action: done).padding(.top, 14)
        }
        .onAppear {
            for slot in InsightMock.slots {
                let id = InsightMock.id(social, slot.key)
                if shots[id] == nil, let img = InsightShot.load(id) { shots[id] = img }
            }
        }
    }

    /// ขั้นทำ 3 ข้อ — ข้อ 1 แตะเปิดแอปจริง (deep link → เว็บ)
    private var steps: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Haptics.impact(.light)
                let (app, web) = InsightMock.deepLink(social)
                if let u = URL(string: app), UIApplication.shared.canOpenURL(u) { openURL(u) } else if let u = URL(string: web) { openURL(u) }
            } label: {
                stepRow(1, "เปิดแอป \(InsightMock.app(social))", trailing: true)
            }
            .buttonStyle(.plain)
            stepRow(2, InsightMock.path(social))
            stepRow(3, "แคปหน้าจอแต่ละหัวข้อ แล้วอัปโหลดที่นี่")
        }
        .padding(12)
        .background(PK.shape(14).fill(PK.fieldFill))
    }

    private func stepRow(_ i: Int, _ text: String, trailing: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(i)").font(.sh(11, .bold)).foregroundStyle(.white).frame(width: 20, height: 20).background(Circle().fill(GL.ink))
            Text(text).font(.sh(13, i == 1 ? .semibold : .regular)).foregroundStyle(GL.ink).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if trailing { PIcon(.arrowUpRight, size: 13).foregroundStyle(GL.ink).padding(.top, 3) }
        }
        .contentShape(Rectangle())
    }

    /// แตะทั้งแถว = อัปโหลดรูปแคปหน้าจอ (ซ้ำ = เปลี่ยนรูป) · ตัวเลขอ่านจากรูปเอง · "แก้ตัวเลข" มีให้หลังอ่านแล้วเท่านั้น
    private func slotRow(_ slot: (key: String, title: String, icon: Ph, segs: [(String, Double)])) -> some View {
        let id = InsightMock.id(social, slot.key)
        let saved = flow.insightValues[id] ?? []
        let has = !saved.isEmpty
        let open = editing == id
        let busy = reading.contains(id)
        return VStack(spacing: 0) {
            Button { upload(id, slot) } label: {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 5) {
                            PIcon(slot.icon, size: 13)
                            Text(slot.title).font(.sh(12.5, .bold))
                        }
                        .foregroundStyle(GL.ink)
                        .padding(.horizontal, 8).frame(height: 24).background(Capsule().fill(PK.fieldFill))
                        if busy {
                            Text("กำลังอ่านตัวเลขจากรูป…").font(.sh(12.5)).foregroundStyle(PK.muted)
                        } else if has, let top = saved.max(by: { $0.pct < $1.pct }) {
                            (Text(top.label + "  ").font(.sh(17, .heavy)) + Text("\(Int(top.pct))%").font(.sh(14, .bold)))
                                .foregroundStyle(GL.ink)
                            Text(saved.filter { $0.label != top.label }.map { "\($0.label) \(Int($0.pct))%" }.joined(separator: " · "))
                                .font(.sh(12)).foregroundStyle(PK.muted).lineLimit(1)
                        } else if let f = failed[id] {
                            Text(f).font(.sh(12.5, .semibold)).foregroundStyle(PK.red).fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("แคปหน้า \"\(slot.title)\" จาก \(InsightMock.app(social)) แล้วแตะเพื่ออัปโหลด")
                                .font(.sh(12.5)).foregroundStyle(PK.muted).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, has && !busy ? 22 : 0)
                    Spacer(minLength: 0)
                    tile(shot: shots[id], has: has, busy: busy)
                }
                .padding(12)
                .background(PK.shape(16).fill(.white))
                .overlay(PK.shape(16).strokeBorder(open ? GL.ink : PK.line, lineWidth: open ? 1.5 : 1))
                .contentShape(PK.shape(16))
            }
            .buttonStyle(.plain)
            .disabled(busy)
            .overlay(alignment: .bottomLeading) {
                if has && !busy {
                    Button { toggle(id, saved) } label: {
                        Text(open ? "ปิด" : "แก้ตัวเลข").font(.sh(12, .bold)).foregroundStyle(PK.muted).underline()
                            .padding(.horizontal, 12).padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 2)
                }
            }
            if open { entry(id, slot).padding(.top, 8) }
        }
        .animation(Motion.snap, value: open)
    }

    /// แก้ตัวเลขที่อ่านมา — เพศ/อายุ ป้ายตายตัว แก้แค่ % · พื้นที่ แก้ชื่อเมืองได้
    private func entry(_ id: String, _ slot: (key: String, title: String, icon: Ph, segs: [(String, Double)])) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(draft.indices, id: \.self) { i in
                HStack(alignment: .bottom, spacing: 8) {
                    if slot.key == "location" {
                        WzInput(label: "เมือง/จังหวัด อันดับ \(i + 1)",
                                text: Binding(get: { draft[i].label }, set: { draft[i].label = $0 }), placeholder: "เช่น กรุงเทพ")
                    } else {
                        Text(draft[i].label).font(.sh(15, .semibold)).foregroundStyle(GL.ink)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 14)
                    }
                    WzInput(label: "%", text: Binding(get: { draft[i].pct > 0 ? String(Int(draft[i].pct)) : "" },
                                                      set: { draft[i].pct = Double($0.filter(\.isNumber)) ?? 0 }),
                            placeholder: "0", keyboard: .numberPad)
                        .frame(width: 84)
                }
            }
            if let err { Text(err).font(.sh(12.5, .semibold)).foregroundStyle(PK.red) }
            PKPrimaryButton(title: "บันทึก") { save(id) }
        }
        .padding(12)
        .background(PK.shape(16).fill(PK.fieldFill))
    }

    /// ช่องรูป — ว่าง = กรอบประ + ไอคอนอัปโหลด · มีรูป = ภาพแคปจริง + ✓
    private func tile(shot: UIImage?, has: Bool, busy: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        return ZStack {
            shape.fill(GL.bg)
            if let shot {
                Image(uiImage: shot).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 58, height: 96).clipShape(shape)
            } else {
                PIcon(.imageSquare, size: 20).foregroundStyle(PK.red)
            }
            if busy {
                shape.fill(.black.opacity(0.35))
                ProgressView().tint(.white)
            } else if has {
                VStack {
                    HStack { Spacer(); PIcon(.check, size: 10).foregroundStyle(.white).frame(width: 18, height: 18).background(Circle().fill(GL.green)) }
                    Spacer()
                }
                .padding(5)
            }
        }
        .frame(width: 58, height: 96)
        .overlay(shape.strokeBorder(has ? GL.green : PK.line2, style: StrokeStyle(lineWidth: 1.5, dash: shot != nil ? [] : [4, 3])))
    }

    private func upload(_ id: String, _ slot: (key: String, title: String, icon: Ph, segs: [(String, Double)])) {
        Haptics.impact(.light)
        editing = nil
        MediaPicker.present(videos: false, limit: 1) { results in
            guard let r = results.first else { return }
            Task { @MainActor in
                guard let img = await MediaPicker.image(r) else { failed[id] = "อัปโหลดไม่สำเร็จ ลองใหม่อีกครั้ง"; return }
                failed[id] = nil
                withAnimation(Motion.snap) { shots[id] = img; reading.insert(id) }
                let segs = await InsightReader.read(img, slot: slot.key)
                withAnimation(Motion.settle) {
                    reading.remove(id)
                    if segs.isEmpty {
                        failed[id] = "อ่านตัวเลขในรูปไม่ได้ · แคปหน้า \"\(slot.title)\" ให้เห็นตัวเลข % แล้วลองใหม่"
                        Haptics.rigid()
                    } else {
                        InsightShot.save(img, id)
                        flow.insightValues[id] = segs
                        flow.insightSlots.insert(id)
                        Haptics.impact(.medium)
                    }
                }
            }
        }
    }

    private func toggle(_ id: String, _ saved: [InsightSeg]) {
        Haptics.impact(.light)
        err = nil
        if editing == id { editing = nil; return }
        draft = saved
        editing = id
    }

    private func save(_ id: String) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let v = draft.filter { $0.pct > 0 && !$0.label.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !v.isEmpty else { err = "ใส่อย่างน้อย 1 ค่า"; Haptics.rigid(); return }
        guard v.reduce(0, { $0 + $1.pct }) <= 100.5 else { err = "รวมกันต้องไม่เกิน 100%"; Haptics.rigid(); return }
        flow.insightValues[id] = v
        flow.insightSlots.insert(id)
        editing = nil
        Haptics.impact(.medium)
    }
}

/// รูปแคปหน้า Insights ที่อัปโหลด — เก็บไฟล์ในเครื่อง (ของจริง = อัปขึ้น S3 แล้ว `analyzeSocialProfileInsight`)
enum InsightShot {
    private static var dir: URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("insight-shots")
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    static func save(_ img: UIImage, _ id: String) {
        try? img.jpegData(compressionQuality: 0.7)?.write(to: dir.appendingPathComponent(id + ".jpg"))
    }
    static func load(_ id: String) -> UIImage? { UIImage(contentsOfFile: dir.appendingPathComponent(id + ".jpg").path) }
}

/// แผงเลื่อนขึ้นจากล่างแบบ sheet — ฉากหลังมืดแตะเพื่อปิด · ขอบบนมน + ขีดจับ
private struct BottomPanel<Content: View>: View {
    let close: () -> Void
    @ViewBuilder let content: Content
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35).ignoresSafeArea()
                .onTapGesture { close() }
                .transition(.opacity)
            VStack(spacing: 0) {
                Capsule().fill(PK.line2).frame(width: 36, height: 5).padding(.top, 8).padding(.bottom, 18)
                content
            }
            .padding(.horizontal, 20).padding(.bottom, 12)
            .frame(maxWidth: .infinity)
            .background(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                .fill(GL.bg).ignoresSafeArea(edges: .bottom))
            .transition(.move(edge: .bottom))
        }
    }
}

private struct WzCategories: View {
    @Environment(StarFlow.self) private var flow
    private let all = ["💄 บิวตี้", "👗 แฟชั่น", "🍜 อาหาร", "☕️ คาเฟ่", "✨ ไลฟ์สไตล์", "✈️ ท่องเที่ยว", "💪 สุขภาพ", "👶 แม่และเด็ก", "🐶 สัตว์เลี้ยง", "📱 เทค", "🎮 เกม", "🎬 บันเทิง", "🎪 อีเวนต์"]
    var body: some View {
        PKWrap(spacing: 8) {
            ForEach(all, id: \.self) { c in
                let on = flow.categories.contains(c)
                WzChip(text: c, on: on) {
                    if on { flow.categories.removeAll { $0 == c } }
                    else if flow.categories.count < 5 { flow.categories.append(c) }
                    else { Haptics.rigid() }
                }
            }
        }
    }
}

private struct WzAbout: View {
    @Environment(StarFlow.self) private var flow
    @Environment(WzErrors.self) private var errors: WzErrors?
    var minHeight: CGFloat = 120
    @FocusState private var focused: Bool
    private var error: String? { errors?.map["แนะนำตัว"] }
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            editor
            if let error { WzFieldError(text: error) }
        }
        .id("wz:แนะนำตัว")
        .onChange(of: flow.about) { _, _ in errors?.clear("แนะนำตัว") }
    }
    private var editor: some View {
        @Bindable var f = flow
        return TextEditor(text: $f.about)
            .font(.sh(17)).foregroundStyle(GL.ink).tint(GL.ink)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .overlay(alignment: .topLeading) {
                if flow.about.isEmpty {
                    Text("เช่น ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่คาเฟ่น่ารักๆ")
                        .font(.sh(17)).foregroundStyle(PK.hint)
                        .padding(.horizontal, 17).padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: minHeight)
            .background(PK.shape(16).fill(.white))
            .overlay(PK.shape(16).strokeBorder(error != nil ? PK.red : focused ? GL.ink : PK.line, lineWidth: error != nil ? 1.5 : 1))
            .focused($focused)
    }
}

/// ขั้นยืนยันตัวตนใน wizard — 4 สถานะ (ผ่าน · รอตรวจ · ตีกลับ · ยังไม่ทำ) รอตรวจ/ตีกลับใช้ `KycHeroCard` ชุดเดียวกับหน้าสถานะ
private struct WzKyc: View {
    @Environment(StarFlow.self) private var flow
    let start: () -> Void
    let toast: (String) -> Void
    /// ยกเลิกคำขอ: แตะครั้งแรก = ขอยืนยัน · ครั้งที่สอง = ยกเลิกจริง (แบบเดียวกับหน้าสถานะ — salehere-ios)
    @State private var confirmCancel = false
    var body: some View {
        switch flow.verify {
        case .approved:
            row(icon: .check, on: true, title: "Verified by Sale Here", sub: "ขึ้นป้ายบนการ์ดแล้ว")
        case .waiting, .rejected:
            // UI เดียวกับหน้าสถานะ (ผู้ใช้ 6 ต.ค. 2569) — หัวข้อ/ชิปอยู่ที่ heading/lines ของ wizard
            VStack(spacing: 12) {
                KycHeroCard(waiting: flow.verify == .waiting, reason: flow.verifyReason)
                if flow.verify == .rejected {
                    Button { Haptics.impact(.medium); start() } label: {
                        Text("ส่งยืนยันตัวตนใหม่").font(.sh(15, .bold)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(PK.shape(14).fill(GL.ink))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        Haptics.impact(.light)
                        guard confirmCancel else { withAnimation(Motion.snap) { confirmCancel = true }; return }
                        confirmCancel = false
                        flow.verify = .none; flow.kycSentAt = nil
                        toast("ยกเลิกการส่งข้อมูลแล้ว")
                    } label: {
                        Text(confirmCancel ? "แตะอีกครั้งเพื่อยกเลิกคำขอ · ต้องถ่ายใหม่ทั้งหมด" : "ยกเลิกคำขอยืนยันตัวตน")
                            .font(.sh(13, .semibold)).foregroundStyle(confirmCancel ? PK.red : PK.muted)
                            .frame(maxWidth: .infinity).frame(height: 30)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    // Lab ทดสอบ: จำลองผลจาก staff ระหว่างรอ (salehere-ios Dev/SIT)
                    Button { Haptics.impact(.light); start() } label: {
                        Text("Lab · เลือกผลยืนยันตัวตน").font(.sh(12.5, .semibold)).foregroundStyle(PK.hint).underline()
                            .frame(maxWidth: .infinity).frame(height: 28)
                    }
                    .buttonStyle(.plain)
                }
            }
        case .none:
            Button {
                Haptics.impact(.medium)
                start()
            } label: {
                VStack(spacing: 8) {
                    PIcon(.identificationCard, size: 28).foregroundStyle(GL.ink)
                    Text("เริ่มยืนยันตัวตน").font(.sh(15, .bold)).foregroundStyle(GL.ink)
                }
                .frame(maxWidth: .infinity).frame(height: 140)
                .background(PK.shape(16).fill(.white))
                .overlay(PK.shape(16).strokeBorder(PK.line2, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])))
                .contentShape(PK.shape(16))
            }
            .buttonStyle(.plain)
        }
    }
    private func row(icon: Ph, on: Bool, title: String, sub: String) -> some View {
        HStack(spacing: 12) {
            PIcon(icon, size: 16).foregroundStyle(on ? .white : GL.ink)
                .frame(width: 28, height: 28).background(Circle().fill(on ? GL.ink : PK.fieldFill))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.sh(15, .bold)).foregroundStyle(GL.ink)
                Text(sub).font(.sh(12.5)).foregroundStyle(PK.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(PK.shape(16).fill(on ? PK.pick : .white))
        .overlay(PK.shape(16).strokeBorder(on ? GL.ink : PK.line, lineWidth: on ? 1.5 : 1))
    }
}

private struct RateInput: View {
    @Binding var value: Int
    @State private var text = ""
    @FocusState private var focused: Bool
    var body: some View {
        HStack(spacing: 6) {
            Text("฿").font(.sh(15, .semibold)).foregroundStyle(PK.hint)
            TextField("", text: $text)
                .font(.sh(16)).foregroundStyle(GL.ink).tint(GL.ink)
                .multilineTextAlignment(.trailing).keyboardType(.numberPad)
                .focused($focused)
                .onChange(of: text) { _, t in if focused { value = Int(t.filter(\.isNumber)) ?? 0 } }
            Text("/โพสต์").font(.sh(12, .semibold)).foregroundStyle(PK.hint)
        }
        .padding(.horizontal, 14).frame(width: 150, height: 44)
        .background(PK.shape(14).fill(.white))
        .overlay(PK.shape(14).strokeBorder(focused ? GL.ink : PK.line, lineWidth: 1))
        .onAppear { text = String(value) }
        .onChange(of: value) { _, v in if !focused { text = String(v) } }
        .onChange(of: focused) { _, f in if !f { text = String(value) } }
    }
}

/// ยอดนิยมขึ้นก่อน · ที่เหลือคือ 77 จังหวัดเรียง ก–ฮ (จาก `IntakeCatalog.provinces`)
private let provinceAlias = ["กรุงเทพมหานคร": "กทม กรุงเทพ bangkok bkk", "นครราชสีมา": "โคราช",
                             "พระนครศรีอยุธยา": "อยุธยา",
                             "ภูเก็ต": "phuket", "เชียงใหม่": "chiang mai", "ชลบุรี": "พัทยา pattaya"]

/// จังหวัดที่สะดวกรับงาน = หน้า CreatorProfileAvailabilityProvince ของ salehere-ios ตัวต่อตัว (ผู้ใช้ 6 ต.ค. 2569: "เอา ยอดนิยมออก และ ใช้ UI แบบเดิม")
/// ช่องค้นหา · บรรทัด "เลือกแล้ว N จังหวัด" · ชิป 44pt ขอบกลม ไอคอน ⊕ / ✓แดง ตัวแดงเมื่อเลือก · จางเมื่อครบ 3 · ไม่มีหมวดยอดนิยม รายการเดียวเรียงตามตัวอักษร
private struct WzProvince: View {
    @Environment(StarFlow.self) private var flow
    @State private var query = ""
    @FocusState private var focused: Bool
    private static let max = 3

    private var q: String { query.trimmingCharacters(in: .whitespaces).lowercased() }
    private func hit(_ p: String) -> Bool { q.isEmpty || (p + " " + (provinceAlias[p] ?? "")).lowercased().contains(q) }

    var body: some View {
        let found = IntakeCatalog.provinces.filter(hit)
        VStack(alignment: .leading, spacing: 0) {
            // ช่องค้นหา (= searchView: radius 10 · ขอบ Gray300 · placeholder "ค้นหาจังหวัด" 14 medium · clear button)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .semibold)).foregroundStyle(PK.hint)
                TextField("", text: $query, prompt: Text("ค้นหาจังหวัด").foregroundStyle(PK.hint))
                    .font(.sh(14, .medium)).foregroundStyle(GL.ink).tint(GL.ink)
                    .focused($focused).submitLabel(.done)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 17)).foregroundStyle(PK.line2)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14).frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(focused ? GL.ink : PK.line2, lineWidth: 1))
            .contentShape(Rectangle())
            .onTapGesture { focused = true }

            // (= categoriesHeaderTitle: "เลือกแล้ว %@ จังหวัด" 16 semibold)
            Text("เลือกแล้ว \(flow.provinces.count) จังหวัด").font(.sh(16, .semibold)).foregroundStyle(GL.ink)
                .padding(.top, 16).padding(.bottom, 12)

            if found.isEmpty {
                // (= emptyContentView)
                Text("ไม่พบข้อมูลการค้นหา \"\(query)\"").font(.sh(14)).foregroundStyle(PK.hint)
                    .frame(maxWidth: .infinity).padding(.vertical, 24)
            } else {
                PKWrap(spacing: 12) {
                    ForEach(found, id: \.self) { p in
                        let on = flow.provinces.contains(p)
                        ProvinceChip(title: p, on: on, disabled: !on && flow.provinces.count >= Self.max) {
                            if on { flow.provinces.removeAll { $0 == p } }
                            else if flow.provinces.count < Self.max { flow.provinces.append(p) }
                            else { Haptics.rigid() }
                        }
                    }
                }
            }
        }
    }
}

/// = ProvinceOptionViewCell ของ salehere-ios: 44pt · radius 22 · ขอบ Gray200 · ไอคอน 20 (ic-plusCircle-outline / ic-checkCircle-red) + ชื่อ 14 medium Gray600
/// เลือก = ตัวแดง ขอบแดง ✓แดง · ครบจำนวน = ตัว/ไอคอน Gray300 ขอบ Gray50
private struct ProvinceChip: View {
    let title: String
    let on: Bool
    let disabled: Bool
    let action: () -> Void
    private static let gray600 = Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255)
    private static let gray300 = Color(red: 209 / 255, green: 213 / 255, blue: 219 / 255)
    private static let gray200 = Color(red: 229 / 255, green: 231 / 255, blue: 235 / 255)
    private static let gray50 = Color(red: 243 / 255, green: 244 / 255, blue: 246 / 255)

    var body: some View {
        let ink: Color = on ? SH.red : disabled ? Self.gray300 : Self.gray600
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            HStack(spacing: 6) {
                PIcon(on ? .checkCircle : .plusCircle, size: 20, weight: on ? .fill : .regular).foregroundStyle(ink)
                Text(title).font(.sh(14, .medium)).foregroundStyle(ink).lineLimit(1)
            }
            .padding(.horizontal, 12).frame(height: 44)
            .background(Capsule().fill(.white))
            .overlay(Capsule().strokeBorder(on ? SH.red : disabled ? Self.gray50 : Self.gray200, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(Motion.snap, value: on)
    }
}

/// 7 วัน + ชิปช่วงเวลา — แตะวัน = เลือกวันที่กำลังตั้ง · ติ๊กช่วงเวลา = เปลี่ยนเฉพาะวันนั้น (ผู้ใช้ 2 ต.ค. 2569)
/// วงดำ = วันที่กำลังตั้ง · วงเทาขอบดำ = มีช่วงแล้ว · จุด 4 จุดใต้วง = 4 ช่วงนาฬิกาของวันนั้น (ช่วงเดียวกับหน้า "วันและเวลาที่สะดวกรับงาน" ของ salehere-ios)
private struct WzAvailability: View {
    @Environment(StarFlow.self) private var flow
    /// วันที่เลือกอยู่ — จำข้ามการกดย้อน/ถัดไป (salehere-ios เก็บใน presenter)
    @AppStorage("starflow.availDay") private var day = "จ"
    private let days = IntakeCatalog.weekShort
    private let slots = StarFlow.daySlots
    private static let full = ["จ": "จันทร์", "อ": "อังคาร", "พ": "พุธ", "พฤ": "พฤหัสฯ", "ศ": "ศุกร์", "ส": "เสาร์", "อา": "อาทิตย์"]

    private var cur: [String] { flow.availWeek[day] ?? [] }

    private func setCur(_ list: [String]) {
        var w = flow.availWeek
        w[day] = list.isEmpty ? nil : slots.filter(list.contains)
        flow.availWeek = w
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 6) {
                ForEach(days, id: \.self) { d in
                    let have = flow.availWeek[d] ?? []
                    Button { Haptics.impact(.light); withAnimation(Motion.snap) { day = d } } label: {
                        VStack(spacing: 6) {
                            Text(d).font(.sh(15, .bold)).foregroundStyle(d == day ? .white : GL.ink)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(d == day ? GL.ink : have.isEmpty ? .white : PK.pick))
                                .overlay(Circle().strokeBorder(d == day || !have.isEmpty ? GL.ink : PK.line, lineWidth: have.isEmpty && d != day ? 1 : 1.5))
                            HStack(spacing: 3) {
                                ForEach(slots, id: \.self) { s in
                                    Circle().fill(have.contains(s) ? GL.ink : PK.line).frame(width: 5, height: 5)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
            (Text("ช่วงเวลา · ").foregroundStyle(PK.hint) + Text(Self.full[day] ?? day).foregroundStyle(GL.ink))
                .font(.sh(12.5, .semibold))
                .padding(.top, 14).padding(.bottom, 8)
            PKWrap(spacing: 8) {
                ForEach(slots, id: \.self) { t in
                    WzChip(text: StarFlow.slotLabel(t), on: cur.contains(t)) {
                        setCur(cur.contains(t) ? cur.filter { $0 != t } : cur + [t])
                    }
                }
                WzChip(text: "ตลอดวัน", on: cur.count == slots.count) {
                    setCur(cur.count == slots.count ? [] : slots)
                }
            }
        }
    }
}

/// ช่องทางติดต่อ — ขึ้นบนการ์ด (ผู้ใช้ 2 ต.ค. 2569) · LINE หรือเบอร์อย่างน้อย 1 · เว็บไม่บังคับ
private struct WzContact: View {
    @Environment(StarFlow.self) private var flow
    var body: some View {
        @Bindable var f = flow
        VStack(spacing: 10) {
            WzInput(label: "LINE ID", text: $f.lineID, placeholder: "@yourlineid", keyboard: .asciiCapable)
            WzInput(label: "เบอร์โทร", text: $f.phone, placeholder: "08x-xxx-xxxx", keyboard: .phonePad, digits: 10)
            WzInput(label: "เว็บไซต์ · ไม่บังคับ", text: $f.website, placeholder: "yourname.com", keyboard: .URL)
        }
        // เติมให้ล่วงหน้าเมื่อยังว่าง (salehere-ios): เบอร์จากบัญชี → ไม่มีเอาจากที่อยู่รับของ · LINE จากบัญชี · ต้องผ่าน format ก่อน ไม่ผ่านเว้นว่าง
        // แค่เติมให้ ยังไม่นับว่าครบจนกว่าจะกดถัดไป
        .onAppear {
            if flow.phone.isEmpty, let t = StarFlow.prefillPhone(SHMockUser.accountTel) ?? StarFlow.prefillPhone(flow.addressInfo.tel) { flow.phone = t }
            if flow.lineID.isEmpty, StarFlow.validLine(SHMockUser.accountLine) { flow.lineID = SHMockUser.accountLine }
        }
    }
}

/// สัดส่วน = หน้า "สัดส่วน" ของ salehere-ios (CreatorBodyFormPage) ตัวต่อตัว: 6 ช่อง 2 คอลัมน์ · แตะช่อง = wheel picker ค่า + หน่วยของช่องนั้น
/// แต่ละช่องมีหน่วยของตัวเอง (รอบอก/เอว/สะโพก นิ้วหรือซม. · รองเท้า EU ครึ่งเบอร์) — ผู้ใช้ 6 ต.ค. 2569: "แต่ละอันมันมี unit ของตัวเอง ลองดูใน salehere-ios"
/// (ก่อนหน้า: ปุ่มสลับในช่อง → "ux ไม่ดี" · segmented ชุดเดียว → ไม่ตรงแอปหลัก)
private struct WzBody: View {
    @Environment(StarFlow.self) private var flow
    @Environment(WzErrors.self) private var errors: WzErrors?
    @Binding var pick: BodyField?
    @State private var guide = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) { cell(.weight); cell(.height) }
            HStack(spacing: 10) { cell(.chest); cell(.waist) }
            HStack(spacing: 10) { cell(.hip); cell(.shoe) }
            Button {
                Haptics.impact(.light)
                withAnimation(Motion.snap) { guide.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text("วิธีการวัดขนาด").font(.sh(13.5, .bold))
                    PIcon(.info, size: 15)
                }
                .foregroundStyle(SH.blue)
                .frame(height: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if guide {
                Image("ic-body-Info")
                    .resizable().scaledToFit()
                    .padding(14)
                    .background(PK.shape(16).fill(.white))
                    .overlay(PK.shape(16).strokeBorder(PK.line, lineWidth: 1))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    /// ช่องอ่านอย่างเดียว หน้าตาเดียวกับ `WzInput` — แตะแล้วเปิด wheel (แอปหลัก: BaseInputTextFieldView disabled + onTapGesture)
    private func cell(_ f: BodyField) -> some View {
        let value = f.value(in: flow.bodyInfo), error = errors?.map[f.label]
        return VStack(alignment: .leading, spacing: 5) {
        Button {
            Haptics.impact(.light)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            pick = f
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(f.label).font(.sh(11.5, .semibold)).foregroundStyle(PK.hint)
                HStack(spacing: 6) {
                    Text(value.isEmpty ? f.placeholder : value).font(.sh(17))
                        .foregroundStyle(value.isEmpty ? PK.hint.opacity(0.7) : GL.ink)
                    Spacer(minLength: 0)
                    Text(f.unit(in: flow.bodyInfo)).font(.sh(15, .semibold)).foregroundStyle(PK.hint)
                }
                .frame(height: 30)
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 6)
            .background(PK.shape(16).fill(.white))
            .overlay(PK.shape(16).strokeBorder(error != nil ? PK.red : pick == f ? GL.ink : PK.line, lineWidth: error != nil ? 1.5 : 1))
            .contentShape(PK.shape(16))
        }
        .buttonStyle(.plain)
            if let error { WzFieldError(text: error) }
        }
        .id("wz:" + f.label)
        .onChange(of: value) { _, _ in errors?.clear(f.label) }
    }
}

/// ช่องสัดส่วน + ช่วงค่าและหน่วยของ wheel (= `inputFields` ใน CreatorBodyFormPageMainPresenter ของ salehere-ios)
enum BodyField: String, CaseIterable, Identifiable {
    case weight, height, chest, waist, hip, shoe
    var id: String { rawValue }
    var label: String {
        switch self {
        case .weight: return "น้ำหนัก"
        case .height: return "ส่วนสูง"
        case .chest: return "รอบอก"
        case .waist: return "รอบเอว"
        case .hip: return "สะโพก"
        case .shoe: return "ขนาดรองเท้า"
        }
    }
    /// หัว sheet = PROFILE_CREATOR_*_PICKER_TITLE
    var title: String { self == .height ? "เลือกส่วนสูง" : self == .weight ? "เลือกน้ำหนัก" : "เลือก\(label)" }
    var placeholder: String { "ระบุ\(label)" }
    /// ช่วงตัวเลขบนวงล้อ (ค่าเดียวกับแอปหลัก)
    var range: ClosedRange<Int> {
        switch self {
        case .weight: return 0...200
        case .height: return 50...250
        case .chest, .waist, .hip: return 20...150
        case .shoe: return 10...60
        }
    }
    var defaultValue: Int {
        switch self {
        case .weight: return 50
        case .height: return 150
        case .chest, .hip: return 32
        case .waist: return 28
        case .shoe: return 37
        }
    }
    /// หน่วยที่เลือกได้ของช่องนี้ — รอบตัวเลือกได้ นอกนั้นคงที่
    var units: [String] {
        switch self {
        case .weight: return ["กก."]
        case .height: return [StarBody.cm]
        case .chest, .waist, .hip: return StarBody.girthUnits
        case .shoe: return ["EU"]
        }
    }
    var isGirth: Bool { units.count > 1 }
    func value(in b: StarBody) -> String {
        switch self {
        case .weight: return b.weight
        case .height: return b.height
        case .chest: return b.chest
        case .waist: return b.waist
        case .hip: return b.hip
        case .shoe: return b.shoe
        }
    }
    func unit(in b: StarBody) -> String {
        switch self {
        case .chest: return b.chestUnit
        case .waist: return b.waistUnit
        case .hip: return b.hipUnit
        default: return units[0]
        }
    }
    func write(_ value: String, unit: String, to b: inout StarBody) {
        switch self {
        case .weight: b.weight = value
        case .height: b.height = value
        case .chest: b.chest = value; b.chestUnit = unit
        case .waist: b.waist = value; b.waistUnit = unit
        case .hip: b.hip = value; b.hipUnit = unit
        case .shoe: b.shoe = value
        }
    }
}

/// วงล้อเลือกค่า + หน่วย ของช่องเดียว (= MultiWheelPickerModal ของ salehere-ios: หัวข้อ · วงล้อเรียงกัน · ปุ่มตกลง) · รองเท้ามีวงล้อ .0/.5 เพิ่ม
private struct BodyWheelSheet: View {
    @Environment(StarFlow.self) private var flow
    let field: BodyField
    let done: () -> Void
    @State private var whole = 0
    @State private var half = 0
    @State private var unit = ""

    var body: some View {
        VStack(spacing: 0) {
            Text(field.title).font(.sh(18, .heavy)).foregroundStyle(GL.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            HStack(spacing: 0) {
                Picker("", selection: $whole) {
                    ForEach(Array(field.range), id: \.self) { Text(String($0)).font(.sh(18, .semibold)).tag($0) }
                }
                .pickerStyle(.wheel).frame(maxWidth: .infinity).clipped()
                if field == .shoe {
                    Picker("", selection: $half) {
                        Text(".0").font(.sh(18, .semibold)).tag(0)
                        Text(".5").font(.sh(18, .semibold)).tag(5)
                    }
                    .pickerStyle(.wheel).frame(width: 80).clipped()
                }
                // วงล้อหน่วยเฉพาะรอบอก/เอว/สะโพก · น้ำหนัก ส่วนสูง รองเท้า = ป้ายหน่วยคงที่ (salehere-ios `WzBottomPanel`)
                if field.isGirth {
                    Picker("", selection: $unit) {
                        ForEach(field.units, id: \.self) { Text($0).font(.sh(18, .semibold)).tag($0) }
                    }
                    .pickerStyle(.wheel).frame(width: 110).clipped()
                } else {
                    Text(field.units[0]).font(.sh(18, .semibold)).foregroundStyle(GL.ink).frame(width: 110)
                }
            }
            .frame(height: 190)
            PKPrimaryButton(title: "ตกลง") {
                var b = flow.bodyInfo
                let text = field == .shoe && half == 5 ? "\(whole).5" : String(whole)
                field.write(text, unit: unit, to: &b)
                flow.bodyInfo = b
                Haptics.impact(.light)
                done()
            }
            .padding(.top, 8)
        }
        .onAppear {
            let b = flow.bodyInfo
            let cur = field.value(in: b)
            let parts = cur.split(separator: ".")
            whole = parts.first.flatMap { Int($0) } ?? field.defaultValue
            half = parts.count > 1 && parts[1].hasPrefix("5") ? 5 : 0
            unit = field.unit(in: b)
        }
    }
}

private struct WzAddress: View {
    @Environment(StarFlow.self) private var flow
    var body: some View {
        @Bindable var f = flow
        VStack(spacing: 10) {
            WzInput(label: "ชื่อ–นามสกุล", text: $f.addressInfo.name)
            WzInput(label: "เบอร์โทรศัพท์", text: $f.addressInfo.tel, keyboard: .phonePad, digits: 10)
            WzInput(label: "ที่อยู่", text: $f.addressInfo.address, placeholder: "เลขที่ อาคาร ซอย ถนน")
            HStack(spacing: 10) {
                WzInput(label: "รหัสไปรษณีย์", text: Binding(get: { flow.addressInfo.zip }, set: { z in
                    guard z != flow.addressInfo.zip else { return }
                    flow.addressInfo.zip = z; flow.addressInfo.sub = ""; flow.addressInfo.district = ""; flow.addressInfo.province = ""
                }), keyboard: .numberPad, digits: 5)
                // ตำบลจาก `ZipBook` (= `getSubDistricts`) → อำเภอ/จังหวัดเติมให้ (= `getDistrictProvince`) ชุดเดียวกับฟอร์มสมัคร
                WzInput(label: "ตำบล/แขวง", text: Binding(get: { flow.addressInfo.sub }, set: { s in
                    flow.addressInfo.sub = s
                    if let p = ZipBook.place(flow.addressInfo.zip, s) { flow.addressInfo.district = p.district; flow.addressInfo.province = p.province }
                }), select: true, options: ZipBook.subs(flow.addressInfo.zip))
            }
            HStack(spacing: 10) {
                WzInput(label: "อำเภอ/เขต", text: $f.addressInfo.district)
                WzInput(label: "จังหวัด", text: $f.addressInfo.province)
            }
        }
    }
}

/// การรับเงิน = `PAYDOC` ของฟอร์มเว็บ v16.1: เลือกนามบุคคล/นามบริษัทก่อน แล้วช่องเปลี่ยนตามชุดนั้น
/// (ผู้ใช้ 24 ก.ย. 2569: "ตอนรับงานต้องถามด้วยว่านามบุคคล/บริษัท")
private struct WzBank: View {
    @Environment(StarFlow.self) private var flow

    private var company: Bool { flow.payKind == "company" }

    var body: some View {
        @Bindable var f = flow
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                kindTile("person", .user, "นามบุคคล", "หัก ณ ที่จ่าย 3%")
                kindTile("company", .buildings, "นามบริษัท", "หัก ณ ที่จ่าย 7%")
            }
            Text(company ? "ชื่อบัญชีต้องตรงกับชื่อนิติบุคคลเป๊ะ ๆ รวมคำว่า \"บริษัท\" และ \"จำกัด\""
                         : "ชื่อบัญชีต้องตรงกับชื่อ–นามสกุลจริงของคุณ ไม่งั้นเงินจะโอนไม่เข้า")
                .font(.sh(12.5)).foregroundStyle(PK.muted).padding(.bottom, 2)
            if company {
                WzInput(label: "ชื่อนิติบุคคล", text: $f.bankInfo.coName, placeholder: "บริษัท ... จำกัด")
                WzInput(label: "เลขประจำตัวผู้เสียภาษี (13 หลัก)", text: $f.bankInfo.taxID, placeholder: "0xxxxxxxxxxxx", keyboard: .numberPad, digits: 13)
                WzInput(label: "สำนักงานใหญ่ / สาขา", text: $f.bankInfo.branch, select: true, options: ["สำนักงานใหญ่", "สาขา"])
                WzInput(label: "ที่อยู่ตามหนังสือรับรอง", text: $f.bankInfo.address, placeholder: "เลขที่ ถนน แขวง เขต จังหวัด รหัสไปรษณีย์")
                // ชื่อกรรมการผู้มีอำนาจลงนาม ตัดออก 6 ต.ค. 2569 — `CampaignPayoutSubmit` ไม่มีช่อง (OCR อ่านจากหนังสือรับรองแทน)
                WzInput(label: "จดทะเบียน VAT หรือไม่", text: $f.bankInfo.vat, select: true, options: ["จดทะเบียน VAT", "ไม่ได้จดทะเบียน VAT"])
            }
            WzInput(label: "ธนาคาร", text: $f.bankInfo.bank, select: true, options: StarBank.banks)
            WzInput(label: "เลขที่บัญชี", text: $f.bankInfo.no, placeholder: "xxxxxxxxxx", keyboard: .numberPad, digits: 15)
            WzInput(label: "ชื่อบัญชี", text: $f.bankInfo.name, placeholder: company ? "ตามชื่อนิติบุคคล" : "ตามหน้าสมุดบัญชี")
            // ไม่มีบรรทัด "ชื่อตรงกับบัตร" และปุ่มถ่ายสมุดบัญชี (salehere-ios ไม่มี — ฟอร์ม payout เดิมขอเอกสารตอนจ่ายจริง)
            Text(company ? "ขอทีหลัง: หนังสือรับรองบริษัท (ไม่เกิน 6 เดือน) · ภ.พ.20 ถ้าจด VAT" : "ขอทีหลัง: สำเนาบัตรประชาชน เซ็นรับรองสำเนาถูกต้อง")
                .font(.sh(11.5)).foregroundStyle(PK.hint)
        }
        .animation(Motion.snap, value: company)
    }

    private func kindTile(_ key: String, _ icon: Ph, _ title: String, _ sub: String) -> some View {
        let on = flow.payKind == key
        return Button {
            Haptics.impact(.light)
            withAnimation(Motion.snap) { flow.payKind = key }
        } label: {
            VStack(spacing: 6) {
                PIcon(icon, size: 22, weight: .regular).foregroundStyle(GL.ink)
                Text(title).font(.sh(14, .bold)).foregroundStyle(GL.ink)
                Text(sub).font(.sh(11.5)).foregroundStyle(PK.muted)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(PK.shape(16).fill(on ? PK.pick : .white))
            .overlay(PK.shape(16).strokeBorder(on ? GL.ink : PK.line, lineWidth: on ? 1.5 : 1))
            .contentShape(PK.shape(16))
        }
        .buttonStyle(.plain)
    }
}

private struct WzDraftRounds: View {
    @Environment(StarFlow.self) private var flow
    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...3, id: \.self) { n in
                WzTile(title: String(n), sub: "ครั้ง", on: flow.draftRounds == n) { flow.draftRounds = n }
            }
        }
    }
}

/// งานที่ขอผ่าน = `SUB.limit` ของฟอร์มเว็บ v16.1 — เก็บค่า `v` · "ไม่มีข้อจำกัด" เลือกได้ข้อเดียว · ✏️ อื่น ๆ พิมพ์เอง
private struct WzLimits: View {
    @Environment(StarFlow.self) private var flow
    @State private var otherOn = false
    private static let none = "ไม่มีข้อจำกัด"
    private let opts: [(v: String, label: String)] = [
        (none, "😄 รับได้หมดเลย"),
        ("ไม่รับงานสินเชื่อ / คริปโต", "💳 สินเชื่อ / คริปโต"),
        ("ไม่รับงานแอลกอฮอล์ / บุหรี่ / บุหรี่ไฟฟ้า", "🍺 แอลกอฮอล์ / บุหรี่"),
        ("ไม่รับงานอาหารเสริม / ลดน้ำหนัก", "💊 อาหารเสริม / ลดน้ำหนัก"),
        ("ไม่รับงานความงามเชิงการแพทย์ (ศัลยกรรม / ฉีด)", "💉 ความงามเชิงการแพทย์"),
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PKWrap(spacing: 8) {
                ForEach(opts, id: \.v) { o in
                    let on = flow.limits.contains(o.v)
                    WzChip(text: o.label, on: on) { toggle(o.v, on) }
                }
                WzChip(text: "✏️ อื่น ๆ", on: otherOn) {
                    otherOn.toggle()
                    if otherOn { flow.limits.removeAll { $0 == Self.none } } else { flow.limitOther = "" }
                }
            }
            if otherOn {
                WzInput(label: "อื่น ๆ", text: Binding(get: { flow.limitOther }, set: { flow.limitOther = $0 }),
                        placeholder: "เช่น ไม่รับงานที่ต้องค้างคืนต่างจังหวัด")
            }
        }
        .onAppear { otherOn = !flow.limitOther.isEmpty }
    }
    private func toggle(_ v: String, _ on: Bool) {
        if on { flow.limits.removeAll { $0 == v }; return }
        if v == Self.none { flow.limits = [v]; flow.limitOther = ""; otherOn = false }
        else { flow.limits.removeAll { $0 == Self.none }; flow.limits.append(v) }
    }
}

/// `SUB.religion` ของฟอร์มเว็บ v16.1 — เลือกข้อเดียว
private struct WzReligion: View {
    @Environment(StarFlow.self) private var flow
    var body: some View {
        PKWrap(spacing: 8) {
            ForEach(["พุทธ", "อิสลาม", "คริสต์", "ฮินดู", "อื่น ๆ / ไม่ระบุ"], id: \.self) { r in
                WzChip(text: r, on: flow.religion == r) { flow.religion = r }
            }
        }
    }
}

/// สั่นซ้ายขวาตอนกดถัดไปทั้งที่ยังไม่ผ่านเงื่อนไข (= `.shake` ของเว็บ)
struct WzShake: ViewModifier {
    let trigger: Int
    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat(0), trigger: trigger) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            CubicKeyframe(-8, duration: 0.06)
            CubicKeyframe(8, duration: 0.06)
            CubicKeyframe(-5, duration: 0.06)
            CubicKeyframe(5, duration: 0.06)
            CubicKeyframe(0, duration: 0.08)
        }
    }
}


/// Creator (บุคคล) / Page (เพจ) — ขั้น `type` ของฟอร์มเว็บ v16.1 (ไอคอนในกล่องแดงอ่อน · ชื่อ · คำอธิบาย · วงกลมเลือก)
private struct WzKind: View {
    @Environment(StarFlow.self) private var flow
    private let options: [(String, Ph, String, String)] = [
        ("creator", .user, "Creator (บุคคล)", "ตัวคุณเองเป็นคนสร้างคอนเทนต์"),
        ("page", .browsers, "Page (เพจ)", "บริหารเพจ/สื่อในนามทีมหรือแบรนด์"),
    ]
    var body: some View {
        VStack(spacing: 10) {
            ForEach(options, id: \.0) { key, icon, title, sub in
                let on = flow.creatorKind == key
                Button {
                    Haptics.impact(.light)
                    withAnimation(Motion.snap) { flow.creatorKind = key }
                } label: {
                    HStack(spacing: 14) {
                        PIcon(icon, size: 22, weight: .regular).foregroundStyle(PK.red)
                            .frame(width: 48, height: 48)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(PK.redTint))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(title).font(.sh(16, .bold)).foregroundStyle(GL.ink)
                            Text(sub).font(.sh(13)).foregroundStyle(PK.muted)
                        }
                        Spacer()
                        Circle().strokeBorder(on ? GL.ink : PK.line2, lineWidth: on ? 6 : 1.2).frame(width: 22, height: 22)
                    }
                    .padding(16)
                    .background(PK.shape(18).fill(on ? PK.pick : .white))
                    .overlay(PK.shape(18).strokeBorder(on ? GL.ink : PK.line, lineWidth: on ? 1.5 : 1))
                    .contentShape(PK.shape(18))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - รูปและผลงาน — ขั้นเดียวก่อนเป็น STAR: รูปของคุณ · รูปผลงาน · วิดีโอผลงาน (ผู้ใช้ 24 ก.ย. 2569)

/// สามหมวดในหน้าเดียว — หัวหมวดบอกขั้นต่ำ ครบแล้วขึ้นเครื่องหมายถูกสีเขียว
private struct WzMediaAll: View {
    let onError: (String) -> Void
    private var folio: Portfolio { Portfolio.shared }
    /// โชว์ครบ 3 หมวดเสมอ — หมวดที่ครบมีติ๊กเขียว ห้ามซ่อน (salehere-ios STAR-FLOW-RULES ข้อ 4)
    private let shown: Set<WzMedia.Kind> = [.photos, .works, .videos]
    @Environment(PhotoStore.self) private var photos: PhotoStore?

    /// หมวดที่ยังไม่ถึงขั้นต่ำ → (คีย์หมวด, "1 คลิป") · error ขึ้นใต้หมวดนั้น (คีย์ "media:videos")
    static func lack() -> [(kind: String, text: String)] {
        let f = Portfolio.shared
        return [("photos", f.creatorImages.count, StarFlow.minPhotos, "รูป"), ("works", f.works.count, StarFlow.minWorks, "รูป"), ("videos", f.videos.count, StarFlow.minVideos, "คลิป")]
            .filter { $0.1 < $0.2 }.map { (kind: $0.0, text: "\($0.2 - $0.1) \($0.3)") }
    }
    @Environment(WzErrors.self) private var errors: WzErrors?
    /// error ของหมวด — โชว์เฉพาะตอนยังขาดจริง (ใส่ครบแล้วหายเอง)
    private func sectionError(_ kind: String) -> String? {
        guard errors?.map["media:" + kind] != nil, let l = Self.lack().first(where: { $0.kind == kind }) else { return nil }
        return "ยังขาด " + l.text
    }

    /// ข้อที่ยังไม่ถึงขั้นต่ำ (nil = ครบ) — ข้อความบอกว่าขาดอะไรเท่าไร
    static func missing() -> String? {
        let f = Portfolio.shared
        var lack: [String] = []
        if f.creatorImages.count < StarFlow.minPhotos { lack.append("รูปของคุณ \(StarFlow.minPhotos - f.creatorImages.count) รูป") }
        if f.works.count < StarFlow.minWorks { lack.append("รูปผลงาน \(StarFlow.minWorks - f.works.count) รูป") }
        if f.videos.count < StarFlow.minVideos { lack.append("คลิป \(StarFlow.minVideos - f.videos.count) คลิป") }
        return lack.isEmpty ? nil : lack.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if shown.contains(.photos) {
                section("รูปของคุณ", key: "photos", have: folio.creatorImages.count, min: StarFlow.minPhotos, note: "\(StarFlow.minPhotos)–\(Portfolio.creatorSlots) รูป") {
                    WzMedia(kind: .photos, onError: onError)
                }
            }
            if shown.contains(.works) {
                section("รูปผลงาน", key: "works", have: folio.works.count, min: StarFlow.minWorks, note: "\(StarFlow.minWorks)–\(Portfolio.workMax) รูป") {
                    WzMedia(kind: .works, onError: onError)
                }
            }
            if shown.contains(.videos) {
                section("วิดีโอผลงาน", key: "videos", have: folio.videos.count, min: StarFlow.minVideos, note: "\(StarFlow.minVideos)–\(Portfolio.videoMax) คลิป") {
                    WzMedia(kind: .videos, onError: onError)
                }
            }
            if StarFlow.shared.keepsData {
                Text("เป็น STAR แล้ว เปลี่ยนได้ ลบไม่ได้").font(.sh(12.5)).foregroundStyle(PK.hint)
            }
        }
        // ช่องรูปที่ 1 ใช้รูปโปรไฟล์ให้ (salehere-ios) — ยังไม่มีรูปของคุณเลยเท่านั้น
        .onAppear {
            if folio.creatorImages.isEmpty, let p = photos?.profile { folio.setCreator(p, at: 0) }
        }
    }

    private func section<C: View>(_ title: String, key: String, have: Int, min: Int, note: String?, @ViewBuilder _ content: () -> C) -> some View {
        let error = sectionError(key)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(title).font(.sh(15, .bold)).foregroundStyle(GL.ink)
                if let note { Text(note).font(.sh(12)).foregroundStyle(PK.hint).lineLimit(1) }
                Spacer(minLength: 4)
                if have >= min {
                    PIcon(.checkCircle, size: 16, weight: .fill).foregroundStyle(GL.green)
                } else {
                    Text("\(have)/\(min)").font(.sh(12.5, .bold)).monospacedDigit().foregroundStyle(error != nil ? PK.red : PK.hint)
                }
            }
            content()
            if let error { WzFieldError(text: error) }
        }
        .id("wz:media:" + key)
        .animation(Motion.snap, value: error)
    }
}
//
// เก็บลง `Portfolio` ที่เดียวกับหน้าแก้ไขโปรไฟล์ — การ์ดอ่านจากที่นี่ทันที · ใช้ช่องรูปชุดเดียวกัน (MediaTile / AddTile)

private struct WzMedia: View {
    enum Kind { case photos, works, videos }
    let kind: Kind
    let onError: (String) -> Void

    private var folio: Portfolio { Portfolio.shared }
    /// เป็น STAR แล้ว = ปุ่มมุมเป็น "เปลี่ยน" (เลือกไฟล์ใหม่มาแทนช่องเดิม) ไม่มีลบ
    private var swaps: Bool { StarFlow.shared.keepsData }
    @Environment(WzErrors.self) private var errors: WzErrors?
    private var key: String { kind == .photos ? "photos" : kind == .works ? "works" : "videos" }
    private var minimum: Int { kind == .photos ? StarFlow.minPhotos : kind == .works ? StarFlow.minWorks : StarFlow.minVideos }
    @State private var importing = 0
    @State private var removal: Removal?
    @State private var playing: Portfolio.Video?
    /// ช่องที่กำลังโหลดไฟล์ใหม่มาแทน
    @State private var swapping: String?

    private enum Removal: Identifiable {
        case creator(Int), work(UUID), video(UUID)
        var id: String {
            switch self {
            case .creator(let i): return "c\(i)"
            case .work(let u): return "w\(u)"
            case .video(let u): return "v\(u)"
            }
        }
    }

    private var grid: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 10), count: 3) }
    /// รูปของคุณ + รูปผลงาน = 3:4 แนวตั้ง (ผู้ใช้ 7 ต.ค. 2569 · ตรงกับช่องรูปบนการ์ด) · คลิปยังจัตุรัส
    private var ratio: CGFloat { kind == .videos ? 1 : 3 / 4 }
    private var max: Int { kind == .photos ? Portfolio.creatorSlots : kind == .works ? Portfolio.workMax : Portfolio.videoMax }
    private var have: Int { kind == .photos ? folio.creatorImages.count : kind == .works ? folio.works.count : folio.videos.count }
    private var left: Int { Swift.max(0, max - have - importing) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: grid, spacing: 10) {
                switch kind {
                case .photos:
                    ForEach(0..<Portfolio.creatorSlots, id: \.self) { i in
                        if let img = folio.creators[i] {
                            // แตะช่อง = เลือกรูปใหม่มาแทน · ไม่มีปุ่มมุม (salehere-ios)
                            MediaTile(image: img, ratio: ratio, loading: swapping == "c\(i)", onTap: { replace(.creator(i)) },
                                      onRemove: {}, swaps: swaps, showsCorner: false)
                        } else if folio.creators.prefix(i).filter({ $0 == nil }).count < importing {
                            PendingTile(ratio: ratio)
                        } else {
                            adder("รูปที่ \(i + 1)")
                        }
                    }
                case .works:
                    ForEach(folio.works) { w in
                        MediaTile(image: w.image, ratio: ratio, loading: swapping == "w\(w.id)", onTap: {}, onRemove: { corner(.work(w.id)) }, swaps: swaps)
                    }
                    ForEach(0..<importing, id: \.self) { _ in PendingTile(ratio: ratio) }
                    if left > 0 { adder("เพิ่มรูป") }
                case .videos:
                    ForEach(folio.videos) { v in
                        MediaTile(image: v.thumb, duration: v.duration, ratio: 1, loading: swapping == "v\(v.id)", onTap: { playing = v },
                                  onRemove: { corner(.video(v.id)) }, swaps: swaps)
                    }
                    ForEach(0..<importing, id: \.self) { _ in PendingTile(ratio: 1) }
                    if left > 0 { adder("เพิ่มคลิป") }
                }
            }
        }
        .animation(Motion.settle, value: have)
        .confirmationDialog(kind == .videos ? "ลบคลิปนี้?" : "ลบรูปนี้?",
                            isPresented: Binding(get: { removal != nil }, set: { if !$0 { removal = nil } }),
                            titleVisibility: .visible) {
            Button("ลบ", role: .destructive) {
                switch removal {
                case .creator(let i)?: folio.clearCreator(at: i)
                case .work(let id)?: folio.removeWork(id)
                case .video(let id)?: folio.removeVideo(id)
                case nil: break
                }
                removal = nil
            }
            Button("ยกเลิก", role: .cancel) { removal = nil }
        }
        .fullScreenCover(item: $playing) { v in VideoSheet(url: v.file) { playing = nil } }
    }

    /// ปุ่มมุมของช่อง: ยังไม่เป็น STAR = ถามลบ · เป็นแล้ว = เลือกไฟล์ใหม่มาแทนที่ช่องเดิม
    private func corner(_ t: Removal) {
        guard swaps else { removal = t; return }
        replace(t)
    }

    /// เลือกไฟล์ใหม่มาแทนที่ช่องเดิม
    private func replace(_ t: Removal) {
        Haptics.impact(.light)
        MediaPicker.present(videos: kind == .videos, limit: 1) { items in
            guard let item = items.first else { return }
            swapping = t.id
            Task { @MainActor in
                defer { swapping = nil }
                switch t {
                case .creator(let i):
                    guard let ui = await MediaPicker.image(item) else { onError("อัปโหลดไม่สำเร็จ ลองใหม่อีกครั้ง"); return }
                    withAnimation(Motion.settle) { folio.setCreator(ui, at: i) }
                case .work(let id):
                    guard let ui = await MediaPicker.image(item) else { onError("อัปโหลดไม่สำเร็จ ลองใหม่อีกครั้ง"); return }
                    withAnimation(Motion.settle) { folio.replaceWork(id, with: ui) }
                case .video(let id):
                    guard let url = await MediaPicker.movie(item) else { onError("อัปโหลดไม่สำเร็จ ลองใหม่อีกครั้ง"); return }
                    switch await folio.replaceVideo(id, from: url) {
                    case .added: break
                    case .tooBig: onError("คลิปใหญ่เกินไป — ตัดให้สั้นลงแล้วลองใหม่"); return
                    case .failed: onError("อัปโหลดไม่สำเร็จ ลองใหม่อีกครั้ง"); return
                    }
                }
                Haptics.impact(.medium)
            }
        }
    }

    private func adder(_ label: String) -> some View {
        Button {
            Haptics.impact(.light)
            // รูปของคุณ = ทีละรูปต่อช่อง (salehere-ios)
            MediaPicker.present(videos: kind == .videos, limit: kind == .photos ? 1 : Swift.max(1, left)) { load($0) }
        } label: { AddTile(label: label, ratio: ratio, invalid: errors?.map["media:" + key] != nil && have < minimum) }
        .buttonStyle(DockPress())
    }

    /// ทีละชิ้น — ชิ้นที่โหลดเสร็จขึ้นก่อน (แบบเดียวกับหน้าแก้ไขโปรไฟล์)
    private func load(_ items: [PHPickerResult]) {
        guard !items.isEmpty else { return }
        importing = items.count
        Task { @MainActor in
            var failed = 0, tooBig = 0
            for item in items {
                switch kind {
                case .photos, .works:
                    if let ui = await MediaPicker.image(item) {
                        withAnimation(Motion.settle) {
                            if kind == .works { folio.addWorks([ui]) }
                            else if let slot = folio.creators.firstIndex(where: { $0 == nil }) { folio.setCreator(ui, at: slot) }
                        }
                    } else { failed += 1 }
                case .videos:
                    if let url = await MediaPicker.movie(item) {
                        switch await folio.addVideo(from: url) {
                        case .added: break
                        case .tooBig: tooBig += 1
                        case .failed: failed += 1
                        }
                    } else { failed += 1 }
                }
                withAnimation(Motion.settle) { importing -= 1 }
            }
            importing = 0
            if tooBig > 0 { onError("คลิปใหญ่เกินไป — ตัดให้สั้นลงแล้วลองใหม่") }
            else if failed > 0 { onError("อัปโหลดไม่สำเร็จ ลองใหม่อีกครั้ง") }
            else { Haptics.impact(.medium) }
        }
    }
}

/// ตัวเลือกรูป/วิดีโอของระบบ เปิดตรงจาก UIKit — `.photosPicker` ใน wizard ค้างไม่ขึ้นจนกว่าจะมีอะไรวาดจอใหม่
/// (หน้า wizard อยู่ใน ZStack ของ shell ที่เปลี่ยน `.id` ทุกครั้ง) จึงไม่พึ่ง presentation ของ SwiftUI
enum MediaPicker {
    @MainActor
    static func present(videos: Bool, limit: Int, done: @escaping ([PHPickerResult]) -> Void) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = videos ? .videos : .images
        config.selectionLimit = limit
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        let delegate = Delegate(done: done)
        picker.delegate = delegate
        objc_setAssociatedObject(picker, &Delegate.key, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        guard var top = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController
        else { return }
        while let next = top.presentedViewController { top = next }
        top.present(picker, animated: true)
    }

    static func image(_ r: PHPickerResult) async -> UIImage? {
        await withCheckedContinuation { c in
            guard r.itemProvider.canLoadObject(ofClass: UIImage.self) else { c.resume(returning: nil); return }
            r.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in c.resume(returning: obj as? UIImage) }
        }
    }

    /// ไฟล์ที่ระบบให้มาถูกลบทันทีหลัง callback — คัดลอกออกมาก่อน
    static func movie(_ r: PHPickerResult) async -> URL? {
        await withCheckedContinuation { c in
            r.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                guard let url else { c.resume(returning: nil); return }
                let copy = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(url.pathExtension)
                c.resume(returning: (try? FileManager.default.copyItem(at: url, to: copy)) != nil ? copy : nil)
            }
        }
    }

    private final class Delegate: NSObject, PHPickerViewControllerDelegate {
        nonisolated(unsafe) static var key = 0
        let done: ([PHPickerResult]) -> Void
        init(done: @escaping ([PHPickerResult]) -> Void) { self.done = done }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            done(results)
        }
    }
}
