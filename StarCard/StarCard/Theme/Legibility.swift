import SwiftUI
import UIKit

// MARK: - ตัวหนังสือต้องอ่านออกเสมอ
//
// # ปัญหา
//
// สีพื้นกับสีตัวหนังสือถูกเลือกคนละที่ คนละจังหวะ — สีพื้นเลือกในถาดพื้นหลัง (แถบสี · hex · รูป)
// สีตัวหนังสือเลือกเหนือแป้นพิมพ์ แล้วเจ้าของการ์ดก็กลับไปเปลี่ยนพื้นทีหลังได้ตลอด
// ไม่มีจังหวะไหนที่ใครเห็นทั้งสองอย่างคู่กัน ตัวหนังสือจึงกลืนไปกับพื้นได้เงียบ ๆ
// โดยเฉพาะหน้า 2–3 ที่ไม่ได้อยู่บนจอตอนเปลี่ยนสี
//
// # กติกาข้อเดียว: สีที่เลือกคือ "คำขอ" — ระบบส่งสีที่ใกล้ที่สุดที่ยังอ่านออก
//
// ท่าเดียวกับนาฬิกาบนหน้าล็อกของ iOS และ tone ของ Material You: **เก็บเฉดไว้ ขยับแค่ความสว่าง**
// เขียวยังเป็นเขียว แค่เข้มขึ้นหรืออ่อนลงจนตัดกับพื้น · เกณฑ์คือ contrast ของ WCAG
// (ตัวหนังสือทั่วไป 4.5:1 · ตัวใหญ่/ไอคอน 3:1)
//
// สิ่งที่ระบบ **ไม่แตะ**: สีพื้นที่ผู้ใช้เลือกเอง — hex ที่พิมพ์มาต้องได้เป๊ะ ตัวที่ขยับคือตัวหนังสือ
// ยกเว้นพื้นที่เป็นรูป ซึ่งตัวหนังสือสีเดียวสู้ทุกจุดของรูปไม่ได้ ตรงนั้นระบบคลุมม่านให้ (ดู `PhotoLuma`)

enum Legibility {
    /// ตัวหนังสือทั่วไป — WCAG AA
    static let body: Double = 4.5
    /// ตัวใหญ่ · ไอคอน · ของที่ต้องมองเห็นแต่ไม่ได้อ่านทีละตัว — WCAG AA ของตัวใหญ่
    static let large: Double = 3.0
    /// หมึกเต็มแรงบนรูป — ม่านถูกคำนวณให้ได้อย่างน้อยเท่านี้ในทุกช่องของรูป
    ///
    /// สูงกว่า `body` โดยตั้งใจ: ตัวหนังสือรองบนการ์ดคือหมึกโปร่ง ถ้าหมึกเต็มแรงได้แค่ 4.5
    /// ตัวรองจะไม่มีที่ให้ถอยเลย ต้องทึบเท่าตัวหลักหมด ลำดับชั้นของตัวหนังสือทั้งใบก็หายไป
    static let photo: Double = 6.0

    /// ช่วงพื้นที่ตัวหนังสือเชื่อได้บนรูป — หย่อนกว่า `photo` ราวหนึ่งในสิบ
    /// เผื่อดวงแสงที่ลอยทับม่าน กับเศษจากการเกลี่ยม่านให้เนียน
    static let photoBound: Double = photo * 0.9

    /// sRGB (0…1) → ความสว่างเชิงเส้น
    static func linear(_ v: Double) -> Double {
        let x = min(1, max(0, v))
        return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
    }

    /// ความสว่างเชิงเส้น → sRGB
    static func encoded(_ l: Double) -> Double {
        let x = min(1, max(0, l))
        return x <= 0.0031308 ? x * 12.92 : 1.055 * pow(x, 1 / 2.4) - 0.055
    }

