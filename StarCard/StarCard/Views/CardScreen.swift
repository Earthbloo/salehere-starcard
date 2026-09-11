import Combine
import SwiftUI
import UIKit

struct CardScreen: View {
    /// คลิปเปิดมาดูอย่างเดียว — ห้ามเข้าโหมดแต่ง / ตู้ widget / ลากวาง
    var viewOnly = false
    /// รูปแบบการ์ด — เลือกมาแล้วจากหน้าแรก และ **ห้ามเปลี่ยนระหว่างทาง**
    ///
    /// ทุกอย่างที่ผูกกับ "กี่หน้า" อ่านค่าจากตัวนี้ที่เดียว: ขนาดหน้า · จุดบอกหน้า ·
    /// การปัดเปลี่ยนหน้า · การเปิดหน้าใหม่ตอนของล้น · รูปที่ export
    let format: CardFormat
    /// ใบในคลังที่ห้องนี้กำลังแก้ — งานทุกจังหวะบันทึกกลับใบนี้ · nil = คลิปเปิดดูอย่างเดียว
    var cardID: String?
    /// การ์ดเพิ่งเกิดจากการแตะเทมเพลต — ถ้าออกโดย **ไม่เคยแตะแก้อะไรเลย** ให้ทิ้งใบนี้
    ///
    /// แตะเทมเพลตคือทางเดียวที่จะ "ขอดูใกล้ ๆ" ได้ ถ้าทุกแตะกลายเป็นการ์ดถาวร
    /// คนเลือกแบบสามรอบจะได้ขยะสามใบไปนอนในคลัง — การดูเฉย ๆ ต้องไม่ทิ้งรอย
    var discardIfUntouched = false
    /// ทางกลับไปคลังการ์ด — nil = ไม่มีทางกลับ (คลิป)
    var onChangeFormat: (() -> Void)?

    /// ผู้ใช้แตะต้องใบนี้แล้วหรือยัง — เข้าโหมดแต่ง หรือผัง/ธีมขยับ นับหมด (แค่ปัดดูหน้าไม่นับ)
    @State private var touched = false

    @State private var pages: [CardPage]
    @State private var theme = CardTheme()
    @State private var showHire = false

    /// โหมดแต่ง — เปิดจากปุ่ม "แต่ง" ซ้ายบน · เข้ามาแล้วยังไม่มีชีต แคนวาสเต็มจอ
    @State private var isEditing = false
    /// สวิตช์ชีตเครื่องมือ — ปุ่มพาเลตข้าง "เสร็จ" · เปิดคือมีชีตทั้งใบ ปิดคือไม่มีชีตเลย
    @State private var showTools = false
    /// ตู้ widget — เปิดจากปุ่ม + ขวาบน
    @State private var showGallery = false
    /// จังหวะ "เปิดไฟ" ตอนเพิ่งเข้าโหมดแต่ง — กรอบประทุกชิ้นเข้มขึ้นชั่วครู่แล้วค่อยจางลงพอดี
    ///
    /// เข้าโหมดแต่งแล้วหน้าตาการ์ดเหมือนเดิมเป๊ะ คือเหตุผลที่คนหาไม่เจอว่าอะไรแก้ได้
    /// (เห็นชัดตอนเทส: ทั้งสามคนไปจบที่ปุ่มพาเลตบนแถบบน เพราะเป็นปุ่มเดียวที่มองเห็น)
    /// การกวาดสายตาครั้งแรกจึงต้องได้คำตอบว่า "ของบนหน้านี้แตะได้ทุกชิ้น" โดยไม่ต้องอ่านอะไร
    @State private var editReveal = false
    @State private var revealTask: Task<Void, Never>?
    @State private var selected: UUID?
    @State private var sheetDetent: PresentationDetent = SheetStop.normal

    /// ตัวเลือกสีพื้นกางอยู่ไหม — หุบไว้ตั้งต้น เม็ดสีเม็ดเดียวตอบได้แล้วว่าตอนนี้พื้นสีอะไร
    @State private var colorOpen = false
    /// สิ่งที่กำลังพิมพ์ในช่อง hex — แยกจากธีมเพราะระหว่างพิมพ์ค่ายังอ่านไม่ออก
    /// ถ้าผูกกับธีมตรง ๆ การ์ดจะกระพริบเป็นสีมั่วทุกตัวอักษรที่พิมพ์
    @State private var hexDraft = ""
    /// กล่องถามรหัสสีเปิดอยู่ไหม
    @State private var hexPrompt = false

    /// การ์ดไม่เหลือที่แม้แต่ของชิ้นเล็กที่สุดแล้วหรือยัง
    ///
    /// วัดด้วย `PageLayout.minSize` ไม่ใช่ขนาดของ widget ตัวใดตัวหนึ่ง — ตอบว่า "เต็ม" ได้ต่อเมื่อ
    /// ไม่มีอะไรลงได้เลยจริง ๆ · ถ้าเหลือที่ให้ของเล็กแต่ไม่พอสำหรับตัวที่ผู้ใช้เลือก อันนั้นเป็นหน้าที่
    /// ของ `warn` ตอนถูกปฏิเสธ ไม่ใช่ป้ายเหมาว่าเพิ่มอะไรไม่ได้เลย ซึ่งจะเป็นการโกหก
    private var cardIsFull: Bool {
        guard pages.count >= format.pageCount, pageSize != .zero else { return false }
        return !pages.contains { page in
            PageLayout.freeSpot(size: PageLayout.minSize, page: pageSize, avoiding: page.items) != nil
        }
    }

