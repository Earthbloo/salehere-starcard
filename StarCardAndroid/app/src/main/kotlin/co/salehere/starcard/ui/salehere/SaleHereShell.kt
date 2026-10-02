package co.salehere.starcard.ui.salehere

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
import androidx.compose.animation.EnterExitState
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import co.salehere.starcard.StarCardIntent
import co.salehere.starcard.StarCardSpace
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.model.CampaignPhase
import co.salehere.starcard.model.CardLibrary
import co.salehere.starcard.model.CardStore
import co.salehere.starcard.model.FlowDialog
import co.salehere.starcard.model.FlowScreen
import co.salehere.starcard.model.LocalStarFlow
import co.salehere.starcard.model.OrderPhase
import co.salehere.starcard.model.StarCampaign
import co.salehere.starcard.model.StarFlow
import co.salehere.starcard.model.VerifyStatus
import co.salehere.starcard.model.WizKind
import co.salehere.starcard.model.WizStep
import co.salehere.starcard.pageSlide
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.LocalDismiss
import co.salehere.starcard.ui.salehere.starflow.AcceptPage
import co.salehere.starcard.ui.salehere.starflow.FlowButton
import co.salehere.starcard.ui.salehere.starflow.FlowLab
import co.salehere.starcard.ui.salehere.starflow.FlowModal
import co.salehere.starcard.ui.salehere.starflow.FlowToast
import co.salehere.starcard.ui.salehere.starflow.GlassCircleButton
import co.salehere.starcard.ui.salehere.starflow.KycMockPage
import co.salehere.starcard.ui.salehere.starflow.LabFab
import co.salehere.starcard.ui.salehere.starflow.RegisterFormPage
import co.salehere.starcard.ui.salehere.starflow.RegisterSuccessDialog
import co.salehere.starcard.ui.salehere.starflow.StarGround
import co.salehere.starcard.ui.salehere.starflow.StarHeader
import co.salehere.starcard.ui.salehere.starflow.StarPage
import co.salehere.starcard.ui.salehere.starflow.StarPageMode
import co.salehere.starcard.ui.salehere.starflow.StarWizard
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * แอป Sale Here จำลอง — สองแท็บ (หน้าแรก = Sale Here STAR · โปรไฟล์) ครอบ Star Card ไว้
 *
 * เลียนแบบ flow เดิมของแอปหลัก 22 ก.ย. 2569 · ตั้งแต่ 23 ก.ย. ครอบ **flow ใหม่** (ถอดจาก unbox-mock/new.html) ไว้ด้วย:
 * ไม่แก้หน้าเดิม แค่แทรกหน้ากรอกข้อมูล Star Profile ก่อนถึงหน้าเดิม
 * ทั้งชุดไม่ใช้ navigation library — สลับหน้าด้วย state + transition · ปุ่มย้อนของระบบปิดชั้นบนสุด
 */
