package co.salehere.starcard.model

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonEncoder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonPrimitive
import kotlin.math.abs

// ผังของ widget เป็นข้อมูล (= Model/WidgetSpec.swift)
//
// กติกา: **ผัง = ไฟล์ JSON หนึ่งไฟล์ต่อชนิด** · ตัวคำนวณกล่อง (`SpecSolver`) เป็นอัลกอริทึมเดียวที่ทุกแพลตฟอร์ม
// ต้อง port ให้ตรงด้วย fixture · ตัววาดรู้จักของไม่กี่อย่างและไม่ตัดสินใจอะไรเอง
//
// ไฟล์นี้ต้องเป็น Kotlin ล้วน (ไม่มี Android/Compose) — รันใน JVM unit test ได้

/** แผนผังของ widget หนึ่งชนิด — ไฟล์ `WidgetSpecs/<kind>.json` */
@Serializable
data class WidgetSpec(
    /** ชนิด (ตรงกับ `WidgetKind.name`) */
    val kind: String,
    /** ขนาดอ้างอิงของผัง — กรอบที่ดีไซน์วาดไว้ */
    val design: SpecSize,
    /** ผังราก */
    val root: SpecNode,
    /** หมายเหตุของผู้แปลง (ไม่ใช้ตอนวาด) */
    val notes: String? = null,
    /** ผังทางเลือกตามรูปทรงกรอบ — เลือกใบแรกที่เงื่อนไขเป็นจริง ไม่มีก็ใช้ `root` */
    val variants: List<SpecVariant>? = null,
    /** ย่อทั้งก้อนเมื่อเนื้อหาสูงเกินกรอบ — ลองทีละขั้น (`[1, 0.9, 0.8 …]`) ใช้ขั้นแรกที่ความสูงตามเนื้อหาพอดี
     *  (ไม่พอดีสักขั้น = ขั้นสุดท้าย) · ตัววาดย่อทั้งก้อนด้วยค่านั้น */
    val fitScale: List<Double>? = null,
    /** ใบใหม่จากไฟล์ผังอย่างเดียว (ไม่มีในโค้ด) — มีบล็อกนี้ = ขึ้นในตู้ · ชนิดในแอปไม่ต้องใส่ (ใส่ก็ไม่อ่าน) */
    val widget: Widget? = null,
) {
    /**
     * นิสัยของ widget ทั้งหมด (= `WidgetSpec.Widget` ของ iOS · WIDGET-SPEC.md §1.5) — แอปไม่มีตารางชื่อ widget ในโค้ด
     * ทุกคีย์ไม่บังคับยกเว้น `title` · ไม่ใส่ = ค่าของหมวด (`WidgetFamily`) หรือกติกากลางของคีย์นั้น
     */
    @Serializable
    data class Widget(
        /** ชื่อในตู้ */
        val title: String,
        /** หมวด = ชื่อ `WidgetFamily` — ไม่ใส่/ไม่รู้จัก = ใบนี้ไม่ขึ้นในแอป */
        val category: String? = null,
        /** SF Symbol ในตู้/แถบ */
        val symbol: String? = null,
        /** ขนาดตอนวางลงการ์ด · ไม่ใส่ = `design` */
        val size: SpecSize? = null,
        /** ลำดับในตู้ */
        val order: Int? = null,
        /** `verified` · `connected` · `personal` — ไม่ใส่ = ของหมวด */
        val tier: String? = null,
        /** วาดพื้นของตัวเอง */
        val ownSurface: Boolean? = null,
        /** วาดเส้นขอบของตัวเอง */
        val ownBorder: Boolean? = null,
        /** ตัวเลือกพื้นผิวในถาด (ตัวแรก = ตั้งต้น) */
        val surfaces: List<String>? = null,
        /** ชื่อตัวเลือกพื้นผิวที่ต่างจากชื่อกลาง */
        val surfaceNames: Map<String, String>? = null,
        /** เส้นขอบตั้งต้น */
        val border: Boolean? = null,
        val photo: Boolean? = null,
        val keepAspect: Boolean? = null,
        val fullBleed: Boolean? = null,
        val resize: Boolean? = null,
        /** **ตัวเลือกทั้งหมดที่ผู้ใช้ปรับได้ในถาด** — ค่าที่เลือกเก็บที่ `WidgetInstance.options[opt]` (19 ต.ค. 2569) */
        val controls: List<KitControl>? = null,
        /** ชุดห้าสไตล์ — หน้าตาของใบ (`look`) */
        val kit: Kit? = null,
        /** วัสดุแผ่นสติกเกอร์ `paper` · `glass` */
        val skin: String? = null,
        /** ป้าย Verified by Sale Here — `followers` · `insight` · `work` */
        val stamp: String? = null,
        /** ใบที่ไม่มีช่องหัวข้อ — chrome วางป้ายมุมขวาบนด้านใน */
        val stampAt: StampAt? = null,
        /** ท่าเข้า `deep` · `mid` · `light` · `anchored` */
        val motion: String? = null,
        /** Sale Here วางให้ทุกการ์ด ตรึงก้นหน้า */
        val pinned: Boolean? = null,
        /** ชื่อชนิดเก่าที่ถอดแล้ว — การ์ดเก่าที่มีชื่อพวกนี้เปิดมาเป็นใบนี้ */
        val replaces: List<String>? = null,
    ) {
        @Serializable
        data class StampAt(val tone: String, val top: Double, val trailing: Double)

        @Serializable
        /** `look` = หน้าตาของใบ (`purple` `cream` `gingham` `night` `mac`) — หนึ่งหน้าตา = หนึ่งชนิด (19 ต.ค. 2569) */
        data class Kit(val look: String? = null)
    }
}

