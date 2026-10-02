import SwiftUI
import UIKit

// MARK: - ข้อความที่แก้ได้บนตัว widget เอง
//
// # ทำไมไม่เป็นช่องกรอกในชีตล่าง
//
// ชีตกรอกฟอร์มทำให้ต้องมองสองที่พร้อมกัน — พิมพ์ในชีต แล้วเงยไปดูว่าบนการ์ดมันยาวเกินไหม
// ซึ่งเป็นคำถามที่ผู้ใช้ตอบเองไม่ได้ เพราะช่องกรอกไม่รู้ว่าตัวเองกว้างเท่าไหร่บนการ์ด
//
// แก้ที่ตัวมันเลยจึงตอบได้ในจังหวะเดียว: ตัวอักษรที่พิมพ์อยู่ *คือ* ตัวอักษรที่จะพิมพ์ออกมา
// เส้นประบอกว่าอันไหนแตะได้ (ภาษาเดียวกับ template ของ CapCut) แตะแล้วเลือกทั้งก้อนให้เลย
// พิมพ์ทับได้ทันที หรือแตะซ้ำเพื่อวางเคอร์เซอร์
//
// # กติกาของความยาว
//
// ข้อความยาวเกินกรอบ **ตัดด้วย …** ไม่ใช่ดัน widget ให้สูงขึ้น
// เพราะ widget ที่โตเองตอนพิมพ์จะไปดันของที่วางไว้ข้างล่างทั้งหน้า ผังที่จัดไว้พังทั้งใบ
// อยากเห็นครบก็ **ยืดกรอบเอง** — ขนาดของ widget เป็นการตัดสินใจของผู้ใช้ ไม่ใช่ผลข้างเคียงของการพิมพ์
//
// # ทำไมช่องพิมพ์ไปวาดที่ชั้นการ์ด ไม่ใช่ในตัว widget
//
// เนื้อหา widget ถูกปิด hit testing ทั้งก้อน (ดู `WidgetChrome`) ช่องพิมพ์ที่อยู่ข้างในจึงกดไม่ติด
// รูปแบบเดียวกับปุ่มเปลี่ยนรูป: ตัว widget ประกาศ *กรอบ* ของช่องผ่าน anchor
// แล้วชั้นการ์ดเอากรอบนั้นไปวางของจริงทับ

// MARK: - สไตล์ที่ส่งขึ้นไปให้ช่องพิมพ์

/// หน้าตาของข้อความช่องหนึ่ง — ส่งขึ้นไปให้ช่องพิมพ์วาดตัวอักษรให้ตรงกับที่เห็นบนการ์ด
///
/// เก็บเป็น `size` + `weight` ไม่ใช่ `Font` สำเร็จรูป เพราะช่องพิมพ์เป็น `UITextView`
/// ซึ่งต้องการ `UIFont` — เก็บสองค่านี้ไว้จึงประกอบได้ทั้งสองฝั่งจากแหล่งเดียว ไม่มีทางเพี้ยนกัน
struct TextSlotStyle: Equatable {
    var size: CGFloat = 14
    var weight: Font.Weight = .regular
    /// ฟอนต์ของช่องนี้ — ตั้งต้นเป็นฟอนต์หลักของแอป
    /// อยู่ในสไตล์ไม่ใช่ในตัว widget เพราะช่องพิมพ์เหนือคีย์บอร์ดต้องใช้หน้าตาเดียวกัน
    var face: CardFont = .noto
    var color: Color = .white
    var align: TextAlignment = .leading
    var tracking: CGFloat = 0
    var lineSpacing: CGFloat = 0
    /// ข้อความบนการ์ดแสดงเป็นตัวใหญ่ แต่ค่าที่เก็บเป็นตัวเดิม — ตอนพิมพ์จึงเห็นค่าจริง
    var uppercase: Bool = false
    /// มุมของกรอบเส้นประ — ชิปใช้ค่าสูงให้โค้งตามแคปซูล
    var corner: CGFloat = 4
    /// ตัวเอียง — หัวเรื่องแบบนิตยสารที่ขึ้นต้นด้วยคำเซริฟเอียง (ดู `ReelShowcase`)
    /// อยู่ในสไตล์ ไม่ใช่ที่ตัว `Text` เพราะช่องพิมพ์เหนือคีย์บอร์ดต้องเห็นหน้าตาเดียวกัน
    var italic: Bool = false
    /// ตัวอักษรถูกแปะเอียงไปกี่องศา (เช่นใบเรตราคาที่แปะเฉียง) — เส้นประต้องเอียงตาม
    /// ไม่งั้นกล่องตรงครอบตัวอักษรเอียงแล้วอ่านเป็นกรอบหลุด · ใส่ให้เองจาก `slotTilt` ไม่ต้องส่งจาก widget
    var tilt: Double = 0

