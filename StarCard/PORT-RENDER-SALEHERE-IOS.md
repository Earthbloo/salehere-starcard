# ย้ายตัววาด Star Card ทั้งชุดไป salehere-ios (mock ในโค้ดก่อน API จริง)

21 ต.ค. 2569 · คู่กับ `WIDGET-SPEC.md` (สัญญาของผัง) · `Render/README.md` (ตัววาด UIKit) · `PORT-SALEHERE-IOS.md` (Star Profile → API เดิม)

## ผลที่ต้องได้

กด **"ดูการ์ดของฉัน"** ใน Star Profile → `StarCardMockService` คืนการ์ด JSON ที่ฝังในแอป (ไม่เรียกเน็ต) → เปิดหน้า Star Card
ที่วาดการ์ดสตอรี่ 540×960 (4 ใบ: `heroMinimal` · `statPoster` · `kitRatePurple` · `proofSeal`) ด้วยตัววาด UIKit ชุดเดียวกับต้นแบบ

- ไม่มีชื่อ widget ในโค้ด — ผัง JSON บอกทุกอย่าง (WIDGET-SPEC §1) · เพิ่ม widget = เพิ่มไฟล์ JSON ไม่ต้อง build
- วันที่ทีม API ทำ GraphQL เสร็จ เปลี่ยนแค่ Service ตัวเดียว (ข้อ 3.7) โมเดล/ตัววาดไม่เปลี่ยน — JSON ก้อนเดียวกันนี้คือสิ่งที่ API จะส่งมา
- ตัววาดคอมไพล์ที่ iOS 16.0 แล้ว (`Packages/StarCardRender`) · ภาพเทียบ SwiftUI ต่าง <5% 110/122 ใบ (WIDGET-SPEC §7)

## ขอบเขตรอบแรก (21 ต.ค. 2569)

| ทำ | ยังไม่ทำ |
|---|---|
| ย้าย**ตัวคำนวณ + ตัววาด**ทั้งชุด (ข้อ 2) ให้วาดการ์ด JSON ข้อ 1 ออกมาได้ | แหล่งข้อมูลจริงจาก `creatorProfile` — ข้อมูลเป็น **mock ตายตัวในโค้ด** (3.5) |
| ธีม/สี · เปลือก · ประกอบหน้า · Scene + ปุ่ม "ดูการ์ดของฉัน" | รูป/อัปโหลดรูป — `photo(slot:)` คืน `nil` ไปก่อน (4 ใบนี้ไม่มีช่องรูปอยู่แล้ว) |
| ไอคอน 5 ตัวที่ 4 ใบใช้ (ข้อ 5 · คืน `nil` ไปก่อนก็วาดได้) | GraphQL — รอทีม API (ข้อ 7) |

## 0. รู้ก่อน 6 ข้อ

1. **สายงานวาดต่อใบ**: `WidgetSpec` (ผัง JSON) + `Widget` (ชิ้นในการ์ด: x y w h surface border options) + ข้อมูลเจ้าของ → `SpecSolver` (กล่อง) → `SpecWidgetView` (วาด) → `SpecChromeView` (เปลือก) — ตัวเลขทุกตัวเป็น pt หน่วยออกแบบของหน้า
2. **สูตรเดียวของเปลือก** (§2): `s = min(W/w0, H/h0)` · `inset = 12` ถ้ามีแผ่น/ขอบ, `0` ถ้าใบวาดพื้นเอง (`widget.ownSurface`) · `box = (W/s − 2·inset, H/s − 2·inset)` · ตัววาด scale ทั้งก้อนด้วย `s` จากมุมบนซ้าย
3. **ทุกอย่างที่ขึ้นกับแอปผ่าน 3 protocol**: `SpecDataSource` (ข้อความ/รายการ/ธง) · `SpecMeasurer` (วัดตัวอักษร) · `SpecRenderContext` (สี token · ฟอนต์ · รูป · asset · ไอคอน) — ตัววาด/ตัวคำนวณห้ามแก้
4. **สี**: ผังเขียนแค่บทบาท `bg bg2 ink ink2 accent line` (+ `@ความทึบ`) บนพื้น `card | light | dark` (§4) · สีจริงคิดจาก `theme.colors {primary, secondary?}` + `theme.ink` ด้วยสูตรเดียวทุกแพลตฟอร์ม
5. **ฟอนต์**: ผังทุกใบใช้ `face: "noto"` = NotoSansThai (weight 100–900 → Light/Regular/Medium/SemiBold/Bold/ExtraBold/Black) — salehere-ios มีครบใน `UIAppFonts` แล้ว ไม่ต้องเพิ่มไฟล์ · `mitr` มีใน Assets แต่ยังไม่ลงทะเบียน (4 ใบนี้ไม่ใช้)
6. **ตัวเลขต้องเท่า fixture ทุก byte** — `SpecSolver.swift` ห้ามแตะ · ถ้าสงสัยว่าวาดผิด ให้เทียบกล่องกับ `present/spec-fixtures/<kind>.json` ก่อนเทียบภาพ

## 1. Mock ในโค้ด — การ์ด JSON ก้อนเดียวที่ใช้ทดสอบ

ไม่มี server · ไม่เรียก API · ฝัง JSON นี้ไว้ในแอป (ไฟล์ `StarCardMock.json` ใน bundle หรือ string literal) แล้วให้ `StarCardMockService` (3.7) decode ส่งกลับ
รูปแบบ = `StarCard` ใน `sync-server/MODEL.md` (ฟิลด์เดียวกับ GraphQL `starCard` ที่ร่างไว้ใน `sync-server/graphql.mjs`) — ทีม API ทำเสร็จแล้วแอปไม่ต้องแก้โมเดล

