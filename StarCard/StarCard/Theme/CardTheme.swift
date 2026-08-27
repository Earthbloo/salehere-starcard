import SwiftUI
import UIKit

// MARK: - หมึกของการ์ด

/// พื้นผิวของการ์ด — "การ์ดใบนี้เขียนด้วยหมึกอะไรบนกระดาษอะไร"
///
/// จงใจ**ไม่**ผูกกับ dark mode ของเครื่องผู้ดู เพราะการ์ดคือชิ้นงานที่ครีเอเตอร์ออกแบบแล้วส่งต่อ
/// ถ้าปล่อยให้ล้อระบบ แบรนด์ที่เปิดดูคนละเครื่องจะเห็นคนละงาน — มันต้องเป็นการตัดสินใจของเจ้าของการ์ด
/// เหมือนเลือกกระดาษพิมพ์ ไม่ใช่ค่า preference ของผู้อ่าน
///
/// สองพื้นผิวนี้ไม่ใช่ "สีกลับด้าน" แต่เป็นคนละภาษาการมองรูป:
/// - `night` — เวทีมืด **รูปคือแหล่งกำเนิดแสง** · เหมาะกับบิวตี้ แฟชั่น กลางคืน
/// - `paper` / `mist` — กระดาษ **รูปคือภาพพิมพ์** · เหมาะกับไลฟ์สไตล์ อาหาร แม่และเด็ก มินิมอล
enum CardInk: String, CaseIterable, Identifiable {
    /// เวทีมืด — ของเดิม
    case night
    /// กระดาษขาวนวล เป็นกลาง
    case paper
    /// กระดาษที่อาบสีธีมบาง ๆ — โทน "ใสใส"
    case mist

    var id: String { rawValue }

    var name: String {
        switch self {
        case .night: return "กลางคืน"
        case .paper: return "กระดาษ"
        case .mist:  return "ใสใส"
        }
    }
    var icon: String {
        switch self {
        case .night: return "moon.stars.fill"
        case .paper: return "doc.plaintext.fill"
        case .mist:  return "drop.fill"
        }
    }

    var isLight: Bool { self != .night }
}

/// ชุดสีที่ใช้ "บนพื้นการ์ด"
///
/// # กติกาข้อเดียวที่ห้ามพลาด
///
/// โทเคนชุดนี้ใช้กับของที่วางอยู่บน **พื้นการ์ด** เท่านั้น
/// ตัวหนังสือที่วางบน **รูป** ต้องเป็นสีขาวเสมอทุกหมึก เพราะมันอ่านออกได้ด้วย scrim ดำ
/// ที่อยู่ใต้ตัวมันเอง ไม่ได้อาศัยพื้นการ์ด — ถ้าพลิกตามหมึกด้วยจะกลายเป็นดำบนรูปแล้วหายไปเลย
///
/// # ทำไมต้องรีแมปค่า ไม่ใช่แค่สลับสี
///
/// ขาวบนดำกับดำบนขาวไม่ได้ให้น้ำหนักเท่ากันที่ค่า alpha เดียวกัน — ตัวหนังสือรองที่
/// `white 0.5` บนพื้นมืดอ่านสบาย แต่ `black 0.5` บนพื้นสว่างดูซีดจนเหมือนโดน disable
/// ส่วนเส้นผมกลับกัน: เส้นเข้มบนพื้นสว่าง "ดัง" กว่าเส้นสว่างบนพื้นมืดที่ค่าเท่ากัน
/// ทุกฟังก์ชันข้างล่างจึงมีเส้นโค้งของตัวเอง ไม่ได้ใช้ค่าดิบร่วมกัน
struct InkStyle: Equatable {
    let ink: CardInk
    /// สีหมึก — ฝั่งสว่างเป็นถ่านที่อาบเฉดของธีมไว้นิดหน่อย ไม่ใช่ดำสนิท
    /// (ดำสนิทบนการ์ดที่มีสีธีมจะอ่านเป็น "ยังไม่ได้ออกแบบ")
    let base: Color

    var isLight: Bool { ink.isLight }

    /// ตัวหนังสือ — `l` คือน้ำหนักชุดเดียวกับที่เคยเขียน `.white.opacity(l)`
    func text(_ l: Double) -> Color {
        guard isLight else { return .white.opacity(l) }
        return base.opacity(min(0.94, pow(max(0, l), 0.85)))
    }

    /// ตัวอักษร/สัญลักษณ์ที่ตั้งใจให้เป็นเงา — พื้นสว่างต้องจางกว่าพื้นมืดมาก
    /// ไม่งั้น "เงา" จะกลายเป็นเนื้อหาที่แย่งสายตา
    func ghost(_ l: Double) -> Color {
        guard isLight else { return .white.opacity(l) }
        return base.opacity(l * 0.5)
    }

