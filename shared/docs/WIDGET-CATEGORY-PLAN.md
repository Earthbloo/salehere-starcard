# Widget = ข้อมูลล้วน · Renderer = เครื่องมือกลาง · 1 หมวด = 1 Model

> เอกสารส่งต่อให้ chat ใหม่ทำต่อ · 15 ต.ค. 2569 · **ทำแล้ว 15 ต.ค. 2569 (iOS · Android · เว็บ) — ดู "ผลที่ทำ" ท้ายไฟล์**
> repo `salehere-starcard`: prototype iOS `StarCard/` · Android `StarCardAndroid/` · เว็บดูการ์ด `sync-server/web/` · JSON ของ widget `shared/WidgetSpecs/` (82 ไฟล์)

## 0. สรุปงาน (อ่านก่อน)

**กติกาเหล็ก 4 ข้อ (ผู้ใช้สั่ง)**
0. **Renderer = ตัวกลาง standalone อ่าน JSON อย่างเดียว · UI ของ widget = JSON only** · ในโค้ดห้ามมี logic ของ widget ตัวใดตัวหนึ่งเด็ดขาด ไม่มีข้อยกเว้น (ข้อ 2.1)
1. **ห้ามกระทบ UI ที่ทำมาแล้ว**: หลังทำ ทุก widget ทุกขนาดทุกตัวเลือก วาดออกมา**เหมือนเดิมทุกจุด** รวมถึงตู้ widget (ลำดับ, หมวด), ถาด (แถวเท่าเดิม), สถานะล็อก, ป้าย Verified, ท่าเคลื่อนไหว
2. **ทุก platform ใช้ concept เดียวกัน**: iOS · Android · เว็บ มีโครงเดียวกัน (renderer กลาง + category + widget JSON) ชื่อ key เดียวกัน
3. **ผลลัพธ์ตรงกันทุก platform เหมือนเดิม**: parity เท่าก่อนเริ่ม (replay 81/81 · fixture เท่าเดิม)

งานนี้คือ **ย้ายที่อยู่ของ logic** (จากโค้ดที่ผูกชื่อ widget → JSON + ตาราง category) **ไม่ใช่ redesign** · อะไรที่จะทำให้หน้าตาเปลี่ยน = ห้ามทำในรอบนี้ ให้จดไว้ในข้อ 11 (backlog)

**สิ่งที่จะทำ**
1. **วิเคราะห์** (ข้อ 10): widget ทุกตัวอยู่หมวดเดียว · Model ของแต่ละหมวดครอบคลุมทุก field ที่ widget ในหมวดใช้จริง · field ไหน API ยังไม่มี → **ส่งรายงานให้ผู้ใช้ก่อนแก้อะไร**
2. **เขียน Model ของ 14 หมวด** (ข้อ 4) เป็นตารางเดียวกันทั้ง 3 platform
3. **เติม key นิสัยลง JSON** ทั้ง 82 ไฟล์ด้วยสคริปต์ จากค่าปัจจุบันในโค้ด (ข้อ 3) → ค่าเท่าเดิม 100%
4. **ให้ renderer / chrome / ถาด / ตู้ อ่าน key + หมวด** แทนชื่อ widget แล้วลบตารางชื่อ widget ทิ้ง ทั้ง 3 platform
5. **validator**: widget อ่าน field นอก Model ของหมวด = error
6. **ตรวจว่าไม่มีอะไรเปลี่ยน** (ข้อ 9)
7. **รายงาน** ตารางก่อน → หลัง

ข้อ 1 ทำก่อนแล้วหยุดรอผู้ใช้ · ข้อ 2–7 ทำหลังผู้ใช้ตอบข้อ 8

## 1. เป้าหมาย (คำของผู้ใช้)

- "Renderer ไม่รู้จัก widget และไม่มี logic ของ widget ตัวไหนเลย" ไม่งั้นไม่ dynamic
- "front ต้องเป็นเครื่องมือกลาง ๆ เท่านั้น แต่ fix เป็น Category ได้": หมวดบอกว่าต้องมีข้อมูลอะไร คำนวณยังไง แล้ว match กับ key ของ widget
- "การวาดต้อง dynamic": หน้าตาทั้งหมดมาจาก JSON
- "เกินหมวดได้ แต่แต่ละหมวดต้องมี Model ของมันเอง widget ในหมวดใช้ Model เดียวกัน มีขาดได้ ห้ามมีเกิน"
- "พอเป็น model เดียวในหมวด ตอน design มันจะง่ายกว่าเยอะ"
- "ห้ามมี Logic ของ widget แต่ละตัวโดยเฉพาะเด็ดขาด เพื่อความ dynamic"
- "Renderer ต้องเป็น standalone ตัวกลางไว้อ่าน json เท่านั้น UI ต้อง json only"

## 2. ภาพเป้าหมาย: 3 ชั้น

```
┌─ ชั้น 3 · widget (JSON · dynamic) ───────────────────────────────┐
│ หน้าตาทั้งหมด + "category" + นิสัยของชิ้น (surfaces, pattern, stamp …) │
│ เพิ่ม/แก้ได้ตลอด ไม่ต้อง build                                      │
└──────────────────────────┬───────────────────────────────────────┘
                           │ อ่านได้เฉพาะ field ใน Model ของหมวดตัวเอง (⊆)
┌─ ชั้น 2 · category (fix ในโค้ด · 14 หมวด) ─────────────────────────┐
│ Model (field ที่หมวดนี้มี · ข้ามส่วนของ API ได้) · แปลงข้อมูล API → ค่าพร้อมวาด │
│ ล็อกจนกรอกอะไร · ข้อความรอข้อมูล · ข้อมูลตัวอย่าง 1 ชุด                    │
└──────────────────────────┬───────────────────────────────────────┘
┌─ ชั้น 1 · renderer (เครื่องมือกลาง) ───────────────────────────────┐
│ SpecSolver + SpecPainter + WidgetChrome: รู้จักชนิดโหนด ไม่รู้จักชื่อ widget │
└──────────────────────────────────────────────────────────────────┘
```

