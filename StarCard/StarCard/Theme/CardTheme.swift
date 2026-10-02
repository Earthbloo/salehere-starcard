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
    /// พื้นใต้ตัวหนังสือ — ตัวหนังสือทุกระดับถูกยันให้อ่านออกบนพื้นช่วงนี้ (ดู `text`)
    private(set) var ground: InkGround
    /// ความสว่างของหมึกเต็มแรง — คิดครั้งเดียวตอนสร้าง ไม่ใช่ทุกครั้งที่ขอสีตัวหนังสือ
    private let baseLuminance: Double

    init(ink: CardInk, base: Color, ground: InkGround = .stage) {
        self.ink = ink
        self.base = base
        self.ground = ground
        self.baseLuminance = RGB(base).luminance
    }

    var isLight: Bool { ink.isLight }

    /// ตัวหนังสือ — `l` คือน้ำหนักชุดเดียวกับที่เคยเขียน `.white.opacity(l)`
    ///
    /// ความทึบที่ออกแบบไว้คือ **ขั้นต่ำของหน้าตา** ไม่ใช่ค่าตายตัว: บนเวทีมืดกับกระดาษขาว ค่าที่ออกแบบไว้
    /// ผ่านเกณฑ์อยู่แล้วเกือบทุกระดับ ตัวเลขแทบไม่ขยับ · แต่บนพื้นกลาง ๆ (แดงสดที่พิมพ์ hex มา · รูป)
    /// หมึกโปร่งครึ่งหนึ่งจมไปกับพื้น ตรงนั้นความทึบถูกดันขึ้นจนได้เกณฑ์ของระดับนั้น (ดู `Legibility.target`)
    /// — ลำดับชั้นของตัวหนังสือแคบลงบนพื้นแบบนั้น แต่ไม่มีบรรทัดไหนหาย
    func text(_ l: Double) -> Color {
        let designed = isLight ? min(0.94, pow(max(0, l), 0.85)) : l
        let needed = Legibility.alpha(ink: baseLuminance, over: isLight ? ground.lo : ground.hi,
                                      target: Legibility.target(emphasis: l))
        return base.opacity(min(1, max(designed, needed)))
    }

    /// หมึกชุดเดียวกันบนแผ่นของ widget — แผ่นเปลี่ยนพื้นใต้ตัวหนังสือ (กระจกกดพื้นลง · แผ่นจางยกพื้นขึ้น)
    /// - Parameters:
    ///   - panel: ความสว่างของสีแผ่น
    ///   - alpha: ความทึบของแผ่น
    func covered(by panel: Double, alpha: Double) -> InkStyle {
        var s = self
        s.ground = ground.covered(by: panel, alpha: alpha)
        return s
    }

    /// แผ่นที่ย้อมด้วยหมึกของการ์ดเอง (แผ่นเข้มบนกระดาษ)
    func coveredByInk(alpha: Double) -> InkStyle { covered(by: baseLuminance, alpha: alpha) }

    /// ตัวอักษร/สัญลักษณ์ที่ตั้งใจให้เป็นเงา — พื้นสว่างต้องจางกว่าพื้นมืดมาก
    /// ไม่งั้น "เงา" จะกลายเป็นเนื้อหาที่แย่งสายตา
    func ghost(_ l: Double) -> Color {
        guard isLight else { return base.opacity(l) }
        return base.opacity(l * 0.5)
    }

    /// เส้นผม · ขอบ
    func line(_ l: Double) -> Color {
        guard isLight else { return base.opacity(l) }
        return base.opacity(min(0.6, l * 0.8))
    }

    /// พื้นแผ่นบาง ๆ ที่ต้องแยกตัวจากฉากหลัง
    /// พื้นมืดแยกตัวด้วยการ "สว่างขึ้น" · พื้นสว่างแยกตัวด้วยการ "เข้มลง" — ความหมายเดียวกัน คนละทิศ
    func fill(_ l: Double) -> Color {
        guard isLight else { return base.opacity(l) }
        return base.opacity(min(0.5, l * 0.8))
    }

    /// ชั้นความสูง — พื้นมืดใช้แสง (เงาดำมองไม่เห็น) · พื้นสว่างใช้เงา (แสงมองไม่เห็น)
    /// เงาเป็น **ดำเสมอ** ไม่ใช่หมึกย้อมเฉด — หมึกของคู่สีเป็นสีจริง (กรมท่า · เลือดหมู)
    /// เงาที่ย้อมสีนั้นอ่านเป็นแสงสีที่สาดอยู่ใต้แผ่น ไม่ใช่ความสูงของแผ่น
    var lift: Color { isLight ? Color.black.opacity(0.18) : .clear }
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
    /// เรียงจากพื้นแบนไปหาพื้นที่มีของเยอะสุด — แถวชิปในแผงอ่านตามลำดับนี้
    /// คนที่อยากได้พื้นเรียบ ๆ เจอคำตอบที่ชิปแรกโดยไม่ต้องอ่านจนจบแถว
    case solid, gradient, grid, stripe, diamond, glow, marble, photo
    var id: String { rawValue }

    var name: String {
        switch self {
        case .gradient: return "ไล่เฉด"
        case .grid:     return "ตาราง"
        case .stripe:   return "ลายทาง"
        case .diamond:  return "ข้าวหลามตัด"
        case .glow:     return "ดวงแสง"
        case .solid:    return "สีเดียว"
        case .marble:   return "หินอ่อน"
        case .photo:    return "รูป"
        }
    }
    var icon: String {
        switch self {
        case .gradient: return "square.filled.and.line.vertical.and.square"
        case .grid:     return "grid"
        case .stripe:   return "rectangle.split.3x1.fill"
        case .diamond:  return "diamond.fill"
        case .glow:     return "sun.max.fill"
        case .solid:    return "square.fill"
        case .marble:   return "swirl.circle.righthalf.filled"
        case .photo:    return "photo.fill"
        }
    }
}

