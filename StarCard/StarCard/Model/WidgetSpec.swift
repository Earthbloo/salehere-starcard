import Foundation
import CoreGraphics

// MARK: - ผังของ widget เป็นข้อมูล
//
// # ทำไมผังถึงย้ายจากโค้ดมาเป็นไฟล์
//
// ก่อนหน้านี้ผังของแต่ละใบอยู่ใน SwiftUI (`VStack` · `HStack` · `Spacer` · `minimumScaleFactor`)
// ซึ่ง Android กับ Web ต้องเขียนใหม่ด้วย layout engine ของตัวเอง ผลตรวจ 28 ก.ย. 2569 (81 ใบ)
// ได้ "เท่ากัน 4 · ต่าง 59" เพราะเราปล่อยให้เครื่องมือของแต่ละแพลตฟอร์มเป็นคนตัดสินใจ
//
// ผู้ใช้ (13 ต.ค. 2569): "ทุก Concept ทุก Widget ต้องเหมือนกัน เพื่อการสร้างที่ง่าย" และ
// "เวลา Resize กว้างยาวแล้ว Render เหมือนกัน 100%"
//
// กติกาใหม่: **ผัง = ไฟล์ JSON หนึ่งไฟล์ต่อชนิด** (ดู `shared/WidgetSpecs/`) · ตัวคำนวณกล่อง
// (`SpecSolver`) เป็นอัลกอริทึมเดียวที่ทุกแพลตฟอร์มต้อง port ให้ตรงด้วย fixture · ตัววาด
// (`SpecPainter`) รู้จักของไม่กี่อย่างและไม่ตัดสินใจอะไรเอง — มันแค่ทาตามตัวเลข
//
// สิ่งที่ widget *ไม่* ต้องรู้: ตัวเองกำลังถูกย่อหรือขยาย กว้างหรือแคบ — ผังประกาศล่วงหน้าแล้วว่า
// ถ้ามีที่เหลือใครได้ (`grow`) ถ้าแคบลงใครขึ้นบรรทัดใหม่ (`wrap`) ถ้าแคบกว่า N ชื่อใช้ขนาดไหน (`sizeWhen`)

/// แผนผังของ widget หนึ่งชนิด — ไฟล์ `shared/WidgetSpecs/<kind>.json`
struct WidgetSpec: Codable, Equatable {
    /// ชนิด (ตรงกับ `WidgetKind.rawValue`)
    var kind: String
    /// ขนาดอ้างอิงของผัง — กรอบที่ดีไซน์วาดไว้ · `WidgetChrome` ใช้คิดสเกล `s = min(W/w0, H/h0)`
    var design: SpecSize
    /// ผังราก
    var root: SpecNode
    /// หมายเหตุของผู้แปลง (ไม่ใช้ตอนวาด)
    var notes: String? = nil
    /// ผังทางเลือกตามรูปทรงกรอบ — เลือกใบแรกที่เงื่อนไขเป็นจริง ไม่มีก็ใช้ `root`
    var variants: [SpecVariant]? = nil
    /// ย่อทั้งก้อนเมื่อเนื้อหาสูงเกินกรอบ — ลองทีละขั้น (`[1, 0.9, 0.8 …]`) ใช้ขั้นแรกที่ความสูงตามเนื้อหาพอดี
    /// (ไม่พอดีสักขั้น = ขั้นสุดท้าย) · ตัววาด `scaleEffect` ทั้งก้อนด้วยค่านั้น — แบบ ViewThatFits ของโค้ดเดิม
    var fitScale: [Double]? = nil
    /// นิสัยของ widget (ตู้ · ถาด · พื้นผิว · ป้าย · ท่าเข้า) — มีบล็อกนี้ + หมวดที่แอปรู้จัก = ขึ้นในตู้
    var widget: Widget? = nil

