# Star Card · แก้ widget 3 พ.ย. 2569 · งานฝั่ง salehere-android

ที่มา: commit `fe91f93` (branch `widget-guide-nov3`) ใน salehere-starcard · แก้ JSON 25 ตัว ลบ 6 ตัว ตาม "Star Card Widget Guide สำหรับ Dev"

ไฟล์ทั้งหมดอยู่ใต้ `app/src/main/java/com/salehere/android/app/`

## สรุปงาน

| # | งาน | ไฟล์ |
|---|---|---|
| 1 | เพิ่มลิ้นชักรายการ `rateSocials` | `compose/component/starcardkit/model/spec/StarCardKitSpecList.kt`, `.../model/layout/StarCardKitSpecField.kt`, `.../model/spec/StarCardKitSpecData.kt` |
| 2 | เรียงช่องทางตามลำดับฟอร์ม IG › TikTok › FB › YouTube › Lemon8 › X | `models/starcard/creator/StarCardSocialType.kt`, `models/starcard/owner/StarCardProfile.kt` |
| 3 | เช็คว่าการ์ดที่มี widget ที่ถูกลบยังเปิดได้ | `compose/component/starcardkit/widget/StarCardKitWidgetShared.kt` |

ส่วนอื่นของ JSON ที่แก้ใช้คำที่ `StarCardKitSpecSolver` รู้จักอยู่แล้ว ไม่ต้องแก้ตัวคำนวณ

## 1. เพิ่มลิ้นชัก `rateSocials`

widget ที่ใช้: `kitRateCream`, `kitRateGingham`, `kitRateMac`, `kitRateNight`, `kitRatePurple`, `rateTags`
ถ้าไม่มีลิ้นชักนี้ widget ทั้ง 6 ตัวจะวาดเป็นกล่องว่าง เพราะ `StarCardKitSpecList.from` ไม่รู้จักชื่อนี้

**1.1 ชื่อลิ้นชัก** · เพิ่มใน `StarCardKitSpecList`

```kotlin
RATE_SOCIALS("rateSocials"),
```

**1.2 ชื่อช่อง** · เพิ่มใน `StarCardKitSpecField` (`PHOTO("photo")` มีอยู่แล้ว ใช้ตัวเดิม)

```kotlin
SHORT_VIDEO("shortVideo"), SHORT_VIDEO_RAW("shortVideoRaw"),
PHOTO_RAW("photoRaw"),
LONG_VIDEO("longVideo"), LONG_VIDEO_RAW("longVideoRaw"),
SEEDING("seeding"), SEEDING_RAW("seedingRaw"),
```

**1.3 จัดข้อมูล** · เพิ่มเคสใน `StarCardKitSpecData.listItems` ต่อจาก `RATES`

- หนึ่งชิ้นต่อหนึ่งโซเชียล เฉพาะโซเชียลที่มีราคาอย่างน้อย 1 ประเภทที่มากกว่า 0
- เรียงตามลำดับช่องทางในข้อ 2
- ใช้ `shownRates` ที่มีอยู่แล้ว ค่า `format.raw` ตรงกับชื่อช่องในผังพอดี (`photo`, `shortVideo`, `longVideo`, `seeding`)

| ช่อง | ค่า | ตัวอย่าง |
|---|---|---|
| `platform` | raw ของช่องทาง | `instagram` |
| `platformName` | ชื่อเต็ม | `Instagram` |
| `platformOrder` | ตำแหน่งในลำดับข้อ 2 | `1` |
| `icon`, `tint` | เหมือน `RATES` | |
| `shortVideo`, `photo`, `longVideo`, `seeding` | `"฿" + numberDisplay(ราคาต่ำสุดของประเภทนั้น)` ไม่มีราคา = ไม่ใส่ช่องนั้นเลย | `฿5,000` |
| `…Raw` | ตัวเลขดิบ | `5000` |

`id` ของชิ้น = `platform.raw` · `i` = ลำดับหลังเรียง

