import SwiftUI

// MARK: - สำรับ "รูปผลงาน" รอบสอง — แปดสถานการณ์ของกองรูปเดียวกัน
//
// ตระกูล `.photo` เดิมมีหกแบบ แต่ทั้งหกตอบโจทย์เดียวกันหมด: **"เรียงรูปให้ดูดี"**
// (แถบภาพ · เบนโตะ · คู่แนวตั้ง · ชิ้นเด่น · คลิป · ตู้ถ่ายรูป)
// สิ่งที่ตู้ยังไม่มีคือ *สถานการณ์* — ครีเอเตอร์คนหนึ่งไม่ได้มีกองรูปแบบเดียวตลอดปี
//
// | มีรูปแบบไหน | ควรหยิบตัวไหน |
// |---|---|
// | รูปเยอะมาก คละสัดส่วน | บอร์ดพิน · โมเสก |
// | รูปดีจริงแค่ 3 ใบ | กองรูปซ้อน · เทปกาว |
// | อยากให้อ่านเป็นงานที่ *ลงจริง* | โพสต์โซเชียล · สตอรี่ |
// | อยากได้อารมณ์ฟิล์ม/ของสะสม | ฟิล์ม 35 มม. |
// | มีรูปชุดเดียวแต่อยากให้คนไล่ดู | สไลด์การ์ด |
//
// # กติกาสามข้อของไฟล์นี้
//
// 1. **รูปคือเนื้อหา ที่เหลือคือกรอบ** — ทุกแบบต้องให้รูปกินพื้นที่เกิน 70%
//    บทเรียนเดียวกับที่ `ProofWorkVariants.swift` เรียนมาแล้ว: กรอบที่กินที่มากกว่ารูป
//    อ่านออกมาเป็นเครื่องมือ ไม่ใช่พอร์ต
// 2. **ห้ามมีตัวอักษรสักตัวในทั้งสำรับ** — ไม่มีชื่อผู้ใช้ ไม่มีชื่อแบรนด์ ไม่มียอดวิว ไม่มีแคปชัน
//    ตระกูลนี้ตอบคำถามเดียวคือ "งานหน้าตาเป็นยังไง" ซึ่งรูปตอบเองได้ทั้งหมด
//    ส่วนคำถาม "ลงที่ไหน กี่วิว ของแบรนด์ไหน" เป็นของตระกูล `ผลงานยืนยัน` ที่ทำไว้ครบแล้ว
//    ป้ายที่ซ้ำกันสองที่ไม่ได้ทำให้น่าเชื่อขึ้นเป็นสองเท่า แต่กินที่ของรูปไปจริง ๆ ทุกครั้ง
//    (ไอคอนกับโลโก้แพลตฟอร์มไม่นับเป็นตัวอักษร — มันคือ *กรอบ* ที่ทำให้อ่านออกว่านี่คือโพสต์)
// 3. **ท่าเปลี่ยนหน้าต้องมาจากวัสดุ** (กฎที่ยกมาจากสำรับ Gen Z) — ฟิล์มต้อง *ถูกดึงผ่านช่อง*
//    กองรูปต้อง *ถูกลอกทีละใบ* สไลด์ต้อง *เลื่อนไปใบถัดไป* ไม่ใช่จางหายเหมือนกันทั้งแปดตัว

/// วัสดุของสำรับนี้ — สีคงที่ ไม่พลิกตามหมึกการ์ด
///
/// เหตุผลเดียวกับ `Paper`/`Vinyl`: กระดาษกับฟิล์มคือพื้นผิว *ของตัวมันเอง*
/// ถ้าปล่อยให้พลิกตามพื้นการ์ด อุปมา "ของที่จับต้องได้" หายทันทีบนการ์ดพื้นสว่าง
private enum Snap {
    /// ขอบกระดาษอัดรูป
    static let paper = Color(red: 0.99, green: 0.99, blue: 0.98)
    /// ฟิล์มเนกาทีฟ — ดำอมน้ำตาล ไม่ใช่ดำสนิท
    static let stock = Color(red: 0.09, green: 0.08, blue: 0.09)
    static let stockEdge = Color(red: 0.16, green: 0.15, blue: 0.16)
    /// ตัวเลขขอบฟิล์ม
    static let filmMark = Color(red: 0.98, green: 0.62, blue: 0.20)
    /// เทปกาววาชิ — โปร่งพอให้เห็นรูปข้างใต้
    static let tape = Color(red: 1.00, green: 0.97, blue: 0.86)
}

