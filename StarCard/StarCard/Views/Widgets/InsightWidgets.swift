import SwiftUI

// MARK: - สำรับ "ผู้ชม"
//
// สเปกหมวด 2.3 — ผู้ชมเป็นใคร · สี่แบบในตระกูลเดียวกัน สลับกันได้
//
// สามแบบแรกเป็น **แผ่นข้อมูล** ตรงไปตรงมา: แถบสัดส่วน · แท่งช่วงอายุ · อันดับเมือง
// แบบที่สี่เป็น **ประโยคเดียว** ที่ยุบทั้งสามชุดเหลือคำตอบบรรทัดเดียว
//
// กติกาที่คุมทั้งไฟล์: **ทุกตัวเลขในนี้ครีเอเตอร์แก้ไม่ได้** — มาจาก OAuth เท่านั้น
// วันต่อ backend ห้ามเปิดฟิลด์ไหนเป็นฟอร์มให้พิมพ์เด็ดขาด ถ้าเปิด ชั้นหลักฐานทั้งชั้น
// เสียน้ำหนักพร้อมกัน (ความเสี่ยงข้อ 4 ในเอกสารคอนเซปต์)

/// สีเพศ — คงที่ ไม่ผูกพาเลตต์ เพราะสามส่วนต้องแยกออกจากกันได้ทุกธีม
private enum Aud {
    static let female = Color(red: 1.00, green: 0.55, blue: 0.74)
    static let male = Color(red: 0.51, green: 0.60, blue: 1.00)
    static let other = Color(red: 0.36, green: 0.90, blue: 0.68)
}

// MARK: - 01 · สัดส่วนผู้ชม

/// Gender Ratio — แถบเดียวสามส่วน อ่านจบก่อนตาจะเลื่อนไปที่อื่น
///
/// จงใจไม่ใช้โดนัท: สามส่วนที่ต่างกัน 78/20/2 บนวงกลม ส่วนที่เล็กที่สุดจะกลายเป็นเสี้ยว
/// ที่มองไม่เห็น ส่วนบนแถบยาวมันยังเป็นช่องที่วัดได้ — รูปทรงต้องเลือกจากข้อมูล ไม่ใช่จากความสวย
///
/// # ท่าเปลี่ยนหน้า — "แถบถูกกวาดคืนทีละส่วน"
/// ใช้ `Scrub.cell` ตัวเดียวกับตารางเวลารับงาน ส่วนที่อยู่ต้นทางของการเดินทางหายก่อนเสมอ
struct AudienceSplitWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    private var a: AudienceInsight { Mock.creator.audience }
    private var parts: [(String, Double, Color)] {
        [("หญิง", a.female, Aud.female),
         ("ชาย", a.male, Aud.male),
         ("อื่น ๆ", a.other, Aud.other)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            WidgetLabel(text: "สัดส่วนผู้ชม")
                .scrubVeil(scrub.d, lead: 0.38, drop: 20, pull: 6)

            bar
            legend
            Spacer(minLength: 0)
        }
    }

    private var bar: some View {
        ScrubReader(d: scrub.d) { d in
            GeometryReader { geo in
                let w = geo.size.width
                HStack(spacing: 3) {
                    ForEach(Array(parts.enumerated()), id: \.offset) { i, p in
                        let k = Scrub.cell(i, of: parts.count, d: d, spill: 0.9)
                        Capsule()
                            .fill(p.2)
                            .frame(width: max(5, (w - 6) * p.1 / 100))
                            .scaleEffect(x: k, anchor: .leading)
                            .opacity(k)
                    }
                    Spacer(minLength: 0)
                }
                .frame(height: geo.size.height, alignment: .center)
            }
        }
        .frame(height: 13)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            ForEach(Array(parts.enumerated()), id: \.offset) { i, p in
                HStack(spacing: 5) {
                    Circle().fill(p.2).frame(width: 7, height: 7)
                    Text(Fmt.pct(p.1))
                        .font(.sh(14, .heavy))
                        .foregroundStyle(ink.text(0.96))
                    Text(p.0)
                        .font(.sh(10.5, .medium))
                        .foregroundStyle(ink.text(0.46))
                }
                .lineLimit(1).fixedSize()
                .scrubVeil(scrub.d,
                           lead: Scrub.lead(i, of: parts.count, d: scrub.d, step: 0.07),
                           drop: 20, pull: 10)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - 02 · ช่วงอายุผู้ชม

/// Age Distribution — แท่งนอนเรียง **ตามอายุ ไม่ใช่ตามขนาด**
///
/// ลำดับอายุคือข้อมูลในตัวมันเอง ถ้าเรียงจากมากไปน้อยแบบชาร์ตทั่วไป
/// ตาจะอ่านไม่ออกว่ากลุ่มนี้ "เอียงไปทางเด็ก" หรือ "เอียงไปทางผู้ใหญ่" ซึ่งคือคำถามจริงของแบรนด์
///
/// # ท่าเปลี่ยนหน้า — "แท่งหดกลับเข้าแกน"
struct AudienceAgeWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    private var bands: [AudienceInsight.AgeBand] { Mock.creator.audience.ages }
    private var top: Double { bands.map(\.share).max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetLabel(text: "ช่วงอายุผู้ชม")
                .scrubVeil(scrub.d, lead: 0.38, drop: 20, pull: 6)

            VStack(spacing: 0) {
                ForEach(Array(bands.enumerated()), id: \.element.id) { i, b in
                    row(b, lead: Scrub.lead(i, of: bands.count, d: scrub.d, step: 0.08))
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
    }

    private func row(_ b: AudienceInsight.AgeBand, lead: Double) -> some View {
        // กลุ่มใหญ่ที่สุดได้สีธีมเต็ม ที่เหลือจางลง — คำตอบต้องเด่นกว่าบริบทเสมอ
        let peak = b.share == top
        return HStack(spacing: 10) {
            Text(b.label)
                .font(.sh(11, .semibold))
                .foregroundStyle(ink.text(peak ? 0.9 : 0.5))
                .frame(width: 42, alignment: .leading)
                .lineLimit(1)

            ScrubReader(d: scrub.d) { d in
                let t = Scrub.ease(Scrub.t(d, lead: lead))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ink.fill(0.07))
                        Capsule()
                            .fill(peak
                                  ? AnyShapeStyle(LinearGradient(colors: [theme.accentSoft, theme.accent],
                                                                 startPoint: .leading, endPoint: .trailing))
                                  : AnyShapeStyle(theme.accent.opacity(0.34)))
                            .frame(width: geo.size.width * b.share / max(1, top) * max(0, 1 - t))
                    }
                }
            }
            .frame(height: 9)

            // ตัวเลขได้ความกว้างตามตัวจริงเสมอ — เดิมล็อกไว้ 36pt ซึ่งพอดีแค่ "8.8%"
            // พอเจอ "22.4%" มันถูกตัดเป็น "22…" คือตัวเลขที่อ่านไม่ได้ ซึ่งแย่กว่าคอลัมน์ไม่ตรงกัน
            Text(Fmt.pct(b.share))
                .font(.sh(12.5, .heavy))
                .foregroundStyle(ink.text(peak ? 0.98 : 0.55))
                .lineLimit(1).fixedSize()
                .frame(minWidth: 38, alignment: .trailing)
                .scrubVeil(scrub.d, lead: lead, drop: 16, pull: 6)
        }
    }
}

