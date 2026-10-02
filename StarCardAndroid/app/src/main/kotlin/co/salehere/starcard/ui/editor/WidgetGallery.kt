package co.salehere.starcard.ui.editor

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.GlassPanel
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.model.CatalogEntry
import co.salehere.starcard.model.Mock
import co.salehere.starcard.model.StarTopic
import co.salehere.starcard.model.TrayGroup
import co.salehere.starcard.model.WidgetKind
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.LocalGhostData
import co.salehere.starcard.ui.LocalSampleData
import co.salehere.starcard.ui.tap
import co.salehere.starcard.ui.widgets.WidgetBody
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

// MARK: - Widget Gallery (= Views/Editor/WidgetGallery.swift)
//
// การเลือกวิดเจ็ตคือการ **เทียบของหลายชิ้น** ไม่ใช่การอ่านทีละชิ้น — พรีวิวขอแค่ **จำทรงกับองค์ประกอบได้**
// กริดสองคอลัมน์: ใบกว้างย่อเหลือ ~0.48 เห็นทรงครบ · ใบทรงตั้งได้สเกลเกือบ 1:1 · เห็นพร้อมกัน 4–6 ใบต่อจอ

/** ระยะห่างระหว่างช่องในกริด */
private const val GalleryGap = 12f

/** สเกลที่ยอมให้พรีวิวย่อ/ขยายได้ — บีบไว้ 0.45–0.62 ส่วนต่างของ "ขนาดที่เห็น" จึงเหลือ 1.3 เท่า จากเดิม 2 เท่า */
private const val TileScaleMin = 0.45f
private const val TileScaleMax = 0.62f

/** ความสูงขั้นต่ำของช่อง — ใบเตี้ยมาก (แถบติดต่อ 6×4) ย่อแล้วบางจนอ่านไม่ออก ให้พื้นที่หายใจขั้นต่ำ */
private const val TileMinHeight = 58f

/** ก้อนหนึ่งตระกูล — `id` เป็น raw ของตระกูล จึงไม่ซ้ำกันทั้งลิสต์ */
private data class GallerySection(val id: String, val label: String, val entries: List<CatalogEntry>)

/**
 * ขนาดจริงของ widget เมื่อไปนั่งอยู่บนการ์ด — หน่วย pt บนพื้นที่ออกแบบ (= `WidgetGallery.metrics`)
 * ตัวเรียกย่อลงให้พอดีช่องในตู้เอง
 */
internal fun galleryMetrics(k: WidgetKind): Size {
    val s = k.defaultSize
    return Size(max(1f, s.width), max(1f, s.height))
}

/**
 * Widget Gallery — ชิปหมวด (= หัวข้อ Star Profile) · กริดสองคอลัมน์ · เห็นหลายใบพร้อมกัน
 * - onFill: ช่องที่ผูกกับหัวข้อ Star Profile ที่ยังไม่ได้กรอก — ผู้เรียกพาไปกรอกข้อนั้น แล้วค่อยเพิ่มใบนี้ให้
 * - showsBar: หัวตู้ (ชื่อ + ปุ่มปิด) — ปิดเมื่อตู้อยู่ในถาดของแถบล่าง ซึ่งมี ‹ กับชื่อโหมดอยู่แล้ว
 *
 * ต้องได้ความสูงจำกัดจากผู้เรียก (`weight(1f)` / ช่องของ `DockSheet(fill = true)`) — รายการข้างในเลื่อนเอง
 */
