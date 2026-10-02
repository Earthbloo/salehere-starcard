package co.salehere.starcard.ui.salehere.starflow

import android.graphics.BlurMaskFilter
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.ui.focus.focusRequester
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.ClipOp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import co.salehere.starcard.components.Motion
import co.salehere.starcard.components.float
import co.salehere.starcard.model.CardRecord
import co.salehere.starcard.model.LocalStarFlow
import co.salehere.starcard.model.StarDataKey
import co.salehere.starcard.model.StarFlow
import co.salehere.starcard.model.StarRow
import co.salehere.starcard.model.StarSocial
import co.salehere.starcard.model.WizStep
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SHColor
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.serifItalic
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.dockPress
import co.salehere.starcard.ui.profile.PK
import co.salehere.starcard.ui.salehere.SH
import co.salehere.starcard.ui.salehere.SHAvatar
import co.salehere.starcard.ui.salehere.SHMockUser
import co.salehere.starcard.ui.tap
import co.salehere.starcard.ui.widgets.FlowLayout
import kotlinx.coroutines.delay
import kotlin.math.max
import kotlin.math.roundToInt

// MARK: - ชิ้นส่วนของหน้าใหม่ใน flow "Unbox × StarCard" (= `.pk` / `.glass` / `.wz` ของ unbox-mock)
//
// พื้นสว่าง #F9FAFB + แสงเบลอโทน champagne + การ์ด/แถวเป็นกระจก · ปุ่มถ่านแคปซูล · เลือกแล้ว = เทา + ขอบดำ
// ภาษาเดียวกับ intake (`PK`) ต่างกันแค่ชั้นแสง/กระจกที่ผู้ใช้เลือกไว้ 22 ก.ย. 2569 (ดู memory star-profile-glow-glass)
// Android ไม่มี Liquid Glass — กระจกทุกชิ้นในไฟล์นี้คือแผ่นฝ้าขาวโปร่ง + ขอบแสงขาว (PORTING §8)

object GL {
    val bg = rgb(249 / 255.0, 250 / 255.0, 251 / 255.0)
    /** = `PK.ink` */
    val ink = Color(0xFF16181D)
    val muted = rgb(79 / 255.0, 79 / 255.0, 79 / 255.0)
    val hint = rgb(138 / 255.0, 143 / 255.0, 152 / 255.0)
    val verified = rgb(28 / 255.0, 140 / 255.0, 237 / 255.0)
    val green = rgb(18 / 255.0, 183 / 255.0, 106 / 255.0)
    val greenInk = rgb(14 / 255.0, 159 / 255.0, 110 / 255.0)
    val greenTint = rgb(231 / 255.0, 246 / 255.0, 239 / 255.0)
    val orb1 = rgb(243 / 255.0, 234 / 255.0, 211 / 255.0)
    val orb2 = rgb(241 / 255.0, 231 / 255.0, 206 / 255.0)
    val cardRim = rgb(1.0, 222 / 255.0, 140 / 255.0)
    val goldInk = rgb(154 / 255.0, 116 / 255.0, 32 / 255.0)
    val gold = rgb(201 / 255.0, 162 / 255.0, 39 / 255.0)

    /** "Didot-Italic" — Android ใช้เซริฟเอียงของระบบ (ดู `serifItalic`) */
    fun serif(size: Float): TextStyle = serifItalic(size)
}

// MARK: - ตัวช่วยร่วมของ flow (internal — ใช้ในโฟลเดอร์ starflow เท่านั้น)

/** `.timingCurve(0.16, 1, 0.3, 1)` — เส้นเวลาของ motion ยาวทั้ง flow (= `--ease-out-expo` ของเว็บ) */
internal val FlowEase = CubicBezierEasing(0.16f, 1f, 0.3f, 1f)

/** กระจกขาวบนพื้นสว่าง — `glassEffect(.regular.tint(.white.opacity(t)))` ≈ ขาวโปร่งเข้มขึ้นนิด */
internal fun glassWhite(tint: Double): Color = Color.White.opacity(minOf(1.0, tint + 0.12))

/** `.monospacedDigit()` */
internal fun TextStyle.tnum(): TextStyle = copy(fontFeatureSettings = "tnum")

/** `.lineSpacing(x)` = กล่องบรรทัดธรรมชาติของ NotoSansThai (≈ 1.36 em) + x */
internal fun TextStyle.lineSpaced(extra: Float): TextStyle =
    copy(lineHeight = (fontSize.value * 1.36f + extra).sp)

/**
 * `.shadow(color:radius:y:)` ของ SwiftUI — เงาฟุ้งรอบรูปทรง วาด **เฉพาะนอกรูปทรง**
 * (แผ่นกระจกโปร่ง ถ้าเงาลอดเข้ามาใต้แผ่นจะกลายเป็นคราบเทา) · `corner` = null → แคปซูล/วงกลม
 */
