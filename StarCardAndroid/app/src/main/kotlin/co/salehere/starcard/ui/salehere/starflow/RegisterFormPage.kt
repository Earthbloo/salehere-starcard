package co.salehere.starcard.ui.salehere.starflow

import androidx.compose.animation.core.Animatable
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
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
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Popup
import androidx.compose.ui.window.PopupProperties
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.model.CampaignQuestion
import co.salehere.starcard.model.LocalStarFlow
import co.salehere.starcard.model.StarCampaign
import co.salehere.starcard.model.StarFlow
import co.salehere.starcard.model.StarSocial
import co.salehere.starcard.model.VerifyStatus
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHColor
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.profile.PK
import co.salehere.starcard.ui.salehere.SH
import co.salehere.starcard.ui.salehere.SHAvatar
import co.salehere.starcard.ui.salehere.SHBarIcon
import co.salehere.starcard.ui.salehere.SHNavBar
import co.salehere.starcard.ui.salehere.SHRedButton
import co.salehere.starcard.ui.tap
import kotlinx.coroutines.delay

/**
 * ฟอร์มสมัครเดิมของแอปหลัก (`UnboxRegister`) — flow ใหม่ตัดช่องที่อยู่ออก เหลือชื่อ+เบอร์ (ถามที่อยู่ตอนตอบรับแทน)
 *
 * ข้อมูลติดต่อ · คำถามของแบรนด์ · การ์ดโซเชียล (+ insight) · ยินยอม · ปุ่มแดงเต็ม
 */
@Composable
fun RegisterFormPage(campaign: StarCampaign, onClose: () -> Unit, onSubmit: () -> Unit, modifier: Modifier = Modifier) {
    val flow = LocalStarFlow.current
    var name by remember { mutableStateOf("มณีรัตน์ ใจดี") }
    var tel by remember { mutableStateOf("0891234567") }
    val answers = remember { mutableStateMapOf<String, String>() }
    val checks = remember { mutableStateListOf<String>() }
    var uploaded by remember { mutableStateOf(false) }

    Column(modifier.fillMaxSize().background(Color.White).imePadding()) {
        SHNavBar(
            title = "ลงทะเบียนร่วมกิจกรรม",
            left = { Gap(32f, 32f) },
            right = { SHBarIcon(icon = Ph.x, action = onClose) },
        )
        Column(
            Modifier
                .weight(1f)
                .fillMaxWidth()
                .background(Color.White)
                .verticalScroll(rememberScrollState())
                .padding(bottom = 24.dp),
        ) {
            SHSectionHeader(title = "ข้อมูลติดต่อ")
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                SHFormField(label = "ชื่อ - นามสกุล", required = true, text = name, onTextChange = { name = it }, placeholder = "กรอกชื่อ - นามสกุล")
                SHFormField(
                    label = "เบอร์โทรศัพท์", required = true, text = tel, onTextChange = { tel = it },
                    placeholder = "กรอกเบอร์โทรศัพท์", keyboard = KeyboardType.Phone,
                )
            }
            if (campaign.questions.isNotEmpty()) {
                SHSectionHeader(title = "คำถาม")
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                    campaign.questions.forEach { q ->
                        RegisterQuestion(
                            q = q,
                            answer = answers[q.id],
                            onAnswer = { answers[q.id] = it },
                            checks = checks,
                            onCheck = { o -> if (checks.contains(o)) checks.remove(o) else checks.add(o) },
                            uploaded = uploaded,
                            onUpload = { uploaded = true },
                        )
                    }
                }
            }
            SHSectionHeader(title = "โซเชียลมีเดีย")
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        RequiredLabel("ลิงก์โซเชียลมีเดียที่ต้องการลงทะเบียน")
                        Text("(ผูกบัญชีอย่างน้อย 1 ช่องทางเพื่อส่งรีวิว)", style = sh(12f), color = SH.muted)
                    }
                    Box(
                        Modifier.height(30.dp).border(1.dp, SH.red, CircleShape).padding(horizontal = 10.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("เพิ่ม/แก้ไขบัญชี", style = sh(12f, SHFont.semibold), color = SH.red)
                    }
                }
                StarSocial.entries.forEach { s -> RegisterSocialCard(s) }
                RegisterConsent()
            }
        }
        Column(
            Modifier
                .fillMaxWidth()
                .background(Color.White)
                .topHairline(SH.line)
                .navigationBarsPadding()
                .padding(horizontal = 16.dp)
                .padding(top = 10.dp, bottom = 8.dp),
        ) {
            SHRedButton(title = "ลงทะเบียนร่วมกิจกรรม", icon = Ph.notePencil, enabled = flow.consent, action = onSubmit)
        }
    }
}