@Composable
fun WidgetGallery(
    theme: CardTheme,
    onAdd: (WidgetKind) -> Unit,
    onFill: (WidgetKind, StarTopic) -> Unit = { _, _ -> },
    onClose: (() -> Unit)?,
    showsBar: Boolean = true,
    modifier: Modifier = Modifier,
) {
    /** ชิปที่เลือกล่าสุด — แต่ละชิป = รายการของหมวดนั้น */
    var group by remember { mutableStateOf(TrayGroup.profile) }
    /** ความกว้างของหนึ่งคอลัมน์ — วัดจากของจริง ค่าตั้งต้นพอให้เฟรมแรกไม่พัง */
    var colW by remember { mutableFloatStateOf(160f) }
    val density = LocalDensity.current.density

    // ก้อนข้อความมีปุ่มของตัวเองบนแถบล่าง — สองทางเข้าสำหรับของชิ้นเดียวคือความงงที่ไม่จำเป็น
    val all = (Mock.catalog + Mock.lockedTeasers)
        .filter { it.kind != WidgetKind.textBlock }
        .sortedWith(compareBy<CatalogEntry>({ it.kind.family.ordinal }, { if (it.unlocked) 0 else 1 }))

    val ordered = all.sortedWith(
        compareBy<CatalogEntry>({ it.kind.family.trayGroup.ordinal }, { it.kind.family.ordinal }),
    )
    val sections = mutableListOf<GallerySection>()
    for (e in ordered) {
        if (e.kind.family.trayGroup != group) continue
        val last = sections.lastOrNull()
        if (last != null && last.id == e.kind.family.raw) {
            sections[sections.size - 1] = last.copy(entries = last.entries + e)
        } else {
            sections.add(GallerySection(e.kind.family.raw, e.kind.family.label, listOf(e)))
        }
    }
    // อ่านสถานะการกรอกตรงนี้ (ใน composition) — กรอกหัวข้อเสร็จ ช่องที่เคยล็อกเปิดทันที
    val sectionMissing = sections.map { sec -> sec.entries.firstOrNull()?.kind?.family?.topic?.takeIf { !it.filled } }
    val entryMissing = sections.map { sec -> sec.entries.map { it.kind.family.topic?.let { t -> !t.filled } ?: false } }

    Column(modifier) {
        if (showsBar) GalleryBar(onClose)

        // ชิปหมวดเลื่อนแนวนอน = หัวข้อ Star Profile (ลำดับเดียวกับที่การ์ดเล่าเรื่อง)
        // หมวดที่ยังไม่มีข้อมูล = ขอบประสีเน้น + จุดเล็ก ให้เห็นตั้งแต่แถวชิปว่าอะไรยังขาด
        Row(
            Modifier
                .padding(bottom = 12.dp)
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = 2.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            TrayGroup.entries.forEach { g ->
                GalleryChip(
                    group = g,
                    active = group == g,
                    missing = g.topic?.let { !it.filled } ?: false,
                    accent = theme.accent,
                ) {
                    Haptics.impact(Haptics.Style.light)
                    // ไม่มีอนิเมชันตอนสลับหมวด — รายการผูกกับหมวด อนิเมตแล้วของเก่าค้างซ้อน
                    group = g
                }
            }
        }

        // เปลี่ยนหมวดแล้วกลับไปบนสุดเสมอ (สร้างรายการใหม่ ไม่ cross-fade ของเก่า)
        key(group) {
            val listState = rememberLazyListState()
            LazyColumn(
                state = listState,
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .onSizeChanged { sz ->
                        // อัปเดตเฉพาะเมื่อกว้างต่างจริง — ระหว่างชีตย่อ/ขยาย ค่าเปลี่ยนทุกเฟรมแล้ววนไม่จบ
                        val w = sz.width / density
                        val next = max(120f, (w - GalleryGap) / 2f)
                        if (w > 1f && abs(next - colW) > 0.5f) colW = next
                    },
                contentPadding = PaddingValues(bottom = 24.dp),
            ) {
                sections.forEachIndexed { si, sec ->
                    item(key = "h-" + sec.id) {
                        GallerySectionHeader(sec.label, sectionMissing[si], theme.accent)
                    }
                    sec.entries.chunked(2).forEachIndexed { ri, row ->
                        item(key = "r-" + sec.id + "-" + ri) {
                            Row(
                                Modifier
                                    .fillMaxWidth()
                                    .padding(top = if (ri > 0) GalleryGap.dp else 0.dp),
                                horizontalArrangement = Arrangement.spacedBy(GalleryGap.dp),
                                verticalAlignment = Alignment.Top,
                            ) {
                                row.forEachIndexed { ci, e ->
                                    val topic = e.kind.family.topic
                                    val missing = entryMissing[si][ri * 2 + ci]
                                    Box(Modifier.weight(1f), contentAlignment = Alignment.TopCenter) {
                                        GalleryTile(
                                            entry = e,
                                            theme = theme,
                                            colWidth = colW,
                                            missingTopic = if (missing) topic else null,
                                        ) {
                                            if (topic != null && missing) onFill(e.kind, topic) else onAdd(e.kind)
                                        }
                                    }
                                }
                                if (row.size == 1) Spacer(Modifier.weight(1f))
                            }
                        }
                    }
                }
            }
        }
    }
}

