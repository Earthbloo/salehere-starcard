package co.salehere.starcard.ui.salehere.starflow

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.model.LocalStarFlow
import co.salehere.starcard.model.VerifyStatus
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHColor
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.salehere.SH
import co.salehere.starcard.ui.salehere.SHBarIcon
import co.salehere.starcard.ui.salehere.SHNavBar
import co.salehere.starcard.ui.salehere.SHRedButton
import co.salehere.starcard.ui.tap
import kotlinx.coroutines.delay

private enum class KycStep { type, howTo, card, face, checking, done }

/**
 * ยืนยันตัวตนจำลอง (KYC ของแอปหลัก ย่อเหลือ 4 ขั้น): เลือกเอกสาร → วิธีถ่าย → ถ่ายบัตร + ใบหน้า → AI ตรวจ → ส่งรอทีมงาน
 *
 * จบแล้ว `verify = waiting` (ทีมงานตรวจ 1–3 วัน) — เปลี่ยนเป็น approved ได้จากแผง lab
 */
@Composable
fun KycMockPage(onClose: () -> Unit, onDone: () -> Unit, modifier: Modifier = Modifier) {
    val flow = LocalStarFlow.current
    var step by remember { mutableStateOf(KycStep.type) }
    var doc by remember { mutableStateOf("บัตรประชาชน") }

    // AI ตรวจ 1.4 วินาทีแล้วไปหน้าส่งแล้ว (= `check()`)
    LaunchedEffect(step) {
        if (step != KycStep.checking) return@LaunchedEffect
        delay(1400)
        Haptics.impact(Haptics.Style.medium)
        step = KycStep.done
    }

    Column(modifier.fillMaxSize().background(Color.White)) {
        SHNavBar(
            title = "ยืนยันตัวตน",
            left = {
                SHBarIcon(icon = Ph.caretLeft, size = 26f, action = {
                    when (step) {
                        KycStep.type -> onClose()
                        KycStep.howTo -> step = KycStep.type
                        KycStep.card -> step = KycStep.howTo
                        KycStep.face -> step = KycStep.card
                        else -> Unit
                    }
                })
            },
            right = { Gap(32f, 32f) },
        )
        AnimatedContent(
            targetState = step,
            modifier = Modifier.weight(1f).fillMaxWidth(),
            transitionSpec = {
                if (targetState == KycStep.done) fadeIn(Motion.settle.float) togetherWith fadeOut(Motion.settle.float)
                else EnterTransition.None togetherWith ExitTransition.None
            },
            label = "kycStep",
        ) { s ->
            Box(Modifier.fillMaxSize()) {
                when (s) {
                    KycStep.type -> KycTypePage(doc = doc, onDoc = { doc = it }, onNext = { step = KycStep.howTo })
                    KycStep.howTo -> KycHowToPage(doc = doc, onNext = { step = KycStep.card })
                    KycStep.card -> KycCameraPage(face = false, doc = doc, onShoot = { step = KycStep.face })
                    KycStep.face -> KycCameraPage(face = true, doc = doc, onShoot = { step = KycStep.checking })
                    KycStep.checking -> Column(
                        Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
                    ) {
                        Spinner(color = SH.red, size = 36f)
                        Text("AI กำลังตรวจสอบข้อมูล…", style = sh(15f, SHFont.semibold), color = SH.ink)
                    }
                    KycStep.done -> Column(
                        Modifier.fillMaxSize().navigationBarsPadding().padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(14.dp),
                    ) {
                        Spacer(Modifier.weight(1f))
                        Box(Modifier.size(96.dp).background(SHColor.greenSoft, CircleShape), contentAlignment = Alignment.Center) {
                            PIcon(Ph.checkCircle, size = 56f, weight = PhWeight.fill, tint = SHColor.green)
                        }
                        Text("ส่งข้อมูลยืนยันตัวตนแล้ว", style = sh(19f, SHFont.bold), color = SH.ink)
                        Text(
                            "ทีมงานตรวจภายใน 1–3 วันทำการ\nระหว่างนี้สมัครงานได้ตามปกติ",
                            style = sh(14f).lineSpaced(3f), color = SH.muted, textAlign = TextAlign.Center,
                        )
                        Spacer(Modifier.weight(1f))
                        SHRedButton(title = "เสร็จสิ้น", action = {
                            if (flow.verify == VerifyStatus.none) flow.verify = VerifyStatus.waiting
                            onDone()
                        })
                    }
                }
            }
        }
    }
}

