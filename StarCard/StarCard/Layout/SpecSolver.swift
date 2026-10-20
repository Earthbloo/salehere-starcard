import Foundation
import CoreGraphics

// MARK: - ตัวคำนวณกล่องจากผัง — อัลกอริทึมเดียวที่ทุกแพลตฟอร์มต้อง port ให้ตรง
//
// # สัญญา
//
// เข้า: `WidgetSpec` + กล่องราก (W×H หน่วยออกแบบ) + แหล่งข้อมูล (ข้อความของช่อง · รายการ · ธง · ฟอนต์ของช่อง)
//     + ตัววัดข้อความ (ความกว้าง/จำนวนบรรทัดของสตริงหนึ่งด้วยฟอนต์หนึ่ง)
// ออก: รายการกล่อง `SpecBox` (x · y · w · h สัมบูรณ์ในกล่องราก) ทุกโหนดที่ต้องวาด พร้อมผลข้อความ
//     (สตริงที่แสดง · ขนาดตัวอักษรสุดท้าย · จำนวนบรรทัด)
//
// ตัววาด (`SpecPainter` บน iOS · Compose บน Android · DOM บนเว็บ) **ไม่ตัดสินใจอะไร** นอกจากทาตามกล่อง
// ความต่างระหว่างแพลตฟอร์มจึงเหลือแค่ตัววัดข้อความ ซึ่งคุมด้วยฟอนต์ไฟล์เดียวกัน (ดู WIDGET-SPEC.md)
//
// # อัลกอริทึม (flex อย่างย่อ — ไม่ใช่ CSS ทั้งสเปก แต่กติกาตรงกับ CSS flex ในส่วนที่ใช้)
//
// 1. `sizeWhen` ของข้อความประเมินจากกล่องราก (w · h · ratio) ก่อนทุกอย่าง
// 2. `chips` ขยายเป็นลูกจริงจาก `list` ด้วยแม่แบบ `each` · โหนดที่ `if` เป็นเท็จถูกตัดทิ้ง
// 3. คอนเทนเนอร์ (`col`/`row`): วัดฐาน (basis) ของลูกในแกนหลัก — ตัวเลข → ตามนั้น · `fill` → 0 + grow ≥ 1 ·
//    ไม่ระบุ → เท่าเนื้อหา (hug) ที่ความกว้าง/สูงที่มีให้ · ที่เหลือแจกตาม `grow` · ที่ขาดหักจากลูกที่ `shrink` > 0
//    ตามสัดส่วนฐาน · แกนขวางตั้งต้น = stretch (เต็มคอนเทนเนอร์) เว้นแต่ระบุขนาดหรือ `align`
// 4. `row` + `wrap`: บรรจุลูกทีละบรรทัดแบบ greedy (ลูกที่ล้นบรรทัดขึ้นบรรทัดใหม่) · บรรทัดสูงเท่าลูกสูงสุด ·
//    บรรทัดเรียงลงด้วย `gap` เดียวกัน
// 5. `stack`: ลูกทุกตัววางซ้อนในกล่องเดียวกัน ตำแหน่งตาม `place` + `dx`/`dy` · ขนาด = ระบุ หรือ hug
// 6. ข้อความ: ความกว้างที่ได้ → วัดจำนวนบรรทัด · เกิน `maxLines` หรือบรรทัดเดียวล้น → ลดขนาดทีละ 0.5
//    จนพอดีหรือถึง `shrinkTo` · ยังไม่พอ = ตัดท้ายด้วย … (ตัววาดเป็นคนตัด ตัวคำนวณบอกแค่จำนวนบรรทัด)
// 7. ทุกกล่องปัดเป็น 2 ทศนิยม (fixture เทียบกันข้ามแพลตฟอร์มด้วยค่านี้)
// 8. ขั้นต่ำที่อ่านออก (`SpecLegibility`): ขนาดที่วาดจริงบนการ์ด (size × renderScale × fitScale) ไม่ต่ำกว่า
//    min(ขนาดในผัง, ขั้นต่ำของบทบาท) — หัวกับเนื้อหามีขั้นต่ำคนละค่า · กรอบยิ่งเล็ก ตัวอักษรในหน่วยผังยิ่งโต

/// ขั้นต่ำของตัวอักษรเมื่อผู้ใช้หดกรอบ — หน่วย pt **บนการ์ด** (หลังคูณสเกลกรอบ × `fitScale`)
///
/// ผู้ใช้ 14 ต.ค. 2569: หด widget แล้วตัวหนังสือเล็กจนอ่านไม่ออกตอน export · "Min Title กับ Min Content ต้องต่างกัน"
/// การ์ดสตอรี่ 540pt แสดงบนจอโทรศัพท์ราว ×0.66 → หัว 18 ≈ 12pt · เนื้อหา 12 ≈ 8pt บนจอคนดู
/// ขั้นต่ำไม่เกินขนาดในผัง (ป้ายจิ๋ว 7pt ไม่ถูกขยายเป็น 12) — ขนาดตั้งต้นของทุกใบจึงไม่เปลี่ยน มีผลเฉพาะตอนหด
enum SpecLegibility {
    /// ขนาดในผังตั้งแต่ค่านี้ = หัว (ชื่อ · ตัวเลขใหญ่ · พาดหัว) — ไม่ใส่ `role` ในผังก็แยกได้เอง
    static let titleFrom: CGFloat = 18
    static let titleMin: CGFloat = 18
    static let contentMin: CGFloat = 12
    /// เทียบก่อน/หลัง: เปิดแอปด้วย `-legibilityOff YES` (DEBUG)
    #if DEBUG
    static let off = UserDefaults.standard.bool(forKey: "legibilityOff")
    #else
    static let off = false
    #endif

    /// ความแรงที่ลองทีละขั้นเมื่อการยกเต็มที่ทำให้ผังล้น/ชิ้นอื่นเล็กลงกว่าเดิม (สุดท้าย = ผังเดิม ไม่ยก)
    static let steps: [CGFloat] = [1, 0.66, 0.33]
    /// รูปต้องเหลืออย่างน้อยเท่านี้ของขนาดเดิม (ด้านสั้น) — ไม่งั้นลดการยกตัวอักษรลง
    static let imageKeep: CGFloat = 0.6

