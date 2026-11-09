# Star Card — ล็อกวิดเจ็ต (salehere-ios · salehere-android · salehere-web)

> 8 พ.ย. 2569 · ใช้แทนการล็อกตามหมวด (`category` → topic / tray group / `GATE_RULE`) ทั้งสามแพลตฟอร์ม
> ที่มา: `shared/WidgetSpecs/*.json` (`widget.requires`) · กติกาไฟล์ผัง `StarCard/WIDGET-SPEC.md` §3.3d · ตัวตรวจ `shared/tools/check-widgets.mjs`
> รายการวิดเจ็ตพร้อมรูป + แถวที่รอ: `present/widget-staritems/index.html`

**สรุปบรรทัดเดียว:** วิดเจ็ตบอกใน JSON ว่ารอแถวไหน (`requires`) → แอปเช็กแต่ละแถวด้วย **ฟังก์ชันเดียวกับติ๊กถูกในหน้า Star Profile** → ครบ = ใช้ได้ · ไม่ครบ = ล็อก

---

## 1. กติกา 7 ข้อ

1. **ล็อก** = มีชื่อใน `widget.requires` ที่ยังไม่ผ่านอย่างน้อย 1 ตัว · `[]` = ไม่ล็อก · ชั้นข้อความ (`textBlock` ไม่มีไฟล์ผัง) = ไม่ล็อกเสมอ
2. **ผ่านหรือไม่** = `isDone(name)` ฟังก์ชันเดียว ใช้ทั้งติ๊กถูกในหน้า Star Profile และล็อกวิดเจ็ต (ห้ามมีสูตรที่สอง)
3. **ข้อมูลที่ใช้คิด = ของเจ้าของการ์ดเสมอ** (ไม่ใช่ของคนที่ล็อกอินอยู่ ยกเว้นเป็นคนเดียวกัน) · คิดสดจากข้อมูลล่าสุด ไม่เก็บสถานะล็อกลงการ์ด
4. **ล็อกมีแค่ฝั่งเจ้าของ** (ตู้ · หน้าแต่ง · ด่าน) — คนอื่นที่เปิดการ์ดไม่เห็นป้ายล็อก/ข้อความ "ยังไม่มีข้อมูล" ไม่มีปุ่มพาไปกรอก
5. **ข้อมูลตัวอย่าง (sample) อยู่ได้แค่ในตู้/หน้าแต่งของเจ้าของ** — ห้ามออกไปในรูปที่บันทึก ลิงก์ หรือหน้าที่คนอื่นเห็น
6. **ทุกทางที่การ์ดออกไปข้างนอกต้องผ่านด่าน (§5)**: แชร์ · บันทึกรูป · คัดลอกลิงก์ / ปุ่มลิงก์บนการ์ด · ตั้งเป็นการ์ดหลัก
7. **การ์ดที่แชร์/ตั้งหลักไปแล้วก่อนเปลี่ยนกติกา ไม่ถูกถอด** — ด่านมีผลกับครั้งถัดไปเท่านั้น

---

## 2. ชื่อ 12 ตัว (enum)

