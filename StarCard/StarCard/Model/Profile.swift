import SwiftUI

// MARK: - โปรไฟล์ที่แก้ได้จริง
//
// # ปัญหาที่ไฟล์นี้แก้
//
// ทุก widget เคยอ่าน `Mock.creator` ตรง ๆ ซึ่งเป็น `let` — การ์ดจึงเป็นของนิรา ภัทรวดี เสมอ
// ไม่ว่าใครเปิด คนที่ลองแอปจึงตัดสินใจไม่ได้ว่าการ์ดใบนี้ "เป็นของตัวเอง" หน้าตาเป็นยังไง
//
// ไฟล์นี้คั่นระหว่าง widget กับ `Mock.creator`: ฟิลด์ไหนที่เจ้าของการ์ดพิมพ์เองได้
// (ตามสัญญาใน `WidgetContent.swift` — ช่อง `editable` ของแต่ละตระกูล) จะอ่านผ่านตัวนี้แทน
// ค่าที่ยังไม่เคยแก้ตกไปใช้ `Mock.creator` ต่อ การ์ดจึงไม่มีวันเปิดมาเป็นฟอร์มเปล่า
//
// # ทำไมเก็บต่อ "ตระกูล" ไม่ใช่ต่อ widget
//
// ตามกติกาใน `WidgetContent.swift` — การ์ดหนึ่งใบมีเจ้าของคนเดียว วาง hero สองตัวก็ต้องชื่อเดียวกัน
// แก้ชื่อที่ตัวไหนก็ต้องเปลี่ยนทั้งใบ · สลับแบบแล้วข้อความที่พิมพ์ไว้ต้องอยู่ครบ
//
// # ทำไมเป็น singleton ไม่ใช่ environment
//
// widget อ่านค่าจาก 3 ที่ที่ไม่ได้อยู่ใต้ต้นไม้เดียวกัน: แคนวาส · พรีวิวในตู้ widget ·
// ตัวเรนเดอร์รูปตอนแชร์ (`ImageRenderer` สร้าง hierarchy ใหม่ทั้งก้อน)
// ถ้าเป็น environment ต้องจำฉีดให้ครบทั้งสามที่ ลืมที่ไหนที่นั่นแครช
// `@Observable` ติดตามการอ่านผ่าน property ไม่ใช่ผ่าน environment — singleton จึงอัปเดต view ได้เหมือนกัน

/// ช่องข้อความที่เจ้าของการ์ดพิมพ์เองได้
///
/// `rawValue` ตั้งให้ตรงกับ `key` ใน `FamilyContract.editable` เพื่อให้ mapping กับ API เป็น 1:1
enum ProfileField: String, CaseIterable {
    case name, tagline, about, quote, handle
    /// ข้อความอิสระของวิดเจ็ต `ข้อความ` — **ช่องเดียวที่เก็บต่อชิ้น ไม่ใช่ต่อการ์ด**
    ///
    /// ช่องอื่นเป็นข้อเท็จจริงของเจ้าของการ์ด (มีคำตอบเดียวต่อใบ) ช่องนี้เป็นของตกแต่ง —
    /// วางสองก้อนบนหน้าเดียวแล้วพิมพ์คนละเรื่องคือการใช้งานปกติ จึงอ้างด้วย id ของ widget
    /// (ดู `TextSlotID.widget` และเหตุผลเต็มใน `WidgetContent.swift` ตระกูล `.text`)
    case note
    /// ชื่อเล่นที่ขึ้นเป็นตัวยักษ์ทับภาพ — **ฟิลด์ของตัวเอง ไม่ใช่คำแรกของชื่อ**
    ///
    /// เคยดึงคำแรกของชื่อมาใช้ ซึ่งพังสองทาง: คนที่ชื่อจริงยาวได้ตัวยักษ์เป็นคำที่ไม่มีใครเรียก
    /// และคนที่อยากให้ตัวยักษ์เป็นอย่างอื่นแก้ไม่ได้เลยนอกจากไปแก้ชื่อทั้งชื่อ
    /// ตอนนี้แยกเป็นช่องของตัวเอง แต่ค่าตั้งต้นยังเป็นคำแรกของชื่อ — ไม่มีใครต้องกรอกเพิ่มถ้าไม่อยากแก้
    case nickname
    case contactName, role, phone, email, lineId
    /// สายงานที่พิมพ์เอง — เป็นรายการ จึงอ้างด้วย `index` เสมอ
    case categories
    /// ชื่อรายการกับราคาในเรตการ์ด — เป็นรายการคู่ขนาน ลำดับที่ `i` ของสองช่องคือเรตอันเดียวกัน
    case rateLabels, ratePrices

