import UIKit

/// ลบพื้นหลังให้ **อัตโนมัติ** — ตัวกลางระหว่างรูปทึบที่ผู้ใช้เลือกกับ widget ตระกูลคัตเอาต์
///
/// # ทำไมผูกกับ *ตัวรูป* ไม่ใช่กับ "widget ไหน ช่องไหน"
///
/// ช่องคนของโปสเตอร์ไม่ได้มีแต่รูปที่วางเฉพาะชิ้น — ช่อง 1 ตกไปใช้ **รูปโปรไฟล์** ด้วย
/// (ดู `PhotoStore.userImage`) รูปใบเดียวจึงโผล่ในสามโปสเตอร์พร้อมกันได้ ถ้าผูกกับช่อง
/// Vision จะวิ่งซ้ำสามรอบกับรูปเดิม และพอเปลี่ยนรูปโปรไฟล์ ผลเก่าก็ค้างอยู่ในช่องที่ไม่รู้ตัว
/// ผูกกับรูปแล้วเปลี่ยนรูปเมื่อไหร่ก็ได้ผลใหม่เองโดยไม่ต้องมีใครสั่งล้าง
///
/// # ทำไมต้องเก็บลงดิสก์
///
/// หน้ากากของรูป 12MP ใช้เวลาเป็นวินาที — ถ้าคิดใหม่ทุกครั้งที่เปิดแอป การ์ดจะโชว์รูปในกรอบก่อน
/// แล้วค่อยกระโดดเป็นคนยืนบนการ์ด ทุกครั้ง · กุญแจบนดิสก์คือลายนิ้วมือจากภาพย่อ (ดู `fingerprint`)
/// เพราะ `UIImage` ที่อ่านจากไฟล์ใหม่ทุกรอบไม่มีตัวตนเดิมติดมา
@MainActor
@Observable
final class SubjectLift {
    static let shared = SubjectLift()

    private final class Entry {
        /// ถือรูปต้นทางไว้ — กุญแจคือที่อยู่ของมัน ถ้าปล่อยให้หลุด ที่อยู่เดิมอาจถูกรูปอื่นใช้ซ้ำ
        let source: UIImage
        var result: Cutout.Result?
        var running = true
        var task: Task<Void, Never>?
        init(_ source: UIImage) { self.source = source }
    }

    private var entries: [ObjectIdentifier: Entry] = [:]
    /// ตัวนับที่ widget อ่านไว้ — `Entry` เป็นคลาสธรรมดา การแก้ข้างในไม่ปลุกใคร
    private var revision = 0

    /// ผลของรูปนี้ — `nil` = ยังไม่เคยเริ่ม · `.framed` = ในรูปไม่มีตัวแบบให้ยก
    func result(for ui: UIImage) -> Cutout.Result? {
        _ = revision
        return entries[ObjectIdentifier(ui)]?.result
    }

    func isRunning(_ ui: UIImage) -> Bool {
        _ = revision
        return entries[ObjectIdentifier(ui)]?.running ?? false
    }

    /// เริ่มยกตัวแบบ — เรียกจาก `body` ได้ เพราะตัวแก้สถานะจริงถูกเลื่อนไปรอบถัดไป
    /// (แก้ `@Observable` กลาง `body` = วาดใหม่ระหว่างวาด)
    func request(_ ui: UIImage) {
        guard entries[ObjectIdentifier(ui)] == nil else { return }
        Task { @MainActor in self.start(ui) }
    }

    /// รอจนรูปนี้ลบพื้นหลังเสร็จ — สำหรับคนที่ต้องได้ผลก่อนวาด (รูปนิ่งของหน้าเทมเพลต)
    ///
    /// `ImageRenderer` วาดรอบเดียวแล้วจบ ถ้าอบตอน Vision ยังไม่เสร็จ รูปเทมเพลตจะติดโหมดกรอบถาวร
    /// ทั้งที่เปิดการ์ดเข้าไปแล้วเห็นคนยืนบนการ์ด — สองหน้าพูดไม่ตรงกัน
    func prepare(_ ui: UIImage) async {
        start(ui)
        await entries[ObjectIdentifier(ui)]?.task?.value
    }

    private func start(_ ui: UIImage) {
        let key = ObjectIdentifier(ui)
        guard entries[key] == nil else { return }
        let entry = Entry(ui)
        entries[key] = entry
        revision &+= 1
        entry.task = Task { @MainActor in
            entry.result = await Self.compute(ui)
            entry.running = false
            self.revision &+= 1
        }
    }

    private static func compute(_ ui: UIImage) async -> Cutout.Result {
        let print = await Task.detached(priority: .userInitiated) { fingerprint(ui) }.value
        if let print, let url = cacheURL(print) {
            let hit = await Task.detached(priority: .userInitiated) { () -> Cutout.Result? in
                guard let data = try? Data(contentsOf: url), let img = UIImage(data: data) else { return nil }
                return Cutout.trim(img)
            }.value
            if let hit { return hit }
        }
        guard let out = await PhotoLift.lift(ui) else { return .framed(ui) }
        let r = await Task.detached(priority: .userInitiated) { Cutout.trim(out) }.value
        // เก็บ *ใบที่ครอปแล้ว* — เล็กกว่าต้นฉบับมาก และอ่านกลับมาใช้ได้ทันที
        if r.isCutout, let print, let url = cacheURL(print), let data = r.image.pngData() {
            try? data.write(to: url, options: .atomic)
        }
        return r
    }

    // MARK: กุญแจบนดิสก์

    private nonisolated static func cacheURL(_ print: UInt64) -> URL? {
        guard let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("subject-lift", isDirectory: true) else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(String(print, radix: 16) + ".png")
    }

    /// ลายนิ้วมือของรูป: ย่อเหลือ 16×16 แล้ว FNV-1a ทับขนาดพิกเซลจริง
    ///
    /// ไม่ใช้ `Hasher` — มันสุ่ม seed ใหม่ทุกครั้งที่เปิดแอป กุญแจจะไม่ตรงกับไฟล์ของรอบก่อนเลย
    private nonisolated static func fingerprint(_ ui: UIImage) -> UInt64? {
        guard let cg = ui.cgImage else { return nil }
        let n = 16
        var px = [UInt8](repeating: 0, count: n * n * 4)
        let ok = px.withUnsafeMutableBytes { raw -> Bool in
            guard let ctx = CGContext(data: raw.baseAddress, width: n, height: n,
                                      bitsPerComponent: 8, bytesPerRow: n * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            ctx.interpolationQuality = .low
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: n, height: n))
            return true
        }
        guard ok else { return nil }
        var h: UInt64 = 0xcbf29ce484222325
        func mix(_ b: UInt8) { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        for b in px { mix(b) }
        for v in [cg.width, cg.height, ui.imageOrientation.rawValue] {
            withUnsafeBytes(of: v.littleEndian) { $0.forEach(mix) }
        }
        return h
    }
}
