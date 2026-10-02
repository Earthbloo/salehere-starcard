import SwiftUI

// widget ชุดนี้วาดพื้นหลังเอง ไม่ใช้กรอบกระจกกลาง (`WidgetKind.drawsOwnSurface`)
// เพื่อให้การ์ดไม่กลายเป็นตารางสี่เหลี่ยมมนเรียงกันทั้งหน้า

// MARK: - เซลล์รูปมาตรฐานของกลุ่มผลงาน

/// กระเบื้องรูปหนึ่งใบในผัง bento — มุมมน ขอบเส้นผม ไม่มีเงา ไม่เอียง
///
/// ภาษาเดียวกันทั้งกลุ่ม "รูปผลงาน" · ความลึกของแต่ละช่องคุมด้วย `depth`
/// (สัดส่วนของความกว้างช่องที่ภาพข้างในถ่วงตัวสวนทางหน้า)
private struct BentoCell: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(\.cardInk) private var ink
    let index: Int
    var radius: CGFloat = 16
    var d: CGFloat = 0
    var width: CGFloat = 100
    var depth: CGFloat = 0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Color.clear
            .overlay {
                WidgetPhoto(index: index)
                    .aspectRatio(contentMode: .fill)
                    // zoom ต้องคุ้ม shift (≥ 2 × depth) ไม่งั้นเห็นขอบว่างที่ริมภาพ
                    .scrubDolly(d, shift: width * depth, zoom: max(0.12, depth * 2.4))
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(ink.line(0.12), lineWidth: 0.6))
            .photoSlot(index)
    }
}

// MARK: - แถบภาพ

/// คอนแทกต์ชีตแนวนอน — สี่ช่องสัดส่วนพอร์เทรตเท่ากัน
///
/// # ท่าเปลี่ยนหน้า — "ฟิล์มเดินผ่านช่องกล้อง"
///
/// แถบทั้งแถบเลื่อนไปหนึ่งเฟรมพอดีตามทิศนิ้ว ขณะที่หน้าต่างของแต่ละเฟรมหุบไล่กัน
/// สายตาจึงอ่านว่าฟิล์มถูกดึงผ่านช่อง ไม่ใช่ภาพสี่ใบที่ถูกเลื่อนออกไปพร้อมกัน
struct ArtFilmstrip: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    var body: some View {
        GeometryReader { geo in
            let n = 4
            let gap: CGFloat = 7
            let w = (geo.size.width - gap * CGFloat(n - 1)) / CGFloat(n)
            HStack(spacing: gap) {
                ForEach(0..<n, id: \.self) { i in
                    BentoCell(index: i + 6, radius: 13, d: scrub.d, width: w, depth: 0.085)
                        .frame(width: w, height: geo.size.height)
                        .scrubAperture(scrub.d,
                                       lead: Scrub.lead(i, of: n, d: scrub.d, step: 0.1),
                                       feather: 0.22, dim: 0.5)
                }
            }
            // เดินหนึ่งเฟรมพอดี — ระยะต้องเท่าช่อง+ร่อง ไม่งั้นอ่านเป็น "ไถล" ไม่ใช่ "เดินเฟรม"
            .scrubSlide(scrub.d, travel: w + gap, fade: 0.85)
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }
}

// MARK: - คู่แนวตั้ง

