package co.salehere.starcard.ui.salehere.starflow

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.AppContext
import co.salehere.starcard.model.CardLibrary
import co.salehere.starcard.model.FlowDialog
import co.salehere.starcard.model.FlowScreen
import co.salehere.starcard.model.LabMode
import co.salehere.starcard.model.LabSync
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.LocalStarFlow
import co.salehere.starcard.model.Portfolio
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.StarCampaign
import co.salehere.starcard.model.StarFlow
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
import co.salehere.starcard.ui.LocalDismiss
import co.salehere.starcard.ui.profile.PK
import co.salehere.starcard.ui.salehere.SH
import co.salehere.starcard.ui.tap
import co.salehere.starcard.ui.widgets.FlowLayout
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * แผงควบคุมของ flow ใหม่ (= `panel.js` ของเว็บ): STATE ของ Unbox 14 ขั้น · ข้อมูลใน Star Profile · ฉากสำเร็จรูป · ล้างข้อมูล
 *
 * เปิดจากปุ่มลอย "Lab" ที่อยู่ทุกหน้า (ผู้ใช้ 23 ก.ย. 2569: "ทำ button ลอยทุกที่ แล้ว config แบบนี้ได้เลยทุกหน้า")
 * กติกาเหมือนเว็บ: กระโดดไปขั้นไหน ขั้นก่อนหน้าติ๊กข้อมูลให้เอง · ติ๊กข้อมูลออกตอนอยู่ขั้นที่ต้องมีแล้ว = ย้อน state กลับ
 * ปิดแผงผ่าน `LocalDismiss` — ผู้เปิด (shell) ใส่ตัวปิดให้ (= `@Environment(\.dismiss)`)
 * - onGo: กระโดด: หน้า + dialog ที่ต้องเปิด
 */
