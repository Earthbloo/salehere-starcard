import SwiftUI

// MARK: - สำรับผ้าปิกนิก
//
// แปลงตรงจากแผ่นตัวอย่างชุดที่สองที่เจ้าของการ์ดส่งมา (29 ก.ย. 2569) — เรื่องเดียวกับสำรับหน้าต่าง
// (สถิติช่อง · ปกพอร์ต) แต่แต่งตัวคนละชุด: **ผ้าตารางฟ้า กระดาษครีม ขอบหยักแดง ตัวเซริฟแคบสีเลือดหมู**
//
// # ตัวอักษร
//
// ต้นฉบับใช้เซริฟ Didone แบบแคบ (condensed) ซึ่งไม่มีทั้งในแอปและใน iOS — ที่นี่ใช้เซริฟของแอป
// (`CardFont.serif` = New York ตัวเดียวกับสำรับหน้าต่าง) แล้ว **บีบแนวนอน** ให้ได้สัดส่วนของต้นฉบับ
// (วัดแล้วใน lab: New York หนาบีบเหลือ ~0.45–0.7 อ่านเป็นเซริฟแคบได้ใกล้ต้นฉบับที่สุด
// ใกล้กว่า Didot/Bodoni 72 ที่บีบเท่ากัน) · ค่าบีบคิดจากขนาดของดีไซน์ครั้งเดียว — เจ้าของการ์ด
// ขยายตัวอักษรเองแล้วคำโตขึ้นทั้งกว้างและสูง ไม่ใช่ถูกบีบแคบลงเรื่อย ๆ
//
// # สองใบใช้สีชุดเดียวกัน (`Picnic`)
//
// สีทั้งชุดเป็นของ *ดีไซน์* ไม่ใช่ของธีม — ผ้าตารางฟ้ากับแดงเลือดหมูคือตัวตนของแผ่น
// (เหมือนหน้าต่าง macOS ที่ไม่เปลี่ยนสีตามวอลเปเปอร์) วางบนการ์ดสีไหนก็อ่านเป็นสติกเกอร์ชิ้นเดียวกัน

/// สีของสำรับ — ดูดจากแผ่นต้นฉบับ
enum Picnic {
    /// กระดาษครีมหัวแผ่น (#FAF1E4) · ครีมในการ์ดข้อมูล (#F9F1E6)
    static let paper = Color(hex: 0xFAF1E4)
    static let card = Color(hex: 0xF9F1E6)
    /// แดงเลือดหมูของตัวอักษร (#9E1F1B) · แดงสดของเส้นหยัก (#B32A1E) · เส้นขอบนอก (#962A1E)
    static let red = Color(hex: 0x9C1E1A)
    static let wave = Color(hex: 0xB42A1F)
    static let rim = Color(hex: 0x962A1E)
    /// ตัวอักษรเข้ม (ชื่อ · ชื่อแพลตฟอร์ม · ป้ายรอง)
    static let ink = Color(hex: 0x24211E)
    static let inkSoft = Color(hex: 0x3B3733)
    /// ฟ้าพื้นแถบหัวของป้ายช่องทาง (#C6DAEE) และเส้นขอบของมัน
    static let sky = Color(hex: 0xC7DBEF)
    static let skyRim = Color(hex: 0xAFC8E3)
    /// ผ้าตาราง — ครีม · เส้นเดี่ยว · จุดที่สองเส้นทับกัน (#F6F0E6 · #BCD2E8 · #93B6DA)
    static let clothCream = Color(hex: 0xF7F1E7)
    static let clothStripe = Color(hex: 0xBAD0E7)
    static let clothCross = Color(hex: 0x93B5DA)
    /// ตัวอักษรบนผ้า (ฐานของป้ายช่องทาง)
    static let footInk = Color(hex: 0x3E4953)
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - ชิ้นส่วนร่วม

/// ผ้าตาราง (gingham) — ครีม + แถบฟ้าสองทิศ จุดตัดเข้มขึ้น · ขอบแถบนุ่มแบบลายผ้าจริง ไม่ใช่กริดคม
struct GinghamCloth: View {
    /// ความกว้างของหนึ่งช่อง (หน่วยออกแบบ)
    var cell: CGFloat = 20

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Picnic.clothCream))
            let cols = Int(ceil(size.width / cell)) + 1
            let rows = Int(ceil(size.height / cell)) + 1
            // แถบตั้ง + แถบนอน (ช่องคู่) → จุดตัดทับอีกชั้น
            for i in stride(from: 0, to: cols, by: 2) {
                ctx.fill(Path(CGRect(x: CGFloat(i) * cell, y: 0, width: cell, height: size.height)),
                         with: .color(Picnic.clothStripe))
            }
            for j in stride(from: 0, to: rows, by: 2) {
                ctx.fill(Path(CGRect(x: 0, y: CGFloat(j) * cell, width: size.width, height: cell)),
                         with: .color(Picnic.clothStripe))
            }
            for i in stride(from: 0, to: cols, by: 2) {
                for j in stride(from: 0, to: rows, by: 2) {
                    ctx.fill(Path(CGRect(x: CGFloat(i) * cell, y: CGFloat(j) * cell,
                                         width: cell, height: cell)),
                             with: .color(Picnic.clothCross))
                }
            }
            // เส้นทอเฉียงจาง ๆ — ผ้าจริงมีเนื้อ แผ่นสีเรียบล้วนอ่านเป็นตารางของโปรแกรม
            var weave = Path()
            let step = cell / 5
            var x = -size.height
            while x < size.width {
                weave.move(to: CGPoint(x: x, y: size.height))
                weave.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += step
            }
            ctx.stroke(weave, with: .color(.white.opacity(0.10)), lineWidth: 0.35)
        }
        // ขอบแถบนุ่มนิดเดียว — ต้นฉบับเป็นผ้าที่ถ่ายมา ไม่ใช่เวกเตอร์
        .blur(radius: 0.35)
        .overlay(EdGrain(count: 220, opacity: 0.05, tint: .white))
        .allowsHitTesting(false)
    }
}

