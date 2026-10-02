import SwiftUI

/// ตำแหน่งที่คำนวณแล้วของ widget หนึ่งตัว — พิกัดในหน่วยออกแบบ อ้างมุมบนซ้ายของหน้า
struct Placed: Identifiable, Equatable {
    var id: UUID { item.id }
    let item: WidgetInstance
    let frame: CGRect
}

/// ผังหน้าแบบ **พิกเซล** — วาง/ยืดได้อิสระในหน่วยออกแบบ ไม่มีคอลัมน์และแถวอีกแล้ว
///
/// # ทำไมเลิกใช้กริดคอลัมน์
///
/// กริด 6 คอลัมน์เป็นหน่วย **สัมพัทธ์** — "6 คอลัมน์" แปลว่าเต็มความกว้างหน้าเสมอ
/// ไม่ว่าหน้าจะกว้างเท่าไหร่ ผลคือขนาดของ widget ไม่ใช่ของที่คนแต่งคุมได้จริง
/// มันเปลี่ยนตามหน้า และหน้าเปลี่ยนตามเครื่อง
///
/// พอพื้นที่ออกแบบถูกตรึงเป็น 540pt (= 1080px) ทุกเครื่อง หน่วยที่ถูกต้องจึงเป็น **pt ตรง ๆ**:
/// widget กว้าง 240 คือกว้าง 240 เหมือนกันหมด ทั้งบนจอเล็ก จอใหญ่ และในไฟล์ที่ export
///
/// # กติกาที่ยังอยู่เหมือนเดิม
///
/// ของต้อง **อยู่ในหน้า** และ **ห้ามทับกัน** — สองข้อนี้มาจากข้อเท็จจริงเดียวกันว่า
/// การ์ดนี้ต้องกลายเป็นรูปแผ่นเดียวที่อ่านออก ของที่ทับกันคือของที่อ่านไม่ออก
/// และผู้ใช้จะไม่รู้ตัวจนกว่าจะ export ออกมาแล้ว
enum PageLayout {
    /// ขั้นการสแนปตอนลาก/ยืด — 6pt ในหน่วยออกแบบ = 12px ที่ @2x
    ///
    /// ละเอียดพอให้รู้สึกว่าวางได้อิสระ แต่ยังหยาบพอให้ของสองชิ้นที่ "ตั้งใจให้ตรงกัน"
    /// ลงมาตรงกันจริงโดยไม่ต้องเล็งทีละพิกเซล
    static let step: CGFloat = 6

    /// ขอบกระดาษ — ระยะที่ระบบ **เว้นให้เอง** ตอนวางของใหม่
    ///
    /// 18 คือค่าเดียวกับที่พอร์ตเคยได้จากสูตรสัดส่วน (0.045 × 402) — ตั้งเป็นตัวเลขตรง ๆ
    /// เพื่อให้ขอบเป็นของที่ **ไม่ขยับตามขนาด canvas** เหมือนทุกอย่างอื่นในหน่วยพิกเซล
    ///
    /// **ไม่ใช่กำแพง** — ผู้ใช้ลากและยืดข้ามมันไปจนสุดขอบหน้าได้ (ดู `bounds`)
    static let margin: CGFloat = 18

    /// ระยะเว้นที่ระบบใช้ **ตอนหาที่วางให้อัตโนมัติ** เท่านั้น
    /// ผู้ใช้จะลากให้ชิดกว่านี้เองก็ได้ — นี่ไม่ใช่กติกา แค่รสนิยมตอนวางแทน
    static let gap: CGFloat = 10

    /// เล็กสุดที่ยังเป็นของที่อ่านออก ไม่ใช่เศษ
    /// (100 ≈ ความกว้างที่ widget แคบสุดในตู้ใช้อยู่จริง — ตั้งสูงกว่านี้แล้วมันจะหยิบมาไม่ได้)
    static let minSize = CGSize(width: 100, height: 40)

