import SwiftUI

struct ContentView: View {
    @State private var photos = PhotoStore()
    @State private var invocation = ClipInvocation()

    /// การ์ดที่กำลังแต่งอยู่ — nil = ยังอยู่ชั้นเลือก (คลัง/เทมเพลต)
    @State private var editingCardID: String?
    /// ใบที่กำลังแต่งเพิ่งเกิดจากการแตะเทมเพลต — ออกโดยไม่แตะแก้อะไร = ทิ้งใบนั้น
    @State private var freshFromTemplate = false
    /// เปิดหน้าเทมเพลตทับคลัง — จากปุ่ม + (คลังว่างไม่ต้องพึ่งสวิตช์นี้ ไปหน้าเทมเพลตเองอยู่แล้ว)
    @State private var showPicker = false
    /// แบบล่าสุดที่เลือกในหน้าเทมเพลต — จำไว้ให้สวิตช์เปิดค้างแบบเดิมรอบหน้า
    @State private var lastFormat: CardFormat = .portfolio

    var body: some View {
        Group {
            if AppRuntime.isClip {
                // คลิปเปิดการ์ดของคนอื่นจากลิงก์ — ไม่ผ่านคลังหรือหน้าเทมเพลตของเจ้าของเครื่อง
                CardScreen(viewOnly: true)
            } else if let cardID = editingCardID {
                // `id` ผูกกับใบ — เปิดคนละใบต้องได้ `CardScreen` ใหม่จริง ๆ
                // ไม่งั้น `@State pages` ของใบเดิมค้างอยู่ (ค่าตั้งต้นของ State ใช้แค่ตอนสร้างครั้งแรก)
                CardScreen(cardID: cardID, discardIfUntouched: freshFromTemplate) {
                    withAnimation(Motion.settle) {
                        editingCardID = nil
                        showPicker = false
                    }
                }
                .id(cardID)
                .transition(.opacity)
            } else if showPicker || CardLibrary.shared.isEmpty {
                // คลังว่าง = ยังไม่มีอะไรให้ดู พาไปเริ่มจากเทมเพลตเลย (หน้านี้คือหน้าแรกของมือใหม่)
                TemplatePicker(
                    initialFormat: lastFormat,
                    onPick: { pickedFormat, picked in
                        lastFormat = pickedFormat
                        let record = CardLibrary.shared.create(from: picked)
                        freshFromTemplate = true
                        withAnimation(Motion.settle) { editingCardID = record.id }
                    },
                    onBack: CardLibrary.shared.isEmpty ? nil : {
                        withAnimation(Motion.settle) { showPicker = false }
                    }
                )
                .transition(.opacity)
            } else {
                CardGallery(
                    onCreate: { withAnimation(Motion.settle) { showPicker = true } },
                    onOpen: { record in
                        freshFromTemplate = false
                        withAnimation(Motion.settle) { editingCardID = record.id }
                    }
                )
                .transition(.opacity)
            }
        }
        .environment(photos)
        .environment(invocation)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            invocation.consume(activity)
        }
        .onOpenURL { url in
            invocation.consume(url)
        }
        .task {
            invocation.consumeLaunchURL()
        }
    }
}

#Preview {
    ContentView()
}
