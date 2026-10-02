import SwiftUI

// MARK: - โปสเตอร์พอร์ต
//
// ใบที่สามของตระกูลคัตเอาต์ (สองใบแรกอยู่ใน `CutoutWidgets.swift`) แปลงตรงจากโปสเตอร์
// พอร์ตโฟลิโอที่เจ้าของการ์ดส่งมา — **ผัง สัดส่วน วัสดุ สี ตามต้นฉบับ · ตัวอักษรใช้ฟอนต์ของแอป**
//
// # สิ่งที่ทำให้ใบนี้ไม่ใช่เวทีมืดแบบใบคัตเอาต์รุ่นแรก (ถอดออกแล้ว 29 ก.ย. 2569)
//
// สองใบแรกของตระกูลคือ **เวทีมืด** — คนยืนอยู่ใต้ไฟ มีเงาทอดลงพื้น ตัวอักษรเรืองอยู่ข้างหลัง
// ใบนี้คือ **แผ่นที่ถูกพิมพ์** — ไม่มีไฟ ไม่มีเงา คนกับคำอยู่บนระนาบเดียวกันคือผิวกระดาษ
// เงาใต้ตัวจึงถูก **ปิด** ไม่ใช่แค่หรี่ลง — เงาบนกระดาษอ่านเป็นสติกเกอร์ที่แปะทับ
// ซึ่งฆ่าความเป็นงานพิมพ์ทั้งใบ · ส่วน **รูปยังเป็นสีของมันเอง**: เคยลองบังคับขาวดำให้เข้ากับ
// หมึกสีเดียว แล้วมันกลืนครีเอเตอร์ทิ้งไปด้วย — รูปคือตัวเขา ไม่ใช่พื้นผิวของโปสเตอร์
//
// # สามชั้นที่ต้องทับกันจริง
//
// 1. **คำยักษ์** กินเต็มความกว้าง — ชั้นหลังสุด
// 2. **คน** PNG พื้นหลังใสของเจ้าของการ์ด ยืนคร่อมคำนั้น
// 3. **แถบกระดาษที่ขอบล่าง** พาดผ่านตัวคน — ชั้นหน้าสุด
//
// ชั้นที่ 3 ไม่ใช่ของตกแต่ง: ถ้าคนถูกแค่ *วางทับ* คำ สายตายังอ่านได้ว่าเป็นรูปที่ครอปมาแปะ
// สิ่งที่พิสูจน์ว่าเขาอยู่ *ระหว่าง* ชั้นคือการมีของอีกชิ้นพาดทับเขาอยู่ (เหตุผลเดียวกับแถบ
// สายงานในใบคัตเอาต์รุ่นแรก — ที่นั่นพาดหน้าอก ที่นี่พาดที่ขอบล่าง)
//
// และแถบนั้นยัง **ทำงานอีกอย่างที่มองไม่เห็น**: รูปตัดพื้นหลังเกือบทุกใบถูกตัดจบที่กลางลำตัว
// ปล่อยขอบตัดไว้กลางแผ่นเมื่อไหร่มันอ่านเป็นครึ่งท่อนลอย ไม่ใช่คนที่ยืนอยู่ —
// แถบสีเดียวกับกระดาษกลืนไปกับแผ่นจนมองไม่เห็นว่ามีแถบ แต่มันคือสิ่งที่กินรอยตัดนั้นไว้
//
// เดิมแถบนี้ยังแบกเส้นคาด + สายงาน + ชื่ออยู่ด้วย — ถอดออกแล้วทั้งสามอย่าง เหลือคำพาดหัว
// กับบรรทัดนำเป็นตัวอักษรชุดเดียวของแผ่น ตัวตนของเจ้าของการ์ดพูดผ่านรูป ไม่ใช่ผ่านป้ายชื่อ