| ชื่อ | ข้อความที่ผู้ใช้เห็น | ผ่านเมื่อ (`isDone`) | ขั้นที่เปิด — iOS `StarWizardStep` · Android `StarProfileRequestStepDestination` · web `StarWizardStep` |
|---|---|---|---|
| `kind` | ประเภทครีเอเตอร์ | `starItems.kind` | `.kind` · `ACCOUNT_TYPE` · `"kind"` |
| `socials` | ช่องทางของฉัน | `starItems.socials` | `.socials` · `SOCIALS` · `"socials"` |
| `categories` | สายที่ใช่ | `starItems.categories` | `.categories` · `CATEGORIES` · `"categories"` |
| `about` | เกี่ยวกับคุณ | `starItems.about` | `.media` · `PORTFOLIO` · `"media"` |
| `provinces` | พื้นที่รับงาน | `starItems.provinces` | `.province` · `PROVINCE` · `"province"` |
| `availability` | วันเวลาว่างรับงาน | `starItems.availability` | `.availability` · `AVAILABILITY` · `"availability"` |
| `contact` | ช่องทางติดต่อ | `starItems.contact` (เบอร์ **และ** LINE) | `.contact` · `CONTACT` · `"contact"` |
| `kyc` | ยืนยันตัวตน | `starItems.kyc` (คำขอล่าสุด approved เท่านั้น) | `.kyc` · `KYC` · `"kyc"` |
| `insight` | ข้อมูลผู้ติดตาม | `socialProfileInsights[]` ที่ `completed == true` ≥ 1 | `.insight` · `SOCIAL_INSIGHT` · `"insight"` |
| `body` | สัดส่วน | กรอก ≥ 1 ค่า จาก น้ำหนัก ส่วนสูง อก เอว สะโพก รองเท้า | `.body` · `MEASUREMENT` · `"body"` |
| `rate` | เรทรับงาน | ช่องทางที่ราคา (`photo` `shortVdo` `longVdo` `sharing`) > 0 ≥ 1 ช่อง | `.socials` · `SOCIALS` · `"socials"` |
| `work` | ผลงานกับ Sale Here | งานที่**รีวิวแล้ว**ผ่าน Sale Here (`works` = แคมเปญ reviewed) ≥ 1 | — ไม่มีขั้น กรอกเองไม่ได้ |

- 8 ตัวแรก = `CreatorStarItems` ของ server ตัวต่อตัว (`user-service/src/utils/user-rank/star-items.js`) — **แอปอ่าน ไม่คิดเอง**
- 4 ตัวหลังคิดจากข้อมูลดิบด้วยสูตรในตารางนี้เท่านั้น (สูตรเดียวกับติ๊กถูกในหน้า Star Profile ปัจจุบันทั้งสามแพลตฟอร์ม)
- `work` ไม่นับแบรนด์ที่ชนะแต่ยังไม่รีวิว (`brands`) — ไม่มีวิดเจ็ตไหนอ่าน `brands` · ทุกใบที่ใช้ `work` อ่าน `works`
- `rate` ไม่มีแถวของตัวเอง (ป้ายราคาในแถวช่องทาง) — ใบที่มี `rate` มี `socials` ด้วยเสมอ (ตัวตรวจบังคับ)
- **ลำดับ 2 แบบ:** ใน JSON = ลำดับตารางนี้ · ที่ผู้ใช้เห็น (ป้าย · แถวในชีต) = ลำดับหน้า Star Profile: ประเภท · ช่องทาง(+เรท) · สายที่ใช่ · เกี่ยวกับคุณ · พื้นที่ · วันเวลา · ติดต่อ · ข้อมูลผู้ติดตาม · สัดส่วน · ยืนยันตัวตน · ผลงานกับ Sale Here

---

## 3. โค้ดกลาง (เขียนแบบนี้ทั้งสามแพลตฟอร์ม)

```text
// อ่านจากไฟล์ผัง — เป็น String เสมอ (ค่าใหม่ในอนาคตต้องไม่ทำผังทั้งใบพัง)
requires(spec) = spec.widget.requires ?? []

// ข้อเท็จจริงของ "เจ้าของการ์ด" — Star Profile กับ Star Card สร้างจากข้อมูลชุดเดียวกัน
LockFacts {
  starItems: CreatorStarItems?   // null = โหลดไม่ได้ / ระบบ STAR ไม่พร้อม
  hasInsight, hasBody, hasRate, hasWork: Bool
  kycState: none | waiting | approved | rejected   // ใช้แค่เลือกข้อความ/ปุ่ม ไม่ใช้ตัดสินผ่าน
}

isDone(name, f):
  name ∈ 8 ตัวแรก → f.starItems?[name] == true          // null = false · ห้ามเดาจากข้อมูลดิบ
  insight → f.hasInsight ;  body → f.hasBody ;  rate → f.hasRate ;  work → f.hasWork
  อื่น ๆ (ชื่อที่แอปรุ่นนี้ไม่รู้จัก) → false

missing(spec, f)  = requires(spec).filter { !isDone($0, f) }      // ว่าง = ใช้ได้
fillable(name, f) = มีขั้นวิซาร์ด (§2) && !(name == kyc && f.kycState == waiting)
blocked(spec, f)  = missing(spec, f).any { !fillable($0, f) }      // มีสิ่งที่กรอกเองตอนนี้ไม่ได้
```

