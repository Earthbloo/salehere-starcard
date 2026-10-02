import SwiftUI
import UIKit

// MARK: - หน้าตาของตัวอักษรบนวิดเจ็ตข้อความ
//
// # ทำไมสไตล์เก็บที่ "ชิ้น" ไม่ใช่ที่ "ตระกูล"
//
// กติกาใน `WidgetContent.swift` บอกว่า *เนื้อหา* เก็บต่อตระกูล เพราะการ์ดใบหนึ่งมีเจ้าของคนเดียว
// แต่ **หน้าตาไม่ใช่เนื้อหา** — มันคือของชุดเดียวกับ `surface`/`border` ซึ่งเก็บต่อชิ้นมาตั้งแต่แรก
// วางข้อความสองก้อนบนหน้าเดียวกันแล้วอยากได้คนละฟอนต์คนละสีเป็นเรื่องปกติของการจัดหน้า
// ถ้าผูกไว้กับตระกูล การแก้ก้อนหนึ่งจะไปเปลี่ยนอีกก้อนทันที ซึ่งอ่านออกมาเป็นบั๊ก
//
// # ทำไมไม่เปิดให้ใส่ฟอนต์/สีอิสระ
//
// เหตุผลเดียวกับที่ `Palette` ไม่รับ hex: การ์ดที่เลือกอะไรก็ได้จะกลมกลืนกันเองไม่ได้
// และ contrast ก็การันตีไม่ได้ · ชุดที่ให้เลือกจึงเป็น **โทเคน** ที่ถูกจูนมาแล้วทั้งพื้นมืดและพื้นกระดาษ

/// ฟอนต์ที่เลือกได้ — ทุกตัวต้องอ่านภาษาไทยออก ไม่ใช่ฟอนต์ละตินที่ปล่อยให้ไทยตกไป fallback
///
/// `noto` กับ `mitr` มาในแอป · ที่เหลือเป็นฟอนต์ไทยของ iOS เอง
/// ตัวไหนหาไม่เจอบนเครื่องจะตกกลับไปที่ `noto` เสมอ (ดู `resolved`)
enum CardFont: String, CaseIterable, Identifiable {
    case noto, mitr, sukhumvit, thonburi, krungthep, rounded, serif

    var id: String { rawValue }

    var name: String {
        switch self {
        case .noto:      return "มาตรฐาน"
        case .mitr:      return "มิตร"
        case .sukhumvit: return "สุขุมวิท"
        case .thonburi:  return "ธนบุรี"
        case .krungthep: return "กรุงเทพ"
        case .rounded:   return "มน"
        case .serif:     return "เซริฟ"
        }
    }

    /// ดีไซน์ของฟอนต์ระบบ — nil แปลว่าตัวนี้เป็นฟอนต์ที่มีชื่อจริง ไม่ใช่ระบบ
    private var design: UIFontDescriptor.SystemDesign? {
        switch self {
        case .rounded: return .rounded
        case .serif:   return .serif
        default:       return nil
        }
    }

    /// ชื่อ PostScript ของน้ำหนักที่ขอ — nil เมื่อเป็นฟอนต์ระบบ
    ///
    /// ฟอนต์ที่มีน้ำหนักเดียว (มิตร · กรุงเทพ) คืนชื่อเดิมทุกน้ำหนัก — หนาไม่ขึ้นดีกว่าตกไปฟอนต์อื่น
    /// กลางประโยค เพราะสิ่งที่ผู้ใช้เลือกคือ *หน้าตา* ไม่ใช่ *น้ำหนัก*
    private func face(_ w: Font.Weight) -> String? {
        switch self {
        case .noto: return SHFont.name(w)
        case .mitr: return "Mitr-Regular"
        case .krungthep: return "Krungthep"
        case .thonburi:
            switch w {
            case .bold, .heavy, .black, .semibold:  return "Thonburi-Bold"
            case .light, .thin, .ultraLight:        return "Thonburi-Light"
            default:                                return "Thonburi"
            }
        case .sukhumvit:
            switch w {
            case .heavy, .black:             return "SukhumvitSet-Bold"
            case .bold:                      return "SukhumvitSet-Bold"
            case .semibold:                  return "SukhumvitSet-SemiBold"
            case .medium:                    return "SukhumvitSet-Medium"
            case .light, .thin, .ultraLight: return "SukhumvitSet-Light"
            default:                         return "SukhumvitSet-Text"
            }
        case .rounded, .serif: return nil
        }
    }

