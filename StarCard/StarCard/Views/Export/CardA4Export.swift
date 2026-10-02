import SwiftUI
import UIKit

/// รูปที่ส่งออกจากการ์ด — "ฉบับเดินทาง": การ์ดวางบนเวทีของ Sale Here พร้อมแถบ QR
///
/// # ทำไมไม่ส่งออกตัวการ์ดเปล่า ๆ อีกแล้ว
///
/// รูปที่ถูกแชร์คือจุดที่การ์ดอยู่ **ห่างจากแพลตฟอร์มที่สุด** — ไม่มีโครงของหน้าเว็บ ไม่มีที่อยู่
/// ในแถบเบราว์เซอร์ ไม่มีอะไรบอกว่าใครออกใบนี้ (วงนอกของกติกาลายเซ็น ดู `Signature`)
/// ฉบับเดินทางจึงมีสามอย่างที่ตัวการ์ดไม่มี: เวทีที่มีลายน้ำ · แถบ QR ที่พากลับมาที่การ์ด · ตรา STAR
/// ตัวการ์ดข้างบนไม่ถูกแตะเลย มันยังเป็นของ Star ทั้งใบ
///
/// * `.story` — 1080×1920 เสมอ การ์ดย่อลง 80% ลอยบนเวที แถบ QR อยู่ใต้การ์ด
/// * `.portfolio` — แถบ 3 หน้าบนเวที กว้างตามหน้า × 3 บวกขอบ
enum CardExport {
    /// พื้นที่ออกแบบกว้าง 540pt และปลายทางคือ 1080px — สเกลจึงเป็น 2 พอดีสำหรับสตอรี่
    ///
    /// เรนเดอร์ 1:1 กับพิกเซลปลายทางแปลว่าไม่มีการย่อ/ขยายซ้ำ ซึ่งเป็นที่มาของ
    /// ตัวหนังสือเบลอบนสตอรี่ · และพอพื้นที่ออกแบบตายตัวแล้ว ขนาดไฟล์ก็ตายตัวตามไปด้วย
    static let pixelWidth: CGFloat = 1080

    /// ผังของฉบับเดินทาง — ตัวเลขทั้งหมดในหน่วยออกแบบ
    struct Travel {
        /// ขนาดผืนทั้งหมด
        let canvas: CGSize
        /// กรอบของตัวการ์ด (หลังย่อ) บนผืน
        let card: CGRect
        /// สัดส่วนที่ย่อการ์ดลง
        let scale: CGFloat
        /// กรอบของแถบ QR
        let band: CGRect
        /// หัวแดงแบบแถบบนของแอป — โลโก้ + Sale Here STAR
        let header: CGRect
        /// มุมของการ์ดบนเวที
        let radius: CGFloat
    }