/// ช่องรูปหนึ่งช่องของสำรับนี้ — clip + ขอบเส้นผม + `photoSlot` ครบในที่เดียว
///
/// แยกจาก `BentoCell` ของ `ArtWidgets` เพราะตัวนั้น private อยู่ในไฟล์นั้น
/// และตัวนี้ต้องรับ "ทิศถ่วง" เป็นเวกเตอร์ (บอร์ดพินถ่วงแนวตั้ง ไม่ใช่แนวนอน)
private struct SnapCell: View {
    let slot: Int
    var radius: CGFloat = 14
    var d: CGFloat = 0
    /// ระยะถ่วงสวนทางหน้า เป็น pt
    var shift: CGFloat = 0
    var zoom: CGFloat = 0.16
    var border: Bool = true

    @Environment(\.cardInk) private var ink

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Color.clear
            .overlay {
                WidgetPhoto(index: slot)
                    .aspectRatio(contentMode: .fill)
                    .scrubDolly(d, shift: shift, zoom: zoom)
            }
            .clipShape(shape)
            .overlay {
                if border { shape.strokeBorder(ink.line(0.12), lineWidth: 0.6) }
            }
            .photoSlot(slot)
    }
}

/// ผลงานชิ้นแรก — ใช้เป็นแหล่งตัวเลขของแบบที่จำลอง "หน้าตาตอนลงจริง"
private var firstWork: VerifiedWork? { Mock.creator.track.works.first }

// MARK: - 01 · บอร์ดพิน

/// สองคอลัมน์ความสูงไม่เท่ากัน — ผังเดียวกับบอร์ดที่คนรุ่นนี้เซฟรูปกันทุกวัน
///
/// ต่างจากเบนโตะตรงที่เบนโตะ *จัดให้* ว่าชิ้นไหนสำคัญ (ช่องใหญ่กินสายตาก่อน)
/// ส่วนบอร์ดพินไม่จัดลำดับให้เลย — ทุกใบเท่ากันในสายตา ต่างกันแค่สัดส่วนที่ถ่ายมา
/// ซึ่งเป็นความรู้สึกที่ถูกต้องเวลาโชว์ "กองงานทั้งปี" ไม่ใช่ "ชิ้นที่ภูมิใจที่สุด"
///
/// ห้าช่องเป็นจำนวนที่วัดแล้วลงตัวที่สุด: สี่ช่องอ่านเป็นกริด หกช่องขึ้นไปช่องเริ่มเล็กจนดูไม่ออก
///
/// # ท่าเปลี่ยนหน้า — "สองคอลัมน์ไหลสวนกัน"
///
/// คอลัมน์ซ้ายไหลลง ขวาไหลขึ้น — ความลึกมาจาก *ทิศที่ต่างกัน* ไม่ใช่จากเงา
/// (กฎเดียวกับ `ArtPair`) แล้วแต่ละช่องหุบไล่กันจากฝั่งที่หน้ากำลังไป
struct GalleryMasonry: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    private let left = [4, 5]
    private let right = [6, 7, 8]

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 7
            let w = (geo.size.width - gap) / 2
            let h = geo.size.height

            HStack(alignment: .top, spacing: gap) {
                column(left, w: w, ratios: [0.44, 0.56], h: h, gap: gap, from: 0, drift: 16)
                column(right, w: w, ratios: [0.3, 0.36, 0.34], h: h, gap: gap, from: 2, drift: -16)
            }
        }
    }

    /// คอลัมน์เดียว — `from` คือลำดับเริ่มต้นของช่องในขบวนรวม (ห้าช่องหุบไล่กันทั้งบอร์ด)
    private func column(_ slots: [Int], w: CGFloat, ratios: [CGFloat],
                        h: CGFloat, gap: CGFloat, from: Int, drift: CGFloat) -> some View {
        let inner = h - gap * CGFloat(slots.count - 1)
        return ScrubReader(d: scrub.d) { d in
            VStack(spacing: gap) {
                ForEach(Array(slots.enumerated()), id: \.element) { i, slot in
                    SnapCell(slot: slot, radius: 14, d: scrub.d,
                             shift: w * 0.06, zoom: 0.18)
                        .frame(width: w, height: inner * ratios[i])
                        .scrubAperture(scrub.d,
                                       lead: Scrub.lead(from + i, of: 5, d: scrub.d, step: 0.09),
                                       feather: 0.22, dim: 0.5)
                }
            }
            // ไหลสวนกันตามแกนตั้ง — `scrubSlide` ทำได้แค่แกนนอน ท่านี้จึงเขียนเอง
            .offset(y: drift * Scrub.ease(Scrub.t(d)))
        }
        .frame(width: w, height: h, alignment: .top)
    }
}