การ์ด = ใบที่ให้มา (คู่สี teal `#0E3B3E` / `#F7CBA7` · `ink: mist` = โทนสว่าง → **พื้นการ์ดสีพีช หมึกเขียวเข้ม**) · เพิ่ม `owner` เพื่อให้ widget มีข้อมูลวาด (ชื่อ · 3 ช่องทาง · 4 เรท) — รูปร่าง `owner` ตาม `sync-server/web/js/data.js` ของเว็บ (ของจริงฝั่งแอปจะอ่าน `creatorProfile` แทน · ข้อ 7)

```json
{
  "format": "story",
  "name": "การ์ดของฉัน",
  "theme": { "colors": { "primary": "#0E3B3E", "secondary": "#F7CBA7" }, "ink": "mist", "backdrop": "solid" },
  "pages": [
    {
      "items": [
        { "id": "56554044-008d-457d-b4da-c337d24913b6", "kind": "heroMinimal",   "x": 18,  "y": 18,  "w": 504, "h": 186, "surface": "glass", "border": true,  "options": {} },
        { "id": "92d8aebf-fa4b-46b6-b155-79251f9a87d5", "kind": "statPoster",    "x": 18,  "y": 214, "w": 504, "h": 295, "surface": "glass", "border": false, "options": {} },
        { "id": "99a519e6-2656-4023-b284-2a149791cd92", "kind": "kitRatePurple", "x": 18,  "y": 519, "w": 246, "h": 238, "surface": "glass", "border": true,  "options": {} },
        { "id": "498e1418-dcbf-4607-85a9-41eddb1948ae", "kind": "proofSeal",     "x": 276, "y": 786, "w": 246, "h": 156, "surface": "glass", "border": false, "options": {} }
      ]
    }
  ],
  "notes": {},
  "photos": {},
  "owner": {
    "verified": true,
    "values": {
      "name": "มณีรัตน์ ใจดี", "nickname": "เมย์", "handle": "mae.review",
      "tagline": "Fashion & Café Creator", "workArea": "กรุงเทพมหานคร",
      "about": "ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่ร้านคาเฟ่น่ารักๆ"
    },
    "list": { "categories": ["แฟชั่น", "คาเฟ่", "ท่องเที่ยว"] },
    "intake": {
      "socials": [
        { "type": "instagram", "link": "https://instagram.com/mae.review", "followers": 24800, "source": "connected", "enabled": true },
        { "type": "tiktok",    "link": "https://tiktok.com/@mae.review",   "followers": 58300, "source": "connected", "enabled": true },
        { "type": "youtube",   "link": "https://youtube.com/@maereview",   "followers": 8900,  "source": "api",       "enabled": true }
      ],
      "rates": [
        { "platform": "instagram", "formatKey": "reels",  "price": 3000, "touched": true },
        { "platform": "instagram", "formatKey": "post",   "price": 2400, "touched": true },
        { "platform": "tiktok",    "formatKey": "short",  "price": 7000, "touched": true },
        { "platform": "youtube",   "formatKey": "shorts", "price": 1100, "touched": true }
      ]
    }
  }
}
```

- `schemaVersion` ไม่ต้องมี (ตัวที่ให้มามี `1` ใส่ไว้ก็ได้ decoder ข้าม) · ผัง widget ใช้ที่ฝังใน bundle (ข้อ 2) ไม่ต้องดึงจากไหน
- รอบนี้ 4 ใบไม่มีช่องรูป → `photos` ว่าง · `notes` ว่าง (ไม่มี `textBlock`)

## 2. ก๊อปไปทั้งไฟล์ — ห้ามแก้ (≈2,400 บรรทัด)

แนะนำวางที่ `SaleHere/StarCardRender/` เป็น group เดียว (ไฟล์เดิมใช้แค่ `UIKit` `CoreGraphics` `CoreImage` `Foundation`):

| จากต้นแบบ (`StarCard/StarCard/`) | หน้าที่ |
|---|---|
| `Model/WidgetSpec.swift` | ผัง JSON → โหนด · `SpecCatalog` โหลดผังจาก bundle (`Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "WidgetSpecs")` — ไม่มีโฟลเดอร์ก็อ่าน json ทั้ง bundle) · `widgetMeta(kind)` อ่านบล็อก `widget` |
| `Layout/SpecSolver.swift` | ตัวคำนวณ + `SpecLegibility` + protocol `SpecDataSource` `SpecMeasurer` + `SpecFont` `SpecItem` `SpecBox` |
| `Render/SpecRenderContext.swift` | protocol ที่แอปต้อง implement (ข้อ 3.4) |
| `Render/SpecRenderShapes.swift` · `SpecRenderPatterns.swift` | รูปทรง/ลาย CoreGraphics |
| `Render/SpecLayerPainter.swift` | `SpecWidgetView` = ต้นไม้ UIView/CALayer จากกล่อง |
| `Render/SpecChromeView.swift` | `SpecChrome.layout / contentInset` + `SpecChromeView` (เปลือก · กระจกทาทึบด้วยสีที่วัดจาก Liquid Glass) |
| `Packages/StarCardRender/Sources/StarCardRender/WidgetKindShim.swift` | `struct WidgetKind: RawRepresentable` — `SpecCatalog` อ้างแค่ `rawValue` · salehere-ios ไม่มี enum นี้ ใช้ shim ตัวนี้เลย |
| `shared/WidgetSpecs/*.json` (122 ไฟล์) | ลาก **folder reference** (สีน้ำเงิน) ชื่อ `WidgetSpecs` เข้า target · รอบ mock จะใส่แค่ 4 ไฟล์ก็ได้ |
| `shared/category-models.json` | (ไม่บังคับ) ไว้เช็กว่าแหล่งข้อมูลตอบครบ |