@Composable
fun SaleHereShell(modifier: Modifier = Modifier) {
    val scope = rememberCoroutineScope()
    val st = remember { ShellState(scope) }
    val flow = st.flow

    // ตู้ widget ขอไปดูงานที่เปิดรับ → กลับแท็บหน้าแรก (รายการกิจกรรม STAR)
    val jobs = flow.jobsRequested
    LaunchedEffect(jobs) {
        if (!jobs) return@LaunchedEffect
        flow.jobsRequested = false
        // พื้นที่ Star Card ปิดตัวเองด้วย `onExit` อยู่แล้ว — ปิดซ้ำที่นี่กันจังหวะ effect สองตัวสวนกัน (ผลเท่าเดิม)
        st.creatorIntent = null
        st.screen = null
        st.openCampaign = null
        st.tab = SHTab.home
        st.toast("รับงานแรกให้จบ แล้วใบแบรนด์/ผลงานยืนยันจะเปิดเอง")
    }

    // ชั้นล่างสุด: อยู่แท็บโปรไฟล์ → ย้อน = กลับหน้าแรก (ชั้นที่เปิดทับลงทะเบียนทีหลังจึงได้ก่อนเสมอ)
    BackHandler(enabled = st.tab != SHTab.home) { st.tab = SHTab.home }

    val first = CardLibrary.shared.displayOrder.firstOrNull()
    val publishedTheme: CardTheme? = remember(first) { first?.let { CardStore.restore(it.snapshot)?.theme } }
    val cardK by animateFloatAsState(if (st.isCard) 1f else 0f, Motion.page.float, label = "flowBehindCard")

    CompositionLocalProvider(LocalStarFlow provides flow) {
        Box(modifier.fillMaxSize().background(SH.page)) {
            // แท็บ
            Column(Modifier.fillMaxSize().zIndex(0f)) {
                Crossfade(
                    targetState = st.tab, animationSpec = Motion.settle.spec(), label = "shTab",
                    modifier = Modifier.weight(1f).fillMaxWidth(),
                ) { t ->
                    when (t) {
                        SHTab.home -> StarHomePage(
                            campaigns = st.campaigns,
                            onOpen = { c ->
                                Haptics.impact(Haptics.Style.light)
                                st.openCampaign = c
                            },
                        )
                        SHTab.profile -> SaleHereProfilePage(
                            onCreatorProfile = { st.openCreatorProfile() },
                            campaignCount = 15,
                            onLab = { st.showLab = true },
                        )
                    }
                }
                SHTabBar(tab = st.tab, onTabChange = { st.tab = it })
            }

            // กิจกรรมที่เปิดอ่านทับหน้าแรก
            AnimatedContent(
                targetState = st.openCampaign,
                modifier = Modifier.fillMaxSize().zIndex(1f),
                transitionSpec = {
                    slideInHorizontally(Motion.page.spec()) { it } togetherWith
                        slideOutHorizontally(Motion.page.spec()) { it } using null
                },
                contentKey = { it?.id },
                label = "campaign",
            ) { c ->
                if (c != null) {
                    Box(Modifier.fillMaxSize().shBlockTouches()) {
                        BackHandler(enabled = st.openCampaign == c) { st.openCampaign = null }
                        StarCampaignPage(
                            campaign = c,
                            onBack = { st.openCampaign = null },
                            onMain = { st.tapMain() },
                            onFill = { st.open(FlowScreen.StarProfile) },
                            onLab = { st.showLab = true },
                        )
                    }
                }
            }

            // พื้น + ดวงไฟที่เดินทางระหว่างสองหน้า — อยู่ใต้ทั้ง Star Profile และ Star Card
            AnimatedVisibility(
                visible = st.starStage,
                modifier = Modifier.fillMaxSize().zIndex(1.5f),
                enter = fadeIn(Motion.page.spec()),
                exit = fadeOut(Motion.page.spec()),
            ) {
                Box(Modifier.fillMaxSize().shBlockTouches()) {
                    StarGround(isCard = st.isCard, theme = st.lampTheme ?: publishedTheme, modifier = Modifier.fillMaxSize())
                }
            }

            // หน้าของ flow ใหม่ — ตอน Star Card เปิดทับ หน้าโปรไฟล์ถอยไปข้างหลังเล็กน้อย (หัวร่วมกับพื้นไม่ขยับ)
            val slot = st.screen?.let { FlowSlot(it, st.flowKey(it)) }
            AnimatedContent(
                targetState = slot,
                modifier = Modifier
                    .fillMaxSize()
                    .zIndex(2f)
                    .graphicsLayer {
                        translationX = -48.dp.toPx() * cardK
                        val s = 1f - 0.04f * cardK
                        scaleX = s
                        scaleY = s
                        alpha = (1f - cardK).coerceIn(0f, 1f)
                    },
                transitionSpec = {
                    (slideInHorizontally(Motion.page.spec()) { it } + fadeIn(Motion.page.spec())) togetherWith
                        fadeOut(Motion.page.spec()) using null
                },
                contentKey = { it?.key },
                label = "flowScreen",
            ) { s ->
                if (s != null) {
                    Box(Modifier.fillMaxSize().shBlockTouches()) {
                        BackHandler(enabled = st.screen == s.screen && st.creatorIntent == null) { st.backFromScreen(s.screen) }
                        ShellFlowView(st, s.screen)
                    }
                }
            }

            // พื้นที่ Star Card เปิดทับ — ไหลจากขวา 72pt พร้อมจาง (`pageSlide`)
            AnimatedVisibility(
                visible = st.creatorIntent != null,
                modifier = Modifier.fillMaxSize().zIndex(3f),
                enter = EnterTransition.None,
                exit = ExitTransition.None,
            ) {
                val p by transition.animateFloat(transitionSpec = { Motion.page.spec() }, label = "pageSlide") { state ->
                    if (state == EnterExitState.Visible) 1f else 0f
                }
                val intent = rememberShLast(st.creatorIntent)
                if (intent != null) {
                    key(intent.id) {
                        StarCardSpace(
                            intent = intent,
                            onExit = { st.creatorIntent = null },
                            onFocusTheme = { st.lampTheme = it },
                            onGalleryVisible = { v -> st.galleryVisible = v },
                            modifier = Modifier.fillMaxSize().pageSlide(p).shBlockTouches(),
                        )
                    }
                }
            }

            // หัวร่วม: "Star Profile/Card" — ชิ้นเดียว อยู่ที่เดิมทั้งสองหน้า
            AnimatedVisibility(
                visible = st.starStage && (st.creatorIntent == null || st.galleryVisible),
                modifier = Modifier.fillMaxSize().zIndex(3.5f),
                enter = fadeIn(Motion.page.spec()),
                exit = fadeOut(Motion.page.spec()),
            ) {
                Column(Modifier.fillMaxWidth().windowInsetsPadding(WindowInsets.statusBars).padding(top = 50.dp)) {
                    StarHeader(
                        isCard = st.isCard,
                        hasCard = flow.hasCard,
                        showsDot = CardLibrary.shared.records.isNotEmpty(),
                        showsToggle = false,
                        onToggle = { toCard -> st.creatorIntent = if (toCard) StarCardIntent.Gallery else null },
                    )
                }
            }

            // หน้า Star Card = หน้าลึกลงไปจาก Star Profile — ‹ ที่เดียวกับปุ่มกลับของหน้า Profile (แทน toggle)
            AnimatedVisibility(
                visible = st.isCard && st.galleryVisible,
                modifier = Modifier.fillMaxSize().zIndex(3.6f),
                enter = fadeIn(Motion.page.spec()),
                exit = fadeOut(Motion.page.spec()),
            ) {
                Row(
                    Modifier
                        .fillMaxWidth()
                        .windowInsetsPadding(WindowInsets.statusBars)
                        .padding(horizontal = 16.dp)
                        .padding(top = 8.dp),
                ) {
                    GlassCircleButton(symbol = Ph.caretLeft, action = { st.creatorIntent = null })
                    Spacer(Modifier.weight(1f))
                }
            }

            // ปุ่ม Lab ลอยอยู่ทุกหน้าทุกที่ (รวมห้องแต่ง/คลัง) — เครื่องมือทดสอบ ไม่ใช่ UI จริง
            Box(Modifier.fillMaxSize().zIndex(20f)) {
                LabFab(action = { if (!st.showLab) st.showLab = true })
            }

            // ยืนยันตัวตนเปิดทับทุกอย่าง · completion = กลับมาที่หน้าเดิม
            AnimatedContent(
                targetState = st.kyc,
                modifier = Modifier.fillMaxSize().zIndex(3f),
                transitionSpec = {
                    slideInVertically(Motion.page.spec()) { it } togetherWith
                        slideOutVertically(Motion.page.spec()) { it } using null
                },
                contentKey = { it != null },
                label = "kyc",
            ) { done ->
                if (done != null) {
                    Box(Modifier.fillMaxSize().shBlockTouches()) {
                        BackHandler(enabled = st.kyc != null) { st.kyc = null }
                        KycMockPage(
                            onClose = { st.kyc = null },
                            onDone = {
                                st.kyc = null
                                done()
                            },
                        )
                    }
                }
            }

            AnimatedContent(
                targetState = st.dialog,
                modifier = Modifier.fillMaxSize().zIndex(4f),
                transitionSpec = { fadeIn(Motion.snap.spec()) togetherWith fadeOut(Motion.snap.spec()) using null },
                label = "flowDialog",
            ) { d ->
                if (d != null) {
                    Box(Modifier.fillMaxSize().shBlockTouches()) {
                        BackHandler(enabled = st.dialog == d) { st.dialog = null }
                        ShellDialog(st, d)
                    }
                }
            }

            // toast ไม่รับแตะ — ลอยเหนือแถบล่าง
            AnimatedContent(
                targetState = st.toastText,
                modifier = Modifier.fillMaxSize().zIndex(5f),
                transitionSpec = {
                    (slideInVertically(Motion.snap.spec()) { it } + fadeIn(Motion.snap.spec())) togetherWith
                        (slideOutVertically(Motion.snap.spec()) { it } + fadeOut(Motion.snap.spec())) using null
                },
                contentKey = { it != null },
                label = "flowToast",
            ) { t ->
                if (t != null) {
                    Box(
                        Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.navigationBars),
                        contentAlignment = Alignment.BottomCenter,
                    ) {
                        FlowToast(text = t)
                    }
                }
            }

            // แผง lab เต็มจอ (= fullScreenCover ไม่ใช่ sheet — sheet ย่อหน้าข้างใต้แล้วตู้ widget วัดความกว้างใหม่ทุกเฟรม)
            AnimatedVisibility(
                visible = st.showLab,
                modifier = Modifier.fillMaxSize().zIndex(30f),
                enter = slideInVertically(Motion.page.spec()) { it },
                exit = slideOutVertically(Motion.page.spec()) { it },
            ) {
                Box(
                    Modifier
                        .fillMaxSize()
                        .background(Color.White)
                        .shBlockTouches()
                        .windowInsetsPadding(WindowInsets.safeDrawing),
                ) {
                    BackHandler(enabled = st.showLab) { st.closeLab() }
                    CompositionLocalProvider(LocalDismiss provides { st.closeLab() }) {
                        FlowLab(
                            stage = flow.stageIndex(screen = st.screen, dialog = st.dialog),
                            campaign = st.campaign,
                            onGo = { s, d -> st.labGo(s, d) },
                            toast = { st.toast(it) },
                        )
                    }
                }
            }
        }
    }
}

