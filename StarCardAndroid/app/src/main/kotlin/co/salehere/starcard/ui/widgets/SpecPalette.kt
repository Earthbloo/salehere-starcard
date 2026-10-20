package co.salehere.starcard.ui.widgets

import androidx.compose.ui.graphics.Color
import co.salehere.starcard.model.KitConfig
import co.salehere.starcard.model.KitFill
import co.salehere.starcard.model.KitLook
import co.salehere.starcard.model.PopSkin
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.ScrapTone
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.hsb
import co.salehere.starcard.theme.mixed
import co.salehere.starcard.theme.onLightSurface
import co.salehere.starcard.theme.opacity

// MARK: - สีของผัง = 6 บทบาท × 3 พื้น (20 ต.ค. 2569 · WIDGET-SPEC.md §4)
// (= Views/Widgets/Primitives/SpecPalette.swift — พอร์ตบรรทัดต่อบรรทัด)
//
// ผังเขียนแค่ชื่อบทบาท: `bg` `bg2` `ink` `ink2` `accent` `line` (+ `white` `black` `clear` `#hex` · `@ความทึบ`)
// "พื้น" บอกว่าบทบาทนั้นคิดจากสูตรไหน — `widget.on` = พื้นตั้งต้นของใบ · โหนด `on` = พื้นของโหนดนั้น
// พื้นสว่าง 4 แบบเดิม (กระดาษ · Canva · สติกเกอร์ · สแครปบุ๊ก) ยุบเป็น `light` กระดาษจากธีมเดียวกัน · แผ่นโปสเตอร์ = `dark`

/** พื้นที่ widget (หรือโหนด) นั่งอยู่ (= `SpecSurface`) */
enum class SpecSurface(val raw: String) {
    /** การ์ดตรง ๆ — หมึกผ่านตัวยันความอ่านออกของธีม */
    card("card"),
    /** แผ่นสว่าง — กระดาษจากธีม: คู่สี = สีอ่อนของคู่ · พาเลตต์ = ครีมอมเฉด */
    light("light"),
    /** แผ่นเข้มอิ่มสี (`PosterPlate`) — คู่สี = สีเข้มของคู่ */
    dark("dark");

    companion object {
        fun from(raw: String?): SpecSurface? = raw?.let { r -> entries.firstOrNull { it.raw == r } }
    }
}

/**
 * ค่าของชิ้น + ธีม ที่ทุกพื้นต้องใช้คิดสี — สร้างครั้งเดียวต่อชิ้น แล้วถาม `color(token, on)` กี่ครั้งก็ได้ (= `struct SpecPalette`)
 * - base: พื้นตั้งต้นของใบ (`widget.on`) · ไม่รู้จัก/ไม่ใส่ = `card`
 * - kit/border/surface/popSkin/scrapTone: รับไว้ให้ผู้เรียกเดิมคอมไพล์ได้ — สีไม่ใช้แล้ว (`look` ยังคิดให้ตัววาดที่ถามหน้าตาของชุด)
 */
