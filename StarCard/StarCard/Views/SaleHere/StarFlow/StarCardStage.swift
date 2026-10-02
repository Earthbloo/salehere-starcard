import SwiftUI
import PhosphorSwift

// MARK: - Star Card บนหน้า Star Profile (ผู้ใช้ 24 ก.ย. 2569)
//
// ปุ่มสลับ ข้อมูล | การ์ด เลิกใช้แล้ว ("ไม่เวิค · เข้า Profile มาแล้วต้องรู้ว่ามีการ์ด") และลองมาแล้วที่ไม่ผ่าน:
// - เวทีการ์ดใหญ่บนสุด → "โครตแปลก · หน้านี้เน้นกรอกข้อมูล ข้อมูลหายไปหมด"
// - แถวแยกที่ย้อมพื้นด้วยสีการ์ดเบลอ → สีเข้มกลายเป็นม่วงน้ำตาลหม่น + กล่องขอบเหลืองสองก้อนแย่งกัน ("นี่สวยละหรอ")
// ตอนนี้: Star Card เป็นหมวดสุดท้ายในการ์ดข้อมูลใบเดิม (แบบเดียวกับหมวด "ช่องทาง") — วัตถุชิ้นเดียว วัสดุเดียวกับหน้า
// สีของการ์ดอยู่แค่ในรูปย่อที่คมชัด ไม่ย้อมอะไรรอบข้าง · แตะ = เปิดแบบที่แบรนด์เห็น (Profile preview)

/// รูปนิ่งของการ์ดใบจริง — อบครั้งเดียวด้วย ImageRenderer (แบบ `TemplateThumbs.render`) ไม่สร้าง widget สดบนหน้านี้
enum StarCardImage {
    @MainActor private static var cache: [String: UIImage] = [:]

    /// รุ่นของรูป — การ์ดถูกแก้ หรือข้อมูลที่ widget วาด (โปรไฟล์ · รูป · ผลงาน) เปลี่ยน = อบใหม่
    @MainActor
    static func key(_ record: CardRecord, photos: PhotoStore) -> String {
        "\(record.id)-\(record.updatedAt.timeIntervalSince1970)-\(Profile.me.revision)-\(photos.profileRevision)-\(Portfolio.shared.revision)"
    }

    @MainActor
    static func bake(_ record: CardRecord, photos: PhotoStore, key: String) async -> UIImage? {
        if let hit = cache[key] { return hit }
        // รอรูปตั้งต้นให้มาก่อน ไม่งั้นอบช่องว่างติดไปในรูป
        await withTaskGroup(of: Void.self) { group in
            for u in (0..<PhotoLib.count).map({ PhotoLib.url($0) }) {
                group.addTask { _ = await ImageCache.shared.load(u) }
            }
        }
        guard let restored = record.restored() else { return nil }
        let pages = restored.pages, theme = restored.theme
        let content: AnyView
        switch record.format {
        case .portfolio:
            content = AnyView(CardStripPreview(pages: pages, theme: theme, width: 300, showsDividers: false,
                                               gutter: CardTemplate.thumbGutter, margin: CardTemplate.thumbGutter,
                                               cornerRadius: 14))
        case .story:
            content = AnyView(CardFramePreview(page: pages.first ?? CardPage(), theme: theme,
                                               pageSize: CardTemplate.previewPageSize(for: .story),
                                               height: 220, cornerRadius: 14))
        }
        let renderer = ImageRenderer(content: content.environment(photos))
        renderer.scale = TemplateWall.screen?.scale ?? 3
        renderer.isOpaque = false
        let ui = renderer.uiImage
        if let ui { cache[key] = ui }
        return ui
    }
}

/// หมวด "Star Card" ท้ายการ์ดข้อมูล — หัว "Star *Card*" + รูปย่อตามแนวจริงติดป้าย "กำลังแสดงอยู่" + ปุ่ม ดูการ์ด + ไอคอนแชร์
/// ไม่มีชื่อการ์ด (ผู้ใช้ 24 ก.ย. 2569: "ดูการ์ด แชร์การ์ดต้องมี ชื่อไม่ต้องมี") · ดูการ์ด/แตะรูป = หน้า Star Card ของฉัน
struct StarCardSection: View {
    let record: CardRecord
    /// การ์ดตั้งต้นที่ทุกคนมี — ยังไม่เปิดใช้: ป้าย "รอคุณเปิด" · ไม่มีแชร์ · ปุ่มชวนเข้าไปดู
    var isDefault = false
    /// ยังไม่ได้เป็น STAR = การ์ดยังไม่ได้แสดงให้ใครเห็น — ไม่ขึ้นป้าย "กำลังแสดงอยู่" และไม่มีปุ่มแชร์ (audit 29 ก.ย. 2569)
    var published = true
    let onOpen: () -> Void

