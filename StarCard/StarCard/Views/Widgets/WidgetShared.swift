import SwiftUI
import PhosphorSwift

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
    /// ช่องรูปครีเอเตอร์ (1–3) — รูปโปรไฟล์ที่อัปโหลดจากหน้า "ข้อมูลของฉัน" จะมาแทนช่องพวกนี้
    static func isProfileSlot(_ i: Int) -> Bool { (1...3).contains(i % count) }
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
                    // แถบแสงกวาดบอกว่า "กำลังมา" — วิ่งเฉพาะระหว่างโหลด พอรูปมาก็ดับตัวเอง
                    ink.fill(0.09)
                        .overlay {
                            TimelineView(.animation(minimumInterval: 1 / 30)) { tl in
                                let t = tl.date.timeIntervalSinceReferenceDate
                                    .truncatingRemainder(dividingBy: 1.4) / 1.4
                                GeometryReader { geo in
                                    LinearGradient(
                                        colors: [.clear, ink.fill(0.1), .clear],
                                        startPoint: .leading, endPoint: .trailing)
                                    .frame(width: geo.size.width * 0.7)
                                    .offset(x: geo.size.width * (CGFloat(t) * 2 - 1))
                                }
                            }
                            .clipped()
                        }
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

/// ยอดบันทึกกับยอดแชร์ของผลงานหนึ่งชิ้น — **ไอคอนแทนคำ**
///
/// เดิมเขียนว่า "บันทึก 42.6K · แชร์ 18.9K" ซึ่งกินความกว้างเกือบเท่ายอดวิว
/// ทั้งที่มันเป็นบรรทัดรอง พอมีสามช่องเรียงกันคำเลยถูกย่อจนอ่านไม่ออกอยู่ดี
/// ไอคอนกินที่หนึ่งในสี่ของคำ และเป็นสัญลักษณ์ที่คนรุ่นนี้อ่านออกโดยไม่ต้องมีคำกำกับ
///
/// สองค่านี้ต้องมีครบทุกแบบในชั้นหลักฐาน ไม่ใช่เฉพาะบางแบบ —
/// ยอดวิวบอกว่า "คนเห็นเยอะแค่ไหน" ส่วนบันทึก/แชร์บอกว่า "คนเห็นแล้วทำอะไรต่อ"
/// ซึ่งเป็นคำถามที่แบรนด์ถามจริงกว่า และเป็นตัวที่ผูกกับ intent ซื้อในสายบิวตี้
struct WorkDeepStats: View {
    let work: VerifiedWork
    var size: CGFloat = 9
    var tint: Color
    var lead: Double = 0.22

    @Environment(\.pageScrub) private var scrub

    var body: some View {
        HStack(spacing: 10) {
            stat("bookmark.fill", work.saves, i: 0)
            stat("arrowshape.turn.up.right.fill", work.shares, i: 1)
            Spacer(minLength: 0)
        }
        .lineLimit(1).minimumScaleFactor(0.65)
    }

    private func stat(_ icon: String, _ value: Int, i: Int) -> some View {
        HStack(spacing: 3.5) {
            Image(systemName: icon)
                .font(.system(size: size * 0.92, weight: .semibold))
            Text(Fmt.compact(value)).dataValue()
                .font(.sh(size, .bold))
        }
        .foregroundStyle(tint)
        .fixedSize()
        .scrubVeil(scrub.d, lead: lead + Double(i) * 0.05, drop: 16, pull: 10)
    }
}

// MARK: - Dispatcher

