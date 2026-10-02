import SwiftUI

// MARK: - โปสเตอร์สายงาน
//
// ใบที่สี่ของตระกูลคัตเอาต์ (สามใบแรกอยู่ใน `CutoutWidgets.swift` กับ `PosterWidgets.swift`)
// แปลงตรงจากแผ่น **MY Niche & SPECIALITIES** — ผัง สัดส่วน วัสดุ ตามต้นฉบับ · ฟอนต์ใช้ของแอป
//
// # สิ่งที่ใบนี้ทำแล้วไม่มีใบไหนในตู้ทำได้
//
// "สายงาน" ของเดิม (`nicheTags` · `stickerTags` · `interestTags`) คือ **ป้ายบนแผ่น** —
// ชิปเรียงกันในกล่อง อ่านเป็นรายการคำ ไม่ใช่ตัวตน · ใบนี้เอาคำชุดเดียวกันไป **ล้อมตัวคน**
// แล้วมันเปลี่ยนความหมายทั้งใบ: จาก "เขาเลือกหมวดพวกนี้" เป็น "เขาทำงานพวกนี้อยู่"
//
// # สามชั้นที่ต้องทับกันจริง
//
// 1. **คำพาดหัวสองบรรทัด** กินเต็มความกว้าง — ชั้นหลังสุด
// 2. **ป้ายสองปีก** ซ้าย/ขวา ถอยเข้าหากลางแผ่นทีละแถวตามตัวคนที่กว้างขึ้นข้างล่าง
// 3. **คน** PNG พื้นหลังใสของเจ้าของการ์ด ยืนกลางช่องว่างที่สองปีกเปิดไว้ให้ — ชั้นหน้าสุด
//
// ต่างจากอีกสามใบของตระกูลตรงที่ **ไม่มีอะไรพาดทับตัวคน** — ต้นฉบับเป็นแผ่นสไลด์ที่แบน
// ความลึกของใบนี้จึงไม่ได้มาจากของที่คร่อมตัวเขา แต่มาจาก *ช่องว่างที่ป้ายหลบให้*
// (ป้ายแถวล่างถอยเข้าใน = มีมวลบางอย่างดันมันอยู่) ซึ่งอ่านเป็นความลึกได้เหมือนกัน
// และตอนเลื่อนหน้า สองปีกวิ่งออกคนละทางในขณะที่คนแทบไม่ขยับ — ความต่างของอัตราอยู่ตรงนั้น
//
// # ทั้งใบมีพื้นและไม่มีพื้น
//
// ต้นฉบับคือแผ่นสีเลือดหมูทึบ ซึ่งเป็น *ดีไซน์* ไม่ใช่กรอบที่ chrome ครอบให้ —
// คำถามเดียวที่เหลือจึงเป็น "เอาแผ่นไหม" เหมือน `artPortfolio` กับสำรับบรรณาธิการ
// (ดู `WidgetKind.surfaceOptions`) · มีแผ่น = สไลด์ที่พิมพ์เสร็จแล้ว ·
// ไม่มีแผ่น = คำ ป้าย และคน นั่งบนการ์ดตรง ๆ หมึกพลิกตามธีมให้เอง

/// ค่าคงที่ของผัง — **หน่วยเดียวกับ `WidgetKind.defaultSize`** (366 × 221)
///
/// ทุกค่าที่นี่คือระยะของต้นฉบับ (472 × 285) คูณ 0.775 ตรง ๆ ไม่มีค่าไหนถูกเดาขึ้นมาใหม่
/// เขียนเป็นตัวเลขคงที่แทนสัดส่วนของกรอบ เพราะ `WidgetChrome` ย่อ/ขยายทั้งก้อนให้อยู่แล้ว
/// (ดู `WidgetChrome` — เนื้อหาถูกวาดที่ขนาดออกแบบเสมอ) ผังจึงเป็นจริงทุกขนาด
enum NP {
    static let w: CGFloat = 366
    static let h: CGFloat = 221