/**
 * ตัวเลือกหนึ่งแถวในถาด (`widget.controls` · = `KitControl` ของ iOS) — ค่าเก็บที่ `WidgetInstance.options[opt]`
 * `items` = ชื่อแหล่งข้อมูลของหมวด (string) หรือคู่ `[key, ชื่อ]` · `default` = bool หรือตัวเลข
 */
@Serializable
data class KitControl(
    val type: String,
    val label: String,
    val opt: String? = null,
    val items: kotlinx.serialization.json.JsonElement? = null,
    val options: List<List<String?>>? = null,
    val clears: List<String>? = null,
    val values: List<Int>? = null,
    val default: kotlinx.serialization.json.JsonElement? = null,
    val flags: Map<String, String>? = null,
    @kotlinx.serialization.SerialName("if") val condition: String? = null,
    val refit: Boolean? = null,
    val minItems: Int? = null,
)

@Serializable
data class SpecSize(val w: Double, val h: Double)

/** ผังทางเลือก — `{"when": "ratio<0.6", "root": …}` · หรือ `{"when": "cfg:style=mac", …}` */
@Serializable
data class SpecVariant(
    /** เงื่อนไขบนกรอบ (`ratio<0.6` · `w<260`) หรือเงื่อนไขข้อมูลแบบเดียวกับ `if` · คั่นด้วย `&` */
    val `when`: String,
    val root: SpecNode,
)

/** ชนิดของโหนด — รายการปิด ทุกแพลตฟอร์มต้องรู้จักครบ */
@Serializable
enum class SpecType {
    col, row, stack, text, image, rect, icon, chips, spacer, line;
    val raw: String get() = name
}

/** ความยาวของกล่อง — ตัวเลข · `"72%"` · `"fill"` · `"hug"` */
@Serializable(with = SpecLengthSerializer::class)
sealed class SpecLength {
    data class Pt(val v: Double) : SpecLength()
    data class Pct(val v: Double) : SpecLength()
    object Fill : SpecLength() { override fun toString() = "fill" }
    object Hug : SpecLength() { override fun toString() = "hug" }
}

object SpecLengthSerializer : KSerializer<SpecLength> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("SpecLength", PrimitiveKind.STRING)
    override fun deserialize(decoder: Decoder): SpecLength {
        val jd = decoder as JsonDecoder
        val p = jd.decodeJsonElement().jsonPrimitive
        if (!p.isString) p.doubleOrNull?.let { return SpecLength.Pt(it) }
        val s = p.content
        return when (s) {
            "fill" -> SpecLength.Fill
            "hug" -> SpecLength.Hug
            else -> {
                if (s.endsWith("%")) s.dropLast(1).toDoubleOrNull()?.let { SpecLength.Pct(it) }
                    ?: throw IllegalArgumentException("bad length $s")
                else s.toDoubleOrNull()?.let { SpecLength.Pt(it) } ?: throw IllegalArgumentException("bad length $s")
            }
        }
    }
    override fun serialize(encoder: Encoder, value: SpecLength) {
        val je = encoder as JsonEncoder
        je.encodeJsonElement(when (value) {
            is SpecLength.Pt -> JsonPrimitive(value.v)
            is SpecLength.Pct -> JsonPrimitive("${value.v}%")
            SpecLength.Fill -> JsonPrimitive("fill")
            SpecLength.Hug -> JsonPrimitive("hug")
        })
    }
}

