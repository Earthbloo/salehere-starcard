import SwiftUI

// ผลงานที่ยืนยันแล้ว — สี่หน้าตาของเรื่องเดียวกัน
//
// ทุกตัวในไฟล์นี้ใช้ข้อมูลชุดเดียวกันเป๊ะ (`Mock.creator.track.works`) และต้องบอกครบสี่สัญญาณ
// **โพสอะไร · ตอนไหน · แบรนด์ไหน · ได้ผลแค่ไหน** — ที่ต่างกันคือ *น้ำหนัก* ที่ให้แต่ละสัญญาณ
//
// **กฎข้อแรกของชั้นนี้: รูปคือตัวนำ** ผลงานของ creator คือภาพที่เขาถ่าย ไม่ใช่แถวตัวเลขของมัน
// ช่องรูปต้องกินพื้นที่เกินครึ่งของ widget เสมอ ตัวหนังสือได้ที่เหลือ ไม่ใช่กลับกัน
// เคยมีอีกสี่แบบในไฟล์นี้ (เพลย์ลิสต์ · ใบเสร็จ · กระดานคะแนน · ป้ายโลหะ) ที่วัดแล้วรูปกินพื้นที่
// 0–5% — อ่านออกมาเป็นเครื่องมือดูข้อมูล ไม่ใช่ผลงาน จึงถอดออกทั้งหมด ไม่ใช่แค่ปรับ
//
// บทเรียนอีกข้อจากการวัด: สิ่งที่ทำให้ widget อ่านออกมาเป็น "ตาราง" ไม่ใช่ปริมาณข้อมูล
// แต่คือ **จำนวนสไตล์ตัวอักษรที่ใช้พร้อมกัน** — แบบที่เป็นงานภาพใช้ 7 สไตล์ แบบที่เป็นตารางใช้ 12
// เวลาจะเพิ่มอะไรลงในนี้ ให้ถามก่อนว่า "เพิ่มเสียงใหม่ หรือพูดด้วยเสียงที่มีอยู่แล้วได้"
//
// กติกาท่าประจำชั้นนี้ (เหมือน `ProofWidgets.swift`): **หัวเรื่องกับตัวเลขคือสมอ**
// ไปทีหลังสุด กลับมาก่อนใคร

// MARK: - ชิ้นส่วนที่ใช้ร่วมกันทุกแบบ

/// หาแบรนด์จากชื่อในผลงาน — ชื่อต้องตรงกับรายการ `brands` ถึงจะได้โลโก้มาแสดง
private func brandOf(_ work: VerifiedWork) -> Brand? {
    Mock.creator.track.brands.first { $0.name == work.brand }
}

private var works: [VerifiedWork] { Mock.creator.track.works }

/// "โพสอะไร" — ไอคอนแพลตฟอร์มสีจริงคู่ชื่อฟอร์แมต
///
/// ไอคอนอย่างเดียวบอกได้แค่ช่องทาง ฟอร์แมตอย่างเดียวบอกได้แค่ความยาว
/// แบรนด์ต้องรู้ทั้งคู่ถึงจะเทียบราคาได้ จึงมัดไว้เป็นชิ้นเดียวไม่ให้ใครแยกใช้
private struct PostTag: View {
    let work: VerifiedWork
    var size: CGFloat = 9
    var tint: Color? = nil
    /// ซ่อนชื่อฟอร์แมตเมื่อช่องแคบเกินกว่าจะอ่านออก — เหลือไอคอนดีกว่าเหลือคำที่ถูกตัดครึ่ง
    var iconOnly: Bool = false

    @Environment(\.cardInk) private var ink

    var body: some View {
        HStack(spacing: 4) {
            BrandIcon(name: work.platform.icon, size: size * 1.15)
            if !iconOnly {
                Text(work.format)
                    .font(.sh(size, .semibold))
                    .foregroundStyle(tint ?? ink.text(0.6))
                    .lineLimit(1)
            }
        }
        .fixedSize()
    }
}

/// ช่องรูปผลงานหนึ่งช่อง — ผูก `photoSlot` ให้เรียบร้อยเพื่อให้กดเปลี่ยนรูปได้ทุกแบบ
private struct WorkPhoto: View {
    let work: VerifiedWork
    var radius: CGFloat = 10
    /// ระยะถ่วงสวนทางหน้า — 0 คือไม่ถ่วง
    var dolly: CGFloat = 0

