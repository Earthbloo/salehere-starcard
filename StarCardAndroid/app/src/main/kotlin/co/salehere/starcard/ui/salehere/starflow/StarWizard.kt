package co.salehere.starcard.ui.salehere.starflow

import android.graphics.Bitmap
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.keyframes
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.model.LocalStarFlow
import co.salehere.starcard.model.Portfolio
import co.salehere.starcard.model.StarCampaign
import co.salehere.starcard.model.StarDataKey
import co.salehere.starcard.model.StarFlow
import co.salehere.starcard.model.StarRow
import co.salehere.starcard.model.StarSocial
import co.salehere.starcard.model.VerifyStatus
import co.salehere.starcard.model.WizKind
import co.salehere.starcard.model.WizStep
import co.salehere.starcard.model.decodeBitmap
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.dockPress
import co.salehere.starcard.ui.profile.AddTile
import co.salehere.starcard.ui.profile.MediaTile
import co.salehere.starcard.ui.profile.PK
import co.salehere.starcard.ui.profile.PKCircleButton
import co.salehere.starcard.ui.profile.PKPrimaryButton
import co.salehere.starcard.ui.profile.PendingTile
import co.salehere.starcard.ui.profile.VideoSheet
import co.salehere.starcard.ui.salehere.SH
import co.salehere.starcard.ui.tap
import co.salehere.starcard.ui.widgets.FlowLayout
import kotlinx.coroutines.launch
import java.text.NumberFormat
import java.util.Locale
import java.util.UUID
import kotlin.math.max
import kotlin.math.min

/**
 * หน้าแทรก = wizard "หนึ่งคำถามต่อหนึ่งหน้า" (= `wizard()` ใน newflow.js)
 *
 * หัวข้อ 1 บรรทัด · ชิปบอกว่าแบรนด์ใช้ข้อนี้ทำอะไร · ช่องกรอกเดียว · ปุ่มถัดไป · แถบความคืบหน้า
 * ขั้นที่มีข้อมูลแล้วไม่โผล่เลย · หน้าสุดท้ายปุ่มบอกปลายทาง (ฟอร์มสมัคร / หน้าตอบรับ / การ์ด)
 *
 * - onFinish: จบ wizard — `madeCard` = รอบนี้เพิ่งประกอบการ์ดขึ้นมา (ไปหน้าการ์ดเกิดก่อนฟอร์มสมัคร)
 * - onExit: กด ✕ — ผู้เรียกเปิด dialog "เก็บไว้ทำต่อทีหลังไหม" (ส่งจำนวนที่ทำแล้ว/ทั้งหมดไปให้)
 * - onKyc: ออกไปยืนยันตัวตนจริง แล้วเรียก completion ตอนกลับมา
 * - toast: toast ของผู้เรียก
 */
