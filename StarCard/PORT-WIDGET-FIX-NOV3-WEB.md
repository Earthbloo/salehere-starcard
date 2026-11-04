# Star Card · แก้ widget 3 พ.ย. 2569 · งานฝั่งเว็บ

ที่มา: commit `fe91f93` (branch `widget-guide-nov3`) ใน salehere-starcard · แก้ JSON 25 ตัว ลบ 6 ตัว ตาม "Star Card Widget Guide สำหรับ Dev"

ไฟล์นี้บอกเฉพาะสิ่งที่ตัววาดเว็บต้องเพิ่มเพื่อให้ JSON ชุดใหม่วาดได้ ชื่อไฟล์ในโปรเจกต์เว็บให้ทีมเว็บแมปเอง

## สรุปงาน

| # | งาน |
|---|---|
| 1 | เพิ่มลิ้นชักรายการ `rateSocials` ในตัวให้ข้อมูล (data source ที่ตอบ `list(name)`) |
| 2 | เรียงช่องทางตามลำดับฟอร์ม IG › TikTok › FB › YouTube › Lemon8 › X |
| 3 | ชิ้นที่ไม่มีผังต้องข้าม ไม่พังทั้งการ์ด |

ส่วนอื่นของ JSON ที่แก้ใช้คำที่ตัวคำนวณ (solver) รู้จักอยู่แล้ว ถ้าตัวคำนวณเว็บพอร์ตจากต้นแบบรุ่นล่าสุด ไม่ต้องแก้เพิ่ม

## 1. เพิ่มลิ้นชัก `rateSocials`

widget ที่ใช้: `kitRateCream`, `kitRateGingham`, `kitRateMac`, `kitRateNight`, `kitRatePurple`, `rateTags`
ถ้าไม่มีลิ้นชักนี้ widget ทั้ง 6 ตัวจะวาดเป็นกล่องว่าง

ข้อมูลมาจาก API ตัวเดิม: `socialProfiles[]` ช่อง `photoPrice`, `shortVdoPrice`, `longVdoPrice`, `sharingPrice`

| ประเภทในผัง | ช่องจาก API |
|---|---|
| `photo` | `photoPrice` |
| `shortVideo` | `shortVdoPrice` |
| `longVideo` | `longVdoPrice` |
| `seeding` | `sharingPrice` |

กติกา:
- หนึ่งชิ้นต่อหนึ่งโซเชียล เฉพาะโซเชียลที่มีราคาอย่างน้อย 1 ประเภทที่มากกว่า 0
- เรียงตามลำดับช่องทางในข้อ 2
- `id` ของชิ้น = `platform` · `i` = ลำดับหลังเรียง

| ช่อง | ค่า | ตัวอย่าง |
|---|---|---|
| `platform` | raw ของช่องทาง | `instagram` |
| `platformName` | ชื่อเต็ม | `Instagram` |
| `platformOrder` | ตำแหน่งในลำดับข้อ 2 | `1` |
| `icon` | `sh:<platform>` | `sh:instagram` |
| `tint` | สีประจำช่องทาง (WIDGET-SPEC.md §3.2) | |
| `shortVideo`, `photo`, `longVideo`, `seeding` | `"฿" + ราคาคั่นหลักพัน` ไม่มีราคา = ไม่ใส่ช่องนั้นเลย | `฿5,000` |
| `shortVideoRaw`, `photoRaw`, `longVideoRaw`, `seedingRaw` | ตัวเลขดิบ | `5000` |

ต้นแบบที่ทำเสร็จแล้ว (`salehere-starcard/sync-server/web/js/data.js`):

```js
case 'rateSocials': {
  const rates = this.rates.filter((r) => r.price > 0)
  return SOCIAL_ORDER.filter((t) => rates.some((r) => r.platform === t)).map((t, i) => {
    const f = { platform: t, platformName: SOCIAL[t]?.name ?? '', icon: 'sh:' + t, tint: SOCIAL[t]?.tint ?? '', platformOrder: String(SOCIAL_ORDER.indexOf(t)) }
    for (const fmt of ['shortVideo', 'photo', 'longVideo', 'seeding']) {
      const ps = rates.filter((r) => r.platform === t && r.format === fmt).map((r) => r.price)
      if (ps.length) { const low = Math.min(...ps); f[fmt] = '฿' + Fmt.baht(low); f[fmt + 'Raw'] = String(low) }
    }
    return I(t, i, f)
  })
}
```

ตัวเลือกในถาดของ widget ราคา (ถ้าเว็บมีหน้าแต่ง): `rateTags` ใช้ตัวเลือกแบบ `pick` ชื่อ `chan` ส่วน `kitRate*` ใช้แบบ `checks` ชื่อ `hide` ทั้งสองอ่านรายการ `ratePlatforms` ซึ่งต้องเรียงตามข้อ 2 เหมือนกัน

## 2. ลำดับช่องทาง = ลำดับฟอร์ม

ทุก widget รวม widget ราคา เรียงช่องทางตามลำดับฟอร์ม Star Profile ซึ่ง iOS และ Android ใช้ตรงกัน:

```text
instagram, tiktok, facebook, youtube, lemon8, x
```

ใช้ค่าคงที่ตัวเดียวสำหรับทุกลิ้นชัก: `socials`, `rates` (`platformOrder`), `rateSocials` และ `ratePlatforms`
ตัวอย่างโค้ดข้างบนใช้ `SOCIAL_ORDER` ของต้นแบบ ซึ่งยังเรียงแบบเดิม ให้ใช้ลำดับนี้แทน

## 3. widget ที่ถูกลบ

ลบแล้ว: `aboutNote`, `contactBar`, `proofBrandGrid`, `proofBrandRail`, `proofBrandCoins`, `typeMarquee`

ทีมตกลงให้หลังบ้านลบ JSON ของ 6 ตัวนี้ทิ้ง การ์ดเก่าที่มีชิ้นเหล่านี้ต้องเปิดได้ ให้ข้ามชิ้นที่ไม่มีผังและเหลือช่องว่างตรงนั้น

## เช็คผล

เทียบกับรูปจากต้นแบบใน `salehere-starcard/present/spec-fixtures/cells/cell-<kind>-design.png`
(รูปในต้นแบบยังเรียงช่องทางแบบเดิม เพราะลำดับข้อ 2 เป็นงานใหม่)
ค่าที่ตัวคำนวณต้องได้อยู่ใน `salehere-starcard/present/spec-fixtures/fixtures/` (ต้นแบบเว็บผ่าน 116/116)

JSON ที่แก้ 25 ตัว:
statGiant, socialTiles, socialChips, popStatsGlass, scrapKeyTab,
kitRateCream, kitRateGingham, kitRateMac, kitRateNight, kitRatePurple, rateTags,
popHeroPaper, popHeroGlass,
kitProfileCream, kitProfileGingham, kitProfileMac, kitProfileNight, kitProfilePurple,
proofSeal, scrapFeed, proofWork, proofTicket, wallPolaroid, portfolioWindow, scrapInfo
