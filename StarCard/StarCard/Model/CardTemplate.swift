import SwiftUI

/// เทมเพลตการ์ดสำเร็จรูป — ผังทั้งใบ + ธีม ที่ประกอบเสร็จแล้วให้เลือกเป็นจุดตั้งต้น
///
/// # โครงของตู้: 6 ผังต่อรูปแบบการ์ด จากสองตระกูล
///
/// ทุกใบสืบสายจากสองบุคลิกที่ชนะ: **สปอตไลต์** (โปสเตอร์/ภาพยนตร์ — จัดจ้าน มั่นใจ)
/// กับ **โฟโต้การ์ด** (การ์ดสะสม/แฟนด้อม — ดรีมมี่ ละมุน) อย่างละ 3 ผัง คละสลับกันในลิสต์
///
/// กติกาที่ทุกใบต้องผ่าน:
/// 1. **ผังต้องต่างกันด้วยตาเปล่า** — ต่างที่โครงสร้าง ไม่ใช่แค่สี (สีเป็นแค่ผลพลอยได้ของบุคลิก)
/// 2. **รูปนำ ข้อมูลเสริม ทุกหน้า** — การ์ดขายตัวตนกับสไตล์ก่อน ตัวเลขค่อยตาม
/// 3. ครบวงจรตัดสินใจจ้าง: ตัวตน → ผลงาน → ตัวเลข → ราคา → ติดต่อ
struct CardTemplate: Identifiable, Equatable {
    let id: String
    let format: CardFormat
    /// ชื่อ = ตระกูล + ท่าของผัง ("สปอตไลต์ คู่คลิป") — บอกโครงสร้างตั้งแต่ชื่อ
    let name: String
    /// ป้ายตระกูล — กวาดตาแยก โปสเตอร์/โฟโต้การ์ด ได้ตอนปัดเร็ว ๆ
    let vibe: String
    /// หนึ่งประโยคบอกว่าผังนี้เล่าเรื่องต่างจากใบอื่นยังไง
    let blurb: String
    let theme: CardTheme
    private let builder: () -> [CardPage]

    /// สร้างหน้าชุดใหม่ทุกครั้ง — `WidgetInstance.id` เป็นของรันไทม์
    /// ถ้าเก็บหน้าไว้เป็นค่าคงที่ การ์ดสองใบที่มาจากเทมเพลตเดียวกันจะแชร์ id กัน
    func makePages() -> [CardPage] { builder() }

    static func == (l: CardTemplate, r: CardTemplate) -> Bool { l.id == r.id }

    /// ขนาดหน้ามาตรฐานที่ใช้ทั้งตอนออกแบบผังและตอนวาดพรีวิว
    /// ช่องว่างระหว่างหน้าในรูปย่อของหน้าเลือกเทมเพลต (หน่วยออกแบบ)
    ///
    /// 26 จาก 402 = 6.5% ของความกว้างหน้า — ที่ขนาดรูปย่อจริงราว 3.5pt
    /// พอที่จะอ่านเป็น "คนละแผ่น" แต่ยังไม่ถึงขั้นแยกกันจนไม่เห็นว่าต่อกันเป็นแถบเดียว
    static let thumbGutter: CGFloat = 26

    static func previewPageSize(for format: CardFormat) -> CGSize {
        switch format {
        case .portfolio: return CGSize(width: 402, height: 670)
        case .story:     return CGSize(width: 540, height: 960)
        }
    }

    static func all(for format: CardFormat) -> [CardTemplate] {
        // คละสลับตระกูลทีละใบ: โปสเตอร์ · โฟโต้การ์ด · โปสเตอร์ · …
        switch format {
        case .story:
            return [.storyPosterDuo, .storyCardCollage, .storyPosterFull,
                    .storyCardBinder, .storyPosterReels, .storyCardAura]
        case .portfolio:
            return [.portPoster, .portCardCollage, .portPosterCover,
                    .portCardScrapbook, .portPosterReels, .portCardAura]
        }
    }

