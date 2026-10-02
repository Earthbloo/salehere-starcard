package co.salehere.starcard.ui.salehere

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHColor
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.editor.LineBox
import co.salehere.starcard.ui.tap

// MARK: - ชิ้นส่วนหน้าจอ "แอป Sale Here จำลอง" (= SHKit.swift)
//
// หน้าพวกนี้เลียนแบบแอป Sale Here จริง (แถบแดง · การ์ดขาว · ปุ่มแดงเต็ม) ตาม screenshot 22 ก.ย. 2569
// เพื่อให้ Star Card มีบริบทตอนเทส flow — ไม่ใช่ภาษาของหน้า Star Card เอง (ดู `PK`)

object SH {
    val red = SHColor.red
    val ink = SHColor.ink
    val muted = SHColor.textSecondary
    val hint = SHColor.textTertiary
    val page = SHColor.page
    val line = SHColor.stroke
    /** ปกโปรไฟล์ยังไม่ตั้ง — เทาอ่อนแบบแอปหลัก */
    val coverGrey = Color(0xFFE9EAEC)
    /** กล่องเลขนับถอยหลัง */
    val clockBox = Color(0xFF1E2026)
    /** แถบ "สถานะดราฟต์รีวิว" */
    val amberTint = Color(0xFFFFF4E0)
    val amber = Color(0xFFF59E0B)
    val blue = Color(0xFF2563EB)
    val verifiedBlue = Color(0xFF1D9BF0)
}

/** แถบบนสีแดงของแอปหลัก — ชิ้นกลางเป็นชื่อหน้า ซ้าย/ขวาเป็นไอคอนขาว · พื้นแดงลามขึ้นใต้แถบสถานะ */
@Composable
fun SHNavBar(
    title: String,
    modifier: Modifier = Modifier,
    left: @Composable () -> Unit = {},
    right: @Composable () -> Unit = {},
) {
    Box(
        modifier
            .fillMaxWidth()
            .background(SH.red)
            .windowInsetsPadding(WindowInsets.statusBars)
            .height(48.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(title, style = sh(18f, SHFont.bold), color = Color.White, maxLines = 1, overflow = TextOverflow.Ellipsis)
        Row(
            Modifier.fillMaxSize().padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            left()
            Spacer(Modifier.weight(1f))
            right()
        }
    }
}

/** โลโก้ Sale Here บนแถบแดง — วงกลมขอบขาว ตัวหนังสือขาว (แบบหน้าโปรไฟล์แอปหลัก) */
@Composable
fun SHBarLogo(modifier: Modifier = Modifier) {
    Box(modifier.size(32.dp).border(1.5.dp, Color.White, CircleShape), contentAlignment = Alignment.Center) {
        Image(
            painterResource(SHIcon.wordmark), contentDescription = null,
            colorFilter = ColorFilter.tint(Color.White), contentScale = ContentScale.Fit,
            modifier = Modifier.width(22.dp),
        )
    }
}

/** ไอคอนขาวบนแถบแดง */
@Composable
fun SHBarIcon(icon: Ph, size: Float = 24f, action: () -> Unit = {}, modifier: Modifier = Modifier) {
    Box(
        modifier.size(32.dp).tap {
            Haptics.impact(Haptics.Style.light)
            action()
        },
        contentAlignment = Alignment.Center,
    ) {
        PIcon(icon, size = size, weight = PhWeight.regular, tint = Color.White)
    }
}

/** ปุ่มแดงเต็มกว้าง — CTA เดียวของแอปหลัก */
@Composable
fun SHRedButton(
    title: String,
    icon: Ph? = null,
    enabled: Boolean = true,
    height: Float = 48f,
    action: () -> Unit,
    modifier: Modifier = Modifier,
) {
    SHRedButtonFace(
        title = title, icon = icon, enabled = enabled, height = height,
        modifier = modifier.tap(enabled = enabled) {
            if (!enabled) return@tap
            Haptics.impact(Haptics.Style.medium)
            action()
        },
    )
}

/** หน้าตาของ `SHRedButton` อย่างเดียว ไม่รับแตะ (= `.allowsHitTesting(false)` บนการ์ดกิจกรรม — แตะแล้วเป็นของการ์ด) */
@Composable
internal fun SHRedButtonFace(title: String, icon: Ph?, enabled: Boolean, height: Float, modifier: Modifier = Modifier) {
    Row(
        modifier
            .fillMaxWidth()
            .height(height.dp)
            .background(if (enabled) SH.red else SHColor.strokeStrong, RoundedCornerShape(10.dp)),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) PIcon(icon, size = 20f, weight = PhWeight.regular, tint = Color.White)
        Text(title, style = sh(16f, SHFont.semibold), color = Color.White, maxLines = 1)
    }
}

