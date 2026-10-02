import Combine
import SwiftUI
import UIKit

struct CardScreen: View {
    /// คลิปเปิดมาดูอย่างเดียว — ห้ามเข้าโหมดแต่ง / ตู้ widget / ลากวาง
    var viewOnly = false
    /// ปิดหน้าดู — มีเฉพาะตอนเปิดจากคลังเพื่อ "ดูแบบที่แบรนด์เห็น" (คลิปจริงไม่มีทางกลับ)
    var onClose: (() -> Void)? = nil
    /// พิธีเปิดของหน้าดู — การ์ดถูก "แจก" ลงบนเวที แล้วแถบผู้ออกบัตรปรากฏเป็นอย่างสุดท้าย
    @State private var dealt = false
    @State private var stripIn = false
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

    /// การ์ดของตัวเองแต่งได้ตลอด — ไม่มีโหมด "ดู" แยกอีกแล้ว (คลิปเท่านั้นที่ดูอย่างเดียว)
    ///
    /// เคยมีปุ่ม "แต่ง" เป็นประตูก่อนถึงเครื่องมือ ผลคือทุกคนต้องผ่านสองชั้นก่อนแตะอะไรได้
    /// ทั้งที่การ "ดูผลจริง" มีหน้าแชร์ทำหน้าที่นั้นอยู่แล้ว
    private var isEditing: Bool { !viewOnly }
    /// แถบล่างอยู่ที่ไหน — ค่าเดียวที่บอกว่าตอนนี้กำลังทำอะไรอยู่ (ดู `DockMode`)
    @State private var dock: DockMode = .main
    /// ความสูงของของที่อยู่ขอบล่าง (แถบ + ถาด หรือแผ่นพิมพ์ + คีย์บอร์ด) — วัดจากของจริงทุกเฟรม
    ///
    /// การ์ดย่อ/ดันตามค่านี้ **ทันที ไม่ผ่านสปริงอีกชั้น** — ถาดที่กำลังไหลขึ้นด้วยสปริงคือ
    /// ตัวขับ การ์ดจึงขยับพร้อมถาดเป็นการเคลื่อนไหวเดียว ไม่ใช่สองอย่างที่วิ่งตามกัน
    @State private var bottomUI: CGFloat = 0
    /// ความสูงของสองแถวเหนือแป้นพิมพ์ตอนพิมพ์ — วัดครั้งเดียว ค่าคงที่ (ดู `bottomCover`)
    @State private var toolsH: CGFloat = 118
    /// ประวัติแก้ไขสำหรับ ↶ ↷ — ทุกตัวเลือกมีผลทันที นี่คือทางกลับทางเดียว
    @State private var history = EditHistory()
    /// ภาพนิ่งที่เพิ่งกู้คืนจากประวัติ — `onChange` ต้องไม่บันทึกมันซ้ำเป็นจังหวะใหม่
    @State private var applied: EditHistory.Snapshot?
    /// สีพื้นที่ผู้ใช้เคยตั้งเองล่าสุด — แตะสีสำเร็จรูปดูเล่นแล้วต้องกลับมาสีนี้ได้ ไม่ใช่หายถาวร
    @State private var myColor: (h: Double, s: Double, b: Double)?
    /// จังหวะ "เปิดไฟ" ตอนเพิ่งเข้าโหมดแต่ง — กรอบประทุกชิ้นเข้มขึ้นชั่วครู่แล้วค่อยจางลงพอดี
    ///
    /// เข้าโหมดแต่งแล้วหน้าตาการ์ดเหมือนเดิมเป๊ะ คือเหตุผลที่คนหาไม่เจอว่าอะไรแก้ได้
    /// (เห็นชัดตอนเทส: ทั้งสามคนไปจบที่ปุ่มพาเลตบนแถบบน เพราะเป็นปุ่มเดียวที่มองเห็น)
    /// การกวาดสายตาครั้งแรกจึงต้องได้คำตอบว่า "ของบนหน้านี้แตะได้ทุกชิ้น" โดยไม่ต้องอ่านอะไร
    @State private var editReveal = false
    @State private var revealTask: Task<Void, Never>?
    /// ชิ้นที่เลือกอยู่ — อ่านจาก dock ไม่มีสถานะแยก (เลือก = อยู่ในโหมดของชิ้นนั้น)
    private var selected: UUID? { dock.selectedID }

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

    /// หน้าที่กำลังดูอยู่
    @State private var index = 0
    /// ความคืบหน้าของการปัด -1…1 · ขับ crossfade เอง ไม่ใช้ ScrollView เพราะ ScrollView สไลด์เสมอ
    @State private var swipe: CGFloat = 0
    /// การปัดครั้งนี้ **เป็นแนวนอนจริง** — ตัดสินตอนนิ้วขยับ แล้วปล่อยนิ้วค่อยอ่าน
    ///
    /// ตอนปล่อยนิ้วเคยดูแค่ความเร็วแนวนอน — ลากชิ้นเฉียง ๆ หรือปัดลงเร็ว ๆ ก็มีความเร็วแนวนอนติดมา
    /// แล้วช่องพลิกทั้งที่นิ้วไม่ได้ปัดซ้ายขวาเลย (ชีตที่เปิดอยู่ปิดตามไปด้วย) — ต้องผ่านด่านแนวนอนก่อนเท่านั้น
    @State private var swipeArmed = false

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
    /// แถบระบบด้านล่าง — กรอบคีย์บอร์ดวัดจากก้นหน้าต่าง แต่ก้อนขอบล่างนั่งอยู่เหนือแถบนี้แล้ว
    @State private var safeBottom: CGFloat = 0

    /// ความสูงของสิ่งที่บังจอด้านล่างอยู่ตอนนี้ — แถบ+ถาด **หรือ** แผ่นพิมพ์+คีย์บอร์ด
    /// ทั้งหมดอยู่ในก้อนเดียวที่ขอบล่าง (ดู `bottomChrome`) วัดครั้งเดียวได้ตัวเลขเดียว
    /// ทุกที่ที่ต้องรู้ว่า "เหลือที่ว่างเท่าไหร่" จึงอ่านจากที่เดียว ไม่มีทางคิดคนละแบบ
    private var bottomCover: CGFloat {
        guard isEditing else { return 0 }
        // ตอนพิมพ์คิดจาก **ความสูงปลายทาง** ของแป้นพิมพ์ (ระบบบอกตั้งแต่เริ่มเลื่อนขึ้น) ไม่ใช่ค่าที่วัดสด
        // ค่าที่วัดสดเปลี่ยนทุกเฟรมระหว่างแป้นพิมพ์เลื่อน — ก้อนข้อความที่กำลังไหลไปกลางจอ
        // จะถูกเขียนเป้าหมายทับทุกเฟรมจนสปริงถูกยกเลิก กลายเป็นกระโดดแทนที่จะลอย
        if dock.isText { return max(0, keyboard - safeBottom) + toolsH + 8 }
        return bottomUI
    }

    /// สเกลของการ์ด — ย่อเท่าที่จำเป็นให้ทั้งหน้าอยู่เหนือของที่บังอยู่ข้างล่าง
    ///
    /// ไม่มีกติกา "ใกล้ 1 ให้ปัดเป็น 1" แล้ว — แถบล่างมีอยู่ตลอด การ์ดจึงย่อลงราว 0.93
    /// เสมอในโหมดหลัก ดีกว่าให้แถบทับก้นการ์ดแล้วชิ้นล่างสุดแตะไม่ได้
    ///
    /// **ย่ออย่างเดียว ไม่ดัน** — ยึดหัวการ์ดไว้กับที่เสมอ (`anchor: .top`) การ์ดจึงไม่เคย
    /// เลื่อนไปหาชิ้นที่กำลังแก้ · ของที่บังอยู่ข้างล่างสูงขึ้นเท่าไหร่ ทั้งใบก็แค่เล็กลงเท่านั้น
    private var editScale: CGFloat {
        // โชว์รูมโชว์ชิ้นเดียว จึงไม่ต้องย่อทั้งหน้าให้พอดีช่องว่าง — `showroom` จัดขนาดของชิ้นนั้นเอง
        // ถ้ายังย่อซ้ำ ของที่ยกขึ้นมาโชว์จะเล็กกว่าตอนอยู่บนการ์ดจริง ซึ่งกลับหัวกลับหางกับคำว่าโชว์รูม
        if showroomID != nil { return 1 }
        let visible = viewportH - bottomCover - 74 - 8
        // เทียบกับความสูง **ที่วาดออกมาจริงบนจอ** ไม่ใช่ความสูงในหน่วยออกแบบ
        let fit = visible / max(pageSize.height * pageFit, 1)
        // ไม่มีชิ้นที่เลือก (พื้นหลัง · ตู้) = กำลังดู **ทั้งใบ** ยอมย่อลึกกว่าเพื่อให้เห็นครบ
        // มีชิ้นที่เลือกค่อยรักษาขนาดให้หมุดยังจับได้
        //
        // แผ่นหลายช่องบนแถบหลักย่อไว้ไม่เกิน 0.9 เสมอ — ขอบของช่องข้าง ๆ จะได้โผล่ราว 20pt ทั้งสองข้าง
        // นี่คือสิ่งที่บอกว่า "กระดาษยาวกว่าจอ" โดยไม่ต้องมีตัวหนังสือ (ดู `deck`)
        let cap: CGFloat = multiPage && dock.isMain ? 0.9 : 1
        return min(cap, max(selected == nil ? 0.48 : 0.62, fit))
    }
    /// สเกลรวมจากหน่วยออกแบบถึงหน่วยจอ — ย่อให้พอดีจอ **คูณ** ย่อเพื่อหลบชีตตอนแต่ง
    private var canvasScale: CGFloat { (isEditing ? editScale : viewScale) * pageFit }

    /// หน้าดู: ย่อการ์ดลงพอให้ท้ายหน้า (`viewerFooter`) ไม่ทับขอบล่างของการ์ด
    /// ยึดหัวไว้ ย่อลงเท่าที่ท้ายหน้าต้องการ — แถบผู้ออกบัตรที่ขอบล่างต้องเห็นเสมอ
    private var viewScale: CGFloat {
        guard viewOnly else { return 1 }
        let shown = pageSize.height * pageFit
        return max(0.6, 1 - (52 + verifyBandSpace) / max(shown, 1))
    }

    /// ที่ว่างใต้แถบบนสำหรับแถบ Verified ของหน้าดู — มีเฉพาะการ์ดที่ได้ตราแล้ว
    private var verifyBandSpace: CGFloat {
        viewOnly && VerifiedFacts.current.verified ? VerifiedBand.height + 8 : 0
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
    @State private var pressMode: UUID?
    /// จุดที่นิ้วแตะบน widget ตัวที่กำลังกด — ขับการเอียง 3 มิติ
    @State private var pressPoint: (id: UUID, at: CGPoint)?
    /// ให้กรอบเลือกไหลจาก widget เดิมไปตัวใหม่ แทนที่จะกระพริบหายแล้วโผล่
    @Namespace private var selectionNS
    /// หน้าตัวอย่างก่อนแชร์รูป / คัดลอกลิงก์
    @State private var showPreview = false
    /// ตู้ widget ขอให้กรอกหัวข้อ Star Profile ก่อนวางใบนี้ (ดู `WidgetFamily.topic`)
    @State private var topicFill: TopicFillRequest?
    /// ใบแบรนด์/ผลงานยืนยันยังล็อก — ถามว่าจะไปดูงานไหม
    @State private var askJobs = false

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
    /// ชีต "ติดต่อ" ของหน้าดู — ปุ่มล่างสุดเปิด (ชุดเดียวกับหน้าโปรไฟล์ครีเอเตอร์ใน salehere-ios)
    @State private var showContact = false
    /// แผ่นตรวจสอบ "Verified by Sale Here" — เปิดจากแถบหน้าดู หรือจากการแตะ widget ตรารับรอง
    @State private var showVerify = false
    /// ทางออกสำรองสำหรับลิงก์ที่ `SFSafariViewController` เปิดไม่ได้ (ไม่ใช่ http/https)
    @Environment(\.openURL) private var openURL
    /// ความสูงของคีย์บอร์ดที่บังจออยู่
    @State private var keyboard: CGFloat = 0

    // การปรับขนาด
    @State private var resizeID: UUID?
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
    /// ขนาดตัวอักษรตอนเริ่มลากหมุดมุมของก้อนข้อความ — ลากคิดเป็นสัดส่วนจากค่านี้
    @State private var resizePoints: CGFloat = 0
    /// ข้ามการบันทึกประวัติหนึ่งรอบ — ใช้ตอน เสร็จ ซึ่งบันทึกไว้แล้วตั้งแต่ตอนเข้าโหมดพิมพ์
    @State private var skipHistory = false

    /// ความสูงของหน้าต่างที่แอปอยู่ — กรอบคีย์บอร์ดที่ระบบส่งมาอยู่ในพิกัดจอ
    /// ต้องเทียบกับความสูงจริงของหน้าต่าง ไม่ใช่ `viewportH` ที่หักแถบระบบไปแล้ว
    private static func windowHeight() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .frame.height ?? 0
    }

    /// โหมดโชว์รูม — **เฉพาะตอนพิมพ์ก้อนข้อความ**
    ///
    /// เคยใช้กับทุกชิ้นที่กำลังแต่ง (ซ่อนที่เหลือ ยกตัวเดียวขึ้นกลางจอ) แล้วมันขัดกับ
    /// หมุดปรับขนาดและการลาก ซึ่งต้องเห็นเพื่อนบ้าน · ตอนนี้แตะชิ้น = ทุกอย่างอยู่ที่เดิม
    /// เหลือโชว์รูมไว้ที่เดียวคือตอนคีย์บอร์ดขึ้น — ก้อนที่พิมพ์อยู่ต้องมายืนกลางที่ว่างเหนือคีย์บอร์ด
    private var showroomID: UUID? {
        guard dragID == nil, case .text(let id) = dock else { return nil }
        return id
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
        // **ไม่ใช้ scale** — ตอนพิมพ์กล่องถูกวาดที่ขนาดแก้ไขตรง ๆ (ดู `drawnSize`) ตัวอักษรจึงคม
        // ไม่ใช่ตัวเล็กที่ถูกขยายด้วย transform จนเบลอ · กลางทั้งสองแกนของ **กล่องที่วาดจริง**
        let d = drawnSize(p)
        return (1,
                pageSize.width / 2 - (p.frame.minX + d.width / 2),
                band / 2 - (p.frame.minY + d.height / 2))
    }

    /// ขนาดที่วาดจริงของ tile — ก้อนข้อความที่กำลังพิมพ์ใช้กล่องขนาดแก้ไข ที่เหลือใช้กรอบจากผัง
    private func drawnSize(_ p: Placed) -> CGSize {
        dock == .text(p.id) ? editBox(p).box : p.frame.size
    }

    /// กล่องตอนพิมพ์ — ตัวอักษรที่ **ขนาดแก้ไขมาตรฐานเดียวกันทุกก้อน** (`TextFit.editSize`)
    ///
    /// บน Story แตะข้อความไหนก็ได้ขนาดแก้ไขเท่ากันหมด — ก้อนที่ย่อไว้จิ๋วบนการ์ดไม่ต้องมาพิมพ์ตัวจิ๋ว
    /// ขนาดที่ตั้งไว้ (`points`) มีผลบนการ์ดเท่านั้น กด เสร็จ แล้วค่อยกลับไปขนาดนั้น
    /// บรรทัดยาวเกินหน้าหดให้ชั่วคราวเหมือนบนการ์ด · กล่องหุ้มตัวอักษรพอดีด้วยขอบเท่ากับบนการ์ด
    /// อ่าน `Profile.me.note` สด ๆ — พิมพ์ตัวอักษรใหม่กล่องจึงโตตามในเฟรมเดียวกัน
    private func editBox(_ p: Placed) -> (points: CGFloat, box: CGSize, m: TextFit.Metrics) {
        let st = p.item.textStyle
        let raw = Profile.me.note(p.item.id)
        let text = raw.isEmpty || raw == Profile.notePlaceholder ? "พิมพ์ข้อความ" : raw
        let maxW = PageLayout.content(pageSize).width - TextBlock.inset * 2
        let pts = TextFit.capped(TextFit.editSize, text, face: st.face, weight: TextBlock.weight, maxWidth: maxW)
        let m = TextFit.metrics(text, face: st.face, weight: TextBlock.weight, size: pts, align: st.align)
        return (pts, CGSize(width: min(m.ink.width, maxW) + TextBlock.inset * 2,
                            height: m.ink.height + TextBlock.inset * 2), m)
    }

    /// มุมของกรอบชิ้น — ก้อนข้อความมุมเล็ก (กล่องหุ้มตัวอักษรพอดี มุมมนใหญ่จะกินมุมตัวอักษร)
    private func chromeRadius(_ kind: WidgetKind) -> CGFloat {
        kind == .textBlock ? min(theme.radius, TextBlock.radius) : theme.radius
    }