    /// นิสัยของ widget ทั้งหมด — แอปไม่มีตารางชื่อ widget ในโค้ด อ่านจากตรงนี้อย่างเดียว (ดู WIDGET-SPEC.md §1.5)
    ///
    /// ทุกคีย์ไม่บังคับยกเว้น `title` · ไม่ใส่ = ค่าของหมวด (`WidgetFamily`) หรือกติกากลางที่เขียนไว้ที่คีย์นั้น
    struct Widget: Codable, Equatable {
        /// ชื่อในตู้
        var title: String
        /// หมวด = ชื่อ `WidgetFamily` — **ต้องเป็นหมวดที่แอปมีแล้ว** หมวดใหม่ = ยังไม่ขึ้นจนกว่าแอปจะเพิ่มหมวดในโค้ด
        var category: String? = nil
        /// SF Symbol ในตู้/แถบ
        var symbol: String? = nil
        /// ขนาดตอนวางลงการ์ด · ไม่ใส่ = `design`
        var size: SpecSize? = nil
        /// ลำดับในตู้ (น้อยขึ้นก่อน · ภายในหมวดเดียวกัน)
        var order: Int? = nil
        /// `verified` · `connected` · `personal` — ไม่ใส่ = ของหมวด
        var tier: String? = nil
        /// วาดพื้นของตัวเอง — chrome ไม่ครอบแผ่น
        var ownSurface: Bool? = nil
        /// วาดเส้นขอบของตัวเอง — chrome ไม่วาดเส้นซ้ำ
        var ownBorder: Bool? = nil
        /// ตัวเลือกพื้นผิวในถาด (ตัวแรก = ตั้งต้น) — ไม่ใส่: วาดพื้นเอง = ไม่มี · ไม่วาดเอง = `glass dim clear`
        var surfaces: [String]? = nil
        /// ชื่อตัวเลือกพื้นผิวที่ต่างจากชื่อกลาง เช่น `{"glass": "มีพื้น"}`
        var surfaceNames: [String: String]? = nil
        /// เส้นขอบตั้งต้น · ไม่ใส่ = มีเมื่อ chrome ครอบแผ่นให้ (`!ownSurface`)
        var border: Bool? = nil
        /// อัปโหลดรูปได้
        var photo: Bool? = nil
        /// ผังตายตัว — ความสูงต่ำสุดคือสัดส่วนที่ออกแบบไว้
        var keepAspect: Bool? = nil
        /// รูปชนขอบ ไม่เว้นระยะขอบใน
        var fullBleed: Bool? = nil
        /// ย่อขยายได้ · ไม่ใส่ = ได้
        var resize: Bool? = nil
        /// **ตัวเลือกทั้งหมดที่ผู้ใช้ปรับได้ในถาดของใบนี้** — ค่าที่เลือกเก็บที่ `WidgetInstance.options[opt]`
        /// ไม่มี = ไม่มีอะไรให้ปรับ (`options` ว่าง) · กติกาเดียวทุกใบ (19 ต.ค. 2569)
        var controls: [KitControl]? = nil
        /// ชุดห้าสไตล์ — หน้าตาของใบ (`look`) · สีพื้น/ขอบมาจากพื้นหลังการ์ด
        var kit: Kit? = nil
        /// วัสดุแผ่นสติกเกอร์ `paper` · `glass` (โทเคน `pop.*`)
        var skin: String? = nil
        /// ป้าย Verified by Sale Here — `followers` · `insight` · `work` · ไม่ใส่ = ไม่มีป้าย
        var stamp: String? = nil
        /// ใบที่ไม่มีช่องหัวข้อ — chrome วางป้ายมุมขวาบนด้านใน
        var stampAt: StampAt? = nil
        /// ท่าเข้า `deep` · `mid` · `light` · `anchored`
        var motion: String? = nil
        /// Sale Here วางให้ทุกการ์ด ตรึงก้นหน้า ลบ/ย้ายไม่ได้
        var pinned: Bool? = nil
        /// ชื่อชนิดเก่าที่ถอดแล้ว — การ์ดเก่าที่มีชื่อพวกนี้เปิดมาเป็นใบนี้
        var replaces: [String]? = nil

        struct StampAt: Codable, Equatable {
            var tone: String
            var top: Double
            var trailing: Double
        }

        struct Kit: Codable, Equatable {
            /// หน้าตาของใบนี้ — `purple` `cream` `gingham` `night` `mac` (สีพื้น/ขอบ/ตัวอักษรจากพื้นหลังการ์ด · ดู `KitStyle`)
            /// หนึ่งหน้าตา = หนึ่งชนิด (ผู้ใช้ 19 ต.ค. 2569) — ไม่ใช่ค่าที่เก็บในชิ้น
            var look: String? = nil
        }
    }
}

