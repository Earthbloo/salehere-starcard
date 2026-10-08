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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var flow = StarFlow.shared
    /// พื้นที่ Star Card เปิดทับอยู่ — nil = ปิด · ค่า = เปิดที่ไหน (คลัง / ห้องแต่งใบนั้น / เทมเพลต / มุมมองแบรนด์)
    @State private var creatorIntent: StarCardIntent?
    /// กดดูการ์ดตอนยังไม่มี → ถามก่อน แล้วเปิดการ์ดด้วย intent นี้ตอน wizard จบ
    @State private var cardAfterWizard: StarCardIntent?
    /// เทมเพลตที่แตะจากแถบตัวอย่างบน Star Profile — เปิดการ์ดครั้งแรกให้เริ่มจากใบนี้เลย ไม่ต้องผ่านหน้าเลือกแบบ
    @State private var pendingTemplate: CardTemplate?
    /// ธีมของใบที่คลังโฟกัสอยู่ — สีดวงไฟของ `StarGround` ในสถานะการ์ด
    @State private var lampTheme: CardTheme?
    /// คลังการ์ดเป็นหน้าที่เห็นอยู่ (ไม่ใช่เทมเพลต/ห้องแต่ง) — หัวร่วมโผล่เฉพาะตอนนี้
    @State private var galleryVisible = false
    /// หน้า ST★R Insight (สถิติคนดูการ์ด) เปิดทับ Star Profile
    @State private var insightOpen = false
    /// แถบสถานะตัวขาวระหว่างที่หน้า Insight (พื้นดำ) บังเต็มจอ — เปิดหลังหน้าเลื่อนเข้ามาสุดแล้ว และปิดก่อนเลื่อนออก
    /// หน้าข้างใต้จึงไม่ถูกเห็นตอนโทนเปลี่ยน
    @State private var insightChrome = false
    /// หน้าตารางงาน เปิดทับ Star Profile (พื้นสว่าง ไม่ต้องสลับโทนแถบสถานะ)
    @State private var scheduleOpen = false
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
    /// ข้อที่ wizard เปิดมา — 0 เสมอ ยกเว้นทางลัดแคปจอ `-shot wiz:…`
    @State private var wizStart = 0
    /// ยืนยันตัวตนเปิดทับทุกอย่าง · completion = กลับมาที่หน้าเดิม
    @State private var kyc: (() -> Void)?
    /// เปิดหน้ายืนยันตัวตนครั้งใหม่ = state ใหม่ทุกครั้ง (ไม่งั้น @State ของรอบก่อนค้าง เช่น ฟอร์มที่เติมค่าแล้ว)
    @State private var kycToken = 0
    /// Lab ผลยืนยันตัวตน (= `StarKycLab.ask` ของ salehere-ios): กดเริ่ม/ส่งใหม่ → ถามก่อนว่าจะจำลองผลไหน · ค่า = งานที่ต้องทำต่อเมื่อได้ผล
    @State private var kycAsk: (() -> Void)?
    /// ผลจาก Lab ไม่ใช่ผลจาก staff — ไม่เด้ง push จำลอง
    @State private var labPicking = false
    @State private var dialog: FlowDialog?
    @State private var wizExitInfo = (done: 0, total: 0)
    @State private var toastText: String?
    @State private var toastToken = 0
    /// หน้าสถานะยืนยันตัวตน (รอตรวจ/ตีกลับ) — เปิดจากปุ่มบนหน้ากิจกรรมและจากแจ้งเตือนตีกลับ
    @State private var kycStatus = false
    /// แจ้งเตือนจำลอง (push ผลยืนยันตัวตน) — แถบบนจอ หายเองใน 6 วิ
    @State private var push: (title: String, body: String, action: () -> Void)?
    @State private var pushToken = 0
    @State private var queuedPush: (title: String, body: String, action: () -> Void)?
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
                        StarHomePage(campaigns: campaigns, onOpen: { c in
                            Haptics.impact(.light)
                            withAnimation(Motion.page) { openCampaign = c }
                        }, onBanner: bannerTap)
                    case .profile:
                        SaleHereProfilePage(onCreatorProfile: openCreatorProfile,
                                            campaignCount: 15,
                                            onLab: { showLab = true },
                                            onBanner: bannerTap)
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
                    StarHeader(isCard: isCard, isStar: flow.isStar, showsDot: !CardLibrary.shared.records.isEmpty, showsToggle: false) { toCard in
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

            if insightOpen {
                // เหนือหัวร่วม "Star Profile" (3.5) และปุ่มกลับ (3.6) — หน้านี้มีหัว ST★R Insight ของตัวเอง
                StarInsightPage(theme: publishedTheme,
                                onClose: { closeInsight() },
                                onEditCard: {
                                    closeInsight()
                                    openStarCard(.gallery)
                                },
                                onShare: {
                                    if let r = CardLibrary.shared.displayOrder.first {
                                        ShareSheet.present(CardLibrary.shared.url(for: r, slug: invocation.slug))
                                    }
                                })
                    .transition(.move(edge: .trailing))
                    .zIndex(3.7)
            }

            if scheduleOpen {
                StarSchedulePage(onClose: { withAnimation(Motion.page) { scheduleOpen = false } })
                    .transition(.move(edge: .trailing))
                    .zIndex(3.7)
            }

            if kycStatus {
                KycStatusPage(campaign: campaign,
                              onClose: { withAnimation(Motion.page) { kycStatus = false } },
                              // ส่งใหม่ = ถาม Lab ก่อน · ได้ผลจาก Lab หน้านี้อยู่ต่อแล้วโหลดสถานะใหม่ (ผ่าน = ปิดเอง) · ถ่ายจริง = หน้ากล้องเปิดทับ
                              onResubmit: { openKyc(back: nil) },
                              onCancel: { flow.verify = .none; flow.kycSentAt = nil; withAnimation(Motion.page) { kycStatus = false }; toast("ยกเลิกการส่งข้อมูลแล้ว") })
                    .transition(.move(edge: .trailing))
                    .zIndex(3.75)
            }

            if let done = kyc {
                KycMockPage(deadline: flow.phase == .register ? campaign.deadline : nil,
                            episode: flow.phase == .register ? campaign.episode : nil,
                            onClose: { withAnimation(Motion.page) { kyc = nil } },
                            onDone: { withAnimation(Motion.page) { kyc = nil }; done() })
                    .id(kycToken)
                    .transition(.move(edge: .bottom))
                    // เหนือหัวร่วม "Star Profile" (3.5) — ไม่งั้นหัวทับหน้ายืนยันตัวตน
                    .zIndex(3.8)
            }

            if let dialog { dialogView(dialog).zIndex(4) }

            // ได้เป็น STAR = ฉลองทั้งจอ เหนือหัวร่วม (`StarLevelUp.swift`)
            if LevelUp.shared.playing {
                LevelUpOverlay().zIndex(4.5)
            }

            if let toastText {
                VStack { Spacer(); FlowToast(text: toastText) }
                    .zIndex(5)
                    .allowsHitTesting(false)
            }

            // แจ้งเตือนจำลองผลยืนยันตัวตน — เหนือทุกอย่าง แตะแล้วพาไปต่อ (ผ่าน = ฟอร์มสมัครใบที่ค้าง · ตีกลับ = หน้าสถานะ)
            if let push {
                VStack {
                    PushBanner(title: push.title, text: push.body, warn: push.title.contains("ไม่ผ่าน")) { dismissPush(); push.action() }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, 4)
                .zIndex(6)
            }
        }
        .onChange(of: showLab) { _, on in
            guard !on, let q = queuedPush else { return }
            queuedPush = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { pushNote(q.title, q.body, action: q.action) }
        }
        // = push `userVerifyApprove` / `userVerifyReject` ของแอปหลัก (ส่งตอน staff กดผล) · lab สลับสถานะ = ผลมาถึง
        .onChange(of: flow.verify) { old, new in
            guard !labPicking, old == .waiting || new == .rejected else { return }
            if new == .approved {
                let ep = flow.pendingCampaign.flatMap { id in campaigns.first { $0.id == id } }
                let tail = ep.map { c in c.deadline.map { " · ปิดรับ \(KycDates.day($0))" } ?? "" } ?? ""
                pushNote("ยืนยันตัวตนผ่านแล้ว ✓", ep.map { "กลับมาสมัคร \($0.episode) ต่อได้เลย\(tail)" } ?? "ป้าย Verified ขึ้นการ์ดของคุณแล้ว") {
                    withAnimation(Motion.page) { kycStatus = false; dialog = nil }
                    guard let c = ep, c.isOpen else { open(.starProfile); return }
                    tab = .home; openCampaign = c
                    // ขั้นที่ยังขาดก่อนฟอร์มกรอกครบแล้ว (KYC เป็นด่านสุดท้าย) = เปิดฟอร์มสมัครให้เลย
                    let steps = flow.registerSteps
                    if steps.isEmpty { open(.register) } else { startWizard(.apply, steps, back: nil) }
                }
            } else if new == .rejected {
                pushNote("ยืนยันตัวตนไม่ผ่าน", flow.verifyReason.isEmpty ? "กรุณาทำรายการใหม่อีกครั้ง" : flow.verifyReason) {
                    withAnimation(Motion.page) { kycStatus = true }
                }
            }
        }
        .background(SH.page.ignoresSafeArea())
        .preferredColorScheme(insightChrome ? .dark : .light)
        .environment(flow)
        // ตู้ widget ขอไปดูงานที่เปิดรับ → กลับแท็บหน้าแรก (รายการกิจกรรม STAR)
        // กลับไปไม่เป็น STAR (เช่นเลือก "ผู้ใช้ใหม่" ใน lab) = ล้างว่าฉลองแล้ว ได้เป็นใหม่ก็ฉลองใหม่
        .onChange(of: flow.starMissing.isEmpty) { _, on in if !on { LevelUp.shared.sync(isStar: false, reduceMotion: reduceMotion) } }
        // ทางลัดไว้แคปจอ/ทดสอบ: `-openInsight YES` = เปิดแอปมาที่หน้า ST★R Insight เลย (เหมือนแตะแจ้งเตือนเข้ามา)
        .onAppear {
            guard UserDefaults.standard.bool(forKey: "openInsight"), !insightOpen else { return }
            screen = .starProfile; insightOpen = true; insightChrome = true
        }
        // ทางลัดไว้แคปจอ presentation (`-shot <ที่>`): campaign · profileTab · starProfile · reveal · register · kycStatus ·
        // wiz:<apply|one>:<ข้อที่>:<ขั้น,ขั้น,…> (เช่น wiz:one:6:kind,socials,categories,media,province,availability,contact,kyc)
        .onAppear { openShot(UserDefaults.standard.string(forKey: "shot") ?? "") }
        // ทางลัดไว้แคปจอ: `-openSchedule YES` = เปิดแอปมาที่หน้าตารางงานเลย · `-openSchedule profile` = แค่หน้า Star Profile (ดูแถวทางเข้า)
        .onAppear {
            if UserDefaults.standard.string(forKey: "openSchedule") == "profile" { screen = .starProfile; return }
            guard UserDefaults.standard.bool(forKey: "openSchedule"), !scheduleOpen else { return }
            screen = .starProfile; scheduleOpen = true
        }
        .onChange(of: flow.jobsRequested) { _, on in
            guard on else { return }
            flow.jobsRequested = false
            withAnimation(Motion.page) { screen = nil; openCampaign = nil; tab = .home }
            toast("รับงานแรกให้จบ แล้วใบแบรนด์/ผลงานยืนยันจะเปิดเอง")
        }
        // fullScreenCover ไม่ใช่ sheet — sheet ย่อหน้าข้างใต้ระหว่างเปิด ตู้ widget ในห้องแต่งวัดความกว้างใหม่ทุกเฟรม
        // แล้ววนไม่จบ (แอปค้าง 24 ก.ย. 2569: กด Lab ตอนตู้ widget เปิดอยู่)
        .confirmationDialog("Lab · ผลยืนยันตัวตน", isPresented: Binding(get: { kycAsk != nil }, set: { if !$0 { kycAsk = nil } }),
                            titleVisibility: .visible) {
            Button("ยังไม่เคยส่งยืนยันตัวตน") { labKyc(.none) }
            Button("รอตรวจ (Waiting)") { labKyc(.waiting) }
            Button("ไม่ผ่าน (Reject)") { labKyc(.rejected) }
            Button("ผ่าน (Approve)") { labKyc(.approved) }
            Button("ถ่ายบัตรจริง (flow เดิม)") {
                let done = kycAsk
                kycAsk = nil
                kycToken += 1
                withAnimation(Motion.page) { kyc = done }
            }
            Button("ยกเลิก", role: .cancel) { kycAsk = nil }
        } message: {
            Text("ตอนนี้ใช้ Lab: \(flow.verify.label)\nเลือกผลที่จะจำลอง (เครื่องนี้เท่านั้น)")
        }
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
                           // ครบทุกข้อแล้ว / หน้า intro / หน้า "ข้อมูลครบแล้ว" (t = 0) = ไม่มีอะไรค้าง ออกได้เลย ไม่ต้องถาม
                           if t == 0 || d >= t { leaveWizard(); return }
                           wizExitInfo = (d, t); withAnimation(Motion.snap) { dialog = .wizExit }
                       },
                       onKyc: { done in kycAsk = done },
                       onStar: celebrateStar,
                       toast: toast, start: wizStart)
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
                     // ชิป "รอตรวจ/ไม่ผ่าน" ข้างชื่อ = ไปหน้าสถานะ (ขั้น KYC ใน wizard) ไม่เปิดกล้องซ้ำ · ยังไม่ทำ = เริ่มยืนยันตัวตนเลย
                     onKyc: { flow.verify == .waiting || flow.verify == .rejected ? startWizard(.one, [.kyc], back: .starProfile) : openKyc(back: .starProfile) },
                     onShare: { toast("แชร์การ์ด — จำลอง") },
                     onOpenStarCard: openStarCard,
                     onInsight: { openInsight() },
                     onPickTemplate: { t in pendingTemplate = t; openStarCard(.create) },
                     onSchedule: { withAnimation(Motion.page) { scheduleOpen = true } },
                     hosted: true)
        case .kyc:
            EmptyView()
        }
    }

    private func openShot(_ spec: String) {
        let p = spec.split(separator: ":").map(String.init)
        switch p.first {
        case "campaign": openCampaign = campaigns[0]
        case "profileTab": tab = .profile
        case "starProfile": tab = .profile; screen = .starProfile
        case "reveal": openCampaign = campaigns[0]; screen = .reveal
        case "register": openCampaign = campaigns[0]; screen = .register
        case "kycStatus": openCampaign = campaigns[0]; kycStatus = true
        case "registered": openCampaign = campaigns[0]; dialog = .registerSuccess
        case "levelup":
            tab = .profile; screen = .starProfile
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { LevelUp.shared.sync(isStar: true, reduceMotion: false, after: 0, covered: true) }
        case "wiz" where p.count == 4:
            let kind = WizKind(rawValue: p[1]) ?? .one
            let steps = p[3].split(separator: ",").compactMap { WizStep(rawValue: String($0)) }
            if kind == .apply { openCampaign = campaigns[0] } else { tab = .profile }
            wiz = (kind, steps, kind == .one ? .starProfile : nil)
            wizStart = Int(p[2]) ?? 0
            screen = .wizard(kind)
        default: break
        }
    }

    private func leaveWizard() {
        pendingTemplate = nil
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
            // = `STAR_WZ_EXIT_*` ของ salehere-ios ตรงตัว ("ทำไปแล้ว 0/N" ก็โชว์)
            FlowModal(title: left <= 2 ? "เหลืออีก \(left) ข้อ จะออกเลยเหรอ" : "เก็บไว้ทำต่อทีหลังไหม",
                      detail: "ทำไปแล้ว \(wizExitInfo.done)/\(wizExitInfo.total) · ข้อมูลที่กรอกไว้ยังอยู่\nกลับมากดสมัครอีกครั้งจะได้ทำต่อจากตรงนี้",
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

    private func openInsight() {
        withAnimation(Motion.page) { insightOpen = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { if insightOpen { insightChrome = true } }
    }
    private func closeInsight() {
        insightChrome = false
        withAnimation(Motion.page) { insightOpen = false }
    }
    private func close() { open(nil) }

    /// banner "สมัครเป็น STAR": รอตรวจ/ไม่ผ่าน = หน้าสถานะยืนยันตัวตน · ปกติ = ถามเฉพาะข้อที่ขาดใน 8 ข้อ แล้วจบที่ Star Profile (= `bannerTap` ของ desktop)
    /// banner: เหลือแค่ยืนยันตัวตนข้อเดียว + รอตรวจ/ไม่ผ่าน = หน้าสถานะ · อื่น ๆ (รวมสถานะ C) = ถามเฉพาะข้อที่ขาดใน 8 ข้อ แล้วจบที่ Star Profile (salehere-ios)
    private func bannerTap() {
        if kycOnlyBlocked { withAnimation(Motion.page) { kycStatus = true }; return }
        startWizard(.one, flow.starMissing, back: .starProfile)
    }

    /// เหลือแค่ยืนยันตัวตน และรอตรวจ/ไม่ผ่าน — ไปหน้าสถานะได้ (ยังขาดข้ออื่น = ห้ามพาไปหน้าสถานะ)
    private var kycOnlyBlocked: Bool { flow.starMissing == [.kyc] && (flow.verify == .waiting || flow.verify == .rejected) }

    private func tapMain() {
        switch flow.phase {
        case .register:
            // จำงานที่กำลังสมัครไว้ — ติดด่านยืนยันตัวตนแล้วผ่านทีหลัง push จะพากลับมาฟอร์มใบนี้
            flow.pendingCampaign = campaign.id
            // ด่าน (salehere-ios ข้อ 5): ครบ 8 ข้อ → ฟอร์มเดิม · เหลือแค่ยืนยันตัวตน + รอตรวจ/ไม่ผ่าน → หน้าสถานะ ·
            // ยังขาดข้ออื่น (ทั้งยังไม่เป็น STAR และ STAR เก่าที่ยังไม่ครบ — บังคับเหมือนกัน) → intro + wizard
            let steps = flow.registerSteps
            if steps.isEmpty { open(.register) }
            else if kycOnlyBlocked { withAnimation(Motion.page) { kycStatus = true } }
            else { startWizard(.apply, [.intro] + steps, back: nil) }
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

    /// เข้า Star Card — ยังไม่เป็น STAR = บังคับกรอก 8 ข้อที่แบรนด์ใช้คัดเลือกก่อนเสมอ (ผู้ใช้ 6 ต.ค. 2569: "force ให้กรอก 8 ข้อก่อนตลอด")
    /// แล้วค่อยพาไปหน้าเลือกเทมเพลต (เดิม 29 ก.ย. ถามแค่ 3 ข้อให้การ์ดเกิด)
    private func openStarCard(_ intent: StarCardIntent) {
        if flow.isStar, let t = pendingTemplate {
            // แตะเทมเพลตจากแถบตัวอย่าง = สร้างใบแรกจากแบบนั้น แล้วเข้าห้องแต่งเลย (motion "ST★R Card" เล่นครั้งแรกเหมือนเดิม)
            pendingTemplate = nil
            let record = CardLibrary.shared.create(from: t)
            if !LevelUp.shared.cardRevealSeen { LevelUp.shared.revealCard(reduceMotion: reduceMotion, toTitle: false) }
            withAnimation(Motion.page) { creatorIntent = .edit(record.id) }
            return
        }
        if flow.isStar {
            // ยังไม่เคยเลือกการ์ด (คลังว่าง) = motion "ST★R Card" ก่อน แล้วพาไปหน้าเลือกเทมเพลตเลือกใบแรก
            // ไม่สร้างใบตั้งต้นให้เอง (ผู้ใช้ 2 ต.ค. 2569: "ถ้า User ไม่เคยเลือก Card มาก่อน Animate และต้องพาไป Template
            // เพื่อเลือกอันแรก") · มีการ์ดแล้วแต่ยังไม่เคยเห็น motion = motion แล้วตราบินขึ้นหัวหน้า Star Card
            let empty = CardLibrary.shared.records.isEmpty
            var target: StarCardIntent = empty ? .create : intent
            if !LevelUp.shared.cardRevealSeen {
                if !empty { target = .gallery }   // หัว ST★R Card อยู่หน้าคลัง — ตราต้องมีที่ให้ลง
                LevelUp.shared.revealCard(reduceMotion: reduceMotion, toTitle: !empty)
            }
            withAnimation(Motion.page) { creatorIntent = target }
            return
        }
        startWizard(.one, flow.starMissing, back: .starProfile)
        cardAfterWizard = intent
    }

    private func startWizard(_ kind: WizKind, _ steps: [WizStep], back: FlowScreen?) {
        wiz = (kind, steps, back)
        wizStart = 0
        wizToken += 1
        cardAfterWizard = nil
        open(.wizard(kind))
    }

    private func finishWizard(_ kind: WizKind, madeCard: Bool) {
        celebrateStar()
        switch kind {
        case .apply:
            // ตรวจซ้ำหลังจบ wizard: เพิ่งเป็น STAR = หน้า "คุณเป็น STAR แล้ว" · ครบ = ฟอร์มสมัคร · ยังไม่ครบ = หน้า Star Profile ให้เห็นว่าขาดอะไร
            if madeCard { open(.reveal) } else if flow.registerSteps.isEmpty { open(.register) } else { open(.starProfile) }
        case .accept:
            open(.accept)
            toast("ที่อยู่เติมให้แล้ว · ต่อที่หน้าตอบรับ")
        case .one:
            if let intent = cardAfterWizard {
                cardAfterWizard = nil
                open(.starProfile)
                if flow.isStar { openStarCard(intent) }
                return
            }
            // ไม่มี toast ตอนจบ (salehere-ios) — หน้า Star Profile อัปเดตแถวให้เห็นเอง
            // ไม่มีที่ให้กลับ (เข้ามาจากปุ่มโปรไฟล์ครีเอเตอร์ครั้งแรก) = จบแล้วไป Star Profile
            open(wiz.back ?? .starProfile)
        }
    }

    /// จังหวะได้เป็น STAR — เล่นเฉพาะตอนกรอกเสร็จเท่านั้น (จบ wizard / จบยืนยันตัวตน) ปิดจอทึบตั้งแต่เฟรมแรก
    /// แล้วหน้าถัดไปค่อยโผล่หลัง motion · ไม่เล่นตามหน้าอื่นทีหลัง (ผู้ใช้ 2 ต.ค. 2569: เล่นซ้ำบนฟอร์มสมัคร "งง ·
    /// ไม่มีแล้ว มีแค่หน้าตอนกรอกเสร็จแค่นั้น") — เรียกก่อนเปลี่ยนหน้าในรอบเดียวกัน หน้าใหม่จึงไม่โผล่ให้เห็นก่อน
    private func celebrateStar() {
        // ฉลองเมื่อครบ 8 ข้อจริง ไม่ใช่แค่มียศ — STAR เก่าที่ยังไม่ครบไม่เล่น ได้เล่นตอนกรอกครบ (salehere-ios)
        LevelUp.shared.sync(isStar: flow.starMissing.isEmpty, reduceMotion: reduceMotion, after: 0, covered: true)
    }

    private func submitRegister() {
        // ที่อยู่กรอกในฟอร์มสมัครเดิมแล้ว (ผู้ใช้ 6 ต.ค. 2569) — นับเป็นข้อที่มีใน Star Profile ทันที ตอบรับไม่ถามซ้ำ
        if flow.addressInfo.full { flow.have.insert(.address) }
        flow.pendingCampaign = nil
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
        kycAsk = {
            celebrateStar()
            // dialog ผล ("ยืนยันตัวตนเสร็จสมบูรณ์" / "ส่งคำขอยืนยันตัวตนสำเร็จ") อยู่ในหน้ายืนยันตัวตนเองแล้ว (UI ของแอปหลัก)
            if flow.isVerified { toast("ป้าย Verified ขึ้นการ์ดแล้ว") }
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

    /// ผลจาก Lab — ทับสถานะในเครื่อง แล้วทำต่อเหมือนกลับจากหน้ายืนยันตัวตน
    private func labKyc(_ v: VerifyStatus) {
        let done = kycAsk
        kycAsk = nil
        labPicking = true
        flow.verify = v
        if v == .waiting { flow.kycSentAt = Date() }
        if v == .rejected, flow.verifyReason.isEmpty { flow.verifyReason = StarFlow.rejectReasons[0] }
        DispatchQueue.main.async { labPicking = false }
        done?()
    }

    private func pushNote(_ title: String, _ body: String, action: @escaping () -> Void) {
        // สลับผลจากแผง lab (fullScreenCover ทับทุกอย่าง) = เก็บไว้ก่อน ปิดแผงแล้วค่อยเด้ง เหมือน push มาถึงตอนกลับเข้าแอป
        if showLab { queuedPush = (title, body, action); return }
        pushToken += 1
        let token = pushToken
        Haptics.impact(.medium)
        withAnimation(Motion.snap) { push = (title, body, action) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if pushToken == token { withAnimation(Motion.snap) { push = nil } }
        }
    }
    private func dismissPush() { pushToken += 1; withAnimation(Motion.snap) { push = nil } }

    private func toast(_ t: String) {
        toastToken += 1
        let token = toastToken
        withAnimation(Motion.snap) { toastText = t }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if toastToken == token { withAnimation(Motion.snap) { toastText = nil } }
        }
    }
}
