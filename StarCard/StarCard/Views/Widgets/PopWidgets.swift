import SwiftUI

// MARK: - สำรับ "แผ่นสติกเกอร์"
//
// แปลงตรงจากไฟล์ดีไซน์ `template STAR CARD_1.svg` (กระดาษเทป) และ `_2.svg` (กระจกชมพู)
// ทั้งสองไฟล์คือ **ผังเดียวกัน 8 กล่อง** ต่างกันแค่วัสดุ — วิวจึงมี 8 ตัวเหมือนเดิม
// แต่ `WidgetKind` มี 16 ตัว (แปดหน้าที่ × สองวัสดุ) แล้วส่งวัสดุลงมาทาง `\.popSkin`
//
// เดิมวัสดุอ่านจากมุมของธีม ผลคือตู้วิดเจ็ตโชว์ได้ทีละวัสดุ แล้วอีกแบบหนึ่งหยิบไม่ได้เลย
// ตอนนี้วัสดุเป็นของชนิด — ตู้จึงวางฝาแฝดสองใบให้เลือกข้างกัน และคละวัสดุในการ์ดเดียวได้
//
// กติกาที่ยกมาจากสำรับ Gen Z:
// 1. **หนึ่งสกิน หนึ่งวัสดุ** — กระจก = กล่องขาวมุมมน เงานุ่ม ป้ายเม็ดยาชมพู ·
//    กระดาษ = กล่องขาวมุมเหลี่ยม เงาแข็ง ป้ายดำเอียง เทปกาว รูเจาะสมุด
// 2. **หมึกคงที่ ไม่พลิกตามหมึกการ์ด** — ตัวหนังสือบนกล่องขาวเป็นถ่านเสมอ
//    (เหตุผลเดียวกับกระดาษโน้ต: ฉลากที่พลิกเป็นขาวตามการ์ดไม่ใช่ฉลากอีกต่อไป)
// 3. สีชมพูของป้าย/ขอบ/ราคา = `theme.rawAccent` — เปลี่ยนพาเลตต์แล้วทั้งแผ่นเปลี่ยนตาม

enum Pop {
    typealias Skin = PopSkin

    /// **ค่าสำรองเท่านั้น** — วัสดุจริงมาจากชนิดของ widget (`WidgetKind.popSkin`) ทาง `\.popSkin`
    /// ตัวนี้เหลือไว้ให้พรีวิวที่วาดวิวตรง ๆ โดยไม่ผ่าน `WidgetBody` ยังได้หน้าตาที่เข้ากับธีม
    static func skin(_ t: CardTheme) -> Skin { t.corner == .soft ? .paper : .glass }

    /// ถ่านอมม่วง — ดำสนิทบนกล่องขาวชมพูอ่านแข็งเกินไป
    static let ink = Color(red: 0.11, green: 0.10, blue: 0.13)
    static let inkSoft = Color(red: 0.40, green: 0.37, blue: 0.43)
    static let paper = Color.white
    /// เส้นคั่นบนกระดาษ
    static let rule = Color(red: 0.84, green: 0.82, blue: 0.85)

    /// สีชมพูของแผ่น — สีเน้นดิบของธีม (ไม่ผ่านสูตรหมึก เพราะวางบนกล่องขาวของตัวเอง)
    static func pink(_ t: CardTheme) -> Color { t.rawAccent }
    static func pinkSoft(_ t: CardTheme) -> Color { t.rawAccentSoft }

    /// พื้นของแผ่นตามพื้นผิวที่ผู้ใช้เลือก (แผงกล่องเหลือสองแบบ: กระจก · เข้ม)
    ///
    /// สำรับนี้ต่างจากที่อื่นตรง **ตัวหนังสือเป็นถ่านคงที่** (ฉลากบนกล่องขาวไม่พลิกตามการ์ด)
    /// แผ่นของมันจึงพลิกเป็นถ่านทึบไม่ได้ — "เข้ม" ที่นี่จึงแปลว่า **ทึบ**: กล่องกระดาษที่ไม่มีอะไรทะลุ
    /// ส่วนกระจกคือ ~62% ที่เห็นกริดพื้นหลังทะลุตามไฟล์ดีไซน์ ความต่างที่ตาเห็นคือ "โปร่ง" กับ "ทึบ"
    static func sheetFill(_ s: WidgetSurface, skin: Skin, theme: CardTheme) -> Color {
        switch s {
        case .glass: return paper.opacity(skin == .glass ? 0.62 : 0.9)
        // สำรับนี้ไม่ให้เลือก "ไม่มีพื้น" (ดู `WidgetKind.surfaceOptions`) — ไฟล์เก่าที่เคยเก็บค่านั้น
        // ไว้ตกมาเป็นกล่องทึบ ไม่ใช่กล่องหาย
        case .dim, .clear, .pane: return paper
        }
    }
    static func sheetShadow(_ s: WidgetSurface, skin: Skin, theme: CardTheme) -> Color {
        skin == .glass ? pink(theme).opacity(0.35) : Color.black.opacity(0.22)
    }