    var font: Font {
        let f = face.font(size, weight)
        return italic ? f.italic() : f
    }
    var uiFont: UIFont { face.uiFont(size, weight) }

    /// สไตล์เดียวกันหลังผ่าน **ฟอนต์ · สี · ขนาด ที่เจ้าของการ์ดตั้งให้ช่องนี้** (ดู `WidgetTextStyle`)
    ///
    /// ค่าที่ดีไซน์เขียนไว้คือ *ค่าอ้างอิง* ไม่ใช่ค่าสุดท้าย — ช่องที่ยังไม่ถูกสั่งทับได้ของดีไซน์ครบ
    /// ทุกอย่าง ส่วนช่องที่ถูกสั่งทับเปลี่ยนเฉพาะสิ่งที่สั่ง (เลือกสีอย่างเดียว ฟอนต์ยังเป็นของดีไซน์)
    ///
    /// - Parameters:
    ///   - ink: หมึกของพื้นที่ช่องนี้นั่งอยู่จริง — สีที่เลือกถูกยันให้อ่านออกบนพื้นนั้น
    ///     (ดู `TextTint.color(ink:accent:)`) เลือกทองบนพื้นแชมเปญจึงได้ทองเข้ม ไม่ใช่ทองที่หายไป
    func tuned(by w: WidgetTextStyle, slot: TextSlotID,
               ink: InkStyle, accent: Color) -> TextSlotStyle {
        var s = self
        let f = slot.field, i = slot.index
        s.size = w.scaled(size, for: f, i)
        if let face = w.face(for: f, i) { s.face = face }
        if let tint = w.tint(for: f, i) {
            s.color = tint.color(ink: ink, accent: accent, large: s.size >= 20)
        }
        return s
    }
}

// MARK: - กรอบของช่องข้อความ ส่งขึ้นไปให้ชั้นการ์ด

struct TextSlotAnchor: Equatable {
    let id: TextSlotID
    let bounds: Anchor<CGRect>
    let style: TextSlotStyle
}

struct TextSlotKey: PreferenceKey {
    static let defaultValue: [TextSlotAnchor] = []
    static func reduce(value: inout [TextSlotAnchor], nextValue: () -> [TextSlotAnchor]) {
        value += nextValue()
    }
}

/// กรอบที่แปลงเป็นพิกัดจริงแล้ว — ชั้นการ์ดใช้ทั้งวางช่องพิมพ์และเช็คว่านิ้วแตะโดนช่องไหน
struct TextSlotRect: Equatable {
    let id: TextSlotID
    let rect: CGRect
    let style: TextSlotStyle
}

// MARK: - สวิตช์โหมดแก้ข้อความ

private struct TextEditModeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// เปิดเฉพาะ widget ที่อยู่บนแคนวาสในโหมดแต่ง
    /// พรีวิวในตู้ widget และรูปที่เรนเดอร์ตอนแชร์จึงไม่มีเส้นประติดไปด้วย
    var textEditMode: Bool {
        get { self[TextEditModeKey.self] }
        set { self[TextEditModeKey.self] = newValue }
    }

    /// มุมเอียง (องศา) ของแผ่นที่ครอบข้อความอยู่ — ตั้งคู่กับ `.rotationEffect` ของแผ่นนั้น
    var slotTilt: Double {
        get { self[SlotTiltKey.self] }
        set { self[SlotTiltKey.self] = newValue }
    }
}

private struct SlotTiltKey: EnvironmentKey {
    static let defaultValue: Double = 0
}

