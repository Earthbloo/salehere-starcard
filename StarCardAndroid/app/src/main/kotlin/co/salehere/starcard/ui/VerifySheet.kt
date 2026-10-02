package co.salehere.starcard.ui

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
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.Signature
import co.salehere.starcard.theme.StarLockup
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.export.VerifiedPillImage
import co.salehere.starcard.ui.widgets.Guilloche
import co.salehere.starcard.ui.widgets.MiniSeal
import co.salehere.starcard.ui.widgets.VerifiedSeal
import kotlin.math.max

/** ความสูงของแผ่นตรวจสอบ (= `VerifySheet.height`) */
object VerifySheet {
    /** พอดีเนื้อหา ไม่ใช่ครึ่งจอ (แถวเสริมมาเมื่อไหร่ชีตสูงขึ้นหนึ่งแถว) */
    val height: Float get() = 372f + max(0, VerifiedFacts.current.rows.size - 3) * 62f
}

/**
 * แผ่นตรวจสอบ — **แผ่นเดียว ใช้ทุกที่**: แตะแถบ Verified บนหน้าดู หรือแตะ widget ตรารับรองบนการ์ด
 *
 * ตราที่แตะแล้วไม่มีคำตอบคือตราที่ปลอมได้ใน Canva — แผ่นนี้ตอบสามคำถามเสมอ:
 * ตรวจอะไร · เมื่อไหร่ · ตรวจซ้ำได้ที่ไหน (ข้อมูลชุดเดียวกับ `VerifiedSealWidget` — ดู `VerifiedFacts`)
 * หน้าตาเป็นภาษาเดียวกับ `ContactSheet`: ชีตมืดของเวที ไม่ใช่การ์ดขาวของแอปหลัก
 */
@Composable
fun VerifySheet(
    slug: String,
    modifier: Modifier = Modifier,
) {
    val facts = VerifiedFacts.current

    Box(modifier.fillMaxSize().clipToBounds()) {
        // ลายกิโยเช่จางที่มุมขวาบน
        Box(
            Modifier
                .align(Alignment.TopEnd)
                .wrapContentSize(Alignment.TopEnd, unbounded = true)
                .offset(x = 110.dp, y = (-120).dp)
                .requiredSize(300.dp),
        ) {
            Guilloche(color = Color.White.opacity(0.055))
        }

        Column(Modifier.fillMaxSize().padding(horizontal = 22.dp)) {
            // หัว — เหรียญรับรองตัวเดียวกับบน widget
            Row(
                Modifier.fillMaxWidth().padding(top = 30.dp, bottom = 20.dp),
                horizontalArrangement = Arrangement.spacedBy(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                VerifiedSeal(radius = 27f, punch = grey(0.09))
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text(
                        if (facts.verified) "Verified by Sale Here" else "กำลังรอการยืนยัน",
                        style = sh(19f, SHFont.bold),
                        color = Color.White,
                    )
                    Text(
                        "สิ่งที่ Sale Here ตรวจแล้วของ @$slug",
                        style = sh(12f, SHFont.medium),
                        color = Color.White.opacity(0.55),
                        maxLines = 1,
                        softWrap = false,
                        autoSize = TextAutoSize.StepBased(minFontSize = (12f * 0.8f).sp, maxFontSize = 12.sp, stepSize = 0.25.sp),
                    )
                }
            }

            val box = RoundedCornerShape(18.dp)
            Column(
                Modifier
                    .fillMaxWidth()
                    .background(Color.White.opacity(0.055), box)
                    .border(0.7.dp, Color.White.opacity(0.09), box)
                    .padding(horizontal = 14.dp),
            ) {
                val last = facts.rows.lastOrNull()?.id
                for (r in facts.rows) {
                    Row(
                        Modifier.fillMaxWidth().padding(vertical = 11.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        if (r.ok) {
                            MiniSeal(size = 20f)
                        } else {
                            PIcon(Ph.clock, size = 18f, weight = PhWeight.regular, tint = Color.White.opacity(0.4))
                        }
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                            Text(r.title, style = sh(14.5f, SHFont.semibold), color = Color.White)
                            Text(
                                r.detail,
                                style = sh(11.5f, SHFont.medium),
                                color = Color.White.opacity(0.5),
                                maxLines = 1,
                                softWrap = false,
                            )
                        }
                        Text(
                            r.value,
                            style = Signature.mono(11f, SHFont.semibold),
                            color = Color.White.opacity(if (r.ok) 0.62 else 0.4),
                            modifier = Modifier.padding(start = 8.dp),
                        )
                    }
                    if (r.id != last) {
                        Box(Modifier.fillMaxWidth().height(0.7.dp).background(Color.White.opacity(0.08)))
                    }
                }
            }

            // ท้ายแผ่น — เลขการ์ด · ที่อยู่ที่ตรวจซ้ำได้ · ตราผู้ออก
            Row(
                Modifier.fillMaxWidth().padding(top = 18.dp),
                verticalAlignment = Alignment.Bottom,
            ) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text(
                        "STAR CARD NO. ${facts.serial}",
                        style = Signature.mono(9.5f, SHFont.semibold).copy(letterSpacing = 0.5.sp),
                        color = Color.White.opacity(0.55),
                    )
                    Text(
                        "ตรานี้มีผลเฉพาะบน ${Signature.url(slug)}",
                        style = sh(11f, SHFont.medium),
                        color = Color.White.opacity(0.4),
                        maxLines = 1,
                        softWrap = false,
                        autoSize = TextAutoSize.StepBased(minFontSize = (11f * 0.7f).sp, maxFontSize = 11.sp, stepSize = 0.25.sp),
                    )
                }
                Spacer(Modifier.width(8.dp))
                StarLockup(height = 24f, tint = Color.White.opacity(0.9))
            }

            Spacer(Modifier.weight(1f))
        }
    }
}

