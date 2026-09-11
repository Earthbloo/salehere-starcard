import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - สำรับ "ปิดดีล"
//
// สามตัวในไฟล์นี้ตอบคำถามที่ตู้เดิมไม่มีใครตอบ: **จ้างยังไง เท่าไหร่ ติดต่อใคร**
// (สเปกหมวด 1.3 · 5.1)
//
// เดิมหมวด "รับงาน" มีสองตัวคือ เวลาที่รับงาน กับ ประเภทคอนเทนต์ ซึ่งบอกได้แค่ว่า
// *ทำอะไรได้* การ์ดจึงจบลงโดยไม่มีปลายทางให้แบรนด์เดินต่อ — ไฟล์นี้คือปลายทางนั้น
//
// กติกาสองข้อยกมาจากสำรับ Gen Z ชุดแรกทั้งดุ้น:
// 1. **หนึ่งแบบ หนึ่งวัสดุ** — เมนูร้าน · นามบัตรกระจก · บัตรกระดาษ
// 2. **ท่าเปลี่ยนหน้าต้องมาจากวัสดุนั้น** — เมนูต้องถูกขีดออกทีละบรรทัด
//    บัตรต้องถูกพลิกเก็บ
//
// ข้อสามที่เพิ่มมาเฉพาะไฟล์นี้ เพราะมันคือหมวดที่เกี่ยวกับเงิน:
// 3. **ตัวเลขห้ามจางหาย** — ราคาทุกตัวใช้มิเตอร์ถอดทีละหลัก (`ScrubDigits`)
//    ราคาที่เลือนหายไปกลางทางอ่านเป็น "ยังไม่แน่ใจ" ซึ่งเป็นสิ่งสุดท้ายที่เรตการ์ดควรสื่อ

/// วัสดุของสำรับนี้ — สีคงที่ ไม่พลิกตามหมึกการ์ด
/// (เหตุผลเดียวกับกระดาษโน้ตในสำรับแรก: ฉลากที่พลิกเป็นสีดำตามการ์ด ไม่ใช่ฉลากอีกต่อไป)
enum Deal {
    /// หมึกดำอมม่วงบนวัสดุสีสด
    static let ink = Color(red: 0.10, green: 0.07, blue: 0.14)
    static let inkSoft = Color(red: 0.38, green: 0.33, blue: 0.44)
    /// กระดาษบัตร
    static let card = Color(red: 0.98, green: 0.98, blue: 0.97)
}

// MARK: - 01 · เมนูราคา

