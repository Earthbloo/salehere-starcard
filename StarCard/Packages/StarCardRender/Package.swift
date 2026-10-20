// swift-tools-version: 5.9
import PackageDescription

// พิสูจน์ว่า "เครื่องวาด Star Card" (ผัง → solver → ตัววาด UIKit) คอมไพล์ที่ **iOS 16.0** โดยไม่พึ่ง SwiftUI/โค้ดอื่นของแอป
// ไฟล์ใน Sources/ เป็น symlink ไปยังไฟล์จริงใน StarCard/ (Render/ · Model/WidgetSpec.swift · Layout/SpecSolver.swift)
// จึงเป็นโค้ดชุดเดียวกับที่แอปต้นแบบใช้ — ไม่มีสำเนาให้เพี้ยน · build: `swift build` ตามหัว StarCard/WIDGET-SPEC.md §6
let package = Package(
    name: "StarCardRender",
    platforms: [.iOS(.v16)],
    products: [.library(name: "StarCardRender", targets: ["StarCardRender"])],
    targets: [.target(name: "StarCardRender", path: "Sources/StarCardRender")]
)
