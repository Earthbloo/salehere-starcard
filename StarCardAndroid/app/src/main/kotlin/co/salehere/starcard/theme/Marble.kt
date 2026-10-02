package co.salehere.starcard.theme

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlurEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.graphics.rememberGraphicsLayer
import androidx.compose.ui.graphics.layer.drawLayer
import kotlin.math.PI
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin

// MARK: - ลายหินอ่อน (= Theme/Marble.swift)

/**
 * เรขาคณิตของแผ่นหิน — เส้นแร่ในพิกัด 0…1 ของแผ่น
 * คิดครั้งเดียวต่อเมล็ดแล้วแคชไว้ เพราะลายเดียวกันถูกวาดซ้ำหลายที่ในเฟรมเดียว และทุกที่ต้องได้ลายเดียวกัน
 */
object MarbleSlab {

    /** เส้นแร่หนึ่งเส้น — เก็บเป็นเส้นหักก่อน แล้วค่อยลากเป็นเส้นโค้งตอนวาด */
    data class Vein(
        /** พิกัด 0…1 ทั้งสองแกน — ยืดตามขนาดจริงตอนวาด */
        val pts: List<Offset>,
        /** ความหนาในหน่วยออกแบบ (แผ่นกว้าง 402) */
        val width: Float,
        val alpha: Double,
        /** เส้นหลักพาดข้ามทั้งแผ่น — ปลายไม่เรียวและไม่จาง */
        val main: Boolean,
        /** เข้าชั้น "รอยฟุ้ง" ด้วยไหม — เฉพาะเส้นแกนของมัด */
        val soft: Boolean,
        /** ความหนาที่ไม่เท่ากันตลอดเส้น — แร่จริงบวมเป็นช่วง */
        val swell: List<Float>,
        /** ความเข้มที่ไม่เท่ากันตลอดเส้น — แร่จริงจางหายเป็นช่วงแล้วโผล่ใหม่ */
        val veil: List<Double>,
    )

    /** ก้อนเมฆในเนื้อหิน — วงรีที่ถูกยืดและเอียงไปตามแนวแร่ */
    data class Cloud(val at: Offset, val r: Float, val k: Double, val stretch: Float, val lean: Double)

    /** เม็ดแร่เล็ก ๆ — จุดคมที่กระจายทั่วแผ่น */
    data class Fleck(val at: Offset, val r: Float, val k: Double)

    data class Slab(val veins: List<Vein>, val clouds: List<Cloud>, val flecks: List<Fleck>)

    private val cache = HashMap<ULong, Slab>()

    fun slab(seed: ULong): Slab = synchronized(cache) { cache.getOrPut(seed) { build(seed) } }

    /** จำนวนช่วงที่แบ่งเส้นเพื่อไล่ความหนา — น้อยกว่านี้รอยต่อเห็นเป็นข้อ มากกว่านี้เปลืองฟรี */
    const val chunks = 5

    // MARK: สร้างลาย