// MARK: - 02 · กองรูปซ้อน

/// สามใบซ้อนกันแบบไพ่ที่เพิ่งคลี่ — ใบบนสุดคือใบที่อยากให้เห็น อีกสองใบคือคำสัญญาว่ายังมีอีก
///
/// นี่คือแบบที่ควรหยิบตอน **มีรูปดีจริงแค่ไม่กี่ใบ** — กริดสี่ช่องกับรูปดีสามใบจะเหลือช่องหนึ่ง
/// ที่ต้องเอารูปรอง ๆ มาถม แล้วทั้งกริดถูกลากลงไปเท่ากับใบที่แย่ที่สุด กองซ้อนไม่มีปัญหานั้น
/// เพราะสายตาอ่านใบบนสุดเป็นเนื้อหา และอ่านใบล่างเป็น *ความหนา* ไม่ใช่ *เนื้อหา*
///
/// # ท่าเปลี่ยนหน้า — "ลอกใบบนออกจากกอง"
///
/// ใบบนหมุนออกแล้วไถลตามทิศนิ้ว ขณะที่สองใบล่าง **ตั้งตรงขึ้นและโตขึ้น** —
/// เพราะของที่อยู่ล่างสุดของกองจะขยับขึ้นมาเป็นใบบนเสมอ ไม่ใช่หายไปพร้อมกัน
struct GalleryStack: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    /// ใบล่างสุดอยู่ต้นลิสต์ — วาดตามลำดับ ZStack จึงได้ใบแรกอยู่หลังสุด
    private let slots = [6, 5, 4]
    private let angles: [Double] = [-8, 4.5, -1.5]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let cardW = min(w * 0.78, h * 0.74)
            let cardH = min(h * 0.94, cardW * 1.3)

            ZStack {
                ForEach(Array(slots.enumerated()), id: \.element) { i, slot in
                    card(slot, i: i, w: cardW, h: cardH)
                }
            }
            .frame(width: w, height: h)
        }
    }

    private func card(_ slot: Int, i: Int, w: CGFloat, h: CGFloat) -> some View {
        /// ใบบนสุด = ตัวสุดท้ายในลิสต์
        let isTop = i == slots.count - 1
        let rest = CGFloat(slots.count - 1 - i)       // 2, 1, 0 นับจากใบล่างสุด

        return ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d, lead: isTop ? 0 : 0.12))
            let s = Double(Scrub.dir(d))

            SnapCell(slot: slot, radius: 10, d: scrub.d,
                     shift: isTop ? 14 : 0, zoom: 0.16, border: false)
                .frame(width: w, height: h)
                .padding(5)
                .background(Snap.paper)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.34), radius: 10 - rest * 2, y: 5)
                // ใบล่างตั้งตรงขึ้นเมื่อใบบนกำลังไป — กองที่บางลงต้องเรียงตัวใหม่เสมอ
                .rotationEffect(.degrees(isTop ? angles[i] + s * 22 * Double(t)
                                               : angles[i] * (1 - 0.75 * Double(t))))
                .offset(x: isTop ? CGFloat(s) * w * 0.5 * t : rest * 3 * (1 - t),
                        y: rest * 5 * (1 - t))
                .scaleEffect(isTop ? 1 - 0.1 * t : 1 - 0.05 * rest + 0.05 * rest * t)
                .opacity(isTop ? Scrub.fade(t, after: 0.45) : 1)
        }
    }
}

// MARK: - 03 · โมเสก

