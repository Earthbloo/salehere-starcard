package co.salehere.starcard.ui.editor

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.GlassPanel
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.redacted
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.RGB
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.TextTint
import co.salehere.starcard.theme.WidgetTextSize
import co.salehere.starcard.theme.WidgetTextStyle
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalGhostData
import co.salehere.starcard.ui.LocalSlotTilt
import co.salehere.starcard.ui.LocalTextEditMode
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.widgets.contactURL
import co.salehere.starcard.ui.widgets.linkSlot
import java.util.UUID
import kotlin.math.max

// MARK: - ข้อความที่แก้ได้บนตัว widget เอง (= Views/Editor/EditableText.swift)
//
// # ทำไมไม่เป็นช่องกรอกในชีตล่าง
// ชีตกรอกฟอร์มทำให้ต้องมองสองที่พร้อมกัน — แก้ที่ตัวมันเลยจึงตอบได้ในจังหวะเดียว:
// ตัวอักษรที่พิมพ์อยู่ *คือ* ตัวอักษรที่จะพิมพ์ออกมา · เส้นประบอกว่าอันไหนแตะได้
//
// # กติกาของความยาว
// ข้อความยาวเกินกรอบ **ตัดด้วย …** ไม่ใช่ดัน widget ให้สูงขึ้น — อยากเห็นครบก็ยืดกรอบเอง
//
// # ทำไมช่องพิมพ์ไปวาดที่ชั้นการ์ด ไม่ใช่ในตัว widget
// เนื้อหา widget ไม่รับทัช ตัว widget จึงประกาศ *กรอบ* ของช่องขึ้นไป (ดู `SlotRegistry`)
// แล้วชั้นการ์ดเอากรอบนั้นไปวางของจริงทับ

/** สัดส่วนกล่องบรรทัดของฟอนต์ไทย (ascent+descent ต่อ em ของ NotoSansThai ≈ 1.36) — ใช้แปลง `lineSpacing` เป็น `lineHeight` */
internal const val LineBox = 1.36f

/** ที่จำค่าล่าสุดของ modifier ที่ประกาศกรอบ — เอาไว้ถอนกรอบเก่าออกจากทะเบียนเมื่อขยับหรือหลุดจากต้นไม้ */
class SlotMemo<T> {
    var value: T? = null
}

// MARK: - สไตล์ที่ส่งขึ้นไปให้ช่องพิมพ์

/**
 * หน้าตาของข้อความช่องหนึ่ง — ส่งขึ้นไปให้ช่องพิมพ์วาดตัวอักษรให้ตรงกับที่เห็นบนการ์ด
 * เก็บเป็น `size` + `weight` + `face` ไม่ใช่ `TextStyle` สำเร็จรูป — ทั้งการ์ดและช่องพิมพ์ประกอบจากแหล่งเดียว
 */