    var isList: Bool { Self.listFields.contains(self) }

    private static let listFields: Set<ProfileField> = [.categories, .rateLabels, .ratePrices]

    /// ลบทิ้งเมื่อพิมพ์จนว่าง — จริงเฉพาะชิปสายงาน (ลบข้อความ = ลอกสติกเกอร์ใบนั้นทิ้ง)
    ///
    /// เรตราคาต้องไม่ลบ เพราะชื่อรายการกับราคาเป็นสองรายการที่เดินคู่กันด้วย `index` —
    /// ลบข้างเดียวเมื่อไหร่ ราคาของรายการถัดไปเลื่อนขึ้นมาสวมชื่อผิดทันที
    var deletesWhenEmpty: Bool { self == .categories }

    /// ชื่อช่องที่โชว์บนแถบพิมพ์เหนือคีย์บอร์ด — ตรงกับ `label` ใน `FamilyContract.editable`
    var label: String {
        switch self {
        case .name:        return "ชื่อแสดงผล"
        case .note:        return "ข้อความ"
        case .tagline:     return "สายงาน"
        case .about:       return "แนะนำตัว"
        case .quote:       return "คำพูด"
        case .handle:      return "ชื่อผู้ใช้"
        case .contactName: return "ชื่อผู้รับงาน"
        case .role:        return "สถานะผู้รับงาน"
        case .phone:       return "เบอร์โทร"
        case .email:       return "อีเมล"
        case .lineId:      return "ไลน์ไอดี"
        case .categories:  return "สายงานที่พิมพ์เอง"
        case .nickname:    return "ชื่อเล่น"
        case .rateLabels:  return "ชื่อรายการ"
        case .ratePrices:  return "ราคา"
        }
    }

    /// ย่อหน้าพิมพ์หลายบรรทัดได้ ที่เหลือบรรทัดเดียว
    var isParagraph: Bool { self == .about || self == .quote || self == .note }

    /// จำกัดความยาว — ค่าเดียวกับที่ `FamilyContract` ประกาศไว้ · ต้องบังคับฝั่ง API ด้วย
    var limit: Int? {
        switch self {
        case .name, .contactName, .lineId, .handle: return 40
        // ตัวยักษ์ทับภาพ — ยาวกว่านี้ต้องย่อจนอ่านไม่ออกก่อนถึงขอบ
        case .nickname:     return 18
        case .rateLabels:   return 24
        // หลักเดียวพอสำหรับราคางานจ้าง (สูงสุดหลักล้าน) — ยาวกว่านี้คือพิมพ์ผิด
        case .ratePrices:   return 7
        case .tagline:      return 100
        case .about:        return 240
        case .quote:        return 120
        case .note:         return 200
        case .role:         return 60
        case .phone:        return 20
        case .email:        return 60
        case .categories:   return 24
        }
    }

    var keyboard: UIKeyboardType {
        switch self {
        case .phone: return .phonePad
        case .email: return .emailAddress
        case .ratePrices: return .numberPad
        default:     return .default
        }
    }
}

/// ที่อยู่ของช่องข้อความหนึ่งช่อง — ฟิลด์ + ลำดับ (ลำดับมีเฉพาะฟิลด์ที่เป็นรายการ)
struct TextSlotID: Hashable {
    let field: ProfileField
    var index: Int? = nil
    /// ชิ้นที่ข้อความก้อนนี้สังกัด — มีค่าเฉพาะช่องที่เก็บต่อชิ้น (ตอนนี้คือ `.note` ตัวเดียว)
    ///
    /// ช่องอื่นต้องปล่อยเป็น nil เสมอ ไม่งั้นข้อความเดียวกันบนสองชิ้นจะกลายเป็นคนละค่า
    /// แล้วกติกา "การ์ดใบหนึ่งมีเจ้าของคนเดียว" ก็หายไปเงียบ ๆ
    var widget: UUID? = nil
}

@Observable
final class Profile {
    /// การ์ดใบเดียวต่อแอป — ยังไม่มีสถานะ "หลายการ์ด" จึงไม่ต้องมีตัวจัดการที่ซับซ้อนกว่านี้
    static let me = Profile()

    /// ช่องที่กำลังพิมพ์อยู่ — nil คือไม่มีใครถูกแก้
    /// อยู่ที่นี่แทนที่จะอยู่ใน `CardScreen` เพราะทั้งตัว widget (ซ่อนข้อความเดิม)
    /// และชั้นการ์ด (วางช่องพิมพ์ทับ) ต้องอ่านค่าเดียวกัน
    var editing: TextSlotID?

