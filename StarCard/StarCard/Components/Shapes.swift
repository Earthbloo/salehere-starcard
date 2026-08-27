import SwiftUI

// MARK: - รูปทรงที่ไม่ใช่สี่เหลี่ยม

/// ทรงซุ้มโค้ง — ครึ่งวงกลมด้านบน ตัดตรงด้านล่าง
/// ภาษาของนิตยสารแฟชั่นและงานพอร์ตโฟลิโอ ใช้กับรูปแล้วเปลี่ยนอารมณ์ทันทีจาก "ข้อมูล" เป็น "งาน"
struct ArchShape: Shape {
    var footRadius: CGFloat = 10

    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        let arc = min(w / 2, h * 0.62)
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY - footRadius))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + arc))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + arc),
                 radius: arc, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - footRadius))
        p.addQuadCurve(to: CGPoint(x: r.maxX - footRadius, y: r.maxY),
                       control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + footRadius, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - footRadius),
                       control: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// ทรงตั๋ว — บากครึ่งวงกลมสองข้าง ใช้กับการ์ดราคาแล้วอ่านออกทันทีว่า "นี่คือของที่ซื้อได้"
struct TicketShape: Shape {
    var notchAt: CGFloat = 0.62
    var notchRadius: CGFloat = 11
    var corner: CGFloat = 18

    func path(in r: CGRect) -> Path {
        let y = r.minY + r.height * notchAt
        var p = Path()
        p.addRoundedRect(in: r, cornerSize: CGSize(width: corner, height: corner), style: .continuous)
        var cut = Path()
        cut.addEllipse(in: CGRect(x: r.minX - notchRadius, y: y - notchRadius,
                                  width: notchRadius * 2, height: notchRadius * 2))
        cut.addEllipse(in: CGRect(x: r.maxX - notchRadius, y: y - notchRadius,
                                  width: notchRadius * 2, height: notchRadius * 2))
        return p.subtracting(cut)
    }
}

/// ทรงหยดน้ำ — ขอบมนไม่เท่ากันสี่มุม ให้ความรู้สึกออร์แกนิกแทนที่จะเป็นกล่อง
struct BlobShape: Shape {
    var seed: Int = 0

    func path(in r: CGRect) -> Path {
        let radii: [CGFloat] = [
            [0.46, 0.18, 0.42, 0.20][seed % 4],
            [0.20, 0.44, 0.18, 0.46][seed % 4],
            [0.44, 0.20, 0.46, 0.18][seed % 4],
            [0.18, 0.46, 0.20, 0.44][seed % 4],
        ]
        let m = min(r.width, r.height)
        var p = Path()
        p.move(to: CGPoint(x: r.minX + m * radii[0], y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - m * radii[1], y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + m * radii[1]),
                       control: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - m * radii[2]))
        p.addQuadCurve(to: CGPoint(x: r.maxX - m * radii[2], y: r.maxY),
                       control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + m * radii[3], y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - m * radii[3]),
                       control: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + m * radii[0]))
        p.addQuadCurve(to: CGPoint(x: r.minX + m * radii[0], y: r.minY),
                       control: CGPoint(x: r.minX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// รูสเปอร์เก็ตของฟิล์ม
struct SprocketRow: View {
    var count: Int = 12
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1.6, style: .continuous)
                        .fill(.black.opacity(0.55))
                        .frame(width: 7, height: 5)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// เทปกาวสำหรับรูปแบบโพลารอยด์
struct TapeStrip: View {
    var tint: Color = .white
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(colors: [tint.opacity(0.42), tint.opacity(0.26)],
                               startPoint: .top, endPoint: .bottom)
            )
            .overlay(Rectangle().strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
            .frame(width: 62, height: 20)
            .rotationEffect(.degrees(-7))
            .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
    }
}