**1 หมวด = 1 Model** หมายถึง:
- Model ของหมวด = รายการ field ชุดเดียว (หยิบจากส่วนไหนของ API ก็ได้ เช่น hero ยืม `socials.handle`)
- widget ทุกตัวในหมวดใช้ **⊆ Model** · โชว์ไม่ครบได้ · ใช้ field นอก Model ไม่ได้
- ข้อมูลตัวอย่าง (ตู้ widget · widget ที่ล็อก · พรีวิว) = **1 ชุดต่อหมวด** ทุกตัวในหมวดใช้ชุดเดียวกัน
- ผลที่ได้: ดีไซเนอร์ออกแบบ widget ใหม่จากรายการ field ของหมวดเดียว · "เปลี่ยนแบบ" ในหมวดแล้วข้อมูลไม่หาย

### 2.1 กติกาเด็ดขาด: Renderer standalone · UI = JSON only

**นิยาม**
- **Renderer** = กล่องดำที่รับ 4 อย่าง → คืนภาพ: (1) widget JSON (2) ข้อมูลตาม Model ของหมวด (3) ค่าของชิ้นในการ์ด (x y w h surface border pattern notes photos …) (4) ธีมการ์ด · ไม่รู้ว่าตัวเองกำลังวาด widget ชื่ออะไร
- **UI ของ widget** = ทุกอย่างที่เห็นในกรอบของชิ้น มาจากโหนดใน JSON เท่านั้น · โค้ดมีแค่ **primitive กลาง** ที่ widget ไหนก็เรียกใช้ได้ด้วยชื่อเดียวกัน

**ห้ามมีในโค้ด (ทุก platform · ทุกไฟล์ที่ไม่ใช่เทสต์/เครื่องมือ export)**

| ห้าม | ตัวอย่างที่มีอยู่ตอนนี้ (ต้องลบ) |
|---|---|
| เช็กชื่อ widget | `kind == .textBlock` · `case .statPoster` · `switch base` · `base == .proofSeal` |
| enum/รายการชื่อ widget | iOS `WidgetKind.Base` · Android `WidgetBase` · เว็บ `kinds.js` (`OWN` `STAMP` `OVERLAY` `FAMILY` `POP` `KIT`) |
| view/composable/ฟังก์ชันวาดต่อ widget | iOS `Views/Widgets/` ~30 ไฟล์ (`StatPosterWidget.swift` `ArtWidgets.swift` `KitWidgets.swift` `PopWidgets.swift` `ScrapbookWidgets.swift` `WindowWidgets.swift` `GinghamWidgets.swift` `VerifiedSealWidget.swift` `TextWidgets.swift` …) + `WidgetBody` switch · Android ตรวจ `TextWidgets.kt` `PopKit.kt` `ScrapbookKit.kt` `WidgetKit.kt` |
| ยืมนิสัยจาก widget อื่นด้วยชื่อ | key `like` + `donor()` · `popTwin` (หาแฝดด้วยชื่อ) |
| ตารางชื่อเก่า → ชื่อใหม่ในโค้ด | `WidgetKind.retired` (iOS/Android) → ย้ายเป็นข้อมูล เช่น `"widget": {"replaces": ["scrapReceipt"]}` |
| ข้อความ/ค่าต่อ widget ในโค้ด | `title` `symbol` `defaultSize` `kitTitle` `entranceStyle` `stampOverlay` `minSize(for:)` |
| ทำพิเศษตาม `id` ของโหนด | `id` ในผังมีไว้ให้ fixture อ้างเท่านั้น |

**มีได้ในโค้ด (เป็นของกลาง ไม่ผูก widget)**

| ของกลาง | ตัวอย่าง |
|---|---|
| ชนิดโหนด · shape · pattern · token สี · ธง `if` | `col` `text` `rect` · `scallop` · `gingham` · `plate` · `papered` |
| primitive ไอคอนที่มีชื่อ (widget ไหนก็ใช้ได้) | `starLockup` `starSeal` `verifiedSeal` `qr` `byline` `provenance` `guilloche` `ringText` `washi` `binderClip` `paperClip` `barcode` `bow` `spark` `windowDots` `embossedLockup` |
| พื้นผิว / chrome | glass dim clear pane · ระยะขอบ · เส้นขอบ |
| ตัวควบคุมในถาด | แถวพื้นหลัง · ลาย · แบบตรา · สไตล์ชุด · ช่องทาง (widget ไหนมีแถวไหน = key ใน JSON) |
| ตาราง category | Model · แปลงข้อมูล · ล็อก · ข้อความรอ · ข้อมูลตัวอย่าง |
| ชั้นข้อความ (textBlock เดิม) | ไม่ใช่ widget · ถ้ายังเป็น widget ต้องมี JSON เหมือนตัวอื่น |

**ตัวบังคับ**: สคริปต์ CI อ่านรายชื่อ `kind` ทั้งหมดจาก `shared/WidgetSpecs/*.json` (+ ชื่อเก่าใน `replaces`) แล้ว grep ในโค้ด 3 platform → ต้อง 0 · ห้ามมี key `like` · เทสต์ "widget ใหม่จาก JSON อย่างเดียว" (ไฟล์ทดสอบที่ใช้ทุก key) ต้องขึ้นตู้ วาด แก้ บันทึก ได้ครบโดยไม่แตะโค้ด

