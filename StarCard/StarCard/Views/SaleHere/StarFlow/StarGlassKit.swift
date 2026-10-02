import SwiftUI
import PhosphorSwift

// MARK: - ชิ้นส่วนของหน้าใหม่ใน flow "Unbox × StarCard" (= `.pk` / `.glass` / `.wz` ของ unbox-mock)
//
// พื้นสว่าง #F9FAFB + แสงเบลอโทน champagne + การ์ด/แถวเป็นกระจก · ปุ่มถ่านแคปซูล · เลือกแล้ว = เทา + ขอบดำ
// ภาษาเดียวกับ intake (`PK`) ต่างกันแค่ชั้นแสง/กระจกที่ผู้ใช้เลือกไว้ 22 ก.ย. 2569 (ดู memory star-profile-glow-glass)

enum GL {
    static let bg = Color(red: 249 / 255, green: 250 / 255, blue: 251 / 255)
    static let ink = PK.ink
    static let muted = Color(red: 79 / 255, green: 79 / 255, blue: 79 / 255)
    static let hint = Color(red: 138 / 255, green: 143 / 255, blue: 152 / 255)
    static let verified = Color(red: 28 / 255, green: 140 / 255, blue: 237 / 255)
    static let green = Color(red: 18 / 255, green: 183 / 255, blue: 106 / 255)
    static let greenInk = Color(red: 14 / 255, green: 159 / 255, blue: 110 / 255)
    static let greenTint = Color(red: 231 / 255, green: 246 / 255, blue: 239 / 255)
    static let orb1 = Color(red: 243 / 255, green: 234 / 255, blue: 211 / 255)
    static let orb2 = Color(red: 241 / 255, green: 231 / 255, blue: 206 / 255)
    static let cardRim = Color(red: 1, green: 222 / 255, blue: 140 / 255)
    static let goldInk = Color(red: 154 / 255, green: 116 / 255, blue: 32 / 255)
    static let gold = Color(red: 201 / 255, green: 162 / 255, blue: 39 / 255)

    static func serif(_ size: CGFloat) -> Font { .custom("Didot-Italic", size: size) }
}

/// แสงเบลอ champagne สองก้อน + จุดสว่างขาว บนพื้น #F9FAFB (= `.gl-orbs`)
struct GlassOrbs: View {
    /// เล่นท่าบาน (orb-bloom) ตอนเข้าหน้า — ครั้งแรกของการ์ดเกิดเท่านั้น
    var bloom = false
    /// false = พื้นและดวงไฟวาดโดย `StarGround` ของ shell แล้ว (หน้า Star Profile) — ที่นี่โปร่งใส
    var ground = true
    @State private var shown = false

    var body: some View {
        GeometryReader { g in
            ZStack {
                if !ground { Color.clear } else {
                GL.bg
                Circle().fill(GL.orb1).frame(width: 340, height: 340).blur(radius: 70).opacity(0.7)
                    .position(x: 30, y: 110)
                    .scaleEffect(shown ? 1 : 0.55)
                Circle().fill(GL.orb2).frame(width: 320, height: 320).blur(radius: 70).opacity(0.5)
                    .position(x: g.size.width + 10, y: 250)
                Circle().fill(.white).frame(width: 140, height: 140).blur(radius: 30).opacity(0.9)
                    .position(x: 260, y: 110)
                    .scaleEffect(shown ? 1 : 0.55)
                }
            }
            .opacity(shown ? 1 : 0)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            if bloom { withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 2.4)) { shown = true } }
            else { shown = true }
        }
    }
}

