import SwiftUI

// MARK: - โปสเตอร์อินไซต์
//
// แปลงจากแผ่น **Público**: คำตัวเขียนยักษ์มุมซ้ายบน · คนยืนกลางแผ่น (PNG พื้นหลังใส)
// · แผ่นข้อมูลขาวลอยล้อมตัวคน ทับไหล่ ทับแขน — ไม่มีแผ่นรองข้างหลัง
//
// ใบเดียวในตระกูล `audience` ที่วาด **ทุกชุดพร้อมกัน** — การเข้าถึง · เพศ · อายุ · เมือง
//
// # สามระนาบ (ภาษาเดียวกับตระกูลคัตเอาต์)
//
// 1. **หลัง** คำตัวเขียน — หัวคนทับมัน
// 2. **กลาง** คน
// 3. **หน้า** แผ่นข้อมูลสี่แผ่น — ทับขอบตัวคน ไม่ทับหน้า
//
// # ไม่มีพื้นเป็นค่าตั้งต้น
//
// พื้นของใบนี้คือ *สีพื้นหลังการ์ดที่เจ้าของเลือก* — ต้นฉบับไม่มีกรอบ ทุกอย่างลอยบนฉากเดียว
// (ถาดยังเลือก "มีพื้น" / "กระจก" ได้เหมือนโปสเตอร์ใบอื่น แต่ใบนี้เริ่มที่ไม่มีพื้น)
//
// # ตัวหนังสือกับตัวเลขต้องใหญ่
//
// ตัวเลขทุกตัวหนา heavy และใหญ่กว่าชื่อของมันเสมอ (ตัวเลขคือคำตอบ ชื่อคือบริบท)
// แผ่นข้อมูลเป็นกระดาษขาวหมึกดำของมันเอง จึงอ่านออกบนทุกสีพื้นหลัง
//
// ทุกตัวเลขมาจาก OAuth — ตอนนี้เป็น mock ใน `MockData` (`AudienceInsight.reach`)

/// ค่าคงที่ของผัง — **หน่วยเดียวกับ `WidgetKind.defaultSize`** (366 × 520)
enum IP {
    static let w: CGFloat = 366
    static let h: CGFloat = 520

    /// คำตัวเขียน
    static let script: CGFloat = 76
    /// ตัวคนสูงกี่ส่วนของแผ่น — หัวต้องขึ้นไปชนคำตัวเขียนเหมือนต้นฉบับ
    static let subject: CGFloat = 0.88

    /// แผ่นข้อมูล — กว้างไม่เกินนี้ ไม่งั้นสองฝั่งปิดตัวคนมิด
    static let narrow: CGFloat = 142
    static let wide: CGFloat = 152

    static let title: CGFloat = 13
    static let label: CGFloat = 12.5
    static let value: CGFloat = 15.5
    static let hero: CGFloat = 34
}

/// หมึกของแผ่นข้อมูลขาว — คงที่ทุกธีม (ดูหัวไฟล์)
private enum Sheet {
    static let paper = Color.white
    static let ink = Color(white: 0.07)
    static let soft = Color(white: 0.42)
    static let rail = Color(white: 0.91)
    static let up = Color(red: 0.07, green: 0.58, blue: 0.30)
}