@Composable
fun StarWizard(
    kind: WizKind,
    campaign: StarCampaign,
    steps: List<WizStep>,
    onFinish: (Boolean) -> Unit,
    onExit: (Int, Int) -> Unit,
    onKyc: (() -> Unit) -> Unit,
    toast: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val flow = LocalStarFlow.current
    var list by remember { mutableStateOf(steps) }
    var i by remember { mutableIntStateOf(0) }
    var err by remember { mutableStateOf<String?>(null) }
    var shakes by remember { mutableIntStateOf(0) }

    val real = list.filter { it != WizStep.intro }
    val step = list.getOrNull(i)
    val isLast = i == list.size - 1
    /** ลำดับข้อ (ไม่นับ intro) */
    val n = list.take(i + 1).count { it != WizStep.intro }
    fun stepDone(s: WizStep): Boolean =
        if (s == WizStep.kyc) flow.isVerified else (s.dataKey?.let { flow.has(it) } ?: false)

    // MARK: ลอจิก (= `Ac.wizNext` / `wizSkip` / `wizKyc`)

    fun finish() {
        val madeCard = kind == WizKind.apply &&
            list.any { it == WizStep.socials || it == WizStep.categories || it == WizStep.about || it == WizStep.kyc } &&
            flow.hasCard
        onFinish(madeCard)
    }

    fun advance() {
        if (i < list.size - 1) i += 1 else finish()
    }

    fun fail(msg: String) {
        err = msg
        shakes += 1
        Haptics.rigid()
    }

    fun next() {
        val s = step ?: run { finish(); return }
        if (s == WizStep.socials && flow.connected.isEmpty()) { fail("เชื่อมอย่างน้อย 1 ช่อง"); return }
        if (s == WizStep.kyc && flow.verify == VerifyStatus.none) { fail("ยืนยันตัวตนก่อน แล้วไปต่อได้เลย"); return }
        if (s == WizStep.media) {
            val lack = wzMediaMissing()
            if (lack != null) { fail("ยังขาด $lack"); return }
        }
        err = null
        if (s == WizStep.intro) { i += 1; return }
        if (s == WizStep.insight) {
            if (flow.insightSlots.isNotEmpty()) flow.have = flow.have + StarDataKey.insight
        } else {
            s.dataKey?.let { flow.have = flow.have + it }
        }
        advance()
    }

    fun skip() {
        err = null
        advance()
    }

    /** ออกไปทำ KYC จริงแล้วกลับมา — ตัดขั้น kyc ทิ้งแล้วไปคำถามถัดไปเลย ไม่ต้องกดผ่านหน้า "ยืนยันตัวตนแล้ว" อีก */
    fun startKyc() {
        onKyc done@{
            if (flow.verify == VerifyStatus.none) return@done
            err = null
            list = list.filter { it != WizStep.kyc }
            if (list.isEmpty()) { finish(); return@done }
            i = min(i, list.size - 1)
            toast(if (flow.isVerified) "ยืนยันตัวตนแล้ว · ไปต่อได้เลย" else "ส่งคำขอยืนยันตัวตนแล้ว · สมัครงานต่อได้เลย")
        }
    }

    val context = when (kind) {
        WizKind.one -> if (flow.hasCard) "เติม Star Card" else "สมัครเป็น STAR"
        WizKind.apply -> if (flow.hasCard) "ข้อมูล STAR · ก่อนสมัคร ${campaign.episode}" else "สมัครเป็น STAR · ${campaign.episode}"
        WizKind.accept -> "ข้อมูล STAR · ก่อนตอบรับ ${campaign.episode}"
    }

    val buttonLabel = when {
        kind == WizKind.one && isLast -> "บันทึกลงการ์ด"
        isLast -> when (kind) {
            WizKind.apply -> "ไปฟอร์มสมัคร ${campaign.episode}"
            WizKind.accept -> "ไปหน้าตอบรับ"
            WizKind.one -> "ไปการ์ดของคุณ"
        }
        else -> "ถัดไป"
    }

    fun heading(s: WizStep): String = when (s) {
        WizStep.kind -> "คุณเป็นแบบไหน? 🙋"
        WizStep.socials -> "แปะวาร์ปช่องของคุณเลย 📱"
        WizStep.categories -> "คุณเป็นครีเอเตอร์สายไหน? 🎨"
        WizStep.about -> "แนะนำตัวสั้น ๆ ✍️"
        WizStep.media -> "รูปและผลงานของคุณ 📸"
        WizStep.rate -> "เรทรับงานของคุณ 💸"
        WizStep.insight -> "ข้อมูลผู้ติดตามของคุณ 📊"
        WizStep.province -> "อยู่จังหวัดไหน / ไปถึงไหนได้บ้าง? 📍"
        WizStep.availability -> "ว่างรับงานวันไหน? 📅"
        WizStep.address -> "ส่งของไปที่ไหน? 📦"
        WizStep.bank -> "รับเงินในนามใคร? 🏦"
        WizStep.draftRounds -> "แก้งานให้ได้กี่รอบ?"
        WizStep.kyc -> when {
            flow.isVerified -> "ยืนยันตัวตนแล้ว 🪪"
            flow.verify == VerifyStatus.waiting -> "ส่งยืนยันตัวตนแล้ว 🪪"
            else -> "ยืนยันตัวตนก่อนเป็น STAR 🪪"
        }
        WizStep.intro -> ""
    }

    fun purpose(s: WizStep): String = when (s) {
        WizStep.address -> "ของรางวัลจะส่งมาที่นี่ · กรอกครั้งเดียว"
        WizStep.bank -> if (campaign.fee > 0) "ค่าตัว ฿${NumberFormat.getIntegerInstance(Locale.US).format(campaign.fee)} โอนเข้าบัญชีนี้" else "ใช้กับทุกงานที่มีค่าตัว"
        WizStep.kyc -> when {
            flow.isVerified -> "ป้าย Verified จะขึ้นบนการ์ดของคุณ"
            flow.verify == VerifyStatus.waiting -> "ทีมงานตรวจภายใน 1–3 วันทำการ · สมัครงานต่อได้เลย"
            else -> "ถ่ายบัตรประชาชน + ใบหน้า · ทำครั้งเดียว ใช้ได้ทุกงาน"
        }
        else -> ""
    }

    val screen = when {
        step == null -> 0
        step == WizStep.intro -> 1
        else -> 2
    }

    Box(modifier.fillMaxSize().background(GL.bg)) {
        AnimatedContent(
            targetState = screen,
            transitionSpec = { fadeIn(Motion.settle.float) togetherWith fadeOut(Motion.settle.float) },
            label = "wizScreen",
        ) { sc ->
            when (sc) {
                1 -> WizIntro(
                    campaign = campaign,
                    rest = real,
                    onClose = { onExit(0, real.size) },
                    onNext = { next() },
                )
                2 -> Column(
                    Modifier
                        .fillMaxSize()
                        .statusBarsPadding()
                        .imePadding(),
                ) {
                    val total = real.size
                    Row(
                        Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        PKCircleButton(
                            symbol = if (i > 0) Ph.caretLeft else Ph.x,
                            label = if (i > 0) "ย้อนกลับ" else "ปิด",
                            action = {
                                if (i > 0) { i -= 1; err = null } else onExit(real.count { stepDone(it) }, total)
                            },
                        )
                        Spacer(Modifier.weight(1f))
                        Text(context, style = sh(12.5f, SHFont.semibold), color = PK.hint, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        Spacer(Modifier.weight(1f))
                        Row(
                            Modifier.widthIn(min = 40.dp),
                            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.End),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(if (total > 1) "$n/$total" else "", style = sh(12.5f, SHFont.bold).tnum(), color = GL.ink)
                            if (i > 0) {
                                // ออกได้ทุกขั้น ไม่ต้องถอยกลับไปหา ✕ ที่ขั้นแรก (audit ข้อ 5) — dialog "เก็บไว้ทำต่อ" ตัวเดิม
                                PKCircleButton(symbol = Ph.x, label = "ปิด", action = { onExit(real.count { stepDone(it) }, total) })
                            }
                        }
                    }
                    if (!(kind == WizKind.one && total < 2)) {
                        val frac by animateFloatAsState(n.toFloat() / max(1, total).toFloat(), Motion.settle.float, label = "wizBar")
                        Box(
                            Modifier
                                .padding(horizontal = 20.dp)
                                .padding(top = 10.dp)
                                .fillMaxWidth()
                                .height(3.dp)
                                .background(PK.line, CircleShape),
                        ) {
                            Box(Modifier.fillMaxWidth(frac.coerceIn(0f, 1f)).fillMaxHeight().background(PK.charcoal, CircleShape))
                        }
                    }
                    val current = step ?: WizStep.intro
                    AnimatedContent(
                        targetState = current,
                        modifier = Modifier.weight(1f),
                        transitionSpec = {
                            (slideInHorizontally(Motion.settle.spec()) { it } + fadeIn(Motion.settle.float)) togetherWith
                                fadeOut(Motion.settle.float)
                        },
                        label = "wizStep",
                    ) { s ->
                        Column(
                            Modifier
                                .fillMaxSize()
                                .verticalScroll(rememberScrollState())
                                .padding(horizontal = 20.dp)
                                .padding(top = 28.dp, bottom = 16.dp),
                        ) {
                            Text(heading(s), style = sh(24f, SHFont.heavy).lineSpaced(4f), color = GL.ink)
                            if (s.line.isNotEmpty()) {
                                NudgeChips(lines = s.line, modifier = Modifier.padding(top = 8.dp, bottom = 20.dp))
                            } else {
                                Text(purpose(s), style = sh(14f), color = PK.muted, modifier = Modifier.padding(top = 6.dp, bottom = 22.dp))
                            }
                            AnimatedVisibility(visible = err != null && s == step, enter = fadeIn(Motion.snap.float), exit = fadeOut(Motion.snap.float)) {
                                Text(err ?: "", style = sh(13f, SHFont.semibold), color = PK.red, modifier = Modifier.padding(bottom = 14.dp))
                            }
                            Box(Modifier.wzShake(shakes)) {
                                WizControl(s, onError = { fail(it) }, startKyc = { startKyc() })
                            }
                        }
                    }
                    Column(
                        Modifier
                            .fillMaxWidth()
                            .navigationBarsPadding()
                            .padding(horizontal = 20.dp)
                            .padding(top = 8.dp, bottom = 20.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        PKPrimaryButton(title = buttonLabel, symbol = Ph.arrowRight, action = { next() })
                        if (step?.optional == true) {
                            GlassLink(title = "ข้ามไว้ก่อน", action = { skip() })
                        }
                    }
                }
                else -> Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
                    Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 6.dp)) {
                        PKCircleButton(symbol = Ph.x, label = "ปิด", action = { onExit(0, 0) })
                        Spacer(Modifier.weight(1f))
                    }
                    Spacer(Modifier.weight(1f))
                    Text(
                        "ข้อมูลครบแล้ว", style = sh(24f, SHFont.heavy), color = GL.ink,
                        modifier = Modifier.align(Alignment.CenterHorizontally),
                    )
                    Spacer(Modifier.weight(1f))
                    PKPrimaryButton(
                        title = when (kind) {
                            WizKind.apply -> "ไปฟอร์มสมัคร"
                            WizKind.one -> "กลับไปการ์ด"
                            WizKind.accept -> "ไปหน้าตอบรับ"
                        },
                        symbol = Ph.arrowRight,
                        action = { finish() },
                        modifier = Modifier.padding(horizontal = 20.dp).padding(bottom = 20.dp),
                    )
                }
            }
        }
    }
}

