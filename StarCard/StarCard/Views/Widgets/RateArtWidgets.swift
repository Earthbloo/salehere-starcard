import SwiftUI

// MARK: - สำรับ "เรตราคาแบบศิลป์"
//
// สี่หน้าตาที่เพิ่มเข้าตระกูล `rate` ต่อจากเมนูร้าน (`RateMenuWidget`) กับป้ายห้อยราคา
// (`RateTagsWidget`) — payload ก้อนเดิมทั้งหมด สลับแบบแล้วไม่มีฟิลด์ไหนหาย
//
// กติกาสามข้อของสำรับ "ปิดดีล" ยกมาทั้งดุ้น (ดู `BookingWidgets.swift`):
// 1. **หนึ่งแบบ หนึ่งวัสดุ** — ใบเสร็จ · ป้ายไฟ · หมึกประทับ · บล็อกสีพิมพ์
// 2. **ท่าเปลี่ยนหน้าต้องมาจากวัสดุนั้น** — ใบเสร็จถูกดึงขึ้นจากเครื่อง · หลอดไฟดับไล่ทีละดวง ·
//    ตรายกขึ้นจากกระดาษ · บล็อกเลื่อนสวนกันเหมือนแท่นพิมพ์แยกสี
// 3. **ตัวเลขห้ามจางหาย** — ทุกราคาเดินผ่าน `DealPrice` ซึ่งบังคับมิเตอร์ (`ScrubDigits`) ให้
//
// ทำไมเพิ่มอีกสี่: เรตราคาเป็นหน้าเดียวในการ์ดที่ผู้อ่านหยุดอ่านนานที่สุด (มันคือตัวเลขที่เขา
// ต้องเอาไปตัดสินใจ) แต่มีให้เลือกแค่สองหน้าตา ทั้งคู่เป็น "เอกสาร" — การ์ดสายอาร์ต
// จึงไม่มีเรตที่เข้ากับหน้าตัวเองเลย สี่ตัวนี้เติมช่วงนั้น: กระดาษบาง · แสง · หมึก · สีพิมพ์

// MARK: - ชิ้นส่วนร่วม

/// ราคาหนึ่งค่าพร้อมหน่วย — โครงเดียวที่ทั้งสี่แบบใช้ร่วมกัน
///
/// ประกาศที่เดียวเพราะกติกาข้อ 3 (ตัวเลขห้ามจางหาย) ต้อง *บังคับได้* ไม่ใช่หวังว่าแบบใหม่
/// ทุกตัวจะจำได้เอง — และเพราะกับดัก "฿฿35,000" (สัญลักษณ์เงินหลุดเข้าไปในช่องที่แก้ได้)
/// เคยเกิดมาแล้วทั้งในเมนูและป้ายราคา จึงแก้ครั้งเดียวตรงนี้แทนที่จะเขียนถูกซ้ำสี่รอบ
private struct DealPrice: View {
    let index: Int
    let unit: String
    var size: CGFloat
    var weight: Font.Weight = .black
    var color: Color = Deal.ink
    var unitColor: Color? = nil
    var unitSize: CGFloat? = nil
    /// สีของ *ช่องพิมพ์* — แยกจากสีที่วาด เพราะบางแบบไล่สีตามนิ้ว (ป้ายไฟ)
    /// ถ้าปล่อยให้ช่องพิมพ์เปลี่ยนสีทุกเฟรม preference ของช่องจะถูกยิงใหม่ทั้งหน้าตลอดการปัด
    var slotColor: Color? = nil
    var lead: Double = 0
    var step: Double = 0.035

    @Environment(\.pageScrub) private var scrub

