package co.salehere.starcard.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.AnimationSpec
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.SpringSpec
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.geometry.Offset
import androidx.compose.foundation.layout.offset
import androidx.compose.ui.layout.layout
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

// MARK: - โทเคนการเคลื่อนไหวของทั้งแอป (= Components/Motion.swift)
//
// iOS ใช้ `interpolatingSpring(stiffness:damping:)` — Compose ใช้ `spring(dampingRatio, stiffness)`
// แปลง: dampingRatio = damping / (2·√stiffness) (มวล 1) ค่าเดิมทุกตัวคงไว้ในชื่อเดิม

/** สปริงหนึ่งตัว — เก็บค่าดิบของ iOS ไว้ แล้วออก `AnimationSpec` ของชนิดใดก็ได้ */
data class SpringToken(val stiffness: Float, val damping: Float) {
    val dampingRatio: Float get() = damping / (2f * sqrt(stiffness))
    fun <T> spec(): SpringSpec<T> = spring(dampingRatio = dampingRatio, stiffness = stiffness)
    /** หน่วง `delay` วินาที ก่อนเริ่ม (= `.delay(_:)`) — Compose ไม่มี delay ในสปริง จึงใช้ที่ `LaunchedEffect` ของผู้เรียก */
}

object Motion {
    /** ตอบสนองทันที เด้งน้อย — ปุ่ม ป้าย การเลือก */
    val snap = SpringToken(380f, 30f)
    /** ไหลนุ่ม — การจัดเรียงใหม่ของ widget */
    val flow = SpringToken(240f, 26f)
    /** เด้งชัด — ตอนการ์ดลอยขึ้นติดนิ้ว */
    val lift = SpringToken(460f, 21f)
    /** หนักแน่น — เปลี่ยนหน้า · จังหวะเดียวของทั้งการเปลี่ยนหน้า */
    val page = SpringToken(190f, 24f)
    /** เข้าที่อย่างสงบ — เข้า/ออกโหมดแต่ง */
    val settle = SpringToken(260f, 28f)

    /** หน่วงไล่ทีละชิ้น (วินาที) */
    fun stagger(i: Int, step: Double = 0.045, cap: Double = 0.45): Double = min(i * step, cap)
}

/** `spec` สำหรับ `animateFloatAsState`/`Animatable<Float>` */
val SpringToken.float: SpringSpec<Float> get() = spec()
/** ทางลัด — `withAnimation(Motion.snap)` ≈ `animateTo(target, Motion.snap.float)` */
fun <T> SpringToken.asSpec(): AnimationSpec<T> = spec()
/** ทวีนตรง ๆ (= `.easeInOut(duration:)`) */
fun easeInOut(seconds: Double): AnimationSpec<Float> = tween((seconds * 1000).toInt())

// MARK: - เข้า/ออกฉากต่อ widget (สไตล์ Framer)

/** สถานะปลายทางของเอฟเฟกต์หนึ่งจังหวะ — identity คือ "อยู่ในที่ของมัน" */
data class MotionFX(
    val opacity: Double = 1.0,
    val dx: Float = 0f,
    val dy: Float = 0f,
    val scale: Float = 1f,
    /** หมุนบนระนาบ (องศา) */
    val rotZ: Double = 0.0,
    /** เอียงพ้นระนาบรอบแกนนอน (องศา) */
    val rotX: Double = 0.0,
    /** พลิกรอบแกนตั้ง (องศา) */
    val rotY: Double = 0.0,
) {
    /** ท่าเดียวกันแต่กลับด้าน — กลับเครื่องหมายเฉพาะองค์ประกอบที่ "มีทิศ" */
    val mirrored: MotionFX get() = copy(dx = -dx, rotY = -rotY, rotZ = -rotZ)

    companion object {
        val identity = MotionFX()
        fun lerp(a: MotionFX, b: MotionFX, t: Float): MotionFX {
            val k = t.toDouble()
            fun f(x: Double, y: Double) = x + (y - x) * k
            fun g(x: Float, y: Float) = x + (y - x) * t
            return MotionFX(f(a.opacity, b.opacity), g(a.dx, b.dx), g(a.dy, b.dy), g(a.scale, b.scale),
                f(a.rotZ, b.rotZ), f(a.rotX, b.rotX), f(a.rotY, b.rotY))
        }
    }
}

