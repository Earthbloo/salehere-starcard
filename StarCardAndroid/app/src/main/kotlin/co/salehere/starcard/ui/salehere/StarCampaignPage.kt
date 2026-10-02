package co.salehere.starcard.ui.salehere

import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.model.CampaignPhase
import co.salehere.starcard.model.LocalStarFlow
import co.salehere.starcard.model.StarCampaign
import co.salehere.starcard.model.StarDataKey
import co.salehere.starcard.model.StarRow
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHColor
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.profile.PK
import co.salehere.starcard.ui.tap
import kotlinx.coroutines.delay
import java.util.Locale
import kotlin.math.max

/**
 * หน้ารายละเอียดกิจกรรม Sale Here STAR — ตาม screenshot แอปหลัก 22 ก.ย. 2569
 *
 * ปก · ชื่อ · วันที่+แชร์ · แท็บ "วิธีการร่วมกิจกรรม / รีวิว" · เนื้อหา · แถบล่างนับถอยหลัง + ปุ่มลงทะเบียน
 */
@Composable
fun StarCampaignPage(
    campaign: StarCampaign,
    onBack: () -> Unit,
    /** ปุ่มหลักแถบล่าง — ลงทะเบียน / ตอบรับ / รายละเอียดการรีวิว ตาม `flow.phase` (ผู้เรียกตัดสินว่าไปหน้าไหน) */
    onMain: () -> Unit = {},
    /** "เติมเลย" ในบรรทัดใต้แถบล่าง (ลงทะเบียนแล้ว แต่การ์ดยังขาด) → Star Profile */
    onFill: () -> Unit = {},
    /** กดค้างชื่อบนแถบแดง → แผง lab */
    onLab: () -> Unit = {},
    modifier: Modifier = Modifier,
) {
    var tab by remember { mutableStateOf(CampaignTab.howTo) }

    Column(modifier.fillMaxSize().background(Color.White)) {
        SHNavBar(
            title = "Sale Here STAR",
            modifier = Modifier.shLongPress(0.6) { Haptics.impact(Haptics.Style.medium); onLab() },
            left = { SHBarIcon(icon = Ph.caretLeft, size = 26f, action = onBack) },
            right = {
                SHBarIcon(icon = Ph.headset)
                SHBarIcon(icon = Ph.bell)
            },
        )
        Column(
            Modifier
                .weight(1f)
                .fillMaxWidth()
                .background(Color.White)
                .verticalScroll(rememberScrollState()),
        ) {
            Image(
                painterResource(campaign.cover), contentDescription = null, contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxWidth().aspectRatio(597f / 397f).clipToBounds(),
            )
            Row(
                Modifier.padding(horizontal = 16.dp).padding(top = 14.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                StarBrandLogo(name = campaign.logo, size = 40f)
                Text(campaign.headline, style = shSpaced(17f, SHFont.semibold, 3f), color = SH.ink)
            }
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp).padding(top = 12.dp, bottom = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                    PIcon(Ph.calendarBlank, size = 16f, weight = PhWeight.regular, tint = SH.muted)
                    Text(campaign.dateRange, style = sh(15f, SHFont.medium), color = SH.muted)
                }
                Spacer(Modifier.weight(1f))
                Row(
                    Modifier
                        .height(34.dp)
                        .border(1.2.dp, SH.red, RoundedCornerShape(8.dp))
                        .tap { Haptics.impact(Haptics.Style.light) }
                        .padding(horizontal = 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    PIcon(Ph.shareFat, size = 16f, weight = PhWeight.regular, tint = SH.red)
                    Text("แชร์", style = sh(14f, SHFont.semibold), color = SH.red)
                }
            }
            Box(Modifier.fillMaxWidth().height(1.dp).background(SH.line))
            CampaignTabs(tab) { tab = it }
            Box(Modifier.fillMaxWidth().height(1.dp).background(SH.line))
            Crossfade(
                targetState = tab, animationSpec = Motion.snap.spec(), label = "campaignTab",
                modifier = Modifier.padding(horizontal = 20.dp).padding(top = 18.dp).padding(bottom = 24.dp),
            ) { t ->
                when (t) {
                    CampaignTab.howTo -> CampaignHowTo(campaign)
                    CampaignTab.reviews -> Column(
                        Modifier.fillMaxWidth().padding(vertical = 40.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        PIcon(Ph.chatCircleText, size = 36f, weight = PhWeight.regular, tint = SH.hint)
                        Text("ยังไม่มีรีวิวจากกิจกรรมนี้", style = sh(14f, SHFont.medium), color = SH.hint)
                    }
                }
            }
        }
        CampaignBottomBar(campaign = campaign, onMain = onMain, onFill = onFill)
    }
}

private enum class CampaignTab { howTo, reviews }

@Composable
private fun CampaignHowTo(campaign: StarCampaign) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(campaign.howTo, style = shSpaced(15f, SHFont.regular, 5f), color = SH.ink)
        if (campaign.reward.isNotEmpty()) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .background(SH.page, RoundedCornerShape(10.dp))
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text("ของรางวัล", style = sh(14f, SHFont.bold), color = SH.ink)
                Text(campaign.reward, style = sh(14f), color = SH.muted)
                Text("จำนวนสิทธิ์", style = sh(14f, SHFont.bold), color = SH.ink, modifier = Modifier.padding(top = 4.dp))
                Text("${campaign.quota} สิทธิ์ · ลงทะเบียนแล้ว ${campaign.registered} คน", style = sh(14f), color = SH.muted)
            }
        }
        if (campaign.timeline.isNotEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Timeline แคมเปญ", style = sh(14f, SHFont.bold), color = SH.ink)
                campaign.timeline.forEach { t ->
                    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Text(t.first, style = sh(13f), color = SH.muted)
                        Spacer(Modifier.weight(1f))
                        Text(t.second, style = sh(13f, SHFont.semibold), color = SH.ink)
                    }
                }
            }
        }
    }
}