หน้า Star Profile เรียก `isDone` ตัวนี้ทุกแถว (แถวช่องทาง = `isDone("socials")` · สัดส่วน = `isDone("body")` …) — แก้สูตรที่เดียว สองหน้าเปลี่ยนพร้อมกัน

**โหลดข้อมูลเจ้าของใหม่** ทุกครั้งที่: เปิดตู้/หน้าแต่ง · ปิดวิซาร์ด · ก่อนเข้าด่าน — โหลดไม่สำเร็จ = เหมือน `starItems` null (ล็อก · ด่านไม่ให้ผ่าน · ปุ่ม "ลองใหม่") ห้ามใช้ค่าเก่าในเครื่อง

---

## 4. หน้าตาฝั่งเจ้าของ

### 4.1 ตู้วิดเจ็ต (แกลเลอรี/ถาด) และใบบนการ์ด (หน้าแต่ง)
- ใบที่ล็อก = วาดใบจริงด้วยข้อมูลตัวอย่าง + กรอบประ + ป้าย **ชื่อแถวที่ขาด** (ลำดับหน้า Star Profile) · บนการ์ด = ป้ายกุญแจมุมใบ
- แตะ (ใบในตู้ หรือป้ายบนการ์ด):
  - `blocked` = **ไม่เปิดวิซาร์ด** สั่นเบา ๆ + บอกเหตุผลข้อเดียว: `work` → "ปลดได้เมื่อมีงานรีวิวผ่าน Sale Here" · `kyc` รอตรวจ → "รอตรวจยืนยันตัวตน" · ชื่อไม่รู้จัก → "อัปเดตแอปเพื่อใช้วิดเจ็ตนี้"
  - ไม่ `blocked` = เปิดวิซาร์ด **เฉพาะขั้นของ `missing`** ต่อกันรวดเดียว (`socials` + `rate` = ขั้นเดียว) → ปิดวิซาร์ด → โหลดเจ้าของใหม่ → ครบ = ในตู้วางใบให้เลย / บนการ์ดปลดล็อก
- ใบที่เคยใช้ได้แล้วกลับมาล็อก (เช่น เอาช่องทางออกหมด) = ล็อกทันที ไม่ต้องทำอะไรพิเศษ
- ใบ `requires: []` ที่ใช้รูปช่อง 1–3 (6 ใบ) สำหรับคนใหม่จะเห็นแค่ avatar — ในตู้ใส่รูปตัวอย่างเป็นภาพย่อได้ (ข้อ 5)

---

## 5. ด่าน (ทุกทางออกตามข้อ 6)

ชิ้นที่นับ = ทุกชิ้นบนการ์ดที่มีไฟล์ผัง (รวมตรารับรองที่ตรึงไว้ · ไม่นับชั้นข้อความ · ชิ้นที่โหลดผังไม่ได้ = ข้าม)

1. ไม่มีชิ้นไหน `missing` → ทำต่อทันที
2. มี → ชีต: 1 แถว = 1 ขั้นวิซาร์ด (ลำดับหน้า Star Profile)
   - ชิ้นที่ `missing` มี `work` → ให้แค่แถว **"ผลงานกับ Sale Here · ยังไม่มีงานที่รีวิว"** ปุ่ม **"เอาวิดเจ็ตนี้ออก"** (ชื่ออื่นที่ขาดของชิ้นนั้นไม่ต้องขึ้น เพราะจะเอาออกอยู่แล้ว)
     กด → ยืนยัน → ลบชิ้นเหล่านั้นออกจากการ์ดและบันทึกขึ้น API (ใช้ได้ทั้งในหน้าแต่งและในคลังการ์ด) → คิดด่านใหม่
   - ชิ้นอื่นรวมชื่อที่ขาดเป็นแถว · `rate` รวมกับ `socials` (ถ้า `socials` ผ่านแล้ว ข้อความ = "เชื่อมแล้ว · ยังไม่ได้ตั้งเรท")
   - แถว `kyc`: ยังไม่ส่ง = กรอกได้ · รอตรวจ = "รอตรวจ" ไม่มีปุ่ม · ถูกปฏิเสธ = "ส่งใหม่" (เปิดขั้น KYC)
   - ปุ่มล่าง **"กรอกให้ครบ"** = วิซาร์ดเฉพาะขั้นที่กรอกได้ ต่อกันรวดเดียว (ไม่มีขั้นที่กรอกได้ = ไม่มีปุ่ม)