    private static func theme(_ palette: Palette, _ ink: CardInk, _ corner: CornerStyle,
                              _ backdrop: BackdropStyle, _ brightness: Double) -> CardTheme {
        var t = CardTheme()
        t.palette = palette
        t.ink = ink
        // เทมเพลตเลือกหมึกไว้เป็นส่วนหนึ่งของงานออกแบบ ไม่ใช่ค่าที่รอให้ระบบเดา —
        // ปล่อยให้อัตโนมัติทับเมื่อไหร่ แบบที่ตั้งใจทำเป็นกระดาษจะกลายเป็นเวทีมืดทั้งชุด
        t.inkAuto = false
        t.corner = corner
        t.backdrop = backdrop
        t.brightness = brightness
        return t
    }
}

// MARK: - สตอรี่ · ตระกูลสปอตไลต์ (3 ผัง)

extension CardTemplate {
    /// S1 · คู่คลิป — โปสเตอร์ชื่อตัวใหญ่ (ซ้าย) ประกบคลิปแนวตั้ง (ขวา) แล้วไล่เบนโตะตัวเลข/ราคา
    static let storyPosterDuo = CardTemplate(
        id: "story.spotlight.duo",
        format: .story,
        name: "สปอตไลต์ คู่คลิป",
        vibe: "POSTER",
        blurb: "โปสเตอร์ชื่อตัวใหญ่ประกบคลิปแนวตั้ง — เห็นหน้าและเห็นงานขยับตั้งแต่วินาทีแรก",
        theme: theme(.ruby, .night, .soft, .gradient, 0.2),
        builder: {
            [CardPage([
                WidgetInstance(.artTypeOver,  x: 18,  y: 18, w: 320, h: 472),
                WidgetInstance(.workReel,     x: 346, y: 18, w: 176, h: 472),
                WidgetInstance(.typeMarquee,  x: 18,  y: 498, w: 504, h: 44),
                WidgetInstance(.statGiant,    x: 18,  y: 550, w: 248, h: 140),
                WidgetInstance(.proofBrands,  x: 18,  y: 698, w: 248, h: 68),
                WidgetInstance(.socialTiles,  x: 274, y: 550, w: 248, h: 80),
                WidgetInstance(.rateTags,     x: 274, y: 638, w: 248, h: 80),
                WidgetInstance(.audienceLine, x: 274, y: 726, w: 248, h: 104),
                WidgetInstance(.contactBar,   x: 18,  y: 838, w: 504, h: 64),
            ])]
        }
    )

    /// S3 · จอเต็ม — ปกนิตยสารขาวดำกินครึ่งเฟรมแบบบิลบอร์ด
    ///
    /// hero เป็น "ปกนิตยสาร" ไม่ใช่ "ชื่อทับภาพ" — เดิมใช้ตัวเดียวกับใบคู่คลิป
    /// แล้วรูปย่อสองใบนี้อ่านเป็นฝาแฝดในกริดเลือกเทมเพลต (คำติจาก critique)
    static let storyPosterFull = CardTemplate(
        id: "story.spotlight.full",
        format: .story,
        name: "สปอตไลต์ จอเต็ม",
        vibe: "POSTER",
        blurb: "บิลบอร์ดของตัวเอง — ปกนิตยสารขาวดำกินครึ่งเฟรม แล้วค่อยตามด้วยตัวเลขกับราคา",
        theme: theme(.noir, .night, .soft, .solid, 0.16),
        builder: {
            [CardPage([
                WidgetInstance(.artPortrait, x: 18,  y: 18, w: 504, h: 600),
                WidgetInstance(.typeMarquee, x: 18,  y: 626, w: 504, h: 44),
                WidgetInstance(.statGiant,   x: 18,  y: 678, w: 248, h: 140),
                WidgetInstance(.rateTags,    x: 274, y: 678, w: 248, h: 80),
                WidgetInstance(.socialTiles, x: 274, y: 766, w: 248, h: 80),
                WidgetInstance(.contactBar,  x: 18,  y: 854, w: 504, h: 64),
            ])]
        }
    )

