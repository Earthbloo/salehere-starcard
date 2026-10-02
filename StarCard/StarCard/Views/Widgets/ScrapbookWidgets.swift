import SwiftUI

// MARK: - สำรับสมุดสแครปบุ๊ก — 14 ใบ
//
// ผังทุกใบวัดจาก canvas (ภาพ 2× ของหน้า 402) แล้วหารสอง — หน่วยในไฟล์นี้จึงเป็นหน่วยออกแบบของแผ่น
// แต่ละใบวาดผังของตัวเองที่ขนาดตายตัวแล้วให้ `PosterSheet` สเกลตามกรอบ (เหมือนสำรับโปสเตอร์)
// ของที่ต้องเกาะขอบขวา/ล่างอ่านจาก `box` ไม่ใช่เลขตายตัว — ยืดกรอบแล้วของไม่หลุดไปอยู่กลางแผ่น
//
// ชิ้นส่วนร่วมอยู่ใน `ScrapbookKit.swift`

/// ขนาดผังของแต่ละใบ (หน่วยออกแบบ)
enum ScrapSize {
    static let folder = CGSize(width: 370, height: 310)
    static let badge = CGSize(width: 180, height: 310)
    static let keyTab = CGSize(width: 110, height: 310)
    static let feed = CGSize(width: 370, height: 260)
    static let tags = CGSize(width: 370, height: 220)
    static let about = CGSize(width: 370, height: 230)
    static let info = CGSize(width: 180, height: 240)
    static let receipt = CGSize(width: 370, height: 290)
    static let stats = CGSize(width: 370, height: 280)
    static let stamp = CGSize(width: 180, height: 150)
    static let phones = CGSize(width: 370, height: 270)
    static let chat = CGSize(width: 370, height: 270)
    static let note = CGSize(width: 370, height: 170)
    static let label = CGSize(width: 370, height: 100)
}

private extension View {
    /// วางมุมบนซ้ายที่ (x, y) ด้วย padding — ไม่ใช่ offset: กรอบของช่องรูป (`photoSlot`)
    /// ต้องอยู่ตรงที่รูปถูกวาดจริง (บทเรียนเดียวกับสำรับปิกนิก)
    func at(_ x: CGFloat, _ y: CGFloat) -> some View {
        padding(.leading, x).padding(.top, y)
    }
}

/// ชื่อแยกสองเสียง — คำแรกดำหนัก ที่เหลือเป็นตัวเขียนชมพู ("rachel **leighton**")
private enum ScrapName {
    static func split(_ name: String) -> (String, String) {
        let parts = name.split(separator: " ", maxSplits: 1).map(String.init)
        return (parts.first ?? name, parts.count > 1 ? parts[1] : "")
    }
}

// MARK: - 01 แฟ้มสแครปบุ๊ก (โปรไฟล์)

struct ScrapFolderWidget: View {
    @Environment(\.scrapTone) private var tone
    @Environment(PhotoStore.self) private var photos
    @Environment(\.widgetID) private var wid
    @Environment(\.widgetLiftsPhoto) private var liftsPhoto
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.folder, frame: size) { box in sheet(box) }
    }

    private func sheet(_ box: CGSize) -> some View {
        let skin = ScrapSkin(surface, ink: ink, tone: tone)
        let plane = cutoutPlane(photos, slot: 1, widget: wid, lift: liftsPhoto)
        let (first, rest) = ScrapName.split(Profile.me.name)
        let folderW = min(box.width - 60, 300)
        return ScrapSheet(skin: skin, box: box) {
            // แฟ้ม — หลัง + หูแฟ้ม · หน้าแฟ้มอยู่ *ใต้* โพลารอยด์ คำใต้รูปจึงไม่ถูกบัง
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Scrap.butter)
                .frame(width: 110, height: 24).at(20, 29)
            RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Scrap.butter)
                .frame(width: folderW, height: 240).at(20, 46)
                .shadow(color: tone.shade.opacity(0.18), radius: 8, y: 6)
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Scrap.butterLight)
                .frame(width: folderW, height: 161).at(20, 125)
                .shadow(color: Color(scrapHex: 0xA06E14).opacity(0.14), radius: 5, y: -3)

            ScrapPolaroid(slot: 2, width: 93, height: 118, caption: (1, "ถ่ายเอง"))
                .rotationEffect(.degrees(-7)).at(35, 12)
            ScrapPolaroid(slot: 3, width: 95, height: 122, caption: (2, "ตัดเอง"))
                .rotationEffect(.degrees(5)).at(119, 6)
            WashiTape(width: 55, height: 15).rotationEffect(.degrees(-16)).at(44, 7)
            BinderClip(width: 34).rotationEffect(.degrees(5)).at(150, -4)

            // คน — ยืนทับขอบขวาของแฟ้ม · รูปทึบ (ยังไม่ลบพื้น) ตกไปเป็นภาพพิมพ์ในกรอบ
            switch plane {
            case let .subject(img, _):
                CutoutSubject(image: img, height: 280, d: 0, drift: 0, shadow: false)
                    .photoSlot(1)
                    .shadow(color: tone.shade.opacity(0.25), radius: 8, y: 6)
                    .frame(width: box.width + 12, height: box.height + 4, alignment: .bottomTrailing)
            case .framed:
                ScrapPolaroid(slot: 1, width: 120, height: 150)
                    .rotationEffect(.degrees(4))
                    .at(box.width - 140, 130)
            }

            // คนในกรอบกินขวามือกว้างกว่าคนคัตเอาต์ — ชื่อหดให้ไม่ไปทับรูป
            let nameW: CGFloat = plane.subject == nil ? 185 : 230
            Text(first)
                .lineLimit(1).minimumScaleFactor(0.4)
                .editableText(.name, Scrap.heavy(72))
                .frame(maxWidth: nameW, alignment: .leading)
                .at(38, 128)
            if !rest.isEmpty {
                Text(rest)
                    .font(CardFont.mitr.font(48, .regular))
                    .foregroundStyle(tone.paperAccent)
                    .lineLimit(1).minimumScaleFactor(0.4)
                    .scrapOutline(1.6)
                    .frame(maxWidth: nameW, alignment: .leading)
                    .rotationEffect(.degrees(-5))
                    .at(72, 194)
            }
            Text(Profile.me.handle.isEmpty ? "" : "@" + Profile.me.handle)
                .font(.sh(10, .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(Scrap.ink))
                .rotationEffect(.degrees(-2))
                .opacity(Profile.me.handle.isEmpty ? 0 : 1)
                .at(41, 270)

            ScrapHeart().fill(tone.accent).frame(width: 22, height: 22).at(box.width - 50, 14)
            ScrapSpark(size: 17).at(234, 35)
            ScrapSpark(size: 13).at(7, 150)
            ScrapSpark(size: 11, color: tone.accent).at(box.width - 25, 125)

            CutoutStatus(plane: plane, theme: theme,
                         lifting: cutoutLifting(photos, slot: 1, widget: wid, lift: liftsPhoto))
                .padding(10)
                .frame(width: box.width, height: box.height, alignment: .topTrailing)
        }
    }
}

