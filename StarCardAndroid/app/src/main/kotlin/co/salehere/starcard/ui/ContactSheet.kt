package co.salehere.starcard.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.SymbolIcon
import co.salehere.starcard.theme.mixed
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.widgets.contactURL

/**
 * ชีต "ติดต่อ" ของหน้าดู — **flow** ตาม `ContactBoxView` ของ salehere-ios
 * (กดปุ่มติดต่อ → ชีตช่องทางเรียงแถวเดียว → แตะแล้วออกไปแอปนั้นทันที)
 * แต่หน้าตาเป็นของเวทีนี้: พื้นมืดชุดเดียวกับหน้าดู ตัวอักษรขาว ไทล์ทรงเดียวกันทุกช่อง
 *
 * ไทล์ทุกช่องเป็นสี่เหลี่ยมมนสีแบรนด์ของช่องทาง + ไอคอนขาว — ทรงเดียวกับไอคอน LINE ของจริง
 * โชว์เฉพาะช่องทางที่เจ้าของการ์ดกรอกไว้จริง
 * - onPick: ปลายทางที่เลือก — ผู้เรียกเป็นคนเปิด (แอปเจ้าของลิงก์ก่อน แล้วค่อยเบราว์เซอร์)
 */
@Composable
fun ContactSheet(
    onPick: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val channels = contactChannels()

    Column(modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            "ติดต่อ",
            style = sh(16f, SHFont.semibold),
            color = Color.White,
            modifier = Modifier.padding(top = 24.dp),
        )

        if (channels.isEmpty()) {
            Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                Text("ยังไม่มีช่องทางติดต่อ", style = sh(13f, SHFont.medium), color = Color.White.opacity(0.5))
            }
        } else {
            Box(Modifier.weight(1f).fillMaxWidth().padding(horizontal = 20.dp), contentAlignment = Alignment.Center) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
                    for (c in channels) {
                        Column(
                            Modifier
                                .weight(1f)
                                .semantics { contentDescription = "${c.label} ${c.value}" }
                                .dockPress {
                                    Haptics.impact(Haptics.Style.light)
                                    onPick(c.url)
                                },
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            Box(Modifier.size(TILE.dp).border(0.8.dp, Color.White.opacity(0.14), TileShape)) {
                                ContactTile(c.id)
                            }
                            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                Text(c.label, style = sh(13f, SHFont.semibold), color = Color.White)
                                // ค่าจริงใต้ป้าย — คนดูรู้ก่อนกดว่าจะโทรเบอร์ไหน ทักไอดีไหน
                                Text(
                                    c.value,
                                    style = sh(10.5f, SHFont.medium),
                                    color = Color.White.opacity(0.5),
                                    maxLines = 1,
                                    overflow = TextOverflow.MiddleEllipsis,
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

private const val TILE = 56f
private val TileShape = RoundedCornerShape(16.dp)
private val phoneTint = rgb(1.0, 0.55, 0.2)
private val mailTint = rgb(0.36, 0.56, 0.98)

private data class ContactChannel(val id: String, val label: String, val value: String, val url: String)

private fun contactChannels(): List<ContactChannel> {
    val me = Profile.me
    val list = mutableListOf<ContactChannel>()
    ProfileField.phone.contactURL?.let { list += ContactChannel("tel", "โทร", me.phone, it) }
    ProfileField.lineId.contactURL?.let { list += ContactChannel("line", "LINE", me.lineId, it) }
    ProfileField.email.contactURL?.let { list += ContactChannel("mail", "อีเมล", me.email, it) }
    return list
}

@Composable
private fun ContactTile(id: String) {
    when (id) {
        "line" -> Image(
            painter = painterResource(SHIcon.shareLine),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.size(TILE.dp).clip(TileShape),
        )
        "tel" -> Glyph(phoneTint) { SymbolIcon(SHIcon.phoneCall, size = 28f, tint = Color.White) }
        else -> Glyph(mailTint) { SFSymbol("envelope.fill", size = 28f, tint = Color.White) }
    }
}

/** ไอคอนขาวบนสี่เหลี่ยมมนสีแบรนด์ (= `tint.gradient`) */
@Composable
private fun Glyph(tint: Color, icon: @Composable () -> Unit) {
    Box(
        Modifier
            .size(TILE.dp)
            .background(Brush.verticalGradient(listOf(tint.mixed(Color.White, 0.12), tint)), TileShape),
        contentAlignment = Alignment.Center,
    ) { icon() }
}
