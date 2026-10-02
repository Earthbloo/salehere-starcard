package co.salehere.starcard.ui.export

import android.content.Context
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.os.SystemClock
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.offset
import androidx.compose.ui.draw.clipToBounds
import co.salehere.starcard.model.CardFormat
import co.salehere.starcard.model.Portfolio
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.WidgetFamily
import co.salehere.starcard.model.WidgetKind
import co.salehere.starcard.model.isEmpty
import co.salehere.starcard.ui.widgets.WidgetChrome
import androidx.compose.foundation.layout.size
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
import co.salehere.starcard.layout.PageLayout
import co.salehere.starcard.model.CardPage
import co.salehere.starcard.model.CardSnapshot
import co.salehere.starcard.model.CardStore
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.PhotoStore
import co.salehere.starcard.theme.CardBackdrop
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.SignatureEmboss
import co.salehere.starcard.theme.StripStyle
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.LocalPageContentWidth
import co.salehere.starcard.ui.LocalPreviewStatic
import co.salehere.starcard.ui.LocalTextEditMode
import co.salehere.starcard.ui.editor.LocalSlotRegistry
import java.io.File
import java.io.FileOutputStream
import kotlin.math.roundToInt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job as CoJob
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.floatOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

// MARK: - ตารางวิดเจ็ต (DEBUG) — วาดทุก widget ทุกตัวเลือกเป็น PNG ไว้เทียบกับ iOS ทีละพิกเซล
//
// สัญญาคือไฟล์ `matrix.json` ที่ฝั่ง iOS เขียน — Android วาด config ชุดเดียวกันด้วยโมเดลจริง
// (`CardSnapshot` → `CardStore.restore`) และเส้นทางวาดจริง (`CardBackdrop` + `CardPageCanvas` + `SignatureEmboss`
// ลำดับเดียวกับ `CardFramePreview`) ที่ความหนาแน่น 2 เท่าคงที่ ไม่ขึ้นกับเครื่อง
//
// adb push matrix.json /data/local/tmp/sc-matrix.json
// adb shell run-as co.salehere.starcard sh -c 'mkdir -p cache/matrix && cp /data/local/tmp/sc-matrix.json cache/matrix/matrix.json'
// adb shell am start -S -n co.salehere.starcard/.MainActivity --es exportWidgetMatrix 1
// adb exec-out run-as co.salehere.starcard tar -C cache/matrix -cf - android | tar -xf - -C <ปลายทาง>
// อ่าน `cacheDir/matrix/matrix.json` · เขียน `cacheDir/matrix/android/<id>.png` + `log.txt`

object WidgetMatrix {
    /** ใช้ได้เฉพาะแอปที่ debuggable — ปุ่มนี้ไม่มีทางถูกเรียกในแอปที่ปล่อยจริง */
    fun enabled(context: Context): Boolean = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    /** อยู่ใน cacheDir — นอกของที่โหมดลองทำสำรอง/คืน · adb เข้าถึงผ่าน `run-as` */
    val root: File get() = File(AppContext.app.cacheDir, "matrix")
    val input: File get() = File(root, "matrix.json")
    val output: File get() = File(root, "android")

    /** `LocalPageContentWidth` ของทุก config widget — ความกว้างเนื้อหาของหน้าสตอรี่ (540 − 18 × 2) เท่า iOS */
    val contentWidth: Float get() = PageLayout.content(Size(540f, 960f)).width

    @Serializable
    data class Page(val w: Float, val h: Float, val strip: Boolean = true)

    /** หนึ่งช่องของตาราง — `item` ว่าง (kind `_page`) = วาดหน้าเปล่าทั้งแผ่น */
    class Job(
        val index: Int,
        val id: String,
        val file: String,
        val kind: String,
        val page: Page,
        val theme: CardTheme,
        val cardPage: CardPage,
        val pageOnly: Boolean,
    )

    /** ชื่อไฟล์ = id ตรงตัว (ตัวเทียบอ่าน `<id>.png`) — มีแค่ `/` ที่อยู่ในชื่อไฟล์ไม่ได้ */
    fun fileName(id: String): String = id.replace('/', '_').replace('\u0000', '_')

