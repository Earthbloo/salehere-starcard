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
    /// ขอบรอบแถบ (หน่วยออกแบบ) — 0 = หน้าชิดขอบ แบบรูปย่อในหน้าเลือกเทมเพลต
    ///
    /// ใส่ค่าเมื่อแถบถูกโชว์ใหญ่เป็น "การ์ดทั้งใบ" (สำรับในคลัง) — สามหน้าวางอยู่บนแผ่นสีธีม
    /// อ่านเป็นของชิ้นเดียวที่มีสามหน้า ไม่ใช่สามหน้าที่ถูกตัดขอบด้วยมุมมนของกรอบนอก
    var margin: CGFloat = 0
    /// มุมมนของกรอบนอก (หน่วยจอ)
    var cornerRadius: CGFloat = 10

    /// ความสูงของแถบที่ความกว้างเท่านี้ — ผูกกับ `gutter`/`margin` เพราะกินความกว้างไปด้วย
    /// ใครวาดกรอบรอไว้ต้องคิดจากสูตรเดียวกัน ไม่งั้นรูปถูกยืดผิดสัดส่วน
    static func height(width: CGFloat, gutter: CGFloat = 0, margin: CGFloat = 0) -> CGFloat {
        let p = CardTemplate.previewPageSize(for: .portfolio)
        return width * (p.height + margin * 2) / (p.width * 3 + gutter * 2 + margin * 2)
    }

    var body: some View {
        let pageSize = CardTemplate.previewPageSize(for: .portfolio)
        let sheet = CGSize(width: pageSize.width * 3 + gutter * 2 + margin * 2,
                           height: pageSize.height + margin * 2)
        let s = width / sheet.width
        let pageRadius = gutter * 0.85

        ZStack {
            if flat {
                LinearGradient(colors: [theme.backdropColors.top, theme.backdropColors.bottom],
                               startPoint: .top, endPoint: .bottom)
            } else {
                CardBackdrop(theme: theme, ignoreSafeArea: false, signed: true)
            }
            HStack(spacing: gutter) {
                ForEach(0..<3, id: \.self) { i in
                    CardPageCanvas(page: pages.indices.contains(i) ? pages[i] : CardPage(),
                                   size: pageSize, theme: theme, lockPreview: true)
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
            .padding(margin)
            if !flat, theme.strip.isStamp {
                SignatureEmboss(light: theme.inkStyle.isLight, foil: theme.strip == .foil, tint: theme.inkStyle.base,
                                pages: pages, pageSize: pageSize, margin: margin, gutter: gutter)
            }
        }
        .frame(width: sheet.width, height: sheet.height)
        .environment(\.cardInk, theme.inkStyle)
        .environment(\.pageContentWidth, PageLayout.content(pageSize).width)
        .environment(\.colorScheme, theme.activeInk.isLight ? .light : .dark)
        // หยุดของที่วิ่งตามเวลาในพรีวิว — จอโชว์พร้อมกันหลายใบ ปล่อยวิ่งแล้วแย่งเฟรมกันจนกระตุก
        .environment(\.previewStatic, true)
        .allowsHitTesting(false)
        .scaleEffect(s)
        .frame(width: width, height: sheet.height * s)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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
                CardBackdrop(theme: theme, ignoreSafeArea: false, signed: true)
            }
            CardPageCanvas(page: page, size: pageSize, theme: theme, lockPreview: true)
            if !flat, theme.strip.isStamp {
                SignatureEmboss(light: theme.inkStyle.isLight, foil: theme.strip == .foil, tint: theme.inkStyle.base,
                                pages: [page], pageSize: pageSize)
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .environment(\.cardInk, theme.inkStyle)
        .environment(\.pageContentWidth, PageLayout.content(pageSize).width)
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
/// — ผังเทมเพลตคงที่ แต่ **เนื้อหาเป็นของเจ้าของการ์ด** (ชื่อ · รูปโปรไฟล์ · รูปผลงาน)
/// รูปแต่ละใบจึงจำว่าอบจากข้อมูลรุ่นไหน (`stamp`) แก้โปรไฟล์แล้วเปิดหน้าเลือกใหม่ = อบใหม่ทับรูปเก่า
@MainActor
@Observable
final class TemplateThumbs {
    static let shared = TemplateThumbs()
    private(set) var images: [String: UIImage] = [:]
    /// ข้อมูลรุ่นที่แต่ละรูปอบมา — ไม่ตรงกับ `stamp` ปัจจุบัน = รูปนั้นเก่า
    private var bakedStamp: [String: String] = [:]
    private var warming = false

    /// รุ่นของข้อมูลที่ widget วาด — เปลี่ยนเมื่อโปรไฟล์ รูปโปรไฟล์ หรือผลงานเปลี่ยน
    private func stamp(_ photos: PhotoStore) -> String {
        "\(Profile.me.revision)-\(photos.profileRevision)-\(Portfolio.shared.revision)"
    }

    /// เทมเพลตจากการ์ดที่ออกแบบจริงมีรูปอบติดแอปมาแล้ว — โชว์รูปนั้น ไม่อบสดทับด้วยข้อมูลผู้ใช้
    func image(for id: String) -> UIImage? { bundled[id] ?? images[id] }

    private let bundled: [String: UIImage] = Dictionary(uniqueKeysWithValues:
        DesignedTemplate.all.compactMap { d in DesignedTemplate.preview(d.id).map { (d.id, $0) } })

    /// อุ่นรูปทุกสไตล์ทั้งสองรูปแบบ — เรียกซ้ำได้ ปลอดภัย (ทำงานรอบเดียว)
    ///
    /// ขนาดรูปไม่ใช่พารามิเตอร์ — มาจาก `TemplateWall.cardSize` ที่เดียว ใครเรียกก่อน (คลังอุ่นล่วงหน้า
    /// หรือหน้าเลือกเอง) ได้รูปขนาดเดียวกันเสมอ ไม่มีกรณีรูปเล็กถูกแคชไว้แล้วโดนยืดบนใบใหญ่
    func warm(photos: PhotoStore) async {
        let now = stamp(photos)
        let all = CardFormat.allCases.flatMap { CardTemplate.all(for: $0) }
            .filter { bundled[$0.id] == nil }
        guard !warming, all.contains(where: { bakedStamp[$0.id] != now }) else { return }
        warming = true
        defer { warming = false }

        // 1) รอรูปตั้งต้นให้ครบก่อน — เรนเดอร์ตอนรูปยังไม่มา thumb จะอบช่องว่างติดถาวร
        var urls = Set((0..<PhotoLib.count).map { PhotoLib.url($0) })
        for brand in Profile.me.creator.track.brands {
            if let raw = brand.logo, let u = URL(string: raw) { urls.insert(u) }
        }
        await withTaskGroup(of: Void.self) { group in
            for u in urls {
                group.addTask { _ = await ImageCache.shared.load(u) }
            }
        }

        // 1.5) ลบพื้นหลังรูปคนของโปสเตอร์ให้เสร็จก่อน (ดู `SubjectLift.prepare`)
        // ใบใหม่จากเทมเพลตไม่มีรูปเฉพาะชิ้น ช่องคนจึงเป็นรูปจากคลัง/โปรไฟล์ใบเดียวกันทุกใบ
        if let person = photos.userImage(slot: 1, for: nil),
           !CutoutCache.shared.result(for: person).isCutout {
            await SubjectLift.shared.prepare(person)
        }

        // 2) เรนเดอร์ทีละใบ เว้นจังหวะให้ UI หายใจระหว่างใบ
        for format in CardFormat.allCases {
            // รูปเก่ายังโชว์อยู่ระหว่างอบใหม่ — สลับทีละใบ ไม่กระพริบว่างทั้งผนัง
            for template in CardTemplate.all(for: format)
            where bundled[template.id] == nil && bakedStamp[template.id] != now {
                let ui = Self.render(pages: template.makePages(), theme: template.theme,
                                     format: template.format, photos: photos)
                withAnimation(.easeOut(duration: 0.25)) { images[template.id] = ui }
                bakedStamp[template.id] = now
                await Task.yield()
            }
        }
    }

    /// อบที่ขนาดเท่าใบในสำรับของหน้าเลือก ที่ scale ของจอจริง — ใบใหญ่กลางจอต้องคมเท่าของจริง
    /// ฉากหลังเป็น `CardBackdrop` เต็มตัว (ดวงแสงครบ) เพราะจ่ายครั้งเดียวตอนอบ ไม่ใช่ทุกเฟรม
    private static func render(pages: [CardPage], theme: CardTheme, format: CardFormat,
                               photos: PhotoStore) -> UIImage? {
        let size = TemplateWall.cardSize(format)
        let radius = TemplateWall.radius(format)
        let content: AnyView
        switch format {
        case .portfolio:
            content = AnyView(CardStripPreview(pages: pages, theme: theme,
                                               width: size.width, showsDividers: false,
                                               gutter: CardTemplate.thumbGutter,
                                               margin: CardTemplate.thumbGutter,
                                               cornerRadius: radius))
        case .story:
            content = AnyView(CardFramePreview(page: pages.first ?? CardPage(),
                                               theme: theme,
                                               pageSize: CardTemplate.previewPageSize(for: .story),
                                               height: size.height,
                                               cornerRadius: radius))
        }
        let renderer = ImageRenderer(content: content.environment(photos))
        renderer.scale = TemplateWall.screen?.scale ?? 3
        renderer.isOpaque = false
        return renderer.uiImage
    }

    #if DEBUG
    /// ยกการ์ดทุกใบในคลังของเครื่องนี้ออกมาเป็นเทมเพลต — เปิดแอปด้วย `-exportDesignedTemplates`
    ///
    /// เขียน `designed-templates.json` + รูป `<id>.png` ลง `Documents/DesignedTemplates/` แล้วคัดลอกไฟล์ทั้งโฟลเดอร์
    /// ไปทับ `Resources/DesignedTemplates/` · รูปอบด้วย id เดิมของชิ้น = รูปและข้อความของผู้ออกแบบ
    func exportDesigned(photos: PhotoStore) async {
        await withTaskGroup(of: Void.self) { group in
            for u in (0..<PhotoLib.count).map({ PhotoLib.url($0) }) {
                group.addTask { _ = await ImageCache.shared.load(u) }
            }
        }
        let dir = URL.documentsDirectory.appending(path: DesignedTemplate.bundleFolder)
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        var out: [DesignedTemplate] = []
        for record in CardLibrary.shared.records.sorted(by: { $0.createdAt < $1.createdAt }) {
            guard let (pages, theme, _) = record.restored() else { continue }
            let id = "designed.\(record.shortID)"
            out.append(DesignedTemplate(id: id, name: record.name, format: record.formatRaw,
                                        snapshot: record.snapshot))
            // รอบแรกให้รูปรายชิ้นโหลดจากดิสก์ รอบสองคือรูปที่ใช้จริง
            _ = Self.render(pages: pages, theme: theme, format: record.format, photos: photos)
            try? await Task.sleep(for: .milliseconds(800))
            if let png = Self.render(pages: pages, theme: theme, format: record.format,
                                     photos: photos)?.pngData() {
                try? png.write(to: dir.appending(path: "\(id).png"))
            }
        }
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? enc.encode(out).write(to: dir.appending(path: "designed-templates.json"))
        print("[export] \(out.count) templates → \(dir.path)")
    }
    #endif
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