/// เส้นหยัก (คลื่น) ที่วิ่งรอบสี่เหลี่ยมมุมมน — ขอบลูกไม้ของต้นฉบับ
///
/// ความยาวคลื่นถูกปัดให้ **ลงตัวพอดีรอบ** เสมอ ไม่งั้นจุดเริ่มกับจุดจบของเส้นจะไม่ต่อกัน
/// (เห็นเป็นรอยสะดุดที่มุมบนซ้าย) · ขนาดกรอบเปลี่ยน = จำนวนคลื่นเปลี่ยน ไม่ใช่คลื่นถูกยืด
struct WavyFrame: Shape {
    var radius: CGFloat
    var amplitude: CGFloat = 2.3
    var wavelength: CGFloat = 11.7

    func path(in r: CGRect) -> Path {
        let R = min(radius, r.width / 2, r.height / 2)
        let sw = max(0, r.width - 2 * R), sh = max(0, r.height - 2 * R)
        let arc = .pi * R / 2
        let total = 2 * sw + 2 * sh + 4 * arc
        guard total > 1 else { return Path(r) }
        let n = max(4, (total / wavelength).rounded())
        let lambda = total / n

        // จุดบนเส้นรอบ + ทิศตั้งฉากชี้ออก ที่ระยะ s (เริ่มหลังมุมบนซ้าย วนตามเข็ม)
        func point(_ s: CGFloat) -> (CGPoint, CGVector) {
            var s = s.truncatingRemainder(dividingBy: total)
            let segs: [(len: CGFloat, f: (CGFloat) -> (CGPoint, CGVector))] = [
                (sw, { t in (CGPoint(x: r.minX + R + t, y: r.minY), CGVector(dx: 0, dy: -1)) }),
                (arc, { t in
                    let a = -CGFloat.pi / 2 + t / max(R, 0.001)
                    return (CGPoint(x: r.maxX - R + R * cos(a), y: r.minY + R + R * sin(a)),
                            CGVector(dx: cos(a), dy: sin(a))) }),
                (sh, { t in (CGPoint(x: r.maxX, y: r.minY + R + t), CGVector(dx: 1, dy: 0)) }),
                (arc, { t in
                    let a = t / max(R, 0.001)
                    return (CGPoint(x: r.maxX - R + R * cos(a), y: r.maxY - R + R * sin(a)),
                            CGVector(dx: cos(a), dy: sin(a))) }),
                (sw, { t in (CGPoint(x: r.maxX - R - t, y: r.maxY), CGVector(dx: 0, dy: 1)) }),
                (arc, { t in
                    let a = CGFloat.pi / 2 + t / max(R, 0.001)
                    return (CGPoint(x: r.minX + R + R * cos(a), y: r.maxY - R + R * sin(a)),
                            CGVector(dx: cos(a), dy: sin(a))) }),
                (sh, { t in (CGPoint(x: r.minX, y: r.maxY - R - t), CGVector(dx: -1, dy: 0)) }),
                (arc, { t in
                    let a = CGFloat.pi + t / max(R, 0.001)
                    return (CGPoint(x: r.minX + R + R * cos(a), y: r.minY + R + R * sin(a)),
                            CGVector(dx: cos(a), dy: sin(a))) }),
            ]
            for seg in segs {
                if s <= seg.len { return seg.f(s) }
                s -= seg.len
            }
            return segs[0].f(0)
        }

        var p = Path()
        let steps = Int(total / 0.8)
        for k in 0...steps {
            let s = total * CGFloat(k) / CGFloat(steps)
            let (pt, nrm) = point(s)
            let off = amplitude * sin(2 * .pi * s / lambda)
            let q = CGPoint(x: pt.x + nrm.dx * off, y: pt.y + nrm.dy * off)
            if k == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        p.closeSubpath()
        return p
    }
}

/// ประกายสี่แฉกกลางเส้นใต้ชื่อ
struct PicnicSparkle: Shape {
    func path(in r: CGRect) -> Path {
        let c = CGPoint(x: r.midX, y: r.midY)
        let w = r.width / 2, h = r.height / 2, k: CGFloat = 0.16
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - h))
        p.addQuadCurve(to: CGPoint(x: c.x + w, y: c.y), control: CGPoint(x: c.x + w * k, y: c.y - h * k))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + h), control: CGPoint(x: c.x + w * k, y: c.y + h * k))
        p.addQuadCurve(to: CGPoint(x: c.x - w, y: c.y), control: CGPoint(x: c.x - w * k, y: c.y + h * k))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - h), control: CGPoint(x: c.x - w * k, y: c.y - h * k))
        p.closeSubpath()
        return p
    }
}

