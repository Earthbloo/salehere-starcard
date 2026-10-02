import SwiftUI

// MARK: - โปสเตอร์ผู้ติดตาม
//
// แปลงตรงจากแผ่น **SOCIAL MEDIA STATS** (พาดหัวยักษ์ + แถวตัวเลขคั่นด้วยเส้น)
// โดยใช้ภาษาเดียวกับสำรับโปสเตอร์ของตู้ (`artPortfolio` · `nichePoster` · `contactPoster`):
// พาดหัวสองบรรทัดผสมสองฟอนต์ · เส้นคาด · แถวตัวเลข · เส้นปิด — **ไม่มีอย่างอื่นเลย**
//
// # สิ่งที่ใบนี้ทำแล้วอีกสามใบในตระกูล `followers` ทำไม่ได้
//
// `socialChips` กับ `socialTiles` คือ **ป้ายข้อมูล** — กล่องหนึ่งกล่องต่อหนึ่งช่อง
// อ่านเป็นรายการที่เรียงต่อกัน ซึ่งถูกสำหรับการ์ดที่วางข้อมูลหลายชุดเรียงกันลงมา
// ส่วน `statGiant` เป็นตัวเลขรวมตัวเดียว ซึ่งตอบคำถาม "ใหญ่แค่ไหน" แต่ไม่ตอบ "ช่องไหน"
//
// ใบนี้เอายอดรายช่องชุดเดิมไปวางเป็น **แถวสถิติใต้พาดหัว** แล้วมันเปลี่ยนความหมายทั้งใบ:
// จาก "ช่องทางของเขามีอะไรบ้าง" เป็น "นี่คือขนาดของเขา" — สไลด์หน้าเดียวที่ครีเอเตอร์
// ส่งให้แบรนด์อยู่แล้ว · ตัวเลขไม่ได้อยู่ในกล่องของตัวเองอีกต่อไป มันเรียงอยู่บนเส้นเดียวกัน
// ซึ่งเป็นสิ่งเดียวที่ทำให้สายตา **เทียบสามช่องพร้อมกัน** ได้ในวินาทีเดียว
//
// # ตัวเลขสลับสี ไม่ใช่เพื่อสวย
//
// ต้นฉบับสลับแดง/ขาวทีละช่อง — บนแถวที่มีสี่ตัวเลขติดกัน สีที่สลับคือสิ่งที่บอกตาว่า
// "ตัวไหนจบตรงไหน" โดยไม่ต้องพึ่งเส้นคั่นอย่างเดียว (เส้นคั่นบาง 0.8pt หายไปทันทีที่ย่อการ์ด
// ลงเป็นพรีวิวในตู้ ส่วนสีไม่หาย) · ที่นี่จึงเก็บกติกานั้นไว้ แต่เปลี่ยนแดงเป็นสีเน้นของธีม
//
// # ทั้งใบมีพื้นและไม่มีพื้น
//
// ต้นฉบับเป็นแถบดำทึบ ซึ่งเป็น *ดีไซน์* ไม่ใช่กรอบที่ chrome ครอบให้ — คำถามเดียวที่เหลือ
// จึงเป็น "เอาแผ่นไหม" เหมือนอีกสามใบของสำรับ (ดู `WidgetKind.surfaceOptions`)
// มีแผ่น = สไลด์ที่พิมพ์เสร็จแล้ว · ไม่มีแผ่น = พาดหัว เส้น และตัวเลข นั่งบนการ์ดตรง ๆ

/// ค่าคงที่ของผัง — **หน่วยเดียวกับ `WidgetKind.defaultSize`** (366 × 214)
///
/// เขียนเป็นตัวเลขคงที่แทนสัดส่วนของกรอบ เพราะ `PosterSheet` ย่อ/ขยายทั้งก้อนให้อยู่แล้ว
/// (เนื้อหาถูกวาดที่ขนาดออกแบบเสมอ) ผังจึงเป็นจริงทุกขนาด
enum SP {
    static let w: CGFloat = 366
    static let h: CGFloat = 214

