import SwiftUI

// MARK: - Photos

/// คลังรูปประกอบ — โหลดจาก Mock URL ของ SaleHere
/// วันที่ต่อ ImageKit จริง แทนที่แค่ enum นี้จุดเดียว
enum PhotoLib {
    /// รูปโปรไฟล์ครีเอเตอร์ (star)
    static let profile = "https://img.salehere.co.th/p/1200x0/2025/12/12/profilecreator0jpeg-cjhwjffusbti.jpg"
    /// รูปผลงาน (review)
    static let works = [
        "https://img.salehere.co.th/p/600x0/2026/07/12/reviewtopic0jpeg-oosenzv18wzj.jpg",
        "https://img.salehere.co.th/p/600x0/2025/09/21/reviewtopic0jpeg-ope9b0rviyjx.jpg",
        "https://img.salehere.co.th/p/600x0/2025/10/15/reviewtopic0jpeg-xqf0qpdhwb6j.jpg",
    ]

    static let count = 12
    /// index 1–3 = รูปครีเอเตอร์ (hero/avatar/polaroid) · ที่เหลือวนรูปผลงาน
    static func url(_ i: Int) -> URL {
        let n = i % count
        let s = (1...3).contains(n) ? profile : works[n % works.count]
        return URL(string: s)!
    }
}

/// แคชรูปจาก Mock URL — โหลดครั้งเดียวแล้วใช้ร่วมกันทุกที่ (การ์ดจริง · พรีวิวใน gallery · thumb)
/// ไม่ใช้ AsyncImage เพราะมันยกเลิกโหลดตอน view หลุดจอ แล้วพรีวิวในกริดค้างสถานะ failure ทั้งที่เน็ตปกติ
@MainActor
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    private var inflight: [URL: Task<UIImage?, Never>] = [:]

    func cached(_ url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }

    func load(_ url: URL) async -> UIImage? {
        if let hit = cached(url) { return hit }
        if let task = inflight[url] { return await task.value }
        // แยกเป็น Task ของตัวเอง — view ที่รอถูกถอดไปก็ไม่ทำให้การโหลดล้ม
        let task = Task<UIImage?, Never> {
            for _ in 0..<2 {
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let ui = UIImage(data: data) {
                    return ui
                }
            }
            return nil
        }
        inflight[url] = task
        let ui = await task.value
        inflight[url] = nil
        if let ui { cache.setObject(ui, forKey: url as NSURL) }
        return ui
    }
}

/// โลโก้จาก Mock URL — scaledToFit บนแผ่นขาว · ระหว่างโหลดปล่อยว่างให้แผ่นขาวเป็น placeholder
struct RemoteLogo: View {
    let url: String
    @State private var ui: UIImage?

    init(url: String) {
        self.url = url
        // เช็คแคชตั้งแต่เกิด — view ที่ถูกสร้างใหม่กลางอนิเมชันวน (เช่นรางโลโก้)
        // จะได้ไม่ต้องรอรอบ task แล้วค้างเป็นแผ่นเปล่า
        if let u = URL(string: url), let hit = ImageCache.shared.cached(u) {
            _ui = State(initialValue: hit)
        }
    }

    var body: some View {
        Group {
            if let ui {
                Image(uiImage: ui).resizable().scaledToFit()
            } else {
                Color.clear
            }
        }
        .task(id: url) {
            guard ui == nil, let u = URL(string: url) else { return }
            if let hit = ImageCache.shared.cached(u) { ui = hit; return }
            ui = await ImageCache.shared.load(u)
        }
    }
}

/// รูปจาก Mock URL — เต็มกรอบที่ถูกเสนอเสมอ ผู้เรียกเป็นคน clip เอง (เหมือน Image เดิม)
struct RemotePhoto: View {
    let url: URL
    @State private var ui: UIImage?
    @Environment(\.cardInk) private var ink

    init(url: URL) {
        self.url = url
        if let hit = ImageCache.shared.cached(url) {
            _ui = State(initialValue: hit)
        }
    }

    var body: some View {
        Color.clear
            .overlay {
                if let ui {
                    Image(uiImage: ui).resizable().aspectRatio(contentMode: .fill)
                } else {
                    // ช่องว่างระหว่างโหลด — พื้นมืดใช้ขาวจาง พื้นกระดาษต้องใช้หมึกจาง
                    // ไม่งั้นช่องรูปจะหายไปกับพื้นจนดูเหมือน layout พัง
                    ink.fill(0.09)
                }
            }
            .task(id: url) {
                guard ui == nil else { return }
                if let hit = ImageCache.shared.cached(url) { ui = hit; return }
                ui = await ImageCache.shared.load(url)
            }
    }
}

/// กระเบื้องรูปหนึ่งช่อง — จัดการ scaledToFill + ขอบ + scrim ไว้ที่เดียว
struct PhotoTile: View {
    let index: Int
    var radius: CGFloat = 10
    var scrim: Bool = false
    var badge: String? = nil

