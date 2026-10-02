import SwiftUI

/// โทเคนการเคลื่อนไหวของทั้งแอป
///
/// ใช้ `interpolatingSpring(stiffness:damping:)` ไม่ใช่ easing เพราะ easing มี "เวลาจบ" ที่ตายตัว
/// พอโดนขัดกลางคัน (ผู้ใช้ปัดซ้ำก่อนอันเก่าจบ) มันจะกระตุก ส่วนสปริงรับ velocity ต่อได้ทันที
/// ซึ่งคือเหตุผลที่งานสาย Framer รู้สึกลื่นกว่า — ไม่ใช่เพราะช้ากว่าหรือเร็วกว่า
enum Motion {
    /// ตอบสนองทันที เด้งน้อย — ใช้กับปุ่ม ป้าย การเลือก
    static let snap = Animation.interpolatingSpring(stiffness: 380, damping: 30)
    /// ไหลนุ่ม — ใช้กับการจัดเรียงใหม่ของ widget
    static let flow = Animation.interpolatingSpring(stiffness: 240, damping: 26)
    /// เด้งชัด — ใช้ตอนการ์ดลอยขึ้นติดนิ้ว
    static let lift = Animation.interpolatingSpring(stiffness: 460, damping: 21)
    /// หนักแน่น — ใช้ตอนเปลี่ยนหน้า · **จังหวะเดียวของทั้งการเปลี่ยนหน้า**
    /// ท่าทุกชิ้น (ทั้งระดับหน้าและระดับชิ้นส่วนใน widget) ไหลด้วยสปริงตัวนี้ตัวเดียว
    /// ห้ามให้ชิ้นไหนถือ animation ของตัวเอง ไม่งั้นขากลับจะไม่ใช่ภาพย้อนของขาไป
    static let page = Animation.interpolatingSpring(stiffness: 190, damping: 24)
    /// เข้าที่อย่างสงบ — ใช้กับการเข้า/ออกโหมดแต่ง
    static let settle = Animation.interpolatingSpring(stiffness: 260, damping: 28)

    /// หน่วงไล่ทีละชิ้น — ทำให้เนื้อหา "ไหลเข้ามา" แทนที่จะโผล่พรึ่บพร้อมกัน
    static func stagger(_ i: Int, step: Double = 0.045, cap: Double = 0.45) -> Double {
        min(Double(i) * step, cap)
    }
}

// MARK: - เข้า/ออกฉากต่อ widget (สไตล์ Framer)

/// สถานะปลายทางของเอฟเฟกต์หนึ่งจังหวะ — identity คือ "อยู่ในที่ของมัน"
/// ไม่มีเบลอโดยเจตนา: ภาษาเดียวกันทั้งชุดคือ "การเคลื่อนที่เชิงเรขาคณิต" (เลื่อน หมุน พลิก ย่อ)
struct MotionFX {
    var opacity: Double = 1
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    var scale: CGFloat = 1
    /// หมุนบนระนาบ (องศา)
    var rotZ: Double = 0
    /// เอียงพ้นระนาบรอบแกนนอน (องศา)
    var rotX: Double = 0
    /// พลิกรอบแกนตั้ง (องศา) — page-turn / cover-flow
    var rotY: Double = 0

    static let identity = MotionFX()

    /// ท่าเดียวกันแต่กลับด้าน — ใช้กับฝั่งซ้าย (d < 0)
    ///
    /// กลับเครื่องหมายเฉพาะองค์ประกอบที่ "มีทิศ" (เลื่อนแนวนอน · หมุนรอบแกนตั้ง · หมุนบนระนาบ)
    /// ส่วน scale/opacity/แนวตั้ง ไม่มีทิศ จึงเท่ากันทั้งสองฝั่ง
    /// นี่คือกติกาที่ทำให้ "ไปยังไง ย้อนยังงั้น" เป็นจริงโดยโครงสร้าง ไม่ใช่โดยการจูนมือ
    var mirrored: MotionFX {
        var m = self
        m.dx = -dx
        m.rotY = -rotY
        m.rotZ = -rotZ
        return m
    }
}

/// ท่าหนึ่งแบบของ widget — เก็บแค่ "ท่าสุดขั้วตอนอยู่ห่างหนึ่งหน้าเต็มทางขวา"
///
/// ฝั่งซ้ายไม่ได้เก็บแยก แต่ใช้ `mirrored` ของท่าเดียวกัน — จงใจให้ **ไม่มีทางตั้งค่าให้ขาไป
/// กับขากลับต่างกันได้** เพราะโจทย์คือวิดีโอกรอกลับ ไม่ใช่สองอนิเมชันที่บังเอิญคล้ายกัน
struct EntranceStyle {
    /// ท่าที่ |d| = 1 (ฝั่ง d > 0) — ฝั่ง d < 0 ใช้ภาพกระจกของท่านี้
    let pose: MotionFX
    /// จังหวะเข้าฉากครั้งแรกตอนเปิดแอปเท่านั้น — การเปลี่ยนหน้าใช้ `Motion.page` ตัวเดียว
    let intro: Animation

    // ภาษาบานเกล็ด (louver): ทุกชิ้น "พลิกอยู่ในช่องของตัวเอง" รอบแกนกลางแนวตั้ง
    // ไม่มีชิ้นไหนเคลื่อนออกจากตำแหน่ง — จึงทับกันไม่ได้โดยโครงสร้าง
    // ความรู้สึกเดินทางให้ parallax ระดับหน้าเป็นคนเล่า · ความลึกต่างกันที่องศาพลิกและสเกล

