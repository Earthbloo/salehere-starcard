package co.salehere.starcard.ui.salehere.starflow

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import co.salehere.starcard.model.StarCampaign
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.profile.PK
import co.salehere.starcard.ui.salehere.SH
import co.salehere.starcard.ui.salehere.SHBarIcon
import co.salehere.starcard.ui.salehere.SHNavBar
import co.salehere.starcard.ui.salehere.SHRedButton
import co.salehere.starcard.ui.tap

/** หน้าตอบรับเดิมของแอปหลัก (`UnboxAcceptingDetailPage`) — ที่อยู่เติมให้จาก Star Profile แล้ว */
@Composable
fun AcceptPage(
    campaign: StarCampaign,
    onBack: () -> Unit,
    onAccept: () -> Unit,
    onDecline: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var answer by remember { mutableStateOf<String?>(null) }

    Column(modifier.fillMaxSize().background(Color.White)) {
        SHNavBar(
            title = "รายละเอียดตอบรับกิจกรรม",
            left = { SHBarIcon(icon = Ph.caretLeft, size = 26f, action = onBack) },
            right = { Gap(32f, 32f) },
        )
        Column(
            Modifier
                .weight(1f)
                .fillMaxWidth()
                .background(Color.White)
                .verticalScroll(rememberScrollState()),
        ) {
            Row(
                Modifier.fillMaxWidth().padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Image(
                    painterResource(campaign.cover), contentDescription = null, contentScale = ContentScale.Crop,
                    modifier = Modifier.size(72.dp).clip(RoundedCornerShape(8.dp)),
                )
                Text(
                    campaign.headline, style = sh(14f, SHFont.bold), color = SH.ink,
                    maxLines = 3, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f),
                )
            }
            val card = RoundedCornerShape(12.dp)
            Column(
                Modifier
                    .padding(horizontal = 16.dp)
                    .fillMaxWidth()
                    .background(Color.White, card)
                    .border(1.dp, SH.line, card)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                AcceptSection("โซเชียลที่คุณต้องรีวิว") {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        campaign.socialChannels.forEach { s ->
                            Image(
                                painterResource(s.icon), contentDescription = null, contentScale = ContentScale.Fit,
                                modifier = Modifier.size(32.dp).clip(CircleShape),
                            )
                        }
                    }
                }
                AcceptSection("ประเภทคอนเทนต์ที่ต้องรีวิว") {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        campaign.contentTypes.forEach { Text("- $it", style = sh(14f), color = SH.ink) }
                    }
                }
                AcceptSection("Timeline แคมเปญ") {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        campaign.timeline.drop(3).forEach { (label, date) ->
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                                Box(Modifier.size(6.dp).background(SH.red, CircleShape))
                                Text(label, style = sh(13f), color = SH.muted, modifier = Modifier.weight(1f))
                                Text(date, style = sh(13f, SHFont.semibold), color = SH.ink)
                            }
                        }
                    }
                }
                AcceptSection("ที่อยู่ในการจัดส่ง") {
                    Row(verticalAlignment = Alignment.Top) {
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text("มณีรัตน์ ใจดี", style = sh(14f, SHFont.bold), color = SH.ink)
                            Text("0891234567", style = sh(13f), color = SH.muted)
                            Text(
                                "99/12 คอนโดลุมพินี ซ.สุขุมวิท 77 สวนหลวง สวนหลวง กรุงเทพมหานคร 10250",
                                style = sh(13f).lineSpaced(2f), color = SH.muted,
                            )
                        }
                        Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                            PIcon(Ph.pencilSimple, size = 14f, weight = PhWeight.regular, tint = SH.red)
                            Text("แก้ไขที่อยู่", style = sh(12f, SHFont.semibold), color = SH.red)
                        }
                    }
                }
                AcceptSection("ข้อมูลที่ควรรู้ก่อนตอบรับ") {
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        listOf(
                            "ต้องส่งดราฟต์รีวิวภายในเวลาที่กำหนด และโพสต์จริงหลังดราฟต์ผ่านเท่านั้น",
                            "หากไม่ส่งรีวิวตามกำหนด จะถูกตัดสิทธิ์และไม่สามารถลงทะเบียนกิจกรรมอื่นได้",
                            "ของรางวัลจะจัดส่งตามที่อยู่ข้างต้น กรุณาตรวจสอบให้ถูกต้อง",
                        ).forEach { t ->
                            Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Text("•", style = sh(13f), color = SH.muted)
                                Text(t, style = sh(13f).lineSpaced(2f), color = SH.muted)
                            }
                        }
                    }
                }
            }
            campaign.acceptQuestions.forEach { q ->
                Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    RequiredLabel(q.q)
                    SHMenuField(value = answer, options = q.options, onPick = { answer = it })
                }
            }
            Row(
                Modifier.fillMaxWidth().padding(vertical = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                PIcon(Ph.calendarBlank, size = 14f, weight = PhWeight.regular, tint = SH.muted)
                Text("เหลือเวลาตอบรับ", style = sh(13f, SHFont.semibold), color = SH.ink)
                Text("1 : 23 : 59 : 12", style = sh(13f, SHFont.bold).tnum(), color = SH.ink)
            }
            Spacer(Modifier.height(40.dp))
        }
        Row(
            Modifier
                .fillMaxWidth()
                .background(Color.White)
                .topHairline(SH.line)
                .navigationBarsPadding()
                .padding(horizontal = 16.dp)
                .padding(top = 10.dp, bottom = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Row(
                Modifier
                    .weight(1f)
                    .height(48.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(PK.fieldFill)
                    .tap {
                        Haptics.impact(Haptics.Style.light)
                        onDecline()
                    },
                horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                PIcon(Ph.xCircle, size = 18f, weight = PhWeight.regular, tint = SH.muted)
                Text("สละสิทธิ์", style = sh(15f, SHFont.semibold), color = SH.muted)
            }
            SHRedButton(title = "ตอบรับกิจกรรม", icon = Ph.gift, action = onAccept, modifier = Modifier.weight(1f))
        }
    }
}

@Composable
private fun AcceptSection(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(title, style = sh(14f, SHFont.bold), color = SH.ink)
        content()
    }
}