    @Environment(\.cardInk) private var ink

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Color.clear
            .overlay { WidgetPhoto(index: index).aspectRatio(contentMode: .fill) }
            .overlay {
                if scrim {
                    LinearGradient(colors: [.clear, .black.opacity(0.55)],
                                   startPoint: .center, endPoint: .bottom)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if let badge {
                    HStack(spacing: 3) {
                        Image(systemName: "play.fill").font(.sh(7, .bold))
                        Text(badge).font(.sh(9, .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Capsule().fill(.black.opacity(0.42)))
                    .padding(7)
                }
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(ink.line(0.13), lineWidth: 0.5))
            .photoSlot(index)
    }
}

// MARK: - Dispatcher

struct WidgetBody: View {
    let kind: WidgetKind
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        Group {
            switch kind {
            case .artPortrait: ArtPortrait(theme: theme, size: size)
            case .artTypeOver: ArtTypeOver(theme: theme, size: size)
            case .artPolaroid: ArtPolaroid(theme: theme)
            case .heroMinimal: HeroMinimal(theme: theme, size: size)
            case .aboutText: AboutText(theme: theme)
            case .interestTags: InterestTags(theme: theme)
            case .workSchedule: WorkScheduleWidget(theme: theme)
            case .workFormat: WorkFormatWidget(theme: theme)
            case .proofBrands: ProofBrands(theme: theme)
            case .proofBrandWall: ProofBrandWall(theme: theme)
            case .proofBrandGrid: ProofBrandGrid(theme: theme)
            case .proofBrandRail: ProofBrandRail(theme: theme)
            case .proofBrandList: ProofBrandList(theme: theme)
            case .proofWork: ProofWork(theme: theme)
            case .proofTicket: ProofTicket(theme: theme)
            case .proofHolo: ProofHolo(theme: theme)
            case .proofShelf: ProofShelf(theme: theme)
            case .proofZine: ProofZine(theme: theme)
            case .statGiant: StatGiant(theme: theme, size: size)
            case .socialChips: SocialChips(theme: theme, width: size.width)
            case .artFilmstrip: ArtFilmstrip(theme: theme)
            case .artDuo: ArtDuo(theme: theme)
            case .workFeatured: WorkFeatured(theme: theme)
            case .workReel: WorkReel(theme: theme)
            case .typeMarquee: TypeMarquee(theme: theme)
            case .typeQuote: TypeQuote(theme: theme, size: size)
            case .nicheTags: NicheTags(theme: theme)
            case .heroAura: HeroAura(theme: theme, size: size)
            case .aboutNote: AboutNote(theme: theme)
            case .statWrapped: StatWrapped(theme: theme, size: size)
            case .artPhotobooth: ArtPhotobooth(theme: theme)
            case .stickerTags: StickerTags(theme: theme)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // ส่งสีธีมลงไปให้ชิ้นส่วนย่อยใช้ได้โดยไม่ต้องรับ theme เป็นพารามิเตอร์ทุกชั้น
        .environment(\.cardAccent, theme.accent)
    }
}

// MARK: - Shared parts

struct AvatarOrb: View {
    let theme: CardTheme
    var size: CGFloat = 74
    var usePhoto: Bool = true

    var body: some View {
        ZStack {
            if usePhoto {
                RemotePhoto(url: PhotoLib.url(3))
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle().fill(
                    LinearGradient(colors: [theme.accentSoft, theme.accent],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
            Circle().fill(
                RadialGradient(colors: [.white.opacity(0.28), .clear],
                               center: .init(x: 0.3, y: 0.2), startRadius: 1, endRadius: size * 0.62)
            )
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 12, y: 5)
    }
}

struct StatColumn: View {
    let value: String
    let label: String
    /// nil = ใช้สีหมึกของการ์ด
    var tint: Color? = nil
    var compact: Bool = false

    @Environment(\.cardInk) private var ink

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.statNumber(compact ? 20 : 23))
                .foregroundStyle(tint ?? ink.text(0.98))
                .lineLimit(1).minimumScaleFactor(0.55)
            Text(label)
                .font(.sh(10, .medium))
                .foregroundStyle(ink.text(0.5))
                .lineLimit(1).minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// ชิปตัวเลขผู้ติดตามเล็ก ๆ ที่ใช้ซ้ำในหลาย hero variant
struct FollowerPills: View {
    var limit: Int = 3

    @Environment(\.cardInk) private var ink

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Mock.creator.socials.prefix(limit)) { s in
                HStack(spacing: 5) {
                    BrandIcon(name: s.type.icon, size: 9.5 * 1.15)
                    Text(Fmt.compact(s.followerCount)).font(.sh(11, .bold))
                }
                .foregroundStyle(ink.text(0.9))
                .padding(.horizontal, 8).padding(.vertical, 4.5)
                .background(Capsule().fill(ink.fill(0.14)))
                .overlay(Capsule().strokeBorder(ink.line(0.16), lineWidth: 0.5))
                .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }
}
