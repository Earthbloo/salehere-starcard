package co.salehere.starcard.model

import co.salehere.starcard.AppContext
import co.salehere.starcard.theme.BackdropEffect
import co.salehere.starcard.theme.BackdropStyle
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardInk
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.ColorDuo
import co.salehere.starcard.theme.CornerStyle
import co.salehere.starcard.theme.Palette
import co.salehere.starcard.theme.StripStyle
import co.salehere.starcard.theme.TextAlignment
import co.salehere.starcard.theme.TextScale
import co.salehere.starcard.theme.TextTint
import co.salehere.starcard.theme.WidgetTextSize
import co.salehere.starcard.theme.WidgetTextStyle
import java.util.UUID
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

// MARK: - จำสถานะการ์ดข้ามการเปิดแอป (= Model/CardStore.swift)
//
// เก็บลง SharedPreferences เป็น JSON ก้อนเดียว **สำหรับตอนพัฒนาเท่านั้น**
// ของจริงต้องไปอยู่บน API (ดู `WidgetContent.kt` — เก็บ layout ต่อชิ้น เนื้อหาต่อตระกูล)
//
// DTO แยกจาก `CardPage`/`WidgetInstance` เป็นชั้นกันชน: ฟิลด์ไหนหายไปก็ตกไปใช้ค่าตั้งต้น การ์ดไม่หายทั้งใบ

/** ภาพนิ่งของการ์ดหนึ่งใบ — รูปแบบเดียวกับที่ API จะเก็บในอนาคต */
@Serializable
data class CardSnapshot(
    var pages: List<Page>,
    var theme: Theme,
    var index: Int,
    /** เวอร์ชันของรูปแบบ — ขึ้นเลขเมื่อไหร่ของเก่าถูกทิ้งแทนที่จะ decode ผิด ๆ */
    var version: Int = 2,
) {
    @Serializable
    data class Item(
        var kind: String,
        // พิกัด/ขนาดเป็น pt บนพื้นที่ออกแบบ (ดู `PageLayout`) ไม่ใช่ช่องกริดอีกแล้ว
        var x: Double,
        var y: Double,
        var w: Double,
        var h: Double,
        var surface: String,
        var border: Boolean,
        /** ตัวตนของชิ้น — ข้อความที่พิมพ์เอง (`Profile.note`) ผูกกับ id นี้ ไฟล์เก่าไม่มี = สุ่มใหม่ตอนกู้ */
        var id: String? = null,
        // หน้าตาตัวอักษร — ไฟล์เก่าไม่มีสี่คีย์นี้ จึงเป็น optional ทั้งชุด
        var face: String? = null,
        var tint: String? = null,
        var scale: String? = null,
        var align: String? = null,
        /** ขนาดตัวอักษรของก้อนข้อความ — ไฟล์รุ่นก่อนไม่มี จึงตกไปใช้ขั้น `scale` เดิมแทน */
        var points: Double? = null,
        // หน้าตาที่ตั้งให้ **รายช่อง** — ฟอนต์ · สี · ขนาด (คีย์คือ "ฟิลด์#ลำดับ")
        var slotFaces: Map<String, String>? = null,
        var slotTints: Map<String, String>? = null,
        var slotSizes: Map<String, String>? = null,
        /** ลายบนแผ่น — ไฟล์เก่าไม่มี = แผ่นเรียบ */
        var pattern: String? = null,
        /** ลบพื้นหลังรูปคน — ไฟล์เก่าไม่มี = เปิด (เก็บเฉพาะตอนปิด) */
        var keepPhotoBG: Boolean? = null,
        /** ตราปั๊มนูนบนแผ่น — ไฟล์เก่าไม่มี = เปิด (เก็บเฉพาะตอนปิด) */
        var noEmboss: Boolean? = null,
        /** ปั๊มนูนเปล่าแทนฟอยล์ — ไฟล์เก่าไม่มี = ฟอยล์ (เก็บเฉพาะตอนเลือกนูน) */
        var blindEmboss: Boolean? = null,
        /** รุ่นแรกเก็บแค่เปิด/ปิดลายทาง — อ่านอย่างเดียว */
        var stripes: Boolean? = null,
    )

    @Serializable
    data class Page(var items: List<Item>)

    @Serializable
    data class Theme(
        var palette: String,
        var ink: String,
        var corner: String,
        var backdrop: String,
        var brightness: Double,
        var hueShift: Double,
        var customHue: Double? = null,
        var customSat: Double? = null,
        // ไฟล์เก่าไม่มีสองคีย์นี้ · `inkAuto` ที่หายไปต้องอ่านเป็น false ไม่ใช่ค่าตั้งต้นของสตรักต์
        var customBri: Double? = null,
        var inkAuto: Boolean? = null,
        var photoEffect: String? = null,
        var photoDim: Double? = null,
        /** แบบของแถบผู้ออกบัตร — ไฟล์เก่าไม่มี ตกไปใช้ "บรรทัด" */
        var strip: String? = null,
        /** รูปพื้นหลังเอียงไปทางสว่างแค่ไหน (ดู `CardTheme.photoLean`) — ไฟล์เก่าไม่มี = วัดใหม่ตอนเปิด */
        var photoLean: Double? = null,
        /** คู่สีที่เลือกไว้ (ดู `ColorDuo`) — ไฟล์เก่าไม่มี = ยังใช้พาเลตต์ตามเดิม */
        var duo: String? = null,
        var duoFlipped: Boolean? = null,
    )
}