@Composable
private fun CampaignTabs(tab: CampaignTab, onTab: (CampaignTab) -> Unit) {
    Row(Modifier.fillMaxWidth().height(50.dp)) {
        CampaignTabItem(CampaignTab.howTo, Ph.clipboardText, "วิธีการร่วมกิจกรรม", tab, onTab)
        CampaignTabItem(CampaignTab.reviews, Ph.notePencil, "รีวิว", tab, onTab)
    }
}

@Composable
private fun RowScope.CampaignTabItem(t: CampaignTab, icon: Ph, title: String, tab: CampaignTab, onTab: (CampaignTab) -> Unit) {
    val on = tab == t
    val tint by animateColorAsState(if (on) SH.red else SH.muted, Motion.snap.spec(), label = "campaignTabTint")
    val bar by animateColorAsState(if (on) SH.red else Color.Transparent, Motion.snap.spec(), label = "campaignTabBar")
    Box(
        Modifier
            .weight(1f)
            .fillMaxHeight()
            .tap {
                if (on) return@tap
                Haptics.impact(Haptics.Style.light)
                onTab(t)
            },
    ) {
        Row(
            Modifier.align(Alignment.Center),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PIcon(icon, size = 20f, weight = PhWeight.regular, tint = tint)
            Text(title, style = sh(15f, if (on) SHFont.bold else SHFont.medium), color = tint, maxLines = 1)
        }
        Box(Modifier.align(Alignment.BottomCenter).fillMaxWidth().height(3.dp).background(bar))
    }
}

