import SwiftUI

// MARK: - Tier

/// ชั้นของ widget — กำหนดว่าผู้ใช้แต่งได้แค่ไหน
/// กฎหลักของโปรดักต์: ชั้น `verified` แต่งหน้าตาไม่ได้ เพราะมันคือหลักฐาน ไม่ใช่งานศิลปะ
enum WidgetTier {
    case verified   // แพลตฟอร์มออกให้ · ลากย้ายได้ · ขนาด/หน้าตาล็อก
    case connected  // มาจาก OAuth · เลือก variant + ขนาดได้ · ตัวเลขแก้ไม่ได้
    case personal   // ตัวตน · อิสระเต็มที่

    /// คีย์ใน JSON (`widget.tier`)
    init?(key: String) {
        switch key {
        case "verified": self = .verified
        case "connected": self = .connected
        case "personal": self = .personal
        default: return nil
        }
    }

    var label: String {
        switch self {
        case .verified:  return "หลักฐาน"
        case .connected: return "เชื่อมต่อ"
        case .personal:  return "ตัวตน"
        }
    }
    var icon: String {
        switch self {
        case .verified:  return "checkmark.seal.fill"
        case .connected: return "link"
        case .personal:  return "paintbrush.fill"
        }
    }
}

/// หมวดใน gallery — แบ่งตาม "คำถามที่แบรนด์ถาม" เหลือสามคำถามใหญ่
/// ฉันเป็นใคร · จ้างฉันยังไง · ฉันทำอะไรมาแล้ว
enum WidgetGroup: String, CaseIterable, Identifiable {
    case about, booking, work
    var id: String { rawValue }

    var label: String {
        switch self {
        case .about:   return "เกี่ยวกับฉัน"
        case .booking: return "รับงาน"
        case .work:    return "ผลงาน"
        }
    }
    var icon: String {
        switch self {
        case .about:   return "person.crop.square"
        case .booking: return "briefcase.fill"
        case .work:    return "photo.on.rectangle.angled"
        }
    }
}

