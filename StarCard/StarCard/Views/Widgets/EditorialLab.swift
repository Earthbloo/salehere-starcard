import SwiftUI

/// โต๊ะตรวจงานชั่วคราวของสำรับบรรณาธิการ — **ไม่ใช่ส่วนหนึ่งของแอป**
/// เปิดด้วย `EditorialLab.on` ใน `ContentView` เพื่อดูทั้งแปดใบที่ขนาดจริงในรอบเดียว
struct EditorialLab: View {
    static let on = false

    @State private var photos = PhotoStore()

    private let kinds: [WidgetKind] = [
        .wallPolaroid, .zineCover, .aboutEditorial,
        .wallMemory, .flowCards, .aboutBehind,
    ]

    var body: some View {
        let theme = CardTheme()
        ScrollView {
            VStack(spacing: 18) {
                ForEach(kinds) { k in
                    VStack(spacing: 4) {
                        Text(k.title).font(.sh(11, .bold)).foregroundStyle(.white)
                        WidgetBody(kind: k, theme: theme, size: k.defaultSize)
                            .frame(width: k.defaultSize.width, height: k.defaultSize.height)
                            .clipped()
                    }
                }
            }
            .padding(.vertical, 40)
        }
        .background(Color.black)
        .environment(photos)
        .environment(\.cardInk, theme.inkStyle)
        .ignoresSafeArea()
    }
}