    var body: some View {
        let price = Profile.me.ratePrice(index)
        let drop = max(14, size * 0.8)
        return HStack(alignment: .firstTextBaseline, spacing: 2) {
            // ฿ อยู่นอกช่องที่แก้ได้ — ค่าที่เก็บเป็นตัวเลขล้วน (ดู `Profile.ratePrice`)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("฿")
                    .font(.sh(size, weight))
                    .foregroundStyle(color)
                    .lineLimit(1).fixedSize()
                    .scrubVeil(scrub.d, lead: lead, drop: drop, pull: 0)
                ScrubDigits(text: Fmt.baht(price), d: scrub.d,
                            lead: lead, step: step, drop: drop)
                    .font(.sh(size, weight))
                    .foregroundStyle(color)
            }
            // ช่องพิมพ์ประกาศที่กล่องรวม ไม่ใช่ที่มิเตอร์ — มิเตอร์แตกตัวอักษรเป็นชิ้นละตัว
            // กรอบที่ได้จึงเล็กเกินกว่าจะแตะโดนจริง
            .editableText(.ratePrices, index: index,
                          .init(size: size, weight: weight,
                                color: slotColor ?? color, corner: 6))

            Text("/\(unit)")
                .font(.sh(unitSize ?? max(8, size * 0.34), .bold))
                .foregroundStyle(unitColor ?? color.opacity(0.55))
                .lineLimit(1).minimumScaleFactor(0.6)
                .layoutPriority(-1)
                .scrubVeil(scrub.d, lead: lead, drop: 14, pull: 4)
        }
        .lineLimit(1)
    }
}

/// ชื่อรายการหนึ่งบรรทัด — ย่อลงเมื่อยาว **ไม่ตัดด้วย …**
/// ชื่องานที่ถูกตัดกลางคำทำให้ทั้งใบตอบไม่ได้ว่าราคานี้คือราคาของอะไร
private struct DealLabel: View {
    let index: Int
    var size: CGFloat = 9
    var weight: Font.Weight = .heavy
    var color: Color = Deal.ink
    var slotColor: Color? = nil
    var tracking: CGFloat = 0.8
    var upper: Bool = true

    var body: some View {
        let raw = Profile.me.rateLabel(index)
        return Text(upper ? raw.uppercased() : raw)
            .font(.sh(size, weight)).tracking(tracking)
            .foregroundStyle(color)
            .lineLimit(1).minimumScaleFactor(0.5)
            .editableText(.rateLabels, index: index,
                          .init(size: size, weight: weight, color: slotColor ?? color,
                                tracking: tracking, uppercase: upper, corner: 4))
    }
}

/// เส้นประแนวนอน — ท่าเดียวกับเส้นประในเมนูราคา (มาสก์แถบทึบ ไม่ใช่ stroke dash)
/// เพราะ stroke dash ของ SwiftUI จะจัดจังหวะประใหม่ทุกครั้งที่ความกว้างเปลี่ยน
private struct DashRule: View {
    var color: Color
    var dash: CGFloat = 2
    var gap: CGFloat = 3

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 0.9)
            .mask {
                HStack(spacing: gap) {
                    ForEach(0..<90, id: \.self) { _ in Rectangle().frame(width: dash) }
                    Spacer(minLength: 0)
                }
            }
    }
}

// MARK: - 01 · ใบเสร็จ