struct InsightPosterWidget: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(\.widgetID) private var wid
    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var cardInk
    @Environment(\.widgetTextStyle) private var tune
    let theme: CardTheme
    let size: CGSize

    private static let scriptPreset = "Audience"

    private var a: AudienceInsight { Profile.me.shownAudience }
    /// สีแท่ง/วง — สีเน้นของธีมที่จูนมาสำหรับพื้นขาว (แผ่นข้อมูลขาวเสมอ)
    private var bar: Color { theme.rawAccent.onLightSurface() }

    var body: some View {
        PosterSheet(design: CGSize(width: IP.w, height: IP.h), frame: size) { box in
            sheet(box)
        }
    }

    private func sheet(_ box: CGSize) -> some View {
        // หมึกของพื้น ใช้สูตรเดียวกับโปสเตอร์ผู้ติดตาม (ไม่มีพื้น = หมึกของการ์ด)
        let skin = StatPosterSkin.make(surface, theme: theme, on: cardInk)
        let plane = cutoutPlane(photos, slot: 1, widget: wid)

        return ZStack(alignment: .topLeading) {
            Color.clear
            if skin.papered {
                skin.plate
                PlatePatternLayer(sheet: skin.plate)
                EdGrain(count: 320, opacity: 0.04, tint: .white)
            }

            // ผังกว้างเท่าออกแบบเสมอ แล้วจัดกลางบนแผ่นที่กว้างขึ้น (เหตุผลเดียวกับ `ContactPosterWidget`)
            ZStack(alignment: .topLeading) {
                // ── หลัง: คำตัวเขียน
                script(skin)

                // ── กลาง: คน
                subject(plane, h: box.height)

                // ── หน้า: แผ่นข้อมูล — ตำแหน่งเป็น padding ไม่ใช่ `.offset`
                // (`scrubVeil` มี mask ขนาดกรอบของชิ้น ชิ้นที่ถูก offset ถูกหน้ากากตัวเองตัดทิ้ง)
                // สองคอลัมน์สลับจังหวะกัน (ขวาขึ้นก่อน ซ้ายตามลงมา) — ไม่ซ้อนกันเอง
                // และเว้นแถบกลางให้หน้ากับลำตัวคนโผล่ตลอดความสูง
                // เว้นแถบกลางให้หน้าคนโผล่เต็ม — คอลัมน์ขวาเริ่มใต้ระดับคาง
                place(0, x: 0, y: 148, w: IP.narrow) { places }
                place(3, x: IP.w - IP.narrow, y: 176, w: IP.narrow) { ages }
                place(1, x: 0, y: 312, w: IP.wide) { gender }
                place(2, x: IP.w - IP.wide, y: 340, w: IP.wide) { reach }
            }
            .frame(width: IP.w, height: box.height, alignment: .topLeading)
            .frame(width: box.width, height: box.height)
        }
        .frame(width: box.width, height: box.height)
        .clipShape(RoundedRectangle(cornerRadius: skin.papered ? min(theme.radius, 20) : 0,
                                    style: .continuous))
        .overlay(alignment: .topTrailing) {
            CutoutStatus(plane: plane, theme: theme).padding(9)
        }
    }

    // MARK: คำตัวเขียน

    /// คำเดียวตัวเขียนยักษ์ — ต้นฉบับคือ "Público" · พิมพ์ทับได้
    ///
    /// ฟอนต์ตัวเขียนเป็นของดีไซน์ (Snell Roundhand ที่มากับ iOS) จึงตั้งเอง
    /// ถ้าผู้ใช้สั่งฟอนต์ในแผงข้อความ ฟอนต์นั้นมาก่อน
    private func script(_ skin: StatPosterSkin) -> some View {
        let text = Profile.me.note(wid, 1, preset: Self.scriptPreset)
        let s = tune.scaled(IP.script, for: .note, 1)
        let font = tune.face(for: .note, 1)?.font(s, .regular)
            ?? Font.custom("SnellRoundhand", size: s)
        return Text(text)
            .font(font)
            .foregroundColor(skin.ink)
            .lineLimit(1).minimumScaleFactor(0.4)
            .editableText(.note, index: 1, widget: wid,
                          preset: Self.scriptPreset, hint: "คำพาดหัว",
                          .init(size: IP.script, weight: .regular, color: skin.ink,
                                align: .leading, corner: 6))
            .frame(width: IP.w * 0.86, alignment: .leading)
            .padding(.leading, 10)
            .padding(.top, 4)
            .scrubSlide(scrub.d, travel: -IP.w * 0.26, fade: 0.84, eased: false)
    }

    // MARK: คน

    @ViewBuilder
    private func subject(_ plane: CutoutPlane, h: CGFloat) -> some View {
        switch plane {
        case let .subject(ui, _):
            // ยืนบนขอบล่างที่เห็นจริง กลางแผ่น · ไม่มีเงา — ฉากเดียวกับแผ่นข้อมูล
            CutoutSubject(image: ui, height: h * IP.subject, d: scrub.d,
                          drift: IP.w * 0.03, shadow: false)
                .photoSlot(1)
                .frame(width: IP.w, height: h, alignment: .bottom)
                .offset(y: h * 0.02)
        case .framed:
            // รูปทึบ — แผ่นมนกลางแผ่นแทนคนยืน ผังที่เหลือไม่ขยับ
            Color.clear
                .overlay {
                    WidgetPhoto(index: 1)
                        .aspectRatio(contentMode: .fill)
                        .scrubDolly(scrub.d, shift: IP.w * 0.04, zoom: 0.12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(width: IP.w * 0.54, height: h * 0.8)
                .photoSlot(1)
                .frame(width: IP.w, height: h, alignment: .bottom)
                .offset(y: -12)
        }
    }

    // MARK: แผ่นข้อมูล

    /// แผ่นขาวหนึ่งแผ่นที่ตำแหน่ง (x, y) ในหน่วยออกแบบ — สูงเท่าเนื้อหาพอดี
    private func place<C: View>(_ i: Int, x: CGFloat, y: CGFloat, w: CGFloat,
                                @ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, 11)
            .padding(.vertical, 10)
            .frame(width: w, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Sheet.paper))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
            .scrubVeil(scrub.d, lead: Scrub.lead(i, of: 4, d: scrub.d, step: 0.07),
                       drop: 26, pull: 10)
            .padding(.leading, x)
            .padding(.top, y)
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .font(.sh(IP.title, .bold))
            .foregroundStyle(Sheet.ink)
            .lineLimit(1).minimumScaleFactor(0.7)
    }

    // ── การเข้าถึง

    private var reach: some View {
        let r = a.reach
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                title("การเข้าถึง · \(r.window)")
                Spacer(minLength: 0)
                BrandIcon(name: r.platform.icon, size: 15)
            }
            ScrubDigits(text: Fmt.compact(r.accounts), d: scrub.d,
                        lead: 0.06, step: 0.05, drop: 26)
                .dataValue()
                .font(.sh(IP.hero, .heavy))
                .foregroundStyle(Sheet.ink)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text("บัญชีที่เห็น")
                .font(.sh(11.5, .semibold))
                .foregroundStyle(Sheet.soft)
                .padding(.bottom, 6)
            HStack(spacing: 5) {
                Text("+\(Fmt.pct(r.delta))")
                    .dataValue()
                    .font(.sh(12, .heavy))
                    .foregroundStyle(Sheet.up)
                    .padding(.horizontal, 6).padding(.vertical, 2.5)
                    .background(Capsule().fill(Sheet.up.opacity(0.12)))
                    .fixedSize()
                Text("ใหม่ \(Fmt.pct(r.newShare))")
                    .dataValue()
                    .font(.sh(12, .bold))
                    .foregroundStyle(Sheet.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
        }
    }

    // ── เพศ

    /// สามส่วนเรียงจากมากไปน้อย — ส่วนใหญ่สุดได้สีเน้น ที่เหลือเป็นเทาเข้ม/อ่อน
    /// (ไม่ผูกชมพู/ฟ้าตายตัว เพราะต้องเข้ากับทุกธีม และยังแยกกันออกทุกธีม)
    private var genderParts: [(String, Double, Color)] {
        let raw = [("หญิง", a.female), ("ชาย", a.male), ("อื่น ๆ", a.other)]
            .sorted { $0.1 > $1.1 }
        let tones = [bar, Color(white: 0.18), Color(white: 0.72)]
        return raw.enumerated().map { ($1.0, $1.1, tones[$0]) }
    }

    private var gender: some View {
        let parts = genderParts
        return VStack(alignment: .leading, spacing: 6) {
            title("เพศ")
            HStack(spacing: 12) {
                donut(parts).frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(parts.enumerated()), id: \.offset) { i, p in
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(Fmt.pct(p.1)).dataValue()
                                .font(.sh(i == 0 ? 19 : IP.value, .heavy))
                                .foregroundStyle(i == 2 ? Sheet.soft : Sheet.ink)
                            Text(p.0)
                                .font(.sh(11, .semibold))
                                .foregroundStyle(Sheet.soft)
                        }
                        .lineLimit(1).minimumScaleFactor(0.7)
                    }
                }
            }
        }
    }

    private func donut(_ parts: [(String, Double, Color)]) -> some View {
        let total = max(parts.reduce(0) { $0 + $1.1 }, 1)
        let gap = 0.012
        return ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d, lead: 0.12))
            ZStack {
                Circle().stroke(Sheet.rail, lineWidth: 10)
                ForEach(Array(parts.enumerated()), id: \.offset) { i, p in
                    let start = parts.prefix(i).reduce(0) { $0 + $1.1 } / total
                    let end = start + p.1 / total
                    // ส่วนที่เล็กมากยังต้องเห็นเป็นขีด — ช่องว่างกินได้ไม่เกินครึ่งของมัน
                    let g = min(gap, (end - start) / 3)
                    Circle()
                        .trim(from: start + g, to: max(start + g, end - g) * max(0, 1 - t))
                        .stroke(p.2, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
            }
            .padding(5)
        }
    }

    // ── ช่วงอายุ · เมือง — แผ่นแท่งแบบต้นฉบับ: ชื่อซ้าย ตัวเลขขวา แท่งบนรางข้างใต้
    //
    // **สามอันดับแรกเท่านั้น เรียงจากมากไปน้อย** (ผู้ใช้สั่ง) — ต้นฉบับเรียงตามขนาดเหมือนกัน
    // แผ่นเตี้ยลงจึงไม่บังหน้าคน และตัวเลขยังใหญ่ได้เท่าเดิม

    private static let topN = 3

    private var ages: some View {
        bars("ช่วงอายุ", rows: top(a.ages.map { ($0.label, $0.share) }))
    }

    private var places: some View {
        bars("เมืองหลัก", rows: top(a.places.map { ($0.name, $0.share) }))
    }

    private func top(_ rows: [(String, Double)]) -> [(String, Double)] {
        Array(rows.sorted { $0.1 > $1.1 }.prefix(Self.topN))
    }

    private func bars(_ heading: String, rows: [(String, Double)]) -> some View {
        let top = rows.map(\.1).max() ?? 1
        return VStack(alignment: .leading, spacing: 4) {
            title(heading)
            ForEach(Array(rows.enumerated()), id: \.offset) { i, r in
                barRow(r.0, share: r.1, peak: r.1 == top,
                       lead: Scrub.lead(i, of: rows.count, d: scrub.d, step: 0.08))
            }
        }
    }

    private func barRow(_ name: String, share: Double, peak: Bool, lead: Double) -> some View {
        VStack(spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(name)
                    .font(.sh(IP.label, .semibold))
                    .foregroundStyle(Sheet.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 2)
                Text(Fmt.pct(share)).dataValue()
                    .font(.sh(IP.value, .heavy))
                    .foregroundStyle(Sheet.ink)
                    .lineLimit(1).fixedSize()
            }
            ScrubReader(d: scrub.d) { d in
                let t = Scrub.ease(Scrub.t(d, lead: lead))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Sheet.rail)
                        Capsule()
                            .fill(peak ? bar : bar.opacity(0.55))
                            .frame(width: max(4, geo.size.width * share / 100 * max(0, 1 - t)))
                    }
                }
            }
            .frame(height: 6)
        }
    }
}
