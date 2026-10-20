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
    /// สีของการ์ด — **สิ่งเดียวที่ API เก็บเรื่องสี** (20 ต.ค. 2569 รอบ 3): `primary` = พื้น · `secondary` = หมึกของการ์ดสองสี
    /// ไม่มีชื่อพาเลตต์/คู่สี/HSB อีกแล้ว — renderer ทุกแพลตฟอร์มคิดสีที่เหลือจากสองค่านี้เอง
    struct Colors: Codable, Equatable {
        var primary: String
        var secondary: String? = nil
    }

    /// theme ที่ API เก็บ (20 ต.ค. 2569 รอบ 4): `colors` · `ink` (โทน) · `backdrop` + ของพื้นรูป — แค่นั้น
    /// `corner` `strip` `inkAuto` ถอดออก (ผู้ใช้: "เอาออกไปให้หมด"): มุม = มน · แถบ = บรรทัด เสมอ · หมึกเก็บตรง ๆ
    struct Theme: Codable {
        var colors: Colors? = nil
        var ink: String
        var backdrop: String
        // ---- ฟิลด์รุ่นก่อน (ชื่อพาเลตต์ · คู่สี · HSB ที่ตั้งเอง · ความสว่าง · เลื่อนเฉด) — อ่านอย่างเดียว ไม่เขียนแล้ว
        // doc เก่าแปลงเป็น `colors` ตอนอ่านด้วย `LegacyTheme.colors` (สูตรเดียวกับ `migrateTheme` ใน theme.js)
        var palette: String? = nil
        var brightness: Double? = nil
        var hueShift: Double? = nil
        var customHue: Double? = nil
        var customSat: Double? = nil
        var customBri: Double? = nil
        var duo: String? = nil
        var duoFlipped: Bool? = nil
        var inkAuto: Bool? = nil
        var corner: String? = nil
        var strip: String? = nil
        var photoEffect: String? = nil
        var photoDim: Double? = nil
        /// รูปพื้นหลังเอียงไปทางสว่างแค่ไหน (ดู `CardTheme.photoLean`) — ไฟล์เก่าไม่มี = วัดใหม่ตอนเปิด
        var photoLean: Double? = nil
        /// ฟอนต์ข้อมูลของการ์ด (ชุดห้าสไตล์) — ไฟล์เก่าไม่มี = มาตรฐาน
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
                colors: .init(primary: theme.primary.hexString, secondary: theme.secondary?.hexString),
                ink: theme.ink.rawValue, backdrop: theme.backdrop.rawValue,
                photoEffect: theme.photoEffect.rawValue, photoDim: theme.photoDim,
                photoLean: theme.photoLean),
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
        let legacyPopSkin: PopSkin = CornerStyle(rawValue: snap.theme.corner ?? "") == .soft ? .paper : .glass
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
        if let v = CardInk(rawValue: snap.theme.ink) { t.ink = v }
        if let v = BackdropStyle(rawValue: snap.theme.backdrop) { t.backdrop = v }
        // สี: doc ใหม่ = `colors` ตรง ๆ · doc เก่า = แปลงจากชื่อพาเลตต์/คู่สี/HSB ด้วยสูตรเดิม
        let colors = LegacyTheme.colors(snap.theme)
        t.primary = Color(docHex: colors.primary) ?? Palette.midnight.dark
        t.secondary = Color(docHex: colors.secondary)
        // doc เก่าที่พลิกคู่สี (`duoFlipped`) = โทนสว่าง — ตอนนี้โทนอยู่ที่ `ink` ไม่ใช่ลำดับสี
        if let v = LegacyTheme.inkOverride(snap.theme, primary: t.primary, lightInk: t.lightInk) { t.ink = v }
        if let v = snap.theme.photoEffect.flatMap(BackdropEffect.init(rawValue:)) { t.photoEffect = v }
        if let v = snap.theme.photoDim { t.photoDim = v }

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