    /// ชั้นลึกสุด — ภาพใหญ่: พลิกชัด ย่อชัด จมลงเล็กน้อย
    static let deep = EntranceStyle(
        pose: MotionFX(dy: 18, scale: 0.88, rotY: 44),
        intro: .interpolatingSpring(stiffness: 170, damping: 24))

    /// ชั้นกลาง — แผ่นข้อมูล: พลิกพอรู้สึก
    static let mid = EntranceStyle(
        pose: MotionFX(dy: 10, scale: 0.94, rotY: 26),
        intro: .interpolatingSpring(stiffness: 230, damping: 25))

    /// ชั้นเบา — ตัวหนังสือ/ชิป: พลิกเงา ๆ อย่างสงบ
    static let light = EntranceStyle(
        pose: MotionFX(dy: 5, scale: 0.975, rotY: 13),
        intro: .interpolatingSpring(stiffness: 280, damping: 26))

    /// **ตัวยึด** — สำหรับ widget ที่มีท่าเป็นของตัวเองข้างใน (ดู `PageScrub`)
    ///
    /// ระดับกรอบต้องแทบไม่ขยับ ไม่งั้นท่าข้างในจะถูก transform ซ้อนอีกชั้นจนอ่านไม่ออก
    /// เหลือไว้แค่ความลึกบาง ๆ พอให้รู้ว่ากรอบก็เดินทางไปด้วย
    static let anchored = EntranceStyle(
        pose: MotionFX(dy: 6, scale: 0.97),
        intro: .interpolatingSpring(stiffness: 210, damping: 25))
}

extension MotionFX {
    /// ไล่ค่าระหว่างสองท่าตามสัดส่วน t (0 = a · 1 = b) — หัวใจของการสครับตามนิ้ว
    static func lerp(_ a: MotionFX, _ b: MotionFX, _ t: CGFloat) -> MotionFX {
        let k = Double(t)
        func f(_ x: Double, _ y: Double) -> Double { x + (y - x) * k }
        func g(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x + (y - x) * t }
        return MotionFX(opacity: f(a.opacity, b.opacity),
                        dx: g(a.dx, b.dx), dy: g(a.dy, b.dy),
                        scale: g(a.scale, b.scale),
                        rotZ: f(a.rotZ, b.rotZ), rotX: f(a.rotX, b.rotX),
                        rotY: f(a.rotY, b.rotY))
    }
}

extension WidgetKind {
    /// ความลึกของ widget ในสำรับ
    ///
    /// กติกา: **ตัวที่มีท่าเป็นของตัวเองข้างในต้องได้ `anchored`** เพราะกรอบกับข้างในเล่นพร้อมกัน
    /// แล้วท่าจะซ้อนกันจนอ่านไม่ออก — กรอบเป็นแค่กล้อง ตัวแสดงคือชิ้นส่วนข้างใน
    var entranceStyle: EntranceStyle {
        switch self {
        // ท่าอยู่ข้างในทั้งหมด — บานเกล็ด · ฟิล์ม · แถบวิ่ง · มิเตอร์ · ตารางกวาด
        case .proofWork, .workFeatured, .workReel, .artDuo, .artPair, .artFilmstrip, .proofBrandGrid,
             .typeMarquee, .proofBrandRail, .statGiant, .artTypeOver,
             // โปสเตอร์คัตเอาต์ — สามระนาบเดินคนละอัตราอยู่ข้างในแล้ว
             // ถ้ากรอบขยับด้วย ความต่างของอัตราจะถูกกลบ แล้วความลึกที่ทั้งแบบมีอยู่ก็หายไป
             .artPortfolio,
             // โปสเตอร์สายงาน — สองปีกวิ่งออกคนละทางอยู่ข้างในแล้ว กรอบต้องนิ่ง
             .nichePoster,
             // โปสเตอร์ผู้ติดตาม — พาดหัวไถล ตัวเลขถอดทีละหลัก เส้นคาดหุบเข้าหาตัวเอง
             // ทั้งหมดอยู่ข้างในแล้ว กรอบต้องนิ่ง ไม่งั้นท่าถูก transform ซ้อน
             .statPoster,
             // ตั๋วผลงาน — ท่าฉีกตามรอยปรุอยู่ข้างในแล้ว กรอบต้องนิ่ง
             .proofTicket,
             // ชุดใหม่อ่าน `pageScrub` เองทุกตัว (สรุปปี · ตู้ถ่ายรูป · แชท · สติกเกอร์)
             // กรอบจึงต้องนิ่ง ไม่งั้นท่าข้างในถูก transform ซ้อน
             .statWrapped, .artPhotobooth,
             .stickerTags,
             // สำรับรอบสอง — ทุกตัวอ่าน `pageScrub` เองทั้งหมด
             // (แถบสัดส่วนกวาด · ป้ายราคาแกว่ง · มิเตอร์ถอดหลัก)
             // กรอบต้องนิ่ง ไม่งั้นท่าข้างในถูก transform ซ้อนจนอ่านไม่ออก
             .rateTags,
             // ป้ายไฟ — หลอดดับไล่ทีละดวงอยู่ข้างในทั้งหมด กรอบต้องนิ่ง
             .rateNeon,
             .contactCard, .contactQR,
             .contactBar, .contactStack, .contactLine, .contactChips,
             // โปสเตอร์ติดต่อ — สามระนาบเดินคนละอัตราอยู่ข้างในแล้ว กรอบต้องนิ่ง
             .contactPoster,
             // ตรารับรอง — วงตัวอักษรหมุน ฟอยล์รับแสงตามนิ้วอยู่ข้างในแล้ว กรอบต้องนิ่ง
             .proofSeal,
             .audienceLine, .audienceSplit, .audienceAge, .audienceMap,
             // โปสเตอร์อินไซต์ — แผ่นข้อมูลโผล่ไล่กัน แท่งหดเข้าแกนอยู่ข้างในแล้ว กรอบต้องนิ่ง
             .audiencePoster,
             // สำรับกองรูป — ทั้งแปดตัวมีท่าประจำวัสดุอยู่ข้างใน (ลอกใบบน · ฟิล์มเดินเฟรม ·
             // สองคอลัมน์ไหลสวนกัน · กวาดทแยง · สไลด์เดินใบ · แถบสตอรี่เติมตามนิ้ว)
             // กรอบต้องนิ่ง ไม่งั้นท่าข้างในถูก transform ซ้อนจนอ่านไม่ออก
             .galleryStack, .galleryCarousel, .galleryMasonry, .galleryMosaic,
             .galleryPost, .galleryStory, .galleryFilm, .galleryTape,
             // สำรับบรรณาธิการ — ทุกใบมีขบวนของตัวเองข้างใน (ฟิล์มล้มทีละใบ ·
             // การ์ดขั้นตอนพลิกไล่ · บรรทัดมุดใต้ขอบตัวเอง) กรอบจึงต้องนิ่ง
             .wallPolaroid, .wallMemory, .zineCover, .aboutEditorial, .aboutBehind,
             .flowCards,
             // แผ่นโชว์คลิป — เครื่องสี่เครื่องพลิกไล่กันอยู่ข้างในแล้ว กรอบต้องนิ่ง
             .reelShowcase,
             // สำรับหน้าต่าง — ตัวเลขถอดทีละหลัก คำยักษ์ไถลหลังคนอยู่ข้างในแล้ว กรอบต้องนิ่ง
             .socialWindow, .portfolioWindow,
             // สำรับผ้าปิกนิก — ท่าเดียวกับสำรับหน้าต่าง
             .socialGingham, .portfolioGingham:
            return .anchored
        // ภาพใหญ่ก้อนเดียว — กรอบพาเดินทางเอง
            return .deep
        // แผ่นข้อมูล — สำรับสติกเกอร์ไม่มีท่าข้างใน กรอบพาไปทั้งแผ่นเหมือนกระดาษที่ถูกปลิว
        case .proofBrandCoins, .socialChips, .socialTiles,
             .interestTags, .nicheTags,
             .popHeroPaper, .popHeroGlass, .popVideoPaper, .popVideoGlass,
             .popStatsGlass, .popWorkPaper, .popWorkGlass,
             .popRatePaper, .popRateGlass, .popNichePaper, .popNicheGlass,
             .popContactPaper, .popContactGlass,
             // สำรับสแครปบุ๊ก — แผ่นกระดาษนิ่ง ๆ กรอบพาไปทั้งแผ่น
             .scrapFolder, .scrapBadge, .scrapKeyTab, .scrapFeed, .scrapTags, .scrapAbout, .scrapInfo,
             .scrapReceipt, .scrapStats, .scrapStamp, .scrapPhones, .scrapChat, .scrapNote, .scrapLabel:
            return .mid
        // ตัวหนังสือล้วน
        case .heroMinimal, .aboutText, .textBlock:
            return .light
        }
    }
}

