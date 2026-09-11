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
///
/// # ทำไมต้องมีโลโก้ ไม่ใช่แค่ตราถูก
///
/// คำว่า "ยืนยัน" เฉย ๆ เป็นคำที่ใครก็พิมพ์ใส่ media kit ของตัวเองได้ — ป้ายที่ไม่บอกว่า
/// *ใครเป็นคนยืนยัน* จึงไม่ได้เพิ่มความน่าเชื่อเลย มันแค่เพิ่มคำโฆษณาอีกคำ
/// ป้ายนี้ต้องอ่านออกมาเป็น **ใบรับรองที่มีคนออกให้** ซึ่งแปลว่าต้องมีสองอย่าง:
/// ชื่อผู้ออก (โลโก้จริง คงสีแบรนด์ ไม่ย้อมตามธีม) และประโยคที่บอกความสัมพันธ์ (Verified by)
///
/// โลโก้คงสีต้นฉบับเสมอ — ตราที่เปลี่ยนสีตามการ์ดที่มันรับรองอยู่ ไม่ใช่ตรา แต่เป็นของตกแต่ง
struct VerifiedBadge: View {
    @Environment(\.cardInk) private var ink

    var body: some View {
        // ตราปิดท้ายบรรทัด ไม่ใช่นำหน้า — ประโยคอ่านจบแล้วสายตาไปหยุดที่ *ใครเป็นคนยืนยัน*
        // ซึ่งคือข้อมูลที่มีค่าที่สุดในป้ายนี้ ถ้าเอาตราขึ้นก่อน มันกลายเป็นแค่ไอคอนนำบรรทัด
        HStack(spacing: 5) {
            Text("Verified by")
                .font(.sh(8, .semibold))
                .lineLimit(1).fixedSize()
            SaleHereMark(size: 14)
        }
        .foregroundStyle(ink.text(0.92))
        .fixedSize()
        .padding(.leading, 8).padding(.trailing, 4).padding(.vertical, 3)
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
/// # ประวัติของบรรทัดนี้ อ่านก่อนแก้
///
/// รอบแรกเป็นตัวจิ๋วจาง ๆ แบบ caption → อ่านออกมาเป็น "ป้ายกำกับ" ไม่ใช่หัวข้อ
/// รอบสองเติมแถบสีธีมตั้งนำหน้า + ตัวหนา 15pt → แก้เรื่องน้ำหนักได้ แต่ได้ปัญหาใหม่:
/// **แถบตั้ง + ตัวหนา คือหน้าตาของ section header ในหน้าฟอร์ม** การ์ดทั้งใบเลยอ่านเป็นแบบฟอร์ม
///
/// รอบนี้เปลี่ยน *อุปกรณ์* ไม่ใช่เปลี่ยน *น้ำหนัก* — ทิ้งแถบตั้ง แล้วให้เส้นไหลจากท้ายคำ
/// ไปจนสุดขอบแทน ซึ่งเป็นท่าของหัวเรื่องในนิตยสาร ไม่ใช่ของฟอร์ม
/// เส้นทำสองหน้าที่พร้อมกัน: บอกว่าหัวข้อจบตรงไหน และพาสายตาไปหาป้ายท้ายบรรทัด
///
/// ขนาดลดจาก 15 เหลือ 13.5 เพราะหัวข้อคือ *บริบท* ไม่ใช่ *เนื้อหา* —
/// ของที่ควรดังที่สุดใน widget คือตัวเลขกับรูป ไม่ใช่คำว่า "ผลงานที่ยืนยันแล้ว"
///
/// (ไม่ uppercase เพราะภาษาไทยไม่มีตัวใหญ่ สั่งไปก็ได้แค่ตัวโรมันที่ปนอยู่กลายเป็นตัวใหญ่ตัวเดียว)
struct WidgetLabel: View {
    let text: String
    var trailing: AnyView? = nil

    @Environment(\.cardAccent) private var accent
    @Environment(\.cardInk) private var ink

    var body: some View {
        HStack(spacing: 10) {
            Text(text)
                .font(.sh(13.5, .bold))
                .foregroundStyle(ink.text(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)

            // เส้นไหลจากท้ายคำไปจนสุด — ไล่จางออกไป ไม่ใช่เส้นทึบยาวเท่ากันตลอด
            // เส้นทึบเสมอกันจะอ่านเป็น "ช่องกรอกที่ยังว่าง" ซึ่งคือสิ่งที่พยายามหนีอยู่พอดี
            Rectangle()
                .fill(LinearGradient(colors: [ink.line(0.2), ink.line(0.04)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 0.8)
                .frame(maxWidth: .infinity)

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