// MARK: หน้าของ flow ใหม่

@Composable
private fun ShellFlowView(st: ShellState, s: FlowScreen) {
    val campaign = st.campaign
    when (s) {
        is FlowScreen.Wizard -> StarWizard(
            kind = s.kind,
            campaign = campaign,
            steps = st.wiz.steps,
            onFinish = { madeCard -> st.finishWizard(s.kind, madeCard) },
            onExit = { d, t ->
                st.wizExitInfo = WizExitInfo(d, t)
                st.dialog = FlowDialog.wizExit
            },
            onKyc = { done -> st.kyc = done },
            toast = { st.toast(it) },
        )
        FlowScreen.Reveal -> StarPage(
            mode = StarPageMode.reveal,
            campaign = campaign,
            onClose = { st.close() },
            onNext = {
                st.flow.revealSeen = true
                st.open(FlowScreen.Register)
            },
            onFill = { steps -> st.startWizard(WizKind.one, steps, back = FlowScreen.Reveal) },
            onKyc = { st.openKyc(back = FlowScreen.Reveal) },
            onShare = { st.toast("แชร์การ์ด — จำลอง") },
        )
        FlowScreen.Register -> RegisterFormPage(campaign = campaign, onClose = { st.close() }, onSubmit = { st.submitRegister() })
        FlowScreen.Accept -> AcceptPage(
            campaign = campaign,
            onBack = { st.close() },
            onAccept = { st.dialog = FlowDialog.acceptConfirm },
            onDecline = { st.dialog = FlowDialog.declineConfirm },
        )
        FlowScreen.StarProfile -> StarPage(
            mode = StarPageMode.profile,
            campaign = campaign,
            onClose = { st.close() },
            onFill = { steps -> st.startWizard(WizKind.one, steps, back = FlowScreen.StarProfile) },
            onKyc = { st.openKyc(back = FlowScreen.StarProfile) },
            onShare = { st.toast("แชร์การ์ด — จำลอง") },
            onOpenStarCard = { intent -> st.creatorIntent = intent },
            hosted = true,
        )
        FlowScreen.Kyc -> Unit
    }
}