/// กระดาษใบเสร็จจากเครื่องพิมพ์ความร้อน — ขอบล่างเป็นฟันฉีก มีบาร์โค้ดปิดท้าย
///
/// อุปมานี้ทำสิ่งที่เมนูร้านทำไม่ได้: เมนูบอกว่า "ของมีขายราคานี้" ส่วนใบเสร็จบอกว่า
/// **"ธุรกรรมนี้เกิดขึ้นจริงแล้ว"** — น้ำเสียงที่ต่างกันคนละเรื่องทั้งที่ตัวเลขชุดเดียวกัน
/// และเป็นน้ำเสียงที่ถูกที่สุดสำหรับครีเอเตอร์ที่รับงานมาแล้วหลายสิบชิ้น ไม่ใช่คนที่เพิ่งตั้งราคา
///
/// บรรทัดล่างสุดเป็น **ราคาต่ำสุดในรายการ** ไม่ใช่ผลรวม — ใบเสร็จจริงรวมยอดเพราะลูกค้า
/// ซื้อทุกบรรทัด แต่เรตการ์ดไม่ใช่ตะกร้าสินค้า ผลรวมของเรตทุกชิ้นเป็นตัวเลขที่ไม่มีความหมาย
/// และอ่านออกมาเหมือนราคาขั้นต่ำที่ต้องจ่าย ซึ่งเป็นความเข้าใจผิดที่แพงที่สุดที่ใบนี้ทำได้
///
/// # ท่าเปลี่ยนหน้า — "กระดาษถูกดึงขึ้นจากเครื่อง"
///
/// ทั้งใบเลื่อนขึ้นแล้วจางหาย ส่วนบรรทัดรายการถูกถอดไล่จากฝั่งที่หน้ากำลังไป
/// เหมือนม้วนกระดาษที่ถูกดึงกลับเข้าเครื่อง — ราคาไม่จาง แต่ถูกถอดทีละหลัก
struct RateReceiptWidget: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    private var rates: [RateItem] { Mock.creator.rates }

    /// ราคาต่ำสุดที่ยังพิมพ์ไม่เสร็จ (ค่าว่างระหว่างพิมพ์คืน 0) ไม่ถูกนับ
    /// ไม่งั้นบรรทัด "เริ่มต้นที่" จะกระโดดเป็น ฿0 ทุกครั้งที่ผู้ใช้ลบตัวเลขจนหมดช่อง
    private var lowest: Int {
        (0..<rates.count).map { Profile.me.ratePrice($0) }.filter { $0 > 0 }.min() ?? 0
    }

    var body: some View {
        ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d))
            paper
                .offset(y: -26 * t)
                .opacity(Scrub.fade(t, after: 0.74))
        }
    }

    private var paper: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("เรตราคา")
                    .font(.sh(10.5, .heavy)).tracking(1.8)
                Spacer(minLength: 4)
                Text("@\(Profile.me.handle)")
                    .font(.sh(9, .semibold))
                    .foregroundStyle(Deal.inkSoft)
            }
            .foregroundStyle(Deal.ink.opacity(0.88))
            .lineLimit(1).minimumScaleFactor(0.6)
            .padding(.bottom, 9)
            .scrubVeil(scrub.d, lead: 0.46, drop: 16, pull: 4)

            DashRule(color: Deal.ink.opacity(0.3))

            VStack(spacing: 0) {
                ForEach(Array(rates.enumerated()), id: \.element.id) { i, r in
                    line(r, i: i).frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            DashRule(color: Deal.ink.opacity(0.3))

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("เริ่มต้นที่")
                    .font(.sh(9.5, .bold)).tracking(1)
                    .foregroundStyle(Deal.inkSoft)
                Spacer(minLength: 4)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("฿").font(.sh(19, .black)).fixedSize()
                        .scrubVeil(scrub.d, lead: 0.06, drop: 18, pull: 0)
                    ScrubDigits(text: Fmt.baht(lowest), d: scrub.d,
                                lead: 0.06, step: 0.03, drop: 18)
                        .font(.sh(19, .black))
                }
                .foregroundStyle(Deal.ink)
                .lineLimit(1)
            }
            .padding(.top, 9)

            barcode.padding(.top, 11)
        }
        .padding(.horizontal, 15)
        .padding(.top, 13)
        // ล่างเผื่อฟันฉีกที่กินเนื้อกระดาษเข้ามา — ไม่เผื่อแล้วบาร์โค้ดจะโดนฟันกัดหาย
        .padding(.bottom, 17)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            // กระดาษความร้อนไม่ใช่กระดาษขาว — มันอมเหลืองและเข้มลงทางท้ายม้วน
            LinearGradient(colors: [Color(red: 0.99, green: 0.99, blue: 0.975),
                                    Color(red: 0.93, green: 0.92, blue: 0.895)],
                           startPoint: .top, endPoint: .bottom)
        }
        .clipShape(ReceiptPaper())
        .shadow(color: .black.opacity(0.34), radius: 11, y: 6)
    }

    private func line(_ r: RateItem, i: Int) -> some View {
        let lead = Scrub.lead(i, of: rates.count, d: scrub.d, step: 0.07)
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            // ฝั่งซ้ายมุดเป็นก้อนเดียว ส่วนราคาถือมิเตอร์ของตัวเอง — ห่อทั้งแถวด้วย veil เมื่อไหร่
            // ตัวเลขจะโดน transform สองชั้นจนอ่านไม่ออกว่ากำลังถูกถอดทีละหลัก
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(format: "%02d", i + 1))
                    .font(.sh(8.5, .bold))
                    .foregroundStyle(Deal.inkSoft.opacity(0.8))
                    .fixedSize()
                DealLabel(index: i, size: 11, weight: .semibold,
                          color: Deal.ink.opacity(0.92), tracking: 0, upper: false)
            }
            .scrubVeil(scrub.d, lead: lead, drop: 18, pull: 10)

            Spacer(minLength: 4)
            DealPrice(index: i, unit: r.unit, size: 13, weight: .heavy,
                      color: Deal.ink, unitColor: Deal.inkSoft, unitSize: 8.5,
                      lead: lead + 0.03)
        }
    }

    private var barcode: some View {
        // แท่งบาร์โค้ดคงที่ ไม่สุ่ม — การ์ดใบเดิมต้องหน้าตาเหมือนเดิมทุกครั้งที่เปิด
        // (กติกาเดียวกับองศาเอียงของป้ายราคาและสติกเกอร์สายงาน)
        let bars: [CGFloat] = [1, 3, 1, 2, 1, 1, 3, 1, 1, 2, 3, 1, 2, 1, 1, 3,
                               2, 1, 1, 2, 1, 3, 1, 1, 2, 1, 3, 2, 1, 1, 2, 3]
        return VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .bottom, spacing: 1.6) {
                ForEach(Array(bars.enumerated()), id: \.offset) { i, w in
                    Rectangle()
                        .fill(Deal.ink.opacity(i.isMultiple(of: 3) ? 0.88 : 0.68))
                        .frame(width: w, height: 20)
                }
            }
            Text("SALEHERE · \(Profile.me.handle.uppercased())")
                .font(.sh(7.5, .semibold)).tracking(2)
                .foregroundStyle(Deal.inkSoft)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .scrubVeil(scrub.d, lead: 0.08, drop: 24, pull: 12)
    }
}

