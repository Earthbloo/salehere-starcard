import SwiftUI

// MARK: - สำรับ Gen Z
//
// ห้าแบบในไฟล์นี้ไม่ได้เพิ่ม "ข้อมูลใหม่" เลยสักตัว — ทุกตัวเล่าเรื่องเดียวกับแบบที่มีอยู่แล้ว
// ในตระกูลของมัน (โปรไฟล์ · แนะนำตัว · ผู้ติดตาม · รูปผลงาน · หมวดหมู่)
// ที่ต่างคือ **สำเนียง**: ของพวกนี้พูดด้วยภาษาที่คนอายุ 18–27 ใช้กันอยู่ทุกวัน
// ออร่า · โน้ตแปะ · การ์ดสรุปยอดปลายปี · สติปรูดจากตู้ถ่ายรูป · สติกเกอร์นูน
//
// กติกาสองข้อที่คุมทั้งไฟล์ ไม่ให้ "ว้าว" กลายเป็น "รก":
//
// 1. **หนึ่งแบบ หนึ่งวัสดุ** — แต่ละตัวเลือกพื้นผิวมาหนึ่งอย่างแล้วเล่นให้สุด
//    (แสง · กระดาษโน้ต · บล็อกสีทึบ · กระดาษภาพ · สติกเกอร์ไวนิล)
//    ห้ามผสมสองวัสดุในตัวเดียว เพราะนั่นคือจุดที่งานสาย Y2K กลายเป็นงานมั่ว
// 2. **ท่าเปลี่ยนหน้าต้องมาจากวัสดุนั้น** — สติกเกอร์ต้อง *ลอก* ไม่ใช่จางหาย
//    โน้ตต้อง *ถูกดึงออกจากกระดาน* · แผ่นภาพต้อง *ไถลออกจากช่องจ่าย* ทั้งแผ่น
//
// สีของวัสดุที่เป็น "ของจับต้องได้" (กระดาษโน้ต · กระดาษภาพ) ไม่ผูกกับ `cardInk` โดยตั้งใจ
// เหตุผลเดียวกับ `Paper` ใน `ProofWorkVariants.swift`: ถ้าโน้ตพลิกเป็นสีดำตามการ์ด
// อุปมา "กระดาษที่แปะไว้" จะหายไปทันที

/// วัสดุของสำรับนี้ — สีคงที่ ไม่พลิกตามหมึกการ์ด
private enum Vinyl {
    /// กระดาษโน้ตสีมัสตาร์ด
    static let sticky = Color(red: 1.00, green: 0.93, blue: 0.62)
    static let stickyDeep = Color(red: 0.98, green: 0.85, blue: 0.44)
    /// กระดาษภาพจากตู้ถ่ายรูป
    static let photoPaper = Color(red: 0.98, green: 0.98, blue: 0.97)
    /// หมึกดำอมม่วง — ดำสนิทบนสีสดอ่านแข็งเกินไป
    static let ink = Color(red: 0.10, green: 0.07, blue: 0.14)
    static let inkSoft = Color(red: 0.38, green: 0.33, blue: 0.44)
    /// ปากกาไฮไลต์
    static let marker = Color(red: 0.62, green: 0.96, blue: 0.72)
}

// MARK: - 01 · ออร่า