/// เรตการ์ดในหน้าตาของ **เมนูร้าน** — ชื่อรายการซ้าย ราคาขวา คั่นด้วยเส้นประ
///
/// เลือกอุปมานี้เพราะเมนูคือเอกสารเดียวที่ทุกคนอ่านออกโดยไม่ต้องมีหัวข้อกำกับ
/// และมันสื่อสิ่งที่เรตการ์ดต้องสื่อพอดี: **ราคานี้คือของที่ตั้งไว้แล้ว ไม่ใช่ของที่ต่อรองกันหน้างาน**
///
/// เดิมมีบรรทัดจิ๋วใต้ราคาบอก "ราคาที่ตลาดจ่าย" (`Mock.creator.marketRate`) และมีชิปที่หัว
/// widget กำกับว่าราคาชุดนี้มีค่าที่ระบบแนะนำเทียบอยู่ — **ถอดออกทั้งคู่แล้ว** ราคาบนใบนี้
/// จึงเป็นราคาที่เจ้าตัวตั้งล้วน ๆ (ฟังก์ชันคำนวณยังอยู่ในโมเดล ไม่มีวิวไหนเรียกใช้)
///
/// # ท่าเปลี่ยนหน้า — "เมนูถูกขีดออกทีละบรรทัด"
///
/// เส้นประหดกลับเข้าหาชื่อรายการก่อน แล้วบรรทัดถึงมุดใต้ขอบตามไป ไล่จากฝั่งที่หน้ากำลังไป
/// ราคาไม่จาง แต่ถูกถอดทีละหลัก
struct RateMenuWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    private var rates: [RateItem] { Mock.creator.rates }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetLabel(text: "เรตราคา")
                .scrubVeil(scrub.d, lead: 0.38, drop: 20, pull: 6)

            VStack(spacing: 0) {
                ForEach(Array(rates.enumerated()), id: \.element.id) { i, r in
                    row(r, i: i, lead: Scrub.lead(i, of: rates.count, d: scrub.d, step: 0.08))
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func row(_ r: RateItem, i: Int, lead: Double) -> some View {
        let price = Profile.me.ratePrice(i)
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(Profile.me.rateLabel(i))
                .font(.sh(12.5, .semibold))
                .foregroundStyle(ink.text(0.9))
                .lineLimit(1).fixedSize()
                .editableText(.rateLabels, index: i,
                              .init(size: 12.5, weight: .semibold, color: ink.text(0.9)))

            // เส้นประ — หดกลับเข้าหาชื่อรายการตามนิ้ว
            ScrubReader(d: scrub.d) { d in
                let t = Scrub.ease(Scrub.t(d, lead: lead))
                Rectangle()
                    .fill(ink.line(0.22))
                    .frame(height: 0.8)
                    .mask {
                        HStack(spacing: 3) {
                            ForEach(0..<40, id: \.self) { _ in
                                Rectangle().frame(width: 2)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .scaleEffect(x: max(0, 1 - t), anchor: .leading)
            }
            .frame(height: 1)
            .offset(y: -3)

            VStack(alignment: .trailing, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    // ฿ แยกออกจากช่องที่แก้ได้ — ไม่งั้นพิมพ์ราคาใหม่แล้วได้ "฿฿35000"
                    // (ท่าเดียวกับตัว @ ในคิวอาร์การ์ด)
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        // fixedSize บังคับไว้ — ตัวเดียวในแถวที่ยืดหดได้จะถูกบีบจนหายไป
                        // เมื่อชื่อรายการ+ราคา+หน่วยรวมกันเบียดความกว้าง (SwiftUI ตัด Text
                        // ที่เหลือ 0pt ทิ้งทั้งตัวโดยไม่เตือน — เห็นเป็นราคาที่ไม่มีสัญลักษณ์เงิน)
                        Text("฿")
                            .font(.sh(14.5, .heavy))
                            .foregroundStyle(ink.text(0.98))
                            .lineLimit(1).fixedSize()
                            .scrubVeil(scrub.d, lead: lead + 0.04, drop: 20, pull: 0)
                        ScrubDigits(text: Fmt.baht(price), d: scrub.d,
                                    lead: lead + 0.04, step: 0.04, drop: 20)
                            .font(.sh(14.5, .heavy))
                            .foregroundStyle(ink.text(0.98))
                    }
                    // ช่องพิมพ์ประกาศที่กล่องรวม ไม่ใช่ที่มิเตอร์ตัวเลข — มิเตอร์แตกตัวอักษร
                    // เป็นชิ้นละตัวและมีหน้ากากของตัวเอง กรอบที่ได้จึงเล็กเกินกว่าจะแตะโดนจริง
                    // (ค่าที่แก้ยังเป็นตัวเลขล้วน ฿ แค่อยู่ในกรอบเดียวกัน)
                    .editableText(.ratePrices, index: i,
                                  .init(size: 14.5, weight: .heavy, color: ink.text(0.98)))
                    Text("/\(r.unit)")
                        .font(.sh(9.5, .medium))
                        .foregroundStyle(ink.text(0.4))
                        .scrubVeil(scrub.d, lead: lead, drop: 14, pull: 4)
                }
            }
            .fixedSize()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 02 · ป้ายราคา

/// เรตราคาชุดเดียวกับเมนู แต่เป็น **ป้ายห้อยราคาในร้าน** — กระดาษแข็งใบละหนึ่งเรต
/// หัวป้ายสีสด ตัวเลขยักษ์เต็มใบ เอียงคนละองศาเหมือนป้ายที่ห้อยอยู่จริง
///
/// ทำไมอุปมานี้ถึงเป็นตัวที่ถูกสำหรับสำเนียง Gen Z: เมนูร้านอ่านเป็น *เอกสาร* — ตาไล่จากบนลงล่าง
/// ทีละบรรทัดจนจบ ส่วนป้ายราคาอ่านเป็น *ของ* — ตาจับตัวเลขก่อนแล้วค่อยย้อนขึ้นไปอ่านว่าราคาอะไร
/// ซึ่งตรงกับวิธีที่คนรุ่นนี้เปิดพอร์ตในมือถือ: เลื่อนเร็ว หยุดที่ตัวเลข แล้วค่อยอ่านรายละเอียด
///
/// และมันยังพูดสิ่งเดียวกับที่เมนูพูด — **ราคานี้ติดไว้แล้ว ไม่ใช่ของที่ต่อรองกันหน้างาน**
/// ป้ายในร้านคือวัตถุที่สื่อความนี้แรงที่สุดเท่าที่มี จึงไม่ได้แลกความหมายทิ้งเพื่อความสนุก
///
/// ฟิลด์ครบชุดเดียวกับ `RateMenuWidget` ทุกตัว (สัญญาของตระกูล `rate`):
/// ชื่อรายการ · ราคา · หน่วย · ราคาที่ตลาดจ่าย — สลับแบบแล้วไม่มีอะไรหายไป
///
/// # ท่าเปลี่ยนหน้า — "ป้ายแกว่งรอบรูเจาะแล้วร่วง"
///
/// จุดหมุนอยู่ที่ **รูเจาะ** ไม่ใช่กลางใบ เพราะของที่ห้อยอยู่หมุนรอบจุดที่มันเกาะเสมอ —
/// หมุนรอบกลางใบเมื่อไหร่ ตาจะอ่านว่า "ภาพถูกหมุน" ไม่ใช่ "ป้ายแกว่ง"
/// ราคาไม่จางตามใบ แต่ถูกถอดทีละหลักด้วยมิเตอร์ (กติกาข้อ 3 ของไฟล์นี้)
struct RateTagsWidget: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    /// **สองใบเท่านั้น** — ป้ายคือของที่ตาจับทีละใบ ไม่ใช่ตารางที่ไล่อ่านจนจบ
    ///
    /// สี่ใบเมื่อไหร่มันกลายเป็นกริดราคา ซึ่งเมนู (`RateMenuWidget`) ทำได้ดีกว่าอยู่แล้ว
    /// และตัวเลขทั้งสี่แย่งความเด่นกันเองจนไม่เหลือใบไหนที่ตาไปหยุด
    /// การ์ดที่ต้องโชว์เรตครบทุกรายการให้สลับไปใช้เมนู — payload ก้อนเดียวกัน ไม่มีอะไรหาย
    private var rates: [RateItem] { Array(Mock.creator.rates.prefix(2)) }

    /// องศาเอียงตั้งต้น — คงที่ ไม่สุ่ม การ์ดใบเดิมต้องหน้าตาเหมือนเดิมทุกครั้งที่เปิด
    /// (กติกาเดียวกับ `StickerTags`)
    private let tilt: [Double] = [-2.6, 2.0]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            WidgetLabel(text: "เรตราคา")
                .scrubVeil(scrub.d, lead: 0.42, drop: 20, pull: 6)

            GeometryReader { geo in
                // สองใบต่อแถวเมื่อกว้างพอ · แคบกว่านั้นเรียงเดี่ยว — ป้ายที่แคบกว่า ~120pt
                // ตัวเลขจะเล็กจนแพ้หัวป้าย ซึ่งกลับหัวกลับหางกับเหตุผลที่แบบนี้มีอยู่
                let cols = geo.size.width >= 250 ? 2 : 1
                let gap: CGFloat = 9
                let tagW = (geo.size.width - gap * CGFloat(cols - 1)) / CGFloat(cols)

                VStack(spacing: gap) {
                    ForEach(Array(rows(cols).enumerated()), id: \.offset) { _, row in
                        HStack(spacing: gap) {
                            ForEach(row, id: \.item.id) { e in
                                tag(e.item, i: e.index, width: tagW)
                            }
                            // ช่องว่างของแถวสุดท้ายที่ไม่เต็ม — ไม่งั้นป้ายใบเดียวจะยืดกินทั้งแถว
                            if row.count < cols {
                                Color.clear.frame(width: tagW)
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }
    }

    /// ซอยเรตเป็นแถวละ `n` ใบ โดยยังถือ index เดิมไว้ — ลำดับของท่าต้องนับจากทั้งแผง
    /// ไม่ใช่นับใหม่ทุกแถว ไม่งั้นใบซ้ายของทุกแถวจะออกพร้อมกันเป็นคอลัมน์
    private func rows(_ n: Int) -> [[(index: Int, item: RateItem)]] {
        let all = rates.enumerated().map { (index: $0.offset, item: $0.element) }
        return stride(from: 0, to: all.count, by: n).map {
            Array(all[$0..<min($0 + n, all.count)])
        }
    }

    private func tag(_ r: RateItem, i: Int, width: CGFloat) -> some View {
        let lead = Scrub.lead(i, of: rates.count, d: scrub.d, step: 0.07)
        return ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d, lead: lead))
            let s = Double(Scrub.dir(d))
            face(r, i: i, width: width, lead: lead)
                .rotationEffect(.degrees(tilt[i % tilt.count] + s * 15 * Double(t)),
                                anchor: .init(x: 0.1, y: 0.14))
                .offset(y: 30 * t)
                .opacity(Scrub.fade(t, after: 0.74))
        }
        .frame(width: width)
    }

    private func face(_ r: RateItem, i: Int, width: CGFloat, lead: Double) -> some View {
        // ตัวเลขโตตามใบ แต่มีเพดานทั้งบนและล่าง — ป้ายที่ตัวเลขล้นขอบอ่านเป็นงานพัง ไม่ใช่งานกล้า
        let priceSize = min(30, max(13, width * 0.16))
        let price = Profile.me.ratePrice(i)

        return VStack(alignment: .leading, spacing: 0) {
            head(r, i: i)

            VStack(alignment: .leading, spacing: 2) {
                Spacer(minLength: 2)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    // ฿ อยู่นอกช่องที่แก้ได้ — ค่าที่เก็บคือตัวเลขล้วน (ดู `Profile.ratePrice`)
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("฿")
                            .font(.sh(priceSize, .black))
                            .foregroundStyle(Deal.ink)
                            .lineLimit(1).fixedSize()
                            .scrubVeil(scrub.d, lead: lead + 0.05, drop: 22, pull: 0)
                        ScrubDigits(text: Fmt.baht(price), d: scrub.d,
                                    lead: lead + 0.05, step: 0.035, drop: 22)
                            .font(.sh(priceSize, .black))
                            .foregroundStyle(Deal.ink)
                    }
                    .editableText(.ratePrices, index: i,
                                  .init(size: priceSize, weight: .black,
                                        color: Deal.ink, corner: 6))
                    Text("/\(r.unit)")
                        .font(.sh(9.5, .bold))
                        .foregroundStyle(Deal.inkSoft)
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .layoutPriority(-1)
                        .scrubVeil(scrub.d, lead: lead, drop: 14, pull: 4)
                }
                .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.top, 7)
            .padding(.bottom, 9)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxHeight: .infinity)
        .background(Deal.card)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .shadow(color: .black.opacity(0.32), radius: 9, y: 5)
    }

    /// หัวป้าย — แถบสีธีมที่มีรูเจาะกับชื่อรายการ
    ///
    /// ใช้สีดิบ (`rawAccent`) เหมือนทุกวัสดุที่เป็นของจับต้องได้ในสำรับนี้:
    /// แถบสีคือ *สีที่พิมพ์ลงบนกระดาษ* ไม่ใช่หมึกที่พลิกตามพื้นการ์ด
    private func head(_ r: RateItem, i: Int) -> some View {
        HStack(spacing: 6) {
            // รูเจาะ — จุดที่ป้ายห้อยอยู่ และเป็นจุดหมุนของท่าแกว่ง
            Circle()
                .fill(Deal.ink.opacity(0.3))
                .frame(width: 7, height: 7)
                .overlay(Circle().strokeBorder(.white.opacity(0.45), lineWidth: 0.8))

            // ชื่อรายการยาวเกินหัวป้าย **ย่อลง ไม่ตัดด้วย …** — ชื่องานที่ถูกตัดกลางคำ
            // ทำให้ป้ายทั้งใบตอบไม่ได้ว่าราคานี้คือราคาของอะไร
            Text(Profile.me.rateLabel(i).uppercased())
                .font(.sh(9, .heavy)).tracking(0.8)
                .foregroundStyle(Deal.ink.opacity(0.88))
                .lineLimit(1).minimumScaleFactor(0.5)
                .editableText(.rateLabels, index: i,
                              .init(size: 9, weight: .heavy, color: Deal.ink.opacity(0.88),
                                    tracking: 0.8, uppercase: true, corner: 4))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9).padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [theme.rawAccent, theme.rawAccentSoft],
                           startPoint: .leading, endPoint: .trailing)
        )
    }
}

