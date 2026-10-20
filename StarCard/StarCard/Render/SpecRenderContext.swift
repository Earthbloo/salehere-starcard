import UIKit

// MARK: - สิ่งที่ตัววาด UIKit ต้องขอจากแอป (= สัญญาของ "แพลตฟอร์ม" — WIDGET-SPEC.md §6)
//
// ตัววาด (`SpecLayerPainter`) รู้จักแค่กล่องจาก `SpecSolver` กับ primitive ไม่กี่อย่าง
// ทุกอย่างที่ขึ้นกับแอปจริง — สีของธีม · ฟอนต์ไฟล์ · รูปของช่อง · asset · ไอคอนที่วาดด้วยโค้ด — ผ่าน protocol นี้
// แอปต้นแบบมี `AppRenderContext` (SwiftUI theme → UIColor) · salehere-ios เขียน adapter ของตัวเองจาก model จริง
//
// ไฟล์ในโฟลเดอร์ `Render/` ใช้เฉพาะ UIKit · CoreAnimation · CoreText · CoreImage ที่มีตั้งแต่ iOS 16
// (พิสูจน์ด้วย `Packages/StarCardRender` ซึ่งคอมไพล์ไฟล์ชุดเดียวกันที่ deployment target 16.0)

/// รูปของช่องหนึ่ง + การจัดวางที่ผู้ใช้ตั้ง (`PhotoFit`): dx/dy = สัดส่วนของขนาดที่วาด · zoom = ขยายรอบกลาง
struct SpecRenderPhoto {
    var image: UIImage
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    var zoom: CGFloat = 1
}

/// คำขอไอคอนหนึ่งชิ้น — ชื่อหลังแทน `$field` แล้ว · กล่องที่ให้ · สีย้อม (nil = ค่าตั้งต้นของไอคอนนั้น)
struct SpecIconRequest {
    var name: String
    var size: CGSize
    var tint: UIColor?
    /// `text` ของโหนด (ใช้กับ `ringText`)
    var text: String?
    /// `size` ของโหนด (ขนาดตัวอักษรของ `ringText`)
    var pointSize: CGFloat?
    /// พิกเซลต่อหน่วยออกแบบที่ไอคอนนี้จะถูกวาดจริง (สเกลจอ × ขั้นย่อ × สเกล chrome) — ให้ adapter ที่ rasterize รู้ความละเอียด
    var pixelScale: CGFloat
}

/// ลายบนแผ่นทึบที่ผู้ใช้เลือกรายชิ้น (= `PlatePattern`)
enum SpecPlatePattern: String { case plain, stripe, diamond }

protocol SpecRenderContext: AnyObject {
    /// token → สี · 6 บทบาท (`bg bg2 ink ink2 accent line`) คิดจากพื้น `on` ของโหนด (nil = `widget.on`) และ `$field` ของรายการ (`$tint@0.3`)
    func color(_ token: String, on: String?, item: SpecItem?) -> UIColor
    /// ฟอนต์ตัวเดียวกับที่ตัววัดใช้ (face token → ไฟล์ฟอนต์ · น้ำหนัก · เอียง)
    func font(_ f: SpecFont) -> UIFont
    /// ความสูงบรรทัดของฟอนต์นี้ (ตัววัดคนเดียวกัน — ใช้คิด `lineHeight` ของผัง)
    func lineHeight(_ f: SpecFont) -> CGFloat
    /// รูปของช่อง `slot` ของชิ้นนี้ · nil = ยังไม่มีรูป (ไม่วาดอะไร)
    func photo(slot: Int) -> SpecRenderPhoto?
    /// รูปจาก asset ของแอป (`src` ที่ไม่ใช่ URL)
    func asset(_ name: String) -> UIImage?
    /// รูปจากเน็ตที่โหลดไว้แล้ว (`src`/`icon` ที่ขึ้นต้น http) · nil = ยังไม่มา (ไม่วาดอะไร)
    func remote(_ url: String) -> UIImage?
    /// ไอคอนตามชื่อ (§6) เป็น view ขนาด `size` · nil = ไม่รู้จัก
    func icon(_ request: SpecIconRequest) -> UIView?
    var platePattern: SpecPlatePattern { get }
}

extension SpecRenderContext {
    func color(_ token: String, on: String? = nil) -> UIColor { color(token, on: on, item: nil) }
}