    /// อัตราส่วน contrast ของ WCAG จากความสว่างสองค่า
    static func ratio(_ a: Double, _ b: Double) -> Double {
        (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// เกณฑ์ของตัวหนังสือตามน้ำหนักที่ widget ขอ (`ink.text(l)`)
    ///
    /// ตัวหลักกับตัวรองต้องได้ AA · ตัวจางมาก ๆ (ลำดับ · หมายเหตุท้ายบรรทัด) ได้เกณฑ์ตัวใหญ่
    /// ที่ต่ำกว่านั้นไม่ใช่ตัวหนังสือแล้ว (จุดคั่น · เงา) จึงไม่มีเกณฑ์
    static func target(emphasis l: Double) -> Double {
        switch l {
        case 0.4...:     return body
        case 0.28..<0.4: return large
        default:         return 1
        }
    }

    /// ความสว่างหลังวางสีความสว่าง `top` ทึบ `alpha` ทับพื้นความสว่าง `under`
    ///
    /// ผสมในพื้นที่ sRGB แบบเดียวกับที่ระบบวาดชั้นโปร่งทับกันจริง — ผสมแบบเชิงเส้นจะได้ตัวเลขที่สวยกว่าของจริง
    static func composite(_ top: Double, alpha: Double, over under: Double) -> Double {
        let a = min(1, max(0, alpha))
        return linear(encoded(under) * (1 - a) + encoded(top) * a)
    }

    /// ความทึบต่ำสุดของหมึกความสว่าง `ink` บนพื้นความสว่าง `ground` ที่ให้ contrast ถึง `target`
    ///
    /// คืน 1 เมื่อทึบเต็มที่แล้วก็ยังไม่ถึง — หมึกฝั่งนี้ได้เท่านี้จริง ๆ (การ์ดเลือกฝั่งที่ชนะไว้แล้ว ดู `CardTheme.activeInk`)
    static func alpha(ink: Double, over ground: Double, target: Double) -> Double {
        guard target > 1 else { return 0 }
        let g = encoded(ground), b = encoded(ink)
        guard abs(b - g) > 0.0001 else { return 1 }
        let goal: Double
        if ink > ground {
            goal = target * (ground + 0.05) - 0.05
            guard goal < ink else { return 1 }
        } else {
            goal = (ground + 0.05) / target - 0.05
            guard goal > ink else { return 1 }
        }
        return min(1, max(0, (encoded(goal) - g) / (b - g)))
    }
}

// MARK: - สีเป็นตัวเลข

/// สี sRGB สามช่อง (0…1) — คิด contrast ได้โดยไม่ต้องวนผ่าน `UIColor` ทุกครั้ง
struct RGB: Hashable {
    var r: Double
    var g: Double
    var b: Double

    init(r: Double, g: Double, b: Double) {
        self.r = min(1, max(0, r))
        self.g = min(1, max(0, g))
        self.b = min(1, max(0, b))
    }

    init(_ color: Color) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(r: Double(r), g: Double(g), b: Double(b))
    }

    /// จาก HSB แบบเดียวกับ `Color(hue:saturation:brightness:)` — ธีมเก็บสีพื้นเป็น HSB
    init(hue: Double, saturation s: Double, brightness v: Double) {
        let h6 = (hue - hue.rounded(.down)) * 6
        let s = min(1, max(0, s)), v = min(1, max(0, v))
        let c = v * s
        let x = c * (1 - abs(h6.truncatingRemainder(dividingBy: 2) - 1))
        let m = v - c
        switch Int(h6) {
        case 0:  self.init(r: c + m, g: x + m, b: m)
        case 1:  self.init(r: x + m, g: c + m, b: m)
        case 2:  self.init(r: m, g: c + m, b: x + m)
        case 3:  self.init(r: m, g: x + m, b: c + m)
        case 4:  self.init(r: x + m, g: m, b: c + m)
        default: self.init(r: c + m, g: m, b: x + m)
        }
    }

    static let white = RGB(r: 1, g: 1, b: 1)
    static let black = RGB(r: 0, g: 0, b: 0)

    /// ความสว่างที่ตารับรู้ (WCAG relative luminance)
    var luminance: Double {
        0.2126 * Legibility.linear(r) + 0.7152 * Legibility.linear(g) + 0.0722 * Legibility.linear(b)
    }

    var color: Color { Color(red: r, green: g, blue: b) }

    /// ไล่เข้าหาอีกสี `t` (0…1) — ผสมใน sRGB แบบเดียวกับที่ระบบวาดชั้นโปร่งทับกัน
    func mixed(with o: RGB, _ t: Double) -> RGB {
        RGB(r: r + (o.r - r) * t, g: g + (o.g - g) * t, b: b + (o.b - b) * t)
    }

    /// สีนี้ทึบ `alpha` วางทับสี `under`
    func over(_ under: RGB, alpha: Double) -> RGB { under.mixed(with: self, alpha) }

    /// สีเดิมที่ขยับความสว่างจนอ่านออกบน `ground` — ไม่ผ่านอยู่แล้วก็คืนตัวเดิม
    ///
    /// ลองทั้งสองทาง: สว่างขึ้น (ผสมขาว → พาสเทล) กับเข้มลง (ผสมดำ → เฉดเดิมที่ลึกขึ้น)
    /// ใช้ทางที่หมึกของการ์ดไป (`prefersLight`) ก่อน ถ้าทางนั้นไปไม่ถึงเกณฑ์แต่อีกทางถึงค่อยข้าม —
    /// สีเน้นบนการ์ดตัวขาวต้องสว่างขึ้นไปทางเดียวกับตัวหนังสือทั้งใบ ไม่งั้นการ์ดอ่านเป็นสองระบบสี
    /// พื้นกลาง ๆ ที่ไม่มีทางไหนถึง เลือกทางที่ได้มากกว่า
    func legible(on ground: InkGround, target: Double, prefersLight: Bool) -> RGB {
        guard ground.contrast(of: luminance) < target else { return self }
        let up = pushed(toward: .white, on: ground, target: target)
        let down = pushed(toward: .black, on: ground, target: target)
        let (first, second) = prefersLight ? (up, down) : (down, up)
        if first.contrast >= target { return first.color }
        if second.contrast >= target { return second.color }
        return first.contrast >= second.contrast ? first.color : second.color
    }

    /// ไล่เข้าหา `end` น้อยที่สุดเท่าที่ถึงเกณฑ์ — ไปสุดทางแล้วยังไม่ถึงก็คืนปลายทาง
    private func pushed(toward end: RGB, on ground: InkGround,
                        target: Double) -> (color: RGB, contrast: Double) {
        let full = ground.contrast(of: end.luminance)
        guard full >= target else { return (end, full) }
        // ระหว่างทาง contrast ตกก่อนแล้วค่อยขึ้น (ผ่านช่วงความสว่างของพื้น) — แต่ "ถึงเกณฑ์หรือยัง"
        // เป็นเท็จช่วงแรกแล้วจริงตลอดหลังจากนั้น จึงหาจุดเปลี่ยนแบบแบ่งครึ่งได้
        var lo = 0.0, hi = 1.0
        for _ in 0..<16 {
            let t = (lo + hi) / 2
            if ground.contrast(of: mixed(with: end, t).luminance) >= target { hi = t } else { lo = t }
        }
        let c = mixed(with: end, hi)
        return (c, ground.contrast(of: c.luminance))
    }
}

extension Color {
    /// สีนี้เวอร์ชันที่อ่านออกบนพื้น — ดู `RGB.legible`
    func legible(on ground: InkGround, target: Double = Legibility.body, prefersLight: Bool) -> Color {
        let c = RGB(self)
        let out = c.legible(on: ground, target: target, prefersLight: prefersLight)
        return out == c ? self : out.color
    }
}

// MARK: - พื้นใต้ตัวหนังสือ

/// ช่วงความสว่างของสิ่งที่อยู่ใต้ตัวหนังสือ — ตัวหนังสือบนการ์ดไปวางตรงไหนก็ได้ จึงต้องชนะทั้งช่วง
///
/// หมึกสว่างแพ้ที่จุด **สว่างสุด** ของพื้น · หมึกเข้มแพ้ที่จุด **มืดสุด** — สองค่านี้พอ ไม่ต้องรู้ทั้งภาพ
struct InkGround: Hashable {
    /// ความสว่างเชิงเส้น (WCAG) ของจุดที่มืดที่สุด
    var lo: Double
    /// ของจุดที่สว่างที่สุด
    var hi: Double