// MARK: - 02 บัตรครีเอเตอร์ (โปรไฟล์)

struct ScrapBadgeWidget: View {
    @Environment(\.scrapTone) private var tone
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.badge, frame: size) { box in badge(box) }
    }

    private func badge(_ box: CGSize) -> some View {
        let cx = box.width / 2
        let c = Profile.me.creator
        let sub = [Profile.me.handle.isEmpty ? nil : "@" + Profile.me.handle, c.categories.first]
            .compactMap { $0 }.joined(separator: " · ")
        return ZStack(alignment: .topLeading) {
            // สายคล้อง + ห่วงเงิน
            Rectangle().fill(tone.mid)
                .frame(width: 22, height: 50)
                .overlay {
                    HStack {
                        Rectangle().stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 2])).frame(width: 0.5)
                        Spacer()
                        Rectangle().stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 2])).frame(width: 0.5)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 3)
                }
                .at(cx - 11, 0)
            Canvas { ctx, s in
                let silver = GraphicsContext.Shading.color(Color(scrapHex: 0xBFC3CB))
                ctx.stroke(Path(ellipseIn: CGRect(x: 10, y: 1, width: 10, height: 10)), with: silver, lineWidth: 2.6)
                var hook = Path()
                hook.move(to: CGPoint(x: 15, y: 13))
                hook.addCurve(to: CGPoint(x: 11, y: 34), control1: CGPoint(x: 6, y: 16), control2: CGPoint(x: 5, y: 30))
                hook.addCurve(to: CGPoint(x: 21, y: 22), control1: CGPoint(x: 18, y: 38), control2: CGPoint(x: 24, y: 30))
                ctx.stroke(hook, with: silver, style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
            }
            .frame(width: 30, height: 40)
            .at(cx - 15, 42)

            card(width: box.width - 20, sub: sub)
                .at(10, 70)
            ScrapSpark(size: 20).at(box.width - 30, 58)
        }
        .frame(width: box.width, height: box.height, alignment: .topLeading)
    }

    private func card(width: CGFloat, sub: String) -> some View {
        VStack(spacing: 5) {
            ZStack(alignment: .topLeading) {
                Text("STAR")
                    .font(.sh(25, .black))
                    .kerning(-0.5)
                    .foregroundStyle(Scrap.ink)
                Text("ครีเอเตอร์")
                    .font(CardFont.mitr.font(20, .regular))
                    .foregroundStyle(tone.paperAccent)
                    .rotationEffect(.degrees(-4))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 15)
            }
            .frame(height: 38)

            Color.clear
                .overlay { WidgetPhoto(index: 1).aspectRatio(contentMode: .fill) }
                .clipped()
                .photoSlot(1)
                .frame(width: 80, height: 80)
                .padding(4)
                .background(tone.band)

            Text(Profile.me.name)
                .lineLimit(1).minimumScaleFactor(0.5)
                .editableText(.name, .init(size: 14, weight: .heavy, color: Scrap.ink))
            Text(sub)
                .font(.sh(8, .medium))
                .foregroundStyle(Scrap.soft)
                .lineLimit(1).minimumScaleFactor(0.6)
                .padding(.top, -3)

            HStack(spacing: 7) {
                QRCode(text: "https://salehere.co.th/star/\(Profile.me.handle)")
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 1) {
                    Text("สแกนดูการ์ด")
                        .font(CardFont.mitr.font(10, .regular))
                        .foregroundStyle(Scrap.ink)
                    Text("STAR · SALE HERE")
                        .font(.sh(5.5, .semibold))
                        .kerning(1)
                        .foregroundStyle(Scrap.soft)
                }
            }
            .padding(.top, 2)
        }
        .padding(.top, 16).padding(.horizontal, 12).padding(.bottom, 10)
        .frame(width: width, height: 235, alignment: .top)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Scrap.cream))
        .overlay(alignment: .top) {
            Capsule().fill(tone.blush)
                .frame(width: 35, height: 6)
                .padding(.top, 8)
        }
        .shadow(color: tone.shade.opacity(0.22), radius: 9, y: 8)
    }
}

// MARK: - 03 พวงกุญแจโซเชียล (ช่องทาง)

struct ScrapKeyTabWidget: View {
    @Environment(\.scrapTone) private var tone
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.keyTab, frame: size) { box in tab(box) }
    }

    private func tab(_ box: CGSize) -> some View {
        let socials = Array(Profile.me.shownSocials.sorted { $0.followerCount > $1.followerCount }.prefix(3))
        let cx = box.width / 2
        return ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in
                let silver = GraphicsContext.Shading.color(Color(scrapHex: 0xC3C7CF))
                ctx.stroke(Path(ellipseIn: CGRect(x: 8, y: 3, width: 24, height: 24)), with: silver, lineWidth: 3)
                ctx.stroke(Path(roundedRect: CGRect(x: 17, y: 26, width: 6, height: 15), cornerRadius: 3),
                           with: .color(Color(scrapHex: 0xAEB3BC)), lineWidth: 2.5)
            }
            .frame(width: 40, height: 42)
            .at(cx - 20, 0)

            VStack(spacing: 5) {
                ForEach(socials) { s in
                    VStack(spacing: 3) {
                        let g = s.type.glyph(night: false)
                        Image(g.name)
                            .renderingMode(.original)
                            .resizable().scaledToFit()
                            .frame(width: g.badge ? 26 : 24, height: g.badge ? 26 : 27)
                            .frame(width: 42, height: 42)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
                            .shadow(color: tone.shade.opacity(0.18), radius: 0, y: 2)
                        Text(Fmt.compact(s.followerCount))
                            .font(.sh(15, .heavy))
                            .foregroundStyle(Scrap.ink)
                            .dataValue()
                    }
                }
                Text("ผู้ติดตาม")
                    .font(CardFont.mitr.font(9, .regular))
                    .foregroundStyle(.white)
            }
            .padding(.top, 27).padding(.bottom, 10)
            .frame(width: 75, height: 265, alignment: .top)
            .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(tone.mid))
            .overlay(alignment: .top) {
                Circle().fill(tone.mid.mix(with: .black, by: 0.14))
                    .frame(width: 13, height: 13)
                    .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                    .padding(.top, 8)
            }
            .shadow(color: tone.shade.opacity(0.24), radius: 8, y: 8)
            .at(cx - 37.5, 39)
        }
        .frame(width: box.width, height: box.height, alignment: .topLeading)
    }
}

