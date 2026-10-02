import SwiftUI

// MARK: - แสตมป์ Sale Here

/// ดวงแสตมป์ที่ Sale Here ติดให้ widget ซึ่งถือข้อมูลที่ตรวจแล้ว — ยอดผู้ติดตาม · งานที่ผ่านระบบ
///
/// # ทำไมเป็นแสตมป์
///
/// ป้ายแคปซูล ("Verified · 2 ชม.") อ่านเป็นปุ่มของแอป ไม่ใช่ของบนงาน และหมึกเดียวกับการ์ด
/// ทำให้มองจากภาพรวมแล้วไม่รู้ว่ามาจาก Sale Here (ผู้ใช้ 30 ก.ย. 2569: "ใน widget มันต้องมีตรงไหน
/// ที่บอกว่าเป็นของ sale here" · "มันต้องดู Art กว่านี้")
///
/// แสตมป์คือของที่ **คนอื่นติดให้** — ไม่มีใครพิมพ์แสตมป์ลงบนซองของตัวเอง ความหมายนี้คนรู้อยู่แล้ว
/// มันจึงบอก "ผ่าน Sale Here มาแล้ว" ได้โดยไม่ต้องอ่านคำ และยังเป็นของสะสมที่อยู่ในโลกเดียวกับ
/// สติกเกอร์ · เทป · โพลารอยด์ของสำรับการ์ด ไม่ใช่ UI ที่หลุดเข้ามาในรูป
///
/// # กติกา
///
/// * **ของชิ้นเดียว** — ดวงแดง ตัวเขียน Sale Here ของจริงสีขาว ตราประทับวันที่ทับมุม
///   (ไม่ประกอบจากเหรียญ + ตัวพิมพ์ + โลโก้ ซึ่งผู้ใช้เคยตีกลับว่า "โครตจะไม่สวย")
/// * แดงของแบรนด์เต็มดวง — ไม่ย้อมตามธีม (ตราที่เปลี่ยนสีตามของที่มันรับรองคือของตกแต่ง)
/// * ไม่ขยับ ไม่มีรุ้ง — ดวงเดียวเล็ก ๆ ต้องไม่แย่งสายตาจากงานของเจ้าของ
/// * ติดที่เดิมทุกใบ: มุมขวาบน คร่อมขอบบนนิดหนึ่ง เหมือนแสตมป์ที่ติดมุมซอง
struct SaleHereStamp: View {
    /// ความกว้างของดวง (ไม่รวมตราประทับ) — ความสูงคิดตามสัดส่วนแสตมป์ 5:6
    var width: CGFloat = 40
    /// วันที่บนตราประทับ — วันที่ Sale Here ตรวจข้อมูลชิ้นนี้
    var date: String = Signature.verifiedOn
    /// เอียงดวงเล็กน้อย — แสตมป์ที่ติดตรงเป๊ะอ่านเป็นไอคอน ไม่ใช่ของที่ติดด้วยมือ
    var tilt: Double = 5
    /// หมึกตราประทับ — หมึกของตัวหนังสือบนใบนั้น (ครีมบนใบมืด · ถ่านบนใบสว่าง)
    /// หมึกไปรษณีย์สีดำตายตัวทับใบมืดแล้วหายไปครึ่งวง เหลือเป็นรอยเปื้อน
    var ink: Color = SaleHereStamp.cancel
    /// มีตราประทับวันที่ทับดวงไหม — ดวงจิ๋วไม่มี (วงวันที่เล็กกว่านั้นอ่านไม่ออก เหลือแต่รอยเปื้อน)
    var cancelled: Bool = true

    static let red = Color(red: 0.86, green: 0.13, blue: 0.15)
    static let paper = Color(red: 1.0, green: 0.988, blue: 0.965)
    /// หมึกตราประทับ — ดำอมน้ำเงินแบบหมึกไปรษณีย์ ทับบนแดงแล้วยังอ่านออก
    static let cancel = Color(red: 0.10, green: 0.11, blue: 0.16)

