import SwiftUI

// MARK: - โปรไฟล์ที่แก้ได้จริง
//
// # ปัญหาที่ไฟล์นี้แก้
//
// ทุก widget เคยอ่าน `Mock.creator` ตรง ๆ ซึ่งเป็น `let` — การ์ดจึงเป็นของนิรา ภัทรวดี เสมอ
// ไม่ว่าใครเปิด คนที่ลองแอปจึงตัดสินใจไม่ได้ว่าการ์ดใบนี้ "เป็นของตัวเอง" หน้าตาเป็นยังไง
//
// ไฟล์นี้คั่นระหว่าง widget กับข้อมูล: ฟิลด์ไหนที่เจ้าของการ์ดพิมพ์เองได้
// (ตามสัญญาใน `WidgetContent.swift` — ช่อง `editable` ของแต่ละตระกูล) จะอ่านผ่านตัวนี้แทน
//
// # ที่เก็บเดียว — การ์ดกับฟอร์มอ่านเขียนก้อนเดียวกัน
//
// * `values` / `list` / `notes` — ข้อความที่พิมพ์ (บนการ์ดหรือในฟอร์ม ก็ช่องเดียวกัน)
// * `intake` — ของจากฟอร์มที่ไม่ใช่ข้อความ (ช่องทาง · ตารางเรท · หมวด · วันว่าง …) ดู `Intake.swift`
// * `creator` — โปรไฟล์ที่ **widget อ่าน** ประกอบจากสองก้อนบน + ข้อมูลระบบ (ผลงาน · ผู้ชม)
//
// แก้ชื่อบนการ์ด → `values` เปลี่ยน → `creator` ถูกประกอบใหม่ → ฟอร์มที่อ่าน `values` เห็นทันที
// แก้ราคาในฟอร์ม → `intake.rates` เปลี่ยน → `creator.rates` ใหม่ → การ์ดวาดใหม่ — ไม่มีตัว sync แยก
//
// # สามโหมดของค่าตั้งต้น
//
// * ยังไม่มี `intake` — ตกไปใช้ `Mock.creator` การ์ดไม่มีวันเปิดมาเป็นฟอร์มเปล่า (โหมดลองแอป)
// * มี `intake` แล้ว — ช่องที่ยังว่างได้ **ประโยคชวนกรอก** ไม่ใช่ข้อมูลของนิรา
//   (ข้อมูลตัวอย่างปนกับของจริงบนการ์ดใบเดียว = การ์ดโกหก)
// * ข้อมูลระบบ (ผลงานยืนยัน · แบรนด์ · ผู้ชม) ยังเป็นตัวอย่างจนกว่าจะต่อ backend
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
    /// เว็บไซต์ — ขั้นช่องทางติดต่อของ Star Profile (2 ต.ค. 2569)
    case website
    /// สายงานที่พิมพ์เอง — เป็นรายการ จึงอ้างด้วย `index` เสมอ
    case categories
    /// ชื่อรายการกับราคาในเรตการ์ด — เป็นรายการคู่ขนาน ลำดับที่ `i` ของสองช่องคือเรตอันเดียวกัน
    ///
    /// เมื่อมีข้อมูลจากฟอร์มแล้ว สองรายการนี้ **ไม่ได้เก็บแยก** — มันคือมุมมองของ `intake.rates`
    /// พิมพ์ราคาบนการ์ด = แก้ช่องนั้นในตารางของฟอร์ม
    case rateLabels, ratePrices
    /// พื้นที่รับงาน — จังหวัด/เมืองที่รับงานได้ (ป้ายชื่อสติกเกอร์)
    case workArea
    /// สัดส่วนร่างกาย — พิมพ์ค่าพร้อมหน่วยมาเลย ("48 กก." · "31 นิ้ว") ตามธรรมเนียมวงการ
    case weight, height, bust, waist, hips, shoe

    var isList: Bool { Self.listFields.contains(self) }

    private static let listFields: Set<ProfileField> = [.categories, .rateLabels, .ratePrices]

    var isRate: Bool { self == .rateLabels || self == .ratePrices }

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
        case .website:     return "เว็บไซต์"
        case .categories:  return "สายงานที่พิมพ์เอง"
        case .nickname:    return "ชื่อเล่น"
        case .rateLabels:  return "ชื่อรายการ"
        case .ratePrices:  return "ราคา"
        case .workArea:    return "พื้นที่รับงาน"
        case .weight:      return "น้ำหนัก"
        case .height:      return "ส่วนสูง"
        case .bust:        return "รอบอก"
        case .waist:       return "เอว"
        case .hips:        return "สะโพก"
        case .shoe:        return "ขนาดรองเท้า"
        }
    }

    /// ประโยคชวนกรอก — ขึ้นบนการ์ดแทนช่องว่างเมื่อมีฟอร์มแล้วแต่ยังไม่ได้พิมพ์ช่องนี้
    var placeholder: String {
        switch self {
        case .name:        return "ชื่อของคุณ"
        case .nickname:    return "ชื่อเล่น"
        case .tagline:     return "สายงานของคุณ"
        case .about:       return "แนะนำตัวสั้น ๆ ให้แบรนด์รู้จัก"
        case .quote:       return "ประโยคที่อยากบอกแบรนด์"
        case .handle:      return "yourname"
        case .contactName: return "ชื่อผู้รับงาน"
        case .role:        return "ติดต่อโดยตรง"
        case .phone:       return "08x-xxx-xxxx"
        case .email:       return "you@email.com"
        case .lineId:      return "@lineid"
        case .website:     return "yourname.com"
        case .workArea:    return "จังหวัด / เมืองที่รับงาน"
        case .weight:      return "— กก."
        case .height:      return "— ซม."
        case .bust, .waist, .hips: return "— นิ้ว"
        case .shoe:        return "— EU"
        case .note:        return Profile.notePlaceholder
        case .categories, .rateLabels, .ratePrices: return ""
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
        // เท่ากับ About Me ของแอป Sale Here — ข้อความเดียวกันต้องส่งกลับไปที่นั่นได้ไม่ถูกตัด
        case .about:        return 200
        case .quote:        return 120
        case .note:         return 200
        case .role:         return 60
        case .phone:        return 20
        case .email, .website: return 60
        case .categories:   return 24
        case .workArea:     return 30
        case .weight, .height, .bust, .waist, .hips, .shoe: return 12
        }
    }

    var keyboard: UIKeyboardType {
        switch self {
        case .phone: return .phonePad
        case .email: return .emailAddress
        case .website: return .URL
        case .ratePrices: return .numberPad
        default:     return .default
        }
    }
}

/// ที่อยู่ของช่องข้อความหนึ่งช่อง — ฟิลด์ + ลำดับ (ลำดับมีเฉพาะฟิลด์ที่เป็นรายการ)
struct TextSlotID: Hashable {
    let field: ProfileField
    /// ลำดับในรายการ — ฟิลด์รายการ (สายงาน · เรต) หรือ **ช่องอิสระช่องที่เท่าไหร่ของชิ้นนั้น**
    var index: Int? = nil
    /// ชิ้นที่ข้อความก้อนนี้สังกัด — มีค่าเฉพาะช่องที่เก็บต่อชิ้น (ตอนนี้คือ `.note` ตัวเดียว)
    ///
    /// ช่องอื่นต้องปล่อยเป็น nil เสมอ ไม่งั้นข้อความเดียวกันบนสองชิ้นจะกลายเป็นคนละค่า
    /// แล้วกติกา "การ์ดใบหนึ่งมีเจ้าของคนเดียว" ก็หายไปเงียบ ๆ
    var widget: UUID? = nil