/// ตัวเลือกหนึ่งแถวในถาด (`widget.controls`) — ตัวควบคุมกลาง (ช่องติ๊ก · ตัวเลือก · สวิตช์ · − n +) ที่ทุกใบใช้
///
/// ค่าเก็บที่ `WidgetInstance.options[opt]` (ค่าตั้งต้น = ไม่เก็บ) · ช่องติ๊กเก็บสิ่งที่ **ซ่อน** (หรือธงแยกตาม `flags`)
struct KitControl: Codable, Equatable {
    /// `checks` · `pick` · `segment` · `switch` · `stepper`
    var type: String
    var label: String
    var opt: String? = nil
    /// รายการ — ชื่อแหล่งข้อมูลของหมวด (`socials` · `shownSocials` · `rates` · `ratePlatforms` · `categories`) หรือคู่ `[key, ชื่อ]`
    var items: Items? = nil
    /// `segment`: คู่ `[ค่า|null, ชื่อ]`
    var options: [[String?]]? = nil
    /// `segment`: ล้างตัวเลือกเหล่านี้เมื่อเปลี่ยน
    var clears: [String]? = nil
    /// `stepper`: ค่าที่เลือกได้
    var values: [Int]? = nil
    /// ค่าตั้งต้น (`switch` = true/false · `stepper` = ตัวเลข)
    var `default`: Value? = nil
    /// `checks`: เก็บเป็นธงแยกต่อรายการแทน `hide` เช่น `{"time": "noTime"}`
    var flags: [String: String]? = nil
    /// เงื่อนไข `opt:k=v` · `!opt:k=v` · `!hidden:key`
    var `if`: String? = nil
    /// false = ไม่จัดกรอบใหม่หลังแก้
    var refit: Bool? = nil
    /// โชว์แถวนี้เมื่อรายการมีอย่างน้อยเท่านี้ (ไม่ใส่ = โชว์เสมอ)
    var minItems: Int? = nil

    enum Items: Codable, Equatable {
        case source(String)
        case fixed([[String]])
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let s = try? c.decode(String.self) { self = .source(s) } else { self = .fixed(try c.decode([[String]].self)) }
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            switch self { case .source(let s): try c.encode(s); case .fixed(let a): try c.encode(a) }
        }
    }

    enum Value: Codable, Equatable {
        case bool(Bool), int(Int)
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let b = try? c.decode(Bool.self) { self = .bool(b) } else { self = .int(try c.decode(Int.self)) }
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            switch self { case .bool(let b): try c.encode(b); case .int(let i): try c.encode(i) }
        }
        var bool: Bool? { if case .bool(let b) = self { return b }; return nil }
        var int: Int? { if case .int(let i) = self { return i }; return nil }
    }
}

struct SpecSize: Codable, Equatable {
    var w: Double
    var h: Double
    var cg: CGSize { CGSize(width: w, height: h) }
}

/// ผังทางเลือก — เช่น `{"when": "ratio<0.6", "root": …}` สำหรับกรอบแนวนอนเตี้ย · หรือ `{"when": "cfg:style=mac", …}` ตามค่าของชิ้น
struct SpecVariant: Codable, Equatable {
    /// เงื่อนไขบนกรอบ (หน่วยออกแบบ): `ratio<0.6` · `w<260` · `h>400` (`ratio` = h/w) · หรือเงื่อนไขข้อมูลแบบเดียวกับ `if` · คั่นด้วย `&`
    var when: String
    var root: SpecNode
}

// MARK: - โหนด

/// ชนิดของโหนด — รายการปิด ทุกแพลตฟอร์มต้องรู้จักครบ
enum SpecType: String, Codable {
    /// คอนเทนเนอร์แนวตั้ง / แนวนอน / ซ้อนกัน
    case col, row, stack
    /// ข้อความช่องเดียว (ช่องของโปรไฟล์ · ข้อความของดีไซน์ · ค่าจากรายการ)
    case text
    /// รูปจากช่องรูปของชิ้น
    case image
    /// สี่เหลี่ยม (พื้น · เส้น · ไล่สี)
    case rect
    /// ไอคอน (ตรา · โลโก้ · Phosphor)
    case icon
    /// รายการชิ้นซ้ำ — วาด `each` ซ้ำตาม `list`
    case chips
    /// ที่ว่าง (ยืดตาม `grow`)
    case spacer
    /// เส้นคั่น
    case line
}

