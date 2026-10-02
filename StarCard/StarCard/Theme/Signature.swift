import SwiftUI
import PhosphorSwift

// MARK: - ลายเซ็นของผู้ออกบัตร
//
// # ทำไมไม่ใช่โลโก้
//
// Linktree ไม่ได้ทำให้คนจำได้ด้วยโลโก้ — ดอกจันของมันมีแค่ 24pt มุมซ้ายบน สิ่งที่ทำงานคือ
// ที่อยู่ (linktr.ee/…) รูปทรงของหน้า ป้าย Verified และท้ายหน้าที่อยู่ที่เดิมทุกครั้ง
// StarCard ใช้กติกาเดียวกัน: **Sale Here ปรากฏในบทบาท "ผู้รับรอง" ไม่ใช่ผู้ออกแบบ**
//
// # สามวง — ยิ่งห่างจากตัวการ์ด ยิ่งพูดได้ดังขึ้น
//
// - วงใน (ตัวการ์ด ของ Star): ตราสามดวงที่แต่ละดวงมีความหมายเดียว · ซีเรียล EP · ป้ายที่มา
//   · แถบผู้ออกบัตรที่ขอบล่าง — ทั้งหมดสีตามหมึกของการ์ด จึงเป็นของเราโดยไม่แย่งการ์ดของเขา
// - วงกลาง (เวที: คลัง ห้องแต่ง หน้าดู): ตรา STAR มุมซ้ายบน · ลายน้ำลายจาง · ปุ่มแดงเดียว
// - วงนอก (ของที่ส่งออก): แถบ QR + ที่อยู่ + ตรา STAR บนลายน้ำ
//
// ไม่มีวงไหนที่มีโลโก้ลอย ๆ กลางการ์ด และไม่มีที่ไหนใช้พื้นแดงเป็นค่าเริ่มต้น
enum Signature {
    /// ดาวทอง = **สถานะ STAR** — ติดข้างชื่อในทุก hero ใช้กับความหมายนี้เท่านั้น ไม่ใช้ตกแต่ง
    static let gold = SHColor.star
    /// แดงวงกลม = **ข้อเท็จจริงที่ Sale Here ออกให้** — ประทับได้เฉพาะชั้นหลักฐาน
    static let red = SaleHereMark.red
    /// เขียว = **ยืนยันตัวตนแล้ว (KYC)** — ใช้ที่เดียวคือแถบผู้ออกบัตรกับหน้าดู
    static let green = SHColor.success
    /// พื้นเวทีของแบรนด์ — หน้าดู หน้าแชร์ และรูปที่ส่งออก (มืดอมม่วงนิดหนึ่ง ไม่ใช่ดำโรงพิมพ์)
    static let stage = Color(red: 0.047, green: 0.043, blue: 0.058)

    /// วันที่ยืนยันตัวตน — วันที่ KYC ใน Star Profile ผ่าน (`StarFlow.verifiedAt`) · ยังไม่ผ่าน = ขีด
    static var verifiedOn: String {
        guard let d = StarFlow.shared.verifiedAt else { return "—" }
        return shortDate(d)
    }

