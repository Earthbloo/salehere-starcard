import SwiftUI
import PhosphorSwift

/// แท็บโปรไฟล์ของแอปจำลอง — หน้าโปรไฟล์ผู้ใช้ Sale Here ตาม screenshot 22 ก.ย. 2569
///
/// ปุ่ม "โปรไฟล์ครีเอเตอร์" คือประตูเดียวเข้าสู่ Star Card (hub "ข้อมูลของฉัน") — flow เดิมของแอปหลัก
struct SaleHereProfilePage: View {
    let onCreatorProfile: () -> Void
    let campaignCount: Int
    /// กดค้างชื่อบนแถบแดง → แผง lab ของ flow ใหม่
    var onLab: () -> Void = {}
    /// banner "สมัครเป็น ST★R" เหนือช่องโพสต์ (ยังไม่เป็น STAR เท่านั้น)
    var onBanner: () -> Void = {}

    private enum Feed { case grid, list, mentions }
    @State private var feed: Feed = .grid

    var body: some View {
        VStack(spacing: 0) {
            SHNavBar(title: SHMockUser.name) {
                SHBarLogo()
            } right: {
                SHBarIcon(icon: .chatCircleText)
                SHBarIcon(icon: .list)
            }
            .onLongPressGesture(minimumDuration: 0.6) { Haptics.impact(.medium); onLab() }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    VStack(spacing: 12) {
                        stats
                        HStack(spacing: 10) {
                            SHOutlineButton(title: "แก้ไขโปรไฟล์", icon: .pencilSimple) {}
                            SHOutlineButton(title: "โปรไฟล์ครีเอเตอร์", icon: .identificationCard, action: onCreatorProfile)
                        }
                        tiles
                        StarInviteBanner(onTap: onBanner)
                        composer
                        draftBanner
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    feedTabs
                        .padding(.top, 14)
                    photoGrid
                    // ทางลัดทดสอบ: แผง lab (ล้างข้อมูล / กระโดดขั้น) — แอปจริงไม่มี
                    Button {
                        Haptics.impact(.light)
                        onLab()
                    } label: {
                        HStack(spacing: 5) {
                            PIcon(.arrowsClockwise, size: 12, weight: .regular)
                            Text("ล้างข้อมูลทดสอบ / Lab").font(.sh(12, .semibold))
                        }
                        .foregroundStyle(SH.hint)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 24)
            }
            .background(SH.page)
        }
    }