พิสูจน์ว่าชุดนี้คอมไพล์ที่ iOS 16 โดยไม่พึ่งอะไร (ก่อนลากเข้าโปรเจกต์):

```bash
cd StarCard/Packages/StarCardRender && swift build --triple arm64-apple-ios16.0-simulator --sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)"
```

## 3. เขียนเองใน salehere-ios (7 ไฟล์)

### 3.1 `StarCardDoc.swift` — โมเดลการ์ด (Codable ตรงกับ JSON ของ API)

```swift
struct StarCardDoc: Codable {
    struct Theme: Codable {
        struct Colors: Codable { var primary: String; var secondary: String? }
        var colors: Colors?
        var ink: String            // night · paper · mist
        var backdrop: String       // solid · gradient (photo ยังไม่ทำรอบนี้)
    }
    struct Item: Codable {
        var id: String
        var kind: String
        var x: Double, y: Double, w: Double, h: Double
        var surface: String?       // glass (ตั้งต้น) · dim · clear · pane
        var border: Bool?
        var options: [String: String]?   // ค่าจากถาด (`widget.controls`) — รอบ mock ยังว่าง
    }
    struct Page: Codable { var items: [Item] }
    var format: String             // story (1 หน้า 540×960) · portfolio (3 หน้า กว้าง 402 สูงตามจอ)
    var name: String?
    var theme: Theme
    var pages: [Page]
    var owner: JSONValue?          // ข้อมูลเจ้าของ — รอบ mock อ่านจากตรงนี้ (3.5) · ของจริงอ่านจาก creatorProfile
    var notes: [String: String]?
    var photos: JSONValue?
}
```

ฟิลด์ที่ไม่รู้จักต้องไม่ทำให้ decode ล้มทั้งใบ (ทุกตัวเป็น optional ยกเว้น 8 ฟิลด์หลักของชิ้น) — ชิ้นที่ `kind` ไม่มีผังในแอป **ข้ามไป** ไม่ crash

### 3.2 `StarCardTheme.swift` — สีของการ์ดจาก 2 ค่า (UIColor)

สูตรเดียวกับ `CardTheme.swift` (ต้นแบบ · SwiftUI) = `makeTheme()` ใน `sync-server/web/js/theme.js:215-275` (JS ล้วน อ่านง่ายกว่า — **port บรรทัดต่อบรรทัดจากตัวนี้**):

| ค่า | สูตร |
|---|---|
| `duo` | มี `secondary` → คู่สี: เข้ม = luminance ต่ำกว่า · `ink != night` (paper/mist) → **พื้น = สีอ่อน หมึก = สีเข้ม** · `night` → กลับกัน |
| `backdropHue` | hue ของ `primary` (HSB) |
| `activeInk` | คู่สี: ตาม `ink` · สีเดียว: `ink` จาก doc (แอปต้นแบบคิด `autoInk` ตอนเลือกสีแล้วเก็บลง doc) · `isLight = activeInk != night` |
| พื้นการ์ด (`backdropColors`) | solid = `top` · gradient = `top → bottom` · คู่สี: top = พื้นคู่, bottom = mix(พื้น, หมึก, 0.10) · สีเดียว: top = primary, bottom = hsb(h, min(1, s×1.06), b×0.80) |
| `inkStyle` | คู่สี: `InkStyle(activeInk, base: หมึกคู่)` · มืด: `InkStyle.night` (ขาว) · สว่าง: base = hsb(h, mist 0.38 / paper 0.26, mist 0.155 / paper 0.135) |
| `rawAccent` | คู่สี: สีอ่อนของคู่ · สีเดียว: hsb(h, clamp(s+0.1, 0.35…0.72), 0.96) |
| `accent` | คู่สี: หมึกคู่ · สว่าง: `onLightSurface(rawAccent)` (theme.js:52) · มืด: rawAccent |
| `slab` (แผ่น dim) | duoDark ?? hsb(h, 0.30, 0.10) |
| `plate` / `plateCream` (พื้น `dark` §4) | duoDark ?? hsb(h, 0.60, 0.255) · duoLight ?? hsb(h, 0.085, 0.95) |
| `radius` | 20 (มุมมนทุกใบ — `corner` ถอดจาก doc แล้ว) |

`InkStyle` (theme.js:92-109 · ต้นแบบ `Theme/Legibility.swift`): `text(a)` = หมึกที่ความทึบ max(ที่ออกแบบ, ที่อ่านออกตาม WCAG บนพื้น) · `ghost(a)` = ×0.5 เมื่อสว่าง · `line(a)` · `fill(a)` · `lift` = ดำ 18% เฉพาะหมึกสว่าง · `liftRadius` 14 · ฟังก์ชัน `Legibility.alpha/target/composite` อยู่ที่ theme.js:62-79 — ย้ายมาเป็น static func ได้ตรง ๆ

### 3.3 `StarCardPalette.swift` — token → UIColor (port `Views/Widgets/Primitives/SpecPalette.swift` 108 บรรทัด เปลี่ยน `Color` → `UIColor`)

