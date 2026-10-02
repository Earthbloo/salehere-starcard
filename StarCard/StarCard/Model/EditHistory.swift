import Foundation

/// ประวัติแก้ไขของการ์ดหนึ่งใบ — ภาพนิ่งของ `pages` + `theme` ต่อหนึ่งจังหวะ
///
/// # ทำไมต้องมี
///
/// แถบเครื่องมือล่างไม่มีปุ่ม "ยกเลิก" — ทุกตัวเลือกมีผลบนการ์ดทันทีที่แตะ
/// (เห็นผลแล้วค่อยตัดสิน เร็วกว่าเลือกแล้วกดยืนยัน) ทางกลับทางเดียวจึงเป็น ↶ ↷
/// ถ้าไม่มีสองปุ่มนี้ การแตะสีสำเร็จรูปดูเล่นหนึ่งครั้งคือการทิ้งสีแบรนด์ที่พิมพ์ไว้ถาวร
///
/// # จังหวะเดียว ไม่ใช่ทุกเฟรม
///
/// ลากแถบสีหนึ่งครั้งเปลี่ยนค่าเป็นสิบ ๆ รอบ · ลากหมุดปรับขนาดก็เช่นกัน
/// ถ้าบันทึกทุกรอบ กด ↶ หนึ่งทีจะย้อนไปแค่หนึ่งพิกเซล ซึ่งไม่ใช่สิ่งที่ใครหมายถึง
/// การเปลี่ยนที่ติดกันภายใน `coalesce` จึงนับเป็นจังหวะเดียว (เก็บเฉพาะสถานะก่อนรอบแรก)
struct EditHistory {
    struct Snapshot: Equatable {
        var pages: [CardPage]
        var theme: CardTheme
    }

    private(set) var past: [Snapshot] = []
    private(set) var future: [Snapshot] = []
    private var lastRecord: TimeInterval = 0

    private static let coalesce: TimeInterval = 0.6
    private static let cap = 80

    var canUndo: Bool { !past.isEmpty }
    var canRedo: Bool { !future.isEmpty }

    /// บันทึกสถานะ **ก่อนเปลี่ยน** — เรียกจาก `onChange` โดยส่งค่าเก่าเข้ามา
    mutating func record(_ before: Snapshot) {
        let now = Date().timeIntervalSinceReferenceDate
        defer { lastRecord = now }
        // แก้อะไรใหม่ = ทางไปข้างหน้าที่เคยย้อนไว้หมดความหมาย
        future.removeAll()
        if now - lastRecord < Self.coalesce, !past.isEmpty { return }
        past.append(before)
        if past.count > Self.cap { past.removeFirst() }
    }

    mutating func undo(current: Snapshot) -> Snapshot? {
        guard let s = past.popLast() else { return nil }
        future.append(current)
        lastRecord = 0
        return s
    }

    mutating func redo(current: Snapshot) -> Snapshot? {
        guard let s = future.popLast() else { return nil }
        past.append(current)
        lastRecord = 0
        return s
    }
}
