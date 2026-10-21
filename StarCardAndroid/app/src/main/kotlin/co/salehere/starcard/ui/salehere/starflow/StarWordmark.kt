package co.salehere.starcard.ui.salehere.starflow

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.layout.FirstBaseline
import androidx.compose.ui.layout.LastBaseline
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import kotlin.math.roundToInt

// MARK: - ตรา ST★R ของ Sale Here เป็นหัวข้อ (= StarWordmark.swift)
//
// ผู้ใช้ 30 ก.ย. 2569: "เอา STAR ใน icon มาใส่แทนเลย Card/Profile ใช้ font เหมือนเดิม" — คำ "Star" ตัวหนาในหัวข้อ
// จึงถูกแทนด้วยเวกเตอร์ ST★R ตัวจริงจาก `ic-salehere-star-outline.pdf` (เฉพาะตัวพิมพ์ใหญ่ ตัดตัวเขียน Sale Here ด้านบนออก)
// วาดเป็น Path ไม่ใช่รูป เพราะต้องย้อมสีตามพื้น (หมึกบนสว่าง · ขาวบนการ์ดมืด) และต้องวางบน baseline เดียวกับคำ serif

/** เส้นทางของตัว S T ★ R — พิกัดเดิมจาก PDF (กรอบ x 0.8…33.2 · y 10.7…21.1 · baseline ตัวอักษรที่ y 20.8) */
object StarCapsShape {
    private const val boxX = 0.8f
    private const val boxY = 10.7f
    const val boxW = 32.4f
    const val boxH = 10.4f
    /** กว้าง : สูง ของตรา */
    const val aspect = boxW / boxH
    /** ส่วนที่ตัว S ล้นใต้ baseline (สัดส่วนของความสูง) — ใช้ยก baseline ให้ตรงกับคำ serif */
    const val descent = (21.1f - 20.8f) / boxH