    init(lo: Double, hi: Double) {
        self.lo = min(lo, hi)
        self.hi = max(lo, hi)
    }

    init(_ tones: [RGB]) {
        let l = tones.map(\.luminance)
        self.init(lo: l.min() ?? 0, hi: l.max() ?? 0)
    }

    /// พื้นของแผงเครื่องมือ (มืดคงที่) — ค่าตั้งต้นของทุกอย่างที่ไม่ได้อยู่บนการ์ด
    static let stage = InkGround(lo: 0.002, hi: 0.03)

    /// contrast ที่แย่ที่สุดของสีทึบความสว่าง `lum` บนพื้นช่วงนี้ — อยู่ในช่วงเดียวกับพื้นคือ 1 (หายไปกับพื้นตรงไหนสักจุด)
    func contrast(of lum: Double) -> Double {
        if lum >= hi { return Legibility.ratio(lum, hi) }
        if lum <= lo { return Legibility.ratio(lum, lo) }
        return 1
    }

    /// พื้นเดียวกันหลังมีแผ่นสีความสว่าง `panel` ทึบ `alpha` วางทับ (แผ่นของ widget)
    func covered(by panel: Double, alpha: Double) -> InkGround {
        guard alpha > 0 else { return self }
        return InkGround(lo: Legibility.composite(panel, alpha: alpha, over: lo),
                         hi: Legibility.composite(panel, alpha: alpha, over: hi))
    }
}

// MARK: - รูปพื้นหลัง

/// สิ่งที่ม่านบนรูปต้องรู้ — มาจากธีม (ดู `CardTheme.photoVeil`)
struct PhotoVeil: Hashable {
    /// หมึกของการ์ดเป็นฝั่งสว่าง (ตัวขาว) — ม่านต้องกดจุดสว่างของรูปลง · ไม่งั้นต้องยกจุดมืดขึ้น
    var lightInk: Bool
    /// ความสว่างของหมึกเต็มแรง
    var ink: Double
    /// สีม่าน — สีบนของฉากหลังตามหมึก (เวทีมืด หรือกระดาษ)
    var color: RGB
    /// ความจางที่ผู้ใช้ตั้ง — ม่านบางกว่านี้ไม่ได้ทั้งภาพ
    var minimum: Double
    var target: Double = Legibility.photo
}

/// แผนที่ความสว่างของรูปพื้นหลัง — ตัดสินว่าม่านต้องหนาแค่ไหน ตรงไหน และหมึกฝั่งไหนเสียรูปน้อยกว่า
///
/// # ทำไมไม่ใช่ม่านเท่ากันทั้งผืน
///
/// ม่านเดิมทึบเท่ากันทั้งภาพตามแถบ "ความจาง" — รูปฟ้าขาวครึ่งบนตึกดำครึ่งล่างจึงมีสองทางเลือกที่แย่ทั้งคู่:
/// ม่านบางแล้วตัวขาวหายไปกับฟ้า หรือม่านหนาแล้วตึกกลายเป็นก้อนดำ · ม่านตัวนี้หนาเฉพาะช่องที่หมึกจะแพ้
/// ส่วนที่เหลือบางเท่าที่ผู้ใช้ตั้งไว้ รูปจึงยังเป็นรูป และตัวหนังสือไปวางตรงไหนก็อ่านออก
///
/// # ทำไมเก็บเป็นกริดในพิกัดของตัวรูป
///
/// ม่านที่ได้เป็นภาพสัดส่วนเดียวกับรูป วางทับด้วยกรอบเดียวกันแล้วตรงกันเป๊ะ
/// ไม่ว่ารูปจะถูกครอปเข้าการ์ดแนวตั้ง แถบสามหน้า หรือรูปย่อในคลัง — ไม่ต้องรู้เลยว่าจอวางรูปไว้ยังไง
struct PhotoLuma {
    /// ขนาดของรูปที่ย่อมาวัด (พิกเซล)
    let width: Int
    let height: Int
    /// จำนวนช่องของกริด
    let cols: Int
    let rows: Int
    /// ความสว่างของจุดที่สว่างที่สุดราวหนึ่งในสิบของแต่ละช่อง — จุดที่ตัวขาวแพ้
    ///
    /// ไม่ใช้ค่าสูงสุด เพราะแสงสะท้อนจุดเดียวในช่องจะลากม่านทั้งช่องให้หนาไปด้วยโดยไม่มีตัวหนังสือไหนได้ประโยชน์
    let hi: [Double]
    /// ของจุดที่มืดที่สุดราวหนึ่งในสิบ — จุดที่ตัวเข้มแพ้
    let lo: [Double]

