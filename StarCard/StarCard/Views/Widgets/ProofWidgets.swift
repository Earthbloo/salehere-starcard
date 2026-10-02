import SwiftUI

// ชั้นหลักฐาน — ทุกตัวติด VerifiedBadge และล็อกขนาดไว้
// เหตุผล: แบรนด์เปิดการ์ด 30 ใบเพื่อเลือก 5 คน ถ้าหน้าตาไม่เหมือนกันเขาเทียบไม่ได้
//
// กติกาท่าประจำชั้นนี้: **หัวเรื่องกับตัวเลขคือสมอ** — ไปทีหลังสุด กลับมาก่อนใคร
// เพราะมันคือสิ่งที่ทำให้การ์ดใบนี้ต่างจาก media kit ทั่วไป ถ้ามันหายพร้อมของอื่น
// ทั้ง widget จะละลายเป็นก้อนเดียวจนไม่เหลือจุดให้ตาเกาะ

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
/// รูปของผลงาน — รูปปกแคมเปญ (asset) เมื่อผลงานมาจากแคมเปญใน Sale Here · ไม่งั้นรูปในช่องของเจ้าของการ์ด
struct WorkPicture: View {
    let work: VerifiedWork
    var body: some View {
        if let cover = work.cover {
            Image(cover).resizable()
        } else {
            WidgetPhoto(index: work.photo)
        }
    }
}

struct ProofWork: View {
    @Environment(PhotoStore.self) private var photos
    /// ระยะหน้าที่ส่งมาจาก tile — ตัวขับท่าบานเกล็ดทั้งหมด
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    private var works: [VerifiedWork] { Profile.me.shownTrack(.verified).works }

    /// หาแบรนด์จากชื่อในผลงาน — ชื่อต้องตรงกับรายการ `brands` ถึงจะได้โลโก้มาแสดง
    private func brand(_ name: String) -> Brand? {
        Profile.me.shownTrack(.verified).brands.first { $0.name == name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // หัวเรื่องคือสมอของทั้งก้อน — ขยับทีหลังสุด กลับมาก่อนใคร
            WidgetLabel(text: "ผลงานที่ยืนยันแล้ว", trailing: AnyView(VerifiedBadge()))
                .scrubVeil(scrub.d, lead: 0.34, drop: 22, pull: 6)

            GeometryReader { geo in
                let gap: CGFloat = 9
                let w = (geo.size.width - gap * CGFloat(works.count - 1)) / CGFloat(works.count)

                HStack(alignment: .top, spacing: gap) {
                    ForEach(Array(works.enumerated()), id: \.element.id) { i, work in
                        column(work, w: w)
                            // ลำดับการหุบผูกกับ sign(d) ล้วน — บานที่หุบก่อนคือบานที่คลี่ทีหลัง
                            .scrubAperture(scrub.d,
                                           lead: Scrub.lead(i, of: works.count, d: scrub.d, step: 0.13),
                                           feather: 0.18, dim: 0.55)
                            .linkSlot(work.postURL)
                    }
                }
            }
        }
    }