/// รูปโปรไฟล์ในซุ้มโค้ง ลอยอยู่กลางดวงแสงสามดวงที่เป็นสีของธีม
///
/// เทรนด์ 2026 · Aura photo — แสงรอบตัวคือบุคลิก ไม่ใช่ฉากหลัง คนรุ่นนี้อ่าน "ออร่าสีม่วง"
/// ออกมาเป็นคำอธิบายตัวตนได้ทันทีโดยไม่ต้องมีคำบรรยาย จึงเป็น hero ที่ใช้ตัวหนังสือน้อยที่สุดในชุด
///
/// # ท่าเปลี่ยนหน้า — "ออร่าหมุนสวนตัวคน"
///
/// ดวงแสงหมุนรอบซุ้มไปทางเดียวกับที่หน้ากำลังไปและบานออก ส่วนตัวคนถ่วงตัวสวนทาง
/// ความลึกจึงมาจาก **ทิศที่ต่างกันของสองชั้น** ไม่ใช่จากเงาหรือความจาง
struct HeroAura: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme
    let size: CGSize

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // แถบชื่อกินที่คงที่ ที่เหลือเป็นของภาพทั้งหมด — ภาพคือพระเอกของ hero ทุกตัว
            let footer = min(78, h * 0.26)
            let stage = max(60, h - footer)
            let archW = min(w * 0.68, stage * 0.82)

            VStack(spacing: 0) {
                ZStack {
                    aura(w: w, h: stage)
                    arch(width: archW, height: stage)
                }
                .frame(width: w, height: stage)

                nameBlock(w: w)
                    .frame(width: w, height: footer, alignment: .topLeading)
            }
        }
    }

    /// ดวงแสงสามดวง — สีธีมดิบสองดวง ขาวหนึ่งดวง
    /// ใช้สีดิบ (`rawAccent`) เพราะดวงแสงคือ *แหล่งกำเนิดแสง* ไม่ใช่หมึกที่เขียนบนการ์ด
    private func aura(w: CGFloat, h: CGFloat) -> some View {
        let r = min(w, h)
        return ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d))
            let s = Double(Scrub.dir(d))
            ZStack {
                Circle().fill(theme.rawAccent.opacity(0.95))
                    .frame(width: r * 0.78, height: r * 0.78)
                    .offset(x: -r * 0.3, y: -r * 0.2)
                Circle().fill(theme.rawAccentSoft.opacity(0.9))
                    .frame(width: r * 0.68, height: r * 0.68)
                    .offset(x: r * 0.32, y: r * 0.02)
                Circle().fill(Color.white.opacity(0.45))
                    .frame(width: r * 0.42, height: r * 0.42)
                    .offset(x: 0, y: r * 0.3)
            }
            // ฟุ้งแรงพอให้ไม่เห็นขอบวงกลม แต่ไม่แรงจนสามดวงละลายเป็นดวงเดียว
            // (ที่ r * 0.17 มันกลายเป็นแสงขาวก้อนเดียว สีของธีมหายไปหมด)
            .blur(radius: r * 0.13)
            .rotationEffect(.degrees(s * 34 * t))
            .scaleEffect(1 + 0.22 * t)
            .opacity(0.9 * Scrub.fade(t, after: 0.72))
        }
        .frame(width: w, height: h)
    }

    /// ตัวคนในซุ้มโค้ง — ทรงเดียวกับที่งานพอร์ตสายแฟชั่นใช้ ไม่ใช่วงกลม avatar
    private func arch(width: CGFloat, height: CGFloat) -> some View {
        let shape = ArchShape(footRadius: 14)
        return Color.clear
            .frame(width: width, height: height * 0.92)
            .overlay {
                WidgetPhoto(index: 1)
                    .aspectRatio(contentMode: .fill)
                    .scrubDolly(scrub.d, shift: width * 0.09, zoom: 0.2)
            }
            .clipShape(shape)
            .overlay(shape.stroke(.white.opacity(0.55), lineWidth: 1))
            .photoSlot(1)
            .overlay(alignment: .topTrailing) { sparkle(size: 15, at: 0.06) }
            .overlay(alignment: .bottomLeading) { sparkle(size: 11, at: 0.2) }
            .shadow(color: theme.rawAccent.opacity(0.45), radius: 22, y: 8)
    }

    /// ประกายที่มุมซุ้ม — หมุนสวนทางกันคนละดวงเพื่อไม่ให้อ่านเป็นไอคอนคู่แฝด
    private func sparkle(size s: CGFloat, at lead: Double) -> some View {
        ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d, lead: lead))
            SymbolIcon(name: SHIcon.sparkle, size: s, tint: .white)
                .rotationEffect(.degrees(Double(Scrub.dir(d)) * 90 * Double(t)))
                .scaleEffect(1 - 0.6 * t)
                .opacity(Scrub.fade(t, after: 0.5))
        }
        .frame(width: s, height: s)
        .padding(6)
    }

    private func nameBlock(w: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Text(Profile.me.name)
                    .font(.sh(min(28, w * 0.105), .black))
                    // kerning ไม่ใช่ tracking — tracking ตัดสระบน/วรรณยุกต์ไทยหลุดจากฐาน
                    .kerning(-0.7)
                    .foregroundStyle(
                        LinearGradient(colors: [ink.text(0.98), theme.accent],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .lineLimit(1).truncationMode(.tail)
                    // ช่องพิมพ์รับสีเดียวได้ ไม่ใช่ไล่เฉด — ใช้สีต้นทางของเฉด
                    // ตอนพิมพ์จึงอ่านออกเท่าเดิม แล้วกลับเป็นไล่เฉดทันทีที่ปิดช่อง
                    .editableText(.name, .init(size: min(28, w * 0.105), weight: .black,
                                               color: ink.text(0.98), tracking: -0.7))
                if Mock.creator.verified {
                    SymbolIcon(name: SHIcon.sealCheck, size: 12, tint: theme.accent)
                }
                Spacer(minLength: 0)
            }
            .scrubVeil(scrub.d, lead: 0.24, drop: 34, pull: 8)

            // เคยมีชิปยอดผู้ติดตามต่อท้าย — ถอดออกแล้ว
            // hero ตอบคำถาม "นี่คือใคร" ส่วนยอดผู้ติดตามตอบ "ใหญ่แค่ไหน" ซึ่งมี widget ของตัวเอง
            Text(Profile.me.tagline.uppercased())
                .font(.sh(9, .semibold)).tracking(1.8)
                .foregroundStyle(ink.text(0.45))
                .lineLimit(1).truncationMode(.tail)
                .editableText(.tagline, .init(size: 9, weight: .semibold,
                                              color: ink.text(0.45), tracking: 1.8,
                                              uppercase: true))
                .scrubVeil(scrub.d, lead: 0.06, drop: 24, pull: 16)
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 02 · โน้ตแปะ

/// ย่อหน้าแนะนำตัวที่ไม่ได้อ่านเหมือน "ข้อความในโปรไฟล์" แต่อ่านเหมือน **โน้ตที่เขียนแปะไว้**
///
/// คนรุ่นนี้โพสต์คำอธิบายตัวเองเป็นสกรีนช็อตแอปโน้ตกันจนเป็นภาษากลาง เพราะกระดาษหนึ่งแผ่น
/// บอกว่า "นี่คือเสียงของฉัน ไม่ใช่ก๊อปปี้ที่ใครเขียนให้" — ซึ่งตรงกับหน้าที่ของ widget ตัวนี้พอดี
///
/// # ท่าเปลี่ยนหน้า — "ถูกดึงออกจากกระดาน"
///
/// แผ่นเอียงเพิ่มขึ้นแล้วลอยขึ้นตามทิศนิ้ว ส่วนเทปกาวที่หัวแผ่น **เอียงสวนทาง** เหมือนยังเกาะกระดานอยู่
/// ตาจึงอ่านว่ากระดาษถูกดึง ไม่ใช่ทั้งภาพถูกเลื่อน
struct AboutNote: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    var body: some View {
        ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d))
            let s = Double(Scrub.dir(d))
            note
                .rotationEffect(.degrees(-1.4 + s * 6 * Double(t)), anchor: .top)
                .offset(y: -22 * t)
                .scaleEffect(1 - 0.06 * t, anchor: .top)
                .opacity(Scrub.fade(t, after: 0.74))
        }
        .padding(.horizontal, 4)
        .padding(.top, 7)
    }

    private var note: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                Text("โน้ตจากฉัน")
                    .font(.sh(10, .heavy)).tracking(0.6)
                    .foregroundStyle(Vinyl.ink.opacity(0.55))
                Spacer(minLength: 4)
            }
            .scrubVeil(scrub.d, lead: 0.3, drop: 18, pull: 6)

            Rectangle().fill(Vinyl.ink.opacity(0.14)).frame(height: 0.8)

            // เว้นที่ท้ายย่อหน้าไว้ให้บรรทัดไฮไลต์ที่ต้องอยู่ใต้มันเสมอ
            // ไม่งั้นย่อหน้ากินทั้งแผ่นแล้วบรรทัดปิดท้ายหลุดออกนอกกระดาษ
            EditableParagraph(field: .about,
                              style: .init(size: 13.5, weight: .medium,
                                           color: Vinyl.ink, lineSpacing: 6),
                              reserve: 8)
                .scrubVeil(scrub.d, lead: 0.1, drop: 30, pull: 14)

            // ปากกาไฮไลต์ปิดท้าย — บรรทัดเดียวที่ตาเห็นก่อนอ่านย่อหน้า
            Text(Profile.me.tagline)
                .font(.sh(11, .heavy))
                .foregroundStyle(Vinyl.ink)
                .lineLimit(1).truncationMode(.tail)
                .editableText(.tagline, .init(size: 11, weight: .heavy, color: Vinyl.ink))
                .padding(.horizontal, 4).padding(.vertical, 1)
                .background(Vinyl.marker)
                .scrubVeil(scrub.d, lead: 0.02, drop: 22, pull: 18)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(colors: [Vinyl.sticky, Vinyl.stickyDeep],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
        .overlay(alignment: .top) { tape }
    }

    /// เทปกาว — เอียงสวนทางแผ่นตอนถูกดึง คือสิ่งเดียวที่ทำให้ท่าอ่านออกว่า "ลอก"
    private var tape: some View {
        ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d))
            let s = Double(Scrub.dir(d))
            Rectangle()
                .fill(.white.opacity(0.5))
                .overlay(Rectangle().strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
                .frame(width: 58, height: 17)
                .rotationEffect(.degrees(-5 - s * 10 * Double(t)))
                .offset(y: -8)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        }
        .frame(width: 58, height: 17)
    }
}