/// แผ่นโปสเตอร์สีธีม — **สูตรเดียวของทั้งตู้**
///
/// ใบที่เป็น "แผ่นพิมพ์" (โปสเตอร์สายงาน · แผ่นโชว์คลิป) ไม่ได้ครอบกระจกของ `WidgetChrome`
/// แต่วาดแผ่นของตัวเอง — ซึ่งแปลว่าถ้าต่างคนต่างคิดสีเอง การ์ดใบเดียวจะมีแผ่นสีเลือดหมู
/// สองเฉดที่ไม่ตรงกันวางซ้อนกันอยู่ · สีจึงมาจากที่นี่ที่เดียว
///
/// **เฉดมาจากสีที่เจ้าของการ์ดเลือก** (`backdropHue` — พาเลตต์ หรือสีที่เขาตั้งเอง)
/// ส่วนความสด/ความสว่างถูกตรึงไว้ที่ค่าของ *แผ่นพิมพ์*: เข้มพอให้ตัวหนังสือครีมอ่านออกเสมอ
/// ไม่ว่าเขาจะเลือกสีไหน — นี่คือสิ่งเดียวที่วิดเจ็ตตัดสินใจเอง ที่เหลือเป็นของเขาทั้งหมด
enum PosterPlate {
    /// แผ่นเข้มอิ่มสีตามเฉดของการ์ด
    static func plate(_ theme: CardTheme) -> Color {
        // คู่สีมีสีเข้มของมันเองอยู่แล้ว — คิดใหม่จากเฉดเมื่อไหร่ แผ่นจะเป็นสีที่ไม่มีอยู่ในคู่
        if let d = theme.duoDark { return d }
        return Color(hue: theme.backdropHue, saturation: 0.60, brightness: 0.255)
    }

    /// ครีมที่อมเฉดเดียวกับแผ่น — ขาวสนิทบนแผ่นเข้มอ่านเป็นตัวอักษรของระบบ ไม่ใช่หมึกของงาน
    static func cream(_ theme: CardTheme) -> Color {
        if let l = theme.duoLight { return l }
        return Color(hue: theme.backdropHue, saturation: 0.085, brightness: 0.95)
    }
}

/// # แผ่นที่จัดหน้ามาแล้ว — **พื้นเต็มกรอบเสมอ ทุกเคส ไม่มีข้อยกเว้น**
///
/// สำรับโปสเตอร์ (`WidgetKind.keepsDesignAspect`) วาดผังของตัวเองที่ขนาดออกแบบตายตัว
/// แล้วสเกลทั้งก้อน — ซึ่งเคยแปลว่า **ลากกรอบให้กว้างขึ้นแล้วแผ่นไม่ขยับ** เพราะสเกลถูกล็อก
/// ด้วยความสูง ที่ว่างด้านขวาจึงเป็นการ์ดเปล่าโผล่ออกมาข้าง ๆ แผ่น ซึ่งอ่านเป็นของที่พัง
///
/// ที่นี่แยกสองเรื่องออกจากกันเด็ดขาด:
/// - **สเกล** (`k`) มาจากแกนที่คับที่สุด — ของข้างในจึงไม่ถูกบีบสักแกน
/// - **ผัง** (`size`) ยืดในหน่วยออกแบบจนคูณ `k` แล้วเท่ากรอบเป๊ะ *ทั้งสองแกน*
///
/// ผลคือ `size.width * k == frame.width` และ `size.height * k == frame.height` เสมอ
/// (ทั้งตอนกว้างกว่าผัง เตี้ยกว่าผัง หรือสัดส่วนเพี้ยนไปทางไหนก็ตาม) — แผ่นเต็มกรอบทุกกรณี
/// ส่วนที่ได้เพิ่มมาเป็น *พื้นที่ของผัง* ที่ใบนั้นเอาไปกระจายเอง (ปีกถอยออกหาขอบ · แถวกระจาย ·
/// คนยังยืนกลางช่องเดิม) ไม่ใช่รูปที่ถูกดึงให้ยาว — ดู `WidgetChrome` "กรอบคือคอนเทนเนอร์"
struct PosterSheet<Content: View>: View {
    /// ขนาดอ้างอิงของผัง — ความกว้าง/สูงต่ำสุดในหน่วยออกแบบ
    let design: CGSize
    /// กรอบจริงที่ชิ้นนี้ได้รับ (`WidgetBody.size`)
    let frame: CGSize
    /// ผังในหน่วยออกแบบที่ยืดแล้ว — ใบนั้นต้องวาดให้เต็มขนาดนี้ ไม่ใช่เต็ม `design`
    @ViewBuilder var content: (CGSize) -> Content

    var body: some View {
        let fw = max(frame.width, 1), fh = max(frame.height, 1)
        let k = max(min(fw / max(design.width, 1), fh / max(design.height, 1)), 0.01)
        let box = CGSize(width: max(design.width, fw / k), height: max(design.height, fh / k))
        content(box)
            .frame(width: box.width, height: box.height, alignment: .topLeading)
            .scaleEffect(k, anchor: .topLeading)
            .frame(width: fw, height: fh, alignment: .topLeading)
    }
}