    /// ข้อความที่ดีไซน์ของ widget ใส่มาให้ตั้งแต่แรก — ขึ้นบนการ์ดจนกว่าเจ้าของจะพิมพ์ทับ
    ///
    /// แบบบรรณาธิการ (ปกผลงาน · ประโยคไฮไลต์ · ขั้นตอนทำงาน) มีตัวอักษรของตัวเองหลายก้อน
    /// ที่ **เป็นส่วนหนึ่งของผัง** ไม่ใช่ข้อเท็จจริงของเจ้าของการ์ด ถ้าปล่อยว่างตอนหยิบออกจากตู้
    /// ผู้ใช้จะเห็นแผ่นเปล่าแล้วไม่รู้ว่ามันคือแบบไหน — ค่าตั้งต้นจึงเดินทางมากับช่อง ไม่ใช่กับคลังข้อมูล
    /// (ไม่นับตอนเทียบว่าเป็นช่องเดียวกัน — สองที่ที่อ้างช่องเดียวกันต้องเท่ากันเสมอ)
    var preset: String = ""
    /// ชื่อช่องบนแถบพิมพ์ — nil = ใช้ชื่อของฟิลด์ · ช่องอิสระหลายช่องในชิ้นเดียวต้องแยกกันออก
    var hint: String? = nil

    static func == (a: Self, b: Self) -> Bool {
        a.field == b.field && a.index == b.index && a.widget == b.widget
    }

    func hash(into h: inout Hasher) {
        h.combine(field)
        h.combine(index)
        h.combine(widget)
    }
}

/// ที่อยู่ของข้อความอิสระหนึ่งก้อน — ชิ้นไหน ช่องที่เท่าไหร่ (nil = ก้อนข้อความที่มีช่องเดียว)
private struct NoteKey: Hashable {
    let widget: UUID
    let index: Int?

    /// คีย์ที่เขียนลงไฟล์ — ช่องเดี่ยวยังเป็น uuid เปล่าเหมือนเดิม ไฟล์เก่าจึงอ่านได้ครบ
    var stored: String { index.map { "\(widget.uuidString)#\($0)" } ?? widget.uuidString }

    init(_ widget: UUID, _ index: Int?) {
        self.widget = widget
        self.index = index
    }

    init?(stored: String) {
        let parts = stored.split(separator: "#", maxSplits: 1)
        guard let id = UUID(uuidString: String(parts.first ?? "")) else { return nil }
        widget = id
        index = parts.count > 1 ? Int(parts[1]) : nil
    }
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
    /// ข้อความอิสระ — คีย์คือ id ของ widget (+ ช่องที่เท่าไหร่) ไม่ใช่ชื่อฟิลด์ (ดู `ProfileField.note`)
    private var notes: [NoteKey: String] = [:]

    /// ข้อมูลจากฟอร์ม — nil = ยังไม่เคยกรอก การ์ดใช้ `Mock.creator` เป็นตัวอย่างไปก่อน
    private(set) var intake: IntakeData?

    /// โปรไฟล์ที่ widget อ่าน — ประกอบใหม่ทุกครั้งที่อะไรเปลี่ยน (ดูหัวไฟล์)
    /// เป็น stored ไม่ใช่ computed เพราะ `RateItem`/`SocialProfile` ถูกประกอบเป็น array —
    /// computed จะสร้างใหม่ทุกครั้งที่ widget อ่าน ซึ่งเป็นหลายสิบครั้งต่อเฟรม
    private(set) var creator: CreatorProfile = .empty {
        didSet { revision &+= 1 }
    }
    /// นับทุกครั้งที่โปรไฟล์เปลี่ยน — ให้ของที่อบเป็นรูปไว้ (รูปย่อเทมเพลต) รู้ว่าต้องอบใหม่
    @ObservationIgnored private(set) var revision = 0

    @ObservationIgnored private var saveTask: Task<Void, Never>?

    static let notePlaceholder = "แตะเพื่อพิมพ์ข้อความ"

    private init() {
        load()
        creator = buildCreator()
    }

    var hasIntake: Bool { intake != nil }

    // MARK: อ่าน

    /// ค่าปัจจุบันของฟิลด์ — ตกไปใช้ค่าตั้งต้น (ตัวอย่าง หรือประโยคชวนกรอก) เมื่อยังไม่เคยแก้
    func text(_ f: ProfileField, _ i: Int? = nil) -> String {
        if let i {
            let items = items(f)
            return items.indices.contains(i) ? items[i] : ""
        }
        // ค่าว่างที่ค้างอยู่ (ปิดแอปกลางคันขณะช่องยังโฟกัส) นับว่ายังไม่กรอก — ไม่ใช่ชื่อว่างเปล่า
        if let v = values[f.rawValue], !v.isEmpty { return v }
        return fallback(f)
    }

    /// มีค่าที่พิมพ์ไว้จริง (ไม่ใช่ว่าง)
    private func stored(_ f: ProfileField) -> String? {
        guard let v = values[f.rawValue], !v.isEmpty else { return nil }
        return v
    }

    func items(_ f: ProfileField) -> [String] {
        if intake != nil, f == .rateLabels { return rateRows.map(\.label) }
        if intake != nil, f == .ratePrices { return rateRows.map { $0.price > 0 ? String($0.price) : "" } }
        return list[f] ?? fallbackList(f)
    }

    /// ค่าดิบสำหรับช่องพิมพ์ — ประโยคชวนกรอกต้องไม่โผล่ในช่องพิมพ์ ไม่งั้นผู้ใช้ต้องลบมันก่อนพิมพ์
    ///
    /// ยังไม่มีฟอร์ม: ค่าตัวอย่างอยู่ในช่องให้แก้ทับได้ (พฤติกรรมเดิมของโหมดลองแอป)
    /// มีฟอร์มแล้ว: ช่องที่ยังไม่พิมพ์ว่างจริง ๆ
    func raw(_ id: TextSlotID) -> String {
        if id.field == .note {
            // ช่องที่ดีไซน์ใส่ข้อความมาให้ — ค่าตั้งต้นต้องอยู่ในช่องพิมพ์ด้วย
            // ไม่งั้นแตะแล้วเจอช่องเปล่า แล้วต้องพิมพ์ใหม่ทั้งก้อนเพื่อแก้คำเดียว
            return id.widget.flatMap { notes[NoteKey($0, id.index)] } ?? id.preset
        }
        if let i = id.index {
            let items = items(id.field)
            return items.indices.contains(i) ? items[i] : ""
        }
        if let v = values[id.field.rawValue] { return v }
        return intake == nil ? fallback(id.field) : (derived(id.field) ?? "")
    }

    /// ช่องนี้ยังแสดงประโยคชวนกรอกอยู่ — ใช้ตัดสินว่าจะจางลง/นับว่า "ยังขาด"
    func isPlaceholder(_ f: ProfileField) -> Bool {
        guard intake != nil else { return false }
        return stored(f) == nil && derived(f) == nil
    }