    /// ขั้นต่ำของชิ้นนี้บนการ์ด (pt) — min(ขนาดในผัง, ขั้นต่ำของบทบาท) · 0 = ไม่มี (`deco`)
    static func target(design: CGFloat, role: String?) -> CGFloat {
        guard role != "deco" else { return 0 }
        let title = role.map { $0 == "title" } ?? (design >= titleFrom)
        return min(design, title ? titleMin : contentMin)
    }

    /// ขนาดต่ำสุดในหน่วยผัง · 0 = ไม่มีขั้นต่ำ (ไม่ได้หด หรือ `role: "deco"`)
    static func floor(design: CGFloat, role: String?, scale: CGFloat) -> CGFloat {
        guard scale > 0, scale < 1, !off else { return 0 }
        return target(design: design, role: role) / scale
    }
}

/// ฟอนต์ที่ตัววัดต้องรู้จัก — ชื่อ face เป็น token ของแอป (`noto` · `mitr` · `serif` …) ไม่ใช่ชื่อไฟล์
struct SpecFont: Hashable {
    var face: String
    var size: CGFloat
    /// 100–900
    var weight: Int
    var tracking: CGFloat = 0
    var kerning: CGFloat = 0
    var italic: Bool = false
    var lineHeight: CGFloat = 1
}

/// ตัววัดข้อความของแพลตฟอร์ม
protocol SpecMeasurer {
    /// ขนาดของสตริงเมื่อจัดในความกว้าง `width` (nil = ไม่จำกัด) — คืนความกว้างที่ใช้จริง · ความสูง · จำนวนบรรทัด
    func measure(_ text: String, font: SpecFont, width: CGFloat?) -> (size: CGSize, lines: Int)
    /// ความสูงหนึ่งบรรทัดของฟอนต์นี้
    func lineHeight(_ font: SpecFont) -> CGFloat
}

/// หนึ่งชิ้นในรายการ (`list`) — ค่าตามชื่อฟิลด์ · `i` = ลำดับ
struct SpecItem: Hashable {
    var id: String
    var i: Int
    var fields: [String: String]
    func value(_ key: String) -> String {
        switch key {
        case "i": return String(i)
        case "rank": return String(i + 1)
        case "rank2": return String(format: "%02d", i + 1)
        default: return fields[key] ?? ""
        }
    }
}

/// แหล่งข้อมูลที่ผังอ้างถึง — แพลตฟอร์มเป็นคนให้ (iOS: `Profile.me` · Android: ViewModel · Web: props)
protocol SpecDataSource {
    /// ข้อความของช่อง (`name` · `categories#0` · `note#1`) — ว่าง = ไม่มี · `preset` = ข้อความตั้งต้นของดีไซน์ (ช่อง note)
    func text(slot: String, preset: String?) -> String
    func list(_ name: String) -> [SpecItem]
    func flag(_ name: String) -> Bool
    /// ฟอนต์ของช่องหลังผ่านที่ผู้ใช้ตั้งให้ช่องนั้น (ฟอนต์ · ขนาด XS–XXL) — `slot` ว่าง = ป้ายของดีไซน์ ไม่ปรับ
    func font(slot: String?, face: String, size: CGFloat, weight: Int) -> SpecFont
}

struct SpecTextResult: Equatable {
    var string: String
    var size: CGFloat
    var lines: Int
    /// ช่องที่ผูก (หลังแทนค่า `$i` แล้ว) — ตัววาดใช้เปิดแก้ข้อความ
    var slot: String?
}

/// กล่องหนึ่งใบที่ตัววาดต้องทา
struct SpecBox: Identifiable, Equatable {
    /// path ของโหนด เช่น `r/0/2` (r = ราก · ตัวเลข = ลำดับลูก · `c3` = ชิ้นที่ 3 ของ chips)
    let id: String
    let node: SpecNode
    var frame: CGRect
    var text: SpecTextResult? = nil
    /// ค่าของรายการที่โหนดนี้ผูกอยู่ (ไอคอน `$platform` · รูป `$photo`)
    var item: SpecItem? = nil
    var depth: Int
}

final class SpecSolver {
    let spec: WidgetSpec
    let box: CGSize
    let data: SpecDataSource
    let measurer: SpecMeasurer

    /// ขั้นย่อที่ `fitScale` เลือก (1 = ไม่ย่อ) — กล่องที่คืนอยู่ในหน่วย `box / scale` ตัววาดคูณกลับทั้งก้อน
    private(set) var scale: CGFloat = 1
    /// สเกลที่ chrome คูณทั้งก้อน (`min(W/w0, H/h0)`) — ใช้คิดขั้นต่ำที่อ่านออก (`SpecLegibility`) · 1 = ไม่คิด
    let renderScale: CGFloat
    /// ความแรงของการยกตัวอักษร (0 = ผังเดิม · 1 = ถึงขั้นต่ำเต็มที่) — `solve` ลดลงทีละขั้นถ้าผังรับไม่ไหว
    private var strength: CGFloat = 1
    /// รอบนี้มีข้อความถูกยกขึ้นจริงไหม — ไม่มี = ผลเท่าผังเดิม ไม่ต้องลองต่อ
    private var lifted = false

    init(spec: WidgetSpec, box: CGSize, data: SpecDataSource, measurer: SpecMeasurer, renderScale: CGFloat = 1) {
        self.spec = spec; self.box = box; self.data = data; self.measurer = measurer; self.renderScale = renderScale
    }

    // MARK: ต้นไม้ที่ขยายแล้ว

    private final class N {
        /// ผังที่ใช้คำนวณ — ข้อความที่ถูกยกขึ้นตามขั้นต่ำที่อ่านออก กล่องตายตัวของมันโตตามด้วย (`prepare`)
        var node: SpecNode
        /// ผังตามไฟล์
        let base: SpecNode
        let id: String
        let item: SpecItem?
        let depth: Int
        var children: [N] = []
        var frame: CGRect = .zero
        var text: SpecTextResult? = nil
        /// ข้อความสูงเกินกล่องที่ได้เท่าไหร่ (ล้น = ทับของข้าง ๆ)
        var overflow: CGFloat = 0
        /// แคชผลวัดข้อความต่อความกว้าง
        var textCache: [CGFloat: (CGSize, SpecTextResult)] = [:]
        init(_ node: SpecNode, id: String, item: SpecItem?, depth: Int) {
            self.node = node; self.base = node; self.id = id; self.item = item; self.depth = depth
        }
    }

