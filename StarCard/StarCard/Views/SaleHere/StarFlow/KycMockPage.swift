import SwiftUI
import PhosphorSwift

/// ยืนยันตัวตน = UI ของ salehere-ios ยกมาทั้งชุด (ผู้ใช้ 6 ต.ค. 2569: "ไปเอาของ salehere-ios มาเลย ไม่ต้องทำใหม่")
///
/// ลำดับจริงของแอปหลัก (bottom sheet `BaseBottomSheetNavigationController`):
///   เลือกเอกสาร (`VerifyTypeUser`) → วิธีการถ่ายรูปบัตร (`VerifyInstruction`) → กล้อง (`CameraView`) → วิธีการถ่ายรูปคู่บัตร → กล้อง
///   → ฟอร์ม (`VerifyUserStatusForm`) → modal "ระบบกำลังประมวลผลภาพ" → OCR ผ่าน = prompt "กรุณายืนยันการส่งข้อมูล" → "ยืนยันตัวตนเสร็จสมบูรณ์" (approved ทันที)
///   OCR ไม่ผ่าน (lab "AI ไม่ผ่าน") = modal เตือน → ฟอร์มเติมค่าจาก OCR ให้กดส่งเอง → prompt (มีคำเตือนแดง) → "ส่งคำขอยืนยันตัวตนสำเร็จ" (waiting)
///   ตีกลับแล้วเข้ามาใหม่ = เปิดฟอร์มพร้อมการ์ดสถานะแดง + เหตุผล (= `CheckTypeUser` → `VerifyUserStatusForm` สถานะ reject)
/// ข้อความทุกคำ = `Localized.strings` · สี = `UIColorExtension` · ขนาด/ระยะ = xib/storyboard · รูป = asset ชุด NewVerifyUser + VerifyUser (คัดลอกมาที่ SaleHereVerify)
struct KycMockPage: View {
    @Environment(StarFlow.self) private var flow
    var deadline: Date? = nil
    var episode: String? = nil
    let onClose: () -> Void
    let onDone: () -> Void