/// สองรูปแนวตั้งเคียงกัน — ช่องเท่ากันเป๊ะ ไม่มีช่องไหนเด่นกว่าช่องไหน
///
/// ทำไมต้องมีทั้งที่ตระกูลนี้มีเบนโตะกับแถบภาพอยู่แล้ว: เบนโตะบอกว่า "ชิ้นนี้สำคัญกว่าชิ้นอื่น"
/// (ช่องใหญ่กินสายตาก่อนเสมอ) ส่วนแถบภาพสี่ช่องบอกว่า "นี่คือคลังงาน ดูรวม ๆ"
/// แต่งานส่วนใหญ่ที่ครีเอเตอร์อยากโชว์คือ **สองชิ้นที่ดีที่สุด** ซึ่งไม่มีอันไหนเป็นรอง
/// และคลิปแนวตั้ง (Reel/TikTok) คือสัดส่วนจริงของงานที่ถ่ายมา ไม่ใช่กรอบสี่เหลี่ยมจัตุรัสที่ครอปทิ้ง
///
/// ช่องสูงเต็มกรอบที่ผู้ใช้ลากไว้ — ขนาดตั้งต้น (6×11) ให้สัดส่วนพอร์เทรตราว 3:4 ต่อช่อง
/// อยากได้สูงกว่านั้นก็ยืดกรอบเอง กติกาเดียวกับทุกตัวในตู้
///
/// # ท่าเปลี่ยนหน้า — "สองบานหุบสวนกัน"
///
/// หน้าต่างสองบานหุบไล่กันตามทิศนิ้ว และภาพข้างในถ่วงตัว **คนละทาง** —
/// ความลึกจึงมาจากทิศที่ต่างกันของสองชั้น ไม่ใช่จากเงาหรือความจาง (กฎเดียวกับใบออร่าที่ถอดออกไปแล้ว)
struct ArtPair: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    // [4, 6] ไม่ใช่ [4, 5] — คลังรูปผลงาน mock มี 3 ใบวนตาม i % 3
    // slot 5 ตกรูปใบเดียวกับ workReel (index 8) พอวางคู่กันบนหน้าเดียวรูปจะซ้ำติดกัน
    // slot 4/6 → works[1]/works[0] จึงได้คนละใบทั้งภายในคู่และกับคลิปข้างเคียง
    private let slots = [4, 6]

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 8
            let w = (geo.size.width - gap) / 2
            HStack(spacing: gap) {
                ForEach(Array(slots.enumerated()), id: \.element) { i, slot in
                    cell(slot, i: i, w: w, h: geo.size.height)
                }
            }
        }
    }

    private func cell(_ slot: Int, i: Int, w: CGFloat, h: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        // ใบซ้ายถ่วงไปทางหนึ่ง ใบขวาถ่วงกลับ — เท่ากันทั้งคู่จะอ่านเป็นภาพเดียวที่ถูกเลื่อน
        let drift: CGFloat = i == 0 ? 0.09 : -0.09
        return Color.clear
            .frame(width: w, height: h)
            .overlay {
                WidgetPhoto(index: slot)
                    .aspectRatio(contentMode: .fill)
                    .scrubDolly(scrub.d, shift: w * drift, zoom: 0.24)
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(.white.opacity(0.14), lineWidth: 0.7))
            .photoSlot(slot)
            .scrubAperture(scrub.d,
                           lead: Scrub.lead(i, of: slots.count, d: scrub.d, step: 0.12),
                           feather: 0.22, dim: 0.5)
    }
}

// MARK: - เบนโตะ

/// ผังเบนโตะ — ช่องสูงหนึ่งช่อง + ช่องกว้างหนึ่งช่อง + ช่องเล็กสองช่อง
///
/// # ท่าเปลี่ยนหน้า — "ความลึกผูกกับขนาดช่อง"
///
/// ช่องใหญ่ถ่วงตัวน้อยและหุบทีหลัง (ของไกล ใหญ่ หนัก) · ช่องเล็กถ่วงมากและหุบก่อน
/// (ของใกล้ เบา) — เป็นกฎเดียวกับที่ตาใช้อ่านระยะในโลกจริง ไม่ต้องอธิบายก็รู้สึกได้
struct ArtDuo: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 8
            let w = geo.size.width, h = geo.size.height
            let leftW = (w - gap) * 0.56
            let rightW = w - gap - leftW
            let topH = (h - gap) * 0.58
            let botH = h - gap - topH
            let smallW = (rightW - gap) / 2

            HStack(spacing: gap) {
                BentoCell(index: 7, radius: 20, d: scrub.d, width: leftW, depth: 0.05)
                    .frame(width: leftW, height: h)
                    .scrubAperture(scrub.d, lead: Scrub.lead(0, of: 4, d: scrub.d, step: 0.11),
                                   feather: 0.2, dim: 0.55)
                VStack(spacing: gap) {
                    BentoCell(index: 8, radius: 18, d: scrub.d, width: rightW, depth: 0.09)
                        .frame(width: rightW, height: topH)
                        .scrubAperture(scrub.d, lead: Scrub.lead(1, of: 4, d: scrub.d, step: 0.11),
                                       feather: 0.2, dim: 0.55)
                    HStack(spacing: gap) {
                        BentoCell(index: 9, radius: 14, d: scrub.d, width: smallW, depth: 0.14)
                            .frame(width: smallW, height: botH)
                            .scrubAperture(scrub.d, lead: Scrub.lead(2, of: 4, d: scrub.d, step: 0.11),
                                           feather: 0.24, dim: 0.55)
                        BentoCell(index: 10, radius: 14, d: scrub.d, width: smallW, depth: 0.14)
                            .frame(width: smallW, height: botH)
                            .scrubAperture(scrub.d, lead: Scrub.lead(3, of: 4, d: scrub.d, step: 0.11),
                                           feather: 0.24, dim: 0.55)
                    }
                }
            }
        }
    }
}