// MARK: - 03 · การ์ดสรุปยอด

/// ยอดผู้ติดตามในหน้าตาของ "สรุปประจำปี" — บล็อกสีทึบ ตัวเลขยักษ์ อันดับเรียงลงมา
///
/// รูปแบบนี้คนรุ่นนี้อ่านออกทันทีว่าเป็น **สรุปที่ระบบคำนวณให้** ไม่ใช่ตัวเลขที่เจ้าตัวพิมพ์เอง
/// ซึ่งตรงกับความจริงของ widget ตัวนี้พอดี (ชั้น connected — ยอดมาจาก OAuth แก้ไม่ได้)
/// นั่นคือเหตุผลที่แบบนี้มีอยู่ ไม่ใช่เพราะมันดูสนุกกว่า
///
/// # ท่าเปลี่ยนหน้า — "สรุปถูกปิดทีละอันดับ"
///
/// ตัวเลขรวมถอดทีละหลัก (มิเตอร์เดียวกับ `StatGiant`) แล้วอันดับดับไล่จากท้ายขึ้นหัว
/// ปีที่เป็นเงาอยู่ข้างหลังไถลสวนทาง — ชั้นที่ใกล้ตาที่สุดเคลื่อนเร็วที่สุด กติกาเดิมของทั้งการ์ด
struct StatWrapped: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme
    let size: CGSize

    private var ranked: [SocialProfile] {
        Mock.creator.socials.sorted { $0.followerCount > $1.followerCount }
    }
    private var total: Int { Mock.creator.socials.reduce(0) { $0 + $1.followerCount } }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            // ปีเงาเกาะมุมบนขวา — มุมเดียวที่ว่างจริง เพราะตัวเลขรวมชิดซ้ายและอันดับอยู่ล่าง
            // เคยวางไว้มุมล่างขวาแล้วมันไปนอนอยู่หลังแถวอันดับจนตัวเลขอ่านยาก
            ZStack(alignment: .topTrailing) {
                // บล็อกสีดิบ — ตัวมันเองคือพื้นผิว จึงไม่พลิกตามหมึกการ์ด
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [theme.rawAccentSoft, theme.rawAccent],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))

                Text("2026")
                    .font(.sh(min(96, w * 0.34), .black))
                    .foregroundStyle(Vinyl.ink.opacity(0.11))
                    .rotationEffect(.degrees(-7))
                    .offset(x: 22, y: -14)
                    .fixedSize()
                    .scrubSlide(scrub.d, travel: -w * 0.4, fade: 0.8, eased: false)

                VStack(alignment: .leading, spacing: 0) {
                    Text("สรุปผู้ติดตามของคุณ".uppercased())
                        .font(.sh(9, .heavy)).tracking(1.6)
                        .foregroundStyle(Vinyl.ink.opacity(0.55))
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .scrubVeil(scrub.d, lead: 0.34, drop: 18, pull: 6)

                    ScrubDigits(text: Fmt.compact(total), d: scrub.d,
                                lead: 0.26, step: 0.06, drop: min(58, w * 0.2))
                        .font(.sh(min(50, w * 0.175), .black))
                        .foregroundStyle(Vinyl.ink)
                        .padding(.top, 2)

                    Spacer(minLength: 6)

                    share
                        .padding(.bottom, 10)

                    VStack(spacing: 0) {
                        ForEach(Array(ranked.enumerated()), id: \.element.id) { i, s in
                            row(s, rank: i + 1,
                                lead: Scrub.lead(i, of: ranked.count, d: scrub.d, step: 0.08))
                                .linkSlot(s.profileURL)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    /// สัดส่วนของแต่ละช่องทางในยอดรวม — แถบเดียวไม่มีตัวเลขกำกับ
    ///
    /// มีไว้เพราะตัวเลขรวมกับอันดับสามบรรทัดตอบคนละคำถาม: "ใหญ่แค่ไหน" กับ "ช่องไหนบ้าง"
    /// สิ่งที่หายไปคือ "หนักไปทางไหน" ซึ่งเป็นคำถามแรกที่แบรนด์ถามเวลาเลือกครีเอเตอร์
    /// ใช้เฉดของหมึกไล่กัน ไม่ใช่สีประจำแพลตฟอร์ม — บล็อกนี้เป็นวัสดุเดียว ห้ามมีสีที่สี่
    ///
    /// ท่า: ช่องดับไล่จากฝั่งที่หน้ากำลังไป (`Scrub.cell`) เหมือนตารางเวลารับงาน
    private var share: some View {
        ScrubReader(d: scrub.d) { d in
            GeometryReader { geo in
                HStack(spacing: 3) {
                    ForEach(Array(ranked.enumerated()), id: \.element.id) { i, s in
                        let ratio = total > 0 ? CGFloat(s.followerCount) / CGFloat(total) : 0
                        let a = Scrub.cell(i, of: ranked.count, d: d, spill: 0.8)
                        Capsule()
                            .fill(Vinyl.ink.opacity(0.85 - Double(i) * 0.26))
                            .frame(width: max(6, (geo.size.width - 6) * ratio))
                            .scaleEffect(x: a, anchor: .leading)
                            .opacity(a)
                    }
                    Spacer(minLength: 0)
                }
                .frame(height: geo.size.height, alignment: .center)
            }
        }
        .frame(height: 7)
    }

    private func row(_ s: SocialProfile, rank: Int, lead: Double) -> some View {
        HStack(spacing: 9) {
            Text(String(format: "%02d", rank))
                .font(.sh(11, .black))
                .foregroundStyle(Vinyl.ink.opacity(0.4))
            BrandIcon(name: s.type.icon, size: 14)
            Text(s.type.name)
                .font(.sh(12, .bold))
                .foregroundStyle(Vinyl.ink)
                .lineLimit(1).minimumScaleFactor(0.6)
            Spacer(minLength: 4)
            Text(Fmt.compact(s.followerCount))
                .font(.sh(12.5, .heavy))
                .foregroundStyle(Vinyl.ink)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .overlay(alignment: .top) {
            Rectangle().fill(Vinyl.ink.opacity(0.13)).frame(height: 0.8)
        }
        .scrubVeil(scrub.d, lead: lead, drop: 26, pull: 12)
    }
}

// MARK: - 04 · ตู้ถ่ายรูป

/// สี่เฟรมบนกระดาษแผ่นเดียว — สติปรูดจากตู้ถ่ายรูป
///
/// ต่างจาก `ArtFilmstrip` ตรงที่ตัวนั้นคือ *คอนแทกต์ชีตของช่างภาพ* (เฟรมลอยบนการ์ด เนี้ยบ เท่ากันเป๊ะ)
/// ส่วนตัวนี้คือ *ของที่ถืออยู่ในมือ* — มีขอบกระดาษ มีวันที่ปั๊ม มีสติกเกอร์แปะทับขอบเฟรม
/// เรื่องเดียวกัน คนละความรู้สึก ซึ่งคือทั้งหมดที่ตระกูล "รูปผลงาน" ต้องการจากแบบใหม่
///
/// # ท่าเปลี่ยนหน้า — "แผ่นถูกดึงออกจากช่องจ่าย"
///
/// ทั้งแผ่นไถลออกไปพร้อมเอียงเพิ่ม ขณะที่หน้าต่างของแต่ละเฟรมหุบไล่กันจากฝั่งที่หน้ากำลังไป
struct ArtPhotobooth: View {
    @Environment(PhotoStore.self) private var photos
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    private let slots = [6, 7, 8, 9]

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 5
            let pad: CGFloat = 8
            let n = slots.count
            let fw = (geo.size.width - pad * 2 - gap * CGFloat(n - 1)) / CGFloat(n)

            ScrubReader(d: scrub.d) { d in
                let t = Scrub.ease(Scrub.t(d))
                let s = Double(Scrub.dir(d))
                strip(fw: fw, gap: gap, pad: pad)
                    .rotationEffect(.degrees(-2 + s * 5 * Double(t)))
                    .scaleEffect(1 - 0.05 * t)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func strip(fw: CGFloat, gap: CGFloat, pad: CGFloat) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: gap) {
                ForEach(Array(slots.enumerated()), id: \.element) { i, slot in
                    frame(slot, w: fw, i: i)
                }
            }
            .frame(maxHeight: .infinity)

            // แถบขาวใต้รูป — เดิมพิมพ์ว่า "STARCARD BOOTH" กับชื่อผู้ใช้ไว้ตรงนี้
            // ถอดออกตามกติกาของตระกูล `รูปผลงาน` ที่ว่าห้ามมีตัวอักษร (ดู `GalleryWidgets.swift`)
            // เหลือดาวดวงเล็กไว้ดวงเดียว — แถบล่างของสตริปจริงไม่เคยว่างเปล่า มันมีมาร์กของตู้เสมอ
            HStack(spacing: 6) {
                SymbolIcon(name: SHIcon.star, size: 9, tint: Vinyl.ink.opacity(0.45))
                Spacer(minLength: 4)
            }
            .frame(height: 10)
            .scrubVeil(scrub.d, lead: 0.32, drop: 14, pull: 8)
        }
        .padding(pad)
        .background(Vinyl.photoPaper)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 12, y: 7)
        .overlay(alignment: .topTrailing) { heartSticker }
    }

    private func frame(_ slot: Int, w: CGFloat, i: Int) -> some View {
        Color.clear
            .frame(width: w)
            .overlay {
                WidgetPhoto(index: slot)
                    .aspectRatio(contentMode: .fill)
                    .scrubDolly(scrub.d, shift: w * 0.07, zoom: 0.16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .photoSlot(slot)
            .scrubAperture(scrub.d,
                           lead: Scrub.lead(i, of: slots.count, d: scrub.d, step: 0.1),
                           feather: 0.24, dim: 0.5)
    }

    /// สติกเกอร์แปะทับขอบกระดาษ — วางคร่อมขอบ ไม่ใช่วางข้างใน
    /// ของที่ล้นออกนอกกรอบคือสิ่งที่ทำให้แผ่นอ่านเป็นของจริง ไม่ใช่ภาพประกอบที่ถูกจัดวาง
    private var heartSticker: some View {
        ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d, lead: 0.16))
            SymbolIcon(name: SHIcon.heart, size: 12, tint: .white)
                .padding(6)
                .background(Circle().fill(theme.rawAccent))
                .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1.5))
                .rotationEffect(.degrees(12 + Double(Scrub.dir(d)) * 40 * Double(t)))
                .scaleEffect(1 - 0.5 * t)
                .opacity(Scrub.fade(t, after: 0.55))
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        }
        .frame(width: 24, height: 24)
        .offset(x: 9, y: -9)
    }
}

