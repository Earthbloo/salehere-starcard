import SwiftUI
import PhosphorSwift

// MARK: - เครื่องหมาย Sale Here แบบเงียบ

/// หน้าตาของเครื่องหมาย Sale Here บน widget ที่ถือข้อมูลซึ่งตรวจแล้ว (ดู `WidgetKind.stampFacts`)
///
/// แสตมป์เต็มดวงเด่นเกินไป (ผู้ใช้ 30 ก.ย. 2569: "ไม่ต้องเด่นมาก แค่เห็นแล้วรู้พอ · แอบ ๆ ใส่ก็ได้")
/// ชุดนี้จึงเป็นเครื่องหมายเล็กที่คนจำได้จาก **ที่เดิม สีเดิม รูปทรงเดิม** ไม่ใช่จากขนาด
/// อิงของที่ทำแบบนี้สำเร็จมาแล้ว:
/// * Levi's Red Tab — แถบผ้าแดงเล็ก ๆ ที่ตะเข็บ จำได้จนแถบเปล่าไม่มีตัวหนังสือก็ยังเป็นเครื่องหมายการค้า
/// * Maison Margiela — ฝีเข็มขาวสี่ฝี ไม่มีโลโก้แต่คนในวงการรู้
/// * "Shot on …" บนรูปจากมือถือ — บรรทัดเดียวที่มุมรูป
/// * ไมโครพรินต์บนธนบัตร — มองไกลเป็นเส้น มองใกล้เป็นตัวอักษร
/// * ตราตอกบนเครื่องเงิน (hallmark) — ตราจิ๋วเรียงแถว บอกผู้ทำและการรับรอง
enum SaleHereMarkStyle: String, CaseIterable, Identifiable {
    case th, en, source, seal, rosette, pill, tab, stitch, credit, hallmark, micro, dot, tape, mini, stamp

    var id: String { rawValue }

    var name: String {
        switch self {
        case .th:       return "ป้ายไทย"
        case .en:       return "ป้ายอังกฤษ"
        case .source:   return "บรรทัดที่มา"
        case .seal:     return "ตรารับรอง"
        case .rosette:  return "ตราริบบิ้น"
        case .pill:     return "ป้ายของแอป"
        case .tab:      return "แถบผ้าแดง"
        case .stitch:   return "ฝีเข็มแดง"
        case .credit:   return "บรรทัดเครดิต"
        case .hallmark: return "ตราตอก"
        case .micro:    return "ไมโครพรินต์"
        case .dot:      return "จุดแดง"
        case .tape:     return "เทปกระดาษ"
        case .mini:     return "แสตมป์จิ๋ว"
        case .stamp:    return "แสตมป์เต็มดวง"
        }
    }

    /// ต้นแบบที่ยืมมา — บรรทัดที่สองบนโต๊ะตรวจงาน
    var source: String {
        switch self {
        case .th:       return "ป้ายขาว โลโก้แดง + \"ยืนยันโดย Sale Here\" — อ่านออกทันที"
        case .en:       return "ป้ายขาว โลโก้แดง + \"Verified by Sale Here\""
        case .source:   return "บรรทัดที่มาแบบอินโฟกราฟิก มุมซ้ายล่าง"
        case .seal:     return "โลโก้จริงในขอบหยักของตรารับรอง + ติ๊กขาว — อ่านได้ทั้ง Sale Here และ Verified"
        case .rosette:  return "ตรารับรองแบบมีริบบิ้น — อ่านเป็นใบประกาศ/รางวัล"
        case .pill:     return "ป้าย VERIFIED BY SALE HERE ตัวจริงจากแอปหลัก"
        case .tab:      return "Levi's Red Tab — แถบแดงเย็บติดขอบขวา"
        case .stitch:   return "Margiela — ฝีเข็มสี่ฝีที่มุม"
        case .credit:   return "\"Shot on iPhone\" — บรรทัดเดียวมุมขวาบน"
        case .hallmark: return "ตราตอกเครื่องเงิน — ตราจิ๋วสามดวงเรียงแถว มุมขวาบน"
        case .micro:    return "ไมโครพรินต์ธนบัตร — เส้นล่างที่อ่านได้เมื่อซูม"
        case .dot:      return "Leica red dot — โลโก้กลมจิ๋วมุมขวาบน"
        case .tape:     return "สแครปบุ๊ก — เทปกระดาษพิมพ์ลายแปะขอบบน"
        case .mini:     return "แสตมป์ดวงเล็ก ไม่มีตราประทับ"
        case .stamp:    return "แบบเดิม (เด่นเกิน) — ไว้เทียบ"
        }
    }

