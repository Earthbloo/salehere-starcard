import SwiftUI

// ผลงานที่ยืนยันแล้ว — ตั๋วผลงาน
//
// ใช้ข้อมูลชุดเดียวกันเป๊ะกับ `ProofWork` (`Profile.me.creator.track.works`) และต้องบอกครบสี่สัญญาณ
// **โพสอะไร · ตอนไหน · แบรนด์ไหน · ได้ผลแค่ไหน** — ที่ต่างกันคือ *น้ำหนัก* ที่ให้แต่ละสัญญาณ
//
// **กฎข้อแรกของชั้นนี้: รูปคือตัวนำ** ผลงานของ creator คือภาพที่เขาถ่าย ไม่ใช่แถวตัวเลขของมัน
// ช่องรูปต้องกินพื้นที่เกินครึ่งของ widget เสมอ ตัวหนังสือได้ที่เหลือ ไม่ใช่กลับกัน
// เคยมีอีกสี่แบบในไฟล์นี้ (เพลย์ลิสต์ · ใบเสร็จ · กระดานคะแนน · ป้ายโลหะ) ที่วัดแล้วรูปกินพื้นที่
// 0–5% — อ่านออกมาเป็นเครื่องมือดูข้อมูล ไม่ใช่ผลงาน จึงถอดออกทั้งหมด ไม่ใช่แค่ปรับ
// (การ์ดสะสมกับปกซีรีส์ถูกถอดออกทีหลัง — เหลือตั๋วผลงานกับตัดแปะ)
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
    Profile.me.shownTrack(.verified).brands.first { $0.name == work.brand }
}

private var works: [VerifiedWork] { Profile.me.shownTrack(.verified).works }

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
                WorkPicture(work: work)
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

/// สีกระดาษของแบบที่มีพื้นผิวเป็นของตัวเอง (ตั๋ว)
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
                ScrubDigits(text: work.views > 0 ? Fmt.compact(work.views) : "–", d: scrub.d,
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
                EPChip(ep: work.ep, tone: .ink, size: 8)
                    .padding(5)
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

