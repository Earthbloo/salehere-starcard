import SwiftUI

// MARK: - จำสถานะการ์ดข้ามการเปิดแอป
//
// # ทำไมมีไฟล์นี้ (และทำไมมันยังไม่ใช่ของจริง)
//
// ระหว่างทดสอบ ทุกครั้งที่ปิดแอปแล้วเปิดใหม่ การ์ดจะกลับไปเป็น `Mock.starterPages` เสมอ
// ซึ่งแปลว่าต้องลากวางใหม่ทั้งหน้าทุกรอบ — ทดสอบท่าลาก/สลับแบบ/ปรับธีมแทบไม่ได้เลย
//
// ตัวนี้เก็บลง `UserDefaults` เป็น JSON ก้อนเดียว **สำหรับตอนพัฒนาเท่านั้น**
// ของจริงต้องไปอยู่บน API (ดู `WidgetContent.swift` — เก็บ layout ต่อชิ้น เนื้อหาต่อตระกูล)
//
// # ทำไมไม่ให้ `CardPage`/`WidgetInstance` conform Codable ตรง ๆ
//
// สองตัวนั้นมี `let id = UUID()` ที่สร้างใหม่ทุกครั้ง ถ้า encode ทั้งก้อนแล้ว decode กลับมา
// id จะถูกกู้คืนมาด้วย ซึ่งฟังดูดีแต่ผูก **สถานะรันไทม์** (id ที่ SwiftUI ใช้ diff view)
// เข้ากับ **รูปแบบไฟล์** — วันที่เพิ่มฟิลด์ใหม่ในสตรักต์ ไฟล์เก่าจะ decode ไม่ผ่านทั้งก้อน
//
// DTO แยกจึงเป็นชั้นกันชน: ฟิลด์ไหนหายไปก็ตกไปใช้ค่าตั้งต้น การ์ดไม่หายทั้งใบ

/// ภาพนิ่งของการ์ดหนึ่งใบ — รูปแบบเดียวกับที่ API จะเก็บในอนาคต
struct CardSnapshot: Codable {
    struct Item: Codable {
        var kind: String
        // พิกัด/ขนาดเป็น pt บนพื้นที่ออกแบบ (ดู `PageLayout`) ไม่ใช่ช่องกริดอีกแล้ว
        var x: Double
        var y: Double
        var w: Double
        var h: Double
        var surface: String
        var border: Bool
        // ตัวตนของชิ้น — ข้อความที่พิมพ์เอง (`Profile.note`) ผูกกับ id นี้ ไฟล์เก่าไม่มี = สุ่มใหม่ตอนกู้
        // (ข้อยกเว้นของกติกา "ไม่เก็บ id" ข้างบน: id นี้ไม่ใช่สถานะรันไทม์อีกแล้ว มันคือคีย์ของเนื้อหา)
        var id: String? = nil
        /// **ค่าที่ผู้ใช้เลือกในถาด** — คีย์ = `opt` ของ `widget.controls` · ชั้นข้อความเก็บ `face` `tint` `scale` `align` `points`
        /// ก้อนเดียวของทุกใบ (19 ต.ค. 2569) · ไฟล์ก่อนหน้านั้นไม่มีคีย์นี้ → อ่านจากคีย์เก่าข้างล่าง (อ่านอย่างเดียว ไม่เขียนแล้ว)
        var options: [String: String]? = nil
        // ── คีย์เก่า (อ่านอย่างเดียว) ──
        // หน้าตาตัวอักษร — ไฟล์เก่าไม่มีสี่คีย์นี้ จึงเป็น optional ทั้งชุด
        // (ตกไปใช้ค่าตั้งต้นของ `WidgetTextStyle` แทนที่จะ decode ไม่ผ่านทั้งการ์ด)
        var face: String? = nil
        var tint: String? = nil
        var scale: String? = nil
        var align: String? = nil
        // ขนาดตัวอักษรของก้อนข้อความ — ไฟล์รุ่นก่อนไม่มี จึงตกไปใช้ขั้น `scale` เดิมแทน
        var points: Double? = nil
        // หน้าตาที่ตั้งให้ **รายช่อง** — ฟอนต์ · สี · ขนาด (คีย์คือ "ฟิลด์#ลำดับ")
        // ไฟล์เก่าไม่มีสามคีย์นี้ = ทุกช่อง "ตามดีไซน์ · ขนาด M" ซึ่งคือหน้าตาเดิมเป๊ะ
        var slotFaces: [String: String]? = nil
        var slotTints: [String: String]? = nil
        var slotSizes: [String: String]? = nil
        // ลายบนแผ่น — ไฟล์เก่าไม่มี = แผ่นเรียบ
        var pattern: String? = nil
        // (`keepPhotoBG` `noEmboss` `blindEmboss` ถูกถอด 19 ต.ค. 2569 — ไม่มีการลบพื้นหลังอัตโนมัติ · ตราปั๊มมีตลอด
        //  ไฟล์เก่าที่ยังมีคีย์พวกนี้อ่านได้ตามปกติ คีย์ถูกข้าม)
        // ชิ้นที่ตรึงกับก้นหน้า (ตรารับรอง Sale Here) — ไฟล์เก่าไม่มี = ชิ้นธรรมดา (เก็บเฉพาะตอนตรึง)
        var pinned: Bool? = nil
        // หน้าตาของตรารับรอง — ไฟล์เก่าไม่มี = เหรียญ (เก็บเฉพาะตอนเลือกแบบอื่น)
        var sealStyle: String? = nil
        // รุ่นแรกเก็บแค่เปิด/ปิดลายทาง — อ่านอย่างเดียว
        var stripes: Bool? = nil
        // ชุดห้าสไตล์: สไตล์ · พื้นหลัง · มุม · สี · ตัวเลือกเนื้อหา — เก็บเฉพาะชนิดในชุด
        var kit: KitConfig? = nil
    }
    struct Page: Codable { var items: [Item] }
    struct Theme: Codable {
        var palette: String
        var ink: String
        var corner: String
        var backdrop: String
        var brightness: Double
        var hueShift: Double
        var customHue: Double?
        var customSat: Double?
        // ไฟล์เก่าไม่มีสองคีย์นี้ · `inkAuto` ที่หายไปต้องอ่านเป็น false ไม่ใช่ค่าตั้งต้นของสตรักต์
        // ไม่งั้นการ์ดที่เคยเลือก "กระดาษ" ไว้จะกลายเป็นเวทีมืดในการเปิดครั้งถัดไป
        var customBri: Double? = nil
        var inkAuto: Bool? = nil
        var photoEffect: String? = nil
        var photoDim: Double? = nil
        /// แบบของแถบผู้ออกบัตร — ไฟล์เก่าไม่มี ตกไปใช้ "บรรทัด"
        var strip: String? = nil
        /// รูปพื้นหลังเอียงไปทางสว่างแค่ไหน (ดู `CardTheme.photoLean`) — ไฟล์เก่าไม่มี = วัดใหม่ตอนเปิด
        var photoLean: Double? = nil
        /// คู่สีที่เลือกไว้ (ดู `ColorDuo`) — ไฟล์เก่าไม่มี = ยังใช้พาเลตต์ตามเดิม
        var duo: String? = nil
        var duoFlipped: Bool? = nil
        /// ฟอนต์ข้อมูลของการ์ด (ชุดห้าสไตล์) — ไฟล์เก่าไม่มี = มาตรฐาน
        var dataFont: String? = nil
    }

