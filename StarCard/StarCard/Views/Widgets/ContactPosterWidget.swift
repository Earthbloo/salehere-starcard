import SwiftUI

// MARK: - โปสเตอร์ติดต่อ
//
// ใบที่ห้าของตระกูลคัตเอาต์ (สี่ใบแรกอยู่ใน `CutoutWidgets.swift` · `PosterWidgets.swift`
// · `NichePosterWidget.swift`) — แต่เป็น **ใบแรกของตระกูลที่อยู่หมวด "รับงาน"**
//
// # ใบนี้ทำอะไรที่อีกหกแบบในตระกูล `contact` ทำไม่ได้
//
// หกแบบเดิมคือ *ป้ายข้อมูล*: บัตร · แถบ · สามบรรทัด · ชิป · คิวอาร์ · ไลน์ตัวใหญ่
// ทุกใบอ่านเป็น "ตารางค่าที่ต้องก็อป" ซึ่งถูกต้องตอนอยู่ท้ายการ์ดที่มี hero อยู่แล้ว
// แต่ไม่มีใบไหน **เป็นภาพ** ได้เลย — คนที่อยากให้ช่องทางติดต่อเป็นแผ่นปิดท้ายที่มีหน้าตัวเอง
// ต้องเอา hero มาวางซ้ำแล้วแปะแถบติดต่อไว้ข้างใต้ ซึ่งเป็นสองชิ้นที่เล่าเรื่องเดียวกัน
//
// ใบนี้ยุบสองชิ้นนั้นเป็นชิ้นเดียว: **คนยืนอยู่ในแผ่น ค่าติดต่อนั่งอยู่ข้างเขา**
//
// # มีแค่ค่าติดต่อ ไม่มีอย่างอื่น
//
// ไม่มีชื่อ ไม่มีสายงาน ไม่มีสถานะผู้รับงาน ไม่มีลายน้ำ — ตัวอักษรบนแผ่นนี้มีสองชนิดเท่านั้น
// คือ **พาดหัว** กับ **ค่าที่ต้องก็อป** · หน้าคือสิ่งที่บอกว่านี่คือใคร ไม่ใช่บรรทัดชื่อ
// (ต้นฉบับที่ผู้ใช้ส่งมาก็เป็นแบบนั้น: CONTACT ME + สี่ช่องทาง + คน จบแค่นั้น)
//
// # สีมาจากธีมของการ์ด ไม่ใช่จากต้นฉบับ
//
// ต้นฉบับเป็นม่วง ซึ่งถูกอยู่บนแผ่นนั้น แต่บนการ์ดที่เจ้าของเลือกพาเลตต์เอง แผ่นม่วง
// บนการ์ดโทนเขียวอ่านเป็นของที่หลงมาจากไฟล์อื่น · ที่นี่จึงเก็บ **ความสัมพันธ์** ของต้นฉบับไว้แทน:
// แผ่นไล่เฉดจากสว่างมุมบนซ้ายไปเข้มมุมล่างขวา · ตราวงกลมเข้มกว่าแผ่น · หมึกเป็นครีมที่อมเฉดเดียวกัน
// · ตัวคนถูกเกลี่ยสีให้เข้าโทนเดียวกับแผ่น ทุกค่าคิดจาก `theme.backdropHue` ตัวเดียว

/// ค่าคงที่ของผัง — **หน่วยเดียวกับ `WidgetKind.defaultSize`** (366 × 270)
///
/// เขียนเป็นตัวเลขคงที่แทนสัดส่วนของกรอบ เพราะ `WidgetChrome` ย่อ/ขยายทั้งก้อนให้อยู่แล้ว
/// (เนื้อหาถูกวาดที่ขนาดออกแบบเสมอ) ผังจึงเป็นจริงทุกขนาด
enum CP {
    static let w: CGFloat = 366
    // เตี้ยกว่ารอบแรก 30pt — ผังเดิมเหลือที่ว่างใต้แถวสุดท้ายเกือบหนึ่งในสามของแผ่น
    // ซึ่งอ่านเป็น "ใบใหญ่เกินเนื้อหา" ไม่ใช่ที่ว่างที่จงใจ
    static let h: CGFloat = 270