    // MARK: ปก + รูป + ชื่อ

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                SH.coverGrey
                    .frame(height: 150)
                    .overlay {
                        HStack(spacing: 60) {
                            PIcon(.imageSquare, size: 44, weight: .regular)
                            PIcon(.imageSquare, size: 44, weight: .regular)
                        }
                        .foregroundStyle(.white.opacity(0.9))
                    }
                PIcon(.camera, size: 18, weight: .regular)
                    .foregroundStyle(SH.muted)
                    .frame(width: 30, height: 30)
                    .background(.white, in: Circle())
                    .padding(10)
            }
            ZStack(alignment: .topLeading) {
                Color.white
                HStack(alignment: .top, spacing: 12) {
                    Color.clear.frame(width: 118, height: 60)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            PIcon(.sealCheck, size: 18, weight: .fill).foregroundStyle(SH.verifiedBlue)
                            Text(SHMockUser.name)
                                .font(.sh(19, .bold)).foregroundStyle(SH.ink).lineLimit(1)
                            Spacer(minLength: 6)
                            Button { Haptics.impact(.light) } label: {
                                PIcon(.shareFat, size: 18, weight: .regular)
                                    .foregroundStyle(SH.red)
                                    .frame(width: 36, height: 36)
                                    .background(SHColor.redSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        Text(SHMockUser.bio)
                            .font(.sh(13)).foregroundStyle(SH.ink)
                            .lineSpacing(2)
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 12)
                avatar
                    .padding(.leading, 10)
                    .offset(y: -62)
            }
            .frame(height: 80, alignment: .top)
        }
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            SHAvatar(size: 112)
                .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                .overlay(Circle().strokeBorder(SHColor.star, lineWidth: 1.5))
            ZStack {
                Circle().fill(SHColor.star)
                PIcon(.star, size: 16, weight: .fill).foregroundStyle(.white)
            }
            .frame(width: 30, height: 30)
            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
        }
        .overlay(alignment: .bottomLeading) {
            PIcon(.qrCode, size: 18, weight: .regular)
                .foregroundStyle(SH.muted)
                .offset(x: -2, y: 8)
        }
    }

    private var stats: some View {
        HStack(spacing: 0) {
            stat("0", "ผู้ติดตาม")
            divider
            stat("0", "กำลังติดตาม")
            divider
            stat("5", "โพสต์")
            divider
            stat("7", "Engagement")
        }
        .padding(.vertical, 6)
        .background(.white)
    }

    private var divider: some View { SH.line.frame(width: 1, height: 28) }

    private func stat(_ n: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(n).font(.sh(16, .semibold)).foregroundStyle(SH.ink)
            Text(label).font(.sh(12)).foregroundStyle(SH.muted)
        }
        .frame(maxWidth: .infinity)
    }

    private var tiles: some View {
        HStack(spacing: 10) {
            tile(title: "Coupon", sub: "เก็บคูปอง", tint: SH.blue) {
                PIcon(.ticket, size: 22, weight: .fill).foregroundStyle(.white)
            }
            tile(title: "Sale Here STAR", sub: "\(campaignCount) กิจกรรม", tint: SH.red) {
                Image("ic-salehere-star-outline-active")
                    .renderingMode(.template)
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 28)
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
        }
    }

    private func tile<Icon: View>(title: String, sub: String, tint: Color, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 10) {
            icon().frame(width: 40, height: 40)
                .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.sh(14, .bold)).foregroundStyle(tint)
                Text(sub).font(.sh(12)).foregroundStyle(SH.muted)
            }
        }
        .padding(8)
        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SH.line, lineWidth: 1))
    }

    private var composer: some View {
        HStack(alignment: .top, spacing: 10) {
            SHAvatar(size: 40)
            Text("สวัสดีค่ะ คุณ \(SHMockUser.name), โพสต์บอกเล่าประสบการณ์ หรือรีวิวกิจกรรมของคุณ")
                .font(.sh(14)).foregroundStyle(SH.hint)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(minHeight: 120, alignment: .top)
        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SH.line, lineWidth: 1))
        .overlay(alignment: .bottomTrailing) {
            PIcon(.imageSquare, size: 22, weight: .regular).foregroundStyle(SH.red).padding(12)
        }
    }

    private var draftBanner: some View {
        HStack(spacing: 12) {
            PIcon(.notePencil, size: 22, weight: .fill)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(SH.amber, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text("สถานะดราฟต์รีวิว").font(.sh(15, .semibold)).foregroundStyle(SH.ink)
            Spacer()
        }
        .padding(10)
        .background(SH.amberTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var feedTabs: some View {
        HStack(spacing: 0) {
            feedItem(.grid, .squaresFour)
            feedItem(.list, .list)
            feedItem(.mentions, .at)
        }
        .frame(height: 46)
        .background(.white)
        .overlay(alignment: .bottom) { SH.line.frame(height: 1) }
    }

    private func feedItem(_ f: Feed, _ icon: Ph) -> some View {
        Button {
            guard feed != f else { return }
            Haptics.impact(.light)
            withAnimation(Motion.snap) { feed = f }
        } label: {
            PIcon(icon, size: 24, weight: .regular)
                .foregroundStyle(feed == f ? SH.red : SHColor.tabInactive)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) { (feed == f ? SH.red : .clear).frame(height: 3) }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var photoGrid: some View {
        let names = ["ph01", "ph02", "ph03", "ph04", "mock-cover-thymora"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
            ForEach(names, id: \.self) { n in
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay { Image(n).resizable().aspectRatio(contentMode: .fill) }
                    .clipped()
            }
        }
        .padding(.top, 2)
    }
}
