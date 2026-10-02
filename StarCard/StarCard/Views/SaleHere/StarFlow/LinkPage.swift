import SwiftUI
import PhosphorSwift

/// หน้าส่งลิงก์รีวิวเดิมของแอปหลัก (`ApproveLinkPage`) — ถอดจาก `S.link` ของ unbox-mock · ข้อความตาม Localized.strings
///
/// ช่องบังคับ = ช่องทางที่กิจกรรมกำหนด · ช่องทางอื่นส่งเพิ่มได้ · ปุ่มแดงกดได้เมื่อช่องบังคับเป็นลิงก์ครบ
/// หน้านี้ไม่ถามข้อมูล Star Profile และไม่มีอะไรแทรกก่อนถึง — บัญชีรับเงินเก็บที่ฟอร์มรับเงินของแอปหลัก
struct LinkPage: View {
    let campaign: StarCampaign
    let onClose: () -> Void
    let onSubmit: () -> Void

    /// ลิงก์โพสต์รีวิวของงานนี้ — คนละชุดกับลิงก์โปรไฟล์ใน `StarFlow.links`
    @State private var links: [StarSocial: String] = [:]
    @FocusState private var focus: StarSocial?
    /// เส้นตายส่งลิงก์ ตรึงตอนเปิดหน้า — แอปหลักนับเป็นกล่องเลขเมื่อเหลือไม่ถึง 1 วัน
    @State private var deadline = Date().addingTimeInterval(23 * 3600 + 59 * 60)

    private var extra: [StarSocial] { StarSocial.allCases.filter { !campaign.socialChannels.contains($0) } }
    private func valid(_ s: StarSocial) -> Bool {
        (links[s] ?? "").range(of: #"^https?://\S+$"#, options: .regularExpression) != nil
    }
    private var ready: Bool { campaign.socialChannels.allSatisfy(valid) }

    var body: some View {
        VStack(spacing: 0) {
            SHNavBar(title: "ส่งดราฟต์รีวิว") {
                Color.clear.frame(width: 32, height: 32)
            } right: {
                SHBarIcon(icon: .x, action: onClose)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    stepper.padding(.top, 16).padding(.bottom, 14)
                    HStack(alignment: .top, spacing: 8) {
                        (Text("* ").foregroundStyle(SH.red) + Text("ลิงก์โพสต์รีวิวบนโซเชียลมีเดีย ที่เราอยากให้คุณส่งรีวิว\n(วางลิงก์รีวิวให้ครบทุกช่องทาง)").foregroundStyle(SH.ink))
                            .font(.sh(14, .semibold)).lineSpacing(3)
                        Spacer(minLength: 0)
                        PIcon(.info, size: 22, weight: .regular).foregroundStyle(SH.red)
                    }
                    .padding(.bottom, 10)
                    ForEach(campaign.socialChannels) { field($0) }
                    Text("ลิงก์โพสต์รีวิวบนโซเชียลมีเดีย ที่สามารถส่งรีวิวเพิ่มเติม")
                        .font(.sh(14, .semibold)).foregroundStyle(SH.ink)
                        .padding(.top, 10).padding(.bottom, 10)
                    ForEach(extra) { field($0) }
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
            .background(.white)
            .scrollDismissesKeyboard(.interactively)
            VStack(spacing: 8) {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    HStack(spacing: 6) {
                        PIcon(.calendarBlank, size: 14, weight: .regular).foregroundStyle(SH.muted)
                        Text("เหลือเวลาส่งลิงก์รีวิว").font(.sh(12, .medium)).foregroundStyle(SH.muted)
                        SHClock(seconds: max(0, Int(deadline.timeIntervalSince(ctx.date))))
                    }
                }
                SHRedButton(title: "ส่งลิงก์รีวิว", icon: .paperPlaneTilt, enabled: ready, action: onSubmit)
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 8)
            .background(Color.white.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { SH.line.frame(height: 1) }
        }
        .background(Color.white.ignoresSafeArea())
    }

    /// 3 ขั้นของงานรีวิว (`TopicReviewStateTopView.setAddSocialLinkState`): สองขั้นแรกเขียว · ขั้นนี้เทาเข้ม · เส้นเขียวทั้งคู่
    private var stepper: some View {
        let names = ["สร้างดราฟต์รีวิว", "ส่งดราฟต์รีวิว", "ส่งลิงก์"]
        return HStack(alignment: .top, spacing: 0) {
            ForEach(0..<3, id: \.self) { i in
                VStack(spacing: 4) {
                    ZStack {
                        HStack(spacing: 0) {
                            (i == 0 ? Color.clear : SHColor.green).frame(height: 1)
                            (i == 2 ? Color.clear : SHColor.green).frame(height: 1)
                        }
                        Text("\(i + 1)").font(.sh(14, .bold)).foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(i < 2 ? SHColor.green : SHColor.textTertiary))
                    }
                    Text(names[i]).font(.sh(12)).foregroundStyle(i < 2 ? SHColor.green : SH.muted)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// ช่องวางลิงก์ของช่องทางหนึ่ง — ไอคอนอยู่ในกล่อง · ใต้กล่องเป็นคำช่วย หรือคำเตือนเมื่อไม่ใช่ลิงก์
    private func field(_ s: StarSocial) -> some View {
        let text = links[s] ?? ""
        let bad = !text.isEmpty && !valid(s)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(s.icon).resizable().aspectRatio(contentMode: .fit).frame(width: 28, height: 28).clipShape(Circle())
                TextField("", text: Binding(get: { links[s] ?? "" }, set: { links[s] = $0.trimmingCharacters(in: .whitespaces) }),
                          prompt: Text("วางลิงก์โพสต์รีวิวบน \(s.name) ของคุณ").foregroundStyle(SH.hint))
                    .font(.sh(14, .medium)).foregroundStyle(SH.blue).tint(SH.red)
                    .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    .focused($focus, equals: s)
            }
            .padding(.horizontal, 10).frame(height: 44)
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(bad ? SH.red : SH.line, lineWidth: 1))
            if bad {
                Text("ลิงก์ไม่ถูกต้อง").font(.sh(12, .medium)).foregroundStyle(SH.red)
            } else {
                HStack(spacing: 4) {
                    PIcon(.info, size: 14, weight: .regular).foregroundStyle(SH.hint)
                    Text("ตรวจสอบบัญชี \(s.name) ที่ลงทะเบียน").font(.sh(12, .medium)).foregroundStyle(SH.hint)
                    Text("คลิก").font(.sh(12, .medium)).foregroundStyle(SH.blue)
                }
            }
        }
        .padding(.bottom, 10)
    }
}