    private enum Step { case type, instructionID, cameraID, instructionFace, cameraFace, form }
    private enum Modal { case loading, ocrError, prompt, successAuto, successManual, exit }
    @State private var step: Step = .type
    @State private var passport = false
    /// กล้อง: ถ่ายแล้ว รอกด "ยืนยัน" / "ถ่ายใหม่"
    @State private var shot = false
    @State private var modal: Modal? = nil
    /// OCR ไม่ผ่าน → ตกไปกรอกมือ (ฟอร์มเติมค่าจาก OCR ให้ · prompt มีคำเตือนแดง · จบเป็น waiting)
    @State private var manual = false
    @State private var hasImages = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            if step == .cameraID || step == .cameraFace { camera.transition(.opacity) } else { sheet }
            if let modal { modalView(modal).transition(.opacity).zIndex(2) }
        }
        .animation(Motion.snap, value: modal == nil)
        .onAppear {
            // ตีกลับ = แอปหลักเปิดฟอร์มเดิมที่กรอกไว้ให้เลย พร้อมการ์ดสถานะแดง
            if flow.verify == .rejected { hasImages = true; manual = true; step = .form }
        }
    }

    // MARK: - bottom sheet (BaseBottomSheetNavigationController: ขาว · มุมบน 16 · หัว 88/66)

    private var sheet: some View {
        VStack(spacing: 0) {
            switch step {
            case .type: typePage
            case .instructionID: instructionPage(face: false)
            case .instructionFace: instructionPage(face: true)
            case .form: formPage
            default: EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
        .padding(.top, 44)
        .ignoresSafeArea(edges: .bottom)
    }

    private func header(_ title: String, subtitle: String? = nil, back: (() -> Void)? = nil) -> some View {
        ZStack {
            VStack(spacing: 2) {
                Text(title).font(.sh(20, .bold)).foregroundStyle(KV.gray1000).frame(height: 30)
                if let subtitle { Text(subtitle).font(.sh(14)).foregroundStyle(KV.gray500) }
            }
            .frame(maxWidth: .infinity)
            HStack {
                if let back {
                    Button(action: back) { Image("ic-back-button").resizable().scaledToFit().frame(width: 28, height: 28).frame(width: 36, height: 44).contentShape(Rectangle()) }
                        .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 36, height: 44)
                }
                Spacer()
                Button { modal = .exit } label: { Image("ic-close-button").resizable().scaledToFit().frame(width: 28, height: 28).contentShape(Rectangle()) }
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 24)
        .frame(height: subtitle == nil ? 66 : 88, alignment: .top)
        .background(Color.white)
    }

    /// ปุ่มแดงมาตรฐาน (BaseRedButtonV4 / ปุ่มในโค้ด: Red600 · มุม 8 · Medium 14 · สูง 44)
    private func redButton(_ title: String, icon: String? = nil, height: CGFloat = 44, radius: CGFloat = 8, action: @escaping () -> Void) -> some View {
        Button { Haptics.impact(.light); action() } label: {
            HStack(spacing: 4) {
                if let icon { Image(icon).resizable().scaledToFit().frame(width: 16, height: 16) }
                Text(title).font(.sh(14, .medium))
            }
            .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: height)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(KV.red600))
        }
        .buttonStyle(.plain)
    }

    private func bottomBar<B: View>(@ViewBuilder _ content: () -> B) -> some View {
        VStack(spacing: 8) {
            KV.sep.frame(height: 1)
            content().padding(.horizontal, 16).padding(.top, 15).padding(.bottom, 24)
        }
        .background(Color.white)
    }

    // MARK: - 1. เลือกเอกสาร (VerifyTypeUserViewController.xib)

    private var typePage: some View {
        VStack(spacing: 0) {
            header("ยืนยันตัวตน", subtitle: "กรุณาเลือกวิธียืนยันตัวตนเพื่อความปลอดภัย")
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Image("ic-verify-user-icon").resizable().scaledToFit().frame(width: 153, height: 153)
                    VStack(spacing: 8) {
                        infoRow(icon: "ic-select-verify", title: "การยืนยันตัวตน",
                                body: "บัญชีที่ได้รับการตรวจสอบแล้วจะมีเครื่องหมายติ๊กถูกสีเขียวแสดงอยู่หน้าชื่อเพื่อแสดงว่าได้รับการยืนยันตัวตน\nจากเซลเฮียร์แล้ว")
                        infoRow(icon: "ic-select-verify-protect", title: "ความปลอดภัยของข้อมูล",
                                body: "ข้อมูลของคุณจะถูกจัดเก็บอย่างปลอดภัยตามนโยบาย\nความปลอดภัยความเป็นส่วนตัวของเซลเฮียร์", readMore: true)
                    }
                    .padding(.horizontal, 16)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("เลือกเพื่อยืนยันตัวตน").font(.sh(16, .semibold)).foregroundStyle(KV.gray1000).frame(height: 24)
                        typeCard(icon: "ic-thai-id", title: "บัตรประจำตัวประชาชน", on: !passport) { passport = false }
                        typeCard(icon: "ic-passport", title: "Passport", on: passport) { passport = true }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 24).padding(.bottom, 84)
            }
            bottomBar { redButton("ยืนยัน") { withAnimation(Motion.page) { step = .instructionID } } }
        }
    }

    private func infoRow(icon: String, title: String, body: String, readMore: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(icon).resizable().scaledToFit().frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.sh(14, .semibold)).foregroundStyle(KV.gray1000)
                Text(body).font(.sh(14, .medium)).foregroundStyle(KV.gray600).lineSpacing(1)
                if readMore { Text("อ่านเพิ่มเติม").font(.sh(14, .medium)).foregroundStyle(KV.ocean).underline() }
            }
            Spacer(minLength: 0)
        }
    }

    private func typeCard(icon: String, title: String, on: Bool, pick: @escaping () -> Void) -> some View {
        Button { Haptics.impact(.light); pick() } label: {
            HStack(spacing: 8) {
                Image(icon).resizable().scaledToFit().frame(width: 40, height: 24).frame(width: 56)
                Text(title).font(.sh(14, .medium)).foregroundStyle(KV.gray1000)
                Spacer()
                Image(on ? "ic-radio-select" : "ic-radio-unselect").resizable().frame(width: 20, height: 20).frame(width: 36)
            }
            .frame(height: 56)
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(KV.gray200, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 2. วิธีการถ่ายรูป (VerifyInstructionViewController)

    private static let idRules = ["✅  วางบัตรประชาชนบนพื้นเรียบ โดยใช้พื้นหลังที่ไม่มีลวดลาย สีเรียบ และไม่มีวัตถุอื่นอยู่ในภาพ",
                                  "✅  ถ่ายให้เห็นบัตรประชาชนทั้งใบโดยไม่มีส่วนใดถูกตัดออกจากกรอบภาพ",
                                  "✅  ใช้แสงสว่างที่เหมาะสมหลีกเลี่ยงเงาหรือแสงสะท้อนที่อาจบดบังข้อมูลบนบัตรประชาชน",
                                  "✅  ภาพต้องมีความคมชัดสามารถอ่านข้อมูลบนบัตรประชาชนได้อย่างชัดเจน ไม่พร่ามัว",
                                  "🚫  ห้ามแก้ไขหรือปรับแต่งรูปภาพ เช่น การเบลอข้อมูลการเพิ่มหรือลบรายละเอียดในภาพ",
                                  "🚫  ห้ามใช้ภาพถ่ายจากหน้าจอ อุปกรณ์อิเล็กทรอนิกส์หรือสำเนาเอกสาร ต้องเป็นรูปถ่ายบัตรประชาชนจริงเท่านั้น"]
    private static let faceRules = ["✅  ถ่ายภาพตนเองพร้อมถือบัตรประชาชน โดยให้เห็นใบหน้าและบัตรประชาชนอย่างชัดเจน",
                                    "✅  บัตรประชาชนต้องชัดเจน ตัวอักษรต้องอ่านได้ ไม่ถูกบังหรือสะท้อนแสง",
                                    "✅  ใช้แสงสว่างที่เหมาะสมหลีกเลี่ยงเงาหรือแสงสะท้อนที่อาจบดบังข้อมูลบนบัตรประชาชน",
                                    "✅  ถือบัตรประชาชนด้วยมือของตนเองและให้เห็นข้อมูลบนบัตรประชาชนอย่างครบถ้วน",
                                    "🚫  ห้ามแก้ไขหรือปรับแต่งรูปภาพ เช่น การเบลอข้อมูลการเพิ่มหรือลบรายละเอียดในภาพ",
                                    "🚫  ห้ามใช้ภาพถ่ายจากหน้าจอ อุปกรณ์อิเล็กทรอนิกส์หรือสำเนาเอกสาร ต้องเป็นรูปถ่ายคู่กับบัตรประชาชนจริงเท่านั้น"]

    private func instructionPage(face: Bool) -> some View {
        VStack(spacing: 0) {
            header(face ? "วิธีการถ่ายรูปคู่บัตรประชาชน" : "วิธีการถ่ายรูปบัตรประชาชน",
                   back: { withAnimation(Motion.page) { step = face ? .cameraID : .type; shot = false } })
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(face ? "ic-face-thaiid-correct" : "ic-thaiid-correct").resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Image(face ? "ic-face-thaiid-incorrect" : "ic-thaiid-incorrect").resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    Text("ข้อกำหนดและเงื่อนไข").font(.sh(14, .semibold)).foregroundStyle(KV.gray1000)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(face ? Self.faceRules : Self.idRules, id: \.self) { r in
                            Text(r).font(.sh(14, .medium)).foregroundStyle(KV.gray1000).lineSpacing(2)
                        }
                    }
                }
                .padding(16).padding(.bottom, 60)
            }
            bottomBar { redButton("ถ่ายรูป", icon: "ic-camera-outline") { shot = false; withAnimation(Motion.page) { step = face ? .cameraFace : .cameraID } } }
        }
    }

    // MARK: - 3. กล้อง (CameraViewController · BaseBlackNavigationController)

    private var camera: some View {
        let face = step == .cameraFace
        return VStack(spacing: 0) {
            ZStack {
                Text(face ? "ถ่ายรูปคู่บัตรประชาชน" : "ถ่ายรูปบัตรประชาชน").font(.sh(16, .medium)).foregroundStyle(.white)
                HStack {
                    Spacer()
                    Button { withAnimation(Motion.page) { step = face ? .instructionFace : .instructionID; shot = false } } label: {
                        Image("ic-x-outline").resizable().scaledToFit().frame(width: 24, height: 24).frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 44).padding(.top, 54)
            if shot {
                Text("ยืนยันข้อมูล").font(.sh(14, .semibold)).foregroundStyle(.white).padding(.top, 16)
                Text("กรุณาตรวจสอบความชัดเจนของภาพบัตรของคุณ").font(.sh(12, .medium)).foregroundStyle(.white).padding(.top, 4)
            } else {
                Text(face ? "ตรวจสอบให้มั่นใจว่าเห็นใบหน้า\nและบัตรประชาชนอยู่ในกรอบและชัดเจน"
                          : "กรุณาวางรูปให้ตรงตามกรอบ และ ไม่วางนิ้วมือบดบังรูป ตัวอักษร\nหรือสัญลักษณ์บนหน้าบัตร")
                    .font(.sh(12, .medium)).foregroundStyle(.white).multilineTextAlignment(.center).lineSpacing(2).padding(.top, 16)
            }
            Spacer()
            // viewfinder จำลอง: ถ่ายแล้ว = ภาพนิ่งเทา (ไม่มีกล้องจริงใน simulator) · ยังไม่ถ่าย = กรอบ asset เดิมเต็มความกว้าง
            ZStack {
                if shot { KycMockPhoto(face: face).padding(.horizontal, 16) }
                Image(face ? "ic-id-card-form-with-face" : "ic-id-card-form").resizable().scaledToFit().opacity(shot ? 0.35 : 1)
            }
            Spacer()
            if shot {
                HStack(spacing: 12) {
                    Button { Haptics.impact(.light); shot = false } label: {
                        HStack(spacing: 6) { Image("ic-arraows-counter-clockwise-outline").renderingMode(.template).resizable().scaledToFit().frame(width: 18, height: 18); Text("ถ่ายใหม่").font(.sh(14, .medium)) }
                            .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 44)
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(.white, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    redButton("ยืนยัน", icon: "ic-check-outline") {
                        shot = false
                        if face { hasImages = true; withAnimation(Motion.page) { step = .form } } else { withAnimation(Motion.page) { step = .instructionFace } }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 40)
            } else {
                Button { Haptics.impact(.medium); withAnimation(Motion.snap) { shot = true } } label: {
                    Image("ic-take-photo").resizable().scaledToFit().frame(width: 72, height: 72)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea()
    }

    // MARK: - 4. ฟอร์ม (VerifyUserStatusFormViewController · สถานะ nil หรือ reject)

    private var formPage: some View {
        VStack(spacing: 0) {
            header("ยืนยันตัวตน", back: flow.verify == .rejected ? nil : { withAnimation(Motion.page) { step = .type } })
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if flow.verify == .rejected {
                        KycStatusCard(reason: flow.verifyReason)
                        descItem(icon: "ic-sealcheck-outline", title: "การยืนยันตัวตน",
                                 body: "บัญชีที่ได้รับการตรวจสอบแล้วจะมีเครื่องหมายติ๊กถูกสีเขียวแสดงอยู่หน้าชื่อเพื่อแสดงว่าได้รับการยืนยันตัวตน\nจากเซลเฮียร์แล้ว")
                        descItem(icon: "ic-shieldcheck-outline", title: "ความปลอดภัยของข้อมูล",
                                 body: "ข้อมูลของคุณจะถูกจัดเก็บอย่างปลอดภัยตามนโยบาย\nความปลอดภัยความเป็นส่วนตัวของเซลเฮียร์", readMore: true)
                    }
                    // Step 1
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Step 1 : ถ่ายรูป").font(.sh(16, .semibold)).foregroundStyle(KV.black2).frame(height: 24)
                        HStack(alignment: .top, spacing: 8) {
                            photoTile(caption: "หน้าบัตรประชาชน", empty: "ic-verify-idcard-148x74", face: false,
                                      note: hasImages ? (manual ? "รูปบัตรประชาชนสำหรับยืนยันตัวตน\nโปรดมั่นใจว่าชัดเจนและถูกต้อง" : "หน้าบัตรประชาชนอยู่ในกรอบ\nถูกต้องและชัดเจน") : nil,
                                      noteColor: manual ? KV.ocean : KV.emerald)
                            photoTile(caption: "รูปคู่บัตรประชาชน", empty: "ic-verify-face-148x74", face: true,
                                      note: hasImages ? (manual ? "ภาพไม่ถูกต้องหรือไม่ชัดเจน\nกรุณาตรวจสอบอีกครั้งก่อนส่ง" : "รูปคู่หน้าบัตรประชาชนอยู่ในกรอบ\nถูกต้องและชัดเจน") : nil,
                                      noteColor: manual ? KV.red600 : KV.emerald)
                        }
                        redButton("ถ่ายรูปบัตรประชาชนและรูปคู่ใหม่", icon: "ic-camera-white16", height: 36, radius: 10) {
                            withAnimation(Motion.page) { step = .instructionID }
                        }
                    }
                    .padding(.vertical, 8)
                    // Step 2
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Step 2 : กรอกข้อมูลส่วนตัว").font(.sh(16, .semibold)).foregroundStyle(KV.black2).frame(height: 24)
                        Text("ข้อมูลบัตรประชาชน").font(.sh(14, .semibold)).foregroundStyle(KV.gray1000).padding(.top, 16).padding(.bottom, 8)
                        field("เลขบัตรประชาชน", icon: "ic-IdentificationCard-outline", placeholder: "เลขบัตรประชาชน", value: KycOCR.idNo)
                        field("วันที่บัตรหมดอายุ", icon: "ic-creditcard-outline", placeholder: "เลือกวันที่บัตรหมดอายุ", value: KycOCR.expiry, select: true)
                        field("คำนำหน้าชื่อ", icon: "ic-usercircle-outline", placeholder: "เลือกคำนำหน้าชื่อ", value: KycOCR.prefix, select: true)
                        field("ชื่อ", suffix: " (ภาษาไทย)", icon: "ic-userlist-outline", placeholder: "ระบุชื่อ", value: KycOCR.first)
                        field("นามสกุล", suffix: " (ภาษาไทย)", icon: "ic-userlist-outline", placeholder: "ระบุนามสกุล", value: KycOCR.last)
                        field("วันเกิด", icon: "ic-calendarblank-outline", placeholder: "เลือกวันเดือนปีเกิด", value: KycOCR.dob, select: true)
                        Text("ข้อมูลที่อยู่").font(.sh(14, .semibold)).foregroundStyle(KV.gray1000).padding(.top, 16).padding(.bottom, 8)
                        field("รายละเอียดที่อยู่", suffix: " (ตามบัตรประชาชน)", icon: "ic-houseline-outline", placeholder: "บ้านเลขที่, ชื่อหมู่บ้าน, ห้อง, ชั้น, ถนน, ซอย", value: KycOCR.address)
                        field("รหัสไปรษณีย์", placeholder: "ระบุรหัสไปรษณีย์", value: KycOCR.zip)
                        field("ตำบล/แขวง", placeholder: "เลือกตำบล/แขวง", value: KycOCR.sub, select: true)
                        field("อำเภอ/เขต", placeholder: "เลือกอำเภอ/เขต", value: KycOCR.district, dim: true)
                        field("จังหวัด", placeholder: "เลือกจังหวัด", value: KycOCR.province, dim: true)
                    }
                    .padding(.top, 8)
                    Color.clear.frame(height: 60)
                }
                .padding(.horizontal, 16)
            }
            bottomBar { redButton("ยืนยันตัวตน") { modal = .prompt } }
        }
        .onAppear {
            // เข้าฟอร์มพร้อมรูป 2 ใบ = แอปหลักเปิด modal ประมวลผลภาพทันที (readIdCardUserVerify)
            guard flow.verify != .rejected, hasImages else { return }
            modal = .loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                if StarFlow.kycOutcome == "waiting" { modal = .ocrError } else { manual = false; modal = .prompt }
            }
        }
    }

    private func photoTile(caption: String, empty: String, face: Bool, note: String?, noteColor: Color) -> some View {
        VStack(spacing: 8) {
            Text(caption).font(.sh(12, .semibold)).foregroundStyle(KV.black2).frame(height: 16)
            ZStack {
                if hasImages {
                    KycMockPhoto(face: face).padding(.horizontal, 8).padding(.top, 4).padding(.bottom, 8)
                } else {
                    Image(empty).resizable().scaledToFit().frame(width: 148, height: 74)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 120)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white).padding(4))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(manual && face ? KV.red600 : KV.gray200, style: StrokeStyle(lineWidth: 1, dash: [2, 2])))
            if let note {
                Text(note).font(.sh(10, .medium)).foregroundStyle(noteColor).multilineTextAlignment(.center).lineSpacing(1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// แถวช่องกรอก (label มี * แดง · ช่องสูง 40 · ไอคอนซ้าย) — ค่าที่โชว์มาจาก OCR เมื่อตกไปกรอกมือ ไม่งั้นว่าง
    private func field(_ label: String, suffix: String? = nil, icon: String? = nil, placeholder: String, value: String, select: Bool = false, dim: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text("*").font(.system(size: 21)).foregroundStyle(KV.red600).frame(width: 8)
                (Text(label).foregroundStyle(KV.black2) + Text(suffix ?? "").foregroundStyle(KV.textV2)).font(.sh(14, .medium))
            }
            .frame(height: 18)
            HStack(spacing: 8) {
                if let icon { Image(icon).resizable().scaledToFit().frame(width: 20, height: 20) }
                Text(manual && !value.isEmpty ? value : placeholder).font(.sh(14)).foregroundStyle(manual && !value.isEmpty ? KV.gray1000 : KV.gray500).lineLimit(1)
                Spacer()
                if select { Image("ic-arrow-right-gray18v2").resizable().scaledToFit().frame(width: 18, height: 18).rotationEffect(.degrees(90)) }
            }
            .padding(.horizontal, 12).frame(height: 40)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(dim ? KV.bg : .white))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(KV.gray200, lineWidth: 1))
        }
        .padding(.top, 8)
    }

    private func descItem(icon: String, title: String, body: String, readMore: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(KV.green50).frame(width: 40, height: 40)
                .overlay(Image(icon).resizable().scaledToFit().frame(width: 24, height: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.sh(14, .semibold)).foregroundStyle(KV.black2)
                Text(body).font(.sh(14, .medium)).foregroundStyle(KV.textV2)
                if readMore { Text("อ่านเพิ่มเติม").font(.sh(14, .medium)).foregroundStyle(KV.blue).underline() }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    // MARK: - modal (BaseModalView / BaseLoadingModalView: ดำ 50% · การ์ดขาวมุม 20)

    @ViewBuilder
    private func modalView(_ m: Modal) -> some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 0) {
                switch m {
                case .loading:
                    ProgressView().controlSize(.large).tint(KV.red600).padding(.top, 8).padding(.bottom, 16)
                    Text("ระบบกำลังประมวลผลภาพ").font(.sh(20, .bold)).foregroundStyle(KV.gray1000)
                    Text("ขั้นตอนนี้อาจใช้เวลาประมาณ 1–2 นาที\nกรุณาอย่าปิดหรือออกจากหน้านี้จนกว่าระบบ\nจะดำเนินการเสร็จสิ้น")
                        .font(.sh(14)).foregroundStyle(KV.gray500).multilineTextAlignment(.center).lineSpacing(2).padding(.top, 8)
                case .ocrError:
                    Image("ic-warning-outline").resizable().scaledToFit().frame(width: 140, height: 140)
                    Text("ภาพบัตรประชาชนไม่ชัดเจน").font(.sh(18, .bold)).foregroundStyle(KV.black2).padding(.top, 16)
                    Text("กรุณาถ่ายภาพใหม่ให้บัตรอยู่ในกรอบ ภาพคมชัดและเห็นข้อมูลทุกส่วนอย่างชัดเจน ไม่มีเงาสะท้อนทับตัวอักษร")
                        .font(.sh(14)).foregroundStyle(KV.gray500).multilineTextAlignment(.center).lineSpacing(2).padding(.top, 8)
                    // lab: นับเป็นครั้งที่ 3 → แอปหลักโชว์ฟอร์มที่เติมค่าจาก OCR ให้กรอกส่งเอง (ไปคิว staff)
                    redButton("ลองใหม่อีกครั้ง") { manual = true; modal = nil }.padding(.top, 24)
                case .prompt:
                    Text("กรุณายืนยันการส่งข้อมูล\nเพื่อยืนยันตัวตน").font(.sh(18, .bold)).foregroundStyle(KV.black2).multilineTextAlignment(.center)
                    Text("โปรดตรวจสอบข้อมูลของคุณอีกครั้งก่อนส่ง!").font(.sh(14)).foregroundStyle(KV.gray500).padding(.top, 4)
                    KycMockPhoto(face: false).frame(height: 175).frame(maxWidth: .infinity).padding(.top, 24)
                    if manual {
                        Text("หากข้อมูลไม่ตรงกับบัตรประชาชน\nคุณจะไม่ผ่านการอนุมัติ").font(.sh(14)).foregroundStyle(KV.red600).multilineTextAlignment(.center).padding(.top, 24)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        promptRow("เลขบัตรประชาชน :", KycOCR.idNoFormatted)
                        promptRow("วันที่บัตรหมดอายุ :", KycOCR.expiry)
                        promptRow("ชื่อ :", "\(KycOCR.prefix) \(KycOCR.first) \(KycOCR.last)")
                        promptRow("วันเกิด :", KycOCR.dob)
                        promptRow("ที่อยู่ :", "\(KycOCR.address) \(KycOCR.sub) \(KycOCR.district) \(KycOCR.province) \(KycOCR.zip)")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 24).padding(.bottom, 8)
                    redButton("ยืนยัน") { modal = manual ? .successManual : .successAuto }.padding(.top, 16)
                    Button { modal = nil } label: {
                        Text("แก้ไข").font(.sh(14, .medium)).foregroundStyle(KV.red600).frame(maxWidth: .infinity).frame(height: 44)
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(KV.red600, lineWidth: 1))
                    }
                    .buttonStyle(.plain).padding(.top, 8)
                case .successAuto, .successManual:
                    Image("ic-sealcheck-gradient").resizable().scaledToFit().frame(width: 140, height: 140)
                    Text(m == .successAuto ? "ยืนยันตัวตนเสร็จสมบูรณ์" : "ส่งคำขอยืนยันตัวตนสำเร็จ").font(.sh(18, .bold)).foregroundStyle(KV.black2).padding(.top, 16)
                    Text(m == .successAuto ? "ยินดีต้อนรับสู่ประสบการณ์ใหม่ที่ครบครันกว่าเดิม\nสิทธิพิเศษของคุณพร้อมใช้งานแล้ว" : "รอการอนุมัติภายใน 7 วันทำการ")
                        .font(.sh(14)).foregroundStyle(KV.gray500).multilineTextAlignment(.center).lineSpacing(2).padding(.top, 8)
                    redButton(m == .successAuto ? "ตกลง" : "ปิด") {
                        if m == .successAuto { flow.verify = .approved; flow.verifyReason = "" }
                        else { flow.verify = .waiting; flow.kycSentAt = Date(); flow.verifyReason = "" }
                        modal = nil
                        onDone()
                    }
                    .padding(.top, 24)
                case .exit:
                    Text("ออกจากหน้ายืนยันตัวตน").font(.sh(18, .bold)).foregroundStyle(KV.black2)
                    Text("ออกจากหน้ายืนยันตัวตนใช่หรือไม่?").font(.sh(14)).foregroundStyle(KV.gray500).padding(.top, 8)
                    redButton("ยืนยัน") { modal = nil; onClose() }.padding(.top, 24)
                    Button { modal = nil } label: {
                        Text("ยกเลิก").font(.sh(14, .medium)).foregroundStyle(KV.red600).frame(maxWidth: .infinity).frame(height: 44)
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(KV.red600, lineWidth: 1))
                    }
                    .buttonStyle(.plain).padding(.top, 8)
                }
            }
            .padding(.horizontal, 24).padding(.top, m == .loading || m == .exit || m == .prompt ? 24 : 32).padding(.bottom, 24)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
            .padding(.horizontal, 27)
        }
    }

    private func promptRow(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(key).font(.sh(14, .semibold)).foregroundStyle(KV.gray900)
            Text(value).font(.sh(14)).foregroundStyle(KV.gray900).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// สีของแอปหลัก (UIColorExtension) ที่หน้ายืนยันตัวตนใช้
enum KV {
    static let gray1000 = Color.hex(0x232323), gray900 = Color.hex(0x2F2F2F), gray600 = Color.hex(0x757575), gray500 = Color.hex(0x919191)
    static let gray200 = Color.hex(0xD6D6D6), gray50 = Color.hex(0xF1F1F1), textV2 = Color.hex(0x828282), textV8 = Color.hex(0xBDBDBD)
    static let bg = Color.hex(0xF9F9F9), black2 = Color.hex(0x333333), sep = Color.hex(0xF1F1F1)
    static let red600 = Color.hex(0xED1C24), red50 = Color.hex(0xFDE8E9), redText = Color.hex(0xD3180F)
    static let ocean = Color.hex(0x1C8CED), emerald = Color.hex(0x16BE64), blue = Color.hex(0x4D94FF)
    static let orange50 = Color.hex(0xFDF2E8), orange600 = Color.hex(0xED7C1C), orangeBorder = Color.hex(0xFF9900)
    static let green50 = Color.hex(0xF3FFEF), green = Color.hex(0x57BD37)
}

/// ค่าที่ OCR อ่านได้ (จำลอง) — โชว์ใน prompt และเติมฟอร์มตอนตกไปกรอกมือ
enum KycOCR {
    static let idNo = "1103700123456", idNoFormatted = "1-1037-00123-45-6", expiry = "12 ก.ย. 2574", prefix = "นางสาว"
    static let first = "มณีรัตน์", last = "ใจดี", dob = "5 มี.ค. 2541"
    static let address = "99/12 คอนโดลุมพินี ซ.สุขุมวิท 77", zip = "10250", sub = "สวนหลวง", district = "สวนหลวง", province = "กรุงเทพมหานคร"
}

/// รูปถ่ายจำลอง (simulator ไม่มีกล้อง) — สี่เหลี่ยมเทาไล่สีมุม 10 + เงาบัตร/คนจาง ๆ
struct KycMockPhoto: View {
    let face: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(LinearGradient(colors: [Color.hex(0x5B5F66), Color.hex(0x2E3137)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Image(face ? "ic-verify-face-148x74" : "ic-verify-idcard-148x74").resizable().scaledToFit().padding(18).opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// การ์ดสถานะ (VerifyUserStatusView) — ที่นี่ใช้แค่สถานะ reject: ขอบประแดง · รูปหน้า+บัตร 80×72 · "สถานะ : ไม่ผ่านการอนุมัติ" · กล่องเหตุผลแดงอ่อน
struct KycStatusCard: View {
    let reason: String
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(KV.red50.opacity(0.5)).frame(width: 80, height: 80)
                    .overlay(Image("ic-face-thaiid-correct").resizable().scaledToFill().frame(width: 80, height: 72).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)))
                VStack(alignment: .leading, spacing: 8) {
                    Text("เราได้รับข้อมูลการยืนยันตัวตนแล้ว").font(.sh(14, .semibold)).foregroundStyle(KV.gray1000)
                    (Text("สถานะ : ").foregroundStyle(KV.black2) + Text("ไม่ผ่านการอนุมัติ").foregroundStyle(KV.redText)).font(.sh(14, .medium))
                }
                Spacer(minLength: 0)
            }
            HStack(alignment: .top, spacing: 4) {
                Image("ic-xcircle-outline").resizable().scaledToFit().frame(width: 16, height: 16)
                Text(reason.isEmpty ? "กรุณาทำรายการใหม่อีกครั้ง เนื่องจากรูปบัตรประชาชนไม่ตรงกัน" : reason).font(.sh(12)).foregroundStyle(KV.red600)
                Spacer(minLength: 0)
            }
            .padding(8).frame(minHeight: 34)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(KV.red50.opacity(0.5)))
        }
        .padding(8)
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(KV.redText, style: StrokeStyle(lineWidth: 1, dash: [2, 2])))
        .padding(.vertical, 8)
    }
}

