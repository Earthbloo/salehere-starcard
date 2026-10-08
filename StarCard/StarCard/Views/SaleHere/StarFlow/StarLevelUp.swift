import SwiftUI
import PhosphorSwift

// MARK: - จังหวะ "ได้เป็น STAR" ทั้งหน้า
// ผู้ใช้ 2 ต.ค. 2569: "เอาทั้งหน้า" → แบบเกมเต็ม "การ์ตูนเกิน" → แบบเรียบ "ไม่เอา ต้องดูว้าว"
// = ว้าวแบบพรีเมียม (แสงขอบจอแบบ Siri iOS 18 · เปิดตัวสินค้า Apple · บัตรโลหะ) ไม่ใช่เกมการ์ตูน: ไม่มีรัศมี/โปรยดาว/จอมืด
//
// ผู้ใช้ 2 ต.ค. 2569 (รอบถัดมา): "ช้าไป · ตอนเปลี่ยนสีทองเป็นเทาไม่เนียน" → ย่อ แล้ว "ช้าลงได้ · เข้ามาต้อง animate เลย" → ~3.4 วิ เริ่มทันที; ระหว่างบิน
// ตราค่อย ๆ เปลี่ยนจากทองเป็นสีจริงของปลายทาง (หัวขาว / ป้ายหมึก) แล้วสลับกับของจริงในเฟรมเดียวกัน ไม่มีช่วงหายแล้วโผล่
//  · armed   0.00s  ซ่อนดาว/ป้าย ST★R/ขอบทองของการ์ด/หัว ST★R Card ไว้รอเปิด
//  · charge  +wait  แสงทองไหลวนรอบขอบจอ · ขอบทองวิ่งรอบรูปโปรไฟล์ · สั่นเบา
//  · impact  +0.85  แสงขอบจอวาบแล้วหด · หน้าเป็นกระจกฝ้า · รูปเด้งนิด · สั่นแรง
//  · reward  +0.95  ตรา ทองโลหะกลางจอ เบลอ→คม + แสงวาบพาดตัวอักษร + ข้อความ · สั่น success
//  · fly     +2.25  ตราหดบินไปปลายทาง สีทองค่อย ๆ กลายเป็นสีจริง · ฝ้าหาย
//  · landed  +2.85  ตราซ้อนพอดีกับของจริงแล้วสลับ · ป้ายเด้ง/ขอบการ์ดไล่ทอง/ดาวเข้ามุมรูป
//  · done    +3.10  นิ่ง
// ดูแล้วจำไว้ — กลับไปไม่เป็น STAR (เช่นสลับใน lab) แล้วเป็นใหม่ก็เล่นใหม่ · replay: `-starflow.starLevelSeen NO`

@Observable
final class LevelUp {
    static let shared = LevelUp()

    enum Beat: Int, Comparable {
        case idle, armed, charge, impact, reward, fly, done
        static func < (a: Beat, b: Beat) -> Bool { a.rawValue < b.rawValue }
    }

    private(set) var beat: Beat = .idle
    /// ตรากลางจอบินถึงปลายทางแล้ว — ของจริง (หัว / ป้าย) โผล่แทนตราในเฟรมเดียวกัน
    private(set) var landed = false
    var playing: Bool { beat > .idle && beat < .done }
    /// ฉลองอะไรอยู่ — ได้เป็น STAR (Star Profile) หรือเปิด Star Card ครั้งแรก
    enum Kind { case star, card }
    private(set) var kind: Kind = .star
    /// เริ่มที่ปิดจอทึบ (ไม่เห็นหน้าข้างใต้จนตราบิน) — เปิด Star Card ครั้งแรก · กรอกสมัครครบ (ผู้ใช้ 2 ต.ค. 2569:
    /// "flow เหมือนเดิม แค่ขึ้น motion Star ก่อนอันแรก")
    private(set) var covered = false
    /// ชิ้นของหน้า Star Profile (รูป/ป้าย/ขอบการ์ด) ขยับเฉพาะตอนฉลอง STAR
    var starPlaying: Bool { playing && kind == .star }
    var cardPlaying: Bool { playing && kind == .card }
    /// ตำแหน่งหัว "ST★R Card" (พิกัดทั้งจอ) — ปลายทางของตรากลางจอตอนเปิด Star Card ครั้งแรก
    var titleFrame: CGRect = .zero
    /// ตำแหน่งป้าย ST★R บนการ์ด (พิกัดทั้งจอ) — ปลายทางที่ตรากลางจอบินไปลง
    var pillFrame: CGRect = .zero

