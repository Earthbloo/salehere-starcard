# Star Card sync — โหมดลองทำ

ที่เก็บกลางบน Mac ให้ iOS กับ Android อ่าน/เขียน **การ์ดใบเดียวกันเป็น JSON ก้อนเดียว**
เพื่อทดสอบว่าค่าที่แพลตฟอร์มหนึ่งเขียน พออีกแพลตฟอร์มอ่านแล้วเขียนกลับ **ค่าเปลี่ยนไหม**

```bash
node sync-server/server.mjs          # หรือ preview "sync-server" ใน .claude/launch.json
open http://localhost:8787           # หน้าดูประวัติ + diff + ผลตรวจ
```

| แอป | ที่อยู่ server |
|---|---|
| iOS Simulator | `http://127.0.0.1:8787` |
| Android Emulator | `http://10.0.2.2:8787` |

ข้อมูลอยู่ที่ `sync-server/data/` (ไม่เข้า git) · ปุ่ม "ล้างการ์ดกลาง" บนหน้าเว็บ = เริ่มใหม่

---

## 1. JSON ของการ์ด (`LabDoc`)

รูปร่างเดียวกับ `api/star-card/example-doc.json` (= ที่ API จริงจะเก็บ) ต่างแค่ `imageId` เป็นสตริง sha

```jsonc
{
  "schemaVersion": 1,
  "format": "story",                     // CardFormat.rawValue
  "name": "สติกเกอร์ กระจกชมพู",
  "theme": { … },                        // CardSnapshot.Theme ตามที่แอปเขียนอยู่แล้ว
  "pages": [ { "items": [ … ] } ],       // CardSnapshot.Page[] ตามที่แอปเขียนอยู่แล้ว (ไม่มี index)
  "photos": {                            // เฉพาะช่องที่มีรูปของตัวเอง หรือถูกจัดกรอบ
    "<WIDGET-UUID>#<slot>": { "imageId": "9f2c…", "fit": { "dx": 0, "dy": -0.08, "zoom": 1.3 } }
  },
  "notes": { "<WIDGET-UUID>[#i]": "ข้อความ" },   // Profile.notes ของชิ้นที่อยู่บนการ์ดนี้เท่านั้น
  "backgroundImageId": "…",              // มีเฉพาะตอน theme.backdrop == "photo" และมีรูปพื้นหลัง
  "owner": {                             // ข้อมูลเจ้าของการ์ด (ของจริง = owner: User ไม่อยู่ในก้อนการ์ด)
    "values": { "name": "kll", … },      // Profile.values — ค่าที่พิมพ์เอง คีย์ = ProfileField.rawValue
    "list": { "categories": ["…"] },     // Profile.list — รายการชิป
    "intake": { … },                     // Profile.intake (IntakeData) — ไม่มี = ยังไม่เคยกรอกฟอร์ม
    "avatarImageId": "…",                // PhotoStore.profile
    "creatorImageIds": ["…", null, null],// Portfolio.creators 3 ช่อง (null = ว่าง)
    "workImageIds": ["…"],               // Portfolio.works ตามลำดับ
    "libraryImageIds": ["…"]             // PhotoStore.uploaded ตามลำดับ
  }
}
```

ข้อความบนการ์ดส่วนใหญ่ (ชื่อ แนะนำตัว เรต ติดต่อ) มาจาก `owner.values/list/intake` ไม่ใช่ `notes`
และช่องรูปที่ไม่ได้ใส่รูปเองไล่หา: รูปครีเอเตอร์/รูปโปรไฟล์ (ช่อง 1–3) → คลังรูป → รูปผลงาน → รูปตัวอย่าง
ถ้าไม่ส่ง `owner` สองเครื่องจะโชว์คนละชื่อคนละรูปทั้งที่ผังตรงกัน · ไม่ซิงก์: วิดีโอ และรูปที่ลบพื้นหลังแล้ว (แต่ละเครื่องคำนวณเอง)