// MARK: - 05 · สติกเกอร์สายงาน

/// สายงานเดิม แต่เป็นสติกเกอร์ไวนิลนูน — ขอบขาวหนา เงาจริง เอียงคนละองศา
///
/// ชิปแคปซูลเรียงเป็นแถวอ่านออกมาเป็น *แท็กในระบบ* ส่วนสติกเกอร์ที่เอียงไม่เท่ากันอ่านออกมาเป็น
/// *ของที่เจ้าตัวเลือกเอง* ซึ่งเป็นความหมายที่ถูกต้องของ widget ตัวนี้ (ครีเอเตอร์พิมพ์เอง ไม่ใช่ระบบจับให้)
///
/// # ท่าเปลี่ยนหน้า — "ลอกทีละใบ"
///
/// สติกเกอร์หมุนขึ้นแล้วหดหายไล่กัน ไม่ใช่จางพร้อมกัน — ของที่ *ถูกลอก* ต้องหมุนออกจากผิวเสมอ
struct StickerTags: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    let theme: CardTheme

    /// องศาเอียงตั้งต้น — คงที่ ไม่สุ่ม การ์ดใบเดิมต้องหน้าตาเหมือนเดิมทุกครั้งที่เปิด
    private let tilt: [Double] = [-4, 2.5, -1.5, 3.5, -2.5]

    var body: some View {
        let items = Profile.me.categories
        return VStack(alignment: .leading, spacing: 12) {
            WidgetLabel(text: "สายงาน")
                .scrubVeil(scrub.d, lead: 0.34, drop: 20, pull: 6)

            FlowLayout(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.element) { i, name in
                    sticker(name, i: i, total: items.count)
                }
            }
            .id(items)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func sticker(_ name: String, i: Int, total: Int) -> some View {
        // สามสีวนกัน — สีเดียวทั้งชุดอ่านเป็นแท็ก ไม่ใช่สติกเกอร์ที่สะสมมาคนละที่
        let fill: AnyShapeStyle = {
            switch i % 3 {
            case 0: return AnyShapeStyle(LinearGradient(
                colors: [theme.rawAccent, theme.rawAccentSoft],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            case 1: return AnyShapeStyle(Color.white)
            default: return AnyShapeStyle(Vinyl.marker)
            }
        }()

        return ScrubReader(d: scrub.d) { d in
            let t = Scrub.ease(Scrub.t(d, lead: Scrub.lead(i, of: total, d: d, step: 0.08)))
            let s = Double(Scrub.dir(d))
            HStack(spacing: 5) {
                if i % 2 == 0 {
                    SymbolIcon(name: SHIcon.starFill, size: 9, tint: Vinyl.ink.opacity(0.7))
                }
                Text(name)
                    .font(.sh(13, .heavy))
                    .foregroundStyle(Vinyl.ink)
                    .lineLimit(1).truncationMode(.tail)
                    // ลบข้อความจนหมดแล้วปิดช่อง = ลอกสติกเกอร์ใบนั้นทิ้ง (ดู `Profile.commit`)
                    .editableText(.categories, index: i,
                                  .init(size: 13, weight: .heavy, color: Vinyl.ink, corner: 10))
            }
            .padding(.horizontal, 13).padding(.vertical, 8)
            .background(Capsule().fill(fill))
            // ขอบขาวหนาคือสิ่งเดียวที่แยก "สติกเกอร์ที่ตัดมาแปะ" ออกจาก "ชิปในฟอร์ม"
            .overlay(Capsule().strokeBorder(.white, lineWidth: 2.5))
            .shadow(color: .black.opacity(0.32), radius: 5, y: 3)
            .rotationEffect(.degrees(tilt[i % tilt.count] + s * 26 * Double(t)))
            .scaleEffect(1 - 0.45 * t)
            .offset(y: -18 * t)
            .opacity(Scrub.fade(t, after: 0.6))
        }
    }
}
