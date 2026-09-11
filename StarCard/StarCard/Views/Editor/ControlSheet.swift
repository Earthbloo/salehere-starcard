import SwiftUI

/// ระดับความสูงของชีตควบคุม
enum SheetStop {
    /// ย่อเหลือแถบ — เห็นการ์ดเต็ม ๆ แต่ยังอยู่ในโหมดแต่ง
    static var compact: PresentationDetent { .height(84) }
    /// ระดับปกติ — เห็นแถวควบคุมครบ
    /// สูงขึ้นจาก 268 เพราะทุกเรื่องมีหัวข้อจัดกลางของตัวเองเพิ่มมาอีกบรรทัด
    static var normal: PresentationDetent { .height(340) }
    /// ระดับที่ตัวเลือกสีกางออกแล้วยังอยู่ในชีตได้ทั้งก้อน — **ต้องไม่ให้เนื้อหาล้นจนต้องเลื่อน**
    ///
    /// พอเนื้อหาใน `ScrollView` ของชีตล้นกรอบ พื้นที่รับทัชกับที่วาดจริงเลื่อนออกจากกันราว 50pt
    /// (แตะตรงแถบความสว่างแล้วได้ช่องรหัสสีที่อยู่ต่ำลงไปอีกแถว) ซึ่งทำให้แผงกดไม่ตรงทั้งแผง
    /// ยกชีตขึ้นมาให้พอดีของทั้งก้อนแทนที่จะปล่อยให้เลื่อน — และตรงกับที่ควรเป็นอยู่แล้ว
    /// คือเปิดตัวเลือกสีมาต้องเห็นครบในทีเดียว ไม่ต้องเลื่อนหาแถบที่จะลาก
    static var tall: PresentationDetent { .height(560) }
}

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
                .padding(kind.isFullBleed || kind.isPlain ? 0 : 12)
                .frame(width: vw, height: vh, alignment: .topLeading)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: width, height: width * ratio, alignment: .topLeading)
        }
        .frame(width: width, height: width * ratio)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .allowsHitTesting(false)
    }
}