@Composable
private fun ShellDialog(st: ShellState, d: FlowDialog) {
    val flow = st.flow
    when (d) {
        FlowDialog.registerSuccess -> RegisterSuccessDialog(
            onClose = { st.dialog = null },
            onKyc = {
                st.dialog = null
                st.openKyc(back = null)
            },
        )
        FlowDialog.wizExit -> {
            val info = st.wizExitInfo
            val left = info.total - info.done
            FlowModal(
                title = if (info.total > 0 && left <= 2) "เหลืออีก $left ข้อ จะออกเลยเหรอ" else "เก็บไว้ทำต่อทีหลังไหม",
                detail = (if (info.done > 0) "ทำไปแล้ว ${info.done}/${info.total} · " else "") +
                    "ข้อมูลที่กรอกไว้ยังอยู่\nกลับมากดสมัครอีกครั้งจะได้ทำต่อจากตรงนี้",
                buttons = listOf(
                    FlowButton(title = "เก็บไว้แล้วออก", primary = false, action = {
                        st.dialog = null
                        if (st.wiz.kind == WizKind.one) st.open(st.wiz.back) else st.close()
                        st.toast("เก็บไว้ให้แล้ว · กลับมาทำต่อได้ทุกเมื่อ")
                    }),
                    FlowButton(title = "ทำต่อเลย", primary = true, action = { st.dialog = null }),
                ),
            )
        }
        FlowDialog.acceptConfirm -> FlowModal(
            title = "ยืนยันตอบรับกิจกรรม",
            detail = "เมื่อตอบรับแล้ว ต้องส่งดราฟต์และโพสต์รีวิวตามกำหนดของกิจกรรม",
            buttons = listOf(
                FlowButton(title = "ตอบรับกิจกรรม", primary = true, action = {
                    st.dialog = null
                    flow.phase = CampaignPhase.acceptedQuota
                    flow.order = OrderPhase.shipping
                    st.close()
                    st.toast("ตอบรับแล้ว · รอรับของจากแบรนด์")
                }),
                FlowButton(title = "ยกเลิก", primary = false, action = { st.dialog = null }),
            ),
        )
        FlowDialog.declineConfirm -> FlowModal(
            title = "สละสิทธิ์กิจกรรมนี้?",
            detail = "สิทธิ์จะถูกส่งต่อให้ผู้รับรางวัลสำรอง",
            buttons = listOf(
                FlowButton(title = "สละสิทธิ์", primary = true, action = {
                    st.dialog = null
                    st.close()
                    st.toast("สละสิทธิ์แล้ว — จำลอง")
                }),
                FlowButton(title = "ยกเลิก", primary = false, action = { st.dialog = null }),
            ),
        )
    }
}