@Composable
private fun KycTypePage(doc: String, onDoc: (String) -> Unit, onNext: () -> Unit) {
    Column(
        Modifier.fillMaxSize().navigationBarsPadding().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text("เลือกเอกสารที่ใช้ยืนยันตัวตน", style = sh(17f, SHFont.bold), color = SH.ink)
        listOf("บัตรประชาชน", "หนังสือเดินทาง").forEach { d ->
            val on = doc == d
            val shape = RoundedCornerShape(12.dp)
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(shape)
                    .background(Color.White)
                    .strokeInside(if (on) SH.red else SH.line, 1f, radius = 12f)
                    .tap {
                        Haptics.impact(Haptics.Style.light)
                        onDoc(d)
                    }
                    .padding(14.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                PIcon(Ph.identificationCard, size = 24f, weight = PhWeight.regular, tint = SH.red)
                Text(d, style = sh(15f, SHFont.semibold), color = SH.ink, modifier = Modifier.weight(1f))
                Box(Modifier.size(22.dp).strokeInside(if (on) SH.red else SH.line, if (on) 6f else 1.2f))
            }
        }
        Spacer(Modifier.weight(1f))
        SHRedButton(title = "ถัดไป", action = onNext)
    }
}

@Composable
private fun KycHowToPage(doc: String, onNext: () -> Unit) {
    Column(
        Modifier.fillMaxSize().navigationBarsPadding().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Text("วิธีถ่าย$doc", style = sh(17f, SHFont.bold), color = SH.ink)
        listOf(
            "วางบัตรบนพื้นเรียบ ไม่มีแสงสะท้อน",
            "ให้บัตรอยู่ในกรอบ เห็นครบทั้ง 4 มุม",
            "ถ่ายใบหน้าตรง ไม่ใส่หมวก/แว่นดำ",
            "ข้อมูลใช้เพื่อยืนยันตัวตนเท่านั้น",
        ).forEach { t ->
            Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                PIcon(Ph.checkCircle, size = 18f, weight = PhWeight.fill, tint = SHColor.green)
                Text(t, style = sh(14f), color = SH.ink)
            }
        }
        Spacer(Modifier.weight(1f))
        SHRedButton(title = "เริ่มถ่าย", icon = Ph.camera, action = onNext)
    }
}

@Composable
private fun KycCameraPage(face: Boolean, doc: String, onShoot: () -> Unit) {
    Box(Modifier.fillMaxSize().background(rgb(0.08, 0.09, 0.11))) {
        Column(
            Modifier.fillMaxSize().navigationBarsPadding().padding(top = 30.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            Text(if (face) "ถ่ายใบหน้าของคุณ" else "ถ่ายด้านหน้า$doc", style = sh(16f, SHFont.bold), color = Color.White)
            if (face) {
                Canvas(Modifier.size(220.dp, 290.dp)) {
                    val w = 2.dp.toPx()
                    drawOval(
                        Color.White.opacity(0.9), topLeft = Offset(w / 2, w / 2), size = Size(size.width - w, size.height - w),
                        style = Stroke(w, pathEffect = PathEffect.dashPathEffect(floatArrayOf(8.dp.toPx(), 6.dp.toPx()))),
                    )
                }
            } else {
                Box(Modifier.size(300.dp, 190.dp).strokeInside(Color.White.opacity(0.9), 2f, radius = 14f))
            }
            Text(
                if (face) "ให้ใบหน้าอยู่ในกรอบ" else "ให้บัตรอยู่ในกรอบ เห็นครบ 4 มุม",
                style = sh(13f), color = Color.White.opacity(0.7),
            )
            Spacer(Modifier.weight(1f))
            Box(
                Modifier
                    .padding(bottom = 30.dp)
                    .size(80.dp)
                    .tap {
                        Haptics.impact(Haptics.Style.medium)
                        onShoot()
                    },
                contentAlignment = Alignment.Center,
            ) {
                // ปุ่มชัตเตอร์: วงขาว 68 + วงแหวนขาวโปร่ง 4 ห่างออกไป 6
                Box(Modifier.size(80.dp).strokeInside(Color.White.opacity(0.5), 4f))
                Box(Modifier.size(68.dp).background(Color.White, CircleShape))
            }
        }
    }
}
