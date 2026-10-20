# Render/ — เครื่องวาด Star Card ฉบับ UIKit (iOS 16) สำหรับ salehere-ios

ต้นแบบวาด widget ด้วย SwiftUI (iOS 26) แต่แอปจริงเป็น UIKit iOS 16.6 — โฟลเดอร์นี้คือ **ตัววาดชุดที่สอง** ที่รับ
กล่องชุดเดียวกันจาก `SpecSolver` แล้ววาดด้วย CoreAnimation/CoreText ล้วน ๆ ใช้ API ตั้งแต่ iOS 16 เท่านั้น
พิสูจน์สองชั้นในโปรเจกต์นี้ (ตัวเลข 20 ต.ค. 2569: 122 ชนิด × 6 กรอบ · ภาพต่าง <1% 7 ใบ · 1–5% 103 ใบ · ≥5% 12 ใบ สูงสุด 8.4% · ดู `WIDGET-SPEC.md` §7):

1. **คอมไพล์ที่ iOS 16.0** — `Packages/StarCardRender` (symlink ไฟล์ชุดนี้ + `WidgetSpec.swift` + `SpecSolver.swift`):
   `cd StarCard/Packages/StarCardRender && swift build --triple arm64-apple-ios16.0-simulator --sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)"`
2. **ภาพเท่า SwiftUI** — `-exportRenderAB -exportPerson` วาดทุกใบ × 6 กรอบด้วยตัววาดทั้งสองจากกล่องเดียวกัน แล้ว
   `present/render-ab/run.sh <udid>` เทียบพิกเซล → `present/render-ab/out/report.html`

## ย้ายไป salehere-ios ยังไง

| เอาไปทั้งไฟล์ (ไม่แก้) | เขียนเองใน salehere-ios |
|---|---|
| `Model/WidgetSpec.swift` (ผัง JSON → โหนด) | `SpecRenderContext` ของแอปจริง: สี token · ฟอนต์ · รูปของช่อง · asset · ไอคอน (ดู `AppRenderContext` ใน `Views/Export/RenderABExport.swift` เป็นตัวอย่าง) |
| `Layout/SpecSolver.swift` (ตัวคำนวณ — ห้ามแก้ ต้องได้ fixture เท่า byte) | `SpecDataSource` จาก model จริง (ชื่อฟิลด์ตาม `WIDGET-SPEC.md` §3.2 · `shared/category-models.json`) |
| `Render/SpecRenderShapes.swift` · `SpecRenderPatterns.swift` | `SpecMeasurer` — ใช้ `IOSSpecMeasurer` (ท้าย `SpecPainter.swift`) ได้เลย เป็น UIKit อยู่แล้ว |
| `Render/SpecLayerPainter.swift` (`SpecWidgetView`) | ไอคอนที่ต้นแบบวาดด้วย SwiftUI (`verifiedSeal` · `qr` · `guilloche` · `starLockup` …) — วาดใหม่ด้วย UIKit หรือใช้ asset |
| `Render/SpecChromeView.swift` (เปลือก · กระจก = `UIBlurEffect` แทน Liquid Glass) | หน้าการ์ด/การวาง (`PageLayout` · pinned seal — สูตรใน §9) |
| `shared/WidgetSpecs/*.json` + `shared/category-models.json` | |

ลำดับเรียกต่อใบ (= `RenderABExport.renderUIKit`):

```swift
let (s, layout) = SpecChrome.layout(frame: frame.size, design: spec.design.cg, isTextLayer: false)
let inset = SpecChrome.contentInset(traits, surface: surface, border: border)
let box = CGSize(width: layout.width - inset * 2, height: layout.height - inset * 2)
let solver = SpecSolver(spec: spec, box: box, data: data, measurer: measurer, renderScale: s)
let widget = SpecWidgetView(boxes: solver.solve(), box: box, fitScale: solver.scale, context: ctx, pixelScale: UIScreen.main.scale * s)
let view = SpecChromeView(frame: frame, design: spec.design.cg, traits: traits, surface: surface, border: border, style: style, content: widget)
```

## สิ่งที่ยอมให้ต่างจาก SwiftUI (WIDGET-SPEC.md §6)

- กระจก: iOS 16 ไม่มี Liquid Glass → ทาทึบด้วยสีที่ Liquid Glass ของ SwiftUI วาดออกมาจริง (วัด 21 ต.ค. 2569: หมึกสว่าง ขาว 57.5% · หมึกมืด/คู่สี ขาว 5.6% · ชั้น verified บนหมึกมืด ดำ 70% + สีเน้น 5%) — ค่าเดียวกับ GlassPanel.kt และ chrome.js
- เงา: `sigma × 2` เป็น `shadowRadius` ของ CoreAnimation (kernel ต่างได้ ±2%)
- anti-alias ขอบตัวอักษร/เส้นโค้ง · ไอคอนที่ rasterize จาก SwiftUI ในต้นแบบ
- `mixHead` ย่อทีละ 2% จนลงบรรทัด (SwiftUI ใช้ `minimumScaleFactor(0.5)` ซึ่งหาค่าต่อเนื่อง)