    @Environment(PhotoStore.self) private var photos
    @Environment(ClipInvocation.self) private var invocation
    @State private var image: UIImage?

    /// สูงเท่ากันทุกใบ กว้างตามแนว — แนวนอนเป็นแถบกว้าง แนวตั้งเป็นแผ่นแคบ
    private var thumb: CGSize { record.format == .portfolio ? CGSize(width: 116, height: 70) : CGSize(width: 40, height: 70) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // หัวหมวด = หัวหน้าย่อส่วน: ตรา ST★R + "Card" serif เอียงไล่หมึก→ทอง (ตราแทนคำ Star ตั้งแต่ 30 ก.ย. 2569)
            HStack(alignment: .lastTextBaseline, spacing: StarCaps.gap(forSerif: 22)) {
                StarCaps(height: StarCaps.height(forSerif: 22))
                Text("Card").font(GL.serif(22))
                    .foregroundStyle(LinearGradient(colors: [GL.ink, GL.ink, GL.goldInk], startPoint: .top, endPoint: .bottom))
                if isDefault {
                    Text("ของคุณพร้อมแล้ว · ตอบ 3 ข้อแล้วเปิดดูได้เลย").font(.sh(12)).foregroundStyle(GL.muted).lineLimit(1)
                        .padding(.leading, 4)
                }
            }
            HStack(spacing: 14) {
                Button {
                    Haptics.impact(.light)
                    onOpen()
                } label: { thumbnail }
                .buttonStyle(DockPress())
                // ดูการ์ด = ปุ่มหลักของหมวด · แชร์ = ไอคอนเล็กข้าง ๆ (ผู้ใช้ 24 ก.ย. 2569: "ความสำคัญเท่ากันเลยหรอ")
                HStack(spacing: 8) {
                    pill(isDefault ? "เปิดการ์ดของฉัน" : "ดูการ์ด", isDefault ? .sparkle : .eye, dark: isDefault, action: onOpen)
                    if !isDefault && published { Button {
                        Haptics.impact(.light)
                        ShareSheet.present(CardLibrary.shared.url(for: record, slug: invocation.slug))
                    } label: {
                        PIcon(.shareNetwork, size: 15, weight: .bold).foregroundStyle(GL.ink)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.85)))
                            .overlay(Circle().strokeBorder(GL.ink.opacity(0.1), lineWidth: 1))
                            .contentShape(Circle())
                    }
                    .buttonStyle(DockPress())
                    .accessibilityLabel("แชร์การ์ด") }
                }
            }
            .padding(.top, 4)
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { GL.ink.opacity(0.08).frame(height: 1) }
        .animation(Motion.settle, value: image == nil)
        .task(id: StarCardImage.key(record, photos: photos)) {
            image = await StarCardImage.bake(record, photos: photos, key: StarCardImage.key(record, photos: photos))
        }
    }

    private var thumbnail: some View {
        ZStack {
            if let image {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fit)
                    .shadow(color: GL.ink.opacity(0.18), radius: 5, y: 3)
                    .transition(.opacity)
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(GL.ink.opacity(0.06))
            }
        }
        .frame(width: thumb.width, height: thumb.height)
        // ป้ายเดียวกับใบที่เผยแพร่อยู่ในคลัง — เกาะมุมซ้ายบนของรูป
        .overlay(alignment: .topLeading) {
            if isDefault || published {
                HStack(spacing: 4) {
                    Circle().fill(isDefault ? GL.gold : SHColor.success).frame(width: 5, height: 5)
                    Text(isDefault ? "รอคุณเปิด" : "กำลังแสดงอยู่").font(.sh(9.5, .bold)).fixedSize()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 7).frame(height: 18)
                .background(Capsule().fill(.black.opacity(0.62)))
                .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 0.6))
                .offset(x: -5, y: -9)
            }
        }
    }

    private func pill(_ title: String, _ icon: Ph, dark: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            HStack(spacing: 6) {
                PIcon(icon, size: 14, weight: .bold)
                Text(title).font(.sh(13.5, .bold))
            }
            .foregroundStyle(dark ? .white : GL.ink)
            .frame(maxWidth: .infinity).frame(height: 36)
            .background(Capsule().fill(dark ? GL.ink : .white.opacity(0.85)))
            .overlay(Capsule().strokeBorder(dark ? .clear : GL.ink.opacity(0.1), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(DockPress())
    }
}

/// แผ่นแชร์ของระบบ เปิดตรงจาก UIKit — presentation ของ SwiftUI ในหน้าที่ซ้อนใน ZStack ของ shell ไม่ขึ้นเสมอ (ดู `MediaPicker`)
enum ShareSheet {
    @MainActor
    static func present(_ url: URL) {
        guard var top = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController
        else { return }
        while let next = top.presentedViewController { top = next }
        top.present(UIActivityViewController(activityItems: [url], applicationActivities: nil), animated: true)
    }
}