    /// S5 · ดูโอคลิป — เฟรมวิดีโอแนวตั้งคู่เป็นพระเอก งานขยับมาก่อนทุกอย่าง
    static let storyPosterReels = CardTemplate(
        id: "story.spotlight.reels",
        format: .story,
        name: "สปอตไลต์ ดูโอคลิป",
        vibe: "POSTER",
        blurb: "คลิปแนวตั้งคู่เต็มตา — สายวิดีโอให้งานขยับนำ แล้วปิดด้วยตัวเลขยักษ์กับเรตราคา",
        theme: theme(.ocean, .night, .soft, .glow, 0.3),
        builder: {
            [CardPage([
                WidgetInstance(.heroMinimal, x: 18,  y: 18, w: 504, h: 110),
                WidgetInstance(.workReel,    x: 18,  y: 136, w: 248, h: 400),
                // ฝั่งขวาเป็นคู่แนวตั้งในชิ้นเดียว (ใช้รูปคนละใบในตัวเอง) —
                // ถ้าใช้เฟรมสตอรี่จะได้รูปตั้งต้นใบเดียวกับคลิปซ้าย ซ้ำกันทั้งแถว
                WidgetInstance(.artPair,     x: 274, y: 136, w: 248, h: 400),
                WidgetInstance(.statGiant,    x: 18,  y: 544, w: 504, h: 206),
                WidgetInstance(.rateTags,     x: 18,  y: 758, w: 248, h: 80),
                WidgetInstance(.proofBrands,  x: 274, y: 758, w: 248, h: 68),
                WidgetInstance(.contactBar,   x: 18,  y: 846, w: 504, h: 64),
            ])]
        }
    )
}

// MARK: - สตอรี่ · ตระกูลโฟโต้การ์ด (3 ผัง)

extension CardTemplate {
    /// S2 · คอลลาจ — แผงสะสมสองคอลัมน์: ออร่า/โฮโล/ยอด ฝั่งกว้าง · เฟรม/โพลารอยด์/คิวอาร์ ฝั่งแคบ
    static let storyCardCollage = CardTemplate(
        id: "story.photocard.collage",
        format: .story,
        name: "โฟโต้การ์ด คอลลาจ",
        vibe: "PHOTOCARD",
        blurb: "แผงสะสมสองคอลัมน์ — ออร่า โฮโลผลงาน โพลารอยด์ ไปจนถึงคิวอาร์ให้สแกนคุยต่อ",
        theme: theme(.lavender, .night, .pill, .glow, 0.42),
        builder: {
            [CardPage([
                WidgetInstance(.heroAura,     x: 18,  y: 18, w: 296, h: 300),
                WidgetInstance(.galleryStory, x: 322, y: 18, w: 200, h: 320),
                WidgetInstance(.proofHolo,    x: 18,  y: 326, w: 296, h: 196),
                WidgetInstance(.artPolaroid,  x: 322, y: 346, w: 200, h: 224),
                WidgetInstance(.socialTiles,  x: 18,  y: 530, w: 296, h: 96),
                WidgetInstance(.contactQR,    x: 322, y: 578, w: 200, h: 224),
                WidgetInstance(.stickerTags,  x: 18,  y: 634, w: 296, h: 110),
                WidgetInstance(.rateTags,     x: 18,  y: 752, w: 296, h: 95),
                WidgetInstance(.typeMarquee,  x: 18,  y: 855, w: 504, h: 44),
            ])]
        }
    )

    /// S4 · สมุดสะสม — หน้าสมุดบนกระดาษ: การ์ดใบใหญ่สองใบเปิดหน้า แผงโฮโลเต็มแถว คิวอาร์ประจำแผง
    static let storyCardBinder = CardTemplate(
        id: "story.photocard.binder",
        format: .story,
        name: "โฟโต้การ์ด สมุดสะสม",
        vibe: "PHOTOCARD",
        blurb: "หน้าสมุดสะสมบนกระดาษชมพู — การ์ดใบใหญ่สองใบ แผงโฮโลเต็มแถว และคิวอาร์ประจำแผง",
        theme: theme(.rose, .mist, .pill, .gradient, 0.55),
        builder: {
            [CardPage([
                WidgetInstance(.artPolaroid,  x: 18,  y: 18, w: 248, h: 300),
                WidgetInstance(.galleryStory, x: 274, y: 18, w: 248, h: 300),
                WidgetInstance(.proofHolo,    x: 18,  y: 326, w: 504, h: 242),
                WidgetInstance(.socialTiles,  x: 18,  y: 576, w: 248, h: 80),
                WidgetInstance(.stickerTags,  x: 18,  y: 664, w: 248, h: 92),
                WidgetInstance(.contactQR,    x: 274, y: 576, w: 248, h: 224),
                WidgetInstance(.rateTags,     x: 18,  y: 764, w: 248, h: 80),
                WidgetInstance(.typeMarquee,  x: 18,  y: 852, w: 504, h: 44),
            ])]
        }
    )