    /// ความสูงของป้ายหัวข้อ — ครึ่งหนึ่งโผล่พ้นขอบบนของกล่อง
    static let labelHeight: CGFloat = 26
    /// ป้ายทรงแท็บกว้างของสามกล่องแถวล่าง
    static let labelHeightWide: CGFloat = 30

    /// ไอคอนประจำสายงาน — ป้ายในลิสต์ต้องมีรูปนำทุกบรรทัด
    static func nicheIcon(_ t: String) -> String {
        let s = t.lowercased()
        if s.contains("บิวตี้") || s.contains("สกินแคร์") || s.contains("เมคอัพ") || s.contains("beauty") {
            return "cylinder.split.1x2.fill"
        }
        if s.contains("ไลฟ์") || s.contains("life") { return "bubble.left.and.bubble.right.fill" }
        if s.contains("ออกกำลัง") || s.contains("ฟิต") || s.contains("fit") || s.contains("กีฬา") { return "dumbbell.fill" }
        if s.contains("คาเฟ่") || s.contains("cafe") || s.contains("กาแฟ") { return "house.fill" }
        if s.contains("อาหาร") || s.contains("food") { return "fork.knife" }
        if s.contains("แฟชั่น") || s.contains("fashion") { return "tshirt.fill" }
        if s.contains("ท่องเที่ยว") || s.contains("travel") { return "airplane" }
        if s.contains("แม่") || s.contains("เด็ก") { return "figure.and.child.holdinghands" }
        if s.contains("เกม") || s.contains("game") { return "gamecontroller.fill" }
        return "tag.fill"
    }
}

// MARK: - ชิ้นส่วนร่วม

/// ป้ายหัวข้อ — ไอคอนในวงขาว + ชื่อหมวด
/// กระจก: เม็ดยาชมพู · กระดาษ: แถบดำมุมเล็กเอียงนิดหนึ่งเหมือนสติกเกอร์ที่แปะมือ
struct PopLabel: View {
    /// วัสดุที่ชนิดของ widget สั่งมา (ดู `WidgetKind.popSkin`) — `nil` เมื่อวาดนอกการ์ด เช่นพรีวิวใน Xcode
    @Environment(\.popSkin) private var skinOverride
    let theme: CardTheme
    let text: String
    let icon: String
    /// แถบกว้าง — สามกล่องแถวล่างในต้นฉบับใช้ป้ายทรง "แท็บ" กว้างเกือบเท่ากล่อง ตัวหนังสือใหญ่กว่า
    var wide: Bool = false

    var body: some View {
        let skin = skinOverride ?? Pop.skin(theme)
        let h = wide ? Pop.labelHeightWide : Pop.labelHeight
        HStack(spacing: wide ? 7 : 6) {
            ZStack {
                Circle().fill(.white)
                Image(systemName: icon)
                    .font(.system(size: wide ? 11 : 9.5, weight: .bold))
                    .foregroundStyle(skin == .glass ? Pop.pink(theme) : Pop.ink)
            }
            .frame(width: wide ? 20 : 17, height: wide ? 20 : 17)
            Text(text)
                .font(.sh(wide ? 15 : 12.5, .bold))
                .foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .padding(.leading, wide ? 8 : 5).padding(.trailing, 12)
        .frame(height: h)
        .frame(maxWidth: wide ? .infinity : nil, alignment: .leading)
        .background {
            if skin == .glass {
                if wide {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Pop.pink(theme))
                } else {
                    Capsule().fill(Pop.pink(theme))
                }
            } else {
                RoundedRectangle(cornerRadius: 3, style: .continuous).fill(Pop.ink)
            }
        }
        .rotationEffect(.degrees(skin == .paper ? -2 : 0), anchor: .bottomLeading)
    }
}

/// กล่องขาวของทุก widget ในสำรับ — ป้ายหัวข้อคร่อมขอบบนซ้าย
///
/// เว้นขอบนอก 4pt ไว้ให้เงา — `WidgetChrome` clip เนื้อหาเข้ากรอบ widget พอดี เงาที่ล้นออกจะหาย
struct PopSheet<Content: View>: View {
    /// วัสดุที่ชนิดของ widget สั่งมา (ดู `WidgetKind.popSkin`) — `nil` เมื่อวาดนอกการ์ด เช่นพรีวิวใน Xcode
    @Environment(\.popSkin) private var skinOverride
    let theme: CardTheme
    var label: String? = nil
    var icon: String = "star.fill"
    var pad: CGFloat = 10
    /// มุมกระดาษพับที่ขอบขวาล่าง — ใช้เฉพาะสกินกระดาษกับกล่องที่ต้นฉบับพับ
    var fold: Bool = false
    /// ป้ายทรงแท็บกว้าง (ดู `PopLabel.wide`)
    var wide: Bool = false
    @ViewBuilder var content: Content

    @Environment(\.widgetSurface) private var surface
    @Environment(\.widgetBorder) private var border

