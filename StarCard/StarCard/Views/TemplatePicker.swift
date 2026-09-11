import SwiftUI

/// หน้าแรกของการสร้างการ์ด — เลือกรูปแบบและเทมเพลตจบในหน้าเดียว
///
/// # ทำไมไม่มีหน้า "เลือกรูปแบบ" แยกอีกแล้ว
///
/// คำถาม "พอร์ตหรือสตอรี่" กับ "หน้าตาแบบไหน" เคยถูกถามคนละหน้า — แต่คำตอบที่ดีของ
/// คำถามแรกคือ *การได้เห็นของจริงของทั้งสองแบบ* ซึ่งก็คือพรีวิวในหน้านี้อยู่แล้ว
/// จึงยุบเหลือหน้าเดียว: สวิตช์รูปแบบอยู่บนหัว สลับแล้วลิสต์เทมเพลตเปลี่ยนตามทันที
///
/// ดัชนีสไลด์ **คงไว้ตอนสลับรูปแบบ** — เทมเพลตสองฝั่งเรียงตระกูลตรงกัน (คู่คลิป·คอลลาจ·…)
/// ผู้ใช้จึงกดสลับไปมาเพื่อดูผังเดียวกันในอีกรูปแบบได้โดยไม่หลงตำแหน่ง
///
/// # ทำไมพรีวิวต้องเป็นของจริงย่อส่วน ไม่ใช่รูปนิ่ง
///
/// เทมเพลตวาดด้วย widget ชุดเดียวกับการ์ดจริงผ่าน `CardPageCanvas` — สิ่งที่เห็นในหน้านี้
/// คือสิ่งที่ได้เป๊ะ ๆ และวันที่ widget เปลี่ยนหน้าตา พรีวิวก็เปลี่ยนตามเองโดยไม่มีรูปแคปเก่าหลอกตา
struct TemplatePicker: View {
    let onPick: (CardFormat, CardTemplate) -> Void
    /// ทางกลับไปคลังการ์ด — nil เมื่อคลังยังว่าง (หน้านี้คือหน้าแรก ไม่มีที่ให้กลับ)
    var onBack: (() -> Void)?

    @State private var format: CardFormat
    /// รางของขีดใต้แท็บ — ให้มันไหลระหว่างสองแท็บแทนการกระพริบหาย
    @Namespace private var tabNS

    /// หน้านี้โชว์ **รูปนิ่ง** จาก `TemplateThumbs` ล้วน ๆ — ไม่มี widget สดสักตัว
    /// การเปิดหน้า/สลับแท็บจึงเลื่อนแค่แกลเลอรีรูปเบา ๆ · widget จริงเกิดตอนเลือกแล้วเท่านั้น
    @Environment(PhotoStore.self) private var photos
    private var thumbs: TemplateThumbs { TemplateThumbs.shared }

    private let templates: [CardFormat: [CardTemplate]]

    init(initialFormat: CardFormat = .portfolio,
         onPick: @escaping (CardFormat, CardTemplate) -> Void,
         onBack: (() -> Void)? = nil) {
        self.onPick = onPick
        self.onBack = onBack
        _format = State(initialValue: initialFormat)
        var t: [CardFormat: [CardTemplate]] = [:]
        for f in CardFormat.allCases {
            t[f] = CardTemplate.all(for: f)
        }
        templates = t
    }

    private var list: [CardTemplate] { templates[format] ?? [] }

    var body: some View {
        // เวทีมืดล้วนแบบเดียวกับคลังการ์ด — แดงแบรนด์ทำหน้าที่สี action/active (ดูเหตุผลใน `CardGallery`)
        ZStack {
            Color(white: 0.06).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                templateGrid
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await TemplateThumbs.shared.warm(photos: photos, cellWidth: Self.cellWidth)
        }
    }

    /// ความกว้างช่องกริด — ใช้ทั้งจัดผังและเป็นขนาดอบรูป ให้รูปคมพอดีจอ
    private static var cellWidth: CGFloat {
        (min(UIScreen.main.bounds.width, 480) - 36 - 14) / 2
    }

