import SwiftUI
import PhosphorSwift

// MARK: - ตรารับรอง · Verified by Sale Here
//
// ใบที่ห้าของสำรับโปสเตอร์ และเป็นใบเดียวที่ **เนื้อหาคือคำรับรอง** ไม่ใช่ตัวเลขหรือรูป
//
// # ทำไมเป็น widget ไม่ใช่ป้าย
//
// ตราที่แปะมุมการ์ดคือสิ่งที่ Sale Here ทำ *กับ* งานของเจ้าของ — ใบนี้กลับด้าน:
// เจ้าของเป็นคน **หยิบคำรับรองมาวางเอง** เหมือนแขวนใบประกาศไว้ที่ผนังร้าน
// มันจึงต้องสวยพอที่คนอยากแขวน ไม่ใช่แค่ถูกต้องพอที่ระบบอยากแปะ
//
// # ภาษาของใบนี้: เอกสารมีค่า
//
// ธนบัตร · ใบหุ้น · หนังสือเดินทาง ใช้ของสามอย่างบอกว่า "ฉันเป็นของแท้" โดยไม่ต้องมีโลโก้ใหญ่:
// **ลายกิโยเช่** (เส้นโค้งซ้อนที่ถ่ายเอกสารไม่ติด) · **เหรียญตราประทับ** · **ตัวอักษรวิ่งรอบตรา**
// ทั้งสามอย่างอยู่บนใบนี้ และ **ทุกสีคิดจากเฉดของการ์ด** — แผ่นกับหมึกสองสีเหมือนโปสเตอร์ใบอื่นในสำรับ
// (รอบแรกเหรียญเป็นฟอยล์รุ้งที่หมุนได้ ผู้ใช้ปฏิเสธ: มันดึงความสนใจจากการ์ดของเจ้าของ — ดู `VerifiedSeal`)
//
// # ตราทรงเดียวกับตราเขียวของแอปหลัก
//
// กลีบแปดกลีบของเหรียญคือทรงเดียวกับ `ic-seal-check` ที่คนเห็นในแอป Sale Here ทุกวัน
// ลายเซ็นต้องเป็นตัวจริง ไม่ใช่ตัวเลียน (ดู `IssuerStrip`) — ใบนี้จึงไม่ประดิษฐ์ทรงตราใหม่

/// ค่าคงที่ของผัง — หน่วยเดียวกับ `WidgetKind.defaultSize` (366 × 232)
enum VS {
    static let w: CGFloat = 366
    static let h: CGFloat = 232
    static let pad: CGFloat = 18

    /// ศูนย์กลางเหรียญ วัดจากขอบซ้ายของผัง — เหรียญกินราว 45% ของแผ่น ตัวอักษรได้ที่เหลือ
    static let medalX: CGFloat = 94
    /// รัศมีของวงตัวอักษร · เหรียญฟอยล์ · ลายกิโยเช่ (ใหญ่กว่าแผ่นโดยตั้งใจ ให้ขอบแผ่นตัด)
    static let ringR: CGFloat = 68
    static let foilR: CGFloat = 50
    static let laceR: CGFloat = 138

    /// คอลัมน์ตัวอักษรเริ่มตรงไหน
    static let colX: CGFloat = 182

    static let cap1: CGFloat = 22
    static let cap2: CGFloat = 34
}

/// หน้าตาของตรารับรอง — เจ้าของเลือกให้เข้ากับการ์ดของตัวเอง (ถาดของชิ้น แถว "แบบ")
///
/// สามแบบที่ผู้ใช้เลือกจากผังตัวเลือก 8 แบบ (1 ต.ค. 2569): ข้อมูลชุดเดียวกัน หมึกของการ์ดเหมือนกัน
/// ต่างกันที่ **เอกสารที่มันยืมภาษามา** — ใบประกาศ · ธนบัตร · โปสเตอร์ตัวอักษร
/// (เคยมีแบบพาสปอร์ต ผู้ใช้ให้ถอดวันเดียวกัน — ค่า "passport" ในไฟล์เก่าตกไปเป็นเหรียญ)
enum SealStyle: String, CaseIterable, Identifiable {
    case medal, note, type
    var id: String { rawValue }