/// โหมด "ไม่มีข้อมูล" ของพรีวิวในตู้ widget — ใบที่ผูกกับหัวข้อ Star Profile ที่ยังไม่ได้กรอก
///
/// ผู้ใช้ 23 ก.ย. 2569: "ต้อง preview widget ไปเลย … แต่ใน widget ต้องไม่มีเลขหรือข้อมูล" —
/// เลย์เอาต์ ป้าย ไอคอน รูป ยังอยู่ครบ แต่ **ค่าของผู้ใช้** (ช่องแก้ได้ทุกช่อง + ตัวเลขจากระบบ) กลายเป็นแท่งว่าง
private struct GhostDataKey: EnvironmentKey {
    static let defaultValue = false
}

/// บนการ์ดจริง: ช่องข้อความที่แก้ได้ (หัวข้อของดีไซน์) คงไว้ — ขีดแค่ค่าข้อมูล (`dataValue()`)
/// ในตู้ widget ยังขีดทุกช่องเหมือนเดิม
private struct GhostKeepsTextKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var ghostKeepsText: Bool {
        get { self[GhostKeepsTextKey.self] }
        set { self[GhostKeepsTextKey.self] = newValue }
    }
    var ghostData: Bool {
        get { self[GhostDataKey.self] }
        set { self[GhostDataKey.self] = newValue }
    }
}

private struct DataValueModifier: ViewModifier {
    @Environment(\.ghostData) private var ghost
    func body(content: Content) -> some View {
        content.ghostDash(ghost, font: nil)
    }
}

/// ยังไม่มีข้อมูล = ค่ากลายเป็น "–" ในที่เดิม (ผู้ใช้ 29 ก.ย. 2569: "ต้องเห็น widget แค่ข้อมูลที่กรอกเป็น - พอ")
/// ตัวจริงยังวางอยู่ (โปร่งใส) ขนาดกล่องจึงไม่เปลี่ยน · ขีดชิดตามการจัดข้อความของก้อนนั้น
private struct GhostDash: ViewModifier {
    let on: Bool
    let font: Font?
    @Environment(\.multilineTextAlignment) private var align
    func body(content: Content) -> some View {
        if on {
            content.opacity(0).overlay(alignment: align == .center ? .center : align == .trailing ? .trailing : .leading) {
                Text("–").font(font).lineLimit(1).fixedSize()
            }
        } else {
            content
        }
    }
}

extension View {
    fileprivate func ghostDash(_ on: Bool, font: Font?) -> some View { modifier(GhostDash(on: on, font: font)) }
}

extension View {
    /// ประกาศว่าตัวหนังสือก้อนนี้คือ "ค่าข้อมูลของผู้ใช้" (ยอดฟอล · % · ราคา · เลขที่) ไม่ใช่ป้ายของดีไซน์
    /// ในโหมดพรีวิวไม่มีข้อมูล ก้อนนี้กลายเป็นแท่งว่าง ส่วนป้ายรอบ ๆ ยังอ่านออก
    func dataValue() -> some View { modifier(DataValueModifier()) }
}

// MARK: - ตัวประกาศว่า "ข้อความก้อนนี้แก้ได้"

private struct EditableTextModifier: ViewModifier {
    @Environment(\.textEditMode) private var editMode
    @Environment(\.slotTilt) private var tilt
    @Environment(\.widgetTextStyle) private var tune
    @Environment(\.cardInk) private var ink
    @Environment(\.cardAccent) private var accent
    @Environment(\.ghostData) private var ghost
    @Environment(\.ghostKeepsText) private var keepText

    let id: TextSlotID
    let style: TextSlotStyle

