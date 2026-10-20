package co.salehere.starcard

import co.salehere.starcard.layout.FSize
import co.salehere.starcard.layout.ReplayData
import co.salehere.starcard.layout.ReplayMeasurer
import co.salehere.starcard.layout.SpecSolver
import co.salehere.starcard.model.SpecCatalog
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.double
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import kotlin.math.abs

// MARK: - สัญญาข้ามแพลตฟอร์ม: ตัวคำนวณ Kotlin ต้องได้กล่องเท่ากับ iOS ทุกใบ (WIDGET-SPEC.md §7)
//
// `present/spec-fixtures/fixtures/<kind>.json` = ผลของ `SpecSolver` บน iOS ที่กรอบทดสอบทุกขนาด พร้อม
// **ทุกคำถามที่ตัวคำนวณถาม** — ตัววัดข้อความ (`measures` · `lineHeights`) และแหล่งข้อมูล (`data`: ข้อความของช่อง ·
// รายการ · ธง · ฟอนต์ของช่อง) ที่นี่เล่นคำตอบของ iOS ซ้ำทุกข้อ จึงทดสอบ **อัลกอริทึมล้วน ๆ**
// ไม่ขึ้นกับฟอนต์ของ JVM หรือข้อมูลตัวอย่างฝั่ง Android
//
// คำถามที่ iOS ไม่เคยถาม (`miss`) = ตัวคำนวณ Kotlin เดินคนละทางกับ iOS แล้ว — นับเป็นความต่าง ไม่ใช่เดาค่า

class SpecSolverFixtureTest {

    // MARK: เทียบ

    private class KindResult(val kind: String) {
        var cases = 0; var casesOK = 0; var boxes = 0; var boxDiffs = 0
        val diffs = ArrayList<String>()
    }

    private fun repoRoot(): File {
        var dir: File? = File(System.getProperty("user.dir")).absoluteFile
        while (dir != null) {
            if (File(dir, "present/spec-fixtures/fixtures").isDirectory) return dir
            dir = dir.parentFile
        }
        error("repo root with present/spec-fixtures not found above ${System.getProperty("user.dir")}")
    }

