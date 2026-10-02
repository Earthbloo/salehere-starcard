import SwiftUI

/// เปลือกของ widget หนึ่งตัว — พื้น · กระจก · ขอบ — ใช้ทั้งบนแคนวาสและตอนเรนเดอร์รูป
///
/// เนื้อหาข้างในปิด hit testing ไว้เสมอ รูปแบบ `.fill` ที่ล้นกรอบจะได้ไม่ไปแย่งทัชของตัวข้างเคียง
/// ชั้นการ์ดเป็นคนวาง catcher ทับเองถ้าต้องการให้ลาก/เลือกได้
/// ปุ่มปลดล็อกบนใบที่ยังไม่มีข้อมูล — ขาวทึบ (ดังกว่าใบที่หม่นอยู่ข้างหลัง) · กุญแจเปิด · ลูกศร = "กดได้"
/// วงแสงหายใจช้า ๆ รอบปุ่ม บอกว่าเป็นของที่ต้องแตะ ไม่ใช่ป้ายสถานะ (เฉพาะในห้องแต่ง)
struct LockCTA: View {
    let title: String
    @State private var breathe = false
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.open.fill").font(.system(size: 11, weight: .bold))
            Text(title).font(.sh(11.5, .bold)).lineLimit(1).fixedSize()
            Image(systemName: "chevron.right").font(.system(size: 9, weight: .heavy)).opacity(0.55)
        }
        .foregroundStyle(Color(red: 0.09, green: 0.09, blue: 0.11))
        .padding(.leading, 10).padding(.trailing, 9).frame(height: WidgetChrome.lockHeight)
        .background(Capsule().fill(.white))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
        .background(
            Capsule().stroke(.white.opacity(breathe ? 0 : 0.7), lineWidth: 2)
                .scaleEffect(breathe ? 1.25 : 1)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) { breathe = true }
        }
    }
}

struct WidgetChrome: View {
    /// ปุ่มปลดล็อกอยู่มุมขวาบนของใบ — ใช้ร่วมกับ `CardScreen` เพื่อรู้ว่าแตะโดนปุ่ม
    static let lockHeight: CGFloat = 30
    static let lockInset: CGFloat = 8
    /// พื้นที่แตะของปุ่ม (พิกัดในใบ) — เผื่อขอบกว้างกว่าตัวปุ่มให้นิ้วแตะง่าย
    static func lockHitRect(in size: CGSize) -> CGRect {
        CGRect(x: size.width - 230, y: 0, width: 230, height: lockInset + lockHeight + 10)
    }

    let placed: Placed
    let theme: CardTheme
    @Environment(\.saleHereMarkStyle) private var markStyle
    /// ห้องแต่ง: ใบที่ข้อมูลยังไม่กรอกขึ้นกุญแจที่มุม (ภาพที่แชร์ออกไปไม่ขึ้น — มีแค่ขีด "–")
    var lockBadge = false
    /// รูปย่อของการ์ดที่เจ้าของเห็นเอง (คลัง · Star Profile): ใบที่ล็อกหน้าตาเดียวกับในห้องแต่ง —
    /// ใบจริงด้วยชุดตัวอย่างใต้ชั้นเทา แต่ **ไม่มีปุ่มปลดล็อก** (ผู้ใช้ 1 ต.ค. 2569: "รูปข้างนอก อันที่ Lock
    /// ไม่มี Preview เหมือนด้านใน") · รูปที่แชร์ออกไปไม่ผ่านทางนี้ ตัวอย่างจึงไม่หลุดไปถึงคนอื่น
    var lockPreview = false