/**
 * ที่เก็บชั่วคราวสำหรับตอนพัฒนา
 * ฉบับร่าง **แยกช่องตามรูปแบบการ์ด** (`CardFormat`) — พอร์ตกับสตอรี่ไม่ทับกัน
 */
object CardStore {
    /** สถานะรันไทม์ที่กู้จากภาพนิ่ง (= tuple `(pages, theme, index)` ของ Swift) */
    data class Restored(val pages: List<CardPage>, val theme: CardTheme, val index: Int)

    /** JSON ร่วมของทุกที่เก็บ — `explicitNulls = false` ให้ optional ที่เป็น null หายจากไฟล์เหมือน JSONEncoder ของ iOS */
    internal val json: Json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
        explicitNulls = false
    }

    /**
     * ขึ้นเป็น v2 ตอนที่ผังเปลี่ยนจากกริดคอลัมน์เป็นพิกเซล — ฉบับร่าง v1 อ่านไม่ได้แล้ว
     * และ **แปลงข้ามมาไม่ได้จริง ๆ** เพราะ "6 คอลัมน์" ของเดิมแปลว่าเต็มหน้าเท่าไหร่ก็ได้
     */
    private fun key(format: CardFormat): String = "starcard.draft.v2.${format.raw}"

    private const val enabledKey = "starcard.draft.enabled"

    /** ปิดการจำสถานะได้จากที่เดียว — เวลาอยากทดสอบหน้าตั้งต้นจริง ๆ */
    var enabled: Boolean
        get() = AppContext.prefs.let { if (it.contains(enabledKey)) it.getBoolean(enabledKey, true) else true }
        set(value) { AppContext.prefs.edit().putBoolean(enabledKey, value).apply() }

    /** แปลงสถานะรันไทม์เป็นภาพนิ่ง — จุดเดียวที่รู้วิธี encode ใช้ร่วมกันทั้งช่องร่างเก่าและคลังการ์ด */
    fun snapshot(pages: List<CardPage>, theme: CardTheme, index: Int): CardSnapshot =
        CardSnapshot(
            pages = pages.map { page ->
                CardSnapshot.Page(items = page.items.map {
                    CardSnapshot.Item(
                        kind = it.kind.raw,
                        x = it.x.toDouble(), y = it.y.toDouble(), w = it.w.toDouble(), h = it.h.toDouble(),
                        surface = it.surface.raw, border = it.border,
                        id = it.id.toString(),
                        face = it.textStyle.face.raw,
                        tint = it.textStyle.tint.raw,
                        scale = it.textStyle.scale.raw,
                        align = it.textStyle.align.raw,
                        points = it.textStyle.points.toDouble(),
                        slotFaces = it.textStyle.slotFaces.mapValues { e -> e.value.raw },
                        slotTints = it.textStyle.slotTints.mapValues { e -> e.value.raw },
                        slotSizes = it.textStyle.slotSizes.mapValues { e -> e.value.raw },
                        pattern = if (it.pattern == PlatePattern.plain) null else it.pattern.raw,
                        keepPhotoBG = if (it.liftPhoto) null else true,
                        noEmboss = if (it.emboss) null else true,
                        blindEmboss = if (it.embossBlind) true else null,
                    )
                })
            },
            theme = CardSnapshot.Theme(
                palette = theme.palette.raw, ink = theme.ink.raw,
                corner = theme.corner.raw, backdrop = theme.backdrop.raw,
                brightness = theme.brightness, hueShift = theme.hueShift,
                customHue = theme.customHue, customSat = theme.customSat,
                customBri = theme.customBri, inkAuto = theme.inkAuto,
                photoEffect = theme.photoEffect.raw, photoDim = theme.photoDim,
                strip = theme.strip.raw, photoLean = theme.photoLean,
                duo = theme.duoID, duoFlipped = theme.duoFlipped,
            ),
            index = index,
        )

    /** แปลงภาพนิ่งกลับเป็นสถานะรันไทม์ — คู่ขาของ `snapshot` และใจดีกับไฟล์เก่าแบบเดียวกับ `load` */
    fun restore(snap: CardSnapshot): Restored? {
        // สำรับสติกเกอร์ในไฟล์เก่าไม่มีวัสดุติดมากับชนิด — ตอนนั้นมันมาจากมุมของธีม
        val legacyPopSkin = if (CornerStyle.from(snap.theme.corner) == CornerStyle.soft) PopSkin.paper else PopSkin.glass
        val pages = snap.pages.map { p ->
            CardPage(p.items.mapNotNull { item ->
                val kind = WidgetKind.decode(item.kind, legacyPopSkin = legacyPopSkin) ?: return@mapNotNull null
                var w = WidgetInstance.make(
                    kind,
                    x = item.x.toFloat(), y = item.y.toFloat(), w = item.w.toFloat(), h = item.h.toFloat(),
                    id = item.id?.let { s -> runCatching { UUID.fromString(s) }.getOrNull() } ?: UUID.randomUUID(),
                )
                w = w.copy(
                    surface = WidgetSurface.decode(item.surface),
                    border = item.border,
                    pattern = item.pattern?.let { s -> PlatePattern.from(s) }
                        ?: (if (item.stripes == true) PlatePattern.stripe else PlatePattern.plain),
                    liftPhoto = item.keepPhotoBG != true,
                    emboss = item.noEmboss != true,
                    embossBlind = item.blindEmboss == true,
                )
                var ts = w.textStyle
                item.face?.let { s -> CardFont.from(s) }?.let { v -> ts = ts.copy(face = v) }
                item.tint?.let { s -> TextTint.from(s) }?.let { v -> ts = ts.copy(tint = v) }
                item.scale?.let { s -> TextScale.from(s) }?.let { v -> ts = ts.copy(scale = v) }
                item.align?.let { s -> TextAlignment.from(s) }?.let { v -> ts = ts.copy(align = v) }
                ts = ts.copy(
                    points = item.points?.toFloat() ?: ts.scale.size,
                    slotFaces = (item.slotFaces ?: emptyMap()).mapNotNull { (k, v) -> CardFont.from(v)?.let { f -> k to f } }.toMap(),
                    slotTints = (item.slotTints ?: emptyMap()).mapNotNull { (k, v) -> TextTint.from(v)?.let { t -> k to t } }.toMap(),
                    slotSizes = (item.slotSizes ?: emptyMap()).mapNotNull { (k, v) -> WidgetTextSize.from(v)?.let { z -> k to z } }.toMap(),
                )
                w.copy(textStyle = ts)
            })
        }
        if (pages.none { it.items.isNotEmpty() }) return null

        var t = CardTheme()
        Palette.from(snap.theme.palette)?.let { t = t.copy(palette = it) }
        CardInk.from(snap.theme.ink)?.let { t = t.copy(ink = it) }
        CornerStyle.from(snap.theme.corner)?.let { t = t.copy(corner = it) }
        BackdropStyle.from(snap.theme.backdrop)?.let { t = t.copy(backdrop = it) }
        t = t.copy(
            brightness = snap.theme.brightness,
            hueShift = snap.theme.hueShift,
            customHue = snap.theme.customHue,
            customSat = snap.theme.customSat,
            customBri = snap.theme.customBri,
            inkAuto = snap.theme.inkAuto ?: false,
        )
        snap.theme.photoEffect?.let { BackdropEffect.from(it) }?.let { t = t.copy(photoEffect = it) }
        snap.theme.photoDim?.let { t = t.copy(photoDim = it) }
        snap.theme.strip?.let { StripStyle.from(it) }?.let { t = t.copy(strip = it) }
        // รหัสที่ไม่รู้จักแล้ว (คู่สีถูกถอดออกจากชุด) ตกไปใช้พาเลตต์แทน ไม่ใช่การ์ดไร้สี
        t = t.copy(
            duoID = snap.theme.duo?.let { ColorDuo.find(it) }?.id,
            duoFlipped = snap.theme.duoFlipped ?: false,
        )

        return Restored(pages, t, minOf(maxOf(0, snap.index), pages.size - 1))
    }

    fun save(pages: List<CardPage>, theme: CardTheme, index: Int, format: CardFormat = CardFormat.portfolio) {
        if (!enabled) return
        val snap = snapshot(pages, theme, index)
        val data = runCatching { json.encodeToString(CardSnapshot.serializer(), snap) }.getOrNull() ?: return
        AppContext.prefs.edit().putString(key(format), data).apply()
    }

    /** มีงานค้างไว้ในแบบนี้ไหม — หน้าเลือกแบบใช้ตัดสินว่าจะขึ้นป้าย "ทำต่อ" */
    fun hasDraft(format: CardFormat): Boolean =
        enabled && AppContext.prefs.contains(key(format))

    /** คืน null เมื่อยังไม่เคยเซฟ หรือไฟล์เก่าอ่านไม่ออก — ผู้เรียกใช้ค่าตั้งต้นต่อไป */
    fun load(format: CardFormat = CardFormat.portfolio): Restored? {
        if (!enabled) return null
        val data = AppContext.prefs.getString(key(format), null) ?: return null
        val snap = runCatching { json.decodeFromString(CardSnapshot.serializer(), data) }.getOrNull() ?: return null
        if (snap.pages.isEmpty()) return null
        return restore(snap)
    }

    /** ล้างของที่จำไว้ — กลับไปหน้าตั้งต้นในการเปิดครั้งถัดไป */
    fun clear(format: CardFormat) {
        AppContext.prefs.edit().remove(key(format)).apply()
    }

    fun clearAll() { CardFormat.entries.forEach { clear(it) } }
}