    init(viewOnly: Bool = false, cardID: String? = nil, discardIfUntouched: Bool = false,
         format: CardFormat = .portfolio, onChangeFormat: (() -> Void)? = nil,
         onClose: (() -> Void)? = nil) {
        self.viewOnly = viewOnly
        self.onClose = onClose
        self.cardID = cardID
        self.discardIfUntouched = discardIfUntouched
        self.onChangeFormat = onChangeFormat
        // เปิดจากคลัง = โหลดใบนั้นทั้งดุ้นตั้งแต่ init — ไม่มีจังหวะที่หน้าตั้งต้นแวบขึ้นก่อน
        if let cardID, let record = CardLibrary.shared.card(id: cardID),
           let restored = record.restored() {
            self.format = record.format
            _pages = State(initialValue: restored.pages)
            _theme = State(initialValue: restored.theme)
            _index = State(initialValue: restored.index)
        } else {
            self.format = format
            var starter = format.starterPages
            PinnedSeal.ensure(&starter, format: format)
            _pages = State(initialValue: starter)
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
            // พื้นที่ที่เหลือหลังเว้นแถบบนกับแถวล่าง
            //
            // พอร์ตเอาขนาดนี้ไปใช้ตรง ๆ · สตอรี่ไม่สนใจมันเลย (หน้าเป็น 540×960 เสมอ)
            // แล้วใช้กล่องนี้แค่คำนวณว่าต้องย่อเท่าไหร่ถึงจะพอดีจอเครื่องนี้
            //
            // **ห้ามหักความสูงของแถบล่างออกจากกล่องนี้** — ความสูงหน้าพอร์ตในหน่วยออกแบบ
            // มาจากกล่องนี้โดยตรง หักเมื่อไหร่หน้าจะสั้นลงแล้วของ 36 แถวของหน้าตั้งต้นล้นทันที
            // แถบล่างจัดการด้วยการ **ย่อ** (`editScale`) ไม่ใช่การเปลี่ยนขนาดหน้า
            let box = CGSize(width: geo.size.width,
                             height: geo.size.height - 74 - 34)
            let size: CGSize = format.pageSize(in: box)
            let fit: CGFloat = format.fit(in: box)

            ZStack {
                // หน้ามีขนาดตายตัวแล้ว จึงไม่มีทางเท่าจอทุกเครื่องพอดี — ที่ว่างรอบตัว
                // ต้องอ่านออกว่า **นอกเฟรม** ไม่ใช่ส่วนของการ์ดที่ยังว่างอยู่
                // ฉากหลังของธีมจึงถูกหุบเข้าไปในหน้า (ดู `.background` ของ deck)
                // แล้วรอบนอกเป็นเวทีมืดเหมือนหน้าตัวอย่างก่อนแชร์
                // เวทีมืดของแบรนด์ — ลายน้ำลายจาง ๆ คือลายเซ็นของสถานที่ ไม่ใช่ของการ์ด (ดู `Signature`)
                ZStack {
                    Color(white: 0.06)
                    SignaturePattern(opacity: viewOnly ? 0.065 : 0.04)
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // ช่องว่างใต้แถบบน **อยู่นอกก้อนที่ถูกย่อ** — ถ้าย่อไปด้วย หัวการ์ดจะขยับขึ้น
                    // ไปมุดใต้แถบบนทุกครั้งที่ถาดเปิด (74 × 0.5 = เหลือแค่ 37pt)
                    Color.clear.frame(height: 74 + verifyBandSpace)
                    VStack(spacing: 0) {
                        // กริดเป็น "พื้นของหน้ากระดาษ" ไม่ใช่ชั้นลอยแยก — จุดจึงอยู่พิกัดเดียวกับ widget เป๊ะ
                        deck(size: size, fit: fit, viewport: geo.size)
                        Color.clear.frame(height: 34)
                    }
                    // ย่อให้พอดีช่องเหนือแถบล่าง — **ย่ออย่างเดียว ไม่มีการดันขึ้น**
                    // หัวการ์ดอยู่ที่เดิมตลอด ไม่ว่าจะเลือกชิ้นไหนหรือถาดสูงแค่ไหน
                    //
                    // ใช้ `editScale` ล้วน ไม่ใช่ `canvasScale` — การย่อจากหน่วยออกแบบลงหน่วยจอ
                    // `deck` ทำไปแล้วข้างใน ถ้าคูณซ้ำตรงนี้การ์ดจะเล็กลงสองรอบ
                    .scaleEffect(isEditing ? editScale : viewScale, anchor: .top)
                    // พิธีเปิดของหน้าดู — การ์ดเลื่อนขึ้นมาวางบนเวทีด้วยสปริงเดียวกับที่มันถูกยกตอนลาก
                    .scaleEffect(viewOnly && !dealt ? 0.94 : 1, anchor: .center)
                    .offset(y: viewOnly && !dealt ? 44 : 0)
                    .opacity(viewOnly && !dealt ? 0 : 1)
                    // เปลี่ยนโหมด = การ์ดย่อ/ขยายด้วยสปริงเดียวกับถาด · ส่วนค่าที่วัดจากถาด (`bottomUI`)
                    // ไม่ต้องอนิเมตซ้ำ มันเดินตามถาดเฟรมต่อเฟรมอยู่แล้ว
                    .animation(Motion.settle, value: dock)
                    .animation(Motion.settle, value: keyboard)
                }

                // เงาไล่ใต้แถบบน — การ์ดที่ถูกดันขึ้นไปมุดใต้แถบบน (ตอนชิ้นที่เลือกอยู่ล่าง ๆ)
                // ต้องอ่านเป็น "เลื่อนพ้นขอบ" ไม่ใช่ "ซ้อนกับปุ่ม"
                VStack(spacing: 0) {
                    LinearGradient(colors: [Color(white: 0.06), Color(white: 0.06).opacity(0)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 118)
                        .ignoresSafeArea(edges: .top)
                        .allowsHitTesting(false)
                    Spacer(minLength: 0)
                }

                // ตอนพิมพ์ แถบบนหลบ — ↶ ↷ แชร์ ไม่ใช่ของที่ใครกดระหว่างพิมพ์ และตาต้องอยู่ที่ตัวอักษร
                // เหลือ "เสร็จ" มุมขวาบนตัวเดียว ที่เดียวกับ Done ของ IG
                if dock.isText { textTopBar.transition(.opacity) } else { topBar.transition(.opacity) }

                // ข้อความบอกเหตุหลบตอนพิมพ์ด้วย — บนหน้าที่หรี่ทั้งหน้า มันคือของชิ้นเดียวที่สว่างแข่งกับตัวอักษร
                if !dock.isText { noticeBar }

                // แถบล่างทั้งก้อน — dock + ถาด หรือแผ่นพิมพ์เหนือคีย์บอร์ด
                // อยู่นอกแคนวาสที่ถูกย่อ/ดัน จึงไม่ขยับตามการ์ด
                if isEditing {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        bottomChrome
                    }
                }

                // โหมดจัดรูป: ทั้งจอคือที่จับรูป — ทับถาดด้วย (ช่วงนี้มีท่าเดียวคือเล็งรูป)
                if isEditing, photos.framing != nil {
                    PhotoFitCatcher(theme: theme, scale: canvasScale)
                        .transition(.opacity)
                }

                // แถบ Verified ของหน้าดู — ใต้แถบบน นอกตัวการ์ด (ดู `VerifiedBand`)
                if verifyBandSpace > 0 {
                    VStack(spacing: 0) {
                        VerifiedBand { showVerify = true }
                            .padding(.horizontal, 20)
                            .padding(.top, 66)
                        Spacer(minLength: 0)
                    }
                    .opacity(stripIn ? 1 : 0)
                    .offset(y: stripIn ? 0 : -10)
                }

                // ท้ายหน้าดู — โครงของเวที (ดู `viewerFooter`)
                if viewOnly {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        viewerFooter
                    }
                    .opacity(stripIn ? 1 : 0)
                    .offset(y: stripIn ? 0 : 16)
                }
            }
            .animation(Motion.settle, value: keyboard)
            .onAppear { viewportH = geo.size.height; safeBottom = geo.safeAreaInsets.bottom }
            .onChange(of: geo.size.height) { _, h in viewportH = h }
            .onAppear {
                pageSize = size; pageFit = fit; viewportW = geo.size.width
                // ก้อนข้อความจากไฟล์รุ่นก่อนยังมีกล่องขนาดตามใจ — จัดให้พอดีตัวอักษรตั้งแต่เปิด
                // (ไม่นับเป็นจังหวะแก้ไข — ผู้ใช้ยังไม่ได้ทำอะไร ↶ ต้องไม่มีอะไรให้ย้อน)
                if isEditing {
                    skipHistory = true
                    for id in pages.flatMap(\.items).filter({ $0.kind == .textBlock }).map(\.id) {
                        fitTextBlock(id)
                    }
                    DispatchQueue.main.async { skipHistory = false }
                }
                resolve()
            }
            .onChange(of: size) { _, s in pageSize = s; resolve() }
            .onChange(of: fit) { _, f in pageFit = f }
            .onChange(of: geo.size.width) { _, w in viewportW = w }
            .onAppear {
                guard isEditing else { return }
                // เขียนใบกลับทันทีที่เปิด — ใบจากไฟล์รุ่นก่อนไม่มี id ของชิ้น (ดู `CardSnapshot.Item.id`)
                // ต้องได้ id ลงไฟล์ก่อนที่ผู้ใช้จะพิมพ์อะไรผูกกับมัน
                persist()
                if let c = theme.customColor { myColor = c }
                hintOnce("dock", "แตะชิ้นบนการ์ดเพื่อแก้ · ปุ่มข้างล่างไว้เปลี่ยนพื้นหลังหรือเพิ่มของ")
                // กรอบเส้นประเข้มขึ้นตอนเข้า แล้วคลายลงเองใน 1.6 วิ
                // จังหวะเข้าคือจังหวะเดียวที่สายตายังไม่รู้ว่าต้องมองอะไร ต้องดังตรงนั้น
                // แล้วเบาลง ไม่งั้นเส้นประเข้ม ๆ รอบทุกชิ้นจะแย่งความสนใจกับงานที่กำลังแต่ง
                editReveal = true
                revealTask?.cancel()
                revealTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.6))
                    guard !Task.isCancelled else { return }
                    withAnimation(Motion.settle) { editReveal = false }
                }
            }
            .onChange(of: dock) { _, d in
                // ทางออกของการยืดที่ไม่ได้มาจากการปล่อยนิ้ว — ดู `endResize`
                endResize()
                // กติกาเหล็ก: **ช่องพิมพ์มีอยู่ได้เฉพาะตอนมีชิ้นที่เลือกอยู่**
                //
                // ทางออกจากชิ้นมีหลายทาง (‹ · แตะที่ว่าง · ลบ · เปลี่ยนหน้า) ถ้าให้แต่ละทางจำเอง
                // ว่าต้องเก็บช่องพิมพ์ด้วย สักวันจะมีทางที่ลืม แล้วคีย์บอร์ดค้างทับการ์ด
                if d.selectedID == nil { endTextEdit() }
            }
            .onChange(of: index) { _, _ in
                // เปลี่ยนหน้าเพราะลาก widget ข้ามหน้า — ตัวที่ลากยังต้องถูกเลือกอยู่
                if dragID == nil {
                    switch dock {
                    case .text: exitTextMode()
                    case .piece: withAnimation(Motion.settle) { dock = .main }
                    default: break
                    }
                }
                resolve()
                persist()
            }
            .onChange(of: theme) { old, new in
                touched = true
                remember(pages: pages, theme: old, changedTheme: new)
                persist()
            }
            .onChange(of: pages) { old, new in
                touched = true
                remember(pages: old, theme: theme, changedPages: new)
                persist()
                // ระหว่างยืดขนาด ใช้สปริงที่ตอบไว — Motion.flow นุ่มเกินไป
                // ขอบ widget จะรั้งอยู่หลังนิ้วครึ่งวินาที อ่านออกมาเป็น "ไม่ติดนิ้ว"
                withAnimation(resizeID == nil ? Motion.flow : Motion.snap) { resolve() }
            }
            .onChange(of: LabSync.shared.remoteStamp) { _, _ in reloadFromLab() }
            .animation(Motion.settle, value: editReveal)
            .onAppear {
                guard viewOnly else { return }
                // แจกการ์ดลงเวที แล้วค่อยให้แถบผู้ออกบัตรกับท้ายหน้าตามมา — ลำดับเดียวกันทุกใบ
                withAnimation(Motion.settle.delay(0.08)) { dealt = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    withAnimation(Motion.settle) { stripIn = true }
                }
            }
        }
        // ปิดการหลบคีย์บอร์ดอัตโนมัติของ SwiftUI — มันดันทั้งจอขึ้นรวมแถบบนกับจุดบอกหน้า
        // การ์ดจึงถูกยกออกนอกจอครึ่งใบ · ก้อนที่พิมพ์อยู่ถูกพาขึ้นมาเองที่ `showroom` แทน
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
        // พิมพ์ผิดแล้วดีดกลับไปสีจริง — ตรงกว่าการขึ้นข้อความเตือนที่ต้องอ่านแล้วแก้เอง
        .alert("สีพื้น", isPresented: $hexPrompt) {
            TextField(theme.backdropHex, text: $hexDraft)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            // พิมพ์ผิดแล้วไม่มีอะไรเกิดขึ้น สีเดิมอยู่ครบ — ไม่ต้องมีข้อความเตือนให้ต้องปิดอีกชั้น
            Button("ใช้สีนี้") {
                if theme.setBackdropHex(hexDraft) { myColor = theme.customColor }
            }
            Button("ยกเลิก", role: .cancel) {}
        } message: {
            Text("พิมพ์รหัสสีหกหลัก เช่น #F11717")
        }
        // เบราว์เซอร์ในแอป — ทั้งใบเต็มจอเหมือน Safari ที่ผู้ใช้คุ้นอยู่แล้ว
        // ไม่ทำเป็นชีตครึ่งจอเพราะหน้าโปรไฟล์กับหน้ารีวิวคือของที่ต้อง "อ่าน" ไม่ใช่ของที่แค่ชำเลือง
        .sheet(isPresented: $showContact) {
            ContactSheet { url in
                showContact = false
                // รอชีตลงก่อน — เบราว์เซอร์ในแอปเปิดทับชีตที่กำลังปิดไม่ขึ้น
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { open(url) }
            }
            .presentationDetents([.height(214)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(white: 0.09))
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showVerify) {
            VerifySheet(slug: invocation.slug)
                .presentationDetents([.height(VerifySheet.height)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(white: 0.09))
                .preferredColorScheme(.dark)
        }
        .fullScreenCover(item: $link) { target in
            SafariSheet(url: target.url, tint: theme.accent)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showPreview) {
            CardSharePreview(pages: pages, theme: theme, pageSize: pageSize, format: format)
                .environment(photos)
                .environment(invocation)
        }
        .alert("ใบนี้ปลดล็อกเมื่อทำงานกับ Sale Here", isPresented: $askJobs) {
            Button("ดูงานที่เปิดรับ") { StarFlow.shared.jobsRequested = true }
            Button("ไว้ก่อน", role: .cancel) {}
        } message: {
            Text("โลโก้แบรนด์และผลงานยืนยันมาจากงานที่ทำจบผ่าน Sale Here เท่านั้น รับงานแรกแล้วใบพวกนี้จะเปิดเอง")
        }
        .fullScreenCover(item: $topicFill) { req in
            StarTopicFill(steps: [req.topic.step]) { done in
                topicFill = nil
                guard done, req.topic.filled, req.place else { return }
                // กรอกครบแล้ว = ใบที่แตะไว้ใช้ได้ทันที วางลงการ์ดให้เลย ไม่ต้องกลับไปหาในตู้อีก
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { _ = addWidget(req.kind) }
            }
            .environment(photos)
        }
    }

    // MARK: - ประวัติ ↶ ↷

    /// บันทึกจังหวะแก้ไขลงประวัติ — ข้ามค่าที่เพิ่งกู้คืนมาเอง (ไม่งั้น ↶ จะสร้างจังหวะใหม่ซ้อน)
    private func remember(pages: [CardPage], theme: CardTheme,
                          changedPages: [CardPage]? = nil, changedTheme: CardTheme? = nil) {
        // ระหว่างพิมพ์กล่องขยับทุกตัวอักษร — ทั้งรอบนับเป็นจังหวะเดียว (บันทึกไว้แล้วที่ `enterTextMode`)
        if dock.isText || skipHistory { return }
        if let a = applied {
            if let p = changedPages, p == a.pages { return }
            if let t = changedTheme, t == a.theme { return }
        }
        history.record(.init(pages: pages, theme: theme))
    }

    private func undo() {
        guard let s = history.undo(current: .init(pages: pages, theme: theme)) else { Haptics.rigid(); return }
        apply(s)
    }

    private func redo() {
        guard let s = history.redo(current: .init(pages: pages, theme: theme)) else { Haptics.rigid(); return }
        apply(s)
    }

    /// กู้คืนภาพนิ่ง — ของบนการ์ดไหลกลับด้วย `flow` ผู้ใช้จึงเห็นว่าอะไรเปลี่ยน ไม่ใช่กระพริบเป็นภาพใหม่
    private func apply(_ s: EditHistory.Snapshot) {
        applied = s
        endTextEdit()
        withAnimation(Motion.flow) {
            pages = s.pages
            theme = s.theme
            index = min(index, max(0, s.pages.count - 1))
            // ชิ้นที่เลือกอยู่อาจไม่มีในภาพนิ่งนั้น (ย้อนการเพิ่ม) — แถบล่างต้องไม่ชี้ไปที่ของที่หายไป
            if let id = selected, !s.pages.contains(where: { $0.items.contains { $0.id == id } }) {
                dock = .main
            }
        }
        Haptics.impact(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { applied = nil }
    }

    /// โหมดลองทำ: อีกเครื่องแก้การ์ดใบนี้ — โหลดผังใหม่จากคลัง ไม่นับเป็นงานแก้ของเครื่องนี้ (ไม่เข้า undo)
    private func reloadFromLab() {
        guard let cardID, cardID == LabSync.shared.cardID,
              let record = CardLibrary.shared.card(id: cardID),
              let r = record.restored() else { return }
        skipHistory = true
        endTextEdit()
        withAnimation(Motion.flow) {
            pages = r.pages
            theme = r.theme
            index = min(index, max(0, r.pages.count - 1))
            if let id = selected, !r.pages.contains(where: { $0.items.contains { $0.id == id } }) {
                dock = .main
            }
        }
        DispatchQueue.main.async { skipHistory = false }
    }

    /// ตู้วิดเจ็ตในถาด — ความสูงมาจากระดับของชีต (ลากได้ ตั้งต้นครึ่งจอ) ตัวตู้เลื่อนเองข้างใน
    private var galleryTray: some View {
        VStack(spacing: 12) {
            // บอกตั้งแต่เปิดตู้ ไม่ใช่รอให้เลือกจนจบแล้วค่อยปฏิเสธ — คนเลื่อนหาของในตู้นี้
            // เป็นนาที การให้เขาทำงานจนจบแล้วบอกว่า "ไม่ได้" คือการเสียเวลาที่กันได้ตั้งแต่ต้น
            if cardIsFull { galleryFullBanner }
            WidgetGallery(theme: theme.toolTheme, onAdd: { kind in
                _ = addWidget(kind)
            }, onFill: { kind, topic in
                // ยังไม่มีข้อมูลของหัวข้อนั้น → พาไปกรอกข้อเดียว กรอกเสร็จค่อยวางใบที่เลือกไว้ให้
                // ยกเว้นผลงานกับ Sale Here: กรอกเองไม่ได้ ต้องไปรับงาน
                if topic.fillable { topicFill = TopicFillRequest(kind: kind, topic: topic) } else { askJobs = true }
            }, onClose: nil, showsBar: false)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .environment(photos)
    }

    @Environment(PhotoStore.self) private var photos
    @Environment(ClipInvocation.self) private var invocation

    // MARK: - Deck

    /// สำรับ = **กระดาษแผ่นเดียวยาว 3 ช่อง** — ปัดแล้วทั้งแผ่นเลื่อน ไม่ใช่การ์ดสามใบสไลด์แยกกัน
    ///
    /// # ทำไมเลิกทำเป็นสไลด์
    ///
    /// เดิมแต่ละหน้าเป็นแผ่นของตัวเอง มีร่อง 26pt คั่น บีบ/พารัลแลกซ์ตอนปัด — สวยแต่มันบอกผู้ใช้ว่า
    /// "นี่คือการ์ดสามใบ" ทั้งที่รูปที่แชร์ออกไปคือแถบยาวใบเดียว (ดู `CardA4Export`) คนจึงจัดหน้าแรก
    /// จนจบในตัว แล้วงงว่าทำไมรูปแชร์มีที่ว่างอีกสองช่อง
    ///
    /// ตอนนี้ฉากหลังวาดครั้งเดียวคลุมทั้งแผ่นเหมือนรูปที่แชร์ ช่องต่อกันไม่มีร่อง · ปัดแล้วแผ่นเลื่อน
    /// เป็นชิ้นเดียวด้วยสปริง `Motion.page` — ซ้ายสุด → กลาง → ขวาสุดของกระดาษ แล้วชนขอบ (หน่วงยาง)
    /// ตอนแต่งแผ่นถูกย่อลงนิดหนึ่ง (ดู `editScale`) ขอบของช่องข้าง ๆ จึงโผล่ให้เห็นตลอดว่ามันต่อกันอยู่
    /// และแตะขอบที่โผล่นั้นได้ = เลื่อนไปช่องนั้น
    private func deck(size: CGSize, fit: CGFloat, viewport: CGSize) -> some View {
        let shown = CGSize(width: size.width * fit, height: size.height * fit)
        let inv: CGFloat = 1 / max(fit, 0.01)
        let strip = CGSize(width: size.width * CGFloat(max(pages.count, 1)), height: size.height)
        let paper = RoundedRectangle(cornerRadius: 22 * inv, style: .continuous)
        return ZStack(alignment: .topLeading) {
            // ชั้นรับ "แตะที่ว่าง" อยู่ **หลัง** ทุกชิ้น ไม่ใช่ท่าแตะบนตัวห่อทั้งสำรับ
            //
            // ท่าแตะบนตัวห่อ (ancestor) ยิงทุกครั้งที่นิ้วแตะชิ้นด้วย — ยิงก่อนตัวจับทัชของชิ้นเสียอีก
            // ผลคือทุกแตะบนชิ้นกลายเป็น "ยกเลิกเลือก แล้วเลือกใหม่" · แตะซ้ำเพื่อพิมพ์จึงไม่มีวันถึง
            // ชั้นที่อยู่ข้างหลังได้ทัชเฉพาะจุดที่ไม่มีชิ้นไหนรับ ซึ่งคือความหมายของ "ที่ว่าง" พอดี
            emptyTapLayer.frame(width: strip.width, height: strip.height)

            // ทุกช่องอยู่ในต้นไม้ view ตลอด — แผ่นเดียวต้องครบทุกส่วนระหว่างเลื่อน
            // (และ gesture ที่ถือการลากข้ามช่องอยู่ก็ไม่ตายกลางทางเพราะช่องต้นทางถูกถอด)
            ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                // `current` = ช่องนี้คือช่องปัจจุบัน · `interactive` = รับ touch ได้ (ปิดระหว่างปัด กันไปโดน widget)
                // ไม่มีระยะหน้า/พารัลแลกซ์อีกแล้ว — กระดาษแผ่นเดียวเลื่อนทั้งแผ่น ของบนแผ่นไม่ขยับแยกกัน
                sheet(page, size: size,
                      current: i == index,
                      dist: 0,
                      interactive: i == index && abs(swipe) < 0.02,
                      parallax: 0)
                    .background {
                        // กริดต่อช่อง — ตอนพิมพ์ (โชว์รูม) กริดคือบริบทของ "ทั้งแผ่น" ซึ่งตอนนั้นซ่อนอยู่
                        if isEditing, showroomID == nil {
                            CanvasGrid(theme: theme, ink: theme.inkStyle, page: size)
                                .frame(width: size.width, height: size.height)
                        }
                    }
                    // ช่องข้าง ๆ ที่โผล่ให้เห็น แตะแล้วเลื่อนไปช่องนั้น — ของที่เห็นต้องไปถึงได้ ไม่ใช่แค่ดู
                    .overlay {
                        if i != index {
                            Color.clear.contentShape(Rectangle())
                                .onTapGesture {
                                    guard dragID == nil else { return }
                                    Haptics.impact(.light)
                                    withAnimation(Motion.page) { index = i }
                                }
                        }
                    }
                    .frame(width: size.width, height: size.height)
                    .offset(x: CGFloat(i) * size.width)
                    // ช่องปัจจุบันอยู่บนสุด — หมุดกับปุ่มมุมที่ยื่นพ้นขอบช่องต้องไม่มุดใต้ช่องถัดไป
                    .zIndex(i == index ? 1 : 0)
            }
        }
        .frame(width: strip.width, height: strip.height, alignment: .topLeading)
        // ฉากหลัง **ผืนเดียวคลุมทั้งแผ่น** — ไล่เฉด/ดวงแสง/รูป ต่อเนื่องข้ามช่องเหมือนรูปที่แชร์
        // มุมและเงาถูกวาดในหน่วยออกแบบแล้วย่อลงพร้อมทั้งผืน — หารกลับด้วย fit
        // เพื่อให้ **ที่ตาเห็นบนจอ** คงที่ ไม่ใช่โตขึ้นตามพื้นที่ออกแบบ
        .background {
            CardBackdrop(theme: theme, ignoreSafeArea: false, signed: true)
                .frame(width: strip.width, height: strip.height)
                .clipShape(paper)
                .shadow(color: .black.opacity(0.5), radius: 26 * inv, y: 12 * inv)
        }
        // ตราปั๊มนูนกดลงบนแผ่นที่พิมพ์เสร็จแล้ว — เหนือ widget ทุกชิ้น ไม่กินทัช (ดู `SignatureEmboss`)
        .overlay {
            if theme.strip.isStamp {
                SignatureEmboss(light: theme.inkStyle.isLight, foil: theme.strip == .foil,
                                tint: theme.inkStyle.base, pages: pages, pageSize: size)
                    .frame(width: strip.width, height: strip.height)
            }
        }
        // เลื่อนทั้งแผ่นให้ช่องปัจจุบันมาอยู่ในหน้าต่าง — `swipe` คือเศษระหว่างทางตอนนิ้วยังลากอยู่
        .offset(x: -(CGFloat(index) + swipe) * size.width)
        // หน้าต่างเท่า **หนึ่งช่อง** พอดี — ไม่ clip แผ่นที่ยาวเกิน ส่วนที่ล้นคือขอบช่องข้าง ๆ ที่ตั้งใจให้เห็น
        //
        // ชั้นลอยข้างล่างอ้างมุมบนซ้ายของหน้าต่างนี้ และ `dragStart` เป็นพิกัดในช่อง —
        // ถ้ามุมนี้ไม่ใช่มุมช่อง ตัวที่ลากจะลอยเยื้องจากนิ้ว
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .overlay(alignment: .topLeading) {
            // ชั้นลอยของตัวที่ลาก — อยู่ระดับหน้าต่าง ไม่ผูกกับช่องใดช่องหนึ่ง จึงลอยข้ามช่องได้
            if dragID != nil, let item = dragItem {
                dragLayer(Placed(item: item, frame: dragStart))
            }
        }
        // ย่อพื้นที่ออกแบบทั้งผืนลงหน่วยจอ
        //
        // **ต้องยึดจุดกึ่งกลาง** ไม่ใช่ยึดหัว: `scaleEffect` ไม่แตะ layout ก้อนนี้จึงยังจองที่
        // เท่าหน่วยออกแบบ (540×960) แล้ว `.frame` บรรทัดถัดไปจัดมันไว้ *กึ่งกลาง* กรอบที่เล็กกว่า
        // ถ้าสเกลยึดหัว จุดอ้างอิงสองอันนี้จะคนละจุด แล้วการ์ดจะเลื่อนขึ้นไปพ้นกรอบของตัวเอง
        .scaleEffect(fit)
        // บอกขนาด **ที่ตาเห็น** เอง ไม่งั้นก้อนนี้ดันทุกอย่างรอบตัวออกนอกจอ
        .frame(width: shown.width, height: shown.height)
        // ชั้นนอกกินเต็มพื้นที่ — เวทีมืดรอบหน้าก็นับเป็นที่ว่าง (ชั้นรับแตะอีกใบอยู่ข้างหลังหน้า)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { emptyTapLayer }
        // หมึกของการ์ดครอบทั้งสำรับ — ทั้ง widget · เปลือกแผ่น · เส้นเลือก
        // ไม่ครอบไปถึงแถบเครื่องมือกับชีตแต่ง เพราะนั่นคือ "เครื่องมือ" ไม่ใช่ "ชิ้นงาน"
        // (แคนวาสขาวบนหน้าจอมืดแบบ Figma — ตาจะแยกออกทันทีว่าอะไรคืองาน อะไรคือปุ่ม)
        .environment(\.cardInk, theme.inkStyle)
        // ก้อนข้อความต้องรู้ว่าหน้ากว้างเท่าไหร่ — บรรทัดที่ยาวเกินนั้นหดขนาดให้เอง
        .environment(\.pageContentWidth, PageLayout.content(size).width)
        .simultaneousGesture(pageSwipe(width: size.width))
    }

    /// กติกาข้อ 4: **แตะที่ว่าง = ‹** ปิดสิ่งที่เปิดอยู่ กลับแถบหลัก
    /// ตอนพิมพ์ = เสร็จ (ท่าปิดคีย์บอร์ดที่ทุกคนคาดหวัง) — ความหมายเดียวกันคือ "จบสิ่งที่ทำอยู่"
    private var emptyTapLayer: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                guard isEditing else { return }
                if dock.isText { exitTextMode() } else { goMain() }
            }
    }

    private func pageSwipe(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { g in
                // การ์ดหน้าเดียวไม่มีหน้าให้ไป — ถ้าไม่กันตรงนี้ การปัดจะได้แค่
                // หน่วงยางที่เด้งกลับ ซึ่งอ่านออกว่า "มีหน้าถัดไปแต่ไปไม่ได้"
                guard multiPage, dragID == nil, resizeID == nil else { return }
                // ยังไม่ติดแนวนอน = ต้องชัดว่าปัดซ้ายขวา ไม่ใช่แค่เอียงนิดหน่อยระหว่างลากลง
                if !swipeArmed {
                    guard abs(g.translation.width) > abs(g.translation.height) * 1.2 else { return }
                    swipeArmed = true
                }
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
                let armed = swipeArmed
                swipeArmed = false
                guard armed, multiPage, dragID == nil, resizeID == nil else {
                    withAnimation(Motion.page) { swipe = 0 }
                    return
                }
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
                    .allowsHitTesting(false)
            }

            ForEach(solved) { p in
                tile(p, on: page, current: current, dist: dist, interactive: interactive,
                     parallax: parallax, pageWidth: size.width)
            }

            // แถบผู้ออกบัตรถูกถอดออกจากการ์ดแล้ว (ตัววิว `IssuerStrip` ยังอยู่ในโค้ด)
            // ก้นหน้าที่เคยกันไว้ให้มัน 30pt กลายเป็นพื้นที่วางของตามปกติ (ดู `PageLayout.content`)

            // ม่านกระจกตอนพิมพ์ — ทั้งหน้ากลายเป็นกระจกฝ้า เหลือก้อนที่พิมพ์อยู่ชิ้นเดียวที่คมชัด
            //
            // เดิมแค่หรี่ชิ้นอื่นลง แต่ฉากหลังของการ์ด (รูป · ไล่เฉด) ยังอยู่เต็ม ๆ ใต้ตัวอักษร
            // ตัวอักษรขาวบนรูปที่หรี่ครึ่งหนึ่งอ่านยากกว่าบนกระจก — และมันอ่านเป็น "การ์ดพัง" ไม่ใช่ "โหมดพิมพ์"
            // กระจกอยู่ **ใต้** ก้อนที่พิมพ์ (zIndex 300 < 400) แต่ **เหนือ** ทุกอย่างที่เหลือ
            if current, showroomID != nil {
                typingVeil
                    .frame(width: size.width, height: size.height)
                    .zIndex(300)
                    .transition(.opacity)
            }

            // กรอบเลือกอยู่ชั้นบนสุดของหน้า ไม่ใช่ติดไปกับตัว widget
            // ของทับกันได้แล้ว ถ้าวาดตามชั้นซ้อนจริง หมุดปรับขนาดจะถูกตัวที่อยู่หน้ากว่าทับจนกดไม่ได้
            // ตอนพิมพ์ (โชว์รูม) ไม่มีกรอบกับหมุด — ก้อนถูกยกขึ้นกลางจอ กรอบจะอ่านเป็นของที่ต้องลาก
            if isEditing, current, dragID == nil, showroomID == nil,
               let sel = solved.first(where: { $0.id == selected }) {
                selectionLayer(sel, interactive: interactive)
                    // ยืดเฉพาะกรอบ ไม่แตะตัว widget — นี่คือ "ไปแค่กรอบ" ที่ตั้งใจ
                    .frame(width: sel.frame.width + (resizeID == sel.id ? overshoot.width : 0),
                           height: sel.frame.height + (resizeID == sel.id ? overshoot.height : 0),
                           alignment: .topLeading)
                    // กรอบเลือก/หมุด/ปุ่มประแจ ต้องถูกท่าโชว์รูมพาไปพร้อมตัว widget
                    // ไม่งั้นมันค้างอยู่ที่ตำแหน่งเดิมแล้วชี้ไปยังที่ว่าง
                    .scaleEffect(showroomScale(sel), anchor: .center)
                    .offset(x: sel.frame.minX - parallaxShift(sel.item, parallax: parallax,
                                                              pageWidth: size.width)
                               + showroom(sel).dx,
                            y: sel.frame.minY + showroom(sel).dy)
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
        // โหมดดู: widget นิ่งสนิท กดแล้วไปปลายทางอย่างเดียว — ไม่เอียงตามนิ้ว ไม่เรืองแสง
        let touch = (isEditing && pressPoint?.id == p.id && dragID == nil) ? pressPoint?.at : nil

        // ก้อนข้อความที่กำลังพิมพ์วาดที่ **ขนาดแก้ไขมาตรฐาน** ไม่ใช่ขนาดบนการ์ด (ดู `editBox`)
        // กรอบจากผังยังเป็นของเดิม — มันคือที่ที่กล่องจะไหลกลับไปตอนกด เสร็จ
        let drawn = drawnSize(p)
        let pd = drawn == p.frame.size ? p : Placed(item: p.item, frame: CGRect(origin: p.frame.origin, size: drawn))

        WidgetChrome(placed: pd, theme: theme, lockBadge: isEditing && interactive)
            .frame(width: drawn.width, height: drawn.height)
            // เส้นประรอบข้อความที่แก้ได้ขึ้นเฉพาะบนแคนวาสในโหมดแต่ง
            // พรีวิวในตู้ widget กับรูปที่เรนเดอร์ตอนแชร์อ่านค่าตั้งต้น false จึงสะอาดตามเดิม
            .environment(\.textEditMode, isEditing && interactive)
            // ส่งระยะหน้าลงไปให้ "ข้างใน" widget ด้วย — ตัวที่มีท่าเป็นของตัวเอง (เช่นบานเกล็ดของ
            // ผลงานที่ยืนยันแล้ว) จะเล่นจังหวะของมันเองแทนที่จะถูกกรอบลากไปทั้งแผ่น
            .environment(\.pageScrub, PageScrub(d: dist, order: order,
                                                flat: p.item.surface == .glass))
            .pressTilt(touch, size: drawn, glow: theme.accent)
            .overlay {
                // คง catcher ไว้ขณะที่มันถือการลากอยู่ — หลัง flip หน้า interactive ของหน้าต้นทาง
                // กลายเป็น false ถ้าถอดตรงนี้ recognizer ตายกลาง gesture แล้ว event ปล่อยนิ้วหาย
                if interactive || dragID == p.id {
                    PressDragCatcher(
                        // ชิ้นที่เลือกอยู่ลากได้ทันที (ตอนพิมพ์ไม่มีผังให้ย้าย จึงไม่เปิด)
                        immediate: isSel && !dock.isText && !p.item.pinned,
                        onBegan: {
                            // ตอนพิมพ์ก้อนนี้อยู่ไม่มีผังให้ย้าย — กดค้างไม่ทำอะไร
                            guard isEditing, showroomID == nil else { return }
                            // ตรารับรองตรึงอยู่กับที่ — กดค้างแล้วบอกเหตุ ไม่ใช่เงียบเหมือนแอปค้าง
                            if p.item.pinned {
                                Haptics.rigid()
                                flash("ตรารับรอง Sale Here อยู่ตรงนี้ทุกการ์ด · ย้ายไม่ได้")
                                return
                            }
                            pressMode = p.id
                            beginDrag(p)
                        },
                        onChanged: { t in
                            guard dragID == p.id else { return }
                            // นิ้ววัดบนจอ แต่หน้าแสดงแบบย่อ — หารสเกลให้ widget วิ่งเท่านิ้วจริง
                            let s = max(canvasScale, 0.01)
                            let scaled = CGSize(width: t.width / s, height: t.height / s)
                            dragTranslation = scaled
                            hover(p)
                            checkEdgeFlip(p, scaled)
                        },
                        onEnded: {
                            if pressMode == p.id { pressMode = nil }
                            endDrag(p)
                        },
                        onTap: { at in
                            // คลิป = การ์ดทำตัวเป็นการ์ดจริง — แตะช่องโซเชียลไปหน้าโปรไฟล์ แตะผลงานไปโพสต์นั้น
                            guard isEditing else {
                                if let url = linkBox.hit(at, in: p.item.id) { open(url) }
                                return
                            }
                            // **สองชั้น ชั้นละความตั้งใจ**
                            //
                            // 1. แตะ = เลือก (กรอบ + หมุด + ถาดของชิ้น) · กดค้าง = ลากย้าย
                            // 2. แตะซ้ำบนชิ้นที่เลือกอยู่ = ลงมือกับข้อความ: ก้อนข้อความเข้าโหมดพิมพ์ทั้งก้อน
                            //    ชิ้นอื่นแตะกรอบเส้นประของช่องนั้น ๆ
                            //
                            // ที่ต้องแยกเพราะการ์ดหนึ่งหน้ามีข้อความเต็มไปหมด ถ้าแตะข้อความแล้วพิมพ์ได้
                            // ตั้งแต่แตะแรก คีย์บอร์ดจะเด้งขึ้นทุกครั้งที่ผู้ใช้แค่จะเลือกหรือจะลาก
                            // ก้อนข้อความ: แตะแรก = เลือก (ได้หมุดมุมย่อขยาย · ลากย้ายได้) · แตะซ้ำ = พิมพ์
                            // ถ้าแตะแล้วขึ้นแป้นพิมพ์ทันทีทุกครั้ง จะไม่มีจังหวะไหนได้จับหมุดเลย
                            if p.item.kind == .textBlock {
                                if selected == p.id { enterTextMode(p.id) } else { select(p.id) }
                                return
                            }
                            // ใบที่ล็อก: แตะ **ปุ่มปลดล็อก** = กรอกข้อมูลนั้น (กรอกเสร็จใบปลดล็อกในที่เดิม)
                            // แตะส่วนอื่นของใบ = เลือก/ลาก/ลบ ตามปกติ (ผู้ใช้ 29 ก.ย. 2569)
                            // ตรารับรองล็อกตาม "ยืนยันตัวตนผ่านแล้วหรือยัง" ไม่ใช่ตามว่าหัวข้อถูกกรอก (ดู `WidgetChrome`)
                            let sealLocked = p.item.kind == .proofSeal && !VerifiedFacts.sealed
                            if let t = p.item.kind.family.topic, !t.filled || sealLocked,
                               WidgetChrome.lockHitRect(in: drawn).contains(at) {
                                Haptics.impact(.light)
                                if t.fillable { topicFill = TopicFillRequest(kind: p.item.kind, topic: t, place: false) } else { askJobs = true }
                                return
                            }
                            guard selected == p.id else {
                                select(p.id)
                                return
                            }
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
                    // ก้อนข้อความไม่มีเส้นประชั้นใน — ทั้งก้อนคือช่องเดียว กรอบเลือกบอกอยู่แล้ว
                    textSlotLayer(slots, on: p, focused: selected == p.id && p.item.kind != .textBlock)
                }
            }
            // ช่องพิมพ์บนการ์ด — ทับตำแหน่งก้อนพอดี อยู่เหนือ catcher จึงรับทัชวางเคอร์เซอร์ได้
            .overlay(alignment: .topLeading) {
                if dock == .text(p.id) { canvasEditor(p) }
            }
            .environment(\.canvasTyping, dock == .text(p.id))
            .opacity(isDrag ? 0 : 1)
            .pageChoreo(p.item.kind, order, d: dist, flat: p.item.surface == .glass)
            // ตอนพิมพ์: ก้อนที่พิมพ์ถูกยกขึ้นกลางที่ว่าง · ที่เหลือถอยออกแล้วหรี่ลง
            // หรี่ด้วย opacity + ย่อ ไม่ใช่ถอดออกจากต้นไม้ view — ผังต้องนิ่งอยู่ที่เดิม
            // ไม่งั้นพอกด เสร็จ ของทั้งหน้าจะกระโดดกลับมาแทนที่จะไหลกลับ
            // **ไม่เบลอ** — เบลอกระจกซ้อนกระจกทั้งหน้าทั้งกระพริบและตาล้า หรี่อย่างเดียวพอ
            .scaleEffect(showroomScale(p), anchor: .center)
            .opacity(showroomDim(p))
            // ตัวที่ถูกหรี่ในโชว์รูมยังอยู่ในต้นไม้ view (ผังต้องนิ่ง) — แต่ต้องไม่รับทัช
            // ไม่งั้นแตะที่ว่างรอบชิ้นงานแล้วไปโดนตัวที่หรี่อยู่ซึ่งบังเอิญวางทับอยู่ตรงนั้น
            .allowsHitTesting(showroomID == nil || showroomID == p.id)
            .offset(x: p.frame.minX - parallaxShift(p.item, parallax: parallax, pageWidth: pageWidth)
                       + showroom(p).dx,
                    y: p.frame.minY + showroom(p).dy)
            // ลำดับในลิสต์คือชั้นซ้อนจริง — ห้ามยกตัวที่เลือกขึ้นหน้า
            // ไม่งั้นกดปุ่มสลับชั้นแล้วจะไม่เห็นอะไรเกิดขึ้นเลยตอนมันยังถูกเลือกอยู่
            // ยกเว้นในโชว์รูม ซึ่งตัวที่แต่งอยู่ต้องอยู่หน้าสุดตามนิยาม
            // ชิ้นที่ตรึง (ตรารับรอง) อยู่เหนือของทุกชิ้นบนหน้า แต่ใต้ชั้นลอยตอนลาก (200)
            .zIndex(showroomID == p.id ? 400 : p.item.pinned ? 150 : Double(order))
            .animation(Motion.settle, value: showroomID)
            // เป้าหมายกลางจอขยับตามความสูงแป้นพิมพ์ — เปลี่ยนเมื่อไหร่ต้องไหลตาม ไม่ใช่กระโดด
            .animation(Motion.settle, value: keyboard)
            .animation(Motion.settle, value: toolsH)
    }

    /// กระจกฝ้าคลุมทั้งหน้าตอนพิมพ์ — มืดสำหรับหมึกกลางคืน สว่างสำหรับกระดาษ ตัวอักษรที่พิมพ์จึงตัดกับพื้นเสมอ
    ///
    /// วัสดุของระบบเบลอทุกอย่างที่อยู่ข้างหลังในหน้าต่างเดียวกัน (ฉากหลัง · ชิ้นอื่น) ไม่ต้องเบลอทีละชิ้น
    /// มุมเท่าการ์ด (ในหน่วยออกแบบ — หารสเกลกลับเหมือน `CardBackdrop`) จะได้อ่านเป็น "การ์ดกลายเป็นกระจก"
    private var typingVeil: some View {
        let light = theme.inkStyle.isLight
        // มุมมนเฉพาะปลายกระดาษ — ช่องกลางของแผ่นต่อเนื่องไม่มีมุม ถ้ามนที่รอยต่อจะเห็นฉากหลังโผล่ตรงมุม
        let r = 22 / max(pageFit, 0.01)
        let lead: CGFloat = index == 0 ? r : 0
        let trail: CGFloat = index == pages.count - 1 ? r : 0
        let shape = UnevenRoundedRectangle(topLeadingRadius: lead, bottomLeadingRadius: lead,
                                           bottomTrailingRadius: trail, topTrailingRadius: trail,
                                           style: .continuous)
        return shape.fill(.thinMaterial)
            .overlay(shape.fill(light ? Color.white.opacity(0.28) : Color.black.opacity(0.30)))
            .environment(\.colorScheme, light ? .light : .dark)
            // แตะบนกระจก = แตะที่ว่าง (เสร็จ) — ปล่อยให้ทัชตกไปถึงตัวรับของทั้งสำรับ
            .allowsHitTesting(false)
    }

    /// ตัวที่กำลังแต่งขยายขึ้น · ตัวอื่นถอยลงเล็กน้อยให้อ่านเป็น "ถอยออกไปข้างหลัง"
    private func showroomScale(_ p: Placed) -> CGFloat {
        guard let id = showroomID else { return 1 }
        return id == p.id ? showroom(p).scale : 0.92
    }

    /// ชิ้นอื่นตอนพิมพ์ — หรี่แค่พอให้ยังเห็นเงาผ่านกระจกว่าก้อนจะกลับไปลงตรงไหน (กระจกทำงานที่เหลือ)
    private func showroomDim(_ p: Placed) -> Double {
        guard let id = showroomID else { return 1 }
        return id == p.id ? 1 : 0.6
    }

    /// ช่องพิมพ์ทับก้อนข้อความ — ขนาดเท่ากล่องแก้ไข (ดู `editBox`) วางกลาง tile ที่ถูกวาดขนาดเดียวกัน
    ///
    /// ขนาดตายตัว ไม่ยืดตาม tile: ระหว่างที่กล่องสปริงจากขนาดบนการ์ดมาเป็นขนาดแก้ไข
    /// ช่องพิมพ์ต้องไม่ยืดตาม ไม่งั้นตัวอักษรถูกตัดขอบไปตลอดขาเข้า
    private func canvasEditor(_ p: Placed) -> some View {
        let e = editBox(p)
        return CanvasTextField(id: TextSlotID(field: .note, widget: p.item.id),
                               style: p.item.textStyle,
                               ink: theme.inkStyle, accent: theme.accent,
                               size: e.points)
            // ช่องพิมพ์ใหญ่เท่า line box แล้วเลื่อนให้ **หมึก** ชิดมุมบนซ้ายของกล่อง (หักขอบ)
            // — จุดเดียวกับที่ตัวอักษรบนการ์ดนั่ง (ดู `TextBlock`) กด เสร็จ แล้วจึงไม่มีอะไรขยับ
            .frame(width: e.m.typo.width, height: e.m.typo.height)
            .offset(x: TextBlock.inset - e.m.ink.minX, y: TextBlock.inset - e.m.ink.minY)
    }

    /// กล่องของก้อนข้อความ **คือตัวอักษรพอดี** — กว้างเท่าบรรทัดที่ยาวที่สุด สูงเท่าจำนวนบรรทัด
    ///
    /// เรียกทุกครั้งที่ข้อความหรือขนาดเปลี่ยน (พิมพ์ · Return · ลากหมุดมุม) ไม่มีจังหวะไหนที่กล่องกับตัวอักษร
    /// ไม่ตรงกัน · ยึดขอบตามการจัดวางเวลาพิมพ์ (ชิดซ้ายยึดซ้าย · กลางยึดกลาง · ชิดขวายึดขวา)
    /// ส่วนตอนลากหมุดมุมยึดมุมบนซ้ายเสมอ — มุมตรงข้ามกับหมุดต้องนิ่ง ไม่งั้นหมุดหนีนิ้ว
    private func fitTextBlock(_ id: UUID, keepTopLeft: Bool = false) {
        guard let pi = pages.firstIndex(where: { $0.items.contains { $0.id == id } }),
              let i = pages[pi].items.firstIndex(where: { $0.id == id }) else { return }
        var w = pages[pi].items[i]
        let inset = TextBlock.inset
        let content = PageLayout.content(pageSize)
        let text = Profile.me.note(id)
        let size = TextFit.capped(w.textStyle.points, text, face: w.textStyle.face,
                                  weight: TextBlock.weight, maxWidth: content.width - inset * 2)
        let m = TextFit.metrics(text, face: w.textStyle.face, weight: TextBlock.weight,
                                size: size, align: w.textStyle.align)
        // พอดี **หมึก** ถึงพอยต์ — ไม่ปัดเข้ากริด 6pt ไม่งั้นได้ขอบว่างข้างละ 0–3pt ที่ไม่มีใครขอ
        let newW = min(m.ink.width + inset * 2, content.width)
        let newH = m.ink.height + inset * 2
        let old = w.rect
        if !keepTopLeft {
            switch w.textStyle.align {
            case .leading:  break
            case .center:   w.x = PageLayout.snap(old.midX - newW / 2)
            case .trailing: w.x = PageLayout.snap(old.maxX - newW)
            }
        }
        w.w = newW
        w.h = newH
        w.rect = PageLayout.clamp(w.rect, page: pageSize, min: PageLayout.minSize(for: .textBlock))
        guard w != pages[pi].items[i] else { return }
        pages[pi].items[i] = w
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
                                    order: order, labelled: r.width >= 132,
                                    scale: canvasScale)
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
    ///
    /// เว็บลิงก์ลองเปิด **แอปเจ้าของลิงก์ก่อน** (universal link — IG · TikTok · YouTube · LINE · FB)
    /// ถ้าเครื่องไม่มีแอปนั้น ระบบตอบ false แล้วค่อยเปิดเบราว์เซอร์ในแอปแทน
    /// คนดูการ์ดกดช่องโซเชียลเพราะอยากไปกดติดตามในแอป ไม่ใช่อยากอ่านหน้าเว็บ
    private func open(_ url: URL) {
        switch url.scheme?.lowercased() {
        // ปลายทางภายในแอป — widget ตรารับรองชี้มาที่แผ่นตรวจสอบ (ดู `VerifiedFacts.sheetURL`)
        case "starcard":
            if url.host == "verified" { showVerify = true }
        case "http", "https":
            UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { opened in
                if !opened { link = LinkTarget(url: url) }
            }
        default:
            openURL(url)
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
                        let box = Self.upright(slot.rect.size, tilt: slot.style.tilt)
                        TextSlotDashes(style: slot.style, accent: theme.accent)
                            .frame(width: box.width + 6, height: box.height + 6)
                            .rotationEffect(.degrees(slot.style.tilt))
                            .position(x: slot.rect.midX, y: slot.rect.midY)
                    }
                }

                // ช่องที่กำลังพิมพ์ — กรอบทึบ + พื้นจาง บอกว่าตัวอักษรที่วิ่งอยู่คือก้อนนี้
                // (ตัวพิมพ์จริงอยู่บนแถบเหนือคีย์บอร์ด ที่นี่เหลือแค่ "ชี้ว่าอันไหน")
                if let active {
                    let box = Self.upright(active.rect.size, tilt: active.style.tilt)
                    ZStack {
                        RoundedRectangle(cornerRadius: active.style.corner + 3, style: .continuous)
                            .fill(theme.accent.opacity(0.18))
                        RoundedRectangle(cornerRadius: active.style.corner + 3, style: .continuous)
                            .strokeBorder(theme.accent, lineWidth: 1.2)
                    }
                    .frame(width: box.width + 8, height: box.height + 8)
                    .rotationEffect(.degrees(active.style.tilt))
                    .position(x: active.rect.midX, y: active.rect.midY)
                    .allowsHitTesting(false)
                }
            }
            .onChange(of: resolved, initial: true) { _, new in
                slotBox.rects[p.item.id] = new
            }
        }
    }

    /// ขนาดจริงของกล่องที่ถูกหมุนไป `tilt` องศา — ย้อนจากกรอบตรงที่ anchor ให้มา
    ///
    /// anchor ของของที่หมุนอยู่ได้กรอบตรงที่ครอบมุมทั้งสี่ ซึ่งใหญ่กว่ากล่องจริง
    /// แก้สมการกรอบครอบกลับ: W = w·cos + h·sin · H = w·sin + h·cos
    /// (จุดกลางไม่ขยับตอนหมุน วางด้วย `midX/midY` ของกรอบครอบได้ตรง ๆ)
    private static func upright(_ bound: CGSize, tilt: Double) -> CGSize {
        guard tilt != 0 else { return bound }
        let t = abs(tilt) * .pi / 180
        let c = cos(t), s = sin(t)
        // cos 2θ — แผ่นที่แปะเอียงไม่มีทางถึง 45° ถ้าถึงก็คืนกรอบครอบไปตามเดิม
        let d = c * c - s * s
        guard d > 0.1 else { return bound }
        return CGSize(width: max(0, (bound.width * c - bound.height * s) / d),
                      height: max(0, (bound.height * c - bound.width * s) / d))
    }

    /// เส้นบาง ๆ บอกขอบเขตของทุกตัวในโหมดแต่ง — ตัวที่ถูกเลือกใช้กรอบเต็มในชั้นบนแทน
    /// กรอบประจำชิ้นในโหมดแต่ง — **เส้นประ ไม่ใช่เส้นจาง**
    ///
    /// ของเดิมเป็นเส้นทึบ 0.7pt ที่ opacity 0.07–0.14 ซึ่งบนพื้นการ์ดจริงแทบมองไม่เห็น
    /// ผลคือโหมดแต่งกับโหมดดูหน้าตาเหมือนกันทุกประการ · เส้นประอ่านออกทันทีว่า
    /// "นี่คือขอบของชิ้นงาน" ไม่ใช่เส้นตกแต่ง และไม่ไปแข่งกับกรอบทึบของตัวที่ถูกเลือกอยู่
    private func editHairline(_ p: Placed) -> some View {
        RoundedRectangle(cornerRadius: chromeRadius(p.item.kind), style: .continuous)
            .strokeBorder(theme.accent.opacity(editReveal ? 0.85 : 0.42),
                          style: StrokeStyle(lineWidth: editReveal ? 1.4 : 1,
                                             dash: [4.5, 3.5]))
            .allowsHitTesting(false)
    }

    /// กรอบเลือก + หมุดปรับขนาด — วาดที่ชั้นบนสุดของหน้า จึงไม่ถูก widget ที่ทับอยู่กลืน
    private func selectionLayer(_ p: Placed, interactive: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: chromeRadius(p.item.kind), style: .continuous)
        return ZStack {
            shape.strokeBorder(theme.accent, lineWidth: 1.5)
            shape.strokeBorder(theme.accent.opacity(0.18), lineWidth: 7).blur(radius: 5)
                .matchedGeometryEffect(id: "selectionGlow", in: selectionNS)
            // จุดมุมสี่จุดบอกว่า "ขอบลากได้" — ก้อนข้อความไม่มีหมุดขอบ และกล่องเล็กเท่าตัวอักษร
            // จุดจะไปนั่งทับตัวแรกกับตัวสุดท้าย · มีแค่กรอบกับปุ่มมุมพอ
            // ชิ้นที่ตรึงก็ไม่มีจุด — จุดแปลว่า "ลากขอบได้" ซึ่งมันทำไม่ได้
            if p.item.kind != .textBlock, !p.item.pinned {
                ForEach(0..<4, id: \.self) { i in
                    Circle().fill(.white).frame(width: 8, height: 8)
                        .overlay(Circle().strokeBorder(theme.accent, lineWidth: 1.6))
                        .shadow(color: .black.opacity(0.4), radius: 3)
                        .position(x: i % 2 == 0 ? 0 : p.frame.width,
                                  y: i < 2 ? 0 : p.frame.height)
                }
            }
        }
        .frame(width: p.frame.width, height: p.frame.height)
        // ปิดทัชแค่ตัวกรอบ — หมุดที่ครอบทีหลังยังกดได้ตามปกติ
        .allowsHitTesting(false)
        // **สามหมุด หนึ่งความหมายต่อหมุด** — ขอบขวา = กว้าง · ขอบล่าง = สูง · มุม = ทั้งชิ้น
        //
        // **สองหมุด ไม่ใช่สาม** — ขอบขวา = กว้าง · ขอบล่าง = สูง · ไม่มีหมุดมุมอีกแล้ว
        //
        // หมุดมุมเคยแปลว่า "ทำให้ใหญ่ขึ้นทั้งใบตามสัดส่วนเดิม" ซึ่งเป็นท่าที่จำเป็นตอนที่ยังมีใบ
        // ที่จัดหน้ามาตายตัว (โปสเตอร์) แล้วกรอบสัดส่วนอื่นทำให้มันเหลือที่ว่าง · พอทุกใบ
        // จัดตัวเองได้ทั้งสองแกน ท่านั้นก็ไม่เหลือความหมาย: มันคือสองหมุดที่ลากพร้อมกัน
        // แต่ *ห้าม* ผู้ใช้เลือกสัดส่วนเอง ซึ่งเป็นสิ่งเดียวที่การยืดกรอบมีไว้ให้ทำ
        .overlay(alignment: .trailing) {
            if interactive, p.item.kind.canResize, !p.item.pinned { widthHandle(p) }
        }
        .overlay(alignment: .bottom) {
            if interactive, p.item.kind.canResize, !p.item.pinned { heightHandle(p) }
        }
        // ก้อนข้อความยังมีหมุดมุม — แต่ของมันไม่ใช่การยืดกรอบ มันปรับ *ขนาดตัวอักษร*
        // แล้วกล่องวิ่งตามตัวอักษร (ใบเดียวในตู้ที่กรอบเป็นผลลัพธ์ ไม่ใช่ตัวตั้ง)
        .overlay(alignment: .bottomTrailing) {
            if interactive, p.item.kind == .textBlock { cornerHandle(p) }
        }
    }

    /// หมุดขอบขวา — **ความกว้างอย่างเดียว** ความสูงไม่ขยับ
    private func widthHandle(_ p: Placed) -> some View {
        HandleGrip(theme: theme, axis: .horizontal)
            // นั่งนอกกรอบ ไม่ใช่คร่อมขอบ — ดูเหตุผลที่ `HandleGrip`
            .offset(x: 11)
            .gesture(
                // วัดใน space ของหน้า ไม่ใช่ของหมุด — หมุดเกาะขอบขวาของตัวที่กำลังยืด
                // พอความกว้างเปลี่ยน หมุดขยับตาม ระยะลากใน local space จะถูกหักออกเท่านั้นพอดี
                // กลายเป็นวงป้อนกลับ โต→ระยะลดลงต่ำกว่าเกณฑ์→หด→ระยะเด้งขึ้น→โต วนไม่จบ
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
                        let over = want - next
                        overshoot.width = abs(over) < 0.5 ? 0 : rubber(over)
                    }
                    .onEnded { _ in
                        endResize()
                        Haptics.impact(.medium)
                    }
            )
    }

    /// หมุดขอบล่าง — **ความสูงอย่างเดียว**
    ///
    /// ไม่มีเพดานล่างจากเนื้อหาอีกแล้ว (เคยมี `minHeight` ที่วัดความสูงที่เนื้อหาขอจริง)
    /// เพราะการโชว์สเกลด้วยแกนที่คับที่สุดเสมอ — บีบเตี้ยลงได้เนื้อหาที่เล็กลงทั้งก้อน
    /// ไม่ใช่เนื้อหาที่ถูกตัดครึ่ง จึงไม่มีอะไรให้ต้องกัน
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
                        let next = PageLayout.snap(min(max(want, PageLayout.minSize.height), room))
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

    /// หน้าตาของหมุดมุม — วงขาวกับลูกศรทแยง อ่านออกทันทีว่า "ลากแล้วทั้งชิ้นใหญ่ขึ้น"
    private var cornerGrip: some View {
        ZStack {
            Circle().fill(.white).frame(width: 22, height: 22)
                .overlay(Circle().strokeBorder(theme.accent, lineWidth: 1.6))
                .shadow(color: .black.opacity(0.4), radius: 3)
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(theme.accent)
        }
        .frame(width: 44, height: 44)
        .contentShape(Circle())
    }

    /// หมุดมุมของก้อนข้อความ — ปรับ **ขนาดตัวอักษร** ไม่ใช่ขนาดกล่อง
    ///
    /// ลากตามแนวทแยง: ออกจากมุมบนซ้าย = โต · เข้าหา = เล็ก · มุมบนซ้ายนิ่ง (ดู `fitTextBlock`)
    /// ไม่มีหมุดกว้าง/สูง เพราะกล่องที่ดันตัวอักษรจนตัดบรรทัดคือการขึ้นบรรทัดใหม่แทนคนเขียน
    private func cornerHandle(_ p: Placed) -> some View {
        cornerGrip
        // นั่ง **นอก** มุมกล่อง (ศูนย์กลางเลยมุมออกไป 8pt) — กล่องเล็กเท่าตัวอักษร ถ้าปุ่มอยู่ในมุม
        // มันจะทับตัวอักษรที่ผู้ใช้กำลังจะย่อขยาย แล้วมองไม่เห็นผล
        .offset(x: 30, y: 30)
        .gesture(
            // วัดใน space ของหน้า — เหตุผลเดียวกับ `scaleHandle`
            DragGesture(minimumDistance: 1, coordinateSpace: .named("page"))
                .onChanged { g in
                    guard let i = pages[index].items.firstIndex(where: { $0.id == p.id }) else { return }
                    if resizeID != p.id {
                        resizeID = p.id
                        resizeW = pages[index].items[i].w
                        resizeH = pages[index].items[i].h
                        resizePoints = pages[index].items[i].textStyle.points
                        resizeScale = max(showroomScale(p), 0.01)
                    }
                    // สัดส่วน = ระยะที่นิ้วเดินตามแนวทแยงของกล่องเดิม เทียบกับความยาวแนวทแยงนั้น
                    let dx = g.translation.width / resizeScale
                    let dy = g.translation.height / resizeScale
                    let diag = max(hypot(resizeW, resizeH), 1)
                    let along = (dx * resizeW + dy * resizeH) / diag
                    let k = max(0.15, (diag + along) / diag)
                    var want = min(max(resizePoints * k, TextFit.minSize), TextFit.maxSize)
                    // ห้ามโตจนบรรทัดล้นหน้า — ตัวอักษรต้องเห็นครบเสมอ
                    let item = pages[index].items[i]
                    want = TextFit.capped(want, Profile.me.note(p.id), face: item.textStyle.face,
                                          weight: TextBlock.weight,
                                          maxWidth: PageLayout.content(pageSize).width - TextBlock.inset * 2)
                    let cur = item.textStyle.points
                    guard abs(want.rounded() - cur) >= 1 else { return }
                    pages[index].items[i].textStyle.points = want.rounded()
                    fitTextBlock(p.id, keepTopLeft: true)
                }
                .onEnded { _ in
                    endResize()
                    Haptics.impact(.medium)
                }
        )
    }

    private func dragLayer(_ p: Placed) -> some View {
        // ใบที่ล็อกต้องหน้าตาเดิมตอนถูกยกขึ้นลาก (ตัวอย่าง + ชั้นเทา) — ไม่ใช่กลายเป็นป้ายรอข้อมูลกลางนิ้ว
        WidgetChrome(placed: p, theme: theme, lockBadge: true)
            .frame(width: p.frame.width, height: p.frame.height)
            .scaleEffect(lifted ? 1.05 : 1.0)
            .shadow(color: .black.opacity(lifted ? 0.55 : 0), radius: lifted ? 30 : 0, y: lifted ? 16 : 0)
            .overlay {
                RoundedRectangle(cornerRadius: chromeRadius(p.item.kind), style: .continuous)
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
        let at = PageLayout.snap(CGPoint(x: dragStart.minX + dragTranslation.width,
                                         y: dragStart.minY + dragTranslation.height))
        var probe = p.item
        probe.w = dragWidth ?? p.item.w
        probe.x = at.x
        probe.y = at.y
        probe.rect = PageLayout.clamp(probe, page: pageSize)

        // ที่ว่างตรงนี้แคบกว่าตัวเอง → **ย่อทั้งชิ้น** ให้พอดีที่ แทนที่จะถูกดันลงไปข้างล่าง
        // นี่คือสิ่งที่ทำให้ "ลากไปแทรกข้าง ๆ ตัวที่ย่อไว้" ทำได้จริง
        // ยกเว้นก้อนข้อความ — ความกว้างของมันคือตัวอักษร ย่อเมื่อไหร่ตัวอักษรโดนตัด
        let room = PageLayout.freeWidth(from: probe.x, y: probe.y, height: probe.h,
                                        page: pageSize, avoiding: page.items, excluding: p.id)
        let floor = PageLayout.minSize.width
        if p.item.kind != .textBlock, room >= floor {
            probe.w = min(p.item.w, max(floor, PageLayout.snap(room)))
        }
        return PageLayout.clamp(probe, page: pageSize)
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
    /// **ไม่แตะ `dock`** — ชิ้นยังถูกเลือกอยู่ แถบล่างแค่หลบให้คีย์บอร์ดชั่วคราว
    /// กด เสร็จ แล้วถาดของชิ้นจึงกลับมา แทนที่จะหลุดออกมาทั้งชั้น
    private func beginTextEdit(_ slot: TextSlotRect, on p: Placed) {
        guard selected == p.id else { return }
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

    /// เลือกชิ้น = เข้าโหมดของชิ้นนั้น (กติกาข้อ 3) · nil = กลับแถบหลัก (กติกาข้อ 4)
    ///
    /// **เลือกแล้วทุกอย่างยังอยู่ที่เดิม** — ไม่มีโชว์รูม ไม่มีปุ่มประแจอีกชั้น
    /// ถาดของชิ้นโผล่ทันที · การ์ดย่อลงให้ทั้งใบอยู่เหนือถาด (ดู `editScale`) แต่ไม่เลื่อนไปหาชิ้นที่เลือก
    private func select(_ id: UUID?) {
        // แตะที่อื่นเมื่อไหร่คือจบการพิมพ์ — อยู่ก่อน guard เพราะแตะข้อความอีกช่องบน widget ตัวเดิม
        // จะไม่เปลี่ยนตัวที่เลือก แต่ยังต้องเก็บค่าของช่องเดิมก่อนย้ายไปช่องใหม่
        endTextEdit()
        // เลือกตัวอื่นคือจบการเล็งรูปด้วย — แผ่นลากที่ค้างอยู่บน widget ตัวเก่าจะกินทัชต่อไปเรื่อย ๆ
        photos.framing = nil
        let target: DockMode = id.map { .piece($0) } ?? .main
        guard dock != target else { return }
        withAnimation(Motion.settle) { dock = target }
        if id != nil { Haptics.impact(.light) }
    }

    /// กลับแถบหลัก — ‹ · แตะที่ว่าง · เปลี่ยนหน้า ล้วนมาลงที่นี่
    private func goMain() {
        if dock.isText { exitTextMode(); return }
        guard !dock.isMain else { return }
        select(nil)
        Haptics.impact(.light)
    }

    /// เข้าโหมดพิมพ์ก้อนข้อความ — ก้อนยกขึ้นกลางที่ว่าง แป้นพิมพ์ขึ้นพร้อมแถวฟอนต์ (ดู `TextTools` · พิมพ์บนการ์ดผ่าน `CanvasTextField`)
    private func enterTextMode(_ id: UUID) {
        guard pages.contains(where: { $0.items.contains { $0.id == id && $0.kind == .textBlock } })
        else { return }
        photos.framing = nil
        // หนึ่งรอบพิมพ์ = หนึ่งจังหวะใน ↶ — บันทึกก่อนเข้า แล้วไม่บันทึกทุกครั้งที่กล่องขยับตามตัวอักษร
        history.record(.init(pages: pages, theme: theme))
        withAnimation(Motion.settle) {
            dock = .text(id)
            Profile.me.editing = TextSlotID(field: .note, widget: id)
        }
        Haptics.impact(.light)
    }

    /// เสร็จ — เก็บข้อความ หุบคีย์บอร์ด ก้อนไหลกลับเข้าที่ของมัน แล้วกลับแถบหลัก (ท่าเดียวกับ IG)
    private func exitTextMode() {
        guard case .text(let id) = dock else { return }
        endTextEdit()
        // ก้อนที่ว่างเปล่าตอนเสร็จหายไปเอง (สติกเกอร์ข้อความเปล่าของ IG ก็หาย) — ไม่ว่าจะเพิ่งสร้าง
        // หรือลบตัวอักษรจนหมด · อยากได้คืนมี ↶
        let empty = Profile.me.note(id) == Profile.notePlaceholder
        skipHistory = true
        DispatchQueue.main.async { skipHistory = false }
        withAnimation(Motion.settle) {
            if empty {
                for pi in pages.indices { pages[pi].items.removeAll { $0.id == id } }
            } else {
                fitTextBlock(id)
            }
            dock = .main
        }
        // ข้อความอยู่ใน `Profile` ไม่ใช่ใน `pages` — บันทึกใบเองตรงนี้ ให้ id ของก้อนลงไฟล์คู่กับข้อความ
        // ไม่งั้นใบที่กู้มาจากไฟล์เก่า (ยังไม่มี id) จะไม่ถูกเขียนใหม่ แล้วเปิดแอปรอบหน้าข้อความหาย
        persist()
        Haptics.impact(.light)
    }

    /// ปุ่ม "ข้อความ" บนแถบหลัก — วางก้อนใหม่แล้วเข้าโหมดพิมพ์ทันที ไม่มีขั้นเลือกแบบคั่นกลาง
    private func addText() {
        guard let id = addWidget(.textBlock) else { return }
        // ก้อนใหม่จัดกลางเหมือนข้อความบน Story — ตอนยกขึ้นพิมพ์กลางจอ ตัวอักษรชิดซ้ายจะดูหลุดกรอบ
        for pi in pages.indices {
            if let i = pages[pi].items.firstIndex(where: { $0.id == id }) {
                pages[pi].items[i].textStyle.align = .center
            }
        }
        // `addWidget` เลือกชิ้นใหม่แบบเลื่อนไปหนึ่งรอบ (เผื่อเปลี่ยนหน้า) — เข้าโหมดพิมพ์ต่อจากนั้น
        DispatchQueue.main.async { enterTextMode(id) }
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
    @discardableResult
    private func addWidget(_ kind: WidgetKind) -> UUID? {
        guard pages.indices.contains(index) else { return nil }
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
            // ย่อ **ทั้งชิ้น** ทีละขั้น — สัดส่วนล็อก การย่อจึงมีปุ่มเดียวคือความกว้าง
            // (ของเดิมหั่นความสูงอย่างเดียวจนได้ชิ้นที่ผังเพี้ยน แล้วอ่านเป็น "แอปวางผิด")
            let floor = max(PageLayout.minSize.width, PageLayout.snap(w.w * 0.6))
            var width = w.w - PageLayout.step
            while width >= floor {
                let size = CGSize(width: width, height: w.h * width / max(w.w, 1))
                if let at = PageLayout.freeSpot(size: size, page: pageSize,
                                                avoiding: pages[index].items) {
                    w.scale(toWidth: width)
                    w.x = at.x
                    w.y = at.y
                    dest = index
                    shrunk = true
                    break
                }
                width -= PageLayout.step
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
            return nil
        }

        let moved = dest.map { $0 != index } ?? true
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
        if shrunk {
            flash("ที่ว่างไม่พอขนาดเต็ม — ย่อให้พอดีแล้ว ลากหมุดมุมปรับต่อได้")
        } else if moved, kind != .textBlock {
            // ลงหน้าอื่นเพราะหน้านี้เต็ม — หน้าปัดไปแล้วแต่ต้องบอกด้วยว่าทำไม ไม่งั้นอ่านเป็นแอปเปลี่ยนหน้าเอง
            flash("หน้านี้เต็ม — เพิ่มไว้หน้า \(index + 1) แล้ว")
        }
        return w.id
    }

    // MARK: - Drag

    private func beginDrag(_ p: Placed) {
        // คลิปเป็นตัวเปิดการ์ด — กดค้างแล้วห้ามลาก · ชิ้นที่ตรึงก็เช่นกัน
        if viewOnly || p.item.pinned { return }
        endTextEdit()
        guard dragID == nil, let live = placed.first(where: { $0.id == p.id }) else { return }
        // **ไม่เลือกชิ้นตอนเริ่มลาก** — เลือก = ถาดของชิ้นโผล่ = การ์ดย่อใต้นิ้วกลางการลาก
        // ชั้นลอยมีกรอบสีเน้นของตัวเองอยู่แล้ว · อยากแต่งค่อยแตะหลังวาง (ดู `endDrag`)
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
        let drop = target(p) ?? PageLayout.clamp(p.item, page: pageSize)

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
        // **วางแล้วแถบล่างอยู่ในสถานะเดิม** — ลากคือย้ายที่ ไม่ใช่เลือก
        // (เคยสลับถาดมาชี้ชิ้นที่เพิ่งวาง ซึ่งอ่านเป็น "ปล่อยนิ้วแล้วชีตเด้ง" · อยากแต่งค่อยแตะ)
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

    // MARK: - Chrome

    /// แถบบน — **สามคอลัมน์กว้างเท่ากัน** ตัวบอกช่องจึงอยู่กลางจอเป๊ะ ไม่ว่าสองข้างจะมีปุ่มกี่ปุ่ม
    ///
    /// # สมดุล
    ///
    /// เดิมตัวบอกช่องถูกวางทับกลางแถบ แต่ข้างขวามีของสามชิ้น (↶ ↷ + ป้าย "แชร์") ข้างซ้ายชิ้นเดียว
    /// น้ำหนักสายตาเทไปขวาทั้งแถบ ตัวบอกช่องเลยดูถูกเบียด
    ///
    /// ตอนนี้: ซ้าย = ของรอง (กลับคลัง · ↶ ↷) เป็นกระจกใส · ขวา = **ปุ่มเดียว** คือแชร์ เป็นวงกลมทึบสีเน้น
    /// วงทึบสีเดียวหนักเท่ากับกระจกใสสองชิ้น สองข้างจึงถ่วงกันพอดี และมุมทั้งสองเป็นวงกลม 40pt เท่ากัน
    /// ปุ่มหลักอยู่มุมขวาบนคนเดียวตามธรรมเนียม iOS — สายตาไม่ต้องเลือกว่าจะกดอะไร
    private var topBar: some View {
        VStack {
            GlassEffectContainer(spacing: 14) {
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        if viewOnly {
                            if let onClose { closeButton(onClose) }
                            stageMark
                        } else {
                            if dock.isMain, let onChangeFormat { libraryButton(onChangeFormat) }
                            undoRedo
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if multiPage { pageDots }

                    HStack(spacing: 8) {
                        // โหมดดูไม่มีปุ่มขอใบเสนอราคา — คนดูติดต่อผ่านช่องบนการ์ดเอง (เบอร์ · ไลน์ · อีเมล)
                        // แชร์ย้ายมาขวาแทน ให้มุมขวายังมีปุ่มถ่วงกับฝั่งซ้าย
                        shareButton(prominent: !viewOnly)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
            }
            .padding(.horizontal, 15).padding(.top, 4)
            Spacer()
        }
    }

    /// ทางกลับคลัง — โผล่เฉพาะแถบหลัก และเป็นไอคอนคลัง ไม่ใช่ ‹
    ///
    /// ‹ บนจอต้องมีตัวเดียวคือตัวที่หัวชีต — ถ้าซ้ายบนก็เป็น ‹ ด้วย
    /// ความเคยชินของ iOS จะพานิ้วมากดตัวนี้เวลาแค่อยากปิดชีต แล้วหลุดออกจากการ์ดทั้งใบ
    private func libraryButton(_ onChangeFormat: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            // ดูเฉย ๆ แล้วออก = ไม่เกิดการ์ด — คลังเก็บเฉพาะของที่ตั้งใจทำ
            if discardIfUntouched, !touched, let cardID {
                CardLibrary.shared.delete(cardID)
            }
            onChangeFormat()
        } label: {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .buttonStyle(DockPress())
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel("กลับคลังการ์ด")
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }

    /// ปิดหน้าดู — โผล่เฉพาะตอนเปิดจากคลัง ("ดูแบบที่แบรนด์เห็น")
    private func closeButton(_ action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .buttonStyle(DockPress())
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel("ปิด")
    }

    /// ตราของเวที — มุมซ้ายบนของหน้าดู ที่เดิมทุกครั้ง เหมือนดอกจันของ Linktree
    /// เล็ก ย้อมขาว และไม่อยู่บนการ์ด — มันบอกว่า "ที่นี่คือ Sale Here" ไม่ได้บอกว่าการ์ดเป็นของใคร
    private var stageMark: some View {
        StarLockup(height: 13, tint: .white.opacity(0.92))
            .padding(.horizontal, 13)
            .frame(height: 40)
            .glassEffect(.regular, in: Capsule())
    }

    /// ท้ายหน้าดู — ปุ่ม "ติดต่อ" ปุ่มเดียว (flow เดียวกับหน้าโปรไฟล์ครีเอเตอร์ใน salehere-ios)
    /// หน้าตาเป็นภาษาของเวทีนี้: แคปซูลกระจกสูง 54 ชุดเดียวกับปุ่มแถบบน ไม่ใช่ปุ่มแดงทึบของแอปหลัก
    private var viewerFooter: some View {
        Button {
            Haptics.impact(.medium)
            showContact = true
        } label: {
            HStack(spacing: 8) {
                SymbolIcon(name: "ic-addressbook-outline", size: 18, tint: .white)
                Text("ติดต่อ").font(.sh(15, .semibold)).foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .contentShape(Capsule())
        }
        .buttonStyle(DockPress())
        .glassEffect(.regular.interactive(), in: Capsule())
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .accessibilityLabel("ติดต่อ")
    }

    /// มุมขวาบนตอนพิมพ์ — คำเดียว ไม่มีกระจก ไม่มีอะไรแย่งตาจากตัวอักษร
    private var textTopBar: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: exitTextMode) {
                    Text("เสร็จ")
                        .font(.sh(16, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(DockPress())
            }
            .padding(.horizontal, 10).padding(.top, 4)
            Spacer()
        }
    }

    /// ↶ ↷ ในแคปซูลเดียว — ทางกลับทางเดียวของทุกตัวเลือกที่มีผลทันที
    ///
    /// ปุ่มที่ย้อนไม่ได้ไม่ได้หายไป แค่จาง — ปุ่มที่โผล่ ๆ หาย ๆ ทำให้ปุ่มข้าง ๆ ขยับที่ทุกครั้ง
    private var undoRedo: some View {
        HStack(spacing: 0) {
            Button(action: undo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 38, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(history.canUndo ? 1 : 0.32)
            .accessibilityLabel("เลิกทำ")
            Rectangle().fill(.white.opacity(0.18)).frame(width: 1, height: 14)
            Button(action: redo) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 38, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(history.canRedo ? 1 : 0.32)
            .accessibilityLabel("ทำซ้ำ")
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 2)
        .glassEffect(.regular.interactive(), in: Capsule())
        .animation(Motion.snap, value: history.canUndo)
        .animation(Motion.snap, value: history.canRedo)
    }

    /// ตัวบอกช่อง — **สามช่องติดกันเป็นแถบเดียว** ไม่ใช่จุดสามจุด
    ///
    /// จุดสามจุดทุกคนอ่านเป็น "สไลด์สามใบ" (หน้า home ของ iPhone) · สี่เหลี่ยมสามช่องที่ชนกันอ่านเป็น
    /// "แผ่นเดียวที่มีสามส่วน" ซึ่งคือความจริงของการ์ดใบนี้ · แตะช่องไหนเลื่อนไปช่องนั้น
    private var pageDots: some View {
        HStack(spacing: 1) {
            ForEach(Array(pages.enumerated()), id: \.element.id) { i, _ in
                let on = i == index
                let first = i == 0, last = i == pages.count - 1
                UnevenRoundedRectangle(topLeadingRadius: first ? 3 : 0, bottomLeadingRadius: first ? 3 : 0,
                                       bottomTrailingRadius: last ? 3 : 0, topTrailingRadius: last ? 3 : 0,
                                       style: .continuous)
                    .fill(on ? Color.white.opacity(0.95) : Color.white.opacity(0.2))
                    .overlay(
                        UnevenRoundedRectangle(topLeadingRadius: first ? 3 : 0, bottomLeadingRadius: first ? 3 : 0,
                                               bottomTrailingRadius: last ? 3 : 0, topTrailingRadius: last ? 3 : 0,
                                               style: .continuous)
                            .strokeBorder(.white.opacity(on ? 0 : 0.4), lineWidth: 0.6)
                    )
                    .frame(width: 11, height: 18)
                    .frame(width: 12, height: 30)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(Motion.page) { index = i }
                        Haptics.impact(.light)
                    }
            }
        }
        .animation(Motion.snap, value: index)
        .accessibilityLabel("ช่อง \(index + 1) จาก \(pages.count)")
    }

    /// เปิดหน้าตัวอย่าง 3 หน้าต่อกัน แล้วค่อยแชร์รูปหรือคัดลอกลิงก์
    ///
    /// ปุ่มเด่นปุ่มเดียวบนแถบบน — แชร์คือเป้าหมายของทั้งหน้า ↶ ↷ เป็นเครื่องมือรอง
    @ViewBuilder
    private func shareButton(prominent: Bool) -> some View {
        Button {
            // ชีตที่เปิดค้างจะบัง fullScreenCover — หุบก่อนแล้วค่อยพาไปหน้าตัวอย่าง
            endTextEdit()
            photos.framing = nil
            withAnimation(Motion.settle) { dock = .main }
            showPreview = true
            Haptics.impact(.light)
        } label: {
            // ไอคอนแชร์ของ iOS — ทุกคนรู้จักโดยไม่ต้องมีคำ · ยกขึ้นหนึ่งพอยต์เพราะน้ำหนักของรูปอยู่ด้านล่าง
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(prominent ? Color.black.opacity(0.85) : Color.white.opacity(0.92))
                .offset(y: -1)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .buttonStyle(DockPress())
        .glassEffect(prominent ? .regular.tint(theme.rawAccent).interactive() : .regular.interactive(),
                     in: Circle())
        .accessibilityLabel("แชร์การ์ด")
    }

    // MARK: - แถบล่าง

    /// ก้อนขอบล่างทั้งก้อน — dock + ถาด หรือแผ่นพิมพ์เหนือคีย์บอร์ด · ความสูงส่งให้ `bottomUI`
    ///
    /// ทั้งสองอย่างไม่มีวันอยู่พร้อมกัน (คีย์บอร์ดขึ้น = แถบล่างหลบให้ทั้งก้อน) จึงวัดที่เดียวได้เลขเดียว
    private var bottomChrome: some View {
        // ซ้อนใน ZStack — สลับแถบหลัก ↔ ชีต หรือชีต ↔ ชีต แล้วของเก่าจางออก ของใหม่จางเข้า **ทับกัน**
        // ถ้าเรียงใน VStack ระหว่างเปลี่ยนจะมีสองใบซ้อนกันชั่วครู่แล้วทั้งก้อนกระโดด
        ZStack(alignment: .bottom) {
            if dock.isText, let sel = selectedItem {
                TextTools(theme: theme, style: sel.textStyle,
                          onStyle: { change in setTextStyle(sel, change) },
                          onDelete: {
                              endTextEdit()
                              deleteWidget(sel)
                          })
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { toolsH = $0 }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let id = Profile.me.editing {
                // เครื่องมือของ **ช่องที่กำลังแก้** — ฟอนต์ สี ขนาด เก็บที่ชิ้นที่ถูกเลือกอยู่
                // (พิมพ์ได้เฉพาะช่องของชิ้นที่เลือก ดู `beginTextEdit` ตัวชิ้นจึงมีเสมอ)
                TextEditBar(id: id, theme: theme,
                            style: selectedItem?.textStyle,
                            onStyle: selectedItem.map { sel in
                                { change in setTextStyle(sel, change) }
                            },
                            onDone: endTextEdit)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if dock.isMain {
                EditorDock(dimmed: cardIsFull ? [.text, .widget] : [], onMain: mainAction)
                    .transition(chromeTransition)
            } else {
                sheet
            }
        }
        // แผ่นพิมพ์ต้องนั่งบนคีย์บอร์ดพอดี — กรอบคีย์บอร์ดวัดจากก้นหน้าต่าง แต่ก้อนนี้อยู่เหนือแถบระบบแล้ว
        .padding(.bottom, Profile.me.editing != nil || dock.isText ? max(0, keyboard - safeBottom) : 6)
        .frame(maxWidth: .infinity)
        // ความสูงเปลี่ยนเป็นขั้น (ชีตโผล่ทั้งใบ) — ให้การ์ดไหลตามด้วยสปริงเดียวกับชีต ไม่ใช่กระโดด
        // ส่วนตอนที่ผังของชีตค่อย ๆ โตอยู่แล้ว (สปริงของ layout) ค่านี้ก็แค่ตามไปทีละเฟรมเหมือนเดิม
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { h in
            withAnimation(Motion.settle) { bottomUI = h }
        }
    }

    /// ชีตของเรื่องที่เปิดอยู่ — มาแทนแถบหลัก (ขยับ 28pt + จาง) ไม่ใช่เลื่อนมาทั้งความสูง
    @ViewBuilder
    private var sheet: some View {
        switch dock {
        case .backdrop:
            DockSheet(title: dockTitle, symbol: dockSymbol, viewport: viewportH, onBack: goMain) { backdropTray }
                .transition(sheetTransition)
        case .gallery:
            DockSheet(title: dockTitle, symbol: dockSymbol, viewport: viewportH, fill: true, onBack: goMain) { galleryTray }
                .transition(sheetTransition)
        case .piece:
            if let sel = selectedItem {
                DockSheet(title: dockTitle, symbol: dockSymbol, viewport: viewportH, onBack: goMain) { pieceTray(sel) }
                    .transition(sheetTransition)
            }
        default:
            EmptyView()
        }
    }

    /// แถบหลักเข้า/ออก — ขยับนิดเดียวพอ มันคือของที่ "หลบ" ให้ชีต ไม่ใช่ตัวเอกของจังหวะนี้
    private var chromeTransition: AnyTransition {
        .offset(y: 24).combined(with: .opacity)
    }

    /// ชีตเข้า/ออก — **ไหลขึ้นมาจากขอบล่างทั้งใบ** เหมือน bottom sheet จริง (ขาออกจมกลับลงไปทางเดิม)
    ///
    /// การ์ดย่อตัวไปพร้อมกันเพราะ `bottomUI` วัดจากความสูงของก้อนนี้ทุกเฟรมระหว่างที่มันโต (ดู `bottomChrome`)
    /// — สองอย่างจึงเป็นการเคลื่อนไหวเดียว ไม่ใช่ชีตขึ้นแล้วการ์ดค่อยกระโดดตาม
    private var sheetTransition: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    /// หัวชีต — ชื่อ **เรื่อง** ที่เปิดอยู่: โหมดที่กดจากแถบหลัก หรือหมวดของชิ้นที่เลือก (ไม่ใช่ชื่อแบบ)
    private var dockTitle: String {
        switch dock {
        case .backdrop:     return "พื้นหลัง"
        case .gallery:      return "เพิ่มวิดเจ็ต"
        case .piece, .text: return selectedItem?.kind.family.label ?? ""
        case .main:         return ""
        }
    }

    private var dockSymbol: String {
        switch dock {
        case .backdrop:     return "paintpalette.fill"
        case .gallery:      return "plus.square.on.square"
        case .piece, .text: return selectedItem?.kind.symbol ?? "square"
        case .main:         return ""
        }
    }

    private func mainAction(_ item: DockMainItem) {
        switch item {
        case .backdrop:
            withAnimation(Motion.settle) { dock = .backdrop }
            Haptics.impact(.light)
        case .text:
            guard !cardIsFull else { warnFull(); return }
            addText()
        case .widget:
            guard !cardIsFull else { warnFull(); return }
            withAnimation(Motion.settle) { dock = .gallery }
            Haptics.impact(.light)
        }
    }

    /// ปุ่มเพิ่มจางอยู่แล้ว — แตะแล้วต้องได้คำอธิบาย ไม่ใช่ปุ่มตาย
    private func warnFull() {
        warn(format.pageCount == 1
             ? "หน้าเต็มแล้ว — เอาของออกหรือย่อของเดิมก่อนถึงจะเพิ่มได้"
             : "ครบ \(format.pageCount) หน้าและเต็มทุกหน้า — เอาของออกก่อนถึงจะเพิ่มได้")
    }

    /// แถบข้อความชั่วคราวเหนือขอบล่าง    /// แถบบอกหน้า — แตะกระโดดข้ามหน้าได้ ไม่ต้องปัดทีละหน้า
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
                .padding(.bottom, (isEditing ? bottomUI : 0) + 12)
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

    // MARK: - ถาดพื้นหลัง

    /// ถาดพื้นหลัง — เห็นครบไม่ต้องเลื่อน: แบบพื้น · สี (หรือรูป) · โทน
    ///
    /// เรื่องแรกคือ "พื้นแบบไหน" เพราะมันเปลี่ยนความหมายของแถวใต้มัน: เลือกรูปเมื่อไหร่
    /// แถวสีกลายเป็นแถวรูป และโทนถูกล็อก (ดู `CardTheme.activeInk`) — แถวโทนไม่หาย แค่จางลง
    /// พร้อมบอกเหตุผลเมื่อแตะ · ซ่อนแล้วผังกระโดดและคนจะถามว่าปุ่มหายไปไหน
    private var backdropTray: some View {
        VStack(spacing: 12) {
            // ขึ้นบรรทัดเองเมื่อชิปเต็มแถว — หกแบบไม่ลงในบรรทัดเดียวบนเครื่องเล็ก
            // แต่ถาดนี้ห้ามเลื่อน: แบบพื้นที่มองไม่เห็นคือแบบที่ไม่มีใครกด
            FlowLayout(spacing: 7) {
                ForEach(BackdropStyle.allCases) { st in
                    Button {
                        withAnimation(Motion.flow) {
                            theme.backdrop = st
                            // หมึกของพื้นรูปตัดสินจากรูปจริง — วัดในจังหวะเดียวกับที่สลับ (↶ ครั้งเดียวย้อนได้ทั้งคู่)
                            if st == .photo { theme.photoLean = photos.luma(theme.photoEffect)?.lean }
                        }
                        Haptics.impact(.light)
                    } label: {
                        optionChip(st.name, on: theme.backdrop == st) {
                            BackdropSwatch(theme: theme, style: st)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if theme.backdrop == .photo {
                backdropPhotoSource
                // เอฟเฟกต์กับความจางมีความหมายก็ต่อเมื่อมีรูปของผู้ใช้อยู่จริง —
                // รูปสำรองของระบบเป็นตัวยืนแทนชั่วคราว ไม่ใช่ของที่ครีเอเตอร์ตั้งใจเอามาแต่ง
                if photos.background != nil {
                    DockRow(label: "เอฟเฟกต์") {
                        DockSegment(options: BackdropEffect.allCases.map { .init(value: $0, title: $0.name) },
                                    selection: theme.photoEffect) { fx in
                            withAnimation(Motion.flow) {
                                theme.photoEffect = fx
                                // เบลอ/จุดปะเปลี่ยนความสว่างของรูปจริง — หมึกที่เหมาะอาจเปลี่ยนฝั่งตาม
                                theme.photoLean = photos.luma(fx)?.lean
                            }
                            Haptics.impact(.light)
                        }
                    }
                    DockRow(label: "ความจาง") {
                        TrackSlider(value: theme.photoDim / 0.8, tint: theme.rawAccent) {
                            theme.photoDim = min(0.8, max(0, $0 * 0.8))
                        }
                    }
                }
            } else {
                colorRow
                if colorOpen {
                    SpectrumPicker(hue: theme.backdropHSB.h,
                                   sat: theme.backdropHSB.s,
                                   bri: theme.backdropHSB.b) { h, s, b in
                        theme.setBackdropColor(h: h, s: s, b: b)
                        myColor = (h, s, b)
                    }
                    .transition(.opacity.combined(with: .offset(y: -8)))
                    hexField
                        .transition(.opacity.combined(with: .offset(y: -8)))
                }
            }

            // มุมกับแถบผู้ออกบัตรไม่ใช่ของที่ต้องถาม — ค่าตั้งต้นของธีมตัดสินให้ (ดู `CardTheme.corner` · `strip`)
            toneRow
            signatureRow
        }
        .animation(Motion.settle, value: colorOpen)
        .animation(Motion.settle, value: theme.backdrop == .photo)
        .animation(Motion.settle, value: photos.background != nil)
    }

    /// แถวสี — "สีของฉัน" ซ้าย (ตัวเลือกสีเอง + สีที่เคยตั้ง) · "สำเร็จรูป" ขวา
    ///
    /// แตะสีสำเร็จรูปดูเล่นแล้วสีแบรนด์ที่พิมพ์ไว้ต้องยังอยู่ให้กดกลับ — ไม่ใช่หายถาวร
    private var colorRow: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("สีของฉัน").font(.sh(10.5, .semibold)).foregroundStyle(.white.opacity(0.45))
                HStack(spacing: 9) {
                    // ตัวเลือกสีเอง — กางแถบสเปกตรัมใต้แถวนี้ (ถาดยืด ไม่ใช่สลับหน้า)
                    Button {
                        colorOpen.toggle()
                        Haptics.impact(.light)
                    } label: {
                        Circle()
                            .strokeBorder(.white.opacity(0.55),
                                          style: StrokeStyle(lineWidth: 1, dash: [3, 2.5]))
                            .frame(width: 30, height: 30)
                            .overlay(Image(systemName: "eyedropper")
                                .font(.sh(11, .semibold))
                                .foregroundStyle(.white.opacity(0.85)))
                            .background(Circle().fill(Color.white.opacity(colorOpen ? 0.2 : 0.04)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("เลือกสีเอง")

                    if let c = myColor {
                        let active = theme.hasCustomColor
                        Button {
                            withAnimation(Motion.flow) {
                                theme.setBackdropColor(h: c.h, s: c.s, b: c.b)
                            }
                            Haptics.impact(.light)
                        } label: {
                            Circle()
                                .fill(Color(hue: c.h, saturation: c.s, brightness: c.b))
                                .frame(width: 30, height: 30)
                                .overlay(Circle().strokeBorder(.white.opacity(active ? 0.95 : 0.25),
                                                               lineWidth: active ? 2 : 0.5))
                                .scaleEffect(active ? 1.1 : 1)
                        }
                        .buttonStyle(.plain)
                        .animation(Motion.snap, value: active)
                        .accessibilityLabel("สีของฉัน")
                    }
                }
            }
            Rectangle().fill(.white.opacity(0.14)).frame(width: 1, height: 30).padding(.top, 20)
            VStack(alignment: .leading, spacing: 6) {
                Text("สำเร็จรูป").font(.sh(10.5, .semibold)).foregroundStyle(.white.opacity(0.45))
                palettePresets
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// เม็ดสีสำเร็จรูป — **คู่สีมาก่อน แล้วค่อยเป็นสีเดี่ยว** อยู่ในแถวเดียวกัน
    ///
    /// ทั้งสองอย่างตอบคำถามเดียวกัน ("เอาสีสำเร็จอันไหน") ต่างกันแค่คู่สีตั้งสีหมึกให้ด้วย
    /// แยกเป็นคนละแถวเมื่อไหร่ ผู้ใช้ต้องอ่านสองหัวข้อก่อนถึงจะรู้ว่าต้องเลือกจากแถวไหน
    /// เม็ดผ่าครึ่งบอกความต่างนั้นได้ในตัวมันเองอยู่แล้ว — สองสีในเม็ดเดียว
    private var palettePresets: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(ColorDuo.all) { d in
                    let on = theme.duoID == d.id
                    Button {
                        // สีที่ตั้งเองต้องยังกดกลับได้ เหมือนตอนแตะสีเดี่ยว — คู่สีก็คือการลองดู
                        if let c = theme.customColor { myColor = c }
                        withAnimation(Motion.flow) { theme.setDuo(d) }
                        Haptics.impact(.light)
                    } label: {
                        DuoDot(duo: d, flipped: on && theme.duoFlipped, on: on)
                    }
                    .buttonStyle(.plain)
                    .animation(Motion.snap, value: on)
                    .accessibilityLabel("\(d.darkName) กับ \(d.lightName)")
                }
                ForEach(Palette.allCases) { p in
                    let active = theme.palette == p && !theme.hasCustomColor && theme.duoID == nil
                    Button {
                        // จำสีที่ตั้งเองไว้ก่อน — สีสำเร็จรูปคือการลองดู ไม่ใช่การทิ้งของเดิม
                        if let c = theme.customColor { myColor = c }
                        withAnimation(Motion.flow) {
                            theme.palette = p
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
                            .scaleEffect(active ? 1.1 : 1)
                    }
                    .buttonStyle(.plain)
                    .animation(Motion.snap, value: active)
                }
            }
            .padding(.vertical, 3).padding(.horizontal, 2)
        }
    }

    /// ช่องพิมพ์รหัสสี — แตะแล้วขึ้นกล่องถาม ไม่ใช่ช่องพิมพ์ที่ฝังอยู่ในถาด
    ///
    /// คีย์บอร์ดสูงเกินครึ่งจอ ฝังไว้ในถาดเมื่อไหร่มันขึ้นมาทับแถบสีสามแถบที่เพิ่งใช้เลือกสีอยู่
    /// กล่องถามขึ้นคนละชั้น ปิดแล้วทุกอย่างยังอยู่ที่เดิม
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

    private enum ToneChoice: Hashable { case dark, light }

    /// ลายเซ็น Sale Here บนตัวการ์ด — ถอดไม่ได้ แต่เลือกได้ว่าเป็นตัวเขียนจางหรือตราปั๊มนูน
    /// (ทั้งสองแบบใช้หมึกของการ์ดใบนั้น ไม่มีแบบไหนเอาสีแบรนด์มาวางทับงานของเจ้าของ)
    private var signatureRow: some View {
        let opts: [DockSegment<StripStyle>.Option] = [.init(value: .line, title: "ตัวเขียน"),
                                                      .init(value: .foil, title: "พิมพ์"),
                                                      .init(value: .emboss, title: "ปั๊มนูน")]
        return DockRow(label: "ลายเซ็น") {
            DockSegment(options: opts, selection: theme.strip.isStamp ? theme.strip : .line) { c in
                withAnimation(Motion.flow) { theme.strip = c }
                Haptics.impact(.light)
            }
        }
    }

    /// โทนหมึก — เหลือสองฝั่ง: มืด · สว่าง
    ///
    /// "กระดาษ" กับ "ใสใส" เป็นคนละหน้าตาก็จริง แต่การเลือกระหว่างสองอันนั้นคือคำถามของ
    /// **ความสดของพื้น** ไม่ใช่รสนิยม — ระบบตอบเองได้ (ดู `CardTheme.lightInk`) ส่วน "อัตโนมัติ"
    /// ไม่ใช่โทน มันคือสถานะตั้งต้นที่เงียบอยู่แล้ว · แถวนี้จึงชี้ค่าที่ใช้อยู่จริงเสมอ
    /// พื้นเป็นรูป = ล็อกกลางคืน (ดู `CardTheme.activeInk`) แถวยังอยู่แต่จาง แตะแล้วบอกเหตุผล
    private var toneRow: some View {
        let locked = theme.backdrop == .photo
        let sel: ToneChoice = theme.activeInk.isLight ? .light : .dark
        let opts: [DockSegment<ToneChoice>.Option] = [.init(value: .dark, title: "มืด"),
                                                      .init(value: .light, title: "สว่าง")]
        return DockRow(label: "โทน", dim: locked) {
            DockSegment(options: opts, selection: locked ? .dark : sel, dim: locked) { c in
                if locked {
                    flash("พื้นเป็นรูป — โทนล็อกเป็นกลางคืนให้ตัวหนังสืออ่านออกบนรูปทุกแบบ")
                    Haptics.rigid()
                    return
                }
                // คู่สีมีสองสีอยู่แล้ว — "สว่าง" จึงแปลว่ายกสีอ่อนของคู่ขึ้นมาเป็นพื้น
                // ไม่ใช่เปลี่ยนหมึกเป็นถ่านแล้วทิ้งสีที่สองไป · ปุ่มสลับข้างจึงไม่ต้องมีเพิ่ม
                if theme.duoColors != nil {
                    withAnimation(Motion.flow) { theme.duoFlipped = c == .light }
                    Haptics.impact(.light)
                    return
                }
                withAnimation(Motion.flow) {
                    theme.inkAuto = false
                    theme.ink = c == .dark ? .night : theme.lightInk
                }
                Haptics.impact(.light)
            }
        }
    }

    // MARK: รูปพื้นหลัง

    private var backdropPhotoSource: some View {
        DockRow(label: "รูป") {
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

    // MARK: - ถาดของชิ้น

    /// เนื้อในชีตของชิ้นที่เลือก — แบบอื่น (ถ้ามี) · กล่อง · ขอบ · แถวท้ายเป็นวิธีใช้กับปุ่มลบ
    ///
    /// หัวชีต (‹ + หมวดของชิ้น) อยู่ที่ `DockSheet` · ทุกอย่างในนี้คือของที่กดแล้วเกิดผลทันที
    /// ก้อนข้อความไม่มีกล่อง/ขอบ (แตะซ้ำแล้วทุกอย่างอยู่เหนือแป้นพิมพ์แบบ IG) เหลือแค่แถวท้าย
    private func pieceTray(_ sel: WidgetInstance) -> some View {
        let isText = sel.kind == .textBlock
        let resizable = sel.kind.canResize
        let hint = sel.pinned ? "Sale Here วางให้ทุกการ์ด · ย้ายหรือลบไม่ได้"
                 : isText ? "แตะซ้ำเพื่อพิมพ์ · ลากเพื่อย้าย · หมุดมุมย่อขยาย"
                 : resizable ? "หมุดข้างยืดกว้าง/สูง · หมุดมุมย่อขยายทั้งชิ้น · แตะตัวอักษรเพื่อแก้"
                 : "ลากเพื่อย้าย · ขนาดล็อก หลักฐานต้องเทียบกันได้"
        return VStack(spacing: 10) {
            if !isText {
                // ตรารับรองที่ตรึงไว้ไม่มีแบบอื่นให้สลับ — ขนาดกับที่ของมันคิดจากแบบนี้แบบเดียว
                if !sel.pinned { variantsRow(sel) }
                // กล่องเหลือสองแบบ: เข้ม หรือ กระจก — "ไม่มีพื้น" ไม่ใช่ตัวเลือกอีกแล้ว
                // ชิ้นที่วาดวัสดุของตัวเอง (กระดาษ · ฟิล์ม · ป้ายไฟ · รูปเต็มกรอบ) ไม่มีแถวนี้
                // เพราะพื้นของมันคือวัสดุนั้น ไม่ใช่แผ่นที่ chrome วาดให้
                if sel.kind.usesSurfaceChoice {
                    DockRow(label: "กล่อง") {
                        DockSegment(options: sel.kind.surfaceOptions.map {
                                        .init(value: $0, title: sel.kind.surfaceName($0)) },
                                    selection: sel.surface) { setSurface(sel, $0) }
                    }
                }
                // ลายทางบนแผ่น — มีเฉพาะตอนแผ่นของมันยังอยู่ (กระจก/ไม่มีพื้นไม่มีแผ่นให้ลาย)
                if sel.kind.takesPattern && sel.surface == .glass {
                    DockRow(label: "ลาย") {
                        DockSegment(options: PlatePattern.allCases.map { .init(value: $0, title: $0.name) },
                                    selection: sel.pattern) { setPattern(sel, $0) }
                    }
                }
                // หน้าต่างช่องทาง: โชว์ช่องไหน — ตั้งต้นคือช่องที่ยอดเยอะสุด (ดู `WindowChannel`)
                if sel.kind.picksChannel, Profile.me.creator.socials.count > 1 {
                    DockRow(label: "ช่องทาง") {
                        DockSegment(options: Profile.me.creator.socials.map {
                                        .init(value: $0.type, title: $0.type.shortName) },
                                    selection: WindowChannel.current(sel.id)?.type ?? .tiktok) {
                            WindowChannel.pick($0, for: sel.id)
                            Haptics.impact(.light)
                        }
                    }
                }
                // รูปคน: ลบพื้นหลังให้เอง (ตั้งต้น) หรือคงรูปเต็มไว้ในกรอบ
                if sel.kind.liftsSubject {
                    DockRow(label: "พื้นหลังรูป") {
                        DockSegment(options: [.init(value: true, title: "ลบออก"),
                                              .init(value: false, title: "คงไว้")],
                                    selection: sel.liftPhoto) { setLiftPhoto(sel, $0) }
                    }
                }
                // ตรารับรอง: หน้าตาสามแบบ เลือกรายชิ้น (ผู้ใช้เลือกจากผังตัวเลือก 1 ต.ค. 2569)
                if sel.kind == .proofSeal {
                    DockRow(label: "แบบ") {
                        DockSegment(options: SealStyle.allCases.map { .init(value: $0, title: $0.name) },
                                    selection: sel.sealStyle) { setSealStyle(sel, $0) }
                    }
                }
                // ตราปั๊มนูน Sale Here STAR บนแผ่นของใบนี้ — สีเดียวกับแผ่น ปิดได้รายชิ้น
                if sel.kind.takesEmboss {
                    DockRow(label: "ตรา") {
                        DockSegment(options: [.init(value: 0, title: "พิมพ์"),
                                              .init(value: 1, title: "ปั๊มนูน"),
                                              .init(value: 2, title: "ไม่มี")],
                                    selection: !sel.emboss ? 2 : (sel.embossBlind ? 1 : 0)) { setEmboss(sel, $0) }
                    }
                }
                DockRow(label: "ขอบ") {
                    DockSegment(options: [.init(value: true, title: "มีขอบ"),
                                          .init(value: false, title: "ไม่มีขอบ")],
                                selection: sel.border) { setBorder(sel, $0) }
                }
            }
            // แถวท้าย: ท่าที่ใช้กับชิ้นนี้ (เงียบ ๆ) + ลบ — ลบเป็นตัวหนังสือแดงในแคปซูลจาง
            // ไม่ใช่ปุ่มแดงทึบ ไม่งั้นมันดังกว่าทุกอย่างในถาดทั้งที่เป็นสิ่งที่กดน้อยที่สุด
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: sel.pinned ? "lock.fill" : isText ? "hand.tap" : (resizable ? "hand.draw" : "lock"))
                        .font(.sh(9.5))
                    Text(hint)
                        .font(.sh(10.5, .medium))
                        .lineLimit(1).minimumScaleFactor(0.65)
                }
                .foregroundStyle(.white.opacity(0.4))
                Spacer(minLength: 8)
                // ตรารับรองที่ตรึงไว้ไม่มีปุ่มลบ — คำยืนยันของ Sale Here ไม่ใช่ของที่เจ้าของการ์ดถอดได้
                if !sel.pinned {
                    Button { deleteWidget(sel) } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "trash").font(.system(size: 12, weight: .semibold))
                            Text("ลบ").font(.sh(12, .semibold))
                        }
                        .foregroundStyle(Color(red: 1, green: 0.5, blue: 0.45))
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(DockPress())
                    .accessibilityLabel("ลบ\(sel.kind.title)")
                }
            }
            .frame(minHeight: 34)
        }
    }

    /// แบบอื่นในตระกูลเดียวกัน — สิ่งแรกที่คนอยากรู้เวลาแตะชิ้นคือ "มันมีหน้าตาแบบอื่นไหม"
    /// ชิ้นที่มีแบบเดียวไม่มีแถวนี้เลย ไม่ใช่แถวว่าง
    @ViewBuilder
    private func variantsRow(_ sel: WidgetInstance) -> some View {
        let siblings = WidgetKind.allCases.filter { $0.family == sel.kind.family }
        if siblings.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(siblings) { k in
                        let active = k == sel.kind
                        Button { swap(sel, to: k) } label: {
                            VStack(spacing: 5) {
                                WidgetThumb(kind: k, theme: theme.toolTheme, width: 92)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(active ? theme.rawAccent : .white.opacity(0.14),
                                                          lineWidth: active ? 2 : 0.6)
                                    )
                                Text(k.title)
                                    .font(.sh(9.5, active ? .semibold : .regular))
                                    .foregroundStyle(active ? .white : .white.opacity(0.5))
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                    .frame(width: 92)
                            }
                            // พรีวิวปิด hit testing ไว้ (กันไม่ให้ widget ข้างในกินทัช)
                            // ถ้าไม่ประกาศ contentShape ปุ่มจะกดติดแค่ตรงข้อความใต้รูป
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .animation(Motion.snap, value: active)
                    }
                }
                .padding(.vertical, 2).padding(.horizontal, 1)
            }
        }
    }

    /// แก้สไตล์ตัวอักษรของชิ้นที่เลือก — รูปแบบเดียวกับ `setSurface`/`setBorder`
    private func setTextStyle(_ sel: WidgetInstance,
                              _ change: (inout WidgetTextStyle) -> Void) {
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            // ไม่สั่นตรงนี้ — ชิปที่เรียกมา (`FontChip` ฯลฯ) สั่นเองแล้ว สองที่จะกลายเป็นสั่นซ้อน
            withAnimation(Motion.flow) { change(&pages[pi].items[i].textStyle) }
            return
        }
    }

    private func setPattern(_ sel: WidgetInstance, _ on: PlatePattern) {
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            withAnimation(Motion.flow) { pages[pi].items[i].pattern = on }
            Haptics.impact(.light)
            return
        }
    }

    private func setSealStyle(_ sel: WidgetInstance, _ style: SealStyle) {
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            withAnimation(Motion.flow) { pages[pi].items[i].sealStyle = style }
            Haptics.impact(.light)
            return
        }
    }

    /// 0 = ฟอยล์ · 1 = ปั๊มนูน · 2 = ไม่มี
    private func setEmboss(_ sel: WidgetInstance, _ mode: Int) {
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            withAnimation(Motion.flow) {
                pages[pi].items[i].emboss = mode != 2
                pages[pi].items[i].embossBlind = mode == 1
            }
            Haptics.impact(.light)
            return
        }
    }

    private func setLiftPhoto(_ sel: WidgetInstance, _ on: Bool) {
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            withAnimation(Motion.flow) { pages[pi].items[i].liftPhoto = on }
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
        guard !sel.pinned else { return }
        guard let pi = pages.firstIndex(where: { $0.items.contains { $0.id == sel.id } }),
              let ii = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { return }
        let removed = pages[pi].items[ii]
        withAnimation(Motion.flow) {
            pages[pi].items.remove(at: ii)
        }
        // ปิดชีตด้วย — สองเหตุผล: แผงที่เปิดค้างอยู่เป็นแผงของของที่ไม่มีอยู่แล้ว (ตอนนี้มันเด้ง
        // ไปเป็นแผงธีมของทั้งการ์ดแทน ซึ่งไม่มีใครขอ) และชีตบังขอบล่างของจอพอดี — ที่ที่แถบ
        // "เลิกทำ" ยืนอยู่ · ไม่ปิดก็เท่ากับยื่นทางกลับให้แล้วเอาไปซ่อนไว้หลังชีต
        withAnimation(Motion.settle) { dock = .main }
        Haptics.impact(.medium)
        offer("ลบ\(sel.kind.title)แล้ว", "เลิกทำ") {
            withAnimation(Motion.flow) {
                let p = min(pi, pages.count - 1)
                pages[p].items.insert(removed, at: min(ii, pages[p].items.count))
                // พากลับไปหน้าที่มันเคยอยู่ด้วย — ระหว่างห้าวินาทีนั้นผู้ใช้ปัดไปหน้าอื่นได้
                // แล้วของที่คืนมาจะโผล่นอกสายตาโดยไม่มีอะไรบอกว่ามันกลับมาแล้ว
                index = p
                dock = .piece(removed.id)
            }
            Haptics.impact(.light)
        }
    }

    /// สลับแบบโดยคงตำแหน่งเดิมไว้ · บีบขนาดให้เข้ากรอบของแบบใหม่
    private func swap(_ sel: WidgetInstance, to kind: WidgetKind) {
        guard kind != sel.kind, !sel.pinned else { return }
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            var w = pages[pi].items[i]
            w.kind = kind
            // แบบใหม่มีสัดส่วนของตัวเอง — คงความกว้างไว้ แล้วให้ความสูงมาจากผังของแบบใหม่
            w.resetAspect()
            // แบบใหม่อาจล้นหน้าถ้าเดิมถูกยืดไว้สุด — รูดกลับเข้าหน้า ตำแหน่งเดิมคงไว้เท่าที่ทำได้
            w.rect = PageLayout.clamp(w, page: pageSize)
            // แบบใหม่บุคลิกต่างจากเดิม — กลับไปใช้พื้นตั้งต้นของมัน
            w.surface = kind.defaultSurface
            w.border = kind.defaultBorder
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

/// เม็ดสีของคู่สีหนึ่งคู่ — วงกลมขนาดเดียวกับสีเดี่ยว ผ่าครึ่งเป็นสองสีของคู่
///
/// ซีกซ้ายคือสีพื้น ซีกขวาคือสีหมึก — สลับข้างที่แถวโทนเมื่อไหร่ สองซีกสลับตาม
/// เม็ดจึงบอกได้เสมอว่ากดแล้วการ์ดจะออกมาหน้าไหน ไม่ใช่แค่ "คู่นี้มีสีอะไรบ้าง"
private struct DuoDot: View {
    let duo: ColorDuo
    let flipped: Bool
    let on: Bool

    var body: some View {
        let bg = flipped ? duo.light : duo.dark
        let ink = flipped ? duo.dark : duo.light
        Circle()
            .fill(ink)
            .overlay(alignment: .leading) { Rectangle().fill(bg).frame(width: 15) }
            .clipShape(Circle())
            .frame(width: 30, height: 30)
            .overlay(Circle().strokeBorder(.white.opacity(on ? 0.95 : 0.2),
                                           lineWidth: on ? 2 : 0.5))
            .scaleEffect(on ? 1.1 : 1)
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
            case .grid:
                LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
                BackdropGrid(line: .white.opacity(t.activeInk.isLight ? 0.6 : 0.12), step: 6)
            case .stripe:
                c.top
                BackdropStripes(band: t.stripeInk, width: 3)
            case .diamond:
                c.top
                BackdropDiamonds(band: t.stripeInk, width: 8)
            case .glow:
                c.bottom
                // ดวงแสงย่อ — ต้องเบลอน้อยกว่าของจริงตามสัดส่วน ไม่งั้นเละเป็นสีเดียว
                Circle().fill(t.accent.opacity(0.75)).frame(width: 16, height: 16)
                    .blur(radius: 6).offset(x: -6, y: -5)
                Circle().fill(t.accentSoft.opacity(0.5)).frame(width: 14, height: 14)
                    .blur(radius: 6).offset(x: 7, y: 6)
            case .solid:
                c.top
            case .marble:
                LinearGradient(colors: [c.top, c.bottom],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                // ลายเดียวกับของจริงแต่ต้องดันความหนาขึ้น — ที่ 24×17pt เส้นตามสัดส่วนจริงบางจนหายไปหมด
                MarbleVeins(vein: t.marbleInk.vein, bleed: t.marbleInk.bleed, lineScale: 3.6)
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


/// คำขอจากตู้ widget: ใบ `kind` ต้องการหัวข้อ `topic` ที่ยังว่าง
struct TopicFillRequest: Identifiable {
    let kind: WidgetKind
    let topic: StarTopic
    /// true = ขอจากตู้ (กรอกเสร็จวางใบให้) · false = แตะใบที่วางอยู่แล้วบนการ์ด (กรอกเสร็จใบปลดล็อกเอง)
    var place = true
    var id: String { kind.rawValue }
}