// MARK: หน้าแรกก่อนสมัคร = "สมัครเป็น STAR" (1 เหตุผล + 1 ภาพ + 1 ปุ่ม) (= `wizIntro`)

@Composable
private fun WizIntro(campaign: StarCampaign, rest: List<WizStep>, onClose: () -> Unit, onNext: () -> Unit) {
    val flow = LocalStarFlow.current
    val card = flow.hasCard
    Box(Modifier.fillMaxSize()) {
        GlassOrbs()
        Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                GlassCircleButton(symbol = Ph.x, size = 40f, action = onClose)
                Spacer(Modifier.weight(1f))
                // ชื่อแบรนด์อยู่ในกล่อง "ขอดูก่อนคัดเลือก" แล้ว — บนหัวเหลือแค่ EP
                Text(
                    if (card) "สมัคร ${campaign.episode}" else "สมัคร ${campaign.episode} · ${campaign.brand}",
                    style = sh(12.5f, SHFont.semibold), color = PK.hint, maxLines = 1,
                )
                Spacer(Modifier.weight(1f))
                Gap(40f, 40f)
            }
            Column(
                Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp)
                    .padding(top = 30.dp, bottom = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                if (card) {
                    // เป็น STAR แล้ว — หน้านี้ไม่ใช่เรื่องการ์ด แต่เป็นสิ่งที่แบรนด์ขอดูก่อนคัดเลือก (ผู้ใช้ 24 ก.ย. 2569)
                    GlassTitle(words = listOf("แบรนด์ขอข้อมูลเพิ่ม" to false), small = true)
                    Text(
                        "ใช้คัดเลือกผู้สมัคร · ส่งครบแล้วค่อยไปฟอร์มสมัคร",
                        style = sh(14f), color = GL.muted, textAlign = TextAlign.Center,
                        modifier = Modifier.padding(top = 10.dp),
                    )
                    BrandAsk(campaign = campaign, steps = rest, modifier = Modifier.padding(top = 26.dp).glReveal(1))
                } else {
                    GlassTitle(words = listOf("สมัครเป็น" to false, "STAR" to true, "ก่อน" to false), small = true)
                    Text(
                        "งานนี้รับเฉพาะ STAR · ทำครั้งเดียว ใช้ได้ทุกงาน",
                        style = sh(14f), color = GL.muted, textAlign = TextAlign.Center,
                        modifier = Modifier.padding(top = 10.dp),
                    )
                    StarGlassCard(compact = true, ghosts = rest, modifier = Modifier.padding(top = 26.dp).glReveal(1))
                }
            }
            PKPrimaryButton(
                title = if (card) "เติมข้อมูล ${rest.size} อย่าง" else "สมัครเป็น STAR · ${rest.size} ข้อ",
                symbol = Ph.arrowRight,
                action = onNext,
                modifier = Modifier.padding(horizontal = 20.dp).padding(top = 8.dp, bottom = 20.dp),
            )
        }
    }
}

@Composable
private fun WizControl(s: WizStep, onError: (String) -> Unit, startKyc: () -> Unit) {
    when (s) {
        WizStep.kind -> WzKind()
        WizStep.socials -> WzSocials()
        WizStep.categories -> WzCategories()
        WizStep.about -> WzAbout()
        WizStep.media -> WzMediaAll(onError = onError)
        WizStep.kyc -> WzKyc(start = startKyc)
        WizStep.rate -> WzRate()
        WizStep.insight -> WzInsight()
        WizStep.province -> WzProvince()
        WizStep.availability -> WzAvailability()
        WizStep.address -> WzAddress()
        WizStep.bank -> WzBank()
        WizStep.draftRounds -> WzDraftRounds()
        WizStep.intro -> Unit
    }
}

// MARK: - ช่องกรอกของแต่ละขั้น (= `WZ[key].body`)

@Composable
private fun WzSocials() {
    val flow = LocalStarFlow.current
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        listOf(StarSocial.instagram, StarSocial.tiktok, StarSocial.facebook, StarSocial.youtube).forEach { s ->
            val on = flow.connected.contains(s)
            val shape = RoundedCornerShape(16.dp)
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(shape)
                    .background(if (on) PK.pick else Color.White)
                    .strokeInside(if (on) GL.ink else PK.line, if (on) 1.5f else 1f, radius = 16f)
                    .tap {
                        if (on) return@tap
                        Haptics.impact(Haptics.Style.light)
                        flow.connected = flow.connected + s
                    }
                    .padding(horizontal = 14.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Image(
                    painterResource(s.icon), contentDescription = null, contentScale = ContentScale.Fit,
                    modifier = Modifier.size(36.dp).clip(CircleShape),
                )
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                    Text(s.name, style = sh(15f, SHFont.bold), color = GL.ink)
                    if (on) Text("${StarFlow.fmt(s.followers)} ผู้ติดตาม", style = sh(12.5f), color = PK.muted)
                }
                if (on) {
                    Box(Modifier.size(28.dp).background(GL.ink, CircleShape), contentAlignment = Alignment.Center) {
                        PIcon(Ph.check, size = 16f, tint = Color.White)
                    }
                } else {
                    Box(
                        Modifier.height(30.dp).background(PK.fieldFill, CircleShape).padding(horizontal = 14.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("เชื่อม", style = sh(13f, SHFont.bold), color = GL.ink)
                    }
                }
            }
        }
    }
}