data class TextSlotStyle(
    var size: Float = 14f,
    var weight: FontWeight = SHFont.regular,
    /** ฟอนต์ของช่องนี้ — อยู่ในสไตล์ไม่ใช่ในตัว widget เพราะช่องพิมพ์เหนือคีย์บอร์ดต้องใช้หน้าตาเดียวกัน */
    var face: CardFont = CardFont.noto,
    var color: Color = Color.White,
    var align: TextAlign = TextAlign.Start,
    var tracking: Float = 0f,
    var lineSpacing: Float = 0f,
    /** ข้อความบนการ์ดแสดงเป็นตัวใหญ่ แต่ค่าที่เก็บเป็นตัวเดิม — ตอนพิมพ์จึงเห็นค่าจริง */
    var uppercase: Boolean = false,
    /** มุมของกรอบเส้นประ — ชิปใช้ค่าสูงให้โค้งตามแคปซูล */
    var corner: Float = 4f,
    /** ตัวเอียง — อยู่ในสไตล์ ไม่ใช่ที่ตัว `Text` เพราะช่องพิมพ์ต้องเห็นหน้าตาเดียวกัน */
    var italic: Boolean = false,
    /** ตัวอักษรถูกแปะเอียงไปกี่องศา — เส้นประต้องเอียงตาม · ใส่ให้เองจาก `LocalSlotTilt` */
    var tilt: Double = 0.0,
) {
    /** `TextStyle` ของช่องนี้ — ฟอนต์ · ตัวเอียง · ช่องไฟ · ระยะบรรทัด · การจัดวาง (สีใส่ที่ `Text` ต่างหาก) */
    val textStyle: TextStyle
        get() {
            var s = face.font(size, weight)
            if (italic) s = s.copy(fontStyle = FontStyle.Italic)
            s = s.copy(letterSpacing = tracking.sp, textAlign = align)
            // `.lineSpacing(x)` ของ SwiftUI = กล่องบรรทัดธรรมชาติ + x — Compose มีแต่ lineHeight รวม
            if (lineSpacing != 0f) s = s.copy(lineHeight = (size * LineBox + lineSpacing).sp)
            return s
        }

    /**
     * สไตล์เดียวกันหลังผ่าน **ฟอนต์ · สี · ขนาด ที่เจ้าของการ์ดตั้งให้ช่องนี้** (ดู `WidgetTextStyle`)
     * ค่าที่ดีไซน์เขียนไว้คือ *ค่าอ้างอิง* — ช่องที่ถูกสั่งทับเปลี่ยนเฉพาะสิ่งที่สั่ง
     * - ink: หมึกของพื้นที่ช่องนี้นั่งอยู่จริง — สีที่เลือกถูกยันให้อ่านออกบนพื้นนั้น
     */
    fun tuned(by: WidgetTextStyle, slot: TextSlotID, ink: InkStyle, accent: Color): TextSlotStyle {
        val s = copy()
        val f = slot.field
        val i = slot.index
        s.size = by.scaled(size, f, i)
        by.face(f, i)?.let { s.face = it }
        by.tint(f, i)?.let { tint -> s.color = tint.color(ink, accent, large = s.size >= 20f) }
        return s
    }
}

// MARK: - กรอบของช่อง ส่งขึ้นไปให้ชั้นการ์ด (PORTING §6)

data class PhotoSlotRect(val index: Int, val rect: Rect)
data class LinkSlotRect(val url: String, val rect: Rect)
/** กรอบที่แปลงเป็นพิกัดหน้าแล้ว — ชั้นการ์ดใช้ทั้งวางช่องพิมพ์และเช็คว่านิ้วแตะโดนช่องไหน */
data class TextSlotRect(val id: TextSlotID, val rect: Rect, val style: TextSlotStyle)

/**
 * ทะเบียนกรอบของทุก widget บนหน้า — หนึ่งตัวต่อหน้าของ `CardScreen`
 *
 * เป็นคลาสธรรมดา ไม่ใช่ observable โดยตั้งใจ — ค่านี้ถูกเขียนใหม่ทุกครั้งที่ผังขยับ
 * แต่ไม่มีใครอ่านมันตอนวาด มีแต่ตอนนิ้วแตะ ถ้าให้มันสั่งวาดใหม่จะกลายเป็นวงวน
 * กรอบทุกอันเก็บเป็น **หน่วยออกแบบของหน้า** (ดู `toPage`)
 */
class SlotRegistry {
    /** หน่วยออกแบบของหน้า → พิกเซลของราก — `CardScreen` ตั้งทุกครั้งที่จัดผัง */
    var scale = 1f
    /** ตำแหน่ง (พิกเซลของราก) ของมุมบนซ้ายของหน้า */
    var origin = Offset.Zero
    val text = mutableMapOf<UUID, MutableList<TextSlotRect>>()
    val links = mutableMapOf<UUID, MutableList<LinkSlotRect>>()
    val photos = mutableMapOf<UUID, MutableList<PhotoSlotRect>>()

    /** (rootRect - origin) / scale */
    fun toPage(rootRect: Rect): Rect {
        val s = if (scale > 0f) scale else 1f
        return Rect(
            (rootRect.left - origin.x) / s,
            (rootRect.top - origin.y) / s,
            (rootRect.right - origin.x) / s,
            (rootRect.bottom - origin.y) / s,
        )
    }

