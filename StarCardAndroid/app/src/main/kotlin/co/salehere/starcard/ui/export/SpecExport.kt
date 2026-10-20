package co.salehere.starcard.ui.export

import android.graphics.Bitmap
import android.os.SystemClock
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.rememberGraphicsLayer
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import co.salehere.starcard.AppContext
import co.salehere.starcard.layout.AndroidSpecMeasurer
import co.salehere.starcard.layout.FSize
import co.salehere.starcard.layout.ReplayData
import co.salehere.starcard.layout.SpecDataSource
import co.salehere.starcard.layout.SpecFont
import co.salehere.starcard.layout.SpecMeasurer
import co.salehere.starcard.layout.SpecSolver
import co.salehere.starcard.model.AndroidSpecData
import co.salehere.starcard.model.CardPage
import co.salehere.starcard.model.CardSnapshot
import co.salehere.starcard.model.CardStore
import co.salehere.starcard.model.KitConfig
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.LocalSpecDataOverride
import co.salehere.starcard.model.PhotoStore
import co.salehere.starcard.model.SpecCatalog
import co.salehere.starcard.model.WidgetInstance
import co.salehere.starcard.model.WidgetKind
import co.salehere.starcard.model.WidgetSpec
import co.salehere.starcard.theme.WidgetTextStyle
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalSampleData
import co.salehere.starcard.ui.widgets.contentInset
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

// MARK: - ส่งออกผัง: พิสูจน์ว่า "ผัง JSON เดียวกัน + ข้อมูลเดียวกัน = ภาพเดียวกัน" (= Views/Export/SpecExport.swift)
//
// 1. เอา fixture ของ iOS ไปวางที่ `filesDir/ios-fixtures/` (สคริปต์ `present/spec-parity/run.sh` ทำให้)
// 2. adb shell am start -S -n co.salehere.starcard/.MainActivity --es exportSpecs 1
// ทุกกรณีของ iOS (กรอบทดสอบ 6 ขนาด + สไตล์ของชุดห้าสไตล์) ถูกวาดซ้ำบน Android ด้วย **ข้อมูลที่ iOS ใช้วาดจริง**
// (เล่นซ้ำจาก fixture) แต่ตัววัดข้อความ · ตัวคำนวณ · ตัววาด · chrome เป็นของ Android ทั้งหมด แล้วเขียนลง `filesDir/Specs/`:
//   cell-<kind>-<probe>.png  — รูป (ความละเอียด ×2 เท่า iOS)
//   fixtures/<kind>.json     — ผลของ `SpecSolver` ฝั่ง Android + ทุกคำถามที่ถามตัววัด (รูปแบบเดียวกับ iOS)
//   data-diff.json           — แหล่งข้อมูลของแอป Android เองตอบต่างจาก iOS ตรงไหน (ข้อมูลโปรไฟล์ — ไม่ใช่เรื่องของผัง)
//   sheet.png                — เขียนเป็นไฟล์สุดท้าย = เครื่องหมายว่าเสร็จ
// adb exec-out run-as co.salehere.starcard tar -C files -cf - Specs | tar -xf - -C <ปลายทาง>

object SpecExport {
    const val folder = "Specs"
    val fixedID: UUID = UUID.fromString("0000000A-0000-4000-8000-000000000001")
    const val margin: Float = 12f
    const val scale: Float = 2f

    val root: File get() = File(AppContext.filesDir, folder)
    /**
     * fixture ของ iOS ที่สคริปต์วางไว้ (ไม่มี = ใช้ข้อมูลของแอปเองล้วน ๆ) — อยู่ใน `filesDir` ของแอป
     * (โฟลเดอร์ที่ `adb push` สร้างใน external storage แอปอ่านไม่ได้ · สคริปต์ส่งผ่าน `run-as` แทน)
     */
    val iosDir: File get() = File(AppContext.filesDir, "ios-fixtures")