    /// เล็กสุด **ต่อชนิด** — ก้อนข้อความคือตัวอักษรพอดี (ดู `CardScreen.fitTextBlock`)
    /// ตัวอักษร 9pt ได้กล่องราว 40×15 ถ้าบังคับ 100×40 เท่าวิดเจ็ตอื่น กล่องจะใหญ่กว่าตัวอักษรสามเท่า
    /// เหลือแค่พื้นกันเศษ — กล่องศูนย์คือกล่องที่แตะไม่ได้
    static func minSize(for kind: WidgetKind) -> CGSize {
        kind == .textBlock ? CGSize(width: 8, height: 8) : minSize
    }

    // MARK: - ขอบเขตของหน้า

    /// **เพดานจริงของหน้า** — ทั้งแผ่น ไม่หักขอบ
    ///
    /// # ทำไมของถึงต้องชนขอบได้
    ///
    /// ก่อนหน้านี้กำแพงคือ `content` ผลคือ widget กว้างสุดได้ `page − 36` เสมอ และไม่มีท่าไหน
    /// ในแอปที่ทำให้ภาพเต็มขอบได้เลย — โปสเตอร์ทุกใบจึงลอยอยู่กลางหน้าพร้อมขอบขาวบาง ๆ
    /// รอบตัวที่ผู้ใช้ไม่ได้สั่งและลบไม่ได้ ซึ่งอ่านออกว่า "แอปยืดไม่สุด" ไม่ใช่ "ดีไซน์เว้นขอบ"
    ///
    /// ขอบกระดาษยังอยู่ แต่ย้ายไปเป็น *ค่าตั้งต้นตอนระบบวางของให้* (`content`) แทนที่จะเป็นกำแพง —
    /// ของที่แอปวางเองยังเว้นขอบสวยเหมือนเดิม ส่วนคนที่อยากได้ full-bleed ก็ลากไปชนขอบได้
    static func bounds(_ page: CGSize) -> CGRect {
        CGRect(x: 0, y: 0,
               width: max(page.width, minSize.width),
               height: max(page.height, minSize.height))
    }

    /// พื้นที่ที่ระบบใช้ **ตอนหาที่วางให้อัตโนมัติ** (หักขอบกระดาษแล้ว)
    ///
    /// ขอบเท่ากันทั้งสี่ด้าน — แถบผู้ออกบัตรถูกถอดออกจากการ์ดแล้ว ก้นหน้าจึงไม่ต้องกันที่ให้ใคร
    static func content(_ page: CGSize) -> CGRect {
        CGRect(x: margin, y: margin,
               width: max(page.width - margin * 2, minSize.width),
               height: max(page.height - margin * 2, minSize.height))
    }

    /// ปัดค่าลงขั้นสแนปที่ใกล้ที่สุด
    static func snap(_ v: CGFloat) -> CGFloat { (v / step).rounded() * step }

    static func snap(_ p: CGPoint) -> CGPoint { CGPoint(x: snap(p.x), y: snap(p.y)) }

    /// รูดกรอบให้อยู่ในหน้าเสมอ — จำกัด**ขนาด**ก่อน แล้วค่อยรูด**ตำแหน่ง**
    ///
    /// ลำดับนี้สำคัญ: ถ้ารูดตำแหน่งก่อน ของที่ใหญ่เกินหน้าจะถูกดันไปติดขอบซ้ายบน
    /// แล้วค่อยถูกหั่นขนาด — ซึ่งย้ายของโดยที่ผู้ใช้ไม่ได้สั่งย้าย
    static func clamp(_ r: CGRect, page: CGSize, min floor: CGSize = minSize) -> CGRect {
        let box = bounds(page)
        let w = min(max(r.width, floor.width), box.width)
        let h = min(max(r.height, floor.height), box.height)
        return CGRect(x: min(max(r.minX, box.minX), box.maxX - w),
                      y: min(max(r.minY, box.minY), box.maxY - h),
                      width: w, height: h)
    }

    /// รูดกรอบของ *ชิ้น* เข้าหน้า — กรอบยืดอิสระแล้ว จึงรูดทีละแกนตามกติกาของหน้า
    static func clamp(_ item: WidgetInstance, page: CGSize) -> CGRect {
        if item.pinned { return pinnedFrame(item, page: page) }
        return clamp(item.rect, page: page, min: minSize(for: item.kind))
    }

