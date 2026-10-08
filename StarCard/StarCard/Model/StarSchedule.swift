import SwiftUI

// MARK: - ตารางงานของ Star (ผู้ใช้ 5 ต.ค. 2569)
//
// "หน้า Star Profile จะมีเหมือน Calendar/Reminder ให้คนเข้ามาลงงานที่ตัวเองจะไป" — เป้าคือเปิดแอปบ่อยขึ้น และเรารู้งานของ Star มากขึ้น
// งานมีสองแบบและต้องแยกออกชัด: **งาน Sale Here** ขึ้นเองจากกิจกรรมที่รับไว้ (ไม่ต้องกรอก ติ๊กเองไม่ได้ สถานะมาจากแอป)
// กับ **งานทั่วไป** ที่ Star ลงเอง — ฟอร์มต้องตอบได้ครบ: แบรนด์อะไร · งานอะไร · ลงที่ไหน · ลงอะไรแต่ละที่ · วันไหน · ถ่ายวันไหน
// งานหนึ่งชิ้นแตกเป็น "ขั้น" ที่ขึ้นปฏิทิน: ทำเอง (ถ่าย ลง) · ส่งให้คนอื่น (ดราฟต์ ลิงก์ วางบิล) · รอคนอื่น (รอของ รอแบรนด์ตรวจ รอเงิน)
// ทั้งหมดเป็นข้อมูลจำลองในหน่วยความจำ — ยังไม่มี backend และยังไม่ตั้งแจ้งเตือนจริง

/// วันที่ของตารางงาน — ทุกค่าเป็นต้นวัน เทียบกันได้ตรง ๆ
enum SD {
    static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        return c
    }()
    static var today: Date { cal.startOfDay(for: Date()) }
    static func day(_ offset: Int, from base: Date = today) -> Date { cal.date(byAdding: .day, value: offset, to: base) ?? base }
    static func gap(_ a: Date, _ b: Date) -> Int { cal.dateComponents([.day], from: b, to: a).day ?? 0 }
    static let weekdays = ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"]
    static let months = ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."]
    static func weekday(_ d: Date) -> String { weekdays[cal.component(.weekday, from: d) - 1] }
    static func dayNumber(_ d: Date) -> Int { cal.component(.day, from: d) }
    static func month(_ d: Date) -> String { months[cal.component(.month, from: d) - 1] }
    /// "17 ต.ค."
    static func short(_ d: Date) -> String { "\(dayNumber(d)) \(month(d))" }
    /// "วันนี้" · "พรุ่งนี้" · "ศ. 9 ต.ค."
    static func label(_ d: Date) -> String {
        if d == today { return "วันนี้" }
        if d == day(1) { return "พรุ่งนี้" }
        return "\(weekday(d)). \(short(d))"
    }
    /// หัวรายการของวันที่เลือก — มีทั้งคำและวันที่ ให้ตรงกับเลขบนแถบวัน: "วันนี้ · จ. 5 ต.ค."
    static func title(_ d: Date) -> String {
        let full = "\(weekday(d)). \(short(d))"
        if d == today { return "วันนี้ · \(full)" }
        if d == day(1) { return "พรุ่งนี้ · \(full)" }
        return full
    }
    static let monthsFull = ["มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน", "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม"]
    /// "ตุลาคม 2569"
    static func monthTitle(_ d: Date) -> String { "\(monthsFull[cal.component(.month, from: d) - 1]) \(cal.component(.year, from: d) + 543)" }
    /// "ตุลาคม"
    static func monthName(_ d: Date) -> String { monthsFull[cal.component(.month, from: d) - 1] }
    /// วันนั้นอยู่ห่างจากเดือนนี้กี่เดือน
    static func monthGap(_ d: Date) -> Int { cal.dateComponents([.month], from: firstOfMonth(today), to: firstOfMonth(d)).month ?? 0 }
    static func firstOfMonth(_ d: Date) -> Date { cal.date(from: cal.dateComponents([.year, .month], from: d)) ?? d }
    /// จันทร์ของสัปดาห์ที่วันนั้นอยู่
    static func monday(of d: Date) -> Date { day(-((cal.component(.weekday, from: d) + 5) % 7), from: d) }
    static func baht(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return "฿" + (f.string(from: NSNumber(value: n)) ?? "\(n)")
    }
}