    /// ด้านยาวของรูปที่ย่อมาวัด — ละเอียดพอเห็นลายของรูป (ใบไม้ · ตัวอักษรในรูป) แต่วัดเสร็จในเสี้ยวของเฟรม
    private static let long = 160
    /// ด้านของช่องหนึ่งช่อง (พิกเซลของรูปที่ย่อ)
    private static let cell = 8
    /// ม่านทึบได้มากสุดเท่านี้ — รูปต้องยังเหลือให้เห็นว่าเป็นรูป
    private static let ceiling = 0.92

    /// วัดรูปหนึ่งใบ — `blurred` คือรูปนี้จะถูกเบลอตอนวาด (เอฟเฟกต์ "เบลอ") จึงต้องเกลี่ยก่อนวัด
    static func measure(_ image: UIImage, blurred: Bool) -> PhotoLuma? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let k = CGFloat(long) / max(size.width, size.height)
        let w = max(cell, Int((size.width * k).rounded()))
        let h = max(cell, Int((size.height * k).rounded()))
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { return nil }
        // วาดผ่าน UIKit ไม่ใช่ `cgImage` ตรง ๆ — รูปจากกล้องส่วนใหญ่เก็บพิกเซลนอนแล้วบอกทิศไว้ในไฟล์
        // วัดจาก `cgImage` เมื่อไหร่ แผนที่จะหมุนไปคนละทางกับรูปที่การ์ดวาด แล้วม่านไปหนาผิดที่
        ctx.interpolationQuality = .medium
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(ctx)
        image.draw(in: CGRect(x: 0, y: 0, width: w, height: h))
        UIGraphicsPopContext()
        guard let data = ctx.data else { return nil }
        let px = data.bindMemory(to: UInt8.self, capacity: w * h * 4)