กติกาที่ต้องครบ: `@a` ท้าย token · `explicit on` ชนะ `widget.on` · **noSheet** (`surface == clear/pane` หรือ `options.fill == clear`) → โหนดที่ไม่ระบุ `on` ใช้สี `card` · พื้น `card` วิ่งผ่าน `InkStyle` (ink/ink2/line/bg2 ตั้งต้น 1 / 0.5 / 0.12 / 0.14) · พื้น `light`: paper = คู่สี ? สีอ่อน (+7% เข้าหาสีเข้มเมื่อการ์ดสว่าง) : hsb(h, 0.10, 0.97) · ink = คู่สี ? สีเข้ม : hsb(h, 0.06, 0.11) · พื้น `dark`: paper = `plate` · ink = `plateCream` · accent = rawAccent · `bg2 = paper.mix(ink, 0.06)` · `ink2 = ink.mix(paper, 0.38)` · `line = ink@0.2`

### 3.4 `StarCardRenderContext.swift` — implement `SpecRenderContext`

ตัวอย่างของต้นแบบ: `AppRenderContext` ใน `Views/Export/RenderABExport.swift:125-297` (ส่วน SwiftUI คือไอคอน — ข้อ 5)

```swift
final class StarCardRenderContext: SpecRenderContext {
    let palette: StarCardPalette            // 3.3 — สร้างครั้งเดียวต่อชิ้น
    let measurer: StarCardMeasurer          // 3.5
    let item: StarCardDoc.Item
    let handle: String                      // QR ชี้ไป https://salehere.co.th/star/<handle>

    func color(_ token: String, on: String?, item: SpecItem?) -> UIColor {
        // `$field` ของรายการ (`$tint@0.3`) แทนค่าก่อน แล้วค่อยถาม palette
        var t = token
        if t.hasPrefix("$"), let item {
            var name = String(t.dropFirst()), alpha = ""
            if let at = name.firstIndex(of: "@") { alpha = String(name[at...]); name = String(name[..<at]) }
            t = item.value(name) + alpha
        }
        return palette.color(t, on: on)
    }
    func font(_ f: SpecFont) -> UIFont { measurer.uiFont(f) }
    func lineHeight(_ f: SpecFont) -> CGFloat { measurer.lineHeight(f) }
    func photo(slot: Int) -> SpecRenderPhoto? { nil }            // รอบ mock: 4 ใบนี้ไม่มีช่องรูป · ของจริง = doc.photos["<id>#<slot>"] → imageId → Kingfisher
    func asset(_ name: String) -> UIImage? { UIImage(named: name) }
    func remote(_ url: String) -> UIImage? { nil }                 // รอบ mock ไม่มี (โลโก้แบรนด์จากเน็ต) · ของจริง = แคช Kingfisher ที่โหลดไว้ก่อนวาด
    func icon(_ r: SpecIconRequest) -> UIView? { StarCardIcons.view(r, ctx: self) }   // ข้อ 5
    var platePattern: SpecPlatePattern { SpecPlatePattern(rawValue: item.options?["pattern"] ?? "") ?? .plain }
}
```

### 3.5 `StarCardData.swift` — `SpecMeasurer` + `SpecDataSource` (รอบแรก mock)

**ตัววัด**: ก๊อป `IOSSpecMeasurer` (ท้าย `Views/Widgets/SpecPainter.swift:439-507`) มาได้ทั้งก้อน — เป็น UIKit อยู่แล้ว เปลี่ยนแค่ `CardFont(...).uiFont` เป็นตารางนี้:

```swift
// face "noto" (ทุกผัง) → NotoSansThai · weight 100–900 → ชื่อไฟล์ (= SHFont.name ของต้นแบบ · ตรงกับ UIFont.saleHereText* ของแอป)
static func fontName(weight w: Int) -> String {
    switch w {
    case ..<400: return "NotoSansThai-Light"
    case ..<500: return "NotoSansThai-Regular"
    case ..<600: return "NotoSansThai-Medium"
    case ..<700: return "NotoSansThai-SemiBold"
    case ..<800: return "NotoSansThai-Bold"
    case ..<900: return "NotoSansThai-ExtraBold"
    default:     return "NotoSansThai-Black"
    }
}
```

กติกาวัดที่ห้ามเปลี่ยน (อยู่ในโค้ดที่ก๊อป): `boundingRect(.usesLineFragmentOrigin, .usesFontLeading)` · `lines = round(h / lineHeight)` · กว้างปัดขึ้น 2 ทศนิยม · `lineHeight` ปัด 2 ทศนิยม · `.kern`/`.tracking` จาก `SpecFont`

**แหล่งข้อมูล — รอบแรก = mock ตายตัว** (ไม่ต้อง port อะไร · ตอบแค่ที่ 4 ใบถาม · ของจริงค่อยเขียน `StarCardData` อ่าน `creatorProfile` ตามข้อ 7):