// MARK: - doc รุ่นก่อน → `colors` (20 ต.ค. 2569 รอบ 3)

/// แปลงสีของ doc เก่า (ชื่อพาเลตต์ · คู่สี · HSB ที่ตั้งเอง · ความสว่าง · เลื่อนเฉด) เป็น `colors`
/// = สูตร `backdropColors.top` ของ CardTheme ก่อนรอบ 3 · ต้องตรงกับ `legacyColors` ใน sync-server/web/js/theme.js
/// และ `LegacyTheme` ใน Android ทุกบรรทัด — doc เดียวกันต้องได้ hex เดียวกันทั้งสามแพลตฟอร์ม
enum LegacyTheme {
    /// หมึกของ doc เก่า (ไม่มี `colors`): คู่สี — `duoFlipped` = โทนสว่าง (paper) · ไม่พลิก = night ·
    /// สีเดียวที่เคยเปิด `inkAuto` (ไม่มีคีย์ = เปิด) — เลือกฝั่งจากความสว่างของพื้นให้ครั้งเดียวตอนแปลง (= `autoInk`)
    static func inkOverride(_ t: CardSnapshot.Theme, primary: Color, lightInk: CardInk) -> CardInk? {
        guard t.colors == nil, t.backdrop != BackdropStyle.photo.rawValue else { return nil }
        if let id = t.duo, ColorDuo.find(id) != nil { return (t.duoFlipped ?? false) ? .paper : .night }
        guard t.inkAuto ?? true else { return nil }
        let l = RGB(primary).luminance
        return (l + 0.05) / 0.07 > 1.05 / (l + 0.05) ? lightInk : .night
    }

    static func colors(_ t: CardSnapshot.Theme) -> CardSnapshot.Colors {
        if let c = t.colors, Color(docHex: c.primary) != nil {
            return CardSnapshot.Colors(primary: Color(docHex: c.primary)!.hexString,
                                       secondary: Color(docHex: c.secondary)?.hexString)
        }
        if let id = t.duo, let d = ColorDuo.find(id), t.backdrop != BackdropStyle.photo.rawValue {
            // คู่เก็บตามนิยาม (เข้ม · อ่อน) เสมอ — ข้างที่ขึ้นเป็นพื้นไปอยู่ที่ `ink` (ดู `inkOverride`)
            return CardSnapshot.Colors(primary: d.dark.hexString, secondary: d.light.hexString)
        }
        let pal = t.palette.flatMap(Palette.init(rawValue:)) ?? .midnight
        let hueShift = t.hueShift ?? 0, brightness = t.brightness ?? 0.30
        let rawHue = (t.customHue ?? pal.backdropHue) + hueShift
        let hue = rawHue - floor(rawHue)
        let sat = t.customHue != nil ? min(0.6, max(0.15, t.customSat ?? 0.5)) : pal.backdropSaturation
        if let bri = t.customBri, t.customHue != nil {
            return CardSnapshot.Colors(primary: Color(hue: hue, saturation: min(1, max(0, t.customSat ?? 0.5)),
                                                      brightness: min(1, max(0, bri))).hexString)
        }
        let ink = CardInk(rawValue: t.ink) ?? .night
        let lightInk: CardInk = (t.customSat ?? 0) >= 0.35 ? .mist : .paper
        let active: CardInk = t.backdrop == BackdropStyle.photo.rawValue ? .night
            : (t.inkAuto ?? true) ? .night : (ink.isLight ? lightInk : .night)
        let b = brightness
        let top: Color
        switch active {
        case .night: top = Color(hue: hue, saturation: max(0, sat - b * 0.28), brightness: 0.05 + b * 0.52)
        case .paper: top = Color(hue: hue, saturation: 0.03 + sat * 0.04, brightness: 0.955 + b * 0.045)
        case .mist:  top = Color(hue: hue, saturation: 0.09 + sat * 0.16, brightness: 0.945 + b * 0.05)
        }
        return CardSnapshot.Colors(primary: top.hexString)
    }
}