    /// ชื่อที่ **มีอยู่จริงบนเครื่องนี้** — ตัวที่ลงทะเบียนไม่สำเร็จตกกลับไปที่ฟอนต์หลักของแอป
    /// เช็คที่นี่ที่เดียว ทั้ง `Font` และ `UIFont` จึงไม่มีทางได้คนละหน้าตากัน
    private func resolved(_ w: Font.Weight) -> String? {
        guard let n = face(w) else { return nil }
        if UIFont(name: n, size: 12) != nil { return n }
        return SHFont.name(w)
    }

    func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        if let d = design {
            return .system(size: size, weight: weight,
                           design: d == .serif ? .serif : .rounded)
        }
        guard let n = resolved(weight) else { return .sh(size, weight) }
        return .custom(n, fixedSize: size)
    }

    func uiFont(_ size: CGFloat, _ weight: Font.Weight = .regular) -> UIFont {
        if let d = design {
            let base = UIFont.systemFont(ofSize: size, weight: weight.ui)
            guard let desc = base.fontDescriptor.withDesign(d) else { return base }
            return UIFont(descriptor: desc, size: size)
        }
        guard let n = resolved(weight), let f = UIFont(name: n, size: size) else {
            return .systemFont(ofSize: size, weight: weight.ui)
        }
        return f
    }
}

extension Font.Weight {
    /// คู่ของน้ำหนักฝั่ง UIKit — ช่องพิมพ์เป็น `UITextView` จึงต้องมีตารางนี้
    var ui: UIFont.Weight {
        switch self {
        case .black:      return .black
        case .heavy:      return .heavy
        case .bold:       return .bold
        case .semibold:   return .semibold
        case .medium:     return .medium
        case .light:      return .light
        case .thin:       return .thin
        case .ultraLight: return .ultraLight
        default:          return .regular
        }
    }
}

