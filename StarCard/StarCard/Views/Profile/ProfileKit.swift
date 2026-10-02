import SwiftUI
import PhosphorSwift

// MARK: - ชุดชิ้นส่วนของหน้า "ข้อมูลของฉัน"
//
// # โทน — ยกมาจากฟอร์มสมัครฝั่งเว็บ (roojai-influencer v16.1) ตรง ๆ
//
// พื้นครีมอุ่น `#FCF7F5` ไม่ใช่ขาวจัด · การ์ดขาวขอบบาง `#F2E9E5` มุม 20 · แดงแบรนด์ `#D42B1D`
// เป็นสี action เดียว (ปุ่ม/ป้าย ไม่ทาพื้นใหญ่) · แดงเข้ม `#941F13` ไว้ไล่สีและตัวหนังสือบนแดงอ่อน ·
// ทอง `#F3BF42` = "ผ่านแล้ว/สำเร็จ" ตามดาวใน CI **ห้ามมีตัวหนังสือขาวทับ** (contrast 1.7:1) ·
// สถานะเลือกแล้ว = พื้นแดงอ่อน `#FDF0EE` + ขอบแดง + ตัวหนังสือแดงเข้ม (ชิป/การ์ดตัวเลือก/แถวช่องทาง)
//
// # ทำไมไม่ใช้ `Form`/`List` ของระบบ
//
// ฟอร์มระบบบังคับฟอนต์ระบบและระยะของมันเอง — ชิ้นส่วนข้างล่างวาดเองทั้งหมดบน NotoSansThai
// ให้หน้าตาเป็นเนื้อเดียวกับฟอร์มเว็บที่ทีมออกแบบไว้ และเล่นสนุกได้ (อีโมจิ · สติกเกอร์ · สปริง)
//
// # กติกาของช่องกรอก (จากผล audit ฟอร์มเว็บ)
//
// * ทุกช่องมีป้ายชื่อ + ดาวบังคับ + ข้อผิดพลาด **ใต้ช่องนั้น** ไม่ใช่ท้ายหน้า
// * คีย์บอร์ดตรงชนิด (เบอร์ = แป้นตัวเลข · อีเมล = แป้นอีเมล ไม่ขึ้นตัวใหญ่)
// * ค่าที่พิมพ์บันทึกเองทุกจังหวะ — ไม่มีปุ่ม "บันทึก" ให้ลืมกด

