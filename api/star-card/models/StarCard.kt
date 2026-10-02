// StarCard.kt — Model กลางของ Star Card ฝั่ง Android (คู่กับ StarCard.swift — ชื่อ ฟิลด์ และกติกาเหมือนกันทุกตัว)
//
// คำอธิบายเต็มของแต่ละฟิลด์อยู่ใน StarCard.swift · ที่นี่อธิบายเฉพาะจุดที่ Kotlin ต้องระวังเป็นพิเศษ
//
// ─── กติกากลาง 7 ข้อ ────────────────────────────────────────────────────────────
// 1. token เป็น String ไม่ใช่ enum          5. ชุดค่าเป็น List เรียงน้อยไปมาก (ไม่ใช้ Set)
// 2. ตัวเลขเป็น Double — **ห้าม Float**        6. null / map-list ว่าง = ไม่ส่ง key
// 3. id เป็น UUID ตัวพิมพ์เล็ก                 7. ฟิลด์ที่ไม่รู้จักเก็บใน `extra` แล้วส่งกลับ
// 4. เวลาเป็น String ISO-8601 (ห้าม Long ms)
//
// ใช้ `StarJson` ตัวเดียวทั้งแอปทุกครั้งที่อ่าน/เขียนก้อนเหล่านี้

@file:OptIn(ExperimentalSerializationApi::class)

package co.salehere.starcard.api

import kotlinx.serialization.EncodeDefault
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.KeepGeneratedSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.Transient
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonEncoder
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.pow
import kotlin.math.sign

/**
 * การตั้งค่า JSON ตัวเดียวของทั้งแอป — ต้องได้ผลเหมือน JSONEncoder ของ iOS
 * - `explicitNulls = false` + `encodeDefaults = false` → ค่า null และ map/list ว่างไม่ถูกส่ง (กติกาข้อ 6)
 * - ฟิลด์ที่ iOS ส่งเสมอแม้เป็นค่าตั้งต้น ติด `@EncodeDefault` ไว้
 * - `ignoreUnknownKeys` สำหรับก้อนอ่านอย่างเดียว · ก้อนการ์ดเก็บของที่ไม่รู้จักเองผ่าน `KeepUnknownSerializer`
 */
val StarJson = Json {
    explicitNulls = false
    encodeDefaults = false
    ignoreUnknownKeys = true
}

private val NoExtra = JsonObject(emptyMap())

// ─── §1 การ์ด — star_cards.draft_doc / star_card_versions.doc ──────────────────────

/** การ์ด 1 ใบ — ผัง · ธีม · ชิ้นทั้งหมด (ไม่มีข้อมูลเจ้าของ ข้อเท็จจริงระบบ URL รูป หรือสถานะหน้าจอ) */
@KeepGeneratedSerializer
@Serializable(with = StarCardDoc.Serializer::class)
data class StarCardDoc(
    val schemaVersion: Int,
    /** "portfolio" = 3 หน้า กว้าง 402 pt · "story" = 1 หน้า 540×960 pt */
    val format: String,
    @EncodeDefault val name: String = "",
    val theme: CardTheme,
    val pages: List<CardPage>,
    @Transient val extra: JsonObject = NoExtra,
) {
    /** kind ทั้งหมดในใบนี้ เรียงแล้ว — เก็บคู่กับฉบับเผยแพร่ */
    val kinds: List<String> get() = pages.flatMap { p -> p.items.map { it.kind } }.distinct().sorted()

    companion object { const val CURRENT_SCHEMA = 1 }
    object Serializer : KeepUnknownSerializer<StarCardDoc>(generatedSerializer(), { it.extra }, { v, e -> v.copy(extra = e) })
}

