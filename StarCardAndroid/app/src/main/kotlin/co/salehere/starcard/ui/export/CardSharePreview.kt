package co.salehere.starcard.ui.export

import android.graphics.Bitmap
import androidx.activity.compose.BackHandler
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
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
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.model.AppRuntime
import co.salehere.starcard.model.CardFormat
import co.salehere.starcard.model.CardPage
import co.salehere.starcard.model.LocalClipInvocation
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.SFSymbol
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.Signature
import co.salehere.starcard.theme.SignaturePattern
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.rgb
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.LocalDismiss
import co.salehere.starcard.ui.copyPlainText
import co.salehere.starcard.ui.glowShadow
import co.salehere.starcard.ui.tap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import kotlin.math.min

/**
 * หน้าตัวอย่างก่อนแชร์ — รูปที่จะได้จริง บนฉากหลังผืนเดียว (พอร์ต = 3 หน้าต่อกัน · สตอรี่ = หน้าเดียว 9:16)
 * เป็นเครื่องมือ ไม่ใช่ชิ้นงาน จึงพื้นมืดเสมอ แผ่นการ์ดลอยเป็นงานพิมพ์บนโต๊ะ
 *
 * - pageSize: ขนาดหน้าบนจอที่ผู้ใช้วาง widget
 * - format: ตัดสินว่ารูปที่ได้เป็นแถบ 3 หน้า หรือสตอรี่หน้าเดียว
 * - onDismiss: ปิดหน้านี้ — null = ใช้ `LocalDismiss` ของผู้เปิด
 */
@Composable
fun CardSharePreview(
    pages: List<CardPage>,
    theme: CardTheme,
    pageSize: Size,
    format: CardFormat = CardFormat.portfolio,
    modifier: Modifier = Modifier,
    onDismiss: (() -> Unit)? = null,
) {
    val invocation = LocalClipInvocation.current
    val localDismiss = LocalDismiss.current
    val dismiss = onDismiss ?: localDismiss
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var image by remember { mutableStateOf<Bitmap?>(null) }
    var fileURL by remember { mutableStateOf<File?>(null) }
    var failed by remember { mutableStateOf(false) }
    var copied by remember { mutableStateOf(false) }
    var saving by remember { mutableStateOf(false) }
    var saved by remember { mutableStateOf(false) }
    var saveFailed by remember { mutableStateOf(false) }
    var rendering by remember { mutableStateOf(true) }

    BackHandler { if (saveFailed) saveFailed = false else dismiss() }

    fun copyLink() {
        copyPlainText(context, invocation.shareURL)
        Haptics.impact(Haptics.Style.medium)
        copied = true
        scope.launch {
            delay(2000)
            copied = false
        }
    }

    /** ขอสิทธิ์แบบเพิ่มอย่างเดียว — เราแค่เพิ่มรูปเข้าไป ไม่ต้องเปิดดูคลังรูปของเจ้าของเครื่อง */
    fun saveToPhotos() {
        val img = image ?: return
        if (saving) return
        saving = true
        scope.launch {
            val ok = withContext(Dispatchers.IO) { CardExport.saveToPhotos(context, img, invocation.slug, format) }
            saving = false
            if (ok) {
                Haptics.impact(Haptics.Style.medium)
                saved = true
            } else {
                saveFailed = true
            }
        }
    }

    Box(modifier.fillMaxSize().background(Signature.stage)) {
        // ตัวเรนเดอร์นอกจอ — ไม่กินที่ ไม่วาดบนจอ ส่งรูปกลับมาครั้งเดียว
        if (rendering) {
            CardExport.Renderer(
                pages = pages, theme = theme, pageSize = pageSize, slug = invocation.slug, format = format,
                onImage = { bmp ->
                    rendering = false
                    if (bmp == null) {
                        failed = true
                    } else {
                        scope.launch {
                            val file = withContext(Dispatchers.IO) { CardExport.jpegFile(bmp, invocation.slug, format) }
                            if (file != null) {
                                image = bmp
                                fileURL = file
                            } else {
                                failed = true
                            }
                        }
                    }
                },
            )
        }

        // เวทีของแบรนด์ — มืด + ลายน้ำจาง (วงกลางของกติกาลายเซ็น ดู `Signature`)
        SignaturePattern(opacity = 0.05)

        Column(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing)) {
            TopBar(format = format, onClose = dismiss)
            Spacer(Modifier.height(12.dp))
            PreviewStage(
                image = image, failed = failed, format = format,
                modifier = Modifier.weight(1f).fillMaxWidth().padding(horizontal = 18.dp),
            )
            Spacer(Modifier.height(16.dp))
            Column(
                Modifier.padding(horizontal = 18.dp).padding(bottom = 22.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                LinkRow(display = invocation.shareURLDisplay, copied = copied, onCopy = { copyLink() })
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    val img = image
                    val file = fileURL
                    // แชร์รูป
                    if (img != null && file != null) {
                        ActionLabel(
                            "แชร์รูป", Ph.shareNetwork, prominent = true,
                            modifier = Modifier.weight(1f).tap {
                                CardExport.share(context, file, "Sale Here STAR · @${invocation.slug}")
                            },
                        )
                    } else {
                        ActionLabel("แชร์รูป", Ph.shareNetwork, prominent = true, modifier = Modifier.weight(1f).alpha(0.38f))
                    }
                    // ลิงก์คัดลอกได้จากแถวบนอยู่แล้ว ช่องนี้จึงยกให้ "บันทึกรูป" · คลิปเซฟไม่ได้ → คัดลอกลิงก์แทน
                    if (AppRuntime.isClip) {
                        ActionLabel(
                            if (copied) "คัดลอกแล้ว" else "คัดลอกลิงก์",
                            if (copied) Ph.check else Ph.clipboardText,
                            prominent = false,
                            modifier = Modifier.weight(1f)
                                .semantics { contentDescription = "คัดลอกลิงก์" }
                                .tap { copyLink() },
                        )
                    } else {
                        ActionLabel(
                            if (saved) "บันทึกแล้ว" else "บันทึกรูป",
                            if (saved) Ph.check else Ph.arrowRight,
                            prominent = false,
                            iconTurn = if (saved) 0f else 90f,
                            modifier = Modifier.weight(1f)
                                .alpha(if (image == null) 0.38f else 1f)
                                .semantics { contentDescription = "บันทึกรูปลงคลังรูป" }
                                .tap(enabled = image != null && !saving) { saveToPhotos() },
                        )
                    }
                }
            }
        }

        if (saveFailed) {
            SaveFailedAlert(onDismiss = { saveFailed = false })
        }
    }
}

