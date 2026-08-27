import SwiftUI

/// Widget Gallery — **ตู้ที่มีแต่ของ ไม่มีป้ายชื่อ**
///
/// # ทำไมถึงถอดตัวหนังสือออกทั้งหมด
///
/// ของเดิมทุกช่องมีสามชั้นซ้อนกัน: พรีวิว → ชื่อ → ชั้นสิทธิ์ + ปุ่มบวก
/// รวมทั้งหน้าได้ตัวหนังสือเกือบร้อยคำ ทั้งที่คำตอบของคำถามเดียวที่ผู้ใช้ถาม
/// ("มันหน้าตาเป็นยังไง") อยู่ในพรีวิวอยู่แล้ว ตัวหนังสือทั้งหมดจึงเป็นเสียงรบกวน
/// ที่แย่งพื้นที่จากสิ่งเดียวที่ควรได้พื้นที่
///
/// # สองอย่างที่เปลี่ยนแล้วหน้าเปลี่ยนทั้งหน้า
///
/// 1. **พรีวิวมีทรงเท่าของจริง** — เดิมทุกช่องถูกยัดในกรอบ 3:2 เท่ากันหมด
///    ปกนิตยสารที่เป็นทรงตั้งกับแถบวิ่งที่เป็นแถบนอนจึงดูเหมือนของขนาดเดียวกัน
///    ตอนนี้ความสูงคำนวณจากขนาดตั้งต้นบนกริดจริง (`grid.d`) ของก็เลยเรียงเป็น masonry
///    และผู้ใช้เห็น "ทรง" ของมันตั้งแต่ในตู้ ซึ่งเป็นครึ่งหนึ่งของการตัดสินใจ
/// 2. **ช่องเดียว = ปุ่มเดียว** ทั้งช่องคือปุ่มเพิ่ม ไม่มีปุ่มบวกซ้อนอยู่ข้างในอีก
///
/// ตัวหนังสือเหลือที่เดียวคือช่องที่ยัง **ล็อกอยู่** เพราะช่องที่กดไม่ได้ต้องบอกเหตุผล
/// ไม่งั้นมันคือช่องที่พังเฉย ๆ
struct WidgetGallery: View {
    let theme: CardTheme
    let onAdd: (WidgetKind) -> Void
    let onClose: (() -> Void)?
    @Environment(PhotoStore.self) private var photos

    @State private var group: WidgetGroup? = nil

    // อ่านคีย์เดียวกับ `DebugFlags` — ประกาศไว้ที่นี่เพื่อให้ตู้วาดใหม่ทันทีที่สลับสวิตช์
    // (`Mock.catalog` อ่าน UserDefaults ตรง ๆ จึงไม่มีอะไรบอก SwiftUI ให้รีเฟรชเอง)
    @AppStorage(DebugFlags.unlockVerifiedKey) private var unlockVerified = false

    private var entries: [CatalogEntry] {
        // เรียงตามหมวด แล้วตามตระกูล — แบบที่สลับกันได้ต้องอยู่ติดกันในตู้ ไม่กระจัดกระจาย
        let all = (Mock.catalog + Mock.lockedTeasers).sorted { a, b in
            let ag = WidgetGroup.allCases.firstIndex(of: a.kind.group) ?? 0
            let bg = WidgetGroup.allCases.firstIndex(of: b.kind.group) ?? 0
            if ag != bg { return ag < bg }
            let af = WidgetFamily.allCases.firstIndex(of: a.kind.family) ?? 0
            let bf = WidgetFamily.allCases.firstIndex(of: b.kind.family) ?? 0
            if af != bf { return af < bf }
            return a.unlocked && !b.unlocked
        }
        guard let group else { return all }
        return all.filter { $0.kind.group == group }
    }

    /// ขนาดจริงของ widget เมื่อไปนั่งอยู่บนการ์ด (หน่วย pt ที่หน้ากระดาษกว้าง 358)
    ///
    /// คิดจากขนาดตั้งต้นบนกริด (6 คอลัมน์ × 36 แถว) ตรง ๆ ไม่ได้เดาเป็นค่าคงที่ต่อชนิด
    /// เพิ่ม widget ใหม่แล้วตู้ได้ทั้งทรงและขนาดที่ถูกต้องเองทันที
    static func metrics(_ k: WidgetKind) -> (w: CGFloat, h: CGFloat) {
        let (c, r) = k.grid.d
        return (60.9 * CGFloat(max(1, c)) - 7.5, 18.67 * CGFloat(max(1, r)) - 7.5)
    }

    /// ทรงตั้ง = สูงกว่ากว้าง — พวกนี้วางคู่กันสองช่องต่อแถวแล้วยังอ่านออก
    static func isTall(_ k: WidgetKind) -> Bool {
        let m = metrics(k)
        return m.h / m.w >= 0.95
    }

