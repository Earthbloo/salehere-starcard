# Star Profile → salehere-ios: แก้ API น้อยที่สุด

อัปเดต 6 ต.ค. 2569 · เทียบ `StarFlow.swift` กับ `salehere-ios` + `salehere-api-microservices/gateway/src/schema`

## สรุป

- **API ใหม่ที่เลี่ยงไม่ได้: 1 ช่อง** — `creatorType: individual | page` ใน `createOrUpdateCreatorProfile` (ประเภทครีเอเตอร์)
- **ต้องเช็ก resolver 2 จุด** (อาจไม่ต้องแก้): ที่อยู่ว่างตอนสมัครกิจกรรม · "ทุกจังหวัด (งานออนไลน์)" ใน `preferredProvinces`
- ที่เหลือ **12 หัวข้อใช้ API เดิมทั้งหมด** งานจริงอยู่ฝั่ง iOS client: ย้ายด่าน "ครบ 100%" และเรียงลำดับใหม่ตาม flow ของเรา
- 3 หัวข้อที่ API ไม่มี (รอบแก้งาน · งานที่ขอผ่าน · ศาสนา) ตัดจาก flow ไปแล้วตั้งแต่ 4 ต.ค. ไม่ต้องทำอะไร

## ตารางเทียบทีละช่อง

| Star Profile | API เดิมที่ใช้ | ปรับใน prototype แล้ว | Note |
|---|---|---|---|
| ประเภทครีเอเตอร์ | — | ใส่ NOTE ที่ `creatorKind` | **API ใหม่ 1 ช่อง** |
| ช่องทางโซเชียล | `createSocialAuthorizeParams` → `socialEngagementPrice` · FB ผ่าน FBSDK · Lemon8 วางลิงก์ | X เปลี่ยนจากกรอกเองเป็น connect | ถ้า `isLoginSocialEnable == false` ตกไปวางลิงก์ |
| เรทรับงาน | `updateSocialProfileEngagementPrice` (photo / shortVdo / longVdo / sharing + suggested) | ตรงอยู่แล้ว | — |
| ข้อมูลผู้ติดตาม | `analyzeSocialProfileInsight(socialType, insightType, imageUrl)` | NOTE ที่ `insightValues` | Vision บนเครื่อง = พรีวิวเท่านั้น |
| สายที่ใช่ | `setUserCategories` (CategoryV2) | ขั้นต่ำ 1 → **3** (เท่ากติกา welcome step เดิม) เพดาน 5 | 18 ชื่อของเราเป็นป้ายชั่วคราว ต้อง map กับ `categories` query |
| แนะนำตัว | `editProfileInfo(caption)` | NOTE ที่ `about` | `User.aboutMe` ไม่ได้ใช้ ไม่ต้องแตะ |
| รูปและผลงาน | `profileImages` 3 ช่อง 3:4 · `portfolio{images, videos}` | NOTE ที่ `minWorks` | client เดิมจำกัด 2+2 ถ้าจะเกินต้องปลดใน client ไม่แตะ API |
| ยืนยันตัวตน | `VerifyUser.graphql` สถานะ approved / reject / waiting_approve | เพิ่มสถานะ **rejected** ครบทุกหน้า (ชิป · wizard · ฟอร์มสมัคร · lab) | — |
| พื้นที่รับงาน | `preferredProvinces` + `getProvinces` | NOTE ที่ `IntakeCatalog.provinces` | เช็กว่า server รับ "ทุกจังหวัด (งานออนไลน์)" เป็น string ได้ไหม |
| วันเวลาว่าง | `availableTimes{day, timeSlots}` 4 ช่วง | ใช้คีย์ `slot_09_12 … slot_17_late` ตรงตัวแล้ว | — |
| ช่องทางติดต่อ | `creatorProfile.tel / lineId / website` | NOTE ที่ `lineID` | ส่ง `showTel/showLineId/showWebsite = true` เสมอ |
| ที่อยู่รับของ | `myAddress` / `createUserAddress` 7 ช่องบังคับ | `StarAddress` เพิ่ม `district`, `province` (เติมอัตโนมัติจาก zip + ตำบล) | ใช้ `getSubDistricts` / `getDistrictProvince` เหมือนหน้าเดิม |
| บัญชีรับเงิน | `CampaignPayoutProfiles` / `CampaignPayoutSubmit` | ตัด `signer` ออก (API ไม่มี) · NOTE mapping ครบที่ `StarBank` | สำเนาบัตร · ที่อยู่ภาษี · หัก ณ ที่จ่าย ให้ฟอร์ม payout เดิมถามตอนจ่ายจริง |
| สัดส่วน | `bodyMeasurement` | มีแล้ว (session อื่น 6 ต.ค.) กรอกเองใน Star Profile | — |

## งานฝั่ง iOS client (ไม่แตะ API)

1. **ด่านสมัครงาน** — `ValidateRegisterSaleHereStarManagerInteractor.swift:22` เช็ก `percentTotal != 100` ฝั่ง client ล้วน ๆ เปลี่ยนเป็นกติกาเรา (6 ต.ค. 2569): ต้องครบ 8 ข้อที่แบรนด์ใช้คัดเลือก = `StarFlow.starSteps` (ประเภท · ช่องทาง+เรท · สาย · รูปผลงาน · พื้นที่ · วันว่าง · ติดต่อ · KYC ผ่าน) → `isStar` ถึงส่งใบสมัครได้ · ทุกทางเข้า (ลงทะเบียนกิจกรรม / ปุ่ม "สมัครเป็น STAR" / แตะแถวใน Star Profile / เปิด Star Card) ถาม 8 ข้อนี้ก่อนเสมอ ครบแล้วเล่น motion "คุณเป็น STAR แล้ว" แล้วค่อยถามข้อที่เหลือ (`applySteps` = 8 ข้อ + ที่อยู่ · บัญชี · สัดส่วน)
2. **Welcome onboarding 3 ขั้น** (ผูกโซเชียล → หมวด ≥3 → KYC) ยุบเข้า wizard เดียว แล้วยัง `completeWelcomeProgressStep` ให้ server ตามเดิมเพื่อไม่ให้ flag ค้าง
3. **ฟอร์มสมัครกิจกรรม** — Line ID ยิง `createOrUpdateCreatorProfile(lineId)` ก่อน แล้วค่อย `createBrandCampaignApplication` พร้อม `myAddress` ถ้ามี
4. **สถานะ `have`** — ไม่ต้องสร้าง field ใหม่ คำนวณจากของเดิม (ดู NOTE ที่ `StarFlow.have`)

## ต้องถาม backend ก่อน (2 จุด)

- `BrandCampaignApplication.address…zipcode` เป็น non-null — ถ้าสมัครโดยยังไม่มีที่อยู่ resolver รับค่าว่างได้ไหม (เติมทีหลังด้วย `updateBrandCampaignApplicationAddress` ที่มีอยู่แล้ว)
- `preferredProvinces` validate กับ `getProvinces` หรือรับ string อะไรก็ได้

## ไฟล์ที่แก้วันนี้ (prototype)

`Model/StarFlow.swift` · `Model/Profile.swift` · `Model/Intake.swift` · `Views/SaleHere/StarFlow/StarWizard.swift` · `StarGlassKit.swift` · `FlowLab.swift` · `RegisterFormPage.swift` — ทุกจุดมีคอมเมนต์ขึ้นต้น `NOTE port`
