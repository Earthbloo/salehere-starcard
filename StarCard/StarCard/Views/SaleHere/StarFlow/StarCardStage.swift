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
    /// ปุ่มเล็กใต้ปุ่ม "ดูการ์ด" (ไอคอนกราฟ + ยอดวิว) → หน้า ST★R Insight · nil = ไม่มีปุ่ม
    /// โผล่เฉพาะใบที่เผยแพร่แล้ว — การ์ดที่ยังไม่มีใครเห็นไม่มีสถิติให้ดู
    var onInsight: (() -> Void)? = nil
    /// ยังไม่เคยเปิดการ์ด: แตะเทมเพลตในแถบตัวอย่าง = เริ่มการ์ดใบแรกจากแบบนั้น · nil = ใช้หน้าตาเดิม (รูปย่อ + ปุ่ม)
    var onPickTemplate: ((CardTemplate) -> Void)? = nil

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
                    Text(onPickTemplate != nil ? "รอคุณเปิดใช้งาน" : "ของคุณพร้อมแล้ว · เปิดดูได้เลย").font(.sh(12)).foregroundStyle(GL.muted).lineLimit(1)
                        .padding(.leading, 4)
                }
            }
            if isDefault, let onPickTemplate {
                // ยังไม่เคยเปิดการ์ด = โชว์แบบให้ดูก่อน: แถบเทมเพลตเลื่อนเอง แตะใบไหนก็เริ่มจากใบนั้น (feedback 5 ต.ค. 2569)
                // เคยเปิดแล้ว = แถวเดิม (รูปย่อใบที่แสดงอยู่ + ดูการ์ด + แชร์ + ยอดวิว)
                ActivateTease(onOpen: onOpen)
            } else {
            HStack(spacing: 14) {
                Button {
                    Haptics.impact(.light)
                    onOpen()
                } label: { thumbnail }
                .buttonStyle(DockPress())
                VStack(spacing: 8) {
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
                    // ยอดวิว → ST★R Insight อยู่ใต้ปุ่มดูการ์ด (ผู้ใช้ 4 ต.ค. 2569: "ปุ่มไว้ข้างล่างดู card")
                    if let onInsight, published && !isDefault { InsightChip(onOpen: onInsight) }
                }
            }
            .padding(.top, 4)
            }
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

/// การ์ดที่ยังไม่ได้เปิดใช้งาน — โชว์แบบการ์ดให้ดูเฉย ๆ เป็นพัด 3 ใบ ค่อย ๆ เปลี่ยน แล้วมีปุ่ม "เปิดใช้งาน"
///
/// ลำดับที่ผู้ใช้ตีกลับ 5 ต.ค. 2569: แถบรูปเรียง → เวทีดำ → พัด 3 ใบหน้าการ์ดละลายเปลี่ยน "สวยนะ" → ใบเดียวเปลี่ยนรูปทรงนอน/ตั้ง "มั่ว"
/// → สองกองแยกแนว "โชว์แค่อย่างเดียว" → ใบเดียวสลับ → "เอา 3 อันเหมือนเดิม แต่ค่อยๆเปลี่ยน"
/// ตอนนี้: พัด 3 ใบ (ใบหน้า + ใบซ้อนหลังสองใบ) โชว์ทีละชุด แนวเดียวกันทั้งชุด — ชุดแนวตั้ง (Story) สลับกับชุดแนวนอน (Portfolio)
/// เปลี่ยนชุด = จางสลับทั้งพัด 0.75 วิ ค้าง 2.6 วิ (รุ่น 1.8 วิ "ช้าไป" · แสงกวาด/เงารุ่นแรก "เข้มไป ช้าไป") ไม่มีใบไหนยืดหดหรือกระโดด · ชุดที่ซ่อนอยู่เลื่อนแบบของตัวเองไปหนึ่งใบระหว่างที่มองไม่เห็น
/// พัดลอยขึ้นลงเบา ๆ · ไม่มีแสงกวาด/ขอบทอง/ป้าย · ปุ่มขาวนิ่ง · แตะการ์ดหรือปุ่ม = เปิด Star Card ตาม flow เดิม · Reduce Motion = นิ่ง
private struct ActivateTease: View {
    let onOpen: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showWide = false
    @State private var tall = 0
    @State private var wide = 0
    @State private var float = false
    private let talls = CardTemplate.all(for: .story)
    private let wides = CardTemplate.all(for: .portfolio)

