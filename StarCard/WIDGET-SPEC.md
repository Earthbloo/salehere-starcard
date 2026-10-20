# Star Card Widget Spec — สัญญาข้ามแพลตฟอร์ม

> ผังของ widget เป็น **ข้อมูล** (JSON หนึ่งไฟล์ต่อชนิด) · ตัวคำนวณกล่องเป็น **อัลกอริทึมเดียว** ที่ iOS / Android / Web
> ต้อง port ให้ตรงด้วย fixture · ตัววาดรู้จัก primitive ไม่กี่อย่างและ **ไม่ตัดสินใจอะไรเอง** · **แอปไม่รู้จักชื่อ widget สักตัว** (§3.3c)
>
> ไฟล์ผัง: `shared/WidgetSpecs/<kind>.json` — **ชุดเดียว** ที่สามแพลตฟอร์มอ่านตรง ๆ ไม่มีสำเนา:
> iOS (folder reference ใน project.pbxproj) · Android (`assets.srcDirs("../../shared")` ใน app/build.gradle.kts) · เว็บ (`sync-server/server.mjs` อ่านสดจากโฟลเดอร์ → `GET /api/specs` · `?known=<hash>` ไม่เปลี่ยน = 204)
> ตัวคำนวณ: `StarCard/Layout/SpecSolver.swift` · `StarCardAndroid/…/layout/SpecSolver.kt` · `sync-server/web/js/spec-solver.js` — ตัววาด: `SpecPainter.swift` · `SpecPainter.kt` · `spec-painter.js`
> fixture: `present/spec-fixtures/fixtures/<kind>.json` (สร้างด้วย `-exportSpecs` · ดู §7) · ตรวจกติกา: `node shared/tools/check-widgets.mjs`
>
> **สถานะ 18 ต.ค. 2569**: 82 ชนิด = JSON ทั้งหมด (ไม่มี view ต่อ widget เหลือในโค้ด) · Model ต่อหมวดใน `shared/category-models.json` · fixture 81/81 ทั้ง Android (JVM) และเว็บ (20 ต.ค. 2569: เว็บ 122/122 ทั้ง solver และตัววัดข้อความ — §7) · ประวัติการเปลี่ยนอยู่ §11

## 1. ทำไม

ผลตรวจ 28 ก.ย. 2569: 81 ใบ × ทุกตัวเลือก → เท่ากัน 4 · ต่าง 59 เพราะผังอยู่ในโค้ดสามชุด (SwiftUI · Compose · DOM)
และเราปล่อยให้ layout engine + ฟอนต์ระบบ + autosize ของแต่ละแพลตฟอร์มตัดสินใจเอง
กติกา (ผู้ใช้ 13 ต.ค. 2569): **ทุก widget ใช้ concept เดียวกัน** · resize กว้าง/สูงอิสระ · วาดออกมาเท่ากัน
กติกาเพิ่ม (ผู้ใช้ 15 ต.ค. 2569): **Renderer เป็น standalone ตัวกลางอ่าน JSON เท่านั้น · UI ของ widget = JSON only** · ห้ามมี logic ของ widget ตัวใดตัวหนึ่งในโค้ด

## 2. สูตรเดียวของกรอบ (chrome)

ใบถูกออกแบบที่ `design = (w0, h0)` (อยู่ในไฟล์ผัง) · ผู้ใช้ลากกรอบเป็น `W × H` อะไรก็ได้

```
s     = min(W / w0, H / h0)                 ย่อ/ขยายทั้งก้อนด้วยแกนที่คับสุด · ไม่บีบสักแกน
inset = 12 ถ้า chrome วาดแผ่น (glass/dim) หรือมีเส้นขอบ · 0 ถ้า surface = pane/clear หรือใบวาดพื้นเอง (widget.ownSurface) หรือ widget.fullBleed
box   = (W / s − 2·inset, H / s − 2·inset)  กล่องรากในหน่วยออกแบบ
```

ตัวคำนวณจัดผังลงใน `box` แล้วตัววาด **scale ทั้งก้อนด้วย `s`** (anchor มุมบนซ้าย) และเลื่อนเข้า `inset·s`
ไม่มีกติการายใบ (ไม่มี noGrow / reflow whitelist / keepsDesignAspect) — ใครกินที่เพิ่ม ใครขึ้นบรรทัดใหม่ อยู่ในผัง ·
ค่าที่ chrome ต้องรู้ต่อใบ (วาดพื้นเองไหม · ขอบ · ชนขอบ · ล็อกสัดส่วน) อ่านจากบล็อก `widget` (§3.3c) ไม่ใช่จากชื่อ

ตัวเลขทุกตัวในผังเป็น **pt หน่วยออกแบบ** (iOS pt = Android dp = Web px ที่ density 1)

## 3. ไฟล์ผัง

```jsonc
{
  "kind": "heroMinimal",            // = ชื่อไฟล์ (ไม่มี enum ในแอป · check-widgets ตรวจว่าตรงกัน)
  "design": { "w": 366, "h": 124 }, // ขนาดอ้างอิง (ความกว้างหน้าพอร์ต 366)
  "notes": "…",                     // ไม่ใช้ตอนวาด
  "widget": { … },                  // นิสัยของ widget ต่อตู้/ถาด/chrome (§3.3c · บังคับ title + category)
  "fitScale": [1, 0.9, 0.8],        // (ไม่บังคับ) ขั้นย่อเมื่อความสูงตามเนื้อหาเกินกรอบ (§3.1 "ไฟล์")
  "variants": [                     // (ไม่บังคับ) ผังทางเลือกตามรูปทรง box / ข้อมูล — ใบแรกที่จริงชนะ
    { "when": "ratio<0.5", "root": { … } }
  ],
  "root": { "type": "col", … }
}
```

`when` / `sizeWhen.when` ประเมินจาก **box** (หน่วยออกแบบ): `w<260` · `h>=400` · `ratio<0.6` (ratio = h/w) · ต่อด้วย `&` · `variants.when` รับเงื่อนไขข้อมูลแบบเดียวกับ `if` ด้วย (เช่น `cfg:fill=clear`) — ชุดห้าสไตล์ = **หนึ่งหน้าตาต่อหนึ่งไฟล์** (`kitRatePurple` … `kitRateMac` · หน้าตาอยู่ที่ `widget.kit.look`) ตั้งแต่ 19 ต.ค. 2569

### 3.1 โหนด — ฟิลด์ทั้งหมดเป็น optional