// MARK: - 07 · นามบัตร

/// สเปก 1.3 — เบอร์ · อีเมล · ไลน์ บนแผ่นกระจก
///
/// สามฟิลด์นี้ถูกอ่านพร้อมกันเสมอ จึงเป็นบัตรใบเดียว ไม่ใช่สาม widget
///
/// เคยมีแถบหัวบัตร (รูป + ชื่อ + ตำแหน่ง + เวลาตอบกลับ) แต่ถูกถอดออกทั้งแถบ —
/// รูปกับชื่อซ้ำกับ hero ที่อยู่บนการ์ดอยู่แล้ว ส่วนตำแหน่งกับเวลาตอบกลับเป็นบริบท
/// ที่มาแย่งความสนใจจากสิ่งเดียวที่บัตรนี้มีหน้าที่ส่งมอบ: **ค่าที่ต้องก็อปไปใช้**
///
/// # ท่าเปลี่ยนหน้า — "บรรทัดติดต่อถูกปิดทีละช่อง"
/// สามช่องทางติดต่อที่ทุกแบบในตระกูล `contact` ต้องแสดงเท่ากัน
///
/// ประกาศไว้ที่เดียวเพราะห้าแบบในตระกูลนี้เคยเขียนลิสต์เดียวกันซ้ำห้ารอบ —
/// เพิ่มช่องทางที่หกวันไหนต้องไล่แก้ห้าที่ และถ้าลืมที่ไหนที่นั่นผิดสัญญาตระกูลทันที
/// (กติกาใน `WidgetContent.swift`: ทุกแบบในตระกูลต้องอ่าน payload ก้อนเดียวกัน)
struct ContactLine {
    let label: String
    let icon: String
    let field: ProfileField