    /** แทนที่รายการที่ id เดียวกัน */
    fun reportText(widget: UUID, slot: TextSlotRect) {
        val l = text.getOrPut(widget) { mutableListOf() }
        val i = l.indexOfFirst { it.id == slot.id }
        if (i >= 0) l[i] = slot else l.add(slot)
    }

    /** แทนที่รายการที่ url+rect เดียวกัน */
    fun reportLink(widget: UUID, slot: LinkSlotRect) {
        val l = links.getOrPut(widget) { mutableListOf() }
        val i = l.indexOfFirst { it.url == slot.url && it.rect == slot.rect }
        if (i >= 0) l[i] = slot else l.add(slot)
    }

    /** แทนที่รายการที่ index เดียวกัน */
    fun reportPhoto(widget: UUID, slot: PhotoSlotRect) {
        val l = photos.getOrPut(widget) { mutableListOf() }
        val i = l.indexOfFirst { it.index == slot.index }
        if (i >= 0) l[i] = slot else l.add(slot)
    }

    /**
     * ช่องที่นิ้วแตะโดน — เผื่อขอบรอบละ 6pt เพราะบรรทัดบาง ๆ อย่างสายงานสูงไม่ถึงนิ้ว
     * ไล่จากช่องท้ายลิสต์ขึ้นมา — ช่องที่ประกาศทีหลังอยู่ชั้นบนกว่าเมื่อกรอบซ้อนกัน
     */
    fun hitText(point: Offset, widget: UUID): TextSlotRect? =
        text[widget]?.lastOrNull { it.rect.inflate(6f).contains(point) }

    /** ลิงก์ที่นิ้วแตะโดน — ไล่จากท้ายลิสต์ขึ้นมา */
    fun hitLink(point: Offset, widget: UUID): String? =
        links[widget]?.lastOrNull { it.rect.contains(point) }?.url
}

val LocalSlotRegistry = staticCompositionLocalOf<SlotRegistry?> { null }

// MARK: - เส้นประ · แท่งว่าง

/**
 * กรอบเส้นประของช่องหนึ่งช่อง — วาดที่ชั้นการ์ด ไม่ใช่ในตัว widget
 * ขึ้นมาวาดที่ชั้นนี้แล้วไม่มีหน้ากากของท่าเปลี่ยนหน้ามาตัด — และได้อยู่เหนือเนื้อหา widget ด้วย
 */
@Composable
fun TextSlotDashes(style: TextSlotStyle, accent: Color, modifier: Modifier = Modifier) {
    val color = accent.opacity(0.7)
    Box(
        modifier.fillMaxSize().drawBehind {
            val sw = 0.9.dp.toPx()
            val r = (style.corner + 2f).dp.toPx()
            drawRoundRect(
                color,
                topLeft = Offset(sw / 2f, sw / 2f),
                size = Size(size.width - sw, size.height - sw),
                cornerRadius = CornerRadius(r, r),
                style = Stroke(width = sw, pathEffect = PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(), 2.6.dp.toPx()))),
            )
        },
    )
}

/**
 * ประกาศว่าตัวหนังสือก้อนนี้คือ "ค่าข้อมูลของผู้ใช้" (ยอดฟอล · % · ราคา) ไม่ใช่ป้ายของดีไซน์
 * ในโหมดพรีวิวไม่มีข้อมูล ก้อนนี้กลายเป็นแท่งว่าง ส่วนป้ายรอบ ๆ ยังอ่านออก
 */
fun Modifier.dataValue(): Modifier = composed {
    val ghost = LocalGhostData.current
    Modifier.redacted(ghost)
}

// MARK: - ตัวประกาศว่า "ข้อความก้อนนี้แก้ได้" (PORTING §11)

/**
 * ประกาศกรอบของช่อง `id` กับชั้นการ์ด (เฉพาะโหมดแต่ง) และติดลิงก์ติดต่อให้ในโหมดดู
 *
 * ใช้กับข้อความที่วาดเองไม่ผ่าน `EditableText` (ตัวอักษรไล่เฉด · ป้ายไฟ) — **ไม่ปรับสไตล์ให้**
 * ส่งสไตล์ที่ผ่าน `tuned` มาแล้ว (เหมือนที่ `EditableText` ทำ) ถ้าอยากให้เส้นประ/แถบพิมพ์ตรงกับที่วาด
 */