// MARK: state + จุด hook (= `Ac.tapRegister` / `tapMain` / `submitRegister` / `wizFinish*`)

/** wizard ที่กำลังเล่น (kind + ขั้นที่ยังขาด + กลับไปไหนเมื่อจบแบบ one) */
private data class WizPlan(val kind: WizKind, val steps: List<WizStep>, val back: FlowScreen?)

private data class WizExitInfo(val done: Int, val total: Int)

/** หน้าของ flow + กุญแจของมัน — เปิดชุดขั้นใหม่ต้องได้ `StarWizard` ใหม่ (state ของใบเดิมไม่งั้นค้าง) */
private data class FlowSlot(val screen: FlowScreen, val key: String)

/** `@State` ทั้งหมดของ `SaleHereShell` + ฟังก์ชันที่เปลี่ยนมัน — อยู่ด้วยกันเหมือน struct ของ SwiftUI */
private class ShellState(private val scope: CoroutineScope) {
    val flow: StarFlow = StarFlow.shared

    /** พื้นที่ Star Card เปิดทับอยู่ — null = ปิด · ค่า = เปิดที่ไหน (คลัง / ห้องแต่งใบนั้น / เทมเพลต / มุมมองแบรนด์) */
    var creatorIntent by mutableStateOf<StarCardIntent?>(null)
    /** ธีมของใบที่คลังโฟกัสอยู่ — สีดวงไฟของ `StarGround` ในสถานะการ์ด */
    var lampTheme by mutableStateOf<CardTheme?>(null)
    /** คลังการ์ดเป็นหน้าที่เห็นอยู่ (ไม่ใช่เทมเพลต/ห้องแต่ง) — หัวร่วมโผล่เฉพาะตอนนี้ */
    var galleryVisible by mutableStateOf(false)
    val isCard: Boolean get() = creatorIntent != null
    /** หัวร่วม + พื้นร่วม โผล่เฉพาะตอนอยู่ Star Profile หรือ Star Card */
    val starStage: Boolean get() = screen == FlowScreen.StarProfile || creatorIntent != null
    var tab by mutableStateOf(SHTab.home)
    /** กิจกรรมที่กำลังเปิดอ่านทับหน้าแรก — null = อยู่หน้าแท็บ */
    var openCampaign by mutableStateOf<StarCampaign?>(null)
    /** หน้าของ flow ใหม่ที่เปิดทับอยู่ */
    var screen by mutableStateOf<FlowScreen?>(null)
    var wiz by mutableStateOf(WizPlan(WizKind.apply, emptyList(), null))
    /** นับรอบ wizard — เปิดชุดขั้นใหม่ต้องได้ `StarWizard` ใหม่ */
    var wizToken by mutableIntStateOf(0)
    /** ยืนยันตัวตนเปิดทับทุกอย่าง · completion = กลับมาที่หน้าเดิม */
    var kyc by mutableStateOf<(() -> Unit)?>(null)
    var dialog by mutableStateOf<FlowDialog?>(null)
    var wizExitInfo by mutableStateOf(WizExitInfo(0, 0))
    var toastText by mutableStateOf<String?>(null)
    private var toastToken = 0
    var showLab by mutableStateOf(false)
    /** แผง lab เพิ่งสั่งเปลี่ยนหน้าเอง — ปิดแผงแล้วไม่ต้องคำนวณ wizard ซ้ำ */
    private var labNavigated = false
    val campaigns: List<StarCampaign> = StarCampaign.mock