    var name: String {
        switch self {
        case .medal:    return "เหรียญ"
        case .note:     return "ธนบัตร"
        case .type:     return "ตัวพิมพ์"
        }
    }
}

// MARK: - ข้อเท็จจริงที่ตรานี้รับรอง

/// สิ่งที่ Sale Here ตรวจแล้วของเจ้าของการ์ด — **แหล่งเดียว** ที่ทั้ง widget และแผ่นตรวจสอบอ่าน
///
/// ตรานี้รับรอง *ข้อเท็จจริง* ไม่ใช่คำสัญญา: ตัวตน · ความเป็นเจ้าของช่อง · ที่มาของยอด
/// ประวัติงานเป็นเรื่องของชั้นหลักฐานอีกชุด (`proofWork`) ไม่รวมในตรา หน้าใหม่จึงได้ตราตั้งแต่วันแรก
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

// MARK: - วัสดุ

/// หมึกและแผ่นของใบนี้ — ทุกสีคิดจากเฉดของธีม (สูตรเดียวกับ `StatPosterSkin`)
struct VerifiedSealSkin {
    var papered: Bool
    var plate: Color
    var ink: Color
    var soft: Color
    var accent: Color
    var hair: Color
    /// สีของลายกิโยเช่ — หมึกเดียวกับตัวอักษรแต่จางจนเป็นผิวของแผ่น ไม่ใช่ลวดลาย
    var lace: Color
    /// สีที่ใช้เจาะเครื่องหมายถูกลงบนฟอยล์ — ต้องเข้มพอจะอ่านออกบนรุ้งทุกเฉด
    var punch: Color

    static func make(_ surface: WidgetSurface, theme: CardTheme, on ink: InkStyle) -> VerifiedSealSkin {
        guard surface == .glass else {
            return VerifiedSealSkin(papered: surface == .pane, plate: .clear,
                                    ink: ink.text(0.95), soft: ink.text(0.58),
                                    accent: theme.accent, hair: ink.line(0.24),
                                    lace: ink.line(ink.isLight ? 0.16 : 0.13),
                                    // ไม่มีแผ่นของตัวเอง = เหรียญนั่งบนพื้นการ์ดตรง ๆ เครื่องหมายถูกจึงต้องเป็น **สีพื้นของการ์ด**
                                    // (เคยเป็นเทาดำ/ขาวกลาง ๆ — บนการ์ดเลือดหมูได้ติ๊กสีดำที่ไม่ใช่สีของใบ · ผู้ใช้ 1 ต.ค. 2569)
                                    punch: theme.backdropColors.top.mixed(with: theme.backdropColors.bottom, by: 0.5))
        }
        // การ์ดโทนสว่าง = แผ่นของตราเป็น **สีอ่อนของธีม** หมึกเป็นสีเข้มของธีม — โทนของตราตามโทนพื้นหลังเสมอ
        //
        // เดิมแผ่นเข้มทุกกรณี — บนการ์ดชมพูสว่างได้แผ่นม่วงเข้มก้อนเดียวท่ามกลางของสีพาสเทล แล้วผู้ใช้ถามว่า
        // "ทำไมมันเป็นชมพูโทนมืด" · รอบแรกยกเว้นคู่สีไว้ ผู้ใช้ให้ตามทั้งหมด: "เอาให้มันเป็นโทนตาม Theme พื้นหลัง"
        // (1 ต.ค. 2569) · คู่สี: แผ่น = สีพื้นของคู่ที่กดลงนิดเดียวให้ยังเห็นขอบแผ่น · หมึก = สีเข้มของคู่
        if theme.activeInk.isLight {
            let plate: Color, dark: Color
            if let c = theme.duoColors {
                plate = c.bg.mixed(with: c.ink, by: 0.10)
                dark = c.ink
            } else {
                let grey = theme.customHue == nil && theme.palette == .noir
                plate = Color(hue: theme.backdropHue, saturation: grey ? 0.03 : 0.20, brightness: 0.975)
                dark = PosterPlate.plate(theme)
            }
            return VerifiedSealSkin(papered: true, plate: plate,
                                    ink: dark, soft: dark.opacity(0.66),
                                    accent: dark, hair: dark.opacity(0.22),
                                    lace: dark.opacity(0.09), punch: plate)
        }
        let cream = PosterPlate.cream(theme)
        let plate = PosterPlate.plate(theme)
        return VerifiedSealSkin(papered: true, plate: plate,
                                ink: cream, soft: cream.opacity(0.64),
                                accent: theme.rawAccent, hair: cream.opacity(0.24),
                                lace: cream.opacity(0.10), punch: plate)
    }
}