    /// ผลงานหนึ่งช่อง = บานเกล็ดหนึ่งบาน
    ///
    /// # ทำไมไม่มีชื่อแคมเปญแล้ว
    ///
    /// เดิมมีบรรทัด "EP.1335 Ballet Dream" ตัวหนาสองบรรทัดคั่นระหว่างรูปกับตัวเลข
    /// ซึ่งกินความสูงไป ~34pt และเป็นข้อความที่ **แบรนด์ไม่ได้ใช้ตัดสินใจ** —
    /// ชื่อแคมเปญมีความหมายกับคนที่ทำงานนั้น ไม่ใช่กับคนที่กำลังเลือกจ้าง
    ///
    /// สิ่งที่แบรนด์กวาดตาหาจริงมีสี่อย่าง: **รูป · แบรนด์ · วิว · บันทึก/แชร์**
    /// ตัดชื่อออกแล้วเอาความสูงทั้งหมดคืนให้รูป ซึ่งเป็นหลักฐานที่ดังที่สุดอยู่แล้ว
    ///
    /// รูปไม่ล็อกสัดส่วน 3:4 อีกแล้ว แต่ **กินที่ทั้งหมดที่เหลือ** — ของเดิมล็อกไว้
    /// รูปเลยตันที่ 139pt แล้วที่ว่างที่เหลือกลายเป็นช่องโหว่ ไม่ได้ไปอยู่กับรูป
    private func column(_ work: VerifiedWork, w: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .frame(width: w)
                .frame(maxHeight: .infinity)
                .overlay {
                    WorkPicture(work: work)
                        .aspectRatio(contentMode: .fill)
                        // ถ่วงสวนทางหน้า · zoom ต้องคุ้ม shift (0.16 ≥ 2 × 0.07) ไม่งั้นเห็นขอบว่าง
                        .scrubDolly(scrub.d, shift: w * 0.07, zoom: 0.16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(ink.line(0.1), lineWidth: 0.5))
                // ป้ายการันตีผลงาน — ติดเฉพาะชิ้นที่ถึงเกณฑ์จริง ไม่ใช่ทุกชิ้น
                // ถ้าติดครบทุกใบมันจะกลายเป็นของประดับแล้วเลิกมีความหมายทันที
                .overlay(alignment: .topLeading) {
                    if let tag = work.viralTag {
                        Text(tag)
                            .font(.sh(8.5, .heavy))
                            .foregroundStyle(.white)
                            .lineLimit(1).fixedSize()
                            .padding(.horizontal, 7).padding(.vertical, 3.5)
                            .background(Capsule().fill(theme.rawAccent.opacity(0.92)))
                            .padding(7)
                            .scrubVeil(scrub.d, lead: 0.2, drop: 16, pull: 8)
                    }
                }
                // ซีเรียลของงาน — เลขตอนที่ระบบออกให้ อยู่มุมล่างของรูปทุกชิ้นทุกแบบ
                .overlay(alignment: .bottomTrailing) {
                    EPChip(ep: work.ep, tone: .ink, size: 7.5)
                        .padding(6)
                        .scrubVeil(scrub.d, lead: 0.22, drop: 14, pull: 8)
                }
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

            // หลักฐานไปท้ายสุด กลับมาก่อนใคร — และไปแบบ "ถอดทีละหลัก" ไม่ใช่จางหาย
            // เหลือยอดวิวค่าเดียว ER ถูกถอดออกทั้งชั้นแล้ว (ยังอยู่ในโมเดลถ้าจะเอากลับมา)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                ScrubDigits(text: work.views > 0 ? Fmt.compact(work.views) : "–", d: scrub.d,
                            lead: 0.3, step: 0.05, drop: 20)
                    .font(.sh(19, .heavy))
                    .foregroundStyle(ink.text(0.98))
                Text("วิว").font(.sh(9.5)).foregroundStyle(ink.text(0.42))
                    .scrubVeil(scrub.d, lead: 0.26, drop: 18, pull: 6)
                Spacer(minLength: 0)
            }
            .lineLimit(1)

            // บรรทัดรอง ไม่ใช่บรรทัดคู่ — วางใต้ยอดวิวและเล็กกว่าชัดเจน
            WorkDeepStats(work: work, size: 9.5, tint: ink.text(0.52))
        }
        .frame(width: w, alignment: .leading)
    }
}

// MARK: - แบรนด์: หลายหน้าตาให้เลือก
//
// แต่ละตัวเล่นคนละจังหวะ: แผงครบ (เห็นทุกแบรนด์) · ราง (เลื่อนเอง ได้ความเคลื่อนไหว) ·
// เหรียญ (แถวเดียว อ่านจบในจังหวะเดียว)

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
                    .dataValue()
                    .clipShape(shape)
            } else if let asset = brand.asset {
                // โลโก้แคมเปญจาก asset ในแอป (แบรนด์ที่ร่วมแคมเปญผ่าน Sale Here)
                Image(asset).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: side, height: side)
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
    private var t: TrackRecord { Profile.me.shownTrack(.brand) }

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
    private var t: TrackRecord { Profile.me.shownTrack(.brand) }

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