/// ท่าเข้า-ออกที่ "สครับตามนิ้ว" — คำนวณจากระยะหน้า `d` ตรง ๆ แบบ scroll-linked ของ Framer
///
/// `d` = i - (index + swipe): ฝั่งขวา (d > 0) คือยังไม่มาถึง · ฝั่งซ้าย (d < 0) คือผ่านไปแล้ว
/// ลากช้าเห็นช้า หยุดกลางทางค้างกลางท่า ปล่อยนิ้วแล้วค่าไหลตามสปริงของหน้าเอง
/// ชิ้นที่อยู่ลึกตามลำดับ (order) จะ "ตามหลังนิ้ว" — ออกทีหลัง และกลับเข้ามาก่อน
///
/// ท่าเป็นฟังก์ชันของ `d` ล้วน ไม่มีสถานะระหว่างทาง: ปัดไปครึ่งทางแล้วดึงกลับ
/// ภาพจะถอยตามนิ้วทุกเฟรมเป๊ะ ๆ เหมือนกรอวิดีโอกลับ
struct PageChoreo: ViewModifier, Animatable {
    let kind: WidgetKind
    let order: Int
    /// true = ห้ามใช้ 3D transform (พื้นผิวกระจก — โดนหมุนพ้นระนาบแล้ว Liquid Glass
    /// หยุด sample พื้นหลัง ตกเป็นแผ่นเข้ม) — แปลงเป็นเอียงในระนาบ + ย่อแทน
    let flat: Bool
    var d: CGFloat

    /// เข้าฉากครั้งแรกตอนเปิดแอป — หลังจากนั้นทุกอย่างเป็นสครับล้วน
    /// เกิดมาพร้อมค่าจริงตั้งแต่เฟรมแรก ไม่รอ onAppear ไม่งั้นหน้าที่เพิ่งเข้าระยะจะแว้บ
    @State private var intro: Bool

    init(kind: WidgetKind, order: Int, flat: Bool, d: CGFloat) {
        self.kind = kind
        self.order = order
        self.flat = flat
        self.d = d
        _intro = State(initialValue: abs(d) >= 0.5)
    }

    /// หัวใจของ "ปล่อยแล้วท่ายังเล่นตาม": ให้สปริงไล่ค่า d ผ่านทุกเฟรม
    /// ไม่งั้น SwiftUI จะ interpolate แค่ค่าปลายทางของ modifier — ทุกชิ้นไหลเข้าพร้อมกัน
    /// เป็นแผ่นแข็ง เส้นทางท่าและขบวน stagger หายหมดตอนหน้าเด้งเข้าที่
    var animatableData: CGFloat {
        get { d }
        set { d = newValue }
    }