    var body: some View {
        let skin = skinOverride ?? Pop.skin(theme)
        let r: CGFloat = skin == .glass ? 20 : 5
        let shape = RoundedRectangle(cornerRadius: r, style: .continuous)
        let lh = wide ? Pop.labelHeightWide : Pop.labelHeight
        let top: CGFloat = label == nil ? 0 : lh / 2

        ZStack(alignment: .topLeading) {
            shape.fill(Pop.sheetFill(surface, skin: skin, theme: theme))
                .overlay {
                    // กระจก: ประกายขอบบนบาง ๆ ให้แผ่นอ่านเป็นกระจก ไม่ใช่ขาวจาง
                    if surface == .glass {
                        shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.95), .white.opacity(0.25)],
                                                          startPoint: .top, endPoint: .bottom), lineWidth: 1.2)
                    }
                }
                .overlay { if border { shape.strokeBorder(Pop.pink(theme), lineWidth: 1.6) } }
                .shadow(color: Pop.sheetShadow(surface, skin: skin, theme: theme),
                        radius: skin == .glass ? 9 : 5, y: skin == .glass ? 5 : 4)
                .overlay(alignment: .bottomTrailing) {
                    if fold && skin == .paper { PopFold(theme: theme) }
                }
            content
                .padding(pad)
                .padding(.top, label == nil ? 0 : lh / 2 + 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipShape(shape)
        }
        .padding(.top, top)
        .overlay(alignment: .topLeading) {
            if let label {
                PopLabel(theme: theme, text: label, icon: icon, wide: wide)
                    .padding(.leading, skin == .glass ? (wide ? 6 : 10) : 8)
                    .padding(.trailing, wide ? 14 : 0)
            }
        }
        .padding(4)
    }
}

/// แผ่นที่แปะเอียง — หมุนทั้งแผ่น แล้ว **ย่อให้มุมทั้งสี่ยังอยู่ในกรอบ widget**
///
/// `WidgetChrome` clip สำรับนี้เข้ากรอบสี่เหลี่ยมตรง (กันไม่ให้ล้นไปทับชิ้นข้างเคียง)
/// หมุนเฉย ๆ มุมแผ่นจะโดนตัดทิ้งทั้งสี่มุม · ย่อเท่าที่กรอบครอบของแผ่นที่หมุนแล้วพอดีกรอบเดิม
/// ในไฟล์ดีไซน์ก็เป็นแบบนี้ — แผ่นเอียงนั่งอยู่ในช่องของมัน ไม่ได้ล้นช่อง
///
/// บอกมุมลงไปทาง `slotTilt` ด้วย เส้นประของช่องข้อความบนแผ่นจะได้เอียงตาม (ดู `TextSlotStyle.tilt`)
struct PopTilt<Content: View>: View {
    /// องศา — บวก = ตามเข็ม
    let degrees: Double
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { g in
            let t = abs(degrees) * .pi / 180
            let c = cos(t), s = sin(t)
            let w = max(g.size.width, 1), h = max(g.size.height, 1)
            let fit = min(w / (w * c + h * s), h / (w * s + h * c))
            content
                .frame(width: g.size.width, height: g.size.height)
                .environment(\.slotTilt, degrees)
                .rotationEffect(.degrees(degrees))
                .scaleEffect(fit)
        }
    }
}

/// มุมกระดาษพับ — บอกว่านี่คือแผ่นกระดาษ ไม่ใช่กล่อง
///
/// สามเหลี่ยมบนซ้าย = พื้นการ์ดที่โผล่จากมุมที่ถูกพับออก (สีชมพูอ่อนของธีม) ·
/// สามเหลี่ยมล่างขวา = ด้านหลังของกระดาษที่พับขึ้นมา ไล่เฉดเทาให้มีความหนา
struct PopFold: View {
    let theme: CardTheme
    var size: CGFloat = 16
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Path { p in
                p.move(to: CGPoint(x: 0, y: size))
                p.addLine(to: CGPoint(x: size, y: 0))
                p.addLine(to: CGPoint(x: size, y: size))
                p.closeSubpath()
            }
            .fill(Pop.pinkSoft(theme).opacity(0.85))
            Path { p in
                p.move(to: CGPoint(x: 0, y: size))
                p.addLine(to: CGPoint(x: size, y: 0))
                p.addLine(to: CGPoint(x: 0, y: 0))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color(red: 0.97, green: 0.96, blue: 0.97),
                                          Color(red: 0.80, green: 0.77, blue: 0.80)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .shadow(color: .black.opacity(0.18), radius: 1.5, x: -1, y: -1)
        }
        .frame(width: size, height: size)
    }
}

/// เทปกาวสีชมพูโปร่ง — แปะเฉียงบนมุมรูปในสกินกระดาษ
struct PopTape: View {
    let theme: CardTheme
    var width: CGFloat = 54
    var body: some View {
        Rectangle()
            .fill(Pop.pink(theme).opacity(0.62))
            .frame(width: width, height: 13)
            .overlay(Rectangle().strokeBorder(.white.opacity(0.35), lineWidth: 0.5))
    }
}