    /// เส้นผม · ขอบ
    func line(_ l: Double) -> Color {
        guard isLight else { return .white.opacity(l) }
        return base.opacity(min(0.6, l * 0.8))
    }

    /// พื้นแผ่นบาง ๆ ที่ต้องแยกตัวจากฉากหลัง
    /// พื้นมืดแยกตัวด้วยการ "สว่างขึ้น" · พื้นสว่างแยกตัวด้วยการ "เข้มลง" — ความหมายเดียวกัน คนละทิศ
    func fill(_ l: Double) -> Color {
        guard isLight else { return .white.opacity(l) }
        return base.opacity(min(0.5, l * 0.8))
    }

    /// ชั้นความสูง — พื้นมืดใช้แสง (เงาดำมองไม่เห็น) · พื้นสว่างใช้เงา (แสงมองไม่เห็น)
    var lift: Color { isLight ? base.opacity(0.18) : .clear }
    var liftRadius: CGFloat { isLight ? 14 : 0 }

    static let night = InkStyle(ink: .night, base: .white)
}

private struct CardInkKey: EnvironmentKey {
    /// ค่าเริ่มต้นคือกลางคืน — พรีวิวในตู้ widget อยู่บนชีตมืด จึงต้องได้หมึกมืดโดยไม่ต้องตั้งค่า
    static let defaultValue = InkStyle.night
}

extension EnvironmentValues {
    var cardInk: InkStyle {
        get { self[CardInkKey.self] }
        set { self[CardInkKey.self] = newValue }
    }
}

// MARK: - สีเน้นที่ปรับตามพื้น

extension Color {
    /// เวอร์ชันที่อ่านออกบนพื้นสว่าง — ลดความสว่าง เพิ่มความอิ่ม
    ///
    /// พาเลตต์ทั้งชุดถูกจูนมาสำหรับพื้นมืด (สว่างจัด อิ่มตัวต่ำ แบบพาสเทลเรืองแสง)
    /// เอาไปวางบนกระดาษขาวแล้วหายไปกับพื้นทันที ต้องดันลงมาเป็นสีอิ่มเข้ม
    /// คำนวณจาก HSB ไม่ใช่ตารางสีตายตัว เพื่อให้สีที่ดูดมาจากรูปพื้นหลังได้ผลเดียวกัน
    /// - Parameter depth: 1 = สีเน้นหลัก · ต่ำกว่านั้นคือคู่ไล่เฉดที่อ่อนกว่า
    func onLightSurface(depth: Double = 1) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        let k = max(0, min(1, depth))
        return Color(hue: Double(h),
                     saturation: Double(min(1, s * (1.35 - 0.28 * (1 - k)) + 0.12)),
                     brightness: Double(min(1, b * (0.60 + 0.26 * (1 - k)))))
    }
}

/// พาเลตต์ระดับการ์ด — widget เลือกได้แค่ "ตามธีม / เข้ม / อ่อน / เน้น"
/// ไม่เปิดให้ใส่ hex อิสระ เพื่อให้การ์ดกลมกลืนเสมอและ contrast ผ่านเกณฑ์
enum Palette: String, CaseIterable, Identifiable {
    // ไล่ตามวงล้อสี: น้ำเงิน → ฟ้า → เขียว → ม่วง → ชมพู → ส้ม → ทอง → เทา
    case midnight, sky, ocean, mint, lime, lavender, orchid, rose, ruby, coral, champagne, noir

    var id: String { rawValue }

    var name: String {
        switch self {
        case .midnight:  return "Midnight"
        case .sky:       return "Sky"
        case .ocean:     return "Ocean"
        case .mint:      return "Mint"
        case .lime:      return "Lime"
        case .lavender:  return "Lavender"
        case .orchid:    return "Orchid"
        case .rose:      return "Rose"
        case .ruby:      return "Ruby"
        case .coral:     return "Coral"
        case .champagne: return "Champagne"
        case .noir:      return "Noir"
        }
    }

