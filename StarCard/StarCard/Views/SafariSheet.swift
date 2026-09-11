import SafariServices
import SwiftUI

/// เบราว์เซอร์ในแอป — ลิงก์บนการ์ดเปิดที่นี่ ไม่เด้งออกไปแอปอื่น
///
/// # ทำไมไม่ใช้ `openURL`
///
/// การ์ดใบนี้ถูกเปิดมาจากคลิปหรือลิงก์แชร์ ผู้ใช้ที่กำลังดูอยู่ยังไม่ได้ตัดสินใจอะไรเลย
/// ถ้ากดโปรไฟล์แล้วเด้งออกไป Safari/IG เท่ากับ **จบเซสชันการดูการ์ด** — เขาต้องหาทางกลับเอง
/// ซึ่งไม่มีทางกลับให้ด้วยซ้ำเมื่อมาจากลิงก์
///
/// `SFSafariViewController` อยู่ในแอป กด "เสร็จ" แล้วกลับมาที่หน้าเดิมทันทีในสภาพเดิมเป๊ะ
/// และยังได้ของครบทุกอย่างของ Safari (แถบที่อยู่จริงที่ปลอมไม่ได้ · Reader · แชร์ · คุกกี้ที่ล็อกอินไว้แล้ว)
/// โดยตัวแอปมองไม่เห็นอะไรในนั้นเลย — ผู้ใช้จึงเชื่อได้ว่าลิงก์พาไปที่ที่มันบอกจริง
struct SafariSheet: UIViewControllerRepresentable {
    let url: URL
    /// สีของปุ่มในแถบเครื่องมือ — ใช้สีเน้นของธีมการ์ด เบราว์เซอร์จะได้ยังรู้สึกเป็นของแอปนี้
    let tint: Color

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let cfg = SFSafariViewController.Configuration()
        // แถบยุบตอนเลื่อน — หน้าโปรไฟล์กับหน้ารีวิวเป็นหน้ายาว ให้เนื้อหาได้ที่เต็ม
        cfg.barCollapsingEnabled = true
        let vc = SFSafariViewController(url: url, configuration: cfg)
        vc.preferredControlTintColor = UIColor(tint)
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}

/// URL ที่ห่อให้ `sheet(item:)` ใช้ได้ — `URL` เองไม่ใช่ `Identifiable`
///
/// ใช้ `item:` ไม่ใช่ `isPresented:` เพราะปลายทางเปลี่ยนทุกครั้งที่กดคนละที่
/// ถ้าใช้บูลคู่กับตัวแปร URL แยก จะมีจังหวะที่ชีตขึ้นมาก่อน URL ใหม่ถูกเซ็ต แล้วเปิดหน้าเก่า
struct LinkTarget: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