    /// ค่าที่ใช้ทั้งแอป — ยังไม่ได้เลือก จึงเป็นแบบเงียบที่จำได้ที่สุดก่อน · สลับได้ด้วย `-saleHereMark <ชื่อ>`
    static var current: SaleHereMarkStyle {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-saleHereMark"), a.indices.contains(i + 1),
           let s = SaleHereMarkStyle(rawValue: a[i + 1]) { return s }
        return .th
    }
}

private struct SaleHereMarkStyleKey: EnvironmentKey {
    static let defaultValue = SaleHereMarkStyle.current
}

extension EnvironmentValues {
    /// โต๊ะตรวจงานสลับแบบทีละแถวได้โดยไม่ต้องรีสตาร์ต
    var saleHereMarkStyle: SaleHereMarkStyle {
        get { self[SaleHereMarkStyleKey.self] }
        set { self[SaleHereMarkStyleKey.self] = newValue }
    }
}

/// เครื่องหมายหนึ่งดวงบน widget หนึ่งใบ — วาดเต็มกรอบของใบ แล้วแต่ละแบบวางตัวเองที่มุมของมัน
struct SaleHereMarkView: View {
    let style: SaleHereMarkStyle
    /// หมึกตัวหนังสือของใบนั้น — ใช้แค่กับตราประทับของแสตมป์
    /// (แบบอื่นเป็นแดงล้วน: ใบที่วาดแผ่นเองไม่ได้ใช้หมึกของการ์ด หมึกนี้จึงหายไปบนแผ่นเข้มของโปสเตอร์)
    let ink: Color
    var date: String = Signature.verifiedOn
    /// ใบชิดขอบบนของการ์ด — ป้ายคำคร่อมขอบล่างแทนขอบบน
    var bottom = false

    static let red = SaleHereMark.red

    var body: some View {
        switch style {
        case .th:       label(SaleHereLabel(text: "ยืนยันโดย Sale Here"))
        case .en:       label(SaleHereLabel(text: "Verified by Sale Here"))
        case .source:
            SaleHereLabel(text: "ข้อมูลจาก Sale Here", compact: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 12).padding(.bottom, 9)
        case .seal:     corner(SaleHereSeal(size: 24), top: 11)
        case .rosette:  corner(SaleHereSeal(size: 23, check: false, ribbons: true), top: 8)
        case .pill:     corner(Image(SHIcon.verifiedPill).resizable().scaledToFit().frame(height: 15)
                                .shadow(color: .black.opacity(0.25), radius: 1, y: 0.5))
        case .tab:      tab
        case .stitch:   stitch
        case .credit:   credit
        case .hallmark: hallmark
        case .micro:    micro
        case .dot:      dot
        case .tape:     tape
        case .mini:     mini
        case .stamp:    stamp
        }
    }