    var accent: Color {
        switch self {
        case .midnight:  return Color(red: 0.51, green: 0.60, blue: 1.00)
        case .sky:       return Color(red: 0.38, green: 0.66, blue: 1.00)
        case .ocean:     return Color(red: 0.32, green: 0.79, blue: 0.95)
        case .mint:      return Color(red: 0.36, green: 0.90, blue: 0.68)
        case .lime:      return Color(red: 0.72, green: 0.93, blue: 0.40)
        case .lavender:  return Color(red: 0.72, green: 0.63, blue: 1.00)
        case .orchid:    return Color(red: 0.93, green: 0.52, blue: 0.98)
        case .rose:      return Color(red: 1.00, green: 0.55, blue: 0.74)
        case .ruby:      return Color(red: 1.00, green: 0.42, blue: 0.47)
        case .coral:     return Color(red: 1.00, green: 0.60, blue: 0.43)
        case .champagne: return Color(red: 0.93, green: 0.80, blue: 0.55)
        case .noir:      return Color(red: 0.84, green: 0.86, blue: 0.90)
        }
    }

    var accentSoft: Color {
        switch self {
        case .midnight:  return Color(red: 0.62, green: 0.78, blue: 1.00)
        case .sky:       return Color(red: 0.58, green: 0.80, blue: 1.00)
        case .ocean:     return Color(red: 0.46, green: 0.94, blue: 0.88)
        case .mint:      return Color(red: 0.63, green: 0.96, blue: 0.80)
        case .lime:      return Color(red: 0.85, green: 1.00, blue: 0.62)
        case .lavender:  return Color(red: 0.88, green: 0.74, blue: 1.00)
        case .orchid:    return Color(red: 1.00, green: 0.70, blue: 1.00)
        case .rose:      return Color(red: 1.00, green: 0.73, blue: 0.85)
        case .ruby:      return Color(red: 1.00, green: 0.63, blue: 0.66)
        case .coral:     return Color(red: 1.00, green: 0.77, blue: 0.60)
        case .champagne: return Color(red: 1.00, green: 0.92, blue: 0.74)
        case .noir:      return Color(red: 0.62, green: 0.65, blue: 0.72)
        }
    }

    /// เฉดฐานของฉากหลัง (0…1 บนวงล้อสี) — เก็บเป็น hue ไม่ใช่ RGB สำเร็จรูป
    /// เพื่อให้ผู้ใช้เลื่อนโทนและความสว่างได้โดยไม่ต้องมีตารางสีตายตัวทุกชุด
    var backdropHue: Double {
        switch self {
        case .midnight:  return 0.64
        case .sky:       return 0.58
        case .ocean:     return 0.54
        case .mint:      return 0.42
        case .lime:      return 0.24
        case .lavender:  return 0.74
        case .orchid:    return 0.82
        case .rose:      return 0.93
        case .ruby:      return 0.98
        case .coral:     return 0.04
        case .champagne: return 0.10
        case .noir:      return 0.62
        }
    }

    /// อิ่มตัวฐาน — noir ต้องจืดกว่าตัวอื่นถึงจะยังเป็นโทนเทา
    var backdropSaturation: Double { self == .noir ? 0.10 : 0.58 }
}

enum CornerStyle: String, CaseIterable, Identifiable {
    case soft, round, pill
    var id: String { rawValue }
    var radius: CGFloat {
        switch self {
        case .soft:  return 18
        case .round: return 28
        case .pill:  return 38
        }
    }
    var name: String {
        switch self {
        case .soft:  return "คม"
        case .round: return "มน"
        case .pill:  return "มนมาก"
        }
    }
}

/// แบบของฉากหลัง
enum BackdropStyle: String, CaseIterable, Identifiable {
    case gradient, glow, solid, photo
    var id: String { rawValue }

    var name: String {
        switch self {
        case .gradient: return "ไล่เฉด"
        case .glow:     return "ดวงแสง"
        case .solid:    return "สีเดียว"
        case .photo:    return "รูปเบลอ"
        }
    }
    var icon: String {
        switch self {
        case .gradient: return "square.filled.and.line.vertical.and.square"
        case .glow:     return "sun.max.fill"
        case .solid:    return "square.fill"
        case .photo:    return "photo.fill"
        }
    }
}

struct CardTheme: Equatable {
    var palette: Palette = .midnight
    /// พื้นผิวของการ์ด — เลือกโดยเจ้าของการ์ด ไม่ล้อ dark mode ของเครื่องผู้ดู
    var ink: CardInk = .night
    var corner: CornerStyle = .round
    var backdrop: BackdropStyle = .gradient
    /// 0 = เข้มเกือบดำ · 1 = สว่าง
    var brightness: Double = 0.30
    /// เลื่อนเฉดพื้นหลังออกจากสีธีม −0.5…0.5 รอบวงล้อสี
    var hueShift: Double = 0

    /// โทนที่ดูดมาจากรูปพื้นหลังที่อัปโหลด — ตั้งแล้วทั้งธีมล้อตามรูปแทนพาเลตต์
    /// เลือกสีพาเลตต์เองเมื่อไหร่ค่านี้ถูกล้าง (ผู้ใช้ตัดสินใจ override)
    var customHue: Double? = nil
    var customSat: Double? = nil