/// เซริฟแคบ — ขนาดและค่าบีบของคำหนึ่งคำ
///
/// `capHeight` คือความสูงตัวพิมพ์ใหญ่ที่ดีไซน์ต้องการ · `width` คือความกว้างสูงสุดของทั้งคำ
/// คืนขนาดฟอนต์ (pt) และตัวคูณแนวนอน
///
/// `condense` คือความแคบ *ของฟอนต์* — บีบเสมอแม้คำจะสั้นพอดีช่องอยู่แล้ว ("8.1%" ในช่องกว้าง
/// ต้องยังเป็นตัวแคบเหมือน "125,000" ข้าง ๆ) · คำยาวที่ล้นช่องถูกบีบเพิ่มจนพอดี
enum Condensed {
    static func fit(_ text: String, capHeight: CGFloat, width: CGFloat,
                    weight: Font.Weight = .black, face: CardFont = .serif,
                    tracking: CGFloat = 0, condense: CGFloat = 0.72) -> (size: CGFloat, squeeze: CGFloat) {
        let probe = face.uiFont(100, weight)
        let size = capHeight / max(probe.capHeight / 100, 0.1)
        let ui = face.uiFont(size, weight)
        let natural = (text as NSString).size(withAttributes: [.font: ui, .kern: tracking]).width
        return (size, min(condense, width / max(natural, 1)))
    }
}

// MARK: - 01 ป้ายช่องทางผ้าปิกนิก (SOCIAL CHANNEL)

