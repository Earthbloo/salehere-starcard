import SwiftUI
import PhosphorSwift

/// ยืนยัน — ข้อ `consent` ของฟอร์มเว็บ: กล่อง PDPA (`LEGAL`) + ติ๊กยินยอม
struct ConsentSection: View {
    let showIssues: Bool
    @Binding var focusRequest: String?

    @FocusState private var focus: String?
    private var p: Profile { Profile.me }
    private var consented: Bool { p.intake?.consentAt != nil }

    var body: some View {
        SectionScroll(focus: $focus, request: $focusRequest) {
            PKPanel {
                HStack(alignment: .top, spacing: 10) {
                    Text("🔒").font(.system(size: 22))
                    Text("ยืนยันความยินยอม (PDPA)").font(.sh(15, .bold)).foregroundStyle(PK.ink)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        // ข้อความเดียวกับ `LEGAL` ของฟอร์มเว็บ
                        legal("1. ผู้ควบคุมข้อมูลส่วนบุคคล",
                              "บริษัท เซล เฮียร์ (ไทยแลนด์) จำกัด เลขที่ 1240/16 ซอยสุขุมวิท 101/1 แขวงบางจาก เขตพระโขนง กรุงเทพมหานคร 10260 เลขประจำตัวผู้เสียภาษี 0105559095248 · โทร. 02-102-6496")
                        legal("2. ข้อมูลที่เก็บรวบรวม",
                              "ข้อมูลติดต่อ ช่องทางโซเชียลและยอดผู้ติดตาม เรทค่าตอบแทน หมวดคอนเทนต์ อาชีพ วัน–เวลา–จังหวัดที่สะดวก และข้อมูลอ่อนไหว (ศาสนา / สัดส่วนร่างกาย)")
                        legal("3. วัตถุประสงค์",
                              "เพื่อพิจารณาคัดเลือก จับคู่งานรีวิว/แคมเปญ ติดต่อประสานงาน จัดทำสัญญา และชำระค่าตอบแทน")
                        legal("4. สิทธิของเจ้าของข้อมูล",
                              "เข้าถึง ขอสำเนา แก้ไข ลบ คัดค้าน และถอนความยินยอมได้ทุกเมื่อ รวมถึงร้องเรียนต่อสำนักงานคณะกรรมการคุ้มครองข้อมูลส่วนบุคคล")
                    }
                    .padding(12)
                }
                .frame(height: 190)
                .background(PK.shape(12).fill(PK.fieldFill))

                Button {
                    Haptics.impact(.light)
                    Profile.me.updateIntake { $0.consentAt = consented ? nil : Date() }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            PK.shape(7).strokeBorder(consented ? PK.ok : PK.line2, lineWidth: 1.5)
                            if consented {
                                PK.shape(7).fill(PK.ok)
                                PIcon(.check, size: 12).foregroundStyle(.white)
                            }
                        }
                        .frame(width: 24, height: 24)
                        Text("อ่านแล้วและยินยอมให้เก็บ ใช้ และเปิดเผยข้อมูล (รวมถึงข้อมูลอ่อนไหว) ตามรายละเอียดข้างบน")
                            .font(.sh(13.5, .semibold)).foregroundStyle(consented ? PK.ok : PK.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(13)
                    .background(PK.shape(PK.fieldRadius).fill(consented ? PK.okTint : PK.fieldFill))
                    .overlay(PK.shape(PK.fieldRadius).strokeBorder(consented ? PK.ok.opacity(0.5) : PK.line, lineWidth: 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .animation(Motion.snap, value: consented)

                if let e = sectionIssue(.consent, PField.consent, shown: showIssues) {
                    Text(e).font(.sh(11.5, .medium)).foregroundStyle(PK.err)
                }
            }
            .id(PField.consent)
        }
    }

    private func legal(_ h: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(h).font(.sh(11.5, .bold)).foregroundStyle(PK.ink)
            Text(body).font(.sh(11, .medium)).foregroundStyle(PK.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