    private let seenKey = "starflow.starLevelSeen"
    /// เวลาบินของตราจากกลางจอไปปลายทาง
    static let flight = 0.6

    /// shell เรียกทุกครั้งที่สถานะ/หน้าเปลี่ยน (`SaleHereShell.celebrateStar`) — ได้เป็น STAR แล้วยังไม่เคยฉลอง = เล่น
    /// `covered` = ปิดจอทึบตั้งแต่เฟรมแรก แล้วเล่นทันที — หน้าข้างใต้โผล่หลัง motion (กรอกสมัครครบ → motion STAR ก่อนหน้าการ์ดเกิด)
    func sync(isStar: Bool, reduceMotion: Bool, after wait: Double = 0.3, covered: Bool = false) {
        let d = UserDefaults.standard
        guard isStar else {
            // motion เปิด Star Card ครั้งแรกก็เริ่มนับใหม่ด้วย — ไม่งั้นเล่นได้ครั้งเดียวต่อการติดตั้ง
            d.set(false, forKey: seenKey); d.set(false, forKey: Self.cardSeenKey); beat = .idle
            return
        }
        if playing { return }
        if d.bool(forKey: seenKey) { beat = .done; return }
        d.set(true, forKey: seenKey)
        kind = .star
        self.covered = covered && !reduceMotion
        if reduceMotion { withAnimation(.easeOut(duration: 0.4)) { beat = .done }; return }
        play(after: wait)
    }

    /// เปิด Star Card ครั้งแรก = ฉลองแบบเดียวกับได้เป็น STAR (ผู้ใช้ 2 ต.ค. 2569: "ต้องมี animate Star Card Motion
    /// เหมือน Star Profile ตอนเสร็จ") — ตรา "ST★R Card" ทองกลางจอ แล้วบินขึ้นไปเป็นหัวของหน้า
    /// เล่นครั้งเดียว · replay: `-starflow.cardRevealSeen NO`
    private static let cardSeenKey = "starflow.cardRevealSeen"
    var cardRevealSeen: Bool { UserDefaults.standard.bool(forKey: Self.cardSeenKey) }

    /// ตราบินขึ้นเป็นหัว "ST★R Card" ของหน้าคลัง · false = ไปหน้าเลือกเทมเพลต (ไม่มีหัวให้ลง) ตราจางหายแทน
    private(set) var toTitle = true

    func revealCard(reduceMotion: Bool, toTitle: Bool = true) {
        let key = Self.cardSeenKey, d = UserDefaults.standard
        guard !playing, !d.bool(forKey: key) else { return }
        d.set(true, forKey: key)
        guard !reduceMotion else { return }
        kind = .card
        self.toTitle = toTitle
        covered = true
        // เริ่มทันทีตอนเข้าหน้า — ชั้นฉลองปิดหน้าไว้ตั้งแต่เฟรมแรก ไม่ให้เห็นการ์ด/เทมเพลตข้างใต้ก่อน
        // (ผู้ใช้ 2 ต.ค. 2569: "เข้ามาต้อง animate เลย อันนี้มันเห็น Template แปปนึง · ช้าลงได้")
        play(after: 0)
    }

