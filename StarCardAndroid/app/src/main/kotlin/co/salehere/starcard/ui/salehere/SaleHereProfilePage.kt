package co.salehere.starcard.ui.salehere

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
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
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHColor
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.tap

/**
 * แท็บโปรไฟล์ของแอปจำลอง — หน้าโปรไฟล์ผู้ใช้ Sale Here ตาม screenshot 22 ก.ย. 2569
 *
 * ปุ่ม "โปรไฟล์ครีเอเตอร์" คือประตูเดียวเข้าสู่ Star Card (hub "ข้อมูลของฉัน") — flow เดิมของแอปหลัก
 */
@Composable
fun SaleHereProfilePage(
    onCreatorProfile: () -> Unit,
    campaignCount: Int,
    /** กดค้างชื่อบนแถบแดง → แผง lab ของ flow ใหม่ */
    onLab: () -> Unit = {},
    modifier: Modifier = Modifier,
) {
    var feed by remember { mutableStateOf(ProfileFeed.grid) }

    Column(modifier.fillMaxSize()) {
        SHNavBar(
            title = SHMockUser.name,
            modifier = Modifier.shLongPress(0.6) { Haptics.impact(Haptics.Style.medium); onLab() },
            left = { SHBarLogo() },
            right = {
                SHBarIcon(icon = Ph.chatCircleText)
                SHBarIcon(icon = Ph.list)
            },
        )
        Column(
            Modifier
                .weight(1f)
                .fillMaxWidth()
                .background(SH.page)
                .verticalScroll(rememberScrollState())
                .padding(bottom = 24.dp),
        ) {
            ProfileHeader()
            Column(
                Modifier.fillMaxWidth().padding(horizontal = 12.dp).padding(top = 10.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                ProfileStats()
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    SHOutlineButton(title = "แก้ไขโปรไฟล์", icon = Ph.pencilSimple, action = {}, modifier = Modifier.weight(1f))
                    SHOutlineButton(
                        title = "โปรไฟล์ครีเอเตอร์", icon = Ph.identificationCard, action = onCreatorProfile,
                        modifier = Modifier.weight(1f),
                    )
                }
                ProfileTiles(campaignCount)
                ProfileComposer()
                ProfileDraftBanner()
            }
            ProfileFeedTabs(feed, onFeed = { feed = it }, modifier = Modifier.padding(top = 14.dp))
            ProfilePhotoGrid()
            // ทางลัดทดสอบ: แผง lab (ล้างข้อมูล / กระโดดขั้น) — แอปจริงไม่มี
            Row(
                Modifier
                    .align(Alignment.CenterHorizontally)
                    .tap {
                        Haptics.impact(Haptics.Style.light)
                        onLab()
                    }
                    .padding(vertical = 18.dp),
                horizontalArrangement = Arrangement.spacedBy(5.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                PIcon(Ph.arrowsClockwise, size = 12f, weight = PhWeight.regular, tint = SH.hint)
                Text("ล้างข้อมูลทดสอบ / Lab", style = sh(12f, SHFont.semibold), color = SH.hint)
            }
        }
    }
}

private enum class ProfileFeed { grid, list, mentions }

// MARK: ปก + รูป + ชื่อ

@Composable
private fun ProfileHeader() {
    Column(Modifier.fillMaxWidth()) {
        Box(Modifier.fillMaxWidth().height(150.dp).background(SH.coverGrey)) {
            Row(Modifier.align(Alignment.Center), horizontalArrangement = Arrangement.spacedBy(60.dp)) {
                PIcon(Ph.imageSquare, size = 44f, weight = PhWeight.regular, tint = Color.White.opacity(0.9))
                PIcon(Ph.imageSquare, size = 44f, weight = PhWeight.regular, tint = Color.White.opacity(0.9))
            }
            Box(
                Modifier
                    .align(Alignment.TopEnd)
                    .padding(10.dp)
                    .size(30.dp)
                    .background(Color.White, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                PIcon(Ph.camera, size = 18f, weight = PhWeight.regular, tint = SH.muted)
            }
        }
        Box(Modifier.fillMaxWidth().height(80.dp).background(Color.White)) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Spacer(Modifier.size(118.dp, 60.dp))
                Column(Modifier.weight(1f).padding(top = 12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                        PIcon(Ph.sealCheck, size = 18f, weight = PhWeight.fill, tint = SH.verifiedBlue)
                        Text(
                            SHMockUser.name, style = sh(19f, SHFont.bold), color = SH.ink,
                            maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f),
                        )
                        Spacer(Modifier.width(6.dp))
                        Box(
                            Modifier
                                .size(36.dp)
                                .background(SHColor.redSoft, RoundedCornerShape(10.dp))
                                .tap { Haptics.impact(Haptics.Style.light) },
                            contentAlignment = Alignment.Center,
                        ) {
                            PIcon(Ph.shareFat, size = 18f, weight = PhWeight.regular, tint = SH.red)
                        }
                    }
                    Text(SHMockUser.bio, style = shSpaced(13f, SHFont.regular, 2f), color = SH.ink, overflow = TextOverflow.Ellipsis)
                }
            }
            // รูปโปรไฟล์ลอยทับปก — สูงกว่าแถบ 80pt จึงวัดแบบไม่จำกัดแล้วยื่นขึ้นไป
            ProfileAvatar(
                Modifier
                    .wrapContentSize(Alignment.TopStart, unbounded = true)
                    .padding(start = 10.dp)
                    .offset(y = (-62).dp),
            )
        }
    }
}

