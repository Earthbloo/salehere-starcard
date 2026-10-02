import SwiftUI
import PhosphorSwift

/// ยืนยันตัวตนจำลอง (KYC ของแอปหลัก ย่อเหลือ 4 ขั้น): เลือกเอกสาร → วิธีถ่าย → ถ่ายบัตร + ใบหน้า → AI ตรวจ → ผ่าน
///
/// จบแล้ว `verify = .approved` ทันที — ระบบจริงอนุมัติอัตโนมัติ ไม่มีช่วง "รอทีมงานตรวจ" (ผู้ใช้ 1 ต.ค. 2569)
struct KycMockPage: View {
    @Environment(StarFlow.self) private var flow
    let onClose: () -> Void
    let onDone: () -> Void

    private enum Step { case type, howTo, card, face, checking, done }
    @State private var step: Step = .type
    @State private var doc = "บัตรประชาชน"

    var body: some View {
        VStack(spacing: 0) {
            SHNavBar(title: "ยืนยันตัวตน") {
                SHBarIcon(icon: .caretLeft, size: 26) {
                    switch step {
                    case .type: onClose()
                    case .howTo: step = .type
                    case .card: step = .howTo
                    case .face: step = .card
                    default: break
                    }
                }
            } right: {
                Color.clear.frame(width: 32, height: 32)
            }
            Group {
                switch step {
                case .type: typePage
                case .howTo: howToPage
                case .card: cameraPage(face: false)
                case .face: cameraPage(face: true)
                case .checking: checkingPage
                case .done: donePage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white.ignoresSafeArea())
    }

    private var typePage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("เลือกเอกสารที่ใช้ยืนยันตัวตน").font(.sh(17, .bold)).foregroundStyle(SH.ink)
            ForEach(["บัตรประชาชน", "หนังสือเดินทาง"], id: \.self) { d in
                Button {
                    Haptics.impact(.light)
                    doc = d
                } label: {
                    HStack(spacing: 12) {
                        PIcon(.identificationCard, size: 24, weight: .regular).foregroundStyle(SH.red)
                        Text(d).font(.sh(15, .semibold)).foregroundStyle(SH.ink)
                        Spacer()
                        Circle().strokeBorder(doc == d ? SH.red : SH.line, lineWidth: doc == d ? 6 : 1.2).frame(width: 22, height: 22)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(doc == d ? SH.red : SH.line, lineWidth: 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
            SHRedButton(title: "ถัดไป") { step = .howTo }
        }
        .padding(16)
    }

    private var howToPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("วิธีถ่าย\(doc)").font(.sh(17, .bold)).foregroundStyle(SH.ink)
            ForEach(["วางบัตรบนพื้นเรียบ ไม่มีแสงสะท้อน", "ให้บัตรอยู่ในกรอบ เห็นครบทั้ง 4 มุม", "ถ่ายใบหน้าตรง ไม่ใส่หมวก/แว่นดำ", "ข้อมูลใช้เพื่อยืนยันตัวตนเท่านั้น"], id: \.self) { t in
                HStack(alignment: .top, spacing: 10) {
                    PIcon(.checkCircle, size: 18, weight: .fill).foregroundStyle(SHColor.green)
                    Text(t).font(.sh(14)).foregroundStyle(SH.ink)
                }
            }
            Spacer()
            SHRedButton(title: "เริ่มถ่าย", icon: .camera) { step = .card }
        }
        .padding(16)
    }

    private func cameraPage(face: Bool) -> some View {
        ZStack {
            Color(red: 0.08, green: 0.09, blue: 0.11)
            VStack(spacing: 18) {
                Text(face ? "ถ่ายใบหน้าของคุณ" : "ถ่ายด้านหน้า\(doc)").font(.sh(16, .bold)).foregroundStyle(.white)
                Group {
                    if face {
                        Ellipse().strokeBorder(.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [8, 6])).frame(width: 220, height: 290)
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 2).frame(width: 300, height: 190)
                    }
                }
                Text(face ? "ให้ใบหน้าอยู่ในกรอบ" : "ให้บัตรอยู่ในกรอบ เห็นครบ 4 มุม").font(.sh(13)).foregroundStyle(.white.opacity(0.7))
                Spacer()
                Button {
                    Haptics.impact(.medium)
                    if face { step = .checking; check() } else { step = .face }
                } label: {
                    Circle().fill(.white).frame(width: 68, height: 68)
                        .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 4).padding(-6))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 30)
            }
            .padding(.top, 30)
        }
    }

    private var checkingPage: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large).tint(SH.red)
            Text("AI กำลังตรวจสอบข้อมูล…").font(.sh(15, .semibold)).foregroundStyle(SH.ink)
        }
    }

    private var donePage: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                Circle().fill(SHColor.greenSoft).frame(width: 96, height: 96)
                PIcon(.checkCircle, size: 56, weight: .fill).foregroundStyle(SHColor.green)
            }
            Text("ยืนยันตัวตนสำเร็จ").font(.sh(19, .bold)).foregroundStyle(SH.ink)
            Text("ตรารับรอง Sale Here บนการ์ดของคุณปลดล็อกแล้ว").font(.sh(14)).foregroundStyle(SH.muted).multilineTextAlignment(.center).lineSpacing(3)
            Spacer()
            SHRedButton(title: "เสร็จสิ้น") {
                flow.verify = .approved
                onDone()
            }
        }
        .padding(16)
    }

    private func check() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            Haptics.impact(.medium)
            withAnimation(Motion.settle) { step = .done }
        }
    }
}