private val categoryList = listOf(
    "💄 บิวตี้", "👗 แฟชั่น", "🍜 อาหาร", "☕️ คาเฟ่", "✨ ไลฟ์สไตล์", "✈️ ท่องเที่ยว", "💪 สุขภาพ", "👶 แม่และเด็ก",
    "🐶 สัตว์เลี้ยง", "📱 เทค", "🎮 เกม", "🎬 บันเทิง", "🎪 อีเวนต์",
)

@Composable
private fun WzCategories() {
    val flow = LocalStarFlow.current
    FlowLayout(spacing = 8f) {
        categoryList.forEach { c ->
            val on = flow.categories.contains(c)
            WzChip(text = c, on = on, action = {
                if (on) flow.categories = flow.categories.filter { it != c }
                else if (flow.categories.size < 5) flow.categories = flow.categories + c
                else Haptics.rigid()
            })
        }
    }
}

@Composable
private fun WzAbout() {
    val flow = LocalStarFlow.current
    var focused by remember { mutableStateOf(false) }
    val shape = RoundedCornerShape(16.dp)
    BasicTextField(
        value = flow.about,
        onValueChange = { flow.about = it },
        textStyle = sh(17f).copy(color = GL.ink),
        cursorBrush = SolidColor(GL.ink),
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 120.dp)
            .clip(shape)
            .background(Color.White)
            .strokeInside(if (focused) GL.ink else PK.line, 1f, radius = 16f)
            .onFocusChanged { focused = it.isFocused }
            .padding(horizontal = 17.dp, vertical = 18.dp),
    )
}

@Composable
private fun WzKyc(start: () -> Unit) {
    val flow = LocalStarFlow.current
    when (flow.verify) {
        VerifyStatus.approved -> KycRow(icon = Ph.check, on = true, title = "Verified by Sale Here", sub = "ขึ้นป้ายบนการ์ดแล้ว")
        VerifyStatus.waiting -> KycRow(icon = Ph.clock, on = false, title = "กำลังตรวจข้อมูล", sub = "เราจะแจ้งเตือนเมื่อผ่าน · ระหว่างนี้สมัครงานได้ตามปกติ")
        VerifyStatus.none -> Column(
            Modifier
                .fillMaxWidth()
                .height(140.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(Color.White)
                .strokeInside(PK.line2, 1.5f, radius = 16f, dash = 6f, gap = 4f)
                .tap {
                    Haptics.impact(Haptics.Style.medium)
                    start()
                },
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
        ) {
            PIcon(Ph.identificationCard, size = 28f, tint = GL.ink)
            Text("เริ่มยืนยันตัวตน", style = sh(15f, SHFont.bold), color = GL.ink)
        }
    }
}

@Composable
private fun KycRow(icon: Ph, on: Boolean, title: String, sub: String) {
    val shape = RoundedCornerShape(16.dp)
    Row(
        Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(if (on) PK.pick else Color.White)
            .strokeInside(if (on) GL.ink else PK.line, if (on) 1.5f else 1f, radius = 16f)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(28.dp).background(if (on) GL.ink else PK.fieldFill, CircleShape), contentAlignment = Alignment.Center) {
            PIcon(icon, size = 16f, tint = if (on) Color.White else GL.ink)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(title, style = sh(15f, SHFont.bold), color = GL.ink)
            Text(sub, style = sh(12.5f), color = PK.muted)
        }
    }
}

@Composable
private fun WzRate() {
    val flow = LocalStarFlow.current
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        StarSocial.entries.filter { flow.connected.contains(it) }.forEach { s ->
            WzGroup(social = s, trailing = "${StarFlow.fmt(s.followers)} ผู้ติดตาม") {
                s.formats.forEach { f ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(f.name, style = sh(14f, SHFont.semibold), color = GL.ink, modifier = Modifier.weight(1f))
                        RateInput(value = flow.rate(s, f), onValueChange = { flow.setRate(s, f, it) })
                    }
                }
            }
        }
    }
}

@Composable
private fun RateInput(value: Int, onValueChange: (Int) -> Unit) {
    var text by remember { mutableStateOf(value.toString()) }
    var focused by remember { mutableStateOf(false) }
    val shape = RoundedCornerShape(14.dp)
    Row(
        Modifier
            .width(150.dp)
            .height(44.dp)
            .clip(shape)
            .background(Color.White)
            .strokeInside(if (focused) GL.ink else PK.line, 1f, radius = 14f)
            .padding(horizontal = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("฿", style = sh(15f, SHFont.semibold), color = PK.hint)
        BasicTextField(
            value = text,
            onValueChange = { t ->
                text = t
                onValueChange(t.filter { it.isDigit() }.toIntOrNull() ?: 0)
            },
            singleLine = true,
            textStyle = sh(16f).copy(color = GL.ink, textAlign = TextAlign.End),
            cursorBrush = SolidColor(GL.ink),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.weight(1f).onFocusChanged { focused = it.isFocused },
        )
        Text("/โพสต์", style = sh(12f, SHFont.semibold), color = PK.hint)
    }
}

/** กล่องรวมต่อช่องโซเชียล (= `.wz-grp`) */
@Composable
private fun WzGroup(social: StarSocial, trailing: String, content: @Composable () -> Unit) {
    val shape = RoundedCornerShape(16.dp)
    Column(
        Modifier
            .fillMaxWidth()
            .background(Color.White, shape)
            .border(1.dp, PK.line, shape)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            Image(
                painterResource(social.icon), contentDescription = null, contentScale = ContentScale.Fit,
                modifier = Modifier.size(24.dp).clip(CircleShape),
            )
            Text(social.name, style = sh(14f, SHFont.bold), color = GL.ink, modifier = Modifier.weight(1f))
            Text(trailing, style = sh(12f, SHFont.semibold), color = PK.hint)
        }
        content()
    }
}

private data class InsightSlot(val key: String, val title: String, val value: String)

