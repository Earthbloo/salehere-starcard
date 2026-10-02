package co.salehere.starcard.ui.salehere

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import co.salehere.starcard.model.StarCampaign
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHColor
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.tap

/**
 * แท็บหน้าแรกของแอปจำลอง — มีแต่ Sale Here STAR (กิจกรรมที่แบรนด์เปิดรับ) ตามที่ตกลง 22 ก.ย. 2569
 *
 * แถวบนเลื่อนแนวนอนเหมือน section "Sale Here STAR" บนหน้าแรกแอปหลัก · ข้างล่างเป็นรายการเต็มให้หน้าไม่โล่ง
 */
@Composable
fun StarHomePage(campaigns: List<StarCampaign>, onOpen: (StarCampaign) -> Unit, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxSize()) {
        SHNavBar(
            title = "Sale Here STAR",
            left = { SHBarLogo() },
            right = {
                SHBarIcon(icon = Ph.headset)
                SHBarIcon(icon = Ph.bell)
            },
        )
        Column(
            Modifier
                .weight(1f)
                .fillMaxWidth()
                .background(SH.page)
                .verticalScroll(rememberScrollState())
                .padding(top = 14.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            StarHomeSectionHeader()
            Row(
                Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                campaigns.forEach { c -> StarCampaignCard(campaign = c, onOpen = { onOpen(c) }) }
            }
            Text(
                "กิจกรรมทั้งหมด", style = sh(17f, SHFont.bold), color = SH.ink,
                modifier = Modifier.padding(horizontal = 16.dp).padding(top = 6.dp),
            )
            Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                campaigns.forEach { c -> StarCampaignRow(campaign = c, onOpen = { onOpen(c) }) }
            }
        }
    }
}

@Composable
private fun StarHomeSectionHeader() {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
        Row(
            Modifier.alignByBaseline(),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PIcon(Ph.sparkle, size = 16f, weight = PhWeight.fill, tint = SHColor.star)
            Text("Sale Here STAR", style = sh(20f, SHFont.black), color = SH.red)
            PIcon(Ph.sparkle, size = 12f, weight = PhWeight.fill, tint = SHColor.star)
        }
        Spacer(Modifier.weight(1f))
        Row(
            Modifier.alignByBaseline().tap {},
            horizontalArrangement = Arrangement.spacedBy(2.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("ดูทั้งหมด", style = sh(14f, SHFont.medium), color = SH.muted)
            PIcon(Ph.caretRight, size = 12f, tint = SH.muted)
        }
    }
}

/** การ์ดในแถวเลื่อน — ปก · โลโก้+ชื่อ · วันที่ · ปุ่มแดง (สัดส่วนจาก screenshot: การ์ด ~172pt) */
@Composable
fun StarCampaignCard(campaign: StarCampaign, onOpen: () -> Unit, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(12.dp)
    Column(
        modifier
            .width(172.dp)
            .background(Color.White, shape)
            .border(1.dp, SH.line, shape)
            .tap(onClick = onOpen),
    ) {
        Image(
            painterResource(campaign.cover), contentDescription = null, contentScale = ContentScale.Crop,
            modifier = Modifier.size(172.dp, 116.dp).clipToBounds(),
        )
        Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(Modifier.fillMaxWidth().height(50.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                StarBrandLogo(name = campaign.logo, size = 32f)
                Text(
                    campaign.headline, style = sh(14f, SHFont.bold), color = SH.ink,
                    maxLines = 2, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )
            }
            Row(horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
                PIcon(Ph.calendarBlank, size = 13f, weight = PhWeight.regular, tint = SH.muted)
                Text(campaign.dateRange, style = sh(12f, SHFont.medium), color = SH.muted)
            }
            // ปุ่มในการ์ดเป็นแค่หน้าตา — แตะตรงไหนก็เปิดกิจกรรม (= `.allowsHitTesting(false)`)
            SHRedButtonFace(
                title = if (campaign.isOpen) "ลงทะเบียนร่วมกิจกรรม" else "หมดเวลา",
                icon = null, enabled = campaign.isOpen, height = 40f,
            )
        }
    }
}

/** แถวในรายการเต็ม — ปกซ้าย ข้อความขวา */
@Composable
fun StarCampaignRow(campaign: StarCampaign, onOpen: () -> Unit, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(12.dp)
    Row(
        modifier
            .fillMaxWidth()
            .background(Color.White, shape)
            .border(1.dp, SH.line, shape)
            .tap(onClick = onOpen)
            .padding(10.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Image(
            painterResource(campaign.cover), contentDescription = null, contentScale = ContentScale.Crop,
            modifier = Modifier.size(112.dp, 84.dp).clip(RoundedCornerShape(8.dp)),
        )
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(
                campaign.headline, style = sh(14f, SHFont.bold), color = SH.ink,
                maxLines = 2, overflow = TextOverflow.Ellipsis,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
                PIcon(Ph.calendarBlank, size = 13f, weight = PhWeight.regular, tint = SH.muted)
                Text(campaign.dateRange, style = sh(12f, SHFont.medium), color = SH.muted)
            }
            Text(
                if (campaign.isOpen) "เปิดรับสมัคร" else "หมดเวลา",
                style = sh(11f, SHFont.bold),
                color = if (campaign.isOpen) SH.red else SH.hint,
                modifier = Modifier
                    .background(if (campaign.isOpen) SHColor.redSoft else SHColor.soft, CircleShape)
                    .padding(horizontal = 8.dp, vertical = 3.dp),
            )
        }
    }
}

/** โลโก้แบรนด์วงกลมมีขอบบาง — `name` คือ drawable ของโลโก้ (iOS เป็นชื่อ asset) */
@Composable
fun StarBrandLogo(name: Int, size: Float, modifier: Modifier = Modifier) {
    Image(
        painterResource(name), contentDescription = null, contentScale = ContentScale.Crop,
        modifier = modifier
            .size(size.dp)
            .clip(CircleShape)
            .border(1.dp, SH.line, CircleShape),
    )
}
