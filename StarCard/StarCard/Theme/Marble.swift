import SwiftUI

// MARK: - ลายหินอ่อน

/// เรขาคณิตของแผ่นหิน — เส้นแร่ในพิกัด 0…1 ของแผ่น
///
/// คิดครั้งเดียวต่อเมล็ดแล้วแคชไว้ เพราะลายเดียวกันถูกวาดซ้ำหลายที่ในเฟรมเดียว
/// (ฉากหลังจริง · ชิปเลือกแบบพื้น · รูปย่อในคลัง · ไฟล์ที่ส่งออก) และทุกที่ต้องได้ลายเดียวกัน
/// ไม่ใช่สุ่มใหม่ทุกครั้งที่รีเฟรช — ลายหินที่ขยับตอนเลื่อนสีคือลายที่ดูเป็นของปลอมทันที
enum MarbleSlab {

    /// เส้นแร่หนึ่งเส้น — เก็บเป็นเส้นหักก่อน แล้วค่อยลากเป็นเส้นโค้งตอนวาด
    struct Vein {
        /// พิกัด 0…1 ทั้งสองแกน — ยืดตามขนาดจริงตอนวาด
        var pts: [CGPoint]
        /// ความหนาในหน่วยออกแบบ (แผ่นกว้าง 402)
        var width: CGFloat
        var alpha: Double
        /// เส้นหลักพาดข้ามทั้งแผ่น — ต่างจากเส้นอื่นตรงที่ปลายไม่เรียวและไม่จาง
        var main: Bool
        /// เข้าชั้น "รอยฟุ้ง" ด้วยไหม — เฉพาะเส้นแกนของมัด ไม่ใช่ทุกเส้นในมัด
        /// ใส่ทุกเส้นเมื่อไหร่ รอยฟุ้งจะทับกันจนขาวโพลนทั้งแผ่น
        var soft: Bool
        /// ความหนาที่ไม่เท่ากันตลอดเส้น — แร่จริงบวมเป็นช่วง ไม่ใช่เส้นปากกาความหนาเดียว
        var swell: [CGFloat]
        /// ความเข้มที่ไม่เท่ากันตลอดเส้น — แร่จริงจางหายเป็นช่วงแล้วโผล่ใหม่
        /// ขาดตัวนี้ทุกเส้นจะเข้มเท่ากันตั้งแต่ต้นจนจบ ซึ่งเป็นลายเซ็นของเส้นที่วาดด้วยโปรแกรม
        var veil: [Double]
    }

    /// ก้อนเมฆในเนื้อหิน — วงรีที่ถูกยืดและเอียงไปตามแนวแร่
    struct Cloud {
        var at: CGPoint
        var r: CGFloat
        var k: Double
        var stretch: CGFloat
        var lean: Double
    }

    /// เม็ดแร่เล็ก ๆ — จุดคมที่กระจายทั่วแผ่น ทำให้ผิวดูเป็นหินไม่ใช่สีทา
    struct Fleck {
        var at: CGPoint
        var r: CGFloat
        var k: Double
    }

    struct Slab {
        var veins: [Vein]
        var clouds: [Cloud]
        var flecks: [Fleck]
    }

    private static var cache: [UInt64: Slab] = [:]

    static func slab(seed: UInt64) -> Slab {
        if let s = cache[seed] { return s }
        let s = build(seed: seed)
        cache[seed] = s
        return s
    }

    /// จำนวนช่วงที่แบ่งเส้นเพื่อไล่ความหนา — น้อยกว่านี้รอยต่อเห็นเป็นข้อ มากกว่านี้เปลืองฟรี
    static let chunks = 5

    // MARK: สร้างลาย

