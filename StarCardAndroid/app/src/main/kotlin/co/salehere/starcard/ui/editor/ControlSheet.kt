package co.salehere.starcard.ui.editor

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import co.salehere.starcard.model.WidgetKind
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.ui.widgets.WidgetBody

/**
 * พรีวิวย่อของ widget หนึ่งแบบ (= Views/Editor/ControlSheet.swift)
 *
 * เรนเดอร์ที่ขนาดใช้งานจริงแล้วค่อยย่อทั้งก้อน — ถ้าเรนเดอร์เล็กตั้งแต่แรก
 * ข้อความจะโดนตัดจนดูไม่ออกว่า widget ทำอะไร
 */
@Composable
fun WidgetThumb(
    kind: WidgetKind,
    theme: CardTheme,
    width: Float = 104f,
    ratio: Float = 0.66f,
    modifier: Modifier = Modifier,
) {
    val vw = 300f
    val vh = vw * ratio
    val scale = width / vw
    val shape = RoundedCornerShape(12.dp)
    // กติกาเดียวกับบนการ์ด: เว้นขอบในได้เฉพาะใบที่มีแผ่นของ chrome รองอยู่ (ดู `WidgetChrome`)
    // — พรีวิวที่เว้นไม่เท่าของจริงคือพรีวิวที่โกหก
    val pad = if (kind.isFullBleed || kind.drawsOwnSurface || kind.defaultSurface == WidgetSurface.clear) 0f else 12f

    Box(
        modifier
            .size(width.dp, (width * ratio).dp)
            .clip(shape)
            .background(Color.White.opacity(0.05)),
        contentAlignment = Alignment.TopStart,
    ) {
        Box(
            Modifier
                .wrapContentSize(Alignment.TopStart, unbounded = true)
                .requiredSize(vw.dp, vh.dp)
                .graphicsLayer {
                    scaleX = scale
                    scaleY = scale
                    transformOrigin = TransformOrigin(0f, 0f)
                }
                .padding(pad.dp),
        ) {
            WidgetBody(kind, theme, Size(vw, vh))
        }
    }
}
