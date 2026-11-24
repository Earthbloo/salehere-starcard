# Insight: เลือก Social ต่อวิดเจ็ต → iOS / Android

ตอนนี้ผู้ใช้ผูก Insight ได้หลาย Social แล้ว แต่วิดเจ็ตผู้ชมยังเลือกไม่ได้ว่าจะใช้ข้อมูลจาก Social ไหน และไม่รู้ด้วยว่าตอนนี้ใช้ของช่องไหนอยู่ งานนี้เพิ่มแถว **"ช่องทาง"** ในถาดของวิดเจ็ต Insight ทุกตัว

- **ตอนนี้เป็นยังไง:** ข้อมูลทุกช่องถูกรวมเป็นก้อนเดียว และหยิบแยกทีละหัวข้อจากช่องแรกที่เจอ ตามลำดับ IG → TikTok → FB → YouTube (ต้นแบบ: `StarFlow.audience()`) ผลคือเพศอาจมาจาก IG แต่อายุมาจาก TikTok
- **หลังแก้:** วิดเจ็ตหนึ่งตัวใช้ข้อมูลจาก **Social เดียวเท่านั้น** ค่าเริ่มต้นคือช่องที่มีผู้ติดตามมากที่สุด และผู้ใช้เปลี่ยนเองได้
- **API ไม่เปลี่ยน:** ใช้ `SocialProfileInsights.gender / age / location [{label, percentage}]` ของแต่ละ social profile ที่มีอยู่แล้ว
- **หน้าตาวิดเจ็ตไม่เปลี่ยน:** แก้แค่ JSON `widget.controls` กับตัวอ่านข้อมูล

---

## 1. กติกา (ตัดสินแล้ว)

| # | กติกา |
|---|---|
| R1 | วิดเจ็ต Insight หนึ่งตัวใช้ข้อมูลจาก **Social เดียว** ห้ามเอาหัวข้อจากช่องอื่นมาปน |
| R2 | ตัวเลือกขึ้นเฉพาะช่องที่ **รองรับ Insight** (Facebook · Instagram · YouTube · TikTok) **และ** ผูกบัญชีอยู่ **และ** มีข้อมูลหัวข้อที่วิดเจ็ตต้องใช้ (ข้อ 2) ส่วน X กับ Lemon8 ไม่ขึ้นเลย |
| R3 | เรียงตามผู้ติดตามจากมากไปน้อย ถ้าเท่ากันใช้ลำดับ IG → TikTok → FB → YouTube |
| R4 | ค่าเริ่มต้นคือ **อันแรกในรายการ** และไม่เก็บลงไฟล์ จนกว่าผู้ใช้จะกดเลือกเอง |
| R5 | ถ้าเหลือ **ช่องเดียว** ไม่ต้องโชว์แถว "ช่องทาง" ให้ใช้ช่องนั้นเลย |
| R6 | ถ้า **ไม่มีช่องไหนผ่านเลย** วิดเจ็ตขึ้น "ข้อมูลผู้ชม — รอ…" (สถานะ pending เดิม) และห้ามเอาข้อมูลตัวอย่างขึ้นการ์ดจริง |
| R7 | ถ้าช่องที่ผู้ใช้เลือกไว้ไม่ผ่านแล้ว (เช่น ลบ Insight หรือยกเลิกผูกบัญชี) ให้กลับไปใช้ค่าเริ่มต้น (R4) ตอนวาด และ**ไม่ต้องลบ**ค่าที่เก็บไว้ ถ้าช่องนั้นกลับมา วิดเจ็ตจะกลับไปใช้ช่องเดิมเอง |
| R8 | หัวข้อที่ช่องที่เลือก**ไม่มีข้อมูล ห้ามวาด** และไม่ขึ้นในช่องติ๊ก "ข้อมูล" ของถาด (ใช้กับวิดเจ็ตแบบ `any` ในข้อ 2) |

---

## 2. วิดเจ็ตไหนต้องใช้หัวข้ออะไร

ข้อมูล Insight ของแต่ละช่องมี 3 หัวข้อ ช่องหนึ่งถือว่า "มีหัวข้อนั้น" เมื่อรายการของหัวข้อนั้นไม่ว่าง

