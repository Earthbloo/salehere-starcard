import SwiftUI

// MARK: - สำรับสมุดสแครปบุ๊ก — ชิ้นส่วนร่วม
//
// แปลงจาก canvas "Pink Scrapbook Widgets" (30 ก.ย. 2569) — เทมเพลต media kit สีชมพูที่เจ้าของการ์ดส่งมา
// เอา *ภาษาภาพ* มา (กระดาษชมพู คลิปหนีบ เทปวาชิ โพลารอยด์ ใบเสร็จ) แต่เนื้อหาเป็นข้อมูลตามหมวดของเรา
//
// # กติกาของทั้งสำรับ
//
// - **จบในรูปที่ export** — ไม่มีเคอร์เซอร์ โฟลเดอร์ แท็บ หรือจุดพิมพ์อยู่ ที่ชวนให้กด (คนส่วนใหญ่ export รูป)
//   อยากให้ไปต่อ = QR ไม่ใช่ปุ่ม
// - **ฟอนต์ไทยไม่มีหัวเท่านั้น** — ดำหนัก (Noto Sans Thai Black) + เสียงชมพู (มิตร) สองเสียงเท่านั้น
//   ตามท่าพาดหัวสองฟอนต์ของเทมเพลต ("rachel **leighton**")
// - **โทนตามธีมของการ์ด** (ผู้ใช้ 1 ต.ค. 2569: "ต้องปรับโทนสีได้ตาม THEME โทนมืดโทนสว่าง")
//   สีของแผ่นกับสีเน้นทั้งหมดมาจาก `ScrapTone` — เฉดจากสีเน้นของธีม · ความมืด/สว่างจากหมึกของการ์ด ·
//   การ์ดคู่สีได้แค่สองสีของคู่ · **ของที่เป็นวัตถุ** (โพลารอยด์ ใบเสร็จ บัตร ป้าย กระดาษโน้ต) ยังเป็นกระดาษจริง
//   สีอ่อนเหมือนเดิมทุกโทน — มันคือของที่วางบนแผ่น ไม่ใช่ตัวแผ่น
//   เจ้าของเลือก "ไม่มีพื้น" แล้วตัวหนังสือที่ลอยบนการ์ดตรง ๆ พลิกตามหมึกของการ์ด

/// สีของวัตถุ — ไม่เปลี่ยนตามธีม (กระดาษจริงสีอ่อน หมึกเข้มบนกระดาษ)
enum Scrap {
    /// หมึกบนกระดาษ · หมึกรอง · ป้ายกำกับ
    static let ink = Color(scrapHex: 0x141414)
    static let soft = Color(scrapHex: 0x7A5664)
    static let label = Color(scrapHex: 0xA86A84)
    /// กระดาษครีม (ใบเสร็จ · บัตร · ป้าย) · เหลืองเนย (แฟ้ม · ป้าย) · เส้นสมุด · เส้นขอบกระดาษ
    static let cream = Color(scrapHex: 0xFFFDF8)
    static let butter = Color(scrapHex: 0xF2DB95)
    static let butterLight = Color(scrapHex: 0xF8E7B0)
    static let note = Color(scrapHex: 0xFFF2B5)
    static let noteInk = Color(scrapHex: 0x5B4520)
    static let rule = Color(scrapHex: 0xC8D6E8)
    static let margin = Color(scrapHex: 0xF09AB0)

    /// เสียงดำหนัก — พาดหัว ชื่อ ตัวเลข
    static func heavy(_ size: CGFloat, color: Color = ink) -> TextSlotStyle {
        .init(size: size, weight: .black, color: color)
    }
    /// เสียงที่สอง — คำที่สองของพาดหัว · ชื่อตัวเขียน · ลายมือ
    static func voice(_ size: CGFloat, color: Color) -> TextSlotStyle {
        .init(size: size, weight: .regular, face: .mitr, color: color)
    }
}

