import SwiftUI

// MARK: - สำรับบรรณาธิการ
//
// # แปดใบนี้มาจากไหน
//
// แปลงตรงจากแผ่นตัวอย่างแปดใบที่เจ้าของการ์ดส่งมา (โพลารอยด์ติดกำแพง · ประโยคไฮไลต์ ·
// ปกซีน · หน้า about me ตัวแดง · บอร์ดรูปติดหมุด · ประโยคขายงาน · การ์ดขั้นตอน ·
// ชื่อยักษ์หลังภาพ) — **ผัง สัดส่วน วัสดุ และสี ตามต้นฉบับ · ตัวอักษรใช้ฟอนต์ของแอป**
// (กติกาเดิมจากรอบเทมเพลต STAR CARD: ดีไซน์มาจากข้างนอก แต่การ์ดทั้งใบต้องพูดฟอนต์เดียวกัน)
//
// # สิ่งที่ทำให้สำรับนี้ต่างจากสำรับอื่นทั้งตู้
//
// widget ตัวอื่นเป็น *ป้ายของข้อมูล* — ตัวอักษรบนมันคือชื่อ ยอดวิว เบอร์โทร ซึ่งมีคำตอบเดียว
// ต่อการ์ดหนึ่งใบ จึงอ่านจากคลังข้อมูลกลางได้ตรง ๆ
//
// สำรับนี้กลับกัน: **ตัวอักษรคือผัง** — "ลงมือทำแล้วได้ / ชัดเจน. / ไม่ใช่คิดไปเอง" ไม่ใช่
// ข้อเท็จจริงของใคร มันคือของตกแต่งที่มีตัวอักษร เหมือนก้อนข้อความ (`textBlock`)
// ทุกก้อนจึงเก็บ **ต่อชิ้น** ด้วย `ProfileField.note` + `index` (ดู `TextSlotID.preset`)
// วางใบเดียวกันสองที่แล้วพิมพ์คนละเรื่องได้ ซึ่งเป็นการใช้งานปกติของแผ่นแบบนี้
//
// และเพราะมันคือผัง **ค่าตั้งต้นจึงเดินทางมากับช่อง** ไม่ใช่มากับคลังข้อมูล — หยิบออกจากตู้
// แล้วต้องเห็นแผ่นที่จัดเสร็จแล้ว ไม่ใช่กรอบเปล่าที่ต้องเดาว่าตรงไหนพิมพ์อะไร
//
// # ช่องรูปทุกช่องอัปโหลดได้
//
// ทุกกรอบรูปประกาศ `.photoSlot(n)` — ชั้นการ์ดแปะปุ่มเปลี่ยนรูปให้เองตามกรอบที่ประกาศไว้
// เลขช่องไม่ซ้ำกันในใบเดียวกัน (ดู `PhotoStore.perWidget`) · ช่อง 1–3 เป็นช่อง "รูปคน"
// ซึ่งรับรูปโปรไฟล์จากหน้า ข้อมูลของฉัน มาเป็นค่าตั้งต้น (ดู `PhotoLib.isProfileSlot`)

// MARK: - จานสีและวัสดุร่วม

/// สีของสำรับ — **คงที่ ไม่ล้อธีมการ์ด** เพราะแต่ละใบคือแผ่นกระดาษที่มีสีของตัวเอง
/// (ครีม · เทาอ่อน · เบจ) การย้อมตามธีมเมื่อไหร่ ความเปรียบต่างที่ดีไซน์จูนมาก็หายทันที
enum Ed {
    static let cream = Color(red: 0.961, green: 0.949, blue: 0.929)
    static let creamWarm = Color(red: 0.949, green: 0.918, blue: 0.859)
    static let paper = Color(red: 0.937, green: 0.933, blue: 0.925)
    static let beige = Color(red: 0.906, green: 0.886, blue: 0.839)

    static let ink = Color(red: 0.105, green: 0.105, blue: 0.110)
    static let inkSoft = Color(red: 0.365, green: 0.357, blue: 0.345)
    static let brown = Color(red: 0.239, green: 0.188, blue: 0.161)
    static let red = Color(red: 0.647, green: 0.161, blue: 0.129)

    /// น้ำเงินปากกาเมจิกของชื่อใต้โพลารอยด์
    static let marker = Color(red: 0.145, green: 0.290, blue: 0.776)
    /// หมุดสีบนหัวโพลารอยด์ — แดง เหลือง น้ำเงิน วนตามต้นฉบับ
    static let pinRed = Color(red: 0.878, green: 0.192, blue: 0.153)
    static let pinYellow = Color(red: 0.965, green: 0.773, blue: 0.094)
    static let pinBlue = Color(red: 0.231, green: 0.510, blue: 0.878)

    /// แถบไฮไลต์ชมพูกับหมุดจับของประโยคเดี่ยว (ภาษาเดียวกับกล่องเลือกใน Figma)
    static let highlightPink = Color(red: 0.906, green: 0.780, blue: 0.855)
    static let handlePink = Color(red: 0.788, green: 0.404, blue: 0.639)
    /// แถบไฮไลต์ม่วงอ่อนกับหมุดน้ำเงินของประโยคขายงาน
    static let highlightIris = Color(red: 0.725, green: 0.725, blue: 0.941)
    static let handleIris = Color(red: 0.188, green: 0.208, blue: 0.808)
    /// วงกลมเลขลำดับบนการ์ดขั้นตอน
    static let stepPink = Color(red: 0.937, green: 0.827, blue: 0.914)

    /// ขนาดตัวอักษรที่ทำให้ข้อความ **กว้างเท่าที่สั่ง** — หัวใจของหัวเรื่องแบบบรรณาธิการ
    ///
    /// หัวเรื่องของสำรับนี้ไม่ใช่ "ตัวอักษรขนาดหนึ่งที่บังเอิญยาว" แต่คือ *แถบที่กินเต็มความกว้าง*
    /// ถ้าตั้งขนาดตายตัว คำสั้นจะเหลือที่ว่างครึ่งแผ่น (แล้วผังพัง) ส่วนคำยาวจะถูกย่อจนจิ๋ว
    /// ที่นี่จึงวัดที่ 100pt ครั้งเดียวแล้วเทียบบัญญัติไตรยางศ์ — ความกว้างของตัวอักษรเป็นเชิงเส้นกับขนาด
    static func fitted(_ text: String, weight: Font.Weight, face: CardFont = .noto,
                       width: CGFloat, cap: CGFloat, floor: CGFloat = 10) -> CGFloat {
        let probe: CGFloat = 100
        let w = TextFit.metrics(text, face: face, weight: weight, size: probe, align: .center).ink.width
        guard w > 1 else { return cap }
        return max(floor, min(cap, probe * width / w))
    }
}

/// วัสดุของใบหนึ่งใบ — เปลี่ยนทั้งชุดเมื่อผู้ใช้ปิดพื้น (`WidgetSurface.clear`)
///
/// # ทำไมต้องมีชุดสีที่สอง
///
/// สำรับนี้ถูกออกแบบเป็น **หมึกเข้มบนกระดาษอ่อน** ทุกใบ — ครีม เทา เบจ
/// พอผู้ใช้ปิดพื้นเพราะไม่อยากได้กรอบ กระดาษหายไปแต่ตัวอักษรยังเป็นถ่าน
/// บนการ์ดมืดมันจึงหายไปทั้งใบ ซึ่งอ่านเป็น "ปิดพื้นแล้วแอปพัง" ไม่ใช่ "ปิดพื้นแล้วไม่มีกรอบ"
///
/// ที่นี่จึงตอบสองอย่างพร้อมกัน: พื้นเป็นสีอะไร และ **หมึกต้องเป็นของใคร** —
/// มีพื้น = หมึกของกระดาษใบนั้น · ไม่มีพื้น = หมึกของการ์ด (พลิกตามธีมให้เอง)
struct EdSkin {
    /// พื้นกระดาษของใบ — `.clear` เมื่อปิดพื้น
    var sheet: Color
    /// ยังมีกระดาษรองอยู่ไหม — เกล็ดกระดาษ เงา และเส้นขอบอ่านค่านี้ก่อนวาด
    var papered: Bool
    var ink: Color
    var inkSoft: Color
    /// ตัวอักษรที่เป็นฉากหลัง (คำยักษ์หลังภาพ)
    var ghost: Color
    /// น้ำเงินปากกาเมจิก — บนการ์ดมืดต้องสว่างขึ้น ไม่งั้นชื่อจมหายไปกับพื้น
    var marker: Color
    /// แดงหัวเรื่อง — เหตุผลเดียวกัน
    var red: Color
}