    /// # ฟอนต์กับสีของช่องถูก "ใส่ให้" ที่นี่ ไม่ใช่ที่ตัว `Text`
    ///
    /// ตัวประกาศช่องรู้สองอย่างที่ตัว `Text` ไม่รู้: สไตล์ที่ดีไซน์ตั้งไว้ (พารามิเตอร์ `style`)
    /// และ **ฟอนต์/สี/ขนาดที่เจ้าของการ์ดตั้งให้ช่องนี้** (จาก environment) — พอมันเป็นคนใส่เอง
    /// ช่องทุกช่องในตู้จึงปรับได้ด้วยโค้ดที่เดียว แทนที่จะต้องไล่แก้ทีละใบทั้งห้าสิบจุด
    ///
    /// เงื่อนไขที่ต้องรักษา: `Text` ที่ถูกครอบ **ต้องไม่ตั้ง `.font`/`.foregroundStyle` ของตัวเอง**
    /// เมื่ออยากให้ปรับได้ (ค่าที่ติดกับ `Text` ชนะค่าที่มาจาก environment เสมอ)
    /// ใบที่จำเป็นต้องตั้งเองเพราะกล่องมีตัวอักษรหลายก้อน ใช้ `WidgetTextStyle.font(_:_:for:_:)` แทน
    func body(content: Content) -> some View {
        // ตัวอักษรบนการ์ดไม่ถูกซ่อนตอนพิมพ์ — มันคือตัวพรีวิว ต้องวิ่งตามที่พิมพ์บนแถบล่างสด ๆ
        // ผู้ใช้จึงเห็นทันทีว่ายาวเกินกรอบเมื่อไหร่ ซึ่งเป็นคำถามเดียวที่ตอบจากช่องกรอกไม่ได้
        var slotStyle = style.tuned(by: tune, slot: id, ink: ink, accent: accent)
        slotStyle.tilt = tilt
        // # สีที่ใส่คือ **สีของสไตล์** เสมอ ไม่ใช่ "สีระบบเมื่อยังไม่ถูกสั่งทับ"
        //
        // เคยเขียนเป็น `picked ? สีที่เลือก : .foreground` ด้วยเจตนาว่า "ยังไม่เลือกก็อย่าไปแตะ" —
        // แต่ `.foreground` ไม่ใช่ "ไม่แตะ" มันคือ *สีระบบ* ที่ไปทับสีที่ชิ้นตั้งไว้กับบรรพบุรุษ
        // ผลคือแถวติดต่อของสำรับสติกเกอร์ (ซึ่งรับสีถ่านมาจาก `PopSheet` ไม่ได้ตั้งที่ตัว `Text`)
        // กลายเป็นตัวขาวบนเม็ดยาขาว = หายไปทั้งแถว
        //
        // สไตล์ของทุกช่องระบุสีของดีไซน์ไว้ครบอยู่แล้ว (เช็คแล้วทั้ง 50 จุด) ใส่ค่านั้นลงไปตรง ๆ
        // จึงถูกต้องทั้งสองทาง: ยังไม่เลือก = ได้สีของดีไซน์ · เลือกแล้ว = ได้สีที่เลือก
        // ส่วนใบที่ตั้งสีไว้ที่ตัว `Text` เอง (ตัวอักษรไล่เฉด · ป้ายไฟ) ยังชนะค่านี้ตามกติกาของ SwiftUI
        return content
            .font(slotStyle.font)
            .foregroundStyle(slotStyle.color)
            // ช่องแก้ได้ทุกช่องคือข้อมูลของผู้ใช้ — พรีวิว "ไม่มีข้อมูล" ทำให้เป็นแท่งว่างเท่าตัวอักษร
            .ghostDash(ghost && !keepText, font: slotStyle.font)
            .anchorPreference(key: TextSlotKey.self, value: .bounds) { b in
                editMode ? [TextSlotAnchor(id: id, bounds: b, style: slotStyle)] : []
            }
            // เบอร์ · อีเมล · ไลน์ · ชื่อ กดแล้วติดต่อได้ในโหมดดู — แถวที่ประกาศ `.linkSlot` ไว้ข้างนอก
            // ชนะค่านี้ (preference ของแม่ทับของลูก) พื้นที่กดจึงเป็นทั้งแถวเมื่อดีไซน์ต้องการ
            .linkSlot(editMode ? nil : id.field.contactURL)
    }
}

/// กรอบเส้นประของช่องหนึ่งช่อง — วาดที่ชั้นการ์ด ไม่ใช่ในตัว widget
///
/// เคยวาดเป็น overlay ติดกับตัวอักษรเลย แล้วเจอว่า **มองเห็นแค่เส้นเดียว**:
/// ท่าเปลี่ยนหน้าอย่าง `scrubVeil` ปิดท้ายด้วย `.mask { Rectangle() }` เพื่อให้บรรทัดมุดใต้ขอบตัวเอง
/// กรอบที่ถูกดันออกนอกตัวอักษร 3pt จึงถูกหน้ากากนั้นตัดทิ้งทุกด้านที่ล้นออกไป
/// ขึ้นมาวาดที่ชั้นนี้แล้วไม่มีหน้ากากของใครมาตัด — และได้อยู่เหนือเนื้อหา widget ด้วย
struct TextSlotDashes: View {
    let style: TextSlotStyle
    let accent: Color

