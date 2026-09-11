import SwiftUI

// MARK: - พรีวิวการ์ดย่อส่วน — ใช้ร่วมกันทั้งหน้าเลือกเทมเพลตและคลังการ์ด
//
// ทั้งสองหน้าต้องโชว์ "ของจริงย่อส่วน" ไม่ใช่รูปแคป — วาดด้วย widget ชุดเดียวกับการ์ดจริง
// ผ่าน `CardPageCanvas` ทุกครั้ง สิ่งที่เห็นจึงตรงกับสิ่งที่ได้เสมอ และแก้ widget ที่เดียว
// พรีวิวทุกจุดเปลี่ยนตามเอง

/// แถบสามหน้าต่อกันบนฉากหลังผืนเดียว — หน้าตาเดียวกับรูปที่แชร์ออกจริง (โครงเดียวกับตอน export)
struct CardStripPreview: View {
    let pages: [CardPage]
    let theme: CardTheme
    let width: CGFloat
    /// เส้นประบอกเขตหน้า — ภาษาหมายเหตุของแอป รูปแชร์จริงไม่มีเส้นนี้
    var showsDividers = true
    /// ฉากหลังแบบเบา — ไล่เฉดแบนแทน `CardBackdrop` (ตัดดวงแสงเบลอใหญ่ทิ้ง)
    /// ใช้กับกริดที่โชว์พรีวิวพร้อมกันหลายใบ: ที่ขนาดจิ๋วตามองไม่ต่าง แต่ GPU ต่างมหาศาล
    var flat = false
    /// ช่องว่างระหว่างหน้า (หน่วยออกแบบ) — **0 = แถบต่อเนื่องเหมือนรูปที่แชร์ออกจริง**
    ///
    /// ใส่ค่าเมื่อพรีวิวต้องตอบคำถาม "ของนี้คืออะไร" มากกว่า "แชร์ออกมาหน้าตายังไง"
    /// เส้นประบาง ๆ ที่คั่นหน้าอยู่เดิมหายไปหมดที่ขนาดรูปย่อ — แถบเลยอ่านเป็นภาพเดียว
    /// แล้วผู้ใช้ที่เพิ่งกดแท็บ "แนวนอน" ก็ไปเจอหน้าทรงตั้งโดยไม่มีอะไรเตือนล่วงหน้า
    /// (ตอนเทสมีคนเข้าใจว่า "1 / 3" คือการ์ดสามใบ แล้วไปกดจุดหาการ์ดอีกสองใบ)
    /// ช่องว่างจริง + มุมมนของแต่ละหน้า ตอบว่า "สามหน้าต่อกัน" ได้โดยไม่ต้องมีคำอธิบาย
    var gutter: CGFloat = 0

    /// ความสูงของแถบที่ความกว้างเท่านี้ — ผูกกับ `gutter` เพราะช่องว่างกินความกว้างไปด้วย
    /// ใครวาดกรอบรอไว้ต้องคิดจากสูตรเดียวกัน ไม่งั้นรูปถูกยืดผิดสัดส่วน
    static func height(width: CGFloat, gutter: CGFloat = 0) -> CGFloat {
        let p = CardTemplate.previewPageSize(for: .portfolio)
        return width * p.height / (p.width * 3 + gutter * 2)
    }

    var body: some View {
        let pageSize = CardTemplate.previewPageSize(for: .portfolio)
        let sheet = CGSize(width: pageSize.width * 3 + gutter * 2, height: pageSize.height)
        let s = width / sheet.width
        let pageRadius = gutter * 0.85

        ZStack {
            if flat {
                LinearGradient(colors: [theme.backdropColors.top, theme.backdropColors.bottom],
                               startPoint: .top, endPoint: .bottom)
            } else {
                CardBackdrop(theme: theme, ignoreSafeArea: false)
            }
            HStack(spacing: gutter) {
                ForEach(0..<3, id: \.self) { i in
                    CardPageCanvas(page: pages.indices.contains(i) ? pages[i] : CardPage(),
                                   size: pageSize, theme: theme)
                        .frame(width: pageSize.width, height: pageSize.height)
                        // มุมมน + ขอบบาง เกิดเฉพาะตอนมีช่องว่าง — แถบต่อเนื่องต้องไม่มีรอยต่อ
                        .clipShape(RoundedRectangle(cornerRadius: pageRadius, style: .continuous))
                        .overlay {
                            if gutter > 0 {
                                RoundedRectangle(cornerRadius: pageRadius, style: .continuous)
                                    .strokeBorder(.white.opacity(0.14), lineWidth: 1.4)
                            }
                        }
                        // ขอบขาวจาง ๆ อ่านออกบนฉากหลังมืด · เงาอ่านออกบนฉากหลังสว่าง
                        // ต้องมีทั้งคู่ ไม่งั้นธีมชมพูจะได้ช่องว่างสีชมพูบนพื้นชมพู = มองไม่เห็นรอยต่อ
                        .shadow(color: .black.opacity(gutter > 0 ? 0.38 : 0),
                                radius: gutter * 0.34, y: gutter * 0.13)
                }
            }
        }
        .frame(width: sheet.width, height: sheet.height)
        .environment(\.cardInk, theme.inkStyle)
        .environment(\.colorScheme, theme.activeInk.isLight ? .light : .dark)
        // หยุดของที่วิ่งตามเวลาในพรีวิว — จอโชว์พร้อมกันหลายใบ ปล่อยวิ่งแล้วแย่งเฟรมกันจนกระตุก
        .environment(\.previewStatic, true)
        .allowsHitTesting(false)
        .scaleEffect(s)
        .frame(width: width, height: sheet.height * s)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            // ช่องว่างจริงพูดแทนเส้นประได้หมดแล้ว — วาดทั้งคู่จะกลายเป็นรอยต่อสองชั้น
            if showsDividers, gutter == 0 {
                HStack(spacing: 0) {
                    ForEach(0..<2, id: \.self) { _ in
                        Spacer()
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 0.7)
                            .overlay {
                                VerticalDashes()
                                    .stroke(.white.opacity(0.22),
                                            style: StrokeStyle(lineWidth: 0.7, dash: [4, 4]))
                            }
                    }
                    Spacer()
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(.white.opacity(0.1), lineWidth: 0.6))
    }
}