| กลุ่ม | ฟิลด์ | ความหมาย |
|---|---|---|
| ไฟล์ | `fitScale` | (ระดับไฟล์) `[1, 0.9, … 0.42]` — ความสูงตามเนื้อหาเกินกรอบ → คำนวณใหม่ในกล่อง `box/k` ทีละขั้น ใช้ขั้นแรกที่พอดี แล้วตัววาด scale ทั้งก้อนด้วย `k` (แทน ViewThatFits ของโค้ดเดิม) |
| ชนิด | `type` | `col` `row` `stack` `text` `image` `rect` `icon` `chips` `spacer` `line` |
| | `id` | ชื่อไว้อ้างใน fixture |
| กล่อง | `w` `h` | ตัวเลข · `"72%"` (สัดส่วนของที่ว่างในแม่ด้านนั้น) · `"fill"` (= grow 1) · `"hug"` (เท่าเนื้อหา · ค่าตั้งต้นของแกนหลัก) |
| | `grow` | น้ำหนักกินที่ที่เหลือในแกนหลักของแม่ (0 = ไม่กิน) |
| | `shrink` | ยอมหดเมื่อที่ไม่พอ · ตั้งต้น: ระบุขนาดตายตัว = 0 · text/col/row/chips/stack/spacer = 1 · อื่น = 0 |
| | `minW` `maxW` `minH` `maxH` | ขอบเขต |
| | `aspect` | กว้าง/สูง · แกนที่ไม่ระบุคิดจากอีกแกน |
| | `pad` | `8` · `[v,h]` · `[t,r,b,l]` |
| | `gap` | ระยะระหว่างลูก (และระหว่างบรรทัดของ wrap) |
| | `align` | จัด **ลูก** ในแกนขวาง: `start` `center` `end` `stretch` (ตั้งต้น stretch · chips/wrap ตั้งต้น start) |
| | `alignSelf` | จัด **ตัวเอง** ในแกนขวางของแม่ (ชนะ `align` ของแม่) |
| | `justify` | จัดลูกในแกนหลัก: `start` `center` `end` `between` `around` |
| | `wrap` | `row` ขึ้นบรรทัดใหม่เมื่อล้น (chips = true เสมอเว้นแต่ `false`) |
| | `place` `dx` `dy` | ใน `stack`: ตำแหน่งลูก `top-left` … `center` … `bottom-right` + ขยับ |
| | `rotate` | หมุน (องศา) ตอนวาด รอบกลางกล่อง — **ทั้งกิ่ง** (ลูกหมุนตาม) · ไม่กระทบการคำนวณกล่อง |
| | `rotateCycle` | ใน `each`: `[-4, 2.5, -1.5]` ชิ้นที่ i หมุน `cycle[i % n]` |
| | `pct` | ใน `each`: ขนาดแกนหลัก = (ค่าฟิลด์ 0–100) % ของที่ว่างในแม่ เช่น `"pct": "$shareRaw"` (แถบกราฟ) · `"$shareRaw/max"` = เทียบค่าสูงสุดในรายการ · `"$followersRaw/sum"` = ส่วนแบ่งของยอดรวม · ไม่หด · ใช้ใน row/col (ไม่ใช่ wrap) — ลูกของแม่ที่อยู่ใน `each` ใช้ได้ทุกชั้น (ค่า max/sum ติดมากับชิ้น) |
| การทา | `fill` | token สี (§4) · ใน `each` ใช้ `$tint` / `$tint@0.3` อ้างฟิลด์ของชิ้นได้ |
| | `fillCycle` | ใน `each`: `["accent", "white", "#9EF5B8"]` ชิ้นที่ i ได้ `cycle[i % n]` (ชนะ `fill`) |
| | `gradient` | `{from, to, angle}` · angle 0 = ซ้าย→ขวา · 90 = บน→ล่าง |
| | `radius` | มุม (continuous/squircle บน iOS · rounded บนที่อื่นยอมรับ) |
| | `circle` | `true` = มุม = ครึ่งด้านสั้น ณ ขนาดจริง (วงกลม/แคปซูล) ชนะ `radius` |
| | `stroke` | `{color, width, dash?}` วาดด้านในขอบ (inner stroke) |
| | `opacity` | ความทึบ **ทั้งกิ่ง** |
| | `shadow` | `{sigma, x?, y?, color?}` **หน่วย sigma** (iOS radius = 2σ · CSS blur = 2σ · Android elevation ≈ σ·1.5) · บนพื้น/รูป/ข้อความ (ข้อความ = เรืองแสง) · x y ตั้งต้น 0 · color ตั้งต้น black@0.25 |
| | `clip` | `true` = ตัดลูกทุกตัวด้วยกล่องนี้ (มุมตาม `radius`/`circle`/`shape`) |
| | `shape` | รูปร่างของกล่อง (พื้น · เส้น · clip): `tag:16` (ป้ายห้อย ปลายตัด 16) · `heart` · `scallop:8` (ตราหยัก 8 กลีบ) · `zigzag:10` (ขอบฟันปลาล่าง ฟันกว้าง 10) · `circle` |
| | `pattern` | ลายพื้นทับบน fill ตัดตามรูปร่าง: `{kind, color, color2?, size, width, angle, opacity}` · kind: `gingham` (ผ้าตาราง size=ช่อง) `stripes` (เฉียง angle) `lines` `dots` `grid` `sprockets` (รูฟิล์มบน+ล่าง width=สูงรู angle=ระยะจากขอบ) `rings` `speckle` (จุดสุ่ม seed คงที่) `barcode` `guilloche` (วาดใน `SpecPatterns.*`) |
| | `platePattern` | บน `rect`: `"<token สีแผ่น>"` — ลายแผ่นที่ผู้ใช้เลือกในถาด (ลายทาง/ข้าวหลามตัด · `PlatePatternLayer`) วางเหนือชั้นแผ่น เงื่อนไข `if` เดียวกับแผ่น · ใบที่ `widget.pattern` ต้องมีทุกใบ |
| ข้อความ | `slot` | ช่องของโปรไฟล์ `name` `tagline` `about` `handle` `nickname` `phone` `email` `lineId` `website` `workArea` `categories#N` `rateLabels#N` `ratePrices#N` `note#N` (ต่อชิ้น) · ค่าที่ระบบคิด `stat:…` `count:…` (§3.2) · ใน chips ใช้ `$field` (ค่าของรายการ) หรือ `categories#$i` · **ต้องอยู่ใน Model ของหมวด** (§3.2b) |
| | `text` | ข้อความของดีไซน์ · ใช้เมื่อ `slot` ว่าง · แทนค่า `{field}` จากรายการได้ |
| | `preset` | ข้อความตั้งต้นของ `note#N` |
| | `face` | ค่า = `CardFont` ของแอป: `noto` (ตั้งต้น) `mitr` — **ฟอนต์ OFL ที่ฝังมาเท่านั้น** (19 ต.ค. 2569 ถอด `serif` `rounded` `sukhumvit` `thonburi` `krungthep` ซึ่งเป็นฟอนต์ของ Apple) · face อื่นตกไป `noto` ทุกแพลตฟอร์ม |
| | `size` `weight` | pt · 100–900 |
| | `maxLines` | 0 = ไม่จำกัด · ตั้งต้น: ในแกนที่รู้ความกว้าง 0 · บรรทัดเดียวเมื่อไม่รู้ความกว้าง |
| | `shrinkTo` | ย่อตัวอักษรได้ถึงขนาดนี้เมื่อไม่พอ (ลดทีละ 0.5) · ไม่ใส่ = ไม่ย่อ ตัด … |
| | `role` | บทบาทต่อขั้นต่ำที่อ่านออก (§5 ข้อ 9): `title` · `content` · `deco` (ไม่มีขั้นต่ำ — ตัวอักษรในโลโก้/ตรา) · ไม่ใส่ = ขนาดในผัง ≥ 18 เป็นหัว นอกนั้นเนื้อหา |
| | `growTo` | ขยายจาก `size` ทีละ 1 จนบรรทัดเดียวเต็มความกว้างกล่อง (เพดาน growTo) — หัวเรื่องแบบ fit-to-width · ทำก่อน shrink |
| | `mixHead` | `true` = พาดหัวสองเสียง: คำแรกตามฟอนต์ของโหนด ที่เหลือเซริฟเอียง ×1.04 (กติกาโปสเตอร์ · ฟอนต์ของช่องที่ผู้ใช้เลือกชนะเซริฟ) |
| | `tracking` `kerning` `lineHeight` | ระยะตัวอักษร · ตัวคูณความสูงบรรทัด (ตั้งต้น 1 = ของฟอนต์) |
| | `textCase` `textAlign` `italic` `color` | `upper`/`lower` · `left`/`center`/`right` |
| | `sizeWhen` | `[{when, size}]` เปลี่ยนขนาดตามกล่องราก |
| | `readonly` | ผู้ใช้แก้ไม่ได้ (ป้ายของดีไซน์ · ตัวเลขจากระบบ) |
| รูป | `photo` | ลำดับช่องรูปของชิ้น (0, 1, 2 …) |
| | `photoRef` | ช่องรูปจากฟิลด์ของรายการ — `"$workPhoto"` (ชนะ `photo`) |
| | `src` | รูปจาก asset/URL — `"$cover"` · `"$brandLogo"` · ว่าง = กลับไปใช้ช่องรูป |
| | `fit` `mono` | `cover` (ตั้งต้น) / `contain` · ขาวดำ (รูป PNG ใสที่ผู้ใช้ตัดพื้นมาเองเป็นคัตเอาต์ได้ — แอปไม่ลบพื้นหลังให้ · `lift` ถูกถอด 19 ต.ค. 2569) |
| ไอคอน | `icon` | ชื่อตาม §6 (`ph:<name>` `sh:<name>` `url:<https…>` `byline` `starLockup` …) · `$icon` / `$logo` / `$brandLogo` (จากรายการ) · `tint` |
| รายการ | `list` `each` `limit` | ชนิด `chips`: วาดแม่แบบ `each` ซ้ำต่อชิ้นใน `list` |
| | `where` | กรองชิ้นก่อนวาด — เงื่อนไขเดียวกับ `if` ต่อชิ้น เช่น `"!hidden:$platform"` · `"$viewsRaw>0"` |
| | `sort` | `"followersRaw desc"` · `"label asc"` · หลายคีย์คั่น `,` — เรียงก่อนวาด (ตัวเลขเทียบเป็นตัวเลข) แล้วนับ `i` ใหม่ |
| | `group` | `"platform"` — หลัง `sort` เก็บชิ้นแรกของแต่ละค่า (แถวละหนึ่งช่องทาง) |
| | `direction` | `"row"` (ตั้งต้น = wrap) · `"col"` = เรียงลงเหมือน `col` (ลูกกว้างเต็ม · `gap` เดิม) |
| เงื่อนไข | `if` | `owner.verified` · `sample` · `ink.light` (หมึกของพื้นสว่าง) · `bordered` (ชิ้นเปิดขอบ) · **พื้นผิวของชิ้น** (ถาด "พื้นหลัง" — ดู §3.4): `surface=glass|dim|clear|pane` · `papered` (= glass หรือ dim: ใบวาดแผ่น/กระดาษของตัวเอง) · `duo` (การ์ดคู่สี) · `stamped` (ใบได้ดวงตรา Verified by Sale Here → วาด `icon: verifiedPill`) · `cutout` (รูปช่อง 1 เป็นคนที่ตัดพื้นแล้ว — สลับคนยืนคร่อม/รูปในกรอบ) · `kit.dark` (แผ่นชุดห้าสไตล์มืด) · ชุดห้าสไตล์: `cfg:fill=solid|gradient|clear` `cfg:corner=round|square` `opt:<key>` (ค่าตัวเลือกไม่ว่าง/ไม่ใช่ 0) `opt:<key>=<v>` `hidden:<id>` (อยู่ในรายการซ่อน) · `has:<slot>` (รวม `has:stat:…`) · `!has:<slot>` · `list:<name>>N` · `list:<name>=N` · `$field` (ไม่ว่าง) · `$field=max` (ชิ้นที่ค่าสูงสุดในรายการ) · `$field>0` · `$i=first` (ชิ้นแรก) · ขึ้นต้น `!` = นิเสธ · ต่อหลายข้อด้วย `&` (และ) / `|` (หรือ) · `$field` ข้างในชื่อธงถูกแทนค่าก่อน (`hidden:$platform`) |
| | `children` | ลูก |

### 3.2 รายการ (`list`) และฟิลด์ของแต่ละชิ้น

ทุกชิ้นมี `i` (ลำดับ 0…) · `rank` (= i+1) · `rank2` (= 01, 02 …) · ฟิลด์ตัวเลขทุกตัวมีคู่ `<key>.max` และ `<key>.sum` ของรายการ (หลัง sort/limit) · ค่าทั้งหมดเป็น **สตริงที่จัดรูปแล้ว** (แพลตฟอร์มจัดรูปเหมือนกันด้วยกติกา `Fmt`: 1.2K · 184K · 1.5M)

