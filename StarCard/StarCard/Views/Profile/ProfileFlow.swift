import SwiftUI
import PhosphorSwift

// MARK: - หน้า "ข้อมูลของฉัน" ทั้งชุด
//
// hub → แตะส่วนไหนแก้ส่วนนั้น (กลับได้ตลอด ทุกอย่างบันทึกเองแล้ว)
// hub → "เริ่มสร้างโปรไฟล์" = wizard สี่ขั้นเฉพาะส่วนจำเป็น → กลับมาดูข้อมูลที่ hub
//
// ไม่ใช้ `NavigationStack` — ทั้งแอปสลับหน้าด้วย state + transition เอง (ดู `ContentView`)
// แถบนำทางของระบบบังคับฟอนต์ระบบ และหน้าพวกนี้มีหัวจอของตัวเองอยู่แล้ว

struct ProfileFlow: View {
    let onClose: () -> Void
    /// Star Card ของฉัน — ผู้เรียกปิดหน้านี้แล้วพากลับหน้าการ์ดของฉัน (คลัง)
    let onMyCards: () -> Void

    enum Screen: Equatable {
        case hub
        case section(ProfileSection)
        case wizard
        /// รูป · ชื่อผู้ใช้ · ลิงก์ · About Me · ผลงาน — ช่องของแอป Sale Here เดิม ไม่ใช่ขั้นของฟอร์ม
        case edit
    }
    @State private var screen: Screen = .hub

    var body: some View {
        ZStack {
            ProfileStage()
            switch screen {
            case .hub:
                ProfileHub(onClose: onClose,
                           onOpen: { s in go(.section(s)) },
                           onStart: {
                               Profile.me.beginIntake()
                               go(.wizard)
                           },
                           onMyCards: onMyCards,
                           onEdit: { go(.edit) })
                    .transition(.opacity)
            case .edit:
                ProfileEditor(onClose: { go(.hub) })
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .opacity))
            case .section(let s):
                // แตะแถวใน hub = เปิด wizard ที่ขั้นนั้น — แถบขั้น · ✕ ปิด · ย้อนกลับ/ถัดไป เหมือนตอนกรอกครั้งแรกทุกอย่าง
                ProfileWizard(start: ProfileSection.required.firstIndex(of: s) ?? 0,
                              onExit: { go(.hub) }, onFinish: { go(.hub) })
                    .id(s)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .opacity))
            case .wizard:
                ProfileWizard(onExit: { go(.hub) }, onFinish: { go(.hub) })
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .opacity))
            }
        }
        .preferredColorScheme(.light)
    }

    private func go(_ s: Screen) {
        withAnimation(Motion.settle) { screen = s }
    }
}

/// เวทีของทุกหน้าในกลุ่มนี้ — สว่าง เรียบ มีแสงแดงแบรนด์จาง ๆ จากมุมบนขวาให้กระจกมีอะไรให้หักเห
/// (ของอยู่บนเวที ไม่ใช่บนกระดาษ — แต่เวทีต้องไม่แย่งซีนบัตร STAR ที่เป็นชิ้นมืดชิ้นเดียว)
struct ProfileStage: View {
    /// พื้นเรียบ #F9FAFB แบบหน้าในแอป Sale Here — ไม่มีแสงสี ไม่มีลาย
    var body: some View {
        PK.bg.ignoresSafeArea()
    }
}

// MARK: - Hub

struct ProfileHub: View {
    let onClose: () -> Void
    let onOpen: (ProfileSection) -> Void
    let onStart: () -> Void
    let onMyCards: () -> Void
    let onEdit: () -> Void