    var body: some View {
        RoundedRectangle(cornerRadius: style.corner + 2, style: .continuous)
            .strokeBorder(accent.opacity(0.7),
                          style: StrokeStyle(lineWidth: 0.9, dash: [3, 2.6]))
            .allowsHitTesting(false)
    }
}

extension View {
    /// ประกาศว่าข้อความก้อนนี้คือช่อง `field` (ลำดับ `index` ถ้าเป็นรายการ)
    ///
    /// ติดไว้ที่ตัว `Text` หลังใส่ฟอนต์/สีครบแล้ว — กรอบที่ส่งขึ้นไปจะได้เท่าตัวอักษรจริง
    /// ไม่ใช่เท่ากล่องที่ครอบมันอยู่
    /// - Parameters:
    ///   - preset: ข้อความตั้งต้นที่ดีไซน์ใส่มา (เฉพาะช่องอิสระ `.note`) — ดู `TextSlotID.preset`
    ///   - hint: ชื่อช่องบนแถบพิมพ์ เมื่อชิ้นเดียวมีช่องอิสระหลายช่อง
    func editableText(_ field: ProfileField, index: Int? = nil,
                      widget: UUID? = nil, preset: String = "", hint: String? = nil,
                      _ style: TextSlotStyle) -> some View {
        modifier(EditableTextModifier(id: TextSlotID(field: field, index: index, widget: widget,
                                                     preset: preset, hint: hint),
                                      style: style))
    }
}

// MARK: - ย่อหน้าที่ตัดตามความสูงที่มีจริง

/// ย่อหน้าแนะนำตัว/คำพูด — จำนวนบรรทัดคำนวณจากความสูงที่เหลือ แล้วตัดท้ายด้วย …
///
/// ต่างจาก `.fixedSize(horizontal:false, vertical:true)` ที่ใช้อยู่เดิมตรงที่ตัวนั้นให้ข้อความ
/// เป็นคนกำหนดความสูง — พิมพ์ยาวขึ้นสองบรรทัด widget ก็ล้นออกนอกกรอบที่ผู้ใช้วางไว้
/// ตัวนี้กลับกัน: **กรอบเป็นคนกำหนดว่าอ่านได้กี่บรรทัด** อยากอ่านครบก็ยืดกรอบ
struct EditableParagraph: View {
    let field: ProfileField
    let style: TextSlotStyle
    /// เว้นที่ไว้ท้ายย่อหน้าเผื่อของที่ต้องอยู่ใต้มัน — หักออกก่อนคำนวณจำนวนบรรทัด
    var reserve: CGFloat = 0
    /// ชิ้นที่ย่อหน้านี้สังกัด — ใส่เฉพาะช่องที่เก็บต่อชิ้น (`.note`) ที่เหลือปล่อย nil
    var widget: UUID? = nil
    /// กรอบที่ย่อหน้าเกาะ — ตัวอักษรที่จัดกลาง/ชิดขวาต้องเกาะกรอบด้านนั้นด้วย
    /// ไม่งั้นเส้นประของช่องจะยังกินเต็มความกว้างทั้งที่ตัวอักษรย้ายไปอยู่อีกฝั่ง
    var anchor: Alignment = .topLeading

    /// หน้าตาที่เจ้าของการ์ดตั้งให้ช่องนี้ — ย่อหน้าตั้งฟอนต์ให้ `Text` เอง
    /// (ต้องรู้ความสูงบรรทัดก่อนวาด) จึงต้องปรับสไตล์ตรงนี้ ไม่ใช่รอให้ตัวประกาศช่องใส่ให้
    @Environment(\.widgetTextStyle) private var tune
    @Environment(\.cardInk) private var ink
    @Environment(\.cardAccent) private var accent
    /// ใบที่ล็อก/ช่องในตู้ที่ยังไม่มีแนะนำตัว — วาดย่อหน้าตัวอย่างให้เห็นว่ากรอกแล้วใบนี้เป็นยังไง
    @Environment(\.sampleData) private var sample

