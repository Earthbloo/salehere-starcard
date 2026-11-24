# ซ่อนแถว "ขอบ" ตาม `widget.borderChoice` — iOS + Android

24 พ.ย. 2569 · JSON ขึ้น SIT แล้ว · **ฝั่งแอปยังไม่ได้ทำ**

## ต้องการอะไร

widget บางตัวออกแบบมาให้เลือกขอบไม่ได้ (ขอบโผล่เกินเส้น, เส้นวิ่งรอบกรอบว่าง, กดแล้วไม่เปลี่ยน)
ไฟล์ผังของ widget พวกนี้มี `"borderChoice": false` อยู่ในส่วน `widget` แล้ว แต่แอปยังไม่อ่านค่านี้ แถว "ขอบ" ในถาดเลยยังขึ้นทุกตัว

## กติกา (เหมือนต้นแบบ `salehere-starcard` ทุกข้อ)

1. `widget.borderChoice == false` → **ไม่มีแถว "ขอบ"** ในถาดของชิ้น · ไม่ใส่ / `true` = มีแถวเหมือนเดิม
2. ขอบของชิ้นแบบนี้ = **ขอบตั้งต้นของชนิดเสมอ** — ค่า `border` ที่เซฟไว้ในการ์ดไม่มีผล (การ์ดที่ผู้ใช้เคยกด "มีขอบ" ไว้ก่อนหน้า ต้องกลับเป็นค่าตั้งต้น)
3. ขอบตั้งต้น = `widget.border ?? !widget.ownSurface` (สูตรเดิมที่ใช้ตอนวางชิ้นใหม่อยู่แล้ว)

ต้นแบบ: `StarCard/StarCard/Model/WidgetModel.swift` (`hasBorderChoice`) · `Model/CardStore.swift:199` (ตอนโหลด) · `Views/CardScreen.swift:2883` (ถาด) · Android `model/CardStore.kt:243` · `ui/CardScreen.kt:3683` · ความหมายของ key อยู่ที่ `StarCard/WIDGET-SPEC.md` บรรทัด 196

## iOS (`salehere-ios`)

**1. อ่าน key** — `SaleHere/StarCardRender/WidgetSpec.swift` ใน `struct Widget` ต่อจาก `var border: Bool? = nil` (บรรทัด ~65)

```swift
/// ผู้ใช้เลือกมีขอบ/ไม่มีขอบได้ · ไม่ใส่ = ได้ · `false` = ไม่มีแถว "ขอบ" และขอบ = ค่าตั้งต้นเสมอ
var borderChoice: Bool? = nil
```

แล้วเพิ่มตัวช่วยไว้ที่เดียว (extension ของ `WidgetSpec.Widget`):

```swift
extension WidgetSpec.Widget {
    var hasBorderChoice: Bool { borderChoice ?? true }
    var defaultBorder: Bool { border ?? !(ownSurface ?? false) }
    /// ขอบที่ใช้จริงของชิ้น — ชนิดที่ล็อกขอบไว้ไม่สนค่าที่เซฟ
    func effectiveBorder(_ saved: Bool?) -> Bool { hasBorderChoice ? (saved ?? false) : defaultBorder }
}
```

**2. ใช้ขอบที่ใช้จริงทุกที่ที่วาด** — เปลี่ยน `item.border ?? false` เป็น `meta?.effectiveBorder(item.border) ?? (item.border ?? false)` (ทุกจุดมี `meta` อยู่ในมือแล้ว)

| ไฟล์ | บรรทัด (โดยประมาณ) | ตอนนี้ |
|---|---|---|
| `Scene/StarCard/StarCardPageView.swift` | 622 | `let border = item.border ?? false` |
| `Scene/StarCard/StarCardLinkHit.swift` | 50 | `let border = item.border ?? false` |
| `Scene/StarCard/StarCardViewController.swift` | 2936 | `contentInset(…, border: item.border ?? false)` |
| `Scene/StarCard/StarCardData.swift` | 1004 | ธง `bordered` → `return item.border ?? false` (`StarCardSpecData` มี `meta` แล้ว) |
| `Scene/StarCard/StarCardPieceTray.swift` | 66 | `border = item.border ?? false` |

ไม่ต้องแตะ: `StarCardViewController.swift` 2245 / 2433 และ `StarCardWidgetGallery.swift` 680 (ตอนวางชิ้นใหม่ ใช้ค่าตั้งต้นอยู่แล้ว)
ไม่บังคับ: `StarCardService.swift` 791 (ตอนเซฟ) ส่ง `effectiveBorder` แทน จะให้ข้อมูลบน server ตรงกับที่เห็น