/// ความยาวของกล่อง — ตัวเลข (หน่วยออกแบบ) · `"72%"` (สัดส่วนของที่ว่างในแม่) · `"fill"` (กินที่ที่เหลือ) · `"hug"` (เท่าเนื้อหา)
enum SpecLength: Codable, Equatable {
    case pt(Double)
    case pct(Double)
    case fill
    case hug

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let d = try? c.decode(Double.self) { self = .pt(d); return }
        let s = try c.decode(String.self)
        switch s {
        case "fill": self = .fill
        case "hug":  self = .hug
        default:
            if s.hasSuffix("%"), let d = Double(s.dropLast()) { self = .pct(d) }
            else if let d = Double(s) { self = .pt(d) } else {
                throw DecodingError.dataCorruptedError(in: c, debugDescription: "bad length \(s)")
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .pt(let d):  try c.encode(d)
        case .pct(let d): try c.encode("\(d)%")
        case .fill:       try c.encode("fill")
        case .hug:        try c.encode("hug")
        }
    }
}

/// ระยะขอบใน — `8` · `[v, h]` · `[t, r, b, l]`
struct SpecInsets: Codable, Equatable {
    var top: Double = 0, right: Double = 0, bottom: Double = 0, left: Double = 0

    init(top: Double = 0, right: Double = 0, bottom: Double = 0, left: Double = 0) {
        self.top = top; self.right = right; self.bottom = bottom; self.left = left
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let d = try? c.decode(Double.self) { self.init(top: d, right: d, bottom: d, left: d); return }
        let a = try c.decode([Double].self)
        switch a.count {
        case 1: self.init(top: a[0], right: a[0], bottom: a[0], left: a[0])
        case 2: self.init(top: a[0], right: a[1], bottom: a[0], left: a[1])
        case 4: self.init(top: a[0], right: a[1], bottom: a[2], left: a[3])
        default: throw DecodingError.dataCorruptedError(in: c, debugDescription: "pad needs 1, 2 or 4 numbers")
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        if top == right && right == bottom && bottom == left { try c.encode(top) }
        else { try c.encode([top, right, bottom, left]) }
    }

    var h: Double { left + right }
    var v: Double { top + bottom }
}

/// การจัดในแกนขวาง (cross axis)
enum SpecAlign: String, Codable { case start, center, end, stretch }
/// การจัดในแกนหลัก (main axis)
enum SpecJustify: String, Codable { case start, center, end, between, around }

/// เส้นขอบ — `{"color": "line@0.16", "width": 0.6, "dash": [3, 2]}` (width ตั้งต้น 1)
struct SpecStroke: Codable, Equatable {
    var color: String
    var width: Double = 1
    var dash: [Double]? = nil

    init(color: String, width: Double = 1, dash: [Double]? = nil) { self.color = color; self.width = width; self.dash = dash }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        color = try c.decode(String.self, forKey: .color)
        width = try c.decodeIfPresent(Double.self, forKey: .width) ?? 1
        dash = try c.decodeIfPresent([Double].self, forKey: .dash)
    }
}

/// เงา — ระบุเป็น sigma (ไม่ใช่ radius ของแพลตฟอร์มใดแพลตฟอร์มหนึ่ง) · x/y ตั้งต้น 0 · สีตั้งต้น black@0.25
struct SpecShadow: Codable, Equatable {
    var sigma: Double
    var y: Double = 0
    var x: Double = 0
    var color: String = "black@0.25"

    init(sigma: Double, y: Double = 0, x: Double = 0, color: String = "black@0.25") { self.sigma = sigma; self.y = y; self.x = x; self.color = color }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sigma = try c.decode(Double.self, forKey: .sigma)
        y = try c.decodeIfPresent(Double.self, forKey: .y) ?? 0
        x = try c.decodeIfPresent(Double.self, forKey: .x) ?? 0
        color = try c.decodeIfPresent(String.self, forKey: .color) ?? "black@0.25"
    }
}

/// ไล่สี — `{"from": "accent", "to": "accent@0", "angle": 90}` (angle ตั้งต้น 90)
struct SpecGradient: Codable, Equatable {
    var from: String
    var to: String
    /// องศา — 0 = ซ้ายไปขวา · 90 = บนลงล่าง
    var angle: Double = 90

    init(from: String, to: String, angle: Double = 90) { self.from = from; self.to = to; self.angle = angle }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        from = try c.decode(String.self, forKey: .from)
        to = try c.decode(String.self, forKey: .to)
        angle = try c.decodeIfPresent(Double.self, forKey: .angle) ?? 90
    }
}

