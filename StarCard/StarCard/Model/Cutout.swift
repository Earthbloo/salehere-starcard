import UIKit

/// รูปที่ผู้ใช้ "ลบพื้นหลังมาแล้ว" — วัตถุดิบของ widget ตระกูลคัตเอาต์
///
/// # แอปไม่ตัดรูปให้
///
/// ตั้งใจไม่มี Vision/ML ในนี้ ผู้ใช้เอา PNG ที่ตัดมาเองมาวาง (iOS แตะค้างที่ตัวคนในแอปรูป
/// แล้วบันทึกก็ได้แล้ว) — ไฟล์นี้จึงมีหน้าที่แค่สองข้อ ซึ่งเป็นสองข้อที่ถ้าไม่ทำแล้วพัง:
///
/// ### 1 ตอบว่ารูปใบนี้ตัดมาจริงไหม
///
/// การมี alpha channel **ไม่พอ** — ภาพถ่ายที่ผ่านแอปแต่งรูปมาหลายใบมี channel ติดมาด้วย
/// แต่ทึบทั้งใบ ถ้าเชื่อแค่ `alphaInfo` widget จะเข้าโหมดคัตเอาต์ให้รูปเต็มเฟรม
/// แล้วได้สี่เหลี่ยมทึบวางทับตัวอักษร ซึ่งแย่กว่าโหมดกรอบทุกทาง
///
/// ตัวชี้ขาดที่ใช้คือ **ขอบนอกของภาพใสเป็นส่วนใหญ่หรือเปล่า** — รูปตัดพื้นหลังทุกใบมีเหมือนกัน
/// และรูปถ่ายเต็มเฟรมไม่มีวันมี (มุมมนหรือขอบจาง ๆ ไม่พอถึงเกณฑ์)
///
/// ### 2 ครอปที่ว่างใสรอบตัวทิ้ง
///
/// เครื่องมือตัดพื้นหลังส่วนใหญ่คืนภาพ **ขนาดเท่าต้นฉบับ** คนจึงกินพื้นที่จริงไม่ถึงครึ่งใบ
/// วางดิบ ๆ แล้วคนจะลอยเล็กจิ๋วอยู่กลางกรอบทั้งที่รูปเขาถูกแล้ว — แล้วเขาจะสรุปว่า
/// "แบบนี้ไม่สวย" ทั้งที่ปัญหาคือขอบใส ไม่ใช่ดีไซน์
enum Cutout {

    /// ผลการตรวจรูปหนึ่งใบ
    struct Result {
        /// รูปที่ครอปขอบใสออกแล้ว — ถ้าไม่ใช่รูปตัด จะเป็นใบเดิมไม่ถูกแตะ
        let image: UIImage
        /// ตัดพื้นหลังมาจริงไหม — `false` แปลว่า widget ต้องไปโหมดกรอบ
        let isCutout: Bool

        static func framed(_ ui: UIImage) -> Result { .init(image: ui, isCutout: false) }
    }

    // MARK: เกณฑ์

    /// ด้านของกริดที่ใช้สแกน — ไม่ต้องอ่านทุกพิกเซลของรูป 12MP เพื่อตอบคำถามสองข้อนี้
    private static let grid = 96
    /// อัลฟาต่ำกว่านี้ถือว่าใส (ไม่ใช่ 0 — ขอบที่ถูก antialias มีค่าเศษติดมาเสมอ)
    private static let clearLevel: UInt8 = 16
    /// ต้องมีพื้นที่ใสอย่างน้อยเท่านี้ถึงจะเรียกว่ารูปตัด
    private static let minClearRatio = 0.12
    /// ด้านของหย่อมมุมที่เอามาตรวจ — กี่ส่วนของด้านภาพ
    private static let cornerPatch = 0.14
    /// สี่มุมรวมกันต้องใสอย่างน้อยเท่านี้
    private static let cornerClearRatio = 0.55
    /// ตัวแบบต้องกินพื้นที่อย่างน้อยเท่านี้ — ต่ำกว่านี้คือเศษขยะ ไม่ใช่คน
    private static let minSubjectRatio = 0.02
    /// เผื่อขอบรอบตัวแบบตอนครอป — เงาและเส้นผมที่จางมากอยู่นอกกริดหยาบ ๆ ได้
    private static let padRatio: CGFloat = 0.015

    // MARK: ทางเข้า