@Composable
private fun ProfileAvatar(modifier: Modifier = Modifier) {
    Box(modifier) {
        Box {
            SHAvatar(
                size = 112f,
                modifier = Modifier
                    .border(1.5.dp, SHColor.star, CircleShape)
                    .border(3.dp, Color.White, CircleShape),
            )
            Box(
                Modifier
                    .align(Alignment.BottomEnd)
                    .size(30.dp)
                    .background(SHColor.star, CircleShape)
                    .border(2.dp, Color.White, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                PIcon(Ph.star, size = 16f, weight = PhWeight.fill, tint = Color.White)
            }
        }
        PIcon(
            Ph.qrCode, size = 18f, weight = PhWeight.regular, tint = SH.muted,
            modifier = Modifier.align(Alignment.BottomStart).offset(x = (-2).dp, y = 8.dp),
        )
    }
}

@Composable
private fun ProfileStats() {
    Row(
        Modifier.fillMaxWidth().background(Color.White).padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ProfileStat("0", "ผู้ติดตาม")
        ProfileStatDivider()
        ProfileStat("0", "กำลังติดตาม")
        ProfileStatDivider()
        ProfileStat("5", "โพสต์")
        ProfileStatDivider()
        ProfileStat("7", "Engagement")
    }
}

@Composable
private fun ProfileStatDivider() {
    Box(Modifier.size(1.dp, 28.dp).background(SH.line))
}

@Composable
private fun RowScope.ProfileStat(n: String, label: String) {
    Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(n, style = sh(16f, SHFont.semibold), color = SH.ink)
        Text(label, style = sh(12f), color = SH.muted)
    }
}

@Composable
private fun ProfileTiles(campaignCount: Int) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        ProfileTile(title = "Coupon", sub = "เก็บคูปอง", tint = SH.blue) {
            PIcon(Ph.ticket, size = 22f, weight = PhWeight.fill, tint = Color.White)
        }
        ProfileTile(title = "Sale Here STAR", sub = "$campaignCount กิจกรรม", tint = SH.red) {
            Image(
                painterResource(SHIcon.starActive), contentDescription = null,
                colorFilter = ColorFilter.tint(Color.White), contentScale = ContentScale.Fit,
                modifier = Modifier.width(28.dp),
            )
        }
        Spacer(Modifier.weight(1f))
    }
}

