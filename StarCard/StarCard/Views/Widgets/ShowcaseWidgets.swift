import SwiftUI

// MARK: - แผ่นโชว์คลิป
//
// # ใบนี้มาจากไหน
//
// แผ่นพรีเซนต์ที่เจ้าของการ์ดส่งมา: หัวเรื่องนิตยสาร (`Recent` เซริฟเอียง คร่อมคำยักษ์
// `VIDEOGRAPHY`) แล้วเครื่องสี่เครื่องเรียงหน้ากระดาน · ใต้แต่ละเครื่องคือชื่อลูกค้า
// กับสรุปสั้น ๆ ว่างานชิ้นนั้นทำอะไร — **ผัง สัดส่วน และวัสดุตามต้นฉบับ · ฟอนต์ของแอป**
// (กติกาเดิมของสำรับบรรณาธิการ ดู `EditorialWidgets.swift`)
//
// # ทำไมไม่เอาไปอยู่ตระกูล "รูปผลงาน"
//
// สำรับกองรูปมีกติกาข้อหนึ่งว่า **ห้ามมีตัวอักษรสักตัว** — ใบนี้กลับกันทั้งใบ:
// ตัวอักษรของมันคือผัง กด "แบบอื่น" ไปเป็นกองรูปเมื่อไหร่ ชื่อลูกค้ากับคำบรรยาย
// ที่พิมพ์ไว้หายทันที ซึ่งผิดสัญญาของตระกูล (ดู `WidgetFamily`) มันจึงมีตระกูลของตัวเอง
//
// # มีแผ่นรอง / ไม่มีแผ่นรอง
//
// สองแบบที่ผู้ใช้ขอเป็น **ปุ่มเดียวในถาด** (กล่อง › มีพื้น / ไม่มีพื้น) ไม่ใช่สองใบในตู้ —
// เนื้อหาชุดเดียวกันเป๊ะ ต่างกันแค่แผ่นสีเข้มที่รองอยู่ ถ้าแยกเป็นสองใบ คนที่พิมพ์ข้อความ
// ไว้แล้วอยากลองอีกแบบต้องพิมพ์ใหม่ทั้งแผ่น · ถอดแผ่นแล้วหมึกพลิกไปใช้หมึกของการ์ด
// เครื่องทั้งสี่จึงยังอ่านออกทั้งบนการ์ดกระดาษและการ์ดมืด

/// ผังของแผ่น — **หน่วย pt ที่ความกว้างออกแบบ 366** (ตรงกับ `WidgetKind.defaultSize`)
///
/// ผังเขียนเป็นตัวเลขจริงครั้งเดียวที่ขนาดนี้ แล้ว `WidgetChrome` ย่อ/ขยายทั้งก้อนให้ตามกรอบ
/// (กรอบที่ไม่ตรงสัดส่วนนี้ได้ที่ว่างเพิ่มในแกนที่กว้างกว่า — ไม่มีสูตร responsive ในไฟล์นี้)
private enum Reel {
    static let w: CGFloat = 366
    /// ความสูงของผัง — **หดลงจาก 284 หลังถอดคำบรรยายออก**
    ///
    /// สามบรรทัดใต้ชื่อลูกค้ากินความสูงราว 24pt แล้วยังบังคับให้แผ่นสูงตาม · พอเหลือแต่ชื่อ
    /// ที่ว่างนั้นถูกยกให้ **ตัวเครื่อง** ทั้งก้อน ไม่ใช่คืนเป็นขอบว่างของแผ่น
    static let h: CGFloat = 254

    // ขอบแคบกว่าเดิมทุกด้าน — แผ่นนี้ขายรูป ขอบคือที่ว่างที่กินพื้นที่รูปไปตรง ๆ
    static let pad: CGFloat = 8
    static let padTop: CGFloat = 10
    static let padBottom: CGFloat = 9

