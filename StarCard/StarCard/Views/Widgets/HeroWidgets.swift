import SwiftUI

// MARK: - Minimal (ชื่อตัวใหญ่ ไม่มีรูป)

/// # ท่าเปลี่ยนหน้า — "ตัวอักษรคลี่ออกจากกัน"
///
/// widget ตัวหนังสือล้วนไม่มีรูปให้ดอลลี่และไม่มีช่องให้หุบ ท่าจึงต้องอยู่ในตัวอักษรเอง:
/// **ระยะห่างตัวอักษร (tracking) คลายออกตามนิ้ว** ก่อนบรรทัดจะมุดใต้ขอบ
/// เป็นภาษา kinetic typography ตรง ๆ — ชื่อไม่ได้ถูกเลื่อนออกไป มันคลายตัวออกแล้วค่อยจากไป
struct HeroMinimal: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        // เทรนด์ 2026 · Oversized editorial type — ชื่อคือพระเอก ตัวหนาเต็มที่ ระยะตัวอักษรบีบ
        // คู่กับบรรทัดเล็กที่ปล่อย tracking กว้าง ให้คอนทราสต์ของ "ก้อนใหญ่ปะทะเส้นบาง"
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                ScrubReader(d: scrub.d) { d in
                    let t = Scrub.ease(Scrub.t(d, lead: 0.05))
                    Capsule().fill(theme.accent)
                        .frame(width: max(0, 14 * (1 - t)), height: 2)
                }
                .frame(width: 14, height: 2, alignment: .leading)
                Text("STARCARD")
                    .font(.sh(8.5, .bold)).tracking(2.6)
                    .foregroundStyle(theme.accent.opacity(0.92))
                    .scrubVeil(scrub.d, lead: 0.06, drop: 16, pull: 14)
            }

            ScrubReader(d: scrub.d) { d in
                let t = Scrub.ease(Scrub.t(d, lead: 0.1))
                Text(Mock.creator.name)
                    .font(.sh(size.width < 260 ? 30 : 40, .black))
                    // บีบอยู่ตอนนิ่ง แล้วคลายออกตอนจากไป
                    .tracking(-1 + 9 * t)
                    .foregroundStyle(ink.text(0.98))
                    .lineLimit(2).minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .scrubVeil(scrub.d, lead: 0.24, drop: 44, pull: 8)

            Text(Mock.creator.tagline.uppercased())
                .font(.sh(9.5, .semibold)).tracking(2)
                .foregroundStyle(ink.text(0.45)).lineLimit(1)
                .minimumScaleFactor(0.7)
                .scrubVeil(scrub.d, lead: 0.02, drop: 22, pull: 18)
        }
        // จัดกลางแนวตั้ง — ตอนถูกยืดสูงกว่าข้อความ ช่องว่างแบ่งบนล่างเท่ากัน ไม่กองอยู่ท้ายกล่อง
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
