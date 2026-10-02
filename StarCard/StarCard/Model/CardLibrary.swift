import SwiftUI

// MARK: - คลังการ์ดหลายใบ
//
// # ทำไมต้องมีคลัง ทั้งที่ `CardStore` มีช่องร่างอยู่แล้ว
//
// `CardStore` เกิดมาเพื่อกันงานหายระหว่างพัฒนา — หนึ่งช่องต่อรูปแบบ เลือกเทมเพลตใหม่คือทับทิ้ง
// แต่ use case จริงของครีเอเตอร์คือ **การ์ดหลายใบพร้อมกัน**: ใบหลักที่แปะไบโอ ·
// ใบที่ปรับมาพิตช์แบรนด์เฉพาะราย · ใบทดลองเทมเพลตใหม่ที่ยังไม่กล้าใช้จริง
// แต่ละใบมีลิงก์ของตัวเอง และมีใบเดียวที่เป็น "ใบหลัก" — ใบที่ลิงก์ประจำตัวชี้ไป
//
// ยังเป็นที่เก็บฝั่งเครื่อง (UserDefaults) เหมือนเดิม — ของจริงย้ายขึ้น API ได้ทั้งก้อน
// เพราะบันทึกด้วย `CardSnapshot` รูปแบบเดียวกับที่ตกลงกันไว้ว่าจะเป็นรูปแบบฝั่งเซิร์ฟเวอร์

/// การ์ดหนึ่งใบในคลัง
struct CardRecord: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var formatRaw: String
    var snapshot: CardSnapshot
    var createdAt: Date
    var updatedAt: Date

    var format: CardFormat { CardFormat(rawValue: formatRaw) ?? .portfolio }

    /// เปิดใบนี้เป็นสถานะรันไทม์ — ทางเดียวที่ทุกหน้าใช้ ตรารับรองที่ตรึงไว้จึงมาครบทุกที่ที่วาดการ์ด
    func restored() -> (pages: [CardPage], theme: CardTheme, index: Int)? {
        CardStore.restore(snapshot, format: format)
    }

    /// ท้ายลิงก์เฉพาะใบ — สั้นพอพูดต่อโทรศัพท์ได้ ยาวพอไม่ชนกันในคลังเดียว
    var shortID: String { String(id.prefix(6)).lowercased() }

    static func == (l: CardRecord, r: CardRecord) -> Bool {
        l.id == r.id && l.updatedAt == r.updatedAt && l.name == r.name
    }
}

/// คลังการ์ดของเครื่องนี้ + ตัวชี้ว่าใบไหนคือใบหลัก
@Observable
final class CardLibrary {
    static let shared = CardLibrary()

    private(set) var records: [CardRecord] = []
    /// ใบที่ลิงก์ประจำตัว (`star/<handle>`) ชี้ไป — ใบเดียวเสมอ
    /// เก็บเป็น id ไม่ใช่ index เพราะลำดับในคลังเปลี่ยนได้ตลอด (เรียงตามแก้ล่าสุด)
    private(set) var publishedID: String?

    private static let recordsKey = "starcard.library.v1"
    private static let publishedKey = "starcard.library.published"

    var isEmpty: Bool { records.isEmpty }

    /// เรียงโชว์: ใบหลักขึ้นก่อนเสมอ ที่เหลือใหม่สุดก่อน — ใบที่คนอื่นเห็นต้องหาเจอใน 0 วินาที
    var displayOrder: [CardRecord] {
        records.sorted { a, b in
            if a.id == publishedID { return true }
            if b.id == publishedID { return false }
            return a.updatedAt > b.updatedAt
        }
    }

    private init() {
        load()
        migrateLegacyDrafts()
    }

    // MARK: อ่าน/เขียนดิสก์

    private func load() {
        let d = UserDefaults.standard
        if let data = d.data(forKey: Self.recordsKey),
           let list = try? JSONDecoder().decode([CardRecord].self, from: data) {
            records = list
        }
        publishedID = d.string(forKey: Self.publishedKey)
        // ตัวชี้ห้ามชี้ไปใบที่ไม่มีอยู่ — เกิดได้ตอนลบใบหลักแล้วแอปดับกลางทาง
        if let p = publishedID, !records.contains(where: { $0.id == p }) {
            publishedID = records.first?.id
        }
    }

