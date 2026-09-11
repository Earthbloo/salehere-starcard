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
    let onClose: (() -> Void)?
    @Environment(PhotoStore.self) private var photos

    /// หมวดหลักที่เปิดอยู่ — ไม่มีสถานะ "ทั้งหมด" เพราะนั่นคือสิ่งที่ทำให้เลื่อนหาไม่เจอ
    @State private var group: WidgetGroup = .about
    /// ความกว้างของหนึ่งคอลัมน์ — วัดจากของจริงครั้งเดียว ค่าตั้งต้นพอให้เฟรมแรกไม่พัง
    @State private var colW: CGFloat = 160

    private let gap: CGFloat = 12

    private var all: [CatalogEntry] {
        (Mock.catalog + Mock.lockedTeasers).sorted { a, b in
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
        for e in all where e.kind.group == group {
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
            bar
            tabs
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(sections) { sec in
                            sectionHeader(sec.label)
                            // `.flexible()` ไม่ใช่ `.fixed()` — ตัวหลังพังทันทีถ้าความกว้างเป็น 0
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: gap, alignment: .top),
                                                GridItem(.flexible(), spacing: gap, alignment: .top)],
                                      alignment: .leading, spacing: gap) {
                                ForEach(sec.entries) { e in
                                    GalleryTile(entry: e, theme: theme, colWidth: colW) {
                                        onAdd(e.kind)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                // เปลี่ยนแท็บแล้วต้องกลับไปบนสุดเสมอ ไม่งั้นจะโผล่กลางกองของหมวดใหม่
                .id(group)
                // วัดความกว้างด้วย `.onGeometryChange` ไม่ใช่ `GeometryReader`
                //
                // GeometryReader **กินความสูงทั้งหมดที่มี** ซึ่งบนชีตที่สูงตามเนื้อหา
                // แปลว่ามันได้ความสูง 0 แล้วทั้งตู้ว่างเปล่า (เจอมาสองรอบ)
                // ตัวนี้อ่านขนาดโดยไม่แตะผัง จึงวัดได้โดยไม่ทำให้อะไรพัง
                .background(alignment: .top) {
                    Color.clear
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { w in
                            if w > 1 { colW = max(120, (w - gap) / 2) }
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

    /// แท็บสามแท็บแบ่งเต็มความกว้าง — ไม่เลื่อน ไม่มีอะไรซ่อน
    ///
    /// เป็นเส้นใต้ ไม่ใช่แคปซูลทึบ เพราะแคปซูลสามใบเรียงกันอ่านเป็น "ปุ่มสามปุ่ม"
    /// ส่วนเส้นใต้อ่านเป็น "ตอนนี้อยู่หน้าไหน" ซึ่งตรงกับหน้าที่ของมันจริง ๆ
    private var tabs: some View {
        HStack(spacing: 0) {
            ForEach(WidgetGroup.allCases) { g in
                let active = group == g
                Button {
                    Haptics.impact(.light)
                    // **ห้ามใส่ `withAnimation` ตรงนี้** — ScrollView ผูก `.id(group)` ไว้
                    // เปลี่ยนแท็บ = สร้าง view ใหม่ทั้งก้อน ถ้าสั่งอนิเมต SwiftUI จะ cross-fade
                    // ของเก่ากับของใหม่ แล้วโลโก้แบรนด์จากแท็บก่อนหน้าค้างซ้อนอยู่ (เจอมาแล้ว)
                    group = g
                } label: {
                    VStack(spacing: 9) {
                        Text(g.label)
                            .font(.sh(14, active ? .bold : .medium))
                            .foregroundStyle(.white.opacity(active ? 0.96 : 0.42))
                            .lineLimit(1)
                        Capsule()
                            .fill(active ? Color.white.opacity(0.9) : .clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // อนิเมตเฉพาะเส้นใต้ ไม่ใช่ทั้งรายการ
                .animation(Motion.snap, value: group)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
        }
    }

    /// หัวข้อคั่นตระกูล — เงียบที่สุดเท่าที่ยังอ่านออก
    /// ตู้นี้ "ของ" คือพระเอก หัวข้อมีหน้าที่เดียวคือบอกว่ากองนี้เริ่มตรงไหน
    private func sectionHeader(_ label: String) -> some View {
        Text(label)
            .font(.sh(12, .heavy))
            .foregroundStyle(.white.opacity(0.4))
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
    private var scale: CGFloat {
        min(max(colWidth / metrics.w, Self.scaleRange.lowerBound), Self.scaleRange.upperBound)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        // **ไม่มีพื้นและไม่มีขอบของช่อง** — เดิมทุกใบถูกครอบด้วยแผ่นขาวจาง + เส้นขอบ
        // ซึ่งเป็นเปลือกที่ไม่มีอยู่จริงบนการ์ด ผลคือวิดเจ็ตที่ตั้งใจให้ไม่มีกรอบ
        // (ตัวหนังสือล้วน · ชิปลอย · สติกเกอร์) ดูมีกรอบไปหมดทั้งตู้ แล้วผู้ใช้เลือกผิด
        // ตู้ต้องแสดง "ของ" ไม่ใช่ "ของในกล่องของตู้"
        return preview
            .overlay { if !entry.unlocked { lockedVeil(shape) } }
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
        return WidgetBody(kind: entry.kind, theme: theme,
                          size: CGSize(width: vw - inset * 2, height: vh - inset * 2))
            .padding(inset)
            .frame(width: vw, height: vh, alignment: .topLeading)
            .scaleEffect(scale, anchor: .center)
            // จัดกลางช่อง ไม่ใช่ชิดมุม — ใบที่ถูกกดสเกลลงจะมีที่ว่างรอบตัว
            // ถ้าชิดมุมบนซ้าย ที่ว่างจะไปกองอยู่ข้างเดียวแล้วกริดดูเอียง
            .frame(width: colWidth, height: max(Self.minHeight, vh * scale))
            .allowsHitTesting(false)
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
}