    /**
     * แร่ในหินอ่อนไม่ได้มาเป็นเส้นเดี่ยว มันมาเป็น "มัด" ของเส้นขนานที่เบียดกันแล้วแยกออก
     * วาดเส้นเดี่ยวเมื่อไหร่ได้ควันหรือสายไฟเรืองแสง — ไม่เป็นหิน
     */
    private fun build(seed: ULong): Slab {
        val rng = Rng(seed)
        val veins = ArrayList<Vein>()

        // ทิศหลักของแผ่น — แร่ในหินจริงเอียงไปทางเดียวกันทั้งแผ่น เพราะมันคือรอยแตกที่ถูกแรงเดียวกันบีบ
        val lean = -1.02

        /** มัดหนึ่งมัด — เส้นแกนพาดแผ่น + เส้นในมัดที่ขนานไปกับมัน + แขนงที่แตกออก */
        fun bundle(start: Offset, lean: Double, width: ClosedRange<Double>, strands: Int, steps: Int, reach: Double) {
            val a = lean + rng.range(-0.22, 0.22)
            val spine = walk(
                Offset(start.x + rng.range(-0.05, 0.05).toFloat(), start.y),
                a, steps, reach, 0.055, rng,
            )
            veins += Vein(
                pts = spine,
                width = rng.range(width.start, width.endInclusive).toFloat(),
                alpha = rng.range(0.6, 1.0),
                main = true, soft = true,
                swell = swell(chunks, 0.32, rng),
                veil = veil(chunks, 0.12, rng),
            )

            // เส้นในมัด — ก๊อปรูปทรงของแกนมาเลื่อนออกข้าง ๆ แล้วเขย่าทีละจุด (ไม่เกิน 4% ของแผ่น)
            repeat(strands) {
                val lo = (rng.range(0.0, 0.55) * (spine.size - 2).toDouble()).toInt()
                val hi = min(spine.size - 1, lo + (rng.range(0.3, 1.0) * (spine.size - 1).toDouble()).toInt())
                if (hi - lo <= 3) return@repeat
                val pts = strand(spine, lo, hi, rng.range(-0.024, 0.024), 0.008, rng)
                veins += Vein(
                    pts = pts,
                    width = rng.range(0.22, 0.62).toFloat(),
                    alpha = rng.range(0.3, 0.8),
                    main = false, soft = false,
                    swell = swell(chunks, 0.3, rng),
                    veil = veil(chunks, 0.06, rng),
                )
            }

            // แขนง — แตกออกจากมัดแล้วตายลงไปเอง ปลายเรียวและจาง
            repeat(rng.range(2.0, 3.99).toInt()) {
                val i = (rng.range(0.1, 0.9) * (spine.size - 2).toDouble()).toInt()
                val side = if (rng.d() < 0.5) -1.0 else 1.0
                val a2 = angle(spine, i) + side * rng.range(0.3, 0.8)
                val b = walk(spine[i], a2, rng.range(6.0, 16.0).toInt(), 0.026, 0.085, rng)
                veins += Vein(
                    pts = b,
                    width = rng.range(0.35, 0.7).toFloat(),
                    alpha = rng.range(0.35, 0.7),
                    main = false, soft = true,
                    swell = swell(chunks, 0.26, rng),
                    veil = veil(chunks, 0.1, rng),
                )
                // แขนงก็มีมัดของมันเอง แค่บางกว่า
                repeat(2) {
                    val pts = strand(b, 0, b.size - 1, rng.range(-0.022, 0.022), 0.008, rng)
                    veins += Vein(
                        pts = pts,
                        width = rng.range(0.2, 0.42).toFloat(),
                        alpha = rng.range(0.25, 0.55),
                        main = false, soft = false,
                        swell = swell(chunks, 0.24, rng),
                        veil = veil(chunks, 0.06, rng),
                    )
                }
            }
        }

        // ชุดรอยแตกหลัก — พาดทั้งแผ่น (stride(from: -0.3, through: 1.25, by: 0.22))
        var i = 0
        while (true) {
            val x0 = -0.3 + i * 0.22
            if (x0 > 1.25) break
            bundle(Offset(x0.toFloat(), 1.12f), lean, 0.7..1.4, 7, 46, 0.04)
            i++
        }
        // ชุดรอยแตกที่สอง — เอียงสวนอยู่นิดหนึ่ง บางกว่า จางกว่า (stride(from: -0.1, through: 1.1, by: 0.4))
        i = 0
        while (true) {
            val x0 = -0.1 + i * 0.4
            if (x0 > 1.1) break
            bundle(Offset(x0.toFloat(), 1.12f), lean + 0.42, 0.45..0.9, 5, 44, 0.038)
            i++
        }
        // รอยสั้น — เกิดแล้วจบในตัวเอง กระจายทั่วแผ่น
        repeat(12) {
            bundle(
                Offset(rng.range(-0.1, 1.1).toFloat(), rng.range(-0.05, 1.05).toFloat()),
                lean + rng.range(-0.5, 0.5), 0.35..0.8, 4, rng.range(8.0, 18.0).toInt(), 0.03,
            )
        }

        // ก้อนเมฆ — ของจริงเป็นเงาเทาจาง ๆ ที่กินพื้นที่มากกว่าเส้นแร่เสียอีก
        val clouds = List(20) {
            Cloud(
                at = Offset(rng.range(-0.15, 1.15).toFloat(), rng.range(-0.1, 1.1).toFloat()),
                r = rng.range(0.05, 0.22).toFloat(),
                k = rng.range(0.25, 0.95),
                // ยืดตามแนวแร่ — เมฆเทาในหินไม่ใช่วงกลม
                stretch = rng.range(1.5, 3.2).toFloat(),
                lean = lean + rng.range(-0.3, 0.3),
            )
        }
        val flecks = List(60) {
            Fleck(
                at = Offset(rng.d().toFloat(), rng.d().toFloat()),
                r = rng.range(0.3, 1.1).toFloat(),
                k = rng.range(0.15, 0.5),
            )
        }
        return Slab(veins, clouds, flecks)
    }

