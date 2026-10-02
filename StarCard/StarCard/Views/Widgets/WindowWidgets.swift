import SwiftUI
import PhosphorSwift

// MARK: - สำรับหน้าต่าง
//
// แปลงตรงจากแผ่นตัวอย่างสองใบที่เจ้าของการ์ดส่งมา (28 ก.ย. 2569) — **ผัง สัดส่วน วัสดุ สี ตามต้นฉบับ
// · ตัวอักษรใช้ฟอนต์ของแอป** (กติกาเดียวกับทุกใบที่แปลงจากไฟล์ดีไซน์)
//
// ทั้งสองใบคือ **หน้าต่างแอป Preview ของ macOS** ที่เปิดอยู่บนการ์ด: แถบหัวเทา ไฟจราจรสามดวง
// ไอคอนเครื่องมือเส้นบาง และขอบสองชั้นของหน้าต่าง macOS รุ่นใหม่ — เนื้อหาข้างในคือ
// "ไฟล์" ที่ครีเอเตอร์กำลังเปิดโชว์แบรนด์ (สถิติช่อง · หน้าปกพอร์ต)
//
// # ทำไมหน้าต่างถึงเป็นวัสดุที่ใช้ได้บนการ์ด
//
// คนรุ่นนี้อ่านหน้าต่าง macOS ออกในแวบเดียวว่า "นี่คือไฟล์งาน" — มันบอกว่าตัวเลขกับรูปข้างใน
// เป็น *เอกสาร* ไม่ใช่ป้ายโฆษณา ซึ่งเป็นน้ำเสียงเดียวกับที่ครีเอเตอร์ใช้ตอนแคปหน้าจอส่งแบรนด์อยู่แล้ว
//
// # สองใบใช้กรอบชุดเดียวกันเป๊ะ
//
// หน้าต่างจริงบนจอเดียวกันมีแถบหัวสูงเท่ากันเสมอ ไม่ว่าหน้าต่างจะกว้างแค่ไหน — ถ้าสองใบนี้วางบน
// การ์ดใบเดียวแล้วแถบหัวสูงไม่เท่ากัน ตาจะอ่านเป็นภาพแคปสองรูปที่ย่อคนละขนาด ไม่ใช่สองหน้าต่าง
// ค่าของกรอบจึงอยู่ที่ `MW` ที่เดียว (หน่วยออกแบบ) และทั้งสองใบสเกลด้วย `PosterSheet` ตัวเดียวกัน

/// ค่าคงที่ของกรอบหน้าต่าง — **หน่วยออกแบบ** วัดจากแผ่นต้นฉบับทั้งสองใบแล้วเฉลี่ยให้เป็นชุดเดียว
enum MW {
    /// แถบหัว — ต้นฉบับทั้งสองใบได้ ~24 เมื่อย่อมาที่ความกว้างของ widget
    static let bar: CGFloat = 24
    static let radius: CGFloat = 15
    /// ไฟจราจร — เส้นผ่านศูนย์กลาง · ระยะศูนย์กลางถึงศูนย์กลาง · ศูนย์กลางดวงแรกจากขอบซ้าย
    static let dot: CGFloat = 9.2
    static let dotStep: CGFloat = 14.6
    static let dotLead: CGFloat = 17
    /// ไอคอนเครื่องมือ — ขนาด · ระยะห่าง · ระยะศูนย์กลางไอคอนสุดท้ายจากขอบขวา
    static let tool: CGFloat = 10.5
    static let toolStep: CGFloat = 21.5
    static let toolTrail: CGFloat = 14.5
}

/// หน้าต่างสว่าง (Aqua) หรือมืด (Dark Mode) — **เลือกรายชิ้นในถาด** ผ่านแถว "กล่อง"
///
/// ไม่ผูกกับธีมของการ์ด: หน้าต่าง macOS ไม่ได้เปลี่ยนสีตามวอลเปเปอร์ เจ้าของการ์ดเป็นคนเลือกเอง
/// (กติกา "หน้าตาของชิ้นเป็นของชิ้น" — ดู `WidgetKind.surfaceOptions`)
struct MacWindowSkin {
    var night: Bool
    var barTop: Color
    var barBottom: Color
    var barLine: Color
    var body: Color
    var bodyLow: Color
    var rimOuter: Color
    var rimInner: Color
    var rimGlint: Color
    var title: Color
    var tool: Color
    /// หมึกของเนื้อหา — หัวข้อ · ตัวเลข · บรรทัดรอง · เส้นคั่น
    var ink: Color
    var number: Color
    var soft: Color
    var faint: Color
    var hair: Color