/// สีตัวอักษร — โทเคน ไม่ใช่ hex อิสระ
///
/// สามตัวแรกล้อการ์ด (พลิกตามหมึกให้เอง) · ที่เหลือเป็นสีคงที่ที่ถูกดันลงมาให้อ่านออก
/// บนพื้นกระดาษด้วย `onLightSurface()` — สีเดียวกันบนพื้นมืดกับพื้นสว่างจึงไม่มีตัวไหนหายไปกับพื้น
enum TextTint: String, CaseIterable, Identifiable {
    case ink, soft, accent, white, black
    case rose, coral, gold, mint, sky, lavender

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ink:      return "ตามหมึก"
        case .soft:     return "จาง"
        case .accent:   return "สีเน้น"
        case .white:    return "ขาว"
        case .black:    return "ดำ"
        case .rose:     return "ชมพู"
        case .coral:    return "ส้ม"
        case .gold:     return "ทอง"
        case .mint:     return "เขียว"
        case .sky:      return "ฟ้า"
        case .lavender: return "ม่วง"
        }
    }

    /// สีดิบของโทเคนที่เป็นสีคงที่ — ใช้ทั้งตอนวาดจริงและตอนวาดวงกลมในแผงเลือก
    private var raw: Color? {
        switch self {
        case .white:    return .white
        case .black:    return Color(white: 0.08)
        case .rose:     return Palette.rose.accent
        case .coral:    return Palette.coral.accent
        case .gold:     return Palette.champagne.accent
        case .mint:     return Palette.mint.accent
        case .sky:      return Palette.sky.accent
        case .lavender: return Palette.lavender.accent
        default:        return nil
        }
    }

    /// สีที่วาดจริงบนการ์ด — **อ่านออกบนพื้นเสมอ** (ดู `Legibility.swift`)
    ///
    /// สีคงที่ถูกขยับความสว่างจนตัดกับพื้น เฉดเดิมอยู่ครบ: ทองบนพื้นแชมเปญกลายเป็นทองเข้ม ไม่ใช่หายไปกับพื้น
    /// และเปลี่ยนสีพื้นทีหลังเมื่อไหร่ ตัวหนังสือที่เลือกสีไว้ก็ตามไปเอง ไม่ต้องกลับมาไล่แก้ทีละก้อน
    /// - Parameter large: ตัวอักษรใหญ่พอให้ใช้เกณฑ์ตัวใหญ่ (3:1) — ก้อนข้อความรู้ขนาดจริงของตัวเอง
    func color(ink: InkStyle, accent: Color, large: Bool = false) -> Color {
        let target = large ? Legibility.large : Legibility.body
        switch self {
        case .ink:    return ink.text(0.92)
        case .soft:   return ink.text(0.55)
        case .accent: return accent.legible(on: ink.ground, target: target, prefersLight: !ink.isLight)
        default:
            guard let c = raw else { return ink.text(0.92) }
            // ขาว/ดำเลือกมาเพื่อ "ขาว" หรือ "ดำ" จริง ๆ — ห้ามขยับสี ไม่งั้นตัวเลือกนี้ก็หายไป
            // อ่านออกได้ด้วยเงากันจมแทน (ดู `halo`)
            if self == .white || self == .black { return c }
            return (ink.isLight ? c.onLightSurface() : c)
                .legible(on: ink.ground, target: target, prefersLight: !ink.isLight)
        }
    }

    /// เงากันจมของขาว/ดำที่ผู้ใช้เลือกเจาะจง — nil เมื่ออ่านออกอยู่แล้ว
    ///
    /// ขาวบนการ์ดสว่าง (หรือดำบนการ์ดมืด) ไม่มีทางอ่านออกด้วยตัวสีเอง และขยับสีก็ไม่ได้ —
    /// เงาสีตรงข้ามรอบตัวอักษรคือวิธีเดียวที่ได้ทั้ง "สีที่เลือก" และ "อ่านออก" (ท่าของหน้าล็อก iOS)
    /// ยิ่งจมมากเงายิ่งเข้ม · อ่านออกอยู่แล้วไม่มีเงา การ์ดพื้นมืดที่ใช้ตัวขาวจึงหน้าตาเหมือนเดิมทุกประการ
    func halo(ink: InkStyle, large: Bool = false) -> Color? {
        guard self == .white || self == .black, let c = raw else { return nil }
        let target = large ? Legibility.large : Legibility.body
        let have = ink.ground.contrast(of: RGB(c).luminance)
        guard have < target else { return nil }
        let short = min(1, (target - have) / (target - 1))
        return (self == .white ? Color.black : Color.white).opacity(0.3 + 0.45 * short)
    }

    /// สีที่โชว์ในแผงเครื่องมือ (พื้นมืดคงที่) — สามตัวแรกไม่มีสีของตัวเอง จึงต้องยืมของธีมมา
    func swatch(accent: Color) -> Color {
        switch self {
        case .ink:    return .white
        case .soft:   return .white.opacity(0.45)
        case .accent: return accent
        default:      return raw ?? .white
        }
    }
}

/// ขนาดตัวอักษร — สี่ขั้น ไม่ใช่สไลเดอร์ต่อเนื่อง
///
/// สไลเดอร์ให้ค่าที่ "เกือบเท่ากัน" ได้เป็นสิบค่า ซึ่งไม่มีค่าไหนดีกว่ากันจริง
/// แต่ทำให้การ์ดสองใบของคนคนเดียวไม่มีทางเท่ากันเลย · ขั้นบันไดคุมสัดส่วนทั้งการ์ดไว้ได้
enum TextScale: String, CaseIterable, Identifiable {
    case small, medium, large, huge