internal fun Modifier.glShadow(color: Color, radius: Float, y: Float = 0f, corner: Float? = null): Modifier =
    if (color.alpha <= 0f) this else drawWithCache {
        val cr = corner?.dp?.toPx() ?: (size.minDimension / 2f)
        val outline = Path().apply { addRoundRect(RoundRect(Rect(Offset.Zero, size), CornerRadius(cr))) }
        val argb = color.toArgb()
        val blurPx = max(0.5f, radius.dp.toPx())
        val paint = android.graphics.Paint().apply {
            isAntiAlias = true
            this.color = argb
            maskFilter = BlurMaskFilter(blurPx, BlurMaskFilter.Blur.NORMAL)
        }
        val dy = y.dp.toPx()
        onDrawBehind {
            clipPath(outline, ClipOp.Difference) {
                drawIntoCanvas { it.nativeCanvas.drawRoundRect(0f, dy, size.width, size.height + dy, cr, cr, paint) }
            }
        }
    }

/**
 * `.overlay(shape.strokeBorder(color, style: StrokeStyle(lineWidth:, dash:)))` — เส้นขอบด้านในรูปทรง
 * `dash` = 0 → เส้นทึบ · `radius` = null → แคปซูล/วงกลม
 */
internal fun Modifier.strokeInside(color: Color, width: Float, radius: Float? = null, dash: Float = 0f, gap: Float = 0f): Modifier =
    drawWithContent {
        drawContent()
        val w = width.dp.toPx()
        val half = w / 2f
        val full = radius?.dp?.toPx() ?: (size.minDimension / 2f)
        val r = max(0f, minOf(full, size.minDimension / 2f) - half)
        drawRoundRect(
            color = color,
            topLeft = Offset(half, half),
            size = Size(size.width - w, size.height - w),
            cornerRadius = CornerRadius(r),
            style = Stroke(width = w, pathEffect = if (dash > 0f) PathEffect.dashPathEffect(floatArrayOf(dash.dp.toPx(), gap.dp.toPx())) else null),
        )
    }

/** `.overlay(alignment: .top) { color.frame(height: 1) }` — เส้นคั่นบางที่ขอบบนของกล่อง */
internal fun Modifier.topHairline(color: Color, height: Float = 1f): Modifier =
    drawWithContent {
        drawContent()
        drawRect(color, size = Size(size.width, height.dp.toPx()))
    }

/** ไหลเข้าที่ทีละชิ้น — จาง + ลอยขึ้น หน่วงตามลำดับ (= `PKReveal(index:)`) */
@Composable
internal fun Modifier.glReveal(index: Int): Modifier {
    val k = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(((0.05 + Motion.stagger(index, step = 0.06, cap = 0.4)) * 1000).toLong())
        k.animateTo(1f, Motion.settle.float)
    }
    return this.graphicsLayer {
        alpha = k.value.coerceIn(0f, 1f)
        translationY = 18.dp.toPx() * (1f - k.value)
    }
}

/**
 * `.lineLimit(1).minimumScaleFactor(k)` ของทั้งแถว — วัดที่ขนาดจริงก่อน ล้นเมื่อไหร่ย่อทั้งก้อนลงเท่ากันทุกชิ้น (ไม่ต่ำกว่า k)
 */
@Composable
internal fun FitWidth(minScale: Float = 0.7f, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Layout(content, modifier) { measurables, constraints ->
        val p = measurables.first().measure(Constraints(maxHeight = constraints.maxHeight))
        val s = if (constraints.hasBoundedWidth && p.width > constraints.maxWidth) {
            max(minScale, constraints.maxWidth.toFloat() / p.width)
        } else 1f
        val w = (p.width * s).roundToInt().coerceIn(constraints.minWidth, constraints.maxWidth)
        val h = (p.height * s).roundToInt().coerceIn(constraints.minHeight, constraints.maxHeight)
        layout(w, h) {
            p.placeWithLayer(0, 0) {
                scaleX = s
                scaleY = s
                transformOrigin = TransformOrigin(0f, 0f)
            }
        }
    }
}

/** ดวงไฟเบลอหนึ่งดวง — วงกลมเต็ม `radius` ขอบฟุ้งออกไปอีก `blur` (แทน `Circle().blur(radius:)`) */
internal fun DrawScope.glowOrb(color: Color, center: Offset, radius: Float, blur: Float, alpha: Float) {
    if (alpha <= 0f || radius <= 0f) return
    val outer = radius + blur
    val inner = ((radius - blur) / outer).coerceIn(0f, 1f)
    val mid = (radius / outer).coerceIn(inner, 1f)
    val c = color.copy(alpha = (color.alpha * alpha).coerceIn(0f, 1f))
    drawCircle(
        brush = Brush.radialGradient(
            0f to c, inner to c, mid to c.copy(alpha = c.alpha * 0.5f), 1f to c.copy(alpha = 0f),
            center = center, radius = outer,
        ),
        radius = outer,
        center = center,
    )
}