    /** กรอบทดสอบ (หน่วยออกแบบ) — ผังเดิม · สูงขึ้น · จัตุรัสเล็ก · จัตุรัสใหญ่ · แถบเตี้ย · แคบสูง (= `SpecExport.probes`) */
    fun probes(spec: WidgetSpec): List<Pair<String, Size>> {
        val w = spec.design.w.toFloat(); val h = spec.design.h.toFloat()
        return listOf(
            "design" to Size(w, h),
            "tall" to Size(w, h * 2),
            "small" to Size(174f, 174f),
            "large" to Size(366f, 366f),
            "strip" to Size(366f, max(60f, h * 0.6f)),
            "narrow" to Size(240f, h * 1.4f),
        )
    }

    // ฟิลด์เรียงตามตัวอักษร = `sortedKeys` ของ JSONEncoder ฝั่ง iOS — diff ไฟล์ตรง ๆ ได้
    @Serializable
    data class FixtureBox(
        val h: Double, val id: String, val lines: Int? = null, val size: Double? = null, val slot: String? = null,
        val text: String? = null, val type: String, val w: Double, val x: Double, val y: Double,
    )

    @Serializable
    data class FixtureMeasure(
        val face: String, val h: Double, val kerning: Double, val lineHeight: Double, val lines: Int, val size: Double,
        val t: String, val tracking: Double, val w: Double, val weight: Int, val width: Double? = null,
    )

    @Serializable
    data class FixtureLine(val face: String, val italic: Boolean, val lineHeight: Double, val size: Double, val v: Double, val weight: Int)

    @Serializable
    data class FixtureCase(
        val box: List<Double>, val boxes: List<FixtureBox>,
        val lineHeights: List<FixtureLine> = emptyList(),
        /** ทุกครั้งที่ตัวคำนวณถามตัววัดข้อความ (ลำดับตามจริง) */
        val measures: List<FixtureMeasure> = emptyList(),
        /** คำถามข้อมูลที่ iOS ไม่เคยถาม (ตัวคำนวณเดินคนละทาง) */
        val misses: List<String> = emptyList(),
        val probe: String,
        val scale: Double = 1.0,
    )

    @Serializable
    data class Fixture(
        val cases: List<FixtureCase>, val design: List<Double>, val inset: Double, val kind: String,
        val rule: String = "s = min(W/w0, H/h0); box = (W/s - 2*inset, H/s - 2*inset); inset = chrome content inset (12 when the chrome draws a plate or border, else 0); boxes below are in box units",
    )

    /** ตัววัดที่จดทุกคำถาม — ค่าที่ตอบมาจาก `AndroidSpecMeasurer` จริง */
    class RecordingMeasurer(private val base: AndroidSpecMeasurer) : SpecMeasurer {
        val log = ArrayList<FixtureMeasure>()
        val lines = ArrayList<FixtureLine>()
        private val seen = HashSet<SpecFont>()
        override fun lineHeight(font: SpecFont): Double {
            val v = base.lineHeight(font)
            if (seen.add(font)) lines.add(FixtureLine(font.face, font.italic, font.lineHeight, font.size, v, font.weight))
            return v
        }
        override fun measure(text: String, font: SpecFont, width: Double?): Pair<FSize, Int> {
            val r = base.measure(text, font, width)
            log.add(FixtureMeasure(
                face = font.face, h = r.first.height, kerning = font.kerning, lineHeight = font.lineHeight,
                lines = r.second, size = font.size, t = text, tracking = font.tracking,
                w = r.first.width, weight = font.weight, width = width,
            ))
            return r
        }
    }

    val json: Json = Json { prettyPrint = true; encodeDefaults = true; explicitNulls = false }
    private val reader = Json { ignoreUnknownKeys = true; isLenient = true }

    fun r2(v: Double): Double = SpecSolver.r2(v)

    /** ชิ้นตั้งต้นของชนิดนี้ที่กรอบ `size` (= `WidgetMatrixExport.baseInstance` + `rect.size`) */
    fun instance(kind: WidgetKind, size: Size): WidgetInstance =
        WidgetInstance.make(kind, x = margin, y = margin, w = size.width, h = size.height, id = fixedID)