/// ป้าย VERIFIED BY SALE HERE — สีน้ำเงินคงที่ตามไฟล์ดีไซน์ ไม่ย้อมตามธีม
/// (ตราของผู้รับรองต้องเป็นสีของผู้รับรอง ไม่ใช่สีของการ์ดที่มันรับรองอยู่)
struct PopVerified: View {
    private let blue = Color(red: 0.16, green: 0.50, blue: 0.90)

    var body: some View {
        HStack(spacing: 5) {
            // ตราหยัก: ฟ้าอ่อนหยัก → วงขาว → เครื่องหมายถูกฟ้า (ตามไฟล์)
            ZStack {
                Image(systemName: "seal.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(red: 0.42, green: 0.80, blue: 0.98))
                Circle().fill(.white).frame(width: 23, height: 23)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(blue)
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: -4) {
                Text("VERIFIED").font(.sh(19, .black)).kerning(0.2)
                Text("BY SALE HERE").font(.sh(10, .black)).kerning(0.3)
            }
            .foregroundStyle(.white)
            .lineLimit(1).minimumScaleFactor(0.6)
        }
        .padding(.leading, 3).padding(.trailing, 8).padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.30, green: 0.66, blue: 0.96),
                                              Color(red: 0.13, green: 0.40, blue: 0.84)],
                                     startPoint: .leading, endPoint: .trailing))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 01 · ป้ายชื่อ

/// ชื่อตัวใหญ่ · รูปโปรไฟล์ · @handle + ประเภทบัญชี · พื้นที่รับงาน · ป้าย VERIFIED
///
/// กระจก: ทุกอย่างอยู่ในกล่องขาวใบเดียว · กระดาษ: ชื่อลอยบนการ์ด รูปแปะเทป ข้อมูลอยู่บนกระดาษโน้ตพับมุม
struct PopHero: View {
    @Environment(PhotoStore.self) private var photos
    /// วัสดุที่ชนิดของ widget สั่งมา (ดู `WidgetKind.popSkin`) — `nil` เมื่อวาดนอกการ์ด เช่นพรีวิวใน Xcode
    @Environment(\.popSkin) private var skinOverride

    let theme: CardTheme
    let size: CGSize

    /// ชื่อกินเกือบเต็มความกว้างกล่องเหมือนต้นฉบับ — ชื่อยาวกว่านั้นย่อเองด้วย `minimumScaleFactor`
    private var nameSize: CGFloat { min(60, size.width * 0.215) }

    var body: some View {
        let skin = skinOverride ?? Pop.skin(theme)
        Group {
            if skin == .glass {
                PopSheet(theme: theme, pad: 10) { inner }
            } else {
                inner.padding(6)
            }
        }
    }