/** ตัวหมุนรอโหลด (= `ProgressView()`) — Material ไม่ใช้ในแอปนี้ */
@Composable
internal fun Spinner(color: Color, size: Float = 36f, modifier: Modifier = Modifier) {
    val t = rememberInfiniteTransition(label = "spinner")
    val a by t.animateFloat(0f, 360f, infiniteRepeatable(tween(900, easing = LinearEasing)), label = "spin")
    Canvas(modifier.size(size.dp)) {
        val w = 3.dp.toPx()
        rotate(a) {
            drawArc(
                color = color, startAngle = 0f, sweepAngle = 270f, useCenter = false,
                topLeft = Offset(w / 2, w / 2), size = Size(this.size.width - w, this.size.height - w),
                style = Stroke(width = w, cap = StrokeCap.Round),
            )
        }
    }
}

/**
 * `confirmationDialog` ของ iOS — แผ่นล่างจอ: หัว + คำอธิบาย + ปุ่มลบสีแดง · ปุ่ม "ยกเลิก" แยกก้อน
 * ใช้ `Dialog` ของ compose-ui ให้ทับทั้งจอได้จากที่ไหนก็ได้ในต้นไม้
 */
@Composable
internal fun ActionSheet(title: String, message: String? = null, action: String, onAction: () -> Unit, onCancel: () -> Unit) {
    Dialog(onDismissRequest = onCancel, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.fillMaxSize().tap { onCancel() }, contentAlignment = Alignment.BottomCenter) {
            Column(
                Modifier.navigationBarsPadding().padding(horizontal = 8.dp).padding(bottom = 8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                val shape = RoundedCornerShape(14.dp)
                Column(Modifier.fillMaxWidth().clip(shape).background(Color.White.opacity(0.97)).tap {}) {
                    Column(
                        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        Text(title, style = sh(13f, SHFont.semibold), color = SHColor.textSecondary, textAlign = TextAlign.Center)
                        if (message != null) {
                            Text(message, style = sh(13f), color = SHColor.textTertiary, textAlign = TextAlign.Center)
                        }
                    }
                    Box(Modifier.fillMaxWidth().height(0.5.dp).background(SHColor.strokeStrong))
                    Box(Modifier.fillMaxWidth().height(56.dp).tap { onAction() }, contentAlignment = Alignment.Center) {
                        Text(action, style = sh(18f), color = SHColor.red)
                    }
                }
                Box(
                    Modifier.fillMaxWidth().height(56.dp).clip(shape).background(Color.White).tap { onCancel() },
                    contentAlignment = Alignment.Center,
                ) {
                    Text("ยกเลิก", style = sh(18f, SHFont.semibold), color = rgb(0.0, 0.48, 1.0))
                }
            }
        }
    }
}

// MARK: - แสง + หัวข้อ

/** แสงเบลอ champagne สองก้อน + จุดสว่างขาว บนพื้น #F9FAFB (= `.gl-orbs`) */
@Composable
fun GlassOrbs(
    /** เล่นท่าบาน (orb-bloom) ตอนเข้าหน้า — ครั้งแรกของการ์ดเกิดเท่านั้น */
    bloom: Boolean = false,
    /** false = พื้นและดวงไฟวาดโดย `StarGround` ของ shell แล้ว (หน้า Star Profile) — ที่นี่โปร่งใส */
    ground: Boolean = true,
    modifier: Modifier = Modifier,
) {
    val shown = remember { Animatable(if (bloom) 0f else 1f) }
    LaunchedEffect(Unit) { if (bloom) shown.animateTo(1f, tween(2400, easing = FlowEase)) }
    Canvas(modifier.fillMaxSize()) {
        if (!ground) return@Canvas
        val k = shown.value
        if (k <= 0f) return@Canvas
        val s = 0.55f + 0.45f * k
        val c = Offset(size.width / 2f, size.height / 2f)
        // `.scaleEffect` หลัง `.position` = ย่อรอบกลางจอ ดวงไฟจึงเลื่อนเข้าหากลางตอนเล็ก
        fun scaled(p: Offset) = Offset(c.x + (p.x - c.x) * s, c.y + (p.y - c.y) * s)
        drawRect(GL.bg.copy(alpha = k))
        glowOrb(GL.orb1, scaled(Offset(30.dp.toPx(), 110.dp.toPx())), 170.dp.toPx() * s, 70.dp.toPx() * s, 0.7f * k)
        glowOrb(GL.orb2, Offset(size.width + 10.dp.toPx(), 250.dp.toPx()), 160.dp.toPx(), 70.dp.toPx(), 0.5f * k)
        glowOrb(Color.White, scaled(Offset(260.dp.toPx(), 110.dp.toPx())), 70.dp.toPx() * s, 30.dp.toPx() * s, 0.9f * k)
    }
}

