import SwiftUI
import CoreText

/// ฟอนต์และไอคอนที่ยกมาจากแอป SaleHere
///
/// ลงทะเบียนฟอนต์ตอนรันแทนการประกาศใน Info.plist เพราะโปรเจกต์นี้ใช้
/// `GENERATE_INFOPLIST_FILE` ซึ่งไม่มีไฟล์ plist ให้แก้ และการยัด array ผ่าน
/// `INFOPLIST_KEY_` ไม่น่าเชื่อถือ — วิธีนี้ไม่ต้องแตะ pbxproj เลย
enum SHFont {
    static func register() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) else { return }
        CTFontManagerRegisterFontsForURLs(urls as CFArray, .process, nil)
    }

    /// NotoSansThai — ตัวเดียวกับที่แอปหลักใช้ รองรับสระบน-ล่างของไทยได้ถูกต้อง
    /// ต่างจากฟอนต์ระบบที่ตกไปใช้ fallback แล้วระยะบรรทัดเพี้ยน
    static func name(_ weight: Font.Weight) -> String {
        switch weight {
        case .black:                   return "NotoSansThai-Black"
        case .heavy:                   return "NotoSansThai-ExtraBold"
        case .bold:                    return "NotoSansThai-Bold"
        case .semibold:                return "NotoSansThai-SemiBold"
        case .medium:                  return "NotoSansThai-Medium"
        case .light, .thin, .ultraLight: return "NotoSansThai-Light"
        default:                       return "NotoSansThai-Regular"
        }
    }
}

extension Font {
    /// ฟอนต์หลักของการ์ด
    static func sh(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(SHFont.name(weight), fixedSize: size)
    }
}

// MARK: - ไอคอน

/// ไอคอนเวกเตอร์ที่ยกมาจากแอปหลัก — โลโก้แบรนด์โซเชียลของจริง ไม่ใช่ SF Symbol ที่ใกล้เคียง
enum SHIcon {
    static let instagram = "about-social-instagram"
    static let tiktok    = "about-social-tiktok"
    static let youtube   = "about-social-youtube"
    static let facebook  = "about-social-facebook"
    static let x         = "about-social-x"
    static let lemon8    = "about-social-lemon8"

    static let sealCheck = "ic-seal-check"
    static let star      = "ic-salehere-star-outline"
    static let wordmark  = "ic-salehere-text"
    static let watermark = "ic-salehere-watermark"
    static let qr        = "ic-salehere-qr"

    static let arrowUpRight = "ph-arrow-up-right"
    static let sparkle      = "ph-sparkle"
    static let starFill     = "ph-star-fill"
    static let check        = "ph-check"
    static let mapPin       = "ph-map-pin"
    static let heart        = "ph-heart-fill"
    static let users        = "ph-users-three"
    static let ticket       = "ph-ticket"
}

/// ไอคอนโลโก้แบรนด์ — คงสีต้นฉบับไว้
struct BrandIcon: View {
    let name: String
    var size: CGFloat = 14

    var body: some View {
        Image(name)
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

/// ไอคอนสัญลักษณ์ — ย้อมสีตามธีมได้
struct SymbolIcon: View {
    let name: String
    var size: CGFloat = 14
    var tint: Color = .white

    var body: some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(tint)
    }
}
