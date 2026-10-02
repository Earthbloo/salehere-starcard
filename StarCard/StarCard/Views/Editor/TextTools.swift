import SwiftUI

// MARK: - โหมดพิมพ์ข้อความ — ท่าเดียวกับ Instagram Story
//
// ครีเอเตอร์ทุกคนมีมือจำท่านี้อยู่แล้ว จึงไม่ประดิษฐ์อะไรเพิ่ม:
//
// * **พิมพ์บนการ์ดตรง ๆ** — เคอร์เซอร์อยู่ที่ตัวอักษรบนการ์ด ไม่มีช่องกรอกแยกอีกช่อง (ดู `CanvasTextField`)
// * เหนือแป้นพิมพ์มีสองแถว: **ชื่อฟอนต์ที่เขียนด้วยฟอนต์นั้น** กับ **แถวไอคอน** (ฟอนต์ · สี · จัดวาง · ลบ)
// * **ไม่มีปุ่มขนาด** — ขนาดปรับที่หมุดมุมของกล่องบนการ์ด (ลากออกโต ลากเข้าเล็ก) กล่องคือตัวอักษรพอดีเสมอ
// * แตะไอคอนสีแล้วแถวบนกลายเป็นวงสี แตะ Aa กลับมาเป็นฟอนต์ — แป้นพิมพ์ไม่หุบ
// * **เสร็จ** อยู่มุมขวาบน · แตะที่ว่างบนการ์ดก็เสร็จเหมือนกัน · ก้อนที่ว่างเปล่าตอนเสร็จหายไปเอง

/// สองแถวเหนือแป้นพิมพ์ — ไม่มีช่องกรอก ตัวอักษรอยู่บนการ์ด
struct TextTools: View {
    let theme: CardTheme
    let style: WidgetTextStyle
    let onStyle: ((inout WidgetTextStyle) -> Void) -> Void
    let onDelete: () -> Void

    private enum Row { case font, color }
    @State private var row: Row = .font