enum PK {
    // # โทเคนของ Sale Here (salehere-ios · `SearchRevampStyle` + `UIColor.Reds/Grays`) — แอปพี่น้องต้องพูดภาษาเดียวกัน
    //
    // พื้น #F9FAFB · การ์ดขาว เส้น #E5E7EB เงา 0.04 · ตัวหนังสือ #16181D / #666666 / #919191
    // แดงทาเต็มปุ่ม/ทุกชิปดูโบราณ (ผู้ใช้ 19 ก.ย.) — ตัวหลักเป็นหมึก #16181D ขาวดำแบบแอปยุคนี้
    // แดง #ED1C24 เหลือเป็น "จุด" ของแบรนด์: ป้ายเลขขั้น · ดาวบังคับ · ข้อผิดพลาด
    // เลือกแล้ว = พื้นเทาอ่อน + ขอบดำ + ตัวหนังสือดำหนา (ไม่ทึบดำ — ผู้ใช้ขอ "ดำแบบเทาๆ เล่นสีขอบดำ")
    // ปุ่มหลัก = ถ่าน #2B2D33 ดำอมเทา ไม่ใช่ดำสนิท
    // เขียว = ครบ/ยืนยันแล้ว · ส้ม = ยังขาด · เหลืองดาว #FFC200 = STAR
    private static func hex(_ v: UInt32) -> Color {
        Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
    static let bg = hex(0xF9FAFB)
    /// ของที่ "เลือกแล้ว" — พื้นเทาอ่อน ขอบดำ ตัวหนังสือดำ
    static let pick = hex(0xF1F2F4)
    static let onPick = hex(0x16181D)
    static let pickLine = hex(0x16181D)
    /// ถ่าน — ปุ่มหลัก
    static let charcoal = hex(0x2B2D33)
    static let card = Color.white
    static let shadow = Color.black.opacity(0.04)
    static let surface = Color.white
    /// พื้นช่องกรอก = bgSecondary ของแอป
    static let fieldFill = hex(0xF3F4F6)
    static let fieldFocus = hex(0xE5E7EB)
    static let line = hex(0xE5E7EB)
    static let line2 = hex(0xD1D5DB)
    // ตัวหนังสือ
    static let ink = hex(0x16181D)
    static let onInk = Color.white
    static let muted = hex(0x666666)
    static let hint = hex(0x919191)
    // แดงแบรนด์
    static let red = hex(0xED1C24)
    static let redDark = hex(0xC8161D)
    static let redTint = hex(0xFDE8E9)
    static let redTint2 = hex(0xF8B4B6)
    // ทอง CI — เฉพาะดาว STAR และการ์ดรางวัลหน้าจบ
    static let gold = hex(0xFFC200)
    static let gold2 = Color(red: 250 / 255, green: 224 / 255, blue: 120 / 255)
    static let goldInk = Color(red: 58 / 255, green: 26 / 255, blue: 5 / 255)
    // สถานะ — ป้ายเล็ก ๆ ที่มีความหมายเท่านั้น
    static let ok = Color(red: 0.16, green: 0.62, blue: 0.37)
    static let okTint = ok.opacity(0.12)
    static let warn = Color(red: 0.92, green: 0.56, blue: 0.08)
    static let warnTint = warn.opacity(0.12)
    static var glass: Glass { .regular.tint(.white.opacity(0.7)) }
    static var glassButton: Glass { .regular.tint(.white.opacity(0.7)).interactive() }
    // ชื่อพาสเทลเดิม — ชี้ไปพื้นโปร่งเดียวกันหมด
    static let peach = fieldFill
    static let lavender = fieldFill
    static let mint = fieldFill
    static let sky = fieldFill
    static let lemon = fieldFill
    static let rose = fieldFill
    static let aqua = fieldFill
    static let sand = fieldFill

    // ชื่อเก่าที่ section ต่าง ๆ ยังเรียก
    static let panel = surface
    static let panelStrong = redTint
    static let field = fieldFill
    static let stroke = line2
    static let ink2 = muted
    static let ink3 = hint
    static let err = red

    static let radius: CGFloat = 24
    static let fieldRadius: CGFloat = 16

    static func shape(_ r: CGFloat = radius) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: r, style: .continuous)
    }

    /// ป้าย STAR กับการ์ดรางวัลใช้ไล่สี — ปุ่มปกติเป็นแดงเรียบ
    static var redGradient: LinearGradient {
        LinearGradient(colors: [red, redDark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var goldGradient: LinearGradient {
        LinearGradient(colors: [gold2, gold], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - แผ่น

/// การ์ดขาวหนึ่งเรื่อง — ขอบบาง เงาอุ่นจาง ๆ หัวข้อทางซ้าย
struct PKPanel<Content: View>: View {
    var title: String? = nil
    var subtitle: String? = nil
    var trailing: AnyView? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if title != nil || subtitle != nil {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        if let title {
                            Text(title).font(.sh(16, .bold)).foregroundStyle(PK.ink)
                        }
                        if let subtitle {
                            Text(subtitle).font(.sh(12.5, .medium)).foregroundStyle(PK.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 0)
                    if let trailing { trailing }
                }
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PKSurface())
    }
}

/// ป้ายหัวช่อง — ชื่อ + ดาวบังคับ + คำใบ้ทางขวา
struct PKLabel: View {
    let text: String
    var required = false
    var hint: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(text).font(.sh(13, .semibold)).foregroundStyle(PK.muted)
            if required { Text("*").font(.sh(13, .bold)).foregroundStyle(PK.red) }
            Spacer(minLength: 0)
            if let hint {
                Text(hint).font(.sh(11.5, .medium)).foregroundStyle(PK.hint)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
        }
    }
}

// MARK: - ช่องพิมพ์

/// ช่องพิมพ์หนึ่งช่อง — ป้าย · ช่อง · ข้อผิดพลาดใต้ช่อง
///
/// `id` ใช้สองอย่าง: โฟกัสคีย์บอร์ด และเป็นเป้าให้ `ScrollViewReader` เลื่อนมาหาเมื่อ validate ไม่ผ่าน
struct PKField: View {
    let label: String
    var required = false
    @Binding var text: String
    var placeholder = ""
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var autocap: TextInputAutocapitalization = .sentences
    var noCorrect = false
    var paragraph = false
    var error: String? = nil
    var hint: String? = nil
    var limit: Int? = nil
    var leading: String? = nil
    let id: String
    var focus: FocusState<String?>.Binding
    var onCommit: () -> Void = {}

    private var isFocused: Bool { focus.wrappedValue == id }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // ตัวนับโผล่ตอนใกล้เต็มเท่านั้น — "0/40" บนทุกช่องคือเสียงรบกวน ไม่ใช่ข้อมูล
            if !label.isEmpty {
                PKLabel(text: label, required: required, hint: counter ?? hint)
            }

            HStack(spacing: 6) {
                if let leading {
                    // ป้ายนำหน้าห้ามตกบรรทัด — ช่องพิมพ์ต่างหากที่ต้องยอมหด
                    Text(leading).font(.sh(15.5, .semibold)).foregroundStyle(PK.hint)
                        .lineLimit(1).fixedSize()
                }
                Group {
                    if paragraph {
                        TextField("", text: $text, prompt: prompt, axis: .vertical)
                            .lineLimit(2...5)
                    } else {
                        TextField("", text: $text, prompt: prompt)
                            .submitLabel(.done)
                            .onSubmit { focus.wrappedValue = nil; onCommit() }
                    }
                }
                .font(.sh(16))
                .foregroundStyle(PK.ink)
                .tint(PK.ink)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .textInputAutocapitalization(autocap)
                .autocorrectionDisabled(noCorrect)
                .focused(focus, equals: id)
                .onChange(of: isFocused) { _, on in if !on { onCommit() } }

                if !text.isEmpty && isFocused {
                    Button {
                        text = ""
                        Haptics.impact(.light)
                    } label: {
                        PIcon(.xCircle, size: 17, weight: .fill)
                            .foregroundStyle(PK.line2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 15)
            .frame(minHeight: 46)
            // filled ไม่มีขอบตอนปกติ — ช่องที่มีขอบทุกช่องอ่านเป็นเอกสาร ช่องที่ "จม" ลงไปอ่านเป็นแอป
            .background(PK.shape(PK.fieldRadius).fill(isFocused ? PK.fieldFocus : PK.fieldFill))
            .overlay(PK.shape(PK.fieldRadius).strokeBorder(
                error != nil ? PK.red : (isFocused ? PK.ink : .clear),
                lineWidth: 1.6))
            .animation(Motion.snap, value: isFocused)

            if let error {
                HStack(spacing: 5) {
                    PIcon(.warningCircle, size: 12, weight: .fill)
                    Text(error).font(.sh(12, .medium))
                }
                .foregroundStyle(PK.red)
                .transition(.opacity)
            }
        }
        .id(id)
        .contentShape(Rectangle())
        .onTapGesture { focus.wrappedValue = id }
    }

    private var prompt: Text {
        Text(placeholder).font(.sh(16)).foregroundStyle(PK.hint.opacity(0.75))
    }

    private var counter: String? {
        guard let limit, text.count * 10 >= limit * 7 else { return nil }
        return "\(text.count)/\(limit)"
    }
}

/// ช่องเลือกจากรายการ — หน้าตาเหมือน `PKField` แต่แตะแล้วเป็นเมนู
/// ใช้กับรายการยาวที่ชิปจะกินทั้งจอ (เช่น ธนาคาร 13 แห่ง)
struct PKSelect: View {
    let label: String
    var required = false
    let options: [String]
    @Binding var value: String
    var placeholder = "เลือก…"
    var error: String? = nil
    let id: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            PKLabel(text: label, required: required)
            Menu {
                ForEach(options, id: \.self) { o in
                    Button {
                        Haptics.impact(.light)
                        value = o
                    } label: {
                        if o == value { Label { Text(o) } icon: { Ph.check.bold } } else { Text(o) }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(value.isEmpty ? placeholder : value)
                        .font(.sh(16)).foregroundStyle(value.isEmpty ? PK.hint.opacity(0.75) : PK.ink)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    PIcon(.caretUpDown, size: 13).foregroundStyle(PK.hint)
                }
                .padding(.horizontal, 15)
                .frame(minHeight: 46)
                .background(PK.shape(PK.fieldRadius).fill(PK.fieldFill))
                .overlay(PK.shape(PK.fieldRadius).strokeBorder(error != nil ? PK.red : .clear, lineWidth: 1.6))
                .contentShape(PK.shape(PK.fieldRadius))
            }
            .tint(PK.ink)
            .animation(Motion.snap, value: value)
            if let error {
                HStack(spacing: 5) {
                    PIcon(.warningCircle, size: 12, weight: .fill)
                    Text(error).font(.sh(12, .medium))
                }
                .foregroundStyle(PK.red)
            }
        }
        .id(id)
    }
}

// MARK: - ไอคอน

/// ไอคอน Phosphor — ชุดเดียวกับเว็บ Sale Here · เรนเดอร์เป็น template ให้ `foregroundStyle` กำหนดสีได้
struct PIcon: View {
    let icon: Ph
    var size: CGFloat = 16
    var weight: Ph.IconWeight = .bold

    init(_ icon: Ph, size: CGFloat = 16, weight: Ph.IconWeight = .bold) {
        self.icon = icon; self.size = size; self.weight = weight
    }

    var body: some View {
        icon.weight(weight)
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

// MARK: - ตัวเลือก

/// ปุ่มตัวเลือกหนึ่งปุ่ม — แคปซูลกว้างเต็มช่อง เลือกแล้วพื้นหมึกตัวขาว · จางเมื่อครบโควตา
struct PKChoice: View {
    let label: String
    var on = false
    var dim = false
    let action: () -> Void

    @State private var bumps = 0

    var body: some View {
        Button {
            guard !dim else { Haptics.rigid(); return }
            Haptics.impact(.light)
            bumps += 1
            action()
        } label: {
            Text(label)
                .font(.sh(13.5, on ? .bold : .semibold))
                .foregroundStyle(on ? PK.onPick : PK.ink.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineLimit(2).minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 40)
                // ยังไม่เลือก = ขาวเส้นบาง ใช้ได้ทั้งบนกระดาษครีมและในการ์ดขาว (พื้นเทาทึบทั้งตารางดูหม่น)
                .background(Capsule().fill(on ? PK.pick : PK.card))
                .overlay(Capsule().strokeBorder(on ? PK.pickLine : PK.line, lineWidth: on ? 1.5 : 1))
                .opacity(dim ? 0.4 : 1)
                .contentShape(Capsule())
        }
        .buttonStyle(DockPress())
        .modifier(PKBump(trigger: bumps))
        .animation(Motion.snap, value: on)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// ตารางปุ่มตัวเลือก 2 คอลัมน์ กว้างเท่ากันทุกปุ่ม — ใช้กับทุกคำถามที่เลือกจากรายการ
struct PKChoiceGrid<Item: Hashable>: View {
    let items: [Item]
    var label: (Item) -> String
    var isOn: (Item) -> Bool
    var isDim: (Item) -> Bool = { _ in false }
    var action: (Item) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                PKChoice(label: label(item), on: isOn(item), dim: isDim(item)) { action(item) }
            }
        }
    }
}

/// ตารางกระเบื้อง 2 คอลัมน์ — จำนวนคี่ ใบสุดท้ายอยู่ซ้ายขนาดเท่าใบอื่น (ใบกว้างเต็มแถวจะดูเป็นคนละอย่าง)
struct PKTileGrid<Item: Identifiable, Tile: View>: View {
    let items: [Item]
    @ViewBuilder let tile: (Item) -> Tile

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(stride(from: 0, to: items.count, by: 2)), id: \.self) { i in
                HStack(alignment: .top, spacing: 8) {
                    tile(items[i])
                    if i + 1 < items.count { tile(items[i + 1]) } else { Color.clear.frame(maxWidth: .infinity) }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}


/// ชิปเลือก — ขาวขอบบาง · เลือกแล้วพื้นแดงอ่อน ตัวหนังสือแดงเข้ม (ภาษาเดียวกับ `.chip.on` ของเว็บ)
/// จางและกดไม่ได้เมื่อครบโควตา — ไม่ใช่ดูกดได้แล้วเงียบ
struct PKChip: View {
    let label: String
    var on = false
    var dim = false
    var tint: Color = PK.red
    /// + หน้าชื่อ เลือกแล้วกลายเป็น ✓ — บอกว่า "เลือกได้หลายอัน" โดยไม่ต้องมีคำอธิบาย
    var plus = false
    let action: () -> Void

    @State private var bumps = 0
    private var brand: Bool { tint == PK.red }

    var body: some View {
        Button {
            guard !dim else { Haptics.rigid(); return }
            Haptics.impact(.light)
            bumps += 1
            action()
        } label: {
            HStack(spacing: 6) {
                if plus {
                    PIcon(on ? .check : .plus, size: 11)
                }
                Text(label)
                    .font(.sh(14, on ? .bold : .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(on ? (brand ? PK.onInk : tint) : PK.ink.opacity(dim ? 0.3 : 0.8))
            .padding(.horizontal, 15).padding(.vertical, 10)
            .background(Capsule().fill(on ? (brand ? PK.ink : tint.opacity(0.16)) : PK.surface.opacity(dim ? 0.5 : 1)))
            .overlay(Capsule().strokeBorder(on ? (brand ? PK.ink : tint) : PK.line2, lineWidth: on ? 1.5 : 1.2))
            .contentShape(Capsule())
        }
        .buttonStyle(DockPress())
        .modifier(PKBump(trigger: bumps))
        .animation(Motion.snap, value: on)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// การ์ดตัวเลือกแบบกระเบื้อง — ไอคอนเล็กซ้าย · ชื่อ · คำอธิบายสั้น (คำถามที่เลือกอย่างเดียว ไม่ต้องพิมพ์)
/// ยังไม่เลือก = พื้นเทาอ่อนไม่มีขอบ · เลือกแล้ว = พื้นหมึก (ไม่มีวงติ๊ก — พื้นก็บอกอยู่แล้ว)
/// แนวนอน ไม่ใช่ไอคอนใหญ่กลาง — ใบสูง 160pt สองใบกินครึ่งจอ ทั้งที่เป็นแค่คำถามเลือกหนึ่งข้อ
struct PKTile: View {
    let icon: Ph
    let title: String
    var detail: String? = nil
    var on = false
    let action: () -> Void

    @State private var bumps = 0

    var body: some View {
        Button {
            Haptics.impact(.light)
            bumps += 1
            action()
        } label: {
            HStack(spacing: 10) {
                PIcon(icon, size: 17, weight: on ? .fill : .regular)
                    .foregroundStyle(on ? PK.onPick : PK.ink)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(on ? Color.white : PK.fieldFill))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.sh(14, .bold)).foregroundStyle(on ? PK.onPick : PK.ink)
                        .lineLimit(2).minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                    if let detail {
                        Text(detail).font(.sh(11, .medium)).foregroundStyle(on ? PK.onPick.opacity(0.75) : PK.muted)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11).padding(.vertical, 11)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(PK.shape(16).fill(on ? PK.pick : PK.card))
            .overlay(PK.shape(16).strokeBorder(on ? PK.pickLine : PK.line, lineWidth: on ? 1.5 : 1))
            .contentShape(PK.shape(16))
        }
        .buttonStyle(DockPress())
        .modifier(PKBump(trigger: bumps))
        .animation(Motion.snap, value: on)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

// MARK: - แถบปุ่มล่าง

/// พื้นแถบปุ่มล่าง — ทึบทั้งแถบจนถึงขอบจอ (เนื้อหาที่เลื่อนไปอยู่ใต้แถบต้องไม่ทะลุขึ้นมา)
/// มีแค่ 24pt เหนือแถบที่จางเป็นขอบนุ่ม ให้รู้ว่ายังมีเนื้อหาต่อข้างล่าง
struct PKBottomBar: ViewModifier {
    func body(content: Content) -> some View {
        content.background(alignment: .top) {
            // ม่านมืดไล่ขึ้น ไม่ใช่แถบทึบ — เวทีสีการ์ดยังเห็นต่อลงไปถึงขอบจอเหมือนคลัง
            VStack(spacing: 0) {
                LinearGradient(colors: [PK.bg.opacity(0), PK.bg.opacity(0.94)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 44)
                PK.bg.opacity(0.94)
            }
            .padding(.top, -44)
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - จังหวะ

/// เด้งนิดเดียวตอนถูกแตะ — มือรู้ว่า "รับแล้ว" ก่อนที่ตาจะเห็นขอบเปลี่ยนสี
struct PKBump: ViewModifier {
    let trigger: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat(1), trigger: trigger) { view, s in
            view.scaleEffect(s)
        } keyframes: { _ in
            SpringKeyframe(1.06, duration: 0.12, spring: .snappy)
            SpringKeyframe(1.0, duration: 0.30, spring: .bouncy)
        }
    }
}

/// ไหลเข้าที่ทีละชิ้น — จาง + ลอยขึ้น หน่วงตามลำดับ (เนื้อหา "ไหลเข้ามา" ไม่โผล่พรึ่บพร้อมกัน)
struct PKReveal: ViewModifier {
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 18)
            .onAppear {
                withAnimation(Motion.settle.delay(0.05 + Motion.stagger(index, step: 0.06, cap: 0.4))) { shown = true }
            }
    }
}

/// การ์ดตัวเลือกใหญ่ — ไอคอนในกล่องแดงอ่อน · ชื่อ · คำอธิบาย · ติ๊กแดง (= `.opt` ของเว็บ)
struct PKOptionCard: View {
    let icon: Ph
    let title: String
    var detail: String? = nil
    var on = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            HStack(spacing: 14) {
                PIcon(icon, size: 20, weight: .fill)
                    .foregroundStyle(PK.ink)
                    .frame(width: 44, height: 44)
                    .background(PK.shape(12).fill(PK.fieldFill))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.sh(15, .bold)).foregroundStyle(PK.ink)
                    if let detail {
                        Text(detail).font(.sh(12, .medium)).foregroundStyle(PK.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 6)
                ZStack {
                    Circle().strokeBorder(on ? PK.ink : PK.line2, lineWidth: 1.5)
                    if on {
                        Circle().fill(PK.ink)
                        PIcon(.check, size: 10).foregroundStyle(PK.onInk)
                    }
                }
                .frame(width: 22, height: 22)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(PK.shape(PK.fieldRadius).fill(PK.surface))
            .overlay(PK.shape(PK.fieldRadius).strokeBorder(on ? PK.ink : PK.line, lineWidth: on ? 1.8 : 1.2))
            .contentShape(PK.shape(PK.fieldRadius))
        }
        .buttonStyle(DockPress())
        .animation(Motion.snap, value: on)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// สวิตช์ปิด/เปิด แบบแถว — ป้ายซ้าย สวิตช์ขวา
struct PKToggleRow: View {
    let label: String
    var detail: String? = nil
    @Binding var on: Bool

    var body: some View {
        Toggle(isOn: $on) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.sh(14.5, .semibold)).foregroundStyle(PK.ink)
                if let detail {
                    Text(detail).font(.sh(12, .medium)).foregroundStyle(PK.muted)
                }
            }
        }
        .tint(PK.ink)
    }
}

// MARK: - ปุ่ม

/// ปุ่มหลักปุ่มเดียวของหน้า — ไล่สีแดง เงาแดงจาง ๆ (= `.welbtn`/`.btn.primary` ของเว็บ)
struct PKPrimaryButton: View {
    let title: String
    var symbol: Ph? = nil
    var tint: Color = PK.charcoal
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button {
            guard enabled else { Haptics.rigid(); return }
            Haptics.impact(.medium)
            action()
        } label: {
            HStack(spacing: 8) {
                StarText(title, size: 16, weight: .bold, color: .white)   // คำ STAR ในปุ่ม = ตรา ST★R
                if let symbol { PIcon(symbol, size: 15) }
            }
            // = `primaryButton` ของคลังการ์ด: กระจกย้อมสีเน้นของการ์ด ตัวหนังสือเข้ม
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Capsule().fill(tint))
            .opacity(enabled ? 1 : 0.4)
            .contentShape(Capsule())
        }
        .buttonStyle(DockPress())
        .animation(Motion.snap, value: enabled)
    }
}

/// ปุ่มรอง — ขาว ขอบบาง (= `.btn` ของเว็บ)
struct PKSecondaryButton: View {
    let title: String
    var symbol: Ph? = nil
    var height: CGFloat = 50
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            HStack(spacing: 7) {
                if let symbol { PIcon(symbol, size: 14) }
                Text(title).font(.sh(14.5, .semibold))
            }
            .foregroundStyle(PK.ink)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .contentShape(Capsule())
            .background(Capsule().fill(PK.card))
            .overlay(Capsule().strokeBorder(PK.line2, lineWidth: 1))
        }
        .buttonStyle(DockPress())
    }
}

/// ปุ่มกลม — กลับ/ปิด/เพิ่ม
struct PKCircleButton: View {
    let symbol: Ph
    var label: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            PIcon(symbol, size: 16)
                .foregroundStyle(PK.ink)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
                .glassEffect(PK.glassButton, in: Circle())
        }
        .buttonStyle(DockPress())
        .accessibilityLabel(label)
    }
}

// MARK: - ป้าย

/// ป้าย "✦ SALE HERE STAR" — ไล่สีแดง ตัวหนังสือขาวถ่างระยะ (= `.welbadge`/`.sc-brand`)
struct PKStarBadge: View {
    var size: CGFloat = 11

    var body: some View {
        Text("✦ SALE HERE STAR")
            .font(.sh(size, .bold)).tracking(1.6)
            .lineLimit(1).fixedSize()   // ป้ายห้ามหักบรรทัด — ของรอบข้างต้องหลบให้
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(Capsule().fill(PK.red))
    }
}

struct PKStatusPill: View {
    let text: String
    var color: Color = PK.muted
    var symbol: Ph? = nil
    /// พื้นทึบตัวขาว — ใช้กับสถานะที่ต้องเห็นจากไกล ("ครบแล้ว")
    var solid = false

    var body: some View {
        HStack(spacing: 5) {
            if let symbol { PIcon(symbol, size: 10) }
            Text(text).font(.sh(11.5, .bold))
        }
        .foregroundStyle(solid ? .white : color)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(solid ? color : color.opacity(0.11)))
        .overlay(Capsule().strokeBorder(color.opacity(solid ? 0 : 0.28), lineWidth: 0.8))
        .lineLimit(1).fixedSize()
    }
}

/// ติ๊กถูกของส่วนที่ครบแล้ว — วงกลมเขียวทึบ ถูกขาวอยู่ข้างใน (เห็นจากหางตาว่าผ่านแล้ว ไม่ต้องอ่าน)
struct PKDoneDot: View {
    var size: CGFloat = 19

    var body: some View {
        Circle().fill(PK.ok)
            .frame(width: size, height: size)
            .overlay(PIcon(.check, size: size * 0.55, weight: .bold).foregroundStyle(.white))
            .accessibilityLabel("ครบแล้ว")
    }
}

/// ค่าที่กรอกไว้ของแถวหนึ่ง — ป้ายชิ้นละค่า ไม่ใช่ประโยคยาวคั่นด้วยจุด
///
/// ตาจับ "ก้อน" ได้เร็วกว่าคำในประโยค — เห็นปุ๊บรู้ว่ามีกี่ค่าและค่าอะไรบ้าง โดยไม่ต้องไล่อ่าน
/// เกิน `max` ป้ายบอกจำนวนที่เหลือแทน เพื่อให้ทุกแถวสูงเท่ากันและไม่มีป้ายไหนโดนตัดครึ่ง
struct PKFactStrip: View {
    let facts: [String]
    var max = 3

    var body: some View {
        let shown = facts.prefix(max)
        let rest = facts.count - shown.count
        HStack(spacing: 3) {
            ForEach(Array(shown.enumerated()), id: \.offset) { _, f in
                Text(f)
                    .font(.sh(10.5, .medium)).foregroundStyle(PK.ink.opacity(0.66))
                    // ป้ายสุดท้ายยาวกว่าที่เหลือได้เสมอ — ย่อตัวอักษรนิดเดียวดีกว่าตัดคำทิ้ง
                    .lineLimit(1).minimumScaleFactor(0.8)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(PK.ink.opacity(0.05)))
            }
            if rest > 0 {
                Text("+\(rest)")
                    .font(.sh(10, .bold)).foregroundStyle(PK.hint)
                    .fixedSize()
            }
        }
    }
}

/// แถวในรายการ — กดแล้วพื้นเข้มขึ้นทั้งแถวแบบ list ของ iOS
/// (`DockPress` ย่อทั้งแถว ซึ่งกับแถวกว้างเต็มการ์ดจะเห็นขอบขยับจนดูพัง)
struct PKRowPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(PK.ink.opacity(configuration.isPressed ? 0.055 : 0))
            .animation(Motion.snap, value: configuration.isPressed)
    }
}

