import SwiftUI

// widget กลุ่มนี้เป็น full-bleed — รูปต้องชนขอบกระจก ไม่มี padding รอบนอก
//
// ทั้งสองตัวเป็น `EntranceStyle.anchored` ที่ระดับกรอบ — ท่าทั้งหมดอยู่ข้างใน
// เพราะของพวกนี้คือ "ผลงาน" ซึ่งเป็นพระเอกของการ์ด มันสมควรมีท่าเป็นของตัวเอง
// ไม่ใช่ถูกกรอบยกไปทั้งแผ่นเหมือนภาพประกอบ

// MARK: - ผลงานชิ้นเด่น

/// ผังเบนโตะแบบมีพระเอก — ช่องใหญ่กินสองในสาม อีกสองช่องเล็กเรียงข้าง
///
/// # ทำไมไม่มีป้ายตัวเลขแล้ว
///
/// เคยมีป้ายยอดวิว + ชื่อแบรนด์ซ้อนอยู่บนช่องพระเอก · ถอดออกตามกติกาของตระกูล `รูปผลงาน`
/// ที่ว่าทั้งตระกูลไม่มีตัวอักษร (ดูหัวไฟล์ `GalleryWidgets.swift`)
/// คำถาม "กี่วิว ของแบรนด์ไหน" เป็นของตระกูล `ผลงานยืนยัน` ซึ่งตอบไว้ครบแล้วห้าแบบ
/// เหลือโลโก้แพลตฟอร์มมุมล่างไว้ดวงเดียว — มันเป็นสัญลักษณ์ ไม่ใช่ข้อความ
/// และเป็นสิ่งเดียวที่ทำให้รูปนี้ยังอ่านออกว่า "งานที่ลงไปแล้ว" ไม่ใช่ "รูปที่ถ่ายเก็บไว้"
///
/// # ท่าเปลี่ยนหน้า — "บานเกล็ดสามบานคนละความลึก"
///
/// สามช่องหุบไล่กันตามทิศนิ้ว ช่องที่อยู่ต้นทางของการเดินทางหุบก่อนเสมอ
/// ความลึกไม่ได้มาจากขนาด แต่มาจาก **อัตราที่ภาพในช่องถ่วงตัว**: ช่องใหญ่ถ่วงน้อย
/// อ่านเป็นของไกล ช่องเล็กถ่วงมาก อ่านเป็นของใกล้ — ตาจึงแยกระนาบออกจากกันได้
struct WorkFeatured: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    /// ชิ้นที่ทำยอดสูงสุด — เหลือไว้เพื่อรู้ว่าโลโก้มุมล่างควรเป็นแพลตฟอร์มไหนเท่านั้น
    private var hero: VerifiedWork? {
        Profile.me.creator.track.works.max { $0.views < $1.views }
    }

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 8
            let bigW = (geo.size.width - gap) * 0.64
            let smallW = geo.size.width - bigW - gap
            let smallH = (geo.size.height - gap) / 2

            HStack(spacing: gap) {
                ZStack(alignment: .bottomLeading) {
                    frame(4, w: bigW, h: geo.size.height, radius: 20, scrim: true,
                          depth: 0.05, i: 0)
                    platformMark.padding(10)
                }
                .frame(width: bigW, height: geo.size.height)
                // ช่องพระเอก = ผลงานชิ้นที่ทำยอดสูงสุด · กดแล้วไปดูโพสต์จริงชิ้นนั้น
                .linkSlot(hero.flatMap(\.postURL))

                VStack(spacing: gap) {
                    frame(5, w: smallW, h: smallH, radius: 15, scrim: false, depth: 0.11, i: 1)
                    frame(6, w: smallW, h: smallH, radius: 15, scrim: false, depth: 0.11, i: 2)
                }
            }
        }
    }

    /// หนึ่งช่อง = บานเกล็ดหนึ่งบาน · `depth` คือระยะที่ภาพข้างในถ่วงสวนทางหน้า
    private func frame(_ index: Int, w: CGFloat, h: CGFloat, radius: CGFloat,
                       scrim: Bool, depth: CGFloat, i: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return Color.clear
            .frame(width: w, height: h)
            .overlay {
                WidgetPhoto(index: index)
                    .aspectRatio(contentMode: .fill)
                    // zoom ต้องคุ้ม shift ไม่งั้นเห็นขอบว่างที่ริมภาพตอนสครับสุดทาง
                    .scrubDolly(scrub.d, shift: w * depth, zoom: depth * 2.4)
            }
            .overlay {
                if scrim {
                    LinearGradient(colors: [.clear, .black.opacity(0.55)],
                                   startPoint: .center, endPoint: .bottom)
                }
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(ink.line(0.13), lineWidth: 0.5))
            .photoSlot(index)
            .scrubAperture(scrub.d,
                           lead: Scrub.lead(i, of: 3, d: scrub.d, step: 0.12),
                           feather: 0.2, dim: 0.55)
    }

    /// โลโก้แพลตฟอร์มบนช่องพระเอก — ชิ้นเดียวที่เหลือจากป้ายหลักฐานเดิม
    ///
    /// อยู่ **นอกม่าน** ของท่าเปลี่ยนหน้าจงใจ (หายช้าสุด กลับมาก่อน) ด้วยเหตุผลเดิม:
    /// มันคือสิ่งที่บอกว่ารูปนี้ไม่ใช่รูปลอย ๆ แต่เป็นของที่ถูกลงไปแล้วบนช่องจริง
    @ViewBuilder
    private var platformMark: some View {
        if let w = hero {
            BrandIcon(name: w.platform.icon, size: 13)
                .padding(6)
                .background(Circle().fill(.black.opacity(0.45)))
                .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 0.5))
                .scrubVeil(scrub.d, lead: 0.4, drop: 22, pull: 8)
        }
    }
}

