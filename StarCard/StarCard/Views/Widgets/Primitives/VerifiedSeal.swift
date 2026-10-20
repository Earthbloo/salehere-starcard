// ชิ้นส่วนกลางที่ตัววาดผัง (SpecPainter) และหน้าจออื่นเรียกใช้ — ไม่ผูกกับ widget ตัวใด
import SwiftUI
import PhosphorSwift


// MARK: - ข้อเท็จจริงที่ตรานี้รับรอง

/// สิ่งที่ Sale Here ตรวจแล้วของเจ้าของการ์ด — **แหล่งเดียว** ที่ทั้ง widget และแผ่นตรวจสอบอ่าน
///
/// ตรานี้รับรอง *ข้อเท็จจริง* ไม่ใช่คำสัญญา: ตัวตน · ความเป็นเจ้าของช่อง · ที่มาของยอด
/// ประวัติงานเป็นเรื่องของชั้นหลักฐานอีกชุด (หมวด `verified`) ไม่รวมในตรา หน้าใหม่จึงได้ตราตั้งแต่วันแรก
struct VerifiedFacts {
    struct Row: Identifiable {
        let id: Int
        let title: String
        let detail: String
        let value: String
        let ok: Bool
        /// แถวที่ตราต้องผ่าน — ประวัติงานเป็นแถวเสริม ไม่มีก็ยังได้ตรา (หน้าใหม่ต้องได้ตราตั้งแต่วันแรก)
        var required = true
    }

    let rows: [Row]
    let serial: String
    /// ได้ตราเมื่อผ่านครบทุกแถว — ตราที่ขึ้นทั้งที่ยังมียอดพิมพ์เองคือคำโฆษณา ไม่ใช่คำรับรอง
    var verified: Bool { core.allSatisfy(\.ok) }
    /// สามแถวที่ตรารับรอง — widget ตรารับรองวาดชุดนี้ · แผ่นตรวจสอบวาดครบทุกแถว
    var core: [Row] { rows.filter(\.required) }

    /// ยอดผู้ติดตามทุกช่องมาจากแพลตฟอร์มไหม — ใบที่โชว์ยอดใช้ตัดสินว่าจะปั๊มตรา/ติดป้าย Verified ได้หรือยัง
    static var numbersVerified: Bool {
        if labForce { return true }
        let s = Profile.me.creator.socials
        return !s.isEmpty && s.allSatisfy { $0.source.isVerified }
    }

    /// โต๊ะตรวจงาน (`VerifiedLab`) บังคับสถานะ "ผ่านครบ" เพื่อดูหน้าตาเต็มโดยไม่ต้องแก้ข้อมูลในเครื่อง
    static var labForce = ProcessInfo.processInfo.arguments.contains("-labVerified")

    /// ยืนยันตัวตนผ่านแล้ว — ตรารับรองปลดล็อกด้วยข้อนี้ข้อเดียว (รอทีมงานตรวจ = ยังล็อก)
    static var sealed: Bool { labForce || StarFlow.shared.isVerified }

    /// หน้าตาตอนผ่านครบ — ตรารับรองวาดชุดนี้ระหว่างที่ยังล็อก (ผู้ใช้ 1 ต.ค. 2569: "ไม่ต้องมี pending
    /// ให้เห็นแบบ final ไปเลย แค่ lock ถ้ายัง") ชั้นเทากับกุญแจของ `WidgetChrome` เป็นตัวบอกว่ายังไม่ได้
    static var sample: VerifiedFacts {
        VerifiedFacts(rows: [
            // ยังไม่ผ่าน = ยังไม่มีวันที่จริง — ใส่วันนี้ให้แถวเต็มเหมือนตอนผ่านแล้ว
            Row(id: 0, title: "ตัวตนจริง", detail: "ตรวจบัตรประชาชนแล้ว",
                value: StarFlow.shared.verifiedAt == nil ? Signature.shortDate(Date()) : Signature.verifiedOn, ok: true),
            Row(id: 1, title: "เจ้าของช่องจริง", detail: "TikTok · Instagram · YouTube", value: "3 ช่อง", ok: true),
            Row(id: 2, title: "ยอดจากแพลตฟอร์ม", detail: "ไม่ใช่ตัวเลขพิมพ์เอง", value: "2 ชม.ที่แล้ว", ok: true),
        ], serial: serial(for: Profile.me.handle))
    }