    // MARK: - ส่วนหัว + สวิตช์รูปแบบ

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if let onBack {
                    Button {
                        Haptics.impact(.light)
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.sh(12, .bold))
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(.white.opacity(0.09)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("กลับไปคลังการ์ด")
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("สร้างการ์ด")
                        .font(.sh(22, .bold))
                        .foregroundStyle(.white)
                    Text("แตะเทมเพลตที่ใช่ เริ่มแต่งได้เลย")
                        .font(.sh(12, .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            formatSwitcher
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    /// สวิตช์รูปแบบ — โมเดลแท็บของ Sale Here 2.0 (§7): เทา → ดำหนา + ขีดใต้ 2px
    /// ขีดใต้ไหลจากแท็บเดิมไปแท็บใหม่ด้วย matchedGeometry — motion เดียวที่แท็บควรมี
    private var formatSwitcher: some View {
        HStack(spacing: 24) {
            ForEach(CardFormat.allCases) { f in
                let active = f == format
                Button {
                    guard !active else { return }
                    Haptics.impact(.light)
                    withAnimation(Motion.settle) { format = f }
                } label: {
                    VStack(spacing: 7) {
                        HStack(spacing: 7) {
                            // 0.58 ไม่ใช่ 0.45 — แท็บที่จมกับพื้นเกินไปอ่านเป็นป้ายประดับ ไม่ใช่ปุ่ม
                            glyph(f, tint: active ? .white : .white.opacity(0.58))
                            Text(f == .portfolio ? "แนวนอน" : "แนวตั้ง")
                                .font(.sh(14, active ? .bold : .semibold))
                        }
                        .foregroundStyle(active ? .white : .white.opacity(0.58))
                        ZStack {
                            // ขีดใต้แดงแบรนด์ — active state ของ Sale Here บนพื้นมืด
                            if active {
                                Capsule().fill(SHColor.red)
                                    .frame(height: 2)
                                    .matchedGeometryEffect(id: "tabline", in: tabNS)
                            } else {
                                Color.clear.frame(height: 2)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(f.title) · \(f.subtitle)")
                .accessibilityAddTraits(active ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }

    /// รูปทรงผลลัพธ์ย่อจิ๋ว — ภาษาเดียวกับหน้าเลือกรูปแบบเดิม (แถบสามหน้า / เฟรมตั้ง)
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

    // MARK: - กริดเทมเพลต (2 คอลัมน์ · ชื่อสไตล์ใต้รูป · แตะ = เริ่ม)

    /// ภาษาสากลของ template picker: รูปย่อขนาดเท่ากันเรียงกริด + ชื่อสไตล์สั้น ๆ ใต้รูป
    ///
    /// เวอร์ชันก่อนโชว์เป็นแถบใหญ่เต็มจอทีละใบ — เพราะพรีวิวใช้รูป/ข้อมูล mock คนเดียวกันหมด
    /// มันเลยอ่านเป็น "การ์ดจริงหลายใบซ้ำ ๆ" ไม่ใช่ "ตัวเลือกหลายสไตล์" คนเข้ามาแล้วงงว่าให้เลือกอะไร
    /// ย่อลงกริดแล้วเนื้อหาจางลง **โครง/สี/บุคลิก** เด่นขึ้น — ซึ่งคือสิ่งที่กำลังให้เลือกจริง ๆ
    private var templateGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                Text(format == .portfolio
                     ? "เลือก 1 จาก 6 สไตล์ · 3 หน้าต่อกันเป็นภาพเดียวยาวตอนแชร์"
                     : "เลือก 1 จาก 6 สไตล์ · เฟรมเดียว 9:16 ลงสตอรี่ได้เลย")
                    .font(.sh(10.5, .medium))
                    .foregroundStyle(.white.opacity(0.52))

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14),
                                    GridItem(.flexible())],
                          spacing: 20) {
                    ForEach(list) { template in
                        gridCell(template, width: Self.cellWidth)
                    }
                }
                .padding(.horizontal, 18)
            }
            .padding(.top, 6)
            .padding(.bottom, 20)
        }
    }

    private func gridCell(_ template: CardTemplate, width: CGFloat) -> some View {
        // ความสูงของแถบมาจากสูตรเดียวกับที่ `CardStripPreview` ใช้วาด — ผูกกันไว้
        // ไม่ให้อัตราส่วนของกรอบกับของรูปหลุดจากกันเวลาช่องว่างระหว่างหน้าเปลี่ยน
        let cellHeight = format == .portfolio
            ? CardStripPreview.height(width: width, gutter: CardTemplate.thumbGutter)
            : width * 960 / 540

        return Button {
            Haptics.impact(.medium)
            onPick(format, template)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    // placeholder สีธีม — จองที่และให้สีของสไตล์ขึ้นก่อนระหว่างรูปกำลังอบ
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(LinearGradient(colors: [template.theme.backdropColors.top,
                                                      template.theme.backdropColors.bottom],
                                             startPoint: .top, endPoint: .bottom))

                    if let ui = thumbs.image(for: template.id) {
                        Image(uiImage: ui)
                            .resizable()
                            .frame(width: width, height: cellHeight)
                            .transition(.opacity)
                    }
                }
                .frame(width: width, height: cellHeight)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 0.6))
                .shadow(color: .black.opacity(0.45), radius: 10, y: 5)

                // ชื่อสไตล์คือสิ่งที่ทำให้กริดอ่านเป็น "ตัวเลือก" ไม่ใช่แกลเลอรีรูป
                Text(template.name)
                    .font(.sh(11.5, .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(template.name) — \(template.blurb)")
    }
}

#Preview {
    TemplatePicker(onPick: { _, _ in })
        .environment(PhotoStore())
}