/// หัวข้อกระจก: คำหน้าตัวหนา + คำเน้นเป็น serif เอียงไล่สีดำ→ทอง (= `.glass-title`)
struct GlassTitle: View {
    let words: [(String, Bool)]
    var small = false

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: words.first?.0 == "Star" ? StarCaps.gap(forSerif: small ? 40 : 54) : (small ? 7 : 8)) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, w in
                if w.0 == "Star" || w.0 == "STAR" {
                    // คำ Star/STAR = ตรา ST★R ของ Sale Here (ผู้ใช้ 30 ก.ย. 2569): นำหน้าคำ serif → สูงเข้าคู่กับ serif ·
                    // เป็นคำเน้นในประโยคไทย ("สมัครเป็น STAR") → สูงเท่าตัวหนาข้าง ๆ
                    StarCaps(height: w.1 ? StarCaps.height(forEmphasis: small ? 30 : 46) : StarCaps.height(forSerif: small ? 40 : 54))
                        .shadow(color: GL.ink.opacity(0.14), radius: 15, y: 14)
                } else if w.1 {
                    Text(w.0)
                        .font(GL.serif(small ? 40 : 54))
                        .foregroundStyle(LinearGradient(colors: [GL.ink, GL.ink, GL.goldInk], startPoint: .top, endPoint: .bottom))
                        .shadow(color: GL.ink.opacity(0.12), radius: 9, y: 12)
                } else {
                    Text(w.0)
                        .font(.sh(small ? 30 : 46, .heavy))
                        .tracking(small ? -0.8 : -2)
                        .foregroundStyle(GL.ink)
                        .shadow(color: GL.ink.opacity(0.14), radius: 15, y: 14)
                }
            }
        }
        .lineLimit(1).minimumScaleFactor(0.7)
    }
}

/// ชิปกระจกใต้หัวข้อ (= `.glass-chip`)
struct GlassChip: View {
    let icon: Ph
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            PIcon(icon, size: 15).foregroundStyle(GL.muted)
            Text(text).font(.sh(13)).foregroundStyle(GL.muted)
        }
        .padding(.horizontal, 12).frame(height: 30)
        .glassEffect(.regular.tint(.white.opacity(0.55)), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.95), lineWidth: 1))
        .shadow(color: GL.ink.opacity(0.06), radius: 7, y: 4)
    }
}

/// ปุ่มกลมกระจก 44 (= `.pk-circle` บนหน้ากระจก)
struct GlassCircleButton: View {
    let symbol: Ph
    var size: CGFloat = 44
    let action: () -> Void
    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            PIcon(symbol, size: 18).foregroundStyle(GL.ink)
                .frame(width: size, height: size)
                .contentShape(Circle())
                .glassEffect(.regular.tint(.white.opacity(0.55)).interactive(), in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.95), lineWidth: 1))
                .shadow(color: GL.ink.opacity(0.08), radius: 7, y: 4)
        }
        .buttonStyle(.plain)
    }
}

/// ปุ่มหลักของหน้า Star Profile — แคปซูลถ่าน 56 + วงแหวนขาวสองชั้น (= `.ach2-btn`)
struct GlassPrimaryButton: View {
    let title: String
    var symbol: Ph = .arrowRight
    let action: () -> Void
    var body: some View {
        Button {
            Haptics.impact(.medium)
            action()
        } label: {
            HStack(spacing: 8) {
                StarText(title, size: 16, weight: .bold, color: .white)
                PIcon(symbol, size: 18)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(Capsule().fill(GL.ink))
            .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 6).padding(-6))
            .overlay(Capsule().strokeBorder(.white.opacity(0.95), lineWidth: 1).padding(-7))
            .shadow(color: GL.ink.opacity(0.16), radius: 20, y: 16)
            .contentShape(Capsule())
        }
        .buttonStyle(DockPress())
    }
}

/// ลิงก์เล็กใต้ปุ่ม (= `.pk-link`)
struct GlassLink: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Text(title).font(.sh(13, .semibold)).foregroundStyle(GL.muted).underline()
                .padding(6).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// ป้าย "★ STAR" มุมการ์ด (= `.sc-level`)