    /// วันที่แบบตราประทับ — วัน.เดือน.ปี พ.ศ. สองหลัก
    static func shortDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .buddhist)
        f.locale = Locale(identifier: "th_TH")
        f.dateFormat = "dd.MM.yy"
        return f.string(from: d)
    }

    /// ความสูงของแถบผู้ออกบัตร (หน่วยออกแบบ)
    ///
    /// `PageLayout.content` กันพื้นที่ก้นหน้าไว้เท่านี้ — widget วางทับไม่ได้ และผังเทมเพลตทุกใบ
    /// จบเหนือเส้นนี้อยู่แล้ว (สูงกว่าขอบกระดาษ 6pt เพื่อให้ตรา Sale Here STAR ขนาด 24 มีที่หายใจ)
    static let stripHeight: CGFloat = 30

    /// ที่อยู่ของการ์ด — โดเมนเดียวกับแอปหลัก ไม่ตั้งโดเมนใหม่ให้ต้องสะสมความจำจากศูนย์
    static func url(slug: String) -> String { "\(ClipInvocation.host)/star/\(slug)" }

    /// ฟอนต์โมโนของ "บรรทัดที่เครื่องอ่าน" — ที่อยู่ ซีเรียล วันที่ (ตัวโรมันกับตัวเลขล้วน)
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// หน้าตาของแถบผู้ออกบัตร — ทุกแบบพิมพ์สามอย่างเดียวกัน (ใคร · เมื่อไหร่ · ตรวจที่ไหน)
enum StripStyle: String, CaseIterable, Identifiable {
    /// บรรทัดเดียวใต้เส้นผม — ค่าเริ่มต้น อ่านเป็นบรรทัดล่างของหนังสือเดินทาง
    case line
    /// รอยปรุ + พื้นจาง — สำหรับตระกูลโฟโต้การ์ดที่พูดภาษาตั๋ว/การ์ดสะสมอยู่แล้ว
    case ticket
    /// ไม่มีเส้นไม่มีพื้น — เบาสุด สำหรับใบที่รูปเต็มขอบ
    case ghost
    /// ตราปั๊มนูนสีเดียวกับการ์ด — ลายเซ็นของตัวการ์ดเปลี่ยนจากตัวเขียนจางเป็นตรา STAR ที่กดลงบนแผ่น
    /// (ดู `SignatureEmboss`)
    case emboss
    /// ตราเดียวกันแต่ **พิมพ์ทึบด้วยหมึกของการ์ด** — มองเห็นได้จากภาพรวมทั้งใบ
    /// (ปั๊มนูนสีเดียวกับแผ่นสวยตอนดูใกล้ แต่ย่อเป็นรูปย่อแล้วหายไปทั้งดวง · เคยเป็นฟอยล์รุ้ง ถูกปฏิเสธเพราะแย่งสายตา
    /// ชื่อเคสคงเป็น `foil` เพราะเป็นค่าที่เขียนลงไฟล์การ์ดไปแล้ว)
    case foil

    var id: String { rawValue }

    /// ลายเซ็นของใบนี้เป็นตรา (ปั๊มนูนหรือพิมพ์ทึบ) ไม่ใช่ตัวเขียนจาง
    var isStamp: Bool { self == .emboss || self == .foil }

    var name: String {
        switch self {
        case .line:   return "บรรทัด"
        case .ticket: return "ตั๋ว"
        case .ghost:  return "โปร่ง"
        case .emboss: return "ปั๊มนูน"
        case .foil:   return "พิมพ์"
        }
    }
}

// MARK: - S2 · แถบผู้ออกบัตร

/// ขอบล่างของทุกหน้า — ถอดไม่ได้ ย้ายไม่ได้ — **ลายเซ็นของผู้ออกบัตร**
///
/// ไวยากรณ์เดียวกับบัตรเครดิต: **ซ้ายล่างคือชื่อผู้ถือบัตร ขวาล่างคือตราของผู้ออกบัตร**
/// (ตำแหน่งเดียวกับที่การ์ดแชร์รีวิวของแอปหลักเซ็นชื่อด้วยตัวเขียน Sale Here มุมขวาล่างอยู่แล้ว)
///
/// ตราที่ใช้คือ **ตราจริงของแอป** `ic-salehere-star-outline` — ตัวเขียน Sale Here ซ้อนบน STAR
/// ที่ตัว A เป็นดาวโปร่ง — ตัวเดียวกับไอคอนแท็บหน้าแรกที่ทุกคนเห็นทุกวัน วางที่ 34×24 เท่าขนาด
/// ที่แท็บบาร์ใช้ในโปรดักชัน สีแดงแบรนด์เสมอ (แท็บที่ active) ไม่ย้อมตามหมึกของการ์ด
///
/// รอบก่อน ๆ พยายาม "พิมพ์" STAR ขึ้นมาเอง (ตัวหนา · ดาวทองแทน A) แล้วอ่านออกมาแบน
/// เพราะมันไม่ใช่ตราที่คนเคยเห็น — ลายเซ็นต้องเป็นตัวจริง ไม่ใช่ตัวเลียน
struct IssuerStrip: View {
    let style: StripStyle
    let slug: String
    let width: CGFloat

    @Environment(\.cardInk) private var ink
    private var verified: Bool { Profile.me.creator.verified }

    /// ขนาดตรา = ขนาดไอคอนแท็บหน้าแรกของแอปหลัก (MediaBox ของ PDF คือ 34×24)
    static let markHeight: CGFloat = 24