    static let all: [ContactLine] = [
        .init(label: "โทร",  icon: "phone.fill",   field: .phone),
        .init(label: "อีเมล", icon: "envelope.fill", field: .email),
        .init(label: "LINE", icon: "message.fill",  field: .lineId),
    ]
}

struct ContactCardWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(spacing: 0) {
                ForEach(Array(ContactLine.all.enumerated()), id: \.offset) { i, l in
                    HStack(spacing: 10) {
                        Text(l.label)
                            .font(.sh(10.5, .semibold))
                            .foregroundStyle(ink.text(0.42))
                            .frame(width: 38, alignment: .leading)
                        Text(Profile.me.text(l.field))
                            .font(.sh(13, .bold))
                            .foregroundStyle(ink.text(0.95))
                            .lineLimit(1).truncationMode(.tail)
                            .editableText(l.field, .init(size: 13, weight: .bold,
                                                         color: ink.text(0.95)))
                        Spacer(minLength: 0)
                    }
                    .frame(maxHeight: .infinity)
                    .scrubVeil(scrub.d,
                               lead: Scrub.lead(i, of: ContactLine.all.count, d: scrub.d, step: 0.08),
                               drop: 22, pull: 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - 08 · คิวอาร์การ์ด

/// บัตรกระดาษพร้อม QR จริง — สแกนแล้วเปิดการ์ดใบนี้ได้
///
/// ตอบข้อ E4 ในเอกสารคอนเซปต์ (QR ในงานอีเวนต์) และเป็นทางเดียวที่การ์ดข้ามจาก
/// หน้าจอไปอยู่บนของพิมพ์ได้โดยไม่ตาย — โปสเตอร์ บูธ นามบัตรกระดาษ
///
/// QR สร้างด้วย CoreImage จริง ไม่ใช่ลายตกแต่ง เพราะ QR ปลอมบนบัตรที่ขายเรื่อง
/// "ของจริงตรวจสอบได้" คือความขัดแย้งที่ไม่ควรมีตั้งแต่ต้น
///
/// # ท่าเปลี่ยนหน้า — "บัตรถูกพลิกเก็บ"
struct ContactQRWidget: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    private var link: String { "https://salehere.co.th/star/\(Profile.me.handle)" }

    var body: some View {
        ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d))
            let s = Double(Scrub.dir(d))
            card
                .rotation3DEffect(.degrees(-s * 58 * Double(t)),
                                  axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                .scaleEffect(1 - 0.1 * t)
                .opacity(Scrub.fade(t, after: 0.7))
        }
    }