struct StarPill: View {
    var body: some View {
        // ตรา ST★R จริงแทนคำ "★ STAR" (ผู้ใช้ 30 ก.ย. 2569)
        StarCaps(height: StarCaps.height(forText: 11))
            .padding(.horizontal, 9).frame(height: 24)
            .background(Capsule().fill(.white.opacity(0.8)))
            .overlay(Capsule().strokeBorder(GL.ink.opacity(0.08), lineWidth: 1))
    }
}

/// ตราหยัก (ดาว Verified) — ขอบมน 10 แฉก ใช้ได้ทั้งเติมทึบและเส้นประ
struct SealShape: Shape {
    var lobes = 10
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.8
        let pt = { (r: CGFloat, a: Double) in CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)) }
        let step = 2 * Double.pi / Double(lobes)
        var p = Path()
        for i in 0..<lobes {
            let a = Double(i) * step - .pi / 2
            if i == 0 { p.move(to: pt(inner, a)) }
            p.addQuadCurve(to: pt(inner, a + step), control: pt(outer * 1.12, a + step / 2))
        }
        p.closeSubpath()
        return p
    }
}

/// ดาว Verified ข้างชื่อ (ผู้ใช้ 29 ก.ย. 2569: เอาแถว "ยืนยันตัวตน" ออกจากรายการ มาเป็นดาวข้างชื่อ)
/// - ยืนยันแล้ว = ดาวน้ำเงินทึบ + ติ๊ก
/// - ยังไม่ยืนยัน = ดาวประสีเทา + "ยังไม่ได้ยืนยันตัวตน" (เทา ไม่ใช่น้ำเงิน — น้ำเงินอ่านเป็นยืนยันแล้ว, ผู้ใช้ 29 ก.ย. 2569)
///   แตะแล้วไป KYC · เข้าหน้ามาดาวเติมน้ำเงินให้ดูแวบหนึ่งว่าจะได้อะไร แล้วกลับเป็นประเทา (ครั้งเดียว ไม่วนตลอด)
/// - รอตรวจ = ดาวประสีเทา + "รอตรวจ"
struct VerifyStar: View {
    let status: VerifyStatus
    /// nil = แค่แสดง (หน้า wizard) — ยังไม่ยืนยันก็ไม่ขึ้นอะไร
    var onTap: (() -> Void)? = nil
    @State private var tease = false
    @State private var ring = false

    var body: some View {
        switch status {
        case .approved:
            seal(filled: true, tint: GL.verified, size: 20)
                .accessibilityLabel("ยืนยันตัวตนแล้ว")
        case .none, .waiting:
            if let onTap {
                let waiting = status == .waiting
                let tint = GL.hint
                Button {
                    Haptics.impact(.light)
                    onTap()
                } label: {
                    HStack(spacing: 5) {
                        ZStack {
                            Circle().strokeBorder(GL.verified.opacity(0.5), lineWidth: 1.5)
                                .scaleEffect(ring ? 1.9 : 0.9).opacity(ring ? 0 : 0.9)
                            seal(filled: tease, tint: tease ? GL.verified : tint, size: 16)
                        }
                        .frame(width: 16, height: 16)
                        Text(waiting ? "รอตรวจ" : "ยังไม่ได้ยืนยันตัวตน").font(.sh(11.5, .bold)).foregroundStyle(GL.muted)
                    }
                    .padding(.leading, 5).padding(.trailing, 9).frame(height: 26)
                    .background(Capsule().fill(GL.ink.opacity(0.06)))
                    .contentShape(Capsule())
                }
                .buttonStyle(DockPress())
                .fixedSize()
                .onAppear { if !waiting { playTease() } }
            }
        }
    }