/// ตระกูลของ widget — กลุ่มที่ "สลับหน้าตากันได้" เพราะเล่าเรื่องเดียวกัน
///
/// # กติกาข้อบังคับของทุกตระกูล: **ทุกแบบต้องแสดงฟิลด์ชุดเดียวกัน**
///
/// ถ้าแบบหนึ่งโชว์สองบรรทัดแต่อีกแบบโชว์บรรทัดเดียว การกด "แบบอื่น" จะกลายเป็นการ
/// *เพิ่ม/ลดข้อมูล* แทนที่จะเป็นการ *เปลี่ยนหน้าตา* — ผู้ใช้เลือกสไตล์แล้วเสียข้อมูลไปโดยไม่รู้ตัว
/// และการ์ดสองใบที่ใช้แบบต่างกันจะเทียบกันไม่ได้ ซึ่งเป็นสิ่งที่แบรนด์ต้องทำเป็นอันดับแรก
///
/// สัญญาของแต่ละตระกูล (ฟิลด์ที่ **ทุกแบบ** ต้องมี):
/// - `hero` — ชื่อ · ตรายืนยัน · สายงาน
/// - `verified` — รูป · แบรนด์ · แพลตฟอร์ม · ยอดวิว · ยอดบันทึก/แชร์
/// - `followers` — ยอดรายช่อง · ชื่อช่อง
/// - `audience` — เพศ · ช่วงอายุ · ประเทศ · บรรทัดที่มา (ช่อง/ช่วงเวลา/คนดู) ครบทุกชุดในทุกแบบ
/// - `contact` — เบอร์ · อีเมล · ไลน์
///
/// แยกจาก `WidgetGroup` เพราะหมวดใน gallery หยาบแค่สามหมวด
/// ถ้าใช้หมวดมาหาแบบอื่น มันจะเสนอสลับ "ฟิล์มสตริป → โลโก้แบรนด์" ซึ่งคนละเรื่องกัน
enum WidgetFamily: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    // ลำดับนี้คือลำดับที่โผล่ในตู้ — ของหลักมาก่อน ถ้อยคำปิดท้ายทั้งสองหมวด
    //
    // `text` อยู่ต่อจาก `intro` ไม่ใช่ท้ายสุด: มันคือใบที่คนมองหาเวลาอยากเขียนอะไรเอง
    // ซึ่งเป็นความตั้งใจที่เกิดตั้งแต่ต้นการจัดหน้า ไม่ใช่ของปิดท้าย · แล้วใบมันเป็น
    // ตัวหนังสือเปล่าบนพื้นมืด ถ้าไปนั่งท้ายตู้ต่อจากรูปสี่สิบใบก็แทบไม่มีใครเลื่อนไปเจอ
    // `seal` ต่อจาก `hero` ทันที — "ฉันเป็นใคร" กับ "ใครรับรองฉัน" คือสองคำถามแรกของแบรนด์
    // และเป็นใบที่ CEO อยากให้คนเจอเร็วที่สุดในตู้
    case hero, seal, intro, text, followers, audience, tags, brand, verified,
         photo, showcase, rate,
         // ชุดห้าสไตล์ — สองหัวข้อที่ตู้เดิมไม่มี (ผู้ใช้ 12 ต.ค. 2569)
         availability, body,
         contact

    var label: String {
        switch self {
        case .hero:      return "โปรไฟล์"
        case .intro:     return "แนะนำตัว"
        case .brand:     return "แบรนด์"
        case .verified:  return "ผลงานยืนยัน"
        case .seal:      return "ตรารับรอง"
        case .followers: return "ผู้ติดตาม"
        case .photo:     return "รูปผลงาน"
        case .showcase:  return "แผ่นโชว์ผลงาน"
        case .text:      return "ข้อความ"
        case .tags:      return "หมวดหมู่"
        case .audience:  return "ผู้ชม"
        case .rate:      return "เรตราคา"
        case .contact:   return "ติดต่อ"
        case .availability: return "วันเวลาและพื้นที่"
        case .body:      return "สัดส่วน"
        }
    }

    /// หัวข้อใน Star Profile ที่ตระกูลนี้ดึงข้อมูลมาโชว์ — nil = ไม่ผูก (ของตกแต่ง / ผลงานจาก Portfolio / ข้อมูลบัญชี)
    ///
    /// ผูกแล้วได้สองอย่าง: ยังไม่กรอกหัวข้อนั้น = ช่องในตู้พาไปกรอกข้อนั้นข้อเดียว ·
    /// กรอกครบ = ทุกแบบในตระกูลใช้ได้ทันที (ผู้ใช้ 23 ก.ย. 2569)
    var topic: StarTopic? {
        switch self {
        case .hero, .tags: return .data(.categories)
        case .followers:   return .data(.socials)
        case .intro: return .data(.about)
        case .rate:        return .data(.rate)
        case .audience:    return .data(.insight)
        case .seal:        return .verify
        // แบรนด์ + ผลงานยืนยัน = หลักฐานจากระบบ ปลดล็อกเมื่อทำงานผ่าน Sale Here จบแล้วอย่างน้อย 1 งาน (ผู้ใช้ 23 ก.ย. 2569)
        case .brand, .verified: return .work
        // ติดต่อ · รูปผลงาน ผูกหัวข้อด้วย (ผู้ใช้ 19 ต.ค. 2569: เปิดการ์ดถามแค่ 3 ข้อ "ที่เหลือถ้ายังไม่กรอก จะโดน Lock")
        case .contact: return .data(.contact)
        case .photo, .showcase: return .data(.media)
        case .text: return nil
        case .availability: return .data(.availability)
        case .body:        return .data(.body)
        }
    }
    /// ส่วนของตู้ (เกี่ยวกับฉัน · รับงาน · ผลงาน) — ทั้งหมวดเท่ากัน
    var group: WidgetGroup {
        switch self {
        case .hero, .seal, .intro, .text, .followers, .audience, .tags, .body: return .about
        case .rate, .availability, .contact: return .booking
        case .brand, .verified, .photo, .showcase: return .work
        }
    }

    /// ชั้นสิทธิ์ตั้งต้นของหมวด — ใบที่ต่างจากเพื่อนใส่ `widget.tier` ทับ
    var tier: WidgetTier {
        switch self {
        case .followers, .audience, .rate: return .connected
        case .brand, .verified, .seal: return .verified
        default: return .personal
        }
    }

    /// ใบในหมวดนี้ยังล็อกอยู่ไหม — หัวข้อ Star Profile ที่หมวดอ่านยังไม่ได้กรอก
    /// ตรารับรองล็อกจนกว่าการยืนยันตัวตนจะ **ผ่าน** (ไม่ใช่แค่ส่งแล้ว) — มีสองสถานะ: ผ่าน หรือ ล็อก
    var missing: Bool {
        if self == .seal { return !VerifiedFacts.sealed }
        return topic.map { !$0.filled } ?? false
    }
}

/// หมวดในตู้ widget = หัวข้อของ Star Profile (ผู้ใช้ 23 ก.ย. 2569: "cat ต้องตรงกับ Star Profile แล้ว scroll เอาแทน")
///
/// ชิปเลื่อนแนวนอนแทนแท็บสามแท็บ · ลำดับ = ลำดับที่การ์ดเล่าเรื่อง (ฉันเป็นใคร → ช่อง → สาย → แนะนำตัว → เรท → ผู้ติดตาม → ตรา)
/// สามหมวดท้ายไม่ผูกกับ Star Profile: ผลงาน (จาก Portfolio) · ติดต่อ (จากบัญชี) · ข้อความ (ของตกแต่ง)
enum TrayGroup: String, CaseIterable, Identifiable {
    case profile, channels, niche, intro, body, rate, schedule, audience, verify, work, contact, decor
    var id: String { rawValue }

    var label: String {
        switch self {
        case .profile: return "โปรไฟล์"
        case .channels: return "ช่องทาง"
        case .niche: return "สายที่ใช่"
        case .intro: return "แนะนำตัว"
        case .rate: return "เรทรับงาน"
        case .body: return "สัดส่วน"
        case .schedule: return "วันเวลา·พื้นที่"
        case .audience: return "ข้อมูลผู้ติดตาม"
        case .verify: return "ยืนยันตัวตน"
        case .work: return "ผลงาน"
        case .contact: return "ติดต่อ"
        case .decor: return "ข้อความ"
        }
    }

