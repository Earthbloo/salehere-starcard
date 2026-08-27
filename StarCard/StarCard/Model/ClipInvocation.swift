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
    /// ค่าเริ่มต้นตรง mock creator ที่มีในโปรโตไทป์
    var slug: String = Mock.creator.handle
    var url: URL?

    func consume(_ activity: NSUserActivity) {
        guard activity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = activity.webpageURL else { return }
        consume(url)
    }

    func consume(_ url: URL) {
        self.url = url
        self.slug = Self.slug(from: url) ?? slug
    }

    /// Xcode ยัด URL ผ่าน env ตอน Run คลิปในซิม — `onContinueUserActivity` บางทีไม่ยิงตอน cold start
    func consumeLaunchURL() {
        if url != nil { return }
        if let raw = ProcessInfo.processInfo.environment["_XCAppClipURL"],
           let parsed = URL(string: raw) {
            consume(parsed)
        }
    }

    /// `https://saleherestarcard.co.th/star/nira.beauty` → `nira.beauty`
    static func slug(from url: URL) -> String? {
        let parts = url.pathComponents.filter { $0 != "/" }
        if parts.count >= 2, parts[0] == "star" { return parts[1] }
        if parts.count == 1, parts[0] != "star" { return parts[0] }
        return nil
    }
}