extension Ed {
    /// # สีเน้นมาจาก **ธีมของการ์ด** ไม่ใช่น้ำเงิน/แดงตายตัวของต้นฉบับอีกแล้ว
    ///
    /// ต้นฉบับแต่ละใบมีปากกาของมันเอง (น้ำเงินเมจิก · แดงหัวเรื่อง) ซึ่งถูกตอนอยู่บนกระดาษใบนั้น
    /// แต่บนการ์ดที่เจ้าของเลือกพาเลตต์เองได้ มันกลายเป็น *สีที่ไม่มีที่มา* — การ์ดโทนเขียว
    /// ที่มีชื่อสีน้ำเงินอ่านเป็นของที่หลงมาจากไฟล์อื่น ไม่ใช่ของที่ถูกออกแบบมาด้วยกัน
    ///
    /// ตอนนี้จึงเป็น **สีเน้นของธีม** ที่ถูกปรับความสว่างตามพื้นที่มันนั่งอยู่จริง
    /// (กระดาษสว่าง → เฉดเข้มของสีนั้น · การ์ดมืด → เฉดสดของสีนั้น) เฉดไม่เปลี่ยน เปลี่ยนแค่ความสว่าง
    /// `theme` เป็น optional ไว้ให้พรีวิวที่ไม่มีธีมยังเรียกได้ — ตกกลับไปใช้ปากกาของต้นฉบับ
    static func skin(_ surface: WidgetSurface, paper: Color, ink: InkStyle,
                     theme: CardTheme? = nil, ghostOnPaper: Color = .white) -> EdSkin {
        if surface == .pane {
            // บนกระจกของ chrome — กระดาษใส ผังเดิมทั้งชุด หมึกเป็นหมึกของการ์ด
            let onGlass = theme?.accent
            return EdSkin(sheet: .clear, papered: true,
                          ink: ink.text(0.95), inkSoft: ink.text(0.55),
                          ghost: ink.ghost(0.14),
                          marker: onGlass ?? Ed.marker, red: onGlass ?? Ed.red)
        }
        guard surface == .clear else {
            // # การ์ดคู่สี — แผ่นของสำรับนี้ต้องเป็น **สีเข้มของคู่** เหมือนโปสเตอร์สายงาน
            //
            // กระดาษครีมของต้นฉบับเป็นสีที่ถูกเลือกไว้ตั้งแต่ก่อนมีคู่สี พอการ์ดทั้งใบเป็นงานสองสี
            // (กรมท่าบนเนย) ครีมกลายเป็นสีที่สามที่ไม่มีใครเลือก — และเป็นสีเดียวในหน้าที่ไม่ใช่
            // ของคู่ ตาจับได้ทันทีว่าใบนี้หลงมาจากงานอื่น (เจ้าของการ์ดเห็นก่อนใครด้วยซ้ำ)
            //
            // แผ่นจึงใช้สูตรกลางของตู้ (`PosterPlate`) ตัวเดียวกับโปสเตอร์สายงาน · หมึกทุกระดับ
            // เป็นสีอ่อนของคู่ · ของที่เป็น *กระดาษจริง* บนแผ่น (โพลารอยด์ การ์ดขั้นตอน เศษข่าว)
            // ยังขาวเหมือนเดิม เพราะมันคือของที่วางอยู่บนแผ่น ไม่ใช่ตัวแผ่น
            if theme?.activeDuo != nil, let theme {
                let plate = PosterPlate.plate(theme)
                let ink = PosterPlate.cream(theme)
                return EdSkin(sheet: plate, papered: true,
                              ink: ink, inkSoft: ink.mixed(with: plate, by: 0.38),
                              ghost: ink.opacity(0.16),
                              marker: ink, red: ink)
            }
            let onPaper = theme?.rawAccent.onLightSurface()
            return EdSkin(sheet: paper, papered: true, ink: Ed.ink, inkSoft: Ed.inkSoft,
                          ghost: ghostOnPaper,
                          marker: onPaper ?? Ed.marker, red: onPaper ?? Ed.red)
        }
        let light = ink.isLight
        // บนการ์ด `theme.accent` พลิกให้เองแล้วทั้งฝั่งกระดาษและฝั่งมืด
        let onCard = theme?.accent
        return EdSkin(sheet: .clear, papered: false,
                      ink: ink.text(0.95), inkSoft: ink.text(0.6),
                      ghost: ink.ghost(0.22),
                      marker: onCard ?? (light ? Ed.marker : Color(red: 0.573, green: 0.714, blue: 1)),
                      red: onCard ?? (light ? Ed.red : Color(red: 0.980, green: 0.451, blue: 0.376)))
    }
}

/// เกล็ดกระดาษ — จุดเล็กสุ่มแบบ **เมล็ดคงที่** จึงไม่กระพริบตอนวาดใหม่
///
/// แผ่นสีเรียบล้วนที่ขนาด 366pt อ่านเป็นไฟล์ PNG ที่ถูกย่อ ไม่ใช่กระดาษ —
/// จุดจาง ๆ ชั้นเดียวคือสิ่งที่ทำให้พื้นมีผิว โดยไม่ต้องแบกรูปพื้นผิวเข้าแอป
struct EdGrain: View {
    var count: Int = 420
    var opacity: Double = 0.05
    var tint: Color = .black

    var body: some View {
        Canvas { ctx, size in
            var seed: UInt64 = 0x9E3779B97F4A7C15
            func rnd() -> CGFloat {
                seed ^= seed << 13
                seed ^= seed >> 7
                seed ^= seed << 17
                return CGFloat(seed % 10_000) / 10_000
            }
            for _ in 0..<count {
                let x = rnd() * size.width
                let y = rnd() * size.height
                let d = 0.6 + rnd() * 1.1
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: d, height: d)),
                         with: .color(tint.opacity(opacity * (0.4 + Double(rnd()) * 0.6))))
            }
        }
        .allowsHitTesting(false)
    }
}

/// จุดฮาล์ฟโทน — ตารางจุดบนปกซีน (ผิวของงานพิมพ์ ไม่ใช่ฟิลเตอร์เบลอ)
struct EdHalftone: View {
    var step: CGFloat = 5
    var dot: CGFloat = 1.5
    var opacity: Double = 0.16

    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = row.isMultiple(of: 2) ? 0 : step / 2
                while x < size.width {
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: dot, height: dot)),
                             with: .color(.white.opacity(opacity)))
                    x += step
                }
                y += step
                row += 1
            }
        }
        .allowsHitTesting(false)
    }
}

/// ข้อความอิสระหนึ่งก้อนของสำรับนี้ — ค่าตั้งต้นของดีไซน์ + ช่องแก้ที่ชั้นการ์ด
///
/// ทุกก้อนตัวอักษรในไฟล์นี้ผ่านตัวนี้ตัวเดียว จึงไม่มีทางมีก้อนไหนที่ "แก้ไม่ได้"
/// หลุดไปโดยไม่มีใครเห็น — ถ้าเห็นตัวอักษรบนแผ่น แปลว่าแตะแล้วพิมพ์ทับได้เสมอ
struct EdText: View {
    let slot: Int
    let preset: String
    let hint: String
    var style: TextSlotStyle
    var lines: Int = 1
    var minScale: CGFloat = 0.62

