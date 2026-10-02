import SwiftUI
import PhosphorSwift
import UIKit

/// หน้าของฉัน — **การ์ดทุกใบที่ทำไว้ เรียงเป็นสำรับปัดดูได้ ใบที่แสดงอยู่ติดป้ายชัด ๆ**
///
/// # สิ่งที่หน้านี้ต้องตอบโดยไม่ต้องอ่าน
///
/// 1. **ฉันทำไว้กี่แบบ หน้าตายังไง** — ทุกใบเป็นการ์ดจริงขนาดใหญ่ ปัดซ้ายขวาดูทีละใบ ใบข้าง ๆ โผล่ขอบ
///    ให้รู้ว่ามีต่อ · ท้ายสำรับคือใบเปล่าเส้นประ "สร้างใหม่" — วิธีเพิ่มอยู่ในที่เดียวกับของที่มี
/// 2. **ใบไหนที่คนเห็นอยู่** — ป้ายเขียว "กำลังแสดงอยู่" แปะบนตัวการ์ด + ขอบเรืองสีธีมของใบนั้น
///    ใบอื่นไม่มีป้าย และตอนปัดไปหยุดที่ใบอื่น แถบล่างบอกว่า "ลิงก์ของคุณยังพาไปใบไหน" พร้อมปุ่ม "ใช้ใบนี้"
/// 3. **นี่คือของฉัน** — หัวหน้าเป็นตัวตน (รูป · ชื่อ · ตรา · @handle) และเวทีทั้งจออาบสีธีมของใบที่กำลังดู
///
/// ปุ่มทุกปุ่มเป็นของใบที่อยู่กลางจอ: แต่ง · แชร์ · ใช้ใบนี้ · ⋯ — ไม่มีประโยคอธิบาย
struct CardGallery: View {
    let onCreate: () -> Void
    let onOpen: (CardRecord) -> Void
    /// เปิดใบนั้นแบบที่แบรนด์เห็น (หน้าดู + เวทีของ Sale Here) — ไม่มี = ไม่โชว์เมนูข้อนี้
    var onPreview: ((CardRecord) -> Void)? = nil
    /// เปิดหน้า "ข้อมูลของฉัน" — แตะที่รูป/ชื่อในหัว
    var onProfile: (() -> Void)? = nil
    /// ตัวนับ "กลับเข้าหน้านี้ใหม่" — ค่าเปลี่ยน = เล่นท่าเข้าฉากอีกครั้ง
    ///
    /// หน้านี้ถูก mount ค้างไว้ตลอดแม้ตอนที่โปรไฟล์ทับอยู่ `onAppear` จึงยิงครั้งเดียวตอนเปิดแอป
    /// ขากลับเข้ามาจะไม่มีท่าอะไรเลยถ้าไม่มีตัวนับตัวนี้มาปลุก (ดู `ContentView.enterGallery`)
    var entryToken: Int = 0
    /// ฝังอยู่ในหน้า Star Profile (สถานะ "การ์ด" ของ toggle ข้อมูล | การ์ด — ผู้ใช้เลือกแบบ G2, 23 ก.ย. 2569):
    /// ไม่มีเวทีมืด ไม่มีหัวของตัวเอง ตัวหนังสือเป็นหมึกบนพื้นสว่างเดียวกับหน้าข้อมูล
    var embedded = false
    /// พื้น/เวทีและหัว (title + toggle) วาดโดย shell แล้ว (`StarGround`/`StarHeader`) — หน้านี้โปร่งใส เหลือแถวตัวตน สำรับ ปุ่ม
    var sharedStage = false
    /// ธีมของใบที่อยู่กลางจอเปลี่ยน — ให้ดวงไฟของ shell เปลี่ยนสีตาม
    var onFocusTheme: ((CardTheme) -> Void)? = nil
    /// เปิดมาที่ใบที่กำลังแสดง (ใบแรกของสำรับ) — มาจากหมวด Star Card บนหน้า Star Profile ที่โชว์ใบนั้นอยู่
    /// (ไม่งั้นเปิดที่ใบที่แก้ล่าสุด แล้วหน้า Profile กับหน้านี้พูดถึงคนละใบ — ผู้ใช้ 24 ก.ย. 2569)
    var startAtLive = false

    private var library: CardLibrary { CardLibrary.shared }
    /// สีตัวหนังสือรอบสำรับ — ขาวบนเวทีมืด · หมึกเมื่อฝังบนพื้นสว่าง
    private var fg: Color { embedded ? GL.ink : .white }
    @Environment(ClipInvocation.self) private var invocation
    @Environment(PhotoStore.self) private var photos

    /// id ของใบที่อยู่กลางจอ — `createID` คือใบเปล่า "สร้างใหม่" ท้ายสำรับ
    @State private var focus: String?
    private static let createID = "__create__"
    /// ตำแหน่งเลื่อนของสำรับ — คุมด้วยระยะตรง ๆ จากจุดหยุดชุดเดียวกับ `DeckSnap`
    ///
    /// `scrollPosition(id:anchor: .center)` หากลางใบเพี้ยนเมื่อใบกว้างไม่เท่ากัน (กดจุดไปใบท้ายแล้วใบเลยกลางจอ)
    /// และตอนเปิดหน้าไม่ยอมเลื่อนไปใบที่ตั้งไว้ — ใช้จุดหยุดชุดเดียวทั้งตอนปัดและตอนสั่งเลื่อน ผลจึงตรงกันเสมอ
    @State private var scroll = ScrollPosition()
    /// ใบที่ตัวสำรับรายงานเองล่าสุด — แยก "นิ้วปัดมาถึง" ออกจาก "สั่งให้ไป" ไม่งั้นสั่งเลื่อนทับนิ้วระหว่างปัด
    @State private var reported: String?
    /// สำรับถูกวางที่ใบตั้งต้นแล้ว — ก่อนนั้นระยะเลื่อนกับจุดหยุดยังไม่ใช่ของจริง ห้ามฟังรายงาน/ห้ามสั่งเลื่อน
    ///
    /// ไม่กั้นไว้ รายงานรอบแรกที่คิดจากขนาดยังไม่นิ่งจะเขียนทับใบที่ตั้งใจเปิด (เปิดมาชื่อใต้การ์ดเป็นอีกใบ)
    @State private var landed = false
    @State private var unpacked = UnpackCache()

