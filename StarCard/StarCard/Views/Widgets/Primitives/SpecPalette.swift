// ชิ้นส่วนกลางที่ตัววาดผัง (SpecPainter · AppRenderContext) เรียกใช้ — ไม่ผูกกับ widget ตัวใด
import SwiftUI

// MARK: - สีของผัง = 6 บทบาท × 3 พื้น (20 ต.ค. 2569 · WIDGET-SPEC.md §4)
//
// ผังเขียนแค่ชื่อบทบาท: `bg` `bg2` `ink` `ink2` `accent` `line` (+ `white` `black` `clear` `#hex` · `@ความทึบ`)
// "พื้น" บอกว่าบทบาทนั้นคิดจากสูตรไหน — `widget.on` = พื้นตั้งต้นของใบ · โหนด `on` = พื้นของโหนดนั้น
//
// ประวัติ: 40 ชื่อ (14 ต.ค.) → 6 ชื่อ × 6 พื้น (20 ต.ค. เช้า) → 6 ชื่อ × 3 พื้น (20 ต.ค. เย็น · ผู้ใช้: "ทำไมต้องแยก 6")
// พื้นสว่าง 4 แบบเดิม (กระดาษบรรณาธิการ · แผ่น Canva · กล่องสติกเกอร์ · กระดาษสแครปบุ๊ก) ต่างกันแค่สีกระดาษของตัวเอง
// ตอนนี้ทุกใบใช้กระดาษจากธีมเดียวกัน → สไตล์ใหม่ = JSON ล้วน ไม่มีสูตรสีต่อชุดให้เขียนในโค้ดอีก (= เพิ่ม widget ไม่ต้อง build)
// (`KitLook` `Pop` `ScrapTone` `Ed.skin` ไม่ถูกเรียกจากที่นี่แล้ว — ลบได้เมื่อไม่มีใครใช้)

/// พื้นที่ widget (หรือโหนด) นั่งอยู่
enum SpecSurface: String {
    /// การ์ดตรง ๆ — หมึกผ่านตัวยันความอ่านออกของธีม
    case card
    /// แผ่นสว่าง (กระดาษ/กล่องของใบ) — สีกระดาษจากธีม: คู่สี = สีอ่อนของคู่ · พาเลตต์ = ครีมอมเฉด
    case light
    /// แผ่นเข้มอิ่มสี (`PosterPlate`) — คู่สี = สีเข้มของคู่
    case dark
}

/// ค่าของชิ้น + ธีม ที่ทุกพื้นต้องใช้คิดสี — สร้างครั้งเดียวต่อชิ้น แล้วถาม `color(_:on:)` กี่ครั้งก็ได้
struct SpecPalette {
    let theme: CardTheme
    let ink: InkStyle
    let accent: Color
    /// พื้นตั้งต้นของใบ (`widget.on`)
    let base: SpecSurface
    /// ใบนี้ **ไม่ได้วาดแผ่นของตัวเอง** อยู่ตอนนี้ (พื้นผิว "ไม่มีพื้น"/กระจกของ chrome · หรือชุด Canva เลือก "โปร่ง")
    /// → ตัวหนังสือนั่งบนการ์ดตรง ๆ ต้องใช้หมึกของการ์ด ไม่ใช่หมึกของแผ่นที่ไม่มีอยู่ (20 ต.ค. 2569: "แนะนำตัว" บนการ์ดคู่สีหายทั้งใบ)
    let noSheet: Bool

    init(theme: CardTheme, ink: InkStyle, accent: Color, kit: KitConfig, border: Bool, surface: WidgetSurface,
         popSkin: PopSkin?, base: String?) {
        self.theme = theme; self.ink = ink; self.accent = accent
        self.base = base.flatMap(SpecSurface.init(rawValue:)) ?? .card
        noSheet = surface == .clear || surface == .pane || kit.fill == .clear
    }

