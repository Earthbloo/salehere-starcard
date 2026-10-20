import Foundation

/// ตัวแทนของ `WidgetKind` ของแอป — `SpecCatalog.spec(for:)` อ้างถึงแค่ `rawValue`
/// แอปจริงมี `WidgetKind` ของตัวเอง ไฟล์นี้มีไว้ให้แพ็กเกจพิสูจน์ว่าโมดูลวาดคอมไพล์ที่ iOS 16 ได้โดยไม่พึ่งโค้ดอื่นของแอป
struct WidgetKind: RawRepresentable, Hashable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}
