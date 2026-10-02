import SwiftUI

// MARK: - ตรา ST★R ของ Sale Here เป็นหัวข้อ
//
// ผู้ใช้ 30 ก.ย. 2569: "เอา STAR ใน icon มาใส่แทนเลย Card/Profile ใช้ font เหมือนเดิม" — คำ "Star" ตัวหนาในหัวข้อ
// จึงถูกแทนด้วยเวกเตอร์ ST★R ตัวจริงจาก `ic-salehere-star-outline.pdf` (เฉพาะตัวพิมพ์ใหญ่ ตัดตัวเขียน Sale Here ด้านบนออก)
// ส่วน Card / Profile ยังเป็น Didot Italic ไล่หมึก→ทองเท่าเดิม  ดูแคนวาสเทียบแบบ: claude.ai/artifact/4fXrX4Lqpu97rh2GcBgS5Q
//
// วาดเป็น Shape ไม่ใช่ Image เพราะต้องย้อมสีตามพื้น (หมึกบนสว่าง · ขาวบนการ์ดมืด) และต้องวางบน baseline เดียวกับคำ serif

/// เส้นทางของตัว S T ★ R — พิกัดเดิมจาก PDF (กรอบ x 0.8…33.2 · y 10.7…21.1 · baseline ตัวอักษรที่ y 20.8)
struct StarCapsShape: Shape {
    static let box = CGRect(x: 0.8, y: 10.7, width: 32.4, height: 10.4)
    /// กว้าง : สูง ของตรา
    static let aspect = box.width / box.height
    /// ส่วนที่ตัว S ล้นใต้ baseline (สัดส่วนของความสูง) — ใช้ยก baseline ให้ตรงกับคำ serif
    static let descent = (21.1 - 20.8) / box.height