    func body(content: Content) -> some View {
        let fx = currentFX
        content
            .rotation3DEffect(.degrees(fx.rotX), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            // แกนกลางตัวเอง — พลิกในช่อง ไม่ยื่นออกไปทับเพื่อนบ้าน
            .rotation3DEffect(.degrees(fx.rotY), axis: (x: 0, y: 1, z: 0),
                              anchor: .center, perspective: 0.55)
            .rotationEffect(.degrees(fx.rotZ))
            .scaleEffect(fx.scale)
            .opacity(fx.opacity)
            .offset(x: fx.dx, y: fx.dy)
            .onAppear {
                guard abs(d) < 0.5, !intro else { intro = true; return }
                // ข้าม run loop ไม่งั้น SwiftUI ยุบสองสถานะเป็นเฟรมเดียว แล้วไม่เห็นจังหวะเข้า
                DispatchQueue.main.async {
                    withAnimation(kind.entranceStyle.intro.delay(Motion.stagger(order))) {
                        intro = true
                    }
                }
            }
    }

    private var currentFX: MotionFX {
        let style = kind.entranceStyle
        guard intro else {
            var start = style.pose
            start.opacity = 0
            return flatten(start)
        }

        let c = max(-1, min(1, d))
        guard c != 0 else { return .identity }
        // ท่าฝั่งซ้ายคือภาพกระจกของฝั่งขวาเสมอ — ขาไปกับขากลับจึงเป็นเส้นเดียวกันกลับด้าน
        let pose = c > 0 ? style.pose : style.pose.mirrored
        // ชิ้นหลังตามหลังนิ้วจริง ๆ — เป็น "ออกตัวช้ากว่า" ไม่ใช่ "วิ่งเร็วกว่า"
        // (ของเดิมคูณ t ให้โตขึ้น ซึ่งกลับด้าน: ชิ้นท้ายหายก่อน แถมตันที่ |d| = 0.77
        //  ทำให้ช่วงท้ายของการปัดภาพค้างนิ่ง ไม่ตอบนิ้ว)
        // ไม่ ease ที่ระดับกรอบ — กรอบต้องเกาะนิ้วเป็นเส้นตรง โค้งเป็นหน้าที่ของชิ้นส่วนข้างใน
        let t = Scrub.t(c, lead: min(Double(order) * 0.07, 0.3))

        var fx = MotionFX.lerp(.identity, pose, t)
        // จางเฉพาะโค้งท้าย — ปัดสั้น ๆ คือการเคลื่อนที่ล้วน ไม่มีอะไรเลือนหาย
        // ตามภาษางาน perspective/stair ของสาย awwwards: เรขาคณิตนำ opacity ตาม
        fx.opacity = Scrub.fade(t, after: 0.6)
        return flatten(fx)
    }

    /// พื้นกระจก: แปลงองศาพ้นระนาบเป็น "เอียงในระนาบ + ย่อ"
    ///
    /// `rotationEffect` เป็น affine 2 มิติ กระจกยัง sample พื้นหลังได้ตามปกติ
    /// ต่างจาก `rotation3DEffect` ที่ทำให้ Liquid Glass ตกเป็นแผ่นเข้มทันที
    /// (ของเดิมแปลงเป็นสเกลอย่างเดียว หาร 900 — ชั้น light เหลือย่อ 1.8% คือแทบไม่มีท่า)
    private func flatten(_ fx: MotionFX) -> MotionFX {
        guard flat else { return fx }
        var f = fx
        f.scale -= CGFloat(abs(f.rotY) + abs(f.rotX)) / 900
        f.rotZ += f.rotY / 22
        f.rotX = 0
        f.rotY = 0
        return f
    }
}

// MARK: - สครับระดับชิ้นส่วนใน widget

/// ระยะหน้าที่ส่งลงไปถึง "ข้างใน" widget
///
/// ระดับกรอบ (`PageChoreo`) เล่าได้แค่ว่ากล่องเดินทาง — ตัวที่ทำให้การเปลี่ยนหน้าเป็นงานออกแบบ
/// คือชิ้นส่วนข้างในที่เล่นคนละจังหวะกัน widget จึงต้องรู้ `d` ด้วยตัวเอง
struct PageScrub: Equatable {
    /// -1…1 · > 0 = หน้านี้อยู่ทางขวา (ยังไม่มาถึง) · < 0 = ผ่านไปทางซ้ายแล้ว
    var d: CGFloat = 0
    /// ลำดับของ widget ในหน้า — ใช้หน่วงเป็นขบวน
    var order: Int = 0
    /// พื้นผิวกระจก — ห้าม 3D transform ที่ "ตัวแผ่นกระจกเอง"
    /// (ชิ้นส่วนทึบข้างในพลิกได้ตามปกติ เพราะแผ่นกระจกไม่ได้ถูก transform ไปด้วย)
    var flat: Bool = false