    private var height: CGFloat { width * 1.2 }

    var body: some View {
        let d = width * 0.78
        ZStack {
            stamp
            if cancelled { cancellation(d) }
        }
        .rotationEffect(.degrees(tilt))
        .frame(width: width, height: height)
        .accessibilityElement()
        .accessibilityLabel("ตรวจสอบโดย Sale Here \(date)")
    }

    @ViewBuilder private func cancellation(_ d: CGFloat) -> some View {
        Group {
            // วงวันที่นั่งมุมล่างซ้ายของดวง ครึ่งวงอยู่บนใบ — วันที่จึงอ่านบนพื้นของใบ ไม่ทับตัวเขียน
            postmark
                .frame(width: d, height: d)
                .offset(x: -width * 0.66, y: height * 0.30)
            // เส้นคลื่นยกเลิกดวง — จากขอบวงไปจบบนดวง ไม่ล้นออกนอกแสตมป์
            CancelWaves()
                .stroke(ink, style: StrokeStyle(lineWidth: max(0.5, d * 0.028), lineCap: .round))
                .frame(width: width * 0.62, height: d * 0.36)
                .offset(x: width * 0.08, y: height * 0.30)
                .opacity(0.7)
        }
    }

    // MARK: ดวงแสตมป์

    private var stamp: some View {
        let edge = width * 0.085
        return ZStack {
            // กระดาษ + รอยปรุ
            Perforated(pitch: width / 8.5, hole: width * 0.034)
                .fill(Self.paper)

            // ช่องพิมพ์ — แดงเต็มช่อง ลายเส้นแกะจาง ๆ แบบแสตมป์พิมพ์ intaglio
            ZStack {
                Rectangle().fill(
                    LinearGradient(colors: [Self.red, Self.red.mix(with: .black, by: 0.18)],
                                   startPoint: .top, endPoint: .bottom))
                EngraveLines()
                    .stroke(.white.opacity(0.10), lineWidth: max(0.35, width * 0.008))
                Rectangle()
                    .strokeBorder(.white.opacity(0.85), lineWidth: max(0.5, width * 0.012))
                    .padding(width * 0.035)

                VStack(spacing: 0) {
                    Text("VERIFIED")
                        .font(.system(size: width * 0.095, weight: .heavy, design: .monospaced))
                        .tracking(width * 0.012)
                        .lineLimit(1).fixedSize()
                    Spacer(minLength: 0)
                    Image(SHIcon.wordmark)
                        .renderingMode(.template)
                        .resizable().scaledToFit()
                        .frame(width: width * 0.60)
                    Spacer(minLength: 0)
                    Text("★ STAR ★")
                        .font(.system(size: width * 0.085, weight: .bold, design: .monospaced))
                        .tracking(width * 0.01)
                        .lineLimit(1).fixedSize()
                }
                .foregroundStyle(.white)
                .padding(.vertical, width * 0.075)
            }
            .clipShape(Rectangle())
            .padding(edge)
        }
        .frame(width: width, height: height)
        .compositingGroup()
        // กระดาษบางที่แปะลงบนแผ่น — เงาชิดคม + เงานุ่มกว้าง ไม่ลอย
        .shadow(color: .black.opacity(0.30), radius: max(0.6, width * 0.02), y: width * 0.015)
        .shadow(color: .black.opacity(0.16), radius: width * 0.12, y: width * 0.07)
    }

    // MARK: ตราประทับวันที่

    private var postmark: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            let lw = max(0.5, d * 0.028)
            ZStack {
                Circle().strokeBorder(ink, lineWidth: lw)
                Circle().strokeBorder(ink, lineWidth: lw * 0.6).padding(d * 0.22)
                StampRingText(text: "SALE HERE · VERIFIED · ", radius: d * 0.39, size: d * 0.11)
                    .foregroundStyle(ink)
                    .frame(width: d, height: d)
                Text(date)
                    .font(.system(size: d * 0.12, weight: .bold, design: .monospaced))
                    .foregroundStyle(ink)
                    .lineLimit(1).fixedSize()
            }
            .frame(width: d, height: d)
        }
        // หมึกประทับไม่เต็มแผ่นเสมอ — จางลงนิดให้เห็นกระดาษกับแดงข้างใต้
        .opacity(0.72)
        .rotationEffect(.degrees(-14))
    }
}