    /// สตอรี่: ผืน 540×960 ตายตัว การ์ดลอยกลาง เว้นหัวท้ายให้พ้นแถบ UI ของ Instagram พอประมาณ
    /// พอร์ต: ผืนกว้างเท่าแถบ 3 หน้าบวกขอบ สูงเท่าหน้าบวกแถบ QR
    static func travel(pageSize: CGSize, format: CardFormat) -> Travel {
        let sheet = CGSize(width: pageSize.width * CGFloat(format.pageCount), height: pageSize.height)
        switch format {
        case .story:
            // ผืนสตอรี่ = ขนาดหน้าเป๊ะ ๆ (540×960) ทุก pt ที่ยกให้เวทีคือ pt ที่หายไปจากเนื้อการ์ด
            // และเนื้อการ์ดบนฟีดเล็กอยู่แล้ว เวทีจึงเหลือแค่ขอบบาง ๆ ที่บอกว่านี่คือแผ่นงานวางอยู่
            // ไม่ใช่ภาพเต็มจอ — ที่เหลือทั้งหมดยกให้การ์ด (ของเดิมย่อการ์ดเหลือ 80% = เห็นเนื้อ 64%)
            let canvas = CGSize(width: 540, height: 960)
            // กรอบบาง — ผู้ใช้ 30 ก.ย. 2569: "เอากรอบน้อย อันนี้กินพื้นที่เกิน"
            let side: CGFloat = 8
            // หัวแดงของ Sale Here อยู่บนสุด การ์ดเริ่มใต้หัว (ผู้ใช้ 30 ก.ย. 2569: "ตอน save ออกไปต้องดูเป็น Sale Here")
            // ไม่มีหัวแล้ว — แบรนด์อยู่ในบรรทัดป้ายใต้การ์ดที่เดียว (หัวแดงแย่งซีนการ์ด)
            let headerH: CGFloat = 0
            let top: CGFloat = 8
            let gap: CGFloat = 6
            let bandH: CGFloat = FooterStyle.current.height
            let bottom: CGFloat = 6
            // การ์ดใหญ่ที่สุดที่ยังอยู่ในขอบและเหลือที่ให้แถบ QR — ปกติชนเพดานความสูง
            let box = CGSize(width: canvas.width - side * 2,
                             height: canvas.height - top - gap - bandH - bottom)
            let s = min(box.width / max(sheet.width, 1), box.height / max(sheet.height, 1))
            let card = CGSize(width: sheet.width * s, height: sheet.height * s)
            let rect = CGRect(x: (canvas.width - card.width) / 2,
                              y: top + (box.height - card.height) / 2,
                              width: card.width, height: card.height)
            let band = CGRect(x: rect.minX, y: rect.maxY + gap, width: card.width, height: bandH)
            let header = CGRect(x: side + 4, y: 8, width: canvas.width - (side + 4) * 2, height: headerH)
            return Travel(canvas: canvas, card: rect, scale: s, band: band, header: header, radius: 26 * s)
        case .portfolio:
            let s: CGFloat = 0.94
            let card = CGSize(width: sheet.width * s, height: sheet.height * s)
            let margin: CGFloat = 16
            // สูงพอให้ "Verified by Sale Here" อ่านออกตอนมองทั้งรูป — พอร์ตกว้างกว่าพันพอยต์ แถบ 64 เหลือเป็นเส้น
            let bandH: CGFloat = FooterStyle.current.height * 1.5
            let headerH: CGFloat = 0
            let canvas = CGSize(width: card.width + margin * 2,
                                height: margin + card.height + 8 + bandH + margin * 0.5)
            let header = CGRect(x: margin, y: margin, width: card.width, height: headerH)
            let rect = CGRect(x: margin, y: margin, width: card.width, height: card.height)
            let band = CGRect(x: margin, y: rect.maxY + 8, width: card.width, height: bandH)
            return Travel(canvas: canvas, card: rect, scale: s, band: band, header: header, radius: 22 * s)
        }
    }

    /// สเกลของ `ImageRenderer` — คำนวณย้อนจากพิกเซลปลายทาง ไม่ใช่ตั้งเป็นค่าคงที่
    static func scale(pageSize: CGSize, format: CardFormat) -> CGFloat {
        guard pageSize.width > 1 else { return 2 }
        return pixelWidth / pageSize.width
    }

    @MainActor
    static func render(pages: [CardPage], theme: CardTheme, photos: PhotoStore,
                       pageSize: CGSize, slug: String,
                       format: CardFormat = .portfolio) -> UIImage? {
        let size = resolvedPageSize(pageSize, format: format)
        let t = travel(pageSize: size, format: format)
        let view = TravelSheet(pages: pages, theme: theme, pageSize: size, format: format,
                               slug: slug, travel: t)
            .environment(photos)
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(width: t.canvas.width, height: t.canvas.height)
        renderer.scale = scale(pageSize: size, format: format)
        renderer.isOpaque = true
        return renderer.uiImage
    }