/// เอฟเฟกต์บนรูปพื้นหลัง
///
/// สามตัวหลังไม่ใช่ตัวกรองความสวยอย่างเดียว — มันคือเครื่องมือ **ลดเสียงของรูป**
/// รูปที่คนอัปโหลดมามีสีของมันเอง เต็มไปด้วยรายละเอียด แล้วการ์ดทั้งใบต้องไปยืนทับบนนั้น
/// ขาวดำตัดสีที่ชนกับธีมทิ้ง · เบลอตัดรายละเอียด · จุดปะตัดทั้งสองอย่างแล้วเหลือเป็นลาย
enum BackdropEffect: String, CaseIterable, Identifiable {
    case none, mono, blur, halftone
    var id: String { rawValue }

    var name: String {
        switch self {
        case .none:     return "ไม่มี"
        case .mono:     return "ขาวดำ"
        case .blur:     return "เบลอ"
        // ไม่ใช้คำว่า "ฮาล์ฟโทน" — ป้ายต้องบอกว่ากดแล้วเห็นอะไร ไม่ใช่ชื่อเทคนิคการพิมพ์
        case .halftone: return "จุดปะ"
        }
    }

    /// ต้องอบด้วย CoreImage ก่อนไหม — ที่เหลือเป็น modifier ของ SwiftUI ที่ทำสด ๆ ได้ทุกเฟรม
    var isBaked: Bool { self == .halftone }
}

struct CardTheme: Equatable {
    var palette: Palette = .midnight
    /// พื้นผิวของการ์ด — เลือกโดยเจ้าของการ์ด ไม่ล้อ dark mode ของเครื่องผู้ดู
    var ink: CardInk = .night
    /// ให้ระบบเลือกหมึกจากความสว่างของสีพื้น แทนที่จะใช้ `ink` ที่เก็บไว้
    ///
    /// เปิดช่อง hex ให้พิมพ์สีอะไรก็ได้เมื่อไหร่ "เลือกหมึกเอง" กลายเป็นกับดักทันที —
    /// พิมพ์ `#101010` ทับตอนที่หมึกเป็นกระดาษแล้วตัวหนังสือหายทั้งใบโดยไม่มีอะไรเตือน
    /// ค่าเริ่มต้นจึงเป็นอัตโนมัติ · แตะชิปโทนเมื่อไหร่คือผู้ใช้ขอคุมเอง แล้วค่านี้ถูกปิด
    /// (ไม่มีชิป "อัตโนมัติ" ในแผงแล้ว — มันเป็นสถานะตั้งต้นที่เงียบอยู่จนกว่าจะมีคนเลือกฝั่ง)
    var inkAuto: Bool = true
    var corner: CornerStyle = .round
    /// หน้าตาของแถบผู้ออกบัตรที่ขอบล่าง (ดู `IssuerStrip`) — ถอดไม่ได้ เลือกได้แค่แบบ
    var strip: StripStyle = .line
    var backdrop: BackdropStyle = .gradient
    /// คู่สีที่เลือกไว้ (ดู `ColorDuo`) — มีค่าเมื่อไหร่ **สีพื้นและสีหมึกมาจากคู่นี้ทั้งคู่**
    /// เก็บเป็นรหัสไม่ใช่สองสี เพราะคู่สีเป็นของที่ตั้งชื่อไว้แล้ว การ์ดจึงอ้างถึงมันได้ในหน้าอื่น
    var duoID: String? = nil
    /// สีไหนขึ้นเป็นพื้น — false = สีเข้มเป็นพื้น (ค่าตั้งต้น) · true = สีอ่อนเป็นพื้น
    var duoFlipped: Bool = false
    /// 0 = เข้มเกือบดำ · 1 = สว่าง
    var brightness: Double = 0.30
    /// เลื่อนเฉดพื้นหลังออกจากสีธีม −0.5…0.5 รอบวงล้อสี
    var hueShift: Double = 0