กติกา
- `pages`/`theme` = **ผลของการแปลงผ่านโมเดลของแอปจริง** (`CardStore.snapshot(restore(x))`) ไม่ใช่ก้อนที่ส่งต่อมาดิบ ๆ
  ไม่งั้นการตรวจจะไม่เห็นค่าที่แอปทำหาย/ปัดเศษระหว่างโหลด
- `photos[k].fit` ใส่เฉพาะเมื่อไม่ใช่ `{0,0,1}` · `imageId` ใส่เฉพาะเมื่อช่องนั้นมีรูปของตัวเอง
- ไม่มีช่องว่าง: `photos` / `notes` ส่งเป็น `{}` เมื่อไม่มีอะไร

## 2. API

| | | |
|---|---|---|
| `GET /api/card[?known=N]` | ฉบับล่าสุด `{rev, doc, by, at}` · rev ยังเป็น N = **204** | ว่าง = `{rev:0, doc:null}` |
| `PUT /api/card` | `{baseRev, doc, platform, device}` → `{rev}` | baseRev ≠ rev ล่าสุด = **409** + ฉบับล่าสุด |
| `POST /api/echo` | `{rev, doc, platform, device}` → `{diffs}` | "อ่าน rev นี้แล้วได้แบบนี้" |
| `POST /api/images` | ไบต์ดิบ + `Content-Type` → `{imageId}` | id = sha256 ของไบต์ (อัปซ้ำได้) |
| `GET /api/images/:id` | ไบต์ของรูป | |
| `GET /api/history` · `GET /api/rev/:n` · `POST /api/reset` | ของหน้าเว็บ | |

`platform` = `"ios"` หรือ `"android"` · `device` = ชื่อเครื่อง/simulator

## 3. สิ่งที่แอปทำ (ทั้งสองแพลตฟอร์มต้องเหมือนกัน)

**เปิด/ปิดโหมด** — ปุ่มในแผง Lab · มีผลตอนเปิดแอปครั้งถัดไป (แอปปิดตัวเองหลังกด)
- เปิดครั้งแรก → **สำรองข้อมูลเดิมทั้งหมด** (UserDefaults/SharedPreferences + Documents/filesDir) ไปไว้ที่ `lab-backup/`
- ปิดโหมด → คืนข้อมูลจาก `lab-backup/` ทับของที่เปลี่ยนไประหว่างลอง แล้วลบ backup
- ธงเปิด/ปิดอยู่ในไฟล์ `lab-mode.json` นอกพื้นที่ที่ถูกสำรอง (ไม่งั้นการคืนข้อมูลจะเขียนทับธง)

**ตอนเริ่ม (โหมดเปิด)**
1. `GET /api/card`
2. ว่าง → ใช้การ์ดใบหลักของเครื่องนี้เป็นการ์ดกลาง (อัปรูป → `PUT` baseRev 0)
3. มีแล้ว → สร้าง/ทับการ์ดในเครื่องจาก doc → โหลดรูปที่ขาด → **ส่ง echo**
4. คลังการ์ดในโหมดนี้เหลือใบเดียว = การ์ดกลาง (ใบอื่นอยู่ใน backup)

**ทุก 1 วินาที**
- สร้าง doc จากสถานะในเครื่อง → ต่างจากที่ซิงก์ล่าสุด → อัปรูปใหม่ → `PUT` (409 = รับฉบับล่าสุดมาใช้)
- `GET /api/card?known=rev` → ได้ rev ใหม่ → ใช้กับการ์ดในเครื่อง (ห้องแต่งที่เปิดอยู่รีโหลดตาม) → **ส่ง echo**

echo = doc ที่แอปสร้างจากสถานะของตัวเอง **หลัง** โหลด rev นั้นเสร็จ · server เทียบกับ doc ของ rev นั้น
ว่าง = อ่านครบไม่มีค่าเพี้ยน · ไม่ว่าง = หน้าเว็บขึ้นแดงพร้อมรายการ path: ค่าเดิม → ค่าที่ได้