    /// ขอบของแถวป้าย — แคบกว่าใบอื่นในตู้ ป้ายต้องเกือบชนขอบแผ่นแบบโปสเตอร์
    static let pad: CGFloat = 12
    /// ขอบของก้อนตัวอักษร — กว้างกว่าป้าย คำยักษ์จึงไม่ไปชนมุมมนของแผ่น
    static let typePad: CGFloat = 20
    static let typeTop: CGFloat = 14
    /// เพดานของสองบรรทัด — บรรทัดล่างใหญ่กว่าชัดเจนตามต้นฉบับ (วัดจากความสูงตัวพิมพ์ใหญ่)
    static let cap1: CGFloat = 35
    static let cap2: CGFloat = 44
    /// ความกว้างที่แต่ละบรรทัดถูก *จัดให้เต็ม* — **ไม่ใช่เต็มแผ่น**
    ///
    /// ต้นฉบับวางพาดหัวไว้กลางแผ่นโดยเหลือขอบทั้งสองข้าง และบรรทัดล่างกว้างกว่าบรรทัดบน
    /// ความต่างของสองความกว้างนี้คือสิ่งที่ทำให้ก้อนพาดหัวเป็น *รูปทรง* ไม่ใช่สองบรรทัดที่บังเอิญ
    /// ยาวเท่ากัน — จัดเต็มแผ่นทั้งคู่เมื่อไหร่ ก้อนจะกลายเป็นสี่เหลี่ยมตันแล้วจังหวะหายไปทั้งใบ
    static let line1W: CGFloat = 0.74
    static let line2W: CGFloat = 0.86

    /// **ช่องว่างกลางแผ่นที่ห้ามมีป้าย** — ที่ยืนของคน · ตัวเลขนี้คือหัวใจของผังทั้งใบ
    static let clearW: CGFloat = 134
    /// ความกว้างสูงสุดของป้ายที่แถวบนสุด (แถวล่างได้น้อยลงตาม `arc`)
    static var colW: CGFloat { (w - clearW) / 2 - pad }

    /// แถบที่แถวป้ายนั่งอยู่ — แถวถูกจัดกลางแถบนี้ ไม่ใช่ไล่ลงจากขอบบน
    /// (มีสามแท็กก็ยังอยู่กลางตัวคน ไม่ใช่กระจุกอยู่หัวไหล่แล้วปล่อยครึ่งล่างว่าง)
    static let bandTop: CGFloat = 99
    static let bandBottom: CGFloat = 207
    static let pitch: CGFloat = 29
    static let pillH: CGFloat = 24
    /// **ขนาดตัวอักษรในป้าย — ไม่ได้ย่อตามต้นฉบับแล้ว**
    ///
    /// สเกลตรงจากสไลด์ได้ 10 ซึ่งบนสไลด์ที่ฉายเต็มจอยังอ่านได้ แต่บนการ์ดที่กว้าง ~360pt
    /// มันคือตัวอักษรไทย 10pt ที่มีสระบน/ล่าง — เล็กเกินกว่าจะอ่านออกบนมือถือ
    /// แถบป้ายจึงขยายขึ้นพร้อมกันทั้งชุด (ตัวอักษร · ความสูงป้าย · ระยะแถว)
    /// โดยกรอบรวมของสี่แถวยังอยู่ในแถบเดิม (`bandTop`…`bandBottom`) ไม่ไปชนพาดหัวหรือขอบล่าง
    static let pillFont: CGFloat = 13
    /// ระยะที่ป้ายแถวล่างสุดถอยเข้าหากลางแผ่น — ตามส่วนที่กว้างที่สุดของตัวคน
    /// (ลดจาก 50 ตอนขยายตัวอักษร — แถวล่างต้องเหลือความกว้างพอให้คำยาวไม่ถูกย่อกลับไปจิ๋ว)
    static let arc: CGFloat = 42
    /// สองปีก ปีกละสี่ — เกินจากนี้ผังของต้นฉบับไม่มีที่ให้ (ดู `visible`)
    static let maxRows = 4

    /// ระยะถอยของแถวที่จุดกึ่งกลางอยู่สูง `y` — โค้งตาม **ตำแหน่งจริงบนแผ่น** ไม่ใช่ลำดับแถว
    ///
    /// ผูกกับลำดับแถวแล้วจะผิดทันทีที่แท็กเหลือสองใบ: แถวที่สองจะได้ระยะถอยของ "แถวล่างสุด"
    /// ทั้งที่มันนั่งอยู่กลางแผ่นตรงที่ตัวคนยังแคบอยู่ · ผูกกับ y แล้วกฎเป็นจริงเสมอ
    /// เพราะสิ่งที่ดันป้ายคือ *ตัวคน* ซึ่งอยู่ที่เดิมไม่ว่าจะมีกี่แถว
    static func inset(atY y: CGFloat) -> CGFloat {
        let t = min(1, max(0, (y - h * 0.42) / (h * 0.52)))
        return arc * pow(t, 2.2)
    }
}