    /// ป้ายคำ **คร่อมขอบบน** ของใบ ชิดขวา — เหมือนป้ายชื่อบนแฟ้ม: บังแค่เส้นขอบ ไม่บังเนื้อหา
    /// (วางด้านในใบแล้วบัง "Trusted by" · ตัวเลข · แถบวิ่ง บนการ์ดจริง)
    /// ใบที่ชิดขอบบนของการ์ด (`bottom`) คร่อมขอบล่างแทน ไม่งั้นครึ่งบนโดนการ์ดตัด
    private func label(_ v: SaleHereLabel) -> some View {
        v.alignmentGuide(bottom ? .bottom : .top) { d in d.height / 2 }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: bottom ? .bottomTrailing : .topTrailing)
            .padding(.trailing, 16)
    }

    /// มุมขวาบนด้านในใบ — ที่เดียวกับป้ายที่มาเดิม ("กรอกเอง · รอตรวจสอบ") ตาจึงหาเจอที่เดิมทุกใบ
    private func corner<V: View>(_ v: V, top: CGFloat = 9) -> some View {
        // เว้นจากขอบขวา 15 — ใบกระจกมุมมน 22 ถ้าชิดกว่านี้ตราไปทับเส้นโค้งของมุม
        v.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, top).padding(.trailing, 15)
    }

    // MARK: แถบผ้าแดง — โผล่จากขอบขวาของใบ เหมือนแถบที่เย็บติดตะเข็บกระเป๋า

    private var tab: some View {
        // ยาว 22 · เย็บติดขอบขวา **ด้านในใบ** โผล่พ้นขอบแค่ 2pt — ใบที่กว้างเต็มการ์ด (แถบวิ่ง)
        // ขอบขวาคือขอบการ์ด แถบที่โผล่ออกไปครึ่งหนึ่งถูกการ์ดตัดเหลือเศษแดงเส้นเดียว
        let h: CGFloat = 11, out: CGFloat = 22
        return ZStack(alignment: .leading) {
            UnevenRoundedRectangle(topLeadingRadius: 1.2, bottomLeadingRadius: 1.2,
                                   bottomTrailingRadius: 2.2, topTrailingRadius: 2.2, style: .continuous)
                .fill(LinearGradient(colors: [Self.red, Self.red.mix(with: .black, by: 0.22)],
                                     startPoint: .top, endPoint: .bottom))
            // เนื้อผ้าทอ — เส้นแนวนอนจาง ๆ
            VStack(spacing: 1.1) {
                ForEach(0..<5, id: \.self) { _ in Rectangle().fill(.white.opacity(0.07)).frame(height: 0.5) }
            }
            .padding(.vertical, 1.5)
            Image(SHIcon.wordmark)
                .renderingMode(.template).resizable().scaledToFit()
                .foregroundStyle(.white)
                .frame(height: h - 2.4)
                .frame(maxWidth: .infinity)
                .padding(.leading, 3)
        }
        .frame(width: out, height: h)
        .shadow(color: .black.opacity(0.28), radius: 1, x: 0.5, y: 0.8)
        .offset(x: 2)
        // ห่างขอบบน 22 เหมือนกันทุกใบ — ใบเตี้ย (แถบวิ่ง · แถวโลโก้) ย้ายมากลางความสูงแทน ไม่ไปจมขอบล่าง
        .modifier(TabTop(h: h))
    }

    // MARK: ฝีเข็มแดงสี่ฝี — มุมขวาบน ด้านในใบ

    private var stitch: some View {
        let w: CGFloat = 20, h: CGFloat = 12
        return ZStack {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(Self.red)
                    .frame(width: 4.2, height: 1.4)
                    .rotationEffect(.degrees(i % 2 == 0 ? -32 : 32))
                    .offset(x: (i % 2 == 0 ? -1 : 1) * w / 2, y: (i < 2 ? -1 : 1) * h / 2)
            }
        }
        .frame(width: w + 6, height: h + 4)
        .shadow(color: .black.opacity(0.18), radius: 0.4, y: 0.4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 9).padding(.trailing, 9)
    }

    // MARK: บรรทัดเครดิต — แบบ "Shot on" มุมขวาล่าง

    private var credit: some View {
        HStack(spacing: 4) {
            SaleHereMark(size: 11)
            Text("Verified by Sale Here")
                .font(.sh(7.5, .semibold))
                .foregroundStyle(Self.red)
                .lineLimit(1).fixedSize()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 9).padding(.trailing, 10)
    }

    // MARK: ตราตอก — สามดวงเรียงแถว มุมขวาล่าง หมึกของใบ ดวงแรกแดง

    private var hallmark: some View {
        HStack(spacing: 2.5) {
            // ดวงผู้ทำ — โลโก้จริงในกรอบโล่ (ดวงเดียวที่เป็นแดง)
            ZStack {
                Shield().fill(Self.red)
                Image(SHIcon.wordmark).renderingMode(.template).resizable().scaledToFit()
                    .foregroundStyle(.white).padding(2.2).padding(.bottom, 1)
            }
            .frame(width: 13, height: 14)
            // ดวงรับรอง — ✓ ในวงรี
            ZStack {
                Ellipse().strokeBorder(Self.red, lineWidth: 0.9)
                Image(systemName: "checkmark").font(.system(size: 6, weight: .heavy)).foregroundStyle(Self.red)
            }
            .frame(width: 15, height: 11)
            // ดวงปี — ปีที่ตรวจในกรอบสี่เหลี่ยมตัดมุม
            ZStack {
                RoundedRectangle(cornerRadius: 1.5).strokeBorder(Self.red, lineWidth: 0.9)
                Text(String(date.suffix(2)))
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(Self.red)
            }
            .frame(width: 14, height: 11)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 8).padding(.trailing, 10)
    }

    // MARK: ไมโครพรินต์ — เส้นล่างของใบที่จริง ๆ เป็นตัวอักษร

    private var micro: some View {
        HStack(spacing: 3) {
            Text(String(repeating: "SALE HERE VERIFIED ", count: 12))
                .font(.system(size: 3.4, weight: .bold, design: .monospaced))
                .tracking(0.25)
                .foregroundStyle(Self.red.opacity(0.8))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()
            SaleHereMark(size: 7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.horizontal, 14).padding(.bottom, 5)
    }

    // MARK: จุดแดง — โลโก้กลมจิ๋วมุมขวาบน

    private var dot: some View {
        SaleHereMark(size: 14)
            .shadow(color: .black.opacity(0.2), radius: 0.8, y: 0.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 9).padding(.trailing, 9)
    }

    // MARK: เทปกระดาษ — แปะคร่อมขอบบน ลายตัวเขียนจาง

    private var tape: some View {
        ZStack {
            Rectangle().fill(Color(red: 1, green: 0.93, blue: 0.92).opacity(0.78))
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Image(SHIcon.wordmark).renderingMode(.template).resizable().scaledToFit()
                        .foregroundStyle(Self.red.opacity(0.85)).frame(height: 8)
                }
            }
        }
        .frame(width: 44, height: 12)
        .mask(TornEnds())
        .shadow(color: .black.opacity(0.14), radius: 0.8, y: 0.6)
        .rotationEffect(.degrees(-7))
        .offset(y: -5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.trailing, 18)
    }

    // MARK: แสตมป์ — ดวงเล็กไม่มีตราประทับ / ดวงเต็มแบบเดิม

    private var mini: some View {
        SaleHereStamp(width: 22, date: date, tilt: 4, ink: ink, cancelled: false)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 7).padding(.trailing, 8)
    }

    private var stamp: some View {
        GeometryReader { geo in
            let w = min(50, max(40, min(geo.size.width, geo.size.height) * 0.22))
            SaleHereStamp(width: w, ink: ink)
                .offset(x: w * 0.12, y: -w * 0.3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }
}

private struct TabTop: ViewModifier {
    let h: CGFloat
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, min(22, max(4, (geo.size.height - h) / 2)))
        }
    }
}