    /// S6 · ออร่า — ออร่าเต็มดวงกลางเฟรม + สตริปตู้ถ่ายรูป — ดรีมมี่สุดในตระกูล
    static let storyCardAura = CardTemplate(
        id: "story.photocard.aura",
        format: .story,
        name: "โฟโต้การ์ด ออร่า",
        vibe: "PHOTOCARD",
        blurb: "ออร่าเต็มดวงกลางเฟรมแบบไอดอล ต่อด้วยสตริปตู้ถ่ายรูป — เบา ฟุ้ง ดรีมมี่สุดในตระกูล",
        theme: theme(.sky, .night, .pill, .glow, 0.36),
        builder: {
            [CardPage([
                WidgetInstance(.heroAura,      x: 18,  y: 18, w: 504, h: 420),
                WidgetInstance(.artPhotobooth, x: 18,  y: 446, w: 504, h: 200),
                WidgetInstance(.socialTiles,   x: 18,  y: 654, w: 248, h: 80),
                WidgetInstance(.rateTags,      x: 274, y: 654, w: 248, h: 80),
                WidgetInstance(.stickerTags,   x: 18,  y: 742, w: 504, h: 120),
                WidgetInstance(.contactBar,    x: 18,  y: 870, w: 504, h: 64),
            ])]
        }
    )
}

// MARK: - พอร์ตโฟลิโอ · ตระกูลสปอตไลต์ (3 ผัง)

extension CardTemplate {
    /// P1 · โปสเตอร์ — ชื่อทับภาพ+สตริปฟิล์ม → ผลงานชิ้นเด่น+ตัวเลข → ผลงานยืนยัน+ดีล
    static let portPoster = CardTemplate(
        id: "portfolio.spotlight.poster",
        format: .portfolio,
        name: "สปอตไลต์ โปสเตอร์",
        vibe: "POSTER",
        blurb: "เปิดด้วยโปสเตอร์ชื่อทับภาพและสตริปฟิล์ม แล้วไล่ผลงานชิ้นเด่น ตัวเลขยักษ์ จนถึงราคาและติดต่อ",
        theme: theme(.ruby, .night, .soft, .gradient, 0.2),
        builder: {
            [
                CardPage([
                    WidgetInstance(.artTypeOver,  y: 18, w: 366, h: 430),
                    WidgetInstance(.typeMarquee,  y: 456, w: 366, h: 46),
                    WidgetInstance(.artFilmstrip, y: 510, w: 366, h: 99),
                ]),
                CardPage([
                    WidgetInstance(.workFeatured, y: 18, w: 366, h: 260),
                    WidgetInstance(.statGiant,    y: 286, w: 366, h: 206),
                    WidgetInstance(.socialTiles,  y: 500, w: 366, h: 117),
                ]),
                CardPage([
                    WidgetInstance(.proofWork,    y: 18, w: 366, h: 295),
                    WidgetInstance(.rateTags,     y: 321, w: 366, h: 117),
                    WidgetInstance(.audienceLine, y: 446, w: 366, h: 130),
                    WidgetInstance(.contactBar,   y: 584, w: 366, h: 64),
                ]),
            ]
        }
    )