/// ค่าคงที่ของผัง — วัดจากแผ่นต้นฉบับ 974 × 248 แล้วย่อเป็นกว้าง 504 (× 0.5175)
enum SG {
    static let w: CGFloat = 504
    static let h: CGFloat = 128
    static let radius: CGFloat = 13.5
    /// แถบหัว (พาดหัว) · การ์ดข้อมูล · ฐานผ้าตาราง
    static let head: CGFloat = 31
    static let foot: CGFloat = 21.5
    /// ระยะขอบข้างของการ์ด และช่องไฟระหว่างการ์ด (มีเส้นแดงตั้งพาดกลาง)
    static let side: CGFloat = 7.2
    static let gap: CGFloat = 11.4
    /// ส่วนแบ่งความกว้างสามการ์ด — ต้นฉบับไม่เท่ากัน (35.5 · 33 · 31.5) เพราะการ์ดแรกแบกโลโก้
    static let share: [CGFloat] = [0.355, 0.331, 0.314]
    static let cardRadius: CGFloat = 7.2
}

struct SocialGinghamWidget: View {
    @Environment(\.widgetID) private var wid
    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetTextStyle) private var tune
    let theme: CardTheme
    let size: CGSize

    /// ช่องข้อความเดียวกับหน้าต่างช่องทาง (1 = พาดหัว · 2 = บทบาทของช่อง) — สลับแบบไปมาแล้วคำที่พิมพ์ไว้ตามไปด้วย
    private static let titlePreset = "SOCIAL CHANNEL"
    private static let rolePreset = "ช่องทางรีวิว"

    var body: some View {
        PosterSheet(design: CGSize(width: SG.w, height: SG.h), frame: size) { box in
            sheet(box)
        }
    }

    private func sheet(_ box: CGSize) -> some View {
        let shape = RoundedRectangle(cornerRadius: SG.radius, style: .continuous)
        return ZStack(alignment: .top) {
            Picnic.sky
            EdGrain(count: 360, opacity: 0.05, tint: .white)

            // ฐานผ้าตาราง — แถบล่างสุด การ์ดสามใบนั่งบนขอบบนของมันพอดี
            GinghamCloth(cell: 8.4)
                .frame(height: SG.foot + 1)
                .frame(maxHeight: .infinity, alignment: .bottom)

            VStack(spacing: 0) {
                title(box.width)
                    .frame(height: SG.head)
                if let s = WindowChannel.current(wid) {
                    cards(s, w: box.width)
                        .frame(maxHeight: .infinity)
                    footer(s)
                        .frame(height: SG.foot)
                } else {
                    Text("ยังไม่มีช่องทาง")
                        .font(.sh(11, .semibold))
                        .foregroundStyle(Picnic.inkSoft)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(width: box.width, height: box.height)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Picnic.skyRim, lineWidth: 0.9))
    }

    // MARK: พาดหัว — เส้น · SOCIAL CHANNEL · เส้น

    private func title(_ w: CGFloat) -> some View {
        let word = Profile.me.note(wid, 1, preset: Self.titlePreset).uppercased()
        let fit = Condensed.fit(word, capHeight: 15.5, width: w * 0.5, weight: .semibold, condense: 0.8)
        return HStack(spacing: 8) {
            Rectangle().fill(Picnic.red).frame(width: 28, height: 0.9)
            Text(word)
                .lineLimit(1)
                .fixedSize()
                .editableText(.note, index: 1, widget: wid, preset: Self.titlePreset, hint: "พาดหัว",
                              .init(size: fit.size, weight: .semibold, face: .serif,
                                    color: Picnic.red, align: .center, uppercase: true))
                .scaleEffect(x: fit.squeeze, y: 1)
                .frame(width: widthOf(word, fit.size, .semibold, for: 1) * fit.squeeze)
            Rectangle().fill(Picnic.red).frame(width: 28, height: 0.9)
        }
        .padding(.top, 3)
        .scrubSlide(scrub.d, travel: -w * 0.18, fade: 0.84, eased: false)
    }

    /// ความกว้างจริงของคำหลังผ่านขนาด/ฟอนต์ที่เจ้าของตั้ง — กรอบของคำที่ถูกบีบต้องเท่าตัวคำที่เห็น
    private func widthOf(_ s: String, _ size: CGFloat, _ weight: Font.Weight, for index: Int) -> CGFloat {
        let face = tune.face(for: .note, index) ?? .serif
        let ui = face.uiFont(tune.scaled(size, for: .note, index), weight)
        return (s as NSString).size(withAttributes: [.font: ui]).width
    }

    // MARK: การ์ดสามใบ

    private func cards(_ s: SocialProfile, w: CGFloat) -> some View {
        let inner = w - SG.side * 2 - SG.gap * 2
        return HStack(spacing: 0) {
            card(width: inner * SG.share[0]) { channel(s) }
            rule
            card(width: inner * SG.share[1]) { followers(s, w: inner * SG.share[1]) }
            rule
            card(width: inner * SG.share[2]) { engagement(s, w: inner * SG.share[2]) }
        }
        .padding(.horizontal, SG.side)
        .id(s.id)
    }

    /// เส้นแดงตั้งกลางช่องไฟระหว่างการ์ด
    private var rule: some View {
        Rectangle().fill(Picnic.red.opacity(0.85))
            .frame(width: 0.8)
            .frame(width: SG.gap)
            .padding(.vertical, 2)
            .scrubVeil(scrub.d, lead: 0.12, drop: 10, pull: 12)
    }

    private func card<C: View>(width: CGFloat, @ViewBuilder _ c: () -> C) -> some View {
        let shape = RoundedRectangle(cornerRadius: SG.cardRadius, style: .continuous)
        return c()
            .frame(width: width)
            .frame(maxHeight: .infinity)
            .background(shape.fill(Picnic.card))
            .overlay(shape.strokeBorder(Picnic.rim.opacity(0.9), lineWidth: 0.85))
    }

    // การ์ด 1 — โลโก้ใหญ่ · ชื่อแพลตฟอร์ม · แฮนเดิล · บทบาทของช่อง
    private func channel(_ s: SocialProfile) -> some View {
        let g = s.type.glyph(night: false)
        return HStack(spacing: 6) {
            Image(g.name)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: g.badge ? 44 : 51, height: g.badge ? 44 : 57)
                .scrubLouver(scrub.d, lead: 0, angle: 70, shrink: 0.2)

            VStack(alignment: .leading, spacing: -4) {
                Text(s.type.windowName)
                    .font(.sh(25, .heavy))
                    .kerning(-0.6)
                    .foregroundStyle(Picnic.ink)
                    .scrubVeil(scrub.d, lead: 0.04, drop: 16, pull: 8)
                Text(s.handle)
                    .font(.sh(14.5, .bold))
                    .kerning(-0.2)
                    .foregroundStyle(Picnic.inkSoft)
                    .dataValue()
                    .scrubVeil(scrub.d, lead: 0.08, drop: 14, pull: 8)
                Text(Profile.me.note(wid, 2, preset: Self.rolePreset))
                    .editableText(.note, index: 2, widget: wid,
                                  preset: Self.rolePreset, hint: "ช่องนี้ใช้ทำอะไร",
                                  .init(size: 11.5, weight: .regular, color: Picnic.inkSoft))
                    .padding(.top, 2)
                    .scrubVeil(scrub.d, lead: 0.12, drop: 12, pull: 8)
            }
            .lineLimit(1).minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 7)
        .linkSlot(s.profileURL)
    }

    // การ์ด 2 — ยอดผู้ติดตามเต็มหลัก เซริฟแคบสีเลือดหมู
    private func followers(_ s: SocialProfile, w: CGFloat) -> some View {
        let num = Fmt.baht(s.followerCount)
        let fit = Condensed.fit(num, capHeight: 36, width: w - 20)
        return VStack(spacing: -3) {
            digits(num, fit: fit, lead: 0.06)
            Text("ผู้ติดตาม")
                .font(.sh(14, .semibold))
                .foregroundStyle(Picnic.ink)
                .scrubVeil(scrub.d, lead: 0.14, drop: 14, pull: 8)
        }
    }

    // การ์ด 3 — Engagement Rate (มาจากการเชื่อมบัญชีเท่านั้น · ยังไม่มี = ขีด + บอกว่ารออะไร)
    private func engagement(_ s: SocialProfile, w: CGFloat) -> some View {
        let has = s.engagementRate > 0
        let num = has ? Fmt.pct(s.engagementRate) : "–"
        let fit = Condensed.fit(num, capHeight: 31, width: w - 20)
        return VStack(spacing: -3) {
            digits(num, fit: fit, lead: 0.12)
            VStack(spacing: -3) {
                Text("Engagement Rate")
                    .font(.sh(14, .bold))
                    .kerning(-0.3)
                    .foregroundStyle(Picnic.ink)
                Text(has ? "เฉลี่ย 30 โพสต์ล่าสุด" : "รอเชื่อมบัญชี")
                    .font(.sh(9.6, .regular))
                    .foregroundStyle(Picnic.inkSoft)
            }
            .lineLimit(1).minimumScaleFactor(0.6)
            .padding(.horizontal, 6)
            .scrubVeil(scrub.d, lead: 0.18, drop: 12, pull: 8)
        }
    }

    /// ตัวเลขเซริฟแคบ — ถอดทีละหลักตอนปัดหน้า แล้วบีบทั้งแถวพร้อมกัน
    private func digits(_ num: String, fit: (size: CGFloat, squeeze: CGFloat), lead: Double) -> some View {
        let ui = CardFont.serif.uiFont(fit.size, .black)
        let natural = (num as NSString).size(withAttributes: [.font: ui]).width
        return ScrubDigits(text: num, d: scrub.d, lead: lead, step: 0.04, drop: 26)
            .dataValue()
            .font(CardFont.serif.font(fit.size, .black))
            .foregroundStyle(Picnic.red)
            .fixedSize()
            .scaleEffect(x: fit.squeeze, y: 1)
            .frame(width: natural * fit.squeeze, height: ui.capHeight * 1.32)
    }

    // MARK: ฐาน — สูตร ER · ที่มาของตัวเลข (ตัวอักษรนั่งบนผ้าตรง ๆ แบบต้นฉบับ)

    private func footer(_ s: SocialProfile) -> some View {
        HStack {
            Text("ER = (Like + Comment + Share) ÷ Views × 100")
            Spacer(minLength: 8)
            Text(source(s))
        }
        .font(.sh(6.9, .medium))
        .foregroundStyle(Picnic.footInk)
        .lineLimit(1).minimumScaleFactor(0.7)
        .padding(.horizontal, 13)
        .padding(.top, 1)
        .scrubVeil(scrub.d, lead: 0.22, drop: 10, pull: 6)
    }

    @MainActor
    private func source(_ s: SocialProfile) -> String {
        if Profile.me.sampleFamilies.contains(.followers) { return "ข้อมูลตัวอย่าง" }
        // ยอดทุกช่องระบบ Sale Here ดึงเองจากลิงก์ที่วาง — ไม่มี "กรอกเอง · รอตรวจสอบ" ขัดกับป้าย Verified ที่มุมขวาบน
        return "ข้อมูลจาก \(s.type.windowName)"
    }
}

