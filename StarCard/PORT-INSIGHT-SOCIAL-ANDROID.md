# Insight เลือก Social ต่อวิดเจ็ต → salehere-android

> 23 พ.ย. 2569 · repo `salehere-android` branch `feature/star-card-redisign`
> iOS ทำแล้วใน `salehere-ios` (`StarCardData.swift` · `StarCardWidgetTray.swift` · `StarCardPieceTray.swift`) Android ทำตามไฟล์นี้ให้ผลเหมือนกัน
> ไฟล์ให้ tester ลองเล่น: `present/insight-social/insight-social-tester.html` (เปิดดูได้ว่าแต่ละเคสต้องเห็นอะไร)

## ปัญหาตอนนี้

`List<SocialProfileInsightFragment>.toStarCardAudienceInsight()` (`StarCardAudienceInsight.kt`) หยิบ Insight **ช่องแรก** ตาม `AUDIENCE_SOCIAL_PRIORITY` (IG → TikTok → YT → FB) มาใช้กับทุกวิดเจ็ต
- ผูก Insight ไว้หลายช่อง ผู้ใช้ไม่รู้ว่าวิดเจ็ตโชว์ของช่องไหน
- เลือกช่องเองไม่ได้

## สิ่งที่ต้องได้

| # | กติกา |
|---|---|
| R1 | วิดเจ็ตผู้ชมแต่ละใบเลือก Social ได้ **1 ช่อง** เก็บใน `options["social"]` (ค่า = `StarCardSocialType.raw` เช่น `instagram`) |
| R2 | ค่าเริ่มต้น = ช่องที่ **ผู้ติดตามมากสุด** ถ้าเท่ากัน เรียง IG → TikTok → FB → YT (ลำดับ `StarCardSocialType.entries`) |
| R3 | ขึ้นเฉพาะช่องที่ทำ Insight ได้และมีข้อมูล (FB / IG / YT / TikTok) X กับ Lemon8 ไม่ขึ้นเลย |
| R4 | ช่องจะขึ้นในรายการก็ต่อเมื่อมี **หัวข้อที่วิดเจ็ตนั้นใช้** (ดู `needs` / `match` ในตารางล่าง) |
| R5 | มีช่องให้เลือกน้อยกว่า 2 → **ไม่โชว์แถว** "ช่องทาง" (`minItems: 2` ระบบเดิมจัดการให้แล้ว) |
| R6 | ไม่มีช่องไหนผ่านเลย → วิดเจ็ตขึ้น "รอข้อมูล" (`star_card_widget_pending_audience`) |
| R7 | ช่องที่เลือกไว้ใช้ไม่ได้แล้ว (ลบ Insight) → วาดค่าเริ่มต้นแทน **แต่ห้ามลบ** `options["social"]` พอช่องนั้นกลับมา ก็กลับไปใช้ช่องที่เลือกไว้เอง |
| R8 | วิดเจ็ตชุด kitInsight (`match: any`) วาดเฉพาะหัวข้อที่ช่องที่เลือกมี และช่องติ๊ก "ซ่อน" ขึ้นเฉพาะหัวข้อนั้น |

## วิดเจ็ตไหนใช้หัวข้ออะไร (มาจาก JSON อยู่แล้ว)

| วิดเจ็ต | `needs` | `match` | ความหมาย |
|---|---|---|---|
| audienceSplit | gender | all | ช่องต้องมีเพศ |
| audienceAge | age | all | ช่องต้องมีอายุ |
| audienceMap | city | all | ช่องต้องมีเมือง |
| audienceLine · audiencePoster · scrapStats | city · gender · age | all | ช่องต้องมีครบ 3 หัวข้อ |
| kitInsightCream / Gingham / Mac / Night / Purple | city · gender · age | any | มีหัวข้อไหนก็ได้ วาดเท่าที่มี |

