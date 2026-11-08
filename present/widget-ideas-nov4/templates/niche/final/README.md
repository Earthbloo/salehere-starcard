# Final Templates (5 พ.ย. 2569) — แนวตั้ง 10 · แนวนอน 10

คัดจาก 41 ใบที่ผู้ใช้ติ๊ก (`picks.txt`) · ใบที่ผังเหมือนกันรวมเป็นใบเดียว · ผังไม่ซ้ำกันทั้ง 20 ใบ · widget ของ salehere-ios เท่านั้น · รูปที่ผู้ใช้ส่งมาเท่านั้น

**5 พ.ย. 2569 (ค่ำ): ผู้ใช้สั่งเก็บเฉพาะหน้านี้ งานออกแบบอื่นลบหมด** — widget ใหม่ 60 ชิ้น · template ชุดเดิม 76 ใบ · ชุดตามสายงาน 266 ใบ · ตัว build/recipes · รูป Unsplash 387 รูป ย้ายไป `~/.Trash/starcard-designs-deleted-2026-11-05/` (กู้คืนได้จนกว่าจะล้างถังขยะ)
โฟลเดอร์นี้ไม่พึ่งไฟล์อื่นแล้ว นอกจากเซิร์ฟเวอร์ `sync-server` (ตัววาด · spec · รูปใน `sync-server/data/images`)

ดู: http://localhost:8802/templates/niche/final/index.html (เปิด preview `widget-ideas` + `sync-server`) · ปุ่ม "ดาวน์โหลดไฟล์ production" = ทั้ง 20 ใบ รูปแบบ createStarCardTemplates (ใส่ proofSeal แล้ว)

## รวมใบที่ติ๊กอย่างไร (ผลอยู่ใน `merge-groups.json`)
ผังเดียวกัน = ชิ้นชนิดเดียวกัน (ไม่นับหน้าตา Purple/Cream/Gingham/Mac/Night/Glass/Paper) อยู่ตำแหน่งเดียวกัน ≥ 60% ของชิ้น · ที่ติ๊ก: แนวตั้ง 25 ใบ = 16 ผัง · แนวนอน 16 ใบ = 8 ผัง
- แนวตั้ง: ชุด kit 7 ใบ → 1 · Pop Paper/Pop Clay/Mom Rose → 1 · Window Night + Fashion Sand → 1 · บรรณาธิการ 3 ใบ → 1 · ชื่อยักษ์ทับรูป 2 → 1 · Mom Cream + Edu Aqua → 1
- แนวนอน: Poster Ink 4 สาย + Star Violet → 1 · Gingham Picnic 4 สาย → 1 · Pop Clay 2 → 1 · Editorial Cocoa + Beauty Nude → 1 · มีผังต่างกันแค่ 8 แบบ → เติม Tomato Pop · Latte Scrap · Carbon Type จากแบบที่ติ๊กในแนวตั้ง และปรับ Merlot ให้หน้า 1 เป็นคลิป (ต่างจาก Poster Ink)
- ตัวอย่างใช้คนต่างสายกันให้ครบ 14 สาย (template ไม่ผูกสาย — ใน production ใช้ข้อมูลของเจ้าของการ์ด)

## รูปไม่ซ้ำในใบ (หน้า final/index.html)
แต่ละใบมีรูปบุคคล 4 + ผลงาน 4 (`photo-sets.json` · PNG ตัดพื้นนับเป็นรูปเดียวกับต้นฉบับ · หมวดของชิ้นจาก `kinds.json`) · วาดรอบแรกดูว่าชิ้นไหนขอช่องรูปไหน แล้วแจก:
1 ชิ้นคนยืนบนการ์ด (รูปครึ่งตัวก่อน) → 2 hero → 3 ผลงานยืนยันได้รูปผลงาน → 4 ช่องบุคคลอื่น → 5 แกลเลอรี/คลิปใช้รูปผลงานที่เหลือแล้วรูปบุคคลที่เหลือ
ตรวจจากหน้าที่วาดจริงว่าไม่มีรูปซ้ำ (`node probe.mjs` → `final-report.json` · 20/20 ผ่าน) · ใต้ทุกใบบอกว่าชิ้นไหนใช้รูปไหน

## แก้ระหว่างทำ
- รูปเกิน 8: Latte Scrap แนวตั้ง กำแพงรูป → แท็กสายงานสแครป · แนวนอน กำแพงรูป → แถบฟิล์ม · Pop Clay แนวนอน แถบฟิล์ม → ย้ายเรตมาหน้า 3 · Tomato Pop แนวนอน ตัวเลขยักษ์ (มีรูปพื้น) → แถบสถิติกระจก
- กล่องเรตโล่งเหลือป้ายเดียว: build เลือกช่องทางที่มีประเภทงานหลายกลุ่ม + เติมเรต YouTube Shorts ให้ kris · golf · pete · poon
- Merlot Reel แนวนอน: ใส่ช่องติดต่อคืนที่หน้า 3

## ชุดข้อมูลส่งทีม API
`node tools/make-handoff.mjs` → `present/starcard-template-handoff/` (zip: `present/starcard-template-handoff.zip`) — แนวทาง: หน้าเลือก template โชว์ภาพตัวอย่าง ผู้ใช้เลือกแล้วได้แค่โครง (ข้อมูล/รูปเป็นของผู้ใช้) · ในชุด: `templates.json` (createStarCardTemplates) · `previews/` ใบละ 1 ภาพ (story 1080×1920 · portfolio 2620×1444 แผ่นแบบ StarCardSheetView) · `preview-urls.json` + `tools/fill-preview-urls.mjs` → `templates-with-preview.json` (exampleImage) · widget spec 60 ชนิด + sha256 · README ทีม API (ต้นฉบับ `tools/handoff-README.md`) · หน้า Final รองรับ `?scale=1&sheet` สำหรับถ่ายภาพนี้

## ไฟล์
| ไฟล์ | หน้าที่ |
|---|---|
| `out/*.json` | **ต้นฉบับของ 20 ใบ** (รูปแบบ designed-templates + owner ตัวอย่าง) — แก้ผังที่นี่ได้ตรง ๆ (x · y · w · h · surface · options) |
| `manifest.json` | รายการ + คำอธิบาย + ใบที่รวมมา (`mergedFrom`) |
| `designed-templates.json` | 20 ใบในรูปแบบของแอป (ยังไม่ใส่ proofSeal — ปุ่มดาวน์โหลดในหน้าใส่ให้) |
| `photo-sets.json` · `kinds.json` | รูปของแต่ละ persona (บุคคล 4 + PNG ตัดพื้น · ผลงาน 4) · หมวดของ widget |
| `probe.mjs` → `final-report.json` | ตรวจรูปไม่ซ้ำทุกใบด้วย Chrome headless: `node probe.mjs` |
| `tools/split.swift` · `tools/cutout.swift` · `tools/sets.json` | ตัดภาพรวมของผู้ใช้ (2×4) เป็น 8 รูป + ทำ PNG ตัดพื้นด้วย Apple Vision — ใช้เมื่อผู้ใช้ส่งชุดรูปใหม่ |
| `shots/` | ภาพจริงทุกใบ |

ตัว build (`build-templates.mjs` · recipes) ถูกลบตามคำสั่ง — แก้ใบต่อจากนี้ทำใน `out/*.json` แล้วรีเฟรชหน้า