    /// ใบที่เปิดมาเจอ — ใบที่แตะล่าสุด กลับจากห้องแต่งต้องเจอใบที่เพิ่งแก้ ไม่ใช่ต้องปัดหา
    private var initialFocusID: String? {
        if startAtLive, let live = published?.id { return live }
        return library.records.max { $0.updatedAt < $1.updatedAt }?.id ?? published?.id
    }
    /// ลำดับใบในสำรับ — **ตรึงไว้ตลอดที่เปิดหน้านี้** ไม่จัดใหม่ตามใบที่แสดง
    ///
    /// ถ้าให้ใบที่แสดงกระโดดไปหัวสำรับทุกครั้งที่กด "ใช้ใบนี้" ตำแหน่งเลื่อนของ ScrollView จะไม่ตรงกับ
    /// ใบที่ตั้งใจดูอีกต่อไป (ของขยับใต้นิ้ว) · ลำดับตั้งต้น: ใบที่แสดงก่อน แล้วไล่ตามที่แก้ล่าสุด
    /// ใบใหม่ (สำเนา) ต่อท้าย ข้างใบ "สร้างใหม่"
    @State private var order: [String] = []
    /// เพิ่งคัดลอกลิงก์ — โชว์ "คัดลอกแล้ว" ชั่วครู่ตรงแถบลิงก์
    @State private var copied = false
    /// กดค้างที่การ์ดเพิ่งเปิดโหมดดู — ปุ่มการ์ดยังยิงตอนปล่อยนิ้ว ต้องกลืนแตะครั้งนั้นทิ้ง
    @State private var previewedByHold = false
    /// สวิตช์ท่าเข้าฉาก — สำรับลอยขึ้นมา หัวกับปุ่มตามมา
    @State private var appeared = false

    /// ชีตคำสั่งรองของใบ — ทำเองทั้งใบแทน `Menu`/`alert` ของระบบ
    ///
    /// เมนูระบบบังคับฟอนต์ระบบ ปฏิเสธฟอนต์แอปทุกกรณี — แอปที่ตัวหนังสือทุกจุดเป็น
    /// NotoSansThai แล้วเมนูโผล่มาเป็นฟอนต์อื่นคือรอยต่อที่เห็นด้วยตาเปล่า
    @State private var sheetOpen = false
    @State private var mode: SheetMode = .menu
    @State private var renameText = ""

    private enum SheetMode { case menu, rename, confirmDelete }

    /// ใบที่แสดงอยู่ (ลิงก์ประจำตัวพาไป) — `displayOrder` เอาใบหลักขึ้นก่อนเสมอ
    private var published: CardRecord? { library.displayOrder.first }
    /// ใบในสำรับตามลำดับที่ตรึงไว้
    private var deckRecords: [CardRecord] {
        order.compactMap { id in library.records.first { $0.id == id } }
    }
    /// ใบที่อยู่กลางจอตอนนี้ — nil เมื่ออยู่ที่ใบเปล่า "สร้างใหม่"
    private var focused: CardRecord? {
        guard let focus, focus != Self.createID else { return focus == nil ? published : nil }
        return library.records.first { $0.id == focus } ?? published
    }

    /// จัดลำดับสำรับ — ครั้งแรกเรียงตามที่ตกลง หลังจากนั้นแค่เติมใบใหม่ท้ายสำรับ/ตัดใบที่ถูกลบ ไม่สลับที่
    private func syncOrder() {
        let ids = Set(library.records.map(\.id))
        var kept = order.filter { ids.contains($0) }
        if kept.isEmpty {
            kept = library.displayOrder.map(\.id)
        } else {
            for r in library.records where !kept.contains(r.id) { kept.append(r.id) }
        }
        order = kept
    }
    private func theme(of record: CardRecord?) -> CardTheme {
        record.flatMap { unpacked.restore($0)?.theme } ?? CardTheme()
    }