/// ลายพื้น — รายการปิด: `gingham` `stripes` `lines` `dots` `grid` `sprockets` `rings` `speckle` `barcode` `guilloche`
struct SpecPattern: Codable, Equatable {
    var kind: String
    var color: String = "ink@0.12"
    var color2: String? = nil
    /// ระยะซ้ำ (pt)
    var size: Double? = nil
    /// ความหนาเส้น/จุด
    var width: Double? = nil
    var angle: Double? = nil
    var opacity: Double? = nil

    init(kind: String, color: String = "ink@0.12") { self.kind = kind; self.color = color }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(String.self, forKey: .kind)
        color = try c.decodeIfPresent(String.self, forKey: .color) ?? "ink@0.12"
        color2 = try c.decodeIfPresent(String.self, forKey: .color2)
        size = try c.decodeIfPresent(Double.self, forKey: .size)
        width = try c.decodeIfPresent(Double.self, forKey: .width)
        angle = try c.decodeIfPresent(Double.self, forKey: .angle)
        opacity = try c.decodeIfPresent(Double.self, forKey: .opacity)
    }
}

/// เงื่อนไขเปลี่ยนขนาดตัวอักษรตามความกว้างของ **กล่องราก** (หน่วยออกแบบ) — ใบแรกที่จริงชนะ
struct SpecSizeRule: Codable, Equatable {
    /// `"w<260"` · `"w>=400"` · `"h<120"` · `"ratio<0.5"`
    var when: String
    var size: Double
}

/// โหนดหนึ่งตัวในผัง — ฟิลด์ทั้งหมดเป็น optional · ค่าว่าง = ค่าตั้งต้นตามชนิด
struct SpecNode: Codable, Equatable {
    var type: SpecType
    /// ชื่อไว้อ้างใน fixture/ดีบั๊ก (ไม่บังคับ)
    var id: String? = nil

    // MARK: กล่อง
    var w: SpecLength? = nil
    var h: SpecLength? = nil
    /// น้ำหนักกินที่ที่เหลือในแกนหลัก (0 = ไม่กิน) — `w/h: "fill"` เท่ากับ `grow: 1`
    var grow: Double? = nil
    /// ยอมหดเมื่อที่ไม่พอ (ค่าตั้งต้น: ข้อความ/คอนเทนเนอร์ = 1 · รูป/ไอคอน/สี่เหลี่ยมขนาดตายตัว = 0)
    var shrink: Double? = nil
    var minW: Double? = nil, maxW: Double? = nil, minH: Double? = nil, maxH: Double? = nil
    /// สัดส่วน กว้าง/สูง — ใส่แล้วแกนที่ไม่ได้ระบุคิดจากอีกแกน
    var aspect: Double? = nil
    var pad: SpecInsets? = nil
    var gap: Double? = nil
    /// การจัด **ลูก** ของคอนเทนเนอร์นี้ในแกนขวาง (ตั้งต้น stretch)
    var align: SpecAlign? = nil
    /// การจัด **ตัวเอง** ในแกนขวางของแม่ — ไม่ใส่ = ตาม `align` ของแม่
    var alignSelf: SpecAlign? = nil
    var justify: SpecJustify? = nil
    var wrap: Bool? = nil
    /// ใน `stack`: ตำแหน่งของลูก — `"top-left"` · `"center"` · `"bottom-right"` …
    var place: String? = nil
    /// ใน `stack`: ขยับจากตำแหน่งที่วาง (หน่วยออกแบบ)
    var dx: Double? = nil, dy: Double? = nil
    /// หมุน (องศา)
    var rotate: Double? = nil
    /// ใน `each`: หมุนสลับตามลำดับชิ้น (ชิ้นที่ i ได้ค่า `rotateCycle[i % n]`)
    var rotateCycle: [Double]? = nil
    /// ใน `each`: ขนาดแกนหลักเป็นสัดส่วนของที่ว่างของแม่ จากฟิลด์ตัวเลข 0–100 ของชิ้น (`"$shareRaw"`) — แถบกราฟ
    /// · `"$shareRaw/max"` = เทียบกับค่าสูงสุดในรายการ (แถบยาวสุด = เต็ม)
    var pct: String? = nil