หัวข้อ → ข้อมูล: `gender` = female + male + other > 0 · `age` = `ages` ไม่ว่าง · `city` = `places` ไม่ว่าง (มาจาก `location`)

## JSON (เพิ่มใน 11 ไฟล์ `05-ผู้ชม/*.json` แล้ว · ต้องอัปขึ้น API)

แถวแรกของ `widget.controls`:

```json
{ "type": "pick", "label": "ช่องทาง", "opt": "social", "items": "insightSocials",
  "needs": ["city", "gender", "age"], "match": "any", "minItems": 2 }
```

`StarCardKitSpecCatalog` ใช้ `ignoreUnknownKeys = true` ดังนั้น **แอปเก่าไม่พัง** ถ้า JSON ขึ้นไปก่อน แอปเก่าจะเห็น `items` ที่ไม่รู้จัก → `controlItems` คืนลิสต์ว่าง → ไม่โชว์แถว

---

## ไฟล์ที่ต้องแก้ (10 ไฟล์ + ไฟล์ใหม่ 1)

ทุก path อยู่ใต้ `app/src/main/java/com/salehere/android/app/`

### 1. `models/starcard/content/StarCardAudienceInsight.kt`: แยก Insight ราย Social

```kotlin
// หัวข้อที่ช่องนี้มี
fun StarCardAudienceInsight.has(topic: String): Boolean = when (topic) {
    "gender" -> female + male + other > 0
    "age" -> ages.isNotEmpty()
    "city" -> places.isNotEmpty()
    else -> false
}

// Insight ช่องเดียว (ย้ายตัวแปลงเดิมมาเป็นต่อช่อง)
fun SocialProfileInsightFragment.toStarCardAudienceInsight(): StarCardAudienceInsight {
    fun share(g: StarCardAudienceGender) = gender.firstOrNull { it.label == g.raw }?.percentage ?: 0.0
    return StarCardAudienceInsight(
        female = share(StarCardAudienceGender.FEMALE),
        male = share(StarCardAudienceGender.MALE),
        other = share(StarCardAudienceGender.OTHER),
        ages = age.map { StarCardAudienceInsight.AgeBand(label = it.label, share = it.percentage) },
        places = location.map { StarCardAudienceInsight.PlaceShare(name = it.displayName ?: it.label, share = it.percentage) },
    )
}

// ทุกช่องที่ทำ Insight ได้และมีข้อมูล (X / Lemon8 หลุดตรงนี้: R3)
fun List<SocialProfileInsightFragment>.toStarCardAudiences(): Map<StarCardSocialType, StarCardAudienceInsight> =
    filter { it.hasAudienceData }
        .mapNotNull { i -> i.socialType.toSocialPlatform()?.takeIf { it.canFillInsight }?.let { it.toSocialType() to i.toStarCardAudienceInsight() } }
        .toMap()
```

`AUDIENCE_SOCIAL_PRIORITY` กับ `List<…>.toStarCardAudienceInsight()` เดิม **ลบได้** (ค่าเริ่มต้นใหม่อยู่ข้อ 3)

### 2. `models/starcard/StarCardOwner.kt`: เก็บราย Social

```kotlin
data class StarCardOwner(
    …
    val audiences: Map<StarCardSocialType, StarCardAudienceInsight>,   // ใหม่
    …
)

// ใน toStarCardOwner(...)
audiences = insights.toStarCardAudiences(),
```

ลบ `audience = insights.toStarCardAudienceInsight()` ทิ้ง (`audience` ไปคำนวณใน content แทน ข้อ 3)

### 3. ไฟล์ใหม่ `compose/component/starcardkit/model/spec/StarCardInsightNeeds.kt`: หาช่องที่ใช้ได้

อยู่ฝั่ง spec เพราะต้องอ่าน `StarCardKitControl` (ไม่ให้ `models/` ไปพึ่ง `compose/`)