    @Environment(\.pageScrub) private var scrub

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Color.clear
            .overlay {
                WidgetPhoto(work.photo)
                    .aspectRatio(contentMode: .fill)
                    // zoom ต้องคุ้ม shift (0.16 ≥ 2 × 0.07) ไม่งั้นเห็นขอบว่างตอนถ่วง
                    .scrubDolly(scrub.d, shift: dolly, zoom: dolly > 0 ? 0.16 : 0)
            }
            .clipShape(shape)
            .photoSlot(work.photo)
    }
}

private extension WidgetPhoto {
    init(_ index: Int) { self.init(index: index) }
}

/// หัวเรื่องมาตรฐานของชั้นหลักฐาน — ทุกแบบใช้ตัวเดียวกันเพื่อให้แบรนด์รู้ทันทีว่ากำลังดูอะไร
private struct ProofHeader: View {
    var badge: Bool = true
    @Environment(\.pageScrub) private var scrub

    var body: some View {
        WidgetLabel(text: "ผลงานที่ยืนยันแล้ว",
                    trailing: badge ? AnyView(VerifiedBadge()) : nil)
            .scrubVeil(scrub.d, lead: 0.34, drop: 22, pull: 6)
    }
}

/// สีกระดาษที่ใช้ซ้ำในแบบที่มีพื้นผิวเป็นของตัวเอง (ตั๋ว · ใบเสร็จ · ตัดแปะ)
///
/// ไม่ผูกกับ `cardInk` โดยตั้งใจ — กระดาษพวกนี้ *คือ* พื้นผิวของตัวเอง
/// ถ้าปล่อยให้พลิกตามพื้นการ์ด อุปมา "ของที่จับต้องได้" จะหายไปทันทีบนการ์ดพื้นสว่าง
private enum Paper {
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let creamDeep = Color(red: 0.95, green: 0.91, blue: 0.86)
    static let slip = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let ink = Color(red: 0.09, green: 0.06, blue: 0.13)
    static let inkSoft = Color(red: 0.35, green: 0.31, blue: 0.42)
    static let stampGreen = Color(red: 0.05, green: 0.56, blue: 0.45)
    static let hot = Color(red: 0.77, green: 0.10, blue: 0.31)
    static let marker = Color(red: 1.00, green: 0.89, blue: 0.30)
}

/// ตัวเลขหลักฐานท้ายชิ้น — **ยอดวิวอย่างเดียว**
///
/// เคยมี ER ต่อท้ายด้วย แต่ตัวเลขสองตัวที่คนละหน่วยวางชิดกันแล้วไม่มีตัวไหนเป็นพระเอก
/// ตาต้องอ่านสองรอบถึงจะรู้ว่าอันไหนคือ "ผลงานนี้ดังแค่ไหน" — เหลือค่าเดียวแล้วอ่านรอบเดียวจบ
/// ER ยังอยู่ในโมเดล (`work.engagementRate`) ถ้าจะเอากลับมาก็หยิบได้ทันที
///
/// ถอดทีละหลักตามนิ้ว ไม่ใช่จางหาย เพราะมันคือค่าที่นับได้ ไม่ใช่คำโปรย
private struct ProofFigures: View {
    let work: VerifiedWork
    var size: CGFloat = 13
    var tint: Color
    var subTint: Color
    var lead: Double = 0.3

    @Environment(\.pageScrub) private var scrub

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                ScrubDigits(text: Fmt.compact(work.views), d: scrub.d,
                            lead: lead, step: 0.05, drop: 20)
                    // ตัวเดียวในบรรทัดนี้ จึงใหญ่ขึ้นได้โดยไม่ไปแย่งความสนใจกับใคร
                    .font(.sh(size * 1.15, .heavy))
                    .foregroundStyle(tint)
                Text("วิว")
                    .font(.sh(size * 0.62))
                    .foregroundStyle(subTint)
                    .scrubVeil(scrub.d, lead: lead - 0.04, drop: 18, pull: 6)
                Spacer(minLength: 2)
            }
            .lineLimit(1)

            // บันทึก/แชร์ เป็นไอคอน ไม่ใช่คำ — และมีครบทุกแบบในชั้นหลักฐาน
            // ยอดวิวบอกว่าคนเห็นเยอะแค่ไหน สองตัวนี้บอกว่าเห็นแล้วทำอะไรต่อ
            WorkDeepStats(work: work, size: size * 0.68, tint: subTint,
                          lead: max(0, lead - 0.08))
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - 01 · ตั๋วผลงาน