// MARK: - แถบวิ่ง

/// # ท่าเปลี่ยนหน้า — "กรอตามนิ้ว"
///
/// ตัวนี้คือหัวใจของอุปมา seek ทั้งการ์ด: ของที่วิ่งอยู่แล้วตามเวลา พอโดนนิ้วลาก
/// จะ **เร่งไปข้างหน้า** ลากกลับก็ **กรอถอย** ปล่อยแล้วสปริงพากลับเข้าจังหวะเดิม
/// ผู้ใช้ได้ความรู้สึก "จับหัวอ่านอยู่" โดยที่เราไม่ได้วาดหัวอ่านเลยสักเส้น
struct TypeMarquee: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    /// ความกว้างของเนื้อหาหนึ่งชุด — วัดจากของจริง ไม่เดาเป็นค่าคงที่
    @State private var runW: CGFloat = 1

    /// เฉพาะชื่อแบรนด์ — เดิมต่อท้ายด้วยสายงานที่พิมพ์เอง ซึ่งเป็นข้อมูลของตระกูล `tags`
    /// แถบนี้อยู่ตระกูล `brand` จึงต้องอ่านเฉพาะสัญญาของตระกูลตัวเอง
    /// (ไม่งั้นสลับจากแถบวิ่งไปเป็นกำแพงโลโก้แล้วสายงานหายไปเฉย ๆ)
    private var words: [String] { Profile.me.shownTrack(.brand).brands.map(\.name) }

    private var row: some View {
        HStack(spacing: 22) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, w in
                HStack(spacing: 22) {
                    Text(w.uppercased())
                        .font(.sh(15, .bold))
                        .foregroundStyle(ink.text(0.9))
                    Image(systemName: "asterisk")
                        .font(.sh(9, .black))
                        .foregroundStyle(theme.accent)
                }
            }
        }
        // ระยะคั่นท้ายชุด — ไม่มีตัวนี้แล้วชุดถัดไปจะติดกันจนอ่านเป็นคำเดียว
        .padding(.trailing, 22)
        .fixedSize()
    }

    var body: some View {
        // ต้องใช้ .overlay ไม่ใช่ ZStack — overlay ไม่นับขนาดของลูกเข้ามาคิดขนาดพ่อ
        // ถ้าใช้ ZStack ตัวกล่องจะกว้างเท่าแถบข้อความ (~1400pt) แล้ว .clipped() จะไร้ผล
        Rectangle()
            .fill(theme.accent.opacity(0.1))
            .overlay(alignment: .leading) {
                ScrubRunner(d: scrub.d, runWidth: runW, period: 16, pull: 0.42,
                            active: abs(scrub.d) < 1.05, copies: 3) { row }
            }
            .clipped()
            // ชุดวัดขนาด — ซ่อนไว้แต่ยังถูกจัดวางจริง จึงได้ความกว้างที่ตรงกับของที่วาด
            .background(alignment: .leading) {
                row.hidden()
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { w in
                        if w > 1 { runW = w }
                    }
            }
            .overlay(alignment: .top) { Rectangle().fill(ink.line(0.12)).frame(height: 0.5) }
            .overlay(alignment: .bottom) { Rectangle().fill(ink.line(0.12)).frame(height: 0.5) }
            .rotationEffect(.degrees(-0.8))
            .padding(.vertical, 3)
    }
}

// MARK: - ตัวเลขยักษ์ ไม่มีกรอบ

