# Star Card · แก้ widget 3 พ.ย. 2569 · งานฝั่ง salehere-ios

ที่มา: commit `fe91f93` (branch `widget-guide-nov3`) ใน salehere-starcard · แก้ JSON 25 ตัว ลบ 6 ตัว ตาม "Star Card Widget Guide สำหรับ Dev"

## สรุปงาน

| # | งาน | ไฟล์ |
|---|---|---|
| 1 | เพิ่มลิ้นชักรายการ `rateSocials` | `Scene/StarCard/StarCardData.swift` |
| 2 | เรียงช่องทางตามลำดับฟอร์ม IG › TikTok › FB › YouTube › Lemon8 › X | `StarCardData.swift`, `StarCardPieceTray.swift` |
| 3 | เช็คว่าการ์ดที่มี widget ที่ถูกลบยังเปิดได้ | `StarCardService.swift` (`StarCardSpecStore`) |

ส่วนอื่นของ JSON ที่แก้ใช้คำที่ตัววาดใน `StarCardRender/` รู้จักอยู่แล้ว ไม่ต้องแก้ตัววาด

## 1. เพิ่มลิ้นชัก `rateSocials`

widget ที่ใช้: `kitRateCream`, `kitRateGingham`, `kitRateMac`, `kitRateNight`, `kitRatePurple`, `rateTags`
ถ้าไม่มีลิ้นชักนี้ widget ทั้ง 6 ตัวจะวาดเป็นกล่องว่าง

เพิ่มเคสใน `StarCardOwner.list(_:)` (บรรทัดราว 537) ต่อจาก `case "rates"`

- หนึ่งชิ้นต่อหนึ่งโซเชียล เฉพาะโซเชียลที่มีราคาอย่างน้อย 1 ประเภทที่มากกว่า 0
- เรียงตามลำดับช่องทางในข้อ 2
- ใช้ `rates` ที่มีอยู่แล้ว ค่า `generic` ของแต่ละราคาตรงกับชื่อช่องในผังพอดี (`photo`, `shortVideo`, `longVideo`, `seeding`)

| ช่อง | ค่า | ตัวอย่าง |
|---|---|---|
| `platform` | raw ของช่องทาง | `instagram` |
| `platformName` | ชื่อเต็ม | `Instagram` |
| `platformOrder` | ตำแหน่งในลำดับข้อ 2 | `1` |
| `icon`, `tint` | เหมือน `rates` | |
| `shortVideo`, `photo`, `longVideo`, `seeding` | `"฿" + thousands(ราคาต่ำสุดของประเภทนั้น)` ไม่มีราคา = ไม่ใส่ช่องนั้นเลย | `฿5,000` |
| `shortVideoRaw`, `photoRaw`, `longVideoRaw`, `seedingRaw` | ตัวเลขดิบ | `5000` |

`id` ของชิ้น = `platform` · `i` = ลำดับหลังเรียง

```swift
case "rateSocials":
    let priced = rates.filter { $0.price > 0 }
    return Platform.specOrder.filter { p in priced.contains { $0.platform == p } }.enumerated().map { i, p in
        var f: [String: String] = ["platform": p.rawValue, "platformName": p.name, "icon": p.icon, "tint": p.tint,
                                   "platformOrder": String(Platform.specOrder.firstIndex(of: p) ?? 99)]
        for fmt in ["shortVideo", "photo", "longVideo", "seeding"] {
            if let low = priced.filter({ $0.platform == p && $0.generic == fmt }).map(\.price).min() {
                f[fmt] = "฿" + Self.thousands(low); f[fmt + "Raw"] = String(low)
            }
        }
        return SpecItem(id: p.rawValue, i: i, fields: f)
    }
```

ต้นแบบที่ทำเสร็จแล้ว: `salehere-starcard/StarCard/StarCard/Views/Widgets/SpecPainter.swift` (`case "rateSocials"`)

## 2. ลำดับช่องทาง = ลำดับฟอร์ม

ทุก widget รวม widget ราคา เรียงช่องทางตามลำดับฟอร์ม Star Profile: **Instagram › TikTok › Facebook › YouTube › Lemon8 › X**
ลำดับนี้คือ `Platform.formOrder` ที่มีอยู่แล้ว

ตอนนี้ `Platform.specOrder` เรียง IG › TikTok › YouTube › FB › Lemon8 › X คือสลับ YouTube กับ Facebook

- เปลี่ยน `Platform.specOrder` ให้เท่ากับ `formOrder` หรือเปลี่ยนทุกที่ที่อ่าน `specOrder` ไปอ่าน `formOrder`
- เรียงลิ้นชัก `socials` ตามลำดับนี้ด้วย ตอนนี้ยังเรียงตามที่ API ส่งมา
- `rates` (`platformOrder`), `rateSocials` และรายการ `ratePlatforms` ในถาด (`StarCardPieceTray.swift` บรรทัดราว 146) อ่าน `specOrder` อยู่แล้ว เปลี่ยนค่าเดียวก็ตามกันหมด

## 3. widget ที่ถูกลบ

ลบแล้ว: `aboutNote`, `contactBar`, `proofBrandGrid`, `proofBrandRail`, `proofBrandCoins`, `typeMarquee`

ทีมตกลงให้หลังบ้านลบ JSON ของ 6 ตัวนี้ทิ้ง และเอาออกจากถาดกับเทมเพลต การ์ดเก่าที่มีชิ้นเหล่านี้จะเหลือช่องว่างตรงนั้น

- ไม่ต้องแก้โค้ด เพราะ `StarCardSpecStore` ข้ามชิ้นที่ไม่มีผังอยู่แล้ว
- เช็คว่าเปิดการ์ดเก่าแล้วไม่ crash ทั้งหน้าดูและหน้าแต่ง
- ผังที่ cache ในเครื่อง (`star_card_widget_schemas/`) ยังวาดได้จนกว่าจะล้าง ไม่ต้องจัดการ

## การปล่อย

ทีมตกลงอัป JSON ทั้งหมดพร้อมกัน แอปเวอร์ชันเก่าที่ยังไม่มีข้อ 1 จะเห็นกล่องราคาว่างจนกว่าผู้ใช้จะอัปเดต

## เช็คผล

เทียบกับรูปจากต้นแบบใน `salehere-starcard/present/spec-fixtures/cells/cell-<kind>-design.png`
(รูปในต้นแบบยังเรียงช่องทางแบบเดิม เพราะลำดับข้อ 2 เป็นงานใหม่)

JSON ที่แก้ 25 ตัว:
statGiant, socialTiles, socialChips, popStatsGlass, scrapKeyTab,
kitRateCream, kitRateGingham, kitRateMac, kitRateNight, kitRatePurple, rateTags,
popHeroPaper, popHeroGlass,
kitProfileCream, kitProfileGingham, kitProfileMac, kitProfileNight, kitProfilePurple,
proofSeal, scrapFeed, proofWork, proofTicket, wallPolaroid, portfolioWindow, scrapInfo

จุดที่ต้องลองเอง:
- โซเชียล 5–6 ช่อง: statGiant กับ socialTiles เปลี่ยนเป็นไอคอนบนตัวเลข ไม่มี "…"
- rateTags: เลือกช่องทางในถาดแล้วราคาเปลี่ยนตามช่องนั้น ยังไม่เลือก = ช่องแรกตามลำดับข้อ 2
- kitRate: ติ๊กซ่อนช่องในถาดแล้วบล็อกของช่องนั้นหาย