    private func persist() {
        let d = UserDefaults.standard
        if let data = try? JSONEncoder().encode(records) {
            d.set(data, forKey: Self.recordsKey)
        }
        d.set(publishedID, forKey: Self.publishedKey)
    }

    /// ยกร่างเก่าจากระบบช่องเดียว (`CardStore`) เข้าคลัง — งานที่ค้างไว้ก่อนมีคลังต้องไม่หาย
    /// ทำครั้งเดียวตอนคลังยังว่าง แล้วล้างช่องเก่าทิ้งกันไม่ให้ถูกยกซ้ำ
    private func migrateLegacyDrafts() {
        guard records.isEmpty else { return }
        for format in CardFormat.allCases {
            guard let saved = CardStore.load(format) else { continue }
            let record = Self.record(name: "การ์ดของฉัน",
                                     format: format,
                                     pages: saved.pages, theme: saved.theme, index: saved.index)
            records.append(record)
            CardStore.clear(format)
        }
        if publishedID == nil { publishedID = records.first?.id }
        if !records.isEmpty { persist() }
    }

    // MARK: คำสั่งหลัก

    /// เปิดใบใหม่จากเทมเพลต — ตั้งชื่อตามเทมเพลตให้ก่อน (เปลี่ยนไม่ได้ในเวอร์ชันนี้ แต่สื่อพอ)
    /// ใบแรกของคลังเป็นใบหลักอัตโนมัติ: ยังไม่มีใบอื่นให้เลือก และลิงก์ประจำตัวต้องมีปลายทางเสมอ
    @discardableResult
    func create(from template: CardTemplate) -> CardRecord {
        let record = Self.record(name: template.name,
                                 format: template.format,
                                 pages: template.makePages(), theme: template.theme, index: 0)
        records.append(record)
        if publishedID == nil { publishedID = record.id }
        persist()
        return record
    }

    /// การ์ดเปล่า — เริ่มจากหน้าว่างครบจำนวนหน้าของรูปแบบ ธีมตั้งต้น ไม่ต้องผ่านเทมเพลต
    func createBlank(format: CardFormat) -> CardRecord {
        let record = Self.record(name: "การ์ดใหม่", format: format,
                                 pages: (0..<format.pageCount).map { _ in CardPage() },
                                 theme: CardTheme(), index: 0)
        records.append(record)
        if publishedID == nil { publishedID = record.id }
        persist()
        return record
    }

    /// การ์ดตั้งต้นที่ทุกคนมี (ผู้ใช้ 29 ก.ย. 2569) = เทมเพลตออกแบบใบแรก — โชว์บน Star Profile ก่อนมีใบจริง ล่อให้กดเข้าไปดู
    /// ยังไม่อยู่ในคลัง (id คงที่ ให้รูปอบใช้แคชเดิม) · เป็นแค่ภาพตัวอย่าง — เข้า Star Card ครั้งแรกไปหน้าเลือกเทมเพลต (ผู้ใช้ 1 ต.ค. 2569)
    /// `createDefault()` ไม่มีใครเรียกแล้ว (เดิมสร้างใบนี้เป็นใบจริงตอนเข้าครั้งแรก)
    static let defaultTemplate: CardTemplate? = CardTemplate.designed(for: .portfolio).first
    static let defaultPreview: CardRecord? = defaultTemplate.map { t in
        CardRecord(id: "default-card", name: t.name, formatRaw: t.format.rawValue,
                   snapshot: CardStore.snapshot(pages: t.makePages(), theme: t.theme, index: 0),
                   createdAt: .distantPast, updatedAt: .distantPast)
    }
    @discardableResult
    func createDefault() -> CardRecord? { Self.defaultTemplate.map { create(from: $0) } }

    /// สำเนาไว้ลองแก้ — ทางที่ปลอดภัยของ "อยากลองเปลี่ยนโดยไม่แตะใบที่ส่งไปแล้ว"
    @discardableResult
    func duplicate(_ id: String) -> CardRecord? {
        guard let src = records.first(where: { $0.id == id }) else { return nil }
        var copy = Self.record(name: src.name + " (สำเนา)",
                               format: src.format,
                               pages: [], theme: CardTheme(), index: 0)
        copy.snapshot = src.snapshot
        records.append(copy)
        persist()
        return copy
    }