    var topic: StarTopic? {
        switch self {
        case .profile, .niche: return .data(.categories)
        case .channels: return .data(.socials)
        case .intro: return .data(.about)
        case .rate: return .data(.rate)
        case .audience: return .data(.insight)
        case .body: return .data(.body)
        case .schedule: return .data(.availability)
        case .verify: return .verify
        case .contact: return .data(.contact)
        case .work: return .data(.media)
        case .decor: return nil
        }
    }
}

extension WidgetFamily {
    var trayGroup: TrayGroup {
        switch self {
        case .hero: return .profile
        case .followers: return .channels
        case .tags: return .niche
        case .intro: return .intro
        case .rate: return .rate
        case .audience: return .audience
        case .seal: return .verify
        case .photo, .showcase, .brand, .verified: return .work
        case .contact: return .contact
        case .text: return .decor
        case .availability: return .schedule
        case .body: return .body
        }
    }
}

/// หัวข้อ Star Profile ที่ widget ผูกอยู่ — ช่องข้อมูล หรือ ยืนยันตัวตน
enum StarTopic: Hashable {
    case data(StarDataKey)
    case verify
    /// เคยทำงานผ่าน Sale Here จบแล้ว — กรอกเองไม่ได้ ต้องไปรับงาน
    case work

    var label: String {
        switch self {
        case .data(let k): return k.label
        case .verify: return "ยืนยันตัวตน"
        case .work: return "ผลงานกับ Sale Here"
        }
    }
    /// คำบนปุ่มของใบที่ยังว่าง
    var action: String {
        switch self {
        case .data(let k): return fillable ? "กรอก\(k.label)" : "กรอกข้อมูลเพื่อปลดล็อก"
        case .verify: return fillable ? "ยืนยันตัวตน" : "ยืนยันตัวตนเพื่อปลดล็อก"
        case .work: return "ทำงานกับ Sale Here ก่อน"
        }
    }
    /// คำบอกที่หัวหมวด
    var missingLine: String {
        switch self {
        case .data(let k): return "ยังไม่มี\(k.label)"
        case .verify: return "ยังไม่ได้ยืนยันตัวตน"
        case .work: return "ปลดล็อกเมื่อทำงานผ่าน Sale Here จบ 1 งาน"
        }
    }
    /// ปลดล็อกด้วยการกรอกได้ไหม (ผลงานกับ Sale Here ต้องไปรับงาน ไม่มี wizard)
    /// ล็อก = ยังไม่มีข้อมูล · แตะแล้วกรอกได้เลย (ผู้ใช้ 29 ก.ย. 2569: "กดแล้วให้เค้ากรอกข้อมูลได้")
    /// ผลงานกับ Sale Here กรอกเองไม่ได้ ต้องไปรับงาน
    var fillable: Bool { self != .work }
    /// ขั้นของ wizard ที่ต้องเปิดเพื่อกรอกหัวข้อนี้
    var step: WizStep {
        switch self {
        case .data(let k): return WizStep(rawValue: k.rawValue) ?? .about
        case .verify: return .kyc
        case .work: return .about
        }
    }
    /// กรอกหัวข้อนี้แล้วหรือยัง (ดูจาก state ของ flow ใหม่ — ตัวเดียวกับ Star Profile)
    var filled: Bool {
        switch self {
        case .data(let k): return StarFlow.shared.has(k)
        case .verify: return StarFlow.shared.verify != .none
        case .work: return StarFlow.shared.reviewed
        }
    }
}

// MARK: - วัสดุของสำรับสติกเกอร์

/// กระดาษเทป หรือ กระจกชมพู — เดิมคำนวณจากมุมของธีม ตอนนี้เป็นส่วนหนึ่งของชนิด
/// (ดู `WidgetKind.popSkin` · หน้าตาของแต่ละวัสดุอยู่ใน `PopWidgets.swift`)
enum PopSkin: String, CaseIterable, Sendable {
    case paper, glass

    var label: String {
        switch self {
        case .paper: return "กระดาษเทป"
        case .glass: return "กระจกชมพู"
        }
    }
}

// MARK: - Kind

/// ชนิดของ widget = ชื่อไฟล์ผัง `shared/WidgetSpecs/<kind>.json`
///
/// **แอปไม่รู้จักชื่อ widget สักตัว** (ผู้ใช้ 15 ต.ค. 2569: "Renderer ต้องเป็น standalone ตัวกลางไว้อ่าน json เท่านั้น")
/// ทุกนิสัย — ชื่อในตู้ · ไอคอน · ขนาด · พื้นผิว · ถาด · ป้าย · ท่าเข้า — อ่านจากบล็อก `widget` ของไฟล์ผัง
/// ค่าที่ไม่ใส่ใช้ค่าของหมวด (`WidgetFamily`) หรือกติกากลางข้างล่าง · เพิ่มไฟล์ใหม่ = ขึ้นตู้ทันที ลบไฟล์ = หายจากตู้เฉย ๆ
///
/// ข้อยกเว้นเดียวคือ **ชั้นข้อความ** (`textLayer`) — ตัวอักษรที่พิมพ์ลงการ์ดแบบ IG ไม่ใช่ widget จึงไม่มีไฟล์ผัง
/// (ดู `TextBlock.layer`) · คีย์ในไฟล์การ์ดยังเป็น `textBlock` ตามเดิม การ์ดเก่าจึงเปิดได้
struct WidgetKind: Hashable, Identifiable {
    /// คีย์ที่บันทึกลงการ์ด = ชื่อไฟล์ผัง
    let rawValue: String

