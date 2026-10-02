import SwiftUI

// MARK: - แถบเครื่องมือล่าง (dock) กับถาดตัวเลือก
//
// # กติกาสามข้อที่ผู้ใช้ต้องรู้ — และโค้ดนี้ต้องไม่ทำอะไรนอกเหนือจากนี้
//
// 1. **แถบหลักมีสามปุ่ม** (พื้นหลัง · ข้อความ · วิดเจ็ต) — โผล่เฉพาะตอนไม่มีอะไรเปิดอยู่
// 2. **กดอะไรก็ตาม (ปุ่มหลัก · ชิ้นบนการ์ด) = แถบหลักหายไป มีชีตขึ้นมาแทน** ชีตมีหัว: ปุ่ม ‹ กับชื่อ
//    ทุกอย่างของเรื่องนั้นอยู่ในชีตใบเดียว เห็นครบ ไม่เลื่อน ไม่มีแท็บย่อย
//    (เคยให้แถบหลักอยู่ใต้ชีตด้วย — สองแถบซ้อนกันอ่านไม่ออกว่าอันไหนคือของเรื่องที่เปิดอยู่)
// 3. **‹ หรือแตะที่ว่างบนการ์ด = ปิดชีต กลับแถบหลัก**
//
// # ทำไมไม่ใช่ `.sheet`
//
// ชีตเป็นชั้นแยกของระบบ: ทัชเหลื่อมเมื่อเนื้อหาล้น · ต้องมี detent หลายระดับให้ลากขึ้นลง ·
// ตู้วิดเจ็ตต้องซ้อนชีตบนชีต · และ `matchedGeometryEffect` ข้ามไปหาการ์ดไม่ได้
// dock กับถาดเป็นวิวธรรมดาในหน้าเดียวกับการ์ด ปัญหาทั้งกลุ่มนั้นจึงไม่มีตั้งแต่ต้น

/// แถบล่างอยู่ที่ไหน — ค่าเดียวที่บอกว่าตอนนี้กำลังทำอะไรอยู่
enum DockMode: Equatable {
    /// แถบหลัก — ยังไม่ได้เลือกอะไร
    case main
    /// พื้นหลังของทั้งการ์ด (สี · รูป · โทน)
    case backdrop
    /// ตู้วิดเจ็ต
    case gallery
    /// ชิ้นที่เลือกอยู่ — ทุกชิ้นบนหน้ายังอยู่ที่เดิม
    case piece(UUID)
    /// กำลังพิมพ์ก้อนข้อความ — ชิ้นอื่นหลบ คีย์บอร์ดขึ้น
    case text(UUID)

    var selectedID: UUID? {
        switch self {
        case .piece(let id), .text(let id): return id
        default: return nil
        }
    }

    var isMain: Bool {
        if case .main = self { return true }
        return false
    }

    var isText: Bool {
        if case .text = self { return true }
        return false
    }
}

/// สามปุ่มของแถบหลัก
enum DockMainItem: String, CaseIterable, Identifiable {
    case backdrop, text, widget
    var id: String { rawValue }

    var label: String {
        switch self {
        case .backdrop: return "พื้นหลัง"
        case .text:     return "ข้อความ"
        case .widget:   return "วิดเจ็ต"
        }
    }

    var symbol: String {
        switch self {
        case .backdrop: return "paintpalette.fill"
        case .text:     return "textformat"
        case .widget:   return "plus.square.on.square"
        }
    }
}

/// แถบหลัก — แคปซูลกระจกใบเดียว สามปุ่ม
struct EditorDock: View {
    /// ปุ่มที่กดแล้วไม่เกิดผล (การ์ดเต็ม) — จาง แต่ยังกดได้เพื่อรับคำอธิบาย
    var dimmed: Set<DockMainItem> = []
    let onMain: (DockMainItem) -> Void

    private let h: CGFloat = 58

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DockMainItem.allCases) { item in
                let dim = dimmed.contains(item)
                Button { onMain(item) } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(height: 22)
                        Text(item.label).font(.sh(10.5, .semibold))
                    }
                    .foregroundStyle(.white.opacity(dim ? 0.32 : 0.92))
                    .frame(maxWidth: .infinity)
                    .frame(height: h)
                    .contentShape(Rectangle())
                }
                .buttonStyle(DockPress())
            }
        }
        .padding(.horizontal, 6)
        .frame(height: h)
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, 16)
        .environment(\.colorScheme, .dark)
    }
}

/// กดแล้วย่อนิดเดียว — ตอบไวด้วย `snap` ไม่มีไฮไลต์ซ้อน
struct DockPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(Motion.snap, value: configuration.isPressed)
    }
}

// MARK: - ชีต