struct JobStep: Identifiable, Hashable, Codable {
    enum Kind: String, Codable { case productWait, shoot, draft, brandReview, event, post, link, invoice, insight, pay }
    var id = UUID()
    var kind: Kind
    var label: String
    var date: Date
    var time: String? = nil
    /// บรรทัดรองเฉพาะขั้น เช่นชิ้นงานของวันลง ("Reel 1 · Story 3")
    var sub: String? = nil
    var done = false

    /// กำลังรอคนอื่น — วงกลมเส้นประ
    var isWait: Bool { kind == .productWait || kind == .brandReview }
}

struct JobItem: Hashable, Codable {
    var name: String
    var count: Int
}

struct JobPost: Identifiable, Hashable, Codable {
    var id = UUID()
    var platform: StarSocial
    var items: [JobItem]
    var date: Date
    var itemsText: String { items.map { "\($0.name) \($0.count)" }.joined(separator: " · ") }
}

struct JobTerm: Hashable, Codable {
    enum Kind: String, Codable { case exclusive, ads }
    var kind: Kind
    var end: Date
    var text: String { kind == .exclusive ? "ห้ามรับแบรนด์คู่แข่ง" : "แบรนด์เอาคลิปไปยิงแอดได้" }
}

struct StarJob: Identifiable, Codable {
    enum Source: String, Codable { case saleHere, own }
    var id = UUID()
    var source: Source
    var brand: String
    var title: String
    /// โลโก้แบรนด์ (asset) — มีเฉพาะงาน Sale Here
    var logo: String? = nil
    var episode: String? = nil
    var posts: [JobPost] = []
    var eventDate: Date? = nil
    var steps: [JobStep] = []
    /// ค่าตัว — เห็นคนเดียว · 0 = ไม่ได้ใส่ / ได้ของอย่างเดียว
    var fee = 0
    var whtDoc = false
    var showOnCard = false
    var terms: [JobTerm] = []
    /// ไปหน้างานที่ไหน
    var place: String? = nil
    /// ได้รับเงินแล้ว — nil/false = ยังรอรับ
    var paid: Bool? = nil

    var isSaleHere: Bool { source == .saleHere }
    var payStep: JobStep? { steps.first { $0.kind == .pay } }
}

/// แพลตฟอร์มที่ลงงานได้ + ชิ้นงานของแต่ละที่
enum JobPlatform {
    static let all: [StarSocial] = [.instagram, .tiktok, .youtube, .facebook]
    static func formats(_ p: StarSocial) -> [String] {
        switch p {
        case .instagram: return ["Reel", "โพสต์", "Story", "ไลฟ์"]
        case .tiktok: return ["คลิป", "ไลฟ์"]
        case .youtube: return ["คลิป", "Shorts", "ไลฟ์"]
        default: return ["โพสต์", "Reel", "ไลฟ์"]
        }
    }
}

/// ร่างของฟอร์ม "ลงงาน" — สามขั้น ถามแค่: แบรนด์/งานอะไร · ลงอะไรบ้าง · ไปหน้างานไหม ที่ไหน เวลาอะไร · ได้เงินเท่าไหร่
/// (ผู้ใช้ 5 ต.ค. 2569: "งงอะ … เอาแค่ เพิ่ม ลงอะไรบ้าง ได้เงินเท่าไหร่ ไป site ไหม ที่ไหน เวลาอะไร พอ")
/// วันถ่าย · ส่งดราฟต์ · ได้ของ/เงิน · จ่ายภายใน · ข้อห้ามจากแบรนด์ เอาออกจากฟอร์มหมดแล้ว และแอปไม่เติมขั้นที่ผู้ใช้ไม่ได้ใส่เอง
struct JobDraft {
    struct Plat {
        var counts: [String: Int] = [:]
        var date: Date?
    }
    var brand = ""
    var title = ""
    var plats: [StarSocial: Plat] = [:]
    var active: StarSocial?
    /// ต้องไปหน้างานไหม — nil = ยังไม่ตอบ
    var site: Bool?
    var siteDate: Date?
    var siteTime: String?
    var sitePlace = ""
    var fee = ""

