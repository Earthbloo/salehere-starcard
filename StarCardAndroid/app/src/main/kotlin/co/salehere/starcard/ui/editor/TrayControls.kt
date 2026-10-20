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
                    .tap { if (!locked) onToggle(key) }
                    .padding(horizontal = 10.dp)
                    .alpha(if (locked) 0.6f else 1f),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Box(
                    Modifier
                        .size(14.dp)
                        .then(
                            if (on) Modifier.background(Color.White, RoundedCornerShape(3.dp))
                            else Modifier.border(1.5.dp, Color.White.opacity(0.45), RoundedCornerShape(3.dp)),
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    if (on) PIcon(Ph.check, size = 10f, weight = PhWeight.bold, tint = Color.Black.opacity(0.86))
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
        StepButton("−", enabled = i > 0) { onChange(values[i - 1]) }
        Text("$value", style = sh(14f, SHFont.bold), color = Color.White, modifier = Modifier.width(40.dp),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center)
        StepButton("+", enabled = i < values.size - 1) { onChange(values[i + 1]) }
    }
}

@Composable
private fun StepButton(glyph: String, enabled: Boolean, onClick: () -> Unit) {
    Box(Modifier.width(40.dp).height(32.dp).tap(enabled) { onClick() }, contentAlignment = Alignment.Center) {
        Text(glyph, style = sh(15f, SHFont.bold), color = Color.White.opacity(if (enabled) 0.9 else 0.25))
    }
}

/** แถวสวิตช์ — ป้ายซ้าย สวิตช์ขวา (= `KitSwitchRow`) */
@Composable
fun TraySwitchRow(label: String, on: Boolean, onChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = sh(12f, SHFont.semibold), color = Color.White.opacity(0.8))
        Spacer(Modifier.weight(1f))
        Box(
            Modifier
                .width(46.dp).height(28.dp)
                .background(if (on) Color(0xFF33C759) else Color.White.opacity(0.18), CircleShape)
                .tap { onChange(!on) }
                .padding(3.dp),
            contentAlignment = if (on) Alignment.CenterEnd else Alignment.CenterStart,
        ) {
            Box(Modifier.size(22.dp).background(Color.White, CircleShape))
        }
    }
}