/// สีของสำรับที่ขึ้นกับธีม — **คิดครั้งเดียวต่อธีม** แล้วส่งลงทาง environment (`\.scrapTone`)
///
/// ตั้งชื่อตาม *ที่ที่สีไปนั่ง* ไม่ใช่ตามชื่อสี: `accent` คือเสียงชมพูบนแผ่น · `paperAccent` คือเสียงเดียวกัน
/// บนกระดาษขาวของวัตถุ — โทนมืดต้องแยกสองตัวนี้ เพราะชมพูสว่างที่อ่านออกบนแผ่นมืด จะจางหายบนกระดาษขาว
struct ScrapTone {
    /// แผ่นมืดไหม
    let dark: Bool
    /// แผ่น · จุดเนื้อกระดาษ (สีกับความทึบ)
    let paper: Color
    let speck: Color
    let speckAlpha: Double
    /// ตัวหนังสือที่นั่งบนแผ่นตรง ๆ · ตัวรอง
    let ink: Color
    let soft: Color
    /// เสียงที่สองบนแผ่น · ตัวเลขเด่นบนแผ่น
    let accent: Color
    let strong: Color
    /// เสียงที่สอง · ตัวเลขเด่น — บนกระดาษขาวของวัตถุ (อ่านออกบนพื้นสว่างเสมอ)
    let paperAccent: Color
    let paperStrong: Color
    /// แถบหัวข้อ (ตัวหนังสือเข้มวางบนนี้ได้เสมอ) · ชมพูกลางของป้าย/กล่อง · พื้นอ่อนในวัตถุ (ราง แถบหัวหน้าต่าง)
    let band: Color
    let mid: Color
    let blush: Color
    /// เงาของของที่ลอยบนแผ่น — เงาดำบนกระดาษสีอ่านเป็นคราบ จึงอาบเฉดของแผ่น
    let shade: Color

    init(_ theme: CardTheme) {
        if let duo = theme.duoColors {
            // การ์ดคู่สี — สองสีของคู่เท่านั้น ใส่สีที่สามเมื่อไหร่งานสองสีพังตรงนั้น
            let bg = duo.bg, fg = duo.ink
            let light = theme.duoLight ?? fg, deep = theme.duoDark ?? bg
            dark = RGB(bg).luminance < RGB(fg).luminance
            paper = bg.mixed(with: fg, by: 0.07)
            speck = fg
            speckAlpha = 0.08
            ink = fg
            soft = fg.mixed(with: bg, by: 0.35)
            accent = fg
            strong = fg
            paperAccent = deep
            paperStrong = deep
            band = light.mixed(with: deep, by: 0.18)
            mid = light.mixed(with: deep, by: 0.32)
            blush = light.mixed(with: deep, by: 0.08)
            shade = deep
            return
        }
        // เฉดจากสีเน้นของธีม · ความสดถ่วงตามสีเน้น (ธีมเทา ๆ ได้แผ่นเทา ๆ ไม่ใช่ชมพูหวาน)
        var h: CGFloat = 0, sat: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(theme.rawAccent).getHue(&h, saturation: &sat, brightness: &b, alpha: &a)
        let k = min(1.2, max(0.3, Double(sat) / 0.49))
        func c(_ s: Double, _ v: Double) -> Color { Color(hue: Double(h), saturation: min(1, s * k), brightness: v) }

        dark = !theme.activeInk.isLight
        paperAccent = c(0.49, 0.86)
        paperStrong = c(0.67, 0.76)
        blush = c(0.10, 0.985)
        if dark {
            // สว่างกว่าพื้นการ์ดกลางคืนหนึ่งขั้นเสมอ — มืดเท่ากันแล้วขอบแผ่นหายไปกับการ์ด อ่านเป็นของลอย ๆ
            paper = c(0.42, 0.31)
            speck = .white
            speckAlpha = 0.06
            ink = Color(hue: Double(h), saturation: 0.04, brightness: 0.98)
            soft = c(0.16, 0.80)
            accent = c(0.40, 0.98)
            strong = c(0.45, 1.0)
            band = c(0.30, 0.95)
            mid = c(0.36, 0.88)
            shade = .black
        } else {
            paper = c(0.16, 0.965)
            speck = c(0.58, 0.75)
            speckAlpha = 0.10
            ink = Scrap.ink
            soft = c(0.30, 0.48)
            accent = c(0.49, 0.89)
            strong = c(0.67, 0.79)
            band = c(0.28, 0.96)
            mid = c(0.33, 0.94)
            shade = c(0.71, 0.55)
        }
    }