/** "* " สีแดง + ข้อความสีหมึก (= `Text("* ").foregroundStyle(SH.red) + Text(q)`) */
@Composable
internal fun RequiredLabel(text: String, required: Boolean = true, modifier: Modifier = Modifier) {
    Text(
        buildAnnotatedString {
            withStyle(SpanStyle(color = SH.red)) { append(if (required) "* " else "") }
            withStyle(SpanStyle(color = SH.ink)) { append(text) }
        },
        style = sh(14f, SHFont.semibold),
        modifier = modifier,
    )
}

@Composable
private fun RegisterQuestion(
    q: CampaignQuestion,
    answer: String?,
    onAnswer: (String) -> Unit,
    checks: List<String>,
    onCheck: (String) -> Unit,
    uploaded: Boolean,
    onUpload: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        RequiredLabel(q.q)
        when (q.kind) {
            CampaignQuestion.Kind.text -> SHFormField(
                label = "", text = answer ?: "", onTextChange = onAnswer, placeholder = "กรอกคำตอบ", paragraph = true,
            )
            CampaignQuestion.Kind.radio -> SHMenuField(value = answer, options = q.options, onPick = onAnswer)
            CampaignQuestion.Kind.checkbox -> {
                Text("เลือกได้มากกว่า 1 ตัวเลือก", style = sh(12f), color = SH.muted)
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    q.options.forEach { o ->
                        val on = checks.contains(o)
                        Row(
                            Modifier.fillMaxWidth().tap {
                                Haptics.impact(Haptics.Style.light)
                                onCheck(o)
                            },
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            CheckBoxMark(on = on, size = 20f, check = 12f)
                            Text(o, style = sh(14f), color = SH.ink)
                        }
                    }
                }
            }
            CampaignQuestion.Kind.upload -> Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                if (uploaded) {
                    Image(
                        painterResource(SHIcon.photo3), contentDescription = null, contentScale = ContentScale.Crop,
                        modifier = Modifier.size(84.dp).clip(RoundedCornerShape(8.dp)),
                    )
                }
                Column(
                    Modifier
                        .size(84.dp)
                        .strokeInside(SH.line, 1f, radius = 8f, dash = 5f, gap = 4f)
                        .tap {
                            Haptics.impact(Haptics.Style.light)
                            onUpload()
                        },
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp, Alignment.CenterVertically),
                ) {
                    PIcon(Ph.plus, size = 20f, tint = SH.muted)
                    Text("เพิ่มรูป", style = sh(12f, SHFont.semibold), color = SH.muted)
                }
            }
        }
    }
}

/** กล่องติ๊กสี่เหลี่ยมมนของแอปหลัก — แดงเต็ม + ติ๊กขาวเมื่อเลือก */
@Composable
private fun CheckBoxMark(on: Boolean, size: Float, check: Float) {
    val shape = RoundedCornerShape(4.dp)
    Box(
        Modifier
            .size(size.dp)
            .background(if (on) SH.red else Color.White, shape)
            .strokeInside(if (on) SH.red else SH.line, 1.2f, radius = 4f),
        contentAlignment = Alignment.Center,
    ) {
        if (on) PIcon(Ph.check, size = check, tint = Color.White)
    }
}