// MARK: - 02 โปสเตอร์พอร์ตผ้าปิกนิก (PORTFOLIO)

/// ค่าคงที่ของผัง — วัดจากแผ่นต้นฉบับ 444 × 760 แล้วย่อเป็นกว้าง 366 (× 0.824)
enum PG {
    static let w: CGFloat = 366
    static let h: CGFloat = 626
    static let radius: CGFloat = 33
    /// เส้นหยัก — ระยะจากขอบ (กึ่งกลางเส้น) · แอมพลิจูด · ความยาวคลื่น
    static let waveInset: CGFloat = 10.7
    /// ผืนผ้าตาราง — ระยะจากขอบซ้าย/ขวา/ล่าง และขอบบน
    static let clothInset: CGFloat = 14.8
    static let clothTop: CGFloat = 186
    /// ศูนย์กลางบรรทัดชื่อ · เส้นประกาย
    static let nameMid: CGFloat = 47
    static let nameCap: CGFloat = 25
    static let sparkleMid: CGFloat = 68.5
    static let sparkleRule: CGFloat = 77
    /// ตัวพิมพ์ใหญ่ของคำพาดหัว — ขอบบน · ความสูง · ความกว้างทั้งคำ
    static let capTop: CGFloat = 79
    static let capHeight: CGFloat = 101
    static let wordW: CGFloat = 0.86
    /// หัวคนตัดผ่านตัวอักษรลงมากี่ส่วนของความสูงตัวพิมพ์ใหญ่
    static let overlap: CGFloat = 0.63
}

