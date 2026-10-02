package co.salehere.starcard.ui.salehere.starflow

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.IntOffset
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.model.LocalStarFlow
import co.salehere.starcard.model.StarCampaign
import co.salehere.starcard.model.StarFlow
import co.salehere.starcard.model.WizKind
import co.salehere.starcard.model.WizStep
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * กรอกหัวข้อ Star Profile ข้อเดียว (หรือหลายข้อ) จากที่อื่นในแอป — ตู้ widget · ช่องประบนการ์ด
 *
 * ห่อ `StarWizard` แบบ `one` + KYC จำลอง ไว้ในหน้าเดียว ไม่ต้องพึ่ง `SaleHereShell`
 * - onDone: true = กรอกจบ · false = ออกกลางทาง
 */
@Composable
fun StarTopicFill(steps: List<WizStep>, onDone: (Boolean) -> Unit, modifier: Modifier = Modifier) {
    val flow = remember { StarFlow.shared }
    var kyc by remember { mutableStateOf<(() -> Unit)?>(null) }
    var kycShown by remember { mutableStateOf(false) }
    var toastText by remember { mutableStateOf("") }
    var toastShown by remember { mutableStateOf(false) }
    var toastToken by remember { mutableIntStateOf(0) }
    val scope = rememberCoroutineScope()

    CompositionLocalProvider(LocalStarFlow provides flow) {
        Box(modifier.fillMaxSize()) {
            StarWizard(
                kind = WizKind.one,
                campaign = StarCampaign.mock[0],
                steps = steps,
                onFinish = { onDone(true) },
                onExit = { _, _ -> onDone(false) },
                onKyc = { done ->
                    kyc = done
                    kycShown = true
                },
                toast = { t ->
                    toastText = t
                    toastShown = true
                    val token = ++toastToken
                    scope.launch {
                        delay(2200)
                        if (token == toastToken) toastShown = false
                    }
                },
            )
            AnimatedVisibility(
                visible = kycShown,
                enter = slideInVertically(Motion.page.spec<IntOffset>()) { it },
                exit = slideOutVertically(Motion.page.spec<IntOffset>()) { it },
            ) {
                KycMockPage(
                    onClose = { kycShown = false; kyc = null },
                    onDone = {
                        val done = kyc
                        kycShown = false
                        kyc = null
                        done?.invoke()
                    },
                )
            }
            AnimatedVisibility(
                visible = toastShown,
                modifier = Modifier.align(Alignment.BottomCenter).navigationBarsPadding(),
                enter = slideInVertically(Motion.snap.spec<IntOffset>()) { it } + fadeIn(Motion.snap.float),
                exit = slideOutVertically(Motion.snap.spec<IntOffset>()) { it } + fadeOut(Motion.snap.float),
            ) {
                FlowToast(text = toastText)
            }
        }
    }
}