private val insightSlotList = listOf(
    InsightSlot("gender", "เพศ", "หญิง 68%"),
    InsightSlot("age", "ช่วงอายุ", "25–34 ปี 42%"),
    InsightSlot("location", "พื้นที่ยอดนิยม", "กรุงเทพฯ 35%"),
)

@Composable
private fun WzInsight() {
    val flow = LocalStarFlow.current
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        StarSocial.entries.filter { flow.connected.contains(it) && it.supportsInsight }.forEach { s ->
            val n = insightSlotList.count { flow.insightSlots.contains("${s.raw}_${it.key}") }
            WzGroup(social = s, trailing = "$n/3") {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    insightSlotList.forEach { slot ->
                        val id = "${s.raw}_${slot.key}"
                        val on = flow.insightSlots.contains(id)
                        val shape = RoundedCornerShape(14.dp)
                        Column(
                            Modifier
                                .weight(1f)
                                .clip(shape)
                                .background(if (on) rgb(242 / 255.0, 251 / 255.0, 246 / 255.0) else GL.bg)
                                .strokeInside(
                                    if (on) GL.green else PK.line2, 1.5f, radius = 14f,
                                    dash = if (on) 0f else 5f, gap = if (on) 0f else 3f,
                                )
                                .tap {
                                    Haptics.impact(Haptics.Style.light)
                                    flow.insightSlots = if (on) flow.insightSlots - id else flow.insightSlots + id
                                }
                                .padding(horizontal = 6.dp, vertical = 8.dp)
                                .heightIn(min = 76.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(3.dp, Alignment.CenterVertically),
                        ) {
                            PIcon(if (on) Ph.check else Ph.plus, size = if (on) 14f else 16f, tint = if (on) GL.green else GL.hint)
                            Text(slot.title, style = sh(12.5f, SHFont.bold), color = GL.ink, textAlign = TextAlign.Center)
                            Text(
                                if (on) slot.value else "แตะเพื่อแนบ",
                                style = sh(11f, if (on) SHFont.semibold else SHFont.regular),
                                color = if (on) GL.greenInk else PK.hint,
                                textAlign = TextAlign.Center,
                            )
                        }
                    }
                }
            }
        }
    }
}

private val provinceList = listOf("กรุงเทพมหานคร", "นนทบุรี", "ปทุมธานี", "สมุทรปราการ", "ชลบุรี", "เชียงใหม่", "ทุกจังหวัด (ออนไลน์)")

@Composable
private fun WzProvince() {
    val flow = LocalStarFlow.current
    FlowLayout(spacing = 8f) {
        provinceList.forEach { p ->
            val on = flow.provinces.contains(p)
            WzChip(text = p, on = on, action = {
                if (on) flow.provinces = flow.provinces.filter { it != p }
                else if (flow.provinces.size < 3) flow.provinces = flow.provinces + p
                else Haptics.rigid()
            })
        }
    }
}

@Composable
private fun WzAvailability() {
    val flow = LocalStarFlow.current
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            listOf("ทุกวัน" to "จันทร์–อาทิตย์", "ส.–อา." to "วันหยุด", "จ.–ศ." to "วันธรรมดา").forEach { (t, s) ->
                WzTile(title = t, sub = s, on = flow.availDays == t, action = { flow.availDays = t }, modifier = Modifier.weight(1f))
            }
        }
        FlowLayout(spacing = 8f) {
            listOf("เช้า", "บ่าย", "เย็น", "ตลอดวัน").forEach { t ->
                WzChip(text = t, on = flow.availTime == t, action = { flow.availTime = t })
            }
        }
    }
}

@Composable
private fun WzAddress() {
    var name by remember { mutableStateOf("มณีรัตน์ ใจดี") }
    var tel by remember { mutableStateOf("0891234567") }
    var address by remember { mutableStateOf("99/12 คอนโดลุมพินี ซ.สุขุมวิท 77") }
    var zip by remember { mutableStateOf("10250") }
    var sub by remember { mutableStateOf("สวนหลวง") }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        WzInput(label = "ชื่อ–นามสกุล", text = name, onTextChange = { name = it })
        WzInput(label = "เบอร์โทรศัพท์", text = tel, onTextChange = { tel = it }, keyboard = KeyboardType.Phone)
        WzInput(label = "ที่อยู่", text = address, onTextChange = { address = it })
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            WzInput(label = "รหัสไปรษณีย์", text = zip, onTextChange = { zip = it }, keyboard = KeyboardType.Number, modifier = Modifier.weight(1f))
            WzInput(label = "ตำบล/แขวง", text = sub, onTextChange = { sub = it }, select = true, modifier = Modifier.weight(1f))
        }
    }
}

/**
 * การรับเงิน = `PAYDOC` ของฟอร์มเว็บ v16.1: เลือกนามบุคคล/นามบริษัทก่อน แล้วช่องเปลี่ยนตามชุดนั้น
 * (ผู้ใช้ 24 ก.ย. 2569: "ตอนรับงานต้องถามด้วยว่านามบุคคล/บริษัท")
 */