@Composable
private fun TopBar(format: CardFormat, onClose: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp).padding(top = 10.dp, bottom = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier
                .size(32.dp)
                .background(Color.White.opacity(0.1), CircleShape)
                .semantics { contentDescription = "ปิด" }
                .tap { onClose() },
            contentAlignment = Alignment.Center,
        ) {
            SFSymbol("xmark", size = 11f, tint = Color.White.opacity(0.7))
        }
        Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text("ฉบับที่จะส่งออก", style = sh(16f, SHFont.semibold), color = Color.White)
            Text(
                if (format == CardFormat.story) "สตอรี่ 1080×1920 · มี QR กลับมาที่การ์ด" else "3 หน้า · แผ่นเดียว · มี QR กลับมาที่การ์ด",
                style = sh(10.5f, SHFont.medium),
                color = Color.White.opacity(0.42),
                textAlign = TextAlign.Center,
            )
        }
        Spacer(Modifier.size(32.dp))
    }
}

@Composable
private fun PreviewStage(image: Bitmap?, failed: Boolean, format: CardFormat, modifier: Modifier) {
    BoxWithConstraints(modifier, contentAlignment = Alignment.Center) {
        val box = Size(maxWidth.value, maxHeight.value)
        Crossfade(targetState = image, animationSpec = Motion.settle.spec(), label = "sharePreview") { img ->
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                when {
                    img != null -> {
                        val fit = fit(Size(img.width.toFloat(), img.height.toFloat()), box)
                        val bmp = remember(img) { img.asImageBitmap() }
                        val shape = RoundedCornerShape(6.dp)
                        Image(
                            bitmap = bmp,
                            contentDescription = if (format == CardFormat.story) "ตัวอย่างการ์ดแบบสตอรี่" else "ตัวอย่างการ์ดสามหน้า",
                            contentScale = ContentScale.FillBounds,
                            filterQuality = FilterQuality.High,
                            modifier = Modifier
                                .size(fit.width.dp, fit.height.dp)
                                .glowShadow(Color.Black.opacity(0.55), 28f, 14f, 6f)
                                .clip(shape)
                                .border(0.5.dp, Color.White.opacity(0.08), shape),
                        )
                    }
                    failed -> Text("สร้างรูปไม่สำเร็จ", style = sh(14f, SHFont.medium), color = Color.White.opacity(0.55))
                    else -> ActivitySpinner(Color.White, Modifier.graphicsLayer { scaleX = 1.15f; scaleY = 1.15f })
                }
            }
        }
    }
}

/** ย่อรูปให้สุดขอบกล่องโดยคงอัตราส่วนของผืนที่เรนเดอร์ */
private fun fit(size: Size, box: Size): Size {
    val s = min(box.width / maxOf(size.width, 1f), box.height / maxOf(size.height, 1f))
    return Size(size.width * s, size.height * s)
}