    /// ค่าตั้งต้นเมื่อไม่มีใครส่งโทนลงมา (พรีวิวใน Xcode) — โทนชมพูสว่างของต้นฉบับ
    static let fallback = ScrapTone(CardTheme())
}

private struct ScrapToneKey: EnvironmentKey {
    static let defaultValue = ScrapTone.fallback
}

extension EnvironmentValues {
    var scrapTone: ScrapTone {
        get { self[ScrapToneKey.self] }
        set { self[ScrapToneKey.self] = newValue }
    }
}

extension Color {
    init(scrapHex hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// หน้าตาของแผ่นตามพื้นผิวที่เจ้าของเลือก — มีพื้น = แผ่นตามโทน · กระจก/ไม่มีพื้น = ไม่วาดแผ่น
/// แล้วตัวหนังสือที่ลอยบนการ์ดตรง ๆ ใช้หมึกของการ์ด (ของที่มีกระดาษของตัวเองยังเป็นสีเดิม)
struct ScrapSkin {
    let papered: Bool
    let ink: Color
    let soft: Color

    init(_ surface: WidgetSurface, ink: InkStyle, tone: ScrapTone) {
        papered = surface == .glass
        self.ink = papered ? tone.ink : ink.text(0.95)
        soft = papered ? tone.soft : ink.text(0.6)
    }
}

// MARK: - กระดาษ

/// กระดาษชมพูมีเนื้อ — จุดขาวถี่ + จุดชมพูเข้มห่าง (ต้นฉบับคือกระดาษสาที่ถูกถ่ายมา ไม่ใช่สีเรียบ)
struct ScrapPaper: View {
    @Environment(\.scrapTone) private var tone

    var body: some View {
        let tone = tone
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(tone.paper))
            var light = Path(), dark = Path()
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    light.addEllipse(in: CGRect(x: x, y: y, width: 1, height: 1))
                    x += 3.5
                }
                y += 3.5
            }
            y = 2.5
            while y < size.height {
                var x: CGFloat = 1.5
                while x < size.width {
                    dark.addEllipse(in: CGRect(x: x, y: y, width: 1, height: 1))
                    x += 5.5
                }
                y += 5.5
            }
            ctx.fill(light, with: .color(.white.opacity(tone.dark ? 0.05 : 0.4)))
            ctx.fill(dark, with: .color(tone.speck.opacity(tone.speckAlpha)))
        }
        .allowsHitTesting(false)
    }
}

/// แผ่นของใบ — กระดาษตามโทนมุมมน หรือว่างเปล่าเมื่อเจ้าของถอดพื้น
struct ScrapSheet<Content: View>: View {
    @Environment(\.scrapTone) private var tone
    let skin: ScrapSkin
    let box: CGSize
    var radius: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack(alignment: .topLeading) {
            if skin.papered { ScrapPaper() }
            content()
        }
        .frame(width: box.width, height: box.height, alignment: .topLeading)
        .clipShape(shape)
        // แผ่นมืดบนการ์ดมืด — เส้นขอบบางช่วยให้ขอบแผ่นยังอ่านออก
        .overlay(shape.strokeBorder(.white.opacity(skin.papered && tone.dark ? 0.1 : 0), lineWidth: 0.8))
    }
}

// MARK: - ของตกแต่ง (วาดด้วยโค้ด — เปลี่ยนสีได้ คมทุกขนาดตอน export)

/// หัวใจ
struct ScrapHeart: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY + h * 0.92))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.33),
                   control1: CGPoint(x: r.minX + w * 0.3, y: r.minY + h * 0.72),
                   control2: CGPoint(x: r.minX, y: r.minY + h * 0.55))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.2),
                   control1: CGPoint(x: r.minX, y: r.minY + h * 0.02),
                   control2: CGPoint(x: r.minX + w * 0.4, y: r.minY - h * 0.02))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.33),
                   control1: CGPoint(x: r.minX + w * 0.6, y: r.minY - h * 0.02),
                   control2: CGPoint(x: r.maxX, y: r.minY + h * 0.02))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.92),
                   control1: CGPoint(x: r.maxX, y: r.minY + h * 0.55),
                   control2: CGPoint(x: r.minX + w * 0.7, y: r.minY + h * 0.72))
        p.closeSubpath()
        return p
    }
}