| คีย์ในถาด / JSON | ข้อมูลจาก API | รายการที่ผังอ่าน |
|---|---|---|
| `gender` | `insights.gender` | `gender` |
| `age` | `insights.age` | `ages` |
| `city` | `insights.location` | `places` |

แต่ละวิดเจ็ตมีวิธีเช็ก (`match`) อย่างใดอย่างหนึ่ง:
- **`all`**: ช่องนั้นต้องมี**ครบทุก**หัวข้อใน `needs` ใช้กับวิดเจ็ตที่ layout ตายตัว ซ่อนบล็อกไม่ได้
- **`any`**: มีอย่างน้อยหนึ่งหัวข้อใน `needs` ก็พอ ใช้กับชุด kitInsight ที่มีช่องติ๊กซ่อนบล็อก หัวข้อที่ช่องนั้นไม่มีให้ซ่อนตาม R8

| ไฟล์ (`shared/WidgetSpecs/05-ผู้ชม/`) | `needs` | `match` |
|---|---|---|
| `audienceAge.json` | `["age"]` | `all` |
| `audienceMap.json` | `["city"]` | `all` |
| `audienceSplit.json` | `["gender"]` | `all` |
| `audienceLine.json` | `["city","gender","age"]` | `all` |
| `audiencePoster.json` | `["city","gender","age"]` | `all` |
| `scrapStats.json` | `["city","gender","age"]` | `all` |
| `kitInsightCream.json` · `kitInsightGingham.json` · `kitInsightMac.json` · `kitInsightNight.json` · `kitInsightPurple.json` | `["city","gender","age"]` | `any` |

---

## 3. JSON: เพิ่มตัวเลือกใน `widget.controls` (11 ไฟล์)

ให้เป็น**แถวแรก**ของ `controls` ถ้าไฟล์ไหนยังไม่มี `controls` (`audience*`, `scrapStats`) ให้สร้าง array ใหม่

```json
{ "type": "pick", "label": "ช่องทาง", "opt": "social",
  "items": "insightSocials", "needs": ["city", "gender", "age"], "match": "any",
  "minItems": 2 }
```

- `type: "pick"`: ตัวควบคุมที่มีอยู่แล้วทั้งสองแพลตฟอร์ม (ใช้แบบเดียวกับ "ช่องทาง" ใน `socialGingham` / `rateTags`) ถ้า `options[opt]` ว่างจะใช้รายการแรกเอง
- `opt: "social"`: เก็บที่ `widget.options["social"]` เป็น raw ของ `SocialType` เช่น `"instagram"`
- `items: "insightSocials"`: **แหล่งรายการใหม่** (ข้อ 4)
- `needs` / `match`: **ฟิลด์ใหม่ของ control** แต่ละไฟล์ใส่ค่าตามตารางข้อ 2 ถ้าไม่ใส่ `match` ให้ถือเป็น `all`
- `minItems: 2`: ทำให้ R5 เป็นจริงเอง โดยไม่ต้องเขียนโค้ดเพิ่ม

> ตามกฎ widget-json-only ในโค้ดห้ามมีชื่อวิดเจ็ต หัวข้อที่วิดเจ็ตใช้ต้องมาจาก `needs` ใน JSON เท่านั้น

---

## 4. ตรรกะกลาง (ต้องเหมือนกันทั้ง iOS และ Android)