    private var inner: some View {
        let skin = skinOverride ?? Pop.skin(theme)
        return VStack(alignment: .leading, spacing: 6) {
            Text(Profile.me.name)
                .kerning(-0.5)
                .lineLimit(1).minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .editableText(.name, .init(size: nameSize, weight: .black, color: Pop.ink, tracking: -0.5))

            HStack(alignment: .top, spacing: 10) {
                // รูปกิน 44% ของแถว — ที่เหลือเป็นคอลัมน์ข้อมูล (แบ่งครึ่งแล้วบรรทัด @handle ไม่พอ)
                portrait
                    .frame(width: (size.width - (skin == .glass ? 28 : 12) - 10) * 0.42)

                VStack(alignment: .leading, spacing: 0) {
                    // สัดส่วนตามไฟล์: บรรทัด @handle ใหญ่ ไอคอน IG เท่าตัวหนังสือ · ขีดคั่นบาง · คนกับ "บุคคล"
                    HStack(spacing: 5) {
                        BrandIcon(name: SHIcon.instagram, size: 15)
                        Text("@" + Profile.me.handle)
                            .lineLimit(1).minimumScaleFactor(0.55)
                            .editableText(.handle, .init(size: 11.5, weight: .medium, color: Pop.ink))
                        Rectangle().fill(Pop.ink.opacity(0.5)).frame(width: 0.8, height: 15)
                        Image(systemName: "person.fill").font(.system(size: 11, weight: .bold))
                        Text("บุคคล").font(.sh(11.5, .medium)).lineLimit(1).fixedSize()
                    }
                    .foregroundStyle(Pop.ink)
                    .padding(.top, 10)

                    Spacer(minLength: 6)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("พื้นที่รับงาน : ").font(.sh(11, .bold)).fixedSize()
                            Text(Profile.me.text(.workArea))
                                .lineLimit(1).minimumScaleFactor(0.7)
                                .editableText(.workArea, .init(size: 11, weight: .regular, color: Pop.ink))
                        }
                        .foregroundStyle(Pop.ink)
                        Rectangle().fill(Pop.ink.opacity(0.85)).frame(height: 1)
                    }

                    Spacer(minLength: 6)

                    if Profile.me.creator.verified {
                        PopVerified()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                .padding(8)
                .background {
                    if skin == .paper {
                        // กระดาษโน้ตพับมุม — ข้อมูลไม่ได้ลอยบนการ์ด มันเขียนอยู่บนกระดาษอีกแผ่น
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Pop.paper)
                            .shadow(color: .black.opacity(0.2), radius: 5, y: 4)
                            .overlay(alignment: .bottomTrailing) { PopFold(theme: theme) }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    /// รูปโปรไฟล์ — กระจก: มุมมน ขอบชมพูอ่อน · กระดาษ: รูปอัดขอบขาว แปะเทปเฉียงมุมบน
    private var portrait: some View {
        let skin = skinOverride ?? Pop.skin(theme)
        let r: CGFloat = skin == .glass ? 14 : 2
        let shape = RoundedRectangle(cornerRadius: r, style: .continuous)
        return Color.clear
            .overlay { WidgetPhoto(index: 1).aspectRatio(contentMode: .fill) }
            .clipShape(shape)
            .overlay(shape.strokeBorder(skin == .glass ? Pop.pinkSoft(theme) : .white, lineWidth: skin == .glass ? 2.5 : 5))
            .shadow(color: skin == .paper ? .black.opacity(0.28) : .clear, radius: 6, y: 4)
            .rotationEffect(.degrees(skin == .paper ? -2 : 0))
            .overlay(alignment: .top) {
                if skin == .paper {
                    PopTape(theme: theme).rotationEffect(.degrees(-8)).offset(x: -18, y: -4)
                }
            }
            .photoSlot(1)
    }
}

// MARK: - 02 · หน้าต่างวิดีโอ

/// เพลเยอร์แนวนอน — แถบชื่อ "Video" + จุดสามจุด · คลิป · ปุ่ม ⏮ ▶ ⏭ 🔊 (ตกแต่ง ไม่กดจริง)
/// กระจก: หน้าต่างขาว · กระดาษ: หน้าต่างดำเหมือนเครื่องเล่นพกพา
struct PopVideo: View {
    @Environment(PhotoStore.self) private var photos
    /// วัสดุที่ชนิดของ widget สั่งมา (ดู `WidgetKind.popSkin`) — `nil` เมื่อวาดนอกการ์ด เช่นพรีวิวใน Xcode
    @Environment(\.popSkin) private var skinOverride

    @Environment(\.widgetSurface) private var surface
    @Environment(\.widgetBorder) private var border
    let theme: CardTheme

    var body: some View {
        let skin = skinOverride ?? Pop.skin(theme)
        let dark = skin == .paper
        let fg: Color = dark ? .white : Pop.ink
        let r: CGFloat = dark ? 12 : 18
        let frame = RoundedRectangle(cornerRadius: dark ? 9 : 12, style: .continuous)

        VStack(spacing: 0) {
            HStack {
                Text("Video").font(.sh(18, .bold))
                Spacer(minLength: 0)
                Image(systemName: "ellipsis").font(.system(size: 19, weight: .black))
            }
            .foregroundStyle(fg)
            .padding(.horizontal, 13).padding(.top, 11).padding(.bottom, 6)

            Color.clear
                .overlay { WidgetPhoto(index: 2).aspectRatio(contentMode: .fill) }
                .clipShape(frame)
                .overlay(frame.strokeBorder(dark ? .white.opacity(0.9) : Pop.pink(theme).opacity(0.75), lineWidth: 2.5))
                .padding(.horizontal, 10)
                .frame(maxHeight: .infinity)
                .photoSlot(2)

            HStack(spacing: 0) {
                Image(systemName: "backward.end.fill").frame(maxWidth: .infinity)
                Image(systemName: "play.fill").frame(maxWidth: .infinity)
                Image(systemName: "forward.end.fill").frame(maxWidth: .infinity)
                Image(systemName: "speaker.wave.2.fill").frame(maxWidth: .infinity)
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(fg)
            .padding(.horizontal, 6).padding(.top, 9).padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(dark ? Pop.ink : Pop.sheetFill(surface, skin: skin, theme: theme))
                .overlay {
                    if !dark && surface == .glass {
                        RoundedRectangle(cornerRadius: r, style: .continuous)
                            .strokeBorder(LinearGradient(colors: [.white.opacity(0.95), .white.opacity(0.25)],
                                                         startPoint: .top, endPoint: .bottom), lineWidth: 1.2)
                    }
                    if border {
                        RoundedRectangle(cornerRadius: r, style: .continuous).strokeBorder(Pop.pink(theme), lineWidth: 1.6)
                    }
                }
                .shadow(color: dark ? .black.opacity(0.28) : Pop.sheetShadow(surface, skin: skin, theme: theme),
                        radius: dark ? 6 : 9, y: 5)
        )
        // เส้นชมพูที่ขอบบนกลางหน้าต่าง — ตามไฟล์
        .overlay(alignment: .top) {
            if !dark {
                Capsule().fill(Pop.pink(theme)).frame(width: 92, height: 3.5).padding(.top, 4)
            }
        }
        .padding(4)
    }
}

// MARK: - 03 · ผู้ติดตามสามช่อง

/// ยอดฟอล IG · TikTok · YouTube ตัวเลขยักษ์
/// กระจก: กล่องมนสามใบ + แถบไอคอน IG ตกแต่งใต้กล่อง · กระดาษ: วงกลมสามวงขอบชมพู
struct PopStats: View {
    /// วัสดุที่ชนิดของ widget สั่งมา (ดู `WidgetKind.popSkin`) — `nil` เมื่อวาดนอกการ์ด เช่นพรีวิวใน Xcode
    @Environment(\.popSkin) private var skinOverride
    let theme: CardTheme

    private var socials: [SocialProfile] { Array(Profile.me.shownSocials.prefix(3)) }

    var body: some View {
        let skin = skinOverride ?? Pop.skin(theme)
        PopSheet(theme: theme, label: "ผู้ติดตาม", icon: "flag.fill", pad: skin == .glass ? 7 : 8) {
            VStack(spacing: 4) {
                HStack(spacing: skin == .glass ? 9 : 12) {
                    ForEach(socials) { s in
                        tile(s).linkSlot(s.profileURL)
                    }
                }
                .frame(maxHeight: .infinity)
                // ป้ายที่มาของยอด — แผ่นสติกเกอร์ใช้ถ่านคงที่บนกล่องขาว จึงใช้ป้ายฉบับพื้นมืดของตัวเอง
                .overlay(alignment: .topTrailing) {
                    ProvenanceTag(kind: Profile.me.shownSocials.provenance, onPhoto: true,
                                  bylineTint: Color(white: 0.12).opacity(0.62))
                        .offset(x: 2, y: -13)
                }

                if skin == .glass {
                    // แถบไอคอน IG — ของตกแต่งที่บอกว่า "นี่คือหน้าจอโซเชียล" ไม่มีข้อมูล
                    HStack(spacing: 0) {
                        ForEach(["house", "magnifyingglass", "camera", "person", "heart", "paperplane", "bookmark"], id: \.self) {
                            Image(systemName: $0).frame(maxWidth: .infinity)
                        }
                    }
                    .font(.system(size: 19, weight: .light))
                    .foregroundStyle(Pop.ink)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Pop.paper.opacity(0.92)))
                }
            }
        }
    }

    /// "184K" → ตัวเลขใหญ่ + หน่วยเล็กลงตามไฟล์
    private func bigNumber(_ n: Int, size: CGFloat) -> Text {
        let s = Fmt.compact(n)
        if let last = s.last, last.isLetter {
            return Text(String(s.dropLast())).font(.sh(size, .black))
                + Text(String(last)).font(.sh(size * 0.68, .black))
        }
        return Text(s).font(.sh(size, .black))
    }

    private func tile(_ s: SocialProfile) -> some View {
        let skin = skinOverride ?? Pop.skin(theme)
        return VStack(spacing: -2) {
            HStack(spacing: 5) {
                BrandIcon(name: s.type.icon, size: 15)
                Text(s.type.name).font(.sh(11.5, .medium)).foregroundStyle(Pop.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            bigNumber(s.followerCount, size: skin == .glass ? 42 : 32)
                .kerning(-1.5)
                .foregroundStyle(Pop.ink)
                .lineLimit(1).minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if skin == .glass {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Pop.paper)
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Pop.pink(theme).opacity(0.6), lineWidth: 2))
            } else {
                Circle()
                    .fill(Color(red: 0.96, green: 0.95, blue: 0.96))
                    .overlay(Circle().strokeBorder(Pop.pinkSoft(theme), lineWidth: 3))
            }
        }
    }
}

// MARK: - 04 · ผลงานสามใบ

/// รูป 3 ใบ + ป้ายหมวด · กระจก: ชิปชมพูทับขอบล่างของรูป · กระดาษ: รูปอัดขอบขาว คำอยู่ที่คางล่าง
struct PopWork: View {
    /// วัสดุที่ชนิดของ widget สั่งมา (ดู `WidgetKind.popSkin`) — `nil` เมื่อวาดนอกการ์ด เช่นพรีวิวใน Xcode
    @Environment(\.popSkin) private var skinOverride
    let theme: CardTheme

    /// ใต้รูปเป็น engagement ของโพสต์นั้น (ไลก์ · คอมเมนต์ · แชร์) — ผูกกับผลงานจริงชิ้นที่ i (จากแคมเปญที่ส่งรีวิวแล้ว)
    private var works: [VerifiedWork] { Profile.me.creator.track.works }
    private let slots = [4, 5, 6]

    var body: some View {
        let skin = skinOverride ?? Pop.skin(theme)
        PopSheet(theme: theme, label: "ผลงานที่ผ่านมา", icon: "rosette", pad: 10, fold: true) {
            HStack(spacing: skin == .glass ? 9 : 8) {
                ForEach(0..<3, id: \.self) { i in
                    card(i)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func card(_ i: Int) -> some View {
        let skin = skinOverride ?? Pop.skin(theme)
        let r: CGFloat = skin == .glass ? 10 : 1.5
        let shape = RoundedRectangle(cornerRadius: r, style: .continuous)
        let photo = Color.clear
            .overlay { WidgetPhoto(index: slots[i]).aspectRatio(contentMode: .fill) }
            .clipShape(shape)

        return Group {
            if skin == .glass {
                photo
                    .overlay(shape.strokeBorder(Pop.pink(theme).opacity(0.7), lineWidth: 2.5))
            } else {
                VStack(spacing: 0) {
                    photo.frame(maxHeight: .infinity)
                    engage(i, tint: Pop.ink, size: 9)
                        .padding(.vertical, 6).padding(.horizontal, 2)
                }
                .padding(4)
                .background(Pop.paper)
                .shadow(color: .black.opacity(0.22), radius: 4, y: 3)
                .rotationEffect(.degrees([-1.5, 1, -0.8][i]))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .photoSlot(slots[i])
        .linkSlot(works.indices.contains(i) ? works[i].postURL : nil)
    }

    /// ♥ ไลก์ · 💬 คอมเมนต์ · ↗ แชร์ ของโพสต์ชิ้นที่ i — ไอคอนแทนคำ เพราะกว้างแค่ ~100pt ต่อใบ
    private func engage(_ i: Int, tint: Color, size: CGFloat) -> some View {
        let w = works.indices.contains(i) ? works[i] : nil
        return Group {
            if let w, w.likes + w.comments + w.shares > 0 {
                HStack(spacing: 0) {
                    stat("heart.fill", w.likes)
                    stat("bubble.left.fill", w.comments)
                    stat("arrowshape.turn.up.right.fill", w.shares)
                }
            } else {
                // ยังไม่มียอดจากระบบ — บอกว่ารอ ไม่โชว์ ♥0 💬0 ที่อ่านเป็น "ไม่มีใครสนใจ"
                Text("รอข้อมูลโพสต์")
            }
        }
        .font(.sh(size, .bold))
        .foregroundStyle(tint)
        .lineLimit(1).minimumScaleFactor(0.6)
        .frame(maxWidth: .infinity)
    }

    private func stat(_ icon: String, _ n: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 7.5, weight: .bold))
            Text(Fmt.compact(n)).dataValue()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 05 · ใบเรตราคา

/// ราคาต่อคลิปต่อแพลตฟอร์ม — โลโก้ซ้าย ราคาชมพูขวา คั่นเส้นประ
/// กระจก: กระดาษพับมุม · กระดาษ: หน้าสมุดเจาะรู ราคาไฮไลต์บล็อกชมพู
struct PopRate: View {
    /// วัสดุที่ชนิดของ widget สั่งมา (ดู `WidgetKind.popSkin`) — `nil` เมื่อวาดนอกการ์ด เช่นพรีวิวใน Xcode
    @Environment(\.popSkin) private var skinOverride
    let theme: CardTheme

    private var rates: [RateItem] { Array(Profile.me.shownRates.prefix(2)) }

    /// ใบเรตราคาถูกแปะเอียง ไม่ใช่วางตรง — มุมตามไฟล์ดีไซน์:
    /// กระจก (`_2.svg`) เอียงทวนเข็ม 7.18° · กระดาษ (`_1.svg`) เอียงตามเข็ม 6.1°
    private func tilt(_ skin: Pop.Skin) -> Double { skin == .glass ? -7.18 : 6.1 }

    var body: some View {
        let skin = skinOverride ?? Pop.skin(theme)
        PopTilt(degrees: tilt(skin)) {
            PopSheet(theme: theme, label: "เรตราคา", icon: "tag.fill",
                     pad: 8, fold: false) {
                VStack(spacing: 0) {
                    ForEach(Array(rates.enumerated()), id: \.element.id) { i, r in
                        row(r, i: i)
                            .frame(maxHeight: .infinity)
                            .overlay(alignment: .top) {
                                if i > 0 { dashes }
                            }
                    }
                }
                .padding(.leading, skin == .paper ? 10 : 0)
            }
            .overlay(alignment: .leading) {
                if skin == .paper {
                    // รูเจาะสมุด — เรียงตามขอบซ้ายของแผ่น
                    VStack(spacing: 9) {
                        ForEach(0..<7, id: \.self) { _ in
                            Circle().fill(Color(red: 0.90, green: 0.88, blue: 0.90))
                                .overlay(Circle().strokeBorder(.black.opacity(0.12), lineWidth: 0.5))
                                .frame(width: 7, height: 7)
                        }
                    }
                    .padding(.leading, 9)
                    .padding(.top, Pop.labelHeight / 2 + 8)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if skin == .glass { PopFold(theme: theme, size: 22).padding(4) }
            }
        }
    }

    private var dashes: some View {
        Rectangle()
            .fill(Pop.ink.opacity(0.5))
            .frame(height: 0.8)
            .mask {
                HStack(spacing: 3) {
                    ForEach(0..<30, id: \.self) { _ in Rectangle().frame(width: 3) }
                    Spacer(minLength: 0)
                }
            }
    }

    private func row(_ r: RateItem, i: Int) -> some View {
        let skin = skinOverride ?? Pop.skin(theme)
        let price = Profile.me.ratePrice(i)
        return HStack(alignment: .center, spacing: 2) {
            VStack(spacing: 1) {
                BrandIcon(name: r.platform.icon, size: 34)
                Text(Profile.me.rateLabel(i))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .editableText(.rateLabels, index: i, .init(size: 8, weight: .medium, color: Pop.ink))
            }
            .frame(width: 50)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: -4) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("฿").font(.sh(21, .black))
                    Text(Fmt.baht(price)).dataValue()
                        .editableText(.ratePrices, index: i, .init(size: 21, weight: .black, color: Pop.ink))
                }
                .kerning(-0.8)
                .foregroundStyle(skin == .glass ? Pop.pink(theme) : Pop.ink)
                .lineLimit(1).minimumScaleFactor(0.55)
                .padding(.horizontal, skin == .paper ? 4 : 0)
                .background {
                    if skin == .paper {
                        RoundedRectangle(cornerRadius: 2).fill(Pop.pinkSoft(theme).opacity(0.9))
                    }
                }
                Text("/\(r.unit)").font(.sh(9, .semibold)).foregroundStyle(Pop.ink)
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - 06 · สายงานแบบลิสต์

/// สายงานเรียงลง ไอคอนนำหน้า คั่นเส้นบาง — อ่านเป็นเมนู ไม่ใช่ชิป
struct PopNiche: View {
    let theme: CardTheme

    var body: some View {
        let items = Array(Profile.me.categories.prefix(5))
        PopSheet(theme: theme, label: "สายงาน", icon: "list.bullet.clipboard.fill", pad: 8, fold: true, wide: true) {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element) { i, t in
                    HStack(spacing: 8) {
                        Image(systemName: Pop.nicheIcon(t))
                            .font(.system(size: 17, weight: .bold))
                            .frame(width: 26)
                        Text(t)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .editableText(.categories, index: i, .init(size: 14, weight: .medium, color: Pop.ink))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(Pop.ink)
                    .padding(.horizontal, 4)
                    .frame(maxHeight: .infinity)
                    .overlay(alignment: .bottom) {
                        if i < items.count - 1 {
                            Rectangle().fill(Pop.rule).frame(height: 0.8)
                        }
                    }
                }
            }
            .id(items)
        }
    }
}

// MARK: - 08 · ช่องทางติดต่อสามแถว

/// โทร · อีเมล · LINE — แต่ละช่องเป็นเม็ดยาขาวขอบชมพู (กระจก) หรือกล่องขอบเทา (กระดาษ)
struct PopContact: View {
    /// วัสดุที่ชนิดของ widget สั่งมา (ดู `WidgetKind.popSkin`) — `nil` เมื่อวาดนอกการ์ด เช่นพรีวิวใน Xcode
    @Environment(\.popSkin) private var skinOverride
    let theme: CardTheme

    var body: some View {
        let skin = skinOverride ?? Pop.skin(theme)
        PopSheet(theme: theme, label: "ช่องทางติดต่อ", icon: "person.fill", pad: 8, wide: true) {
            VStack(spacing: 8) {
                ForEach(Array(ContactLine.all.enumerated()), id: \.offset) { i, l in
                    HStack(spacing: 6) {
                        badge(l)
                        Text(Profile.me.text(l.field))
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .editableText(l.field, .init(size: 12, weight: .medium, color: Pop.ink))
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 5).padding(.trailing, 8).padding(.vertical, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        let shape = RoundedRectangle(cornerRadius: skin == .glass ? 999 : 4, style: .continuous)
                        shape.fill(Pop.paper)
                            .overlay(shape.strokeBorder(skin == .glass ? Pop.pink(theme).opacity(0.6) : Pop.rule,
                                                        lineWidth: skin == .glass ? 2 : 0.8))
                    }
                    .linkSlot(l.field.contactURL)
                }
            }
        }
    }

    /// ไอคอนช่องทาง — โทร/อีเมลวงดำ · LINE วงเขียวของแบรนด์
    private func badge(_ l: ContactLine) -> some View {
        let isLine = l.field == .lineId
        return ZStack {
            Circle().fill(isLine ? Color(red: 0.02, green: 0.78, blue: 0.33) : Pop.ink)
            if isLine {
                Text("LINE").font(.system(size: 6.5, weight: .black)).foregroundStyle(.white)
            } else {
                Image(systemName: l.icon).font(.system(size: 10.5, weight: .bold)).foregroundStyle(.white)
            }
        }
        .frame(width: 23, height: 23)
    }
}