    /// โทนที่ดูดมาจากรูปพื้นหลังที่อัปโหลด — ตั้งแล้วทั้งธีมล้อตามรูปแทนพาเลตต์
    /// เลือกสีพาเลตต์เองเมื่อไหร่ค่านี้ถูกล้าง (ผู้ใช้ตัดสินใจ override)
    var customHue: Double? = nil
    var customSat: Double? = nil
    /// ความสว่างของสีพื้นที่ผู้ใช้เลือกเอง — **มีค่านี้เมื่อไหร่แปลว่าเป็นสีจริง ไม่ใช่แค่เฉด**
    ///
    /// สองตัวบนมาได้จากรูปที่อัปโหลด (`dominantTone` คืนแค่เฉดกับความสด) ซึ่งเป็นเพียง "โทน"
    /// ที่ยังต้องผ่านสูตรของหมึกอยู่ · ส่วนสีที่พิมพ์เป็น hex หรือลากจากแถบสีคือสีที่ผู้ใช้
    /// เห็นแล้วต้องได้แบบนั้นเป๊ะ ตัวนี้จึงเป็นตัวแยกสองกรณีออกจากกัน
    var customBri: Double? = nil

    /// เอฟเฟกต์บนรูปพื้นหลัง — มีผลเฉพาะตอน `backdrop == .photo`
    var photoEffect: BackdropEffect = .none
    /// แผ่นสีที่คลุมรูปไว้ 0…0.8 — ยิ่งมากรูปยิ่งจม ตัวหนังสือบนการ์ดยิ่งอ่านง่าย
    ///
    /// เดิมตรึงไว้ที่ 0.42 ซึ่งหนักพอที่ใส่เอฟเฟกต์ไปแล้วแทบไม่เห็นความต่าง — และมันเป็น
    /// การตัดสินใจแทนครีเอเตอร์ว่า "รูปของคุณสำคัญเท่านี้" ทั้งที่บางใบรูปคือพระเอก
    var photoDim: Double = 0.42
    /// รูปพื้นหลังเอียงไปทางสว่างแค่ไหน ในสายตาของตัวหนังสือ (−1…1) — บวก = หมึกเข้มเสียรูปน้อยกว่า
    ///
    /// วัดตอนเลือกรูปและตอนเปลี่ยนเอฟเฟกต์ (ดู `PhotoLuma.lean`) แล้วเก็บไว้กับธีม เพราะหมึกของทั้งการ์ด
    /// ต้องตัดสินได้จากธีมอย่างเดียว — widget ทุกตัว รูปที่ส่งออก รูปย่อในคลัง ไม่มีใครถือรูปพื้นหลังอยู่ในมือ
    /// nil = ยังไม่เคยวัด (ไฟล์รุ่นก่อน) ถือเป็นรูปมืดแบบเดิม
    var photoLean: Double? = nil
    /// ธีมนี้ถูกวาดบนแผงเครื่องมือ (พื้นมืดคงที่) ไม่ใช่บนการ์ด — ดู `toolTheme` · ไม่ถูกเซฟ
    var onStage = false

    /// สีพื้นที่ผู้ใช้เลือกเอง แยกเป็นสามค่า — nil เมื่อสียังมาจากพาเลตต์หรือโทนของรูป
    ///
    /// ความสดไม่ผ่าน `backdropSat` ที่บีบไว้ 0.15…0.6 — เพดานนั้นมีไว้กันโทนที่ดูดจากรูป
    /// ไม่ให้ฉูดฉาดเกินการ์ด แต่สีที่พิมพ์มาเองต้องได้แดง `#F11717` เต็ม ๆ ตามที่พิมพ์
    private var customParts: (h: Double, s: Double, b: Double)? {
        guard let bri = customBri, customHue != nil else { return nil }
        return (backdropHue, min(1, max(0, customSat ?? 0.5)), min(1, max(0, bri)))
    }

    /// มีสีพื้นที่ผู้ใช้เลือกเองอยู่ไหม
    var hasCustomColor: Bool { customParts != nil }

    /// คู่สีที่เลือกไว้ — nil เมื่อการ์ดใบนี้ยังใช้พาเลตต์หรือสีที่ตั้งเอง
    var duo: ColorDuo? { duoID.flatMap(ColorDuo.find) }

    /// สองสีที่ **มีผลจริง** ตอนนี้ — พื้นเป็นรูปเมื่อไหร่คู่สีถอยให้รูปทั้งคู่
    ///
    /// รูปที่อัปโหลดมาสว่างตรงไหนมืดตรงไหนคุมไม่ได้ หมึกสีครีมบนรูปจึงไม่มีอะไรรับประกันว่าอ่านออก
    /// เหมือนกับที่ `activeInk` บังคับกลางคืนตรงนั้น — คู่สีไม่หาย แค่รอจนกว่าพื้นจะกลับมาเป็นสี
    var duoColors: (bg: Color, ink: Color)? {
        guard let d = activeDuo else { return nil }
        return duoFlipped ? (d.light, d.dark) : (d.dark, d.light)
    }

    /// คู่สีที่มีผลจริงตอนนี้ (ดู `duoColors` สำหรับเหตุผลเรื่องพื้นรูป)
    var activeDuo: ColorDuo? { backdrop == .photo ? nil : duo }