```text
// ข้อมูล: แยก Insight ตามช่อง (ห้ามรวมเป็นก้อนเดียวแล้ว)
audiences: [SocialType: AudienceInsight]       // จาก socialProfiles[].insights
has(s, topic) = audiences[s].<topic> ไม่ว่าง      // gender: female+male+other > 0

// รายการตัวเลือก (items: "insightSocials")
func insightSocials(needs, match, hidden) -> [SocialType]
    req = needs                                          // `hidden` ไม่ตัดออกจาก req (ดู R8)
    ok(s) = s.supportsInsight && s ผูกอยู่ &&
            (match == "all" ? req.all { has(s, $0) } : req.any { has(s, $0) })
    return socials.filter(ok)
                  .sorted(by: followers desc, แล้วลำดับ IG, TikTok, FB, YT)

// ช่องที่วิดเจ็ตใช้วาด
func resolvedSocial(widget, control) -> SocialType?
    list = insightSocials(control.needs, control.match, widget.hidden)
    if let v = widget.options["social"], list.contains(v) { return v }   // R7
    return list.first                                                     // R4 · nil = pending (R6)

// หัวข้อที่ซ่อนจริงตอนวาด (R8)
effectiveHidden = widget.options["hide"] ∪ { t in needs | !has(resolvedSocial, t) }
```

- **ใน sample mode** (ตู้วิดเจ็ตกับใบที่ล็อก) ยังใช้ `Mock.creator.audience` เหมือนเดิม ไม่ต้องแยกช่อง และไม่ต้องโชว์แถว "ช่องทาง"
- **`hidden` ไม่มีผลกับรายการช่อง** เพราะถ้ามี รายการช่องกับช่องติ๊กจะขึ้นต่อกันวนไปมา ลำดับที่ถูกคือ เลือกช่องก่อน → ช่องติ๊กโชว์เฉพาะหัวข้อที่ช่องนั้นมี
- **`audiencePoster`:** ตัวเลข reach (`stat:reach*`) ยังเป็น mock รอ OAuth ปล่อยไว้ก่อน ตอนต่อของจริงค่อยให้อ่านของช่องที่เลือกด้วย
- **`stat:countsUpdated`:** ถ้า API มีวันที่อัปเดตแยกตามช่อง ให้ใช้วันที่ของช่องที่เลือก

---

## 5. iOS: จุดที่ต้องแก้

อ้างชื่อตามต้นแบบ (`salehere-starcard/StarCard`) ใน salehere-ios ให้แก้จุดที่ทำหน้าที่เดียวกัน

| ที่ | แก้อะไร |
|---|---|
| ข้อมูลโปรไฟล์ (`Profile` / `CreatorProfile.audience`) | เปลี่ยน `audience: AudienceInsight` เป็น `audiences: [SocialType: AudienceInsight]` โดยสร้างจาก `insights` ของ social profile แต่ละช่อง และ**ลบ**ตรรกะเดิมที่ "หยิบจากช่องแรกที่เจอ" (`StarFlow.audience()`) |
| `Model/WidgetSpec.swift` → `KitControl` | เพิ่มฟิลด์ `needs: [String]?` และ `match: String?` แล้วต่อท้ายคอมเมนต์ของ `items` ด้วย `insightSocials` |
| `Views/CardScreen.swift` → `controlItems(_:)` | เปลี่ยน signature ให้รับ `ctl` กับ `sel` ด้วย เพิ่ม `case .source("insightSocials")` ที่คืนค่า `insightSocials(...)` เป็นคู่ `(rawValue, shortName)` |
| `Views/CardScreen.swift` → `controlChecks(...)` | สำหรับวิดเจ็ต audience: ตัดหัวข้อที่ช่องที่เลือกไม่มีออกจาก `items` (R8) ส่วน `minShown 1` ให้นับจากรายการที่เหลือ |
| `Views/Widgets/SpecPainter.swift` → `IOSSpecData` | เพิ่ม `var shownAudience: AudienceInsight` ที่อ่าน `kit.opts["social"]` ผ่าน `resolvedSocial` แล้วเปลี่ยน `p.shownAudience` ทุกจุด (`ages`, `places`, `gender`, `stat:placeCount`, `stat:reach*`) ให้ใช้ตัวนี้ ส่วนเงื่อนไข `hidden:city/gender/age` ให้อ่านจาก `effectiveHidden` |
| `Views/Widgets/WidgetShared.swift` → ข้อความ pending (`case .audience`) | เปลี่ยนจาก `c.audience.isEmpty` เป็น `resolvedSocial == nil` ของวิดเจ็ตนั้น (R6) |
| `Model/Profile.swift` → `lacks(.audience)` | เปลี่ยนเป็น "ไม่มีช่องไหนมี Insight เลย" (`audiences.isEmpty`) |