@Composable
fun FlowLab(
    stage: Int,
    campaign: StarCampaign,
    onGo: (FlowScreen?, FlowDialog?) -> Unit,
    toast: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val flow = LocalStarFlow.current
    val photos = LocalPhotoStore.current
    val dismiss = LocalDismiss.current
    var confirmClear by remember { mutableStateOf(false) }
    var confirmClearAll by remember { mutableStateOf(false) }
    var confirmLab by remember { mutableStateOf(false) }

    val red = SHColor.red
    val ink = SHColor.ink
    val muted = SHColor.textSecondary

    fun jump(back: Int) {
        val r = flow.goto(back)
        toast("ย้อนกลับไป \"${StarFlow.stages[back].title}\" เพราะข้อมูลนี้หายไป")
        dismiss()
        onGo(r.first, r.second)
    }

    fun clearFlow() {
        Haptics.impact(Haptics.Style.heavy)
        flow.reset(); dismiss(); onGo(null, null)
        toast("ล้างข้อมูล flow ใหม่แล้ว")
    }

    fun clearEverything() {
        Haptics.impact(Haptics.Style.heavy)
        flow.reset()
        Profile.me.resetAll(); photos?.clearProfile(); Portfolio.shared.resetAll()
        CardLibrary.shared.records.map { it.id }.forEach { CardLibrary.shared.delete(it) }
        dismiss(); onGo(null, null)
        toast("ล้างข้อมูลทั้งหมดแล้ว")
    }

    Column(modifier.fillMaxSize().background(Color.White)) {
        // แถบหัวแบบ `navigationTitle(... inline)` + ปุ่ม ✕ มุมขวา
        Box(Modifier.fillMaxWidth().statusBarsPadding().height(44.dp)) {
            Text("Unbox × StarCard", style = sh(17f, SHFont.semibold), color = ink, modifier = Modifier.align(Alignment.Center))
            Box(
                Modifier.align(Alignment.CenterEnd).padding(end = 12.dp).size(36.dp).tap { dismiss() },
                contentAlignment = Alignment.Center,
            ) {
                PIcon(Ph.x, size = 16f, tint = ink)
            }
        }
        Column(
            Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .navigationBarsPadding()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            // MARK: โหมดลองทำ — การ์ดกลางบน sync-server (ดู `LabSync`)
            LabSection(onToggle = { confirmLab = true })

            // MARK: STATE ของ Unbox — 14 ขั้น ป้าย เดิม/แทรก · ขั้นปัจจุบันพื้นแดงอ่อน
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                LabHeader("STATE ของ UNBOX", "กดเพื่อไป · ขั้นก่อนหน้าติ๊กข้อมูลให้เอง")
                StarFlow.stages.forEach { s ->
                    val now = s.id == stage
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (now) SHColor.redSoft else Color.Transparent)
                            .tap {
                                val r = flow.goto(s.id)
                                dismiss()
                                onGo(r.first, r.second)
                                s.note?.let { toast(it) }
                            }
                            .padding(horizontal = 8.dp, vertical = 7.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            if (s.inserted) "แทรก" else "เดิม",
                            style = sh(11f, if (s.inserted) SHFont.bold else SHFont.regular),
                            color = if (s.inserted) red else SHColor.textTertiary,
                            modifier = Modifier.width(34.dp),
                        )
                        Box(
                            Modifier
                                .size(30.dp)
                                .background(
                                    if (s.id == 0 && now) SHColor.green else (if (now) red.opacity(0.15) else PK.fieldFill),
                                    CircleShape,
                                ),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text("${s.id}", style = sh(13f, SHFont.bold), color = if (s.id == 0 && now) Color.White else ink)
                        }
                        Text(
                            s.title,
                            style = sh(14f, if (now) SHFont.bold else SHFont.regular),
                            color = if (now && s.inserted) red else ink,
                            textAlign = TextAlign.Start,
                            modifier = Modifier.weight(1f),
                        )
                    }
                }
            }

            // MARK: ข้อมูลใน Star Profile — ติ๊กเข้า/ออก + "ขอที่ขั้น N"
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                LabHeader("ข้อมูลใน STAR PROFILE", "ติ๊กออก = ย้อน state กลับไปขั้นที่ขอ")
                FlowLayout(spacing = 4f, modifier = Modifier.padding(bottom = 2.dp)) {
                    Text("Star Card:", style = sh(14f), color = ink)
                    Text(
                        if (flow.isStar) "มีแล้ว (เป็น STAR)" else if (flow.hasCard) "มีแล้ว (ยังไม่ยืนยันตัวตน)" else "ยังไม่มี",
                        style = sh(14f, SHFont.bold), color = if (flow.hasCard) PK.redDark else muted,
                    )
                    Text("· กิจกรรม", style = sh(14f), color = ink)
                    Text(campaign.episode, style = sh(14f, SHFont.bold), color = PK.redDark)
                }
                StarFlow.rules.forEach { r ->
                    val on = r.key?.let { flow.has(it) } ?: flow.isVerified
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .tap {
                                Haptics.impact(Haptics.Style.light)
                                flow.tick(r.key, on = !on, stage = stage)?.let { jump(it) }
                            }
                            .padding(vertical = 6.dp),
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        val box = RoundedCornerShape(5.dp)
                        Box(
                            Modifier
                                .size(20.dp)
                                .background(if (on) SH.blue else Color.White, box)
                                .strokeInside(if (on) SH.blue else SHColor.strokeStrong, 1.3f, radius = 5f),
                            contentAlignment = Alignment.Center,
                        ) {
                            if (on) PIcon(Ph.check, size = 11f, tint = Color.White)
                        }
                        Text(r.key?.label ?: "ยืนยันตัวตน (KYC)", style = sh(14f), color = ink, modifier = Modifier.weight(1f))
                        Text("ขอที่ขั้น ${r.askAt}", style = sh(11.5f), color = SHColor.textTertiary)
                    }
                }
                Row(
                    Modifier.padding(top = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("สถานะ KYC", style = sh(12.5f, SHFont.semibold), color = muted)
                    // `Picker(.segmented)` — รางเทา ลูกบิดขาว
                    Row(
                        Modifier
                            .weight(1f)
                            .height(32.dp)
                            .background(rgb(0.93, 0.93, 0.94), RoundedCornerShape(9.dp))
                            .padding(2.dp),
                    ) {
                        listOf(
                            VerifyStatus.none to "ยังไม่ทำ",
                            VerifyStatus.waiting to "รอตรวจ",
                            VerifyStatus.approved to "ผ่าน",
                        ).forEach { (v, label) ->
                            val sel = flow.verify == v
                            Box(
                                Modifier
                                    .weight(1f)
                                    .fillMaxHeight()
                                    .then(
                                        if (sel) Modifier
                                            .glShadow(Color.Black.opacity(0.12), 4f, 1f, corner = 7f)
                                            .background(Color.White, RoundedCornerShape(7.dp))
                                        else Modifier,
                                    )
                                    .tap {
                                        val back = if (v == VerifyStatus.none) flow.tick(null, on = false, stage = stage) else null
                                        if (v == VerifyStatus.none && back != null) jump(back) else flow.verify = v
                                    },
                                contentAlignment = Alignment.Center,
                            ) {
                                Text(label, style = sh(13f, if (sel) SHFont.semibold else SHFont.medium), color = ink)
                            }
                        }
                    }
                }
            }

            // MARK: ฉากสำเร็จรูป
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                LabHeader("ฉากสำเร็จรูป", "ตั้งข้อมูล + สถานะงานในคลิกเดียว")
                FlowLayout(spacing = 8f) {
                    StarFlow.presets.forEach { p ->
                        Row(
                            Modifier
                                .height(32.dp)
                                .clip(CircleShape)
                                .background(PK.fieldFill)
                                .tap {
                                    flow.apply(p)
                                    dismiss()
                                    onGo(null, null)
                                    toast("ตั้งฉาก: ${p.title}")
                                }
                                .padding(horizontal = 11.dp),
                            horizontalArrangement = Arrangement.spacedBy(5.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(p.title, style = sh(12.5f, SHFont.semibold), color = ink)
                            if (p.verify == VerifyStatus.approved) PIcon(Ph.sealCheck, size = 12f, weight = PhWeight.fill, tint = GL.verified)
                        }
                    }
                    Box(
                        Modifier
                            .height(32.dp)
                            .border(1.dp, SHColor.strokeStrong, CircleShape)
                            .clip(CircleShape)
                            .tap {
                                flow.revealSeen = false
                                dismiss()
                            }
                            .padding(horizontal = 11.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("เล่น motion การ์ดเกิดใหม่", style = sh(12.5f, SHFont.semibold), color = ink)
                    }
                }
            }

            // MARK: ล้างข้อมูล
            Column(Modifier.padding(bottom = 30.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                LabHeader("ล้างข้อมูล", "")
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Box(
                        Modifier
                            .weight(1f)
                            .height(42.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(SHColor.redSoft)
                            .tap { confirmClear = true },
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("ล้าง flow ใหม่", style = sh(13f, SHFont.bold), color = red)
                    }
                    Box(
                        Modifier
                            .weight(1f)
                            .height(42.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(red)
                            .tap { confirmClearAll = true },
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("ล้างทั้งหมด + การ์ด", style = sh(13f, SHFont.bold), color = Color.White)
                    }
                }
                Text(
                    "flow ใหม่ = สถานะงาน · ข้อมูล Star Profile · KYC · ยินยอม · การ์ดเกิด — ทั้งหมด = เพิ่มหน้า \"ข้อมูลของฉัน\" รูป ผลงาน และการ์ดทุกใบ",
                    style = sh(11.5f), color = SHColor.textTertiary,
                )
            }
        }
    }

    if (confirmClear) {
        ActionSheet(
            title = "ล้างข้อมูล flow ใหม่?",
            message = "กลับเป็นผู้ใช้ใหม่: ยังไม่มี Star Profile ยังไม่ยืนยันตัวตน ยังไม่สมัครงาน",
            action = "ล้างข้อมูล",
            onAction = { confirmClear = false; clearFlow() },
            onCancel = { confirmClear = false },
        )
    }
    if (confirmLab) {
        val on = LabMode.isOn
        ActionSheet(
            title = if (on) "ปิดโหมดลองทำ?" else "เปิดโหมดลองทำ?",
            message = if (on) {
                "ข้อมูลเดิมก่อนเข้าโหมดจะถูกคืนกลับ ของที่แก้ระหว่างลองจะหาย (การ์ดกลางยังอยู่บน server) · เปิดแอปใหม่อีกครั้งหลังแอปปิด"
            } else {
                "สำรองข้อมูลเดิมทั้งหมดไว้ก่อน แล้วคลังการ์ดจะเหลือใบเดียวคือการ์ดกลางที่ซิงก์กับ iOS · เปิดแอปใหม่อีกครั้งหลังแอปปิด"
            },
            action = if (on) "ปิดแอป · คืนข้อมูลเดิม" else "ปิดแอป · เริ่มโหมดลองทำ",
            onAction = { confirmLab = false; LabMode.request(!on) },
            onCancel = { confirmLab = false },
        )
    }
    if (confirmClearAll) {
        ActionSheet(
            title = "ล้างทั้งหมด?",
            message = "ลบข้อมูลของฉัน รูป ผลงาน และการ์ดทุกใบ ย้อนกลับไม่ได้",
            action = "ล้างทั้งหมด",
            onAction = { confirmClearAll = false; clearEverything() },
            onCancel = { confirmClearAll = false },
        )
    }
}