    /// เครื่องหนึ่งเครื่อง — สัดส่วน 1:1.87 ใกล้เคียงตัวเครื่องจริงที่ครอบจอ 9:19.5
    ///
    /// กว้างขึ้นจาก 78 → 82 และสูงขึ้นจาก 146 → 153 (สัดส่วนเดิมเป๊ะ) — ความกว้างมาจาก
    /// ที่ว่างที่เหลือจริงหลังหักขอบกับร่อง: (366 − 8×2 − 7×3) ÷ 4 · ไม่มีขอบว่างเหลือให้เห็น
    static let phoneW: CGFloat = 82
    static let phoneH: CGFloat = 153
    static let gutter: CGFloat = 7
    /// ชื่อลูกค้ากว้างเท่าตัวเครื่อง — ไม่ล้นออกไปกินร่องระหว่างเครื่องอีกแล้ว
    static let capW: CGFloat = 82

    static let recentSize: CGFloat = 19
    static let recentBox: CGFloat = 23
    /// คำยักษ์ถูกวัดให้ **กว้างเท่านี้เสมอ** ไม่ว่าเจ้าของการ์ดจะพิมพ์คำไหนลงไป
    static let titleWidth: CGFloat = 252
    static let titleCap: CGFloat = 30
    static let titleBox: CGFloat = 36
    /// คำเซริฟคร่อมคำยักษ์ตามต้นฉบับ — ไม่ใช่สองบรรทัดที่วางต่อกัน
    static let titleOverlap: CGFloat = 3

    static let slots = 4
}

/// วัสดุของแผ่น — ตอบสองข้อพร้อมกัน: มีแผ่นรองไหม และ **หมึกเป็นของใคร**
///
/// เหตุผลเดียวกับ `EdSkin`: ถ้าถอดแผ่นแล้วยังใช้หมึกครีมของแผ่น ตัวหนังสือจะหายไป
/// ทั้งใบบนการ์ดกระดาษ — ซึ่งอ่านเป็น "ปิดพื้นแล้วแอปพัง" ไม่ใช่ "ปิดพื้นแล้วไม่มีกรอบ"
private struct ReelSkin {
    var sheet: Color
    var papered: Bool
    var ink: Color
    var inkSoft: Color
    /// ตัวเครื่อง — บนแผ่นเข้มเป็นถ่านเกือบดำ · บนการ์ดมืดต้องยกขึ้นเป็นกราไฟต์
    /// ไม่งั้นเครื่องสี่เครื่องกลายเป็นรูสี่รูที่เจาะทะลุการ์ด
    var bezel: Color
    var rim: Color
}

/// คลิปล่าสุด — หัวเรื่องนิตยสาร + เครื่องสี่เครื่อง + ชื่อลูกค้ากับสรุปงานใต้แต่ละเครื่อง
///
/// # สีของแผ่นคือ **สีที่เจ้าของการ์ดเลือก** ไม่ใช่สีที่ใบนี้คิดเอง
///
/// ต้นฉบับเป็นเลือดหมู แต่สีตายตัวบนการ์ดที่เจ้าของเลือกพาเลตต์เองได้อ่านเป็น
/// *ของที่หลงมาจากไฟล์อื่น* — และเป็นการตัดสินใจแทนเขาในเรื่องที่เขาเพิ่งตัดสินใจไปแล้ว
/// เฉดของแผ่นจึงมาจาก `backdropHue` ของการ์ด (พาเลตต์ที่เลือก หรือสีที่ตั้งเอง)
///
/// ใช้สูตรกลาง `PosterPlate` ตัวเดียวกับ **โปสเตอร์สายงาน** เพราะสองใบนี้ไปอยู่บนหน้าเดียวกันได้
/// ถ้าต่างคนต่างคิดสี การ์ดจะมีแผ่นเลือดหมูสองเฉดที่ไม่ตรงกันวางซ้อนกัน
struct ReelShowcase: View {
    let theme: CardTheme
    let size: CGSize

    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var cardInk
    @Environment(\.widgetID) private var wid