    /// ขอบของทั้งแผ่น — เส้นคาดสองเส้นชนขอบนี้ ไม่ใช่ชนขอบแผ่น (โปสเตอร์ไม่ใช่ตาราง)
    static let pad: CGFloat = 18
    static let top: CGFloat = 18
    static let bottom: CGFloat = 16

    /// เพดานของพาดหัวสองบรรทัด — บรรทัดล่างใหญ่กว่าชัดเจน (วัดจากความสูงตัวพิมพ์ใหญ่)
    static let cap1: CGFloat = 30
    static let cap2: CGFloat = 42
    /// ความกว้างที่แต่ละบรรทัดถูก *จัดให้เต็ม* — **ไม่ใช่เต็มแผ่นทั้งคู่**
    ///
    /// ความต่างของสองความกว้างคือสิ่งที่ทำให้ก้อนพาดหัวเป็น *รูปทรง* ไม่ใช่สองบรรทัด
    /// ที่บังเอิญยาวเท่ากัน (กติกาเดียวกับโปสเตอร์สายงาน — ดู `NP.line1W`)
    static let line1W: CGFloat = 0.60
    static let line2W: CGFloat = 0.96

    /// แถวสถิติ — ไอคอน · ตัวเลข · ชื่อช่อง
    ///
    /// **ไอคอนใหญ่กว่าตัวเลขโดยตั้งใจ** — ตอนที่ใบนี้ยังมีบรรทัดนำกับฐาน ตัวเลขคือของชิ้นเดียว
    /// ที่ดังพอจะถือแผ่นไว้ได้ · พอถอดตัวอักษรรอบนอกออกหมด แผ่นเหลือของอยู่สามอย่าง
    /// และ *ตรา* ก็ดังได้เท่ากับตัวเลข — โลโก้ที่อ่านออกในแวบเดียวตอบคำถาม "ช่องไหน"
    /// ได้เร็วกว่าชื่อช่องที่พิมพ์ไว้ข้างล่าง ซึ่งเป็นคำถามแรกที่แบรนด์ถาม ไม่ใช่คำถามที่สอง
    static let icon: CGFloat = 27
    static let label: CGFloat = 9.5
}

/// วัสดุและหมึกของใบนี้ — **ทุกสีคิดจากเฉดของธีม ไม่มีสีตายตัวสักสี**
///
/// ต้นฉบับเป็นดำกับแดง ซึ่งถูกตอนอยู่บนสไลด์ใบนั้น แต่บนการ์ดที่เจ้าของเลือกพาเลตต์เอง
/// มันจะกลายเป็นสีที่ไม่มีที่มา · ที่นี่จึงเก็บ **ความสัมพันธ์** ของต้นฉบับไว้แทนตัวสี:
/// แผ่นเข้มจัดอิ่มสี · หมึกเป็นครีมที่อมเฉดเดียวกัน · สีสลับเป็นสีเน้นที่จูนมาสำหรับพื้นมืด
struct StatPosterSkin {
    var papered: Bool
    var plate: Color
    var ink: Color
    var soft: Color
    /// สีของตัวเลขช่องคี่ และเส้นคาดใต้พาดหัว
    var accent: Color
    /// เส้นคั่นระหว่างช่อง และเส้นคาดเหนือฐาน
    var hair: Color

    static func make(_ surface: WidgetSurface, theme: CardTheme, on ink: InkStyle) -> StatPosterSkin {
        if surface == .pane {
            return StatPosterSkin(papered: true, plate: .clear,
                                  ink: ink.text(0.95),
                                  soft: ink.text(0.58),
                                  accent: theme.accent,
                                  hair: ink.line(0.24))
        }
        guard surface == .clear else {
            // สีแผ่นกับครีมมาจากสูตรกลางของตู้ (`PosterPlate`) — โปสเตอร์สายงานกับแผ่นโชว์คลิป
            // ใช้ชุดเดียวกัน การ์ดที่วางสองใบนี้ไว้ด้วยกันจึงได้แผ่นสีเดียวกันเป๊ะ
            let cream = PosterPlate.cream(theme)
            return StatPosterSkin(papered: true,
                                  plate: PosterPlate.plate(theme),
                                  ink: cream,
                                  soft: cream.opacity(0.66),
                                  // ดิบ ไม่ใช่ `theme.accent` — แผ่นนี้มืดเสมอ ไม่ว่าการ์ดจะเป็นกระดาษ
                                  // สีเน้นที่ถูกย้อมให้เข้มพอสำหรับพื้นขาวจะจมหายไปกับแผ่น
                                  accent: theme.rawAccent,
                                  hair: cream.opacity(0.24))
        }
        return StatPosterSkin(papered: false, plate: .clear,
                              ink: ink.text(0.95),
                              soft: ink.text(0.58),
                              accent: theme.accent,
                              hair: ink.line(0.24))
    }
}