    private var id: TextSlotID { TextSlotID(field: field, widget: widget) }

    var body: some View {
        let style = self.style.tuned(by: tune, slot: id, ink: ink, accent: accent)
        return GeometryReader { geo in
            let step = style.uiFont.lineHeight + style.lineSpacing
            let room = max(0, geo.size.height - reserve) + style.lineSpacing
            let lines = max(1, Int(room / max(step, 1)))
            Text(sample && field == .about ? Profile.me.shownAbout : Profile.me.text(id))
                .font(style.font)
                .tracking(style.tracking)
                .foregroundStyle(style.color)
                .lineSpacing(style.lineSpacing)
                .multilineTextAlignment(style.align)
                .lineLimit(lines)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                // ส่ง **สไตล์ของดีไซน์** เข้าไป ไม่ใช่ตัวที่ปรับแล้ว — ตัวประกาศช่องปรับให้เองอีกชั้น
                .editableText(field, widget: widget, self.style)
                .frame(width: geo.size.width, height: geo.size.height, alignment: anchor)
        }
    }
}

// MARK: - แถบพิมพ์เหนือคีย์บอร์ด

/// ช่องกรอกที่ลอยอยู่เหนือคีย์บอร์ด — ที่เดียวที่พิมพ์ได้
///
/// # ทำไมไม่พิมพ์ทับตัวอักษรบนการ์ดตรง ๆ
///
/// เคยทำแบบนั้นแล้วมีปัญหาสองข้อที่แก้ไม่ได้ด้วยการจูน:
///
/// 1. **ตัวอักษรบนการ์ดเล็กมาก** — สายงานคือ 8.5pt ชื่อผู้ใช้ 7.5pt
///    วางเคอร์เซอร์ เลือกคำ ลากหัวท้าย ทำไม่ได้จริงที่ขนาดนั้น
/// 2. **คีย์บอร์ดบังของที่กำลังพิมพ์** — ต้องคอยดันแคนวาสหนี ซึ่งขยับทั้งหน้าไปมาจนสับสน
///
/// แถบนี้ตอบทั้งสองข้อ: ช่องกรอกอยู่ที่เดิมเสมอ (เหนือคีย์บอร์ด) ขนาดตัวอักษรอ่านออก
/// มีชื่อช่องกำกับว่ากำลังแก้อะไรอยู่ · ส่วนตัวอักษรบนการ์ดอัปเดตสดตามที่พิมพ์
/// ผู้ใช้จึงเห็นผลจริงพร้อมกับที่พิมพ์ โดยไม่ต้องพิมพ์ลงบนของที่เล็กเกินจะกดถูก
struct TextEditBar: View {
    let id: TextSlotID
    let theme: CardTheme
    /// หน้าตาที่ช่องนี้ใช้อยู่ตอนนี้ (ของชิ้นที่ถูกเลือก) — `nil` เมื่อยังหาชิ้นไม่เจอ
    var style: WidgetTextStyle? = nil
    var onStyle: (((inout WidgetTextStyle) -> Void) -> Void)? = nil
    let onDone: () -> Void

    @FocusState private var focused: Bool
    /// แถวเครื่องมือที่กางอยู่ — `nil` = ยังไม่กาง (แถบบางที่สุด เห็นการ์ดมากที่สุด)
    ///
    /// ท่าเดียวกับ IG: เครื่องมือกางทีละอย่าง ไม่ใช่กองสามแถวรอไว้ตลอดเวลา
    /// (แถบที่สูงสามแถวดันการ์ดขึ้นไปจนไม่เห็นตัวอักษรที่กำลังแก้ ซึ่งเป็นสิ่งเดียวที่ต้องเห็น)
    @State private var tool: Tool? = nil

    private enum Tool { case font, color, size }

    private var field: ProfileField { id.field }
    private var value: String { Profile.me.text(id) }
    /// ชื่อช่องบนหัวแถบ — ชิ้นที่มีข้อความอิสระหลายก้อน (ปกผลงาน · ขั้นตอนทำงาน)
    /// ต้องบอกว่ากำลังแก้ก้อนไหน ไม่งั้นทุกก้อนขึ้นว่า "ข้อความ" เหมือนกันหมด
    private var label: String { id.hint ?? field.label }

