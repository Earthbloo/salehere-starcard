package co.salehere.starcard.ui.profile

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.TargetBasedAnimation
import androidx.compose.animation.core.VectorConverter
import androidx.compose.animation.expandHorizontally
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkHorizontally
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.Portfolio
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.StarSeal
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.theme.systemFont
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.dockPress
import co.salehere.starcard.ui.pkDimPress
import co.salehere.starcard.ui.pkRowPress
import co.salehere.starcard.ui.profile.sections.ChannelsSection
import co.salehere.starcard.ui.profile.sections.ConsentSection
import co.salehere.starcard.ui.profile.sections.InterestsSection
import co.salehere.starcard.ui.profile.sections.PaymentSection
import co.salehere.starcard.ui.profile.sections.PersonSection
import co.salehere.starcard.ui.profile.sections.TermsSection
import co.salehere.starcard.ui.tap
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.max
import kotlin.math.roundToInt

// MARK: - หน้า "ข้อมูลของฉัน" ทั้งชุด (= ProfileFlow.swift)
//
// hub → แตะส่วนไหนแก้ส่วนนั้น (กลับได้ตลอด ทุกอย่างบันทึกเองแล้ว)
// hub → "เริ่มสร้างโปรไฟล์" = wizard เฉพาะส่วนจำเป็น → กลับมาดูข้อมูลที่ hub
// ไม่ใช้ Navigation — ทั้งแอปสลับหน้าด้วย state + transition เอง (ดู `ContentView`)

private sealed interface Screen {
    data object Hub : Screen
    data class Section(val section: ProfileSection) : Screen
    data object Wizard : Screen
    /** รูป · ชื่อผู้ใช้ · ลิงก์ · About Me · ผลงาน — ช่องของแอป Sale Here เดิม ไม่ใช่ขั้นของฟอร์ม */
    data object Edit : Screen
}

@Composable
fun ProfileFlow(
    onClose: () -> Unit,
    /** Star Card ของฉัน — ผู้เรียกปิดหน้านี้แล้วพากลับหน้าการ์ดของฉัน (คลัง) */
    onMyCards: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var screen by remember { mutableStateOf<Screen>(Screen.Hub) }
    fun go(s: Screen) { screen = s }

    // ปุ่มย้อนของระบบ = กลับ hub (hub เองให้ผู้เรียกจัดการ)
    BackHandler(enabled = screen != Screen.Hub) { go(Screen.Hub) }

    Box(modifier.fillMaxSize()) {
        ProfileStage()
        AnimatedContent(
            targetState = screen,
            transitionSpec = {
                if (targetState == Screen.Hub) {
                    fadeIn(Motion.settle.spec()) togetherWith fadeOut(Motion.settle.spec())
                } else {
                    (slideInHorizontally(Motion.settle.spec()) { it } + fadeIn(Motion.settle.spec())) togetherWith
                        fadeOut(Motion.settle.spec())
                }
            },
            label = "profileFlow",
            modifier = Modifier.fillMaxSize(),
        ) { s ->
            when (s) {
                Screen.Hub -> ProfileHub(
                    onClose = onClose,
                    onOpen = { sec -> go(Screen.Section(sec)) },
                    onStart = {
                        Profile.me.beginIntake()
                        go(Screen.Wizard)
                    },
                    onMyCards = onMyCards,
                    onEdit = { go(Screen.Edit) },
                )
                Screen.Edit -> ProfileEditor(onClose = { go(Screen.Hub) })
                // แตะแถวใน hub = เปิด wizard ที่ขั้นนั้น — แถบขั้น · ✕ ปิด · ย้อนกลับ/ถัดไป เหมือนตอนกรอกครั้งแรกทุกอย่าง
                is Screen.Section -> ProfileWizard(
                    start = max(0, ProfileSection.required.indexOf(s.section)),
                    onExit = { go(Screen.Hub) },
                    onFinish = { go(Screen.Hub) },
                )
                Screen.Wizard -> ProfileWizard(onExit = { go(Screen.Hub) }, onFinish = { go(Screen.Hub) })
            }
        }
    }
}

/** เวทีของทุกหน้าในกลุ่มนี้ — พื้นเรียบ #F9FAFB แบบหน้าในแอป Sale Here ไม่มีแสงสี ไม่มีลาย */
@Composable
fun ProfileStage(modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize().background(PK.bg))
}

// MARK: - Hub