@Composable
private fun RegisterSocialCard(s: StarSocial) {
    val flow = LocalStarFlow.current
    val on = flow.connected.contains(s)
    val shape = RoundedCornerShape(12.dp)
    Column(
        Modifier
            .fillMaxWidth()
            .background(Color.White, shape)
            .border(1.dp, if (on) SHColor.green.opacity(0.5) else SH.line, shape)
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
            if (on) {
                Box(Modifier.size(44.dp)) {
                    SHAvatar(size = 44f)
                    Box(Modifier.size(44.dp).border(1.dp, SH.line, CircleShape))
                }
            } else {
                Image(
                    painterResource(s.icon), contentDescription = null, contentScale = ContentScale.Fit,
                    modifier = Modifier.size(44.dp).clip(CircleShape),
                )
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(if (on) s.handle else s.name.uppercase(), style = sh(14f, SHFont.bold), color = SH.ink)
                if (on) Text(s.url, style = sh(11f), color = SH.muted, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            Box(
                Modifier
                    .height(24.dp)
                    .background(if (on) SHColor.greenSoft else SH.page, CircleShape)
                    .padding(horizontal = 8.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    if (on) "ผูกบัญชีแล้ว" else "ยังไม่ได้ผูกบัญชี",
                    style = sh(11f, SHFont.semibold), color = if (on) SHColor.green else SH.muted,
                )
            }
        }
        if (on) {
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                PIcon(Ph.usersThree, size = 14f, weight = PhWeight.regular, tint = SH.muted)
                Text("${StarFlow.fmt(s.followers)} ผู้ติดตาม", style = sh(12f, SHFont.medium), color = SH.muted)
            }
            if (s.supportsInsight) {
                val n = listOf("gender", "age", "location").count { flow.insightSlots.contains("${s.raw}_$it") }
                Row(
                    Modifier
                        .fillMaxWidth()
                        .background(SH.page, RoundedCornerShape(8.dp))
                        .padding(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                            Text("ข้อมูลผู้ติดตาม", style = sh(13f, SHFont.semibold), color = SH.ink)
                            if (n >= 3) {
                                PIcon(Ph.checkCircle, size = 16f, weight = PhWeight.fill, tint = SHColor.green)
                            } else {
                                Box(
                                    Modifier.height(18.dp).background(SH.page, CircleShape).padding(horizontal = 6.dp),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    Text("$n/3", style = sh(11f, SHFont.bold), color = if (n > 0) SH.amber else SH.muted)
                                }
                            }
                        }
                        Text(
                            if (n >= 3) "อัปเดตล่าสุด 12 ก.ย. 69" else "อัปโหลดรูป Insight เพศ / ช่วงอายุ / พื้นที่ยอดนิยม",
                            style = sh(11f), color = if (n in 1..2) SH.amber else SH.muted,
                        )
                    }
                    Box(
                        Modifier
                            .height(30.dp)
                            .background(if (n >= 3) Color.White else SH.red, CircleShape)
                            .border(1.dp, SH.red, CircleShape)
                            .padding(horizontal = 10.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            if (n >= 3) "อัปเดตข้อมูล" else "เพิ่มข้อมูล",
                            style = sh(12f, SHFont.semibold), color = if (n >= 3) SH.red else Color.White,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun RegisterConsent() {
    val flow = LocalStarFlow.current
    Row(
        Modifier
            .fillMaxWidth()
            .tap {
                Haptics.impact(Haptics.Style.light)
                flow.consent = !flow.consent
            }
            .padding(top = 8.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        CheckBoxMark(on = flow.consent, size = 22f, check = 13f)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("ฉันยอมรับข้อกำหนดและเงื่อนไข", style = sh(14f, SHFont.bold), color = SH.ink)
            Text(
                "ฉันยินยอมที่จะโพสต์รีวิวสินค้า และเปิดเป็นสาธารณะ ตามช่องทางโซเชียลมีเดียที่ลงทะเบียนไว้ภายหลังจากได้รับกล่อง Unbox หากไม่ได้รีวิวตามเวลาที่กำหนด ฉันจะถูกตัดสิทธิ์และไม่สามารถลงทะเบียนเข้าร่วมกิจกรรม ‘Sale Here UNBOX’ ได้อีกในครั้งต่อไป",
                style = sh(12f).lineSpaced(3f), color = SH.muted,
            )
        }
    }
}

/**
 * เลือกคำตอบจากรายการ (= `Menu { Button(o) }` ของ SwiftUI) — ช่องขอบเทา + เมนูลอยใต้ช่อง
 * ใช้ร่วมกับหน้าตอบรับ (`AcceptPage`)
 */
@Composable
internal fun SHMenuField(value: String?, options: List<String>, onPick: (String) -> Unit, modifier: Modifier = Modifier) {
    var open by remember { mutableStateOf(false) }
    var fieldH by remember { mutableIntStateOf(0) }
    val shape = RoundedCornerShape(8.dp)
    Box(modifier.fillMaxWidth()) {
        Row(
            Modifier
                .fillMaxWidth()
                .height(46.dp)
                .onSizeChanged { fieldH = it.height }
                .border(1.dp, SH.line, shape)
                .clip(shape)
                .tap { open = true }
                .padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(value ?: "เลือกคำตอบ", style = sh(15f), color = if (value == null) SH.hint else SH.ink, modifier = Modifier.weight(1f))
            PIcon(Ph.caretDown, size = 14f, tint = SH.hint)
        }
        if (open) {
            Popup(
                alignment = Alignment.TopStart,
                offset = IntOffset(0, fieldH + 8),
                onDismissRequest = { open = false },
                properties = PopupProperties(focusable = true),
            ) {
                val menu = RoundedCornerShape(12.dp)
                Column(
                    Modifier
                        .width(IntrinsicSize.Max)
                        .widthIn(min = 220.dp)
                        .glShadow(Color.Black.opacity(0.16), 16f, 6f, corner = 12f)
                        .clip(menu)
                        .background(Color.White)
                        .border(0.5.dp, SH.line, menu)
                        .padding(vertical = 6.dp),
                ) {
                    options.forEach { o ->
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .tap {
                                    onPick(o)
                                    open = false
                                }
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(o, style = sh(15f), color = SH.ink, modifier = Modifier.weight(1f))
                            if (o == value) PIcon(Ph.check, size = 14f, tint = SH.ink)
                        }
                    }
                }
            }
        }
    }
}

/** หัวข้อหมวดในฟอร์มของแอปหลัก — แถบเทาอ่อน ตัวหนา */
@Composable
fun SHSectionHeader(title: String, modifier: Modifier = Modifier) {
    Box(
        modifier
            .fillMaxWidth()
            .height(40.dp)
            .background(SH.page)
            .padding(horizontal = 16.dp),
        contentAlignment = Alignment.CenterStart,
    ) {
        Text(title, style = sh(15f, SHFont.bold), color = SH.ink)
    }
}

/** ช่องกรอกของแอปหลัก — ป้ายด้านบน (ดอกจันแดง) + กล่องขอบเทา */
@Composable
fun SHFormField(
    label: String,
    required: Boolean = false,
    text: String,
    onTextChange: (String) -> Unit,
    placeholder: String = "",
    keyboard: KeyboardType = KeyboardType.Text,
    paragraph: Boolean = false,
    modifier: Modifier = Modifier,
) {
    var focused by remember { mutableStateOf(false) }
    val shape = RoundedCornerShape(8.dp)
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        if (label.isNotEmpty()) RequiredLabel(label, required = required)
        BasicTextField(
            value = text,
            onValueChange = onTextChange,
            singleLine = !paragraph,
            minLines = if (paragraph) 3 else 1,
            maxLines = if (paragraph) 6 else 1,
            textStyle = sh(15f).copy(color = SH.ink),
            cursorBrush = SolidColor(SH.red),
            keyboardOptions = KeyboardOptions(keyboardType = keyboard),
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 46.dp)
                .border(1.dp, if (focused) SH.red else SH.line, shape)
                .onFocusChanged { focused = it.isFocused },
            decorationBox = { inner ->
                Box(
                    Modifier
                        .fillMaxWidth()
                        .heightIn(min = 46.dp)
                        .padding(horizontal = 14.dp, vertical = if (paragraph) 12.dp else 0.dp),
                    contentAlignment = if (paragraph) Alignment.TopStart else Alignment.CenterStart,
                ) {
                    if (text.isEmpty()) Text(placeholder, style = sh(15f), color = SH.hint)
                    inner()
                }
            },
        )
    }
}

/** dialog "ลงทะเบียนสำเร็จ" ของแอปหลัก (`AnimatedConfirmDialog`) — ชวนยืนยันตัวตนถ้ายังไม่ผ่าน */
@Composable
fun RegisterSuccessDialog(onClose: () -> Unit, onKyc: () -> Unit, modifier: Modifier = Modifier) {
    val flow = LocalStarFlow.current
    val pop = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(100)
        pop.animateTo(1f, Motion.lift.float)
    }
    Box(
        modifier
            .fillMaxSize()
            .background(Color.Black.opacity(0.5))
            .tap {},
        contentAlignment = Alignment.Center,
    ) {
        Box(Modifier.padding(horizontal = 30.dp)) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .background(Color.White, RoundedCornerShape(18.dp))
                    .tap {}
                    .padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Box(
                    Modifier
                        .padding(top = 6.dp)
                        .graphicsLayer {
                            val k = pop.value
                            val s = 0.4f + 0.6f * k
                            scaleX = s
                            scaleY = s
                            alpha = k.coerceIn(0f, 1f)
                        },
                    contentAlignment = Alignment.Center,
                ) {
                    Box(Modifier.size(96.dp).background(SHColor.greenSoft, CircleShape))
                    Box(Modifier.size(72.dp).background(SHColor.green, CircleShape))
                    PIcon(Ph.check, size = 36f, tint = Color.White)
                }
                Text("ลงทะเบียนสำเร็จ", style = sh(19f, SHFont.bold), color = SH.ink)
                Text(
                    "ผู้ที่ผ่านการคัดเลือกจะได้รับการแจ้งเตือน\nให้ยืนยันสิทธิ์ผ่านแอปฯ Sale Here",
                    style = sh(14f).lineSpaced(3f), color = SH.muted, textAlign = TextAlign.Center,
                )
                // ยืนยันตัวตนไปแล้ว (ผ่านหรือรอตรวจ) = ไม่ชวนซ้ำ (ผู้ใช้ 24 ก.ย.)
                val kycDone = flow.verify != VerifyStatus.none
                if (!kycDone) {
                    Text(
                        "*กรุณายืนยันตัวตน เพื่อความรวดเร็ว ในการผ่านการคัดเลือก!!",
                        style = sh(12f, SHFont.semibold), color = SH.red, textAlign = TextAlign.Center,
                    )
                } else if (flow.verify == VerifyStatus.waiting) {
                    Text(
                        "ส่งยืนยันตัวตนแล้ว · ทีมงานตรวจภายใน 1–3 วันทำการ",
                        style = sh(12f, SHFont.semibold), color = SH.muted, textAlign = TextAlign.Center,
                    )
                }
                Column(Modifier.fillMaxWidth().padding(top = 6.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (kycDone) {
                        SHRedButton(title = "แชร์กิจกรรมนี้", icon = Ph.shareFat, height = 46f, action = onClose)
                    } else {
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .height(46.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(PK.fieldFill)
                                .tap {
                                    Haptics.impact(Haptics.Style.light)
                                    onClose()
                                },
                            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            PIcon(Ph.shareFat, size = 18f, weight = PhWeight.regular, tint = SH.ink)
                            Text("แชร์กิจกรรมนี้", style = sh(15f, SHFont.semibold), color = SH.ink)
                        }
                        SHRedButton(title = "ยืนยันตัวตน", icon = Ph.identificationCard, height = 46f, action = onKyc)
                    }
                }
            }
            Box(
                Modifier
                    .align(Alignment.TopEnd)
                    .size(36.dp)
                    .tap { onClose() },
                contentAlignment = Alignment.Center,
            ) {
                PIcon(Ph.x, size = 16f, tint = SH.muted)
            }
        }
    }
}