    /// สองสีของคู่ **ตามบทบาทถาวร** ไม่ขึ้นกับว่าฝั่งไหนขึ้นเป็นพื้นอยู่
    ///
    /// แผ่นทึบของ widget ต้องเข้มเสมอและหมึกบนแผ่นต้องสว่างเสมอ ไม่ว่าการ์ดจะพลิกข้างไปทางไหน —
    /// ถ้าผูกกับ `duoColors` แผ่นจะกลายเป็นครีมบนการ์ดครีมแล้วหายไปทั้งใบ
    var duoDark: Color? { activeDuo?.dark }
    var duoLight: Color? { activeDuo?.light }

    /// เลือกคู่สี — ล้างสีที่ตั้งเองทิ้ง เพราะสองอย่างนี้ตอบคำถามเดียวกัน (พื้นสีอะไร) คนละคำตอบ
    ///
    /// ขึ้นข้างที่ตรงกับโทนของการ์ดตอนนั้น: การ์ดกระดาษที่ลองคู่สีดูต้องได้พื้นสีอ่อนของคู่นั้น
    /// ไม่ใช่กระโดดเป็นพื้นมืดแล้วให้ผู้ใช้ไปหาทางกดกลับเอง — เขาเปลี่ยนแค่ "สีอะไร" ไม่ได้เปลี่ยน
    /// ว่าการ์ดใบนี้มืดหรือสว่าง · อยากสลับข้างค่อยใช้แถวโทนซึ่งอยู่ใต้แถวคู่สีอยู่แล้ว
    mutating func setDuo(_ d: ColorDuo) {
        let wasLight = activeInk.isLight
        customHue = nil
        customSat = nil
        customBri = nil
        duoID = d.id
        duoFlipped = wasLight
    }

    /// สีที่ผู้ใช้เลือกเองตอนนี้ (HSB) — แผงใช้จำไว้เป็น "สีของฉัน" ก่อนสลับไปสีสำเร็จรูป
    var customColor: (h: Double, s: Double, b: Double)? { customParts }