/// วัสดุและหมึกของใบนี้ — **ทุกสีคิดจากพื้นที่ตัวอักษรนั่งอยู่จริง ไม่มีสีตายตัวสักสี**
///
/// # ทำไมไม่ฝังแดงกับถ่านไว้เลย
///
/// รอบแรกใบนี้เป็นแดงออฟเซตบนกระดาษครีม ตามต้นฉบับเป๊ะ — แล้วมันผิดสองชั้นพร้อมกัน:
/// บนการ์ดธีมม่วง/เขียว แดงกลายเป็นสีแปลกปลอมสีเดียวบนหน้า (การ์ดทั้งใบมีพาเลตต์ของมัน)
/// และตอนถอดกระดาษออก ถ่านบนการ์ดมืดก็จมหายไปทั้งบรรทัด
///
/// กติกาที่ใช้แทนคือข้อเดียว: **ถามพื้นก่อนว่าเป็นใคร แล้วค่อยเลือกหมึก**
/// - มีกระดาษ → พื้นคือแผ่นสว่างที่อมเฉดของธีมไว้บาง ๆ · หมึกเป็นเฉดเดียวกันแต่เข้มจนอ่านออก
/// - ไม่มีกระดาษ → พื้นคือ *การ์ด* · หมึกจึงเป็นหมึกของการ์ด (`InkStyle` พลิกให้เองทั้งสองฝั่ง)
///
/// สีเน้นใช้ `theme.accent`/`onLightSurface()` ซึ่งเก็บเฉดเดิมแล้วขยับแค่ความสว่าง —
/// เขียวยังเป็นเขียว แค่เข้มพอจะอ่านออกบนกระดาษ (ท่าเดียวกับที่ `Legibility` ใช้ทั้งแอป)
struct PosterSkin {
    /// ยังมีกระดาษรองอยู่ไหม — เกล็ด เศษหนังสือพิมพ์ มุมมน และแถบฐาน อ่านค่านี้ก่อนวาด
    var papered: Bool
    var sheet: Color
    /// สีของคำพาดหัว บรรทัดนำ และเส้นคาดฐาน
    var accent: Color
    var ink: Color
    var inkSoft: Color
    /// หมึกของเศษหนังสือพิมพ์
    var news: Color

    static func make(_ surface: WidgetSurface, theme: CardTheme, on ink: InkStyle) -> PosterSkin {
        let hue = theme.backdropHue
        // # การ์ดคู่สี — แผ่นคือ **สีเข้มของคู่** ชุดเดียวกับโปสเตอร์สายงาน
        //
        // รอบก่อนใบนี้ทำกระดาษจากสีอ่อนของคู่แล้วผสมขาวเข้าไป ซึ่งอ่านออกก็จริง แต่บนหน้าเดียวกัน
        // ที่มีโปสเตอร์สายงาน · ผู้ติดตาม · คลิปล่าสุด เป็นแผ่นกรมท่าเรียงกันสามใบ ใบนี้กลายเป็น
        // แผ่นขาวใบเดียวที่โดดออกมา — การ์ดอ่านเป็น "สองระบบสีที่วางปนกัน" ไม่ใช่งานสองสีใบเดียว
        //
        // เศษหนังสือพิมพ์ยังเป็นกระดาษขาวที่ฉีกมาแปะ (ดู `scrap`) หมึกบนมันจึงเป็นสีเข้มของคู่
        // ไม่ใช่สีอ่อน — มันไม่ได้นั่งอยู่บนแผ่น มันนั่งอยู่บนกระดาษของตัวเอง
        // บนกระจกของ chrome — ผังของแผ่นพิมพ์ทั้งชุด แต่ตัวแผ่นใส หมึกเป็นหมึกของการ์ด
        if surface == .pane {
            return .init(papered: true, sheet: .clear,
                         accent: theme.accent,
                         ink: ink.text(0.95), inkSoft: ink.text(0.55),
                         news: ink.text(0.45))
        }
        if surface != .clear, let duo = theme.activeDuo {
            let plate = PosterPlate.plate(theme)
            let ink = PosterPlate.cream(theme)
            return .init(papered: true, sheet: plate,
                         accent: ink, ink: ink,
                         inkSoft: ink.mixed(with: plate, by: 0.42),
                         news: duo.dark)
        }
        guard surface == .clear else {
            return .init(papered: true,
                         // กระดาษอมเฉดของธีมไว้ **นิดเดียว** — ขาวสนิทอ่านเป็นพื้นแอป
                         // ส่วนกระดาษที่ย้อมจนเห็นสีจะกลายเป็นแผ่นพลาสติกสี ไม่ใช่กระดาษ
                         sheet: Color(hue: hue, saturation: 0.045, brightness: 0.965),
                         accent: theme.rawAccent.onLightSurface(),
                         ink: Color(hue: hue, saturation: 0.16, brightness: 0.11),
                         inkSoft: Color(hue: hue, saturation: 0.10, brightness: 0.42),
                         news: Color(hue: hue, saturation: 0.12, brightness: 0.28))
        }
        return .init(papered: false, sheet: .clear,
                     accent: theme.accent,
                     ink: ink.text(0.95), inkSoft: ink.text(0.55),
                     news: .clear)
    }
}