/// ชีตของเรื่องหนึ่งเรื่อง — หัวมี ‹ กับชื่อ ข้างล่างคือตัวเลือกทั้งหมดของเรื่องนั้น · มาแทนแถบหลักทั้งใบ
///
/// ชื่อคือ **เรื่อง** ไม่ใช่ชื่อแบบของชิ้น — "โปรไฟล์" ไม่ใช่ "ออร่า" (ชื่อแบบไม่ได้บอกว่าชีตนี้ทำอะไร)
///
/// # ลากปรับความสูง
///
/// ขีดบนหัวชีต (และทั้งแถบหัว) ลากขึ้นลงได้ — ปล่อยแล้วดีดเข้าระดับที่ใกล้ที่สุดเหมือนชีตของระบบ
/// · ชีตเนื้อหาสั้น (`fill == false`): หุบ → พอดีเนื้อหา (ตั้งต้น) → ครึ่งจอ → สูง · เนื้อหาชิดบน ที่เหลือเป็นที่ว่าง
/// · ชีตที่เลื่อนในตัว (`fill == true` เช่นตู้วิดเจ็ต): หุบ → เตี้ย → ครึ่งจอ (ตั้งต้น) → สูง · เนื้อหาได้ความสูงเต็มช่อง
/// **ลากลงไม่ปิดชีต** — ต่ำสุดคือ "หุบ" เหลือแค่หัวชีต (ขีด ‹ ชื่อ) ให้เห็นการ์ดเกือบเต็มจอ แตะหัวแล้วกางกลับ
/// ปิดได้ทางเดียวคือ ‹ หรือแตะที่ว่างบนการ์ด
/// การ์ดข้างบนย่อ/ขยายตามเองทุกเฟรม เพราะ `bottomUI` วัดจากความสูงของชีตอยู่แล้ว
struct DockSheet<Content: View>: View {
    let title: String
    let symbol: String
    /// ความสูงจอ — ใช้คิดระดับครึ่งจอ/สูง
    var viewport: CGFloat = 874
    /// เนื้อหาเลื่อนในตัวเอง ต้องได้ความสูงเต็มช่อง (ไม่ใช่สูงตามเนื้อหา)
    var fill = false
    let onBack: () -> Void
    @ViewBuilder var content: Content

    /// เนื้อในชีตตามหลังตัวชีตมาหนึ่งจังหวะ — ชีตไหลขึ้นมาก่อน แล้วตัวเลือกค่อยลอยเข้าที่
    /// (ทั้งใบขึ้นพร้อมกันอ่านเป็น "แผ่นเดียวกระโดดขึ้นมา" ไม่ใช่ "ชีตเปิดแล้วมีของอยู่ข้างใน")
    @State private var settled = false
    /// ระดับที่ค้างอยู่ — เก็บเป็นลำดับ ไม่ใช่ความสูง เนื้อหาเปลี่ยน (แตะชิ้นอื่น) ระดับเดิมยังถูกความหมาย
    @State private var level: Int?
    /// ระยะลากสด (บวก = ขึ้น)
    @State private var drag: CGFloat = 0
    /// ความสูงตามธรรมชาติของเนื้อหา — ระดับ "พอดีเนื้อหา"
    @State private var natural: CGFloat = 0

    /// ความสูงของช่องเนื้อหาแต่ละระดับ จากเตี้ยไปสูง
    private var detents: [CGFloat] {
        let mid = viewport * 0.44
        let tall = viewport * 0.64
        if fill { return [0, max(220, viewport * 0.3), max(260, viewport * 0.5), tall] }
        // ระดับที่แทบไม่ต่างจากพอดีเนื้อหาไม่ต้องมี — ลากแล้วไม่เห็นอะไรเปลี่ยน
        return [0, natural] + [mid, tall].filter { $0 > natural + 48 }
    }

    /// ระดับตั้งต้น — พอดีเนื้อหา หรือครึ่งจอสำหรับตู้
    private var defaultLevel: Int { fill ? 2 : 1 }

    private var currentLevel: Int {
        min(level ?? defaultLevel, detents.count - 1)
    }

    private var collapsed: Bool { currentLevel == 0 && drag <= 0 }

    /// ความสูงช่องเนื้อหาตอนนี้ — ระดับ + ระยะลาก เลยขอบบน/ล่างแล้วหน่วงแบบยาง
    private var liveHeight: CGFloat {
        let raw = detents[currentLevel] + drag
        let top = detents.last ?? raw
        if raw > top { return top + rubber(raw - top) }
        return raw
    }

