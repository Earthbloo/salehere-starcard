import SwiftUI
import PhosphorSwift

/// banner ชวน "สมัครเป็น ST★R" — แทน "ทำโปรไฟล์ให้สมบูรณ์กันเถอะ" (`WelcomeOnboardingSectionView`) ของ salehere-ios
/// แคนวาส A ตราทอง (6 ต.ค. 2569) · ผู้ใช้ 7 ต.ค. 2569: เช็คแค่ 8 ข้อ · % เฉพาะตอนทำ STAR · เป็น STAR แล้วหายไปเลย · สูงเท่ากันทุกสถานะ
/// = `starBanner()` ของ desktop/js/screens.js — หน้าแรก (ใต้หัว Sale Here STAR) + แท็บโปรไฟล์ (เหนือช่องโพสต์)
///   ปกติ → "สมัครเลย" = ถามเฉพาะข้อที่ขาดใน 8 ข้อ · รอตรวจตัวตน → ป้ายนาฬิกาที่รูป + "ดูสถานะ" · ไม่ผ่าน → ป้าย ! แดง + "ส่งใหม่" (แดงที่เดียว)
struct StarInviteBanner: View {
    @Environment(StarFlow.self) private var flow
    let onTap: () -> Void

    private static let height: CGFloat = 88
    private static let gold = Color(red: 201 / 255, green: 162 / 255, blue: 39 / 255)
    private static let track = Color(red: 241 / 255, green: 230 / 255, blue: 198 / 255)
    private static let rim = Color(red: 1, green: 222 / 255, blue: 140 / 255)
    private static let pillInk = Color(red: 122 / 255, green: 90 / 255, blue: 18 / 255)
    private static let pillBg = Color(red: 1, green: 243 / 255, blue: 207 / 255)
    private static let pillLine = Color(red: 240 / 255, green: 217 / 255, blue: 143 / 255)

    private var left: Int { flow.starMissing.count }
    /// เหลือแค่ยืนยันตัวตนข้อเดียว — ป้ายรอตรวจ/ไม่ผ่านโชว์เฉพาะตอนนี้ (salehere-ios: ยังขาดข้ออื่นอยู่ = ป้ายดาวปกติ · ห้ามพาไปหน้าสถานะทั้งที่ยังไม่ได้กรอก)
    private var onlyKyc: Bool { flow.starMissing == [.kyc] }
    private var waiting: Bool { onlyKyc && flow.verify == .waiting }
    private var rejected: Bool { onlyKyc && flow.verify == .rejected }
    /// สถานะ C: STAR เก่า (มียศ) ที่ 8 ข้อยังไม่ครบ — วงทองเต็ม + ดาว · ไม่มี % · "ขาด N ข้อ"
    private var more: Bool { flow.needsStarInfo }
    private var title: String { more ? "เติมข้อมูล STAR" : "สมัครเป็น STAR" }
    private var pill: String { more ? "ขาด \(left) ข้อ" : "\(Int((flow.starPct * 100).rounded()))%" }
    private var ring: Double { more ? 1 : flow.starPct }
    private var sub: String {
        more ? "แบรนด์ขอข้อมูลเพิ่ม · กรอกครบแล้วสมัครงานได้ต่อเลย"
            : waiting ? "รอตรวจตัวตน · แจ้งผลภายใน 1–3 วันทำการ"
            : rejected ? "ตัวตนไม่ผ่าน · ถ่ายใหม่แล้วส่งได้เลย"
            : left == StarFlow.starSteps.count ? "รับงานรีวิวจากแบรนด์ · ตอบ 8 ข้อที่ต้องกรอกก่อนเป็น STAR"
            : "อีก \(left) ข้อได้เป็น STAR"
    }
    /// ไม่โชว์บนจอ (ปุ่มเหลือแค่วงลูกศร) — ข้อความให้ VoiceOver
    private var cta: String { more ? "เติมข้อมูล" : waiting ? "ดูสถานะ" : rejected ? "ส่งใหม่" : "สมัครเลย" }

    var body: some View {
        // STAR ครบ 8 ข้อ (สถานะ B) = ไม่มี banner
        if !flow.isStar || more {
            Button {
                Haptics.impact(.light)
                onTap()
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    avatar
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .center, spacing: 6) {
                            StarText(title, size: 16, weight: .heavy)
                            Text(pill)
                                .font(.sh(12, .heavy)).monospacedDigit().foregroundStyle(Self.pillInk).lineLimit(1)
                                .padding(.horizontal, 8).frame(height: 22)
                                .background(Capsule().fill(Self.pillBg))
                                .overlay(Capsule().strokeBorder(Self.pillLine, lineWidth: 1))
                        }
                        Text(sub).font(.sh(12.5, rejected ? .semibold : .regular))
                            .foregroundStyle(rejected ? Color(red: 180 / 255, green: 35 / 255, blue: 24 / 255) : Color(white: 0.29))
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    // ปุ่ม = วงดำ + ลูกศร ไม่มีข้อความ (ทั้งใบแตะได้อยู่แล้ว) — salehere-ios 7 ต.ค. 2569 "มันสูง · เอาแค่ icon พอ"
                    PIcon(.arrowRight, size: 16, weight: .bold)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(white: 0.137)))
                }
                .padding(.leading, 12).padding(.trailing, 14).padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: Self.height)
                .background(PK.shape(18).fill(LinearGradient(colors: [.white, Color(red: 1, green: 251 / 255, blue: 239 / 255)], startPoint: .top, endPoint: .bottom)))
                .overlay(PK.shape(18).strokeBorder(Self.rim, lineWidth: 1))
                .shadow(color: Color(red: 154 / 255, green: 116 / 255, blue: 32 / 255).opacity(0.18), radius: 13, y: 8)
                .contentShape(PK.shape(18))
            }
            .buttonStyle(DockPress())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title) \(pill) · \(sub) · \(cta)")
            .accessibilityAddTraits(.isButton)
        }
    }

    /// รูปในวงทอง — วงเติมตาม % · ป้ายมุมขวาล่าง: ดาว (ปกติ) / นาฬิกาเส้นประ (รอตรวจ) / ! แดง (ไม่ผ่าน)
    private var avatar: some View {
        ZStack {
            Circle().stroke(Self.track, lineWidth: 4)
            Circle().trim(from: 0, to: ring)
                .stroke(Self.gold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Motion.settle, value: ring)
            Group {
                if let img = Portfolio.shared.creatorImages.first {
                    Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
                } else {
                    ZStack { PK.fieldFill; PIcon(.user, size: 22).foregroundStyle(PK.hint) }
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
        }
        .frame(width: 64, height: 64)
        .overlay(alignment: .bottomTrailing) { badge.offset(x: 2, y: 0) }
    }

    @ViewBuilder private var badge: some View {
        if waiting {
            PIcon(.clock, size: 11, weight: .bold).foregroundStyle(Color(white: 0.31))
                .frame(width: 22, height: 22)
                .background(Circle().fill(.white))
                .overlay(Circle().strokeBorder(Color(white: 0.61), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])))
        } else if rejected {
            Text("!").font(.sh(12, .heavy)).foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(SH.red))
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
        } else {
            PIcon(.star, size: 11, weight: .fill).foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Self.gold))
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
        }
    }
}