// MARK: - ชิ้นส่วน

/// กระดาษแสตมป์ที่มีรอยปรุรอบดวง — วงเจาะครึ่งวงตลอดทั้งสี่ขอบ
struct Perforated: Shape {
    var pitch: CGFloat
    var hole: CGFloat

    func path(in rect: CGRect) -> Path {
        var holes = Path()
        func run(from a: CGPoint, to b: CGPoint) {
            let len = hypot(b.x - a.x, b.y - a.y)
            let n = max(2, Int((len / pitch).rounded()))
            for i in 0...n {
                let t = CGFloat(i) / CGFloat(n)
                let c = CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
                holes.addEllipse(in: CGRect(x: c.x - hole, y: c.y - hole, width: hole * 2, height: hole * 2))
            }
        }
        run(from: CGPoint(x: rect.minX, y: rect.minY), to: CGPoint(x: rect.maxX, y: rect.minY))
        run(from: CGPoint(x: rect.minX, y: rect.maxY), to: CGPoint(x: rect.maxX, y: rect.maxY))
        run(from: CGPoint(x: rect.minX, y: rect.minY), to: CGPoint(x: rect.minX, y: rect.maxY))
        run(from: CGPoint(x: rect.maxX, y: rect.minY), to: CGPoint(x: rect.maxX, y: rect.maxY))
        return Path(Path(rect).cgPath.subtracting(holes.cgPath))
    }
}

/// เส้นแกะแนวนอนเป็นคลื่นเตี้ย ๆ — ผิวของแสตมป์พิมพ์แบบแกะเหล็ก
private struct EngraveLines: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let gap = max(1.6, rect.height / 22)
        var y = rect.minY
        while y <= rect.maxY {
            p.move(to: CGPoint(x: rect.minX, y: y))
            let steps = 12
            for i in 1...steps {
                let x = rect.minX + rect.width * CGFloat(i) / CGFloat(steps)
                p.addLine(to: CGPoint(x: x, y: y + sin(CGFloat(i) * .pi / 3) * gap * 0.22))
            }
            y += gap
        }
        return p
    }
}

/// เส้นคลื่นสามเส้นของตรายกเลิกดวง
private struct CancelWaves: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        for row in 0..<3 {
            let y = rect.minY + rect.height * (0.18 + 0.32 * CGFloat(row))
            p.move(to: CGPoint(x: rect.minX, y: y))
            let steps = 24
            for i in 1...steps {
                let t = CGFloat(i) / CGFloat(steps)
                p.addLine(to: CGPoint(x: rect.minX + rect.width * t,
                                      y: y + sin(t * .pi * 4) * rect.height * 0.08))
            }
        }
        return p
    }
}

/// ตัวอักษรเรียงรอบวง — วางทีละตัวแล้วหมุนตามมุม (SwiftUI ไม่มี text-on-path)
private struct StampRingText: View {
    let text: String
    let radius: CGFloat
    let size: CGFloat

    var body: some View {
        let chars = Array(text)
        ZStack {
            ForEach(chars.indices, id: \.self) { i in
                let a = Double(i) / Double(chars.count) * 360 - 90
                Text(String(chars[i]))
                    .font(.system(size: size, weight: .bold, design: .monospaced))
                    .fixedSize()
                    .offset(y: -radius)
                    .rotationEffect(.degrees(a + 90))
            }
        }
    }
}

// MARK: - ใครได้แสตมป์