    @Environment(\.widgetID) private var wid
    /// หน้าตาที่เจ้าของการ์ดตั้งให้ช่องนี้ — ตัวนี้ตั้งฟอนต์/สีให้ `Text` เอง จึงต้องปรับสไตล์ก่อนวาด
    @Environment(\.widgetTextStyle) private var tune
    @Environment(\.cardInk) private var ink
    @Environment(\.cardAccent) private var accent

    var body: some View {
        let raw = Profile.me.note(wid, slot, preset: preset)
        let tuned = style.tuned(by: tune,
                                slot: TextSlotID(field: .note, index: slot, widget: wid),
                                ink: ink, accent: accent)
        return Text(style.uppercase ? raw.uppercased() : raw)
            .kerning(tuned.tracking)
            .lineSpacing(tuned.lineSpacing)
            .foregroundStyle(tuned.color)
            .multilineTextAlignment(style.align)
            .lineLimit(lines)
            .minimumScaleFactor(minScale)
            .fixedSize(horizontal: false, vertical: true)
            // สไตล์ของดีไซน์ ไม่ใช่ตัวที่ปรับแล้ว — ตัวประกาศช่องปรับให้เองอีกชั้น
            .editableText(.note, index: slot, widget: wid, preset: preset, hint: hint, style)
    }
}

/// ช่องรูปหนึ่งช่องของสำรับนี้ — เต็มกรอบเสมอ · ขาวดำได้ · ประกาศช่องให้ปุ่มเปลี่ยนรูป
struct EdPhoto: View {
    let slot: Int
    var mono: Bool = false
    var depth: CGFloat = 10

    @Environment(\.pageScrub) private var scrub

    var body: some View {
        Color.clear
            .overlay {
                WidgetPhoto(index: slot)
                    .aspectRatio(contentMode: .fill)
                    .grayscale(mono ? 1 : 0)
                    .scrubDolly(scrub.d, shift: depth, zoom: 0.12)
            }
            .clipped()
            .photoSlot(slot)
    }
}

/// วางของหนึ่งชิ้นด้วยพิกัด **สัดส่วน** ของแผ่น (0…1) แล้วเอียงตามองศาที่ดีไซน์กำหนด
///
/// ผังของสำรับนี้มาจากรูปที่มีสัดส่วนของตัวเอง — เก็บเป็นสัดส่วนไว้ ผู้ใช้ยืดกรอบแล้ว
/// ของทุกชิ้นยังอยู่ตำแหน่งเดิมของมันในผัง ไม่ใช่กองรวมกันที่มุมใดมุมหนึ่ง
///
/// ส่งองศาลง `slotTilt` ด้วย — กรอบเส้นประของช่องข้อความข้างในจะได้เอียงตามแผ่น
struct EdPlace<Content: View>: View {
    let x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
    let size: CGSize
    var tilt: Double = 0
    var align: Alignment = .top
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(width: max(1, w * size.width), height: max(1, h * size.height),
                   alignment: align)
            .environment(\.slotTilt, tilt)
            .rotationEffect(.degrees(tilt))
            .position(x: (x + w / 2) * size.width, y: (y + h / 2) * size.height)
    }
}

