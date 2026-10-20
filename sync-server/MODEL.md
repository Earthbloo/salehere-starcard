# Star Card — Model + API (ทดลอง)

เป้าหมาย: model ที่เข้าใจง่าย · ใช้กับ widget JSON ได้ · เก็บ/อ่านการ์ดผ่าน API (GraphQL) · แอปและเว็บวาดออกมาเหมือนกัน

## Model มีแค่ 2 อย่าง

**WidgetSpec** — ผังของ widget หนึ่งชนิด = ไฟล์ JSON หนึ่งไฟล์ (`shared/WidgetSpecs/<kind>.json` · สัญญาเต็ม: `StarCard/WIDGET-SPEC.md`)

**StarCard** — การ์ดหนึ่งใบ

```
StarCard
├─ format     story (1 หน้า 540×960) | portfolio (3 หน้า กว้าง 402)
├─ theme      สี/พื้นหลัง/โทนของการ์ด (JSON) — สี = `colors { primary, secondary? }` hex เท่านั้น (ดูหัวข้อ theme)
├─ pages[]
│   └─ items[]   Widget { id, kind, x, y, w, h, surface, border, options }
│                kind → WidgetSpec · x/y/w/h = หน่วยออกแบบของหน้า · options = ตั้งค่าอื่นของชิ้น
├─ owner      ข้อมูลเจ้าของการ์ดที่ widget อ่าน (ชื่อ · ช่องทาง · เรต …)
├─ notes      ข้อความของชั้นข้อความ (textBlock) เท่านั้น · widget ไม่มี   { "<widgetId>[#ช่อง]": "…" }
└─ photos     รูปในช่องของชิ้น       { "<widgetId>#<ช่อง>": { imageId, fit } }
```

วาด = `WidgetSpec` + `Widget` + `owner` → ตัวคำนวณผัง (`SpecSolver`) → ตัววาด · **อัลกอริทึมเดียวกันทุกแพลตฟอร์ม**

## theme — สีมาจาก API เท่านั้น (20 ต.ค. 2569 รอบ 3)

```jsonc
"theme": {
  "colors": { "primary": "#3A4B41", "secondary": "#E6CFA7" },   // สีเดียว = ไม่มี secondary · ค่าตรงกับที่เลือก ไม่เปลี่ยนตามโทน
  "ink": "night",                          // หมึก: night (มืด) · paper / mist (สว่าง) · คู่สี: = โทน เข้ม/อ่อน ที่ผู้ใช้เลือก (สีไหนขึ้นเป็นพื้น) · สีเดียว: แอปเลือกให้จากความสว่างของพื้น (ผู้ใช้ไม่ได้เลือก)
  "backdrop": "solid",                     // solid · gradient (· photo + photoEffect/photoDim/photoLean เมื่อพื้นเป็นรูป)
}
```

= 3 อย่างตามถาด "พื้นหลัง" ของแอปเป๊ะ (สีเดียว/ไล่เฉด · สี · โทน **เข้ม/อ่อน เฉพาะคู่สี** — 20 ต.ค. 2569 รอบ 5) · `corner` `strip` `inkAuto` ถอดออก 20 ต.ค. 2569 รอบ 4:
มุม = มน · แถบผู้ออกบัตร = บรรทัด ทุกใบ · หมึกเก็บตรง ๆ (เลือกสีเองแล้วแอปเลือกฝั่งหมึกให้ทันที ไม่มีโหมดอัตโนมัติแยก) · doc เก่าที่มีคีย์พวกนี้ถูกเมิน/แปลงตอนอ่าน

- `primary` = สีพื้นการ์ด · **ทุกสีที่เหลือ renderer คิดเอง** ด้วยสูตรเดียวกันทั้งสามแพลตฟอร์ม (`CardTheme` iOS/Android · `makeTheme` เว็บ):
  ไล่เฉด = primary → ปลาย hsb(hue, min(1, sat×1.06), bri×0.80) · สีเน้นดิบ = hsb(hue, clamp(sat+0.1, 0.35…0.72), 0.96) · หมึกฝั่งสว่าง = ถ่านอาบเฉด ·
  กระดาษ/แผ่นของ widget (พื้น `light`/`dark` ใน WIDGET-SPEC §4) = ครีมอมเฉด / แผ่นอิ่มสี จาก hue เดียวกัน
- `secondary` มี = **การ์ดสองสี**: เก็บคู่ตามที่เลือก (ไม่สลับค่า) · **โทน = `ink`**: `night` = สีเข้มของคู่เป็นพื้น สีอ่อนเป็นหมึก/สีเน้น/แผ่น ·
  `paper`/`mist` = สีอ่อนเป็นพื้น สีเข้มเป็นหมึก (ไม่มีสีที่สาม) · renderer ตัดสินเองว่าสีไหนเข้ม/อ่อนจากความสว่าง