// MARK: - 04 ฟีดของฉัน (ช่องทาง)

struct ScrapFeedWidget: View {
    @Environment(\.scrapTone) private var tone
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.feed, frame: size) { box in sheet(box) }
    }

    private func sheet(_ box: CGSize) -> some View {
        let c = Profile.me.creator
        return ScrapSheet(skin: ScrapSkin(surface, ink: ink, tone: tone), box: box) {
            window(width: box.width - 36, creator: c).at(18, 18)

            Text("ฟีด")
                .font(.sh(46, .black))
                .foregroundStyle(Scrap.ink)
                .scrapOutline(1.5)
                .at(11, box.height - 72)
            Text("ของฉัน")
                .font(CardFont.mitr.font(34, .regular))
                .foregroundStyle(tone.paperAccent)
                .scrapOutline(1.5)
                .rotationEffect(.degrees(-6))
                .at(72, box.height - 58)

            ScrapSpark(size: 13).at(box.width - 20, 6)
        }
    }

    private func window(width: CGFloat, creator c: CreatorProfile) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ScrapWindowDots()
                Text("salehere.co.th/star/\(Profile.me.handle)")
                    .font(.sh(6.5, .medium))
                    .foregroundStyle(Color(scrapHex: 0x8A6674))
                    .lineLimit(1)
                    .padding(.horizontal, 9).padding(.vertical, 2)
                    .background(Capsule().fill(.white))
                    .padding(.leading, 30)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(tone.blush)

            HStack(alignment: .center, spacing: 8) {
                Color.clear
                    .overlay { WidgetPhoto(index: 1).aspectRatio(contentMode: .fill) }
                    .frame(width: 37, height: 37)
                    .clipShape(Circle())
                    .photoSlot(1)
                    .padding(1.5)
                    .background(Circle().fill(.white))
                    .padding(1)
                    .background(Circle().fill(tone.paperAccent))
                VStack(alignment: .leading, spacing: 1) {
                    Text(Profile.me.handle)
                        .font(.sh(12, .heavy))
                        .foregroundStyle(Scrap.ink)
                    Text(Profile.me.tagline)
                        .font(.sh(7.5, .medium))
                        .foregroundStyle(Scrap.soft)
                }
                .lineLimit(1).minimumScaleFactor(0.6)
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 3) {
                    socials(Profile.me.shownSocials)
                    Text("ผู้ติดตาม")
                        .font(.sh(6, .semibold))
                        .foregroundStyle(Scrap.soft)
                }
            }
            .padding(.horizontal, 10).padding(.top, 9)

            HStack(spacing: 3) {
                ForEach(2...5, id: \.self) { i in
                    Color.clear
                        .overlay { WidgetPhoto(index: i).aspectRatio(contentMode: .fill) }
                        .clipped()
                        .photoSlot(i)
                }
            }
            .frame(height: 98)
            .padding(.horizontal, 10).padding(.top, 8)
            Spacer(minLength: 0)
        }
        .frame(width: width, height: 186)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .shadow(color: tone.shade.opacity(0.2), radius: 9, y: 8)
    }

    /// ทุกช่องที่ผูกไว้พร้อมยอด — เกิน 3 ช่องขึ้นแถวที่สอง (ไม่มีปุ่มให้เลือก)
    private func socials(_ list: [SocialProfile]) -> some View {
        let rows = stride(from: 0, to: list.count, by: 3).map { Array(list[$0..<min($0 + 3, list.count)]) }
        return VStack(alignment: .trailing, spacing: 4) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(rows[r]) { s in
                        HStack(spacing: 3) {
                            ScrapSocialIcon(type: s.type, size: 17)
                            Text(Fmt.compact(s.followerCount))
                                .font(.sh(11, .heavy))
                                .foregroundStyle(Scrap.ink)
                                .dataValue()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 05 ป้ายห้อยสายงาน (สายที่ใช่)

struct ScrapTagsWidget: View {
    @Environment(\.scrapTone) private var tone
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let size: CGSize

    /// สีป้ายวนเอง — ไม่มีปุ่มให้เลือก (พื้น · ตัวหนังสือ · วงไอคอน · ไอคอน) · สองใบเป็นสีของโทน
    private var skins: [(Color, Color, Color, Color)] {
        [
            (Scrap.cream, Scrap.ink, tone.band, Scrap.ink),
            (Scrap.ink, .white, tone.paperAccent, .white),
            (Scrap.butterLight, Scrap.ink, .white, Scrap.ink),
            (tone.mid, Scrap.ink, .white, Scrap.ink),
        ]
    }
    private static let spots: [(CGFloat, CGFloat, Double)] = [
        (22, 64, -4), (199, 58, 3), (32, 132, 2.5), (207, 136, -3),
    ]

    var body: some View {
        PosterSheet(design: ScrapSize.tags, frame: size) { box in sheet(box) }
    }

    private func sheet(_ box: CGSize) -> some View {
        let cats = Array(Profile.me.categories.prefix(4))
        let spread = (box.width - ScrapSize.tags.width) / 2
        return ScrapSheet(skin: ScrapSkin(surface, ink: ink, tone: tone), box: box) {
            ScrapLabel(first: "สายที่", second: "ใช่", size: 22).at(15, 13)
            ForEach(Array(cats.enumerated()), id: \.offset) { i, cat in
                let spot = Self.spots[i]
                tag(cat, index: i, skin: skins[i % skins.count])
                    .rotationEffect(.degrees(spot.2))
                    .at(spot.0 + (i.isMultiple(of: 2) ? 0 : spread), spot.1)
            }
            ScrapHeart().fill(tone.accent).frame(width: 20, height: 20).at(box.width - 40, 15)
            ScrapSpark(size: 13).at(200, 20)
            ScrapSpark(size: 15).at(box.width - 30, box.height - 28)
            ScrapBow(width: 28).at(box.width / 2 - 20, box.height - 30)
        }
    }

    private func tag(_ name: String, index: Int, skin: (Color, Color, Color, Color)) -> some View {
        HStack(spacing: 8) {
            Image(systemName: Pop.nicheIcon(name))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(skin.3)
                .frame(width: 30, height: 30)
                .background(Circle().fill(skin.2))
            Text(name)
                .lineLimit(1).minimumScaleFactor(0.5)
                .editableText(.categories, index: index, .init(size: 17, weight: .heavy, color: skin.1))
            Spacer(minLength: 0)
        }
        .padding(.leading, 26).padding(.trailing, 10)
        .frame(width: 150, height: 52)
        .background(TagShape(cut: 16).fill(skin.0))
        .overlay(alignment: .leading) {
            Circle().fill(tone.paper)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(skin.0.mix(with: .black, by: 0.12), lineWidth: 2))
                .padding(.leading, 9)
        }
        .shadow(color: tone.shade.opacity(0.2), radius: 6, y: 5)
    }
}

// MARK: - 06 รู้จักตัวฉัน (แนะนำตัว)

struct ScrapAboutWidget: View {
    @Environment(\.scrapTone) private var tone
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var ink
    @Environment(\.sampleData) private var sample
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.about, frame: size) { box in sheet(box) }
    }

    private func sheet(_ box: CGSize) -> some View {
        let skin = ScrapSkin(surface, ink: ink, tone: tone)
        let c = Profile.me.creator
        let chips = [c.location, c.workTime.days.isEmpty ? "" : "รับงาน " + c.workTime.daySummary]
            .filter { !$0.isEmpty }
        let right = box.width - 146
        return ScrapSheet(skin: skin, box: box) {
            ScrapLabel(first: "รู้จัก", second: "ตัวฉัน", size: 27, dark: true, stacked: true).at(18, 22)

            Text(sample ? Profile.me.shownAbout : Profile.me.about)
                .lineLimit(5)
                .editableText(.about, .init(size: 11.5, weight: .medium, color: skin.ink, lineSpacing: 4))
                .frame(width: min(200, right - 30), alignment: .leading)
                .at(20, 104)

            HStack(spacing: 5) {
                ForEach(chips, id: \.self) { t in
                    Text(t)
                        .font(.sh(8.5, .semibold))
                        .foregroundStyle(Scrap.ink)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(.white))
                }
            }
            .at(20, 188)

            Rectangle().fill(tone.mid)
                .frame(width: 105, height: 100)
                .rotationEffect(.degrees(-8))
                .at(right + 8, 25)
            ScrapPolaroid(slot: 1, width: 125, height: 160)
                .rotationEffect(.degrees(4))
                .at(right + 4, 29)
            Text(Profile.me.nickname)
                .lineLimit(1).minimumScaleFactor(0.5)
                .editableText(.nickname, Scrap.voice(37, color: tone.paperAccent))
                .scrapOutline(1.5)
                .rotationEffect(.degrees(-4))
                .frame(maxWidth: 120, alignment: .leading)
                .at(right + 30, 164)
            PaperClip()
                .stroke(Color(scrapHex: 0xAEB3BC), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 15, height: 41)
                .rotationEffect(.degrees(10))
                .at(right + 95, 15)

            ScrapSpark(size: 15).at(box.width - 25, box.height - 30)
            ScrapHeart().fill(tone.accent).frame(width: 18, height: 18).at(176, 30)
        }
    }
}