/** สถานะโหมดลองทำ + ปุ่มเปิด/ปิด (ยืนยันก่อน — แอปปิดตัวเอง) */
@Composable
private fun LabSection(onToggle: () -> Unit) {
    val sync = LabSync.shared
    val ink = SHColor.ink
    val on = LabMode.isOn
    val server = remember { LabMode.server }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        LabHeader("โหมดลองทำ", "การ์ดกลาง iOS ⇄ Android")
        Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(PK.fieldFill).padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.size(9.dp).background(labColor(sync.phase, on), CircleShape))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    if (on) labPhaseText(sync.phase) + " · rev ${sync.rev}" else "ปิดอยู่ · ใช้ข้อมูลในเครื่อง",
                    style = sh(14f, SHFont.bold), color = ink,
                )
                val e = sync.lastEcho
                if (on && e != null) {
                    Text(
                        if (e == 0) "รับของอีกเครื่องล่าสุด: ค่าตรงกันทุกจุด" else "รับของอีกเครื่องล่าสุด: ค่าเพี้ยน $e จุด (ดูรายละเอียดบนหน้าเว็บ)",
                        style = sh(12f), color = if (e == 0) SHColor.green else SHColor.red,
                    )
                }
                Text(server, style = sh(11.5f), color = SHColor.textTertiary)
            }
        }
        Box(
            Modifier
                .fillMaxWidth()
                .height(42.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(if (on) PK.fieldFill else ink)
                .border(1.dp, ink.opacity(if (on) 0.2 else 0.0), RoundedCornerShape(10.dp))
                .tap { onToggle() },
            contentAlignment = Alignment.Center,
        ) {
            Text(
                if (on) "ปิดโหมดลองทำ · คืนข้อมูลเดิม" else "เปิดโหมดลองทำ",
                style = sh(13f, SHFont.bold), color = if (on) ink else Color.White,
            )
        }
        Text(
            "เก็บการ์ดเป็น JSON ก้อนเดียวที่ server กลาง แก้จากเครื่องไหนอีกเครื่องเห็นตาม · ข้อมูลเดิมถูกสำรองไว้ ปิดโหมดแล้วได้คืน",
            style = sh(11.5f), color = SHColor.textTertiary,
        )
    }
}