    private func play(after wait: Double) {
        beat = .armed; landed = false
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(wait))
            beat = .charge
            if covered {
                // เปิด Star Card: ไม่มีอะไรให้ชาร์จ (ไม่มีวงรูปโปรไฟล์) — ตราขึ้นกลางจอเกือบทันที
                // (ผู้ใช้ 2 ต.ค. 2569: "กว่าจะขึ้น star card กลางจอมันนานมาก")
                try? await Task.sleep(for: .milliseconds(200))
            } else {
                try? await Task.sleep(for: .milliseconds(450))
                Haptics.impact(.soft)
                try? await Task.sleep(for: .milliseconds(400))
            }
            beat = .impact
            Haptics.rigid()
            try? await Task.sleep(for: .milliseconds(covered ? 0 : 100))
            beat = .reward
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            try? await Task.sleep(for: .milliseconds(1300))
            beat = .fly
            try? await Task.sleep(for: .milliseconds(Int(LevelUp.flight * 1000)))
            landed = true
            Haptics.impact(.light)   // ตราลงที่
            try? await Task.sleep(for: .milliseconds(250))
            beat = .done
        }
    }
}

/// ทองไล่สีวนรอบ — สว่าง/เข้มสลับ ให้ดูเป็นโลหะ ไม่ใช่เหลืองแบน
enum StarGold {
    static let light = Color(red: 1, green: 0.95, blue: 0.66)
    static let mid = Color(red: 0.97, green: 0.73, blue: 0)
    static let deep = Color(red: 0.88, green: 0.54, blue: 0)
    static let warm = Color(red: 1, green: 0.83, blue: 0.3)
    static let ring = AngularGradient(colors: [light, mid, deep, warm, light],
                                      center: .center, startAngle: .degrees(-90), endAngle: .degrees(270))
}

// MARK: - รูปโปรไฟล์

/// รูปโปรไฟล์บนการ์ด Star Profile — เป็น STAR = ขอบทองไล่สี + ดาวขวาล่าง (เหมือนหน้าโปรไฟล์หลัก)
struct StarAvatar: View {
    let isStar: Bool
    var size: CGFloat = 60
    private var lv: LevelUp { LevelUp.shared }

    @State private var ring: CGFloat = 0
    @State private var badge = false
    @State private var bump = false
    @State private var wave = false
    @State private var sparkOn = false
    @State private var shine: CGFloat = -1.2

    var body: some View {
        SHAvatar(size: size)
            .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 3))
            .overlay {
                LinearGradient(colors: [.clear, .white.opacity(0.75), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: size * 0.45)
                    .rotationEffect(.degrees(20))
                    .offset(x: shine * size)
                    .clipShape(Circle())
                    .allowsHitTesting(false)
            }
            .overlay {
                Circle().inset(by: 1.25).trim(from: 0, to: ring)
                    .stroke(StarGold.ring, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: StarGold.mid.opacity(ring > 0 && ring < 1 ? 0.8 : 0), radius: 6)
            }
            .scaleEffect(bump ? 1.06 : 1)
            .shadow(color: GL.ink.opacity(0.12), radius: 8, y: 6)
            .background {
                Circle().stroke(StarGold.ring, lineWidth: 1.5)
                    .scaleEffect(wave ? 1.6 : 1).opacity(wave ? 0 : (sparkOn ? 0.6 : 0))
            }
            .overlay(alignment: .bottomTrailing) {
                if badge {
                    PIcon(.star, size: 11, weight: .fill).foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(LinearGradient(colors: [StarGold.warm, StarGold.deep], startPoint: .top, endPoint: .bottom)))
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        .offset(x: 2, y: 2)
                        .transition(.asymmetric(insertion: .scale(scale: 0.1).combined(with: .opacity), removal: .opacity))
                }
            }
            .onAppear { apply(lv.beat, animated: false) }
            .onChange(of: lv.beat) { _, b in if lv.kind == .star { apply(b, animated: true) } }
            .onChange(of: isStar) { _, _ in apply(lv.beat, animated: false) }
    }

    private func apply(_ b: LevelUp.Beat, animated: Bool) {
        guard isStar else { ring = 0; badge = false; return }
        guard animated else {
            let shown = !lv.starPlaying
            ring = shown ? 1 : 0; badge = shown
            return
        }
        switch b {
        case .idle, .done:
            if !(ring == 1 && badge) { withAnimation(.easeOut(duration: 0.3)) { ring = 1; badge = true } }
        case .armed:
            ring = 0; badge = false; wave = false; shine = -1.2
        case .charge:
            withAnimation(.timingCurve(0.45, 0, 0.55, 1, duration: 0.85)) { ring = 1 }
        case .impact:
            // แบบเรียบ: เด้งนิดเดียว + วงทองจาง ๆ กระจายออกหนึ่งวง ไม่มีแฟลช/ประกาย
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { bump = true }
            sparkOn = true
            withAnimation(.easeOut(duration: 0.9)) { wave = true }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { bump = false }
                try? await Task.sleep(for: .milliseconds(800))
                sparkOn = false
            }
        case .reward:
            break
        case .fly:
            // ฝ้าหายแล้วค่อยให้เห็นดาวเข้ามุม + แสงวาบพาดรูป
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(Int(LevelUp.flight * 1000)))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { badge = true }
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.easeInOut(duration: 0.55)) { shine = 1.2 }
            }
        }
    }
}