/** ธีมของทั้งใบ — ชื่อฟิลด์ตรงกับ CardSnapshot.Theme ของ prototype */
@KeepGeneratedSerializer
@Serializable(with = CardTheme.Serializer::class)
data class CardTheme(
    val palette: String,
    val ink: String,
    /** null = true (ระบบเลือกหมึกเอง) */
    val inkAuto: Boolean? = null,
    val corner: String,
    val backdrop: String,
    val brightness: Double,
    @EncodeDefault val hueShift: Double = 0.0,
    val customHue: Double? = null,
    val customSat: Double? = null,
    val customBri: Double? = null,
    val duo: String? = null,
    val duoFlipped: Boolean? = null,
    val strip: String? = null,
    /** รูปพื้นหลัง — ใช้เมื่อ backdrop == "photo" · เก็บต่อใบ */
    val photo: PhotoRef? = null,
    val photoEffect: String? = null,
    val photoDim: Double? = null,
    /** วัดครั้งเดียวตอนเลือกรูป — ทุกเครื่องใช้ค่านี้ ไม่วัดใหม่ */
    val photoLean: Double? = null,
    @Transient val extra: JsonObject = NoExtra,
) {
    object Serializer : KeepUnknownSerializer<CardTheme>(generatedSerializer(), { it.extra }, { v, e -> v.copy(extra = e) })
}

@KeepGeneratedSerializer
@Serializable(with = CardPage.Serializer::class)
data class CardPage(
    @EncodeDefault val items: List<WidgetItem> = emptyList(),
    @Transient val extra: JsonObject = NoExtra,
) {
    object Serializer : KeepUnknownSerializer<CardPage>(generatedSerializer(), { it.extra }, { v, e -> v.copy(extra = e) })
}

/**
 * ชิ้นหนึ่งชิ้น — widget ใคร widget มัน: ตำแหน่ง · ข้อความ · หน้าตา · รูป อยู่ในตัวมันครบ
 * key ใน text/style/photos = ชื่อช่อง/เลขช่องจาก WidgetSpec ของ kind นั้น
 */
@KeepGeneratedSerializer
@Serializable(with = WidgetItem.Serializer::class)
data class WidgetItem(
    /** UUID ตัวพิมพ์เล็ก — ใช้ `UUID.randomUUID().toString()` (ตัวเล็กอยู่แล้ว) */
    val id: String,
    /** kind ที่ไม่รู้จักต้องเก็บชิ้นไว้ตามเดิม แล้วโชว์ PNG ของหน้าแทน */
    val kind: String,
    /** กรอบที่ผู้ใช้ขอ (pt) — Double เท่านั้น: โมเดลวาดของแอปใช้ Float ได้ แต่ห้ามเอาค่า Float มาเขียนกลับตรง ๆ */
    val x: Double,
    val y: Double,
    val w: Double,
    val h: Double,
    val surface: String? = null,
    val border: Boolean? = null,
    val pattern: String? = null,
    /** null = true */
    val liftPhoto: Boolean? = null,
    /** print · blind · off · null = print */
    val emboss: String? = null,
    /** ชื่อช่อง → ข้อความของชิ้นนี้ (เก็บตามที่พิมพ์ — ตัวพิมพ์ใหญ่ทำตอนวาด) */
    val text: Map<String, String> = emptyMap(),
    /** ชื่อช่อง → หน้าตา · ช่องรายการใช้ชื่อคอลัมน์ เช่น "rate.price" */
    val style: Map<String, SlotStyle> = emptyMap(),
    /** เลขช่องรูป ("1") → รูปที่ผู้ใช้ใส่เอง */
    val photos: Map<String, PhotoRef> = emptyMap(),
    @Transient val extra: JsonObject = NoExtra,
) {
    object Serializer : KeepUnknownSerializer<WidgetItem>(generatedSerializer(), { it.extra }, { v, e -> v.copy(extra = e) })
}

/** หน้าตาของช่องหนึ่งช่อง — null = ตามสเปก → ตามธีม */
@KeepGeneratedSerializer
@Serializable(with = SlotStyle.Serializer::class)
data class SlotStyle(
    /** ฟอนต์ต้องเป็นไฟล์ที่ฝังในแอป — Android ไม่มี Sukhumvit/Thonburi/Krungthep/SF Rounded/New York */
    val font: String? = null,
    /** xs s m l xl xxl */
    val size: String? = null,
    /** pt ต่อเนื่อง — เฉพาะช่องที่สเปกอนุญาต */
    val pt: Double? = null,
    val color: String? = null,
    val align: String? = null,
    @Transient val extra: JsonObject = NoExtra,
) {
    object Serializer : KeepUnknownSerializer<SlotStyle>(generatedSerializer(), { it.extra }, { v, e -> v.copy(extra = e) })
}