/// เก้าช่องเท่ากันเป๊ะ — คอนแทกต์ชีตที่หนาแน่นที่สุดในตู้
///
/// ตัวนี้มีไว้ตอบสถานการณ์เดียว: **มีงานเยอะจนการเลือกมาโชว์ 3–4 ชิ้นคือการขายตัวเองต่ำไป**
/// ความหนาแน่นคือสาร — แบรนด์ที่เห็นเก้าช่องเต็มอ่านออกทันทีว่าคนนี้ทำงานสม่ำเสมอ
/// ซึ่งเป็นข้อมูลที่ตัวเลข "ส่งงานแล้ว 24 ชิ้น" บอกไม่ได้เท่า
///
/// ช่องเล็กจึงต้อง **ไม่มีขอบ** และร่องแคบ (4pt) — ขอบเส้นผมเก้าเส้นในพื้นที่เท่านี้
/// อ่านออกมาเป็นตารางสเปรดชีตทันที
///
/// # ท่าเปลี่ยนหน้า — "กวาดทแยง"
///
/// ดับไล่ตามแนวทแยง (แถว+คอลัมน์) ไม่ใช่ไล่ทีละแถว — แนวทแยงคือเส้นทางที่ตาอ่านกริดอยู่แล้ว
struct GalleryMosaic: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    private let slots = [4, 5, 6, 7, 8, 9, 10, 11, 0]

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 4
            let w = (geo.size.width - gap * 2) / 3
            let h = (geo.size.height - gap * 2) / 3

            ScrubReader(d: scrub.d) { d in
                VStack(spacing: gap) {
                    ForEach(0..<3, id: \.self) { r in
                        HStack(spacing: gap) {
                            ForEach(0..<3, id: \.self) { c in
                                tile(slots[r * 3 + c], diag: r + c, w: w, h: h, d: d)
                            }
                        }
                    }
                }
            }
        }
    }

    /// หนึ่งช่อง — `diag` คือลำดับบนแนวทแยง (0…4) ใช้เป็นลำดับในขบวนดับ
    private func tile(_ slot: Int, diag: Int, w: CGFloat, h: CGFloat, d: CGFloat) -> some View {
        let k = CGFloat(Scrub.cell(diag, of: 5, d: d, spill: 1.6))
        return SnapCell(slot: slot, radius: 7, d: scrub.d, shift: w * 0.1, zoom: 0.22,
                        border: false)
            .frame(width: w, height: h)
            .scaleEffect(0.86 + 0.14 * k)
            .opacity(Double(k))
    }
}

// MARK: - 04 · โพสต์โซเชียล

/// รูปหนึ่งใบในกรอบที่มันถูกโพสต์จริง — หัวโพสต์ · รูป · แถวปฏิสัมพันธ์
///
/// ทำไมต้องมีทั้งที่ `GalleryStack` ก็โชว์รูปอยู่แล้ว: ตัวนี้เอารูปไปวางใน *กรอบของแพลตฟอร์ม*
/// ซึ่งอ่านออกมาคนละอย่างกับรูปที่ลอยอยู่บนการ์ด — แบรนด์เห็นกรอบโพสต์แล้วอ่านทันทีว่า
/// "นี่คือของที่ลงไปแล้ว" ไม่ใช่ "รูปสวยที่ครีเอเตอร์เลือกมาใส่พอร์ต"
///
/// # ทำไมไม่มีตัวอักษรสักตัว
///
/// ทั้งตระกูล `.photo` ถอดข้อความออกหมดแล้ว (ดูหัวไฟล์) — กรอบโพสต์เคยมีชื่อผู้ใช้
/// ชื่อแบรนด์ และยอดวิวกำกับ ซึ่งกินสามบรรทัดของแผ่นเล็ก ๆ ไปเพื่อบอกสิ่งที่ตระกูล
/// `.verified` บอกได้ดีกว่าอยู่แล้ว · ที่เหลือคือ **รูปกับสัญลักษณ์ของแพลตฟอร์ม**
/// ซึ่งเป็นสองอย่างที่ทำให้มันยังเป็น "โพสต์" อยู่โดยไม่ต้องมีตัวหนังสือ
///
/// # ท่าเปลี่ยนหน้า — "โพสต์ถูกเลื่อนพ้นจอ"
///
/// หัวกับแถวล่างมุดหายก่อน (ของรอบนอกไปก่อนเสมอ) แล้วรูปค่อยหุบตามทีหลัง
struct GalleryPost: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    private var work: VerifiedWork? { firstWork }

    var body: some View {
        VStack(spacing: 9) {
            header
            SnapCell(slot: 4, radius: 14, d: scrub.d, shift: 20, zoom: 0.18)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scrubAperture(scrub.d, lead: 0.16, feather: 0.2, dim: 0.5)
            footer
        }
    }

    /// หัวโพสต์ — รูปโปรไฟล์กลม + โลโก้แพลตฟอร์ม
    /// แถบชื่อที่เคยอยู่ตรงกลางถูกถอดออก · ที่ว่างปล่อยไว้เฉย ๆ ไม่เอาอะไรมาแทน
    /// เพราะสิ่งที่ทำให้หัวแถบนี้อ่านเป็น "หัวโพสต์" คือ *วงกลมซ้าย + โลโก้ขวา* ไม่ใช่ชื่อ
    private var header: some View {
        HStack(spacing: 8) {
            SnapCell(slot: 3, radius: 999, d: scrub.d, shift: 0, zoom: 0, border: false)
                .frame(width: 26, height: 26)
                .overlay(Circle().strokeBorder(ink.line(0.2), lineWidth: 0.6))
            Spacer(minLength: 4)
            if let w = work { BrandIcon(name: w.platform.icon, size: 13) }
        }
        .scrubVeil(scrub.d, lead: 0.3, drop: 18, pull: 10)
    }

    /// แถวล่าง — ไอคอนปฏิสัมพันธ์ซ้าย · ที่คั่นขวา
    ///
    /// ไม่มีตัวเลขกำกับไอคอนแล้ว และนั่นถูกแล้ว: ไอคอนสามตัวนี้ไม่ได้อยู่ตรงนี้เพื่อรายงานยอด
    /// (ยอดจริงอยู่ในตระกูล `ผลงานยืนยัน`) แต่อยู่เพื่อบอกว่า *นี่คือกรอบของโพสต์*
    /// ซึ่งไอคอนเปล่า ๆ ก็บอกได้ครบเท่ากับตอนมีตัวเลข
    private var footer: some View {
        HStack(spacing: 14) {
            ForEach(Array(["heart", "bubble.right", "paperplane"].enumerated()), id: \.element) { i, n in
                Image(systemName: n)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(ink.text(0.55))
                    .scrubVeil(scrub.d, lead: 0.24 + Double(i) * 0.04, drop: 16, pull: 10)
            }
            Spacer(minLength: 0)
            Image(systemName: "bookmark")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(ink.text(0.55))
                .scrubVeil(scrub.d, lead: 0.36, drop: 16, pull: 10)
        }
    }
}

