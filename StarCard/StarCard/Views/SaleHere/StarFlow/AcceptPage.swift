import SwiftUI
import PhosphorSwift

/// หน้าตอบรับเดิมของแอปหลัก (`UnboxAcceptingDetailPage`) — ที่อยู่เติมให้จาก Star Profile แล้ว
struct AcceptPage: View {
    @Environment(StarFlow.self) private var flow
    let campaign: StarCampaign
    let onBack: () -> Void
    let onAccept: () -> Void
    let onDecline: () -> Void
    @State private var answer: String?

    var body: some View {
        VStack(spacing: 0) {
            SHNavBar(title: "รายละเอียดตอบรับกิจกรรม") {
                SHBarIcon(icon: .caretLeft, size: 26, action: onBack)
            } right: {
                Color.clear.frame(width: 32, height: 32)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        Image(campaign.cover).resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text(campaign.headline).font(.sh(14, .bold)).foregroundStyle(SH.ink).lineLimit(3)
                    }
                    .padding(16)
                    VStack(alignment: .leading, spacing: 18) {
                        section("โซเชียลที่คุณต้องรีวิว") {
                            HStack(spacing: 8) {
                                ForEach(campaign.socialChannels) { s in
                                    Image(s.icon).resizable().aspectRatio(contentMode: .fit).frame(width: 32, height: 32).clipShape(Circle())
                                }
                            }
                        }
                        section("ประเภทคอนเทนต์ที่ต้องรีวิว") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(campaign.contentTypes, id: \.self) { Text("- \($0)").font(.sh(14)).foregroundStyle(SH.ink) }
                            }
                        }
                        section("Timeline แคมเปญ") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(campaign.timeline.dropFirst(3).enumerated()), id: \.offset) { _, t in
                                    HStack(spacing: 8) {
                                        Circle().fill(SH.red).frame(width: 6, height: 6)
                                        Text(t.0).font(.sh(13)).foregroundStyle(SH.muted)
                                        Spacer()
                                        Text(t.1).font(.sh(13, .semibold)).foregroundStyle(SH.ink)
                                    }
                                }
                            }
                        }
                        section("ที่อยู่ในการจัดส่ง") {
                            HStack(alignment: .top) {
                                // ที่อยู่ที่กรอกใน Star Profile (ขั้น "ส่งของไปที่ไหน?") — ไม่ใช่ค่าตายตัว
                                let a = flow.addressInfo
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(a.name).font(.sh(14, .bold)).foregroundStyle(SH.ink)
                                    Text(a.tel).font(.sh(13)).foregroundStyle(SH.muted)
                                    Text([a.address, a.sub, a.zip].filter { !$0.isEmpty }.joined(separator: " ")).font(.sh(13)).foregroundStyle(SH.muted).lineSpacing(2)
                                }
                                Spacer()
                                HStack(spacing: 4) { PIcon(.pencilSimple, size: 14, weight: .regular); Text("แก้ไขที่อยู่").font(.sh(12, .semibold)) }
                                    .foregroundStyle(SH.red)
                            }
                        }
                        section("ข้อมูลที่ควรรู้ก่อนตอบรับ") {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(["ต้องส่งดราฟต์รีวิวภายในเวลาที่กำหนด และโพสต์จริงหลังดราฟต์ผ่านเท่านั้น",
                                         "หากไม่ส่งรีวิวตามกำหนด จะถูกตัดสิทธิ์และไม่สามารถลงทะเบียนกิจกรรมอื่นได้",
                                         "ของรางวัลจะจัดส่งตามที่อยู่ข้างต้น กรุณาตรวจสอบให้ถูกต้อง"], id: \.self) { t in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•").font(.sh(13)).foregroundStyle(SH.muted)
                                        Text(t).font(.sh(13)).foregroundStyle(SH.muted).lineSpacing(2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SH.line, lineWidth: 1))
                    .padding(.horizontal, 16)
                    ForEach(campaign.acceptQuestions) { q in
                        VStack(alignment: .leading, spacing: 8) {
                            (Text("* ").foregroundStyle(SH.red) + Text(q.q).foregroundStyle(SH.ink)).font(.sh(14, .semibold))
                            Menu {
                                ForEach(q.options, id: \.self) { o in Button(o) { answer = o } }
                            } label: {
                                HStack {
                                    Text(answer ?? "เลือกคำตอบ").font(.sh(15)).foregroundStyle(answer == nil ? SH.hint : SH.ink)
                                    Spacer()
                                    PIcon(.caretDown, size: 14).foregroundStyle(SH.hint)
                                }
                                .padding(.horizontal, 14).frame(height: 46)
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(SH.line, lineWidth: 1))
                            }
                        }
                        .padding(16)
                    }
                    HStack(spacing: 8) {
                        PIcon(.calendarBlank, size: 14, weight: .regular).foregroundStyle(SH.muted)
                        Text("เหลือเวลาตอบรับ").font(.sh(13, .semibold)).foregroundStyle(SH.ink)
                        Text("1 : 23 : 59 : 12").font(.sh(13, .bold)).foregroundStyle(SH.ink).monospacedDigit()
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    Color.clear.frame(height: 40)
                }
            }
            .background(.white)
            HStack(spacing: 10) {
                Button {
                    Haptics.impact(.light)
                    onDecline()
                } label: {
                    HStack(spacing: 8) { PIcon(.xCircle, size: 18, weight: .regular); Text("สละสิทธิ์").font(.sh(15, .semibold)) }
                        .foregroundStyle(SH.muted).frame(maxWidth: .infinity).frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(PK.fieldFill))
                }
                .buttonStyle(.plain)
                SHRedButton(title: "ตอบรับกิจกรรม", icon: .gift, action: onAccept)
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 8)
            .background(Color.white.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { SH.line.frame(height: 1) }
        }
        .background(Color.white.ignoresSafeArea())
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.sh(14, .bold)).foregroundStyle(SH.ink)
            content()
        }
    }
}
