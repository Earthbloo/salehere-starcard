import SwiftUI
import PhosphorSwift
import PhotosUI

/// การรับเงิน — ข้อ `pay` ของฟอร์มเว็บ: นามบุคคล/นามบริษัท · บัญชีที่จะให้เงินเข้า · ถ่ายหน้าสมุดบัญชี
/// ขอแค่บัญชีตอนสมัคร — เอกสารยืนยันตัวตน (`PayKind.later`) ขอตอนได้งานแรก
struct PaymentSection: View {
    let showIssues: Bool
    @Binding var focusRequest: String?

    @Environment(PhotoStore.self) private var photos
    @FocusState private var focus: String?
    @State private var pick: PhotosPickerItem?
    private var p: Profile { Profile.me }
    private var pay: PaymentInfo { p.intake?.payment ?? PaymentInfo() }

    private func err(_ f: String) -> String? { sectionIssue(.payment, f, shown: showIssues) }

    var body: some View {
        SectionScroll(focus: $focus, request: $focusRequest) {
            // นามบุคคล / นามบริษัท — กระเบื้องสองช่องเหมือน Creator/Page
            VStack(alignment: .leading, spacing: 10) {
                PKTileGrid(items: PayKind.allCases) { k in
                    PKTile(icon: k.icon, title: k.title, on: pay.kind == k) {
                        update { $0.kind = k }
                    }
                }
                if let e = err(PField.payKind) {
                    Text(e).font(.sh(11.5, .medium)).foregroundStyle(PK.err).padding(.horizontal, 4)
                }
            }
            .id(PField.payKind)

            if let kind = pay.kind {
                account(kind)
                documents(kind)
                tax(kind)
                later(kind)
            }
        }
        .animation(Motion.settle, value: pay.kind)
        .onChange(of: pick) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    photos.setBookBank(Self.shrink(img, max: 1400))
                    update { $0.bookPhoto = true }
                    Haptics.impact(.medium)
                }
                pick = nil
            }
        }
    }

    // MARK: บัญชี

    private func account(_ kind: PayKind) -> some View {
        PKPanel(title: "เงินจะเข้าบัญชีไหน") {
            if kind == .company {
                PKField(label: "ชื่อนิติบุคคล", required: true, text: bind(\.companyName),
                        placeholder: "บริษัท … จำกัด", error: err(PField.companyName),
                        id: PField.companyName, focus: $focus)
                PKField(label: "เลขประจำตัวผู้เสียภาษี", required: true, text: digits(\.taxId, max: 13),
                        placeholder: "13 หลัก", keyboard: .numberPad, noCorrect: true,
                        error: err(PField.taxId), id: PField.taxId, focus: $focus)
                chips("สำนักงานใหญ่ / สาขา", IntakeCatalog.branches, \.branch, id: PField.branch)
                PKField(label: "ที่อยู่ตามหนังสือรับรอง", required: true, text: bind(\.address),
                        placeholder: "เลขที่ ถนน แขวง เขต จังหวัด รหัสไปรษณีย์", paragraph: true,
                        error: err(PField.address), id: PField.address, focus: $focus)
                PKField(label: "กรรมการผู้มีอำนาจลงนาม", required: true, text: bind(\.signer),
                        placeholder: "ชื่อ–นามสกุล ตามหนังสือรับรอง", error: err(PField.signer),
                        id: PField.signer, focus: $focus)
                chips("จดทะเบียน VAT", IntakeCatalog.vatOptions, \.vat, id: PField.vat)
            }
            PKSelect(label: "ธนาคาร", required: true, options: IntakeCatalog.banks, value: bind(\.bank),
                     placeholder: "เลือกธนาคาร…", error: err(PField.bank), id: PField.bank)
            PKField(label: "เลขที่บัญชี", required: true, text: accountBinding, placeholder: "xxx-x-xxxxx-x",
                    keyboard: .numberPad, noCorrect: true, error: err(PField.accountNo),
                    id: PField.accountNo, focus: $focus)
            PKField(label: "ชื่อบัญชี", required: true, text: bind(\.accountName),
                    placeholder: kind == .company ? "ตามชื่อนิติบุคคล" : "ตามหน้าสมุดบัญชี",
                    contentType: .name, error: err(PField.accountName), id: PField.accountName, focus: $focus)
            PKNote(text: kind == .company
                   ? "ชื่อบัญชีต้องตรงกับชื่อนิติบุคคล รวมคำว่า “บริษัท” และ “จำกัด”"
                   : "ชื่อบัญชีต้องตรงกับชื่อ–นามสกุลจริง ไม่งั้นเงินโอนไม่เข้า",
                   symbol: .warningCircle, color: PK.warn)
        }
    }

    private func chips(_ label: String, _ options: [String], _ key: WritableKeyPath<PaymentInfo, String>,
                       id: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            PKLabel(text: label, required: true)
            PKChoiceGrid(items: options, label: { $0 }, isOn: { pay[keyPath: key] == $0 }) { o in
                update { $0[keyPath: key] = o }
            }
            if let e = err(id) {
                Text(e).font(.sh(11.5, .medium)).foregroundStyle(PK.err)
            }
        }
        .id(id)
    }

    // MARK: เอกสาร

    private func documents(_ kind: PayKind) -> some View {
        PKPanel(title: "เอกสารที่ต้องแนบ") {
            HStack(spacing: 12) {
                thumb
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(kind == .company ? "ถ่ายหน้าสมุดบัญชีบริษัท" : "ถ่ายหน้าสมุดบัญชี")
                            .font(.sh(14.5, .bold)).foregroundStyle(PK.ink)
                        Text("*").font(.sh(13, .bold)).foregroundStyle(PK.red)
                    }
                    Text(pay.bookPhoto ? "แนบแล้ว" : "เห็นเลขบัญชีกับชื่อบัญชีชัด ๆ ก็พอ")
                        .font(.sh(12, .medium)).foregroundStyle(pay.bookPhoto ? PK.ok : PK.muted)
                }
                Spacer(minLength: 6)
                PhotosPicker(selection: $pick, matching: .images) {
                    Text(pay.bookPhoto ? "เปลี่ยน" : "เลือกรูป").font(.sh(12.5, .bold))
                        .foregroundStyle(pay.bookPhoto ? PK.ink : PK.onInk)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(Capsule().fill(pay.bookPhoto ? PK.fieldFill : PK.ink))
                        .overlay(Capsule().strokeBorder(pay.bookPhoto ? PK.line2 : .clear, lineWidth: 1.2))
                }
                .buttonStyle(DockPress())
            }
            if let e = err(PField.bookPhoto) {
                HStack(spacing: 5) {
                    PIcon(.warningCircle, size: 12, weight: .fill)
                    Text(e).font(.sh(12, .medium))
                }
                .foregroundStyle(PK.red)
            }
        }
        .id(PField.bookPhoto)
    }

    /// รูปย่อของหน้าสมุด · แนบแล้วแต่ไม่มีรูป (ข้อมูลตัวอย่าง) = ไอคอนเอกสารเขียว · ยังไม่แนบ = กรอบประ
    @ViewBuilder
    private var thumb: some View {
        let shape = PK.shape(12)
        if let img = photos.bookBank {
            Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56).clipShape(shape)
                .overlay(shape.strokeBorder(PK.line2, lineWidth: 1))
        } else {
            PIcon(pay.bookPhoto ? .fileImage : .camera, size: 22, weight: pay.bookPhoto ? .fill : .bold)
                .foregroundStyle(pay.bookPhoto ? PK.ok : PK.hint)
                .frame(width: 56, height: 56)
                .background(shape.fill(pay.bookPhoto ? PK.okTint : PK.fieldFill))
                .overlay(shape.strokeBorder(pay.bookPhoto ? PK.ok.opacity(0.4) : PK.line2,
                                            style: StrokeStyle(lineWidth: 1, dash: pay.bookPhoto ? [] : [4, 3])))
        }
    }

    // MARK: ภาษี

    /// ตัวอย่างจริงตัวเดียว — โชว์แล้วไม่งงตอนเงินเข้าไม่เท่าค่าจ้าง
    private func tax(_ kind: PayKind) -> some View {
        let wht = kind.withholding
        let fee = 5_000
        let cut = fee * wht / 100
        return PKPanel(title: "ยอดจ่ายเกิน 1,000 บาท หักภาษี ณ ที่จ่าย \(wht)%") {
            VStack(spacing: 0) {
                taxRow("ตัวอย่าง — ค่าจ้างงานนี้", "฿\(Fmt.baht(fee))", PK.ink)
                Rectangle().fill(PK.line).frame(height: 1)
                taxRow("หัก ณ ที่จ่าย \(wht)%", "− ฿\(Fmt.baht(cut))", PK.ink)
                Rectangle().fill(PK.line).frame(height: 1)
                taxRow("เงินเข้าบัญชีจริง", "฿\(Fmt.baht(fee - cut))", PK.ok, bold: true)
            }
            .background(PK.shape(12).fill(PK.fieldFill))
        }
    }

    private func taxRow(_ label: String, _ value: String, _ tint: Color, bold: Bool = false) -> some View {
        HStack {
            Text(label).font(.sh(13, bold ? .bold : .medium)).foregroundStyle(bold ? PK.ink : PK.muted)
            Spacer()
            Text(value).font(.sh(14, .bold)).foregroundStyle(tint).monospacedDigit()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
    }

    // MARK: ยังไม่ต้องส่ง

    private func later(_ kind: PayKind) -> some View {
        PKPanel(title: "ขอตอนได้งานแรก") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(kind.later, id: \.self) { doc in
                    HStack(alignment: .top, spacing: 8) {
                        PIcon(.hourglass, size: 12)
                            .foregroundStyle(PK.hint).padding(.top, 3)
                        Text(doc).font(.sh(13, .medium)).foregroundStyle(PK.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: เขียนกลับ

    private func update(_ f: (inout PaymentInfo) -> Void) {
        Profile.me.updateIntake { d in
            var x = d.payment ?? PaymentInfo()
            f(&x)
            d.payment = x
        }
    }

    /// ย่อรูปจากกล้อง (12MP+) ให้พอกับเอกสาร — เก็บเต็มไฟล์ทั้งดิสก์และหน่วยความจำจะบวมเปล่า ๆ
    static func shrink(_ img: UIImage, max side: CGFloat) -> UIImage {
        let w = img.size.width, h = img.size.height
        let s = min(1, side / Swift.max(w, h))
        guard s < 1 else { return img }
        let size = CGSize(width: w * s, height: h * s)
        return UIGraphicsImageRenderer(size: size).image { _ in img.draw(in: CGRect(origin: .zero, size: size)) }
    }

    private func bind(_ key: WritableKeyPath<PaymentInfo, String>) -> Binding<String> {
        Binding(get: { pay[keyPath: key] }, set: { v in update { $0[keyPath: key] = v } })
    }

    /// ตัวเลขล้วน ยาวไม่เกิน `max`
    private func digits(_ key: WritableKeyPath<PaymentInfo, String>, max: Int) -> Binding<String> {
        Binding(get: { pay[keyPath: key] },
                set: { v in update { $0[keyPath: key] = String(v.filter(\.isNumber).prefix(max)) } })
    }

    /// เก็บเป็นตัวเลข 10 หลัก แสดงเป็น xxx-x-xxxxx-x
    private var accountBinding: Binding<String> {
        Binding(get: { PaymentInfo.formatAccount(pay.accountNo) },
                set: { v in update { $0.accountNo = String(v.filter(\.isNumber).prefix(10)) } })
    }
}