// MARK: - ชั้นฉลองทั้งจอ

/// วาดเหนือทุกอย่างของ shell ระหว่างเล่น — ไม่รับแตะ
struct LevelUpOverlay: View {
    private var lv: LevelUp { LevelUp.shared }

    @State private var edge = 0.0          // แสงขอบจอ
    @State private var edgeWide = false    // วาบตอนปัง
    /// เปิด Star Card เริ่มที่ปิดทึบตั้งแต่เฟรมแรก (ค่าเริ่มของ State ไม่ใช่ animation) — ห้ามเห็นการ์ดก่อนตราบินขึ้น
    @State private var frost = LevelUp.shared.covered ? 1.0 : 0.0
    @State private var markIn = false
    @State private var markShine: CGFloat = -1
    @State private var textIn = false
    @State private var flying = false
    @State private var t0 = Date()

    private let markH: CGFloat = 70

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let center = CGPoint(x: w / 2, y: h * 0.42)
            let card = lv.kind == .card
            let pill = lv.pillFrame, title = lv.titleFrame
            let dest = card
                ? (title == .zero ? CGPoint(x: w * 0.4, y: 120) : CGPoint(x: title.midX, y: title.midY))
                : (pill == .zero ? CGPoint(x: w - 50, y: h * 0.3) : CGPoint(x: pill.midX, y: pill.midY))
            ZStack {
                // กระจกฝ้าทั้งหน้า — เห็นหน้าเดิมลาง ๆ · หน้าการ์ดเป็นเวทีมืด ฝ้าจึงเป็นควันเข้ม ไม่ซีดขาว
                // หน้าการ์ด: หรี่ด้วยดำล้วน ไม่ใช้ material — material บนเวทีแดงเข้มออกเทา แล้วตอนหายสีเพี้ยนเทา→แดง
                // (ผู้ใช้ 2 ต.ค. 2569: "ตอนเปลี่ยนสีทองเป็นเทาไม่เนียน") · หน้าโปรไฟล์พื้นสว่าง ใช้ฝ้าขาวได้
                if card {
                    // ทึบ ไม่โปร่ง — การ์ดข้างใต้โผล่ตอนตราบินขึ้นหัวเท่านั้น (ผู้ใช้ 2 ต.ค. 2569: "ห้ามเห็น template ก่อน")
                    // สีเดียวกับมุมมืดของเวทีการ์ด ตอนจางจึงไม่เปลี่ยนโทน
                    RadialGradient(colors: [Color(red: 0.2, green: 0.07, blue: 0.08), Color(red: 0.07, green: 0.02, blue: 0.03)],
                                   center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: h * 0.7)
                        .opacity(frost)
                } else if lv.covered {
                    // พื้นสว่างทึบโทนเดียวกับหน้า Star (champagne) — หน้าการ์ดเกิดโผล่ตอนตราบินลงป้าย
                    RadialGradient(colors: [.white, GL.bg], center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: h * 0.7)
                        .overlay(Circle().fill(GL.orb1).frame(width: 340).blur(radius: 80).opacity(0.5).position(x: w * 0.5, y: h * 0.42))
                        .opacity(frost)
                } else {
                    Rectangle().fill(.ultraThinMaterial).opacity(frost)
                    Color.white.opacity(frost * 0.35)
                }
                edgeGlow(w: w, h: h)
                Group {
                    if card && !lv.toTitle {
                        // ไปหน้าเลือกเทมเพลต: ไม่มีหัวให้ลง — ตราขยายนิดแล้วจางหายพร้อมม่าน
                        cardTitle.scaleEffect(flying ? 1.45 : (markIn ? 1.3 : 1.1))
                    } else if card {
                        // ประกอบเหมือนหัวหน้า Star Card ทุกค่า — บินไปลงแล้วซ้อนพอดีกับหัวจริง
                        cardTitle.scaleEffect(flying ? 1 : (markIn ? 1.3 : 1.1))
                    } else {
                        mark.scaleEffect(flying ? StarCaps.height(forText: 11) / markH : (markIn ? 1 : 0.86))
                    }
                }
                .blur(radius: markIn ? 0 : 14)
                // ถึงปลายทาง = สลับกับของจริงทันที (สีเดียวกันแล้ว ไม่มีช่วงจาง)
                .opacity(markIn && !lv.landed && !(card && !lv.toTitle && flying) ? 1 : 0)
                .position(flying && !(card && !lv.toTitle) ? dest : center)
                VStack(spacing: 6) {
                    // คำ STAR = ตรา ST★R (`StarText`) แบบ salehere-ios
                    if !card {
                        StarText("คุณเป็น STAR แล้ว", size: 22, weight: .heavy, color: GL.ink)
                    } else {
                        Text(lv.toTitle ? "การ์ดของคุณพร้อมแล้ว" : "เลือกแบบการ์ดใบแรก").font(.sh(22, .heavy))
                            .foregroundStyle(.white)
                    }
                    Text(!card ? "ยืนยันตัวตนผ่าน · แบรนด์เลือกคุณได้แล้ว" : lv.toTitle ? "แต่ง · แชร์ · ส่งให้แบรนด์ได้เลย" : "ข้อมูลของคุณเติมลงการ์ดให้เอง").font(.sh(14))
                        .foregroundStyle(card ? .white.opacity(0.75) : GL.muted)
                }
                .opacity(textIn ? 1 : 0)
                .offset(y: textIn ? 0 : 10)
                .position(x: center.x, y: center.y + markH * 0.5 + 44)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { t0 = Date(); apply(lv.beat) }
        .onChange(of: lv.beat) { _, b in apply(b) }
    }