**ทางพิสูจน์ว่าทำถูก**: ลบไฟล์ JSON ของ widget ไหนก็ได้ → แอปยัง build ผ่าน และ widget นั้นหายจากตู้เฉย ๆ · เพิ่ม JSON ใหม่ → ขึ้นตู้ทันที

**เกณฑ์ว่าเสร็จ**: grep ชื่อ widget (`statPoster` `proofSeal` …) ในโค้ดทั้ง 3 platform = 0 (ยกเว้นเทสต์/fixture) · มีแค่ชื่อหมวด · และกติกาเหล็กข้อ 0 ผ่านครบ

## 3. สถานะตอนนี้ + นิสัยที่ต้องย้าย

| ส่วน | สถานะ |
|---|---|
| ตัวคำนวณ `SpecSolver` (iOS `Layout/SpecSolver.swift` · Android · `sync-server/web/js/spec-solver.js`) | ✅ ไม่รู้จัก widget (grep = 0) |
| ตัววาด `SpecPainter` | ✅ เกือบ: อ่าน `kind.popSkin` จุดเดียว (สี `pop.sheet`/`pop.shadow`) |
| นิสัยต่อ widget | ❌ iOS `Model/WidgetModel.swift` · `Model/KitModel.swift` · `Theme/SaleHereStamp.swift` · `Components/Motion.swift` · Android `model/WidgetModel.kt` · `SaleHereByline.kt` · เว็บ `sync-server/web/js/kinds.js` (`OWN` `STAMP` `OVERLAY` `FAMILY`) — **เขียนซ้ำ 3 ที่** |
| `WidgetChrome` · `CardScreen` · `Layout/CardLayout.swift` | ❌ เช็ก `.textBlock` / `.proofSeal` ตรง ๆ |
| `WidgetBody` (iOS `Views/Widgets/WidgetShared.swift:277`) | ❌ SwiftUI view เดิมต่อ widget (สำรองเมื่อไม่มี JSON · ใช้จริงแค่ `textBlock`) |
| ข้อมูล | ❌ เว็บ `data.js` เติม `MOCK` เมื่อ API ไม่มี (แอปก็เช่นกัน) — **รอบนี้ห้ามเปลี่ยนพฤติกรรมนี้** (เปลี่ยน = UI เปลี่ยน) |

### นิสัยที่ต้องย้ายออกจากโค้ด → key ใน JSON (บล็อก `widget`)

ค่าทุกตัว **ดึงด้วยสคริปต์จากโค้ดปัจจุบัน** ห้ามกรอกมือ · ค่าที่เหมือนกันทั้งหมวดยกไปเป็นค่าของหมวดได้ · widget ที่ปัจจุบันต่างจากเพื่อนในหมวด **ต้องใส่ key ทับใน JSON** เพื่อให้ผลเหมือนเดิม

| ในโค้ด (ชื่อ iOS) | คุมอะไร | key |
|---|---|---|
| `family` | หมวด | `category` (มีแล้ว) |
| `title` `symbol` `defaultSize` `aspect` | ชื่อในตู้ · ไอคอน · ขนาดตอนวาง | `title` `symbol` `size` (มีแล้วสำหรับชนิดจาก JSON) |
| ลำดับใน `Base.allCases` | ลำดับในตู้ | `order` |
| `group` | ส่วนของตู้ about/booking/work | หมวด (ตรวจว่าทั้งหมวดเท่ากัน · ไม่เท่า = override) |
| `tier` | personal/connected/verified | หมวด + override (`typeMarquee` ต่างจากเพื่อน) |
| `drawsOwnSurface` `drawsOwnPaper` | ใครวาดพื้น | `ownSurface` |
| `surfaceOptions` `defaultSurface` | ตัวเลือกพื้นหลัง (ตัวแรก = ตั้งต้น · `audiencePoster` เริ่ม clear) | `surfaces` |
| `defaultBorder` | ขอบตั้งต้น | `border` |
| `controls` `usesPhoto` | แถวในถาด | `controls` (ตัวเลือกทั้งหมด · ค่าที่ `options[opt]`) `photo` (`pattern` `tray` `emboss` `liftPhoto` ถอด 19 ต.ค. 2569) |
| `keepsDesignAspect` `isFullBleed` `canResize` | การยืด | `keepAspect` `fullBleed` `resize` |
| `isPop` `popRole` `popSkin` `isKit` `kitTitle` `isScrap` `scrapDesign` `isWindow` `isEditorial` | สำรับ/วัสดุ | `skin` · `kit.look` · `kitTitle` (`tray` ถอด 19 ต.ค. 2569 — ตัวเลือกทั้งหมดอยู่ที่ `controls`) |
| `stampFacts` | ป้าย Verified ชนิดไหน | `stamp` (ต่อ widget · ห้ามยกเป็นของหมวด เพราะ `scrapFeed` `scrapKeyTab` `typeMarquee` ไม่มีป้าย) |
| `stampOverlay` | ตำแหน่ง/โทนป้าย (6 widget) | `stampAt` |
| `entranceStyle` (`Components/Motion.swift`) | ท่าเข้า | `motion` |
| `minSize(for:)` | ขนาดเล็กสุด | `minSize` |
| `.proofSeal` (ชื่อตรง) | ตรึงก้นหน้า · ล็อกจน KYC | key `pinned` + กติกาของหมวด `seal` |
| `.textBlock` (ชื่อตรง) | ตัวหนังสือแบบ IG · ไม่มี JSON | **บังคับรอบนี้**: แยกเป็น "ชั้นข้อความ" ของการ์ด (ไม่ใช่ widget) โดยหน้าตา/การแก้/ไฟล์การ์ดเหมือนเดิมทุกอย่าง |
| `like` · `donor()` · `popTwin` · `retired` | ยืมนิสัย/หาแฝด/ชื่อเก่า ด้วยชื่อ widget | ลบ `like` (นิสัยมาจาก key ครบแล้ว) · แฝด = `"twin": "<kind>"` ใน JSON · ชื่อเก่า = `"replaces": [..]` |
| view เดิมต่อ widget (iOS ~30 ไฟล์ใน `Views/Widgets/`) | วาดเมื่อไม่มี JSON / ใช้ใน A-B | ลบทั้งหมด หลังตรวจว่าทุก kind มี JSON และผล A-B ตรง (เครื่องมือ `-exportSpecAB` ต้องย้ายไปเทียบกับภาพที่บันทึกไว้แทน) |