    /** path ในกรอบ `width × height` (px) — even-odd เหมือน `FillStyle(eoFill: true)` */
    fun path(width: Float, height: Float): Path {
        val s = width / boxW
        fun px(x: Double) = (x.toFloat() - boxX) * s
        fun py(y: Double) = (y.toFloat() - boxY) * s
        val p = Path()
        p.fillType = PathFillType.EvenOdd
        fun move(x: Double, y: Double) = p.moveTo(px(x), py(y))
        fun line(x: Double, y: Double) = p.lineTo(px(x), py(y))
        fun curve(x: Double, y: Double, c1x: Double, c1y: Double, c2x: Double, c2y: Double) =
            p.cubicTo(px(c1x), py(c1y), px(c2x), py(c2y), px(x), py(y))

        move(20.684, 14.485)
        line(19.098, 11.244)
        line(17.512, 14.485)
        line(13.965, 15.006)
        line(16.531, 17.528)
        line(15.926, 21.091)
        line(19.098, 19.409)
        line(22.27, 21.091)
        line(21.664, 17.528)
        line(24.23, 15.006)
        line(20.684, 14.485)
        p.close()
        move(19.826, 15.765)
        line(19.093, 14.265)
        line(18.358, 15.765)
        line(16.717, 16.006)
        line(17.905, 17.173)
        line(17.624, 18.822)
        line(19.093, 18.043)
        line(20.56, 18.822)
        line(20.28, 17.173)
        line(21.468, 16.006)
        line(19.826, 15.765)
        p.close()
        move(3.046, 17.554)
        curve(3.221, 18.379, 3.046, 17.876, 3.104, 18.152)
        curve(3.689, 18.939, 3.339, 18.607, 3.494, 18.794)
        curve(4.366, 19.258, 3.884, 19.084, 4.11, 19.191)
        curve(5.168, 19.36, 4.622, 19.326, 4.89, 19.36)
        curve(5.569, 19.338, 5.293, 19.36, 5.426, 19.353)
        curve(5.992, 19.266, 5.712, 19.323, 5.852, 19.299)
        curve(6.393, 19.128, 6.131, 19.232, 6.265, 19.185)
        curve(6.732, 18.905, 6.521, 19.07, 6.634, 18.996)
        curve(6.967, 18.583, 6.829, 18.814, 6.908, 18.707)
        curve(7.056, 18.15, 7.026, 18.459, 7.056, 18.315)
        curve(6.941, 17.705, 7.056, 17.985, 7.018, 17.831)
        curve(6.626, 17.375, 6.864, 17.579, 6.759, 17.469)
        curve(6.153, 17.131, 6.493, 17.282, 6.335, 17.2)
        curve(5.562, 16.942, 5.97, 17.062, 5.774, 16.999)
        curve(4.9, 16.777, 5.351, 16.886, 5.13, 16.831)
        curve(4.204, 16.605, 4.67, 16.724, 4.437, 16.667)
        curve(3.493, 16.39, 3.963, 16.541, 3.727, 16.469)
        curve(2.823, 16.113, 3.259, 16.31, 3.036, 16.219)
        curve(2.23, 15.753, 2.61, 16.008, 2.412, 15.888)
        curve(1.757, 15.276, 2.047, 15.617, 1.889, 15.458)
        curve(1.444, 14.648, 1.624, 15.093, 1.52, 14.884)
        curve(1.331, 13.844, 1.369, 14.413, 1.331, 14.144)
        curve(1.475, 12.939, 1.331, 13.514, 1.379, 13.213)
        curve(1.874, 12.203, 1.571, 12.664, 1.703, 12.419)
        curve(2.472, 11.634, 2.043, 11.986, 2.243, 11.797)
        curve(3.214, 11.229, 2.7, 11.471, 2.948, 11.336)
        curve(4.047, 10.989, 3.479, 11.123, 3.757, 11.043)
        curve(4.914, 10.909, 4.336, 10.936, 4.625, 10.909)
        curve(5.896, 10.989, 5.247, 10.909, 5.574, 10.936)
        curve(6.806, 11.234, 6.218, 11.043, 6.521, 11.124)
        curve(7.593, 11.655, 7.09, 11.343, 7.353, 11.484)
        curve(8.215, 12.265, 7.833, 11.826, 8.04, 12.029)
        curve(8.623, 13.071, 8.389, 12.5, 8.525, 12.77)
        curve(8.769, 14.08, 8.72, 13.373, 8.769, 13.709)
        line(6.723, 14.08)
        curve(6.545, 13.356, 6.707, 13.79, 6.648, 13.549)
        curve(6.14, 12.899, 6.443, 13.164, 6.308, 13.012)
        curve(5.556, 12.662, 5.972, 12.786, 5.777, 12.707)
        curve(4.85, 12.594, 5.336, 12.617, 5.1, 12.594)
        curve(4.329, 12.65, 4.678, 12.594, 4.504, 12.613)
        curve(3.856, 12.833, 4.155, 12.687, 3.997, 12.748)
        curve(3.511, 13.17, 3.715, 12.919, 3.6, 13.031)
        curve(3.376, 13.683, 3.421, 13.309, 3.376, 13.48)
        curve(3.422, 14.003, 3.376, 13.806, 3.392, 13.913)
        curve(3.582, 14.245, 3.452, 14.093, 3.505, 14.174)
        curve(3.902, 14.444, 3.659, 14.316, 3.766, 14.382)
        curve(4.423, 14.637, 4.038, 14.505, 4.211, 14.57)
        curve(5.183, 14.855, 4.634, 14.704, 4.887, 14.778)
        curve(6.228, 15.131, 5.479, 14.933, 5.828, 15.024)
        curve(6.687, 15.248, 6.346, 15.161, 6.499, 15.2)
        curve(7.287, 15.452, 6.874, 15.296, 7.074, 15.364)
        curve(7.931, 15.783, 7.5, 15.539, 7.714, 15.649)
        curve(8.514, 16.282, 8.146, 15.917, 8.341, 16.083)
        curve(8.937, 16.988, 8.687, 16.48, 8.828, 16.716)
        curve(9.1, 17.95, 9.045, 17.261, 9.1, 17.581)
        curve(8.841, 19.19, 9.1, 18.395, 9.014, 18.808)
        curve(8.075, 20.178, 8.668, 19.571, 8.413, 19.9)
        curve(6.82, 20.829, 7.737, 20.456, 7.319, 20.672)
        curve(5.092, 21.064, 6.32, 20.985, 5.745, 21.064)
        curve(4.047, 20.97, 4.737, 21.064, 4.388, 21.033)
        curve(3.079, 20.684, 3.706, 20.907, 3.384, 20.812)
        curve(2.239, 20.203, 2.775, 20.557, 2.495, 20.396)
        curve(1.579, 19.523, 1.983, 20.009, 1.763, 19.783)
        curve(1.149, 18.642, 1.395, 19.263, 1.251, 18.969)
        curve(1.0, 17.554, 1.046, 18.314, 0.997, 17.951)
        line(3.046, 17.554)
        line(3.046, 17.554)
        p.close()
        move(8.608, 12.991)
        line(8.608, 11.146)
        line(16.237, 11.146)
        line(16.237, 12.991)
        line(13.443, 12.991)
        line(13.443, 20.826)
        line(11.359, 20.826)
        line(11.359, 12.991)
        line(8.607, 12.991)
        line(8.608, 12.991)
        p.close()
        move(29.221, 11.146)
        curve(30.577, 11.335, 29.727, 11.146, 30.179, 11.209)
        curve(31.585, 11.875, 30.976, 11.461, 31.312, 11.641)
        curve(32.211, 12.735, 31.859, 12.109, 32.068, 12.396)
        curve(32.428, 13.882, 32.355, 13.074, 32.428, 13.456)
        curve(32.383, 14.573, 32.428, 14.125, 32.413, 14.354)
        curve(32.227, 15.183, 32.352, 14.791, 32.3, 14.994)
        curve(31.929, 15.703, 32.153, 15.372, 32.054, 15.545)
        curve(31.464, 16.124, 31.804, 15.861, 31.649, 16.002)
        curve(31.814, 16.487, 31.607, 16.234, 31.725, 16.355)
        curve(32.031, 16.916, 31.904, 16.62, 31.976, 16.763)
        curve(32.158, 17.4, 32.086, 17.07, 32.128, 17.231)
        curve(32.233, 17.931, 32.189, 17.57, 32.214, 17.746)
        curve(32.262, 18.733, 32.246, 18.209, 32.255, 18.476)
        curve(32.336, 19.476, 32.268, 18.989, 32.293, 19.238)
        curve(32.55, 20.17, 32.379, 19.715, 32.451, 19.946)
        curve(33.001, 20.826, 32.65, 20.395, 32.8, 20.613)
        line(30.778, 20.826)
        curve(30.466, 20.271, 30.635, 20.652, 30.53, 20.467)
        curve(30.327, 19.656, 30.402, 20.076, 30.356, 19.871)
        curve(30.264, 18.988, 30.297, 19.441, 30.277, 19.219)
        curve(30.187, 18.269, 30.251, 18.758, 30.226, 18.518)
        curve(30.094, 17.8, 30.161, 18.112, 30.131, 17.954)
        curve(29.926, 17.386, 30.057, 17.645, 30.001, 17.507)
        curve(29.619, 17.091, 29.851, 17.265, 29.748, 17.167)
        curve(29.107, 16.977, 29.489, 17.015, 29.319, 16.977)
        line(26.649, 16.977)
        line(26.649, 20.826)
        line(24.561, 20.826)
        line(24.561, 11.146)
        line(29.223, 11.146)
        line(29.221, 11.146)
        p.close()
        move(28.668, 15.291)
        curve(29.3, 15.228, 28.886, 15.291, 29.096, 15.27)
        curve(29.842, 15.017, 29.503, 15.185, 29.684, 15.115)
        curve(30.221, 14.63, 30.001, 14.919, 30.127, 14.789)
        curve(30.363, 14.041, 30.315, 14.47, 30.363, 14.274)
        curve(30.289, 13.596, 30.363, 13.883, 30.339, 13.735)
        curve(30.063, 13.23, 30.239, 13.457, 30.164, 13.335)
        curve(29.681, 12.983, 29.962, 13.126, 29.835, 13.043)
        curve(29.143, 12.893, 29.527, 12.924, 29.349, 12.893)
        line(26.647, 12.893)
        line(26.647, 15.291)
        line(28.668, 15.291)
        p.close()
        return p
    }
}

