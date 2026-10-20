package co.salehere.starcard.layout

import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.double
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.math.abs

// MARK: - เล่นคำตอบที่ iOS บันทึกไว้ใน fixture ซ้ำ (WIDGET-SPEC.md §7)
//
// fixture ของ iOS (`-exportSpecs`) จดทุกคำถามที่ตัวคำนวณถาม — ตัววัดข้อความ (`measures` · `lineHeights`)
// และแหล่งข้อมูล (`data`) · สองคลาสนี้ตอบด้วยค่าชุดนั้นทุกข้อ:
//   - unit test: ทั้งตัววัดและข้อมูลเป็นของ iOS → ทดสอบ **อัลกอริทึมล้วน ๆ**
//   - ตัวส่งออกบนเครื่อง: ข้อมูลเป็นของ iOS แต่ตัววัด/ตัวคำนวณ/ตัววาดเป็นของ Android → ทดสอบว่า
//     ผังเดียวกัน + ข้อมูลเดียวกัน ได้ภาพเดียวกัน (ข้อมูลของแต่ละแอปเป็นอีกเรื่อง — เทียบแยกที่ `SpecDataDiff`)
// คำถามที่ iOS ไม่เคยถาม = เดินคนละทางกับ iOS แล้ว — จดเป็น `misses` ไม่เดาค่า

/** แหล่งข้อมูลที่ตอบด้วยค่าที่ iOS บันทึกไว้ (`case.data`) · ถามนอกชุด → `fallback` (ถ้ามี) และจดไว้ */
class ReplayData(o: JsonObject, private val fallback: SpecDataSource? = null) : SpecDataSource {
    val misses = ArrayList<String>()

    val texts: Map<Pair<String, String?>, String> = o["texts"]!!.jsonArray.associate {
        val t = it.jsonObject
        (t["slot"]!!.jsonPrimitive.content to t["preset"]?.let { p -> if (p is JsonNull) null else p.jsonPrimitive.content }) to
            t["v"]!!.jsonPrimitive.content
    }
    val lists: Map<String, List<SpecItem>> = o["lists"]!!.jsonObject.mapValues { (_, arr) ->
        arr.jsonArray.map { e ->
            val it = e.jsonObject
            SpecItem(it["id"]!!.jsonPrimitive.content, it["i"]!!.jsonPrimitive.int,
                it["fields"]!!.jsonObject.mapValues { f -> f.value.jsonPrimitive.content })
        }
    }
    val flags: Map<String, Boolean> = o["flags"]!!.jsonObject.mapValues { it.value.jsonPrimitive.boolean }
    private val fonts = o["fonts"]!!.jsonArray.map { it.jsonObject }

    override fun text(slot: String, preset: String?): String =
        texts[slot to preset] ?: run { misses += "text $slot preset=$preset"; fallback?.text(slot, preset) ?: "" }
    override fun list(name: String): List<SpecItem> =
        lists[name] ?: run { misses += "list $name"; fallback?.list(name) ?: emptyList() }
    override fun flag(name: String): Boolean =
        flags[name] ?: run { misses += "flag $name"; fallback?.flag(name) ?: false }
    override fun font(slot: String?, face: String, size: Double, weight: Int): SpecFont {
        val f = fonts.firstOrNull {
            val s = it["slot"]?.let { e -> if (e is JsonNull) null else e.jsonPrimitive.content }
            s == slot && it["face"]!!.jsonPrimitive.content == face && abs(it["size"]!!.jsonPrimitive.double - size) < 1e-6 &&
                it["weight"]!!.jsonPrimitive.int == weight
        }
        if (f == null) {
            misses += "font $slot $face/$size/$weight"
            return fallback?.font(slot, face, size, weight) ?: SpecFont(face, size, weight)
        }
        return SpecFont(f["outFace"]!!.jsonPrimitive.content, f["outSize"]!!.jsonPrimitive.double, f["outWeight"]!!.jsonPrimitive.int)
    }