    @Environment(PhotoStore.self) private var photos
    private var p: Profile { Profile.me }
    @State private var confirmReset = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            PKHeader(title: "โปรไฟล์ STAR", leftSymbol: .caretDown, leftLabel: "ปิด", onLeft: onClose)
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 14) {
                        if p.intake == nil {
                            hero
                        } else {
                            // หน้านี้คือ "ความเป็น STAR ของฉัน" ไม่ใช่สารบัญฟอร์ม:
                            // บัตร STAR (ยศ) → สิ่งที่ต้องทำต่อข้อเดียว → ข้อมูลเป็นแถวสรุป → เครื่องมือทดสอบท้ายสุด
                            // ปุ่มหลักปุ่มเดียวอยู่แถบล่างคงที่ ไม่ลอยอยู่กลางหน้า
                            starCard
                            nextStep
                            sections
                            tools
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, p.intake == nil ? 40 : 120)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    // สลับ hero ↔ hub (ล้างข้อมูล/นำเข้า) = เนื้อหาคนละชุด ตำแหน่งเลื่อนเดิมใช้ต่อไม่ได้
                    .id(p.hasIntake)
                }
                if p.intake != nil { bottomBar }
            }
        }
        .onAppear { withAnimation(Motion.settle.delay(0.05)) { appeared = true } }
    }

    // MARK: ยังไม่เคยกรอก — หน้าต้อนรับแบบเดียวกับฟอร์มเว็บ

    private var hero: some View {
        VStack(spacing: 18) {
            // อีโมจิลอยขนาบป้าย — อยู่แถวเดียวกับป้าย ไม่ล้ำลงไปทับพาดหัว
            HStack(spacing: 6) {
                PKFloatingEmoji(emoji: "🌟", size: 28, duration: 6.5)
                Spacer(minLength: 4)
                PKStarBadge()
                Spacer(minLength: 4)
                PKFloatingEmoji(emoji: "💎", size: 24, duration: 7.5, delay: 0.8, tilt: 6)
            }
            .padding(.horizontal, 6)
            .padding(.top, 10)

            VStack(spacing: 12) {
                (Text("ร่วมเป็น ")
                    + Text("STAR").foregroundStyle(PK.redGradient)
                    + Text(" รับงานรีวิวที่ใช่สำหรับคุณ 🌟"))
                    .font(.sh(27, .black))
                    .foregroundStyle(PK.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 20)
                Text("กรอกครั้งเดียว STAR Card ทุกใบดึงไปใช้ · แก้ตรงไหนบนการ์ดก็กลับมาเปลี่ยนที่นี่ด้วย ไม่ต้องทำพอร์ตเองให้ยุ่งยาก")
                    .font(.sh(14, .medium))
                    .foregroundStyle(PK.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // จุดขาย 4 ข้อ — สติกเกอร์สองคอลัมน์ ข้อความสั้นพอไม่ตัดกลางคำ (ผล audit ของเว็บ)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                perk("🎯", "แมตช์งานที่ใช่", "จับคู่แคมเปญให้ตรงสาย", PK.peach)
                perk("💰", "ตั้งเรทเอง", "มีเรทตลาดไกด์ให้", PK.lemon)
                perk("📸", "ไม่ต้องทำพอร์ต", "ดึงผลงานจากช่องของคุณ", PK.lavender)
                perk("🧾", "เงินเข้าตรงเวลา", "ทีมงานดูแลให้จบ", PK.mint)
            }

            // ขั้นตอนทั้งหมดบอกล่วงหน้า — ตัวเลข "4 ขั้น" ต้องตรงกับตัวนับใน wizard
            PKWrap(spacing: 4) {
                ForEach(Array(ProfileSection.required.enumerated()), id: \.element) { i, s in
                    HStack(spacing: 4) {
                        Text("\(s.emoji) \(stepShort(s))")
                            .font(.sh(11.5, .bold)).foregroundStyle(PK.ink)
                            .padding(.horizontal, 9).padding(.vertical, 6)
                            .background(Capsule().fill(PK.surface))
                            .overlay(Capsule().strokeBorder(PK.line2, lineWidth: 1))
                        if i < ProfileSection.required.count - 1 {
                            Text("›").font(.sh(13, .bold)).foregroundStyle(PK.hint)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                PKPrimaryButton(title: "🚀 เริ่มสร้างโปรไฟล์ STAR!", action: onStart)
                Text("ใช้เวลาประมาณ 2 นาที · พักไว้ก่อนได้ ระบบบันทึกให้เองทุกจังหวะ")
                    .font(.sh(11.5, .medium)).foregroundStyle(PK.hint)
                Button {
                    Haptics.impact(.light)
                    withAnimation(Motion.settle) { Profile.me.importFromSystemProfile() }
                } label: {
                    Text("เคยสมัคร STAR ไว้แล้ว? นำเข้าจากโปรไฟล์ Sale Here เดิม")
                        .font(.sh(12.5, .semibold)).foregroundStyle(PK.redDark).underline()
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
                sampleFillLink
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 20)
        .glassEffect(PK.glass, in: PK.shape(28))
        .overlay(PK.shape(28).strokeBorder(PK.line, lineWidth: 1))
    }

    /// ทางลัดทดสอบ — เติมทุกช่องด้วยข้อมูลตัวอย่าง (เหลือแตะยินยอม PDPA เอง)
    private var sampleFillLink: some View {
        SampleFillLink()
    }

    /// ชื่อสั้นสำหรับชิปขั้นตอน — ชื่อเต็ม "ช่องทางและยอดผู้ติดตาม" ยาวจนแถวชิปตกบรรทัด
    private func stepShort(_ s: ProfileSection) -> String {
        switch s {
        case .channels:  return "ช่องทาง"
        case .interests: return "สายที่ใช่"
        case .payment:   return "รับเงิน"
        case .terms:     return "Vibe"
        case .person:    return "รู้จักกัน"
        case .consent:   return "ยืนยัน"
        }
    }

    private func perk(_ emoji: String, _ title: String, _ detail: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(emoji).font(.system(size: 26))
            Text(title).font(.sh(13.5, .black)).foregroundStyle(PK.ink).lineLimit(1).minimumScaleFactor(0.8)
            Text(detail).font(.sh(11, .medium)).foregroundStyle(PK.ink.opacity(0.62)).lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PK.shape(16).fill(tint))
    }

    // MARK: หัว: รูป ชื่อ สถานะ

    // MARK: แถบล่าง — ปุ่มหลักปุ่มเดียวของหน้า

    private var bottomBar: some View {
        let done = p.requiredDoneCount
        let total = ProfileSection.required.count
        return Group {
            if let s = nextMissing {
                // ไปที่ส่วนที่ขาดจริง — การ์ดบอก "ทำต่อ: ยืนยัน" แต่ปุ่มพาไปขั้น 1 = ผู้ใช้ต้องกดถัดไปอีก 5 ครั้งเอง
                PKPrimaryButton(title: "กรอกต่อ · เหลืออีก \(total - done) ส่วน", symbol: .arrowRight) {
                    onOpen(s)
                }
            } else {
                PKPrimaryButton(title: "Star Card ของฉัน", symbol: .arrowRight, action: onMyCards)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .modifier(PKBottomBar())
    }

    // MARK: บัตร STAR — ใครคือคนนี้ในสายตาแบรนด์ และอยู่ขั้นไหนของการเป็น STAR

    /// บัตรโฮโลเหลืองเป็นพื้นสว่างชิ้นเดียวในหน้ามืด — ตัวหนังสือบนมันจึงเข้มเสมอ ไม่ตาม `PK.ink`
    private var heroInk: Color { Color(red: 0.13, green: 0.12, blue: 0.11) }

    private var starCard: some View {
        let c = p.creator
        return Button {
            Haptics.impact(.light)
            onEdit()
        } label: {
            HStack(spacing: 14) {
                photos.avatar()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 2))
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(p.isPlaceholder(.name) ? "ยังไม่มีชื่อ" : p.name)
                            .font(.sh(21, .black)).foregroundStyle(heroInk)
                            .lineLimit(1).minimumScaleFactor(0.8)
                        if c.verified { StarSeal(size: 15) }
                    }
                    Text("@\(p.handle)").font(.sh(13, .medium)).foregroundStyle(heroInk.opacity(0.55)).lineLimit(1)
                }
                Spacer(minLength: 6)
                // แตะทั้งบัตรได้ — ปุ่มดินสอบอกว่ามันแก้ได้ ไม่ใช่แค่ป้ายชื่อ
                PIcon(.pencilSimple, size: 15, weight: .bold)
                    .foregroundStyle(heroInk)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white.opacity(0.45)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 1))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 24)
            .contentShape(PK.shape())
        }
        .buttonStyle(PKDimPress())
        // โฮโลพาสเทล + ดาวดวงโต (STAR) ในถาดกระจกขาว — ชิ้นเดียวในหน้าที่มีสี ทุกอย่างข้างล่างเป็นขาวนุ่ม
        .background(PKWarmMesh())
        .clipShape(PK.shape(24))
        .padding(6)
        .glassEffect(PK.glass, in: PK.shape(30))
    }

    // MARK: สิ่งที่ต้องทำต่อ — ข้อเดียว ไม่ใช่ 6 กระเบื้องให้ไล่หา

    private var nextMissing: ProfileSection? { ProfileSection.required.first { $0.status(p) != .complete } }

    @ViewBuilder
    private var nextStep: some View {
        let done = p.requiredDoneCount
        let total = ProfileSection.required.count
        if let s = nextMissing {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    PIcon(s.icon, size: 18, weight: .fill)
                        .foregroundStyle(PK.warn)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(PK.warn.opacity(0.13)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ทำต่อ: \(s.title)").font(.sh(17, .bold)).foregroundStyle(PK.ink)
                        Text(s.issues(p).first?.message ?? s.purpose)
                            .font(.sh(12.5, .medium)).foregroundStyle(PK.muted)
                            .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(18)
                Rectangle().fill(PK.line).frame(height: 1)
                HStack(spacing: 10) {
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(PK.ink.opacity(0.08))
                            Capsule().fill(PK.ink).frame(width: g.size.width * CGFloat(done) / CGFloat(max(1, total)))
                        }
                    }
                    .frame(height: 6)
                    Text("\(done)/\(total)").font(.sh(12, .bold)).foregroundStyle(PK.muted).monospacedDigit()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .background(PKSoftCard(radius: 24))
            .contentShape(PK.shape(24))
            .onTapGesture { Haptics.impact(.light); onOpen(s) }
        }
    }

    // MARK: ข้อมูล — การ์ดชิ้นละส่วน มีขอบของตัวเอง · แตะแก้ได้
    //
    // ทีละชิ้นแยกกัน ไม่ใช่ตารางยาวก้อนเดียว — แต่ละชิ้นสูงเท่ากันหมด สรุปตัดท้ายให้เหลือบรรทัดเดียวเสมอ
    // (ปล่อยให้ตกบรรทัดแล้วชิ้นสูงไม่เท่ากัน แถวเรียงลงมาแล้วดูรุงรัง)
    // ครบแล้ว = ขอบเทาบาง ติ๊กวงกลมเขียว · ยังขาด = ขอบส้ม พื้นส้มจาง ป้ายบอกว่าขาดกี่ข้อ

    private var sections: some View {
        let done = p.requiredDoneCount
        let total = ProfileSection.required.count
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("ข้อมูลของฉัน").font(.sh(19, .bold)).foregroundStyle(PK.ink)
                Spacer(minLength: 0)
                Text(done == total ? "ครบแล้ว" : "\(done)/\(total)")
                    .font(.sh(12, .bold)).monospacedDigit()
                    .foregroundStyle(done == total ? PK.ok : PK.hint)
            }
            .padding(.horizontal, 6)
            .padding(.top, 8)
            VStack(spacing: 10) {
                ForEach(ProfileSection.required, id: \.self) { s in row(s) }
            }
        }
    }

    private func row(_ s: ProfileSection) -> some View {
        let status = s.status(p)
        let issues = s.issues(p)
        let facts = s.facts(p)
        let missing = status != .complete
        let shape = PK.shape(22)
        return Button {
            Haptics.impact(.light)
            onOpen(s)
        } label: {
            HStack(spacing: 10) {
                PIcon(s.icon, size: 18, weight: missing ? .fill : .regular)
                    .foregroundStyle(missing ? PK.warn : PK.ink.opacity(0.55))
                    .frame(width: 38, height: 38)
                    .background(PKSoftIcon(tint: missing ? PK.warn : nil))
                VStack(alignment: .leading, spacing: 5) {
                    Text(s.title).font(.sh(14.5, .bold)).foregroundStyle(PK.ink).lineLimit(1)
                    if facts.isEmpty {
                        Text(issues.first?.message ?? s.purpose)
                            .font(.sh(11.5, .medium)).foregroundStyle(PK.hint)
                            .lineLimit(1).truncationMode(.tail)
                    } else {
                        PKFactStrip(facts: facts)
                    }
                }
                Spacer(minLength: 6)
                if missing {
                    PKStatusPill(text: status == .empty ? "ยังไม่กรอก" : "ขาดอีก \(max(1, issues.count))",
                                 color: PK.warn, symbol: .warningCircle)
                } else {
                    PKDoneDot(size: 20)
                }
                PIcon(.caretRight, size: 11).foregroundStyle(PK.ink.opacity(0.22))
            }
            .padding(.horizontal, 14)
            .frame(height: 70)
            .contentShape(Rectangle())
        }
        .buttonStyle(PKRowPress())
        .clipShape(shape)
        .background(PKSoftCard(radius: 22, tint: missing ? PK.warn : nil))
    }

    // MARK: เครื่องมือทดสอบ — ท้ายสุด ตัวเล็ก ไม่ปนกับของจริง

    private var tools: some View {
        VStack(spacing: 10) {
            Text("เครื่องมือทดสอบ").font(.sh(11, .bold)).foregroundStyle(PK.hint).tracking(0.4)
            HStack(spacing: 18) {
                SampleFillLink(compact: true)
                Button {
                    withAnimation(Motion.snap) { confirmReset.toggle() }
                } label: {
                    Text("ล้างข้อมูล").font(.sh(11.5, .semibold)).foregroundStyle(confirmReset ? PK.red : PK.muted)
                }
                .buttonStyle(.plain)
            }
            if confirmReset {
                HStack(spacing: 10) {
                    PKSecondaryButton(title: "ยกเลิก") { withAnimation(Motion.snap) { confirmReset = false } }
                    Button {
                        Haptics.impact(.heavy)
                        Profile.me.resetAll()
                        photos.clearProfile()
                        Portfolio.shared.resetAll()
                        withAnimation(Motion.settle) { confirmReset = false }
                    } label: {
                        Text("ลบทั้งหมด").font(.sh(14.5, .bold)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(Capsule().fill(PK.red))
                    }
                    .buttonStyle(DockPress())
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 14)
    }
}

// MARK: - หน้าแก้ทีละส่วน (จาก hub)

struct SectionScreen: View {
    let section: ProfileSection
    let onBack: () -> Void

    @State private var showIssues = false
    @State private var focusRequest: String?
    @State private var keyboardUp = false
    private var p: Profile { Profile.me }

    private var issues: [ProfileIssue] { section.issues(p) }

    var body: some View {
        VStack(spacing: 0) {
            PKHeader(title: section.title,
                     subtitle: section.isRequired ? "จำเป็นสำหรับการ์ด" : "เติมทีหลังได้ · ไม่บังคับ",
                     leftSymbol: .x, leftLabel: "ปิด", onLeft: onBack)
            ZStack(alignment: .bottom) {
                SectionBody(section: section, showIssues: showIssues, focusRequest: $focusRequest)
                bottom
                    // คีย์บอร์ดขึ้น = แถบปุ่มหลบ ไม่ทับช่องที่กำลังพิมพ์ · กด ✓ บนคีย์บอร์ดแล้วแถบกลับมา
                    .opacity(keyboardUp ? 0 : 1)
                    .offset(y: keyboardUp ? 40 : 0)
                    .allowsHitTesting(!keyboardUp)
            }
        }
        .modifier(KeyboardWatcher(visible: $keyboardUp))
    }

    private var bottom: some View {
        VStack(spacing: 10) {
            if showIssues, !issues.isEmpty {
                PKIssueBox(issues: issues) { focusRequest = $0.field }
            }
            PKPrimaryButton(title: "เสร็จ", symbol: .check) {
                if section.isRequired, let first = issues.first {
                    withAnimation(Motion.settle) { showIssues = true }
                    focusRequest = first.field
                    Haptics.rigid()
                } else {
                    onBack()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .modifier(PKBottomBar())
        .animation(Motion.settle, value: showIssues)
    }
}

// MARK: - Wizard สี่ขั้น (ครั้งแรก)

struct ProfileWizard: View {
    let onExit: () -> Void
    let onFinish: () -> Void

    private let steps = ProfileSection.required
    @State private var step: Int
    @State private var showIssues = false
    @State private var focusRequest: String?
    @State private var keyboardUp = false
    private var p: Profile { Profile.me }

    /// `start` — ขั้นที่เปิดมาถึงก่อน (0 = ครั้งแรก · จาก hub = ขั้นของแถวที่แตะ)
    init(start: Int = 0, onExit: @escaping () -> Void, onFinish: @escaping () -> Void) {
        _step = State(initialValue: min(max(0, start), ProfileSection.required.count - 1))
        self.onExit = onExit
        self.onFinish = onFinish
    }

    private var current: ProfileSection { steps[min(max(0, step), steps.count - 1)] }
    private var issues: [ProfileIssue] { current.issues(p) }

    /// ทิศของการเปลี่ยนขั้น — ไปหน้า = ไหลมาจากขวา · ย้อน = ไหลมาจากซ้าย (ขากลับเป็นภาพย้อนของขาไป)
    @State private var forward = true
    /// จำนวนข้อที่ยังขาดมากที่สุดที่เคยเห็นต่อส่วน — ตัวหารของ "กรอกไปแล้วเท่าไหร่" ในแถบสตอรี่
    @State private var peak: [ProfileSection: Int] = [:]
    /// นับครั้งที่กด "ถัดไป" ทั้งที่ยังไม่ครบ — ให้เหรียญของส่วนนี้ส่ายหัว
    @State private var nudge = 0

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ZStack(alignment: .bottom) {
                SectionBody(section: current, showIssues: showIssues, focusRequest: $focusRequest)
                    .environment(\.wizardHeading, WizardHeading(section: current))
                    .id(step)
                    .transition(slide)
                bottom
                    .opacity(keyboardUp ? 0 : 1)
                    .offset(y: keyboardUp ? 40 : 0)
                    .allowsHitTesting(!keyboardUp)
            }
        }
        .modifier(KeyboardWatcher(visible: $keyboardUp))
    }

    private var bottom: some View {
        VStack(spacing: 10) {
            if showIssues, !issues.isEmpty {
                PKIssueBox(issues: issues) { focusRequest = $0.field }
            }
            // แถวนำทางแบบเว็บ: ‹ ย้อนกลับ ซ้าย · ถัดไป → ขวา (ขั้นแรกไม่มีย้อน — ปุ่มปิดอยู่มุมบน)
            HStack(spacing: 10) {
                if step > 0 {
                    PKSecondaryButton(title: "ย้อนกลับ", symbol: .caretLeft, height: 54, action: back)
                        .frame(width: 132)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
                PKPrimaryButton(title: step == steps.count - 1 ? "เสร็จสิ้น 🎉" : "ถัดไป",
                                symbol: step == steps.count - 1 ? nil : Ph.arrowRight,
                                action: next)
            }
            .animation(Motion.settle, value: step)
            SampleFillLink(compact: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .modifier(PKBottomBar())
        .animation(Motion.settle, value: showIssues)
    }

    private func next() {
        if let first = issues.first {
            withAnimation(Motion.settle) { showIssues = true }
            focusRequest = first.field
            nudge += 1
            Haptics.rigid()
            return
        }
        if step < steps.count - 1 {
            forward = true
            withAnimation(Motion.settle) {
                showIssues = false
                step += 1
            }
        } else {
            Profile.me.updateIntake { $0.firstRunDone = true }
            onFinish()
        }
    }

    private func back() {
        // ปุ่มย้อนที่กำลังจางออกยังรับแตะได้อีกจังหวะ — กันไม่ให้ถอยหลุดขั้นแรก
        guard step > 0 else { return }
        forward = false
        withAnimation(Motion.settle) {
            showIssues = false
            step -= 1
        }
    }

    /// แตะเหรียญบนแถบ — กระโดดไปส่วนนั้นตรง ๆ หน้าไหลเข้ามาตามทิศ
    private func jump(to i: Int) {
        guard i != step, steps.indices.contains(i) else { return }
        forward = i > step
        withAnimation(Motion.settle) {
            showIssues = false
            step = i
        }
    }

    private var slide: AnyTransition {
        .asymmetric(insertion: .offset(x: forward ? 56 : -56).combined(with: .opacity),
                    removal: .offset(x: forward ? -56 : 56).combined(with: .opacity))
    }

    /// แถวบนแถวเดียว — ✕ ปิด · แถวเหรียญตรา (แตะเพื่อกระโดด)
    private var topBar: some View {
        HStack(spacing: 10) {
            PKCircleButton(symbol: .x, label: "ปิด", action: onExit)
            PKStampRow(current: step, fill: steps.map(fill),
                       icons: steps.map(\.icon), titles: steps.map(\.title),
                       nudge: nudge, onTap: jump)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .onAppear { steps.forEach(notePeak) }
        .onChange(of: p.intake) { _, _ in steps.forEach(notePeak) }
    }

    /// ส่วนนี้กรอกไปแล้วเท่าไหร่ — ครบ = 1 · ที่เหลือเทียบกับจำนวนข้อที่ขาดมากที่สุดที่เคยเห็น
    private func fill(_ s: ProfileSection) -> CGFloat {
        let left = s.issues(p).count
        if left == 0, p.intake != nil { return 1 }
        let top = max(peak[s] ?? left, left, 1)
        return CGFloat(top - left) / CGFloat(top)
    }

    private func notePeak(_ s: ProfileSection) {
        let n = s.issues(p).count
        if n > (peak[s] ?? 0) { peak[s] = n }
    }
}

/// หัวคำถามของขั้นหนึ่ง — ป้ายส่วน · คำถามตัวใหญ่ · ทำไมต้องกรอก
/// ภาษาเดียวกับ onboarding ที่ถามทีละเรื่อง: หน้าถามคำถาม ไม่ใช่หน้าตั้งชื่อฟอร์ม
struct WizardHeading: View {
    let section: ProfileSection

    /// คำถามตัวใหญ่ → ประโยครองบรรทัดเดียว · ชิดซ้ายแบบหน้านิตยสาร ไม่ใช่กลางแบบป๊อปอัป
    /// ไม่มีป้าย "02 · ชื่อส่วน" แล้ว — เหรียญตราบนแถบบอกว่าอยู่ส่วนไหน
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(section.question)
                .font(.sh(24, .bold))
                .foregroundStyle(PK.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(section.purpose)
                .font(.sh(13.5, .medium)).foregroundStyle(PK.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}

extension EnvironmentValues {
    /// หัวคำถามที่ wizard ส่งลงมาให้ `SectionScroll` วางเป็นชิ้นแรก — หน้า section เดี่ยว (จาก hub) ไม่มี
    @Entry var wizardHeading: WizardHeading? = nil
}

// MARK: - ตัวเลือกเนื้อหาตามส่วน

struct SectionBody: View {
    let section: ProfileSection
    let showIssues: Bool
    @Binding var focusRequest: String?

    var body: some View {
        switch section {
        case .channels:  ChannelsSection(showIssues: showIssues, focusRequest: $focusRequest)
        case .interests: InterestsSection(showIssues: showIssues, focusRequest: $focusRequest)
        case .payment:   PaymentSection(showIssues: showIssues, focusRequest: $focusRequest)
        case .terms:     TermsSection(showIssues: showIssues, focusRequest: $focusRequest)
        case .person:    PersonSection(showIssues: showIssues, focusRequest: $focusRequest)
        case .consent:   ConsentSection(showIssues: showIssues, focusRequest: $focusRequest)
        }
    }
}

/// ScrollView ของทุกส่วน — เลื่อนไปหาช่องที่ขอแล้วโฟกัสให้ (คีย์บอร์ดขึ้นที่ช่องนั้นเลย)
struct SectionScroll<Content: View>: View {
    var focus: FocusState<String?>.Binding
    @Binding var request: String?
    @ViewBuilder var content: Content

    @Environment(\.wizardHeading) private var heading

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // หัวคำถามเลื่อนไปกับเนื้อหา — ฟอร์มยาวไม่ต้องเสียที่ให้หัวค้างอยู่บนจอ
                    if let heading { heading.modifier(PKReveal(index: 0)) }
                    // ไหลเข้าทีละแผง ไม่โผล่พรึ่บพร้อมกัน
                    // วนตามตัว subview (id ของมันเอง) ไม่ใช่ index — ตอนสลับขั้น SwiftUI ยังวาดแผงเก่าที่กำลังจางออก
                    // ถ้าอ้าง `subs[i]` ด้วย index เก่าบน collection ใหม่ที่สั้นกว่า = Index out of range
                    Group(subviews: content) { subs in
                        ForEach(Array(subs.enumerated()), id: \.element.id) { pair in
                            pair.element.modifier(PKReveal(index: pair.offset + 1))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 190)
            }
            .scrollDismissesKeyboard(.interactively)
            // แป้นตัวเลข/โทรศัพท์ไม่มีปุ่มปิดของตัวเอง — ให้ "เสร็จ" เหนือคีย์บอร์ดทุกช่อง
            // (แถบปุ่มล่างหลบตอนคีย์บอร์ดขึ้น ผู้ใช้ต้องมีทางปิดที่แน่นอน ไม่ใช่เดาว่าต้องแตะที่ว่าง)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        focus.wrappedValue = nil
                    } label: {
                        Text("เสร็จ").font(.sh(15, .bold)).foregroundStyle(PK.ink)
                    }
                }
            }
            .onChange(of: request) { _, id in
                guard let id else { return }
                withAnimation(Motion.settle) { proxy.scrollTo(id, anchor: .center) }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(320))
                    focus.wrappedValue = id
                    request = nil
                }
            }
        }
    }
}

/// ข้อความผิดพลาดของช่องหนึ่ง — โผล่หลังกด "ถัดไป" แล้วไม่ผ่านเท่านั้น (ไม่ด่าตั้งแต่ยังไม่ทันพิมพ์)
func sectionIssue(_ section: ProfileSection, _ field: String, shown: Bool) -> String? {
    guard shown else { return nil }
    return section.issues(Profile.me).first { $0.field == field }?.message
}


// MARK: - ทางลัดทดสอบ

/// "เติมข้อมูลตัวอย่าง" — สำหรับคนที่ขี้เกียจพิมพ์ตอนลองแอป · เติมครบทุกช่องยกเว้นยินยอม PDPA
struct SampleFillLink: View {
    var compact = false
    @State private var filled = false

    var body: some View {
        Button {
            Haptics.impact(.medium)
            withAnimation(Motion.settle) { Profile.me.fillSample() }
            filled = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                filled = false
            }
        } label: {
            HStack(spacing: 5) {
                PIcon(filled ? .checkCircle : .magicWand, size: compact ? 11 : 13, weight: filled ? .fill : .bold)
                Text(filled ? "เติมให้แล้ว" : (compact ? "เติมข้อมูลตัวอย่าง" : "ขี้เกียจกรอก? เติมข้อมูลตัวอย่างให้ (ทดสอบ)"))
                    .font(.sh(compact ? 11.5 : 12.5, .semibold))
            }
            .foregroundStyle(filled ? PK.ok : PK.muted)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(Motion.snap, value: filled)
    }
}