```kotlin
data class StarCardInsightNeeds(val topics: List<String>, val any: Boolean) {
    companion object {
        val ALL_TOPICS = listOf("city", "gender", "age")
        val ANY_TOPIC = StarCardInsightNeeds(ALL_TOPICS, any = true)

        // อ่านจากแถว pick ที่ items == "insightSocials" ของชนิดนั้น · null = ไม่ใช่วิดเจ็ต Insight
        fun of(controls: List<StarCardKitControl>): StarCardInsightNeeds? =
            controls.firstOrNull { (it.items as? JsonPrimitive)?.contentOrNull == INSIGHT_SOCIALS }?.let { c ->
                StarCardInsightNeeds(c.needs?.takeIf { it.isNotEmpty() } ?: ALL_TOPICS, any = c.match == "any")
            }
    }
}
const val INSIGHT_SOCIALS = "insightSocials"

// ช่องที่ผ่าน เรียงผู้ติดตามมาก → น้อย, เท่ากันตาม StarCardSocialType.entries (R2, R4)
fun StarCardProfileContent.insightPlatforms(needs: StarCardInsightNeeds): List<StarCardSocialType> {
    fun followers(t: StarCardSocialType) = socials.firstOrNull { it.type == t }?.followerCount ?: 0
    return audiences.filter { (_, a) -> if (needs.any) needs.topics.any(a::has) else needs.topics.all(a::has) }
        .keys.sortedWith(compareByDescending<StarCardSocialType> { followers(it) }.thenBy { StarCardSocialType.entries.indexOf(it) })
}

// ช่องที่วิดเจ็ตนี้ใช้จริง: ที่เลือกไว้ถ้ายังผ่าน ไม่งั้นค่าเริ่มต้น (R7: ไม่ลบค่าที่เก็บไว้)
fun StarCardProfileContent.insightPlatform(needs: StarCardInsightNeeds, picked: String?): StarCardSocialType? {
    val list = insightPlatforms(needs)
    return list.firstOrNull { it.raw == picked } ?: list.firstOrNull()
}
```

### 3.1 `models/starcard/content/StarCardProfileContent.kt` + `models/starcard/owner/StarCardProfile.kt`

```kotlin
// StarCardProfileContent.kt
data class StarCardProfileContent(
    …
    val audience: StarCardAudienceInsight,                                         // = ของช่องค่าเริ่มต้น
    val audiences: Map<StarCardSocialType, StarCardAudienceInsight> = emptyMap(),  // ใหม่
    …
)
```

```kotlin
// StarCardProfile.kt · toStarCardProfileContent(): ลบ `audience = audience,` แล้วต่อท้ายแบบนี้
private fun StarCardOwner.toStarCardProfileContent(strings: StarCardStringResolver): StarCardProfileContent {
    val content = StarCardProfileContent.empty.copy(
        …                       // ของเดิมทั้งหมด
        audiences = audiences,
    )
    // ใบที่ไม่มีแถว "ช่องทาง" และที่อื่นที่ยังอ่าน content.audience = ช่องผู้ติดตามมากสุดที่มีข้อมูล
    val main = content.insightPlatforms(StarCardInsightNeeds.ANY_TOPIC).firstOrNull()
    return content.copy(audience = main?.let { audiences[it] } ?: audienceEmpty)
}
```

### 4. `compose/component/starcardkit/model/spec/StarCardKitControl.kt`: รับ 2 ช่องใหม่

```kotlin
data class StarCardKitControl(
    …
    val minItems: Int? = null,
    val needs: List<String>? = null,   // ใหม่
    val match: String? = null,         // ใหม่: "all" (ค่าเริ่มต้น) | "any"
)
```

### 5. `compose/ui/star/editor/views/StarCardEditorState.kt`: รายการในถาด

`controlItems` ตอนนี้รับแค่ `items` → ต้องรู้ `needs` ด้วย เปลี่ยนให้รับทั้ง control:

```kotlin
fun controlItems(ctl: StarCardKitControl): List<Pair<String, String>> {
    val key = (ctl.items as? JsonPrimitive)?.contentOrNull
    if (key == INSIGHT_SOCIALS) {
        val needs = StarCardInsightNeeds(ctl.needs?.takeIf { it.isNotEmpty() } ?: StarCardInsightNeeds.ALL_TOPICS, ctl.match == "any")
        return ownerProfile.content.insightPlatforms(needs).map { it.raw to it.shortName }
    }
    return controlItems(ctl.items)   // ของเดิม
}
```

แก้ที่เรียกให้ส่ง `ctl` แทน `ctl.items`:
- `StarCardEditorControlRowScreen.kt` แถว pick (บรรทัด ~27) กับ checks (~62)
- `withoutMissingPickOptions()` (บรรทัด ~2654) ⚠️ ตอนสลับชนิด (เช่น kitInsightCream → kitInsightNight) ฟังก์ชันนี้**ลบ** pick ที่ไม่อยู่ในรายการ ต้องส่ง `control` เข้าไป ไม่งั้นรายการว่าง → ไม่ลบ (ปลอดภัย) แต่ถ้าส่งผิดจะลบค่าที่ผู้ใช้เลือกไว้

แถว pick เดิมจัดการให้แล้ว ไม่ต้องแก้: `minItems` (R5) และ `isPickValueMissing` → ไฮไลต์ตัวแรกเมื่อค่าที่เก็บไว้หายไป (R7)

### 6. `compose/ui/star/editor/dock/views/StarCardEditorControlRowScreen.kt`: ช่องติ๊ก "ซ่อน" ของ kitInsight (R8)

ในแถว `"checks"` ที่ `opt == hide` ของวิดเจ็ตที่มี `insightNeeds.any`: ตัดหัวข้อที่ช่องที่เลือก**ไม่มี**ออกจาก `items`

```kotlin
val needs = StarCardInsightNeeds.of(sel.kind.controls)
val lacks = if (needs?.any == true) {
    val content = state.ownerProfile.content
    val a = content.insightPlatform(needs, sel.options["social"])?.let { content.audiences[it] }
    needs.topics.filterNot { a?.has(it) == true }.toSet()
} else emptySet()
val items = controlItems.filterNot { it.first in lacks }   // ก่อนเช็ก items.isEmpty()
```

### 7. ตัววาด: `StarCardKitSpecData.kt` + `StarCardKitSpecPainterScreen.kt` + `StarCardKitWidgetBodyScreen.kt`

**7.1 `StarCardKitSpecData`**: รับ needs แล้วอ่าน Insight ของช่องที่เลือก

```kotlin
data class StarCardKitSpecData(
    …
    val insightNeeds: StarCardInsightNeeds? = null,   // ใหม่
) {
    val insightPlatform: StarCardSocialType?
        get() = insightNeeds?.let { p.content.insightPlatform(it, kit.opts["social"]) }

    private val shownAudience: StarCardAudienceInsight
        get() = if (insightNeeds == null) p.content.audience
                else insightPlatform?.let { p.content.audiences[it] } ?: audienceEmpty
```

ทุกที่ที่อ่าน `shownAudience` (stat ผู้ชม, list `AGES` / `PLACES` / เพศ) ได้ของช่องที่เลือกเอง ไม่ต้องแก้ทีละจุด

ใน `flag()` บรรทัด `HIDDEN` (R8): หัวข้อที่ช่องไม่มีให้นับเป็นซ่อน

```kotlin
StarCardKitSpecKeyPrefix.HIDDEN.extract(name)?.let { key ->
    if (kit.list(StarCardKitOpt.HIDE).contains(key)) return true
    val n = insightNeeds
    return n != null && n.any && key in n.topics && !shownAudience.has(key)
}
```

**7.2 `StarCardKitSpecPainterScreen.kt`** (~บรรทัด 170): ส่ง needs ตอนสร้าง data และใส่ใน key ของ `remember`