    static func make(_ surface: WidgetSurface) -> MacWindowSkin {
        surface == .dim ? .night : .day
    }

    /// ค่าดูดจากแผ่นต้นฉบับ (แถบหัว #EFEFF0→#E6E6E7 · พื้น #F6F6F6→#F3F3F3 · ขอบ #A6A7AB)
    static let day = MacWindowSkin(
        night: false,
        barTop: Color(hex: 0xEFEFF0), barBottom: Color(hex: 0xE6E6E8), barLine: Color(hex: 0xD9D9DB),
        body: Color(hex: 0xF7F7F7), bodyLow: Color(hex: 0xF2F2F3),
        rimOuter: Color(hex: 0xA6A7AB), rimInner: Color(hex: 0xC6C7CA), rimGlint: .white.opacity(0.85),
        title: Color(hex: 0x5C5E62), tool: Color(hex: 0x5A5C60),
        ink: Color(hex: 0x14171B), number: Color(hex: 0x3C3F44),
        soft: Color(hex: 0x84878C), faint: Color(hex: 0x6C6F74), hair: Color(hex: 0xD6D6D9))

    static let night = MacWindowSkin(
        night: true,
        barTop: Color(hex: 0x3A3A3D), barBottom: Color(hex: 0x303033), barLine: Color(hex: 0x19191B),
        body: Color(hex: 0x252527), bodyLow: Color(hex: 0x1E1E20),
        rimOuter: Color(hex: 0x0B0B0C), rimInner: .white.opacity(0.10), rimGlint: .white.opacity(0.06),
        title: Color(hex: 0xB9BAC0), tool: Color(hex: 0xBEBFC4),
        ink: Color(hex: 0xF4F4F6), number: Color(hex: 0xE4E5E8),
        soft: Color(hex: 0x9A9CA2), faint: Color(hex: 0x8C8E94), hair: Color(hex: 0x3C3C40))
}

/// ไอคอนบนแถบหัว — SF Symbols ตรง ๆ เพราะนี่คือไอคอนของ macOS เอง (Phosphor จะอ่านเป็นแอปอื่น)
enum MacTool: Hashable {
    case info, zoomIn, zoomOut, share, pencil, pencilLine, duplicate, more, markup
    /// ปุ่มแถบข้าง + ลูกศรเล็ก (หน้าต่างรูปของ Preview)
    case sidebar
    /// เส้นคั่นกลุ่มปุ่ม
    case divider
    /// ปุ่มล้นแถบ "••"
    case overflow

    var symbol: String? {
        switch self {
        case .info: return "info.circle"
        case .zoomIn: return "plus.magnifyingglass"
        case .zoomOut: return "minus.magnifyingglass"
        case .share: return "square.and.arrow.up"
        // ดินสอโปร่งของต้นฉบับ — SF "pencil" ที่ขนาดนี้ทึบเป็นขีดเดียว ใช้ Phosphor เส้นบางแทน (ดู `toolView`)
        case .pencil: return nil
        case .pencilLine: return "pencil.line"
        case .duplicate: return "square.on.square"
        case .more: return "ellipsis.circle"
        case .markup: return "pencil.tip.crop.circle"
        case .sidebar, .divider, .overflow: return nil
        }
    }

    /// ชุดของหน้าต่างเอกสาร (แผ่น Social Channel)
    static let document: [MacTool] = [.info, .zoomIn, .zoomOut, .share, .pencil, .duplicate, .more]
    /// ชุดของหน้าต่างรูป (แผ่น Portfolio)
    static let image: [MacTool] = [.sidebar, .divider, .zoomOut, .zoomIn, .share, .pencilLine, .overflow, .markup]
}

