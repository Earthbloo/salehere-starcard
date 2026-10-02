import SwiftUI
import PhosphorSwift

/// หน้าเดียวกัน 2 โหมด (= `starPage()` ใน newflow.js)
/// - `.reveal` = การ์ดเพิ่งเกิด: ตรา + "คุณเป็น STAR แล้ว" + ปุ่มต่อไปฟอร์มสมัคร (motion ยาวครั้งแรกครั้งเดียว)
/// - `.profile` = Star Profile ถาวรจากปุ่ม "โปรไฟล์ครีเอเตอร์": หัวข้อ "Star Profile" + ปุ่มแชร์
///
/// พื้นสว่าง + แสงเบลอ champagne + การ์ดกระจกขอบเหลืองนิดๆ ใบเดียว + รายการ "เติมการ์ดให้เต็ม" เป็นกระจก
struct StarPage: View {
    enum Mode { case reveal, profile }

    @Environment(StarFlow.self) private var flow
    let mode: Mode
    let campaign: StarCampaign
    let onClose: () -> Void
    /// reveal: ต่อไปฟอร์มสมัคร
    var onNext: () -> Void = {}
    /// เปิด wizard เฉพาะข้อที่ส่งมา (kind one) แล้วกลับมาหน้านี้
    let onFill: ([WizStep]) -> Void
    let onKyc: () -> Void
    var onShare: () -> Void = {}
    /// profile: เปิดพื้นที่ Star Card เดิม (คลัง/ห้องแต่ง)
    var onOpenStarCard: (StarCardIntent) -> Void = { _ in }
    /// หัว (title + toggle) และพื้น/ดวงไฟ ถูกวาดโดย shell (`StarHeader` + `StarGround`) — หน้านี้เว้นที่ไว้ให้เฉย ๆ
    var hosted = false

    /// toggle ข้อมูล | การ์ด (แบบ G2) — หน้าเดียว สองมุมมองของของเดียวกัน
    enum Pane { case data, card }
    @State private var pane: Pane = .data

    private var quiet: Bool { mode == .profile || flow.revealSeen }
    /// คลังการ์ด — Star Profile โชว์ใบที่กำลังแสดงอยู่เป็นพระเอก (Star Card = Star Profile ที่เป็นภาพ)
    @State private var library = CardLibrary.shared
    /// ใบที่กำลังแสดงอยู่ = หน้าตาของ Star Profile (ผู้ใช้ 24 ก.ย. 2569 เลิก toggle ข้อมูล | การ์ด)
    /// ยังไม่มีใบในคลัง = การ์ดกระจกสรุปไปก่อน + ปุ่มเลือกแบบการ์ด
    /// ยังไม่มีใบในคลัง = โชว์การ์ดตั้งต้นที่ทุกคนมี (ผู้ใช้ 29 ก.ย. 2569: "ต้องมีหลอกล่อให้เข้าไปดู")
    private var liveCard: CardRecord? { mode == .profile ? (library.displayOrder.first ?? CardLibrary.defaultPreview) : nil }
    @Environment(PhotoStore.self) private var photos
    @State private var wordsIn = false
    @State private var cardIn = false
    @State private var rowsIn = false
    @State private var barPct: Double = 0
    /// แถว "เติมการ์ดให้เต็ม" กางรายการเต็มลงมาอยู่ไหม — เริ่มพับไว้
    @State private var listOpen = false
    /// ฉลองครบครั้งเดียว (ไม่ใช่ทุกครั้งที่เปิดหน้า) — ข้อมูลกลับมาขาดแล้วครบใหม่ก็ฉลองใหม่
    @AppStorage("starflow.fullCheered") private var cheered = false
    @State private var cheer = false
    @State private var burst = false