/// ประกายสี่แฉกลอยตัว — ใช้ `PicnicSparkle` ตัวเดียวกับสำรับปิกนิก
struct ScrapSpark: View {
    var size: CGFloat = 14
    var color: Color = .white

    var body: some View {
        PicnicSparkle().fill(color).frame(width: size, height: size)
    }
}

/// โบว์ — สองห่วง สองหาง ปมกลาง
struct ScrapBow: View {
    @Environment(\.scrapTone) private var tone
    var width: CGFloat = 30

    var body: some View {
        let color = tone.band, edge = tone.paperAccent
        Canvas { ctx, size in
            let s = size.width / 64
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            var left = Path()
            left.move(to: pt(32, 20))
            left.addCurve(to: pt(6, 16), control1: pt(24, 6), control2: pt(6, 4))
            left.addCurve(to: pt(32, 20), control1: pt(6, 28), control2: pt(24, 28))
            var right = Path()
            right.move(to: pt(32, 20))
            right.addCurve(to: pt(58, 16), control1: pt(40, 6), control2: pt(58, 4))
            right.addCurve(to: pt(32, 20), control1: pt(58, 28), control2: pt(40, 28))
            var tails = Path()
            tails.move(to: pt(29, 22)); tails.addLine(to: pt(19, 44)); tails.addLine(to: pt(26, 41))
            tails.addLine(to: pt(30, 47)); tails.closeSubpath()
            tails.move(to: pt(35, 22)); tails.addLine(to: pt(45, 44)); tails.addLine(to: pt(38, 41))
            tails.addLine(to: pt(34, 47)); tails.closeSubpath()
            ctx.fill(tails, with: .color(color.mix(with: edge, by: 0.3)))
            for loop in [left, right] {
                ctx.fill(loop, with: .color(color))
                ctx.stroke(loop, with: .color(edge), lineWidth: 1.6 * s)
            }
            ctx.fill(Path(ellipseIn: CGRect(x: 27 * s, y: 16 * s, width: 10 * s, height: 10 * s)),
                     with: .color(edge))
        }
        .frame(width: width, height: width * 0.75)
    }
}

/// คลิปหนีบกระดาษดำ — ลวดเงินสองเส้น + ตัวหนีบคางหมู
struct BinderClip: View {
    var width: CGFloat = 34

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 68
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            var wire = Path()
            wire.move(to: pt(20, 36)); wire.addLine(to: pt(25, 8))
            wire.addQuadCurve(to: pt(43, 8), control: pt(34, 1)); wire.addLine(to: pt(48, 36))
            ctx.stroke(wire, with: .color(Color(scrapHex: 0xC3C7CF)),
                       style: StrokeStyle(lineWidth: 3.2 * s, lineCap: .round))
            var inner = Path()
            inner.move(to: pt(26, 36)); inner.addLine(to: pt(29, 14))
            inner.addQuadCurve(to: pt(39, 14), control: pt(34, 10)); inner.addLine(to: pt(42, 36))
            ctx.stroke(inner, with: .color(Color(scrapHex: 0x9EA3AC)),
                       style: StrokeStyle(lineWidth: 2.4 * s, lineCap: .round))
            var body = Path()
            body.move(to: pt(8, 34)); body.addLine(to: pt(60, 34))
            body.addLine(to: pt(56, 62)); body.addLine(to: pt(12, 62)); body.closeSubpath()
            ctx.fill(body, with: .color(Color(scrapHex: 0x161616)))
            var shine = Path()
            shine.move(to: pt(12, 38)); shine.addLine(to: pt(56, 38))
            ctx.stroke(shine, with: .color(Color(scrapHex: 0x4A4A4A)), lineWidth: 2 * s)
        }
        .frame(width: width, height: width * 66 / 68)
        .shadow(color: .black.opacity(0.18), radius: 2, y: 1.5)
    }
}