// MARK: - 07 บัตรข้อมูลของฉัน (แนะนำตัว)

struct ScrapInfoWidget: View {
    @Environment(\.scrapTone) private var tone
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.info, frame: size) { box in card(box) }
    }

    /// แถวที่โชว์ — **อายุไม่อยู่ในชุดตั้งต้น** (ข้อมูลส่วนตัว) · แถวที่ไม่มีค่าหายไปเอง
    private var rows: [(String, String)] {
        let c = Profile.me.creator
        return [
            ("ชื่อเล่น", Profile.me.nickname),
            ("อยู่", c.location),
            ("สาย", c.categories.prefix(2).joined(separator: " · ")),
            ("รับงาน", c.workTime.days.isEmpty ? "" : c.workTime.daySummary),
        ].filter { !$0.1.isEmpty }
    }

    private func card(_ box: CGSize) -> some View {
        let w = box.width - 20
        return ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                Scrap.cream
                Canvas { ctx, s in
                    var y: CGFloat = 54
                    while y < s.height {
                        ctx.fill(Path(CGRect(x: 0, y: y, width: s.width, height: 1)), with: .color(Scrap.rule))
                        y += 28.5
                    }
                    ctx.fill(Path(CGRect(x: 26, y: 0, width: 1, height: s.height)), with: .color(Scrap.margin))
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("ข้อมูล").font(.sh(18, .black)).foregroundStyle(Scrap.ink)
                    Text("ของฉัน").font(CardFont.mitr.font(18, .regular)).foregroundStyle(tone.paperAccent)
                }
                .at(35, 24)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(rows, id: \.0) { r in
                        HStack(spacing: 6) {
                            Text(r.0)
                                .font(.sh(7, .semibold))
                                .foregroundStyle(Scrap.label)
                                .frame(width: 36, alignment: .leading)
                            Text(r.1)
                                .font(CardFont.mitr.font(12, .regular))
                                .foregroundStyle(Scrap.ink)
                                .lineLimit(1).minimumScaleFactor(0.6)
                        }
                        .padding(.bottom, 3)
                        .frame(height: 28.5, alignment: .bottom)
                    }
                }
                .at(35, 54)
            }
            .frame(width: w, height: 212)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .rotationEffect(.degrees(-2))
            .shadow(color: tone.shade.opacity(0.2), radius: 8, y: 8)
            .at(10, 18)

            BinderClip(width: 34).at(box.width / 2 - 17, 0)
        }
        .frame(width: box.width, height: box.height, alignment: .topLeading)
    }
}

