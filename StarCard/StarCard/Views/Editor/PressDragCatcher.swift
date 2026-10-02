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
    /// **ลากได้ทันที ไม่ต้องกดค้าง** — ใช้กับชิ้นที่เลือกอยู่แล้ว
    ///
    /// ผู้ใช้เพิ่งแตะมันเมื่อกี้ จึงชัดอยู่แล้วว่านิ้วที่ลากบนชิ้นนี้ตั้งใจจะย้ายมัน ไม่ใช่จะปัดหน้า
    /// (ชิ้นที่ยังไม่ได้เลือกยังต้องกดค้าง — ไม่งั้นปัดเปลี่ยนช่องบนการ์ดที่มีของเต็มไม่ได้เลย)
    /// สลับได้ระหว่างที่ view ยังอยู่: กดค้างถูกปิด แพนถูกเปิด ทั้งคู่ไม่ทำงานพร้อมกัน
    var immediate = false
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

        // แพน — เริ่มทันทีที่นิ้วขยับพ้นเกณฑ์ (~10pt) ไม่ต้องรอ · แตะเฉย ๆ ยังเป็นแตะเพราะแพนไม่ติด
        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.maximumNumberOfTouches = 1
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)

        context.coordinator.press = press
        context.coordinator.pan = pan
        context.coordinator.applyMode()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.applyMode()
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: PressDragCatcher
        private var origin: CGPoint = .zero
        /// นิ้วนี้เคยเริ่มลากแล้ว — ปล่อยนิ้วต้องไม่นับเป็นแตะ
        ///
        /// แตะของ UIKit ยอมให้นิ้วขยับได้ราว 45pt และค้างได้นานกว่าเกณฑ์กดค้าง (0.25 วิ) —
        /// ลากสลับที่ระยะสั้น ๆ จึงยิงทั้ง `onEnded` **และ** `onTap` ตอนยกนิ้ว แล้วแตะก็ไปเลือกชิ้น
        /// ถาดของชิ้นเลยเด้งขึ้นทุกครั้งที่วาง · ล้างค่าตอนนิ้วลงครั้งใหม่ (ดู `handleTouch`)
        private var dragged = false
        weak var press: UILongPressGestureRecognizer?
        weak var pan: UIPanGestureRecognizer?

        init(_ parent: PressDragCatcher) { self.parent = parent }

        /// ชิ้นที่เลือกอยู่ลากด้วยแพน ชิ้นอื่นลากด้วยกดค้าง — เปิดทีละตัว ไม่งั้นสองตัวขับการลากซ้อนกัน
        func applyMode() {
            press?.isEnabled = !parent.immediate
            pan?.isEnabled = parent.immediate
        }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            guard let view = g.view else { return }
            let space = view.window ?? view
            switch g.state {
            case .began:
                // เริ่มนับระยะจากจุดที่แพนติด ไม่ใช่จุดที่นิ้วแตะ — ชิ้นจะได้ยกขึ้นตรงที่ ไม่กระโดด 10pt
                g.setTranslation(.zero, in: space)
                dragged = true
                parent.onBegan()
            case .changed:
                let t = g.translation(in: space)
                parent.onChanged(CGSize(width: t.x, height: t.y))
            case .ended, .cancelled, .failed:
                parent.onEnded()
            default:
                break
            }
        }

        @objc func handlePress(_ g: UILongPressGestureRecognizer) {
            guard let view = g.view else { return }
            // อ้างอิงพิกัดหน้าต่าง เพราะ view ใต้เท้าเลื่อนได้ระหว่างลาก (auto-scroll)
            let space = view.window ?? view
            switch g.state {
            case .began:
                origin = g.location(in: space)
                dragged = true
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
            case .began:
                dragged = false
                parent.onPress(g.location(in: view))
            case .changed:
                parent.onPress(g.location(in: view))
            default:
                parent.onPress(nil)
            }
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let view = g.view, !dragged else { return }
            parent.onTap(g.location(in: view))
        }

        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