    private init(raw: String) { self.rawValue = raw }

    /// ชนิดจากไฟล์ผังที่ลงทะเบียนไว้ — ไม่รู้จัก = nil
    ///
    /// หมวดต้องเป็นหมวดที่แอปมีอยู่แล้ว — หมวดใหม่/ไม่ใส่หมวด = ยังไม่ขึ้น จนกว่าแอปจะเพิ่มหมวดนั้นในโค้ด
    init?(rawValue: String) {
        if rawValue == TextBlock.layerKey { self.init(raw: rawValue); return }
        guard let m = SpecCatalog.widgetMeta(rawValue),
              m.category.flatMap(WidgetFamily.init(rawValue:)) != nil else { return nil }
        self.init(raw: rawValue)
    }

    /// ชั้นข้อความของการ์ด — ไม่ใช่ widget (ไม่มีผัง · ไม่อยู่ในตู้)
    static let textLayer = WidgetKind(raw: TextBlock.layerKey)
    var isTextLayer: Bool { rawValue == TextBlock.layerKey }

    /// ทุกชนิดจากไฟล์ผัง เรียงตาม `widget.order` (ไม่ใส่ = ท้ายสุด) แล้วตามชื่อ
    ///
    /// คิดครั้งเดียวต่อชุดผัง (`SpecCatalog.generation`) — ถาดเรียกตัวนี้ทุกเฟรมตอนลาก/ยืด (แถว "แบบ")
    static var allCases: [WidgetKind] {
        if let c = sortedCache, c.generation == SpecCatalog.generation { return c.kinds }
        let kinds = SpecCatalog.widgetKinds.compactMap(WidgetKind.init(rawValue:)).sorted { a, b in
            let ao = a.meta.order ?? .max, bo = b.meta.order ?? .max
            return ao != bo ? ao < bo : a.rawValue < b.rawValue
        }
        sortedCache = (SpecCatalog.generation, kinds)
        return kinds
    }
    private static var sortedCache: (generation: Int, kinds: [WidgetKind])?

    /// นิสัยของชนิดนี้ — บล็อก `widget` ของไฟล์ผัง (ชั้นข้อความใช้ของมันเองใน `TextBlock.layer`)
    var meta: WidgetSpec.Widget {
        if isTextLayer { return TextBlock.layer }
        return SpecCatalog.widgetMeta(rawValue) ?? WidgetSpec.Widget(title: rawValue)
    }

    static func == (a: WidgetKind, b: WidgetKind) -> Bool { a.rawValue == b.rawValue }
    func hash(into h: inout Hasher) { h.combine(rawValue) }

    var id: String { rawValue }

    /// อ่านชนิดจากไฟล์ — ชื่อเก่าที่ถอดออกแล้วตกไปที่ใบที่ประกาศ `widget.replaces` ไว้
    ///
    /// ไฟล์เก่าของสำรับสติกเกอร์เขียนแค่ `popHero` (ก่อนแยกวัสดุ) — ลองต่อท้ายด้วยวัสดุตามธีมของไฟล์นั้น
    /// (`corner == .soft` = กระดาษ) การ์ดเก่าเปิดมาแล้วหน้าตาไม่ขยับสักใบ
    ///
    /// ชุดห้าสไตล์ก่อน 19 ต.ค. 2569 เป็นชนิดเดียวต่อหัวข้อ + `kit.style` ในชิ้น — `kitLook` = สไตล์นั้น
    /// ได้ชนิดใหม่ที่ `widget.kit.look` ตรงกัน หน้าตาเดิมไม่ขยับ
    static func decode(_ raw: String, legacyPopSkin: PopSkin = .glass, kitLook: String? = nil) -> WidgetKind? {
        if let k = WidgetKind(rawValue: raw) { return k }
        if let k = SpecCatalog.replacement(for: raw, look: kitLook).flatMap(WidgetKind.init(rawValue:)) { return k }
        let suffix = legacyPopSkin == .paper ? "Paper" : "Glass"
        return WidgetKind(rawValue: raw + suffix)
    }

    /// หมวดใน gallery — ค่าของหมวด (`WidgetFamily.group`)
    var group: WidgetGroup { family.group }

    /// ตระกูล — ใช้หา "แบบอื่น" ที่สลับกันแล้วยังเล่าเรื่องเดิม
    var family: WidgetFamily { meta.category.flatMap(WidgetFamily.init(rawValue:)) ?? .text }

    /// ชั้นสิทธิ์ — ค่าของหมวด · ใบที่ต่างจากเพื่อนใส่ `widget.tier` ทับ
    var tier: WidgetTier { meta.tier.flatMap(WidgetTier.init(key:)) ?? family.tier }

    /// widget ที่ **วาดพื้นผิวของตัวเอง** (`widget.ownSurface`) — chrome จึงไม่ครอบแผ่นซ้ำ
    var drawsOwnSurface: Bool { meta.ownSurface ?? false }