@KeepGeneratedSerializer
@Serializable(with = PhotoRef.Serializer::class)
data class PhotoRef(
    val imageId: Int,
    /** PNG ที่ลบพื้นหลังแล้ว — ใช้ไฟล์นี้เลย ไม่ต้องให้ ML Kit ตัดใหม่ */
    val liftImageId: Int? = null,
    val fit: PhotoFit? = null,
    @Transient val extra: JsonObject = NoExtra,
) {
    object Serializer : KeepUnknownSerializer<PhotoRef>(generatedSerializer(), { it.extra }, { v, e -> v.copy(extra = e) })
}

/**
 * การเลื่อน/ซูมรูป — สัดส่วนของรูปที่วาดแบบ aspect-fill (สูตรเต็มใน StarCard.swift)
 * Compose: `graphicsLayer { scaleX = zoom; scaleY = zoom; translationX = dx * R.w; translationY = dy * R.h }`
 * รูปคนที่ลบพื้นหลังแล้วใช้ `transformOrigin = TransformOrigin(0.5f, 1f)` (ยึดเท้า)
 */
@KeepGeneratedSerializer
@Serializable(with = PhotoFit.Serializer::class)
data class PhotoFit(
    @EncodeDefault val dx: Double = 0.0,
    @EncodeDefault val dy: Double = 0.0,
    @EncodeDefault val zoom: Double = 1.0,
    @Transient val extra: JsonObject = NoExtra,
) {
    object Serializer : KeepUnknownSerializer<PhotoFit>(generatedSerializer(), { it.extra }, { v, e -> v.copy(extra = e) })
}

// ─── §2 ข้อมูลเจ้าของ — ไม่อยู่ในการ์ด · ใช้ร่วมทุกใบ · ไม่มีข้อมูลส่วนตัว ────────────────

@Serializable
data class StarOwner(
    val displayName: String,
    val nickname: String? = null,
    val handle: String,
    val tagline: String? = null,
    val about: String? = null,
    val quote: String? = null,
    val workArea: String? = null,
    val categories: List<String> = emptyList(),
    val interests: List<String> = emptyList(),
    /** ลิงก์ที่เจ้าของวาง — ยอดผู้ติดตามอยู่ใน StarFacts */
    val socials: List<SocialLink> = emptyList(),
    /** แบรนด์เทียบข้ามคน — ทับรายชิ้นไม่ได้ */
    val rates: List<RateRow> = emptyList(),
    /** เฉพาะช่องที่เจ้าของเปิดให้โชว์ */
    val contact: ContactInfo? = null,
    val body: BodyMeasurement? = null,
    val availability: Availability? = null,
    val photos: OwnerPhotos,
)

@Serializable data class SocialLink(val type: String, val url: String)

@Serializable data class RateRow(val platform: String, val format: String, val price: Double, val currency: String)

@Serializable
data class ContactInfo(
    val name: String? = null,
    val role: String? = null,
    val phone: String? = null,
    val email: String? = null,
    val lineId: String? = null,
)

@Serializable
data class BodyMeasurement(
    val height: Measure? = null,
    val weight: Measure? = null,
    val bust: Measure? = null,
    val waist: Measure? = null,
    val hips: Measure? = null,
    val shoe: Measure? = null,
)

@Serializable data class Measure(val value: Double, val unit: String)

@Serializable
data class Availability(
    val booking: String,
    /** 0 = อาทิตย์ … 6 = เสาร์ — เรียงก่อนส่ง (`.sorted()`) */
    val days: List<Int> = emptyList(),
    val slots: List<Int> = emptyList(),
)

/**
 * รูปของเจ้าของ = แหล่งรูปสำรองของช่องที่ไม่ได้ใส่รูปเอง — ลำดับกลาง:
 *   ช่อง 1–3 → creator[(i − 1) % จำนวนที่มี] → avatar → รูปตัวอย่าง
 *   ช่องอื่น  → works[i % จำนวน] → รูปตัวอย่าง
 */