    /** เดินเส้นแบบสุ่มมีทิศ — มุมค่อย ๆ เบนไปทางเดิมสะสม ไม่ใช่สั่นรอบทิศตั้งต้น */
    private fun walk(start: Offset, a0: Double, steps: Int, step: Double, wobble: Double, rng: Rng): List<Offset> {
        val pts = ArrayList<Offset>(steps + 1)
        pts += start
        var px = start.x.toDouble()
        var py = start.y.toDouble()
        var a = a0
        var drift = 0.0
        repeat(steps) {
            drift = max(-1.0, min(1.0, drift + rng.range(-0.5, 0.5)))
            a += drift * wobble
            // หักศอกเป็นครั้งคราว — รอยแตกในหินสะดุดเป็นข้อ ๆ
            if (rng.d() < 0.22) a += rng.range(-0.34, 0.34)
            px += cos(a) * step
            py += sin(a) * step
            pts += Offset(px.toFloat(), py.toFloat())
            if (py < -0.3 || py > 1.3 || px < -0.4 || px > 1.4) return pts
        }
        return pts
    }

    /** เส้นในมัด — รูปทรงเดียวกับแกนแต่เลื่อนออกด้านข้าง และระยะเลื่อนแกว่งไปเรื่อย ๆ */
    private fun strand(pts: List<Offset>, lo: Int, hi: Int, off: Double, sway: Double, rng: Rng): List<Offset> {
        var d = off
        val out = ArrayList<Offset>(hi - lo + 1)
        for (i in lo..hi) {
            d += rng.range(-sway, sway)
            val a = angle(pts, i) + PI / 2
            out += Offset(pts[i].x + (cos(a) * d).toFloat(), pts[i].y + (sin(a) * d).toFloat())
        }
        return out
    }

    private fun angle(pts: List<Offset>, i: Int): Double {
        val j = min(i + 1, pts.size - 1)
        val h = if (j == i) max(0, i - 1) else i
        return atan2((pts[j].y - pts[h].y).toDouble(), (pts[j].x - pts[h].x).toDouble())
    }

    private fun swell(count: Int, spread: Double, rng: Rng): List<Float> =
        List(count) { (1 + rng.range(-spread, spread)).toFloat() }

    private fun veil(count: Int, floor: Double, rng: Rng): List<Double> =
        List(count) { rng.range(floor, 1.0) }

    /** สุ่มแบบกำหนดเมล็ดได้ (SplitMix64) — ลายต้องซ้ำเดิมทุกครั้ง */
    private class Rng(seed: ULong) {
        private var s: ULong = seed * 0x9E3779B97F4A7C15uL

        fun next(): ULong {
            s += 0x9E3779B97F4A7C15uL
            var z = s
            z = (z xor (z shr 30)) * 0xBF58476D1CE4E5B9uL
            z = (z xor (z shr 27)) * 0x94D049BB133111EBuL
            return z xor (z shr 31)
        }

        fun d(): Double = (next() shr 11).toDouble() * (1.0 / 9007199254740992.0)
        fun range(a: Double, b: Double): Double = a + d() * (b - a)
    }
}

// MARK: - ชั้นลายหินอ่อน