    private func expand(_ node: SpecNode, id: String, item: SpecItem?, depth: Int) -> N? {
        if let cond = node.if, !evaluate(cond, item: item) { return nil }
        let n = N(node, id: id, item: item, depth: depth)
        if node.type == .chips, let name = node.list, let tpl = node.each?.node {
            var items = data.list(name)
            if let w = node.where { items = items.filter { evaluate(w, item: $0) } }
            if let sort = node.sort {
                // หลายคีย์คั่นด้วย `,` — `"platformOrder asc, priceRaw asc"` (คีย์แรกเท่ากันค่อยดูคีย์ถัดไป)
                let keys: [(String, Bool)] = sort.split(separator: ",").map {
                    let parts = $0.split(separator: " ").map(String.init)
                    return (parts.first ?? "", parts.count > 1 && parts[1] == "desc")
                }
                items.sort { a, b in
                    for (key, desc) in keys {
                        let av = a.value(key), bv = b.value(key)
                        if av == bv { continue }
                        let less: Bool
                        if let x = Double(av), let y = Double(bv) {
                            if x == y { continue }
                            less = x < y
                        } else { less = av < bv }
                        return desc ? !less : less
                    }
                    return false
                }
                items = items.enumerated().map { var it = $0.element; it.i = $0.offset; return it }
            }
            if let g = node.group {
                var seen = Set<String>()
                items = items.filter { seen.insert($0.value(g)).inserted }
                items = items.enumerated().map { var it = $0.element; it.i = $0.offset; return it }
            }
            if let lim = node.limit { items = Array(items.prefix(lim)) }
            // ค่าสรุปของรายการ (หลัง sort/limit) ติดไปกับทุกชิ้น: `<key>.max` · `<key>.sum` สำหรับฟิลด์ตัวเลข
            var maxes: [String: Double] = [:], sums: [String: Double] = [:]
            for it in items { for (k, v) in it.fields { if let d = Double(v) { maxes[k] = max(maxes[k] ?? -.infinity, d); sums[k, default: 0] += d } } }
            items = items.map { it in
                var it = it
                for (k, m) in maxes { it.fields[k + ".max"] = String(m); it.fields[k + ".sum"] = String(sums[k] ?? 0) }
                return it
            }
            n.children = items.enumerated().compactMap { expand(tpl, id: "\(id)/c\($0.offset)", item: $0.element, depth: depth + 1) }
        } else {
            n.children = (node.children ?? []).enumerated().compactMap {
                expand($0.element, id: "\(id)/\($0.offset)", item: item, depth: depth + 1)
            }
        }
        return n
    }

    /// `owner.verified` · `has:tagline` · `!has:about` · `list:socials>1` · `sample` · `$field` (ของรายการ ไม่ว่าง)
    private func evaluate(_ cond: String, item: SpecItem?) -> Bool {
        // `a & b` = ทุกข้อจริง · `a | b` = ข้อใดข้อหนึ่งจริง (& ผูกแน่นกว่า |)
        if cond.contains("|") { return cond.split(separator: "|").contains { evaluate(String($0), item: item) } }
        if cond.contains("&") { return cond.split(separator: "&").allSatisfy { evaluate(String($0), item: item) } }
        var c = cond.trimmingCharacters(in: .whitespaces)
        var negate = false
        if c.hasPrefix("!") { negate = true; c.removeFirst() }
        // `$field` ที่อยู่ *ข้างใน* ชื่อธง (`hidden:$platform` · `opt:chan=$platform`) แทนด้วยค่าของชิ้นก่อน
        if !c.hasPrefix("$"), c.contains("$"), let item {
            for (k, v) in item.fields { c = c.replacingOccurrences(of: "$" + k, with: v) }
            c = c.replacingOccurrences(of: "$i", with: String(item.i))
        }
        let v: Bool
        if c.hasPrefix("has:") {
            v = !resolveText(String(c.dropFirst(4)), item: item).isEmpty
        } else if c.hasPrefix("list:") {
            let body = String(c.dropFirst(5))
            if let r = body.range(of: ">") {
                let name = String(body[..<r.lowerBound]); let n = Int(body[r.upperBound...]) ?? 0
                v = data.list(name).count > n
            } else if let r = body.range(of: "=") {
                let name = String(body[..<r.lowerBound]); let n = Int(body[r.upperBound...]) ?? 0
                v = data.list(name).count == n
            } else { v = !data.list(body).isEmpty }
        } else if c.hasPrefix("$"), let item {
            let body = String(c.dropFirst())
            // เทียบตัวเลข: `$viewsRaw>0` · `$shareRaw>=40` · `$i<2`
            if let m = body.range(of: #"(<=|>=|<|>)"#, options: .regularExpression) {
                let key = String(body[..<m.lowerBound]), op = String(body[m]), rhs = Double(body[m.upperBound...]) ?? 0
                let lhs = Double(item.value(key)) ?? 0
                switch op {
                case "<": v = lhs < rhs
                case "<=": v = lhs <= rhs
                case ">": v = lhs > rhs
                default: v = lhs >= rhs
                }
            } else if body.hasSuffix("=max") {
                let k = String(body.dropLast(4)); v = item.value(k) == item.value(k + ".max") && !item.value(k).isEmpty
            } else if body.hasSuffix("=first") {
                v = item.i == 0
            } else {
                v = !item.value(body).isEmpty
            }
        } else {
            v = data.flag(c)
        }
        return negate ? !v : v
    }

    /// ข้อความของโหนด — ช่อง (`slot`) ก่อน · ว่างแล้วใช้ `text` ของดีไซน์ · `$field` อ่านจากรายการ · `{field}` ในข้อความแทนค่า
    private func resolveText(_ raw: String, item: SpecItem?) -> String {
        if raw.hasPrefix("$"), let item { return item.value(String(raw.dropFirst())) }
        var s = raw
        if let item, s.contains("$i") { s = s.replacingOccurrences(of: "$i", with: String(item.i)) }
        if raw.hasPrefix("$") || raw.contains("{") {
            if let item {
                for (k, val) in item.fields { s = s.replacingOccurrences(of: "{\(k)}", with: val) }
                s = s.replacingOccurrences(of: "{i}", with: String(item.i))
            }
            return s
        }
        return data.text(slot: s, preset: nil)
    }

    private func boundSlot(_ node: SpecNode, item: SpecItem?) -> String? {
        guard let slot = node.slot else { return nil }
        if slot.hasPrefix("$") { return nil }
        if let item, slot.contains("$i") { return slot.replacingOccurrences(of: "$i", with: String(item.i)) }
        return slot
    }