    var body: some View {
        HStack(spacing: 12) {
            // ผู้ถือบัตร — ชื่อนูนซ้ายล่างเหมือนบัตร · ตราติ๊กสีแดงเดียวกับตราผู้ออก = รับรองโดยคนเดียวกัน
            HStack(spacing: 8) {
                Text("@\(slug)")
                    .font(.sh(10.5, .semibold))
                    .foregroundStyle(ink.text(style == .ghost ? 0.82 : 0.9))
                // ตราติ๊กขึ้นเมื่อทุกช่องยืนยันยอดผ่านการเชื่อมบัญชี/API — ยอดที่กรอกเองบอกตรง ๆ ว่ารอตรวจ
                // การ์ดที่ประกาศ "ยืนยันแล้ว" ทั้งที่ยอดพิมพ์เอง = ข้อความโฆษณา ไม่ใช่ลายเซ็นผู้ออก
                HStack(spacing: 3.5) {
                    if verified {
                        SymbolIcon(name: SHIcon.sealCheck, size: 9, tint: Signature.red)
                    } else {
                        PIcon(.clock, size: 9).foregroundStyle(ink.text(0.5))
                    }
                    Text(verified ? "ยืนยันยอดแล้ว" : "ยอดกรอกเอง · รอตรวจสอบ")
                        .font(.sh(9, .medium))
                        .foregroundStyle(ink.text(0.58))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            // ผู้ออกบัตร — ตราจริง ขนาดจริง สีจริง
            StarLockup(height: Self.markHeight, tint: Signature.red)
        }
        .padding(.horizontal, PageLayout.margin)
        .frame(width: width, height: Signature.stripHeight)
        .background { fill }
        .overlay(alignment: .top) { rule }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("@\(slug) \(verified ? "ยืนยันยอดแล้ว" : "ยอดกรอกเอง รอตรวจสอบ") · ออกโดย Sale Here STAR")
    }

    @ViewBuilder
    private var fill: some View {
        switch style {
        case .ticket:
            // แผ่นจาง ๆ ใต้ลายเซ็น — พื้นมืดสว่างขึ้นนิด พื้นกระดาษเข้มลงนิด ความหมายเดียวกันคนละทิศ
            ink.fill(0.06)
        case .line, .ghost, .emboss, .foil:
            // เวทีมืดที่มีรูปพื้นหลัง — ตัวอักษรบรรทัดนี้ต้องมี scrim ของตัวเองเหมือนตัวอักษรบนรูปทุกตัว
            if !ink.isLight {
                LinearGradient(colors: [.clear, .black.opacity(0.32)], startPoint: .top, endPoint: .bottom)
            }
        }
    }

    @ViewBuilder
    private var rule: some View {
        switch style {
        case .line:
            // เส้นผมไล่จางจากซ้ายไปขวา — อยู่ใต้ชื่อผู้ถือบัตรแล้วละลายหายก่อนถึงตรา ตราจึงลอยในที่ว่าง
            Rectangle()
                .fill(LinearGradient(colors: [ink.line(0.3), ink.line(0.04)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 0.8)
                .padding(.horizontal, PageLayout.margin)
        case .ticket:
            // ขอบตั๋ว — เส้นผมทึบเต็มความกว้าง (เส้นประในรอบก่อนอ่านเป็นเสียงรบกวน)
            Rectangle().fill(ink.line(0.2)).frame(height: 0.7)
        case .ghost, .emboss, .foil:
            EmptyView()
        }
    }
}

// MARK: - S3 · ระบบตราสามดวง

/// ดาวทองข้างชื่อ = เป็น Sale Here STAR
///
/// แทนตราติ๊กที่เคยย้อมสีตามธีม — ตราที่เปลี่ยนสีตามการ์ดที่มันรับรองอยู่ไม่ใช่ตรา แต่เป็นของตกแต่ง
/// ดาวเป็นสีทองเดียวกันทุกใบ มีเงาบางกันจมบนรูป
struct StarSeal: View {
    var size: CGFloat = 11
    /// หมึกของตรา = **สีเดียวกับชื่อที่มันเกาะอยู่** (ตั้งต้นขาว เพราะชื่อส่วนใหญ่อยู่บนรูปหรือแผ่นเข้ม)
    var tint: Color = .white
    /// สีของเครื่องหมายถูก — สีของพื้นใต้ชื่อ
    var punch: Color = Color(white: 0.10)

    var body: some View {
        // เหรียญกลีบตัวเดียวกับแถบหน้าดู · widget ตรารับรอง · รูปส่งออก — **ตราเดียว ทุกที่ หมึกเดียวกับตัวอักษรข้าง ๆ**
        // (ดาวทองรุ่นแรกไม่มีใครอ่านว่า "ยืนยันแล้ว" · ฟอยล์รุ้งรุ่นสองแย่งสายตาจากชื่อของเจ้าของ)
        VerifiedSeal(radius: size * 0.68, punch: punch, tint: tint, compact: true)
            .shadow(color: .black.opacity(0.35), radius: size * 0.12, y: size * 0.05)
            .accessibilityLabel("Verified by Sale Here")
            .verifySlot()
    }
}

// MARK: - S4 · ซีเรียลผลงาน

/// ชิปเลขตอน EP — ทรงเดียวกันทุกที่ที่มันโผล่
///
/// Strava ไม่ต้องใส่โลโก้ในรูปวิ่งเพราะแผนที่เส้นส้มคือ Strava อยู่แล้ว —
/// เลขตอนที่ระบบออกให้คือของแบบนั้นของเรา: จุดแดงของผู้ออก + ตัวเลขโมโน บนแผ่นเล็กมุมมน
struct EPChip: View {
    enum Tone { case ink, accent, light }

    let ep: String
    var tone: Tone = .ink
    var size: CGFloat = 8
    var accent: Color = .white

    var body: some View {
        HStack(spacing: size * 0.45) {
            Circle().fill(Signature.red).frame(width: size * 0.5, height: size * 0.5)
            Text(ep).font(Signature.mono(size, .bold)).tracking(0.4)
                .lineLimit(1).fixedSize()
        }
        .foregroundStyle(fg)
        .padding(.horizontal, size * 0.75).padding(.vertical, size * 0.38)
        .background(RoundedRectangle(cornerRadius: size * 0.55, style: .continuous).fill(bg))
    }

    private var fg: Color {
        switch tone {
        case .ink:    return Color(red: 0.98, green: 0.96, blue: 0.92)
        case .accent: return .white
        case .light:  return Color.black.opacity(0.85)
        }
    }

    private var bg: Color {
        switch tone {
        case .ink:    return Color(red: 0.09, green: 0.08, blue: 0.10)
        case .accent: return accent
        case .light:  return Color.white.opacity(0.92)
        }
    }
}

// MARK: - S5 · ป้ายที่มาของตัวเลข

/// ตัวเลขทุกตัวบนการ์ดบอกว่ามาจากไหน — ใช้คำเดิมทุกที่ ห้ามแปรผัน
enum Provenance: Hashable {
    /// ยืนยันโดย Sale Here (จากงานในระบบ)
    case verified
    /// จากบัญชีที่เชื่อม · เวลาที่ sync ล่าสุด
    case connected(String)
    /// จากสกรีนช็อต insight ที่ Star อัปโหลด · วันที่
    case screenshot(String)
    /// จากโปรไฟล์ STAR (ค่าที่ระบบเก็บไว้)
    case profile
    /// ตั้งเอง — ราคาและข้อความที่เจ้าของการ์ดพิมพ์
    case own
    /// ผู้สมัครกรอกยอดเอง ยังไม่ได้เชื่อมบัญชี — ทีมงานตรวจแล้วค่อยเปลี่ยนเป็น `connected`
    case manual

    var label: String {
        switch self {
        case .verified:             return "ยืนยันโดย Sale Here"
        case .connected(let ago):   return "จากบัญชีที่เชื่อม · \(ago)"
        case .screenshot(let date): return "จากสกรีนช็อต · \(date)"
        case .profile:              return "จากโปรไฟล์ STAR"
        case .own:                  return "ตั้งเอง"
        case .manual:               return "กรอกเอง · รอตรวจสอบ"
        }
    }
}

struct ProvenanceTag: View {
    let kind: Provenance
    @Environment(\.cardInk) private var ink

    /// บนรูปถ่าย (เช่น `ตัวเลขยักษ์`) หมึกของการ์ดใช้ไม่ได้ — ป้ายต้องเป็นขาวบนแผ่นมืดของตัวเอง
    var onPhoto = false
    /// หมึกของบรรทัด "ยืนยันโดย Sale Here" เมื่อพื้นใต้ป้ายไม่ใช่ทั้งหมึกการ์ดและรูปถ่าย (เช่นกล่องขาวของสำรับสติกเกอร์)
    var bylineTint: Color? = nil

    /// ใบนี้มีแสตมป์ Sale Here แล้ว — ป้าย Verified หลบให้ (ป้าย "กรอกเอง · รอตรวจสอบ" ยังขึ้นตามเดิม)
    @Environment(\.saleHereStamped) private var stamped

    var body: some View {
        // มีเครื่องหมาย Sale Here แล้ว = ที่มาคือ Sale Here — ป้ายที่มาเดิม (ภาพหน้าจอ · เชื่อมบัญชี) หลบให้
        if stamped {
            SaleHereByline(tint: ink.text(0.82),
                           tone: bylineTint != nil ? .light : (onPhoto ? .dark : .ink))
        } else if case .connected(let ago) = kind {
            verifiedPill(ago)
        } else {
            plainTag
        }
    }

    /// ยอดจากบัญชีที่เชื่อม = แถบ Verified ฉบับย่อ: เหรียญรับรองตัวเดียวกับหน้าดูและรูปส่งออก · คำเต็ม · เวลาที่ดึง
    /// (เดิมเป็นจุดเขียวกับคำว่า "จากบัญชีที่เชื่อม" ซึ่งบอกที่มาแต่ไม่บอกว่า **ใครรับรอง**)
    private func verifiedPill(_ ago: String) -> some View {
        HStack(spacing: 4) {
            VerifiedSeal(radius: 5.5, punch: onPhoto || !ink.isLight ? Color(white: 0.12) : Color(white: 0.97),
                         tint: onPhoto ? .white : ink.text(0.86), compact: true)
            // เวลาที่ดึงยอดต่อท้ายเฉพาะตอนเป็นเวลาจริง ("2 ชม.") — ค่าที่เป็นประโยค ("เชื่อมบัญชีแล้ว") ทำให้ป้ายล้นขอบ widget
            (Text("Verified").font(.sh(8.5, .bold))
             + Text(ago.contains(where: \.isNumber) ? " · \(ago)" : "").font(.sh(8, .medium)))
                .lineLimit(1).fixedSize()
        }
        .foregroundStyle(onPhoto ? Color.white.opacity(0.92) : ink.text(0.86))
        .padding(.leading, 3).padding(.trailing, 7).padding(.vertical, 2.5)
        .background(Capsule().fill(onPhoto ? Color.black.opacity(0.34) : ink.fill(0.12)))
        .overlay(Capsule().strokeBorder(onPhoto ? Color.white.opacity(0.22) : ink.line(0.16), lineWidth: 0.5))
        .verifySlot()
    }

    private var plainTag: some View {
        HStack(spacing: 4) {
            switch kind {
            case .verified:
                SaleHereMark(size: 9)
            case .connected:
                Circle().fill(Signature.green).frame(width: 4.5, height: 4.5)
            case .screenshot:
                Image(systemName: "camera.viewfinder").font(.system(size: 7.5, weight: .semibold))
            case .profile:
                SymbolIcon(name: SHIcon.starFill, size: 7, tint: Signature.gold)
            case .own:
                Image(systemName: "pencil").font(.system(size: 7.5, weight: .semibold))
            case .manual:
                Image(systemName: "clock").font(.system(size: 7.5, weight: .semibold))
            }
            Text(kind.label).font(.sh(8, .semibold)).lineLimit(1).fixedSize()
        }
        .foregroundStyle(onPhoto ? Color.white.opacity(0.8) : ink.text(0.62))
        .padding(.horizontal, 6).padding(.vertical, 2.5)
        .background(Capsule().fill(onPhoto ? Color.black.opacity(0.3) : ink.fill(0.10)))
        .overlay(Capsule().strokeBorder(onPhoto ? Color.white.opacity(0.18) : ink.line(0.14), lineWidth: 0.5))
        // ยอดที่ยังกรอกเองก็เปิดแผ่นเดียวกัน — แผ่นบอกตรง ๆ ว่าข้อไหนยังรอ
        .verifySlot(kind == .manual || kind == .verified)
    }
}

extension View {
    /// ตราทุกดวงแตะแล้วได้คำตอบเดียวกัน — เปิดแผ่นตรวจสอบ (`VerifySheet`) ในหน้าดู
    ///
    /// ขยายพื้นที่แตะรอบตัวตรา 8pt แล้วหักคืน ผังจึงไม่ขยับ: ตราข้างชื่อเล็กแค่ 11pt แตะตรง ๆ ไม่โดน
    func verifySlot(_ on: Bool = true) -> some View {
        padding(8).linkSlot(on ? VerifiedFacts.sheetURL : nil).padding(-8)
    }
}

// MARK: - S6 · ลายน้ำแบบลวดลาย

/// ลาย Sale Here ซ้ำ ๆ แบบกระดาษหนังสือเดินทาง — ใช้บนเวทีและของที่ส่งออก **ไม่ใช้บนตัวการ์ด**
///
/// ที่ 4–5% คนจะ "รู้สึก" ว่าเป็น Sale Here โดยไม่ได้อ่านคำว่า Sale Here
/// asset ตัวนี้อยู่ในโปรเจกต์มาตลอด (`ic-salehere-watermark`) แต่ไม่เคยถูกใช้
struct SignaturePattern: View {
    var opacity: Double = 0.045
    var scale: CGFloat = 0.32

    var body: some View {
        Rectangle()
            .fill(ImagePaint(image: Image(SHIcon.watermark), scale: scale))
            .opacity(opacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - S6.5 · ลายเซ็นมุมการ์ด

/// โลโก้ Sale Here ตัวโตมุมขวาล่าง **ของตัวการ์ด** — ขาวจาง ล้นพ้นขอบแผ่นแล้วถูกขอบตัด
///
/// # ทำไมอยู่ในการ์ด ไม่ใช่บนเวที
///
/// ลายน้ำบนเวทีเซ็นชื่อ "หน้าจอ" ซึ่งเป็นของที่ไม่มีใครได้เห็นนอกจากเจ้าของเครื่อง —
/// ของที่เดินทางออกไปคือ **การ์ด** ลายเซ็นจึงต้องติดไปกับแผ่น ทั้งตอนดูในแอป ตอนแชร์ และตอนพิมพ์
///
/// # สีของลายน้ำ = หมึกของการ์ดใบนั้น
///
/// ไม่ใช่แดงแบรนด์: การ์ดมีหมึกของตัวเองทุกใบ (เหลือง กรมท่า หินขัด รูปถ่าย) แดงทับลงไปคือ
/// **สีที่สิบเอ็ด** ที่ไม่เข้ากับใบไหนเลย — แดงเหลือไว้ที่เดียวคือตราผู้ออกบัตร (ดู `IssuerStrip`)
///
/// และไม่ใช่ขาวทุกใบ: กติกาของ `InkStyle.fill` คือ **พื้นมืดแยกตัวด้วยการสว่างขึ้น
/// พื้นสว่างแยกตัวด้วยการเข้มลง** — ลายน้ำจึงใช้ `ink.base` ตรง ๆ คือขาวบนใบมืด
/// และถ่านที่อาบเฉดของธีมบนใบสว่าง (ไม่ใช่ดำสนิท — ดำสนิทบนการ์ดที่มีสีธีมอ่านเป็น "ยังไม่ได้ออกแบบ")
///
/// ค่าความทึบคนละเส้นโค้งสองฝั่ง เพราะหมึกเข้มบนพื้นสว่าง "ดัง" กว่าขาวบนพื้นมืดมากที่ค่าเท่ากัน
///
/// # กติกาขนาด
///
/// อิง **ด้านสั้น** ของแผ่น ไม่ใช่ด้านกว้าง — พอร์ตเป็นแถบสามหน้ากว้างกว่าสูงเกือบสองเท่า
/// ถ้าอิงด้านกว้างจะได้ลายน้ำที่โตกว่าครึ่งแผ่น ส่วนสตอรี่ทรงตั้งจะได้ตัวจิ๋ว — คนละน้ำหนักทั้งที่เป็นการ์ดเหมือนกัน
struct SignatureCorner: View {
    /// หมึกของการ์ดใบนั้น — ขาวบนใบมืด · ถ่านอาบเฉดธีมบนใบสว่าง
    var tint: Color = .white
    /// หมึกเป็นฝั่งสว่างไหม (= การ์ดพื้นสว่าง)
    var light: Bool = false
    /// ความแรงเทียบค่ามาตรฐาน (1 = มาตรฐาน)
    var strength: Double = 1

    /// สัดส่วนกับ **ด้านสั้น** ของแผ่น
    private let span: CGFloat = 0.68
    /// ส่วนที่ยอมให้ไหลพ้นขอบ (เทียบกับตัวมันเอง)
    private let bleedX: CGFloat = 0.12
    private let bleedY: CGFloat = 0.06

    private var alpha: Double { (light ? 0.07 : 0.17) * strength }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * span

            ZStack(alignment: .bottomTrailing) {
                Color.clear
                Image(SHIcon.wordmark)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: side, height: side)
                    // ไล่จางไปทางมุมที่มันไหลออกนอกแผ่น — ส่วนที่คมที่สุดอยู่ในแผ่นเสมอ
                    .foregroundStyle(
                        LinearGradient(colors: [tint, tint.opacity(0.35)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .opacity(alpha)
                    // ลายเซ็นคนเขียนไม่เคยตรงกับขอบกระดาษ
                    .rotationEffect(.degrees(-8), anchor: .bottomTrailing)
                    .offset(x: side * bleedX, y: side * bleedY)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - S6.6 · ตราปั๊มนูน

/// ตรา Sale Here STAR **ปั๊มนูนสีเดียวกับการ์ด** — ไม่มีสีของตัวเองเลยสักสี
///
/// วาดแค่สองอย่าง: ขอบสว่างด้านบนซ้าย กับเงาด้านล่างขวา แล้ว **เจาะตัวตราออก** จากทั้งคู่
/// เนื้อของตราจึงโปร่ง เห็นพื้นของการ์ดใบนั้นตรง ๆ (ไล่เฉด · หินขัด · รูปถ่าย · widget ที่อยู่ใต้มัน)
/// มันเข้ากับทุกดีไซน์ด้วยเหตุผลเดียว: ไม่ได้เอาสีอะไรมาวางทับของใคร
///
/// ตราคือตัวจริงของแอป (`ic-salehere-star-outline`) สัดส่วนจริง — ไม่ใช่ตัวพิมพ์เลียนแบบ
struct EmbossedLockup: View {
    var height: CGFloat = 26
    /// การ์ดพื้นสว่างไหม — พื้นสว่างเงาต้องทำงานหนักกว่าแสง พื้นมืดกลับกัน
    var light: Bool = false
    /// **พิมพ์ทึบ** ด้วยหมึกของแผ่นแทนปั๊มนูนเปล่า — ตราเดียวกัน ตำแหน่งเดียวกัน แต่เห็นได้จากภาพรวมทั้งใบ
    /// (ชื่อพารามิเตอร์ยังเป็น `foil` เพราะค่าที่เก็บในไฟล์การ์ดคือ "foil" — ดู `StripStyle.foil`)
    var foil: Bool = false
    /// หมึกของตราพิมพ์ — **สีเดียวกับพาดหัวของแผ่นนั้น** ไม่มีสีของตัวเอง
    var tint: Color = .white

    var body: some View {
        if foil { inkStamp } else { blindStamp }
    }

    /// ตราพิมพ์สีเดียว — รอบก่อนเป็นฟอยล์รุ้ง ผู้ใช้ปฏิเสธทุกจุดเพราะมันแย่งสายตาจากการ์ดของเจ้าของ
    /// หมึกเดียวกับพาดหัวอ่านออกชัดเท่าพาดหัว แต่ไม่เพิ่มสีใหม่ให้งานของเขาสักสี
    private var inkStamp: some View {
        mark.foregroundStyle(tint.opacity(0.92))
            .accessibilityLabel("Sale Here STAR")
    }

    private var blindStamp: some View {
        let depth = max(0.6, height * 0.030)
        return ZStack {
            mark.foregroundStyle(.white.opacity(light ? 0.72 : 0.42))
                .offset(x: -depth, y: -depth)
            mark.foregroundStyle(.black.opacity(light ? 0.36 : 0.62))
                .offset(x: depth, y: depth * 1.15)
            // เจาะเนื้อตราออก — เหลือแต่เสี้ยวแสงกับเสี้ยวเงารอบขอบ
            mark.foregroundStyle(.black).blendMode(.destinationOut)
        }
        .compositingGroup()
        // เนื้อตรานูนขึ้นนิดเดียว — พอให้ตาจับรูปทรงได้บนพื้นเรียบ
        .overlay { mark.foregroundStyle((light ? Color.black : Color.white).opacity(light ? 0.045 : 0.06)) }
        .accessibilityLabel("Sale Here STAR")
    }

    private var mark: some View {
        Image(SHIcon.star)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(height: height)
    }
}

/// ลายเซ็นแบบปั๊มนูนของตัวการ์ด — มุมล่างของแผ่น **เหนือ widget ทุกชิ้น**
///
/// เครื่องปั๊มนูนกดลงบนกระดาษที่พิมพ์เสร็จแล้ว มันจึงอยู่บนสุด ไม่ใช่ใต้งาน ·
/// ขนาดอิงด้านสั้นของแผ่นเหมือน `SignatureCorner` — พอร์ตสามหน้ากับสตอรี่ได้น้ำหนักเท่ากัน
///
/// # สองกติกาที่กันไม่ให้ตราไปทำลายงานของเจ้าของ
///
/// 1. **ไม่ปั๊มซ้ำ** — ถ้าบนการ์ดมีใบที่ปั๊มตราบนแผ่นของตัวเองอยู่แล้ว (`WidgetKind.takesEmboss`)
///    การ์ดใบนั้นเซ็นชื่อแล้ว ตราระดับการ์ดไม่ขึ้นอีก
/// 2. **ไม่ทับรูป** — ไล่หามุมล่างที่ไม่มี widget รูปอยู่ใต้มัน (ขวาล่างของหน้าสุดท้ายก่อน แล้วซ้ายล่าง
///    แล้วถอยไปหน้าก่อน) รอบแรกตราไปตกบนเอวของรูปคนในโปสเตอร์ติดต่อ ซึ่งเป็นสิ่งที่ตรานูนไม่ควรทำเลย
struct SignatureEmboss: View {
    var light: Bool = false
    var foil: Bool = false
    /// หมึกของตราพิมพ์ — หมึกของการ์ดใบนั้น
    var tint: Color = .white
    /// หน้าของการ์ด — ว่าง = ไม่มีข้อมูลผัง (โต๊ะตรวจงาน) วางขวาล่างตรง ๆ
    var pages: [CardPage] = []
    var pageSize: CGSize = .zero
    /// ขอบนอกกับร่องคั่นหน้า — พรีวิวในคลังวางสามหน้าห่างกัน ตำแหน่งหน้าจึงไม่ใช่ `i × กว้าง` เฉย ๆ
    var margin: CGFloat = 0
    var gutter: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            // ตราพิมพ์ต้องใหญ่พอจะอ่านออกตอนย่อทั้งใบ · ปั๊มนูนเล็กกว่าได้เพราะมันตั้งใจเงียบ
            let h = max(20, side * (foil ? 0.070 : 0.058))
            let mark = CGSize(width: h * 34 / 24, height: h)
            let inset = CGSize(width: side * 0.042, height: side * 0.034)

            if pages.isEmpty || pageSize.width < 1 {
                EmbossedLockup(height: h, light: light, foil: foil, tint: tint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, inset.width)
                    .padding(.bottom, inset.height)
            } else if let spot = Self.spot(pages: pages, pageSize: pageSize, mark: mark, inset: inset) {
                EmbossedLockup(height: h, light: light, foil: foil, tint: tint)
                    .position(x: margin + CGFloat(spot.page) * (pageSize.width + gutter) + spot.center.x,
                              y: margin + spot.center.y)
            }
        }
        .allowsHitTesting(false)
    }

    /// มุมที่จะปั๊ม — nil = การ์ดใบนี้มีใบที่ปั๊มตราของตัวเองแล้ว
    static func spot(pages: [CardPage], pageSize: CGSize,
                     mark: CGSize, inset: CGSize) -> (page: Int, center: CGPoint)? {
        if pages.contains(where: { $0.items.contains { $0.kind.takesEmboss && $0.emboss } }) { return nil }

        let y = pageSize.height - inset.height - mark.height / 2
        let right = CGPoint(x: pageSize.width - inset.width - mark.width / 2, y: y)
        let left = CGPoint(x: inset.width + mark.width / 2, y: y)

        for i in pages.indices.reversed() {
            let photos = PageLayout.solve(pages[i].items, page: pageSize)
                // ตรารับรองที่ตรึงไว้มีตรา Sale Here STAR ของตัวเองอยู่แล้ว — ปั๊มทับคือเซ็นซ้อน
                .filter { $0.item.kind.usesPhoto || $0.item.kind.isFullBleed || $0.item.pinned }
                .map(\.frame)
            for c in [right, left] {
                let r = CGRect(x: c.x - mark.width / 2, y: c.y - mark.height / 2,
                               width: mark.width, height: mark.height).insetBy(dx: -4, dy: -4)
                if !photos.contains(where: { $0.intersects(r) }) { return (i, c) }
            }
        }
        return (max(0, pages.count - 1), right)
    }
}

// MARK: - S7 · ตราของเวที

/// ตรา "Sale Here STAR" สำหรับโครงของเวที (มุมซ้ายบนของหน้าดู · แถบล่างของรูปที่ส่งออก)
/// ย้อมสีเดียว — บนเวทีมันคือป้ายของสถานที่ ไม่ใช่โลโก้สีแบรนด์
struct StarLockup: View {
    var height: CGFloat = 14
    var tint: Color = .white

    var body: some View {
        Image(SHIcon.star)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .foregroundStyle(tint)
            .accessibilityLabel("Sale Here STAR")
    }
}