@Serializable
data class OwnerPhotos(
    val avatar: ImageRef? = null,
    /** 3 ช่อง · ช่องว่าง = null ในรายการ */
    val creator: List<ImageRef?> = emptyList(),
    val works: List<ImageRef> = emptyList(),
    val videos: List<VideoRef> = emptyList(),
)

// ─── §3 รูป ─────────────────────────────────────────────────────────────────────

/** URL ตามขนาด: https://img.salehere.co.th/p/{W}x{H}/{path} */
@Serializable data class ImageRef(val id: Int, val path: String, val width: Int, val height: Int)

@Serializable data class VideoRef(val id: Int, val url: String, val thumb: ImageRef, val duration: Double)

// ─── §4 ข้อเท็จจริงจากระบบ — server เขียนเท่านั้น ─────────────────────────────────

@Serializable
data class StarFacts(
    val verified: Boolean,
    val rank: String? = null,
    val followers: Map<String, Int> = emptyMap(),
    val followersUpdatedAt: String? = null,
    val track: TrackRecord,
)

@Serializable
data class TrackRecord(
    val completedCampaigns: Int,
    val onTimeCampaigns: Int,
    val brands: List<BrandWork> = emptyList(),
)

@Serializable data class BrandWork(val brandId: Int, val name: String, val logo: ImageRef? = null, val campaigns: Int)

// ─── §5 สเปกของ widget และเทมเพลต ──────────────────────────────────────────────

@Serializable
data class WidgetSpec(
    val kind: String,
    /** ทุกแบบในตระกูลเดียวกันใช้ชื่อช่องชุดเดียวกัน */
    val family: String,
    val minIos: String? = null,
    val minAndroid: String? = null,
    val enabled: Boolean,
    val defaultSize: Size,
    /** ชื่อช่อง (ห้ามเปลี่ยน/ห้ามใช้ซ้ำ) → สเปกของช่อง */
    val slots: Map<String, SlotSpec> = emptyMap(),
    val photoSlots: List<Int> = emptyList(),
    /** key เก่าของ prototype → ชื่อช่องใหม่ เช่น "note#1" → "headline" */
    val legacy: Map<String, String> = emptyMap(),
) {
    @Serializable data class Size(val w: Double, val h: Double)
}

@Serializable
data class SlotSpec(
    val label: String,
    /** "own" · "profile.<ฟิลด์>" · "profile.rates[].price" · "fact.<ค่า>" */
    val from: String,
    val override: Boolean? = null,
    val list: Boolean? = null,
    val defaultText: String? = null,
    val maxLength: Int? = null,
    /** "upper" — แปลงตอนวาด */
    val textCase: String? = null,
    val style: SlotStyle? = null,
    val styleable: List<String> = emptyList(),
)

@Serializable
data class CardTemplate(
    val id: String,
    val name: String,
    val format: String,
    val doc: StarCardDoc,
    val preview: ImageRef,
    val order: Int,
    val active: Boolean,
)

// ─── §6 ระเบียนและคำตอบของ API ──────────────────────────────────────────────────

@Serializable
data class StarCardRecord(
    val id: Int,
    val shortId: String,
    val isPrimary: Boolean,
    val templateId: String? = null,
    val draftRev: Int,
    val draft: StarCardDoc,
    val published: StarCardVersion? = null,
    /** ISO-8601 UTC */
    val updatedAt: String,
)

@Serializable
data class StarCardVersion(
    val version: Int,
    val doc: StarCardDoc,
    val pageImages: List<ImageRef>,
    val ogImage: ImageRef? = null,
    val kinds: List<String>,
    val platform: String,
    val appVersion: String,
    val publishedAt: String,
)

/** สิ่งที่คนเปิดลิงก์การ์ดได้รับ — ไม่มีร่าง ไม่มีข้อมูลส่วนตัว */
@Serializable data class StarCardView(val card: StarCardVersion, val owner: StarOwner, val facts: StarFacts)

@Serializable data class SaveDraftRequest(val cardId: Int, val baseRev: Int, val doc: StarCardDoc)