@Composable
fun ProfileHub(
    onClose: () -> Unit,
    onOpen: (ProfileSection) -> Unit,
    onStart: () -> Unit,
    onMyCards: () -> Unit,
    onEdit: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val p = Profile.me
    val hasIntake = p.intake != null
    val appear = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(50)
        appear.animateTo(1f, Motion.settle.float)
    }

    Column(modifier.fillMaxSize().statusBarsPadding()) {
        PKHeader(title = "โปรไฟล์ STAR", leftSymbol = Ph.caretDown, leftLabel = "ปิด", onLeft = onClose)
        Box(Modifier.weight(1f).fillMaxWidth()) {
            // สลับ hero ↔ hub (ล้างข้อมูล/นำเข้า) = เนื้อหาคนละชุด ตำแหน่งเลื่อนเดิมใช้ต่อไม่ได้
            key(p.hasIntake) {
                Column(
                    Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .graphicsLayer {
                            alpha = appear.value.coerceIn(0f, 1f)
                            translationY = (1f - appear.value) * 14.dp.toPx()
                        }
                        .navigationBarsPadding()
                        .padding(start = 16.dp, end = 16.dp, top = 4.dp, bottom = if (hasIntake) 120.dp else 40.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    if (!hasIntake) {
                        HubHero(onStart = onStart)
                    } else {
                        // หน้านี้คือ "ความเป็น STAR ของฉัน" ไม่ใช่สารบัญฟอร์ม:
                        // บัตร STAR → สิ่งที่ต้องทำต่อข้อเดียว → ข้อมูลเป็นแถวสรุป → เครื่องมือทดสอบท้ายสุด
                        HubStarCard(onEdit = onEdit)
                        HubNextStep(onOpen = onOpen)
                        HubSections(onOpen = onOpen)
                        HubTools()
                    }
                }
            }
            if (hasIntake) HubBottomBar(onOpen = onOpen, onMyCards = onMyCards, modifier = Modifier.align(Alignment.BottomCenter))
        }
    }
}

// MARK: ยังไม่เคยกรอก — หน้าต้อนรับแบบเดียวกับฟอร์มเว็บ

@Composable
private fun HubHero(onStart: () -> Unit) {
    val shape = PK.shape(28f)
    Column(
        Modifier
            .fillMaxWidth()
            .pkGlass(shape)
            .border(1.dp, PK.line, shape)
            .padding(start = 16.dp, end = 16.dp, top = 14.dp, bottom = 20.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        // อีโมจิลอยขนาบป้าย — อยู่แถวเดียวกับป้าย ไม่ล้ำลงไปทับพาดหัว
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 6.dp).padding(top = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PKFloatingEmoji(emoji = "🌟", size = 28f, duration = 6.5)
            Spacer(Modifier.weight(1f))
            PKStarBadge()
            Spacer(Modifier.weight(1f))
            PKFloatingEmoji(emoji = "💎", size = 24f, duration = 7.5, delay = 0.8, tilt = 6.0)
        }

        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
            val title = buildAnnotatedString {
                append("ร่วมเป็น ")
                withStyle(SpanStyle(brush = androidx.compose.ui.graphics.Brush.horizontalGradient(listOf(PK.red, PK.redDark)))) { append("STAR") }
                append(" รับงานรีวิวที่ใช่สำหรับคุณ 🌟")
            }
            Text(
                title, style = sh(27f, SHFont.black), color = PK.ink, textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 20.dp),
            )
            Text(
                "กรอกครั้งเดียว STAR Card ทุกใบดึงไปใช้ · แก้ตรงไหนบนการ์ดก็กลับมาเปลี่ยนที่นี่ด้วย ไม่ต้องทำพอร์ตเองให้ยุ่งยาก",
                style = sh(14f, SHFont.medium), color = PK.muted, textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 20.dp),
            )
        }

        // จุดขาย 4 ข้อ — สติกเกอร์สองคอลัมน์ ข้อความสั้นพอไม่ตัดกลางคำ (ผล audit ของเว็บ)
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Perk("🎯", "แมตช์งานที่ใช่", "จับคู่แคมเปญให้ตรงสาย", PK.peach, Modifier.weight(1f))
                Perk("💰", "ตั้งเรทเอง", "มีเรทตลาดไกด์ให้", PK.lemon, Modifier.weight(1f))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Perk("📸", "ไม่ต้องทำพอร์ต", "ดึงผลงานจากช่องของคุณ", PK.lavender, Modifier.weight(1f))
                Perk("🧾", "เงินเข้าตรงเวลา", "ทีมงานดูแลให้จบ", PK.mint, Modifier.weight(1f))
            }
        }

        // ขั้นตอนทั้งหมดบอกล่วงหน้า — ตัวเลขต้องตรงกับตัวนับใน wizard
        PKWrap(spacing = 4f, modifier = Modifier.fillMaxWidth()) {
            val all = ProfileSection.required
            all.forEachIndexed { i, s ->
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        "${s.emoji} ${stepShort(s)}",
                        style = sh(11.5f, SHFont.bold), color = PK.ink, maxLines = 1, softWrap = false,
                        modifier = Modifier
                            .background(PK.surface, CircleShape)
                            .border(1.dp, PK.line2, CircleShape)
                            .padding(horizontal = 9.dp, vertical = 6.dp),
                    )
                    if (i < all.size - 1) Text("›", style = sh(13f, SHFont.bold), color = PK.hint)
                }
            }
        }

        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
            PKPrimaryButton(title = "🚀 เริ่มสร้างโปรไฟล์ STAR!", action = onStart)
            Text(
                "ใช้เวลาประมาณ 2 นาที · พักไว้ก่อนได้ ระบบบันทึกให้เองทุกจังหวะ",
                style = sh(11.5f, SHFont.medium), color = PK.hint, textAlign = TextAlign.Center,
            )
            Text(
                "เคยสมัคร STAR ไว้แล้ว? นำเข้าจากโปรไฟล์ Sale Here เดิม",
                style = sh(12.5f, SHFont.semibold).copy(textDecoration = TextDecoration.Underline),
                color = PK.redDark, textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 2.dp).tap {
                    Haptics.light()
                    Profile.me.importFromSystemProfile()
                },
            )
            // ทางลัดทดสอบ — เติมทุกช่องด้วยข้อมูลตัวอย่าง (เหลือแตะยินยอม PDPA เอง)
            SampleFillLink()
        }
    }
}