    /**
     * config หนึ่งช่อง → งานวาด ผ่านโมเดลจริงทั้งคู่ (`CardSnapshot` ของ Android + `CardStore.restore`)
     * คืนข้อความเหตุผลเมื่อทำไม่ได้ (kind ที่ Android ไม่รู้จัก, JSON อ่านไม่ออก)
     */
    fun job(index: Int, raw: JsonElement): Pair<Job?, String?> {
        val o = raw as? JsonObject ?: return null to "config #$index ไม่ใช่ object"
        val id = o["id"]?.jsonPrimitive?.contentOrNull ?: "config-$index"
        val kind = o["kind"]?.jsonPrimitive?.contentOrNull ?: "?"
        return runCatching {
            val json = CardStore.json
            val page = json.decodeFromJsonElement(Page.serializer(), o.getValue("page"))
            val theme = json.decodeFromJsonElement(CardSnapshot.Theme.serializer(), o.getValue("theme"))
            val itemJson = o["item"]?.takeIf { it !is JsonNull }
            val pageOnly = kind == "_page" || itemJson == null
            val size = Size(page.w, page.h)
            if (pageOnly) {
                // หน้าเปล่า — `restore` คืน null เมื่อไม่มีชิ้นเลย จึงยืมชิ้นหนึ่งไปกู้ธีม แล้ววาดหน้าเปล่า
                val probe = CardSnapshot.Item(kind = "textBlock", x = 0.0, y = 0.0, w = 100.0, h = 40.0, surface = "glass", border = false)
                val r = CardStore.restore(CardSnapshot(pages = listOf(CardSnapshot.Page(listOf(probe))), theme = theme, index = 0))
                    ?: error("กู้ธีมไม่ได้")
                Job(index, id, fileName(id), kind, page, r.theme, CardPage(), pageOnly = true) to null
            } else {
                val item = json.decodeFromJsonElement(CardSnapshot.Item.serializer(), itemJson!!)
                val r = CardStore.restore(CardSnapshot(pages = listOf(CardSnapshot.Page(listOf(item))), theme = theme, index = 0))
                    ?: return@runCatching null to "ข้าม: Android ไม่รู้จัก kind \"${item.kind}\" (WidgetKind.decode = null)"
                if (size.width <= 0f || size.height <= 0f) return@runCatching null to "ข้าม: page ขนาด 0"
                Job(index, id, fileName(id), kind, page, r.theme, r.pages.first(), pageOnly = false) to null
            }
        }.getOrElse { null to "อ่าน config ไม่ได้: ${it.javaClass.simpleName}: ${it.message}" }
    }
}

/**
 * หน้าหนึ่งแผ่นของตาราง (= `MatrixWidgetPage` / `CardSheet` ของ iOS)
 * - widget: ฉากหลังจริง (`signed = page.strip` — ของ widget เป็น false เสมอ) + `WidgetChrome` จริง วางแบบ `CardPageCanvas`
 *   แต่ `LocalPageContentWidth` ตรึงที่หน้าสตอรี่ (540×960) ตามกติกาใน matrix.json — `CardPageCanvas` ตั้งค่านี้ทับเอง จึงไม่ใช้ตัวนั้น
 * - หน้าเปล่า (`_page`): `CardSheet(format = story)` ตัวจริง — เซ็นมุม + ตราปั๊มตาม `theme.strip`
 * ไม่ย่อ ไม่มีมุมมน ไม่มีเส้นขอบของพรีวิว
 */
@Composable
private fun MatrixSheet(job: WidgetMatrix.Job) {
    val theme = job.theme
    val size = Size(job.page.w, job.page.h)
    CompositionLocalProvider(
        LocalCardInk provides theme.inkStyle,
        LocalPreviewStatic provides true,
        LocalTextEditMode provides false,
        LocalSlotRegistry provides null,
    ) {
        if (job.pageOnly) {
            CardSheet(pages = listOf(CardPage()), theme = theme, pageSize = size, format = CardFormat.story)
            return@CompositionLocalProvider
        }
        val solved = remember(job.cardPage.items, size) { PageLayout.solve(job.cardPage.items, size) }
        Box(Modifier.size(size.width.dp, size.height.dp).clipToBounds()) {
            CardBackdrop(theme = theme, ignoreSafeArea = false, signed = job.page.strip)
            CompositionLocalProvider(LocalPageContentWidth provides WidgetMatrix.contentWidth) {
                Box(Modifier.size(size.width.dp, size.height.dp)) {
                    for (p in solved) {
                        key(p.id) {
                            WidgetChrome(placed = p, theme = theme, modifier = Modifier.offset(p.frame.left.dp, p.frame.top.dp))
                        }
                    }
                }
            }
            if (job.page.strip && theme.strip.isStamp) {
                SignatureEmboss(
                    light = theme.inkStyle.isLight, foil = theme.strip == StripStyle.foil, tint = theme.inkStyle.base,
                    pages = listOf(job.cardPage), pageSize = size,
                )
            }
        }
    }
}