/** หัวข้อกระจก: คำหน้าตัวหนา + คำเน้นเป็น serif เอียงไล่สีดำ→ทอง (= `.glass-title`) */
@Composable
fun GlassTitle(words: List<Pair<String, Boolean>>, small: Boolean = false, modifier: Modifier = Modifier) {
    val d = LocalDensity.current.density
    FitWidth(minScale = 0.7f, modifier = modifier) {
        Row(horizontalArrangement = Arrangement.spacedBy((if (small) 7 else 8).dp)) {
            words.forEach { (t, serif) ->
                if (serif) {
                    BasicText(
                        t, Modifier.alignByBaseline(),
                        style = GL.serif(if (small) 40f else 54f).copy(
                            brush = Brush.verticalGradient(listOf(GL.ink, GL.ink, GL.goldInk)),
                            shadow = Shadow(GL.ink.opacity(0.12), Offset(0f, 12f * d), 9f * d),
                        ),
                        maxLines = 1, softWrap = false,
                    )
                } else {
                    BasicText(
                        t, Modifier.alignByBaseline(),
                        style = sh(if (small) 30f else 46f, SHFont.heavy).copy(
                            color = GL.ink,
                            letterSpacing = (if (small) -0.8f else -2f).sp,
                            shadow = Shadow(GL.ink.opacity(0.14), Offset(0f, 14f * d), 15f * d),
                        ),
                        maxLines = 1, softWrap = false,
                    )
                }
            }
        }
    }
}

/** ชิปกระจกใต้หัวข้อ (= `.glass-chip`) */
@Composable
fun GlassChip(icon: Ph, text: String, modifier: Modifier = Modifier) {
    Row(
        modifier
            .glShadow(GL.ink.opacity(0.06), 7f, 4f)
            .height(30.dp)
            .background(glassWhite(0.55), CircleShape)
            .border(1.dp, Color.White.opacity(0.95), CircleShape)
            .padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PIcon(icon, size = 15f, tint = GL.muted)
        Text(text, style = sh(13f), color = GL.muted, maxLines = 1)
    }
}

// MARK: - ปุ่ม

/** ปุ่มกลมกระจก 44 (= `.pk-circle` บนหน้ากระจก) */
@Composable
fun GlassCircleButton(symbol: Ph, size: Float = 44f, action: () -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier
            .glShadow(GL.ink.opacity(0.08), 7f, 4f)
            .size(size.dp)
            .clip(CircleShape)
            .background(glassWhite(0.55))
            .border(1.dp, Color.White.opacity(0.95), CircleShape)
            .tap {
                Haptics.impact(Haptics.Style.light)
                action()
            },
        contentAlignment = Alignment.Center,
    ) {
        PIcon(symbol, size = 18f, tint = GL.ink)
    }
}

/** ปุ่มหลักของหน้า Star Profile — แคปซูลถ่าน 56 + วงแหวนขาวสองชั้น (= `.ach2-btn`) */
@Composable
fun GlassPrimaryButton(title: String, symbol: Ph = Ph.arrowRight, action: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier
            .fillMaxWidth()
            .height(56.dp)
            .dockPress {
                Haptics.impact(Haptics.Style.medium)
                action()
            }
            .glShadow(GL.ink.opacity(0.16), 20f, 16f)
            .drawBehind {
                // วงแหวนขาวโปร่งหนา 6 รอบแคปซูล แล้วเส้นขาวบาง 1 อยู่นอกสุด (= strokeBorder + padding ติดลบ)
                val r = size.height / 2f
                val w6 = 6.dp.toPx()
                val w1 = 1.dp.toPx()
                val o1 = w6 / 2f
                drawRoundRect(
                    Color.White.opacity(0.5), topLeft = Offset(-o1, -o1), size = Size(size.width + w6, size.height + w6),
                    cornerRadius = CornerRadius(r + o1), style = Stroke(w6),
                )
                val o2 = w6 + w1 / 2f
                drawRoundRect(
                    Color.White.opacity(0.95), topLeft = Offset(-o2, -o2), size = Size(size.width + o2 * 2, size.height + o2 * 2),
                    cornerRadius = CornerRadius(r + o2), style = Stroke(w1),
                )
            }
            .background(GL.ink, CircleShape),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title, style = sh(16f, SHFont.bold), color = Color.White, maxLines = 1)
        PIcon(symbol, size = 18f, tint = Color.White)
    }
}

/** ลิงก์เล็กใต้ปุ่ม (= `.pk-link`) */
@Composable
fun GlassLink(title: String, action: () -> Unit, modifier: Modifier = Modifier) {
    Text(
        title,
        style = sh(13f, SHFont.semibold).copy(textDecoration = TextDecoration.Underline),
        color = GL.muted,
        modifier = modifier
            .tap {
                Haptics.impact(Haptics.Style.light)
                action()
            }
            .padding(6.dp),
    )
}

// MARK: - ป้าย