    @Test
    fun solverMatchesIOSFixtures() {
        val root = repoRoot()
        val fixtureDir = File(root, "present/spec-fixtures/fixtures")
        val specDir = File(root, "shared/WidgetSpecs")
        val json = Json { ignoreUnknownKeys = true; isLenient = true }
        // ตัวเลขทุกตัวปัด 2 ทศนิยมทั้งสองฝั่ง — ต่างได้แค่เศษปัด (≤ 0.01)
        val tol = System.getProperty("spec.tol")?.toDoubleOrNull() ?: 0.0101
        val results = ArrayList<KindResult>()
        val specs = specDir.listFiles { f -> f.extension == "json" }!!.map { it.nameWithoutExtension }.toSortedSet()
        val fixtures = fixtureDir.listFiles { f -> f.extension == "json" }!!.associateBy { it.nameWithoutExtension }
        assertTrue("no specs found", specs.isNotEmpty())

        for (kind in specs) {
            val res = KindResult(kind); results += res
            // ผังต้องโหลดได้ด้วยตัวอ่านแบบเข้มงวด — คีย์ที่ Kotlin ไม่รู้จัก = Android วาดคำนั้นไม่เป็น
            val spec = try { SpecCatalog.fromJson(File(specDir, "$kind.json").readText()) } catch (e: Exception) {
                res.diffs += "spec decode failed: ${e.message?.lines()?.firstOrNull()?.take(200)}"; continue
            }
            val file = fixtures[kind]
            if (file == null) { res.diffs += "no iOS fixture (re-run -exportSpecs)"; continue }
            val fx = json.parseToJsonElement(file.readText()).jsonObject
            for (case in fx["cases"]!!.jsonArray) {
                val c = case.jsonObject
                res.cases++
                val probe = c["probe"]!!.jsonPrimitive.content
                val box = c["box"]!!.jsonArray.map { it.jsonPrimitive.double }
                val data = ReplayData(c["data"]!!.jsonObject)
                val measurer = ReplayMeasurer(c)
                val renderScale = c["renderScale"]?.jsonPrimitive?.doubleOrNull ?: 1.0
                val solver = SpecSolver(spec, FSize(box[0], box[1]), data, measurer, renderScale)
                val boxes = try { solver.solve() } catch (e: Exception) {
                    res.diffs += "$probe: solver threw ${e::class.simpleName}: ${e.message?.take(120)}"; continue
                }
                var caseDiffs = 0
                fun diff(what: String) { caseDiffs++; res.boxDiffs++; if (res.diffs.size < 8) res.diffs += "$probe $what" }
                for (m in (data.misses + measurer.misses).distinct().take(3)) diff("asked what iOS never asked: $m")
                val exScale = c["scale"]?.jsonPrimitive?.doubleOrNull ?: 1.0
                if (abs(exScale - solver.scale) > 1e-9) diff("fitScale ${solver.scale} ≠ $exScale")
                val got = boxes.associateBy { it.id }
                val expected = c["boxes"]!!.jsonArray.map { it.jsonObject }
                for (b in expected) {
                    res.boxes++
                    val id = b["id"]!!.jsonPrimitive.content
                    val g = got[id]
                    if (g == null) { diff("$id: missing on Kotlin side (expected ${b["type"]!!.jsonPrimitive.content})"); continue }
                    val type = b["type"]!!.jsonPrimitive.content
                    if (g.node.type.name != type) { diff("$id: type ${g.node.type.name} ≠ $type"); continue }
                    val ex = doubleArrayOf(b["x"]!!.jsonPrimitive.double, b["y"]!!.jsonPrimitive.double, b["w"]!!.jsonPrimitive.double, b["h"]!!.jsonPrimitive.double)
                    val gf = doubleArrayOf(g.frame.x, g.frame.y, g.frame.width, g.frame.height)
                    val names = listOf("x", "y", "w", "h")
                    val bad = (0 until 4).filter { abs(ex[it] - gf[it]) > tol }
                    if (bad.isNotEmpty()) { diff("$id: " + bad.joinToString(" ") { "${names[it]} ${fmt(gf[it])}≠${fmt(ex[it])}" }); continue }
                    val exText = b["text"]?.jsonPrimitive?.contentOrNull
                    if (exText != null) {
                        val t = g.text
                        if (t == null) { diff("$id: no text result (expected '${exText.take(30)}')"); continue }
                        val problems = ArrayList<String>()
                        if (t.string != exText) problems += "text '${t.string.take(30)}' ≠ '${exText.take(30)}'"
                        b["size"]?.jsonPrimitive?.doubleOrNull?.let { if (abs(it - t.size) > tol) problems += "size ${fmt(t.size)}≠${fmt(it)}" }
                        b["lines"]?.jsonPrimitive?.int?.let { if (it != t.lines) problems += "lines ${t.lines}≠$it" }
                        if (problems.isNotEmpty()) diff("$id: " + problems.joinToString(" · "))
                    }
                }
                val extra = got.keys - expected.map { it["id"]!!.jsonPrimitive.content }.toSet()
                for (id in extra.sorted()) diff("$id: extra on Kotlin side (${got[id]!!.node.type.name})")
                if (caseDiffs == 0) res.casesOK++
            }
        }

        // MARK: สรุปต่อชนิด
        val sb = StringBuilder()
        sb.append("\n=== SpecSolver fixture conformance (tolerance $tol) ===\n")
        var okKinds = 0
        for (r in results) {
            val ok = r.cases > 0 && r.casesOK == r.cases && r.diffs.isEmpty()
            if (ok) okKinds++
            sb.append(String.format(java.util.Locale.US, "%-18s %s cases %2d/%2d  boxes %5d  diffs %4d\n",
                r.kind, if (ok) "PASS" else "FAIL", r.casesOK, r.cases, r.boxes, r.boxDiffs))
            for (d in r.diffs) sb.append("    $d\n")
        }
        sb.append("=== kinds passing: $okKinds/${results.size} ===\n")
        println(sb)
        File(root, "StarCardAndroid/app/build/spec-fixture-summary.txt").apply { parentFile.mkdirs(); writeText(sb.toString()) }
        assertTrue("$okKinds/${results.size} kinds match the iOS fixtures — see summary above", okKinds == results.size)
    }
}