/// กดบนชิ้นมืด — หรี่ลงนิดเดียว (ย่อขนาดทั้งบัตรกว้างเต็มจอดูเหมือนพัง · สีหมึกทับพื้นดำมองไม่เห็น)
struct PKDimPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(Motion.snap, value: configuration.isPressed)
    }
}

/// สรุปสิ่งที่ยังขาด — ขึ้นเหนือปุ่มถัดไปเมื่อกดแล้วไม่ผ่าน · แตะบรรทัดไหนเลื่อนไปช่องนั้น
struct PKIssueBox: View {
    let issues: [ProfileIssue]
    var onTap: (ProfileIssue) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                PIcon(.warning, size: 12, weight: .fill)
                Text("ยังขาดอีก \(issues.count) อย่าง").font(.sh(13, .bold))
            }
            .foregroundStyle(PK.red)
            ForEach(issues) { i in
                Button { onTap(i) } label: {
                    HStack(spacing: 6) {
                        Text("·").font(.sh(12.5, .bold))
                        Text(i.message).font(.sh(12.5, .medium)).multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        PIcon(.arrowUpRight, size: 10)
                    }
                    .foregroundStyle(PK.redDark)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PK.shape(14).fill(PK.redTint))
        .overlay(PK.shape(14).strokeBorder(PK.redTint2, lineWidth: 1))
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

/// ข้อความช่วยสั้น ๆ — พื้นครีม ไอคอนแดงนำหน้า (= `.autonote`/`.note` ของเว็บ)
struct PKNote: View {
    let text: String
    var symbol: Ph = .info
    var color: Color = PK.muted

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            PIcon(symbol, size: 13)
                .foregroundStyle(color)
                .padding(.top, 1)
            Text(text).font(.sh(12.5, .medium)).foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PK.shape(14).fill(PK.fieldFill))
    }
}