enum KycDates {
    static func day(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "th_TH"); f.calendar = Calendar(identifier: .buddhist); f.dateFormat = "d MMM"
        return f.string(from: d)
    }
    static func stamp(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "th_TH"); f.calendar = Calendar(identifier: .buddhist); f.dateFormat = "d MMM HH:mm"
        return f.string(from: d)
    }
    /// เวลาที่เหลือแบบหยาบ: "2 วัน" · "14 ชม." · "40 นาที" · "หมดเวลา"
    static func left(_ d: Date, from now: Date) -> String {
        let s = Int(d.timeIntervalSince(now))
        if s <= 0 { return "หมดเวลา" }
        if s >= 86_400 { return "\(s / 86_400) วัน" }
        if s >= 3_600 { return "\(s / 3_600) ชม." }
        return "\(max(1, s / 60)) นาที"
    }
}

/// หน้าสถานะยืนยันตัวตน — กดปุ่ม "ลงทะเบียนร่วมกิจกรรม" เดิมตอนติดด่าน (รอตรวจ/ตีกลับ) จะมาหน้านี้ และจากแจ้งเตือนตีกลับ
/// (ผู้ใช้ 6 ต.ค. 2569: หน้ากิจกรรมไม่แก้ "แต่กดเข้าไป ต้องทำ UI ให้สวยกว่านี้")
/// โครง: hero สีอ่อนตามสถานะ (บัตรจำลอง + ตราเวลา/เตือน) → เส้นทาง 3 ขั้น → การ์ดงานที่ค้าง (ปก · EP · นับถอยหลังปิดรับ) → ปุ่ม
struct KycStatusPage: View {
    @Environment(StarFlow.self) private var flow
    let campaign: StarCampaign
    let onClose: () -> Void
    let onResubmit: () -> Void
    let onCancel: () -> Void
    @State private var confirmCancel = false
    @State private var pulse = false