    /// # ทำไมเป็น "มัด" ไม่ใช่ "เส้น"
    ///
    /// แร่ในหินอ่อนไม่ได้มาเป็นเส้นเดี่ยว มันมาเป็นมัดของเส้นขนานที่เบียดกันแล้วแยกออก
    /// วาดเส้นเดี่ยวเมื่อไหร่ได้ควันหรือสายไฟเรืองแสง — ไม่ว่าจะเบลอดีแค่ไหนก็ไม่เป็นหิน
    /// สิ่งที่ทำให้ตาอ่านว่า "หิน" คือเส้นเล็กหลายเส้นที่ขนานกันในระยะประชิด (ดูรูปคาร์รารา)
    private static func build(seed: UInt64) -> Slab {
        var rng = Rng(seed: seed)
        var veins: [Vein] = []

        // ทิศหลักของแผ่น — แร่ในหินจริงไม่ได้วิ่งสะเปะสะปะ มันเอียงไปทางเดียวกันทั้งแผ่น
        // เพราะมันคือรอยแตกที่ถูกแรงเดียวกันบีบ · ลายที่เส้นไปคนละทางอ่านเป็น "รอยขีด" ไม่ใช่หิน
        let lean = -1.02

        /// มัดหนึ่งมัด — เส้นแกนพาดแผ่น + เส้นในมัดที่ขนานไปกับมัน + แขนงที่แตกออก
        func bundle(at start: CGPoint, lean: Double, width: ClosedRange<Double>,
                    strands: Int, steps: Int, reach: Double) {
            let a = lean + rng.range(-0.22, 0.22)
            let spine = walk(from: CGPoint(x: start.x + CGFloat(rng.range(-0.05, 0.05)), y: start.y),
                             angle: a, steps: steps, step: reach, wobble: 0.055, rng: &rng)
            veins.append(Vein(pts: spine,
                              width: CGFloat(rng.range(width.lowerBound, width.upperBound)),
                              alpha: rng.range(0.6, 1.0),
                              main: true, soft: true,
                              swell: swell(count: chunks, spread: 0.32, rng: &rng),
                              veil: veil(count: chunks, floor: 0.12, rng: &rng)))

            // เส้นในมัด — ก๊อปรูปทรงของแกนมาเลื่อนออกข้าง ๆ แล้วเขย่าทีละจุด
            // ระยะเลื่อนต้องแคบ (ไม่เกิน 4% ของแผ่น) ไม่งั้นมันแยกเป็นคนละเส้นแทนที่จะเป็นมัดเดียว
            for _ in 0..<strands {
                let lo = Int(rng.range(0, 0.55) * Double(spine.count - 2))
                let hi = min(spine.count - 1, lo + Int(rng.range(0.3, 1.0) * Double(spine.count - 1)))
                guard hi - lo > 3 else { continue }
                let pts = strand(of: spine, from: lo, to: hi,
                                 off: rng.range(-0.024, 0.024), sway: 0.008, rng: &rng)
                veins.append(Vein(pts: pts,
                                  width: CGFloat(rng.range(0.22, 0.62)),
                                  alpha: rng.range(0.3, 0.8),
                                  main: false, soft: false,
                                  swell: swell(count: chunks, spread: 0.3, rng: &rng),
                                  veil: veil(count: chunks, floor: 0.06, rng: &rng)))
            }

            // แขนง — แตกออกจากมัดแล้วตายลงไปเอง ปลายเรียวและจาง
            for _ in 0..<Int(rng.range(2, 3.99)) {
                let i = Int(rng.range(0.1, 0.9) * Double(spine.count - 2))
                let side: Double = rng.d() < 0.5 ? -1 : 1
                let a2 = angle(spine, at: i) + side * rng.range(0.3, 0.8)
                let b = walk(from: spine[i], angle: a2,
                             steps: Int(rng.range(6, 16)), step: 0.026, wobble: 0.085, rng: &rng)
                veins.append(Vein(pts: b,
                                  width: CGFloat(rng.range(0.35, 0.7)),
                                  alpha: rng.range(0.35, 0.7),
                                  main: false, soft: true,
                                  swell: swell(count: chunks, spread: 0.26, rng: &rng),
                                  veil: veil(count: chunks, floor: 0.1, rng: &rng)))
                // แขนงก็มีมัดของมันเอง แค่บางกว่า
                for _ in 0..<2 {
                    let pts = strand(of: b, from: 0, to: b.count - 1,
                                     off: rng.range(-0.022, 0.022), sway: 0.008, rng: &rng)
                    veins.append(Vein(pts: pts,
                                      width: CGFloat(rng.range(0.2, 0.42)),
                                      alpha: rng.range(0.25, 0.55),
                                      main: false, soft: false,
                                      swell: swell(count: chunks, spread: 0.24, rng: &rng),
                                      veil: veil(count: chunks, floor: 0.06, rng: &rng)))
                }
            }
        }

        // ชุดรอยแตกหลัก — พาดทั้งแผ่น
        for x0 in stride(from: -0.3, through: 1.25, by: 0.22) {
            bundle(at: CGPoint(x: x0, y: 1.12), lean: lean,
                   width: 0.7...1.4, strands: 7, steps: 46, reach: 0.04)
        }
        // ชุดรอยแตกที่สอง — เอียงสวนอยู่นิดหนึ่ง บางกว่า จางกว่า
        // หินจริงถูกบีบมากกว่าหนึ่งครั้ง รอยชุดหลังตัดผ่านชุดแรกเป็นร่างแห
        // ขาดชุดนี้ลายจะเป็นเส้นขนานเรียงกันซึ่งอ่านเป็นผ้าไหม ไม่ใช่หิน
        for x0 in stride(from: -0.1, through: 1.1, by: 0.4) {
            bundle(at: CGPoint(x: x0, y: 1.12), lean: lean + 0.42,
                   width: 0.45...0.9, strands: 5, steps: 44, reach: 0.038)
        }
        // รอยสั้น — เกิดแล้วจบในตัวเอง กระจายทั่วแผ่น
        // ลายที่มีแต่รอยยาวพาดทั้งแผ่นจะอ่านเป็นภาพวาด เพราะตาจับจังหวะซ้ำได้หมดในแวบเดียว
        for _ in 0..<12 {
            bundle(at: CGPoint(x: CGFloat(rng.range(-0.1, 1.1)), y: CGFloat(rng.range(-0.05, 1.05))),
                   lean: lean + rng.range(-0.5, 0.5),
                   width: 0.35...0.8, strands: 4, steps: Int(rng.range(8, 18)), reach: 0.03)
        }

        // ก้อนเมฆ — ของจริงเป็นเงาเทาจาง ๆ ที่กินพื้นที่มากกว่าเส้นแร่เสียอีก
        let clouds = (0..<20).map { _ in
            Cloud(at: CGPoint(x: CGFloat(rng.range(-0.15, 1.15)), y: CGFloat(rng.range(-0.1, 1.1))),
                  r: CGFloat(rng.range(0.05, 0.22)),
                  k: rng.range(0.25, 0.95),
                  // ยืดตามแนวแร่ — เมฆเทาในหินไม่ใช่วงกลม มันลากไปทางเดียวกับรอยแตก
                  stretch: CGFloat(rng.range(1.5, 3.2)),
                  lean: lean + rng.range(-0.3, 0.3))
        }
        let flecks = (0..<60).map { _ in
            Fleck(at: CGPoint(x: CGFloat(rng.d()), y: CGFloat(rng.d())),
                  r: CGFloat(rng.range(0.3, 1.1)),
                  k: rng.range(0.15, 0.5))
        }
        return Slab(veins: veins, clouds: clouds, flecks: flecks)
    }