/// เศษหนังสือพิมพ์ที่แปะเป็นฉากหลัง — **แถบตัวอักษร ไม่ใช่ตัวอักษรจริง**
///
/// ต้นฉบับมีเศษกระดาษพิมพ์ฉีกแปะอยู่หลังตัวแบบสามชิ้น ถ้าเอาข้อความจริงมาวางจะเจอสองปัญหา:
/// ที่ 6pt มันอ่านไม่ออกอยู่ดี (จึงเป็นแค่ texture ในสายตา) และการ์ดที่ถูก export เป็นรูปจะมี
/// ประโยคที่ไม่มีใครเขียนติดไปด้วย · แถบสีเทาที่มีจังหวะแบบคอลัมน์ให้ผลตาเดียวกันโดยไม่โกหก
struct PosterClipping: View {
    var tint: Color = Color(white: 0.2)
    var opacity: Double = 0.42
    /// เมล็ดคงที่ต่อชิ้น — ความยาวบรรทัดต้องไม่เปลี่ยนทุกครั้งที่ SwiftUI วาดใหม่
    var seed: UInt64 = 0x9E3779B97F4A7C15

    /// ระยะบรรทัดจริงของหนังสือพิมพ์ย่อส่วน — **ค่าคงที่เป็น pt ไม่ใช่สัดส่วนของชิ้น**
    ///
    /// รอบแรกหารความสูงด้วยจำนวนบรรทัดที่ส่งมา ผลคือชิ้นใหญ่ได้บรรทัดห่างเป็นนิ้ว
    /// แล้วมันอ่านเป็นการ์ดโครงร่างที่ยังโหลดไม่เสร็จ ไม่ใช่กระดาษพิมพ์ —
    /// สิ่งที่บอกตาว่า "นี่คือตัวหนังสือ" คือ *ความถี่* ไม่ใช่รูปร่างของแต่ละบรรทัด
    private let lead: CGFloat = 3.1