    /// ความสว่างที่ตารับรู้ของสีพื้น (0…1 ตามสูตร WCAG) — nil เมื่อยังไม่มีสีที่เลือกเอง
    private var customLuminance: Double? {
        guard let p = customParts else { return nil }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(Color(hue: p.h, saturation: p.s, brightness: p.b))
                .getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        func lin(_ v: CGFloat) -> Double {
            let x = Double(max(0, min(1, v)))
            return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    }

    /// หมึกที่ใช้จริง — **พื้นหลังเป็นรูปเมื่อไหร่ บังคับกลางคืนเสมอ**
    ///
    /// รูปพื้นหลังเป็นภาพอะไรก็ได้ สว่างตรงไหนมืดตรงไหนคุมไม่ได้ หมึกเข้มบนกระดาษ
    /// จึงไม่มีทางรับประกันว่าอ่านออก ส่วนหมึกกลางคืนมี scrim ของตัวเองรองอยู่แล้วทุกชั้น
    /// เก็บค่าที่ผู้ใช้เลือกไว้ใน `ink` ตามเดิม — เปลี่ยนฉากหลังกลับเมื่อไหร่ได้โทนเดิมคืน
    ///
    /// โหมดอัตโนมัติไม่ได้ใช้เกณฑ์ตายตัวว่า "สว่างเกินเท่านี้คือกระดาษ" — มันคำนวณ contrast
    /// ของหมึกทั้งสองฝั่งกับพื้นจริงแล้วเลือกฝั่งที่ชนะ · สีกลาง ๆ อย่างแดงสดคือจุดที่เกณฑ์
    /// ตายตัวตัดสินผิดบ่อยที่สุด เพราะมันไม่สว่างพอจะเป็นกระดาษและไม่มืดพอจะเป็นเวทีมืด
    var activeInk: CardInk {
        if backdrop == .photo { return .night }
        // คู่สีตอบคำถามนี้ไปแล้วในตัวมันเอง: พื้นสว่างกว่าหมึก = ฝั่งสว่าง · ไม่ต้องเดาจากเกณฑ์ไหน
        if let c = duoColors {
            return RGB(c.bg).luminance > RGB(c.ink).luminance ? lightInk : .night
        }
        // ผู้ใช้เลือกได้แค่สองฝั่ง (มืด · สว่าง) — ฝั่งสว่างยังแยกกระดาษ/ใสใสตามความสดของพื้นเอง
        guard inkAuto else { return ink.isLight ? lightInk : .night }
        guard let l = customLuminance else { return .night }
        let withWhiteInk = 1.05 / (l + 0.05)
        // หมึกฝั่งสว่างเป็นถ่านที่อาบสีธีม ไม่ใช่ดำสนิท — ความสว่างของมันราว 0.02
        let withDarkInk = (l + 0.05) / 0.07
        guard withDarkInk > withWhiteInk else { return .night }
        return lightInk
    }

    /// หน้าตาของฝั่งสว่าง — พื้นที่ยังมีสีอยู่มากต้องได้ถ่านที่อาบเฉดเดียวกัน
    /// ไม่งั้นตัวหนังสือลอยหลุดออกจากพื้น · แถวโทนจึงไม่ต้องถามคำถามนี้กับผู้ใช้
    var lightInk: CardInk { (customSat ?? 0) >= 0.35 ? .mist : .paper }

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
        // สีที่ผู้ใช้เลือกเองไม่ผ่านสูตรของหมึก — ผ่านเมื่อไหร่ `#101010` จะถูกดันขึ้นมาเป็นเทา
        // และเม็ดสีในแผงกับพื้นการ์ดจะบอกคนละสีกัน ซึ่งเป็นจุดที่คนเลิกเชื่อช่อง hex
        // คู่สีคือสีจริงที่เลือกมาแล้ว ห้ามผ่านสูตรไหนทั้งนั้น — ปลายล่างจึงเป็นแค่เงาของสีเดียวกัน
        // เข้มลงเสมอ ไม่ใช่ผสมหมึกเข้าไป ไม่งั้นคู่สีสองสีจะกลายเป็นสามสีบนการ์ดใบเดียว
        if let c = duoColors {
            let inkDarker = RGB(c.ink).luminance < RGB(c.bg).luminance
            return (c.bg, inkDarker ? c.bg.mixed(with: c.ink, by: 0.10)
                                    : c.bg.mixed(with: .black, by: 0.26))
        }
        if let p = customParts {
            return (Color(hue: p.h, saturation: p.s, brightness: p.b),
                    // ปลายล่างเข้มลงเล็กน้อยพอให้ไล่เฉดยังมีทิศทาง แต่ยังอ่านเป็นสีเดียวกัน
                    Color(hue: p.h, saturation: min(1, p.s * 1.06), brightness: p.b * 0.80))
        }
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

    /// สีของแถบในฉากหลังแบบ "ลายทาง" — เฉดเดียวกับพื้น ต่างกันแค่หนึ่งขั้นความสว่าง
    ///
    /// พื้นเข้มได้แถบที่สว่างขึ้นในเฉดเดิม (เบอร์กันดีบนเบอร์กันดี) ไม่ใช่ขาวโปร่งที่ทำให้สีหม่น
    /// พื้นสว่างได้แถบที่เข้มลงในเฉดเดิม (ครีมบนขาว · ฟ้าบนฟ้าอ่อน)
    var stripeInk: Color {
        if let c = duoColors { return c.ink.opacity(0.10) }
        let h = backdropHue
        switch activeInk {
        case .night:
            return Color(hue: h, saturation: min(1, backdropSat + 0.1), brightness: 0.85).opacity(0.10)
        case .paper:
            return Color(hue: h, saturation: 0.22, brightness: 0.58).opacity(0.13)
        case .mist:
            return Color(hue: h, saturation: 0.40, brightness: 0.55).opacity(0.14)
        }
    }

    /// สีหมึกและโทเคนทั้งชุดของการ์ดใบนี้
    var inkStyle: InkStyle {
        // หมึกของคู่สีคือสีที่สองของคู่ตรง ๆ — ทั้งตัวหนังสือ เส้น แผ่น ใช้สีนี้หมดทั้งใบ
        if let c = duoColors { return InkStyle(ink: activeInk, base: c.ink) }
        guard activeInk.isLight else { return .night }
        // ถ่านที่อาบเฉดของธีมไว้ — mist อาบเข้มกว่าเพราะพื้นมันมีสีมากกว่า
        let charcoal = Color(hue: backdropHue,
                             saturation: activeInk == .mist ? 0.38 : 0.26,
                             brightness: activeInk == .mist ? 0.155 : 0.135)
        return InkStyle(ink: activeInk, base: charcoal)
    }

    /// สีเน้นบนพื้นการ์ด — ปรับตามหมึกเสมอ
    /// สีเน้นบนพื้นการ์ด — ปรับตามหมึกเสมอ
    ///
    /// คู่สีไม่มี "สีที่สาม" ให้เน้น — งานสองสีเน้นด้วยหมึกสีเดียวกับตัวหนังสือ แล้วไปเล่นที่ขนาด
    /// กับน้ำหนักแทน · ใส่สีเน้นของพาเลตต์เข้าไปเมื่อไหร่ คู่สีที่อุตส่าห์จับมาก็พังตรงนั้น
    var accent: Color {
        if let c = duoColors { return c.ink }
        return activeInk.isLight ? rawAccent.onLightSurface() : rawAccent
    }
    var accentSoft: Color {
        if let c = duoColors { return c.ink.mixed(with: c.bg, by: 0.34) }
        return activeInk.isLight ? rawAccent.onLightSurface(depth: 0.35) : rawAccentSoft
    }

    /// สีเน้นดิบของพาเลตต์ — จูนไว้สำหรับพื้นมืด
    /// ใช้ตรง ๆ ได้เฉพาะของที่วางบน "รูป" (มี scrim ดำรองอยู่แล้ว) เท่านั้น
    var rawAccent: Color {
        // คู่สี: ตัวดิบคือ **สีอ่อนของคู่เสมอ** ไม่ใช่หมึกของการ์ด
        //
        // ของที่เรียกตัวนี้นั่งอยู่บนรูปที่มี scrim ดำ หรือบนแผ่นเข้มของ widget — สองที่ที่มืดแน่นอน
        // ส่งหมึกของการ์ดไปเมื่อไหร่ การ์ดโทนสว่างจะได้ตัวเข้มไปวางบนแผ่นเข้ม แล้วมันหายไปทั้งบรรทัด
        if let d = activeDuo { return d.light }
        guard let h = customHue else { return palette.accent }
        return Color(hue: h, saturation: min(0.72, max(0.35, (customSat ?? 0.5) + 0.1)), brightness: 0.96)
    }
    var rawAccentSoft: Color {
        if let d = activeDuo { return d.light.mixed(with: d.dark, by: 0.30) }
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
        // ต้องปิดโหมดอัตโนมัติด้วย ไม่งั้นการ์ดที่ตั้งสีพื้นสว่างไว้จะลากหมึกกระดาษเข้ามาในชีต
        // ทั้งที่ชีตนั่งอยู่บนพื้นมืดคงที่ — บรรทัดบนจะถูกคำนวณทับทันทีที่อ่านค่า
        t.inkAuto = false
        // คู่สีที่วางสีอ่อนไว้เป็นพื้นจะลากหมึกเข้มเข้ามาในชีตที่พื้นมืดคงที่ — สลับข้างให้เฉพาะในชีต
        // (ไม่ล้างคู่สีทิ้ง ไม่งั้นพรีวิว widget ในตู้จะกลับไปเป็นสีพาเลตต์ ไม่ใช่สีของการ์ดใบนี้)
        if let c = t.duoColors, RGB(c.bg).luminance > RGB(c.ink).luminance {
            t.duoFlipped.toggle()
        }
        return t
    }

    var radius: CGFloat { corner.radius }
}

// MARK: - สีพื้นเป็นเลขฐานสิบหก

extension CardTheme {
    /// สีพื้นตอนนี้แยกเป็น HSB — ตัวเลือกสีเปิดมาต้องชี้ที่สีจริงบนการ์ด ไม่ใช่ค่าตั้งต้น
    ///
    /// อ่านจาก `backdropColors.top` ไม่ใช่จาก `customHue`/`customSat` ตรง ๆ เพราะการ์ดที่
    /// ยังใช้สีพาเลตต์อยู่ก็ต้องตอบได้ว่าตอนนี้พื้นสีอะไร — ไม่งั้นแตะเปิดตัวเลือกสีครั้งแรก
    /// แถบจะกระโดดไปสีอื่นก่อนผู้ใช้ทันได้แตะอะไรเลย
    var backdropHSB: (h: Double, s: Double, b: Double) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(backdropColors.top).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        else { return (backdropHue, 0.5, 0.5) }
        return (Double(h), Double(s), Double(b))
    }