/// เหรียญโลโก้ — วงกลมมีขอบ เรียงเป็นแถวเดียวแนวนอน
///
/// ต่างจากอีกสี่ใบในตระกูลตรงที่มันตัดทุกอย่างทิ้งเหลือ **วงกลมขนาดเท่ากันเรียงกัน** —
/// ไม่มีชื่อใต้แผ่น ไม่มีแผ่นพระเอก ไม่มีตาราง เพราะของที่ขนาดเท่ากันทั้งแถวอ่านเป็น
/// *รายชื่อ* ไม่ใช่ *ผัง* ตาจึงกวาดจบในจังหวะเดียวแล้วไปต่อ ซึ่งคือสิ่งที่แถบ
/// "trusted by" ของเว็บแบรนด์ทำกันทั้งวงการ
///
/// # ทำไมวงกลมต้องมีพื้นขาว ไม่ใช่โลโก้ลอย ๆ แบบ `BrandPlate`
///
/// โลโก้ถูกออกแบบมาให้ยืนบนขาว — ไฟล์ PNG โปร่งที่ใช้หมึกเข้มวางบนการ์ดพื้นมืดแล้ว
/// **หายไปทั้งใบ** ส่วนไฟล์ JPG พื้นขาวจะกลายเป็นสี่เหลี่ยมขาวโด่อยู่กลางแถว
/// วงขาว + ขอบจึงแก้ทั้งสองข้อพร้อมกัน: ทุกแบรนด์ได้พื้นเดียวกัน และขอบคือสิ่งที่
/// บอกว่าวงจบตรงไหนเมื่อโลโก้เองก็พื้นขาว
///
/// # ท่าเปลี่ยนหน้า — "เหรียญพลิกไล่แถว"
/// พลิกทีละเหรียญตามทิศนิ้ว เหรียญที่พลิกก่อนคือเหรียญที่กลับมาทีหลัง
struct ProofBrandCoins: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    private var t: TrackRecord { Profile.me.shownTrack(.brand) }

    var body: some View {
        VStack(spacing: 8) {
            caption

            GeometryReader { geo in
                // เหรียญคือวงกลม — รูปทรงไม่เปลี่ยนตามกรอบ ที่เปลี่ยนคือ *จำนวนที่ลงในแถว*
                // (กติกาการย่อ-ขยายของตู้: กรอบคือกล่องจัดแถว ไม่ใช่ตัวยืดของข้างใน)
                // แคบมากก็ยังต้องเหลือที่ให้เหรียญหนึ่งใบ + วง "+N" — ไม่งั้นวงท้ายถูกตัดหาย
                // แล้วแถบที่เหลือจะโกหกว่านี่คือแบรนด์ทั้งหมด
                let cap = min(geo.size.height, 58)
                let d = max(18, min(cap, (geo.size.width - cap * 0.11) / 2))
                let gap = max(4, d * 0.11)
                // จำนวนวงที่ลงในความกว้างนี้จริง ๆ — เหลือที่ไม่พอก็ตัด ไม่บีบวงให้เล็กลง
                let fit = max(1, Int((geo.size.width + gap) / (d + gap)))
                let overflow = t.brands.count > fit
                // เหลือที่ให้วง "+N" หนึ่งช่องเสมอเมื่อโชว์ไม่ครบ — ไม่งั้นแถวจบแบบเงียบ ๆ
                // แล้วคนอ่านจะนึกว่านี่คือแบรนด์ทั้งหมดที่มี
                let shown = Array(t.brands.prefix(overflow ? max(1, fit - 1) : fit))
                let extra = t.brandCount - shown.count
                let slots = shown.count + (extra > 0 ? 1 : 0)
                // ถ่างให้เต็มความกว้างเมื่อของน้อย แต่ไม่เกินระยะที่ยังอ่านเป็นแถวเดียวกัน
                // แถวกินเต็มความกว้างเสมอ — เหรียญคือเนื้อหาของใบนี้ ไม่ใช่ของประดับที่เกาะกลาง
                let spread = slots > 1
                    ? min(d * 0.7, max(gap, (geo.size.width - d * CGFloat(slots)) / CGFloat(slots - 1)))
                    : gap

                HStack(spacing: spread) {
                    ForEach(Array(shown.enumerated()), id: \.element.id) { i, brand in
                        coin(brand, d: d)
                            .scrubLouver(scrub.d,
                                         lead: Scrub.lead(i, of: slots, d: scrub.d, step: 0.09),
                                         angle: 66, shrink: 0.14)
                    }
                    if extra > 0 {
                        more(extra, d: d)
                            .scrubLouver(scrub.d,
                                         lead: Scrub.lead(shown.count, of: slots, d: scrub.d, step: 0.09),
                                         angle: 66, shrink: 0.14)
                    }
                }
                // แถวอยู่กลางกรอบทั้งสองแกน — หัวเรื่องเป็นบล็อกกลาง แถวที่ชิดซ้ายจะทำให้
                // ทั้งใบอ่านเป็นสองชิ้นที่วางคนละระบบ
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    /// บรรทัดกำกับ — **เล็กและเงียบโดยตั้งใจ**
    ///
    /// # ลำดับความดังของใบนี้
    ///
    /// คนที่เปิดการ์ดมาหาแถบนี้กวาดตาหา *โลโก้ที่เขารู้จัก* — แบรนด์คู่แข่งของตัวเอง
    /// แบรนด์ระดับเดียวกัน แบรนด์ที่แปลว่าคนนี้ผ่านงานจริงมาแล้ว · การจำโลโก้เกิดก่อน
    /// การอ่านตัวหนังสือเสมอ คำถามที่เขาถือมาคือ "**ใครบ้าง**" ไม่ใช่ "กี่เจ้า"
    ///
    /// "6 แบรนด์" จึงเป็น *คำกำกับของแถว* ไม่ใช่เนื้อหาของแถว — ตัวเลขจำนวนตอบได้แค่
    /// "เยอะไหม" ซึ่งเป็นคำถามรอง เคยทำเป็นคำหนา 25pt อยู่รอบหนึ่ง แล้วมันกลายเป็น
    /// ป้ายชื่อตู้ที่ดังกว่าของในตู้ · ที่นี่จึงย่อลงมาเป็นบรรทัดเดียวขนาดคำบรรยาย
    /// แล้วยกน้ำหนักทั้งหมดคืนให้เหรียญ
    private var caption: some View {
        HStack(spacing: 5) {
            Text("Trusted by")
                .font(CardFont.serif.font(10.5, .regular).italic())
                .foregroundStyle(ink.text(0.48))
            // ตัวเลขยังถอดทีละหลัก — มันคือค่าที่นับได้ ต่อให้ตัวเล็กลงก็ยังเป็นค่า ไม่ใช่คำโปรย
            ScrubDigits(text: "\(t.brandCount)", d: scrub.d, lead: 0.34, step: 0.04, drop: 12)
            Text("แบรนด์")
        }
        .font(.sh(10.5, .bold))
        .foregroundStyle(ink.text(0.72))
        .lineLimit(1)
        .scrubVeil(scrub.d, lead: 0.38, drop: 14, pull: 6)
        .padding(.horizontal, 74)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            VerifiedBadge()
                .scrubVeil(scrub.d, lead: 0.44, drop: 14, pull: 6)
        }
    }

    /// เหรียญหนึ่งใบ — พื้นขาว · โลโก้เว้นขอบใน · วงขอบไล่เฉดจากสีธีมไปหาเส้นผม
    private func coin(_ brand: Brand, d: CGFloat) -> some View {
        Circle()
            // พื้นมืดลดความขาวลงนิดเดียวให้วงไม่แผดกว่าตัวการ์ด · พื้นกระดาษใช้ขาวเต็ม
            // แล้วให้ขอบเป็นตัวบอกว่าวงจบตรงไหน
            .fill(ink.isLight ? Color.white : Color.white.opacity(0.93))
            .overlay {
                if let logo = brand.logo {
                    // เว้นขอบในบางที่สุดที่ยังไม่ชนขอบวง — โลโก้คือเนื้อหา ขาวรอบ ๆ คือที่ว่าง
                    RemoteLogo(url: logo)
                        .dataValue()
                        .padding(d * 0.07)
                } else if let asset = brand.asset {
                    Image(asset).resizable().aspectRatio(contentMode: .fill)
                        .frame(width: d, height: d).clipShape(Circle())
                } else {
                    Text(brand.monogram)
                        .dataValue()
                        .font(.sh(d * 0.3, .heavy))
                        .foregroundStyle(.black.opacity(0.5))
                }
            }
            .clipShape(Circle())
            .overlay {
                Circle().strokeBorder(
                    LinearGradient(colors: [theme.accent.opacity(0.75), ink.line(0.22)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: max(1.2, d * 0.042))
            }
            .frame(width: d, height: d)
    }

    /// วงปิดท้าย — ไม่ใช่เหรียญ จึงไม่ได้พื้นขาว ต่างกันชัดว่านี่คือ *จำนวนที่เหลือ* ไม่ใช่แบรนด์อีกใบ
    private func more(_ extra: Int, d: CGFloat) -> some View {
        Circle()
            .fill(ink.fill(0.08))
            .overlay(Circle().strokeBorder(ink.line(0.2), lineWidth: max(1, d * 0.03)))
            .overlay {
                Text("+\(extra)")
                    .font(.sh(d * 0.3, .bold))
                    .foregroundStyle(ink.text(0.68))
            }
            .frame(width: d, height: d)
    }
}