    func path(in rect: CGRect) -> Path {
        let s = rect.width / Self.box.width
        func pt(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: rect.minX + (x - Self.box.minX) * s, y: rect.minY + (y - Self.box.minY) * s)
        }
        var p = Path()
            p.move(to: pt(20.684, 14.485))
            p.addLine(to: pt(19.098, 11.244))
            p.addLine(to: pt(17.512, 14.485))
            p.addLine(to: pt(13.965, 15.006))
            p.addLine(to: pt(16.531, 17.528))
            p.addLine(to: pt(15.926, 21.091))
            p.addLine(to: pt(19.098, 19.409))
            p.addLine(to: pt(22.27, 21.091))
            p.addLine(to: pt(21.664, 17.528))
            p.addLine(to: pt(24.23, 15.006))
            p.addLine(to: pt(20.684, 14.485))
            p.closeSubpath()
            p.move(to: pt(19.826, 15.765))
            p.addLine(to: pt(19.093, 14.265))
            p.addLine(to: pt(18.358, 15.765))
            p.addLine(to: pt(16.717, 16.006))
            p.addLine(to: pt(17.905, 17.173))
            p.addLine(to: pt(17.624, 18.822))
            p.addLine(to: pt(19.093, 18.043))
            p.addLine(to: pt(20.56, 18.822))
            p.addLine(to: pt(20.28, 17.173))
            p.addLine(to: pt(21.468, 16.006))
            p.addLine(to: pt(19.826, 15.765))
            p.closeSubpath()
            p.move(to: pt(3.046, 17.554))
            p.addCurve(to: pt(3.221, 18.379), control1: pt(3.046, 17.876), control2: pt(3.104, 18.152))
            p.addCurve(to: pt(3.689, 18.939), control1: pt(3.339, 18.607), control2: pt(3.494, 18.794))
            p.addCurve(to: pt(4.366, 19.258), control1: pt(3.884, 19.084), control2: pt(4.11, 19.191))
            p.addCurve(to: pt(5.168, 19.36), control1: pt(4.622, 19.326), control2: pt(4.89, 19.36))
            p.addCurve(to: pt(5.569, 19.338), control1: pt(5.293, 19.36), control2: pt(5.426, 19.353))
            p.addCurve(to: pt(5.992, 19.266), control1: pt(5.712, 19.323), control2: pt(5.852, 19.299))
            p.addCurve(to: pt(6.393, 19.128), control1: pt(6.131, 19.232), control2: pt(6.265, 19.185))
            p.addCurve(to: pt(6.732, 18.905), control1: pt(6.521, 19.07), control2: pt(6.634, 18.996))
            p.addCurve(to: pt(6.967, 18.583), control1: pt(6.829, 18.814), control2: pt(6.908, 18.707))
            p.addCurve(to: pt(7.056, 18.15), control1: pt(7.026, 18.459), control2: pt(7.056, 18.315))
            p.addCurve(to: pt(6.941, 17.705), control1: pt(7.056, 17.985), control2: pt(7.018, 17.831))
            p.addCurve(to: pt(6.626, 17.375), control1: pt(6.864, 17.579), control2: pt(6.759, 17.469))
            p.addCurve(to: pt(6.153, 17.131), control1: pt(6.493, 17.282), control2: pt(6.335, 17.2))
            p.addCurve(to: pt(5.562, 16.942), control1: pt(5.97, 17.062), control2: pt(5.774, 16.999))
            p.addCurve(to: pt(4.9, 16.777), control1: pt(5.351, 16.886), control2: pt(5.13, 16.831))
            p.addCurve(to: pt(4.204, 16.605), control1: pt(4.67, 16.724), control2: pt(4.437, 16.667))
            p.addCurve(to: pt(3.493, 16.39), control1: pt(3.963, 16.541), control2: pt(3.727, 16.469))
            p.addCurve(to: pt(2.823, 16.113), control1: pt(3.259, 16.31), control2: pt(3.036, 16.219))
            p.addCurve(to: pt(2.23, 15.753), control1: pt(2.61, 16.008), control2: pt(2.412, 15.888))
            p.addCurve(to: pt(1.757, 15.276), control1: pt(2.047, 15.617), control2: pt(1.889, 15.458))
            p.addCurve(to: pt(1.444, 14.648), control1: pt(1.624, 15.093), control2: pt(1.52, 14.884))
            p.addCurve(to: pt(1.331, 13.844), control1: pt(1.369, 14.413), control2: pt(1.331, 14.144))
            p.addCurve(to: pt(1.475, 12.939), control1: pt(1.331, 13.514), control2: pt(1.379, 13.213))
            p.addCurve(to: pt(1.874, 12.203), control1: pt(1.571, 12.664), control2: pt(1.703, 12.419))
            p.addCurve(to: pt(2.472, 11.634), control1: pt(2.043, 11.986), control2: pt(2.243, 11.797))
            p.addCurve(to: pt(3.214, 11.229), control1: pt(2.7, 11.471), control2: pt(2.948, 11.336))
            p.addCurve(to: pt(4.047, 10.989), control1: pt(3.479, 11.123), control2: pt(3.757, 11.043))
            p.addCurve(to: pt(4.914, 10.909), control1: pt(4.336, 10.936), control2: pt(4.625, 10.909))
            p.addCurve(to: pt(5.896, 10.989), control1: pt(5.247, 10.909), control2: pt(5.574, 10.936))
            p.addCurve(to: pt(6.806, 11.234), control1: pt(6.218, 11.043), control2: pt(6.521, 11.124))
            p.addCurve(to: pt(7.593, 11.655), control1: pt(7.09, 11.343), control2: pt(7.353, 11.484))
            p.addCurve(to: pt(8.215, 12.265), control1: pt(7.833, 11.826), control2: pt(8.04, 12.029))
            p.addCurve(to: pt(8.623, 13.071), control1: pt(8.389, 12.5), control2: pt(8.525, 12.77))
            p.addCurve(to: pt(8.769, 14.08), control1: pt(8.72, 13.373), control2: pt(8.769, 13.709))
            p.addLine(to: pt(6.723, 14.08))
            p.addCurve(to: pt(6.545, 13.356), control1: pt(6.707, 13.79), control2: pt(6.648, 13.549))
            p.addCurve(to: pt(6.14, 12.899), control1: pt(6.443, 13.164), control2: pt(6.308, 13.012))
            p.addCurve(to: pt(5.556, 12.662), control1: pt(5.972, 12.786), control2: pt(5.777, 12.707))
            p.addCurve(to: pt(4.85, 12.594), control1: pt(5.336, 12.617), control2: pt(5.1, 12.594))
            p.addCurve(to: pt(4.329, 12.65), control1: pt(4.678, 12.594), control2: pt(4.504, 12.613))
            p.addCurve(to: pt(3.856, 12.833), control1: pt(4.155, 12.687), control2: pt(3.997, 12.748))
            p.addCurve(to: pt(3.511, 13.17), control1: pt(3.715, 12.919), control2: pt(3.6, 13.031))
            p.addCurve(to: pt(3.376, 13.683), control1: pt(3.421, 13.309), control2: pt(3.376, 13.48))
            p.addCurve(to: pt(3.422, 14.003), control1: pt(3.376, 13.806), control2: pt(3.392, 13.913))
            p.addCurve(to: pt(3.582, 14.245), control1: pt(3.452, 14.093), control2: pt(3.505, 14.174))
            p.addCurve(to: pt(3.902, 14.444), control1: pt(3.659, 14.316), control2: pt(3.766, 14.382))
            p.addCurve(to: pt(4.423, 14.637), control1: pt(4.038, 14.505), control2: pt(4.211, 14.57))
            p.addCurve(to: pt(5.183, 14.855), control1: pt(4.634, 14.704), control2: pt(4.887, 14.778))
            p.addCurve(to: pt(6.228, 15.131), control1: pt(5.479, 14.933), control2: pt(5.828, 15.024))
            p.addCurve(to: pt(6.687, 15.248), control1: pt(6.346, 15.161), control2: pt(6.499, 15.2))
            p.addCurve(to: pt(7.287, 15.452), control1: pt(6.874, 15.296), control2: pt(7.074, 15.364))
            p.addCurve(to: pt(7.931, 15.783), control1: pt(7.5, 15.539), control2: pt(7.714, 15.649))
            p.addCurve(to: pt(8.514, 16.282), control1: pt(8.146, 15.917), control2: pt(8.341, 16.083))
            p.addCurve(to: pt(8.937, 16.988), control1: pt(8.687, 16.48), control2: pt(8.828, 16.716))
            p.addCurve(to: pt(9.1, 17.95), control1: pt(9.045, 17.261), control2: pt(9.1, 17.581))
            p.addCurve(to: pt(8.841, 19.19), control1: pt(9.1, 18.395), control2: pt(9.014, 18.808))
            p.addCurve(to: pt(8.075, 20.178), control1: pt(8.668, 19.571), control2: pt(8.413, 19.9))
            p.addCurve(to: pt(6.82, 20.829), control1: pt(7.737, 20.456), control2: pt(7.319, 20.672))
            p.addCurve(to: pt(5.092, 21.064), control1: pt(6.32, 20.985), control2: pt(5.745, 21.064))
            p.addCurve(to: pt(4.047, 20.97), control1: pt(4.737, 21.064), control2: pt(4.388, 21.033))
            p.addCurve(to: pt(3.079, 20.684), control1: pt(3.706, 20.907), control2: pt(3.384, 20.812))
            p.addCurve(to: pt(2.239, 20.203), control1: pt(2.775, 20.557), control2: pt(2.495, 20.396))
            p.addCurve(to: pt(1.579, 19.523), control1: pt(1.983, 20.009), control2: pt(1.763, 19.783))
            p.addCurve(to: pt(1.149, 18.642), control1: pt(1.395, 19.263), control2: pt(1.251, 18.969))
            p.addCurve(to: pt(1.0, 17.554), control1: pt(1.046, 18.314), control2: pt(0.997, 17.951))
            p.addLine(to: pt(3.046, 17.554))
            p.addLine(to: pt(3.046, 17.554))
            p.closeSubpath()
            p.move(to: pt(8.608, 12.991))
            p.addLine(to: pt(8.608, 11.146))
            p.addLine(to: pt(16.237, 11.146))
            p.addLine(to: pt(16.237, 12.991))
            p.addLine(to: pt(13.443, 12.991))
            p.addLine(to: pt(13.443, 20.826))
            p.addLine(to: pt(11.359, 20.826))
            p.addLine(to: pt(11.359, 12.991))
            p.addLine(to: pt(8.607, 12.991))
            p.addLine(to: pt(8.608, 12.991))
            p.closeSubpath()
            p.move(to: pt(29.221, 11.146))
            p.addCurve(to: pt(30.577, 11.335), control1: pt(29.727, 11.146), control2: pt(30.179, 11.209))
            p.addCurve(to: pt(31.585, 11.875), control1: pt(30.976, 11.461), control2: pt(31.312, 11.641))
            p.addCurve(to: pt(32.211, 12.735), control1: pt(31.859, 12.109), control2: pt(32.068, 12.396))
            p.addCurve(to: pt(32.428, 13.882), control1: pt(32.355, 13.074), control2: pt(32.428, 13.456))
            p.addCurve(to: pt(32.383, 14.573), control1: pt(32.428, 14.125), control2: pt(32.413, 14.354))
            p.addCurve(to: pt(32.227, 15.183), control1: pt(32.352, 14.791), control2: pt(32.3, 14.994))
            p.addCurve(to: pt(31.929, 15.703), control1: pt(32.153, 15.372), control2: pt(32.054, 15.545))
            p.addCurve(to: pt(31.464, 16.124), control1: pt(31.804, 15.861), control2: pt(31.649, 16.002))
            p.addCurve(to: pt(31.814, 16.487), control1: pt(31.607, 16.234), control2: pt(31.725, 16.355))
            p.addCurve(to: pt(32.031, 16.916), control1: pt(31.904, 16.62), control2: pt(31.976, 16.763))
            p.addCurve(to: pt(32.158, 17.4), control1: pt(32.086, 17.07), control2: pt(32.128, 17.231))
            p.addCurve(to: pt(32.233, 17.931), control1: pt(32.189, 17.57), control2: pt(32.214, 17.746))
            p.addCurve(to: pt(32.262, 18.733), control1: pt(32.246, 18.209), control2: pt(32.255, 18.476))
            p.addCurve(to: pt(32.336, 19.476), control1: pt(32.268, 18.989), control2: pt(32.293, 19.238))
            p.addCurve(to: pt(32.55, 20.17), control1: pt(32.379, 19.715), control2: pt(32.451, 19.946))
            p.addCurve(to: pt(33.001, 20.826), control1: pt(32.65, 20.395), control2: pt(32.8, 20.613))
            p.addLine(to: pt(30.778, 20.826))
            p.addCurve(to: pt(30.466, 20.271), control1: pt(30.635, 20.652), control2: pt(30.53, 20.467))
            p.addCurve(to: pt(30.327, 19.656), control1: pt(30.402, 20.076), control2: pt(30.356, 19.871))
            p.addCurve(to: pt(30.264, 18.988), control1: pt(30.297, 19.441), control2: pt(30.277, 19.219))
            p.addCurve(to: pt(30.187, 18.269), control1: pt(30.251, 18.758), control2: pt(30.226, 18.518))
            p.addCurve(to: pt(30.094, 17.8), control1: pt(30.161, 18.112), control2: pt(30.131, 17.954))
            p.addCurve(to: pt(29.926, 17.386), control1: pt(30.057, 17.645), control2: pt(30.001, 17.507))
            p.addCurve(to: pt(29.619, 17.091), control1: pt(29.851, 17.265), control2: pt(29.748, 17.167))
            p.addCurve(to: pt(29.107, 16.977), control1: pt(29.489, 17.015), control2: pt(29.319, 16.977))
            p.addLine(to: pt(26.649, 16.977))
            p.addLine(to: pt(26.649, 20.826))
            p.addLine(to: pt(24.561, 20.826))
            p.addLine(to: pt(24.561, 11.146))
            p.addLine(to: pt(29.223, 11.146))
            p.addLine(to: pt(29.221, 11.146))
            p.closeSubpath()
            p.move(to: pt(28.668, 15.291))
            p.addCurve(to: pt(29.3, 15.228), control1: pt(28.886, 15.291), control2: pt(29.096, 15.27))
            p.addCurve(to: pt(29.842, 15.017), control1: pt(29.503, 15.185), control2: pt(29.684, 15.115))
            p.addCurve(to: pt(30.221, 14.63), control1: pt(30.001, 14.919), control2: pt(30.127, 14.789))
            p.addCurve(to: pt(30.363, 14.041), control1: pt(30.315, 14.47), control2: pt(30.363, 14.274))
            p.addCurve(to: pt(30.289, 13.596), control1: pt(30.363, 13.883), control2: pt(30.339, 13.735))
            p.addCurve(to: pt(30.063, 13.23), control1: pt(30.239, 13.457), control2: pt(30.164, 13.335))
            p.addCurve(to: pt(29.681, 12.983), control1: pt(29.962, 13.126), control2: pt(29.835, 13.043))
            p.addCurve(to: pt(29.143, 12.893), control1: pt(29.527, 12.924), control2: pt(29.349, 12.893))
            p.addLine(to: pt(26.647, 12.893))
            p.addLine(to: pt(26.647, 15.291))
            p.addLine(to: pt(28.668, 15.291))
            p.closeSubpath()
        return p
    }
}