    // MARK: การทา
    var fill: String? = nil
    /// ใน `each`: สีพื้นสลับตามลำดับชิ้น (`fillCycle[i % n]`) — ชนะ `fill`
    var fillCycle: [String]? = nil
    var gradient: SpecGradient? = nil
    var radius: Double? = nil
    /// วงกลม/แคปซูล — มุม = ครึ่งของด้านสั้น ณ ขนาดจริง (ชนะ `radius`)
    var circle: Bool? = nil
    var stroke: SpecStroke? = nil
    var opacity: Double? = nil
    var shadow: SpecShadow? = nil
    var clip: Bool? = nil
    /// ลายพื้นทับบน `fill` (ตัดตามรูปร่างของกล่อง)
    var pattern: SpecPattern? = nil
    /// ลายของแผ่นที่ผู้ใช้เลือกในถาด (เรียบ · ลายทาง · ข้าวหลามตัด — `WidgetInstance.pattern`) วาดด้วย `PlatePatternLayer` ตัวเดิม
    /// ค่าคือ token สีของแผ่นที่ลายนั่งอยู่ (แถบลาย = สีนั้นผสมดำครึ่งหนึ่ง) · ตัดตามรูปร่างของกล่อง
    var platePattern: String? = nil
    /// รูปร่างของกล่อง (พื้น · เส้น · clip): `tag:16` · `heart` · `scallop:8` · `zigzag:10` · `circle`
    var shape: String? = nil

    // MARK: ข้อความ
    /// ช่องของโปรไฟล์ `"name"` · `"categories#0"` · `"note#1"` — หรือ `"$price"` = ฟิลด์ของรายการใน `chips`
    var slot: String? = nil
    /// ข้อความของดีไซน์ (ป้ายคงที่) — มีได้ทั้งคู่: `slot` ว่างแล้วค่อยใช้ `text`
    var text: String? = nil
    /// ข้อความตั้งต้นของช่อง `note` (ผู้ใช้พิมพ์ทับได้)
    var preset: String? = nil
    /// `"display"` · `"body"` · `"mono"` · ชื่อ `CardFont` (`noto` · `mitr` · `serif` …)
    var face: String? = nil
    var size: Double? = nil
    /// 100–900
    var weight: Int? = nil
    var maxLines: Int? = nil
    /// ย่อตัวอักษรได้ถึงขนาดนี้เมื่อไม่พอ (ไม่ใส่ = ไม่ย่อ ตัด … แทน)
    var shrinkTo: Double? = nil
    /// ขยายตัวอักษรจนบรรทัดเดียวเต็มความกว้างของกล่อง (ไม่เกิน `growTo` · ตั้งต้น 400) — หัวเรื่องยักษ์แบบ fit-to-width
    var growTo: Double? = nil
    /// บทบาทของข้อความต่อขั้นต่ำที่อ่านออก (`SpecLegibility`): `"title"` · `"content"` · `"deco"` (ไม่มีขั้นต่ำ)
    /// ไม่ใส่ = ขนาดในผัง ≥ 18 เป็นหัว นอกนั้นเนื้อหา
    var role: String? = nil
    var tracking: Double? = nil
    var kerning: Double? = nil
    /// ตัวคูณความสูงบรรทัด (ค่าตั้งต้น 1.0 = ของฟอนต์)
    var lineHeight: Double? = nil
    /// `"upper"` · `"lower"`
    var textCase: String? = nil
    var color: String? = nil
    /// `"left"` · `"center"` · `"right"`
    var textAlign: String? = nil
    var italic: Bool? = nil
    /// พาดหัวสองเสียง — คำแรกตามฟอนต์ของโหนด ที่เหลือเซริฟเอียง (กติกาโปสเตอร์ "MY *Social*")
    var mixHead: Bool? = nil
    var sizeWhen: [SpecSizeRule]? = nil

    // MARK: รูป
    /// ลำดับช่องรูปของชิ้น (0, 1, 2 …)
    var photo: Int? = nil
    /// ช่องรูปจากฟิลด์ของรายการ — `"$workPhoto"` (ชนะ `photo`)
    var photoRef: String? = nil
    /// รูปจาก asset ของแอป/URL — `"$cover"` · `"$brandLogo"` · ว่างแล้วกลับไปใช้ช่องรูป
    var src: String? = nil
    /// `"cover"` (ตั้งต้น) · `"contain"`
    var fit: String? = nil
    var mono: Bool? = nil

    // MARK: ไอคอน
    /// `"starLockup"` · `"starSeal"` · `"ph:check"` · `"sh:instagram"` · `"$platform"` (จากรายการ)
    var icon: String? = nil
    var tint: String? = nil

