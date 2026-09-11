import SwiftUI
import UIKit

/// ตัวรับ "กดค้างแล้วลาก" ที่เขียนด้วย UIKit
///
/// ทำไมไม่ใช้ gesture ของ SwiftUI:
/// - `LongPressGesture().sequenced(before: DragGesture())` ใน `ScrollView` ถูก pan ของ
///   ScrollView แย่งไปตั้งแต่ต้น long press เลยไม่เคยสำเร็จกับ input จริง
/// - `.simultaneousGesture(DragGesture(minimumDistance: 0))` แก้ข้อแรกได้ แต่ไปบล็อก
///   การเลื่อนหน้าจอทั้งหน้า เพราะมันคว้า touch ทุกครั้งที่นิ้วแตะ
///
/// `UILongPressGestureRecognizer` ไม่มีปัญหาทั้งสองข้อ — มันเป็น recognizer แบบต่อเนื่อง
/// ที่ยิง `.began` เมื่อครบเวลา แล้วยิง `.changed` ต่อระหว่างลาก และก่อนครบเวลามันไม่ขวาง
/// pan ของ scroll view เลย ผู้ใช้จึงยังปัดเลื่อนหน้าจอได้ตามปกติ
struct PressDragCatcher: UIViewRepresentable {
    var minimumDuration: Double = 0.25
    /// ระยะที่นิ้วขยับได้ก่อนครบเวลาโดยยังไม่ยกเลิก — ค่าเริ่มต้นของ UIKit คือ 10pt ซึ่งแคบไปสำหรับนิ้วจริง
    var allowableMovement: CGFloat = 32
    var onBegan: () -> Void
    var onChanged: (CGSize) -> Void
    var onEnded: () -> Void
    /// แตะสั้น ๆ พร้อมจุดที่แตะ (พิกัดภายใน widget) — ชั้นการ์ดใช้ตัดสินว่านิ้วโดนช่องข้อความหรือโดนตัว widget
    var onTap: (CGPoint) -> Void
    /// จุดที่นิ้วแตะ (พิกัดภายใน widget) · nil เมื่อยกนิ้ว — ใช้คำนวณการเอียง 3 มิติ
    var onPress: (CGPoint?) -> Void = { _ in }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let press = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePress(_:))
        )
        press.minimumPressDuration = minimumDuration
        press.allowableMovement = allowableMovement
        press.delegate = context.coordinator
        view.addGestureRecognizer(press)

        // ตัวจับ "กำลังแตะ" แยกต่างหาก · duration 0 จึงยิงทันทีที่นิ้วลง
        // และไม่ขวาง recognizer ตัวอื่นเพราะ delegate ยอมให้ทำงานพร้อมกัน
        let touch = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTouch(_:))
        )
        touch.minimumPressDuration = 0
        touch.delegate = context.coordinator
        view.addGestureRecognizer(touch)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.delegate = context.coordinator
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: PressDragCatcher
        private var origin: CGPoint = .zero

        init(_ parent: PressDragCatcher) { self.parent = parent }

        @objc func handlePress(_ g: UILongPressGestureRecognizer) {
            guard let view = g.view else { return }
            // อ้างอิงพิกัดหน้าต่าง เพราะ view ใต้เท้าเลื่อนได้ระหว่างลาก (auto-scroll)
            let space = view.window ?? view
            switch g.state {
            case .began:
                origin = g.location(in: space)
                parent.onBegan()
            case .changed:
                let now = g.location(in: space)
                parent.onChanged(CGSize(width: now.x - origin.x, height: now.y - origin.y))
            case .ended, .cancelled, .failed:
                parent.onEnded()
            default:
                break
            }
        }

        @objc func handleTouch(_ g: UILongPressGestureRecognizer) {
            guard let view = g.view else { return }
            switch g.state {
            case .began, .changed:
                parent.onPress(g.location(in: view))
            default:
                parent.onPress(nil)
            }
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let view = g.view else { return }
            parent.onTap(g.location(in: view))
        }

        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