/// ตรา ST★R ขนาดตามความสูง ย้อมสีเดียว วาง baseline ให้เท่ากับตัวอักษรข้าง ๆ (ใช้ใน HStack(alignment: .lastTextBaseline))
struct StarCaps: View {
    let height: CGFloat
    var color: Color = GL.ink

    var body: some View {
        StarCapsShape()
            .fill(color, style: FillStyle(eoFill: true))
            .frame(width: height * StarCapsShape.aspect, height: height)
            .alignmentGuide(.lastTextBaseline) { d in d[.bottom] - height * StarCapsShape.descent }
            .alignmentGuide(.firstTextBaseline) { d in d[.bottom] - height * StarCapsShape.descent }
            .accessibilityLabel("Star")
    }

    /// ความสูงตราที่เข้าคู่กับคำ serif ขนาดนั้น (สัดส่วนจากแคนวาส: caps .74em ต่อ serif 1.16em)
    static func height(forSerif size: CGFloat) -> CGFloat { size * 0.64 }
    /// ความสูงตราเมื่อแทนคำ STAR กลางประโยค (ปุ่ม ป้าย) — โตกว่าตัวอักษรรอบข้างเล็กน้อย
    /// (ผู้ใช้ 30 ก.ย. 2569: "Star มันต้องใหญ่กว่าฟอนต์ปกติ")
    static func height(forText size: CGFloat) -> CGFloat { size * 0.82 }
    /// ความสูงตราเมื่อเป็นคำเน้นในหัวข้อ ("สมัครเป็น STAR") — เท่า cap height ของคำ serif เดิม (serif = 1.33 × ตัวหนา)
    static func height(forEmphasis heavySize: CGFloat) -> CGFloat { heavySize * 0.95 }
    /// ช่องว่างระหว่างตรากับคำ serif
    static func gap(forSerif size: CGFloat) -> CGFloat { size * 0.19 }
}

