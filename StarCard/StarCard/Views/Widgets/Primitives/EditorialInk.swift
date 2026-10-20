// ชิ้นส่วนกลางที่ตัววาดผัง (SpecPainter) และหน้าจออื่นเรียกใช้ — ไม่ผูกกับ widget ตัวใด
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
