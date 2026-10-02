import SwiftUI

/// พรีวิวย่อของ widget หนึ่งแบบ
///
/// เรนเดอร์ที่ขนาดใช้งานจริงแล้วค่อยย่อทั้งก้อน — ถ้าเรนเดอร์เล็กตั้งแต่แรก
/// ข้อความจะโดนตัดจนดูไม่ออกว่า widget ทำอะไร
struct WidgetThumb: View {
    let kind: WidgetKind
    let theme: CardTheme
    var width: CGFloat = 104
    var ratio: CGFloat = 0.66

    var body: some View {
        let vw: CGFloat = 300
        let vh = vw * ratio
        let scale = width / vw
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.05))
            WidgetBody(kind: kind, theme: theme, size: CGSize(width: vw, height: vh))
                // ตระกูลที่ยังไม่มีข้อมูล = รูปย่อวาดด้วยชุดตัวอย่าง ไม่ใช่ป้ายรอข้อมูลที่หน้าตาเหมือนกันทุกแบบ
                .environment(\.sampleData, Profile.me.lacks(kind.family))
                // กติกาเดียวกับบนการ์ด: เว้นขอบในได้เฉพาะใบที่มีแผ่นของ chrome รองอยู่
                // (ดู `WidgetChrome`) — พรีวิวที่เว้นไม่เท่าของจริงคือพรีวิวที่โกหก
                .padding(kind.isFullBleed || kind.drawsOwnSurface
                         || kind.defaultSurface == .clear ? 0 : 12)
                .frame(width: vw, height: vh, alignment: .topLeading)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: width, height: width * ratio, alignment: .topLeading)
        }
        .frame(width: width, height: width * ratio)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .allowsHitTesting(false)
    }
}