    static let pad: CGFloat = 22
    /// พาดหัว — เล็กกว่ารอบแรกหนึ่งขั้น (27 → 22) เพราะคำเดียวกินความกว้างครึ่งแผ่นแล้ว
    static let titleSize: CGFloat = 22

    // ── ชิปช่องทาง
    //
    // เดิมเป็น *ตรากลม + ค่าลอย ๆ บนแผ่น*: ค่าถูกบีบอยู่ในคอลัมน์กว้างตายตัว 120pt
    // อีเมลยาว 18 ตัวอักษรจึงถูกย่อลงเหลือราว 7pt (`minimumScaleFactor` 0.55) —
    // เล็กกว่าตัวเลขบนสลิปธนาคาร และไม่มีพื้นรองให้ตัดกับแผ่นสีเข้ม
    //
    // ตอนนี้ค่าแต่ละช่องนั่งใน **ชิป** ของตัวเอง: พื้นครีมทึบ หมึกเข้มเท่าแผ่น ตัวอักษรใหญ่ขึ้น
    // และชิปหุ้มพอดีข้อความ (ไม่ใช่คอลัมน์ตายตัว) ความยาวที่ต่างกันจึงไม่ทำให้ตัวอักษรหด
    /// ไอคอนนำหน้าในชิป
    static let chipIcon: CGFloat = 11.5
    /// ขนาดของค่าที่ต้องก็อป — ใหญ่กว่าเดิมหนึ่งขั้นเต็ม เพราะมีพื้นชิปรองแล้ว
    static let valueSize: CGFloat = 13.5
    static let chipPadH: CGFloat = 12
    static let chipPadV: CGFloat = 7.5
    /// ช่องไฟระหว่างไอคอนกับค่าในชิปเดียวกัน
    static let gap: CGFloat = 7
    /// ระยะระหว่างชิป — แน่นพอให้สามอันอ่านเป็นก้อนเดียว ไม่ใช่สามป้ายที่บังเอิญอยู่ใกล้กัน
    static let chipGap: CGFloat = 9
    /// ขอบบนของชิปใบแรก — ก้อนสามชิปอยู่กลางแผ่นค่อนลงล่าง ไม่ใช่ไล่ลงจากพาดหัว
    static let firstRow: CGFloat = 96

    /// ขอบซ้ายของตัวคน — ค่าติดต่อต้องจบก่อนถึงเส้นนี้เสมอ
    ///
    /// ต้นฉบับวางคนไว้ *ข้าง* คอลัมน์ข้อความ ไม่ใช่ทับมัน — ตัวอักษรที่ถูกไหล่กินครึ่งบรรทัด
    /// อ่านเป็นผังที่พัง ไม่ใช่ความลึก (ความลึกของใบนี้อยู่ที่แสงหลังหัวกับอัตราการเลื่อน)
    static let subjectEdge: CGFloat = 206
    /// ช่องยืนของคน วัดจาก **ขอบขวา** — กว้างคงที่ไม่ว่าแผ่นจะถูกลากให้กว้างแค่ไหน
    /// (คนไม่ได้โตตามกรอบ ที่ว่างที่ได้มาจึงเป็นของคอลัมน์ซ้ายทั้งก้อน)
    static let subjectZone: CGFloat = w - subjectEdge

    /// ความกว้างที่ *ตัวอักษร* ในชิปมีจริง — หักพื้นชิปกับไอคอนออกจากช่องว่างถึงตัวคนแล้ว
    static var valueW: CGFloat {
        subjectEdge - pad - (chipPadH * 2 + chipIcon + gap) - 6
    }
}