// MARK: - ใบ

struct VerifiedSealWidget: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var cardInk
    @Environment(\.widgetSealStyle) private var style
    let theme: CardTheme
    let size: CGSize


    var body: some View {
        PosterSheet(design: CGSize(width: VS.w, height: VS.h), frame: size) { box in
            sheet(box)
        }
        .linkSlot(VerifiedFacts.sheetURL)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Verified by Sale Here")
    }

    private func sheet(_ box: CGSize) -> some View {
        // ใบนี้มีหน้าตาเดียวคือ **ตอนผ่านแล้ว** — ยังไม่ยืนยันตัวตนก็วาดแบบเดียวกันด้วยชุดตัวอย่าง
        // แล้วให้ชั้นล็อกของ `WidgetChrome` บอกสถานะ (เคยมีร่าง "PENDING with" · ผู้ใช้ให้ถอด 1 ต.ค. 2569)
        let facts = VerifiedFacts.sealed ? VerifiedFacts.current : VerifiedFacts.sample
        let skin = VerifiedSealSkin.make(surface, theme: theme, on: cardInk)
        let shape = RoundedRectangle(cornerRadius: skin.papered ? min(theme.radius, 20) : 0,
                                     style: .continuous)
        // ของบนแผ่นกว้างเท่าผังเสมอแล้วจัดกลาง — ที่ว่างที่ได้มาคือขอบสองข้าง (ดู `PosterSheet`)
        let inset = (box.width - VS.w) / 2
        let cy = box.height / 2

        return ZStack(alignment: .topLeading) {
            Color.clear

            if surface == .glass {
                skin.plate
                PlatePatternLayer(sheet: skin.plate)
                EdGrain(count: 280, opacity: 0.045, tint: .white)
            }

            switch style {
            case .medal:
                // ── ลายกิโยเช่ · ศูนย์กลางเดียวกับเหรียญ ใหญ่กว่าแผ่นแล้วให้ขอบแผ่นตัด
                Guilloche(color: skin.lace)
                    .frame(width: VS.laceR * 2, height: VS.laceR * 2)
                    .position(x: inset + VS.medalX, y: cy)
                    .scrubSlide(scrub.d, travel: -VS.w * 0.10, fade: 0.9, eased: false)

                medal(facts, skin: skin)
                    .position(x: inset + VS.medalX, y: cy)

                column(facts, skin: skin)
                    .frame(width: VS.w - VS.colX - VS.pad, height: box.height, alignment: .leading)
                    .offset(x: inset + VS.colX)
            case .note:     note(facts, skin: skin, box: box)
            case .type:     typePoster(facts, skin: skin, box: box)
            }
        }
        .frame(width: box.width, height: box.height)
        .clipShape(shape)
    }

    // MARK: เหรียญ

    /// สามชั้นจากนอกเข้าใน — วงตัวอักษร · เส้นวง · เหรียญฟอยล์แปดกลีบ
    private func medal(_ facts: VerifiedFacts, skin: VerifiedSealSkin) -> some View {
        let ring = "VERIFIED BY SALE HERE  ✦  IDENTITY  ✦  CHANNELS  ✦  NUMBERS  ✦  "
        // หมุนตามนิ้วตอนปัดหน้าเท่านั้น — เคยหมุนเองตลอดเวลา แต่ของที่ขยับไม่หยุดแย่งสายตาจากงานของเจ้าของ
        let spin = Angle.degrees(Double(scrub.d) * 70)

        return ZStack {
            RingText(text: ring, radius: VS.ringR, size: 7.2, color: skin.ink.opacity(0.78))
                .rotationEffect(spin)

            Circle().strokeBorder(skin.hair, lineWidth: 0.7)
                .frame(width: (VS.ringR - 9) * 2, height: (VS.ringR - 9) * 2)
            Circle().strokeBorder(skin.hair.opacity(0.7), lineWidth: 0.7)
                .frame(width: (VS.ringR + 9) * 2, height: (VS.ringR + 9) * 2)

            VerifiedSeal(radius: VS.foilR, punch: skin.punch, tint: skin.ink)
        }
        .frame(width: (VS.ringR + 12) * 2, height: (VS.ringR + 12) * 2)
        .scrubSlide(scrub.d, travel: -VS.w * 0.04, fade: 0.95, eased: false)
    }

    // MARK: คอลัมน์ตัวอักษร

    private func column(_ facts: VerifiedFacts, skin: VerifiedSealSkin) -> some View {
        let w = VS.w - VS.colX - VS.pad
        let l1 = "VERIFIED by"
        let fs1 = Ed.fitted(l1, weight: .heavy, width: w * 0.74, cap: VS.cap1, floor: 12)

        return VStack(alignment: .leading, spacing: 0) {
            // บรรทัดบนผสมสองฟอนต์ตามกติกาของสำรับ · บรรทัดล่างคือ **ตัวเขียน Sale Here ตัวจริง**
            // (รอบแรกพิมพ์คำว่า SALE HERE ด้วยฟอนต์ของการ์ด — ถูกต้องแต่ไม่มีใครจำได้ว่าเป็น Sale Here
            // ตัวเขียนสองบรรทัดนี้คือสิ่งที่คนเห็นในแอปทุกวัน ลายเซ็นต้องเป็นตัวจริง ไม่ใช่ตัวเลียน)
            VStack(alignment: .leading, spacing: 1) {
                mixedLine(l1, size: fs1, color: skin.ink)
                    .lineLimit(1).minimumScaleFactor(0.5)
                Image(SHIcon.wordmark)
                    .renderingMode(.template)
                    .resizable().scaledToFit()
                    .frame(height: 62)
                    .foregroundStyle(skin.ink)
                    .accessibilityLabel("Sale Here")
            }
            .scrubSlide(scrub.d, travel: -VS.w * 0.22, fade: 0.84, eased: false)

            Rectangle().fill(skin.accent).frame(height: 1.4)
                .padding(.top, 6)
                .scrubVeil(scrub.d, lead: 0.1, drop: 14, pull: 18)

            VStack(spacing: 4) {
                // เฉพาะข้อที่ผ่านแล้ว — แถว "รอเชื่อม / รอตรวจ" บนใบที่พาดหัวว่า VERIFIED คือร่างรอที่ผู้ใช้ให้ถอด
                // (ยืนยันตัวตนอย่างเดียวก็ได้ตรา · ผูกช่องแล้วแถวช่องกับยอดค่อยขึ้นเพิ่ม)
                ForEach(facts.core.filter(\.ok)) { r in
                    factRow(r, skin: skin)
                        .scrubVeil(scrub.d, lead: 0.12 + Double(r.id) * 0.06, drop: 14, pull: 10)
                }
            }
            .padding(.top, 8)

            Spacer(minLength: 4)

            HStack(alignment: .bottom, spacing: 6) {
                // วงแดงของผู้ออก — สีแบรนด์ที่เดียวบนแผ่น และเป็นสิ่งที่ตาจับได้จากภาพรวมว่าใบนี้ของ Sale Here
                SaleHereMark(size: 21)
                VStack(alignment: .leading, spacing: 1) {
                    Text("STAR CARD NO.")
                        .font(Signature.mono(6, .semibold)).tracking(0.9)
                        .foregroundStyle(skin.soft.opacity(0.8))
                    Text(facts.serial)
                        .font(Signature.mono(9, .bold)).tracking(0.6)
                        .foregroundStyle(skin.soft)
                }
                Spacer(minLength: 0)
                // ตราจริง ขนาดใกล้ของจริง ย้อมหมึกของแผ่น — ผู้ออกคำรับรองเซ็นชื่อมุมขวาล่าง
                StarLockup(height: 20, tint: skin.ink.opacity(0.92))
            }
            .scrubVeil(scrub.d, lead: 0.3, drop: 12, pull: 8)
        }
        .padding(.top, 14)
        .padding(.bottom, 13)
    }

    // MARK: แบบธนบัตร

    /// วันที่ของแถวตัวตน — ค่าเดียวที่ทุกแบบพิมพ์ (แถวช่องกับยอดมีเฉพาะแบบที่มีที่ให้)
    private func identityDate(_ facts: VerifiedFacts) -> String {
        facts.rows.first { $0.id == 0 }?.value ?? Signature.verifiedOn
    }

    /// กรอบเส้นคู่ · ตัวพิมพ์จิ๋ววิ่งขอบบนล่าง · เลขการ์ดซ้ำสองมุมทแยง — ไวยากรณ์ของธนบัตรกับใบหุ้น
    /// ตัวเขียน Sale Here อยู่กลางแผ่นเหมือนชื่อธนาคารผู้ออก
    private func note(_ facts: VerifiedFacts, skin: VerifiedSealSkin, box: CGSize) -> some View {
        let micro = String(repeating: "SALE HERE STAR · VERIFIED CREATOR · ", count: 8)
        let microLine = Text(micro)
            .font(Signature.mono(4.5, .medium)).tracking(1)
            .foregroundStyle(skin.soft.opacity(0.75))
            .lineLimit(1).fixedSize()
            .frame(width: box.width - 44, alignment: .leading).clipped()
        let serial = Text(facts.serial)
            .font(Signature.mono(11, .bold)).tracking(0.9)
            .foregroundStyle(skin.ink)

        return ZStack {
            Guilloche(color: skin.lace)
                .frame(width: VS.laceR * 2, height: VS.laceR * 2)
                .scrubSlide(scrub.d, travel: -VS.w * 0.10, fade: 0.9, eased: false)

            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(skin.hair, lineWidth: 1).padding(8)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(skin.hair, lineWidth: 0.6).padding(11)

            VStack { microLine; Spacer(minLength: 0); microLine }
                .padding(.vertical, 15)

            VStack {
                HStack(alignment: .top) {
                    serial
                    Spacer(minLength: 0)
                    VerifiedSeal(radius: 15, punch: skin.punch, tint: skin.ink, compact: true)
                }
                Spacer(minLength: 0)
                HStack(alignment: .bottom) {
                    StarLockup(height: 20, tint: skin.ink.opacity(0.92))
                    Spacer(minLength: 0)
                    serial
                }
            }
            .padding(.horizontal, 22).padding(.top, 24).padding(.bottom, 24)

            VStack(spacing: 2) {
                Text("VERIFIED CREATOR")
                    .font(Signature.mono(8.5, .semibold)).tracking(2.9)
                    .foregroundStyle(skin.ink)
                Image(SHIcon.wordmark)
                    .renderingMode(.template)
                    .resizable().scaledToFit()
                    .frame(height: 104)
                    .foregroundStyle(skin.ink)
                    .accessibilityLabel("Sale Here")
                Text("ตัวตนจริง · \(identityDate(facts))")
                    .font(.sh(9, .semibold))
                    .foregroundStyle(skin.soft)
            }
            .scrubSlide(scrub.d, travel: -VS.w * 0.16, fade: 0.84, eased: false)
        }
        .frame(width: box.width, height: box.height)
    }

    // MARK: แบบตัวพิมพ์

    /// โปสเตอร์ตัวอักษร: VERIFIED เป็นพาดหัว · by + ตัวเขียน Sale Here · เหรียญติ๊กถูกดวงเดียว
    ///
    /// เหรียญใช้ **หมึกของใบ** เหมือนตัวอักษรข้าง ๆ (เครื่องหมายถูกเจาะถึงสีแผ่น) — รอบแรกเป็นแดงของแบรนด์
    /// ซึ่งไม่ขยับตามพื้นหลังที่เจ้าของเลือก ผู้ใช้ให้แก้: "โทนสี tick ถูก มันต้องเป็นสีของมัน" (1 ต.ค. 2569)
    ///
    /// พาดหัวกินราวหกส่วนสิบของความกว้าง ไม่ใช่เต็มแผ่น — ผังแรกพิมพ์เต็มกว้างแล้วผู้ใช้บอกว่าใหญ่ไป
    /// (1 ต.ค. 2569) คำว่า VERIFIED ต้องเด่น แต่ตัวเขียน Sale Here ต้องยังเป็นของชิ้นที่สองที่ตาเห็น
    private func typePoster(_ facts: VerifiedFacts, skin: VerifiedSealSkin, box: CGSize) -> some View {
        let w = box.width - VS.pad * 2
        let fs = Ed.fitted("VERIFIED", weight: .black, width: w * 0.60, cap: 50, floor: 30)
        let passed = facts.core.filter(\.ok).map(\.title).joined(separator: " · ")

        return VStack(alignment: .leading, spacing: 0) {
            Text("VERIFIED")
                .font(.sh(fs, .black)).kerning(-fs * 0.04)
                .foregroundStyle(skin.ink)
                .lineLimit(1).fixedSize()
                .scrubSlide(scrub.d, travel: -VS.w * 0.22, fade: 0.84, eased: false)

            HStack(alignment: .center, spacing: 9) {
                Text("by")
                    .font(CardFont.serif.font(30, .regular).italic())
                    .foregroundStyle(skin.ink)
                    .offset(y: -4)
                Image(SHIcon.wordmark)
                    .renderingMode(.template)
                    .resizable().scaledToFit()
                    .frame(height: 86)
                    .foregroundStyle(skin.ink)
                    .accessibilityLabel("Sale Here")
                Spacer(minLength: 0)
                VerifiedSeal(radius: 36, punch: skin.punch, tint: skin.ink)
            }
            .frame(maxHeight: .infinity)
            .scrubSlide(scrub.d, travel: -VS.w * 0.12, fade: 0.9, eased: false)

            Rectangle().fill(skin.hair).frame(height: 1)
            HStack(spacing: 8) {
                Text(passed)
                    .font(.sh(9, .semibold))
                    .lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Text(facts.serial)
                    .font(Signature.mono(8.5, .semibold)).tracking(0.5)
                    .lineLimit(1).fixedSize()
            }
            .foregroundStyle(skin.soft)
            .padding(.top, 7)
        }
        .padding(.horizontal, VS.pad).padding(.top, 14).padding(.bottom, 12)
        .frame(width: box.width, height: box.height)
    }

    /// ชื่อข้อ ···· ค่า — เส้นจุดไข่ปลาแบบสารบัญ/ใบเสร็จ ตาวิ่งจากข้อไปหาวันที่ได้เอง
    private func factRow(_ r: VerifiedFacts.Row, skin: VerifiedSealSkin) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(r.title)
                .font(.sh(10.5, .semibold))
                .foregroundStyle(r.ok ? skin.ink : skin.soft)
                .lineLimit(1).fixedSize()
            DotLeader(color: skin.hair)
            Text(r.value)
                .font(Signature.mono(9, .semibold))
                .foregroundStyle(r.ok ? skin.soft : skin.accent)
                .lineLimit(1).fixedSize()
        }
    }

    /// คำแรกหนา · ที่เหลือเซริฟเอียง (ก๊อปกติกาจาก `StatPosterWidget.mixedLine` — พาดหัวใบนี้พิมพ์ทับไม่ได้
    /// เพราะเป็นคำของผู้รับรอง จึงไม่ผ่าน `tune`)
    private func mixedLine(_ raw: String, size: CGFloat, color: Color) -> Text {
        let parts = raw.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let head = Text(String(parts.first ?? "").uppercased())
            .font(.sh(size, .heavy))
            .kerning(-size * 0.03)
        guard parts.count > 1 else { return head.foregroundColor(color) }
        let tail = Text(" " + String(parts[1]))
            .font(CardFont.serif.font(size * 1.06, .regular).italic())
        return (head + tail).foregroundColor(color)
    }
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

/// เส้นจุดไข่ปลาที่ยืดเต็มช่องว่างระหว่างชื่อข้อกับค่า
struct DotLeader: View {
    let color: Color

    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: geo.size.height - 2.5))
                p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - 2.5))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [0.1, 3.4]))
        }
        .frame(height: 10)
        .frame(maxWidth: .infinity)
    }
}