struct PortfolioGinghamWidget: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(\.widgetID) private var wid
    @Environment(\.widgetLiftsPhoto) private var liftsPhoto
    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetTextStyle) private var tune
    let theme: CardTheme
    let size: CGSize

    /// ช่องเดียวกับหน้าต่างพอร์ต (1 = คำพาดหัว) — สลับแบบไปมาแล้วคำที่พิมพ์ไว้ตามไปด้วย
    private static let headlinePreset = "PORTFOLIO"

    var body: some View {
        PosterSheet(design: CGSize(width: PG.w, height: PG.h), frame: size) { box in
            poster(w: box.width, h: box.height)
        }
    }

    private func poster(w: CGFloat, h: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: PG.radius, style: .continuous)
        let plane = cutoutPlane(photos, slot: 1, widget: wid, lift: liftsPhoto)
        let cloth = CGRect(x: PG.clothInset, y: PG.clothTop,
                           width: w - PG.clothInset * 2, height: h - PG.clothTop - PG.clothInset)
        let subjectTop = PG.capTop + PG.capHeight * PG.overlap
        let bleed = h * 0.03

        return ZStack(alignment: .topLeading) {
            // ── กระดาษครีม + ผืนผ้า + ขอบหยัก
            LinearGradient(colors: [Picnic.paper, Picnic.paper.mix(with: Color(hex: 0xEFE2CE), by: 0.5)],
                           startPoint: .top, endPoint: .bottom)
            EdGrain(count: 420, opacity: 0.05, tint: .black)

            GinghamCloth(cell: 20.5)
                .frame(width: cloth.width, height: cloth.height)
                .offset(x: cloth.minX, y: cloth.minY)

            // รูปทึบ — **ผ้ายังอยู่** รูปถูกวางบนผ้าเป็นภาพพิมพ์ขอบครีม (ขอบแดงบางชุดเดียวกับการ์ดของป้ายช่องทาง)
            //
            // เคยให้รูปกินผืนผ้าทั้งผืน แล้วแผ่นเหลือแค่กระดาษครีมกับรูปสี่เหลี่ยม — ตัวตนของดีไซน์ (ผ้าตาราง)
            // หายไปทั้งใบ · และบน simulator Vision ลบพื้นหลังไม่ได้ รูปของเจ้าของการ์ดจึงตกมาทางนี้ทุกครั้ง
            if case .framed = plane {
                framedPrint(in: cloth, w: w)
            }

            WavyFrame(radius: PG.radius - PG.waveInset)
                .stroke(Picnic.wave, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
                .padding(PG.waveInset)
                .frame(width: w, height: h)

            // ── ชั้นหลัง: ชื่อ · ประกาย · คำยักษ์
            nameRow(w: w)
                .frame(width: w)
                .position(x: w / 2, y: PG.nameMid)
                .scrubSlide(scrub.d, travel: -w * 0.16, fade: 0.84, eased: false)

            sparkleRow
                .frame(width: w)
                .position(x: w / 2, y: PG.sparkleMid)
                .scrubVeil(scrub.d, lead: 0.1, drop: 10, pull: 10)

            headline(w: w)
                .scrubSlide(scrub.d, travel: -w * 0.26, fade: 0.84, eased: false)

            // ── ชั้นกลาง: คน — ยืนทับทั้งผ้าและขอบหยัก ถูกตัดแค่ที่ขอบนอกของแผ่น (แบบต้นฉบับ)
            if case let .subject(img, _) = plane {
                CutoutSubject(image: img, height: max(h * 0.4, h + bleed - subjectTop),
                              d: scrub.d, drift: w * 0.04, shadow: false)
                    .photoSlot(1)
                    .frame(width: w, height: h, alignment: .bottom)
                    .offset(y: bleed)
            }

            CutoutStatus(plane: plane, theme: theme,
                         lifting: cutoutLifting(photos, slot: 1, widget: wid, lift: liftsPhoto))
                .padding(.top, PG.clothTop + 8).padding(.trailing, PG.clothInset + 8)
                .frame(width: w, height: h, alignment: .topTrailing)
        }
        .frame(width: w, height: h)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Picnic.rim, lineWidth: 1.3))
    }

    /// ชื่อกลางแผ่น — ไทยตกไปหน้าตามีหัวของระบบ (เซริฟของแอปไม่มีอักษรไทย) ตรงกับต้นฉบับพอดี
    private func nameRow(w: CGFloat) -> some View {
        let name = Profile.me.name
        let ns = Ed.fitted(name, weight: .medium, face: .serif, width: w * 0.5,
                           cap: PG.nameCap, floor: 12)
        return HStack(spacing: ns * 0.25) {
            Text(name)
                .lineLimit(1)
                .fixedSize()
                .editableText(.name, .init(size: ns, weight: .medium, face: .serif, color: Picnic.ink))
            if Profile.me.creator.verified {
                StarSeal(size: max(8, ns * 0.36), tint: Picnic.red, punch: Picnic.paper)
            }
        }
    }

    /// เส้นบางสองข้าง + ประกายสี่แฉกตรงกลาง
    private var sparkleRow: some View {
        HStack(spacing: 6) {
            Rectangle().fill(Picnic.red.opacity(0.8)).frame(width: PG.sparkleRule, height: 0.8)
            PicnicSparkle().fill(Picnic.red).frame(width: 9, height: 11)
            Rectangle().fill(Picnic.red.opacity(0.8)).frame(width: PG.sparkleRule, height: 0.8)
        }
    }

    /// ภาพพิมพ์บนผ้า — ขอบครีม · เส้นแดงบาง · เงาจาง ๆ ว่ามันวางอยู่บนผ้า ไม่ได้ถูกพิมพ์เป็นเนื้อเดียว
    ///
    /// วางด้วย padding ไม่ใช่ offset — กรอบของช่อง (`photoSlot`) ต้องอยู่ตรงที่รูปถูกวาดจริง
    /// ไม่งั้นแผ่นจัดรูปกับปุ่มเปลี่ยนรูปไปเกาะตำแหน่งก่อนเลื่อน (บทเรียนเดียวกับโปสเตอร์พอร์ต)
    private func framedPrint(in cloth: CGRect, w: CGFloat) -> some View {
        let side: CGFloat = 20, top: CGFloat = 14, bottom: CGFloat = 20, mat: CGFloat = 6
        let outer = RoundedRectangle(cornerRadius: 9, style: .continuous)
        let inner = RoundedRectangle(cornerRadius: 4, style: .continuous)
        return Color.clear
            .overlay {
                WidgetPhoto(index: 1)
                    .aspectRatio(contentMode: .fill)
                    .scrubDolly(scrub.d, shift: w * 0.04, zoom: 0.12)
            }
            .clipShape(inner)
            .photoSlot(1)
            .padding(mat)
            .background(outer.fill(Picnic.card))
            .overlay(outer.strokeBorder(Picnic.rim.opacity(0.9), lineWidth: 0.9))
            .shadow(color: .black.opacity(0.16), radius: 7, y: 3)
            .frame(width: cloth.width - side * 2, height: cloth.height - top - bottom)
            .padding(.leading, cloth.minX + side)
            .padding(.top, cloth.minY + top)
    }

    /// คำยักษ์เซริฟแคบสีเลือดหมู — วางด้วยขอบบนของตัวพิมพ์ใหญ่ ไม่ใช่ขอบกล่องข้อความ
    private func headline(w: CGFloat) -> some View {
        let word = Profile.me.note(wid, 1, preset: Self.headlinePreset).uppercased()
        let fit = Condensed.fit(word, capHeight: PG.capHeight, width: w * PG.wordW, weight: .black)
        let face = tune.face(for: .note, 1) ?? .serif
        let ui = face.uiFont(tune.scaled(fit.size, for: .note, 1), .black)
        let natural = (word as NSString).size(withAttributes: [.font: ui]).width
        let lineTop = PG.capTop - (ui.ascender - ui.capHeight)
        return Text(word)
            .lineLimit(1)
            .fixedSize()
            .editableText(.note, index: 1, widget: wid, preset: Self.headlinePreset, hint: "คำพาดหัว",
                          .init(size: fit.size, weight: .black, face: .serif, color: Picnic.red,
                                align: .center, uppercase: true, corner: 6))
            .scaleEffect(x: fit.squeeze, y: 1)
            .frame(width: natural * fit.squeeze, height: ui.lineHeight, alignment: .top)
            .frame(width: w)
            .offset(y: lineTop)
    }
}