    private func string(of n: N) -> (String, String?) {
        let node = n.node
        var s = ""
        var slot: String? = nil
        if let sl = node.slot {
            if sl.hasPrefix("$") { s = n.item?.value(String(sl.dropFirst())) ?? "" }
            else { slot = boundSlot(node, item: n.item); s = data.text(slot: slot ?? sl, preset: node.preset) }
        }
        if s.isEmpty, let t = node.text { s = resolveTemplate(t, item: n.item) }
        if s.isEmpty, let p = node.preset { s = p }
        switch node.textCase {
        case "upper": s = s.uppercased()
        case "lower": s = s.lowercased()
        default: break
        }
        return (s, slot)
    }

    /// แทนค่าของรายการในข้อความ — `{field}` และ `$field` (คีย์ยาวก่อน กัน `$share` ไปกิน `$shareRaw`)
    private func resolveTemplate(_ t: String, item: SpecItem?) -> String {
        guard let item, t.contains("{") || t.contains("$") else { return t }
        var s = t
        let keys = (Array(item.fields.keys) + ["i", "rank", "rank2"]).sorted { $0.count > $1.count }
        for k in keys {
            let v = item.value(k)
            s = s.replacingOccurrences(of: "{\(k)}", with: v)
            s = s.replacingOccurrences(of: "$" + k, with: v)
        }
        return s
    }

    // MARK: ขนาดตัวอักษรตามกล่องราก

    private func baseSize(_ node: SpecNode) -> CGFloat {
        var size = CGFloat(node.size ?? 14)
        for r in node.sizeWhen ?? [] where SpecCondition.box(r.when, box: box) { size = CGFloat(r.size); break }
        return size
    }

    private func font(for n: N, size: CGFloat) -> SpecFont {
        let node = n.node
        var f = data.font(slot: boundSlot(node, item: n.item), face: node.face ?? "body",
                          size: size, weight: node.weight ?? 400)
        f.tracking = CGFloat(node.tracking ?? 0)
        f.kerning = CGFloat(node.kerning ?? 0)
        f.italic = node.italic ?? false
        f.lineHeight = CGFloat(node.lineHeight ?? 1)
        return f
    }

    /// วัดข้อความในความกว้าง `width` (nil = บรรทัดเดียวไม่จำกัด) — ย่อตาม `shrinkTo` จนลง `maxLines`
    private func fitText(_ n: N, width: CGFloat?) -> (CGSize, SpecTextResult) {
        let key = width ?? -1
        if let c = n.textCache[key] { return c }
        let (s, slot) = string(of: n)
        let node = n.node
        let maxLines = node.maxLines ?? (width == nil ? 1 : 0)   // 0 = ไม่จำกัด
        let design = baseSize(node)
        // ขั้นต่ำที่อ่านออก = ขนาดเริ่ม · ถ้าที่ไม่พอ ย่อลงได้จนถึงพื้นเดิมของผัง — คำที่ถูกตัด "@mane…" แย่กว่าตัวเล็กลงนิดหน่อย
        let legible = legibleSize(node, design: design)
        if legible > design { lifted = true }
        var size = max(design, legible)
        let floor = node.shrinkTo.map { min(CGFloat($0), design) } ?? design
        var out: (CGSize, Int) = (.zero, 1)
        // fit-to-width: โตทีละ 1pt จนบรรทัดเดียวล้นความกว้าง แล้วถอยหนึ่งขั้น (เพดาน `growTo`)
        if let cap = node.growTo, let width, !s.isEmpty {
            var grown = size
            while grown + 1 <= CGFloat(cap) {
                let m = measurer.measure(s, font: font(for: n, size: grown + 1), width: nil)
                if m.size.width > width + 0.01 { break }
                grown += 1
            }
            size = grown
        }
        while true {
            let f = font(for: n, size: size)
            if s.isEmpty {
                out = (CGSize(width: 0, height: measurer.lineHeight(f)), 1)
                break
            }
            let m = measurer.measure(s, font: f, width: width)
            out = (m.size, m.lines)
            let overflowLines = maxLines > 0 && m.lines > maxLines
            let overflowWidth = width.map { m.size.width > $0 + 0.01 } ?? false
            if !(overflowLines || overflowWidth) || size - 0.5 < floor { break }
            size -= 0.5
        }
        var lines = out.1
        if maxLines > 0 { lines = min(lines, maxLines) }
        let f = font(for: n, size: size)
        let lh = measurer.lineHeight(f)
        // ความสูงจากจำนวนบรรทัดที่แสดงจริง (ตัดท้ายแล้วกล่องไม่สูงเกิน)
        let h = s.isEmpty ? lh : (lines == out.1 ? max(out.0.height, lh) : lh * CGFloat(lines))
        let r = (CGSize(width: width.map { min(out.0.width, $0) } ?? out.0.width, height: h),
                 SpecTextResult(string: s, size: size, lines: lines, slot: slot))
        n.textCache[key] = r
        return r
    }

    // MARK: ขนาดเนื้อหา (hug)

    /// ความยาวที่ระบุตายตัว — ตัวเลข หรือ % ของที่ว่าง (`avail`) · nil = ไม่ได้ระบุ/fill/hug
    private func fixed(_ l: SpecLength?, avail: CGFloat?) -> CGFloat? {
        switch l {
        case .pt(let d)?: return CGFloat(d)
        case .pct(let d)?: return avail.map { $0 * CGFloat(d) / 100 }
        default: return nil
        }
    }
    private func isFill(_ l: SpecLength?) -> Bool { if case .fill? = l { return true } else { return false } }

    private func pad(_ node: SpecNode) -> SpecInsets { node.pad ?? SpecInsets() }

    private func clampW(_ node: SpecNode, _ w: CGFloat) -> CGFloat {
        var v = w
        if let mn = node.minW { v = max(v, CGFloat(mn)) }
        if let mx = node.maxW { v = min(v, CGFloat(mx)) }
        return max(0, v)
    }
    private func clampH(_ node: SpecNode, _ h: CGFloat) -> CGFloat {
        var v = h
        if let mn = node.minH { v = max(v, CGFloat(mn)) }
        if let mx = node.maxH { v = min(v, CGFloat(mx)) }
        return max(0, v)
    }