@Composable
private fun WzBank() {
    val flow = LocalStarFlow.current
    var bank by remember { mutableStateOf("กสิกรไทย") }
    var no by remember { mutableStateOf("") }
    var name by remember { mutableStateOf("มณีรัตน์ ใจดี") }
    var coName by remember { mutableStateOf("") }
    var taxID by remember { mutableStateOf("") }
    var branch by remember { mutableStateOf("สำนักงานใหญ่") }
    var address by remember { mutableStateOf("") }
    var signer by remember { mutableStateOf("") }
    var vat by remember { mutableStateOf("จดทะเบียน VAT (มี ภ.พ.20)") }
    var shot by remember { mutableStateOf(false) }
    val company = flow.payKind == "company"

    Column(
        Modifier.animateContentSize(Motion.snap.spec()),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            BankKindTile("person", Ph.user, "นามบุคคล", "หัก ณ ที่จ่าย 3%", Modifier.weight(1f))
            BankKindTile("company", Ph.buildings, "นามบริษัท", "หัก ณ ที่จ่าย 7%", Modifier.weight(1f))
        }
        Text(
            if (company) "ชื่อบัญชีต้องตรงกับชื่อนิติบุคคลเป๊ะ ๆ รวมคำว่า \"บริษัท\" และ \"จำกัด\""
            else "ชื่อบัญชีต้องตรงกับชื่อ–นามสกุลจริงของคุณ ไม่งั้นเงินจะโอนไม่เข้า",
            style = sh(12.5f), color = PK.muted, modifier = Modifier.padding(bottom = 2.dp),
        )
        if (company) {
            WzInput(label = "ชื่อนิติบุคคล", text = coName, onTextChange = { coName = it }, placeholder = "บริษัท ... จำกัด")
            WzInput(label = "เลขประจำตัวผู้เสียภาษี (13 หลัก)", text = taxID, onTextChange = { taxID = it }, placeholder = "0xxxxxxxxxxxx", keyboard = KeyboardType.Number)
            WzInput(label = "สำนักงานใหญ่ / สาขา", text = branch, onTextChange = { branch = it }, select = true)
            WzInput(label = "ที่อยู่ตามหนังสือรับรอง", text = address, onTextChange = { address = it }, placeholder = "เลขที่ ถนน แขวง เขต จังหวัด รหัสไปรษณีย์")
            WzInput(label = "ชื่อกรรมการผู้มีอำนาจลงนาม", text = signer, onTextChange = { signer = it }, placeholder = "ชื่อ–นามสกุล ตามหนังสือรับรอง")
            WzInput(label = "จดทะเบียน VAT หรือไม่", text = vat, onTextChange = { vat = it }, select = true)
        }
        WzInput(label = "ธนาคาร", text = bank, onTextChange = { bank = it }, select = true)
        WzInput(label = "เลขที่บัญชี", text = no, onTextChange = { no = it }, placeholder = "xxx-x-xxxxx-x", keyboard = KeyboardType.Number)
        WzInput(label = "ชื่อบัญชี", text = name, onTextChange = { name = it }, placeholder = if (company) "ตามชื่อนิติบุคคล" else "ตามหน้าสมุดบัญชี")
        if (!company) {
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                PIcon(Ph.checkCircle, size = 14f, weight = PhWeight.fill, tint = GL.green)
                Text("ชื่อตรงกับบัตรที่ยืนยันแล้ว", style = sh(12.5f, SHFont.semibold), color = GL.green)
            }
        }
        val shotFill by animateColorAsState(if (shot) PK.pick else Color.White, Motion.snap.spec(), label = "bookShot")
        Row(
            Modifier
                .fillMaxWidth()
                .height(88.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(shotFill)
                .strokeInside(
                    if (shot) GL.ink else PK.line2, 1.5f, radius = 16f,
                    dash = if (shot) 0f else 6f, gap = if (shot) 0f else 4f,
                )
                .tap {
                    Haptics.impact(Haptics.Style.light)
                    shot = !shot
                },
            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PIcon(if (shot) Ph.check else Ph.camera, size = 22f, tint = GL.ink)
            Text(
                if (shot) "แนบหน้าสมุดบัญชีแล้ว" else (if (company) "ถ่ายหน้าสมุดบัญชีบริษัท" else "ถ่ายหน้าสมุดบัญชี"),
                style = sh(15f, SHFont.bold), color = GL.ink,
            )
        }
        Text(
            if (company) "ขอทีหลัง: หนังสือรับรองบริษัท (ไม่เกิน 6 เดือน) · ภ.พ.20 ถ้าจด VAT" else "ขอทีหลัง: สำเนาบัตรประชาชน เซ็นรับรองสำเนาถูกต้อง",
            style = sh(11.5f), color = PK.hint,
        )
    }
}

@Composable
private fun BankKindTile(key: String, icon: Ph, title: String, sub: String, modifier: Modifier) {
    val flow = LocalStarFlow.current
    val on = flow.payKind == key
    val shape = RoundedCornerShape(16.dp)
    Column(
        modifier
            .clip(shape)
            .background(if (on) PK.pick else Color.White)
            .strokeInside(if (on) GL.ink else PK.line, if (on) 1.5f else 1f, radius = 16f)
            .tap {
                Haptics.impact(Haptics.Style.light)
                flow.payKind = key
            }
            .padding(vertical = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        PIcon(icon, size = 22f, weight = PhWeight.regular, tint = GL.ink)
        Text(title, style = sh(14f, SHFont.bold), color = GL.ink)
        Text(sub, style = sh(11.5f), color = PK.muted)
    }
}

@Composable
private fun WzDraftRounds() {
    val flow = LocalStarFlow.current
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        (1..3).forEach { n ->
            WzTile(title = n.toString(), sub = "ครั้ง", on = flow.draftRounds == n, action = { flow.draftRounds = n }, modifier = Modifier.weight(1f))
        }
    }
}

/** สั่นซ้ายขวาตอนกดถัดไปทั้งที่ยังไม่ผ่านเงื่อนไข (= `.shake` ของเว็บ · `WzShake`) */
@Composable
fun Modifier.wzShake(trigger: Int): Modifier {
    val x = remember { Animatable(0f) }
    val start = remember { trigger }
    LaunchedEffect(trigger) {
        if (trigger == start) return@LaunchedEffect
        x.snapTo(0f)
        x.animateTo(0f, keyframes {
            durationMillis = 320
            -8f at 60
            8f at 120
            -5f at 180
            5f at 240
        })
    }
    return this.graphicsLayer { translationX = x.value.dp.toPx() }
}

private data class KindOption(val key: String, val icon: Ph, val title: String, val sub: String)

/** Creator (บุคคล) / Page (เพจ) — ขั้น `type` ของฟอร์มเว็บ v16.1 (ไอคอนในกล่องแดงอ่อน · ชื่อ · คำอธิบาย · วงกลมเลือก) */
@Composable
private fun WzKind() {
    val flow = LocalStarFlow.current
    val options = listOf(
        KindOption("creator", Ph.user, "Creator (บุคคล)", "ตัวคุณเองเป็นคนสร้างคอนเทนต์"),
        KindOption("page", Ph.browsers, "Page (เพจ)", "บริหารเพจ/สื่อในนามทีมหรือแบรนด์"),
    )
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        options.forEach { o ->
            val on = flow.creatorKind == o.key
            val shape = RoundedCornerShape(18.dp)
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(shape)
                    .background(if (on) PK.pick else Color.White)
                    .strokeInside(if (on) GL.ink else PK.line, if (on) 1.5f else 1f, radius = 18f)
                    .tap {
                        Haptics.impact(Haptics.Style.light)
                        flow.creatorKind = o.key
                    }
                    .padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.size(48.dp).background(PK.redTint, RoundedCornerShape(12.dp)), contentAlignment = Alignment.Center) {
                    PIcon(o.icon, size = 22f, weight = PhWeight.regular, tint = PK.red)
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text(o.title, style = sh(16f, SHFont.bold), color = GL.ink)
                    Text(o.sub, style = sh(13f), color = PK.muted)
                }
                Box(Modifier.size(22.dp).strokeInside(if (on) GL.ink else PK.line2, if (on) 6f else 1.2f))
            }
        }
    }
}

