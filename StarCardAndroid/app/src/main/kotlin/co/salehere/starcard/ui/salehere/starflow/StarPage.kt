package co.salehere.starcard.ui.salehere.starflow

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.BlurredEdgeTreatment
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.layout
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.StarCardIntent
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.model.CardFormat
import co.salehere.starcard.model.CardLibrary
import co.salehere.starcard.model.CardPage
import co.salehere.starcard.model.CardRecord
import co.salehere.starcard.model.CardStore
import co.salehere.starcard.model.CardTemplate
import co.salehere.starcard.model.LocalStarFlow
import co.salehere.starcard.model.StarCampaign
import co.salehere.starcard.model.StarDataKey
import co.salehere.starcard.model.StarRow
import co.salehere.starcard.model.VerifyStatus
import co.salehere.starcard.model.WizStep
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.CardFramePreview
import co.salehere.starcard.ui.CardGallery
import co.salehere.starcard.ui.CardStripPreview
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.dockPress
import co.salehere.starcard.ui.pkRowPress
import co.salehere.starcard.ui.profile.PK
import co.salehere.starcard.ui.profile.PKFactStrip
import co.salehere.starcard.ui.tap
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.ceil
import kotlin.math.max

/** โหมดของ `StarPage` (= `StarPage.Mode`) */
enum class StarPageMode { reveal, profile }

/** toggle ข้อมูล | การ์ด (แบบ G2) — หน้าเดียว สองมุมมองของของเดียวกัน (= `StarPage.Pane`) */
private enum class StarPane { info, card }  // info = `.data` ของ Swift

/**
 * หน้าเดียวกัน 2 โหมด (= `starPage()` ใน newflow.js)
 * - `reveal` = การ์ดเพิ่งเกิด: ตรา + "คุณเป็น STAR แล้ว" + ปุ่มต่อไปฟอร์มสมัคร (motion ยาวครั้งแรกครั้งเดียว)
 * - `profile` = Star Profile ถาวรจากปุ่ม "โปรไฟล์ครีเอเตอร์": หัวข้อ "Star Profile" + ปุ่มแชร์
 *
 * พื้นสว่าง + แสงเบลอ champagne + การ์ดกระจกขอบเหลืองนิดๆ ใบเดียว + รายการ "เติมการ์ดให้เต็ม" เป็นกระจก
 * - onNext: reveal — ต่อไปฟอร์มสมัคร
 * - onFill: เปิด wizard เฉพาะข้อที่ส่งมา (kind one) แล้วกลับมาหน้านี้
 * - onOpenStarCard: profile — เปิดพื้นที่ Star Card เดิม (คลัง/ห้องแต่ง)
 * - hosted: หัว (title + toggle) และพื้น/ดวงไฟ ถูกวาดโดย shell (`StarHeader` + `StarGround`) — หน้านี้เว้นที่ไว้ให้เฉย ๆ
 */