/// โล่ของตราผู้ทำ — บนตรง ล่างโค้งลงเป็นปลายแหลม
private struct Shield: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.55))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY * 0.92))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.55), control: CGPoint(x: r.minX, y: r.maxY * 0.92))
        p.closeSubpath()
        return p
    }
}

/// ปลายเทปฉีกเป็นฟันเลื่อยเล็ก ๆ ทั้งสองข้าง
private struct TornEnds: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let n = 5, d: CGFloat = 1.6
        p.move(to: CGPoint(x: r.minX + d, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - d, y: r.minY))
        for i in 1...n {
            let y = r.minY + r.height * CGFloat(i) / CGFloat(n)
            p.addLine(to: CGPoint(x: r.maxX - (i % 2 == 0 ? d : 0), y: y))
        }
        p.addLine(to: CGPoint(x: r.minX + d, y: r.maxY))
        for i in stride(from: n - 1, through: 0, by: -1) {
            let y = r.minY + r.height * CGFloat(i) / CGFloat(n)
            p.addLine(to: CGPoint(x: r.minX + (i % 2 == 0 ? d : 0), y: y))
        }
        p.closeSubpath()
        return p
    }
}


// MARK: - ตรารับรอง Sale Here

/// โลโก้กลมแดงของแอป **ตัวจริง** แต่ขอบเป็นหยักแบบตรารับรอง + ติ๊กขาวที่มุม — ของชิ้นเดียวที่อ่านได้สองอย่างพร้อมกัน
///
/// * ขอบหยัก = "ผ่านการรับรอง" (ทรงเดียวกับติ๊กฟ้าของ IG/X และตรา ic-seal-check ของแอป) — คนอ่านออกโดยไม่ต้องมีคำ
/// * แดง + ตัวเขียน Sale Here = ใครเป็นคนรับรอง — โลโก้กลมนี้คือไอคอนที่ผู้ใช้แอปเห็นทุกวัน
/// * ติ๊กขาวที่มุม = คำตอบว่าตรวจแล้ว (ไม่ใช่แค่โลโก้แปะ)
/// * ขอบขาวแบบสติกเกอร์ไดคัท — แดงบนการ์ดเลือดหมู/ชมพูกลืนกันถ้าไม่มีขอบ
struct SaleHereSeal: View {
    var size: CGFloat = 22
    var check = true
    var ribbons = false