/** ท่าหนึ่งแบบของ widget — เก็บแค่ "ท่าสุดขั้วตอนอยู่ห่างหนึ่งหน้าเต็มทางขวา" */
data class EntranceStyle(val pose: MotionFX, val intro: SpringToken) {
    companion object {
        /** ชั้นลึกสุด — ภาพใหญ่ */
        val deep = EntranceStyle(MotionFX(dy = 18f, scale = 0.88f, rotY = 44.0), SpringToken(170f, 24f))
        /** ชั้นกลาง — แผ่นข้อมูล */
        val mid = EntranceStyle(MotionFX(dy = 10f, scale = 0.94f, rotY = 26.0), SpringToken(230f, 25f))
        /** ชั้นเบา — ตัวหนังสือ/ชิป */
        val light = EntranceStyle(MotionFX(dy = 5f, scale = 0.975f, rotY = 13.0), SpringToken(280f, 26f))
        /** ตัวยึด — widget ที่มีท่าเป็นของตัวเองข้างใน */
        val anchored = EntranceStyle(MotionFX(dy = 6f, scale = 0.97f), SpringToken(210f, 25f))
    }
}

// MARK: - สครับระดับชิ้นส่วนใน widget

/** ระยะหน้าที่ส่งลงไปถึง "ข้างใน" widget (= `PageScrub`) */
data class PageScrub(
    /** -1…1 · > 0 = หน้านี้อยู่ทางขวา (ยังไม่มาถึง) · < 0 = ผ่านไปทางซ้ายแล้ว */
    val d: Float = 0f,
    /** ลำดับของ widget ในหน้า — ใช้หน่วงเป็นขบวน */
    val order: Int = 0,
    /** พื้นผิวกระจก — ห้าม 3D transform ที่ตัวแผ่นกระจกเอง */
    val flat: Boolean = false,
) {
    companion object { val still = PageScrub() }
}

/** ค่าเริ่มต้นคือ "นิ่ง" — พรีวิวในตู้ widget และชั้นลอยตอนลาก จึงไม่ติดท่าเปลี่ยนหน้า (= `\.pageScrub`) */
val LocalPageScrub = compositionLocalOf { PageScrub.still }

/**
 * คณิตกลางของทุกท่าในระดับชิ้นส่วน — กติกาเหล็ก 3 ข้อ:
 * 1. ความคืบหน้าคิดจาก |d| เท่านั้น · 2. ทิศคิดจาก sign(d) เท่านั้น · 3. ไม่มีชิ้นไหนถือ animation ของตัวเอง
 */
object Scrub {
    /** ทิศเดินทาง +1 / -1 */
    fun dir(d: Float): Float = if (d < 0) -1f else 1f

    /** ความคืบหน้าของท่า 0…1 — `lead` = ยอมให้ "อยู่นิ่งก่อน" กี่ส่วนของทาง */
    fun t(d: Float, lead: Double = 0.0): Float {
        val a = min(1f, abs(d))
        val l = lead.coerceIn(0.0, 0.85).toFloat()
        return ((a - l) / max(0.0001f, 1 - l)).coerceIn(0f, 1f)
    }

    /** โค้งนุ่มหัวท้าย (smoothstep) */
    fun ease(t: Float): Float = t * t * (3 - 2 * t)

    /** ลำดับที่กลับด้านเองตามทิศ — ชิ้นที่อยู่ "ต้นทาง" ของการเดินทางไปก่อนเสมอ */
    fun lead(i: Int, of: Int, d: Float, step: Double = 0.13): Double {
        if (of <= 1) return 0.0
        val k = if (d < 0) i else (of - 1 - i)
        return k * step
    }

    /** ความจางช่วงท้าย — เรขาคณิตนำ opacity ตาม */
    fun fade(t: Float, after: Double = 0.55): Double {
        val a = after.coerceIn(0.01, 0.99)
        return (1 - (t.toDouble() - a) / (1 - a)).coerceIn(0.0, 1.0)
    }

    fun mix(a: Float, b: Float, t: Float): Float = a + (b - a) * t

    /** มิเตอร์ไล่ทีละช่อง — ค่าความสว่างของช่องที่ i · 1 = ยังเต็ม · 0 = ดับแล้ว */
    fun cell(i: Int, of: Int, d: Float, lead: Double = 0.0, spill: Double = 1.0): Double {
        if (of <= 0) return 0.0
        val t = t(d, lead).toDouble()
        val k = (if (d < 0) (of - 1 - i) else i).toDouble()
        val span = of + spill
        return ((1 - t) * span - k).coerceIn(0.0, 1.0)
    }
}

// MARK: - ท่ามาตรฐาน (modifier)
//
// ใน Compose ค่า `d` ที่ส่งเข้ามาถูกไล่โดยสปริงของหน้า (`Animatable`) อยู่แล้ว ทุก modifier จึงเป็นฟังก์ชันของ d ล้วน
// (`ScrubReader` ของ iOS ไม่จำเป็น — ส่ง `d` ตรง ๆ)