// MARK: - 05 · สตอรี่

/// เฟรม 9:16 พร้อมแถบความคืบหน้าด้านบน — ฟอร์แมตที่คนรุ่นนี้เปิดดูวันละหลายร้อยครั้ง
///
/// นี่คือแบบเดียวในตู้ที่ **สัดส่วนเป็นสาร**: 9:16 บอกว่างานนี้ถ่ายมาเพื่อจอมือถือแนวตั้ง
/// ไม่ใช่รูปแนวนอนที่ถูกครอปมาใส่ช่อง ซึ่งเป็นเรื่องที่แบรนด์ต้องรู้ก่อนจ้างถ่ายคลิป
/// ขนาดตั้งต้นจึงเป็น 3 คอลัมน์ (ครึ่งหน้า) ไม่ใช่เต็มหน้า — เต็มหน้าแล้วสูงเกินหน้ากระดาษ
///
/// # ท่าเปลี่ยนหน้า — "สตอรี่เดินไปช่องถัดไป"
///
/// แถบช่องที่สองเติมตามระยะนิ้วจริง ๆ แล้วพอเต็มก็ข้ามไปช่องที่สาม
/// ผู้ใช้จึงเห็นด้วยตาว่าการปัดคือการ *ดูต่อ* ไม่ใช่การ *ทิ้งหน้านี้ไป*
/// (อุปมาเดียวกับหัวอ่านวิดีโอใน `WorkReel` — ทั้งการ์ดใช้ภาษา seek ชุดเดียวกัน)
struct GalleryStory: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        ZStack {
            Color.clear
                .overlay {
                    WidgetPhoto(index: 5)
                        .aspectRatio(contentMode: .fill)
                        .scrubDolly(scrub.d, shift: 26, zoom: 0.22)
                }

            LinearGradient(colors: [.black.opacity(0.55), .clear, .clear, .black.opacity(0.62)],
                           startPoint: .top, endPoint: .bottom)