    /// ชิ้นที่ให้ผู้ใช้เลือกพื้นผิวได้
    var usesSurfaceChoice: Bool { surfaceOptions.count > 1 }
    /// ใส่ลายทางบนแผ่นได้ (`widget.pattern`)
    /// อ่าน `WidgetInstance.textStyle` — เฉพาะชั้นข้อความ
    var usesTextStyle: Bool { isTextLayer }
    /// โชว์รูปครีเอเตอร์/ผลงาน — อัปโหลดรูปทับได้ (`widget.photo`)
    var usesPhoto: Bool { meta.photo ?? false }
    /// รูปชนขอบ ไม่เว้น padding (`widget.fullBleed`)
    var isFullBleed: Bool { meta.fullBleed ?? false }

    var title: String { meta.title }
    var symbol: String { meta.symbol ?? "square.fill" }

    /// ขนาดตั้งต้นตอนหยิบออกจากตู้ — `widget.size` ไม่ใส่ = ขนาดออกแบบของผัง
    var defaultSize: CGSize {
        if let s = meta.size { return s.cg }
        return SpecCatalog.spec(named: rawValue)?.design.cg ?? CGSize(width: 366, height: 224)
    }

    /// สัดส่วนที่ผังถูกออกแบบไว้ — จุดอ้างอิงของการสเกล ไม่ใช่กรงที่ขังกรอบ
    var aspect: CGFloat {
        let s = defaultSize
        return s.height / max(s.width, 1)
    }

    /// ความสูงที่คู่กับความกว้างนี้ตามสัดส่วนที่ออกแบบไว้
    func height(forWidth w: CGFloat) -> CGFloat { max(1, (w * aspect).rounded()) }

    /// ขนาดเต็มที่ความกว้างนี้
    func size(forWidth w: CGFloat) -> CGSize { CGSize(width: w, height: height(forWidth: w)) }

    /// ปรับขนาดได้ไหม (`widget.resize` · ตั้งต้นได้)
    var canResize: Bool { meta.resize ?? true }

    /// ผังตายตัวที่สเกลตามความกว้าง — ความสูงต่ำสุดคือสัดส่วนที่ออกแบบไว้ (`widget.keepAspect`)
    var keepsDesignAspect: Bool { meta.keepAspect ?? false }

    /// พื้นผิวตั้งต้นตอนหยิบออกจากตู้/สลับแบบ = ตัวเลือกแรกของถาด (ไม่มีตัวเลือก = กระจก)
    var defaultSurface: WidgetSurface { surfaceOptions.first ?? .glass }

    /// พื้นผิวที่ใบนี้ให้เลือก (`widget.surfaces`) — ไม่ใส่: ใบที่วาดพื้นเองไม่มีแถวนี้ · ใบที่ chrome ครอบได้ กระจก/เข้ม/ไม่มีพื้น
    var surfaceOptions: [WidgetSurface] {
        if let s = meta.surfaces { return s.compactMap(WidgetSurface.init(rawValue:)) }
        return drawsOwnSurface ? [] : [.glass, .dim, .clear]
    }

    /// ชื่อของตัวเลือกพื้นผิวบนถาด — `widget.surfaceNames` ทับชื่อกลาง (เช่น กระดาษของตัวเอง = "มีพื้น")
    func surfaceName(_ s: WidgetSurface) -> String { meta.surfaceNames?[s.rawValue] ?? s.name }

    /// ตัวเลือกในถาดของใบนี้ (`widget.controls`)
    var controls: [KitControl] { meta.controls ?? [] }

    /// เส้นขอบตั้งต้น (`widget.border`) — ไม่ใส่: ขอบเป็นของ "แผ่นข้อมูล" ที่ chrome ครอบให้เท่านั้น
    var defaultBorder: Bool { meta.border ?? !drawsOwnSurface }

    /// ใบที่วาดเส้นขอบของตัวเอง (`widget.ownBorder`) — chrome ไม่วาดเส้นซ้ำ
    var drawsOwnBorder: Bool { meta.ownBorder ?? false }

    /// วัสดุของแผ่นสติกเกอร์ (`widget.skin`) — nil = ไม่ใช่แผ่นสติกเกอร์
    var popSkin: PopSkin? { meta.skin.flatMap(PopSkin.init(rawValue:)) }

    /// ชิ้นที่ Sale Here วางให้ทุกการ์ด (`widget.pinned`) — ดู `PinnedSeal`
    var isPinnedKind: Bool { meta.pinned ?? false }

    /// ผังของใบนี้วาดตรา Sale Here STAR ของตัวเอง (ไอคอน `embossedLockup`) — มีตลอด ไม่มีปุ่มปิด (19 ต.ค. 2569)
    /// การ์ดที่มีใบแบบนี้ไม่ปั๊มตรามุมการ์ดซ้ำ (`SignatureEmboss.spot`)
    var carriesEmboss: Bool {
        guard let spec = SpecCatalog.spec(for: self) else { return false }
        func has(_ n: SpecNode) -> Bool {
            n.icon == "embossedLockup" || (n.children ?? []).contains(where: has) || (n.each.map { has($0.node) } ?? false)
        }
        return has(spec.root) || (spec.variants ?? []).contains { has($0.root) }
    }
}