// MARK: - 08 ใบเสร็จเรท (เรทรับงาน)

struct ScrapReceiptWidget: View {
    @Environment(\.scrapTone) private var tone
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.receipt, frame: size) { box in sheet(box) }
    }

    /// ใบละช่อง — ช่องที่มีเรทมากสุดก่อน · ไม่เกินสองใบ (ใบที่สามไม่มีที่ให้อ่านออก)
    private var groups: [(SocialType, [RateItem])] {
        let rates = Profile.me.shownRates
        var order: [SocialType] = []
        for r in rates where !order.contains(r.platform) { order.append(r.platform) }
        return order.map { p in (p, rates.filter { $0.platform == p }) }
            .sorted { $0.1.count > $1.1.count }
            .prefix(2).map { $0 }
    }

    private func sheet(_ box: CGSize) -> some View {
        let skin = ScrapSkin(surface, ink: ink, tone: tone)
        let list = groups
        let w: CGFloat = 145
        let gap = list.count > 1 ? (box.width - 40 - w * 2) / 3 : 0
        return ScrapSheet(skin: skin, box: box) {
            ScrapLabel(first: "เรท", second: "รับงาน", size: 27).at(16, 14)
            Capsule().fill(Color(scrapHex: 0x3A2A31))
                .frame(width: box.width - 40, height: 13)
                .shadow(color: tone.shade.opacity(0.25), radius: 3, y: 3)
                .at(20, 75)
            ForEach(Array(list.enumerated()), id: \.offset) { i, g in
                receipt(g.0, items: g.1, width: w)
                    .rotationEffect(.degrees(i == 1 ? 1.5 : 0), anchor: .top)
                    .at(list.count > 1 ? 20 + gap + CGFloat(i) * (w + gap) : (box.width - w) / 2, 82)
            }
            Text("ราคาต่อชิ้น · บาท")
                .font(CardFont.mitr.font(11, .regular))
                .foregroundStyle(skin.papered ? tone.strong : skin.soft)
                .rotationEffect(.degrees(-3))
                .at(box.width - 135, box.height - 34)
            ScrapHeart().fill(tone.accent).frame(width: 22, height: 22).at(box.width - 45, box.height - 58)
            ScrapSpark(size: 17).at(box.width - 45, 30)
            ScrapSpark(size: 13).at(17, box.height - 30)
        }
    }

    private func receipt(_ p: SocialType, items: [RateItem], width: CGFloat) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    let g = p.glyph(night: false)
                    Image(g.name).renderingMode(.original).resizable().scaledToFit()
                        .frame(width: 15, height: 15)
                    Text(p.windowName)
                        .font(.sh(14, .heavy))
                        .foregroundStyle(Scrap.ink)
                }
                dashed
                ForEach(items.prefix(4)) { r in
                    HStack {
                        Text(r.label).font(.sh(9, .medium)).lineLimit(1).minimumScaleFactor(0.7)
                        Spacer(minLength: 4)
                        Text(Fmt.baht(r.price)).font(.sh(9, .bold)).monospacedDigit().dataValue()
                    }
                    .foregroundStyle(Scrap.ink)
                }
                dashed
                Text("ขอบคุณที่สนใจ")
                    .font(.sh(7, .semibold))
                    .kerning(1)
                    .foregroundStyle(Color(scrapHex: 0x8A6674))
                ScrapBarcode().frame(height: 18).padding(.horizontal, 10)
            }
            .padding(.top, 16).padding(.horizontal, 12).padding(.bottom, 9)
            .background(Scrap.cream)
            ZigzagEdge(tooth: 10).fill(Scrap.cream).frame(height: 7)
        }
        .frame(width: width)
        .shadow(color: tone.shade.opacity(0.12), radius: 5, y: 5)
    }

    private var dashed: some View {
        Rectangle()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            .foregroundStyle(Color(scrapHex: 0xD8C2CB))
            .frame(height: 0.5)
    }
}

// MARK: - 09 สถิติผู้ชม (ข้อมูลผู้ติดตาม)

