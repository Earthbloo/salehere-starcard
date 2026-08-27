import SwiftUI

/// ยอดผู้ติดตามแยกรายแพลตฟอร์ม
///
/// ต้องแยกช่อง ไม่ใช่รวมเป็นตัวเลขเดียว เพราะแบรนด์เลือกช่องก่อนเลือกคน —
/// คนทำแคมเปญ TikTok ไม่สนใจว่ายอด IG เท่าไหร่ ตัวเลขรวมจึงตอบคำถามเขาไม่ได้
///
/// # ท่าเปลี่ยนหน้า — "ตัวเลขไปก่อน การ์ดไปทีหลัง"
///
/// สองจังหวะซ้อนกันในแผ่นเดียว: ยอดผู้ติดตามถูกถอดออกทีละหลักก่อน แล้วแผ่นทั้งใบ
/// ถึงค่อยมุดใต้ขอบตามไปไล่กันทีละแพลตฟอร์ม — ของข้างในไปก่อนกล่องเสมอ
/// นั่นคือสิ่งที่แยก "แผ่นข้อมูลที่มีชีวิต" ออกจาก "แผ่นสี่เหลี่ยมที่ถูกเลื่อน"
struct SocialChips: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let width: CGFloat

    private var socials: [SocialProfile] { Mock.creator.socials }
    /// จอแคบวางเรียงลง จอกว้างวางเรียงข้าง
    private var stacked: Bool { width < 240 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetLabel(text: "ผู้ติดตาม", trailing: AnyView(SyncDot(ago: "2 ชม.")))
                .scrubVeil(scrub.d, lead: 0.36, drop: 20, pull: 6)

            // เต็มพื้นที่ที่เหลือเสมอ — กล่องสูงเท่าไหร่ชิปก็แบ่งกันจนเต็ม
            // ห้ามปักหมุดบนแล้วทิ้งช่องว่างโบ๋ท้ายกล่อง
            if stacked {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(socials.enumerated()), id: \.element.id) { i, s in
                        platform(s, i: i).frame(maxHeight: .infinity)
                    }
                }
            } else {
                HStack(alignment: .center, spacing: 8) {
                    ForEach(Array(socials.enumerated()), id: \.element.id) { i, s in
                        platform(s, i: i).frame(maxHeight: 64)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    private func platform(_ s: SocialProfile, i: Int) -> some View {
        let lead = Scrub.lead(i, of: socials.count, d: scrub.d, step: 0.09)
        return HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(s.type.tint.opacity(0.16))
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(s.type.tint.opacity(0.28), lineWidth: 0.6)
                BrandIcon(name: s.type.icon, size: 17)
            }
            .frame(width: 34, height: 34)
            .scrubLouver(scrub.d, lead: lead, angle: 70, shrink: 0.2)

            VStack(alignment: .leading, spacing: 1) {
                ScrubDigits(text: Fmt.compact(s.followerCount), d: scrub.d,
                            lead: lead + 0.04, step: 0.05, drop: 22)
                    .font(.sh(16, .bold))
                    .foregroundStyle(ink.text(0.98))
                Text(s.type.name)
                    .font(.sh(9, .medium))
                    .foregroundStyle(ink.text(0.42))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .scrubVeil(scrub.d, lead: lead, drop: 16, pull: 8)
            }
            Spacer(minLength: 0)
        }
        // เทรนด์ 2026 · Surface elevation ในธีมมืด — ใช้ "ผิวสว่างขึ้น + เรืองแสงประจำแพลตฟอร์ม"
        // แทนเงาดำ เพราะเงาดำบนพื้นมืดมองไม่เห็น ชั้นความสูงจึงต้องสื่อด้วยแสงและขอบแทน
        .padding(.horizontal, 10).padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        // พื้นมืดยกแผ่นด้วย "ผิวสว่างขึ้น" เพราะเงาดำบนพื้นมืดมองไม่เห็น
        // พื้นกระดาษกลับกันเป๊ะ: ยกด้วยแผ่นขาวทึบ + เงาจริง ส่วนผิวสว่างขึ้นจะจมหายไปกับพื้น
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(LinearGradient(
                    colors: ink.isLight ? [.white.opacity(0.92), .white.opacity(0.7)]
                                        : [.white.opacity(0.1), .white.opacity(0.045)],
                    startPoint: .top, endPoint: .bottom))
        )
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
            .strokeBorder(LinearGradient(colors: [s.type.tint.opacity(0.4), ink.line(0.06)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing),
                          lineWidth: 0.8))
        .shadow(color: s.type.tint.opacity(ink.isLight ? 0.16 : 0.28), radius: 10, y: 4)
        .shadow(color: ink.lift.opacity(0.5), radius: ink.liftRadius * 0.6, y: 4)
        // กล่องไปทีหลังของข้างในเสมอ
        .scrubVeil(scrub.d, lead: lead + 0.16, drop: 34, pull: 12)
    }
}