    // MARK: รายการ
    /// `"categories"` · `"socials"` · `"rates"` · `"works"` · `"brands"` · `"contacts"`
    var list: String? = nil
    /// แม่แบบของแต่ละชิ้นในรายการ
    var each: SpecNodeBox? = nil
    /// จำนวนสูงสุด
    var limit: Int? = nil
    /// เรียงรายการก่อนวาด: `"followersRaw desc"` · `"label asc"` (ตัวเลขเทียบเป็นตัวเลข)
    var sort: String? = nil
    /// ทิศของ `chips`: `"row"` (ตั้งต้น · wrap) หรือ `"col"` (เรียงลง · ลูกกว้างเต็ม)
    var direction: String? = nil
    /// เก็บชิ้นแรกของแต่ละค่าของฟิลด์นี้ (หลัง `sort`) — `"group": "platform"` = แถวละหนึ่งช่องทาง
    var group: String? = nil
    /// กรองชิ้นของรายการก่อนวาด — เงื่อนไขเดียวกับ `if` ประเมินต่อชิ้น (`"!hidden:$platform"` · `"$viewsRaw>0"`)
    var `where`: String? = nil

    // MARK: เงื่อนไข
    /// `"owner.verified"` · `"has:tagline"` · `"!has:about"` · `"list:socials>1"`
    var `if`: String? = nil

    var children: [SpecNode]? = nil

    init(type: SpecType) { self.type = type }
}

/// กล่องหุ้มโหนดที่ซ้อนตัวเอง (Swift ต้องการ indirection สำหรับ struct ที่อ้างตัวเอง)
final class SpecNodeBox: Codable, Equatable {
    let node: SpecNode
    init(_ node: SpecNode) { self.node = node }
    required init(from decoder: Decoder) throws { node = try SpecNode(from: decoder) }
    func encode(to encoder: Encoder) throws { try node.encode(to: encoder) }
    static func == (a: SpecNodeBox, b: SpecNodeBox) -> Bool { a.node == b.node }
}

// MARK: - แคตตาล็อก