    /// ลากต่ำกว่าหุบ — ทั้งใบจมตามนิ้วแบบหนืด ปล่อยแล้วเด้งกลับ (ไม่ปิด)
    private var sink: CGFloat { liveHeight < 0 ? rubber(-liveHeight) : 0 }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        VStack(spacing: 0) {
            header
            Group {
                if fill {
                    content
                        .frame(maxWidth: .infinity)
                        .frame(height: max(0, liveHeight), alignment: .top)
                } else {
                    content
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { natural = $0 }
                        .frame(maxWidth: .infinity)
                        // ยังไม่ได้วัดเนื้อหา = ปล่อยสูงตามธรรมชาติ (เฟรมแรกไม่วูบเป็น 0)
                        .frame(height: natural == 0 ? nil : max(0, liveHeight), alignment: .top)
                }
            }
            // หุบลงไป เนื้อหาจางตามแทนที่จะโดนตัดเป็นเส้นคม
            .opacity(min(1, max(0, liveHeight) / 60))
            .opacity(settled ? 1 : 0)
            .offset(y: settled ? 0 : 14)
            .clipped()
        }
        .onAppear { withAnimation(Motion.settle.delay(0.06)) { settled = true } }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        // ม่านบางใต้เนื้อหา — กระจกล้วนโปร่งจนชิปจมเวลาการ์ดสว่างมุดอยู่ข้างใต้
        .background(shape.fill(Color.black.opacity(0.26)))
        .glassEffect(.regular, in: shape)
        .padding(.horizontal, 12)
        .offset(y: sink)
        .environment(\.colorScheme, .dark)
    }

    /// ขีดลาก + ‹ + ชื่อ — ทั้งแถบคือที่จับ
    private var header: some View {
        VStack(spacing: 6) {
            Capsule()
                .fill(Color.white.opacity(drag == 0 ? 0.3 : 0.55))
                .frame(width: 36, height: 5)
                .padding(.top, 7)
                .animation(Motion.snap, value: drag == 0)

            HStack(spacing: 10) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                        .contentShape(Circle())
                }
                .buttonStyle(DockPress())
                .accessibilityLabel("กลับ")

                HStack(spacing: 7) {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .opacity(0.8)
                    Text(title).font(.sh(15, .semibold))
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                .foregroundStyle(.white.opacity(0.94))
                // ชื่อเปลี่ยน (แตะชิ้นอื่น) = crossfade ไม่ใช่กระโดด
                .id(title)
                .transition(.opacity)
                Spacer(minLength: 0)
            }
            .animation(Motion.snap, value: title)
        }
        .padding(.bottom, collapsed ? 0 : 12)
        .contentShape(Rectangle())
        // หุบอยู่ แตะหัวชีต = กางกลับระดับตั้งต้น (ปุ่ม ‹ ยังรับแตะของมันเองก่อน)
        .onTapGesture {
            guard currentLevel == 0 else { return }
            Haptics.impact(.light)
            withAnimation(Motion.settle) { level = defaultLevel }
        }
        .gesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .global)
                .onChanged { v in drag = -v.translation.height }
                .onEnded { v in settle(predicted: -v.predictedEndTranslation.height) }
        )
        .accessibilityAction(named: "ขยายชีต") { step(+1) }
        .accessibilityAction(named: "ย่อชีต") { step(-1) }
    }

    /// ปล่อยนิ้ว — เลือกระดับจากจุดที่ชีตจะไหลไปถึง (รวมแรงเหวี่ยง) ไม่ใช่แค่จุดที่ปล่อย
    private func settle(predicted: CGFloat) {
        let base = detents[currentLevel]
        let aim = base + predicted
        // ลงแรงแค่ไหนก็จบที่ "หุบ" — ลากลงไม่มีวันปิดชีต
        let target = detents.indices.min { abs(detents[$0] - aim) < abs(detents[$1] - aim) } ?? currentLevel
        if target != currentLevel { Haptics.impact(.light) }
        withAnimation(Motion.settle) {
            level = target
            drag = 0
        }
    }

    private func step(_ d: Int) {
        let target = min(max(currentLevel + d, 0), detents.count - 1)
        withAnimation(Motion.settle) { level = target }
    }

    /// สูตรเดียวกับ overscroll ของ UIScrollView — ยังลากได้ แต่ไม่ไปแล้ว
    private func rubber(_ x: CGFloat) -> CGFloat {
        let c: CGFloat = 0.55, d: CGFloat = 120
        return (1 - 1 / (x * c / d + 1)) * d
    }
}

/// หนึ่งแถวในถาด — ป้ายสั้น ๆ ทางซ้าย ตัวเลือกทางขวา
struct DockRow<Content: View>: View {
    let label: String
    var dim = false
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(label)
                .font(.sh(11.5, .semibold))
                .foregroundStyle(.white.opacity(dim ? 0.28 : 0.5))
                .lineLimit(1).minimumScaleFactor(0.8)
                .frame(width: 40, alignment: .leading)
            content.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// ตัวเลือกแบบแบ่งช่อง — ไฮไลต์ **ไหล** ไปช่องที่แตะ ไม่กระพริบหายแล้วโผล่
struct DockSegment<T: Hashable>: View {
    struct Option {
        let value: T
        let title: String
        var symbol: String? = nil
    }

    let options: [Option]
    let selection: T
    var dim = false
    let onPick: (T) -> Void

    @Namespace private var ns

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.value) { o in
                let on = o.value == selection
                Button { onPick(o.value) } label: {
                    Group {
                        if let s = o.symbol {
                            Image(systemName: s).font(.system(size: 12, weight: .semibold))
                        } else {
                            Text(o.title).font(.sh(11.5, .semibold))
                        }
                    }
                    .foregroundStyle(on ? Color.black.opacity(0.86)
                                        : Color.white.opacity(dim ? 0.32 : 0.74))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background {
                        if on {
                            Capsule().fill(Color.white.opacity(dim ? 0.35 : 0.92))
                                .matchedGeometryEffect(id: "on", in: ns)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.black.opacity(0.28)))
        .animation(Motion.snap, value: selection)
    }
}