    /// ขนาดที่โหนดต้องการเมื่อให้ที่ `availW` × `availH` (ความกว้าง/สูงที่มีให้ · nil = ไม่จำกัด)
    private func intrinsic(_ n: N, availW: CGFloat?, availH: CGFloat?) -> CGSize {
        let node = n.node
        let fw = fixed(node.w, avail: availW), fh = fixed(node.h, avail: availH)
        if let fw, let fh { return CGSize(width: clampW(node, fw), height: clampH(node, fh)) }
        if let a = node.aspect, a > 0 {
            if let fw { return CGSize(width: clampW(node, fw), height: clampH(node, fw / CGFloat(a))) }
            if let fh { return CGSize(width: clampW(node, fh * CGFloat(a)), height: clampH(node, fh)) }
        }
        var size: CGSize
        switch node.type {
        case .text:
            let w = fw ?? availW
            let (m, _) = fitText(n, width: w.map { clampW(node, $0) })
            size = CGSize(width: fw ?? m.width, height: fh ?? m.height)
        case .icon:
            let s = CGFloat(node.size ?? 16)
            size = CGSize(width: fw ?? fh ?? s, height: fh ?? fw ?? s)
        case .image:
            // รูปไม่มีขนาดในตัว — ไม่ระบุ = เต็มที่ที่มีให้ (ปกติใส่ `grow` หรือ `aspect`)
            size = CGSize(width: fw ?? availW ?? 0, height: fh ?? availH ?? 0)
        case .rect, .spacer:
            size = CGSize(width: fw ?? 0, height: fh ?? 0)
        case .line:
            size = CGSize(width: fw ?? availW ?? 0, height: fh ?? 1)
        case .col, .row, .chips, .stack:
            let p = pad(node)
            let innerW = (fw ?? availW).map { max(0, $0 - CGFloat(p.h)) }
            let innerH = (fh ?? availH).map { max(0, $0 - CGFloat(p.v)) }
            let c = contentSize(n, innerW: innerW, innerH: innerH)
            size = CGSize(width: fw ?? (c.width + CGFloat(p.h)), height: fh ?? (c.height + CGFloat(p.v)))
        }
        if let a = node.aspect, a > 0 {
            if fw == nil && fh == nil { size.height = size.width / CGFloat(a) }
        }
        return CGSize(width: clampW(node, size.width), height: clampH(node, size.height))
    }

    private func chipsWrap(_ node: SpecNode) -> Bool { node.type == .chips && node.wrap != false && node.direction != "col" }
    private func chipsCol(_ node: SpecNode) -> Bool { node.type == .chips && node.direction == "col" }

    /// ขนาดเนื้อหาข้างในคอนเทนเนอร์ (ไม่รวม pad)
    private func contentSize(_ n: N, innerW: CGFloat?, innerH: CGFloat?) -> CGSize {
        let node = n.node
        let gap = CGFloat(node.gap ?? 0)
        switch node.type {
        case .stack:
            var w: CGFloat = 0, h: CGFloat = 0
            for c in n.children {
                let s = intrinsic(c, availW: innerW, availH: innerH)
                w = max(w, s.width + CGFloat(c.node.dx ?? 0)); h = max(h, s.height + CGFloat(c.node.dy ?? 0))
            }
            return CGSize(width: w, height: h)
        case .row, .chips:
            if chipsCol(node) { fallthrough }
            if node.wrap == true || chipsWrap(node), let innerW {
                let lines = wrapLines(n, width: innerW, gap: gap)
                let h = lines.reduce(0) { $0 + $1.height } + gap * CGFloat(max(0, lines.count - 1))
                let w = lines.map(\.width).max() ?? 0
                return CGSize(width: min(w, innerW), height: h)
            }
            var w: CGFloat = 0, h: CGFloat = 0
            for (i, c) in n.children.enumerated() {
                let s = intrinsic(c, availW: nil, availH: innerH)
                w += s.width + (i > 0 ? gap : 0); h = max(h, s.height)
            }
            return CGSize(width: w, height: h)
        default: // col
            var w: CGFloat = 0, h: CGFloat = 0
            for (i, c) in n.children.enumerated() {
                let s = intrinsic(c, availW: innerW, availH: nil)
                h += s.height + (i > 0 ? gap : 0); w = max(w, s.width)
            }
            return CGSize(width: w, height: h)
        }
    }

    private struct Line { var items: [(N, CGSize)]; var width: CGFloat; var height: CGFloat }

    private func wrapLines(_ n: N, width: CGFloat, gap: CGFloat) -> [Line] {
        var lines: [Line] = []
        var cur = Line(items: [], width: 0, height: 0)
        for c in n.children {
            let s = intrinsic(c, availW: width, availH: nil)
            let need = cur.items.isEmpty ? s.width : cur.width + gap + s.width
            if !cur.items.isEmpty && need > width + 0.01 {
                lines.append(cur); cur = Line(items: [], width: 0, height: 0)
            }
            cur.items.append((c, s))
            cur.width = cur.items.isEmpty ? 0 : (cur.items.count == 1 ? s.width : cur.width + gap + s.width)
            cur.height = max(cur.height, s.height)
        }
        if !cur.items.isEmpty { lines.append(cur) }
        return lines
    }

    // MARK: วางผัง

    private func layout(_ n: N, frame: CGRect) {
        n.frame = frame
        let node = n.node
        if node.type == .text {
            let w = max(0, frame.width)
            let (m, r) = fitText(n, width: w)
            n.text = r
            n.overflow = m.height - frame.height
            return
        }
        guard !n.children.isEmpty else { return }
        let p = pad(node)
        let inner = CGRect(x: frame.minX + CGFloat(p.left), y: frame.minY + CGFloat(p.top),
                           width: max(0, frame.width - CGFloat(p.h)), height: max(0, frame.height - CGFloat(p.v)))
        let gap = CGFloat(node.gap ?? 0)
        switch node.type {
        case .stack: layoutStack(n, inner: inner)
        case .row, .chips:
            if chipsCol(node) { layoutFlex(n, inner: inner, gap: gap, row: false) }
            else if node.wrap == true || chipsWrap(node) { layoutWrap(n, inner: inner, gap: gap) }
            else { layoutFlex(n, inner: inner, gap: gap, row: true) }
        default: layoutFlex(n, inner: inner, gap: gap, row: false)
        }
    }