    /** งานวาดหนึ่งช่องผ่านโมเดลจริง (`CardSnapshot` → `CardStore.restore`) — เส้นทางเดียวกับ `WidgetMatrixExporter` */
    fun job(index: Int, id: String, w: WidgetInstance): WidgetMatrix.Job? {
        val item = CardStore.snapshot(pages = listOf(CardPage(items = listOf(w))), theme = co.salehere.starcard.theme.CardTheme(), index = 0)
            .pages[0].items[0]
        val r = CardStore.restore(CardSnapshot(pages = listOf(CardSnapshot.Page(items = listOf(item))), theme = WidgetMatrixBase.theme, index = 0))
            ?: return null
        val page = WidgetMatrix.Page(w = w.w + margin * 2, h = w.h + margin * 2, strip = false)
        return WidgetMatrix.Job(index, id, WidgetMatrix.fileName(id), w.kind.raw, page, r.theme, r.pages.first(), pageOnly = false)
    }

    /** fixture ของ iOS หนึ่งชนิด — กรณีตามชื่อ probe (null = ไม่มีไฟล์) */
    fun iosCases(kind: String): Map<String, JsonObject>? {
        val f = File(iosDir, "$kind.json")
        if (!f.isFile) return null
        return runCatching {
            reader.parseToJsonElement(f.readText()).jsonObject["cases"]!!.jsonArray
                .associate { it.jsonObject["probe"]!!.jsonPrimitive.content to it.jsonObject }
        }.getOrNull()
    }

    /** กล่องราก + ผลของ solver ที่กรอบ `probe` (สูตรเดียวใน §2) */
    fun fixtureCase(
        spec: WidgetSpec, kind: WidgetKind, name: String, probe: Size, w: WidgetInstance,
        data: SpecDataSource, base: AndroidSpecMeasurer, designBox: Boolean = false,
    ): FixtureCase {
        val renderScale = if (designBox) 1.0 else min(probe.width / spec.design.w, probe.height / spec.design.h)
        val box: FSize = if (designBox) FSize(spec.design.w, spec.design.h) else {
            val inset = contentInset(kind, w.surface, w.border).toDouble()
            FSize(probe.width / renderScale - inset * 2, probe.height / renderScale - inset * 2)
        }
        val rec = RecordingMeasurer(base)
        val solver = SpecSolver(spec, box, data, rec, renderScale)
        val boxes = solver.solve()
        return FixtureCase(
            probe = name, box = listOf(r2(box.width), r2(box.height)),
            boxes = boxes.map { b ->
                FixtureBox(
                    id = b.id, type = b.node.type.raw,
                    x = r2(b.frame.minX), y = r2(b.frame.minY), w = r2(b.frame.width), h = r2(b.frame.height),
                    text = b.text?.string, size = b.text?.let { r2(it.size) }, lines = b.text?.lines, slot = b.text?.slot,
                )
            },
            measures = rec.log, lineHeights = rec.lines, scale = solver.scale,
            misses = (data as? ReplayData)?.misses?.distinct() ?: emptyList(),
        )
    }
}

/** ธีมของแผ่นทดสอบ (= `WidgetMatrixExport.baseTheme` ของ iOS) */
object WidgetMatrixBase {
    /** midnight โทนมืด (= `Palette.midnight.dark` · `DEFAULT_PRIMARY` ของเว็บ) — doc เก็บ hex ไม่ใช่ชื่อ */
    val theme = CardSnapshot.Theme(
        colors = CardSnapshot.Colors(primary = "#1A1F35"), ink = "night", backdrop = "solid",
    )
}

