// ชิ้นส่วนกลางที่ตัววาดผัง (SpecPainter) และหน้าจออื่นเรียกใช้ — ไม่ผูกกับ widget ตัวใด
import SwiftUI


/// QR ของจริงจาก CoreImage — เรนเดอร์ครั้งเดียวแล้วแคชไว้ตามข้อความ
///
/// ใช้ `interpolation(.none)` เพราะ QR ที่ถูก smooth ตอนขยาย จะสแกนยากขึ้นจริง
/// ไม่ใช่แค่ดูฟุ้ง — ตัวอ่านต้องการขอบคมเพื่อแยกโมดูล
struct QRCode: View {
    let text: String
    var tint: Color = .black

    @State private var image: UIImage?

    init(text: String, tint: Color = .black) {
        self.text = text
        self.tint = tint
        // สร้างตั้งแต่เกิด ไม่รอ .task — CIFilter เร็วระดับมิลลิวินาทีและมีแคชกันซ้ำ
        // จำเป็นกับตอนอบรูปเทมเพลตด้วย: ImageRenderer เรนเดอร์เฟรมเดียวจบ ไม่รัน .task
        // ถ้ารอ task ตัว QR จะอบออกมาเป็นแผ่นขาวเปล่าติดถาวร
        _image = State(initialValue: QRCode.render(text))
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
    }

    private static var cache: [String: UIImage] = [:]

    private static func render(_ text: String) -> UIImage? {
        if let hit = cache[text] { return hit }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let out = filter.outputImage else { return nil }
        let scaled = out.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        let ctx = CIContext()
        guard let cg = ctx.createCGImage(scaled, from: scaled.extent) else { return nil }
        // ห้ามใส่ .alwaysTemplate — ภาพจาก CIQRCodeGenerator ทึบทั้งใบ (ทั้งโมดูลดำและพื้นขาว)
        // ย้อมเป็นสีเดียวเมื่อไหร่ QR กลายเป็นบล็อกทึบที่สแกนไม่ได้ทันที
        let ui = UIImage(cgImage: cg)
        cache[text] = ui
        return ui
    }
}