    private func layoutStack(_ n: N, inner: CGRect) {
        for c in n.children {
            let fw = fixed(c.node.w, avail: inner.width), fh = fixed(c.node.h, avail: inner.height)
            var s = intrinsic(c, availW: inner.width, availH: inner.height)
            if isFill(c.node.w) || (fw == nil && c.node.type != .text && c.node.type != .icon && c.node.aspect == nil && c.node.type != .rect) { s.width = inner.width }
            if isFill(c.node.h) || (fh == nil && (c.node.type == .image || c.node.type == .col || c.node.type == .row || c.node.type == .stack) && c.node.aspect == nil) { s.height = inner.height }
            if c.node.type == .text, fw == nil { s.width = inner.width; s = CGSize(width: inner.width, height: intrinsic(c, availW: inner.width, availH: inner.height).height) }
            if c.node.type == .rect, fw == nil, !isFill(c.node.w) { s.width = inner.width }
            if c.node.type == .rect, fh == nil, !isFill(c.node.h) { s.height = inner.height }
            s.width = min(s.width, inner.width); s.height = min(s.height, inner.height)
            let (ax, ay) = placement(c.node.place)
            let x = inner.minX + (inner.width - s.width) * ax + CGFloat(c.node.dx ?? 0)
            let y = inner.minY + (inner.height - s.height) * ay + CGFloat(c.node.dy ?? 0)
            layout(c, frame: CGRect(x: x, y: y, width: s.width, height: s.height))
        }
    }

    private func placement(_ place: String?) -> (CGFloat, CGFloat) {
        guard let place else { return (0, 0) }
        var ax: CGFloat = 0, ay: CGFloat = 0
        let parts = place.split(separator: "-").map(String.init)
        for p in parts {
            switch p {
            case "top": ay = 0
            case "bottom": ay = 1
            case "left": ax = 0
            case "right": ax = 1
            case "center": if parts.count == 1 { ax = 0.5; ay = 0.5 } else if parts.first == p { ay = 0.5 } else { ax = 0.5 }
            default: break
            }
        }
        if parts == ["center"] { return (0.5, 0.5) }
        return (ax, ay)
    }

    private func layoutWrap(_ n: N, inner: CGRect, gap: CGFloat) {
        let lines = wrapLines(n, width: inner.width, gap: gap)
        let totalH = lines.reduce(0) { $0 + $1.height } + gap * CGFloat(max(0, lines.count - 1))
        var y = inner.minY + mainOffset(n.node.justify, free: inner.height - totalH, count: lines.count).start
        let stepExtra = mainOffset(n.node.justify, free: inner.height - totalH, count: lines.count).between
        for line in lines {
            let freeW = inner.width - line.width
            var x = inner.minX + mainOffset(n.node.justify, free: freeW, count: line.items.count).start
            let extra = mainOffset(n.node.justify, free: freeW, count: line.items.count).between
            for (c, s) in line.items {
                let ay = crossOffset(c.node.alignSelf ?? n.node.align ?? .start, free: line.height - s.height)
                layout(c, frame: CGRect(x: x, y: y + ay, width: s.width, height: s.height))
                x += s.width + gap + extra
            }
            y += line.height + gap + stepExtra
        }
    }

    /// ระยะเริ่มกับระยะแทรกระหว่างชิ้นตาม `justify`
    private func mainOffset(_ j: SpecJustify?, free: CGFloat, count: Int) -> (start: CGFloat, between: CGFloat) {
        let f = max(0, free)
        switch j ?? .start {
        case .start: return (0, 0)
        case .center: return (f / 2, 0)
        case .end: return (f, 0)
        case .between: return (0, count > 1 ? f / CGFloat(count - 1) : 0)
        case .around: let b = f / CGFloat(max(count, 1)); return (b / 2, b)
        }
    }

    private func crossOffset(_ a: SpecAlign, free: CGFloat) -> CGFloat {
        switch a {
        case .start, .stretch: return 0
        case .center: return max(0, free) / 2
        case .end: return max(0, free)
        }
    }