- สีเดียว: `primary` = พื้นการ์ดตามที่เลือกเป๊ะ · ไม่มีแถวโทน — `ink` = `autoInk` (contrast ของหมึกสองฝั่งกับพื้น: สว่างชนะ → paper/mist ตาม sat ≥ 0.35 · ไม่งั้น night) คิดตอนเลือกสี ทุกแพลตฟอร์มสูตรเดียวกัน · เม็ดพาเลตต์สำเร็จรูป: แตะครั้งแรก = เฉดเข้ม แตะซ้ำ = สลับเข้ม/อ่อน (ปุ่มลัด เขียน hex)
- พาเลตต์ 12 สี / คู่สี 11 คู่ ในแอปเป็น **ปุ่มลัด** ที่เขียน hex ลง `colors` (ตาราง: `Palette`/`ColorDuo` ในแอป · `PRESETS`/`DUO_PRESETS` ใน theme.js) — API/DB ไม่รู้จักชื่อ
- doc รุ่นก่อนที่มี `palette` `duo` `duoFlipped` `customHue/Sat/Bri` `brightness` `hueShift` ยังอ่านได้: แปลงเป็น `colors` ตอนโหลด
  (`LegacyTheme` iOS/Android · `migrateTheme` เว็บ · ไฟล์ JSON ใช้ `node shared/tools/theme-colors-v4.mjs <file>`) แล้วเซฟกลับเป็นรูปใหม่

## API (GraphQL · `POST /graphql`)

```graphql
query  { widgetSpecs { kind title category design json } }         # ผังทุกชนิด
query  { widgetSpec(kind: "aboutNote") { json } }
query  { widgetSpecsVersion }                                      # เปลี่ยนเมื่อผังใดเปลี่ยน
query  { mockPhotos { version creators works } }                   # รูป mock ชุดเดียวของทุก platform
query  { starCard { rev format theme pages { items { id kind x y w h surface border options } } owner notes photos } }
mutation { saveStarCard(baseRev: 22, card: { format: "story", pages: [ … ] }) { ok rev conflict } }
```

- `baseRev` = rev ที่เห็นล่าสุด — มีคนบันทึกก่อน → `conflict: true` (อ่านใหม่แล้วบันทึกอีกครั้ง)
- รูปเป็นไฟล์ ไม่ส่งผ่าน GraphQL: ทดลอง `POST /api/images` → `imageId` · ของจริง = S3 presign
- schema เต็มอยู่ใน `sync-server/graphql.mjs` (`SDL`)

## ซิงก์ตอนสลับเครื่อง (เจ้าของใช้คนเดียว — ไม่ต้องตลอดเวลาแบบงานหลายคน)

| | ดึง | ส่ง |
|---|---|---|
| iOS / Android | เปิดแอป · กลับเข้าแอป → `widgetSpecsVersion` · `mockPhotos` · rev ของการ์ด (โหลดทั้งใบเฉพาะเมื่อใหม่กว่า) | แก้แล้วนิ่ง ~2 วิ · ตอนพับแอป → `saveStarCard` (เฉพาะเมื่อแก้จริง) |
| เว็บ (ดูอย่างเดียว) | เปิดหน้า · กลับมาที่แท็บ | — |

- ระหว่างใช้ แอปเช็กแค่ "ลายเซ็นการแก้" (เวลาแก้การ์ด + รุ่นของโปรไฟล์/รูป) ทุก 2 วิ — ไม่ต่อเน็ต ไม่ประกอบการ์ด
- ชนกัน (แก้สองเครื่องโดยยังไม่ได้ซิงก์) = **บันทึกล่าสุดชนะ** ไม่ถามผู้ใช้
- เครื่องที่ไม่ได้แก้อะไรจะไม่ส่งฉบับของตัวเองทับเด็ดขาด

กติกาเลือกรูปช่อง i (ทุก platform): รูปที่ใส่ในช่องของชิ้นเอง → ช่อง 1–3 ใช้ `creators[(i%12 − 1) % n]` → ที่เหลือ `works[i % n]` ·
ชุดรูปอยู่ใน `data/mock-photos.json` (แช่จากรูปของ iOS rev 22)

## ลองเลย

```bash
node sync-server/server.mjs
```

| | |
|---|---|
| เว็บดูการ์ด | http://localhost:8787/card/ (ตามการ์ดล่าสุดเอง ทุก 1 วิ) |
| ทุก widget เทียบ iOS | http://localhost:8787/card/dev/gallery.html |
| แอป iOS / Android | เปิด "โหมดลองทำ" — แอปเขียนการ์ดใบเดียวกันเข้า API นี้ |
| เทสต์ตัวคำนวณ | `node sync-server/web/test/replay.mjs` → ต้องได้ 81/81 |

## ยกไป project อื่น

ไฟล์ที่ต้องเอาไป: `graphql.mjs` (schema + resolver) · `web/js/*` (ตัวคำนวณ · ตัววาด · ธีม — ES module ไม่มี dependency) · `shared/WidgetSpecs/`
เปลี่ยนที่เก็บ: resolver `current()` / `write()` / `specs()` ใน `graphql.mjs` ชี้ไป DB แทนไฟล์ — schema ไม่เปลี่ยน

<details><summary>ที่ยังต่างจากแอป (รู้แล้ว)</summary>

- ฟอนต์วัดด้วยเบราว์เซอร์ — ความกว้างตัวอักษรต่างได้เศษจุด (ผัง/ระยะเท่ากัน)
- กระจก (Liquid Glass) ของ iOS ใช้ blur ของเบราว์เซอร์แทน
- สถานะ "ล็อก" ของ widget ที่ยังไม่กรอกหัวข้อ Star Profile ไม่อยู่ใน model → เว็บถือว่าปลดล็อกแล้ว
- ข้อมูลเจ้าของ: iOS อ่าน Star Profile ของเครื่อง · เว็บอ่าน `owner` ในการ์ด — ค่าเท่ากันเมื่อแอปเขียน `owner` ครบ
- ความสูงหน้า portfolio: แอปสูงตามจอ · เว็บใช้ 402 × 670
</details>