    static let still = PageScrub()
}

private struct PageScrubKey: EnvironmentKey {
    static let defaultValue = PageScrub.still
}

extension EnvironmentValues {
    /// ค่าเริ่มต้นคือ "นิ่ง" — พรีวิวในตู้ widget และชั้นลอยตอนลาก จึงไม่ติดท่าเปลี่ยนหน้าไปด้วย
    var pageScrub: PageScrub {
        get { self[PageScrubKey.self] }
        set { self[PageScrubKey.self] = newValue }
    }
}

/// คณิตกลางของทุกท่าในระดับชิ้นส่วน
///
/// กติกาเหล็ก 3 ข้อ ที่ทำให้ "ขาไป = ขากลับกรอกลับ" เป็นจริง:
/// 1. ความคืบหน้าคิดจาก `|d|` เท่านั้น (ฟังก์ชันคู่) — ซ้ายขวาเดินเส้นเดียวกัน
/// 2. ทิศคิดจาก `sign(d)` เท่านั้น (ฟังก์ชันคี่) — สลับข้างคือสลับเครื่องหมาย ไม่ใช่สลับสูตร
/// 3. ไม่มีชิ้นไหนถือ `withAnimation` ของตัวเอง — ทุกชิ้นถูกไล่ค่าด้วยสปริงของหน้าตัวเดียว
enum Scrub {
    /// ทิศเดินทาง +1 / -1
    static func dir(_ d: CGFloat) -> CGFloat { d < 0 ? -1 : 1 }

    /// ความคืบหน้าของท่า 0…1
    /// - Parameter lead: ยอมให้ "อยู่นิ่งก่อน" กี่ส่วนของทาง
    ///   ชิ้นที่ lead มาก = ออกจากฉากทีหลัง และกลับเข้ามาก่อน (ขากลับกลับลำดับให้เอง)
    static func t(_ d: CGFloat, lead: Double = 0) -> CGFloat {
        let a = min(1, abs(d))
        let l = CGFloat(max(0, min(0.85, lead)))
        return max(0, min(1, (a - l) / max(0.0001, 1 - l)))
    }

    /// โค้งนุ่มหัวท้าย (smoothstep) — ใช้เส้นเดียวกันทั้งสองขา จึงยังย้อนได้เป๊ะ
    static func ease(_ t: CGFloat) -> CGFloat { t * t * (3 - 2 * t) }

    /// **ลำดับที่กลับด้านเองตามทิศ** — หัวใจของขบวนที่ย้อนได้
    ///
    /// ชิ้นที่อยู่ "ต้นทาง" ของการเดินทางไปก่อนเสมอ ปัดกลับก็คลี่กลับตามลำดับตรงข้าม
    /// โดยไม่ต้องเขียนสองสูตร — ผูกกับ `sign(d)` ล้วน
    static func lead(_ i: Int, of n: Int, d: CGFloat, step: Double = 0.13) -> Double {
        guard n > 1 else { return 0 }
        let k = d < 0 ? i : (n - 1 - i)
        return Double(k) * step
    }

    /// ความจางช่วงท้าย — เรขาคณิตนำ opacity ตาม
    static func fade(_ t: CGFloat, after: Double = 0.55) -> Double {
        let a = max(0.01, min(0.99, after))
        return max(0, min(1, 1 - (Double(t) - a) / (1 - a)))
    }

    /// ไล่ค่าเชิงเส้น
    static func mix(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    /// **มิเตอร์ไล่ทีละช่อง** — ค่าความสว่างของช่องที่ `i` เมื่อขบวนดับไล่จากฝั่งที่หน้ากำลังไป
    /// คืน 1 = ยังเต็ม · 0 = ดับแล้ว
    static func cell(_ i: Int, of n: Int, d: CGFloat, lead: Double = 0, spill: Double = 1) -> Double {
        guard n > 0 else { return 0 }
        let t = Double(t(d, lead: lead))
        let k = Double(d < 0 ? (n - 1 - i) : i)
        let span = Double(n) + spill
        return max(0, min(1, (1 - t) * span - k))
    }
}

// MARK: - สะพานสำหรับท่าที่วาดเอง

/// ให้ค่าที่คำนวณเองไหลตามสปริงของหน้าได้
///
/// ข้อจำกัดที่ต้องรู้: `\.pageScrub` เป็น environment ซึ่ง **ไม่ interpolate**
/// ตอนปล่อยนิ้ว `d` จะกระโดดไปค่าปลายทางทันที ท่าที่คำนวณใน `body` ของ widget ตรง ๆ
/// จึงตัดวาบแทนที่จะไหล — ค่าที่ขับท่าได้จริงต้องอยู่ใน `Animatable` เท่านั้น
///
/// ตัวนี้คือทางออกสำหรับท่าที่ modifier สำเร็จรูปทำไม่ได้ (วงแหวน · ดาว · ตารางกวาด · เกรเดียนต์)
///
/// - Warning: ห้ามส่ง `d` ที่ได้จาก closure นี้ต่อเข้าไปใน `Animatable` ตัวอื่น
///   (สปริงไล่สปริงแล้วท่าจะหน่วง) — ตัวลูกต้องรับ `scrub.d` ดิบเสมอ
struct ScrubReader<Content: View>: View, Animatable {
    var d: CGFloat
    @ViewBuilder var content: (CGFloat) -> Content

    var animatableData: CGFloat {
        get { d }
        set { d = newValue }
    }

    var body: some View { content(d) }
}

// MARK: - ท่ามาตรฐาน

/// **บานเกล็ด** — ช่องมองหุบ ของข้างในไม่ขยับ
///
/// นี่คือแกนของภาษาทั้งชุด: ปกติเวลาเปลี่ยนหน้า "ของ" ถูกย่อ/เลื่อน/จางออกไป
/// ท่านี้กลับกัน — ของอยู่นิ่งคมชัดเท่าเดิม แต่ **หน้าต่างที่มองมันแคบลงจนหาย**
/// สายตาจึงอ่านว่ามีวัตถุจริงอยู่หลังผนัง ไม่ใช่ภาพแบนที่ถูกดันหลุดจอ
///
/// หุบจากฝั่งที่หน้ากำลังมุ่งไป — ปัดซ้ายกินจากซ้าย ปัดกลับคายคืนทางซ้าย
struct ScrubAperture: ViewModifier, Animatable {
    var d: CGFloat
    var lead: Double = 0
    /// ความนุ่มของรอยตัด เป็นสัดส่วนของความกว้าง — ขอบคมเกินอ่านเป็น "โดนครอป" ไม่ใช่ "โดนบัง"
    var feather: CGFloat = 0.16
    /// ความมืดที่ไหลเข้ามาช่วงท้าย — ของเดินเข้าเงาข้างเวที
    var dim: Double = 0.5