/// ประโยคที่มีคำ STAR อยู่ข้างใน — คำ STAR ทุกคำถูกแทนด้วยตรา ST★R สูงเท่าตัวอักษร วางบน baseline เดียวกัน
/// (ผู้ใช้ 30 ก.ย. 2569: "คำว่า STAR ตอนนี้ทุก flow ต้องใช้ Star อันที่มีดาวจาก icon") — ไม่มีคำ STAR ก็เป็น Text ธรรมดา
/// ใช้กับข้อความบรรทัดเดียว (ปุ่ม ป้าย หัวย่อย) — ประโยคยาวที่ต้องตัดบรรทัดยังเป็น Text
struct StarText: View {
    let text: String
    var size: CGFloat = 16
    var weight: Font.Weight = .bold
    var color: Color = GL.ink

    init(_ text: String, size: CGFloat = 16, weight: Font.Weight = .bold, color: Color = GL.ink) {
        self.text = text; self.size = size; self.weight = weight; self.color = color
    }

    var body: some View {
        let parts = text.components(separatedBy: "STAR").map { $0.trimmingCharacters(in: .whitespaces) }
        HStack(alignment: .lastTextBaseline, spacing: size * 0.26) {
            ForEach(Array(parts.enumerated()), id: \.offset) { i, part in
                if i > 0 { StarCaps(height: StarCaps.height(forText: size), color: color) }
                if !part.isEmpty { Text(part).font(.sh(size, weight)).foregroundStyle(color) }
            }
        }
        .lineLimit(1)
    }
}