fun Modifier.editableSlot(id: TextSlotID, style: TextSlotStyle): Modifier = composed {
    val editMode = LocalTextEditMode.current
    val reg = LocalSlotRegistry.current
    val wid = LocalWidgetID.current
    // เบอร์ · อีเมล · ไลน์ · ชื่อ กดแล้วติดต่อได้ในโหมดดู — แถวที่ประกาศ `linkSlot` ไว้ข้างนอกชนะค่านี้
    val link = if (editMode) null else id.field.contactURL
    var m: Modifier = Modifier
    if (editMode && reg != null && wid != null) {
        DisposableEffect(reg, wid, id) {
            onDispose { reg.text[wid]?.removeAll { it.id == id } }
        }
        m = m.onGloballyPositioned { c ->
            reg.reportText(wid, TextSlotRect(id, reg.toPage(c.boundsInRoot()), style))
        }
    }
    m.linkSlot(link)
}

/**
 * ช่องข้อความหนึ่งช่องบนการ์ด — ฟอนต์กับสีของช่องถูก "ใส่ให้" ที่นี่ ไม่ใช่ที่ตัว `Text`
 *
 * ตัวประกาศช่องรู้สองอย่าง: สไตล์ที่ดีไซน์ตั้งไว้ (`style`) และ **ฟอนต์/สี/ขนาดที่เจ้าของการ์ดตั้งให้ช่องนี้**
 * (จาก `LocalWidgetTextStyle`) — ช่องทุกช่องในตู้จึงปรับได้ด้วยโค้ดที่เดียว
 * สีที่ใส่คือ **สีของสไตล์** เสมอ: ยังไม่เลือก = ได้สีของดีไซน์ · เลือกแล้ว = ได้สีที่เลือก
 * - preset: ข้อความตั้งต้นที่ดีไซน์ใส่มา (เฉพาะช่องอิสระ `note`)
 * - hint: ชื่อช่องบนแถบพิมพ์ เมื่อชิ้นเดียวมีช่องอิสระหลายช่อง
 * - text: ข้อความที่จะวาด — ค่าเริ่มต้นคือ `Profile.me.text(id)`
 * - autoSizeMin: `.minimumScaleFactor` (0…1)
 */
@Composable
fun EditableText(
    field: ProfileField,
    index: Int? = null,
    widget: UUID? = null,
    preset: String = "",
    hint: String? = null,
    style: TextSlotStyle,
    text: String? = null,
    modifier: Modifier = Modifier,
    maxLines: Int = 1,
    softWrap: Boolean = false,
    autoSizeMin: Float? = null,
    textAlign: TextAlign? = null,
) {
    val id = TextSlotID(field = field, index = index, widget = widget, preset = preset, hint = hint)
    val tune = LocalWidgetTextStyle.current
    val ink = LocalCardInk.current
    val accent = LocalCardAccent.current
    val tilt = LocalSlotTilt.current
    val ghost = LocalGhostData.current
    val slotStyle = style.tuned(tune, id, ink, accent)
    slotStyle.tilt = tilt

    // ตัวอักษรบนการ์ดไม่ถูกซ่อนตอนพิมพ์ — มันคือตัวพรีวิว ต้องวิ่งตามที่พิมพ์บนแถบล่างสด ๆ
    val value = text ?: Profile.me.text(id)
    val shown = if (slotStyle.uppercase) value.uppercase() else value
    var ts = slotStyle.textStyle
    if (textAlign != null) ts = ts.copy(textAlign = textAlign)
    val autoSize = autoSizeMin?.let {
        TextAutoSize.StepBased(
            minFontSize = (slotStyle.size * it.coerceIn(0.05f, 1f)).sp,
            maxFontSize = slotStyle.size.sp,
            stepSize = 0.5.sp,
        )
    }
    // แท่งว่างของโหมดไม่มีข้อมูลต้องเป็นสีของช่อง ไม่ใช่สีระบบ
    CompositionLocalProvider(LocalContentColor provides slotStyle.color) {
        Text(
            shown,
            style = ts,
            color = slotStyle.color,
            maxLines = maxLines,
            softWrap = softWrap,
            overflow = TextOverflow.Ellipsis,
            autoSize = autoSize,
            modifier = modifier
                .editableSlot(id, slotStyle)
                // ช่องแก้ได้ทุกช่องคือข้อมูลของผู้ใช้ — พรีวิว "ไม่มีข้อมูล" ทำให้เป็นแท่งว่างเท่าตัวอักษร
                .redacted(ghost),
        )
    }
}