    /// หมึกที่ใช้จริง — **พื้นหลังเป็นรูปเมื่อไหร่ บังคับกลางคืนเสมอ**
    ///
    /// รูปพื้นหลังเป็นภาพอะไรก็ได้ สว่างตรงไหนมืดตรงไหนคุมไม่ได้ หมึกเข้มบนกระดาษ
    /// จึงไม่มีทางรับประกันว่าอ่านออก ส่วนหมึกกลางคืนมี scrim ของตัวเองรองอยู่แล้วทุกชั้น
    /// เก็บค่าที่ผู้ใช้เลือกไว้ใน `ink` ตามเดิม — เปลี่ยนฉากหลังกลับเมื่อไหร่ได้โทนเดิมคืน
    var activeInk: CardInk { backdrop == .photo ? .night : ink }

    var backdropHue: Double {
        let raw = (customHue ?? palette.backdropHue) + hueShift
        return raw - floor(raw)
    }
    private var backdropSat: Double {
        customHue != nil ? min(0.6, max(0.15, customSat ?? 0.5)) : palette.backdropSaturation
    }

    /// สองสีของฉากหลังหลังปรับความสว่างและโทนแล้ว
    ///
    /// ฝั่งสว่างไม่ได้ใช้สูตรเดียวกันแล้วดันค่าขึ้น — ปลายบนของสูตรเดิมจบที่ความสว่าง 0.57
    /// ซึ่งยังเป็นสีเทากลาง ไม่ใช่กระดาษ · และที่สำคัญกว่าคือ **ความอิ่มตัวต้องกลับทิศ**:
    /// พื้นมืดยิ่งสว่างยิ่งต้องลดสีลง ส่วนกระดาษยิ่งสว่างยิ่งต้องเหลือสีไว้นิดหนึ่ง
    /// ไม่งั้นมันจะเป็นสีขาวเปล่าที่ไม่มีบุคลิก
    var backdropColors: (top: Color, bottom: Color) {
        let hue = backdropHue, sat = backdropSat, b = brightness
        switch activeInk {
        case .night:
            return (
                Color(hue: hue, saturation: max(0, sat - b * 0.28), brightness: 0.05 + b * 0.52),
                Color(hue: hue, saturation: max(0, sat - b * 0.20), brightness: 0.015 + b * 0.22)
            )
        case .paper:
            // ขาวนวลไล่ลงเทาอ่อน — เก็บเฉดธีมไว้แค่พอให้ไม่ใช่ขาวโรงพิมพ์
            return (
                Color(hue: hue, saturation: 0.03 + sat * 0.04, brightness: 0.955 + b * 0.045),
                Color(hue: hue, saturation: 0.06 + sat * 0.07, brightness: 0.865 + b * 0.075)
            )
        case .mist:
            // อาบสีธีมชัดขึ้น แต่ยังสว่างพอให้หมึกเข้มอ่านสบาย
            return (
                Color(hue: hue, saturation: 0.09 + sat * 0.16, brightness: 0.945 + b * 0.05),
                Color(hue: hue, saturation: 0.20 + sat * 0.26, brightness: 0.815 + b * 0.10)
            )
        }
    }

    /// สีหมึกและโทเคนทั้งชุดของการ์ดใบนี้
    var inkStyle: InkStyle {
        guard activeInk.isLight else { return .night }
        // ถ่านที่อาบเฉดของธีมไว้ — mist อาบเข้มกว่าเพราะพื้นมันมีสีมากกว่า
        let charcoal = Color(hue: backdropHue,
                             saturation: activeInk == .mist ? 0.38 : 0.26,
                             brightness: activeInk == .mist ? 0.155 : 0.135)
        return InkStyle(ink: activeInk, base: charcoal)
    }

    /// สีเน้นบนพื้นการ์ด — ปรับตามหมึกเสมอ
    var accent: Color { activeInk.isLight ? rawAccent.onLightSurface() : rawAccent }
    var accentSoft: Color {
        activeInk.isLight ? rawAccent.onLightSurface(depth: 0.35) : rawAccentSoft
    }

