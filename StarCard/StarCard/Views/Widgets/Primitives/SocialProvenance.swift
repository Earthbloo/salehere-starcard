// ชิ้นส่วนกลางที่ตัววาดผัง (SpecPainter) และหน้าจออื่นเรียกใช้ — ไม่ผูกกับ widget ตัวใด
import SwiftUI


// MARK: - ที่มาของยอดทั้งชุด

extension Array where Element == SocialProfile {
    /// ป้ายที่มาของ widget ผู้ติดตาม — ทุกช่องยืนยันแล้วถึงจะได้ป้ายเขียว
    /// มีช่องที่กรอกเองปนอยู่แม้ช่องเดียว ป้ายต้องบอกว่า "รอตรวจสอบ" (ป้ายเขียวคลุมเลขที่ยังไม่ตรวจ = การ์ดโกหก)
    var provenance: Provenance {
        // โต๊ะตรวจงานบังคับสถานะ "ยอดจากแพลตฟอร์ม" ได้ (ดู `VerifiedFacts.labForce`)
        if VerifiedFacts.labForce, !isEmpty { return .connected(first?.syncedAgo ?? "2 ชม.") }
        guard !isEmpty, allSatisfy(\.source.isVerified) else { return .manual }
        return .connected(first?.syncedAgo ?? "วันนี้")
    }
}