    /// กรอบของชิ้นที่ **ตรึงกับก้นหน้า** (ดู `WidgetInstance.pinned`) — x · กว้าง · สูง ตามที่ถือไว้
    /// ส่วน y นั่งบนขอบกระดาษล่างเสมอ
    ///
    /// คิดจากก้นหน้าทุกครั้งแทนที่จะเชื่อ `y` ในไฟล์ เพราะหน้าพอร์ตสูงตามจอ: ค่า y ที่ถูกบนเครื่องหนึ่ง
    /// คือลอยกลางหน้าหรือล้นก้นหน้าบนอีกเครื่อง · ทุกที่ที่ถามกรอบของชิ้น (`slots` · `freeSpot` ·
    /// `freeWidth`) ผ่าน `clamp` ตัวบน จึงเห็นที่เดียวกันหมด
    static func pinnedFrame(_ item: WidgetInstance, page: CGSize) -> CGRect {
        var r = clamp(item.rect, page: page, min: minSize(for: item.kind))
        r.origin.y = max(bounds(page).minY, content(page).maxY - r.height)
        return r
    }

    /// ขนาดที่ยังยืดได้จากมุมนั้นไปทางขวา / ลงล่าง — ใช้จำกัดตอนลากหมุด
    ///
    /// เพดานคือ **ขอบหน้า** ไม่ใช่ขอบกระดาษ หมุดจึงลากจนภาพเต็มขอบได้
    static func roomWidth(from x: CGFloat, page: CGSize) -> CGFloat {
        max(minSize.width, bounds(page).maxX - x)
    }
    static func roomHeight(from y: CGFloat, page: CGSize) -> CGFloat {
        max(minSize.height, bounds(page).maxY - y)
    }

    // MARK: - วางในหนึ่งหน้า

    /// วางทุกตัวตามพิกัดที่มันถือไว้ **แล้วดันลงจนไม่มีใครทับใคร**
    ///
    /// พิกัดที่ถูกดัน **ไม่ถูกเขียนกลับลงตัว item** โดยตั้งใจ — ค่าที่ผู้ใช้ตั้งไว้ยังอยู่เหมือนเดิม
    /// ย้ายตัวที่ขวางออกเมื่อไหร่ ของที่ถูกดันก็เด้งกลับขึ้นที่เดิมเอง
    ///
    /// - Parameter first: id ของตัวที่ต้อง **ได้ที่ที่มันขอก่อนใคร**
    ///   ใช้ตอนลาก: ตัวที่นิ้วจับต้องชนะเสมอ ตัวอื่นเป็นฝ่ายหลบ ไม่ใช่กลับกัน
    static func solve(_ items: [WidgetInstance], page: CGSize, first: UUID? = nil) -> [Placed] {
        guard page.width > 0, page.height > 0 else { return [] }
        let spot = slots(items, page: page, first: first)
        // ชิ้นที่ตรึงวาดทีหลังสุด = อยู่ชั้นบนสุด — หน้าที่เต็มจนของต้องทับกัน ตรารับรองต้องไม่ใช่ฝ่ายที่ถูกบัง
        return (items.filter { !$0.pinned } + items.filter(\.pinned)).map {
            Placed(item: $0, frame: spot[$0.id] ?? clamp($0, page: page))
        }
    }