    private static let red = SaleHereMark.red
    private static let deep = SaleHereMark.red.mix(with: .black, by: 0.28)

    var body: some View {
        ZStack {
            if ribbons {
                // หางริบบิ้นสองเส้นลอดใต้ตรา — ตราประกาศ/รางวัล
                HStack(spacing: size * 0.02) {
                    RibbonTail().fill(Self.deep).frame(width: size * 0.3, height: size * 0.62)
                        .rotationEffect(.degrees(16), anchor: .top)
                    RibbonTail().fill(Self.deep).frame(width: size * 0.3, height: size * 0.62)
                        .rotationEffect(.degrees(-16), anchor: .top)
                }
                .overlay(HStack(spacing: size * 0.02) {
                    RibbonTail().stroke(.white, lineWidth: max(0.6, size * 0.035)).frame(width: size * 0.3, height: size * 0.62)
                        .rotationEffect(.degrees(16), anchor: .top)
                    RibbonTail().stroke(.white, lineWidth: max(0.6, size * 0.035)).frame(width: size * 0.3, height: size * 0.62)
                        .rotationEffect(.degrees(-16), anchor: .top)
                })
                .offset(y: size * 0.46)
            }
            ZStack {
                // ไดคัทขาว
                Scallop(bumps: 14, depth: 0.075).fill(.white)
                    .frame(width: size * 1.13, height: size * 1.13)
                Scallop(bumps: 14, depth: 0.075)
                    .fill(LinearGradient(colors: [Self.red, Self.deep], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: size, height: size)
                Circle()
                    .strokeBorder(.white.opacity(0.55), lineWidth: max(0.45, size * 0.028))
                    .frame(width: size * 0.74, height: size * 0.74)
                Image(SHIcon.wordmark)
                    .renderingMode(.template).resizable().scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: size * 0.5, height: size * 0.5)
            }
            .frame(width: size, height: size)
            .overlay(alignment: .bottomTrailing) {
                if check {
                    ZStack {
                        Circle().fill(.white)
                        Image(systemName: "checkmark")
                            .font(.system(size: size * 0.24, weight: .black))
                            .foregroundStyle(Self.red)
                    }
                    .frame(width: size * 0.44, height: size * 0.44)
                    .offset(x: size * 0.1, y: size * 0.08)
                }
            }
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .shadow(color: .black.opacity(0.28), radius: max(0.6, size * 0.04), y: size * 0.03)
        .accessibilityElement()
        .accessibilityLabel("Verified by Sale Here")
    }
}

/// วงกลมขอบหยัก — ทรงของตรารับรอง
struct Scallop: Shape {
    var bumps = 14
    var depth: CGFloat = 0.075

    func path(in r: CGRect) -> Path {
        let c = CGPoint(x: r.midX, y: r.midY)
        let R = min(r.width, r.height) / 2
        var p = Path()
        let steps = bumps * 12
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps) * .pi * 2
            let rr = R * (1 - depth + depth * cos(CGFloat(bumps) * t)) / 1
            let pt = CGPoint(x: c.x + rr * cos(t), y: c.y + rr * sin(t))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// หางริบบิ้น — ปลายล่างตัดเป็นร่องตัววี
private struct RibbonTail: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY - r.width * 0.45))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}


// MARK: - ป้ายคำ Sale Here