3. ปิดวิซาร์ด → โหลดเจ้าของใหม่ → คิดใหม่
   - ครบ → ทำสิ่งที่กดไว้ต่อทันที
   - ไม่ครบ → **เปิดชีตเดิมอีกครั้ง** แถวที่กรอกแล้วติ๊กเขียว (ห้ามปิดเงียบ)
4. ตรารับรองตรึงอยู่ทุกการ์ดและต้องการ `kyc` → **การ์ดออกไปข้างนอกได้หลังยืนยันตัวตนผ่านเท่านั้น** (= พฤติกรรมเดิมทั้งสามแพลตฟอร์ม) · ตราตรึงไม่มีทางถูกเอาออก (ไม่มี `work`)

---

## 6. ข้อมูลเจ้าของที่ต้องโหลด

| ใช้ทำ | field |
|---|---|
| 8 ตัวแรก | `creatorProfile.starItems { kind socials categories about provinces availability contact kyc }` |
| `kycState` | `myUserVerify.status` (ข้อความ/ปุ่มเท่านั้น) |
| `insight` | `socialProfileInsights[].completed` (ตัวเดียวกับหน้า Star Profile — ไม่ใช้ `socialProfiles[].insight`) |
| `body` | `creatorProfile.bodyMeasurement { weight height chest waist hip shoeSize }` |
| `rate` | `socialProfiles[] { photoPrice shortVdoPrice longVdoPrice sharingPrice }` |
| `work` | แคมเปญที่รีวิวแล้ว (`reviewed` = `works` ชุดเดียวกับที่วิดเจ็ตวาด) |

---

## 7. สิ่งที่ต้องแก้ ต่อแพลตฟอร์ม

### ทุกแพลตฟอร์ม
- [ ] ตัวอ่านผัง: `widget.requires: [String]?` · node `removeBg: Bool?` — ฟิลด์ใหม่ต้องไม่ทำผังพัง
- [ ] `LockFacts` + `isDone` + `missing` + `blocked` ตาม §3 ที่เดียว · หน้า Star Profile เรียกตัวนี้
- [ ] ลบการล็อกตามหมวดทั้งหมด (category เหลือไว้จัดกลุ่มในตู้อย่างเดียว)
- [ ] ด่าน §5 ครอบทุกทางออก (ข้อ 6) · ล็อก/ตัวอย่าง/ข้อความว่างเฉพาะฝั่งเจ้าของ (ข้อ 4–5)

### salehere-ios (path ใต้ `SaleHere/`)
| ไฟล์ | แก้ |
|---|---|
| `StarCardRender/WidgetSpec.swift` | เพิ่ม `requires` (Widget) · `removeBg` (node) — port จาก `salehere-starcard/StarCard/StarCard/Model/WidgetSpec.swift` |
| `Scene/StarCard/StarCardWidgetTray.swift` | `StarCardTrayLocks` / `lockGroup(forCategory:)` / `wizardStep` → `missing(spec)` + ชื่อ → `StarWizardStep` (§2) |
| `Scene/StarCard/StarCardLockGate.swift` | `lockedGroups` → ด่าน §5 (แถว `work` เอาออก · แถว KYC 3 สถานะ) · `recheck` โหลดไม่ได้ = ชีตพร้อม "ลองใหม่" (ตอนนี้ทิ้งคำขอเงียบ ๆ) |
| `Scene/StarCard/StarCardWidgetGallery.swift` | ป้าย = ชื่อแถวที่ขาด · แตะ = §4.1 |
| `Scene/StarCard/StarCardData.swift` | `hasFullBodyMeasurement` (ครบ 6) → `hasBody` (≥ 1) · `hasCompletedInsight` อ่าน `socialProfileInsights` · `hasWork` = `works` ไม่ว่าง |
| `Scene/StarProfile/Shared/StarProfileDomain.swift` | `has(topic)` → เรียก `isDone` ตัวกลาง (สูตรเดิมตรงอยู่แล้ว) |
| ทางออกอื่น (บันทึกรูป · คัดลอกลิงก์ · ปุ่มลิงก์บนการ์ด) | ผ่านด่าน §5 |