    var chosen: [StarSocial] { JobPlatform.all.filter { plats[$0] != nil } }
    var firstDate: Date? { plats.values.compactMap(\.date).min() }
    var feeValue: Int { Int(fee.filter(\.isNumber)) ?? 0 }

    /// ขั้นนี้ยังขาดอะไร — "" = ครบ ไปต่อได้
    func missing(step: Int) -> String {
        switch step {
        case 1:
            if brand.trimmingCharacters(in: .whitespaces).isEmpty { return "ชื่อแบรนด์" }
            if title.trimmingCharacters(in: .whitespaces).isEmpty { return "งานอะไร" }
        case 2:
            if chosen.isEmpty { return "ลงที่ไหน" }
            for p in chosen {
                guard let v = plats[p] else { continue }
                if v.counts.values.allSatisfy({ $0 == 0 }) { return "ชิ้นงานของ \(p.short)" }
                if v.date == nil { return "วันลง \(p.short)" }
            }
        default:
            if site == nil { return "ต้องไปหน้างานไหม" }
            if site == true && siteDate == nil { return "วันที่ไปหน้างาน" }
        }
        return ""
    }
    /// แพลตฟอร์มแรกที่ยังกรอกไม่ครบ — กด "ถัดไป" ตอนยังขาด จะสลับแท็บไปที่อันนี้
    var firstIncomplete: StarSocial? {
        chosen.first { p in
            guard let v = plats[p] else { return false }
            return v.date == nil || v.counts.values.allSatisfy { $0 == 0 }
        }
    }

    func posts() -> [JobPost] {
        chosen.compactMap { p in
            guard let v = plats[p], let d = v.date else { return nil }
            let items = JobPlatform.formats(p).compactMap { f in (v.counts[f] ?? 0) > 0 ? JobItem(name: f, count: v.counts[f] ?? 0) : nil }
            return JobPost(platform: p, items: items, date: d)
        }
        .sorted { $0.date < $1.date }
    }

    /// ขั้นของงาน = เฉพาะสิ่งที่กรอก: ไปหน้างาน (ถ้ามี) + ลงคอนเทนต์วันละเรื่อง
    func steps() -> [JobStep] {
        var s: [JobStep] = []
        if site == true, let siteDate {
            let place = sitePlace.trimmingCharacters(in: .whitespaces)
            s.append(JobStep(kind: .event, label: "ไปหน้างาน", date: siteDate, time: siteTime, sub: place.isEmpty ? nil : place))
        }
        // ลงคอนเทนต์ = เรื่องเดียวต่อวัน ไม่ว่ากี่แพลตฟอร์ม — แพลตฟอร์มอ่านจาก `posts` ของวันนั้นตอนวาดการ์ด
        for day in Set(posts().map(\.date)).sorted() { s.append(JobStep(kind: .post, label: "ลงคอนเทนต์", date: day)) }
        return s.sorted { ($0.date, $0.time ?? "99") < ($1.date, $1.time ?? "99") }
    }

    func job() -> StarJob {
        let place = sitePlace.trimmingCharacters(in: .whitespaces)
        return StarJob(source: .own, brand: brand.trimmingCharacters(in: .whitespaces), title: title.trimmingCharacters(in: .whitespaces),
                       posts: posts(), eventDate: site == true ? siteDate : nil, steps: steps(), fee: feeValue,
                       place: site == true && !place.isEmpty ? place : nil)
    }