/** แถบล่างติดจอ — บรรทัดบอกสถานะ + (flow ใหม่) บรรทัดบอกว่ามี Star Card หรือยัง + ปุ่มตาม `BrandCampaignState` */
@Composable
private fun CampaignBottomBar(campaign: StarCampaign, onMain: () -> Unit, onFill: () -> Unit) {
    val flow = LocalStarFlow.current
    val shadow = Color.Black.opacity(0.06)
    Box(
        Modifier
            .fillMaxWidth()
            // เงาขึ้นข้างบน (= `.shadow(color: .black.opacity(0.06), radius: 10, y: -4)`)
            .drawBehind {
                val h = 14.dp.toPx()
                drawRect(
                    Brush.verticalGradient(listOf(Color.Transparent, shadow), startY = -h, endY = 0f),
                    topLeft = Offset(0f, -h), size = Size(size.width, h),
                )
            }
            .background(Color.White)
            .windowInsetsPadding(WindowInsets.navigationBars),
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .animateContentSize(Motion.settle.spec())
                .padding(horizontal = 16.dp)
                .padding(top = 12.dp, bottom = 8.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            when (flow.phase) {
                CampaignPhase.register -> {
                    val deadline = campaign.deadline
                    if (deadline != null) {
                        ClockLine("เหลือเวลาลงทะเบียน", deadline)
                        StarLine()
                    } else {
                        DescLine(Ph.calendarBlank, "หมดเวลาลงทะเบียนแล้ว", tint = SH.hint)
                    }
                    SHRedButton(
                        title = if (campaign.isOpen) "ลงทะเบียนร่วมกิจกรรม" else "หมดเวลาลงทะเบียน",
                        icon = Ph.notePencil, enabled = campaign.isOpen, action = onMain,
                    )
                }
                CampaignPhase.registered -> {
                    DescLine(Ph.calendarBlank, "รอประกาศชื่อผู้ได้รับคัดเลือก")
                    RegisteredLine(onFill)
                    SHGreenButton(title = "คุณได้ลงทะเบียนแล้ว", icon = Ph.checkCircle)
                }
                CampaignPhase.waitingAcceptQuota -> {
                    val deadline = remember { System.currentTimeMillis() + (1 * 86400 + 23 * 3600 + 59 * 60) * 1000L }
                    ClockLine("เหลือเวลาตอบรับ", deadline)
                    SHRedButton(title = "ตอบรับกิจกรรม", icon = Ph.gift, action = onMain)
                }
                CampaignPhase.acceptedQuota -> {
                    DescLine(
                        Ph.`package`,
                        if (flow.reviewed) "เสร็จสิ้นการส่งรีวิวกิจกรรม" else flow.order.label,
                        tint = if (flow.reviewed) SHColor.green else SH.ink,
                    )
                    SHRedButton(
                        title = if (flow.reviewed) "ดูโพสต์รีวิว" else "รายละเอียดการรีวิว",
                        icon = Ph.clipboardText, action = onMain,
                    )
                }
            }
        }
        // เส้นบนของแถบ — วาดทับขอบบน (= `.overlay(alignment: .top) { SH.line.frame(height: 1) }`)
        Box(Modifier.align(Alignment.TopCenter).fillMaxWidth().height(1.dp).background(SH.line))
    }
}

/** นาฬิกานับถอยหลังทีละวินาที (= `TimelineView(.periodic(from: .now, by: 1))`) */
@Composable
private fun ClockLine(label: String, deadline: Long) {
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(Unit) {
        while (true) {
            delay(1000)
            now = System.currentTimeMillis()
        }
    }
    val left = max(0L, (deadline - now) / 1000L).toInt()
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
        PIcon(Ph.calendarBlank, size = 18f, weight = PhWeight.regular, tint = SH.red)
        Text(label, style = sh(14f, SHFont.semibold), color = SH.ink)
        Spacer(Modifier.weight(1f))
        Clock(left)
    }
}

@Composable
private fun DescLine(icon: Ph, text: String, tint: Color = SH.muted) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
        PIcon(icon, size = 18f, weight = PhWeight.regular, tint = tint)
        Text(text, style = sh(14f, SHFont.semibold), color = tint)
        Spacer(Modifier.weight(1f))
    }
}

/** ป้ายสถานะ STAR + คำบอกเงื่อนไขตรง ๆ ก่อนกดปุ่ม (= บรรทัด `.lvl-chip` ของ flow ใหม่) */
@Composable
private fun StarLine() {
    val flow = LocalStarFlow.current
    val missing = flow.registerSteps.size
    val chip = if (flow.isStar) "★ STAR แล้ว" else if (flow.hasCard) "☆ ยังไม่ยืนยันตัวตน" else "☆ ยังไม่เป็น STAR"
    val hint = if (!flow.hasCard) "งานนี้รับเฉพาะ STAR · กดลงทะเบียนแล้วสมัครเป็น STAR ก่อน (ครั้งเดียว ใช้ได้ทุกงาน)"
    else if (missing > 0) "แบรนด์คัดเลือกจากการ์ด · ขอเติมอีก $missing อย่างก่อนส่งใบสมัคร"
    else if (flow.isStar) "การ์ดคุณครบแล้ว · ส่งใบสมัครได้เลย"
    else "การ์ดพร้อม · ยืนยันตัวตนด้วย แบรนด์จะคัดเลือกง่ายขึ้น"
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.Top) {
        StarLevelChip(text = chip)
        Text(hint, style = shSpaced(12f, SHFont.regular, 2f), color = SH.ink, modifier = Modifier.weight(1f))
        Spacer(Modifier.width(0.dp))
    }
}

