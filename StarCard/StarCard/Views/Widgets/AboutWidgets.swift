import SwiftUI

// widget กลุ่ม "เกี่ยวกับฉัน" และ "เงื่อนไขรับงาน"
//
// สามตัวหลัง (หมวดหมู่ · เวลา · ประเภทคอนเทนต์) เป็นชั้น connected — ค่ามาจากหน้าตั้งค่าโปรไฟล์
// แต่งหน้าตาได้ แต่แก้ค่าบนการ์ดไม่ได้ ไม่งั้นข้อมูลจะขัดกับระบบจับคู่งาน

// MARK: - แนะนำตัว

/// ย่อหน้าแนะนำตัว — ตัวเดียวในการ์ดที่ครีเอเตอร์พูดด้วยเสียงตัวเองล้วน ๆ
///
/// วางแบบ standfirst ของนิตยสาร: เส้นสีตั้งนำสายตา ข้อความเยื้องเข้ามา
///
/// # ท่าเปลี่ยนหน้า — "เส้นนำหดกลับ"
/// เส้นสีที่ยึดบล็อกทั้งก้อนหดขึ้นจากปลายล่างตามนิ้ว อ่านเป็นแถบความคืบหน้าของการปัด
/// แล้วยืดกลับลงมาตอนปัดกลับ — ตัวหนังสือมุดใต้ขอบตามทีหลัง
struct AboutText: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    private var c: CreatorProfile { Mock.creator }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // เส้นนำ — จางลงตามความสูง ให้บล็อกดูละลายหายไปแทนที่จะจบห้วน ๆ
            ScrubReader(d: scrub.d) { d in
                let t = Scrub.ease(Scrub.t(d))
                Capsule()
                    .fill(LinearGradient(colors: [theme.accent, theme.accent.opacity(0.08)],
                                         startPoint: .top, endPoint: .bottom))
                    .scaleEffect(y: max(0, 1 - t), anchor: .top)
            }
            .frame(width: 2.5)

            VStack(alignment: .leading, spacing: 10) {
                Text("แนะนำตัว".uppercased())
                    .font(.sh(9.5, .semibold)).tracking(1.4)
                    .foregroundStyle(theme.accent.opacity(0.85))
                    .scrubVeil(scrub.d, lead: 0.3, drop: 18, pull: 6)

                Text(c.about)
                    .font(.sh(14))
                    .foregroundStyle(ink.text(0.88))
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
                    .scrubVeil(scrub.d, lead: 0.06, drop: 34, pull: 16)

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - หมวดหมู่ที่สนใจ

/// หมวดหมู่ทางการของแพลตฟอร์ม — ต่างจาก "สายงาน" ที่ครีเอเตอร์พิมพ์เอง
/// ติดเครื่องหมายถูกไว้เพราะเป็นค่าที่ระบบใช้จับคู่งานจริง ไม่ใช่คำโปรยที่เขียนเอง
///
/// # ท่าเปลี่ยนหน้า — "ชิปร่วงทีละเม็ด"
/// ชิปมุดใต้บรรทัดของตัวเองไล่กันตามทิศ ไม่ใช่ทั้งกลุ่มเลื่อนเป็นแผ่นเดียว
struct InterestTags: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    var body: some View {
        let items = Mock.creator.interests
        return VStack(alignment: .leading, spacing: 11) {
            WidgetLabel(text: "หมวดหมู่ที่สนใจ",
                        trailing: AnyView(SymbolIcon(name: SHIcon.sealCheck, size: 11,
                                                     tint: theme.accent.opacity(0.8))))
                .scrubVeil(scrub.d, lead: 0.34, drop: 20, pull: 6)

            FlowLayout(spacing: 7) {
                ForEach(Array(items.enumerated()), id: \.element) { i, name in
                    Text(name)
                        .font(.sh(12, .semibold))
                        .foregroundStyle(ink.text(0.95))
                        .lineLimit(1)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(
                            Capsule().fill(LinearGradient(
                                colors: [theme.accent.opacity(0.28), theme.accent.opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .overlay(Capsule().strokeBorder(theme.accent.opacity(0.34), lineWidth: 0.6))
                        // เรืองอ่อน ๆ ใต้ชิป ให้ลอยขึ้นจากพื้นการ์ดแทนที่จะแบนติดกัน
                        .shadow(color: theme.accent.opacity(0.22), radius: 8, y: 3)
                        .scrubVeil(scrub.d,
                                   lead: Scrub.lead(i, of: items.count, d: scrub.d, step: 0.07),
                                   drop: 26, pull: 10)
                }
            }
            .frame(maxHeight: .infinity, alignment: .leading)
        }
    }
}

// MARK: - เวลาที่รับงาน

/// วัน × ช่วงเวลาที่สะดวก — ตอบคำถาม "ติดต่อไปแล้วจะได้คิวเมื่อไหร่"
///
/// # ทำไมถึงไม่ใช่ตาราง
///
/// ของเดิมเป็นตาราง 7 × 4 ที่ทุกช่องมีน้ำหนักเท่ากัน: ช่องว่างเป็นแผ่นเรืองแสง ช่องไม่ว่างเป็นจุด
/// ผลคือแผ่นสี่เหลี่ยมมนสิบกว่าใบกระจายเต็มพื้นที่ อ่านออกมาเป็น **แดชบอร์ด** ไม่ใช่ตารางเวลา
/// และป้ายเวลาฝั่งซ้ายกินความกว้างไปเกือบหนึ่งในสี่เพื่อบอกสิ่งที่พูดได้ด้วยตัวเลขสองหลัก
///
/// แบบนี้เปลี่ยนหน่วยของการอ่านจาก "ช่อง" เป็น "วัน": หนึ่งวันคือหนึ่งแท่งตั้ง
/// ในแท่งมีสี่ปล้องไล่จากเช้าไปค่ำ ปล้องที่ว่างติดไฟ ที่เหลือเป็นร่องจาง
/// ตาจึงกวาดข้ามสัปดาห์ได้ในทีเดียวและเห็น "ลายของสัปดาห์" ทันที ว่าคนนี้ว่างเป็นทรงไหน
/// ส่วนคำตอบสั้น ๆ ("ว่าง จ–ส") ถูกดันขึ้นไปอยู่บนหัวเรื่อง เพราะแบรนด์ส่วนใหญ่อ่านแค่บรรทัดนั้น
///
/// # ท่าเปลี่ยนหน้า — "ไฟดับไล่ข้ามสัปดาห์"
///
/// ท่าเดิมที่ถูกอยู่แล้ว: ดับไล่ทีละวันตามทิศนิ้ว เหมือนกวาดมือผ่านแผงไฟ
/// ปล้องล่างของแต่ละแท่งหน่วงกว่าปล้องบนเล็กน้อย แท่งจึงดับจากหัวลงท้ายในตัวมันเอง
struct WorkScheduleWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    private var t: WorkTime { Mock.creator.workTime }

    /// เวลาเริ่มของแต่ละช่วง — ตัดจากชื่อย่อในโมเดล ไม่ประกาศตารางใหม่ให้หลุดกันทีหลัง
    private var hours: [String] { WorkTime.slotShort.map { String($0.prefix(2)) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WidgetLabel(text: "เวลาที่รับงาน", trailing: AnyView(summary))
                .scrubVeil(scrub.d, lead: 0.34, drop: 20, pull: 6)

            GeometryReader { geo in
                let cols = WorkTime.dayNames.count
                let rows = WorkTime.slotShort.count
                let axisW: CGFloat = 22
                let dayH: CGFloat = 16
                let gapX: CGFloat = 5
                let gapY: CGFloat = 5
                let colW = (geo.size.width - axisW - gapX * CGFloat(cols)) / CGFloat(cols)
                let trackH = max(30, geo.size.height - dayH - 5)
                let segH = (trackH - gapY * CGFloat(rows - 1)) / CGFloat(rows)

                ScrubReader(d: scrub.d) { d in
                    HStack(alignment: .top, spacing: gapX) {
                        axis(segH: segH, gapY: gapY, dayH: dayH, d: d)
                            .frame(width: axisW)
                        ForEach(0..<cols, id: \.self) { c in
                            column(c, w: colW, segH: segH, gapY: gapY,
                                   trackH: trackH, dayH: dayH, d: d)
                        }
                    }
                }
            }
        }
    }

    /// คำตอบสั้นที่สุดของ widget นี้ — วันที่ว่าง ไม่ใช่คำอธิบายสัญลักษณ์
    /// (ป้าย "= ว่างรับงาน" แบบเดิมอธิบายสิ่งที่สีมันบอกอยู่แล้ว แต่ไม่ได้เพิ่มข้อมูลอะไรเลย)
    private var summary: some View {
        Text("ว่าง \(t.daySummary)")
            .font(.sh(10.5, .bold))
            .foregroundStyle(theme.accent)
            .lineLimit(1).fixedSize()
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(Capsule().fill(theme.accent.opacity(0.15)))
            .overlay(Capsule().strokeBorder(theme.accent.opacity(0.3), lineWidth: 0.6))
    }

    /// แกนเวลาฝั่งซ้าย — เหลือแค่ชั่วโมงเริ่มของแต่ละช่วง
    /// ชื่อเต็ม ("09.00–12.00") ยาวกว่าที่มันเพิ่มความเข้าใจ เพราะปลายช่วงคือต้นของช่วงถัดไปอยู่แล้ว
    private func axis(segH: CGFloat, gapY: CGFloat, dayH: CGFloat, d: CGFloat) -> some View {
        VStack(spacing: gapY) {
            ForEach(Array(hours.enumerated()), id: \.offset) { r, h in
                Text(h)
                    .font(.sh(9, .medium))
                    .foregroundStyle(ink.text(t.slots.contains(r) ? 0.5 : 0.22))
                    .lineLimit(1).fixedSize()
                    .frame(height: segH, alignment: .center)
                    .opacity(Double(1 - Scrub.ease(Scrub.t(d, lead: 0.1 + Double(r) * 0.04))))
            }
            Color.clear.frame(height: dayH + 5)
        }
    }

    /// ช่วงเวลาที่ว่าง "ติดกัน" ถูกยุบเป็นก้อนเดียว
    ///
    /// นี่คือจุดที่แยกตารางเวลาออกจากตารางข้อมูล: คนไม่ได้อ่านว่า "ว่างช่อง 14–17 และช่อง 17+"
    /// แต่อ่านว่า "ว่างยาวตั้งแต่บ่ายถึงค่ำ" — ก้อนเดียวยาว ๆ พูดสิ่งนั้นได้ ส่วนสองก้อนที่มีร่องคั่น
    /// บังคับให้ตาต้องประกอบเอง และทำให้แท่งดูขาดเป็นท่อน
    private var freeRuns: [(start: Int, len: Int)] {
        var out: [(start: Int, len: Int)] = []
        var i = 0
        let n = WorkTime.slotShort.count
        while i < n {
            guard t.slots.contains(i) else { i += 1; continue }
            var len = 1
            while i + len < n, t.slots.contains(i + len) { len += 1 }
            out.append((start: i, len: len))
            i += len
        }
        return out
    }

    /// หนึ่งวัน = หนึ่งแท่ง — รางเปล่าทั้งวัน แล้วช่วงที่ว่างติดไฟทับลงไป
    ///
    /// เดิมวาดทุกช่องเป็นกระเบื้องขนาดเท่ากัน 28 ใบ ช่องที่ *ไม่* ว่างจึงดังเท่าช่องที่ว่าง
    /// ทั้งที่มันคือพื้นหลัง — แผงเลยอ่านออกมาเป็นตารางข้อมูล ตอนนี้ของที่ไม่ว่างคือ "ราง"
    /// ซึ่งเงียบและต่อเนื่อง ของที่ว่างคือ "แสง" ซึ่งเป็นชิ้นเดียวที่ตาต้องอ่าน
    private func column(_ c: Int, w: CGFloat, segH: CGFloat, gapY: CGFloat,
                        trackH: CGFloat, dayH: CGFloat, d: CGFloat) -> some View {
        let dayOn = t.days.contains(c)
        let a = Scrub.cell(c, of: WorkTime.dayNames.count, d: d, spill: 1.4)
        // แท่งผอมกว่าช่องที่ได้มา — แท่งกว้างเท่าช่องจะกลับไปอ่านเป็นกระเบื้องเหมือนเดิม
        let barW = min(w, 26)

        return VStack(spacing: 6) {
            ZStack(alignment: .top) {
                Capsule()
                    .fill(ink.fill(0.05))
                    .overlay(Capsule().strokeBorder(ink.line(0.07), lineWidth: 0.5))

                if dayOn {
                    ForEach(Array(freeRuns.enumerated()), id: \.offset) { i, run in
                        Capsule()
                            .fill(LinearGradient(colors: [theme.accentSoft, theme.accent],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(height: segH * CGFloat(run.len) + gapY * CGFloat(run.len - 1))
                            .offset(y: (segH + gapY) * CGFloat(run.start))
                            .shadow(color: theme.accent.opacity(0.45 * a), radius: 8, y: 3)
                            // ก้อนบนดับก่อนก้อนล่างครึ่งจังหวะ — แท่งจึงดับจากหัวลงท้ายในตัวมันเอง
                            .opacity(Scrub.cell(c, of: WorkTime.dayNames.count, d: d,
                                                lead: Double(i) * 0.04, spill: 1.4))
                            .scaleEffect(y: 0.86 + 0.14 * a, anchor: .top)
                    }
                }
            }
            .frame(width: barW, height: trackH)

            Text(WorkTime.dayNames[c])
                .font(.sh(9.5, dayOn ? .bold : .medium))
                .foregroundStyle(dayOn ? theme.accent : ink.text(0.25))
                .lineLimit(1).minimumScaleFactor(0.6)
                .frame(width: w, height: dayH)
                .opacity(a)
                .offset(y: (1 - a) * 8)
        }
        .frame(width: w)
    }
}

// MARK: - ประเภทคอนเทนต์ที่ถนัด

/// สี่ประเภทเรียงเป็นกริด — ตัวที่ไม่รับทำก็โชว์แบบจาง
/// เพราะแบรนด์ต้องรู้ทั้งสิ่งที่ทำได้และทำไม่ได้ก่อนจะทักมา
///
/// # ท่าเปลี่ยนหน้า — "ไทล์พลิกทีละใบ"
/// พลิกในช่องของตัวเองไล่กันตามทิศ · เครื่องหมายถูกเป็นชิ้นสุดท้ายที่หาย เพราะมันคือคำตอบ
struct WorkFormatWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    private var picked: [ContentFormat] { Mock.creator.formats }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            WidgetLabel(text: "ประเภทคอนเทนต์ที่ถนัด",
                        trailing: AnyView(Text("\(picked.count)/\(ContentFormat.allCases.count)")
                            .font(.sh(10.5, .bold))
                            .foregroundStyle(theme.accent.opacity(0.85))))
                .scrubVeil(scrub.d, lead: 0.34, drop: 20, pull: 6)

            GeometryReader { geo in
                let gap: CGFloat = 8
                let cols = geo.size.width > 250 ? 2 : 1
                let all = Array(ContentFormat.allCases.enumerated())
                let rows = Int(ceil(Double(all.count) / Double(cols)))
                let w = (geo.size.width - gap * CGFloat(cols - 1)) / CGFloat(cols)
                let h = (geo.size.height - gap * CGFloat(rows - 1)) / CGFloat(rows)

                VStack(spacing: gap) {
                    ForEach(0..<rows, id: \.self) { r in
                        HStack(spacing: gap) {
                            ForEach(all.dropFirst(r * cols).prefix(cols), id: \.element.id) { i, f in
                                tile(f, size: CGSize(width: w, height: h))
                                    .scrubLouver(scrub.d,
                                                 lead: Scrub.lead(i, of: all.count,
                                                                  d: scrub.d, step: 0.09),
                                                 angle: 48, shrink: 0.1)
                            }
                        }
                    }
                }
            }
        }
    }

    private func tile(_ f: ContentFormat, size: CGSize) -> some View {
        let on = picked.contains(f)
        // ช่องเตี้ยกว่านี้ใส่คำอธิบายไม่พอ — ตัดทิ้งดีกว่าปล่อยให้ล้นออกนอกกรอบ
        let compact = size.height < 86
        let shape = RoundedRectangle(cornerRadius: 15, style: .continuous)
        return VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                // ไอคอนเป็นแผ่นมนไล่เฉดสีประจำประเภท + เรืองแสงใต้แผ่น
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(on ? AnyShapeStyle(LinearGradient(
                        colors: [f.tint.opacity(0.95), f.tint.opacity(0.65)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(ink.fill(0.09)))
                    .frame(width: 30, height: 30)
                    .overlay {
                        // ไอคอนที่ "ทำได้" นั่งอยู่บนแผ่นสีอิ่ม จึงขาวเสมอทุกหมึก
                        // ส่วนที่ "ไม่ทำ" นั่งบนแผ่นจางของการ์ด ต้องพลิกตามหมึก
                        Image(systemName: f.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(on ? AnyShapeStyle(Color.white) : AnyShapeStyle(ink.text(0.25)))
                    }
                    .shadow(color: on ? f.tint.opacity(0.5) : .clear, radius: 9, y: 4)
                Spacer(minLength: 0)
                if on {
                    // คำตอบ "ทำได้" คือชิ้นสุดท้ายที่ควรหาย
                    SymbolIcon(name: SHIcon.check, size: 11, tint: f.tint)
                        .scrubVeil(scrub.d, lead: 0.42, drop: 16, pull: 6)
                }
            }
            Spacer(minLength: 0)
            Text(f.name)
                .font(.sh(12.5, .semibold))
                .foregroundStyle(ink.text(on ? 0.96 : 0.3))
                .lineLimit(1).minimumScaleFactor(0.7)
                .scrubVeil(scrub.d, lead: 0.16, drop: 20, pull: 8)
            if !compact {
                Text(f.detail)
                    .font(.sh(9))
                    .foregroundStyle(ink.text(on ? 0.45 : 0.18))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .scrubVeil(scrub.d, lead: 0.05, drop: 22, pull: 12)
            }
        }
        .padding(10)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .background(
            shape.fill(on ? AnyShapeStyle(LinearGradient(
                colors: [f.tint.opacity(0.2), f.tint.opacity(0.045)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
                : AnyShapeStyle(ink.fill(0.04)))
        )
        .clipShape(shape)
        .overlay(shape.strokeBorder(on ? f.tint.opacity(0.4) : ink.line(0.09), lineWidth: 0.7))
    }
}

// MARK: - ชิปที่ขึ้นบรรทัดเอง

/// เรียงชิปซ้าย→ขวา แล้วขึ้นบรรทัดใหม่เมื่อชนขอบ
///
/// ใช้ `Layout` ของจริงแทน LazyVGrid เพราะชิปกว้างไม่เท่ากัน — กริดคอลัมน์ตายตัว
/// จะทิ้งช่องว่างข้างชิปสั้น ๆ จนอ่านเป็นตารางแทนที่จะเป็นแท็ก
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0, x + s.width > maxW {
                x = 0; y += lineH + spacing; lineH = 0
            }
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
        return CGSize(width: maxW == .infinity ? x : maxW, height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > bounds.minX, x + s.width > bounds.maxX {
                x = bounds.minX; y += lineH + spacing; lineH = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
    }
}

struct FlowChips<Content: View>: View {
    let items: [String]
    var spacing: CGFloat = 6
    @ViewBuilder let chip: (String) -> Content

    var body: some View {
        FlowLayout(spacing: spacing) {
            ForEach(items, id: \.self) { chip($0) }
        }
    }
}