### salehere-android (`origin/feature/star-card-redisign` · path ใต้ `app/src/main/java/com/salehere/android/app/` — `starcardkit/` = `compose/component/starcardkit/` · `starcardhost/` = `compose/ui/star/starcardhost/`)
| ไฟล์ | แก้ |
|---|---|
| `starcardkit/model/spec/StarCardKitSpecCatalog.kt:9` | **ด่วน** `ignoreUnknownKeys = false` → ผังที่มี `removeBg` / `requires` ถูกทิ้งทั้งใบ · แก้พร้อมเพิ่มฟิลด์ข้างล่าง |
| `starcardkit/model/spec/StarCardKitWidgetSpec.kt` · `StarCardKitSpecNode.kt` | เพิ่ม `requires` · `removeBg` |
| `starcardkit/model/widget/StarCardKitWidgetFamily.kt` · `StarCardKitTopic.kt` | `topic` / `missing` / `lockedTopic` → `missing(spec)` · SEAL เลิกใช้ `isVerified` แยก (ใช้ `isDone("kyc")`) · เลิกแยก `MEDIA` / `ABOUT` · `Work` เลิกไป `PORTFOLIO` |
| `models/starcard/StarCardOwner.kt:154` | body `.all { != null }` → `.any { != null }` |
| `models/starcard/owner/StarCardFlow.kt` | `toStarDataKeys` → `LockFacts` · `reviewed` = `works` ไม่ว่าง (เลิกนับ `brands`) |
| `compose/ui/star/profile/uimodels/StarProfileDataRowUiModel.kt:35` | ติ๊กถูกเรียก `isDone` · `starItems` null = ไม่ผ่าน (เลิก fallback `facts.isNotEmpty()` ของ 8 แถวหลัก) |
| `starcardhost/uimodels/StarCardLockRowUiModel.kt` | ไม่กรอง `Work` ทิ้ง → แถวเอาออก · แถว KYC ใช้ `IdentityWaiting` / `IdentityRejected` ที่มีอยู่ |
| `starcardhost/StarCardHostViewModel.kt` | `resumeStarCardLockGate` ไม่ครบ → เปิดชีตเดิม (ไม่ปิดเงียบ) · ก่อนด่านโหลดเจ้าของใหม่ (ไม่ใช้ `_ownerSection` ค้าง) |
| `StarCardEditorState.kt` · `StarCardEditorViewModel.kt` | แตะใบล็อก → วิซาร์ดเฉพาะ `missing` (ไม่ใช่ขั้นเดียว) · `viewerTap` เปิดได้เฉพาะเจ้าของ และคิดจากข้อมูลเจ้าของการ์ด |
| `StarCardProfile.kt` `missingFamilies` | ข้อมูลตัวอย่างตัดสินจาก `missing` ตัวเดียวกัน และเฉพาะเจ้าของ |

