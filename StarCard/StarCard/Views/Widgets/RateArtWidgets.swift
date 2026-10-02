import SwiftUI

// MARK: - สำรับ "เรตราคาแบบศิลป์"
//
// ป้ายไฟ — หน้าตาเดียวที่เพิ่มเข้าตระกูล `rate` ต่อจากป้ายห้อยราคา (`RateTagsWidget`)
// payload ก้อนเดิมทั้งหมด สลับแบบแล้วไม่มีฟิลด์ไหนหาย
//
// (เคยมีอีกสามแบบในไฟล์นี้ — ใบเสร็จ · ตราประทับ · บล็อกราคา — ถอดออกแล้ว)
//
// กติกาสามข้อของสำรับ "ปิดดีล" ยกมาทั้งดุ้น (ดู `BookingWidgets.swift`):
// 1. **หนึ่งแบบ หนึ่งวัสดุ** — ป้ายไฟคือแผ่นมืดกับหลอดเรืองแสง
// 2. **ท่าเปลี่ยนหน้าต้องมาจากวัสดุนั้น** — หลอดไฟดับไล่ทีละดวง
// 3. **ตัวเลขห้ามจางหาย** — ทุกราคาเดินผ่าน `DealPrice` ซึ่งบังคับมิเตอร์ (`ScrubDigits`) ให้
//
// ทำไมต้องมีตัวนี้: เรตราคาเป็นหน้าเดียวในการ์ดที่ผู้อ่านหยุดอ่านนานที่สุด (มันคือตัวเลขที่เขา
// ต้องเอาไปตัดสินใจ) แต่ป้ายห้อยราคาเป็นกระดาษขาว การ์ดที่ทั้งใบเป็นพื้นมืดจึงไม่มีเรต
// ที่เข้ากับหน้าตัวเองเลย — ตัวนี้เติมช่วงนั้น

// MARK: - ชิ้นส่วนร่วม

/// ราคาหนึ่งค่าพร้อมหน่วย — โครงกลางของตระกูล `rate`
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
    /// ราคาเป็นกล่องรวมสองก้อน (฿ + มิเตอร์ตัวเลข) — ช่องพิมพ์ประกาศที่ *กล่อง* ไม่ใช่ที่ก้อน
    /// ฟอนต์กับสีจึงต้องใส่เอง ตัวประกาศช่องใส่ให้ได้เฉพาะก้อนที่ไม่ได้ตั้งเอง
    @Environment(\.widgetTextStyle) private var tune
    @Environment(\.cardInk) private var ink
    @Environment(\.cardAccent) private var accent

    var body: some View {
        let price = Profile.me.ratePrice(index)
        let drop = max(14, size * 0.8)
        let color = tune.color(self.color, for: .ratePrices, index,
                               ink: ink, accent: accent) ?? self.color
        return HStack(alignment: .firstTextBaseline, spacing: 2) {
            // ฿ อยู่นอกช่องที่แก้ได้ — ค่าที่เก็บเป็นตัวเลขล้วน (ดู `Profile.ratePrice`)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("฿")
                    .font(tune.font(size, weight, for: .ratePrices, index))
                    .foregroundStyle(color)
                    .lineLimit(1).fixedSize()
                    .scrubVeil(scrub.d, lead: lead, drop: drop, pull: 0)
                ScrubDigits(text: Fmt.baht(price), d: scrub.d,
                            lead: lead, step: step, drop: drop)
                    .font(tune.font(size, weight, for: .ratePrices, index))
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

    /// ป้ายนี้ตั้งสีเอง (สีที่วาดกับสีของช่องต่างกันโดยตั้งใจ) จึงต้องถามสีที่ผู้ใช้เลือกเอง
    @Environment(\.widgetTextStyle) private var tune
    @Environment(\.cardInk) private var ink
    @Environment(\.cardAccent) private var accent

    var body: some View {
        let raw = Profile.me.rateLabel(index)
        return Text(upper ? raw.uppercased() : raw)
            .font(tune.font(size, weight, for: .rateLabels, index))
            .tracking(tracking)
            .foregroundStyle(tune.color(color, for: .rateLabels, index,
                                        ink: ink, accent: accent) ?? color)
            .lineLimit(1).minimumScaleFactor(0.5)
            .editableText(.rateLabels, index: index,
                          .init(size: size, weight: weight, color: slotColor ?? color,
                                tracking: tracking, uppercase: upper, corner: 4))
    }
}

/// เส้นประแนวนอน — มาสก์แถบทึบ ไม่ใช่ stroke dash
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

// MARK: - 01 · ป้ายไฟ

/// ป้ายไฟนีออนหน้าร้าน — แผ่นมืด หลอดเรืองแสงสีธีม ตัวเลขคือหลอด
///
/// ตัวนี้มีไว้สำหรับการ์ดสายกลางคืน/สายอีเวนต์ที่ทั้งใบเป็นพื้นมืด แล้วกระดาษขาวของเมนู
/// กับป้ายราคาไปเจาะรูสว่างกลางหน้าจนองค์ประกอบพัง — **มันคือเรตตัวเดียวในตู้ที่เป็นของมืด**
///
/// สามบรรทัดพอ ป้ายไฟที่มีสี่บรรทัดขึ้นไปกลายเป็นตารางเรืองแสง ซึ่งอ่านเป็นจอ LED
/// ไม่ใช่ป้ายหน้าร้าน — เรตที่เหลืออยู่ในโปรไฟล์ครบ ใบนี้เลือกมาสามบรรทัดบนสุด
///
/// # ท่าเปลี่ยนหน้า — "หลอดดับไล่ทีละดวง"
///
/// ความสว่างเป็นฟังก์ชันของระยะหน้าล้วน ๆ ไม่ใช่ไทม์เมอร์กะพริบ — ปัดค้างกลางทาง
/// ป้ายจึงหรี่ค้างอยู่ตรงนั้นจริง ๆ และปัดกลับหลอดติดคืนตามลำดับตรงข้าม
struct RateNeonWidget: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    private var rates: [RateItem] { Array(Profile.me.shownRates.prefix(3)) }

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