/// คลิปหนีบกระดาษเงิน
struct PaperClip: Shape {
    func path(in r: CGRect) -> Path {
        let s = r.width / 30
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * s, y: r.minY + y * s) }
        var p = Path()
        p.move(to: pt(20, 22))
        p.addLine(to: pt(20, 62))
        p.addArc(center: pt(13, 62), radius: 7 * s, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: pt(6, 14))
        p.addArc(center: pt(16, 14), radius: 10 * s, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: pt(26, 58))
        return p
    }
}

/// เทปวาชิ — ลายทางขาวชมพูโปร่ง
struct WashiTape: View {
    @Environment(\.scrapTone) private var tone
    var width: CGFloat = 55
    var height: CGFloat = 15
    var tint: Color = .white

    var body: some View {
        let stripe = tone.band
        Canvas { ctx, size in
            var x: CGFloat = 0
            var odd = false
            while x < size.width {
                ctx.fill(Path(CGRect(x: x, y: 0, width: 4.5, height: size.height)),
                         with: .color(odd ? stripe.opacity(0.62) : tint.opacity(0.72)))
                x += 4.5
                odd.toggle()
            }
        }
        .frame(width: width, height: height)
        .shadow(color: tone.shade.opacity(0.14), radius: 1, y: 0.5)
    }
}

/// บาร์โค้ด — แท่งกว้างแคบไม่ซ้ำจังหวะ (จังหวะเดียวซ้ำทั้งแถวอ่านเป็นลายผ้า ไม่ใช่บาร์โค้ด)
struct ScrapBarcode: View {
    var color: Color = Scrap.ink
    private static let bars: [CGFloat] = [3, 1, 1, 2, 4, 1, 2, 3, 1, 1, 3, 2, 1, 4, 1, 2, 2, 1, 3, 1, 1, 2, 4, 1, 2, 1, 3]

    var body: some View {
        Canvas { ctx, size in
            let unit = size.width / Self.bars.reduce(0, +)
            var x: CGFloat = 0
            for (i, b) in Self.bars.enumerated() {
                if i.isMultiple(of: 2) {
                    ctx.fill(Path(CGRect(x: x, y: 0, width: b * unit, height: size.height)), with: .color(color))
                }
                x += b * unit
            }
        }
    }
}

// MARK: - ตัวหนังสือ

extension View {
    /// ขอบขาวรอบตัวหนังสือ — ตัวเขียนชมพูที่ทับรูป/กระดาษต้องแยกตัวจากพื้นได้ทุกพื้น
    func scrapOutline(_ w: CGFloat = 1.5, color: Color = .white) -> some View {
        shadow(color: color, radius: 0, x: w, y: 0)
            .shadow(color: color, radius: 0, x: -w, y: 0)
            .shadow(color: color, radius: 0, x: 0, y: w)
            .shadow(color: color, radius: 0, x: 0, y: -w)
    }
}

/// พาดหัวกล่องคำ — คำแรกดำหนักบนแถบขาว (หรือขาวบนแถบดำ) · คำที่สองเสียงชมพูบนแถบชมพู
///
/// สองคำเป็นช่องข้อความอิสระของชิ้น (`.note` ช่อง `first`/`second`) — ค่าตั้งต้นมากับดีไซน์
struct ScrapLabel: View {
    @Environment(\.widgetID) private var wid
    @Environment(\.scrapTone) private var tone
    let first: String
    let second: String
    var size: CGFloat = 24
    /// true = แถบดำตัวขาว (ท่า "analytics" ของต้นฉบับ)
    var dark = false
    var slots: (Int, Int) = (1, 2)
    /// แถบที่สองลงต่ำกว่าแถวหรือขึ้นบรรทัดใหม่
    var stacked = false