    /// กรอบที่แต่ละตัว **ได้จริง** หลังดันกันแล้ว — แยกจาก `solve` เพราะมีสองคนใช้
    ///
    /// `solve` ใช้ตอนวาด ส่วน `CardScreen.endDrag` ใช้ตอนปล่อยนิ้วเพื่อเขียนผลกลับลงข้อมูลจริง
    /// (ระหว่างลาก ตัวที่นิ้วจับได้สิทธิ์ก่อน พอปล่อยแล้วคำนวณใหม่โดยไม่มี `first`
    ///  ลำดับจะกลับไปตัดสินด้วย "อยู่สูงกว่าได้ก่อน" ของที่เพิ่งลากไปวางจึงเด้งกลับที่เดิม)
    static func slots(_ items: [WidgetInstance], page: CGSize,
                      first: UUID? = nil) -> [UUID: CGRect] {
        // กำแพงคือขอบหน้า — ของที่ผู้ใช้ลากไปชนขอบต้อง **อยู่ที่เดิม** ไม่ใช่ถูกดีดกลับเข้าขอบกระดาษ
        let box = bounds(page)
        // ส่วนตอนที่ระบบเป็นคนหาที่ให้ ยังเว้นขอบกระดาษเหมือนเดิม (ดู `margin`)
        let polite = content(page)
        let order = items.enumerated().sorted { a, b in
            // ชิ้นที่ตรึงได้ที่ก่อนทุกคน — ก่อนตัวที่นิ้วจับด้วย ของที่ลากมาทับจึงเป็นฝ่ายหลบเสมอ
            if a.element.pinned != b.element.pinned { return a.element.pinned }
            if let first {
                if a.element.id == first { return true }
                if b.element.id == first { return false }
            }
            if a.element.y != b.element.y { return a.element.y < b.element.y }
            if a.element.x != b.element.x { return a.element.x < b.element.x }
            // ลำดับในลิสต์เป็นตัวตัดสินสุดท้าย — ผลลัพธ์จึงคงที่ทุกครั้งที่คำนวณใหม่
            return a.offset < b.offset
        }

        var taken: [CGRect] = []
        var spot: [UUID: CGRect] = [:]
        // ชิ้นที่ตรึงถูกวางก่อนเสมอ จึงเป็นกรอบชุดแรกของ `taken`
        let pinnedCount = items.filter(\.pinned).count

        // หดเข้ามาครึ่งจุดก่อนเทียบ — ของที่ขอบชนกันพอดีไม่ใช่ของที่ทับกัน
        func free(_ r: CGRect) -> Bool {
            guard r.minX >= box.minX - 0.01, r.minY >= box.minY - 0.01,
                  r.maxX <= box.maxX + 0.01, r.maxY <= box.maxY + 0.01 else { return false }
            let probe = r.insetBy(dx: 0.5, dy: 0.5)
            return !taken.contains { $0.intersects(probe) }
        }

        for (_, item) in order {
            var want = clamp(item, page: page)
            if item.pinned {
                taken.append(want)
                spot[item.id] = want
                continue
            }
            // ขอที่ทับชิ้นที่ตรึง = ได้ที่ **เหนือมันพอดี** — ที่ใกล้สุดกับที่นิ้วปล่อย
            // (ไม่ทำแบบนี้ การดันลงจะไม่มีวันเจอที่ว่าง แล้วของกระโดดไปมุมบนซ้ายของหน้า)
            for pin in taken.prefix(pinnedCount) where pin.insetBy(dx: 0.5, dy: 0.5).intersects(want) {
                let above = pin.minY - want.height
                if above >= box.minY { want.origin.y = above }
            }
            var put: CGRect? = nil

            // 1) ดันลงตรง ๆ ในแนวเดิม — ท่าปกติ ของขยับน้อยที่สุด
            var y = want.minY
            while y + want.height <= box.maxY + 0.01 {
                let r = CGRect(x: want.minX, y: y, width: want.width, height: want.height)
                if free(r) { put = r; break }
                y += step
            }

            // 2) แนวเดิมเต็มถึงก้นหน้าแล้ว — กวาดหาที่ว่างแรกทั้งหน้า บนลงล่าง ซ้ายไปขวา
            //
            //    กวาดหยาบกว่าขั้นสแนป (4 เท่า) เพราะขั้นนี้วิ่งระหว่างลาก ถ้าละเอียดเท่ากัน
            //    จะกลายเป็นการค้นหลักแสนกรอบต่อการขยับนิ้วหนึ่งครั้ง
            if put == nil {
                let coarse = step * 4
                // ตัวที่ใหญ่เกินกรอบสุภาพ (เช่นใบที่ยืดเต็มขอบ) ต้องกวาดทั้งหน้า
                // ไม่งั้นช่วงกวาดว่างเปล่าแล้วมันตกไปข้อ 3 ทั้งที่ยังมีที่ว่างจริง
                let sweep = want.width <= polite.width && want.height <= polite.height ? polite : box
                outer: for yy in stride(from: sweep.minY, through: sweep.maxY - want.height, by: coarse) {
                    for xx in stride(from: sweep.minX, through: sweep.maxX - want.width, by: coarse) {
                        let r = CGRect(x: xx, y: yy, width: want.width, height: want.height)
                        if free(r) { put = r; break outer }
                    }
                }
            }

            // 3) หน้าเต็มจริง ๆ — ยอมทับที่ก้นหน้า ดีกว่าดันหลุดออกนอกหน้าซึ่งพิมพ์ไม่ติด
            //
            //    แต่ **ห้ามซุกใต้ชิ้นที่ตรึง** — มันอยู่ชั้นบนสุดและย้ายไม่ได้ ของที่ไปอยู่ใต้มัน
            //    คือของที่มองไม่เห็นและแตะไม่ถึงอีกเลย · ทับของชิ้นอื่นเหนือมันแทน (ยังเห็น ยังลากออกได้)
            var floorY = box.maxY - want.height
            for pin in taken.prefix(pinnedCount) where pin.minX < want.maxX && pin.maxX > want.minX {
                floorY = min(floorY, pin.minY - want.height)
            }
            let final = put ?? CGRect(x: want.minX, y: max(box.minY, floorY),
                                      width: want.width, height: want.height)
            taken.append(final)
            spot[item.id] = final
        }

        return spot
    }