/** สีจุดสถานะ (= `LabFab.color` ของ iOS) — เขียว ซิงก์แล้ว · แดง ต่อไม่ได้ · ส้ม กำลังต่อ/ส่ง */
internal fun labColor(p: LabSync.Phase, on: Boolean): Color {
    if (!on) return SHColor.textTertiary
    return when (p) {
        LabSync.Phase.synced -> SHColor.green
        is LabSync.Phase.offline -> SHColor.red
        else -> rgb(1.0, 0.62, 0.1)
    }
}

/** ข้อความสถานะ (= `LabFab.phaseText` ของ iOS) */
internal fun labPhaseText(p: LabSync.Phase): String = when (p) {
    LabSync.Phase.idle, LabSync.Phase.connecting -> "กำลังต่อ server"
    LabSync.Phase.synced -> "ซิงก์แล้ว"
    LabSync.Phase.pushing -> "กำลังส่ง"
    is LabSync.Phase.offline -> "ต่อไม่ได้ · ${p.why}"
}

/** ป้ายโหมดลองทำบนปุ่มลอย: rev ที่ถืออยู่ + ผลตรวจล่าสุดถ้าเพี้ยน */
private fun labBadge(sync: LabSync): String {
    if (sync.phase is LabSync.Phase.offline) return "ลองทำ · ต่อไม่ได้"
    val e = sync.lastEcho
    if (e != null && e > 0) return "ลองทำ r${sync.rev} · เพี้ยน $e"
    return "ลองทำ r${sync.rev}"
}