    /// สีเน้นดิบของพาเลตต์ — จูนไว้สำหรับพื้นมืด
    /// ใช้ตรง ๆ ได้เฉพาะของที่วางบน "รูป" (มี scrim ดำรองอยู่แล้ว) เท่านั้น
    var rawAccent: Color {
        guard let h = customHue else { return palette.accent }
        return Color(hue: h, saturation: min(0.72, max(0.35, (customSat ?? 0.5) + 0.1)), brightness: 0.96)
    }
    var rawAccentSoft: Color {
        guard let h = customHue else { return palette.accentSoft }
        let shifted = (h + 0.04) - floor(h + 0.04)
        return Color(hue: shifted, saturation: min(0.5, max(0.25, customSat ?? 0.4)), brightness: 1.0)
    }
    /// ธีมเวอร์ชันสำหรับ **แผงเครื่องมือ** — บังคับหมึกกลางคืนเสมอ
    ///
    /// ทุกอย่างในชีตแต่งกับตู้ widget นั่งอยู่บนพื้นมืดคงที่ ไม่ใช่บนการ์ด
    /// ถ้าส่ง `theme` ตรง ๆ เข้าไป `accent` จะกลายเป็นสีเข้มสำหรับพื้นสว่าง
    /// แล้วปุ่มกับสไลเดอร์ในชีตจะจมหายไปกับพื้นมืด — และพรีวิว widget ในตู้
    /// ก็จะวาดด้วยหมึกกระดาษทั้งที่ฉากหลังของตู้เป็นสีเข้ม
    var toolTheme: CardTheme {
        var t = self
        t.ink = .night
        return t
    }

    var radius: CGFloat { corner.radius }
}

// MARK: - Backdrop

/// ฉากหลังของการ์ด
///
/// Liquid Glass จะสวยก็ต่อเมื่อมี "อะไรให้หักเห" อยู่ข้างหลัง พื้นสีเรียบทำให้กระจกดูตาย
/// จึงมีดวงแสงนวลอยู่เสมอในทุกแบบ ยกเว้นแบบ "สีเดียว" ที่ผู้ใช้เลือกความเรียบเอง
struct CardBackdrop: View {
    let theme: CardTheme
    @Environment(PhotoStore.self) private var photos: PhotoStore?

    var body: some View {
        // ต้องห่อด้วย overlay — ดวงแสงมี .frame(width: 440) ซึ่งใหญ่กว่าจอ
        // ถ้าวางตรง ๆ ใน ZStack ฉากหลังจะกว้าง 440pt แล้วดัน layout ทั้งแอปให้เลื่อนออกนอกจอ
        Rectangle()
            .fill(.clear)
            .overlay { layers }
            .clipped()
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var layers: some View {
        let c = theme.backdropColors
        ZStack {
            switch theme.backdrop {
            case .gradient:
                LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
                orbs(0.5)

            case .glow:
                // ฝั่งสว่างต้องไล่จากบนลงล่าง ไม่ใช่พื้นเดียวทับดวงแสง
                // เพราะดวงแสงบนกระดาษให้ความลึกไม่พอ พื้นจะแบนเป็นแผ่นเดียว
                if theme.activeInk.isLight {
                    LinearGradient(colors: [c.top, c.bottom], startPoint: .topLeading, endPoint: .bottom)
                } else {
                    c.bottom
                }
                orbs(1.0)

            case .solid:
                c.top

            case .photo:
                c.bottom
                if let bg = photos?.background {
                    // พื้นหลังที่ผู้ใช้อัปโหลดเอง — โชว์คมชัด แค่คลุม scrim ให้ตัวหนังสือบนการ์ดอ่านออก
                    Image(uiImage: bg)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .overlay(c.top.opacity(theme.activeInk.isLight ? 0.72 : 0.42))
                        .overlay(LinearGradient(colors: [.clear, c.bottom.opacity(0.5)],
                                                startPoint: .center, endPoint: .bottom))
                } else if let photos {
                    photos.image(0)
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 60, opaque: true)
                        .overlay(c.top.opacity(theme.activeInk.isLight ? 0.78 : 0.55))
                        .saturation(1.2)
                } else {
                    LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
                }
                orbs(0.35)
            }
        }
    }

    @ViewBuilder
    private func orbs(_ strength: Double) -> some View {
        // บนกระดาษ ดวงแสงกลายเป็น "รอยสีซึม" — ต้องเบาลงมาก ไม่งั้นอ่านเป็นคราบเปื้อน
        let k = theme.activeInk.isLight ? strength * 0.34 : strength
        ZStack {
            Circle()
                .fill(theme.accent.opacity(0.5 * k))
                .frame(width: 440, height: 440)
                .blur(radius: 140)
                .offset(x: -140, y: -240)
            Circle()
                .fill(theme.accentSoft.opacity(0.34 * k))
                .frame(width: 380, height: 380)
                .blur(radius: 150)
                .offset(x: 160, y: 280)
        }
    }
}