    private var values: [String: String] = [:]
    private var list: [ProfileField: [String]] = [:]
    /// ข้อความอิสระ — คีย์คือ id ของ widget ไม่ใช่ชื่อฟิลด์ (ดู `ProfileField.note`)
    private var notes: [UUID: String] = [:]

    static let notePlaceholder = "แตะเพื่อพิมพ์ข้อความ"

    private init() { load() }

    // MARK: อ่าน

    /// ค่าปัจจุบันของฟิลด์ — ตกไปใช้ค่าตั้งต้นจากระบบเมื่อยังไม่เคยแก้
    func text(_ f: ProfileField, _ i: Int? = nil) -> String {
        if let i {
            let items = items(f)
            return items.indices.contains(i) ? items[i] : ""
        }
        return values[f.rawValue] ?? Profile.fallback(f)
    }

    func items(_ f: ProfileField) -> [String] {
        list[f] ?? Profile.fallbackList(f)
    }

    /// ข้อความอิสระของชิ้นหนึ่ง — ชิ้นที่ยังไม่เคยพิมพ์ได้ประโยคชวนพิมพ์ไปก่อน
    /// (ไม่ใช่ค่าว่าง — วิดเจ็ตที่เพิ่งหยิบออกจากตู้แล้วมองไม่เห็นอะไรเลยอ่านออกมาเป็นแอปพัง)
    func note(_ widget: UUID?) -> String {
        guard let widget, let v = notes[widget] else { return Profile.notePlaceholder }
        return v
    }

    var name: String        { text(.name) }
    var tagline: String     { text(.tagline) }
    var about: String       { text(.about) }
    var quote: String       { text(.quote) }
    var handle: String      { text(.handle) }
    var contactName: String { text(.contactName) }
    var role: String        { text(.role) }
    var phone: String       { text(.phone) }
    var email: String       { text(.email) }
    var lineId: String      { text(.lineId) }
    var categories: [String] { items(.categories) }
    var nickname: String    { text(.nickname) }

    // MARK: เรตราคา — ชื่อรายการกับราคาที่เจ้าของการ์ดตั้งเอง

    /// ชื่อรายการของเรตลำดับที่ `i`
    func rateLabel(_ i: Int) -> String { text(.rateLabels, i) }

    /// ราคาของเรตลำดับที่ `i` — เก็บเป็นข้อความเพราะช่องพิมพ์ทุกช่องเป็นข้อความ
    /// แต่ผู้อ่านต้องได้ตัวเลขเสมอ จึงกรองเฉพาะหลักออกมาที่นี่ที่เดียว
    /// (พิมพ์ค้างไว้เป็นค่าว่างระหว่างทางได้ — คืน 0 ไปก่อน ไม่ใช่พังทั้ง widget)
    func ratePrice(_ i: Int) -> Int {
        Int(text(.ratePrices, i).filter(\.isNumber)) ?? 0
    }

    /// ตัวยักษ์บนแบบ `ArtTypeOver` — ชื่อเล่น
    /// ค่าตั้งต้นคือคำแรกของชื่อ แต่แก้แยกได้ (ดู `ProfileField.nickname`)
    var mark: String { nickname }

    func text(_ id: TextSlotID) -> String {
        id.field == .note ? note(id.widget) : text(id.field, id.index)
    }

    // MARK: เขียน

    func set(_ id: TextSlotID, _ raw: String) {
        let v = String(raw.prefix(id.field.limit ?? 500))
        if id.field == .note {
            guard let w = id.widget else { return }
            notes[w] = v
        } else if let i = id.index {
            var items = items(id.field)
            guard items.indices.contains(i) else { return }
            items[i] = v
            list[id.field] = items
        } else {
            values[id.field.rawValue] = v
        }
    }

    /// ช่องที่ถูกพิมพ์จนว่างเปล่า
    ///
    /// - รายการ (ชิป): ลบชิปใบนั้นทิ้ง — ผู้ใช้ลบข้อความจนหมดคือการบอกว่า "ไม่เอาใบนี้"
    /// - ฟิลด์เดี่ยว: คืนค่าตั้งต้น การ์ดจึงไม่มีบรรทัดว่างที่อธิบายไม่ได้
    func commit(_ id: TextSlotID) {
        let v = text(id).trimmingCharacters(in: .whitespacesAndNewlines)
        if id.field == .note {
            guard let w = id.widget else { return }
            // ลบจนว่าง = คืนประโยคชวนพิมพ์ ไม่ใช่เหลือชิ้นเปล่าที่มองไม่เห็นบนการ์ด
            if v.isEmpty { notes[w] = nil } else { notes[w] = v }
            save()
            return
        }
        if let i = id.index {
            if v.isEmpty {
                var items = items(id.field)
                guard items.indices.contains(i) else { save(); return }
                if id.field.deletesWhenEmpty {
                    items.remove(at: i)
                } else {
                    // คืนค่าตั้งต้นแทนการลบ — ช่องที่หายไปทำให้รายการคู่ขนานเลื่อนสวมกันผิด
                    let base = Profile.fallbackList(id.field)
                    items[i] = base.indices.contains(i) ? base[i] : ""
                }
                list[id.field] = items
            } else {
                set(id, v)
            }
        } else if v.isEmpty {
            values[id.field.rawValue] = nil
        } else {
            values[id.field.rawValue] = v
        }
        save()
    }

