# Star Card — Model + API (ทดลอง)

เป้าหมาย: model ที่เข้าใจง่าย · ใช้กับ widget JSON ได้ · เก็บ/อ่านการ์ดผ่าน API (GraphQL) · แอปและเว็บวาดออกมาเหมือนกัน

## Model มีแค่ 2 อย่าง

**WidgetSpec** — ผังของ widget หนึ่งชนิด = ไฟล์ JSON หนึ่งไฟล์ (`shared/WidgetSpecs/<kind>.json` · สัญญาเต็ม: `StarCard/WIDGET-SPEC.md`)

**StarCard** — การ์ดหนึ่งใบ

```
StarCard
├─ format     story (1 หน้า 540×960) | portfolio (3 หน้า กว้าง 402)
├─ theme      สี/พื้นหลัง/โทนของการ์ด (JSON)
├─ pages[]
│   └─ items[]   Widget { id, kind, x, y, w, h, surface, border, options }
│                kind → WidgetSpec · x/y/w/h = หน่วยออกแบบของหน้า · options = ตั้งค่าอื่นของชิ้น
├─ owner      ข้อมูลเจ้าของการ์ดที่ widget อ่าน (ชื่อ · ช่องทาง · เรต …)
├─ notes      ข้อความของชั้นข้อความ (textBlock) เท่านั้น · widget ไม่มี   { "<widgetId>[#ช่อง]": "…" }
└─ photos     รูปในช่องของชิ้น       { "<widgetId>#<ช่อง>": { imageId, fit } }
```

วาด = `WidgetSpec` + `Widget` + `owner` → ตัวคำนวณผัง (`SpecSolver`) → ตัววาด · **อัลกอริทึมเดียวกันทุกแพลตฟอร์ม**

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