/// # ท่าเปลี่ยนหน้า — "มิเตอร์"
///
/// ตัวเลขคือหลักฐาน มันไม่ควรจางหายแบบข้อความ — มันถูก **ถอดออกทีละหลัก**
/// จากฝั่งที่หน้ากำลังไป แล้วประกอบกลับตามลำดับตรงข้ามตอนปัดกลับ
/// เป็นท่าที่บอกว่า "นี่คือค่าที่นับได้" ไม่ใช่ "นี่คือคำโปรย"
struct StatGiant: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme
    let size: CGSize

    private var total: Int { Profile.me.shownSocials.reduce(0) { $0 + $1.followerCount } }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        let fs = min(58, size.width * 0.235)
        return ZStack(alignment: .bottomLeading) {
            // ตัวเลขวางบนภาพผลงานจริง น่าเชื่อกว่าลอยอยู่บนพื้นเปล่า
            Color.clear
                .overlay {
                    WidgetPhoto(index: 3)
                        .aspectRatio(contentMode: .fill)
                        .scrubDolly(scrub.d, shift: size.width * 0.055, zoom: 0.15)
                }
                .clipShape(shape)
                .overlay {
                    ScrubReader(d: scrub.d) { d in
                        let t = Scrub.ease(Scrub.t(d))
                        LinearGradient(colors: [.black.opacity(0.2),
                                                .black.opacity(0.8 + 0.2 * Double(t))],
                                       startPoint: .top, endPoint: .bottom)
                    }
                    .clipShape(shape)
                }
                .photoSlot(3)

            VStack(alignment: .leading, spacing: 0) {
                // หัวเรื่องอยู่ **เหนือ** ตัวเลข ไม่ใช่ใต้
                //
                // ตัวเลขยักษ์ที่ยังไม่มีคำกำกับ อ่านออกมาเป็นตัวเลขลอย ๆ อยู่หนึ่งจังหวะ
                // ตาต้องกวาดลงไปอ่านคำข้างล่างแล้วย้อนขึ้นมาอ่านเลขใหม่ — สองรอบเพื่อค่าเดียว
                // เอาคำขึ้นก่อนแล้วตาอ่านรอบเดียวจบ
                HStack(spacing: 8) {
                    Text("ผู้ติดตามรวมทุกช่องทาง")
                        .font(.sh(11, .bold)).tracking(0.6)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Spacer(minLength: 0)
                    // ใบนี้เคยเป็นตัวเลขลอย ๆ บนรูป ไม่มีอะไรบอกที่มา — ป้ายเดียวกับ `ผู้ติดตามแบบแถว` ฉบับบนรูปถ่าย
                    ProvenanceTag(kind: Profile.me.shownSocials.provenance, onPhoto: true)
                }
                .scrubVeil(scrub.d, lead: 0.34, drop: 20, pull: 8)

                ScrubDigits(text: Fmt.compact(total), d: scrub.d,
                            lead: 0.24, step: 0.06, drop: fs * 1.15)
                    .font(.sh(fs, .black))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, theme.rawAccentSoft],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .padding(.top, 2)

                Spacer(minLength: 8)

                // แต่ละช่องเป็นชิปของตัวเอง ไม่ใช่ไอคอนกับเลขลอย ๆ ต่อกัน
                // ที่ขนาดเดิม (ไอคอน 13 · เลข 11) สามช่องอ่านออกมาเป็นแถบเดียว แยกกันไม่ออก
                HStack(spacing: 8) {
                    ForEach(Array(Profile.me.shownSocials.enumerated()), id: \.element.id) { i, s in
                        HStack(spacing: 6) {
                            BrandIcon(name: s.type.icon, size: 17)
                            Text(Fmt.compact(s.followerCount)).dataValue()
                                .font(.sh(14, .heavy))
                                .foregroundStyle(.white)
                        }
                        .lineLimit(1).fixedSize()
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        // ชิปเป็น **กระจก** ไม่ใช่แผ่นดำจาง — ของเดิมคือ fill ดำ + เส้นขอบขาว
                        // ซึ่งอ่านออกมาเป็นสติกเกอร์แปะทับรูป ไม่ได้อยู่ในชั้นเดียวกับการ์ด
                        // สูตรเดียวกับ GlassPanel: ม่านมืดบาง ๆ ใต้เนื้อหาให้ตัวเลขติดตา
                        // แล้วปล่อยให้ระบบวาด rim light เอง (เส้นขอบที่เขียนเองจะไปกลบของจริง)
                        .background(Capsule().fill(.black.opacity(0.2)))
                        .glassEffect(.clear, in: Capsule())
                        .scrubVeil(scrub.d,
                                   lead: Scrub.lead(i, of: Profile.me.shownSocials.count,
                                                    d: scrub.d, step: 0.06),
                                   drop: 26, pull: 10)
                        .linkSlot(s.profileURL)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(18)
        }
    }

}