    var animatableData: CGFloat {
        get { d }
        set { d = newValue }
    }

    func body(content: Content) -> some View {
        let t = Scrub.ease(Scrub.t(d, lead: lead))
        let fromLeading = d < 0
        content
            // มืดทีหลัง (หลัง 45%) — ปัดสั้น ๆ ต้องเป็นเรขาคณิตล้วน ไม่มีอะไรหม่นลงเปล่า ๆ
            .overlay(Color.black.opacity(dim * Double(max(0, t - 0.45) / 0.55)))
            .mask { curtain(t, fromLeading: fromLeading) }
    }

    private func curtain(_ t: CGFloat, fromLeading: Bool) -> some View {
        let f = max(0.001, min(0.5, feather))
        let edge = fromLeading ? t : 1 - t
        let stops: [Gradient.Stop] = fromLeading
            ? [.init(color: .clear, location: 0),
               .init(color: .clear, location: max(0, edge - f)),
               .init(color: .black, location: min(1, edge)),
               .init(color: .black, location: 1)]
            : [.init(color: .black, location: 0),
               .init(color: .black, location: max(0, edge)),
               .init(color: .clear, location: min(1, edge + f)),
               .init(color: .clear, location: 1)]
        return Rectangle()
            .fill(LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing))
    }
}

/// **ม่านบรรทัด** — ตัวหนังสือไถลลงลอดใต้ขอบกล่องของตัวเอง
///
/// ไม่ใช้การจางเป็นหลัก เพราะคำที่จางหายอ่านเป็น "โหลดไม่ทัน"
/// ส่วนคำที่ไถลลงใต้ขอบอ่านเป็น "ไตเติ้ลหนัง" — เจตนาชัดกว่ากันมาก
struct ScrubVeil: ViewModifier, Animatable {
    var d: CGFloat
    var lead: Double = 0
    /// ระยะไถลลง — ต้องมากกว่าความสูงบรรทัดเล็กน้อยถึงจะหายหมดพอดีที่ปลายทาง
    var drop: CGFloat = 20
    /// ระยะถูกดึงสวนทางเล็กน้อย — บอกทิศโดยไม่ต้องเห็นทั้งบรรทัดวิ่ง
    var pull: CGFloat = 10

    var animatableData: CGFloat {
        get { d }
        set { d = newValue }
    }

    func body(content: Content) -> some View {
        let t = Scrub.ease(Scrub.t(d, lead: lead))
        let s = Scrub.dir(d)
        content
            .offset(x: -s * pull * t, y: drop * t)
            .opacity(Scrub.fade(t, after: 0.55))
            // ตัดที่กรอบเดิมของตัวเอง — บรรทัดจึงมุดหายใต้ขอบ ไม่ไปโผล่ทับของข้างล่าง
            .mask { Rectangle() }
    }
}

/// **กล้องดอลลี่** — ภาพในกรอบเลื่อนสวนทางหน้า พร้อมดันเข้าหาเลนส์เล็กน้อย
///
/// กรอบเดินไปกับหน้า แต่ภาพข้างในถ่วงไว้ ตาจึงอ่านว่ากรอบคือ "ช่องหน้าต่าง"
/// และภาพคือของที่อยู่ไกลออกไป — ความลึกจริงที่ opacity หรือ scale ให้ไม่ได้
///
/// `zoom` ต้องมากพอจะปิดรอยที่เกิดจาก `shift` (โดยคร่าว ≥ 2 × shift ÷ ความกว้างกรอบ)
/// ไม่งั้นจะเห็นขอบว่างโผล่ที่ริมภาพตอนสครับไปสุด
struct ScrubDolly: ViewModifier, Animatable {
    var d: CGFloat
    var shift: CGFloat
    var zoom: CGFloat = 0.16
    var lead: Double = 0

    var animatableData: CGFloat {
        get { d }
        set { d = newValue }
    }

    func body(content: Content) -> some View {
        // ไม่ ease — กล้องต้องเกาะนิ้วเป็นเส้นตรง ถ้าใส่โค้งจะรู้สึกว่าภาพ "ตามไม่ทัน"
        let t = Scrub.t(d, lead: lead)
        let s = Scrub.dir(d)
        content
            .scaleEffect(1 + zoom * t)
            .offset(x: -s * shift * t)
    }
}

/// **บานพับเดี่ยว** — ชิ้นหนึ่งพลิกอยู่ในช่องของตัวเอง
///
/// ต่างจากบานเกล็ดตรงที่ตัว "ของ" พลิกจริง ไม่ใช่หน้าต่างหุบ — ใช้กับของที่มีหน้าเดียว
/// อย่างโลโก้หรือแผ่นไอคอน ซึ่งการเห็นมันหันข้างคือความหมายในตัวเอง
///
/// หรี่ด้วย `brightness/saturation` ไม่ใช่แผ่นดำทับ เพราะฟิลเตอร์สีเคารพรูปทรงที่ clip ไว้แล้ว
/// (แผ่นทับจะโผล่มุมเหลี่ยมออกมานอกมุมมนของแผ่นโลโก้)
struct ScrubLouver: ViewModifier, Animatable {
    var d: CGFloat
    var lead: Double = 0
    var angle: Double = 62
    var shrink: CGFloat = 0.12
    /// พื้นผิวกระจก — เปลี่ยนเป็นเอียงในระนาบแทนการพลิกพ้นระนาบ
    var flat: Bool = false