    static var current: VerifiedFacts {
        if labForce {
            return VerifiedFacts(rows: sample.rows + workRow(Profile.me.creator), serial: sample.serial)
        }
        let c = Profile.me.creator
        let linked = c.socials.filter { $0.source.isVerified }
        let allLinked = !c.socials.isEmpty && linked.count == c.socials.count
        let fresh = linked.first?.syncedAgo ?? ""
        let names = linked.prefix(3).map(\.type.name).joined(separator: " · ")

        // ตัวตนจริง = ยืนยันตัวตน (KYC) ใน Star Profile ผ่านแล้ว — สถานะเดียวกับตราบนชื่อ (`CreatorProfile.verified`)
        let identity = c.verified
        return VerifiedFacts(rows: [
            // วันที่ยืนยันตัวตนยังเป็นค่าจำลอง (ดู `Signature.verifiedOn`) จนกว่าจะต่อ `userVerify`
            Row(id: 0, title: "ตัวตนจริง", detail: identity ? "ตรวจบัตรประชาชนแล้ว" : "ยังไม่ได้ยืนยันตัวตน",
                value: identity ? Signature.verifiedOn : "รอยืนยัน", ok: identity),
            Row(id: 1, title: "เจ้าของช่องจริง",
                detail: names.isEmpty ? "ยังไม่ได้เชื่อมบัญชี" : names,
                value: linked.isEmpty ? "รอเชื่อม" : "\(linked.count) ช่อง", ok: !linked.isEmpty),
            Row(id: 2, title: "ยอดจากแพลตฟอร์ม",
                detail: allLinked ? "ไม่ใช่ตัวเลขพิมพ์เอง" : "บางช่องยังกรอกเอง",
                value: allLinked ? (fresh.isEmpty ? "ล่าสุด" : fresh) : "รอตรวจ", ok: allLinked),
        ] + workRow(c), serial: Self.serial(for: Profile.me.handle))
    }

    /// แถวเสริม — คนที่แตะป้าย "Verified by" บนผลงานมาถึงแผ่นนี้ต้องเจอคำตอบเรื่องงานด้วย
    private static func workRow(_ c: CreatorProfile) -> [Row] {
        let n = c.track.works.count
        guard n > 0 else { return [] }
        return [Row(id: 3, title: "ประวัติงานในระบบ", detail: "งานที่ทำผ่าน Sale Here",
                    value: "\(n) งาน", ok: true, required: false)]
    }

    /// เลขประจำการ์ด — คงที่ต่อชื่อผู้ใช้ (ของจริงจะเป็นเลขที่ระบบออกให้)
    private static func serial(for handle: String) -> String {
        var h: UInt32 = 2166136261
        for b in handle.utf8 { h = (h ^ UInt32(b)) &* 16777619 }
        return String(format: "TH %07d", Int(h % 9_000_000) + 1_000_000)
    }

    /// ปลายทางของการแตะในหน้าดู — `CardScreen.open` รับไปเปิดแผ่นตรวจสอบ
    static let sheetURL = URL(string: "starcard://verified")!
}


// MARK: - ชิ้นส่วน

/// เหรียญรับรองแปดกลีบ — **หมึกสีเดียว** ของพื้นที่ที่มันนั่งอยู่ เครื่องหมายถูกเจาะทะลุถึงสีพื้น
///
/// # ทำไมไม่ใช่ฟอยล์รุ้ง
///
/// รอบก่อนเหรียญนี้เป็นฟอยล์รุ้งที่หมุนรับแสง ผู้ใช้ปฏิเสธทุกจุด: "มันดึงความสนใจของ card ของ user เกินไป"
/// ของที่มีห้าสีและขยับได้ชนะสายตาทุกอย่างบนการ์ด ซึ่งเป็นงานของเจ้าของ ไม่ใช่ของเรา
/// ตรารับรองต้อง **อ่านออก** ไม่ใช่ **ดัง** — ทรงกลีบกับเครื่องหมายถูกคือสิ่งที่คนอ่านว่า "ยืนยันแล้ว"
/// สีของมันจึงเป็นหมึกเดียวกับตัวอักษรรอบ ๆ (ครีมบนแผ่นเข้ม · ถ่านบนกระดาษ · ขาวบนเวทีของเรา)
struct VerifiedSeal: View {
    let radius: CGFloat
    /// สีที่ใช้เจาะเครื่องหมายถูก — สีของพื้นใต้เหรียญ
    let punch: Color
    /// หมึกของเหรียญ — สีเดียวกับตัวอักษรที่อยู่ข้าง ๆ
    var tint: Color = .white
    /// ตัวจิ๋ว (ข้างชื่อ · ในป้าย · ในแถบ) — ตัดเส้นประในกับเงาออก ที่ขนาดนี้มันอ่านเป็นฝุ่น
    var compact: Bool = false