### salehere-web (`feature/new-star-card` · path ใต้ `src/components/features/`)
| ไฟล์ | แก้ |
|---|---|
| `star-card/card-doc.ts` `lockedGroups` / `ownerUnlocks` | → `missing(spec)` · body `every` → `some` · insight อ่าน `socialProfileInsights` |
| `star-card/lock-gate.ts` `GATE_RULE` | → ด่าน §5 (รวม `work` · KYC 3 สถานะ · words/brand/verified ไม่มีกรณีพิเศษแล้ว) |
| `star-card/engine/kinds.js` `CATEGORY_GROUP` · `engine/chrome.js` | ป้ายล็อกอ่าน `missing` · ข้อความ "ยังไม่มีข้อมูล" (`pendingText`) เฉพาะเจ้าของ |
| `star-card/engine/data.js` | `sampleFamilies` / รูปตัวอย่าง (`sampleURL`) เฉพาะเจ้าของ · avatar default ของระบบ = ไม่มีรูป (`realAvatarUrl` เหมือน `snapshot.ts`) |
| `star-profile/flow/star-rules.ts` `has` | เรียก `isDone` ตัวกลาง (สูตรเดิมตรงอยู่แล้ว) |
| ทางออก (แชร์ · บันทึกรูป · คัดลอกลิงก์) | ผ่านด่าน §5 (`useCardGate`) |

### server / API
- [ ] เสิร์ฟ JSON ชุดใหม่จาก `shared/WidgetSpecs` (มี `requires` ทุกใบ · `removeBg` 9 ใบ) — **ตามลำดับ §8**

---

## 8. ลำดับปล่อย (สำคัญ)

Android ที่ใช้งานอยู่ตอนนี้ **ทิ้งผังทั้งใบเมื่อเจอคีย์ที่ไม่รู้จัก** — API เสิร์ฟ JSON ใหม่ก่อน = วิดเจ็ตหายจาก Android ทุกใบ (9 ใบที่มี `removeBg` หายทันทีที่ JSON 6 พ.ย. ขึ้น API)

1. **Android** ออกรุ่นที่อ่าน `requires` + `removeBg` ได้ (ยังไม่ต้องใช้)
2. **API** เสิร์ฟ JSON ใหม่ให้ Android รุ่นตามข้อ 1 ขึ้นไป (รุ่นเก่า: บังคับอัปเดต หรือส่ง JSON เดิม) · iOS / web รุ่นเก่าไม่อ่านคีย์ใหม่ ไม่พัง (ล็อกตามหมวดเดิมต่อ)
3. **iOS · Android · web** เปลี่ยนเป็นล็อกตาม `requires` (§3–5) — ปล่อยแยกกันได้ ไม่ต้องรอกัน
4. ผังที่ไม่มี `requires` (ไม่ควรเกิด · ตัวตรวจบังคับทุกใบ) = `[]` ไม่ล็อก

---

## 9. เคสขอบ

| เคส | ผล |
|---|---|
| `starItems` null / โหลดเจ้าของไม่ได้ | 8 ตัวแรกไม่ผ่าน · ชีต/หน้าโชว์ "โหลดไม่ได้ · ลองใหม่" · ด่านไม่ให้ผ่าน |
| ชื่อที่แอปไม่รู้จัก | ไม่ผ่าน · `blocked` → "อัปเดตแอป" · ด่าน: ชิ้นนั้นต้องเอาออก (เหมือน `work`) · ใบอื่นปกติ |
| วิดเจ็ตหลายแบบ (variants / ตัวเลือกซ่อนบางส่วน) | `requires` = รวมทุกแบบ (ซ่อนส่วนนั้นไว้ก็ยังล็อก — ตั้งใจให้ง่าย) |
| ข้อมูลหายหลังการ์ดออกไปแล้ว | ฝั่งเจ้าของล็อกกลับ · คนอื่นเห็นข้อมูลจริง (อาจว่าง) ไม่มีตัวอย่าง ไม่มีป้าย |
| `contact` | ต้องมีทั้งเบอร์และ LINE (ตามติ๊กถูก) — ใบที่โชว์แค่เบอร์ก็ยังรอทั้งคู่ · เว็บไซต์ไม่อยู่ในเงื่อนไข |
| `about` | server ต้องมีรูปครีเอเตอร์ + ผลงาน + คลิป + แนะนำตัว — ใช้ตามนั้น (ตรงกับติ๊กถูก) |
| works/brands ที่ใช้แค่ไอคอนเดียว (`limit: 1`: galleryPost · workFeatured · workReel) | ไม่ทำให้ล็อก · ไม่มีงาน = ไอคอน/วงกลมหาย (`if: list:works>0`) |
| รูป `photo` ช่อง (mod 12) 1–3 | ไม่ทำให้ล็อก: รูปครีเอเตอร์ → avatar บัญชี (avatar default ของระบบ = ไม่มี) → ว่าง · ช่องอื่น + `photoRef`: รูปผลงาน → ว่าง (ฝั่งข้อมูลจริงห้ามรูปตัวอย่าง) |
| `removeBg` | ไม่เกี่ยวกับล็อก — แอปตัดพื้นหลังรูปครีเอเตอร์ช่องนั้นให้เองก่อนวาด (`WIDGET-SPEC.md` §3.1) |