```kotlin
val insightNeeds = remember(kind) { StarCardInsightNeeds.of(kind.controls) }
… StarCardKitSpecData(…, insightNeeds = insightNeeds)
```

**7.3 `StarCardKitWidgetBodyScreen.kt`** `pendingMessageRes`: "รอข้อมูล" ต้องเช็กต่อใบ (R6)

ตอนนี้ดู `content.audience` ก้อนเดียว เลยไม่ขึ้นรอข้อมูลเมื่อมีช่องอื่นแต่ไม่มีหัวข้อที่ใบนี้ใช้ เปลี่ยน AUDIENCE เป็น:

```kotlin
StarCardKitWidgetFamily.AUDIENCE -> R.string.star_card_widget_pending_audience.takeIf {
    val needs = StarCardInsightNeeds.of(kind.controls)
    if (needs == null) audienceIsEmpty(content.audience) else content.insightPlatforms(needs).isEmpty()
}
```

(ต้องส่ง `kind` เข้า `pendingMessageRes` และเพิ่ม `kind` ใน key ของ `remember` บรรทัด ~45)

---

## ห้ามแก้ / ไม่ต้องแก้

- **JSON**: แก้แล้วในฝั่ง spec ห้ามใส่ชื่อวิดเจ็ตในโค้ด Kotlin ทุกอย่างอ่านจาก `controls` (`needs` / `match`)
- **ล็อกวิดเจ็ต** (`StarCardLockRequirement.INSIGHT`): ยังใช้กติกาเดิม "มี Insight อย่างน้อย 1 ช่อง"
- **ยังไม่ตัดสิน**: audienceLine / audiencePoster / scrapStats ถ้าไม่มีช่องไหนครบ 3 หัวข้อ ตอนนี้ขึ้น "รอข้อมูล" (R6) ถ้าตัดสินให้ล็อกในตู้ จะส่งไฟล์แยกมาให้

## เคสทดสอบ (เหมือน iOS)

| # | ผูกไว้ | วิดเจ็ต | ต้องเห็น |
|---|---|---|---|
| T1 | IG 50K ครบ 3 · TikTok 120K ครบ 3 | ทุกตัว | แถว "ช่องทาง" = TikTok \| IG ค่าเริ่มต้น TikTok |
| T2 | เหมือน T1 แล้วกด IG | kitInsight | ทุกบล็อกเป็นของ IG ปิดแอปเปิดใหม่ยังเป็น IG |
| T3 | IG ครบ 3 · TikTok มีแค่อายุ | audienceAge | TikTok \| IG |
| T4 | เหมือน T3 | audienceLine | ไม่มีแถว (มีแค่ IG ผ่าน) วาดของ IG |
| T5 | เหมือน T3 | audienceSplit | ไม่มีแถว ใช้เพศของ IG ไม่เอา TikTok มาปน |
| T6 | ผูก X / Lemon8 ด้วย | ทุกตัว | X กับ Lemon8 ไม่ขึ้นในรายการ |
| T7 | มีแค่ YouTube และมีแค่เพศ | audienceAge | "รอข้อมูล" ไม่มีแถว |
| T8 | มีแค่ IG และมีแค่เพศ + อายุ | kitInsightNight | ไม่มีแถว ช่องติ๊กซ่อนมีแค่ เพศ · อายุ ไม่มีบล็อกเมือง |
| T9 | ตาม T1 กด TikTok แล้วลบ Insight TikTok | ทุกตัว | เปลี่ยนเป็น IG พอแนบ TikTok กลับมา กลับเป็น TikTok เอง |
| T10 | ยังไม่มี Insight | ตู้ / ใบล็อก | ตัวอย่างเหมือนเดิม ไม่มีแถว |
| T11 | ตาม T2 แล้วสลับชนิด kitInsightCream → kitInsightNight | kitInsight | ยังเป็น IG (ค่าไม่ถูกลบตอนสลับ) |