    private var waiting: Bool { flow.verify == .waiting }
    private var tint: Color { waiting ? SHColor.orange : SH.red }
    private var soft: Color { waiting ? SHColor.orangeSoft : SHColor.redSoft }
    private var reason: String { flow.verifyReason.isEmpty ? "กรุณาทำรายการใหม่อีกครั้ง เนื่องจากรูปบัตรประชาชนไม่ตรงกัน" : flow.verifyReason }

    var body: some View {
        // โครงเดียวกับหน้า wizard (ผู้ใช้ 6 ต.ค. 2569: "ต้องโครงสีขาวแบบในรูป ไม่ใช่สีแดง"): ✕ กลม · หัวเทาเล็กกลาง · หัวข้อใหญ่ · ชิป · ปุ่มดำ
        VStack(spacing: 0) {
            HStack {
                PKCircleButton(symbol: .x, label: "ปิด") { onClose() }
                Spacer()
                StarText("ยืนยันตัวตน · \(campaign.title)", size: 12.5, weight: .semibold, color: PK.hint)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 20).padding(.top, 6)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(waiting ? "ทีมงานกำลังตรวจเอกสาร 🪪" : "เอกสารยังไม่ผ่าน 🪪").font(.sh(24, .heavy)).foregroundStyle(GL.ink).lineSpacing(4)
                    NudgeChips(lines: waiting ? ["แจ้งผลภายใน 3 วันทำการ", "คำตอบที่กรอกไว้ยังอยู่ครบ"] : ["ส่งใหม่ได้เลย ไม่ต้องรอ", "คำตอบที่กรอกไว้ยังอยู่ครบ"])
                        .padding(.top, 8).padding(.bottom, 20)
                    VStack(spacing: 12) {
                        hero
                    }
                }
                .padding(.horizontal, 20).padding(.top, 28).padding(.bottom, 16)
            }
            bottom
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear { withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true } }
        // ผลมาถึงระหว่างเปิดหน้านี้ (ผ่าน หรือยกเลิกคำขอ) = หน้านี้หมดหน้าที่ ปิดเอง — push/toast พาไปต่อ
        .onChange(of: flow.verify) { _, v in if v == .approved || v == .none { onClose() } }
    }

    // MARK: hero — บัตรจำลอง 2 ใบซ้อน + ตราสถานะ · หัวเรื่องบอกว่าใครกำลังทำอะไรให้ และคำตอบยังอยู่
    private var hero: some View { KycHeroCard(waiting: waiting, reason: reason) }

    // MARK: ปุ่ม (ชุดเดียวกับ wizard: ดำเต็ม + ลิงก์รองใต้) — รอ: กลับ + ยกเลิกคำขอ (กด 2 ครั้ง) · ตีกลับ: ส่งใหม่ + ทางติดต่อทีม
    private var bottom: some View {
        VStack(spacing: 8) {
            if waiting {
                PKPrimaryButton(title: "กลับไปหน้ากิจกรรม", symbol: .arrowRight) { onClose() }
                Button {
                    Haptics.impact(.light)
                    if confirmCancel { onCancel() } else { withAnimation(Motion.snap) { confirmCancel = true } }
                } label: {
                    Text(confirmCancel ? "แตะอีกครั้งเพื่อยกเลิกคำขอ · ต้องถ่ายใหม่ทั้งหมด" : "ยกเลิกคำขอยืนยันตัวตน")
                        .font(.sh(13, .semibold)).foregroundStyle(confirmCancel ? PK.red : PK.muted)
                        .frame(maxWidth: .infinity).frame(height: 30)
                }
                .buttonStyle(.plain)
            } else {
                PKPrimaryButton(title: "ส่งยืนยันตัวตนใหม่", symbol: .identificationCard) { onResubmit() }
                Text("ติดปัญหาเอกสาร? ติดต่อทีม Sale Here").font(.sh(12.5)).foregroundStyle(PK.hint)
                    .frame(height: 30)
            }
        }
        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 20)
    }
}