        let table = (0..<256).map { Legibility.linear(Double($0) / 255) }
        var lum = [Double](repeating: 0, count: w * h)
        for i in 0..<(w * h) {
            lum[i] = 0.2126 * table[Int(px[i * 4])]
                   + 0.7152 * table[Int(px[i * 4 + 1])]
                   + 0.0722 * table[Int(px[i * 4 + 2])]
        }
        if blurred {
            // เบลอของการ์ดราวห้าเปอร์เซ็นต์ของด้านสั้น — กล่องสองรอบใกล้เคียงเกาส์พอ
            let r = max(1, min(w, h) / 20)
            lum = boxBlur(boxBlur(lum, w, h, r), w, h, r)
        }

        let cols = (w + cell - 1) / cell, rows = (h + cell - 1) / cell
        var hi = [Double](repeating: 0, count: cols * rows)
        var lo = hi
        var bucket: [Double] = []
        bucket.reserveCapacity(cell * cell)
        for cy in 0..<rows {
            for cx in 0..<cols {
                bucket.removeAll(keepingCapacity: true)
                for y in (cy * cell)..<min(h, (cy + 1) * cell) {
                    for x in (cx * cell)..<min(w, (cx + 1) * cell) { bucket.append(lum[y * w + x]) }
                }
                bucket.sort()
                let n = bucket.count
                hi[cy * cols + cx] = bucket[min(n - 1, Int(Double(n) * 0.9))]
                lo[cy * cols + cx] = bucket[min(n - 1, Int(Double(n) * 0.1))]
            }
        }
        return PhotoLuma(width: w, height: h, cols: cols, rows: rows, hi: hi, lo: lo)
    }