    /// หน้าการ์ดเกิดอยู่ใน flow Unbox — ไม่ชวนเติมข้อที่ถามแค่ใน Star Profile (งานที่ขอผ่าน · ศาสนา)
    /// ยืนยันตัวตนไม่อยู่ในรายการ — เป็นดาวข้างชื่อบนการ์ดแทน (ผู้ใช้ 29 ก.ย. 2569)
    private var rows: [StarRow] {
        StarRow.all.filter { $0.key != nil && (mode == .profile || !StarFlow.profileOnlyKeys.contains($0.key)) }
    }
    private var todo: [StarRow] { rows.filter { !flow.done($0) } }
    private var done: [StarRow] { rows.filter { flow.done($0) } }
    /// ปุ่มล่างยังพาเติมทุกข้อ (เส้นทางจาก Star Profile ถามครบทุกช่อง — ผู้ใช้ 24 ก.ย.)
    private var left: Int { todo.count }
    /// ความครบของรายการที่หน้านี้แสดง (หน้าการ์ดเกิดไม่นับข้อที่ถามแค่ใน Star Profile)
    private var pct: Double { rows.isEmpty ? 0 : Double(done.count) / Double(rows.count) }


    var body: some View {
        ZStack(alignment: .top) {
            GlassOrbs(bloom: mode == .reveal && !quiet, ground: !hosted)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    head
                    if mode == .profile && pane == .card {
                        // มุมมอง "การ์ด" = คลังการ์ดเดิม ฝังบนพื้นสว่างเดียวกัน (สำรับ · ชื่อ · ลิงก์ · แต่ง/แชร์/ใช้ใบนี้)
                        CardGallery(onCreate: { onOpenStarCard(.create) },
                                    onOpen: { onOpenStarCard(.edit($0.id)) },
                                    onPreview: { onOpenStarCard(.preview($0.id)) },
                                    embedded: true)
                            .environment(photos)
                            .frame(height: 540)
                            .padding(.horizontal, -16)
                            .padding(.top, 8)
                            .transition(.opacity)
                        cardMissing.padding(.top, 8)
                            .transition(.opacity)
                    } else {
                        Group {
                            // ข้อมูลเป็นพระเอกของหน้านี้ — การ์ดจริงเป็นแถวเล็กใต้ข้อมูล ให้รู้ว่ามีและแตะเข้าไปได้
                            // (ผู้ใช้ 24 ก.ย. 2569: การ์ดใหญ่บนสุด "โครตแปลก · หน้านี้เน้นให้กรอกข้อมูล ข้อมูลหายไปหมด")
                            VStack(spacing: 12) {
                                // แตะรูปโปรไฟล์ = ไปหน้า "รูปและผลงาน" (audit: Profile photo)
                                // หมวดสุดท้ายของการ์ดข้อมูล = Star Card ใบที่เผยแพร่อยู่ · แตะ = หน้า Star Card ของฉัน (แต่ง/แชร์)
                                StarGlassCard(onAvatar: mode == .profile && flow.hasCard ? { onFill([.media]) } : nil,
                                              onVerify: onKyc,
                                              liveCard: liveCard, cardIsDefault: library.records.isEmpty, cardCount: library.records.count,
                                              onOpenCard: { onOpenStarCard(.gallery) })
                                if liveCard == nil && mode == .profile && flow.hasCard {
                                    GlassActionButton(title: "เลือกแบบการ์ด", symbol: .sparkle) { onOpenStarCard(.create) }
                                }
                            }
                        }
                            .padding(.top, 24)
                            .opacity(cardIn ? 1 : 0)
                            .rotation3DEffect(.degrees(cardIn ? 0 : 28), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
                            .offset(y: cardIn ? 0 : 90)
                            .scaleEffect(cardIn ? 1 : 0.96)
                        // รายการ 13 แถวพับเก็บในแถวเดียว (แบบ F, ผู้ใช้ 29 ก.ย. 2569: "มันแอบท้อ" / "ยังดูเยอะทุกแบบ")
                        // แตะแถว = กางรายการลงมาในการ์ดใบเดียวกัน (dropdown) — แก้ข้อที่กรอกแล้วจากรายการนี้
                        // มีการ์ดแล้วหรือยังก็หน้าตาเดียวกัน ("ตอนยังทำไม่ครบทำไมไม่เป็นแบบเดียวกัน")
                        fillRow
                            .padding(.top, 20)
                            .opacity(rowsIn ? 1 : 0).offset(y: rowsIn ? 0 : 18)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, mode == .profile ? 58 : 66)
                .padding(.bottom, 170)
            }
            if hosted {
                // แผ่นไล่สีรองหัวร่วมของ shell — เนื้อหาที่เลื่อนขึ้นมาจางหายใต้หัว ไม่ทับตัวหนังสือ (audit ข้อ 1)
                // อยู่เหนือรายการ แต่ใต้ปุ่มย้อนกลับ
                VStack(spacing: 0) {
                    // ทึบจนถึงใต้หัว (safe top ≈ 59 + หัว 50…114) แล้วค่อยจาง — ครอบแถบสถานะด้วย
                    LinearGradient(stops: [.init(color: GL.bg, location: 0), .init(color: GL.bg, location: 0.8), .init(color: GL.bg.opacity(0), location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 228)
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
            }
            HStack {
                GlassCircleButton(symbol: mode == .profile ? .caretLeft : .x, action: onClose)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 8)
        }
        // ปุ่มล่างมีทุกสถานะ (ผู้ใช้ 30 ก.ย. 2569: "ต้องมี Bottom Button ให้กด เพื่อทำตอบ") — ยังไม่มีการ์ด = "สมัครเป็น STAR" ·
        // มีการ์ดแต่ยังไม่ครบ = "เติมข้อมูลต่อ" · ครบแล้ว = "ดูการ์ดของฉัน"  ปุ่มเดียวต่อสถานะ (audit 29 ก.ย. 2569) จึงเอาปุ่ม "เติมต่อ" ในแถว % ออก
        .overlay(alignment: .bottom) { foot }
        .animation(Motion.settle, value: pane)
        .background(hosted ? Color.clear.ignoresSafeArea() : GL.bg.ignoresSafeArea())
        .preferredColorScheme(.light)
        .onAppear { enter(); cheerIfFull() }
        .onChange(of: flow.pct) { _, _ in
            withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.9).delay(0.25)) { barPct = pct }
            cheerIfFull()
        }
    }

    private func enter() {
        if quiet {
            wordsIn = true; cardIn = true; rowsIn = true; barPct = pct
            return
        }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 1.1).delay(0.95)) { wordsIn = true }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 1.5).delay(0.7)) { cardIn = true }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.9).delay(2.6)) { rowsIn = true }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.9).delay(2.7)) { barPct = pct }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { flow.revealSeen = true }
    }

    // MARK: หัว

    @ViewBuilder
    private var head: some View {
        switch mode {
        case .profile:
            VStack(alignment: .leading, spacing: 0) {
                if flow.hasCard {
                    if hosted {
                        // ที่ว่างเท่าหัวร่วมของ shell (`StarHeader` สูง 64)
                        Color.clear.frame(height: 64)
                    } else {
                        GlassTitle(words: [("Star", false), ("Profile", true)])
                    }
                    GlassChip(icon: .eye, text: "แบรนด์ใช้ข้อมูลนี้ตอนคัดคน").padding(.top, 12)
                } else {
                    // ยังไม่มีการ์ด: หัว "สมัครเป็น STAR" อยู่ที่ shell เหมือนกัน (ไม่งั้นแผ่นรองหัวทับหัวที่อยู่ในรายการ)
                    if hosted { Color.clear.frame(height: 64) }
                    else { GlassTitle(words: [("สมัครเป็น", false), ("STAR", true)], small: true) }
                    // ไม่นับจำนวนตรงนี้ — ตัวเลขบนหน้ามีแค่วงแหวน % (audit 29 ก.ย. 2569: ป้าย 12 · ปุ่ม 11 · รายการ 13 นับคนละชุด)
                    GlassChip(icon: .eye, text: "แบรนด์ใช้ข้อมูลนี้ตอนคัดคน").padding(.top, 12)
                }
            }
        case .reveal:
            // ตราและหัวข้ออยู่กลางจอเหมือนเว็บ (.ach2-seal + .glass-title กลาง) — ไม่ชิดซ้าย
            VStack(alignment: .center, spacing: 14) {
                RevealSeal(animated: !quiet)
                HStack(alignment: .lastTextBaseline, spacing: 7) {
                    if flow.isStar {
                        word("คุณเป็น", serif: false, delay: 0)
                        word("STAR", serif: true, delay: 0.17)
                        word("แล้ว", serif: false, delay: 0.34)
                    } else {
                        word("การ์ดของคุณ", serif: false, delay: 0)
                        word("พร้อมแล้ว", serif: true, delay: 0.17)
                    }
                }
                .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// คำขึ้นทีละคำ (blur → คม) (= `.reveal-words`)
    private func word(_ t: String, serif: Bool, delay: Double) -> some View {
        Group {
            if t == "STAR" {
                // คำ STAR = ตรา ST★R (ผู้ใช้ 30 ก.ย. 2569) สูงเท่าคำหนาข้าง ๆ
                StarCaps(height: StarCaps.height(forEmphasis: 30))
            } else if serif {
                Text(t).font(GL.serif(40))
                    .foregroundStyle(LinearGradient(colors: [GL.ink, GL.ink, GL.goldInk], startPoint: .top, endPoint: .bottom))
            } else {
                Text(t).font(.sh(30, .heavy)).tracking(-0.8).foregroundStyle(GL.ink)
            }
        }
        .opacity(wordsIn ? 1 : 0)
        .blur(radius: wordsIn ? 0 : 8)
        .offset(y: wordsIn ? 0 : 10)
        .animation(quiet ? nil : .timingCurve(0.16, 1, 0.3, 1, duration: 1.1).delay(0.95 + delay), value: wordsIn)
    }

    // MARK: toggle ข้อมูล | การ์ด (แบบ G2 23 ก.ย. 2569) — เลิกใช้ 24 ก.ย. เก็บโค้ดไว้เผื่อย้อน

    private var paneToggle: some View {
        HStack(spacing: 2) {
            paneChip("ข้อมูล", .data)
            paneChip("การ์ด", .card, dot: true)
        }
        .padding(3)
        .glassEffect(.regular.tint(.white.opacity(0.6)), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.95), lineWidth: 1))
        .shadow(color: GL.ink.opacity(0.07), radius: 8, y: 4)
    }

    private func paneChip(_ title: String, _ p: Pane, dot: Bool = false) -> some View {
        let on = pane == p
        return Button {
            guard pane != p else { return }
            Haptics.impact(.light)
            // "การ์ด" = ไปหน้า Star Card เดิม (คลังการ์ดเต็มจอ) — ผู้ใช้ 23 ก.ย.: "ต้องเปลี่ยนไปหน้าเดิม แค่เพิ่ม toggle"
            if p == .card { onOpenStarCard(.gallery) } else { withAnimation(Motion.settle) { pane = p } }
        } label: {
            HStack(spacing: 5) {
                Text(title).font(.sh(13, .bold))
                if dot && !on && !library.records.isEmpty {
                    // จุดเขียว = มีใบที่กำลังแสดงอยู่ (ป้ายเดียวกับในคลัง)
                    Circle().fill(GL.green).frame(width: 6, height: 6)
                }
            }
            .foregroundStyle(on ? .white : GL.ink)
            .padding(.horizontal, 13).frame(height: 32)
            .background(Capsule().fill(on ? GL.ink : .clear))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// ข้อที่ขาดและจะไปขึ้นบนการ์ดจริง ๆ — บัญชี/รอบแก้/ที่อยู่ ไม่ขึ้นการ์ด อยู่ที่มุมมอง "ข้อมูล" เท่านั้น
    private var todoOnCard: [StarRow] { todo.filter { ![.bank, .draftRounds, .address].contains($0.key) && !StarFlow.profileOnlyKeys.contains($0.key) } }

    /// ใต้สำรับในมุมมองการ์ด: ข้อที่ยังขาด "บนการ์ด" (แบบ F) — บอกว่ากรอกแล้วขึ้นตรงไหน
    private var cardMissing: some View {
        let list = todoOnCard
        return VStack(alignment: .leading, spacing: 10) {
            if !list.isEmpty {
                HStack(alignment: .lastTextBaseline) {
                    Text("ยังขาดบนการ์ด").font(.sh(18, .bold)).foregroundStyle(GL.ink)
                    Spacer()
                    Text("\(list.count)").font(.sh(15, .heavy)).foregroundStyle(GL.ink).monospacedDigit()
                }
                ForEach(list) { r in row(r) }
            } else {
                HStack(spacing: 8) {
                    PIcon(.check, size: 12).foregroundStyle(.white).frame(width: 24, height: 24).background(Circle().fill(GL.green))
                    Text("ข้อมูลครบทุกอย่างบนการ์ดแล้ว").font(.sh(14.5, .bold)).foregroundStyle(GL.ink)
                }
            }
        }
    }

    // MARK: แถวเดียว "เติมข้อมูลให้ครบ" (แบบ F) — วงแหวน % · เวลาที่เหลือ · ปุ่มเติมต่อ

    private var fillRow: some View {
        VStack(spacing: 0) {
            fillHeader.padding(14)
            if listOpen {
                // รายการอยู่ในการ์ดใบเดียวกับหัว (ผู้ใช้ 29 ก.ย. 2569: "มันต้องเป็นส่วนนึงของการ์ดบน") — ข้อที่ขาดก่อน แล้วข้อที่ครบ
                VStack(spacing: 0) {
                    ForEach(todo + done) { r in
                        GL.ink.opacity(0.06).frame(height: 1).padding(.leading, 14)
                        innerRow(r)
                    }
                }
                .transition(.opacity)
            }
        }
        .background(PK.shape(22).fill(.white))
        .overlay(PK.shape(22).strokeBorder(GL.ink.opacity(0.06), lineWidth: 1))
        .clipShape(PK.shape(22))
        .shadow(color: GL.ink.opacity(0.07), radius: 15, y: 12)
    }

    /// หัวของการ์ดข้อมูล: วงแหวน % · สถานะ · ⌄ · ปุ่มเติมต่อ — เป็นเรื่องข้อมูล ไม่ใช่การ์ด (ผู้ใช้ 29 ก.ย. 2569: "การ์ดเต็มแล้ว มันไม่ถูก มันคือข้อมูล")
    private var fillHeader: some View {
        let full = left == 0
        return HStack(spacing: 12) {
            Button {
                Haptics.impact(.light)
                withAnimation(Motion.settle) { listOpen.toggle() }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().stroke(GL.ink.opacity(0.08), lineWidth: 4)
                        // 0% = วงว่างจริง ๆ (เดิม max 0.02 เหลือจุดดำค้างที่ดูเหมือนภาพเพี้ยน)
                        Circle().trim(from: 0, to: barPct)
                            .stroke(full ? GL.green : GL.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .opacity(barPct > 0.001 ? 1 : 0)
                        // ครบแล้ว: วงเขียวกระจายออก + ติ๊ก
                        Circle().stroke(GL.green, lineWidth: 3)
                            .scaleEffect(burst ? 1.9 : 1).opacity(burst ? 0 : (cheer ? 0.7 : 0))
                        if full {
                            PIcon(.check, size: 18, weight: .bold).foregroundStyle(GL.greenInk)
                        } else {
                            Text("\(Int((pct * 100).rounded()))%").font(.sh(12, .heavy)).foregroundStyle(GL.ink).monospacedDigit()
                        }
                    }
                    .frame(width: 42, height: 42)
                    .scaleEffect(cheer ? 1.14 : 1)
                    // ไม่บอกเวลา "อีกกี่นาที" (ผู้ใช้ 29 ก.ย. 2569) — วงแหวน % บอกความคืบหน้าพอแล้ว
                    VStack(alignment: .leading, spacing: 1) {
                        // ยังไม่มีการ์ด = หน้าสมัคร → แถวพูดเรื่องสมัคร ไม่ใช่ "เติมให้ครบ" (critique 29 ก.ย. 2569)
                        Text(full ? "ข้อมูลครบแล้ว" : flow.hasCard ? "เติมข้อมูลให้ครบ" : "ข้อมูลสำหรับสมัคร").font(.sh(16, .bold)).foregroundStyle(GL.ink)
                        if full { Text(cheer ? "แบรนด์เห็นข้อมูลคุณครบแล้ว" : "แตะเพื่อดู/แก้ข้อมูล").font(.sh(13)).foregroundStyle(cheer ? GL.greenInk : GL.hint) }
                    }
                    Spacer(minLength: 4)
                    PIcon(.caretDown, size: 14, weight: .bold).foregroundStyle(GL.hint)
                        .rotationEffect(.degrees(listOpen ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // ปุ่มไปตอบต่ออยู่ล่างจอ (`foot`) ไม่ซ้อนในแถวนี้ — แถวนี้มีหน้าที่บอก % และกางรายการ
        }
    }

    /// ครบทุกข้อครั้งแรก = ฉลองสั้น ๆ: วงแหวนเด้ง + วงเขียวกระจาย + สั่น success (checklist "Completion celebration")
    private func cheerIfFull() {
        guard left == 0 else { cheered = false; return }
        guard !cheered else { return }
        cheered = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) { cheer = true }
            withAnimation(.easeOut(duration: 0.9)) { burst = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { cheer = false }
                burst = false
            }
        }
    }

    /// แถวข้อมูลในการ์ด (dropdown) — แบน ไม่มีกรอบ/เงาของตัวเอง คั่นด้วยเส้นบาง · แตะแล้วทำแบบเดียวกับ `row`
    private func innerRow(_ r: StarRow) -> some View {
        let ok = flow.done(r)
        return Button {
            Haptics.impact(.light)
            if ok {
                if let s = r.key.flatMap({ WizStep(rawValue: $0.rawValue) }) { onFill([s]) }
            } else {
                onFill(missingSteps(from: r))
            }
        } label: {
            HStack(spacing: 12) {
                PIcon(r.icon, size: 16, weight: ok ? .fill : .bold)
                    .foregroundStyle(ok ? GL.ink : GL.hint)
                    .frame(width: 36, height: 36)
                    .background(PK.shape(11).fill(ok ? PK.fieldFill : .clear))
                    .overlay(PK.shape(11).strokeBorder(ok ? .clear : Color(red: 201 / 255, green: 204 / 255, blue: 210 / 255), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                VStack(alignment: .leading, spacing: 2) {
                    // ป้าย "แบรนด์ไม่เห็น" บนข้อส่วนตัวเอาออก (ผู้ใช้ 29 ก.ย. 2569: "เอาออกไป")
                    Text(r.title).font(.sh(15, .bold)).foregroundStyle(GL.ink)
                    if ok {
                        PKFactStrip(facts: flow.facts(r))
                    } else {
                        Text(r.why).font(.sh(12.5)).foregroundStyle(Color(red: 122 / 255, green: 127 / 255, blue: 136 / 255)).lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                if ok {
                    PIcon(.check, size: 11).foregroundStyle(.white).frame(width: 22, height: 22).background(Circle().fill(GL.green))
                } else {
                    HStack(spacing: 3) { PIcon(.plus, size: 12); Text("เพิ่ม").font(.sh(12.5, .bold)) }
                        .foregroundStyle(.white).padding(.leading, 9).padding(.trailing, 11).frame(height: 30)
                        .background(Capsule().fill(GL.ink))
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func row(_ r: StarRow) -> some View {
        let ok = flow.done(r)
        return Button {
            Haptics.impact(.light)
            if ok {
                // ข้อที่ครบแล้ว = แก้ข้อนั้นข้อเดียว
                if let s = r.key.flatMap({ WizStep(rawValue: $0.rawValue) }) { onFill([s]) }
            } else {
                // ข้อที่ยังขาด = เริ่มที่ข้อนี้แล้วกดถัดไปต่อจนครบทุกข้อ ไม่ต้องเข้าออกทีละข้อ (ผู้ใช้ 24 ก.ย. 2569)
                onFill(missingSteps(from: r))
            }
        } label: {
            HStack(spacing: 12) {
                PIcon(r.icon, size: 18, weight: ok ? .fill : .bold)
                    .foregroundStyle(ok ? GL.ink : GL.hint)
                    .frame(width: 42, height: 42)
                    .background(PK.shape(14).fill(ok ? PK.fieldFill : .clear))
                    .overlay(PK.shape(14).strokeBorder(ok ? .clear : Color(red: 201 / 255, green: 204 / 255, blue: 210 / 255), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.title).font(.sh(16, .bold)).foregroundStyle(GL.ink)
                    if ok {
                        PKFactStrip(facts: flow.facts(r))
                    } else {
                        Text(pane == .card ? r.onCard : r.why).font(.sh(13)).foregroundStyle(Color(red: 122 / 255, green: 127 / 255, blue: 136 / 255)).lineLimit(2)
                    }
                }
                Spacer(minLength: 8)
                if ok {
                    PIcon(.check, size: 12).foregroundStyle(.white).frame(width: 24, height: 24).background(Circle().fill(GL.green))
                } else {
                    HStack(spacing: 4) { PIcon(.plus, size: 13); Text("เพิ่ม").font(.sh(13, .bold)) }
                        .foregroundStyle(.white).padding(.leading, 10).padding(.trailing, 13).frame(height: 34)
                        .background(Capsule().fill(GL.ink))
                        .shadow(color: GL.ink.opacity(0.25), radius: 7, y: 6)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12).frame(minHeight: 66)
            .background(PK.shape(20).fill(ok ? .white.opacity(0.92) : .clear))
            .overlay(PK.shape(20).strokeBorder(ok ? .white : Color(red: 184 / 255, green: 187 / 255, blue: 194 / 255), style: StrokeStyle(lineWidth: ok ? 1 : 1.5, dash: ok ? [] : [5, 4])))
            .shadow(color: GL.ink.opacity(ok ? 0.07 : 0), radius: 11, y: 8)
            .contentShape(PK.shape(20))
        }
        .buttonStyle(PKRowPress())
    }

    /// ข้อที่ยังขาดทั้งหมดเป็นขั้นต่อกันตามลำดับรายการ — เริ่มที่ข้อที่แตะ ไล่ต่อจนสุด แล้ววนกลับมาข้อก่อนหน้า
    private func missingSteps(from start: StarRow?) -> [WizStep] {
        let step: (StarRow) -> WizStep? = { r in r.key.flatMap { WizStep(rawValue: $0.rawValue) } }
        let all = todo.compactMap(step)
        guard let start, let first = step(start), let i = all.firstIndex(of: first) else { return all }
        return Array(all[i...] + all[..<i])
    }

    // MARK: ปุ่มล่าง (= `.ach2-foot`)

    private var foot: some View {
        VStack(spacing: 14) {
            switch mode {
            case .reveal:
                GlassPrimaryButton(title: "ต่อ: ฟอร์มสมัคร \(campaign.episode)", action: onNext)
                GlassLink(title: "แชร์การ์ดก่อน", action: onShare)
            case .profile:
                if !flow.hasCard {
                    // รอบแรกกรอกให้ครบทุกข้อในรอบเดียว ไม่กลับมาหน้านี้ระหว่างทาง (ผู้ใช้ 24 ก.ย. 2569)
                    // ไม่ใส่จำนวนข้อ — ตัวเลขบนหน้ามีแค่วงแหวน % (จำนวนขั้นสมัครนับคนละชุดกับรายการ)
                    GlassPrimaryButton(title: "สมัครเป็น STAR", symbol: .arrowRight) { onFill(flow.applySteps) }
                } else if left > 0 {
                    // ไม่ใส่จำนวนข้อ — ตัวเลขบนหน้ามีแค่วงแหวน % (เหตุผลเดียวกับปุ่มสมัคร)
                    GlassPrimaryButton(title: "เติมข้อมูลต่อ") {
                        onFill(missingSteps(from: nil))
                    }
                } else {
                    // ข้อมูลครบ — แชร์อยู่ในหน้าการ์ด ปุ่มล่างพาเข้าไปแทนการแชร์จากตรงนี้
                    GlassPrimaryButton(title: "ดูการ์ดของฉัน", symbol: .arrowUpRight) { onOpenStarCard(.gallery) }
                }
            }
        }
        .padding(.horizontal, 22).padding(.top, 34).padding(.bottom, 26)
        .background(
            LinearGradient(stops: [.init(color: GL.bg.opacity(0), location: 0), .init(color: GL.bg.opacity(0.96), location: 0.38), .init(color: GL.bg, location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        )
    }
}

/// ตราวงแหวนทอง + ดาว วาดตัวเองตอนเข้าหน้า (= `.ach2-seal`)
struct RevealSeal: View {
    let animated: Bool
    @State private var drawn = false
    @State private var glow = false
    private var gold: LinearGradient {
        LinearGradient(colors: [Color(red: 232 / 255, green: 199 / 255, blue: 102 / 255), GL.gold, Color(red: 138 / 255, green: 106 / 255, blue: 26 / 255)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Color(red: 1, green: 210 / 255, blue: 90 / 255).opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: 56))
                .frame(width: 112, height: 112).blur(radius: 6)
                .opacity(glow ? 0.35 : 0).scaleEffect(glow ? 1.15 : 0.6)
            Circle().trim(from: 0, to: drawn ? 1 : 0).stroke(gold, lineWidth: 1.2).frame(width: 68, height: 68).rotationEffect(.degrees(-90))
            Circle().trim(from: 0, to: drawn ? 1 : 0).stroke(gold, lineWidth: 0.6).opacity(0.6).frame(width: 59, height: 59).rotationEffect(.degrees(-90))
            PIcon(.star, size: 30, weight: .fill).foregroundStyle(gold)
                .opacity(drawn ? 1 : 0).scaleEffect(drawn ? 1 : 0.6)
        }
        .frame(width: 76, height: 76)
        .onAppear {
            if !animated { drawn = true; glow = true; return }
            withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 1.4).delay(0.5)) { drawn = true }
            withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 2.2).delay(0.75)) { glow = true }
        }
    }
}


/// Star Card ใบที่กำลังแสดงอยู่ วาดด้วย widget จริง (ของจริงย่อส่วน ไม่ใช่รูปแคป) — แตะเพื่อเข้าห้องแต่ง
///
/// Star Profile กับ Star Card คือเรื่องเดียวกัน: ข้อมูลที่กรอกไว้ข้างล่างหน้านี้คือสิ่งที่การ์ดใบนี้เอาไปวาด
struct StarCardHero: View {
    let record: CardRecord
    let onOpen: () -> Void

    var body: some View {
        let restored = record.restored()
        let theme = restored?.theme ?? CardTheme()
        let pages = restored?.pages ?? []
        let radius: CGFloat = 18
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Button {
            Haptics.impact(.light)
            onOpen()
        } label: {
            VStack(spacing: 10) {
                GeometryReader { g in
                    let w = g.size.width
                    ZStack {
                        shape.fill(LinearGradient(colors: [theme.backdropColors.top, theme.backdropColors.bottom],
                                                  startPoint: .top, endPoint: .bottom))
                        switch record.format {
                        case .portfolio:
                            CardStripPreview(pages: pages, theme: theme, width: w, showsDividers: false,
                                             gutter: CardTemplate.thumbGutter, margin: CardTemplate.thumbGutter,
                                             cornerRadius: radius)
                        case .story:
                            CardFramePreview(page: pages.first ?? CardPage(), theme: theme,
                                             pageSize: CardTemplate.previewPageSize(for: .story),
                                             height: g.size.height, cornerRadius: radius)
                        }
                    }
                    .frame(width: w, height: g.size.height)
                    .clipShape(shape)
                    .overlay(shape.strokeBorder(GL.cardRim.opacity(0.75), lineWidth: 1))
                    .shadow(color: GL.ink.opacity(0.14), radius: 22, y: 16)
                }
                .aspectRatio(heroAspect, contentMode: .fit)
                HStack(spacing: 6) {
                    Circle().fill(GL.green).frame(width: 6, height: 6)
                    Text("กำลังแสดงอยู่ · \(record.name)").font(.sh(12, .semibold)).foregroundStyle(GL.muted).lineLimit(1)
                    Spacer(minLength: 4)
                    Text("แตะเพื่อแต่ง").font(.sh(12, .semibold)).foregroundStyle(GL.hint)
                }
                .padding(.horizontal, 4)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(DockPress())
    }

    private var heroAspect: CGFloat {
        switch record.format {
        case .portfolio:
            let g = CardTemplate.thumbGutter
            let p = CardTemplate.previewPageSize(for: .portfolio)
            return (p.width * 3 + g * 2 + g * 2) / (p.height + g * 2)
        case .story:
            let p = CardTemplate.previewPageSize(for: .story)
            return p.width / p.height
        }
    }
}

/// ปุ่มกระจกสองปุ่มใต้การ์ด (= ปุ่มรองที่เท่ากัน ไม่ใช่ลิงก์)
struct GlassActionButton: View {
    let title: String
    let symbol: Ph
    let action: () -> Void
    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            HStack(spacing: 6) {
                PIcon(symbol, size: 14)
                Text(title).font(.sh(14, .bold))
            }
            .foregroundStyle(GL.ink)
            .frame(maxWidth: .infinity).frame(height: 44)
            .glassEffect(.regular.tint(.white.opacity(0.6)).interactive(), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.95), lineWidth: 1))
            .shadow(color: GL.ink.opacity(0.06), radius: 8, y: 4)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
