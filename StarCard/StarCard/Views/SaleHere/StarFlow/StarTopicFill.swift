import SwiftUI

/// กรอกหัวข้อ Star Profile ข้อเดียว (หรือหลายข้อ) จากที่อื่นในแอป — ตู้ widget · ช่องประบนการ์ด
///
/// ห่อ `StarWizard` แบบ `one` + KYC จำลอง ไว้ในหน้าเดียว ไม่ต้องพึ่ง `SaleHereShell`
struct StarTopicFill: View {
    let steps: [WizStep]
    /// true = กรอกจบ · false = ออกกลางทาง
    let onDone: (Bool) -> Void

    @State private var flow = StarFlow.shared
    @State private var kyc: (() -> Void)?
    @State private var toastText: String?

    var body: some View {
        ZStack {
            StarWizard(kind: .one, campaign: StarCampaign.mock[0], steps: steps,
                       onFinish: { _ in onDone(true) },
                       onExit: { _, _ in onDone(false) },
                       onKyc: { done in withAnimation(Motion.page) { kyc = done } },
                       toast: { t in
                           withAnimation(Motion.snap) { toastText = t }
                           DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { withAnimation(Motion.snap) { toastText = nil } }
                       })
            if let done = kyc {
                KycMockPage(onClose: { withAnimation(Motion.page) { kyc = nil } },
                            onDone: { withAnimation(Motion.page) { kyc = nil }; done() })
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
            if let toastText {
                VStack { Spacer(); FlowToast(text: toastText) }.zIndex(2).allowsHitTesting(false)
            }
        }
        .environment(flow)
        .preferredColorScheme(.light)
    }
}