/// การ์ดภาพสถานะ (hero) — ชุดเดียวใช้ทั้งหน้าสถานะและขั้น KYC ใน wizard (ผู้ใช้ 6 ต.ค. 2569: "รอผลยืนยันตัวตน ต้องไม่มี UI นี้แล้ว ให้ขึ้น UI ทีมงานกำลังตรวจสอบเอกสาร")
/// รอ: ส้มอ่อน + นาฬิกา + บรรทัดเดียวว่าไม่ต้องทำอะไร · ตีกลับ: แดงอ่อน + เตือน + เหตุผลจาก staff
struct KycHeroCard: View {
    let waiting: Bool
    let reason: String
    private var tint: Color { waiting ? SHColor.orange : SH.red }
    private var soft: Color { waiting ? SHColor.orangeSoft : SHColor.redSoft }
    var body: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .bottomTrailing) {
                KycIdCardArt(tint: tint)
                ZStack {
                    Circle().fill(.white).frame(width: 46, height: 46)
                    Circle().fill(tint).frame(width: 36, height: 36)
                    PIcon(waiting ? .clock : .warning, size: 18, weight: .fill).foregroundStyle(.white)
                }
                .offset(x: 14, y: 12)
            }
            .padding(.top, 4)
            Text(waiting ? "ระหว่างนี้ไม่ต้องทำอะไรเพิ่ม · มีผลเมื่อไหร่เราจะแจ้งเตือน"
                         : (reason.isEmpty ? "กรุณาทำรายการใหม่อีกครั้ง เนื่องจากรูปบัตรประชาชนไม่ตรงกัน" : reason))
                .font(.sh(waiting ? 13.5 : 15, waiting ? .regular : .semibold)).foregroundStyle(waiting ? PK.muted : GL.ink)
                .multilineTextAlignment(.center).lineSpacing(3).padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22).padding(.horizontal, 16)
        .background(PK.shape(16).fill(soft))
    }
}