/** ป้าย "★ STAR" มุมการ์ด (= `.sc-level`) */
@Composable
fun StarPill(modifier: Modifier = Modifier) {
    Box(
        modifier
            .height(24.dp)
            .background(Color.White.opacity(0.8), CircleShape)
            .border(1.dp, GL.ink.opacity(0.08), CircleShape)
            .padding(horizontal = 9.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text("★ STAR", style = sh(11f, SHFont.heavy).copy(letterSpacing = 0.5.sp), color = GL.ink, maxLines = 1)
    }
}

/** ป้าย Verified น้ำเงิน (= `.sc-verified`) */
@Composable
fun VerifiedPill(modifier: Modifier = Modifier) {
    Row(
        modifier
            .height(20.dp)
            .background(GL.verified, CircleShape)
            .padding(start = 5.dp, end = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(3.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PIcon(Ph.sealCheck, size = 11f, weight = PhWeight.fill, tint = Color.White)
        Text("Verified", style = sh(11f, SHFont.bold), color = Color.White, maxLines = 1)
    }
}

/** ช่องประ "ข้อมูลจะขึ้นตรงนี้" บนการ์ดที่ยังว่าง (= `.wzi-ghost`) */
@Composable
fun GhostSlot(text: String, modifier: Modifier = Modifier) {
    Box(
        modifier
            .height(24.dp)
            .background(Color.White.opacity(0.35), RoundedCornerShape(8.dp))
            .strokeInside(GL.ink.opacity(0.22), 1f, radius = 8f, dash = 3f, gap = 3f)
            .padding(horizontal = 9.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(text, style = sh(11.5f, SHFont.semibold), color = GL.hint, maxLines = 1)
    }
}

// MARK: - การ์ดกระจก

/** ไอคอนโซเชียลขาวดำเข้ม (= `.saturation(0).brightness(-0.35).contrast(1.4)`) */
private val MonoIcon: ColorFilter = run {
    // เทา → ลดสว่าง 0.35 → ขยายคอนทราสต์ 1.4 รอบ 0.5 : out = 1.4·gray − 0.69 (สเกล 0–1)
    val k = 1.4f
    val off = -0.69f * 255f
    ColorFilter.colorMatrix(
        ColorMatrix(
            floatArrayOf(
                k * 0.2126f, k * 0.7152f, k * 0.0722f, 0f, off,
                k * 0.2126f, k * 0.7152f, k * 0.0722f, 0f, off,
                k * 0.2126f, k * 0.7152f, k * 0.0722f, 0f, off,
                0f, 0f, 0f, 1f, 0f,
            ),
        ),
    )
}

/** การ์ดกระจกใบจริง ประกอบจาก Star Profile · อัปเดตตามที่กรอก (= `cardView` ของเว็บ, สไตล์ `.ach2.glass .sc-card`) */
@Composable
fun StarGlassCard(
    /** ย่อ: ไม่โชว์แนะนำตัว/ผลงาน (หน้า intro ของ wizard) */
    compact: Boolean = false,
    /** ช่องที่ยังว่างให้โชว์เป็นช่องประ (หน้า intro) */
    ghosts: List<WizStep> = emptyList(),
    /** แตะรูปโปรไฟล์ — Star Profile พาไปหน้า "รูปและผลงาน" · null = รูปเฉย ๆ */
    onAvatar: (() -> Unit)? = null,
    /** หมวดสุดท้าย "Star Card" (ใบที่กำลังแสดง) — null = ไม่มีหมวดนี้ (หน้า reveal / intro / ยังไม่มีใบในคลัง) */
    liveCard: CardRecord? = null,
    cardCount: Int = 0,
    onOpenCard: () -> Unit = {},
    modifier: Modifier = Modifier,
) {
    val flow = LocalStarFlow.current
    val socials = StarSocial.entries.filter { flow.connected.contains(it) }
    fun ghost(s: WizStep) = ghosts.contains(s)
    val shape = RoundedCornerShape(26.dp)

    Box(
        modifier
            .fillMaxWidth()
            .glShadow(GL.ink.opacity(0.08), 22f, 18f, corner = 26f)
            .glShadow(rgb(1.0, 210 / 255.0, 90 / 255.0).opacity(0.14), 8f, 0f, corner = 26f)
            .clip(shape)
            .background(glassWhite(0.35))
            .background(
                Brush.linearGradient(
                    listOf(Color.White.opacity(0.42), Color.White.opacity(0.14), Color.White.opacity(0.3)),
                    start = Offset.Zero, end = Offset.Infinite,
                ),
            )
            .drawWithContent {
                drawContent()
                // เส้นขาวด้านใน (ห่างขอบ 1) + ขอบทองนิด ๆ ด้านนอก
                val w = 1.dp.toPx()
                val r = 26.dp.toPx()
                drawRoundRect(
                    Color.White.opacity(0.75), topLeft = Offset(w * 1.5f, w * 1.5f),
                    size = Size(size.width - w * 3, size.height - w * 3), cornerRadius = CornerRadius(r - w * 1.5f), style = Stroke(w),
                )
                drawRoundRect(
                    GL.cardRim.opacity(0.75), topLeft = Offset(w / 2, w / 2),
                    size = Size(size.width - w, size.height - w), cornerRadius = CornerRadius(r - w / 2), style = Stroke(w),
                )
            },
    ) {
        Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                CardAvatar(onAvatar)
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Row(
                        Modifier.padding(end = if (flow.isStar) 64.dp else 0.dp),
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            SHMockUser.name, style = sh(20f, SHFont.heavy), color = GL.ink, maxLines = 1,
                            overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false),
                        )
                        if (flow.isVerified) VerifiedPill()
                    }
                    when {
                        flow.has(StarDataKey.categories) -> {
                            val row = StarRow.all.first { it.key == StarDataKey.categories }
                            Text(
                                "@${SHMockUser.fallbackName.lowercase()} · " + flow.facts(row).joinToString(" · "),
                                style = sh(13f), color = GL.muted, maxLines = 1, overflow = TextOverflow.Ellipsis,
                            )
                        }
                        ghosts.isEmpty() -> Text("สายที่ใช่จะขึ้นตรงนี้", style = sh(13f, italic = true), color = GL.muted.opacity(0.6))
                        else -> FlowLayout(spacing = 5f) {
                            if (ghost(WizStep.categories)) GhostSlot("สายที่ใช่")
                            if (ghost(WizStep.province)) GhostSlot("พื้นที่")
                            if (ghost(WizStep.availability)) GhostSlot("วันว่าง")
                        }
                    }
                }
            }
            if (ghosts.isNotEmpty()) {
                FlowLayout(spacing = 5f) {
                    if (ghost(WizStep.socials)) GhostSlot("ยอดผู้ติดตาม")
                    if (ghost(WizStep.media)) GhostSlot("รูปและผลงาน")
                    if (ghost(WizStep.rate)) GhostSlot("เรทรับงาน")
                    if (ghost(WizStep.insight)) GhostSlot("ข้อมูลผู้ติดตาม")
                    if (ghost(WizStep.about)) GhostSlot("แนะนำตัว")
                    if (ghost(WizStep.kyc)) GhostSlot("Verified")
                }
            } else if (socials.isNotEmpty() && flow.has(StarDataKey.socials)) {
                // ช่องทาง = หมวดของมันเองในการ์ด (หัวเล็ก + เส้นคั่น แบบแถวท้าย) ไม่ลอยต่อจากชื่อ (ผู้ใช้ 24 ก.ย. 2569)
                // ยังไม่ผูกโซเชียล = ไม่มีหมวดนี้เลย (ผู้ใช้ 1 ต.ค. 2569: "ยังไม่มีก็เอาออก")
                Column(
                    Modifier.fillMaxWidth().topHairline(GL.ink.opacity(0.08)).padding(top = 10.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text("ช่องทาง", style = sh(12f, SHFont.semibold), color = GL.muted)
                    FlowLayout(spacing = 8f) {
                        socials.forEach { s ->
                            Row(
                                Modifier
                                    .height(34.dp)
                                    .background(Color.White.opacity(0.82), CircleShape)
                                    .border(1.dp, Color.White.opacity(0.95), CircleShape)
                                    .padding(start = 6.dp, end = 12.dp),
                                horizontalArrangement = Arrangement.spacedBy(5.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Image(
                                    painterResource(s.icon), contentDescription = null,
                                    modifier = Modifier.size(20.dp).clip(CircleShape),
                                    contentScale = ContentScale.Fit, colorFilter = MonoIcon,
                                )
                                Text(StarFlow.fmt(s.followers), style = sh(14f, SHFont.bold), color = GL.ink)
                            }
                        }
                    }
                }
            }
            if (!compact && flow.has(StarDataKey.about)) {
                Text(flow.about, style = sh(15f).lineSpaced(4f), color = GL.ink)
            }
            if (!compact && flow.reviewed) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    listOf(SHIcon.photo1, SHIcon.photo4).forEach { res ->
                        Image(
                            painterResource(res), contentDescription = null, contentScale = ContentScale.Crop,
                            modifier = Modifier
                                .size(64.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .border(2.dp, Color.White, RoundedCornerShape(8.dp)),
                        )
                    }
                }
            }
            // แถว "ทำงานผ่าน Sale Here N งาน" เอาออก (ผู้ใช้ 24 ก.ย. 2569) — แถวท้ายโผล่เฉพาะตอนมีเรท/ยืนยันตัวตนแล้ว
            if (ghosts.isEmpty() && (flow.has(StarDataKey.rate) || flow.isVerified)) {
                FlowLayout(spacing = 12f, modifier = Modifier.fillMaxWidth().topHairline(GL.ink.opacity(0.08)).padding(top = 10.dp)) {
                    if (flow.has(StarDataKey.rate)) CardFoot("เรทเริ่ม ", "฿1,500", "/โพสต์")
                    if (flow.isVerified) CardFoot("", "ยืนยันตัวตนแล้ว")
                }
            }
            if (ghosts.isEmpty() && liveCard != null) {
                StarCardSection(record = liveCard, onOpen = onOpenCard)
            }
        }
        if (flow.isStar || ghosts.isNotEmpty()) {
            StarPill(Modifier.align(Alignment.TopEnd).padding(12.dp))
        }
    }
}