@Composable
fun StarPage(
    mode: StarPageMode,
    campaign: StarCampaign,
    onClose: () -> Unit,
    onNext: () -> Unit = {},
    onFill: (List<WizStep>) -> Unit,
    onKyc: () -> Unit,
    onShare: () -> Unit = {},
    onOpenStarCard: (StarCardIntent) -> Unit = {},
    hosted: Boolean = false,
    modifier: Modifier = Modifier,
) {
    val flow = LocalStarFlow.current
    var pane by remember { mutableStateOf(StarPane.info) }
    val quiet = mode == StarPageMode.profile || flow.revealSeen
    /** คลังการ์ด — Star Profile โชว์ใบที่กำลังแสดงอยู่เป็นพระเอก (Star Card = Star Profile ที่เป็นภาพ) */
    val library = CardLibrary.shared
    /** ใบที่กำลังแสดงอยู่ = หน้าตาของ Star Profile · ยังไม่มีใบในคลัง = การ์ดกระจกสรุปไปก่อน + ปุ่มเลือกแบบการ์ด */
    val liveCard: CardRecord? = if (mode == StarPageMode.profile) library.displayOrder.firstOrNull() else null

    val cardIn = remember { Animatable(if (quiet) 1f else 0f) }
    val rowsIn = remember { Animatable(if (quiet) 1f else 0f) }
    val barPct = remember { Animatable(if (quiet) flow.pct.toFloat() else 0f) }

    val rows = StarRow.all
    val todo = rows.filter { !flow.done(it) }
    val done = rows.filter { flow.done(it) }
    /** ปุ่มล่างยังพาเติมทุกข้อ (เส้นทางจาก Star Profile ถามครบทุกช่อง — ผู้ใช้ 24 ก.ย.) */
    val left = todo.size
    val mins = max(1, ceil(flow.missingSteps.size * 0.5).toInt() + (if (flow.isVerified) 0 else 1))

    LaunchedEffect(Unit) {
        if (quiet) {
            cardIn.snapTo(1f); rowsIn.snapTo(1f); barPct.snapTo(flow.pct.toFloat())
            return@LaunchedEffect
        }
        launch { cardIn.animateTo(1f, tween(1500, delayMillis = 700, easing = FlowEase)) }
        launch { rowsIn.animateTo(1f, tween(900, delayMillis = 2600, easing = FlowEase)) }
        launch { barPct.animateTo(flow.pct.toFloat(), tween(900, delayMillis = 2700, easing = FlowEase)) }
        launch { delay(3200); flow.revealSeen = true }
    }
    val pct = flow.pct.toFloat()
    var seenPct by remember { mutableFloatStateOf(pct) }
    LaunchedEffect(pct) {
        if (pct == seenPct) return@LaunchedEffect
        seenPct = pct
        barPct.animateTo(pct, tween(900, delayMillis = 250, easing = FlowEase))
    }

    /** ข้อที่ยังขาดทั้งหมดเป็นขั้นต่อกันตามลำดับรายการ — เริ่มที่ข้อที่แตะ ไล่ต่อจนสุด แล้ววนกลับมาข้อก่อนหน้า */
    fun missingSteps(start: StarRow?): List<WizStep> {
        fun stepOf(r: StarRow): WizStep? = if (r.key != null) WizStep.from(r.key.raw) else WizStep.kyc
        val all = todo.mapNotNull { r ->
            if (r.key == null && flow.verify != VerifyStatus.none) null else stepOf(r)
        }
        if (start == null) return all
        val first = stepOf(start) ?: return all
        val i = all.indexOf(first)
        if (i < 0) return all
        return all.drop(i) + all.take(i)
    }

    fun tapRow(r: StarRow) {
        Haptics.impact(Haptics.Style.light)
        val ok = flow.done(r)
        val waiting = r.key == null && flow.verify == VerifyStatus.waiting
        if (ok || waiting) {
            // ข้อที่ครบแล้ว = แก้ข้อนั้นข้อเดียว · ยืนยันตัวตนที่รอตรวจ = ดูสถานะ
            if (r.key == null) onKyc() else WizStep.from(r.key.raw)?.let { onFill(listOf(it)) }
        } else {
            // ข้อที่ยังขาด = เริ่มที่ข้อนี้แล้วกดถัดไปต่อจนครบทุกข้อ ไม่ต้องเข้าออกทีละข้อ (ผู้ใช้ 24 ก.ย. 2569)
            onFill(missingSteps(r))
        }
    }

    val cardPane = mode == StarPageMode.profile && pane == StarPane.card

    Box(modifier.fillMaxSize().then(if (hosted) Modifier else Modifier.background(GL.bg))) {
        GlassOrbs(bloom = mode == StarPageMode.reveal && !quiet, ground = !hosted)
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .statusBarsPadding()
                .padding(horizontal = 16.dp)
                .padding(top = if (mode == StarPageMode.profile) 58.dp else 66.dp, bottom = if (cardPane) 40.dp else 170.dp),
        ) {
            StarPageHead(mode = mode, hosted = hosted, quiet = quiet)
            if (cardPane) {
                // มุมมอง "การ์ด" = คลังการ์ดเดิม ฝังบนพื้นสว่างเดียวกัน (สำรับ · ชื่อ · ลิงก์ · แต่ง/แชร์/ใช้ใบนี้)
                CardGallery(
                    onCreate = { onOpenStarCard(StarCardIntent.Create) },
                    onOpen = { onOpenStarCard(StarCardIntent.Edit(it.id)) },
                    onPreview = { onOpenStarCard(StarCardIntent.Preview(it.id)) },
                    embedded = true,
                    modifier = Modifier.padding(top = 8.dp).bleedHorizontal(16f).height(540.dp),
                )
                CardMissing(todo = todo, pane = pane, onTap = { tapRow(it) }, modifier = Modifier.padding(top = 8.dp))
            } else {
                // ข้อมูลเป็นพระเอกของหน้านี้ — การ์ดจริงเป็นแถวเล็กใต้ข้อมูล ให้รู้ว่ามีและแตะเข้าไปได้
                // (ผู้ใช้ 24 ก.ย. 2569: การ์ดใหญ่บนสุด "โครตแปลก · หน้านี้เน้นให้กรอกข้อมูล ข้อมูลหายไปหมด")
                Column(
                    Modifier
                        .padding(top = 24.dp)
                        .graphicsLayer {
                            val k = cardIn.value
                            alpha = k.coerceIn(0f, 1f)
                            rotationX = 28f * (1f - k)
                            cameraDistance = 6f * density
                            translationY = 90.dp.toPx() * (1f - k)
                            val s = 0.96f + 0.04f * k
                            scaleX = s
                            scaleY = s
                        },
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    // แตะรูปโปรไฟล์ = ไปหน้า "รูปและผลงาน" (audit: Profile photo)
                    // หมวดสุดท้ายของการ์ดข้อมูล = Star Card ใบที่เผยแพร่อยู่ · แตะ = หน้า Star Card ของฉัน (แต่ง/แชร์)
                    StarGlassCard(
                        onAvatar = if (mode == StarPageMode.profile && flow.hasCard) ({ onFill(listOf(WizStep.media)) }) else null,
                        liveCard = liveCard,
                        cardCount = library.records.size,
                        onOpenCard = { onOpenStarCard(StarCardIntent.Gallery) },
                    )
                    if (liveCard == null && mode == StarPageMode.profile && flow.hasCard) {
                        GlassActionButton(title = "เลือกแบบการ์ด", symbol = Ph.sparkle, action = { onOpenStarCard(StarCardIntent.Create) })
                    }
                }
                Completion(mode = mode, left = left, doneCount = done.size, total = rows.size, barPct = barPct, modifier = Modifier.padding(top = 26.dp))
                Column(
                    Modifier
                        .padding(top = 12.dp)
                        .graphicsLayer {
                            val k = rowsIn.value
                            alpha = k.coerceIn(0f, 1f)
                            translationY = 18.dp.toPx() * (1f - k)
                        },
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    todo.forEach { r -> StarRowItem(r, pane, onTap = { tapRow(r) }) }
                    // ข้อที่ครบแล้วเรียงต่อท้ายเลย ไม่รวบเป็นแถว "ครบแล้ว N อย่าง" ที่ต้องกดเปิด (ผู้ใช้ 24 ก.ย. 2569: "ไม่ต้องปิดได้ ซ่อนได้ โชว์เรียงมาเลย")
                    done.forEach { r -> StarRowItem(r, pane, onTap = { tapRow(r) }) }
                }
            }
        }
        if (hosted) {
            // แผ่นไล่สีรองหัวร่วมของ shell — เนื้อหาที่เลื่อนขึ้นมาจางหายใต้หัว ไม่ทับตัวหนังสือ (audit ข้อ 1)
            // ทึบจนถึงใต้หัว (safe top ≈ 59 + หัว 50…114) แล้วค่อยจาง — ครอบแถบสถานะด้วย
            val top = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(228.dp - 59.dp + top)
                    .background(Brush.verticalGradient(0f to GL.bg, 0.8f to GL.bg, 1f to GL.bg.opacity(0.0))),
            )
        }
        Row(Modifier.statusBarsPadding().padding(horizontal = 16.dp).padding(top = 8.dp)) {
            GlassCircleButton(symbol = if (mode == StarPageMode.profile) Ph.caretLeft else Ph.x, action = onClose)
            Spacer(Modifier.weight(1f))
        }
        // มุมมอง "การ์ด" มีปุ่มของคลัง (แต่ง/แชร์/ใช้ใบนี้) อยู่แล้ว — ไม่ซ้อนปุ่ม "เติมอีก N อย่าง" ทับรายการ
        if (!cardPane) {
            Column(
                Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .background(Brush.verticalGradient(0f to GL.bg.opacity(0.0), 0.38f to GL.bg.opacity(0.96), 1f to GL.bg))
                    .navigationBarsPadding()
                    .padding(horizontal = 22.dp)
                    .padding(top = 34.dp, bottom = 26.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                when (mode) {
                    StarPageMode.reveal -> {
                        GlassPrimaryButton(title = "ต่อ: ฟอร์มสมัคร ${campaign.episode}", action = onNext)
                        GlassLink(title = "แชร์การ์ดก่อน", action = onShare)
                    }
                    StarPageMode.profile -> when {
                        // รอบแรกกรอกให้ครบทุกข้อในรอบเดียว ไม่กลับมาหน้านี้ระหว่างทาง (ผู้ใช้ 24 ก.ย. 2569)
                        !flow.hasCard -> GlassPrimaryButton(
                            title = "สมัครเป็น STAR · ${flow.applySteps.size} ข้อ",
                            action = { onFill(flow.applySteps) },
                        )
                        left > 0 -> GlassPrimaryButton(
                            title = "เติมอีก $left อย่าง · ประมาณ $mins นาที",
                            action = {
                                val s = missingSteps(null)
                                if (s.isEmpty()) onKyc() else onFill(s)
                            },
                        )
                        // ข้อมูลครบ — แชร์อยู่ในหน้าการ์ด ปุ่มล่างพาเข้าไปแทนการแชร์จากตรงนี้
                        else -> GlassPrimaryButton(title = "ดูการ์ดของฉัน", symbol = Ph.arrowUpRight, action = { onOpenStarCard(StarCardIntent.Gallery) })
                    }
                }
            }
        }
    }
}