/** ระยะขอบใน — `8` · `[v, h]` · `[t, r, b, l]` */
@Serializable(with = SpecInsetsSerializer::class)
data class SpecInsets(val top: Double = 0.0, val right: Double = 0.0, val bottom: Double = 0.0, val left: Double = 0.0) {
    val h: Double get() = left + right
    val v: Double get() = top + bottom
}

object SpecInsetsSerializer : KSerializer<SpecInsets> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("SpecInsets", PrimitiveKind.STRING)
    override fun deserialize(decoder: Decoder): SpecInsets {
        val jd = decoder as JsonDecoder
        val e = jd.decodeJsonElement()
        if (e is JsonPrimitive) { val d = e.doubleOrNull ?: throw IllegalArgumentException("bad pad"); return SpecInsets(d, d, d, d) }
        val a = e.jsonArray.map { it.jsonPrimitive.doubleOrNull ?: throw IllegalArgumentException("bad pad") }
        return when (a.size) {
            1 -> SpecInsets(a[0], a[0], a[0], a[0])
            2 -> SpecInsets(a[0], a[1], a[0], a[1])
            4 -> SpecInsets(a[0], a[1], a[2], a[3])
            else -> throw IllegalArgumentException("pad needs 1, 2 or 4 numbers")
        }
    }
    override fun serialize(encoder: Encoder, value: SpecInsets) {
        val je = encoder as JsonEncoder
        if (value.top == value.right && value.right == value.bottom && value.bottom == value.left) je.encodeJsonElement(JsonPrimitive(value.top))
        else je.encodeJsonElement(JsonArray(listOf(value.top, value.right, value.bottom, value.left).map { JsonPrimitive(it) }))
    }
}

/** การจัดในแกนขวาง (cross axis) */
@Serializable
enum class SpecAlign { start, center, end, stretch }

/** การจัดในแกนหลัก (main axis) */
@Serializable
enum class SpecJustify { start, center, end, between, around }

/** เส้นขอบ — `{"color": "line@0.16", "width": 0.6, "dash": [3, 2]}` (width ตั้งต้น 1) */
@Serializable
data class SpecStroke(val color: String, val width: Double = 1.0, val dash: List<Double>? = null)

/** เงา — ระบุเป็น sigma · x/y ตั้งต้น 0 · สีตั้งต้น black@0.25 */
@Serializable
data class SpecShadow(val sigma: Double, val y: Double = 0.0, val x: Double = 0.0, val color: String = "black@0.25")

/** ไล่สี — `{"from": "accent", "to": "accent@0", "angle": 90}` (angle ตั้งต้น 90) */
@Serializable
data class SpecGradient(val from: String, val to: String, val angle: Double = 90.0)

/** ลายพื้น — รายการปิด: `gingham` `stripes` `lines` `dots` `grid` `sprockets` `rings` `speckle` `barcode` `guilloche` */
@Serializable
data class SpecPattern(
    val kind: String,
    val color: String = "ink@0.12",
    val color2: String? = null,
    val size: Double? = null,
    val width: Double? = null,
    val angle: Double? = null,
    val opacity: Double? = null,
)

/** เงื่อนไขเปลี่ยนขนาดตัวอักษรตามความกว้างของ **กล่องราก** — ใบแรกที่จริงชนะ */
@Serializable
data class SpecSizeRule(val `when`: String, val size: Double)