// MARK: - พื้นผิวของชิ้นที่กำลังวาด (ส่งลงทาง environment)

private struct WidgetSurfaceKey: EnvironmentKey {
    static let defaultValue = WidgetSurface.glass
}
private struct WidgetPatternKey: EnvironmentKey {
    static let defaultValue = PlatePattern.plain
}
private struct WidgetBorderKey: EnvironmentKey {
    static let defaultValue = false
}
/// วัสดุของแผ่นสติกเกอร์ — `nil` แปลว่าไม่ได้วาดจากชนิดใดชนิดหนึ่ง (พรีวิวใน Xcode)
private struct PopSkinKey: EnvironmentKey {
    static let defaultValue: PopSkin? = nil
}

extension EnvironmentValues {
    /// พื้นผิวที่ผู้ใช้เลือกให้ชิ้นนี้ — widget ที่วาดแผ่นเองอ่านค่านี้แทนที่จะให้ `WidgetChrome` ครอบ
    var widgetSurface: WidgetSurface {
        get { self[WidgetSurfaceKey.self] }
        set { self[WidgetSurfaceKey.self] = newValue }
    }
    var widgetPattern: PlatePattern {
        get { self[WidgetPatternKey.self] }
        set { self[WidgetPatternKey.self] = newValue }
    }
    var widgetBorder: Bool {
        get { self[WidgetBorderKey.self] }
        set { self[WidgetBorderKey.self] = newValue }
    }
    /// วัสดุที่ชนิดของชิ้นสั่งมา — ชิ้นส่วนร่วมของสำรับสติกเกอร์อยู่ลึกหลายชั้น
    /// ส่งทาง environment จึงถึงทุกตัวโดยไม่ต้องไล่เติมพารามิเตอร์ทั้งไฟล์
    var popSkin: PopSkin? {
        get { self[PopSkinKey.self] }
        set { self[PopSkinKey.self] = newValue }
    }
}


// MARK: - Plate pattern

/// ลายบนแผ่นทึบของ widget — เรียบ · ลายทาง · ข้าวหลามตัด
enum PlatePattern: String, CaseIterable, Identifiable {
    case plain, stripe, diamond
    var id: String { rawValue }

    var name: String {
        switch self {
        case .plain:   return "เรียบ"
        case .stripe:  return "ลายทาง"
        case .diamond: return "ข้าวหลามตัด"
        }
    }
}

// MARK: - Surface

/// พื้นผิวของ widget — ผู้ใช้เลือกทับค่าตั้งต้นของชนิดได้ทุกตัว
///
/// มีสองแบบเท่านั้น และ **ไม่มีแบบ "ไม่มีพื้น"** ตั้งใจ: ชิ้นที่ไม่มีพื้นจะลอยหายไปกับการ์ด
/// จนอ่านไม่ออกว่าตรงไหนคือชิ้นเดียวกัน (และบนพื้นหลังรูป ตัวหนังสือก็จมหายไปเลย)
/// ของเดิมมี `จาง` กับ `โปร่ง` ด้วย — จางอ่อนเกินกว่าจะเป็นพื้นจริง ส่วนโปร่งคือ "ไม่มีพื้น"
/// ทั้งคู่ถูกยุบมาเป็นกระจก (ดู `decode`) การ์ดเก่าจึงเปิดแล้วได้พื้นครบทุกชิ้นทันที
enum WidgetSurface: String, CaseIterable, Identifiable {
    case glass   // liquid glass
    case dim     // แผ่นเข้มทึบ
    /// **ไม่มีพื้นเลย** — เนื้อหานั่งบนการ์ดตรง ๆ ไม่มีแผ่น ไม่มีกระดาษ ไม่มีเงา
    ///
    /// กติกาเดิมของการ์ดคือ "ทุกชิ้นต้องมีพื้น" เพราะของที่ลอยอยู่บนการ์ดเปล่าอ่านไม่ออกว่า
    /// เป็นชิ้นเดียวกันหรือคนละชิ้น — ซึ่งจริงสำหรับ *แผ่นข้อมูล* ที่วางติดกันหลายใบ
    ///
    /// แต่มันไม่จริงสำหรับใบที่เป็น **ภาพทั้งใบ**: กองโพลารอยด์ · ประโยคตัวใหญ่ · การ์ดขั้นตอน
    /// สามอย่างนี้มีรูปทรงของตัวเองอยู่แล้ว กระดาษที่รองอยู่ข้างหลังจึงกลายเป็น *กรอบ*
    /// ที่ตัดมันออกจากการ์ด แทนที่จะช่วยให้มันเป็นส่วนหนึ่งของการ์ด
    ///
    /// ตัวที่เลือกได้อยู่ที่ `WidgetKind.surfaceOptions` — ไม่ใช่ทุกใบที่ถอดพื้นแล้วยังอ่านออก
    case clear