    /// ข้อความอิสระของชิ้นหนึ่ง — ชิ้นที่ยังไม่เคยพิมพ์ได้ประโยคชวนพิมพ์ไปก่อน
    /// (ไม่ใช่ค่าว่าง — วิดเจ็ตที่เพิ่งหยิบออกจากตู้แล้วมองไม่เห็นอะไรเลยอ่านออกมาเป็นแอปพัง)
    func note(_ widget: UUID?, _ index: Int? = nil, preset: String = "") -> String {
        guard let widget, let v = notes[NoteKey(widget, index)] else {
            return preset.isEmpty ? Profile.notePlaceholder : preset
        }
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
    var website: String     { text(.website) }
    var categories: [String] { items(.categories) }
    var nickname: String    { text(.nickname) }

    // MARK: เรตราคา — ชื่อรายการกับราคาที่เจ้าของการ์ดตั้งเอง

    /// แถวเรตที่การ์ดวาด — โครงจากตารางในฟอร์ม หรือจากตัวอย่างเมื่อยังไม่มีฟอร์ม
    var rateRows: [RateItem] {
        guard let intake else { return [] }
        return intake.rates.map {
            RateItem(label: $0.displayLabel, price: $0.price, unit: $0.format.unit,
                     format: $0.format, platform: $0.platform, key: $0.formatKey)
        }
    }

    /// ชื่อรายการของเรตลำดับที่ `i`
    func rateLabel(_ i: Int) -> String {
        if lacks(.rate) { return shownRates.indices.contains(i) ? shownRates[i].label : "" }
        return text(.rateLabels, i)
    }

    /// ราคาของเรตลำดับที่ `i` — เก็บเป็นข้อความเพราะช่องพิมพ์ทุกช่องเป็นข้อความ
    /// แต่ผู้อ่านต้องได้ตัวเลขเสมอ จึงกรองเฉพาะหลักออกมาที่นี่ที่เดียว
    /// (พิมพ์ค้างไว้เป็นค่าว่างระหว่างทางได้ — คืน 0 ไปก่อน ไม่ใช่พังทั้ง widget)
    func ratePrice(_ i: Int) -> Int {
        if lacks(.rate) { return shownRates.indices.contains(i) ? shownRates[i].price : 0 }
        return Int(text(.ratePrices, i).filter(\.isNumber)) ?? 0
    }

    /// ตัวยักษ์บนแบบ `ArtTypeOver` — ชื่อเล่น
    /// ค่าตั้งต้นคือคำแรกของชื่อ แต่แก้แยกได้ (ดู `ProfileField.nickname`)
    var mark: String { nickname }

    func text(_ id: TextSlotID) -> String {
        id.field == .note ? note(id.widget, id.index, preset: id.preset)
                          : text(id.field, id.index)
    }

    // MARK: เขียน

    func set(_ id: TextSlotID, _ raw: String) {
        let v = String(raw.prefix(id.field.limit ?? 500))
        if id.field == .note {
            guard let w = id.widget else { return }
            notes[NoteKey(w, id.index)] = v
        } else if let i = id.index {
            if intake != nil, id.field.isRate {
                // ราคา/ชื่อบนการ์ดคือช่องในตารางของฟอร์ม — เขียนกลับไปที่นั่น ไม่มีสำเนาที่สอง
                updateIntake { d in
                    guard d.rates.indices.contains(i) else { return }
                    if id.field == .ratePrices {
                        d.rates[i].price = Int(v.filter(\.isNumber)) ?? 0
                        d.rates[i].touched = true
                    } else {
                        d.rates[i].label = v
                    }
                }
                return
            }
            var items = items(id.field)
            guard items.indices.contains(i) else { return }
            items[i] = v
            list[id.field] = items
        } else {
            values[id.field.rawValue] = v
            pushToStarProfile(id.field, v)
        }
        creator = buildCreator()
        saveSoon()
    }

    /// ช่องที่ถูกพิมพ์จนว่างเปล่า
    ///
    /// - รายการ (ชิป): ลบชิปใบนั้นทิ้ง — ผู้ใช้ลบข้อความจนหมดคือการบอกว่า "ไม่เอาใบนี้"
    /// - ฟิลด์เดี่ยว: คืนค่าตั้งต้น การ์ดจึงไม่มีบรรทัดว่างที่อธิบายไม่ได้
    func commit(_ id: TextSlotID) {
        let v = raw(id).trimmingCharacters(in: .whitespacesAndNewlines)
        if id.field == .note {
            guard let w = id.widget else { return }
            // ลบจนว่าง = คืนของตั้งต้น (ข้อความของดีไซน์ หรือประโยคชวนพิมพ์)
            // ไม่ใช่เหลือชิ้นเปล่าที่มองไม่เห็นบนการ์ด
            let k = NoteKey(w, id.index)
            if v.isEmpty { notes[k] = nil } else { notes[k] = v }
            save()
            return
        }
        if let i = id.index {
            if intake != nil, id.field.isRate {
                // ชื่อว่าง = กลับไปใช้ชื่อมาตรฐาน · ราคาว่าง = 0 ค้างไว้ (ไม่มีค่าตั้งต้นให้คืน)
                if id.field == .rateLabels {
                    updateIntake { d in
                        guard d.rates.indices.contains(i) else { return }
                        d.rates[i].label = v.isEmpty ? nil : v
                    }
                }
                save()
                return
            }
            if v.isEmpty {
                var items = items(id.field)
                guard items.indices.contains(i) else { save(); return }
                if id.field.deletesWhenEmpty {
                    items.remove(at: i)
                } else {
                    // คืนค่าตั้งต้นแทนการลบ — ช่องที่หายไปทำให้รายการคู่ขนานเลื่อนสวมกันผิด
                    let base = fallbackList(id.field)
                    items[i] = base.indices.contains(i) ? base[i] : ""
                }
                list[id.field] = items
            } else {
                var items = items(id.field)
                guard items.indices.contains(i) else { save(); return }
                items[i] = v
                list[id.field] = items
            }
        } else if v.isEmpty {
            values[id.field.rawValue] = nil
            pushToStarProfile(id.field, "")
        } else {
            values[id.field.rawValue] = v
            pushToStarProfile(id.field, v)
        }
        creator = buildCreator()
        save()
    }

    func binding(_ id: TextSlotID) -> Binding<String> {
        Binding(get: { [weak self] in self?.raw(id) ?? "" },
                set: { [weak self] in self?.set(id, $0) })
    }

    /// ทางลัดสำหรับฟอร์ม — ช่องเดี่ยว
    func binding(_ f: ProfileField) -> Binding<String> { binding(TextSlotID(field: f)) }

    /// เพิ่มชิปสายงานที่พิมพ์เอง
    func appendCategory(_ v: String) {
        let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        var items = items(.categories)
        guard !items.contains(t) else { return }
        items.append(String(t.prefix(ProfileField.categories.limit ?? 24)))
        list[.categories] = items
        creator = buildCreator()
        save()
    }

    func removeCategory(_ v: String) {
        var items = items(.categories)
        items.removeAll { $0 == v }
        list[.categories] = items
        creator = buildCreator()
        save()
    }

    /// ล้างของที่แก้ไว้ทั้งหมด — กลับไปเป็นโปรไฟล์ตั้งต้น (รวมข้อมูลฟอร์ม)
    func resetAll() {
        values.removeAll()
        list.removeAll()
        notes.removeAll()
        intake = nil
        editing = nil
        creator = buildCreator()
        save()
    }

    var isCustomised: Bool { !values.isEmpty || !list.isEmpty || !notes.isEmpty || intake != nil }

    // MARK: ฟอร์ม

    /// แก้ข้อมูลฟอร์ม — **ทุกทางที่แก้ `intake` ต้องผ่านตรงนี้** การ์ดถึงจะเห็นและถูกบันทึก
    func updateIntake(_ mutate: (inout IntakeData) -> Void) {
        guard var d = intake else { return }
        mutate(&d)
        guard d != intake else { return }
        intake = d
        creator = buildCreator()
        saveSoon()
    }

    /// Binding ตรงเข้าไปในฟอร์ม — ทุกครั้งที่ SwiftUI เขียน การ์ดก็เปลี่ยนตามในเฟรมเดียวกัน
    func intakeBinding<T: Equatable>(_ path: WritableKeyPath<IntakeData, T>, default d: T) -> Binding<T> {
        Binding(get: { [weak self] in self?.intake?[keyPath: path] ?? d },
                set: { [weak self] v in self?.updateIntake { $0[keyPath: path] = v } })
    }

    /// เริ่มกรอกครั้งแรก — สลับจากโหมดตัวอย่างมาเป็นข้อมูลของตัวเอง
    /// ข้อความที่เคยแก้บนการ์ดไว้ยังอยู่ (มันคือของผู้ใช้จริง ไม่ใช่ตัวอย่าง)
    func beginIntake() {
        guard intake == nil else { return }
        intake = IntakeData()
        creator = buildCreator()
        save()
    }

    /// ยกข้อมูลจากโปรไฟล์ STAR เดิมในระบบเข้ามา — **ตอนนี้ใช้ mock แทน API** (`ProfileCreator` query)
    /// ของจริงคือคนที่เคยกรอกฟอร์มในแอปหลักไว้แล้ว: เปิดหน้า "ข้อมูลของฉัน" ควรเจอของครบ ไม่ใช่ฟอร์มเปล่า
    func importFromSystemProfile() {
        let m = Mock.creator
        var d = IntakeData()
        d.kind = .creator
        d.socials = m.socials.map {
            SocialEntry(type: $0.type,
                        link: $0.profileUrl.isEmpty
                            ? ($0.type.profileURL(handle: $0.handle)?.absoluteString ?? "")
                            : $0.profileUrl,
                        followers: $0.followerCount, source: .connected)
        }
        // หมวดในระบบเดิมสะกดไม่ตรงรายการทางการของฟอร์ม — จับคู่คำที่ซ้อนกัน ไม่บังคับต้องตรงเป๊ะ
        let names = IntakeCatalog.interests.map(\.name)
        var picked: [String] = []
        for c in m.categories + m.interests {
            if let hit = names.first(where: { $0 == c || $0.contains(c) || c.contains($0) }),
               !picked.contains(hit) { picked.append(hit) }
        }
        d.interests = Array(picked.prefix(IntakeCatalog.maxInterests))
        d.rates = m.rates.map { r in
            RateCell(platform: r.platform,
                     formatKey: (r.platform.formats.first { $0.generic == r.format } ?? r.platform.defaultFormat).key,
                     price: r.price, label: r.label, touched: true)
        }
        d.availability = Availability(days: m.workTime.days, slots: m.workTime.slots, draftRounds: 2,
                                      limits: [], otherLimit: "", provinces: [m.location],
                                      booking: m.bookingState.rawValue)
        d.consentAt = Date()
        d.status = .approved
        d.importedAt = Date()
        d.firstRunDone = true

        values[ProfileField.name.rawValue] = m.name
        values[ProfileField.tagline.rawValue] = m.tagline
        values[ProfileField.about.rawValue] = m.about
        values[ProfileField.handle.rawValue] = m.handle
        values[ProfileField.contactName.rawValue] = m.contact.name
        values[ProfileField.role.rawValue] = m.contact.role
        values[ProfileField.phone.rawValue] = m.contact.phone
        values[ProfileField.email.rawValue] = m.contact.email
        values[ProfileField.lineId.rawValue] = m.contact.lineId
        values[ProfileField.workArea.rawValue] = m.location
        list[.categories] = m.categories

        intake = d
        creator = buildCreator()
        save()
    }

    /// เติมข้อมูลตัวอย่างครบทุกช่อง — **สำหรับทดสอบ** เดิน flow ได้โดยไม่ต้องพิมพ์
    ///
    /// ชุดเดียวกับ demo ของฟอร์มเว็บ (มณีรัตน์ ใจดี / mae.review) · สถานะยังเป็น draft และ **ไม่ติ๊กยินยอมให้**
    /// เพราะ PDPA ต้องเป็นการกดของเจ้าตัว — ผู้ทดสอบเหลือแตะเองหนึ่งครั้งที่ขั้นสุดท้าย
    func fillSample() {
        var d = intake ?? IntakeData()
        d.kind = .creator
        d.socials = [
            SocialEntry(type: .instagram, link: "instagram.com/mae.review", followers: 24_800, source: .connected),
            SocialEntry(type: .tiktok, link: "tiktok.com/@mae.review", followers: 86_200, source: .manual),
            SocialEntry(type: .youtube, link: "youtube.com/@maereview", followers: 12_400, source: .api),
        ]
        d.interests = ["แฟชั่น", "คาเฟ่", "ท่องเที่ยว"]
        // ชุดเดียวกับ Shift+D ของฟอร์มเว็บ
        d.rates = [
            RateCell(platform: .instagram, formatKey: "post", price: 1_800, touched: true),
            RateCell(platform: .instagram, formatKey: "carousel", price: 2_300, touched: true),
            RateCell(platform: .instagram, formatKey: "reels", price: 2_900, touched: true),
            RateCell(platform: .tiktok, formatKey: "short", price: 5_400, touched: true),
            RateCell(platform: .tiktok, formatKey: "long", price: 8_100, touched: true),
            RateCell(platform: .tiktok, formatKey: "live", price: 14_000, touched: true),
            RateCell(platform: .youtube, formatKey: "integrated", price: 2_900, touched: true),
            RateCell(platform: .youtube, formatKey: "dedicated", price: 5_200, touched: true),
        ]
        d.availability = Availability(days: Set(0..<7), slots: [1, 2], draftRounds: 2,
                                      limits: ["ไม่รับงานแอลกอฮอล์ / บุหรี่ / บุหรี่ไฟฟ้า", "ไม่รับงานสินเชื่อ / คริปโต"],
                                      otherLimit: "ไม่รับงานที่ต้องค้างคืนต่างจังหวัด",
                                      provinces: ["กรุงเทพมหานคร", "นนทบุรี"],
                                      booking: BookingState.available.rawValue)
        // ปีเป็น ค.ศ. — `Calendar.current` บนเครื่องภาษาไทยเป็นพุทธศักราช จะได้ปี 1455 แทน 1998
        var dob = DateComponents(); dob.year = 1998; dob.month = 4; dob.day = 12
        d.personal = PersonalInfo(dob: Calendar(identifier: .gregorian).date(from: dob), nationality: "ไทย",
                                  gender: "หญิง", religion: "พุทธ", job: "work", faculty: "",
                                  field: "การตลาด / โฆษณา")
        d.payment = PaymentInfo(kind: .person, bank: "กสิกรไทย", accountNo: "1234567890",
                                accountName: "มณีรัตน์ ใจดี", bookPhoto: true)
        d.status = .draft
        d.firstRunDone = false

        let sample: [ProfileField: String] = [
            .name: "มณีรัตน์ ใจดี", .nickname: "เมย์", .tagline: "Fashion & Café Creator",
            .about: "รีวิวแฟชั่นและคาเฟ่แบบใช้จริง ถ่ายเองตัดเองทุกคลิป เน้นลุคใส่ได้ทุกวัน",
            .handle: "mae.review", .contactName: "มณีรัตน์ ใจดี", .role: "ติดต่อโดยตรง · ไม่ผ่านผู้จัดการ",
            .phone: "0812345678", .email: "mae@salehere.co.th", .lineId: "@maereview",
            .workArea: "กรุงเทพมหานคร", .quote: "ไม่รีวิวของที่ตัวเองไม่ใช้จริง",
            .weight: "48 กก.", .height: "165 ซม.", .bust: "32 นิ้ว", .waist: "25 นิ้ว",
            .hips: "35 นิ้ว", .shoe: "23 ซม.",
        ]
        for (f, v) in sample { values[f.rawValue] = v }
        list[.categories] = d.interests

        intake = d
        creator = buildCreator()
        save()
    }

    // MARK: ประกอบโปรไฟล์ที่ widget อ่าน

    /// ตระกูล widget ที่ตอนนี้แสดง **ข้อมูลตัวอย่าง** แทนของจริง (ยังไม่กรอก) — บนการ์ดจริงขึ้นป้ายรอกรอก
    /// ในตู้ widget ยังวาดใบเต็ม ๆ ให้เห็นว่ามีข้อมูลแล้วหน้าตาเป็นยังไง (ผู้ใช้ 24 ก.ย. 2569: "ต้องมี widget ตัวอย่าง")
    private(set) var sampleFamilies: Set<WidgetFamily> = []

    // MARK: โครงตัวอย่างของตระกูลที่ยังไม่มีข้อมูล
    //
    // ใบที่ล็อกต้องเห็นว่า "กรอกแล้วจะได้อะไร" ไม่ใช่กรอบเปล่า (ผู้ใช้ 1 ต.ค. 2569) — widget ของตระกูลนั้น
    // จึงอ่านผ่าน `shown…` : ของจริงถ้ามี · ยังไม่มี = ชุดตัวอย่าง · `creator` ยังว่างจริงเหมือนเดิม
    // ตัวอย่างขึ้นได้แค่ในตู้ widget กับใบที่ล็อกในห้องแต่ง (`sampleData`) — ที่อื่น `WidgetBody.pending`
    // กันไว้ทั้งใบ · widget นอกตระกูลห้ามอ่านทางนี้ ไม่งั้นตัวอย่างหลุดขึ้นการ์ดจริง

    /// ตระกูลนี้ยังไม่มีข้อมูลของเจ้าของการ์ด
    func lacks(_ family: WidgetFamily) -> Bool {
        switch family {
        case .followers: return creator.socials.isEmpty
        case .rate:      return creator.rates.isEmpty
        case .audience:  return creator.audience.isEmpty
        case .brand:     return creator.track.brands.isEmpty
        case .verified:  return creator.track.works.isEmpty
        case .intro:     return stored(.about) == nil
        default:         return false
        }
    }

    var shownSocials: [SocialProfile] { lacks(.followers) ? Mock.creator.socials : creator.socials }
    var shownRates: [RateItem] { lacks(.rate) ? Mock.creator.rates : creator.rates }
    var shownAudience: AudienceInsight { lacks(.audience) ? Mock.creator.audience : creator.audience }
    /// `.brand` หรือ `.verified` — สองตระกูลขาดข้อมูลไม่พร้อมกัน (ตอบรับงานแล้วมีแบรนด์ แต่ยังไม่มีผลงานจนกว่าจะส่งรีวิว)
    func shownTrack(_ family: WidgetFamily) -> TrackRecord { lacks(family) ? Mock.creator.track : creator.track }
    /// แนะนำตัวไม่มี `pending` กันให้ — ผู้เรียกต้องเช็ก `sampleData` เองก่อนอ่านทางนี้
    var shownAbout: String { lacks(.intro) ? Mock.creator.about : about }

    private func buildCreator() -> CreatorProfile {
        guard let d = intake else {
            // ยังไม่มี Star Profile เลย = ว่างทั้งใบ (ไม่ยืมชุดตัวอย่าง — การ์ดจริงเกิดได้หลังมี Star Profile เท่านั้น)
            sampleFamilies = [.followers, .rate, .audience, .brand, .verified]
            return .empty
        }
        // ช่องที่ยังไม่มียอดไม่ขึ้นการ์ด — "Instagram 0" อ่านเป็นข้อมูลผิด ไม่ใช่ข้อมูลที่ยังไม่กรอก
        let socials: [SocialProfile] = d.enabledSocials
            .filter { $0.followers > 0 }
            .sorted { $0.type.formOrder < $1.type.formOrder }
            .map { e in
                // วิว/ER/mix ต้องมาจาก OAuth หรือ API จริงเท่านั้น — ยังไม่ต่อ = 0 แล้ว widget บอกว่า "รอซิงก์"
                // (ไม่จำลองตัวเลขให้ดูดี: ยอดที่ไม่ได้มาจากระบบคือคำโฆษณา ดู `FamilyContract`)
                SocialProfile(type: e.type, handle: "@" + e.handle, followerCount: e.followers,
                              avgEngagementCount: 0, avgViewCount: 0,
                              syncedAgo: e.source.isVerified ? "เชื่อมบัญชีแล้ว" : "กรอกเอง",
                              mix: EngageMix(likes: 0, comments: 0, shares: 0, saves: 0),
                              postsPerWeek: 0, engagementRate: 0,
                              profileUrl: e.link, source: e.source)
            }
        // ช่องทาง/เรทยังว่าง → การ์ดว่าง + ป้ายรอกรอก (`sampleFamilies` = หัวข้อที่ยังไม่มีข้อมูล) — ไม่ยืมตัวอย่างมาวาด (1 ต.ค. 2569)
        var sample: Set<WidgetFamily> = []
        if socials.isEmpty { sample.insert(.followers) }
        if rateRows.isEmpty { sample.insert(.rate) }
        sampleFamilies = sample
        let shownSocials = socials
        let shownRates = rateRows
        let formats = ContentFormat.allCases.filter { f in d.rates.contains { $0.format == f } }
        let a = d.availability
        let state = BookingState(rawValue: a.booking) ?? .available
        let workTime = WorkTime(days: a.days, slots: a.slots)
        let availability = a.days.isEmpty ? state.label : "\(state.label) · \(workTime.daySummary)"

        return CreatorProfile(
            name: name, handle: handle, tagline: tagline, location: text(.workArea), about: about,
            // ตราดาว = ทุกช่องที่เปิดไว้ยืนยันยอดผ่านการเชื่อมบัญชี/API แล้ว (ที่มาเดียวกับป้าย "ยืนยันแล้ว" ของฟอร์มเว็บ)
            // ไม่มีขั้น "ทีมงานอนุมัติ" ใน flow — ยอดที่กรอกเองทีมงานเช็กเบื้องหลัง
            // `-labVerified` บังคับสถานะยืนยันครบ เพื่อดูตราทุกดวงพร้อมกันโดยไม่ต้องแก้ข้อมูลในเครื่อง
            // ตรา Verified = ยืนยันตัวตน (KYC) ผ่านแล้ว — สถานะเดียวกับแถว "ยืนยันตัวตน" ใน Star Profile
            // ยอดผู้ติดตามมาจากแพลตฟอร์มหรือไม่เป็นอีกเรื่อง (ดู `VerifiedFacts.numbersVerified`)
            verified: VerifiedFacts.labForce || d.status == .approved,
            categories: categories, interests: d.interests, styleTags: [], formats: formats,
            workTime: workTime, socials: shownSocials, rates: shownRates,
            // แพ็กเกจ/เงื่อนไขไม่มีในฟอร์มเว็บ · เวลาตอบกลับ ผู้ชม ผลงานยืนยัน มาจากระบบเท่านั้น —
            // ยังไม่ต่อ backend = ว่าง แล้ว `WidgetBody` โชว์ "รอข้อมูลจากระบบ" แทน (ห้ามตัวอย่างปลอม)
            packages: [], terms: .empty,
            // เบอร์/อีเมล/สถานะผู้รับงาน/เวลาตอบกลับ ไม่มีใน Star Profile — การ์ดไม่โชว์ (ดู `FamilyContract` ของ `.contact`)
            contact: ContactInfo(name: contactName, role: "", phone: "", email: "", lineId: lineId, responseTime: ""),
            // ผู้ชม = แนบ "ข้อมูลผู้ติดตาม" ไว้ใน Star Profile แล้วค่อยขึ้น (ตัวเลขยังเป็นตัวอย่างจนกว่าจะต่อ OAuth Insights) · ยังไม่แนบ = "รอข้อมูล"
            audience: StarFlow.shared.audience(),
            // แบรนด์ + ผลงานยืนยัน = หลักฐานจากระบบ Sale Here: แคมเปญที่ตอบรับงาน และงานที่ส่งลิงก์รีวิวแล้ว (ผู้ใช้ 1 ต.ค. 2569)
            track: TrackRecord.fromCampaigns(StarFlow.shared),
            availability: availability, bookingState: state)
    }

    // MARK: ค่าตั้งต้น

    /// ยังไม่กรอก = คำใบ้ภาษาไทยของช่องนั้น ไม่ใช่ข้อมูลตัวอย่าง — ทั้งก่อนและหลังมี `intake`
    private func fallback(_ f: ProfileField) -> String {
        derived(f) ?? f.placeholder
    }

    /// ค่าที่ "รู้ได้เอง" จากช่องอื่นที่กรอกแล้ว — ยังไม่ต้องถามซ้ำ
    private func derived(_ f: ProfileField) -> String? {
        guard let d = intake else { return nil }
        switch f {
        case .name:
            // ชื่อบัญชี Sale Here — Star Profile ไม่ถามชื่อซ้ำ การ์ดจึงใช้ชื่อเดียวกับหน้าโปรไฟล์
            return Profile.accountName
        case .tagline:
            // สายงานใต้ชื่อ = สายที่ใช่ที่เลือกใน Star Profile จนกว่าจะพิมพ์ทับ
            let cats = fallbackList(.categories)
            return cats.isEmpty ? nil : cats.joined(separator: " · ")
        case .handle:
            let h = d.enabledSocials.map(\.handle).first { !$0.isEmpty }
            return h ?? Profile.accountName.lowercased()
        case .contactName:
            return stored(.name)
        case .nickname:
            // ชื่อที่พิมพ์ทับ หรือชื่อบัญชี — ไม่งั้นการ์ดที่ยังไม่ได้พิมพ์ชื่อขึ้น "ชื่อเล่น" เป็นตัวยักษ์
            let n = stored(.name) ?? Profile.accountName
            return n.split(separator: " ").first.map(String.init) ?? n
        case .workArea:
            return d.availability.provinces.first
        case .note:
            return Profile.notePlaceholder
        default:
            return nil
        }
    }

    private func fallbackList(_ f: ProfileField) -> [String] {
        // สายงานบนการ์ดเริ่มจากหมวดทางการที่เลือกในฟอร์ม จนกว่าจะพิมพ์ชิปเอง · ยังไม่กรอก = ว่าง
        guard let d = intake else { return [] }
        return f == .categories ? d.interests.map(IntakeCatalog.short) : []
    }

    // MARK: Star Profile → การ์ด (ดู `StarFlow`)

    /// ชื่อบัญชี Sale Here ของผู้ใช้จำลอง — ที่เดียวกับที่หน้าโปรไฟล์ของแอปหลักอ่าน
    static let accountName = "Tarmjaipa"

    /// รับคำตอบจาก Star Profile มาเป็นข้อมูลของการ์ด — **ทางเดียวที่การ์ดได้ข้อมูลจาก Star Profile**
    ///
    /// กติกา: หัวข้อไหน Star Profile บอกว่า "มีแล้ว" (`have`) ค่อยเอาค่านั้นขึ้นการ์ด · ยังไม่ได้กรอก = ช่องว่าง/ป้ายรอกรอก
    /// ไม่มีข้อมูลตัวอย่างปนเข้ามาแทนช่องที่ยังว่าง (30 ก.ย. 2569: การ์ดโชว์แนะนำตัวของตัวอย่างทั้งที่ยังไม่ได้กรอก)
    ///
    /// ข้อความที่พิมพ์บนการ์ดเอง (ชื่อ · คำพูด · สัดส่วน · ชิปสายงาน) ไม่ถูกแตะ — เป็นของผู้ใช้ ไม่ใช่ของ Star Profile
    /// ยกเว้น `แนะนำตัว` กับ `ไลน์ไอดี` ที่เป็นช่องเดียวกันทั้งสองที่ (พิมพ์บนการ์ดก็เขียนกลับไป Star Profile — ดู `pushToStarProfile`)
    func sync(from f: StarFlow) {
        // build ก่อน 30 ก.ย. 2569 เคยเติมชุดตัวอย่าง "มณีรัตน์ ใจดี" ลงช่องพิมพ์ทุกช่อง — ล้างทิ้ง **ครั้งเดียว**
        // ไม่งั้นค้างเป็น "ของที่ผู้ใช้พิมพ์" · ทำครั้งเดียวเพื่อไม่ไปลบชุดตัวอย่างที่ผู้ทดสอบกดเติมเองทีหลัง (`fillSample`)
        if !UserDefaults.standard.bool(forKey: Profile.purgedKey) {
            UserDefaults.standard.set(true, forKey: Profile.purgedKey)
            if values[ProfileField.name.rawValue] == Profile.sampleName {
                values.removeAll()
                list.removeAll()
            }
        }
        guard !f.have.isEmpty || f.verify != .none else {
            if intake != nil {
                intake = nil
                creator = buildCreator()
                save()
            }
            return
        }
        var d = intake ?? IntakeData()
        d.kind = f.has(.kind) ? CreatorKind(rawValue: f.creatorKind) : nil

        let connected = StarSocial.allCases.filter { f.connected.contains($0) }
        d.socials = f.has(.socials) ? connected.compactMap { s in
            guard let t = SocialType(rawValue: s.rawValue) else { return nil }
            let src = f.followerSources[s.rawValue] ?? s.fetch
            return SocialEntry(type: t, link: f.link(s), followers: f.followers(s),
                               source: src == "api" ? .api : src == "connect" ? .connected : .manual)
        } : []
        d.rates = f.has(.rate) ? connected.flatMap { s -> [RateCell] in
            guard let p = SocialType(rawValue: s.rawValue) else { return [] }
            return s.formats.map { fmt in
                let generic = ContentFormat(rawValue: fmt.rawValue)
                let spec = p.formats.first { $0.generic == generic } ?? p.defaultFormat
                return RateCell(platform: p, formatKey: spec.key, price: f.rate(s, fmt),
                                touched: f.rates["\(s.rawValue)_\(fmt.rawValue)"] != nil)
            }
        } : []
        // ชิปใน wizard เป็น "👗 แฟชั่น" — ตัดอีโมจิแล้วจับคู่กับหมวดทางการของฟอร์ม (คำที่ซ้อนกันพอ ไม่บังคับตรงเป๊ะ)
        d.interests = f.has(.categories) ? f.categories.compactMap { IntakeCatalog.official($0) } : []

        var a = d.availability
        a.provinces = f.has(.province) ? f.provinces : []
        if f.has(.availability) {
            a.days = IntakeCatalog.days(f.availDays)
            // ตารางรายวันรวมกันเป็นชุดเดียว — คีย์ช่วงของ Star Profile = `WorkTime.slotNames` ตัวต่อตัว (4 ช่วงของแอปหลัก)
            a.slots = Set(f.availWeek.values.joined().compactMap { StarFlow.daySlots.firstIndex(of: $0) })
        } else {
            a.days = []
            a.slots = []
        }
        a.draftRounds = f.has(.draftRounds) ? f.draftRounds : nil
        a.limits = f.has(.limits) ? f.limits : []
        a.otherLimit = f.has(.limits) ? f.limitOther : ""
        d.availability = a
        d.personal.religion = f.has(.religion) ? f.religion : ""
        if f.has(.bank) {
            var pay = d.payment ?? PaymentInfo()
            pay.kind = PayKind(rawValue: f.payKind)
            d.payment = pay
        } else {
            d.payment = nil
        }
        switch f.verify {
        case .none: d.status = .draft
        case .waiting: d.status = .pending
        case .rejected: d.status = .draft   // ตีกลับ = ส่งใหม่ได้ ตราไม่ขึ้น
        case .approved: d.status = .approved
        }
        d.consentAt = f.consent ? (d.consentAt ?? Date()) : nil
        d.firstRunDone = true

        // สองช่องนี้ Star Profile เป็นเจ้าของ — มี = ค่าเดียวกัน · ไม่มี = ว่างบนการ์ดด้วย (พิมพ์บนการ์ดก็เขียนกลับไปที่นั่น)
        var v = values
        v[ProfileField.about.rawValue] = f.has(.about) ? f.about : nil
        v[ProfileField.lineId.rawValue] = f.lineID.isEmpty ? nil : f.lineID
        v[ProfileField.phone.rawValue] = f.phone.isEmpty ? nil : f.phone
        v[ProfileField.website.rawValue] = f.website.isEmpty ? nil : f.website
        // สัดส่วนบนการ์ด (widget สายแฟชั่น) = ช่อง "สัดส่วน" ใน Star Profile — ค่าพร้อมหน่วยตามธรรมเนียมของการ์ด ("32 นิ้ว")
        let body = f.has(.body) ? f.bodyInfo : StarBody()
        func sized(_ value: String, _ unit: String) -> String? { value.isEmpty ? nil : "\(value) \(unit)" }
        v[ProfileField.weight.rawValue] = sized(body.weight, "กก.")
        v[ProfileField.height.rawValue] = sized(body.height, StarBody.cm)
        v[ProfileField.bust.rawValue] = sized(body.chest, body.chestUnit)
        v[ProfileField.waist.rawValue] = sized(body.waist, body.waistUnit)
        v[ProfileField.hips.rawValue] = sized(body.hip, body.hipUnit)
        v[ProfileField.shoe.rawValue] = sized(body.shoe, "EU")
        // ชิปสายงานบนการ์ด = สายที่ใช่ใน Star Profile เท่านั้น (ผู้ใช้ 1 ต.ค. 2569) — ชิปที่เคยพิมพ์ค้างบนการ์ดไม่ใช่แหล่งข้อมูล
        let listChanged = list[.categories] != nil
        list[.categories] = nil

        // ประกอบโปรไฟล์ใหม่ทุกครั้ง — แบรนด์/ผลงานยืนยันอ่านสถานะแคมเปญ (`phase` · `reviewed`) ซึ่งไม่ได้อยู่ใน `IntakeData`
        // ถ้าเช็กแค่ intake เปลี่ยน ตอบรับงานแล้วการ์ดก็ยังไม่ขึ้นโลโก้แบรนด์ (เจอ 1 ต.ค. 2569)
        let changed = d != intake || v != values || listChanged
        if changed {
            intake = d
            values = v
        }
        creator = buildCreator()
        if changed { save() }
    }

    /// ช่องที่ Star Profile ก็มี — พิมพ์บนการ์ดแล้วต้องเห็นในหน้า Star Profile ด้วย (ที่เก็บเดียว)
    private func pushToStarProfile(_ f: ProfileField, _ v: String) {
        guard intake != nil else { return }
        let flow = StarFlow.shared
        switch f {
        case .about:
            if flow.about != v { flow.about = v }
            if v.isEmpty { flow.have.remove(.about) } else { flow.have.insert(.about) }
        case .lineId:
            if flow.lineID != v { flow.lineID = v }
        case .phone:
            if flow.phone != v { flow.phone = v }
        case .website:
            if flow.website != v { flow.website = v }
        case .weight, .height, .bust, .waist, .hips, .shoe:
            // ตัวเลขที่พิมพ์บนการ์ด ("32 นิ้ว") → ช่องเดียวกันใน Star Profile · หน่วยรอบตัวตามที่พิมพ์ (นิ้ว/ซม.)
            let num = String(v.filter { $0.isNumber || $0 == "." })
            let unit = v.contains("ซม") ? StarBody.cm : v.contains("นิ้ว") ? StarBody.inch : nil
            var b = flow.bodyInfo
            switch f {
            case .weight: b.weight = num
            case .height: b.height = num
            case .bust: b.chest = num; if let unit { b.chestUnit = unit }
            case .waist: b.waist = num; if let unit { b.waistUnit = unit }
            case .hips: b.hip = num; if let unit { b.hipUnit = unit }
            default: b.shoe = num
            }
            if flow.bodyInfo != b { flow.bodyInfo = b }
            if b.filled { flow.have.insert(.body) } else { flow.have.remove(.body) }
        default:
            break
        }
    }

    /// ชื่อในชุดตัวอย่าง `fillSample` — ใช้จับข้อมูลเก่าที่ต้องล้าง
    static let sampleName = "มณีรัตน์ ใจดี"
    private static let purgedKey = "starcard.profile.samplePurged.v1"

    // MARK: จำข้ามการเปิดแอป

    private static let key = "starcard.profile.v1"

    private struct Snapshot: Codable {
        var values: [String: String]
        var list: [String: [String]]
        /// ข้อความอิสระต่อชิ้น — คีย์เป็น uuidString (+ `#ช่อง` ถ้าชิ้นนั้นมีหลายช่อง)
    /// ไฟล์เก่าไม่มีคีย์นี้ จึง optional
        var notes: [String: String]? = nil
        /// ข้อมูลฟอร์ม — ไฟล์รุ่นก่อนไม่มี = ยังไม่เคยกรอก
        var intake: IntakeData? = nil
        var version: Int = 2
    }

    private func save() {
        saveTask?.cancel()
        let snap = Snapshot(values: values,
                            list: Dictionary(uniqueKeysWithValues: list.map { ($0.key.rawValue, $0.value) }),
                            notes: Dictionary(uniqueKeysWithValues: notes.map { ($0.key.stored, $0.value) }),
                            intake: intake)
        guard let data = try? JSONEncoder().encode(snap) else { return }
        UserDefaults.standard.set(data, forKey: Profile.key)
    }

    /// บันทึกหลังหยุดพิมพ์ครู่หนึ่ง — ทุกตัวอักษรในฟอร์มต้องไม่หายถ้าแอปถูกปิดกลางคัน
    /// แต่ก็ไม่ต้องเขียนดิสก์ทุกคีย์
    private func saveSoon() {
        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            self?.save()
        }
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
            if let key = NoteKey(stored: k) { notes[key] = v }
        }
        intake = snap.intake
    }
}