struct WidgetBody: View {
    let kind: WidgetKind
    let theme: CardTheme
    let size: CGSize

    /// หมึกของ *พื้นที่ชิ้นนี้นั่งอยู่จริง* — ไม่ใช่ของการ์ดทั้งใบ
    /// ชิ้นที่อยู่บนแผ่นเข้มทึบได้เวทีมืดของตัวเอง แม้การ์ดจะเป็นกระดาษ (ดู `WidgetChrome`)
    @Environment(\.cardInk) private var ink

    /// ตู้ widget วาดใบเต็ม ๆ ด้วยข้อมูลตัวอย่างเสมอ (ค่าเป็นแท่งว่างถ้ายังไม่กรอก) — ไม่ขึ้นป้ายรอกรอกแทนใบ
    @Environment(\.sampleData) private var sampleOK

    /// ตระกูลที่ต้องใช้ข้อมูลจากระบบ (แคมเปญ · OAuth) หรือข้อมูลที่ยังไม่ได้กรอก — ว่าง = บอกตรง ๆ ไม่วาดของปลอม
    private var pending: String? {
        if sampleOK { return nil }
        let c = Profile.me.creator
        let sample = Profile.me.sampleFamilies
        // เว้นวรรคเมื่อชื่อแหล่งขึ้นต้นด้วยตัวละติน ("รอ OAuth …") — ตัวไทยติดกันได้ ("รอประวัติแคมเปญ…")
        let src = kind.family.contract.source.rawValue
        let source = (src.first?.isASCII ?? false) ? " " + src : src
        switch kind.family {
        case .brand:     return c.track.brands.isEmpty ? "แบรนด์ที่เคยร่วมงาน — รอ\(source)" : nil
        case .verified:  return c.track.works.isEmpty ? "ผลงานยืนยัน — รอ\(source)" : nil
        case .audience:  return c.audience.isEmpty ? "ข้อมูลผู้ชม — รอ\(source)" : nil
        case .followers: return sample.contains(.followers) ? "ยังไม่ใส่ช่องทาง — กรอกใน Star Profile" : nil
        case .rate:      return sample.contains(.rate) ? "ยังไม่ตั้งเรท — กรอกใน Star Profile" : nil
        default:         return nil
        }
    }