@Composable
private fun RegisteredLine(onFill: () -> Unit) {
    val flow = LocalStarFlow.current
    val asked = setOf(StarDataKey.rate, StarDataKey.about, StarDataKey.insight, StarDataKey.province, StarDataKey.availability)
    val left = StarRow.all.filter { r ->
        val k = r.key ?: return@filter !flow.isVerified
        k in asked && !flow.has(k)
    }
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
        StarLevelChip(text = if (flow.isStar) "★ STAR" else "⏳ รอยืนยันตัวตน")
        val first = left.firstOrNull()
        if (first != null) {
            Text(
                "แบรนด์เปิดดูการ์ดคุณได้แล้ว · ยังขาด${first.title}ที่แบรนด์มักถาม",
                style = shSpaced(12f, SHFont.regular, 2f), color = SH.ink, modifier = Modifier.weight(1f),
            )
            Spacer(Modifier.width(4.dp))
            Box(
                Modifier
                    .height(26.dp)
                    .background(SH.ink, CircleShape)
                    .tap {
                        Haptics.impact(Haptics.Style.light)
                        onFill()
                    }
                    .padding(horizontal = 10.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text("เติมเลย", style = sh(12f, SHFont.bold), color = Color.White)
            }
        } else {
            Text(
                "แบรนด์เปิดดูการ์ดคุณได้แล้ว · มีครบทุกอย่างที่แบรนด์ขอดู",
                style = sh(12f), color = SH.ink, modifier = Modifier.weight(1f),
            )
            Spacer(Modifier.width(0.dp))
        }
    }
}

@Composable
private fun Clock(seconds: Int) {
    val days = seconds / 86400
    val h = (seconds % 86400) / 3600
    val m = (seconds % 3600) / 60
    val s = seconds % 60
    Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
        if (days > 0) {
            ClockBox(days.toString(), wide = true)
            ClockColon()
        }
        ClockBox(String.format(Locale.US, "%02d", h))
        ClockColon()
        ClockBox(String.format(Locale.US, "%02d", m))
        ClockColon()
        ClockBox(String.format(Locale.US, "%02d", s))
    }
}

@Composable
private fun ClockColon() {
    Text(":", style = sh(14f, SHFont.bold), color = SH.ink)
}

@Composable
private fun ClockBox(t: String, wide: Boolean = false) {
    Box(
        Modifier
            .background(SH.clockBox, RoundedCornerShape(5.dp))
            .padding(horizontal = 2.dp)
            .defaultMinSize(minWidth = (if (wide) 30 else 26).dp, minHeight = 24.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            t, style = sh(13f, SHFont.bold).copy(fontFeatureSettings = "tnum"), color = Color.White,
            textAlign = TextAlign.Center,
        )
    }
}

/** ป้ายเล็ก "★ STAR" / "☆ ยังไม่เป็น STAR" ใต้นาฬิกา */
@Composable
fun StarLevelChip(text: String, modifier: Modifier = Modifier) {
    Box(
        modifier
            .height(22.dp)
            .background(PK.fieldFill, CircleShape)
            .padding(horizontal = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(text, style = sh(11f, SHFont.bold), color = SH.ink, maxLines = 1, softWrap = false)
    }
}

/** ปุ่มเขียวเต็มกว้าง กดไม่ได้ — "คุณได้ลงทะเบียนแล้ว" ของแอปหลัก */
@Composable
fun SHGreenButton(title: String, icon: Ph? = null, modifier: Modifier = Modifier) {
    Row(
        modifier
            .fillMaxWidth()
            .height(48.dp)
            .background(SHColor.green, RoundedCornerShape(10.dp)),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) PIcon(icon, size = 20f, weight = PhWeight.regular, tint = Color.White)
        Text(title, style = sh(16f, SHFont.semibold), color = Color.White)
    }
}