            VStack(spacing: 0) {
                bars
                head
                Spacer(minLength: 0)
                foot
            }
            .padding(9)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(shape)
        .photoSlot(5)
    }

    /// แถบความคืบหน้าสามช่อง — ช่องแรกดูจบแล้ว ช่องที่สองกำลังเดิน ช่องที่สามยังไม่ถึง
    private var bars: some View {
        ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d))
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(.white.opacity(0.28))
                        .frame(height: 2.5)
                        .overlay(alignment: .leading) {
                            GeometryReader { g in
                                Capsule().fill(.white.opacity(0.95))
                                    .frame(width: g.size.width * fill(i, t: t))
                            }
                        }
                }
            }
        }
        .frame(height: 2.5)
    }

    /// สัดส่วนที่เติมของแถบที่ `i` — ช่องก่อนหน้าเต็มเสมอ ช่องปัจจุบันเดินตามนิ้ว
    private func fill(_ i: Int, t: CGFloat) -> CGFloat {
        switch i {
        case 0: return 1
        case 1: return min(1, t * 2)
        default: return max(0, t * 2 - 1)
        }
    }

    /// หัวสตอรี่ — วงกลมรูปโปรไฟล์ที่มีขอบขาว ไม่มีชื่อกำกับ
    private var head: some View {
        HStack(spacing: 7) {
            SnapCell(slot: 3, radius: 999, d: scrub.d, shift: 0, zoom: 0, border: false)
                .frame(width: 22, height: 22)
                .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 1.2))
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .scrubVeil(scrub.d, lead: 0.3, drop: 16, pull: 10)
    }

    /// แถบล่าง — ป้าย "ปัดขึ้น" ที่เป็นลูกศรล้วน
    ///
    /// แคปชันกับยอดวิวถูกถอดออกตามกติกาของตระกูล (ดูหัวไฟล์) เหลือสัญลักษณ์เดียวที่
    /// ทำให้เฟรมนี้ยังอ่านเป็นสตอรี่: ลูกศรชวนปัด ซึ่งเป็นของที่ทุกคนจำได้โดยไม่ต้องมีคำกำกับ
    private var foot: some View {
        HStack {
            Spacer(minLength: 0)
            Image(systemName: "chevron.up")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(Capsule().fill(.black.opacity(0.42)))
                .overlay(Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 0.5))
                .scrubVeil(scrub.d, lead: 0.34, drop: 20, pull: 8)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - 06 · ฟิล์ม 35 มม.

/// สามเฟรมบนฟิล์มเนกาทีฟ — รูพรุนสองแถว ตัวเลขขอบส้ม เอียงเล็กน้อย
///
/// ต่างจาก `ArtFilmstrip` ตรงที่ตัวนั้นคือ *คอนแทกต์ชีต* (เฟรมลอยบนการ์ด เนี้ยบ ไม่มีวัสดุ)
/// ส่วนตัวนี้คือ *ฟิล์มจริงที่ยกขึ้นส่องไฟ* — มีสต็อกดำ มีรูพรุน มีเลขเฟรม
/// เรื่องเดียวกัน คนละความรู้สึก ซึ่งคือทั้งหมดที่ตระกูลนี้ต้องการจากแบบใหม่
/// (ตรรกะเดียวกับที่ `ArtPhotobooth` มีอยู่คู่กับแถบภาพ)
///
/// # ท่าเปลี่ยนหน้า — "ฟิล์มถูกดึงผ่านช่อง"
///
/// ทั้งม้วนเดินไปหนึ่งเฟรมพอดี (ระยะ = ความกว้างเฟรม + ร่อง) ขณะที่หน้าต่างแต่ละเฟรมหุบไล่กัน
struct GalleryFilm: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    private let slots = [4, 5, 6]

    var body: some View {
        GeometryReader { geo in
            let pad: CGFloat = 5
            let gap: CGFloat = 4
            let hole = max(4.5, geo.size.height * 0.1)
            let n = slots.count
            let fw = (geo.size.width - pad * 2 - gap * CGFloat(n - 1)) / CGFloat(n)

            VStack(spacing: 3) {
                sprockets(hole)
                HStack(spacing: gap) {
                    ForEach(Array(slots.enumerated()), id: \.element) { i, slot in
                        SnapCell(slot: slot, radius: 3, d: scrub.d,
                                 shift: fw * 0.09, zoom: 0.2, border: false)
                            .frame(width: fw)
                            .scrubAperture(scrub.d,
                                           lead: Scrub.lead(i, of: n, d: scrub.d, step: 0.1),
                                           feather: 0.22, dim: 0.5)
                    }
                }
                .frame(maxHeight: .infinity)
                // เดินหนึ่งเฟรมพอดี — สั้นกว่านี้อ่านเป็น "ไถล" ไม่ใช่ "เดินเฟรม"
                .scrubSlide(scrub.d, travel: fw + gap, fade: 0.85)
                sprockets(hole)
            }
            .padding(pad)
            .frame(width: geo.size.width, height: geo.size.height)
            .background(
                LinearGradient(colors: [Snap.stockEdge, Snap.stock, Snap.stockEdge],
                               startPoint: .top, endPoint: .bottom)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .rotationEffect(.degrees(-1.2))
            .shadow(color: .black.opacity(0.35), radius: 10, y: 5)
        }
    }

    /// แถวรูพรุน — รูขนาดคงที่แล้วปล่อยให้จำนวนวิ่งตามความกว้าง (ฟิล์มจริงระยะรูคงที่เสมอ)
    ///
    /// เคยมีเลขขอบฟิล์ม ("STARCARD 400") พิมพ์ทับแถวบนแบบฟิล์มจริง — ถอดออกตามกติกา
    /// ของตระกูลที่ว่าห้ามมีตัวอักษร · สิ่งที่ทำให้มันเป็นฟิล์มคือรูพรุนกับสต็อกดำ ไม่ใช่เลขนั้น
    private func sprockets(_ h: CGFloat) -> some View {
        GeometryReader { g in
            let step = h * 1.55
            let n = max(3, Int(g.size.width / step))
            HStack(spacing: 0) {
                ForEach(0..<n, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1.4, style: .continuous)
                        .fill(Color.black.opacity(0.55))
                        .frame(width: h * 0.72, height: h * 0.62)
                        .frame(width: step)
                }
                Spacer(minLength: 0)
            }
            // ขีดส้มริมขอบ — ที่เดิมของเลขขอบฟิล์ม เก็บ *สี* ของฟิล์มไว้โดยไม่ต้องมีตัวหนังสือ
            .overlay(alignment: .trailing) {
                Capsule()
                    .fill(Snap.filmMark.opacity(0.9))
                    .frame(width: h * 1.6, height: h * 0.22)
                    .scrubVeil(scrub.d, lead: 0.36, drop: 10, pull: 6)
            }
        }
        .frame(height: h)
    }
}