---

## 6. Android: จุดที่ต้องแก้

| ที่ | แก้อะไร |
|---|---|
| `model/Profile.kt` (`creator.audience`, `lacks(audience)`) | แยกเป็น `audiences: Map<SocialType, AudienceInsight>` เหมือน iOS |
| `model/WidgetSpec.kt` → `KitControl` | เพิ่ม `needs: List<String>?` และ `match: String?` |
| `ui/CardScreen.kt` → `controlItems(...)` (~บรรทัด 1829) | เพิ่ม `"insightSocials" ->` ที่คืนรายการเดียวกับ iOS ทั้งลำดับและเงื่อนไข และต้องรับ `sel` + `ctl` ด้วย |
| `ui/CardScreen.kt` → แถว `"checks"` | ตัดหัวข้อที่ช่องที่เลือกไม่มีออก (R8) |
| `model/SpecData.kt` → `shownAudience` (บรรทัด 57) | อ่าน `kit.opts["social"]` ผ่าน `resolvedSocial` แล้วใช้ตัวนี้ทุกจุด (`ages` `places` `gender` `stat:*`) และให้ `hidden:*` อ่าน `effectiveHidden` |
| `ui/widgets/WidgetShared.kt` → `audienceIsEmpty` | เปลี่ยนเป็นเช็ก `resolvedSocial == null` ของวิดเจ็ตนั้น |

> **ข้อควรรู้:** Android ในต้นแบบยังไม่มีข้อมูล Insight จาก Star Profile เลย การ์ดขึ้น mock อยู่ ในแอปจริงให้ดึงจาก API ตามข้อ 4

**Web (`sync-server/web/js/data.js` บรรทัด 352 `get audience()`):** การ์ดที่แชร์เป็นลิงก์ต้องแก้แบบเดียวกัน ไม่งั้นในแอปกับบนเว็บจะขึ้นคนละช่อง

---

## 7. เคสทดสอบ

| # | ข้อมูลที่ผูกไว้ | วิดเจ็ต | ผลที่ต้องได้ |
|---|---|---|---|
| T1 | IG 50K (ครบ 3) · TikTok 120K (ครบ 3) | ทุกตัว | แถว "ช่องทาง" = **TikTok \| IG** ค่าเริ่มต้นเป็น TikTok |
| T2 | ข้อมูลเดียวกับ T1 แล้วกด IG | `kitInsightCream` | ทุกบล็อกเป็นของ IG ปิดแอปเปิดใหม่แล้วยังเป็น IG |
| T3 | IG (ครบ 3) · TikTok (มีแค่อายุ) | `audienceAge` | TikTok \| IG |
| T4 | ข้อมูลเดียวกับ T3 | `audienceLine` | มีแค่ IG ผ่าน จึง**ไม่มีแถว**ช่องทาง (R5) และวาดของ IG |
| T5 | ข้อมูลเดียวกับ T3 | `audienceSplit` (เพศ) | มีแค่ IG ไม่มีแถว และ**ไม่**เอาข้อมูล TikTok มาปน |
| T6 | ผูก X / Lemon8 ไว้ด้วย | ทุกตัว | X กับ Lemon8 ไม่ขึ้นในรายการ |
| T7 | YouTube มีแค่เพศ | `audienceAge` | ขึ้น "ข้อมูลผู้ชม — รอ…" (R6) |
| T8 | IG มีแค่เพศกับอายุ | `kitInsightNight` | ตัวเลือกช่องทางคือ IG ช่องติ๊กโชว์แค่ เพศ · อายุ และไม่วาดบล็อกเมือง (R8) |
| T9 | ตาม T1 กด TikTok แล้วไปลบ Insight ของ TikTok | ทุกตัว | กลับไปเป็น IG (R7) พอแนบ TikTok กลับมา ก็กลับเป็น TikTok |
| T10 | ยังไม่มี Insight เลย | ตู้วิดเจ็ต / ใบที่ล็อก | ขึ้นตัวอย่างเหมือนเดิม และไม่มีแถว "ช่องทาง" |