/** หัวตู้ — ชื่อ + ปุ่มปิด */
@Composable
private fun GalleryBar(onClose: (() -> Unit)?) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(bottom = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("เพิ่มวิดเจ็ต", style = sh(17f, SHFont.bold), color = Color.White.opacity(0.95))
        Spacer(Modifier.weight(1f))
        if (onClose != null) {
            Box(
                Modifier
                    .size(30.dp)
                    .background(Color.White.opacity(0.1), CircleShape)
                    .tap(onClick = onClose),
                contentAlignment = Alignment.Center,
            ) {
                SFSymbol("xmark", size = 11f, tint = Color.White.opacity(0.7))
            }
        }
    }
}

/** ชิปหมวดหนึ่งอัน — หมวดที่ยังไม่มีข้อมูล = จุดสีเน้น + ขอบประ (เมื่อยังไม่ได้เลือก) */
@Composable
private fun GalleryChip(group: TrayGroup, active: Boolean, missing: Boolean, accent: Color, onTap: () -> Unit) {
    val bg by animateColorAsState(
        if (active) Color.White else Color.White.opacity(0.1), Motion.snap.spec(), label = "chipBg",
    )
    val fg by animateColorAsState(
        if (active) Color.Black else Color.White.opacity(if (missing) 0.8 else 0.9), Motion.snap.spec(), label = "chipFg",
    )
    val dashed = missing && !active
    Row(
        Modifier
            .height(34.dp)
            .background(bg, CircleShape)
            .drawWithContent {
                drawContent()
                if (dashed) {
                    dashedRoundRect(
                        color = accent.opacity(0.8),
                        lineWidth = 1.2.dp.toPx(),
                        intervals = floatArrayOf(4.dp.toPx(), 3.dp.toPx()),
                        radius = size.height / 2f,
                    )
                }
            }
            .tap(onClick = onTap)
            .padding(horizontal = 13.dp),
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (missing) Box(Modifier.size(6.dp).background(accent, CircleShape))
        Text(
            group.label,
            style = sh(13f, if (active) SHFont.bold else SHFont.semibold),
            color = fg,
            maxLines = 1,
            softWrap = false,
        )
    }
}

/**
 * หัวข้อคั่นตระกูล — เงียบที่สุดเท่าที่ยังอ่านออก
 * ทั้งตระกูลรอหัวข้อเดียวกัน — บอกครั้งเดียวที่หัว ไม่ต้องอ่านซ้ำทุกใบ
 */
@Composable
private fun GallerySectionHeader(label: String, missing: StarTopic?, accent: Color) {
    Row(
        Modifier.padding(top = 20.dp, bottom = 11.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, style = sh(12f, SHFont.heavy), color = Color.White.opacity(0.4))
        if (missing != null) {
            Text(
                if (missing.fillable) "${missing.missingLine} · แตะใบไหนก็ได้เพื่อกรอก" else missing.missingLine,
                style = sh(11f, SHFont.semibold),
                color = accent.opacity(0.9),
                modifier = Modifier.weight(1f, fill = false),
            )
        }
    }
}

// MARK: - พรีวิวหนึ่งใบ

/**
 * ทั้งช่องคือปุ่มเพิ่ม · ไม่มีปุ่มบวกซ้อนอยู่ข้างในอีก
 * **ไม่มีพื้นและไม่มีขอบของช่อง** — ตู้ต้องแสดง "ของ" ไม่ใช่ "ของในกล่องของตู้"
 * - missingTopic: หัวข้อ Star Profile ที่ใบนี้ต้องใช้แต่ยังไม่ได้กรอก — null = ใช้ได้เลย
 */