    /// ฟอร์มที่กรอกตัวอย่างไว้ — ไว้แคปจอเท่านั้น (`-scheduleDemo YES`) ไม่โผล่ในแอปปกติ
    static var demo: JobDraft {
        var d = JobDraft()
        d.brand = "Nami Skin"; d.title = "รีวิวเซรั่ม"
        d.plats[.instagram] = Plat(counts: ["Reel": 1, "Story": 2], date: SD.day(12))
        d.plats[.tiktok] = Plat(counts: ["คลิป": 1], date: SD.day(14))
        d.active = .instagram
        d.site = true; d.siteDate = SD.day(8); d.siteTime = "13:00"; d.sitePlace = "สยามพารากอน"
        d.fee = "6,500"
        return d
    }
}

/// คำถามที่แอปถามตามจังหวะ หลังติ๊กขั้นเสร็จ
struct ScheduleAsk: Identifiable {
    enum Kind { case link, whtDoc, showOnCard }
    let id = UUID()
    let kind: Kind
    let jobID: UUID
    let title: String
    let sub: String
    let yes: String
    let no: String
    let doneText: String
}

@Observable
final class StarSchedule {
    static let shared = StarSchedule()
    /// งานทั้งหมด — เก็บลงเครื่องทุกครั้งที่เปลี่ยน เปิดแอปใหม่งานที่ลงไว้ยังอยู่
    /// ไม่มีข้อมูลตัวอย่างแล้ว (ผู้ใช้ 5 ต.ค. 2569: "ลบทุก Mock เดะเพิ่มเอง") — ตารางเริ่มว่าง · งาน Sale Here จะมาเมื่อผูกกับกิจกรรมจริง
    var jobs: [StarJob] { didSet { save() } }
    private static let key = "starschedule.v1"