// MARK: - 07 · เทปกาว

/// สามใบวางทับกันแบบแปะบนโต๊ะ — เอียงคนละองศา มีเทปวาชิคาดหัว
///
/// คู่กับ `กองรูปซ้อน` ในสถานการณ์ "มีรูปดีไม่กี่ใบ" แต่ตอบคนละอารมณ์:
/// กองซ้อนคือของที่ *ยังไม่ถูกคลี่* (เรียบร้อย มีลำดับ) ส่วนตัวนี้คือของที่ *ถูกแปะไว้แล้ว*
/// — ไม่มีลำดับ ไม่มีกริด อ่านออกมาเป็นมู้ดบอร์ดของเจ้าตัว ไม่ใช่ผลงานที่ระบบจัดให้
///
/// องศาเอียงต้องไม่เท่ากันสักใบ และต้องไม่หารลงตัว — เอียง 5° เท่ากันทุกใบ
/// อ่านออกมาเป็น "เอฟเฟกต์" ทันที ไม่ใช่ "ของที่คนแปะ"
///
/// # ท่าเปลี่ยนหน้า — "ลอกทีละใบ"
///
/// แต่ละใบหมุนขึ้นแล้วลอยออกไล่กัน (กฎเดียวกับ `StickerTags`) — ของที่ *ถูกแปะ*
/// ต้องหมุนออกจากผิวเสมอ ไม่ใช่จางหายอยู่กับที่
struct GalleryTape: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    /// ช่อง · จุดกลาง (สัดส่วนของกรอบ) · องศา · ความกว้าง (สัดส่วน)
    private let pieces: [(slot: Int, x: CGFloat, y: CGFloat, rot: Double, w: CGFloat)] = [
        (4, 0.31, 0.46, -7.5, 0.50),
        (5, 0.70, 0.36,  5.0, 0.42),
        (6, 0.62, 0.74, -2.5, 0.40),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                ForEach(Array(pieces.enumerated()), id: \.offset) { i, p in
                    piece(p, i: i, box: CGSize(width: w, height: h))
                }
            }
            .frame(width: w, height: h)
        }
    }

    private func piece(_ p: (slot: Int, x: CGFloat, y: CGFloat, rot: Double, w: CGFloat),
                       i: Int, box: CGSize) -> some View {
        let pw = box.width * p.w
        let ph = min(pw * 1.25, box.height * 0.72)

        return ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d, lead: Scrub.lead(i, of: pieces.count,
                                                           d: d, step: 0.11)))
            let s = Double(Scrub.dir(d))

            SnapCell(slot: p.slot, radius: 3, d: scrub.d, shift: pw * 0.06,
                     zoom: 0.16, border: false)
                .frame(width: pw, height: ph)
                .padding(4)
                .background(Snap.paper)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay(alignment: .top) { washi(width: pw * 0.52) }
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                .rotationEffect(.degrees(p.rot + s * 16 * Double(t)))
                .scaleEffect(1 - 0.16 * t)
                .opacity(Scrub.fade(t, after: 0.5))
        }
        .frame(width: pw + 30, height: ph + 30)
        .position(x: box.width * p.x, y: box.height * p.y)
    }

    /// เทปคาดหัวใบ — วางคร่อมขอบ ไม่ใช่วางข้างใน
    /// ของที่ล้นออกนอกกรอบคือสิ่งที่ทำให้แผ่นอ่านเป็นของจริง (บทเรียนจาก `ArtPhotobooth`)
    private var washiHeight: CGFloat { 13 }

    private func washi(width: CGFloat) -> some View {
        Rectangle()
            .fill(Snap.tape.opacity(0.72))
            .frame(width: width, height: washiHeight)
            .overlay(Rectangle().strokeBorder(.white.opacity(0.5), lineWidth: 0.5))
            .rotationEffect(.degrees(-3))
            .offset(y: -washiHeight * 0.45)
    }
}