// MARK: - คลิปแนวตั้ง

/// คลิปหนึ่งชิ้นเต็มกรอบ พร้อมปุ่มเล่นกลางภาพ
///
/// ยอดวิวกับชื่อแบรนด์ที่เคยอยู่มุมล่างถูกถอดออกตามกติกาของตระกูล `รูปผลงาน` —
/// เหลือโลโก้แพลตฟอร์มดวงเดียว ซึ่งเป็นสัญลักษณ์ ไม่ใช่ตัวอักษร (ดู `WorkFeatured`)
///
/// # ท่าเปลี่ยนหน้า — "หัวอ่านวิดีโอ"
///
/// การ์ดใบนี้อ้างว่ามันคือคลิป งั้นตอนปัดมันก็ควรทำตัวเหมือนคลิป —
/// **ปุ่มเล่นแปลงร่างเป็นวงแหวนกรอ** ที่เติมตามระยะนิ้ว และไอคอนกลางเปลี่ยนเป็น
/// ลูกศรกรอหน้า/กรอหลังตามทิศที่ปัด ผู้ใช้จึงเห็นด้วยตาว่า "นี่คือการ seek" ไม่ใช่แค่รู้สึก
struct WorkReel: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    /// ผูกกับผลงานจริงชิ้นแรก — เหลือไว้เพื่อรู้ว่าโลโก้มุมล่างเป็นแพลตฟอร์มไหน
    private var work: VerifiedWork? { Profile.me.creator.track.works.first }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        ZStack {
            Color.clear
                .overlay {
                    WidgetPhoto(index: 8)
                        .aspectRatio(contentMode: .fill)
                        .scrubDolly(scrub.d, shift: 24, zoom: 0.2)
                }

            // เงามืดด้านล่างไหลสูงขึ้นตามนิ้ว — เวทีหรี่ลงก่อนของจะออกจากฉาก
            ScrubReader(d: scrub.d) { d in
                let t = Scrub.ease(Scrub.t(d))
                LinearGradient(colors: [.clear, .black.opacity(0.62 + 0.3 * Double(t))],
                               startPoint: UnitPoint(x: 0.5, y: 0.5 - 0.42 * Double(t)),
                               endPoint: .bottom)
            }

            if let w = work {
                VStack {
                    Spacer()
                    HStack {
                        BrandIcon(name: w.platform.icon, size: 13)
                            .padding(6)
                            .background(Circle().fill(.black.opacity(0.42)))
                            .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 0.5))
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .scrubVeil(scrub.d, lead: 0.36, drop: 26, pull: 10)
                }
            }

            // สีเน้นดิบ ไม่ใช่สีที่ปรับตามหมึก — วงแหวนนั่งอยู่บนรูป ไม่ใช่บนพื้นการ์ด
            SeekRing(d: scrub.d, tint: theme.rawAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(shape)
        .overlay(shape.strokeBorder(ink.line(0.12), lineWidth: 0.6))
        .photoSlot(8)
        // ทั้งใบคือคลิปหนึ่งคลิป — กดตรงไหนก็คือกดคลิปนั้น
        .linkSlot(work.flatMap(\.postURL))
    }
}

/// ปุ่มเล่นที่กลายเป็นหัวอ่าน — วงแหวนเติมตาม |d| · ไอคอนสลับเป็นลูกศรกรอตาม sign(d)
///
/// เป็น `Animatable` เอง ไม่ใช่คำนวณใน body ของ widget เพราะค่าจาก environment ไม่ interpolate
/// (ปล่อยนิ้วแล้ววงแหวนจะกระโดดกลับ 0 ทันทีแทนที่จะไหลกลับ)
private struct SeekRing: View, Animatable {
    var d: CGFloat
    let tint: Color

    var animatableData: CGFloat {
        get { d }
        set { d = newValue }
    }

    var body: some View {
        let t = Scrub.ease(Scrub.t(d))
        let back = d > 0
        ZStack {
            Circle().fill(.ultraThinMaterial)
            Circle().strokeBorder(.white.opacity(0.16), lineWidth: 1.4)
            Circle()
                .trim(from: 0, to: t)
                .stroke(tint, style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(1.4)

            // ปุ่มเล่นจางออกให้ลูกศรกรอเข้ามาแทน — ของสองชิ้นสลับที่กันในวงเดียว
            Image(systemName: "play.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .offset(x: 1.5)
                .opacity(Double(1 - min(1, t * 2.2)))
                .scaleEffect(1 - 0.3 * t)

            Image(systemName: back ? "backward.fill" : "forward.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .opacity(Double(max(0, t * 2.2 - 0.9)))
                .scaleEffect(0.6 + 0.4 * t)
        }
        .frame(width: 44, height: 44)
        .scaleEffect(1 - 0.12 * t)
        .opacity(Scrub.fade(t, after: 0.8))
    }
}