@Composable
private fun LabHeader(t: String, sub: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(t, style = sh(15f, SHFont.heavy).copy(letterSpacing = 0.5.sp), color = SHColor.ink, modifier = Modifier.alignByBaseline())
        Text(sub, style = sh(11.5f), color = SHColor.textTertiary, modifier = Modifier.alignByBaseline())
    }
}

/** ปุ่มลอย "Lab" — อยู่ทุกหน้าทุกที่ ลากขึ้นลงตามขอบขวาได้ (จำตำแหน่งไว้ = `@AppStorage("labFab.y")`) */
@Composable
fun LabFab(action: () -> Unit, modifier: Modifier = Modifier) {
    val prefs = remember { AppContext.prefs }
    var savedY by remember { mutableFloatStateOf(prefs.getFloat("labFab.y", 0.55f)) }
    var drag by remember { mutableFloatStateOf(0f) }
    var pill by remember { mutableStateOf(IntSize.Zero) }
    val dens = LocalDensity.current

    BoxWithConstraints(modifier.fillMaxSize()) {
        val h = maxHeight.value
        val w = maxWidth.value
        fun clampY(v: Float) = min(max(v, 80f), h - 120f)
        val y = clampY(h * savedY + drag)
        Row(
            Modifier
                .offset {
                    // ยื่นพ้นขอบขวานิดหน่อย — ไม่บังปุ่มของหน้า · ชิดขวาเสมอ ป้ายยาวขึ้น (โหมดลองทำ) ก็ไม่ล้นจอ
                    val right = with(dens) { (w + 6f).dp.toPx() }
                    val cy = with(dens) { y.dp.toPx() }
                    IntOffset((right - pill.width).roundToInt(), (cy - pill.height / 2f).roundToInt())
                }
                .onSizeChanged { pill = it }
                .pointerInput(h) {
                    detectDragGestures(
                        onDragEnd = {
                            savedY = clampY(h * savedY + drag) / h
                            drag = 0f
                            prefs.edit().putFloat("labFab.y", savedY).apply()
                        },
                        onDragCancel = { drag = 0f },
                    ) { change, amount ->
                        change.consume()
                        drag += amount.y / dens.density
                    }
                }
                .glShadow(Color.Black.opacity(0.25), 6f, 3f)
                .height(30.dp)
                .clip(CircleShape)
                .background(SHColor.ink.opacity(0.78))
                .border(0.6.dp, Color.White.opacity(0.25), CircleShape)
                .tap { action() }
                .padding(start = 10.dp, end = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(5.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (LabMode.isOn) {
                val sync = LabSync.shared
                Box(Modifier.size(7.dp).background(labColor(sync.phase, on = true), CircleShape))
                Text(labBadge(sync), style = sh(11f, SHFont.bold).copy(fontFeatureSettings = "tnum"), color = Color.White)
            } else {
                PIcon(Ph.arrowsClockwise, size = 11f, tint = Color.White)
                Text("Lab", style = sh(11f, SHFont.bold), color = Color.White)
            }
        }
    }
}