/** บานเกล็ด — ช่องมองหุบ ของข้างในไม่ขยับ (= `scrubAperture`) */
fun Modifier.scrubAperture(d: Float, lead: Double = 0.0, feather: Float = 0.16f, dim: Double = 0.5): Modifier {
    val t = Scrub.ease(Scrub.t(d, lead))
    if (t <= 0f) return this
    val fromLeading = d < 0
    val f = feather.coerceIn(0.001f, 0.5f)
    val edge = if (fromLeading) t else 1 - t
    val dimA = (dim * (max(0f, t - 0.45f) / 0.55f)).toFloat().coerceIn(0f, 1f)
    return graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen)
        .drawWithContent {
            drawContent()
            if (dimA > 0f) drawRect(Color.Black.copy(alpha = dimA))
            val stops = if (fromLeading) arrayOf(
                0f to Color.Transparent, max(0f, edge - f) to Color.Transparent,
                min(1f, edge) to Color.Black, 1f to Color.Black)
            else arrayOf(
                0f to Color.Black, max(0f, edge) to Color.Black,
                min(1f, edge + f) to Color.Transparent, 1f to Color.Transparent)
            drawRect(Brush.horizontalGradient(colorStops = stops), blendMode = BlendMode.DstIn)
        }
}

/** ม่านบรรทัด — ตัวหนังสือไถลลงลอดใต้ขอบกล่องของตัวเอง (= `scrubVeil`) */
fun Modifier.scrubVeil(d: Float, lead: Double = 0.0, drop: Float = 20f, pull: Float = 10f): Modifier {
    val t = Scrub.ease(Scrub.t(d, lead))
    if (t <= 0f) return this
    val s = Scrub.dir(d)
    val a = Scrub.fade(t, 0.55).toFloat()
    return graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen)
        .drawWithContent {
            // ตัดที่กรอบเดิมของตัวเอง — บรรทัดจึงมุดหายใต้ขอบ
            clipRect { this@drawWithContent.drawContent() }
        }
        .graphicsLayer { translationX = -s * pull * t * density; translationY = drop * t * density; alpha = a }
}

/** กล้องดอลลี่ — ภาพในกรอบเลื่อนสวนทางหน้า พร้อมดันเข้าหาเลนส์ (= `scrubDolly`) */
fun Modifier.scrubDolly(d: Float, shift: Float, zoom: Float = 0.16f, lead: Double = 0.0): Modifier {
    val t = Scrub.t(d, lead)
    if (t <= 0f) return this
    val s = Scrub.dir(d)
    return graphicsLayer { scaleX = 1 + zoom * t; scaleY = 1 + zoom * t; translationX = -s * shift * t * density }
}

/** บานพับเดี่ยว — ชิ้นหนึ่งพลิกอยู่ในช่องของตัวเอง (= `scrubLouver`) */
fun Modifier.scrubLouver(d: Float, lead: Double = 0.0, angle: Double = 62.0, shrink: Float = 0.12f, flat: Boolean = false): Modifier {
    val t = Scrub.ease(Scrub.t(d, lead))
    if (t <= 0f) return this
    val s = Scrub.dir(d)
    val a = Scrub.fade(t, 0.68).toFloat()
    return graphicsLayer {
        scaleX = 1 - shrink * t; scaleY = 1 - shrink * t
        if (flat) rotationZ = s * 5f * t else { rotationY = -s * angle.toFloat() * t; cameraDistance = 8f * density }
        alpha = a
    }.drawWithContent {
        drawContent()
        // หรี่ด้วยแผ่นดำจาง ๆ แทน brightness/saturation (Compose ไม่มีฟิลเตอร์สีต่อชั้นแบบเบา ๆ)
        drawRect(Color.Black.copy(alpha = 0.34f * t), blendMode = BlendMode.SrcAtop)
    }
}

/** ไถลในราง — เลื่อนไปทางเดียวกับที่หน้ากำลังไป โดยไม่ย่อและไม่พลิก (= `scrubSlide`) */
fun Modifier.scrubSlide(d: Float, travel: Float, lead: Double = 0.0, fade: Double = 0.7, eased: Boolean = true): Modifier {
    val raw = Scrub.t(d, lead)
    val t = if (eased) Scrub.ease(raw) else raw
    if (t <= 0f) return this
    val a = Scrub.fade(t, fade).toFloat()
    return graphicsLayer { translationX = -Scrub.dir(d) * travel * t * density; alpha = a }
}