/// วัสดุและหมึกของใบนี้ — **ทุกสีคิดจากเฉดของธีม ไม่มีสีตายตัวสักสี**
///
/// # แผ่นเป็นสีเรียบ ไม่ใช่ไล่เฉด
///
/// รอบแรกเป็นไล่เฉดสว่าง→เข้มบวกแสงหลังหัว ซึ่งอ่านเป็น *เอฟเฟกต์* ไม่ใช่สีที่เจ้าของการ์ดเลือก —
/// และบนการ์ดที่มีของหลายชิ้น แผ่นที่สีไม่นิ่งจะสู้กับทุกอย่างรอบตัว · สีเดียวเรียบ ๆ
/// ทำให้ใบนี้เป็น "บล็อกสีของธีม" ที่วางข้างของชิ้นอื่นได้โดยไม่แย่งสายตา
struct ContactPosterSkin {
    /// มีแผ่นรองไหม — เจ้าของการ์ดเลือกเองจากถาด (ดู `WidgetKind.surfaceOptions`)
    var papered: Bool
    var plate: Color
    var ink: Color
    /// พื้นของชิป — ทึบบนแผ่นสี (ตัวอักษรต้องตัดกับพื้นของตัวเอง ไม่ใช่กับแผ่น)
    var chipFill: Color
    var chipLine: Color
    /// หมึกในชิป — เข้มเท่าแผ่นเมื่อชิปเป็นครีม
    var chipInk: Color
    var chipGlyph: Color
    /// เงาใต้ตัวคน — บนแผ่นพิมพ์ไม่มี (เงาอ่านเป็นสติกเกอร์ที่ถูกแปะ ไม่ใช่คนที่อยู่ในภาพ)
    /// ตอนถอดแผ่นออกต้องมี เพราะพื้นข้างหลังกลายเป็นการ์ดที่มีรูป/ลายของตัวเอง
    var shadow: Bool

    static func make(_ surface: WidgetSurface, theme: CardTheme, on ink: InkStyle) -> ContactPosterSkin {
        let h = theme.backdropHue
        if surface == .pane {
            return ContactPosterSkin(papered: true, plate: .clear,
                                     ink: ink.text(0.95),
                                     chipFill: ink.fill(0.12),
                                     chipLine: ink.line(0.26),
                                     chipInk: ink.text(0.95),
                                     chipGlyph: ink.text(0.72),
                                     shadow: false)
        }
        if surface != .clear, let duo = theme.activeDuo {
            return ContactPosterSkin(papered: true,
                                     plate: duo.dark, ink: duo.light,
                                     chipFill: duo.light.opacity(0.94), chipLine: .clear,
                                     chipInk: duo.dark,
                                     chipGlyph: duo.dark.mixed(with: duo.light, by: 0.30),
                                     shadow: false)
        }
        guard surface == .clear else {
            let cream = PosterPlate.cream(theme)
            return ContactPosterSkin(
                papered: true,
                // เข้มพอให้ครีมอ่านออกทุกพาเลตต์ (รวมแชมเปญกับไลม์ที่เฉดสว่างอยู่แล้ว)
                // และอิ่มพอให้ยังเป็น *สี* ไม่ใช่เทาที่อมสี
                plate: Color(hue: h, saturation: 0.62, brightness: 0.34),
                ink: cream,
                // ชิปครีมทึบบนแผ่นเข้ม = คู่สีที่ตัดกันแรงที่สุดที่ใบนี้มีอยู่แล้ว
                // ไม่ต้องเพิ่มสีใหม่ให้แผ่นเพื่อให้อ่านออก
                chipFill: cream.opacity(0.94),
                chipLine: .clear,
                chipInk: Color(hue: h, saturation: 0.78, brightness: 0.18),
                chipGlyph: Color(hue: h, saturation: 0.66, brightness: 0.36),
                shadow: false)
        }
        // ไม่มีแผ่น — ทุกอย่างนั่งบนการ์ดตรง ๆ หมึกจึงพลิกตามพื้นการ์ด ไม่ใช่ครีมตายตัว
        return ContactPosterSkin(
            papered: false,
            plate: .clear,
            ink: ink.text(0.95),
            // ไม่มีแผ่น = ไม่รู้ว่าพื้นข้างหลังเป็นรูปหรือสีอะไร ชิปจึงเป็นพื้นโปร่งที่มีเส้นขอบ
            // (ครีมทึบตรงนี้จะอ่านเป็นสติกเกอร์สีขาวที่หลงมาจากใบอื่น)
            chipFill: ink.fill(0.12),
            chipLine: ink.line(0.26),
            chipInk: ink.text(0.95),
            chipGlyph: ink.text(0.72),
            shadow: true)
    }
}

