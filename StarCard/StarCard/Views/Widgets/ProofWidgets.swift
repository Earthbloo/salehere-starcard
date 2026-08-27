import SwiftUI

// ชั้นหลักฐาน — ทุกตัวติด VerifiedBadge และล็อกขนาดไว้
// เหตุผล: แบรนด์เปิดการ์ด 30 ใบเพื่อเลือก 5 คน ถ้าหน้าตาไม่เหมือนกันเขาเทียบไม่ได้
//
// กติกาท่าประจำชั้นนี้: **หัวเรื่องกับตัวเลขคือสมอ** — ไปทีหลังสุด กลับมาก่อนใคร
// เพราะมันคือสิ่งที่ทำให้การ์ดใบนี้ต่างจาก media kit ทั่วไป ถ้ามันหายพร้อมของอื่น
// ทั้ง widget จะละลายเป็นก้อนเดียวจนไม่เหลือจุดให้ตาเกาะ

/// โลโก้แบรนด์ที่เคยร่วมงาน
///
/// # ท่าเปลี่ยนหน้า — "บานพับเรียงแถว"
/// แผ่นโลโก้พลิกอยู่ในช่องของตัวเองไล่กันตามทิศนิ้ว ชื่อใต้แผ่นมุดตามทีหลังครึ่งจังหวะ
struct ProofBrands: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    private var t: TrackRecord { Mock.creator.track }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetLabel(text: "ร่วมงานกับ \(t.brandCount) แบรนด์", trailing: AnyView(VerifiedBadge()))
                .scrubVeil(scrub.d, lead: 0.36, drop: 22, pull: 6)

            // โชว์ 4 แบรนด์ในขนาดที่อ่านชื่อออก แล้วสรุปที่เหลือเป็นแผ่นเดียว
            // เดิมยัด 6 แผ่นจนชื่อเหลือ 8pt ซึ่งเล็กเกินกว่าจะอ่าน — แผ่นเยอะไม่ได้แปลว่าสื่อได้มากกว่า
            GeometryReader { geo in
                let n = min(t.brands.count, 4)
                let gap: CGFloat = 10
                let extra = t.brandCount > n
                let slots = CGFloat(n + (extra ? 1 : 0))
                let d = min((geo.size.width - gap * (slots - 1)) / slots, geo.size.height * 0.68)
                let total = n + (extra ? 1 : 0)

                HStack(alignment: .top, spacing: gap) {
                    ForEach(Array(t.brands.prefix(n).enumerated()), id: \.element.id) { i, brand in
                        let lead = Scrub.lead(i, of: total, d: scrub.d, step: 0.1)
                        VStack(spacing: 7) {
                            BrandPlate(brand: brand, side: d)
                                .scrubLouver(scrub.d, lead: lead, angle: 66, shrink: 0.14)
                            Text(brand.name)
                                .font(.sh(9.5, .medium))
                                .foregroundStyle(ink.text(0.5))
                                .lineLimit(1).minimumScaleFactor(0.6)
                                .frame(width: d + gap * 0.6)
                                .scrubVeil(scrub.d, lead: lead + 0.06, drop: 18, pull: 8)
                        }
                    }
                    if extra {
                        let lead = Scrub.lead(n, of: total, d: scrub.d, step: 0.1)
                        VStack(spacing: 7) {
                            RoundedRectangle(cornerRadius: d * 0.26, style: .continuous)
                                .fill(ink.fill(0.07))
                                .overlay(RoundedRectangle(cornerRadius: d * 0.26, style: .continuous)
                                    .strokeBorder(ink.line(0.16), lineWidth: 0.8))
                                .overlay {
                                    Text("+\(t.brandCount - n)")
                                        .font(.sh(d * 0.3, .bold))
                                        .foregroundStyle(ink.text(0.7))
                                }
                                .frame(width: d, height: d)
                                .scrubLouver(scrub.d, lead: lead, angle: 66, shrink: 0.14)
                            Text("อื่น ๆ")
                                .font(.sh(9.5, .medium))
                                .foregroundStyle(ink.text(0.32))
                                .lineLimit(1).minimumScaleFactor(0.6)
                                // กรอบเดียวกับชื่อแบรนด์ตัวอื่น ไม่งั้นบรรทัดนี้ไม่ถูกบีบ
                                // แล้วอ่านออกมาใหญ่กว่าเพื่อนทั้งแถว
                                .frame(width: d + gap * 0.6)
                                .scrubVeil(scrub.d, lead: lead + 0.06, drop: 18, pull: 8)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

/// ผลงานที่ระบบยืนยันตัวเลขให้
///
/// ต่างจาก widget ผลงานทั่วไปตรงที่ตัวเลขวิว/engagement ดึงมาจากโพสต์จริง ไม่ใช่ creator พิมพ์เอง
/// นี่คือสิ่งที่ media kit ที่ทำใน Canva ทำไม่ได้
///
/// # ท่าเปลี่ยนหน้า — "บานเกล็ด"
///
/// แนวคิดเดียวที่คุมทั้งท่า: **ของไม่ขยับ ที่ขยับคือหน้าต่างที่มองมัน**
///
/// - ช่องผลงานทั้งสามคือบานเกล็ดสามบาน หุบไล่กันตามทิศนิ้ว รูปข้างในคมชัดอยู่กับที่จนวินาทีสุดท้าย
/// - รูปในบานถ่วงตัวสวนทางหน้า (ดอลลี่) — กรอบคือหน้าต่าง รูปคือของที่อยู่ลึกกว่า
/// - ตัวหนังสือไม่จางทิ้ง แต่มุดลงใต้ขอบกล่องตัวเองทีละบรรทัด
/// - **ตัวเลขวิวถูกถอดออกทีละหลัก** ไม่ใช่จางหาย เพราะมันคือค่าที่นับได้ ไม่ใช่คำโปรย
/// - ลำดับมีความหมาย: ชื่อแบรนด์ไปก่อน · แคมเปญตาม · ตัวเลขไปท้ายสุดและกลับมาก่อนใคร
struct ProofWork: View {
    @Environment(PhotoStore.self) private var photos
    /// ระยะหน้าที่ส่งมาจาก tile — ตัวขับท่าบานเกล็ดทั้งหมด
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    private var works: [VerifiedWork] { Mock.creator.track.works }

    /// หาแบรนด์จากชื่อในผลงาน — ชื่อต้องตรงกับรายการ `brands` ถึงจะได้โลโก้มาแสดง
    private func brand(_ name: String) -> Brand? {
        Mock.creator.track.brands.first { $0.name == name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // หัวเรื่องคือสมอของทั้งก้อน — ขยับทีหลังสุด กลับมาก่อนใคร
            WidgetLabel(text: "ผลงานที่ยืนยันแล้ว", trailing: AnyView(VerifiedBadge()))
                .scrubVeil(scrub.d, lead: 0.34, drop: 22, pull: 6)

            GeometryReader { geo in
                let gap: CGFloat = 9
                let w = (geo.size.width - gap * CGFloat(works.count - 1)) / CGFloat(works.count)
                // บล็อกข้อความใต้รูป: แบรนด์ + แคมเปญ 2 บรรทัด + ตัวเลข
                let textH: CGFloat = 102
                // เต็มความกว้างการ์ดเสมอ แล้วสูงตามสัดส่วน 3:4 เท่าที่พื้นที่มี
                let photoH = min(w * 4.0 / 3.0, max(40, geo.size.height - textH))

                HStack(alignment: .top, spacing: gap) {
                    ForEach(Array(works.enumerated()), id: \.element.id) { i, work in
                        column(work, w: w, photoH: photoH)
                            // ลำดับการหุบผูกกับ sign(d) ล้วน — บานที่หุบก่อนคือบานที่คลี่ทีหลัง
                            .scrubAperture(scrub.d,
                                           lead: Scrub.lead(i, of: works.count, d: scrub.d, step: 0.13),
                                           feather: 0.18, dim: 0.55)
                    }
                }
            }
        }
    }

    /// ผลงานหนึ่งช่อง = บานเกล็ดหนึ่งบาน
    private func column(_ work: VerifiedWork, w: CGFloat, photoH: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .frame(width: w, height: photoH)
                .overlay {
                    WidgetPhoto(index: work.photo)
                        .aspectRatio(contentMode: .fill)
                        // ถ่วงสวนทางหน้า · zoom ต้องคุ้ม shift (0.16 ≥ 2 × 0.07) ไม่งั้นเห็นขอบว่าง
                        .scrubDolly(scrub.d, shift: w * 0.07, zoom: 0.16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(ink.line(0.1), lineWidth: 0.5))
                .photoSlot(work.photo)

            // แบรนด์เจ้าของงาน — โลโก้จริงคู่ชื่อ อ่านได้ทั้งคนที่จำโลโก้และคนที่จำชื่อ
            // ปิดท้ายด้วยไอคอนแพลตฟอร์ม: แบรนด์ถามว่า "ลงที่ไหน" ก่อนถามยอดวิวเสมอ
            HStack(spacing: 6) {
                if let b = brand(work.brand) {
                    BrandPlate(brand: b, side: 20)
                }
                Text(work.brand)
                    .font(.sh(10, .semibold))
                    .foregroundStyle(ink.text(0.72))
                    .lineLimit(1).minimumScaleFactor(0.6)
                Spacer(minLength: 3)
                BrandIcon(name: work.platform.icon, size: 11)
            }
            .scrubVeil(scrub.d, lead: 0.04, drop: 26, pull: 12)

            Text("\(work.ep) \(work.campaign)")
                .font(.sh(12, .semibold))
                .foregroundStyle(ink.text(0.95))
                .lineSpacing(1)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .scrubVeil(scrub.d, lead: 0.13, drop: 34, pull: 10)

            Spacer(minLength: 0)

            // หลักฐานไปท้ายสุด กลับมาก่อนใคร — และไปแบบ "ถอดทีละหลัก" ไม่ใช่จางหาย
            // เหลือยอดวิวค่าเดียว ER ถูกถอดออกทั้งชั้นแล้ว (ยังอยู่ในโมเดลถ้าจะเอากลับมา)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                ScrubDigits(text: Fmt.compact(work.views), d: scrub.d,
                            lead: 0.3, step: 0.05, drop: 20)
                    .font(.sh(16, .heavy))
                    .foregroundStyle(ink.text(0.98))
                Text("วิว").font(.sh(9)).foregroundStyle(ink.text(0.42))
                    .scrubVeil(scrub.d, lead: 0.26, drop: 18, pull: 6)
                Spacer(minLength: 0)
            }
            .lineLimit(1)
        }
        .frame(width: w, alignment: .leading)
    }
}

// MARK: - แบรนด์: หลายหน้าตาให้เลือก
//
// แต่ละตัวเล่นคนละจังหวะ: แถว+ชื่อ (อ่านง่าย) · กำแพง (โลโก้ล้วน แน่น) ·
// ราง (เลื่อนเอง ได้ความเคลื่อนไหว) · รายชื่อ (ตัวหนังสือล้วน ไม่มีโลโก้)

/// โลโก้แบรนด์ล้วน ๆ — ไม่มีแผ่นรองและไม่มีกรอบ
///
/// ตัวโลโก้เองคือรูปทรงที่แบรนด์อยากให้จำ การเอาแผ่นขาวกับเส้นขอบมาครอบทำให้ทุกแบรนด์
/// หน้าตาเหมือนกันหมดจนโลโก้กลายเป็นแค่ไอคอนในตาราง
/// จุดเดียวที่คุมหน้าตาโลโก้ของทุก widget — แก้ที่นี่เปลี่ยนทั้งชุด
struct BrandPlate: View {
    let brand: Brand
    let side: CGFloat

    @Environment(\.cardInk) private var ink

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
        Group {
            if let logo = brand.logo {
                RemoteLogo(url: logo)
                    .clipShape(shape)
            } else {
                // ไม่มีไฟล์โลโก้ถึงจะเหลือแผ่นโมโนแกรมไว้ ไม่งั้นช่องนั้นว่างเปล่า
                //
                // ตอนที่แผงโชว์ครบทุกแบรนด์ แผ่นพวกนี้อยู่ปนกับโลโก้จริงเป็นสิบใบ
                // แผ่นเทาทึบตัวอักษรขาวจัดแบบเดิมจึงดังพอ ๆ กับโลโก้จริงทั้งที่มันคือตัวแทน
                // ไล่เฉด + เส้นขอบ ทำให้มันอ่านเป็น "แผ่นชื่อย่อที่ตั้งใจออกแบบ" และถอยไปเป็นแถวหลัง
                shape.fill(LinearGradient(colors: [ink.fill(0.13), ink.fill(0.05)],
                                          startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(shape.strokeBorder(ink.line(0.14), lineWidth: 0.6))
                    .overlay {
                        Text(brand.monogram)
                            .font(.sh(side * 0.31, .heavy))
                            .foregroundStyle(ink.text(0.6))
                    }
            }
        }
        .frame(width: side, height: side)
    }
}

/// กำแพงโลโก้ — กริดเต็มพื้นที่ ไม่มีชื่อ เหมาะกับคนที่ร่วมงานมาเยอะ
///
/// # ท่าเปลี่ยนหน้า — "กำแพงพลิกทีละแผ่น"
/// แผ่นพระเอกพลิกช้าและองศาน้อย (ของหนัก) · แผ่นเล็กพลิกไวและองศาชัด (ของเบา)
struct ProofBrandWall: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    private var t: TrackRecord { Mock.creator.track }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetLabel(text: "ร่วมงานกับ \(t.brandCount) แบรนด์", trailing: AnyView(VerifiedBadge()))
                .scrubVeil(scrub.d, lead: 0.36, drop: 22, pull: 6)

            // เทรนด์ 2026 · Bento Grid — แบรนด์แรกได้ช่องใหญ่สองเท่า ที่เหลือเป็นช่องเล็ก
            GeometryReader { geo in
                let gap: CGFloat = 8
                let side = (geo.size.width - gap * 3) / 4
                let big = side * 2 + gap
                let rest = Array(t.brands.dropFirst().prefix(4))
                // นับจากยอดแบรนด์จริงในระบบ ไม่ใช่จำนวนโลโก้ที่มีไฟล์ — ตัวเลขต้องตรงกับหัวข้อ
                let extra = max(0, t.brandCount - 5)

                HStack(spacing: gap) {
                    if let hero = t.brands.first {
                        BrandPlate(brand: hero, side: big)
                            .scrubLouver(scrub.d, lead: Scrub.lead(0, of: 5, d: scrub.d, step: 0.1),
                                         angle: 44, shrink: 0.08)
                    }
                    ForEach(0..<2, id: \.self) { c in
                        VStack(spacing: gap) {
                            ForEach(0..<2, id: \.self) { r in
                                let i = c * 2 + r
                                let lead = Scrub.lead(i + 1, of: 5, d: scrub.d, step: 0.1)
                                ZStack {
                                    if i < rest.count {
                                        BrandPlate(brand: rest[i], side: side)
                                    }
                                    // ช่องสุดท้ายบอกจำนวนที่เหลือ แทนที่จะตัดหายไปเงียบ ๆ
                                    if i == rest.count - 1, extra > 0 {
                                        RoundedRectangle(cornerRadius: side * 0.26, style: .continuous)
                                            .fill(.black.opacity(0.62))
                                            .overlay {
                                                ScrubDigits(text: "+\(extra)", d: scrub.d,
                                                            lead: lead + 0.1, step: 0.05,
                                                            drop: side * 0.4)
                                                    .font(.sh(side * 0.3, .bold))
                                                    .foregroundStyle(.white.opacity(0.95))
                                            }
                                            .frame(width: side, height: side)
                                    }
                                }
                                .scrubLouver(scrub.d, lead: lead, angle: 70, shrink: 0.16)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(height: big, alignment: .top)
            }
        }
    }
}

/// แผงโลโก้ครบทุกใบ — **แบบเดียวในตระกูลที่ไม่มี "+N"**
///
/// สามแบบเดิมเลือกโชว์ 4–5 ใบแล้วสรุปที่เหลือเป็นตัวเลข ซึ่งดีเวลาอยากได้ความสะอาด
/// แต่มันตอบคำถาม "เคยทำกับใครมาบ้าง" ได้ไม่หมด — แบรนด์ที่เปิดการ์ดมาหาว่ามีคู่แข่งของตัวเอง
/// อยู่ในนั้นไหม ต้องเห็นทุกใบถึงจะตอบได้ ตัวนี้จึงวางครบทุกแบรนด์ในระบบเสมอ ไม่ตัดใคร
///
/// วางเป็น **คอนแทกต์ชีต**: ช่องชนกันสนิท คั่นด้วยเส้นผมแทนร่อง — ต่างจาก "กำแพงโลโก้"
/// ที่เป็นเบนโตะมีแผ่นพระเอก ตรงนี้ทุกแบรนด์เท่ากันหมด ซึ่งคือความหมายที่ถูกต้องของแผงรวม
///
/// # ท่าเปลี่ยนหน้า — "ไฟดับเป็นคลื่นทแยง"
///
/// ดับไล่ตามเส้นทแยง (แถว + คอลัมน์) ไม่ใช่ไล่ทีละใบตามลำดับ เพราะแผงที่กว้างเท่ากันทั้งผืน
/// ถ้าดับเรียงทีละใบจะอ่านเป็น "ลิสต์ที่ถูกไล่ลบ" ส่วนคลื่นทแยงอ่านเป็นแผงไฟที่ถูกกวาดด้วยมือ
struct ProofBrandGrid: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    private var t: TrackRecord { Mock.creator.track }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetLabel(text: "ร่วมงานกับ \(t.brandCount) แบรนด์", trailing: AnyView(VerifiedBadge()))
                .scrubVeil(scrub.d, lead: 0.36, drop: 22, pull: 6)

            GeometryReader { geo in
                // สี่คอลัมน์เมื่อเต็มความกว้างการ์ด · สามเมื่อถูกย่อ
                // ห้าคอลัมน์ขึ้นไปโลโก้จะเล็กกว่าที่ตาแยกแบรนด์ออก ซึ่งทำให้แผงไร้ความหมาย
                let cols = geo.size.width > 300 ? 4 : 3
                let rows = max(1, Int(ceil(Double(t.brands.count) / Double(cols))))
                let cw = geo.size.width / CGFloat(cols)
                let ch = min(cw, geo.size.height / CGFloat(rows))

                ScrubReader(d: scrub.d) { d in
                    VStack(spacing: 0) {
                        ForEach(0..<rows, id: \.self) { r in
                            HStack(spacing: 0) {
                                ForEach(0..<cols, id: \.self) { c in
                                    cell(row: r, col: c, cols: cols, rows: rows,
                                         w: cw, h: ch, d: d)
                                }
                            }
                        }
                    }
                    .frame(width: geo.size.width, alignment: .topLeading)
                }
            }
        }
    }

    private func cell(row: Int, col: Int, cols: Int, rows: Int,
                      w: CGFloat, h: CGFloat, d: CGFloat) -> some View {
        let i = row * cols + col
        // คลื่นทแยง: ช่องที่อยู่บนเส้นทแยงเดียวกันดับพร้อมกัน
        let a = Scrub.cell(row + col, of: cols + rows - 1, d: d, spill: 1.6)
        return ZStack {
            if i < t.brands.count {
                BrandPlate(brand: t.brands[i], side: min(w, h) * 0.72)
                    .opacity(a)
                    .scaleEffect(0.72 + 0.28 * a)
            }
        }
        .frame(width: w, height: h)
        // เส้นผมเฉพาะขอบใน — ขอบนอกปล่อยว่างไว้ให้แผงลอยอยู่บนการ์ด ไม่ใช่กล่องที่มีกรอบ
        .overlay(alignment: .leading) {
            if col > 0, i < t.brands.count {
                Rectangle().fill(ink.line(0.1)).frame(width: 0.5)
            }
        }
        .overlay(alignment: .top) {
            if row > 0 {
                Rectangle().fill(ink.line(0.1)).frame(height: 0.5)
            }
        }
    }
}

/// รางโลโก้เลื่อนเอง — วนไม่รู้จบ ให้การ์ดมีความเคลื่อนไหวโดยไม่กินพื้นที่
///
/// # ท่าเปลี่ยนหน้า — "กรอตามนิ้ว"
/// รางวิ่งอยู่แล้วตามเวลา ตอนปัดมันเร่ง/ถอยตามนิ้ว ปล่อยแล้วสปริงพากลับเข้าจังหวะเดิม
///
/// ขับด้วย `ScrubRunner` (TimelineView) ไม่ใช่ `withAnimation(repeatForever)` —
/// transaction ที่วนค้างไว้จะไปกลืนการอัปเดตรูปโลโก้ที่โหลดเสร็จทีหลัง จนแผ่นค้างเป็นสีขาวเปล่า
struct ProofBrandRail: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme
    private var t: TrackRecord { Mock.creator.track }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetLabel(text: "ร่วมงานกับ \(t.brandCount) แบรนด์", trailing: AnyView(VerifiedBadge()))
                .scrubVeil(scrub.d, lead: 0.36, drop: 20, pull: 6)

            GeometryReader { geo in
                let side = min(geo.size.height, 44)
                let gap: CGFloat = 8
                let runWidth = (side + gap) * CGFloat(t.brands.count)
                // สำเนาต้องพอคลุมความกว้างกล่อง + หนึ่งชุดที่กำลังเลื่อนออก
                let copies = max(3, Int((geo.size.width / max(runWidth, 1)).rounded(.up)) + 1)

                ScrubRunner(d: scrub.d, runWidth: runWidth,
                            period: Double(t.brands.count) * 2.2,
                            pull: 0.5,
                            // นอกระยะแล้วหยุดตีเฟรม — ไม่งั้นหน้าที่มองไม่เห็นยังกิน CPU ทุกเฟรม
                            active: abs(scrub.d) < 1.05,
                            copies: copies) {
                    HStack(spacing: gap) {
                        ForEach(t.brands) { brand in
                            BrandPlate(brand: brand, side: side)
                        }
                    }
                    .padding(.trailing, gap)
                    .fixedSize()
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
                .clipped()
                .mask(
                    // ขอบซ้าย-ขวาจางลง ให้โลโก้ "ไหลเข้า-ออก" แทนที่จะโดนตัดกลางตัว
                    LinearGradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.06),
                        .init(color: .black, location: 0.94),
                        .init(color: .clear, location: 1),
                    ], startPoint: .leading, endPoint: .trailing)
                )
            }
        }
    }
}