    /// ผังของตู้ — **แนวนอนหนึ่งช่องเต็มแถว · แนวตั้งสองช่องต่อแถว**
    ///
    /// ของแนวนอนอย่างกริดหลักฐานหรือตารางเวลาถูกบีบครึ่งความกว้างเมื่อไหร่ ตัวหนังสือข้างใน
    /// จะเหลือ 5–6pt ซึ่งดูไม่ออกว่ามันคืออะไร — พวกนี้ต้องได้ความกว้างเต็มเพื่อให้พรีวิว
    /// มีขนาดเท่าของจริงบนการ์ด ส่วนทรงตั้งสูงพอที่ครึ่งความกว้างก็ยังอ่านออก
    /// และการวางคู่ทำให้ไม่ต้องเลื่อนยาวเกินจำเป็น
    private var rows: [[CatalogEntry]] {
        var out: [[CatalogEntry]] = []
        var pair: [CatalogEntry] = []
        for e in entries {
            if Self.isTall(e.kind) {
                pair.append(e)
                if pair.count == 2 { out.append(pair); pair = [] }
            } else {
                if !pair.isEmpty { out.append(pair); pair = [] }
                out.append([e])
            }
        }
        if !pair.isEmpty { out.append(pair) }
        return out
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView(showsIndicators: false) {
                #if DEBUG
                if group == nil || group == .work { debugUnlockToggle }
                #endif

                LazyVStack(spacing: 12) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(row) { e in
                                GalleryTile(entry: e, theme: theme) { onAdd(e.kind) }
                            }
                            // แถวที่มีทรงตั้งใบเดียว — กันที่ครึ่งขวาไว้ ไม่ให้มันยืดเต็มแถว
                            if row.count == 1, Self.isTall(row[0].kind) {
                                Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                            }
                        }
                    }
                }
                .padding(.top, 2)
                .padding(.bottom, 8)
            }
        }
        .preferredColorScheme(.dark)
    }

    /// แถวบนสุด — ตัวกรองหมวด กับปุ่มปิด ไม่มีหัวข้อ
    /// ชีตนี้เปิดจากปุ่มบวก ผู้ใช้รู้อยู่แล้วว่ากำลังเพิ่ม widget การเขียนซ้ำไม่ได้บอกอะไรใหม่
    private var topBar: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(nil, "ทั้งหมด")
                    ForEach(WidgetGroup.allCases) { g in
                        chip(g, g.label)
                    }
                }
                .padding(.vertical, 2)
            }
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
        .padding(.bottom, 12)
    }

    /// ชิปกรองหมวด — เหลือแค่คำ ไม่มีไอคอนนำหน้าแล้ว
    /// ไอคอนสี่ตัวที่ไม่มีใครจำความหมายได้ทำให้แถวนี้หนักกว่าที่ควรเป็นเท่านั้นเอง
    private func chip(_ t: WidgetGroup?, _ label: String) -> some View {
        let active = group == t
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { group = t }
        } label: {
            Text(label)
                .font(.sh(13, .semibold))
                .foregroundStyle(active ? .black.opacity(0.85) : .white.opacity(0.66))
                .padding(.horizontal, 15).padding(.vertical, 8)
                .background(Capsule().fill(active ? Color.white.opacity(0.92) : Color.white.opacity(0.07)))
        }
        .buttonStyle(.plain)
    }

    #if DEBUG
    /// สวิตช์สำหรับตอนพัฒนา — ข้ามเงื่อนไข "ส่งงาน 3 ชิ้น" เพื่อดูหน้าตาทั้งตระกูลได้ทันที
    /// ครอบ `#if DEBUG` ไว้ กติกาโปรดักต์จึงไม่ถูกแตะเลยในบิลด์ที่ปล่อยจริง
    ///
    /// เป็น Button ไม่ใช่ Toggle เพราะตู้อยู่ใน ScrollView ซ้อน ScrollView
    /// ซึ่ง UISwitch ข้างใน Toggle จะไม่ได้รับ tap เลย
    private var debugUnlockToggle: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                unlockVerified.toggle()
            }
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "hammer.fill").font(.sh(10))
                Text("ปลดล็อกชั้นหลักฐาน").font(.sh(11, .semibold))
                Spacer(minLength: 6)
                Capsule()
                    .fill(unlockVerified ? Color.orange : Color.white.opacity(0.18))
                    .frame(width: 34, height: 20)
                    .overlay(alignment: unlockVerified ? .trailing : .leading) {
                        Circle().fill(.white).frame(width: 16, height: 16).padding(2)
                    }
            }
            .foregroundStyle(.orange.opacity(0.9))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Capsule().fill(.orange.opacity(unlockVerified ? 0.16 : 0.08)))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 11)
    }
    #endif
}