    var body: some View {
        VStack(spacing: 10) {
            if row == .font {
                FontCarousel(selection: style.face) { f in onStyle { $0.face = f } }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TextTint.allCases) { t in
                            TintChip(tint: t, on: style.tint == t, accent: theme.rawAccent) {
                                onStyle { $0.tint = t }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 44)
            }

            HStack(spacing: 4) {
                tool("textformat", on: row == .font, label: "ฟอนต์") { row = .font }
                Button {
                    row = .color
                    Haptics.impact(.light)
                } label: {
                    Circle()
                        .fill(AngularGradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                                              center: .center))
                        .frame(width: 22, height: 22)
                        .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1.5))
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(row == .color ? 0.22 : 0)))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("สีตัวอักษร")

                TextAlignButton(align: style.align) { a in onStyle { $0.align = a } }

                Spacer(minLength: 0)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 1, green: 0.5, blue: 0.45))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(DockPress())
                .accessibilityLabel("ลบข้อความ")
            }
            .padding(.horizontal, 6)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.1)))
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 8)
        .environment(\.colorScheme, .dark)
        .animation(Motion.snap, value: row == .font)
    }

    /// ไอคอนหนึ่งช่องในแถวเครื่องมือ — ช่องที่ทำงานอยู่ได้พื้นสว่างเหมือน IG
    private func tool(_ symbol: String, on: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.impact(.light)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(on ? Color.black.opacity(0.85) : Color.white.opacity(0.9))
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(on ? 0.9 : 0)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - ช่องพิมพ์บนการ์ด

/// ช่องพิมพ์ที่นั่งทับตำแหน่งของก้อนข้อความบนการ์ดพอดี — ฟอนต์ สี การจัดวาง ตรงกับก้อนจริงทุกค่า
///
/// ตัวอักษรของก้อนถูกซ่อนระหว่างพิมพ์ (ดู `TextBlock` กับ `canvasTyping`) ช่องนี้จึง *คือ* ตัวอักษร
/// ไม่ใช่ตัวอย่างที่วิ่งตามช่องกรอกที่อื่น · ก้อนถูกยกขึ้นกลางที่ว่างเหนือแป้นพิมพ์ (ดู `showroom`)
///
/// ขนาดตัวอักษรตอนพิมพ์คือ **ขนาดแก้ไขมาตรฐาน** เท่ากันทุกก้อน (ดู `editBox`) ไม่ใช่ขนาดบนการ์ด
/// ไม่ตัดบรรทัดเอง — Return เท่านั้นที่ขึ้นบรรทัดใหม่ · กล่องรอบตัวโตตามที่พิมพ์
///
/// # ทำไมเป็น `UITextView` ไม่ใช่ `TextField`
///
/// `TextField` มีขอบในของตัวเองราว 5pt ต่อข้าง และตัดบรรทัดเองเมื่อชนขอบ — คุมไม่ได้ทั้งสองอย่าง
/// `UITextView` ตั้งขอบในเป็นศูนย์ได้ สั่งไม่ตัดบรรทัดได้ และวางบรรทัดด้วย TextKit ตัวเดียวกับที่ใช้วัด
struct CanvasTextField: View {
    let id: TextSlotID
    let style: WidgetTextStyle
    let ink: InkStyle
    let accent: Color
    /// ขนาดตัวอักษรตอนพิมพ์ — คิดมาแล้วจากชั้นการ์ด (ขนาดแก้ไขมาตรฐาน หดเมื่อบรรทัดยาวเกินหน้า)
    let size: CGFloat
    /// ก้อนนี้ **บนการ์ด** ใหญ่พอให้ใช้เกณฑ์ตัวใหญ่ไหม — ไม่ใช่ขนาดตอนพิมพ์ (ซึ่งเท่ากันทุกก้อน)
    /// สีตอนพิมพ์ต้องเป็นสีเดียวกับที่จะกลับไปวางบนการ์ด ไม่งั้นกด เสร็จ แล้วสีกระตุก
    var large: Bool = true

    private var color: Color { style.tint.color(ink: ink, accent: accent, large: large) }
    private var halo: Color? { style.tint.halo(ink: ink, large: large) }

    /// ประโยคชวนพิมพ์บนการ์ดไม่ใช่ข้อความของผู้ใช้ — ช่องพิมพ์ต้องเห็นเป็นช่องว่าง
    private var raw: String {
        let v = Profile.me.text(id)
        return v == Profile.notePlaceholder ? "" : v
    }

    var body: some View {
        FitTextView(id: id, text: raw,
                    font: style.face.uiFont(size, TextBlock.weight),
                    lineSpacing: size * TextFit.spacing,
                    align: style.align.ns,
                    color: UIColor(color), tint: UIColor(accent),
                    halo: halo.map { UIColor($0) })
            .overlay {
                if raw.isEmpty {
                    Text("พิมพ์ข้อความ")
                        .font(style.face.font(size, TextBlock.weight))
                        .foregroundStyle(color.opacity(0.45))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .allowsHitTesting(false)
                }
            }
    }
}

/// `UITextView` ที่ไม่มีขอบใน ไม่เลื่อน และจัดข้อความไว้กลางแนวตั้งของกล่อง
private struct FitTextView: UIViewRepresentable {
    let id: TextSlotID
    let text: String
    let font: UIFont
    let lineSpacing: CGFloat
    let align: NSTextAlignment
    let color: UIColor
    let tint: UIColor
    /// เงากันจมของตัวอักษรบนรูป — สีเดียวกับที่การ์ดวาด (ดู `legibilityHalo`) ช่องพิมพ์จึงอ่านออกเท่ากัน
    var halo: UIColor? = nil

    func makeUIView(context: Context) -> FocusTextView {
        let v = FocusTextView()
        v.backgroundColor = .clear
        v.isScrollEnabled = false
        v.textContainerInset = .zero
        v.textContainer.lineFragmentPadding = 0
        // ไม่ตัดบรรทัดเอง — กล่องกว้างเท่าบรรทัดที่ยาวที่สุดอยู่แล้ว (ดู `fitTextBlock`) ที่เหลือคือกันเศษพิกเซล
        v.textContainer.lineBreakMode = .byClipping
        v.autocorrectionType = .no
        v.autocapitalizationType = .sentences
        v.keyboardAppearance = .dark
        v.delegate = context.coordinator
        v.text = text
        apply(to: v)
        // โฟกัสตอนช่องเข้าหน้าต่างแล้ว (ดู `FocusTextView.didMoveToWindow`) — สั่งตรงนี้จะไม่ติด
        // เพราะ SwiftUI ยังไม่ได้แปะ view ลงลำดับชั้น และ `async` ก็ไม่รับประกันว่าแปะแล้ว
        v.wantsFocus = true
        return v
    }

    func updateUIView(_ v: FocusTextView, context: Context) {
        context.coordinator.parent = self
        if v.text != text { v.text = text }
        apply(to: v)
    }

    /// ฟอนต์เปลี่ยนทุกตัวอักษรที่พิมพ์ (ขนาดคิดจากกล่อง) — ต้องเขียนทับทั้งก้อน ไม่ใช่แค่ตัวถัดไป
    private func apply(to v: FocusTextView) {
        let para = NSMutableParagraphStyle()
        para.lineSpacing = lineSpacing
        para.alignment = align
        // ย่อหน้าตัดสินการตัดบรรทัดก่อน container — ไม่ตั้งตรงนี้ด้วยจะกลับไปตัดคำเอง
        para.lineBreakMode = .byClipping
        var attrs: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: para, .foregroundColor: color]
        if let halo {
            // รัศมีชั้นนอกของ `legibilityHalo` — UIKit มีเงาได้ชั้นเดียว เอาชั้นที่กว้างกว่าไว้
            let shadow = NSShadow()
            shadow.shadowColor = halo
            shadow.shadowBlurRadius = max(2, font.pointSize * 0.14)
            shadow.shadowOffset = .zero
            attrs[.shadow] = shadow
        }
        v.typingAttributes = attrs
        // ระหว่างที่แป้นพิมพ์กำลังประกอบคำ (marked text) ห้ามแตะ storage — คำที่กำลังพิมพ์จะหลุด
        if v.markedTextRange == nil, v.textStorage.length > 0 {
            let sel = v.selectedRange
            v.textStorage.setAttributes(attrs, range: NSRange(location: 0, length: v.textStorage.length))
            v.selectedRange = sel
        }
        v.font = font
        v.textColor = color
        v.textAlignment = align
        v.tintColor = tint
        v.setNeedsLayout()
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: FitTextView
        init(_ parent: FitTextView) { self.parent = parent }
        func textViewDidChange(_ tv: UITextView) {
            // เขียนลง `Profile` (observable) — กล่องรอบตัวอ่านค่านี้แล้วโตตามเอง (ดู `editBox`)
            Profile.me.set(parent.id, tv.text)
        }
    }
}