/// หัวข้อ "ST★R + คำ serif" สำเร็จรูป — ใช้ที่ที่ไม่ต้องไขว้จางสองคำ
struct StarWordmark: View {
    let word: String
    var serifSize: CGFloat = 54
    var onDark = false

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: StarCaps.gap(forSerif: serifSize)) {
            StarCaps(height: StarCaps.height(forSerif: serifSize), color: onDark ? .white : GL.ink)
                .shadow(color: onDark ? .black.opacity(0.35) : GL.ink.opacity(0.14), radius: 15, y: 14)
            Text(word).font(GL.serif(serifSize))
                .foregroundStyle(GL.serifInk(onDark: onDark))
                .shadow(color: onDark ? .black.opacity(0.3) : GL.ink.opacity(0.12), radius: 9, y: 12)
        }
        .lineLimit(1).minimumScaleFactor(0.7)
    }
}

extension GL {
    /// สีคำ serif ของหัวข้อ: หมึก→ทองบนพื้นสว่าง · ขาว→ทองอ่อนบนการ์ดมืด
    static func serifInk(onDark: Bool) -> LinearGradient {
        LinearGradient(colors: onDark ? [.white, .white, Color(red: 232 / 255, green: 199 / 255, blue: 102 / 255)]
                                      : [GL.ink, GL.ink, GL.goldInk],
                       startPoint: .top, endPoint: .bottom)
    }
}