/// กระดาษที่ขอบล่างเป็นฟันฉีก — รูปทรงจริง ไม่ใช่ลายที่วาดทับ
/// (วาดทับเมื่อไหร่ เงาของแผ่นจะยังเป็นสี่เหลี่ยมตรง แล้วตาจะจับได้ทันทีว่าเป็นสติกเกอร์)
private struct ReceiptPaper: Shape {
    var tooth: CGFloat = 9

    func path(in r: CGRect) -> Path {
        var p = Path()
        let base = r.maxY - tooth * 0.5
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: base))

        let n = max(4, Int(r.width / tooth))
        let w = r.width / CGFloat(n)
        // ไล่จากขวาไปซ้าย — ทิศเดียวกับที่เส้นรอบรูปกำลังเดินอยู่
        for i in stride(from: n - 1, through: 0, by: -1) {
            let x = r.minX + CGFloat(i) * w
            p.addLine(to: CGPoint(x: x + w * 0.5, y: r.maxY))
            p.addLine(to: CGPoint(x: x, y: base))
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - 02 · ป้ายไฟ

/// ป้ายไฟนีออนหน้าร้าน — แผ่นมืด หลอดเรืองแสงสีธีม ตัวเลขคือหลอด
///
/// ตัวนี้มีไว้สำหรับการ์ดสายกลางคืน/สายอีเวนต์ที่ทั้งใบเป็นพื้นมืด แล้วกระดาษขาวของเมนู
/// กับป้ายราคาไปเจาะรูสว่างกลางหน้าจนองค์ประกอบพัง — **มันคือเรตตัวเดียวในตู้ที่เป็นของมืด**
///
/// สามบรรทัดพอ ป้ายไฟที่มีสี่บรรทัดขึ้นไปกลายเป็นตารางเรืองแสง ซึ่งอ่านเป็นจอ LED
/// ไม่ใช่ป้ายหน้าร้าน — ใครต้องการครบทุกรายการให้สลับไปเมนูราคา payload ก้อนเดียวกัน
///
/// # ท่าเปลี่ยนหน้า — "หลอดดับไล่ทีละดวง"
///
/// ความสว่างเป็นฟังก์ชันของระยะหน้าล้วน ๆ ไม่ใช่ไทม์เมอร์กะพริบ — ปัดค้างกลางทาง
/// ป้ายจึงหรี่ค้างอยู่ตรงนั้นจริง ๆ และปัดกลับหลอดติดคืนตามลำดับตรงข้าม
struct RateNeonWidget: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    private var rates: [RateItem] { Array(Mock.creator.rates.prefix(3)) }

    /// สีหลอด — ใช้สีดิบเสมอ ป้ายไฟคือ *แสงที่เปล่งออกมา* ไม่ใช่หมึกที่พลิกตามพื้นการ์ด
    private var glow: Color { theme.rawAccent }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Circle()
                    .fill(glow)
                    .frame(width: 5, height: 5)
                    .shadow(color: glow, radius: 5)
                Text("เรตราคา")
                    .font(.sh(9, .heavy)).tracking(2.6)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.bottom, 11)
            .scrubVeil(scrub.d, lead: 0.48, drop: 14, pull: 4)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(rates.enumerated()), id: \.element.id) { i, r in
                    tube(r, i: i).frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            ZStack {
                shape.fill(Color(red: 0.055, green: 0.045, blue: 0.088))
                // แสงที่ผนังรับไว้ — ป้ายไฟจริงย้อมพื้นรอบตัวมันเสมอ
                shape.fill(RadialGradient(colors: [glow.opacity(0.24), .clear],
                                          center: .init(x: 0.14, y: -0.05),
                                          startRadius: 2, endRadius: 280))
            }
        }
        // หลอดขอบ — ไม่ clip ทับ ไม่งั้นแสงที่ล้นออกนอกขอบถูกตัดจนเหลือแค่เส้นสี
        .overlay {
            shape.strokeBorder(glow.opacity(0.5), lineWidth: 1)
                .shadow(color: glow.opacity(0.65), radius: 6)
        }
        .shadow(color: .black.opacity(0.42), radius: 14, y: 8)
    }

    private func tube(_ r: RateItem, i: Int) -> some View {
        let lead = Scrub.lead(i, of: rates.count, d: scrub.d, step: 0.09)
        return ScrubReader(d: scrub.d) { d in
            let lit = 1 - Double(Scrub.ease(Scrub.t(d, lead: lead)))
            VStack(alignment: .leading, spacing: 0) {
                DealLabel(index: i, size: 8.5, weight: .heavy,
                          color: glow.opacity(0.3 + 0.6 * lit),
                          slotColor: glow, tracking: 2.2)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    DealPrice(index: i, unit: r.unit, size: 26, weight: .black,
                              color: .white.opacity(0.22 + 0.78 * lit),
                              unitColor: .white.opacity(0.18 + 0.32 * lit),
                              unitSize: 9, slotColor: .white, lead: lead + 0.02)
                    Spacer(minLength: 0)
                }
                // เรืองสองชั้น: ไส้หลอดแคบ ๆ กับแสงฟุ้งกว้าง — ชั้นเดียวได้แค่ตัวหนังสือมีขอบเบลอ
                .shadow(color: glow.opacity(0.85 * lit), radius: 7)
                .shadow(color: glow.opacity(0.45 * lit), radius: 17)
            }
        }
    }
}