    /// สีพื้นตอนนี้ในรูป `#RRGGBB` — ป้ายบนเม็ดสีของแผง
    var backdropHex: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(backdropColors.top).getRed(&r, green: &g, blue: &b, alpha: &a)
        else { return "#000000" }
        return String(format: "#%02X%02X%02X",
                      Int(round(max(0, min(1, r)) * 255)),
                      Int(round(max(0, min(1, g)) * 255)),
                      Int(round(max(0, min(1, b)) * 255)))
    }

    /// ตั้งสีพื้นจาก HSB — ทางเข้าเดียวของทั้งแถบสีและช่อง hex
    ///
    /// เขียน `customHue` โดยหัก `hueShift` ออกก่อน เพราะ `backdropHue` จะบวกกลับเข้าไปทีหลัง
    /// ถ้าไม่หัก การ์ดที่มาจากเทมเพลตซึ่งตั้ง `hueShift` ไว้จะได้สีเพี้ยนไปจากที่พิมพ์
    mutating func setBackdropColor(h: Double, s: Double, b: Double) {
        duoID = nil
        customHue = (h - hueShift) - floor(h - hueShift)
        customSat = min(1, max(0, s))
        customBri = min(1, max(0, b))
    }

    /// ล้างสีที่เลือกเอง กลับไปใช้สีของพาเลตต์
    mutating func clearBackdropColor() {
        duoID = nil
        customHue = nil
        customSat = nil
        customBri = nil
    }

    /// อ่านค่า `#RGB` หรือ `#RRGGBB` — คืน false เมื่ออ่านไม่ออก แล้วผู้เรียกคงสีเดิมไว้
    mutating func setBackdropHex(_ text: String) -> Bool {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "").uppercased()
        let digits: String
        switch raw.count {
        // ย่อสามหลักแบบ CSS — คนพิมพ์ `#FFF` แล้วคาดว่าจะได้ขาว ไม่ใช่ค่าที่อ่านไม่ออก
        case 3: digits = raw.map { "\($0)\($0)" }.joined()
        case 6: digits = raw
        default: return false
        }
        guard digits.allSatisfy(\.isHexDigit), let v = UInt32(digits, radix: 16) else { return false }
        let ui = UIColor(red: CGFloat((v >> 16) & 0xFF) / 255,
                         green: CGFloat((v >> 8) & 0xFF) / 255,
                         blue: CGFloat(v & 0xFF) / 255, alpha: 1)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return false }
        // สีเทาล้วนไม่มีเฉด — `getHue` คืน 0 ให้ ซึ่งจะกลายเป็นแดงทันทีที่ผู้ใช้ดันความสดขึ้น
        // เก็บเฉดเดิมของการ์ดไว้แทน ตัวสีที่ได้ยังเป็นเทาเหมือนที่พิมพ์เพราะความสดเป็น 0
        setBackdropColor(h: s < 0.004 ? backdropHue : Double(h),
                         s: Double(s), b: Double(b))
        return true
    }
}