    private var skin: ReelSkin {
        if surface == .pane {
            // กระจกของ chrome เป็นพื้น — แผ่นใส แต่ผังยังเป็นแผ่นพิมพ์ใบเดิม
            return ReelSkin(sheet: .clear, papered: true,
                            ink: cardInk.text(0.95), inkSoft: cardInk.text(0.55),
                            bezel: cardInk.isLight ? Color(white: 0.10) : Color(white: 0.16),
                            rim: cardInk.line(0.22))
        }
        guard surface == .clear else {
            // แผ่นกับครีมมาจากสูตรกลางของตู้ — เฉดคือสีที่เจ้าของการ์ดเลือกไว้
            let cream = PosterPlate.cream(theme)
            return ReelSkin(sheet: PosterPlate.plate(theme), papered: true,
                            ink: cream, inkSoft: cream.opacity(0.62),
                            bezel: Color(white: 0.07), rim: cream.opacity(0.16))
        }
        // ถอดแผ่นแล้ว — ทุกอย่างพลิกไปใช้หมึกของการ์ด
        return ReelSkin(sheet: .clear, papered: false,
                        ink: cardInk.text(0.95), inkSoft: cardInk.text(0.55),
                        bezel: cardInk.isLight ? Color(white: 0.10) : Color(white: 0.16),
                        rim: cardInk.line(0.22))
    }

    var body: some View {
        // # แผ่นต้องเต็มกรอบเสมอ — **ทั้งกว้างและสูง ทุกเคส** (ดู `PosterSheet`)
        //
        // `Reel.w × Reel.h` เป็นแค่ *ขนาดต่ำสุด* ของผัง · กรอบที่กว้างกว่านั้นยกที่ว่างให้
        // **ขอบสองข้าง** (หัวเรื่องกับเครื่องสี่เครื่องยังเป็นก้อนเดียวกลางแผ่น ไม่ถูกดีดออกไปหาขอบ)
        // กรอบที่สูงกว่านั้นยกให้พื้นของแผ่น — ไม่มีการ์ดโผล่ข้างแผ่นอีกไม่ว่าลากไปทางไหน
        PosterSheet(design: CGSize(width: Reel.w, height: Reel.h), frame: size) { box in
            sheet(box)
        }
    }

    /// - Parameter box: ผังในหน่วยออกแบบที่ยืดเต็มกรอบแล้ว (≥ `Reel.w × Reel.h`)
    ///   — แผ่นยืดตามกรอบทั้งสองแกน ของข้างในไม่ถูกบีบ มีแต่ร่องที่กว้างขึ้น
    private func sheet(_ box: CGSize) -> some View {
        let s = skin
        let radius = min(theme.radius, 22)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return ZStack {
            if s.papered {
                shape.fill(s.sheet)
                PlatePatternLayer(sheet: s.sheet)
                    .clipShape(shape)
                // เส้นขอบในตามต้นฉบับ — บอกว่านี่คือ *แผ่นที่จัดหน้าแล้ว* ไม่ใช่กล่องพื้นหลัง
                RoundedRectangle(cornerRadius: radius - 5, style: .continuous)
                    .strokeBorder(s.rim, lineWidth: 0.8)
                    .padding(5)
            }
            VStack(spacing: 0) {
                header(s)
                Spacer().frame(height: 9)
                columns(s)
                Spacer(minLength: 0)
            }
            .padding(.top, Reel.padTop)
            .padding(.bottom, Reel.padBottom)
            .padding(.horizontal, Reel.pad)
            // ก้อนเนื้อหากว้างเท่าผังเสมอ แล้วจัดกลางบนแผ่น — แผ่นยืดได้ ของบนแผ่นไม่แยกจากกัน
            .frame(width: Reel.w)
        }
        .frame(width: box.width, height: box.height)
        .clipShape(shape)
    }

    // MARK: หัวเรื่อง