    /// เดินเส้นแบบสุ่มมีทิศ — มุมค่อย ๆ เบนไปทางเดิมสะสม ไม่ใช่สั่นรอบทิศตั้งต้น
    /// (สั่นรอบทิศตั้งต้นได้เส้นตรงที่มีขนฟู ส่วนมุมสะสมได้เส้นที่โค้งไปจริง ๆ)
    private static func walk(from start: CGPoint, angle a0: Double, steps: Int,
                             step: Double, wobble: Double, rng: inout Rng) -> [CGPoint] {
        var pts = [start]
        var p = start
        var a = a0
        var drift = 0.0
        for _ in 0..<steps {
            drift = max(-1, min(1, drift + rng.range(-0.5, 0.5)))
            a += drift * wobble
            // หักศอกเป็นครั้งคราว — รอยแตกในหินไม่ได้โค้งเรียบเหมือนควัน มันสะดุดเป็นข้อ ๆ
            if rng.d() < 0.22 { a += rng.range(-0.34, 0.34) }
            p.x += CGFloat(cos(a) * step)
            p.y += CGFloat(sin(a) * step)
            pts.append(p)
            if p.y < -0.3 || p.y > 1.3 || p.x < -0.4 || p.x > 1.4 { break }
        }
        return pts
    }

