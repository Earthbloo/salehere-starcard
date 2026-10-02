import SwiftUI

// MARK: - ชิ้นส่วนร่วมของโปสเตอร์คัตเอาต์
//
// ใช้ร่วมกันโดยทุกใบที่ให้คน **ยืนอยู่บนการ์ด** แทนการถูกขังในกรอบรูป — โปสเตอร์พอร์ต ·
// โปสเตอร์สายงาน · โปสเตอร์ติดต่อ · โปสเตอร์อินไซต์ · หน้าต่างพอร์ต · พอร์ตผ้าปิกนิก
//
// รูปที่มีช่องอัลฟา (ลบพื้นหลังแล้ว) คนยืนบนการ์ด ตัวอักษรไปอยู่หลังไหล่ได้จริง ·
// รูปทึบตกไปโหมดกรอบเงียบ ๆ ไม่มีอะไรพัง
//
// (สองใบแรกของตระกูล — ชื่ออยู่หลังคน · ทะลุกรอบ — ถูกถอดออก 29 ก.ย. 2569 · ดู `WidgetKind.decode`)

/// สิ่งที่ช่องรูปของตระกูลนี้ได้มาจริง
enum CutoutPlane {
    /// คนยืนอยู่บนการ์ด · `own` = รูปของเจ้าของการ์ดเอง (ไม่ใช่ตัวอย่างที่เราแถมให้ดูท่า)
    case subject(UIImage, own: Bool)
    /// รูปทึบ — กลับไปโหมดกรอบ **เงียบ ๆ** ไม่มีป้ายแดง ไม่มีข้อความเตือน
    ///
    /// ข้อนี้คือสิ่งที่ทำให้คนกล้าลอง: เลือกรูปผิดแล้วไม่มีใครโดนลงโทษ ได้อีกหน้าตาหนึ่งที่ยังสวย
    case framed

    var subject: UIImage? {
        if case let .subject(ui, _) = self { return ui }
        return nil
    }
    var isSample: Bool {
        if case let .subject(_, own) = self { return !own }
        return false
    }
}

/// รูปตัวอย่างที่แถมมากับแอป — **เหตุผลที่มันมีอยู่ไม่ใช่เพื่อความสวยของพรีวิว**
///
/// ถ้าตระกูลนี้ตกไปใช้รูปตัวอย่างทึบของระบบเหมือน widget อื่น เจ้าของการ์ดจะไม่มีวันเห็นท่าคัตเอาต์
/// จนกว่าจะบังเอิญอัปรูป PNG มาเอง ซึ่งจะไม่เกิดขึ้นเพราะไม่มีอะไรบอกเขาว่ามีท่านี้อยู่
/// การ์ดเปล่าจึงต้องโชว์ผลลัพธ์ที่ถูกต้องตั้งแต่วินาทีแรก — นี่คือทั้งหมดของการ "ชวนให้เอา PNG มา"
enum CutoutSample {
    static let image = UIImage(named: "cutout-sample")
}

/// `lift` = ชิ้นนี้ลบพื้นหลังให้เอง (ดู `WidgetInstance.liftPhoto`) — รูปทึบจะถูกส่งเข้า Vision
/// ระหว่างรอยังเป็นโหมดกรอบ แล้วเปลี่ยนเป็นคนยืนบนการ์ดเมื่อเสร็จ · หาตัวแบบไม่เจอ = กรอบต่อไปเงียบ ๆ
@MainActor
func cutoutPlane(_ store: PhotoStore, slot: Int, widget: UUID?, lift: Bool = false) -> CutoutPlane {
    guard let ui = store.userImage(slot: slot, for: widget) else {
        guard let sample = CutoutSample.image else { return .framed }
        return .subject(sample, own: false)
    }
    let r = CutoutCache.shared.result(for: ui)
    if r.isCutout { return .subject(r.image, own: true) }
    guard lift else { return .framed }
    guard let lifted = SubjectLift.shared.result(for: ui) else {
        SubjectLift.shared.request(ui)
        return .framed
    }
    return lifted.isCutout ? .subject(lifted.image, own: true) : .framed
}

/// ช่องนี้กำลังรอ Vision อยู่ไหม — ให้ป้ายสถานะบอกว่า "กำลังลบพื้นหลัง" แทนคำเชิญเดิม
@MainActor
func cutoutLifting(_ store: PhotoStore, slot: Int, widget: UUID?, lift: Bool) -> Bool {
    guard lift, let ui = store.userImage(slot: slot, for: widget) else { return false }
    return SubjectLift.shared.isRunning(ui)
}

// MARK: - ชิ้นส่วนร่วม