| list | ฟิลด์ |
|---|---|
| `categories` | `text` · ช่องแก้ได้ `categories#$i` |
| `socials` | `platform` (instagram/tiktok/youtube/facebook/lemon8/x) `name` `short` `icon` (asset โลโก้) `tint` (#hex ของช่อง) `handle` `followers` `followersFull` `followersRaw` `views` `viewsFull` `viewsRaw` `engagement` `engagementRaw` `synced` `verified` ("1" เมื่อเชื่อม OAuth แล้ว · ว่าง = กรอกเอง) |
| `rates` | `label` `price` (฿12,000) `priceRaw` `priceNum` ("3,000") `unit` `platform` `platformName` `platformOrder` `icon` `tint` `format` · ช่องแก้ได้ `rateLabels#$i` `ratePrices#$i` |
| `brands` | `name` `logo` (URL) `industry` |
| `works` | `brand` `brandLogo` (URL `logo` ของแบรนด์ · ไม่มีก็ชื่อ asset ในแอป `asset` · ไม่มีทั้งคู่ = ว่าง) `ep` `campaign` `platform` `icon` `tint` `format` `cover` `workPhoto` `photo` `views` `viewsRaw` `saves` `savesRaw` `shares` `sharesRaw` `likes` `comments` `engagement` `engageRaw` `viralTag` |
| `contacts` | `kind` (phone/email/line/web) `value` `icon` (`ph:phone` `ph:envelope` `sh:line` `ph:globe` — ชื่อที่แหล่งข้อมูลสร้างเอง ต้องมี asset ทั้งสาม · `SpecIconCoverageTest` ตรวจ) `slot` (phone/email/lineId/website) — ค่าอ่านด้วย `text` ของโปรไฟล์ (ยังไม่กรอก = ประโยคชวนกรอกของช่อง เหมือน iOS) · ตัดเฉพาะช่องที่ว่างจริง |
| `gender` `ages` `places` | `label`/`name` `share` (62%) `shareRaw` · gender มี `tint` (#FF8CBD หญิง · #8299FF ชาย · #5CE6AD อื่น ๆ) |
| `body` | `kind` (h/w/g/s) `label` `value` ("165 cm" · "48 kg" · "32 / 25 / 35" · "EU 38") `num` `unit` (ซม. · กก. · หน่วยรอบตัวเมื่อสามค่าหน่วยเดียวกัน ไม่งั้นว่างและ `value` = "32 นิ้ว · 25 ซม. · 35 นิ้ว") `wide` ("1" = แถวรอบอก/เอว/สะโพก) — จาก Star Profile: iOS `StarFlow.bodyInfo` · Android/เว็บ = ค่าพร้อมหน่วยที่ iOS sync มาใน `values.weight/height/bust/waist/hips/shoe` ("165 ซม." · "32 นิ้ว" · "38 EU") แยกตัวเลข/หน่วยกลับ · ยังไม่กรอก: sample = ชุด 165/48/32-25-35/38 · การ์ดจริง = ว่าง |
| `avail` · `areas` | `text` — `avail` = `availSummary` ของ iOS ทุกตัวอักษร: ตารางรายวัน (จ→อา) → วันที่ชุดช่วงเหมือนกันรวมกลุ่ม · ติดกันเกิน 2 วันเขียน "จ–ศ" ไม่งั้น "จ พ ศ" · ช่วง: ครบ 4 = "ตลอดวัน" · ติดกันรวม "09.00–14.00" · ห่างคั่น " + " · เป็นต้นไป = "17.00 เป็นต้นไป" → "จ–ศ 17.00 เป็นต้นไป" · Android/เว็บคิดจาก `intake.availability.days` (0 = อาทิตย์) × `slots` (iOS แบนตารางมาให้ทุกวันช่วงเดียวกัน — วันที่ช่วงต่างกันจึงออกเป็นบรรทัดเดียวบนสองแพลตฟอร์มนั้น · §10) · Android ไม่มีฟอร์มใช้ป้าย wizard ของเครื่อง · `areas` = จังหวัด |
| `photos` | `photo` (ช่องรูป 4…9) |

ค่าที่ระบบคิดให้ ใช้เป็น `slot` ของ `text` (อ่านอย่างเดียว): `stat:totalFollowers` `stat:avgViews` `stat:brandCount` `stat:workCount` `stat:socialCount` `stat:rateCount` `stat:placeCount` `stat:reach` (184K) `stat:reachRaw` `stat:reachDelta` (+12%) `stat:reachNew` (38%) `stat:reachWindow` `stat:reachPlatform` `stat:reachIcon` `stat:cardURL` `stat:year` `stat:phoneFmt` (เบอร์จัดรูป 3-3-4) `stat:site` (เว็บไซต์ตัดโปรโตคอล) `stat:lineFlow` · `count:<list>` = จำนวนชิ้นของรายการ

สามค่าช่องทางติดต่อ (`stat:phoneFmt` `stat:site` `stat:lineFlow`) อ่าน **ค่าดิบของ Star Profile** ไม่ใช่ `text` ของโปรไฟล์ (ยังไม่กรอก = ว่าง → ผังซ่อนด้วย `has:` · sample = 081-234-5678 · nirabeauty.co · @nirabeauty): iOS `StarFlow.phone/website/lineID` · Android/เว็บ = `stored(phone/website/lineId)` ของโปรไฟล์ (iOS `Profile.sync` เขียนค่าเดียวกันลง `values` ตอน sync · ว่าง = ไม่มีคีย์) — ช่อง `website` อยู่ใน `ProfileField` ของทั้งสามตั้งแต่ 20 ต.ค. 2569

**กติกาปัดเลข (20 ต.ค. 2569 — ทุกตัวเลขที่จัดรูปในแหล่งข้อมูล)**: **half-up บนค่าทศนิยมที่สั้นที่สุดของ double** — 1.25 → 1.3 · 1.15 → 1.2 · 62.5 → 63 · 1.005 → 1.01 · `Fmt.compact(1250)` = "1.3K" · `share` 62.5 → "63%" · `engagement` 4.65 → "4.7%"
- iOS `Fmt.fixed(v, digits)` = `NumberFormatter(.halfUp)` (ห้าม `String(format: "%.1f")` — printf ปัดบนค่าไบนารีแบบ ties-to-even: 1.25 → "1.2" · 62.5 → "62")
- Android `Fmt.f` = `String.format(Locale.US, "%.nf")` (Java = HALF_UP บนหลักของ `Double.toString` อยู่แล้ว)
- เว็บ `fixed(v, d)` ใน data.js ปัดบนสตริง `String(v)` เอง (ห้าม `toFixed` — ปัดบนค่าไบนารี: 1.15 → "1.1" · 1.005 → "1.00")
- ส่วนที่เป็นจำนวนเต็มอยู่แล้ว (`Int(v.rounded())` · `roundToInt` · `Math.round` ที่ ≥ 100 ของ `compact`) เท่ากันทั้งสาม (ครึ่งปัดขึ้นสำหรับค่าบวก)

สีของช่อง (`tint`) เป็น hex ตายตัวต่อแพลตฟอร์ม: IG `#E85C9E` · TikTok `#33F0EB` · YT `#FF524D` · FB `#5C8FFA` · Lemon8 `#FFD640` · X `#D9D9E0`

### 3.2b Model ของหมวด — widget อ่านได้เฉพาะ field ของหมวดตัวเอง (15 ต.ค. 2569)

`shared/category-models.json` = สัญญาข้อมูลไฟล์เดียวที่สามแพลตฟอร์ม + ดีไซเนอร์ใช้ (ที่มา: `shared/docs/WIDGET-CATEGORY-PLAN.md` ข้อ 4)

- `base` (ทุกหมวดมี): `slot:name` `slot:handle` `slot:note#N` `photo` `flag:owner.verified` `flag:stamped` `flag:cutout`
- `categories.<หมวด>.fields` = field ของหมวด · `.borrow` = ↗ ยืมจากส่วนอื่นของ API (เช่น hero ยืม `socials.handle` · intro ยืม `categories`)
- widget ใช้ **⊆ Model** ของ `widget.category` · โชว์ไม่ครบได้ · ใช้ field นอก Model = `check-widgets.mjs` ล้ม
- ข้อมูลตัวอย่าง (ตู้ · ใบที่ล็อก · พรีวิว) = 1 ชุดต่อหมวด · ต้องการข้อมูลใหม่ → เพิ่มที่แหล่งข้อมูลของทุกแพลตฟอร์มพร้อมกัน (`IOSSpecData` · `AndroidSpecData` · `data.js`) แล้วบันทึกใน §3.2 + category-models.json

### 3.3 ผังกับ "โมเดล" ของการ์ด — ใช้ร่วมกันยังไง

ผังไม่ได้แทนเอกสารการ์ด มันคือชั้นที่อยู่ **ระหว่าง** เอกสารกับตัววาด:

| ชั้น | เก็บที่ | ใครเขียน |
|---|---|---|
| เอกสารการ์ด (`CardSnapshot` v2 บนเครื่อง · `StarCardDoc` บนเซิร์ฟเวอร์) | ต่อการ์ดของผู้ใช้: หน้า → ชิ้น `{kind, x, y, w, h, surface, border, pattern, slotFaces/slotTints/slotSizes, kit, pinned, …}` | ผู้ใช้ (ผ่าน editor) |
| ข้อมูลเจ้าของ (`Profile` / `StarProfile` / รูปใน `PhotoStore`) | ชื่อ · สายงาน · แนะนำตัว · ช่องทาง · เรต · รูป | ผู้ใช้ / ระบบ |
| **ผัง** (`shared/WidgetSpecs/<kind>.json`) | ต่อ **ชนิด** · ฝังมากับแอป (โหมดลองทำโหลดจาก `/api/specs` ได้ — `SpecCatalog.replace`) | ดีไซเนอร์ |

จุดเชื่อม = **ชื่อช่อง** เท่านั้น: `slot` ในผังคือคีย์เดียวกับ `ProfileField.rawValue` / `WidgetTextStyle.slotKey` ในเอกสาร
(`name` · `tagline` · `categories#2` · `note#1`) และ `photo` คือลำดับช่องรูปเดียวกับ `PhotoStore` / `WidgetItem.photos["N"]`
· `kind` ในเอกสาร = ชื่อไฟล์ผัง (ชื่อเก่าที่ถอดแล้วตกไปที่ใบที่ประกาศ `widget.replaces` · ไฟล์สติกเกอร์รุ่นแรกที่เขียนแค่ `popHero` ต่อท้ายวัสดุตามธีมของไฟล์ — `WidgetKind.decode`)
· สไตล์ที่ผู้ใช้ตั้งให้ช่อง (ฟอนต์ · สี · ขั้นขนาด) ถูกอ่านจากเอกสารชิ้นนั้นแล้วคูณทับค่าของผัง (§5 ข้อ 2)
· ฝั่ง API (`api/star-card/star-card.schema.graphql`) ยังไม่ประกาศรายการช่อง — รายการที่ใช้จริงคือ `ProfileField` ในแอป + `category-models.json`

**ออกแบบใบใหม่ = เขียน JSON ใบเดียว** (ผัง + บล็อก `widget`) ไม่ต้องแตะเอกสารการ์ดหรือโมเดลโปรไฟล์ ตราบที่ใช้ช่อง/รายการใน Model ของหมวด (§3.2b) ·
หมวดใหม่เท่านั้นที่ต้องรอโค้ด (`WidgetFamily` iOS/Android · `CATEGORY_TIER` เว็บ)

### 3.3c บล็อก `widget` — นิสัยทั้งหมดของ widget อยู่ในไฟล์ผัง (15 ต.ค. 2569)

**แอปไม่รู้จักชื่อ widget สักตัว** (iOS · Android · เว็บ) — ตู้ · ถาด · พื้นผิว · ป้าย · ท่าเข้า อ่านจากบล็อกนี้อย่างเดียว
(iOS `WidgetKind` = struct ที่มีแค่ `rawValue` · property ทุกตัวอ่าน `meta` = บล็อกนี้ · Android `WidgetKind` เหมือนกัน · เว็บ `kinds.js` → `kindInfo(kind, spec)`)
เพิ่มไฟล์ = ขึ้นตู้ทันที · ลบไฟล์ = หายจากตู้ (build ผ่าน · Android มี `WidgetJsonOnlyTest` พิสูจน์) · ตรวจด้วย `node shared/tools/check-widgets.mjs`
(ชื่อ widget ในโค้ด = 0 · คีย์ในบล็อกต้องอยู่ในรายการที่แอปอ่าน · ไม่มี `like` · field ⊆ Model ของหมวด · `kind` = ชื่อไฟล์)

```jsonc
"widget": {
  "title": "หน้าต่างช่องทาง",        // ชื่อในตู้ (บังคับ)
  "category": "followers",          // หมวด = WidgetFamily ที่แอปมี (บังคับ) · อ่านข้อมูลได้เฉพาะ Model ของหมวด (shared/category-models.json)
  "symbol": "macwindow",            // SF Symbol ในตู้/แถบ
  "size": { "w": 504, "h": 124 },   // ขนาดตอนวาง · ไม่ใส่ = design
  "order": 16,                      // ลำดับในตู้ (ในหมวดเดียวกัน) · ไม่ใส่ = ท้ายสุด
  "tier": "personal",               // verified · connected · personal · ไม่ใส่ = ของหมวด
  "ownSurface": true,               // วาดพื้นเอง → chrome ไม่ครอบแผ่น · ตั้งต้น false
  "ownBorder": true,                // วาดเส้นขอบเอง → chrome ไม่วาดเส้น (ชุดห้าสไตล์ · สติกเกอร์)
  "surfaces": ["glass", "dim"],     // ตัวเลือก "กล่อง" ในถาด ตัวแรก = ตั้งต้น · ไม่ใส่: ownSurface ? [] : [glass dim clear]
  "surfaceNames": { "glass": "สว่าง", "dim": "มืด" }, // ชื่อที่ต่างจากชื่อกลาง (กระจก · เข้ม · ไม่มีพื้น · กระจก)
  "border": false,                  // ขอบตั้งต้น · ไม่ใส่ = !ownSurface
  "photo": true,                    // อัปโหลดรูปได้ (ตราปั๊มอยู่ในผังเองและมีตลอด)
  "keepAspect": true,               // ผังตายตัว — ความสูงต่ำสุด = สัดส่วนที่ออกแบบ
  "fullBleed": true,                // รูปชนขอบ ไม่มีระยะขอบใน
  "resize": false,                  // ปิดหมุดย่อขยาย · ตั้งต้น true
  "controls": [ … ],                // **ตัวเลือกทั้งหมดที่ผู้ใช้ปรับได้** (ข้างล่าง) · ค่าเก็บที่ options[opt] ของชิ้น · ไม่ใส่ = ไม่มีอะไรให้ปรับ
  "kit": { "look": "cream" },       // ชุดห้าสไตล์: หน้าตาของใบ (purple|cream|gingham|night|mac) · สีพื้น/ขอบจากพื้นหลังการ์ด
  "skin": "paper",                  // วัสดุแผ่นสติกเกอร์ paper · glass (โทเคน pop.*)
  "stamp": "followers",             // ป้าย Verified by Sale Here: followers · insight · work · ไม่ใส่ = ไม่มีป้าย
  "stampAt": { "tone": "light", "top": 1.5, "trailing": 10 }, // ใบที่ไม่มีช่องหัวข้อ — chrome วางป้ายมุมขวาบน (tone ink · dark · light)
  "motion": "anchored",             // ท่าเข้า deep · mid · light · anchored (ใบที่มีท่าข้างในต้อง anchored)
  "pinned": true,                   // Sale Here วางให้ทุกการ์ด ตรึงก้นหน้า (ตรารับรอง · ห้ามลบ/ย้าย/ยืด · PageLayout ให้ที่ก่อนใคร)
  "replaces": ["statWrapped"]       // ชื่อชนิดเก่าที่ถอดแล้ว — การ์ดเก่าเปิดมาเป็นใบนี้
}
```

คีย์ที่แอปอ่านมีเท่านี้ (= `WIDGET_KEYS` ใน check-widgets.mjs = `WidgetSpec.Widget` ของ iOS/Android = `kindInfo` ของเว็บ) · คีย์ใหม่ต้องเพิ่มพร้อมกันทั้ง 4 ที่

**ตัวเลือกของใบ (`widget.controls`)** — กติกาเดียวทุกใบ (19 ต.ค. 2569): ถาดวาดแถวตามรายการนี้ตามลำดับ (หลังแถว "กล่อง" ก่อนแถว "ขอบ")
ค่าที่ผู้ใช้เลือกเก็บที่ `options[opt]` ของชิ้น — **ค่าตั้งต้นไม่เก็บ** ชิ้นที่ไม่ได้ปรับมี `options` ว่าง · ค่าเป็นข้อความเสมอ
front/backend ไม่ต้องรู้จักชื่อตัวเลือก อ่านจากไฟล์ผังอย่างเดียว (Android วาดได้เฉพาะ `segment` — ช่องติ๊ก/สวิตช์/− n + ยังเป็นช่องว่างเดิม)

ชิ้นในไฟล์การ์ด = ฟิลด์หลัก `id kind x y w h surface border` + `options` (+ `photos` ใน API) — ชั้นข้อความ (`textBlock`) เก็บ `face` `tint` `scale` `align` `points` ใน `options` ด้วย ·
ไฟล์ก่อน 19 ต.ค. ที่มี `pattern` `kit` `pinned` `sealStyle` `keepPhotoBG` `noEmboss` แยกเป็นคีย์ อ่านได้ (แปลงเป็น `options` · ที่ไม่มีที่ไปถูกข้าม) ·
`pinned` ไม่ใช่ค่าในชิ้น — เป็นของชนิด (`widget.pinned`)

ตัวเลือกที่มีตอนนี้: `pattern` (ลาย · 12 ใบ · `if: surface=glass`) · `fill` `corner` (พื้นหลัง · มุม · ชุดห้าสไตล์ 50 ใบ) · `hide` `qr` `count` `mode` `noTime`/`noArea` (เนื้อหาของชุดห้าสไตล์)

| `type` | คีย์ | ทำอะไร |
|---|---|---|
| `checks` | `opt` (= `hide`) · `items` · `flags?` · `minItems?` | ช่องติ๊ก เก็บสิ่งที่ซ่อนคั่นด้วย `,` ที่ `opt` (หรือธงแยกตาม `flags` เช่น `{"time":"noTime"}`) |
| `pick` | `opt` · `items` · `minItems?` | เลือกหนึ่งจากรายการของหมวด (ตอนนี้ไม่มีใบไหนใช้) |
| `segment` | `opt` · `options: [[ค่า|null, ชื่อ]]` · `clears?` | ตัวเลือกคงที่ · เปลี่ยนแล้วล้างตัวเลือกใน `clears` |
| `switch` | `opt` · `default` | สวิตช์ (เก็บเฉพาะค่าที่ต่างจากตั้งต้น) |
| `stepper` | `opt` · `values` · `default` | − n + |

ทุกแถวมี `label` · `if` (`opt:k=v` · `hidden:key` · `surface=glass` · `bordered` · นำหน้า `!`) · `refit: false` (ไม่จัดกรอบใหม่) ·
`items` = คู่ `[[key, ชื่อ]]` หรือแหล่งของหมวด `socials` · `shownSocials` · `rates` · `ratePlatforms` · `categories`

**หมวด (15 หมวด · fix ในโค้ด)** `hero` `seal` `intro` `text` `followers` `audience` `tags` `brand` `verified` `photo` `showcase` `rate` `availability` `body` `contact` —
ค่าของหมวดอยู่ในโค้ด `WidgetFamily` (iOS/Android) · `CATEGORY_TIER` (เว็บ):

| ค่าของหมวด | ตาราง |
|---|---|
| ส่วนของตู้ `group` | เกี่ยวกับฉัน = hero seal intro text followers audience tags body · รับงาน = rate availability contact · ผลงาน = brand verified photo showcase |
| ชั้นสิทธิ์ `tier` ตั้งต้น | connected = followers audience rate · verified = brand verified seal · อื่น = personal (ใบที่ต่างใส่ `widget.tier` ทับ เช่น `typeMarquee`) |
| หัวข้อ Star Profile ที่ล็อก `topic` | hero/tags → สายงาน · followers → ช่องทาง · intro → แนะนำตัว · rate → เรต · audience → insight · seal → ยืนยันตัวตน · brand/verified → ผลงานผ่าน Sale Here · availability/body → ตามชื่อ · text/photo/showcase/contact ไม่ล็อก |

**ชั้นข้อความ** (`textBlock` ในไฟล์การ์ด) ไม่ใช่ widget — ไม่มีไฟล์ผัง ไม่อยู่ในตู้ · นิสัยของมันอยู่ที่ `TextBlock.layer` (iOS/Android · `WidgetKind.textLayer`) / `TEXT_LAYER_META` ใน `kinds.js` · กล่อง = ตัวอักษรพอดี วาดด้วย `CardScreen.fitTextBlock` · คีย์ในไฟล์การ์ดยังเป็น `textBlock` การ์ดเก่าจึงเปิดได้

### 3.4 พื้นผิวกับขอบ — ใบที่วาดพื้นเองต้องอ่านเอง

ชิ้นทุกชิ้นมีค่า `surface` (`glass` กระจก · `dim` แผ่นเข้มทึบ · `clear` ไม่มีพื้น · `pane` กระจกของ chrome) กับ `border` จากถาดของ editor

- ใบที่ **chrome วาดแผ่นให้** (`widget.ownSurface` ไม่ใส่/false): chrome วาดแผ่น/ขอบ/ระยะขอบในเอง ผังไม่ต้องรู้
- ใบที่ **วาดพื้นเอง** (`ownSurface: true` — โปสเตอร์ · สำรับกระดาษ · สติกเกอร์ · สแครปบุ๊ก · ชุดห้าสไตล์ · หน้าต่าง): chrome ไม่วาดอะไร (ยกเว้น `pane` ที่ chrome ครอบกระจกให้แล้วส่ง `pane` ลงมา) —
  **ผังต้องมีเงื่อนไขเอง** ไม่งั้นถาดพื้นหลังไม่มีผล (บั๊ก 14 ต.ค. 2569: ผังวาดแผ่นตายตัวทุกใบ)
  ```jsonc
  { "type": "rect", "fill": "plate",  "if": "papered" }            // แผ่น/กระดาษ เฉพาะตอนมีพื้น
  { "type": "text", "color": "plateInk", "if": "papered" }         // หมึกบนแผ่น
  { "type": "text", "color": "ink",      "if": "!papered" }        // ไม่มีพื้น/บนกระจก chrome → หมึกของการ์ด
  ```
  สีของทุกสำรับมาจากตัวแปลงเดียว `SpecPalette` (6 บทบาท × 3 พื้น §4 — 20 ต.ค. 2569; `Ed.skin` `Pop` `KitLook` `ScrapTone` ไม่ใช่แหล่งสีแล้ว) — ผังต้องให้ผลเดียวกันทุกค่า `surface` · ชิ้นส่วนเหล่านี้ไม่รู้ชื่อ widget
- `bordered` ของใบที่วาดพื้นเอง: ผังวาดเส้นขอบเองด้วย `stroke` + `"if": "bordered"` (chrome วาดให้เฉพาะใบที่มันวาดแผ่น)

## 4. token สี — 6 บทบาท × 3 พื้น (20 ต.ค. 2569)

ผังเขียนแค่ **บทบาท** ของสี ไม่ใช่สี · สีจริงคิดจาก (บทบาท, พื้นที่ใบนั่ง, ธีมการ์ด) ในตัวแปลงเดียวต่อแพลตฟอร์ม:
iOS `SpecPalette.swift` · Android `SpecPalette.kt` · เว็บ `specPalette()` ใน `theme.js` (พอร์ตบรรทัดต่อบรรทัด)

| ชื่อ | ความหมาย |
|---|---|
| `bg` | พื้นของที่ที่ใบ/โหนดนั่งอยู่ (กระดาษ แผ่น กล่อง) |
| `bg2` | พื้นชั้นที่สอง — กล่องย่อย ชิป แถบหัว (= `bg` ขยับเข้าหาหมึก 6%) |
| `ink` | ตัวหนังสือบนพื้นนั้น (บนการ์ดผ่านตัวยันความอ่านออก `InkStyle.text`) |
| `ink2` | หมึกจาง — ป้าย ตัวรอง (= `ink` ขยับเข้าหากระดาษ 38%) |
| `accent` | สีเน้นของการ์ด ปรับให้เหมาะกับพื้นนั้น |
| `line` | เส้นขอบ เส้นคั่น (= `ink@0.2`) |
| `white` `black` `clear` `#RRGGBB` `#RRGGBBAA` | ตรงตัว |

ทุกชื่อต่อท้าย `@0.45` = ความทึบ · บนการ์ด `ink@a` `ink2@a` `line@a` `bg2@a` วิ่งผ่าน `InkStyle.text/ghost/line/fill(a)` (ค่าตั้งต้น 1 · 0.5 · 0.12 · 0.14)

**พื้น** (`SpecSurface`): `widget.on` = พื้นตั้งต้นของใบ (ไม่ใส่ = `card`) · โหนดที่นั่งคนละพื้นใส่ `"on"` ของตัวเอง

| พื้น | กระดาษ (`bg`) | หมึก (`ink`) | สีเน้น (`accent`) | ใคร |
|---|---|---|---|---|
| `card` | ขาว / เกือบดำ ตามโทน | `InkStyle` ของธีม | `cardAccent` | ใบที่นั่งบนการ์ดตรง ๆ (39) |
| `light` | ครีมอมเฉดการ์ด `hsb(hue, 0.10, 0.97)` · คู่สี = สีอ่อน (+7% เข้าหาสีเข้มเมื่อการ์ดสว่าง) | ถ่านอมเฉด `hsb(hue, 0.06, 0.11)` · คู่สี = สีเข้ม | `rawAccent.onLightSurface()` · คู่สี = สีเข้ม | กระดาษ Canva สติกเกอร์ สแครปบุ๊ก บรรณาธิการ (64) |
| `dark` | `PosterPlate.plate` · คู่สี = สีเข้ม | `PosterPlate.cream` · คู่สี = สีอ่อน | `rawAccent` | โปสเตอร์ + Canva แบบกลางคืน (19) |

ธง `kit.dark` ในเงื่อนไข `if` = ใบนี้มี `on: dark` (ไม่ใช่ความมืดของสีพื้น Canva อีกแล้ว)

**กติกา "ไม่มีแผ่น"**: ถ้าใบนี้ไม่ได้วาดแผ่นของตัวเองอยู่ (พื้นผิว `clear`/`pane` · หรือชุด Canva เลือก `fill=clear`) โหนดที่ไม่ได้ระบุ `on` เองจะใช้สีของ `card` แทนพื้นตั้งต้น — ตัวหนังสือนั่งบนการ์ดตรง ๆ ต้องใช้หมึกการ์ด (บนการ์ดคู่สี หมึกของ `light` = สีเข้มของคู่ = สีการ์ด → หายทั้งใบ · 20 ต.ค. 2569) · โหนดที่ระบุ `on` เอง (โพลารอยด์ ป้าย) = วัตถุที่วาดพื้นของมันแน่ ๆ จึงใช้พื้นนั้นเสมอ (`SpecPalette.noSheet` ทั้ง 3 แพลตฟอร์ม)

**ประวัติ**: 40 ชื่อ (14 ต.ค. — แต่ละสำรับตั้งชื่อสีของตัวเองตอนแปลงจาก Swift) → 6 ชื่อ × 6 พื้น (20 ต.ค. เช้า `color-tokens-v2.mjs`) → 6 ชื่อ × 3 พื้น (20 ต.ค. เย็น `color-surfaces-v3.mjs` — ผู้ใช้: "ทำไมต้องแยก 6 · เพิ่ม JSON ต้องไม่ build") · พื้นสว่าง 4 แบบเดิมต่างกันแค่สีกระดาษของตัวเอง ตอนนี้กระดาษมาจากธีมเดียวกันทุกใบ → สไตล์ใหม่ = JSON ล้วน · สูตร `KitLook` `Pop` `ScrapTone` `Ed.skin` ไม่ถูกเรียกจากตัวแปลงสีแล้ว (ลบได้เมื่อไม่มีที่อื่นใช้) · layout ไม่เปลี่ยน (solver ไม่อ่านสี) · ภาพเทียบ: `present/color-surfaces-v3/`

## 5. อัลกอริทึมของตัวคำนวณ (ต้องได้ตัวเลขเท่า fixture ทุก byte · ปัด 2 ทศนิยม)

1. **ขยาย**: `chips` → ลูกจริงจาก `list` ด้วย `each` (`where` → `sort` → `group` → `limit`) · โหนดที่ `if` เป็นเท็จหายไป · `$i` ใน slot/ข้อความแทนด้วยลำดับ
2. **ขนาดตัวอักษร**: `size` → ใบแรกของ `sizeWhen` ที่จริงบน box (ก่อนทุกอย่าง) → คูณขั้นที่ผู้ใช้ตั้งให้ช่องนั้น (XS 0.60 · S 0.78 · M 1 · L 1.30 · XL 1.70 · XXL 2.20 · คุม 6–160) · ฟอนต์ของช่องที่ผู้ใช้เลือกชนะ `face`
3. **intrinsic(node, availW, availH)** = ขนาดที่ต้องการ:
   - ระบุ `w`+`h` → ตามนั้น · `aspect` + แกนเดียว → อีกแกนคิดจากสัดส่วน
   - `text` → วัดที่ความกว้าง `availW` (nil = บรรทัดเดียวไม่จำกัด) ด้วย `fitText` (ข้อ 6) · `icon` → `size` · `image` → เต็มที่ที่มี · `rect`/`spacer` → 0 · `line` → กว้างเต็ม สูง 1
   - คอนเทนเนอร์ → `contentSize` + pad: `col` = สูงรวม + gap · กว้างสุดของลูก (ลูกวัดที่ `availW − pad`) · `row` ไม่ wrap = กว้างรวม + gap · สูงสุดของลูก (ลูกวัดโดยไม่จำกัดกว้าง) · `row`/`chips` wrap = บรรจุบรรทัด (ข้อ 5) · `stack` = max ของลูก (+dx/dy)
   - แล้วคุมด้วย min/max
4. **layoutFlex (col/row)** ในกล่อง inner = frame − pad · แกนหลัก = สูง (col) / กว้าง (row):
   - แกนขวางของลูก: ระบุ → ตามนั้น · `fill` หรือ (alignSelf ?? align ของแม่) = `stretch` และไม่มี aspect → เต็ม inner · ไม่งั้น hug · คุม ≤ inner และ min/max
   - ฐานแกนหลัก: ระบุ → ตามนั้น · `fill` → 0 และ grow ≥ 1 · `aspect` → จากแกนขวาง · ไม่งั้น intrinsic (text ใน col วัดที่กว้าง = แกนขวางที่ได้; ใน row วัดบรรทัดเดียว)
   - `free = main − gaps − Σฐาน` · free > 0 แจกตาม `grow` (ชิ้นที่ชน max หยุดรับ วนแจกใหม่ ≤ 8 รอบ) · free < 0 หักจากชิ้นที่ `shrink` > 0 ตามสัดส่วน `shrink × ฐาน` (ชิ้นที่ชน min หยุด วน ≤ 8 รอบ)
   - วางจาก `justify` (start/center/end/between/around) · แกนขวางตาม alignSelf ?? align
5. **layoutWrap (row wrap / chips)**: วัดลูกทีละตัวที่กว้าง = inner (hug) · greedy: เกินบรรทัดขึ้นบรรทัดใหม่ (ลูกแรกของบรรทัดไม่ขึ้นใหม่แม้กว้างเกิน) · บรรทัดสูง = ลูกสูงสุด · ในบรรทัดวางตาม `justify` · บรรทัดเรียงลงด้วย `gap` · แกนขวางในบรรทัดตาม alignSelf ?? align (ตั้งต้น start)
6. **fitText**: วัด (สตริง, ฟอนต์, กว้าง) → (กว้างที่ใช้, จำนวนบรรทัด) · `growTo` ก่อน (ขยายทีละ 1 จนบรรทัดเดียวเต็ม) · เกิน `maxLines` หรือบรรทัดเดียวกว้างเกิน → ลด 0.5 จนพอหรือถึง `shrinkTo` · บรรทัดที่แสดง = min(บรรทัดที่วัด, maxLines) · สูง = บรรทัด × lineHeight(ฟอนต์) × `lineHeight` · ว่าง = 1 บรรทัด กว้าง 0
   - **ตัวคำนวณบอกแค่ขนาด+จำนวนบรรทัด** ตัววาดตัดท้ายด้วย … ถ้าสตริงยาวเกินบรรทัดที่บอก
   - lineHeight ของฟอนต์ = ค่าจากไฟล์ฟอนต์ (ascender − descender + lineGap) ปัด 2 ทศนิยม · ความกว้างจากกลิฟของไฟล์เดียวกัน ปัดขึ้น 2 ทศนิยม · ตัดคำไทยด้วยพจนานุกรม ICU (Android/Web) vs CoreText (iOS) **อาจต่างได้** — ดู §8
7. **stack**: ลูกขนาดระบุ/hug (`rect`/`image`/คอนเทนเนอร์ไม่ระบุ = เต็ม inner · text ไม่ระบุกว้าง = เต็มกว้าง สูง hug) · วางด้วย `place` + dx/dy · ไม่ clip (เว้นแต่ `clip`) · ลูกถูกคุม ≤ ขนาดแม่
8. **fitScale** (ถ้าไฟล์มี): ความสูงตามเนื้อหา > box → ลองขั้นถัดไปในกล่อง `box/k` จนพอดี · ตัววาด scale ด้วย `k` · fixture จด `scale`
9. **ออก**: ทุกโหนดเป็นกล่องสัมบูรณ์ใน box (x y w h) + ผลข้อความ (string, size, lines, slot) + depth · ปัด 2 ทศนิยม
10. **ขั้นต่ำที่อ่านออก** (14 ต.ค. 2569 · `SpecLegibility` · Swift + Kotlin อัลกอริทึมเดียว) — ผู้ใช้หดกรอบแล้วตัวหนังสือเล็กจนอ่านไม่ออกตอน export
   - เข้า: `renderScale` = `s` ของ chrome (§2 · iOS env `widgetRenderScale` · Android `LocalWidgetRenderScale`) · ขนาดที่วาดจริงบนการ์ด = size × renderScale × fitScale
   - ขั้นต่ำ (pt บนการ์ด) = min(ขนาดในผัง, **หัว 18** / **เนื้อหา 12**) · หัว = `role: title` หรือขนาดในผัง ≥ 18 · `deco` ไม่มี · ไม่เกินขนาดในผัง → ขนาดตั้งต้นไม่เปลี่ยน มีผลเฉพาะตอนหด
   - ขนาดเริ่มของข้อความ = design + (ขั้นต่ำ/สเกล − design) × `strength` · ที่ไม่พอ = ย่อลงได้ถึงพื้นเดิมของผัง (`shrinkTo`/design) — ไม่ตัด … เพราะขั้นต่ำ
   - กล่องตายตัว (`w` `h` `minW/maxW/minH/maxH`) ของข้อความ และของกล่องที่ห่อข้อความโดยตรง (pill/ชิป) คูณด้วยอัตราที่ตัวอักษรลูกโตมากสุด
   - `solve`: รอบ strength 1 → ไม่มีใครถูกยก = จบ · ไม่งั้นคำนวณรอบผังเดิม (strength 0) เป็นเกณฑ์ แล้วลอง 1 · 0.66 · 0.33 ใช้ขั้นแรกที่ผ่าน · ไม่ผ่านเลย = ผังเดิม
   - ผ่าน = (ก) ข้อความไม่เล็กกว่ารอบเดิม เว้นแต่ยัง ≥ ขั้นต่ำของมัน (ข) ข้อความไม่ล้นกล่องเกิน max(0.5, 30% ของ size) ที่เดิมไม่ล้น (ค) รูป/ไอคอนด้านสั้น ≥ 60% ของเดิม (ง) ไม่มีชิ้นหลุดกรอบแม่ (>1) หรือคู่ข้อความทับกัน (>1×1) ใหม่ที่รอบเดิมไม่มี
   - ผล: ที่ 174×174 ตัวเล็กสุดมัธยฐาน 5 → ~8.5 pt · ~14 ใบโปสเตอร์/สแครปที่แน่นอยู่แล้วคงผังเดิม
   - fixture จด `renderScale` ต่อเคส · เทียบก่อน/หลังบน iOS: เปิดแอปด้วย `-legibilityOff YES` (DEBUG) · แผ่นเทียบ `present/text-legibility/`
   - **ยังไม่ทำ**: ขนาดกรอบต่ำสุดต่อใบ · export พอร์ตเป็น 3 รูป

## 6. ตัววาด — primitive ที่ต้องมีครบทุกแพลตฟอร์ม

| โหนด | วาด |
|---|---|
| col/row/stack/chips/spacer/rect/line | พื้น (`fill`/`gradient`) มุม `radius`/`circle`/`shape` · ลาย `pattern`/`platePattern` · เส้น `stroke` ด้านใน · เงา (sigma) · `opacity` · `rotate` · `clip` — ไม่มีค่า = ไม่วาด (`line` ตั้งต้น `ink@0.12`) |
| text | สตริงจาก fixture ด้วยฟอนต์/ขนาดจากตัวคำนวณ · `lines` บรรทัด ตัดท้าย … · จัด `textAlign` · `mixHead` สองฟอนต์ · **ห้ามใช้ autosize ของแพลตฟอร์ม** · ช่องที่ `slot` ผูกและไม่ `readonly` = แตะแก้ได้ (iOS: `editableText`) |
| image | รูปช่อง `photo`/`photoRef`/`src` แบบ cover/contain + `fit {dx,dy,zoom}` ของผู้ใช้ (สูตรเดียวกับ `PhotoFit`) · clip ตาม `radius` |
| icon | ชื่อที่ขึ้นต้น `http` (เช่น `$logo` ของ brands) = โหลดจากเน็ตเหมือน `url:` · ตามชื่อ: `starLockup` (โลโก้ ST★R template สี tint) · `starSeal` (ตรายืนยัน) · `saleHereStar` · `qr` (QR ลิงก์การ์ด) · `provenance` / `provenance:socials` / `provenance:photo` / `provenance:screenshot` / `provenance:profile` (ป้ายที่มาของข้อมูล) · `verifiedBadge` (ป้าย Verified by Sale Here) · `byline` / `byline:dark` / `byline:light` (ป้าย "Verified by Sale Here" แบบบรรทัด ตัวอักษร = สูง×0.45 — คนละอันกับ `sh:verifiedPill` ตราฟ้า) · `verifiedSeal` (ตราใหญ่ กลีบหยัก+เครื่องหมายถูก) · `guilloche` (ลายกิโยเช่วงกลม) · `ringText` (ข้อความ `text` วนรอบวงกลม ขนาด `size`) · `washi` (เทปวาชิ) · `binderClip` · `paperClip` · `barcode` · `bow` · `spark` · `windowDots` (ปุ่มหน้าต่าง 3 จุด) · `embossedLockup` (โลโก้ปั๊มนูน) · `ph:<name>` (Phosphor bold ชื่อ kebab-case ตามไลบรารี เช่น `ph:paper-plane-tilt` · ต่อท้าย `-fill` = น้ำหนัก fill — ชุดเดียวกัน 3 แพลตฟอร์ม · Android `SpecIconCoverageTest` (ใน SpecSolverFixtureTest.kt) ตรวจว่าทุกไอคอนในผังมีจริง) · `sh:<name>` (asset ของแอป: instagram tiktok youtube facebook x lemon8 line sealCheck verifiedPill star wordmark watermark qr — `line` = โลโก้ LINE ชุด about-social เพิ่ม 20 ต.ค. 2569: iOS `about-social-line.imageset` (PDF) · Android `drawable-nodpi/about_social_line.png` · เว็บผ่าน `SH` ใน web-icons.mjs) · `SpecIconCoverageTest` ตรวจทั้งชื่อในผังและชื่อที่ `SpecData.kt` สร้างเอง (`sh:`/`ph:` ของ `contacts` + `sh:<platform>` ทุกช่อง) · `url:` (โลโก้จากเน็ต) · ชื่อ asset ตรง ๆ · เว็บเสิร์ฟทุกชื่อที่ `/card/icon/<ชื่อในผัง>` |

ชิ้นส่วนกลางที่ไอคอน/token เหล่านี้ใช้ (iOS `Views/Widgets/Primitives/`: `VerifiedSeal` `QRCode` `Sparkle` `SocialProvenance` `WindowChannel` `CutoutPlane` `EditorialInk` `PopInk` `KitLook` `FlowLayout`) เป็นของกลาง — ไม่รู้ชื่อ widget · widget ไหนก็เรียกได้ด้วยชื่อเดียวกัน

สิ่งที่ยอมให้ต่างได้ (ไม่ใช่บั๊ก): anti-alias ขอบตัวอักษร · kernel ของ blur/เงา (±2%) · squircle vs rounded ที่มุม

**ตัววาดชุดที่สองของ iOS — UIKit/iOS 16 (20 ต.ค. 2569 · `StarCard/StarCard/Render/`)**: salehere-ios เป็น UIKit 16.6 จึงมี painter
ที่รับกล่องชุดเดียวกันแล้ววาดด้วย CoreAnimation/CoreText ล้วน ๆ (`SpecWidgetView` · `SpecChromeView` · `SpecRenderShapes/Patterns`)
ทุกอย่างที่ขึ้นกับแอปผ่าน `SpecRenderContext` (สี token · ฟอนต์ · รูป · asset · ไอคอน) — ต้นแบบมี `AppRenderContext` ใน `Views/Export/RenderABExport.swift`
คอมไพล์ที่ iOS 16.0 ได้จริง: `Packages/StarCardRender` (symlink ไฟล์ชุดเดียวกัน + `WidgetSpec.swift` + `SpecSolver.swift`) ·
`swift build --triple arm64-apple-ios16.0-simulator --sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)"` · วิธีย้ายอยู่ใน `Render/README.md`
สิ่งที่ยอมให้ต่างเพิ่มจากข้างบน: กระจก = `UIBlurEffect` แทน Liquid Glass · `mixHead` ย่อทีละ 2% (ไม่ใช่ `minimumScaleFactor`) · การย่อรูป (resampling)

## 7. fixture = สัญญา

`-exportSpecs` (iOS DEBUG · ใส่ `-exportPerson` ด้วยเสมอเพื่อให้มีรูปคน) เขียน `Documents/Specs/fixtures/<kind>.json` + `cell-<kind>-<probe>.png`:

```jsonc
{ "kind": "heroMinimal", "design": [366, 124], "inset": 12,
  "cases": [ { "probe": "design", "box": [342, 100], "renderScale": 1, "scale": 1,
               "boxes": [ { "id": "r/1", "type": "text", "x": 0, "y": 18.34, "w": 342, "h": 57.1,
                            "text": "Tarmjaipa", "size": 40, "lines": 1, "slot": "name" }, … ],
               "measures": [ … ], "lineHeights": { … }, "data": { "texts": …, "lists": …, "flags": …, "fonts": … } }, … ] }
```

กรอบทดสอบ 6 แบบต่อใบ: `design` · `tall` (×2 สูง) · `small` 174² · `large` 366² · `strip` (สูง 60% · อย่างน้อย 60) · `narrow` 240 กว้าง ×1.4 สูง · ชุดห้าสไตล์ไม่มีกรณี `style-*` แล้ว (19 ต.ค. 2569: แต่ละหน้าตาเป็นชนิดของตัวเอง)
fixture จด **จากรอบที่วาดจริง** (`SpecExport.capture` ใน `SpecPainter`) ทั้งกล่องราก (ทศนิยมเต็ม) · `scale` ของ `fitScale` · `renderScale` ·
ทุกคำถามที่ตัวคำนวณถามตัววัด (`measures` · `lineHeights`) และแหล่งข้อมูล (`data`: texts · lists · flags · fonts)

สำเนาล่าสุดอยู่ `present/spec-fixtures/` (`./sync.sh <udid>` ดึงจากซิม → `fixtures/` 81 ไฟล์ + `cells/` + `sheet.png` + `STATUS.md`) · `aboutNote` ยังไม่มี fixture (เขียน JSON อย่างเดียว ยังไม่ได้ export)

**Android** พิสูจน์สองชั้น (`present/spec-parity/run.sh [ios-udid]` → `out/report.html`):
1. **อัลกอริทึม** — `SpecSolverFixtureTest` (JVM · ต้องตั้ง `JAVA_HOME` เป็น jbr ของ Android Studio) เล่นคำตอบของ iOS ซ้ำทุกข้อ แล้วต้องได้กล่องเท่ากันทุกกล่อง · ถามสิ่งที่ iOS ไม่ได้ถาม = ล้ม → **81/81**
2. **ทั้งเส้นทาง** — ตัวส่งออกบนเครื่อง (`--es exportSpecs 1`) วาดทุกกรณีด้วยข้อมูลของ iOS (`ReplayData` · fixture + รูปพอร์ตก๊อปเข้า filesDir ด้วย `run-as`) แต่ตัววัด/ตัวคำนวณ/ตัววาด/chrome ของ Android
   → `compare.py` เทียบตัวเลข + การวัดตัวอักษร + ภาพทีละพิกเซล · ล่าสุด 98.9% ของการวัด 7,939 ครั้งเท่าทุกบิต · 70/80 ใบกล่องเท่าทุกกล่อง
ผังของ Kotlin อ่านแบบเข้มงวด (`model/WidgetSpec.kt`: `ignoreUnknownKeys = false`) — คำใหม่ในผังที่ Android ยังไม่รู้จักทำให้เทสต์ล้มทันที
กติกาตัววัดให้ตรง CoreText อยู่ใน `AndroidSpecMeasurer` (ฟอนต์ไฟล์เดียวกัน · กลิฟเป็นหน่วยฟอนต์จำนวนเต็ม · Σ แล้ว ceil 2 ทศนิยม · tracking+kerning นับตัวที่ไม่ใช่ Mn/Me · นับช่องว่างท้ายบรรทัด · ตัดคำ ICU เอง)

**UIKit (iOS 16) เทียบ SwiftUI** (`-exportRenderAB -exportPerson` → `Documents/RenderAB/{swiftui,uikit}` · `present/render-ab/run.sh <udid> [--launch]` → `out/report.html`):
วาดทุกใบ × 6 กรอบด้วยตัววาดทั้งสองจาก **กล่องชุดเดียวกัน** (จดจากรอบวาดของ SwiftUI ด้วย `SpecExport.capture`) · พื้นผิว `.clear` ไม่มีขอบ พื้นโปร่ง = เทียบ painter ล้วน
(+ ป้าย Verified มุมขวาบนของ chrome) · ตัวเลขตรงโดยนิยาม · ภาพ 20 ต.ค. 2569: 122 ชนิด · ต่าง <1% 7 ใบ · 1–5% 103 ใบ · ≥5% 12 ใบ (สูงสุด 8.4% = รูปถ่ายที่ย่อ) · เฉลี่ย 2.7% · มัธยฐาน 2.3%
ที่เหลือคือ anti-alias ขอบตัวอักษร/เส้นโค้ง · resampling ของรูป · ขาวดำ (`mono`) ที่เมทริกซ์ความสว่างต่าง

**เว็บ** พิสูจน์สองชั้นเหมือนกัน (`cd sync-server/web && npm test` = ทั้งสอง · ต้อง `cd sync-server && npm install` ครั้งแรก):
1. **อัลกอริทึม** — `node sync-server/web/test/replay.mjs [kind…]` เล่น fixture ซ้ำด้วย `spec-solver.js` (ตัววัด+ข้อมูลจาก fixture) → **122/122** (20 ต.ค. 2569)
2. **ตัววัดข้อความ** — `node sync-server/web/test/measure-parity.mjs [kind…] [--explain <คำ>]` เปิด Google Chrome ของเครื่องแบบ headless (puppeteer-core · ไม่โหลด Chromium)
   โหลดฟอนต์ด้วย `loadFonts()` ตัวเดียวกับหน้าเว็บ แล้วให้ `WebMeasurer` (`web/js/measure.js`) **วัดเอง** ทุกคำถามที่ iOS จดไว้ (`measures` · `lineHeights`)
   → `test/out/measure-parity/summary.json` (รูปแบบ `worstMeasures` เดียวกับ compare.py) + `diffs.json`
   **20 ต.ค. 2569: 19,605 คำถาม (ไม่ซ้ำ) · กว้างต่างไม่เกิน 0.01 = 100% · ไม่ต่างเลย 99.55% · จำนวนบรรทัดเท่ากัน 100% · lineHeight 3,850/3,850 · 122/122 ชนิด**
   (ก่อนแก้: 91.2% / 98.2% บรรทัด) กติกาที่ต้องตรง CoreText อยู่หัวไฟล์ `measure.js`: หน่วยฟอนต์จำนวนเต็มต่อกลุ่มอักษร จัดรูปทั้งย่อหน้า (kerning ข้ามรอยต่อบรรทัดยังอยู่) ·
   Σ `หน่วย × (size/1000)` แบบ double ทีละกลุ่ม · จุดตัดบรรทัด = ICU UAX #14 ของเบราว์เซอร์ (กล่องกว้าง 0 — ไม่ใช่ `Intl.Segmenter` แบบคำ ที่ตัด "BUILDING|..." "@maneerat|.review") ·
   ความกว้างบรรทัดไม่เกินกล่อง (ช่องว่างท้ายที่ล้น / กลุ่มเดียวที่กว้างกว่ากล่อง iOS รายงานเท่ากล่อง) · `tracking` บวกท้ายกลุ่มสุดท้ายห้อยได้ตอนตัดสินพอดีบรรทัด และไม่นับที่บรรทัดสุดท้ายของข้อความหลายบรรทัด (บรรทัดเดียวนับ)
   · เทียบตา `sync-server/web/dev/gallery.html`

**ผ่าน = ต่างไม่เกิน 0.01** ยกเว้นข้อความที่ตัดคำไทยต่างกัน (ดู §8) · ใบที่ไม่ผ่านคือบั๊กของ solver/ตัววัด **ไม่ใช่ของผัง — ห้ามแก้ JSON เพื่อให้แพลตฟอร์มเดียวตรง**

**"ไม่มีอะไรเปลี่ยน"** (ใช้ตอน refactor ตัววาด/นิสัย ไม่ใช่ตอนออกแบบ): iOS `-exportBaseline` → `traits.json` (นิสัยทุกใบ) + 667 PNG (ทุกใบ × พื้นผิว × ขอบ × ลาย × สไตล์) ก่อน/หลัง ต้องเท่าทุก byte (`galleryPost__paper` กระพริบเองระหว่างสองรอบของโค้ดเดียวกัน) · Android `WidgetTraitsDumpTest` (env `TRAITS_OUT` `SPECS_DIR`) · เครื่องมือ A/B เก่า-ใหม่ (`-exportSpecAB`) ถูกถอดไปพร้อม view เดิม — แผ่นเทียบเก็บไว้ `present/spec-ab/`

## 8. ข้อความไทยกับการตัดคำ

ตัววัดของแต่ละแพลตฟอร์มใช้ **ไฟล์ฟอนต์เดียวกัน** (Noto Sans Thai Light…Black · Mitr) ความกว้างกลิฟจึงเท่ากัน
สิ่งที่ยังต่างได้คือ *จุดตัดคำไทย* (iOS CoreText vs ICU) ซึ่งเปลี่ยนจำนวนบรรทัดได้ในประโยคยาว (ผู้ใช้ 14 ต.ค. 2569: "เรื่องฟ้อนก็ตาม platform นะ เน้น layout และ space พอ")
ทางแก้ที่ตกลงไว้ (ยังไม่ทำ): เครื่องที่แก้ข้อความเก็บจุดตัด (`breaks`) ลงเอกสารการ์ด แล้วทุกแพลตฟอร์มตัดตามนั้น
ระหว่างนี้ fixture ของข้อความหลายบรรทัดอนุโลมให้ `lines` ต่างได้ ±1 แต่ `size` และกล่องของโหนดอื่นต้องเท่ากัน
ทุก face เป็นฟอนต์ที่ฝังมา (Noto Sans Thai · Mitr, OFL) — ไม่มีฟอนต์ระบบในผังแล้ว · ✱ ใน `typeMarquee` ยังตกไปฟอนต์ระบบ

## 9. สิ่งที่ไม่อยู่ในผัง (เป็นของแพลตฟอร์ม — แต่ต้องทำเหมือนกันทั้งสาม)

- แอนิเมชันเปิดการ์ด/พลิกหน้า (`pageScrub`) · ท่าเข้า (`widget.motion` บอกแค่แบบ) · ปุ่มแก้รูป/ข้อความที่ลอยทับ
- แผ่นของ chrome (กระจก/ทึบ/ขอบ/ลาย/ป้าย `stamp`) — อยู่รอบ box ตาม §2 · ค่าต่อใบจากบล็อก `widget`
- **การยืด/ย้ายในห้องแต่ง** (iOS 13 ต.ค. · Android + เว็บตาม 18 ต.ค. 2569): หมุดมุมเดียว (`sizeHandle`) กว้างอิสระ ≤ หน้า · สูงอิสระ · ระหว่างลาก `resizeLive` (ข้อมูลไม่ถูกแตะ) + `resizePush` (ใบที่ซ้อนแนวนอนและอยู่ต่ำกว่าถูกดันลงเป็นลูกโซ่ ไม่มีช่อง ไม่ดึงกลับ) · ยางยืดเกินที่ว่าง/ต่ำกว่าขั้นต่ำ · ปล่อยนิ้ว `endResize` เขียน w/h เป็น pt จำนวนเต็ม (ไม่ snap 6pt) · ใบ `pinned` ไม่ถูกดัน ไม่มีหมุด ไม่ย้าย
- **ตรารับรองที่ตรึง** (`widget.pinned` · `PinnedSeal` / `PageLayout.pinnedFrame` / `page.js pinnedFrame`): หนึ่งใบต่อการ์ด หน้าสุดท้าย · สตอรี่ = มุมขวาล่าง กว้างครึ่งหน้า · พอร์ต = ก้นช่องที่ 3 เต็มช่อง · y คิดจากก้นหน้าทุกครั้ง ไม่เชื่อ `y` ในไฟล์ · ยังเป็น `WidgetInstance` จริง (รูปแชร์/พรีวิว/JSON เห็นเหมือนใบอื่น)
- **ตัวจำผล** (ประสิทธิภาพ · 15 ต.ค. 2569): iOS `SpecSolveMemo` จำผลตัวคำนวณต่อ (ชิ้น · กรอบ · ข้อมูล · `SpecCatalog.generation`) · ตาราง `metas` แยกจากผังทั้งต้น (ถาดอ่านนิสัยหลายร้อยครั้งต่อเฟรม) · `IOSSpecMeasurer` cache ผลวัดตรงตัว · พรีวิวสไตล์ในถาดใช้ id คงที่ (`CardScreen.kitPreview`) — id สุ่มทุกเฟรมคือต้นเหตุกระตุก · เครื่องมือ DEBUG: `-benchKinds` (+env `BENCH_KIND` `BENCH_RENDER`) · env `HITCH=1` (นับเฟรมช้า พิมพ์ solve ms) · env `BENCH_STARTER=<kind>` (การ์ดหน้าเดียวใบเดียว) · Debug config ใช้ `-O`
- **โหลดผังจากเซิร์ฟเวอร์**: โหมดลองทำเท่านั้น (`LabSync` → `SpecCatalog.replace(with:)` จาก `/api/specs` · ไฟล์ที่อ่านไม่ผ่านถูกข้าม) · DEBUG `SpecCatalog.reload(from:)` อ่านโฟลเดอร์บน Mac โดยไม่ build · โหมดจริงยังฝังมากับแอป

## 10. สถานะ (20 ต.ค. 2569)

**82 / 82 ชนิดเป็น JSON ทั้งหมด** — ไม่มี view ต่อ widget ในโค้ดสามแพลตฟอร์ม (iOS ลบ 28 ไฟล์ 15 ต.ค.) · ไม่มีชื่อ widget ในโค้ด (`check-widgets.mjs` = 0) · ชนิดที่ไม่มีไฟล์ = ไม่มีในแอป (ไม่มี fallback)
หมวดที่มี: hero 9 · intro 8 · tags 7 · followers 10 · audience 7 · brand 4 · verified 3 · photo 17 · showcase 1 · rate 2 · availability 1 · body 1 · contact 11 · seal 1 (`proofSeal` · pinned) · text 0 (ชั้นข้อความไม่ใช่ widget)

**ชนิดที่ถอด 14 ต.ค. 2569 (16 ใบ · ผู้ใช้เลือกใน review.html · ห้ามเอากลับ)** — การ์ดเก่าเปิดมาเป็นใบที่ประกาศ `replaces`:
scrapFolder→scrapBadge · statWrapped→statPoster · interestTags→nicheTags · artPhotobooth→artFilmstrip · galleryMosaic→galleryMasonry · galleryStory→workReel · galleryTape→galleryStack · zineCover→wallMemory · scrapChat→proofWork · rateNeon→rateTags · popRatePaper/popRateGlass/scrapReceipt→kitRate · scrapStamp · flowCards · scrapLabel ถอดโดยไม่มีแทน (ตราถูกตรึงแล้ว · ข้อความจากโน้ตคนอื่นอ่านไม่ออก)

**ตั้งใจคงไว้เป็นโค้ด**: ชั้นข้อความ `textBlock` (ไม่ใช่ widget — §3.3c) · ชิ้นส่วนกลางใน `Primitives/` (ไอคอนมีชื่อ · สกิน) · ตาราง 15 หมวด

สิ่งที่ยังแสดงไม่ได้ในผัง (ทุกใบมี `notes` บอกส่วนที่ประมาณไว้ · ผล A/B สุดท้ายกับโค้ดเดิม 66/96 ใบต่าง <5% พิกเซล แย่สุด ~20%):
- ข้อความ: ไล่สี · scaleX · ตัดคำรูปแบบพิเศษ (เลขพันคั่นลูกน้ำจากรายการมีแค่แบบย่อ) · (หลายฟอนต์ในบรรทัดเดียวทำได้แล้วด้วย `mixHead` เฉพาะแบบคำแรก+เซริฟ)
- รูปร่าง/วัสดุ: กรอบคลื่น (wavy perimeter) · มุมไม่เท่ากันในกล่องเดียว · สามเหลี่ยม/path อิสระ · เงาสองชั้น · เส้นขอบไล่สี · ไล่สี 3 จุด · blur/glass/halftone/grain ของระบบ · รูกลมเจาะทะลุ (destinationOut) · marquee/mask
- เงื่อนไข/ข้อมูล: ชิ้นสุดท้ายของรายการ · เส้นคั่น *ระหว่าง* แถวเท่านั้น · เทียบสตริง (`$platform=instagram`) · รีวิว / `ages3` / payload ของ QR ไม่อยู่ใน data source · ตัวเลือกช่องรายชิ้น (`opt:chan`) อ่านได้แค่เป็นเงื่อนไข · ไอคอนต่อหมวด
- ตำแหน่ง: `dx`/`dy` เป็น % · จุดหมุดหมุนที่ไม่ใช่กลางกล่อง · ตัวนับที่โตตามความกว้าง (รูเฟือง/ขีดสมุด)

**ค้างตัดสินใจ / ยังไม่ทำ**
- **`owner.verified` คนละความหมายต่อแพลตฟอร์ม** (พบ 20 ต.ค. 2569 — ยังไม่แก้ รอตัดสิน): iOS = `VerifiedFacts.sealed || creator.verified` → sealed = ผ่าน KYC ของ Star Profile (`-labVerified` บังคับได้) · creator.verified = ฟอร์มสถานะ approved · Android = `VerifiedFacts.labForce || StarFlow.isVerified` (KYC) `|| creator.verified` (= **ทุกช่องโซเชียลที่เปิดไว้ยืนยันยอดผ่านการเชื่อมบัญชี/API** ไม่ใช่สถานะฟอร์ม) · เว็บ = `ctx.verified` (ไม่มีใครส่ง — main.js ไม่ตั้ง) `|| creator.verified` (= ทุกช่องไม่ใช่ `manual`) · ไม่มี intake = `MOCK.verified` (true) → การ์ดเดียวกัน ตราฟ้า/`has:owner.verified` ขึ้นบนแพลตฟอร์มหนึ่งแต่ไม่ขึ้นอีกแพลตฟอร์มได้ · ต้องเลือกหนึ่งความหมาย (แนะนำ = KYC ผ่าน ตามกติกา "Verified = KYC" 30 ก.ย.) แล้วให้ `LabDoc.Owner` ส่งธงนั้นให้ Android/เว็บ
- `avail` บน Android/เว็บยังคิดจาก `intake.availability.days × slots` ที่ iOS แบนมา (ทุกวันช่วงเดียวกัน) — iOS มีตารางรายวัน (`availWeek`) จึงออกได้หลายบรรทัด ("จ–ศ 17.00 เป็นต้นไป" + "ส อา ตลอดวัน") แต่อีกสองได้บรรทัดเดียว · ถ้าต้องเท่ากันทุกกรณีต้องส่ง `availWeek` ใน `IntakeData.availability`
- จุดตัดคำไทย `breaks` ในเอกสารการ์ด (§8)
- ขั้นต่ำที่อ่านออก: ขนาดกรอบต่ำสุดต่อใบ · export พอร์ตเป็น 3 รูป
- Android วาดตัวเลือกได้เฉพาะ `segment` (ลาย · พื้นหลัง · มุม · ราคา) — `checks` `switch` `stepper` ยังไม่มี
- ย้ายโค้ดแปลงข้อมูล API → ค่าพร้อมวาด ให้แยกต่อหมวด (ตอนนี้อยู่ `IOSSpecData` / `AndroidSpecData` / `data.js` ที่เดียว · ผลเท่าเดิม) · เว็บยังเติม `MOCK` เมื่อ API ไม่มี
- โหลดผังจากเซิร์ฟเวอร์ตอนเปิดแอปในโหมดจริง (มีแค่โหมดลองทำ)
- ข้อมูลที่ API ยังไม่มี (ให้ทีม API — `WIDGET-CATEGORY-PLAN.md` ข้อ 10C): insight ผู้ชม · แบรนด์/งานที่ผ่าน Sale Here · สัดส่วน · วิว/engagement ต่อช่องทาง · เว็บไซต์ (ต้นแบบมีแล้วทั้งสาม 20 ต.ค.) · `avail` เป็นข้อความ
- `aboutNote` ยังไม่มี fixture · Android บันทึกการ์ด lab ของ iOS แล้วขนาด `audiencePoster` ขยับ (362×209 → 378×201 · พฤติกรรมตอนโหลดเดิม)

## 11. ประวัติ

| วันที่ (2569) | เปลี่ยนอะไร |
|---|---|
| 28 ก.ย. | ตรวจ 81 ใบ × 3,472 ค่า iOS vs Android: เท่า 4 · ต่าง 59 → ที่มาของสัญญานี้ |
| 13 ต.ค. | เครื่องยนต์ผัง (`WidgetSpec` · `SpecSolver` · `SpecPainter`) · กติกากรอบเดียว §2 · ถอดกริด 3 ขนาด กลับเป็นยืดอิสระ + หมุดมุมเดียว · fixture `-exportSpecs` |
| 14 ต.ค. | แปลงครบ 96/97 (ทุกตระกูล · ชุดห้าสไตล์ = ผังเดียว + variants) · คำศัพท์คลื่น 2 (`shape` `pattern` `lift` `where` `growTo` `&`/`|` `cfg:`/`opt:`/`hidden:` `kit.*` `scrap.*`) · บั๊ก bake สี → token `plate` `accentPaper` `ed.*` `pop.*` + ธง `surface=` `papered` `duo` `stamped` + `platePattern` `mixHead` `fitScale` `group` `src`/`photoRef` `byline` · ขั้นต่ำที่อ่านออก §5 ข้อ 10 · ย้ายผังไป `shared/WidgetSpecs` (iOS folder ref · Android assets) · Android `SpecSolverFixtureTest` + `present/spec-parity` · ถอด 16 ใบ |
| 19 ต.ค. | ชุดห้าสไตล์แตกเป็น 50 ชนิด (`kit<หัวข้อ><Purple|Cream|Gingham|Night|Mac>`) · หน้าตา = `widget.kit.look` · ไม่มี `cfg:style` และไม่เก็บ `kit.style` ในชิ้นแล้ว · ไฟล์เก่า (`kitRate` + `kit.style`) อ่านเป็นชนิดใหม่ผ่าน `replaces` + look |
| 19 ต.ค. | ตัวเลือกทุกใบ = `widget.controls` (ย้ายจาก `kit.controls` + `pattern: true`) · ชิ้น = ฟิลด์หลัก + `options` ก้อนเดียว (คีย์ = `opt`) · ถอด `tray` (ช่องทาง · แบบตรา ซึ่งไม่มีผลตั้งแต่ย้ายเป็น JSON) และตัวเลือกแฮนเดิลของ kit รูปโปรไฟล์ (ผังไม่ได้อ่าน) · `pinned` ดูจากชนิด |
| 19 ต.ค. | ถอด `widget.emboss` · `widget.liftPhoto` · `lift` ของรูป และค่าในชิ้น `keepPhotoBG` `noEmboss` `blindEmboss` — ตราปั๊มวาดในผังและมีตลอด (การ์ดรู้ว่ามีจากไอคอน `embossedLockup` ในผัง) · แอปไม่ลบพื้นหลังรูปคนอีกแล้ว (PNG ใสของผู้ใช้ยังเป็นคัตเอาต์ได้) |
| 15 ต.ค. | **JSON only**: บล็อก `widget` ครบทุกไฟล์ (เติมด้วยสคริปต์จากค่าที่ iOS คำนวณจริง · ภาพ 667 ไฟล์เท่าเดิมทุก byte) · `shared/category-models.json` · `check-widgets.mjs` · ลบ enum/ตารางชื่อ/view ต่อ widget ทั้ง 3 แพลตฟอร์ม · `textBlock` = ชั้นข้อความ · `proofSeal` → `pinned` · การ์ดเริ่มต้น → `shared/starter-cards.json` · แก้กระตุกตอนยืด (`SpecSolveMemo` · `metas` · cache ตัววัด · id คงที่ของพรีวิวสไตล์) |
| 18 ต.ค. | Android (`CardLayout.kt` `CardScreen.kt` `Motion.kt`) + เว็บ (`page.js`) ตาม iOS: ตราตรึง `pinned` + หมุดมุมเดียว `resizeLive`/`resizePush` · ยังไม่ commit |
| 20 ต.ค. | แหล่งข้อมูล Android + เว็บเท่า iOS บนข้อมูลจริง: ช่อง `website` (ProfileField/FIELDS) → `stat:site` + แถว web ของ `contacts` · `stat:phoneFmt`/`lineFlow` อ่านค่าดิบ · `body` จากค่าพร้อมหน่วยที่ sync มา · `avail` = `availSummary` (รวมกลุ่มวัน/รวมช่วง) · `works.brandLogo` = logo ?? asset · กติกาปัดเลข half-up บนทศนิยม (iOS `Fmt.fixed` แทน `String(format:)` · เว็บ `fixed` แทน `toFixed`) · ไอคอน `sh:line` ครบสามแพลตฟอร์ม · `SpecIconCoverageTest` ตรวจชื่อที่ data source สร้างด้วย · `owner.verified` ต่างความหมาย → §10 ค้างตัดสินใจ |