// MARK: - Backdrop

/// ฉากหลังของการ์ด
///
/// Liquid Glass จะสวยก็ต่อเมื่อมี "อะไรให้หักเห" อยู่ข้างหลัง พื้นสีเรียบทำให้กระจกดูตาย
/// จึงมีดวงแสงนวลอยู่เสมอในทุกแบบ ยกเว้นแบบ "สีเดียว" ที่ผู้ใช้เลือกความเรียบเอง
struct CardBackdrop: View {
    let theme: CardTheme
    /// ตอนเรนเดอร์รูปแถบ 3 หน้า ไม่มี safe area ของจอ — อย่า ignore ไม่งั้นแผ่นจะไม่มีขนาด
    var ignoreSafeArea: Bool = true
    /// เซ็นมุมขวาล่างด้วยโลโก้ Sale Here ตัวโต (ดู `SignatureCorner`)
    ///
    /// **เปิดเฉพาะตอนเป็นฉากหลังของตัวการ์ด** — ฉากหลังตัวเดียวกันนี้ถูกใช้เป็นเวทีเต็มจอด้วย
    /// (คลัง · หน้าเลือกแบบ) เวทีมีลายน้ำลายซ้ำของมันเองอยู่แล้ว เซ็นซ้ำจะได้โลโก้สองขนาดในเฟรมเดียว
    var signed: Bool = false
    @Environment(PhotoStore.self) private var photos: PhotoStore?

    var body: some View {
        // ต้องห่อด้วย overlay — ดวงแสงมี .frame(width: 440) ซึ่งใหญ่กว่าจอ
        // ถ้าวางตรง ๆ ใน ZStack ฉากหลังจะกว้าง 440pt แล้วดัน layout ทั้งแอปให้เลื่อนออกนอกจอ
        let view = Rectangle()
            .fill(.clear)
            .overlay { layers }
            .clipped()
        if ignoreSafeArea {
            view.ignoresSafeArea()
        } else {
            view
        }
    }

    @ViewBuilder
    private var layers: some View {
        ZStack {
            fills
            // ชั้นบนสุดของ "พื้น" — ใต้ widget ทุกชิ้นเสมอ · ล้นขอบแผ่นแล้วโดน `.clipped()` ตัด
            // แบบปั๊มนูนวาดเหนือ widget (ดู `SignatureEmboss`) — ที่นี่จึงเว้นไว้ ไม่เซ็นสองครั้ง
            if signed, !theme.strip.isStamp {
                let ink = theme.inkStyle
                SignatureCorner(tint: ink.base, light: ink.isLight)
            }
        }
    }