// MARK: - หัวจอ + ขั้นตอน

/// หัวจอของหน้าในกลุ่มนี้ — ปุ่มซ้าย · ชื่อกลาง · ปุ่มขวา (ว่างได้)
struct PKHeader: View {
    let title: String
    var subtitle: String? = nil
    var leftSymbol: Ph = .caretLeft
    var leftLabel = "กลับ"
    let onLeft: () -> Void
    var right: AnyView? = nil

    var body: some View {
        HStack(spacing: 10) {
            PKCircleButton(symbol: leftSymbol, label: leftLabel, action: onLeft)
            Spacer(minLength: 4)
            VStack(spacing: 1) {
                Text(title).font(.sh(17, .bold)).foregroundStyle(PK.ink).lineLimit(1)
                if let subtitle {
                    Text(subtitle).font(.sh(12, .medium)).foregroundStyle(PK.muted).lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            if let right { right } else { Color.clear.frame(width: 40, height: 40) }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
}

/// แถบขั้นแบบสะสมตรา (ผู้ใช้เลือก 19 ก.ย. จาก prototype 3 แบบ · "Stamp Row")
///
/// หนึ่งเหรียญ = หนึ่งส่วน ร้อยด้วยเส้นเดียว · เส้นเข้มถึงเหรียญที่อยู่ = เดินมาถึงไหนแล้ว
/// เหรียญที่อยู่ใหญ่กว่านิด มีวงรอบค่อย ๆ ปิดตามที่กรอกจริง (ไม่เคยว่าง — endowed progress)
/// ครบส่วนไหน = เหรียญนั้น "ประทับตรา": พื้นเข้ม ไอคอนขาว เด้งเอียงแบบปั๊มตรา + ติ๊กเขียวมุมล่าง
/// แตะเหรียญเพื่อกระโดดไปส่วนนั้น — แผนที่ที่ใช้ได้จริง ไม่ใช่แค่ให้ดู
struct PKStampRow: View {
    let current: Int
    /// 0…1 ต่อส่วน
    let fill: [CGFloat]
    let icons: [Ph]
    let titles: [String]
    /// เพิ่มขึ้นทุกครั้งที่กด "ถัดไป" ทั้งที่ยังไม่ครบ — เหรียญที่อยู่ส่ายหัว
    var nudge: Int = 0
    var onTap: (Int) -> Void = { _ in }

    @State private var stamps: [Int: Int] = [:]
    @State private var shakes: [Int: Int] = [:]

    private let coin: CGFloat = 32

    var body: some View {
        GeometryReader { g in
            let n = max(fill.count, 2)
            // เผื่อวงรอบของเหรียญที่อยู่ (ใหญ่ขึ้น 1.14 เท่า) ไม่ให้ล้นขอบ
            let inset = (coin + 8) * 1.14 / 2 + 1
            let span = g.size.width - inset * 2
            let x = { (i: Int) in inset + span * CGFloat(i) / CGFloat(n - 1) }
            ZStack(alignment: .topLeading) {
                Capsule().fill(PK.line)
                    .frame(width: span, height: 2)
                    .position(x: g.size.width / 2, y: g.size.height / 2)
                Capsule().fill(PK.charcoal)
                    .frame(width: span * CGFloat(current) / CGFloat(n - 1), height: 2)
                    .position(x: inset + span * CGFloat(current) / CGFloat(n - 1) / 2, y: g.size.height / 2)
                ForEach(fill.indices, id: \.self) { i in
                    stamp(i).position(x: x(i), y: g.size.height / 2)
                }
            }
        }
        .frame(height: 44)
        .animation(.spring(response: 0.45, dampingFraction: 0.62), value: fill)
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: current)
        .onChange(of: current) { _, _ in Haptics.impact(.soft) }
        .onChange(of: nudge) { _, _ in shakes[current, default: 0] += 1 }
        .onChange(of: fill) { old, new in
            guard old.count == new.count else { return }
            if let i = new.indices.first(where: { new[$0] >= 1 && old[$0] < 1 }) {
                stamps[i, default: 0] += 1
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else if new.indices.contains(where: { new[$0] > old[$0] }) {
                UISelectionFeedbackGenerator().selectionChanged()
            }
        }
    }

    private func stamp(_ i: Int) -> some View {
        let here = i == current
        let done = fill[i] >= 1
        return Button { if !here { onTap(i) } } label: {
            ZStack {
                // วงรอบกว้างกว่าเหรียญ — ล็อกขนาดเหรียญไว้ ไม่ให้ ZStack ขยายพื้นตามวง
                Circle().fill(done ? PK.charcoal : Color.white)
                    .frame(width: coin, height: coin)
                if !done && !here {
                    Circle().strokeBorder(PK.line, lineWidth: 1.5)
                        .frame(width: coin, height: coin)
                }
                PIcon(icons[i], size: 15, weight: done || here ? .bold : .regular)
                    .foregroundStyle(done ? Color.white : here ? PK.ink : PK.ink.opacity(0.36))
                if here {
                    // วงรอบบอก "ส่วนนี้กรอกไปเท่าไหร่" — ปิดวงเมื่อครบ
                    Circle().stroke(PK.ink.opacity(0.08), lineWidth: 2.5)
                        .frame(width: coin + 8, height: coin + 8)
                    Circle().trim(from: 0, to: max(0.06, min(1, fill[i])))
                        .stroke(PK.charcoal, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: coin + 8, height: coin + 8)
                }
            }
            .frame(width: coin, height: coin)
            .overlay(alignment: .bottomTrailing) {
                // เขียว = ครบ ความหมายเดียวกับจุดเขียวบน hub
                Circle().fill(PK.ok)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                    .overlay(PIcon(.check, size: 7.5, weight: .bold).foregroundStyle(.white))
                    .frame(width: 14, height: 14)
                    .offset(x: here ? 6 : 3, y: here ? 6 : 3)
                    .scaleEffect(done ? 1 : 0.01)
                    .opacity(done ? 1 : 0)
            }
            .scaleEffect(here ? 1.14 : 1)
            // ปั๊มตรา: พุ่งขึ้น เอียง แล้วกดลง
            .keyframeAnimator(initialValue: StampPose(), trigger: stamps[i] ?? 0) { v, p in
                v.scaleEffect(p.scale).rotationEffect(.degrees(p.tilt))
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.3, duration: 0.18)
                    SpringKeyframe(0.94, duration: 0.14)
                    SpringKeyframe(1, duration: 0.3)
                }
                KeyframeTrack(\.tilt) {
                    CubicKeyframe(-10, duration: 0.18)
                    CubicKeyframe(3, duration: 0.14)
                    CubicKeyframe(0, duration: 0.2)
                }
            }
            .keyframeAnimator(initialValue: CGFloat(0), trigger: shakes[i] ?? 0) { v, dx in
                v.offset(x: dx)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(-5, duration: 0.07)
                    CubicKeyframe(5, duration: 0.07)
                    CubicKeyframe(-3, duration: 0.07)
                    CubicKeyframe(3, duration: 0.07)
                    CubicKeyframe(0, duration: 0.07)
                }
            }
            .frame(width: coin + 12, height: coin + 12)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(titles[i])
        .accessibilityValue(done ? "ครบแล้ว" : here ? "ส่วนที่กำลังกรอก" : "")
    }
}

private struct StampPose {
    var scale: CGFloat = 1
    var tilt: Double = 0
}

// MARK: - จัดชิปหลายบรรทัด

/// เรียงของหลายชิ้นซ้ายไปขวา ล้นแล้วขึ้นบรรทัดใหม่ — ใช้กับกลุ่มชิป
struct PKWrap: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0, x + sz.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
        return CGSize(width: width == .infinity ? x : width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > bounds.minX, x + sz.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
    }
}

// MARK: - ของเล่น Gen Z

/// อีโมจิลอยขึ้นลงช้า ๆ — สำเนาของ `.f3d` บนหน้าต้อนรับของเว็บ
struct PKFloatingEmoji: View {
    let emoji: String
    var size: CGFloat = 38
    var duration: Double = 6
    var delay: Double = 0
    var tilt: Double = -8