    /// **กระจกของ chrome บนใบที่วาดวัสดุเอง** — กระดาษ/แผ่นพิมพ์ของมันถูกถอดออก
    /// แล้วเอาเนื้อหาไปวางบนแผ่นกระจกใบเดียวกับที่ widget ตัวอื่นทั้งการ์ดใช้อยู่
    ///
    /// ทำไมต้องมีแบบที่สาม: สำรับที่วาดวัสดุเองเคยมีคำถามเดียวคือ "เอาแผ่นของมันไหม"
    /// ตอบว่าไม่ แล้วเนื้อหาไปนั่งบนการ์ดเปล่า ๆ ซึ่งคือคนละเรื่องกับ "อยากได้ของชิ้นนี้
    /// ให้เข้าชุดกับใบอื่นบนหน้าเดียวกัน" — ใบอื่นทั้งหน้าเป็นกระจก ใบนี้จึงต้องเป็นกระจกได้ด้วย
    ///
    /// ตอนวาด ตัวนี้ถูกแปลงเป็นสองอย่างพร้อมกัน (ดู `WidgetChrome`): chrome ครอบกระจกให้
    /// ส่วน widget ได้รับค่า `.clear` ลงไป — มันจึงไม่วาดแผ่นของตัวเองและพลิกหมึกตามการ์ดให้เอง
    /// โดยไม่ต้องรู้จักพื้นผิวแบบนี้เลยสักใบ
    case pane

    var id: String { rawValue }

    var name: String {
        switch self {
        case .glass: return "กระจก"
        case .dim:   return "เข้ม"
        case .clear: return "ไม่มีพื้น"
        case .pane:  return "กระจก"
        }
    }

    /// อ่านค่าจากไฟล์ — ชื่อที่เลิกใช้แล้ว (`faint`/`plain`) ตกมาเป็นกระจก ไม่ใช่ค่าว่าง
    static func decode(_ raw: String) -> WidgetSurface {
        WidgetSurface(rawValue: raw) ?? .glass
    }
}

// MARK: - Instance

struct WidgetInstance: Identifiable, Equatable {
    let id: UUID
    var kind: WidgetKind
    /// มุมบนซ้ายของกรอบ — **หน่วย pt บนพื้นที่ออกแบบ** อ้างมุมบนซ้ายของหน้า
    ///
    /// เป็นพิกัดที่ผู้ใช้ *ขอ* ไม่ใช่พิกัดที่ได้จริง — `PageLayout.solve` เป็นคนตัดสินตอนวาด
    /// และจะ **ดันตัวที่ไปตกทับของที่วางไว้ก่อนลงจนมีที่ว่าง** (ของทับกันไม่ได้บนหน้ากระดาษ)
    /// ค่าที่ถูกดันไม่ถูกเขียนกลับมาที่นี่ ย้ายตัวที่ขวางออกเมื่อไหร่ของก็เด้งกลับขึ้นที่เดิมเอง
    ///
    /// ลำดับใน `CardPage.items` คือลำดับ "ใครได้ที่ก่อน" เวลาสองตัวขอที่เดียวกัน
    var x: CGFloat
    var y: CGFloat
    var w: CGFloat
    var h: CGFloat

    /// กรอบที่ตัวนี้ *ขอ* — ยังไม่ผ่านการรูดเข้าหน้าและการดันไม่ให้ทับกัน
    var rect: CGRect {
        get { CGRect(x: x, y: y, width: w, height: h) }
        set { x = newValue.minX; y = newValue.minY; w = newValue.width; h = newValue.height }
    }
    /// พื้นผิว — ตั้งต้นตามบุคลิกของชนิด (typography โปร่ง · แผ่นข้อมูลกระจก)
    var surface: WidgetSurface
    /// เส้นขอบรอบ widget — แยกจากพื้นผิว เพราะบางทีอยากได้กรอบโดยไม่เอาพื้น
    /// (พื้นโปร่ง + มีขอบ = การ์ดเส้นขอบล้วน ซึ่งเป็นอีกหน้าตาหนึ่ง)
    var border: Bool
    /// **ค่าที่ผู้ใช้เลือกในถาด** — คีย์ = `opt` ของ `widget.controls` · ค่าตั้งต้นไม่เก็บ (ใบที่ไม่ได้ปรับ = ว่าง)
    ///
    /// ก้อนเดียวของทุกใบ (19 ต.ค. 2569) — ระบบไม่ต้องรู้ว่าแต่ละใบมีตัวเลือกอะไร อ่านจากไฟล์ผังเอา
    var options: [String: String] = [:]
    /// ลายบนแผ่น — `options["pattern"]` (ตัวเลือก "ลาย" ในไฟล์ผัง)
    var pattern: PlatePattern {
        get { options["pattern"].flatMap(PlatePattern.init(rawValue:)) ?? .plain }
        set { options["pattern"] = newValue == .plain ? nil : newValue.rawValue }
    }
    /// ชิ้นที่ Sale Here วางให้และ **ตรึงไว้กับก้นหน้า** — ลบ ย้าย ยืด สลับแบบไม่ได้ (ดู `PinnedSeal`)
    ///
    /// เป็นของชนิด (`widget.pinned`) ไม่ใช่ค่าที่เก็บในชิ้น · ผังให้ที่มันก่อนใคร และ `y` ที่ถือไว้ไม่ถูกใช้:
    /// ก้นหน้าของพอร์ตสูงไม่เท่ากันทุกเครื่อง ตำแหน่งจึงคิดจากก้นหน้าตอนวาดทุกครั้ง (ดู `PageLayout.pinnedFrame`)
    var pinned: Bool { kind.isPinnedKind }
    /// หน้าตาตัวอักษร — ฟอนต์ · สี · ขนาด · การจัดวาง
    ///
    /// อยู่ที่ชิ้น ไม่ใช่ที่ตระกูล ด้วยเหตุผลเดียวกับ `surface`/`border`: มันคือ *หน้าตา* ไม่ใช่ *เนื้อหา*
    /// ตอนนี้มีแค่ `textBlock` ที่อ่านค่านี้ (ดู `CardFont`) ตัวอื่นถือไว้เฉย ๆ โดยไม่มีผล
    var textStyle = WidgetTextStyle()
    /// หน้าตา + ตัวเลือกของชุดห้าสไตล์ — **อ่านจาก `options`** (`fill` · `corner` · ตัวเลือกเนื้อหา) + หน้าตาของชนิด
    /// แก้ทีละค่าให้เขียน `options[opt]` ตรง ๆ · ตัว setter มีไว้ให้ที่ตั้งทั้งชุด (เช่น ตอนกู้ไฟล์)
    var kit: KitConfig {
        get {
            KitConfig(style: kind.kitStyle,
                      fill: options["fill"].flatMap(KitFill.init(rawValue:)) ?? .solid,
                      corner: options["corner"].flatMap(KitCorner.init(rawValue:)) ?? .round,
                      opts: options)
        }
        set {
            var o = newValue.opts
            o["fill"] = newValue.fill == .solid ? nil : newValue.fill.rawValue
            o["corner"] = newValue.corner == .round ? nil : newValue.corner.rawValue
            options = o
        }
    }