    private var slotFace: CardFont? { style?.face(for: id.field, id.index) }
    private var slotTint: TextTint? { style?.tint(for: id.field, id.index) }
    private var slotSize: WidgetTextSize { style?.size(for: id.field, id.index) ?? .m }

    /// เปลี่ยนหน้าตาของ **ช่องนี้ช่องเดียว** — คีย์มาจากฟิลด์+ลำดับของช่องที่กำลังแก้
    private func set(_ change: @escaping (inout WidgetTextStyle, String) -> Void) {
        guard let onStyle else { return }
        let key = WidgetTextStyle.slotKey(id.field, id.index)
        onStyle { change(&$0, key) }
        Haptics.impact(.light)
    }

    var body: some View {
        VStack(spacing: 10) {
            if onStyle != nil, let tool { picker(tool) }
            bar
        }
    }

    /// แถวเครื่องมือที่กางอยู่ — ฟอนต์เลื่อนได้ · สีเลื่อนได้ · ขนาดหกขั้น
    @ViewBuilder
    private func picker(_ tool: Tool) -> some View {
        switch tool {
        case .font:
            FontCarousel(selection: slotFace ?? .noto) { f in
                set { $0.slotFaces[$1] = f }
            }
        case .color:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // ใบแรกคือทางกลับ — สีที่ดีไซน์เลือกไว้ (ครีมบนแผ่นเข้ม ฯลฯ)
                    // ไม่มีใบนี้ คนที่เผลอกดสีจะหาของเดิมไม่เจออีกเลย
                    autoChip(on: slotTint == nil) { set { $0.slotTints[$1] = nil } }
                    ForEach(TextTint.allCases) { t in
                        TintChip(tint: t, on: slotTint == t, accent: theme.rawAccent) {
                            set { $0.slotTints[$1] = t }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 44)
        case .size:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WidgetTextSize.allCases) { v in
                        sizeChip(v, on: slotSize == v) { set { $0.slotSizes[$1] = v } }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 44)
        }
    }