/** `.padding(.horizontal, -x)` — ยื่นเลยขอบซ้ายขวาของผู้ถือ */
private fun Modifier.bleedHorizontal(x: Float): Modifier = layout { measurable, constraints ->
    val px = x.dp.roundToPx()
    val wide = if (constraints.hasBoundedWidth) constraints.copy(maxWidth = constraints.maxWidth + 2 * px, minWidth = constraints.minWidth + 2 * px) else constraints
    val placeable = measurable.measure(wide)
    layout(max(0, placeable.width - 2 * px), placeable.height) { placeable.place(-px, 0) }
}

// MARK: หัว

@Composable
private fun StarPageHead(mode: StarPageMode, hosted: Boolean, quiet: Boolean) {
    val flow = LocalStarFlow.current
    when (mode) {
        StarPageMode.profile -> Column {
            if (flow.hasCard) {
                // ที่ว่างเท่าหัวร่วมของ shell (`StarHeader` สูง 64)
                if (hosted) Spacer(Modifier.height(64.dp))
                else GlassTitle(words = listOf("Star" to false, "Profile" to true))
                GlassChip(icon = Ph.eye, text = "แบรนด์ใช้ข้อมูลนี้ตอนคัดคน", modifier = Modifier.padding(top = 12.dp))
            } else {
                // ยังไม่มีการ์ด: หัว "สมัครเป็น STAR" อยู่ที่ shell เหมือนกัน (ไม่งั้นแผ่นรองหัวทับหัวที่อยู่ในรายการ)
                if (hosted) Spacer(Modifier.height(64.dp))
                else GlassTitle(words = listOf("สมัครเป็น" to false, "STAR" to true), small = true)
                val n = flow.applySteps.size
                GlassChip(
                    icon = Ph.clock,
                    text = "กรอก $n อย่าง · ประมาณ ${max(1, ceil(n * 0.4).toInt())} นาที",
                    modifier = Modifier.padding(top = 12.dp),
                )
            }
        }
        // ตราและหัวข้ออยู่กลางจอเหมือนเว็บ (.ach2-seal + .glass-title กลาง) — ไม่ชิดซ้าย
        StarPageMode.reveal -> Column(
            Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            RevealSeal(animated = !quiet)
            FitWidth(minScale = 0.7f) {
                Row(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                    if (flow.isStar) {
                        RevealWord("คุณเป็น", serif = false, delay = 0.0, quiet = quiet)
                        RevealWord("STAR", serif = true, delay = 0.17, quiet = quiet)
                        RevealWord("แล้ว", serif = false, delay = 0.34, quiet = quiet)
                    } else {
                        RevealWord("การ์ดของคุณ", serif = false, delay = 0.0, quiet = quiet)
                        RevealWord("พร้อมแล้ว", serif = true, delay = 0.17, quiet = quiet)
                    }
                }
            }
        }
    }
}