/// ผังทุกชนิดที่แอปถืออยู่ — โหลดจาก `shared/WidgetSpecs/*.json` ครั้งเดียว
///
/// ชนิดที่ไม่มีไฟล์ = ไม่มีในแอป (ไม่ขึ้นตู้ · การ์ดที่มีชื่อนั้นอ่านไม่ออก)
enum SpecCatalog {
    private static var cache: [String: WidgetSpec] = {
        var out: [String: WidgetSpec] = [:]
        let dec = JSONDecoder()
        // โปรเจกต์แบบ folder-synced วางไฟล์ไว้ที่รากของบันเดิล (ไม่มีโฟลเดอร์ย่อย) — ลองโฟลเดอร์ก่อน ว่างค่อยกวาดราก
        var urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "WidgetSpecs") ?? []
        if urls.isEmpty { urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [] }
        for u in urls {
            guard let data = try? Data(contentsOf: u) else { continue }
            do {
                let spec = try dec.decode(WidgetSpec.self, from: data)
                out[spec.kind] = spec
            } catch {
                #if DEBUG
                print("WidgetSpec \(u.lastPathComponent): \(error)")
                #endif
            }
        }
        return out
    }()

    static func spec(for kind: WidgetKind) -> WidgetSpec? { cache[kind.rawValue] }
    static func spec(named name: String) -> WidgetSpec? { cache[name] }

    /// ชนิดที่มีบล็อก `widget` เรียงตามชื่อ — `WidgetKind.allCases` กรองหมวดที่แอปรู้จัก + เรียงตาม `order` อีกชั้น
    static var widgetKinds: [String] { metas.keys.sorted() }

    /// บล็อก `widget` แยกเก็บจากผัง — ทุก property ของ `WidgetKind` อ่านจากตรงนี้ (หลายร้อยครั้งต่อเฟรมตอนลาก/ยืด)
    /// ดึงจาก `cache` ตรง ๆ = คัดลอก `WidgetSpec` ทั้งก้อน (ผังทั้งต้น) ทุกครั้ง · ตารางนี้คิดใหม่เมื่อผังทั้งชุดเปลี่ยนเท่านั้น
    private static var metas: [String: WidgetSpec.Widget] = cache.compactMapValues(\.widget)
    static func widgetMeta(_ kind: String) -> WidgetSpec.Widget? { metas[kind] }
    /// ชนิดที่ประกาศว่าแทนชื่อเก่านี้ (`widget.replaces`)
    static func replacement(for old: String) -> String? {
        cache.values.first { $0.widget?.replaces?.contains(old) ?? false }?.kind
    }
    /// ชื่อเก่าที่แตกเป็นหลายชนิดตามหน้าตา (เช่นชุดห้าสไตล์ก่อน 19 ต.ค. 2569) — เลือกใบที่ `widget.kit.look` ตรงกับที่ชิ้นเคยเก็บ
    static func replacement(for old: String, look: String?) -> String? {
        let all = cache.values.filter { $0.widget?.replaces?.contains(old) ?? false }
        return (all.first { $0.widget?.kit?.look == look } ?? all.sorted { $0.kind < $1.kind }.first { $0.widget?.kit?.look == nil }
                ?? all.first)?.kind
    }
    static var all: [WidgetSpec] { cache.values.sorted { $0.kind < $1.kind } }

    /// ผังที่ใช้กับกรอบนี้ — ผังทางเลือกใบแรกที่เงื่อนไขจริง ไม่มีก็ราก
    static func root(of spec: WidgetSpec, box: CGSize) -> SpecNode {
        for v in spec.variants ?? [] where SpecCondition.box(v.when, box: box) { return v.root }
        return spec.root
    }

    /// เพิ่มทุกครั้งที่ผังทั้งชุดถูกแทน — ตัวจำผลของตัวคำนวณ (`SpecSolveMemo`) ใช้เป็นส่วนหนึ่งของกุญแจ
    private(set) static var generation = 0

    /// ผังทั้งชุดเปลี่ยน — คิดตารางนิสัยใหม่ + เลื่อนรุ่น (ตัวจำผลของตัวคำนวณ · ลำดับตู้ของ `WidgetKind.allCases`)
    private static func changed() {
        metas = cache.compactMapValues(\.widget)
        generation &+= 1
    }

    /// โหมดลองทำ: แทนผังทั้งชุดด้วยไฟล์ที่ดึงจาก API — ไฟล์ที่อ่านไม่ผ่านถูกข้าม · คืนจำนวนที่อ่านได้ (0 = คงชุดเดิม)
    @discardableResult
    static func replace(with files: [Data]) -> Int {
        let dec = JSONDecoder()
        var out: [String: WidgetSpec] = [:]
        for d in files {
            do { let spec = try dec.decode(WidgetSpec.self, from: d); out[spec.kind] = spec }
            catch { print("WidgetSpec (API): \(error)") }
        }
        if !out.isEmpty { cache = out; changed() }
        return out.count
    }

    #if DEBUG
    /// โหลดใหม่จากดิสก์ (ใช้กับห้องแล็บ) — path ของโฟลเดอร์ที่มีไฟล์ json
    static func reload(from dir: URL) {
        let dec = JSONDecoder()
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
        for u in files where u.pathExtension == "json" {
            if let data = try? Data(contentsOf: u), let spec = try? dec.decode(WidgetSpec.self, from: data) {
                cache[spec.kind] = spec
            }
        }
        changed()
    }
    #endif
}

// MARK: - เงื่อนไขบนกรอบ

enum SpecCondition {
    /// `w<260` · `h>=120` · `ratio<0.6` (ratio = h/w) — หลายเงื่อนไขคั่นด้วย `&`
    static func box(_ expr: String, box: CGSize) -> Bool {
        for part in expr.split(separator: "&") {
            let e = part.trimmingCharacters(in: .whitespaces)
            guard let (key, op, val) = parse(e) else { return false }
            let lhs: Double
            switch key {
            case "w": lhs = box.width
            case "h": lhs = box.height
            case "ratio": lhs = box.width > 0 ? box.height / box.width : 0
            default: return false
            }
            if !compare(lhs, op, val) { return false }
        }
        return true
    }

    private static func parse(_ e: String) -> (String, String, Double)? {
        for op in ["<=", ">=", "<", ">", "="] {
            if let r = e.range(of: op) {
                let k = e[..<r.lowerBound].trimmingCharacters(in: .whitespaces)
                let v = e[r.upperBound...].trimmingCharacters(in: .whitespaces)
                guard let d = Double(v) else { return nil }
                return (k, op, d)
            }
        }
        return nil
    }

    private static func compare(_ a: Double, _ op: String, _ b: Double) -> Bool {
        switch op {
        case "<":  return a < b
        case "<=": return a <= b
        case ">":  return a > b
        case ">=": return a >= b
        default:   return abs(a - b) < 0.001
        }
    }
}