/// กรอบหน้าต่าง — แถบหัว + เนื้อหา + ขอบสองชั้น
///
/// ขนาดทั้งหมดเป็นหน่วยออกแบบ ผู้เรียกวางมันใน `PosterSheet` ซึ่งสเกลทั้งก้อนให้เอง
/// แถบหัว **ไม่ยืดตามความสูง** — ยืดหน้าต่างให้สูงขึ้นแล้วได้พื้นที่เนื้อหาเพิ่ม เหมือนหน้าต่างจริง
struct MacWindow<Title: View, Content: View>: View {
    let skin: MacWindowSkin
    let tools: [MacTool]
    @ViewBuilder var title: () -> Title
    @ViewBuilder var content: () -> Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: MW.radius, style: .continuous)
        VStack(spacing: 0) {
            bar
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        .background(LinearGradient(colors: [skin.body, skin.bodyLow],
                                   startPoint: .top, endPoint: .bottom))
        .clipShape(shape)
        // ขอบสองชั้นของหน้าต่าง macOS รุ่นใหม่ — เส้นนอกเข้ม · แถบสว่างบาง · เส้นในจาง
        // เส้นเดียวอ่านเป็นกล่องที่วาดด้วยโปรแกรม ไม่ใช่หน้าต่างที่ลอยอยู่
        .overlay {
            ZStack {
                shape.strokeBorder(skin.rimOuter, lineWidth: 0.9)
                RoundedRectangle(cornerRadius: MW.radius - 0.9, style: .continuous)
                    .strokeBorder(skin.rimGlint, lineWidth: 1.1)
                    .padding(0.9)
                RoundedRectangle(cornerRadius: MW.radius - 2, style: .continuous)
                    .strokeBorder(skin.rimInner, lineWidth: 0.6)
                    .padding(2)
            }
            .allowsHitTesting(false)
        }
    }

    private var bar: some View {
        ZStack {
            LinearGradient(colors: [skin.barTop, skin.barBottom], startPoint: .top, endPoint: .bottom)

            // ชื่อหน้าต่างอยู่กลาง *ทั้งหน้าต่าง* ไม่ใช่กลางที่ว่างระหว่างไฟกับไอคอน (แบบ macOS)
            title()

            HStack(spacing: 0) {
                HStack(spacing: MW.dotStep - MW.dot) {
                    light(Color(hex: 0xFF5F57), Color(hex: 0xE0443E))
                    light(Color(hex: 0xFEBC2E), Color(hex: 0xDEA123))
                    light(Color(hex: 0x28C840), Color(hex: 0x1AAB29))
                }
                .padding(.leading, MW.dotLead - MW.dot / 2)
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    ForEach(Array(tools.enumerated()), id: \.offset) { _, t in
                        toolView(t)
                    }
                }
                .padding(.trailing, MW.toolTrail - MW.toolStep / 2)
            }
        }
        .frame(height: MW.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(skin.barLine).frame(height: 0.7)
        }
    }

    private func light(_ fill: Color, _ edge: Color) -> some View {
        Circle()
            .fill(fill)
            .overlay(Circle().strokeBorder(edge.opacity(skin.night ? 0.5 : 0.85), lineWidth: 0.45))
            .frame(width: MW.dot, height: MW.dot)
    }

    @ViewBuilder
    private func toolView(_ t: MacTool) -> some View {
        switch t {
        case .pencil:
            PIcon(.pencilSimple, size: MW.tool * 1.02, weight: .regular)
                .foregroundStyle(skin.tool)
                .frame(width: MW.toolStep)
        case .divider:
            Rectangle().fill(skin.tool.opacity(0.35))
                .frame(width: 0.7, height: MW.tool * 1.15)
                .frame(width: MW.toolStep * 0.55)
        case .overflow:
            HStack(spacing: MW.tool * 0.2) {
                Circle().frame(width: MW.tool * 0.28, height: MW.tool * 0.28)
                Circle().frame(width: MW.tool * 0.28, height: MW.tool * 0.28)
            }
            .foregroundStyle(skin.tool)
            .frame(width: MW.toolStep * 0.8)
        case .sidebar:
            HStack(spacing: MW.tool * 0.22) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: MW.tool, weight: .light))
                Image(systemName: "chevron.down")
                    .font(.system(size: MW.tool * 0.5, weight: .semibold))
            }
            .foregroundStyle(skin.tool)
            .frame(width: MW.toolStep * 1.25)
        default:
            Image(systemName: t.symbol ?? "circle")
                .font(.system(size: MW.tool, weight: .light))
                .foregroundStyle(skin.tool)
                .frame(width: MW.toolStep)
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - ช่องที่เลือกโชว์

extension SocialType {
    /// ชื่อบนหน้าต่าง — ชื่อเต็มของแพลตฟอร์ม ("Instagram" ไม่ใช่ "IG") ยกเว้น X ที่วงเล็บยาวเกินบรรทัด
    var windowName: String { self == .x ? "X" : name }