    @MainActor
    static func jpegFile(pages: [CardPage], theme: CardTheme, photos: PhotoStore,
                         pageSize: CGSize, slug: String,
                         format: CardFormat = .portfolio) -> (image: UIImage, url: URL)? {
        guard let image = render(pages: pages, theme: theme, photos: photos,
                                 pageSize: pageSize, slug: slug, format: format),
              let data = image.jpegData(compressionQuality: 0.92) else { return nil }
        // ชื่อไฟล์แยกตามแบบ — ไม่งั้นสองแบบเขียนทับกันในโฟลเดอร์ชั่วคราวเดียวกัน
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("StarCard-\(slug)-\(format.rawValue).jpg")
        do {
            try data.write(to: url, options: .atomic)
            return (image, url)
        } catch {
            return nil
        }
    }

    /// ขนาดหน้าที่ใช้เรนเดอร์ — ปกติคือขนาดที่ผู้ใช้แต่งจริง
    ///
    /// ที่ต้องมีทางสำรอง เพราะ `pageSize` มาจาก `GeometryReader` ซึ่งยังเป็นศูนย์
    /// อยู่หนึ่งเฟรมแรก ถ้าเผลอเรนเดอร์ตอนนั้นจะได้รูปเปล่า
    static func resolvedPageSize(_ size: CGSize, format: CardFormat = .portfolio) -> CGSize {
        guard size.width > 1, size.height > 1 else {
            let s = UIScreen.main.bounds.size
            let box = CGSize(width: s.width, height: max(s.height - 74 - 34, 1))
            return format.pageSize(in: box)
        }
        return size
    }
}

/// ฉบับเดินทางทั้งผืน — เวที · การ์ด · แถบ QR
private struct TravelSheet: View {
    let pages: [CardPage]
    let theme: CardTheme
    let pageSize: CGSize
    let format: CardFormat
    let slug: String
    let travel: CardExport.Travel

    var body: some View {
        let t = travel
        ZStack(alignment: .topLeading) {
            // เวที = กระดาษรองภาพสีขาวอุ่น (แบบ mat ของกรอบรูป) — เป็นกลางกับการ์ดทุกสี และดันสีของการ์ดให้เด่นขึ้น
            // ลายตัวเขียน Sale Here จางมากจนรู้สึกได้แต่ไม่อ่าน · แดงของแบรนด์ไปอยู่ที่โลโก้ในบรรทัดป้ายที่เดียว
            // (หัวแดงเต็มผืนรอบก่อนแย่งซีนการ์ด — ผู้ใช้ 30 ก.ย. 2569: "ไม่เด่นเกินการ์ด ต้องส่งเสริมการ์ด")
            TravelPaper.color
            SignaturePattern(opacity: 0.035, scale: 0.34)

            // เงาของการ์ดวาดบนแผ่นทึบ **ใต้** การ์ด ไม่ใช่บนตัวการ์ด — ใน `ImageRenderer` ฉากหลังของ
            // `CardSheet` (overlay ที่ clip) ไม่ถูกนับเป็นเนื้อทึบของเลเยอร์ `.shadow` จึงเห็นแต่ widget
            // เป็นรูปทรง แล้ววาดเงาดำรัศมี 26 รอบ widget ทุกตัว — การ์ดหมึกสว่างจะมีวงดำล้อมทุกกล่อง
            // (หมึกกลางคืนมองไม่เห็นเพราะพื้นมืดอยู่แล้ว บั๊กนี้จึงซ่อนอยู่จนมีเทมเพลตชมพู)
            RoundedRectangle(cornerRadius: t.radius, style: .continuous)
                .fill(Signature.stage)
                .frame(width: t.card.width, height: t.card.height)
                .shadow(color: .black.opacity(0.10), radius: 3, y: 1)
                .shadow(color: .black.opacity(0.16), radius: 22, y: 12)
                .position(x: t.card.midX, y: t.card.midY)

            CardSheet(pages: pages, theme: theme, pageSize: pageSize, format: format)
                .frame(width: pageSize.width * CGFloat(format.pageCount), height: pageSize.height)
                .clipShape(RoundedRectangle(cornerRadius: t.radius / t.scale, style: .continuous))
                .scaleEffect(t.scale, anchor: .topLeading)
                .frame(width: t.card.width, height: t.card.height, alignment: .topLeading)
                .position(x: t.card.midX, y: t.card.midY)

            TravelBand(slug: slug)
                .frame(width: t.band.width, height: t.band.height)
                .position(x: t.band.midX, y: t.band.midY)
        }
        .frame(width: t.canvas.width, height: t.canvas.height)
        .clipped()
        .transaction { $0.animation = nil }
    }
}