@Composable
private fun GalleryTile(
    entry: CatalogEntry,
    theme: CardTheme,
    colWidth: Float,
    missingTopic: StarTopic? = null,
    onAdd: () -> Unit,
) {
    var pressed by remember { mutableStateOf(false) }
    val press by animateFloatAsState(if (pressed) 0.96f else 1f, Motion.snap.float, label = "tilePress")
    val m = galleryMetrics(entry.kind)
    // สเกลจริงที่ใช้ — ตัวเดียวกันทั้งวัดความสูงและวาด จึงไม่มีทางคำนวณเหลื่อมกัน
    val scale = min(max(colWidth / m.width, TileScaleMin), TileScaleMax)
    val tileH = max(TileMinHeight, m.height * scale)
    val add by rememberUpdatedState(onAdd)
    val unlocked by rememberUpdatedState(entry.unlocked)

    Box(
        Modifier
            .size(colWidth.dp, tileH.dp)
            .graphicsLayer {
                scaleX = press
                scaleY = press
            }
            .pointerInput(Unit) {
                detectTapGestures(
                    onPress = {
                        pressed = true
                        tryAwaitRelease()
                        pressed = false
                    },
                    onTap = {
                        if (!unlocked) {
                            Haptics.rigid()
                        } else {
                            Haptics.impact(Haptics.Style.light)
                            add()
                        }
                    },
                )
            },
    ) {
        GalleryPreview(entry, theme, m, scale, colWidth, tileH, missingTopic)
        if (!entry.unlocked) LockedVeil(entry.requirement, Modifier.matchParentSize())
        // ยังไม่มีข้อมูลของหัวข้อนี้: พรีวิวยังเป็นใบจริงพร้อมข้อมูลตัวอย่าง — แท่งว่างบอกไม่ได้ว่าใบนี้คืออะไร
        if (missingTopic != null && entry.unlocked) FillFrame(missingTopic, theme.accent, Modifier.matchParentSize())
    }
}

/**
 * เรนเดอร์ที่ **ขนาดจริงของ widget** แล้วค่อยย่อทั้งก้อน — จัดกลางช่อง ไม่ใช่ชิดมุม
 * ห้ามเรนเดอร์ที่ความกว้างคอลัมน์ตรง ๆ — วิดเจ็ตหลายตัวสลับผังตามความกว้าง พรีวิวจะไม่ใช่ของจริงย่อส่วน
 */
@Composable
private fun GalleryPreview(
    entry: CatalogEntry,
    theme: CardTheme,
    m: Size,
    scale: Float,
    colWidth: Float,
    tileH: Float,
    missingTopic: StarTopic?,
) {
    val kind = entry.kind
    // ตัวที่ **รูปคือพื้นผิว** ปล่อยให้เต็มช่อง · ที่เหลือต้องมีขอบหายใจเท่ากับตอนอยู่บนการ์ด
    val inset = if (kind.isFullBleed || kind.usesPhoto) 0f else 14f
    // ตัวที่ได้แผ่นจาก chrome ตอนลงการ์ด ต้องเห็นแผ่นนั้นในตู้ด้วย — ไม่งั้นตู้โชว์ตัวหนังสือลอย ๆ
    val panelled = !kind.drawsOwnSurface

    Box(
        Modifier
            .size(colWidth.dp, tileH.dp)
            // ยังใช้ไม่ได้ = ใบจาง (ผู้ใช้ 24 ก.ย.: "ต้องมี alpha เทา ๆ ว่ายังใช้ไม่ได้")
            .alpha(if (entry.unlocked) 1f else 0.18f),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier
                .wrapContentSize(Alignment.Center, unbounded = true)
                .requiredSize(m.width.dp, m.height.dp)
                .graphicsLayer {
                    scaleX = scale
                    scaleY = scale
                },
            contentAlignment = Alignment.TopStart,
        ) {
            // ยังไม่มีข้อมูลของหัวข้อนี้ = เห็นใบเต็ม ๆ แต่ค่าของผู้ใช้เป็นแท่งว่าง
            CompositionLocalProvider(
                LocalGhostData provides (missingTopic != null),
                LocalSampleData provides true,
            ) {
                val body: @Composable () -> Unit = {
                    Box(
                        Modifier
                            .fillMaxSize()
                            .padding(inset.dp),
                    ) {
                        WidgetBody(kind, theme, Size(m.width - inset * 2f, m.height - inset * 2f))
                    }
                }
                // แผ่นของพรีวิวในตู้ — เปิดเฉพาะชิ้นที่ `WidgetChrome` จะวาดแผ่นให้ตอนอยู่บนการ์ด
                if (panelled) {
                    GlassPanel(radius = 18f, modifier = Modifier.fillMaxSize()) { body() }
                } else {
                    body()
                }
            }
        }
    }
}