```swift
/// ค่าเดียวกับ `owner` ในการ์ด JSON ข้อ 1 — เขียนตายในโค้ดก่อน
struct MockStarCardData: SpecDataSource {
    let item: StarCardDoc.Item          // ธงของชิ้น (surface/border/options) อ่านจากตรงนี้
    let meta: WidgetSpec.Widget?        // บล็อก `widget` ของผัง (`on` · `stamp`)
    let inkLight = true                 // ธีม mock = คู่สี teal โทน mist → สว่าง

    func text(slot: String, preset: String?) -> String {
        switch slot {
        case "name": return "มณีรัตน์ ใจดี"
        case "nickname": return "เมย์"
        case "tagline": return "Fashion & Café Creator"
        case "handle": return "mae.review"
        case "count:socials": return "3"
        case "stat:totalFollowers": return "92K"          // 24,800 + 58,300 + 8,900 → Fmt.compact
        case "stat:cardURL": return "https://salehere.co.th/star/mae.review"
        default: return ""                                 // ว่าง = ผังซ่อนโหนดนั้นเอง
        }
    }

    func list(_ name: String) -> [SpecItem] {
        func I(_ id: String, _ i: Int, _ f: [String: String]) -> SpecItem { SpecItem(id: id, i: i, fields: f) }
        switch name {
        case "socials": return [
            I("instagram", 0, ["platform": "instagram", "name": "Instagram", "short": "IG", "icon": "sh:instagram", "tint": "#E85C9E", "handle": "mae.review", "followers": "24.8K", "followersRaw": "24800", "verified": "1"]),
            I("tiktok", 1, ["platform": "tiktok", "name": "TikTok", "short": "TikTok", "icon": "sh:tiktok", "tint": "#33F0EB", "handle": "mae.review", "followers": "58.3K", "followersRaw": "58300", "verified": "1"]),
            I("youtube", 2, ["platform": "youtube", "name": "YouTube", "short": "YouTube", "icon": "sh:youtube", "tint": "#FF524D", "handle": "maereview", "followers": "8.9K", "followersRaw": "8900", "verified": "1"]),
        ]
        case "rates": return [
            I("ig-reels", 0, ["label": "Reels", "price": "฿3,000", "priceRaw": "3000", "platform": "instagram", "platformName": "Instagram", "icon": "sh:instagram", "tint": "#E85C9E", "format": "shortVideo"]),
            I("ig-post", 1, ["label": "ภาพลงฟีด (1–3 ภาพ)", "price": "฿2,400", "priceRaw": "2400", "platform": "instagram", "platformName": "Instagram", "icon": "sh:instagram", "tint": "#E85C9E", "format": "photo"]),
            I("tt-short", 2, ["label": "คลิปสั้น (ไม่เกิน 60 วิ)", "price": "฿7,000", "priceRaw": "7000", "platform": "tiktok", "platformName": "TikTok", "icon": "sh:tiktok", "tint": "#33F0EB", "format": "shortVideo"]),
            I("yt-shorts", 3, ["label": "YouTube Shorts", "price": "฿1,100", "priceRaw": "1100", "platform": "youtube", "platformName": "YouTube", "icon": "sh:youtube", "tint": "#FF524D", "format": "shortVideo"]),
        ]
        case "categories": return ["แฟชั่น", "คาเฟ่", "ท่องเที่ยว"].enumerated().map { I("cat\($0.offset)", $0.offset, ["text": $0.element]) }
        default: return []
        }
    }

    func flag(_ name: String) -> Bool {
        let surface = item.surface ?? "glass"
        switch name {
        case "owner.verified": return true
        case "stamped": return meta?.stamp != nil          // statPoster (`stamp: followers`) ได้ป้าย Verified by Sale Here
        case "papered": return surface == "glass" || surface == "dim"
        case "bordered": return item.border ?? false
        case "ink.light": return inkLight
        case "duo": return true
        case "kit.dark": return meta?.on == "dark"
        case "sample", "cutout": return false
        default: break
        }
        if name.hasPrefix("surface=") { return surface == String(name.dropFirst(8)) }
        if name.hasPrefix("cfg:") || name.hasPrefix("opt:") {               // `cfg:fill=clear` · `opt:mode=fmt` · `opt:qr`
            let body = name.drop(while: { $0 != ":" }).dropFirst()
            if let eq = body.firstIndex(of: "=") { return (item.options?[String(body[..<eq])] ?? "") == String(body[body.index(after: eq)...]) }
            let v = item.options?[String(body)] ?? ""; return !v.isEmpty && v != "0"
        }
        if name.hasPrefix("hidden:") { return false }
        return false
    }

    func font(slot: String?, face: String, size: CGFloat, weight: Int) -> SpecFont {
        SpecFont(face: "noto", size: slot == nil ? size : min(max(size, 6), 160), weight: weight)
    }
}
```

เงื่อนไขอื่นในผัง (`$i<1` · `list:socials>3` · `!$i=first` …) ตัวคำนวณประเมินเองจากรายการที่คืน ไม่ต้องตอบ

ที่มาของธงด้านบน (ใช้เหมือนกันตอนทำของจริง): `papered = surface ∈ {glass, dim}` · `bordered = border` · `surface=<x>` · `cfg:fill`/`cfg:corner` = `options["fill"]`/`options["corner"]` · `opt:<k>=<v>` = `options[k]` · `ink.light = theme.isLight` · `duo = มี secondary` · `kit.dark = widget.on == "dark"` · `stamped = widget.stamp != nil && ข้อมูลหมวดนั้นมาจาก Sale Here` (รอบ mock: `stamp == "followers"` และ socials ทุกช่อง `source != manual` → true) · `sample = false` เสมอในแอปจริง

(ไว้ตอนทำแหล่งข้อมูลจริง) ตารางค่าคงที่ที่ต้องเท่ากันทุกแพลตฟอร์ม (`data.js:46-70`): ชื่อ/ตัวย่อ/สีของช่องทาง (`instagram #E85C9E` `tiktok #33F0EB` `youtube #FF524D` `facebook #5C8FFA` `lemon8 #FFD640` `x #D9D9E0`) · ชื่อรูปแบบงานต่อช่องทาง (`FORMATS`) · `Fmt.compact` (≥1e6 → M · ≥1e3 → K · <100 ทศนิยม 1 ตำแหน่ง half-up) · `Fmt.thousands` คอมม่า