/// ข้อมูลที่ widget ถืออยู่ซึ่ง **มาจาก Sale Here** — ตัดสินว่าใบไหนได้เครื่องหมาย
///
/// ผู้ใช้ 30 ก.ย. 2569: "วางใน widget ที่เป็นข้อมูลที่มาจากเรา เช่น follow กับ Insight แบรนด์ที่ร่วมงาน"
enum StampFacts {
    /// ยอดผู้ติดตาม — ระบบดึงยอดจากลิงก์ที่ผู้ใช้วาง
    case followers
    /// สถิติผู้ชม (Insight) — ระบบเป็นคนสรุปให้
    case insight
    /// แบรนด์/งานที่ทำผ่านระบบ — ระบบออกให้จากงานที่ส่งจริง
    case work

    /// ทุกตระกูลได้เครื่องหมายเมื่อใบนั้นปลดล็อกแล้ว (ข้อมูลเข้ามาแล้ว — ดู `missing` ใน `WidgetChrome`)
    ///
    /// ยอดผู้ติดตามไม่รอสถานะ "ยืนยันผ่านการเชื่อมบัญชี" อีกแล้ว: ใน flow จริงผู้ใช้วางลิงก์ แล้วระบบเราดึงยอดเอง
    /// ยอดจึงมาจาก Sale Here ตั้งแต่แรก — รอสถานะนั้นแล้วเครื่องหมายไม่ขึ้นสักใบบนเครื่องจริง
    /// (ผู้ใช้ 30 ก.ย. 2569: "ไม่เห็นจะมีสัก widget")
    var verified: Bool { true }
}

extension WidgetKind {
    /// widget ที่แสดงข้อมูลซึ่งมาจาก Sale Here — ตัวอื่น (รูป · เรต · สายงาน · ข้อความที่พิมพ์เอง) ไม่ได้เครื่องหมาย
    ///
    /// เฉพาะใบที่ **มีช่องให้บรรทัดยืนยันอยู่ในตัว** (ท้ายบรรทัดหัวข้อ หรือแถบเว้นของโปสเตอร์) —
    /// ใบที่ไม่มีช่องจะไม่ได้บรรทัดนี้จนกว่าจะออกแบบช่องให้ ไม่แปะทับเนื้อหา
    var stampFacts: StampFacts? {
        if popRole == .stats { return .followers }
        switch self {
        case .statGiant, .socialChips, .socialTiles, .statPoster, .statWrapped, .socialWindow, .socialGingham:
            return .followers
        case .audienceSplit, .audienceAge, .audienceLine, .audienceMap, .audiencePoster, .scrapStats:
            return .insight
        case .proofBrandGrid, .proofBrandRail, .proofBrandCoins, .proofWork, .proofTicket, .wallPolaroid:
            return .work
        default:
            return nil
        }
    }
}

extension WidgetKind {
    /// ใบที่ **ไม่มีช่องหัวข้อ** ให้ป้าย — chrome วางป้ายมุมขวาบนด้านในให้ (ตำแหน่งจูนทีละใบจากหน้าตาจริง)
    /// ใบที่มีช่องแล้ว (ท้าย `WidgetLabel` · โปสเตอร์สถิติ) คืน nil
    var stampOverlay: (tone: SaleHereByline.Tone, top: CGFloat, trailing: CGFloat)? {
        switch self {
        case .statWrapped:    return (.dark, 12, 12)
        case .socialWindow:   return (.light, 1.5, 10)
        case .socialGingham:  return (.light, 5, 12)
        case .audienceLine:   return (.ink, 12, 12)
        case .audiencePoster: return (.dark, 12, 12)
        case .scrapStats:     return (.light, 6, 14)
        case .wallPolaroid:   return (.light, 4, 8)
        default:              return nil
        }
    }
}

// MARK: - บอกชิ้นข้างในว่ามีแสตมป์แล้ว

private struct SaleHereStampedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// ใบนี้มีแสตมป์ Sale Here ติดอยู่ — ป้าย Verified เดิมในหัวข้อ (`ProvenanceTag` · `VerifiedBadge`)
    /// จึงหลบให้ ไม่รับรองซ้ำสองที่ในใบเดียว
    var saleHereStamped: Bool {
        get { self[SaleHereStampedKey.self] }
        set { self[SaleHereStampedKey.self] = newValue }
    }
}