/// บัตรประชาชนจำลอง 2 ใบซ้อน (ใบหลังเอียง) — ภาพประกอบ hero ของหน้าสถานะ ไม่ใช้รูปบัตรจริง
struct KycIdCardArt: View {
    let tint: Color
    var body: some View {
        ZStack {
            card.rotationEffect(.degrees(-7)).offset(x: -10, y: -8).opacity(0.55)
            card
        }
        .frame(width: 168, height: 108)
    }
    private var card: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white)
            .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
            .frame(width: 160, height: 100)
            .overlay(alignment: .topLeading) {
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous).fill(tint.opacity(0.18)).frame(width: 34, height: 42)
                        .overlay(PIcon(.user, size: 18, weight: .fill).foregroundStyle(tint.opacity(0.7)))
                    VStack(alignment: .leading, spacing: 7) {
                        Capsule().fill(SH.ink.opacity(0.75)).frame(width: 64, height: 7)
                        Capsule().fill(SH.line).frame(width: 84, height: 6)
                        Capsule().fill(SH.line).frame(width: 52, height: 6)
                        Capsule().fill(SH.line).frame(width: 72, height: 6)
                    }
                    .padding(.top, 3)
                }
                .padding(14)
            }
            .overlay(alignment: .topTrailing) {
                Capsule().fill(tint).frame(width: 22, height: 6).padding(12)
            }
    }
}