    static func inspect(_ ui: UIImage) -> Result {
        guard let cg = upright(ui).cgImage, hasAlphaChannel(cg),
              let a = alphaGrid(cg) else { return .framed(ui) }
        guard looksCut(a), let box = subjectBox(a),
              let out = crop(cg, to: box, scale: ui.scale) else { return .framed(ui) }
        // กันภาพที่ครอปแล้วเหลือเศษ — ถ้าปล่อยผ่าน widget จะยืดของกว้าง 3 พิกเซลเต็มกรอบ
        // แล้วทั้งใบกลายเป็นริ้วสีพาดจอ ซึ่งดูไม่ออกเลยว่ามาจากรูป · โหมดกรอบปลอดภัยกว่าเสมอ
        guard out.size.width >= 24, out.size.height >= 24 else { return .framed(ui) }
        return .init(image: out, isCutout: true)
    }

    /// ครอปรูปที่ **รู้อยู่แล้วว่าตัดมา** (ผลของ `PhotoLift`) — ข้ามเกณฑ์ `looksCut`
    ///
    /// หน้ากากจาก Vision ถูกต้องตามนิยามอยู่แล้ว แต่คนครึ่งตัวที่กินเต็มเฟรมจะชนมุมล่างทั้งสองมุม
    /// แล้วตกเกณฑ์มุมใส — ถ้าส่งเข้า `inspect` ใบที่เพิ่งลบพื้นให้จะถูกตีกลับไปโหมดกรอบเฉย ๆ
    static func trim(_ ui: UIImage) -> Result {
        guard let cg = upright(ui).cgImage, let a = alphaGrid(cg), let box = subjectBox(a),
              let out = crop(cg, to: box, scale: ui.scale),
              out.size.width >= 24, out.size.height >= 24 else { return .framed(ui) }
        return .init(image: out, isCutout: true)
    }

    // MARK: ขั้นตอน

    /// ปรับภาพให้ตั้งตรงก่อนแตะ `cgImage`
    ///
    /// `cgImage` ไม่รู้จัก `imageOrientation` — รูปจากกล้องที่ถ่ายแนวตั้งเก็บพิกเซลเป็นแนวนอน
    /// แล้วบอกให้หมุนตอนวาด ครอปตรง ๆ จึงได้กรอบที่หมุนผิดด้าน 90°
    private static func upright(_ ui: UIImage) -> UIImage {
        guard ui.imageOrientation != .up else { return ui }
        let f = UIGraphicsImageRendererFormat.default()
        f.scale = ui.scale
        f.opaque = false
        return UIGraphicsImageRenderer(size: ui.size, format: f).image { _ in
            ui.draw(in: CGRect(origin: .zero, size: ui.size))
        }
    }

