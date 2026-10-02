import SwiftUI
import PhosphorSwift

/// แอป Sale Here จำลอง — สองแท็บ (หน้าแรก = Sale Here STAR · โปรไฟล์) ครอบ Star Card ไว้
///
/// เลียนแบบ flow เดิมของแอปหลัก 22 ก.ย. 2569: หน้าแรก → กิจกรรม → ลงทะเบียน · โปรไฟล์ → โปรไฟล์ครีเอเตอร์ → Star Card
/// ตั้งแต่ 23 ก.ย. ครอบ **flow ใหม่** (ถอดจาก unbox-mock/new.html) ไว้ด้วย: ไม่แก้หน้าเดิม แค่แทรกหน้ากรอกข้อมูล Star Profile
/// ก่อนถึงหน้าเดิม — กดสมัคร → wizard → การ์ดเกิด → ฟอร์มสมัคร · กดตอบรับ → wizard → หน้าตอบรับ · โปรไฟล์ครีเอเตอร์ → Star Profile
/// ทั้งชุดไม่ใช้ `NavigationStack` เหมือนส่วนอื่นของแอป — สลับหน้าด้วย state + transition
struct SaleHereShell: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(ClipInvocation.self) private var invocation

    @State private var flow = StarFlow.shared
    /// พื้นที่ Star Card เปิดทับอยู่ — nil = ปิด · ค่า = เปิดที่ไหน (คลัง / ห้องแต่งใบนั้น / เทมเพลต / มุมมองแบรนด์)
    @State private var creatorIntent: StarCardIntent?
    /// กดดูการ์ดตอนยังไม่มี → ถามก่อน แล้วเปิดการ์ดด้วย intent นี้ตอน wizard จบ
    @State private var cardAfterWizard: StarCardIntent?
    /// ธีมของใบที่คลังโฟกัสอยู่ — สีดวงไฟของ `StarGround` ในสถานะการ์ด
    @State private var lampTheme: CardTheme?
    /// คลังการ์ดเป็นหน้าที่เห็นอยู่ (ไม่ใช่เทมเพลต/ห้องแต่ง) — หัวร่วมโผล่เฉพาะตอนนี้
    @State private var galleryVisible = false
    private var isCard: Bool { creatorIntent != nil }
    /// หัวร่วม + พื้นร่วม โผล่เฉพาะตอนอยู่ Star Profile หรือ Star Card
    private var starStage: Bool { screen == .starProfile || creatorIntent != nil }
    @State private var tab: SHTab = .home
    /// กิจกรรมที่กำลังเปิดอ่านทับหน้าแรก — nil = อยู่หน้าแท็บ
    @State private var openCampaign: StarCampaign?
    /// หน้าของ flow ใหม่ที่เปิดทับอยู่
    @State private var screen: FlowScreen?
    /// wizard ที่กำลังเล่น (kind + ขั้นที่ยังขาด + กลับไปไหนเมื่อจบแบบ one)
    @State private var wiz: (kind: WizKind, steps: [WizStep], back: FlowScreen?) = (.apply, [], nil)
    /// นับรอบ wizard — เปิดชุดขั้นใหม่ต้องได้ `StarWizard` ใหม่ (State ของใบเดิมไม่งั้นค้าง)
    @State private var wizToken = 0
    /// ยืนยันตัวตนเปิดทับทุกอย่าง · completion = กลับมาที่หน้าเดิม
    @State private var kyc: (() -> Void)?
    @State private var dialog: FlowDialog?
    @State private var wizExitInfo = (done: 0, total: 0)
    @State private var toastText: String?
    @State private var toastToken = 0
    @State private var showLab = false
    /// แผง lab เพิ่งสั่งเปลี่ยนหน้าเอง — ปิดแผงแล้วไม่ต้องคำนวณ wizard ซ้ำ
    @State private var labNavigated = false
    private let campaigns = StarCampaign.mock

    /// กิจกรรมที่ flow ผูกอยู่ — งานที่เปิดอยู่ ไม่งั้นงานแรก (EP.1585)
    private var campaign: StarCampaign { openCampaign ?? campaigns[0] }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case .home:
                        StarHomePage(campaigns: campaigns) { c in
                            Haptics.impact(.light)
                            withAnimation(Motion.page) { openCampaign = c }
                        }
                    case .profile:
                        SaleHereProfilePage(onCreatorProfile: openCreatorProfile,
                                            campaignCount: 15,
                                            onLab: { showLab = true })
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                SHTabBar(tab: $tab)
            }
            .zIndex(0)

            if let c = openCampaign {
                StarCampaignPage(campaign: c, onBack: {
                    withAnimation(Motion.page) { openCampaign = nil }
                }, onMain: tapMain, onFill: { open(.starProfile) }, onLab: { showLab = true })
                .id(c.id)
                .transition(.asymmetric(insertion: .move(edge: .trailing),
                                        removal: .move(edge: .trailing)))
                .zIndex(1)
            }

            if starStage {
                // พื้น + ดวงไฟที่เดินทางระหว่างสองหน้า — อยู่ใต้ทั้ง Star Profile และ Star Card
                StarGround(isCard: isCard, theme: lampTheme ?? publishedTheme)
                    .transition(.opacity)
                    .zIndex(1.5)
            }

            if let screen {
                flowView(screen)
                    .id(screen == .wizard(wiz.kind) ? "wiz\(wizToken)" : "\(screen)")
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                    // ตอน Star Card เปิดทับ หน้าโปรไฟล์ถอยไปข้างหลังเล็กน้อย (หัวร่วมกับพื้นไม่ขยับ)
                    .offset(x: isCard ? -48 : 0)
                    .scaleEffect(isCard ? 0.96 : 1)
                    .opacity(isCard ? 0 : 1)
                    .animation(Motion.page, value: isCard)
                    .zIndex(2)
            }

            if let intent = creatorIntent {
                StarCardSpace(intent: intent, onExit: { withAnimation(Motion.page) { creatorIntent = nil } },
                              onFocusTheme: { lampTheme = $0 },
                              onGalleryVisible: { v in withAnimation(Motion.settle) { galleryVisible = v } })
                    .environment(photos)
                    .environment(invocation)
                    .id(intent.id)
                    .transition(.modifier(active: PageSlide(progress: 0), identity: PageSlide(progress: 1)))
                    .zIndex(3)
            }

            if starStage, creatorIntent == nil || galleryVisible {
                // หัวร่วม: "Star Profile/Card" + toggle — ชิ้นเดียว อยู่ที่เดิมทั้งสองหน้า
                VStack {
                    StarHeader(isCard: isCard, hasCard: flow.hasCard, showsDot: !CardLibrary.shared.records.isEmpty, showsToggle: false) { toCard in
                        withAnimation(Motion.page) { creatorIntent = toCard ? .gallery : nil }
                    }
                    .padding(.top, 50)
                    Spacer()
                }
                .transition(.opacity)
                .zIndex(3.5)
            }

            if isCard && galleryVisible {
                // หน้า Star Card = หน้าลึกลงไปจาก Star Profile — ‹ ที่เดียวกับปุ่มกลับของหน้า Profile (แทน toggle)
                VStack {
                    HStack {
                        GlassCircleButton(symbol: .caretLeft) { withAnimation(Motion.page) { creatorIntent = nil } }
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.top, 8)
                    Spacer()
                }
                .transition(.opacity)
                .zIndex(3.6)
            }

            // ปุ่ม Lab ลอยอยู่ทุกหน้าทุกที่ (รวมห้องแต่ง/คลัง) — เครื่องมือทดสอบ ไม่ใช่ UI จริง
            // ซ่อนได้ตอนแคปจอ (`-hideLab YES`) — แผงยังเปิดได้จากกดค้างแถบแดง
            if !LabFab.hidden {
                LabFab { showLab = true }
                    .allowsHitTesting(!showLab)
                    .zIndex(20)
            }

            if let done = kyc {
                KycMockPage(onClose: { withAnimation(Motion.page) { kyc = nil } },
                            onDone: { withAnimation(Motion.page) { kyc = nil }; done() })
                    .transition(.move(edge: .bottom))
                    // เหนือหัวร่วม "Star Profile" (3.5) — ไม่งั้นหัวทับหน้ายืนยันตัวตน
                    .zIndex(3.8)
            }

            if let dialog { dialogView(dialog).zIndex(4) }

            if let toastText {
                VStack { Spacer(); FlowToast(text: toastText) }
                    .zIndex(5)
                    .allowsHitTesting(false)
            }
        }
        .background(SH.page.ignoresSafeArea())
        .preferredColorScheme(.light)
        .environment(flow)
        // ตู้ widget ขอไปดูงานที่เปิดรับ → กลับแท็บหน้าแรก (รายการกิจกรรม STAR)
        .onChange(of: flow.jobsRequested) { _, on in
            guard on else { return }
            flow.jobsRequested = false
            withAnimation(Motion.page) { screen = nil; openCampaign = nil; tab = .home }
            toast("รับงานแรกให้จบ แล้วใบแบรนด์/ผลงานยืนยันจะเปิดเอง")
        }
        // fullScreenCover ไม่ใช่ sheet — sheet ย่อหน้าข้างใต้ระหว่างเปิด ตู้ widget ในห้องแต่งวัดความกว้างใหม่ทุกเฟรม
        // แล้ววนไม่จบ (แอปค้าง 24 ก.ย. 2569: กด Lab ตอนตู้ widget เปิดอยู่)
        .fullScreenCover(isPresented: $showLab, onDismiss: refreshAfterLab) {
            FlowLab(stage: flow.stageIndex(screen: screen, dialog: dialog), campaign: campaign, onGo: labGo, toast: toast)
                .environment(flow)
                .environment(photos)
        }
    }

    private var publishedTheme: CardTheme? {
        CardLibrary.shared.displayOrder.first.flatMap { CardStore.restore($0.snapshot)?.theme }
    }

    // MARK: หน้าของ flow ใหม่

    @ViewBuilder
    private func flowView(_ s: FlowScreen) -> some View {
        switch s {
        case .wizard(let kind):
            StarWizard(kind: kind, campaign: campaign, steps: wiz.steps,
                       onFinish: { madeCard in finishWizard(kind, madeCard: madeCard) },
                       onExit: { d, t in
                           // ครบทุกข้อแล้ว = ไม่มีอะไรค้าง ออกได้เลย ไม่ต้องถาม
                           if t > 0 && d >= t { leaveWizard(); return }
                           wizExitInfo = (d, t); withAnimation(Motion.snap) { dialog = .wizExit }
                       },
                       onKyc: { done in withAnimation(Motion.page) { kyc = done } },
                       toast: toast)
        case .reveal:
            StarPage(mode: .reveal, campaign: campaign,
                     onClose: { close() },
                     onNext: { flow.revealSeen = true; open(.register) },
                     onFill: { steps in startWizard(.one, steps, back: .reveal) },
                     onKyc: { openKyc(back: .reveal) },
                     onShare: { toast("แชร์การ์ด — จำลอง") })
        case .register:
            RegisterFormPage(campaign: campaign, onClose: { close() }, onSubmit: submitRegister)
        case .accept:
            AcceptPage(campaign: campaign, onBack: { close() },
                       onAccept: { withAnimation(Motion.snap) { dialog = .acceptConfirm } },
                       onDecline: { withAnimation(Motion.snap) { dialog = .declineConfirm } })
        case .link:
            LinkPage(campaign: campaign, onClose: { close() }, onSubmit: submitLinks)
        case .starProfile:
            StarPage(mode: .profile, campaign: campaign,
                     onClose: { close() },
                     onFill: { steps in startWizard(.one, steps, back: .starProfile) },
                     onKyc: { openKyc(back: .starProfile) },
                     onShare: { toast("แชร์การ์ด — จำลอง") },
                     onOpenStarCard: openStarCard,
                     hosted: true)
        case .kyc:
            EmptyView()
        }
    }

    private func leaveWizard() {
        if wiz.kind == .one { open(wiz.back) } else { close() }
    }

    @ViewBuilder
    private func dialogView(_ d: FlowDialog) -> some View {
        switch d {
        case .registerSuccess:
            RegisterSuccessDialog(onClose: { withAnimation(Motion.snap) { dialog = nil } },
                                  onKyc: {
                                      withAnimation(Motion.snap) { dialog = nil }
                                      openKyc(back: nil)
                                  })
                .environment(flow)
        case .wizExit:
            let left = wizExitInfo.total - wizExitInfo.done
            // ปุ่มที่พากลับเข้ามา wizard ชุดนี้ (ตอบรับ / สมัคร)
            let again = wiz.kind == .accept ? "ตอบรับ" : "สมัคร"
            FlowModal(title: wizExitInfo.total > 0 && left <= 2 ? "เหลืออีก \(left) ข้อ จะออกเลยเหรอ" : "เก็บไว้ทำต่อทีหลังไหม",
                      detail: (wizExitInfo.done > 0 ? "ทำไปแล้ว \(wizExitInfo.done)/\(wizExitInfo.total) · " : "") + "ข้อมูลที่กรอกไว้ยังอยู่\nกลับมากด\(again)อีกครั้งจะได้ทำต่อจากตรงนี้",
                      buttons: [("เก็บไว้แล้วออก", false, {
                          withAnimation(Motion.snap) { dialog = nil }
                          leaveWizard()
                          toast("เก็บไว้ให้แล้ว · กลับมาทำต่อได้ทุกเมื่อ")
                      }), ("ทำต่อเลย", true, { withAnimation(Motion.snap) { dialog = nil } })])
        case .acceptConfirm:
            FlowModal(title: "ยืนยันตอบรับกิจกรรม", detail: "เมื่อตอบรับแล้ว ต้องส่งดราฟต์และโพสต์รีวิวตามกำหนดของกิจกรรม",
                      buttons: [("ตอบรับกิจกรรม", true, {
                          withAnimation(Motion.snap) { dialog = nil }
                          flow.phase = .acceptedQuota; flow.order = .shipping
                          close()
                          toast("ตอบรับแล้ว · รอรับของจากแบรนด์")
                      }), ("ยกเลิก", false, { withAnimation(Motion.snap) { dialog = nil } })])
        case .declineConfirm:
            FlowModal(title: "สละสิทธิ์กิจกรรมนี้?", detail: "สิทธิ์จะถูกส่งต่อให้ผู้รับรางวัลสำรอง",
                      buttons: [("สละสิทธิ์", true, {
                          withAnimation(Motion.snap) { dialog = nil }
                          close()
                          toast("สละสิทธิ์แล้ว — จำลอง")
                      }), ("ยกเลิก", false, { withAnimation(Motion.snap) { dialog = nil } })])
        }
    }

    // MARK: จุด hook (= `Ac.tapRegister` / `tapMain` / `submitRegister` / `wizFinish*`)

    /// ปุ่ม "โปรไฟล์ครีเอเตอร์" — ไปหน้า Star Profile ก่อนเสมอ (ผู้ใช้ 24 ก.ย.: "กดมาต้องไปหน้าแรกก่อน")
    /// ปุ่ม "สมัครเป็น STAR" บนหน้านั้นค่อยพาเข้า wizard กรอกครบทุกข้อในรอบเดียว
    private func openCreatorProfile() { open(.starProfile) }

    private func open(_ s: FlowScreen?) {
        withAnimation(Motion.page) { screen = s }
    }
    private func close() { open(nil) }

    private func tapMain() {
        switch flow.phase {
        case .register:
            let steps = flow.registerSteps
            if steps.isEmpty { open(.register) } else { startWizard(.apply, [.intro] + steps, back: nil) }
        case .waitingAcceptQuota:
            let steps = flow.acceptSteps
            if steps.isEmpty { open(.accept) } else { startWizard(.accept, steps, back: nil) }
        case .acceptedQuota:
            // ดราฟต์ผ่านแล้ว = ปุ่ม "ส่งลิงก์รีวิว" → หน้าส่งลิงก์เดิมเลย ไม่แทรกถามอะไร
            // (บัญชีรับเงิน: ฟอร์มรับเงินของแอปหลักเก็บเองอยู่แล้ว — ผู้ใช้ 1 ต.ค. 2569)
            guard flow.draftApproved, !flow.reviewed else {
                toast("หน้ารายละเอียดการรีวิว = หน้าเดิมของแอปหลัก (ไม่ได้จำลอง)")
                return
            }
            open(.link)
        case .registered:
            break
        }
    }

    /// เข้า Star Card — ยังไม่มีการ์ด = ถามก่อน 3 ข้อ (Creator/Page · สายที่ใช่ · แนะนำตัวและผลงาน) แล้วพาไปหน้าเลือกเทมเพลต
    /// ข้ออื่นยังไม่ถาม — widget ที่ต้องใช้จะล็อก "กรอกข้อมูลเพื่อปลดล็อก" (ผู้ใช้ 29 ก.ย. 2569)
    private func openStarCard(_ intent: StarCardIntent) {
        if flow.hasCard {
            // ยังไม่เคยสร้างการ์ด (คลังว่าง) = พาไปหน้าเลือกเทมเพลตให้เลือกแบบเอง (ผู้ใช้ 1 ต.ค. 2569)
            // เดิมสร้างใบตั้งต้นให้แล้วเปิดห้องแต่งเลย — ใบตั้งต้นเหลือเป็นแค่ภาพตัวอย่างบน Star Profile
            let target: StarCardIntent = CardLibrary.shared.records.isEmpty ? .create : intent
            withAnimation(Motion.page) { creatorIntent = target }
            return
        }
        startWizard(.one, flow.cardSteps, back: .starProfile)
        cardAfterWizard = intent
    }

    private func startWizard(_ kind: WizKind, _ steps: [WizStep], back: FlowScreen?) {
        wiz = (kind, steps, back)
        wizToken += 1
        cardAfterWizard = nil
        open(.wizard(kind))
    }

    private func finishWizard(_ kind: WizKind, madeCard: Bool) {
        switch kind {
        case .apply:
            if madeCard { open(.reveal) } else { open(.register); toast("ข้อมูลเติมให้แล้ว · ต่อที่ฟอร์มสมัคร") }
        case .accept:
            open(.accept)
            toast("ที่อยู่เติมให้แล้ว · ต่อที่หน้าตอบรับ")
        case .one:
            if let intent = cardAfterWizard {
                cardAfterWizard = nil
                open(.starProfile)
                if flow.hasCard { openStarCard(intent) }
                return
            }
            // ครบแล้วไม่ต้อง toast — แถวข้อมูลบน Star Profile ฉลองเอง (toast เดิมทับแถวพอดีและพูดซ้ำ)
            if !(flow.hasCard && flow.pct >= 1) { toast(flow.hasCard ? "บันทึกข้อมูลแล้ว" : "บันทึกแล้ว") }
            // ไม่มีที่ให้กลับ (เข้ามาจากปุ่มโปรไฟล์ครีเอเตอร์ครั้งแรก) = จบแล้วไป Star Profile
            open(wiz.back ?? .starProfile)
        }
    }

    private func submitRegister() {
        flow.phase = .registered
        close()
        withAnimation(Motion.snap.delay(0.35)) { dialog = .registerSuccess }
    }

    /// ส่งลิงก์รีวิว = จบงาน — แอปหลักกลับหน้ากิจกรรมแล้วขึ้น toast "ส่งรีวิวสำเร็จ" (ไม่มี dialog)
    private func submitLinks() {
        flow.reviewed = true
        close()
        toast("ส่งรีวิวสำเร็จ")
    }

    /// ยืนยันตัวตนจากหน้าการ์ด/Star Profile/dialog — กลับมาหน้าเดิมพร้อม toast
    private func openKyc(back: FlowScreen?) {
        withAnimation(Motion.page) {
            kyc = {
                toast(flow.isVerified ? "ป้าย Verified ขึ้นการ์ดแล้ว" : "ส่งคำขอยืนยันตัวตนแล้ว · รอทีมตรวจ")
            }
        }
    }

    /// ปิดแผง lab แล้ว wizard ที่เปิดค้างอยู่ต้องเห็นข้อมูลชุดใหม่ — ขั้นที่ติ๊กแล้วหายไป ครบแล้วก็ปิด wizard ไปเลย
    private func refreshAfterLab() {
        defer { labNavigated = false }
        guard !labNavigated, case .wizard(let kind) = screen else { return }
        let fresh: [WizStep]
        switch kind {
        case .apply: fresh = flow.registerSteps.isEmpty ? [] : [.intro] + flow.registerSteps
        case .accept: fresh = flow.acceptSteps
        case .one: fresh = wiz.steps.filter { $0 == .kyc ? flow.verify == .none : !($0.dataKey.map(flow.has) ?? true) }
        }
        guard fresh != wiz.steps else { return }
        if fresh.isEmpty {
            switch kind {
            case .apply: open(.register); toast("ข้อมูลครบแล้ว · ต่อที่ฟอร์มสมัคร")
            case .accept: open(.accept); toast("ข้อมูลครบแล้ว · ต่อที่หน้าตอบรับ")
            case .one: open(wiz.back)
            }
        } else {
            startWizard(kind, fresh, back: wiz.back)
        }
    }

    private func labGo(_ s: FlowScreen?, _ d: FlowDialog?) {
        labNavigated = true
        if openCampaign == nil { withAnimation(Motion.page) { openCampaign = campaigns[0] } }
        // ตั้งข้อมูล/ฉากเฉย ๆ (ไม่มีหน้าให้เปิด) จากในห้องแต่ง/คลัง → อยู่ที่เดิม ไม่เด้งออก
        if s == nil, d == nil, creatorIntent != nil { return }
        // กระโดดขั้นตอนที่ชั้น Star Card เปิดอยู่ — ปิดชั้นก่อน ไม่งั้นหน้าที่สั่งเปิดอยู่ใต้คลัง
        if creatorIntent != nil { creatorIntent = nil }
        if case .wizard(let kind) = s {
            // ขั้นที่ยังขาดของ wizard ชุดนั้น + หน้าเดิมที่มันพาไปเมื่อไม่มีอะไรต้องถาม
            let steps: [WizStep], after: FlowScreen
            switch kind {
            case .apply, .one: steps = flow.registerSteps.isEmpty ? [] : [.intro] + flow.registerSteps; after = .register
            case .accept: steps = flow.acceptSteps; after = .accept
            }
            if steps.isEmpty { open(after) } else { startWizard(kind, steps, back: nil) }
        } else {
            open(s)
        }
        withAnimation(Motion.snap) { dialog = d }
    }

    private func toast(_ t: String) {
        toastToken += 1
        let token = toastToken
        withAnimation(Motion.snap) { toastText = t }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if toastToken == token { withAnimation(Motion.snap) { toastText = nil } }
        }
    }
}