/// หน้าเดียวเป็นเฟรมตั้ง — ใช้กับสตอรี่ (และหน้าเดี่ยวของพอร์ตถ้าต้องการ)
struct CardFramePreview: View {
    let page: CardPage
    let theme: CardTheme
    let pageSize: CGSize
    let height: CGFloat
    var cornerRadius: CGFloat = 13
    /// ฉากหลังแบบเบา — เหตุผลเดียวกับ `CardStripPreview.flat`
    var flat = false

    var body: some View {
        let s = height / pageSize.height
        ZStack {
            if flat {
                LinearGradient(colors: [theme.backdropColors.top, theme.backdropColors.bottom],
                               startPoint: .top, endPoint: .bottom)
            } else {
                CardBackdrop(theme: theme, ignoreSafeArea: false)
            }
            CardPageCanvas(page: page, size: pageSize, theme: theme)
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .environment(\.cardInk, theme.inkStyle)
        .environment(\.colorScheme, theme.activeInk.isLight ? .light : .dark)
        .environment(\.previewStatic, true)
        .allowsHitTesting(false)
        .scaleEffect(s)
        .frame(width: pageSize.width * s, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(.white.opacity(0.1), lineWidth: 0.6))
    }
}

// MARK: - รูปนิ่งของเทมเพลต

/// แคชรูปนิ่งของพรีวิวเทมเพลต — **หน้าเลือกโชว์แค่รูป** widget จริงเกิดเฉพาะตอนเลือกแล้ว
///
/// พรีวิวสด 12 ใบ = widget หลายร้อยชิ้นที่ต้องสร้าง/วาดค้างไว้ตลอด แค่เปิดหน้าก็กระตุก
/// เรนเดอร์เป็นรูปครั้งเดียวตอนแอปว่าง (เว้นจังหวะทีละใบ) แล้วกริดกลายเป็นแกลเลอรีรูปเบา ๆ
/// — เทมเพลตเป็นของคงที่ รูปจึงไม่มีวันเก่าจนกว่าโค้ดเทมเพลต/widget จะเปลี่ยน ซึ่งคือรอบ build ใหม่อยู่แล้ว
@MainActor
@Observable
final class TemplateThumbs {
    static let shared = TemplateThumbs()
    private(set) var images: [String: UIImage] = [:]
    private var warming = false

    func image(for id: String) -> UIImage? { images[id] }

    /// อุ่นรูปทุกสไตล์ทั้งสองรูปแบบ — เรียกซ้ำได้ ปลอดภัย (ทำงานรอบเดียว)
    func warm(photos: PhotoStore, cellWidth: CGFloat) async {
        guard !warming, images.count < CardFormat.allCases
            .reduce(0, { $0 + CardTemplate.all(for: $1).count }) else { return }
        warming = true
        defer { warming = false }

        // 1) รอรูปตั้งต้นให้ครบก่อน — เรนเดอร์ตอนรูปยังไม่มา thumb จะอบช่องว่างติดถาวร
        var urls = Set((0..<PhotoLib.count).map { PhotoLib.url($0) })
        for brand in Mock.creator.track.brands {
            if let raw = brand.logo, let u = URL(string: raw) { urls.insert(u) }
        }
        await withTaskGroup(of: Void.self) { group in
            for u in urls {
                group.addTask { _ = await ImageCache.shared.load(u) }
            }
        }

        // 2) เรนเดอร์ทีละใบ เว้นจังหวะให้ UI หายใจระหว่างใบ
        for format in CardFormat.allCases {
            for template in CardTemplate.all(for: format) where images[template.id] == nil {
                let ui = Self.render(template, cellWidth: cellWidth, photos: photos)
                withAnimation(.easeOut(duration: 0.25)) { images[template.id] = ui }
                await Task.yield()
            }
        }
    }

    private static func render(_ template: CardTemplate, cellWidth: CGFloat,
                               photos: PhotoStore) -> UIImage? {
        let pages = template.makePages()
        let content: AnyView
        switch template.format {
        case .portfolio:
            content = AnyView(CardStripPreview(pages: pages, theme: template.theme,
                                               width: cellWidth, flat: true,
                                               gutter: CardTemplate.thumbGutter))
        case .story:
            content = AnyView(CardFramePreview(page: pages.first ?? CardPage(),
                                               theme: template.theme,
                                               pageSize: CardTemplate.previewPageSize(for: .story),
                                               height: cellWidth * 960 / 540,
                                               cornerRadius: 10, flat: true))
        }
        let renderer = ImageRenderer(content: content.environment(photos))
        renderer.scale = 2
        renderer.isOpaque = false
        return renderer.uiImage
    }
}

/// เส้นตั้งเส้นเดียว — มีไว้ให้ stroke ด้วย dash ได้ (Rectangle จะ dash รอบกรอบ ไม่ใช่เส้นเดี่ยว)
struct VerticalDashes: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: 0))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.height))
        return p
    }
}