    private static func hasAlphaChannel(_ cg: CGImage) -> Bool {
        switch cg.alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly: return true
        default: return false
        }
    }

    /// อ่าน alpha ลงกริดเล็ก — แถวที่ 0 คือ **ขอบล่าง** ของภาพ (แกน y ของ CGContext ชี้ขึ้น)
    ///
    /// วาดลง RGBA แล้วหยิบเฉพาะไบต์อัลฟา ไม่ใช่ `alphaOnly` ตรง ๆ — `CGContext` ฝั่ง Swift
    /// บังคับให้ส่ง color space มาเสมอ ซึ่งเป็นสิ่งที่บริบท alpha ล้วนไม่มี · 96×96 กินแค่ 36KB
    private static func alphaGrid(_ cg: CGImage) -> [UInt8]? {
        let n = grid
        var rgba = [UInt8](repeating: 0, count: n * n * 4)
        let ok = rgba.withUnsafeMutableBytes { raw -> Bool in
            guard let ctx = CGContext(data: raw.baseAddress, width: n, height: n,
                                      bitsPerComponent: 8, bytesPerRow: n * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            // ห้าม interpolate — การเฉลี่ยจะลากพิกเซลใสกับทึบมาผสมกัน แล้วขอบนอกของรูปตัด
            // จะกลายเป็นครึ่งทึบทั้งวง ซึ่งทำให้ `rimIsClear` ตอบไม่ตามความจริง
            ctx.interpolationQuality = .none
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: n, height: n))
            return true
        }
        guard ok else { return nil }
        var a = [UInt8](repeating: 0, count: n * n)
        for i in 0..<(n * n) { a[i] = rgba[i * 4 + 3] }
        return a
    }

    /// รูปใบนี้ถูกตัดพื้นหลังมาไหม
    ///
    /// # ทำไมไม่ตรวจ "ขอบนอกทั้งวงใส"
    ///
    /// นั่นคือเกณฑ์แรกที่ใช้ แล้วมันปฏิเสธรูปตัดของจริงใบแรกที่เทสต์ทันที — เพราะคนที่ถูกตัดมา
    /// มัก **ชนขอบล่าง** (ตัดครึ่งตัวกันเอง) หรือชนขอบข้างเวลายืนเอียง พอแถบล่างไม่ใส
    /// ทั้งใบก็ตกไปโหมดกรอบ ทั้งที่มันคือรูป PNG โปร่งใสเต็มใบ
    ///
    /// เกณฑ์ที่ใช้จริงจึงเป็นสองข้อที่รูปถ่ายเต็มเฟรมไม่มีวันผ่านทั้งคู่:
    /// **มีพื้นที่ใสจริงพอสมควร** (รูปทึบมี 0% · มุมมนมีไม่ถึง 2%) และ
    /// **มุมส่วนใหญ่ว่าง** (ตัวแบบชนขอบได้ แต่ไม่มีทางเต็มทั้งสี่มุมพร้อมกัน)
    private static func looksCut(_ a: [UInt8]) -> Bool {
        let n = grid
        var clear = 0
        for v in a where v < clearLevel { clear += 1 }
        guard Double(clear) / Double(n * n) >= minClearRatio else { return false }

        let c = max(2, Int(Double(n) * cornerPatch))
        var total = 0, open = 0
        for (ox, oy) in [(0, 0), (n - c, 0), (0, n - c), (n - c, n - c)] {
            for y in oy..<(oy + c) {
                for x in ox..<(ox + c) {
                    total += 1
                    if a[y * n + x] < clearLevel { open += 1 }
                }
            }
        }
        guard total > 0 else { return false }
        return Double(open) / Double(total) >= cornerClearRatio
    }

    /// กรอบของส่วนที่ทึบ — คืนเป็นสัดส่วน 0–1 ของภาพ โดยแกน y **ชี้ลงจากขอบบน** แล้ว
    private static func subjectBox(_ a: [UInt8]) -> CGRect? {
        let n = grid
        var minX = n, maxX = -1, minY = n, maxY = -1, solid = 0
        for y in 0..<n {
            for x in 0..<n where a[y * n + x] >= clearLevel {
                solid += 1
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
        }
        guard maxX >= minX, maxY >= minY,
              Double(solid) / Double(n * n) >= minSubjectRatio else { return nil }
        let s = CGFloat(n)
        return CGRect(x: CGFloat(minX) / s,
                      // พลิกแกน y กลับเป็นระบบของภาพ (ลงจากขอบบน) ก่อนส่งออกจากที่นี่
                      y: CGFloat(n - 1 - maxY) / s,
                      width: CGFloat(maxX - minX + 1) / s,
                      height: CGFloat(maxY - minY + 1) / s)
    }

    /// ครอปตามสัดส่วนที่ได้ — เผื่อขอบเล็กน้อยแล้วรูดกลับเข้าในภาพเสมอ
    ///
    /// กรอบที่กินเกือบทั้งใบอยู่แล้วไม่ครอป — ครอปไป 1–2% ไม่ได้อะไรนอกจากภาพใหม่อีกใบในหน่วยความจำ
    private static func crop(_ cg: CGImage, to box: CGRect, scale: CGFloat) -> UIImage? {
        guard box.width < 0.97 || box.height < 0.97 else {
            return UIImage(cgImage: cg, scale: scale, orientation: .up)
        }
        let w = CGFloat(cg.width), h = CGFloat(cg.height)
        let pad = max(box.width * w, box.height * h) * padRatio
        let r = CGRect(x: box.minX * w - pad, y: box.minY * h - pad,
                       width: box.width * w + pad * 2, height: box.height * h + pad * 2)
            .intersection(CGRect(x: 0, y: 0, width: w, height: h))
            .integral
        guard r.width >= 1, r.height >= 1, let out = cg.cropping(to: r) else { return nil }
        return UIImage(cgImage: out, scale: scale, orientation: .up)
    }
}

// MARK: - แคชผลการตรวจ

/// ผลการตรวจของรูปแต่ละใบ — คิดครั้งเดียวต่อหนึ่งใบ
///
/// **ไม่ใช่ `@Observable`** ตั้งใจ: ตัวนี้ถูกอ่านระหว่าง `body` ของ widget แล้วเขียนแคชกลับทันที
/// ถ้าอยู่ในสโตร์ที่ถูกสังเกต การเขียนนั้นจะสั่งวาดใหม่ แล้ววาดใหม่ก็อ่านอีก — วนไม่จบ
@MainActor
final class CutoutCache {
    static let shared = CutoutCache()
    private var store: [ObjectIdentifier: Cutout.Result] = [:]

    func result(for ui: UIImage) -> Cutout.Result {
        let key = ObjectIdentifier(ui)
        if let hit = store[key] { return hit }
        let r = Cutout.inspect(ui)
        store[key] = r
        return r
    }
}