// MARK: - 03 · ตราประทับ

/// กระดาษหนากับ **ตรายางที่ประทับทับราคา** — ราคาแรกคือพระเอก ที่เหลือเป็นบรรทัดเล็กใต้เส้น
///
/// เมนูกับใบเสร็จให้ราคาทุกตัวน้ำหนักเท่ากัน ซึ่งถูกเมื่อผู้อ่านกำลัง *เทียบ* ราคา
/// แต่ครีเอเตอร์ส่วนใหญ่มีงานหลักอยู่หนึ่งอย่าง ที่เหลือคืองานพ่วง — ใบนี้พูดแทนกรณีนั้น:
/// **"ราคาเริ่มต้นคือเท่านี้ ที่เหลือคุยกันได้"** และตรายางคือสิ่งที่ทำให้ตัวเลขอ่านเป็น
/// ราคาที่ถูกอนุมัติแล้ว ไม่ใช่ตัวเลขที่เพิ่งพิมพ์ลงไป
///
/// ชื่อรายการของราคาพระเอกอยู่ **ในตรา** ไม่ใช่ใต้ตัวเลข — วางไว้ทั้งสองที่เมื่อไหร่
/// มันซ้ำกันเองในระยะสายตาเดียว
///
/// # ท่าเปลี่ยนหน้า — "ตรายกขึ้นจากกระดาษ"
///
/// ตราขยายพร้อมจางออกเหมือนถูกยกขึ้นมาใกล้ตา (ของที่เข้าใกล้ตาโตขึ้นและหลุดโฟกัส)
/// ส่วนกระดาษอยู่กับที่ — เพราะกระดาษไม่ได้ถูกยก
struct RateStampWidget: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    private var rates: [RateItem] { Mock.creator.rates }
    private var rest: [(offset: Int, element: RateItem)] {
        Array(rates.enumerated()).dropFirst().map { (offset: $0.offset, element: $0.element) }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            sheet
            stamp
                .padding(.top, 13)
                .padding(.trailing, 13)
        }
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("เรตเริ่มต้น")
                .font(.sh(9, .heavy)).tracking(2.2)
                .foregroundStyle(Deal.inkSoft)
                .scrubVeil(scrub.d, lead: 0.48, drop: 14, pull: 4)

            if let first = rates.first {
                DealPrice(index: 0, unit: first.unit, size: 38, weight: .black,
                          color: Deal.ink, unitColor: Deal.inkSoft, unitSize: 11,
                          lead: 0.06, step: 0.03)
                    .padding(.top, 3)
            }

            Spacer(minLength: 10)

            if !rest.isEmpty {
                DashRule(color: Deal.ink.opacity(0.24))
                    .padding(.bottom, 2)
                VStack(spacing: 0) {
                    ForEach(rest, id: \.element.id) { e in
                        minorLine(e.element, i: e.offset).frame(maxHeight: .infinity)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(colors: [Color(red: 0.985, green: 0.98, blue: 0.965),
                                        Color(red: 0.945, green: 0.935, blue: 0.915)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                // ลายน้ำ ฿ — ต้องยัง *อ่านออกว่าเป็นตัว ฿* ถึงจะเป็นลายน้ำ
                // เคยวางชิดมุมบนขวาแล้วโดนขอบตัดทั้งหัวและข้าง เหลือเป็นรอยเปื้อนรูปทรงประหลาด
                Text("฿")
                    .font(.sh(150, .black))
                    .foregroundStyle(Deal.ink.opacity(0.05))
                    .offset(x: 26, y: 26)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }

    private func minorLine(_ r: RateItem, i: Int) -> some View {
        let lead = Scrub.lead(i, of: rates.count, d: scrub.d, step: 0.06)
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            DealLabel(index: i, size: 10.5, weight: .semibold,
                      color: Deal.ink.opacity(0.78), tracking: 0, upper: false)
            Spacer(minLength: 4)
            DealPrice(index: i, unit: r.unit, size: 12, weight: .heavy,
                      color: Deal.ink.opacity(0.9), unitColor: Deal.inkSoft,
                      unitSize: 8, lead: lead + 0.03)
        }
    }

    /// ตรายาง — กรอบสองชั้น หมึกสีธีม เอียงคงที่
    /// ไม่ใส่คำว่า "อนุมัติ/รับรอง" เพราะไม่มีใครออกตรานี้ให้จริง — คำที่อ้างผู้ออกที่ไม่มีตัวตน
    /// คือสิ่งเดียวกับตรา "Verified" ปลอมที่ทั้งแอปพยายามไม่เป็น
    private var stamp: some View {
        // หมึกต้องเข้มพอบนกระดาษ — สีเน้นดิบของธีมสว่างหลายตัวจางจนตราอ่านเป็นรอยพิมพ์ผิด
        // `onLightSurface` คือตัวเดียวกับที่การ์ดใช้ทุกครั้งที่สีธีมต้องไปนั่งบนพื้นสว่าง
        let c = theme.rawAccent.onLightSurface()
        return ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d, lead: 0.1))
            VStack(spacing: 1) {
                Text("ยืนราคานี้")
                    .font(.sh(7.5, .heavy)).tracking(2)
                    .opacity(0.85)
                DealLabel(index: 0, size: 10.5, weight: .black,
                          color: c, tracking: 0.4)
                Text("RATE CARD")
                    .font(.sh(6.5, .bold)).tracking(1.8)
                    .opacity(0.7)
            }
            .foregroundStyle(c)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .frame(maxWidth: 132)
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(c, lineWidth: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(c.opacity(0.5), lineWidth: 0.8)
                    .padding(-3.5)
            }
            // หมึกยางไม่เคยติดเต็ม 100% — ความจางคือสิ่งที่ทำให้มันอ่านเป็นตรา ไม่ใช่ป้ายพิมพ์
            .opacity(0.84)
            .rotationEffect(.degrees(-11))
            .scaleEffect(1 + 0.42 * t)
            .opacity(Double(1 - t))
        }
        .fixedSize()
    }
}