    var body: some View {
        let p = placed
        let ink = theme.inkStyle
        let kind = p.item.kind
        // MARK: `.pane` — กระจกของ chrome บนใบที่ปกติวาดวัสดุเอง
        //
        // แปลงที่นี่ที่เดียวแล้วไม่มี widget ตัวไหนต้องรู้จักพื้นผิวแบบนี้เลย:
        // **chrome** เห็นเป็นกระจก (วาดแผ่น เว้นระยะขอบใน ปรับหมึกให้เหมือนทุกใบที่อยู่บนกระจก)
        // ส่วน **widget** ได้รับ `.clear` ลงไป — มันจึงไม่วาดกระดาษของตัวเอง
        // และพลิกหมึกตามการ์ดด้วยทางเดิมที่มันมีอยู่แล้ว
        let pane = p.item.surface == .pane
        let surface: WidgetSurface = pane ? .glass : p.item.surface
        // ส่ง `.pane` ลงไปตรง ๆ — **ไม่ใช่ `.clear`**
        //
        // เดิมส่ง `.clear` ลงไป widget จึงวาดร่างที่ "ไม่มีกระดาษ" ซึ่งเป็นคนละผังกับร่างที่มีแผ่น
        // (ไม่มีเศษข่าว ไม่มีแถบฐาน ระยะขอบคนละชุด) — ผู้ใช้สลับจาก "มีพื้น" มาเป็น "กระจก"
        // แล้วเห็นของข้างในขยับไปหมด ทั้งที่คำถามที่เขากดคือ *พื้นข้างหลังเป็นอะไร* เท่านั้น
        //
        // ตอนนี้ widget รู้ว่าตัวเองอยู่บนกระจกของ chrome: **ผังยังเป็นผังของแผ่นพิมพ์**
        // เปลี่ยนแค่ตัวแผ่นเป็นใส แล้วหมึกพลิกไปใช้หมึกของการ์ด (เฉพาะสำรับที่มีแผ่นของตัวเอง
        // เท่านั้นที่เลือก `.pane` ได้ — ดู `WidgetKind.surfaceOptions`)
        let innerSurface: WidgetSurface = p.item.surface
        // ก้อนข้อความ: กล่องคือตัวอักษรพอดี — ขอบชิด มุมเล็ก และ **ไม่ clip** เนื้อหา
        // (ตัวอักษรไม่มีวันล้นกล่องที่หุ้มมันอยู่แล้ว clip มีแต่จะกินสระบนเวลาวัดคลาดไปหนึ่งพิกเซล)
        let isText = kind == .textBlock
        let radius = isText ? min(theme.radius, TextBlock.radius) : theme.radius
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        // **ทุกชิ้นมีพื้น** — พื้นไม่ผูกกับเส้นขอบอีกแล้ว (เดิม "ไม่มีขอบ" = พื้นหายไปด้วย
        // ชิ้นนั้นเลยลอยหายไปกับการ์ด) เส้นขอบเป็นเรื่องของเส้นอย่างเดียว ดูที่ `.overlay` ท้ายไฟล์
        //
        // ยกเว้นของที่ **วาดพื้นของตัวเองอยู่แล้ว** (กระดาษ · ฟิล์ม · ป้ายไฟ · รูปเต็มกรอบ ·
        // แผ่นสติกเกอร์) — ครอบทับเมื่อไหร่ได้กล่องซ้อนกล่อง ป้ายหัวข้อที่คร่อมขอบกล่องจะถูก clip
        // และวัสดุของมันจะสู้กับพื้นกระจกจนสีเพี้ยน
        // "ไม่มีพื้น" = ไม่มีแผ่นให้วาด ไม่ว่าใบนั้นจะเป็นแบบที่ chrome ครอบให้หรือวาดเอง
        // `.pane` = ขอกระจกของ chrome มาครอบ ถึงใบนั้นจะเป็นชนิดที่วาดวัสดุเองก็ตาม
        let framed = pane || (!kind.drawsOwnSurface && surface != .clear)
        // MARK: ระยะขอบในมีได้เมื่อ **มีอะไรให้เว้นจาก** เท่านั้น
        //
        // ระยะขอบในคือระยะระหว่างเนื้อหากับ *ขอบของชิ้น* — และขอบของชิ้นคือสิ่งเดียวกับ
        // กรอบที่ขึ้นตอนแตะ/เลือก (ดู `CardScreen.editHairline`) ชิ้นที่ไม่มีทั้งพื้นและเส้นขอบ
        // จึงไม่มีอะไรให้เว้นจากเลย ระยะที่เว้นไว้กลายเป็นลมรอบเนื้อหา แล้วกรอบตอนเลือก
        // ก็ลอยห่างจากตัวอักษรออกไปข้างละ 12pt โดยไม่มีเหตุผล — และเวลาลากไปวางชิดของอื่น
        // ระยะจริงที่ตาเห็นจะไม่เท่ากับระยะที่ผังบอก
        //
        // มีพื้น (แผ่นของ chrome) หรือมีเส้นขอบเมื่อไหร่ ระยะนั้นมีหน้าที่ทันที: กันไม่ให้
        // ตัวอักษรไปชนขอบแผ่น/เส้น · ส่วนใบที่วาดพื้นของตัวเอง (กระดาษ · ฟิล์ม · โปสเตอร์)
        // เว้นระยะไว้ในผังของมันเองแล้ว ครอบเพิ่มอีกชั้นคือการหดแผ่นให้เล็กลงเฉย ๆ
        let insetable = framed || (!kind.drawsOwnSurface && p.item.border)
        // `.pane` ไม่เว้นระยะขอบใน — **กรอบของเนื้อหาต้องเท่ากับตอน "มีพื้น" เป๊ะ**
        //
        // สำรับที่วาดแผ่นเองจัดผังในกรอบเต็มของชิ้น (ระยะขอบอยู่ในผังของมันแล้ว) ครอบเพิ่มอีก 12pt
        // ต่อข้างเท่ากับยัดผังเดิมลงกล่องที่เล็กลง 24pt ทั้งสองแกน — `PosterSheet` ยืดผังตามกรอบ
        // ใหม่ ปีก/พิลล์/คนเลยขยับไปคนละที่ ผู้ใช้สลับพื้นหลังแล้วเห็นของข้างในเบี้ยวทั้งใบ
        let inset: CGFloat = isText ? TextBlock.inset
                           : (pane || kind.isFullBleed || !insetable ? 0 : 12)

        // MARK: กรอบคือคอนเทนเนอร์ · เนื้อหาจัดตัวเองข้างใน
        let natural = max(kind.defaultSize.width, 1)
        // # กรอบคือ **คอนเทนเนอร์** เนื้อหาจัดตัวเองข้างใน — ไม่ใช่รูปที่ถูกดึงให้เต็ม
        //
        // ยืดกรอบกว้างขึ้น = ผังได้ที่กว้างขึ้นไปจัดเอง (แถวกระจาย · รูปกินเต็มช่องแล้วครอป ·
        // ระยะขอบคงที่) · ยืดสูงขึ้น = ผังได้ที่สูงขึ้น · **ตัวอักษรกับรูปไม่ถูกบีบสักแกน**
        // ความรู้สึกเดียวกับ auto layout: ของข้างในรักษารูปทรงของตัวเอง ที่เปลี่ยนคือการกระจายตัว
        //
        // เพดานเดียวที่ยังสเกลอยู่คือ **ตอนกรอบแคบกว่าผัง** — เนื้อหาหลายตัวมีความกว้างต่ำสุด
        // ของมันเอง (ไอคอน 34pt สามอัน + ตัวเลข + ระยะห่าง) `HStack` ไม่บีบให้ต่ำกว่านั้น
        // มันจะล้นออกไปทับชิ้นข้างเคียงแทน · ตรงนั้นจึงย่อทั้งก้อนลงแทน — เป็น *ทางกันล้น*
        // ไม่ใช่วิธีจัดผัง (กรอบที่กว้างกว่าหรือเท่าผังได้ `s == 1` เสมอ)
        //
        // ส่วนความสูง: ผู้ใช้ย่อต่ำกว่าที่เนื้อหาขอไม่ได้ (ดู `CardScreen.minHeight`) จึงไม่มี
        // กรณีที่เนื้อหาถูกกรอบตัดโดยไม่มีใครสั่ง
        let s = kind == .textBlock ? 1 : min(1, max(p.frame.width, 1) / natural)
        // ผังถูกวางในหน่วย "ก่อนย่อ" แล้วค่อยหดทั้งก้อน — ความสูงจึงต้องหารกลับด้วย
        let layout = CGSize(width: max(p.frame.width, 1) / s,
                            height: max(p.frame.height, 1) / s)
        // กุญแจของตราที่ล็อกย่อตามใบ — ตราครึ่งหน้าบนสตอรี่ได้กุญแจเล็กลงตามส่วน
        let lockScale = max(0.7, s)

        // แผ่นของ widget คือพื้นจริงของตัวหนังสือข้างใน — กระจกกดพื้นลง แผ่นจางยกพื้นขึ้น
        // ส่งหมึกที่รู้จักแผ่นนี้ลงไป ตัวหนังสือรองในแผ่นจึงถูกยันแค่เท่าที่แผ่นนั้นต้องการจริง (ดู `InkStyle.text`)
        // หัวข้อ Star Profile ที่ใบนี้อ่านยังไม่ได้กรอก = วาดเลย์เอาต์เต็มใบ แต่ค่าเป็น "–" (ผู้ใช้ 29 ก.ย. 2569)
        // ตรารับรองล็อกจนกว่าการยืนยันตัวตนจะ **ผ่าน** — มีสองสถานะเท่านั้น: ผ่าน หรือ ล็อก (ไม่มี "รอทีมงานตรวจ")
        let sealLocked = kind == .proofSeal && !VerifiedFacts.sealed
        let missing = kind == .proofSeal ? sealLocked : (kind.family.topic.map { !$0.filled } ?? false)
        // แสตมป์ Sale Here — ใบที่ถือข้อมูลซึ่งตรวจแล้ว (ดู `SaleHereStamp`) · ใบที่ยังไม่มีข้อมูลไม่ได้ดวง
        let stamped = !missing && (kind.stampFacts?.verified ?? false)
        // ใบที่ล็อกในห้องแต่ง = วาดใบจริงด้วยชุดตัวอย่าง ให้เห็นว่ากรอกแล้วได้อะไร — ไม่ใช่กรอบเปล่ากับขีด "–"
        // (ผู้ใช้ 1 ต.ค. 2569) · ภาพที่แชร์/โหมดดูไม่ผ่านทางนี้ ยังเป็นป้ายรอข้อมูลเหมือนเดิม
        let lockLook = lockBadge || lockPreview
        let sampled = lockLook && missing && Profile.me.lacks(kind.family)
        let content = WidgetBody(kind: kind, theme: theme, size: layout)
            .environment(\.sampleData, sampled)
            .environment(\.ghostData, missing && !sampled && !sealLocked)
            .environment(\.ghostKeepsText, true)
            .environment(\.cardInk, framed ? Self.ink(ink, on: surface, theme: theme) : ink)
            .environment(\.widgetID, p.item.id)
            // ฟอนต์/สี/ขนาด/การจัดวางของตัวอักษร — เก็บอยู่ที่ชิ้น ส่งลงไปทางเดียวกับ id
            // (วิดเจ็ตที่ไม่ได้อ่านค่านี้ก็แค่ไม่หยิบไปใช้ ไม่ต้องรู้จักมันด้วยซ้ำ)
            .environment(\.widgetTextStyle, p.item.textStyle)
            .environment(\.widgetSurface, innerSurface)
            .environment(\.widgetBorder, p.item.border)
            .environment(\.widgetPattern, p.item.pattern)
            .environment(\.widgetLiftsPhoto, kind.liftsSubject && p.item.liftPhoto)
            // มีแสตมป์แล้วไม่ปั๊มตรานูนซ้ำ — รับรองที่เดียวต่อใบ
            .environment(\.widgetEmboss, kind.takesEmboss && p.item.emboss && !stamped)
            .environment(\.saleHereStamped, stamped)
            .environment(\.widgetEmbossBlind, p.item.embossBlind)
            .environment(\.widgetSealStyle, p.item.sealStyle)
            .padding(inset)
            .frame(width: layout.width, height: layout.height, alignment: .topLeading)
            .scaleEffect(s, anchor: .topLeading)
            .frame(width: p.frame.width, height: p.frame.height, alignment: .topLeading)
            .allowsHitTesting(false)

        Group {
            if !framed {
                // ของที่วาดพื้นเอง — chrome ไม่ยุ่งกับมันเลย นอกจากกันของล้นกรอบ
                //
                // ต้องเป็น **สี่เหลี่ยมตรง** ไม่ใช่ `shape` ที่มุมมน: ตรงนี้ไม่มีแผ่นพื้นของ chrome
                // มุมมนจึงไม่มีอะไรให้อ้างอิง มันกลายเป็นแค่ของที่กินหัวข้อซึ่งนั่งชิดมุมบนซ้าย
                // (รัศมี 22pt กินตัวแรกของ "ผู้ติดตาม" หายไปทั้งตัว)
                //
                // สำรับที่วาดวัสดุเองหลายตัวยื่นเงา/เทป/ป้ายพ้นกรอบ — `Rectangle()` ที่นี่จึงกว้าง
                // เท่ากรอบพอดี ไม่ใช่ตัวตัดวัสดุ (ตัวที่ต้องยื่นจริง ๆ เผื่อระยะไว้ในกรอบของมันเอง)
                Self.clipped(content, Rectangle(), unless: isText)
            } else {
                switch surface {
                // `.pane` ถูกแปลงเป็น `.glass` ไปแล้วตั้งแต่ต้น body — เขียนไว้ให้ครบเคส
                case .glass, .pane:
                    // คู่สี: กระจกต้องไม่ย้อมสีเน้นของการ์ด — ย้อมเมื่อไหร่แผ่นอมสีของคู่ขึ้นมา
                    // แล้วมันเลิกเป็นกระจก กลายเป็นแผ่นสีอ่อนของคู่อีกใบที่สู้กับแผ่นทึบข้าง ๆ
                    // กระจกในงานสองสีคือ **เงาดำใส** ไม่ใช่สีที่สาม
                    let tinted = kind.tier == .verified && theme.activeDuo == nil
                    GlassPanel(tint: tinted ? theme.accent : nil,
                               tintStrength: tinted ? 0.13 : 0,
                               // คู่สี: ม่านเป็น **ดำจาง** ทั้งสองฝั่ง — แผ่นจึงเป็น "สีพื้นที่เข้มลง"
                               // ไม่ใช่สีทึบใบใหม่ · การ์ดยังอ่านเป็นสองสี แต่มีชั้นความลึกเพิ่มมา
                               // หนึ่งชั้นที่เป็นเฉดเดียวกับพื้น (แผ่นทึบสีเข้มยังมีอยู่ที่ "เข้ม"
                               // กับสำรับโปสเตอร์ ซึ่งตั้งใจให้ดังกว่าอยู่แล้ว)
                               veil: theme.activeDuo == nil ? nil : Color.black.opacity(0.16),
                               radius: radius) {
                        Self.clipped(content, shape, unless: isText)
                    }

                case .clear:
                    // ถึงตรงนี้ไม่ได้ — `framed` เป็น false ไปแล้วเมื่อไม่มีพื้น
                    // เขียนไว้ให้คอมไพเลอร์ครบเคส และกันพลาดถ้ามีใครแก้เงื่อนไขข้างบนวันหลัง
                    Self.clipped(content, shape, unless: isText)

                case .dim:
                    // "เข้ม" = แผ่น **ทึบ 100%** ไม่ให้พื้นหลังทะลุขึ้นมาแม้แต่นิดเดียว
                    // (ม่านโปร่งคือสิ่งที่กระจกทำอยู่แล้ว มีสองแบบที่เหมือนกันครึ่งหนึ่งไม่มีประโยชน์)
                    //
                    // แผ่นทึบเปลี่ยน *พื้นของตัวหนังสือ* ทั้งดุ้น ไม่ใช่แค่กดพื้นหลังลง — บนการ์ดกระดาษ
                    // ตัวหนังสือจึงต้องพลิกเป็นตัวขาวไปด้วย (ดู `ink(_:on:theme:)`) ไม่งั้นได้ถ่านบนถ่าน
                    ZStack {
                        shape.fill(Self.slab(theme))
                        Self.clipped(content, shape, unless: isText)
                    }
                    .shadow(color: ink.lift.opacity(0.6), radius: ink.liftRadius * 0.7, y: 4)
                }
            }
        }
        // ใบที่ล็อก = สีของใบยังเต็ม มีแค่ชั้นเทาโปร่งทับ (ผู้ใช้ 1 ต.ค. 2569: "ไม่เอาสีจาง … layer สีเทา alpha ทับเฉย ๆ พอ")
        // ไม่ลดความสด ไม่ลด opacity ของตัวใบ — แบบเดียวกับม่านของช่องที่ล็อกในตู้ widget
        // ตรารับรองที่ยังล็อกมีชั้นเทา **ทุกที่** รวมรูปที่แชร์ — ใต้ชั้นเทาคือหน้าตา "VERIFIED" เต็มใบ
        // ถ้าหลุดออกไปโดยไม่มีอะไรทับ มันคือคำรับรองที่ Sale Here ยังไม่ได้ให้
        .overlay {
            if missing && (lockLook || sealLocked) {
                shape.fill(Self.lockVeil).allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topTrailing) {
            if lockBadge, missing, let t = kind.family.topic {
                // ปุ่มจริงของใบที่ล็อก — แตะที่ปุ่มนี้เท่านั้นถึงเปิดหน้ากรอก (ส่วนอื่นของใบยังเลือก/ลาก/ลบได้ตามปกติ)
                // แตะรับที่ `CardScreen` ผ่าน `WidgetChrome.lockHitRect` (ชั้นนี้ไม่รับทัชเอง)
                LockCTA(title: t == .verify ? "ยืนยันตัวตนเพื่อปลดล็อก" : t == .work ? "ทำงานจบ 1 งานเพื่อปลดล็อก" : "กรอกข้อมูลเพื่อปลดล็อก")
                    .padding(Self.lockInset)
                    .allowsHitTesting(false)
            } else if sealLocked {
                // นอกห้องแต่ง (หน้าดู · รูปที่แชร์) ไม่มีปุ่ม — กุญแจดวงเดียวพอ ของที่ดูเหมือนกดได้ห้ามอยู่ในรูป
                Image(systemName: "lock.fill")
                    .font(.system(size: 11 * lockScale, weight: .bold))
                    .foregroundStyle(Color(red: 0.09, green: 0.09, blue: 0.11))
                    .frame(width: 26 * lockScale, height: 26 * lockScale)
                    .background(Circle().fill(.white))
                    .padding(Self.lockInset * lockScale)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topTrailing) {
            // ใบที่ไม่มีช่องหัวข้อ — ป้าย Verified by Sale Here มุมขวาบนด้านใน (ดู `WidgetKind.stampOverlay`)
            if stamped, let o = kind.stampOverlay {
                SaleHereByline(tint: (framed ? Self.ink(ink, on: surface, theme: theme) : ink).text(0.85), tone: o.tone)
                    .padding(.top, o.top).padding(.trailing, o.trailing)
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            if p.item.border && !kind.isPop {
                shape.strokeBorder(ink.line(0.12), lineWidth: 0.7)
            }
        }
    }

    /// ชั้นเทาที่ทับใบซึ่งยังล็อกอยู่
    static let lockVeil = Color(white: 0.22).opacity(0.5)

    /// แผ่น "เข้ม" — ถ่านทึบที่อาบเฉดของธีมไว้ เหมือนหมึกของการ์ดฝั่งกระดาษ แต่เข้มกว่า
    ///
    /// ไม่ใช่ดำสนิท: ดำ 100% บนการ์ดมืดอ่านเป็น "รูที่เจาะทะลุการ์ด" ไม่ใช่แผ่นที่วางอยู่บนการ์ด
    static func slab(_ theme: CardTheme) -> Color {
        if let d = theme.duoDark { return d }
        return Color(hue: theme.backdropHue, saturation: 0.30, brightness: 0.10)
    }

    /// หมึกบนแผ่นแต่ละแบบ — ตัวเลขชุดเดียวกับที่วาดแผ่นข้างบน (และใน `GlassPanel`)
    ///
    /// กระจกแค่ *กด/ยก* พื้นเดิม หมึกจึงเป็นชุดเดิมของการ์ด · แต่แผ่นเข้มทึบบังพื้นการ์ดหมดแล้ว
    /// มันจึงเป็นเวทีมืดของตัวเอง — หมึกพลิกเป็นตัวขาวทุกธีม และพื้นที่ยันตัวหนังสือคือความสว่างของแผ่นจริง
    private static func ink(_ ink: InkStyle, on surface: WidgetSurface, theme: CardTheme) -> InkStyle {
        switch surface {
        case .clear:
            return ink
        case .glass, .pane:
            // คู่สี: ม่านเป็นดำจางทั้งสองฝั่ง (ดู `veil` ข้างบน) — พื้นใต้ตัวหนังสือจึงถูก *กดลง*
            // ไม่ใช่ถูกยกขึ้นด้วยขาวขุ่น · หมึกยังเป็นหมึกของการ์ดใบเดิม แค่ถูกยันให้แก่ขึ้นตามพื้นที่เข้มลง
            if theme.activeDuo != nil { return ink.covered(by: 0, alpha: 0.16) }
            return ink.isLight ? ink.covered(by: 1, alpha: 0.58) : ink.covered(by: 0, alpha: 0.16)
        case .dim:
            let lum = RGB(slab(theme)).luminance
            return InkStyle(ink: .night, base: theme.duoLight ?? .white,
                            ground: InkGround(lo: lum, hi: lum))
        }
    }

    /// clip เนื้อหาเข้ารูปกล่อง — ยกเว้นก้อนข้อความ (ดูเหตุผลที่ `isText`)
    @ViewBuilder
    private static func clipped<V: View, S: Shape>(_ v: V, _ shape: S, unless skip: Bool) -> some View {
        if skip { v } else { v.clipShape(shape) }
    }
}