    /// ความทึบของม่านในแต่ละช่อง — ทึบอย่างน้อย `minimum` ทั้งภาพ แล้วหนาขึ้นเฉพาะช่องที่หมึกจะแพ้
    func veil(_ spec: PhotoVeil) -> [Double] {
        // ความสว่างที่พื้นต้องไม่เกิน (หมึกขาว) หรือต้องไม่ต่ำกว่า (หมึกเข้ม) ถึงจะได้ contrast ตามเป้า
        let goal = spec.lightInk ? (spec.ink + 0.05) / spec.target - 0.05
                                 : spec.target * (spec.ink + 0.05) - 0.05
        let c = Legibility.encoded(goal)
        let v = Legibility.encoded(spec.color.luminance)
        var a = [Double](repeating: 0, count: cols * rows)
        for i in a.indices {
            let g = Legibility.encoded(spec.lightInk ? hi[i] : lo[i])
            var need = 0.0
            if spec.lightInk, g > c {
                need = v < c ? (g - c) / (g - v) : 1
            } else if !spec.lightInk, g < c {
                need = v > c ? (c - g) / (v - g) : 1
            }
            a[i] = min(Self.ceiling, max(spec.minimum, need))
        }
        return smoothed(a)
    }

    /// หมึกฝั่งไหนเสียรูปน้อยกว่า (−1…1) — บวก = รูปสว่าง หมึกเข้มต้องการม่านบางกว่า
    ///
    /// เทียบ "ม่านเฉลี่ยที่ต้องใช้" ของสองฝั่ง ไม่ใช่ความสว่างเฉลี่ยของรูป — รูปครึ่งฟ้าขาวครึ่งตึกดำ
    /// เฉลี่ยออกมากลาง ๆ ซึ่งบอกอะไรไม่ได้ แต่ม่านที่ต้องใช้บอกตรง ๆ ว่าฝั่งไหนต้องกลบรูปมากกว่า
    var lean: Double {
        let forWhite = veil(PhotoVeil(lightInk: true, ink: 1, color: RGB(r: 0.1, g: 0.1, b: 0.12), minimum: 0))
        let forDark = veil(PhotoVeil(lightInk: false, ink: 0.015, color: RGB(r: 0.95, g: 0.94, b: 0.92), minimum: 0))
        let n = Double(max(1, forWhite.count))
        return (forWhite.reduce(0, +) - forDark.reduce(0, +)) / n
    }

    /// ม่านเป็นภาพสีเดียวทั้งผืน ต่างกันแค่ความทึบ — ขนาดเท่ารูปที่ย่อมาวัด ยืดเต็มกรอบรูปพื้นหลังแล้วตรงกันพอดี
    ///
    /// ไล่ค่าระหว่างกึ่งกลางช่องเอง (bilinear) ก่อนส่งให้ SwiftUI ยืดต่อ — กริดดิบสิบกว่าช่องถูกยืดเต็มจอตรง ๆ
    /// จะเห็นเป็นลายข้าวหลามตัดของการยืดภาพเล็ก
    func veilImage(_ alpha: [Double], color: RGB) -> UIImage? {
        let w = width, h = height, cell = Double(Self.cell)
        guard alpha.count == cols * rows,
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let data = ctx.data
        else { return nil }
        let px = data.bindMemory(to: UInt8.self, capacity: w * h * 4)
        func axis(_ p: Int, _ count: Int) -> (Int, Int, Double) {
            let f = (Double(p) + 0.5) / cell - 0.5
            let i0 = min(count - 1, max(0, Int(f.rounded(.down))))
            return (i0, min(count - 1, i0 + 1), min(1, max(0, f - Double(i0))))
        }
        for y in 0..<h {
            let (y0, y1, ty) = axis(y, rows)
            for x in 0..<w {
                let (x0, x1, tx) = axis(x, cols)
                let top = alpha[y0 * cols + x0] * (1 - tx) + alpha[y0 * cols + x1] * tx
                let bottom = alpha[y1 * cols + x0] * (1 - tx) + alpha[y1 * cols + x1] * tx
                let a = top * (1 - ty) + bottom * ty
                let i = (y * w + x) * 4
                px[i]     = UInt8((color.r * a * 255).rounded())
                px[i + 1] = UInt8((color.g * a * 255).rounded())
                px[i + 2] = UInt8((color.b * a * 255).rounded())
                px[i + 3] = UInt8((a * 255).rounded())
            }
        }
        guard let cg = ctx.makeImage() else { return nil }
        return UIImage(cgImage: cg)
    }