/** คำขึ้นทีละคำ (blur → คม) (= `.reveal-words`) */
@Composable
private fun RowScope.RevealWord(t: String, serif: Boolean, delay: Double, quiet: Boolean) {
    val k = remember { Animatable(if (quiet) 1f else 0f) }
    LaunchedEffect(Unit) {
        if (!quiet) k.animateTo(1f, tween(1100, delayMillis = ((0.95 + delay) * 1000).toInt(), easing = FlowEase))
    }
    val style = if (serif) {
        GL.serif(40f).copy(brush = Brush.verticalGradient(listOf(GL.ink, GL.ink, GL.goldInk)))
    } else {
        sh(30f, SHFont.heavy).copy(color = GL.ink, letterSpacing = (-0.8f).sp)
    }
    val blur = 8f * (1f - k.value.coerceIn(0f, 1f))
    BasicText(
        t,
        Modifier
            .alignByBaseline()
            .graphicsLayer {
                alpha = k.value.coerceIn(0f, 1f)
                translationY = 10.dp.toPx() * (1f - k.value)
            }
            .then(if (blur > 0.05f) Modifier.blur(blur.dp, BlurredEdgeTreatment.Unbounded) else Modifier),
        style = style,
        maxLines = 1,
        softWrap = false,
    )
}

