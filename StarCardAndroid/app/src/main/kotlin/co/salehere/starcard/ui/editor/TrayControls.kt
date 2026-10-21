package co.salehere.starcard.ui.editor

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.layout.offset
import androidx.compose.runtime.getValue
import androidx.compose.ui.unit.IntOffset
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.ui.dockPress
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.tap

// ชิ้นส่วนของตัวเลือกในถาด (`widget.controls`) — = KitTrayControls.swift
// ตามกติกาตัวควบคุมของแอป: หลายตัวเลือก = ช่องติ๊กที่มองเห็น · จำนวน = − n + · ของเสริม = สวิตช์

/** ช่องติ๊ก — ขึ้นบรรทัดใหม่เองเมื่อเต็ม · ช่องสุดท้ายที่ติ๊กอยู่เอาออกไม่ได้ (= `KitCheckRow`) */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun TrayCheckRow(
    items: List<Pair<String, String>>,
    hidden: Set<String>,
    shownCount: Int,
    minShown: Int = 1,
    onToggle: (String) -> Unit,
) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        items.forEach { (key, title) ->
            val on = key !in hidden
            val locked = on && shownCount <= minShown
            Row(
                Modifier
                    .height(30.dp)
                    .background(Color.White.opacity(if (on) 0.12 else 0.05), CircleShape)
                    // ช่องที่ล็อกยังรับแตะ (ยุบตามนิ้ว) แต่ไม่ทำอะไร — = `DockPress` ของ iOS
                    .dockPress { if (!locked) onToggle(key) }
                    .padding(horizontal = 10.dp)
                    .alpha(if (locked) 0.6f else 1f),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Box(
                    Modifier
                        .size(14.dp)
                        .then(
                            // = `checkmark.square.fill` / `square` 14pt semibold ของ iOS (ช่องเต็มขาว เครื่องหมายเป็นรูเจาะ)
                            if (on) Modifier.background(Color.White, RoundedCornerShape(2.5.dp))
                            else Modifier.border(1.3.dp, Color.White.opacity(0.45), RoundedCornerShape(2.5.dp)),
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    if (on) PIcon(Ph.check, size = 9f, weight = PhWeight.bold, tint = Color.Black.opacity(0.86))
                }
                Text(title, style = sh(12f, SHFont.semibold), color = Color.White.opacity(if (on) 0.92 else 0.55), maxLines = 1)
            }
        }
    }
}

/** − n + — ค่าที่เลือกได้เป็นขั้น เช่น 1 · 2 · 4 · 6 (= `KitStepper`) */
@Composable
fun TrayStepper(values: List<Int>, value: Int, onChange: (Int) -> Unit) {
    val i = values.indexOf(value).coerceAtLeast(0)
    Row(
        Modifier.height(32.dp).background(Color.Black.opacity(0.28), CircleShape),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        StepButton(Ph.minus, enabled = i > 0) { onChange(values[i - 1]) }
        Text("$value", style = sh(14f, SHFont.bold), color = Color.White, modifier = Modifier.width(40.dp),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center)
        StepButton(Ph.plus, enabled = i < values.size - 1) { onChange(values[i + 1]) }
    }
}

@Composable
private fun StepButton(glyph: Ph, enabled: Boolean, onClick: () -> Unit) {
    // = SF `minus`/`plus` 12pt bold ใน `DockPress` · ปิดใช้ = จาง 0.25
    Box(Modifier.width(40.dp).height(32.dp).dockPress(enabled) { onClick() }, contentAlignment = Alignment.Center) {
        PIcon(glyph, size = 12f, weight = PhWeight.bold, tint = Color.White.opacity(if (enabled) 0.9 else 0.25))
    }
}

/** แถวสวิตช์ — ป้ายซ้าย สวิตช์ขวา (= `KitSwitchRow`) */
@Composable
fun TraySwitchRow(label: String, on: Boolean, onChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = sh(12f, SHFont.semibold), color = Color.White.opacity(0.8))
        Spacer(Modifier.weight(1f))
        // = UISwitch ของระบบ: ราง 51×31 · ปุ่ม 27 · เขียว #33C759 / เทา #39393D (โหมดมืด) · ปุ่มเลื่อนและสีรางไหล
        val k by animateFloatAsState(if (on) 1f else 0f, Motion.snap.float, label = "switch")
        val track by animateColorAsState(if (on) Color(0xFF33C759) else Color(0xFF39393D), Motion.snap.spec(), label = "switchTrack")
        Box(
            Modifier
                .width(51.dp).height(31.dp)
                .background(track, CircleShape)
                .tap { onChange(!on) }
                .padding(2.dp),
            contentAlignment = Alignment.CenterStart,
        ) {
            Box(
                Modifier
                    .offset { IntOffset(((51f - 4f - 27f) * k * density).toInt(), 0) }
                    .size(27.dp)
                    .background(Color.White, CircleShape),
            )
        }
    }
}
