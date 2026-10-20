package co.salehere.starcard.layout

import co.salehere.starcard.model.SpecAlign
import co.salehere.starcard.model.SpecCondition
import co.salehere.starcard.model.SpecInsets
import co.salehere.starcard.model.SpecJustify
import co.salehere.starcard.model.SpecLength
import co.salehere.starcard.model.SpecNode
import co.salehere.starcard.model.SpecType
import co.salehere.starcard.model.WidgetSpec
import kotlin.math.max
import kotlin.math.min

// ตัวคำนวณกล่องจากผัง — อัลกอริทึมเดียวที่ทุกแพลตฟอร์มต้อง port ให้ตรง (= Layout/SpecSolver.swift ทีละบรรทัด)
//
// เข้า: `WidgetSpec` + กล่องราก (W×H หน่วยออกแบบ) + แหล่งข้อมูล + ตัววัดข้อความ
// ออก: รายการกล่อง `SpecBox` (x · y · w · h สัมบูรณ์ในกล่องราก) ทุกโหนดที่ต้องวาด พร้อมผลข้อความ
// ตัววาด **ไม่ตัดสินใจอะไร** นอกจากทาตามกล่อง · ทุกกล่องปัดเป็น 2 ทศนิยม
//
// **คิดด้วย Double** เพราะ CGFloat ของ iOS (64 บิต) คือ Double — Float สะสมเศษคนละแบบ แล้วไปพลิกเงื่อนไข
// ขอบ (`> width + 0.01`) ได้ ผลจึงต่างกันทั้งที่สูตรเดียวกัน
//
// ไฟล์นี้ต้องเป็น Kotlin ล้วน (ไม่มี Android/Compose) — รันใน JVM unit test ได้

/** ขนาด (กว้าง × สูง) ในหน่วยออกแบบ */
data class FSize(val width: Double, val height: Double) {
    companion object { val zero = FSize(0.0, 0.0) }
}

/** กรอบสัมบูรณ์ในกล่องราก */
data class FRect(val x: Double, val y: Double, val width: Double, val height: Double) {
    val minX: Double get() = x
    val minY: Double get() = y
    val maxX: Double get() = x + width
    val maxY: Double get() = y + height
    companion object { val zero = FRect(0.0, 0.0, 0.0, 0.0) }
}

/** ฟอนต์ที่ตัววัดต้องรู้จัก — ชื่อ face เป็น token ของแอป (`noto` · `mitr` · `serif` …) */
data class SpecFont(
    val face: String,
    val size: Double,
    /** 100–900 */
    val weight: Int,
    val tracking: Double = 0.0,
    val kerning: Double = 0.0,
    val italic: Boolean = false,
    val lineHeight: Double = 1.0,
)

/** ตัววัดข้อความของแพลตฟอร์ม */
interface SpecMeasurer {
    /** ขนาดของสตริงเมื่อจัดในความกว้าง `width` (null = ไม่จำกัด) — คืนความกว้างที่ใช้จริง · ความสูง · จำนวนบรรทัด */
    fun measure(text: String, font: SpecFont, width: Double?): Pair<FSize, Int>
    /** ความสูงหนึ่งบรรทัดของฟอนต์นี้ */
    fun lineHeight(font: SpecFont): Double
}

/** หนึ่งชิ้นในรายการ (`list`) — ค่าตามชื่อฟิลด์ · `i` = ลำดับ */
data class SpecItem(val id: String, val i: Int, val fields: Map<String, String>) {
    fun value(key: String): String = when (key) {
        "i" -> i.toString()
        "rank" -> (i + 1).toString()
        // `%02d` ของ Swift — ไม่ใช้ `String.format` เพราะ locale ของเครื่องอาจให้ตัวเลขไม่ใช่ ASCII
        "rank2" -> (i + 1).toString().padStart(2, '0')
        else -> fields[key] ?: ""
    }
}

/**
 * `String(Double)` ของ Swift — `27.0` · `1240000.0` · `0.5` (Kotlin ให้ `1.24E6` ตั้งแต่ 1e7 ซึ่งทำให้
 * `$k=max` ที่เทียบ **สตริง** ของ `<key>.max` ไม่ตรงกับ iOS)
 */
fun swiftDouble(d: Double): String {
    if (d.isNaN() || d.isInfinite()) return d.toString()
    val a = kotlin.math.abs(d)
    if (a != 0.0 && (a >= 1e16 || a < 1e-4)) return d.toString()
    var s = java.math.BigDecimal(d.toString()).stripTrailingZeros().toPlainString()
    if (!s.contains('.')) s += ".0"
    return s
}

/** `Double(String)` ของ Swift — ไม่รับช่องว่างหน้า/หลัง (Kotlin `toDoubleOrNull` รับ) */
fun swiftParseDouble(s: String): Double? {
    if (s.isEmpty() || s.first().isWhitespace() || s.last().isWhitespace()) return null
    return s.toDoubleOrNull()
}

/** แหล่งข้อมูลที่ผังอ้างถึง — แพลตฟอร์มเป็นคนให้ */
interface SpecDataSource {
    /** ข้อความของช่อง (`name` · `categories#0` · `note#1`) — ว่าง = ไม่มี · `preset` = ข้อความตั้งต้นของดีไซน์ */
    fun text(slot: String, preset: String?): String
    fun list(name: String): List<SpecItem>
    fun flag(name: String): Boolean
    /** ฟอนต์ของช่องหลังผ่านที่ผู้ใช้ตั้งให้ช่องนั้น — `slot` ว่าง = ป้ายของดีไซน์ ไม่ปรับ */
    fun font(slot: String?, face: String, size: Double, weight: Int): SpecFont
}

data class SpecTextResult(
    val string: String,
    val size: Double,
    val lines: Int,
    /** ช่องที่ผูก (หลังแทนค่า `$i` แล้ว) */
    val slot: String?,
)

/** กล่องหนึ่งใบที่ตัววาดต้องทา */
data class SpecBox(
    /** path ของโหนด เช่น `r/0/2` (`c3` = ชิ้นที่ 3 ของ chips) */
    val id: String,
    val node: SpecNode,
    val frame: FRect,
    val text: SpecTextResult? = null,
    val item: SpecItem? = null,
    val depth: Int,
)