    /// ความกว้างที่ยัง **ว่างจริง** จากจุดนั้นไปทางขวา ตลอดช่วงความสูงนั้น
    ///
    /// # ทำไมต้องมีตัวนี้
    ///
    /// ผู้ใช้ย่อ widget ตัวแรกเหลือครึ่งหน้า แล้วลากตัวที่สองไปวางข้าง ๆ — แต่ตัวที่สอง
    /// ยังกว้างเต็มหน้า พอถูกรูดกลับเข้าหน้ามันเลยไปทับตัวแรกแล้วถูกดันลง
    /// ผลคือ **วางคู่กันไม่ได้เลย** ทั้งที่ที่ว่างมีอยู่จริง ซึ่งอ่านออกเป็นบั๊ก ไม่ใช่กติกา
    static func freeWidth(from x: CGFloat, y: CGFloat, height: CGFloat, page: CGSize,
                          avoiding items: [WidgetInstance], excluding id: UUID?) -> CGFloat {
        let box = bounds(page)
        let top = min(max(y, box.minY), box.maxY - min(height, box.height))
        let band = CGRect(x: box.minX, y: top, width: box.width, height: min(height, box.height))
        var limit = box.maxX
        for item in items where item.id != id {
            let r = clamp(item, page: page)
            guard r.minY < band.maxY - 0.5, r.maxY > band.minY + 0.5 else { continue }
            if r.minX >= x - 0.5 { limit = min(limit, r.minX) }
        }
        return max(0, limit - x)
    }

    /// ที่ว่างแรกที่ของขนาดนี้ลงได้โดยไม่ทับใคร — ไล่บนลงล่าง ซ้ายไปขวา เว้นระยะ `gap`
    ///
    /// คืน nil เมื่อหน้าไม่เหลือที่พอ — **ผู้เรียกต้องไม่ยัดของลงหน้านั้นต่อ**
    /// เพราะ `solve` มีทางออกสุดท้ายเป็นการยอมทับกันที่ก้นหน้า ซึ่งอ่านออกว่าแอปพัง
    static func freeSpot(size: CGSize, page: CGSize,
                         avoiding items: [WidgetInstance]) -> CGPoint? {
        let box = content(page)
        let w = min(max(size.width, minSize.width), box.width)
        let h = min(max(size.height, minSize.height), box.height)
        let taken = items.map { clamp($0, page: page).insetBy(dx: -gap / 2, dy: -gap / 2) }

        for y in stride(from: box.minY, through: box.maxY - h, by: step) {
            for x in stride(from: box.minX, through: box.maxX - w, by: step) {
                let r = CGRect(x: x, y: y, width: w, height: h)
                if !taken.contains(where: { $0.intersects(r) }) { return CGPoint(x: x, y: y) }
            }
        }
        return nil
    }
}