@Composable
private fun CardAvatar(onAvatar: (() -> Unit)?) {
    val pic: @Composable () -> Unit = {
        Box(Modifier.glShadow(GL.ink.opacity(0.12), 8f, 6f).size(60.dp)) {
            SHAvatar(size = 60f)
            Box(Modifier.size(60.dp).border(3.dp, Color.White.opacity(0.85), CircleShape))
        }
    }
    if (onAvatar != null) {
        Box(
            Modifier
                .semantics { contentDescription = "เปลี่ยนรูป" }
                .dockPress {
                    Haptics.impact(Haptics.Style.light)
                    onAvatar()
                },
        ) {
            pic()
            Box(
                Modifier
                    .align(Alignment.BottomEnd)
                    .offset(2.dp, 2.dp)
                    .size(22.dp)
                    .background(GL.ink, CircleShape)
                    .border(2.dp, Color.White, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                PIcon(Ph.camera, size = 11f, weight = PhWeight.fill, tint = Color.White)
            }
        }
    } else {
        pic()
    }
}

@Composable
private fun CardFoot(a: String, b: String, c: String = "") {
    Text(
        buildAnnotatedString {
            withStyle(SpanStyle(color = GL.muted)) { append(a) }
            withStyle(SpanStyle(color = GL.ink, fontWeight = FontWeight.Bold)) { append(b) }
            withStyle(SpanStyle(color = GL.muted)) { append(c) }
        },
        style = sh(12f), maxLines = 1,
    )
}

// MARK: - ชิ้นส่วน wizard (= `.wz-*`)

/** ชิปเลือก (= `.wz-chip`): ขาว+ขอบบาง · เลือกแล้ว = เทา + ขอบดำ */
@Composable
fun WzChip(text: String, on: Boolean, action: () -> Unit, modifier: Modifier = Modifier) {
    val fill by animateColorAsState(if (on) PK.pick else Color.White, Motion.snap.spec(), label = "wzChipFill")
    val line by animateColorAsState(if (on) GL.ink else PK.line, Motion.snap.spec(), label = "wzChipLine")
    Box(
        modifier
            .height(40.dp)
            .clip(CircleShape)
            .background(fill)
            .strokeInside(line, if (on) 1.5f else 1f)
            .tap {
                Haptics.impact(Haptics.Style.light)
                action()
            }
            .padding(horizontal = 14.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(text, style = sh(14f, if (on) SHFont.bold else SHFont.semibold), color = GL.ink, maxLines = 1)
    }
}

/** กล่องเลือก (= `.wz-tile`): เลขใหญ่ + คำอธิบาย */
@Composable
fun WzTile(title: String, sub: String, on: Boolean, action: () -> Unit, modifier: Modifier = Modifier) {
    val fill by animateColorAsState(if (on) PK.pick else Color.White, Motion.snap.spec(), label = "wzTileFill")
    val line by animateColorAsState(if (on) GL.ink else PK.line, Motion.snap.spec(), label = "wzTileLine")
    val shape = RoundedCornerShape(16.dp)
    Column(
        modifier
            .fillMaxWidth()
            .clip(shape)
            .background(fill)
            .strokeInside(line, if (on) 1.5f else 1f, radius = 16f)
            .tap {
                Haptics.impact(Haptics.Style.light)
                action()
            }
            .padding(vertical = 16.dp, horizontal = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        Text(
            title, style = sh(22f, SHFont.heavy), color = GL.ink, maxLines = 1, softWrap = false,
            autoSize = androidx.compose.foundation.text.TextAutoSize.StepBased(
                minFontSize = (22f * 0.7f).sp, maxFontSize = 22.sp, stepSize = 0.5.sp,
            ),
        )
        Text(sub, style = sh(12.5f), color = PK.muted, textAlign = TextAlign.Center)
    }
}

/** ช่องกรอกของ wizard (= `.wz-in.col`): ป้ายเล็กด้านบน + ค่า + ท้าย */
@Composable
fun WzInput(
    label: String,
    text: String,
    onTextChange: (String) -> Unit,
    placeholder: String = "",
    unit: String? = null,
    keyboard: KeyboardType = KeyboardType.Text,
    select: Boolean = false,
    modifier: Modifier = Modifier,
) {
    val focus = remember { FocusRequester() }
    var focused by remember { mutableStateOf(false) }
    val line by animateColorAsState(if (focused) GL.ink else PK.line, Motion.snap.spec(), label = "wzInputLine")
    val shape = RoundedCornerShape(16.dp)
    Column(
        modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Color.White)
            .strokeInside(line, 1f, radius = 16f)
            .tap { if (!select) runCatching { focus.requestFocus() } }
            .padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 6.dp),
    ) {
        Text(label, style = sh(11.5f, SHFont.semibold), color = PK.hint, maxLines = 1)
        Row(Modifier.height(30.dp), horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            BasicTextField(
                value = text,
                onValueChange = onTextChange,
                enabled = !select,
                singleLine = true,
                textStyle = sh(17f).copy(color = GL.ink),
                cursorBrush = SolidColor(GL.ink),
                keyboardOptions = KeyboardOptions(keyboardType = keyboard),
                modifier = Modifier
                    .weight(1f)
                    .focusRequester(focus)
                    .onFocusChanged { focused = it.isFocused },
                decorationBox = { inner ->
                    Box(contentAlignment = Alignment.CenterStart) {
                        if (text.isEmpty()) Text(placeholder, style = sh(17f), color = PK.hint.opacity(0.7), maxLines = 1)
                        inner()
                    }
                },
            )
            if (unit != null) Text(unit, style = sh(15f, SHFont.semibold), color = PK.hint)
            if (select) PIcon(Ph.caretDown, size = 14f, tint = PK.line2)
        }
    }
}

/** ชิปบอก "แบรนด์ใช้ข้อนี้ทำอะไร" ใต้หัวข้อ (= `.nchip` · ชิ้นแรกไล่สี champagne + ไอคอนตา) */
@Composable
fun NudgeChips(lines: List<String>, modifier: Modifier = Modifier) {
    FlowLayout(spacing = 6f, modifier = modifier) {
        lines.forEachIndexed { i, t ->
            val first = i == 0
            Row(
                Modifier
                    .height(26.dp)
                    .clip(CircleShape)
                    .background(
                        if (first) {
                            Brush.horizontalGradient(
                                listOf(rgb(1.0, 243 / 255.0, 201 / 255.0), rgb(1.0, 227 / 255.0, 154 / 255.0), rgb(1.0, 217 / 255.0, 194 / 255.0)),
                            )
                        } else SolidColor(PK.fieldFill),
                    )
                    .strokeInside(if (first) rgb(1.0, 214 / 255.0, 110 / 255.0).opacity(0.6) else Color.Transparent, 1f)
                    .padding(horizontal = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (first) PIcon(Ph.eye, size = 12f, tint = rgb(180 / 255.0, 116 / 255.0, 26 / 255.0))
                Text(t, style = sh(12f, SHFont.semibold), color = if (first) GL.ink else GL.muted, maxLines = 1)
            }
        }
    }
}

// MARK: - dialog กลางจอ + toast (= `U.dialog({kind:'modal'})` / `Store.toast`)

/** ปุ่มหนึ่งปุ่มของ `FlowModal` (= tuple `(String, Bool, () -> Void)` ของ Swift) — `primary` = ปุ่มแดงเต็ม */
data class FlowButton(val title: String, val primary: Boolean, val action: () -> Unit)

@Composable
fun FlowModal(title: String, detail: String, buttons: List<FlowButton>, modifier: Modifier = Modifier) {
    Box(
        modifier
            .fillMaxSize()
            .background(Color.Black.opacity(0.45))
            .tap {},
        contentAlignment = Alignment.Center,
    ) {
        Column(
            Modifier
                .padding(horizontal = 36.dp)
                .fillMaxWidth()
                .background(Color.White, RoundedCornerShape(18.dp))
                .padding(22.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text(title, style = sh(17f, SHFont.bold), color = SH.ink, textAlign = TextAlign.Center)
            Text(detail, style = sh(14f).lineSpaced(3f), color = SH.muted, textAlign = TextAlign.Center)
            Column(Modifier.padding(top = 4.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                buttons.forEach { b ->
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .height(46.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (b.primary) SH.red else PK.fieldFill)
                            .tap {
                                Haptics.impact(Haptics.Style.light)
                                b.action()
                            },
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(b.title, style = sh(15f, SHFont.semibold), color = if (b.primary) Color.White else SH.ink)
                    }
                }
            }
        }
    }
}

@Composable
fun FlowToast(text: String, modifier: Modifier = Modifier) {
    Text(
        text,
        style = sh(13f, SHFont.semibold),
        color = Color.White,
        modifier = modifier
            .padding(bottom = 90.dp)
            .glShadow(Color.Black.opacity(0.18), 10f, 4f)
            .background(SH.ink.opacity(0.92), CircleShape)
            .padding(horizontal = 16.dp, vertical = 10.dp),
    )
}

/** ที่ว่างเท่ากล่อง (= `Color.clear.frame(width:height:)`) */
@Composable
internal fun Gap(w: Float, h: Float) {
    Spacer(Modifier.size(w.dp, h.dp))
}