### 3.6 `StarCardPageView.swift` — ประกอบหน้า

```swift
// หน้าในหน่วยออกแบบ: story 540×960 · portfolio กว้าง 402 สูง = จอ×402/กว้างจอ · วาดที่ขนาดจริงแล้ว transform ด้วย fit = min(จอ/540, สูงที่มี/960)
let page = CGSize(width: 540, height: 960)
let canvas = UIView(frame: CGRect(origin: .zero, size: page))
canvas.layer.cornerRadius = 28; canvas.clipsToBounds = true
// พื้นการ์ด: solid = สีเดียว · gradient = CAGradientLayer top→bottom (3.2)
for item in page.items {
    guard let spec = SpecCatalog.spec(named: item.kind) else { continue }       // kind ที่ไม่รู้จัก = ข้าม
    let meta = spec.widget
    var frame = CGRect(x: item.x, y: item.y, width: item.w, height: item.h)
    // ตราที่ตรึง (`widget.pinned`): y คิดจากก้นหน้าเสมอ ไม่เชื่อค่าในไฟล์ (= PageLayout.pinnedFrame · page.js:16)
    if meta?.pinned == true { frame.origin.y = page.height - 18 - frame.height }
    canvas.addSubview(renderWidget(item, spec: spec, frame: frame))             // ข้อ 4 · ชิ้น pinned addSubview ท้ายสุด (อยู่บนสุด)
}
```

รอบ mock ไม่ต้องทำ: การดันชิ้นที่ทับกัน (`solvePage` ใน page.js — การ์ดที่แอปเซฟมาไม่ทับกันอยู่แล้ว) · แอนิเมชันเข้า · แก้/ลาก · หน้า portfolio 3 หน้า

### 3.7 Service · Scene · Router

ทำตามแบบ `CampaignPayout` (มี Mock/Live สลับที่ Configurator — `Scene/CampaignPayoutPage/CampaignPayoutConfigurator.swift:17-46`):

```swift
protocol StarCardServicing { func fetchCard() async throws -> StarCardDoc }

/// รอบนี้: JSON ของข้อ 1 ที่ฝังในแอป — ไม่เรียกเน็ต (ไฟล์ StarCardMock.json ใน bundle หรือ string literal)
final class StarCardMockService: StarCardServicing {
    func fetchCard() async throws -> StarCardDoc {
        let url = Bundle.main.url(forResource: "StarCardMock", withExtension: "json")!
        return try JSONDecoder().decode(StarCardDoc.self, from: Data(contentsOf: url))
    }
}
/// รอทีม API: GraphAPI.StarCardQuery ผ่าน APIManager.shared.fetch(query:) (Resources/API/APIManager.swift:59) — doc เป็น JSON String (gateway ไม่มี scalar JSON) → decode ด้วย StarCardDoc ตัวเดิม
final class StarCardLiveService: StarCardServicing { … }
```

- Scene ใหม่ `Scene/StarCard/` (VC + Router + Configurator ตามแบบ `StarProfilePageConfigurator.createModule` · เปิดด้วย `TransitionSlideDelegate` + `presentFullScreen`) — หน้าเดียว: ปุ่มกลับ · `StarCardPageView` กลางจอ · โหลดอยู่/ล้มเหลว
- **ปุ่มที่ต้องต่อ**: `StarCardSectionView` (`Scene/StarProfile/StarProfileKit/StarGlassCard.swift:175-205`) → `routeToStarCard()` (`StarProfilePageViewController.swift:127`) → `StarProfilePageRouter.navigateToStarCardOld()` (`StarProfilePageRouter.swift:39-45` เปิด `CreatorProfileStarCardConfigurator` หน้าเก่า) → **เปลี่ยนให้เปิด Scene ใหม่** ด้วย `StarCardMockService` · ปุ่ม "เปิดใช้งานการ์ด" ยังไม่มีในแอป (มีแค่ key `STAR_CARD_OPEN` = "ดูการ์ดของฉัน") — ถ้าจะมี ให้เรียก Router เดิมตัวเดียวกัน
- โหลดผัง: ใช้ที่ฝังใน bundle (`SpecCatalog` อ่านเอง) · วันที่ API ส่งผังมา ใช้ `SpecCatalog.replace(with: [Data])` (มีอยู่แล้วใน WidgetSpec.swift:553) ก่อนวาด

## 4. ลำดับวาดต่อใบ (= `Render/README.md` · `RenderABExport.renderUIKit`)

```swift
func renderWidget(_ item: StarCardDoc.Item, spec: WidgetSpec, frame: CGRect) -> UIView {
    let meta = spec.widget
    let traits = SpecChromeTraits(drawsOwnSurface: meta?.ownSurface ?? false, drawsOwnBorder: meta?.ownBorder ?? false,
                                  isFullBleed: meta?.fullBleed ?? false, isTextLayer: false,
                                  verifiedTier: (meta?.tier ?? tierOf(meta?.category)) == "verified")   // CATEGORY_TIER ใน kinds.js:11 (brand/verified/seal = verified)
    let surface = SpecChromeSurface(rawValue: item.surface ?? "glass") ?? .glass
    let border = item.border ?? false

    let (s, layout) = SpecChrome.layout(frame: frame.size, design: spec.design.cg, isTextLayer: false)
    let inset = SpecChrome.contentInset(traits, surface: surface, border: border)
    let box = CGSize(width: layout.width - inset * 2, height: layout.height - inset * 2)

    let data = MockStarCardData(item: item, meta: meta)          // รอบแรก (3.5) · ของจริง = StarCardData จาก creatorProfile
    let solver = SpecSolver(spec: spec, box: box, data: data, measurer: measurer, renderScale: s)
    let boxes = solver.solve()
    let ctx = StarCardRenderContext(palette: StarCardPalette(theme: theme, item: item, base: meta?.on), …)
    let widget = SpecWidgetView(boxes: boxes, box: box, fitScale: solver.scale, context: ctx, pixelScale: UIScreen.main.scale * s)

    let style = chromeStyle(theme: theme, traits: traits, surface: surface)      // ด้านล่าง
    return SpecChromeView(frame: frame, design: spec.design.cg, traits: traits, surface: surface, border: border, style: style, content: widget)
}
```