รายการนี้อาจยังไม่ครบ: ให้ grep `extension WidgetKind` · `switch base` · `base ==` · `kind ==` ทั้ง 3 platform แล้วเพิ่มให้ครบก่อนเริ่ม

## 4. Category = Model (สัญญาข้อมูล)

### 4.1 ฐาน: ทุกหมวดมี

| field | มาจาก |
|---|---|
| `name` `handle` | `owner.values` (handle ว่าง → ตัดจากลิงก์ช่องทาง) |
| ~~`note#N`~~ | ตัดแล้ว 19 ต.ค. 2569 — widget ไม่มีช่องพิมพ์ · หัวข้อ = `text` ตายตัวในผัง · ข้อความบน widget แตะ/ปรับขนาด/สีไม่ได้ |
| รูปช่อง (`photo: N`) | `photos["<id>#N"]` · ไม่มี → รูปเจ้าของ (ช่อง 1–3 รูปคน · ที่เหลือผลงาน) |
| ธง `owner.verified` `stamped` `cutout` | ยืนยันตัวตน · ได้ป้าย · รูปตัดพื้นแล้ว |

### 4.2 Model ของแต่ละหมวด

**ต้องมี** = ไม่มีแล้วหมวดล็อก (= กติกาล็อกปัจจุบัน `WidgetFamily.topic` ไม่เปลี่ยน) · **↗** = ยืมจากส่วนอื่นของ API (เป็นส่วนหนึ่งของ Model หมวดนี้)

| หมวด | Model (นอกจากฐาน) | ต้องมี (ล็อก) | คำนวณ/จัดรูป |
|---|---|---|---|
| **hero** | `nickname` `tagline` `workArea` · `categories{text}` `categories#N` · ↗`socials{handle}` | หมวดงาน | nickname ว่าง → คำแรกของชื่อ |
| **intro** | `about` `tagline` `nickname` `workArea` · ↗`categories{text}` `categories#N` | แนะนำตัว | — |
| **tags** | `categories{text}` `categories#N` | หมวดงาน | — |
| **followers** | `socials{platform name short icon tint handle followers followersFull followersRaw views viewsRaw engagement engagementRaw verified synced}` · `stat:totalFollowers` `count:socials` · ↗`tagline` | ช่องทาง | 24800→`24.8K`/`24,800` · รวม · เรียง IG→TikTok→YT→FB→Lemon8→X · สี/ไอคอนต่อแพลตฟอร์ม |
| **audience** | `gender{label share shareRaw tint}` `ages{label share shareRaw}` `places{name share shareRaw}` · `stat:reach` `reachDelta` `reachNew` `reachWindow` · `count:places` · ↗`socials{name}` | insight | 62→`62%` · `184K` · `+14.4%` |
| **brand** | `brands{name logo industry}` · `stat:brandCount` | งานผ่าน Sale Here ≥1 | นับ |
| **verified** | `works{brand brandLogo campaign ep platform icon tint format cover workPhoto views viewsRaw saves shares likes comments engagement viralTag}` · `stat:workCount` | งานผ่าน Sale Here ≥1 | วิว K/M · % · โลโก้จาก brands |
| **rate** | `rates{label price priceRaw priceNum unit platform platformName icon tint format}` · `rateLabels#N` `ratePrices#N` · `stat:rateCount` | เรต | `฿3,000` · label ว่าง → "IG Reel" · กรองราคา > 0 |
| **contact** | `phone` `email` `lineId` `website` · `contacts{kind value icon slot}` · `stat:phoneFmt` `stat:site` `stat:lineFlow` | — | `089-123-4567` · contacts เฉพาะที่มีค่า |
| **availability** | `avail{text}` `areas{text}` · `workArea` | วันเวลา | areas = จังหวัด |
| **body** | `body{kind label value num unit wide}` | สัดส่วน | หน่วยต่อ field |
| **photo** | ↗`works` (`works.icon`) | — | — |
| **showcase** | (ฐาน) | — | — |
| **seal** | ↗`count:socials` | ยืนยันตัวตน (KYC) | — |

ชื่อ field ตรงกับ `StarCard/WIDGET-SPEC.md` §3.2 / §3.3b · Model ตารางนี้ = **ผลรวมของที่ widget ใช้จริงวันนี้** จึงไม่มี widget ไหนต้องแก้ JSON เพื่อให้เข้า Model

### 4.3 ข้อมูลดิบจาก API → ค่าที่ widget เห็น

