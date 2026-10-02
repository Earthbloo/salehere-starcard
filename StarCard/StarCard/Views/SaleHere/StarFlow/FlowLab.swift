import SwiftUI
import PhosphorSwift

/// แผงควบคุมของ flow ใหม่ (= `panel.js` ของเว็บ): STATE ของ Unbox 15 ขั้น · ข้อมูลใน Star Profile · ฉากสำเร็จรูป · ล้างข้อมูล
///
/// เปิดจากปุ่มลอย "Lab" ที่อยู่ทุกหน้า (ผู้ใช้ 23 ก.ย. 2569: "ทำ button ลอยทุกที่ แล้ว config แบบนี้ได้เลยทุกหน้า")
/// กติกาเหมือนเว็บ: กระโดดไปขั้นไหน ขั้นก่อนหน้าติ๊กข้อมูลให้เอง · ติ๊กข้อมูลออกตอนอยู่ขั้นที่ต้องมีแล้ว = ย้อน state กลับ
struct FlowLab: View {
    @Environment(StarFlow.self) private var flow
    @Environment(PhotoStore.self) private var photos
    @Environment(\.dismiss) private var dismiss
    let stage: Int
    let campaign: StarCampaign
    /// กระโดด: หน้า + dialog ที่ต้องเปิด
    let onGo: (FlowScreen?, FlowDialog?) -> Void
    let toast: (String) -> Void
    @State private var confirmClear = false
    @State private var confirmClearAll = false
    @State private var confirmLab = false
    @State private var autofill = StarFlow.autofill