/// ผลงานคือตั๋วที่ **ฉีกแล้ว** — เข้างานจริง ไม่ใช่แค่จอง
/// รอยปรุกับรหัสตอนทำหน้าที่เป็นซีเรียล ซึ่งเป็นสิ่งที่ media kit ทำใน Canva ปลอมขึ้นมาไม่ได้
///
/// # ท่าเปลี่ยนหน้า — "ฉีกตามรอยปรุ"
/// ครึ่งบน (รูป) กับครึ่งล่าง (ข้อมูล) ไถลสวนทางกันออกจากกันที่รอยปรุ
/// ไม่ใช่ทั้งใบเลื่อนไปพร้อมกัน — เพราะจุดที่ตาเกาะคือรอยฉีก ไม่ใช่ขอบตั๋ว
struct ProofTicket: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProofHeader()

            GeometryReader { geo in
                let gap: CGFloat = 7
                let w = (geo.size.width - gap * CGFloat(works.count - 1)) / CGFloat(works.count)
                // รูปคือตัวนำ — กิน 60% ของใบ ไม่ใช่ 36% เหมือนเดิม
                // ส่วนท้ายตั๋วเหลือแค่สามบรรทัด (แบรนด์ · ชื่อ · ตัวเลข) จึงพอดีกับ 40% ที่เหลือ
                let photoH = max(w * 0.9, geo.size.height * 0.58)

                HStack(alignment: .top, spacing: gap) {
                    ForEach(Array(works.enumerated()), id: \.element.id) { i, work in
                        stub(work, w: w, h: geo.size.height, photoH: photoH,
                             lead: Scrub.lead(i, of: works.count, d: scrub.d, step: 0.1))
                            .linkSlot(work.postURL)
                    }
                }
            }
        }
    }

    private func stub(_ work: VerifiedWork, w: CGFloat, h: CGFloat, photoH: CGFloat, lead: Double) -> some View {
        VStack(spacing: 0) {
            // ครึ่งบน — รูปกับรหัสตอน
            ZStack(alignment: .bottomLeading) {
                WorkPhoto(work: work, radius: 0, dolly: w * 0.06)
                    .frame(height: photoH)
                // "โพสอะไร" ไปอยู่บนรูป ไม่ใช่บรรทัดใต้ชื่อ — รูปกับแพลตฟอร์มเป็นเรื่องเดียวกัน
                // และตั๋วได้บรรทัดคืนมาหนึ่งบรรทัดเพื่อเอาไปให้ช่องรูป
                PostTag(work: work, size: 10, iconOnly: true)
                    .padding(4)
                    .background(Circle().fill(.black.opacity(0.5)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(5)
                Text(work.ep)
                    .font(.sh(8.5, .heavy))
                    .foregroundStyle(Paper.cream)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Paper.ink, in: UnevenRoundedRectangle(topLeadingRadius: 0,
                                                                      bottomLeadingRadius: 0,
                                                                      bottomTrailingRadius: 0,
                                                                      topTrailingRadius: 7))
            }
            .frame(height: photoH)
            .scrubSlide(scrub.d, travel: -14, lead: lead, fade: 0.85)

            perforation(w: w)

            // ครึ่งล่าง — สี่สัญญาณเรียงจากใครไปเท่าไหร่
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    if let b = brandOf(work) { BrandPlate(brand: b, side: 15) }
                    Text(work.brand)
                        .font(.sh(9, .semibold))
                        .foregroundStyle(Paper.inkSoft)
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Spacer(minLength: 0)
                }

                Text(work.campaign)
                    .font(.sh(12.5, .bold))
                    .foregroundStyle(Paper.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 2)

                ProofFigures(work: work, size: 11.5,
                             tint: Paper.ink, subTint: Paper.inkSoft)
                    .padding(.top, 5)
                    .overlay(alignment: .top) {
                        Rectangle().fill(Paper.ink.opacity(0.14)).frame(height: 0.6)
                    }
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 9)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(LinearGradient(colors: [Paper.cream, Paper.creamDeep],
                                       startPoint: .top, endPoint: .bottom))
            .scrubSlide(scrub.d, travel: 16, lead: lead + 0.05, fade: 0.85)
        }
        // ล็อกความสูงเท่ากับที่ widget ได้จริง ไม่ใช่ปล่อยให้ยืดตามเนื้อหา
        // ชื่อแคมเปญยาวไม่เท่ากันจะทำให้ตั๋วสูงไม่เท่าและใบที่ยาวกว่าจะทะลุไปทับ widget ถัดไป
        .frame(width: w, height: h, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    /// รอยปรุ — เจาะรูจริงด้วย destinationOut ไม่ใช่วาดวงกลมสีพื้นทับ
    /// เพราะพื้นหลังการ์ดเป็นเกรเดียนต์ วงกลมสีเดียวจะเห็นเป็นจุดด่างทันที
    private func perforation(w: CGFloat) -> some View {
        let d: CGFloat = 5
        return Rectangle()
            .fill(Paper.creamDeep)
            .frame(height: 9)
            .overlay {
                Rectangle().fill(Paper.ink.opacity(0.28))
                    .frame(height: 0.6)
                    .padding(.horizontal, d)
            }
            .overlay(alignment: .leading) {
                Circle().frame(width: d, height: d).blendMode(.destinationOut).offset(x: -d / 2)
            }
            .overlay(alignment: .trailing) {
                Circle().frame(width: d, height: d).blendMode(.destinationOut).offset(x: d / 2)
            }
            .compositingGroup()
    }
}

