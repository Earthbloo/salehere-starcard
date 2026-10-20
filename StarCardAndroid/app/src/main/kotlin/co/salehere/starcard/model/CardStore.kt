package co.salehere.starcard.model

import androidx.compose.ui.graphics.Color
import co.salehere.starcard.AppContext
import co.salehere.starcard.theme.docHex
import co.salehere.starcard.theme.hexString
import co.salehere.starcard.theme.hsb
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import co.salehere.starcard.theme.BackdropEffect
import co.salehere.starcard.theme.BackdropStyle
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardInk
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.ColorDuo
import co.salehere.starcard.theme.CornerStyle
import co.salehere.starcard.theme.Palette
import co.salehere.starcard.theme.RGB
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
        /**
         * **ค่าที่ผู้ใช้เลือกในถาด** — คีย์ = `opt` ของ `widget.controls` · ชั้นข้อความเก็บ `face` `tint` `scale` `align` `points`
         * ก้อนเดียวของทุกใบ (19 ต.ค. 2569) · ไฟล์ก่อนหน้านั้นไม่มีคีย์นี้ → อ่านจากคีย์เก่าข้างล่าง (อ่านอย่างเดียว ไม่เขียนแล้ว)
         */
        var options: Map<String, String>? = null,
        // ── คีย์เก่า (อ่านอย่างเดียว) ──
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
        // (`keepPhotoBG` `noEmboss` `blindEmboss` ถูกถอด 19 ต.ค. 2569 — ไฟล์เก่าที่มีคีย์พวกนี้อ่านได้ คีย์ถูกข้าม)
        /** ชิ้นที่ตรึงกับก้นหน้า (ดู `PinnedSeal`) — เก็บเฉพาะตอนเป็น true */
        var pinned: Boolean? = null,
        /** หน้าตาของตรารับรอง — ไฟล์เก่าไม่มี = เหรียญ (เก็บเฉพาะตอนไม่ใช่เหรียญ) */
        var sealStyle: String? = null,
        /** หน้าตาของชุดห้าสไตล์ — เก็บเฉพาะชิ้นที่ `kind.isKit` */
        var kit: KitConfig? = null,
        /** รุ่นแรกเก็บแค่เปิด/ปิดลายทาง — อ่านอย่างเดียว */
        var stripes: Boolean? = null,
    )

    @Serializable
    data class Page(var items: List<Item>)

    /**
     * สีของการ์ด — **สิ่งเดียวที่ API เก็บเรื่องสี** (20 ต.ค. 2569 รอบ 3): `primary` = พื้น · `secondary` = หมึกของการ์ดสองสี
     * ไม่มีชื่อพาเลตต์/คู่สี/HSB อีกแล้ว — renderer ทุกแพลตฟอร์มคิดสีที่เหลือจากสองค่านี้เอง
     */
    @Serializable
    data class Colors(var primary: String, var secondary: String? = null)

    /**
     * theme ที่ API เก็บ (20 ต.ค. 2569 รอบ 4): `colors` · `ink` (โทน) · `backdrop` + ของพื้นรูป — แค่นั้น
     * `corner` `strip` `inkAuto` ถอดออก (ผู้ใช้: "เอาออกไปให้หมด"): มุม = มน · แถบ = บรรทัด เสมอ · หมึกเก็บตรง ๆ
     */
    @Serializable
    data class Theme(
        var colors: Colors? = null,
        var ink: String,
        var backdrop: String,
        // ---- ฟิลด์รุ่นก่อน (ชื่อพาเลตต์ · คู่สี · HSB ที่ตั้งเอง · ความสว่าง · เลื่อนเฉด) — อ่านอย่างเดียว ไม่เขียนแล้ว
        // doc เก่าแปลงเป็น `colors` ตอนอ่านด้วย `LegacyTheme.colors` (สูตรเดียวกับ `migrateTheme` ใน theme.js)
        var palette: String? = null,
        var brightness: Double? = null,
        var hueShift: Double? = null,
        var customHue: Double? = null,
        var customSat: Double? = null,
        var customBri: Double? = null,
        var duo: String? = null,
        var duoFlipped: Boolean? = null,
        var inkAuto: Boolean? = null,
        var corner: String? = null,
        var strip: String? = null,
        var photoEffect: String? = null,
        var photoDim: Double? = null,
        /** รูปพื้นหลังเอียงไปทางสว่างแค่ไหน (ดู `CardTheme.photoLean`) — ไฟล์เก่าไม่มี = วัดใหม่ตอนเปิด */
        var photoLean: Double? = null,
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
                        options = storedOptions(it),
                    )
                })
            },
            theme = CardSnapshot.Theme(
                colors = CardSnapshot.Colors(primary = theme.primary.hexString, secondary = theme.secondary?.hexString),
                ink = theme.ink.raw, backdrop = theme.backdrop.raw,
                photoEffect = theme.photoEffect.raw, photoDim = theme.photoDim,
                photoLean = theme.photoLean,
            ),
            index = index,
        )

    /** คีย์หน้าตาตัวอักษรของชั้นข้อความใน `options` */
    private val TEXT_KEYS = listOf("face", "tint", "scale", "align", "points")

    /** สิ่งที่เขียนลง `options` ของไฟล์ — ตัวเลือกในถาด · ชั้นข้อความเพิ่มหน้าตาตัวอักษร · ว่าง = ไม่เขียนคีย์ */
    private fun storedOptions(w: WidgetInstance): Map<String, String>? {
        val o = w.options.toMutableMap()
        if (w.kind.usesTextStyle) {
            o["face"] = w.textStyle.face.raw
            o["tint"] = w.textStyle.tint.raw
            o["scale"] = w.textStyle.scale.raw
            o["align"] = w.textStyle.align.raw
            o["points"] = w.textStyle.points.toDouble().toString()
        }
        return o.ifEmpty { null }
    }

    /** ไฟล์ก่อน 19 ต.ค. 2569 — ค่าที่เคยกระจายเป็นคีย์ของชิ้น → `options` ก้อนเดียว (`sealStyle` `pinned` ถูกข้าม) */
    private fun legacyOptions(it: CardSnapshot.Item): Map<String, String> {
        val o = mutableMapOf<String, String>()
        val p = it.pattern ?: (if (it.stripes == true) PlatePattern.stripe.raw else null)
        if (p != null && p != PlatePattern.plain.raw) o["pattern"] = p
        it.kit?.let { k ->
            for ((kk, v) in k.opts) o.putIfAbsent(kk, v)
            if (k.fill != KitFill.solid) o["fill"] = k.fill.name
            if (k.corner != KitCorner.round) o["corner"] = k.corner.name
        }
        it.face?.let { v -> o["face"] = v }
        it.tint?.let { v -> o["tint"] = v }
        it.scale?.let { v -> o["scale"] = v }
        it.align?.let { v -> o["align"] = v }
        it.points?.let { v -> o["points"] = v.toString() }
        return o
    }

    /** แปลงภาพนิ่งกลับเป็นสถานะรันไทม์ — คู่ขาของ `snapshot` และใจดีกับไฟล์เก่าแบบเดียวกับ `load` */
    fun restore(snap: CardSnapshot): Restored? {
        // สำรับสติกเกอร์ในไฟล์เก่าไม่มีวัสดุติดมากับชนิด — ตอนนั้นมันมาจากมุมของธีม
        val legacyPopSkin = if (CornerStyle.from(snap.theme.corner) == CornerStyle.soft) PopSkin.paper else PopSkin.glass
        val pages = snap.pages.map { p ->
            CardPage(p.items.mapNotNull { item ->
                val kind = WidgetKind.decode(item.kind, legacyPopSkin = legacyPopSkin, kitLook = item.kit?.style?.raw)
                    ?: return@mapNotNull null
                var w = WidgetInstance.make(
                    kind,
                    x = item.x.toFloat(), y = item.y.toFloat(), w = item.w.toFloat(), h = item.h.toFloat(),
                    id = item.id?.let { s -> runCatching { UUID.fromString(s) }.getOrNull() } ?: UUID.randomUUID(),
                )
                val o = (item.options ?: legacyOptions(item)).toMutableMap()
                var ts = w.textStyle
                if (kind.usesTextStyle) {
                    o["face"]?.let { s -> CardFont.from(s) }?.let { v -> ts = ts.copy(face = v) }
                    o["tint"]?.let { s -> TextTint.from(s) }?.let { v -> ts = ts.copy(tint = v) }
                    o["scale"]?.let { s -> TextScale.from(s) }?.let { v -> ts = ts.copy(scale = v) }
                    o["align"]?.let { s -> TextAlignment.from(s) }?.let { v -> ts = ts.copy(align = v) }
                    ts = ts.copy(points = o["points"]?.toFloatOrNull() ?: ts.scale.size)
                }
                // หน้าตาตัวอักษรเป็นของชั้นข้อความเท่านั้น — ไฟล์เก่าเขียนคีย์พวกนี้ให้ทุกชิ้น ไม่ใช่ตัวเลือกของ widget
                for (k in TEXT_KEYS) o.remove(k)
                w = w.copy(
                    surface = WidgetSurface.decode(item.surface),
                    border = item.border,
                    options = o,
                )
                ts = ts.copy(
                    slotFaces = (item.slotFaces ?: emptyMap()).mapNotNull { (k, v) -> CardFont.from(v)?.let { f -> k to f } }.toMap(),
                    slotTints = (item.slotTints ?: emptyMap()).mapNotNull { (k, v) -> TextTint.from(v)?.let { t -> k to t } }.toMap(),
                    slotSizes = (item.slotSizes ?: emptyMap()).mapNotNull { (k, v) -> WidgetTextSize.from(v)?.let { z -> k to z } }.toMap(),
                )
                w.copy(textStyle = ts)
            })
        }
        if (pages.none { it.items.isNotEmpty() }) return null

        var t = CardTheme()
        CardInk.from(snap.theme.ink)?.let { t = t.copy(ink = it) }
        BackdropStyle.from(snap.theme.backdrop)?.let { t = t.copy(backdrop = it) }
        // สี: doc ใหม่ = `colors` ตรง ๆ · doc เก่า = แปลงจากชื่อพาเลตต์/คู่สี/HSB ด้วยสูตรเดิม
        val colors = LegacyTheme.colors(snap.theme)
        t = t.copy(
            primary = Color.docHex(colors.primary) ?: Palette.midnight.dark,
            secondary = Color.docHex(colors.secondary),
        )
        // doc เก่า: พลิกคู่สี = โทนสว่าง · สีเดียวที่เคยเปิด inkAuto = เลือกฝั่งจากความสว่างให้ครั้งเดียว
        LegacyTheme.inkOverride(snap.theme, t.primary, t.lightInk)?.let { t = t.copy(ink = it) }
        snap.theme.photoEffect?.let { BackdropEffect.from(it) }?.let { t = t.copy(photoEffect = it) }
        snap.theme.photoDim?.let { t = t.copy(photoDim = it) }

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


// MARK: - doc รุ่นก่อน → `colors` (20 ต.ค. 2569 รอบ 3)

/**
 * แปลงสีของ doc เก่า (ชื่อพาเลตต์ · คู่สี · HSB ที่ตั้งเอง · ความสว่าง · เลื่อนเฉด) เป็น `colors`
 * = สูตร `backdropColors.top` ของ CardTheme ก่อนรอบ 3 · ต้องตรงกับ `LegacyTheme` ของ iOS และ `legacyColors` ใน theme.js ทุกบรรทัด
 */
object LegacyTheme {
    /**
     * หมึกของ doc เก่า (ไม่มี `colors`): คู่สี — `duoFlipped` = โทนสว่าง (paper) · ไม่พลิก = night ·
     * สีเดียวที่เคยเปิด `inkAuto` (ไม่มีคีย์ = เปิด) — เลือกฝั่งจากความสว่างของพื้นให้ครั้งเดียวตอนแปลง (= `autoInk`)
     */
    fun inkOverride(t: CardSnapshot.Theme, primary: Color, lightInk: CardInk): CardInk? {
        if (t.colors != null || t.backdrop == BackdropStyle.photo.raw) return null
        if (t.duo?.let { ColorDuo.find(it) } != null) return if (t.duoFlipped == true) CardInk.paper else CardInk.night
        if (t.inkAuto == false) return null
        val l = RGB(primary).luminance
        return if ((l + 0.05) / 0.07 > 1.05 / (l + 0.05)) lightInk else CardInk.night
    }

    fun colors(t: CardSnapshot.Theme): CardSnapshot.Colors {
        t.colors?.let { c ->
            val p = Color.docHex(c.primary)
            if (p != null) return CardSnapshot.Colors(p.hexString, Color.docHex(c.secondary)?.hexString)
        }
        val d = t.duo?.let { ColorDuo.find(it) }
        if (d != null && t.backdrop != BackdropStyle.photo.raw) {
            // คู่เก็บตามนิยาม (เข้ม · อ่อน) เสมอ — ข้างที่ขึ้นเป็นพื้นไปอยู่ที่ `ink` (ดู `inkOverride`)
            return CardSnapshot.Colors(d.dark.hexString, d.light.hexString)
        }
        val pal = Palette.from(t.palette) ?: Palette.midnight
        val hueShift = t.hueShift ?: 0.0; val brightness = t.brightness ?: 0.30
        val rawHue = (t.customHue ?: pal.backdropHue) + hueShift
        val hue = rawHue - floor(rawHue)
        val sat = if (t.customHue != null) min(0.6, max(0.15, t.customSat ?: 0.5)) else pal.backdropSaturation
        val bri = t.customBri
        if (bri != null && t.customHue != null) {
            return CardSnapshot.Colors(hsb(hue, min(1.0, max(0.0, t.customSat ?: 0.5)), min(1.0, max(0.0, bri))).hexString)
        }
        val ink = CardInk.from(t.ink) ?: CardInk.night
        val lightInk = if ((t.customSat ?: 0.0) >= 0.35) CardInk.mist else CardInk.paper
        val active = when {
            t.backdrop == BackdropStyle.photo.raw -> CardInk.night
            t.inkAuto ?: true -> CardInk.night
            ink.isLight -> lightInk
            else -> CardInk.night
        }
        val b = brightness
        val top = when (active) {
            CardInk.night -> hsb(hue, max(0.0, sat - b * 0.28), 0.05 + b * 0.52)
            CardInk.paper -> hsb(hue, 0.03 + sat * 0.04, 0.955 + b * 0.045)
            CardInk.mist -> hsb(hue, 0.09 + sat * 0.16, 0.945 + b * 0.05)
        }
        return CardSnapshot.Colors(top.hexString)
    }
}