class SpecPalette(
    val theme: CardTheme,
    val ink: InkStyle,
    val accent: Color,
    kit: KitConfig,
    val border: Boolean,
    val surface: WidgetSurface,
    popSkin: PopSkin?,
    base: String?,
    scrapTone: ScrapTone? = null,
) {
    val base: SpecSurface = SpecSurface.from(base) ?: SpecSurface.card
    /** ใบนี้ไม่ได้วาดแผ่นของตัวเองอยู่ (ไม่มีพื้น/กระจก chrome · Canva "โปร่ง") → ตัวหนังสือใช้หมึกการ์ด (= iOS `noSheet`) */
    val noSheet: Boolean = surface == WidgetSurface.clear || surface == WidgetSurface.pane || kit.fill == KitFill.clear

    /** หน้าตาของชุดห้าสไตล์ของชิ้นนี้ (มุม/ขอบ) — ตัววาดบางที่ยังถาม · สีไม่ได้มาจากตรงนี้แล้ว */
    val look: KitLook by lazy { KitLook(kit.resolved(theme), border = border, cardDark = !ink.isLight) }

    /** token → สี · `on` = พื้นของโหนด (null = พื้นตั้งต้นของใบ) */
    fun color(token: String, on: String?): Color {
        var name = token
        var alpha: Double? = null
        val at = token.lastIndexOf('@')
        if (at >= 0) { name = token.substring(0, at); alpha = token.substring(at + 1).toDoubleOrNull() }
        val explicit = SpecSurface.from(on)
        val s = explicit ?: base
        val c: Color = when (name) {
            "white" -> Color.White
            "black" -> Color.Black
            "clear" -> return Color.Transparent
            "bg", "bg2", "ink", "ink2", "accent", "line" -> if (explicit == null && noSheet) return card(name, alpha) else when (s) {
                SpecSurface.card -> return card(name, alpha)
                SpecSurface.light -> sheet(name, light = true)
                SpecSurface.dark -> sheet(name, light = false)
            }
            else -> if (name.startsWith("#")) specHex(name) else Color.Transparent
        }
        return alpha?.let { c.opacity(it) } ?: c
    }

    /** บนการ์ด ความทึบวิ่งผ่านตัวยันความอ่านออก — ค่าตั้งต้นของแต่ละบทบาทคือน้ำหนักที่ผังเคยเขียน */
    private fun card(role: String, a: Double?): Color = when (role) {
        "ink" -> ink.text(a ?: 1.0)
        "ink2" -> ink.ghost(a ?: 0.5)
        "line" -> ink.line(a ?: 0.12)
        "bg2" -> ink.fill(a ?: 0.14)
        "accent" -> a?.let { accent.opacity(it) } ?: accent
        else -> { val p = if (ink.isLight) Color.White else grey(0.08); a?.let { p.opacity(it) } ?: p }   // bg
    }

    /**
     * แผ่นของใบ — สูตรเดียวทั้งสว่างและเข้ม ต่างกันแค่ว่า "กระดาษ" กับ "หมึก" เป็นสีไหนของธีม (= iOS `sheet(_:light:)`)
     * - สว่าง: กระดาษครีมอมเฉด (คู่สี = สีอ่อน · +7% เข้าหาสีเข้มเมื่อการ์ดสว่าง) · หมึกถ่านอมเฉด (คู่สี = สีเข้ม)
     * - เข้ม: แผ่นอิ่มสี (`PosterPlate.plate`) · หมึกครีม (`PosterPlate.cream`) · สีเน้น = สีเน้นดิบ
     */
    private fun sheet(role: String, light: Boolean): Color {
        val paper: Color
        val inkC: Color
        val accentC: Color
        if (light) {
            val l = theme.duoLight
            val d = theme.duoDark
            if (l != null && d != null) {
                paper = l.mixed(d, if (theme.duoFlipped) 0.07 else 0.0); inkC = d; accentC = d
            } else {
                paper = hsb(theme.backdropHue, 0.10, 0.97)
                inkC = hsb(theme.backdropHue, 0.06, 0.11)
                accentC = theme.rawAccent.onLightSurface()
            }
        } else {
            paper = PosterPlate.plate(theme); inkC = PosterPlate.cream(theme); accentC = theme.rawAccent
        }
        return when (role) {
            "bg" -> paper
            "bg2" -> paper.mixed(inkC, 0.06)
            "ink" -> inkC
            "ink2" -> inkC.mixed(paper, 0.38)
            "accent" -> accentC
            else -> inkC.opacity(0.2)   // line
        }
    }
}

/** `#RRGGBB` / `#RRGGBBAA` → สี (= `Color(hex:)` ของ iOS) */
fun specHex(hex: String): Color {
    var h = hex.trimStart('#')
    if (h.length == 6) h += "FF"
    val v = h.toLongOrNull(16) ?: return Color.Transparent
    return Color(
        red = ((v shr 24) and 0xFF).toFloat() / 255f,
        green = ((v shr 16) and 0xFF).toFloat() / 255f,
        blue = ((v shr 8) and 0xFF).toFloat() / 255f,
        alpha = (v and 0xFF).toFloat() / 255f,
    )
}
