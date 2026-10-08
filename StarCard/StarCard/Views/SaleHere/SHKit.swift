import SwiftUI
import PhosphorSwift

// MARK: - ชิ้นส่วนหน้าจอ "แอป Sale Here จำลอง"
//
// หน้าพวกนี้เลียนแบบแอป Sale Here จริง (แถบแดง · การ์ดขาว · ปุ่มแดงเต็ม) ตาม screenshot 22 ก.ย. 2569
// เพื่อให้ Star Card มีบริบทตอนเทส flow — ไม่ใช่ภาษาของหน้า Star Card เอง (ดู `PK`)

enum SH {
    static let red = SHColor.red
    static let ink = SHColor.ink
    static let muted = SHColor.textSecondary
    static let hint = SHColor.textTertiary
    static let page = SHColor.page
    static let line = SHColor.stroke
    /// ปกโปรไฟล์ยังไม่ตั้ง — เทาอ่อนแบบแอปหลัก
    static let coverGrey = Color(red: 233 / 255, green: 234 / 255, blue: 236 / 255)
    /// กล่องเลขนับถอยหลัง
    static let clockBox = Color(red: 30 / 255, green: 32 / 255, blue: 38 / 255)
    /// แถบ "สถานะดราฟต์รีวิว"
    static let amberTint = Color(red: 255 / 255, green: 244 / 255, blue: 224 / 255)
    static let amber = Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255)
    static let blue = Color(red: 37 / 255, green: 99 / 255, blue: 235 / 255)
    static let verifiedBlue = Color(red: 29 / 255, green: 155 / 255, blue: 240 / 255)
}

/// แถบบนสีแดงของแอปหลัก — ชิ้นกลางเป็นชื่อหน้า ซ้าย/ขวาเป็นไอคอนขาว
struct SHNavBar<Left: View, Right: View>: View {
    let title: String
    @ViewBuilder var left: Left
    @ViewBuilder var right: Right

    var body: some View {
        ZStack {
            Text(title).font(.sh(18, .bold)).foregroundStyle(.white).lineLimit(1)
            HStack(spacing: 14) {
                left
                Spacer()
                right
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .background(SH.red.ignoresSafeArea(edges: .top))
    }
}

/// โลโก้ Sale Here บนแถบแดง — วงกลมขอบขาว ตัวหนังสือขาว (แบบหน้าโปรไฟล์แอปหลัก)
struct SHBarLogo: View {
    var body: some View {
        Image("ic-salehere-text")
            .renderingMode(.template)
            .resizable().aspectRatio(contentMode: .fit)
            .frame(width: 22)
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
    }
}

/// ไอคอนขาวบนแถบแดง
struct SHBarIcon: View {
    let icon: Ph
    var size: CGFloat = 24
    var action: () -> Void = {}
    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            PIcon(icon, size: size, weight: .regular)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// ปุ่มแดงเต็มกว้าง — CTA เดียวของแอปหลัก
struct SHRedButton: View {
    let title: String
    var icon: Ph? = nil
    var enabled = true
    var height: CGFloat = 48
    let action: () -> Void

    var body: some View {
        Button {
            guard enabled else { return }
            Haptics.impact(.medium)
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon { PIcon(icon, size: 20, weight: .regular) }
                Text(title).font(.sh(16, .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(enabled ? SH.red : SHColor.strokeStrong, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// ปุ่มขอบแดง ตัวแดง — ปุ่มรองในหน้าโปรไฟล์
struct SHOutlineButton: View {
    let title: String
    var icon: Ph? = nil
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon { PIcon(icon, size: 20, weight: .regular) }
                Text(title).font(.sh(15, .semibold))
            }
            .foregroundStyle(SH.red)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(SH.red, lineWidth: 1.2))
        }
        .buttonStyle(.plain)
    }
}

/// แท็บล่างของแอปจำลอง — สองแท็บตามที่ตกลง: หน้าแรก (STAR) · โปรไฟล์
enum SHTab: Hashable { case home, profile }

struct SHTabBar: View {
    @Binding var tab: SHTab
    @Environment(PhotoStore.self) private var photos

    var body: some View {
        HStack(spacing: 0) {
            item(.home, label: "หน้าแรก") {
                Image(tab == .home ? "ic-salehere-star-outline-active" : "ic-salehere-star-outline")
                    .renderingMode(.template)
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 26)
            }
            item(.profile, label: "โปรไฟล์") {
                SHAvatar(size: 28)
                    .overlay(Circle().strokeBorder(tab == .profile ? SH.red : .clear, lineWidth: 2))
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { SH.line.frame(height: 0.5) }
    }

    private func item<Icon: View>(_ t: SHTab, label: String, @ViewBuilder icon: () -> Icon) -> some View {
        Button {
            guard tab != t else { return }
            Haptics.impact(.light)
            withAnimation(Motion.settle) { tab = t }
        } label: {
            VStack(spacing: 4) {
                icon().frame(height: 28)
                Text(label).font(.sh(11, .medium))
            }
            .foregroundStyle(tab == t ? SH.red : SHColor.tabInactive)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// รูปโปรไฟล์วงกลม — รูปเดียวกับที่ hub "ข้อมูลของฉัน" ใช้ ให้คนเดียวกันทั้ง flow
struct SHAvatar: View {
    var size: CGFloat
    @Environment(PhotoStore.self) private var photos

    var body: some View {
        photos.avatar()
        .aspectRatio(contentMode: .fill)
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// ชื่อที่โชว์ในแอปจำลอง — ชื่อจาก "ข้อมูลของฉัน" ถ้ากรอกแล้ว ไม่งั้นชื่อบัญชีทดสอบ
enum SHMockUser {
    static let fallbackName = Profile.accountName
    /// `myProfile.tel` / `myProfile.lineId` ของบัญชี Sale Here (สมัครด้วยเบอร์) — ขั้นช่องทางติดต่อเติมให้ล่วงหน้า
    static let accountTel = "+66891234567"
    static let accountLine = ""
    static let fallbackBio = "ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่ร้านคาเฟ่น่ารักๆ"

    static var name: String {
        let p = Profile.me
        // ยังไม่มี Star Profile = ยังไม่มีชื่อที่พิมพ์ทับ — ห้ามหลุดชื่อของชุดตัวอย่าง (`Mock.creator`) ขึ้นหน้าบัญชี
        return p.hasIntake && !p.isPlaceholder(.name) ? p.name : fallbackName
    }
    /// About Me ของบัญชี = ช่อง "แนะนำตัว" ช่องเดียวกับการ์ดและ Star Profile
    static var bio: String {
        let p = Profile.me
        return p.hasIntake && !p.isPlaceholder(.about) ? p.about : fallbackBio
    }
}
