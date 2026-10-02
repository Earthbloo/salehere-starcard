package co.salehere.starcard.ui.profile.sections

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.model.Profile
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.theme.systemFont
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.profile.PField
import co.salehere.starcard.ui.profile.PK
import co.salehere.starcard.ui.profile.PKPanel
import co.salehere.starcard.ui.profile.ProfileSection
import co.salehere.starcard.ui.profile.SectionScroll
import co.salehere.starcard.ui.profile.pkAnchor
import co.salehere.starcard.ui.profile.rememberPKFocus
import co.salehere.starcard.ui.profile.sectionIssue
import co.salehere.starcard.ui.tap

/** ยืนยัน — ข้อ `consent` ของฟอร์มเว็บ: กล่อง PDPA (`LEGAL`) + ติ๊กยินยอม */
@Composable
fun ConsentSection(
    showIssues: Boolean,
    focusRequest: String?,
    onFocusRequestChange: (String?) -> Unit,
    modifier: Modifier = Modifier,
) {
    val focus = rememberPKFocus()
    val consented = Profile.me.intake?.consentAt != null
    val fill by animateColorAsState(if (consented) PK.okTint else PK.fieldFill, Motion.snap.spec(), label = "consentFill")
    val edge by animateColorAsState(if (consented) PK.ok.opacity(0.5) else PK.line, Motion.snap.spec(), label = "consentEdge")

    SectionScroll(focus = focus, request = focusRequest, onRequestChange = onFocusRequestChange, modifier = modifier) {
        PKPanel(modifier = Modifier.pkAnchor(PField.consent)) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.Top) {
                Text("🔒", style = systemFont(22f))
                Text("ยืนยันความยินยอม (PDPA)", style = sh(15f, SHFont.bold), color = PK.ink)
            }
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(190.dp)
                    .clip(PK.shape(12f))
                    .background(PK.fieldFill),
            ) {
                Column(
                    Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    // ข้อความเดียวกับ `LEGAL` ของฟอร์มเว็บ
                    Legal(
                        "1. ผู้ควบคุมข้อมูลส่วนบุคคล",
                        "บริษัท เซล เฮียร์ (ไทยแลนด์) จำกัด เลขที่ 1240/16 ซอยสุขุมวิท 101/1 แขวงบางจาก เขตพระโขนง กรุงเทพมหานคร 10260 เลขประจำตัวผู้เสียภาษี 0105559095248 · โทร. 02-102-6496",
                    )
                    Legal(
                        "2. ข้อมูลที่เก็บรวบรวม",
                        "ข้อมูลติดต่อ ช่องทางโซเชียลและยอดผู้ติดตาม เรทค่าตอบแทน หมวดคอนเทนต์ อาชีพ วัน–เวลา–จังหวัดที่สะดวก และข้อมูลอ่อนไหว (ศาสนา / สัดส่วนร่างกาย)",
                    )
                    Legal(
                        "3. วัตถุประสงค์",
                        "เพื่อพิจารณาคัดเลือก จับคู่งานรีวิว/แคมเปญ ติดต่อประสานงาน จัดทำสัญญา และชำระค่าตอบแทน",
                    )
                    Legal(
                        "4. สิทธิของเจ้าของข้อมูล",
                        "เข้าถึง ขอสำเนา แก้ไข ลบ คัดค้าน และถอนความยินยอมได้ทุกเมื่อ รวมถึงร้องเรียนต่อสำนักงานคณะกรรมการคุ้มครองข้อมูลส่วนบุคคล",
                    )
                }
            }

            Row(
                Modifier
                    .fillMaxWidth()
                    .tap {
                        Haptics.light()
                        Profile.me.updateIntake { it.copy(consentAt = if (consented) null else System.currentTimeMillis()) }
                    }
                    .background(fill, PK.shape(PK.fieldRadius))
                    .border(1.dp, edge, PK.shape(PK.fieldRadius))
                    .padding(13.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.Top,
            ) {
                Box(
                    Modifier
                        .size(24.dp)
                        .background(if (consented) PK.ok else PK.ok.opacity(0.0), PK.shape(7f))
                        .border(1.5.dp, if (consented) PK.ok else PK.line2, PK.shape(7f)),
                    contentAlignment = Alignment.Center,
                ) {
                    if (consented) PIcon(Ph.check, size = 12f, tint = Color.White)
                }
                Text(
                    "อ่านแล้วและยินยอมให้เก็บ ใช้ และเปิดเผยข้อมูล (รวมถึงข้อมูลอ่อนไหว) ตามรายละเอียดข้างบน",
                    style = sh(13.5f, SHFont.semibold),
                    color = if (consented) PK.ok else PK.ink,
                    modifier = Modifier.weight(1f),
                )
            }

            val e = sectionIssue(ProfileSection.consent, PField.consent, showIssues)
            if (e != null) Text(e, style = sh(11.5f, SHFont.medium), color = PK.err)
        }
    }
}

@Composable
private fun Legal(h: String, body: String) {
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(h, style = sh(11.5f, SHFont.bold), color = PK.ink)
        Text(body, style = sh(11f, SHFont.medium), color = PK.ink2)
    }
}
