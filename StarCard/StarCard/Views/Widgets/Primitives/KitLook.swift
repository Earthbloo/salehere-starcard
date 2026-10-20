// ชิ้นส่วนกลางที่ตัววาดผัง (SpecPainter) และหน้าจออื่นเรียกใช้ — ไม่ผูกกับ widget ตัวใด
import SwiftUI
import UIKit


// MARK: - ชุดห้าสไตล์ — วาดตาม Canva DAHXOY1w-iM หน้า 3–12
//
// ทุกใบเป็น **แผ่นของตัวเอง** (ม่วงสติกเกอร์ · ครีมนุ่ม · กรอบตาราง · กลางคืน · หน้าต่าง Mac)
// พื้น ขอบ มุม และสีมาจาก `KitConfig` ของชิ้น ไม่ใช่จาก `WidgetChrome`
//
// กติกาที่ใช้ทั้งไฟล์:
// - **ห้าสไตล์โชว์ข้อมูลชุดเดียวกัน** (ผู้ใช้ 12 ต.ค. 2569) — สไตล์กลางคืน/Mac ใน Canva ขาดบางช่อง
//   ที่นี่เติมให้ครบในภาษาของสไตล์นั้น
// - หัวข้อแก้คำ/ฟอนต์/สีได้ (`.note` ช่อง 1) · ข้อมูลจากระบบใช้ฟอนต์ข้อมูลของการ์ด (`CardTheme.dataFont`)
// - การ์ดถูก export เป็นรูป — ไม่มีปุ่มหรือไอคอนเครื่องมือที่ดูเหมือนกดได้ (แถบหน้าต่าง Mac เหลือแค่ไฟสามดวง)
// - **กรอบคือคอนเทนเนอร์แบบ auto layout** (ดูกติกาที่ `WidgetChrome`): กรอบสูง/กว้างขึ้น = แถว กล่อง
//   และรูปกินพื้นที่ที่ได้มา ไม่ใช่ปล่อยที่ว่างท้ายใบ · ตัวอักษรไม่ถูกบีบ · กรอบเตี้ยกว่าเนื้อหา =
//   ทั้งก้อนย่อลง (`ViewThatFits` ห้าขั้น) ไม่ใช่โดนตัดครึ่ง · กรอบแคบกว่าผัง = chrome ย่อทั้งก้อนให้

// MARK: หน้าตาที่คำนวณแล้วของชิ้นหนึ่ง

struct KitLook {
    let style: KitStyle
    let fill: KitFill
    let fillHex: String
    let bordered: Bool
    let borderHex: String
    let square: Bool
    /// พื้นใต้เนื้อหามืด — ตัดสินสีหมึกทั้งใบ
    let dark: Bool

    init(_ c: KitConfig, border: Bool, cardDark: Bool) {
        style = c.style
        fill = c.fill
        fillHex = c.fillColor
        bordered = border
        borderHex = c.borderColor
        square = c.corner == .square && border
        // กรอบตาราง: เนื้อหาอยู่บนการ์ดขาวด้านในเสมอ · โปร่ง = ตามพื้นการ์ด
        dark = c.style == .gingham ? false : (c.fill == .clear ? cardDark : KitColor.dark(c.fillColor))
    }

    var radius: CGFloat { square ? 3 : style.radius }
    var ink: Color { dark ? Color(white: 0.96) : Color(red: 0.08, green: 0.08, blue: 0.09) }
    var mut: Color { dark ? Color.white.opacity(0.6) : Color.black.opacity(0.52) }
    var borderColor: Color { Color(kitHex: borderHex) }

    /// สีตัวเลขเด่น — กลางคืนใช้สีขอบ · Mac ใช้น้ำเงินของระบบ · ที่เหลือใช้หมึก
    var accent: Color {
        switch style {
        // พื้นสว่าง + ขอบสีอ่อน (ฟ้านีออนบนเหลือง) = ตัวเลขอ่านไม่ออก → ใช้สีขอบเฉดเข้มแทน
        case .night: return bordered ? (dark || KitColor.lum(borderHex) < 0.5 ? borderColor : KitColor.shade(borderHex, -0.55))
                                     : (dark ? Color(kitHex: "#5AC8F0") : Color(kitHex: "#0E7FB0"))
        case .mac:   return dark ? Color(kitHex: "#6AA8FF") : Color(kitHex: "#2F6FE4")
        default:     return ink
        }
    }

    /// สีหัวข้อที่ระบบแนะนำ — ผู้ใช้เลือกทับได้ในแถบแก้ข้อความ
    var title: Color {
        switch style {
        case .gingham: return Color(red: 0.07, green: 0.07, blue: 0.07)
        case .cream:   return dark ? ink : Color(red: 0.17, green: 0.17, blue: 0.17)
        case .mac:     return dark ? Color(white: 0.9) : Color(white: 0.29)
        default:       return ink
        }
    }