    private func layoutFlex(_ n: N, inner: CGRect, gap: CGFloat, row: Bool) {
        let kids = n.children
        guard !kids.isEmpty else { return }
        let mainAvail = row ? inner.width : inner.height
        let crossAvail = row ? inner.height : inner.width

        struct K { var basis: CGFloat; var cross: CGFloat; var grow: CGFloat; var shrink: CGFloat; var minMain: CGFloat; var maxMain: CGFloat; var stretch: Bool }
        var ks: [K] = []
        for c in kids {
            let node = c.node
            let mainLen = row ? node.w : node.h
            let crossLen = row ? node.h : node.w
            let align = node.alignSelf ?? n.node.align ?? .stretch
            let stretch = align == .stretch && fixed(crossLen, avail: crossAvail) == nil && !isFill(crossLen) && node.aspect == nil
            // แกนขวาง
            var cross: CGFloat
            if let f = fixed(crossLen, avail: crossAvail) { cross = f }
            else if isFill(crossLen) || stretch { cross = crossAvail }
            else { cross = row ? intrinsic(c, availW: nil, availH: crossAvail).height : intrinsic(c, availW: crossAvail, availH: nil).width }
            cross = row ? clampH(node, min(cross, crossAvail)) : clampW(node, min(cross, crossAvail))
            // แกนหลัก
            var grow = CGFloat(node.grow ?? 0)
            var basis: CGFloat
            if let pct = node.pct, let item = c.item {
                // `$field` = 0–100 ของที่ว่าง · `$field/max` = เทียบค่าสูงสุดในรายการ (chips เดียวกัน) · `$field/sum` = ส่วนแบ่งของยอดรวม
                let byMax = pct.hasSuffix("/max"), bySum = pct.hasSuffix("/sum")
                let key = String((byMax || bySum ? String(pct.dropLast(4)) : pct).drop(while: { $0 == "$" }))
                let v = Double(item.value(key)) ?? 0
                var denom: Double = 100
                if byMax { denom = max(1e-9, Double(item.value(key + ".max")) ?? 1) }
                if bySum { denom = max(1e-9, Double(item.value(key + ".sum")) ?? 1) }
                basis = max(0, mainAvail - gap * CGFloat(kids.count - 1)) * CGFloat(min(max(v / denom, 0), 1))
            } else if let f = fixed(mainLen, avail: mainAvail) { basis = f }
            else if isFill(mainLen) { basis = 0; grow = max(grow, 1) }
            else if let a = node.aspect, a > 0 { basis = row ? cross * CGFloat(a) : cross / CGFloat(a) }
            else {
                let s = row ? intrinsic(c, availW: nil, availH: cross) : intrinsic(c, availW: cross, availH: nil)
                basis = row ? s.width : s.height
            }
            // ขนาดที่ระบุตายตัวไม่หด · ข้อความ/คอนเทนเนอร์/ที่ว่าง หดได้ · รูป/ไอคอน/สี่เหลี่ยม ไม่หด
            let defaultShrink: CGFloat = (fixed(mainLen, avail: mainAvail) != nil || node.pct != nil) ? 0
                : (node.type == .text || node.type == .col || node.type == .row || node.type == .chips || node.type == .stack || node.type == .spacer) ? 1 : 0
            let shrink = CGFloat(node.shrink ?? Double(defaultShrink))
            let minMain = CGFloat(row ? node.minW ?? 0 : node.minH ?? 0)
            let maxMain = CGFloat(row ? node.maxW ?? .infinity : node.maxH ?? .infinity)
            ks.append(K(basis: min(max(basis, minMain), maxMain), cross: cross, grow: grow, shrink: shrink,
                        minMain: minMain, maxMain: maxMain, stretch: stretch))
        }
        let gaps = gap * CGFloat(kids.count - 1)
        var sizes = ks.map(\.basis)
        var free = mainAvail - gaps - sizes.reduce(0, +)
        if free > 0 {
            // แจกที่เหลือตาม grow — ชิ้นที่ชน max หยุดรับ แล้วแจกใหม่ให้ที่เหลือ
            var active = Set(ks.indices.filter { ks[$0].grow > 0 })
            var guardN = 0
            while free > 0.001, !active.isEmpty, guardN < 8 {
                let total = active.reduce(0) { $0 + ks[$1].grow }
                var used: CGFloat = 0
                for i in Array(active) {
                    let add = free * ks[i].grow / total
                    let want = sizes[i] + add
                    if want >= ks[i].maxMain { used += ks[i].maxMain - sizes[i]; sizes[i] = ks[i].maxMain; active.remove(i) }
                    else { sizes[i] = want; used += add }
                }
                free -= used; guardN += 1
            }
        } else if free < 0 {
            var deficit = -free
            var active = Set(ks.indices.filter { ks[$0].shrink > 0 && sizes[$0] > ks[$0].minMain })
            var guardN = 0
            while deficit > 0.001, !active.isEmpty, guardN < 8 {
                let weight = active.reduce(0) { $0 + ks[$1].shrink * ks[$1].basis }
                guard weight > 0 else { break }
                var took: CGFloat = 0
                for i in Array(active) {
                    let cut = deficit * ks[i].shrink * ks[i].basis / weight
                    let want = sizes[i] - cut
                    if want <= ks[i].minMain { took += sizes[i] - ks[i].minMain; sizes[i] = ks[i].minMain; active.remove(i) }
                    else { sizes[i] = want; took += cut }
                }
                deficit -= took; guardN += 1
            }
        }
        let used = sizes.reduce(0, +) + gaps
        let off = mainOffset(n.node.justify, free: mainAvail - used, count: kids.count)
        var cursor = (row ? inner.minX : inner.minY) + off.start
        for (i, c) in kids.enumerated() {
            let main = max(0, sizes[i])
            let cross = ks[i].cross
            let align = c.node.alignSelf ?? n.node.align ?? .stretch
            let co = crossOffset(align, free: crossAvail - cross)
            let f = row ? CGRect(x: cursor, y: inner.minY + co, width: main, height: cross)
                        : CGRect(x: inner.minX + co, y: cursor, width: cross, height: main)
            layout(c, frame: f)
            cursor += main + gap + off.between
        }
    }

    // MARK: ออก

    /// ผังที่ใช้กับกรอบ/ข้อมูลนี้ — ผังทางเลือกใบแรกที่ `when` จริง (เงื่อนไขกรอบ หรือเงื่อนไขข้อมูล คั่นด้วย `&`)
    private func selectRoot() -> SpecNode {
        for v in spec.variants ?? [] {
            let ok = v.when.split(separator: "&").allSatisfy { part in
                let e = part.trimmingCharacters(in: .whitespaces)
                let key = e.prefix { $0.isLetter }
                if ["w", "h", "ratio"].contains(String(key)) { return SpecCondition.box(e, box: box) }
                return evaluate(e, item: nil)
            }
            if ok { return v.root }
        }
        return spec.root
    }

    /// เตรียมรอบคำนวณที่ขั้นย่อปัจจุบัน — ล้างแคชข้อความ และให้กล่องตายตัว (`w` `h` `min/max`) โตเท่าที่ตัวอักษรโต:
    /// - ข้อความเอง: ป้ายในช่อง `w: 42` ที่ออกแบบให้ตัว 11pt ต้องกว้างตามตัวที่ใหญ่ขึ้น ไม่งั้นเหลือ "1…"
    /// - กล่องที่ห่อข้อความโดยตรง (pill · ชิป · แถวป้าย): โตตามลูกข้อความที่โตมากสุด ไม่งั้นตัวอักษรล้นทับของข้าง ๆ
    ///   (กล่องชั้นนอกกว่านั้น — การ์ด/แผ่น — ไม่โต ผังจัดที่ให้เองตามปกติ)
    @discardableResult
    private func prepare(_ n: N) -> CGFloat {
        n.textCache.removeAll()
        var g: CGFloat = 1
        if n.base.type == .text {
            let design = baseSize(n.base)
            let legible = legibleSize(n.base, design: design)
            g = design > 0 ? max(design, legible) / design : 1
        } else {
            for c in n.children where c.base.type == .text { g = max(g, prepare(c)) }
            for c in n.children where c.base.type != .text { prepare(c) }
        }
        n.node = g > 1 ? Self.grown(n.base, by: Double(g)) : n.base
        return n.base.type == .text ? g : 1
    }

    /// ขนาดเริ่มที่ยกแล้ว (หน่วยผัง) — ไล่จากขนาดในผังไปหาขั้นต่ำตาม `strength` · 0 = ไม่ยก
    private func legibleSize(_ node: SpecNode, design: CGFloat) -> CGFloat {
        let f = SpecLegibility.floor(design: design, role: node.role, scale: renderScale * scale)
        return f > design ? design + (f - design) * strength : 0
    }