    var body: some View {
        let a = Profile.me.note(wid, slots.0, preset: first)
        let b = Profile.me.note(wid, slots.1, preset: second)
        let layout = stacked ? AnyLayout(VStackLayout(alignment: .leading, spacing: -size * 0.12))
                             : AnyLayout(HStackLayout(alignment: .bottom, spacing: -2))
        layout {
            Text(a)
                .lineLimit(1).fixedSize()
                .editableText(.note, index: slots.0, widget: wid, preset: first, hint: "คำแรก",
                              .init(size: size, weight: .black, color: dark ? .white : Scrap.ink))
                .padding(.horizontal, size * 0.3)
                .padding(.bottom, size * 0.08)
                .background(dark ? Scrap.ink : Color.white)
                .rotationEffect(.degrees(-2))
                .shadow(color: tone.shade.opacity(dark ? 0 : 0.12), radius: 3, y: 1.5)
            Text(b)
                .lineLimit(1).fixedSize()
                .editableText(.note, index: slots.1, widget: wid, preset: second, hint: "คำที่สอง",
                              Scrap.voice(size * 0.86, color: Scrap.ink))
                .padding(.horizontal, size * 0.34)
                .padding(.vertical, size * 0.02)
                .background(tone.band)
                .rotationEffect(.degrees(1.5))
                .offset(x: stacked ? size * 1.3 : 0, y: stacked ? 0 : size * 0.22)
        }
    }
}

// MARK: - ของที่ถือรูป

/// โพลารอยด์ — กรอบขาว ขอบล่างหนา · คำใต้รูปเป็นช่องอิสระของชิ้น (ไม่ใช่ข้อมูลสายงาน:
/// รูปไม่ได้ผูกกับสาย คำใต้รูปจึงต้องเป็นของที่เจ้าของพิมพ์เอง)
struct ScrapPolaroid: View {
    @Environment(\.widgetID) private var wid
    @Environment(\.scrapTone) private var tone
    let slot: Int
    let width: CGFloat
    let height: CGFloat
    var caption: (index: Int, preset: String)? = nil

    var body: some View {
        let pad: CGFloat = width * 0.065
        let foot: CGFloat = caption == nil ? pad : height * 0.2
        VStack(spacing: 0) {
            Color.clear
                .overlay { WidgetPhoto(index: slot).aspectRatio(contentMode: .fill) }
                .clipped()
                .photoSlot(slot)
            if let caption {
                Text(Profile.me.note(wid, caption.index, preset: caption.preset))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .editableText(.note, index: caption.index, widget: wid, preset: caption.preset,
                                  hint: "คำใต้รูป", Scrap.voice(width * 0.11, color: tone.paperStrong))
                    .frame(height: foot)
            }
        }
        .padding([.top, .horizontal], pad)
        .padding(.bottom, caption == nil ? pad : 0)
        .frame(width: width, height: height)
        .background(Color.white)
        .shadow(color: tone.shade.opacity(0.2), radius: 6, y: 5)
    }
}

/// ป้ายห้อยทรงตัดมุมซ้าย (ป้ายราคา/กระเป๋าเดินทาง)
struct TagShape: Shape {
    var cut: CGFloat = 16
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + cut, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + cut, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - r.height * 0.3))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.3))
        p.closeSubpath()
        return p
    }
}

/// ขอบหยักฟันเลื่อยใต้ใบเสร็จ
struct ZigzagEdge: Shape {
    var tooth: CGFloat = 10
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        let n = max(1, Int((r.width / tooth).rounded()))
        let step = r.width / CGFloat(n)
        var x = r.maxX
        for _ in 0..<n {
            p.addLine(to: CGPoint(x: x - step / 2, y: r.maxY))
            p.addLine(to: CGPoint(x: x - step, y: r.minY))
            x -= step
        }
        p.closeSubpath()
        return p
    }
}

/// จุดสามสีบนแถบหัวหน้าต่าง — **สีของโทน** ไม่ใช่แดงเหลืองเขียวของ macOS (มันคือของตกแต่ง ไม่ใช่ปุ่ม)
struct ScrapWindowDots: View {
    @Environment(\.scrapTone) private var tone

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(tone.paperAccent)
            Circle().fill(tone.mid)
            Circle().fill(tone.band)
        }
        .frame(width: 26, height: 6)
    }
}

/// โลโก้ช่องทางในกล่องชมพูอ่อน
struct ScrapSocialIcon: View {
    @Environment(\.scrapTone) private var tone
    let type: SocialType
    var size: CGFloat = 19

    var body: some View {
        let g = type.glyph(night: false)
        Image(g.name)
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: size * (g.badge ? 0.62 : 0.66), height: size * (g.badge ? 0.62 : 0.7))
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(tone.blush))
    }
}