ที่มา = `owner` ในการ์ด JSON (GraphQL `starCard { owner }`): `values` (ข้อความ) · `list` (ชิป) · `intake` (ฟอร์ม Star Profile) · `*ImageIds` (รูป) · โค้ดแปลงจริง: `sync-server/web/js/data.js` (= port ของ `AndroidSpecData`) · **❗ = API ยังไม่มี ตอนนี้ใช้ `MOCK`**

| หมวด | API ดิบ | → key ที่ widget ใช้ |
|---|---|---|
| ฐาน | `values.name` · `intake.socials[].link` · `photos` · `creatorImageIds` `workImageIds` | `name` · `handle` · รูปช่อง · `owner.verified` (ทุกช่องทาง `source ≠ manual`) |
| hero / intro | `values.{nickname tagline about}` · `intake.availability.provinces[0]` · `intake.interests[]` | `nickname` `tagline` `about` `workArea` `categories` |
| tags | `intake.interests[]` (หรือ `list.categories`) | `categories` |
| followers | `intake.socials[] {type link followers enabled source}` · ❗ วิว · ❗ engagement · ❗ เวลาซิงก์ | `socials[]` · `stat:totalFollowers` |
| audience | ❗ ทั้งก้อน `{female male other ages[] places[] reach{}}` | `gender` `ages` `places` `stat:reach…` |
| brand / verified | ❗ `track.brands[]` · ❗ `track.works[]` | `brands` · `works` |
| rate | `intake.rates[] {platform formatKey price label?}` | `rates[]` |
| contact | `values.{phone email lineId}` · ❗ เว็บไซต์ | `contacts` · `stat:phoneFmt` |
| availability | `intake.availability {days slots provinces}` | `areas` · ❗ `avail` ยังไม่แปลงจาก days/slots |
| body | ❗ สัดส่วน | `body[]` |
| seal | `intake.status` (KYC) | ล็อก/ปลด |

## 5. widget แต่ละตัวใช้อะไร (สกัดจาก JSON ทั้ง 82 ไฟล์)

สร้างด้วย `node shared/docs/widget-data-usage.cjs /tmp/usage.json` แล้ว `node shared/docs/widget-category-models.cjs /tmp/usage.json` · ช่อง "ใช้ข้อมูล" รวมฐาน · **ทุกตัวอยู่ใน Model ของหมวดแล้ว (คอลัมน์ "นอก Model" ว่างทั้งหมด)** · สคริปต์อาจหลุด key ที่อ้างแบบอื่น ต้องตรวจด้วยตาซ้ำ

#### hero (9)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `artPortfolio` | `name` `รูปช่อง` `ธง owner.verified` |  |
| `artTypeOver` | `name` `nickname` `tagline` `รูปช่อง` `ธง owner.verified` |  |
| `heroMinimal` | `name` `tagline` `ธง owner.verified` |  |
| `kitProfile` | `handle` `name` `tagline` `categories.text` `↗socials.handle` `รูปช่อง` |  |
| `popHeroGlass` | `handle` `name` `workArea` `รูปช่อง` `ธง owner.verified` |  |
| `popHeroPaper` | `handle` `name` `workArea` `รูปช่อง` `ธง owner.verified` |  |
| `portfolioGingham` | `name` `รูปช่อง` `ธง cutout` `ธง owner.verified` |  |
| `portfolioWindow` | `name` `รูปช่อง` `ธง cutout` `ธง owner.verified` |  |
| `scrapBadge` | `categories#N` `handle` `name` `รูปช่อง` |  |

#### intro (8)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `aboutBehind` | `about` `name` `รูปช่อง` |  |
| `aboutEditorial` | `about` `รูปช่อง` |  |
| `aboutMe` | `about` `name` `รูปช่อง` |  |
| `aboutNote` | `↗categories#N` `name` `tagline` `workArea` `↗categories` `รูปช่อง` |  |
| `aboutText` | `about` `tagline` |  |
| `kitBio` | `about` |  |
| `scrapAbout` | `about` `nickname` `workArea` `รูปช่อง` |  |
| `scrapInfo` | `↗categories#N` `nickname` `workArea` |  |

#### tags (7)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `kitNiche` | `categories#N` `categories` |  |
| `nichePoster` | `categories#N` `categories` `รูปช่อง` |  |
| `nicheTags` | `categories#N` `categories` |  |
| `popNicheGlass` | `categories#N` `categories` |  |
| `popNichePaper` | `categories#N` `categories` |  |
| `scrapTags` | `categories#N` `categories` |  |
| `stickerTags` | `categories#N` `categories` |  |

#### followers (10)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `kitSocial` | `socials.followersFull` `socials.handle` `socials.icon` `socials.name` `ธง stamped` |  |
| `popStatsGlass` | `socials.followers` `socials.icon` `socials.name` |  |
| `scrapFeed` | `handle` `↗tagline` `socials.followers` `socials.icon` `รูปช่อง` |  |
| `scrapKeyTab` | `socials.followers` `socials.icon` |  |
| `socialChips` | `socials.engagement` `socials.followers` `socials.icon` `socials.name` `socials.tint` `socials.verified` `socials.views` `socials.viewsRaw` `ธง stamped` |  |
| `socialGingham` | `socials.engagement` `socials.engagementRaw` `socials.followersFull` `socials.handle` `socials.icon` `socials.name` |  |
| `socialTiles` | `socials.followers` `socials.icon` `socials.name` `socials.tint` `ธง stamped` |  |
| `socialWindow` | `socials.engagement` `socials.engagementRaw` `socials.followersFull` `socials.handle` `socials.icon` `socials.name` |  |
| `statGiant` | `socials.followers` `socials.icon` `stat:totalFollowers` `รูปช่อง` |  |
| `statPoster` | `socials.followers` `socials.icon` `socials.name` `ธง stamped` |  |