    var id: String { rawValue }

    var name: String {
        switch self {
        case .small:  return "เล็ก"
        case .medium: return "กลาง"
        case .large:  return "ใหญ่"
        case .huge:   return "ยักษ์"
        }
    }

    var size: CGFloat {
        switch self {
        case .small:  return 13
        case .medium: return 17
        case .large:  return 26
        case .huge:   return 40
        }
    }

    /// น้ำหนักไต่ตามขนาด — ตัวเล็กบางเกินไปอ่านไม่ออก ตัวยักษ์ที่บางอ่านเป็นหัวเรื่อง ไม่ใช่ข้อความ
    var weight: Font.Weight {
        switch self {
        case .small, .medium: return .medium
        case .large:          return .semibold
        case .huge:           return .bold
        }
    }

    /// ระยะบรรทัด — ตัวใหญ่ต้องการช่องไฟเป็นสัดส่วนที่น้อยลง ไม่ใช่ค่าคงที่เดียวทุกขนาด
    var lineSpacing: CGFloat {
        switch self {
        case .small:  return 4
        case .medium: return 5
        case .large:  return 4
        case .huge:   return 0
        }
    }
}

enum TextAlign: String, CaseIterable, Identifiable {
    case leading, center, trailing

    var id: String { rawValue }

    var name: String {
        switch self {
        case .leading:  return "ซ้าย"
        case .center:   return "กลาง"
        case .trailing: return "ขวา"
        }
    }