/** ชื่อสั้นสำหรับชิปขั้นตอน — ชื่อเต็มยาวจนแถวชิปตกบรรทัด */
private fun stepShort(s: ProfileSection): String = when (s) {
    ProfileSection.channels -> "ช่องทาง"
    ProfileSection.interests -> "สายที่ใช่"
    ProfileSection.payment -> "รับเงิน"
    ProfileSection.terms -> "Vibe"
    ProfileSection.person -> "รู้จักกัน"
    ProfileSection.consent -> "ยืนยัน"
}

@Composable
private fun Perk(emoji: String, title: String, detail: String, tint: Color, modifier: Modifier = Modifier) {
    Column(
        modifier.background(tint, PK.shape(16f)).padding(13.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(emoji, style = systemFont(26f), maxLines = 1, softWrap = false)
        Text(title, style = sh(13.5f, SHFont.black), color = PK.ink, maxLines = 1, autoSize = pkAutoSize(13.5f, 0.8f))
        Text(detail, style = sh(11f, SHFont.medium), color = PK.ink.opacity(0.62), maxLines = 2, overflow = TextOverflow.Ellipsis)
    }
}

// MARK: แถบล่าง — ปุ่มหลักปุ่มเดียวของหน้า

private fun nextMissing(p: Profile): ProfileSection? =
    ProfileSection.required.firstOrNull { it.status(p) != SectionStatus.complete }

@Composable
private fun HubBottomBar(onOpen: (ProfileSection) -> Unit, onMyCards: () -> Unit, modifier: Modifier = Modifier) {
    val p = Profile.me
    val done = p.requiredDoneCount
    val total = ProfileSection.required.size
    val s = nextMissing(p)
    Box(
        modifier
            .fillMaxWidth()
            .pkBottomBar()
            .navigationBarsPadding()
            .padding(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 10.dp),
    ) {
        if (s != null) {
            // ไปที่ส่วนที่ขาดจริง — การ์ดบอก "ทำต่อ: ยืนยัน" แต่ปุ่มพาไปขั้น 1 = ผู้ใช้ต้องกดถัดไปอีก 5 ครั้งเอง
            PKPrimaryButton(title = "กรอกต่อ · เหลืออีก ${total - done} ส่วน", symbol = Ph.arrowRight) { onOpen(s) }
        } else {
            PKPrimaryButton(title = "Star Card ของฉัน", symbol = Ph.arrowRight, action = onMyCards)
        }
    }
}

// MARK: บัตร STAR — ใครคือคนนี้ในสายตาแบรนด์

/** บัตรโฮโลเหลืองเป็นพื้นสว่างชิ้นเดียวในหน้า — ตัวหนังสือบนมันจึงเข้มเสมอ ไม่ตาม `PK.ink` */
private val heroInk = rgb(0.13, 0.12, 0.11)

@Composable
private fun HubStarCard(onEdit: () -> Unit) {
    val p = Profile.me
    val c = p.creator
    val photos = LocalPhotoStore.current
    // โฮโลพาสเทล + ดาวดวงโต (STAR) ในถาดกระจกขาว — ชิ้นเดียวในหน้าที่มีสี ทุกอย่างข้างล่างเป็นขาวนุ่ม
    Box(Modifier.fillMaxWidth().pkGlass(PK.shape(30f)).padding(6.dp).clip(PK.shape(24f))) {
        PKWarmMesh(Modifier.matchParentSize())
        Row(
            Modifier
                .fillMaxWidth()
                .pkDimPress {
                    Haptics.light()
                    onEdit()
                }
                .padding(horizontal = 18.dp, vertical = 24.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                Modifier
                    .size(64.dp)
                    .dropShadow(CircleShape, Shadow(radius = 8.dp, color = Color.Black.opacity(0.18), offset = DpOffset(0.dp, 4.dp)))
                    .clip(CircleShape),
            ) {
                if (photos != null) photos.avatar(Modifier.matchParentSize())
                else Box(Modifier.matchParentSize().background(PK.fieldFill))
                Box(Modifier.matchParentSize().border(2.dp, Color.White.opacity(0.85), CircleShape))
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        if (p.isPlaceholder(ProfileField.personName)) "ยังไม่มีชื่อ" else p.name,
                        style = sh(21f, SHFont.black), color = heroInk, maxLines = 1,
                        autoSize = pkAutoSize(21f, 0.8f),
                        modifier = Modifier.weight(1f, fill = false),
                    )
                    if (c.verified) StarSeal(size = 15f)
                }
                Text("@${p.handle}", style = sh(13f, SHFont.medium), color = heroInk.opacity(0.55), maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            // แตะทั้งบัตรได้ — ปุ่มดินสอบอกว่ามันแก้ได้ ไม่ใช่แค่ป้ายชื่อ
            Box(
                Modifier
                    .size(36.dp)
                    .background(Color.White.opacity(0.45), CircleShape)
                    .border(1.dp, Color.White.opacity(0.7), CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                PIcon(Ph.pencilSimple, size = 15f, weight = PhWeight.bold, tint = heroInk)
            }
        }
    }
}

// MARK: สิ่งที่ต้องทำต่อ — ข้อเดียว ไม่ใช่ 6 กระเบื้องให้ไล่หา

@Composable
private fun HubNextStep(onOpen: (ProfileSection) -> Unit) {
    val p = Profile.me
    val done = p.requiredDoneCount
    val total = ProfileSection.required.size
    val s = nextMissing(p) ?: return
    Column(
        Modifier
            .fillMaxWidth()
            .pkSoftCard(24f)
            .clip(PK.shape(24f))
            .tap {
                Haptics.light()
                onOpen(s)
            },
    ) {
        Row(
            Modifier.fillMaxWidth().padding(18.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.size(42.dp).background(PK.warn.opacity(0.13), CircleShape), contentAlignment = Alignment.Center) {
                PIcon(s.icon, size = 18f, weight = PhWeight.fill, tint = PK.warn)
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text("ทำต่อ: ${s.title}", style = sh(17f, SHFont.bold), color = PK.ink)
                Text(
                    s.issues(p).firstOrNull()?.message ?: s.purpose,
                    style = sh(12.5f, SHFont.medium), color = PK.muted, maxLines = 2, overflow = TextOverflow.Ellipsis,
                )
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(PK.line))
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            BoxWithConstraints(Modifier.weight(1f).height(6.dp)) {
                Box(Modifier.matchParentSize().background(PK.ink.opacity(0.08), CircleShape))
                Box(
                    Modifier
                        .width(maxWidth * (done.toFloat() / max(1, total).toFloat()))
                        .height(6.dp)
                        .background(PK.ink, CircleShape),
                )
            }
            Text("$done/$total", style = sh(12f, SHFont.bold).copy(fontFeatureSettings = "tnum"), color = PK.muted)
        }
    }
}

// MARK: ข้อมูล — การ์ดชิ้นละส่วน มีขอบของตัวเอง · แตะแก้ได้
//
// ทุกชิ้นสูงเท่ากันหมด สรุปตัดท้ายให้เหลือบรรทัดเดียวเสมอ
// ครบแล้ว = ติ๊กวงกลมเขียว · ยังขาด = ขอบส้ม พื้นส้มจาง ป้ายบอกว่าขาดกี่ข้อ

@Composable
private fun HubSections(onOpen: (ProfileSection) -> Unit) {
    val p = Profile.me
    val done = p.requiredDoneCount
    val total = ProfileSection.required.size
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 6.dp).padding(top = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("ข้อมูลของฉัน", style = sh(19f, SHFont.bold), color = PK.ink)
            Spacer(Modifier.weight(1f))
            Text(
                if (done == total) "ครบแล้ว" else "$done/$total",
                style = sh(12f, SHFont.bold).copy(fontFeatureSettings = "tnum"),
                color = if (done == total) PK.ok else PK.hint,
            )
        }
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            ProfileSection.required.forEach { s -> HubRow(s, onOpen) }
        }
    }
}