    private func seal(filled: Bool, tint: Color, size: CGFloat) -> some View {
        ZStack {
            SealShape().fill(tint).opacity(filled ? 1 : 0)
            SealShape().stroke(tint, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [2.4, 2.2]))
                .padding(0.7).opacity(filled ? 0 : 1)
            PIcon(.check, size: size * 0.5, weight: .bold).foregroundStyle(filled ? .white : tint)
        }
        .frame(width: size, height: size)
        .scaleEffect(filled && tease ? 1.15 : 1)
    }

    /// ดาวเติมเต็มให้เห็นว่าจะได้อะไร แล้วกลับเป็นประ + วงแหวนกระจายออก — เล่นครั้งเดียวตอนเข้าหน้า
    private func playTease() {
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.6).delay(0.9)) { tease = true }
        withAnimation(.easeOut(duration: 1.1).delay(0.9)) { ring = true }
        withAnimation(.easeInOut(duration: 0.5).delay(2.2)) { tease = false }
    }
}

/// ช่องประ "ข้อมูลจะขึ้นตรงนี้" บนการ์ดที่ยังว่าง (= `.wzi-ghost`)
struct GhostSlot: View {
    let text: String
    var body: some View {
        Text(text).font(.sh(11.5, .semibold)).foregroundStyle(GL.hint)
            .padding(.horizontal, 9).frame(height: 24)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.white.opacity(0.35)))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(GL.ink.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
    }
}

/// การ์ดกระจกใบจริง ประกอบจาก Star Profile · อัปเดตตามที่กรอก (= `cardView` ของเว็บ, สไตล์ `.ach2.glass .sc-card`)
struct StarGlassCard: View {
    @Environment(StarFlow.self) private var flow
    /// ย่อ: ไม่โชว์แนะนำตัว/ผลงาน (หน้า intro ของ wizard)
    var compact = false
    /// ช่องที่ยังว่างให้โชว์เป็นช่องประ (หน้า intro)
    var ghosts: [WizStep] = []
    /// แตะรูปโปรไฟล์ — Star Profile พาไปหน้า "รูปและผลงาน" · nil = รูปเฉย ๆ
    var onAvatar: (() -> Void)? = nil
    /// แตะดาวข้างชื่อ = ไปยืนยันตัวตน · nil = ดาวโชว์เฉพาะตอนยืนยันแล้ว
    var onVerify: (() -> Void)? = nil
    /// หมวดสุดท้าย "Star Card" (ใบที่กำลังแสดง) — nil = ไม่มีหมวดนี้ (หน้า reveal / intro / ยังไม่มีใบในคลัง)
    var liveCard: CardRecord? = nil
    /// ใบที่โชว์คือการ์ดตั้งต้น (ยังไม่มีใบจริงในคลัง)
    var cardIsDefault = false
    var cardCount = 0
    var onOpenCard: () -> Void = {}