// MARK: - ใบ

struct StatPosterWidget: View {
    @Environment(\.widgetID) private var wid
    @Environment(\.pageScrub) private var scrub
    @Environment(\.widgetSurface) private var surface
    @Environment(\.cardInk) private var cardInk
    /// พาดหัวบรรทัดบนเป็นตัวหนาต่อด้วยเซริฟเอียงในก้อนเดียว จึงตั้งฟอนต์เอง
    /// (ตัวประกาศช่องใส่ฟอนต์ให้ได้เฉพาะก้อนที่ไม่ได้ตั้งเอง — ดู `EditableTextModifier`)
    @Environment(\.widgetTextStyle) private var tune
    @Environment(\.widgetEmboss) private var embossed
    @Environment(\.widgetEmbossBlind) private var embossBlind
    @Environment(\.saleHereStamped) private var stamped
    let theme: CardTheme
    let size: CGSize

    /// พาดหัวเป็นของ **ดีไซน์** ไม่ใช่ของโปรไฟล์ จึงเก็บต่อชิ้นแบบเดียวกับสำรับบรรณาธิการ
    /// (วางใบนี้สองที่แล้วพาดหัวคนละคำได้ — เป็นเรื่องปกติของโปสเตอร์)
    private static let line1Preset = "MY Social"
    private static let line2Preset = "MEDIA STATS"

    private var socials: [SocialProfile] { Profile.me.shownSocials }

    var body: some View {
        // แผ่นต้องเต็มกรอบเสมอ ทั้งกว้างและสูง ทุกเคส (ดู `PosterSheet`)
        PosterSheet(design: CGSize(width: SP.w, height: SP.h), frame: size) { box in
            sheet(box)
        }
    }