struct ScrapStatsWidget: View {
    @Environment(\.scrapTone) private var tone
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var ink
    /// ยังไม่มีข้อมูลจริง = ตัวเลขเป็น "–" — แท่งต้องว่างด้วย ไม่งั้นแท่งเล่าตัวเลขที่ตัวหนังสือซ่อนไว้
    @Environment(\.ghostData) private var ghost
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.stats, frame: size) { box in sheet(box) }
    }

    private func pct(_ v: Double) -> String { "\(Int(v.rounded()))%" }

    private func sheet(_ box: CGSize) -> some View {
        let skin = ScrapSkin(surface, ink: ink, tone: tone)
        let c = Profile.me.creator
        let a = Profile.me.shownAudience
        let age = a.ages.max { $0.share < $1.share }
        let place = a.places.max { $0.share < $1.share }
        let female = a.female >= a.male
        // ป้ายใต้ค่าเป็นคำคงที่ — ข้อมูลยังไม่มีแล้วค่ากลายเป็น "–" แต่ป้ายต้องยังบอกว่าช่องนี้คืออะไร
        let rows: [(String, String, String)] = [
            ("person.2.fill", a.female + a.male > 0 ? pct(female ? a.female : a.male) : "–",
             female ? "ผู้ชมเป็นผู้หญิง" : "ผู้ชมเป็นผู้ชาย"),
            ("birthday.cake.fill", age?.label ?? "–", "อายุหลักของผู้ชม"),
            ("mappin.and.ellipse", place?.name ?? "–", "เมืองหลักของผู้ชม"),
        ]
        return ScrapSheet(skin: skin, box: box) {
            ScrapLabel(first: "สถิติ", second: "ผู้ชม", size: 27, dark: true).at(15, 15)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(rows, id: \.0) { r in
                    HStack(spacing: 9) {
                        Image(systemName: r.0)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(skin.ink)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(r.1)
                                .font(.sh(22, .heavy))
                                .foregroundStyle(tone.strong)
                                .lineLimit(1).minimumScaleFactor(0.5)
                                .dataValue()
                            Text(r.2)
                                .font(CardFont.mitr.font(10, .regular))
                                .foregroundStyle(skin.ink)
                        }
                    }
                    .frame(width: box.width - 175, alignment: .leading)
                }
            }
            .at(18, 70)

            HStack(spacing: 6) {
                ForEach(c.socials.filter { $0.engagementRate > 0 }.prefix(3)) { s in
                    VStack(spacing: 1) {
                        Text(Fmt.pct(s.engagementRate)).font(.sh(15, .heavy)).dataValue()
                        Text(s.type.windowName.uppercased() + " · ER")
                            .font(.sh(5.5, .bold)).kerning(0.5)
                            .lineLimit(1).minimumScaleFactor(0.6)
                    }
                    .foregroundStyle(Scrap.ink)
                    .frame(width: 64, height: 40)
                    .background(tone.mid)
                    .shadow(color: tone.shade.opacity(0.14), radius: 3, y: 3)
                }
            }
            .at(18, box.height - 54)

            phone(a)
                .rotationEffect(.degrees(4))
                .at(box.width - 133, 22)
            ScrapSpark(size: 17).at(box.width - 158, 16)
            ScrapHeart().fill(tone.accent).frame(width: 18, height: 18).at(box.width - 26, box.height - 26)
        }
    }

    /// จอมือถือ — อายุ · เพศ · เมือง ครบทั้งชุด (เมืองโชว์ 3 อันดับแรก)
    private func phone(_ a: AudienceInsight) -> some View {
        let places = Array(a.places.sorted { $0.share > $1.share }.prefix(3))
        return VStack(alignment: .leading, spacing: 4) {
            head("อายุ")
            bars(a.ages.map { ($0.label, $0.share) }, keepOrder: true)
            divider
            head("เพศ")
            GeometryReader { g in
                let total = max(a.female + a.male + a.other, 1)
                HStack(spacing: 0) {
                    if ghost {
                        tone.blush
                    } else {
                        tone.paperStrong.frame(width: g.size.width * a.female / total)
                        tone.band.frame(width: g.size.width * a.male / total)
                        Color(scrapHex: 0xE9E1E4)
                    }
                }
                .clipShape(Capsule())
            }
            .frame(height: 7)
            HStack {
                Text("หญิง \(pct(a.female))").dataValue()
                Spacer()
                Text("ชาย \(pct(a.male))").dataValue()
            }
            .font(.sh(6.5, .semibold))
            divider
            head("เมือง")
            bars(places.map { ($0.name, $0.share) }, keepOrder: false)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Scrap.ink)
        .padding(.top, 18).padding(.horizontal, 9).padding(.bottom, 8)
        .frame(width: 101, height: 223)
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color(scrapHex: 0xFFF8FA)))
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(scrapHex: 0x1B1B1D)))
        .shadow(color: tone.shade.opacity(0.3), radius: 10, y: 10)
    }

    private func head(_ t: String) -> some View {
        Text(t).font(.sh(9.5, .heavy))
    }

    private var divider: some View {
        Rectangle().stroke(style: StrokeStyle(lineWidth: 0.8, dash: [3, 2]))
            .foregroundStyle(tone.band).frame(height: 0.5)
            .padding(.vertical, 2)
    }

    /// แถวแท่งบรรทัดเดียว — ชื่อ · แท่ง · เปอร์เซ็นต์ · ค่าที่มากสุดเข้มสุด
    private func bars(_ list: [(String, Double)], keepOrder: Bool) -> some View {
        let top = list.map(\.1).max() ?? 1
        return VStack(spacing: 4) {
            ForEach(list, id: \.0) { item in
                HStack(spacing: 4) {
                    Text(item.0)
                        .font(.sh(6.5, item.1 == top ? .bold : .semibold))
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .frame(width: 30, alignment: .leading)
                    GeometryReader { g in
                        Capsule().fill(tone.blush)
                            .overlay(alignment: .leading) {
                                if !ghost {
                                    Capsule().fill(item.1 == top ? tone.paperStrong : tone.paperAccent)
                                        .frame(width: g.size.width * item.1 / max(top, 1))
                                }
                            }
                    }
                    .frame(height: 6)
                    Text(pct(item.1))
                        .font(.sh(6.5, .bold))
                        .frame(width: 18, alignment: .trailing)
                        .dataValue()
                }
            }
        }
    }
}

// MARK: - 10 ตรายางยืนยันตัวตน (ยืนยันตัวตน)

struct ScrapStampWidget: View {
    @Environment(\.scrapTone) private var tone
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.stamp, frame: size) { box in stamp(box) }
    }

    private func stamp(_ box: CGSize) -> some View {
        let facts = VerifiedFacts.current
        return ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in
                var s = Path()
                s.move(to: CGPoint(x: 29, y: 15)); s.addCurve(to: CGPoint(x: 2, y: 9),
                    control1: CGPoint(x: 20, y: 11), control2: CGPoint(x: 12, y: 17))
                s.move(to: CGPoint(x: 29, y: 15)); s.addCurve(to: CGPoint(x: 4, y: 24),
                    control1: CGPoint(x: 22, y: 20), control2: CGPoint(x: 11, y: 17))
                ctx.stroke(s, with: .color(tone.paperAccent), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
            .frame(width: 30, height: 30)
            .at(0, 35)

            VStack(alignment: .leading, spacing: 5) {
                Text(facts.verified ? "ยืนยันตัวตนแล้ว" : "รอยืนยันตัวตน")
                    .font(.sh(15, .black))
                    .foregroundStyle(Scrap.ink)
                Rectangle().stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    .foregroundStyle(tone.band).frame(height: 0.5)
                ForEach(facts.core, id: \.id) { r in
                    HStack(spacing: 4) {
                        Image(systemName: r.ok ? "checkmark" : "circle.dotted")
                            .font(.system(size: 8, weight: .heavy))
                        Text(r.title).font(.sh(8.5, .semibold))
                    }
                    .foregroundStyle(r.ok ? Scrap.ink : Scrap.soft)
                }
            }
            .padding(.leading, 28).padding(.top, 13).padding(.trailing, 10)
            .frame(width: 145, height: 110, alignment: .topLeading)
            .background(TagShape(cut: 17).fill(Scrap.cream))
            .overlay(alignment: .leading) {
                Circle().fill(tone.paper).frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color(scrapHex: 0xF1E4D6), lineWidth: 2))
                    .padding(.leading, 8)
            }
            .rotationEffect(.degrees(-3))
            .shadow(color: tone.shade.opacity(0.2), radius: 7, y: 7)
            .at(20, 15)

            if facts.verified {
                RubberStamp()
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-14))
                    .opacity(0.92)
                    .at(box.width - 64, box.height - 66)
            }
        }
        .frame(width: box.width, height: box.height, alignment: .topLeading)
    }
}