    var body: some View {
        Canvas { ctx, size in
            var s = seed
            func rnd() -> CGFloat {
                s ^= s << 13; s ^= s >> 7; s ^= s << 17
                return CGFloat(s % 10_000) / 10_000
            }
            let pad = min(7, size.width * 0.08)
            // สองคอลัมน์เมื่อชิ้นกว้างพอ — หน้าหนังสือพิมพ์ไม่มีคอลัมน์เดียวกว้างเต็มหน้า
            let cols = size.width - pad * 2 > 90 ? 2 : 1
            let gutter: CGFloat = cols == 2 ? 7 : 0
            let colW = (size.width - pad * 2 - gutter) / CGFloat(cols)
            let head = min(size.height * 0.10, 5.5)

            // พาดหัวของเศษกระดาษ — แถบหนาสองบรรทัดบนสุด
            ctx.fill(Path(CGRect(x: pad, y: pad, width: (size.width - pad * 2) * 0.72,
                                 height: head)),
                     with: .color(tint.opacity(opacity * 1.15)))

            for c in 0..<cols {
                let x = pad + CGFloat(c) * (colW + gutter)
                var y = pad + head + 5
                while y < size.height - pad {
                    let ww = colW * (0.72 + rnd() * 0.28)
                    ctx.fill(Path(CGRect(x: x, y: y, width: ww, height: 1.1)),
                             with: .color(tint.opacity(opacity * (0.55 + Double(rnd()) * 0.45))))
                    y += lead
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - โปสเตอร์พอร์ต

struct ArtPortfolioPoster: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(\.widgetID) private var wid
    @Environment(\.widgetLiftsPhoto) private var liftsPhoto
    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var cardInk
    @Environment(\.widgetEmboss) private var embossed
    @Environment(\.widgetEmbossBlind) private var embossBlind
    let theme: CardTheme
    let size: CGSize

    /// คำพาดหัว — ของ *ดีไซน์* ไม่ใช่ของโปรไฟล์ จึงเก็บต่อชิ้นแบบเดียวกับสำรับบรรณาธิการ
    /// (วางใบนี้สองที่แล้วพาดหัวคนละคำได้ — "PORTFOLIO" กับ "PORTRAIT" เป็นเรื่องปกติของโปสเตอร์)
    private static let headlinePreset = "PORTFOLIO"

    /// # ทำไมต้องอ่านขนาดจาก `GeometryReader` ทั้งที่ `size` ถูกส่งมาให้แล้ว
    ///
    /// หมุดย่อความสูงของการ์ดไม่ได้มีเพดานล่างเป็นตัวเลขคงที่ — มันเอา widget ไปวาดซ้ำอีกชุด
    /// แบบ `fixedSize` แล้ว **ถามว่าเนื้อหาขอความสูงเท่าไหร่** (ดู `CardScreen.minHeight(for:)`)
    ///
    /// ใบที่ประกาศ `.frame(height: size.height)` ตรง ๆ จะตอบกลับไปเท่ากับความสูงที่ได้รับมา
    /// เพดานล่างจึงเท่ากับความสูงปัจจุบันเสมอ แปลว่า **ลากย่อไม่ลงสักพิกเซล** —
    /// ซึ่งเป็นสิ่งที่เกิดขึ้นจริงกับใบนี้รอบแรก
    ///
    /// `GeometryReader` ไม่มีความสูงในตัว ใบนี้จึงบอกระบบตามจริงว่า "ยืดหดได้ทุกขนาด"
    /// ซึ่งเป็นความจริงของมัน: ทุกระยะบนแผ่นคิดเป็น *สัดส่วน* ของกรอบ ไม่มีค่าคงที่สักค่า
    var body: some View {
        GeometryReader { geo in
            poster(w: max(1, geo.size.width), h: max(1, geo.size.height))
        }
    }

    private func poster(w: CGFloat, h: CGFloat) -> some View {
        let skin = PosterSkin.make(surface, theme: theme, on: cardInk)
        let plane = cutoutPlane(photos, slot: 1, widget: wid, lift: liftsPhoto)
        let pad = w * 0.055
        let headline = Profile.me.note(wid, 1, preset: Self.headlinePreset).uppercased()
        // คำพาดหัวต้องกิน **เต็มความกว้าง** เสมอ — ขนาดตายตัวทำให้คำสั้นลอยอยู่ครึ่งแผ่น
        // และคำยาวถูกย่อจนเป็นบรรทัดจิ๋ว ซึ่งทั้งสองอย่างไม่ใช่โปสเตอร์แล้ว
        let fs = Ed.fitted(headline, weight: .heavy, width: w - pad * 2,
                           cap: h * 0.19, floor: 16)
        // ── ที่ยืนของตัวคน คิดจาก **ก้อนตัวอักษร** ไม่ใช่จากสัดส่วนของใบ
        //
        // เคยตั้งเป็น "สูง 0.88 ของใบ" ตรง ๆ แล้วมันถูกเฉพาะที่ความสูงตั้งต้นใบเดียว:
        // พอผู้ใช้ย่อใบให้เตี้ยลง คำพาดหัวเล็กลงตามเพดาน `h * 0.19` แต่ตัวคนยังสูง 0.88 เท่าเดิม
        // สัดส่วนที่คนทับคำจึงโตขึ้นเรื่อย ๆ จนกลืนคำไปทั้งบรรทัด
        //
        // ที่นี่จึงหาขอบบนของตัวคนจาก *ตำแหน่งจริงของตัวอักษร*: ลงมา ~60% ของตัวพาดหัว
        // แปลว่าหัวคนตัดผ่านช่วงล่างของตัวอักษรเสมอ ไม่ว่ากรอบจะสูงเท่าไหร่ —
        // คาบเกี่ยวพอให้อ่านว่า "คำอยู่ข้างหลังเขา" แต่ยังเหลือตัวอักษรให้อ่านครบ
        let bleed = h * 0.05
        let typeTop = h * 0.055
        // บรรทัดชื่อเหนือพาดหัว: เซอริฟเอียงตัวบาง ดึงชิดคำพาดหัว — จังหวะเดียวกับ "Recent" / "VIDEOGRAPHY"
        let nameSize = fs * 0.42
        let nameGap = -fs * 0.26
        let subjectTop = typeTop + nameSize * 1.3 + nameGap + fs * 0.60
        let subjectH = max(h * 0.4, h + bleed - subjectTop)
        let shape = RoundedRectangle(cornerRadius: skin.papered ? 18 : 0, style: .continuous)

        return ZStack(alignment: .topLeading) {
            Color.clear

            // ── กระดาษ
            if skin.papered {
                skin.sheet
                PlatePatternLayer(sheet: skin.sheet)
                EdGrain(count: 320, opacity: 0.05, tint: .black)
            }

            // ── ชั้นหลัง: ชื่อ + คำยักษ์
            //
            // บรรทัดนำเป็น **ชื่อเจ้าของการ์ด** แบบเดียวกับหัว `ReelShowcase` ("Recent" / "VIDEOGRAPHY"):
            // เซอริฟเอียงตัวบางอยู่บน คำหนาทึบอยู่ล่าง ดึงขึ้นมาชิดกัน — สองน้ำหนักทำให้พาดหัวมีจังหวะ
            // และบอกว่า "พอร์ตของใคร" ในจังหวะเดียว
            // ชื่ออยู่ **กลาง** เหนือคำพาดหัว ดึงลงมาชิดจนเกือบแตะหัวตัวอักษร — อ่านเป็นก้อนเดียวกัน
            // ตราปั๊มนูน Sale Here STAR บนแผ่น — มุมขวาล่าง ตำแหน่งผู้ออกบัตร · อยู่ **ใต้ตัวคน**:
            // มันถูกกดลงบนแผ่นกระดาษ คนยืนอยู่หน้าแผ่น ลากคนมาทับเมื่อไหร่ตราก็แค่ถูกบัง ไม่ขึ้นมาทับตัวคน
            if embossed {
                EmbossedLockup(height: max(20, h * (embossBlind ? 0.085 : 0.10)),
                               light: surface == .glass ? theme.activeDuo == nil : cardInk.isLight,
                               foil: !embossBlind, tint: skin.accent)
                    .padding(.trailing, pad * 0.9)
                    .padding(.bottom, pad * 0.75)
                    .frame(width: w, height: h, alignment: .bottomTrailing)
                    .allowsHitTesting(false)
            }

            VStack(alignment: .center, spacing: nameGap) {
                // ตรายืนยันเกาะชื่อเหมือนทุกใบในตระกูลโปรไฟล์ (สัญญาของตระกูล: ชื่อ · ตรายืนยัน · สายงาน)
                HStack(spacing: nameSize * 0.28) {
                    Text(Profile.me.name)
                        .lineLimit(1).minimumScaleFactor(0.45)
                        .editableText(.name, .init(size: nameSize, weight: .regular, face: .serif,
                                                   color: skin.accent, italic: true))
                    if Profile.me.creator.verified {
                        StarSeal(size: max(9, nameSize * 0.5), tint: skin.accent,
                                 punch: skin.papered && surface == .glass ? skin.sheet : (cardInk.isLight ? Color(white: 0.97) : Color(white: 0.10)))
                    }
                }
                Text(headline)
                    // heavy ไม่ใช่ black — ที่น้ำหนักหนาสุด NotoSansThai วางสระบนชนวรรณยุกต์
                    .kerning(-fs * 0.045)
                    .lineLimit(1).minimumScaleFactor(0.3)
                    .editableText(.note, index: 1, widget: wid,
                                  preset: Self.headlinePreset, hint: "คำพาดหัว",
                                  .init(size: fs, weight: .heavy, color: skin.accent,
                                        tracking: -fs * 0.045, uppercase: true, corner: 6))
            }
            .frame(width: w - pad * 2, alignment: .center)
            .padding(.leading, pad)
            .padding(.top, h * 0.055)
            // ชั้นหลังสุดวิ่งสวนแรงที่สุด — ตาอ่านความลึกจาก *ความต่างของอัตรา* ไม่ใช่จากระยะ
            .scrubSlide(scrub.d, travel: -w * 0.26, fade: 0.84, eased: false)

            // ── ชั้นกลาง: คน
            switch plane {
            case let .subject(ui, _):
                // **อยู่กลางแผ่น** และสูงพอให้หัวแตะคำพาดหัวเท่านั้น
                //
                // รอบก่อนตัวคนสูง 0.92 ของใบและเยื้องไปทางขวา ผลคือสองอย่างที่ผิดพร้อมกัน:
                // ตัวคนไม่อยู่กลางกรอบ (อ่านเป็นรูปที่วางพลาด ไม่ใช่การจัดองค์ประกอบ)
                // และหัวขึ้นไปกินคำพาดหัวถึงกลางตัวอักษรจนเหลือให้อ่านสองสามตัว
                //
                // "อยู่หลังคำ" ต้องการแค่ **คาบเกี่ยว** ไม่ใช่กลืน — ขอบบนของหัวตัดผ่าน
                // ช่วงล่างของตัวอักษรก็พอแล้วที่ตาจะสรุปว่าคำอยู่ข้างหลังเขา
                CutoutSubject(image: ui, height: subjectH, d: scrub.d, drift: w * 0.04,
                              shadow: false)
                    // กรอบของ *ช่อง* เท่าตัวคนพอดี — ปุ่มเปลี่ยนรูปเกาะกรอบนี้
                    .photoSlot(1)
                    .frame(width: w, height: h, alignment: .bottom)
                    // ล้นขอบล่างเล็กน้อย — รอยตัดที่เอวจะได้จบใต้แถบฐาน ไม่ใช่กลางแผ่น
                    .offset(y: bleed)
            case .framed:
                // บล็อกรูปเริ่มใต้ก้อนตัวอักษรพอดี — ไม่มีอัลฟาให้ตัวอักษรลอดออกมา
                // ทับเมื่อไหร่ก็คือทับจริง ๆ ไม่ใช่ "อยู่หลังคน"
                framedPlate(w: w, top: subjectTop + fs * 0.45, h: h)
            }

            // ไม่มีแถบฐานทับตัวคนแล้ว — แถบสีกระดาษเดียวกับแผ่นมองไม่เห็นแต่ **บังท้ายรูป**
            // ผู้ใช้ลากคนลงไปเท่าไหร่ก็ไม่ถึงขอบล่าง · ตัวคนล้นขอบล่าง (`bleed`) ตั้งแต่ต้นอยู่แล้ว
            // รอยตัดที่เอวจึงจบนอกแผ่น ไม่ต้องมีอะไรบัง

            // ป้ายสถานะไปอยู่ **ขวาบน** ไม่ใช่ซ้ายบนเหมือนอีกสองใบของตระกูล —
            // ซ้ายบนของใบนี้คือบรรทัดสายงาน ป้ายจะทับมันพอดีทุกครั้งที่เข้าโหมดแต่ง
            CutoutStatus(plane: plane, theme: theme,
                         lifting: cutoutLifting(photos, slot: 1, widget: wid, lift: liftsPhoto))
                .padding(pad * 0.7)
                .frame(width: w, height: h, alignment: .topTrailing)
        }
        .frame(width: w, height: h)
        .clipShape(shape)
    }

    // MARK: โหมดกรอบ

    /// รูปทึบ — โปสเตอร์ยังเป็นโปสเตอร์ใบเดิม เปลี่ยนแค่ว่ารูปถูก **พิมพ์เป็นบล็อก** ใต้คำพาดหัว
    ///
    /// ไม่ใช่ "แบบเดียวกันแต่พัง": ใบนี้อยู่ตระกูลเดียวกับปกนิตยสาร คนกด "เปลี่ยนแบบ" มาเจอมัน
    /// ด้วยรูป JPEG ตลอดเวลา ถ้าหน้าตาตรงนั้นแย่ ทั้งแบบก็ไม่มีความหมาย
    /// บล็อกลง **ชนขอบล่างของใบ** — รูปครึ่งตัวที่ลอยจบเหนือขอบล่างอ่านเป็นรูปที่วางค้างไว้
    /// วางด้วย padding ไม่ใช่ offset: กรอบของช่อง (`photoSlot`) ต้องอยู่ตรงที่รูปถูกวาดจริง
    /// ไม่งั้นแผ่นจัดรูปกับปุ่มเปลี่ยนรูปไปเกาะตำแหน่งก่อนเลื่อน
    private func framedPlate(w: CGFloat, top: CGFloat, h: CGFloat) -> some View {
        Color.clear
            .overlay {
                WidgetPhoto(index: 1)
                    .aspectRatio(contentMode: .fill)
                    .scrubDolly(scrub.d, shift: w * 0.04, zoom: 0.12)
            }
            .frame(width: w * 0.70, height: max(40, h - top))
            .clipped()
            // อยู่กลางกรอบเหมือนตัวคัตเอาต์ — บล็อกที่เยื้องข้างเดียวอ่านเป็นรูปที่วางพลาด
            // เงาบาง ๆ รอบบล็อก — รูปที่พื้นหลังสว่าง (ถ่ายในสตูดิโอ ฉากขาว) จะกลืนไปกับกระดาษ
            // จนอ่านไม่ออกว่าตรงไหนคือขอบรูป · ตัวคัตเอาต์ไม่ต้องการเงานี้ เพราะมันไม่มีขอบให้หา
            .shadow(color: .black.opacity(0.13), radius: 10, y: 4)
            .photoSlot(1)
            .padding(.top, top)
            .frame(width: w, height: h, alignment: .top)
    }
}
