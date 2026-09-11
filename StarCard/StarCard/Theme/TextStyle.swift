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

    func color(ink: InkStyle, accent: Color) -> Color {
        switch self {
        case .ink:    return ink.text(0.92)
        case .soft:   return ink.text(0.55)
        case .accent: return accent
        default:
            guard let c = raw else { return ink.text(0.92) }
            // ขาว/ดำเลือกมาเพื่อ "ขาว" หรือ "ดำ" จริง ๆ — ห้ามปรับตามพื้น ไม่งั้นตัวเลือกนี้ก็หายไป
            if self == .white || self == .black { return c }
            return ink.isLight ? c.onLightSurface() : c
        }
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
struct WidgetTextStyle: Equatable {
    var face: CardFont = .noto
    var tint: TextTint = .ink
    var scale: TextScale = .medium
    var align: TextAlign = .leading
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