// MARK: - ตัวอักษรใหญ่คร่อมขอบภาพ

/// ชื่อตัวใหญ่วางคร่อมขอบล่างของภาพ — ครึ่งบนอยู่บนภาพเป็นสีขาว ครึ่งล่างพ้นภาพเป็นสีธีม
///
/// # ท่าเปลี่ยนหน้า — "ตัวอักษรจมผ่านขอบภาพ"
///
/// เส้นแบ่งสองสีของตัวยักษ์คือขอบล่างของภาพ ตอนปัดเราให้ **เส้นแบ่งนั้นไหลขึ้น**
/// พร้อมกับตัวอักษรไถลสวนทางรูป ผลคือตัวอักษรค่อย ๆ เปลี่ยนเป็นสีธีมทั้งตัว
/// เหมือนมันจมลงผ่านผิวของภาพ — ท่านี้ทำได้เพราะเส้นแบ่งเป็นมาสก์ ไม่ใช่สองชั้นที่วางทับกันเฉย ๆ
struct ArtTypeOver: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    /// ชื่อยักษ์ถูกวาดสองชั้น (ตัวขาวทับภาพ + เงาสีธีมที่พ้นภาพ) จึงต้องตั้งฟอนต์/สีเอง
    /// ไม่ใช่รอให้ตัวประกาศช่องใส่ให้ — ดู `EditableTextModifier`
    @Environment(\.widgetTextStyle) private var tune
    @Environment(\.cardAccent) private var accent
    let theme: CardTheme
    let size: CGSize

    /// ตัวยักษ์ = **ชื่อเล่น** (ช่องของตัวเอง ค่าตั้งต้นคือคำแรกของชื่อ) ไม่ใช่ handle โรมัน
    ///
    /// เดิมใช้ `nira.beauty` → `NIRA` เพราะสระบน-ล่างของไทยชนกันที่น้ำหนัก black
    /// แต่ผลคือแบบนี้เป็นแบบเดียวในตระกูลโปรไฟล์ที่ขึ้นภาษาอังกฤษ ส่วนอีกสี่แบบเป็นไทยหมด —
    /// สลับแบบทีเดียวภาษาเปลี่ยน ซึ่งผิดกติกาที่ว่าการกด "แบบอื่น" ต้องเปลี่ยนแค่หน้าตา
    ///
    /// ทางแก้ที่ไม่ต้องทิ้งตัวยักษ์: ลดน้ำหนักจาก black เป็น bold และย่อขนาดลง 12%
    /// ที่น้ำหนักนี้ NotoSansThai วางสระกับวรรณยุกต์ได้โดยไม่ชนตัวอักษรข้างเคียง
    private var mark: String { Profile.me.nickname }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // คำนวณย้อนจากขอบล่างขึ้นมา ไม่ใช่แบ่งเป็นเปอร์เซ็นต์จากบน
            // ย่อกว่าตอนใช้โรมัน 12% — ไทยกินความสูงมากกว่าเพราะมีชั้นสระบนกับวรรณยุกต์
            let fs = min(w * 0.235, h * 0.235) * 0.88
            let footer: CGFloat = 46            // ชื่อไทย + บรรทัดสายงาน
            let photoH = h - footer - fs * 0.10
            // NotoSansThai เผื่อที่ให้สระบน-ล่าง ต้องหักด้วย ascent จริง
            // ไทยต้องมากกว่าโรมัน เพราะตัวอักษรจริงนั่งต่ำลงมาในกล่อง em (ที่ว่างข้างบนเป็นของสระ)
            let baseline = photoH - fs * 1.16

            // ชื่อเล่นยาวไม่ตัดด้วย … แต่ **ย่อขนาดลงจนพอดีความกว้าง** —
            // ตัวยักษ์ที่ถูกตัดกลางคำอ่านไม่ออกว่าเป็นชื่ออะไร ซึ่งทำให้ทั้งแบบนี้ไร้ความหมาย
            // จึงจับใส่กรอบกว้างเท่าที่มีจริง แล้วปล่อยให้ฟอนต์หดเอง
            let markW = w * 0.94
            let giant = Text(mark)
                .font(tune.font(fs, .bold, for: .nickname))
                .kerning(-tune.scaled(fs, for: .nickname) * 0.02)
                .lineLimit(1)
                .minimumScaleFactor(0.28)
                .frame(width: markW, alignment: .leading)

            ZStack(alignment: .topLeading) {
                Color.clear
                    .frame(width: w, height: photoH)
                    .overlay {
                        WidgetPhoto(index: 1)
                            .aspectRatio(contentMode: .fill)
                            .scrubDolly(scrub.d, shift: w * 0.05, zoom: 0.14)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        LinearGradient(colors: [.clear, .black.opacity(0.45)],
                                       startPoint: .center, endPoint: .bottom)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .photoSlot(1)

                ScrubReader(d: scrub.d) { d in
                    let t = Scrub.ease(Scrub.t(d))
                    let s = CGFloat(Scrub.dir(d))
                    // เส้นแบ่งไหลขึ้น — ตัวอักษรจึงเปลี่ยนเป็นสีธีมจากล่างขึ้นบน
                    let cut = max(0, photoH - fs * 0.75 * t)
                    let slide = -s * w * 0.12 * t
                    ZStack(alignment: .topLeading) {
                        // ชั้นล่าง: ส่วนที่พ้นภาพลงมา
                        giant
                            .foregroundStyle(theme.accent)
                            .offset(x: w * 0.03 + slide, y: baseline)
                        // ชั้นบน: ส่วนที่ทับอยู่บนภาพ — ตัดด้วยเส้นแบ่งที่เคลื่อนได้
                        // ช่องพิมพ์ประกาศที่ชั้นนี้ชั้นเดียว (อีกชั้นเป็นเงาสีธีมของตัวเดียวกัน)
                        giant
                            .foregroundStyle(tune.color(.white, for: .nickname,
                                                        ink: ink, accent: accent) ?? .white)
                            .editableText(.nickname, .init(size: fs, weight: .bold,
                                                           color: .white, tracking: -fs * 0.02,
                                                           corner: 6))
                            .offset(x: w * 0.03 + slide, y: baseline)
                            .mask(alignment: .top) { Rectangle().frame(height: cut) }
                    }
                    .opacity(Scrub.fade(t, after: 0.82))
                }

                VStack(alignment: .leading, spacing: 2) {
                    // บล็อกนี้อยู่ "ใต้" รูป จึงนั่งบนพื้นการ์ด ไม่ใช่บน scrim — ต้องพลิกตามหมึก
                    HStack(spacing: 5) {
                        Text(Profile.me.name)
                            .lineLimit(1).truncationMode(.tail)
                            .editableText(.name, .init(size: 14, weight: .semibold,
                                                       color: ink.text(0.9)))
                        // ตรายืนยันเกาะชื่อ ไม่ใช่ widget แยก — ตราที่วางเองได้คือตราที่จัดฉากได้
                        if Profile.me.creator.verified {
                            StarSeal(size: 10, tint: ink.text(0.9), punch: ink.isLight ? Color(white: 0.97) : Color(white: 0.10))
                        }
                        Spacer(minLength: 0)
                    }
                    .scrubVeil(scrub.d, lead: 0.24, drop: 24, pull: 8)

                    // hero บอกแค่ "นี่คือใคร" — ยอดผู้ติดตามกับพื้นที่รับงานเป็นคนละคำถาม
                    // และมี widget ของตัวเองอยู่แล้ว เอามาใส่ที่นี่คือการตอบคำถามที่ยังไม่มีใครถาม
                    Text(Profile.me.tagline.uppercased())
                        .tracking(2)
                        .lineLimit(1).truncationMode(.tail)
                        .editableText(.tagline, .init(size: 8.5, weight: .semibold,
                                                      color: ink.text(0.45), tracking: 2,
                                                      uppercase: true))
                        .scrubVeil(scrub.d, lead: 0.08, drop: 20, pull: 18)
                }
                // ยึดกับแถบล่างที่กันไว้ ไม่ผูกกับ baseline ของตัวยักษ์
                .offset(x: w * 0.035, y: h - footer + 2)
            }
            .frame(width: w, height: h, alignment: .topLeading)
        }
    }
}