/// ป้ายที่ **อ่านเป็นคำ** — โลโก้กลมแดงของแอป + ประโยคสั้น บนแคปซูลขาว
///
/// ตรารูปทรง (แสตมป์ · แถบผ้า · ตราหยัก) ถูกตีกลับว่า "ดูยาก เข้าใจยาก" (ผู้ใช้ 30 ก.ย. 2569)
/// คำว่า "ยืนยันโดย" บอกความหมายตรง ๆ ส่วนโลโก้จริงบอกว่าใคร — ไม่ต้องตีความอะไรเลย
/// พื้นขาวของตัวเองทำให้อ่านออกบนการ์ดทุกสี (หมึกของการ์ดใช้ไม่ได้กับใบที่วาดแผ่นเข้มเอง)
struct SaleHereLabel: View {
    var text: String
    /// บรรทัดที่มา — เล็กกว่า ไม่มีเงา
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 3.5 : 4.5) {
            SaleHereMark(size: compact ? 11 : 13)
            Text(text)
                .font(.sh(compact ? 7.5 : 8.5, .semibold))
                .foregroundStyle(Color(red: 0.09, green: 0.09, blue: 0.11))
                .lineLimit(1).fixedSize()
        }
        .padding(.leading, compact ? 2.5 : 3).padding(.trailing, compact ? 7 : 8)
        .padding(.vertical, compact ? 2 : 2.5)
        .background(Capsule().fill(.white))
        .shadow(color: .black.opacity(compact ? 0.12 : 0.22), radius: compact ? 1 : 2, y: 1)
        .accessibilityElement(children: .combine)
    }
}


// MARK: - บรรทัดยืนยัน (อยู่ในตัว widget)

/// "ยืนยันโดย Sale Here" ที่เป็น **ส่วนหนึ่งของ widget** — ไม่มีพื้น ไม่มีขอบ หมึกเดียวกับตัวหนังสือรองของใบนั้น
/// มีแค่โลโก้กลมแดงของแอปที่คงสีแบรนด์
///
/// ผู้ใช้ 30 ก.ย. 2569: "ขอบ overlay ต้องอยู่ใน widget ใส่แบบเนียน ๆ" — ป้ายที่แปะทับ/คร่อมขอบถูกตีกลับทั้งหมด
/// จึงวางในช่องที่ widget เว้นไว้ให้ป้ายที่มาอยู่แล้ว (ท้ายบรรทัดหัวข้อ `WidgetLabel`) หรือแถบเว้นล่างของโปสเตอร์
struct SaleHereByline: View {
    /// หมึกของใบที่ป้ายนั่งอยู่ — ใช้กับแบบ `.ink`
    var tint: Color
    var size: CGFloat = 8.5
    var tone: Tone = .ink

    /// พื้นของป้ายตามพื้นใต้มัน
    enum Tone {
        /// พื้น/เส้นจาง ๆ จากหมึกของใบ — กลืนกับใบ (ท้ายบรรทัดหัวข้อ)
        case ink
        /// บนรูปถ่าย/แผ่นเข้ม — ดำใส ตัวขาว
        case dark
        /// บนกล่องขาว/กระดาษสว่าง — ขาวทึบ ตัวถ่าน
        case light
    }

    var body: some View {
        // ป้ายขวาบนของ widget (ผู้ใช้ 30 ก.ย. 2569: "ติ๊กแดง และ Verified by icon Sale Here · เป็น badge อยู่ขวาบน ห้ามกลาง")
        // ติ๊กแดงในดาวหยัก + "Verified by" + โลโก้กลมแดงของแอป (โลโก้แทนคำว่า Sale Here)
        HStack(spacing: size * 0.38) {
            ZStack {
                SealShape().fill(SaleHereMark.red)
                PIcon(.check, size: size * 0.78, weight: .bold).foregroundStyle(.white)
            }
            .frame(width: size * 1.45, height: size * 1.45)
            Text("Verified by")
                .font(.sh(size, .semibold))
                .foregroundStyle(text)
                .lineLimit(1).fixedSize()
            SaleHereMark(size: size * 1.7)
        }
        .padding(.leading, size * 0.42).padding(.trailing, size * 0.3)
        .padding(.vertical, size * 0.26)
        .background(Capsule().fill(fill))
        .overlay(Capsule().strokeBorder(stroke, lineWidth: 0.5))
        .fixedSize()
        .accessibilityElement()
        .accessibilityLabel("Verified by Sale Here")
    }

    private var text: Color {
        switch tone {
        case .ink:   return tint
        case .dark:  return .white.opacity(0.92)
        case .light: return Color(white: 0.1).opacity(0.85)
        }
    }
    private var fill: Color {
        switch tone {
        case .ink:   return tint.opacity(0.12)
        case .dark:  return .black.opacity(0.38)
        case .light: return .white.opacity(0.92)
        }
    }
    private var stroke: Color {
        switch tone {
        case .ink:   return tint.opacity(0.2)
        case .dark:  return .white.opacity(0.22)
        case .light: return .black.opacity(0.08)
        }
    }
}