/// ตรารับรองของรูปที่ส่งออก — ท่อนแดงติ๊กขาว + ท่อนขาว VERIFIED / by โลโก้ Sale Here + STAR
struct TrustBadge: View {
    let k: CGFloat
    private var red: Color { SaleHereMark.red }

    var body: some View {
        let h = 40 * k
        let shape = RoundedRectangle(cornerRadius: 9 * k, style: .continuous)
        HStack(spacing: 0) {
            ZStack {
                red
                LinearGradient(colors: [.white.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom)
                ZStack {
                    SealShape().fill(.white)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10.5 * k, weight: .black))
                        .foregroundStyle(red)
                }
                .frame(width: 23 * k, height: 23 * k)
            }
            .frame(width: h)

            VStack(alignment: .leading, spacing: 2 * k) {
                Text("VERIFIED")
                    .font(.sh(12.5 * k, .black)).tracking(1.6 * k)
                    .foregroundStyle(red)
                    .lineLimit(1).fixedSize()
                HStack(spacing: 4 * k) {
                    Text("by")
                        .font(.sh(8.5 * k, .semibold))
                        .foregroundStyle(TravelPaper.ink.opacity(0.55))
                    SaleHereMark(size: 13 * k)
                    StarLockup(height: 12 * k, tint: red)
                }
                .fixedSize()
            }
            .padding(.leading, 9 * k).padding(.trailing, 11 * k)
            .frame(height: h)
            .background(Color.white)
        }
        .frame(height: h)
        .clipShape(shape)
        .overlay(shape.strokeBorder(red.opacity(0.9), lineWidth: 1.1 * k))
        .shadow(color: .black.opacity(0.10), radius: 4 * k, y: 2 * k)
    }
}

/// กระดาษรองของรูปที่ส่งออก
enum TravelPaper {
    static let color = Color(red: 0.961, green: 0.957, blue: 0.945)
    static let ink = Color(red: 0.09, green: 0.09, blue: 0.11)
}

/// หน้าตาของแถบผู้ออกใต้การ์ด — สี่แบบ แต่ละแบบยืมไวยากรณ์จากของจริงที่คนไทยเชื่ออยู่แล้ว
/// (ตราที่คิดขึ้นเองถูกตีกลับสี่รอบ 30 ก.ย. 2569: "ไม่สวย ไม่ดูน่าเชื่อถือเลย")
enum FooterStyle: String, CaseIterable {
    /// ป้าย VERIFIED BY SALE HERE **ตัวจริงของแอป** — ป้ายเดียวกับหน้าโปรไฟล์ครีเอเตอร์ (ผู้ใช้เอาไปวางในการ์ดชมพูเองด้วย)
    case pill
    /// สลิปธนาคาร — แผ่นขาว หัวผู้ออก · รายการที่ตรวจแล้วมีติ๊กเขียว · เลขที่ · QR ตรวจสอบ
    case slip
    /// ติ๊กฟ้าแบบ IG/LINE — ฟ้าคือ "ยืนยันแล้ว" ที่ทุกคนอ่านออก + ชื่อผู้ออกตัวหนา
    case blue
    /// บัตรใน Apple Wallet / boarding pass — แถบถ่านทึบ โลโก้ขาว ตัวโมโน
    case pass