// MARK: - 04 · บล็อกราคา

/// โปสเตอร์บล็อกสี — หนึ่งเรตหนึ่งแถบ ตัวเลขชิดขวา ไม่มีกรอบไม่มีกระดาษ
///
/// ตัวเดียวในตระกูลที่ **ไม่ใช่ของจับต้องได้** มันคืองานพิมพ์: บล็อกสีทึบ ตัวเลขหนัก
/// เลขลำดับกำกับหัวแถว — ภาษาของโปสเตอร์สวิสที่การ์ดสายดีไซน์ใช้กันทั้งใบ
/// เมนู/ใบเสร็จ/ป้าย เอาไปวางบนการ์ดแบบนั้นแล้วอ่านเป็นเอกสารที่หลงเข้ามา
///
/// สลับสีทีละแถบ (สีธีม → กระดาษ → หมึก → สีธีมอ่อน) เพราะแถบสีเดียวกันสี่แถบเรียงกัน
/// คือตาราง ไม่ใช่โปสเตอร์ — และการสลับทำให้ตาเห็น *ลำดับ* โดยไม่ต้องมีเส้นคั่น
///
/// # ท่าเปลี่ยนหน้า — "แท่นพิมพ์แยกสี"
///
/// แถบคู่-คี่เลื่อนสวนทางกัน เหมือนงานพิมพ์ที่เพลตแต่ละสีเลื่อนไม่ตรงกัน
/// ระยะเลื่อนต่างกันตามลำดับ ปัดกลับก็คลี่กลับตามลำดับตรงข้าม
struct RateBlockWidget: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    private var rates: [RateItem] { Mock.creator.rates }

    var body: some View {
        VStack(spacing: 3) {
            header
                .frame(height: 22)
            ForEach(Array(rates.enumerated()), id: \.element.id) { i, r in
                band(r, i: i).frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("เรตราคา")
                .font(.sh(10, .heavy)).tracking(2)
                .foregroundStyle(Deal.card)
            Spacer(minLength: 0)
            Text("\(rates.count) รายการ")
                .font(.sh(8.5, .bold)).tracking(0.6)
                .foregroundStyle(Deal.card.opacity(0.55))
        }
        .lineLimit(1)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Deal.ink)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .scrubSlide(scrub.d, travel: -70, lead: 0.4, fade: 0.72)
    }

    private func band(_ r: RateItem, i: Int) -> some View {
        let p = palette(i)
        let lead = Scrub.lead(i, of: rates.count, d: scrub.d, step: 0.06)
        // สลับทิศทีละแถบ · แถบล่างเดินไกลกว่าแถบบน — เพลตที่เลื่อนเท่ากันหมดอ่านเป็นภาพเดียวที่ถูกลาก
        let travel: CGFloat = (i.isMultiple(of: 2) ? -1 : 1) * (52 + CGFloat(i) * 16)
        return HStack(spacing: 10) {
            Text(String(format: "%02d", i + 1))
                .font(.sh(10, .black))
                .foregroundStyle(p.sub)
                .fixedSize()
            DealLabel(index: i, size: 11, weight: .heavy,
                      color: p.fg.opacity(0.9), tracking: 1.4)
            Spacer(minLength: 4)
            DealPrice(index: i, unit: r.unit, size: 22, weight: .black,
                      color: p.fg, unitColor: p.sub, unitSize: 8.5, lead: lead + 0.02)
        }
        .padding(.horizontal, 13)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(p.bg)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .scrubSlide(scrub.d, travel: travel, lead: lead, fade: 0.76)
    }

    /// สีของแถบที่ `i` — พื้น · ตัวอักษรหลัก · ตัวอักษรรอง
    private func palette(_ i: Int) -> (bg: Color, fg: Color, sub: Color) {
        switch i % 4 {
        case 0:  return (theme.rawAccent, Deal.ink, Deal.ink.opacity(0.5))
        case 1:  return (Deal.card, Deal.ink, Deal.inkSoft)
        case 2:  return (Deal.ink, Deal.card, Deal.card.opacity(0.5))
        default: return (theme.rawAccentSoft, Deal.ink, Deal.ink.opacity(0.5))
        }
    }
}
