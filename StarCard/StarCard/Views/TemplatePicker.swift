import SwiftUI

/// หน้าเลือกสไตล์ — **ผนังโปสเตอร์: การ์ดหลายใบขนาดอ่านออกบนเวทีเดียวกัน ทุกใบเรืองแสงสีของตัวเอง**
///
/// # ทำไมเป็นผนัง ไม่ใช่กริดและไม่ใช่สำรับ
///
/// กริดสองคอลัมน์ + แท็บขีดใต้ + ประโยคอธิบาย คือหน้าตาของ "รายการไฟล์" — เปิดมาแล้วรู้สึกว่ากำลัง
/// เลือกจากตาราง ไม่ใช่กำลังจะลงมือทำงานศิลป์ · สำรับปัดทีละใบสวยแต่เห็นสไตล์เดียวต่อครั้ง
/// คนที่มาเลือกอยากเห็น **ความหลากหลาย** ก่อน แล้วค่อยเลือก ("อยากให้เห็นหลาย ๆ เทมเพลตในหน้าเดียว")
///
/// ผนังจึงเอาสองอย่างมารวมกัน: ของหลายใบพร้อมกันแบบกริด แต่ทุกใบเป็นวัตถุจริงบนเวทีมืดแบบสำรับ —
/// ใบตั้งเรียงสองคอลัมน์เยื้องกันเหมือนแปะบนผนัง (ไม่ใช่ตาราง) ใบแนวนอนซ้อนกันเต็มความกว้าง
/// ทุกใบมีแสงสีธีมของตัวเองส่องออกมาด้านหลัง ผนังทั้งผืนจึงพูดว่า "มีหลายบุคลิกให้เลือก" ด้วยสีก่อนอ่านชื่อ
/// เวทีอาบสีของใบที่อยู่ใกล้กลางจอที่สุด — เลื่อนผ่านใบไหน ห้องเปลี่ยนสีตาม · แตะใบไหน = เริ่มแต่งใบนั้น
///
/// # ของที่คงไว้
///
/// * ทุกใบคือการ์ดที่ออกแบบเสร็จจริงในแอป (`DesignedTemplate`)
/// * พรีวิวเป็นรูปนิ่งที่อบติดแอปมา (ผ่าน `TemplateThumbs`) — widget จริงเกิดตอนเลือกแล้ว
struct TemplatePicker: View {
    let onPick: (CardFormat, CardTemplate) -> Void
    /// เริ่มจากการ์ดเปล่า — ใบแรกบนผนัง ไม่ต้องผ่านเทมเพลต
    var onBlank: ((CardFormat) -> Void)?
    /// ทางกลับไปคลังการ์ด — nil เมื่อคลังยังว่าง (หน้านี้คือหน้าแรก ไม่มีที่ให้กลับ)
    var onBack: (() -> Void)?

    @State private var format: CardFormat
    /// ใบที่อยู่ใกล้กลางจอที่สุด — เวทีอาบสีของใบนี้
    @State private var nearest: CardTemplate?
    /// สวิตช์ท่าเข้าฉาก — หัวลงมา ใบถูกแปะขึ้นผนังทีละใบ
    @State private var appeared = false
    /// รางของแผ่นเลือกในสวิตช์รูปแบบ — ไหลจากช่องเดิมไปช่องใหม่
    @Namespace private var segNS

    @Environment(PhotoStore.self) private var photos

    private let templates: [CardFormat: [CardTemplate]]

    init(initialFormat: CardFormat = .portfolio,
         onPick: @escaping (CardFormat, CardTemplate) -> Void,
         onBlank: ((CardFormat) -> Void)? = nil,
         onBack: (() -> Void)? = nil) {
        self.onPick = onPick
        self.onBlank = onBlank
        self.onBack = onBack
        _format = State(initialValue: initialFormat)
        var t: [CardFormat: [CardTemplate]] = [:]
        for f in CardFormat.allCases {
            t[f] = CardTemplate.all(for: f)
        }
        templates = t
    }

    private var list: [CardTemplate] { templates[format] ?? [] }
    /// ธีมของเวที — ใบใกล้กลางจอ หรือใบแรกระหว่างผนังยังไม่รายงาน
    private var stageTheme: CardTheme {
        (nearest.flatMap { n in list.first { $0.id == n.id } } ?? list.first)?.theme ?? CardTheme()
    }