#### audience (7)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `audienceAge` | `ages.label` `ages.share` `ages.shareRaw` |  |
| `audienceLine` | `gender.share` `gender.shareRaw` `ages.label` `ages.share` `places.name` `places.share` |  |
| `audienceMap` | `places.name` `places.share` `places.shareRaw` `count:places` |  |
| `audiencePoster` | `places.name` `places.share` `places.shareRaw` `ages.label` `ages.share` `ages.shareRaw` `gender.label` `gender.share` `gender.shareRaw` `stat:reach` `stat:reachDelta` `stat:reachNew` `stat:reachWindow` `รูปช่อง` |  |
| `audienceSplit` | `gender.label` `gender.share` `gender.shareRaw` `gender.tint` |  |
| `kitInsight` | `stat:reachWindow` `places.name` `places.share` `places.shareRaw` `gender.label` `gender.share` `gender.tint` `ages.label` `ages.share` `ages.shareRaw` |  |
| `scrapStats` | `gender.label` `gender.share` `gender.shareRaw` `ages.shareRaw` `places.shareRaw` `↗socials.name` |  |

#### brand (4)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `proofBrandCoins` | `brands.logo` `stat:brandCount` |  |
| `proofBrandGrid` | `brands.logo` `stat:brandCount` |  |
| `proofBrandRail` | `brands.logo` `stat:brandCount` |  |
| `typeMarquee` | `brands.name` |  |

#### verified (3)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `proofTicket` | `works.brand` `works.brandLogo` `works.campaign` `works.cover` `works.ep` `works.icon` `works.saves` `works.shares` `works.views` `works.workPhoto` |  |
| `proofWork` | `works.brand` `works.brandLogo` `works.cover` `works.ep` `works.icon` `works.saves` `works.shares` `works.views` `works.viralTag` `works.workPhoto` |  |
| `wallPolaroid` | `works.brand` `works.campaign` `works.cover` `works.views` `works.workPhoto` |  |

#### photo (17)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `artDuo` | `รูปช่อง` |  |
| `artFilmstrip` | `รูปช่อง` |  |
| `artPair` | `รูปช่อง` |  |
| `galleryCarousel` | `รูปช่อง` |  |
| `galleryFilm` | `รูปช่อง` |  |
| `galleryMasonry` | `รูปช่อง` |  |
| `galleryPost` | `↗works.icon` `รูปช่อง` |  |
| `galleryStack` | `รูปช่อง` |  |
| `kitWorks` | `รูปช่อง` |  |
| `popVideoGlass` | `รูปช่อง` |  |
| `popVideoPaper` | `รูปช่อง` |  |
| `popWorkGlass` | `รูปช่อง` |  |
| `popWorkPaper` | `↗works` |  |
| `scrapPhones` | `รูปช่อง` |  |
| `wallMemory` | `รูปช่อง` |  |
| `workFeatured` | `↗works.icon` `รูปช่อง` |  |
| `workReel` | `↗works.icon` `รูปช่อง` |  |

#### showcase (1)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `reelShowcase` | `รูปช่อง` |  |

#### rate (2)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `kitRate` | `rates.label` `rates.platformName` `rates.price` |  |
| `rateTags` | `rateLabels#N` `rates.price` `rates.unit` |  |

#### contact (11)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `contactBar` | `lineId` `phone` `website` |  |
| `contactCard` | `lineId` `phone` `website` |  |
| `contactChips` | `lineId` `phone` `website` |  |
| `contactLine` | `lineId` |  |
| `contactPoster` | `lineId` `phone` `website` `รูปช่อง` |  |
| `contactQR` | `handle` `ธง owner.verified` |  |
| `contactStack` | `lineId` `phone` `website` |  |
| `kitContact` | `stat:lineFlow` `stat:phoneFmt` `stat:site` |  |
| `popContactGlass` | `lineId` `phone` `website` |  |
| `popContactPaper` | `lineId` `phone` `website` |  |
| `scrapNote` | `lineId` `phone` `website` |  |

#### availability (1)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `kitTime` | `avail.text` `areas.text` |  |

#### body (1)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `kitBody` | `body.label` `body.num` `body.unit` `body.value` `body.wide` |  |

#### seal (1)

| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |
|---|---|---|
| `proofSeal` | `handle` `↗count:socials` |  |

## 6. ป้าย / tier / ส่วนของตู้: ต่อหมวด หรือต่อ widget

เพื่อไม่ให้ UI เปลี่ยน: **ค่าของหมวด = ค่าตั้งต้น · widget ที่ปัจจุบันต่าง ใส่ key ทับใน JSON**

| widget | หมวด | ตอนนี้ | ต้องใส่ทับ |
|---|---|---|---|
| `scrapFeed` `scrapKeyTab` | followers | ไม่มีป้าย | `"stamp": null` |
| `typeMarquee` | brand | ไม่มีป้าย · tier personal | `"stamp": null` · `"tier": "personal"` |

(ตรวจด้วยสคริปต์ทุกค่าใน 3: ไม่ต้องเชื่อตารางนี้อย่างเดียว)

## 7. ลำดับงาน