    private func autoChip(on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("ตามดีไซน์")
                .font(.sh(12, .semibold))
                .foregroundStyle(on ? Color.black.opacity(0.88) : Color.white.opacity(0.9))
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(Capsule().fill(on ? Color.white.opacity(0.95) : Color.white.opacity(0.08)))
                .overlay(Capsule().strokeBorder(.white.opacity(on ? 0 : 0.22), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    private func sizeChip(_ v: WidgetTextSize, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(v.label)
                .font(.sh(12, .bold))
                .foregroundStyle(on ? Color.black.opacity(0.88) : Color.white.opacity(0.9))
                .frame(minWidth: 40).frame(height: 36)
                .background(Capsule().fill(on ? Color.white.opacity(0.95) : Color.white.opacity(0.08)))
                .overlay(Capsule().strokeBorder(.white.opacity(on ? 0 : 0.22), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    /// ปุ่มกางเครื่องมือหนึ่งตัว — กดซ้ำที่ตัวเดิมคือหุบ (แป้นพิมพ์ไม่หุบตาม)
    private func toolButton(_ t: Tool, symbol: String, label: String) -> some View {
        Button {
            withAnimation(Motion.snap) { tool = tool == t ? nil : t }
            Haptics.impact(.light)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tool == t ? Color.black.opacity(0.85) : Color.primary.opacity(0.65))
                .frame(width: 34, height: 30)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tool == t ? Color.white.opacity(0.92) : Color.clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var bar: some View {
        // แผ่นลอย ไม่ใช่แถบเต็มความกว้าง — แถบที่ชนขอบจอทั้งสามด้านอ่านเป็น "ส่วนหนึ่งของคีย์บอร์ด"
        // ซึ่งผิด มันคือของของการ์ด · แผ่นที่มีระยะขอบรอบตัวและมุมโค้งอ่านเป็น "เครื่องมือที่ลอยขึ้นมา"
        // ใช้ Liquid Glass ตัวเดียวกับปุ่มบนแถบบน — ทั้งจอจึงพูดภาษาวัสดุเดียวกัน
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)

        return GlassEffectContainer(spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.sh(9.5, .semibold))
                            .foregroundStyle(theme.accent)
                        if let limit = field.limit {
                            // เหลืออีกกี่ตัว — ต้องเห็นก่อนพิมพ์ชน ไม่ใช่ตอนพิมพ์แล้วตัวหาย
                            Text("\(value.count)/\(limit)")
                                .font(.sh(9, .medium))
                                .foregroundStyle(.secondary.opacity(value.count >= limit ? 1 : 0.6))
                        }
                        Spacer(minLength: 0)

                        if onStyle != nil {
                            toolButton(.font, symbol: "textformat", label: "ฟอนต์")
                            toolButton(.color, symbol: "paintpalette", label: "สีตัวอักษร")
                            toolButton(.size, symbol: "textformat.size", label: "ขนาด")
                        }
                    }

                    field.isParagraph
                        ? AnyView(TextField("", text: Profile.me.binding(id), axis: .vertical)
                            .lineLimit(1...4))
                        : AnyView(TextField("", text: Profile.me.binding(id))
                            .submitLabel(.done)
                            .onSubmit(onDone))
                }
                .font(.sh(15))
                .foregroundStyle(.primary)
                .tint(theme.accent)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(field.keyboard)
                .focused($focused)

                // ล้างทั้งช่องในปุ่มเดียว — เร็วกว่าลากเลือกทั้งก้อนแล้วลบในช่องแคบ ๆ
                if !value.isEmpty {
                    Button {
                        Profile.me.set(id, "")
                        Haptics.impact(.light)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                }

                Button("เสร็จ", action: onDone)
                    .font(.sh(13, .semibold))
                    .buttonStyle(.glassProminent)
                    .tint(theme.accent)
            }
            .padding(.leading, 16)
            .padding(.trailing, 7)
            .padding(.vertical, 8)
            // ม่านบางใต้เนื้อหา — กระจกใสล้วนทำให้ตัวหนังสือจมเวลาลอยอยู่บนรูปพื้นหลัง
            .background(shape.fill(theme.inkStyle.isLight ? Color.white.opacity(0.5)
                                                          : Color.black.opacity(0.22)))
            .glassEffect(.regular, in: shape)
            .shadow(color: .black.opacity(0.32), radius: 18, y: 8)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
        // โฟกัสหลังแผ่นเข้าลำดับชั้นแล้ว — สั่งในเฟรมเดียวกับที่มันเพิ่งเกิดจะไม่ติด
        .task { focused = true }
        // ปัดลงบนแผ่นเพื่อปิด — ท่าที่มือไปถึงง่ายที่สุดขณะพิมพ์
        .gesture(DragGesture(minimumDistance: 18).onEnded { g in
            if g.translation.height > 18 { onDone() }
        })
    }
}

// MARK: - ที่จำกรอบของช่องข้อความทั้งหน้า

/// กล่องเก็บกรอบช่องข้อความแยกตาม widget
///
/// เป็นคลาสธรรมดา ไม่ใช่ `@Observable` โดยตั้งใจ — ค่านี้ถูกเขียนใหม่ทุกครั้งที่ผังขยับ
/// แต่ไม่มีใครอ่านมันตอนวาด มีแต่ตอนนิ้วแตะ ถ้าให้มันสั่งวาดใหม่จะกลายเป็นวงวน
/// (เขียน → วาดใหม่ → คำนวณกรอบใหม่ → เขียน) ที่ไม่ได้ให้อะไรกลับมาเลย
final class TextSlotBox {
    var rects: [UUID: [TextSlotRect]] = [:]

    /// ช่องที่นิ้วแตะโดน — เผื่อขอบรอบละ 6pt เพราะบรรทัดบาง ๆ อย่างสายงานสูงไม่ถึงนิ้ว
    ///
    /// ไล่จากช่องท้ายลิสต์ขึ้นมา — ช่องที่ประกาศทีหลังอยู่ชั้นบนกว่าเมื่อกรอบซ้อนกัน
    func hit(_ point: CGPoint, in widget: UUID) -> TextSlotRect? {
        rects[widget]?.last { $0.rect.insetBy(dx: -6, dy: -6).contains(point) }
    }
}