/// แจ้งเตือนจำลอง (= push `userVerifyApprove` / `userVerifyReject` ของแอปหลัก) — แถบบนจอ แตะแล้วพาไปที่ที่ต้องไปต่อ
struct PushBanner: View {
    let title: String
    let text: String
    /// ตีกลับ = ไอคอนเตือน (แอปหลักใช้ ic-verify-reject42 คู่กับ ic-verify-approve42)
    var warn = false
    let onTap: () -> Void
    var body: some View {
        Button { Haptics.impact(.light); onTap() } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 9, style: .continuous).fill(SH.red).frame(width: 38, height: 38)
                    .overlay(PIcon(warn ? .warning : .sealCheck, size: 20, weight: .fill).foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 2) {
                    HStack { Text("Sale Here").font(.sh(12.5, .semibold)).foregroundStyle(SH.muted); Spacer(); Text("ตอนนี้").font(.sh(11.5)).foregroundStyle(SH.hint) }
                    Text(title).font(.sh(14, .bold)).foregroundStyle(SH.ink).lineLimit(1)
                    Text(text).font(.sh(13)).foregroundStyle(SH.ink).lineLimit(2)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white).shadow(color: .black.opacity(0.18), radius: 18, y: 6))
            .padding(.horizontal, 10)
        }
        .buttonStyle(.plain)
    }
}