    /// P3 · ปกใหญ่ — ปกนิตยสารเต็มหน้า → โมเสกรูปเต็มแผ่น → ปกซีรีส์+ป้ายไฟราคา
    static let portPosterCover = CardTemplate(
        id: "portfolio.spotlight.cover",
        format: .portfolio,
        name: "สปอตไลต์ ปกใหญ่",
        vibe: "POSTER",
        blurb: "ปกนิตยสารเต็มหน้าแรก ตามด้วยโมเสกรูปเต็มแผ่น ปิดด้วยปกซีรีส์ผลงานและป้ายไฟราคา",
        theme: theme(.champagne, .night, .soft, .gradient, 0.22),
        builder: {
            [
                CardPage([
                    WidgetInstance(.artPortrait, y: 18, w: 366, h: 460),
                    WidgetInstance(.typeMarquee, y: 486, w: 366, h: 46),
                    WidgetInstance(.nicheTags,   y: 540, w: 366, h: 81),
                ]),
                CardPage([
                    WidgetInstance(.galleryMosaic, y: 18, w: 366, h: 313),
                    WidgetInstance(.statGiant,     y: 339, w: 366, h: 180),
                    WidgetInstance(.socialTiles,   y: 527, w: 366, h: 117),
                ]),
                CardPage([
                    WidgetInstance(.proofShelf,   y: 18, w: 366, h: 260),
                    WidgetInstance(.rateNeon,     y: 286, w: 366, h: 224),
                    WidgetInstance(.contactChips, y: 518, w: 366, h: 117),
                ]),
            ]
        }
    )

    /// P5 · ดูโอคลิป — เฟรมวิดีโอแนวตั้งคู่ทั้งหน้าแรก งานขยับนำก่อนใคร
    static let portPosterReels = CardTemplate(
        id: "portfolio.spotlight.reels",
        format: .portfolio,
        name: "สปอตไลต์ ดูโอคลิป",
        vibe: "POSTER",
        blurb: "คลิปแนวตั้งคู่ทั้งหน้าแรก — สายวิดีโอโชว์งานขยับก่อนใคร แล้วค่อยตัวเลขกับตั๋วผลงาน",
        theme: theme(.ocean, .night, .soft, .glow, 0.3),
        builder: {
            [
                CardPage([
                    WidgetInstance(.heroMinimal, y: 18, w: 366, h: 130),
                    // คู่แนวตั้งชิ้นเดียว — รูปคนละใบในตัวเอง ไม่ซ้ำกันเหมือนวางเฟรมสองชิ้น
                    WidgetInstance(.artPair,     y: 156, w: 366, h: 360),
                    WidgetInstance(.nicheTags,   y: 524, w: 366, h: 81),
                ]),
                CardPage([
                    WidgetInstance(.galleryCarousel, y: 18, w: 366, h: 224),
                    WidgetInstance(.statGiant,       y: 250, w: 366, h: 206),
                    WidgetInstance(.socialTiles,     y: 464, w: 366, h: 117),
                    WidgetInstance(.typeMarquee,     y: 589, w: 366, h: 46),
                ]),
                CardPage([
                    WidgetInstance(.proofTicket,  y: 18, w: 366, h: 260),
                    WidgetInstance(.rateTags,     y: 286, w: 366, h: 117),
                    WidgetInstance(.audienceLine, y: 411, w: 366, h: 130),
                    WidgetInstance(.contactBar,   y: 549, w: 366, h: 64),
                ]),
            ]
        }
    )
}

// MARK: - พอร์ตโฟลิโอ · ตระกูลโฟโต้การ์ด (3 ผัง)