    var animatableData: CGFloat {
        get { d }
        set { d = newValue }
    }

    func body(content: Content) -> some View {
        let t = Scrub.ease(Scrub.t(d, lead: lead))
        let s = Double(Scrub.dir(d))
        return content
            .brightness(-0.34 * Double(t))
            .saturation(1 - 0.45 * Double(t))
            .scaleEffect(1 - shrink * t)
            .rotation3DEffect(.degrees(flat ? 0 : -s * angle * Double(t)),
                              axis: (x: 0, y: 1, z: 0), anchor: .center, perspective: 0.5)
            .rotationEffect(.degrees(flat ? s * 5 * Double(t) : 0))
            .opacity(Scrub.fade(t, after: 0.68))
    }
}

/// **ไถลในราง** — เลื่อนไปทางเดียวกับที่หน้ากำลังไป โดยไม่ย่อและไม่พลิก
/// ใช้กับของที่ "เกิดมาเพื่อเลื่อน" อย่างฟิล์มสตริป หรือกับชิปที่ควรปลิวออกข้าง
struct ScrubSlide: ViewModifier, Animatable {
    var d: CGFloat
    var travel: CGFloat
    var lead: Double = 0
    var fade: Double = 0.7
    var eased: Bool = true

    var animatableData: CGFloat {
        get { d }
        set { d = newValue }
    }

    func body(content: Content) -> some View {
        let raw = Scrub.t(d, lead: lead)
        let t = eased ? Scrub.ease(raw) : raw
        return content
            .offset(x: -Scrub.dir(d) * travel * t)
            .opacity(Scrub.fade(t, after: fade))
    }
}

// MARK: - มิเตอร์ตัวเลข

/// **มิเตอร์** — ตัวเลขลอกทีละหลักตามนิ้ว
///
/// ตัวเลขคือหลักฐาน มันไม่ควร "จางหาย" แบบข้อความทั่วไป — มันควรถูกถอดออกทีละหลัก
/// แล้วประกอบกลับตามลำดับตรงข้ามตอนปัดกลับ เหมือนหน้าปัดเครื่องนับที่หมุนย้อนได้
///
/// ตัวอักษรถูกแยกเป็นชิ้นละตัว ซึ่งทำให้ kerning หายไป — ยอมแลกเพราะตัวเลขเป็น
/// ความกว้างคงที่อยู่แล้ว ส่วนคำไทยยาว ๆ ห้ามใช้ตัวนี้ (ใช้ `scrubVeil` แทน)
struct ScrubDigits: View {
    let text: String
    var d: CGFloat
    var lead: Double = 0
    var step: Double = 0.05
    var drop: CGFloat = 26

    var body: some View {
        let chars = Array(text)
        HStack(spacing: 0) {
            ForEach(Array(chars.enumerated()), id: \.offset) { i, ch in
                Text(String(ch))
                    .fixedSize()
                    .scrubVeil(d,
                               lead: min(0.8, lead + Scrub.lead(i, of: chars.count, d: d, step: step)),
                               drop: drop, pull: 0)
            }
        }
    }
}

// MARK: - แถบวิ่งที่กรอตามนิ้ว

/// **รางวิ่ง** — เลื่อนเองตามเวลา และ **กรอตามนิ้วเมื่อผู้ใช้ปัด**
///
/// นี่คือจุดที่อุปมา "seek วิดีโอ" จับต้องได้ที่สุดของทั้งการ์ด: ของที่วิ่งอยู่แล้ว
/// พอโดนนิ้วลากจะเร่งไปข้างหน้า ลากกลับก็กรอถอย ปล่อยแล้วสปริงพากลับเข้าจังหวะเดิม
///
/// ตำแหน่งคิดเป็น "จำนวนรอบ" แล้วพับด้วย `floor` — จึงใช้สำเนาแค่ไม่กี่ชุด
/// ไม่ว่าจะกรอไปไกลแค่ไหน และรอยต่อมองไม่เห็นเพราะเนื้อหาซ้ำเป็นคาบอยู่แล้ว
///
/// ขับด้วย `TimelineView` ไม่ใช่ `withAnimation(repeatForever)` — transaction ที่วนค้างไว้
/// จะไปกลืนการอัปเดตรูปที่โหลดเสร็จทีหลัง และ `@State` ของมันจะรีเซ็ตทุกครั้งที่หน้า
/// หลุดออกจากต้นไม้ view ทำให้แถบกระโดดกลับต้นเมื่อปัดกลับมา
struct ScrubRunner<Content: View>: View {
    var d: CGFloat
    /// ความกว้างของเนื้อหาหนึ่งชุด (รวมระยะคั่นท้ายชุด)
    var runWidth: CGFloat
    /// วินาทีต่อหนึ่งรอบ
    var period: Double
    /// ปัดเต็มหนึ่งหน้าแล้วกรอไปกี่รอบ
    var pull: Double = 0.45
    var active: Bool = true
    var copies: Int = 3
    @ViewBuilder var row: () -> Content