/** โหนดหนึ่งตัวในผัง — ฟิลด์ทั้งหมดเป็น optional · ค่าว่าง = ค่าตั้งต้นตามชนิด */
@Serializable
data class SpecNode(
    val type: SpecType,
    val id: String? = null,

    // กล่อง
    val w: SpecLength? = null,
    val h: SpecLength? = null,
    val grow: Double? = null,
    val shrink: Double? = null,
    val minW: Double? = null, val maxW: Double? = null, val minH: Double? = null, val maxH: Double? = null,
    val aspect: Double? = null,
    val pad: SpecInsets? = null,
    val gap: Double? = null,
    val align: SpecAlign? = null,
    val alignSelf: SpecAlign? = null,
    val justify: SpecJustify? = null,
    val wrap: Boolean? = null,
    val place: String? = null,
    val dx: Double? = null, val dy: Double? = null,
    val rotate: Double? = null,
    val rotateCycle: List<Double>? = null,
    val pct: String? = null,

    // การทา
    val fill: String? = null,
    val fillCycle: List<String>? = null,
    val gradient: SpecGradient? = null,
    val radius: Double? = null,
    val circle: Boolean? = null,
    val stroke: SpecStroke? = null,
    val opacity: Double? = null,
    val shadow: SpecShadow? = null,
    val clip: Boolean? = null,
    val pattern: SpecPattern? = null,
    /** ลายของแผ่นที่ผู้ใช้เลือกในถาด — ค่าคือ token สีของแผ่นที่ลายนั่งอยู่ · ตัดตามรูปร่างของกล่อง */
    val platePattern: String? = null,
    val shape: String? = null,

    // ข้อความ
    val slot: String? = null,
    val text: String? = null,
    val preset: String? = null,
    val face: String? = null,
    val size: Double? = null,
    val weight: Int? = null,
    val maxLines: Int? = null,
    val shrinkTo: Double? = null,
    val growTo: Double? = null,
    /** บทบาทต่อขั้นต่ำที่อ่านออก: "title" · "content" · "deco" (ไม่มีขั้นต่ำ) · ไม่ใส่ = ขนาด ≥ 18 เป็นหัว */
    val role: String? = null,
    val tracking: Double? = null,
    val kerning: Double? = null,
    val lineHeight: Double? = null,
    val textCase: String? = null,
    val color: String? = null,
    val textAlign: String? = null,
    val italic: Boolean? = null,
    /** พาดหัวสองเสียง — คำแรกตามฟอนต์ของโหนด ที่เหลือเซริฟเอียง (กติกาโปสเตอร์ "MY *Social*") */
    val mixHead: Boolean? = null,
    val sizeWhen: List<SpecSizeRule>? = null,

    // รูป
    val photo: Int? = null,
    /** ช่องรูปจากฟิลด์ของรายการ — `"$workPhoto"` (ชนะ `photo`) */
    val photoRef: String? = null,
    /** รูปจาก asset ของแอป/URL — `"$cover"` · ว่างแล้วกลับไปใช้ช่องรูป */
    val src: String? = null,
    val fit: String? = null,
    val mono: Boolean? = null,

    // ไอคอน
    val icon: String? = null,
    val tint: String? = null,

    // รายการ
    val list: String? = null,
    val each: SpecNode? = null,
    val limit: Int? = null,
    val sort: String? = null,
    val direction: String? = null,
    /** เก็บชิ้นแรกของแต่ละค่าของฟิลด์นี้ (หลัง `sort`) — `"group": "platform"` = แถวละหนึ่งช่องทาง */
    val group: String? = null,
    @SerialName("where") val where: String? = null,

    // เงื่อนไข — คีย์ JSON `if`
    @SerialName("if") val cond: String? = null,

    val children: List<SpecNode>? = null,
)

// แคตตาล็อก — ผังทุกชนิดที่แอปถืออยู่ · การโหลดจาก assets อยู่ที่อื่น (`register`/`load`)
object SpecCatalog {
    /**
     * **เข้มงวด** — คีย์ที่โมเดลนี้ไม่รู้จักทำให้โหลดไม่ผ่าน (ไม่ข้ามเงียบ ๆ)
     * ผังใช้คำใหม่ที่ Android ยังวาดไม่เป็น = ต้องรู้ทันทีตอนเทสต์ ไม่ใช่ไปเห็นภาพเพี้ยนบนเครื่อง
     */
    val json: Json = Json { ignoreUnknownKeys = false; isLenient = true }
    private val cache = LinkedHashMap<String, WidgetSpec>()

    /** แปลง JSON หนึ่งไฟล์เป็นผัง */
    fun fromJson(text: String): WidgetSpec = json.decodeFromString(WidgetSpec.serializer(), text)

    /** โหลดจากข้อความ JSON แล้วเก็บเข้าแคตตาล็อก */
    fun load(json: String): WidgetSpec = fromJson(json).also { register(it) }