/** ของที่ widget จะขึ้น `SystemPending` แทนดีไซน์เพราะข้อมูลบนเครื่องว่าง (= `pendingNote` ของ iOS) */
private fun pendingNote(kind: WidgetKind): String? {
    val c = Profile.me.creator
    val sample = Profile.me.sampleFamilies
    return when (kind.family) {
        WidgetFamily.brand -> if (c.track.brands.isEmpty()) "SystemPending (no brands)" else null
        WidgetFamily.verified -> if (c.track.works.isEmpty()) "SystemPending (no works)" else null
        WidgetFamily.audience -> if (c.audience.isEmpty) "SystemPending (no audience)" else null
        WidgetFamily.followers -> if (WidgetFamily.followers in sample) "SystemPending (followers are sample)" else null
        WidgetFamily.rate -> if (WidgetFamily.rate in sample) "SystemPending (rates are sample)" else null
        else -> null
    }
}

/** จอของตัวส่งออก — วาดทีละช่องลงเลเยอร์นอกผัง เขียน PNG แล้วไปช่องถัดไป · จบแล้วเรียก `onDone` */
@Composable
fun WidgetMatrixExporter(onDone: () -> Unit) {
    val photos = remember { PhotoStore() }
    val layer = rememberGraphicsLayer()
    val recorded = remember { IntArray(1) }
    var job by remember { mutableStateOf<WidgetMatrix.Job?>(null) }
    var status by remember { mutableStateOf("กำลังเตรียม…") }
    var scale by remember { mutableStateOf(2f) }
    val done by rememberUpdatedState(onDone)
    // งานยาวหลายนาที — จอดับเมื่อไหร่เฟรมหยุด ตัววาดก็หยุด (ธงของหน้าต่างแอปเอง ไม่แตะค่าระบบ)
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
                            // ไม่กินที่ในผังของจอ — วาดลงเลเยอร์อย่างเดียว
                            layout(0, 0) { p.place(0, 0) }
                        }
                        .drawWithContent {
                            layer.record { this@drawWithContent.drawContent() }
                            recorded[0] += 1
                        },
                ) {
                    // หนึ่งหน่วยออกแบบ = `scale` พิกเซลเสมอ · ตัวอักษรไม่ล้อการตั้งค่าของเครื่อง
                    CompositionLocalProvider(LocalDensity provides Density(scale, 1f), LocalPhotoStore provides photos) {
                        MatrixSheet(j)
                    }
                }
            }
        }
    }

    LaunchedEffect(Unit) {
        val log = StringBuilder()
        val t0 = SystemClock.elapsedRealtime()
        fun line(s: String) { log.append(s).append('\n') }
        val out = WidgetMatrix.output
        withContext(Dispatchers.IO) {
            out.deleteRecursively()
            out.mkdirs()
        }
        val text = withContext(Dispatchers.IO) { runCatching { WidgetMatrix.input.readText() }.getOrNull() }
        if (text == null) {
            line("ไม่พบ ${WidgetMatrix.input}")
            withContext(Dispatchers.IO) { runCatching { File(out, "log.txt").writeText(log.toString()) } }
            status = "ไม่พบ matrix.json"
            done()
            return@LaunchedEffect
        }
        val root = CardStore.json.parseToJsonElement(text).jsonObject
        scale = root["scale"]?.jsonPrimitive?.floatOrNull ?: 2f
        val configs = root["configs"]?.jsonArray ?: JsonArray(emptyList())
        line("matrix: ${configs.size} configs · scale $scale · device density ${AppContext.app.resources.displayMetrics.density}")

        status = "โหลดรูปตัวอย่าง…"
        val tp = SystemClock.elapsedRealtime()
        runCatching { CardExport.preload() }.onFailure { line("preload ล้ม: ${it.message}") }
        line("preload รูปตัวอย่าง ${SystemClock.elapsedRealtime() - tp} ms")
        line("pageContentWidth (widget configs) = ${WidgetMatrix.contentWidth}")
        line("subject lift: stub บน Android (PhotoLift/SubjectLift คืน \"ไม่มี cutout\" เสมอ) — iOS ใช้ Vision")
        line("owner บนเครื่อง: name=\"${Profile.me.creator.name}\" · creators=${Portfolio.shared.creators.count { it != null }} · works=${Portfolio.shared.works.size} · library=${photos.uploaded.size} · avatar=${photos.profile != null}")
        val pending = WidgetKind.entries.mapNotNull { k -> pendingNote(k)?.let { "${k.raw}: $it" } }
        line("SystemPending: " + if (pending.isEmpty()) "none" else pending.joinToString(" · "))
        line("")

        var ok = 0
        var failed = 0
        var skipped = 0
        val used = HashSet<String>()
        // บีบ PNG นอกลูปวาด — วาดช่องถัดไปได้เลยระหว่างที่ช่องก่อนยังเขียนไฟล์อยู่ (ค้างได้ไม่เกิน 4 รูป)
        val lines = arrayOfNulls<String>(configs.size)
        val gate = Semaphore(4)
        val writers = mutableListOf<CoJob>()
        val encode = Dispatchers.Default.limitedParallelism(3)
        for ((i, raw) in configs.withIndex()) {
            val (made, why) = WidgetMatrix.job(i, raw)
            if (made == null) {
                skipped += 1
                lines[i] = "SKIP #$i ${(raw as? JsonObject)?.get("id")?.jsonPrimitive?.contentOrNull} — $why"
                continue
            }
            var name = made.file
            if (!used.add(name)) { name = "${made.file}__$i"; used.add(name) }
            val note = if (name != made.id) " (ไฟล์ $name.png)" else ""
            if (i % 10 == 0) status = "${i + 1}/${configs.size} · ${made.id}"
            val tc = SystemClock.elapsedRealtime()
            recorded[0] = 0
            job = made
            val shot = runCatching {
                // รอให้ผังนิ่ง แล้วถ่ายซ้ำจนสองรูปติดกันเหมือนกัน (รูปที่โหลดช้ามาทีหลังได้ = "วาดสองรอบ")
                var frames = 0
                while (recorded[0] == 0 && frames < 120) { withFrameNanos { }; frames++ }
                repeat(2) { withFrameNanos { } }
                delay(40)
                var prev = layer.toImageBitmap().asAndroidBitmap()
                var shots = 1
                var stable = false
                while (shots < 6) {
                    repeat(2) { withFrameNanos { } }
                    delay(if (shots == 1) 60L else 250L)
                    val next = layer.toImageBitmap().asAndroidBitmap()
                    shots += 1
                    if (next.sameAs(prev)) { stable = true; prev = next; break }
                    prev = next
                }
                Triple(prev, shots, stable)
            }
            val renderMs = SystemClock.elapsedRealtime() - tc
            if (shot.isFailure) {
                failed += 1
                val e = shot.exceptionOrNull()
                lines[i] = "FAIL #$i ${made.id} [${made.kind}] ${e?.javaClass?.simpleName}: ${e?.message}"
                continue
            }
            val (bmp, shots, stable) = shot.getOrThrow()
            val w = (made.page.w * scale).roundToInt()
            val h = (made.page.h * scale).roundToInt()
            gate.acquire()
            writers += launch(encode) {
                try {
                    val src = if (bmp.config == Bitmap.Config.ARGB_8888) bmp else bmp.copy(Bitmap.Config.ARGB_8888, false)
                    val px = IntArray(src.width * src.height)
                    src.getPixels(px, 0, src.width, 0, 0, src.width, src.height)
                    val translucent = px.count { (it ushr 24) != 0xFF }
                    // ทึบเสมอ (= ImageRenderer.isOpaque) — ส่วนโปร่งถูกปูดำ
                    val opaque = Bitmap.createBitmap(src.width, src.height, Bitmap.Config.ARGB_8888)
                    android.graphics.Canvas(opaque).apply {
                        drawColor(android.graphics.Color.BLACK)
                        drawBitmap(src, 0f, 0f, null)
                    }
                    opaque.setHasAlpha(false)
                    FileOutputStream(File(out, "$name.png")).use { opaque.compress(Bitmap.CompressFormat.PNG, 100, it) }
                    opaque.recycle()
                    val sizeNote = if (src.width != w || src.height != h) " SIZE ${src.width}x${src.height} ≠ ${w}x$h" else ""
                    val alphaNote = if (translucent > 0) " translucent=${translucent}px" else ""
                    val stableNote = if (stable) "" else " UNSTABLE"
                    lines[i] = "OK   #$i ${made.id}$note [${made.kind}] ${src.width}x${src.height} shots=$shots$stableNote$alphaNote$sizeNote render ${renderMs} ms"
                } catch (e: Exception) {
                    lines[i] = "FAIL #$i ${made.id} [${made.kind}] write ${e.javaClass.simpleName}: ${e.message}"
                } finally {
                    gate.release()
                }
            }
        }
        writers.joinAll()
        for (l in lines) if (l != null) line(l)
        ok = lines.count { it?.startsWith("OK") == true }
        failed = lines.count { it?.startsWith("FAIL") == true }
        val sizeBad = lines.count { it?.contains(" SIZE ") == true }
        val unstable = lines.count { it?.contains(" UNSTABLE") == true }
        val translucentN = lines.count { it?.contains(" translucent=") == true }
        line("")
        line("size mismatches $sizeBad · unstable $unstable · had transparency (flattened on black) $translucentN")
        job = null
        val total = SystemClock.elapsedRealtime() - t0
        line("")
        line("rendered $ok · failed $failed · skipped $skipped · of ${configs.size} · wall ${total / 1000.0} s")
        withContext(Dispatchers.IO) { File(out, "log.txt").writeText(log.toString()) }
        status = "เสร็จ · $ok รูป · ล้ม $failed · ข้าม $skipped · ${total / 1000} วิ"
        done()
    }
}
