# Star Card Template 20 ใบ — ชุดข้อมูลสำหรับทีม API

5 พ.ย. 2569 · แนวตั้ง (story) 10 ใบ + แนวนอน (portfolio 3 หน้า) 10 ใบ · ใช้ widget ที่มีในแอป · ใส่ตรา Verified (`proofSeal`) แล้ว
ภาพรวม: `overview-story.png` · `overview-portfolio.png`

## แนวทาง
- **หน้าเลือก template โชว์ภาพตัวอย่าง** (`previews/` ใบละ 1 ภาพ) แทนการวาดสดด้วยข้อมูลของคนดู → เหมือนกันทุกแพลตฟอร์ม ตรงกับที่ออกแบบทุกจุด
- **ผู้ใช้กดเลือก** → `createStarCard(templateId)` ได้ผัง ธีม และชิ้นจาก template (ทำได้อยู่แล้ว) → การ์ดแสดงข้อมูลและรูปของผู้ใช้เอง
- ไม่ต้องอัปรูปคนหรือรูปผลงานของตัวอย่าง — อยู่ในภาพตัวอย่างแล้ว

## ส่งอะไรบ้าง
| ไฟล์ | คืออะไร |
|---|---|
| `templates.json` | **โครง 20 ใบ** พร้อมอัปผ่าน `createStarCardTemplates` (array · ~37 KB) — `{ name, format, snapshot: { theme, pages } }` |
| `previews/*.jpg` | **ภาพตัวอย่างใบละ 1 ภาพ** (JPEG) — story 1080×1920 · portfolio 2620×1444 (3 หน้าเรียงกัน + ช่องว่าง 26 รอบและระหว่างหน้าบนสีธีม = ขนาดแผ่น × 2 แบบเดียวกับ `StarCardSheetView`) · ขอบเหลี่ยม แอปมนมุมเอง |
| `templates-index.json` | ลำดับ · ชื่อ · format · ธีม · ไฟล์ภาพ + ขนาดของแต่ละใบ |
| `preview-urls.json` + `tools/fill-preview-urls.mjs` | ใส่ URL ภาพที่อัปแล้ว → `node tools/fill-preview-urls.mjs` → `templates-with-preview.json` (templates.json + `exampleImage { imgPath, width, height }` ต่อใบ) |
| `widgets.json` · `widget-specs/` | widget 60 ชนิดที่ใช้ (รวม proofSeal) + sha256 + ไฟล์ spec เวอร์ชันที่ใช้ออกแบบ |

## ขั้นตอน
**0. widget บน server ครบและตรงเวอร์ชัน** — template อ้าง widget ด้วย `kind` แอปโหลดหน้าตาจาก `schemaUrl` · เทียบ `sha256` ใน `widgets.json` กับไฟล์ที่ server ใช้ · ขาดหรือไม่ตรง → อัป `widget-specs/<kind>.json` ผ่าน `generateStarCardWidgetSchemaUploadUrl` + `createStarCardWidget` (ไม่ตรง = การ์ดที่สร้างจะหน้าตาไม่เหมือนภาพตัวอย่าง)

**1. สร้าง template (ทำได้เลย)**
```graphql
mutation ($file: Upload!) { createStarCardTemplates(file: $file) { successful entities { id name format sequence } errors { message } } }
```
staff เท่านั้น · ≤ 1 MB · ≤ 50 ใบ · ใบไหนผิด = ไม่สร้างทั้งไฟล์ · ไม่ได้ใส่ `sequence` = ต่อท้ายตามลำดับในไฟล์ (ใส่เองได้ถ้าจะให้ขึ้นก่อน)

**2. ภาพตัวอย่าง (ต้องเพิ่มใน API)** — ตอนนี้ `StarCardTemplate` ไม่มีช่องรูป และ `createStarCardTemplates` ไม่เก็บรูป
1. เพิ่ม `exampleImage: Image` ให้ `StarCardTemplate` (แบบเดียวกับ `StarCardWidget.exampleImage`) และให้ไฟล์ `createStarCardTemplates` รับ `exampleImage: { imgPath, width, height }` ต่อใบได้
2. อัป `previews/*.jpg` (`generatePreSignedUrl` → PUT) → ใส่ `fileUrl` ใน `preview-urls.json` → `node tools/fill-preview-urls.mjs`
3. อัป `templates-with-preview.json` แทน `templates.json` (หรือถ้าสร้าง template ไปแล้ว ผูกภาพด้วยชื่อ + format)

**3. แอป (iOS · Android)** — fragment `StarCardTemplateFields` ขอ `exampleImage { imgPath }` เพิ่ม · หน้าเลือก template (iOS `StarCardTemplatePicker` · Android `StarCardTemplateScreen`) โชว์ภาพนี้แทนการวาดสด (ไม่มีภาพ = วาดสดแบบเดิม) · กดเลือกยังเรียก `createStarCard(templateId)` เหมือนเดิม · เว็บไม่มีหน้าเลือก template (แสดงการ์ดที่สร้างแล้ว)

## กติกาข้อมูล
- หน่วยออกแบบ: story 540×960 · portfolio 3 หน้า หน้าละ 402×670 · ขอบหน้า 18 · ช่องว่างระหว่างชิ้น 10
- ตรา `proofSeal` (ชิ้นสุดท้ายของหน้าสุดท้าย): story (276, 786) 246×156 · portfolio หน้า 3 (18, 420) 366×232
- ชิ้นไม่มี `id` · ไม่มี `photos` (การ์ดใช้รูปของผู้ใช้) · `surface`: glass / dim / pane · `options` ที่ใช้: `chan` `hide` `qr` `fill` `corner`
- ธีม: `colors.primary` (+ `secondary` = การ์ดคู่สี) · `ink` night / paper / mist · `backdrop` solid / gradient
- คน ชื่อ ตัวเลข และรูปในภาพตัวอย่างเป็นข้อมูลสมมติ ใช้รูปที่ทีมเตรียมเอง (ไม่มีรูปสต็อกหรือโลโก้แบรนด์จากเว็บ)

## QA
สร้างการ์ดจากแต่ละ template บน iOS และ Android แล้วเทียบกับภาพตัวอย่าง — ตำแหน่ง ขนาด สี และหน้าตาของชิ้นต้องตรง (ข้อมูลและรูปเป็นของผู้ใช้)

## สร้างชุดนี้ใหม่ (ทีม Star Card)
`node tools/make-handoff.mjs` ในโฟลเดอร์ `present/widget-ideas-nov4/templates/niche/final/` (เปิด preview `widget-ideas` 8802 + `sync-server` 8787)
