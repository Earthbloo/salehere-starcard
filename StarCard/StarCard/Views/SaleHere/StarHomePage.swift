import SwiftUI
import PhosphorSwift

/// แท็บหน้าแรกของแอปจำลอง — มีแต่ Sale Here STAR (กิจกรรมที่แบรนด์เปิดรับ) ตามที่ตกลง 22 ก.ย. 2569
///
/// แถวบนเลื่อนแนวนอนเหมือน section "Sale Here STAR" บนหน้าแรกแอปหลัก · ข้างล่างเป็นรายการเต็มให้หน้าไม่โล่ง
struct StarHomePage: View {
    let campaigns: [StarCampaign]
    let onOpen: (StarCampaign) -> Void
    /// banner "สมัครเป็น ST★R" (ยังไม่เป็น STAR เท่านั้น)
    var onBanner: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            SHNavBar(title: "Sale Here STAR") {
                SHBarLogo()
            } right: {
                SHBarIcon(icon: .headset)
                SHBarIcon(icon: .bell)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    sectionHeader
                    StarInviteBanner(onTap: onBanner).padding(.horizontal, 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(campaigns) { c in
                                StarCampaignCard(campaign: c, onOpen: { onOpen(c) })
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    Text("กิจกรรมทั้งหมด")
                        .font(.sh(17, .bold)).foregroundStyle(SH.ink)
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                    VStack(spacing: 12) {
                        ForEach(campaigns) { c in
                            StarCampaignRow(campaign: c, onOpen: { onOpen(c) })
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .background(SH.page)
        }
    }

    private var sectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: 6) {
                PIcon(.sparkle, size: 16, weight: .fill).foregroundStyle(SHColor.star)
                Text("Sale Here STAR").font(.sh(20, .black)).foregroundStyle(SH.red)
                PIcon(.sparkle, size: 12, weight: .fill).foregroundStyle(SHColor.star)
            }
            Spacer()
            Button {} label: {
                HStack(spacing: 2) {
                    Text("ดูทั้งหมด").font(.sh(14, .medium))
                    PIcon(.caretRight, size: 12)
                }
                .foregroundStyle(SH.muted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }
}

/// การ์ดในแถวเลื่อน — ปก · โลโก้+ชื่อ · วันที่ · ปุ่มแดง (สัดส่วนจาก screenshot: การ์ด ~172pt)
struct StarCampaignCard: View {
    let campaign: StarCampaign
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 0) {
                Image(campaign.cover)
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 172, height: 116)
                    .clipped()
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        StarBrandLogo(name: campaign.logo, size: 32)
                        Text(campaign.headline)
                            .font(.sh(14, .bold)).foregroundStyle(SH.ink)
                            .lineLimit(2).multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 50, alignment: .top)
                    HStack(spacing: 5) {
                        PIcon(.calendarBlank, size: 13, weight: .regular)
                        Text(campaign.dateRange).font(.sh(12, .medium))
                    }
                    .foregroundStyle(SH.muted)
                    SHRedButton(title: campaign.isOpen ? "ลงทะเบียนร่วมกิจกรรม" : "หมดเวลา",
                                enabled: campaign.isOpen, height: 40, action: onOpen)
                        .allowsHitTesting(false)
                }
                .padding(10)
            }
            .frame(width: 172)
            .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SH.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// แถวในรายการเต็ม — ปกซ้าย ข้อความขวา
struct StarCampaignRow: View {
    let campaign: StarCampaign
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 12) {
                Image(campaign.cover)
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 112, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 6) {
                    Text(campaign.headline)
                        .font(.sh(14, .bold)).foregroundStyle(SH.ink)
                        .lineLimit(2).multilineTextAlignment(.leading)
                    HStack(spacing: 5) {
                        PIcon(.calendarBlank, size: 13, weight: .regular)
                        Text(campaign.dateRange).font(.sh(12, .medium))
                    }
                    .foregroundStyle(SH.muted)
                    Text(campaign.isOpen ? "เปิดรับสมัคร" : "หมดเวลา")
                        .font(.sh(11, .bold))
                        .foregroundStyle(campaign.isOpen ? SH.red : SH.hint)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(campaign.isOpen ? SHColor.redSoft : SHColor.soft, in: Capsule())
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SH.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// โลโก้แบรนด์วงกลมมีขอบบาง
struct StarBrandLogo: View {
    let name: String
    var size: CGFloat
    var body: some View {
        Image(name)
            .resizable().aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(SH.line, lineWidth: 1))
    }
}
