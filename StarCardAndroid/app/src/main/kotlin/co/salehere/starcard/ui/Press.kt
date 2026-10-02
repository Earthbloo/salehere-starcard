package co.salehere.starcard.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.theme.opacity

// MARK: - ปุ่มแบบ iOS — ไม่มี ripple (= `ButtonStyle` ของ SwiftUI)
//
// ทุกปุ่มในแอปใช้ตัวใดตัวหนึ่งในไฟล์นี้ — ห้ามใช้ `clickable` ที่มี indication ของ Material

/** แตะได้ ไม่มีเอฟเฟกต์ (= `Button { }.buttonStyle(.plain)`) */
@Composable
fun Modifier.tap(enabled: Boolean = true, onClick: () -> Unit): Modifier {
    val source = remember { MutableInteractionSource() }
    return this.clickable(interactionSource = source, indication = null, enabled = enabled, onClick = onClick)
}

/** กดแล้วยุบ 0.94 และจางเล็กน้อย (= `DockPress`) — ปุ่มบนถาดแต่งและแผงเครื่องมือทั้งหมด */
@Composable
fun Modifier.dockPress(enabled: Boolean = true, onClick: () -> Unit): Modifier {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val k by animateFloatAsState(if (pressed) 1f else 0f, Motion.snap.float, label = "dockPress")
    return this
        .graphicsLayer { val s = 1f - 0.06f * k; scaleX = s; scaleY = s; alpha = 1f - 0.15f * k }
        .clickable(interactionSource = source, indication = null, enabled = enabled, onClick = onClick)
}

/** แถวที่กดแล้วพื้นเข้มขึ้นจาง ๆ (= `PKRowPress`) */
@Composable
fun Modifier.pkRowPress(enabled: Boolean = true, onClick: () -> Unit): Modifier {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val k by animateFloatAsState(if (pressed) 1f else 0f, Motion.snap.float, label = "pkRowPress")
    return this
        .clickable(interactionSource = source, indication = null, enabled = enabled, onClick = onClick)
        .background(Color(0xFF16181D).opacity(0.055 * k))
}

/** กดแล้วจางลง (= `PKDimPress`) */
@Composable
fun Modifier.pkDimPress(enabled: Boolean = true, onClick: () -> Unit): Modifier {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val k by animateFloatAsState(if (pressed) 1f else 0f, Motion.snap.float, label = "pkDimPress")
    return this
        .graphicsLayer { alpha = 1f - 0.22f * k }
        .clickable(interactionSource = source, indication = null, enabled = enabled, onClick = onClick)
}