    private func header(_ s: ReelSkin) -> some View {
        // คำยักษ์ถูกวัดจาก **ข้อความที่พิมพ์อยู่จริง** ไม่ใช่ขนาดตายตัว —
        // พิมพ์ "PHOTOGRAPHY" แทน "VIDEOGRAPHY" แล้วแถบต้องยังกว้างเท่าเดิม (ดู `Ed.fitted`)
        let title = Profile.me.note(wid, 1, preset: "VIDEOGRAPHY").uppercased()
        let titleSize = Ed.fitted(title, weight: .black, width: Reel.titleWidth,
                                  cap: Reel.titleCap, floor: 11)
        return VStack(spacing: 0) {
            EdText(slot: 0, preset: "Recent", hint: "คำนำหัว",
                   style: .init(size: Reel.recentSize, weight: .regular, face: .serif,
                                color: s.ink, align: .center, italic: true))
                .frame(height: Reel.recentBox)
            EdText(slot: 1, preset: "VIDEOGRAPHY", hint: "หัวเรื่อง",
                   style: .init(size: titleSize, weight: .black, color: s.ink,
                                align: .center, tracking: 0.4, uppercase: true))
                .frame(height: Reel.titleBox)
                .padding(.top, -Reel.titleOverlap)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: เครื่องสี่เครื่อง

    private func columns(_ s: ReelSkin) -> some View {
        HStack(alignment: .top, spacing: Reel.gutter) {
            ForEach(0..<Reel.slots, id: \.self) { i in
                column(s, i: i)
            }
        }
    }

    private func column(_ s: ReelSkin, i: Int) -> some View {
        // เครื่องซ้ายสุดออกเดินทางก่อนเสมอ ปัดกลับก็คลี่กลับตามลำดับตรงข้าม (ดู `Scrub.lead`)
        let lead = Scrub.lead(i, of: Reel.slots, d: scrub.d, step: 0.08)
        // ใต้เครื่องเหลือ **ชื่อลูกค้าอย่างเดียว**
        //
        // คำบรรยายสามบรรทัด 6.4pt ที่เคยอยู่ตรงนี้ (ช่อง `6 + i`) เล็กเกินกว่าจะอ่านบนการ์ดจริง
        // — มันเลยทำหน้าที่ได้แค่ *เนื้อเทา* ที่ดันเครื่องให้เล็กลง · ข้อความเก่ายังอยู่ในโปรไฟล์
        // (ไม่ได้ลบทิ้ง) ถ้าวันหนึ่งกลับมาใส่อีกก็ยังอยู่ครบ
        return VStack(spacing: 0) {
            phone(s, i: i)
            Spacer().frame(height: 6)
            EdText(slot: 2 + i, preset: "ชื่อลูกค้า", hint: "ชื่อลูกค้าใบที่ \(i + 1)",
                   style: .init(size: 9.5, weight: .bold, color: s.ink, align: .center))
                .frame(width: Reel.capW)
        }
        .frame(width: Reel.phoneW)
        .scrubLouver(scrub.d, lead: lead, angle: 38, shrink: 0.08)
    }

    /// ตัวเครื่อง — ขอบหนา 2.5 · จอมุมมนตามตัวเครื่อง · เกาะไดนามิกไอส์แลนด์ที่หัวจอ
    private func phone(_ s: ReelSkin, i: Int) -> some View {
        let shell = RoundedRectangle(cornerRadius: 12, style: .continuous)
        let screen = RoundedRectangle(cornerRadius: 9.5, style: .continuous)
        return ZStack(alignment: .top) {
            shell.fill(s.bezel)
            EdPhoto(slot: 4 + i, depth: 8)
                .clipShape(screen)
                .padding(2.5)
            // เกาะดำที่หัวจอ — ชิ้นเดียวที่ทำให้กรอบสี่เหลี่ยมอ่านออกว่าเป็น *เครื่อง*
            Capsule().fill(Color.black.opacity(0.92))
                .frame(width: 20, height: 5.5)
                .padding(.top, 6)
        }
        .frame(width: Reel.phoneW, height: Reel.phoneH)
        .overlay(shell.strokeBorder(s.rim, lineWidth: 0.8))
        .shadow(color: .black.opacity(s.papered ? 0.45 : 0.3), radius: 6, y: 3)
    }
}