/// `UITextView` ที่ขอแป้นพิมพ์เองเมื่อได้อยู่ในหน้าต่าง
///
/// ไม่จัดกลางแนวตั้งเอง — กรอบของมันเท่า line box พอดีอยู่แล้ว (ดู `canvasEditor`)
/// ขยับข้อความเองแม้ครึ่งพอยต์ หมึกจะไม่ตรงกับตำแหน่งที่ตัวอักษรบนการ์ดจะกลับไปนั่ง
final class FocusTextView: UITextView {
    /// ขอแป้นพิมพ์ทันทีที่ได้อยู่ในหน้าต่าง — `becomeFirstResponder` ก่อนหน้านั้นคืน false เงียบ ๆ
    var wantsFocus = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, wantsFocus else { return }
        wantsFocus = false
        becomeFirstResponder()
    }
}

private struct CanvasTypingKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// ก้อนข้อความนี้กำลังถูกพิมพ์บนการ์ดอยู่ — ตัวอักษรของก้อนต้องหลบให้ช่องพิมพ์ที่ทับอยู่
    var canvasTyping: Bool {
        get { self[CanvasTypingKey.self] }
        set { self[CanvasTypingKey.self] = newValue }
    }
}

// MARK: - ชิ้นส่วน

/// แถวฟอนต์แบบ IG — **เลื่อนแล้วเปลี่ยนเลย** ตัวที่หยุดอยู่กลางจอคือตัวที่ใช้ ไม่ต้องแตะ
///
/// แถวเลื่อนแล้ว snap ทีละใบ ใบที่อยู่ตรงกลางถูกส่งออกไปเป็นฟอนต์ของก้อนทันทีระหว่างเลื่อน
/// ตัวอักษรบนการ์ดจึงเปลี่ยนตามนิ้ว — ไม่ใช่เลื่อนไปหา แล้วค่อยแตะเลือกอีกที
/// แตะใบไหนก็ได้เหมือนกัน: ใบนั้นเลื่อนมาอยู่กลางเอง
struct FontCarousel: View {
    let selection: CardFont
    let onPick: (CardFont) -> Void