    /// ขยายม่านออกหนึ่งช่องแล้วเกลี่ย — ตัวหนังสือที่คร่อมขอบช่องสว่างต้องได้ม่านเต็ม และขอบม่านต้องไม่เห็นเป็นขั้น
    ///
    /// ขยายก่อนเกลี่ยเสมอ: ช่องรอบช่องที่หนาที่สุดถูกยกขึ้นเท่ามันแล้ว การเกลี่ยจึงไม่กินยอดของมันลง
    private func smoothed(_ a: [Double]) -> [Double] {
        var grown = a
        for y in 0..<rows {
            for x in 0..<cols {
                var m = 0.0
                for yy in max(0, y - 1)...min(rows - 1, y + 1) {
                    for xx in max(0, x - 1)...min(cols - 1, x + 1) { m = max(m, a[yy * cols + xx]) }
                }
                grown[y * cols + x] = m
            }
        }
        let k = [1.0, 2.0, 1.0]
        var out = grown
        for y in 0..<rows {
            for x in 0..<cols {
                var s = 0.0, n = 0.0
                for j in -1...1 {
                    for i in -1...1 {
                        let yy = y + j, xx = x + i
                        guard yy >= 0, yy < rows, xx >= 0, xx < cols else { continue }
                        let wgt = k[j + 1] * k[i + 1]
                        s += grown[yy * cols + xx] * wgt
                        n += wgt
                    }
                }
                out[y * cols + x] = s / n
            }
        }
        return out
    }

    private static func boxBlur(_ v: [Double], _ w: Int, _ h: Int, _ r: Int) -> [Double] {
        var tmp = v, out = v
        for y in 0..<h {
            for x in 0..<w {
                var s = 0.0, n = 0.0
                for xx in max(0, x - r)...min(w - 1, x + r) { s += v[y * w + xx]; n += 1 }
                tmp[y * w + x] = s / n
            }
        }
        for y in 0..<h {
            for x in 0..<w {
                var s = 0.0, n = 0.0
                for yy in max(0, y - r)...min(h - 1, y + r) { s += tmp[yy * w + x]; n += 1 }
                out[y * w + x] = s / n
            }
        }
        return out
    }
}

// MARK: - เงากันจม

extension View {
    /// เงาสองชั้นรอบตัวอักษร — ชั้นในคมพอให้ขอบตัวอักษรตัดกับพื้น ชั้นนอกฟุ้งพอให้ลายของพื้นหายไปใต้ตัว
    ///
    /// ใช้กับสีที่ผู้ใช้เลือกเจาะจง (ขาว · ดำ) ซึ่งขยับสีไม่ได้ ไม่งั้นตัวเลือกนั้นก็หายไป
    /// — ท่าเดียวกับตัวหนังสือขาวบนวอลเปเปอร์สว่างของหน้าล็อก iOS
    @ViewBuilder
    func legibilityHalo(_ color: Color?, size: CGFloat) -> some View {
        if let color {
            self
                .shadow(color: color, radius: max(0.8, size * 0.035))
                .shadow(color: color.opacity(0.55), radius: max(2, size * 0.14))
        } else {
            self
        }
    }
}