    var body: some View {
        ZStack {
            stage

            VStack(spacing: 0) {
                header
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -12)
                    .animation(Motion.settle.delay(0.08), value: appeared)

                // ผนังเกิดใหม่ทั้งผืนตอนสลับรูปแบบ (`id`) — ผังคนละแบบ ระยะเลื่อนใช้ร่วมกันไม่ได้
                ZStack {
                    TemplateWall(templates: list, format: format, appeared: appeared,
                                 nearest: $nearest,
                                 onBlank: onBlank.map { f in { f(format) } }) { picked in
                        onPick(format, picked)
                    }
                    .id(format)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity))
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { appeared = true }
        .task { await TemplateThumbs.shared.warm(photos: photos) }
    }

    // MARK: - เวที

    /// ฉากหลังทั้งจอ = ฉากหลังของสไตล์ที่ใกล้กลางจอ หรี่ลงให้ใบจริงลอยเด่น — เลื่อนผ่านใบไหน ห้องเปลี่ยนสีตาม
    private var stage: some View {
        ZStack {
            CardBackdrop(theme: stageTheme, ignoreSafeArea: true)
            LinearGradient(colors: [.black.opacity(0.66), .black.opacity(0.5), .black.opacity(0.76)],
                           startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
        .animation(Motion.settle, value: nearest?.id)
    }

    // MARK: - หัว: กลับ + ชื่อหน้า + สวิตช์รูปแบบ

    /// แถวบน: กลับ · ชื่อหน้า "Template" กลางจอ — แถวล่าง: สวิตช์รูปแบบเต็มคำ ไม่ถูกตัดเป็น "…"
    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Text("Template")
                    .font(.sh(20, .bold))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    if let onBack {
                        Button {
                            Haptics.impact(.light)
                            onBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.92))
                                .frame(width: 40, height: 40)
                                .contentShape(Circle())
                        }
                        .buttonStyle(DockPress())
                        .glassEffect(.regular.interactive(), in: Circle())
                        .accessibilityLabel("กลับไปคลังการ์ด")
                    }
                    Spacer()
                }
            }
            .frame(height: 40)

            formatSwitch
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    /// สวิตช์รูปแบบ — แคปซูลกระจกสองช่อง แผ่นสว่างไหลไปช่องที่เลือก
    ///
    /// เดิมเป็นแท็บขีดใต้แดงแบบหน้าฟีด — บนเวทีมืดของห้องศิลป์มันอ่านเป็นแอปข่าว
    /// ตัวเลือกสองทางบนกระจกคือภาษาเดียวกับแถบเครื่องมือในห้องแต่ง
    private var formatSwitch: some View {
        HStack(spacing: 2) {
            ForEach(CardFormat.allCases) { f in
                let active = f == format
                Button {
                    guard !active else { return }
                    Haptics.impact(.light)
                    withAnimation(Motion.settle) { format = f }
                } label: {
                    HStack(spacing: 7) {
                        glyph(f, tint: active ? .white : .white.opacity(0.55))
                        Text(f == .portfolio ? "แนวนอน" : "แนวตั้ง")
                            .font(.sh(13.5, active ? .bold : .semibold))
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .foregroundStyle(active ? .white : .white.opacity(0.55))
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .background {
                        if active {
                            Capsule().fill(.white.opacity(0.17))
                                .matchedGeometryEffect(id: "seg", in: segNS)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(f.title) · \(f.subtitle)")
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(3)
        .glassEffect(.regular, in: Capsule())
    }

    /// รูปทรงผลลัพธ์ย่อจิ๋ว — แถบสามหน้า / เฟรมตั้ง
    @ViewBuilder
    private func glyph(_ f: CardFormat, tint: Color) -> some View {
        switch f {
        case .portfolio:
            HStack(spacing: 1.5) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1.2, style: .continuous)
                        .fill(tint)
                        .frame(width: 4, height: 13)
                }
            }
        case .story:
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(tint)
                .frame(width: 9, height: 15)
        }
    }
}

// MARK: - ผนัง

/// ผนังสไตล์ — ทุกใบเป็นวัตถุจริงขนาดอ่านออก เรืองแสงสีธีมของตัวเอง เลื่อนดูได้ทั้งผืน แตะใบไหน = เลือกใบนั้น
///
/// ใบตั้งเรียงสองคอลัมน์ คอลัมน์ขวาเยื้องลงครึ่งก้าว — สายตาไล่เป็นซิกแซกเหมือนกวาดดูโปสเตอร์บนผนัง
/// ไม่ใช่ไล่แถวในตาราง · ใบแนวนอนกว้างเกือบเต็มจอซ้อนกันลงมา เห็นสามสี่ใบต่อจอ
/// ใบที่กำลังพ้นขอบบนล่างเอียงหนีและจางลง — ผนังโค้งออกจากสายตา ไม่ใช่รายการที่ถูกตัดขอบ
struct TemplateWall: View {
    let templates: [CardTemplate]
    let format: CardFormat
    let appeared: Bool
    @Binding var nearest: CardTemplate?
    /// ใบ "เริ่มจากว่าง" — ช่องแรกของผนัง (nil = ไม่มีช่องนี้)
    var onBlank: (() -> Void)?
    let onPick: (CardTemplate) -> Void

    static let sidePadding: CGFloat = 20
    static let gutter: CGFloat = 14
    static let rowSpacing: CGFloat = 18
    /// คอลัมน์ขวาเยื้องลงเท่านี้ — ผนังโปสเตอร์ ไม่ใช่ตาราง
    static let stagger: CGFloat = 56
    private static let topPadding: CGFloat = 14
    private static let bottomPadding: CGFloat = 28

    /// จอที่แอปแสดงอยู่ — `UIScreen.main` เลิกใช้แล้วใน iOS 26 จึงถามผ่าน scene แทน
    @MainActor static var screen: UIScreen? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.screen
    }

    /// ขนาดของใบบนผนัง — **ที่เดียว**ที่ตัดสินทั้งผังของผนังและขนาดที่ `TemplateThumbs` อบรูป
    @MainActor static func cardSize(_ format: CardFormat) -> CGSize {
        let width = min(screen?.bounds.width ?? 402, 480)
        switch format {
        case .story:
            let w = ((width - sidePadding * 2 - gutter) / 2).rounded(.down)
            return CGSize(width: w, height: (w * 960 / 540).rounded())
        case .portfolio:
            let w = width - sidePadding * 2
            return CGSize(width: w,
                          height: CardStripPreview.height(width: w, gutter: CardTemplate.thumbGutter,
                                                          margin: CardTemplate.thumbGutter).rounded())
        }
    }

    /// มุมนอกของใบแนวนอนเล็กกว่า — ร่วมศูนย์กับมุมของหน้าข้างใน (เหตุผลเดียวกับสำรับในคลัง)
    static func radius(_ format: CardFormat) -> CGFloat { format == .story ? 18 : 14 }

    private var thumbs: TemplateThumbs { .shared }

    var body: some View {
        let size = Self.cardSize(format)

        ScrollView(.vertical) {
            Group {
                if format == .story {
                    HStack(alignment: .top, spacing: Self.gutter) {
                        column(stride(from: 0, to: slotCount, by: 2), size: size)
                        column(stride(from: 1, to: slotCount, by: 2), size: size)
                            .padding(.top, Self.stagger)
                    }
                } else {
                    VStack(spacing: Self.rowSpacing) {
                        ForEach(0..<slotCount, id: \.self) { slot(at: $0, size: size) }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Self.sidePadding)
            .padding(.top, Self.topPadding)
            .padding(.bottom, Self.bottomPadding)
        }
        .scrollIndicators(.hidden)
        // แสงของใบล้นกรอบได้ · ขอบบนล่างของผนังจางเข้าไปในเวทีแทนการตัดตรง ๆ
        .scrollClipDisabled()
        .mask {
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.035),
                .init(color: .black, location: 0.965),
                .init(color: .clear, location: 1),
            ], startPoint: .top, endPoint: .bottom)
        }
        // ใบที่ใกล้กลางจอที่สุด — เวทีอาบสีของมัน (ผังคงที่ คำนวณจากระยะเลื่อนได้ตรง ๆ ไม่ต้องวัดทีละใบ)
        .onScrollGeometryChange(for: Int.self) { g in
            nearestIndex(midY: g.visibleRect.midY, size: size)
        } action: { _, i in
            let t = i - blankOffset
            guard templates.indices.contains(t) else { return }
            nearest = templates[t]
        }
    }

    /// คอลัมน์หนึ่งของผนังใบตั้ง
    private func column(_ indices: StrideTo<Int>, size: CGSize) -> some View {
        VStack(spacing: Self.rowSpacing) {
            ForEach(Array(indices), id: \.self) { slot(at: $0, size: size) }
        }
    }

    /// จุดกึ่งกลางแนวตั้งของใบ `i` ในพิกัดเนื้อหา — สูตรเดียวกับที่ผังวางจริง
    private func centerY(of i: Int, size: CGSize) -> CGFloat {
        let step = size.height + Self.rowSpacing
        switch format {
        case .story:
            return Self.topPadding + CGFloat(i / 2) * step + (i % 2 == 1 ? Self.stagger : 0) + size.height / 2
        case .portfolio:
            return Self.topPadding + CGFloat(i) * step + size.height / 2
        }
    }

    private func nearestIndex(midY: CGFloat, size: CGSize) -> Int {
        (0..<slotCount).min {
            abs(centerY(of: $0, size: size) - midY) < abs(centerY(of: $1, size: size) - midY)
        } ?? 0
    }

    /// ช่องบนผนัง — ช่องแรกเป็น "เริ่มจากว่าง" (ถ้ามี) ที่เหลือเป็นเทมเพลตตามลำดับ
    private var blankOffset: Int { onBlank == nil ? 0 : 1 }
    private var slotCount: Int { templates.count + blankOffset }

    @ViewBuilder
    private func slot(at i: Int, size: CGSize) -> some View {
        if let onBlank, i == 0 {
            blankCard(size: size, onTap: onBlank)
        } else {
            card(templates[i - blankOffset], at: i, size: size)
        }
    }

    /// ใบเปล่า — กรอบเส้นประบนกระจก + เครื่องหมายบวก: อ่านเป็น "ผืนว่างรอวาด" ไม่ใช่สไตล์หนึ่งในผนัง
    private func blankCard(size: CGSize, onTap: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: Self.radius(format), style: .continuous)
        return Button {
            Haptics.impact(.medium)
            onTap()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(.white.opacity(0.14)))
                Text("เริ่มจากว่าง")
                    .font(.sh(15, .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: size.width, height: size.height)
            .background(shape.fill(.white.opacity(0.06)))
            .overlay(shape.strokeBorder(.white.opacity(0.4),
                                        style: StrokeStyle(lineWidth: 1.4, dash: [7, 6])))
            .contentShape(shape)
        }
        .buttonStyle(DockPress())
        .scrollTransition(.interactive, axis: .vertical) { content, phase in
            content
                .scaleEffect(1 - 0.06 * abs(phase.value))
                .opacity(1 - 0.45 * abs(phase.value))
                .rotation3DEffect(.degrees(10 * phase.value), axis: (x: -1, y: 0, z: 0), perspective: 0.6)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 22)
        .animation(Motion.settle.delay(0.12), value: appeared)
        .accessibilityLabel("เริ่มจากการ์ดเปล่า")
    }

    /// ใบหนึ่งใบ — รูปจริง + ป้ายชื่อบนตัวใบ + แสงสีธีมส่องจากด้านหลัง
    private func card(_ template: CardTemplate, at i: Int, size: CGSize) -> some View {
        let shape = RoundedRectangle(cornerRadius: Self.radius(format), style: .continuous)
        let accent = template.theme.rawAccent

        return Button {
            Haptics.impact(.medium)
            onPick(template)
        } label: {
            ZStack {
                // สีธีมรองไว้ใต้รูป — ระหว่างรูปกำลังอบ ใบไม่เป็นช่องโหว่ใส
                shape.fill(LinearGradient(colors: [template.theme.backdropColors.top,
                                                   template.theme.backdropColors.bottom],
                                          startPoint: .top, endPoint: .bottom))
                if let ui = thumbs.image(for: template.id) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(shape)
            .overlay(shape.strokeBorder(.white.opacity(0.16), lineWidth: 0.8))
            // แสงสีธีมของใบเองส่องออกมาด้านหลัง — ผนังทั้งผืนพูดเรื่องความหลากหลายด้วยสี
            .shadow(color: accent.opacity(0.42), radius: 26, y: 12)
            .contentShape(shape)
        }
        .buttonStyle(DockPress())
        // ใบที่กำลังพ้นขอบบนล่างเอียงหนีและจางลง — ผนังโค้งออกจากสายตา
        .scrollTransition(.interactive, axis: .vertical) { content, phase in
            content
                .scaleEffect(1 - 0.06 * abs(phase.value))
                .opacity(1 - 0.45 * abs(phase.value))
                .rotation3DEffect(.degrees(10 * phase.value), axis: (x: -1, y: 0, z: 0), perspective: 0.6)
        }
        // ท่าเข้าฉาก: ใบถูกแปะขึ้นผนังทีละใบ
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 22)
        .animation(Motion.settle.delay(0.12 + Motion.stagger(i, step: 0.055)), value: appeared)
        .accessibilityLabel("\(template.name) — \(template.blurb)")
    }
}

#Preview {
    TemplatePicker(onPick: { _, _ in })
        .environment(PhotoStore())
}