// MARK: - แถบ Verified ของหน้าดู

/** ความสูงของแถบ (= `VerifiedBand.height`) */
object VerifiedBand {
    const val height: Float = 38f
}

/**
 * แถบใต้แถบบนของหน้าดู — อยู่ **นอกตัวการ์ด** เจ้าของลบหรือแต่งไม่ได้ (คู่ของแม่กุญแจบนแถบที่อยู่เบราว์เซอร์)
 * ดังได้เต็มที่เพราะเป็นพื้นที่ของเวที ไม่ใช่ของงานที่เจ้าของออกแบบ · แตะแล้วเปิด `VerifySheet`
 */
@Composable
fun VerifiedBand(
    action: () -> Unit,
    modifier: Modifier = Modifier,
) {
    StageGlassPanel(
        radius = VerifiedBand.height / 2f,
        modifier = modifier
            .height(VerifiedBand.height.dp)
            .semantics { contentDescription = "Verified by Sale Here ดูสิ่งที่ตรวจแล้ว" }
            .dockPress {
                Haptics.impact(Haptics.Style.light)
                action()
            },
    ) {
        Row(
            Modifier.height(VerifiedBand.height.dp).padding(start = 6.dp, end = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(9.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // ป้ายตัวจริงของแอปหลัก — **ของชิ้นเดียว** ที่บอกทั้ง "ยืนยันแล้ว" และ "โดยใคร"
            VerifiedPillImage(height = 28f, label = null)
            Spacer(Modifier.weight(1f).width(6.dp))
            Text(
                "ตรวจ ${Signature.verifiedOn}",
                style = Signature.mono(10f, SHFont.medium),
                color = Color.White.opacity(0.55),
                maxLines = 1,
            )
            SFSymbol("chevron.right", size = 10f, tint = Color.White.opacity(0.45))
        }
    }
}

// MARK: - ป้ายรับรองของคลังการ์ด

/** ป้ายรับรองของคลัง — ป้าย VERIFIED BY SALE HERE ตัวจริงของแอปหลัก สูงเท่าป้าย "กำลังแสดงอยู่" */
@Composable
fun VerifiedTab(modifier: Modifier = Modifier) {
    // ป้ายตัวจริงของแอปหลัก ลอยเหนือการ์ด — ไม่ต้องมีแคปซูลรอง ตัวมันเป็นป้ายอยู่แล้ว
    VerifiedPillImage(
        height = 30f,
        label = "Verified by Sale Here",
        modifier = modifier.shadow(
            elevation = 8.dp,
            shape = RoundedCornerShape(15.dp),
            clip = false,
            ambientColor = Color.Black.opacity(0.45),
            spotColor = Color.Black.opacity(0.45),
        ),
    )
}