    /// โลโก้ **เปลือย** สำหรับวางบนพื้นเรียบ — ต้นฉบับวางโน้ต TikTok ตัวเปล่า ไม่มีวงกลมรอง
    ///
    /// มีเฉพาะช่องที่โลโก้จริงไม่ใช่วงกลม (TikTok · X · YouTube) · ที่เหลือ (IG · Facebook · Lemon8)
    /// ตราวงกลมของแอปคือหน้าตาที่คนจำได้อยู่แล้ว จึงใช้ตัวเดิม (`badge == true` ย่อลงนิดหน่อย
    /// เพราะวงกลมทึบหนักตากว่าโลโก้เส้นที่ขนาดเท่ากัน)
    func glyph(night: Bool) -> (name: String, badge: Bool) {
        switch self {
        case .tiktok:  return (night ? "glyph-tiktok-night" : "glyph-tiktok", false)
        case .x:       return (night ? "glyph-x-night" : "glyph-x", false)
        case .youtube: return ("glyph-youtube", false)
        default:       return (icon, true)
        }
    }
}

/// ช่องที่หน้าต่างสถิติโชว์ — **เลือกรายชิ้น** ในถาด (แถว "ช่องทาง")
///
/// เก็บเป็นช่องข้อความอิสระของชิ้น (`Profile.note` ช่องที่ `slot`) — ทางเดียวกับพาดหัวของดีไซน์
/// จึงได้การบันทึก · ซิงก์ · กู้คืน มาฟรีโดยไม่ต้องเพิ่มฟิลด์ในไฟล์การ์ด
/// ไม่เคยเลือก = **ช่องที่ยอดเยอะที่สุด** (สิ่งที่ครีเอเตอร์แทบทุกคนจะเลือกเองอยู่แล้ว)
enum WindowChannel {
    /// ช่องอิสระที่สงวนไว้ — ไม่ได้ประกาศเป็นช่องพิมพ์ จึงไม่โผล่บนแถบพิมพ์
    static let slot = 9
    private static let auto = "auto"

    @MainActor
    static func current(_ widget: UUID?) -> SocialProfile? {
        let socials = Profile.me.shownSocials
        let raw = Profile.me.note(widget, slot, preset: auto)
        if let t = SocialType(rawValue: raw), let s = socials.first(where: { $0.type == t }) { return s }
        return socials.max { $0.followerCount < $1.followerCount }
    }

    @MainActor
    static func pick(_ type: SocialType, for widget: UUID) {
        Profile.me.set(TextSlotID(field: .note, index: slot, widget: widget), type.rawValue)
    }
}

// MARK: - 01 หน้าต่างช่องทาง (SOCIAL CHANNEL)

/// ค่าคงที่ของผัง — วัดจากแผ่นต้นฉบับ 842 × 208 แล้วย่อเป็นกว้าง 504 (× 0.599)
enum SW {
    static let w: CGFloat = 504
    static let h: CGFloat = 124
    /// ส่วนแบ่งความกว้างของสามช่อง — ต้นฉบับไม่เท่ากัน (35 · 34.5 · ที่เหลือ) เพราะช่องแรกแบกโลโก้
    static let col1: CGFloat = 0.35
    static let col2: CGFloat = 0.345
    static let footer: CGFloat = 17
}

struct SocialWindowWidget: View {
    @Environment(\.widgetID) private var wid
    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    let theme: CardTheme
    let size: CGSize

    /// ข้อความของดีไซน์ — เก็บต่อชิ้น (วางสองหน้าต่างแล้วตั้งชื่อคนละชื่อได้)
    private static let titlePreset = "SOCIAL CHANNEL"
    private static let rolePreset = "ช่องทางรีวิว"

    var body: some View {
        PosterSheet(design: CGSize(width: SW.w, height: SW.h), frame: size) { box in
            let skin = MacWindowSkin.make(surface)
            MacWindow(skin: skin, tools: MacTool.document) {
                Text(Profile.me.note(wid, 1, preset: Self.titlePreset).uppercased())
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .editableText(.note, index: 1, widget: wid,
                                  preset: Self.titlePreset, hint: "ชื่อหน้าต่าง",
                                  .init(size: 7.8, weight: .semibold, color: skin.title,
                                        align: .center, tracking: 0.9, uppercase: true))
                    .frame(maxWidth: box.width * 0.36)
            } content: {
                content(skin, box: box)
            }
            .frame(width: box.width, height: box.height)
        }
    }