    /** กิจกรรมที่ flow ผูกอยู่ — งานที่เปิดอยู่ ไม่งั้นงานแรก (EP.1585) */
    val campaign: StarCampaign get() = openCampaign ?: campaigns[0]

    fun flowKey(s: FlowScreen): String = when (s) {
        is FlowScreen.Wizard -> if (s.kind == wiz.kind) "wiz$wizToken" else "wizard(${s.kind.raw})"
        FlowScreen.Reveal -> "reveal"
        FlowScreen.Register -> "register"
        FlowScreen.Accept -> "accept"
        FlowScreen.StarProfile -> "starProfile"
        FlowScreen.Kyc -> "kyc"
    }

    /**
     * ปุ่ม "โปรไฟล์ครีเอเตอร์" — ไปหน้า Star Profile ก่อนเสมอ (ผู้ใช้ 24 ก.ย.: "กดมาต้องไปหน้าแรกก่อน")
     * ปุ่ม "สมัครเป็น STAR" บนหน้านั้นค่อยพาเข้า wizard กรอกครบทุกข้อในรอบเดียว
     */
    fun openCreatorProfile() = open(FlowScreen.StarProfile)

    fun open(s: FlowScreen?) {
        screen = s
    }

    fun close() = open(null)

    /** ปุ่มย้อนของระบบบนหน้าของ flow — wizard = ✕ ของมัน (ถามก่อนออก) · หน้าอื่น = ปิด */
    fun backFromScreen(s: FlowScreen) {
        if (s is FlowScreen.Wizard) {
            val real = wiz.steps.filter { it != WizStep.intro }
            val done = real.count { st ->
                if (st == WizStep.kyc) flow.isVerified else (st.dataKey?.let { flow.has(it) } ?: false)
            }
            wizExitInfo = WizExitInfo(done, real.size)
            dialog = FlowDialog.wizExit
        } else {
            close()
        }
    }

    fun tapMain() {
        when (flow.phase) {
            CampaignPhase.register -> {
                val steps = flow.registerSteps
                if (steps.isEmpty()) open(FlowScreen.Register) else startWizard(WizKind.apply, listOf(WizStep.intro) + steps, back = null)
            }
            CampaignPhase.waitingAcceptQuota -> {
                val steps = flow.acceptSteps
                if (steps.isEmpty()) open(FlowScreen.Accept) else startWizard(WizKind.accept, steps, back = null)
            }
            CampaignPhase.acceptedQuota -> toast("หน้ารายละเอียดการรีวิว = หน้าเดิมของแอปหลัก (ไม่ได้จำลอง)")
            CampaignPhase.registered -> Unit
        }
    }

    fun startWizard(kind: WizKind, steps: List<WizStep>, back: FlowScreen?) {
        wiz = WizPlan(kind, steps, back)
        wizToken += 1
        open(FlowScreen.Wizard(kind))
    }

    fun finishWizard(kind: WizKind, madeCard: Boolean) {
        when (kind) {
            WizKind.apply -> if (madeCard) {
                open(FlowScreen.Reveal)
            } else {
                open(FlowScreen.Register)
                toast("ข้อมูลเติมให้แล้ว · ต่อที่ฟอร์มสมัคร")
            }
            WizKind.accept -> {
                open(FlowScreen.Accept)
                toast("ที่อยู่เติมให้แล้ว · ต่อที่หน้าตอบรับ")
            }
            WizKind.one -> {
                toast(
                    if (!flow.hasCard) "บันทึกแล้ว"
                    else if (flow.pct >= 1) "การ์ดเต็มแล้ว · แบรนด์เห็นข้อมูลคุณครบ"
                    else "เพิ่มลงการ์ดแล้ว",
                )
                // ไม่มีที่ให้กลับ (เข้ามาจากปุ่มโปรไฟล์ครีเอเตอร์ครั้งแรก) = จบแล้วไป Star Profile
                open(wiz.back ?: FlowScreen.StarProfile)
            }
        }
    }