`SpecChromeStyle` (ค่าที่วัดจาก Liquid Glass จริง 21 ต.ค. 2569 — เท่า `chrome.js:67-70` และ Android `GlassPanel.kt`) · **หมายเหตุ**: แอปต้นแบบใช้ `SpecChromeView` เฉพาะใน A/B ของ painter (ไม่เคยวาดเปลือกจริงในแอป) — เปลือกให้เทียบกับเว็บ `chrome.js` เป็นหลัก:

| ฟิลด์ | ค่า |
|---|---|
| `radius` | 20 |
| `veil` | หมึกสว่าง → ขาว 57.5% · หมึกมืด/คู่สี → ขาว 5.6% · `verifiedTier` บนหมึกมืด (ไม่ใช่คู่สี) → ดำ 70% |
| `tint` | `verifiedTier` && ไม่ใช่คู่สี → `accent` ที่ 5% (มืด) / 2.5% (สว่าง) · ไม่งั้น nil |
| `slab` | `theme.slab` |
| `lift` · `liftRadius` · `liftY` | `inkStyle.lift` (ดำ 18% เมื่อสว่าง · ใส เมื่อมืด) · `inkStyle.liftRadius` (14 สว่าง / 0 มืด) · 6 (= เงา `0 6px` ของ chrome.js:71) |
| `line` | `inkStyle.line(0.12)` |

หมึกของเนื้อหา**ใต้แผ่นกระจก** ต่างจากหมึกบนการ์ด (`chromeInk` theme.js:451): glass/pane → `ink.covered(panel: คู่สี ? 0 : (สว่าง ? 1 : 0), alpha: คู่สี ? 0.16 : (สว่าง ? 0.58 : 0.16))` · dim → `InkStyle.night` บน `slab` · clear → หมึกการ์ดตรง ๆ — ส่ง `InkStyle` ตัวนี้ให้ `StarCardPalette` ของชิ้นที่ `framed`

## 5. ไอคอนที่ 4 ใบนี้ใช้ (ส่วนเดียวที่ต้องวาดใหม่ — ต้นแบบวาดด้วย SwiftUI)

`icon(_ r: SpecIconRequest) -> UIView?` คืน `nil` = ไม่วาดไอคอนนั้น **ใบที่เหลือยังวาดครบ** — ทำทีละตัวได้

| ชื่อในผัง | ใช้ที่ | มีใน salehere-ios? | ทำยังไง |
|---|---|---|---|
| `ph:check` | heroMinimal (ติ๊ก verified ข้างชื่อ) | ✓ asset `ph-check` (มี `ph-*` 30 ตัว) + `PhosphorSwift` (SPM) | `UIImage(named: "ph-" + ชื่อ)` ก่อน · ไม่มีก็ `UIHostingController` ครอบ `Ph` (ชื่อ kebab-case = `Ph.rawValue` · ต่อท้าย `-fill` = weight fill) |
| `$icon` → `sh:instagram` `sh:tiktok` `sh:youtube` | statPoster (โลโก้ช่อง) | ✓ `about-social-instagram/tiktok/youtube` imageset | `UIImageView(UIImage(named: "about-social-" + ชื่อ))` · มี `tint` → `.withRenderingMode(.alwaysTemplate)` · ตาราง `sh:` → asset = `SHIcon` ใน `Theme/Typography.swift:41-56` |
| `sh:wordmark` | proofSeal | ✓ `ic-salehere-text` | เหมือนบน |
| `byline` | statPoster (ป้าย "Verified by Sale Here" ตัวอักษร = สูง×0.45) | — | `SaleHereByline` `Theme/SaleHereMarks.swift:483` · เว็บ `spec-icons.js:101` (`byline`) — UILabel + รูปตราเล็ก |
| `starLockup` | heroMinimal · proofSeal (โลโก้ ST★R สี `tint ?? accent`) | — | `StarLockup` `Theme/Signature.swift:570` (ตัว ★ เป็น vector `StarCaps`) · salehere-ios มี `StarCaps` อยู่แล้ว (`StarProfileKit/StarWordmark.swift:181`) — ครอบด้วย `UIHostingController` ได้เลย |
| `verifiedSeal` | proofSeal (ตรากลีบหยัก + เครื่องหมายถูก) | — | `VerifiedSeal` `Views/Widgets/Primitives/VerifiedSeal.swift:110` · เว็บ `spec-icons.js:52-76` (`sealPath` `checkPath` `verifiedSeal`) — CAShapeLayer 2 ชั้น |
| `guilloche` | proofSeal (ลายกิโยเช่ สี `tint ?? ink@0.2`) | — | `Guilloche` `VerifiedSeal.swift:216` · เว็บ `spec-icons.js` — วง/เส้นโค้ง CAShapeLayer |
| `ringText` | proofSeal (ข้อความวนรอบวง · `r.text` `r.pointSize`) | — | `RingText` `VerifiedSeal.swift:192` — CoreText วางทีละตัวอักษรบนวง รัศมี `min(w,h)/2 − size` |

