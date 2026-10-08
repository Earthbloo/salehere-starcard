# Unbox flow mock (Sale Here STAR)

เว็บจำลอง flow "Sale Here STAR / Unbox" ของแอป salehere-ios ตั้งแต่เห็นงานจนส่งรีวิวเสร็จ
เปลี่ยน state ได้ทุกตัวจากแผงด้านขวา ไม่ต้อง build ไม่มี dependency

## สองโหมด

- `index.html` = **flow Unbox เดิม** ทุกหน้าตามแอปจริง
- flow ใหม่ = flow เดิมทั้งหมด + "หน้ากรอกข้อมูล Star Profile" ที่แทรกก่อนถึงหน้าเดิม (สลับได้จากแผง) · `new.html` ลบแล้ว (7 ต.ค. 2569) — flow ใหม่ตัวจริงอยู่ที่ `desktop/` (พอร์ต 8796)

หน้าแทรกเป็น **wizard หนึ่งคำถามต่อหนึ่งหน้า** (หัวข้อ 1 บรรทัด · ช่องกรอกเดียว · ปุ่มถัดไป · แถบความคืบหน้า · "สมัคร EP.xxxx n/N" บอกบริบท) ในภาษา UI ของ StarCard iOS (พื้น #F9FAFB · ปุ่มถ่านแคปซูล · เลือกแล้ว = เทา + ขอบดำ) ขั้นที่มีข้อมูลแล้วไม่โผล่ · หน้าสุดท้ายบอกปลายทาง "ต่อไป: ฟอร์มสมัคร (หน้าเดิม)"

| จุดแทรก | หน้าแทรก | ถามเฉพาะที่ยังไม่มี | แล้วไปหน้าเดิม |
|---|---|---|---|
| กดสมัคร | `fillProfile` | โซเชียล 1 ช่อง · สายที่ใช่ · แนะนำตัว · ยืนยันตัวตน (ส่งต่อได้ระหว่างรอตรวจ) · เรทต่อรูปแบบคอนเทนต์ · ข้อมูลผู้ติดตาม (ไม่บังคับ) · จังหวัด · วันเวลาว่าง — แบรนด์คัดทันทีหลังลงทะเบียน ข้อมูลจึงต้องครบก่อนส่ง (ออกกลางคันมี dialog เก็บไว้ทำต่อ) | การ์ดเกิด → ฟอร์มสมัครเดิม (`register` — flow ใหม่ตัดช่องที่อยู่ออก เหลือชื่อ+เบอร์) |
| การ์ดเพิ่งเกิด | `cardReveal` | "คุณเป็น STAR แล้ว" โทนสว่าง (ไม่มีคำว่าระดับ/Level) + รายการ "เติมการ์ดให้เต็ม" แบบหน้า ข้อมูลของฉัน ใน iOS: มี = ติ๊กเขียว + ชิปสรุป · ยังไม่มี = ประโยชน์ 1 บรรทัด + ปุ่ม "+ เพิ่ม" → เปิด wizard ข้อเดียว (`fillOne`) แล้วกลับมาหน้านี้ | ฟอร์มสมัครเดิม | · **ยังไม่ครบ:** ข้อที่ขาดขึ้นก่อน ข้อที่ครบรวมเป็น "ครบแล้ว N อย่าง" · ตัวเลข + แถบ "5/10" · ปุ่มหลัก "เติมอีก N อย่าง" = wizard ต่อเนื่องเฉพาะข้อที่ขาด · ฟอร์มสมัครลดเป็นลิงก์ "ข้ามไปก่อน" · แชร์ซ่อนจนครบ
| ปุ่ม "โปรไฟล์ครีเอเตอร์" (แท็บโปรไฟล์) | `profileHub` (flow ใหม่ render เป็น Star Profile) | หน้าเดียวกับการ์ดเกิดแต่ไม่มี intro · สไตล์ glass (`.ach2.glass`): พื้นสว่าง + แสงเบลอ champagne · หัวข้อ "Star *Profile*" · การ์ดกระจกขอบเหลืองนิดๆ + รายการเติมข้อมูลเป็นกระจก · ยังไม่มีการ์ด = หัวข้อ "สร้าง Star Card ของคุณ" + ปุ่มสร้างการ์ด (3 ข้อ) · มีแล้ว = ปุ่มแชร์การ์ด | กลับแท็บโปรไฟล์ |
| กดตอบรับ | `fillAccept` | ที่อยู่รับของ · บัญชีรับเงิน · รอบแก้ (ถามตอนได้งานแล้วเท่านั้น) | หน้าตอบรับเดิม (`accept`) |

แผงของ flow ใหม่มีแค่ 2 อย่าง: **State ของ Unbox** (happy case 13 ขั้นเป็นลำดับเดียว กดเพื่อไป ขั้นก่อนหน้าติ๊กข้อมูลให้เอง) และ **ข้อมูลใน Star Profile** (13 ช่อง รวม KYC) · กติกา: **ติ๊กข้อมูลออกตอนอยู่ขั้นที่ต้องมีแล้ว = ย้อน state กลับไปขั้นที่ขอข้อมูลนั้น** (เช่น ติ๊กที่อยู่ออกตอนทำงานอยู่ → กลับไป "ก่อนตอบรับ")

ติ๊กเข้า/ออกได้ทุกช่อง: **มี** = พาเนลพับ "ครบแล้ว" · **ไม่มี** = พาเนลกางให้กรอก · กรอกจริงแล้วช่องนั้นกลายเป็น "มี" ทันที งานถัดไปเติมให้เอง (เล่นจนจบได้เหมือนใช้จริง)

## เปิดใช้

```bash
python3 -m http.server 8765 --directory unbox-mock
```

แล้วเปิด http://localhost:8765 (หรือ `preview_start unbox-mock` ใน Claude)

## แผงควบคุม (ขวา)

- **ขั้นทั้ง 14** กดเพื่อกระโดดไปขั้นนั้นทันที (ตั้ง state + หน้าจอให้)
- **ฉากสำเร็จรูป** ผู้ใช้ใหม่ / ยังไม่ล็อกอิน / STAR 67% / ครบ 100% / โดนบล็อก / ได้รับเลือก / ตัวสำรอง / ดราฟต์ไม่ผ่าน / ส่งลิงก์ / เสร็จสิ้น ฯลฯ
- **กิจกรรม** `BrandCampaignState` · `BrandCampaignReviewState` · `OrderStatus` · `QuotaType` · ผลประกาศ · อ่านบรีฟแล้ว · แท็บรีวิว
- **ผู้ใช้** ล็อกอิน · onboarding 3 ขั้น (ผูกโซเชียล / เลือกหมวด / ยืนยันตัวตน) · โปรไฟล์ครีเอเตอร์ % · `UserVerifyStatus` (KYC) · `PunishmentStatus` · `BrandCampaignReviewStatus` · ผล AI ตรวจบัตร
- **หน้าจอ** เลือกหน้าตรง ๆ · คัดลอกลิงก์ (state ถูกเข้ารหัสใน URL hash) · รีเซ็ต

state จำไว้ใน `localStorage` และ URL hash → รีเฟรชแล้วอยู่ที่เดิม ส่งลิงก์ให้คนอื่นเปิดที่ state เดียวกันได้

## หน้าที่จำลอง (ตาม salehere-ios 2.114)

| หน้า | ต้นทางใน iOS |
|---|---|
| หน้าแรก STAR (การ์ด 175×250, lottie title) | MainPageSalehereStarView · UnboxListCollectionViewCell |
| โปรไฟล์ (tile Sale Here STAR, การ์ดยืนยันตัวตน 4 สถานะ) | MyProfile · VerifyUserStatusView |
| หน้ากิจกรรม + ปุ่มล่างทุก state + นาฬิกา | UnboxInfo · UnboxStateView · BrandCampaignState / ReviewState |
| ด่านสมัคร: ล็อกอิน → ค้างรีวิว → 3 ขั้น → 100% | ValidateRegisterSaleHereStarManager |
| ฟอร์มสมัคร (ที่อยู่ 7 ช่อง · คำถามแบรนด์ · การ์ดโซเชียล · insight · ยินยอม) | UnboxRegister · BaseSocialAccountView · SocialInsightRow |
| dialog ลงทะเบียนสำเร็จ (lottie จริง · ชวน KYC) | AnimatedConfirmDialog |
| หน้าตอบรับ / สละสิทธิ์ | UnboxAcceptingDetailPage · AcceptUnboxPopupView |
| รายละเอียดการรีวิว (บรีฟ) | UnboxBrief |
| composer ดราฟต์ (stepper · tips · unbox banner) | ReviewShopping |
| สถานะดราฟต์ + ผลตรวจ (ต้องแก้ / แนะนำให้แก้) | TopicPreview · DraftVerdict |
| ส่งลิงก์รีวิว | ApproveLinkPage |
| กิจกรรมของฉัน 3 แท็บ | UserBrandCampaign |
| รายชื่อผู้ได้รีวิว | UnboxUserRegisterList |
| onboarding เต็มจอ + ชีท 3 ขั้น + hub โปรไฟล์ครีเอเตอร์ | WelcomeOnboardingPage / StepPage · CreatorProfilePage |
| KYC: เลือกเอกสาร → วิธีถ่าย → กล้อง ×2 → AI ตรวจ → ยืนยัน / ฟอร์มกรอกเอง | VerifyTypeUser · VerifyInstruction · Camera · VerifyUserStatusForm |

## ไฟล์

- `js/data.js` enum ทุกตัว + copy ไทย + campaign/user จำลอง + 14 ขั้น + preset
- `js/state.js` store กลาง (localStorage + URL hash)
- `js/ui.js` คอมโพเนนต์ร่วม (nav แดง · ปุ่ม BaseCampaignButton · dialog 3 แบบ · bottom sheet · ช่องกรอก · นาฬิกา · stepper)
- `js/screens.js` หน้าจอทั้งหมด + dialog/sheet + ACTIONS (logic ด่าน)
- `js/newflow.js` flow ใหม่: หน้าแทรก 3 จุด (ก่อนสมัคร · การ์ดเกิด · ก่อนตอบรับ) — หลังตอบรับไม่แทรกอะไรอีกเลย + PK components + จุด hook (tapRegister / tapMain / submitLinks) ไม่แตะโค้ดหน้าเดิม
- `js/info.js` อินโฟกราฟิกซ้ายมือถือ (flow ใหม่ · จอกว้าง ≥1180px): 3 ด่าน เป็น STAR → สมัครงานได้ → ตอบรับได้ ต้องมีข้อมูลอะไร ถามตอนไหน · ติ๊กตาม state จริง + ป้าย "ตอนนี้"
- `js/panel.js` แผงควบคุม (สลับ flow · ติ๊กข้อมูล Star Profile · ขั้นของแต่ละ flow · preset)
- `css/app.css` โทเคนสี/ขนาดจาก UIColorExtension + xib/storyboard
- `assets/ic/` ไอคอนจริง 150 ไฟล์ render จาก pdf/svg ของ Assets.xcassets · `assets/*.json` lottie จริง
- `js/icons.js` Phosphor สำรอง (ที่แอปไม่มี asset)

## ข้อควรรู้

- KYC จำลอง: ผล AI ตั้งได้ในแผง (ผ่าน / ไม่ชัด / หน้าไม่ตรง / หมดอายุ / บัตรซ้ำ) ไม่ผ่านครบ 3 ครั้ง → กรอกฟอร์มเอง → รอคนตรวจ
- ฟอร์มสมัครส่งยอดฟอลเป็นค่าว่างเหมือนแอปจริง (บั๊กเดิม) — ยอดที่แบรนด์เห็นมาจากโปรไฟล์โซเชียล
- ตัดสิทธิ์ (`reviewPending`) แสดง copy "คุณถูกตัดสิทธิ์" ทั้งที่แค่ค้างรีวิว ตามแอปจริง

