# Android: widget ผลงาน 3 ตัว ตัวอักษรใหญ่ขึ้น + ยอดวิวบนรูป

**เป้าหมาย:** ตั๋วผลงาน (`proofTicket`), ผลงานที่ยืนยันแล้ว (`proofWork`) และกำแพงโพลารอยด์ (`wallPolaroid`) อ่านออกบนการ์ด
- ยอดวิวอยู่มุมขวาบนของรูป เป็นป้ายดำโปร่ง มีไอคอนลูกตา
- ใต้รูปมีบรรทัดเดียว คือ ไลก์ · แชร์ (ไม่มีบันทึกและคอมเมนต์)
- ค่าที่เป็น 0 ไม่โชว์
- กำแพงโพลารอยด์มีผังแนวนอนแล้ว

ภาพก่อน/หลัง และภาพ 10 ขนาด: https://claude.ai/artifact/5XGLgvL1u5ihY3GziqPAiw

## งานที่ต้องทำ

### 1. ใช้ JSON ใหม่ 3 ไฟล์ (ไม่ต้องแก้โค้ด)
ไฟล์อยู่ที่ `salehere-starcard/shared/WidgetSpecs/12-ผลงานยืนยัน/` ได้แก่ `proofTicket.json` · `proofWork.json` · `wallPolaroid.json`

แอปโหลดผังจาก `schemaUrl` (S3) ดังนั้นต้องอัปโหลด 3 ไฟล์นี้ขึ้นแทนของเดิมผ่าน gateway ตามขั้นตอนปกติ

### 2. เพิ่มฟิลด์ `likesRaw`
ไฟล์ `starcardkit/model/layout/StarCardKitSpecField.kt` ราวบรรทัด 52

```kotlin
LIKES("likes"),
LIKES_RAW("likesRaw"),   // ใหม่
COMMENTS("comments"),
```

ไฟล์ `starcardkit/model/spec/StarCardKitSpecData.kt` ราวบรรทัด 262 ใน `"works"`

```kotlin
// เดิม
StarCardKitSpecField.LIKES to w.likes.shortDisplay(), StarCardKitSpecField.COMMENTS to w.comments.shortDisplay(),
// ใหม่
StarCardKitSpecField.LIKES to w.likes.shortDisplay(), StarCardKitSpecField.LIKES_RAW to w.likes.toString(),
StarCardKitSpecField.COMMENTS to w.comments.shortDisplay(),
```

ถ้าไม่เพิ่ม แอปจะไม่ crash แต่ไลก์จะไม่ขึ้นเลย เพราะ JSON เช็ค `$likesRaw>0`

### 3. ไอคอน (ไม่ต้องทำอะไร)
`StarCardKitPh` มี `EYE`, `HEART` และ `SHARE_FAT` แบบ fill อยู่แล้ว ใช้กับ `ph:eye-fill` · `ph:heart-fill` · `ph:share-fat-fill`

## สิ่งที่ JSON ใหม่ใช้ (มีใน `StarCardKitSpecSolver.kt` แล้ว)
- **เงื่อนไข `$likesRaw.max>0`:** ใช้ค่าสรุป `<key>.max` ของ chips (บรรทัด 103–111) แถวตัวเลขจะหายทั้งแถวเมื่อไม่มีผลงานใบไหนมียอด
- **variant ตามสัดส่วนกรอบ** (`ratio<0.48`, `ratio<0.8`) สำหรับกำแพงโพลารอยด์แนวนอน
- **chips ที่ใช้ `wrap: false`, `w: fill`, `maxW`, `h: fill`:** ใบโพลารอยด์กว้างเท่ากัน และรูปสูงเต็มที่ที่เหลือ
- **จำนวนตั๋ว/บานตามความกว้าง:**
  - ตั๋วผลงาน 3/4/5 ใบ เมื่อ `w>=524/701/878`
  - ผลงานที่ยืนยันแล้ว 3/4/5 บาน เมื่อ `w>=496/664/832`

## ทดสอบ
วางทั้ง 3 widget แล้วลองทั้งตอนผลงานมียอด และตอนยอดเป็น 0 ทุกใบ

| ขนาดกรอบ (pt) | ต้องเห็น |
|---|---|
| 366×222, 366×260 (ขนาดออกแบบ) | ป้ายวิวมุมขวาบนรูป · ใต้รูป ❤ ไลก์ ↗ แชร์ บรรทัดเดียว |
| 174×174, 174×260 | ตัวเลขไม่ถูกตัดเป็น "1…" |
| 520×300 | ตั๋ว/บาน 2–3 ใบ ตัวเลขครบบรรทัดเดียว |
| 620×200 (แนวนอน) | กำแพงโพลารอยด์เรียงแถวเดียวเต็มกว้าง ใบใหญ่เท่ากัน |
| 366×260 (กำแพง) | กำแพงโพลารอยด์สองแถว (บน 3 ล่าง 2) |
| ยอดเป็น 0 ทุกใบ | ไม่มีป้ายวิว · ไม่มีแถวตัวเลข · ไม่ขึ้น "0 วิว" · รูปได้ที่เต็ม |

ถ้าจะเทียบภาพกับเว็บต้นแบบ ให้เปิด preview "sync-server" ใน salehere-starcard แล้วเข้า `/card/dev/work-sizes.html`