    var pages: [Page]
    var theme: Theme
    var index: Int
    /// เวอร์ชันของรูปแบบ — ขึ้นเลขเมื่อไหร่ของเก่าถูกทิ้งแทนที่จะ decode ผิด ๆ
    var version: Int = 2
}

/// ที่เก็บชั่วคราวสำหรับตอนพัฒนา
///
/// ฉบับร่าง **แยกช่องตามรูปแบบการ์ด** (`CardFormat`) — พอร์ตกับสตอรี่ไม่ทับกัน
/// เพราะสองแบบนี้มีจำนวนหน้าไม่เท่ากัน ถ้าใช้ช่องเดียวกัน การเปิดอีกแบบหนึ่ง
/// จะเขียนทับงานของอีกแบบทันทีที่แตะอะไรสักอย่าง — งานหายโดยไม่มีใครสั่งลบ
enum CardStore {
    /// ขึ้นเป็น v2 ตอนที่ผังเปลี่ยนจากกริดคอลัมน์เป็นพิกเซล — ฉบับร่าง v1 อ่านไม่ได้แล้ว
    /// และ **แปลงข้ามมาไม่ได้จริง ๆ** เพราะ "6 คอลัมน์" ของเดิมแปลว่าเต็มหน้าเท่าไหร่ก็ได้
    /// ขึ้นกับเครื่องที่แต่ง ซึ่งไฟล์ไม่ได้บันทึกไว้ · ปล่อยให้ตกไปใช้หน้าตั้งต้นดีกว่าเดาผิด
    private static func key(_ format: CardFormat) -> String {
        "starcard.draft.v2.\(format.rawValue)"
    }