    @State private var up = false

    var body: some View {
        Text(emoji)
            .font(.system(size: size))
            .rotationEffect(.degrees(up ? tilt : -tilt))
            .offset(y: up ? -9 : 9)
            .shadow(color: .black.opacity(0.08), radius: 6, y: 6)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(delay)) {
                    up = true
                }
            }
    }
}

// MARK: - คีย์บอร์ด

/// รู้ว่าคีย์บอร์ดขึ้นอยู่ไหม — แถบปุ่มล่างต้องหลบ ไม่งั้นมันทับช่องที่กำลังพิมพ์
struct KeyboardWatcher: ViewModifier {
    @Binding var visible: Bool

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation(Motion.snap) { visible = true }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(Motion.snap) { visible = false }
            }
    }
}

// MARK: - สีประจำส่วน

extension ProfileSection {
    /// พาสเทลของช่องนี้บน quest board — จำได้ด้วยสีก่อนอ่านชื่อ
    var tint: Color {
        switch self {
        case .channels:  return PK.lavender
        case .interests: return PK.mint
        case .payment:   return PK.lemon
        case .terms:     return PK.aqua
        case .person:    return PK.peach
        case .consent:   return PK.sand
        }
    }

    var emoji: String {
        // อีโมจิ = `emo` ของฟอร์มเว็บ
        switch self {
        case .channels:  return "📱"
        case .interests: return "✨"
        case .payment:   return "💸"
        case .terms:     return "🗓️"
        case .person:    return "🙌"
        case .consent:   return "🔒"
        }
    }
}