// MARK: - รูปและผลงาน — ขั้นเดียวก่อนเป็น STAR: รูปของคุณ · รูปผลงาน · วิดีโอผลงาน (ผู้ใช้ 24 ก.ย. 2569)

/** ข้อที่ยังไม่ถึงขั้นต่ำ (null = ครบ) — ข้อความบอกว่าขาดอะไรเท่าไร (= `WzMediaAll.missing()`) */
private fun wzMediaMissing(): String? {
    val f = Portfolio.shared
    val lack = mutableListOf<String>()
    if (f.creatorImages.size < StarFlow.minPhotos) lack += "รูปของคุณ ${StarFlow.minPhotos - f.creatorImages.size} รูป"
    if (f.works.size < StarFlow.minWorks) lack += "รูปผลงาน ${StarFlow.minWorks - f.works.size} รูป"
    if (f.videos.size < StarFlow.minVideos) lack += "คลิป ${StarFlow.minVideos - f.videos.size} คลิป"
    return if (lack.isEmpty()) null else lack.joinToString(" · ")
}

/** สามหมวดในหน้าเดียว — หัวหมวดบอกขั้นต่ำ ครบแล้วขึ้นเครื่องหมายถูกสีเขียว */
@Composable
private fun WzMediaAll(onError: (String) -> Unit) {
    val folio = Portfolio.shared
    Column(verticalArrangement = Arrangement.spacedBy(22.dp)) {
        MediaSection("รูปของคุณ", have = folio.creatorImages.size, min = StarFlow.minPhotos, note = null) {
            WzMedia(kind = WzMediaKind.photos, onError = onError)
        }
        MediaSection("รูปผลงาน", have = folio.works.size, min = StarFlow.minWorks, note = "อย่างน้อย ${StarFlow.minWorks}") {
            WzMedia(kind = WzMediaKind.works, onError = onError)
        }
        MediaSection(
            "วิดีโอผลงาน", have = folio.videos.size, min = StarFlow.minVideos,
            note = "อย่างน้อย ${StarFlow.minVideos} · ไฟล์ละไม่เกิน ${Portfolio.videoMaxMB} MB",
        ) {
            WzMedia(kind = WzMediaKind.videos, onError = onError)
        }
    }
}

@Composable
private fun MediaSection(title: String, have: Int, min: Int, note: String?, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(title, style = sh(15f, SHFont.bold), color = GL.ink)
            if (note != null) {
                Text(note, style = sh(12f), color = PK.hint, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
            }
            Spacer(Modifier.weight(1f).widthIn(min = 4.dp))
            if (have >= min) {
                PIcon(Ph.checkCircle, size = 16f, weight = PhWeight.fill, tint = GL.green)
            } else {
                Text("$have/$min", style = sh(12.5f, SHFont.bold).tnum(), color = PK.hint)
            }
        }
        content()
    }
}

// เก็บลง `Portfolio` ที่เดียวกับหน้าแก้ไขโปรไฟล์ — การ์ดอ่านจากที่นี่ทันที · ใช้ช่องรูปชุดเดียวกัน (MediaTile / AddTile)

private enum class WzMediaKind { photos, works, videos }

private sealed class Removal {
    data class Creator(val i: Int) : Removal()
    data class Work(val id: UUID) : Removal()
    data class Video(val id: UUID) : Removal()
}

@Composable
private fun WzMedia(kind: WzMediaKind, onError: (String) -> Unit) {
    val folio = Portfolio.shared
    var importing by remember { mutableIntStateOf(0) }
    var removal by remember { mutableStateOf<Removal?>(null) }
    var playing by remember { mutableStateOf<Portfolio.Video?>(null) }
    var launchLimit by remember { mutableIntStateOf(1) }
    val scope = rememberCoroutineScope()

    val maxCount = when (kind) {
        WzMediaKind.photos -> Portfolio.creatorSlots
        WzMediaKind.works -> Portfolio.workMax
        WzMediaKind.videos -> Portfolio.videoMax
    }
    val have = when (kind) {
        WzMediaKind.photos -> folio.creatorImages.size
        WzMediaKind.works -> folio.works.size
        WzMediaKind.videos -> folio.videos.size
    }
    val left = max(0, maxCount - have - importing)

    /** ทีละชิ้น — ชิ้นที่โหลดเสร็จขึ้นก่อน (แบบเดียวกับหน้าแก้ไขโปรไฟล์) */
    fun load(items: List<Uri>) {
        if (items.isEmpty()) return
        importing = items.size
        scope.launch {
            var failed = 0
            var tooBig = 0
            for (item in items) {
                when (kind) {
                    WzMediaKind.photos, WzMediaKind.works -> {
                        val img = MediaPicker.image(item)
                        if (img != null) {
                            if (kind == WzMediaKind.works) folio.addWorks(listOf(img))
                            else {
                                val slot = folio.creators.indexOfFirst { it == null }
                                if (slot >= 0) folio.setCreator(img, slot)
                            }
                        } else failed += 1
                    }
                    WzMediaKind.videos -> when (folio.addVideo(MediaPicker.movie(item))) {
                        Portfolio.VideoResult.added -> Unit
                        Portfolio.VideoResult.tooBig -> tooBig += 1
                        Portfolio.VideoResult.failed -> failed += 1
                    }
                }
                importing = max(0, importing - 1)
            }
            importing = 0
            if (tooBig > 0) onError("คลิปใหญ่เกิน ${Portfolio.videoMaxMB} MB — ตัดให้สั้นลงแล้วลองใหม่")
            else if (failed > 0) onError(if (kind == WzMediaKind.videos) "โหลดคลิปไม่สำเร็จ ลองเลือกใหม่อีกครั้ง" else "โหลดรูปไม่สำเร็จ $failed รูป ลองเลือกใหม่")
            else Haptics.impact(Haptics.Style.medium)
        }
    }

    val contract = remember(max(2, left)) { MediaPicker.contract(left) }
    val launcher = rememberLauncherForActivityResult(contract) { uris -> load(uris.take(max(1, launchLimit))) }

    val cells = mutableListOf<@Composable () -> Unit>()
    val adder: (String) -> Unit = { label ->
        cells.add {
            Box(
                Modifier.dockPress {
                    Haptics.impact(Haptics.Style.light)
                    launchLimit = max(1, left)
                    launcher.launch(MediaPicker.request(videos = kind == WzMediaKind.videos))
                },
            ) { AddTile(label = label, ratio = 1f) }
        }
    }
    when (kind) {
        WzMediaKind.photos -> for (i in 0 until Portfolio.creatorSlots) {
            val img = folio.creators.getOrNull(i)
            when {
                img != null -> cells.add { MediaTile(image = img, ratio = 1f, onTap = {}, onRemove = { removal = Removal.Creator(i) }) }
                folio.creators.take(i).count { it == null } < importing -> cells.add { PendingTile(ratio = 1f) }
                else -> adder("รูปที่ ${i + 1}")
            }
        }
        WzMediaKind.works -> {
            folio.works.forEach { w -> cells.add { MediaTile(image = w.image, ratio = 1f, onTap = {}, onRemove = { removal = Removal.Work(w.id) }) } }
            repeat(importing) { cells.add { PendingTile(ratio = 1f) } }
            if (left > 0) adder("เพิ่มรูป")
        }
        WzMediaKind.videos -> {
            folio.videos.forEach { v ->
                cells.add {
                    MediaTile(image = v.thumb, duration = v.duration, ratio = 1f, onTap = { playing = v }, onRemove = { removal = Removal.Video(v.id) })
                }
            }
            repeat(importing) { cells.add { PendingTile(ratio = 1f) } }
            if (left > 0) adder("เพิ่มคลิป")
        }
    }

    Column(Modifier.animateContentSize(Motion.settle.spec()), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        cells.chunked(3).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                row.forEach { c -> Box(Modifier.weight(1f)) { c() } }
                repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
            }
        }
    }

    removal?.let { r ->
        ActionSheet(
            title = if (kind == WzMediaKind.videos) "ลบคลิปนี้?" else "ลบรูปนี้?",
            action = "ลบ",
            onAction = {
                when (r) {
                    is Removal.Creator -> folio.clearCreator(r.i)
                    is Removal.Work -> folio.removeWork(r.id)
                    is Removal.Video -> folio.removeVideo(r.id)
                }
                removal = null
            },
            onCancel = { removal = null },
        )
    }
    playing?.let { v ->
        Dialog(
            onDismissRequest = { playing = null },
            properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
        ) {
            VideoSheet(url = v.file, modifier = Modifier.fillMaxSize(), onClose = { playing = null })
        }
    }
}