    private let red = SHColor.red
    private let ink = SHColor.ink
    private let muted = SHColor.textSecondary

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    labSection
                    stateSection
                    dataSection
                    presetSection
                    clearSection
                }
                .padding(16)
            }
            .background(Color.white)
            .navigationTitle("Unbox × StarCard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { PIcon(.x, size: 16).foregroundStyle(ink) }
                }
            }
        }
        .presentationDetents([.large])
        .confirmationDialog("ล้างข้อมูล flow ใหม่?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("ล้างข้อมูล", role: .destructive) { clearFlow() }
        } message: { Text("กลับเป็นผู้ใช้ใหม่: ยังไม่มี Star Profile ยังไม่ยืนยันตัวตน ยังไม่สมัครงาน") }
        .confirmationDialog("ล้างทั้งหมด?", isPresented: $confirmClearAll, titleVisibility: .visible) {
            Button("ล้างทั้งหมด", role: .destructive) { clearEverything() }
        } message: { Text("ลบข้อมูลของฉัน รูป ผลงาน และการ์ดทุกใบ ย้อนกลับไม่ได้") }
        .confirmationDialog(LabMode.isOn ? "ปิดโหมดลองทำ?" : "เปิดโหมดลองทำ?", isPresented: $confirmLab, titleVisibility: .visible) {
            Button(LabMode.isOn ? "ปิดแอป · คืนข้อมูลเดิม" : "ปิดแอป · เริ่มโหมดลองทำ") { LabMode.request(!LabMode.isOn) }
        } message: {
            Text(LabMode.isOn
                 ? "ข้อมูลเดิมก่อนเข้าโหมดจะถูกคืนกลับ ของที่แก้ระหว่างลองจะหาย (การ์ดกลางยังอยู่บน server) · เปิดแอปใหม่อีกครั้งหลังแอปปิด"
                 : "สำรองข้อมูลเดิมทั้งหมดไว้ก่อน แล้วคลังการ์ดจะเหลือใบเดียวคือการ์ดกลางที่ซิงก์กับ Android · เปิดแอปใหม่อีกครั้งหลังแอปปิด")
        }
    }

    // MARK: โหมดลองทำ — การ์ดกลางบน sync-server (ดู `LabSync`)

    private var labSection: some View {
        let sync = LabSync.shared
        return VStack(alignment: .leading, spacing: 8) {
            header("โหมดลองทำ", "การ์ดกลาง iOS ⇄ Android")
            HStack(spacing: 10) {
                Circle().fill(LabFab.color(sync.phase, on: LabMode.isOn)).frame(width: 9, height: 9)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LabMode.isOn ? LabFab.phaseText(sync.phase) + " · rev \(sync.rev)" : "ปิดอยู่ · ใช้ข้อมูลในเครื่อง")
                        .font(.sh(14, .bold)).foregroundStyle(ink)
                    if LabMode.isOn, let e = sync.lastEcho {
                        Text(e == 0 ? "รับของอีกเครื่องล่าสุด: ค่าตรงกันทุกจุด" : "รับของอีกเครื่องล่าสุด: ค่าเพี้ยน \(e) จุด (ดูรายละเอียดบนหน้าเว็บ)")
                            .font(.sh(12)).foregroundStyle(e == 0 ? SHColor.green : red)
                    }
                    Text(LabMode.server.absoluteString).font(.sh(11.5)).foregroundStyle(SHColor.textTertiary)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(PK.fieldFill))
            Button { confirmLab = true } label: {
                Text(LabMode.isOn ? "ปิดโหมดลองทำ · คืนข้อมูลเดิม" : "เปิดโหมดลองทำ")
                    .font(.sh(13, .bold)).foregroundStyle(LabMode.isOn ? ink : .white)
                    .frame(maxWidth: .infinity).frame(height: 42)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(LabMode.isOn ? PK.fieldFill : ink))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(ink.opacity(LabMode.isOn ? 0.2 : 0), lineWidth: 1))
            }
            .buttonStyle(.plain)
            Text("เก็บการ์ดเป็น JSON ก้อนเดียวที่ server กลาง แก้จากเครื่องไหนอีกเครื่องเห็นตาม · ข้อมูลเดิมถูกสำรองไว้ ปิดโหมดแล้วได้คืน")
                .font(.sh(11.5)).foregroundStyle(SHColor.textTertiary)
        }
    }

    private func header(_ t: String, _ sub: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(t).font(.sh(15, .heavy)).tracking(0.5).foregroundStyle(ink)
            Text(sub).font(.sh(11.5)).foregroundStyle(SHColor.textTertiary)
        }
    }

    // MARK: STATE ของ Unbox — 15 ขั้น ป้าย เดิม/แทรก · ขั้นปัจจุบันพื้นแดงอ่อน

    private var stateSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            header("STATE ของ UNBOX", "กดเพื่อไป · ขั้นก่อนหน้าติ๊กข้อมูลให้เอง")
            ForEach(StarFlow.stages) { s in
                let now = s.id == stage
                Button {
                    let r = flow.goto(s.id)
                    dismiss()
                    onGo(r.0, r.1)
                    if let n = s.note { toast(n) }
                } label: {
                    HStack(spacing: 12) {
                        Text(s.inserted ? "แทรก" : "เดิม").font(.sh(11, s.inserted ? .bold : .regular))
                            .foregroundStyle(s.inserted ? red : SHColor.textTertiary).frame(width: 34, alignment: .leading)
                        Text("\(s.id)").font(.sh(13, .bold)).foregroundStyle(s.id == 0 && now ? .white : ink)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(s.id == 0 && now ? SHColor.green : (now ? red.opacity(0.15) : PK.fieldFill)))
                        Text(s.title).font(.sh(14, now ? .bold : .regular)).foregroundStyle(now && s.inserted ? red : ink)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(now ? SHColor.redSoft : .clear))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: ข้อมูลใน Star Profile — ติ๊กเข้า/ออก + "ขอที่ขั้น N"

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("ข้อมูลใน STAR PROFILE", "ติ๊กออก = ย้อน state กลับไปขั้นที่ขอ")
            HStack(spacing: 4) {
                Text("Star Card:").font(.sh(14)).foregroundStyle(ink)
                Text(flow.isStar ? "มีแล้ว (เป็น STAR)" : flow.hasCard ? "มีแล้ว (ยังไม่ยืนยันตัวตน)" : "ยังไม่มี").font(.sh(14, .bold)).foregroundStyle(flow.hasCard ? PK.redDark : muted)
                Text("· กิจกรรม").font(.sh(14)).foregroundStyle(ink)
                Text(campaign.episode).font(.sh(14, .bold)).foregroundStyle(PK.redDark)
            }
            .padding(.bottom, 2)
            Toggle(isOn: $autofill) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("กรอกตัวอย่างให้").font(.sh(14, .bold)).foregroundStyle(ink)
                    Text("ช่องว่างมีค่าให้แล้ว (รวมรูป คลิป insight) · กดถัดไปได้เลย").font(.sh(11.5)).foregroundStyle(SHColor.textTertiary)
                }
            }
            .tint(red)
            .onChange(of: autofill) { _, v in StarFlow.autofill = v }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(PK.fieldFill))

            ForEach(Array(StarFlow.rules.enumerated()), id: \.offset) { _, r in
                let on = r.key.map(flow.has) ?? flow.isVerified
                Button {
                    Haptics.impact(.light)
                    if let back = flow.tick(r.key, on: !on, stage: stage) { jump(back) }
                } label: {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous).fill(on ? SH.blue : .white)
                            .frame(width: 20, height: 20)
                            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(on ? SH.blue : SHColor.strokeStrong, lineWidth: 1.3))
                            .overlay { if on { PIcon(.check, size: 11).foregroundStyle(.white) } }
                        Text(r.key?.label ?? "ยืนยันตัวตน (KYC)").font(.sh(14)).foregroundStyle(ink)
                        Spacer()
                        Text(r.askAt == StarFlow.profileOnly ? "ถามที่ Star Profile" : "ขอที่ขั้น \(r.askAt)").font(.sh(11.5)).foregroundStyle(SHColor.textTertiary)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 10) {
                Text("สถานะ KYC").font(.sh(12.5, .semibold)).foregroundStyle(muted)
                Picker("", selection: Binding(get: { flow.verify }, set: { v in
                    if v == .none, let back = flow.tick(nil, on: false, stage: stage) { jump(back) } else { flow.verify = v }
                })) {
                    Text("ยังไม่ทำ").tag(VerifyStatus.none); Text("รอตรวจ").tag(VerifyStatus.waiting); Text("ผ่าน").tag(VerifyStatus.approved)
                }
                .pickerStyle(.segmented)
            }
            .padding(.top, 4)
        }
    }

    // MARK: ฉากสำเร็จรูป

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("ฉากสำเร็จรูป", "ตั้งข้อมูล + สถานะงานในคลิกเดียว")
            PKWrap(spacing: 8) {
                ForEach(StarFlow.presets) { p in
                    Button {
                        flow.apply(p)
                        dismiss()
                        onGo(nil, nil)
                        toast("ตั้งฉาก: \(p.title)")
                    } label: {
                        HStack(spacing: 5) {
                            Text(p.title).font(.sh(12.5, .semibold)).foregroundStyle(ink)
                            if p.verify == .approved { PIcon(.sealCheck, size: 12, weight: .fill).foregroundStyle(GL.verified) }
                        }
                        .padding(.horizontal, 11).frame(height: 32)
                        .background(Capsule().fill(PK.fieldFill))
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    flow.revealSeen = false; dismiss()
                } label: {
                    Text("เล่น motion การ์ดเกิดใหม่").font(.sh(12.5, .semibold)).foregroundStyle(ink)
                        .padding(.horizontal, 11).frame(height: 32)
                        .background(Capsule().strokeBorder(SHColor.strokeStrong, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: ล้างข้อมูล

    private var clearSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            header("ล้างข้อมูล", "")
            HStack(spacing: 10) {
                Button { confirmClear = true } label: {
                    Text("ล้าง flow ใหม่").font(.sh(13, .bold)).foregroundStyle(red)
                        .frame(maxWidth: .infinity).frame(height: 42)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(SHColor.redSoft))
                }
                .buttonStyle(.plain)
                Button { confirmClearAll = true } label: {
                    Text("ล้างทั้งหมด + การ์ด").font(.sh(13, .bold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 42)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(red))
                }
                .buttonStyle(.plain)
            }
            Text("flow ใหม่ = สถานะงาน · ข้อมูล Star Profile · KYC · ยินยอม · การ์ดเกิด — ทั้งหมด = เพิ่มหน้า \"ข้อมูลของฉัน\" รูป ผลงาน และการ์ดทุกใบ")
                .font(.sh(11.5)).foregroundStyle(SHColor.textTertiary)
        }
        .padding(.bottom, 30)
    }

    private func jump(_ back: Int) {
        let r = flow.goto(back)
        toast("ย้อนกลับไป \"\(StarFlow.stages[back].title)\" เพราะข้อมูลนี้หายไป")
        dismiss()
        onGo(r.0, r.1)
    }

    private func clearFlow() {
        Haptics.impact(.heavy)
        flow.reset(); dismiss(); onGo(nil, nil)
        toast("ล้างข้อมูล flow ใหม่แล้ว")
    }

    private func clearEverything() {
        Haptics.impact(.heavy)
        flow.reset()
        Profile.me.resetAll(); photos.clearProfile(); Portfolio.shared.resetAll()
        CardLibrary.shared.records.map(\.id).forEach { CardLibrary.shared.delete($0) }
        dismiss(); onGo(nil, nil)
        toast("ล้างข้อมูลทั้งหมดแล้ว")
    }
}

/// ปุ่มลอย "Lab" — อยู่ทุกหน้าทุกที่ ลากขึ้นลงตามขอบขวาได้ (จำตำแหน่งไว้)
struct LabFab: View {
    /// ซ่อนปุ่มตอนแคปจอ: เปิดแอปด้วย `-hideLab YES` (หรือ `defaults write … hideLab -bool YES`) — แผง lab ยังเปิดได้จากกดค้างแถบแดง
    static var hidden: Bool { UserDefaults.standard.bool(forKey: "hideLab") }

    let action: () -> Void
    @AppStorage("labFab.y") private var savedY: Double = 0.55
    @State private var drag: CGFloat = 0
    private var sync: LabSync { LabSync.shared }

    /// ป้ายโหมดลองทำ: rev ที่ถืออยู่ + ผลตรวจล่าสุดถ้าเพี้ยน
    private var badge: String {
        if case .offline = sync.phase { return "ลองทำ · ต่อไม่ได้" }
        if let e = sync.lastEcho, e > 0 { return "ลองทำ r\(sync.rev) · เพี้ยน \(e)" }
        return "ลองทำ r\(sync.rev)"
    }

    static func color(_ p: LabSync.Phase, on: Bool) -> Color {
        guard on else { return SHColor.textTertiary }
        switch p {
        case .synced: return SHColor.green
        case .offline: return SHColor.red
        default: return Color(red: 1, green: 0.62, blue: 0.1)
        }
    }

    static func phaseText(_ p: LabSync.Phase) -> String {
        switch p {
        case .idle, .connecting: return "กำลังต่อ server"
        case .synced: return "ซิงก์แล้ว"
        case .pushing: return "กำลังส่ง"
        case .offline(let why): return "ต่อไม่ได้ · \(why)"
        }
    }

    var body: some View {
        GeometryReader { g in
            let y = min(max(g.size.height * savedY + drag, 80), g.size.height - 120)
            Button(action: action) {
                HStack(spacing: 5) {
                    if LabMode.isOn {
                        Circle().fill(Self.color(sync.phase, on: true)).frame(width: 7, height: 7)
                        Text(badge).font(.sh(11, .bold)).monospacedDigit()
                    } else {
                        PIcon(.arrowsClockwise, size: 11)
                        Text("Lab").font(.sh(11, .bold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.leading, 10).padding(.trailing, 14).frame(height: 30)
                .background(Capsule().fill(SHColor.ink.opacity(0.78)))
                .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 0.6))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            // ยื่นพ้นขอบขวานิดหน่อย — ไม่บังปุ่มของหน้า · ชิดขวาเสมอ ป้ายยาวขึ้น (โหมดลองทำ) ก็ไม่ล้นจอ
            .frame(width: g.size.width, alignment: .trailing)
            .offset(x: 6)
            .position(x: g.size.width / 2, y: y)
            .gesture(DragGesture(minimumDistance: 6)
                .onChanged { drag = $0.translation.height }
                .onEnded { v in
                    savedY = Double(min(max(g.size.height * savedY + v.translation.height, 80), g.size.height - 120) / g.size.height)
                    drag = 0
                })
        }
        .ignoresSafeArea()
    }
}
