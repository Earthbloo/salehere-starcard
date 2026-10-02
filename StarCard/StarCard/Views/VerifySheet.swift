import SwiftUI
import PhosphorSwift

/// แผ่นตรวจสอบ — **แผ่นเดียว ใช้ทุกที่**: แตะแถบ Verified บนหน้าดู หรือแตะ widget ตรารับรองบนการ์ด
///
/// ตราที่แตะแล้วไม่มีคำตอบคือตราที่ปลอมได้ใน Canva — แผ่นนี้ตอบสามคำถามเสมอ:
/// ตรวจอะไร · เมื่อไหร่ · ตรวจซ้ำได้ที่ไหน (ข้อมูลชุดเดียวกับ `VerifiedSealWidget` — ดู `VerifiedFacts`)
///
/// หน้าตาเป็นภาษาเดียวกับ `ContactSheet`: ชีตมืดของเวที ไม่ใช่การ์ดขาวของแอปหลัก
struct VerifySheet: View {
    let slug: String

    var body: some View {
        let facts = VerifiedFacts.current

        VStack(alignment: .leading, spacing: 0) {
            // หัว — เหรียญรับรองตัวเดียวกับบน widget + ลายกิโยเช่จางที่มุมขวา
            HStack(spacing: 14) {
                VerifiedSeal(radius: 27, punch: Color(white: 0.09))
                VStack(alignment: .leading, spacing: 3) {
                    Text(facts.verified ? "Verified by Sale Here" : "กำลังรอการยืนยัน")
                        .font(.sh(19, .bold))
                        .foregroundStyle(.white)
                    Text("สิ่งที่ Sale Here ตรวจแล้วของ @\(slug)")
                        .font(.sh(12, .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)

            VStack(spacing: 0) {
                ForEach(facts.rows) { r in
                    HStack(spacing: 12) {
                        if r.ok {
                            MiniSeal(size: 20)
                        } else {
                            PIcon(.clock, size: 18).foregroundStyle(.white.opacity(0.4))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(r.title).font(.sh(14.5, .semibold)).foregroundStyle(.white)
                            Text(r.detail).font(.sh(11.5, .medium)).foregroundStyle(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        Text(r.value)
                            .font(Signature.mono(11, .semibold))
                            .foregroundStyle(.white.opacity(r.ok ? 0.62 : 0.4))
                    }
                    .padding(.vertical, 11)
                    if r.id != facts.rows.last?.id {
                        Rectangle().fill(.white.opacity(0.08)).frame(height: 0.7)
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.055)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.09), lineWidth: 0.7))

            // ท้ายแผ่น — เลขการ์ด · ที่อยู่ที่ตรวจซ้ำได้ · ตราผู้ออก
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("STAR CARD NO. \(facts.serial)")
                        .font(Signature.mono(9.5, .semibold)).tracking(0.5)
                        .foregroundStyle(.white.opacity(0.55))
                    Text("ตรานี้มีผลเฉพาะบน \(Signature.url(slug: slug))")
                        .font(.sh(11, .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                Spacer(minLength: 8)
                StarLockup(height: 24, tint: .white.opacity(0.9))
            }
            .padding(.top, 18)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(alignment: .topTrailing) {
            Guilloche(color: .white.opacity(0.055))
                .frame(width: 300, height: 300)
                .offset(x: 110, y: -120)
                .allowsHitTesting(false)
        }
        .clipped()
    }

    /// ความสูงของชีต — พอดีเนื้อหา ไม่ใช่ครึ่งจอ (แถวเสริมมาเมื่อไหร่ชีตสูงขึ้นหนึ่งแถว)
    static var height: CGFloat { 372 + CGFloat(max(0, VerifiedFacts.current.rows.count - 3)) * 62 }
}

// MARK: - แถบ Verified ของหน้าดู

/// แถบใต้แถบบนของหน้าดู — อยู่ **นอกตัวการ์ด** เจ้าของลบหรือแต่งไม่ได้ (คู่ของแม่กุญแจบนแถบที่อยู่เบราว์เซอร์)
/// ดังได้เต็มที่เพราะเป็นพื้นที่ของเวที ไม่ใช่ของงานที่เจ้าของออกแบบ · แตะแล้วเปิด `VerifySheet`
struct VerifiedBand: View {
    let action: () -> Void

    static let height: CGFloat = 38

    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            HStack(spacing: 9) {
                // ป้ายตัวจริงของแอปหลัก — **ของชิ้นเดียว** ที่บอกทั้ง "ยืนยันแล้ว" และ "โดยใคร"
                // (รอบก่อนประกอบจากเหรียญ + ตัวอักษร + วงแดง สามชิ้นคนละภาษา — ผู้ใช้: "โครตจะไม่สวย")
                Image(SHIcon.verifiedPill)
                    .resizable().scaledToFit()
                    .frame(height: 28)
                    .accessibilityHidden(true)
                Spacer(minLength: 6)
                Text("ตรวจ \(Signature.verifiedOn)")
                    .font(Signature.mono(10, .medium))
                    .foregroundStyle(.white.opacity(0.55))
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.leading, 6).padding(.trailing, 14)
            .frame(height: Self.height)
            .contentShape(Capsule())
        }
        .buttonStyle(DockPress())
        .glassEffect(.regular.interactive(), in: Capsule())
        .accessibilityLabel("Verified by Sale Here ดูสิ่งที่ตรวจแล้ว")
    }
}

// MARK: - ป้ายรับรองของคลังการ์ด

/// ป้ายรับรองของคลัง — ป้าย VERIFIED BY SALE HERE ตัวจริงของแอปหลัก สูงเท่าป้าย "กำลังแสดงอยู่"
struct VerifiedTab: View {
    var body: some View {
        // ป้ายตัวจริงของแอปหลัก ลอยเหนือการ์ด — ไม่ต้องมีแคปซูลรอง ตัวมันเป็นป้ายอยู่แล้ว
        Image(SHIcon.verifiedPill)
            .resizable().scaledToFit()
            .frame(height: 30)
            .shadow(color: .black.opacity(0.45), radius: 8, y: 4)
            .accessibilityLabel("Verified by Sale Here")
    }
}