    /// token → สี · `on` = พื้นของโหนด (nil = พื้นตั้งต้นของใบ)
    func color(_ token: String, on: String?) -> Color {
        var name = token
        var alpha: Double? = nil
        if let at = token.lastIndex(of: "@") {
            name = String(token[..<at]); alpha = Double(token[token.index(after: at)...])
        }
        // โหนดที่ระบุ `on` เอง = วัตถุที่วาดพื้นของมันแน่ ๆ (โพลารอยด์ ป้าย) → ใช้พื้นนั้นเสมอ
        // โหนดที่ไม่ระบุ = ตามใบ → ถ้าใบไม่ได้วาดแผ่นอยู่ ตกไปใช้หมึกการ์ด
        let explicit = on.flatMap(SpecSurface.init(rawValue:))
        let surface = explicit ?? base
        let c: Color
        switch name {
        case "white": c = .white
        case "black": c = .black
        case "clear": return .clear
        case "bg", "bg2", "ink", "ink2", "accent", "line":
            if explicit == nil && noSheet { return card(name, alpha) }
            switch surface {
            case .card:  return card(name, alpha)
            case .light: c = sheet(name, light: true)
            case .dark:  c = sheet(name, light: false)
            }
        default:
            c = name.hasPrefix("#") ? Color(hex: name) : .clear
        }
        return alpha.map { c.opacity($0) } ?? c
    }

    /// บนการ์ด ความทึบวิ่งผ่านตัวยันความอ่านออก — ค่าตั้งต้นของแต่ละบทบาทคือน้ำหนักที่ผังเคยเขียน
    private func card(_ role: String, _ a: Double?) -> Color {
        switch role {
        case "ink":    return ink.text(a ?? 1)
        case "ink2":   return ink.ghost(a ?? 0.5)
        case "line":   return ink.line(a ?? 0.12)
        case "bg2":    return ink.fill(a ?? 0.14)
        case "accent": return a.map { accent.opacity($0) } ?? accent
        default:       let p: Color = ink.isLight ? .white : Color(white: 0.08); return a.map { p.opacity($0) } ?? p   // bg
        }
    }

    /// แผ่นของใบ — สูตรเดียวทั้งสว่างและเข้ม ต่างกันแค่ว่า "กระดาษ" กับ "หมึก" เป็นสีไหนของธีม
    /// - สว่าง: กระดาษครีมอมเฉดของการ์ด (คู่สี = สีอ่อน · ขยับเข้าหาสีเข้ม 7% เมื่อการ์ดเองก็สว่าง ให้แผ่นแยกจากพื้น) · หมึกถ่านอมเฉด (คู่สี = สีเข้ม)
    /// - เข้ม: แผ่นอิ่มสี (`PosterPlate.plate`) · หมึกครีม (`PosterPlate.cream`) · สีเน้น = สีเน้นดิบ (บนแผ่นมืดต้องสด)
    private func sheet(_ role: String, light: Bool) -> Color {
        let paper: Color, ink: Color, accent: Color
        if light {
            if let l = theme.duoLight, let d = theme.duoDark {
                paper = l.mixed(with: d, by: theme.duoFlipped ? 0.07 : 0); ink = d; accent = d
            } else {
                paper = Color(hue: theme.backdropHue, saturation: 0.10, brightness: 0.97)
                ink = Color(hue: theme.backdropHue, saturation: 0.06, brightness: 0.11)
                accent = theme.rawAccent.onLightSurface()
            }
        } else {
            paper = PosterPlate.plate(theme); ink = PosterPlate.cream(theme); accent = theme.rawAccent
        }
        switch role {
        case "bg":     return paper
        case "bg2":    return paper.mixed(with: ink, by: 0.06)
        case "ink":    return ink
        case "ink2":   return ink.mixed(with: paper, by: 0.38)
        case "accent": return accent
        default:       return ink.opacity(0.2)   // line
        }
    }
}