    private var card: some View {
        VStack(spacing: 9) {
            Spacer(minLength: 0)

            QRCode(text: link, tint: Deal.ink)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 118)
                .scrubAperture(scrub.d, lead: 0.1, feather: 0.2, dim: 0.35)

            VStack(spacing: 1) {
                // ตัว @ ไม่ใช่ส่วนหนึ่งของค่า — แยกออกจากช่องที่แก้ได้ ไม่งั้นพิมพ์แล้วได้ "@@nira"
                HStack(spacing: 0) {
                    Text("@").font(.sh(11.5, .heavy)).foregroundStyle(Deal.ink)
                    Text(Profile.me.handle)
                        .font(.sh(11.5, .heavy))
                        .foregroundStyle(Deal.ink)
                        .lineLimit(1).truncationMode(.tail)
                        .editableText(.handle, .init(size: 11.5, weight: .heavy, color: Deal.ink))
                }
                Text("สแกนเพื่อดูการ์ดเต็ม")
                    .font(.sh(8.5, .semibold))
                    .foregroundStyle(Deal.inkSoft)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .scrubVeil(scrub.d, lead: 0.28, drop: 16, pull: 6)

            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Deal.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .top) {
            // แถบสีธีมที่หัวบัตร — ที่เดียวที่บัตรกระดาษยอมรับสีของการ์ด
            Rectangle().fill(theme.rawAccent).frame(height: 5)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
        }
        .shadow(color: .black.opacity(0.35), radius: 12, y: 7)
    }
}