/// ตรายางหมึกดำสีเดียว — วงนอก · ตัวอักษรวิ่งรอบ · วงใน · เครื่องหมายถูก
/// (หมึกเดียว อ่านออกในแวบเดียว — ไม่ใช่ฟอยล์รุ้ง ไม่ใช่นูนเปล่า)
private struct RubberStamp: View {
    private static let ring = Array("VERIFIED · SALE HERE · VERIFIED · SALE HERE · ")

    var body: some View {
        GeometryReader { g in
            let r = g.size.width / 2
            ZStack {
                Circle().stroke(Scrap.ink, lineWidth: r * 0.06)
                Circle().stroke(Scrap.ink, lineWidth: r * 0.04).padding(r * 0.46)
                ForEach(Array(Self.ring.enumerated()), id: \.offset) { i, ch in
                    Text(String(ch))
                        .font(.sh(r * 0.2, .heavy))
                        .foregroundStyle(Scrap.ink)
                        .offset(y: -r * 0.73)
                        .rotationEffect(.degrees(Double(i) / Double(Self.ring.count) * 360))
                }
                Path { p in
                    p.move(to: CGPoint(x: r * 0.75, y: r * 1.02))
                    p.addLine(to: CGPoint(x: r * 0.93, y: r * 1.2))
                    p.addLine(to: CGPoint(x: r * 1.27, y: r * 0.82))
                }
                .stroke(Scrap.ink, style: StrokeStyle(lineWidth: r * 0.11, lineCap: .round, lineJoin: .round))
            }
            .frame(width: g.size.width, height: g.size.height)
        }
    }
}

// MARK: - 11 กำแพงมือถือ (ผลงาน)

struct ScrapPhonesWidget: View {
    @Environment(\.scrapTone) private var tone
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.phones, frame: size) { box in sheet(box) }
    }

    private func sheet(_ box: CGSize) -> some View {
        let w: CGFloat = 75, h: CGFloat = 145
        let gap = (box.width - 36 - w * 4) / 3
        let tilts: [Double] = [-3, 2, -2, 3]
        return ScrapSheet(skin: ScrapSkin(surface, ink: ink, tone: tone), box: box) {
            ScrapLabel(first: "ผลงาน", second: "ล่าสุด", size: 27)
                .frame(width: box.width - 17, alignment: .trailing)
                .at(0, 13)
            ForEach(0..<4, id: \.self) { i in
                phone(slot: i + 1, width: w, height: h)
                    .rotationEffect(.degrees(tilts[i]))
                    .at(18 + CGFloat(i) * (w + gap), i.isMultiple(of: 2) ? 75 : 98)
            }
            Text("ใหม่!")
                .font(CardFont.mitr.font(10, .regular))
                .foregroundStyle(.white)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(UnevenRoundedRectangle(topLeadingRadius: 9, bottomLeadingRadius: 2,
                                                   bottomTrailingRadius: 9, topTrailingRadius: 9)
                    .fill(Scrap.ink))
                .rotationEffect(.degrees(-6))
                .at(15, 48)
            ScrapSpark(size: 18).at(65, 20)
            ScrapSpark(size: 13, color: tone.accent).at(90, box.height - 30)
            ScrapHeart().fill(tone.accent).frame(width: 20, height: 20).at(box.width - 110, box.height - 34)
        }
    }

    private func phone(slot: Int, width: CGFloat, height: CGFloat) -> some View {
        Color.clear
            .overlay { WidgetPhoto(index: slot).aspectRatio(contentMode: .fill) }
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .photoSlot(slot)
            .overlay {
                Image(systemName: "play.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Scrap.ink)
                    .frame(width: 23, height: 23)
                    .background(Circle().fill(.white.opacity(0.9)))
            }
            .padding(3.5)
            .frame(width: width, height: height)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(scrapHex: 0x1B1B1D)))
            .shadow(color: tone.shade.opacity(0.28), radius: 7, y: 8)
    }
}

// MARK: - 12 แชทจากแบรนด์ (ผลงาน — รีวิวจากงานที่จบผ่าน Sale Here เท่านั้น)