/** ขนาดของตรา ST★R เทียบกับตัวอักษรรอบข้าง (= static ของ `StarCaps` ใน iOS) */
object StarCaps {
    /** ความสูงตราที่เข้าคู่กับคำ serif ขนาดนั้น (สัดส่วนจากแคนวาส: caps .74em ต่อ serif 1.16em) */
    fun heightForSerif(size: Float): Float = size * 0.64f
    /** ความสูงตราเมื่อแทนคำ STAR กลางประโยค (ปุ่ม ป้าย) — โตกว่าตัวอักษรรอบข้างเล็กน้อย */
    fun heightForText(size: Float): Float = size * 0.82f
    /** ความสูงตราเมื่อเป็นคำเน้นในหัวข้อ ("สมัครเป็น STAR") — เท่า cap height ของคำ serif เดิม */
    fun heightForEmphasis(heavySize: Float): Float = heavySize * 0.95f
    /** ช่องว่างระหว่างตรากับคำ serif */
    fun gapForSerif(size: Float): Float = size * 0.19f
}

/**
 * ตรา ST★R สูง `height` (dp) ย้อมสีเดียว — ประกาศ `FirstBaseline`/`LastBaseline` ไว้ที่ baseline ของตัวอักษร
 * จึงวางใน `Row` ด้วย `Modifier.alignBy(LastBaseline)` / `alignByBaseline()` ให้ตรงกับคำ serif ข้าง ๆ ได้
 * (= `.alignmentGuide(.lastTextBaseline) { d[.bottom] - height * descent }`)
 */