    /// - Parameter box: ผังในหน่วยออกแบบที่ยืดเต็มกรอบแล้ว (≥ `SP.w × SP.h`)
    private func sheet(_ box: CGSize) -> some View {
        let skin = StatPosterSkin.make(surface, theme: theme, on: cardInk)
        let shape = RoundedRectangle(cornerRadius: skin.papered ? min(theme.radius, 20) : 0,
                                     style: .continuous)

        return ZStack(alignment: .topLeading) {
            Color.clear

            // ── แผ่น
            if skin.papered {
                skin.plate
                PlatePatternLayer(sheet: skin.plate)
                // เกล็ดจาง ๆ ชั้นเดียว — แผ่นสีเรียบล้วนที่ความกว้างเท่านี้อ่านเป็นรูปที่ยังโหลดไม่เสร็จ
                EdGrain(count: 260, opacity: 0.04, tint: .white)
            }

            // # ทั้งใบมีของอยู่สามอย่าง — พาดหัว · เส้น · ตัวเลข
            //
            // รอบแรกมีบรรทัดนำ (สายงาน + ป้ายที่มา) กับฐาน (สายงาน + ชื่อ) ประกบอยู่ด้วย
            // ตามลายเซ็นของสำรับโปสเตอร์ · แต่บนใบที่ **เนื้อหาคือตัวเลข** มันไม่ได้ทำงานแบบเดียวกัน:
            // โปสเตอร์พอร์ตกับโปสเตอร์สายงานมีรูปคนเป็นตัวนำ บรรทัดเล็กสี่มุมจึงเป็นกรอบให้ภาพ
            // ใบนี้ไม่มีภาพ บรรทัดเล็กสี่มุมจึงกลายเป็น *ตัวอักษรอีกสี่ก้อน* ที่แย่งสายตากับตัวเลข
            // ทั้งที่ชื่อกับสายงานมีอยู่แล้วบนการ์ดใบเดียวกัน (ใบโปรไฟล์อยู่เหนือมันขึ้นไป)
            VStack(spacing: 0) {
                headline(skin, w: box.width)
                    .padding(.top, SP.top + (stamped ? 8 : 0))

                // เส้นคาดใต้พาดหัว — หนากว่าเส้นล่างและเป็นสีเน้น เพราะมันคือ *ขอบล่างของพาดหัว*
                // ไม่ใช่เส้นแบ่งตาราง (ขอบล่างของแถวสถิติได้เส้นบางของมันเองอยู่แล้ว)
                Rectangle().fill(skin.accent).frame(height: 1.4)
                    .padding(.top, 10)
                    .scrubVeil(scrub.d, lead: 0.1, drop: 14, pull: 18)

                Spacer(minLength: 6)

                stats(skin, w: box.width)

                Spacer(minLength: 6)

                // เส้นปิดแถว — ต้นฉบับมีเส้นประกบตัวเลขทั้งบนและล่าง ไม่ใช่เส้นเดียวข้างบน
                // มันคือสิ่งที่ทำให้แถวตัวเลขเป็น *แถบ* ไม่ใช่ของที่ลอยอยู่ครึ่งล่างของแผ่น
                Rectangle().fill(skin.hair).frame(height: 0.8)
                    .padding(.bottom, SP.bottom)
                    .scrubVeil(scrub.d, lead: 0.16, drop: 14, pull: 18)
            }
            .padding(.horizontal, SP.pad)

            // ป้าย Verified by Sale Here มุมขวาบน (ไม่กลาง — ผู้ใช้ 30 ก.ย. 2569) · พาดหัวเลื่อนลงให้พ้นป้าย
            // ผังโปสเตอร์ถูกย่อตามกรอบ (ออกแบบกว้าง 366) ขนาดจึงใหญ่กว่าใบอื่นเพื่อให้บนการ์ดเท่ากัน
            if stamped {
                SaleHereByline(tint: skin.ink.opacity(0.9), size: 10.5)
                    .padding(.top, 10).padding(.trailing, 12)
                    .frame(width: box.width, height: box.height, alignment: .topTrailing)
                    .allowsHitTesting(false)
            }

            // ตราปั๊มนูนมุมขวาบน — ใบนี้ตั้งใจไม่มีบรรทัดเล็ก จึงบอกว่า "ตัวเลขนี้ Sale Here ออกให้" ด้วยตรานูนแทนป้าย
            // ขึ้นเฉพาะเมื่อยอดทุกช่องมาจากแพลตฟอร์มจริง (ยอดกรอกเองไม่มีสิทธิ์ได้ตราของผู้ออก)
            if embossed, VerifiedFacts.numbersVerified {
                EmbossedLockup(height: embossBlind ? 19 : 21, light: surface == .glass ? false : cardInk.isLight,
                               foil: !embossBlind, tint: skin.ink)
                    .padding(.top, 13).padding(.trailing, 15)
                    .frame(width: box.width, height: box.height, alignment: .topTrailing)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: box.width, height: box.height)
        .clipShape(shape)
    }

    // MARK: พาดหัว

    /// สองบรรทัดกลางแผ่น — **แต่ละบรรทัดถูกจัดให้เต็มความกว้างของตัวเอง** (ดู `SP.line1W`)
    ///
    /// ขนาดตายตัวใช้ไม่ได้: คำสั้นจะลอยอยู่กลางแผ่นโดยมีที่ว่างสองข้างเป็นคืบ ส่วนคำยาว
    /// ถูกย่อจนเป็นบรรทัดจิ๋ว — ทั้งสองอย่างไม่ใช่พาดหัวโปสเตอร์แล้ว
    ///
    /// # บรรทัดบนมีสองหน้าตาในก้อนเดียว
    ///
    /// รอบแรกใบนี้เป็นพาดหัวบรรทัดเดียวหนาล้วน ซึ่งอ่านเป็น *ป้ายหัวข้อ* ไม่ใช่โปสเตอร์ —
    /// ตัวหนาล้วนไม่มีจังหวะข้างในตัวมันเอง มันจึงเป็นแค่แถบตัวอักษรที่หนา
    ///
    /// ท่าที่ใช้แทนคือท่าเดียวกับโปสเตอร์สายงาน (`NichePosterWidget.mixedLine`) เป๊ะ ๆ:
    /// **คำแรกหนา ที่เหลือเซริฟเอียง** — กฎข้อเดียวที่ผู้ใช้รู้สึกได้เอง พิมพ์ทับได้ทั้งบรรทัด
    /// ในช่องเดียวแล้วหน้าตาสองท่อนยังอยู่ · ต่อ `Text` เข้าด้วยกันไม่ใช่วางสอง `Text` ใน `HStack`
    /// เพราะการย่อให้พอดีบรรทัดต้องเกิดกับทั้งก้อนพร้อมกัน
    private func headline(_ skin: StatPosterSkin, w: CGFloat) -> some View {
        let l1 = Profile.me.note(wid, 1, preset: Self.line1Preset)
        let l2 = Profile.me.note(wid, 2, preset: Self.line2Preset).uppercased()
        let fs1 = Ed.fitted(l1, weight: .heavy, width: w * SP.line1W, cap: SP.cap1, floor: 12)
        let fs2 = Ed.fitted(l2, weight: .heavy, width: w * SP.line2W, cap: SP.cap2, floor: 13)

        // ระยะระหว่างบรรทัดติดลบ — **ไม่ใช่การบีบให้สวย แต่เป็นการหักที่ว่างที่ฟอนต์เผื่อไว้**
        // NotoSansThai กันที่ให้สระบน/วรรณยุกต์ไว้เหนือทุกบรรทัดเสมอ พาดหัวอังกฤษล้วนจึงมี
        // ช่องว่างเปล่าราวหนึ่งในสามของตัวอักษรคั่นอยู่ ซึ่งในสายตาคืออีกบรรทัดที่หายไป
        return VStack(alignment: .center, spacing: -fs1 * 0.30) {
            mixedLine(l1, size: fs1, color: skin.ink)
                .lineLimit(1).minimumScaleFactor(0.4)
                .editableText(.note, index: 1, widget: wid,
                              preset: Self.line1Preset, hint: "พาดหัวบรรทัดบน",
                              .init(size: fs1, weight: .heavy, color: skin.ink,
                                    align: .center, tracking: -fs1 * 0.03, corner: 6))
            Text(l2)
                // heavy ไม่ใช่ black — ที่น้ำหนักหนาสุด NotoSansThai วางสระบนชนวรรณยุกต์
                .kerning(-tune.scaled(fs2, for: .note, 2) * 0.035)
                .lineLimit(1).minimumScaleFactor(0.4)
                .editableText(.note, index: 2, widget: wid,
                              preset: Self.line2Preset, hint: "พาดหัวบรรทัดล่าง",
                              .init(size: fs2, weight: .heavy, color: skin.ink,
                                    align: .center, tracking: -fs2 * 0.035,
                                    uppercase: true, corner: 6))
        }
        .frame(maxWidth: .infinity)
        // ชั้นหลังสุดวิ่งสวนแรงที่สุด — ตาอ่านความลึกจาก *ความต่างของอัตรา* ไม่ใช่จากระยะ
        .scrubSlide(scrub.d, travel: -SP.w * 0.26, fade: 0.84, eased: false)
    }

    /// คำแรกหนา · ที่เหลือเซริฟเอียง — คืน `Text` ก้อนเดียวที่ย่อพร้อมกันทั้งบรรทัด
    /// (ก๊อปกติกามาจาก `NichePosterWidget` ตรง ๆ — สองใบนี้ต้องพูดสำเนียงเดียวกัน)
    private func mixedLine(_ raw: String, size: CGFloat, color: Color) -> Text {
        let parts = raw.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let s = tune.scaled(size, for: .note, 1)
        let head = Text(String(parts.first ?? "").uppercased())
            .font(tune.font(size, .heavy, for: .note, 1))
            .kerning(-s * 0.03)
        guard parts.count > 1 else { return head.foregroundColor(color) }
        // เซริฟที่ขนาดเท่ากันดู *เตี้ยกว่า* ตัวหนา (x-height ต่างกัน) — ชดเชยขึ้นเล็กน้อย
        // ฟอนต์ที่ผู้ใช้สั่งทับมาก่อนเซริฟของดีไซน์ — สั่งแล้วต้องได้ทั้งบรรทัด ไม่ใช่ครึ่งเดียว
        let tail = Text(" " + String(parts[1]))
            .font((tune.face(for: .note, 1) ?? .serif).font(s * 1.04, .regular).italic())
        return (head + tail).foregroundColor(color)
    }

    // MARK: แถวสถิติ

    /// ทุกช่องกว้างเท่ากันและคั่นด้วยเส้นตั้ง — **ความกว้างเท่ากันคือสิ่งที่ทำให้มันเทียบกันได้**
    ///
    /// ถ้าปล่อยให้แต่ละช่องกว้างตามตัวเลขของตัวเอง ช่องที่ยอดเยอะ (ตัวเลขยาวกว่า) จะได้พื้นที่
    /// มากกว่าโดยอัตโนมัติ ซึ่งอ่านเป็นการให้น้ำหนัก ทั้งที่มันเป็นแค่ผลข้างเคียงของจำนวนหลัก
    private func stats(_ skin: StatPosterSkin, w: CGFloat) -> some View {
        let n = max(socials.count, 1)
        // ตัวเลขเล็กลงเมื่อช่องเยอะ — ที่หกช่อง ช่องหนึ่งกว้างราว 55pt ซึ่งตัวเลข 22pt ล้นแน่
        let numSize: CGFloat = n >= 5 ? 16 : (n == 4 ? 19 : 22)

        return HStack(spacing: 0) {
            ForEach(Array(socials.enumerated()), id: \.element.id) { i, s in
                if i > 0 {
                    Rectangle()
                        .fill(skin.hair)
                        .frame(width: 0.8)
                        .padding(.vertical, 3)
                        .scrubVeil(scrub.d, lead: 0.2, drop: 10, pull: 14)
                }
                column(s, i: i, of: n, skin: skin, numSize: numSize)
                    .frame(maxWidth: .infinity)
                    .linkSlot(s.profileURL)
            }
        }
        // ลบช่องออกหนึ่งช่องแล้วลำดับที่เหลือเลื่อน — ผูก id กับลิสต์ให้ SwiftUI สร้างใหม่ทั้งชุด
        .id(socials.map(\.id))
    }

    private func column(_ s: SocialProfile, i: Int, of n: Int,
                        skin: StatPosterSkin, numSize: CGFloat) -> some View {
        let lead = Scrub.lead(i, of: n, d: scrub.d, step: 0.08)
        // สลับสีทีละช่อง ตามต้นฉบับ — ช่องแรกได้สีเน้น
        let tint = i % 2 == 0 ? skin.accent : skin.ink

        return VStack(spacing: 5) {
            // โลโก้คงสีต้นฉบับของแพลตฟอร์ม ไม่ย้อมตามแผ่น — มันคือ *ตรา* ไม่ใช่ไอคอนของระบบ
            // และเป็นสิ่งเดียวบนใบนี้ที่บอกว่าเป็นช่องไหนโดยไม่ต้องอ่าน
            BrandIcon(name: s.type.icon, size: SP.icon)
                .scrubLouver(scrub.d, lead: lead, angle: 70, shrink: 0.2)

            // ตัวเลขคือหลักฐาน มันถูกถอดออกทีละหลัก ไม่ใช่จางหายทั้งก้อน
            ScrubDigits(text: Fmt.compact(s.followerCount), d: scrub.d,
                        lead: lead + 0.04, step: 0.05, drop: 24)
                .dataValue()
                .font(.sh(numSize, .heavy))
                .foregroundStyle(tint)
                .lineLimit(1).minimumScaleFactor(0.5)

            Text(s.type.name)
                .font(.sh(SP.label, .semibold))
                .kerning(SP.label * 0.1)
                .foregroundStyle(skin.soft)
                .lineLimit(1).minimumScaleFactor(0.6)
                .scrubVeil(scrub.d, lead: lead, drop: 14, pull: 8)
        }
        .padding(.horizontal, 4)
    }

}
