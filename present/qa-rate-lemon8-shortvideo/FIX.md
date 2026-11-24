# QA Reject — เรตราคา Lemon8 ไม่แสดง Short Video

| | |
|---|---|
| หน้า | STAR Card → edit card → widget หมวด "เรตราคา" ทุกตัว |
| Environment | SIT (account 0811111159) |
| อาการ | Lemon8 แสดงแค่ Photo · ราคา Short Video หาย |
| คาดหวัง | แสดงทั้ง Photo และ Short Video |

## สาเหตุ

ตอนแปลงราคาจาก API (`socialProfiles[].photoPrice / shortVdoPrice / longVdoPrice / sharingPrice`) เป็นข้อมูลการ์ด
โค้ดจะหา "รูปแบบงานแรกของแพลตฟอร์มที่เป็นประเภทนั้น" — แต่ Lemon8 มีแค่ `photo` กับ `seeding` **ไม่มี `shortVideo`**
→ หาไม่เจอ → `shortVdoPrice` ถูกทิ้ง

X (Twitter) เป็นแบบเดียวกัน (Star Profile ให้กรอก Short Video ได้ แต่การ์ดไม่มีที่ลง)

JSON widget ไม่ต้องแก้ — kitRate* / rateTags แสดงทุกช่องที่มีราคาอยู่แล้ว (`"if": "$shortVideo"`)

## แก้ใน salehere-ios

`SaleHere/Scene/StarCard/StarCardData.swift` บรรทัด 187–188 (`Platform.formats`)

```diff
-            case .lemon8: return [("photo", "โพสต์ภาพ (Photo Set)", "photo"), ("review", "รีวิวยาว + แท็กสินค้า", "seeding")]
-            case .x: return [("post", "โพสต์ + ภาพ", "photo"), ("thread", "เธรดรีวิว (3 โพสต์ขึ้นไป)", "seeding")]
+            case .lemon8: return [("photo", "โพสต์ภาพ (Photo Set)", "photo"), ("video", "คลิปสั้น", "shortVideo"),
+                                  ("review", "รีวิวยาว + แท็กสินค้า", "seeding")]
+            case .x: return [("post", "โพสต์ + ภาพ", "photo"), ("video", "โพสต์วิดีโอ", "shortVideo"),
+                             ("thread", "เธรดรีวิว (3 โพสต์ขึ้นไป)", "seeding")]
```

ไม่ต้องแตะจุดอื่น — `rates` (บรรทัด ~425) และ `case "rateSocials"` ใช้รายการนี้อยู่แล้ว

## แก้แล้วใน salehere-starcard (ต้นแบบ)

| ไฟล์ | |
|---|---|
| `StarCard/StarCard/Model/Intake.swift` | `SocialType.formats` · lemon8 + x เพิ่ม `video` → `.shortVideo` |
| `StarCardAndroid/.../model/Intake.kt` | เหมือนกัน |
| `sync-server/web/js/data.js` | `FORMATS.lemon8.video` · `FORMATS.x.video` |

## ทดสอบ

1. Star Profile → เรตราคา → Lemon8 ใส่ทั้ง Photo และ Short Video (เช่น 2,389 / 1,500)
2. เปิด STAR Card → edit card → วาง widget เรตราคาทุกตัว (Cream / Gingham / Mac / Night / Purple / rateTags)
3. แถว Lemon8 ต้องมี **Short Video** และ **Photo** คู่กัน เหมือนแถว Instagram / Facebook
4. ทำซ้ำกับ X (Short Video + Seeding)
5. ช่องที่ราคา = 0 ต้องไม่แสดง (เดิม)