    /// ใบที่อยู่กลางจอตอนนี้ — ตัวขับหลัก ทั้งจากการเลื่อนและจากการแตะ
    @State private var centered: CardFont?

    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CardFont.allCases) { f in
                        FontChip(font: f, on: f == selection) {
                            withAnimation(Motion.snap) { centered = f }
                        }
                        .id(f)
                    }
                }
                .scrollTargetLayout()
            }
            // เว้นขอบครึ่งจอ — ใบแรกกับใบสุดท้ายต้องมาอยู่กลางจอได้เหมือนใบอื่น
            .contentMargins(.horizontal, max(0, geo.size.width / 2 - 52), for: .scrollContent)
            .scrollTargetBehavior(.viewAligned(anchor: .center))
            .scrollPosition(id: $centered, anchor: .center)
            .onAppear { centered = selection }
            .onChange(of: centered) { _, f in
                if let f, f != selection { onPick(f) }
            }
            .onChange(of: selection) { _, f in
                if centered != f { withAnimation(Motion.snap) { centered = f } }
            }
        }
        .frame(height: 44)
    }
}

/// ชิปฟอนต์ — **ชื่อฟอนต์เขียนด้วยฟอนต์นั้นเอง** (Modern · Classic · Signature ของ IG)
/// ตัวที่เลือกเป็นพื้นขาวตัวดำ ที่เหลือโปร่งมีขอบบาง ๆ
struct FontChip: View {
    let font: CardFont
    let on: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
            Haptics.impact(.light)
        } label: {
            Text(font.name)
                .font(font.font(15, .semibold))
                .lineLimit(1)
                .foregroundStyle(on ? Color.black.opacity(0.88) : Color.white.opacity(0.92))
                .padding(.horizontal, 16)
                .frame(height: 38)
                .background(Capsule().fill(on ? Color.white.opacity(0.95) : Color.white.opacity(0.08)))
                .overlay(Capsule().strokeBorder(.white.opacity(on ? 0 : 0.22), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
        .animation(Motion.snap, value: on)
        .accessibilityLabel(font.name)
    }
}

/// วงสีตัวอักษร — สามตัวแรกไม่มีสีของตัวเอง (ตามการ์ด) จึงเป็นชิปมีชื่อ ที่เหลือเป็นวงสี
/// วงกลมขาวสองใบที่แปลว่าคนละอย่างเป็นตัวเลือกที่เดาไม่ออกว่าต่างกันตรงไหน
struct TintChip: View {
    let tint: TextTint
    let on: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
            Haptics.impact(.light)
        } label: {
            if tint == .ink || tint == .soft || tint == .accent {
                Text(tint.name).font(.sh(12, .semibold))
                    .foregroundStyle(on ? Color.black.opacity(0.88) : Color.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Capsule().fill(on ? Color.white.opacity(0.95) : Color.white.opacity(0.08)))
                    .overlay(Capsule().strokeBorder(.white.opacity(on ? 0 : 0.22), lineWidth: 0.8))
            } else {
                Circle()
                    .fill(tint.swatch(accent: accent))
                    .frame(width: 30, height: 30)
                    .overlay(Circle().strokeBorder(.white.opacity(on ? 1 : 0.35),
                                                   lineWidth: on ? 3 : 1))
                    .scaleEffect(on ? 1.1 : 1)
                    .frame(width: 38, height: 38)
            }
        }
        .buttonStyle(.plain)
        .animation(Motion.snap, value: on)
        .accessibilityLabel(tint.name)
    }
}

/// จัดวางวนสามแบบในไอคอนเดียว — ไอคอนคือสถานะปัจจุบัน (ท่าเดียวกับปุ่มจัดวางของ IG)
struct TextAlignButton: View {
    let align: TextAlign
    let onPick: (TextAlign) -> Void

    var body: some View {
        Button {
            let all = TextAlign.allCases
            let i = all.firstIndex(of: align) ?? 0
            onPick(all[(i + 1) % all.count])
            Haptics.impact(.light)
        } label: {
            Image(systemName: align.icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("จัดวาง \(align.name)")
    }
}