@Serializable
data class SaveDraftResult(
    val saved: Boolean,
    val rev: Int,
    /** มีเมื่อชนกัน */
    val latest: StarCardRecord? = null,
    /** ก้อนที่ server จัดตามกติกากลางแล้ว — ใช้ก้อนนี้ต่อ */
    val canonical: StarCardDoc? = null,
)

@Serializable
data class PublishRequest(
    val cardId: Int,
    val rev: Int,
    val pageImageIds: List<Int>,
    val ogImageId: Int? = null,
    val platform: String,
    val appVersion: String,
)

/** แก้ข้อมูลเจ้าของทีละช่อง — ห้ามส่งทั้งก้อน */
@Serializable data class StarProfileUpdate(val field: String, val value: JsonElement)

// ─── กติกาข้อ 2 · 3 — จัดรูปแบบกลาง ───────────────────────────────────────────────

fun StarCardDoc.canonicalized(): StarCardDoc = copy(
    theme = theme.canonicalized(),
    pages = pages.map { p -> p.copy(items = p.items.map { it.canonicalized() }) },
)

fun CardTheme.canonicalized(): CardTheme = copy(
    brightness = brightness.r(4),
    hueShift = hueShift.r(4),
    customHue = customHue?.r(4),
    customSat = customSat?.r(4),
    customBri = customBri?.r(4),
    photoDim = photoDim?.r(4),
    photoLean = photoLean?.r(4),
    photo = photo?.canonicalized(),
)

fun WidgetItem.canonicalized(): WidgetItem = copy(
    id = id.lowercase(),
    x = x.r(2), y = y.r(2), w = w.r(2), h = h.r(2),
    style = style.mapValues { (_, s) -> s.copy(pt = s.pt?.r(1)) },
    photos = photos.mapValues { (_, p) -> p.canonicalized() },
)

fun PhotoRef.canonicalized(): PhotoRef =
    copy(fit = fit?.let { it.copy(dx = it.dx.r(4), dy = it.dy.r(4), zoom = it.zoom.r(4)) })

/**
 * ปัดแบบเดียวกับ Swift `.rounded()` (ครึ่งหนึ่งปัดออกจากศูนย์)
 * ห้ามใช้ `kotlin.math.round` (ปัดครึ่งหนึ่งไปหาเลขคู่) หรือ `Math.round` (ครึ่งหนึ่งปัดขึ้นเสมอ) — ค่าติดลบ .5 จะไม่ตรงกับ iOS
 */
private fun Double.r(places: Int): Double {
    val k = 10.0.pow(places)
    return sign(this) * floor(abs(this * k) + 0.5) / k
}

// ─── กติกาข้อ 7 — เก็บฟิลด์ที่ไม่รู้จักไว้ส่งกลับ ────────────────────────────────────

/**
 * ครอบ serializer ที่ plugin สร้างให้ (`@KeepGeneratedSerializer`):
 * ตอนอ่าน แยก key ที่รู้จักไปให้ตัวเดิม ที่เหลือเก็บใน `extra` · ตอนเขียน รวม `extra` กลับเข้าไป
 */
open class KeepUnknownSerializer<T>(
    private val base: KSerializer<T>,
    private val extraOf: (T) -> JsonObject,
    private val withExtra: (T, JsonObject) -> T,
) : KSerializer<T> {
    override val descriptor: SerialDescriptor = base.descriptor
    private val known: Set<String> by lazy { (0 until descriptor.elementsCount).map(descriptor::getElementName).toSet() }

    override fun deserialize(decoder: Decoder): T {
        val input = decoder as? JsonDecoder ?: error("Star Card models read from JSON only")
        val obj = input.decodeJsonElement().jsonObject
        val value = input.json.decodeFromJsonElement(base, JsonObject(obj.filterKeys { it in known }))
        return withExtra(value, JsonObject(obj.filterKeys { it !in known }))
    }

    override fun serialize(encoder: Encoder, value: T) {
        val output = encoder as? JsonEncoder ?: error("Star Card models write JSON only")
        val obj = output.json.encodeToJsonElement(base, value).jsonObject
        output.encodeJsonElement(JsonObject(obj + extraOf(value)))
    }
}