// MARK: ความครบของการ์ด (= `.ach2-bt`)

@Composable
private fun Completion(mode: StarPageMode, left: Int, doneCount: Int, total: Int, barPct: Animatable<Float, *>, modifier: Modifier) {
    val flow = LocalStarFlow.current
    if (flow.hasCard) {
        Column(modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
            // รายการเดียวทุกข้อ — กลุ่มแยก "ใช้ตอนได้งาน" เอาออก (ผู้ใช้ 24 ก.ย. 2569: "เอาออก รวมไปเลย")
            Row(Modifier.fillMaxWidth()) {
                Text(
                    if (left > 0) "เติมการ์ดให้เต็ม" else "การ์ดเต็มแล้ว",
                    style = sh(18f, SHFont.bold), color = GL.ink, modifier = Modifier.alignByBaseline(),
                )
                Spacer(Modifier.weight(1f))
                if (left > 0) {
                    Text("$doneCount/$total", style = sh(15f, SHFont.heavy).tnum(), color = GL.ink, modifier = Modifier.alignByBaseline())
                } else {
                    Row(
                        Modifier.alignByBaseline(),
                        horizontalArrangement = Arrangement.spacedBy(3.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        PIcon(Ph.check, size = 13f, tint = GL.greenInk)
                        Text("$total/$total", style = sh(15f, SHFont.heavy), color = GL.greenInk)
                    }
                }
            }
            val fill = if (left > 0) GL.ink else GL.green
            Canvas(Modifier.fillMaxWidth().height(5.dp)) {
                val r = CornerRadius(size.height / 2f)
                drawRoundRect(GL.ink.opacity(0.08), cornerRadius = r)
                val w = size.width * barPct.value.coerceIn(0f, 1f)
                if (w > 0f) drawRoundRect(fill, size = Size(w, size.height), cornerRadius = r)
            }
            Text(
                if (left > 0) {
                    if (mode == StarPageMode.reveal) "ส่งใบสมัครก่อนได้ · ค่อยกลับมาเติมระหว่างรอผล" else "แบรนด์เห็นราคาและสไตล์คุณก่อนเลือก"
                } else "แบรนด์เห็นข้อมูลคุณครบแล้ว",
                style = sh(13f), color = GL.muted,
            )
        }
    } else {
        Column(modifier, verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("ข้อมูลบนการ์ด", style = sh(18f, SHFont.bold), color = GL.ink)
            Text("ข้อมูลเหล่านี้จะขึ้นบนการ์ดของคุณ", style = sh(13f), color = GL.muted)
        }
    }
}

/** ข้อที่ขาดและจะไปขึ้นบนการ์ดจริง ๆ — บัญชี/รอบแก้/ที่อยู่ ไม่ขึ้นการ์ด อยู่ที่มุมมอง "ข้อมูล" เท่านั้น */
@Composable
private fun CardMissing(todo: List<StarRow>, pane: StarPane, onTap: (StarRow) -> Unit, modifier: Modifier) {
    val list = todo.filter { it.key != StarDataKey.bank && it.key != StarDataKey.draftRounds && it.key != StarDataKey.address }
    Column(modifier, verticalArrangement = Arrangement.spacedBy(10.dp)) {
        if (list.isNotEmpty()) {
            Row(Modifier.fillMaxWidth()) {
                Text("ยังขาดบนการ์ด", style = sh(18f, SHFont.bold), color = GL.ink, modifier = Modifier.alignByBaseline())
                Spacer(Modifier.weight(1f))
                Text("${list.size}", style = sh(15f, SHFont.heavy).tnum(), color = GL.ink, modifier = Modifier.alignByBaseline())
            }
            list.forEach { r -> StarRowItem(r, pane, onTap = { onTap(r) }) }
        } else {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(24.dp).background(GL.green, CircleShape), contentAlignment = Alignment.Center) {
                    PIcon(Ph.check, size = 12f, tint = Color.White)
                }
                Text("ข้อมูลครบทุกอย่างบนการ์ดแล้ว", style = sh(14.5f, SHFont.bold), color = GL.ink)
            }
        }
    }
}