/// วงแหวนความคืบหน้า — ตัวเลขตรงกลาง · ครบแล้วเป็นทอง
struct PKRing: View {
    let done: Int
    let total: Int
    var size: CGFloat = 64

    private var frac: CGFloat { total == 0 ? 0 : CGFloat(done) / CGFloat(total) }
    private var complete: Bool { done >= total && total > 0 }

    var body: some View {
        // หมึกล้วน — เขียวสงวนไว้ให้ป้าย "ครบแล้ว" ป้ายเดียว
        ZStack {
            Circle().stroke(PK.ink.opacity(0.08), lineWidth: 6)
            Circle()
                .trim(from: 0, to: frac)
                .stroke(PK.ink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Motion.settle, value: frac)
            if complete {
                PIcon(.check, size: size * 0.34).foregroundStyle(PK.ink)
            } else {
                Text("\(done)/\(total)").font(.sh(size * 0.24, .black)).foregroundStyle(PK.ink)
            }
        }
        .frame(width: size, height: size)
    }
}


// MARK: - พื้นผิวนุ่ม (ขาวลอย · เงาฟุ้ง · ขอบแสง)

/// การ์ดขาวลอยบนเวทีสว่าง — ไม่มีเส้นขอบเทา ใช้เงาฟุ้งกับขอบแสงขาวแยกตัวแทน
/// `tint` = ส่วนที่ยังขาด: พื้นขาวอาบสีจาง ๆ ขอบสีเดียวกัน (ยังเห็นจากหางตาว่าต้องไปเติม)
struct PKSoftCard: View {
    var radius: CGFloat = 22
    var tint: Color? = nil