/// วัสดุและหมึกของใบนี้ — **ทุกสีคิดจากเฉดของธีม ไม่มีสีตายตัวสักสี**
///
/// ต้นฉบับเป็นเลือดหมูกับครีม ซึ่งถูกตอนอยู่บนสไลด์ใบนั้น แต่บนการ์ดที่เจ้าของเลือกพาเลตต์เอง
/// มันจะกลายเป็นสีที่ไม่มีที่มา (การ์ดโทนเขียวที่มีแผ่นแดงอ่านเป็นของที่หลงมาจากไฟล์อื่น)
/// ที่นี่จึงเก็บ **ความสัมพันธ์** ของต้นฉบับไว้แทนตัวสี: แผ่นเข้มจัดอิ่มสี · หมึกเป็นครีมที่อมเฉดเดียวกัน
struct NicheSkin {
    var papered: Bool
    var plate: Color
    var ink: Color
    var pillLine: Color
    var pillFill: Color
    /// เงาใต้ตัวคน — บนแผ่นพิมพ์ไม่มี (เงาอ่านเป็นสติกเกอร์ที่ถูกแปะ ไม่ใช่คนที่อยู่ในภาพ)
    /// ตอนถอดแผ่นออกต้องมี เพราะพื้นข้างหลังกลายเป็นการ์ดที่มีรูป/ลายของตัวเอง
    var shadow: Bool

    static func make(_ surface: WidgetSurface, theme: CardTheme, on ink: InkStyle) -> NicheSkin {
        if surface == .pane {
            return NicheSkin(papered: true, plate: .clear,
                             ink: ink.text(0.95),
                             pillLine: ink.line(0.26),
                             pillFill: ink.fill(0.06),
                             shadow: false)
        }
        guard surface == .clear else {
            // สีแผ่นกับครีมมาจากสูตรกลางของตู้ (`PosterPlate`) — แผ่นโชว์คลิปใช้ชุดเดียวกัน
            // การ์ดที่วางสองใบนี้ไว้ด้วยกันจึงได้แผ่นสีเดียวกันเป๊ะ ไม่ใช่เลือดหมูสองเฉด
            let cream = PosterPlate.cream(theme)
            return NicheSkin(papered: true,
                             plate: PosterPlate.plate(theme),
                             ink: cream,
                             pillLine: cream.opacity(0.42),
                             pillFill: cream.opacity(0.05),
                             shadow: false)
        }
        return NicheSkin(papered: false, plate: .clear,
                         ink: ink.text(0.95),
                         pillLine: ink.line(0.26),
                         pillFill: ink.fill(0.06),
                         shadow: true)
    }
}

// MARK: - ใบ