**3. ซ่อนแถวในถาด** — `Scene/StarCard/StarCardPieceTray.swift` บรรทัด ~228

```swift
if p.meta?.hasBorderChoice ?? true {
    StarCardDockRow(label: "ขอบ") { … เหมือนเดิม … }
}
```

แก้คอมเมนต์หัวไฟล์ข้อ 3 เป็น `ขอบ — ทุกใบ ยกเว้น widget.borderChoice: false → item.border`

## Android (`salehere-android`)

ฝั่ง Android มีจุดโหลดการ์ดจุดเดียว (`StarCardKitStore.restore`) เลยแก้ตอนโหลดได้เหมือนต้นแบบ ไม่ต้องไล่แก้ที่วาด

**1. อ่าน key** — `compose/component/starcardkit/model/spec/StarCardKitWidgetSpec.kt` ใน `data class Widget` ต่อจาก `val border: Boolean? = null`

```kotlin
val borderChoice: Boolean? = null,
```

**2. ตัวช่วย** — `compose/component/starcardkit/model/widget/StarCardKitWidgetKind.kt` ต่อจาก `defaultBorder` (บรรทัด ~72)

```kotlin
/** ผู้ใช้เลือกมีขอบ/ไม่มีขอบได้ (`widget.borderChoice` · ไม่ใส่ = ได้) — ไม่ได้ = ขอบเป็น `defaultBorder` เสมอ */
val hasBorderChoice: Boolean get() = meta.borderChoice ?: true
```

**3. ตอนโหลด** — `compose/component/starcardkit/model/StarCardKitStore.kt` ใน `restore()` บรรทัด ~115

```kotlin
// ใบที่ไม่มีแถวขอบ (`widget.borderChoice: false`) — ขอบเป็นของชนิด ค่าเก่าในไฟล์ไม่มีผล
border = if (kind.hasBorderChoice) item.border else kind.defaultBorder,
```

**4. ซ่อนแถวในถาด** — `compose/ui/star/editor/dock/views/StarCardEditorPieceTrayScreen.kt` บรรทัด ~89

```kotlin
if (sel.kind.hasBorderChoice) {
    StarCardEditorDockRow(label = stringResource(R.string.star_card_editor_border)) { … เหมือนเดิม … }
}
```

## Web (`salehere-web`)

ไม่มีถาดแก้ไข ไม่ต้องทำเรื่องแถว · ถ้าอยากให้หน้าดูการ์ดตรงกับแอป ให้ใช้กติกาข้อ 2 ตอนวาดขอบ (ไม่บังคับรอบนี้)

## widget ที่ตั้ง `borderChoice: false` (21 ตัว · อยู่บน SIT แล้ว)

| เหตุผล | widget |
|---|---|
| มุมโผล่ออกนอกเส้น | portfolioWindow · socialWindow · portfolioGingham · socialGingham · proofTicket · aboutMe |
| เส้นวิ่งรอบกรอบว่าง | artDuo · artFilmstrip · artPair · artTypeOver · audiencePoster · galleryCarousel · galleryFilm · galleryMasonry · galleryStack · scrapBadge · scrapInfo · scrapKeyTab · stickerTags · wallMemory |
| กดแล้วไม่ต่าง | proofSeal |

อีกตัวที่แก้รอบเดียวกันแต่ **ยังเลือกขอบได้**: `rateTags` เปลี่ยนขอบตั้งต้นเป็น `"border": false` (วางใหม่ = ไม่มีขอบ) — แอปรองรับอยู่แล้ว ไม่ต้องทำอะไร

## เช็คหลังแก้

1. แตะ portfolioWindow บนการ์ด → ถาดไม่มีแถว "ขอบ" · แตะ kitProfileCream (ไม่ได้ตั้ง) → ยังมีแถว "ขอบ"
2. การ์ดเก่าที่เคยตั้ง galleryStack เป็น "มีขอบ" → เปิดแล้วขอบกลับเป็นค่าตั้งต้นของชนิด ทั้งตอนแก้และตอนดูการ์ด
3. วาง widget ใหม่จากถาด → ขอบเป็นค่าตั้งต้นเหมือนเดิม (ไม่เปลี่ยนพฤติกรรม)
4. widget ที่ไม่มี `borderChoice` ทุกตัว → ไม่มีอะไรเปลี่ยน