/** toggle ข้อมูล | การ์ด (แบบ G2 23 ก.ย. 2569) — เลิกใช้ 24 ก.ย. เก็บโค้ดไว้เผื่อย้อน */
@Suppress("unused")
@Composable
private fun PaneToggle(pane: StarPane, hasRecords: Boolean, onPane: (StarPane) -> Unit, onOpenStarCard: (StarCardIntent) -> Unit) {
    Row(
        Modifier
            .glShadow(GL.ink.opacity(0.07), 8f, 4f)
            .background(glassWhite(0.6), CircleShape)
            .border(1.dp, Color.White.opacity(0.95), CircleShape)
            .padding(3.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        listOf(Triple("ข้อมูล", StarPane.info, false), Triple("การ์ด", StarPane.card, true)).forEach { (title, p, dot) ->
            val on = pane == p
            Row(
                Modifier
                    .height(32.dp)
                    .background(if (on) GL.ink else Color.Transparent, CircleShape)
                    .tap {
                        if (pane == p) return@tap
                        Haptics.impact(Haptics.Style.light)
                        // "การ์ด" = ไปหน้า Star Card เดิม (คลังการ์ดเต็มจอ) — ผู้ใช้ 23 ก.ย.: "ต้องเปลี่ยนไปหน้าเดิม แค่เพิ่ม toggle"
                        if (p == StarPane.card) onOpenStarCard(StarCardIntent.Gallery) else onPane(p)
                    }
                    .padding(horizontal = 13.dp),
                horizontalArrangement = Arrangement.spacedBy(5.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(title, style = sh(13f, SHFont.bold), color = if (on) Color.White else GL.ink)
                if (dot && !on && hasRecords) {
                    // จุดเขียว = มีใบที่กำลังแสดงอยู่ (ป้ายเดียวกับในคลัง)
                    Box(Modifier.size(6.dp).background(GL.green, CircleShape))
                }
            }
        }
    }
}

// MARK: แถว "เติมการ์ดให้เต็ม" — ข้อที่ขาดขึ้นก่อน · ข้อที่ครบเรียงต่อท้าย (= `revealRows`)

@Composable
private fun StarRowItem(r: StarRow, pane: StarPane, onTap: () -> Unit) {
    val flow = LocalStarFlow.current
    val ok = flow.done(r)
    val waiting = r.key == null && flow.verify == VerifyStatus.waiting
    val shape = RoundedCornerShape(20.dp)
    Row(
        Modifier
            .fillMaxWidth()
            .glShadow(GL.ink.opacity(if (ok) 0.07 else 0.0), 11f, 8f, corner = 20f)
            .clip(shape)
            .pkRowPress { onTap() }
            .background(if (ok) Color.White.opacity(0.92) else Color.Transparent)
            .strokeInside(
                if (ok) Color.White else rgb(184 / 255.0, 187 / 255.0, 194 / 255.0),
                if (ok) 1f else 1.5f, radius = 20f,
                dash = if (ok) 0f else 5f, gap = if (ok) 0f else 4f,
            )
            .heightIn(min = 66.dp)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            Modifier
                .size(42.dp)
                .background(if (ok) PK.fieldFill else Color.Transparent, RoundedCornerShape(14.dp))
                .then(
                    if (ok) Modifier
                    else Modifier.strokeInside(rgb(201 / 255.0, 204 / 255.0, 210 / 255.0), 1.5f, radius = 14f, dash = 4f, gap = 3f),
                ),
            contentAlignment = Alignment.Center,
        ) {
            PIcon(r.icon, size = 18f, weight = if (ok) PhWeight.fill else PhWeight.bold, tint = if (ok) GL.ink else GL.hint)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(r.title, style = sh(16f, SHFont.bold), color = GL.ink)
            if (ok) {
                PKFactStrip(facts = flow.facts(r))
            } else {
                Text(
                    if (waiting) "ทีมงานตรวจภายใน 1–3 วันทำการ" else (if (pane == StarPane.card) r.onCard else r.why),
                    style = sh(13f), color = rgb(122 / 255.0, 127 / 255.0, 136 / 255.0), maxLines = 2, overflow = TextOverflow.Ellipsis,
                )
            }
        }
        when {
            ok -> Box(Modifier.size(24.dp).background(GL.green, CircleShape), contentAlignment = Alignment.Center) {
                PIcon(Ph.check, size = 12f, tint = Color.White)
            }
            waiting -> Row(
                Modifier.height(30.dp).background(Color.White.opacity(0.8), CircleShape).padding(horizontal = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                PIcon(Ph.clock, size = 12f, tint = GL.muted)
                Text("กำลังตรวจ", style = sh(12f, SHFont.bold), color = GL.muted)
            }
            else -> Row(
                Modifier
                    .glShadow(GL.ink.opacity(0.25), 7f, 6f)
                    .height(34.dp)
                    .background(GL.ink, CircleShape)
                    .padding(start = 10.dp, end = 13.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                PIcon(Ph.plus, size = 13f, tint = Color.White)
                Text("เพิ่ม", style = sh(13f, SHFont.bold), color = Color.White)
            }
        }
    }
}

/** ตราวงแหวนทอง + ดาว วาดตัวเองตอนเข้าหน้า (= `.ach2-seal`) */
@Composable
fun RevealSeal(animated: Boolean, modifier: Modifier = Modifier) {
    val drawn = remember { Animatable(if (animated) 0f else 1f) }
    val glow = remember { Animatable(if (animated) 0f else 1f) }
    LaunchedEffect(Unit) {
        if (!animated) return@LaunchedEffect
        launch { drawn.animateTo(1f, tween(1400, delayMillis = 500, easing = FlowEase)) }
        launch { glow.animateTo(1f, tween(2200, delayMillis = 750, easing = FlowEase)) }
    }
    val gold = Brush.linearGradient(
        listOf(rgb(232 / 255.0, 199 / 255.0, 102 / 255.0), GL.gold, rgb(138 / 255.0, 106 / 255.0, 26 / 255.0)),
        start = Offset.Zero, end = Offset.Infinite,
    )
    Box(modifier.size(76.dp), contentAlignment = Alignment.Center) {
        Canvas(Modifier.size(76.dp)) {
            val c = Offset(size.width / 2f, size.height / 2f)
            val g = glow.value
            // แสงนวลหลังตรา — จาง 0 → 0.35 · ขยาย 0.6 → 1.15
            glowOrb(rgb(1.0, 210 / 255.0, 90 / 255.0).opacity(0.55), c, 50.dp.toPx() * (0.6f + 0.55f * g), 6.dp.toPx(), 0.35f * g)
            val d = drawn.value.coerceIn(0f, 1f)
            if (d > 0f) {
                val r1 = 34.dp.toPx()
                drawArc(
                    gold, startAngle = -90f, sweepAngle = 360f * d, useCenter = false,
                    topLeft = Offset(c.x - r1, c.y - r1), size = Size(r1 * 2, r1 * 2), style = Stroke(1.2.dp.toPx()),
                )
                val r2 = 29.5.dp.toPx()
                drawArc(
                    gold, startAngle = -90f, sweepAngle = 360f * d, useCenter = false, alpha = 0.6f,
                    topLeft = Offset(c.x - r2, c.y - r2), size = Size(r2 * 2, r2 * 2), style = Stroke(0.6.dp.toPx()),
                )
            }
        }
        PIcon(
            Ph.star, size = 30f, weight = PhWeight.fill, tint = Color.White,
            modifier = Modifier
                .graphicsLayer {
                    val d = drawn.value
                    alpha = d.coerceIn(0f, 1f)
                    val s = 0.6f + 0.4f * d
                    scaleX = s
                    scaleY = s
                    compositingStrategy = CompositingStrategy.Offscreen
                }
                .drawWithContent {
                    drawContent()
                    drawRect(gold, blendMode = BlendMode.SrcIn)
                },
        )
    }
}

/**
 * Star Card ใบที่กำลังแสดงอยู่ วาดด้วย widget จริง (ของจริงย่อส่วน ไม่ใช่รูปแคป) — แตะเพื่อเข้าห้องแต่ง
 *
 * Star Profile กับ Star Card คือเรื่องเดียวกัน: ข้อมูลที่กรอกไว้ข้างล่างหน้านี้คือสิ่งที่การ์ดใบนี้เอาไปวาด
 */
@Composable
fun StarCardHero(record: CardRecord, onOpen: () -> Unit, modifier: Modifier = Modifier) {
    val restored = remember(record.snapshot) { CardStore.restore(record.snapshot) }
    val theme = restored?.theme ?: CardTheme()
    val pages = restored?.pages ?: emptyList()
    val radius = 18f
    val shape = RoundedCornerShape(radius.dp)
    Column(
        modifier
            .fillMaxWidth()
            .dockPress {
                Haptics.impact(Haptics.Style.light)
                onOpen()
            },
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        BoxWithConstraints(
            Modifier
                .fillMaxWidth()
                .aspectRatio(heroAspect(record.format))
                .glShadow(GL.ink.opacity(0.14), 22f, 16f, corner = radius)
                .clip(shape)
                .background(Brush.verticalGradient(listOf(theme.backdropColors.top, theme.backdropColors.bottom)))
                .border(1.dp, GL.cardRim.opacity(0.75), shape),
            contentAlignment = Alignment.Center,
        ) {
            val w = maxWidth.value
            val h = maxHeight.value
            when (record.format) {
                CardFormat.portfolio -> CardStripPreview(
                    pages = pages, theme = theme, width = w, showsDividers = false,
                    gutter = CardTemplate.thumbGutter, margin = CardTemplate.thumbGutter,
                    cornerRadius = radius,
                )
                CardFormat.story -> CardFramePreview(
                    page = pages.firstOrNull() ?: CardPage(), theme = theme,
                    pageSize = CardTemplate.previewPageSize(CardFormat.story),
                    height = h, cornerRadius = radius,
                )
            }
        }
        Row(
            Modifier.padding(horizontal = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.size(6.dp).background(GL.green, CircleShape))
            Text(
                "กำลังแสดงอยู่ · ${record.name}", style = sh(12f, SHFont.semibold), color = GL.muted,
                maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f),
            )
            Spacer(Modifier.width(4.dp))
            Text("แตะเพื่อแต่ง", style = sh(12f, SHFont.semibold), color = GL.hint)
        }
    }
}

private fun heroAspect(format: CardFormat): Float = when (format) {
    CardFormat.portfolio -> {
        val g = CardTemplate.thumbGutter
        val p = CardTemplate.previewPageSize(CardFormat.portfolio)
        (p.width * 3 + g * 2 + g * 2) / (p.height + g * 2)
    }
    CardFormat.story -> {
        val p = CardTemplate.previewPageSize(CardFormat.story)
        p.width / p.height
    }
}

/** ปุ่มกระจกสองปุ่มใต้การ์ด (= ปุ่มรองที่เท่ากัน ไม่ใช่ลิงก์) */
@Composable
fun GlassActionButton(title: String, symbol: Ph, action: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier
            .fillMaxWidth()
            .height(44.dp)
            .glShadow(GL.ink.opacity(0.06), 8f, 4f)
            .clip(CircleShape)
            .background(glassWhite(0.6))
            .border(1.dp, Color.White.opacity(0.95), CircleShape)
            .tap {
                Haptics.impact(Haptics.Style.light)
                action()
            },
        horizontalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PIcon(symbol, size = 14f, tint = GL.ink)
        Text(title, style = sh(14f, SHFont.bold), color = GL.ink)
    }
}