// MARK: - ย่อหน้าที่ตัดตามความสูงที่มีจริง

/**
 * ย่อหน้าแนะนำตัว/คำพูด — จำนวนบรรทัดคำนวณจากความสูงที่เหลือ แล้วตัดท้ายด้วย …
 * **กรอบเป็นคนกำหนดว่าอ่านได้กี่บรรทัด** อยากอ่านครบก็ยืดกรอบ
 * - reserve: เว้นที่ไว้ท้ายย่อหน้าเผื่อของที่ต้องอยู่ใต้มัน — หักออกก่อนคำนวณจำนวนบรรทัด
 * - widget: ชิ้นที่ย่อหน้านี้สังกัด — ใส่เฉพาะช่องที่เก็บต่อชิ้น (`note`)
 * - anchor: กรอบที่ย่อหน้าเกาะ — ตัวอักษรที่จัดกลาง/ชิดขวาต้องเกาะกรอบด้านนั้นด้วย
 */
@Composable
fun EditableParagraph(
    field: ProfileField,
    style: TextSlotStyle,
    reserve: Float = 0f,
    widget: UUID? = null,
    anchor: Alignment = Alignment.TopStart,
    modifier: Modifier = Modifier,
) {
    val tune = LocalWidgetTextStyle.current
    val ink = LocalCardInk.current
    val accent = LocalCardAccent.current
    val id = TextSlotID(field = field, widget = widget)
    // ย่อหน้าต้องรู้ความสูงบรรทัดก่อนวาด จึงปรับสไตล์ตรงนี้ด้วย (ตัวประกาศช่องปรับให้อีกชั้นตอนวาดจริง)
    val tuned = style.tuned(tune, id, ink, accent)
    val measurer = rememberTextMeasurer()
    val density = LocalDensity.current
    val lineStyle = tuned.textStyle
    // ความสูงของบรรทัดหนึ่งบรรทัดตามที่จะวาดจริง (รวมระยะบรรทัดแล้ว) — วัดด้วยสระบน/ล่างไทยให้เผื่อครบ
    val step = remember(lineStyle, density) {
        with(density) { measurer.measure(AnnotatedString("ป้ๅ"), style = lineStyle, maxLines = 1).size.height.toDp().value }
    }
    BoxWithConstraints(modifier.fillMaxSize(), contentAlignment = anchor) {
        val room = max(0f, maxHeight.value - reserve)
        val lines = max(1, (room / max(step, 1f)).toInt())
        // ส่ง **สไตล์ของดีไซน์** เข้าไป ไม่ใช่ตัวที่ปรับแล้ว — ตัวประกาศช่องปรับให้เองอีกชั้น
        EditableText(
            field = field,
            widget = widget,
            style = style,
            maxLines = lines,
            softWrap = true,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

// MARK: - แถบพิมพ์เหนือคีย์บอร์ด

private enum class EditTool { font, color, size }

/**
 * ช่องกรอกที่ลอยอยู่เหนือคีย์บอร์ด — ที่เดียวที่พิมพ์ได้
 *
 * ตัวอักษรบนการ์ดเล็กมาก (สายงาน 8.5pt) วางเคอร์เซอร์ไม่ได้จริง และคีย์บอร์ดบังของที่กำลังพิมพ์ —
 * แถบนี้อยู่ที่เดิมเสมอ ขนาดอ่านออก มีชื่อช่องกำกับ · ส่วนตัวอักษรบนการ์ดอัปเดตสดตามที่พิมพ์
 * - style: หน้าตาที่ช่องนี้ใช้อยู่ตอนนี้ (ของชิ้นที่ถูกเลือก) — `null` เมื่อยังหาชิ้นไม่เจอ
 * - onStyle: เปลี่ยนหน้าตาของชิ้น — `null` = ไม่มีเครื่องมือฟอนต์/สี/ขนาด
 */
@Composable
fun TextEditBar(
    id: TextSlotID,
    theme: CardTheme,
    style: WidgetTextStyle? = null,
    onStyle: (((WidgetTextStyle) -> WidgetTextStyle) -> Unit)? = null,
    onDone: () -> Unit,
    modifier: Modifier = Modifier,
) {
    // แถวเครื่องมือที่กางอยู่ — null = ยังไม่กาง (แถบบางที่สุด เห็นการ์ดมากที่สุด) · ท่าเดียวกับ IG
    var tool by remember { mutableStateOf<EditTool?>(null) }
    // แถวสุดท้ายที่เคยกาง — ให้ท่าหุบยังวาดแถวเดิมอยู่ระหว่างหายไป (ไม่ใช่ state จึงไม่สั่งวาดซ้ำ)
    val lastTool = remember { arrayOf(EditTool.font) }
    val shownTool = tool ?: lastTool[0]
    SideEffect { tool?.let { lastTool[0] = it } }

    val field = id.field
    val value = Profile.me.text(id)
    // ชื่อช่องบนหัวแถบ — ชิ้นที่มีข้อความอิสระหลายก้อนต้องบอกว่ากำลังแก้ก้อนไหน
    val label = id.hint ?: field.label

    val slotFace = style?.face(id.field, id.index)
    val slotTint = style?.tint(id.field, id.index)
    val slotSize = style?.size(id.field, id.index) ?: WidgetTextSize.m

    // เปลี่ยนหน้าตาของ **ช่องนี้ช่องเดียว** — คีย์มาจากฟิลด์+ลำดับของช่องที่กำลังแก้
    val set: ((WidgetTextStyle, String) -> WidgetTextStyle) -> Unit = { change ->
        if (onStyle != null) {
            val key = WidgetTextStyle.slotKey(id.field, id.index)
            onStyle { s -> change(s, key) }
            Haptics.impact(Haptics.Style.light)
        }
    }

    Column(modifier, verticalArrangement = Arrangement.spacedBy(10.dp)) {
        AnimatedVisibility(
            visible = onStyle != null && tool != null,
            enter = fadeIn(Motion.snap.spec()) + expandVertically(Motion.snap.spec()),
            exit = fadeOut(Motion.snap.spec()) + shrinkVertically(Motion.snap.spec()),
        ) {
            EditToolPicker(shownTool, theme, slotFace, slotTint, slotSize, set)
        }
        EditBarPanel(id, theme, field, value, label, onStyle != null, tool, { tool = it }, onDone)
    }
}

/** แถวเครื่องมือที่กางอยู่ — ฟอนต์เลื่อนได้ · สีเลื่อนได้ · ขนาดหกขั้น */
@Composable
private fun EditToolPicker(
    tool: EditTool,
    theme: CardTheme,
    slotFace: CardFont?,
    slotTint: TextTint?,
    slotSize: WidgetTextSize,
    set: ((WidgetTextStyle, String) -> WidgetTextStyle) -> Unit,
) {
    when (tool) {
        EditTool.font -> FontCarousel(selection = slotFace ?: CardFont.noto, onPick = { f ->
            set { s, k -> s.copy(slotFaces = (s.slotFaces + (k to f)).toMutableMap()) }
        })
        EditTool.color -> Row(
            Modifier.fillMaxWidth().height(44.dp).horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // ใบแรกคือทางกลับ — สีที่ดีไซน์เลือกไว้ · ไม่มีใบนี้ คนที่เผลอกดสีจะหาของเดิมไม่เจออีกเลย
            AutoChip(on = slotTint == null) { set { s, k -> s.copy(slotTints = (s.slotTints - k).toMutableMap()) } }
            TextTint.entries.forEach { t ->
                TintChip(tint = t, on = slotTint == t, accent = theme.rawAccent, onTap = {
                    set { s, k -> s.copy(slotTints = (s.slotTints + (k to t)).toMutableMap()) }
                })
            }
        }
        EditTool.size -> Row(
            Modifier.fillMaxWidth().height(44.dp).horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            WidgetTextSize.entries.forEach { v ->
                SizeChip(v, on = slotSize == v) { set { s, k -> s.copy(slotSizes = (s.slotSizes + (k to v)).toMutableMap()) } }
            }
        }
    }
}

@Composable
private fun AutoChip(on: Boolean, action: () -> Unit) {
    val src = remember { MutableInteractionSource() }
    Box(
        Modifier
            .height(36.dp)
            .background(if (on) Color.White.opacity(0.95) else Color.White.opacity(0.08), CircleShape)
            .border(0.8.dp, Color.White.opacity(if (on) 0.0 else 0.22), CircleShape)
            .clickable(src, indication = null, onClick = action)
            .padding(horizontal = 14.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text("ตามดีไซน์", style = sh(12f, SHFont.semibold),
            color = if (on) Color.Black.opacity(0.88) else Color.White.opacity(0.9), maxLines = 1, softWrap = false)
    }
}

@Composable
private fun SizeChip(v: WidgetTextSize, on: Boolean, action: () -> Unit) {
    val src = remember { MutableInteractionSource() }
    Box(
        Modifier
            .height(36.dp)
            .widthIn(min = 40.dp)
            .background(if (on) Color.White.opacity(0.95) else Color.White.opacity(0.08), CircleShape)
            .border(0.8.dp, Color.White.opacity(if (on) 0.0 else 0.22), CircleShape)
            .clickable(src, indication = null, onClick = action),
        contentAlignment = Alignment.Center,
    ) {
        Text(v.label, style = sh(12f, SHFont.bold),
            color = if (on) Color.Black.opacity(0.88) else Color.White.opacity(0.9), maxLines = 1, softWrap = false)
    }
}

/** ปุ่มกางเครื่องมือหนึ่งตัว — กดซ้ำที่ตัวเดิมคือหุบ (แป้นพิมพ์ไม่หุบตาม) */
@Composable
private fun ToolButton(t: EditTool, symbol: String, on: Boolean, primary: Color, onToggle: (EditTool) -> Unit) {
    val src = remember { MutableInteractionSource() }
    Box(
        Modifier
            .size(34.dp, 30.dp)
            .background(if (on) Color.White.opacity(0.92) else Color.Transparent, RoundedCornerShape(9.dp))
            .clickable(src, indication = null) {
                onToggle(t)
                Haptics.impact(Haptics.Style.light)
            },
        contentAlignment = Alignment.Center,
    ) {
        SFSymbol(symbol, size = 15f, tint = if (on) Color.Black.opacity(0.85) else primary.opacity(0.65))
    }
}

/**
 * แผ่นลอย ไม่ใช่แถบเต็มความกว้าง — แถบที่ชนขอบจอทั้งสามด้านอ่านเป็น "ส่วนหนึ่งของคีย์บอร์ด" ซึ่งผิด
 * แผ่นที่มีระยะขอบรอบตัวและมุมโค้งอ่านเป็น "เครื่องมือที่ลอยขึ้นมา" · กระจกตัวเดียวกับปุ่มบนแถบบน
 */
@Composable
private fun EditBarPanel(
    id: TextSlotID,
    theme: CardTheme,
    field: ProfileField,
    value: String,
    label: String,
    hasTools: Boolean,
    tool: EditTool?,
    onTool: (EditTool?) -> Unit,
    onDone: () -> Unit,
) {
    val light = theme.inkStyle.isLight
    val primary = if (light) Color.Black.opacity(0.9) else Color.White
    val secondary = primary.opacity(0.6)
    val onAccent = if (RGB(theme.accent).luminance > 0.45) Color.Black.opacity(0.88) else Color.White
    val shape = RoundedCornerShape(26.dp)
    val focus = remember { FocusRequester() }
    val keyboard = LocalSoftwareKeyboardController.current
    val density = LocalDensity.current
    val limit = field.limit

    // โฟกัสหลังแผ่นเข้าลำดับชั้นแล้ว — สั่งในเฟรมเดียวกับที่มันเพิ่งเกิดจะไม่ติด
    LaunchedEffect(Unit) {
        withFrameNanos { }
        runCatching { focus.requestFocus() }
        keyboard?.show()
    }

    var drag by remember { mutableStateOf(0f) }
    GlassPanel(
        radius = 26f,
        // ม่านบางใต้เนื้อหา — กระจกใสล้วนทำให้ตัวหนังสือจมเวลาลอยอยู่บนรูปพื้นหลัง
        veil = if (light) Color.White.opacity(0.5) else Color.Black.opacity(0.22),
        modifier = Modifier
            .padding(start = 12.dp, end = 12.dp, bottom = 10.dp)
            .shadow(18.dp, shape, clip = false, ambientColor = Color.Black.opacity(0.32), spotColor = Color.Black.opacity(0.32))
            // ปัดลงบนแผ่นเพื่อปิด — ท่าที่มือไปถึงง่ายที่สุดขณะพิมพ์
            .pointerInput(Unit) {
                detectVerticalDragGestures(
                    onDragStart = { drag = 0f },
                    onDragEnd = { if (drag > 18f * density.density) onDone() },
                    onVerticalDrag = { _, dy -> drag += dy },
                )
            },
    ) {
        Row(
            Modifier.padding(start = 16.dp, end = 7.dp, top = 8.dp, bottom = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(label, style = sh(9.5f, SHFont.semibold), color = theme.accent, maxLines = 1, softWrap = false)
                    if (limit != null) {
                        // เหลืออีกกี่ตัว — ต้องเห็นก่อนพิมพ์ชน ไม่ใช่ตอนพิมพ์แล้วตัวหาย
                        Text(
                            "${value.length}/$limit",
                            style = sh(9f, SHFont.medium),
                            color = secondary.opacity(if (value.length >= limit) 1.0 else 0.6),
                            maxLines = 1, softWrap = false,
                        )
                    }
                    Spacer(Modifier.weight(1f, fill = false))
                    if (hasTools) {
                        ToolButton(EditTool.font, "textformat", tool == EditTool.font, primary) { onTool(if (tool == it) null else it) }
                        ToolButton(EditTool.color, "paintpalette", tool == EditTool.color, primary) { onTool(if (tool == it) null else it) }
                        ToolButton(EditTool.size, "textformat.size", tool == EditTool.size, primary) { onTool(if (tool == it) null else it) }
                    }
                }
                BasicTextField(
                    value = Profile.me.raw(id),
                    onValueChange = { Profile.me.set(id, it) },
                    textStyle = sh(15f).copy(color = primary),
                    cursorBrush = SolidColor(theme.accent),
                    singleLine = !field.isParagraph,
                    maxLines = if (field.isParagraph) 4 else 1,
                    keyboardOptions = KeyboardOptions(
                        capitalization = KeyboardCapitalization.None,
                        autoCorrectEnabled = false,
                        keyboardType = field.keyboard,
                        imeAction = if (field.isParagraph) ImeAction.Default else ImeAction.Done,
                    ),
                    keyboardActions = KeyboardActions(onDone = { onDone() }),
                    modifier = Modifier.fillMaxWidth().focusRequester(focus),
                )
            }

            // ล้างทั้งช่องในปุ่มเดียว — เร็วกว่าลากเลือกทั้งก้อนแล้วลบในช่องแคบ ๆ
            if (value.isNotEmpty()) {
                val src = remember { MutableInteractionSource() }
                Box(
                    Modifier.size(24.dp).clickable(src, indication = null) {
                        Profile.me.set(id, "")
                        Haptics.impact(Haptics.Style.light)
                    },
                    contentAlignment = Alignment.Center,
                ) {
                    SFSymbol("xmark.circle.fill", size = 16f, tint = secondary.opacity(0.55))
                }
            }

            val doneSrc = remember { MutableInteractionSource() }
            Box(
                Modifier
                    .background(theme.accent, CircleShape)
                    .clickable(doneSrc, indication = null, onClick = onDone)
                    .padding(horizontal = 14.dp, vertical = 8.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text("เสร็จ", style = sh(13f, SHFont.semibold), color = onAccent, maxLines = 1, softWrap = false)
            }
        }
    }
}