// MARK: - 02 · การ์ดสะสม

/// ผลงานกลายเป็นของสะสม — แบรนด์ที่ได้ร่วมงานคือ "ตัวหายาก"
///
/// # ท่าเปลี่ยนหน้า — "พลิกฟอยล์"
/// การ์ดพลิกในช่องของตัวเองไล่กันตามทิศนิ้ว และ **มุมของฟอยล์หมุนตามระยะหน้า**
/// นี่คือจุดเดียวในสำรับที่ผิววัสดุเปลี่ยนตามนิ้ว ไม่ใช่แค่ตำแหน่ง
struct ProofHolo: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    private var foilAngle: Angle { .degrees(140 + Double(scrub.d) * 90) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProofHeader()

            GeometryReader { geo in
                let gap: CGFloat = 8
                let w = (geo.size.width - gap * CGFloat(works.count - 1)) / CGFloat(works.count)

                HStack(alignment: .top, spacing: gap) {
                    ForEach(Array(works.enumerated()), id: \.element.id) { i, work in
                        card(work, w: w, h: geo.size.height)
                            .scrubLouver(scrub.d,
                                         lead: Scrub.lead(i, of: works.count, d: scrub.d, step: 0.11),
                                         angle: 58, shrink: 0.1)
                            .linkSlot(work.postURL)
                    }
                }
            }
        }
    }

    private func card(_ work: VerifiedWork, w: CGFloat, h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                if let b = brandOf(work) { BrandPlate(brand: b, side: 16) }
                Text(work.brand)
                    .font(.sh(8.5, .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1).minimumScaleFactor(0.6)
                Spacer(minLength: 2)
                // เลขการ์ด — รหัสตอนเดิม แค่พูดด้วยสำเนียงของของสะสม
                Text(work.ep.replacingOccurrences(of: "EP.", with: "#"))
                    .font(.sh(8, .heavy))
                    .foregroundStyle(theme.accent)
                    .fixedSize()
            }

            // ภาพกินที่ที่เหลือทั้งหมดของการ์ด — เดิมล็อกสัดส่วนไว้แล้วเหลือที่ว่างใต้ตัวเลข
            // ตอนนี้ตัวหนังสือได้เท่าที่มันต้องการ ที่เหลือเป็นของภาพ
            ZStack(alignment: .topLeading) {
                WorkPhoto(work: work, radius: 7, dolly: w * 0.05)
                PostTag(work: work, size: 8, tint: .white.opacity(0.92))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Capsule().fill(.black.opacity(0.45)))
                    .padding(5)
            }
            .frame(maxHeight: .infinity)

            Text(work.campaign)
                .font(.sh(11.5, .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            // เดิมเป็นตัวเลข + หลอด meter + บรรทัด ER = สามเสียงซ้อนกันในก้อนเดียว
            // และกินความสูงที่ควรเป็นของภาพ ยุบเหลือบรรทัดเดียวเหมือนแบบอื่นในชั้นนี้
            ProofFigures(work: work, size: 12,
                         tint: .white, subTint: .white.opacity(0.42))
        }
        .padding(7)
        .frame(width: w, height: h, alignment: .topLeading)
        .background(LinearGradient(colors: [Color(red: 0.11, green: 0.08, blue: 0.22),
                                            Color(red: 0.07, green: 0.05, blue: 0.14)],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(2)
        .background(
            AngularGradient(colors: [theme.accent, .white.opacity(0.85), theme.accentSoft,
                                     theme.accent.opacity(0.7), theme.accent],
                            center: .center, angle: foilAngle),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
}

// MARK: - 03 · ปกซีรีส์

/// รหัสตอนอ่านเหมือนซีรีส์อยู่แล้ว — จึงดันขึ้นเป็นริบบิ้นมุมปก
/// ชื่อแคมเปญพาดทับรูปแบบโปสเตอร์ ไม่ใช่แคปชันใต้รูป
///
/// แบบที่ให้ภาพกินพื้นที่มากที่สุดในตระกูล (~54%) และใช้สไตล์ตัวอักษรน้อยที่สุดรองจากตัดแปะ
///
/// # ท่าเปลี่ยนหน้า — "ชั้นวางเลื่อนสวนกัน"
/// ปกใบคี่เลื่อนขึ้น ใบคู่เลื่อนลง เหมือนชั้นวางสองชั้นที่เคลื่อนคนละทาง
struct ProofShelf: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProofHeader()

            GeometryReader { geo in
                let gap: CGFloat = 8
                let w = (geo.size.width - gap * CGFloat(works.count - 1)) / CGFloat(works.count)

                HStack(alignment: .top, spacing: gap) {
                    ForEach(Array(works.enumerated()), id: \.element.id) { i, work in
                        poster(work, w: w, h: geo.size.height)
                            .scrubSlide(scrub.d,
                                        travel: i % 2 == 0 ? -26 : 26,
                                        lead: Scrub.lead(i, of: works.count, d: scrub.d, step: 0.08))
                            .linkSlot(work.postURL)
                    }
                }
            }
        }
    }

    private func poster(_ work: VerifiedWork, w: CGFloat, h: CGFloat) -> some View {
        // ไม่มีแถวตัวเลขใต้ปกอีกแล้ว — ทุกอย่างไปอยู่บนปก ปกจึงได้ความสูงทั้งหมดของ widget
        // นี่คือแบบที่รูปกินพื้นที่มากที่สุดในชั้นนี้ และเป็นเหตุผลเดียวที่มันมีอยู่
        ZStack(alignment: .bottomLeading) {
                WorkPhoto(work: work, radius: 13, dolly: w * 0.07)

                // รูปผลงานสว่างกว่าที่คิดเสมอ (รีวิวอาหาร/สกินแคร์ถ่ายไฟจัด)
                // ม่านจึงต้องเริ่มตั้งแต่กลางรูปและลงไปเกือบทึบ ไม่งั้นชื่อแคมเปญขาวหายไปกับพื้น
                LinearGradient(stops: [.init(color: .clear, location: 0.28),
                                       .init(color: .black.opacity(0.45), location: 0.58),
                                       .init(color: .black.opacity(0.94), location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 5) {
                    Text(work.campaign.uppercased())
                        .font(.sh(14, .black))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .fixedSize(horizontal: false, vertical: true)
                        .scrubVeil(scrub.d, lead: 0.12, drop: 30, pull: 10)

                    HStack(spacing: 5) {
                        if let b = brandOf(work) { BrandPlate(brand: b, side: 14) }
                        Text(work.brand)
                            .font(.sh(8.5))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1).minimumScaleFactor(0.6)
                    }
                    .scrubVeil(scrub.d, lead: 0.06, drop: 26, pull: 10)

                    ProofFigures(work: work, size: 12.5,
                                 tint: .white, subTint: .white.opacity(0.5))
                }
                .padding(9)

                // ริบบิ้นมุมปก — รหัสตอนต้องอ่านได้ก่อนอย่างอื่นทั้งหมด
                Text(work.ep)
                    .font(.sh(8.5, .heavy))
                    .foregroundStyle(.white)
                    .padding(.leading, 6).padding(.trailing, 8).padding(.vertical, 3)
                    .background(theme.accent, in: UnevenRoundedRectangle(topLeadingRadius: 0,
                                                                         bottomLeadingRadius: 0,
                                                                         bottomTrailingRadius: 4,
                                                                         topTrailingRadius: 4))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 9)

                PostTag(work: work, size: 10, iconOnly: true)
                    .padding(5)
                    .background(Circle().fill(.black.opacity(0.5)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(7)
        }
        .frame(width: w, height: h)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

// MARK: - 04 · ตัดแปะ

/// แบบเดียวในตระกูลที่ยอมทิ้งความเป๊ะ เพื่อให้การ์ดดูเหมือนคนทำ ไม่ใช่ระบบ gen
/// ใช้สไตล์ตัวอักษรน้อยที่สุดในชุด — ข้อมูลครบเท่าเดิม แต่พูดด้วยเสียงเดียว
///
/// # ท่าเปลี่ยนหน้า — "แผ่นปลิว"
/// แต่ละแผ่นหมุนเพิ่มขึ้นตามระยะหน้าแล้วปลิวออกไล่กัน — องศาเอียงตั้งต้นต่างกันอยู่แล้ว
/// จึงไม่ต้องเพิ่มจังหวะอะไรอีกให้รก
struct ProofZine: View {
    @Environment(\.pageScrub) private var scrub
    let theme: CardTheme

    /// องศาเอียงตั้งต้นของแต่ละแผ่น — คงที่ ไม่สุ่ม เพื่อให้การ์ดใบเดิมหน้าตาเหมือนเดิมเสมอ
    private let tilt: [Double] = [-2.4, 1.3, -1.0]
    private let drop: [CGFloat] = [0, 5, -2]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProofHeader(badge: false)

            GeometryReader { geo in
                let gap: CGFloat = 6
                let w = (geo.size.width - 16 - gap * CGFloat(works.count - 1)) / CGFloat(works.count)

                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .top, spacing: gap) {
                        ForEach(Array(works.enumerated()), id: \.element.id) { i, work in
                            // สูงเท่ากันทุกแผ่นและเท่าที่กระดานมี — ไม่งั้นแผ่นที่ชื่อแบรนด์
                            // ตกบรรทัดจะยาวทะลุขอบกระดานออกไปลอยบนพื้นการ์ด
                            snip(work, w: w, h: geo.size.height - 30)
                                .rotationEffect(.degrees(tilt[i % tilt.count] + Double(scrub.d) * 7))
                                .offset(y: drop[i % drop.count])
                                .scrubSlide(scrub.d, travel: 34,
                                            lead: Scrub.lead(i, of: works.count, d: scrub.d, step: 0.12))
                                .linkSlot(work.postURL)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 8)
                    .padding(.top, 14)

                    // สติกเกอร์ยืนยัน — วางทับขอบแผ่น ไม่ใช่วางเรียงข้าง ๆ
                    // ต้องบอกชื่อผู้ออกเหมือน `VerifiedBadge` ไม่งั้นมันคือคำที่ใครก็พิมพ์เองได้
                    // ใช้ตราวงกลมตัวเดียวกัน ทั้งการ์ดจึงมีลายเซ็นผู้ออกแบบเดียว
                    HStack(spacing: 4) {
                        Text("Verified by").font(.sh(8, .bold)).foregroundStyle(.white)
                        SaleHereMark(size: 13)
                            .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1))
                    }
                    .fixedSize()
                    .padding(.horizontal, 8).padding(.vertical, 3.5)
                    .background(Capsule().fill(theme.accent))
                    .rotationEffect(.degrees(6))
                    .padding(.trailing, 6)
                    .scrubVeil(scrub.d, lead: 0.3, drop: 20, pull: 8)
                }
                .background {
                    // กระดานปะ — จุดฮาล์ฟโทนบนพื้นเข้ม ให้แผ่นกระดาษลอยขึ้นมา
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [Color(red: 0.14, green: 0.10, blue: 0.27),
                                                      Color(red: 0.08, green: 0.05, blue: 0.17)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay {
                            DotScreen(spacing: 7, radius: 1, color: .white.opacity(0.16))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                }
            }
        }
    }

    private func snip(_ work: VerifiedWork, w: CGFloat, h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            ZStack(alignment: .bottomTrailing) {
                WorkPhoto(work: work, radius: 2)
                    // สูงกว่ากว้าง — รูปที่ตัดมาแปะควรเป็นทรงตั้ง ไม่ใช่แถบนอน
                    // และเป็นวิธีคืนพื้นที่ให้ภาพโดยไม่ต้องตัดข้อมูลอะไรออก
                    .aspectRatio(0.92, contentMode: .fit)
                    .frame(maxHeight: .infinity)
                    .saturation(1.15)
                    .contrast(1.12)
                    // เบาลงกว่าเดิมมาก — ตอนแรกใช้ 0.42 + multiply แล้วรูปกลายเป็นตาข่าย
                    // อ่านไม่ออกว่าเป็นรูปอะไร ฮาล์ฟโทนควรเป็นผิว ไม่ใช่ลวดลายทับรูป
                    // ไม่มีฮาล์ฟโทนทับรูปแล้ว — ลองมาสามระดับ (0.42 → 0.2 → 0.12) ทุกระดับยังอ่าน
                    // เป็นตาข่ายบนรูปอยู่ดี และรูปคือสิ่งสำคัญที่สุดของ widget ชั้นนี้
                    // ความเป็นซีนมาจากเทปกาว องศาเอียง และปากกาไฮไลต์ ซึ่งไม่ได้บังรูปเลย
                    // จุดฮาล์ฟโทนเหลือไว้บนกระดานที่อยู่ข้างหลังอย่างเดียว
                Text(work.ep)
                    .font(.sh(7.5, .heavy))
                    .foregroundStyle(Paper.cream)
                    .padding(.horizontal, 4).padding(.vertical, 2)
                    .background(Paper.ink)
                    .rotationEffect(.degrees(-1.5))
                    .padding(3)
            }

            // ปากกาไฮไลต์บนคำแรก — เลียนแบบคนอ่านที่ขีดคำที่อยากให้เห็นก่อน
            Text(work.campaign.split(separator: " ").first.map(String.init) ?? work.campaign)
                .font(.sh(11.5, .black))
                .foregroundStyle(Paper.ink)
                .padding(.horizontal, 2)
                .background(Paper.marker)
                .lineLimit(1).minimumScaleFactor(0.7)

            // แบรนด์กับแพลตฟอร์มอยู่บรรทัดเดียวกัน — เดิมแยกสองบรรทัดแล้วกินความสูงของรูปไปเปล่า ๆ
            HStack(spacing: 4) {
                if let b = brandOf(work) { BrandPlate(brand: b, side: 13) }
                Text(work.brand)
                    .font(.sh(8, .semibold))
                    .foregroundStyle(Paper.inkSoft)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Spacer(minLength: 3)
                PostTag(work: work, size: 8, tint: Paper.inkSoft, iconOnly: true)
            }

            Spacer(minLength: 2)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                ScrubDigits(text: Fmt.compact(work.views), d: scrub.d, lead: 0.26, step: 0.05, drop: 16)
                    .font(.sh(13, .heavy))
                    .foregroundStyle(Paper.ink)
                Text("วิว")
                    .font(.sh(8))
                    .foregroundStyle(Paper.inkSoft)
                Spacer(minLength: 0)
            }
            .padding(.top, 2)
            .overlay(alignment: .top) {
                Rectangle().fill(Paper.ink).frame(height: 1.4)
            }

            WorkDeepStats(work: work, size: 8, tint: Paper.inkSoft, lead: 0.18)
        }
        .padding(.horizontal, 5)
        .padding(.top, 5)
        .padding(.bottom, 7)
        .frame(width: w, height: h, alignment: .topLeading)
        .background(Paper.cream)
        .overlay(alignment: .top) {
            // เทปกาว — โปร่งแสงพอให้เห็นกระดาษข้างใต้ ไม่งั้นอ่านเป็นแถบสีทึบ
            Rectangle()
                .fill(Paper.marker.opacity(0.55))
                .frame(width: 34, height: 13)
                .rotationEffect(.degrees(-3))
                .offset(y: -7)
        }
        .shadow(color: .black.opacity(0.45), radius: 6, y: 4)
    }
}

/// จุดฮาล์ฟโทน — วาดด้วย Canvas ไม่ใช่ภาพ pattern เพราะต้องคมทุกความหนาแน่นหน้าจอ
private struct DotScreen: View {
    var spacing: CGFloat
    var radius: CGFloat
    var color: Color

    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = radius
            while y < size.height {
                var x: CGFloat = radius
                while x < size.width {
                    ctx.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius,
                                                    width: radius * 2, height: radius * 2)),
                             with: .color(color))
                    x += spacing
                }
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}