    private var socials: [StarSocial] { StarSocial.allCases.filter { flow.connected.contains($0) } }
    /// เรท/ข้อมูลผู้ติดตามอยู่หน้าเดียวกับช่องทาง — ขึ้นช่องประเฉพาะข้อที่ยังไม่มีจริง
    private func ghost(_ s: WizStep) -> Bool { ghosts.contains(s.page) && !(s.dataKey.map(flow.has) ?? false) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                avatar
                VStack(alignment: .leading, spacing: 4) {
                    // ชื่อ + ดาว — ป้าย "ยังไม่ได้ยืนยันตัวตน" ยาว ถ้าไม่พอบรรทัดเดียวให้ลงบรรทัดใต้ชื่อ ไม่ตัดชื่อ
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 6) {
                            nameText.fixedSize()
                            VerifyStar(status: flow.verify, onTap: onVerify)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            nameText
                            VerifyStar(status: flow.verify, onTap: onVerify)
                        }
                    }
                    .padding(.trailing, flow.isStar ? 64 : 0)
                    if flow.has(.categories) {
                        // ชื่อผู้ใช้ตัวเดียวกับที่การ์ดและลิงก์การ์ดใช้ (`Profile.handle` — ช่องแรกที่เชื่อม หรือชื่อบัญชี)
                        Text("@\(Profile.me.handle) · " + flow.facts(StarRow.all.first { $0.key == .categories }!).joined(separator: " · "))
                            .font(.sh(13)).foregroundStyle(GL.muted).lineLimit(1)
                    } else if ghosts.isEmpty {
                        Text("สายที่ใช่จะขึ้นตรงนี้").font(.sh(13)).italic().foregroundStyle(GL.muted.opacity(0.6))
                    } else {
                        PKWrap(spacing: 5) {
                            if ghost(.categories) { GhostSlot(text: "สายที่ใช่") }
                            if ghost(.province) { GhostSlot(text: "พื้นที่") }
                            if ghost(.availability) { GhostSlot(text: "วันว่าง") }
                        }
                    }
                }
            }
            if !ghosts.isEmpty {
                PKWrap(spacing: 5) {
                    if ghost(.socials) { GhostSlot(text: "ยอดผู้ติดตาม") }
                    if ghost(.media) { GhostSlot(text: "รูปและผลงาน") }
                    if ghost(.rate) { GhostSlot(text: "เรทรับงาน") }
                    if ghost(.insight) { GhostSlot(text: "ข้อมูลผู้ติดตาม") }
                    if ghost(.about) { GhostSlot(text: "แนะนำตัว") }
                    if ghost(.kyc) { GhostSlot(text: "Verified") }
                }
            } else if !socials.isEmpty && flow.has(.socials) {
                // ช่องทาง = หมวดของมันเองในการ์ด (หัวเล็ก + เส้นคั่น แบบแถวท้าย) ไม่ลอยต่อจากชื่อ (ผู้ใช้ 24 ก.ย. 2569)
                // ยังไม่ผูกโซเชียล = ไม่มีหมวดนี้เลย ไม่ใช่หัวข้อกับประโยคบอกว่ายังไม่มี (ผู้ใช้ 1 ต.ค. 2569: "ยังไม่มีก็เอาออก")
                VStack(alignment: .leading, spacing: 8) {
                    Text("ช่องทาง").font(.sh(12, .semibold)).foregroundStyle(GL.muted)
                    PKWrap(spacing: 8) {
                        ForEach(socials) { s in
                            HStack(spacing: 5) {
                                Image(s.icon).resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20).clipShape(Circle())
                                    .saturation(0).brightness(-0.35).contrast(1.4)
                                Text(StarFlow.fmt(flow.followers(s))).font(.sh(14, .bold)).foregroundStyle(GL.ink)
                            }
                            .padding(.leading, 6).padding(.trailing, 12).frame(height: 34)
                            .background(Capsule().fill(.white.opacity(0.82)))
                            .overlay(Capsule().strokeBorder(.white.opacity(0.95), lineWidth: 1))
                        }
                    }
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { GL.ink.opacity(0.08).frame(height: 1) }
            }
            if !compact && flow.has(.about) {
                Text(flow.about).font(.sh(15)).foregroundStyle(GL.ink).lineSpacing(4)
            }
            if !compact && flow.reviewed {
                HStack(spacing: 6) {
                    ForEach(["ph01", "ph04"], id: \.self) { n in
                        Image(n).resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(.white, lineWidth: 2))
                    }
                }
            }
            // แถวท้ายการ์ดเอาออกหมดแล้ว: "ทำงานผ่าน Sale Here N งาน" (ผู้ใช้ 24 ก.ย. 2569) · "เรทเริ่ม ฿1,500/โพสต์" และ
            // "ยืนยันตัวตนแล้ว" (ผู้ใช้ 30 ก.ย. 2569) — เรทเป็นของแบรนด์ตอนคัดคน ส่วนยืนยันตัวตนมีตราน้ำเงินข้างชื่อบอกอยู่แล้ว
            if ghosts.isEmpty, let liveCard {
                StarCardSection(record: liveCard, isDefault: cardIsDefault, published: flow.hasCard, onOpen: onOpenCard)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassBody)
        .overlay(alignment: .topTrailing) {
            if flow.isStar || !ghosts.isEmpty { StarPill().padding(12) }
        }
    }

    private var nameText: some View {
        Text(SHMockUser.name).font(.sh(20, .heavy)).foregroundStyle(GL.ink).lineLimit(1)
    }

    @ViewBuilder
    private var avatar: some View {
        let pic = SHAvatar(size: 60)
            .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 3))
            .shadow(color: GL.ink.opacity(0.12), radius: 8, y: 6)
        if let onAvatar {
            Button {
                Haptics.impact(.light)
                onAvatar()
            } label: {
                pic.overlay(alignment: .bottomTrailing) {
                    PIcon(.camera, size: 11, weight: .fill).foregroundStyle(.white)
                        .frame(width: 22, height: 22).background(Circle().fill(GL.ink))
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(DockPress())
            .accessibilityLabel("เปลี่ยนรูป")
        } else {
            pic
        }
    }

    private var glassBody: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        return shape
            .fill(LinearGradient(colors: [.white.opacity(0.42), .white.opacity(0.14), .white.opacity(0.3)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .glassEffect(.regular.tint(.white.opacity(0.35)), in: shape)
            .overlay(shape.strokeBorder(.white.opacity(0.75), lineWidth: 1).padding(1))
            .overlay(shape.strokeBorder(GL.cardRim.opacity(0.75), lineWidth: 1))
            .shadow(color: Color(red: 1, green: 210 / 255, blue: 90 / 255).opacity(0.14), radius: 8)
            .shadow(color: GL.ink.opacity(0.08), radius: 22, y: 18)
    }
}

// MARK: - ชิ้นส่วน wizard (= `.wz-*`)

/// ชิปเลือก (= `.wz-chip`): ขาว+ขอบบาง · เลือกแล้ว = เทา + ขอบดำ
struct WzChip: View {
    let text: String
    let on: Bool
    let action: () -> Void
    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Text(text).font(.sh(14, on ? .bold : .semibold)).foregroundStyle(GL.ink)
                .padding(.horizontal, 14).frame(height: 40)
                .background(Capsule().fill(on ? PK.pick : .white))
                .overlay(Capsule().strokeBorder(on ? GL.ink : PK.line, lineWidth: on ? 1.5 : 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(Motion.snap, value: on)
    }
}

/// กล่องเลือก (= `.wz-tile`): เลขใหญ่ + คำอธิบาย
struct WzTile: View {
    let title: String
    let sub: String
    let on: Bool
    let action: () -> Void
    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            VStack(spacing: 2) {
                Text(title).font(.sh(22, .heavy)).foregroundStyle(GL.ink).lineLimit(1).minimumScaleFactor(0.7)
                Text(sub).font(.sh(12.5)).foregroundStyle(PK.muted)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 6)
            .background(PK.shape(16).fill(on ? PK.pick : .white))
            .overlay(PK.shape(16).strokeBorder(on ? GL.ink : PK.line, lineWidth: on ? 1.5 : 1))
            .contentShape(PK.shape(16))
        }
        .buttonStyle(.plain)
        .animation(Motion.snap, value: on)
    }
}

/// ช่องกรอกของ wizard (= `.wz-in.col`): ป้ายเล็กด้านบน + ค่า + ท้าย
struct WzInput: View {
    let label: String
    @Binding var text: String
    var placeholder = ""
    var unit: String? = nil
    var keyboard: UIKeyboardType = .default
    var select = false
    /// ตัวเลือกของช่อง select — แตะแล้วขึ้นเมนูให้เลือก (ไม่มีตัวเลือก = พิมพ์เองได้)
    var options: [String] = []
    /// รับเฉพาะตัวเลข ตัดที่เกินความยาวนี้ทิ้ง (nil = ไม่ใช่ช่องตัวเลข)
    var digits: Int? = nil
    @FocusState private var focused: Bool

    var body: some View {
        if select && !options.isEmpty {
            Menu {
                ForEach(options, id: \.self) { o in
                    Button { Haptics.impact(.light); text = o } label: {
                        if o == text { Label(o, systemImage: "checkmark") } else { Text(o) }
                    }
                }
            } label: { field }
            .buttonStyle(.plain)
        } else {
            field
        }
    }

    private func cleanDigits(_ v: String) {
        guard let max = digits else { return }
        let clean = String(v.filter { $0.isASCII && $0.isNumber }.prefix(max))
        if clean != v { text = clean }
    }

    private var isMenu: Bool { select && !options.isEmpty }

    private var field: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(.sh(11.5, .semibold)).foregroundStyle(PK.hint)
            HStack(spacing: 6) {
                TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(PK.hint.opacity(0.7)))
                    .font(.sh(17)).foregroundStyle(GL.ink).tint(GL.ink)
                    .keyboardType(keyboard)
                    .focused($focused)
                    .disabled(isMenu)
                    .onChange(of: text) { _, v in cleanDigits(v) }
                    .onAppear { cleanDigits(text) }   // ค่าเก่าที่เคยพิมพ์ตัวอักษรไว้
                if let unit { Text(unit).font(.sh(15, .semibold)).foregroundStyle(PK.hint) }
                if isMenu { PIcon(.caretDown, size: 14).foregroundStyle(PK.line2) }
            }
            .frame(height: 30)
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 6)
        .background(PK.shape(16).fill(.white))
        .overlay(PK.shape(16).strokeBorder(focused ? GL.ink : PK.line, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { if !isMenu { focused = true } }
        .animation(Motion.snap, value: focused)
    }
}