// MARK: - ค่าว่างของข้อมูลระบบ

/// การ์ดที่ยังไม่มีข้อมูลจากระบบ — ทุกช่องว่างจริง ไม่ใช่ตัวอย่าง (widget อ่านแล้วโชว์ "รอข้อมูลจากระบบ")
extension CreatorProfile {
    static let empty = CreatorProfile(
        name: "", handle: "", tagline: "", location: "", about: "",
        verified: false, categories: [], interests: [], styleTags: [], formats: [],
        workTime: WorkTime(days: [], slots: []), socials: [], rates: [],
        packages: [], terms: .empty,
        contact: ContactInfo(name: "", role: "", phone: "", email: "", lineId: "", responseTime: ""),
        audience: .empty, track: .empty,
        availability: "", bookingState: .available)
}

extension WorkTermsInfo {
    static let empty = WorkTermsInfo(adBoost: "", commercialRights: "", exclusivity: "", rush: "")
}

extension AudienceInsight {
    static let empty = AudienceInsight(female: 0, male: 0, other: 0, ages: [], places: [])
    var isEmpty: Bool { ages.isEmpty && places.isEmpty && female + male + other == 0 }
}

extension TrackRecord {
    /// ประวัติงานจากระบบ Sale Here — ประกอบจากสถานะแคมเปญใน `StarFlow` (ตอนนี้ mock ติดตามแคมเปญเดียว)
    ///
    /// * ตอบรับงานแล้ว (`acceptedQuota`) = ร่วมแคมเปญกับแบรนด์นั้น → ขึ้นโลโก้แบรนด์
    /// * ส่งลิงก์รีวิวแล้ว (`reviewed`) = ผลงานยืนยัน 1 ชิ้น · ยอดวิว/ER ยังไม่มีจากระบบ = 0 แล้ว widget ขึ้น "–"
    /// ของจริงคือ `BrandCampaignDetails` ที่ครีเอเตอร์คนนี้มี state ≥ acceptedQuota
    static func fromCampaigns(_ f: StarFlow) -> TrackRecord {
        guard f.phase == .acceptedQuota else { return .empty }
        let c = StarCampaign.mock[0]
        let brand = Brand(name: c.brand, logo: nil, industry: "", asset: c.logo)
        let platform = SocialType(rawValue: (c.socialChannels.first ?? .instagram).rawValue) ?? .instagram
        let works: [VerifiedWork] = f.reviewed
            ? [VerifiedWork(brand: c.brand, ep: c.episode, campaign: c.title, platform: platform,
                            format: c.contentTypes.first ?? "Photo", views: 0, engagementRate: 0, photo: 0, cover: c.cover)]
            : []
        return TrackRecord(delivered: works.count, accepted: 1, brandCount: 1, brands: [brand],
                           avgEngagementRate: 0, works: works,
                           sales: SalesRecord(code: "", redemptions: 0, clicks: 0, volume: 0, topCategory: "", campaigns: 1),
                           reviews: [])
    }

