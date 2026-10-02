package co.salehere.starcard.ui.salehere.starflow

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.lerp
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.SpringToken
import co.salehere.starcard.components.float
import co.salehere.starcard.theme.CardBackdrop
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SignaturePattern
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.tap
import kotlin.math.roundToInt

// MARK: - หัวร่วมของสองหน้า (Star Profile ↔ Star Card) — ชิ้นเดียว ไม่เปลี่ยนตำแหน่งตอนสลับหน้า
//
// ผู้ใช้ 23 ก.ย. 2569: "title กับ toggle ต้องรักษาไว้เหมือนชิ้นเดียวกัน" — หัวนี้จึงไม่ได้อยู่ในหน้าใดหน้าหนึ่ง
// แต่ลอยอยู่บนทั้งสองหน้าใน `SaleHereShell` เปลี่ยนแค่คำ (Profile ⇄ Card) สี (หมึก ⇄ ขาว) และลูกบิดของ toggle

/**
 * - hasCard: ยังไม่มีการ์ด = หัว "สมัครเป็น STAR" ไม่มี toggle (ยังไม่มีหน้าการ์ดให้สลับ)
 * - showsToggle: ปุ่มสลับ ข้อมูล | การ์ด — เลิกใช้ 24 ก.ย. 2569 (การ์ดอยู่บนหน้า Profile แล้ว หน้า Card มีปุ่ม ‹ กลับแทน)
 */
@Composable
fun StarHeader(
    isCard: Boolean,
    hasCard: Boolean = true,
    showsDot: Boolean,
    showsToggle: Boolean = true,
    onToggle: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    val t by animateFloatAsState(if (isCard) 1f else 0f, Motion.page.float, label = "starHeader")
    Row(
        modifier
            .fillMaxWidth()
            .height(64.dp)
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.Bottom,
    ) {
        if (hasCard) HeaderTitle(t) else GlassTitle(words = listOf("สมัครเป็น" to false, "STAR" to true), small = true)
        Spacer(Modifier.weight(1f))
        if (hasCard && showsToggle) {
            HeaderToggle(isCard = isCard, t = t, showsDot = showsDot, onToggle = onToggle, modifier = Modifier.padding(bottom = 6.dp))
        }
    }
}

/** "Star" + คำ serif — คำ serif ไขว้จางกัน ตัวหนังสือเปลี่ยนสีตามพื้น (หมึกบนสว่าง · ขาวบนมืด) */
@Composable
private fun HeaderTitle(t: Float) {
    val d = LocalDensity.current.density
    val k = t.coerceIn(0f, 1f)
    val ink = lerp(GL.ink, Color.White, k)
    val gold = lerp(GL.goldInk, rgb(232 / 255.0, 199 / 255.0, 102 / 255.0), k)
    val serifBrush = Brush.verticalGradient(listOf(ink, ink, gold))
    val serifShadow = Shadow(lerp(GL.ink.opacity(0.12), Color.Black.opacity(0.3), k), Offset(0f, 12f * d), 9f * d)
    FitWidth(minScale = 0.7f) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            BasicText(
                "Star",
                Modifier.alignByBaseline(),
                style = sh(46f, SHFont.heavy).copy(
                    color = ink,
                    letterSpacing = (-2f).sp,
                    shadow = Shadow(lerp(GL.ink.opacity(0.14), Color.Black.opacity(0.35), k), Offset(0f, 14f * d), 15f * d),
                ),
                maxLines = 1, softWrap = false,
            )
            Box(Modifier.alignByBaseline()) {
                BasicText(
                    "Profile",
                    Modifier.graphicsLayer {
                        alpha = 1f - k
                        translationY = -6.dp.toPx() * t
                    },
                    style = GL.serif(54f).copy(brush = serifBrush, shadow = serifShadow),
                    maxLines = 1, softWrap = false,
                )
                BasicText(
                    "Card",
                    Modifier.graphicsLayer {
                        alpha = k
                        translationY = 6.dp.toPx() * (1f - t)
                    },
                    style = GL.serif(54f).copy(brush = serifBrush, shadow = serifShadow),
                    maxLines = 1, softWrap = false,
                )
            }
        }
    }
}