    var icon: String {
        switch self {
        case .leading:  return "text.alignleft"
        case .center:   return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }

    var text: TextAlignment {
        switch self {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }

    var frame: Alignment {
        switch self {
        case .leading:  return .topLeading
        case .center:   return .top
        case .trailing: return .topTrailing
        }
    }
}

/// หน้าตาตัวอักษรของ widget หนึ่งชิ้น — เก็บอยู่ใน `WidgetInstance` คู่กับ `surface`/`border`
/// ขั้นขนาดตัวอักษร **ของช่องหนึ่งช่อง** — คูณกับขนาดที่ดีไซน์ตั้งไว้ให้ช่องนั้น
///
/// # ทำไมเป็นตัวคูณ ไม่ใช่ขนาด pt
///
/// เพราะ `M` ต้องแปลว่า *ขนาดที่ดีไซน์ตั้งใจ* เสมอ ไม่ว่าจะเป็นชื่อ 28pt หรือสายงาน 9.5pt —
/// ถ้าขั้นเป็น pt ตายตัว การกด `M` ที่สองช่องนั้นจะทำให้มันเท่ากัน แล้วลำดับชั้นหายไป
/// ตัวคูณทำให้ทุกขั้นเป็น "เทียบกับที่ออกแบบไว้" ซึ่งเป็นภาษาที่คนแต่งการ์ดคิดอยู่แล้ว
///
/// ช่วงของตัวคูณอยู่ที่ `factor` ข้างล่าง (0.60–2.20) — กรอบของชิ้นถูกล็อกสัดส่วนไว้
/// ตัวอักษรที่โตเกินกรอบไม่ได้ทำให้กรอบโตตาม
/// มันจะถูกตัดหรือถูกย่อลงเอง ซึ่งเป็นพฤติกรรมที่ยอมรับได้ ต่างจากขั้นที่กดแล้วไม่เห็นผล
enum WidgetTextSize: String, CaseIterable, Identifiable, Equatable {
    case xs, s, m, l, xl, xxl

    var id: String { rawValue }
    /// ป้ายบนถาด — สั้นพอให้หกขั้นอยู่ในแถวเดียว
    var label: String { rawValue.uppercased() }

    /// ช่วงกว้างจริง — จากเล็กกว่าที่ออกแบบไว้เกือบครึ่ง ไปจนใหญ่กว่าสองเท่า
    ///
    /// ของเดิมอยู่ที่ 0.80–1.36 ซึ่งกด XS กับ XXL แล้วแทบไม่ต่างกัน — ขั้นที่ไม่เห็นผล
    /// คือขั้นที่ไม่มีอยู่จริง · ตอนนี้ไล่แบบเรขาคณิต (คูณ ~1.3 ต่อขั้น) สายตาจึงอ่านออกว่า
    /// **ทุกขั้นเป็นคนละขนาด** ไม่ใช่ตัวเลขหกตัวที่ให้ผลใกล้กันสี่ตัว
    ///
    /// ขนาดที่ได้ถูกคุมปลายทั้งสองข้างอีกชั้นที่ `WidgetTextStyle.scaled` — ตัวคูณเดียวกัน
    /// เจอกับคำบรรยาย 6.4pt กับชื่อ 28pt คนละเรื่องกัน ปลายล่างจึงต้องมีพื้นที่อ่านออกเสมอ
    var factor: CGFloat {
        switch self {
        case .xs:  return 0.60
        case .s:   return 0.78
        case .m:   return 1.00
        case .l:   return 1.30
        case .xl:  return 1.70
        case .xxl: return 2.20
        }
    }
}

struct WidgetTextStyle: Equatable {
    var face: CardFont = .noto
    var tint: TextTint = .ink
    /// ขั้นขนาดแบบเก่า — เหลือไว้อ่านไฟล์รุ่นก่อน (ดู `CardStore`) ตัววาดไม่ใช้แล้ว
    var scale: TextScale = .medium
    var align: TextAlign = .leading
    /// ขนาดตัวอักษรของก้อนข้อความ (pt) — ปรับต่อเนื่องด้วยหมุดมุม ไม่ใช่ขั้นบันได
    ///
    /// ต่างจาก `TextScale` โดยตั้งใจ: ก้อนข้อความคือหัวเรื่อง/ป้าย ที่ผู้ใช้จูนขนาดด้วยตาเทียบกับของข้าง ๆ
    /// การบังคับสี่ขั้นทำให้ "พอดี" หาไม่เจอบ่อยกว่าที่มันช่วยคุมสัดส่วน
    var points: CGFloat = 28

    /// # หน้าตาของ **แต่ละช่องข้อความ** ในชิ้นนี้ — ฟอนต์ · สี · ขนาด
    ///
    /// สามชุดนี้เก็บ "เฉพาะช่องที่ถูกสั่งทับ" — ไม่มีคีย์ = **ตามที่ดีไซน์เลือกไว้**
    /// ซึ่งต้องเป็นค่าตั้งต้นเสมอ ไม่งั้นหยิบชิ้นออกจากตู้แล้วเซริฟของหัวเรื่องนิตยสาร
    /// หรือครีมบนแผ่นเข้มจะถูกกลบด้วยค่ามาตรฐานทันทีโดยไม่มีใครสั่ง
    ///
    /// เก็บที่ *ชิ้น* ไม่ใช่ที่ *ข้อความ* — วางฮีโร่สองตัวบนการ์ดเดียวกัน ชื่อเดียวกัน
    /// แต่แต่งคนละแบบได้ เพราะนี่คือหน้าตาของชิ้นนั้น ไม่ใช่ข้อเท็จจริงของเจ้าของการ์ด
    var slotFaces: [String: CardFont] = [:]
    var slotTints: [String: TextTint] = [:]
    /// ขั้นขนาด **ของแต่ละช่อง** — คีย์คือช่องนั้น (ดู `slotKey`) · ไม่มีคีย์ = `m` (ขนาดที่ดีไซน์ตั้งไว้)
    ///
    /// # ทำไมเป็นรายช่อง ไม่ใช่ขั้นเดียวทั้งชิ้น
    ///
    /// ขั้นเดียวทั้งชิ้นขยายทุกบรรทัดพร้อมกัน ซึ่งแก้ปัญหา "ทั้งใบเล็กไป" ได้ แต่ไม่ได้แก้
    /// ปัญหาที่คนแต่งเจอจริงกว่า: **ชื่อควรใหญ่กว่านี้ แต่คำบรรยายกำลังดีแล้ว**
    /// พอขยายทั้งชิ้น คำบรรยายก็ล้นตามไปด้วย แล้วต้องย้อนกลับมาขั้นเดิมทั้งใบ
    ///
    /// เก็บที่ *ชิ้น* ไม่ใช่ที่ *ข้อความ* — วางฮีโร่สองตัวบนการ์ดเดียวกัน ชื่อเดียวกัน
    /// แต่ตั้งขนาดคนละขั้นได้ เพราะขนาดคือหน้าตาของชิ้นนั้น ไม่ใช่ข้อเท็จจริงของเจ้าของการ์ด
    var slotSizes: [String: WidgetTextSize] = [:]

    /// คีย์ของช่องหนึ่งช่องในชิ้น — ฟิลด์ + ลำดับ (ชิ้นไหนดูจากตัว `WidgetInstance` ที่ถือค่านี้อยู่)
    static func slotKey(_ field: ProfileField, _ index: Int? = nil) -> String {
        index.map { "\(field.rawValue)#\($0)" } ?? field.rawValue
    }

    func size(for field: ProfileField, _ index: Int? = nil) -> WidgetTextSize {
        slotSizes[Self.slotKey(field, index)] ?? .m
    }
    /// `nil` = ตามดีไซน์
    func face(for field: ProfileField, _ index: Int? = nil) -> CardFont? {
        slotFaces[Self.slotKey(field, index)]
    }
    /// `nil` = ตามดีไซน์
    func tint(for field: ProfileField, _ index: Int? = nil) -> TextTint? {
        slotTints[Self.slotKey(field, index)]
    }

    /// ฟอนต์จริงของช่องที่ดีไซน์สั่งมาเป็น `size`/`weight` — ผ่านฟอนต์และขั้นขนาดของช่องนั้นแล้ว
    func font(_ size: CGFloat, _ weight: Font.Weight = .regular,
              for field: ProfileField, _ index: Int? = nil) -> Font {
        (face(for: field, index) ?? .noto).font(scaled(size, for: field, index), weight)
    }

    /// สีของช่องนั้น — คืนสีที่ดีไซน์ตั้งไว้ถ้าเจ้าของการ์ดยังไม่ได้เลือกสีให้ช่องนี้
    ///
    /// ใช้กับใบที่ตั้งสีเองไม่ได้ผ่านตัวประกาศช่อง (ตัวอักษรไล่เฉด · กล่องที่มีหลายก้อน)
    func color(_ design: Color, for field: ProfileField, _ index: Int? = nil,
               ink: InkStyle, accent: Color) -> Color? {
        tint(for: field, index)?.color(ink: ink, accent: accent)
    }

    /// ขนาดหลังคูณขั้นของช่องนั้น — คุมปลายทั้งสองข้างไว้
    ///
    /// ล่าง 6pt: เล็กกว่านี้อ่านไม่ออกบนกระดาษที่พิมพ์จริง (คำบรรยาย 6.4pt × XS = 3.8pt)
    /// บน 160pt: ใหญ่กว่านี้ไม่มีกรอบไหนในตู้รับไหว มันกลายเป็นตัวอักษรที่ถูกตัดทิ้งครึ่งตัว
    func scaled(_ size: CGFloat, for field: ProfileField, _ index: Int? = nil) -> CGFloat {
        min(max(size * self.size(for: field, index).factor, 6), 160)
    }
}

private struct WidgetTextStyleKey: EnvironmentKey {
    static let defaultValue = WidgetTextStyle()
}

extension EnvironmentValues {
    /// สไตล์ตัวอักษรของชิ้นที่กำลังวาดอยู่ — ส่งลงมาจาก `WidgetChrome` ทางเดียวกับ `widgetID`
    /// พรีวิวในตู้กับ thumb ไม่มีชิ้นจริงให้อ่าน จึงได้ค่าตั้งต้นไปโดยไม่ต้องรู้จัก `WidgetInstance`
    var widgetTextStyle: WidgetTextStyle {
        get { self[WidgetTextStyleKey.self] }
        set { self[WidgetTextStyleKey.self] = newValue }
    }
}

// MARK: - ตัวอักษรขยายเต็มกล่อง

extension TextAlign {
    /// จุดยึดในกล่อง — กลางแนวตั้งเสมอ (กล่องที่สูงกว่าข้อความต้องอ่านเป็น "จงใจเว้น" ไม่ใช่ข้อความหล่นไปติดหัว)
    var centered: Alignment {
        switch self {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }

    var ns: NSTextAlignment {
        switch self {
        case .leading:  return .left
        case .center:   return .center
        case .trailing: return .right
        }
    }
}

/// วัดก้อนข้อความ — **ไม่ตัดบรรทัดเอง** บรรทัดใหม่มีเฉพาะที่ผู้ใช้กด Return
///
/// กล่องของก้อนข้อความคือตัวอักษรพอดี: กว้างเท่าบรรทัดที่ยาวที่สุด สูงเท่าจำนวนบรรทัด
/// ขนาดปรับด้วยหมุดมุมอย่างเดียว (ดู `cornerHandle`) — ไม่มีหมุดกว้าง/สูงให้ดันข้อความจนตัดบรรทัด
/// เพราะการขึ้นบรรทัดใหม่คือการตัดสินใจของคนเขียน ไม่ใช่ผลข้างเคียงของกล่อง
///
/// วัดด้วย TextKit (`boundingRect`) — ช่องพิมพ์ (`UITextView`) วางบรรทัดด้วยตัวเดียวกัน จึงตรงกันเป๊ะ
enum TextFit {
    /// ช่องไฟระหว่างบรรทัดเป็นสัดส่วนของขนาด — ค่าคงที่เดียวใช้ไม่ได้เมื่อขนาดวิ่งตั้งแต่ 9 ถึง 200
    static let spacing: CGFloat = 0.10
    static let minSize: CGFloat = 9
    static let maxSize: CGFloat = 200
    /// ขนาดตอนพิมพ์ — **เท่ากันทุกก้อน** ไม่ว่าบนการ์ดจะย่อไว้จิ๋วหรือขยายไว้ยักษ์ (ท่าเดียวกับ Story)
    /// เท่ากับขนาดตั้งต้นของก้อนใหม่ ก้อนที่เพิ่งสร้างจึงไม่เปลี่ยนขนาดตอนกด เสร็จ
    static let editSize: CGFloat = 28

    struct Metrics {
        /// กล่องตามตัวพิมพ์ (line box) — สูงตามฟอนต์ เผื่อสระบน/ล่างไว้เสมอแม้ไม่มี
        var typo: CGSize
        /// กล่องตาม **หมึก** ที่วาดจริง ในพิกัดของ `typo` (จุดกำเนิดมุมบนซ้าย · ค่าลบได้ถ้าหมึกล้น line box)
        var ink: CGRect
    }

    /// วัดสองกล่อง — กล่องบนการ์ดใช้ **หมึก** ไม่ใช่ line box
    ///
    /// ผู้ใช้เห็นตัวอักษร ไม่ได้เห็น line box: ฟอนต์ไทยเผื่อที่ให้สระบน/วรรณยุกต์/สระล่างไว้ตลอด
    /// บรรทัดที่ไม่มีของพวกนั้นจึงมีที่ว่างเหนือ-ใต้ตัวอักษรราวสามสิบเปอร์เซ็นต์ ซึ่งในสายตาเขาคือ padding
    ///
    /// วัดด้วย CoreText ทีละบรรทัด — `boundingRect(.usesDeviceMetrics)` ให้แค่ขนาดหมึก ไม่ให้ตำแหน่ง
    /// (origin.y เป็นศูนย์เสมอ) และหลายบรรทัดคืน line box ทั้งก้อน ใช้ไม่ได้
    /// วางบรรทัดแบบเดียวกับที่ SwiftUI/TextKit วาง: สูง = ascent+descent+leading · คั่นด้วย `spacing`
    /// บรรทัดสั้นเลื่อนตามการจัดวางในความกว้างของบรรทัดที่ยาวที่สุด
    static func metrics(_ text: String, face: CardFont, weight: Font.Weight, size: CGFloat,
                        align: TextAlign) -> Metrics {
        let font = face.uiFont(size, weight)
        let gap = size * spacing
        let lines = text.isEmpty ? [" "] : text.components(separatedBy: "\n")
        var rows: [(w: CGFloat, h: CGFloat, asc: CGFloat, ink: CGRect)] = []
        var maxW: CGFloat = 0
        for l in lines {
            let ct = CTLineCreateWithAttributedString(
                NSAttributedString(string: l.isEmpty ? " " : l, attributes: [.font: font]))
            var asc: CGFloat = 0, desc: CGFloat = 0, lead: CGFloat = 0
            let w = CGFloat(CTLineGetTypographicBounds(ct, &asc, &desc, &lead))
            // พิกัด CoreText คือฐานบรรทัด แกน y ชี้ขึ้น — แปลงเป็นมุมบนซ้ายทีหลัง
            rows.append((w, asc + desc + lead, asc, CTLineGetImageBounds(ct, nil)))
            maxW = max(maxW, w)
        }
        let typoW = maxW.rounded(.up)
        var y: CGFloat = 0
        var ink: CGRect? = nil
        for (i, r) in rows.enumerated() {
            let x0: CGFloat
            switch align {
            case .leading:  x0 = 0
            case .center:   x0 = (typoW - r.w) / 2
            case .trailing: x0 = typoW - r.w
            }
            if r.ink.width > 0, r.ink.height > 0 {
                let rect = CGRect(x: x0 + r.ink.minX, y: y + r.asc - r.ink.maxY,
                                  width: r.ink.width, height: r.ink.height)
                ink = ink.map { $0.union(rect) } ?? rect
            }
            y += r.h + (i < rows.count - 1 ? gap : 0)
        }
        let typo = CGSize(width: typoW, height: y.rounded(.up))
        // ช่องว่างล้วนไม่มีหมึก — ตกไปใช้ line box ไม่งั้นกล่องยุบเหลือศูนย์
        return Metrics(typo: typo, ink: (ink ?? CGRect(origin: .zero, size: typo)).integral)
    }

    /// ขนาดธรรมชาติของข้อความที่ขนาดฟอนต์หนึ่ง — ไม่จำกัดความกว้าง ไม่ตัดบรรทัด (line box)
    static func natural(_ text: String, face: CardFont, weight: Font.Weight, size: CGFloat) -> CGSize {
        metrics(text, face: face, weight: weight, size: size, align: .leading).typo
    }

    /// ขนาดที่ใช้จริง — เท่าที่ตั้งไว้ เว้นแต่บรรทัดที่ยาวที่สุดจะล้น `maxWidth` แล้วจึงหดลงพอดี
    ///
    /// ล้นหน้าคือกรณีเดียวที่ระบบแตะขนาดแทนผู้ใช้ — และแตะแค่ชั่วคราว: ตัดคำให้สั้นลงเมื่อไหร่ก็ได้ขนาดเดิมคืน
    static func capped(_ points: CGFloat, _ text: String, face: CardFont, weight: Font.Weight,
                       maxWidth: CGFloat) -> CGFloat {
        let p = min(max(points, minSize), maxSize)
        guard maxWidth > 4 else { return p }
        let w = natural(text, face: face, weight: weight, size: p).width
        guard w > maxWidth else { return p }
        return max(minSize, (p * maxWidth / w).rounded(.down))
    }
}