/**
 * ลายแร่บนพื้นหิน — วาดเป็นเวกเตอร์ ไม่ใช่รูป (สีพื้นเปลี่ยนได้ทุกเฉด · ไฟล์ส่งออกต้องคม)
 * สี่ชั้นซ้อนกัน เรียงจากฟุ้งสุดไปคมสุด: **เนื้อหิน** · **รอยฟุ้ง** · **ตัวเส้น** · **แกนกับเม็ดแร่**
 * แต่ละชั้นบันทึกลง `GraphicsLayer` แล้วเบลอทั้งชั้นครั้งเดียว (= `drawLayer` + `.blur` ของ SwiftUI · ต่ำกว่า API 31 ไม่เบลอ)
 */
@Composable
fun MarbleVeins(
    /** สีเส้นแร่ */
    vein: Color,
    /** สีเมฆในเนื้อหินและรอยฟุ้งรอบเส้น */
    bleed: Color,
    /** ตัวคูณความหนา — ที่ขนาดชิปเล็ก ๆ ต้องดันขึ้น ไม่งั้นลายหายไปเป็นฝุ่น */
    lineScale: Float = 1f,
    seed: ULong = 0xA17uL,
    modifier: Modifier = Modifier,
) {
    val cloudLayer = rememberGraphicsLayer()
    val softLayer = rememberGraphicsLayer()
    val bodyLayer = rememberGraphicsLayer()
    val coreLayer = rememberGraphicsLayer()
    Canvas(modifier.fillMaxSize()) {
        if (size.width < 1f || size.height < 1f) return@Canvas
        val slab = MarbleSlab.slab(seed)
        val pt = density
        val widthPt = size.width / pt
        // ความหนาอิงความกว้างของแผ่น ไม่ใช่ค่าคงที่เป็นพอยต์ — ไฟล์ส่งออกกว้างกว่าจอหลายเท่า
        val k = max(0.3f, widthPt / 402f) * lineScale * pt
        // รัศมีเบลอไม่คูณ `lineScale` — ตัวคูณนั้นมีไว้ดันเส้นให้เห็นบนชิปเล็ก ๆ
        val b = max(0.3f, widthPt / 402f) * pt
        val sz = size

        // 1) เนื้อหิน — เมฆเทายืดตามแนวแร่
        cloudLayer.record {
            for (c in slab.clouds) {
                val w = c.r * 2f * sz.width * c.stretch
                val h = c.r * 2f * sz.width
                val at = Offset(c.at.x * sz.width, c.at.y * sz.height)
                withTransform({
                    translate(at.x, at.y)
                    rotate(Math.toDegrees(c.lean).toFloat(), pivot = Offset.Zero)
                }) {
                    drawOval(bleed.opacity(c.k), topLeft = Offset(-w / 2f, -h / 2f), size = Size(w, h))
                }
            }
        }
        cloudLayer.renderEffect = BlurEffect(17f * b, 17f * b, TileMode.Clamp)
        drawLayer(cloudLayer)

        // 2) รอยฟุ้งตามแนวแร่ — เฉพาะแกนของมัด เส้นกว้างเบลอหนัก
        softLayer.record {
            for (v in slab.veins) if (v.soft) {
                strokeVein(v, sz, k * (if (v.main) 5f else 3f), bleed, 0.9, pt)
            }
        }
        softLayer.renderEffect = BlurEffect(7f * b, 7f * b, TileMode.Clamp)
        drawLayer(softLayer)

        // 3) ตัวเส้นทั้งมัด — ขอบยังนุ่ม
        bodyLayer.record {
            for (v in slab.veins) strokeVein(v, sz, k * 1.7f, vein, 0.34, pt)
        }
        bodyLayer.renderEffect = BlurEffect(1.6f * b, 1.6f * b, TileMode.Clamp)
        drawLayer(bodyLayer)

        // 4) แกนเส้นกับเม็ดแร่ — รายละเอียดที่ตาจับได้เวลามองใกล้
        coreLayer.record {
            for (v in slab.veins) strokeVein(v, sz, k * 0.8f, vein, 0.55, pt)
            for (f in slab.flecks) {
                drawOval(
                    vein.opacity(f.k),
                    topLeft = Offset(f.at.x * sz.width - f.r * k, f.at.y * sz.height - f.r * k),
                    size = Size(f.r * 2f * k, f.r * 2f * k),
                )
            }
        }
        coreLayer.renderEffect = BlurEffect(0.8f * b, 0.8f * b, TileMode.Clamp)
        drawLayer(coreLayer)
    }
}