```kotlin
StarCardKitSpecList.RATE_SOCIALS -> {
    val priced = shownRates.filter { it.price > 0 }
    StarCardSocialType.entries.filter { t -> priced.any { it.platform == t } }.mapIndexed { i, t ->
        val f = mutableMapOf(
            StarCardKitSpecField.PLATFORM.raw to t.raw, StarCardKitSpecField.PLATFORM_NAME.raw to t.name,
            StarCardKitSpecField.ICON.raw to t.specIcon, StarCardKitSpecField.TINT.raw to t.tintHex,
            StarCardKitSpecField.PLATFORM_ORDER.raw to StarCardSocialType.entries.indexOf(t).toString(),
        )
        listOf(
            StarCardContentFormat.ShortVideo to (StarCardKitSpecField.SHORT_VIDEO to StarCardKitSpecField.SHORT_VIDEO_RAW),
            StarCardContentFormat.Photo to (StarCardKitSpecField.PHOTO to StarCardKitSpecField.PHOTO_RAW),
            StarCardContentFormat.LongVideo to (StarCardKitSpecField.LONG_VIDEO to StarCardKitSpecField.LONG_VIDEO_RAW),
            StarCardContentFormat.Seeding to (StarCardKitSpecField.SEEDING to StarCardKitSpecField.SEEDING_RAW),
        ).forEach { (fmt, keys) ->
            priced.filter { it.platform == t && it.format == fmt }.minOfOrNull { it.price }?.let { low ->
                f[keys.first.raw] = "฿" + low.numberDisplay(); f[keys.second.raw] = low.toString()
            }
        }
        StarCardKitSpecItem(t.raw, i, f)
    }
}
```

ต้นแบบที่ทำเสร็จแล้ว: `salehere-starcard/StarCardAndroid/app/src/main/kotlin/co/salehere/starcard/model/SpecData.kt` (`"rateSocials"`)

## 2. ลำดับช่องทาง = ลำดับฟอร์ม

ทุก widget รวม widget ราคา เรียงช่องทางตามลำดับฟอร์ม Star Profile: **Instagram › TikTok › Facebook › YouTube › Lemon8 › X**
ลำดับนี้คือ `StarCardSocialType.formOrder` ที่มีอยู่แล้ว (`models/starcard/owner/StarCardSocialTypeIntakeExtensions.kt`)

ตอนนี้ `StarCardSocialType.entries` เรียง IG › TikTok › YouTube › FB › Lemon8 › X คือสลับ YouTube กับ Facebook

- ลิ้นชัก `socials` เรียงตาม `formOrder` อยู่แล้ว (`StarCardProfile.kt` บรรทัดราว 385) ไม่ต้องแก้
- `rates` (`platformOrder`), `rateSocials` และรายการ `ratePlatforms` ในถาด (`StarCardEditorState.kt` บรรทัดราว 1446) ตอนนี้อ่านจาก `entries` ให้เปลี่ยนไปเรียงตาม `formOrder`
- ทางที่ง่ายที่สุดคือเปลี่ยน `entries` เป็น `listOf(Instagram, TikTok, Facebook, YouTube, Lemon8, X)` ให้ตรงกับ `formOrder`
- ถ้าเปลี่ยน `entries` ให้เช็คที่ใช้ `ordinal` ด้วย เช่น `SocialInsightFormUiModel.kt` ที่เรียงด้วย `ordinal` และเช็คว่าไม่มีที่ไหนเก็บค่านี้ลงดิสก์หรือส่งขึ้น API

## 3. widget ที่ถูกลบ

ลบแล้ว: `aboutNote`, `contactBar`, `proofBrandGrid`, `proofBrandRail`, `proofBrandCoins`, `typeMarquee`

ทีมตกลงให้หลังบ้านลบ JSON ของ 6 ตัวนี้ทิ้ง และเอาออกจากถาดกับเทมเพลต การ์ดเก่าที่มีชิ้นเหล่านี้จะเหลือช่องว่างตรงนั้น

- เช็คว่าเมื่อ `StarCardKitSpecCatalog.spec(kind)` คืน null แอปข้ามชิ้นนั้น ไม่ crash ทั้งหน้าดูและหน้าแต่ง
- ถ้า `kind` ของชิ้นเป็น enum ในแอป ให้เช็คว่าอ่านการ์ดที่มีชื่อ kind ที่ไม่รู้จักได้
- ผังที่ cache ในเครื่อง (`StarCardWidgetSchemaStorage`) ยังวาดได้จนกว่าจะล้าง ไม่ต้องจัดการ

## การปล่อย

ทีมตกลงอัป JSON ทั้งหมดพร้อมกัน แอปเวอร์ชันเก่าที่ยังไม่มีข้อ 1 จะเห็นกล่องราคาว่างจนกว่าผู้ใช้จะอัปเดต

## เช็คผล

เทียบกับรูปจากต้นแบบใน `salehere-starcard/present/spec-fixtures/cells/cell-<kind>-design.png`
(รูปในต้นแบบยังเรียงช่องทางแบบเดิม เพราะลำดับข้อ 2 เป็นงานใหม่)
ถ้าใช้ `StarCardKitReplayData` ให้ดึง fixture ชุดใหม่จาก `salehere-starcard/present/spec-fixtures/fixtures/` มาแทนของเดิม

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