/// ตัวคนบนการ์ด — ไม่มี clip ไม่มีกรอบ มีแค่เงาที่บอกว่ามันลอยอยู่เหนือพื้น
struct CutoutSubject: View {
    @Environment(PhotoStore.self) private var store
    @Environment(\.widgetID) private var wid
    let image: UIImage
    let height: CGFloat
    let d: CGFloat
    /// ระยะที่ตัวคนถ่วงตัวเวลาเลื่อนหน้า — น้อยกว่าพื้นและหน้าเสมอ (มันคือชั้นกลาง)
    let drift: CGFloat
    /// เงาใต้ตัว — โปสเตอร์กระดาษไม่มีเงา ตัวคนถูก *พิมพ์ลงบนแผ่น* ไม่ได้ยืนอยู่เหนือมัน
    var shadow: Bool = true

    /// กว้างเท่าไหร่ที่ความสูงนี้ — คิดจากสัดส่วนของรูปเอง ไม่ใช่ปล่อยให้ `scaledToFit` เดา
    ///
    /// เคยใช้ `.scaledToFit().frame(height:)` แล้วเจอกับดัก: ถ้ากรอบที่ผู้เรียกให้มา **แคบกว่า**
    /// ความกว้างที่ควรได้ ภาพจะถูกจำกัดด้วยความกว้างแทน แล้ว *เตี้ยลงกว่าที่สั่ง* เงียบ ๆ
    /// ผลคือตัวคนลอยเหนือขอบล่างเป็นช่องดำ ซึ่งอ่านเป็นรูปที่วางผิด ไม่ใช่การจัดองค์ประกอบ
    private var width: CGFloat {
        let ar = image.size.height > 0 ? image.size.width / image.size.height : 0.7
        return height * ar
    }

    /// ช่อง 1 เสมอ — ทุกใบในตระกูลนี้มีคนแค่ช่องเดียว
    private var fit: PhotoFit { store.fit(slot: 1, for: wid) }

    var body: some View {
        ScrubReader(d: d) { dd in
            let t = Scrub.ease(Scrub.t(dd))
            let s = Scrub.dir(dd)
            Image(uiImage: image)
                .resizable()
                .frame(width: width, height: height)
                // เงาสองชั้น: ชั้นกว้างคือระยะห่างจากพื้น ชั้นแคบคือจุดที่เท้าแตะ
                // ชั้นเดียวอ่านเป็นสติกเกอร์ที่ถูกแปะ ไม่ใช่คนที่ยืนอยู่
                .shadow(color: .black.opacity(shadow ? 0.55 : 0), radius: 26, y: 20)
                .shadow(color: .black.opacity(shadow ? 0.35 : 0), radius: 6, y: 3)
                // จัดรูปของเจ้าของการ์ด (ดู `PhotoFitSurface`) — ซูมยึด **เท้า** ไม่ใช่กลางตัว
                // คนที่ขยายต้องโตขึ้นไปข้างบนจากพื้นที่ยืนอยู่ ไม่ใช่ลอยหลุดจากขอบล่าง
                .scaleEffect(fit.zoom, anchor: .bottom)
                .offset(x: fit.dx * width, y: fit.dy * height)
                .offset(x: s * drift * t)
                .scaleEffect(1 - 0.04 * t, anchor: .bottom)
                .opacity(Scrub.fade(t, after: 0.86))
        }
        .frame(width: width, height: height)
    }
}

/// สถานะของช่องรูป — โผล่เฉพาะตอนแต่งการ์ด
///
/// ไม่ใช่ปุ่ม (ตัว widget ถูกปิด hit testing ทั้งก้อน ปุ่มจริงอยู่ชั้น tile — ดู `PhotoSlotButton`)
/// มันคือ **ป้ายบอกสถานะ** อย่างเดียว และนั่นพอแล้ว: ป้ายเขียวคือรางวัลที่สอนว่ารูปแบบไหน "ผ่าน"
/// ส่วนป้ายจาง ๆ คือคำเชิญที่ไม่ขวางทาง — ไม่มีใครถูกบังคับให้ไปหา PNG มาก่อนจึงจะใช้การ์ดได้
struct CutoutStatus: View {
    @Environment(\.textEditMode) private var editing
    let plane: CutoutPlane
    let theme: CardTheme
    var lifting = false

    var body: some View {
        if editing, let label {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 7.5, weight: .bold))
                Text(label)
                    .font(.sh(8.5, .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(good ? .black.opacity(0.85) : .white.opacity(0.9))
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background {
                Capsule().fill(good ? AnyShapeStyle(theme.accent)
                                    : AnyShapeStyle(Color.black.opacity(0.55)))
            }
            .overlay(Capsule().strokeBorder(.white.opacity(good ? 0 : 0.22), lineWidth: 0.5))
        }
    }

    private var good: Bool {
        if case .subject(_, true) = plane { return true }
        return false
    }
    private var icon: String { good ? "checkmark" : (lifting ? "hourglass" : "wand.and.stars") }
    private var label: String? {
        if lifting { return "กำลังลบพื้นหลัง…" }
        switch plane {
        case .subject(_, true):  return "พื้นหลังใส"
        case .subject(_, false): return "รูปตัวอย่าง"
        case .framed:            return "ใส่รูปพื้นหลังใสได้อีกแบบ"
        }
    }
}