// MARK: - 08 · สไลด์การ์ด

/// การ์ดใบใหญ่หนึ่งใบ กับใบถัดไปโผล่มาให้เห็นครึ่งเดียว + จุดบอกตำแหน่ง
///
/// ผังนี้ตอบสถานการณ์ที่กริดทุกแบบตอบไม่ได้: **อยากให้คนดูทีละใบ แต่ต้องรู้ว่ายังมีอีก**
/// กริดให้ดูพร้อมกันหมด (ตาเลือกเอง) ส่วนใบเดี่ยวไม่บอกว่ามีอีก — ใบที่โผล่มาครึ่งใบ
/// คือสิ่งเดียวที่ทำให้คนรู้ว่าต้องเลื่อนต่อ ซึ่งเป็นภาษาที่แอปทุกตัวสอนคนรุ่นนี้มาแล้ว
///
/// # ท่าเปลี่ยนหน้า — "สไลด์เดินไปใบถัดไปจริง ๆ"
///
/// รางเลื่อนไปหนึ่งใบพอดีตามทิศนิ้ว ใบที่โผล่มาครึ่งใบขยายขึ้นมาเป็นใบเต็ม
/// และ **จุดบอกตำแหน่งเดินตามไปด้วย** — จุดที่ไม่เดินตามคือจุดที่ทำให้ทั้งท่าอ่านเป็นของปลอม
struct GalleryCarousel: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    private let slots = [4, 5, 6]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let gap: CGFloat = 8
            let cardW = w * 0.84
            let dots: CGFloat = 16

            ScrubReader(d: scrub.d) { d in
                let t = Scrub.ease(Scrub.t(d))
                // ตำแหน่งบนรางเป็นทศนิยม — ใช้ทั้งเลื่อนราง ย่อ/ขยายใบ และเดินจุด
                let pos = Scrub.dir(d) > 0 ? t : -t

                VStack(spacing: 7) {
                    HStack(spacing: gap) {
                        ForEach(Array(slots.enumerated()), id: \.element) { i, slot in
                            SnapCell(slot: slot, radius: 16, d: scrub.d,
                                     shift: cardW * 0.07, zoom: 0.2)
                                .frame(width: cardW, height: h - dots)
                                .scaleEffect(scale(i, pos: pos))
                                .opacity(dim(i, pos: pos))
                        }
                    }
                    .frame(width: w, height: h - dots, alignment: .leading)
                    .offset(x: -pos * (cardW + gap))

                    dotRow(pos: pos)
                        .frame(height: dots - 7)
                }
                .frame(width: w, height: h, alignment: .top)
                .clipped()
            }
        }
    }

    /// ใบที่อยู่ตรงตำแหน่งปัจจุบันเต็มขนาด ใบข้าง ๆ ย่อ — ระยะห่างเป็นตัวคุม ไม่ใช่ลำดับ
    private func scale(_ i: Int, pos: CGFloat) -> CGFloat {
        1 - 0.07 * min(1, abs(CGFloat(i) - pos))
    }

    private func dim(_ i: Int, pos: CGFloat) -> Double {
        Double(1 - 0.35 * min(1, abs(CGFloat(i) - pos)))
    }

    /// จุดบอกตำแหน่ง — จุดที่ active ยืดเป็นขีด แล้วยืด/หดไล่ตามตำแหน่งบนราง
    private func dotRow(pos: CGFloat) -> some View {
        HStack(spacing: 4) {
            ForEach(slots.indices, id: \.self) { i in
                let k = max(0, 1 - abs(CGFloat(i) - pos))
                Capsule()
                    .fill(ink.text(0.25 + 0.6 * Double(k)))
                    .frame(width: 5 + 9 * k, height: 5)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