/** ท่าเข้า-ออกที่ "สครับตามนิ้ว" ระดับกรอบ widget (= `pageChoreo`) */
fun Modifier.pageChoreo(style: EntranceStyle, order: Int, d: Float, flat: Boolean = false, intro: Boolean = true): Modifier {
    var fx: MotionFX
    if (!intro) {
        fx = style.pose.copy(opacity = 0.0)
    } else {
        val c = d.coerceIn(-1f, 1f)
        if (c == 0f) return this
        val pose = if (c > 0) style.pose else style.pose.mirrored
        val t = Scrub.t(c, min(order * 0.07, 0.3))
        fx = MotionFX.lerp(MotionFX.identity, pose, t).copy(opacity = Scrub.fade(t, 0.6))
    }
    if (flat) {
        fx = fx.copy(scale = fx.scale - (abs(fx.rotY) + abs(fx.rotX)).toFloat() / 900f,
                     rotZ = fx.rotZ + fx.rotY / 22, rotX = 0.0, rotY = 0.0)
    }
    val f = fx
    return graphicsLayer {
        rotationX = f.rotX.toFloat(); rotationY = f.rotY.toFloat(); rotationZ = f.rotZ.toFloat()
        cameraDistance = 8f * density
        scaleX = f.scale; scaleY = f.scale; alpha = f.opacity.toFloat()
        translationX = f.dx * density; translationY = f.dy * density
    }
}

/** เอียง 3 มิติเข้าหาจุดที่นิ้วแตะ + ขยายนิดหน่อย (= `pressTilt`) — เงาเรืองแสงให้ผู้เรียกวาดเอง */
fun Modifier.pressTilt(point: Offset?, width: Float, height: Float): Modifier {
    val maxTilt = 7f
    var tx = 0f; var ty = 0f
    if (point != null && width > 1 && height > 1) {
        val nx = (point.x / width - 0.5f) * 2
        val ny = (point.y / height - 0.5f) * 2
        tx = -ny * maxTilt; ty = nx * maxTilt
    }
    val pressed = point != null
    return graphicsLayer {
        rotationX = tx; rotationY = ty; cameraDistance = 10f * density
        scaleX = if (pressed) 1.025f else 1f; scaleY = if (pressed) 1.025f else 1f
    }
}

// MARK: - มิเตอร์ตัวเลข

/** ตัวเลขลอกทีละหลักตามนิ้ว (= `ScrubDigits`) */
@Composable
fun ScrubDigits(text: String, d: Float, lead: Double = 0.0, step: Double = 0.05, drop: Float = 26f,
                style: TextStyle, color: Color = Color.Unspecified, modifier: Modifier = Modifier) {
    val chars = text.toList()
    Row(modifier) {
        chars.forEachIndexed { i, ch ->
            Text(ch.toString(), style = style, color = color, softWrap = false,
                modifier = Modifier.wrapContentSize()
                    .scrubVeil(d, lead = min(0.8, lead + Scrub.lead(i, chars.size, d, step)), drop = drop, pull = 0f))
        }
    }
}

// MARK: - แถบวิ่งที่กรอตามนิ้ว

/**
 * รางวิ่ง — เลื่อนเองตามเวลา และกรอตามนิ้วเมื่อผู้ใช้ปัด (= `ScrubRunner`)
 * ตำแหน่งคิดเป็น "จำนวนรอบ" แล้วพับด้วย floor — ใช้สำเนาแค่ไม่กี่ชุด
 */
@Composable
fun ScrubRunner(d: Float, runWidth: Float, period: Double, pull: Double = 0.45, active: Boolean = true,
                copies: Int = 3, modifier: Modifier = Modifier, row: @Composable () -> Unit) {
    val previewStatic = co.salehere.starcard.ui.LocalPreviewStatic.current
    val clock = rememberSeconds(active && !previewStatic)
    val p = max(0.5, period)
    val raw = clock / p - d * pull
    val wrapped = (raw - floor(raw)).toFloat()
    Row(modifier.graphicsLayer { translationX = -runWidth * wrapped * density }) {
        repeat(max(2, copies)) { row() }
    }
}

/** นาฬิกาต่อเฟรม (วินาที) — `TimelineView(.animation)` ของ SwiftUI · หยุดเดินเมื่อ `running = false` */
@Composable
fun rememberSeconds(running: Boolean = true): Double {
    var t by remember { mutableStateOf(0.0) }
    LaunchedEffect(running) {
        if (!running) return@LaunchedEffect
        val base = t
        val start = withFrameNanos { it }
        while (true) {
            withFrameNanos { now -> t = base + (now - start) / 1_000_000_000.0 }
        }
    }
    return t
}

/** `Animatable` ที่ตั้งค่าเป้าหมายแล้วไล่ด้วยสปริงของหน้า — ทางลัดสำหรับ `withAnimation(Motion.x) { v = y }` */
@Composable
fun rememberSpringValue(initial: Float): Animatable<Float, *> = remember { Animatable(initial) }

/** `Dp` จาก pt ของดีไซน์ */
val Float.pt: Dp get() = this.dp
val Int.pt: Dp get() = this.dp
val Double.pt: Dp get() = this.toFloat().dp