    private var galleryFullBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "tray.full.fill").font(.sh(13))
            VStack(alignment: .leading, spacing: 2) {
                Text("การ์ดเต็มแล้ว").font(.sh(12.5, .semibold))
                Text(format.pageCount == 1
                     ? "หน้านี้ไม่เหลือที่ว่าง — เอาของออกหรือย่อของเดิมก่อนถึงจะเพิ่มได้"
                     : "ครบ \(format.pageCount) หน้าและไม่เหลือที่ว่าง — เอาของออกก่อนถึงจะเพิ่มได้")
                    .font(.sh(10.5, .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 14).padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.08)))
    }

    /// ระดับชีตที่ **พอดีกับแผงตอนนี้**
    ///
    /// ไม่ใช่เรื่องความสวย — แผงที่ยาวเกินกรอบชีตทำให้พื้นที่รับทัชเลื่อนออกจากที่วาดจริง
    /// ราวห้าสิบพอยต์ทั้งแผง (เหตุผลเต็มอยู่ที่ `SheetStop.tall`) สองสถานะที่ยาวคือ
    /// ตอนกางตัวเลือกสี กับตอนพื้นหลังเป็นรูปแล้วมีแถวเอฟเฟกต์กับแถบความจางเพิ่มมา
    private var fittingDetent: PresentationDetent {
        guard selectedItem == nil else { return SheetStop.normal }
        if theme.backdrop == .photo { return photos.background != nil ? SheetStop.tall : SheetStop.normal }
        return colorOpen ? SheetStop.tall : SheetStop.normal
    }

    /// ปรับระดับชีตให้พอดีแผง — เรียกหลังทุกอย่างที่เปลี่ยนความสูงของแผง
    /// ไม่แตะเมื่อผู้ใช้ดันชีตขึ้นสุดเอง ตรงนั้นเขาเลือกแล้วว่าจะดูทั้งแผงเต็ม ๆ
    private func fitSheet() {
        guard sheetDetent != .large else { return }
        sheetDetent = fittingDetent
    }

    /// หน้าที่กำลังดูอยู่
    @State private var index = 0
    /// ความคืบหน้าของการปัด -1…1 · ขับ crossfade เอง ไม่ใช้ ScrollView เพราะ ScrollView สไลด์เสมอ
    @State private var swipe: CGFloat = 0

    /// ผังที่แคชไว้ของหน้าปัจจุบัน — ห้าม solve ใหม่ทุก touch event
    @State private var placed: [Placed] = []
    /// `placed` เป็นผังของหน้าไหน — ตัวกันไม่ให้หน้าใหม่ถูกวาดด้วยผังของหน้าเก่า
    @State private var placedPage: UUID? = nil
    /// ขนาดหน้าใน **หน่วยออกแบบ** — ไม่ใช่หน่วยจอ (ดู `CardFormat.pageSize(in:)`)
    @State private var pageSize: CGSize = .zero
    /// อัตราย่อจากหน่วยออกแบบลงหน่วยจอ — 1 เมื่อหน้าได้ขนาดมาจากจออยู่แล้ว
    ///
    /// ทุกที่ที่ต้องแปลง "สิ่งที่นิ้วทำบนจอ" เป็น "สิ่งที่เกิดบนหน้ากระดาษ" อ่านค่านี้
    /// ผ่าน `canvasScale` ที่เดียว — ไม่มีใครคูณ/หารสเกลเองอีก
    @State private var pageFit: CGFloat = 1
    /// ความกว้างจอ — ใช้ล็อกความกว้างแผงล่าง ไม่ให้เนื้อหาข้างในดันจนล้นจอ
    @State private var viewportW: CGFloat = 402

    /// ข้อความบอกเหตุชั่วคราว — ใช้ตอนที่ระบบ **ปฏิเสธ** สิ่งที่ผู้ใช้สั่ง
    ///
    /// การสั่นอย่างเดียวบอกได้แค่ว่า "ไม่สำเร็จ" ไม่ได้บอกว่าทำไมและต้องทำอะไรต่อ
    @State private var notice: CardNotice?
    @State private var noticeClear: DispatchWorkItem?

    // การลาก
    @State private var dragID: UUID?
    @State private var dragStart: CGRect = .zero
    @State private var dragTranslation: CGSize = .zero
    /// ตัวจับเวลาตอนลากค้างที่ขอบหน้า — ครบเวลาแล้วพา widget ข้ามหน้า
    @State private var edgeFlip: DispatchWorkItem?
    /// ช่องที่นิ้วชี้อยู่ตอนนี้ — ตัวขับ "ของอื่นหลบระหว่างที่นิ้วยังอยู่"
    @State private var dragOrigin: CGPoint?
    /// ความกว้างที่ถูกย่อให้พอดีช่องว่างตรงที่นิ้วชี้ — nil = ใช้ความกว้างเดิม
    @State private var dragWidth: CGFloat?
    /// ตัวหน่วงก่อนคอมมิตช่องใหม่ — กันไม่ให้ลากผ่านเร็ว ๆ แล้วทั้งหน้ากระตุกสะบัด
    @State private var reflow: DispatchWorkItem?
    /// เวลาที่จัดผังใหม่ครั้งล่าสุดระหว่างลาก — ใช้คุมให้ไม่ถี่เกิน `reflowGap`
    @State private var lastReflow: TimeInterval = 0
    /// ตำแหน่งนิ้วภายใน widget ตอนเริ่มลาก — ใช้คำนวณนิ้วจริงบนหน้า
    /// (เช็คจากจุดกลาง widget ไม่ได้ เพราะตัวกว้างเต็มหน้าจุดกลางไปไม่ถึงขอบ)
    @State private var dragGripX: CGFloat = 0
    /// ความสูงจอ — ใช้คำนวณสเกลแคนวาสตอนแต่ง
    @State private var viewportH: CGFloat = 874

    /// **เจตนา**ที่จะเปิดเครื่องมืออยู่ — ค้างไว้ตลอดชั้น ไม่หายไปเพราะชีตหลบคีย์บอร์ดชั่วคราว
    ///
    /// แยกจาก `showsToolSheet` (ชีตขึ้นอยู่จริงไหม) เพราะสองอย่างนี้ไม่ใช่เรื่องเดียวกัน:
    /// ระหว่างพิมพ์ ชีตต้องลง แต่ผู้ใช้ยัง "อยู่ในเครื่องมือ" อยู่ กด เสร็จ แล้วต้องได้ชีตคืน
    private var toolsOpen: Bool { isEditing && showTools }

    /// ชีตเครื่องมือกำลังขึ้นอยู่ไหม
    ///
    /// ชีตกับคีย์บอร์ดแย่งครึ่งล่างของจอกันตรง ๆ ชีตจึงหลบให้ระหว่างพิมพ์ —
    /// แต่ **หลบโดยไม่ทิ้งเจตนา** `showTools` ยังเป็น true อยู่ พอปิดช่องพิมพ์ชีตจึงกลับขึ้นมาเอง
    /// (เดิมสั่ง `showTools = false` ตอนเริ่มพิมพ์ ผลคือกด เสร็จ ทีเดียวหลุดออกมาทั้งสองชั้นรวด)
    private var showsToolSheet: Bool { toolsOpen && Profile.me.editing == nil }

    /// ความสูงของสิ่งที่บังจอด้านล่างอยู่ตอนนี้ — ชีตเครื่องมือ **หรือ** คีย์บอร์ด+แถบพิมพ์
    /// สองอย่างนี้ไม่มีวันบังพร้อมกัน (ชีตหลบให้คีย์บอร์ดเสมอ) จึงยุบเหลือตัวเลขเดียว
    /// ทุกที่ที่ต้องรู้ว่า "เหลือที่ว่างเท่าไหร่" จึงอ่านจากที่เดียว ไม่มีทางคิดคนละแบบ
    private var bottomCover: CGFloat {
        if Profile.me.editing != nil { return keyboard + Self.editBarHeight }
        guard showsToolSheet else { return 0 }
        if sheetDetent == SheetStop.compact { return 84 }
        if sheetDetent == .large { return viewportH * 0.72 }
        if sheetDetent == SheetStop.tall { return 560 }
        return 340
    }

    /// สเกลตอนแต่ง — ย่อเท่าที่จำเป็นหลังดันขึ้นแล้ว ไม่ล็อกเพดาน 0.82 ที่เคยให้ชีตทับการ์ด
    private var editScale: CGFloat {
        // โชว์รูมโชว์ชิ้นเดียว จึงไม่ต้องย่อทั้งหน้าให้พอดีช่องว่าง — `showroom` จัดขนาดของชิ้นนั้นเอง
        // ถ้ายังย่อซ้ำ ของที่ยกขึ้นมาโชว์จะเล็กกว่าตอนอยู่บนการ์ดจริง ซึ่งกลับหัวกลับหางกับคำว่าโชว์รูม
        if showroomID != nil { return 1 }
        let visible = viewportH - bottomCover - 74 - 8
        // เทียบกับความสูง **ที่วาดออกมาจริงบนจอ** ไม่ใช่ความสูงในหน่วยออกแบบ
        let fit = visible / max(pageSize.height * pageFit, 1)
        return fit > 0.92 ? 1 : min(1, max(0.62, fit))
    }
    /// สเกลรวมจากหน่วยออกแบบถึงหน่วยจอ — ย่อให้พอดีจอ **คูณ** ย่อเพื่อหลบชีตตอนแต่ง
    private var canvasScale: CGFloat { (isEditing ? editScale : 1) * pageFit }

    /// ดันแคนวาสขึ้นให้ widget ที่เลือก (หรือท้ายหน้า) อยู่ในช่องว่างเหนือชีต
    private var canvasLift: CGFloat {
        // โชว์รูมพา widget ไปยืนกลางช่องว่างเองแล้ว — และ "ช่องว่าง" นับคีย์บอร์ดไว้ด้วย
        // (ดู `bottomCover`) จึงไม่ต้องดันทั้งแคนวาสซ้ำแม้ตอนกำลังพิมพ์
        //
        // เดิมมีสาขาแยกที่ดันแคนวาสตามบรรทัดที่พิมพ์อยู่ — จำเป็นตอนที่พิมพ์ได้จากทั้งหน้า
        // ตอนนี้พิมพ์ได้เฉพาะในโชว์รูม ซึ่งจัดตำแหน่งเองอยู่แล้ว สาขานั้นจึงเป็นโค้ดที่ไม่มีทางถึง
        if showroomID != nil { return 0 }
        let cover = bottomCover
        guard isEditing, cover > 0 else { return 0 }
        let top: CGFloat = 74
        let visibleBottom = viewportH - cover
        let s = canvasScale
        // ระหว่างลาก ผังขยับทุกครั้งที่สลับที่ — ถ้าให้ระยะดันวิ่งตามตัวที่เลือก
        // แคนวาสจะกระตุกใต้นิ้วจนลากลงท้ายหน้าไม่ได้ · ตอนลากจึงยึดท้ายหน้าเป็นหลักซึ่งนิ่งเสมอ
        // ระหว่างยืดก็ยึดท้ายหน้าเหมือนกัน — ถ้าให้ระยะดันวิ่งตามขอบล่างของตัวที่ยืด
        // แคนวาสจะเลื่อนขึ้นทุกครั้งที่สูงขึ้นหนึ่งแถว นิ้ว (ซึ่งนิ่งอยู่กับที่บนจอ)
        // จะกลายเป็นอยู่ต่ำลงในพิกัดหน้า → สูงขึ้นอีกแถว → วนยืดไม่หยุด
        if dragID == nil, resizeID == nil, let id = selected, let p = placed.first(where: { $0.id == id }) {
            let widgetBottom = top + p.frame.maxY * s
            let overflow = widgetBottom + 20 - visibleBottom
            return max(0, overflow)
        }
        let pageBottom = top + pageSize.height * s
        return max(0, pageBottom + 12 - visibleBottom)
    }
    /// สำเนา widget ที่กำลังลาก — ใช้วาดชั้นลอยที่ระดับ deck ให้อยู่รอดข้ามการสลับหน้า
    @State private var dragItem: WidgetInstance?
    /// หน้าบ้านเดิมของตัวที่ลาก — ไว้พากลับเมื่อปล่อยในที่ที่วางไม่ได้
    @State private var dragOriginPage = 0
    @State private var lifted = false
    /// ความหมายของท่ากดค้างที่กำลังทำอยู่ — ตัดสินตอนนิ้วลงครบเวลา แล้ว **ล็อกไว้จนปล่อยนิ้ว**
    ///
    /// กดค้างบน widget มีสองความหมาย: ในโชว์รูมคือ "ลากเก็บออกจากเครื่องมือ" นอกโชว์รูมคือ
    /// "ย้ายที่" · แต่ `showroomID` เปลี่ยนได้ระหว่างนิ้วยังอยู่ (ตัวที่เลือกเปลี่ยน · ชีตเปิด/ปิด)
    /// ถ้าให้ทั้งสามช่วงของ gesture อ่านสด ๆ ท่าเดียวจะกลายเป็นคนละท่ากลางคัน แล้ว `endDrag`
    /// จะไม่มีวันถูกเรียก — `dragID` ค้างตลอดไป ซึ่งแปลว่ากรอบเลือกไม่ขึ้น หมุดปรับขนาดหาย
    /// และกดอะไรบนการ์ดก็ไม่ติดอีกเลยจนกว่าจะปิดแอป
    @State private var pressMode: (id: UUID, showroom: Bool)?
    /// จุดที่นิ้วแตะบน widget ตัวที่กำลังกด — ขับการเอียง 3 มิติ
    @State private var pressPoint: (id: UUID, at: CGPoint)?
    /// ให้กรอบเลือกไหลจาก widget เดิมไปตัวใหม่ แทนที่จะกระพริบหายแล้วโผล่
    @Namespace private var selectionNS
    /// หน้าตัวอย่างก่อนแชร์รูป / คัดลอกลิงก์
    @State private var showPreview = false

    // การแก้ข้อความบนตัว widget
    /// กรอบของช่องข้อความทุกช่องบนหน้า แยกตาม widget
    ///
    /// เก็บในกล่องอ้างอิงแทน `@State` ปกติ เพราะค่านี้ถูกเขียนใหม่ทุกครั้งที่ผังเปลี่ยน
    /// แต่ไม่มีใครใช้มัน *ตอนวาด* — มีแต่ตอนนิ้วแตะ ถ้าเป็น state จะสั่งวาดใหม่ฟรี ๆ ทุกเฟรม
    @State private var slotBox = TextSlotBox()
    /// กรอบของลิงก์ทุกอันบนหน้า แยกตาม widget — กล่องอ้างอิงด้วยเหตุผลเดียวกับ `slotBox`
    @State private var linkBox = LinkSlotBox()
    /// ลิงก์ที่กำลังเปิดอยู่ในเบราว์เซอร์ในแอป — ช่องโซเชียลพาไปหน้าโปรไฟล์ ผลงานพาไปโพสต์จริง
    @State private var link: LinkTarget?
    /// ทางออกสำรองสำหรับลิงก์ที่ `SFSafariViewController` เปิดไม่ได้ (ไม่ใช่ http/https)
    @Environment(\.openURL) private var openURL
    /// ความสูงของคีย์บอร์ดที่บังจออยู่
    @State private var keyboard: CGFloat = 0
    /// ระยะที่นิ้วลากชิ้นงานลงในโชว์รูม — ปล่อยเกินระยะแล้วออกจากโชว์รูม
    @State private var showroomDrag: CGFloat = 0

    // การปรับขนาด
    @State private var resizeID: UUID?
    /// ความสูงจริงที่เนื้อหาของตัวที่เลือกต้องการ — วัดจากของจริง ไม่ใช่ตัวเลขที่ตั้งด้วยมือ
    /// nil = ยังวัดไม่ได้ (หรือเป็น widget ที่ยืดหดได้อิสระอย่างรูป) → ใช้เพดานล่างของกริดแทน
    @State private var contentH: CGFloat?
    /// ระยะที่ลากเลยขีดจำกัดไปแล้ว — **ขยับแค่กรอบ ไม่ขยับตัว widget**
    /// ปล่อยนิ้วแล้วสปริงกลับเป็นศูนย์ ผู้ใช้จึงรู้ว่า "สุดแล้ว" โดยไม่ต้องมีข้อความบอก
    @State private var overshoot: CGSize = .zero
    @State private var resizeW: CGFloat = 0
    @State private var resizeH: CGFloat = 0
    /// สเกลที่ชิ้นงานถูกยกขึ้นในโชว์รูม ณ วินาทีที่เริ่มลากหมุด
    ///
    /// หมุดวัดระยะในพิกัด "หน้ากระดาษ" แต่ขอบที่ตาเห็นถูกโชว์รูมขยายไปแล้ว — ต้องหารกลับ
    /// ไม่งั้นลากหนึ่งช่องบนจอได้ไม่เท่าหนึ่งช่องจริง · **จับค่าไว้ตอนเริ่ม ไม่อ่านสด**
    /// เพราะสเกลโชว์รูมคำนวณจากขนาดของชิ้นงาน ถ้าอ่านสดจะกลายเป็นวงป้อนกลับ
    /// (โต→สเกลลด→ระยะที่หารได้เพิ่ม→โตอีก)
    @State private var resizeScale: CGFloat = 1

    /// ความสูงของหน้าต่างที่แอปอยู่ — กรอบคีย์บอร์ดที่ระบบส่งมาอยู่ในพิกัดจอ
    /// ต้องเทียบกับความสูงจริงของหน้าต่าง ไม่ใช่ `viewportH` ที่หักแถบระบบไปแล้ว
    /// ความสูงโดยประมาณของแถบพิมพ์ — ใช้กันไม่ให้บรรทัดที่กำลังแก้มุดไปอยู่ใต้มัน
    private static let editBarHeight: CGFloat = 66

    private static func windowHeight() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .frame.height ?? 0
    }

    /// โหมดโชว์รูม — เปิดแผงเครื่องมือของ widget ตัวใดตัวหนึ่งอยู่
    ///
    /// ระหว่างแต่งชิ้นเดียว ของที่เหลือบนหน้าคือสิ่งรบกวนล้วน ๆ — มันแย่งสายตาและทำให้ตัดสินใจยาก
    /// ว่าที่เพิ่งเปลี่ยนไปคืออะไร · ซ่อนที่เหลือแล้วยกตัวเดียวขึ้นกลางที่ว่าง เหลือของให้ดูชิ้นเดียว
    private var showroomID: UUID? {
        // ระหว่างลากย้ายที่ **ห้ามเข้าโชว์รูม** — `beginDrag` ตั้งตัวที่จับขึ้นมาให้เป็นตัวที่เลือก
        // ถ้าชีตเปิดค้างอยู่ (เช่นแผงธีมซึ่งยังไม่มีตัวไหนถูกเลือก) ตัวที่เพิ่งถูกจับจะกลายเป็น
        // ตัวในโชว์รูมทันทีตั้งแต่นิ้วยังไม่ขยับ — ที่เหลือทั้งหน้าหายไปกลางการลาก
        // และท่าที่กำลังทำอยู่เปลี่ยนความหมายกลางคันจาก "ย้ายที่" เป็น "ลากเก็บออกจากเครื่องมือ"
        guard dragID == nil else { return nil }
        // อ่านจาก `toolsOpen` ไม่ใช่ `showsToolSheet` — ระหว่างพิมพ์ชีตลงไปแล้ว
        // แต่ยังต้องอยู่ในโชว์รูม ไม่งั้นตัวที่กำลังแก้ข้อความจะวิ่งกลับเข้าผังทันทีที่คีย์บอร์ดขึ้น
        return toolsOpen && selectedItem != nil ? selected : nil
    }

    /// ท่าที่พา widget ตัวที่กำลังแต่งไปยืนกลางช่องว่างเหนือชีต
    ///
    /// คำนวณในพิกัด "หน้ากระดาษ" ไม่ใช่พิกัดจอ เพราะ tile ทุกตัวถูกวางด้วย `.offset` ในระบบนั้น
    /// แปลงกลับด้วย `canvasScale` ทีเดียวตรงนี้ ที่เหลือจึงบวกลบกันตรง ๆ ได้
    private func showroom(_ p: Placed) -> (scale: CGFloat, dx: CGFloat, dy: CGFloat) {
        guard showroomID == p.id else { return (1, 0, 0) }
        let s = max(canvasScale, 0.01)
        // ช่องว่างที่เหลือระหว่างแถบบนกับหลังคาชีต แปลงเป็นหน่วยของหน้ากระดาษ
        let band = max(140, (viewportH - bottomCover - 74 - 16) / s)
        let fit = min((band - 28) / max(p.frame.height, 1),
                      (pageSize.width - 8) / max(p.frame.width, 1))
        // ไม่ขยายเกิน 1.35 เท่า — ใหญ่กว่านั้นตัวอักษรเริ่มแตกและอ่านเป็นพรีวิว ไม่ใช่ของจริง
        //
        // ต้องกลางทั้งสองแกน: ตัวที่กว้างไม่เต็มหน้าอยู่ตรงไหนของผังก็ค้างอยู่ตรงนั้น
        // พอขยายขึ้นแล้วมันล้นออกนอกจอด้านที่มันชิดอยู่ ซึ่งอ่านเป็น layout พังมากกว่าโชว์รูม
        return (min(1.35, max(0.5, fit)),
                pageSize.width / 2 - p.frame.midX,
                band / 2 - p.frame.midY)
    }

    init(viewOnly: Bool = false, cardID: String? = nil, discardIfUntouched: Bool = false,
         format: CardFormat = .portfolio, onChangeFormat: (() -> Void)? = nil) {
        self.viewOnly = viewOnly
        self.cardID = cardID
        self.discardIfUntouched = discardIfUntouched
        self.onChangeFormat = onChangeFormat
        // เปิดจากคลัง = โหลดใบนั้นทั้งดุ้นตั้งแต่ init — ไม่มีจังหวะที่หน้าตั้งต้นแวบขึ้นก่อน
        if let cardID, let record = CardLibrary.shared.card(id: cardID),
           let restored = CardStore.restore(record.snapshot) {
            self.format = record.format
            _pages = State(initialValue: restored.pages)
            _theme = State(initialValue: restored.theme)
            _index = State(initialValue: restored.index)
        } else {
            self.format = format
            _pages = State(initialValue: format.starterPages)
        }
    }

    /// การ์ดนี้มีหน้าให้เปลี่ยนไหม — จุดบอกหน้า/การปัด/การลากข้ามหน้าแขวนอยู่กับข้อนี้ทั้งหมด
    private var multiPage: Bool { pages.count > 1 }

    private var current: CardPage? { pages.indices.contains(index) ? pages[index] : nil }
    private var selectedItem: WidgetInstance? {
        pages.flatMap(\.items).first { $0.id == selected }
    }

    var body: some View {
        GeometryReader { geo in
            // พื้นที่ที่เหลือหลังเว้นแถบบนกับแถวจุดบอกหน้า
            //
            // พอร์ตเอาขนาดนี้ไปใช้ตรง ๆ · สตอรี่ไม่สนใจมันเลย (หน้าเป็น 540×960 เสมอ)
            // แล้วใช้กล่องนี้แค่คำนวณว่าต้องย่อเท่าไหร่ถึงจะพอดีจอเครื่องนี้
            let box = CGSize(width: geo.size.width,
                             height: geo.size.height - 74 - 34)
            let size: CGSize = format.pageSize(in: box)
            let fit: CGFloat = format.fit(in: box)

            ZStack {
                // หน้ามีขนาดตายตัวแล้ว จึงไม่มีทางเท่าจอทุกเครื่องพอดี — ที่ว่างรอบตัว
                // ต้องอ่านออกว่า **นอกเฟรม** ไม่ใช่ส่วนของการ์ดที่ยังว่างอยู่
                // ฉากหลังของธีมจึงถูกหุบเข้าไปในหน้า (ดู `.background` ของ deck)
                // แล้วรอบนอกเป็นเวทีมืดเหมือนหน้าตัวอย่างก่อนแชร์
                Color(white: 0.06).ignoresSafeArea()

                VStack(spacing: 0) {
                    Color.clear.frame(height: 74)
                    // กริดเป็น "พื้นของหน้ากระดาษ" ไม่ใช่ชั้นลอยแยก — จุดจึงอยู่พิกัดเดียวกับ widget เป๊ะ
                    // เคยเป็นชั้นแยกที่ ignoresSafeArea แล้วพิกัดมันเลื่อนขึ้นไปเท่าแถบบนของจอ
                    // จุดจึงลอยเหนือกรอบและวาดไม่ถึงท้ายหน้า
                    deck(size: size, fit: fit, viewport: geo.size)
                    Color.clear.frame(height: 34)
                }
                // โหมดแต่ง: ย่อให้พอดีช่องเหนือชีต แล้วดันของที่โฟกัสขึ้นมาให้เห็น
                //
                // ใช้ `editScale` ล้วน ไม่ใช่ `canvasScale` — การย่อจากหน่วยออกแบบลงหน่วยจอ
                // `deck` ทำไปแล้วข้างใน ถ้าคูณซ้ำตรงนี้การ์ดจะเล็กลงสองรอบ
                .scaleEffect(isEditing ? editScale : 1, anchor: .top)
                .offset(y: -canvasLift)

                topBar
                // จุดบอกหน้าหลบให้แถบพิมพ์ — มันนั่งที่เดียวกันพอดี และระหว่างพิมพ์ก็เปลี่ยนหน้าไม่ได้อยู่แล้ว
                if multiPage, Profile.me.editing == nil, showroomID == nil { pageRail }

                noticeBar

                // แถบพิมพ์ลอยเหนือคีย์บอร์ด — อยู่นอกแคนวาสที่ถูกย่อ/ดัน จึงไม่ขยับตามการ์ด
                if let id = Profile.me.editing {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        TextEditBar(id: id, theme: theme, onDone: endTextEdit)
                            .padding(.bottom, keyboard)
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(Motion.settle, value: keyboard)
            .animation(Motion.settle, value: sheetDetent)
            .animation(Motion.settle, value: canvasLift)
            .animation(Motion.settle, value: showTools)
            .onAppear { viewportH = geo.size.height }
            .onChange(of: geo.size.height) { _, h in viewportH = h }
            .onAppear { pageSize = size; pageFit = fit; viewportW = geo.size.width; resolve() }
            .onChange(of: size) { _, s in pageSize = s; resolve() }
            .onChange(of: fit) { _, f in pageFit = f }
            .onChange(of: geo.size.width) { _, w in viewportW = w }
            // ทางออกของการยืดที่ไม่ได้มาจากการปล่อยนิ้ว — ดู `endResize`
            .onChange(of: selected) { _, _ in endResize() }
            .onChange(of: isEditing) { _, editing in
                // เข้าโหมดแต่ง = ตั้งใจใช้ใบนี้แล้ว — ต่อให้ยังไม่ขยับอะไรก็ไม่ใช่การ "ดูเฉย ๆ"
                if editing {
                    touched = true
                    hintOnce("edit", "กดค้างที่ชิ้นแล้วลากเพื่อย้าย · แตะหนึ่งครั้งเพื่อเลือก แล้วจะมีหมุดปรับขนาดกับปุ่มเปลี่ยนรูปโผล่มา")
                    // กรอบเส้นประเข้มขึ้นตอนเข้า แล้วคลายลงเองใน 1.4 วิ
                    // จังหวะเข้าคือจังหวะเดียวที่สายตายังไม่รู้ว่าต้องมองอะไร ต้องดังตรงนั้น
                    // แล้วเบาลง ไม่งั้นเส้นประเข้ม ๆ รอบทุกชิ้นจะแย่งความสนใจกับงานที่กำลังแต่ง
                    editReveal = true
                    revealTask?.cancel()
                    revealTask = Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1.4))
                        guard !Task.isCancelled else { return }
                        withAnimation(Motion.settle) { editReveal = false }
                    }
                } else {
                    // ออกจากโหมดแต่งแล้วข้อความที่พูดถึงท่าในโหมดนั้นก็หมดหน้าที่
                    clearNotice()
                    revealTask?.cancel()
                    editReveal = false
                }
                endResize()
            }
            .onChange(of: index) { _, _ in
                // เปลี่ยนหน้าเพราะลาก widget ข้ามหน้า — ตัวที่ลากยังต้องถูกเลือกอยู่
                if dragID == nil { selected = nil }
                endTextEdit()
                resolve()
                persist()
            }
            .onChange(of: theme) { _, _ in
                touched = true
                persist()
            }
            .onChange(of: pages) { _, _ in
                touched = true
                persist()
                // ระหว่างยืดขนาด ใช้สปริงที่ตอบไว — Motion.flow นุ่มเกินไป
                // ขอบ widget จะรั้งอยู่หลังนิ้วครึ่งวินาที อ่านออกมาเป็น "ไม่ติดนิ้ว"
                withAnimation(resizeID == nil ? Motion.flow : Motion.snap) { resolve() }
            }
            .animation(Motion.settle, value: isEditing)
            .animation(Motion.settle, value: editReveal)
            // กติกาเหล็กของสามชั้น: **ช่องพิมพ์มีอยู่ได้เฉพาะข้างในโชว์รูม**
            //
            // ทางออกจากโชว์รูมมีหลายทาง (ปุ่มพาเลต · ปุ่ม เสร็จ บนแถบบน · ลบ widget · เปลี่ยนหน้า)
            // ถ้าให้แต่ละทางจำเองว่าต้องเก็บช่องพิมพ์ด้วย สักวันจะมีทางที่ลืม แล้วคีย์บอร์ดค้าง
            // ทับการ์ดโดยไม่มีอะไรชี้ว่ากำลังแก้อะไรอยู่ · บังคับที่เดียวตรงนี้แทน
            .onChange(of: showroomID) { _, room in if room == nil { endTextEdit() } }
        }
        // ปิดการหลบคีย์บอร์ดอัตโนมัติของ SwiftUI — มันดันทั้งจอขึ้นรวมแถบบนกับจุดบอกหน้า
        // การ์ดจึงถูกยกออกนอกจอครึ่งใบ · เราดันเองที่ `canvasLift` โดยดูจากบรรทัดที่กำลังพิมพ์
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            guard let f = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else { keyboard = 0; return }
            keyboard = max(0, Self.windowHeight() - f.minY)
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboard = 0
        }
        // ให้ระบบรู้ว่าพื้นสว่างหรือมืด — แถบสถานะกับ affordance ของ OS จะได้อ่านออก
        // สิ่งที่อยู่หลังแถบสถานะคือเวทีมืด ไม่ใช่หน้าการ์ด จึงตรึงเป็นมืดเสมอ
        .preferredColorScheme(.dark)
        // ชีตใบเดียวมีเครื่องมือครบ — ขึ้นเมื่อกดพาเลต หรือเมื่อเลือก widget · ปิดแล้วหายทั้งใบ
        // ปิดชีตแล้ว **ยังเลือกค้างไว้** — ออกจากโชว์รูมกลับมาเห็นทั้งหน้า แต่ยังแต่งตัวเดิมต่อได้ทันที
        // (เดิมล้างการเลือกทิ้งด้วย ต้องไปหาแล้วแตะใหม่ทุกครั้งที่เผลอปิดชีต)
        // ตัวเซ็ตเตอร์ไม่ยอมรับ "ปิด" ระหว่างพิมพ์ — ตอนนั้นชีตลงเพราะ `showsToolSheet` เป็น false
        // ซึ่งเป็นการ**หลบ** ไม่ใช่การปิด ถ้าปล่อยให้มันเขียน `showTools = false` ตามไปด้วย
        // เจตนาก็หายไปพร้อมกัน แล้วกด เสร็จ ก็ไม่เหลืออะไรให้กลับมา (นี่คืออาการเดิม)
        .sheet(isPresented: Binding(get: { showsToolSheet },
                                    set: { if !$0, Profile.me.editing == nil {
                                        withAnimation(Motion.settle) { showTools = false }
                                    } })) {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if let sel = selectedItem {
                            widgetPanel(sel)
                            variantPicker(sel)
                        } else {
                            themePanel
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, selectedItem == nil ? 12 : 16)
                    .padding(.bottom, 28)
                }
            }
            .environment(photos)
            // แผงของ widget ไม่มีระดับ "หุบเป็นแถบ" — ลากลงคือปิด แล้วออกจากโชว์รูมกลับไปเห็นทั้งหน้า
            //
            // ถ้ายังมีระดับนั้น การลากลงจะได้แถบเตี้ย ๆ ค้างไว้ พร้อมโชว์รูมที่ยังเปิดอยู่
            // — สถานะที่ไม่มีใครตั้งใจจะไปถึง และออกจากมันได้ยากกว่าเข้า
            // ส่วนแผงธีมของทั้งการ์ดยังมีครบ เพราะมันคือแผงที่ต้องเปิดค้างไว้ดูการ์ดไปปรับไป
            .presentationDetents(selectedItem == nil
                                 ? [SheetStop.compact, SheetStop.normal, SheetStop.tall, .large]
                                 : [SheetStop.normal, .large],
                                 selection: $sheetDetent)
            .presentationDragIndicator(.visible)
            .environment(\.colorScheme, .dark)
            .presentationBackground {
                Rectangle().fill(.ultraThinMaterial)
                    .overlay(Color(white: 0.07).opacity(theme.activeInk.isLight ? 0.86 : 0))
            }
            .presentationBackgroundInteraction(.enabled(upThrough: SheetStop.normal))
            .interactiveDismissDisabled()
            // พิมพ์ผิดแล้วดีดกลับไปสีจริง — ตรงกว่าการขึ้นข้อความเตือนที่ต้องอ่านแล้วแก้เอง
            .alert("สีพื้น", isPresented: $hexPrompt) {
                TextField(theme.backdropHex, text: $hexDraft)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                // พิมพ์ผิดแล้วไม่มีอะไรเกิดขึ้น สีเดิมอยู่ครบ — ไม่ต้องมีข้อความเตือนให้ต้องปิดอีกชั้น
                Button("ใช้สีนี้") { _ = theme.setBackdropHex(hexDraft) }
                Button("ยกเลิก", role: .cancel) {}
            } message: {
                Text("พิมพ์รหัสสีหกหลัก เช่น #F11717")
            }
            // ตู้ widget ต้องซ้อนอยู่บนชีตที่เปิดค้าง — ถ้าไปเปิดที่ราก ชีตล่างจะถูกหุบทิ้งก่อน
            .sheet(isPresented: Binding(get: { showGallery && showsToolSheet },
                                        set: { if !$0 { showGallery = false } })) {
                gallerySheet
            }
        }
        .sheet(isPresented: Binding(get: { showGallery && !showsToolSheet },
                                    set: { if !$0 { showGallery = false } })) {
            gallerySheet
        }
        .alert("ส่งคำขอแล้ว", isPresented: $showHire) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("ในคลิปนี้ยังเป็น mock — ของจริงจะพาไป inbox ของ @\(invocation.slug)")
        }
        // เบราว์เซอร์ในแอป — ทั้งใบเต็มจอเหมือน Safari ที่ผู้ใช้คุ้นอยู่แล้ว
        // ไม่ทำเป็นชีตครึ่งจอเพราะหน้าโปรไฟล์กับหน้ารีวิวคือของที่ต้อง "อ่าน" ไม่ใช่ของที่แค่ชำเลือง
        .fullScreenCover(item: $link) { target in
            SafariSheet(url: target.url, tint: theme.accent)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showPreview) {
            CardSharePreview(pages: pages, theme: theme, pageSize: pageSize, format: format)
                .environment(photos)
                .environment(invocation)
        }
    }

    private var gallerySheet: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                // บอกตั้งแต่เปิดตู้ ไม่ใช่รอให้เลือกจนจบแล้วค่อยปฏิเสธ — คนเลื่อนหาของในตู้นี้
                // เป็นนาที การให้เขาทำงานจนจบแล้วบอกว่า "ไม่ได้" คือการเสียเวลาที่กันได้ตั้งแต่ต้น
                if cardIsFull { galleryFullBanner }
                WidgetGallery(theme: theme.toolTheme, onAdd: { kind in
                    addWidget(kind)
                    showGallery = false
                }, onClose: { showGallery = false })
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .environment(photos)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        // ตู้ widget ก็ทึมมืดเช่นกัน — พรีวิวข้างในต้องเด่นกว่าฉากหลัง
        // เครื่องมือมืดเสมอ ไม่ว่าการ์ดจะใช้หมึกอะไร — ตาต้องแยกออกทันทีว่า
            // อะไรคือ "ชิ้นงานที่กำลังออกแบบ" อะไรคือ "ปุ่มที่ใช้ออกแบบมัน"
            // (แบบเดียวกับแคนวาสขาวบนหน้าจอมืดของ Figma)
            .environment(\.colorScheme, .dark)
            .presentationBackground {
                // `.ultraThinMaterial` อ่าน colorScheme ของ presentation ซึ่งตอนนี้ล้อหมึกของการ์ด
                // พอเลือกกระดาษ ชีตจะพลิกเป็นแผ่นขาว แล้วปุ่มทั้งแผงที่เขียนด้วยสีขาวหายไปกับพื้น
                // ความมืดของเครื่องมือจึงต้องทาเอง ไม่ฝากไว้กับ colorScheme
                Rectangle().fill(.ultraThinMaterial)
                    .overlay(Color(white: 0.07).opacity(theme.activeInk.isLight ? 0.86 : 0))
            }
    }

    @Environment(PhotoStore.self) private var photos
    @Environment(ClipInvocation.self) private var invocation

    // MARK: - Deck

    /// เพจเจอร์แบบเลื่อนภาพ — ดันซ้ายขวาเต็มความกว้าง ไม่มีการจางหาย
    ///
    /// ตัวที่ทำให้ไม่ใช่แค่ "สไลด์ธรรมดา" คือ **พารัลแลกซ์ในหน้า**:
    /// widget ข้างในเลื่อนช้ากว่าตัวหน้าเล็กน้อย และตัวที่กินเต็มความกว้างเลื่อนช้ากว่าตัวแคบ
    /// สมองจึงอ่านว่าเป็นชั้นลึกซ้อนกัน ไม่ใช่ภาพแบนแผ่นเดียวที่ถูกดันไปมา
    private func deck(size: CGSize, fit: CGFloat, viewport: CGSize) -> some View {
        let shown = CGSize(width: size.width * fit, height: size.height * fit)
        let inv: CGFloat = 1 / max(fit, 0.01)
        return ZStack {
            ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                let d = CGFloat(i) - (CGFloat(index) + swipe)
                // ระหว่างลากข้ามหน้า ต้องคงทุกหน้าไว้ในต้นไม้ view — ถ้าหน้าต้นทางถูกถอด
                // gesture recognizer ที่ถือการลากอยู่จะตายไปด้วย แล้วจะไม่มีวันได้ event ปล่อยนิ้ว
                if abs(d) < 1.35 || dragID != nil {
                    // `current` = หน้านี้คือหน้าปัจจุบัน (ใช้คุมการเข้าฉาก — ห้ามผูกกับ swipe)
                    // `interactive` = รับ touch ได้ (ปิดระหว่างปัด กันไปโดน widget)
                    sheet(page, size: size,
                          current: i == index,
                          // ระยะหน้า — ตัวขับท่าเข้า/ออกของทุก widget ให้สครับตามนิ้ว
                          dist: d,
                          interactive: i == index && abs(swipe) < 0.02,
                          // พารัลแลกซ์ต้องเป็นศูนย์ทั้งตอนอยู่กลางจอและตอนออกไปสุด
                          // ถ้าค้างค่าไว้ที่ปลาย หน้าที่ออกไปแล้วจะเลื่อนไม่พ้นจอ เหลือเศษค้างขอบ
                          parallax: d * max(0, 1 - abs(d)))
                        // บีบแนวนอนนิดหน่อยตอนถูกดันออก ให้รู้สึกว่ามีแรง ไม่ใช่แผ่นแข็ง
                        // (เคยเอียงหน้า 3 มิติด้วย แต่ 3D transform ทำให้ Liquid Glass
                        //  หยุด sample พื้นหลังแล้วตกเป็นแผ่นเข้มทั้งหน้าตลอดการปัด — ตัดทิ้ง)
                        .scaleEffect(x: 1 - abs(d) * 0.05, y: 1 - abs(d) * 0.08)
                        .offset(x: d * (size.width + 26))
                        .zIndex(Double(-abs(d)))
                        .allowsHitTesting(i == index)
                }
            }
        }
        // กรอบชั้นในเท่า **หน้า** พอดี ไม่ใช่เท่าพื้นที่ว่างทั้งก้อน
        //
        // ชั้นลอยข้างล่างอ้างมุมบนซ้ายของกรอบนี้ และ `dragStart` เป็นพิกัดในหน้ากระดาษ —
        // ถ้ามุมนี้ไม่ใช่มุมหน้า ตัวที่ลากจะลอยเยื้องจากนิ้ว
        .frame(width: size.width, height: size.height)
        .overlay(alignment: .topLeading) {
            // ชั้นลอยของตัวที่ลาก — อยู่ระดับ deck ไม่ผูกกับหน้าใดหน้าหนึ่ง จึงลอยข้ามหน้าได้
            if dragID != nil, let item = dragItem {
                dragLayer(Placed(item: item, frame: dragStart))
            }
        }
        // กริดกับฉากหลังอยู่ **ในหน่วยออกแบบเดียวกับ widget** จึงต้องอยู่ในก้อนที่ถูกย่อด้วย
        // ถ้าไปแขวนไว้ข้างนอก จุดกริดจะไม่ตรงกับขอบ widget ทันทีที่ fit ไม่ใช่ 1
        .background {
            // โชว์รูมเหลือของให้ดูชิ้นเดียว — กริดคือบริบทของ "ทั้งหน้า"
            // ปล่อยไว้แล้วมันจะชี้ไปยังผังที่ตอนนี้มองไม่เห็น
            if isEditing, showroomID == nil {
                CanvasGrid(theme: theme, ink: theme.inkStyle, page: size)
                    .frame(width: size.width, height: size.height)
            }
        }
        .background {
            // มุมและเงาถูกวาดในหน่วยออกแบบแล้วย่อลงพร้อมทั้งผืน — หารกลับด้วย fit
            // เพื่อให้ **ที่ตาเห็นบนจอ** คงที่ ไม่ใช่โตขึ้นตามพื้นที่ออกแบบ
            CardBackdrop(theme: theme, ignoreSafeArea: false)
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 22 * inv, style: .continuous))
                .shadow(color: .black.opacity(0.5), radius: 26 * inv, y: 12 * inv)
        }
        // ย่อพื้นที่ออกแบบทั้งผืนลงหน่วยจอ
        //
        // **ต้องยึดจุดกึ่งกลาง** ไม่ใช่ยึดหัว: `scaleEffect` ไม่แตะ layout ก้อนนี้จึงยังจองที่
        // เท่าหน่วยออกแบบ (540×960) แล้ว `.frame` บรรทัดถัดไปจัดมันไว้ *กึ่งกลาง* กรอบที่เล็กกว่า
        // ถ้าสเกลยึดหัว จุดอ้างอิงสองอันนี้จะคนละจุด แล้วการ์ดจะเลื่อนขึ้นไปพ้นกรอบของตัวเอง
        .scaleEffect(fit)
        // บอกขนาด **ที่ตาเห็น** เอง ไม่งั้นก้อนนี้ดันทุกอย่างรอบตัวออกนอกจอ
        .frame(width: shown.width, height: shown.height)
        // ชั้นนอกกินเต็มพื้นที่ เพื่อให้แตะที่ว่างรอบหน้าแล้วยกเลิกการเลือกได้
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        // หมึกของการ์ดครอบทั้งสำรับ — ทั้ง widget · เปลือกแผ่น · เส้นเลือก
        // ไม่ครอบไปถึงแถบเครื่องมือกับชีตแต่ง เพราะนั่นคือ "เครื่องมือ" ไม่ใช่ "ชิ้นงาน"
        // (แคนวาสขาวบนหน้าจอมืดแบบ Figma — ตาจะแยกออกทันทีว่าอะไรคืองาน อะไรคือปุ่ม)
        .environment(\.cardInk, theme.inkStyle)
        .simultaneousGesture(pageSwipe(width: size.width))
        // ในโชว์รูมพื้นหลังคือที่ว่างรอบชิ้นงาน ไม่ใช่ "ที่ว่างของหน้า" — แตะแล้วไม่ต้องยกเลิกการเลือก
        // แต่ถ้ากำลังพิมพ์อยู่ การแตะออกนอกชิ้นงานคือท่าปิดคีย์บอร์ดที่ทุกคนคาดหวัง
        .onTapGesture {
            guard isEditing else { return }
            if showroomID != nil {
                if Profile.me.editing != nil { endTextEdit() }
            } else {
                select(nil)
            }
        }
    }

    private func pageSwipe(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { g in
                // การ์ดหน้าเดียวไม่มีหน้าให้ไป — ถ้าไม่กันตรงนี้ การปัดจะได้แค่
                // หน่วงยางที่เด้งกลับ ซึ่งอ่านออกว่า "มีหน้าถัดไปแต่ไปไม่ได้"
                guard multiPage, dragID == nil, resizeID == nil else { return }
                guard abs(g.translation.width) > abs(g.translation.height) else { return }
                // หักระยะ dead zone ออก ไม่งั้นพอ gesture ติดครั้งแรกหน้าจะกระโดดไป 12pt ทันที
                let raw = -g.translation.width
                let dead: CGFloat = 12
                let adjusted = raw > 0 ? max(0, raw - dead) : min(0, raw + dead)
                var p = adjusted / max(width, 1)
                // หน่วงยางที่หน้าแรกและหน้าสุดท้าย
                if (index == 0 && p < 0) || (index == pages.count - 1 && p > 0) { p *= 0.32 }
                swipe = max(-1, min(1, p))
            }
            .onEnded { g in
                guard multiPage, dragID == nil, resizeID == nil else { swipe = 0; return }
                let velocity = -g.predictedEndTranslation.width / max(width, 1)
                let target = (swipe > 0.28 || velocity > 0.75) ? index + 1
                           : (swipe < -0.28 || velocity < -0.75) ? index - 1
                           : index
                let next = max(0, min(pages.count - 1, target))
                if next != index { Haptics.impact(.light) }
                withAnimation(Motion.page) {
                    index = next
                    swipe = 0
                }
            }
    }

    /// ขอบเขต A4 — ในโหมดดูไม่มีพื้นหลังของตัวเอง ทุกหน้าจึงลอยอยู่บนฉากหลังผืนเดียวกัน
    /// ถ้าใส่พื้นหลังให้แต่ละหน้า มันจะอ่านออกมาเป็น "แผ่นกระดาษหลายแผ่น" แทนที่จะเป็นงานชิ้นเดียว
    private func sheet(_ page: CardPage, size: CGSize, current: Bool, dist: CGFloat, interactive: Bool, parallax: CGFloat) -> some View {
        // `placed` คือผังของหน้าปัจจุบันที่หน่วงไว้ใน state — มีไว้เพื่อให้ "จัดเรียงใหม่"
        // (ลาก widget สลับที่ · เพิ่ม/ลบ) ไหลตามสปริงได้ เพราะ `resolve()` ถูกเรียกใน withAnimation
        //
        // แต่ตอน **เปลี่ยนหน้า** state ตัวนี้ยังเป็นผังของหน้าเดิมอยู่หนึ่งรอบ (resolve() วิ่งใน
        // onChange ซึ่งมาทีหลัง body) ถ้าเผลอใช้ หน้าใหม่จะถูกวาดด้วย id ของ widget หน้าเก่า
        // แล้วพอ resolve() ตามมา ForEach จะเห็น id เปลี่ยนยกชุด → SwiftUI รื้อ tile ทิ้งทั้งหน้า
        // → ท่าที่กำลังไหลอยู่ถูกยกเลิกหมด นี่คือเหตุผลที่ "ปล่อยนิ้วแล้วไม่ animate"
        //
        // จึงต้องเช็คเจ้าของผังก่อนเสมอ · ถ้าไม่ใช่ของหน้านี้ให้คำนวณสด ๆ ซึ่งได้ค่าเดียวกับที่
        // resolve() กำลังจะเซ็ตพอดี — id กับกรอบไม่ขยับ อนิเมชันจึงไหลต่อไม่สะดุด
        let solved = placedPage == page.id ? placed : PageLayout.solve(page.items, page: size)

        // หมายเหตุ: เคยครอบด้วย GlassEffectContainer เพื่อให้กระจกหลอมเชื่อมกัน
        // แต่มันแคชการวาดทั้งกลุ่ม พอ widget โดน transform 3D ตอนเปลี่ยนหน้า
        // เนื้อหาในกระจกจะหายไปเลย — จึงให้แต่ละชิ้นเป็นกระจกอิสระแทน
        return sheetBody(page, size: size, current: current, dist: dist,
                         interactive: interactive, parallax: parallax, solved: solved)
    }

    private func sheetBody(_ page: CardPage, size: CGSize, current: Bool, dist: CGFloat,
                           interactive: Bool, parallax: CGFloat, solved: [Placed]) -> some View {
        ZStack(alignment: .topLeading) {
            // ตัวยึดขนาดหน้า — ถ้าไม่มี ZStack จะมีขนาดเท่า widget ที่ใหญ่ที่สุด (เพราะ .offset ไม่นับเป็นขนาด)
            // แล้ว .frame ข้างล่างจะจัดก้อนเนื้อหาไว้กึ่งกลางแทนที่จะชิดมุมบนซ้ายของกระดาษ
            Color.clear.frame(width: size.width, height: size.height)

            if isEditing, showroomID == nil {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 0.8, dash: [5, 5]))
                    .foregroundStyle(theme.inkStyle.line(0.16))
                    .frame(width: size.width, height: size.height)
            }

            ForEach(solved) { p in
                tile(p, on: page, current: current, dist: dist, interactive: interactive,
                     parallax: parallax, pageWidth: size.width)
            }

            // กรอบเลือกอยู่ชั้นบนสุดของหน้า ไม่ใช่ติดไปกับตัว widget
            // ของทับกันได้แล้ว ถ้าวาดตามชั้นซ้อนจริง หมุดปรับขนาดจะถูกตัวที่อยู่หน้ากว่าทับจนกดไม่ได้
            if isEditing, current, dragID == nil,
               let sel = solved.first(where: { $0.id == selected }) {
                selectionLayer(sel, interactive: interactive)
                    // ยืดเฉพาะกรอบ ไม่แตะตัว widget — นี่คือ "ไปแค่กรอบ" ที่ตั้งใจ
                    .frame(width: sel.frame.width + (resizeID == sel.id ? overshoot.width : 0),
                           height: sel.frame.height + (resizeID == sel.id ? overshoot.height : 0),
                           alignment: .topLeading)
                    .background { contentProbe(sel) }
                    // กรอบเลือก/หมุด/ปุ่มประแจ ต้องถูกท่าโชว์รูมพาไปพร้อมตัว widget
                    // ไม่งั้นมันค้างอยู่ที่ตำแหน่งเดิมแล้วชี้ไปยังที่ว่าง
                    .scaleEffect(showroomScale(sel), anchor: .center)
                    .offset(x: sel.frame.minX - parallaxShift(sel.item, parallax: parallax,
                                                              pageWidth: size.width)
                               + showroom(sel).dx,
                            y: sel.frame.minY + showroom(sel).dy
                               + (showroomID == sel.id ? showroomDrag : 0))
                    .zIndex(500)
                    .animation(Motion.settle, value: showroomID)
            }
        }
        .frame(width: size.width, height: size.height)
        // พิกัดอ้างอิงของหมุดปรับขนาด — ต้องเป็นตัวที่ "ไม่ขยับตอน widget โต"
        // และอยู่ใต้ .scaleEffect ของแคนวาส เพื่อให้ระยะที่วัดได้เป็นหน่วยเดียวกับผัง
        .coordinateSpace(.named("page"))
    }

    /// widget ที่กินเต็มความกว้าง = ชั้นหลัง เลื่อนช้ากว่า · ตัวแคบ = ชั้นหน้า เลื่อนเร็วกว่า
    private func parallaxShift(_ item: WidgetInstance, parallax: CGFloat, pageWidth: CGFloat) -> CGFloat {
        parallax * pageWidth * (item.w >= pageWidth * 0.75 ? 0.22 : 0.52)
    }

    // MARK: - Tile

    @ViewBuilder
    private func tile(_ p: Placed, on page: CardPage, current: Bool, dist: CGFloat, interactive: Bool,
                      parallax: CGFloat, pageWidth: CGFloat) -> some View {
        let isSel = selected == p.id
        // ไม่ผูกกับ current — ระหว่างลากข้ามหน้า tile ต้นทางต้องซ่อนอยู่แม้หน้ามันไม่ใช่หน้าปัจจุบัน
        let isDrag = dragID == p.id
        let order = page.items.firstIndex { $0.id == p.id } ?? 0
        let touch = (pressPoint?.id == p.id && dragID == nil) ? pressPoint?.at : nil

        WidgetChrome(placed: p, theme: theme)
            .frame(width: p.frame.width, height: p.frame.height)
            // เส้นประรอบข้อความที่แก้ได้ขึ้นเฉพาะบนแคนวาสในโหมดแต่ง
            // พรีวิวในตู้ widget กับรูปที่เรนเดอร์ตอนแชร์อ่านค่าตั้งต้น false จึงสะอาดตามเดิม
            .environment(\.textEditMode, isEditing && interactive)
            // ส่งระยะหน้าลงไปให้ "ข้างใน" widget ด้วย — ตัวที่มีท่าเป็นของตัวเอง (เช่นบานเกล็ดของ
            // ผลงานที่ยืนยันแล้ว) จะเล่นจังหวะของมันเองแทนที่จะถูกกรอบลากไปทั้งแผ่น
            .environment(\.pageScrub, PageScrub(d: dist, order: order,
                                                flat: p.item.surface == .glass))
            .pressTilt(touch, size: p.frame.size, glow: theme.accent)
            .overlay {
                // คง catcher ไว้ขณะที่มันถือการลากอยู่ — หลัง flip หน้า interactive ของหน้าต้นทาง
                // กลายเป็น false ถ้าถอดตรงนี้ recognizer ตายกลาง gesture แล้ว event ปล่อยนิ้วหาย
                if interactive || dragID == p.id {
                    PressDragCatcher(
                        // ในโชว์รูมชิ้นงานลากย้ายที่ไม่ได้ (ผังถูกซ่อนอยู่) — ท่าลากจึงว่าง
                        // เอามาใช้เป็นทางออก: ลากลงคือเก็บของกลับเข้าที่ ภาษาเดียวกับการปัดชีตลง
                        onBegan: {
                            let inShowroom = showroomID == p.id
                            pressMode = (p.id, inShowroom)
                            if inShowroom {
                                // กดค้างบนชิ้นที่กำลังแต่งอยู่ = จะลากเก็บ ไม่ใช่จะพิมพ์ — หุบคีย์บอร์ดก่อน
                                if Profile.me.editing != nil { endTextEdit() }
                                showroomDrag = 0
                            } else {
                                beginDrag(p)
                            }
                        },
                        onChanged: { t in
                            if pressMode?.id == p.id, pressMode?.showroom == true {
                                // ลากขึ้นหนืดกว่าลากลงสามเท่า — ทางออกมีทางเดียวคือลง
                                showroomDrag = t.height > 0 ? t.height : t.height / 3
                                return
                            }
                            guard dragID == p.id else { return }
                            // นิ้ววัดบนจอ แต่หน้าแสดงแบบย่อ — หารสเกลให้ widget วิ่งเท่านิ้วจริง
                            let s = max(canvasScale, 0.01)
                            let scaled = CGSize(width: t.width / s, height: t.height / s)
                            dragTranslation = scaled
                            hover(p)
                            checkEdgeFlip(p, scaled)
                        },
                        onEnded: {
                            let mode = pressMode
                            if mode?.id == p.id { pressMode = nil }
                            if mode?.id == p.id, mode?.showroom == true {
                                let far = showroomDrag > 70
                                withAnimation(Motion.settle) { showroomDrag = 0 }
                                if far { closeTools() }
                                return
                            }
                            endDrag(p)
                        },
                        onTap: { at in
                            // โหมดดู = การ์ดทำตัวเป็นการ์ดจริง — แตะช่องโซเชียลไปหน้าโปรไฟล์
                            // แตะผลงานไปโพสต์นั้น · แตะที่ว่างไม่ทำอะไร (ยังไม่ใช่โหมดแต่ง)
                            guard isEditing else {
                                if let url = linkBox.hit(at, in: p.item.id) { open(url) }
                                return
                            }
                            // **สามชั้น ชั้นละความตั้งใจ** — บนตัว widget ทำได้แค่สองชั้นแรก
                            //
                            // 1. แตะ = โฟกัส (ได้กรอบ + หมุดปรับขนาด + ปุ่มประแจ) · กดค้าง = ลากย้าย
                            // 2. กดประแจ = เข้าเครื่องมือ (โชว์รูม) — ตรงนี้เท่านั้นที่ข้อความแก้ได้
                            //
                            // ที่ต้องแยกเพราะการ์ดหนึ่งหน้ามีข้อความเต็มไปหมด ถ้าแตะข้อความแล้วพิมพ์ได้
                            // ตั้งแต่ชั้นโฟกัส คีย์บอร์ดจะเด้งขึ้นทุกครั้งที่ผู้ใช้แค่จะเลือกหรือจะลาก
                            // แล้วสองท่าที่ใช้บ่อยที่สุดก็ใช้ไม่ได้ทั้งคู่
                            guard showroomID == p.id else {
                                select(p.id)
                                return
                            }
                            // ในโชว์รูม: แตะกรอบเส้นประ = พิมพ์ช่องนั้น · แตะที่ว่าง = ปิดคีย์บอร์ด
                            // (ปิดแค่คีย์บอร์ด ยังอยู่ในเครื่องมือ — ออกจากเครื่องมือคือลากชิ้นงานลง)
                            if let hit = slotBox.hit(at, in: p.item.id) {
                                beginTextEdit(hit, on: p)
                            } else if Profile.me.editing != nil {
                                endTextEdit()
                            }
                        },
                        onPress: { at in
                            if let at { pressPoint = (p.id, at) }
                            else if pressPoint?.id == p.id { pressPoint = nil }
                        }
                    )
                }
            }
            .overlay { if isEditing, !isSel { editHairline(p) } }
            // ปุ่มเปลี่ยนรูปอยู่บนตัวรูปเลย — "รูปนี้แก้ได้" ต้องอ่านออกจากตัวรูป ไม่ใช่ไปงมในชีตล่าง
            // วางทับ catcher จึงกินทัชก่อน แตะปุ่มแล้วไม่กลายเป็นลาก widget
            //
            // **เฉพาะตัวที่ถูกเลือก** — ปุ่มพวกนี้นับตามช่องรูป ไม่ใช่ตามชิ้น เบนโตะใบเดียวมีสี่ช่อง
            // ก็ได้สี่ชุด · เปิดพร้อมกันทั้งหน้าแปลว่าจังหวะที่ครีเอเตอร์กำลังตัดสินว่าหน้านี้สวยหรือยัง
            // คือจังหวะเดียวกับที่ของซึ่งเขาจะตัดสินถูกปิดอยู่ · กติกาเดียวกับปุ่มประแจ (ดู `toolButton`)
            .overlayPreferenceValue(PhotoSlotKey.self) { slots in
                if isEditing, interactive, isSel, !slots.isEmpty {
                    photoSlotButtons(slots, on: p)
                }
            }
            // กรอบลิงก์ไม่ได้วาดอะไรเลย มีหน้าที่เดียวคือจำพิกัดไว้ให้ `onTap` ใช้ตัดสิน
            // (จำเฉพาะหน้าที่นิ้วแตะได้จริง — หน้าอื่นเก็บไปก็ไม่มีใครถาม)
            .overlayPreferenceValue(LinkSlotKey.self) { slots in
                if interactive { linkSlotLayer(slots, on: p) }
            }
            // ช่องพิมพ์ต้องอยู่เหนือ catcher เหมือนปุ่มเปลี่ยนรูป ไม่งั้นเคอร์เซอร์/การเลือกข้อความกดไม่ติด
            .overlayPreferenceValue(TextSlotKey.self) { slots in
                if isEditing, interactive {
                    textSlotLayer(slots, on: p, focused: showroomID == p.id)
                }
            }
            .opacity(isDrag ? 0 : 1)
            .pageChoreo(p.item.kind, order, d: dist, flat: p.item.surface == .glass)
            // โชว์รูม: ตัวที่กำลังแต่งถูกยกขึ้นกลางจอ · ที่เหลือถอยออกแล้วละลายหายไป
            // หรี่ด้วย opacity + ย่อ ไม่ใช่ถอดออกจากต้นไม้ view — ผังต้องนิ่งอยู่ที่เดิม
            // ไม่งั้นพอปิดชีต ของทั้งหน้าจะกระโดดกลับมาแทนที่จะไหลกลับ
            .scaleEffect(showroomScale(p), anchor: .center)
            .opacity(showroomDim(p))
            .blur(radius: showroomID != nil && showroomID != p.id ? 4 : 0)
            // ตัวที่ถูกหรี่หายในโชว์รูมยังอยู่ในต้นไม้ view (ผังต้องนิ่ง) — แต่ต้องไม่รับทัช
            // ไม่งั้นแตะที่ว่างรอบชิ้นงานแล้วไปโดนตัวที่มองไม่เห็นซึ่งบังเอิญวางทับอยู่ตรงนั้น
            .allowsHitTesting(showroomID == nil || showroomID == p.id)
            .offset(x: p.frame.minX - parallaxShift(p.item, parallax: parallax, pageWidth: pageWidth)
                       + showroom(p).dx,
                    y: p.frame.minY + showroom(p).dy
                       + (showroomID == p.id ? showroomDrag : 0))
            // ลำดับในลิสต์คือชั้นซ้อนจริง — ห้ามยกตัวที่เลือกขึ้นหน้า
            // ไม่งั้นกดปุ่มสลับชั้นแล้วจะไม่เห็นอะไรเกิดขึ้นเลยตอนมันยังถูกเลือกอยู่
            // ยกเว้นในโชว์รูม ซึ่งตัวที่แต่งอยู่ต้องอยู่หน้าสุดตามนิยาม
            .zIndex(showroomID == p.id ? 400 : Double(order))
            .animation(Motion.settle, value: showroomID)
    }

    /// ตัวที่กำลังแต่งขยายขึ้น · ตัวอื่นถอยลงเล็กน้อยให้อ่านเป็น "ถอยออกไปข้างหลัง"
    private func showroomScale(_ p: Placed) -> CGFloat {
        guard let id = showroomID else { return 1 }
        return id == p.id ? showroom(p).scale : 0.92
    }

    private func showroomDim(_ p: Placed) -> Double {
        guard let id = showroomID else { return 1 }
        return id == p.id ? 1 : 0
    }

    /// ปุ่มเปลี่ยนรูปหนึ่งปุ่มต่อหนึ่งช่องรูป — อ่านตำแหน่งช่องจาก anchor ที่ตัว widget ประกาศไว้
    ///
    /// วาดที่ชั้นนี้แทนที่จะให้ widget ใส่ปุ่มเอง เพราะเนื้อหา widget ถูกปิด hit testing ทั้งก้อน
    /// (รูปแบบ .fill ล้นกรอบ ถ้าเปิดทัชไว้มันจะไปแย่งทัชของ widget ข้างเคียง)
    private func photoSlotButtons(_ slots: [PhotoSlotAnchor], on p: Placed) -> some View {
        // เรียงตามตำแหน่งบนหน้าจอ — บนลงล่าง ซ้ายไปขวา
        // ลำดับนี้คือลำดับที่รูปจะไหลลงช่องเวลาผู้ใช้เลือกมาทีเดียวหลายใบ
        GeometryReader { geo in
            let sorted = slots.sorted {
                let a = geo[$0.bounds], b = geo[$1.bounds]
                return a.minY == b.minY ? a.minX < b.minX : a.minY < b.minY
            }
            let order = sorted.map(\.index)
            ForEach(sorted, id: \.index) { slot in
                let r = geo[slot.bounds]
                // ช่องที่กำลังจัดกรอบอยู่เปลี่ยนเป็นแผ่นลางทับทั้งช่อง — ปุ่มหายไปชั่วคราว
                // เพราะโหมดนี้มีอยู่ท่าเดียวคือ "เล็งรูป" ปุ่มอื่นในจังหวะนั้นคือของที่ไม่มีใครกด
                if photos.framing == PhotoSlotRef(widget: p.item.id, slot: slot.index) {
                    PhotoFitSurface(theme: theme, widgetID: p.item.id,
                                    slot: slot.index, size: r.size)
                        .frame(width: r.width, height: r.height)
                        .position(x: r.midX, y: r.midY)
                } else {
                    // ป้ายใต้ปุ่มกินความกว้างราว 130pt ทั้งแถว — ช่องที่แคบกว่านั้นให้เหลือแค่ไอคอน
                    PhotoSlotButton(theme: theme, widgetID: p.item.id, slot: slot.index,
                                    order: order, labelled: r.width >= 132)
                        // ชิดขวาบนของช่อง — คู่ปุ่ม (เปลี่ยน + ถอย) จึงงอกไปทางซ้าย ไม่ล้นออกนอกรูป
                        // .frame ไม่กินทัชในพื้นที่ว่าง ทัชนอกตัวปุ่มจึงตกไปถึง catcher ตามเดิม
                        .padding(5)
                        .frame(width: r.width, height: r.height, alignment: .topTrailing)
                        .position(x: r.midX, y: r.midY)
                }
            }
        }
    }

    /// เปิดลิงก์ — ในแอปเป็นค่าตั้งต้น ออกนอกแอปเฉพาะที่เปิดในแอปไม่ได้
    ///
    /// `SFSafariViewController` รับเฉพาะ http/https · สคีมอื่น (deep link ของแอป) ต้องส่งให้ระบบ
    /// ไม่งั้นมันจะ crash ตอนสร้าง ไม่ใช่แค่เปิดไม่ขึ้น
    private func open(_ url: URL) {
        switch url.scheme?.lowercased() {
        case "http", "https": link = LinkTarget(url: url)
        default:              openURL(url)
        }
    }

    /// ชั้นที่ "จำ" กรอบลิงก์ของ widget หนึ่งตัว — ไม่วาดอะไรและไม่กินทัช
    ///
    /// ต้องแปลง anchor เป็นพิกัดจริงที่ชั้นนี้ เพราะ `onTap` ให้พิกัดในระบบเดียวกับ tile
    /// ส่วนตัวลิงก์เองอยู่ลึกหลายชั้นในตัว widget ซึ่งปิด hit testing ไว้ทั้งก้อน
    private func linkSlotLayer(_ slots: [LinkSlotAnchor], on p: Placed) -> some View {
        GeometryReader { geo in
            let resolved = slots.map { LinkSlotRect(url: $0.url, rect: geo[$0.bounds]) }
            Color.clear
                .onChange(of: resolved, initial: true) { _, new in
                    linkBox.rects[p.item.id] = new
                }
        }
        .allowsHitTesting(false)
    }

    /// ชั้นข้อความที่แก้ได้ของ widget หนึ่งตัว
    ///
    /// ทำสองอย่าง: จำกรอบของทุกช่องไว้ให้ตัวจับทัชใช้ · วางช่องพิมพ์จริงทับช่องที่กำลังแก้อยู่
    /// ตัวเส้นประไม่ได้วาดที่นี่ — มันอยู่ติดกับตัวอักษรในตัว widget เอง จึงล้อขนาดจริงของข้อความ
    private func textSlotLayer(_ slots: [TextSlotAnchor], on p: Placed,
                               focused: Bool) -> some View {
        GeometryReader { geo in
            let resolved = slots.map {
                TextSlotRect(id: $0.id, rect: geo[$0.bounds], style: $0.style)
            }
            let active = resolved.first { $0.id == Profile.me.editing }
            ZStack {
                // เส้นประรอบทุกช่องที่ยังไม่ได้แก้ — ภาษาเดียวกับ template ของ CapCut
                // ดันออกนอกตัวอักษร 3pt ให้กรอบไม่ทับหางสระ แล้วยังไม่กินพื้นที่ผังเพราะอยู่คนละชั้น
                // เส้นประขึ้น **เฉพาะตัวที่อยู่ในโชว์รูม** ไม่ใช่ทุกตัวในโหมดแต่ง และไม่ใช่ตัวที่แค่ถูกเลือก
                //
                // เคยขึ้นทั้งหน้าเพื่อบอกว่า "อันไหนแก้ได้บ้าง" แล้วพบว่าหน้าหนึ่งมีข้อความสิบกว่าก้อน
                // เส้นประเต็มไปหมดจนอ่านไม่ออกว่าตอนนี้กดอะไรได้ · แล้วเคยขึ้นตอนแค่เลือก ซึ่งก็ยังโกหก
                // เพราะชั้นโฟกัสแตะข้อความแล้วไม่มีอะไรเกิดขึ้น (พิมพ์ได้เฉพาะในเครื่องมือ)
                //
                // ผูกกับโชว์รูมแล้วเส้นประแปลว่า "แตะได้เดี๋ยวนี้" ตรง ๆ — ตรงกับสิ่งที่กดแล้วเกิดขึ้นจริง
                if focused {
                    ForEach(resolved.filter { $0.id != active?.id }, id: \.id) { slot in
                        TextSlotDashes(style: slot.style, accent: theme.accent)
                            .frame(width: slot.rect.width + 6, height: slot.rect.height + 6)
                            .position(x: slot.rect.midX, y: slot.rect.midY)
                    }
                }

                // ช่องที่กำลังพิมพ์ — กรอบทึบ + พื้นจาง บอกว่าตัวอักษรที่วิ่งอยู่คือก้อนนี้
                // (ตัวพิมพ์จริงอยู่บนแถบเหนือคีย์บอร์ด ที่นี่เหลือแค่ "ชี้ว่าอันไหน")
                if let active {
                    ZStack {
                        RoundedRectangle(cornerRadius: active.style.corner + 3, style: .continuous)
                            .fill(theme.accent.opacity(0.18))
                        RoundedRectangle(cornerRadius: active.style.corner + 3, style: .continuous)
                            .strokeBorder(theme.accent, lineWidth: 1.2)
                    }
                    .frame(width: active.rect.width + 8, height: active.rect.height + 8)
                    .position(x: active.rect.midX, y: active.rect.midY)
                    .allowsHitTesting(false)
                }
            }
            .onChange(of: resolved, initial: true) { _, new in
                slotBox.rects[p.item.id] = new
            }
        }
    }

    /// เส้นบาง ๆ บอกขอบเขตของทุกตัวในโหมดแต่ง — ตัวที่ถูกเลือกใช้กรอบเต็มในชั้นบนแทน
    /// กรอบประจำชิ้นในโหมดแต่ง — **เส้นประ ไม่ใช่เส้นจาง**
    ///
    /// ของเดิมเป็นเส้นทึบ 0.7pt ที่ opacity 0.07–0.14 ซึ่งบนพื้นการ์ดจริงแทบมองไม่เห็น
    /// ผลคือโหมดแต่งกับโหมดดูหน้าตาเหมือนกันทุกประการ · เส้นประอ่านออกทันทีว่า
    /// "นี่คือขอบของชิ้นงาน" ไม่ใช่เส้นตกแต่ง และไม่ไปแข่งกับกรอบทึบของตัวที่ถูกเลือกอยู่
    private func editHairline(_ p: Placed) -> some View {
        RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
            .strokeBorder(theme.accent.opacity(editReveal ? 0.85 : 0.42),
                          style: StrokeStyle(lineWidth: editReveal ? 1.4 : 1,
                                             dash: [4.5, 3.5]))
            .allowsHitTesting(false)
    }

    /// กรอบเลือก + หมุดปรับขนาด — วาดที่ชั้นบนสุดของหน้า จึงไม่ถูก widget ที่ทับอยู่กลืน
    private func selectionLayer(_ p: Placed, interactive: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
        return ZStack {
            shape.strokeBorder(theme.accent, lineWidth: 1.5)
            shape.strokeBorder(theme.accent.opacity(0.18), lineWidth: 7).blur(radius: 5)
                .matchedGeometryEffect(id: "selectionGlow", in: selectionNS)
            ForEach(0..<4, id: \.self) { i in
                Circle().fill(.white).frame(width: 8, height: 8)
                    .overlay(Circle().strokeBorder(theme.accent, lineWidth: 1.6))
                    .shadow(color: .black.opacity(0.4), radius: 3)
                    .position(x: i % 2 == 0 ? 0 : p.frame.width,
                              y: i < 2 ? 0 : p.frame.height)
            }
        }
        .frame(width: p.frame.width, height: p.frame.height)
        // ปิดทัชแค่ตัวกรอบ — หมุดที่ครอบทีหลังยังกดได้ตามปกติ
        .allowsHitTesting(false)
        .overlay(alignment: .trailing) {
            if interactive, p.item.kind.canResizeWidth { widthHandle(p) }
        }
        .overlay(alignment: .bottom) {
            if interactive, p.item.kind.canResizeHeight { heightHandle(p) }
        }
        // ปุ่มประแจ — ทางเข้าเดียวของแผงเครื่องมือ
        //
        // อยู่บนตัว widget ไม่ใช่ในแถบบน เพราะมันคือคำสั่งที่มีเป้าหมายชัดเจน ("แต่งตัวนี้")
        // ปุ่มในแถบบนต้องอธิบายเองว่าหมายถึงตัวไหน ส่วนปุ่มที่เกาะอยู่กับของไม่ต้องอธิบายเลย
        //
        // มุมขวาล่าง: มุมขวาบนเป็นที่ของปุ่มเปลี่ยนรูปแล้ว และหมุดปรับขนาดอยู่กึ่งกลางขอบ
        .overlay(alignment: .bottomTrailing) {
            if interactive, showroomID == nil { toolButton() }
        }
    }

    /// ปุ่มเข้าแผงเครื่องมือของชิ้นที่เลือก — **มีคำ ไม่ใช่ไอคอนเปล่า**
    ///
    /// ของเดิมเป็นวงกลมรูปประแจ ซึ่งอ่านไม่ออกว่าทำอะไร (ตอนเทสมีคนอ่านว่า
    /// "เครื่องมือช่าง ฟังดูน่ากลัว" แล้วไม่กล้ากด) ไอคอนตัวนี้ไม่มีความหมายที่ใครรู้ร่วมกัน
    /// ต่างจากลูกศรย้อนกลับหรือรูปถ่าย จึงต้องมีคำกำกับ ไม่ใช่หวังให้เดาถูก
    ///
    /// ย้ายลงมาห้อยใต้กรอบด้วย — ของเดิมนั่งคร่อมมุมกรอบพอดี ทัชที่พลาดขอบปุ่มจึงตกไปโดน
    /// ชิ้นที่อยู่ข้างล่างแทน กลายเป็น "กดประแจแล้วการเลือกกระโดดไปชิ้นอื่น"
    private func toolButton() -> some View {
        Button(action: openTools) {
            HStack(spacing: 4) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("แต่งชิ้นนี้").font(.sh(10, .semibold))
            }
            .foregroundStyle(.black.opacity(0.88))
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(Capsule().fill(LinearGradient(
                colors: [theme.accentSoft, theme.accent],
                startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(Capsule().strokeBorder(.white.opacity(0.32), lineWidth: 0.6))
            .shadow(color: .black.opacity(0.42), radius: 7, y: 3)
        }
        .buttonStyle(.plain)
        // ห้อยพ้นขอบล่างทั้งตัว — ไม่ทับเนื้อหา ไม่คร่อมขอบ และเยื้องขวาพ้นหมุดปรับความสูง
        // ที่อยู่กึ่งกลางขอบล่าง
        .offset(x: 6, y: 22)
        .transition(.scale.combined(with: .opacity))
    }

    private func dragLayer(_ p: Placed) -> some View {
        WidgetChrome(placed: p, theme: theme)
            .frame(width: p.frame.width, height: p.frame.height)
            .scaleEffect(lifted ? 1.05 : 1.0)
            .shadow(color: .black.opacity(lifted ? 0.55 : 0), radius: lifted ? 30 : 0, y: lifted ? 16 : 0)
            .overlay {
                RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                    .strokeBorder(theme.accent, lineWidth: 1.5)
            }
            .offset(x: dragStart.minX + dragTranslation.width,
                    y: dragStart.minY + dragTranslation.height)
            .allowsHitTesting(false)
            .zIndex(200)
    }

    // MARK: - State

    /// เขียนงานกลับใบในคลัง — เรียกทุกครั้งที่ผัง/ธีม/หน้าเปลี่ยน
    /// เบามากเพราะเป็นก้อนเล็ก ไม่ต้อง debounce · คลิปไม่มีใบให้เขียน (`cardID` ว่าง) จึงเงียบไปเอง
    private func persist() {
        guard let cardID else { return }
        CardLibrary.shared.save(id: cardID, pages: pages, theme: theme, index: index)
    }

    private func resolve() {
        guard let page = current else { placed = []; placedPage = nil; return }
        placed = PageLayout.solve(layoutItems(page), page: pageSize, first: dragID)
        placedPage = page.id
    }

    /// รายการที่ใช้คำนวณผัง
    ///
    /// ระหว่างลาก ตัวที่ถูกจับจะถูก **ย้ายไปช่องที่นิ้วชี้อยู่ก่อน** แล้วค่อยคำนวณผัง
    /// ผลคือตัวอื่นถูกดันหลบ *ระหว่างที่นิ้วยังอยู่* ไม่ใช่รอปล่อยแล้วค่อยกระโดด
    ///
    /// ข้อมูลจริง (`pages`) ไม่ถูกแตะเลยจนกว่าจะปล่อยนิ้ว — ลากแล้วเปลี่ยนใจ
    /// ยกนิ้วออกนอกหน้า ทุกอย่างกลับที่เดิมเองโดยไม่ต้อง undo
    private func layoutItems(_ page: CardPage) -> [WidgetInstance] {
        guard let dragID, let at = dragOrigin,
              let i = page.items.firstIndex(where: { $0.id == dragID }) else { return page.items }
        var items = page.items
        items[i].x = at.x
        items[i].y = at.y
        if let w = dragWidth { items[i].w = w }
        return items
    }

    /// หาช่องที่นิ้วชี้อยู่ แล้วคอมมิตเมื่อค้างครบเวลา
    ///
    /// หน่วง 170ms ก่อนคอมมิตเพราะถ้าขยับผังทุกครั้งที่ข้ามเส้นกริด การลากผ่านการ์ด
    /// เร็ว ๆ ทีเดียวจะทำให้ทั้งหน้ากระตุกสะบัดตามทุกช่องที่ผ่าน — ผู้ใช้อ่านไม่ทันและรู้สึกพัง
    /// ช่องปลายทางที่นิ้วชี้อยู่ **ณ วินาทีนี้** — คำนวณสด ไม่พึ่งค่าที่คอมมิตไว้
    ///
    /// ใช้ทั้งตอนลาก (ผ่าน `hover` ซึ่งหน่วงก่อนคอมมิต) และตอนปล่อยนิ้ว (ใช้ตรง ๆ)
    /// สองที่ต้องคิดด้วยสูตรเดียวกัน ไม่งั้นสิ่งที่ตาเห็นตอนลากกับที่ได้ตอนปล่อยจะไม่ตรงกัน
    private func target(_ p: Placed) -> CGRect? {
        guard pageSize.width > 0, let page = current else { return nil }
        // คิดจาก "ความกว้างจริงตอนนี้" ไม่ใช่ความกว้างเดิม ไม่งั้นตัวที่ถูกย่อไปแล้ว
        // จะถูกรูดกลับไปชิดซ้ายทุกครั้งที่ขยับนิ้ว
        let liveW = dragWidth ?? p.item.w
        let at = PageLayout.snap(CGPoint(x: dragStart.minX + dragTranslation.width,
                                         y: dragStart.minY + dragTranslation.height))
        var r = PageLayout.clamp(CGRect(origin: at,
                                        size: CGSize(width: liveW, height: p.item.h)),
                                 page: pageSize)

        // ที่ว่างตรงนี้แคบกว่าตัวเอง → ย่อให้พอดีที่ แทนที่จะถูกดันลงไปข้างล่าง
        // นี่คือสิ่งที่ทำให้ "ลากไปแทรกข้าง ๆ ตัวที่ย่อไว้" ทำได้จริง
        let room = PageLayout.freeWidth(from: r.minX, y: r.minY, height: r.height,
                                        page: pageSize, avoiding: page.items, excluding: p.id)
        if room >= PageLayout.minSize.width {
            r.size.width = min(p.item.w, max(PageLayout.minSize.width, PageLayout.snap(room)))
        }
        return PageLayout.clamp(r, page: pageSize)
    }

    /// ช่องว่างขั้นต่ำระหว่างการจัดผังใหม่สองครั้งระหว่างลาก
    ///
    /// ไม่ใช่ "หน่วงก่อนทำ" แต่เป็น "อย่าทำถี่กว่านี้" — ต่างกันทั้งความรู้สึกและผลลัพธ์ (ดู `hover`)
    /// 0.07 วิ = ~14 ครั้ง/วินาที ซึ่งเร็วกว่าที่ตาจับได้ว่าเป็นขั้น แต่ช้าพอให้สปริงเดินจบท่า
    private static let reflowGap: TimeInterval = 0.07

    /// เปิดที่ให้ของที่กำลังลาก — **ระหว่างที่นิ้วยังไม่ปล่อย**
    ///
    /// # บั๊กเดิม: ตัวจับเวลาที่ไม่มีวันครบ
    ///
    /// ของเดิมหน่วง 170ms ก่อนคอมมิต และ **ยกเลิกนัดเดิมทิ้งทุกครั้งที่นิ้วขยับ**
    /// (`reflow?.cancel()` แล้วตั้งใหม่) ซึ่งแปลว่าผังจะขยับก็ต่อเมื่อนิ้ว *หยุดนิ่งสนิท* 170ms
    /// — นิ้วจริงไม่เคยนิ่งขนาดนั้น recognizer ยิง `.changed` ทุกไม่กี่มิลลิวินาที
    /// ผลคือ **ไม่มีอะไรหลบให้เลยตลอดการลาก** แล้วทุกอย่างไปกระโดดเข้าที่ตอนปล่อยนิ้วทีเดียว
    /// ซึ่งตรงข้ามกับที่ต้องการพอดี (และเป็นเหตุผลเดียวที่ยังอ่านออกมาว่า "มันไม่ reorder ให้")
    ///
    /// # กติกาใหม่: throttle ไม่ใช่ debounce
    ///
    /// นัดแรกได้ทำทันที (หรือรอจนครบช่องว่างจากครั้งก่อน) แล้ว **ห้ามยกเลิกนัดที่ตั้งไว้แล้ว** —
    /// นัดที่ตั้งไว้จะอ่านตำแหน่งนิ้ว *สด ๆ ตอนมันทำงาน* ไม่ใช่ค่าที่จับไว้ตอนตั้งนัด
    /// จึงไม่มีทางค้าง และไม่มีทางกระตุกถี่เกินสปริงจะตามทัน
    ///
    /// นี่คือพฤติกรรมเดียวกับหน้าโฮมของ iOS: ไอคอนหลบให้ *ตอนนิ้วยังอยู่* ช่องว่างเดินตามนิ้วไปเรื่อย ๆ
    /// และตำแหน่งสุดท้ายคือสิ่งที่เห็นอยู่แล้วก่อนปล่อย ไม่ใช่ผลลัพธ์ที่เพิ่งมารู้ตอนยกนิ้ว
    private func hover(_ p: Placed) {
        guard dragID == p.id, let t = target(p) else { return }

        // ตรงกับที่คอมมิตไปแล้ว — ไม่มีอะไรต้องขยับ
        if let d = dragOrigin, abs(d.x - t.minX) < 0.5, abs(d.y - t.minY) < 0.5,
           abs((dragWidth ?? p.item.w) - t.width) < 0.5 {
            return
        }
        // มีนัดที่ยังไม่ถึงคิว — ปล่อยให้มันเดิน (มันจะอ่านช่องล่าสุดเองตอนทำงาน)
        guard reflow == nil else { return }

        let wait = max(0, Self.reflowGap - (Date().timeIntervalSinceReferenceDate - lastReflow))
        let work = DispatchWorkItem {
            reflow = nil
            // อ่านช่องปลายทาง **ตอนนี้** ไม่ใช่ตอนตั้งนัด — นิ้วเดินต่อไปแล้วระหว่างรอคิว
            guard dragID == p.id, let now = target(p) else { return }
            lastReflow = Date().timeIntervalSinceReferenceDate
            // สปริงตอบไว (snap) ไม่ใช่ flow — ของที่หลบให้ต้องไปถึงที่ก่อนนิ้วจะเดินต่อ
            // ไม่งั้นช่องว่างจะรั้งอยู่หลังนิ้วจนอ่านเป็น "ระบบตามไม่ทัน"
            withAnimation(Motion.snap) {
                dragOrigin = now.origin
                dragWidth = now.width
                resolve()
            }
        }
        reflow = work
        DispatchQueue.main.asyncAfter(deadline: .now() + wait, execute: work)
    }

    /// เริ่มพิมพ์ช่องหนึ่ง — เรียกได้เฉพาะตอนอยู่ในโชว์รูมของ widget ตัวนั้น
    ///
    /// **ไม่แตะ `showTools`** ชีตจะหลบให้คีย์บอร์ดเองผ่าน `showsToolSheet` โดยเจตนายังค้างอยู่
    /// นี่คือสิ่งที่ทำให้กด เสร็จ แล้วได้เครื่องมือคืน แทนที่จะหลุดออกมาทั้งชั้น
    private func beginTextEdit(_ slot: TextSlotRect, on p: Placed) {
        guard showroomID == p.id else { return }
        guard Profile.me.editing != slot.id else { return }
        // ย้ายไปช่องใหม่ต้องเก็บค่าช่องเดิมก่อนเสมอ — แต่ปล่อยคีย์บอร์ดค้างไว้ ไม่ต้องหุบ
        commitTextEdit()
        withAnimation(Motion.settle) { Profile.me.editing = slot.id }
        Haptics.impact(.light)
    }

    /// ปิดช่องพิมพ์แล้วเก็บค่า — เรียกได้ซ้ำโดยไม่มีผลข้างเคียง
    /// ปิดช่องพิมพ์แล้วเก็บค่า **พร้อมหุบคีย์บอร์ด** — ใช้กับทุกทางออกที่ไม่ได้ไปแก้ช่องอื่นต่อ
    private func endTextEdit() {
        // การถอด `UITextView` ออกจากลำดับชั้น **ไม่ได้แปลว่าคีย์บอร์ดจะหุบ** — UIKit ยังถือ
        // ตัวมันเป็น first responder ต่อจนกว่าจะมีใครสั่ง จึงเห็นคีย์บอร์ดค้างทับการ์ดทั้งที่
        // ช่องพิมพ์หายไปแล้ว · สั่งที่ระดับแอปเพราะถึงตรงนี้เราไม่มีตัวอ้างอิงไปถึง view นั้นแล้ว
        //
        // สั่งไว้นอก guard ด้วย: คีย์บอร์ดที่ค้างอยู่ต้องหุบแม้ในเฟรมที่ไม่มีช่องไหนถูกแก้อยู่แล้ว
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
        commitTextEdit()
    }

    /// เก็บค่าช่องที่แก้อยู่โดย **ไม่แตะคีย์บอร์ด** — ใช้ตอนย้ายไปแก้ช่องอื่นต่อ
    /// ถ้าสั่งหุบตรงนี้ด้วย คีย์บอร์ดจะกระพริบลงแล้วขึ้นใหม่ทุกครั้งที่เปลี่ยนช่อง
    private func commitTextEdit() {
        guard let id = Profile.me.editing else { return }
        // อยู่ในบล็อกอนิเมชันเพราะการเคลียร์ค่านี้คือสิ่งที่พาชีตเครื่องมือกลับขึ้นมา
        // และพาโชว์รูมกลับไปยืนกลางช่องว่างที่คีย์บอร์ดเพิ่งคืนให้
        withAnimation(Motion.settle) { Profile.me.editing = nil }
        Profile.me.commit(id)
    }

    private func select(_ id: UUID?) {
        // แตะที่อื่นเมื่อไหร่คือจบการพิมพ์ — อยู่ก่อน guard เพราะแตะข้อความอีกช่องบน widget ตัวเดิม
        // จะไม่เปลี่ยนตัวที่เลือก แต่ยังต้องเก็บค่าของช่องเดิมก่อนย้ายไปช่องใหม่
        endTextEdit()
        // เลือกตัวอื่นคือจบการเล็งรูปด้วย — แผ่นลากที่ค้างอยู่บน widget ตัวเก่าจะกินทัชต่อไปเรื่อย ๆ
        photos.framing = nil
        guard selected != id else { return }
        withAnimation(Motion.snap) { selected = id }
        // **เลือกแล้วไม่เปิดชีต** — เลือกกับแต่งเป็นคนละความตั้งใจ
        //
        // เดิมเลือกปุ๊บชีตขึ้นปั๊บ ผลคือทุกครั้งที่แค่อยากลาก/ย้าย/แตะข้อความ ชีตก็เด้งมาบังครึ่งจอ
        // แล้วแคนวาสถูกย่อ+ดันขึ้นตามไปด้วย ทั้งที่ยังไม่ได้จะแต่งอะไรเลย
        // ตอนนี้ต้องกดปุ่มประแจบนตัว widget ถึงจะเข้าโหมดแต่ง — ดู `toolButton`
        if id != nil { Haptics.impact(.light) }
    }

    /// ปิดแผงเครื่องมือ — ของทั้งหน้าไหลกลับเข้าที่ ตัวที่เลือกยังเลือกอยู่
    private func closeTools() {
        endTextEdit()
        withAnimation(Motion.settle) { showTools = false }
        Haptics.impact(.light)
    }

    /// เปิดแผงเครื่องมือของ widget ที่เลือกอยู่ พร้อมเข้าโหมดโชว์รูม
    private func openTools() {
        endTextEdit()
        sheetDetent = SheetStop.normal
        withAnimation(Motion.settle) { showTools = true }
        Haptics.impact(.medium)
    }

    /// หยิบของออกจากตู้ → หา **หน้าที่ยังมีที่ว่างจริง** ให้มัน
    ///
    /// # ทำไมไม่วางลงหน้าที่เปิดอยู่เสมอ
    ///
    /// หน้าหนึ่งมี 6×36 ช่อง และหน้าตั้งต้นหน้าแรกใช้ครบ 36 แถวพอดี — ของชิ้นถัดไปที่ลงหน้านั้น
    /// จึงไม่มีที่ให้ยืนจริง ๆ `PageLayout.solve` เลยตกไปถึงทางออกสุดท้ายของมัน คือ
    /// **ยอมให้ทับกันที่ก้นหน้า** (ดีกว่าดันหลุดออกนอกหน้าซึ่งพิมพ์ไม่ติด)
    ///
    /// ผลที่ผู้ใช้เห็นคือ "วิดเจ็ตทับกันได้" กับ "ลากแล้วไม่มีอะไรหลบให้" — ซึ่งทั้งคู่ไม่ใช่กติกา
    /// แต่เป็นอาการของหน้าที่เต็มแล้ว · ตัวผังไม่ผิด สิ่งที่ผิดคือการยัดของลงหน้าที่ไม่มีที่
    ///
    /// ตอนนี้จึงไล่หาหน้าที่รับได้ (หน้าปัจจุบันก่อน แล้ววนไปหน้าถัดไป) แล้วพาผู้ใช้ไปหน้านั้น
    /// ไม่มีหน้าไหนรับได้เลยก็ **เปิดหน้าใหม่** — พอร์ตที่ของล้นหน้าคือพอร์ตที่ต้องมีหน้าเพิ่ม
    /// ไม่ใช่พอร์ตที่ต้องเอาของมากองทับกัน
    private func addWidget(_ kind: WidgetKind) {
        guard pages.indices.contains(index) else { return }
        var w = WidgetInstance(kind)

        // ไล่จากหน้าที่เปิดอยู่ → ท้ายเล่ม → วนกลับมาหน้าแรก
        let order = Array(index..<pages.count) + Array(0..<index)
        var dest: Int? = nil
        for p in order {
            guard let at = PageLayout.freeSpot(size: CGSize(width: w.w, height: w.h),
                                               page: pageSize,
                                               avoiding: pages[p].items) else { continue }
            w.x = at.x
            w.y = at.y
            dest = p
            break
        }

        // ไม่มีที่เต็มขนาด และเปิดหน้าใหม่ไม่ได้ — **ย่อให้พอดีที่ว่าง** ก่อนจะยอมแพ้
        //
        // บนการ์ดหน้าเดียว การปฏิเสธคือทางตัน: ผู้ใช้ต้องเดาเองว่าต้องรื้ออะไรออกก่อน
        // ทั้งที่ช่องว่างมีอยู่จริง แค่เตี้ยกว่า "ขนาดที่พอดีสวย" ของชิ้นนั้น
        // ซึ่งเป็นค่าที่ตั้งมาสำหรับหน้าที่มีเพื่อนแค่สองสามชิ้น ไม่ใช่ห้าชิ้น
        //
        // ย่อได้ถึง 60% ของความสูงตั้งต้น — ต่ำกว่านั้นได้เศษ ไม่ใช่ของที่อ่านออก
        // และย่อลงหน้าที่ **กำลังดูอยู่** เท่านั้น เพราะขนาดเต็มถูกลองครบทุกหน้าไปแล้วข้างบน
        var shrunk = false
        if dest == nil, pages.count >= format.pageCount {
            let floor = max(PageLayout.minSize.height, PageLayout.snap(w.h * 0.6))
            var h = w.h - PageLayout.step
            while h >= floor {
                if let at = PageLayout.freeSpot(size: CGSize(width: w.w, height: h),
                                                page: pageSize,
                                                avoiding: pages[index].items) {
                    w.h = h
                    w.x = at.x
                    w.y = at.y
                    dest = index
                    shrunk = true
                    break
                }
                h -= PageLayout.step
            }
        }

        // ย่อสุดแล้วยังไม่ลง = **บอกว่าเต็ม** ไม่ใช่แอบเปิดหน้าใหม่
        //
        // สตอรี่มีหน้าเดียวตามนิยาม ส่วนพอร์ตส่งออกแค่ 3 หน้า (ดู `CardExport`) —
        // หน้าที่ 4 จึงเป็นหน้าที่แต่งได้แต่ไม่มีวันถูกแชร์ ซึ่งแย่กว่าการถูกปฏิเสธตรง ๆ
        guard dest != nil || pages.count < format.pageCount else {
            // ค้างไว้จนกดปิด ไม่ใช่จางหายเอง — นี่คือการบอกว่า "สิ่งที่คุณเพิ่งสั่งไม่เกิดขึ้น"
            // ซึ่งเป็นข้อความที่ผู้ใช้ต้องได้อ่านแน่ ๆ ไม่ใช่ได้อ่านถ้าบังเอิญมองอยู่ตอนนั้น
            warn(format.pageCount == 1
                 ? "เพิ่มไม่ได้ · หน้าเต็มแล้ว — ย่อหรือเอาของออกก่อน"
                 : "เพิ่ม\(kind.title)ไม่ได้ · ครบ \(format.pageCount) หน้าและเต็มทุกหน้าแล้ว")
            return
        }

        withAnimation(Motion.flow) {
            if let d = dest {
                // ต่อท้ายลิสต์ = ได้สิทธิ์ที่นั่งทีหลังสุดเวลาชนกัน ของใหม่จึงเป็นฝ่ายหลบ
                pages[d].items.append(w)
                if d != index { index = d }
            } else {
                w.x = PageLayout.margin
                w.y = PageLayout.margin
                pages.append(CardPage([w]))
                index = pages.count - 1
            }
        }
        // เลือกทีหลังหนึ่งรอบ — เปลี่ยนหน้าทำให้ `onChange(of: index)` ล้างการเลือกทิ้ง
        // ถ้าสั่งเลือกในรอบเดียวกัน ของใหม่จะโผล่มาแบบไม่ถูกเลือกทุกครั้งที่มันไปอยู่คนละหน้า
        DispatchQueue.main.async { select(w.id) }
        Haptics.impact(.medium)
        // ของที่โผล่มาเล็กกว่าที่เห็นในตู้ต้องมีคำอธิบาย ไม่งั้นอ่านเป็น "แอปวางผิด"
        if shrunk { flash("ที่ว่างไม่พอขนาดเต็ม — ย่อให้พอดีแล้ว ลากขอบปรับต่อได้") }
    }

    // MARK: - Drag

    private func beginDrag(_ p: Placed) {
        // คลิปเป็นตัวเปิดการ์ด — กดค้างแล้วห้ามหลุดเข้าโหมดแต่ง
        if viewOnly { return }
        endTextEdit()
        // กดค้างจากโหมดดู = เข้าโหมดแต่งแล้วลากต่อได้ทันที (แบบ home screen ของ iOS)
        // ชีตขึ้นแบบหุบเป็นแถบเตี้ย ๆ — แคนวาสยังใหญ่เกือบเต็ม
        if !isEditing {
            withAnimation(Motion.settle) { isEditing = true }
            sheetDetent = SheetStop.compact
        }
        guard dragID == nil, let live = placed.first(where: { $0.id == p.id }) else { return }
        select(p.id)
        withAnimation(Motion.snap) { swipe = 0 }
        dragID = p.id
        dragItem = p.item
        dragOriginPage = index
        dragStart = live.frame
        dragGripX = (pressPoint?.id == p.id ? pressPoint?.at.x : nil) ?? live.frame.width / 2
        dragTranslation = .zero
        // เริ่มที่ตำแหน่งเดิมของมันเอง ผังจึงไม่ขยับตอนยกขึ้น
        dragOrigin = CGPoint(x: p.item.x, y: p.item.y)
        dragWidth = p.item.w
        Haptics.impact(.medium)
        withAnimation(Motion.lift) { lifted = true }
    }

    private func endDrag(_ p: Placed) {
        guard dragID == p.id else { return }
        edgeFlip?.cancel(); edgeFlip = nil
        reflow?.cancel(); reflow = nil

        // ปล่อยนอกพื้นที่หน้า (เหนือชีต/พ้นขอบ) = วางไม่ได้ — เด้งกลับบ้านเดิม
        let finger = CGPoint(x: dragStart.midX + dragTranslation.width,
                             y: dragStart.midY + dragTranslation.height)
        let slack: CGFloat = 40
        guard finger.x > -slack, finger.x < pageSize.width + slack,
              finger.y > -slack, finger.y < pageSize.height + slack else {
            bounceBack(p)
            return
        }

        // **คำนวณสดตอนปล่อย ไม่ใช่ใช้ค่าที่คอมมิตไว้**
        //
        // ค่าที่คอมมิตมาจาก `hover` ซึ่งหน่วง 170ms ก่อนเซ็ต ถ้าผู้ใช้ลากแล้วปล่อยเร็วกว่านั้น
        // งานที่รออยู่จะถูกยกเลิกใน `endDrag` แล้ว `dragSlot` ยังเป็นช่อง**เดิมตอนยกขึ้น**
        // ผลคือของเด้งกลับที่เดิมทุกครั้งที่ลากเร็ว ซึ่งอ่านออกมาเป็น "วางไม่ติด"
        let drop = target(p) ?? PageLayout.clamp(p.item.rect, page: pageSize)

        // ปล่อยนิ้วบนหน้าอื่นที่ไม่ใช่หน้าต้นทาง — ย้าย item จริงตอนนี้ ต่อท้าย = ขึ้นชั้นบนสุด
        if let src = pages.firstIndex(where: { pg in pg.items.contains { $0.id == p.id } }),
           src != index, pages.indices.contains(index),
           let i = pages[src].items.firstIndex(where: { $0.id == p.id }) {
            let item = pages[src].items.remove(at: i)
            pages[index].items.append(item)
        }

        Haptics.impact(.medium)
        withAnimation(Motion.settle) {
            lifted = false
            dragID = nil
            dragItem = nil
            dragTranslation = .zero
            if let i = pages[index].items.firstIndex(where: { $0.id == p.id }) {
                pages[index].items[i].x = drop.minX
                pages[index].items[i].y = drop.minY
                // ความกว้างที่ถูกย่อให้พอดีที่คือความกว้างที่ผู้ใช้เห็นตอนปล่อย — เก็บไว้จริง
                pages[index].items[i].w = drop.width
            }
            // **คอมมิตผังทั้งหน้าให้ตรงกับที่ตาเห็นตอนปล่อย**
            //
            // ระหว่างลาก ตัวที่นิ้วจับได้สิทธิ์ก่อนใคร (`first:`) ตัวอื่นจึงหลบขึ้น/ลงให้เห็น ๆ
            // แต่ถ้าปล่อยแล้วไม่เขียนอะไรลงข้อมูล รอบคำนวณถัดไปจะไม่มี `first:` อีกแล้ว
            // ลำดับกลับไปตัดสินด้วย "แถวน้อยกว่าได้ก่อน" แล้วของที่เพิ่งลากขึ้นไปวางข้างบน
            // ก็ถูกดันกลับลงมาที่เดิมทันทีที่ยกนิ้ว — คือ "ลากสลับที่กันไม่ได้" ที่เห็นกันอยู่
            //
            // เขียนช่องที่ทุกตัว *ได้จริง* กลับลงไป ผลลัพธ์บนจอกับข้อมูลจึงเป็นเรื่องเดียวกัน
            // และรอดข้ามการเปิดแอปด้วย (ผังที่จำได้ต้องเป็นผังที่เห็น ไม่ใช่ผังก่อนถูกดัน)
            let settled = PageLayout.slots(pages[index].items, page: pageSize, first: p.id)
            for (id, r) in settled {
                guard let i = pages[index].items.firstIndex(where: { $0.id == id }) else { continue }
                pages[index].items[i].x = r.minX
                pages[index].items[i].y = r.minY
            }
            dragOrigin = nil
            dragWidth = nil
        }
    }

    /// วางไม่ได้ — คืนของกลับตำแหน่งเดิม แล้วให้ชั้นลอย "สปริงเด้งกลับ" ไปที่บ้านของมัน
    /// ค้าง dragID ไว้จนสปริงจบ ไม่งั้นชั้นลอยหายวับแทนที่จะเห็นมันบินกลับ
    private func bounceBack(_ p: Placed) {
        reflow?.cancel(); reflow = nil
        dragOrigin = nil
        dragWidth = nil
        // ตอนนี้การลากไม่แตะข้อมูลเลยจนกว่าจะปล่อย — ของยังอยู่บ้านเดิมอยู่แล้ว
        // ผังที่ถูกดันไว้ระหว่างลากก็คลายกลับเองเมื่อ `dragSlot` ถูกล้าง
        // เหลือแค่พาหน้ากลับ ถ้าลากข้ามหน้าไปแล้ว
        if index != dragOriginPage, pages.indices.contains(dragOriginPage) {
            withAnimation(Motion.page) { index = dragOriginPage; swipe = 0 }
        }
        Haptics.rigid()

        withAnimation(.interpolatingSpring(stiffness: 320, damping: 18)) {
            dragTranslation = .zero
            lifted = false
        }
        // รอสปริงเข้าที่ก่อนค่อยสลับชั้นลอยเป็น tile จริง — สลับก่อนจะเห็นวูบ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            guard dragID == p.id else { return }
            dragID = nil
            dragItem = nil
        }
    }

    /// ลากค้างที่ขอบขวา = ไปหน้าถัดไป · ขอบซ้าย = หน้าก่อนหน้า
    /// หน่วง 0.35 วิ กันสลับหน้าโดยไม่ตั้งใจตอนลากผ่านขอบเฉย ๆ
    private func checkEdgeFlip(_ p: Placed, _ t: CGSize) {
        let x = dragStart.minX + dragGripX + t.width
        let margin: CGFloat = 30
        let dir: Int? = x > pageSize.width - margin ? 1 : (x < margin ? -1 : nil)
        guard let dir, pages.indices.contains(index + dir) else {
            edgeFlip?.cancel(); edgeFlip = nil
            return
        }
        guard edgeFlip == nil else { return }
        let work = DispatchWorkItem { flipPage(p, by: dir) }
        edgeFlip = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    /// สลับหน้าที่แสดงระหว่างลาก — ห้ามย้ายข้อมูลตอนนี้เด็ดขาด
    /// ถ้าย้าย item ออกจากหน้าเดิม tile ต้นทาง (ที่ถือ gesture การลากอยู่) จะถูกถอดจากต้นไม้ view
    /// แล้ว event ปล่อยนิ้วจะไม่มีวันมาถึง — การย้ายจริงเกิดตอน endDrag เท่านั้น
    private func flipPage(_ p: Placed, by dir: Int) {
        edgeFlip = nil
        let target = index + dir
        guard dragID == p.id, pages.indices.contains(target) else { return }

        // หน้าปลายทางไม่มีที่ว่างพอสำหรับชิ้นนี้ = **ห้ามข้ามไป**
        //
        // ถ้าปล่อยให้ข้าม พอปล่อยนิ้ว `endDrag` จะย้ายของจริงเข้าไป แล้วผังของหน้านั้น
        // ก็ตกไปถึงทางออกสุดท้าย (ทับกันที่ก้นหน้า) ซึ่งผู้ใช้ไม่ได้สั่งและมองไม่เห็นว่าเกิดอะไร
        // สั่นแบบปฏิเสธแทน — บอกว่า "มันไปไม่ได้" ดีกว่าพาไปแล้วพัง
        let size = CGSize(width: dragWidth ?? p.item.w, height: p.item.h)
        guard PageLayout.freeSpot(size: size, page: pageSize,
                                  avoiding: pages[target].items) != nil else {
            Haptics.rigid()
            return
        }

        withAnimation(Motion.page) {
            index = target
            swipe = 0
        }
        Haptics.impact(.medium)
    }

    /// แถวต่ำสุดที่เนื้อหาของตัวนี้ยังไม่เละ
    ///
    /// # ทำไมวัดแทนที่จะตั้งเป็นตัวเลข
    ///
    /// ค่าที่ตั้งด้วยมือผิดเสมอ — ตั้งสูงไปผู้ใช้ย่อไม่ได้ ตั้งต่ำไปเนื้อหาถูกตัด
    /// และพอแก้เนื้อหาใน widget ทีหลัง ตัวเลขที่ตั้งไว้ก็ไม่ตามไปด้วย (เพิ่งเจอกับ `ผู้ติดตาม`)
    ///
    /// ตัวนี้วัดความสูงที่เนื้อหา *ขอ* จริงตอนไม่ถูกบีบ แล้วคืนเป็น pt ตรง ๆ
    ///
    /// widget ที่วางผังด้วย `GeometryReader` (รูป · กริด · แถบวิ่ง) จะขอความสูงน้อยมาก
    /// เพราะมันยืดหดตามกรอบได้อยู่แล้ว — ซึ่งถูกต้อง พวกนี้ควรย่อได้ลึกกว่าตัวที่เป็นตัวหนังสือ
    private func minHeight(for p: Placed) -> CGFloat {
        guard let h = contentH, h > 1 else { return PageLayout.minSize.height }
        let inset: CGFloat = p.item.kind.isFullBleed || !p.item.border ? 0 : 12
        let need = PageLayout.snap((h + inset * 2).rounded(.up))
        return min(max(need, PageLayout.minSize.height),
                   PageLayout.content(pageSize).height)
    }

    /// สำเนาที่ซ่อนไว้สำหรับวัดความสูงของเนื้อหา — วัดเฉพาะตัวที่เลือกอยู่ตัวเดียว
    /// (วัดทุกตัวตลอดเวลาแปลว่าวาด widget ซ้ำสองชุดทั้งหน้า ซึ่งไม่คุ้ม)
    private func contentProbe(_ p: Placed) -> some View {
        let inset: CGFloat = p.item.kind.isFullBleed || !p.item.border ? 0 : 12
        let w = max(1, p.frame.width - inset * 2)
        return WidgetBody(kind: p.item.kind, theme: theme,
                          size: CGSize(width: w, height: 2000))
            .frame(width: w)
            .fixedSize(horizontal: false, vertical: true)
            .hidden()
            .allowsHitTesting(false)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { h in
                contentH = h
            }
    }

    /// แรงต้านตอนลากเลยขีด — ยิ่งลากไกลยิ่งขยับน้อยลง แล้วตันที่ ~26pt
    /// สูตรเดียวกับ overscroll ของ UIScrollView: ผู้ใช้รู้ทันทีว่า "ยังลากได้ แต่ไม่ไปแล้ว"
    private func rubber(_ d: CGFloat) -> CGFloat {
        let cap: CGFloat = 26
        return (1 - 1 / (abs(d) / cap + 1)) * cap * (d < 0 ? -1 : 1)
    }

    // MARK: - Handles

    /// เลิกโหมดยืดขนาด — เรียกซ้ำได้ ไม่มีผลข้างเคียง
    ///
    /// `onEnded` ของ `DragGesture` **ไม่ถูกเรียกถ้า view ที่ถือ gesture ถูกถอดกลางคัน** —
    /// กด เสร็จ ด้วยอีกนิ้ว · เลือกตัวอื่น · ตัวที่ยืดอยู่ถูกลบ ล้วนถอดกรอบเลือกทิ้งทั้งชั้น
    /// แล้ว `resizeID` ค้าง ซึ่งบล็อกการปัดเปลี่ยนหน้า และทำให้การยืดครั้งถัดไปอ่านค่าตั้งต้นผิด
    /// (มันเห็นว่าตัวเองยืดอยู่แล้วเลยไม่จับค่าเริ่มต้นใหม่) · จึงล้างจากทางออกทุกทาง ไม่ใช่แค่ปล่อยนิ้ว
    private func endResize() {
        guard resizeID != nil else { return }
        resizeID = nil
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) { overshoot = .zero }
    }

    private func widthHandle(_ p: Placed) -> some View {
        HandleGrip(theme: theme, axis: .horizontal)
            // นั่งนอกกรอบ ไม่ใช่คร่อมขอบ — ดูเหตุผลที่ `HandleGrip`
            .offset(x: 11)
            .gesture(
                // วัดใน space ของหน้า ไม่ใช่ของหมุด — หมุดเกาะขอบขวาของตัวที่กำลังยืด
                // พอความกว้างเปลี่ยน หมุดขยับตาม ระยะลากใน local space จะถูกหักออกเท่านั้นพอดี
                // กลายเป็นวงป้อนกลับ โต→ระยะลดลงต่ำกว่าเกณฑ์→หด→ระยะเด้งขึ้น→โต วนไม่จบ
                // (.global ก็ใช้ไม่ได้ เพราะแคนวาสถูก .scaleEffect ย่อในโหมดแต่ง หน่วยจะไม่ตรงกับผัง)
                DragGesture(minimumDistance: 1, coordinateSpace: .named("page"))
                    .onChanged { g in
                        guard let i = pages[index].items.firstIndex(where: { $0.id == p.id }) else { return }
                        if resizeID != p.id {
                            resizeID = p.id
                            resizeW = pages[index].items[i].w
                            resizeScale = max(showroomScale(p), 0.01)
                        }
                        // เพดานคือขอบขวาของหน้า — ยืดเลยขอบไปก็ไม่มีที่ให้วาด
                        let room = PageLayout.roomWidth(from: pages[index].items[i].x, page: pageSize)
                        let want = resizeW + g.translation.width / resizeScale
                        let cur = pages[index].items[i].w
                        // ฮิสเทอรีซิส — ต้องลากพ้นครึ่งขั้นไปอีกหน่อยจึงเปลี่ยน
                        // กันนิ้วสั่นคาเส้นแบ่งแล้วขนาดวูบไปมา
                        guard abs(want - cur) > PageLayout.step * 0.6 else { return }
                        let next = PageLayout.snap(min(max(want, PageLayout.minSize.width), room))
                        if abs(next - cur) > 0.5 {
                            pages[index].items[i].w = next
                            Haptics.impact(.light)
                        }
                        // ลากเลยขีดแล้ว — ให้ "กรอบ" ยืดตามนิ้วแบบหนืด ตัว widget ไม่ขยับ
                        // ผู้ใช้จึงรู้ว่าสุดแล้วจากแรงต้าน ไม่ใช่จากการที่จู่ ๆ นิ้วไม่มีผล
                        let over = want - next
                        overshoot.width = abs(over) < 0.5 ? 0 : rubber(over)
                    }
                    .onEnded { _ in
                        endResize()
                        Haptics.impact(.medium)
                    }
            )
    }

    private func heightHandle(_ p: Placed) -> some View {
        HandleGrip(theme: theme, axis: .vertical)
            .offset(y: 11)
            .gesture(
                // ดูเหตุผลที่ใช้ space ของหน้าใน `widthHandle`
                DragGesture(minimumDistance: 1, coordinateSpace: .named("page"))
                    .onChanged { g in
                        guard let i = pages[index].items.firstIndex(where: { $0.id == p.id }) else { return }
                        if resizeID != p.id {
                            resizeID = p.id
                            resizeH = pages[index].items[i].h
                            resizeScale = max(showroomScale(p), 0.01)
                        }
                        let room = PageLayout.roomHeight(from: pages[index].items[i].y, page: pageSize)
                        let want = resizeH + g.translation.height / resizeScale
                        let cur = pages[index].items[i].h
                        guard abs(want - cur) > PageLayout.step * 0.6 else { return }
                        // เพดานล่างมาจาก **ความสูงที่เนื้อหาขอจริง** ไม่ใช่ตัวเลขที่ตั้งด้วยมือ
                        // ย่อต่ำกว่านี้เมื่อไหร่เนื้อหาถูกตัด ซึ่งเป็นสิ่งที่ผู้ใช้ไม่ควรทำได้โดยบังเอิญ
                        let floor = minHeight(for: p)
                        let next = PageLayout.snap(min(max(want, floor), room))
                        if abs(next - cur) > 0.5 {
                            pages[index].items[i].h = next
                            Haptics.impact(.light)
                        }
                        let over = want - next
                        overshoot.height = abs(over) < 0.5 ? 0 : rubber(over)
                    }
                    .onEnded { _ in
                        endResize()
                        Haptics.impact(.medium)
                    }
            )
    }

    // MARK: - Chrome

    private var topBar: some View {
        VStack {
            GlassEffectContainer(spacing: 14) {
                HStack(spacing: 10) {
                    if viewOnly {
                        shareButton
                    } else {
                        // ทางกลับไปเลือกแบบ — โผล่เฉพาะตอนไม่ได้แต่งอยู่
                        //
                        // ระหว่างแต่งมีของค้างมือเสมอ (ตัวที่เลือก · ชีต · คีย์บอร์ด)
                        // ปุ่มพาออกจากทั้งหน้าจอที่นั่งอยู่ข้าง ๆ ปุ่ม "เสร็จ" คือปุ่มที่รอถูกกดผิด
                        if !isEditing, let onChangeFormat {
                            Button {
                                Haptics.impact(.light)
                                // ดูเฉย ๆ แล้วออก = ไม่เกิดการ์ด — คลังเก็บเฉพาะของที่ตั้งใจทำ
                                if discardIfUntouched, !touched, let cardID {
                                    CardLibrary.shared.delete(cardID)
                                }
                                onChangeFormat()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(width: 30, height: 22)
                            }
                            .buttonStyle(.glass)
                            .accessibilityLabel("เปลี่ยนแบบการ์ด")
                        }

                        // แต่ง — ซ้ายบน · ทางเข้าชีตควบคุมล่าง
                        Button {
                            withAnimation(Motion.settle) {
                                isEditing.toggle()
                                if !isEditing {
                                    endTextEdit()
                                    photos.framing = nil
                                    selected = nil
                                    showTools = false
                                }
                            }
                            Haptics.impact(.medium)
                        } label: {
                            Text(isEditing ? "เสร็จ" : "แต่ง")
                                .font(.sh(13, .semibold)).frame(minWidth: 34)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(theme.accent)

                        if isEditing { toolsButton }
                    }

                    Spacer()

                    if viewOnly {
                        Button {
                            showHire = true
                            Haptics.impact(.medium)
                        } label: {
                            Text("คุยงาน")
                                .font(.sh(13, .semibold)).frame(minWidth: 34)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(theme.accent)
                    } else {
                        shareButton
                        // เพิ่ม widget — ขวาบน · เปิดตู้อย่างเดียว ไม่เด้งชีตแต่ง
                        Button {
                            endTextEdit()
                            selected = nil
                            clearNotice()
                            // เข้าโหมดแต่งไปเลย — ของที่เพิ่งเพิ่มจะโผล่มาพร้อมหมุดและถูกเลือกไว้
                            // เพิ่มจากโหมดดูแล้วมันจะลงไปเงียบ ๆ โดยไม่มีอะไรบนจอเปลี่ยนสักอย่าง
                            // (`addWidget` สั่ง `select` ไว้แล้ว แต่การเลือกมองเห็นได้เฉพาะตอนแต่ง)
                            if !isEditing { withAnimation(Motion.settle) { isEditing = true } }
                            showGallery = true
                            Haptics.impact(.light)
                        } label: {
                            // SF Symbol ตรง ๆ — SHIcon เป็น asset ของแบรนด์ ไม่มี glyph บวก
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(width: 34, height: 22)
                        }
                        .buttonStyle(.glass)
                        .accessibilityLabel("เพิ่ม widget")
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
            }
            .padding(.horizontal, 15).padding(.top, 4)
            Spacer()
        }
    }

    /// สวิตช์ชีตเครื่องมือ — ติดสีเมื่อเปิด เพราะมันเป็นปุ่มค้างสถานะ ไม่ใช่ปุ่มสั่งงานครั้งเดียว
    @ViewBuilder
    private var toolsButton: some View {
        let btn = Button {
            showGallery = false
            endTextEdit()
            withAnimation(Motion.settle) {
                showTools.toggle()
                // ปิดแล้วต้องไม่เหลือชีตค้างเพราะ widget ที่เลือกไว้ — ปุ่มนี้คือสวิตช์ของชีตทั้งใบ
                selected = nil
            }
            if showTools { sheetDetent = fittingDetent }
            Haptics.impact(.light)
        } label: {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 34, height: 22)
        }
        .accessibilityLabel("เครื่องมือแต่งการ์ด")

        if showTools {
            btn.buttonStyle(.glassProminent).tint(theme.accent)
        } else {
            btn.buttonStyle(.glass)
        }
    }

    /// เปิดหน้าตัวอย่าง 3 หน้าต่อกัน แล้วค่อยแชร์รูปหรือคัดลอกลิงก์
    private var shareButton: some View {
        Button {
            // ชีตแต่งถ้าเปิดค้างจะบัง fullScreenCover — หุบก่อนแล้วค่อยพาไปหน้าตัวอย่าง
            if isEditing {
                endTextEdit()
                photos.framing = nil
                withAnimation(Motion.settle) {
                    isEditing = false
                    selected = nil
                    showTools = false
                }
            }
            showPreview = true
            Haptics.impact(.light)
        } label: {
            Text("แชร์")
                .font(.sh(13, .semibold)).frame(minWidth: 34)
        }
        .buttonStyle(.glass)
        .accessibilityLabel("แชร์การ์ด")
    }

    /// แถบบอกหน้า — แตะกระโดดข้ามหน้าได้ ไม่ต้องปัดทีละหน้า
    /// แถบข้อความชั่วคราวเหนือขอบล่าง — ไม่รับสัมผัส และหายเองใน 2.4 วิ
    @ViewBuilder
    private var noticeBar: some View {
        if let n = notice {
            VStack {
                Spacer(minLength: 0)
                HStack(spacing: 12) {
                    Text(n.text)
                        .font(.sh(12.5, .semibold))
                        .foregroundStyle(.white.opacity(0.94))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let title = n.actionTitle, let act = n.action {
                        Button {
                            clearNotice()
                            act()
                        } label: {
                            Text(title).font(.sh(12.5, .bold))
                                .foregroundStyle(theme.rawAccent)
                        }
                        .buttonStyle(.plain)
                    } else if n.kind == .warning {
                        Button { clearNotice() } label: {
                            Image(systemName: "xmark").font(.sh(10, .bold))
                                .foregroundStyle(.white.opacity(0.55))
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.black.opacity(0.72)))
                .padding(.horizontal, 24)
                .padding(.bottom, multiPage ? 40 : 22)
                // ข้อความบอกสถานะต้องไม่ขวางการ์ดที่อยู่ข้างหลัง · ส่วนสองชนิดที่มีปุ่ม
                // ต้องรับทัชได้ ไม่งั้นปุ่มที่วาดไว้ก็กดไม่ได้
                .allowsHitTesting(n.kind != .status)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    /// บอกสถานะ — หายเอง ไม่ต้องให้ใครปิด
    private func flash(_ text: String) {
        show(CardNotice(text: text, kind: .status), seconds: 3.2)
    }

    /// **คำสั่งถูกปฏิเสธ** — ค้างจนผู้ใช้ปิดเอง
    ///
    /// ของแบบนี้ห้ามหายเอง: ผู้ใช้เพิ่งกดอะไรบางอย่างแล้วมันไม่เกิดขึ้น สายตายังอยู่ที่ชีตที่กำลังปิด
    /// ข้อความที่จางหายไปใน 3 วินาทีจึงพลาดได้ง่ายมาก แล้วเขาจะสรุปว่าแอปพัง ไม่ใช่ว่าการ์ดเต็ม
    private func warn(_ text: String) {
        Haptics.rigid()
        show(CardNotice(text: text, kind: .warning), seconds: nil)
    }

    /// ยื่นทางกลับให้หนึ่งทาง — ใช้กับของที่ทำไปแล้วและกู้คืนได้
    private func offer(_ text: String, _ title: String, _ act: @escaping () -> Void) {
        show(CardNotice(text: text, kind: .offer, actionTitle: title, action: act), seconds: 5)
    }

    /// สอนท่าให้ครั้งเดียวในชีวิต — ค้างจนกดรับทราบ
    ///
    /// มีเพราะปุ่มบนช่องรูปถูกย้ายไปโผล่เฉพาะตอนที่ชิ้นนั้นถูกเลือก · ไม่มีอะไรมาแทน
    /// ก็เท่ากับย้ายปัญหาจาก "ปุ่มบังรูป" ไปเป็น "หาปุ่มไม่เจอ" ซึ่งไม่ได้ดีขึ้นเลย
    ///
    /// ตั้งธงว่าเห็นแล้วตั้งแต่ตอนขึ้น ไม่ใช่ตอนกดรับทราบ — คนที่ปัดผ่านไปเลยแปลว่าเขาไม่ต้องการ
    /// การเอามาขึ้นซ้ำทุกครั้งที่เข้าโหมดแต่งคือการไม่ฟังคำตอบนั้น
    private func hintOnce(_ key: String, _ text: String) {
        let flag = "starcard.hint.\(key)"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        UserDefaults.standard.set(true, forKey: flag)
        show(CardNotice(text: text, kind: .offer, actionTitle: "เข้าใจแล้ว") {}, seconds: nil)
    }

    private func show(_ n: CardNotice, seconds: Double?) {
        noticeClear?.cancel()
        withAnimation(Motion.snap) { notice = n }
        guard let seconds else { noticeClear = nil; return }
        let work = DispatchWorkItem { withAnimation(Motion.snap) { notice = nil } }
        noticeClear = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func clearNotice() {
        noticeClear?.cancel()
        noticeClear = nil
        withAnimation(Motion.snap) { notice = nil }
    }

    private var pageRail: some View {
        VStack {
            Spacer()
            HStack(spacing: 6) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { i, _ in
                    Capsule()
                        .fill(i == index ? theme.accent : Color.white.opacity(0.22))
                        .frame(width: i == index ? 22 : 7, height: 7)
                        .onTapGesture {
                            withAnimation(Motion.page) { index = i }
                        }
                }
                Text("\(index + 1) / \(pages.count)")
                    .font(.sh(9.5, .semibold)).tracking(0.6)
                    .foregroundStyle(theme.inkStyle.text(0.4))
                    .padding(.leading, 6)
            }
            .padding(.bottom, 14)
        }
    }

    /// หัวข้อของแต่ละเรื่องในชีต — **จัดกลาง ตัวใหญ่ ทุกเรื่องใช้ตัวเดียวกัน**
    ///
    /// ของเดิมเป็นป้ายจิ๋ว 9.5pt ในคอลัมน์ซ้ายกว้าง 46pt: มันเบียดกับแถวปุ่มจนอ่านเป็นส่วนหนึ่งของปุ่ม
    /// และคำที่ยาวกว่าคอลัมน์ก็ถูกบีบจนเสียน้ำหนัก ชีตทั้งใบเลยอ่านออกมาเป็นปุ่มสิบกว่าปุ่มเรียงกัน
    /// ไม่ใช่คำถามไม่กี่ข้อที่ต้องตอบ
    ///
    /// พอหัวข้อขึ้นไปอยู่กลางเหนือแถวของตัวเอง แต่ละเรื่องก็มีหัวและตัวชัดเจน
    /// และแถวปุ่มได้ความกว้างคืนไปเต็มบรรทัด
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.sh(13.5, .semibold))
            .foregroundStyle(.white.opacity(0.72))
            .lineLimit(1).minimumScaleFactor(0.7)
            // ชิดซ้าย — ขอบซ้ายของหัวข้อทุกเรื่องกับแถวตัวเลือกใต้มันเป็นเส้นเดียวกันทั้งชีต
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// เรื่องหนึ่งเรื่องในชีต — หัวข้อชิดซ้าย แล้วตัวเลือกอยู่ใต้หัวข้อ
    private func section<V: View>(_ title: String, @ViewBuilder content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(title)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// เปลือกของตัวเลือกหนึ่งตัว — ตัวอย่างจริงนำหน้า ชื่อตามหลัง
    private func optionChip<V: View>(_ name: String, on: Bool,
                                     @ViewBuilder preview: () -> V) -> some View {
        HStack(spacing: 5) {
            preview()
                .frame(width: 24, height: 17)
                .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 0.5))
            Text(name).font(.sh(9.5, .semibold))
        }
        .fixedSize()
        .foregroundStyle(on ? .black.opacity(0.85) : .white.opacity(0.7))
        .padding(.horizontal, 6).padding(.vertical, 4.5)
        .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(on ? Color.white.opacity(0.92) : Color.white.opacity(0.08)))
    }

    private var themePanel: some View {
        VStack(spacing: 18) {
            // ── พื้นหลัง ───────────────────────────────────────────────
            // เรื่องแรกของแผง เพราะมันเปลี่ยนความหมายของทุกเรื่องที่อยู่ใต้มัน:
            // เลือกรูปเมื่อไหร่ สีพื้นหมดความหมายและหมึกถูกล็อก · เรื่องที่คุมเรื่องอื่นต้องมาก่อน
            //
            // และตอบคำถามเดียวจบ — "พื้นแบบไหน" ตอบแล้วค่อยเห็นลูกบิดของแบบนั้น
            // ไม่ใช่กองลูกบิดของทุกแบบวางรวมกันแล้วให้เดาว่าอันไหนใช้กับอันไหน
            section("พื้นหลัง") {
                HStack(spacing: 7) {
                    ForEach(BackdropStyle.allCases) { st in
                        Button {
                            withAnimation(Motion.flow) { theme.backdrop = st }
                            fitSheet()
                            Haptics.impact(.light)
                        } label: {
                            optionChip(st.name, on: theme.backdrop == st) {
                                BackdropSwatch(theme: theme, style: st)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }

            // ── ลูกบิดของชนิดพื้นที่เลือกอยู่ ──────────────────────────
            if theme.backdrop == .photo {
                backdropPhotoPanel
            } else {
                backdropColorPanel
                // ซ่อนเรื่องโทนเมื่อพื้นหลังเป็นรูป — รูปคุมความสว่างไม่ได้ หมึกเลยถูกล็อกเป็น
                // กลางคืน (ดู `CardTheme.activeInk`) ตัวเลือกที่กดแล้วไม่มีอะไรเกิดขึ้นแย่กว่าไม่มีตัวเลือก
                tonePanel
            }

            // ── มุม ────────────────────────────────────────────────────
            section("มุม") {
                HStack(spacing: 7) {
                    ForEach(CornerStyle.allCases) { c in
                        Button {
                            withAnimation(Motion.snap) { theme.corner = c }
                        } label: {
                            Text(c.name).font(.sh(11, .semibold))
                                .foregroundStyle(theme.corner == c ? .black.opacity(0.85) : .white.opacity(0.7))
                                .padding(.horizontal, 13).padding(.vertical, 6)
                                .background(Capsule().fill(theme.corner == c ? Color.white.opacity(0.92) : Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: สีพื้น

    /// สีของพื้นหลัง — **ทางเข้าเดียว**
    ///
    /// เดิมมีสามทางที่เขียนค่าเดียวกัน: วงกลมพาเลตต์ · แถบสเปกตรัมที่ปักอยู่หัวชีตตลอดเวลา ·
    /// และโทนที่ดูดมาจากรูปที่อัปโหลด — สามอย่างเขียนลง `customHue`/`customSat` เหมือนกัน
    /// โดยไม่มีอะไรบนจอบอกว่าตอนนี้พื้นสีอะไรอยู่ · เม็ดเดียวที่โชว์สีจริงกับเลข hex จริง
    /// ตอบคำถามนั้นได้ตลอดเวลา แล้วของที่ใช้แก้ค่อยกางออกมาเมื่อขอ
    private var backdropColorPanel: some View {
        section("สีพื้น") {
            VStack(alignment: .leading, spacing: 11) {
                Button {
                    colorOpen.toggle()
                    fitSheet()
                    Haptics.impact(.light)
                } label: {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(theme.backdropColors.top)
                            .frame(width: 18, height: 18)
                            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
                        Text(theme.backdropHex)
                            .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                        Spacer(minLength: 8)
                        Image(systemName: colorOpen ? "chevron.up" : "chevron.down")
                            .font(.sh(9, .bold))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("สีพื้น \(theme.backdropHex)")

                if colorOpen {
                    palettePresets
                    SpectrumPicker(hue: theme.backdropHSB.h,
                                   sat: theme.backdropHSB.s,
                                   bri: theme.backdropHSB.b) { h, s, b in
                        theme.setBackdropColor(h: h, s: s, b: b)
                    }
                    hexField
                }
            }
        }
    }

    private var palettePresets: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(Palette.allCases) { p in
                    let active = theme.palette == p && !theme.hasCustomColor
                    Button {
                        withAnimation(Motion.flow) {
                            theme.palette = p
                            // เลือกสีสำเร็จรูป = ตั้งใจเลิกใช้สีที่เลือกเอง/สีจากรูปพื้นหลัง
                            theme.clearBackdropColor()
                        }
                        Haptics.impact(.light)
                    } label: {
                        Circle()
                            .fill(LinearGradient(colors: [p.accentSoft, p.accent],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 30, height: 30)
                            .overlay(Circle().strokeBorder(.white.opacity(active ? 0.95 : 0.2),
                                                           lineWidth: active ? 2 : 0.5))
                            .scaleEffect(active ? 1.12 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 3).padding(.horizontal, 2)
        }
    }

    /// ช่องพิมพ์รหัสสี — แตะแล้วขึ้นกล่องถาม ไม่ใช่ช่องพิมพ์ที่ฝังอยู่ในแผง
    ///
    /// # ทำไมไม่ฝังช่องพิมพ์ไว้ตรงนี้
    ///
    /// คีย์บอร์ดสูงเกินครึ่งจอ ฝังไว้ในแผงเมื่อไหร่มันขึ้นมาทับแถบสีสามแถบที่เพิ่งใช้เลือกสีอยู่
    /// แล้วชีตต้องหลบทั้งใบ — กลายเป็นว่าเปิดตัวเลือกสีมาแต่มองไม่เห็นสีที่กำลังเลือก
    /// กล่องถามขึ้นคนละชั้น ปิดแล้วทุกอย่างยังอยู่ที่เดิม
    ///
    /// (เคยลองแบบฝังก่อน แล้วกดยังไงก็ไม่ติด — ตอนนั้นเข้าใจผิดว่าเป็นเรื่องโฟกัส
    /// ที่จริงคือทัชไม่เคยไปถึงมันเลยเพราะผังของชีตล้นกรอบ ดู `SheetStop.tall`)
    private var hexField: some View {
        Button {
            // เปิดมาเป็นช่องว่าง โดยเอาสีปัจจุบันไปเป็นตัวอย่างในช่องแทน — เปิดมาพร้อมค่าเดิม
            // เท่ากับบังคับให้ลบหกตัวอักษรก่อนถึงจะพิมพ์ของตัวเองได้ ทั้งที่ไม่มีใครมาแก้ทีละหลัก
            hexDraft = ""
            hexPrompt = true
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 8) {
                Text("HEX").font(.sh(9.5, .semibold)).foregroundStyle(.white.opacity(0.45))
                Text(theme.backdropHex)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer(minLength: 8)
                Image(systemName: "pencil").font(.sh(9.5, .semibold))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 9).padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    // MARK: โทน

    /// โทนหมึก — อัตโนมัติเป็นค่าตั้งต้น แถวชิปข้างล่างคือการขอคุมเอง
    ///
    /// แถวชิปโชว์หมึกที่ **ใช้อยู่จริง** เสมอ ไม่ว่าใครเป็นคนเลือก — สวิตช์ข้างหัวข้อคือที่เดียว
    /// ที่บอกว่าใครตัดสิน · ถ้าแยกเป็น "ไม่มีอันไหนถูกเลือก ตอนโหมดอัตโนมัติ" แถวนั้นจะอ่านว่า
    /// การ์ดยังไม่มีโทน ทั้งที่มันมีอยู่และเห็นอยู่ตรงหน้า
    private var tonePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                sectionTitle("โทน")
                Button {
                    withAnimation(Motion.flow) { theme.inkAuto = true }
                    Haptics.impact(.light)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: theme.inkAuto ? "checkmark" : "wand.and.sparkles")
                            .font(.sh(8, .bold))
                        Text("อัตโนมัติ").font(.sh(10, .semibold))
                    }
                    .fixedSize()
                    .foregroundStyle(theme.inkAuto ? .black.opacity(0.85) : .white.opacity(0.6))
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Capsule().fill(theme.inkAuto
                                               ? Color.white.opacity(0.92)
                                               : Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 7) {
                ForEach(CardInk.allCases) { i in
                    Button {
                        withAnimation(Motion.flow) {
                            theme.inkAuto = false
                            theme.ink = i
                        }
                        Haptics.impact(.light)
                    } label: {
                        optionChip(i.name, on: theme.activeInk == i) {
                            InkSwatch(theme: theme, ink: i)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: รูปพื้นหลัง

    private var backdropPhotoPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            backdropPhotoSource
            // เอฟเฟกต์กับความจางมีความหมายก็ต่อเมื่อมีรูปของผู้ใช้อยู่จริง —
            // รูปสำรองของระบบเป็นตัวยืนแทนชั่วคราว ไม่ใช่ของที่ครีเอเตอร์ตั้งใจเอามาแต่ง
            if photos.background != nil {
                section("เอฟเฟกต์") {
                    HStack(spacing: 7) {
                        ForEach(BackdropEffect.allCases) { fx in
                            Button {
                                withAnimation(Motion.flow) { theme.photoEffect = fx }
                                Haptics.impact(.light)
                            } label: {
                                optionChip(fx.name, on: theme.photoEffect == fx) {
                                    PhotoEffectSwatch(theme: theme, effect: fx)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer(minLength: 0)
                    }
                }
                section("ความจางของรูป") {
                    TrackSlider(value: theme.photoDim / 0.8, tint: theme.rawAccent) {
                        theme.photoDim = min(0.8, max(0, $0 * 0.8))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var backdropPhotoSource: some View {
        section("รูปพื้นหลัง") {
            HStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 33, height: 42)
                    .overlay {
                        if let bg = photos.background {
                            Image(uiImage: bg).resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: "photo").font(.sh(12))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 0.5))

                BackgroundPickButton(theme: theme.toolTheme) { tone in
                    withAnimation(Motion.flow) {
                        theme.backdrop = .photo
                        theme.customHue = tone?.hue
                        theme.customSat = tone?.saturation
                        // โทนที่ดูดจากรูปเป็นแค่เฉด ไม่ใช่สีพื้นจริง — ล้างความสว่างที่เคยตั้งเอง
                        // ไม่งั้นเปลี่ยนกลับไปพื้นสีทีหลังจะได้สีเก่าผสมเฉดใหม่ ซึ่งไม่ใช่ทั้งสองอย่าง
                        theme.customBri = nil
                    }
                    // รูปใบแรกพาแถวเอฟเฟกต์กับแถบความจางเข้ามาด้วย — แผงยาวขึ้นทันที
                    fitSheet()
                }

                // ทางออกที่ Linktree ไม่มี — ใส่รูปแล้วไม่ชอบต้องมีทางกลับที่เห็นอยู่ตรงนั้น
                // เอารูปออกแล้วพาไปพื้นไล่เฉดด้วย เพราะ "พื้นเป็นรูป แต่ไม่มีรูป"
                // จะตกไปใช้รูปสำรองของระบบ ซึ่งไม่ใช่สิ่งที่ใครสั่ง
                if photos.background != nil {
                    Button {
                        withAnimation(Motion.flow) {
                            photos.clearBackground()
                            theme.backdrop = .gradient
                            theme.clearBackdropColor()
                            theme.photoEffect = .none
                        }
                        fitSheet()
                        Haptics.impact(.medium)
                    } label: {
                        Text("เอาออก").font(.sh(9.5, .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func widgetPanel(_ sel: WidgetInstance) -> some View {
        let kind = sel.kind
        VStack(alignment: .leading, spacing: 16) {
            // ชื่อ widget คือหัวเรื่องของทั้งชีต — จัดกลางและใหญ่ที่สุดในแผง
            // ปุ่มปิดวางทับด้านขวาแทนที่จะอยู่ในแถวเดียวกัน ไม่งั้นชื่อจะถูกดันออกจากกึ่งกลางจริง
            HStack(spacing: 7) {
                Image(systemName: kind.symbol).font(.sh(13))
                    .foregroundStyle(kind.tier == .verified ? theme.rawAccent : .white.opacity(0.75))
                Text(kind.title).font(.sh(16, .semibold)).foregroundStyle(.white)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 8)
                // ปิดแผง = ออกจากโชว์รูม แต่ยังเลือก widget ตัวเดิมค้างไว้
                // (เดิมสั่ง `select(nil)` แล้วชีตกลายเป็นแผงธีมของทั้งการ์ดแทนที่จะหายไป)
                Button { closeTools() } label: {
                    Image(systemName: "xmark").font(.sh(10, .bold))
                        .foregroundStyle(.white.opacity(0.6)).frame(width: 24, height: 24)
                        .background(Circle().fill(.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }

            // ไม่มีสเต็ปเปอร์ขนาด/ระยะแล้ว — ปรับบนการ์ดโดยตรง
            // (ลากหมุดที่ขอบเพื่อย่อขยาย · ลากตัว widget เพื่อจัดตำแหน่งและระยะห่าง)
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: kind.canResizeWidth || kind.canResizeHeight
                          ? "hand.draw.fill" : "lock.fill")
                        .font(.sh(9))
                    Text(kind.canResizeWidth || kind.canResizeHeight
                         ? "ลากหมุดที่ขอบเพื่อปรับขนาด"
                         : "ขนาดล็อก · หลักฐานต้องเทียบกันได้")
                        .font(.sh(10.5, .medium))
                        .lineLimit(1).minimumScaleFactor(0.65)
                }
                .foregroundStyle(.white.opacity(0.42))

                Spacer(minLength: 0)
                Button {
                    deleteWidget(sel)
                } label: {
                    Image(systemName: "trash.fill").font(.sh(12))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 32, height: 30)
                        .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.red.opacity(0.42)))
                }
                .buttonStyle(.plain)
            }

            // เคยมีปุ่ม "ขึ้นหน้า / ลงหลัง" ตรงนี้ — ถอดออกแล้ว
            //
            // ชั้นซ้อนมีความหมายเฉพาะตอนของทับกันได้ พอผังบังคับว่าห้ามทับ
            // (`PageLayout.solve` ดันตัวที่มาทีหลังลงจนมีที่ว่าง) ปุ่มคู่นี้ก็กดแล้วไม่มีอะไรเกิดขึ้น
            // ปุ่มที่กดแล้วไม่มีอะไรเกิดขึ้นแย่กว่าปุ่มที่ไม่มี เพราะผู้ใช้จะเดาว่าแอปพัง

            // พื้นผิว — เลือกได้ทุก widget: กระจก · เข้ม · จาง · โปร่ง
            section("พื้น") {
                HStack(spacing: 7) {
                    ForEach(WidgetSurface.allCases) { s in
                        let active = sel.surface == s
                        Button {
                            setSurface(sel, s)
                        } label: {
                            Text(s.name).font(.sh(11, .semibold))
                                .foregroundStyle(active ? .black.opacity(0.85) : .white.opacity(0.65))
                                .padding(.horizontal, 13).padding(.vertical, 6)
                                .background(Capsule().fill(active ? Color.white.opacity(0.9) : Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }

            // ขอบ — แยกจากพื้น เพราะบางแบบอยากได้แค่เส้นกรอบโดยไม่เอาพื้น
            section("ขอบ") {
                HStack(spacing: 7) {
                    ForEach([true, false], id: \.self) { on in
                        let active = sel.border == on
                        Button {
                            setBorder(sel, on)
                        } label: {
                            Text(on ? "มีขอบ" : "ไม่มีขอบ").font(.sh(11, .semibold))
                                .foregroundStyle(active ? .black.opacity(0.85) : .white.opacity(0.65))
                                .padding(.horizontal, 13).padding(.vertical, 6)
                                .background(Capsule().fill(active ? Color.white.opacity(0.9) : Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }

            // ตัวอักษร — ขึ้นเฉพาะใบที่ทั้งใบเป็นตัวอักษรที่พิมพ์เอง (ดู `WidgetKind.usesTextStyle`)
            if kind.usesTextStyle { textStyleSections(sel) }
        }
    }

    /// สี่เรื่องของตัวอักษร — ฟอนต์ · สี · ขนาด · การจัดวาง
    ///
    /// อยู่ในแผงของ *ชิ้น* ไม่ใช่แผงธีมของทั้งการ์ด เพราะค่าพวกนี้เก็บต่อชิ้น
    /// (วางข้อความสองก้อนบนหน้าเดียวแล้วอยากได้คนละหน้าตาเป็นเรื่องปกติของการจัดหน้า)
    @ViewBuilder
    private func textStyleSections(_ sel: WidgetInstance) -> some View {
        let st = sel.textStyle

        // ── ฟอนต์ ──────────────────────────────────────────────────
        // ตัวอย่างเขียนด้วยฟอนต์นั้นจริง ๆ ทั้งไทยและละติน — ชื่อฟอนต์บอกอะไรไม่ได้เท่าตัวอักษร
        // และคนไทยเลือกฟอนต์จาก *หัวสระกับหาง* ซึ่งจะเห็นก็ต่อเมื่อมีตัวไทยให้ดู
        section("ฟอนต์") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CardFont.allCases) { f in
                        let active = st.face == f
                        Button { setTextStyle(sel) { $0.face = f } } label: {
                            VStack(spacing: 3) {
                                Text("ก่ำ Ag")
                                    .font(f.font(16, .semibold))
                                    .lineLimit(1)
                                Text(f.name)
                                    .font(.sh(8.5, .medium))
                                    .opacity(0.7)
                            }
                            .foregroundStyle(active ? .black.opacity(0.88) : .white.opacity(0.72))
                            .frame(width: 64, height: 48)
                            .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(active ? Color.white.opacity(0.92) : Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }

        // ── สี ─────────────────────────────────────────────────────
        // สามตัวแรกไม่มีสีของตัวเอง (มันคือ "ตามการ์ด") จึงเป็นชิปมีชื่อ ไม่ใช่วงกลม —
        // วงกลมขาวสองใบที่แปลว่าคนละอย่างเป็นตัวเลือกที่เดาไม่ออกว่าต่างกันตรงไหน
        section("สีตัวอักษร") {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 7) {
                    ForEach([TextTint.ink, .soft, .accent]) { t in
                        let active = st.tint == t
                        Button { setTextStyle(sel) { $0.tint = t } } label: {
                            Text(t.name).font(.sh(11, .semibold))
                                .foregroundStyle(active ? .black.opacity(0.85) : .white.opacity(0.65))
                                .padding(.horizontal, 13).padding(.vertical, 6)
                                .background(Capsule().fill(active ? Color.white.opacity(0.9)
                                                                  : Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 9) {
                    ForEach([TextTint.white, .black, .rose, .coral, .gold, .mint, .sky, .lavender]) { t in
                        let active = st.tint == t
                        Button { setTextStyle(sel) { $0.tint = t } } label: {
                            Circle()
                                .fill(t.swatch(accent: theme.rawAccent))
                                .frame(width: 26, height: 26)
                                .overlay(Circle().strokeBorder(.white.opacity(active ? 0.95 : 0.22),
                                                               lineWidth: active ? 2 : 0.6))
                                .scaleEffect(active ? 1.1 : 1)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(t.name)
                    }
                    Spacer(minLength: 0)
                }
            }
        }

        // ── ขนาด ───────────────────────────────────────────────────
        section("ขนาด") {
            HStack(spacing: 7) {
                ForEach(TextScale.allCases) { sc in
                    let active = st.scale == sc
                    Button { setTextStyle(sel) { $0.scale = sc } } label: {
                        Text(sc.name).font(.sh(11, .semibold))
                            .foregroundStyle(active ? .black.opacity(0.85) : .white.opacity(0.65))
                            .padding(.horizontal, 13).padding(.vertical, 6)
                            .background(Capsule().fill(active ? Color.white.opacity(0.9)
                                                              : Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }

        // ── จัดวาง ─────────────────────────────────────────────────
        section("จัดวาง") {
            HStack(spacing: 7) {
                ForEach(TextAlign.allCases) { a in
                    let active = st.align == a
                    Button { setTextStyle(sel) { $0.align = a } } label: {
                        Image(systemName: a.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(active ? .black.opacity(0.85) : .white.opacity(0.65))
                            .frame(width: 40, height: 28)
                            .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(active ? Color.white.opacity(0.9) : Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(a.name)
                }
                Spacer(minLength: 0)
            }
        }
    }

    /// แก้สไตล์ตัวอักษรของชิ้นที่เลือก — รูปแบบเดียวกับ `setSurface`/`setBorder`
    private func setTextStyle(_ sel: WidgetInstance,
                              _ change: (inout WidgetTextStyle) -> Void) {
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            withAnimation(Motion.flow) { change(&pages[pi].items[i].textStyle) }
            Haptics.impact(.light)
            return
        }
    }

    private func setSurface(_ sel: WidgetInstance, _ s: WidgetSurface) {
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            withAnimation(Motion.flow) { pages[pi].items[i].surface = s }
            Haptics.impact(.light)
            return
        }
    }

    private func setBorder(_ sel: WidgetInstance, _ on: Bool) {
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            withAnimation(Motion.flow) { pages[pi].items[i].border = on }
            Haptics.impact(.light)
            return
        }
    }

    /// แถวสลับแบบภายในหมวดเดียวกัน
    ///
    /// วางไว้ตรงนี้แทนที่จะต้องไปเปิด gallery ใหม่ เพราะเวลาผู้ใช้แตะ widget
    /// สิ่งที่เขาอยากรู้อันดับแรกคือ "มันมีหน้าตาแบบอื่นไหม" ไม่ใช่ "จะเพิ่มตัวใหม่"
    @ViewBuilder
    private func variantPicker(_ sel: WidgetInstance) -> some View {
        let siblings = WidgetKind.allCases.filter { $0.family == sel.kind.family }
        if siblings.count > 1 {
            VStack(alignment: .leading, spacing: 9) {
                sectionTitle("แบบอื่นของ \(sel.kind.family.label)")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(siblings) { k in
                            let active = k == sel.kind
                            Button { swap(sel, to: k) } label: {
                                VStack(spacing: 6) {
                                    WidgetThumb(kind: k, theme: theme.toolTheme)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(active ? theme.rawAccent : .white.opacity(0.12),
                                                              lineWidth: active ? 2 : 0.6)
                                        )
                                    Text(k.title)
                                        .font(.sh(9.5, active ? .semibold : .regular))
                                        .foregroundStyle(active ? .white : .white.opacity(0.5))
                                        .lineLimit(1).minimumScaleFactor(0.7)
                                        .frame(width: 104)
                                }
                                // พรีวิวปิด hit testing ไว้ (กันไม่ให้ widget ข้างในกินทัช)
                                // ถ้าไม่ประกาศ contentShape ปุ่มจะกดติดแค่ตรงข้อความใต้รูป
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    /// ลบ widget พร้อมยื่นทางกลับให้ห้าวินาที
    ///
    /// # ทำไมเป็น "เลิกทำ" ไม่ใช่ "ยืนยันว่าจะลบ"
    ///
    /// การลบ widget เป็นท่าที่ทำบ่อยระหว่างจัดหน้า กล่องยืนยันจึงกลายเป็นภาษีที่เก็บทุกครั้ง
    /// จนคนกดผ่านโดยไม่อ่านภายในสามครั้งแรก แล้วก็ไม่ได้กันอะไรอีกต่อไป · ส่วนการเลิกทำ
    /// ไม่รบกวนคนที่ตั้งใจลบเลยสักนิด และช่วยคนที่กดพลาดได้จริง
    ///
    /// เก็บทั้งตัวและ **ที่นั่งเดิม** ไว้ — รูปกับข้อความของ widget ผูกกับ `id` ที่คงไว้
    /// (ดู `PhotoStore.perWidget`) ของจึงกลับมาครบ ไม่ใช่กลับมาเป็นตัวเปล่า
    private func deleteWidget(_ sel: WidgetInstance) {
        guard let pi = pages.firstIndex(where: { $0.items.contains { $0.id == sel.id } }),
              let ii = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { return }
        let removed = pages[pi].items[ii]
        withAnimation(Motion.flow) {
            pages[pi].items.remove(at: ii)
            selected = nil
        }
        // ปิดชีตด้วย — สองเหตุผล: แผงที่เปิดค้างอยู่เป็นแผงของของที่ไม่มีอยู่แล้ว (ตอนนี้มันเด้ง
        // ไปเป็นแผงธีมของทั้งการ์ดแทน ซึ่งไม่มีใครขอ) และชีตบังขอบล่างของจอพอดี — ที่ที่แถบ
        // "เลิกทำ" ยืนอยู่ · ไม่ปิดก็เท่ากับยื่นทางกลับให้แล้วเอาไปซ่อนไว้หลังชีต
        withAnimation(Motion.settle) { showTools = false }
        Haptics.impact(.medium)
        offer("ลบ\(sel.kind.title)แล้ว", "เลิกทำ") {
            withAnimation(Motion.flow) {
                let p = min(pi, pages.count - 1)
                pages[p].items.insert(removed, at: min(ii, pages[p].items.count))
                // พากลับไปหน้าที่มันเคยอยู่ด้วย — ระหว่างห้าวินาทีนั้นผู้ใช้ปัดไปหน้าอื่นได้
                // แล้วของที่คืนมาจะโผล่นอกสายตาโดยไม่มีอะไรบอกว่ามันกลับมาแล้ว
                index = p
                selected = removed.id
            }
            Haptics.impact(.light)
        }
    }

    /// สลับแบบโดยคงตำแหน่งเดิมไว้ · บีบขนาดให้เข้ากรอบของแบบใหม่
    private func swap(_ sel: WidgetInstance, to kind: WidgetKind) {
        guard kind != sel.kind else { return }
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            var w = pages[pi].items[i]
            w.kind = kind
            // แบบใหม่อาจล้นหน้าถ้าเดิมถูกยืดไว้สุด — รูดกลับเข้าหน้า ตำแหน่งเดิมคงไว้เท่าที่ทำได้
            w.rect = PageLayout.clamp(w.rect, page: pageSize)
            // แบบใหม่บุคลิกต่างจากเดิม — กลับไปใช้พื้นตั้งต้นของมัน
            w.surface = kind.isPlain ? .plain : .glass
            w.border = !kind.isPlain
            withAnimation(Motion.flow) {
                pages[pi].items[i] = w
            }
            Haptics.impact(.medium)
            return
        }
    }

}

// MARK: - ข้อความชั่วคราวเหนือขอบล่าง

/// ข้อความที่แอปพูดกับผู้ใช้ — **สามชนิด ต่างกันที่ว่าใครเป็นคนปิด**
///
/// เดิมมีชนิดเดียวคือตัวหนังสือที่จางหายเองใน 3 วินาทีและแตะไม่ได้ ซึ่งเหมาะกับการรายงานสถานะ
/// แต่ถูกใช้รายงาน "คำสั่งของคุณถูกปฏิเสธ" ด้วย — คนละเรื่องกันโดยสิ้นเชิง เพราะอย่างหลัง
/// ผู้ใช้ต้องได้อ่านแน่ ๆ ไม่ใช่ได้อ่านถ้าบังเอิญมองอยู่ · และมันถือปุ่มไม่ได้เลย
/// จึงไม่มีทางเสนอ "เลิกทำ" ให้กับของที่ลบไปแล้ว
private struct CardNotice {
    enum Kind {
        /// รายงานสถานะ — หายเอง ไม่รับทัช
        case status
        /// คำสั่งถูกปฏิเสธ — ค้างจนผู้ใช้กดปิด
        case warning
        /// ทำไปแล้วแต่กู้คืนได้ — ถือปุ่มหนึ่งปุ่ม
        case offer
    }
    let text: String
    let kind: Kind
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
}

// MARK: - Spectrum picker

/// แถบเลือกสี — ลากบนสเปกตรัมเลือกเฉด · แถบล่างปรับความสด
///
/// ฝังในแผงแทน `ColorPicker` ของระบบ เพราะตัวระบบเป็นชีตซ้อนชีตแล้วเปิดไม่ขึ้น
/// และแบบฝังยังดีกว่าตรงที่การ์ดเปลี่ยนสีให้เห็นสด ๆ ทุกเฟรมระหว่างลาก
private struct SpectrumPicker: View {
    let hue: Double
    let sat: Double
    /// ความสว่าง — แถบที่สามมีไว้เพราะช่อง hex ต้องวิ่งกลับมาลงแถบได้ครบทั้งสามค่า
    /// ขาดตัวนี้ไปแถบสีจะแก้สีที่พิมพ์มาไม่ได้ทั้งหมด แล้วสองทางเข้าจะเถียงกันเอง
    let bri: Double
    let onChange: (Double, Double, Double) -> Void

    private let knob: CGFloat = 20
    private let barH: CGFloat = 26

    /// ความกว้างของแถบ — วัดจาก `GeometryReader` ที่วางไว้เป็น **พื้นหลัง** ไม่ใช่ตัวห่อแถบ
    ///
    /// เดิมห่อแต่ละแถบด้วย `GeometryReader` แล้วบีบด้วย `.frame(height: 26)` ทับอีกที
    /// ผลคือพื้นที่รับทัชของแถบไม่ตรงกับที่มันวาด — มันกินขึ้นไปข้างบนราวห้าสิบพอยต์
    /// แถวที่วางไว้เหนือแถบสีจึงกดไม่ติด ทัชถูกแถบสีคว้าไปหมดทั้งที่นิ้วอยู่คนละที่กับแถบ
    /// (อาการนี้เจอตอนวางช่อง hex ไว้เหนือแถบแล้วกดยังไงก็ไม่ขึ้น แต่กดสูงขึ้นไปอีก 48pt กลับติด)
    ///
    /// วัดจากพื้นหลังแทน แถบจึงเป็นกล่องสูง 26pt ธรรมดาในผังปกติ · รูปทรงที่รับทัชกับรูปทรง
    /// ที่วาดเป็นก้อนเดียวกันแน่นอน
    @State private var width: CGFloat = 0

    var body: some View {
        VStack(spacing: 7) {
            bar(colors: (0...12).map { Color(hue: Double($0) / 12, saturation: 0.9, brightness: 1) },
                value: hue) { onChange($0, sat, bri) }
            // แถบความสดวาดที่ความสว่างอย่างน้อย 0.45 — ตอนสีพื้นเกือบดำ แถบที่ล้อค่าจริง
            // จะกลายเป็นแถบดำล้วนที่มองไม่ออกว่าลากไปทางไหนแล้วได้อะไร
            bar(colors: [Color(hue: hue, saturation: 0.04, brightness: max(0.45, bri)),
                         Color(hue: hue, saturation: 1, brightness: max(0.45, bri))],
                value: sat) { onChange(hue, $0, bri) }
            bar(colors: [Color(hue: hue, saturation: sat, brightness: 0.02),
                         Color(hue: hue, saturation: sat, brightness: 1)],
                value: bri) { onChange(hue, sat, max(0.02, $0)) }
        }
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { width = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in width = w }
            }
        }
    }

    private func bar(colors: [Color], value: Double,
                     _ set: @escaping (Double) -> Void) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                .overlay(Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 0.5))
                .frame(height: 16)
            Circle()
                // ปุ่มจับเป็นสีจริงที่กำลังจะได้ ไม่ใช่สีเต็มความสว่างเสมอ — ลากแถบล่างลง
                // แล้วปุ่มต้องมืดตามไปด้วย ไม่งั้นมันบอกสีที่การ์ดไม่ได้ใช้
                .fill(Color(hue: hue, saturation: sat, brightness: max(0.06, bri)))
                .frame(width: knob, height: knob)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                .offset(x: CGFloat(min(max(value, 0), 1)) * max(width - knob, 0))
        }
        // แถบสูงกว่าเส้นสี — ให้นิ้วจับติดง่าย ไม่ต้องเล็งเป๊ะ
        .frame(maxWidth: .infinity, minHeight: barH, maxHeight: barH)
        .contentShape(Rectangle())
        // ต้อง highPriority ไม่งั้น ScrollView ของชีตแย่ง pan ไปหมด แถบเลื่อนไม่ได้เลย
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    // หักครึ่งปุ่มออก ให้จุดที่นิ้วแตะตรงกับกึ่งกลางปุ่มพอดี
                    set(Double(min(1, max(0, (g.location.x - knob / 2) / max(width - knob, 1)))))
                }
                .onEnded { _ in Haptics.impact(.light) }
        )
    }
}

/// แถบลากค่าเดียว 0…1 — โครงเดียวกับแถบใน `SpectrumPicker` รวมถึงเหตุผลที่ไม่ใช้
/// `GeometryReader` ห่อตัวเอง (ดูคอมเมนต์ `width` ที่นั่น)
private struct TrackSlider: View {
    let value: Double
    var tint: Color = .white
    let onChange: (Double) -> Void

    @State private var width: CGFloat = 0
    private let knob: CGFloat = 20

    var body: some View {
        let k = CGFloat(min(1, max(0, value)))
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.12)).frame(height: 6)
            // ส่วนที่ผ่านมาแล้วเป็นสีเน้น — แถบเปล่าล้วนบอกไม่ได้ว่าตอนนี้อยู่มากหรือน้อย
            // ถ้าไม่มองหาปุ่มจับให้เจอก่อน
            Capsule().fill(tint.opacity(0.9))
                .frame(width: k * max(width - knob, 0) + knob / 2, height: 6)
            Circle()
                .fill(.white)
                .frame(width: knob, height: knob)
                .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                .offset(x: k * max(width - knob, 0))
        }
        .frame(maxWidth: .infinity, minHeight: 26, maxHeight: 26)
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { width = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in width = w }
            }
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    onChange(Double(min(1, max(0, (g.location.x - knob / 2) / max(width - knob, 1)))))
                }
                .onEnded { _ in Haptics.impact(.light) }
        )
    }
}

/// ตัวอย่างย่อของเอฟเฟกต์หนึ่งแบบ — **รูปจริงของผู้ใช้ ผ่านเอฟเฟกต์จริง**
///
/// ต่างจากของ Linktree ที่เป็นไอคอนสัญลักษณ์ — ไอคอนบอกชื่อเทคนิค แต่ไม่ได้ตอบคำถาม
/// เดียวที่คนถามตอนกวาดตาดูแถวนี้ คือ "รูปของฉันผ่านอันนี้แล้วออกมาหน้าตายังไง"
private struct PhotoEffectSwatch: View {
    let theme: CardTheme
    let effect: BackdropEffect

    @Environment(PhotoStore.self) private var photos: PhotoStore?

    var body: some View {
        ZStack {
            theme.backdropColors.bottom
            if let bg = photos?.background(effect) {
                Image(uiImage: bg)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .grayscale(effect == .mono ? 1 : 0)
                    // รัศมีเบลอต้องย่อตามกรอบ — ใช้ 26 เท่าของจริงในกรอบ 24pt แล้วเละเป็นสีเดียว
                    .blur(radius: effect == .blur ? 3 : 0, opaque: true)
            }
        }
    }
}

// MARK: - Canvas grid

/// จุดปะคือ "กริดจริง" ไม่ใช่ลายตกแต่ง — ระยะห่างจุดคือขั้นที่ widget สแนปได้จริง
///
/// ตอนผังยังเป็นคอลัมน์ จุดต้องโกหกเล็กน้อย (ซอยแนวนอนละเอียดกว่าที่สแนปได้จริง)
/// เพื่อให้สนามจุดดูเป็นจัตุรัส · พอผังเป็นพิกเซลแล้วไม่ต้องโกหกอีก:
/// ทั้งสองแกนสแนปทีละ `PageLayout.step` เท่ากัน จุดจึงวางตรงขั้นจริงได้ทั้งคู่
private struct CanvasGrid: View {
    let theme: CardTheme
    /// จุดกริดอยู่บนหน้ากระดาษ จึงต้องพลิกตามหมึกเหมือนทุกอย่างบนการ์ด
    var ink: InkStyle = .night
    /// พิกัดอ้างมุมบนซ้ายของหน้ากระดาษ — ตัวเรียกต้องวางให้กรอบตรงกับหน้าเอง
    let page: CGSize

    var body: some View {
        Canvas { ctx, _ in
            let box = PageLayout.content(page)
            guard box.width > 0, box.height > 0 else { return }
            // วาดทุก 2 ขั้น — ขั้นละ 6pt ถี่เกินกว่าจะอ่านเป็นกริด กลายเป็นพื้นเทา
            let pitch = PageLayout.step * 2
            // จุดเน้นทุก 5 ช่วง (60pt) — ตัวช่วยกะระยะแบบไม้บรรทัด ไม่ใช่ขั้นสแนปคนละแบบ
            let major = 5
            let big: CGFloat = 2.2, small: CGFloat = 1.4

            var iy = 0
            var y = box.minY
            while y <= box.maxY + 1 {
                var ix = 0
                var x = box.minX
                while x <= box.maxX + 1 {
                    let strong = ix % major == 0 && iy % major == 0
                    let d = strong ? big : small
                    ctx.fill(Path(ellipseIn: CGRect(x: x - d / 2, y: y - d / 2,
                                                    width: d, height: d)),
                             with: .color(ink.line(strong ? 0.18 : 0.07)))
                    x += pitch
                    ix += 1
                }
                y += pitch
                iy += 1
            }
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}

// MARK: - Handle

private struct HandleGrip: View {
    let theme: CardTheme
    enum Axis { case horizontal, vertical }
    let axis: Axis

    var body: some View {
        Capsule()
            .fill(.white)
            .frame(width: axis == .horizontal ? 6 : 32, height: axis == .horizontal ? 32 : 6)
            .overlay(Capsule().strokeBorder(theme.accent, lineWidth: 1.4))
            .shadow(color: .black.opacity(0.5), radius: 5, y: 2)
            // พื้นที่กดเผื่อรอบละ 9pt · คู่กับการดันหมุดออกนอกกรอบ 11pt
            //
            // เดิมเผื่อ 16pt แล้ววางคร่อมขอบพอดี — พื้นที่กดจึงกินเข้าไปในตัว widget 19pt
            // ข้อความที่อยู่ติดขอบล่าง/ขวาตรงกลางเลยแตะไม่ติดเลย เพราะหมุดคว้าทัชไปก่อนทุกครั้ง
            .contentShape(Rectangle().inset(by: -9))
    }
}

// MARK: - Haptics

enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func rigid() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
}

// MARK: - ตัวอย่างย่อของตัวเลือกธีม

/// ตัวอย่างย่อของ "โทน" หนึ่งแบบ — ฉากหลังจริง + แผ่นการ์ดจริง + สีหมึกจริง
///
/// ชื่ออย่าง "กระดาษ" กับ "ใสใส" ไม่ได้บอกว่ากดแล้วได้อะไร ต้องเห็นถึงจะรู้
/// วาดด้วยสูตรเดียวกับของจริงทุกค่า ไม่ใช่ภาพประกอบที่วาดแยก — เปลี่ยนธีมเมื่อไหร่ตัวอย่างตามทันที
private struct InkSwatch: View {
    let theme: CardTheme
    let ink: CardInk

    var body: some View {
        var t = theme
        t.ink = ink
        // ตัวอย่างต้องโชว์หมึกที่ชิปนี้แทน ไม่ใช่หมึกที่ระบบเลือกให้ — ลืมปิดโหมดอัตโนมัติ
        // เมื่อไหร่ ชิปทั้งสามจะวาดออกมาหน้าตาเหมือนกันหมด เพราะทุกใบถูกคำนวณทับด้วยค่าเดียวกัน
        t.inkAuto = false
        // ฉากหลังแบบรูปบังคับหมึกกลางคืน ตัวอย่างทั้งสามจะเหมือนกันหมด — สลับเป็นไล่เฉดให้เห็นความต่าง
        if t.backdrop == .photo { t.backdrop = .gradient }
        let c = t.backdropColors
        let s = t.inkStyle
        return ZStack {
            LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(s.isLight ? Color.white.opacity(0.64) : Color.white.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(s.line(0.22), lineWidth: 0.5))
                .overlay(alignment: .leading) {
                    // สามบรรทัดจำลอง — เส้นบางและระยะห่างต้องคุมเป็นสัดส่วนของกรอบ
                    // ไม่ใช่ค่าคงที่ ไม่งั้นพอย่อกรอบลงบรรทัดจะเบียดกันจนเป็นก้อนเดียว
                    VStack(alignment: .leading, spacing: 1.6) {
                        Capsule().fill(t.accent).frame(width: 5, height: 1.8)
                        Capsule().fill(s.text(0.82)).frame(width: 12, height: 2.2)
                        Capsule().fill(s.text(0.36)).frame(width: 8, height: 1.8)
                    }
                    .padding(.leading, 3)
                }
                .padding(2.5)
        }
    }
}

/// ตัวอย่างย่อของ "ฉากหลัง" หนึ่งแบบ — ใช้สีและชั้นเดียวกับ `CardBackdrop`
private struct BackdropSwatch: View {
    let theme: CardTheme
    let style: BackdropStyle

    @Environment(PhotoStore.self) private var photos: PhotoStore?

    var body: some View {
        var t = theme
        t.backdrop = style
        let c = t.backdropColors
        return ZStack {
            switch style {
            case .gradient:
                LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
            case .glow:
                c.bottom
                // ดวงแสงย่อ — ต้องเบลอน้อยกว่าของจริงตามสัดส่วน ไม่งั้นเละเป็นสีเดียว
                Circle().fill(t.accent.opacity(0.75)).frame(width: 16, height: 16)
                    .blur(radius: 6).offset(x: -6, y: -5)
                Circle().fill(t.accentSoft.opacity(0.5)).frame(width: 14, height: 14)
                    .blur(radius: 6).offset(x: 7, y: 6)
            case .solid:
                c.top
            case .photo:
                c.bottom
                if let bg = photos?.background {
                    Image(uiImage: bg).resizable().aspectRatio(contentMode: .fill)
                        .overlay(c.top.opacity(theme.activeInk.isLight ? 0.6 : 0.35))
                } else if let photos {
                    photos.image(0).aspectRatio(contentMode: .fill)
                        .blur(radius: 4, opaque: true)
                        .overlay(c.bottom.opacity(0.45))
                }
            }
        }
    }
}