/** ปุ่มขอบแดง ตัวแดง — ปุ่มรองในหน้าโปรไฟล์ */
@Composable
fun SHOutlineButton(title: String, icon: Ph? = null, action: () -> Unit, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(10.dp)
    Row(
        modifier
            .fillMaxWidth()
            .height(48.dp)
            .background(Color.White, shape)
            .border(1.2.dp, SH.red, shape)
            .tap {
                Haptics.impact(Haptics.Style.light)
                action()
            },
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) PIcon(icon, size = 20f, weight = PhWeight.regular, tint = SH.red)
        Text(title, style = sh(15f, SHFont.semibold), color = SH.red, maxLines = 1)
    }
}

/** แท็บล่างของแอปจำลอง — สองแท็บตามที่ตกลง: หน้าแรก (STAR) · โปรไฟล์ */
enum class SHTab { home, profile }

@Composable
fun SHTabBar(tab: SHTab, onTabChange: (SHTab) -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier
            .fillMaxWidth()
            .background(Color.White)
            .windowInsetsPadding(WindowInsets.navigationBars),
    ) {
        Row(Modifier.fillMaxWidth().padding(top = 8.dp, bottom = 2.dp)) {
            SHTabItem(SHTab.home, "หน้าแรก", tab, onTabChange) { tint ->
                Image(
                    painterResource(if (tab == SHTab.home) SHIcon.starActive else SHIcon.star), contentDescription = null,
                    colorFilter = ColorFilter.tint(tint), contentScale = ContentScale.Fit,
                    modifier = Modifier.size(44.dp, 26.dp),
                )
            }
            SHTabItem(SHTab.profile, "โปรไฟล์", tab, onTabChange) { _ ->
                SHAvatar(size = 28f, modifier = Modifier.border(2.dp, if (tab == SHTab.profile) SH.red else Color.Transparent, CircleShape))
            }
        }
        Box(Modifier.align(Alignment.TopCenter).fillMaxWidth().height(0.5.dp).background(SH.line))
    }
}

@Composable
private fun RowScope.SHTabItem(
    t: SHTab,
    label: String,
    tab: SHTab,
    onTabChange: (SHTab) -> Unit,
    icon: @Composable (Color) -> Unit,
) {
    val tint by animateColorAsState(if (tab == t) SH.red else SHColor.tabInactive, Motion.settle.spec(), label = "shTab")
    Column(
        Modifier.weight(1f).tap {
            if (tab == t) return@tap
            Haptics.impact(Haptics.Style.light)
            onTabChange(t)
        },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Box(Modifier.height(28.dp), contentAlignment = Alignment.Center) { icon(tint) }
        Text(label, style = sh(11f, SHFont.medium), color = tint)
    }
}

/** รูปโปรไฟล์วงกลม — รูปเดียวกับที่ hub "ข้อมูลของฉัน" ใช้ ให้คนเดียวกันทั้ง flow */
@Composable
fun SHAvatar(size: Float, modifier: Modifier = Modifier) {
    val photos = LocalPhotoStore.current
    Box(modifier.size(size.dp).clip(CircleShape)) {
        photos?.avatar(Modifier.fillMaxSize())
    }
}