    func card(id: String) -> CardRecord? {
        records.first { $0.id == id }
    }

    /// บันทึกงานแก้ — จุดเดียวที่ห้องแต่งเขียนกลับ
    func save(id: String, pages: [CardPage], theme: CardTheme, index: Int) {
        guard let i = records.firstIndex(where: { $0.id == id }) else { return }
        records[i].snapshot = CardStore.snapshot(pages: pages, theme: theme, index: index)
        records[i].updatedAt = Date()
        persist()
    }

    /// เปลี่ยนชื่อใบ — ชื่อคือเครื่องมือแยกใบตอนคลังโต ("ใบส่ง Cathy Doll" ต้องตั้งได้)
    func rename(_ id: String, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let i = records.firstIndex(where: { $0.id == id }) else { return }
        records[i].name = trimmed
        persist()
    }

    /// ตั้งใบหลัก — สลับตัวชี้เฉย ๆ ไม่มีอะไรถูกลบหรือทับ จึงไม่ต้องมีหน้าต่างยืนยัน
    func setPublished(_ id: String) {
        guard records.contains(where: { $0.id == id }) else { return }
        publishedID = id
        persist()
    }

    /// ลบใบ — ถ้าลบใบหลัก ตัวชี้ตกไปใบล่าสุดที่เหลือ ลิงก์ประจำตัวไม่มีวันชี้ไปความว่างเปล่า
    func delete(_ id: String) {
        records.removeAll { $0.id == id }
        if publishedID == id { publishedID = displayOrder.first?.id }
        persist()
    }

    // MARK: โหมดลองทำ (ดู `LabSync`)

    /// ให้คลังเหลือใบเดียว = การ์ดกลาง · ใบอื่นไม่หายจริง อยู่ในข้อมูลที่ `LabMode` สำรองไว้
    func labKeepOnly(_ id: String) {
        guard records.contains(where: { $0.id == id }) else { return }
        records.removeAll { $0.id != id }
        publishedID = id
        persist()
    }

    /// ใส่การ์ดกลางที่รับมาจากเครื่องอื่น — มีใบอยู่แล้วทับใบนั้น ไม่มีสร้างใหม่ · คืน id ของใบ
    @discardableResult
    func labUpsert(id: String?, name: String, format: CardFormat, snapshot: CardSnapshot) -> String {
        let keep: String
        if let id, let i = records.firstIndex(where: { $0.id == id }) {
            records[i].name = name
            records[i].formatRaw = format.rawValue
            records[i].snapshot = snapshot
            records[i].updatedAt = Date()
            keep = id
        } else {
            let r = CardRecord(id: UUID().uuidString, name: name, formatRaw: format.rawValue,
                               snapshot: snapshot, createdAt: Date(), updatedAt: Date())
            records.append(r)
            keep = r.id
        }
        records.removeAll { $0.id != keep }
        publishedID = keep
        persist()
        return keep
    }

    // MARK: ลิงก์

    /// ลิงก์ของใบนั้น — ใบหลักได้ลิงก์ประจำตัวสั้น ๆ ที่เหลือได้ลิงก์เฉพาะใบ
    func url(for record: CardRecord, slug: String) -> URL {
        let base = "https://\(ClipInvocation.host)/star/\(slug)"
        let raw = record.id == publishedID ? base : "\(base)/c/\(record.shortID)"
        return URL(string: raw)!
    }

    /// แบบสั้นไว้โชว์บนการ์ด — คนอ่านไม่ต้องเห็น https://
    func urlDisplay(for record: CardRecord, slug: String) -> String {
        let u = url(for: record, slug: slug)
        return (u.host ?? "") + u.path
    }

    // MARK: ประกอบ record

    private static func record(name: String, format: CardFormat,
                               pages: [CardPage], theme: CardTheme, index: Int) -> CardRecord {
        CardRecord(id: UUID().uuidString,
                   name: name,
                   formatRaw: format.rawValue,
                   snapshot: CardStore.snapshot(pages: pages, theme: theme, index: index),
                   createdAt: Date(),
                   updatedAt: Date())
    }
}