/// รายชื่อแบรนด์ — ตัวหนังสือล้วน ไม่มีโลโก้เลย · มินิมอลสุดในชุด
///
/// # ท่าเปลี่ยนหน้า — "เครดิตไหลทีละชื่อ"
/// ชื่อแต่ละแบรนด์มุดใต้บรรทัดของตัวเองไล่กัน ไม่ใช่ทั้งบล็อกเลื่อนพร้อมกัน
struct ProofBrandList: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    private var t: TrackRecord { Mock.creator.track }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetLabel(text: "ร่วมงานกับ \(t.brandCount) แบรนด์", trailing: AnyView(VerifiedBadge()))
                .scrubVeil(scrub.d, lead: 0.36, drop: 22, pull: 6)

            // เทรนด์ 2026 · Oversized editorial type — ชื่อแบรนด์ตัวหนาใหญ่คั่นด้วยจุดสีธีม
            // ต้องใช้ FlowLayout ตรง ๆ ไม่ใช่ FlowChips เพราะท่านี้ต้องรู้ลำดับของแต่ละชื่อ
            FlowLayout(spacing: 10) {
                ForEach(Array(t.brands.enumerated()), id: \.element.id) { i, brand in
                    HStack(spacing: 10) {
                        Text(brand.name)
                            .font(.sh(17, .bold))
                            .tracking(-0.3)
                            .foregroundStyle(ink.text(0.92))
                            .lineLimit(1)
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 4, height: 4)
                    }
                    .scrubVeil(scrub.d,
                               lead: Scrub.lead(i, of: t.brands.count, d: scrub.d, step: 0.07),
                               drop: 28, pull: 14)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