// MARK: - 03 · ผู้ชมอยู่ที่ไหน

/// Top Locations — อันดับพร้อมสัดส่วน
///
/// ตัวเลขนำหน้า (01 · 02) ใช้ได้ที่นี่เพราะมัน**คืออันดับจริง** ไม่ใช่เลขประดับ
/// และเป็นข้อมูลที่ต่อตรงกับ E2 ในเอกสารคอนเซปต์ (หน้ารวมอินฟลูฯ ตามจังหวัด)
///
/// # ท่าเปลี่ยนหน้า — "อันดับถูกปิดไล่จากท้าย"
struct AudienceMapWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    private var places: [AudienceInsight.PlaceShare] { Mock.creator.audience.places }
    private var top: Double { places.map(\.share).max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            WidgetLabel(text: "ผู้ชมอยู่ที่ไหน",
                        trailing: AnyView(
                            HStack(spacing: 4) {
                                SymbolIcon(name: SHIcon.mapPin, size: 10, tint: theme.accent)
                                Text("อันดับ 1–\(places.count)")
                                    .font(.sh(9.5, .bold))
                                    .foregroundStyle(theme.accent)
                                    .fixedSize()
                            }))
                .scrubVeil(scrub.d, lead: 0.38, drop: 20, pull: 6)

            VStack(spacing: 0) {
                ForEach(Array(places.enumerated()), id: \.element.id) { i, p in
                    row(p, rank: i + 1,
                        lead: Scrub.lead(i, of: places.count, d: scrub.d, step: 0.08))
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func row(_ p: AudienceInsight.PlaceShare, rank: Int, lead: Double) -> some View {
        ZStack(alignment: .leading) {
            // แถบสัดส่วนอยู่ "หลังตัวหนังสือ" ไม่ใช่ข้าง ๆ — แถวจึงอ่านเป็นรายการ ไม่ใช่ตาราง
            ScrubReader(d: scrub.d) { d in
                let t = Scrub.ease(Scrub.t(d, lead: lead))
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(theme.accent.opacity(rank == 1 ? 0.2 : 0.09))
                        .frame(width: geo.size.width * p.share / max(1, top) * max(0, 1 - t))
                }
            }

            HStack(spacing: 10) {
                Text(String(format: "%02d", rank))
                    .font(.sh(10, .black))
                    .foregroundStyle(ink.text(0.32))
                Text(p.name)
                    .font(.sh(13, .bold))
                    .foregroundStyle(ink.text(0.94))
                    .lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                Text(Fmt.pct(p.share))
                    .font(.sh(13, .heavy))
                    .foregroundStyle(ink.text(0.94))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .scrubVeil(scrub.d, lead: lead, drop: 22, pull: 10)
        }
    }
}

// MARK: - 04 · ประโยคเดียว

/// ผู้ชมทั้งชุดยุบเหลือ **ประโยคเดียวที่พิมพ์ใหญ่** — เพศ อายุ เมือง เรียงเป็นสามคำ
///
/// เปอร์เซ็นต์ยังอยู่ครบ แต่ถูกลดชั้นเป็นบรรทัดจิ๋วท้ายก้อน เพราะมันคือ *หลักฐานประกอบ*
/// ไม่ใช่ *คำตอบ* — คนที่อยากตรวจตัวเลขค่อยอ่านทีหลังได้
///
/// สามค่านี้คำนวณจากข้อมูลจริงทุกครั้ง ไม่ได้ฮาร์ดโค้ดว่าเป็นผู้หญิง/25–34/กรุงเทพฯ
///
/// # ท่าเปลี่ยนหน้า — "บรรทัดคลายตัวแล้วจากไป"
/// ระยะตัวอักษรคลายออกก่อนบรรทัดจะมุดใต้ขอบ — ภาษา kinetic typography เดียวกับ `HeroMinimal`
struct AudienceLineWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let size: CGSize

    private var a: AudienceInsight { Mock.creator.audience }

    private var gender: (word: String, share: Double) {
        let all: [(String, Double)] = [("ผู้หญิง", a.female), ("ผู้ชาย", a.male), ("เพศอื่น", a.other)]
        let top = all.max { $0.1 < $1.1 } ?? all[0]
        return (top.0, top.1)
    }
    private var age: AudienceInsight.AgeBand? { a.ages.max { $0.share < $1.share } }
    private var place: AudienceInsight.PlaceShare? { a.places.max { $0.share < $1.share } }

    var body: some View {
        // ขนาดคำนวณจากความกว้างจริง ไม่ตั้งค่าคงที่ — widget ตัวนี้ถูกย่อครึ่งได้
        let big = min(30, size.width * 0.093)
        return VStack(alignment: .leading, spacing: 1) {
            Text("คนที่ตามฉันส่วนใหญ่คือ")
                .font(.sh(11.5, .semibold))
                .foregroundStyle(ink.text(0.45))
                .lineLimit(1).minimumScaleFactor(0.7)
                .padding(.bottom, 7)
                .scrubVeil(scrub.d, lead: 0.42, drop: 18, pull: 6)

            line(gender.word, size: big, tint: ink.text(0.96), i: 0)
            if let age { line("อายุ \(age.label)", size: big, tint: theme.accent, i: 1) }
            if let place { line("ใน\(place.name)", size: big, tint: ink.text(0.96), i: 2) }

            Spacer(minLength: 6)

            Text("\(Fmt.pct(gender.share)) · \(Fmt.pct(age?.share ?? 0)) · \(Fmt.pct(place?.share ?? 0)) ตามลำดับ")
                .font(.sh(10, .medium))
                .foregroundStyle(ink.text(0.34))
                .lineLimit(1).minimumScaleFactor(0.65)
                .scrubVeil(scrub.d, lead: 0, drop: 18, pull: 16)

                .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func line(_ text: String, size: CGFloat, tint: Color, i: Int) -> some View {
        let lead = Scrub.lead(i, of: 3, d: scrub.d, step: 0.09)
        return ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d, lead: lead))
            Text(text)
                .font(.sh(size, .black))
                // บีบอยู่ตอนนิ่ง แล้วคลายออกตอนจากไป
                .tracking(-0.8 + 7 * t)
                .foregroundStyle(tint)
                .lineLimit(1).minimumScaleFactor(0.55)
        }
        .scrubVeil(scrub.d, lead: lead + 0.1, drop: size * 1.3, pull: 8)
    }
}