    func binding(_ id: TextSlotID) -> Binding<String> {
        Binding(get: { [weak self] in self?.text(id) ?? "" },
                set: { [weak self] in self?.set(id, $0) })
    }

    /// ล้างของที่แก้ไว้ทั้งหมด — กลับไปเป็นโปรไฟล์ตั้งต้น
    func resetAll() {
        values.removeAll()
        list.removeAll()
        notes.removeAll()
        editing = nil
        save()
    }

    var isCustomised: Bool { !values.isEmpty || !list.isEmpty || !notes.isEmpty }

    // MARK: ค่าตั้งต้น

    private static func fallback(_ f: ProfileField) -> String {
        let c = Mock.creator
        switch f {
        case .name:        return c.name
        case .tagline:     return c.tagline
        case .about:       return c.about
        case .handle:      return c.handle
        case .contactName: return c.contact.name
        case .role:        return c.contact.role
        case .phone:       return c.contact.phone
        case .email:       return c.contact.email
        case .lineId:      return c.contact.lineId
        // คำพูดไม่มีที่อยู่ใน `CreatorProfile` เพราะยังไม่มีฟิลด์นี้ใน API เดิม
        // ค่าตั้งต้นจึงอยู่ตรงนี้จุดเดียว — วันต่อ backend ย้ายไปที่โมเดลแล้วลบบรรทัดนี้ทิ้ง
        case .quote:       return "ไม่รีวิวของที่ตัวเองไม่ใช้จริง"
        // ช่องนี้ปกติถูกอ่านผ่าน `note(_:)` ซึ่งรู้จัก id ของชิ้น — ทางนี้คือตอนไม่มีชิ้นให้ถาม
        // (พรีวิวในตู้ widget · thumb ในแผงสลับแบบ)
        case .note:        return Profile.notePlaceholder
        // ค่าตั้งต้นของตัวยักษ์คือคำแรกของ *ชื่อที่ใช้อยู่ตอนนี้* ไม่ใช่ชื่อใน mock —
        // เปลี่ยนชื่อแล้วตัวยักษ์ตามไปเองจนกว่าจะมีคนแก้ช่องนี้จริง ๆ
        case .nickname:
            let n = Profile.me.name
            return n.split(separator: " ").first.map(String.init) ?? n
        case .categories, .rateLabels, .ratePrices: return ""
        }
    }

    private static func fallbackList(_ f: ProfileField) -> [String] {
        switch f {
        case .categories: return Mock.creator.categories
        case .rateLabels: return Mock.creator.rates.map(\.label)
        case .ratePrices: return Mock.creator.rates.map { String($0.price) }
        default:          return []
        }
    }

    // MARK: จำข้ามการเปิดแอป

    private static let key = "starcard.profile.v1"

    private struct Snapshot: Codable {
        var values: [String: String]
        var list: [String: [String]]
        /// ข้อความอิสระต่อชิ้น — คีย์เป็น uuidString · ไฟล์เก่าไม่มีคีย์นี้ จึง optional
        var notes: [String: String]? = nil
        var version: Int = 1
    }

    private func save() {
        let snap = Snapshot(values: values,
                            list: Dictionary(uniqueKeysWithValues: list.map { ($0.key.rawValue, $0.value) }),
                            notes: Dictionary(uniqueKeysWithValues: notes.map { ($0.key.uuidString, $0.value) }))
        guard let data = try? JSONEncoder().encode(snap) else { return }
        UserDefaults.standard.set(data, forKey: Profile.key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Profile.key),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        values = snap.values
        // คีย์ที่ถูกถอดออกไปแล้วจะแปลงกลับไม่ได้ — ข้ามคีย์นั้น ไม่ใช่ทิ้งทั้งโปรไฟล์
        for (k, v) in snap.list {
            if let f = ProfileField(rawValue: k) { list[f] = v }
        }
        for (k, v) in snap.notes ?? [:] {
            if let id = UUID(uuidString: k) { notes[id] = v }
        }
    }
}