@Composable
private fun ProfileTile(title: String, sub: String, tint: Color, icon: @Composable () -> Unit) {
    val shape = RoundedCornerShape(12.dp)
    Row(
        Modifier
            .background(Color.White, shape)
            .border(1.dp, SH.line, shape)
            .padding(8.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(40.dp).background(tint, RoundedCornerShape(8.dp)), contentAlignment = Alignment.Center) { icon() }
        Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(title, style = sh(14f, SHFont.bold), color = tint)
            Text(sub, style = sh(12f), color = SH.muted)
        }
    }
}

@Composable
private fun ProfileComposer() {
    val shape = RoundedCornerShape(12.dp)
    Box(
        Modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = 120.dp)
            .background(Color.White, shape)
            .border(1.dp, SH.line, shape),
    ) {
        Row(Modifier.fillMaxWidth().padding(12.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            SHAvatar(size = 40f)
            Text(
                "สวัสดีค่ะ คุณ ${SHMockUser.name}, โพสต์บอกเล่าประสบการณ์ หรือรีวิวกิจกรรมของคุณ",
                style = shSpaced(14f, SHFont.regular, 3f), color = SH.hint, modifier = Modifier.weight(1f),
            )
        }
        PIcon(
            Ph.imageSquare, size = 22f, weight = PhWeight.regular, tint = SH.red,
            modifier = Modifier.align(Alignment.BottomEnd).padding(12.dp),
        )
    }
}

@Composable
private fun ProfileDraftBanner() {
    Row(
        Modifier
            .fillMaxWidth()
            .background(SH.amberTint, RoundedCornerShape(12.dp))
            .padding(10.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(36.dp).background(SH.amber, RoundedCornerShape(8.dp)), contentAlignment = Alignment.Center) {
            PIcon(Ph.notePencil, size = 22f, weight = PhWeight.fill, tint = Color.White)
        }
        Text("สถานะดราฟต์รีวิว", style = sh(15f, SHFont.semibold), color = SH.ink)
        Spacer(Modifier.weight(1f))
    }
}

@Composable
private fun ProfileFeedTabs(feed: ProfileFeed, onFeed: (ProfileFeed) -> Unit, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().height(46.dp).background(Color.White)) {
        Row(Modifier.fillMaxSize()) {
            ProfileFeedItem(ProfileFeed.grid, Ph.squaresFour, feed, onFeed)
            ProfileFeedItem(ProfileFeed.list, Ph.list, feed, onFeed)
            ProfileFeedItem(ProfileFeed.mentions, Ph.at, feed, onFeed)
        }
        Box(Modifier.align(Alignment.BottomCenter).fillMaxWidth().height(1.dp).background(SH.line))
    }
}

@Composable
private fun RowScope.ProfileFeedItem(f: ProfileFeed, icon: Ph, feed: ProfileFeed, onFeed: (ProfileFeed) -> Unit) {
    val on = feed == f
    val tint by animateColorAsState(if (on) SH.red else SHColor.tabInactive, Motion.snap.spec(), label = "feedTint")
    val bar by animateColorAsState(if (on) SH.red else Color.Transparent, Motion.snap.spec(), label = "feedBar")
    Box(
        Modifier
            .weight(1f)
            .fillMaxHeight()
            .tap {
                if (on) return@tap
                Haptics.impact(Haptics.Style.light)
                onFeed(f)
            },
        contentAlignment = Alignment.Center,
    ) {
        PIcon(icon, size = 24f, weight = PhWeight.regular, tint = tint)
        Box(Modifier.align(Alignment.BottomCenter).fillMaxWidth().height(3.dp).background(bar))
    }
}

@Composable
private fun ProfilePhotoGrid() {
    val names = listOf(SHIcon.photo1, SHIcon.photo2, SHIcon.photo3, SHIcon.photo4, SHIcon.mockCoverThymora)
    Column(Modifier.fillMaxWidth().padding(top = 2.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        names.chunked(3).forEach { row ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                row.forEach { n ->
                    Image(
                        painterResource(n), contentDescription = null, contentScale = ContentScale.Crop,
                        modifier = Modifier.weight(1f).aspectRatio(1f).clipToBounds(),
                    )
                }
                repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
            }
        }
    }
}
