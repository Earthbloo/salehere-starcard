import UIKit
import Vision
import CoreImage

/// ลบพื้นหลังออกจากรูปหนึ่งใบ — ยกเฉพาะ "ตัวแบบ" ขึ้นมา ที่เหลือกลายเป็นใส
///
/// # ทำไมต้องคืนภาพ **ขนาดเท่าเดิม** ไม่ใช่ครอปรอบตัวแบบ
///
/// ทุกช่องรูปในตู้วาดด้วย `.aspectRatio(contentMode: .fill)` แล้วครอปตามกรอบของช่อง
/// (ดู `PhotoTile` · `EdPhoto` · สำรับกองรูปทั้งหมด) ถ้าคืนภาพที่ถูกครอปมาชิดตัวแบบ
/// สัดส่วนของภาพจะเปลี่ยนไปคนละเรื่อง แล้ว **ทุกช่องที่เคยเล็งไว้ก็เลื่อนหมดในวินาทีที่กดปุ่ม**
/// รวมถึงค่าเลื่อน/ซูมที่ผู้ใช้จัดไว้เอง (`PhotoFit` เก็บเป็นสัดส่วนของภาพที่เรนเดอร์จริง)
///
/// คืนภาพขนาดเดิมที่พื้นหลังใสแทน — การกดปุ่มจึงเปลี่ยน *แค่พื้นหลัง* อย่างเดียว
/// ตัวแบบยังอยู่ตำแหน่งเดิมเป๊ะ และไม่มีช่องไหนในการ์ดขยับสักช่อง
///
/// # ทำไมไม่ใช้ `VNGenerateAttentionBasedSaliencyImageRequest`
///
/// ตัวนั้นให้ *แผนที่ความน่าสนใจ* ซึ่งเป็นหย่อมเบลอ ๆ ไม่ใช่ขอบของวัตถุ — เอามาทำหน้ากาก
/// แล้วได้ขอบฟุ้งรอบตัวคน ซึ่งบนพื้นสีอ่อนของสำรับบรรณาธิการเห็นเป็นรัศมีสกปรกทันที
/// `VNGenerateForegroundInstanceMaskRequest` (iOS 17+) ให้หน้ากากระดับพิกเซลของวัตถุจริง
/// ตัวเดียวกับที่ระบบใช้ตอน "แตะค้างที่ตัวคน" ในแอปรูป
enum PhotoLift {

    /// ยกตัวแบบออกจากพื้นหลัง — `nil` เมื่อในรูปไม่มีวัตถุที่แยกออกมาได้
    ///
    /// ทำงานนอกเธรดหลัก: หน้ากากของรูป 12MP ใช้เวลาเป็นวินาที ถ้าอยู่บนเธรดหลัก
    /// การ์ดจะค้างทั้งใบระหว่างนั้น แล้วผู้ใช้จะกดปุ่มซ้ำเพราะคิดว่าไม่ติด
    static func lift(_ image: UIImage) async -> UIImage? {
        let source = upright(image)
        guard let cg = source.cgImage else { return nil }
        let scale = source.scale
        return await Task.detached(priority: .userInitiated) { () -> UIImage? in
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)
            do {
                try handler.perform([request])
            } catch {
                return nil
            }
            guard let result = request.results?.first, !result.allInstances.isEmpty else {
                return nil
            }
            guard let buffer = try? result.generateMaskedImage(
                ofInstances: result.allInstances, from: handler,
                // false = คงกรอบเดิมของภาพไว้ (ดูเหตุผลที่หัวไฟล์)
                croppedToInstancesExtent: false)
            else { return nil }

            let ci = CIImage(cvPixelBuffer: buffer)
            guard let out = CIContext().createCGImage(ci, from: ci.extent) else { return nil }
            return UIImage(cgImage: out, scale: scale, orientation: .up)
        }.value
    }

    /// วาดภาพใหม่ให้ตั้งตรงก่อนส่งเข้า Vision
    ///
    /// `cgImage` ไม่รู้จัก `imageOrientation` — รูปแนวตั้งจากกล้องเก็บพิกเซลเป็นแนวนอน
    /// ส่งดิบ ๆ เข้าไปแล้วหน้ากากจะออกมาตะแคง ซึ่งอ่านเป็น "ลบพื้นหลังแล้วรูปเพี้ยน"
    private static func upright(_ ui: UIImage) -> UIImage {
        guard ui.imageOrientation != .up else { return ui }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = ui.scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: ui.size, format: format).image { _ in
            ui.draw(in: CGRect(origin: .zero, size: ui.size))
        }
    }
}