    var body: some View {
        let d = radius * 2
        ZStack {
            SealScallop().fill(tint)
            if !compact {
                // ผิวโค้งนิดเดียว — ครึ่งบนสว่างกว่าครึ่งล่าง ให้เหรียญเป็นของนูน ไม่ใช่ไอคอนแบน
                SealScallop().fill(LinearGradient(colors: [.white.opacity(0.22), .black.opacity(0.10)],
                                                  startPoint: .top, endPoint: .bottom))
                SealScallop()
                    .stroke(punch.opacity(0.45), style: StrokeStyle(lineWidth: 0.7, dash: [1.2, 2.4]))
                    .frame(width: d * 0.80, height: d * 0.80)
            }
            CheckStroke()
                .stroke(punch, style: .init(lineWidth: d * 0.105, lineCap: .round, lineJoin: .round))
                .frame(width: d * 0.44, height: d * 0.34)
        }
        .frame(width: d, height: d)
        .shadow(color: .black.opacity(compact ? 0 : 0.30), radius: compact ? 0 : 6, y: compact ? 0 : 3)
    }
}


/// ตราเขียวตัวเล็กสำหรับแถวรายการ — วาดเองเพราะ `ic-seal-check` ย้อมสีแล้วเครื่องหมายถูกหายไปทั้งดวง
struct MiniSeal: View {
    var size: CGFloat = 18
    var color: Color = Signature.green

    var body: some View {
        ZStack {
            SealScallop().fill(color)
            CheckStroke()
                .stroke(.white, style: .init(lineWidth: size * 0.12, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.42, height: size * 0.32)
        }
        .frame(width: size, height: size)
    }
}


/// กลีบแปดกลีบ ทรงเดียวกับตราเขียวของแอปหลัก (`ic-seal-check`)
struct SealScallop: Shape {
    var petals: Int = 8
    var depth: CGFloat = 0.075

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let R = min(rect.width, rect.height) / 2
        let steps = petals * 28
        var p = Path()
        for i in 0...steps {
            let t = Double(i) / Double(steps) * 2 * .pi
            let r = R * (1 - depth + depth * CGFloat(cos(Double(petals) * t)))
            let pt = CGPoint(x: c.x + r * CGFloat(cos(t)), y: c.y + r * CGFloat(sin(t)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}


struct CheckStroke: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.55))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}


/// ตัวอักษรวิ่งรอบวง — ฟอนต์โมโนจึงแบ่งมุมเท่ากันได้โดยไม่ต้องวัดทีละตัว
struct RingText: View {
    let text: String
    let radius: CGFloat
    var size: CGFloat = 7
    var color: Color = .white

    var body: some View {
        let chars = Array(text)
        ZStack {
            ForEach(chars.indices, id: \.self) { i in
                Text(String(chars[i]))
                    .font(Signature.mono(size, .bold))
                    .foregroundStyle(color)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(i) / Double(chars.count) * 360))
            }
        }
        .frame(width: radius * 2 + size * 2, height: radius * 2 + size * 2)
        .drawingGroup()
    }
}


/// ลายกิโยเช่ — เส้นคลื่นปิดวงซ้อนกันสองชุด (ลายเดียวกับที่พิมพ์กันปลอมบนธนบัตร)
struct Guilloche: View {
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let R = min(size.width, size.height) / 2
            // (จำนวนคลื่น · ความสูงคลื่น · รัศมีฐาน · จำนวนเส้น)
            let sets: [(Double, Double, Double, Int)] = [(16, 0.115, 0.86, 16), (9, 0.10, 0.60, 12)]
            for (n, amp, base, count) in sets {
                for k in 0..<count {
                    let phi = Double(k) / Double(count) * 2 * .pi / n
                    var p = Path()
                    let steps = 420
                    for i in 0...steps {
                        let t = Double(i) / Double(steps) * 2 * .pi
                        let r = R * (base + amp * sin(n * (t + phi)))
                        let pt = CGPoint(x: c.x + r * cos(t), y: c.y + r * sin(t))
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                    p.closeSubpath()
                    ctx.stroke(p, with: .color(color), lineWidth: 0.5)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