private fun fmt(v: Double) = String.format(java.util.Locale.US, "%.2f", v)

/**
 * ทุกชื่อไอคอนที่ผังใช้ต้องวาดได้บน Android — ผังใหม่ที่เรียกไอคอนที่ยังไม่มี = ล้มทันที (ไม่ใช่ไปเห็นช่องว่างบนเครื่อง)
 * `ph:<name>` → `Ph` (theme/Ph.kt) หรือ `res/drawable/ph_<name>` · `sh:<name>` → `shIconNamed` · ชื่อพิเศษ → `SpecIcon`
 * ชื่ออื่น → drawable ชื่อเดียวกัน (ขีดกลาง → ขีดล่าง · ตัวเล็ก) · `$field` มาจากข้อมูล (ตรวจตอนส่งออกบนเครื่อง)
 */
class SpecIconCoverageTest {
    @Test
    fun everySpecIconExistsOnAndroid() {
        var dir: File? = File(System.getProperty("user.dir")).absoluteFile
        while (dir != null && !File(dir, "shared/WidgetSpecs").isDirectory) dir = dir.parentFile
        val root = dir ?: error("shared/WidgetSpecs not found")
        val app = File(root, "StarCardAndroid/app/src/main")
        val ph = Regex("""\("([a-z0-9-]+)",""").findAll(File(app, "kotlin/co/salehere/starcard/theme/Ph.kt").readText()).map { it.groupValues[1] }.toSet()
        val drawables = listOf("drawable", "drawable-nodpi").flatMap { File(app, "res/$it").list()?.toList() ?: emptyList() }
            .map { it.substringBeforeLast('.') }.toSet()
        val special = Regex("""^\s*"([^"]+)"(?:,\s*"([^"]+)")*\s*->""", RegexOption.MULTILINE)
            .findAll(File(app, "kotlin/co/salehere/starcard/ui/widgets/SpecIcons.kt").readText())
            .flatMap { m -> Regex("\"([^\"]+)\"").findAll(m.value.substringBefore("->")).map { it.groupValues[1] } }.toSet()
        val sh = setOf("instagram", "tiktok", "youtube", "facebook", "x", "lemon8", "sealCheck", "verifiedPill", "star", "wordmark", "watermark", "qr")
        val json = Json { ignoreUnknownKeys = true }
        val missing = sortedSetOf<String>()
        fun walk(e: kotlinx.serialization.json.JsonElement, kind: String) {
            when (e) {
                is kotlinx.serialization.json.JsonObject -> {
                    e["icon"]?.let { v ->
                        val name = (v as? kotlinx.serialization.json.JsonPrimitive)?.contentOrNull ?: return@let
                        val ok = when {
                            name.startsWith("$") -> true
                            name in special -> true
                            name.startsWith("ph:") -> name.drop(3).removeSuffix("-fill") in ph || "ph_" + name.drop(3).replace('-', '_') in drawables
                            name.startsWith("sh:") -> name.drop(3) in sh || name.drop(3).replace('-', '_').lowercase() in drawables
                            name.startsWith("url:") || name.startsWith("http") -> true
                            else -> name.replace('-', '_').lowercase() in drawables
                        }
                        if (!ok) missing += "$kind: $name"
                    }
                    e.values.forEach { walk(it, kind) }
                }
                is kotlinx.serialization.json.JsonArray -> e.forEach { walk(it, kind) }
                else -> Unit
            }
        }
        for (f in File(root, "shared/WidgetSpecs").listFiles { x -> x.extension == "json" }!!) walk(json.parseToJsonElement(f.readText()), f.nameWithoutExtension)
        assertTrue("icons Android cannot draw:\n" + missing.joinToString("\n"), missing.isEmpty())
    }
}