    /// ปิดการจำสถานะได้จากที่เดียว — เวลาอยากทดสอบหน้าตั้งต้นจริง ๆ
    static var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "starcard.draft.enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "starcard.draft.enabled") }
    }

    /// แปลงสถานะรันไทม์เป็นภาพนิ่ง — จุดเดียวที่รู้วิธี encode ใช้ร่วมกันทั้งช่องร่างเก่าและคลังการ์ด
    static func snapshot(pages: [CardPage], theme: CardTheme, index: Int) -> CardSnapshot {
        CardSnapshot(
            pages: pages.map { page in
                CardSnapshot.Page(items: page.items.map {
                    CardSnapshot.Item(kind: $0.kind.rawValue,
                                      x: $0.x, y: $0.y, w: $0.w, h: $0.h,
                                      surface: $0.surface.rawValue, border: $0.border,
                                      id: $0.id.uuidString,
                                      options: storedOptions($0))
                })
            },
            theme: CardSnapshot.Theme(
                palette: theme.palette.rawValue, ink: theme.ink.rawValue,
                corner: theme.corner.rawValue, backdrop: theme.backdrop.rawValue,
                brightness: theme.brightness, hueShift: theme.hueShift,
                customHue: theme.customHue, customSat: theme.customSat,
                customBri: theme.customBri, inkAuto: theme.inkAuto,
                photoEffect: theme.photoEffect.rawValue, photoDim: theme.photoDim,
                strip: theme.strip.rawValue, photoLean: theme.photoLean,
                duo: theme.duoID, duoFlipped: theme.duoFlipped,
                dataFont: theme.dataFont == .noto ? nil : theme.dataFont.rawValue),
            index: index)
    }

    /// คีย์หน้าตาตัวอักษรของชั้นข้อความใน `options`
    private static let textKeys = ["face", "tint", "scale", "align", "points"]

    /// สิ่งที่เขียนลง `options` ของไฟล์ — ตัวเลือกในถาด · ชั้นข้อความเพิ่มหน้าตาตัวอักษร · ว่าง = ไม่เขียนคีย์
    private static func storedOptions(_ w: WidgetInstance) -> [String: String]? {
        var o = w.options
        if w.kind.usesTextStyle {
            o["face"] = w.textStyle.face.rawValue
            o["tint"] = w.textStyle.tint.rawValue
            o["scale"] = w.textStyle.scale.rawValue
            o["align"] = w.textStyle.align.rawValue
            o["points"] = String(Double(w.textStyle.points))
        }
        return o.isEmpty ? nil : o
    }

    /// ไฟล์ก่อน 19 ต.ค. 2569 — ค่าที่เคยกระจายเป็นคีย์ของชิ้น → `options` ก้อนเดียว
    /// (`sealStyle` · `pinned` · `keepPhotoBG` · `noEmboss` · `blindEmboss` ไม่มีที่ไปแล้ว ถูกข้าม)
    private static func legacyOptions(_ it: CardSnapshot.Item) -> [String: String] {
        var o: [String: String] = [:]
        if let p = it.pattern ?? (it.stripes == true ? PlatePattern.stripe.rawValue : nil), p != PlatePattern.plain.rawValue {
            o["pattern"] = p
        }
        if let k = it.kit {
            o.merge(k.opts) { a, _ in a }
            if k.fill != .solid { o["fill"] = k.fill.rawValue }
            if k.corner != .round { o["corner"] = k.corner.rawValue }
        }
        if let v = it.face { o["face"] = v }
        if let v = it.tint { o["tint"] = v }
        if let v = it.scale { o["scale"] = v }
        if let v = it.align { o["align"] = v }
        if let v = it.points { o["points"] = String(v) }
        return o
    }

    /// แปลงภาพนิ่งกลับเป็นสถานะรันไทม์ — คู่ขาของ `snapshot` และใจดีกับไฟล์เก่าแบบเดียวกับ `load`
    ///
    /// บอก `format` มาด้วย = การ์ดจริงของผู้ใช้ → ได้ตรารับรองที่ตรึงไว้เสมอ (ดู `PinnedSeal`)
    /// ไม่บอก = อ่านดิบ ๆ ตามไฟล์ (โต๊ะตรวจงาน · ขอแค่ธีม)
    static func restore(_ snap: CardSnapshot,
                        format: CardFormat? = nil) -> (pages: [CardPage], theme: CardTheme, index: Int)? {
        // สำรับสติกเกอร์ในไฟล์เก่าไม่มีวัสดุติดมากับชนิด — ตอนนั้นมันมาจากมุมของธีม
        let legacyPopSkin: PopSkin = CornerStyle(rawValue: snap.theme.corner) == .soft ? .paper : .glass
        var pages = snap.pages.map { p in
            CardPage(p.items.compactMap { it -> WidgetInstance? in
                guard let kind = WidgetKind.decode(it.kind, legacyPopSkin: legacyPopSkin,
                                                   kitLook: it.kit.map { $0.style.rawValue }) else { return nil }
                var w = WidgetInstance(kind, x: it.x, y: it.y, w: it.w, h: it.h,
                                       id: it.id.flatMap(UUID.init(uuidString:)) ?? UUID())
                w.surface = WidgetSurface.decode(it.surface)
                w.border = it.border
                var o = it.options ?? legacyOptions(it)
                if kind.usesTextStyle {
                    if let v = o["face"].flatMap(CardFont.init(rawValue:)) { w.textStyle.face = v }
                    if let v = o["tint"].flatMap(TextTint.init(rawValue:)) { w.textStyle.tint = v }
                    if let v = o["scale"].flatMap(TextScale.init(rawValue:)) { w.textStyle.scale = v }
                    if let v = o["align"].flatMap(TextAlign.init(rawValue:)) { w.textStyle.align = v }
                    w.textStyle.points = o["points"].flatMap(Double.init).map { CGFloat($0) } ?? w.textStyle.scale.size
                }
                // หน้าตาตัวอักษรเป็นของชั้นข้อความเท่านั้น — ไฟล์เก่าเขียนคีย์พวกนี้ให้ทุกชิ้น ไม่ใช่ตัวเลือกของ widget
                for k in Self.textKeys { o[k] = nil }
                w.options = o
                w.textStyle.slotFaces = (it.slotFaces ?? [:]).compactMapValues(CardFont.init(rawValue:))
                w.textStyle.slotTints = (it.slotTints ?? [:]).compactMapValues(TextTint.init(rawValue:))
                w.textStyle.slotSizes = (it.slotSizes ?? [:]).compactMapValues(WidgetTextSize.init(rawValue:))
                return w
            })
        }
        // การ์ดเปล่า (เริ่มจากว่าง) ไม่มีชิ้นเลยแต่ยังเป็นการ์ดจริง — ขอแค่มีหน้า
        guard !pages.isEmpty else { return nil }
        if let format { PinnedSeal.ensure(&pages, format: format) }

        var t = CardTheme()
        if let v = Palette(rawValue: snap.theme.palette) { t.palette = v }
        if let v = CardInk(rawValue: snap.theme.ink) { t.ink = v }
        if let v = CornerStyle(rawValue: snap.theme.corner) { t.corner = v }
        if let v = BackdropStyle(rawValue: snap.theme.backdrop) { t.backdrop = v }
        t.brightness = snap.theme.brightness
        t.hueShift = snap.theme.hueShift
        t.customHue = snap.theme.customHue
        t.customSat = snap.theme.customSat
        t.customBri = snap.theme.customBri
        t.inkAuto = snap.theme.inkAuto ?? false
        if let v = snap.theme.photoEffect.flatMap(BackdropEffect.init(rawValue:)) { t.photoEffect = v }
        if let v = snap.theme.photoDim { t.photoDim = v }
        if let v = snap.theme.strip.flatMap(StripStyle.init(rawValue:)) { t.strip = v }
        // รหัสที่ไม่รู้จักแล้ว (คู่สีถูกถอดออกจากชุด) ตกไปใช้พาเลตต์แทน ไม่ใช่การ์ดไร้สี
        t.duoID = snap.theme.duo.flatMap { ColorDuo.find($0) }?.id
        t.duoFlipped = snap.theme.duoFlipped ?? false
        t.dataFont = snap.theme.dataFont.flatMap(CardFont.init(rawValue:)) ?? .noto

        return (pages, t, min(max(0, snap.index), pages.count - 1))
    }

    static func save(pages: [CardPage], theme: CardTheme, index: Int,
                     format: CardFormat = .portfolio) {
        guard enabled else { return }
        let snap = snapshot(pages: pages, theme: theme, index: index)
        guard let data = try? JSONEncoder().encode(snap) else { return }
        UserDefaults.standard.set(data, forKey: key(format))
    }

    /// มีงานค้างไว้ในแบบนี้ไหม — หน้าเลือกแบบใช้ตัดสินว่าจะขึ้นป้าย "ทำต่อ"
    static func hasDraft(_ format: CardFormat) -> Bool {
        enabled && UserDefaults.standard.data(forKey: key(format)) != nil
    }

    /// คืน nil เมื่อยังไม่เคยเซฟ หรือไฟล์เก่าอ่านไม่ออก — ผู้เรียกใช้ค่าตั้งต้นต่อไป
    static func load(_ format: CardFormat = .portfolio)
        -> (pages: [CardPage], theme: CardTheme, index: Int)? {
        guard enabled,
              let data = UserDefaults.standard.data(forKey: key(format)),
              let snap = try? JSONDecoder().decode(CardSnapshot.self, from: data),
              snap.pages.contains(where: { !$0.items.isEmpty }) else { return nil }
        return restore(snap, format: format)
    }

    /// ล้างของที่จำไว้ — กลับไปหน้าตั้งต้นในการเปิดครั้งถัดไป
    static func clear(_ format: CardFormat) {
        UserDefaults.standard.removeObject(forKey: key(format))
    }

    static func clearAll() { CardFormat.allCases.forEach(clear) }
}