    fun register(spec: WidgetSpec) { cache[spec.kind] = spec; generation++ }

    /** รุ่นของผังทั้งชุด — เพิ่มทุกครั้งที่ผังเปลี่ยน · `WidgetKind.entries` จำลำดับตู้ไว้ต่อรุ่น */
    var generation = 0
        private set

    /** โหมดลองทำ: แทนผังทั้งชุดด้วยไฟล์ที่ดึงจาก API — ไฟล์ที่อ่านไม่ผ่านถูกข้าม · คืนจำนวนที่อ่านได้ (0 = คงชุดเดิม) */
    fun replace(texts: List<String>): Int {
        val out = LinkedHashMap<String, WidgetSpec>()
        for (t in texts) {
            runCatching { fromJson(t) }.onSuccess { out[it.kind] = it }.onFailure { println("SpecCatalog spec (API): ${it.message}") }
        }
        if (out.isNotEmpty()) { cache.clear(); cache.putAll(out); generation++ }
        return out.size
    }

    fun spec(kind: WidgetKind): WidgetSpec? = cache[kind.name]
    fun spec(named: String): WidgetSpec? = cache[named]

    /** ชนิดที่มีบล็อก `widget` และหมวดที่แอปรู้จัก เรียงตามชื่อ — `WidgetKind.entries` เรียงตาม `order` อีกชั้น */
    val widgetKinds: List<String>
        get() = cache.values
            .filter { sp -> val w = sp.widget; w != null && WidgetFamily.entries.any { it.name == w.category } }
            .map { it.kind }
            .sorted()

    fun widgetMeta(kind: String): WidgetSpec.Widget? = cache[kind]?.widget

    /** ชนิดที่ประกาศว่าแทนชื่อเก่านี้ (`widget.replaces`) */
    fun replacement(old: String): String? = cache.values.firstOrNull { it.widget?.replaces?.contains(old) == true }?.kind

    /** ชื่อเก่าที่แตกเป็นหลายชนิดตามหน้าตา (ชุดห้าสไตล์ก่อน 19 ต.ค. 2569) — เลือกใบที่ `widget.kit.look` ตรงกับที่ชิ้นเคยเก็บ */
    fun replacement(old: String, look: String?): String? {
        val all = cache.values.filter { it.widget?.replaces?.contains(old) == true }
        return (all.firstOrNull { it.widget?.kit?.look == look }
            ?: all.sortedBy { it.kind }.firstOrNull { it.widget?.kit?.look == null }
            ?: all.firstOrNull())?.kind
    }
    val all: List<WidgetSpec> get() = cache.values.sortedBy { it.kind }

    /** ผังที่ใช้กับกรอบนี้ — ผังทางเลือกใบแรกที่เงื่อนไขจริง ไม่มีก็ราก */
    fun root(of: WidgetSpec, boxW: Double, boxH: Double): SpecNode {
        for (v in of.variants ?: emptyList()) if (SpecCondition.box(v.`when`, boxW, boxH)) return v.root
        return of.root
    }
}

// เงื่อนไขบนกรอบ
object SpecCondition {
    /** `w<260` · `h>=120` · `ratio<0.6` (ratio = h/w) — หลายเงื่อนไขคั่นด้วย `&` */
    fun box(expr: String, w: Double, h: Double): Boolean {
        for (part in expr.split("&")) {
            val e = part.trim()
            val (key, op, v) = parse(e) ?: return false
            val lhs: Double = when (key) {
                "w" -> w
                "h" -> h
                "ratio" -> if (w > 0) h / w else 0.0
                else -> return false
            }
            if (!compare(lhs, op, v)) return false
        }
        return true
    }

    private fun parse(e: String): Triple<String, String, Double>? {
        for (op in listOf("<=", ">=", "<", ">", "=")) {
            val i = e.indexOf(op)
            if (i >= 0) {
                val k = e.substring(0, i).trim()
                val v = e.substring(i + op.length).trim()
                val d = v.toDoubleOrNull() ?: return null
                return Triple(k, op, d)
            }
        }
        return null
    }

    private fun compare(a: Double, op: String, b: Double): Boolean = when (op) {
        "<" -> a < b
        "<=" -> a <= b
        ">" -> a > b
        ">=" -> a >= b
        else -> abs(a - b) < 0.001
    }
}