    static var override: FooterStyle?
    static var current: FooterStyle {
        if let o = override { return o }
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-footer"), a.indices.contains(i + 1), let f = FooterStyle(rawValue: a[i + 1]) { return f }
        // ผู้ใช้เลือกสลิป (30 ก.ย. 2569: "ชอบ B แต่ไม่ต้องติ๊กถูก เอา 3 ข้อ")
        return .slip
    }

    var name: String {
        switch self {
        case .pill: return "A · ป้ายตัวจริงของแอป"
        case .slip: return "B · สลิปรับรอง"
        case .blue: return "C · ติ๊กฟ้า"
        case .pass: return "D · บัตร Wallet"
        }
    }
    /// ความสูงของแถบในหน่วยออกแบบของสตอรี่ — พอร์ตคูณ 1.5
    var height: CGFloat {
        switch self {
        case .pill, .blue: return 64
        case .pass: return 68
        case .slip: return 60
        }
    }
}

/// แถบใต้การ์ดบนรูปที่ส่งออก — ผู้ออกรับรอง + QR กลับมาที่การ์ด (ดู `FooterStyle`)
struct TravelBand: View {
    let slug: String
    var style: FooterStyle = .current

    private var facts: VerifiedFacts { .current }
    private var verified: Bool { facts.verified }
    private var url: String { Signature.url(slug: slug) }
    private var stamp: String { "\(Signature.verifiedOn)  ·  \(facts.serial)" }

