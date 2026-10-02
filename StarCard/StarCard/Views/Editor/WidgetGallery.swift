import SwiftUI

/// Widget Gallery — **แท็บสามหมวด · กริดสองคอลัมน์ · เห็นหลายใบพร้อมกัน**
///
/// # ห้ารอบที่ผ่านมา
///
/// | รอบ | ทำอะไร | พังตรงไหน |
/// |---|---|---|
/// | 1 | กริดสองใบ/แถว + ชิปกรองหมวดเดียว | ชิปเบียด |
/// | 2 | ชิปสองแถว หมวดหลัก + หมวดย่อย | 19 ปุ่มก่อนเห็นของสักชิ้น |
/// | 3 | รายการหมวด แล้วเจาะเข้าไป | ต้องแตะก่อนถึงจะเห็นวิดเจ็ต |
/// | 4 | เลื่อนเดียวยาว ๆ ทั้ง 38 ใบ | เลื่อนหาไม่เจอ |
/// | 5 | แท็บสามหมวด ใบละแถวเต็มความกว้าง | **ใบใหญ่จนเห็นทีละใบ** |
///
/// # สิ่งที่เรียนรู้ครบแล้ว
///
/// การเลือกวิดเจ็ตคือการ **เทียบของหลายชิ้น** ไม่ใช่การอ่านทีละชิ้น
/// พรีวิวจึงไม่ต้องอ่านออกทุกตัวอักษร ขอแค่ **จำทรงกับองค์ประกอบได้** ก็พอตัดสินใจแล้ว
/// — ของที่อ่านออกเต็ม ๆ คือของบนการ์ดจริง ไม่ใช่ของในตู้
///
/// กริดสองคอลัมน์จึงเป็นคำตอบ: ใบกว้าง 6 คอลัมน์ย่อเหลือ ~0.48 เห็นทรงครบ ·
/// ใบทรงตั้ง 3 คอลัมน์ได้สเกลเกือบ 1:1 พอดีคอลัมน์ · เห็นพร้อมกัน 4–6 ใบต่อหน้าจอ
struct WidgetGallery: View {
    let theme: CardTheme
    let onAdd: (WidgetKind) -> Void
    /// ช่องที่ผูกกับหัวข้อ Star Profile ที่ยังไม่ได้กรอก — ผู้เรียกพาไปกรอกข้อนั้น แล้วค่อยเพิ่มใบนี้ให้
    var onFill: (WidgetKind, StarTopic) -> Void = { _, _ in }
    let onClose: (() -> Void)?
    /// หัวตู้ (ชื่อ + ปุ่มปิด) — ปิดเมื่อตู้อยู่ในถาดของแถบล่าง ซึ่งมี ‹ กับชื่อโหมดอยู่แล้ว
    var showsBar = true
    @Environment(PhotoStore.self) private var photos
    /// อ่านเพื่อให้ตู้วาดใหม่เมื่อกรอกหัวข้อเสร็จ (ช่องที่เคยล็อกเปิดทันที)
    @State private var flow = StarFlow.shared

    /// ชิปที่เลือกล่าสุด — ใช้กระโดดไปหมวดนั้นในรายการยาว (รายการเดียว เลื่อนดูได้ทั้งตู้)
    @State private var group: TrayGroup = .profile
    /// ความกว้างของหนึ่งคอลัมน์ — วัดจากของจริงครั้งเดียว ค่าตั้งต้นพอให้เฟรมแรกไม่พัง
    @State private var colW: CGFloat = 160

    private let gap: CGFloat = 12

    private var all: [CatalogEntry] {
        // ก้อนข้อความมีปุ่มของตัวเองบนแถบล่าง — สองทางเข้าสำหรับของชิ้นเดียวคือความงงที่ไม่จำเป็น
        (Mock.catalog + Mock.lockedTeasers).filter { $0.kind != .textBlock }.sorted { a, b in
            let af = WidgetFamily.allCases.firstIndex(of: a.kind.family) ?? 0
            let bf = WidgetFamily.allCases.firstIndex(of: b.kind.family) ?? 0
            if af != bf { return af < bf }
            return a.unlocked && !b.unlocked
        }
    }

    /// ก้อนหนึ่งตระกูล — `id` เป็น rawValue ของตระกูล จึงไม่ซ้ำกันทั้งลิสต์
    /// (เคยใช้ลำดับ 0,1,2… เป็น id แล้ว `LazyVStack` รีไซเคิลเซลล์ผิดใบมาแล้วรอบหนึ่ง)
    private struct Section: Identifiable {
        let id: String
        let label: String
        let entries: [CatalogEntry]
    }