/** ลากเส้นทีละช่วงเพื่อให้ความหนาและความเข้มไม่เท่ากันตลอดเส้น — ช่วงเหลื่อมกันหนึ่งจุดและใช้ปลายมน */
private fun DrawScope.strokeVein(v: MarbleSlab.Vein, size: Size, k: Float, color: Color, alpha: Double, pt: Float) {
    val n = v.pts.size
    if (n <= 2) return
    val chunks = MarbleSlab.chunks
    for (c in 0 until chunks) {
        val lo = c * (n - 1) / chunks
        val hi = min(n - 1, (c + 1) * (n - 1) / chunks + 1)
        if (hi - lo < 1) continue
        val t = (c + 0.5) / chunks
        // เส้นหลักพาดข้ามแผ่น ปลายมันอยู่นอกกรอบอยู่แล้ว — เรียวปลายเมื่อไหร่จะดูเหมือนเส้นที่ "จบ" กลางแผ่น
        val taper = if (v.main) 1.0 else sin(PI * t).pow(0.5)
        val fade = if (v.main) 1.0 else 0.4 + 0.6 * sin(PI * t).pow(0.6)
        val w = v.width * v.swell[c] * taper.toFloat() * k
        drawPath(
            veinPath(v.pts.subList(lo, hi + 1), size),
            color = color.opacity(alpha * v.alpha * fade * v.veil[c]),
            style = Stroke(width = max(0.2f * pt, w), cap = StrokeCap.Round, join = StrokeJoin.Round),
        )
    }
}

/** เส้นหักกลายเป็นเส้นโค้ง — ลากผ่านจุดกึ่งกลางของแต่ละคู่โดยใช้จุดจริงเป็นจุดควบคุม */
private fun veinPath(pts: List<Offset>, size: Size): Path {
    val p = pts.map { Offset(it.x * size.width, it.y * size.height) }
    val path = Path()
    path.moveTo(p[0].x, p[0].y)
    if (p.size == 2) {
        path.lineTo(p[1].x, p[1].y)
        return path
    }
    for (i in 1 until p.size - 1) {
        val mx = (p[i].x + p[i + 1].x) / 2f
        val my = (p[i].y + p[i + 1].y) / 2f
        path.quadraticTo(p[i].x, p[i].y, mx, my)
    }
    path.lineTo(p[p.size - 1].x, p[p.size - 1].y)
    return path
}

// MARK: - สีของลายหิน

/** สีเส้นแร่กับเมฆในเนื้อหิน (= tuple `marbleInk` ของ Swift) */
data class MarbleInk(val vein: Color, val bleed: Color)

/**
 * สีเส้นแร่กับเมฆในเนื้อหิน — ล้อสีพื้นที่ผู้ใช้เลือกเสมอ ไม่ใช่ชุดสีตายตัว
 * หินเข้มได้เส้นสว่าง (พอร์โตโร) · หินสว่างได้เส้นถ่านอาบเฉดเดียวกับพื้น (คาร์รารา)
 */
val CardTheme.marbleInk: MarbleInk
    get() {
        // คู่สีมีสีเดียวให้ใช้เป็นลาย — ลายหินอ่อนคือหมึกที่ซึมในกระดาษ ไม่ใช่สีที่เพิ่มเข้ามา
        duoColors?.let { c -> return MarbleInk(c.ink.opacity(0.28), c.ink.opacity(0.10)) }
        val h = backdropHue
        return when (activeInk) {
            CardInk.night -> MarbleInk(Color.White.opacity(0.26), Color.White.opacity(0.07))
            CardInk.paper -> MarbleInk(
                hsb(h, 0.16, 0.42).opacity(0.34),
                hsb(h, 0.13, 0.55).opacity(0.22),
            )
            CardInk.mist -> MarbleInk(
                hsb(h, 0.34, 0.34).opacity(0.34),
                hsb(h, 0.34, 0.48).opacity(0.24),
            )
        }
    }