/// หมุดจับของกล่องไฮไลต์ — เส้นตั้งที่ขอบกล่อง + จุดกลมที่ปลาย
///
/// สองใบที่เป็นประโยคเดี่ยวยืมภาษาของเครื่องมือออกแบบมาเล่า: คำที่ถูกเน้นคือคำที่
/// "ถูกเลือกอยู่" ไม่ใช่คำที่ถูกทาสี — หมุดจับคือสิ่งเดียวที่ทำให้อ่านออกแบบนั้น
struct EdSelectionHandles: View {
    let tint: Color
    var dot: CGFloat = 9
    var line: CGFloat = 1.4

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                Rectangle().fill(tint).frame(width: line, height: h)
                Circle().fill(tint).frame(width: dot, height: dot)
                    .offset(x: -(dot - line) / 2, y: h - dot / 2)
            }
            .frame(width: geo.size.width, height: h, alignment: .topLeading)
            .overlay(alignment: .topTrailing) {
                ZStack(alignment: .topTrailing) {
                    Rectangle().fill(tint).frame(width: line, height: h)
                    Circle().fill(tint).frame(width: dot, height: dot)
                        .offset(x: (dot - line) / 2, y: -dot / 2)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 1 · กำแพงโพลารอยด์

/// ฟิล์มแปะกระจายบนผนังครีม · **ชื่อแบรนด์ทับขอบล่างของใบ · ยอดวิวกับ ER อยู่ใต้ใบ**
///
/// # หนึ่งใบ = ผลงานหนึ่งชิ้น ไม่ใช่คนหนึ่งคน
///
/// รอบแรกผนังนี้เป็นทีมงานห้าคน (ชื่อเล่น · ไอจี · สายงาน) ตามต้นฉบับที่เป็นหน้า "ทีมของเรา"
/// แต่การ์ดใบหนึ่งมีเจ้าของคนเดียว — กำแพงที่มีหน้าคนอื่นห้าคนจึงตอบคำถามที่ไม่มีใครถาม
/// ตอนนี้แต่ละใบคือผลงานที่แพลตฟอร์มยืนยันแล้ว: รูปงาน · ชื่อแบรนด์ที่จ้าง · ผลที่ได้
///
/// # สามอย่างที่ทำให้มันเป็น "กำแพง" ไม่ใช่ "ตารางรูป"
///
/// 1. **ใบเหลื่อมกัน** — ขอบใบล่างกินเข้าไปในใบบน คนแปะรูปไม่ได้วัดระยะ
/// 2. **องศาไม่ซ้ำกันสักใบ** และไม่มีใบไหนตรง 0°
/// 3. **ชื่ออยู่บนผนัง ไม่ได้อยู่บนฟิล์ม** — เขียนทับกระดาษรอง ไม่ใช่แคปชันในกรอบ
///
/// หมุดกลมสีบนหัวใบคือตัวที่บอกว่ามันถูก *แปะ* ไว้ ไม่ใช่ถูกวางลงในช่องของผัง
///
/// # ท่าเปลี่ยนหน้า
///
/// ใบทยอยล้มลงตามลำดับที่กลับด้านเองตามทิศ (`Scrub.lead`) — เหมือนลมพัดผ่านกำแพง
struct WallPolaroid: View {
    let theme: CardTheme
    let size: CGSize

    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var cardInk

    private var skin: EdSkin { Ed.skin(surface, paper: Ed.cream, ink: cardInk, theme: theme) }

    /// ที่แปะของใบหนึ่งใบบนผนัง — x/y/w/h เป็นสัดส่วนของแผ่น
    private struct Spot {
        let x, y, w, h: CGFloat
        let tilt: Double
        let pin: Color
    }

    /// ผังของผนัง **ตามจำนวนผลงานที่มีจริง**
    ///
    /// # ทำไมไม่ใช้ผังห้าใบใบเดียวแล้ววนของซ้ำให้ครบ
    ///
    /// เพราะสองใบที่เขียนชื่อแบรนด์เดียวกันพร้อมยอดวิวชุดเดียวกันไม่ได้อ่านเป็น "ผลงานสองชิ้น"
    /// มันอ่านเป็นบั๊ก · และกำแพงที่มีช่องโหว่ตรงมุมก็อ่านเป็นของที่โหลดไม่ครบ
    /// ผังจึงต้องรู้จักจำนวนจริง แล้วจัดใบให้เต็มหน้าเสมอไม่ว่าจะมีสามชิ้นหรือห้าชิ้น
    ///
    /// ทุกผังรักษากติกาเดิมของกำแพงไว้ครบ: ไม่มีใบไหนตรง 0° · องศาไม่ซ้ำกัน ·
    /// แถวบนจบก่อนแถวล่างเริ่ม (ชื่อที่ถูกใบอื่นทับคือชื่อที่อ่านไม่ได้)
    private static func spots(_ n: Int) -> [Spot] {
        switch n {
        case 0, 1:
            return [.init(x: 0.300, y: 0.120, w: 0.400, h: 0.700, tilt: -2.0, pin: Ed.pinRed)]
        case 2:
            return [.init(x: 0.070, y: 0.140, w: 0.360, h: 0.620, tilt: -2.6, pin: Ed.pinRed),
                    .init(x: 0.545, y: 0.175, w: 0.360, h: 0.620, tilt: 2.4, pin: Ed.pinYellow)]
        case 3:
            return [.init(x: 0.150, y: 0.005, w: 0.345, h: 0.470, tilt: -2.6, pin: Ed.pinRed),
                    .init(x: 0.520, y: 0.015, w: 0.350, h: 0.470, tilt: 2.4, pin: Ed.pinYellow),
                    .init(x: 0.325, y: 0.520, w: 0.345, h: 0.470, tilt: -2.2, pin: Ed.pinBlue)]
        case 4:
            return [.init(x: 0.075, y: 0.005, w: 0.345, h: 0.470, tilt: -2.6, pin: Ed.pinRed),
                    .init(x: 0.555, y: 0.015, w: 0.350, h: 0.470, tilt: 2.4, pin: Ed.pinYellow),
                    .init(x: 0.075, y: 0.505, w: 0.345, h: 0.470, tilt: -3.0, pin: Ed.pinBlue),
                    .init(x: 0.555, y: 0.520, w: 0.345, h: 0.470, tilt: 2.2, pin: Ed.pinRed)]
        default:
            return [.init(x: 0.165, y: 0.005, w: 0.345, h: 0.470, tilt: -2.6, pin: Ed.pinRed),
                    .init(x: 0.515, y: 0.015, w: 0.350, h: 0.470, tilt: 2.4, pin: Ed.pinYellow),
                    .init(x: 0.040, y: 0.505, w: 0.330, h: 0.470, tilt: -3.4, pin: Ed.pinYellow),
                    .init(x: 0.360, y: 0.530, w: 0.315, h: 0.470, tilt: 2.8, pin: Ed.pinBlue),
                    .init(x: 0.655, y: 0.525, w: 0.330, h: 0.470, tilt: -1.8, pin: Ed.pinRed)]
        }
    }

    var body: some View {
        // ห้าชิ้นล่าสุดพอสำหรับผนังหนึ่งบาน — ที่เหลืออยู่ในใบ "ผลงานยืนยัน" แบบอื่นของตระกูล
        let works = Array(Profile.me.shownTrack(.verified).works.prefix(5))
        let spots = Self.spots(works.count)
        return ZStack(alignment: .topLeading) {
            skin.sheet
            PlatePatternLayer(sheet: skin.sheet)
            if skin.papered { EdGrain(count: 380, opacity: 0.05) }

            ForEach(Array(works.enumerated()), id: \.offset) { i, work in
                let s = spots[min(i, spots.count - 1)]
                EdPlace(x: s.x, y: s.y, w: s.w, h: s.h, size: size, tilt: s.tilt) {
                    card(s, work: work, i: i, of: works.count)
                        .linkSlot(work.postURL)
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func card(_ c: Spot, work: VerifiedWork, i: Int, of n: Int) -> some View {
        let lead = Scrub.lead(i, of: n, d: scrub.d, step: 0.1)
        // **ช่องฟิล์มเป็นแนวตั้ง 4:5 เสมอ** ไม่ใช่เศษส่วนของความสูงช่อง —
        // ฟิล์มโพลารอยด์จริงเป็นทรงตั้ง ถ้าปล่อยให้ความสูงช่องเป็นคนกำหนด
        // ใบจะกลายเป็นทรงนอนทันทีที่ผู้ใช้ลดความสูงของ widget แล้วมันเลิกเป็นโพลารอยด์
        let w = c.w * size.width
        let rim = max(4, w * 0.055)
        let nameSize = max(12, min(23, w * 0.17))
        // **ย่อทั้งใบให้พอดีช่อง ไม่ใช่ปล่อยให้ล้น**
        //
        // ความสูงของฟิล์มมาจาก *ความกว้าง* (โพลารอยด์เป็นทรงตั้ง 4:5 เสมอ) ส่วนช่องที่ใบนี้ได้
        // มาจาก *ความสูงของ widget* — พอผู้ใช้ลากย่อความสูง สองค่านั้นเลิกสัมพันธ์กันทันที
        // ใบจะยื่นพ้นช่องลงไปทับใบแถวล่าง แล้วทั้งกำแพงกลายเป็นกองที่ชนกัน
        //
        // ย่อทั้งใบตามสัดส่วน (ไม่ใช่บีบเฉพาะความสูง) — โพลารอยด์ยังเป็นโพลารอยด์
        // แค่เป็นใบที่เล็กลง ซึ่งเป็นสิ่งที่ตาคาดหวังเวลาลากย่อของทั้งกอง
        // ระยะที่ชื่อ **ห้อยพ้นขอบล่างของใบ** — บรรทัดแรกนั่งบนขอบขาว บรรทัดที่สองอยู่นอกใบ
        let hang = nameSize * 0.95
        let natural = (w - rim * 2) * 1.25 + rim * 2.8 + hang + nameSize * 0.35 + 24
        let fit = min(1, c.h * size.height / max(natural, 1))
        return VStack(spacing: 0) {
            film(c, work: work, rim: rim)
                // ขอบขาวล่างหนากว่าอีกสามด้าน — โพลารอยด์จริงเป็นแบบนั้น
                // และนั่นคือที่ที่ชื่อไปนั่งทับ ถ้าขอบบาง ชื่อจะไปนอนบนหน้าคนแทน
                .frame(height: (w - rim * 2) * 1.25 + rim * 2.8)
                .overlay(alignment: .bottom) { brandName(work.brand, size: nameSize, w: w) }
            // ที่ว่างสำหรับครึ่งล่างของชื่อที่ห้อยออกมา — overlay ไม่กินที่ในผัง ต้องกันเอง
            Spacer(minLength: 0).frame(height: hang + nameSize * 0.35)
            meta(work)
            Spacer(minLength: 0)
        }
        .scaleEffect(fit, anchor: .top)
        .scrubLouver(scrub.d, lead: lead, angle: 44, shrink: 0.1)
    }

    private func film(_ c: Spot, work: VerifiedWork, rim: CGFloat) -> some View {
        Group {
            if let cover = work.cover {
                Image(cover).resizable().aspectRatio(contentMode: .fill)
            } else {
                EdPhoto(slot: work.photo, depth: 8)
            }
        }
            .padding(rim)
            .padding(.bottom, rim * 0.5)
            .background(Color.white)
            .overlay(Rectangle().strokeBorder(Color.black.opacity(0.06), lineWidth: 0.6))
            .shadow(color: .black.opacity(0.16), radius: 7, y: 4)
            // หมุดกลมคาบขอบบนของใบ — ครึ่งบนอยู่บนผนัง ครึ่งล่างอยู่บนฟิล์ม
            .overlay(alignment: .top) {
                Circle().fill(c.pin)
                    .frame(width: 11, height: 11)
                    .shadow(color: .black.opacity(0.22), radius: 2, y: 1)
                    .offset(y: -9)
            }
    }

    /// ชื่อตัวใหญ่ที่ **คาบขอบล่างของฟิล์ม** — ไม่ใช่บรรทัดที่นั่งเรียบร้อยอยู่ใต้ใบ
    ///
    /// # นี่คือข้อที่ทำให้ผังนี้เป็นกำแพงรูป ไม่ใช่ตารางรายชื่อ
    ///
    /// รอบแรกชื่ออยู่ *ใต้* ฟิล์มทั้งก้อน ทุกใบจึงกลายเป็นการ์ดพนักงาน: รูปหนึ่งช่อง
    /// ตัวหนังสือหนึ่งช่อง เรียงกันเป็นตาราง — ซึ่งอ่านง่ายแต่ไม่มีอะไรเป็นงานออกแบบเลย
    ///
    /// ต้นฉบับวางชื่อ **ทับลงบนใบ** และปล่อยให้มันยื่นพ้นขอบทั้งด้านล่างและด้านข้าง
    /// สองอย่างนั้นคือสิ่งเดียวที่ทำให้ตาอ่านว่าชื่อกับรูปเป็น *ของชิ้นเดียวกัน* ที่ถูกแปะไว้
    /// ไม่ใช่ข้อความที่บังเอิญอยู่ใต้รูป · กว้างเกินใบราว 16% พอให้รู้สึกว่าล้น
    /// แต่ไม่มากจนไปชนชื่อของใบข้าง ๆ
    ///
    /// เงาขาวจาง ๆ ไม่ใช่ของตกแต่ง — บรรทัดแรกนั่งอยู่บนขอบขาว แต่ตัวที่ยื่นเลยขอบใบไปอยู่บน
    /// *พื้นหลังการ์ด* ซึ่งจะมืดหรือสว่างก็ได้ เงานั้นคือสิ่งที่กันไม่ให้ชื่อหายไปครึ่งบรรทัด
    private func brandName(_ brand: String, size s: CGFloat, w: CGFloat) -> some View {
        Text(brand)
            .font(.sh(s, .black))
            .kerning(-s * 0.03)
            .foregroundStyle(skin.marker)
            .multilineTextAlignment(.center)
            .lineLimit(2).minimumScaleFactor(0.4)
            .frame(width: w * 1.16)
            .shadow(color: (skin.papered ? Color.white : cardInk.base).opacity(0.75),
                    radius: 2.5)
            .offset(y: s * 0.95)
    }

    /// สองบรรทัดใต้ชื่อแบรนด์ — **ผลของงาน แล้วค่อยชื่อแคมเปญ**
    ///
    /// เรียงแบบนี้เพราะคนที่เปิดการ์ดคือคนที่กำลังจะจ้าง เขาอ่าน "งานนี้ไปได้ไกลแค่ไหน" ก่อนเสมอ
    /// ส่วนชื่อแคมเปญคือของที่ช่วยจำว่างานไหน ไม่ใช่ของที่ใช้ตัดสินใจ
    ///
    /// ไม่มี `EdText` ในนี้แม้แต่บรรทัดเดียว — ตัวเลขชั้นหลักฐานเป็นของที่ระบบออกให้
    /// เปิดให้พิมพ์ทับเมื่อไหร่ มันก็เลิกเป็นหลักฐานทันที (กติกาเดียวกับทั้งชั้น `verified`)
    private func meta(_ work: VerifiedWork) -> some View {
        VStack(spacing: 1) {
            Text(work.views > 0 ? Fmt.compact(work.views) + " วิว · ER " + Fmt.pct(work.engagementRate) : "รอยอดจากระบบ")
                .font(.sh(7, .bold))
                .foregroundStyle(skin.ink.opacity(0.85))
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(work.campaign)
                .font(.sh(7, .medium))
                .foregroundStyle(skin.inkSoft)
                .lineLimit(2).minimumScaleFactor(0.6)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

/// สามเหลี่ยมหางฟองแชต
struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// ประกายสี่แฉก — ดวงใหญ่กับดวงเล็กคู่กันเสมอ (ดวงเดียวอ่านเป็นดาว ไม่ใช่ประกาย)
struct Sparkle: View {
    var tint: Color

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Star4().fill(tint).frame(width: s * 0.72, height: s * 0.72)
                    .offset(x: -s * 0.1, y: s * 0.06)
                Star4().fill(tint).frame(width: s * 0.38, height: s * 0.38)
                    .offset(x: s * 0.3, y: -s * 0.26)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct Star4: Shape {
    func path(in r: CGRect) -> Path {
        let c = CGPoint(x: r.midX, y: r.midY)
        let R = min(r.width, r.height) / 2
        let k = R * 0.30
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - R))
        p.addQuadCurve(to: CGPoint(x: c.x + R, y: c.y), control: CGPoint(x: c.x + k, y: c.y - k))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + R), control: CGPoint(x: c.x + k, y: c.y + k))
        p.addQuadCurve(to: CGPoint(x: c.x - R, y: c.y), control: CGPoint(x: c.x - k, y: c.y + k))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - R), control: CGPoint(x: c.x - k, y: c.y - k))
        p.closeSubpath()
        return p
    }
}

// MARK: - 3 · ปกผลงาน

/// ปกนิตยสาร/ซีนหนึ่งหน้า — รูปเต็มแผ่น · หัวเรื่องเซริฟคร่อมซ้ายขวา ·
/// แถบผลงานสี่ใบพาดกลาง · ชื่อย่อตัวยักษ์ปิดท้ายล่าง
///
/// # ทำไมหัวเรื่องต้องแยกเป็นสองก้อน
///
/// ต้นฉบับวาง "Brand" ชิดซ้ายและ "Identity" ชิดขวาโดยมีใบหน้าอยู่ตรงกลาง —
/// ถ้าเป็นข้อความก้อนเดียวที่จัดชิดขอบ คำที่สองจะเลื่อนตามความยาวคำแรกทันทีที่ผู้ใช้พิมพ์
/// แยกเป็นสองช่องแล้วแต่ละคำเกาะขอบของตัวเอง ช่องว่างตรงกลางจึงเป็นของผัง ไม่ใช่ของตัวอักษร
struct ZineCover: View {
    let theme: CardTheme
    let size: CGSize

    @Environment(\.pageScrub) private var scrub

    var body: some View {
        ZStack(alignment: .topLeading) {
            backdrop
            EdPlace(x: 0.055, y: 0.06, w: 0.89, h: 0.30, size: size) { head }
            EdPlace(x: 0, y: 0.455, w: 1, h: 0.26, size: size) { strip }
            EdPlace(x: 0.055, y: 0.775, w: 0.89, h: 0.205, size: size, align: .bottom) { footer }
        }
        .frame(width: size.width, height: size.height)
    }

    /// รูปพื้นเต็มแผ่น + ย้อมคราม + จุดฮาล์ฟโทน = ผิวของงานพิมพ์
    private var backdrop: some View {
        EdPhoto(slot: 2, depth: 14)
            .frame(width: size.width, height: size.height)
            // ย้อมครามหนัก ๆ แล้วลดความสดของภาพเดิมลง — ปกซีนคือ *งานพิมพ์สีเดียว*
            // ถ้าปล่อยสีจริงของรูปขึ้นมาแข่ง หัวเรื่องขาวกับตัวอักษรกำกับจะอ่านไม่ออกทันที
            .saturation(0.35)
            .overlay(Color(red: 0.173, green: 0.314, blue: 0.573).opacity(0.62).blendMode(.multiply))
            .overlay(Color(red: 0.208, green: 0.376, blue: 0.663).opacity(0.22).blendMode(.screen))
            .overlay(EdHalftone(step: 5, dot: 1.4, opacity: 0.16))
            .overlay(LinearGradient(colors: [.black.opacity(0.28), .clear, .black.opacity(0.34)],
                                    startPoint: .top, endPoint: .bottom))
    }

    private var head: some View {
        let title = min(40, size.width * 0.115)
        return VStack(alignment: .leading, spacing: size.height * 0.03) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                EdText(slot: 0, preset: "ผลงาน", hint: "หัวเรื่องซ้าย",
                       style: .init(size: title, weight: .medium, color: .white, tracking: -0.5))
                Spacer(minLength: 8)
                EdText(slot: 1, preset: "ที่ภูมิใจ", hint: "หัวเรื่องขวา",
                       style: .init(size: title, weight: .medium, color: .white,
                                    align: .trailing, tracking: -0.5))
            }
            .scrubVeil(scrub.d, lead: 0.2, drop: 30, pull: 12)

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: size.height * 0.018) {
                    EdText(slot: 2, preset: "โดย มินท์ ชนากานต์", hint: "บรรทัดผู้ทำ",
                           style: meta(9))
                    EdText(slot: 3, preset: "งานออกแบบตัวตนแบรนด์\nสายสตรีทแวร์ที่อบอุ่น",
                           hint: "คำอธิบายซ้าย", style: meta(7.5), lines: 3)
                }
                Spacer(minLength: 0)
                EdText(slot: 4, preset: "ครีเอเตอร์\nสายไลฟ์สไตล์", hint: "คำอธิบายขวา",
                       style: meta(7.5, align: .trailing), lines: 3)
            }
            .scrubVeil(scrub.d, lead: 0.08, drop: 22, pull: 16)
        }
    }

    /// ตัวอักษรกำกับแบบซีน — ตัวเล็ก ตัวใหญ่ทั้งหมด ระยะห่างกว้าง
    /// (ต้นฉบับใช้ฟอนต์ mono · แอปมีฟอนต์เดียว จึงใช้ระยะห่างเป็นตัวเล่าจังหวะแทน)
    private func meta(_ s: CGFloat, align: TextAlignment = .leading) -> TextSlotStyle {
        .init(size: s, weight: .semibold, color: .white.opacity(0.9), align: align,
              tracking: 1.4, lineSpacing: 2, uppercase: false)
    }

    /// แถบผลงานสี่ใบพาดกลางหน้า — **การ์ดแยกใบ ไม่ใช่ฟิล์มสตริปแถบเดียว**
    ///
    /// ต้นฉบับวางการ์ดคนละขนาดเรียงกันโดยมีช่องไฟคั่น และใบกลางเป็นกระดาษขาวที่สูงกว่าเพื่อน —
    /// ช่องไฟกับความสูงที่ไม่เท่ากันคือสิ่งเดียวที่ทำให้มันอ่านเป็น "กองงานที่ถูกวางเรียง"
    /// ถ้าชนกันหมดทุกใบ มันจะกลายเป็นภาพเดียวที่ถูกตัดเป็นท่อน
    private var strip: some View {
        HStack(alignment: .center, spacing: size.width * 0.014) {
            tile(4, w: 0.215, h: 0.80, tilt: -1.5, white: false)
            tile(5, w: 0.245, h: 0.95, tilt: 1, white: false)
            tile(6, w: 0.275, h: 1.0, tilt: 0, white: true)
            tile(7, w: 0.235, h: 0.86, tilt: -1, white: false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tile(_ slot: Int, w: CGFloat, h: CGFloat, tilt: Double, white: Bool) -> some View {
        let lead = Double(slot - 4) * 0.07
        let r: CGFloat = 7
        return EdPhoto(slot: slot, depth: 6)
            .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
            .frame(width: w * size.width, height: h * size.height * 0.26)
            .padding(white ? 5 : 0)
            .background(
                RoundedRectangle(cornerRadius: white ? r + 3 : r, style: .continuous)
                    .fill(white ? Color.white : Color.clear)
            )
            .shadow(color: .black.opacity(0.32), radius: 9, y: 5)
            .rotationEffect(.degrees(tilt))
            .scrubLouver(scrub.d, lead: lead, angle: 50, shrink: 0.12)
    }

    private var footer: some View {
        VStack(spacing: 4) {
            HStack {
                EdText(slot: 5, preset: "salehere.co.th", hint: "บรรทัดล่างซ้าย",
                       style: .init(size: 9, weight: .medium, color: .white.opacity(0.92)))
                Spacer(minLength: 6)
                EdText(slot: 6, preset: "ผลงานที่คัดมา", hint: "บรรทัดล่างขวา",
                       style: .init(size: 9, weight: .medium, color: .white.opacity(0.92),
                                    align: .trailing))
            }
            EdText(slot: 7, preset: "STAR", hint: "ชื่อย่อตัวใหญ่",
                   style: .init(size: min(46, size.width * 0.135), weight: .black,
                                color: .white, align: .center, tracking: -1))
                .frame(maxWidth: .infinity)
                .scrubVeil(scrub.d, lead: 0.02, drop: 26, pull: 10)
        }
    }
}

// MARK: - 4 · หน้าแนะนำตัว

/// หัวเรื่องตัวแดงยักษ์สองบรรทัดบนกระดาษครีม · รูปมุมขวา · ย่อหน้าแนะนำตัวใต้หัวเรื่อง
///
/// เส้นตั้งบาง ๆ สองเส้นคือสิ่งที่ยึดหน้าไว้ด้วยกัน — เส้นหนึ่งห้อยลงมาจากขอบบนมาหยุดที่หัวเรื่อง
/// อีกเส้นห้อยจากหัวเรื่องลงไปหาย่อหน้า สายตาจึงเดินจากบนลงล่างตามเส้น ไม่ใช่กระโดดหาของที่ใหญ่สุด
///
/// ย่อหน้าอ่านจากช่อง **แนะนำตัว** ของโปรไฟล์ (`.about`) — ใบนี้กับ `แนะนำตัว`
/// จึงสลับกันได้โดยไม่มีข้อความไหนหาย ตามกติกาตระกูลใน `WidgetContent.swift`
struct AboutEditorial: View {
    let theme: CardTheme
    let size: CGSize

    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var cardInk

    private var skin: EdSkin { Ed.skin(surface, paper: Ed.creamWarm, ink: cardInk, theme: theme) }

    var body: some View {
        // หัวเรื่องกินเต็มคอลัมน์ซ้าย (65% ของแผ่น) — บรรทัดที่ยาวกว่าเป็นตัวกำหนดขนาดของทั้งคู่
        // ทั้งสองบรรทัดจึงสูงเท่ากันเสมอ เหมือนหัวเรื่องที่ถูกจัดด้วยมือ ไม่ใช่ตัวอักษรที่ยืดเอง
        let col = size.width * 0.63
        let lineA = Profile.me.note(widgetID, 0, preset: "เกี่ยวกับ")
        let lineB = Profile.me.note(widgetID, 1, preset: "ฉัน.")
        let big = min(Ed.fitted(lineA, weight: .black, width: col, cap: size.height * 0.26),
                      Ed.fitted(lineB, weight: .black, width: col, cap: size.height * 0.26))
        return ZStack(alignment: .topLeading) {
            skin.sheet
            PlatePatternLayer(sheet: skin.sheet)
            if skin.papered { EdGrain(count: 320, opacity: 0.05, tint: Ed.brown) }

            rules
            EdPlace(x: 0.055, y: 0.055, w: 0.66, h: 0.44, size: size, align: .topLeading) {
                title(big, a: lineA, b: lineB)
            }
            EdPlace(x: 0.575, y: 0.195, w: 0.385, h: 0.690, size: size) { portrait }
            EdPlace(x: 0.055, y: 0.620, w: 0.50, h: 0.350, size: size, align: .topLeading) {
                intro(big)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    @Environment(\.widgetID) private var widgetID

    /// เส้นตั้งสองเส้น — เส้นบนห้อยจากขอบแผ่นลงมาหยุดที่หัวเรื่อง
    /// เส้นล่างห้อยจากหัวเรื่องลงไปหาย่อหน้า สายตาจึงเดินตามเส้น ไม่ใช่กระโดดหาของที่ใหญ่สุด
    private var rules: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(skin.red.opacity(0.9))
                .frame(width: 1, height: size.height * 0.085)
                .offset(x: size.width * 0.545, y: 0)
            Rectangle().fill(skin.red.opacity(0.9))
                .frame(width: 1, height: size.height * 0.135)
                .offset(x: size.width * 0.235, y: size.height * 0.455)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private func title(_ big: CGFloat, a: String, b: String) -> some View {
        VStack(alignment: .leading, spacing: -big * 0.26) {
            EdText(slot: 0, preset: "เกี่ยวกับ", hint: "หัวเรื่องบรรทัดบน",
                   style: .init(size: big, weight: .black, color: skin.red, tracking: -big * 0.05))
            EdText(slot: 1, preset: "ฉัน.", hint: "หัวเรื่องบรรทัดล่าง",
                   style: .init(size: big, weight: .black, color: skin.red, tracking: -big * 0.05))
        }
        .scrubVeil(scrub.d, lead: 0.22, drop: 38, pull: 10)
    }

    private var portrait: some View {
        EdPhoto(slot: 1, depth: 10)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Ed.brown.opacity(0.18), radius: 10, y: 6)
            .scrubLouver(scrub.d, lead: 0.1, angle: 40, shrink: 0.1)
    }

    private func intro(_ big: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: size.height * 0.022) {
            EdText(slot: 2, preset: "ยินดีที่ได้รู้จัก!", hint: "หัวข้อย่อย",
                   style: .init(size: min(17, big * 0.30), weight: .bold, color: skin.ink,
                                tracking: -0.3))
            EditableParagraph(field: .about,
                              style: .init(size: 8.5, weight: .regular,
                                           color: skin.ink.opacity(0.85), lineSpacing: 2.8))
        }
        .scrubVeil(scrub.d, lead: 0.04, drop: 24, pull: 16)
    }
}

// MARK: - 5 · บอร์ดรูปติดหมุด

/// รูปใหญ่กลางบอร์ด · รูปเล็กห้าใบติดหมุดแดงรอบ ๆ · ลายมือคร่อมบนล่าง — รูปสีจริงทั้งบอร์ด
///
/// # ทำไมไม่ขาวดำ
///
/// รอบแรกบอร์ดนี้บังคับขาวดำเพื่อให้รูปหกใบที่ถ่ายคนละที่คนละเวลาอ่านเป็นชุดเดียวกัน
/// แต่มันแลกด้วยของที่แพงกว่านั้น: รูปของครีเอเตอร์คือสิ่งที่เขาเลือกมาอวด
/// การล้างสีทิ้งคือการเอาของที่เขาตั้งใจที่สุดออกไปเพื่อความเรียบร้อยของผัง
///
/// สิ่งที่มัดรูปหกใบให้เป็นชุดเดียวกันจึงเป็น *ของบนบอร์ด* ไม่ใช่การล้างสี:
/// ขอบกระดาษอัดรูปสีขาวเท่ากันทุกใบ · หมุดแดงดวงเดียวกัน · องศาเอียงคนละองศา
/// และพื้นกระดาษที่ทุกใบนอนอยู่บนมัน
struct WallMemory: View {
    let theme: CardTheme
    let size: CGSize

    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var cardInk

    private var skin: EdSkin { Ed.skin(surface, paper: Ed.paper, ink: cardInk, theme: theme) }

    /// รูปเล็กห้าใบรอบรูปใหญ่ (สัดส่วนของแผ่น)
    private struct Pin {
        let x, y, w, h: CGFloat
        let tilt: Double
        let slot: Int
    }

    /// ใบเล็กเบียดเข้าหาใบกลางจนขอบเหลื่อมกัน — ต้นฉบับไม่มีช่องไฟระหว่างใบเลย
    /// บอร์ดรูปคือของที่ถูกติดทับกันไปเรื่อย ๆ ไม่ใช่กริดที่เว้นระยะเท่ากัน
    private static let pins: [Pin] = [
        .init(x: 0.040, y: 0.225, w: 0.215, h: 0.205, tilt: -6, slot: 4),
        .init(x: 0.020, y: 0.500, w: 0.225, h: 0.215, tilt: 5, slot: 5),
        .init(x: 0.755, y: 0.215, w: 0.215, h: 0.210, tilt: 6, slot: 6),
        .init(x: 0.745, y: 0.480, w: 0.230, h: 0.220, tilt: -5, slot: 7),
        .init(x: 0.615, y: 0.680, w: 0.225, h: 0.205, tilt: 4, slot: 8),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            skin.sheet
            PlatePatternLayer(sheet: skin.sheet)
            if skin.papered { EdGrain(count: 340, opacity: 0.05) }

            EdPlace(x: 0.13, y: 0.055, w: 0.74, h: 0.10, size: size, tilt: -1.2) {
                EdText(slot: 0, preset: "เป็นครีเอเตอร์ในแบบของคุณ", hint: "ลายมือบรรทัดบน",
                       style: .init(size: min(17, size.width * 0.05), weight: .light,
                                    color: skin.ink, align: .center, tracking: 0.4))
                    .frame(maxWidth: .infinity)
                    .scrubVeil(scrub.d, lead: 0.26, drop: 18, pull: 10)
            }

            EdPlace(x: 0.215, y: 0.155, w: 0.575, h: 0.600, size: size, tilt: -0.8) { hero }

            ForEach(Array(Self.pins.enumerated()), id: \.offset) { i, p in
                EdPlace(x: p.x, y: p.y, w: p.w, h: p.h, size: size, tilt: p.tilt) {
                    snapshot(p, i: i)
                }
            }

            EdPlace(x: 0.16, y: 0.855, w: 0.70, h: 0.11, size: size, tilt: -3) {
                EdText(slot: 1, preset: "สิ่งที่อยากบอกตัวเองตอนเริ่มต้น", hint: "ลายมือบรรทัดล่าง",
                       style: .init(size: min(14, size.width * 0.042), weight: .light,
                                    color: skin.ink.opacity(0.9), align: .center, tracking: 0.3),
                       lines: 2)
                    .frame(maxWidth: .infinity)
                    .scrubVeil(scrub.d, lead: 0.02, drop: 18, pull: 12)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    /// รูปใหญ่กลางบอร์ด — กระดาษอัดรูปขอบหนา ไม่มีหมุด (มันถูก *วาง* ไว้ ส่วนใบเล็กถูก *ติด*)
    private var hero: some View {
        EdPhoto(slot: 1, depth: 12)
            .padding(7)
            .background(Color.white)
            .shadow(color: .black.opacity(0.12), radius: 9, y: 5)
            .scrubLouver(scrub.d, lead: 0.16, angle: 38, shrink: 0.08)
    }

    private func snapshot(_ p: Pin, i: Int) -> some View {
        let lead = Scrub.lead(i, of: Self.pins.count, d: scrub.d, step: 0.08)
        return EdPhoto(slot: p.slot, depth: 6)
            .padding(4)
            .background(Color.white)
            .shadow(color: .black.opacity(0.14), radius: 5, y: 3)
            .overlay(alignment: .topLeading) {
                Circle().fill(Ed.pinRed)
                    .frame(width: 8, height: 8)
                    .shadow(color: .black.opacity(0.28), radius: 1.5, y: 1)
                    .offset(x: 5, y: 5)
            }
            .scrubLouver(scrub.d, lead: lead, angle: 46, shrink: 0.12)
    }
}

// MARK: - 7 · การ์ดขั้นตอน

/// การ์ดขาวหกใบวางเฉียงทับกัน · แต่ละใบมีคำกำกับเล็ก ชื่อขั้นตอนตัวใหญ่ และเลขในวงกลม
/// ที่ห้อยอยู่ปลายเส้นบาง ๆ จากมุมบนขวาของใบ
///
/// # ทำไมเลขไม่ใช่ป้ายในการ์ด
///
/// ต้นฉบับแขวนเลขไว้ *นอก* การ์ดด้วยเส้นเดียว — เลขจึงอ่านเป็น "ลำดับของกระบวนการ"
/// ไม่ใช่ "หมายเลขของกล่อง" และเส้นที่ลากออกไปคือสิ่งที่ผูกหกใบให้เป็นเส้นทางเดียวกัน
/// ถ้าเอาเลขเข้าไปไว้ในการ์ด มันจะกลายเป็นการ์ดหกใบที่ไม่เกี่ยวกัน
struct FlowCards: View {
    let theme: CardTheme
    let size: CGSize

    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var cardInk

    /// การ์ดหกใบเป็นกระดาษขาวของมันเอง — ปิดพื้นแล้วหายแค่ *พื้นรอง* ไม่ใช่ตัวการ์ด
    /// ตัวอักษรบนการ์ดจึงเป็นถ่านเสมอ ไม่ต้องพลิกตามหมึกของการ์ด
    private var skin: EdSkin { Ed.skin(surface, paper: Ed.paper, ink: cardInk, theme: theme) }

    private struct Step {
        let x, y, w, h: CGFloat
        let tilt: Double
        let label: String
        let title: String
        let no: String
    }

    private static let steps: [Step] = [
        .init(x: 0.13, y: 0.035, w: 0.31, h: 0.205, tilt: -4,
              label: "ยินดีที่ได้รู้จัก", title: "ทำความรู้จัก", no: "1"),
        .init(x: 0.545, y: 0.095, w: 0.325, h: 0.200, tilt: 3,
              label: "เริ่มกันเลย", title: "เปิดโปรเจกต์", no: "2"),
        .init(x: 0.245, y: 0.300, w: 0.455, h: 0.215, tilt: -6,
              label: "ทุกอย่างเริ่มที่ไอเดีย", title: "วางคอนเซปต์", no: "3"),
        .init(x: 0.055, y: 0.560, w: 0.355, h: 0.205, tilt: 4,
              label: "ลงมือสร้าง", title: "ถ่ายทำ", no: "4"),
        .init(x: 0.585, y: 0.575, w: 0.345, h: 0.205, tilt: -3,
              label: "ส่งมอบ", title: "ตัดต่อ & ส่งงาน", no: "5"),
        .init(x: 0.275, y: 0.775, w: 0.330, h: 0.195, tilt: 5,
              label: "ยังไม่จบแค่นี้", title: "ดูแลต่อ", no: "6"),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            skin.sheet
            PlatePatternLayer(sheet: skin.sheet)
            if skin.papered { EdGrain(count: 280, opacity: 0.04) }

            ForEach(Array(Self.steps.enumerated()), id: \.offset) { i, s in
                EdPlace(x: s.x, y: s.y, w: s.w, h: s.h, size: size, tilt: s.tilt) {
                    card(s, i: i)
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func card(_ s: Step, i: Int) -> some View {
        let lead = Scrub.lead(i, of: Self.steps.count, d: scrub.d, step: 0.08)
        let big = min(21, s.w * size.width * 0.17)
        return VStack(alignment: .leading, spacing: 3) {
            EdText(slot: i, preset: s.label, hint: "คำกำกับขั้นที่ \(s.no)",
                   style: .init(size: 7, weight: .medium, color: Ed.inkSoft))
            EdText(slot: 6 + i, preset: s.title, hint: "ชื่อขั้นที่ \(s.no)",
                   style: .init(size: big, weight: .regular, color: Ed.ink, tracking: -0.5))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
        )
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
            .strokeBorder(Ed.ink.opacity(0.22), lineWidth: 0.7))
        .overlay(alignment: .topTrailing) { badge(s, i: i) }
        .scrubLouver(scrub.d, lead: lead, angle: 42, shrink: 0.1)
    }

    /// เลขในวงกลมที่ห้อยจากมุมบนขวาด้วยเส้นเฉียงเส้นเดียว
    private func badge(_ s: Step, i: Int) -> some View {
        let d: CGFloat = 19
        return ZStack {
            // เส้นห้อยอยู่บน *พื้นรอง* ไม่ใช่บนการ์ดขาว — ปิดพื้นแล้วมันต้องพลิกตามหมึกของการ์ด
            Rectangle().fill(skin.ink.opacity(0.45))
                .frame(width: 0.7, height: 26)
                .rotationEffect(.degrees(38))
                .offset(x: -9, y: 9)
            Circle().fill(Ed.stepPink)
                .frame(width: d, height: d)
                .overlay {
                    EdText(slot: 12 + i, preset: s.no, hint: "เลขขั้นที่ \(s.no)",
                           style: .init(size: 9, weight: .semibold, color: Ed.ink, align: .center))
                }
        }
        .offset(x: d * 0.45, y: -d * 0.45)
    }
}

// MARK: - 8 · ชื่อหลังภาพ

/// คำยักษ์สีขาวพาดเต็มความกว้าง โดยมีภาพตัดขาวดำยืนทับอยู่ข้างหน้า
/// เหนือคำมีบรรทัดกำกับตัวเล็กระยะห่างกว้าง ใต้ภาพมีย่อหน้าแนะนำตัว
///
/// # ความลึกมาจากการทับ ไม่ใช่จากเงา
///
/// ต้นฉบับไม่มีเงาสักเส้น — สิ่งที่บอกว่ามีสองระนาบคือ *ขาของคนที่ทับตัวอักษรอยู่*
/// ที่นี่จึงเรียงเป็น คำ → ภาพ ตรง ๆ และให้ภาพกินพื้นที่ลงมาจนพ้นเส้นฐานของคำ
/// (ถ้าใส่เงาเพิ่ม มันจะอ่านเป็นสติกเกอร์ที่แปะทับ ไม่ใช่คนที่ยืนอยู่ข้างหน้าตัวอักษร)
struct AboutBehind: View {
    let theme: CardTheme
    let size: CGSize

    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var cardInk

    /// คำยักษ์เป็นสีขาวบนเบจตามต้นฉบับ — พอปิดพื้น มันต้องกลายเป็น "เงาของหมึกการ์ด"
    /// ไม่งั้นตัวขาวบนการ์ดกระดาษจะหายไปทั้งคำ
    private var skin: EdSkin { Ed.skin(surface, paper: Ed.beige, ink: cardInk, theme: theme) }

    @Environment(\.widgetID) private var widgetID

    var body: some View {
        // คำยักษ์ **กินเต็มความกว้างแผ่นเสมอ** — ต้นฉบับให้ตัวอักษรโผล่พ้นภาพทั้งซ้ายและขวา
        // ถ้าตั้งขนาดตายตัว คำสั้นจะซ่อนอยู่หลังภาพจนหมด แล้วชั้นที่สองของหน้าก็หายไปทั้งชั้น
        let word = Profile.me.note(widgetID, 1, preset: "รู้จักฉัน")
        let big = Ed.fitted(word, weight: .black, width: size.width * 0.92,
                            cap: size.height * 0.30)
        return ZStack(alignment: .topLeading) {
            skin.sheet
            PlatePatternLayer(sheet: skin.sheet)
            if skin.papered { EdGrain(count: 320, opacity: 0.05, tint: Ed.brown) }

            EdPlace(x: 0.08, y: 0.045, w: 0.84, h: 0.055, size: size) {
                EdText(slot: 0, preset: "หลงใหลการเล่าเรื่อง ภาพ และงานคราฟต์",
                       hint: "บรรทัดบนสุด",
                       style: .init(size: 7, weight: .semibold, color: skin.inkSoft,
                                    align: .center, tracking: 1.8))
                    .frame(maxWidth: .infinity)
                    .scrubVeil(scrub.d, lead: 0.28, drop: 14, pull: 8)
            }

            EdPlace(x: 0.04, y: 0.115, w: 0.92, h: 0.24, size: size) {
                EdText(slot: 1, preset: "รู้จักฉัน", hint: "คำยักษ์",
                       style: .init(size: big, weight: .black, color: skin.ghost,
                                    align: .center, tracking: -big * 0.02))
                    .frame(maxWidth: .infinity)
                    .scrubVeil(scrub.d, lead: 0.18, drop: 30, pull: 10)
            }

            EdPlace(x: 0.185, y: 0.185, w: 0.370, h: 0.815, size: size, align: .bottom) { cutout }
            EdPlace(x: 0.575, y: 0.395, w: 0.385, h: 0.545, size: size, align: .topLeading) {
                blurb
            }
        }
        .frame(width: size.width, height: size.height)
    }

    /// ภาพตัด — ไม่มีกรอบ ไม่มีเงา ชนก้นแผ่นเหมือนคนยืนอยู่บนพื้น
    private var cutout: some View {
        EdPhoto(slot: 1, mono: true, depth: 8)
            .scrubLouver(scrub.d, lead: 0.1, angle: 34, shrink: 0.08, flat: true)
    }

    private var blurb: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                EdText(slot: 2, preset: "รู้จักฉัน —", hint: "หัวย่อหน้า",
                       style: .init(size: 9, weight: .bold, color: skin.ink))
                Text(Profile.me.name)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .editableText(.name, .init(size: 9, weight: .bold, color: skin.ink))
                Spacer(minLength: 0)
            }
            EditableParagraph(field: .about,
                              style: .init(size: 8, weight: .regular,
                                           color: skin.ink.opacity(0.88), lineSpacing: 2.4))
        }
        .scrubVeil(scrub.d, lead: 0.02, drop: 22, pull: 14)
    }
}