---

## 10. เช็กว่าทำถูก (ชุดเดียวกันทั้งสามแพลตฟอร์ม)

| # | ข้อมูลเจ้าของ | ทำ | ต้องได้ |
|---|---|---|---|
| 1 | ใหม่หมด (starItems ทุกตัว false) | เปิดตู้ | ใช้ได้ 6 ใบ (`requires: []`) · ที่เหลือล็อก |
| 2 | กรอกส่วนสูงค่าเดียว | ดูแถวสัดส่วน + kitBody* | ติ๊กเขียว **และ** ใบปลดพร้อมกัน |
| 3 | ผูก IG ไม่ใส่ราคา | ดู kitRate* / rateTags | ล็อก · ป้าย "เรทรับงาน" · แตะ → ขั้นช่องทาง |
| 4 | ข้อ 3 แล้วใส่ราคา IG ฿1,000 | กลับมาที่ตู้ | ปลด |
| 5 | ครบทุกข้อ ยกเว้น `provinces` | ดู popHeroGlass | ล็อก · ป้าย "พื้นที่รับงาน" |
| 6 | ขาดทั้ง `provinces` และ `availability` | แตะ kitTime* | วิซาร์ด 2 ขั้นต่อกัน → ครบ → ใบถูกวาง |
| 7 | ผ่าน KYC + `about` · ไม่มีงานรีวิว · การ์ดจากเทมเพลตมี proofWork | กดแชร์ | ชีตมีแถว "ผลงานกับ Sale Here" ปุ่มเอาออก · กด → ยืนยัน → ชิ้นหาย → แชร์ต่อ |
| 8 | ผ่าน KYC · ขาด `contact` · การ์ดมี contactCard | กดแชร์ → กรอกให้ครบ → ออกกลางทาง | ชีตเดิมกลับมา แถวที่กรอกแล้วติ๊กเขียว |
| 9 | KYC รอตรวจ | กดแชร์ / แตะตรารับรอง | แถว "รอตรวจ" ไม่มีปุ่ม · ไม่เปิดวิซาร์ด · ออกไปไม่ได้ |
| 10 | คนอื่นเปิดลิงก์การ์ด | — | ไม่มีป้ายล็อก ไม่มีข้อความว่าง ไม่มีตัวอย่าง |
| 11 | ผังมี `"requires": ["future"]` | เปิดตู้ | ใบจาง "อัปเดตแอป" · ไม่ crash · ใบอื่นปกติ |
| 12 | Android รุ่นใหม่ + JSON ที่มี `removeBg` / `requires` | เปิดตู้ | ครบ 116 ใบ ไม่มีใบหาย |
| 13 | ผ่าน KYC · ขาด `contact` | กด "บันทึกรูป" หรือคัดลอกลิงก์ | ด่านเดียวกับแชร์ |
| 14 | ปิดเน็ตแล้วกดแชร์ | — | ชีต "โหลดไม่ได้ · ลองใหม่" ไม่แชร์ |

---

## 11. ดูแลไฟล์ผัง

- แก้/เพิ่มผัง → `node shared/tools/check-widgets.mjs --write-requires` → `node shared/tools/check-widgets.mjs` ต้องผ่าน
- **ห้ามเขียน `requires` ด้วยมือ** — ตัวตรวจคิดจาก binding และ error ทันทีถ้าไม่ตรง