1. **วิเคราะห์** ข้อ 10 → ส่งรายงาน → รอผู้ใช้
2. **สคริปต์ดึงนิสัย** จากโค้ด iOS (ต้นฉบับ) → เทียบกับ Android + `kinds.js` → ถ้า 3 ที่ไม่ตรงกัน **หยุดรายงาน** (ห้ามเดาว่าตัวไหนถูก)
3. **เติม key ลง JSON** ทั้ง 82 ไฟล์ (บล็อก `widget`) · ผังไม่แตะ
4. **ตาราง category** ใน 3 platform (ชื่อ + Model + แปลงข้อมูล + ล็อก + ข้อความรอ + ข้อมูลตัวอย่าง + ค่าตั้งต้นของป้าย/tier/ส่วนตู้) · ย้ายโค้ดแปลงข้อมูลเดิมเข้ามา **ไม่เขียนใหม่** (ผลต้องเท่าเดิม)
5. **เปลี่ยนจุดที่อ่านชื่อ widget** ให้อ่าน key/หมวด ทีละจุด · ตรวจหลังแต่ละจุด
6. **proofSeal** → `pinned` + หมวด seal · **textBlock** → ชั้นข้อความ (บังคับ · หน้าตา/การแก้/ไฟล์การ์ดเหมือนเดิม — การ์ดเก่าต้องเปิดได้) · `like`/`popTwin`/`retired` → key ใน JSON
7. **ลบ** ตารางชื่อ widget · enum ชื่อ widget · view เดิมต่อ widget ทั้งหมด (ไม่เหลือข้อยกเว้น) · ใส่สคริปต์ CI ข้อ 2.1
8. **validator** (ข้อ 5 ใช้สคริปต์ตัวเดียวกัน) · ใส่ในเทสต์
9. **ตรวจ** ข้อ 9 · รายงาน

## 8. ต้องตัดสินใจก่อนเริ่ม (ถามผู้ใช้)

1. Model ข้อ 4.2 ถูกไหม (โดยเฉพาะ field ↗ ที่ยืมข้ามหมวด)
2. รายชื่อหมวด fix ในโค้ด (แนะนำ) หรือเก็บเป็นข้อมูล
3. 14 หมวดใช้ต่อตามเดิม (แนะนำ · ไม่กระทบ UI) หรือจัดใหม่ (กระทบตู้ → ไป backlog)
4. primitive ไอคอนที่มีชื่อ (ข้อ 2.1) เก็บเป็นของกลางในโค้ด (แนะนำ · widget ไหนก็ใช้ได้) หรือแปลงเป็นไฟล์ vector ให้ JSON อ้าง (UI จะเป็น JSON ล้วนกว่า แต่ต้องพิสูจน์ว่าภาพเท่าเดิม)

## 9. ตรวจว่าไม่มีอะไรเปลี่ยน (ทุกข้อต้องผ่าน)

| ตรวจ | วิธี | ผ่านเมื่อ |
|---|---|---|
| กล่องของทุก widget | `node sync-server/web/test/replay.mjs` · Android unit test (`--rerun`) · iOS `-exportSpecs` | 81/81 · fixture เท่าก่อนเริ่มทุก byte |
| ภาพ | export ภาพทุก widget × ทุกพื้นหลัง × ทุกลาย ก่อน/หลัง (iOS `-exportSpecAB` · หน้า `sync-server/web/dev/gallery.html`) | ภาพเท่ากัน |
| ตู้ widget | ลำดับ · หมวด · ชื่อ · ไอคอน · ขนาดตอนวาง | เท่าเดิม |
| ถาด | แถวของทุก widget | เท่าเดิม |
| ล็อก / ข้อความรอ / ป้าย / ท่าเข้า | ทุกหมวด ทุก widget | เท่าเดิม |
| การ์ดเก่า | เปิดการ์ดที่บันทึกไว้ (lab sync rev ล่าสุด) บน 3 platform | เปิดได้ หน้าตาเท่าเดิม |
| ไม่มีชื่อ widget ในโค้ด | สคริปต์ CI ข้อ 2.1 (ชื่อจาก JSON + `replaces`) ทั้ง 3 platform | 0 · ไม่มี `like` |
| JSON only จริง | เพิ่ม widget ทดสอบจาก JSON ล้วน (ใช้ทุก key) · ลบ JSON ของ widget หนึ่งตัว | ขึ้นตู้/วาด/แก้/บันทึกได้โดยไม่แก้โค้ด · ลบแล้ว build ผ่าน |

## 10. งานวิเคราะห์ (ทำก่อน · ห้ามแก้ไฟล์)

**A · widget อยู่หมวดเดียวและถูกหมวด**: ทุกตัวมี `category` ตัวเดียว · เนื้อหาหลักตรงหมวด · ถ้าคิดว่าควรย้าย **เสนอเท่านั้น** (ย้ายหมวด = ตู้/ล็อกเปลี่ยน = backlog) · ตัวที่ควรดู: `galleryPost` `workFeatured` `workReel` `popWorkPaper` (photo แต่ใช้ `works`)

**B · Model ครอบคลุม**: widget ทุกตัว ⊆ Model ของหมวด (ข้อ 5 ตอนนี้ผ่าน) · ตรวจด้วยตาว่าสคริปต์ไม่หลุด key · Model ไม่มี field ที่ไม่มี widget ไหนใช้และไม่มีแผนใช้

**C · ข้อมูลที่ API ยังไม่มี** (❗ ข้อ 4.3) → **จดเป็นรายการให้ทีม API** ไม่แก้ widget (แก้ = UI เปลี่ยน):

