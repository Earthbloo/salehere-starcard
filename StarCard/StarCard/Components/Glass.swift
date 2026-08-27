import SwiftUI

/// แผ่นกระจกมาตรฐานของการ์ด — Liquid Glass ของ iOS 26 ตรง ๆ ไม่แต่งหน้าทับ
///
/// เคยเติมเส้นไฮไลต์ขอบเอง แล้วพบว่ามันไปกลบ rim light จริงของระบบ
/// (ตัวที่วิ่งตามแสงและพื้นหลัง) จนกระจกอ่านเป็นแผ่นมีเส้นขอบแบน ๆ —
/// ของแท้ต้องปล่อยให้ระบบวาดขอบเอง แล้วให้กระจกอยู่ใน GlassEffectContainer
/// เดียวกันทั้งหน้าเพื่อให้ชิ้นที่ใกล้กันหลอมเชื่อมแบบ "liquid" จริง
struct GlassPanel<Content: View>: View {
    var tint: Color? = nil
    var tintStrength: Double = 0.16
    var radius: CGFloat = 28
    var interactive: Bool = false
    @ViewBuilder var content: Content

    @Environment(\.cardInk) private var ink

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            // ม่านบางใต้เนื้อหา — clear glass โปร่งจริงจนตัวหนังสือจมบนพื้นหลังสว่าง
            // ตามแนวทาง Apple: ใช้ clear เมื่อพื้นหลังเป็นสื่อ + เติม dimming layer เอง
            //
            // ฝั่งกระดาษกลับทิศ: ม่านต้องเป็น "ขาวขุ่น" ไม่ใช่ "ดำจาง" — กระจกฝ้าสีขาว
            // คือหน้าตาของ Liquid Glass บนพื้นสว่างจริง ๆ และเป็นตัวที่ทำให้การ์ดอ่านว่า "ใส"
            // ถ้าใช้ดำจางบนกระดาษ แผ่นจะกลายเป็นรอยเปื้อนเทาที่ดูสกปรก
            .background(shape.fill(ink.isLight ? Color.white.opacity(0.58) : Color.black.opacity(0.16)))
            .glassEffect(glass, in: shape)
            // พื้นมืดยกแผ่นด้วยแสง · พื้นสว่างยกแผ่นด้วยเงา
            .shadow(color: ink.lift, radius: ink.liftRadius, y: ink.isLight ? 6 : 0)
    }

    private var glass: Glass {
        // clear = ตัวโปร่งใสของ Liquid Glass — เห็นพื้นหลังหักเหทะลุจริง
        var g = Glass.clear
        if let tint { g = g.tint(tint.opacity(tintStrength)) }
        if interactive { g = g.interactive() }
        return g
    }
}

// MARK: - Typography

extension Font {
    /// ตัวเลขใหญ่ที่เป็นพระเอกของ widget สถิติ — ต้องเป็น rounded + width ตายตัว
    /// ไม่งั้นตัวเลขจะเต้นตอน sync ค่าใหม่
    static func statNumber(_ size: CGFloat) -> Font { .sh(size, .bold) }
    static func display(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font { .sh(size, weight) }
}

// MARK: - Small parts

/// ป้าย "ยืนยันโดย SaleHere" — ติดเฉพาะ widget ชั้นหลักฐาน
/// เป็นสิ่งเดียวที่ทำให้การ์ดใบนี้ต่างจาก media kit ทุกใบในตลาด
struct VerifiedBadge: View {
    @Environment(\.cardInk) private var ink

    var body: some View {
        HStack(spacing: 3) {
            SymbolIcon(name: SHIcon.sealCheck, size: 10, tint: ink.text(0.92))
            Text("ยืนยัน").font(.sh(8.5, .semibold))
                .lineLimit(1).fixedSize()
        }
        .foregroundStyle(ink.text(0.92))
        .fixedSize()
        .padding(.horizontal, 7).padding(.vertical, 3.5)
        .background(Capsule().fill(ink.fill(0.16)))
        .overlay(Capsule().strokeBorder(ink.line(0.22), lineWidth: 0.5))
    }
}

// MARK: - สีธีมที่ส่งผ่าน environment

/// สีเน้นของการ์ด — ส่งลงมาทาง environment เพื่อให้ชิ้นส่วนเล็ก ๆ (เช่นหัวข้อ)
/// ใช้สีธีมได้โดยไม่ต้องรับ `theme` เป็นพารามิเตอร์ทุกจุดเรียก
private struct CardAccentKey: EnvironmentKey {
    static let defaultValue = Color.white
}

extension EnvironmentValues {
    var cardAccent: Color {
        get { self[CardAccentKey.self] }
        set { self[CardAccentKey.self] = newValue }
    }
}

/// หัวข้อของ widget
///
/// เคยเป็นตัวจิ๋วจาง ๆ แบบ caption แล้วอ่านออกมาเป็น "ป้ายกำกับ" ไม่ใช่หัวข้อ
/// ตอนนี้มีแถบสีธีมนำหน้าเป็นเครื่องหมายประจำตัว + ตัวหนาขนาดอ่านได้จริง
/// และเลิก uppercase เพราะภาษาไทยไม่มีตัวใหญ่ — สั่งไปก็ได้แค่ตัวโรมันที่ปนอยู่
/// กลายเป็นตัวใหญ่ตัวเดียวจนบรรทัดดูไม่เข้ากัน
struct WidgetLabel: View {
    let text: String
    var trailing: AnyView? = nil

    @Environment(\.cardAccent) private var accent
    @Environment(\.cardInk) private var ink

    var body: some View {
        HStack(spacing: 9) {
            Capsule()
                .fill(LinearGradient(colors: [accent, accent.opacity(0.45)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 3, height: 15)
            Text(text)
                .font(.sh(15, .bold))
                .foregroundStyle(ink.text(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            if let trailing { trailing }
        }
    }
}

/// ตัวบอกความสด — "sync 2 ชม." คือจุดขายที่ PDF ทำไม่ได้
struct SyncDot: View {
    let ago: String
    @State private var pulse = false
    @Environment(\.cardInk) private var ink

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(ink.isLight ? Color(red: 0.10, green: 0.62, blue: 0.36)
                                  : Color(red: 0.35, green: 0.95, blue: 0.6))
                .frame(width: 5, height: 5)
                .scaleEffect(pulse ? 1.5 : 1)
                .opacity(pulse ? 0.4 : 1)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)
            Text("sync \(ago)")
                .font(.sh(9, .medium))
                .foregroundStyle(ink.text(0.42))
        }
        .onAppear { pulse = true }
    }
}
