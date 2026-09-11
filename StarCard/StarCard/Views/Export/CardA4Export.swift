import SwiftUI
import UIKit

/// รูปที่ส่งออกจากการ์ด — รูปร่างขึ้นกับ `CardFormat`
///
/// * `.portfolio` — แถบ 3 หน้าต่อกันแนวนอน สัดส่วนเท่าจอที่วาง ไม่บังคับ A4
/// * `.story` — หน้าเดียว 9:16 ที่ความกว้าง 1080px ลงฟีดได้ตรง ๆ
///
/// ฉากหลังวาดครั้งเดียวคลุมทั้งผืน หน้าละคอลัมน์ที่ขนาดจริง
enum CardExport {
    /// พื้นที่ออกแบบกว้าง 540pt และปลายทางคือ 1080px — สเกลจึงเป็น 2 พอดีทุกแบบ
    ///
    /// เรนเดอร์ 1:1 กับพิกเซลปลายทางแปลว่าไม่มีการย่อ/ขยายซ้ำ ซึ่งเป็นที่มาของ
    /// ตัวหนังสือเบลอบนสตอรี่ · และพอพื้นที่ออกแบบตายตัวแล้ว ขนาดไฟล์ก็ตายตัวตามไปด้วย
    /// ไม่ขึ้นกับว่าใครแต่งมาจากเครื่องอะไร
    static let pixelWidth: CGFloat = 1080

    /// ผืนที่จะเรนเดอร์จริง — กว้าง 3 หน้าเมื่อเป็นพอร์ต · หน้าเดียวเมื่อเป็นสตอรี่
    static func canvas(pageSize: CGSize, format: CardFormat) -> CGSize {
        CGSize(width: pageSize.width * CGFloat(format.pageCount), height: pageSize.height)
    }

    /// สเกลของ `ImageRenderer` — คำนวณย้อนจากพิกเซลปลายทาง ไม่ใช่ตั้งเป็นค่าคงที่
    static func scale(pageSize: CGSize, format: CardFormat) -> CGFloat {
        guard pageSize.width > 1 else { return 2 }
        return pixelWidth / pageSize.width
    }

    @MainActor
    static func render(pages: [CardPage], theme: CardTheme, photos: PhotoStore,
                       pageSize: CGSize, format: CardFormat = .portfolio) -> UIImage? {
        let size = resolvedPageSize(pageSize, format: format)
        let sheet = canvas(pageSize: size, format: format)
        let view = CardSheet(pages: pages, theme: theme, pageSize: size, format: format)
            .environment(photos)
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(width: sheet.width, height: sheet.height)
        renderer.scale = scale(pageSize: size, format: format)
        renderer.isOpaque = true
        return renderer.uiImage
    }

    @MainActor
    static func jpegFile(pages: [CardPage], theme: CardTheme, photos: PhotoStore,
                         pageSize: CGSize, slug: String,
                         format: CardFormat = .portfolio) -> (image: UIImage, url: URL)? {
        guard let image = render(pages: pages, theme: theme, photos: photos,
                                 pageSize: pageSize, format: format),
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

/// แผ่นพิมพ์ทั้งใบ — ฉากหลังผืนเดียว แล้ววางหน้าเรียงกันข้างบน
private struct CardSheet: View {
    let pages: [CardPage]
    let theme: CardTheme
    let pageSize: CGSize
    let format: CardFormat

    var body: some View {
        let sheet = CardExport.canvas(pageSize: pageSize, format: format)
        ZStack {
            CardBackdrop(theme: theme, ignoreSafeArea: false)
            HStack(spacing: 0) {
                ForEach(0..<format.pageCount, id: \.self) { i in
                    let page = pages.indices.contains(i) ? pages[i] : CardPage()
                    CardPageCanvas(page: page, size: pageSize, theme: theme)
                        .frame(width: pageSize.width, height: pageSize.height)
                }
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
struct CardPageCanvas: View {
    let page: CardPage
    let size: CGSize
    let theme: CardTheme

    var body: some View {
        let solved = PageLayout.solve(page.items, page: size)
        ZStack {
            ForEach(solved) { p in
                WidgetChrome(placed: p, theme: theme)
                    .frame(width: p.frame.width, height: p.frame.height)
                    .position(x: p.frame.midX, y: p.frame.midY)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .environment(\.cardInk, theme.inkStyle)
    }
}