@Composable
fun StarCaps(height: Float, color: Color = GL.ink, modifier: Modifier = Modifier) {
    val density = LocalDensity.current.density
    val width = height * StarCapsShape.aspect
    val path = remember(width, height, density) { StarCapsShape.path(width * density, height * density) }
    Canvas(
        modifier
            .layout { measurable, constraints ->
                val p = measurable.measure(constraints)
                val baseline = (p.height - height * StarCapsShape.descent * density).roundToInt()
                layout(p.width, p.height, mapOf(FirstBaseline to baseline, LastBaseline to baseline)) { p.placeRelative(0, 0) }
            }
            .size(width.dp, height.dp)
            .semantics { contentDescription = "Star" },
    ) {
        drawPath(path, color)
    }
}

/** สีคำ serif ของหัวข้อ: หมึก→ทองบนพื้นสว่าง · ขาว→ทองอ่อนบนการ์ดมืด (= `GL.serifInk(onDark:)`) */
fun serifInkBrush(onDark: Boolean): Brush = Brush.verticalGradient(
    if (onDark) listOf(Color.White, Color.White, rgb(232 / 255.0, 199 / 255.0, 102 / 255.0))
    else listOf(GL.ink, GL.ink, GL.goldInk),
)

/** หัวข้อ "ST★R + คำ serif" สำเร็จรูป — ใช้ที่ที่ไม่ต้องไขว้จางสองคำ (= `StarWordmark`) */
@Composable
fun StarWordmark(word: String, serifSize: Float = 54f, onDark: Boolean = false, modifier: Modifier = Modifier) {
    val density = LocalDensity.current.density
    val wordShadow = Shadow(if (onDark) Color.Black.opacity(0.3) else GL.ink.opacity(0.12), Offset(0f, 12f * density), 9f * density)
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(StarCaps.gapForSerif(serifSize).dp)) {
        StarCaps(
            height = StarCaps.heightForSerif(serifSize),
            color = if (onDark) Color.White else GL.ink,
            modifier = Modifier.alignBy(LastBaseline),
        )
        BasicText(
            word,
            Modifier.alignBy(LastBaseline),
            style = GL.serif(serifSize).merge(TextStyle(brush = serifInkBrush(onDark), shadow = wordShadow)),
            maxLines = 1,
            softWrap = false,
        )
    }
    // เงาฟุ้งใต้ตรา (iOS `.shadow(radius: 15, y: 14)`) ไม่ถูกจำลอง — ตราเป็น path สีเดียว เงาของมันจางจนแทบไม่เห็นบนพื้นทั้งสอง
}
