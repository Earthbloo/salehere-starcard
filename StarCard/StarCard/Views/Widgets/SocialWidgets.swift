import SwiftUI

/// ยอดผู้ติดตามแยกรายแพลตฟอร์ม พร้อมตัวเลขที่บอกคุณภาพของช่อง
///
/// ต้องแยกช่อง ไม่ใช่รวมเป็นตัวเลขเดียว เพราะแบรนด์เลือกช่องก่อนเลือกคน —
/// คนทำแคมเปญ TikTok ไม่สนใจว่ายอด IG เท่าไหร่ ตัวเลขรวมจึงตอบคำถามเขาไม่ได้
///
/// # ทำไมเปลี่ยนจากสามช่องเรียงข้าง มาเป็นสามแถวเรียงลง
///
/// ของเดิมวางสามช่องต่อแถว แต่ละช่องจึงกว้างราว 110pt ซึ่งพอสำหรับ "ยอดฟอลโลว์ + ชื่อช่อง"
/// แต่ไม่พอเมื่อเติม ER กับยอดวิวเข้าไป — บรรทัดล่างถูกตัดเหลือ `ER 4.…` `92.0K…`
/// ซึ่งแย่กว่าไม่มีเลย เพราะมันกินที่แล้วไม่ให้ข้อมูล
///
/// สามแถวเรียงลงได้ความกว้างเต็มการ์ดต่อหนึ่งช่อง ตัวเลขทุกตัวจึงเขียนเต็มได้
/// และ **ทุกค่ามีไอคอนกำกับ** — เลขลอย ๆ สามตัวในแถวเดียวไม่มีทางรู้ว่าตัวไหนคืออะไร
struct SocialChips: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let width: CGFloat

    private var socials: [SocialProfile] { Mock.creator.socials }
    /// แคบมากถึงจะยอมตัดค่ารองทิ้ง — ที่ความกว้างครึ่งการ์ดยังใส่ได้ครบ
    private var tight: Bool { width < 190 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetLabel(text: "ผู้ติดตาม")
                .scrubVeil(scrub.d, lead: 0.36, drop: 20, pull: 6)

            VStack(spacing: 8) {
                ForEach(Array(socials.enumerated()), id: \.element.id) { i, s in
                    row(s, i: i).frame(maxHeight: .infinity)
                        .linkSlot(s.profileURL)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func row(_ s: SocialProfile, i: Int) -> some View {
        let lead = Scrub.lead(i, of: socials.count, d: scrub.d, step: 0.09)
        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(s.type.tint.opacity(0.16))
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(s.type.tint.opacity(0.28), lineWidth: 0.6)
                BrandIcon(name: s.type.icon, size: 17)
            }
            .frame(width: 34, height: 34)
            .scrubLouver(scrub.d, lead: lead, angle: 70, shrink: 0.2)

            VStack(alignment: .leading, spacing: 0) {
                ScrubDigits(text: Fmt.compact(s.followerCount), d: scrub.d,
                            lead: lead + 0.04, step: 0.05, drop: 22)
                    .font(.sh(17, .heavy))
                    .foregroundStyle(ink.text(0.98))
                Text(s.type.name)
                    .font(.sh(9.5, .medium))
                    .foregroundStyle(ink.text(0.42))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .scrubVeil(scrub.d, lead: lead, drop: 16, pull: 8)
            }

            Spacer(minLength: 6)

            if !tight {
                // ค่าที่บอก "คุณภาพของช่อง" — ไอคอนนำหน้าทุกตัว
                // เลขลอย ๆ สองตัวติดกันไม่มีทางรู้ว่าตัวไหนคือวิว ตัวไหนคือ engagement
                HStack(spacing: 11) {
                    metric("play.fill", Fmt.compact(s.avgViewCount), ink.text(0.55), lead: lead)
                    // ER ใช้ "คำ" ไม่ใช่ไอคอน — หัวใจอ่านออกมาเป็น "ยอดไลก์" ซึ่งไม่ใช่สิ่งเดียวกัน
                    // และไม่มีไอคอนตัวไหนในโลกที่แปลว่า engagement rate ได้โดยไม่ต้องสอน
                    tagged("ER", Fmt.pct(s.engagementRate), s.type.tint, lead: lead + 0.03)
                }
            }
        }
        // เทรนด์ 2026 · Surface elevation ในธีมมืด — ใช้ "ผิวสว่างขึ้น + เรืองแสงประจำแพลตฟอร์ม"
        // แทนเงาดำ เพราะเงาดำบนพื้นมืดมองไม่เห็น ชั้นความสูงจึงต้องสื่อด้วยแสงและขอบแทน
        .padding(.horizontal, 11).padding(.vertical, 8)
        .frame(maxWidth: .infinity)
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

    /// ค่าที่มี "คำ" นำหน้าแทนไอคอน — ใช้กับค่าที่ไม่มีสัญลักษณ์สากล
    private func tagged(_ label: String, _ value: String, _ tint: Color, lead: Double) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.sh(9.5, .black)).tracking(0.3)
                .foregroundStyle(tint.opacity(0.9))
            Text(value)
                .font(.sh(12, .bold))
                .foregroundStyle(ink.text(0.88))
        }
        .lineLimit(1).fixedSize()
        .scrubVeil(scrub.d, lead: lead, drop: 18, pull: 10)
    }

    /// หนึ่งค่า = ไอคอน + ตัวเลข · ใช้กับค่าที่ไอคอนสื่อได้จริง (▶ = วิว)
    private func metric(_ icon: String, _ value: String, _ tint: Color, lead: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(tint.opacity(0.85))
            Text(value)
                .font(.sh(12, .bold))
                .foregroundStyle(ink.text(0.88))
        }
        .lineLimit(1).fixedSize()
        .scrubVeil(scrub.d, lead: lead, drop: 18, pull: 10)
    }
}


// MARK: - ผู้ติดตามแบบชิป

/// สามช่องทางเรียงข้างกัน — **ยอดฟอลโลว์อย่างเดียว ไม่มีค่ารอง**
///
/// เป็นแบบเดิมก่อนที่ `SocialChips` จะเปลี่ยนเป็นสามแถว และมีอยู่คู่กันโดยตั้งใจ:
/// แถวตอบคำถาม "ช่องไหนดี" (มี ER กับยอดวิว) · ชิปตอบคำถาม "มีช่องอะไรบ้าง"
///
/// สิ่งที่ทำให้แบบนี้ยังใช้ได้ทั้งที่แคบ คือ **มันไม่พยายามใส่ค่ารอง** —
/// ปัญหาของเดิมไม่ใช่ผังสามช่อง แต่คือการยัดสี่ค่าลงในช่อง 110pt
///
/// # ท่าเปลี่ยนหน้า — "ตัวเลขไปก่อน การ์ดไปทีหลัง"
/// ยอดผู้ติดตามถูกถอดออกทีละหลักก่อน แล้วแผ่นทั้งใบถึงค่อยมุดใต้ขอบตามไปไล่กัน
struct SocialTiles: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let width: CGFloat

    private var socials: [SocialProfile] { Mock.creator.socials }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetLabel(text: "ผู้ติดตาม")
                .scrubVeil(scrub.d, lead: 0.36, drop: 20, pull: 6)

            HStack(alignment: .center, spacing: 8) {
                ForEach(Array(socials.enumerated()), id: \.element.id) { i, s in
                    tile(s, i: i)
                        .linkSlot(s.profileURL)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func tile(_ s: SocialProfile, i: Int) -> some View {
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
        .padding(.horizontal, 10).padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: 64)
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