| ที่ API ยังไม่มี | widget ที่ใช้ |
|---|---|
| insight ผู้ชม (ทั้งหมวด audience) | `audienceAge` `audienceLine` `audienceMap` `audiencePoster` `audienceSplit` `kitInsight` `scrapStats` |
| แบรนด์ที่ผ่าน Sale Here (brand) | `proofBrandCoins` `proofBrandGrid` `proofBrandRail` `typeMarquee` |
| งานที่ผ่าน Sale Here (verified + photo ที่ยืม) | `proofTicket` `proofWork` `wallPolaroid` · `galleryPost` `workFeatured` `workReel` `popWorkPaper` |
| สัดส่วน (body) | `kitBody` |
| วิว / engagement / เวลาซิงก์ ต่อช่องทาง | `socialChips` `socialGingham` `socialWindow` |
| เว็บไซต์ | `contactBar` `contactCard` `contactChips` `contactPoster` `contactStack` `popContactGlass` `popContactPaper` `scrapNote` `kitContact` |
| วันเวลารับงานเป็นข้อความ (`avail`) | `kitTime` (front แปลงจาก `days/slots` ได้ แต่ทำแล้วข้อความเปลี่ยน → backlog) |

**รายงานที่ส่งผู้ใช้**: ตารางเดียว · widget · หมวด · field ที่ใช้ (↗ ข้ามหมวด) · ❗ ที่ API ไม่มี · ข้อเสนอ (ถ้ามี)

## 11. Backlog (ทำให้ UI เปลี่ยน → ห้ามทำรอบนี้)

- ย้ายหมวดของ widget ที่ใช้ `works` ใน photo
- ป้าย Verified / tier เป็นของหมวดล้วน (3 widget จะเปลี่ยน)
- เลิกเติม `MOCK` ในโหมดจริง + ใส่ `if`/`has:` ซ่อนส่วนที่ API ไม่มี (เว็บไซต์ · วิว/engagement)
- แปลง `days/slots` เป็นข้อความ `avail`
- จัดหมวดใหม่
- ลายแผ่น/สีเป็นข้อมูลบน API (ดู `shared/docs/starcard-model.html`)

## 12. กติกาของ repo

- trial ต้องย้อนกลับได้: แก้แอปแล้วอัปเดต `sync-server/trial/apps.patch` + `revert.sh`
- JSON อยู่ `shared/WidgetSpecs/` ที่เดียว · ห้ามแก้ JSON เพื่อแก้ parity ของ platform เดียว
- ห้ามแตะ repo `salehere-ios`
- เอาแบบเรียบง่าย · ไม่ใช้ agent หลายตัวขนานกัน

## 13. ผลที่ทำ (15 ต.ค. 2569)

- **JSON**: บล็อก `widget` ของทั้ง 82 ไฟล์ถูกเติมนิสัยครบด้วยสคริปต์ จากค่าที่ iOS คำนวณจริง (`-exportBaseline` → traits.json) · ผังไม่แตะ (เทียบกับสำเนาเดิมแล้ว 82/82 เท่ากัน) · ไม่มี `like` · สัญญาคีย์อยู่ที่ `StarCard/WIDGET-SPEC.md` §3.3c
- **Model ของหมวด**: `shared/category-models.json` (ไฟล์เดียวใช้ทุกแพลตฟอร์ม/ดีไซเนอร์) · เพิ่มจากข้อ 4.2: hero ↗`socials.followersRaw` `socials.platform` · rate `rates.platformOrder` · audience ↗`socials.engagementRaw` · body `body.kind`
- **ค่าของหมวดในโค้ด**: `WidgetFamily.group` · `.tier` · `.missing` (iOS/Android) · `CATEGORY_TIER` (เว็บ)
- **iOS**: `WidgetKind` = struct มีแค่ `rawValue` อ่านทุกอย่างจาก `meta` · ลบ `Base` enum · `retired` → `replaces` · ลบ view ต่อ widget 28 ไฟล์ (ชิ้นส่วนกลางที่ตัววาดใช้ย้ายไป `Views/Widgets/Primitives/`) · ถาดชุดห้าสไตล์อ่าน `kit.controls` · `textBlock` = ชั้นข้อความ (`WidgetKind.textLayer` · นิสัยใน `TextBlock.layer`) · การ์ดเริ่มต้น → `shared/starter-cards.json`
- **Android**: เหมือน iOS (`WidgetBase` enum ลบ · `WidgetKind` อ่าน JSON · `stampFacts`/`kitTitle`/`entranceStyle` อ่าน JSON) · Android ยังไม่มีถาดเนื้อหาชุดห้าสไตล์/ช่องทาง/แบบตรา (ช่องว่างเดิม ไม่ใช่ของใหม่)
- **เว็บ**: `kinds.js` ไม่มีชื่อ widget · `extraTokens` รับ `skin` แทนชื่อ
- **ตรวจ**: `node shared/tools/check-widgets.mjs` (ชื่อในโค้ด 0 · คีย์ widget ถูก · ทุกใบ ⊆ Model) · iOS ภาพ 667 ไฟล์ก่อน/หลังเท่ากันทุก byte ยกเว้น `galleryPost__paper` ที่ต่างกันเองระหว่างสองรอบของโค้ดเดิม · นิสัย/ลำดับตู้ iOS เท่าเดิม · Android นิสัยก่อน = iOS = หลัง (0 ต่าง) · Android fixture 81/81 · เว็บ replay 81/81 · `WidgetJsonOnlyTest` (Android) + iOS build ผ่านเมื่อลบไฟล์ผังหนึ่งไฟล์
- **ยังไม่ได้ทำ**: ย้ายโค้ดแปลงข้อมูล API → ค่าพร้อมวาด ให้แยกเป็นต่อหมวดในโค้ด (ตอนนี้ยังอยู่ที่ `IOSSpecData` / `AndroidSpecData` / `data.js` เหมือนเดิม · ผลเท่าเดิม) · โหลดผังจาก server ตอนเปิดแอปในโหมดจริง (มีแค่ในโหมดลองทำ)