/**
 * ขั้นต่ำของตัวอักษรเมื่อผู้ใช้หดกรอบ — หน่วย pt **บนการ์ด** (หลังคูณสเกลกรอบ × `fitScale`) · ตรงกับ Swift `SpecLegibility`
 * หัวกับเนื้อหามีขั้นต่ำคนละค่า · ขั้นต่ำไม่เกินขนาดในผัง (ขนาดตั้งต้นไม่เปลี่ยน มีผลเฉพาะตอนหด)
 */
object SpecLegibility {
    /** ขนาดในผังตั้งแต่ค่านี้ = หัว — ไม่ใส่ `role` ในผังก็แยกได้เอง */
    const val TITLE_FROM = 18.0
    const val TITLE_MIN = 18.0
    const val CONTENT_MIN = 12.0

    /** ความแรงที่ลองทีละขั้นเมื่อการยกเต็มที่ทำให้ผังล้น/ชิ้นอื่นเล็กลงกว่าเดิม (สุดท้าย = ผังเดิม ไม่ยก) */
    val STEPS = doubleArrayOf(1.0, 0.66, 0.33)
    /** รูปต้องเหลืออย่างน้อยเท่านี้ของขนาดเดิม (ด้านสั้น) — ไม่งั้นลดการยกตัวอักษรลง */
    const val IMAGE_KEEP = 0.6

    /** ขั้นต่ำของชิ้นนี้บนการ์ด (pt) — min(ขนาดในผัง, ขั้นต่ำของบทบาท) · 0 = ไม่มี (`deco`) */
    fun target(design: Double, role: String?): Double {
        if (role == "deco") return 0.0
        val title = if (role != null) role == "title" else design >= TITLE_FROM
        return min(design, if (title) TITLE_MIN else CONTENT_MIN)
    }

    /** ขนาดต่ำสุดในหน่วยผัง · 0 = ไม่มีขั้นต่ำ (ไม่ได้หด หรือ `role: "deco"`) */
    fun floor(design: Double, role: String?, scale: Double): Double {
        if (!(scale > 0 && scale < 1)) return 0.0
        return target(design, role) / scale
    }
}