/** จอของตัวส่งออก — วาดทีละช่องลงเลเยอร์นอกผัง เขียน PNG + fixture แล้วไปช่องถัดไป · จบแล้วเขียน `sheet.png` */
@Composable
fun SpecExporter(onDone: () -> Unit) {
    val photos = remember { PhotoStore() }
    val layer = rememberGraphicsLayer()
    val recorded = remember { IntArray(1) }
    var job by remember { mutableStateOf<WidgetMatrix.Job?>(null) }
    var jobData by remember { mutableStateOf<SpecDataSource?>(null) }
    var status by remember { mutableStateOf("กำลังเตรียม…") }
    val done by rememberUpdatedState(onDone)
    val scale = SpecExport.scale
    val measurer = remember { AndroidSpecMeasurer() }
    val view = LocalView.current
    DisposableEffect(view) {
        view.keepScreenOn = true
        onDispose { view.keepScreenOn = false }
    }

    Box(Modifier.fillMaxSize().background(Color.White)) {
        Text(status, style = sh(14f), color = Color.Black, modifier = Modifier.align(Alignment.Center).padding(24.dp))
        val j = job
        if (j != null) {
            key(j.index) {
                val w = (j.page.w * scale).roundToInt()
                val h = (j.page.h * scale).roundToInt()
                Box(
                    Modifier
                        .layout { measurable, _ ->
                            val p = measurable.measure(Constraints.fixed(w, h))
                            layout(0, 0) { p.place(0, 0) }
                        }
                        .drawWithContent {
                            layer.record { this@drawWithContent.drawContent() }
                            recorded[0] += 1
                        },
                ) {
                    CompositionLocalProvider(
                        LocalDensity provides Density(scale, 1f),
                        LocalPhotoStore provides photos,
                        // = `render(…, sample: true)` ของ iOS — ตู้/แคตตาล็อกวาดใบเต็มด้วยข้อมูลตัวอย่าง
                        LocalSampleData provides true,
                        LocalSpecDataOverride provides jobData,
                    ) {
                        MatrixSheet(j)
                    }
                }
            }
        }
    }

    LaunchedEffect(Unit) {
        val dir = SpecExport.root
        withContext(Dispatchers.IO) {
            dir.deleteRecursively()
            File(dir, "fixtures").mkdirs()
        }
        status = "โหลดรูปตัวอย่าง…"
        runCatching { CardExport.preload() }
        val log = StringBuilder()
        val dataDiff = LinkedHashMap<String, List<String>>()
        val t0 = SystemClock.elapsedRealtime()
        var index = 0
        var kinds = 0

        /** วาด `w` ผ่าน chrome จริงแล้วเขียน PNG */
        suspend fun shoot(id: String, w: WidgetInstance, file: String, data: SpecDataSource?): String {
            val made = SpecExport.job(index, id, w) ?: return "SKIP $id (restore ล้ม)"
            index += 1
            recorded[0] = 0
            jobData = data
            job = made
            val shot = runCatching {
                var frames = 0
                while (recorded[0] == 0 && frames < 120) { withFrameNanos { }; frames++ }
                repeat(2) { withFrameNanos { } }
                delay(40)
                var prev = layer.toImageBitmap().asAndroidBitmap()
                var shots = 1
                while (shots < 6) {
                    repeat(2) { withFrameNanos { } }
                    delay(if (shots == 1) 60L else 250L)
                    val next = layer.toImageBitmap().asAndroidBitmap()
                    shots += 1
                    if (next.sameAs(prev)) { prev = next; break }
                    prev = next
                }
                prev
            }
            val bmp = shot.getOrElse { return "FAIL $id ${it.javaClass.simpleName}: ${it.message}" }
            return withContext(Dispatchers.IO) {
                runCatching {
                    val src = if (bmp.config == Bitmap.Config.ARGB_8888) bmp else bmp.copy(Bitmap.Config.ARGB_8888, false)
                    // ทึบเสมอ (= ImageRenderer.isOpaque) — ส่วนโปร่งถูกปูดำ
                    val opaque = Bitmap.createBitmap(src.width, src.height, Bitmap.Config.ARGB_8888)
                    android.graphics.Canvas(opaque).apply {
                        drawColor(android.graphics.Color.BLACK)
                        drawBitmap(src, 0f, 0f, null)
                    }
                    opaque.setHasAlpha(false)
                    FileOutputStream(File(dir, file)).use { opaque.compress(Bitmap.CompressFormat.PNG, 100, it) }
                    opaque.recycle()
                    "OK   $id ${src.width}x${src.height}"
                }.getOrElse { "FAIL $id write ${it.javaClass.simpleName}: ${it.message}" }
            }
        }

        for (spec in SpecCatalog.all) {
            val kind = WidgetKind.from(spec.kind)
            if (kind == null) { log.append("SKIP ${spec.kind}: Android ไม่รู้จัก kind\n"); continue }
            status = "${spec.kind} (${kinds + 1}/${SpecCatalog.all.size})"
            val ios = SpecExport.iosCases(spec.kind)
            val cases = ArrayList<SpecExport.FixtureCase>()
            val design = Size(spec.design.w.toFloat(), spec.design.h.toFloat())
            // กรณีทั้งหมด: กรอบทดสอบ 6 ขนาด (ห้าหน้าตาของชุดห้าสไตล์เป็นชนิดแยกกันแล้ว — 19 ต.ค. 2569)
            val plan = ArrayList<Triple<String, WidgetInstance, KitConfig?>>()
            for ((name, size) in SpecExport.probes(spec)) plan.add(Triple(name, SpecExport.instance(kind, size), null))
            for ((name, w, cfg) in plan) {
                val own = AndroidSpecData(sample = true, widget = SpecExport.fixedID,
                    kit = cfg ?: KitConfig(), border = cfg?.let { w.border } ?: false, kitDark = spec.widget?.on == "dark")
                val iosCase = ios?.get(name)
                // ข้อมูลที่ iOS ใช้วาดจริง (เล่นซ้ำ) — ไม่มี fixture ก็ใช้ของแอปเอง
                val data: SpecDataSource = iosCase?.let { ReplayData(it["data"]!!.jsonObject, fallback = own) } ?: own
                log.append(shoot("${spec.kind}-$name", w, "cell-${spec.kind}-$name.png", data)).append('\n')
                val size = Size(w.w, w.h)
                cases.add(SpecExport.fixtureCase(spec, kind, name, size, w, data, measurer, designBox = cfg != null))
                if (data is ReplayData) {
                    val d = data.diff(own)
                    if (d.isNotEmpty()) dataDiff["${spec.kind}/$name"] = d
                }
            }
            val base = SpecExport.instance(kind, design)
            val fx = SpecExport.Fixture(
                kind = spec.kind, design = listOf(spec.design.w, spec.design.h),
                inset = contentInset(kind, base.surface, base.border).toDouble(), cases = cases,
            )
            withContext(Dispatchers.IO) {
                runCatching { File(dir, "fixtures/${spec.kind}.json").writeText(SpecExport.json.encodeToString(SpecExport.Fixture.serializer(), fx)) }
                    .onFailure { log.append("FAIL fixture ${spec.kind}: ${it.message}\n") }
            }
            kinds += 1
        }
        job = null
        val total = SystemClock.elapsedRealtime() - t0
        log.append("\n[specs] wrote $kinds kinds · wall ${total / 1000.0} s\n")
        withContext(Dispatchers.IO) {
            runCatching { File(dir, "log.txt").writeText(log.toString()) }
            runCatching { SpacingLab.run(SpecExport.iosDir, File(dir, "spacing-lab.json")) }.onFailure { File(dir, "spacing-lab.err").writeText(it.toString()) }
            runCatching {
                val enc = Json { prettyPrint = true }
                File(dir, "data-diff.json").writeText(enc.encodeToString(
                    kotlinx.serialization.builtins.MapSerializer(
                        kotlinx.serialization.serializer<String>(),
                        kotlinx.serialization.builtins.ListSerializer(kotlinx.serialization.serializer<String>()),
                    ), dataDiff))
            }
            // เครื่องหมายว่าเสร็จ
            runCatching {
                val marker = Bitmap.createBitmap(4, 4, Bitmap.Config.ARGB_8888).apply { eraseColor(android.graphics.Color.WHITE) }
                FileOutputStream(File(dir, "sheet.png")).use { marker.compress(Bitmap.CompressFormat.PNG, 100, it) }
            }
        }
        status = "เสร็จ · $kinds ชนิด · ${total / 1000} วิ"
        done()
    }
}