struct ScrapChatWidget: View {
    @Environment(\.scrapTone) private var tone
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.chat, frame: size) { box in sheet(box) }
    }

    private func sheet(_ box: CGSize) -> some View {
        let reviews = Array(Profile.me.shownTrack(.verified).reviews.prefix(2))
        return ScrapSheet(skin: ScrapSkin(surface, ink: ink, tone: tone), box: box) {
            ScrapLabel(first: "เสียงจาก", second: "แบรนด์", size: 27).at(16, 13)
            VStack(spacing: 0) {
                HStack {
                    ScrapWindowDots()
                    Spacer()
                    Text("ข้อความ").font(.sh(7, .semibold)).foregroundStyle(Color(scrapHex: 0x8A6674))
                    Spacer()
                    Color.clear.frame(width: 26, height: 1)
                }
                .padding(.horizontal, 8)
                .frame(height: 21)
                .background(Color(scrapHex: 0xF7F4F5))
                VStack(alignment: .leading, spacing: 10) {
                    if reviews.isEmpty {
                        Text("ยังไม่มีรีวิวจากงานที่จบผ่าน Sale Here")
                            .font(.sh(9, .medium))
                            .foregroundStyle(Scrap.soft)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    ForEach(Array(reviews.enumerated()), id: \.offset) { i, r in
                        bubble(r, index: i)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 11)
                Spacer(minLength: 0)
            }
            .frame(width: box.width - 36, height: 185)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .shadow(color: tone.shade.opacity(0.2), radius: 9, y: 8)
            .at(18, 68)

            ScrapHeart().fill(tone.accent).frame(width: 21, height: 21).at(box.width - 50, 18)
            ScrapSpark(size: 14).at(box.width - 90, 45)
        }
    }

    private func bubble(_ r: ClientReview, index: Int) -> some View {
        HStack(alignment: .bottom, spacing: 6) {
            Text(String(r.brand.prefix(1)))
                .font(.sh(10, .heavy))
                .foregroundStyle(Scrap.ink)
                .frame(width: 23, height: 23)
                .background(Circle().fill(tone.band))
                .padding(.bottom, 12)
            VStack(alignment: .leading, spacing: 3) {
                Text(r.text)
                    .font(.sh(9.5, .medium))
                    .foregroundStyle(Scrap.ink)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .padding(.horizontal, 9).padding(.vertical, 7)
                    .background(UnevenRoundedRectangle(topLeadingRadius: 11, bottomLeadingRadius: 3,
                                                       bottomTrailingRadius: 11, topTrailingRadius: 11)
                        .fill(index.isMultiple(of: 2) ? Color(scrapHex: 0xEFEDEF) : tone.band.mix(with: .white, by: 0.45)))
                    .overlay(alignment: .topTrailing) {
                        if index == 0 {
                            ScrapHeart().fill(.white).frame(width: 8, height: 8)
                                .frame(width: 17, height: 17)
                                .background(Circle().fill(tone.paperAccent))
                                .overlay(Circle().stroke(.white, lineWidth: 1.5))
                                .offset(x: 5, y: -6)
                        }
                    }
                Text("\(r.brand) · งานผ่าน Sale Here")
                    .font(.sh(7, .semibold))
                    .foregroundStyle(Scrap.soft)
                    .padding(.leading, 3)
            }
            .frame(maxWidth: 240, alignment: .leading)
        }
    }
}

// MARK: - 13 กระดาษโน้ตติดต่อ (ติดต่อ)

struct ScrapNoteWidget: View {
    @Environment(\.scrapTone) private var tone
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.note, frame: size) { box in sheet(box) }
    }

    /// = ขั้นช่องทางติดต่อของ Star Profile — LINE · เบอร์ · เว็บไซต์ (2 ต.ค. 2569) · ช่องที่ว่างไม่ขึ้น
    private var rows: [(String, ProfileField, String)] {
        let me = Profile.me
        return [("LINE", .lineId, me.lineId), ("โทร", .phone, me.phone), ("เว็บ", .website, me.website)].filter { !$0.2.isEmpty }
    }

    private func sheet(_ box: CGSize) -> some View {
        ScrapSheet(skin: ScrapSkin(surface, ink: ink, tone: tone), box: box) {
            pad.rotationEffect(.degrees(-1.5)).at(17, 20)
            BinderClip(width: 34).at(108, 5)
            envelope.rotationEffect(.degrees(5)).at(box.width - 120, 47)
            ScrapSpark(size: 17).at(box.width - 35, 20)
            ScrapHeart().fill(tone.accent).frame(width: 18, height: 18).at(box.width - 110, box.height - 35)
        }
    }

    private var pad: some View {
        ZStack(alignment: .topLeading) {
            Scrap.cream
            Canvas { ctx, s in
                var y: CGFloat = 48
                while y < s.height {
                    ctx.fill(Path(CGRect(x: 0, y: y, width: s.width, height: 1)), with: .color(Scrap.rule))
                    y += 27
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                ScrapNoteHeading().frame(height: 31, alignment: .bottom).padding(.bottom, 4)
                ForEach(rows, id: \.0) { r in
                    HStack(spacing: 7) {
                        Text(r.0)
                            .font(.sh(7, .bold))
                            .foregroundStyle(Scrap.label)
                            .frame(width: 29, alignment: .leading)
                        Text(r.2)
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .editableText(r.1, Scrap.voice(12, color: Scrap.ink))
                    }
                    .frame(height: 27)
                }
            }
            .padding(.leading, 17).padding(.top, 12).padding(.trailing, 12)
        }
        .frame(width: 220, height: 135)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: tone.shade.opacity(0.2), radius: 7, y: 7)
    }

    private var envelope: some View {
        ZStack(alignment: .top) {
            Color(scrapHex: 0xFBF1E6)
            Path { p in
                p.move(to: .zero); p.addLine(to: CGPoint(x: 105, y: 0)); p.addLine(to: CGPoint(x: 52.5, y: 46))
                p.closeSubpath()
            }
            .fill(Color(scrapHex: 0xF5E4D4))
            ScrapHeart().fill(.white).frame(width: 13, height: 13)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tone.paperAccent))
                .shadow(color: tone.shade.opacity(0.3), radius: 2, y: 1.5)
                .padding(.top, 29)
        }
        .frame(width: 105, height: 75)
        .shadow(color: tone.shade.opacity(0.2), radius: 7, y: 7)
    }
}

/// หัวกระดาษโน้ต — สองเสียงเหมือนพาดหัวอื่น แต่ไม่มีแถบ (มันเขียนลงบนกระดาษตรง ๆ)
private struct ScrapNoteHeading: View {
    @Environment(\.widgetID) private var wid
    @Environment(\.scrapTone) private var tone

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(Profile.me.note(wid, 1, preset: "มาทำงาน"))
                .lineLimit(1).fixedSize()
                .editableText(.note, index: 1, widget: wid, preset: "มาทำงาน", hint: "คำแรก", Scrap.heavy(20))
            Text(Profile.me.note(wid, 2, preset: "ด้วยกันนะ"))
                .lineLimit(1).fixedSize()
                .editableText(.note, index: 2, widget: wid, preset: "ด้วยกันนะ", hint: "คำที่สอง", Scrap.voice(20, color: tone.paperAccent))
        }
    }
}

// MARK: - 14 หัวข้อกล่องคำ (ข้อความ)

struct ScrapLabelWidget: View {
    @Environment(\.scrapTone) private var tone
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        PosterSheet(design: ScrapSize.label, frame: size) { box in
            ZStack(alignment: .topLeading) {
                ScrapLabel(first: "แบรนด์ที่", second: "เคยร่วมงาน", size: 38)
                    .frame(width: box.width, height: box.height)
                ScrapSpark(size: 17, color: tone.accent).at(20, 15)
            }
            .frame(width: box.width, height: box.height, alignment: .topLeading)
        }
    }
}