/// QR ของจริงจาก CoreImage — เรนเดอร์ครั้งเดียวแล้วแคชไว้ตามข้อความ
///
/// ใช้ `interpolation(.none)` เพราะ QR ที่ถูก smooth ตอนขยาย จะสแกนยากขึ้นจริง
/// ไม่ใช่แค่ดูฟุ้ง — ตัวอ่านต้องการขอบคมเพื่อแยกโมดูล
struct QRCode: View {
    let text: String
    var tint: Color = .black

    @State private var image: UIImage?

    init(text: String, tint: Color = .black) {
        self.text = text
        self.tint = tint
        // สร้างตั้งแต่เกิด ไม่รอ .task — CIFilter เร็วระดับมิลลิวินาทีและมีแคชกันซ้ำ
        // จำเป็นกับตอนอบรูปเทมเพลตด้วย: ImageRenderer เรนเดอร์เฟรมเดียวจบ ไม่รัน .task
        // ถ้ารอ task ตัว QR จะอบออกมาเป็นแผ่นขาวเปล่าติดถาวร
        _image = State(initialValue: QRCode.render(text))
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
    }

    private static var cache: [String: UIImage] = [:]

    private static func render(_ text: String) -> UIImage? {
        if let hit = cache[text] { return hit }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let out = filter.outputImage else { return nil }
        let scaled = out.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        let ctx = CIContext()
        guard let cg = ctx.createCGImage(scaled, from: scaled.extent) else { return nil }
        // ห้ามใส่ .alwaysTemplate — ภาพจาก CIQRCodeGenerator ทึบทั้งใบ (ทั้งโมดูลดำและพื้นขาว)
        // ย้อมเป็นสีเดียวเมื่อไหร่ QR กลายเป็นบล็อกทึบที่สแกนไม่ได้ทันที
        let ui = UIImage(cgImage: cg)
        cache[text] = ui
        return ui
    }
}