    var body: some View {
        GeometryReader { geo in
            // ทุกขนาดคิดจากความสูงของแถบเทียบกับสตอรี่ — พอร์ตกว้างกว่าสองเท่า แถบสูงกว่า ของข้างในโตตาม
            let k = geo.size.height / style.height
            Group {
                switch style {
                case .pill: pill(k)
                case .slip: slip(k)
                case .blue: blue(k)
                case .pass: pass(k)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: ชิ้นส่วนร่วม

    private func qr(_ k: CGFloat, size: CGFloat = 46, dark: Bool = false) -> some View {
        QRCode(text: "https://\(url)")
            .padding(4 * k)
            .background(RoundedRectangle(cornerRadius: 8 * k, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 8 * k, style: .continuous)
                .strokeBorder(TravelPaper.ink.opacity(dark ? 0 : 0.08), lineWidth: 0.8 * k))
            .frame(width: size * k, height: size * k)
    }

    private func scanLines(_ k: CGFloat, ink: Color, title: String = "สแกนเพื่อตรวจสอบ") -> some View {
        VStack(alignment: .leading, spacing: 3 * k) {
            Text(verified ? title : "สแกนดูการ์ดเต็ม")
                .font(.sh(13 * k, .semibold)).foregroundStyle(ink)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(url)
                .font(Signature.mono(9.5 * k)).tracking(0.3)
                .foregroundStyle(ink.opacity(0.5))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    private func hairline(_ k: CGFloat) -> some View {
        Rectangle().fill(TravelPaper.ink.opacity(0.12)).frame(height: 0.8 * k)
    }

    // MARK: A · ป้ายตัวจริงของแอป

    private func pill(_ k: CGFloat) -> some View {
        HStack(spacing: 13 * k) {
            qr(k)
            scanLines(k, ink: TravelPaper.ink)
            Spacer(minLength: 8 * k)
            VStack(alignment: .trailing, spacing: 4 * k) {
                if verified {
                    Image(SHIcon.verifiedPill).resizable().scaledToFit().frame(height: 34 * k)
                        .accessibilityLabel("Verified by Sale Here")
                    Text(stamp).font(Signature.mono(7.5 * k, .medium)).tracking(0.3 * k)
                        .foregroundStyle(TravelPaper.ink.opacity(0.45)).lineLimit(1).fixedSize()
                } else {
                    StarLockup(height: 28 * k, tint: SaleHereMark.red)
                }
            }
            .fixedSize()
        }
        .padding(.horizontal, 4 * k)
        .overlay(alignment: .top) { hairline(k) }
    }

    // MARK: B · สลิปรับรอง

    private func slip(_ k: CGFloat) -> some View {
        HStack(spacing: 14 * k) {
            // ซ้าย = ไอคอนสองตัวของแอป · ขวา = ติ๊ก + "Verified by Sale Here" คู่กับ QR
            // (ผู้ใช้ 30 ก.ย. 2569: "Verified by Sale Here เอาไปด้านขวา กับมีติ๊กถูกด้วย")
            HStack(spacing: 8 * k) {
                SaleHereMark(size: 34 * k)
                StarLockup(height: 27 * k, tint: SaleHereMark.red)
            }

            Spacer(minLength: 6 * k)

            HStack(spacing: 10 * k) {
                HStack(spacing: 5 * k) {
                    if verified {
                        ZStack {
                            SealShape().fill(SaleHereMark.red)
                            Image(systemName: "checkmark").font(.system(size: 8 * k, weight: .black)).foregroundStyle(.white)
                        }
                        .frame(width: 17 * k, height: 17 * k)
                    }
                    Text(verified ? "Verified by Sale Here" : "Star Card by Sale Here")
                        .font(.sh(11.5 * k, .bold)).foregroundStyle(TravelPaper.ink)
                        .lineLimit(1).fixedSize()
                }
                VStack(spacing: 3 * k) {
                    qr(k, size: 44)
                    Text(verified ? "สแกนตรวจสอบ" : "สแกนดูการ์ด")
                        .font(.sh(7.5 * k, .semibold)).foregroundStyle(TravelPaper.ink.opacity(0.7))
                        .lineLimit(1).fixedSize()
                }
            }
        }
        // ไม่มีแผ่นขาว — ของทั้งหมดวางบนกระดาษรองตรง ๆ เป็นส่วนหนึ่งของกรอบ (ผู้ใช้ 30 ก.ย. 2569: "ไม่เอาเป็น card ทำเป็นเหมือนกรอบพอ")
        .padding(.horizontal, 6 * k).padding(.vertical, 2 * k)
    }

    // MARK: C · ติ๊กฟ้า

    private func blue(_ k: CGFloat) -> some View {
        HStack(spacing: 13 * k) {
            qr(k)
            scanLines(k, ink: TravelPaper.ink)
            Spacer(minLength: 8 * k)
            HStack(spacing: 8 * k) {
                if verified {
                    ZStack {
                        SealShape().fill(GL.verified)
                        Image(systemName: "checkmark").font(.system(size: 12 * k, weight: .black)).foregroundStyle(.white)
                    }
                    .frame(width: 27 * k, height: 27 * k)
                }
                VStack(alignment: .leading, spacing: 1.5 * k) {
                    HStack(spacing: 4 * k) {
                        Text(verified ? "Verified by" : "Star Card by")
                            .font(.sh(9.5 * k, .medium)).foregroundStyle(TravelPaper.ink.opacity(0.6))
                        SaleHereMark(size: 14 * k)
                    }
                    Text("Sale Here STAR").font(.sh(13.5 * k, .black)).foregroundStyle(TravelPaper.ink)
                        .lineLimit(1).fixedSize()
                    if verified {
                        Text(stamp).font(Signature.mono(7 * k, .medium)).tracking(0.3 * k)
                            .foregroundStyle(TravelPaper.ink.opacity(0.45)).lineLimit(1).fixedSize()
                    }
                }
            }
            .fixedSize()
        }
        .padding(.horizontal, 4 * k)
        .overlay(alignment: .top) { hairline(k) }
    }

    // MARK: D · บัตร Wallet

    private func pass(_ k: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14 * k, style: .continuous)
        return HStack(spacing: 13 * k) {
            qr(k, size: 48, dark: true)
            scanLines(k, ink: .white)
            Spacer(minLength: 8 * k)
            VStack(alignment: .trailing, spacing: 3 * k) {
                HStack(spacing: 7 * k) {
                    ZStack {
                        Circle().fill(.white)
                        SymbolIcon(name: SHIcon.wordmark, size: 12 * k, tint: TravelPaper.ink)
                    }
                    .frame(width: 21 * k, height: 21 * k)
                    StarLockup(height: 19 * k, tint: .white)
                }
                Text(verified ? "VERIFIED  ·  \(Signature.verifiedOn)  ·  \(facts.serial)" : "STAR CARD")
                    .font(Signature.mono(7.5 * k, .bold)).tracking(1.1 * k)
                    .foregroundStyle(.white.opacity(0.7)).lineLimit(1).fixedSize()
            }
            .fixedSize()
        }
        .padding(.horizontal, 14 * k)
        .background(shape.fill(TravelPaper.ink))
    }
}

/// แผ่นการ์ดทั้งใบ — ฉากหลังผืนเดียว แล้ววางหน้าเรียงกันข้างบน (ใช้ทั้งฉบับเดินทางและพรีวิว)
struct CardSheet: View {
    let pages: [CardPage]
    let theme: CardTheme
    let pageSize: CGSize
    let format: CardFormat

    var body: some View {
        let sheet = CGSize(width: pageSize.width * CGFloat(format.pageCount), height: pageSize.height)
        ZStack {
            CardBackdrop(theme: theme, ignoreSafeArea: false, signed: true)
            HStack(spacing: 0) {
                ForEach(0..<format.pageCount, id: \.self) { i in
                    let page = pages.indices.contains(i) ? pages[i] : CardPage()
                    CardPageCanvas(page: page, size: pageSize, theme: theme)
                        .frame(width: pageSize.width, height: pageSize.height)
                }
            }
            // ตราปั๊มนูนกดลงบนแผ่นที่พิมพ์เสร็จแล้ว — เหนือ widget ทุกชิ้น (ดู `SignatureEmboss`)
            if theme.strip.isStamp {
                SignatureEmboss(light: theme.inkStyle.isLight, foil: theme.strip == .foil,
                                tint: theme.inkStyle.base, pages: pages, pageSize: pageSize)
            }
        }
        .frame(width: sheet.width, height: sheet.height)
        .clipped()
        .environment(\.cardInk, theme.inkStyle)
        .environment(\.colorScheme, theme.activeInk.isLight ? .light : .dark)
        .transaction { $0.animation = nil }
    }
}

/// หนึ่งหน้าของการ์ดแบบนิ่ง — เฉพาะ widget ไม่มีฉากหลังของตัวเอง
///
/// วางด้วย `.position` ไม่ใช่ `.offset` เพราะ ImageRenderer มักทิ้ง offset
/// แถบผู้ออกบัตรอยู่ที่ขอบล่างของทุกหน้าเสมอ — พรีวิวในคลัง รูปเทมเพลต และรูปที่ส่งออก
/// ผ่านตัวนี้ทั้งหมด สิ่งที่เห็นจึงตรงกับสิ่งที่ได้
struct CardPageCanvas: View {
    let page: CardPage
    let size: CGSize
    let theme: CardTheme
    /// รูปย่อที่เจ้าของการ์ดเห็นเอง — ใบที่ล็อกโชว์ตัวอย่างใต้ชั้นเทาเหมือนในห้องแต่ง (ดู `WidgetChrome.lockPreview`)
    var lockPreview = false

    var body: some View {
        let solved = PageLayout.solve(page.items, page: size)
        ZStack {
            ForEach(solved) { p in
                WidgetChrome(placed: p, theme: theme, lockPreview: lockPreview)
                    .frame(width: p.frame.width, height: p.frame.height)
                    .position(x: p.frame.midX, y: p.frame.midY)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .environment(\.cardInk, theme.inkStyle)
        .environment(\.pageContentWidth, PageLayout.content(size).width)
    }
}