@Composable
private fun HubRow(s: ProfileSection, onOpen: (ProfileSection) -> Unit) {
    val p = Profile.me
    val status = s.status(p)
    val issues = s.issues(p)
    val facts = s.facts(p)
    val missing = status != SectionStatus.complete
    val shape = PK.shape(22f)
    Row(
        Modifier
            .fillMaxWidth()
            .height(70.dp)
            .pkSoftCard(22f, tint = if (missing) PK.warn else null)
            .clip(shape)
            .pkRowPress {
                Haptics.light()
                onOpen(s)
            }
            .padding(horizontal = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(38.dp), contentAlignment = Alignment.Center) {
            PKSoftIcon(tint = if (missing) PK.warn else null, modifier = Modifier.matchParentSize())
            PIcon(
                s.icon, size = 18f, weight = if (missing) PhWeight.fill else PhWeight.regular,
                tint = if (missing) PK.warn else PK.ink.opacity(0.55),
            )
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            Text(s.title, style = sh(14.5f, SHFont.bold), color = PK.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
            if (facts.isEmpty()) {
                Text(
                    issues.firstOrNull()?.message ?: s.purpose,
                    style = sh(11.5f, SHFont.medium), color = PK.hint, maxLines = 1, overflow = TextOverflow.Ellipsis,
                )
            } else {
                PKFactStrip(facts = facts)
            }
        }
        if (missing) {
            PKStatusPill(
                text = if (status == SectionStatus.empty) "ยังไม่กรอก" else "ขาดอีก ${max(1, issues.size)}",
                color = PK.warn, symbol = Ph.warningCircle,
            )
        } else {
            PKDoneDot(size = 20f)
        }
        PIcon(Ph.caretRight, size = 11f, tint = PK.ink.opacity(0.22))
    }
}

// MARK: เครื่องมือทดสอบ — ท้ายสุด ตัวเล็ก ไม่ปนกับของจริง

@Composable
private fun HubTools() {
    val photos = LocalPhotoStore.current
    var confirmReset by remember { mutableStateOf(false) }
    val resetColor by animateColorAsState(if (confirmReset) PK.red else PK.muted, Motion.snap.spec(), label = "reset")
    Column(
        Modifier.fillMaxWidth().padding(top = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text("เครื่องมือทดสอบ", style = sh(11f, SHFont.bold).copy(letterSpacing = 0.4.sp), color = PK.hint)
        Row(horizontalArrangement = Arrangement.spacedBy(18.dp), verticalAlignment = Alignment.CenterVertically) {
            SampleFillLink(compact = true)
            Text(
                "ล้างข้อมูล", style = sh(11.5f, SHFont.semibold), color = resetColor,
                modifier = Modifier.tap { confirmReset = !confirmReset },
            )
        }
        AnimatedVisibility(
            visible = confirmReset,
            enter = fadeIn(Motion.snap.spec()) + expandVertically(Motion.snap.spec(), expandFrom = Alignment.Top),
            exit = fadeOut(Motion.snap.spec()) + shrinkVertically(Motion.snap.spec(), shrinkTowards = Alignment.Top),
        ) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                PKSecondaryButton(title = "ยกเลิก", modifier = Modifier.weight(1f)) { confirmReset = false }
                Box(
                    Modifier
                        .weight(1f)
                        .height(50.dp)
                        .dockPress {
                            Haptics.impact(Haptics.Style.heavy)
                            Profile.me.resetAll()
                            photos?.clearProfile()
                            Portfolio.shared.resetAll()
                            confirmReset = false
                        }
                        .background(PK.red, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Text("ลบทั้งหมด", style = sh(14.5f, SHFont.bold), color = Color.White)
                }
            }
        }
    }
}

// MARK: - หน้าแก้ทีละส่วน (จาก hub)

@Composable
fun SectionScreen(section: ProfileSection, onBack: () -> Unit, modifier: Modifier = Modifier) {
    var showIssues by remember { mutableStateOf(false) }
    var focusRequest by remember { mutableStateOf<String?>(null) }
    val keyboardUp = keyboardVisible()
    val issues = section.issues(Profile.me)
    val shownIssues = remember { arrayOf(issues) }
    if (issues.isNotEmpty()) shownIssues[0] = issues

    Column(modifier.fillMaxSize().statusBarsPadding()) {
        PKHeader(
            title = section.title,
            subtitle = if (section.isRequired) "จำเป็นสำหรับการ์ด" else "เติมทีหลังได้ · ไม่บังคับ",
            leftSymbol = Ph.x, leftLabel = "ปิด", onLeft = onBack,
        )
        Box(Modifier.weight(1f).fillMaxWidth().imePadding()) {
            SectionBody(section = section, showIssues = showIssues, focusRequest = focusRequest, onFocusRequestChange = { focusRequest = it })
            // คีย์บอร์ดขึ้น = แถบปุ่มหลบ ไม่ทับช่องที่กำลังพิมพ์
            androidx.compose.animation.AnimatedVisibility(
                visible = !keyboardUp,
                modifier = Modifier.align(Alignment.BottomCenter),
                enter = fadeIn(Motion.snap.spec()) + slideInVertically(Motion.snap.spec()) { it / 3 },
                exit = fadeOut(Motion.snap.spec()) + slideOutVertically(Motion.snap.spec()) { it / 3 },
            ) {
                Column(
                    Modifier
                        .fillMaxWidth()
                        .pkBottomBar()
                        .navigationBarsPadding()
                        .padding(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 10.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    AnimatedVisibility(
                        visible = showIssues && issues.isNotEmpty(),
                        enter = fadeIn(Motion.settle.spec()) + expandVertically(Motion.settle.spec()),
                        exit = fadeOut(Motion.settle.spec()) + shrinkVertically(Motion.settle.spec()),
                    ) {
                        PKIssueBox(issues = shownIssues[0], onTap = { focusRequest = it.field })
                    }
                    PKPrimaryButton(title = "เสร็จ", symbol = Ph.check) {
                        val first = issues.firstOrNull()
                        if (section.isRequired && first != null) {
                            showIssues = true
                            focusRequest = first.field
                            Haptics.rigid()
                        } else {
                            onBack()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Wizard (ครั้งแรก · หรือเปิดจากแถวใน hub ที่ขั้นนั้น)

/** `start` — ขั้นที่เปิดมาถึงก่อน (0 = ครั้งแรก · จาก hub = ขั้นของแถวที่แตะ) */
@Composable
fun ProfileWizard(
    start: Int = 0,
    onExit: () -> Unit,
    onFinish: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val steps = ProfileSection.required
    val p = Profile.me
    var step by remember { mutableIntStateOf(start.coerceIn(0, steps.size - 1)) }
    var showIssues by remember { mutableStateOf(false) }
    var focusRequest by remember { mutableStateOf<String?>(null) }
    val keyboardUp = keyboardVisible()
    /** ทิศของการเปลี่ยนขั้น — ไปหน้า = ไหลมาจากขวา · ย้อน = ไหลมาจากซ้าย */
    var forward by remember { mutableStateOf(true) }
    /** จำนวนข้อที่ยังขาดมากที่สุดที่เคยเห็นต่อส่วน — ตัวหารของ "กรอกไปแล้วเท่าไหร่" */
    val peak = remember { mutableStateMapOf<ProfileSection, Int>() }
    /** นับครั้งที่กด "ถัดไป" ทั้งที่ยังไม่ครบ — ให้เหรียญของส่วนนี้ส่ายหัว */
    var nudge by remember { mutableIntStateOf(0) }

    val current = steps[step.coerceIn(0, steps.size - 1)]
    val issues = current.issues(p)
    val shownIssues = remember { arrayOf(issues) }
    if (issues.isNotEmpty()) shownIssues[0] = issues
    val last = step == steps.size - 1

    fun notePeak(s: ProfileSection) {
        val n = s.issues(p).size
        if (n > (peak[s] ?: 0)) peak[s] = n
    }

    /** ส่วนนี้กรอกไปแล้วเท่าไหร่ — ครบ = 1 · ที่เหลือเทียบกับจำนวนข้อที่ขาดมากที่สุดที่เคยเห็น */
    fun fill(s: ProfileSection): Float {
        val left = s.issues(p).size
        if (left == 0 && p.intake != null) return 1f
        val top = maxOf(peak[s] ?: left, left, 1)
        return (top - left).toFloat() / top.toFloat()
    }

    fun next() {
        val first = issues.firstOrNull()
        if (first != null) {
            showIssues = true
            focusRequest = first.field
            nudge += 1
            Haptics.rigid()
            return
        }
        if (step < steps.size - 1) {
            forward = true
            showIssues = false
            step += 1
        } else {
            Profile.me.updateIntake { it.copy(firstRunDone = true) }
            onFinish()
        }
    }

    fun back() {
        // ปุ่มย้อนที่กำลังจางออกยังรับแตะได้อีกจังหวะ — กันไม่ให้ถอยหลุดขั้นแรก
        if (step <= 0) return
        forward = false
        showIssues = false
        step -= 1
    }

    /** แตะเหรียญบนแถบ — กระโดดไปส่วนนั้นตรง ๆ หน้าไหลเข้ามาตามทิศ */
    fun jump(i: Int) {
        if (i == step || i !in steps.indices) return
        forward = i > step
        showIssues = false
        step = i
    }

    LaunchedEffect(p.intake) { steps.forEach { notePeak(it) } }

    Column(modifier.fillMaxSize().statusBarsPadding()) {
        // แถวบนแถวเดียว — ✕ ปิด · แถวเหรียญตรา (แตะเพื่อกระโดด)
        Row(
            Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 2.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PKCircleButton(symbol = Ph.x, label = "ปิด", action = onExit)
            PKStampRow(
                current = step,
                fill = steps.map { fill(it) },
                icons = steps.map { it.icon },
                titles = steps.map { it.title },
                nudge = nudge,
                onTap = { jump(it) },
                modifier = Modifier.weight(1f),
            )
        }
        Box(Modifier.weight(1f).fillMaxWidth().imePadding()) {
            val slide = with(LocalDensity.current) { 56.dp.roundToPx() }
            AnimatedContent(
                targetState = step,
                transitionSpec = {
                    val dir = if (forward) 1 else -1
                    (slideInHorizontally(Motion.settle.spec()) { slide * dir } + fadeIn(Motion.settle.spec())) togetherWith
                        (slideOutHorizontally(Motion.settle.spec()) { -slide * dir } + fadeOut(Motion.settle.spec()))
                },
                label = "wizardStep",
                modifier = Modifier.fillMaxSize(),
            ) { i ->
                val s = steps[i.coerceIn(0, steps.size - 1)]
                CompositionLocalProvider(LocalWizardHeading provides WizardHeading(s)) {
                    SectionBody(section = s, showIssues = showIssues, focusRequest = focusRequest, onFocusRequestChange = { focusRequest = it })
                }
            }
            androidx.compose.animation.AnimatedVisibility(
                visible = !keyboardUp,
                modifier = Modifier.align(Alignment.BottomCenter),
                enter = fadeIn(Motion.snap.spec()) + slideInVertically(Motion.snap.spec()) { it / 3 },
                exit = fadeOut(Motion.snap.spec()) + slideOutVertically(Motion.snap.spec()) { it / 3 },
            ) {
                Column(
                    Modifier
                        .fillMaxWidth()
                        .pkBottomBar()
                        .navigationBarsPadding()
                        .padding(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 10.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    AnimatedVisibility(
                        visible = showIssues && issues.isNotEmpty(),
                        enter = fadeIn(Motion.settle.spec()) + expandVertically(Motion.settle.spec()),
                        exit = fadeOut(Motion.settle.spec()) + shrinkVertically(Motion.settle.spec()),
                    ) {
                        PKIssueBox(issues = shownIssues[0], onTap = { focusRequest = it.field })
                    }
                    // แถวนำทางแบบเว็บ: ‹ ย้อนกลับ ซ้าย · ถัดไป → ขวา (ขั้นแรกไม่มีย้อน — ปุ่มปิดอยู่มุมบน)
                    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        AnimatedVisibility(
                            visible = step > 0,
                            enter = fadeIn(Motion.settle.spec()) + expandHorizontally(Motion.settle.spec(), expandFrom = Alignment.Start),
                            exit = fadeOut(Motion.settle.spec()) + shrinkHorizontally(Motion.settle.spec(), shrinkTowards = Alignment.Start),
                        ) {
                            PKSecondaryButton(
                                title = "ย้อนกลับ", symbol = Ph.caretLeft, height = 54f,
                                modifier = Modifier.padding(end = 10.dp).width(132.dp),
                            ) { back() }
                        }
                        PKPrimaryButton(
                            title = if (last) "เสร็จสิ้น 🎉" else "ถัดไป",
                            symbol = if (last) null else Ph.arrowRight,
                            modifier = Modifier.weight(1f),
                        ) { next() }
                    }
                    SampleFillLink(compact = true)
                }
            }
        }
    }
}

/**
 * หัวคำถามของขั้นหนึ่ง — คำถามตัวใหญ่ → ประโยครองบรรทัดเดียว · ชิดซ้ายแบบหน้านิตยสาร
 * wizard ส่งลงมาทาง `LocalWizardHeading` ให้ `SectionScroll` วางเป็นชิ้นแรก
 */
data class WizardHeading(val section: ProfileSection) {
    @Composable
    fun Content(modifier: Modifier = Modifier) {
        Column(
            modifier.fillMaxWidth().padding(start = 4.dp, end = 4.dp, top = 8.dp, bottom = 6.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(section.question, style = sh(24f, SHFont.bold), color = PK.ink)
            Text(section.purpose, style = sh(13.5f, SHFont.medium), color = PK.muted)
        }
    }
}

/** หัวคำถามที่ wizard ส่งลงมาให้ `SectionScroll` วางเป็นชิ้นแรก — หน้า section เดี่ยว (จาก hub) ไม่มี (= `\.wizardHeading`) */
val LocalWizardHeading = compositionLocalOf<WizardHeading?> { null }

// MARK: - ตัวเลือกเนื้อหาตามส่วน

@Composable
fun SectionBody(
    section: ProfileSection,
    showIssues: Boolean,
    focusRequest: String?,
    onFocusRequestChange: (String?) -> Unit,
    modifier: Modifier = Modifier,
) {
    when (section) {
        ProfileSection.channels -> ChannelsSection(showIssues, focusRequest, onFocusRequestChange, modifier)
        ProfileSection.interests -> InterestsSection(showIssues, focusRequest, onFocusRequestChange, modifier)
        ProfileSection.payment -> PaymentSection(showIssues, focusRequest, onFocusRequestChange, modifier)
        ProfileSection.terms -> TermsSection(showIssues, focusRequest, onFocusRequestChange, modifier)
        ProfileSection.person -> PersonSection(showIssues, focusRequest, onFocusRequestChange, modifier)
        ProfileSection.consent -> ConsentSection(showIssues, focusRequest, onFocusRequestChange, modifier)
    }
}

/**
 * ตัวเลื่อนของทุกส่วน — เลื่อนไปหาช่องที่ขอแล้วโฟกัสให้ (คีย์บอร์ดขึ้นที่ช่องนั้นเลย)
 * หัวคำถาม (ถ้ามี) เลื่อนไปกับเนื้อหา · ทุกชิ้นลูกไหลเข้าทีละแผง ไม่โผล่พรึ่บพร้อมกัน (= `PKReveal` ต่อชิ้น)
 */
@Composable
fun SectionScroll(
    focus: PKFocus,
    request: String?,
    onRequestChange: (String?) -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val heading = LocalWizardHeading.current
    val scroll = rememberScrollState()
    val scope = rememberCoroutineScope()
    val viewport = remember { arrayOfNulls<LayoutCoordinates>(1) }
    val keyboardUp = keyboardVisible()

    // นาฬิกาของการไหลเข้า — นับตั้งแต่เฟรมแรก แล้วหยุดเมื่อทุกชิ้นเข้าที่
    var elapsed by remember { mutableLongStateOf(-1L) }
    LaunchedEffect(Unit) {
        val t0 = withFrameNanos { it }
        while (true) {
            val t = withFrameNanos { it }
            elapsed = t - t0
            if (elapsed > 1_800_000_000L) break
        }
    }
    val curve = remember { TargetBasedAnimation(Motion.settle.spec<Float>(), Float.VectorConverter, 0f, 1f) }

    fun center(id: String) {
        val vp = viewport[0] ?: return
        val a = focus.anchor(id) ?: return
        if (!vp.isAttached) return
        val top = vp.localPositionOf(a, Offset.Zero).y
        val target = scroll.value + (top + a.size.height / 2f - vp.size.height / 2f).roundToInt()
        scope.launch { scroll.animateScrollTo(target.coerceIn(0, scroll.maxValue), Motion.settle.spec()) }
    }

    LaunchedEffect(request) {
        val id = request ?: return@LaunchedEffect
        center(id)
        delay(320)
        focus.focus(id)
        onRequestChange(null)
    }
    // คีย์บอร์ดขึ้นแล้วพื้นที่เหลือน้อยลง — พาช่องที่กำลังพิมพ์มาไว้กลางจอ
    LaunchedEffect(keyboardUp) {
        if (!keyboardUp) return@LaunchedEffect
        delay(260)
        focus.current?.let { center(it) }
    }

    CompositionLocalProvider(LocalPKFocus provides focus) {
        Box(modifier.fillMaxSize().onGloballyPositioned { viewport[0] = it }) {
            Layout(
                contents = listOf<@Composable () -> Unit>({ heading?.Content() }, content),
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(scroll)
                    .padding(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 190.dp),
            ) { (heads, items), constraints ->
                val gap = 12.dp.roundToPx()
                val rise = 18.dp.toPx()
                val cs = constraints.copy(minWidth = 0, minHeight = 0)
                // หัวคำถาม = ชิ้นที่ 0 · เนื้อหาเริ่มที่ 1 เสมอ (มีหรือไม่มีหัวก็หน่วงเท่ากัน)
                val placed = heads.map { 0 to it.measure(cs) } + items.mapIndexed { k, m -> (k + 1) to m.measure(cs) }
                val h = placed.sumOf { it.second.height } + gap * max(0, placed.size - 1)
                layout(constraints.maxWidth, h) {
                    var y = 0
                    placed.forEach { (index, pl) ->
                        val wait = ((0.05 + Motion.stagger(index, step = 0.06, cap = 0.4)) * 1_000_000_000L).toLong()
                        pl.placeRelativeWithLayer(0, y) {
                            val e = elapsed
                            val v = if (e <= wait) 0f else curve.getValueFromNanos(e - wait)
                            alpha = v.coerceIn(0f, 1f)
                            translationY = (1f - v) * rise
                        }
                        y += pl.height + gap
                    }
                }
            }
            // แป้นตัวเลข/โทรศัพท์ไม่มีปุ่มปิดของตัวเอง — ให้ "เสร็จ" เหนือคีย์บอร์ดทุกช่อง
            if (keyboardUp) PKKeyboardDone(onDone = { focus.clear() }, modifier = Modifier.align(Alignment.BottomCenter))
        }
    }
}

/** ข้อความผิดพลาดของช่องหนึ่ง — โผล่หลังกด "ถัดไป" แล้วไม่ผ่านเท่านั้น (ไม่ด่าตั้งแต่ยังไม่ทันพิมพ์) */
fun sectionIssue(section: ProfileSection, field: String, shown: Boolean): String? {
    if (!shown) return null
    return section.issues(Profile.me).firstOrNull { it.field == field }?.message
}

// MARK: - ทางลัดทดสอบ

/** "เติมข้อมูลตัวอย่าง" — สำหรับคนที่ขี้เกียจพิมพ์ตอนลองแอป · เติมครบทุกช่องยกเว้นยินยอม PDPA */
@Composable
fun SampleFillLink(compact: Boolean = false, modifier: Modifier = Modifier) {
    var filled by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val job = remember { arrayOfNulls<Job>(1) }
    val tint by animateColorAsState(if (filled) PK.ok else PK.muted, Motion.snap.spec(), label = "sampleFill")
    Row(
        modifier.tap {
            Haptics.medium()
            Profile.me.fillSample()
            filled = true
            job[0]?.cancel()
            job[0] = scope.launch {
                delay(2000)
                filled = false
            }
        },
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PIcon(
            if (filled) Ph.checkCircle else Ph.magicWand,
            size = if (compact) 11f else 13f,
            weight = if (filled) PhWeight.fill else PhWeight.bold,
            tint = tint,
        )
        Text(
            if (filled) "เติมให้แล้ว" else if (compact) "เติมข้อมูลตัวอย่าง" else "ขี้เกียจกรอก? เติมข้อมูลตัวอย่างให้ (ทดสอบ)",
            style = sh(if (compact) 11.5f else 12.5f, SHFont.semibold),
            color = tint,
        )
    }
}