// MARK: - 09 · แถบติดต่อ

/// ช่องทางติดต่อทั้งหมดในบรรทัดเดียว — ตัวมินิมอลที่สุดในตระกูล
///
/// ไม่มีกรอบ ไม่มีป้ายกำกับ ไม่มีไอคอน เหลือแค่ค่าจริงคั่นด้วยจุด
/// ใช้ปิดท้ายหน้าที่แน่นอยู่แล้ว โดยไม่แย่งพื้นที่จากของข้างบน
///
/// # ท่าเปลี่ยนหน้า — "บรรทัดไถลออกข้าง"
struct ContactBarWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    var body: some View {
        HStack(spacing: 9) {
            ForEach(Array(ContactLine.all.enumerated()), id: \.offset) { i, l in
                if i > 0 {
                    Circle().fill(ink.text(0.22)).frame(width: 2.5, height: 2.5)
                }
                Text(Profile.me.text(l.field))
                    .font(.sh(12, .semibold))
                    .foregroundStyle(ink.text(0.78))
                    .lineLimit(1).truncationMode(.tail)
                    .editableText(l.field, .init(size: 12, weight: .semibold,
                                                 color: ink.text(0.78)))
                    .scrubSlide(scrub.d, travel: 50 + CGFloat(i) * 16,
                                lead: Scrub.lead(i, of: ContactLine.all.count, d: scrub.d, step: 0.07),
                                fade: 0.55)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - 10 · สามบรรทัด

/// ช่องทางติดต่อเรียงเป็นสามบรรทัด มีเส้นคั่นบาง ๆ — ไม่มีรูป ไม่มีกรอบ
///
/// ต่างจากนามบัตรตรงที่นามบัตรมีรูป ชื่อ และตำแหน่ง ส่วนตัวนี้เหลือเฉพาะ *ค่าที่ต้องก็อป*
/// เหมาะกับการ์ดที่มี hero อยู่ข้างบนแล้ว — ชื่อกับรูปถูกเล่าไปแล้วหนึ่งรอบ ไม่ต้องเล่าซ้ำ
///
/// # ท่าเปลี่ยนหน้า — "บรรทัดมุดใต้ขอบทีละบรรทัด"
struct ContactStackWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(ContactLine.all.enumerated()), id: \.offset) { i, l in
                HStack(spacing: 12) {
                    Text(l.label)
                        .font(.sh(10.5, .semibold))
                        .foregroundStyle(ink.text(0.4))
                        .frame(width: 40, alignment: .leading)
                    Text(Profile.me.text(l.field))
                        .font(.sh(14, .bold))
                        .foregroundStyle(ink.text(0.94))
                        .lineLimit(1).truncationMode(.tail)
                        .editableText(l.field, .init(size: 14, weight: .bold,
                                                     color: ink.text(0.94)))
                    Spacer(minLength: 0)
                }
                .frame(maxHeight: .infinity)
                .overlay(alignment: .top) {
                    if i > 0 {
                        Rectangle().fill(ink.line(0.1)).frame(height: 0.7)
                    }
                }
                .scrubVeil(scrub.d,
                           lead: Scrub.lead(i, of: ContactLine.all.count, d: scrub.d, step: 0.08),
                           drop: 24, pull: 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 11 · ไลน์ตัวใหญ่

/// ช่องทางเดียวตัวใหญ่ — ไลน์ เพราะดีลในไทยจบที่ไลน์เกือบทั้งหมด
///
/// การ์ดที่ให้สามช่องทางเท่า ๆ กันคือการ์ดที่ไม่ได้บอกว่า *ควรทักช่องไหน*
/// ตัวนี้ตอบข้อนั้นตรง ๆ ด้วยการให้ช่องเดียวได้พื้นที่ทั้งหมด
///
/// # ท่าเปลี่ยนหน้า — "ตัวอักษรคลายตัวออก"
/// ระยะตัวอักษรคลายก่อนบรรทัดมุดใต้ขอบ — ภาษาเดียวกับ `heroMinimal`
struct ContactLineWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let size: CGSize

    private var c: ContactInfo { Mock.creator.contact }
    private var lineSize: CGFloat { min(32, size.width * 0.1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("ทักมาทางไลน์")
                .font(.sh(10.5, .bold)).tracking(1.2)
                .foregroundStyle(theme.accent.opacity(0.9))
                .lineLimit(1)
                .scrubVeil(scrub.d, lead: 0.4, drop: 16, pull: 6)

            ScrubReader(d: scrub.d) { d in
                let t = Scrub.ease(Scrub.t(d, lead: 0.16))
                Text(Profile.me.lineId)
                    .font(.sh(lineSize, .black))
                    // บีบอยู่ตอนนิ่ง แล้วคลายออกตอนจากไป
                    .tracking(-0.8 + 8 * t)
                    .foregroundStyle(ink.text(0.97))
                    .lineLimit(1).truncationMode(.tail)
                    .editableText(.lineId, .init(size: lineSize, weight: .black,
                                                 color: ink.text(0.97), tracking: -0.8))
            }
            .scrubVeil(scrub.d, lead: 0.24, drop: 40, pull: 8)

            Spacer(minLength: 4)

            // เวลาตอบกลับมาจากอินบ็อกซ์จริง แก้ไม่ได้ · สถานะผู้รับงานพิมพ์เองได้ — แยกเป็นสองก้อน
            HStack(spacing: 4) {
                Text("ตอบกลับ \(c.responseTime) ·")
                    .font(.sh(10.5, .medium))
                    .foregroundStyle(ink.text(0.42))
                    .lineLimit(1).fixedSize()
                Text(Profile.me.role)
                    .font(.sh(10.5, .medium))
                    .foregroundStyle(ink.text(0.42))
                    .lineLimit(1).truncationMode(.tail)
                    .editableText(.role, .init(size: 10.5, weight: .medium, color: ink.text(0.42)))
            }
            .scrubVeil(scrub.d, lead: 0, drop: 20, pull: 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - 12 · ชิปช่องทาง

/// สามช่องทางเป็นชิปเรียง ขึ้นบรรทัดเองเมื่อแคบ
///
/// รุ่นที่อยู่กึ่งกลางระหว่างแถบบรรทัดเดียว (มินิมอลสุด) กับนามบัตร (ครบสุด) —
/// มีขอบเขตของแต่ละช่องทางให้ตาจับได้ แต่ยังไม่มีพื้นทึบให้อ่านเป็นตาราง
///
/// # ท่าเปลี่ยนหน้า — "ชิปปลิวออกข้างทีละใบ"
struct ContactChipsWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(ContactLine.all.enumerated()), id: \.offset) { i, l in
                HStack(spacing: 6) {
                    Image(systemName: l.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(theme.accent)
                    Text(Profile.me.text(l.field))
                        .font(.sh(12, .semibold))
                        .foregroundStyle(ink.text(0.9))
                        .lineLimit(1).truncationMode(.tail)
                        .editableText(l.field, .init(size: 12, weight: .semibold,
                                                     color: ink.text(0.9), corner: 10))
                }
                .fixedSize()
                .padding(.horizontal, 12).padding(.vertical, 8)
                .overlay(Capsule().strokeBorder(ink.line(0.18), lineWidth: 0.8))
                .scrubSlide(scrub.d, travel: 60 + CGFloat(i) * 14,
                            lead: Scrub.lead(i, of: ContactLine.all.count, d: scrub.d, step: 0.07),
                            fade: 0.55)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