/** toggle ข้อมูล | การ์ด — ลูกบิดเลื่อนไปมาในรางเดียว (= matchedGeometry) ไม่ใช่สองปุ่มคนละหน้า */
@Composable
private fun HeaderToggle(isCard: Boolean, t: Float, showsDot: Boolean, onToggle: (Boolean) -> Unit, modifier: Modifier) {
    val dens = LocalDensity.current
    var w0 by remember { mutableIntStateOf(0) }
    var w1 by remember { mutableIntStateOf(0) }
    val gap = with(dens) { 2.dp.roundToPx() }
    val knobX by animateFloatAsState(if (isCard) (w0 + gap).toFloat() else 0f, Motion.page.float, label = "knobX")
    val knobW by animateFloatAsState((if (isCard) w1 else w0).toFloat(), Motion.page.float, label = "knobW")
    val knob by animateColorAsState(if (isCard) Color.White.opacity(0.92) else GL.ink, Motion.page.spec(), label = "knob")
    Box(
        modifier
            .glShadow(GL.ink.opacity(if (isCard) 0.0 else 0.07), 8f, 4f)
            .clip(CircleShape)
            .background(Color.White.opacity(if (isCard) 0.14 else 0.6))
            .border(if (isCard) 0.6.dp else 1.dp, Color.White.opacity(if (isCard) 0.22 else 0.95), CircleShape)
            .padding(3.dp),
    ) {
        if (w0 > 0) {
            Box(
                Modifier
                    .offset { IntOffset(knobX.roundToInt(), 0) }
                    .width(with(dens) { knobW.toDp() })
                    .height(32.dp)
                    .background(knob, CircleShape),
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            ToggleChip("ข้อมูล", on = !isCard, dot = false, isCard = isCard, modifier = Modifier.onSizeChanged { w0 = it.width }) { onToggle(false) }
            ToggleChip("การ์ด", on = isCard, dot = showsDot && !isCard, isCard = isCard, modifier = Modifier.onSizeChanged { w1 = it.width }) { onToggle(true) }
        }
    }
}

@Composable
private fun ToggleChip(title: String, on: Boolean, dot: Boolean, isCard: Boolean, modifier: Modifier, action: () -> Unit) {
    val color = if (on) (if (isCard) Color.Black.opacity(0.88) else Color.White) else (if (isCard) Color.White.opacity(0.85) else GL.ink)
    Row(
        modifier
            .height(32.dp)
            .clip(CircleShape)
            .tap {
                if (on) return@tap
                Haptics.impact(Haptics.Style.light)
                action()
            }
            .padding(horizontal = 13.dp),
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title, style = sh(13f, SHFont.bold), color = color)
        if (dot) Box(Modifier.size(6.dp).background(GL.green, CircleShape))
    }
}

// MARK: - พื้นร่วม + ดวงไฟ — แสงเดียวกันเดินทางจากหน้าโปรไฟล์ไปหน้าการ์ด
//
// ผู้ใช้: "แสงที่หมุนจาก dark กับ light มันต้องสวิตช์ไฟเหมือน move ดวงไฟ" — พื้นสว่าง ↔ เวทีมืดของธีมการ์ด
// และดวงไฟ champagne สองดวงของหน้าโปรไฟล์คือดวงเดียวกับแสงสีธีมที่ส่องการ์ด แค่ย้ายที่และเปลี่ยนสี

/** - theme: ธีมของใบที่กำลังดู — สีของดวงไฟและเวทีในสถานะการ์ด */
@Composable
fun StarGround(isCard: Boolean, theme: CardTheme?, modifier: Modifier = Modifier) {
    val accent by animateColorAsState(theme?.rawAccent ?: GL.gold, Motion.settle.spec(), label = "groundAccent")
    val t by animateFloatAsState(if (isCard) 1f else 0f, Motion.lamp.float, label = "lamp")
    Box(modifier.fillMaxSize().background(GL.bg)) {
        if (theme != null) {
            Box(Modifier.fillMaxSize().graphicsLayer { alpha = t.coerceIn(0f, 1f) }) {
                CardBackdrop(theme = theme, ignoreSafeArea = false)
                Box(
                    Modifier
                        .fillMaxSize()
                        .background(Brush.verticalGradient(listOf(Color.Black.opacity(0.54), Color.Black.opacity(0.36), Color.Black.opacity(0.6)))),
                )
                SignaturePattern(opacity = 0.06, modifier = Modifier.fillMaxSize())
            }
        }
        Canvas(Modifier.fillMaxSize()) {
            val w = size.width
            val h = size.height
            val k = t.coerceIn(0f, 1f)
            // ดวงไฟหลัก: มุมซ้ายบน champagne → กลางจอเป็นสีธีมส่องการ์ด
            glowOrb(
                lerp(GL.orb1, accent, k),
                lerp(Offset(30.dp.toPx(), 110.dp.toPx()), Offset(w * 0.5f, h * 0.46f), t),
                170.dp.toPx(), 70.dp.toPx(), 0.7f + (0.5f - 0.7f) * k,
            )
            // ดวงรอง: ขวา → ตามไปคล้อยหลัง
            glowOrb(
                lerp(GL.orb2, accent, k),
                lerp(Offset(w + 10.dp.toPx(), 250.dp.toPx()), Offset(w * 0.62f, h * 0.56f), t),
                160.dp.toPx(), 70.dp.toPx(), 0.5f + (0.28f - 0.5f) * k,
            )
            // จุดสว่างขาว: หายไปเมื่อเป็นเวทีมืด
            glowOrb(
                Color.White,
                lerp(Offset(260.dp.toPx(), 110.dp.toPx()), Offset(w * 0.5f, h * 0.42f), t),
                70.dp.toPx(), 30.dp.toPx(), 0.9f + (0.08f - 0.9f) * k,
            )
        }
    }
}

/** ดวงไฟเดินทาง — ช้ากว่าเปลี่ยนหน้านิดหน่อย ให้เห็นแสงย้ายที่จริง ๆ (= `Motion.lamp`) */
val Motion.lamp: SpringToken get() = SpringToken(110f, 22f)