    fun submitRegister() {
        flow.phase = CampaignPhase.registered
        close()
        // = `withAnimation(Motion.snap.delay(0.35))` — dialog โผล่หลังฟอร์มเลื่อนออก
        scope.launch {
            delay(350)
            dialog = FlowDialog.registerSuccess
        }
    }

    /** ยืนยันตัวตนจากหน้าการ์ด/Star Profile/dialog — กลับมาหน้าเดิมพร้อม toast */
    @Suppress("UNUSED_PARAMETER")
    fun openKyc(back: FlowScreen?) {
        kyc = {
            toast(if (flow.isVerified) "ป้าย Verified ขึ้นการ์ดแล้ว" else "ส่งคำขอยืนยันตัวตนแล้ว · รอทีมตรวจ")
        }
    }

    /** ปิดแผง lab (= `dismiss` + `onDismiss` ของ fullScreenCover — onDismiss มาหลังแผงเลื่อนลงเสร็จ) */
    fun closeLab() {
        showLab = false
        scope.launch {
            delay(300)
            refreshAfterLab()
        }
    }

    /** ปิดแผง lab แล้ว wizard ที่เปิดค้างอยู่ต้องเห็นข้อมูลชุดใหม่ — ขั้นที่ติ๊กแล้วหายไป ครบแล้วก็ปิด wizard ไปเลย */
    fun refreshAfterLab() {
        try {
            if (labNavigated) return
            val kind = (screen as? FlowScreen.Wizard)?.kind ?: return
            val fresh: List<WizStep> = when (kind) {
                WizKind.apply -> if (flow.registerSteps.isEmpty()) emptyList() else listOf(WizStep.intro) + flow.registerSteps
                WizKind.accept -> flow.acceptSteps
                WizKind.one -> wiz.steps.filter {
                    if (it == WizStep.kyc) flow.verify == VerifyStatus.none else !(it.dataKey?.let { k -> flow.has(k) } ?: true)
                }
            }
            if (fresh == wiz.steps) return
            if (fresh.isEmpty()) {
                when (kind) {
                    WizKind.apply -> {
                        open(FlowScreen.Register)
                        toast("ข้อมูลครบแล้ว · ต่อที่ฟอร์มสมัคร")
                    }
                    WizKind.accept -> {
                        open(FlowScreen.Accept)
                        toast("ข้อมูลครบแล้ว · ต่อที่หน้าตอบรับ")
                    }
                    WizKind.one -> open(wiz.back)
                }
            } else {
                startWizard(kind, fresh, back = wiz.back)
            }
        } finally {
            labNavigated = false
        }
    }

    fun labGo(s: FlowScreen?, d: FlowDialog?) {
        labNavigated = true
        if (openCampaign == null) openCampaign = campaigns[0]
        // ตั้งข้อมูล/ฉากเฉย ๆ (ไม่มีหน้าให้เปิด) จากในห้องแต่ง/คลัง → อยู่ที่เดิม ไม่เด้งออก
        if (s == null && d == null && creatorIntent != null) return
        // กระโดดขั้นตอนที่ชั้น Star Card เปิดอยู่ — ปิดชั้นก่อน ไม่งั้นหน้าที่สั่งเปิดอยู่ใต้คลัง
        if (creatorIntent != null) creatorIntent = null
        if (s is FlowScreen.Wizard) {
            val kind = s.kind
            val steps = if (kind == WizKind.apply) listOf(WizStep.intro) + flow.registerSteps else flow.acceptSteps
            if (steps.isEmpty()) {
                open(if (kind == WizKind.apply) FlowScreen.Register else FlowScreen.Accept)
            } else {
                startWizard(kind, steps, back = null)
            }
        } else {
            open(s)
        }
        dialog = d
    }

    fun toast(t: String) {
        toastToken += 1
        val token = toastToken
        toastText = t
        scope.launch {
            delay(2400)
            if (toastToken == token) toastText = null
        }
    }
}