    static let empty = TrackRecord(delivered: 0, accepted: 0, brandCount: 0, brands: [], avgEngagementRate: 0,
                                   works: [], sales: SalesRecord(code: "", redemptions: 0, clicks: 0, volume: 0,
                                                                 topCategory: "", campaigns: 0),
                                   reviews: [])
}

// MARK: - โหมดลองทำ (ดู `LabSync`)

extension Profile {
    /// ข้อความอิสระของชิ้นที่อยู่บนการ์ดใบหนึ่ง — คีย์แบบที่เขียนลงไฟล์ (`uuid` หรือ `uuid#ช่อง`)
    func labNotes(for widgets: Set<UUID>) -> [String: String] {
        Dictionary(uniqueKeysWithValues: notes.filter { widgets.contains($0.key.widget) }.map { ($0.key.stored, $0.value) })
    }

    /// ข้อมูลเจ้าของการ์ดที่การ์ดอ่าน — ชุดเดียวกับที่เขียนลงดิสก์ (`Snapshot`) ยกเว้นข้อความรายชิ้น
    func labOwner() -> (values: [String: String], list: [String: [String]], intake: IntakeData?) {
        (values, Dictionary(uniqueKeysWithValues: list.map { ($0.key.rawValue, $0.value) }), intake)
    }

    /// ทับข้อมูลเจ้าของการ์ดด้วยชุดที่รับมาจากอีกเครื่อง — คีย์รายการที่เครื่องนี้ไม่รู้จักถูกข้าม (เหมือนตอนโหลดดิสก์)
    func applyLabOwner(values: [String: String], list: [String: [String]], intake: IntakeData?) {
        self.values = values
        self.list = [:]
        for (k, v) in list {
            if let f = ProfileField(rawValue: k) { self.list[f] = v }
        }
        self.intake = intake
        creator = buildCreator()
        save()
    }

    /// ทับข้อความของชิ้นบนการ์ดใบนั้นด้วยชุดที่รับมา — ชิ้นที่ไม่มีในชุดถูกลบ (คืนข้อความตั้งต้น)
    func applyLabNotes(_ incoming: [String: String], for widgets: Set<UUID>) {
        notes = notes.filter { !widgets.contains($0.key.widget) }
        for (k, v) in incoming {
            if let key = NoteKey(stored: k) { notes[key] = v }
        }
        save()
    }
}