    @ViewBuilder
    private func content(_ skin: MacWindowSkin, box: CGSize) -> some View {
        if let s = WindowChannel.current(wid) {
            VStack(spacing: 0) {
                GeometryReader { g in
                    HStack(spacing: 0) {
                        channel(s, skin: skin)
                            .frame(width: box.width * SW.col1, alignment: .leading)
                        divider(skin, h: g.size.height)
                        followers(s, skin: skin, colW: box.width * SW.col2)
                            .frame(width: box.width * SW.col2)
                        divider(skin, h: g.size.height)
                        engagement(s, skin: skin, colW: box.width * (1 - SW.col1 - SW.col2))
                            .frame(maxWidth: .infinity)
                    }
                    .frame(width: g.size.width, height: g.size.height)
                }
                footer(s, skin: skin)
            }
            // เปลี่ยนช่องแล้วสร้างใหม่ทั้งแผ่น — ตัวเลขหลักไม่เท่ากันต้องไม่ไหลต่อจากของเดิม
            .id(s.id)
        } else {
            Text("ยังไม่มีช่องทาง")
                .font(.sh(11, .semibold))
                .foregroundStyle(skin.soft)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// เส้นคั่นช่อง — สั้นกว่าความสูงช่อง (ต้นฉบับ ~74%) ลอยกลาง ไม่ชนแถบหัวหรือเส้นฐาน
    private func divider(_ skin: MacWindowSkin, h: CGFloat) -> some View {
        Rectangle().fill(skin.hair)
            .frame(width: 0.8, height: h * 0.74)
            .scrubVeil(scrub.d, lead: 0.12, drop: 10, pull: 12)
    }

    // MARK: ช่อง 1 — โลโก้ · ชื่อแพลตฟอร์ม · แฮนเดิล · บทบาทของช่อง

    private func channel(_ s: SocialProfile, skin: MacWindowSkin) -> some View {
        let g = s.type.glyph(night: skin.night)
        return HStack(spacing: 11) {
            Image(g.name)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: g.badge ? 40 : 46, height: g.badge ? 40 : 51)
                .scrubLouver(scrub.d, lead: 0, angle: 70, shrink: 0.2)

            VStack(alignment: .leading, spacing: -3) {
                Text(s.type.windowName)
                    .font(.sh(19.5, .heavy))
                    .kerning(-0.3)
                    .foregroundStyle(skin.ink)
                    .scrubVeil(scrub.d, lead: 0.04, drop: 16, pull: 8)
                Text(s.handle)
                    .font(.sh(12.2, .bold))
                    .foregroundStyle(skin.number)
                    .dataValue()
                    .scrubVeil(scrub.d, lead: 0.08, drop: 14, pull: 8)
                Text(Profile.me.note(wid, 2, preset: Self.rolePreset))
                    .editableText(.note, index: 2, widget: wid,
                                  preset: Self.rolePreset, hint: "ช่องนี้ใช้ทำอะไร",
                                  .init(size: 10, weight: .regular, color: skin.soft))
                    .padding(.top, 2)
                    .scrubVeil(scrub.d, lead: 0.12, drop: 12, pull: 8)
            }
            .lineLimit(1).minimumScaleFactor(0.55)
        }
        .padding(.leading, 17)
        .padding(.trailing, 8)
        // โหมดดู: แตะช่องนี้แล้วเปิดหน้าโปรไฟล์ของช่องนั้น
        .linkSlot(s.profileURL)
    }

    // MARK: ช่อง 2 — ยอดผู้ติดตามเต็มหลัก

    /// **เต็มหลักพร้อมจุลภาค ไม่ย่อเป็น K** — ต้นฉบับเขียน "125,000" ตัวยักษ์ ความเต็มของเลขคือ
    /// สิ่งที่ทำให้ช่องกลางหนักที่สุดในแผ่น (320K อ่านเร็วกว่า แต่เบาจนช่องกลางโหว่)
    ///
    /// ตัวเลขแต่ละหลักเป็น `Text` แยกกัน (ถอดทีละหลักตอนปัดหน้า) `minimumScaleFactor` จึงย่อทั้งก้อนไม่ได้ —
    /// ขนาดคิดให้พอดีช่องตั้งแต่ต้น: ล้านต้น ๆ ("1,240,000") ย่อลงเอง ส่วนหลักแสนได้ขนาดของต้นฉบับ
    private func followers(_ s: SocialProfile, skin: MacWindowSkin, colW: CGFloat) -> some View {
        let num = Fmt.baht(s.followerCount)
        let fs = Ed.fitted(num, weight: .heavy, width: colW - 22, cap: 37, floor: 14)
        return VStack(spacing: -fs * 0.19) {
            ScrubDigits(text: num, d: scrub.d, lead: 0.06, step: 0.04, drop: 26)
                .dataValue()
                .font(.sh(fs, .heavy))
                .kerning(-fs * 0.024)
                .foregroundStyle(skin.number)
            Text("ผู้ติดตาม")
                .font(.sh(14, .medium))
                .foregroundStyle(skin.soft)
                .scrubVeil(scrub.d, lead: 0.14, drop: 14, pull: 8)
        }
        .padding(.horizontal, 8)
        .padding(.top, 2)
    }

    // MARK: ช่อง 3 — Engagement Rate

    /// ER มาจากการเชื่อมบัญชีเท่านั้น (ดู `SocialProfile.engagementRate`) — ยังไม่มีค่า = ขีด + บอกว่ารออะไร
    /// ไม่เดาเลขให้ดูดี: ช่องที่กรอกเองไม่มี ER จริง
    private func engagement(_ s: SocialProfile, skin: MacWindowSkin, colW: CGFloat) -> some View {
        let has = s.engagementRate > 0
        let num = has ? Fmt.pct(s.engagementRate) : "–"
        let fs = Ed.fitted(num, weight: .heavy, width: colW - 22, cap: 30.5, floor: 14)
        return VStack(spacing: -4) {
            ScrubDigits(text: num, d: scrub.d, lead: 0.12, step: 0.05, drop: 24)
                .dataValue()
                .font(.sh(fs, .heavy))
                .kerning(-fs * 0.02)
                .foregroundStyle(has ? skin.number : skin.soft)
            VStack(spacing: -2) {
                Text("Engagement Rate")
                    .font(.sh(11.4, .bold))
                    .foregroundStyle(skin.number)
                Text(has ? "เฉลี่ย 30 โพสต์ล่าสุด" : "รอเชื่อมบัญชี")
                    .font(.sh(8.6, .regular))
                    .foregroundStyle(skin.soft)
            }
            .lineLimit(1).minimumScaleFactor(0.6)
            .scrubVeil(scrub.d, lead: 0.18, drop: 12, pull: 8)
        }
        .padding(.horizontal, 8)
    }

    // MARK: ฐาน — สูตร ER · ที่มาของตัวเลข

    private func footer(_ s: SocialProfile, skin: MacWindowSkin) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(skin.hair.opacity(0.75)).frame(height: 0.7)
                .padding(.horizontal, 8)
            HStack {
                Text("ER = (Like + Comment + Share) ÷ Views × 100")
                Spacer(minLength: 8)
                Text(source(s))
            }
            .font(.sh(6.8, .regular))
            .foregroundStyle(skin.faint)
            .lineLimit(1).minimumScaleFactor(0.7)
            .padding(.horizontal, 12)
            .frame(maxHeight: .infinity)
            .scrubVeil(scrub.d, lead: 0.22, drop: 10, pull: 6)
        }
        .frame(height: SW.footer)
    }

    /// มุมขวาล่าง — ต้นฉบับเขียน "ข้อมูลสมมติ" เพราะแผ่นนั้นเป็นตัวอย่าง · บนการ์ดจริงบอกที่มาของตัวเลขตามจริง
    @MainActor
    private func source(_ s: SocialProfile) -> String {
        if Profile.me.sampleFamilies.contains(.followers) { return "ข้อมูลตัวอย่าง" }
        // ยอดทุกช่องระบบ Sale Here ดึงเองจากลิงก์ที่วาง — ไม่มี "กรอกเอง · รอตรวจสอบ" ขัดกับป้าย Verified ที่มุมขวาบน
        return "ข้อมูลจาก \(s.type.windowName)"
    }
}