วิธีเร็วสุดสำหรับรอบ mock: ไอคอน SwiftUI 5 ตัวสุดท้ายห่อด้วย `UIHostingController(rootView:).view` ขนาด `r.size` (ต้นแบบก็ทำแบบนี้ผ่าน `ImageRenderer` — `RenderABExport.swift:195-222`) แล้วค่อยเขียน CoreAnimation ทีหลัง · ชุดเต็ม 20+ ชื่ออยู่ใน WIDGET-SPEC §6

## 6. เช็กว่าถูก

ตัวเลขที่ `SpecChrome.layout/contentInset` ต้องให้ กับการ์ดใบ mock (คิดจากสูตร §2 · ใช้ assert ได้):

| ใบ | design | กรอบ W×H | `s` | `inset` | `box` | พื้น (`widget.on`) |
|---|---|---|---|---|---|---|
| heroMinimal | 366×135 | 504×186 | 1.3770 | 12 (กระจก+ขอบ) | 342.00 × 111.07 | card |
| statPoster | 366×214 | 504×295 | 1.3770 | 0 (`ownSurface`) | 366.00 × 214.23 | dark |
| kitRatePurple | 300×290 | 246×238 | 0.8200 | 0 (`ownSurface` + `ownBorder`) | 300.00 × 290.24 | light |
| proofSeal | 366×232 | 246×156 | 0.6721 | 0 (`ownSurface` · `pinned` → y = 960−18−156 = 786) | 366.00 × 232.10 | dark |

หน้าตาที่ควรเห็น: การ์ดพื้นพีช `#F7CBA7` หมึกเขียวเข้ม `#0E3B3E` · heroMinimal = กระจกขาว 57.5% มีขอบ ชื่อ "มณีรัตน์ ใจดี" + ติ๊ก + "Fashion & Café Creator" · statPoster = แผ่นเขียวเข้ม (คู่สี → `plate` = สีเข้ม) หัว "MY Social / MEDIA STATS" 3 แถวช่องทาง 24.8K · 58.3K · 8.9K + ป้าย byline · kitRatePurple = กระดาษสีอ่อน หัว "เรทรับงาน" 4 แถวราคา `฿3,000` … · proofSeal = ตราเขียวเข้มมุมขวาล่าง

ลำดับเช็ก: (1) decode JSON ข้อ 1 ผ่าน (2) `SpecCatalog.spec(named:)` เจอทั้ง 4 (3) assert ตารางบน (4) `solver.solve()` ให้กล่องรากเท่า `box` และข้อความไม่ว่าง (5) ภาพ — เทียบกับภาพของต้นแบบ: เปิดแอปต้นแบบด้วย `-exportRenderAB -exportPerson` แล้ว `present/render-ab/run.sh <udid>` (วิธีใน `Render/README.md`) หรือดูเว็บ `http://localhost:8787/card/dev/gallery.html` (ต้องรัน `node sync-server/server.mjs`) · ที่ยอมให้ต่าง: ขอบตัวอักษร anti-alias · kernel เงา ±2% · การย่อรูป (WIDGET-SPEC §6)

## 7. หลัง mock ผ่าน → ของจริง

1. **GraphQL**: เพิ่ม `starCard` query + `saveStarCard` mutation ตาม SDL ร่างใน `sync-server/graphql.mjs:10-118` (doc เป็น JSON String เพราะ gateway ไม่มี scalar JSON · ตาราง/โมเดลฝั่ง user-service ใน `api/star-card/` · แผนใน `starcard-backend-plan`) → เขียน `StarCardLiveService` · operation ใน `Resources/API/Query/StarCard.graphql` · codegen รอบ Debug build ทำให้เอง
2. **ข้อมูลเจ้าของ**: เขียน `StarCardData` จริงแทน `MockStarCardData` — อ่าน `StarProfileSnapshot`/`creatorProfile` ของแอป (ต้นแบบ `IOSSpecData` ที่ `SpecPainter.swift:509-738` · เว็บ `data.js` เป็นแบบ) (ฟิลด์ API ↔ ช่องของผังอยู่ใน `PORT-SALEHERE-IOS.md` ตาราง) · `owner.verified` = KYC approved · `stamped` = ข้อมูลหมวดนั้นมาจาก OAuth/API ไม่ใช่กรอกเอง
3. **รูป**: `doc.photos["<id>#<slot>"] = { imageId, fit {dx dy zoom} }` → URL จาก image-service → โหลดด้วย Kingfisher ให้ครบก่อนวาด แล้ว `photo(slot:)` คืน `SpecRenderPhoto(image, dx, dy, zoom)`
4. **ผังจาก API**: `widgetSpecs` + `widgetSpecsVersion` → `SpecCatalog.replace(with:)` เมื่อเวอร์ชันเปลี่ยน (ต้นแบบทำแล้วใน `Model/LabSync.swift`) · ผังที่อ่านไม่ผ่านถูกข้าม ไม่ล้ม
5. **ที่ยังไม่ครอบคลุม**: หน้า portfolio 3 หน้า (สูงตามจอ) · `textBlock` (ชั้นข้อความ — ตัวเดียวที่ไม่ใช่ผัง · วาด UILabel ตาม `chrome.js:145-155`) · พื้นหลังรูป (`backdrop: photo`) · โหมดแต่ง (ลาก/ยืด/ถาด) · แชร์เป็นรูป (`UIGraphicsImageRenderer` ที่ 2× ให้ 1080×1920 พอดี)