    var body: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.impact(.medium)
                onOpen()
            } label: {
                // เพิ่มความน่าสนใจอีกนิด (ผู้ใช้ 5 ต.ค. 2569: "จืดไปนิด เพิ่มสัก 10%") — ทุกอย่างเบาและช้า ไม่มีสีเพิ่ม:
                // ใบหน้าเอียงซ้ายขวาช้า ๆ แบบมีมิติ · ใบหลังขยับสวนเล็กน้อย · แสงกวาดผ่านใบหน้านาน ๆ ครั้ง · พัดกางออกตอนชุดใหม่จางเข้า · เงาพื้นหายใจตามการลอย
                TimelineView(.animation(paused: reduceMotion)) { tl in
                    let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
                    let tallOn = !(showWide && !wides.isEmpty), wideOn = showWide || talls.isEmpty
                    ZStack {
                        Ellipse().fill(GL.ink.opacity(0.05)).frame(width: 190, height: 18).blur(radius: 10)
                            .scaleEffect(x: float ? 0.9 : 1.04).offset(y: 106)
                        if !talls.isEmpty {
                            fan(talls, front: tall, size: CGSize(width: 110, height: 196),
                                backs: [(-44, 10, -11, 0.86), (42, 8, 9, 0.9)], open: tallOn, t: t)
                                .opacity(tallOn ? 1 : 0)
                                .scaleEffect(tallOn ? 1 : 0.95)
                        }
                        if !wides.isEmpty {
                            fan(wides, front: wide, size: CGSize(width: 232, height: 128),
                                backs: [(-22, 22, -7, 0.9), (22, -20, 6, 0.93)], open: wideOn, t: t)
                                .opacity(wideOn ? 1 : 0)
                                .scaleEffect(wideOn ? 1 : 0.95)
                        }
                    }
                    .offset(y: float ? -4 : 3)
                    .frame(maxWidth: .infinity).frame(height: 226)
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(DockPress())
            .accessibilityLabel("Star Card ยังไม่ได้เปิดใช้งาน ตัวอย่างแบบการ์ดแนวตั้งและแนวนอน")

            Button {
                Haptics.impact(.medium)
                onOpen()
            } label: {
                HStack(spacing: 7) {
                    PIcon(.sparkle, size: 15, weight: .bold)
                    Text("เปิดใช้งาน").font(.sh(15, .bold))
                }
                .foregroundStyle(GL.ink)
                .frame(maxWidth: .infinity).frame(height: 46)
                .background(Capsule().fill(.white))
                .overlay(Capsule().strokeBorder(GL.ink.opacity(0.14), lineWidth: 1))
                .contentShape(Capsule())
            }
            .buttonStyle(DockPress())
        }
        .padding(.top, 4)
        .task {
            guard !reduceMotion, !talls.isEmpty, !wides.isEmpty else { return }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) { float = true }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_600_000_000)
                withAnimation(.easeInOut(duration: 0.75)) { showWide.toggle() }
                // รอให้จางสลับจบ แล้วเลื่อนแบบของชุดที่เพิ่งถูกซ่อน (มองไม่เห็นตอนเปลี่ยน)
                try? await Task.sleep(nanoseconds: 850_000_000)
                if showWide { tall = (tall + 1) % talls.count } else { wide = (wide + 1) % wides.count }
            }
        }
    }

    /// พัดแนวเดียว 3 ใบ: ใบซ้อนหลังสองใบ (แบบถัด ๆ ไป วนซ้ำถ้ามีไม่ถึงสาม) + ใบหน้า · `backs` = (x, y, องศา, สเกล) ไกลสุดก่อน
    /// `open` = ชุดนี้กำลังโชว์ (ใบหลังกางเต็ม) · ซ่อนอยู่ = หุบเข้าหาใบหน้า แล้วกางออกตอนจางเข้า
    private func fan(_ list: [CardTemplate], front: Int, size: CGSize, backs: [(CGFloat, CGFloat, Double, CGFloat)],
                     open: Bool, t: Double) -> some View {
        let spread: CGFloat = open ? 1 : 0.5
        let sway = sin(t * 0.7)
        let sweep = (t.truncatingRemainder(dividingBy: 3.4)) / 3.4
        return ZStack {
            ForEach(Array(backs.enumerated()), id: \.offset) { k, b in
                face(list[(front + backs.count - k) % list.count], size)
                    .shadow(color: GL.ink.opacity(0.11), radius: 6, y: 4)
                    .brightness(-0.03 * Double(backs.count - k))
                    .scaleEffect(b.3)
                    .rotationEffect(.degrees(b.2 * Double(spread) - sway * 1.3 * (b.2 < 0 ? -1 : 1)))
                    .offset(x: b.0 * spread - CGFloat(sway) * 2, y: b.1 * spread)
            }
            face(list[front % list.count], size)
                .overlay {
                    LinearGradient(colors: [.clear, .white.opacity(0.2), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: size.width * 0.4).rotationEffect(.degrees(18))
                        .offset(x: -size.width + size.width * 2 * min(1, sweep / 0.18))
                        .opacity(open && sweep < 0.18 ? 1 : 0)
                        .blendMode(.plusLighter)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white.opacity(0.85), lineWidth: 1))
                .shadow(color: GL.ink.opacity(0.18), radius: 12, y: 9)
                .rotation3DEffect(.degrees(sway * 5), axis: (x: 0.15, y: 1, z: 0), perspective: 0.55)
        }
    }

    private func face(_ t: CardTemplate, _ size: CGSize) -> some View {
        Group {
            if let ui = TemplateThumbs.shared.image(for: t.id) {
                Image(uiImage: ui).resizable().aspectRatio(contentMode: .fill)
            } else {
                GL.ink.opacity(0.08)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