/** ช่องที่ยังกดไม่ได้ — ต้องบอกว่าทำยังไงถึงจะได้มา ไม่งั้นมันคือช่องที่พังเฉย ๆ */
@Composable
private fun LockedVeil(requirement: String?, modifier: Modifier) {
    Column(
        modifier
            .background(Color.Black.opacity(0.25), RoundedCornerShape(16.dp))
            .padding(horizontal = 10.dp),
        verticalArrangement = Arrangement.spacedBy(5.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        SFSymbol("lock.fill", size = 13f, tint = Color.White.opacity(0.75))
        Text(
            requirement ?: "",
            style = sh(9.5f, SHFont.semibold),
            color = Color.White.opacity(0.62),
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

/**
 * ใบที่รอหัวข้อ Star Profile: ม่านจาง + กรอบประสีเน้นของการ์ด + กุญแจมุมขวาบน + ป้าย "+ กรอก…" คร่อมขอบล่าง
 * ภาษาเดียวกับช่องประบนหน้า Star Profile · ไม่มีม่านทึบ — พรีวิวคือเหตุผลที่คนอยากกรอก ต้องเห็นชัด
 */
@Composable
private fun FillFrame(t: StarTopic, accent: Color, modifier: Modifier) {
    val shape = RoundedCornerShape(16.dp)
    Box(
        modifier
            .background(Color.Black.opacity(0.42), shape)
            .drawBehind {
                dashedRoundRect(
                    color = accent.opacity(0.6),
                    lineWidth = 1.5.dp.toPx(),
                    intervals = floatArrayOf(6.dp.toPx(), 4.dp.toPx()),
                    radius = 16.dp.toPx(),
                    outset = 3.dp.toPx(),
                )
            },
    ) {
        // กุญแจล็อกมุมขวาบน — เห็นตั้งแต่ไกลว่าใบนี้ยังหยิบไม่ได้
        Box(
            Modifier
                .align(Alignment.TopEnd)
                .padding(6.dp)
                .size(26.dp)
                .background(Color.Black.opacity(0.7), CircleShape)
                .border(0.8.dp, Color.White.opacity(0.35), CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            SFSymbol("lock.fill", size = 11f, tint = Color.White)
        }
        Row(
            Modifier
                .align(Alignment.BottomCenter)
                .offset(y = 10.dp)
                .shadow(
                    6.dp, CircleShape, clip = false,
                    ambientColor = Color.Black.opacity(0.35), spotColor = Color.Black.opacity(0.35),
                )
                .background(Color.White, CircleShape)
                .border(1.2.dp, accent.opacity(0.9), CircleShape)
                .height(26.dp)
                .padding(horizontal = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            SFSymbol(if (t.fillable) "plus" else "lock.fill", size = 10f, tint = Color.Black)
            Text(t.action, style = sh(11f, SHFont.bold), color = Color.Black, maxLines = 1, softWrap = false)
        }
    }
}

/**
 * เส้นประตามขอบ (= `shape.strokeBorder(style: StrokeStyle(dash:))`) — เส้นอยู่ **ด้านใน** ขอบ
 * `outset` ขยายกรอบออกก่อนวาด (= `.padding(-x)` ของ SwiftUI)
 */
private fun DrawScope.dashedRoundRect(
    color: Color,
    lineWidth: Float,
    intervals: FloatArray,
    radius: Float,
    outset: Float = 0f,
) {
    val half = lineWidth / 2f
    val w = size.width + outset * 2f - lineWidth
    val h = size.height + outset * 2f - lineWidth
    if (w <= 0f || h <= 0f) return
    val r = max(0f, radius - half)
    drawRoundRect(
        color = color,
        topLeft = Offset(-outset + half, -outset + half),
        size = Size(w, h),
        cornerRadius = CornerRadius(r, r),
        style = Stroke(width = lineWidth, pathEffect = PathEffect.dashPathEffect(intervals, 0f)),
    )
}