/**
 * ห้องทดลองระยะตัวอักษร — ทุกการวัดของ iOS ที่มี tracking/kerning: ความกว้างบน Android ตามสูตรต่าง ๆ
 * (ไว้หาว่า CoreText ใส่ระยะยังไง) · เขียน `files/Specs/spacing-lab.json`
 */
object SpacingLab {
    fun run(iosDir: File, out: File) {
        val reader = Json { ignoreUnknownKeys = true; isLenient = true }
        val rows = StringBuilder("[\n")
        val seen = HashSet<String>()
        val m = AndroidSpecMeasurer()
        for (f in iosDir.listFiles { x -> x.extension == "json" && !x.name.startsWith("._") } ?: emptyArray()) {
            val cases = reader.parseToJsonElement(f.readText()).jsonObject["cases"]!!.jsonArray
            for (c in cases) for (e in c.jsonObject["measures"]!!.jsonArray) {
                val o = e.jsonObject
                val tr = o["tracking"]?.jsonPrimitive?.content?.toDoubleOrNull() ?: 0.0
                val ke = o["kerning"]?.jsonPrimitive?.content?.toDoubleOrNull() ?: 0.0
                if (tr == 0.0 && ke == 0.0) continue
                if (o["lines"]!!.jsonPrimitive.content != "1") continue
                val t = o["t"]!!.jsonPrimitive.content
                val face = o["face"]!!.jsonPrimitive.content
                val size = o["size"]!!.jsonPrimitive.content.toDouble()
                val weight = o["weight"]!!.jsonPrimitive.content.toInt()
                val key = "$t|$face|$size|$weight|$tr|$ke"
                if (!seen.add(key)) continue
                val f0 = SpecFont(face, size, weight)
                val withSp = m.paint(f0.copy(tracking = tr, kerning = ke))
                val plain = m.paint(f0)
                val kernOff = android.text.TextPaint(plain).apply { fontFeatureSettings = "'kern' 0" }
                val spKernOff = android.text.TextPaint(withSp).apply { fontFeatureSettings = "'kern' 0" }
                val k = AndroidSpecMeasurer.K
                fun mw(p: android.text.TextPaint) = p.measureText(t).toDouble() / k
                val g = run {
                    val it = android.icu.text.BreakIterator.getCharacterInstance(); it.setText(t)
                    var n = 0; while (it.next() != android.icu.text.BreakIterator.DONE) n++; n
                }
                rows.append("""{"t":${Json.encodeToString(kotlinx.serialization.serializer<String>(), t)},"face":"$face","size":$size,"weight":$weight,"tracking":$tr,"kerning":$ke,""")
                rows.append(""""ios":${o["w"]!!.jsonPrimitive.content},"ls":${mw(withSp)},"plain":${mw(plain)},"plainKernOff":${mw(kernOff)},"lsKernOff":${mw(spKernOff)},"n":${t.length},"cp":${t.codePointCount(0, t.length)},"g":$g},""").append('\n')
            }
        }
        if (rows.endsWith(",\n")) rows.setLength(rows.length - 2)
        rows.append("\n]\n")
        out.writeText(rows.toString())
        // ค่าดิบ (ไม่ปัด) ของคำตัวอย่าง — ใช้ตรวจว่าเศษที่เหลือมาจากไหน
        val raw = StringBuilder()
        for ((t, size, w) in listOf(Triple("01", 10.0, 900), Triple("0", 10.0, 900), Triple("1", 10.0, 900), Triple("ชลบุรี", 13.0, 700), Triple("Tarmjaipa", 9.0, 700))) {
            val p = m.paint(SpecFont("noto", size, w))
            val widths = FloatArray(t.length); p.getTextWidths(t, widths)
            raw.append("$t $size $w measure=${p.measureText(t).toDouble() / AndroidSpecMeasurer.K} widths=${widths.joinToString { (it / AndroidSpecMeasurer.K).toString() }} textSize=${p.textSize}\n")
            for (k in listOf(64.0, 256.0, 4096.0, 16384.0)) {
                val q = android.text.TextPaint(p).apply { textSize = (size * k).toFloat() }
                raw.append("   K=$k measure=${q.measureText(t).toDouble() / k}\n")
            }
        }
        File(out.parentFile, "raw-measure.txt").writeText(raw.toString())
    }
}