    var body: some View {
        Group {
            if let pending {
                SystemPending(text: pending, family: kind.family)
            } else {
            switch kind {
            case .artTypeOver: ArtTypeOver(theme: theme, size: size)
            case .artPortfolio: ArtPortfolioPoster(theme: theme, size: size)
            // สำรับหน้าต่าง — ผังของมันเป็น *แผ่น* จึงรับขนาดเต็มไปคำนวณเองทั้งใบ
            case .portfolioWindow: PortfolioWindowWidget(theme: theme, size: size)
            case .socialWindow: SocialWindowWidget(theme: theme, size: size)
            // สำรับผ้าปิกนิก — ผังของมันเป็น *แผ่น* เหมือนกัน
            case .portfolioGingham: PortfolioGinghamWidget(theme: theme, size: size)
            case .socialGingham: SocialGinghamWidget(theme: theme, size: size)
            // สำรับสมุดสแครปบุ๊ก — ผังของมันเป็น *แผ่น* เหมือนกัน
            case .scrapFolder: ScrapFolderWidget(theme: theme, size: size)
            case .scrapBadge: ScrapBadgeWidget(theme: theme, size: size)
            case .scrapKeyTab: ScrapKeyTabWidget(theme: theme, size: size)
            case .scrapFeed: ScrapFeedWidget(theme: theme, size: size)
            case .scrapTags: ScrapTagsWidget(theme: theme, size: size)
            case .scrapAbout: ScrapAboutWidget(theme: theme, size: size)
            case .scrapInfo: ScrapInfoWidget(theme: theme, size: size)
            case .scrapReceipt: ScrapReceiptWidget(theme: theme, size: size)
            case .scrapStats: ScrapStatsWidget(theme: theme, size: size)
            case .scrapStamp: ScrapStampWidget(theme: theme, size: size)
            case .scrapPhones: ScrapPhonesWidget(theme: theme, size: size)
            case .scrapChat: ScrapChatWidget(theme: theme, size: size)
            case .scrapNote: ScrapNoteWidget(theme: theme, size: size)
            case .scrapLabel: ScrapLabelWidget(theme: theme, size: size)
            case .heroMinimal: HeroMinimal(theme: theme, size: size)
            case .aboutText: AboutText(theme: theme)
            case .interestTags: InterestTags(theme: theme)
            case .proofBrandGrid: ProofBrandGrid(theme: theme)
            case .proofBrandRail: ProofBrandRail(theme: theme)
            case .proofBrandCoins: ProofBrandCoins(theme: theme)
            case .proofWork: ProofWork(theme: theme)
            case .proofTicket: ProofTicket(theme: theme)
            case .statGiant: StatGiant(theme: theme, size: size)
            case .socialChips: SocialChips(theme: theme, width: size.width)
            case .socialTiles: SocialTiles(theme: theme, width: size.width)
            // โปสเตอร์ผู้ติดตาม — ผังของมันเป็น *แผ่น* จึงรับขนาดเต็มไปคำนวณเองทั้งใบ
            case .statPoster: StatPosterWidget(theme: theme, size: size)
            case .artFilmstrip: ArtFilmstrip(theme: theme)
            case .artDuo: ArtDuo(theme: theme)
            case .artPair: ArtPair(theme: theme)
            case .workFeatured: WorkFeatured(theme: theme)
            case .workReel: WorkReel(theme: theme)
            // สำรับกองรูป
            case .galleryStack: GalleryStack(theme: theme)
            case .galleryCarousel: GalleryCarousel(theme: theme)
            case .galleryMasonry: GalleryMasonry(theme: theme)
            case .galleryMosaic: GalleryMosaic(theme: theme)
            case .galleryPost: GalleryPost(theme: theme)
            case .galleryStory: GalleryStory(theme: theme)
            case .galleryFilm: GalleryFilm(theme: theme)
            case .galleryTape: GalleryTape(theme: theme)
            // แผ่นโชว์คลิป — ผังของมันเป็น *แผ่น* จึงรับขนาดเต็มไปคำนวณเองทั้งใบ
            case .reelShowcase: ReelShowcase(theme: theme, size: size)
            case .typeMarquee: TypeMarquee(theme: theme)
            case .textBlock: TextBlock(theme: theme, size: size)
            case .nicheTags: NicheTags(theme: theme)
            // โปสเตอร์สายงาน — ผังของมันเป็น *แผ่น* จึงรับขนาดเต็มไปคำนวณเองทั้งใบ
            case .nichePoster: NichePosterWidget(theme: theme, size: size)
            case .statWrapped: StatWrapped(theme: theme, size: size)
            case .artPhotobooth: ArtPhotobooth(theme: theme)
            case .stickerTags: StickerTags(theme: theme)
            // สำรับรอบสอง — เรตราคาและช่องทางติดต่อ
            case .rateTags: RateTagsWidget(theme: theme)
            // สำรับเรตแบบศิลป์
            case .rateNeon: RateNeonWidget(theme: theme)
            case .contactCard: ContactCardWidget(theme: theme)
            case .contactQR: ContactQRWidget(theme: theme)
            case .contactBar: ContactBarWidget(theme: theme)
            case .contactStack: ContactStackWidget(theme: theme)
            case .contactLine: ContactLineWidget(theme: theme, size: size)
            case .contactChips: ContactChipsWidget(theme: theme)
            // โปสเตอร์ติดต่อ — ผังของมันเป็น *แผ่น* จึงรับขนาดเต็มไปคำนวณเองทั้งใบ
            case .contactPoster: ContactPosterWidget(theme: theme, size: size)
            case .proofSeal: VerifiedSealWidget(theme: theme, size: size)
            // ประชากรผู้ติดตาม
            case .audienceLine: AudienceLineWidget(theme: theme, size: size)
            case .audienceSplit: AudienceSplitWidget(theme: theme)
            case .audienceAge: AudienceAgeWidget(theme: theme)
            case .audiencePoster: InsightPosterWidget(theme: theme, size: size)
            case .audienceMap: AudienceMapWidget(theme: theme)
            // สำรับแผ่นสติกเกอร์
            // วัสดุไม่ได้อยู่ในตัววิว — ส่งลงไปทาง environment (ดู `popSkin` ท้ายฟังก์ชันนี้)
            case .popHeroPaper, .popHeroGlass: PopHero(theme: theme, size: size)
            case .popVideoPaper, .popVideoGlass: PopVideo(theme: theme)
            case .popStatsGlass: PopStats(theme: theme)
            case .popWorkPaper, .popWorkGlass: PopWork(theme: theme)
            case .popRatePaper, .popRateGlass: PopRate(theme: theme)
            case .popNichePaper, .popNicheGlass: PopNiche(theme: theme)
            case .popContactPaper, .popContactGlass: PopContact(theme: theme)
            // สำรับบรรณาธิการ
            case .wallPolaroid: WallPolaroid(theme: theme, size: size)
            case .wallMemory: WallMemory(theme: theme, size: size)
            case .zineCover: ZineCover(theme: theme, size: size)
            case .aboutEditorial: AboutEditorial(theme: theme, size: size)
            case .aboutBehind: AboutBehind(theme: theme, size: size)
            case .flowCards: FlowCards(theme: theme, size: size)
            }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // ส่งสีธีมลงไปให้ชิ้นส่วนย่อยใช้ได้โดยไม่ต้องรับ theme เป็นพารามิเตอร์ทุกชั้น
        //
        // สีเน้นคิดจากพื้นที่ชิ้นนี้นั่งอยู่ ไม่ใช่จากหมึกของการ์ด — บนแผ่นเข้มทึบที่วางบนการ์ดกระดาษ
        // สีเน้นแบบ "ย้อมให้เข้มพอสำหรับพื้นขาว" จะจมหายไปกับแผ่น ต้องใช้ตัวดิบที่จูนมาสำหรับพื้นมืด
        .environment(\.cardAccent, ink.isLight ? theme.rawAccent.onLightSurface() : theme.rawAccent)
        // วัสดุของแผ่นสติกเกอร์ — ชิ้นส่วนร่วม (ป้ายหัวข้อ · แผ่น · เทป) อยู่ลึกหลายชั้น
        // ส่งเป็นพารามิเตอร์แปลว่าต้องไล่ทุกตัวเรียก ส่งทาง environment แล้วทั้งกิ่งได้พร้อมกัน
        .environment(\.popSkin, kind.popSkin)
        // สำรับสแครปบุ๊ก — สีของแผ่นมาจากธีมของการ์ด (เฉด + มืด/สว่าง) คิดครั้งเดียวต่อชิ้น
        .environment(\.scrapTone, kind.isScrap ? ScrapTone(theme) : .fallback)
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
            Text(value).dataValue()
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
            ForEach(Profile.me.creator.socials.prefix(limit)) { s in
                HStack(spacing: 5) {
                    BrandIcon(name: s.type.icon, size: 9.5 * 1.15)
                    Text(Fmt.compact(s.followerCount)).dataValue().font(.sh(11, .bold))
                }
                .foregroundStyle(ink.text(0.9))
                .padding(.horizontal, 8).padding(.vertical, 4.5)
                .background(Capsule().fill(ink.fill(0.14)))
                .overlay(Capsule().strokeBorder(ink.line(0.16), lineWidth: 0.5))
                .lineLimit(1)
                .linkSlot(s.profileURL)
            }
            Spacer(minLength: 0)
        }
    }
}


// MARK: - ช่องที่รอข้อมูล

/// แทนที่ widget ทั้งชิ้นเมื่อข้อมูลของตระกูลนั้นยังไม่มี — กรอบประ ไอคอนตระกูล และบอกว่ารออะไร
/// (ไม่วาดเลข 0 หรือแบรนด์ตัวอย่าง: การ์ดที่โชว์ของปลอมคือการ์ดโกหก)
struct SystemPending: View {
    let text: String
    let family: WidgetFamily
    @Environment(\.cardInk) private var ink

    var body: some View {
        VStack(spacing: 8) {
            PIcon(.hourglass, size: 16)
                .foregroundStyle(ink.text(0.35))
            Text(text)
                .font(.sh(10.5, .semibold))
                .foregroundStyle(ink.text(0.45))
                .multilineTextAlignment(.center)
                .lineLimit(3).minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ink.text(0.18), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
    }
}


/// ตู้ widget: วาดด้วยข้อมูลตัวอย่างแม้ยังไม่กรอก — ให้เห็นว่ามีข้อมูลแล้วใบจะหน้าตายังไง
private struct SampleDataKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var sampleData: Bool {
        get { self[SampleDataKey.self] }
        set { self[SampleDataKey.self] = newValue }
    }
}