@Composable
private fun LinkRow(display: String, copied: Boolean, onCopy: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .background(Color.White.opacity(0.07), RoundedCornerShape(14.dp))
            .semantics { contentDescription = "คัดลอกลิงก์การ์ด" }
            .tap { onCopy() }
            .padding(horizontal = 14.dp, vertical = 11.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        SFSymbol("link", size = 11f, tint = Color.White.opacity(0.45))
        Text(
            display,
            style = sh(12f, SHFont.medium),
            color = Color.White.opacity(0.7),
            maxLines = 1,
            softWrap = false,
            autoSize = TextAutoSize.StepBased(minFontSize = (12f * 0.75f).sp, maxFontSize = 12.sp, stepSize = 0.25.sp),
            modifier = Modifier.weight(1f),
        )
        Spacer(Modifier.width(8.dp))
        Text(
            if (copied) "คัดลอกแล้ว" else "คัดลอก",
            style = sh(11f, SHFont.semibold),
            color = if (copied) rgb(0.45, 0.92, 0.62) else Color.White.opacity(0.45),
        )
    }
}

@Composable
private fun ActionLabel(
    title: String,
    icon: Ph,
    prominent: Boolean,
    modifier: Modifier = Modifier,
    iconTurn: Float = 0f,
) {
    val fg = if (prominent) Color.Black.opacity(0.86) else Color.White.opacity(0.9)
    Row(
        modifier
            .background(if (prominent) Color.White else Color.White.opacity(0.10), RoundedCornerShape(16.dp))
            .padding(vertical = 15.dp),
        horizontalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PIcon(icon, size = 13f, weight = PhWeight.bold, tint = fg, modifier = Modifier.graphicsLayer { rotationZ = iconTurn })
        Text(title, style = sh(14.5f, SHFont.semibold), color = fg, maxLines = 1)
    }
}

/** `.alert("บันทึกรูปไม่ได้")` — แผ่นเตือนของแอปเอง (ฟอนต์แอป ไม่ใช่ของระบบ) */
@Composable
private fun SaveFailedAlert(onDismiss: () -> Unit) {
    Box(
        Modifier
            .fillMaxSize()
            .background(Color.Black.opacity(0.45))
            .tap { },
        contentAlignment = Alignment.Center,
    ) {
        Column(
            Modifier
                .padding(horizontal = 44.dp)
                .background(rgb(0.16, 0.16, 0.17), RoundedCornerShape(18.dp))
                .border(0.6.dp, Color.White.opacity(0.08), RoundedCornerShape(18.dp)),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(
                Modifier.padding(horizontal = 18.dp).padding(top = 20.dp, bottom = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text("บันทึกรูปไม่ได้", style = sh(16f, SHFont.semibold), color = Color.White, textAlign = TextAlign.Center)
                Text(
                    "ไปที่ ตั้งค่า > StarCard แล้วอนุญาตให้เพิ่มรูปลงคลังรูป",
                    style = sh(13f, SHFont.regular),
                    color = Color.White.opacity(0.7),
                    textAlign = TextAlign.Center,
                )
            }
            Box(Modifier.fillMaxWidth().height(0.6.dp).background(Color.White.opacity(0.12)))
            Box(
                Modifier.fillMaxWidth().height(46.dp).tap { onDismiss() },
                contentAlignment = Alignment.Center,
            ) {
                Text("ตกลง", style = sh(15f, SHFont.semibold), color = Color.White)
            }
        }
    }
}

/** `ProgressView()` — วงก้านแปดก้านหมุนทีละก้านแบบ iOS */
@Composable
private fun ActivitySpinner(color: Color, modifier: Modifier = Modifier) {
    val spin = rememberInfiniteTransition(label = "spinner")
    val step by spin.animateFloat(
        initialValue = 0f, targetValue = 8f,
        animationSpec = infiniteRepeatable(tween(800, easing = LinearEasing), RepeatMode.Restart),
        label = "step",
    )
    Canvas(modifier.size(22.dp)) {
        val c = Offset(size.width / 2f, size.height / 2f)
        val lead = step.toInt() % 8
        for (i in 0 until 8) {
            val age = (lead - i + 8) % 8
            val a = 1f - age / 8f * 0.85f
            rotate(degrees = i * 45f, pivot = c) {
                drawLine(
                    color.copy(alpha = color.alpha * a),
                    start = Offset(c.x, size.height * 0.08f),
                    end = Offset(c.x, size.height * 0.32f),
                    strokeWidth = size.width * 0.1f,
                    cap = StrokeCap.Round,
                )
            }
        }
    }
}