    var body: some View {
        ZStack {
            // เวทีอาบสีของใบที่กำลังดู — ปัดไปใบไหนทั้งหน้าเปลี่ยนสีตาม (ใบเปล่าใช้สีของใบที่แสดงอยู่)
            // เวทีติดไฟก่อนของ แล้วสำรับค่อยเข้ามา — ตาอ่านเป็นชั้น ไม่ใช่ทั้งหน้าโผล่พรึ่บ
            if embedded {
                // แสงเรืองสีธีมของใบที่ดูอยู่ บนพื้นสว่างของ Star Profile — ไม่ใช่เวทีมืดทั้งจอ
                RadialGradient(colors: [theme(of: focused ?? published).rawAccent.opacity(0.28), .clear],
                               center: .center, startRadius: 20, endRadius: 320)
                    .animation(Motion.settle, value: focus)
                    .allowsHitTesting(false)
            } else if !sharedStage {
                stage(theme(of: focused ?? published))
                    .opacity(appeared ? 1 : 0.55)
                    .animation(Motion.settle, value: appeared)
            }

            if library.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    if !embedded {
                        header
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : -12)
                            .animation(Motion.settle.delay(0.08), value: appeared)
                    }
                    deck
                        .scaleEffect(appeared ? 1 : 0.94)
                        // สำรับแกว่งเข้าที่รอบแกนตั้งของตัวเอง — อ่านเป็นของหนาที่มีด้าน
                        // ไม่ใช่ภาพแบนที่ถูกย่อ (นิ่งสนิทที่ปลายทาง ไม่ค้าง transform ไว้)
                        .rotation3DEffect(.degrees(appeared ? 0 : 13),
                                          axis: (x: 0, y: 1, z: 0), perspective: 0.55)
                        .opacity(appeared ? 1 : 0)
                        .animation(Motion.settle, value: appeared)
                    dock
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 28)
                        .animation(Motion.settle.delay(0.14), value: appeared)
                }
            }
        }
        .preferredColorScheme(embedded ? .light : .dark)
        .onAppear {
            syncOrder()
            // เปิดมาที่ใบที่แตะล่าสุด — กลับจากห้องแต่งต้องเจอใบที่เพิ่งแก้ ไม่ใช่ต้องปัดหา
            // (ใบที่แสดงอยู่มีป้ายบนตัวมันเอง อยู่ตรงไหนของสำรับก็เห็น)
            if focus == nil {
                focus = initialFocusID
            }
            appeared = true
        }
        .onChange(of: entryToken) { _, _ in
            appeared = false
            // ข้าม run loop ไม่งั้น SwiftUI ยุบสองสถานะเป็นเฟรมเดียว แล้วไม่เห็นจังหวะเข้า
            DispatchQueue.main.async { appeared = true }
        }
        .onChange(of: library.records.map(\.id)) { _, _ in syncOrder() }
        .onChange(of: focus, initial: true) { _, _ in onFocusTheme?(theme(of: focused ?? published)) }
        // อบรูปเทมเพลตล่วงหน้าตั้งแต่ยังอยู่หน้านี้ — กด + แล้วหน้าเลือกได้รูปพร้อมใช้ทันที
        .task { await TemplateThumbs.shared.warm(photos: photos) }
        .sheet(isPresented: $sheetOpen) {
            if let record = focused {
                actionSheet(record)
                    .presentationDetents([.height(mode == .menu ? 340 : 252), .medium, .large])
                    .presentationDragIndicator(.visible)
                    .environment(\.colorScheme, .dark)
                    .presentationBackground {
                        // มืดแบบเดียวกับชีตเครื่องมือในห้องแต่ง — เครื่องมือมืดเสมอ
                        Rectangle().fill(.ultraThinMaterial)
                            .overlay(Color(white: 0.07).opacity(0.5))
                    }
            }
        }
    }

    // MARK: - เวที

    /// ฉากหลังทั้งจอ = ฉากหลังของใบที่ดูอยู่ หรี่ลงให้การ์ดจริงลอยเด่น
    ///
    /// หรี่ไม่แรงเท่าเดิม — สีของธีมยังต้องอ่านออกว่าเป็นสีอะไร ไม่ใช่เทาเข้มเหมือนกันทุกใบ
    private func stage(_ theme: CardTheme) -> some View {
        ZStack {
            CardBackdrop(theme: theme, ignoreSafeArea: true)
            LinearGradient(colors: [.black.opacity(0.54), .black.opacity(0.36), .black.opacity(0.6)],
                           startPoint: .top, endPoint: .bottom)
            // ลายน้ำลายของแบรนด์บนเวที — จางพอให้ "รู้สึก" ไม่ใช่ "อ่าน" (ดู `Signature`)
            SignaturePattern(opacity: 0.06)
        }
        .ignoresSafeArea()
        .animation(Motion.settle, value: focus)
    }

    /// toggle ข้อมูล | การ์ด บนเวทีมืด — คู่กับตัวบนหน้า Star Profile (พื้นสว่าง) ตำแหน่งเดียวกัน: ขวาบนข้างชื่อ
    private var paneToggle: some View {
        HStack(spacing: 2) {
            Button {
                Haptics.impact(.light)
                onProfile?()
            } label: {
                Text("ข้อมูล").font(.sh(13, .bold)).foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 12).frame(height: 30).contentShape(Capsule())
            }
            .buttonStyle(.plain)
            Text("การ์ด").font(.sh(13, .bold)).foregroundStyle(.black.opacity(0.88))
                .padding(.horizontal, 12).frame(height: 30)
                .background(Capsule().fill(.white.opacity(0.92)))
        }
        .padding(3)
        .glassEffect(.regular, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 0.6))
    }

    // MARK: - หัว: ตัวตน

    /// รูป · ชื่อ · ตรา · @handle — หน้าตาของหน้าโปรไฟล์ที่ทุกคนคุ้น = "หน้านี้คือของฉัน" โดยไม่ต้องอ่าน
    private var header: some View {
        VStack(spacing: 14) {
            if sharedStage {
                // หัวร่วม (title + toggle) อยู่ที่ shell (top 50 + สูง 64) — เว้นที่ไว้ให้แถวตัวตนอยู่ใต้มัน
                Color.clear.frame(height: 108)
            } else if onProfile != nil {
                // หัวเดียวกับหน้า Star Profile: "Star Card" + toggle ข้อมูล | การ์ด ขวาบน (ผู้ใช้ 23 ก.ย.: เก็บ title ไว้ สวยดี)
                HStack(alignment: .bottom, spacing: 10) {
                    // คำ Star = ตรา ST★R ของ Sale Here (ผู้ใช้ 30 ก.ย. 2569)
                    HStack(alignment: .lastTextBaseline, spacing: StarCaps.gap(forSerif: 40)) {
                        StarCaps(height: StarCaps.height(forSerif: 40), color: .white)
                        Text("Card").font(GL.serif(40)).foregroundStyle(GL.serifInk(onDark: true))
                    }
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
                    Spacer(minLength: 0)
                    paneToggle.padding(.bottom, 6)
                }
                .padding(.horizontal, 20)
            }
            identityRow
        }
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var identityRow: some View {
        HStack(spacing: 12) {
            // ตัวตนทั้งก้อนแตะได้ = เปิด "ข้อมูลของฉัน" — ที่เดียวกับที่ทุกการ์ดดึงข้อมูลตั้งต้นไป
            Button {
                Haptics.impact(.light)
                onProfile?()
            } label: {
                HStack(spacing: 12) {
                    // รูปเดียวกับที่การ์ดใช้เป็นรูปโปรไฟล์ (ดู `PhotoLib`) — เห็นหน้าตัวเองก่อนเห็นอะไร
                    photos.avatar()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 46, height: 46)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 5) {
                            Text(Profile.me.name)
                                .font(.sh(17, .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1).minimumScaleFactor(0.8)
                            if Profile.me.creator.verified {
                                // ดาวทอง = สถานะ STAR — ตราเดียวกับที่อยู่ข้างชื่อบนการ์ดทุกใบ
                                StarSeal(size: 13)
                            }
                        }
                        HStack(spacing: 6) {
                            Text("การ์ด \(library.records.count) ใบ")
                                .font(.sh(12, .medium))
                                .foregroundStyle(.white.opacity(0.62))
                                .lineLimit(1).minimumScaleFactor(0.8)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(DockPress())
            .disabled(onProfile == nil)
            .accessibilityLabel("ข้อมูลของฉัน")
            Spacer(minLength: 8)

            glassCircle("plus", label: "สร้างการ์ดใหม่") { onCreate() }
        }
        .padding(.horizontal, 20)
    }

    private func glassCircle(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .buttonStyle(DockPress())
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel(label)
    }

    // MARK: - สำรับ

    /// ขนาดของใบในสำรับ — **แต่ละใบเป็นทรงจริงของมัน**
    ///
    /// แนวนอน (พอร์ต) คือแถบสามหน้าต่อกันกว้างเกือบเต็มจอ — หน้าตาเดียวกับรูปที่แชร์ออก
    /// แนวตั้ง (สตอรี่) คือเฟรม 9:16 · เดิมบีบทุกใบลงเฟรมตั้งเดียวกันแล้วโชว์แค่หน้าแรก
    /// ใบแนวนอนเลยดูเป็นแนวตั้ง และอีกสองหน้าหายไปจากสายตาทั้งที่มันคือครึ่งหนึ่งของงาน
    private struct DeckMetrics {
        let portrait: CGSize
        let landscape: CGSize

        func size(of format: CardFormat) -> CGSize { format == .portfolio ? landscape : portrait }
        /// มุมนอกของใบแนวนอนเล็กกว่า — ร่วมศูนย์กับมุมของหน้าข้างใน (มุมหน้า + ขอบ)
        /// ใช้ 22 เท่าใบตั้ง มุมนอกจะกินมุมของหน้าแรก/หน้าท้ายจนดูเป็นคนละทรงกัน
        func radius(of format: CardFormat) -> CGFloat { format == .portfolio ? 14 : 22 }
    }

    /// ช่องว่างระหว่างหน้า / ขอบรอบแถบของใบแนวนอน (หน่วยออกแบบ)
    private static let stripGutter: CGFloat = CardTemplate.thumbGutter
    private static let stripMargin: CGFloat = CardTemplate.thumbGutter
    /// ระยะห่างระหว่างใบในสำรับ
    private static let deckSpacing: CGFloat = 12

    private func metrics(_ box: CGSize) -> DeckMetrics {
        let story = CardTemplate.previewPageSize(for: .story)
        // แถวสูงได้เท่าที่เหลือหลังหักชื่อใบกับจุดบอกตำแหน่งใต้การ์ด
        let maxH = max(140, box.height - 74)
        let pw = min(box.width - 64, maxH * story.width / story.height)
        // แนวนอนกว้างกว่าใบตั้ง — ของสามหน้าในจอแนวตั้งต้องได้ทุกพอยต์ที่มี ใบข้าง ๆ ยังโผล่ขอบให้เห็น
        let lw = box.width - 44
        return DeckMetrics(
            portrait: CGSize(width: pw, height: pw * story.height / story.width),
            landscape: CGSize(width: lw,
                              height: CardStripPreview.height(width: lw, gutter: Self.stripGutter,
                                                              margin: Self.stripMargin)))
    }

    /// ใบเปล่า "สร้างใหม่" ใช้ทรงเดียวกับใบก่อนหน้ามัน — สำรับที่มีแต่แนวนอนจะไม่มีใบตั้งโผล่มาปิดท้าย
    private var createFormat: CardFormat { deckRecords.last?.format ?? .portfolio }

    /// การ์ดทุกใบเรียงแนวนอน ปัดทีละใบ ใบข้าง ๆ โผล่ขอบ — ท้ายสำรับคือใบเปล่า "สร้างใหม่"
    private var deck: some View {
        GeometryReader { geo in
            let m = metrics(geo.size)
            let sizes = deckRecords.map { m.size(of: $0.format) } + [m.size(of: createFormat)]
            let rowH = sizes.map(\.height).max() ?? m.portrait.height
            let focusH = m.size(of: focused?.format ?? createFormat).height
            let ids = deckRecords.map(\.id) + [Self.createID]
            let snap = DeckSnap(widths: sizes.map(\.width), spacing: Self.deckSpacing)
            let land: () -> Void = {
                guard !landed, let target = focus ?? initialFocusID,
                      let i = ids.firstIndex(of: target) else { return }
                reported = target
                if focus != target { focus = target }
                // วางทันทีไม่ไหล — สำรับกำลังค่อย ๆ ปรากฏอยู่แล้ว
                DispatchQueue.main.async {
                    scroll.scrollTo(x: snap.stops[i])
                    // ใบแรกคือระยะ 0 ที่สำรับอยู่แล้ว ไม่มีรายงาน "ถึง" ให้รอ
                    if i == 0 { landed = true }
                }
            }

            VStack(spacing: 14) {
                Spacer(minLength: 0)
                ScrollView(.horizontal) {
                    LazyHStack(spacing: Self.deckSpacing) {
                        ForEach(deckRecords) { record in
                            card(record, size: m.size(of: record.format),
                                 radius: m.radius(of: record.format))
                                .id(record.id)
                        }
                        createCard(size: m.size(of: createFormat), radius: m.radius(of: createFormat))
                            .id(Self.createID)
                    }
                    .background(FastDeceleration())
                    // ใบแรก/ใบท้ายหยุดกลางจอได้ — เว้นหัวท้ายตามความกว้างของใบนั้นเอง
                    .padding(.leading, (geo.size.width - (sizes.first?.width ?? 0)) / 2)
                    .padding(.trailing, (geo.size.width - (sizes.last?.width ?? 0)) / 2)
                }
                .scrollTargetBehavior(snap)
                .scrollPosition($scroll)
                // ใบที่อยู่กลางจอตามระยะเลื่อนจริง — ชื่อ/สีเวที/ปุ่มเปลี่ยนตามตั้งแต่ระหว่างปัด
                .onScrollGeometryChange(for: Int.self) {
                    $0.containerSize.width > 0 ? snap.nearest($0.contentOffset.x) : -1
                } action: { _, i in
                    guard ids.indices.contains(i) else { return }
                    // ก่อนถึงใบตั้งต้น ระยะเลื่อนคือของที่ระบบวางเอง ไม่ใช่นิ้ว — รอจนถึงใบที่ตั้งใจเปิดแล้วค่อยเปิดรับ
                    guard landed else {
                        if ids[i] == reported { landed = true }
                        return
                    }
                    reported = ids[i]
                    if focus != ids[i] { focus = ids[i] }
                }
                // สั่งไปใบไหน (จุด · ลบ · ทำสำเนา) เลื่อนไปจุดหยุดของใบนั้น
                .onChange(of: focus) { _, new in
                    guard landed, let new, new != reported, let i = ids.firstIndex(of: new) else { return }
                    withAnimation(Motion.page) { scroll.scrollTo(x: snap.stops[i]) }
                }
                // วางที่ใบตั้งต้น — สั่งทุกครั้งที่ใบชุดใหม่ถูกวัด จนสำรับรายงานว่าถึงจริง
                //
                // สำรับปรากฏก่อน `onAppear` ของหน้าจะเติมลำดับใบ (ตอนนั้นมีแค่ใบ "สร้างใหม่")
                // และระยะที่สั่งทันทีหลังใบมาถึงถูกตอนวัดเนื้อหาใหม่ทับหาย — สั่งครั้งเดียวจึงค้างที่ใบแรก
                .onChange(of: ids, initial: true) { _, _ in land() }
                .onScrollGeometryChange(for: CGFloat.self) { $0.contentSize.width } action: { _, _ in land() }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                .frame(height: rowH)

                // ชื่อใบเกาะใต้ใบที่อยู่กลางจอ — ใบแนวนอนเตี้ยกว่า ชื่อจึงขยับขึ้นตาม ไม่ค้างลอยห่างอยู่ก้นแถว
                caption
                    .offset(y: -(rowH - focusH) / 2)
                    .animation(Motion.settle, value: focusH)
                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// การ์ดหนึ่งใบในสำรับ — ใบที่แสดงอยู่มีป้ายเขียวบนตัวการ์ดและขอบเรืองสีธีมของมัน
    @ViewBuilder
    private func card(_ record: CardRecord, size: CGSize, radius: CGFloat) -> some View {
        let restored = unpacked.restore(record)
        let theme = restored?.theme ?? CardTheme()
        let pages = restored?.pages ?? []
        let live = record.id == library.publishedID
        let landscape = record.format == .portfolio
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        Button {
            if previewedByHold { previewedByHold = false; return }
            Haptics.impact(.light)
            onOpen(record)
        } label: {
            ZStack {
                // สีธีมรองไว้ใต้พรีวิว — ระหว่างรูปในการ์ดยังโหลดไม่เสร็จ ใบไม่เป็นช่องโหว่ใส
                shape.fill(LinearGradient(colors: [theme.backdropColors.top, theme.backdropColors.bottom],
                                          startPoint: .top, endPoint: .bottom))
                switch record.format {
                case .portfolio:
                    // แนวนอน = ครบสามหน้าบนแผ่นเดียว — หน้าตาเดียวกับรูปที่แชร์ออกไปจริง
                    CardStripPreview(pages: pages, theme: theme, width: size.width,
                                     showsDividers: false, gutter: Self.stripGutter,
                                     margin: Self.stripMargin, cornerRadius: radius)
                case .story:
                    CardFramePreview(page: pages.first ?? CardPage(), theme: theme,
                                     pageSize: CardTemplate.previewPageSize(for: .story),
                                     height: size.height, cornerRadius: radius)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(shape)
            .overlay(shape.strokeBorder(live ? theme.rawAccent.opacity(0.9) : .white.opacity(0.14),
                                        lineWidth: live ? 1.6 : 0.8))
            .overlay(alignment: .topLeading) {
                if live {
                    // ป้ายบนตัวการ์ด ไม่ใช่ข้าง ๆ — เลื่อนผ่านเร็ว ๆ ก็ยังรู้ว่าใบนี้คือใบที่คนเห็น
                    HStack(spacing: 6) {
                        Circle().fill(SHColor.success).frame(width: 6, height: 6)
                        Text("กำลังแสดงอยู่").font(.sh(11, .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(Capsule().fill(.black.opacity(0.62)))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.6))
                    // ใบแนวนอนเตี้ย ป้ายขนาดเดิมวางบนตัวการ์ดจะทับหน้าแรกไปครึ่งหน้า —
                    // ย้ายไปเกาะเหนือขอบบนแทน ยังติดไปกับใบตอนปัดเหมือนเดิม
                    .padding(landscape ? 0 : 12)
                    .offset(y: landscape ? -40 : 0)
                    // กด "ใช้ใบนี้" แล้วป้ายผุดขึ้นบนใบตรงหน้า — ใบไม่ขยับ ป้ายกับแสงเป็นคนบอก
                    .transition(.scale(scale: 0.6, anchor: landscape ? .bottomLeading : .topLeading)
                        .combined(with: .opacity))
                }
            }
            .overlay(alignment: .topTrailing) {
                // ป้ายรับรองเกาะเหนือขอบบนขวา คู่กับป้าย "กำลังแสดงอยู่" ทางซ้าย — อยู่นอกตัวการ์ด
                // ไม่กินพื้นที่งานของเจ้าของ แต่มองทั้งสำรับแล้วรู้ทันทีว่าใบไหน Sale Here รับรองแล้ว
                if VerifiedFacts.current.verified {
                    VerifiedTab()
                        .padding(landscape ? 0 : 12)
                        .offset(y: landscape ? -40 : 0)
                }
            }
            .shadow(color: live ? theme.rawAccent.opacity(0.45) : .black.opacity(embedded ? 0.22 : 0.5),
                    radius: live ? 30 : 24, y: 14)
            .animation(Motion.settle, value: live)
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        // ทางลัดไว้เทส: กดค้างที่การ์ด = เปิดโหมดดู (หน้าเดียวกับ ⋯ › ดูแบบที่แบรนด์เห็น)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in
            guard let onPreview else { return }
            previewedByHold = true
            Haptics.impact(.medium)
            onPreview(record)
        })
        .accessibilityLabel(record.name + (live ? " · กำลังแสดงอยู่" : ""))
    }

    /// ใบเปล่าท้ายสำรับ — วิธีเพิ่มอยู่ในที่เดียวกับของที่มี ไม่ต้องไปหาปุ่มที่อื่น
    private func createCard(size: CGSize, radius: CGFloat) -> some View {
        let width = size.width, height = size.height
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return Button {
            Haptics.impact(.medium)
            onCreate()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(SHColor.red))
                    .shadow(color: SHColor.red.opacity(0.4), radius: 14, y: 6)
                Text("สร้างการ์ดใหม่")
                    .font(.sh(14, .semibold))
                    .foregroundStyle(fg.opacity(0.85))
                Text("เลือกจากเทมเพลต")
                    .font(.sh(11.5, .medium))
                    .foregroundStyle(fg.opacity(0.45))
            }
            .frame(width: width, height: height)
            .background(shape.fill(fg.opacity(0.05)))
            .overlay(shape.strokeBorder(fg.opacity(0.28),
                                        style: StrokeStyle(lineWidth: 1.2, dash: [7, 6])))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("สร้างการ์ดใหม่")
    }

    /// ใต้สำรับ: ชื่อใบที่ดูอยู่ + จุดบอกตำแหน่งในสำรับ (จุดแยกกัน — เพราะนี่คือ **คนละใบ** จริง ๆ)
    private var caption: some View {
        let all = order + [Self.createID]
        let index = all.firstIndex(of: focus ?? published?.id ?? "") ?? 0
        return VStack(spacing: 10) {
            Text(focused?.name ?? "สร้างการ์ดใหม่")
                .font(.sh(15, .semibold))
                .foregroundStyle(fg)
                .lineLimit(1).truncationMode(.tail)
                .id(focused?.id ?? Self.createID)
                .transition(.opacity)
            HStack(spacing: 6) {
                ForEach(Array(all.enumerated()), id: \.element) { i, id in
                    Group {
                        // ช่อง "สร้างใหม่" ไม่ใช่การ์ด — เป็น + ไม่ใช่จุด จำนวนจุดจึงเท่ากับ "การ์ด N ใบ" ในหัว
                        if id == Self.createID {
                            Image(systemName: "plus")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(fg.opacity(i == index ? 0.95 : 0.4))
                                .frame(width: 10, height: 6)
                        } else {
                            Capsule()
                                .fill(i == index ? fg.opacity(0.95) : fg.opacity(0.3))
                                .frame(width: i == index ? 18 : 6, height: 6)
                        }
                    }
                    .onTapGesture {
                            Haptics.impact(.light)
                            withAnimation(Motion.page) { focus = id }
                        }
                }
            }
            .animation(Motion.snap, value: index)
        }
        .animation(Motion.snap, value: focus)
        .padding(.horizontal, 32)
    }

    // MARK: - ล่าง: ปุ่มของใบที่ดูอยู่

    @ViewBuilder
    private var dock: some View {
        ZStack {
            if let record = focused {
                let theme = theme(of: record)
                let live = record.id == library.publishedID
                let url = library.url(for: record, slug: invocation.slug)
                VStack(spacing: 10) {
                    // ทุกใบมีลิงก์ของตัวเอง คัดลอกได้หมด — แถบลิงก์จึงโชว์ทุกใบ ไม่ใช่เฉพาะใบที่แสดงอยู่
                    linkPill(record, url: url)

                    HStack(spacing: 10) {
                        if live {
                            primaryButton("pencil", "แต่งการ์ด", tint: theme.rawAccent) { onOpen(record) }
                            ShareLink(item: url) {
                                secondaryLabel("square.and.arrow.up", "แชร์")
                            }
                            .buttonStyle(DockPress())
                            .glassEffect(.regular.interactive(), in: Capsule())
                        } else {
                            // ปุ่มหลักของใบที่ยังไม่แสดงคือ "ใช้ใบนี้" — ท่าที่คนมาหน้านี้เพื่อทำมากที่สุด
                            primaryButton("checkmark", "ใช้ใบนี้", tint: theme.rawAccent) {
                                withAnimation(Motion.settle) { library.setPublished(record.id) }
                            }
                            Button {
                                Haptics.impact(.light)
                                onOpen(record)
                            } label: {
                                secondaryLabel("pencil", "แต่ง")
                            }
                            .buttonStyle(DockPress())
                            .glassEffect(.regular.interactive(), in: Capsule())
                        }
                        // ⋯ อยู่ท้ายแถวปุ่มของใบ — เป็นคำสั่งของใบตรงหน้า จึงอยู่กับปุ่มของใบ ไม่ใช่มุมบน
                        moreButton
                    }
                }
                .id(record.id)
                .transition(.opacity)
            } else {
                VStack(spacing: 10) {
                    Color.clear.frame(height: 42)
                    primaryButton("plus", "สร้างการ์ดใหม่", tint: SHColor.red, light: true) { onCreate() }
                }
                .transition(.opacity)
            }
        }
        .animation(Motion.settle, value: focus)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    /// ปุ่มหลักปุ่มเดียวของแถบล่าง — สีเน้นของใบที่ดูอยู่ ทั้งหน้าจึงพูดสีเดียวกัน
    private func primaryButton(_ symbol: String, _ title: String, tint: Color,
                               light: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.medium)
            action()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: symbol).font(.system(size: 14, weight: .bold))
                Text(title).font(.sh(15, .bold))
            }
            .foregroundStyle(light ? Color.white : Color.black.opacity(0.86))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .contentShape(Capsule())
        }
        .buttonStyle(DockPress())
        .glassEffect(.regular.tint(tint).interactive(), in: Capsule())
    }

    /// ⋯ ของใบที่ดูอยู่ — วงกลมสูงเท่าปุ่มในแถว
    private var moreButton: some View {
        Button {
            Haptics.impact(.light)
            mode = .menu
            sheetOpen = true
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(fg)
                .frame(width: 52, height: 52)
                .contentShape(Circle())
        }
        .buttonStyle(DockPress())
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel("ตัวเลือกของการ์ดใบนี้")
    }

    private func secondaryLabel(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .offset(y: symbol == "square.and.arrow.up" ? -1 : 0)
            Text(title).font(.sh(15, .semibold))
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 22)
        .frame(height: 52)
        .contentShape(Capsule())
    }

    /// ลิงก์ของฉัน — แตะทั้งแถบ = คัดลอก · ลิงก์คือของที่ส่งให้แบรนด์ จึงอยู่ติดปุ่ม ไม่ซ่อนในเมนู
    private func linkPill(_ record: CardRecord, url: URL) -> some View {
        Button {
            UIPasteboard.general.string = url.absoluteString
            Haptics.impact(.light)
            withAnimation(Motion.settle) { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(Motion.settle) { copied = false }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: copied ? "checkmark" : "link")
                    .font(.sh(11, .bold))
                    .contentTransition(.symbolEffect(.replace))
                Text(copied ? "คัดลอกลิงก์แล้ว" : library.urlDisplay(for: record, slug: invocation.slug))
                    .font(.sh(12.5, .semibold))
                    .lineLimit(1).truncationMode(.middle)
                Spacer(minLength: 6)
                if !copied {
                    Text("คัดลอก")
                        .font(.sh(11, .semibold))
                        .foregroundStyle(fg.opacity(0.55))
                }
            }
            .foregroundStyle(copied ? SHColor.success : fg.opacity(0.9))
            .padding(.horizontal, 16)
            .frame(height: 42)
            .contentShape(Capsule())
        }
        .buttonStyle(DockPress())
        .glassEffect(.regular.interactive(), in: Capsule())
        .accessibilityLabel(copied ? "คัดลอกลิงก์แล้ว" : "คัดลอกลิงก์ของฉัน")
    }

    // MARK: - ชีตคำสั่งรอง (ฟอนต์แอปทุกตัวอักษร)

    @ViewBuilder
    private func actionSheet(_ record: CardRecord) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            switch mode {
            case .menu:
                Text(record.name)
                    .font(.sh(15, .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1).truncationMode(.tail)
                    .padding(.top, 4)

                // ลิงก์ของใบนี้ — ใบรองมีลิงก์เฉพาะใบของตัวเอง (ส่งใบไหนให้แบรนด์ไหนก็เลือกเอา)
                sheetRow("link", "คัดลอกลิงก์") {
                    UIPasteboard.general.string =
                        library.url(for: record, slug: invocation.slug).absoluteString
                    Haptics.impact(.light)
                    sheetOpen = false
                }
                // เห็นสิ่งที่แบรนด์เห็นเมื่อกดลิงก์ — เวที ตรา และแถบผู้ออกบัตร ก่อนส่งจริง
                if let onPreview {
                    sheetRow("eye", "มุมมองแบรนด์") {
                        Haptics.impact(.light)
                        sheetOpen = false
                        onPreview(record)
                    }
                }
                sheetRow("pencil", "เปลี่ยนชื่อ") {
                    renameText = record.name
                    withAnimation(Motion.settle) { mode = .rename }
                }
                sheetRow("plus.square.on.square", "ทำสำเนา") {
                    let copy = library.duplicate(record.id)
                    Haptics.impact(.medium)
                    sheetOpen = false
                    // สำเนาโผล่ท้ายสำรับ — พาไปดูมัน ไม่งั้นกดแล้วเหมือนไม่มีอะไรเกิดขึ้น
                    if let copy {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation(Motion.page) { focus = copy.id }
                        }
                    }
                }
                sheetRow("trash", "ลบการ์ด", destructive: true) {
                    withAnimation(Motion.settle) { mode = .confirmDelete }
                }

            case .rename:
                Text("เปลี่ยนชื่อการ์ด")
                    .font(.sh(15, .semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 4)
                Text("ตั้งชื่อให้จำง่าย เช่น \"ใบส่งสายบิวตี้\"")
                    .font(.sh(11.5, .medium))
                    .foregroundStyle(.white.opacity(0.45))

                TextField("ชื่อการ์ด", text: $renameText)
                    .font(.sh(14.5, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.08)))
                    .submitLabel(.done)
                    .onSubmit { commitRename(record) }

                HStack(spacing: 10) {
                    sheetPill("ยกเลิก") { sheetOpen = false }
                    sheetPill("บันทึก", prominent: true) { commitRename(record) }
                }

            case .confirmDelete:
                Text("ลบ \"\(record.name)\"?")
                    .font(.sh(15, .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1).truncationMode(.middle)
                    .padding(.top, 4)
                Text("ลิงก์ของใบนี้จะใช้ไม่ได้อีก และกู้คืนไม่ได้")
                    .font(.sh(11.5, .medium))
                    .foregroundStyle(.white.opacity(0.45))

                HStack(spacing: 10) {
                    sheetPill("เก็บไว้") { sheetOpen = false }
                    sheetPill("ลบการ์ดนี้", destructive: true) {
                        // ไปที่ใบที่เลื่อนเข้ามาแทนที่ (หรือใบก่อนหน้าถ้าลบใบท้าย) — ต้องเป็น id ใหม่เสมอ
                        // ไม่งั้นตำแหน่งเลื่อนค้างที่เดิมทั้งที่สำรับสั้นลงแล้ว
                        let i = order.firstIndex(of: record.id) ?? 0
                        let remaining = order.filter { $0 != record.id }
                        withAnimation(Motion.settle) {
                            library.delete(record.id)
                            focus = remaining.indices.contains(i) ? remaining[i]
                                  : (remaining.last ?? Self.createID)
                        }
                        Haptics.impact(.medium)
                        sheetOpen = false
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private func commitRename(_ record: CardRecord) {
        withAnimation(Motion.settle) { library.rename(record.id, to: renameText) }
        Haptics.impact(.light)
        sheetOpen = false
    }

    /// แถวคำสั่งในชีต — ไอคอน + ตัวหนังสือฟอนต์แอป บนแผ่นจาง ๆ
    private func sheetRow(_ symbol: String, _ title: String,
                          destructive: Bool = false,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 22)
                Text(title)
                    .font(.sh(14.5, .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(destructive ? SHColor.red : .white.opacity(0.9))
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    /// ปุ่มแคปซูลคู่ท้ายชีต — ยืนยัน/ยกเลิก
    private func sheetPill(_ title: String, prominent: Bool = false,
                           destructive: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.sh(13.5, .semibold))
                .foregroundStyle(destructive || prominent ? .white : .white.opacity(0.75))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Capsule().fill(
                    destructive ? SHColor.red
                    : prominent ? Color.white.opacity(0.18)
                    : Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - คลังว่าง

    /// ปกติจะไม่เห็น — คลังว่างแล้ว `ContentView` พาไปเลือกเทมเพลตเอง · มีไว้กันจอว่างระหว่างสลับ
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(fg.opacity(0.35))
            Text("ยังไม่มีการ์ด")
                .font(.sh(16, .semibold))
                .foregroundStyle(fg.opacity(0.85))
            Button {
                Haptics.impact(.medium)
                onCreate()
            } label: {
                Text("เลือกเทมเพลต")
                    .font(.sh(13.5, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22).padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(SHColor.red))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
    }
}

/// อัตราหน่วงของ `UIScrollView` ใต้สำรับ = `.fast` — อัตราเดียวกับ paging ของระบบ
///
/// SwiftUI ไม่มีตัวปรับนี้ · อัตราปกติไหลยาวแล้วค่อย ๆ คลานเข้าเป้า ปัดทีละใบเลยรู้สึกหนืดและลอย
private struct FastDeceleration: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView { Probe() }
    func updateUIView(_ uiView: UIView, context: Context) {}

    private final class Probe: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
        }
        required init?(coder: NSCoder) { fatalError() }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            var v = superview
            while let s = v, !(s is UIScrollView) { v = s.superview }
            (v as? UIScrollView)?.decelerationRate = .fast
        }
    }
}

/// ภาพนิ่งที่แกะแล้วของแต่ละใบ — แกะครั้งเดียวต่อการแก้หนึ่งครั้ง (ผูกกับ `updatedAt`)
///
/// `CardPage` ได้ id ใหม่ทุกครั้งที่แกะ — แกะใหม่ทุกรอบที่หน้าวาด SwiftUI จึงเห็นเป็นหน้าคนละหน้า
/// แล้ววาดพรีวิวทุกใบใหม่หมด ซึ่งเกิดกลางการปัดทุกครั้งที่ใบกลางจอเปลี่ยน (ปัดแล้วหนืด กระตุก)
/// ไม่ใช่ `@Observable` โดยตั้งใจ — เติมแคชระหว่างวาดต้องไม่สั่งให้วาดใหม่
@MainActor
private final class UnpackCache {
    private var store: [String: (stamp: Date, value: (pages: [CardPage], theme: CardTheme)?)] = [:]

    func restore(_ record: CardRecord) -> (pages: [CardPage], theme: CardTheme)? {
        if let hit = store[record.id], hit.stamp == record.updatedAt { return hit.value }
        let value = record.restored().map { (pages: $0.pages, theme: $0.theme) }
        store[record.id] = (record.updatedAt, value)
        return value
    }
}

/// ปัดหยุดให้ **กลางใบตรงกลางจอ** — ใบในสำรับกว้างไม่เท่ากัน (แนวนอนกว้าง · แนวตั้งแคบ)
///
/// `.viewAligned` ของระบบหยุดที่ขอบซ้ายของใบ ใช้ได้เฉพาะตอนทุกใบกว้างเท่ากัน
/// พอใบกว้างไม่เท่ากัน ใบที่หยุดจะเยื้องไปข้างหนึ่ง · ปัดทีละใบเสมอเหมือนสำรับไพ่
private struct DeckSnap: ScrollTargetBehavior {
    /// ระยะเลื่อนที่ทำให้แต่ละใบอยู่กลางจอ — ใบแรกคือ 0 เพราะหัวแถวเว้นไว้พอดีครึ่งที่เหลือของมัน
    let stops: [CGFloat]

    init(widths: [CGFloat], spacing: CGFloat) {
        let first = widths.first ?? 0
        var run: CGFloat = 0
        var out: [CGFloat] = []
        for w in widths {
            out.append(run + (w - first) / 2)
            run += w + spacing
        }
        stops = out
    }

    /// ใบที่ใกล้ระยะเลื่อนนี้ที่สุด
    func nearest(_ x: CGFloat) -> Int {
        stops.indices.min { abs(stops[$0] - x) < abs(stops[$1] - x) } ?? 0
    }
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        guard !stops.isEmpty else { return }
        let from = nearest(context.originalTarget.rect.minX)
        // ระยะที่ตั้งใจไป = ที่ลากมาแล้ว + แรงสะบัดที่ระบบคาดไว้ — เกินเกณฑ์นิดเดียวก็พลิกใบ เหมือน paging
        // (เดิมตัดสินที่ "ข้ามครึ่งใบหรือยัง" ปัดสั้น ๆ เลยเด้งกลับที่เดิม)
        let moved = target.rect.minX - stops[from]
        let step = moved > Self.flip ? 1 : moved < -Self.flip ? -1 : 0
        target.rect.origin.x = stops[min(max(from + step, 0), stops.count - 1)]
    }

    /// ระยะขั้นต่ำที่นับว่า "ตั้งใจพลิก" — กันนิ้วที่แค่แตะเฉียด ๆ หรือลากเอียงตอนเลื่อนขึ้นลง
    private static let flip: CGFloat = 36
}

#Preview {
    CardGallery(onCreate: {}, onOpen: { _ in })
        .environment(PhotoStore())
        .environment(ClipInvocation())
}