extension CardTemplate {
    /// P2 · คอลลาจ — ออร่า+เฟรมคู่ → โฮโล+ตู้ถ่ายรูป → กองรูป+คิวอาร์กลางหน้า
    static let portCardCollage = CardTemplate(
        id: "portfolio.photocard.collage",
        format: .portfolio,
        name: "โฟโต้การ์ด คอลลาจ",
        vibe: "PHOTOCARD",
        blurb: "ออร่าพร้อมโพลารอยด์คู่เฟรมสตอรี่ → การ์ดโฮโลกับตู้ถ่ายรูป → กองรูปและคิวอาร์กลางหน้า",
        theme: theme(.lavender, .night, .pill, .glow, 0.42),
        builder: {
            [
                CardPage([
                    WidgetInstance(.heroAura,     y: 18, w: 366, h: 384),
                    WidgetInstance(.artPolaroid,  x: 18, y: 410, w: 179, h: 206),
                    WidgetInstance(.galleryStory, x: 205, y: 410, w: 179, h: 206),
                ]),
                CardPage([
                    WidgetInstance(.proofHolo,     y: 18, w: 366, h: 260),
                    WidgetInstance(.artPhotobooth, y: 286, w: 366, h: 200),
                    WidgetInstance(.socialTiles,   y: 494, w: 366, h: 117),
                ]),
                CardPage([
                    WidgetInstance(.galleryStack, y: 18, w: 366, h: 242),
                    WidgetInstance(.rateTags,     y: 268, w: 366, h: 117),
                    WidgetInstance(.contactQR,    x: 112, y: 393, w: 179, h: 224),
                ]),
            ]
        }
    )

    /// P4 · สมุดภาพ — สแครปบุ๊กกระดาษ: โพลารอยด์เหลื่อมเฟรม โน้ตแปะ เทปกาว ตราประทับ
    static let portCardScrapbook = CardTemplate(
        id: "portfolio.photocard.scrapbook",
        format: .portfolio,
        name: "โฟโต้การ์ด สมุดภาพ",
        vibe: "PHOTOCARD",
        blurb: "สมุดภาพกระดาษโทนอุ่น — โพลารอยด์เหลื่อมเฟรมสตอรี่ โน้ตลายมือ เทปกาว และตราประทับราคา",
        theme: theme(.rose, .mist, .pill, .gradient, 0.52),
        builder: {
            [
                CardPage([
                    WidgetInstance(.galleryStory, x: 205, y: 18, w: 179, h: 295),
                    WidgetInstance(.artPolaroid,  x: 18,  y: 76, w: 179, h: 206),
                    WidgetInstance(.aboutNote,    y: 321, w: 366, h: 153),
                    WidgetInstance(.stickerTags,  y: 482, w: 366, h: 135),
                ]),
                CardPage([
                    WidgetInstance(.galleryTape, y: 18, w: 366, h: 224),
                    WidgetInstance(.proofHolo,   y: 250, w: 366, h: 242),
                    WidgetInstance(.socialTiles, y: 500, w: 366, h: 117),
                ]),
                CardPage([
                    WidgetInstance(.rateStamp,     y: 18, w: 366, h: 260),
                    WidgetInstance(.artPhotobooth, y: 286, w: 366, h: 206),
                    WidgetInstance(.contactLine,   y: 500, w: 366, h: 117),
                ]),
            ]
        }
    )

    /// P6 · ออร่า — ออร่าเต็มหน้าแรกแบบไอดอล → บอร์ดพิน+คำพูด → โฮโล+คิวอาร์
    static let portCardAura = CardTemplate(
        id: "portfolio.photocard.aura",
        format: .portfolio,
        name: "โฟโต้การ์ด ออร่า",
        vibe: "PHOTOCARD",
        blurb: "ออร่าเต็มหน้าแรกแบบไอดอล ตามด้วยบอร์ดพินกับคำพูดประจำตัว ปิดด้วยโฮโลผลงานและคิวอาร์",
        theme: theme(.sky, .night, .pill, .glow, 0.36),
        builder: {
            [
                CardPage([
                    WidgetInstance(.heroAura,    y: 18, w: 366, h: 420),
                    WidgetInstance(.socialTiles, y: 446, w: 366, h: 117),
                    WidgetInstance(.typeMarquee, y: 571, w: 366, h: 46),
                ]),
                CardPage([
                    WidgetInstance(.galleryMasonry, y: 18, w: 366, h: 260),
                    WidgetInstance(.typeQuote,      y: 286, w: 366, h: 180),
                    WidgetInstance(.audienceSplit,  y: 474, w: 366, h: 135),
                ]),
                CardPage([
                    WidgetInstance(.proofHolo, y: 18, w: 366, h: 242),
                    WidgetInstance(.rateTags,  y: 268, w: 366, h: 117),
                    WidgetInstance(.contactQR, x: 112, y: 393, w: 179, h: 224),
                ]),
            ]
        }
    )
}
