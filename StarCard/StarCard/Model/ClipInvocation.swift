import SwiftUI

/// แอปหลักกับ App Clip แชร์ไบนารีคนละก้อน — สวิตช์นี้มาจาก flag ของคลิป target
enum AppRuntime {
    static var isClip: Bool {
        #if APPCLIP
        true
        #else
        false
        #endif
    }
}

/// URL ที่เปิดคลิป/แอปมา — ในซิมใช้ `_XCAppClipURL` ยัดเข้ามาแทน QR จริง
@Observable
final class ClipInvocation {
    /// slug จาก URL ที่เปิดมา — nil = แอปเปิดปกติ ใช้ชื่อผู้ใช้ปัจจุบันของโปรไฟล์แทน
    private var urlSlug: String?
    var url: URL?

    /// ท้ายลิงก์ประจำตัว — **ตามชื่อผู้ใช้ที่แก้ล่าสุดเสมอ** ไม่ใช่ค่าที่จำไว้ตอนเปิดแอป
    /// (เคยเก็บเป็นค่าคงที่ตอน init: แก้ชื่อผู้ใช้ในฟอร์มแล้ว footer การ์ดยังเป็นชื่อเก่าทั้งที่หัวหน้าเปลี่ยนไปแล้ว)
    var slug: String { urlSlug ?? Profile.me.handle }

    func consume(_ activity: NSUserActivity) {
        guard activity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = activity.webpageURL else { return }
        consume(url)
    }

    func consume(_ url: URL) {
        self.url = url
        if let s = Self.slug(from: url) { urlSlug = s }
    }

    /// Xcode ยัด URL ผ่าน env ตอน Run คลิปในซิม — `onContinueUserActivity` บางทีไม่ยิงตอน cold start
    func consumeLaunchURL() {
        if url != nil { return }
        if let raw = ProcessInfo.processInfo.environment["_XCAppClipURL"],
           let parsed = URL(string: raw) {
            consume(parsed)
        }
    }

    /// `https://salehere.co.th/star/nira.beauty` → `nira.beauty`
    /// รับลิงก์โปรไฟล์เดิมของแอปหลักด้วย: `/user/nira.beauty/creator-profile-info`
    static func slug(from url: URL) -> String? {
        let parts = url.pathComponents.filter { $0 != "/" }
        if parts.count >= 2, parts[0] == "star" || parts[0] == "user" { return parts[1] }
        if parts.count == 1, parts[0] != "star" { return parts[0] }
        return nil
    }

    /// ลิงก์การ์ดที่เอาไปแปะ Line / ไบโอได้ — ใช้ URL ที่เปิดมา ถ้าไม่มีก็ประกอบจาก slug
    ///
    /// โดเมนเดียวกับแอปหลัก — ที่อยู่คือลายเซ็นที่ถูกที่สุด (คนรู้ว่าเป็นของใครตั้งแต่เห็นลิงก์ในไบโอ)
    /// โดเมนใหม่ต้องเริ่มสะสมความจำจากศูนย์ ส่วน salehere.co.th มีคนรู้จักอยู่แล้ว
    static let host = "salehere.co.th"

    var shareURL: URL {
        url ?? URL(string: "https://\(Self.host)/star/\(slug)")!
    }

    /// โฮสต์ + พาธ อ่านง่ายในแถวคัดลอก ไม่มี https://
    var shareURLDisplay: String {
        let u = shareURL
        let host = u.host ?? Self.host
        let path = u.path == "/" ? "" : u.path
        return host + path
    }
}