    var body: some View {
        let shape = PK.shape(radius)
        shape.fill(PK.card)
            .shadow(color: PK.shadow, radius: 14, y: 5)
            .overlay { if let tint { shape.fill(tint.opacity(0.08)) } }
            .overlay { if let tint { shape.strokeBorder(tint.opacity(0.5), lineWidth: 1.2) } }
    }
}

/// ไอคอนในวงกลมพื้นจาง
struct PKSoftIcon: View {
    var tint: Color? = nil

    var body: some View {
        // แบนราบ ไม่มีเงา/ขอบ — ในแถวมีของหลายชิ้นอยู่แล้ว ไอคอนนูนอีกชั้นทำให้ทั้งแถวดูรก
        Circle().fill(tint.map { $0.opacity(0.14) } ?? PK.ink.opacity(0.045))
    }
}

/// พื้นบัตร STAR — เหลืองเนยโฮโลแบบ Y2K + **ดาวดวงโต** ไหลพ้นขอบขวา + ประกายเล็ก ๆ
///
/// พื้นหลังต้องบอกเองว่า "นี่คือ STAR" ด้วยดาว ไม่ใช่โลโก้ (ผู้ใช้ 19 ก.ย.: เอาแค่ไอคอนดาว)
/// โทนเหลืองเสมอ (สีของ STAR) แต่ไม่ใช่ทองอิ่มทั้งแผ่น — เนย · เลมอน · พีช · ไลม์จาง ไล่กันแบบโฮโล
struct PKWarmMesh: View {
    var body: some View {
        ZStack {
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.45], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ], colors: [
                Color(red: 1.00, green: 0.91, blue: 0.55), Color(red: 1.00, green: 0.95, blue: 0.68), Color(red: 1.00, green: 0.88, blue: 0.70),
                Color(red: 0.97, green: 0.98, blue: 0.72), Color(red: 1.00, green: 0.97, blue: 0.80), Color(red: 1.00, green: 0.90, blue: 0.62),
                Color(red: 1.00, green: 0.96, blue: 0.84), Color(red: 1.00, green: 0.93, blue: 0.66), Color(red: 1.00, green: 0.84, blue: 0.58),
            ])
            GeometryReader { g in
                let h = g.size.height * 1.15
                // ดาวดวงโต — เนยไล่ชมพู มีแสงขาวด้านบนให้ดูมันวาวเหมือนสติกเกอร์
                PIcon(.star, size: h, weight: .fill)
                    .foregroundStyle(LinearGradient(colors: [Color(red: 1.0, green: 0.88, blue: 0.30),
                                                             Color(red: 1.0, green: 0.66, blue: 0.20)],
                                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        PIcon(.star, size: h, weight: .fill)
                            .foregroundStyle(LinearGradient(colors: [.white.opacity(0.55), .clear],
                                                            startPoint: .top, endPoint: .center))
                    )
                    .shadow(color: Color(red: 1.0, green: 0.62, blue: 0.10).opacity(0.35), radius: 14, y: 6)
                    .rotationEffect(.degrees(14))
                    .position(x: g.size.width - h * 0.36, y: g.size.height * 0.58)

                // ประกายเล็ก ๆ
                sparkle(14).position(x: g.size.width * 0.56, y: g.size.height * 0.22)
                sparkle(9).position(x: g.size.width * 0.66, y: g.size.height * 0.80)
                sparkle(7).position(x: g.size.width * 0.52, y: g.size.height * 0.62)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func sparkle(_ size: CGFloat) -> some View {
        PIcon(.sparkle, size: size, weight: .fill)
            .foregroundStyle(.white)
            .shadow(color: Color(red: 1.0, green: 0.70, blue: 0.20).opacity(0.7), radius: 3)
    }
}

/// พื้นของแผ่น/การ์ดในฟอร์ม — ขาวลอยบนกระดาษครีมด้วยเงาอุ่นจาง ไม่มีขอบ ไม่มีกระจก
struct PKSurface: View {
    var radius: CGFloat = PK.radius

    var body: some View {
        // ม่านดำบางใต้กระจก (แบบ `GlassPanel` บนการ์ดมืด) ให้ตัวหนังสือขาวอ่านได้ทุกฉากหลัง
        PK.shape(radius).fill(PK.card)
            .overlay(PK.shape(radius).strokeBorder(PK.line, lineWidth: 1))
            .shadow(color: PK.shadow, radius: 3, y: 1)
    }
}
