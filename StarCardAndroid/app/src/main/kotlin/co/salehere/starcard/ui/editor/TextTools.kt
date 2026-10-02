package co.salehere.starcard.ui.editor

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.gestures.snapping.SnapPosition
import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.components.legibilityHalo
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.TextAlignment
import co.salehere.starcard.theme.TextFit
import co.salehere.starcard.theme.TextTint
import co.salehere.starcard.theme.WidgetTextStyle
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.max

// MARK: - โหมดพิมพ์ข้อความ — ท่าเดียวกับ Instagram Story (= Views/Editor/TextTools.swift)
//
// * **พิมพ์บนการ์ดตรง ๆ** — เคอร์เซอร์อยู่ที่ตัวอักษรบนการ์ด ไม่มีช่องกรอกแยก (ดู `CanvasTextField`)
// * เหนือแป้นพิมพ์มีสองแถว: **ชื่อฟอนต์ที่เขียนด้วยฟอนต์นั้น** กับ **แถวไอคอน** (ฟอนต์ · สี · จัดวาง · ลบ)
// * **ไม่มีปุ่มขนาด** — ขนาดปรับที่หมุดมุมของกล่องบนการ์ด
// * **เสร็จ** อยู่มุมขวาบน · แตะที่ว่างบนการ์ดก็เสร็จเหมือนกัน · ก้อนที่ว่างเปล่าตอนเสร็จหายไปเอง

/** น้ำหนักตัวอักษรของก้อนข้อความ (= `TextBlock.weight` ใน TextWidgets.swift) — ช่องพิมพ์ต้องใช้ตัวเดียวกับที่การ์ดวาด */
internal val TextBlockWeight: FontWeight = SHFont.semibold

private enum class ToolRow { font, color }

