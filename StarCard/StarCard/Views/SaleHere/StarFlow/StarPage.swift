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
    /// profile: แถบกราฟใต้ Star Card → หน้า ST★R Insight
    var onInsight: (() -> Void)? = nil
    /// profile: แตะเทมเพลตในแถบตัวอย่าง (ยังไม่เคยเปิดการ์ด) → เริ่มการ์ดใบแรกจากแบบนั้น
    var onPickTemplate: ((CardTemplate) -> Void)? = nil
    /// แถว "ตารางงาน" ใต้การ์ดข้อมูล → หน้าตารางงาน · nil = ไม่มีแถว (ผู้ใช้ 5 ต.ค. 2569)
    var onSchedule: (() -> Void)? = nil
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
    /// แถว "เติมการ์ดให้เต็ม" กางรายการเต็มลงมาอยู่ไหม — เริ่มพับไว้
    /// nil = ยังไม่เคยแตะ: สถานะ C (STAR เก่าที่ยังขาด) กางให้เลย · อื่น ๆ หุบ (= `listOpenChoice ?? needsStarInfo` ของ salehere-ios)
    /// `-shotOpen YES` (แคปจอ) = เปิดมากางรายการแล้ว
    @State private var listOpenChoice: Bool? = UserDefaults.standard.bool(forKey: "shotOpen") ? true : nil
    private var listOpen: Bool { listOpenChoice ?? flow.needsStarInfo }
    /// การ์ด "ใช้ให้แบรนด์คัดเลือก" กาง/หุบ — nil = ยังไม่เคยแตะ: กางเองเมื่อยังขาด (เห็นว่าต้องกรอกอะไร) · ครบแล้วหุบ
    @State private var laterOpen: Bool? = nil
    /// ฉลองครบครั้งเดียว (ไม่ใช่ทุกครั้งที่เปิดหน้า) — ข้อมูลกลับมาขาดแล้วครบใหม่ก็ฉลองใหม่
    @AppStorage("starflow.fullCheered") private var cheered = false
    @State private var cheer = false
    @State private var burst = false

    /// หน้าการ์ดเกิดอยู่ใน flow Unbox — ไม่ชวนเติมข้อที่ถามแค่ใน Star Profile (งานที่ขอผ่าน · ศาสนา)
    /// ยืนยันตัวตนกลับมาเป็นข้อหนึ่งในรายการของ Star Profile และนับใน % (ผู้ใช้ 2 ต.ค. 2569) — ชิปข้างชื่อยังอยู่
    private var rows: [StarRow] {
        // ยืนยันตัวตนอยู่ท้ายรายการ — "เติมข้อมูลต่อ" กรอกข้อมูลก่อน แล้วค่อยออกไปยืนยันตัวตนเป็นข้อสุดท้าย
        let data = StarRow.all.filter { $0.key != nil && (mode == .profile || !StarFlow.profileOnlyKeys.contains($0.key)) }
        return mode == .profile ? data + StarRow.all.filter { $0.key == nil } : data
    }
    private var todo: [StarRow] { rows.filter { !flow.done($0) } }
    private var done: [StarRow] { rows.filter { flow.done($0) } }
    /// ปุ่มล่างยังพาเติมทุกข้อ (เส้นทางจาก Star Profile ถามครบทุกช่อง — ผู้ใช้ 24 ก.ย.)
    private var left: Int { todo.count }
    private var full: Bool { left == 0 }
    /// % ทางไปเป็น STAR (8 ข้อ + ยืนยันตัวตน) — มีเฉพาะก่อนเป็น STAR: วงแหวนหัว "ข้อมูลสมัคร STAR" + ปุ่ม "สมัครเป็น STAR" เลขเดียวกัน
    /// ผู้ใช้ 7 ต.ค. 2569: "Percent ไม่ต้องนับคำถามที่แบรนด์ใช้คัดเลือก นับแค่ตอนกรอก Star ว่าอีกกี่ Percent ได้เป็น Star" · หลังเป็น STAR ไม่มี %
    private var starPct: Double { flow.starPct }
    /// 8 ข้อที่แบรนด์ใช้คัดเลือก (= หน้าของ `StarFlow.starSteps` ไม่นับข้อไม่บังคับ) + ยืนยันตัวตน — ด่านเดียวที่ต้องผ่านก่อนเป็น STAR
    /// ผู้ใช้ 6 ต.ค. 2569: ก่อนเป็น STAR โชว์แค่ชุดนี้ ไม่มี % · หลังเป็น STAR ยุบเป็นบรรทัด "ครบแล้ว" แล้วแยกกลุ่ม "เติมเมื่อถึงเวลา"
    private static let starKeys: Set<StarDataKey> = Set(StarFlow.starSteps.flatMap(\.keys)).subtracting(StarFlow.optionalKeys)
    private var starRows: [StarRow] { rows.filter { $0.key.map { Self.starKeys.contains($0) } ?? true } }
    /// ข้อที่ไม่ใช่ด่าน (ที่อยู่ · บัญชี · สัดส่วน · แนะนำตัว · ข้อมูลผู้ติดตาม) — ไม่กรอกก็ไม่เสียอะไร แถวบอกเองว่าใช้ตอนไหน
    private var extraRows: [StarRow] { rows.filter { $0.key.map { !Self.starKeys.contains($0) } ?? false } }
    private var starLeft: Int { starRows.filter { !flow.done($0) }.count }
    /// ขั้น wizard ของแถว — แถวยืนยันตัวตน (key nil) = ขั้น `.kyc`
    private func step(_ r: StarRow) -> WizStep? { r.key.map { WizStep(rawValue: $0.rawValue) } ?? .kyc }


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
                                StarGlassCard(onAvatar: mode == .profile && flow.isStar ? { onFill([.media]) } : nil,
                                              onVerify: onKyc,
                                              liveCard: liveCard, cardIsDefault: library.records.isEmpty, cardCount: library.records.count,
                                              onOpenCard: { onOpenStarCard(.gallery) },
                                              onInsight: mode == .profile ? onInsight : nil,
                                              onPickTemplate: mode == .profile ? onPickTemplate : nil,
                                              footer: AnyView(fillSection))
                                if liveCard == nil && mode == .profile && flow.isStar {
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
                        // แถว % ข้อมูลอยู่ใต้การ์ด (ใต้หมวด ST★R Card) ทันที แล้วค่อยเป็นตารางงาน (feedback 5 ต.ค. 2569:
                        // "% ข้อมูลที่เหลือมันต้องอยู่ใต้ Star Card") — เดิมแถวตารางงานคั่นอยู่ตรงกลาง
                        // แถว % รวมเข้าไปเป็นหมวดท้ายของการ์ดกระจกแล้ว (`fillSection` → `StarGlassCard.footer`) — ผู้ใช้ 5 ต.ค. 2569: "มันยังไม่รวมอะใน ios"
                        if mode == .profile, let onSchedule {
                            ScheduleEntryRow(onOpen: onSchedule)
                                .padding(.top, 16)
                                .opacity(rowsIn ? 1 : 0).offset(y: rowsIn ? 0 : 18)
                        }
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
            // หน้า "คุณเป็น STAR แล้ว" ไม่มีปุ่มปิด — ไปต่อทางปุ่มล่างอย่างเดียว (salehere-ios `WzRevealPage`)
            if mode == .profile {
                HStack {
                    GlassCircleButton(symbol: .caretLeft, action: onClose)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 8)
            }
        }
        // ปุ่มล่างมีทุกสถานะ (ผู้ใช้ 30 ก.ย. 2569: "ต้องมี Bottom Button ให้กด เพื่อทำตอบ") — ยังไม่มีการ์ด = "สมัครเป็น STAR" ·
        // มีการ์ดแต่ยังไม่ครบ = "เติมข้อมูลต่อ" · ครบแล้ว = "ดูการ์ดของฉัน"  ปุ่มเดียวต่อสถานะ (audit 29 ก.ย. 2569) จึงเอาปุ่ม "เติมต่อ" ในแถว % ออก
        .overlay(alignment: .bottom) { foot }
        .animation(Motion.settle, value: pane)
        .background(hosted ? Color.clear.ignoresSafeArea() : GL.bg.ignoresSafeArea())
        .preferredColorScheme(.light)
        .onAppear { enter(); cheerIfFull() }
        .onChange(of: flow.pct) { _, _ in cheerIfFull() }
    }

    private func enter() {
        if quiet {
            wordsIn = true; cardIn = true; rowsIn = true
            return
        }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 1.1).delay(0.95)) { wordsIn = true }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 1.5).delay(0.7)) { cardIn = true }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.9).delay(2.6)) { rowsIn = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { flow.revealSeen = true }
    }

    // MARK: หัว

    @ViewBuilder
    private var head: some View {
        switch mode {
        case .profile:
            VStack(alignment: .leading, spacing: 0) {
                // หัว "Star Profile" ต่อเมื่อเป็น STAR (ครบ 8 ข้อ) — ก่อนนั้นเป็น "สมัครเป็น STAR" เสมอ (ผู้ใช้ 6 ต.ค. 2569)
                if flow.isStar {
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

    // MARK: หมวดข้อมูลท้ายการ์ด — ผู้ใช้ 6 ต.ค. 2569 (รอบ 3, canvas 2sCTvdiCfUcVAp5i7RYyqD แบบ A):
    // เป็น STAR แล้ว = กล่องทอง "ข้อมูล STAR ครบแล้ว" กดลูกศรกาง 8 ข้อ "ในกล่อง" (แถวขาว) · ข้างล่าง "เติมเมื่อถึงเวลา" = แถวเส้นประ ปุ่ม "เพิ่ม" ขอบขาว
    // (เดิมสองส่วนเป็นแถวขาว + ปุ่มดำเหมือนกัน ผู้ใช้: "ไม่ชัดว่า 2 ส่วนต่างกันยังไง" · กล่องเขียวที่มีชิป 8 ข้อก็ "เป็น list เหมือนกัน" · "ไม่ต้องเขียวตลอด เอาสี STAR")
    // ก่อนเป็น STAR = หัวดาว "ข้อมูลสมัคร STAR · เหลืออีก N ข้อ" กางรายการ 8 ข้อแบบเดิม

    private static let goldBg = Color(red: 1, green: 0.973, blue: 0.882)
    private static let goldLine = Color(red: 0.91, green: 0.824, blue: 0.541)
    private static let goldInk = Color(red: 0.361, green: 0.239, blue: 0.02)
    private static let goldMuted = Color(red: 0.478, green: 0.353, blue: 0.07)
    private static let goldFill = Color(red: 0.878, green: 0.702, blue: 0.227)

    /// หัวเดียวครอบทั้งหมด (ผู้ใช้ 7 ต.ค. 2569: "มันก็คือข้อมูล Star เหมือนกัน ควรอยู่ภายใต้ข้อมูล Star") — ข้างในแบ่งตามสิ่งที่ข้อมูลใช้ทำ:
    /// "ใช้สมัครเป็น STAR" (8 ข้อ · ทอง หุบไว้เมื่อครบ) + "ใช้ให้แบรนด์คัดเลือก" (หลังเป็น STAR · ข้อที่ขาดเห็นเสมอ)
    private var fillSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ข้อมูล STAR ของคุณ").font(.sh(17, .heavy)).foregroundStyle(GL.ink)
                .padding(.horizontal, 4).padding(.bottom, 10)
            if flow.isStar {
                starBlock
                if mode == .profile, !extraRows.isEmpty { laterSection.padding(.top, 10) }
            } else {
                fillHeader.padding(.vertical, 4)
                if listOpen {
                    // แถวแบบเดียวกับในการ์ดทอง/เทา (`starRow`) — ผู้ใช้ 7 ต.ค. 2569: "ใช้ UI แบบเดียวกัน"
                    let list = starRows.filter { !flow.done($0) } + starRows.filter(flow.done)
                    VStack(spacing: 8) { ForEach(list) { r in starRow(r) } }
                        .padding(.top, 8)
                        .transition(.opacity)
                }
            }
        }
    }

    /// กล่องทอง: ติ๊กทอง + "ข้อมูล STAR ครบแล้ว" + ลูกศรลง · กดแล้ว 8 ข้อกางลงมาในกล่องเดียวกัน (ไม่ปนกับรายการข้างล่าง)
    private var starBlock: some View {
        let list = starRows.filter { !flow.done($0) } + starRows.filter(flow.done)
        return VStack(spacing: 8) {
            Button {
                Haptics.impact(.light)
                withAnimation(Motion.settle) { listOpenChoice = !listOpen }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        // สองหมวดต้องอ่านต่างกันทันที (ผู้ใช้ 7 ต.ค. 2569): ทอง = "ข้อมูล STAR ของคุณ" (ด่าน 8 ข้อ ไม่มีติ๊ก) · ข้างล่าง = "ข้อมูลที่แบรนด์ใช้คัดเลือก"
                        Text("ใช้สมัครเป็น STAR").font(.sh(15, .heavy)).foregroundStyle(Self.goldInk)
                        Text(flow.needsStarInfo ? "ขาด \(flow.starMissing.count) ข้อ · แบรนด์ขอข้อมูลเพิ่ม" : "ครบ 8 ข้อแล้ว")
                            .font(.sh(12.5)).foregroundStyle(Self.goldMuted).lineLimit(2)
                    }
                    Spacer(minLength: 4)
                    ZStack {
                        Circle().fill(.white)
                        Circle().strokeBorder(Self.goldLine, lineWidth: 1)
                        PIcon(.caretDown, size: 14, weight: .bold).foregroundStyle(Self.goldMuted)
                            .rotationEffect(.degrees(listOpen ? 180 : 0))
                    }
                    .frame(width: 30, height: 30)
                }
                .padding(.vertical, 4).padding(.leading, 6).padding(.trailing, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(listOpen ? "ซ่อน 8 ข้อ" : "ดู 8 ข้อ")
            if listOpen {
                VStack(spacing: 8) { ForEach(list) { r in starRow(r) } }
                    .transition(.opacity)
            }
        }
        .padding(10)
        .background(PK.shape(20).fill(Self.goldBg))
        .overlay(PK.shape(20).strokeBorder(Self.goldLine, lineWidth: 1))
    }

    /// แถวในการ์ด (ทอง / เทา) แบบเดียวกันทั้งสองการ์ด (ผู้ใช้ 7 ต.ค. 2569: "การ์ดในหัวข้อใช้สมัครเป็น STAR ใช้ UI แบบเดียวกันได้ไหม")
    /// ยังไม่มี: ไอคอนกรอบประ + บรรทัดรอง (ใช้ตอนไหน / ทำไม / สถานะยืนยันตัวตน) + ปุ่ม "เพิ่ม" ขาว · กรอบแถวเส้นประ
    /// มีแล้ว: ไอคอนทึบพื้นเทา + ชิปค่าที่กรอก + ติ๊กเขียว · แถวขาวขอบบาง · แตะ = แก้ข้อนั้น
    /// ก่อนเป็น STAR ข้อที่ขาด: ไม่มีปุ่ม "เพิ่ม" · แตะไม่ได้ (ไปทางปุ่ม "สมัครเป็น STAR" อย่างเดียว — salehere-ios 7 ต.ค. 2569)
    private func starRow(_ r: StarRow, note: String? = nil) -> some View {
        let ok = flow.done(r), kyc = kycNote(r), canAdd = flow.isStar
        return Button {
            Haptics.impact(.light)
            if ok { if let s = step(r) { onFill([s]) } } else { onFill(flow.missingSteps(from: r)) }
        } label: {
            HStack(spacing: 12) {
                PIcon(r.icon, size: 18, weight: ok ? .fill : .bold)
                    .foregroundStyle(ok ? GL.ink : GL.hint)
                    .frame(width: 36, height: 36)
                    .background(PK.shape(12).fill(ok ? PK.fieldFill : .clear))
                    .overlay(PK.shape(12).strokeBorder(ok ? .clear : Color(red: 201 / 255, green: 204 / 255, blue: 210 / 255), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                VStack(alignment: .leading, spacing: ok ? 3 : 1) {
                    Text(r.title).font(.sh(15, .semibold)).foregroundStyle(GL.ink)
                    if ok { PKFactStrip(facts: flow.facts(r)) }
                    else {
                        Text(note ?? kyc ?? r.why).font(.sh(12.5)).lineLimit(1)
                            .foregroundStyle(kyc == nil || note != nil ? GL.hint : (flow.verify == .rejected ? SH.red : SHColor.orange))
                    }
                }
                Spacer(minLength: 8)
                if ok {
                    PIcon(.check, size: 11, weight: .bold).foregroundStyle(.white).frame(width: 22, height: 22).background(Circle().fill(GL.green))
                } else if canAdd {
                    Text("เพิ่ม").font(.sh(13, .bold)).foregroundStyle(GL.ink)
                        .padding(.horizontal, 14).frame(height: 32)
                        .background(Capsule().fill(.white)).overlay(Capsule().strokeBorder(PK.line2, lineWidth: 1))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(PK.shape(16).fill(ok ? .white : .clear))
            .overlay(PK.shape(16).strokeBorder(ok ? PK.line : PK.line2, style: StrokeStyle(lineWidth: ok ? 1 : 1.5, dash: ok ? [] : [5, 4])))
            .contentShape(PK.shape(16))
        }
        .buttonStyle(PKRowPress())
        // หน้า "คุณเป็น STAR แล้ว" กางดูได้แต่แตะแถวไม่ได้
        .disabled(mode == .reveal || (!ok && !canAdd))
    }

    /// การ์ด "ใช้ให้แบรนด์คัดเลือก" — คู่แฝดของกล่องทอง (ผู้ใช้ 7 ต.ค. 2569: "เป็นอีก Card นึงเหมือนกัน ใช้สมัครเป็น STAR ได้ไหม เปิดปิดได้เหมือนกัน")
    /// หน้าตาเดียวกันทุกอย่าง (หัว + บรรทัดสถานะ + ลูกศรวงกลม · แถวขาวข้างใน) ต่างแค่สีเทา — ทอง = ด่านเป็น STAR · เทา = ข้อมูลที่แบรนด์ใช้คัดเลือก
    /// กางเองเมื่อยังขาด (กติกา "สิ่งที่ต้องทำเห็นเสมอ" — ผู้ใช้: "User จะเข้าใจไหมว่ามีข้อมูลให้กรอกตรงไหนบ้าง") · ครบแล้วหุบ · แตะหัวสลับเองได้
    /// ไม่มี % (นับแค่ทางไปเป็น STAR) · ครบครั้งแรก = ขอบเขียววาบ (`cheerIfFull`)
    private var laterSection: some View {
        let missing = extraRows.filter { !flow.done($0) }, list = missing + extraRows.filter(flow.done)
        let open = laterOpen ?? !missing.isEmpty
        return VStack(spacing: 8) {
            Button {
                Haptics.impact(.light)
                withAnimation(Motion.settle) { laterOpen = !open }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("ใช้ให้แบรนด์คัดเลือก").font(.sh(15, .heavy)).foregroundStyle(GL.ink)
                        Text(missing.isEmpty ? "ครบ \(list.count) ข้อแล้ว" : "ยังขาด \(missing.count) ข้อ")
                            .font(.sh(12.5)).foregroundStyle(missing.isEmpty ? (cheer ? GL.greenInk : GL.muted) : GL.muted).lineLimit(2)
                    }
                    Spacer(minLength: 4)
                    ZStack {
                        Circle().fill(.white)
                        Circle().strokeBorder(PK.line2, lineWidth: 1)
                        PIcon(.caretDown, size: 14, weight: .bold).foregroundStyle(GL.ink)
                            .rotationEffect(.degrees(open ? 180 : 0))
                    }
                    .frame(width: 30, height: 30)
                }
                .padding(.vertical, 4).padding(.leading, 6).padding(.trailing, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(open ? "ซ่อนข้อมูลที่แบรนด์ใช้คัดเลือก" : "ดูข้อมูลที่แบรนด์ใช้คัดเลือก")
            if open {
                VStack(spacing: 8) { ForEach(list) { r in starRow(r, note: Self.whenNeeded(r)) } }
                    .transition(.opacity)
            }
        }
        .padding(10)
        .background(PK.shape(20).fill(PK.fieldFill))
        .overlay(PK.shape(20).strokeBorder(cheer ? GL.green : PK.line, lineWidth: cheer ? 2 : 1))
        .scaleEffect(cheer ? 1.015 : 1)
    }

    /// วงแหวน % ทางไปเป็น STAR (หัว "ข้อมูลสมัคร STAR") — เลขเดียวกับปุ่ม "สมัครเป็น STAR"
    private var starRing: some View {
        ZStack {
            Circle().stroke(GL.ink.opacity(0.08), lineWidth: 4)
            Circle().trim(from: 0, to: starPct)
                .stroke(GL.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((starPct * 100).rounded()))%").font(.sh(12, .heavy)).foregroundStyle(GL.ink).monospacedDigit()
        }
        .frame(width: 42, height: 42)
        .animation(Motion.settle, value: starPct)
    }

    /// บรรทัดใต้ชื่อของข้อที่ไม่ใช่ด่าน = บอกว่าใช้ตอนไหน (canvas แบบ A)
    private static func whenNeeded(_ r: StarRow) -> String {
        switch r.key {
        case .bank?: return "ใช้ตอนได้ค่าตัว"
        case .address?: return "ใช้ตอนลงทะเบียนกิจกรรม"
        case .body?: return "ใช้ตอนรับงานสายแฟชั่น"
        case .about?: return "ขึ้นใต้ชื่อบนการ์ด · ไม่บังคับ"
        case .insight?: return "แบรนด์ดูกลุ่มคนดู · ไม่บังคับ"
        default: return r.why
        }
    }

    /// หัวก่อนเป็น STAR: ดาว + "ข้อมูลสมัคร STAR · เหลืออีก N ข้อ" + ⌄ กางรายการ 8 ข้อ (ไม่มี %)
    private var fillHeader: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.impact(.light)
                withAnimation(Motion.settle) { listOpenChoice = !listOpen }
            } label: {
                HStack(spacing: 14) {
                    starRing
                    VStack(alignment: .leading, spacing: 1) {
                        Text("ใช้สมัครเป็น STAR").font(.sh(15, .bold)).foregroundStyle(GL.ink)
                        Text(starLeft == starRows.count ? "8 ข้อที่ต้องกรอกก่อนเป็น STAR" : "อีก \(starLeft) ข้อได้เป็น STAR")
                            .font(.sh(13)).foregroundStyle(GL.hint)
                    }
                    Spacer(minLength: 4)
                    PIcon(.caretDown, size: 14, weight: .bold).foregroundStyle(GL.hint)
                        .rotationEffect(.degrees(listOpen ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    /// ครบทุกข้อครั้งแรก = ฉลองสั้น ๆ: วงแหวนเด้ง + วงเขียวกระจาย + สั่น success (checklist "Completion celebration")
    private func cheerIfFull() {
        guard full else { cheered = false; return }
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

    /// แถวยืนยันตัวตนตอนรอตรวจ/ตีกลับ — บอกสถานะแทน "ทำไมต้องกรอก" (แตะแล้วเข้า wizard ขั้น KYC ซึ่งมีการ์ดสถานะ + ปุ่มส่งใหม่)
    private func kycNote(_ r: StarRow) -> String? {
        guard r.key == nil else { return nil }
        switch flow.verify {
        case .waiting: return "ทีมงานกำลังตรวจ · แจ้งผลภายใน 3 วันทำการ" + (flow.kycSentAt.map { " · ส่งเมื่อ \(KycDates.day($0))" } ?? "")
        case .rejected: return "ไม่ผ่าน: \(flow.verifyReason.isEmpty ? "กรุณาทำรายการใหม่" : flow.verifyReason) · แตะเพื่อส่งใหม่"
        default: return nil
        }
    }

    private func row(_ r: StarRow) -> some View {
        let ok = flow.done(r)
        return Button {
            Haptics.impact(.light)
            if ok {
                // ข้อที่ครบแล้ว = แก้ข้อนั้นข้อเดียว
                if let s = step(r) { onFill([s]) }
            } else {
                // ข้อที่ยังขาด = เริ่มที่ข้อนี้แล้วกดถัดไปต่อจนครบทุกข้อ ไม่ต้องเข้าออกทีละข้อ (ผู้ใช้ 24 ก.ย. 2569)
                onFill(fillSteps(from: r))
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
                        Text(kycNote(r) ?? (pane == .card ? r.onCard : r.why)).font(.sh(13)).foregroundStyle(kycNote(r) == nil ? Color(red: 122 / 255, green: 127 / 255, blue: 136 / 255) : (flow.verify == .rejected ? SH.red : SHColor.orange)).lineLimit(2)
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

    /// ยังไม่เป็น STAR = ชุดเดียว 8 ข้อก่อนแล้วข้อเสริม · เป็น STAR แล้ว = เริ่มที่ข้อที่แตะ ไล่ต่อจนครบ
    private func fillSteps(from start: StarRow?) -> [WizStep] {
        flow.isStar ? flow.missingSteps(from: start) : flow.applySteps
    }

    // MARK: ปุ่มล่าง (= `.ach2-foot`)

    private var foot: some View {
        VStack(spacing: 14) {
            switch mode {
            case .reveal:
                GlassPrimaryButton(title: "ต่อ: ฟอร์มสมัคร \(campaign.title)", action: onNext)
            case .profile:
                if !flow.isStar {
                    // ยังไม่ครบ 8 ข้อ = ปุ่ม "สมัครเป็น STAR" เสมอ → 8 ข้อก่อน (ครบ = motion STAR) แล้วต่อข้อที่เหลือในรอบเดียว (ผู้ใช้ 6 ต.ค. 2569)
                    // % ทางไปเป็น STAR เลขเดียวกับวงแหวนหัว "ข้อมูลสมัคร STAR" (ผู้ใช้ 7 ต.ค. 2569)
                    GlassPrimaryButton(title: "สมัครเป็น STAR", progress: starPct) { onFill(flow.applySteps) }
                } else if !full {
                    // เป็น STAR แต่ยังตอบคำถามที่แบรนด์ใช้คัดเลือกไม่ครบ = "เติมข้อมูลต่อ" ไม่มี % (ผู้ใช้ 7 ต.ค. 2569: % นับแค่ทางไปเป็น STAR)
                    // ข้อที่ขาดใน 8 ข้อก่อน (สถานะ C) แล้วข้อเสริม
                    GlassPrimaryButton(title: "เติมข้อมูลต่อ", symbol: .arrowRight) { onFill(flow.fillMoreSteps) }
                } else {
                    // ครบทุกข้อ = ปุ่มล่างพาไปการ์ด
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
