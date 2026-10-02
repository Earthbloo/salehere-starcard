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

    private var nameSize: CGFloat { size.width < 260 ? 30 : 40 }

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
                // ชื่อโปรแกรมตัวจริง ไม่ใช่คำว่า STARCARD — บรรทัดนี้คือที่ที่การ์ดบอกว่าใครออกให้
                StarLockup(height: 12, tint: theme.accent.opacity(0.95))
                    .scrubVeil(scrub.d, lead: 0.06, drop: 16, pull: 14)

                // ตรายืนยันตัวตนติดมากับชื่อเสมอ ไม่ใช่ widget แยก
                // ตราที่ผู้ใช้เลือกวางเองได้ อ่านออกมาเป็นตราที่จัดฉากได้
                if Profile.me.creator.verified {
                    StarSeal(size: 11, tint: theme.accent.opacity(0.95))
                        .scrubVeil(scrub.d, lead: 0.04, drop: 14, pull: 10)
                }
            }

            ScrubReader(d: scrub.d) { d in
                let t = Scrub.ease(Scrub.t(d, lead: 0.1))
                Text(Profile.me.name)
                    // บีบอยู่ตอนนิ่ง แล้วคลายออกตอนจากไป
                    // ต้อง kerning ไม่ใช่ tracking — tracking แทรกช่องไฟ "หลังทุกตัวอักษร"
                    // รวมถึงระหว่างพยัญชนะกับสระบน/วรรณยุกต์ ทำให้เครื่องหมายไทยหลุดหาย
                    .kerning(-1 + 9 * t)
                    // ยาวเกินสองบรรทัดตัดด้วย … ไม่ดัน widget ให้สูงขึ้น
                    // (เดิม `fixedSize` ให้ข้อความเป็นคนกำหนดความสูง พิมพ์ยาวแล้วล้นกรอบที่วางไว้)
                    .lineLimit(2).truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .editableText(.name, .init(size: nameSize, weight: .black,
                                               color: ink.text(0.98), tracking: -1))
            }
            .scrubVeil(scrub.d, lead: 0.24, drop: 44, pull: 8)

            Text(Profile.me.tagline.uppercased())
                .tracking(2)
                .lineLimit(1)
                .truncationMode(.tail)
                .editableText(.tagline, .init(size: 9.5, weight: .semibold,
                                              color: ink.text(0.45), tracking: 2,
                                              uppercase: true))
                .scrubVeil(scrub.d, lead: 0.02, drop: 22, pull: 18)
        }
        // จัดกลางแนวตั้ง — ตอนถูกยืดสูงกว่าข้อความ ช่องว่างแบ่งบนล่างเท่ากัน ไม่กองอยู่ท้ายกล่อง
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