    @ViewBuilder
    private var fills: some View {
        let c = theme.backdropColors
        ZStack {
            switch theme.backdrop {
            case .gradient:
                LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
                orbs(0.5)

            case .grid:
                // ไล่เฉดเดิม + เส้นตารางจาง ๆ แบบกระดาษกราฟ — พื้นของแผ่นสติกเกอร์ในไฟล์ดีไซน์
                // เส้นเป็นขาวโปร่งบนพื้นสว่าง / ขาวจางกว่าบนเวทีมืด ให้กระจกโปร่งของ widget มีอะไรให้เห็นทะลุ
                LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
                BackdropGrid(line: .white.opacity(theme.activeInk.isLight ? 0.55 : 0.09))
                orbs(0.35)

            case .stripe:
                // ลายทางสีเดียวกันสองเฉด (tone-on-tone) — วอลเปเปอร์/ผ้า ไม่ใช่ลายลูกกวาดตัดสี
                // ต่างกันแค่เฉดเดียว widget จึงยังเป็นพระเอก · เกล็ดกระดาษทำให้อ่านเป็นวัสดุ ไม่ใช่เวกเตอร์
                c.top
                BackdropStripes(band: theme.stripeInk)
                EdGrain(count: 2400, opacity: theme.activeInk.isLight ? 0.05 : 0.09,
                        tint: theme.activeInk.isLight ? .black : .white)

            case .diamond:
                // ข้าวหลามตัด (harlequin) — สูตรสีเดียวกับลายทาง: สองเฉดของสีเดียว
                c.top
                BackdropDiamonds(band: theme.stripeInk)
                EdGrain(count: 2400, opacity: theme.activeInk.isLight ? 0.05 : 0.09,
                        tint: theme.activeInk.isLight ? .black : .white)

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

            case .marble:
                // แผ่นหินเอียงเฉียง ไม่ใช่ไล่บนลงล่าง — หินขัดเป็นแผ่นที่แสงตกเฉียง
                // ไล่ตรง ๆ จะอ่านเป็นฉากหลังของแอปที่บังเอิญมีเส้น ไม่ใช่แผ่นหินที่วางอยู่
                LinearGradient(colors: [c.top, c.bottom],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                MarbleVeins(vein: theme.marbleInk.vein, bleed: theme.marbleInk.bleed)
                    .equatable()
                orbs(0.24)

            case .photo:
                c.bottom
                if let bg = photos?.background(theme.photoEffect) {
                    // พื้นหลังที่ผู้ใช้อัปโหลดเอง — โชว์คมชัด แค่คลุม scrim ให้ตัวหนังสือบนการ์ดอ่านออก
                    //
                    // ขาวดำกับเบลอทำสดตรงนี้ · จุดปะถูกอบมาแล้วตั้งแต่ใน `PhotoStore`
                    // เพราะ CoreImage ต่อเฟรมบนแผ่นเต็มจอแพงเกินกว่าจะทำระหว่างลาก widget
                    Image(uiImage: bg)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .grayscale(theme.photoEffect == .mono ? 1 : 0)
                        .blur(radius: theme.photoEffect == .blur ? 26 : 0, opaque: true)
                        .overlay(c.top.opacity(theme.photoDim))
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

/// แถบตั้งของฉากหลังแบบ "ลายทาง" — กว้างเท่ากันทั้งแถบสีและช่องว่าง
struct BackdropStripes: View {
    let band: Color
    var width: CGFloat = 15

    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            var x: CGFloat = width * 0.5
            while x < size.width {
                p.addRect(CGRect(x: x, y: 0, width: width, height: size.height))
                x += width * 2
            }
            ctx.fill(p, with: .color(band))
        }
        .allowsHitTesting(false)
    }
}

/// ลายบน **แผ่นทึบของ widget** — ผู้ใช้เลือกรายชิ้นในถาด (`WidgetInstance.pattern`)
///
/// ลายเป็น **เฉดเข้มของแผ่นเอง** ทึบทั้งชิ้น — tone-on-tone แบบวอลเปเปอร์ ไม่ใช่เส้นขาวจาง ๆ
/// ที่ทำให้แผ่นดูซีด · แผ่นใส (`.clear`) ไม่วาด เพราะไม่มีแผ่นให้ลาย
struct PlatePatternLayer: View {
    let sheet: Color
    @Environment(\.widgetPattern) private var pattern

    var body: some View {
        let band = sheet.mixed(with: .black, by: 0.5)
        if sheet != .clear {
            switch pattern {
            case .plain:   EmptyView()
            case .stripe:  BackdropStripes(band: band)
            case .diamond: BackdropDiamonds(band: band)
            }
        }
    }
}

/// ข้าวหลามตัดแบบ harlequin — ข้าวหลามตัดทึบวางบนตาราง แล้วช่องว่างระหว่างมันคือข้าวหลามตัดสีพื้น
/// สัดส่วนสูง:กว้าง ≈ 1.75 ตามลายตัวตลก/ไพ่ ที่แบนกว่านี้อ่านเป็นตารางเอียง
struct BackdropDiamonds: View {
    let band: Color
    var width: CGFloat = 42

    var body: some View {
        Canvas { ctx, size in
            let w = width, h = width * 1.75
            var p = Path()
            var y: CGFloat = 0
            while y <= size.height + h / 2 {
                var x: CGFloat = 0
                while x <= size.width + w / 2 {
                    p.move(to: CGPoint(x: x, y: y - h / 2))
                    p.addLine(to: CGPoint(x: x + w / 2, y: y))
                    p.addLine(to: CGPoint(x: x, y: y + h / 2))
                    p.addLine(to: CGPoint(x: x - w / 2, y: y))
                    p.closeSubpath()
                    x += w
                }
                y += h
            }
            ctx.fill(p, with: .color(band))
        }
        .allowsHitTesting(false)
    }
}

/// เส้นตารางของฉากหลังแบบ "ตาราง" — ระยะคงที่ในหน่วยออกแบบ ทุกเครื่องและไฟล์ที่ส่งออกได้ตารางถี่เท่ากัน
struct BackdropGrid: View {
    let line: Color
    var step: CGFloat = 22

    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            var x: CGFloat = 0
            while x <= size.width { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)); x += step }
            var y: CGFloat = 0
            while y <= size.height { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)); y += step }
            ctx.stroke(p, with: .color(line), lineWidth: 0.8)
        }
        .allowsHitTesting(false)
    }
}