struct NichePosterWidget: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(\.widgetID) private var wid
    @Environment(\.widgetLiftsPhoto) private var liftsPhoto
    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var cardInk
    /// พาดหัวบรรทัดบนเป็นตัวหนาต่อด้วยเซริฟเอียงในก้อนเดียว จึงตั้งฟอนต์เอง
    /// (ตัวประกาศช่องใส่ฟอนต์ให้ได้เฉพาะก้อนที่ไม่ได้ตั้งเอง — ดู `EditableTextModifier`)
    @Environment(\.widgetTextStyle) private var tune
    let theme: CardTheme
    let size: CGSize

    /// สองบรรทัดพาดหัวเป็นของ **ดีไซน์** ไม่ใช่ของโปรไฟล์ จึงเก็บต่อชิ้นแบบเดียวกับสำรับบรรณาธิการ
    /// (วางใบนี้สองที่แล้วพาดหัวคนละคำได้ — เป็นเรื่องปกติของโปสเตอร์)
    private static let line1Preset = "MY Niche &"
    private static let line2Preset = "SPECIALITIES"

    var body: some View {
        // # แผ่นต้องเต็มกรอบเสมอ — **ทั้งกว้างและสูง ทุกเคส** (ดู `PosterSheet`)
        //
        // `NP.w × NP.h` เป็นแค่ *ขนาดต่ำสุด* ของผัง · กรอบที่กว้างกว่านั้นยกที่ว่างให้สองปีก
        // (ป้ายถอยออกไปหาขอบ คนยังยืนกลางช่องเดิม) กรอบที่สูงกว่านั้นยกให้พื้นของแผ่น
        // ไม่มีทางไหนที่แผ่นจะเล็กกว่ากรอบแล้วเห็นการ์ดโผล่ข้าง ๆ อีก
        PosterSheet(design: CGSize(width: NP.w, height: NP.h), frame: size) { box in
            sheet(box)
        }
    }

    /// แท็กที่ได้ขึ้นแผ่นจริง — แปดใบ สองปีก ปีกละสี่
    ///
    /// ตัดที่แปดไม่ใช่เพราะขี้เกียจ: ผังของต้นฉบับมีสี่แถว ใบที่เก้าไม่มีที่ให้ยืนนอกจาก
    /// ไปทับตัวคนหรือดันแถวลงไปนอกแผ่น · ที่เหลือยังอยู่ครบใน `nicheTags` ซึ่งอยู่ตระกูลเดียวกัน
    private var visible: [String] { Array(Profile.me.categories.prefix(NP.maxRows * 2)) }

    /// - Parameter box: ผังในหน่วยออกแบบที่ยืดเต็มกรอบแล้ว (≥ `NP.w × NP.h`)
    private func sheet(_ box: CGSize) -> some View {
        let skin = NicheSkin.make(surface, theme: theme, on: cardInk)
        let plane = cutoutPlane(photos, slot: 1, widget: wid, lift: liftsPhoto)
        let items = visible
        let shape = RoundedRectangle(cornerRadius: skin.papered ? min(theme.radius, 20) : 0,
                                     style: .continuous)

        return ZStack(alignment: .topLeading) {
            Color.clear

            // ── แผ่น
            if skin.papered {
                skin.plate
                PlatePatternLayer(sheet: skin.plate)
                // เกล็ดจาง ๆ ชั้นเดียว — แผ่นสีเรียบล้วนที่ความกว้างเท่านี้อ่านเป็นรูปที่ยังโหลดไม่เสร็จ
                EdGrain(count: 260, opacity: 0.04, tint: .white)
            }

            // ── ชั้นหลัง: คำพาดหัวสองบรรทัด
            headline(skin, w: box.width)

            // ── ชั้นกลาง: สองปีก
            wings(skin, items: items, w: box.width)

            // ── ชั้นหน้า: คน
            subject(plane, skin: skin, w: box.width)

            // ป้ายสถานะไปอยู่ **ขวาบน** — ซ้ายบนของใบนี้คือตัวแรกของคำพาดหัว
            CutoutStatus(plane: plane, theme: theme,
                         lifting: cutoutLifting(photos, slot: 1, widget: wid, lift: liftsPhoto))
                .padding(9)
                .frame(width: box.width, height: box.height, alignment: .topTrailing)
        }
        .frame(width: box.width, height: box.height)
        .clipShape(shape)
    }

    // MARK: คำพาดหัว

    /// สองบรรทัดกลางแผ่น — **แต่ละบรรทัดถูกจัดให้เต็มความกว้างของตัวเอง** (ดู `NP.line1W`)
    ///
    /// ขนาดตายตัวใช้ไม่ได้: คำสั้นจะลอยอยู่กลางแผ่นโดยมีที่ว่างสองข้างเป็นคืบ ส่วนคำยาว
    /// ถูกย่อจนเป็นบรรทัดจิ๋ว — ทั้งสองอย่างไม่ใช่พาดหัวโปสเตอร์แล้ว
    ///
    /// # บรรทัดบนมีสองหน้าตาในก้อนเดียว
    ///
    /// ต้นฉบับเป็น `MY` ตัวหนา + `Niche` เซริฟเอียง + `&` — สามท่อนคนละหน้าตาในบรรทัดเดียว
    /// ถ้าแยกเป็นสามช่องพิมพ์ ผู้ใช้จะต้องแต่งสามครั้งเพื่อเปลี่ยนพาดหัวหนึ่งบรรทัด (และช่องที่มี
    /// คำว่า "&" อยู่ช่องเดียวคือของที่ไม่มีใครเข้าใจว่ามีไว้ทำไม)
    ///
    /// กฎที่ใช้แทนคือข้อเดียวที่ผู้ใช้รู้สึกได้เอง: **คำแรกหนา ที่เหลือเซริฟเอียง**
    /// พิมพ์ทับได้ทั้งบรรทัดในช่องเดียว แล้วหน้าตาสองท่อนยังอยู่ · ต่อ `Text` เข้าด้วยกัน
    /// ไม่ใช่วางสอง `Text` ใน `HStack` เพราะการย่อให้พอดีบรรทัดต้องเกิดกับทั้งก้อนพร้อมกัน
    private func headline(_ skin: NicheSkin, w: CGFloat) -> some View {
        let width = w - NP.typePad * 2
        let l1 = Profile.me.note(wid, 1, preset: Self.line1Preset)
        let l2 = Profile.me.note(wid, 2, preset: Self.line2Preset).uppercased()
        let fs1 = Ed.fitted(l1, weight: .heavy, width: w * NP.line1W, cap: NP.cap1, floor: 13)
        let fs2 = Ed.fitted(l2, weight: .heavy, width: w * NP.line2W, cap: NP.cap2, floor: 13)

        // ระยะระหว่างบรรทัดติดลบ — **ไม่ใช่การบีบให้สวย แต่เป็นการหักที่ว่างที่ฟอนต์เผื่อไว้**
        // NotoSansThai กันที่ให้สระบน/วรรณยุกต์ไว้เหนือทุกบรรทัดเสมอ พาดหัวอังกฤษล้วนจึงมี
        // ช่องว่างเปล่าราวหนึ่งในสามของตัวอักษรคั่นอยู่ ซึ่งในสายตาคืออีกบรรทัดที่หายไป
        // (หักไว้แค่ 0.30 ไม่ใช่มากกว่านั้น — พาดหัวที่พิมพ์เป็นไทยต้องยังมีที่ให้สระอยู่)
        return VStack(alignment: .center, spacing: -fs1 * 0.30) {
            mixedLine(l1, size: fs1, color: skin.ink)
                .lineLimit(1).minimumScaleFactor(0.4)
                .editableText(.note, index: 1, widget: wid,
                              preset: Self.line1Preset, hint: "พาดหัวบรรทัดบน",
                              .init(size: fs1, weight: .heavy, color: skin.ink,
                                    align: .center, tracking: -fs1 * 0.03, corner: 6))
            Text(l2)
                // heavy ไม่ใช่ black — ที่น้ำหนักหนาสุด NotoSansThai วางสระบนชนวรรณยุกต์
                .kerning(-tune.scaled(fs2, for: .note, 2) * 0.03)
                .lineLimit(1).minimumScaleFactor(0.4)
                .editableText(.note, index: 2, widget: wid,
                              preset: Self.line2Preset, hint: "พาดหัวบรรทัดล่าง",
                              .init(size: fs2, weight: .heavy, color: skin.ink,
                                    align: .center, tracking: -fs2 * 0.03,
                                    uppercase: true, corner: 6))
        }
        .frame(width: width, alignment: .center)
        .padding(.horizontal, NP.typePad)
        .padding(.top, NP.typeTop)
        // ชั้นหลังสุดวิ่งสวนแรงที่สุด — ตาอ่านความลึกจาก *ความต่างของอัตรา* ไม่ใช่จากระยะ
        .scrubSlide(scrub.d, travel: -NP.w * 0.26, fade: 0.84, eased: false)
    }

    /// คำแรกหนา · ที่เหลือเซริฟเอียง — คืน `Text` ก้อนเดียวที่ย่อพร้อมกันทั้งบรรทัด
    private func mixedLine(_ raw: String, size: CGFloat, color: Color) -> Text {
        let parts = raw.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let s = tune.scaled(size, for: .note, 1)
        let head = Text(String(parts.first ?? "").uppercased())
            .font(tune.font(size, .heavy, for: .note, 1))
            .kerning(-s * 0.03)
        guard parts.count > 1 else { return head.foregroundColor(color) }
        // เซริฟที่ขนาดเท่ากันดู *เตี้ยกว่า* ตัวหนา (x-height ต่างกัน) — ชดเชยขึ้นเล็กน้อย
        // ฟอนต์ที่ผู้ใช้สั่งทับมาก่อนเซริฟของดีไซน์ — สั่งแล้วต้องได้ทั้งบรรทัด ไม่ใช่ครึ่งเดียว
        let tail = Text(" " + String(parts[1]))
            .font((tune.face(for: .note, 1) ?? .serif).font(s * 1.04, .regular).italic())
        return (head + tail).foregroundColor(color)
    }

    // MARK: สองปีก

    private func wings(_ skin: NicheSkin, items: [String], w: CGFloat) -> some View {
        let rows = min(NP.maxRows, (items.count + 1) / 2)
        let blockH = CGFloat(max(rows - 1, 0)) * NP.pitch + NP.pillH
        let top = (NP.bandTop + NP.bandBottom) / 2 - blockH / 2

        return ZStack(alignment: .topLeading) {
            Color.clear
            ForEach(0..<rows, id: \.self) { r in
                let y = top + CGFloat(r) * NP.pitch
                let inset = NP.inset(atY: y + NP.pillH / 2)
                let lead = Scrub.lead(r, of: rows, d: scrub.d, step: 0.07)
                HStack(spacing: 0) {
                    if let s = item(items, 2 * r) {
                        pill(s, index: 2 * r, skin: skin, maxW: NP.colW - inset,
                             lead: lead, travel: -NP.w * 0.2)
                    }
                    Spacer(minLength: 0)
                    if let s = item(items, 2 * r + 1) {
                        pill(s, index: 2 * r + 1, skin: skin, maxW: NP.colW - inset,
                             lead: lead, travel: NP.w * 0.2)
                    }
                }
                .padding(.horizontal, NP.pad + inset)
                // # แถวป้ายกว้างเท่า **ผัง** เสมอ แล้วจัดกลางในแผ่นที่กว้างขึ้น
                //
                // ป้ายเป็นของที่ *ล้อมตัวคน* ไม่ใช่ของที่เกาะขอบแผ่น — ผูกกับขอบเมื่อไหร่
                // แผ่นที่ถูกลากให้กว้างจะดีดสองปีกออกไปคนละมุมจนคนยืนโดดอยู่กลางที่ว่าง
                // (ลองแล้วรอบหนึ่ง: "chip ต้องมาอยู่กลาง ๆ กว่านี้")
                // ระยะจากตัวคนถึงป้ายจึงคงที่ ส่วนที่กว้างขึ้นกลายเป็นขอบว่างสองข้างแทน
                .frame(width: NP.w, height: NP.pillH)
                .frame(width: w)
                .offset(y: y)
            }
        }
        .frame(width: w, height: NP.h, alignment: .topLeading)
        // ลบแท็กออกหนึ่งใบแล้วลำดับที่เหลือเลื่อน — ผูก id กับลิสต์ให้ SwiftUI สร้างใหม่ทั้งชุด
        // ไม่งั้นป้ายใบถัดไปจะยังถือ index เดิมแล้วแก้ผิดใบ
        .id(items)
    }

    private func item(_ items: [String], _ i: Int) -> String? {
        i < items.count ? items[i] : nil
    }

    /// ป้ายหนึ่งใบ — **กว้างตามคำที่อยู่ข้างใน แต่ไม่เกินที่ว่างของแถวนั้น**
    ///
    /// วัดความกว้างเองแทนที่จะใช้ `.frame(maxWidth:)` เพราะกรอบที่มีแต่ `maxWidth` เป็นของ *ยืด*
    /// ใน `HStack` มันจะกินที่จนสุดเพดานทุกใบ แล้วป้ายทั้งสี่แถวกว้างเท่ากันหมด —
    /// ซึ่งอ่านเป็นตาราง ไม่ใช่แท็ก (ความยาวไม่เท่ากันของแต่ละคำคือสิ่งที่ทำให้มันเป็นแท็ก)
    private func pill(_ text: String, index: Int, skin: NicheSkin, maxW: CGFloat,
                      lead: Double, travel: CGFloat) -> some View {
        let sidePad: CGFloat = 10
        let natural = TextFit.metrics(text, face: .noto, weight: .semibold,
                                      size: NP.pillFont, align: .leading).ink.width
        let width = min(natural + sidePad * 2 + 2, max(maxW, 44))

        return Text(text)
            // พื้นย่อสุดที่ยังอ่านออก — ที่ 0.55 คำยาวในแถวล่าง (ซึ่งที่ว่างแคบที่สุด)
            // ถูกย่อกลับไปเล็กกว่าเดิม แล้วการขยายตัวอักษรทั้งชุดก็ไม่มีผลกับป้ายใบนั้นเลย
            .lineLimit(1).minimumScaleFactor(0.72)
            // ลบข้อความจนหมดแล้วปิดช่อง = เอาป้ายใบนั้นออก (ดู `Profile.commit`)
            .editableText(.categories, index: index,
                          .init(size: NP.pillFont, weight: .semibold,
                                color: skin.ink, corner: 12))
            .padding(.horizontal, sidePad)
            .frame(width: width, height: NP.pillH)
            .background(Capsule().fill(skin.pillFill))
            .overlay(Capsule().strokeBorder(skin.pillLine, lineWidth: 0.8))
            // ปีกซ้ายไปซ้าย ปีกขวาไปขวา — สองข้างแยกจากกันตอนเลื่อน แล้วหุบกลับมาหาคน
            .scrubSlide(scrub.d, travel: travel, lead: lead, fade: 0.55)
    }

    // MARK: คน

    @ViewBuilder
    private func subject(_ plane: CutoutPlane, skin: NicheSkin, w: CGFloat) -> some View {
        switch plane {
        case let .subject(ui, _):
            // # สูง 0.70 ของแผ่น — ไม่ใช่ 0.92 อย่างอีกสามใบของตระกูล
            //
            // ตัวเลขนี้คือสัดส่วนของต้นฉบับเป๊ะ ๆ และมันทำงานอย่างหนึ่งที่มองไม่เห็น:
            // **ขอบบนของหัวไปตกที่ขอบบนของคำยักษ์บรรทัดล่างพอดี** แปลว่าบรรทัดบน —
            // บรรทัดที่มีคำเซริฟเอียงซึ่งเป็นลายเซ็นของใบนี้ — ไม่มีวันถูกบังไม่ว่าเงาของรูป
            // จะเป็นทรงไหน · รอบแรกตั้งไว้ 0.92 ตามใบพี่ ๆ แล้วรูปที่ยกแขน (ซึ่งมีเยอะมาก
            // ในรูปโปรไฟล์ครีเอเตอร์) กินคำว่า `&` หายไปทั้งตัวตั้งแต่รูปแรกที่ลอง
            //
            // เพดานความกว้างยังอยู่: `CutoutSubject` คิดความกว้างจากสัดส่วนของรูปเอง
            // รูปทรงกว้าง (คนนั่ง · คนกางแขน) จะล้นไปทับป้ายสองข้างโดยที่ผังไม่รู้ตัว
            // ที่นี่จึงแปลง "กว้างได้แค่ไหน" กลับเป็น "สูงได้แค่ไหน" แล้วยอมให้เตี้ยลงแทน
            let ar = ui.size.height > 0 ? ui.size.width / ui.size.height : 0.7
            let cap = NP.clearW * 1.08 / max(ar, 0.05)
            let hh = min(NP.h * 0.70, cap)
            CutoutSubject(image: ui, height: hh, d: scrub.d, drift: NP.w * 0.035,
                          shadow: skin.shadow)
                // กรอบของ *ช่อง* เท่าตัวคนพอดี — ปุ่มเปลี่ยนรูปเกาะกรอบนี้
                .photoSlot(1)
                .frame(width: w, height: NP.h, alignment: .bottom)
                // ล้นขอบล่างเล็กน้อย — รอยตัดที่เอวจะได้จบนอกแผ่น ไม่ใช่กลางแผ่น
                .offset(y: NP.h * 0.03)
        case .framed:
            // รูปทึบ — แผ่นยังเป็นแผ่นใบเดิม เปลี่ยนแค่ว่ารูปถูก **พิมพ์เป็นบล็อก** กลางช่องว่าง
            //
            // ไม่ใช่ "แบบเดียวกันแต่พัง": ใบนี้อยู่ตระกูลเดียวกับสายงานอีกสามใบ คนกด "เปลี่ยนแบบ"
            // มาเจอมันด้วยรูป JPEG ตลอดเวลา ถ้าหน้าตาตรงนั้นแย่ ทั้งแบบก็ไม่มีความหมาย
            Color.clear
                .overlay {
                    WidgetPhoto(index: 1)
                        .aspectRatio(contentMode: .fill)
                        .scrubDolly(scrub.d, shift: NP.w * 0.04, zoom: 0.12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .frame(width: NP.clearW + 14, height: NP.h - NP.bandTop + 24)
                .photoSlot(1)
                .frame(width: w, height: NP.h, alignment: .bottom)
                .offset(y: -NP.h * 0.045)
        }
    }
}