// MARK: - ใบ

struct ContactPosterWidget: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(\.widgetID) private var wid
    @Environment(\.widgetLiftsPhoto) private var liftsPhoto
    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var cardInk
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        // # แผ่นต้องเต็มกรอบเสมอ — **ทั้งกว้างและสูง ทุกเคส** (ดู `PosterSheet`)
        //
        // `CP.w × CP.h` เป็นแค่ *ขนาดต่ำสุด* ของผัง · กรอบที่กว้างกว่านั้นยกที่ว่างให้คอลัมน์ซ้าย
        // (พาดหัวยังชิดซ้ายบน คนยังยืนชิดขวา ช่องยืนของเขากว้างเท่าเดิม) กรอบที่สูงกว่านั้น
        // ยกให้พื้นของแผ่นกับตัวคนซึ่งยืนบนขอบล่างที่เห็นจริง — ไม่มีการ์ดโผล่ข้างแผ่นอีก
        PosterSheet(design: CGSize(width: CP.w, height: CP.h), frame: size) { box in
            sheet(box)
        }
    }

    /// - Parameter box: ผังในหน่วยออกแบบที่ยืดเต็มกรอบแล้ว (≥ `CP.w × CP.h`)
    private func sheet(_ box: CGSize) -> some View {
        let skin = ContactPosterSkin.make(surface, theme: theme, on: cardInk)
        let plane = cutoutPlane(photos, slot: 1, widget: wid, lift: liftsPhoto)

        return ZStack(alignment: .topLeading) {
            Color.clear

            // ── พื้น: สีเดียวเรียบ ๆ
            if skin.papered {
                skin.plate
                PlatePatternLayer(sheet: skin.plate)
                // เกล็ดจาง ๆ ชั้นเดียว — สีเรียบล้วนที่ความกว้างเท่านี้อ่านเป็นรูปที่ยังโหลดไม่เสร็จ
                // (เป็นผิวของกระดาษ ไม่ใช่การไล่เฉด — แผ่นยังเป็นสีเดียวทั้งใบ)
                EdGrain(count: 240, opacity: 0.04, tint: .white)
            }

            // ── ของบนแผ่น: **กว้างเท่าผังเสมอ แล้วจัดกลางบนแผ่นที่กว้างขึ้น**
            //
            // พาดหัว · คน · ชิป เป็นก้อนเดียวที่จัดหน้ามาแล้ว (คนยืนข้างคอลัมน์ค่าติดต่อพอดี)
            // ผูกแต่ละชั้นกับขอบแผ่นเมื่อไหร่ แผ่นที่ถูกลากให้กว้างจะดึงคนกับชิปออกจากกัน
            // จนเหลือที่ว่างคั่นกลางหนึ่งคืบ · ที่ว่างที่ได้มาจึงเป็นขอบสองข้าง ไม่ใช่ระยะในผัง
            ZStack(alignment: .topLeading) {
                // ── ชั้นหลัง: พาดหัว
                headline(skin, w: CP.w)

                // ── ชั้นกลาง: คน
                //
                // ส่งความสูงจริงของแผ่นลงไปด้วย — คนต้องยืนอยู่บน *ขอบล่างที่เห็น* ไม่ใช่ที่เส้น 270
                // ของผังตั้งต้น · กรอบที่ถูกลากให้สูงขึ้นแล้วคนลอยค้างกลางแผ่นอ่านเป็นรูปที่วางหลุด
                subject(plane, skin: skin, box: CGSize(width: CP.w, height: box.height))

                // ── ชั้นหน้า: ค่าติดต่อ
                //
                // อยู่ *หน้า* ตัวคนในลำดับการวาด ทั้งที่ผังกันที่ให้ไม่ทับกันอยู่แล้ว —
                // เผื่อรูปที่เจ้าของการ์ดตัดมากว้างกว่าที่ผังเผื่อไว้ ค่าที่ต้องก็อปต้องไม่มีวันถูกบัง
                rows(skin, box: CGSize(width: CP.w, height: box.height))
            }
            .frame(width: CP.w, height: box.height)
            .frame(width: box.width, height: box.height)
        }
        .frame(width: box.width, height: box.height)
        // ไม่มีแผ่น = ไม่มีอะไรให้ตัดมุม · ตัวคนจึงล้นออกไปนั่งบนการ์ดได้จริง
        .clipShape(RoundedRectangle(cornerRadius: skin.papered ? min(theme.radius, 22) : 0,
                                    style: .continuous))
        .overlay(alignment: .topTrailing) {
            CutoutStatus(plane: plane, theme: theme,
                         lifting: cutoutLifting(photos, slot: 1, widget: wid, lift: liftsPhoto)).padding(9)
        }
    }

    // MARK: พาดหัว

    /// `Contact` / `ME` ชิดซ้ายบน สองบรรทัด — **คู่ตัวพิมพ์ ไม่ใช่คำเดียวหนาทึบ**
    ///
    /// ไม่ใช่ช่องที่พิมพ์เองได้ — มันคือ *ชื่อของแผ่น* ไม่ใช่เนื้อหาของเจ้าของการ์ด
    /// (ถ้าเปิดให้พิมพ์ ใบนี้จะกลายเป็นก้อนข้อความที่บังเอิญมีรูปคน ซึ่งมีอยู่แล้วในตู้)
    ///
    /// # ทำไมเลิกใช้ CONTACT ME หนาทึบ + ลูกศรสามตัว
    ///
    /// ตัวหนาทึบล้วนความกว้างครึ่งแผ่น อ่านเป็น *ป้ายประกาศ* ไม่ใช่พาดหัวของแผ่นที่มีคนยืนอยู่
    /// และลูกศรสามตัวคือของประดับที่ไม่ได้ชี้ไปไหนจริง — บนแผ่นเล็ก ๆ มันอ่านเป็นเศษที่ค้างอยู่
    ///
    /// คู่ตัวพิมพ์ที่ใช้คือคู่เดียวกับพาดหัวใบอื่นในตระกูลโปสเตอร์ (ดู `NichePosterWidget`):
    /// คำแรกเป็นเซอริฟเอียงตัวบาง คำหลังเป็นตัวหนาทึบตัวใหญ่กว่า — สองน้ำหนักในบรรทัดเดียว
    /// ทำให้พาดหัวมีจังหวะโดยไม่ต้องมีของประดับ
    private func headline(_ skin: ContactPosterSkin, w: CGFloat) -> some View {
        // ผังเดียวกับหัวของ `ReelWidget` ("Recent" / "VIDEOGRAPHY"): คำนำเซอริฟเอียงตัวบางอยู่บน
        // คำหลักหนาทึบตัวใหญ่อยู่ล่าง ดึงขึ้นมาชิดกัน — ต่างกันแค่ใบนี้ชิดซ้าย เพราะขวาเป็นที่ของคน
        VStack(alignment: .leading, spacing: 0) {
            Text("Contact")
                .font(CardFont.serif.font(CP.titleSize * 0.95, .regular).italic())
            Text("ME")
                .font(.sh(CP.titleSize * 1.5, .black))
                .tracking(0.4)
                .padding(.top, -CP.titleSize * 0.3)
        }
        .foregroundStyle(skin.ink)
        .lineLimit(1).fixedSize()
        .frame(width: w - CP.pad * 2, alignment: .leading)
        .padding(.leading, CP.pad)
        .padding(.top, CP.pad * 0.8)
        // ชั้นหลังสุดวิ่งสวนแรงที่สุด — ตาอ่านความลึกจาก *ความต่างของอัตรา* ไม่ใช่จากระยะ
        .scrubSlide(scrub.d, travel: -CP.w * 0.26, fade: 0.84, eased: false)
    }

    // MARK: ค่าติดต่อ

    /// สามช่องทางของตระกูล (`ContactLine.all`) — **ชิปละหนึ่งช่องทาง** ไม่มีป้ายกำกับ
    ///
    /// ป้ายกำกับ ("โทร" · "อีเมล") ยังไม่มีเหมือนเดิม — ไอคอนบอกเรื่องเดียวกันอยู่แล้ว
    /// และบนแผ่นที่มีหน้าคนอยู่ครึ่งใบ ทุกคำที่ไม่ใช่ค่าที่ต้องก็อปคือคำที่แย่งสายตาไปเปล่า ๆ
    ///
    /// ชิปหุ้ม **พอดีข้อความ** (`fixedSize`) ไม่ใช่คอลัมน์กว้างเท่ากันสามอัน: ความยาวที่ต่างกัน
    /// ของเบอร์/อีเมล/ไลน์จึงไม่ถูกบีบให้เท่ากัน ตัวอักษรได้ขนาดเต็มทุกอัน
    /// - Parameter box: ผังจริงของแผ่น — ก้อนชิปยังเกาะขอบบนเหมือนเดิม
    ///   (จังหวะของคอลัมน์เป็นของผัง ไม่ใช่ของกรอบ) ส่วนความกว้างที่ชิปมีได้คิดจากแผ่นจริง
    private func rows(_ skin: ContactPosterSkin, box: CGSize) -> some View {
        // ระยะของชิปมาจาก **ผัง** ไม่ใช่ `.offset`
        //
        // `scrubVeil` ปิดท้ายด้วย `.mask { Rectangle() }` ซึ่งเป็นสี่เหลี่ยมขนาด *กรอบผัง* ของชิ้น
        // ชิ้นที่ถูก `.offset` ไปวาดที่อื่นจึงถูกหน้ากากตัวเองตัดทิ้งทั้งแถว (เจอมาแล้วรอบหนึ่ง:
        // แผ่นขึ้นครบแต่ไม่มีชิปไหนโผล่เลยสักอัน) · ระยะทุกค่าจึงต้องเป็น padding/spacing เท่านั้น
        VStack(alignment: .leading, spacing: CP.chipGap) {
            ForEach(Array(ContactLine.all.enumerated()), id: \.offset) { i, l in
                HStack(spacing: CP.gap) {
                    Image(systemName: l.icon)
                        .font(.system(size: CP.chipIcon, weight: .bold))
                        .foregroundStyle(skin.chipGlyph)
                    Text(Profile.me.text(l.field))
                        .lineLimit(1).minimumScaleFactor(0.8).truncationMode(.tail)
                        .editableText(l.field, .init(size: CP.valueSize, weight: .semibold,
                                                     color: skin.chipInk, corner: 999))
                        .frame(maxWidth: CP.valueW, alignment: .leading)
                }
                .fixedSize()
                .padding(.horizontal, CP.chipPadH)
                .padding(.vertical, CP.chipPadV)
                .background(Capsule().fill(skin.chipFill))
                .overlay(Capsule().strokeBorder(skin.chipLine, lineWidth: 0.8))
                .linkSlot(l.field.contactURL)
                // ชิปมุดใต้ขอบไล่ทีละอัน — ภาษาเดียวกับอีกหกแบบในตระกูล
                .scrubVeil(scrub.d,
                           lead: Scrub.lead(i, of: ContactLine.all.count, d: scrub.d, step: 0.08),
                           drop: 26, pull: 12)
            }
        }
        // สีของ *ตัวอักษรที่ไม่ใช่ช่อง* ในก้อนนี้ — ช่องที่แก้ได้ได้สีจาก `TextSlotStyle` ที่ส่งให้
        // `.editableText` โดยตรง (ดู `EditableTextModifier`) บรรทัดนี้จึงไม่ใช่ทางที่ค่าติดต่อได้สีมา
        .foregroundStyle(skin.ink)
        .padding(.leading, CP.pad)
        .padding(.top, CP.firstRow)
        .frame(width: box.width, height: box.height, alignment: .topLeading)
    }

    // MARK: คน

    /// ตัวคนชิดขวา ล้นขอบล่างและขอบขวาเล็กน้อย — ต้นฉบับครอปแบบนั้น
    ///
    /// รอยตัดที่เอวของ PNG ส่วนใหญ่ต้องตกนอกแผ่น ไม่งั้นมันอ่านเป็นรูปครึ่งท่อนลอยอยู่
    /// ไม่ใช่คนที่ยืนอยู่ · เงาถูกปิด เพราะนี่คือแผ่นพิมพ์ ไม่ใช่สติกเกอร์ที่ถูกแปะบนแผ่น
    /// - Parameter box: ผังจริงของแผ่น — ทุกระยะของชั้นนี้คิดจากค่านี้ ไม่ใช่จาก `CP.w × CP.h`
    @ViewBuilder
    private func subject(_ plane: CutoutPlane, skin: ContactPosterSkin,
                         box: CGSize) -> some View {
        switch plane {
        case let .subject(ui, _):
            // 0.80 ไม่ใช่เต็มใบ — หัวต้องจบ *ใต้* พาดหัว ไม่งั้นมันกินคำว่า ME กับลูกศรไปทั้งชุด
            //
            // **รูปไม่ถูกย้อมสีใด ๆ** — รอบก่อนเกลี่ยสีให้เข้าโทนแผ่นแล้วผิวคนเพี้ยนไปทั้งรูป
            // ซึ่งเป็นราคาที่ไม่มีใครยอมจ่ายเพื่อความกลมกลืน · รูปที่เจ้าของการ์ดตัดมาขึ้นตามจริง
            CutoutSubject(image: ui, height: box.height * 0.80, d: scrub.d,
                          drift: CP.w * 0.035, shadow: skin.shadow)
                // กรอบของ *ช่อง* เท่าตัวคนพอดี — ปุ่มเปลี่ยนรูปเกาะกรอบนี้
                .photoSlot(1)
                .frame(width: box.width, height: box.height, alignment: .bottomTrailing)
                .offset(x: CP.w * 0.045, y: box.height * 0.035)
        case .framed:
            // รูปทึบ — กลับไปโหมดกรอบ **เงียบ ๆ** แผ่นมนทางขวาแทนที่จะเป็นคนยืนบนแผ่น
            // ผังที่เหลือไม่ขยับสักนิด: พาดหัวยังชิดซ้ายบน สามแถวยังอยู่ใต้มัน
            Color.clear
                .overlay {
                    WidgetPhoto(index: 1)
                        .aspectRatio(contentMode: .fill)
                        .scrubDolly(scrub.d, shift: CP.w * 0.04, zoom: 0.12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .frame(width: CP.subjectZone - 6, height: box.height * 0.62)
                .photoSlot(1)
                .frame(width: box.width, height: box.height, alignment: .bottomTrailing)
                .offset(x: -CP.pad * 0.6, y: -CP.pad * 0.7)
        }
    }
}