    private var sections: [Section] {
        var out: [Section] = []
        let ordered = all.sorted { a, b in
            let ag = TrayGroup.allCases.firstIndex(of: a.kind.family.trayGroup) ?? 0
            let bg = TrayGroup.allCases.firstIndex(of: b.kind.family.trayGroup) ?? 0
            return ag != bg ? ag < bg : (WidgetFamily.allCases.firstIndex(of: a.kind.family) ?? 0) < (WidgetFamily.allCases.firstIndex(of: b.kind.family) ?? 0)
        }
        for e in ordered where e.kind.family.trayGroup == group {
            if let last = out.last, last.id == e.kind.family.rawValue {
                out[out.count - 1] = Section(id: last.id, label: last.label,
                                             entries: last.entries + [e])
            } else {
                out.append(Section(id: e.kind.family.rawValue,
                                   label: e.kind.family.label, entries: [e]))
            }
        }
        return out
    }

    /// ขนาดจริงของ widget เมื่อไปนั่งอยู่บนการ์ด — หน่วย pt บนพื้นที่ออกแบบ
    /// (ตัวเรียกย่อลงให้พอดีช่องในตู้เอง ดู `GalleryTile.colWidth`)
    static func metrics(_ k: WidgetKind) -> (w: CGFloat, h: CGFloat) {
        let s = k.defaultSize
        return (max(1, s.width), max(1, s.height))
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsBar { bar }
            chips
                .padding(.bottom, 12)

            // แต่ละชิป = รายการของหมวดนั้น (ไม่ใช่กระโดดในรายการยาว — `scrollTo` แบบมี animation
            // ลงไปหา section ที่ LazyVStack ยังไม่สร้าง ทำแอปค้าง 24 ก.ย. 2569)
            Group {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(sections) { sec in
                            let topic = sec.entries.first?.kind.family.topic
                            sectionHeader(sec.label, missing: topic.flatMap { $0.filled ? nil : $0 })
                                .id(sec.id)
                            // `.flexible()` ไม่ใช่ `.fixed()` — ตัวหลังพังทันทีถ้าความกว้างเป็น 0
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: gap, alignment: .top),
                                                GridItem(.flexible(), spacing: gap, alignment: .top)],
                                      alignment: .leading, spacing: gap) {
                                ForEach(sec.entries) { e in
                                    let topic = e.kind.family.topic
                                    let missing = topic.map { !$0.filled } ?? false
                                    GalleryTile(entry: e, theme: theme, colWidth: colW,
                                                missingTopic: missing ? topic : nil) {
                                        if let topic, missing { onFill(e.kind, topic) } else { onAdd(e.kind) }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                // เปลี่ยนหมวดแล้วกลับไปบนสุดเสมอ (สร้างรายการใหม่ ไม่ cross-fade ของเก่า)
                .id(group)
                // วัดความกว้างด้วย `.onGeometryChange` ไม่ใช่ `GeometryReader`
                //
                // GeometryReader **กินความสูงทั้งหมดที่มี** ซึ่งบนชีตที่สูงตามเนื้อหา
                // แปลว่ามันได้ความสูง 0 แล้วทั้งตู้ว่างเปล่า (เจอมาสองรอบ)
                // ตัวนี้อ่านขนาดโดยไม่แตะผัง จึงวัดได้โดยไม่ทำให้อะไรพัง
                .background(alignment: .top) {
                    Color.clear
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { w in
                            // อัปเดตเฉพาะเมื่อกว้างต่างจริง — ระหว่างหน้าถูกย่อ/ขยาย (เปิด sheet) ค่าเปลี่ยนทุกเฟรม
                            // แล้วขนาดช่องเปลี่ยน → วัดใหม่ → วนไม่จบ
                            let next = max(120, (w - gap) / 2)
                            if w > 1, abs(next - colW) > 0.5 { colW = next }
                        }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var bar: some View {
        HStack(spacing: 12) {
            Text("เพิ่มวิดเจ็ต")
                .font(.sh(17, .bold))
                .foregroundStyle(.white.opacity(0.95))
            Spacer(minLength: 4)
            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.sh(11, .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 16)
    }

    /// ชิปหมวดเลื่อนแนวนอน = หัวข้อ Star Profile (ลำดับเดียวกับที่การ์ดเล่าเรื่อง)
    ///
    /// หมวดที่ยังไม่มีข้อมูล = ขอบประสีเน้น + จุดเล็ก ให้เห็นตั้งแต่แถวชิปว่าอะไรยังขาด
    /// แตะชิป = เลื่อนไปหมวดนั้นในรายการเดียวกัน (ไม่ใช่สลับหน้า) ของทั้งตู้ยังเลื่อนดูต่อได้
    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TrayGroup.allCases) { g in
                    let active = group == g
                    let missing = g.topic.map { !$0.filled } ?? false
                    Button {
                        Haptics.impact(.light)
                        // **ห้ามใส่ `withAnimation`** — ScrollView ผูก `.id(group)` ไว้ อนิเมตแล้วของเก่าค้างซ้อน
                        group = g
                    } label: {
                        HStack(spacing: 5) {
                            if missing {
                                Circle().fill(theme.accent).frame(width: 6, height: 6)
                            }
                            Text(g.label).font(.sh(13, active ? .bold : .semibold))
                        }
                        .foregroundStyle(active ? .black : .white.opacity(missing ? 0.8 : 0.9))
                        .padding(.horizontal, 13).frame(height: 34)
                        .background(Capsule().fill(active ? Color.white : Color.white.opacity(0.1)))
                        .overlay(Capsule().strokeBorder(missing && !active ? theme.accent.opacity(0.8) : .clear,
                                                        style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .animation(Motion.snap, value: group)
    }

    /// หัวข้อคั่นตระกูล — เงียบที่สุดเท่าที่ยังอ่านออก
    /// ตู้นี้ "ของ" คือพระเอก หัวข้อมีหน้าที่เดียวคือบอกว่ากองนี้เริ่มตรงไหน
    private func sectionHeader(_ label: String, missing: StarTopic? = nil) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.sh(12, .heavy))
                .foregroundStyle(.white.opacity(0.4))
            if let missing {
                // ทั้งตระกูลรอหัวข้อเดียวกัน — บอกครั้งเดียวที่หัว ไม่ต้องอ่านซ้ำทุกใบ
                Text(missing.fillable ? "\(missing.missingLine) · แตะใบไหนก็ได้เพื่อกรอก" : missing.missingLine)
                    .font(.sh(11, .semibold))
                    .foregroundStyle(theme.accent.opacity(0.9))
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 11)
    }
}

// MARK: - พรีวิวหนึ่งใบ

/// ทั้งช่องคือปุ่มเพิ่ม · ไม่มีปุ่มบวกซ้อนอยู่ข้างในอีก
private struct GalleryTile: View {
    let entry: CatalogEntry
    let theme: CardTheme
    /// ความกว้างของคอลัมน์ที่ช่องนี้อยู่ — วัดครั้งเดียวที่ระดับกริดแล้วส่งลงมา
    let colWidth: CGFloat
    /// หัวข้อ Star Profile ที่ใบนี้ต้องใช้แต่ยังไม่ได้กรอก — nil = ใช้ได้เลย
    var missingTopic: StarTopic? = nil
    let onAdd: () -> Void

    @State private var pressed = false

    private var metrics: (w: CGFloat, h: CGFloat) { WidgetGallery.metrics(entry.kind) }

    /// สเกลที่ยอมให้พรีวิวย่อ/ขยายได้
    ///
    /// # ทำไมต้องคุมช่วง
    ///
    /// เดิมทุกใบถูกย่อให้ "เต็มคอลัมน์" พอดี ซึ่งแปลว่า **สเกลไม่เท่ากันสักใบ**:
    /// ใบกว้าง 6 คอลัมน์ (358pt) ย่อเหลือ 0.48 · ใบทรงตั้ง 3 คอลัมน์ (175pt) ได้ 0.99
    /// สองเท่าพอดี — ตัวหนังสือในใบแรกเลยเล็กครึ่งหนึ่งของใบหลังทั้งที่บนการ์ดจริงเท่ากัน
    ///
    /// ผลคือใบเล็กดู "ใหญ่เกิน" และใบใหญ่ดู "เล็กเกิน" ทั้งที่ไม่มีใบไหนผิดขนาดเลย
    /// สิ่งที่ผิดคือกติกา "ต้องเต็มคอลัมน์" ซึ่งไม่มีเหตุผลรองรับนอกจากความเรียบร้อยของกริด
    ///
    /// ตอนนี้บีบช่วงไว้ที่ 0.45–0.62 — ใบกว้างยังได้ 0.48 เท่าเดิม (ลดไม่ได้ คอลัมน์แค่นั้น)
    /// แต่ใบทรงตั้งถูกกดจาก 0.99 ลงมาที่ 0.62 แล้วจัดกลางคอลัมน์แทนการยืดเต็ม
    /// ส่วนต่างของ "ขนาดที่เห็น" จึงเหลือ 1.3 เท่า จากเดิม 2 เท่า
    private static let scaleRange: ClosedRange<CGFloat> = 0.45...0.62

    /// ความสูงขั้นต่ำของช่อง — ใบเตี้ยมาก (แถบติดต่อ 6×4) ย่อแล้วเหลือ ~30pt
    /// ซึ่งบางจนอ่านไม่ออกว่าเป็นอะไร ให้พื้นที่หายใจขั้นต่ำแล้วจัดเนื้อหาไว้กลาง
    private static let minHeight: CGFloat = 58

    /// สเกลจริงที่ใช้ — ตัวเดียวกันทั้งวัดความสูงและวาด จึงไม่มีทางคำนวณเหลื่อมกัน
    ///
    /// เพดานสุดท้ายคือ **ความกว้างของคอลัมน์** — ใบที่กว้างเกินหน้าปกติ (แผ่นสติกเกอร์สามช่อง ·
    /// หน้าต่างช่องทาง กว้าง 504) โดนพื้น 0.45 ดันให้ล้นคอลัมน์ไปถูกตัดขอบทั้งสองข้าง
    private var scale: CGFloat {
        min(max(colWidth / metrics.w, Self.scaleRange.lowerBound), Self.scaleRange.upperBound,
            colWidth / metrics.w)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        // **ไม่มีพื้นและไม่มีขอบของช่อง** — เดิมทุกใบถูกครอบด้วยแผ่นขาวจาง + เส้นขอบ
        // ซึ่งเป็นเปลือกที่ไม่มีอยู่จริงบนการ์ด ผลคือวิดเจ็ตที่ตั้งใจให้ไม่มีกรอบ
        // (ตัวหนังสือล้วน · ชิปลอย · สติกเกอร์) ดูมีกรอบไปหมดทั้งตู้ แล้วผู้ใช้เลือกผิด
        // ตู้ต้องแสดง "ของ" ไม่ใช่ "ของในกล่องของตู้"
        return preview
            // ยังไม่มีข้อมูลของหัวข้อนี้: พรีวิวยังเป็นใบจริงพร้อมข้อมูลตัวอย่าง (ผู้ใช้ 23 ก.ย.: "ต้อง preview
            // widget ไปเลย ให้เห็นว่าคือ widget อะไร ถ้าอยากได้ เค้าก็จะกรอก") — แท่งว่างบอกไม่ได้ว่าใบนี้คืออะไร
            .overlay { if !entry.unlocked { lockedVeil(shape) } }
            .overlay { if let t = missingTopic, entry.unlocked { fillFrame(shape, t) } }
            .scaleEffect(pressed ? 0.96 : 1)
            .animation(Motion.snap, value: pressed)
            .contentShape(Rectangle())
            .onTapGesture {
                guard entry.unlocked else { Haptics.rigid(); return }
                Haptics.impact(.light)
                onAdd()
            }
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 40) {
            } onPressingChanged: { pressed = $0 }
    }

    /// เรนเดอร์ที่ **ขนาดจริงของ widget** แล้วค่อยย่อทั้งก้อน
    ///
    /// ห้ามเรนเดอร์ที่ความกว้างของคอลัมน์ตรง ๆ — วิดเจ็ตหลายตัวสลับผังตามความกว้าง
    /// (กริดสองคอลัมน์เป็นคอลัมน์เดียว · ชิปขึ้นบรรทัดใหม่) พรีวิวจะไม่ใช่ของจริงย่อส่วนอีกต่อไป
    private var preview: some View {
        let vw = metrics.w
        let vh = metrics.h
        // ตัวที่ **รูปคือพื้นผิว** ปล่อยให้เต็มช่อง · ที่เหลือต้องมีขอบหายใจเท่ากับตอนอยู่บนการ์ด
        let inset: CGFloat = entry.kind.isFullBleed || entry.kind.usesPhoto ? 0 : 14
        // ตัวที่ได้แผ่นจาก chrome ตอนลงการ์ด ต้องเห็นแผ่นนั้นในตู้ด้วย — ไม่งั้นตู้โชว์ตัวหนังสือลอย ๆ
        // แล้วของที่หยิบลงไปมีกล่อง ซึ่งเป็นคนละใบกับที่เลือก (ดู `WidgetKind.drawsOwnSurface`)
        let panelled = !entry.kind.drawsOwnSurface
        return WidgetBody(kind: entry.kind, theme: theme,
                          size: CGSize(width: vw - inset * 2, height: vh - inset * 2))
            .padding(inset)
            // ยังไม่มีข้อมูลของหัวข้อนี้ = เห็นใบเต็ม ๆ ด้วยชุดตัวอย่าง (`Profile.shown…`) — กรอกแล้วจะได้หน้าตานี้
            // ตระกูลที่ไม่มีชุดตัวอย่าง (ข้อความที่พิมพ์เอง) ค่าของผู้ใช้ยังเป็นขีด "–"
            .environment(\.ghostData, missingTopic != nil && !Profile.me.lacks(entry.kind.family))
            .environment(\.sampleData, missingTopic != nil || Profile.me.lacks(entry.kind.family))
            .modifier(GalleryPanel(on: panelled))
            .frame(width: vw, height: vh, alignment: .topLeading)
            .scaleEffect(scale, anchor: .center)
            // จัดกลางช่อง ไม่ใช่ชิดมุม — ใบที่ถูกกดสเกลลงจะมีที่ว่างรอบตัว
            // ถ้าชิดมุมบนซ้าย ที่ว่างจะไปกองอยู่ข้างเดียวแล้วกริดดูเอียง
            .frame(width: colWidth, height: max(Self.minHeight, vh * scale))
            .allowsHitTesting(false)
            // ยังใช้ไม่ได้ = ใบเป็นขาวดำและจาง (ผู้ใช้ 24 ก.ย.: "ต้องมี alpha เทา ๆ ว่ายังใช้ไม่ได้ หรือรูปกุญแจ")
            .opacity(entry.unlocked ? 1 : 0.18)
    }

    /// ช่องที่ยังกดไม่ได้ — ต้องบอกว่าทำยังไงถึงจะได้มา ไม่งั้นมันคือช่องที่พังเฉย ๆ
    private func lockedVeil(_ shape: RoundedRectangle) -> some View {
        VStack(spacing: 5) {
            Image(systemName: "lock.fill")
                .font(.sh(13, .semibold))
                .foregroundStyle(.white.opacity(0.75))
            Text(entry.requirement ?? "")
                .font(.sh(9.5, .semibold))
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shape.fill(.black.opacity(0.25)))
    }

    /// ใบที่รอหัวข้อ Star Profile: กรอบประสีเน้นของการ์ด + ป้าย "+ กรอก…" คร่อมขอบล่าง
    ///
    /// ภาษาเดียวกับช่องประบนหน้า Star Profile (ขาด = เส้นประ · ปุ่มเพิ่มสีถ่าน) ผู้ใช้เจอที่นั่นมาก่อนแล้ว
    /// ไม่มีม่านทึบทับพรีวิว — พรีวิวคือเหตุผลที่คนอยากกรอก ต้องเห็นชัด
    private func fillFrame(_ shape: RoundedRectangle, _ t: StarTopic) -> some View {
        // สีเต็มเหมือนเดิม แค่ม่านจาง ๆ ทับ + กุญแจ (ผู้ใช้ 24 ก.ย.: "ไม่เอาขาวดำ แค่มีม่านจาง ๆ")
        shape
            .fill(.black.opacity(0.42))
            .overlay(shape.strokeBorder(theme.accent.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])).padding(-3))
            .overlay(alignment: .topTrailing) {
                // กุญแจล็อกมุมขวาบน — เห็นตั้งแต่ไกลว่าใบนี้ยังหยิบไม่ได้
                Image(systemName: "lock.fill").font(.sh(11, .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(.black.opacity(0.7)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 0.8))
                    .padding(6)
            }
            .overlay(alignment: .bottom) {
                HStack(spacing: 4) {
                    Image(systemName: t.fillable ? "plus" : "lock.fill").font(.sh(10, .heavy))
                    Text(t.action).font(.sh(11, .bold))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 10).frame(height: 26)
                .background(Capsule().fill(.white))
                .overlay(Capsule().strokeBorder(theme.accent.opacity(0.9), lineWidth: 1.2))
                .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
                .offset(y: 10)
            }
    }
}

/// แผ่นของพรีวิวในตู้ — เปิดเฉพาะชิ้นที่ `WidgetChrome` จะวาดแผ่นให้ตอนอยู่บนการ์ด
private struct GalleryPanel: ViewModifier {
    let on: Bool

    func body(content: Content) -> some View {
        if on {
            GlassPanel(radius: 18) { content }
        } else {
            content
        }
    }
}