/** ชื่อที่โชว์ในแอปจำลอง — ชื่อจาก "ข้อมูลของฉัน" ถ้ากรอกแล้ว ไม่งั้นชื่อบัญชีทดสอบ */
object SHMockUser {
    const val fallbackName = "Tarmjaipa"
    const val fallbackBio = "ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่ร้านคาเฟ่น่ารักๆ"

    val name: String
        get() {
            val p = Profile.me
            return if (p.isPlaceholder(ProfileField.personName)) fallbackName else p.name
        }
    val bio: String
        get() {
            val p = Profile.me
            return if (p.isPlaceholder(ProfileField.tagline)) fallbackBio else p.tagline
        }
}

// MARK: - ตัวช่วยของหน้าในแอปจำลอง (ไม่มีใน Swift — แทน API ของ SwiftUI ที่ Compose ไม่มี)

/** `.font(.sh(size, weight)).lineSpacing(x)` — SwiftUI บวกระยะเพิ่มจากกล่องบรรทัดธรรมชาติ */
internal fun shSpaced(size: Float, weight: FontWeight = SHFont.regular, spacing: Float): TextStyle =
    sh(size, weight).copy(lineHeight = (size * LineBox + spacing).sp)

/**
 * `.onLongPressGesture(minimumDuration:)` — กดค้างครบเวลาโดยไม่ขยับเกินระยะแตะ แล้วกลืนนิ้วที่เหลือ
 * (ปุ่มที่อยู่ใต้นิ้วจะไม่ถูกกดซ้ำตอนปล่อย)
 */
@Composable
internal fun Modifier.shLongPress(seconds: Double = 0.6, action: () -> Unit): Modifier {
    val latest by rememberUpdatedState(action)
    return this.pointerInput(seconds) {
        awaitEachGesture {
            val down = awaitFirstDown(requireUnconsumed = false, pass = PointerEventPass.Initial)
            val slop = viewConfiguration.touchSlop
            val ended = withTimeoutOrNull((seconds * 1000).toLong()) {
                var stop = false
                while (!stop) {
                    val e = awaitPointerEvent(PointerEventPass.Initial)
                    val c = e.changes.firstOrNull { it.id == down.id }
                    stop = c == null || !c.pressed || (c.position - down.position).getDistance() > slop
                }
                true
            }
            if (ended == null) {
                latest()
                var pressed = true
                while (pressed) {
                    val e = awaitPointerEvent(PointerEventPass.Initial)
                    e.changes.forEach { it.consume() }
                    pressed = e.changes.any { it.pressed }
                }
            }
        }
    }
}

/**
 * ชั้นที่เปิดทับเต็มจอต้องกันนิ้วไม่ให้ทะลุไปหน้าข้างใต้ — SwiftUI กันให้เองเพราะพื้นของชั้นรับแตะได้
 * Compose ส่งแตะผ่านบริเวณที่ไม่มีตัวรับ จึงใส่ตัวรับเปล่าไว้ที่รากของชั้น (ไม่กลืน event — ลูกข้างในยังได้ตามปกติ)
 */
internal fun Modifier.shBlockTouches(): Modifier = this.pointerInput(Unit) {
    awaitPointerEventScope {
        while (true) awaitPointerEvent(PointerEventPass.Final)
    }
}

/** ค่าล่าสุดที่ไม่ใช่ null — ให้ชั้นที่กำลังเลื่อนออกยังวาดของเดิมได้ (= `if let x` ของ SwiftUI ระหว่าง removal transition) */
@Composable
internal fun <T : Any> rememberShLast(value: T?): T? {
    val holder = androidx.compose.runtime.remember { arrayOfNulls<Any?>(1) }
    if (value != null) holder[0] = value
    @Suppress("UNCHECKED_CAST")
    return holder[0] as T?
}