// MARK: - 02 หน้าต่างพอร์ต (PORTFOLIO)

/// ค่าคงที่ของผัง — วัดจากแผ่นต้นฉบับ 420 × 648 แล้วย่อเป็นกว้าง 366 (× 0.871)
/// ตำแหน่งทุกค่าวัดจาก **ขอบบนของพื้นที่เนื้อหา** (ใต้แถบหัว)
enum PWin {
    static let w: CGFloat = 366
    static let h: CGFloat = 565
    /// ศูนย์กลางบรรทัดชื่อ
    static let nameMid: CGFloat = 34
    static let nameCap: CGFloat = 27
    /// ขอบบนของตัวพิมพ์ใหญ่ในคำพาดหัว
    static let capTop: CGFloat = 52
    /// คำพาดหัวกินความกว้างเท่าไหร่ของหน้าต่าง
    static let wordW: CGFloat = 0.936
    /// หัวคนตัดผ่านตัวอักษรลงมากี่ส่วนของความสูงตัวพิมพ์ใหญ่ — คาบเกี่ยว ไม่ใช่กลืน
    static let overlap: CGFloat = 0.56
    /// เส้นสองข้างชื่อ
    static let rule: CGFloat = 0.133
    static let ruleGap: CGFloat = 0.026
}

struct PortfolioWindowWidget: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(\.widgetID) private var wid
    @Environment(\.widgetLiftsPhoto) private var liftsPhoto
    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.widgetTextStyle) private var tune
    let theme: CardTheme
    let size: CGSize

    private static let headlinePreset = "PORTFOLIO"

    var body: some View {
        PosterSheet(design: CGSize(width: PWin.w, height: PWin.h), frame: size) { box in
            let skin = MacWindowSkin.make(surface)
            MacWindow(skin: skin, tools: MacTool.image) {
                EmptyView()
            } content: {
                page(skin, w: box.width, h: box.height - MW.bar)
            }
            .frame(width: box.width, height: box.height)
        }
    }

    /// - Parameters: `w`/`h` = พื้นที่เนื้อหาใต้แถบหัว (หน่วยออกแบบ)
    private func page(_ skin: MacWindowSkin, w: CGFloat, h: CGFloat) -> some View {
        let plane = cutoutPlane(photos, slot: 1, widget: wid, lift: liftsPhoto)
        let word = Profile.me.note(wid, 1, preset: Self.headlinePreset).uppercased()
        // คำพาดหัวต้องกิน **เต็มความกว้าง** ของหน้าต่างเสมอ — คำสั้นลอยครึ่งแผ่นไม่ใช่โปสเตอร์
        let fs = Ed.fitted(word, weight: .black, face: .serif, width: w * PWin.wordW,
                           cap: h * 0.2, floor: 18)
        let tuned = tune.scaled(fs, for: .note, 1)
        let ui = CardFont.serif.uiFont(tuned, .black)
        // วางด้วย *ขอบบนของตัวพิมพ์ใหญ่* ไม่ใช่ขอบบนของกล่องข้อความ — กล่องของเซริฟมีที่ว่างเหนือหัวตัวอักษร
        // ไม่เท่ากันทุกขนาด ถ้าวางด้วยกล่อง คำยาวกับคำสั้นจะลอยคนละระดับ
        let lineTop = PWin.capTop - (ui.ascender - ui.capHeight)
        let subjectTop = PWin.capTop + ui.capHeight * PWin.overlap
        let bleed = h * 0.04

        return ZStack(alignment: .topLeading) {
            // ── พื้นสตูดิโอ — เทาอ่อนเรียบ มีแสงนวลหลังตัวคนนิดเดียว (ต้นฉบับถ่ายบนฉากเทา)
            RadialGradient(colors: [skin.body.opacity(skin.night ? 0.0 : 0.9),
                                    skin.bodyLow.opacity(0)],
                           center: UnitPoint(x: 0.5, y: 0.45), startRadius: 0, endRadius: w * 0.7)

            // ── ชั้นหลัง: ชื่อ + คำยักษ์
            nameRow(skin, w: w)
                .frame(width: w)
                .position(x: w / 2, y: PWin.nameMid)
                .scrubSlide(scrub.d, travel: -w * 0.18, fade: 0.84, eased: false)

            headline(word, size: fs, skin: skin)
                .frame(width: w, height: ui.lineHeight, alignment: .top)
                .offset(y: lineTop)
                .scrubSlide(scrub.d, travel: -w * 0.26, fade: 0.84, eased: false)

            // ── ชั้นกลาง: คน
            switch plane {
            case let .subject(img, _):
                CutoutSubject(image: img, height: max(h * 0.4, h + bleed - subjectTop),
                              d: scrub.d, drift: w * 0.04, shadow: false)
                    .photoSlot(1)
                    .frame(width: w, height: h, alignment: .bottom)
                    // ล้นขอบล่าง — รอยตัดที่เอวจบนอกหน้าต่าง ไม่ใช่กลางแผ่น
                    .offset(y: bleed)
            case .framed:
                // รูปทึบ — ไม่มีอัลฟาให้คำลอดหลังคน · รูปจึงเป็น *เนื้อไฟล์* ใต้หัวเรื่อง
                // เต็มความกว้างหน้าต่าง ชนขอบล่าง (หน้าต่างรูปของ Preview ที่มีแถบหัวเรื่องข้างบน)
                let top = PWin.capTop + ui.capHeight + 12
                Color.clear
                    .overlay {
                        WidgetPhoto(index: 1)
                            .aspectRatio(contentMode: .fill)
                            .scrubDolly(scrub.d, shift: w * 0.04, zoom: 0.12)
                    }
                    .frame(width: w, height: max(40, h - top))
                    .clipped()
                    .photoSlot(1)
                    .padding(.top, top)
                    .frame(width: w, height: h, alignment: .top)
            }

            CutoutStatus(plane: plane, theme: theme,
                         lifting: cutoutLifting(photos, slot: 1, widget: wid, lift: liftsPhoto))
                .padding(9)
                .frame(width: w, height: h, alignment: .topTrailing)
        }
        .frame(width: w, height: h)
    }

    /// ชื่อกลางแผ่น มีเส้นบางสองข้าง — เส้นหดเองเมื่อชื่อยาว (ไม่ดันชื่อให้เล็กลง)
    private func nameRow(_ skin: MacWindowSkin, w: CGFloat) -> some View {
        let name = Profile.me.name
        let ns = Ed.fitted(name, weight: .regular, face: .serif, width: w * 0.58,
                           cap: PWin.nameCap, floor: 12)
        let ruleColor = skin.soft.opacity(skin.night ? 0.8 : 0.9)
        return HStack(spacing: w * PWin.ruleGap) {
            Rectangle().fill(ruleColor).frame(maxWidth: w * PWin.rule, maxHeight: 0.9)
            HStack(spacing: ns * 0.25) {
                Text(name)
                    .lineLimit(1)
                    .fixedSize()
                    .editableText(.name, .init(size: ns, weight: .regular, face: .serif,
                                               color: skin.title))
                if Profile.me.creator.verified {
                    StarSeal(size: max(8, ns * 0.38), tint: skin.title,
                             punch: skin.night ? MacWindowSkin.night.body : MacWindowSkin.day.body)
                }
            }
            Rectangle().fill(ruleColor).frame(maxWidth: w * PWin.rule, maxHeight: 0.9)
        }
        .frame(width: w * 0.94)
    }

    /// คำยักษ์เซริฟดำ ไล่เฉดเทาจากบนลงล่างตามต้นฉบับ (#6E→#8E) — **ไล่เฉดเฉพาะตอนเจ้าของยังไม่เลือกสี**
    /// เลือกสีเองแล้วต้องได้สีนั้นทั้งคำ (เฉดที่ตั้งที่ตัว `Text` ชนะสีจากแถบพิมพ์เสมอ)
    @ViewBuilder
    private func headline(_ word: String, size fs: CGFloat, skin: MacWindowSkin) -> some View {
        let text = Text(word)
            .kerning(-fs * 0.02)
            .lineLimit(1).minimumScaleFactor(0.3)
        let style = TextSlotStyle(size: fs, weight: .black, face: .serif,
                                  color: skin.night ? Color(white: 0.74) : Color(white: 0.47),
                                  align: .center, tracking: -fs * 0.02, uppercase: true, corner: 6)
        if tune.tint(for: .note, 1) == nil {
            text
                .foregroundStyle(LinearGradient(
                    colors: skin.night ? [Color(white: 0.80), Color(white: 0.56)]
                                       : [Color(white: 0.40), Color(white: 0.56)],
                    startPoint: .top, endPoint: .bottom))
                .editableText(.note, index: 1, widget: wid, preset: Self.headlinePreset,
                              hint: "คำพาดหัว", style)
        } else {
            text.editableText(.note, index: 1, widget: wid, preset: Self.headlinePreset,
                              hint: "คำพาดหัว", style)
        }
    }
}