class SpecSolver(
    val spec: WidgetSpec,
    val box: FSize,
    val data: SpecDataSource,
    val measurer: SpecMeasurer,
    /** สเกลที่ chrome คูณทั้งก้อน (`min(W/w0, H/h0)`) — ใช้คิดขั้นต่ำที่อ่านออก · 1 = ไม่คิด */
    val renderScale: Double = 1.0,
) {
    /** ขั้นย่อที่ `fitScale` เลือก (1 = ไม่ย่อ) — กล่องที่คืนอยู่ในหน่วย `box / scale` ตัววาดคูณกลับทั้งก้อน */
    var scale: Double = 1.0
        private set
    /** ความแรงของการยกตัวอักษร (0 = ผังเดิม · 1 = ถึงขั้นต่ำเต็มที่) — `solve` ลดลงทีละขั้นถ้าผังรับไม่ไหว */
    private var strength = 1.0
    /** รอบนี้มีข้อความถูกยกขึ้นจริงไหม — ไม่มี = ผลเท่าผังเดิม ไม่ต้องลองต่อ */
    private var lifted = false

    // ต้นไม้ที่ขยายแล้ว
    private class N(
        /** ผังตามไฟล์ */
        val base: SpecNode, val id: String, val item: SpecItem?, val depth: Int,
    ) {
        /** ผังที่ใช้คำนวณ — ข้อความที่ถูกยกขึ้นตามขั้นต่ำที่อ่านออก กล่องตายตัวของมันโตตามด้วย (`prepare`) */
        var node: SpecNode = base
        var children: List<N> = emptyList()
        var frame: FRect = FRect.zero
        var text: SpecTextResult? = null
        /** ข้อความสูงเกินกล่องที่ได้เท่าไหร่ (ล้น = ทับของข้าง ๆ) */
        var overflow = 0.0
        /** แคชผลวัดข้อความต่อความกว้าง */
        val textCache = HashMap<Double, Pair<FSize, SpecTextResult>>()
    }

    private fun expand(node: SpecNode, id: String, item: SpecItem?, depth: Int): N? {
        val cond = node.cond
        if (cond != null && !evaluate(cond, item)) return null
        val n = N(node, id, item, depth)
        val name = node.list
        val tpl = node.each
        if (node.type == SpecType.chips && name != null && tpl != null) {
            var items = data.list(name)
            val w = node.where
            if (w != null) items = items.filter { evaluate(w, it) }
            val sort = node.sort
            if (sort != null) {
                // หลายคีย์คั่นด้วย `,` — `"platformOrder asc, priceRaw asc"` (คีย์แรกเท่ากันค่อยดูคีย์ถัดไป)
                val keys: List<Pair<String, Boolean>> = sort.split(",").filter { it.isNotEmpty() }.map { k ->
                    val parts = k.split(" ").filter { it.isNotEmpty() }
                    Pair(parts.firstOrNull() ?: "", parts.size > 1 && parts[1] == "desc")
                }
                // = ตัวเทียบของ Swift (`a` มาก่อน `b` ไหม) · sort ของทั้งสองฝั่งคงลำดับเดิมเมื่อเท่ากัน
                fun before(a: SpecItem, b: SpecItem): Boolean {
                    for ((key, desc) in keys) {
                        val av = a.value(key); val bv = b.value(key)
                        if (av == bv) continue
                        val x = swiftParseDouble(av); val y = swiftParseDouble(bv)
                        val less: Boolean
                        if (x != null && y != null) {
                            if (x == y) continue
                            less = x < y
                        } else less = av < bv
                        return if (desc) !less else less
                    }
                    return false
                }
                items = items.sortedWith { a, b -> if (before(a, b)) -1 else if (before(b, a)) 1 else 0 }
                items = items.mapIndexed { i, it -> it.copy(i = i) }
            }
            val g = node.group
            if (g != null) {
                val seen = HashSet<String>()
                items = items.filter { seen.add(it.value(g)) }
                items = items.mapIndexed { i, it -> it.copy(i = i) }
            }
            val lim = node.limit
            if (lim != null) items = items.take(lim)
            // ค่าสรุปของรายการ (หลัง sort/limit) ติดไปกับทุกชิ้น: `<key>.max` · `<key>.sum` สำหรับฟิลด์ตัวเลข
            val maxes = LinkedHashMap<String, Double>(); val sums = LinkedHashMap<String, Double>()
            for (it in items) for ((k, v) in it.fields) {
                val d = swiftParseDouble(v) ?: continue
                maxes[k] = max(maxes[k] ?: Double.NEGATIVE_INFINITY, d)
                sums[k] = (sums[k] ?: 0.0) + d
            }
            items = items.map { it ->
                val f = LinkedHashMap(it.fields)
                for ((k, m) in maxes) { f["$k.max"] = swiftDouble(m); f["$k.sum"] = swiftDouble(sums[k] ?: 0.0) }
                it.copy(fields = f)
            }
            n.children = items.mapIndexedNotNull { idx, it -> expand(tpl, "$id/c$idx", it, depth + 1) }
        } else {
            n.children = (node.children ?: emptyList()).mapIndexedNotNull { idx, c -> expand(c, "$id/$idx", item, depth + 1) }
        }
        return n
    }

    /** `owner.verified` · `has:tagline` · `!has:about` · `list:socials>1` · `sample` · `$field` (ของรายการ ไม่ว่าง) */
    private fun evaluate(cond: String, item: SpecItem?): Boolean {
        // `a & b` = ทุกข้อจริง · `a | b` = ข้อใดข้อหนึ่งจริง (& ผูกแน่นกว่า |)
        if (cond.contains("|")) return cond.split("|").filter { it.isNotEmpty() }.any { evaluate(it, item) }
        if (cond.contains("&")) return cond.split("&").filter { it.isNotEmpty() }.all { evaluate(it, item) }
        var c = cond.trim()
        var negate = false
        if (c.startsWith("!")) { negate = true; c = c.drop(1) }
        // `$field` ที่อยู่ *ข้างใน* ชื่อธง (`hidden:$platform` · `opt:chan=$platform`) แทนด้วยค่าของชิ้นก่อน
        if (!c.startsWith("$") && c.contains("$") && item != null) {
            for ((k, v) in item.fields) c = c.replace("$$k", v)
            c = c.replace("\$i", item.i.toString())
        }
        val v: Boolean
        if (c.startsWith("has:")) {
            v = resolveText(c.drop(4), item).isNotEmpty()
        } else if (c.startsWith("list:")) {
            val body = c.drop(5)
            val gt = body.indexOf(">"); val eq = body.indexOf("=")
            v = if (gt >= 0) {
                val name = body.substring(0, gt); val n = body.substring(gt + 1).toIntOrNull() ?: 0
                data.list(name).size > n
            } else if (eq >= 0) {
                val name = body.substring(0, eq); val n = body.substring(eq + 1).toIntOrNull() ?: 0
                data.list(name).size == n
            } else data.list(body).isNotEmpty()
        } else if (c.startsWith("$") && item != null) {
            val body = c.drop(1)
            // เทียบตัวเลข: `$viewsRaw>0` · `$shareRaw>=40` · `$i<2`
            val m = Regex("(<=|>=|<|>)").find(body)
            if (m != null) {
                val key = body.substring(0, m.range.first); val op = m.value
                val rhs = swiftParseDouble(body.substring(m.range.last + 1)) ?: 0.0
                val lhs = swiftParseDouble(item.value(key)) ?: 0.0
                v = when (op) {
                    "<" -> lhs < rhs
                    "<=" -> lhs <= rhs
                    ">" -> lhs > rhs
                    else -> lhs >= rhs
                }
            } else if (body.endsWith("=max")) {
                val k = body.dropLast(4); v = item.value(k) == item.value("$k.max") && item.value(k).isNotEmpty()
            } else if (body.endsWith("=first")) {
                v = item.i == 0
            } else {
                v = item.value(body).isNotEmpty()
            }
        } else {
            v = data.flag(c)
        }
        return if (negate) !v else v
    }

    /** ข้อความของโหนด — ช่อง (`slot`) ก่อน · ว่างแล้วใช้ `text` ของดีไซน์ · `$field` อ่านจากรายการ · `{field}` ในข้อความแทนค่า */
    private fun resolveText(raw: String, item: SpecItem?): String {
        if (raw.startsWith("$") && item != null) return item.value(raw.drop(1))
        var s = raw
        if (item != null && s.contains("\$i")) s = s.replace("\$i", item.i.toString())
        if (raw.startsWith("$") || raw.contains("{")) {
            if (item != null) {
                for ((k, v) in item.fields) s = s.replace("{$k}", v)
                s = s.replace("{i}", item.i.toString())
            }
            return s
        }
        return data.text(s, null)
    }

    private fun boundSlot(node: SpecNode, item: SpecItem?): String? {
        val slot = node.slot ?: return null
        if (slot.startsWith("$")) return null
        if (item != null && slot.contains("\$i")) return slot.replace("\$i", item.i.toString())
        return slot
    }

    private fun stringOf(n: N): Pair<String, String?> {
        val node = n.node
        var s = ""
        var slot: String? = null
        val sl = node.slot
        if (sl != null) {
            if (sl.startsWith("$")) s = n.item?.value(sl.drop(1)) ?: ""
            else { slot = boundSlot(node, n.item); s = data.text(slot ?: sl, node.preset) }
        }
        val t = node.text
        if (s.isEmpty() && t != null) s = resolveTemplate(t, n.item)
        val p = node.preset
        if (s.isEmpty() && p != null) s = p
        when (node.textCase) {
            // Swift `uppercased()` ไม่ขึ้นกับ locale ของเครื่อง — ตรึง ROOT (ไม่งั้นเครื่องภาษาตุรกีได้ İ)
            "upper" -> s = s.uppercase(java.util.Locale.ROOT)
            "lower" -> s = s.lowercase(java.util.Locale.ROOT)
        }
        return Pair(s, slot)
    }

    /** แทนค่าของรายการในข้อความ — `{field}` และ `$field` (คีย์ยาวก่อน กัน `$share` ไปกิน `$shareRaw`) */
    private fun resolveTemplate(t: String, item: SpecItem?): String {
        if (item == null || !(t.contains("{") || t.contains("$"))) return t
        var s = t
        val keys = (item.fields.keys.toList() + listOf("i", "rank", "rank2")).sortedByDescending { it.length }
        for (k in keys) {
            val v = item.value(k)
            s = s.replace("{$k}", v)
            s = s.replace("$$k", v)
        }
        return s
    }

    // ขนาดตัวอักษรตามกล่องราก

    private fun baseSize(node: SpecNode): Double {
        var size = node.size ?: 14.0
        for (r in node.sizeWhen ?: emptyList()) if (SpecCondition.box(r.`when`, box.width, box.height)) { size = r.size; break }
        return size
    }

    private fun fontFor(n: N, size: Double): SpecFont {
        val node = n.node
        val f = data.font(boundSlot(node, n.item), node.face ?: "body", size, node.weight ?: 400)
        return f.copy(
            tracking = node.tracking ?: 0.0,
            kerning = node.kerning ?: 0.0,
            italic = node.italic ?: false,
            lineHeight = node.lineHeight ?: 1.0,
        )
    }

    /** วัดข้อความในความกว้าง `width` (null = บรรทัดเดียวไม่จำกัด) — ย่อตาม `shrinkTo` จนลง `maxLines` */
    private fun fitText(n: N, width: Double?): Pair<FSize, SpecTextResult> {
        val key = width ?: -1.0
        n.textCache[key]?.let { return it }
        val (s, slot) = stringOf(n)
        val node = n.node
        val maxLines = node.maxLines ?: (if (width == null) 1 else 0)   // 0 = ไม่จำกัด
        val design = baseSize(node)
        // ขั้นต่ำที่อ่านออก = ขนาดเริ่ม · ถ้าที่ไม่พอ ย่อลงได้จนถึงพื้นเดิมของผัง — คำที่ถูกตัด "@mane…" แย่กว่าตัวเล็กลงนิดหน่อย
        val legible = legibleSize(node, design)
        if (legible > design) lifted = true
        var size = max(design, legible)
        val floorSize = node.shrinkTo?.let { min(it, design) } ?: design
        var out: Pair<FSize, Int> = Pair(FSize.zero, 1)
        // fit-to-width: โตทีละ 1pt จนบรรทัดเดียวล้นความกว้าง แล้วถอยหนึ่งขั้น (เพดาน `growTo`)
        val cap = node.growTo
        if (cap != null && width != null && s.isNotEmpty()) {
            var grown = size
            while (grown + 1 <= cap) {
                val m = measurer.measure(s, fontFor(n, grown + 1), null)
                if (m.first.width > width + 0.01) break
                grown += 1
            }
            size = grown
        }
        while (true) {
            val f = fontFor(n, size)
            if (s.isEmpty()) {
                out = Pair(FSize(0.0, measurer.lineHeight(f)), 1)
                break
            }
            val m = measurer.measure(s, f, width)
            out = m
            val overflowLines = maxLines > 0 && m.second > maxLines
            val overflowWidth = if (width != null) m.first.width > width + 0.01 else false
            if (!(overflowLines || overflowWidth) || size - 0.5 < floorSize) break
            size -= 0.5
        }
        var lines = out.second
        if (maxLines > 0) lines = min(lines, maxLines)
        val f = fontFor(n, size)
        val lh = measurer.lineHeight(f)
        // ความสูงจากจำนวนบรรทัดที่แสดงจริง (ตัดท้ายแล้วกล่องไม่สูงเกิน)
        val h = if (s.isEmpty()) lh else (if (lines == out.second) max(out.first.height, lh) else lh * lines)
        val r = Pair(
            FSize(if (width != null) min(out.first.width, width) else out.first.width, h),
            SpecTextResult(s, size, lines, slot),
        )
        n.textCache[key] = r
        return r
    }

    // ขนาดเนื้อหา (hug)

    /** ความยาวที่ระบุตายตัว — ตัวเลข หรือ % ของที่ว่าง (`avail`) · null = ไม่ได้ระบุ/fill/hug */
    private fun fixed(l: SpecLength?, avail: Double?): Double? = when (l) {
        is SpecLength.Pt -> l.v
        is SpecLength.Pct -> avail?.let { it * l.v / 100 }
        else -> null
    }
    private fun isFill(l: SpecLength?): Boolean = l == SpecLength.Fill

    private fun pad(node: SpecNode): SpecInsets = node.pad ?: SpecInsets()

    private fun clampW(node: SpecNode, w: Double): Double {
        var v = w
        node.minW?.let { v = max(v, it) }
        node.maxW?.let { v = min(v, it) }
        return max(0.0, v)
    }
    private fun clampH(node: SpecNode, h: Double): Double {
        var v = h
        node.minH?.let { v = max(v, it) }
        node.maxH?.let { v = min(v, it) }
        return max(0.0, v)
    }

    /** ขนาดที่โหนดต้องการเมื่อให้ที่ `availW` × `availH` (null = ไม่จำกัด) */
    private fun intrinsic(n: N, availW: Double?, availH: Double?): FSize {
        val node = n.node
        val fw = fixed(node.w, availW); val fh = fixed(node.h, availH)
        if (fw != null && fh != null) return FSize(clampW(node, fw), clampH(node, fh))
        val a = node.aspect
        if (a != null && a > 0) {
            if (fw != null) return FSize(clampW(node, fw), clampH(node, fw / a))
            if (fh != null) return FSize(clampW(node, fh * a), clampH(node, fh))
        }
        var size: FSize
        when (node.type) {
            SpecType.text -> {
                val w = fw ?: availW
                val (m, _) = fitText(n, w?.let { clampW(node, it) })
                size = FSize(fw ?: m.width, fh ?: m.height)
            }
            SpecType.icon -> {
                val s = node.size ?: 16.0
                size = FSize(fw ?: fh ?: s, fh ?: fw ?: s)
            }
            // รูปไม่มีขนาดในตัว — ไม่ระบุ = เต็มที่ที่มีให้ (ปกติใส่ `grow` หรือ `aspect`)
            SpecType.image -> size = FSize(fw ?: availW ?: 0.0, fh ?: availH ?: 0.0)
            SpecType.rect, SpecType.spacer -> size = FSize(fw ?: 0.0, fh ?: 0.0)
            SpecType.line -> size = FSize(fw ?: availW ?: 0.0, fh ?: 1.0)
            SpecType.col, SpecType.row, SpecType.chips, SpecType.stack -> {
                val p = pad(node)
                val innerW = (fw ?: availW)?.let { max(0.0, it - p.h) }
                val innerH = (fh ?: availH)?.let { max(0.0, it - p.v) }
                val c = contentSize(n, innerW, innerH)
                size = FSize(fw ?: (c.width + p.h), fh ?: (c.height + p.v))
            }
        }
        if (a != null && a > 0) {
            if (fw == null && fh == null) size = FSize(size.width, size.width / a)
        }
        return FSize(clampW(node, size.width), clampH(node, size.height))
    }

    private fun chipsWrap(node: SpecNode): Boolean = node.type == SpecType.chips && node.wrap != false && node.direction != "col"
    private fun chipsCol(node: SpecNode): Boolean = node.type == SpecType.chips && node.direction == "col"

    /** ขนาดเนื้อหาข้างในคอนเทนเนอร์ (ไม่รวม pad) */
    private fun contentSize(n: N, innerW: Double?, innerH: Double?): FSize {
        val node = n.node
        val gap = node.gap ?: 0.0
        when (node.type) {
            SpecType.stack -> {
                var w = 0.0; var h = 0.0
                for (c in n.children) {
                    val s = intrinsic(c, innerW, innerH)
                    w = max(w, s.width + (c.node.dx ?: 0.0)); h = max(h, s.height + (c.node.dy ?: 0.0))
                }
                return FSize(w, h)
            }
            SpecType.row, SpecType.chips -> {
                if (chipsCol(node)) return colContent(n, innerW, gap)
                if ((node.wrap == true || chipsWrap(node)) && innerW != null) {
                    val lines = wrapLines(n, innerW, gap)
                    val h = lines.fold(0.0) { acc, l -> acc + l.height } + gap * max(0, lines.size - 1)
                    val w = lines.maxOfOrNull { it.width } ?: 0.0
                    return FSize(min(w, innerW), h)
                }
                var w = 0.0; var h = 0.0
                for ((i, c) in n.children.withIndex()) {
                    val s = intrinsic(c, null, innerH)
                    w += s.width + (if (i > 0) gap else 0.0); h = max(h, s.height)
                }
                return FSize(w, h)
            }
            else -> return colContent(n, innerW, gap)
        }
    }

    // ส่วน `col` ของ contentSize (Swift ใช้ fallthrough)
    private fun colContent(n: N, innerW: Double?, gap: Double): FSize {
        var w = 0.0; var h = 0.0
        for ((i, c) in n.children.withIndex()) {
            val s = intrinsic(c, innerW, null)
            h += s.height + (if (i > 0) gap else 0.0); w = max(w, s.width)
        }
        return FSize(w, h)
    }

    private class Line(val items: MutableList<Pair<N, FSize>>, var width: Double, var height: Double)

    private fun wrapLines(n: N, width: Double, gap: Double): List<Line> {
        val lines = ArrayList<Line>()
        var cur = Line(ArrayList(), 0.0, 0.0)
        for (c in n.children) {
            val s = intrinsic(c, width, null)
            val need = if (cur.items.isEmpty()) s.width else cur.width + gap + s.width
            if (cur.items.isNotEmpty() && need > width + 0.01) {
                lines.add(cur); cur = Line(ArrayList(), 0.0, 0.0)
            }
            cur.items.add(Pair(c, s))
            cur.width = if (cur.items.isEmpty()) 0.0 else (if (cur.items.size == 1) s.width else cur.width + gap + s.width)
            cur.height = max(cur.height, s.height)
        }
        if (cur.items.isNotEmpty()) lines.add(cur)
        return lines
    }

    // วางผัง

    private fun layout(n: N, frame: FRect) {
        n.frame = frame
        val node = n.node
        if (node.type == SpecType.text) {
            val w = max(0.0, frame.width)
            val (m, r) = fitText(n, w)
            n.text = r
            n.overflow = m.height - frame.height
            return
        }
        if (n.children.isEmpty()) return
        val p = pad(node)
        val inner = FRect(frame.minX + p.left, frame.minY + p.top,
            max(0.0, frame.width - p.h), max(0.0, frame.height - p.v))
        val gap = node.gap ?: 0.0
        when (node.type) {
            SpecType.stack -> layoutStack(n, inner)
            SpecType.row, SpecType.chips -> {
                if (chipsCol(node)) layoutFlex(n, inner, gap, row = false)
                else if (node.wrap == true || chipsWrap(node)) layoutWrap(n, inner, gap)
                else layoutFlex(n, inner, gap, row = true)
            }
            else -> layoutFlex(n, inner, gap, row = false)
        }
    }

    private fun layoutStack(n: N, inner: FRect) {
        for (c in n.children) {
            val cn = c.node
            val fw = fixed(cn.w, inner.width); val fh = fixed(cn.h, inner.height)
            var s = intrinsic(c, inner.width, inner.height)
            if (isFill(cn.w) || (fw == null && cn.type != SpecType.text && cn.type != SpecType.icon && cn.aspect == null && cn.type != SpecType.rect)) s = s.copy(width = inner.width)
            if (isFill(cn.h) || (fh == null && (cn.type == SpecType.image || cn.type == SpecType.col || cn.type == SpecType.row || cn.type == SpecType.stack) && cn.aspect == null)) s = s.copy(height = inner.height)
            if (cn.type == SpecType.text && fw == null) { s = FSize(inner.width, intrinsic(c, inner.width, inner.height).height) }
            if (cn.type == SpecType.rect && fw == null && !isFill(cn.w)) s = s.copy(width = inner.width)
            if (cn.type == SpecType.rect && fh == null && !isFill(cn.h)) s = s.copy(height = inner.height)
            s = FSize(min(s.width, inner.width), min(s.height, inner.height))
            val (ax, ay) = placement(cn.place)
            val x = inner.minX + (inner.width - s.width) * ax + (cn.dx ?: 0.0)
            val y = inner.minY + (inner.height - s.height) * ay + (cn.dy ?: 0.0)
            layout(c, FRect(x, y, s.width, s.height))
        }
    }

    private fun placement(place: String?): Pair<Double, Double> {
        if (place == null) return Pair(0.0, 0.0)
        var ax = 0.0; var ay = 0.0
        val parts = place.split("-").filter { it.isNotEmpty() }
        for (p in parts) {
            when (p) {
                "top" -> ay = 0.0
                "bottom" -> ay = 1.0
                "left" -> ax = 0.0
                "right" -> ax = 1.0
                "center" -> if (parts.size == 1) { ax = 0.5; ay = 0.5 } else if (parts.first() == p) ay = 0.5 else ax = 0.5
            }
        }
        if (parts == listOf("center")) return Pair(0.5, 0.5)
        return Pair(ax, ay)
    }

    private fun layoutWrap(n: N, inner: FRect, gap: Double) {
        val lines = wrapLines(n, inner.width, gap)
        val totalH = lines.fold(0.0) { acc, l -> acc + l.height } + gap * max(0, lines.size - 1)
        var y = inner.minY + mainOffset(n.node.justify, inner.height - totalH, lines.size).first
        val stepExtra = mainOffset(n.node.justify, inner.height - totalH, lines.size).second
        for (line in lines) {
            val freeW = inner.width - line.width
            var x = inner.minX + mainOffset(n.node.justify, freeW, line.items.size).first
            val extra = mainOffset(n.node.justify, freeW, line.items.size).second
            for ((c, s) in line.items) {
                val ay = crossOffset(c.node.alignSelf ?: n.node.align ?: SpecAlign.start, line.height - s.height)
                layout(c, FRect(x, y + ay, s.width, s.height))
                x += s.width + gap + extra
            }
            y += line.height + gap + stepExtra
        }
    }

    /** ระยะเริ่มกับระยะแทรกระหว่างชิ้นตาม `justify` — (start, between) */
    private fun mainOffset(j: SpecJustify?, free: Double, count: Int): Pair<Double, Double> {
        val f = max(0.0, free)
        return when (j ?: SpecJustify.start) {
            SpecJustify.start -> Pair(0.0, 0.0)
            SpecJustify.center -> Pair(f / 2, 0.0)
            SpecJustify.end -> Pair(f, 0.0)
            SpecJustify.between -> Pair(0.0, if (count > 1) f / (count - 1) else 0.0)
            SpecJustify.around -> { val b = f / max(count, 1); Pair(b / 2, b) }
        }
    }

    private fun crossOffset(a: SpecAlign, free: Double): Double = when (a) {
        SpecAlign.start, SpecAlign.stretch -> 0.0
        SpecAlign.center -> max(0.0, free) / 2
        SpecAlign.end -> max(0.0, free)
    }

    private class K(val basis: Double, val cross: Double, val grow: Double, val shrink: Double, val minMain: Double, val maxMain: Double, val stretch: Boolean)

    private fun layoutFlex(n: N, inner: FRect, gap: Double, row: Boolean) {
        val kids = n.children
        if (kids.isEmpty()) return
        val mainAvail = if (row) inner.width else inner.height
        val crossAvail = if (row) inner.height else inner.width

        val ks = ArrayList<K>()
        for (c in kids) {
            val node = c.node
            val mainLen = if (row) node.w else node.h
            val crossLen = if (row) node.h else node.w
            val align = node.alignSelf ?: n.node.align ?: SpecAlign.stretch
            val stretch = align == SpecAlign.stretch && fixed(crossLen, crossAvail) == null && !isFill(crossLen) && node.aspect == null
            // แกนขวาง
            val fc = fixed(crossLen, crossAvail)
            var cross: Double = if (fc != null) fc
                else if (isFill(crossLen) || stretch) crossAvail
                else if (row) intrinsic(c, null, crossAvail).height else intrinsic(c, crossAvail, null).width
            cross = if (row) clampH(node, min(cross, crossAvail)) else clampW(node, min(cross, crossAvail))
            // แกนหลัก
            var grow = node.grow ?: 0.0
            val basis: Double
            val pct = node.pct
            val item = c.item
            val fm = fixed(mainLen, mainAvail)
            val a = node.aspect
            if (pct != null && item != null) {
                // `$field` = 0–100 ของที่ว่าง · `$field/max` = เทียบค่าสูงสุดในรายการ · `$field/sum` = ส่วนแบ่งของยอดรวม
                val byMax = pct.endsWith("/max"); val bySum = pct.endsWith("/sum")
                val key = (if (byMax || bySum) pct.dropLast(4) else pct).trimStart('$')
                val v = swiftParseDouble(item.value(key)) ?: 0.0
                var denom = 100.0
                if (byMax) denom = max(1e-9, swiftParseDouble(item.value("$key.max")) ?: 1.0)
                if (bySum) denom = max(1e-9, swiftParseDouble(item.value("$key.sum")) ?: 1.0)
                basis = max(0.0, mainAvail - gap * (kids.size - 1)) * min(max(v / denom, 0.0), 1.0)
            } else if (fm != null) basis = fm
            else if (isFill(mainLen)) { basis = 0.0; grow = max(grow, 1.0) }
            else if (a != null && a > 0) basis = if (row) cross * a else cross / a
            else {
                val s = if (row) intrinsic(c, null, cross) else intrinsic(c, cross, null)
                basis = if (row) s.width else s.height
            }
            // ขนาดที่ระบุตายตัวไม่หด · ข้อความ/คอนเทนเนอร์/ที่ว่าง หดได้ · รูป/ไอคอน/สี่เหลี่ยม ไม่หด
            val defaultShrink = if (fm != null || node.pct != null) 0.0
                else if (node.type == SpecType.text || node.type == SpecType.col || node.type == SpecType.row || node.type == SpecType.chips || node.type == SpecType.stack || node.type == SpecType.spacer) 1.0 else 0.0
            val shrink = node.shrink ?: defaultShrink
            val minMain = (if (row) node.minW else node.minH) ?: 0.0
            val maxMain = (if (row) node.maxW else node.maxH) ?: Double.POSITIVE_INFINITY
            ks.add(K(min(max(basis, minMain), maxMain), cross, grow, shrink, minMain, maxMain, stretch))
        }
        val gaps = gap * (kids.size - 1)
        val sizes = DoubleArray(ks.size) { ks[it].basis }
        var free = mainAvail - gaps - sizes.sum()
        if (free > 0) {
            // แจกที่เหลือตาม grow — ชิ้นที่ชน max หยุดรับ แล้วแจกใหม่ให้ที่เหลือ
            val active = ks.indices.filter { ks[it].grow > 0 }.toMutableSet()
            var guardN = 0
            while (free > 0.001 && active.isNotEmpty() && guardN < 8) {
                val total = active.fold(0.0) { acc, i -> acc + ks[i].grow }
                var used = 0.0
                for (i in active.toList()) {
                    val add = free * ks[i].grow / total
                    val want = sizes[i] + add
                    if (want >= ks[i].maxMain) { used += ks[i].maxMain - sizes[i]; sizes[i] = ks[i].maxMain; active.remove(i) }
                    else { sizes[i] = want; used += add }
                }
                free -= used; guardN += 1
            }
        } else if (free < 0) {
            var deficit = -free
            val active = ks.indices.filter { ks[it].shrink > 0 && sizes[it] > ks[it].minMain }.toMutableSet()
            var guardN = 0
            while (deficit > 0.001 && active.isNotEmpty() && guardN < 8) {
                val weight = active.fold(0.0) { acc, i -> acc + ks[i].shrink * ks[i].basis }
                if (!(weight > 0)) break
                var took = 0.0
                for (i in active.toList()) {
                    val cut = deficit * ks[i].shrink * ks[i].basis / weight
                    val want = sizes[i] - cut
                    if (want <= ks[i].minMain) { took += sizes[i] - ks[i].minMain; sizes[i] = ks[i].minMain; active.remove(i) }
                    else { sizes[i] = want; took += cut }
                }
                deficit -= took; guardN += 1
            }
        }
        val used = sizes.sum() + gaps
        val off = mainOffset(n.node.justify, mainAvail - used, kids.size)
        var cursor = (if (row) inner.minX else inner.minY) + off.first
        for ((i, c) in kids.withIndex()) {
            val main = max(0.0, sizes[i])
            val cross = ks[i].cross
            val align = c.node.alignSelf ?: n.node.align ?: SpecAlign.stretch
            val co = crossOffset(align, crossAvail - cross)
            val f = if (row) FRect(cursor, inner.minY + co, main, cross)
                    else FRect(inner.minX + co, cursor, cross, main)
            layout(c, f)
            cursor += main + gap + off.second
        }
    }

    // ออก

    /** ผังที่ใช้กับกรอบ/ข้อมูลนี้ — ผังทางเลือกใบแรกที่ `when` จริง (เงื่อนไขกรอบ หรือเงื่อนไขข้อมูล คั่นด้วย `&`) */
    private fun selectRoot(): SpecNode {
        for (v in spec.variants ?: emptyList()) {
            val ok = v.`when`.split("&").filter { it.isNotEmpty() }.all { part ->
                val e = part.trim()
                val key = e.takeWhile { it.isLetter() }
                if (key in listOf("w", "h", "ratio")) SpecCondition.box(e, box.width, box.height)
                else evaluate(e, null)
            }
            if (ok) return v.root
        }
        return spec.root
    }

    /**
     * เตรียมรอบคำนวณที่ขั้นย่อปัจจุบัน — ล้างแคชข้อความ และให้กล่องตายตัว (`w` `h` `min/max`) โตเท่าที่ตัวอักษรโต:
     * ข้อความเอง + กล่องที่ห่อข้อความโดยตรง (pill · ชิป) โตตามลูกข้อความที่โตมากสุด (ตรงกับ Swift `prepare`)
     */
    private fun prepare(n: N): Double {
        n.textCache.clear()
        var g = 1.0
        if (n.base.type == SpecType.text) {
            val design = baseSize(n.base)
            val legible = legibleSize(n.base, design)
            g = if (design > 0) max(design, legible) / design else 1.0
        } else {
            for (c in n.children) if (c.base.type == SpecType.text) g = max(g, prepare(c))
            for (c in n.children) if (c.base.type != SpecType.text) prepare(c)
        }
        n.node = if (g > 1) grown(n.base, g) else n.base
        return if (n.base.type == SpecType.text) g else 1.0
    }

    /** ขนาดเริ่มที่ยกแล้ว (หน่วยผัง) — ไล่จากขนาดในผังไปหาขั้นต่ำตาม `strength` · 0 = ไม่ยก */
    private fun legibleSize(node: SpecNode, design: Double): Double {
        val f = SpecLegibility.floor(design, node.role, renderScale * scale)
        return if (f > design) design + (f - design) * strength else 0.0
    }

    private fun grown(b: SpecNode, g: Double): SpecNode {
        fun pt(l: SpecLength?): SpecLength? = if (l is SpecLength.Pt) SpecLength.Pt(l.v * g) else l
        return b.copy(
            w = pt(b.w), h = pt(b.h),
            minW = b.minW?.let { it * g }, maxW = b.maxW?.let { it * g },
            minH = b.minH?.let { it * g }, maxH = b.maxH?.let { it * g },
        )
    }

    /** หนึ่งรอบเต็ม: เลือกขั้น `fitScale` แล้วจัดผัง ที่ `strength` ปัจจุบัน */
    private fun run(root: N) {
        var b = box
        scale = 1.0
        lifted = false
        prepare(root)
        val steps = spec.fitScale
        if (steps != null && steps.isNotEmpty()) {
            var chosen = false
            for ((i, k) in steps.withIndex()) {
                if (!(k > 0)) continue
                // ขั้นต่ำที่อ่านออกขึ้นกับ k — ผลวัดของขั้นก่อนใช้ซ้ำไม่ได้
                scale = k; prepare(root)
                val kb = FSize(box.width / k, box.height / k)
                val need = intrinsic(root, kb.width, null).height
                if (need <= kb.height + 0.5 || i == steps.size - 1) { b = kb; chosen = true; break }
            }
            if (!chosen) { scale = 1.0; prepare(root) }
        }
        layout(root, FRect(0.0, 0.0, b.width, b.height))
    }

    /** ร่องรอยของรอบหนึ่ง: ชิ้นที่หลุดนอกกรอบแม่ · คู่ข้อความที่ทับกัน (ตรงกับ Swift `collisions`) */
    private fun collisions(root: N): Set<String> {
        val out = HashSet<String>()
        val texts = ArrayList<N>()
        fun walk(n: N, parent: N?) {
            if (parent != null) {
                val a = n.frame; val b = parent.frame
                if (a.minX < b.minX - 1 || a.minY < b.minY - 1 || a.maxX > b.maxX + 1 || a.maxY > b.maxY + 1) out.add("out:" + n.id)
            }
            val t = n.text
            if (t != null && t.string.isNotEmpty()) texts.add(n)
            n.children.forEach { walk(it, n) }
        }
        walk(root, null)
        for (i in texts.indices) for (j in i + 1 until texts.size) {
            val a = texts[i].frame; val b = texts[j].frame
            val w = min(a.maxX, b.maxX) - max(a.minX, b.minX)
            val h = min(a.maxY, b.maxY) - max(a.minY, b.minY)
            if (w > 1 && h > 1) out.add("hit:" + texts[i].id + "|" + texts[j].id)
        }
        return out
    }

    private class Drawn(val size: Double, val overflow: Boolean, val target: Double, val image: Boolean = false)

    /** ข้อความทุกชิ้น: ขนาดที่วาดจริงบนการ์ด · ล้นกล่องไหม · ขั้นต่ำของมัน — ไว้เทียบกับรอบผังเดิม */
    private fun texts(n: N, out: HashMap<String, Drawn>) {
        if (n.node.type == SpecType.image || n.node.type == SpecType.icon) {
            // รูป/ไอคอน/QR เป็นเนื้อหาเหมือนกัน — ยกตัวอักษรจนรูปเหลือเป็นเส้นบาง ๆ ไม่คุ้ม
            out[n.id] = Drawn(min(n.frame.width, n.frame.height) * scale * renderScale, false, 0.0, true)
        }
        n.text?.let { t ->
            // ล้นไม่เกิน 30% ของขนาดตัวอักษร = หางสระ/วรรณยุกต์เลยขอบนิดเดียว ตาไม่เห็น · เกินนั้น = ทับของข้าง ๆ
            out[n.id] = Drawn(t.size * scale * renderScale, n.overflow > max(0.5, t.size * 0.3),
                SpecLegibility.target(baseSize(n.base), n.base.role))
        }
        n.children.forEach { texts(it, out) }
    }

    fun solve(): List<SpecBox> {
        val rootNode = selectRoot()
        val root = expand(rootNode, "r", null, 0) ?: return emptyList()
        // ยกตัวอักษรเต็มที่ก่อน · ถ้าไม่มีใครถูกยก = ผังเดิมพอดี
        strength = 1.0
        run(root)
        if (lifted) {
            // รอบผังเดิมเป็นเกณฑ์: รอบที่ยกต้องไม่ทำให้ข้อความไหนเล็กกว่าเดิม (เว้นแต่ยังไม่ต่ำกว่าขั้นต่ำของมัน)
            // และไม่ล้นกล่องที่เดิมไม่ล้น — ไม่ผ่านก็ลดความแรงลงทีละขั้น จนสุดท้ายคือผังเดิม (ตรงกับ Swift)
            strength = 0.0
            run(root)
            val base = HashMap<String, Drawn>()
            texts(root, base)
            val baseHits = collisions(root)
            var ok = false
            for (t in SpecLegibility.STEPS) {
                strength = t
                run(root)
                val now = HashMap<String, Drawn>()
                texts(root, now)
                ok = now.all { (id, v) ->
                    val o = base[id] ?: return@all true
                    if (v.image) v.size >= o.size * SpecLegibility.IMAGE_KEEP - 0.01
                    else v.size >= min(o.size, v.target) - 0.01 && (!v.overflow || o.overflow)
                }
                // ข้อความทับกัน/หลุดกรอบแม่ที่รอบผังเดิมไม่มี = ผังรับไม่ไหว
                if (ok) ok = baseHits.containsAll(collisions(root))
                if (ok) break
            }
            if (!ok) { strength = 0.0; run(root) }
        }
        val out = ArrayList<SpecBox>()
        fun walk(n: N) {
            val f = FRect(r2(n.frame.minX), r2(n.frame.minY), r2(n.frame.width), r2(n.frame.height))
            out.add(SpecBox(n.id, n.node, f, n.text, n.item, n.depth))
            n.children.forEach { walk(it) }
        }
        walk(root)
        return out
    }

    companion object {
        /** ปัด 2 ทศนิยมแบบ Swift `rounded()` (ครึ่งหนึ่งปัดออกจากศูนย์ — ไม่ใช่ half-even ของ `kotlin.math.round`) */
        fun r2(v: Double): Double {
            val s = v * 100
            // `Math.round` (Java 7+) = ครึ่งปัดขึ้นแบบไม่พลาดที่ 0.49999999999999994 อย่าง `floor(s + 0.5)`
            val r = if (s >= 0) Math.round(s).toDouble() else -Math.round(-s).toDouble()
            return r / 100
        }
    }
}