    /// พรีวิวย่อส่วนสั่งหยุดเวลาได้ทั้งชุดจาก environment (ดู `CardStripPreview`)
    ///
    /// คลัง/หน้าเทมเพลตโชว์พรีวิวพร้อมกันเป็นสิบใบ ถ้าแถบวิ่งของทุกใบยัง invalidate
    /// ทุกเฟรม การเปลี่ยนหน้า (crossfade สองจอ) จะต้องแย่งเฟรมกับมันจนกระตุก —
    /// ของจริงบนแคนวาสไม่ได้ตั้งค่านี้ จึงวิ่งเหมือนเดิมทุกประการ
    @Environment(\.previewStatic) private var previewStatic

    var body: some View {
        ScrubReader(d: d) { d in
            TimelineView(.animation(minimumInterval: nil, paused: !active || previewStatic)) { tl in
                let p = max(0.5, period)
                let raw = tl.date.timeIntervalSinceReferenceDate / p - Double(d) * pull
                let wrapped = raw - floor(raw)
                HStack(spacing: 0) {
                    ForEach(0..<max(2, copies), id: \.self) { _ in row() }
                }
                .offset(x: -runWidth * CGFloat(wrapped))
            }
        }
    }
}

/// สวิตช์ "พรีวิวนิ่ง" — จอที่โชว์การ์ดย่อส่วนพร้อมกันหลายใบตั้งเป็น true
/// เพื่อหยุดของที่วิ่งตามเวลา (แถบวิ่ง/โลโก้เลื่อน) ไม่ให้แย่งเฟรมกับการเปลี่ยนหน้า
private struct PreviewStaticKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var previewStatic: Bool {
        get { self[PreviewStaticKey.self] }
        set { self[PreviewStaticKey.self] = newValue }
    }
}

// MARK: - เอียงตามนิ้ว

/// เอียง 3 มิติเข้าหาจุดที่นิ้วแตะ + ขยายนิดหน่อย + เรืองแสงสีธีม
///
/// บนเดสก์ท็อปคือ hover tilt · บนมือถือผูกกับการกดค้างแทน
struct PressTilt: ViewModifier {
    let point: CGPoint?
    let size: CGSize
    let glow: Color

    private var pressed: Bool { point != nil }

    /// องศาสูงสุดที่ยอมให้เอียง — เกินกว่านี้จะอ่านเป็น "หลุดระนาบ" มากกว่า "ตอบสนอง"
    private let maxTilt: Double = 7

    private var tilt: (x: Double, y: Double) {
        guard let p = point, size.width > 1, size.height > 1 else { return (0, 0) }
        let nx = (p.x / size.width - 0.5) * 2      // -1…1
        let ny = (p.y / size.height - 0.5) * 2
        return (x: -ny * maxTilt, y: nx * maxTilt)
    }

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(tilt.x), axis: (x: 1, y: 0, z: 0), perspective: 0.55)
            .rotation3DEffect(.degrees(tilt.y), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
            .scaleEffect(pressed ? 1.025 : 1)
            .shadow(color: glow.opacity(pressed ? 0.45 : 0), radius: pressed ? 24 : 0, y: 8)
            // สปริงเฉพาะตอน "กดลง/ปล่อย" เท่านั้น — **ห้ามใส่สปริงให้ตำแหน่ง**
            // ไม่งั้นแผ่นจะไล่ตามนิ้วช้ากว่าเสมอ ซึ่งตรงข้ามกับโจทย์ "ติดนิ้ว"
            // ทัชมาที่ 120Hz อยู่แล้ว ต่อค่าดิบเข้าไปตรง ๆ จึงลื่นที่สุด
            .animation(Motion.snap, value: pressed)
    }
}

extension View {
    func pageChoreo(_ kind: WidgetKind, _ order: Int, d: CGFloat, flat: Bool = false) -> some View {
        modifier(PageChoreo(kind: kind, order: order, flat: flat, d: d))
    }

    func pressTilt(_ point: CGPoint?, size: CGSize, glow: Color) -> some View {
        modifier(PressTilt(point: point, size: size, glow: glow))
    }

    /// ช่องมองหุบตามนิ้ว — ของข้างในอยู่นิ่ง
    func scrubAperture(_ d: CGFloat, lead: Double = 0,
                       feather: CGFloat = 0.16, dim: Double = 0.5) -> some View {
        modifier(ScrubAperture(d: d, lead: lead, feather: feather, dim: dim))
    }

    /// บรรทัดมุดหายใต้ขอบกล่องตัวเอง
    func scrubVeil(_ d: CGFloat, lead: Double = 0,
                   drop: CGFloat = 20, pull: CGFloat = 10) -> some View {
        modifier(ScrubVeil(d: d, lead: lead, drop: drop, pull: pull))
    }

    /// ภาพในกรอบถ่วงตัวสวนทางหน้า — ใช้กับ "ตัวภาพ" ที่อยู่ในกรอบที่ clip แล้วเท่านั้น
    func scrubDolly(_ d: CGFloat, shift: CGFloat, zoom: CGFloat = 0.16,
                    lead: Double = 0) -> some View {
        modifier(ScrubDolly(d: d, shift: shift, zoom: zoom, lead: lead))
    }

    /// ชิ้นเดียวพลิกในช่องของตัวเอง
    func scrubLouver(_ d: CGFloat, lead: Double = 0, angle: Double = 62,
                     shrink: CGFloat = 0.12, flat: Bool = false) -> some View {
        modifier(ScrubLouver(d: d, lead: lead, angle: angle, shrink: shrink, flat: flat))
    }

    /// ไถลไปตามทิศที่หน้ากำลังไป
    func scrubSlide(_ d: CGFloat, travel: CGFloat, lead: Double = 0,
                    fade: Double = 0.7, eased: Bool = true) -> some View {
        modifier(ScrubSlide(d: d, travel: travel, lead: lead, fade: fade, eased: eased))
    }
}