/** สองแถวเหนือแป้นพิมพ์ — ไม่มีช่องกรอก ตัวอักษรอยู่บนการ์ด */
@Composable
fun TextTools(
    theme: CardTheme,
    style: WidgetTextStyle,
    onStyle: ((WidgetTextStyle) -> WidgetTextStyle) -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var row by remember { mutableStateOf(ToolRow.font) }

    Column(modifier.padding(bottom = 8.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        AnimatedContent(
            targetState = row,
            transitionSpec = { fadeIn(Motion.snap.spec()) togetherWith fadeOut(Motion.snap.spec()) },
            label = "toolRow",
        ) { r ->
            when (r) {
                ToolRow.font -> FontCarousel(selection = style.face, onPick = { f -> onStyle { it.copy(face = f) } })
                ToolRow.color -> Row(
                    Modifier.fillMaxWidth().height(44.dp).horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    TextTint.entries.forEach { t ->
                        TintChip(tint = t, on = style.tint == t, accent = theme.rawAccent, onTap = { onStyle { it.copy(tint = t) } })
                    }
                }
            }
        }

        Row(
            Modifier
                .padding(horizontal = 12.dp)
                .fillMaxWidth()
                .background(Color.White.opacity(0.1), RoundedCornerShape(18.dp))
                .padding(horizontal = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            ToolIcon("textformat", on = row == ToolRow.font) { row = ToolRow.font }

            // วงสี — ตัวเดียวที่ไม่ใช่ไอคอนขาว เพราะสีคือสิ่งที่มันเปิด
            val colorSrc = remember { MutableInteractionSource() }
            Box(
                Modifier
                    .size(44.dp)
                    .background(Color.White.opacity(if (row == ToolRow.color) 0.22 else 0.0), RoundedCornerShape(10.dp))
                    .clickable(colorSrc, indication = null) {
                        row = ToolRow.color
                        Haptics.impact(Haptics.Style.light)
                    },
                contentAlignment = Alignment.Center,
            ) {
                Box(
                    Modifier
                        .size(22.dp)
                        .background(
                            Brush.sweepGradient(
                                listOf(Color.Red, Color.Yellow, Color.Green, Color.Cyan, Color.Blue, Color.Magenta, Color.Red),
                            ),
                            CircleShape,
                        )
                        .border(1.5.dp, Color.White.opacity(0.9), CircleShape),
                )
            }

            TextAlignButton(align = style.align, onPick = { a -> onStyle { it.copy(align = a) } })

            Spacer(Modifier.weight(1f, fill = false))

            // ลบก้อน — กดแล้วย่อนิดเดียว (= `DockPress`)
            val delSrc = remember { MutableInteractionSource() }
            Box(
                Modifier
                    .dockPress(delSrc)
                    .size(44.dp)
                    .clickable(delSrc, indication = null, onClick = onDelete),
                contentAlignment = Alignment.Center,
            ) {
                SFSymbol("trash", size = 16f, tint = rgb(1.0, 0.5, 0.45))
            }
        }
    }
}

/** ไอคอนหนึ่งช่องในแถวเครื่องมือ — ช่องที่ทำงานอยู่ได้พื้นสว่างเหมือน IG */
@Composable
private fun ToolIcon(symbol: String, on: Boolean, action: () -> Unit) {
    val src = remember { MutableInteractionSource() }
    Box(
        Modifier
            .size(44.dp)
            .background(Color.White.opacity(if (on) 0.9 else 0.0), RoundedCornerShape(10.dp))
            .clickable(src, indication = null) {
                action()
                Haptics.impact(Haptics.Style.light)
            },
        contentAlignment = Alignment.Center,
    ) {
        SFSymbol(symbol, size = 17f, tint = if (on) Color.Black.opacity(0.85) else Color.White.opacity(0.9))
    }
}

/** กดแล้วย่อนิดเดียว — ตอบไวด้วย `snap` ไม่มีไฮไลต์ซ้อน (= `DockPress` ใน EditorDock.swift) */
@Composable
private fun Modifier.dockPress(src: MutableInteractionSource): Modifier {
    val pressed by src.collectIsPressedAsState()
    val s by animateFloatAsState(if (pressed) 0.94f else 1f, Motion.snap.float, label = "pressScale")
    val a by animateFloatAsState(if (pressed) 0.85f else 1f, Motion.snap.float, label = "pressAlpha")
    return graphicsLayer {
        scaleX = s
        scaleY = s
        alpha = a
    }
}

// MARK: - ช่องพิมพ์บนการ์ด

/**
 * ช่องพิมพ์ที่นั่งทับตำแหน่งของก้อนข้อความบนการ์ดพอดี — ฟอนต์ สี การจัดวาง ตรงกับก้อนจริงทุกค่า
 *
 * ตัวอักษรของก้อนถูกซ่อนระหว่างพิมพ์ (ดู `LocalCanvasTyping`) ช่องนี้จึง *คือ* ตัวอักษร
 * ขนาดตัวอักษรตอนพิมพ์คือ **ขนาดแก้ไขมาตรฐาน** เท่ากันทุกก้อน ไม่ใช่ขนาดบนการ์ด
 * ไม่ตัดบรรทัดเอง — Return เท่านั้นที่ขึ้นบรรทัดใหม่ · กล่องรอบตัวโตตามที่พิมพ์
 * (`UITextView` → `BasicTextField` ไม่มีขอบใน กว้างเท่าบรรทัดที่ยาวที่สุด)
 * - size: ขนาดตัวอักษรตอนพิมพ์ — คิดมาแล้วจากชั้นการ์ด
 * - large: ก้อนนี้ **บนการ์ด** ใหญ่พอให้ใช้เกณฑ์ตัวใหญ่ไหม — สีตอนพิมพ์ต้องเป็นสีเดียวกับที่จะกลับไปวาง
 */
@Composable
fun CanvasTextField(
    id: TextSlotID,
    style: WidgetTextStyle,
    ink: InkStyle,
    accent: Color,
    size: Float,
    large: Boolean = true,
    modifier: Modifier = Modifier,
) {
    val color = style.tint.color(ink, accent, large)
    val halo = style.tint.halo(ink, large)
    val density = LocalDensity.current

    // ประโยคชวนพิมพ์บนการ์ดไม่ใช่ข้อความของผู้ใช้ — ช่องพิมพ์ต้องเห็นเป็นช่องว่าง
    val v = Profile.me.text(id)
    val raw = if (v == Profile.notePlaceholder) "" else v

    val textStyle = style.face.font(size, TextBlockWeight)
        .copy(
            color = color,
            textAlign = style.align.text,
            lineHeight = (size * LineBox + size * TextFit.spacing).sp,
        )
        .legibilityHalo(halo, size, density.density)

    val focus = remember { FocusRequester() }
    val keyboard = LocalSoftwareKeyboardController.current
    // ขอแป้นพิมพ์ทันทีที่ได้อยู่ในต้นไม้ (= `FocusTextView.didMoveToWindow`)
    LaunchedEffect(Unit) {
        withFrameNanos { }
        runCatching { focus.requestFocus() }
        keyboard?.show()
    }

    BasicTextField(
        value = raw,
        onValueChange = { Profile.me.set(id, it) },
        textStyle = textStyle,
        cursorBrush = SolidColor(accent),
        singleLine = false,
        keyboardOptions = KeyboardOptions(
            capitalization = KeyboardCapitalization.Sentences,
            autoCorrectEnabled = false,
            imeAction = ImeAction.Default,
        ),
        // ไม่ตัดบรรทัดเอง — กล่องกว้างเท่าบรรทัดที่ยาวที่สุดอยู่แล้ว วัดตัวเองแบบไม่จำกัดความกว้าง
        modifier = modifier.wrapContentSize(Alignment.TopStart, unbounded = true).focusRequester(focus),
        decorationBox = { inner ->
            Box(contentAlignment = Alignment.TopStart) {
                if (raw.isEmpty()) {
                    Text(
                        "พิมพ์ข้อความ",
                        style = style.face.font(size, TextBlockWeight),
                        color = color.opacity(0.45),
                        maxLines = 1, softWrap = false,
                    )
                }
                inner()
            }
        },
    )
}

// MARK: - ชิ้นส่วน

/**
 * แถวฟอนต์แบบ IG — **เลื่อนแล้วเปลี่ยนเลย** ตัวที่หยุดอยู่กลางจอคือตัวที่ใช้ ไม่ต้องแตะ
 * ใบที่อยู่ตรงกลางถูกส่งออกไปเป็นฟอนต์ของก้อนทันทีระหว่างเลื่อน · แตะใบไหนก็ได้: ใบนั้นเลื่อนมาอยู่กลางเอง
 */
@Composable
fun FontCarousel(selection: CardFont, onPick: (CardFont) -> Unit, modifier: Modifier = Modifier) {
    val fonts = CardFont.entries
    val state = rememberLazyListState()
    val scope = rememberCoroutineScope()
    val fling = rememberSnapFlingBehavior(state, SnapPosition.Center)

    BoxWithConstraints(modifier.fillMaxWidth().height(44.dp)) {
        // เว้นขอบครึ่งจอ — ใบแรกกับใบสุดท้ายต้องมาอยู่กลางจอได้เหมือนใบอื่น
        val side = max(0f, maxWidth.value / 2f - 52f)
        // ใบที่อยู่กลางจอตอนนี้ — ตัวขับหลัก ทั้งจากการเลื่อนและจากการแตะ
        val centered by remember {
            derivedStateOf {
                val info = state.layoutInfo
                val c = (info.viewportStartOffset + info.viewportEndOffset) / 2
                info.visibleItemsInfo.minByOrNull { abs(it.offset + it.size / 2 - c) }?.index
            }
        }
        LaunchedEffect(centered) {
            val i = centered ?: return@LaunchedEffect
            val f = fonts[i]
            if (f != selection) onPick(f)
        }
        LaunchedEffect(selection) {
            if (centered != selection.ordinal && !state.isScrollInProgress) state.centerOn(selection.ordinal, animate = centered != null)
        }
        LazyRow(
            state = state,
            flingBehavior = fling,
            contentPadding = PaddingValues(horizontal = side.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxSize(),
        ) {
            itemsIndexed(fonts, key = { _, f -> f.name }) { i, f ->
                FontChip(font = f, on = f == selection, action = {
                    scope.launch { state.centerOn(i, animate = true) }
                })
            }
        }
    }
}

/** เลื่อนให้ใบที่ `index` มาอยู่กลางช่องมอง */
private suspend fun LazyListState.centerOn(index: Int, animate: Boolean) {
    fun delta(): Float? {
        val info = layoutInfo
        val item = info.visibleItemsInfo.firstOrNull { it.index == index } ?: return null
        val c = (info.viewportStartOffset + info.viewportEndOffset) / 2f
        return item.offset + item.size / 2f - c
    }
    var d = delta()
    if (d == null) {
        scrollToItem(index)
        d = delta() ?: return
    }
    if (animate) animateScrollBy(d, Motion.snap.float) else scrollBy(d)
}

/**
 * ชิปฟอนต์ — **ชื่อฟอนต์เขียนด้วยฟอนต์นั้นเอง** (Modern · Classic · Signature ของ IG)
 * ตัวที่เลือกเป็นพื้นขาวตัวดำ ที่เหลือโปร่งมีขอบบาง ๆ
 */
@Composable
fun FontChip(font: CardFont, on: Boolean, action: () -> Unit, modifier: Modifier = Modifier) {
    val fg by animateColorAsState(if (on) Color.Black.opacity(0.88) else Color.White.opacity(0.92), Motion.snap.spec(), label = "fg")
    val bg by animateColorAsState(if (on) Color.White.opacity(0.95) else Color.White.opacity(0.08), Motion.snap.spec(), label = "bg")
    val rim by animateColorAsState(Color.White.opacity(if (on) 0.0 else 0.22), Motion.snap.spec(), label = "rim")
    val src = remember { MutableInteractionSource() }
    Box(
        modifier
            .height(38.dp)
            .clip(CircleShape)
            .background(bg)
            .border(0.8.dp, rim, CircleShape)
            .clickable(src, indication = null) {
                action()
                Haptics.impact(Haptics.Style.light)
            }
            .padding(horizontal = 16.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(font.displayName, style = font.font(15f, SHFont.semibold), color = fg, maxLines = 1, softWrap = false)
    }
}

/**
 * วงสีตัวอักษร — สามตัวแรกไม่มีสีของตัวเอง (ตามการ์ด) จึงเป็นชิปมีชื่อ ที่เหลือเป็นวงสี
 * วงกลมขาวสองใบที่แปลว่าคนละอย่างเป็นตัวเลือกที่เดาไม่ออกว่าต่างกันตรงไหน
 */
@Composable
fun TintChip(tint: TextTint, on: Boolean, accent: Color, onTap: () -> Unit, modifier: Modifier = Modifier) {
    val src = remember { MutableInteractionSource() }
    val click = Modifier.clickable(src, indication = null) {
        onTap()
        Haptics.impact(Haptics.Style.light)
    }
    if (tint == TextTint.ink || tint == TextTint.soft || tint == TextTint.accent) {
        val fg by animateColorAsState(if (on) Color.Black.opacity(0.88) else Color.White.opacity(0.9), Motion.snap.spec(), label = "fg")
        val bg by animateColorAsState(if (on) Color.White.opacity(0.95) else Color.White.opacity(0.08), Motion.snap.spec(), label = "bg")
        val rim by animateColorAsState(Color.White.opacity(if (on) 0.0 else 0.22), Motion.snap.spec(), label = "rim")
        Box(
            modifier
                .height(36.dp)
                .clip(CircleShape)
                .background(bg)
                .border(0.8.dp, rim, CircleShape)
                .then(click)
                .padding(horizontal = 14.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(tint.displayName, style = sh(12f, SHFont.semibold), color = fg, maxLines = 1, softWrap = false)
        }
    } else {
        val ring by animateColorAsState(Color.White.opacity(if (on) 1.0 else 0.35), Motion.snap.spec(), label = "ring")
        val width by animateFloatAsState(if (on) 3f else 1f, Motion.snap.float, label = "ringWidth")
        val scale by animateFloatAsState(if (on) 1.1f else 1f, Motion.snap.float, label = "scale")
        Box(modifier.size(38.dp).then(click), contentAlignment = Alignment.Center) {
            Box(
                Modifier
                    .size(30.dp)
                    .graphicsLayer {
                        scaleX = scale
                        scaleY = scale
                    }
                    .background(tint.swatch(accent), CircleShape)
                    .border(width.dp, ring, CircleShape),
            )
        }
    }
}

/** จัดวางวนสามแบบในไอคอนเดียว — ไอคอนคือสถานะปัจจุบัน (ท่าเดียวกับปุ่มจัดวางของ IG) */
@Composable
fun TextAlignButton(align: TextAlignment, onPick: (TextAlignment) -> Unit, modifier: Modifier = Modifier) {
    val src = remember { MutableInteractionSource() }
    Box(
        modifier
            .size(44.dp)
            .clickable(src, indication = null) {
                val all = TextAlignment.entries
                val i = all.indexOf(align).let { if (it < 0) 0 else it }
                onPick(all[(i + 1) % all.size])
                Haptics.impact(Haptics.Style.light)
            },
        contentAlignment = Alignment.Center,
    ) {
        SFSymbol(align.icon, size = 17f, tint = Color.White.opacity(0.9))
    }
}