    /// ตรา ST★R ทองโลหะ + แสงวาบพาดตัวอักษร
    private var mark: some View {
        let w = markH * StarCapsShape.aspect
        return StarCapsShape()
            .fill(LinearGradient(colors: [StarGold.deep, StarGold.warm, StarGold.light, StarGold.mid, StarGold.deep],
                                 startPoint: .topLeading, endPoint: .bottomTrailing), style: FillStyle(eoFill: true))
            .overlay {
                LinearGradient(colors: [.clear, .white.opacity(0.95), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: w * 0.28)
                    .rotationEffect(.degrees(18))
                    .offset(x: markShine * w * 0.75)
                    .mask(StarCapsShape().fill(style: FillStyle(eoFill: true)))
            }
            .frame(width: w, height: markH)
            // ระหว่างบิน ทอง → หมึกของป้าย ST★R
            .overlay { StarCapsShape().fill(GL.ink, style: FillStyle(eoFill: true)).opacity(flying ? 1 : 0) }
            .shadow(color: StarGold.mid.opacity(flying ? 0 : 0.55), radius: 22)
    }

    /// "ST★R Card" ทองโลหะ — ขนาด/ระยะเดียวกับ `StarHeader.title` (serif 54) · แสงวาบตัดตามตัวอักษร
    private var cardTitle: some View {
        let metal = LinearGradient(colors: [StarGold.deep, StarGold.warm, StarGold.light, StarGold.mid, StarGold.deep],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
        let real = LinearGradient(colors: [.white, .white, Color(red: 232 / 255, green: 199 / 255, blue: 102 / 255)],
                                  startPoint: .top, endPoint: .bottom)
        return cardWords(metal)
            .overlay {
                LinearGradient(colors: [.clear, .white.opacity(0.95), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 70)
                    .rotationEffect(.degrees(18))
                    .offset(x: markShine * 160)
                    .mask(cardWords(Color.white))
            }
            // ระหว่างบิน ทอง → สีจริงของหัว (ขาว ไล่ทองอ่อนลงล่าง) — ลงที่แล้วตรงกับหัวจริงทุกพิกเซล
            .overlay { cardWords(real).opacity(flying && lv.toTitle ? 1 : 0) }
            .shadow(color: StarGold.mid.opacity(flying && lv.toTitle ? 0 : 0.55), radius: 22)
            .shadow(color: .black.opacity(flying && lv.toTitle ? 0.35 : 0), radius: 15, y: 14)
    }

    private func cardWords<S: ShapeStyle>(_ fill: S) -> some View {
        let capsH = StarCaps.height(forSerif: 54)
        return HStack(alignment: .lastTextBaseline, spacing: StarCaps.gap(forSerif: 54)) {
            StarCapsShape()
                .fill(fill, style: FillStyle(eoFill: true))
                .frame(width: capsH * StarCapsShape.aspect, height: capsH)
                .alignmentGuide(.lastTextBaseline) { d in d[.bottom] - capsH * StarCapsShape.descent }
            Text("Card").font(GL.serif(54)).foregroundStyle(fill)
        }
        .lineLimit(1)
        .fixedSize()
    }

    /// แสงทองไหลวนรอบขอบจอ (แบบ Siri) — สองชั้น: ชั้นกว้างเบลอ + เส้นคม
    private func edgeGlow(w: CGFloat, h: CGFloat) -> some View {
        TimelineView(.animation) { tl in
            let a = tl.date.timeIntervalSince(t0) * 220
            // ทองล้วน — ขาวในวงออกเงิน/เทาบนพื้นมืด
            let grad = AngularGradient(colors: [StarGold.light, StarGold.deep, StarGold.warm, StarGold.light, StarGold.mid, StarGold.light],
                                       center: .center, angle: .degrees(a))
            let shape = RoundedRectangle(cornerRadius: 56, style: .continuous)
            ZStack {
                shape.strokeBorder(grad, lineWidth: edgeWide ? 46 : 26).blur(radius: 22)
                shape.strokeBorder(grad, lineWidth: edgeWide ? 10 : 5).blur(radius: 3)
            }
            .frame(width: w, height: h)
            .opacity(edge)
        }
    }

    private func apply(_ b: LevelUp.Beat) {
        switch b {
        case .idle, .done:
            break
        case .armed:
            if lv.covered { frost = 1 }
        case .charge:
            // แสงขึ้นทันที (ไม่ easeIn) — ไม่มีช่วงจอมืดเปล่าตอนเพิ่งเข้า
            withAnimation(.easeOut(duration: 0.45)) { edge = 1 }
        case .impact:
            withAnimation(.easeOut(duration: 0.15)) { edgeWide = true }
            withAnimation(.easeOut(duration: 0.3)) { frost = 1 }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.easeOut(duration: 0.6)) { edgeWide = false; edge = 0 }
            }
        case .reward:
            withAnimation(.timingCurve(0.2, 0.9, 0.3, 1, duration: lv.covered ? 0.45 : 0.7)) { markIn = true }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(.easeOut(duration: 0.45)) { textIn = true }
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.easeInOut(duration: 0.8)) { markShine = 1 }
            }
        case .fly:
            withAnimation(.easeIn(duration: 0.18)) { textIn = false }
            withAnimation(.timingCurve(0.5, 0, 0.2, 1, duration: LevelUp.flight)) { flying = true }
            withAnimation(.easeInOut(duration: LevelUp.flight - 0.04)) { frost = 0 }   // ใสหมดพอดีตอนตราลง
        }
    }
}