    private static func grown(_ b: SpecNode, by g: Double) -> SpecNode {
        func pt(_ l: SpecLength?) -> SpecLength? { if case .pt(let d)? = l { return .pt(d * g) }; return l }
        var v = b
        v.w = pt(b.w); v.h = pt(b.h)
        v.minW = b.minW.map { $0 * g }; v.maxW = b.maxW.map { $0 * g }
        v.minH = b.minH.map { $0 * g }; v.maxH = b.maxH.map { $0 * g }
        return v
    }

    /// หนึ่งรอบเต็ม: เลือกขั้น `fitScale` แล้วจัดผัง ที่ `strength` ปัจจุบัน
    private func run(_ root: N) {
        var b = box
        scale = 1
        lifted = false
        prepare(root)
        if let steps = spec.fitScale, !steps.isEmpty {
            var chosen = false
            for (i, k) in steps.enumerated() where k > 0 {
                // ขั้นต่ำที่อ่านออกขึ้นกับ k — ผลวัดของขั้นก่อนใช้ซ้ำไม่ได้
                scale = CGFloat(k); prepare(root)
                let kb = CGSize(width: box.width / CGFloat(k), height: box.height / CGFloat(k))
                let need = intrinsic(root, availW: kb.width, availH: nil).height
                if need <= kb.height + 0.5 || i == steps.count - 1 { b = kb; chosen = true; break }
            }
            if !chosen { scale = 1; prepare(root) }
        }
        layout(root, frame: CGRect(origin: .zero, size: b))
    }

    /// ข้อความทุกชิ้น: ขนาดที่วาดจริงบนการ์ด · ล้นกล่องไหม · ขั้นต่ำของมัน — ไว้เทียบกับรอบผังเดิม
    private func texts(_ n: N, into out: inout [String: Drawn]) {
        if n.node.type == .image || n.node.type == .icon {
            // รูป/ไอคอน/QR เป็นเนื้อหาเหมือนกัน — ยกตัวอักษรจนรูปเหลือเป็นเส้นบาง ๆ ไม่คุ้ม
            out[n.id] = Drawn(size: min(n.frame.width, n.frame.height) * scale * renderScale, overflow: false, target: 0, image: true)
        }
        if let t = n.text {
            // ล้นไม่เกิน 30% ของขนาดตัวอักษร = หางสระ/วรรณยุกต์เลยขอบนิดเดียว ตาไม่เห็น · เกินนั้น = ทับของข้าง ๆ
            out[n.id] = Drawn(size: t.size * scale * renderScale, overflow: n.overflow > max(0.5, t.size * 0.3),
                              target: SpecLegibility.target(design: baseSize(n.base), role: n.base.role), image: false)
        }
        for c in n.children { texts(c, into: &out) }
    }
    /// ร่องรอยของรอบหนึ่ง: ชิ้นที่หลุดนอกกรอบแม่ · คู่ข้อความที่ทับกัน — รอบที่ยกต้องไม่มีอะไรใหม่ที่รอบผังเดิมไม่มี
    private func collisions(_ root: N) -> Set<String> {
        var out = Set<String>()
        var texts: [N] = []
        func walk(_ n: N, parent: N?) {
            if let p = parent {
                let a = n.frame, b = p.frame
                if a.minX < b.minX - 1 || a.minY < b.minY - 1 || a.maxX > b.maxX + 1 || a.maxY > b.maxY + 1 { out.insert("out:" + n.id) }
            }
            if let t = n.text, !t.string.isEmpty { texts.append(n) }
            for c in n.children { walk(c, parent: n) }
        }
        walk(root, parent: nil)
        for i in texts.indices {
            for j in texts.indices where j > i {
                let r = texts[i].frame.intersection(texts[j].frame)
                if !r.isNull, r.width > 1, r.height > 1 { out.insert("hit:" + texts[i].id + "|" + texts[j].id) }
            }
        }
        return out
    }

    private struct Drawn { var size: CGFloat; var overflow: Bool; var target: CGFloat; var image: Bool }

    func solve() -> [SpecBox] {
        let rootNode = selectRoot()
        guard let root = expand(rootNode, id: "r", item: nil, depth: 0) else { return [] }
        // ยกตัวอักษรเต็มที่ก่อน · ถ้าไม่มีใครถูกยก = ผังเดิมพอดี
        strength = 1
        run(root)
        if lifted {
            // รอบผังเดิมเป็นเกณฑ์: รอบที่ยกต้องไม่ทำให้ข้อความไหนเล็กกว่าเดิม และไม่ล้นกล่องที่เดิมไม่ล้น
            // (กล่องสูงตายตัว · ชิ้นข้าง ๆ ที่ต้องแบ่งที่กัน) — ไม่ผ่านก็ลดความแรงลงทีละขั้น จนสุดท้ายคือผังเดิม
            strength = 0
            run(root)
            var base: [String: Drawn] = [:]
            texts(root, into: &base)
            let baseHits = collisions(root)
            var ok = false
            for t in SpecLegibility.steps {
                strength = t
                run(root)
                var now: [String: Drawn] = [:]
                texts(root, into: &now)
                // ข้อความเล็กลงกว่าเดิมได้ ถ้ายังไม่ต่ำกว่าขั้นต่ำของมัน (หัว 40 ลงเหลือ 25 ได้ · ต่ำกว่า 18 ไม่ได้)
                // รูปเล็กลงได้ไม่ต่ำกว่า 60% ของเดิม
                ok = now.allSatisfy { id, v in
                    guard let o = base[id] else { return true }
                    if v.image { return v.size >= o.size * SpecLegibility.imageKeep - 0.01 }
                    return v.size >= min(o.size, v.target) - 0.01 && (!v.overflow || o.overflow)
                }
                // ข้อความทับกัน/หลุดกรอบแม่ที่รอบผังเดิมไม่มี = ผังรับไม่ไหว
                if ok { ok = collisions(root).isSubset(of: baseHits) }
                if ok { break }
            }
            if !ok { strength = 0; run(root) }
        }
        var out: [SpecBox] = []
        func walk(_ n: N) {
            func r2(_ v: CGFloat) -> CGFloat { (v * 100).rounded() / 100 }
            let f = CGRect(x: r2(n.frame.minX), y: r2(n.frame.minY), width: r2(n.frame.width), height: r2(n.frame.height))
            out.append(SpecBox(id: n.id, node: n.node, frame: f, text: n.text, item: n.item, depth: n.depth))
            n.children.forEach(walk)
        }
        walk(root)
        return out
    }
}