    /// `id` ส่งเข้ามาได้เฉพาะตอนกู้จากไฟล์ — ข้อความกับรูปของก้อนผูกกับ id นี้ (ดู `Profile.note`,
    /// `PhotoStore.perWidget`) ถ้าสุ่มใหม่ทุกครั้งที่เปิดแอป ของที่พิมพ์ไว้จะหายทั้งที่ยังอยู่ในไฟล์
    ///
    /// ไม่ระบุ `h` = ได้ความสูงตาม **สัดส่วนที่ออกแบบไว้** ของความกว้างนั้น ไม่ใช่ความสูงตั้งต้นดิบ ๆ
    /// (ผังในเทมเพลตจึงเขียนแค่ x/y/w แล้วได้ชิ้นที่สัดส่วนถูกต้องเสมอ — ยืดทีหลังได้ตามใจ)
    init(_ kind: WidgetKind, x: CGFloat = PageLayout.margin, y: CGFloat = PageLayout.margin,
         w: CGFloat? = nil, h: CGFloat? = nil, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        self.x = x
        self.y = y
        let width = w ?? kind.defaultSize.width
        self.w = width
        self.h = h ?? kind.height(forWidth: width)
        self.surface = kind.defaultSurface
        self.border = kind.defaultBorder
    }

    /// ย่อ/ขยาย **ทั้งชิ้นตามสัดส่วนที่เป็นอยู่** — หมุดมุมใช้ตัวนี้
    ///
    /// ใช้สัดส่วนปัจจุบันของชิ้น ไม่ใช่สัดส่วนของชนิด: ชิ้นที่ผู้ใช้ยืดเป็นแถบเตี้ยไว้แล้ว
    /// พอลากมุมต่อ ต้องได้แถบเตี้ยที่ใหญ่ขึ้น ไม่ใช่เด้งกลับไปเป็นสัดส่วนตั้งต้น
    mutating func scale(toWidth width: CGFloat) {
        let ratio = h / max(w, 1)
        w = width
        h = max(1, (width * ratio).rounded())
    }

    /// คืนความสูงให้ตรงสัดส่วนที่ออกแบบไว้ — ใช้ตอนสลับแบบ (แบบใหม่มีผังของตัวเอง)
    mutating func resetAspect() { h = kind.height(forWidth: w) }

    /// สเกลของชิ้นเทียบกับผังที่ออกแบบไว้ — 1 = ขนาดจริง
    var scale: CGFloat { w / max(kind.defaultSize.width, 1) }

    // ใช้ == ที่สังเคราะห์ให้ (เทียบทุก field รวม kind)
    // ตัวเดิมที่เขียนเองข้าม kind ไป — สลับแบบในหมวดเดียวกันที่ขนาดเท่ากันแล้ว
    // onChange(of: pages) เลยไม่ยิง การ์ดไม่วาดใหม่ กดเปลี่ยนแบบแล้วเหมือนไม่ติด
}

// MARK: - Catalog entry

/// รายการใน Widget Gallery — "ตู้รางวัล"
struct CatalogEntry: Identifiable {
    let id: String
    let kind: WidgetKind
    let unlocked: Bool
    /// เงื่อนไขที่ต้องทำเพื่อปลดล็อก — nil เมื่อปลดล็อกแล้ว
    let requirement: String?

    init(kind: WidgetKind, unlocked: Bool = true, requirement: String? = nil) {
        self.id = kind.rawValue + (unlocked ? "" : "-locked")
        self.kind = kind
        self.unlocked = unlocked
        self.requirement = requirement
    }
}