    init() {
        // ล้างงานทั้งหมด: เปิดแอปด้วย `-scheduleReset YES`
        if UserDefaults.standard.bool(forKey: "scheduleReset") { UserDefaults.standard.removeObject(forKey: Self.key) }
        if let data = UserDefaults.standard.data(forKey: Self.key), let saved = try? JSONDecoder().decode([StarJob].self, from: data) {
            // งานที่ลงไว้ก่อนหน้า: ตัดขั้นรอที่แอปเคยสร้างให้เองออก
            jobs = saved.map { j in
                var j = j
                // และขั้นที่แอปเคยเติมให้เอง (ส่งลิงก์ · เก็บ Insight · วางบิล · รับเงิน) — เหลือเฉพาะสิ่งที่ผู้ใช้ใส่
                if j.source == .own { j.steps.removeAll { $0.isWait || [.link, .insight, .invoice, .pay].contains($0.kind) } }
                // งานที่ลงไว้ตอนยังแตกแถวละแพลตฟอร์ม: รวมเป็น "ลงคอนเทนต์" วันละเรื่อง
                var seen: Set<Date> = []
                j.steps = j.steps.compactMap { st in
                    guard st.kind == .post else { return st }
                    guard seen.insert(st.date).inserted else { return nil }
                    var st = st
                    st.label = "ลงคอนเทนต์"; st.sub = nil
                    return st
                }
                return j
            }
        } else {
            jobs = []
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(jobs) { UserDefaults.standard.set(data, forKey: Self.key) }
    }

    struct Entry: Identifiable {
        let job: StarJob
        let step: JobStep
        var id: UUID { step.id }
    }

    var entries: [Entry] { jobs.flatMap { j in j.steps.map { Entry(job: j, step: $0) } } }
    /// ขั้นที่เลยวันแล้วยังไม่เสร็จ — ขึ้นบนสุดของรายการ
    var overdue: [Entry] { entries.filter { $0.step.date < SD.today && !$0.step.done }.sorted { $0.step.date < $1.step.date } }
    func upcoming(from d: Date) -> [Entry] {
        entries.filter { $0.step.date >= d && !($0.step.done && $0.step.date < SD.today) }
            .sorted { ($0.step.date, $0.step.time ?? "99") < ($1.step.date, $1.step.time ?? "99") }
    }
    /// วันนั้นยังมีเรื่องต้องทำกี่อย่าง แยกชนิดงาน — ป้ายเลขใต้เลขวัน (แดง = Sale Here · เทา = งานทั่วไป)
    func marks(on d: Date) -> (saleHere: Int, own: Int) {
        let open = entries.filter { $0.step.date == d && !$0.step.done }
        return (open.filter { $0.job.isSaleHere }.count, open.filter { !$0.job.isSaleHere }.count)
    }
    /// วันถัดไปหลังวันนั้นที่ยังมีเรื่องต้องทำ
    func nextDay(after d: Date) -> Date? { entries.filter { $0.step.date > d && !$0.step.done }.map(\.step.date).min() }
    func hasOpen(on d: Date) -> Bool { entries.contains { $0.step.date == d && !$0.step.done } }
    /// ขั้นถัดไปที่ Star ต้องทำเอง — บรรทัดเดียวบนหน้า Star Profile
    var next: Entry? { upcoming(from: SD.today).first { !$0.step.done && !$0.step.isWait } }
    var pendingMoney: Int { jobs.filter { $0.fee > 0 && $0.paid != true }.reduce(0) { $0 + $1.fee } }
    var openCount: Int { entries.filter { !$0.step.done && $0.step.date >= SD.today && SD.gap($0.step.date, SD.today) < 7 }.count }

    func job(_ id: UUID) -> StarJob? { jobs.first { $0.id == id } }

    /// ติ๊กขั้นของงานทั่วไป — คืนคำถามที่ควรถามต่อ (ถ้ามี)
    @discardableResult
    func toggle(job id: UUID, step stepID: UUID) -> ScheduleAsk? {
        guard let j = jobs.firstIndex(where: { $0.id == id }), jobs[j].source == .own,
              let s = jobs[j].steps.firstIndex(where: { $0.id == stepID }) else { return nil }
        jobs[j].steps[s].done.toggle()
        let job = jobs[j], step = job.steps[s]
        guard step.done else { return nil }
        if step.kind == .post, job.steps.contains(where: { $0.kind == .link && !$0.done }) {
            return ScheduleAsk(kind: .link, jobID: id, title: "ลง \(job.brand) แล้ว วางลิงก์เลยไหม", sub: "ส่งให้แบรนด์ และเก็บเป็นผลงานได้ทีเดียว",
                               yes: "วางลิงก์", no: "ทีหลัง", doneText: "เก็บลิงก์แล้ว")
        }
        if step.kind == .pay && !job.whtDoc {
            return ScheduleAsk(kind: .whtDoc, jobID: id, title: "ได้ใบ 50 ทวิจาก \(job.brand) หรือยัง", sub: "ใช้ตอนยื่นภาษีปลายปี",
                               yes: "ได้แล้ว", no: "ยังไม่ได้", doneText: "บันทึกใบ 50 ทวิแล้ว")
        }
        if !job.showOnCard && job.steps.allSatisfy(\.done) {
            return ScheduleAsk(kind: .showOnCard, jobID: id, title: "งาน \(job.brand) จบแล้ว โชว์บน Star Card ไหม", sub: "แบรนด์เห็นชื่อแบรนด์และชิ้นงาน ไม่เห็นค่าตัว",
                               yes: "โชว์", no: "ไม่โชว์", doneText: "เพิ่มผลงานลง Star Card แล้ว")
        }
        return nil
    }

    func answer(_ ask: ScheduleAsk) {
        guard let j = jobs.firstIndex(where: { $0.id == ask.jobID }) else { return }
        switch ask.kind {
        case .link: if let s = jobs[j].steps.firstIndex(where: { $0.kind == .link }) { jobs[j].steps[s].done = true }
        case .whtDoc: jobs[j].whtDoc = true
        case .showOnCard: jobs[j].showOnCard = true
        }
    }

    func setShow(_ id: UUID, _ on: Bool) {
        if let j = jobs.firstIndex(where: { $0.id == id }) { jobs[j].showOnCard = on }
    }
    func setPaid(_ id: UUID, _ on: Bool) {
        if let j = jobs.firstIndex(where: { $0.id == id }) { jobs[j].paid = on }
    }
    func add(_ job: StarJob) { jobs.append(job) }
    func remove(_ id: UUID) { jobs.removeAll { $0.id == id } }
}