// MARK: - ช่องเดียวในตู้

/// หนึ่ง widget = หนึ่งช่อง = หนึ่งปุ่ม · ไม่มีชื่อ ไม่มีป้ายชั้นสิทธิ์ ไม่มีปุ่มบวกซ้อนข้างใน
private struct GalleryTile: View {
    let entry: CatalogEntry
    let theme: CardTheme
    let onAdd: () -> Void

    @State private var pressed = false

    /// ขนาดจริงของ widget ตัวนี้บนการ์ด — ใช้ทั้งกำหนดทรงของช่องและกำหนดสเกลของพรีวิว
    private var metrics: (w: CGFloat, h: CGFloat) { WidgetGallery.metrics(entry.kind) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return Color.clear
            .aspectRatio(metrics.w / metrics.h, contentMode: .fit)
            .overlay { preview }
            .background(shape.fill(.white.opacity(0.05)))
            .clipShape(shape)
            .overlay(shape.strokeBorder(.white.opacity(0.09), lineWidth: 0.5))
            .overlay { if !entry.unlocked { lockedVeil(shape) } }
            .scaleEffect(pressed ? 0.96 : 1)
            .animation(Motion.snap, value: pressed)
            .contentShape(shape)
            .onTapGesture {
                guard entry.unlocked else { Haptics.rigid(); return }
                onAdd()
            }
            // กดค้างแล้วช่องยุบตาม — ตอบสนองที่หายไปพร้อมปุ่มบวกต้องมีอะไรมาแทน
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 40) {
            } onPressingChanged: { pressed = $0 }
    }

    /// เรนเดอร์ที่ **ความกว้างจริงของ widget** แล้วค่อยสเกลทั้งก้อนให้พอดีช่อง
    ///
    /// สำคัญที่ "ความกว้างจริง" ไม่ใช่ค่าคงที่ค่าเดียวทั้งตู้: โพลารอยด์กว้าง 3 คอลัมน์
    /// ถ้าเรนเดอร์ที่ความกว้าง 6 คอลัมน์แล้วย่อ มันจะกลายเป็นการ์ดที่ถูกยืดออก ไม่ใช่ของจริงย่อส่วน
    /// ตัวแนวนอนที่ได้เต็มแถวจะได้สเกล ≈ 1 คือเห็นเท่าที่จะเห็นบนการ์ดเป๊ะ ๆ
    private var preview: some View {
        GeometryReader { geo in
            let vw = metrics.w
            let vh = metrics.h
            let scale = geo.size.width / vw
            // ตัวที่ **รูปคือพื้นผิว** ปล่อยให้เต็มช่อง · ที่เหลือต้องมีขอบหายใจเท่ากับตอนอยู่บนการ์ด
            //
            // เคยใช้ `isPlain` เป็นเงื่อนไข แล้วพวก typography ไร้กรอบ (ชื่อมินิมอล · แนะนำตัว · ชิป)
            // ถูกดันไปชนขอบช่องจนตัวหนังสือโดนตัดข้าง — พวกนั้นไม่มีพื้นผิวของตัวเอง
            // สิ่งที่มันมีคือระยะขอบของหน้ากระดาษ ซึ่งช่องในตู้ต้องจำลองให้ด้วย
            let inset: CGFloat = entry.kind.isFullBleed || entry.kind.usesPhoto ? 0 : 14
            // ขนาดที่ส่งให้ `WidgetBody` ต้องเป็นขนาด **หลังหักขอบ** ไม่ใช่ขนาดช่อง
            // ไม่งั้นตัวที่คำนวณผังจาก size (เช่นกริดหลักฐาน) จะเผื่อที่ไว้เกินจริงแล้วล้นออกนอกกรอบ
            WidgetBody(kind: entry.kind, theme: theme,
                       size: CGSize(width: vw - inset * 2, height: vh - inset * 2))
                .padding(inset)
                .frame(width: vw, height: vh, alignment: .topLeading)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .allowsHitTesting(false)
        .opacity(entry.unlocked ? 1 : 0.18)
    }

    /// ช่องที่ยังกดไม่ได้ — ที่เดียวในตู้ที่ยังมีตัวหนังสือ เพราะต้องบอกว่าทำยังไงถึงจะได้มา
    private func lockedVeil(_ shape: RoundedRectangle) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.sh(14, .semibold))
                .foregroundStyle(.white.opacity(0.75))
            Text(entry.requirement ?? "")
                .font(.sh(10.5, .semibold))
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shape.fill(.black.opacity(0.25)))
    }
}