/// ชิปบอก "แบรนด์ใช้ข้อนี้ทำอะไร" ใต้หัวข้อ (= `.nchip` · ชิ้นแรกไล่สี champagne + ไอคอนตา)
struct NudgeChips: View {
    let lines: [String]
    var body: some View {
        PKWrap(spacing: 6) {
            ForEach(Array(lines.enumerated()), id: \.offset) { i, t in
                HStack(spacing: 4) {
                    if i == 0 { PIcon(.eye, size: 12).foregroundStyle(Color(red: 180 / 255, green: 116 / 255, blue: 26 / 255)) }
                    Text(t).font(.sh(12, .semibold)).foregroundStyle(i == 0 ? GL.ink : GL.muted)
                }
                .padding(.horizontal, 10).frame(height: 26)
                .background(
                    Capsule().fill(i == 0
                        ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 243 / 255, blue: 201 / 255), Color(red: 1, green: 227 / 255, blue: 154 / 255), Color(red: 1, green: 217 / 255, blue: 194 / 255)], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(PK.fieldFill)))
                .overlay(Capsule().strokeBorder(i == 0 ? Color(red: 1, green: 214 / 255, blue: 110 / 255).opacity(0.6) : .clear, lineWidth: 1))
            }
        }
    }
}

// MARK: - dialog กลางจอ + toast (= `U.dialog({kind:'modal'})` / `Store.toast`)

struct FlowModal: View {
    let title: String
    let detail: String
    let buttons: [(String, Bool, () -> Void)]

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 14) {
                Text(title).font(.sh(17, .bold)).foregroundStyle(SH.ink).multilineTextAlignment(.center)
                Text(detail).font(.sh(14)).foregroundStyle(SH.muted).multilineTextAlignment(.center).lineSpacing(3)
                VStack(spacing: 8) {
                    ForEach(Array(buttons.enumerated()), id: \.offset) { _, b in
                        Button {
                            Haptics.impact(.light)
                            b.2()
                        } label: {
                            Text(b.0).font(.sh(15, .semibold))
                                .foregroundStyle(b.1 ? .white : SH.ink)
                                .frame(maxWidth: .infinity).frame(height: 46)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(b.1 ? SH.red : PK.fieldFill))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
            .padding(22)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
            .padding(.horizontal, 36)
        }
        .transition(.opacity)
    }
}

struct FlowToast: View {
    let text: String
    var body: some View {
        Text(text).font(.sh(13, .semibold)).foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Capsule().fill(SH.ink.opacity(0.92)))
            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
            .padding(.bottom, 90)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
