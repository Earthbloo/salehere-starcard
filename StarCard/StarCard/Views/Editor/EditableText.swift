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

    var font: Font { face.font(size, weight) }
    var uiFont: UIFont { face.uiFont(size, weight) }
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
}

// MARK: - ตัวประกาศว่า "ข้อความก้อนนี้แก้ได้"

private struct EditableTextModifier: ViewModifier {
    @Environment(\.textEditMode) private var editMode

    let id: TextSlotID
    let style: TextSlotStyle

    func body(content: Content) -> some View {
        // ตัวอักษรบนการ์ดไม่ถูกซ่อนตอนพิมพ์ — มันคือตัวพรีวิว ต้องวิ่งตามที่พิมพ์บนแถบล่างสด ๆ
        // ผู้ใช้จึงเห็นทันทีว่ายาวเกินกรอบเมื่อไหร่ ซึ่งเป็นคำถามเดียวที่ตอบจากช่องกรอกไม่ได้
        content
            .anchorPreference(key: TextSlotKey.self, value: .bounds) { b in
                editMode ? [TextSlotAnchor(id: id, bounds: b, style: style)] : []
            }
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
    func editableText(_ field: ProfileField, index: Int? = nil,
                      widget: UUID? = nil, _ style: TextSlotStyle) -> some View {
        modifier(EditableTextModifier(id: TextSlotID(field: field, index: index, widget: widget),
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

    private var id: TextSlotID { TextSlotID(field: field, widget: widget) }

    var body: some View {
        GeometryReader { geo in
            let step = style.uiFont.lineHeight + style.lineSpacing
            let room = max(0, geo.size.height - reserve) + style.lineSpacing
            let lines = max(1, Int(room / max(step, 1)))
            Text(Profile.me.text(id))
                .font(style.font)
                .tracking(style.tracking)
                .foregroundStyle(style.color)
                .lineSpacing(style.lineSpacing)
                .multilineTextAlignment(style.align)
                .lineLimit(lines)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .editableText(field, widget: widget, style)
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
    let onDone: () -> Void

    @FocusState private var focused: Bool

    private var field: ProfileField { id.field }
    private var value: String { Profile.me.text(id) }

    var body: some View {
        // แผ่นลอย ไม่ใช่แถบเต็มความกว้าง — แถบที่ชนขอบจอทั้งสามด้านอ่านเป็น "ส่วนหนึ่งของคีย์บอร์ด"
        // ซึ่งผิด มันคือของของการ์ด · แผ่นที่มีระยะขอบรอบตัวและมุมโค้งอ่านเป็น "เครื่องมือที่ลอยขึ้นมา"
        // ใช้ Liquid Glass ตัวเดียวกับปุ่มบนแถบบน — ทั้งจอจึงพูดภาษาวัสดุเดียวกัน
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)

        GlassEffectContainer(spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(field.label)
                            .font(.sh(9.5, .semibold))
                            .foregroundStyle(theme.accent)
                        if let limit = field.limit {
                            // เหลืออีกกี่ตัว — ต้องเห็นก่อนพิมพ์ชน ไม่ใช่ตอนพิมพ์แล้วตัวหาย
                            Text("\(value.count)/\(limit)")
                                .font(.sh(9, .medium))
                                .foregroundStyle(.secondary.opacity(value.count >= limit ? 1 : 0.6))
                        }
                        Spacer(minLength: 0)
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
