import SwiftUI
import PhosphorSwift

/// หน้ารายละเอียดกิจกรรม Sale Here STAR — ตาม screenshot แอปหลัก 22 ก.ย. 2569
///
/// ปก · ชื่อ · วันที่+แชร์ · แท็บ "วิธีการร่วมกิจกรรม / รีวิว" · เนื้อหา · แถบล่างนับถอยหลัง + ปุ่มลงทะเบียน
struct StarCampaignPage: View {
    @Environment(StarFlow.self) private var flow
    let campaign: StarCampaign
    let onBack: () -> Void
    /// ปุ่มหลักแถบล่าง — ลงทะเบียน / ตอบรับ / รายละเอียดการรีวิว ตาม `flow.phase` (ผู้เรียกตัดสินว่าไปหน้าไหน)
    var onMain: () -> Void = {}
    /// "เติมเลย" ในบรรทัดใต้แถบล่าง (ลงทะเบียนแล้ว แต่การ์ดยังขาด) → Star Profile
    var onFill: () -> Void = {}
    /// กดค้างชื่อบนแถบแดง → แผง lab
    var onLab: () -> Void = {}

    private enum Tab { case howTo, reviews }
    @State private var tab: Tab = .howTo

    var body: some View {
        VStack(spacing: 0) {
            SHNavBar(title: "Sale Here STAR") {
                SHBarIcon(icon: .caretLeft, size: 26, action: onBack)
            } right: {
                SHBarIcon(icon: .headset)
                SHBarIcon(icon: .bell)
            }
            .onLongPressGesture(minimumDuration: 0.6) { Haptics.impact(.medium); onLab() }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Image(campaign.cover)
                        .resizable().aspectRatio(597 / 397, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    HStack(alignment: .top, spacing: 12) {
                        StarBrandLogo(name: campaign.logo, size: 40)
                        Text(campaign.headline)
                            .font(.sh(17, .semibold)).foregroundStyle(SH.ink)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 16).padding(.top, 14)
                    HStack {
                        HStack(spacing: 6) {
                            PIcon(.calendarBlank, size: 16, weight: .regular)
                            Text(campaign.dateRange).font(.sh(15, .medium))
                        }
                        .foregroundStyle(SH.muted)
                        Spacer()
                        Button {
                            Haptics.impact(.light)
                        } label: {
                            HStack(spacing: 6) {
                                PIcon(.shareFat, size: 16, weight: .regular)
                                Text("แชร์").font(.sh(14, .semibold))
                            }
                            .foregroundStyle(SH.red)
                            .padding(.horizontal, 12).frame(height: 34)
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(SH.red, lineWidth: 1.2))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 12)
                    SH.line.frame(height: 1)
                    tabs
                    SH.line.frame(height: 1)
                    Group {
                        switch tab {
                        case .howTo:
                            VStack(alignment: .leading, spacing: 14) {
                                Text(campaign.howTo)
                                    .font(.sh(15)).foregroundStyle(SH.ink)
                                    .lineSpacing(5)
                                if !campaign.reward.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("ของรางวัล").font(.sh(14, .bold)).foregroundStyle(SH.ink)
                                        Text(campaign.reward).font(.sh(14)).foregroundStyle(SH.muted)
                                        Text("จำนวนสิทธิ์").font(.sh(14, .bold)).foregroundStyle(SH.ink).padding(.top, 4)
                                        Text("\(campaign.quota) สิทธิ์ · ลงทะเบียนแล้ว \(campaign.registered) คน").font(.sh(14)).foregroundStyle(SH.muted)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(SH.page))
                                }
                                if !campaign.timeline.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Timeline แคมเปญ").font(.sh(14, .bold)).foregroundStyle(SH.ink)
                                        ForEach(Array(campaign.timeline.enumerated()), id: \.offset) { _, t in
                                            HStack {
                                                Text(t.0).font(.sh(13)).foregroundStyle(SH.muted)
                                                Spacer()
                                                Text(t.1).font(.sh(13, .semibold)).foregroundStyle(SH.ink)
                                            }
                                        }
                                    }
                                }
                            }
                        case .reviews:
                            VStack(spacing: 10) {
                                PIcon(.chatCircleText, size: 36, weight: .regular).foregroundStyle(SH.hint)
                                Text("ยังไม่มีรีวิวจากกิจกรรมนี้").font(.sh(14, .medium)).foregroundStyle(SH.hint)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 40)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 18)
                    .padding(.bottom, 24)
                }
            }
            .background(.white)
            bottomBar
        }
        .background(Color.white.ignoresSafeArea())
    }

    private var tabs: some View {
        HStack(spacing: 0) {
            tabItem(.howTo, icon: .clipboardText, title: "วิธีการร่วมกิจกรรม")
            tabItem(.reviews, icon: .notePencil, title: "รีวิว")
        }
        .frame(height: 50)
    }

    private func tabItem(_ t: Tab, icon: Ph, title: String) -> some View {
        Button {
            guard tab != t else { return }
            Haptics.impact(.light)
            withAnimation(Motion.snap) { tab = t }
        } label: {
            HStack(spacing: 8) {
                PIcon(icon, size: 20, weight: .regular)
                Text(title).font(.sh(15, tab == t ? .bold : .medium))
            }
            .foregroundStyle(tab == t ? SH.red : SH.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                (tab == t ? SH.red : .clear).frame(height: 3)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// แถบล่างติดจอ — บรรทัดบอกสถานะ + (flow ใหม่) บรรทัดบอกว่ามี Star Card หรือยัง + ปุ่มตาม `BrandCampaignState`
    private var bottomBar: some View {
        VStack(spacing: 10) {
            switch flow.phase {
            case .register:
                if let deadline = campaign.deadline {
                    clockLine("เหลือเวลาลงทะเบียน", deadline)
                    starLine
                } else {
                    descLine(.calendarBlank, "หมดเวลาลงทะเบียนแล้ว", tint: SH.hint)
                }
                SHRedButton(title: campaign.isOpen ? "ลงทะเบียนร่วมกิจกรรม" : "หมดเวลาลงทะเบียน", icon: .notePencil, enabled: campaign.isOpen, action: onMain)
            case .registered:
                descLine(.calendarBlank, "รอประกาศชื่อผู้ได้รับคัดเลือก")
                registeredLine
                SHGreenButton(title: "คุณได้ลงทะเบียนแล้ว", icon: .checkCircle)
            case .waitingAcceptQuota:
                clockLine("เหลือเวลาตอบรับ", Date().addingTimeInterval(1 * 86400 + 23 * 3600 + 59 * 60))
                SHRedButton(title: "ตอบรับกิจกรรม", icon: .gift, action: onMain)
            case .acceptedQuota:
                if flow.draftApproved && !flow.reviewed {
                    // ดราฟต์ผ่านแล้ว = สถานะ `waitingReview` ของแอปหลัก (แอปหลักโชว์ใต้แท็บ "รีวิว")
                    clockLine("เหลือเวลาส่งลิงก์รีวิว", Date().addingTimeInterval(23 * 3600 + 59 * 60))
                    SHRedButton(title: "ส่งลิงก์รีวิว", icon: .paperPlaneTilt, action: onMain)
                } else {
                    descLine(.package, flow.reviewed ? "เสร็จสิ้นการส่งรีวิวกิจกรรม" : flow.order.label, tint: flow.reviewed ? SHColor.green : SH.ink)
                    SHRedButton(title: flow.reviewed ? "ดูโพสต์รีวิว" : "รายละเอียดการรีวิว", icon: .clipboardText, action: onMain)
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { SH.line.frame(height: 1) }
        .shadow(color: .black.opacity(0.06), radius: 10, y: -4)
        .animation(Motion.settle, value: flow.phase)
    }

    private func clockLine(_ label: String, _ deadline: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let left = max(0, Int(deadline.timeIntervalSince(ctx.date)))
            HStack(spacing: 8) {
                PIcon(.calendarBlank, size: 18, weight: .regular).foregroundStyle(SH.red)
                Text(label).font(.sh(14, .semibold)).foregroundStyle(SH.ink)
                Spacer(minLength: 8)
                SHClock(seconds: left)
            }
        }
    }

    private func descLine(_ icon: Ph, _ text: String, tint: Color = SH.muted) -> some View {
        HStack(spacing: 8) {
            PIcon(icon, size: 18, weight: .regular).foregroundStyle(tint)
            Text(text).font(.sh(14, .semibold)).foregroundStyle(tint)
            Spacer()
        }
    }

    /// ป้ายสถานะ STAR + คำบอกเงื่อนไขตรง ๆ ก่อนกดปุ่ม (= บรรทัด `.lvl-chip` ของ flow ใหม่)
    private var starLine: some View {
        let missing = flow.registerSteps.count
        // คำ STAR ในป้าย = ตรา ST★R (มีดาวในตัวแล้ว ไม่ต้องนำหน้าด้วย ★)
        let chip = flow.isStar ? "STAR แล้ว" : flow.hasCard ? "☆ ยังไม่ยืนยันตัวตน" : "☆ ยังไม่เป็น STAR"
        let hint = !flow.hasCard ? "งานนี้รับเฉพาะ STAR · กดลงทะเบียนแล้วสมัครเป็น STAR ก่อน (ครั้งเดียว ใช้ได้ทุกงาน)"
            : missing > 0 ? "แบรนด์คัดเลือกจากการ์ด · ขอเติมอีก \(missing) อย่างก่อนส่งใบสมัคร"
            : flow.isStar ? "การ์ดคุณครบแล้ว · ส่งใบสมัครได้เลย" : "การ์ดพร้อม · ยืนยันตัวตนด้วย แบรนด์จะคัดเลือกง่ายขึ้น"
        return HStack(alignment: .top, spacing: 6) {
            StarLevelChip(text: chip)
            Text(hint).font(.sh(12)).foregroundStyle(SH.ink).lineSpacing(2)
            Spacer(minLength: 0)
        }
    }

    private var registeredLine: some View {
        let left = StarRow.all.filter { r in
            guard let k = r.key else { return !flow.isVerified }
            return [.rate, .about, .insight, .province, .availability].contains(k) && !flow.has(k)
        }
        return HStack(alignment: .center, spacing: 6) {
            StarLevelChip(text: flow.isStar ? "STAR" : "⏳ รอยืนยันตัวตน")
            if let first = left.first {
                Text("แบรนด์เปิดดูการ์ดคุณได้แล้ว · ยังขาด\(first.title)ที่แบรนด์มักถาม").font(.sh(12)).foregroundStyle(SH.ink).lineSpacing(2)
                Spacer(minLength: 4)
                Button {
                    Haptics.impact(.light)
                    onFill()
                } label: {
                    Text("เติมเลย").font(.sh(12, .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 10).frame(height: 26).background(Capsule().fill(SH.ink))
                }
                .buttonStyle(.plain)
            } else {
                Text("แบรนด์เปิดดูการ์ดคุณได้แล้ว · มีครบทุกอย่างที่แบรนด์ขอดู").font(.sh(12)).foregroundStyle(SH.ink)
                Spacer(minLength: 0)
            }
        }
    }

}

/// กล่องเลขนับถอยหลังของแอปหลัก (วัน : ชม. : นาที : วินาที) — ใช้ทั้งแถบล่างหน้ากิจกรรมและหน้าส่งลิงก์
struct SHClock: View {
    let seconds: Int

    var body: some View {
        let days = seconds / 86400
        let h = (seconds % 86400) / 3600, m = (seconds % 3600) / 60, s = seconds % 60
        return HStack(spacing: 4) {
            if days > 0 { box(String(days), wide: true); colon }
            box(String(format: "%02d", h)); colon
            box(String(format: "%02d", m)); colon
            box(String(format: "%02d", s))
        }
    }

    private var colon: some View {
        Text(":").font(.sh(14, .bold)).foregroundStyle(SH.ink)
    }

    private func box(_ t: String, wide: Bool = false) -> some View {
        Text(t)
            .font(.sh(13, .bold)).foregroundStyle(.white)
            .monospacedDigit()
            .frame(minWidth: wide ? 30 : 26, minHeight: 24)
            .padding(.horizontal, 2)
            .background(SH.clockBox, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}

/// ป้ายเล็ก "★ STAR" / "☆ ยังไม่เป็น STAR" ใต้นาฬิกา
struct StarLevelChip: View {
    let text: String
    var body: some View {
        StarText(text, size: 11, weight: .bold, color: SH.ink).fixedSize()
            .padding(.horizontal, 8).frame(height: 22)
            .background(Capsule().fill(PK.fieldFill))
    }
}

/// ปุ่มเขียวเต็มกว้าง กดไม่ได้ — "คุณได้ลงทะเบียนแล้ว" ของแอปหลัก
struct SHGreenButton: View {
    let title: String
    var icon: Ph? = nil
    var body: some View {
        HStack(spacing: 8) {
            if let icon { PIcon(icon, size: 20, weight: .regular) }
            Text(title).font(.sh(16, .semibold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity).frame(height: 48)
        .background(SHColor.green, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