    /** ข้อความของคำตอบที่ต่างจาก `other` (แหล่งข้อมูลของแอปเอง) — ถามคำถามชุดเดียวกับที่ iOS ถาม */
    fun diff(other: SpecDataSource): List<String> {
        val out = ArrayList<String>()
        for ((k, v) in texts) { val a = other.text(k.first, k.second); if (a != v) out += "text ${k.first}: '${a.take(40)}' ≠ iOS '${v.take(40)}'" }
        for ((k, v) in flags) { val a = other.flag(k); if (a != v) out += "flag $k: $a ≠ iOS $v" }
        for ((k, v) in lists) {
            val a = other.list(k)
            if (a.size != v.size) { out += "list $k: ${a.size} items ≠ iOS ${v.size}"; continue }
            for (i in v.indices) {
                val ex = v[i].fields; val got = a[i].fields
                for ((fk, fv) in ex) if ((got[fk] ?: "∅") != fv) out += "list $k[$i].$fk: '${(got[fk] ?: "∅").take(30)}' ≠ iOS '${fv.take(30)}'"
                for (fk in got.keys - ex.keys) out += "list $k[$i].$fk: extra on Android"
            }
        }
        return out
    }
}

/** ตัววัดที่ตอบด้วยค่าที่ iOS บันทึกไว้ (`case.measures` · `case.lineHeights`) */
class ReplayMeasurer(c: JsonObject) : SpecMeasurer {
    private data class Measure(
        val t: String, val face: String, val size: Double, val weight: Int,
        val tracking: Double, val kerning: Double, val lineHeight: Double,
        val width: Double?, val w: Double, val h: Double, val lines: Int,
    )
    private data class LineQ(val face: String, val size: Double, val weight: Int, val lineHeight: Double, val italic: Boolean, val v: Double)

    private val measures = c["measures"]!!.jsonArray.map { m ->
        val o = m.jsonObject
        Measure(
            t = o["t"]!!.jsonPrimitive.content, face = o["face"]!!.jsonPrimitive.content,
            size = o["size"]!!.jsonPrimitive.double, weight = o["weight"]!!.jsonPrimitive.int,
            tracking = o["tracking"]?.jsonPrimitive?.doubleOrNull ?: 0.0, kerning = o["kerning"]?.jsonPrimitive?.doubleOrNull ?: 0.0,
            lineHeight = o["lineHeight"]?.jsonPrimitive?.doubleOrNull ?: 1.0,
            width = o["width"]?.let { if (it is JsonNull) null else it.jsonPrimitive.doubleOrNull },
            w = o["w"]!!.jsonPrimitive.double, h = o["h"]!!.jsonPrimitive.double, lines = o["lines"]!!.jsonPrimitive.int)
    }
    private val lineQs = (c["lineHeights"]?.jsonArray ?: emptyList()).map { l ->
        val o = l.jsonObject
        LineQ(o["face"]!!.jsonPrimitive.content, o["size"]!!.jsonPrimitive.double, o["weight"]!!.jsonPrimitive.int,
            o["lineHeight"]!!.jsonPrimitive.double, o["italic"]!!.jsonPrimitive.boolean, o["v"]!!.jsonPrimitive.double)
    }
    val misses = ArrayList<String>()

    private fun near(a: Double, b: Double) = abs(a - b) < 1e-6

    override fun measure(text: String, font: SpecFont, width: Double?): Pair<FSize, Int> {
        val m = measures.firstOrNull {
            it.t == text && it.face == font.face && it.weight == font.weight && near(it.size, font.size) &&
                near(it.tracking, font.tracking) && near(it.kerning, font.kerning) && near(it.lineHeight, font.lineHeight) &&
                (if (it.width == null || width == null) it.width == null && width == null else near(it.width, width))
        }
        if (m != null) return FSize(m.w, m.h) to m.lines
        misses += "measure '${text.take(24)}' ${font.face}/${font.size}/${font.weight} w=$width"
        return FSize(0.0, 0.0) to 1
    }

    override fun lineHeight(font: SpecFont): Double {
        val q = lineQs.firstOrNull {
            it.face == font.face && it.weight == font.weight && near(it.size, font.size) &&
                near(it.lineHeight, font.lineHeight) && it.italic == font.italic
        }
        if (q != null) return q.v
        misses += "lineHeight ${font.face}/${font.size}/${font.weight}×${font.lineHeight}"
        return 0.0
    }
}