    /// พื้นของแผ่น
    var background: AnyShapeStyle {
        switch fill {
        case .solid:    return AnyShapeStyle(Color(kitHex: fillHex))
        case .gradient: return AnyShapeStyle(LinearGradient(colors: [KitColor.shade(fillHex, 0.25), KitColor.shade(fillHex, -0.22)],
                                                            startPoint: .topLeading, endPoint: .bottomTrailing))
        case .clear:    return AnyShapeStyle(Color.clear)
        }
    }

    /// กล่องย่อยข้างในแผ่น — แต่ละสไตล์ตีความไม่เหมือนกัน
    var blockFill: Color {
        switch style {
        case .purple:  return .white
        case .cream:   return fill == .clear ? (dark ? .white.opacity(0.08) : .white.opacity(0.7))
                                             : (dark ? KitColor.shade(fillHex, 0.08) : KitColor.shade(fillHex, 0.55))
        case .gingham: return Color(white: 0.95)
        case .night:   return dark ? .white.opacity(0.035) : .black.opacity(0.04)
        case .mac:     return dark ? .white.opacity(0.08) : Color(white: 0.93)
        }
    }
    var blockLine: Color {
        switch style {
        case .night: return bordered ? borderColor.opacity(0.3) : (dark ? .white.opacity(0.1) : .black.opacity(0.1))
        default:     return .black.opacity(0.08)
        }
    }
    /// หมึกในกล่องย่อย — ม่วงสติกเกอร์มีกล่องขาวเสมอ หมึกในกล่องจึงเป็นถ่านทุกพื้น
    var blockInk: Color { style == .purple || style == .gingham ? Color(red: 0.08, green: 0.08, blue: 0.09) : ink }
    var blockMut: Color { style == .purple || style == .gingham ? Color.black.opacity(0.52) : mut }
    var hair: Color { dark ? .white.opacity(0.1) : .black.opacity(0.09) }
}


/// ไอคอนต่อสายงาน — 18 หมวดของฟอร์ม (`IntakeCatalog.interests`)
enum KitNiche {
    /// ตัดอีโมจิหน้าชื่อหมวด ("👗 แฟชั่น" → "แฟชั่น") — Canva แสดงคำล้วน ไอคอนมาจากสไตล์
    static func clean(_ c: String) -> String {
        let s = c.drop { ch in !(ch.isLetter && (ch.unicodeScalars.first.map { $0.value < 0x2000 } ?? false)) }
        return String(s).trimmingCharacters(in: .whitespaces)
    }
    static func symbol(_ raw: String) -> String {
        switch clean(raw) {
        case "บิวตี้": return "sparkles"
        case "แฟชั่น": return "tshirt"
        case "อาหาร & เครื่องดื่ม", "อาหาร": return "fork.knife"
        case "คาเฟ่": return "cup.and.saucer"
        case "ไลฟ์สไตล์": return "sun.max"
        case "ท่องเที่ยว": return "airplane"
        case "สุขภาพ & ออกกำลังกาย": return "figure.run"
        case "แม่และเด็ก": return "figure.and.child.holdinghands"
        case "สัตว์เลี้ยง": return "pawprint"
        case "เทคโนโลยี & แกดเจ็ต": return "iphone"
        case "เกม": return "gamecontroller"
        case "บ้าน & สวน": return "house"
        case "รถยนต์ & ยานยนต์": return "car"
        case "การเงิน & การลงทุน": return "banknote"
        case "การศึกษา": return "book"
        case "กีฬา": return "sportscourt"
        case "บันเทิง & ดารา": return "film"
        case "อีเวนต์ & กิจกรรม": return "party.popper"
        default: return "star"
        }
    }
}


/// แถวที่ขึ้นบรรทัดใหม่เองเมื่อเต็ม — ชิปจังหวัด/สายงาน
struct KitWrap: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, row: CGFloat = 0, w: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0 && x + s.width > maxW { x = 0; y += row + spacing; row = 0 }
            x += s.width + spacing; row = max(row, s.height); w = max(w, x - spacing)
        }
        return CGSize(width: min(w, maxW), height: y + row)
    }
    func placeSubviews(in b: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = b.minX, y = b.minY, row: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            // เผื่อเศษจากการปัดพิกเซล — ไม่งั้นชิ้นสุดท้ายที่พอดีเป๊ะหลุดลงบรรทัดใหม่แล้วโดนกรอบตัด
            if x > b.minX && x + s.width > b.maxX + 1 { x = b.minX; y += row + spacing; row = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing; row = max(row, s.height)
        }
    }
}