/**
 * ตัวเลือกรูป/วิดีโอของระบบ (= `MediaPicker` ที่เปิด PHPicker ตรงจาก UIKit)
 * Android ใช้ Photo Picker ผ่าน `rememberLauncherForActivityResult` — ที่นี่เก็บสัญญา/คำขอ/ตัวถอดรูปไว้ที่เดียว
 */
object MediaPicker {
    /** Photo Picker หลายรูป — ระบบรับขั้นต่ำ 2 · ผู้เรียกตัดส่วนเกินเหลือเท่าที่ช่องว่างจริง */
    fun contract(limit: Int): ActivityResultContracts.PickMultipleVisualMedia =
        ActivityResultContracts.PickMultipleVisualMedia(max(2, limit))

    fun request(videos: Boolean): PickVisualMediaRequest =
        PickVisualMediaRequest(
            if (videos) ActivityResultContracts.PickVisualMedia.VideoOnly
            else ActivityResultContracts.PickVisualMedia.ImageOnly,
        )

    suspend fun image(uri: Uri): Bitmap? = decodeBitmap(uri)

    /** ไฟล์ที่ Photo Picker ให้มาอ่านได้ตลอดช่วงที่แอปถือ uri — `Portfolio.addVideo` คัดลอกออกมาเองอยู่แล้ว */
    fun movie(uri: Uri): Uri = uri
}

/**
 * "แบรนด์ขอดู" — กล่องคำขอจากแบรนด์ของงานนี้ (หน้า intro ตอนเป็น STAR แล้วแต่ข้อมูลยังขาด)
 * โลโก้ + ชื่อแบรนด์ แล้วทีละแถว: ข้อที่ขาด + แบรนด์ใช้ข้อนี้ทำอะไร · ไม่มีเลขลำดับ ไม่ใช่ภาพการ์ด
 */
@Composable
private fun BrandAsk(campaign: StarCampaign, steps: List<WizStep>, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(24.dp)
    Column(
        modifier
            .fillMaxWidth()
            .glShadow(GL.ink.opacity(0.07), 18f, 12f, corner = 24f)
            .clip(shape)
            .background(Color.White.opacity(0.62))
            .border(1.dp, Color.White.opacity(0.9), shape)
            .padding(16.dp),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(bottom = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // = `StarBrandLogo(name:size:)` ของหน้าแรก — วาดตรงนี้เพราะโลโก้ของแคมเปญเป็น drawable id
            Image(
                painterResource(campaign.logo), contentDescription = null, contentScale = ContentScale.Crop,
                modifier = Modifier.size(34.dp).clip(CircleShape).border(1.dp, SH.line, CircleShape),
            )
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                Text(campaign.brand, style = sh(14.5f, SHFont.bold), color = GL.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text("ขอดูก่อนคัดเลือก", style = sh(12.5f), color = GL.muted)
            }
            PIcon(Ph.eye, size = 16f, tint = GL.goldInk)
        }
        steps.forEach { st ->
            Row(
                Modifier.fillMaxWidth().topHairline(GL.ink.opacity(0.07)).padding(vertical = 9.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(
                    Modifier
                        .size(38.dp)
                        .background(Color.White.opacity(0.7), RoundedCornerShape(11.dp))
                        .strokeInside(GL.ink.opacity(0.22), 1f, radius = 11f, dash = 3f, gap = 3f),
                    contentAlignment = Alignment.Center,
                ) {
                    PIcon(brandAskIcon(st), size = 18f, tint = GL.ink)
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                    Text(st.name, style = sh(15f, SHFont.bold), color = GL.ink)
                    st.line.firstOrNull()?.let { why ->
                        Text(why, style = sh(12.5f), color = GL.muted, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                }
            }
        }
    }
}

private fun brandAskIcon(s: WizStep): Ph {
    if (s == WizStep.kyc) return Ph.sealCheck
    if (s == WizStep.kind) return Ph.user
    return StarRow.all.firstOrNull { it.key == s.dataKey }?.icon ?: Ph.circleDashed
}