    /// เส้นในมัด — รูปทรงเดียวกับแกนแต่เลื่อนออกด้านข้าง และระยะเลื่อนแกว่งไปเรื่อย ๆ
    /// ระยะที่คงที่เป๊ะจะได้เส้นคู่ขนานแบบรางรถไฟ ซึ่งไม่มีในธรรมชาติ
    private static func strand(of pts: [CGPoint], from lo: Int, to hi: Int,
                               off: Double, sway: Double, rng: inout Rng) -> [CGPoint] {
        var d = off
        var out: [CGPoint] = []
        out.reserveCapacity(hi - lo + 1)
        for i in lo...hi {
            d += rng.range(-sway, sway)
            let a = angle(pts, at: i) + .pi / 2
            out.append(CGPoint(x: pts[i].x + CGFloat(cos(a) * d),
                               y: pts[i].y + CGFloat(sin(a) * d)))
        }
        return out
    }

    private static func angle(_ pts: [CGPoint], at i: Int) -> Double {
        let j = min(i + 1, pts.count - 1)
        let h = j == i ? max(0, i - 1) : i
        return atan2(Double(pts[j].y - pts[h].y), Double(pts[j].x - pts[h].x))
    }

    private static func swell(count: Int, spread: Double, rng: inout Rng) -> [CGFloat] {
        (0..<count).map { _ in CGFloat(1 + rng.range(-spread, spread)) }
    }

    private static func veil(count: Int, floor: Double, rng: inout Rng) -> [Double] {
        (0..<count).map { _ in rng.range(floor, 1) }
    }

    /// สุ่มแบบกำหนดเมล็ดได้ (SplitMix64) — ต้องไม่ใช้ `Double.random` เพราะลายต้องซ้ำเดิมทุกครั้ง
    private struct Rng {
        var s: UInt64
        init(seed: UInt64) { s = seed &* 0x9E3779B97F4A7C15 }
        mutating func next() -> UInt64 {
            s &+= 0x9E3779B97F4A7C15
            var z = s
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
        mutating func d() -> Double { Double(next() >> 11) * (1.0 / 9007199254740992.0) }
        mutating func range(_ a: Double, _ b: Double) -> Double { a + d() * (b - a) }
    }
}

// MARK: - ชั้นลายหินอ่อน

/// ลายแร่บนพื้นหิน — วาดเป็นเวกเตอร์ ไม่ใช่รูป
///
/// ที่ไม่ใช้รูปลายหินสำเร็จเพราะสีพื้นของการ์ดเปลี่ยนได้ทุกเฉด ลายที่อบสีมาแล้วจะชนกับพื้นเสมอ
/// และการ์ดถูกส่งออกเป็นไฟล์ความละเอียดสูง — เส้นเวกเตอร์คมที่ทุกขนาด รูปบิตแมปไม่คม
///
/// สี่ชั้นซ้อนกัน เรียงจากฟุ้งสุดไปคมสุด: **เนื้อหิน** (เมฆเทา) · **รอยฟุ้ง** (แถบตามแนวแร่)
/// · **ตัวเส้น** (ขอบยังนุ่ม) · **แกนกับเม็ดแร่** (คม) — ตัดชั้นใดชั้นหนึ่งออกก็เหลือแค่เส้นวาด
struct MarbleVeins: View, Equatable {
    /// สีเส้นแร่
    let vein: Color
    /// สีเมฆในเนื้อหินและรอยฟุ้งรอบเส้น
    let bleed: Color
    /// ตัวคูณความหนา — ที่ขนาดชิปเล็ก ๆ ต้องดันขึ้น ไม่งั้นลายหายไปเป็นฝุ่น
    var lineScale: CGFloat = 1
    var seed: UInt64 = 0xA17

    var body: some View {
        Canvas { ctx, size in
            let slab = MarbleSlab.slab(seed: seed)
            // ความหนาอิงความกว้างของแผ่น ไม่ใช่ค่าคงที่เป็นพอยต์ — ไฟล์ส่งออกกว้างกว่าจอหลายเท่า
            // ถ้าตรึงเป็นพอยต์ ลายบนไฟล์จะกลายเป็นเส้นผมบาง ๆ ที่มองไม่เห็น
            let k = max(0.3, size.width / 402) * lineScale
            // รัศมีเบลอไม่คูณ `lineScale` — ตัวคูณนั้นมีไว้ดันเส้นให้เห็นบนชิปเล็ก ๆ
            // ถ้าเบลอโตตามไปด้วย ชิปจะกลายเป็นก้อนเทาเลอะ ๆ ที่ไม่มีเส้นให้ดูเลย
            let b = max(0.3, size.width / 402)

            // 1) เนื้อหิน — เมฆเทายืดตามแนวแร่
            ctx.drawLayer { l in
                l.addFilter(.blur(radius: 17 * b))
                for c in slab.clouds {
                    let w = c.r * 2 * size.width * c.stretch
                    let h = c.r * 2 * size.width
                    let box = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
                    let at = CGPoint(x: c.at.x * size.width, y: c.at.y * size.height)
                    let m = CGAffineTransform(rotationAngle: c.lean)
                        .concatenating(CGAffineTransform(translationX: at.x, y: at.y))
                    l.fill(Path(ellipseIn: box).applying(m), with: .color(bleed.opacity(c.k)))
                }
            }

            // 2) รอยฟุ้งตามแนวแร่ — เฉพาะแกนของมัด เส้นกว้างเบลอหนัก
            ctx.drawLayer { l in
                l.addFilter(.blur(radius: 7 * b))
                for v in slab.veins where v.soft {
                    stroke(l, v, in: size, k: k * (v.main ? 5 : 3), color: bleed, alpha: 0.9)
                }
            }

            // 3) ตัวเส้นทั้งมัด — ขอบยังนุ่ม
            ctx.drawLayer { l in
                l.addFilter(.blur(radius: 1.6 * b))
                for v in slab.veins {
                    stroke(l, v, in: size, k: k * 1.7, color: vein, alpha: 0.34)
                }
            }

            // 4) แกนเส้นกับเม็ดแร่ — รายละเอียดที่ตาจับได้เวลามองใกล้
            ctx.drawLayer { l in
                l.addFilter(.blur(radius: 0.8 * b))
                for v in slab.veins {
                    stroke(l, v, in: size, k: k * 0.8, color: vein, alpha: 0.55)
                }
                for f in slab.flecks {
                    let r = CGRect(x: f.at.x * size.width - f.r * k, y: f.at.y * size.height - f.r * k,
                                   width: f.r * 2 * k, height: f.r * 2 * k)
                    l.fill(Ellipse().path(in: r), with: .color(vein.opacity(f.k)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// ลากเส้นทีละช่วงเพื่อให้ความหนาและความเข้มไม่เท่ากันตลอดเส้น
    ///
    /// `GraphicsContext` ลากเส้นหนาเดียวต่อหนึ่ง path — ความหนาที่ไล่ขึ้นลงจึงต้องซอยเป็นช่วง
    /// ช่วงเหลื่อมกันหนึ่งจุดและใช้ปลายมน รอยต่อจึงกลืนกันสนิท
    private func stroke(_ ctx: GraphicsContext, _ v: MarbleSlab.Vein, in size: CGSize,
                        k: CGFloat, color: Color, alpha: Double) {
        let n = v.pts.count
        guard n > 2 else { return }
        let chunks = MarbleSlab.chunks
        for c in 0..<chunks {
            let lo = c * (n - 1) / chunks
            let hi = min(n - 1, (c + 1) * (n - 1) / chunks + 1)
            guard hi - lo >= 1 else { continue }
            let t = (Double(c) + 0.5) / Double(chunks)
            // เส้นหลักพาดข้ามแผ่น ปลายมันอยู่นอกกรอบอยู่แล้ว — เรียวปลายเมื่อไหร่จะดูเหมือนเส้นที่ "จบ" กลางแผ่น
            let taper = v.main ? 1.0 : pow(sin(.pi * t), 0.5)
            let fade = v.main ? 1.0 : 0.4 + 0.6 * pow(sin(.pi * t), 0.6)
            let w = v.width * v.swell[c] * CGFloat(taper) * k
            ctx.stroke(path(Array(v.pts[lo...hi]), in: size),
                       with: .color(color.opacity(alpha * v.alpha * fade * v.veil[c])),
                       style: StrokeStyle(lineWidth: max(0.2, w), lineCap: .round, lineJoin: .round))
        }
    }

    /// เส้นหักกลายเป็นเส้นโค้ง — ลากผ่านจุดกึ่งกลางของแต่ละคู่โดยใช้จุดจริงเป็นจุดควบคุม
    private func path(_ pts: [CGPoint], in size: CGSize) -> Path {
        let p = pts.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
        var path = Path()
        path.move(to: p[0])
        if p.count == 2 {
            path.addLine(to: p[1])
            return path
        }
        for i in 1..<(p.count - 1) {
            let mid = CGPoint(x: (p[i].x + p[i + 1].x) / 2, y: (p[i].y + p[i + 1].y) / 2)
            path.addQuadCurve(to: mid, control: p[i])
        }
        path.addLine(to: p[p.count - 1])
        return path
    }
}

// MARK: - สีของลายหิน

extension CardTheme {
    /// สีเส้นแร่กับเมฆในเนื้อหิน — ล้อสีพื้นที่ผู้ใช้เลือกเสมอ ไม่ใช่ชุดสีตายตัว
    ///
    /// หินเข้มได้เส้นสว่าง (พอร์โตโร) · หินสว่างได้เส้นถ่านอาบเฉดเดียวกับพื้น (คาร์รารา)
    /// เส้นขาวบนพื้นสว่างจะหายไปทั้งลาย และเส้นดำบนพื้นเข้มก็เช่นกัน — ลายจึงต้องกลับขั้วตามหมึก
    var marbleInk: (vein: Color, bleed: Color) {
        // คู่สีมีสีเดียวให้ใช้เป็นลาย — ลายหินอ่อนคือหมึกที่ซึมในกระดาษ ไม่ใช่สีที่เพิ่มเข้ามา
        if let c = duoColors { return (c.ink.opacity(0.28), c.ink.opacity(0.10)) }
        let h = backdropHue
        switch activeInk {
        case .night:
            return (.white.opacity(0.26), .white.opacity(0.07))
        case .paper:
            return (Color(hue: h, saturation: 0.16, brightness: 0.42).opacity(0.34),
                    Color(hue: h, saturation: 0.13, brightness: 0.55).opacity(0.22))
        case .mist:
            return (Color(hue: h, saturation: 0.34, brightness: 0.34).opacity(0.34),
                    Color(hue: h, saturation: 0.34, brightness: 0.48).opacity(0.24))
        }
    }
}
