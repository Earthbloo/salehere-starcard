import SwiftUI

// MARK: - Tier

/// ชั้นของ widget — กำหนดว่าผู้ใช้แต่งได้แค่ไหน
/// กฎหลักของโปรดักต์: ชั้น `verified` แต่งหน้าตาไม่ได้ เพราะมันคือหลักฐาน ไม่ใช่งานศิลปะ
enum WidgetTier {
    case verified   // แพลตฟอร์มออกให้ · ลากย้ายได้ · ขนาด/หน้าตาล็อก
    case connected  // มาจาก OAuth · เลือก variant + ขนาดได้ · ตัวเลขแก้ไม่ได้
    case personal   // ตัวตน · อิสระเต็มที่

    var label: String {
        switch self {
        case .verified:  return "หลักฐาน"
        case .connected: return "เชื่อมต่อ"
        case .personal:  return "ตัวตน"
        }
    }
    var icon: String {
        switch self {
        case .verified:  return "checkmark.seal.fill"
        case .connected: return "link"
        case .personal:  return "paintbrush.fill"
        }
    }
}

/// หมวดใน gallery — แบ่งตาม "คำถามที่แบรนด์ถาม" เหลือสามคำถามใหญ่
/// ฉันเป็นใคร · จ้างฉันยังไง · ฉันทำอะไรมาแล้ว
enum WidgetGroup: String, CaseIterable, Identifiable {
    case about, booking, work
    var id: String { rawValue }

    var label: String {
        switch self {
        case .about:   return "เกี่ยวกับฉัน"
        case .booking: return "รับงาน"
        case .work:    return "ผลงาน"
        }
    }
    var icon: String {
        switch self {
        case .about:   return "person.crop.square"
        case .booking: return "briefcase.fill"
        case .work:    return "photo.on.rectangle.angled"
        }
    }
}

/// ตระกูลของ widget — กลุ่มที่ "สลับหน้าตากันได้" เพราะเล่าเรื่องเดียวกัน
///
/// # กติกาข้อบังคับของทุกตระกูล: **ทุกแบบต้องแสดงฟิลด์ชุดเดียวกัน**
///
/// ถ้าแบบหนึ่งโชว์สองบรรทัดแต่อีกแบบโชว์บรรทัดเดียว การกด "แบบอื่น" จะกลายเป็นการ
/// *เพิ่ม/ลดข้อมูล* แทนที่จะเป็นการ *เปลี่ยนหน้าตา* — ผู้ใช้เลือกสไตล์แล้วเสียข้อมูลไปโดยไม่รู้ตัว
/// และการ์ดสองใบที่ใช้แบบต่างกันจะเทียบกันไม่ได้ ซึ่งเป็นสิ่งที่แบรนด์ต้องทำเป็นอันดับแรก
///
/// สัญญาของแต่ละตระกูล (ฟิลด์ที่ **ทุกแบบ** ต้องมี):
/// - `hero` — ชื่อ · ตรายืนยัน · สายงาน
/// - `verified` — รูป · แบรนด์ · แพลตฟอร์ม · ยอดวิว · ยอดบันทึก/แชร์
/// - `followers` — ยอดรายช่อง · ชื่อช่อง
/// - `audience` — เพศ · ช่วงอายุ · ประเทศ · บรรทัดที่มา (ช่อง/ช่วงเวลา/คนดู) ครบทุกชุดในทุกแบบ
/// - `contact` — เบอร์ · อีเมล · ไลน์
///
/// แยกจาก `WidgetGroup` เพราะหมวดใน gallery หยาบแค่สามหมวด
/// ถ้าใช้หมวดมาหาแบบอื่น มันจะเสนอสลับ "ฟิล์มสตริป → โลโก้แบรนด์" ซึ่งคนละเรื่องกัน
enum WidgetFamily: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    // ลำดับนี้คือลำดับที่โผล่ในตู้ — ของหลักมาก่อน ถ้อยคำปิดท้ายทั้งสองหมวด
    //
    // `text` อยู่ต่อจาก `intro` ไม่ใช่ท้ายสุด: มันคือใบที่คนมองหาเวลาอยากเขียนอะไรเอง
    // ซึ่งเป็นความตั้งใจที่เกิดตั้งแต่ต้นการจัดหน้า ไม่ใช่ของปิดท้าย · แล้วใบมันเป็น
    // ตัวหนังสือเปล่าบนพื้นมืด ถ้าไปนั่งท้ายตู้ต่อจากรูปสี่สิบใบก็แทบไม่มีใครเลื่อนไปเจอ
    // `seal` ต่อจาก `hero` ทันที — "ฉันเป็นใคร" กับ "ใครรับรองฉัน" คือสองคำถามแรกของแบรนด์
    // และเป็นใบที่ CEO อยากให้คนเจอเร็วที่สุดในตู้
    case hero, seal, intro, text, followers, audience, tags, brand, verified,
         photo, showcase, rate, contact

    var label: String {
        switch self {
        case .hero:      return "โปรไฟล์"
        case .intro:     return "แนะนำตัว"
        case .brand:     return "แบรนด์"
        case .verified:  return "ผลงานยืนยัน"
        case .seal:      return "ตรารับรอง"
        case .followers: return "ผู้ติดตาม"
        case .photo:     return "รูปผลงาน"
        case .showcase:  return "แผ่นโชว์ผลงาน"
        case .text:      return "ข้อความ"
        case .tags:      return "หมวดหมู่"
        case .audience:  return "ผู้ชม"
        case .rate:      return "เรตราคา"
        case .contact:   return "ติดต่อ"
        }
    }

    /// หัวข้อใน Star Profile ที่ตระกูลนี้ดึงข้อมูลมาโชว์ — nil = ไม่ผูก (ของตกแต่ง / ผลงานจาก Portfolio / ข้อมูลบัญชี)
    ///
    /// ผูกแล้วได้สองอย่าง: ยังไม่กรอกหัวข้อนั้น = ช่องในตู้พาไปกรอกข้อนั้นข้อเดียว ·
    /// กรอกครบ = ทุกแบบในตระกูลใช้ได้ทันที (ผู้ใช้ 23 ก.ย. 2569)
    var topic: StarTopic? {
        switch self {
        case .hero, .tags: return .data(.categories)
        case .followers:   return .data(.socials)
        case .intro: return .data(.about)
        case .rate:        return .data(.rate)
        case .audience:    return .data(.insight)
        case .seal:        return .verify
        // แบรนด์ + ผลงานยืนยัน = หลักฐานจากระบบ ปลดล็อกเมื่อทำงานผ่าน Sale Here จบแล้วอย่างน้อย 1 งาน (ผู้ใช้ 23 ก.ย. 2569)
        case .brand, .verified: return .work
        case .text, .photo, .showcase, .contact: return nil
        }
    }
}

/// หมวดในตู้ widget = หัวข้อของ Star Profile (ผู้ใช้ 23 ก.ย. 2569: "cat ต้องตรงกับ Star Profile แล้ว scroll เอาแทน")
///
/// ชิปเลื่อนแนวนอนแทนแท็บสามแท็บ · ลำดับ = ลำดับที่การ์ดเล่าเรื่อง (ฉันเป็นใคร → ช่อง → สาย → แนะนำตัว → เรท → ผู้ติดตาม → ตรา)
/// สามหมวดท้ายไม่ผูกกับ Star Profile: ผลงาน (จาก Portfolio) · ติดต่อ (จากบัญชี) · ข้อความ (ของตกแต่ง)
enum TrayGroup: String, CaseIterable, Identifiable {
    case profile, channels, niche, intro, rate, audience, verify, work, contact, decor
    var id: String { rawValue }

    var label: String {
        switch self {
        case .profile: return "โปรไฟล์"
        case .channels: return "ช่องทาง"
        case .niche: return "สายที่ใช่"
        case .intro: return "แนะนำตัว"
        case .rate: return "เรทรับงาน"
        case .audience: return "ข้อมูลผู้ติดตาม"
        case .verify: return "ยืนยันตัวตน"
        case .work: return "ผลงาน"
        case .contact: return "ติดต่อ"
        case .decor: return "ข้อความ"
        }
    }

    var topic: StarTopic? {
        switch self {
        case .profile, .niche: return .data(.categories)
        case .channels: return .data(.socials)
        case .intro: return .data(.about)
        case .rate: return .data(.rate)
        case .audience: return .data(.insight)
        case .verify: return .verify
        case .work, .contact, .decor: return nil
        }
    }
}

extension WidgetFamily {
    var trayGroup: TrayGroup {
        switch self {
        case .hero: return .profile
        case .followers: return .channels
        case .tags: return .niche
        case .intro: return .intro
        case .rate: return .rate
        case .audience: return .audience
        case .seal: return .verify
        case .photo, .showcase, .brand, .verified: return .work
        case .contact: return .contact
        case .text: return .decor
        }
    }
}

/// หัวข้อ Star Profile ที่ widget ผูกอยู่ — ช่องข้อมูล หรือ ยืนยันตัวตน
enum StarTopic: Hashable {
    case data(StarDataKey)
    case verify
    /// เคยทำงานผ่าน Sale Here จบแล้ว — กรอกเองไม่ได้ ต้องไปรับงาน
    case work

    var label: String {
        switch self {
        case .data(let k): return k.label
        case .verify: return "ยืนยันตัวตน"
        case .work: return "ผลงานกับ Sale Here"
        }
    }
    /// คำบนปุ่มของใบที่ยังว่าง
    var action: String {
        switch self {
        case .data(let k): return fillable ? "กรอก\(k.label)" : "กรอกข้อมูลเพื่อปลดล็อก"
        case .verify: return fillable ? "ยืนยันตัวตน" : "ยืนยันตัวตนเพื่อปลดล็อก"
        case .work: return "ทำงานกับ Sale Here ก่อน"
        }
    }
    /// คำบอกที่หัวหมวด
    var missingLine: String {
        switch self {
        case .data(let k): return "ยังไม่มี\(k.label)"
        case .verify: return "ยังไม่ได้ยืนยันตัวตน"
        case .work: return "ปลดล็อกเมื่อทำงานผ่าน Sale Here จบ 1 งาน"
        }
    }
    /// ปลดล็อกด้วยการกรอกได้ไหม (ผลงานกับ Sale Here ต้องไปรับงาน ไม่มี wizard)
    /// ล็อก = ยังไม่มีข้อมูล · แตะแล้วกรอกได้เลย (ผู้ใช้ 29 ก.ย. 2569: "กดแล้วให้เค้ากรอกข้อมูลได้")
    /// ผลงานกับ Sale Here กรอกเองไม่ได้ ต้องไปรับงาน
    var fillable: Bool { self != .work }
    /// ขั้นของ wizard ที่ต้องเปิดเพื่อกรอกหัวข้อนี้
    var step: WizStep {
        switch self {
        case .data(let k): return WizStep(rawValue: k.rawValue) ?? .about
        case .verify: return .kyc
        case .work: return .about
        }
    }
    /// กรอกหัวข้อนี้แล้วหรือยัง (ดูจาก state ของ flow ใหม่ — ตัวเดียวกับ Star Profile)
    var filled: Bool {
        switch self {
        case .data(let k): return StarFlow.shared.has(k)
        case .verify: return StarFlow.shared.verify != .none
        case .work: return StarFlow.shared.reviewed
        }
    }
}

// MARK: - วัสดุของสำรับสติกเกอร์

/// กระดาษเทป หรือ กระจกชมพู — เดิมคำนวณจากมุมของธีม ตอนนี้เป็นส่วนหนึ่งของชนิด
/// (ดู `WidgetKind.popSkin` · หน้าตาของแต่ละวัสดุอยู่ใน `PopWidgets.swift`)
enum PopSkin: String, CaseIterable, Sendable {
    case paper, glass

    var label: String {
        switch self {
        case .paper: return "กระดาษเทป"
        case .glass: return "กระจกชมพู"
        }
    }
}

// MARK: - Kind

enum WidgetKind: String, CaseIterable, Identifiable {
    // โปรไฟล์
    //
    // ปกนิตยสาร (`artPortrait`) · ชื่ออยู่หลังคน (`artNameBehind`) · ทะลุกรอบ (`artBreakout`) ·
    // โพลารอยด์ (`artPolaroid`) · ออร่า (`heroAura`) ถูกถอดออก 29 ก.ย. 2569 ตามที่เจ้าของโปรเจกต์สั่ง —
    // การ์ดเก่าที่มีห้าใบนี้ถูกแปลงเป็นพี่น้องที่ใกล้ที่สุดตอนเปิด (ดู `decode`) ไม่ใช่หายไปทั้งก้อน
    case artTypeOver, heroMinimal
    // โปรไฟล์ — โปสเตอร์พอร์ต (ดู `PosterWidgets.swift` · ชิ้นส่วนคัตเอาต์ร่วมอยู่ใน `CutoutWidgets.swift`)
    //
    // อ่าน **ช่องอัลฟา** ของรูป คนจึงยืนคร่อมคำได้ · และเป็น **แผ่นพิมพ์** ไม่ใช่เวทีมืด:
    // คำยักษ์ทับเต็มความกว้าง · คนขาวดำยืนคร่อมคำนั้น · แถบชื่อพาดใต้เท้า
    // และเป็นตัวเดียวในตระกูลที่ถอดกระดาษออกได้ (ดู `surfaceOptions`)
    case artPortfolio
    // โปรไฟล์ — หน้าต่างพอร์ต (ดู `WindowWidgets.swift`)
    //
    // โปสเตอร์พอร์ตที่ถูกเปิดอยู่ใน **หน้าต่าง Preview ของ macOS** — ชื่อมีเส้นสองข้าง คำเซริฟดำยักษ์
    // คนยืนคร่อมคำนั้นบนฉากเทาของสตูดิโอ · แปลงตรงจากแผ่นตัวอย่างที่เจ้าของการ์ดส่งมา
    case portfolioWindow
    // โปรไฟล์ — โปสเตอร์พอร์ตผ้าปิกนิก (ดู `GinghamWidgets.swift`)
    //
    // เรื่องเดียวกับหน้าต่างพอร์ต แต่งคนละชุด: กระดาษครีม ขอบหยักแดง คำเซริฟแคบสีเลือดหมู
    // และคนยืนบนผืนผ้าตารางฟ้า · แปลงตรงจากแผ่นตัวอย่างชุดที่สองของเจ้าของการ์ด
    case portfolioGingham
    // เกี่ยวกับฉัน
    case aboutText, interestTags
    // หลักฐาน — โลโก้แบรนด์
    case proofBrandGrid, proofBrandRail, proofBrandCoins
    // หลักฐาน — ผลงานยืนยัน สองหน้าตาของเรื่องเดียวกัน
    //
    // ทั้งชั้นนี้ **รูปคือตัวนำ** ไม่ใช่ตัวประกอบ เคยมีอีกสี่แบบที่เป็นตาราง/ใบเสร็จ/แถวรายการ
    // (กระดานคะแนน · ใบเสร็จ · เพลย์ลิสต์ · ป้ายโลหะ) แต่วัดแล้วรูปกินพื้นที่ 0–5%
    // มันคือเครื่องมืออ่านข้อมูล ไม่ใช่ผลงาน — ถอดออกทั้งหมด
    // เรียงจากรูปน้อยไปรูปมาก — ลำดับนี้คือลำดับที่โผล่ในตู้
    case proofWork, proofTicket
    // หลักฐาน — ตรารับรอง (ดู `VerifiedSealWidget.swift`)
    //
    // ใบที่ห้าของสำรับโปสเตอร์ และใบเดียวที่ **เนื้อหาคือคำรับรอง**: เหรียญฟอยล์แปดกลีบ
    // วงตัวอักษรหมุนรอบ ลายกิโยเช่ใต้แผ่น และสามข้อที่ Sale Here ตรวจแล้ว
    // เจ้าของหยิบมาวางเองเหมือนแขวนใบประกาศ — แตะในหน้าดูแล้วเปิดแผ่นตรวจสอบ
    case proofSeal
    // ผู้ติดตาม
    case statGiant, socialChips, socialTiles, statWrapped
    // ผู้ติดตาม — โปสเตอร์แถวสถิติ (ดู `StatPosterWidget.swift`)
    //
    // ใบที่สี่ของตระกูล และใบเดียวที่ **ไม่ใช่ป้ายข้อมูล** — ยอดรายช่องชุดเดิมถูกวางเป็น
    // แถวใต้พาดหัวยักษ์ สายตาจึงเทียบทุกช่องพร้อมกันได้ในวินาทีเดียว แทนที่จะไล่อ่านทีละกล่อง
    // และเป็นใบที่สี่ของสำรับโปสเตอร์ จึงถอดแผ่นออกได้เหมือนพี่ ๆ (ดู `surfaceOptions`)
    case statPoster
    // ผู้ติดตาม — หน้าต่างช่องทาง (ดู `WindowWidgets.swift`)
    //
    // ช่องเดียวแบบเต็มยศในหน้าต่าง macOS: โลโก้ · แฮนเดิล · ยอดเต็มหลัก · ER พร้อมสูตรที่ฐาน
    // ใบเดียวในตระกูลที่ **เลือกช่องได้รายชิ้น** (ถาด → "ช่องทาง") — วางสองใบ = สองช่อง
    case socialWindow
    // ผู้ติดตาม — ป้ายช่องทางผ้าปิกนิก (ดู `GinghamWidgets.swift`)
    //
    // ข้อมูลชุดเดียวกับหน้าต่างช่องทาง (เลือกช่องได้รายชิ้นเหมือนกัน) บนแถบฟ้า การ์ดครีมสามใบ
    // และฐานผ้าตาราง
    case socialGingham
    // ผลงาน
    case artFilmstrip, artDuo, artPair, workFeatured, workReel, artPhotobooth
    // ผลงาน — สำรับ "กองรูป" แปดสถานการณ์ (ดู `GalleryWidgets.swift`)
    // เรียงตามความหนาแน่นของรูป: กองน้อย → กองเยอะ → กรอบแพลตฟอร์ม → วัสดุ
    case galleryStack, galleryCarousel, galleryMasonry, galleryMosaic,
         galleryPost, galleryStory, galleryFilm, galleryTape
    // ผลงาน — แผ่นโชว์คลิป (ดู `ShowcaseWidgets.swift`)
    //
    // ตัวเดียวในตู้ที่เป็น **แผ่นพรีเซนต์ทั้งแผ่น** ไม่ใช่ป้ายข้อมูลหรือกองรูป:
    // หัวเรื่องใหญ่ + เครื่องสี่เครื่องเรียง + ชื่อลูกค้ากับสรุปงานใต้แต่ละเครื่อง
    // (สิ่งที่ครีเอเตอร์ส่งให้แบรนด์อยู่แล้วในสไลด์ — ตู้เพิ่งมีที่ให้มันวันนี้)
    case reelShowcase
    // เนื้อหา
    case typeMarquee, nicheTags, stickerTags
    // สายงาน — โปสเตอร์ที่เอาแท็กไปล้อมตัวคน (ดู `NichePosterWidget.swift`)
    //
    // ใบที่สี่ของตระกูลคัตเอาต์ แต่เป็นใบเดียวที่ **เนื้อหาคือแท็ก ไม่ใช่ชื่อ** —
    // อีกสามใบเล่าว่า "เขาคือใคร" ใบนี้เล่าว่า "เขาทำงานอะไร" จึงอยู่ตระกูล `tags`
    // ไม่ใช่ `hero` · และถอดแผ่นออกได้เหมือน `artPortfolio` (ดู `surfaceOptions`)
    case nichePoster
    // ข้อความล้วน — ตัวเดียวในตู้ที่ *ไม่มีเนื้อหาของตัวเอง* นอกจากที่เจ้าของการ์ดพิมพ์ลงไป
    case textBlock
    // เรตราคา — สเปกหมวด 5.1 ที่ตู้เดิมไม่มีเลย · หกหน้าตาของราคาชุดเดียวกัน
    // สองตัวแรกเป็น "เอกสาร" (เมนู · ป้ายห้อย) · สี่ตัวหลังเป็นสำรับศิลป์
    // ที่ทำให้การ์ดสายดีไซน์มีเรตที่เข้ากับหน้าตัวเอง (ดู `RateArtWidgets.swift`)
    case rateTags, rateNeon
    // ช่องทางติดต่อ — สเปก 1.3
    case contactCard, contactQR,
         // สี่แบบมินิมอล — บรรทัดเดียว · สามบรรทัด · ไลน์ตัวใหญ่ · ชิป
         contactBar, contactStack, contactLine, contactChips,
         // โปสเตอร์ติดต่อ — ใบเดียวในตระกูลที่ **เป็นภาพ** ไม่ใช่ป้ายข้อมูล
         // (ดู `ContactPosterWidget.swift`) · ใบที่ห้าของตระกูลคัตเอาต์ และใบแรกของมันที่อยู่หมวดรับงาน
         contactPoster
    // ประชากรผู้ติดตาม — สเปก 2.3
    case audienceLine, audienceSplit, audienceAge, audienceMap
    // ผู้ชม — โปสเตอร์อินไซต์ (ดู `InsightPosterWidget.swift`)
    //
    // ใบเดียวในตระกูลที่วาด **ทุกชุดพร้อมกัน** บนแผ่นเดียว: การเข้าถึง · เพศ · อายุ · เมือง
    // แผ่นข้อมูลขาวสี่แผ่นลอยอยู่ใต้พาดหัว — หน้าสไลด์ Insight ที่ครีเอเตอร์แคปส่งแบรนด์อยู่แล้ว
    case audiencePoster
    // สำรับ "แผ่นสติกเกอร์" — แปลงตรงจากเทมเพลต STAR CARD_1/_2 (ดู `PopWidgets.swift`)
    //
    // **แปดหน้าที่ × สองวัสดุ = สิบหกตัว** เรียงคู่กันเพื่อให้ตู้วางฝาแฝดติดกัน
    //
    // เดิมเป็นแปดตัวที่อ่านวัสดุจาก `CardTheme.corner` ซึ่งอ่านดีบนกระดาษแต่พังในตู้:
    // ตู้เรนเดอร์ทุกใบด้วยธีมของการ์ดที่เปิดอยู่ แปลว่าอีกวัสดุหนึ่ง **หยิบไม่ได้เลย**
    // นอกจากไปสลับธีมทั้งใบ วัสดุจึงย้ายมาเป็นของ *ชนิด* (ดู `popSkin`) ไม่ใช่ของธีม
    case popHeroPaper, popHeroGlass,
         popVideoPaper, popVideoGlass,
         popStatsGlass,
         popWorkPaper, popWorkGlass,
         popRatePaper, popRateGlass,
         popNichePaper, popNicheGlass,
         
         popContactPaper, popContactGlass

    // สำรับบรรณาธิการ — แปลงตรงจากแผ่นตัวอย่างแปดใบ (ดู `EditorialWidgets.swift`)
    //
    // ทั้งสำรับมี **ตัวอักษรเป็นผัง** ไม่ใช่ป้ายกำกับของข้อมูล — ข้อความของมันจึงเก็บต่อชิ้น
    // (`ProfileField.note` + `index`) โดยมีข้อความตั้งต้นของดีไซน์เดินทางมากับช่อง
    // เรียงจาก "กองรูป" → "หน้าแนะนำตัว" → "ประโยคเดี่ยว" → "การ์ดขั้นตอน"
    case wallPolaroid, wallMemory, zineCover,
         aboutEditorial, aboutBehind,
         flowCards

    // สำรับสมุดสแครปบุ๊ก — แปลงจากเทมเพลต media kit สีชมพู (ดู `ScrapbookWidgets.swift`)
    //
    // สิบสี่ใบ หนึ่งภาษาภาพ (กระดาษชมพู คลิปหนีบ เทปวาชิ โพลารอยด์ ใบเสร็จ) กระจายไปทุกหมวดของตู้
    // เนื้อหาเป็นข้อมูลตามหมวดของเราเอง — ไม่มีรูปผูกกับสายงาน ไม่มีปุ่มหรือเคอร์เซอร์ที่กดไม่ได้ในรูปที่ export
    case scrapFolder, scrapBadge, scrapKeyTab, scrapFeed, scrapTags, scrapAbout, scrapInfo,
         scrapReceipt, scrapStats, scrapStamp, scrapPhones, scrapChat, scrapNote, scrapLabel

    var id: String { rawValue }

    /// อ่านชนิดจากไฟล์ — ใจดีกับการ์ดที่บันทึกไว้ก่อนสำรับสติกเกอร์จะแยกวัสดุ
    ///
    /// ไฟล์เก่าเขียนแค่ `popHero` เพราะตอนนั้นวัสดุมาจากมุมของธีม — ตอนกู้จึงเดาจากธีมของไฟล์นั้น
    /// ด้วยกติกาเดิมเป๊ะ (`corner == .soft` = กระดาษ) การ์ดเก่าเปิดมาแล้วหน้าตาไม่ขยับสักใบ
    static func decode(_ raw: String, legacyPopSkin: PopSkin = .glass) -> WidgetKind? {
        if let k = WidgetKind(rawValue: raw) { return k }
        if let k = retired[raw] { return k }
        let suffix = legacyPopSkin == .paper ? "Paper" : "Glass"
        return WidgetKind(rawValue: raw + suffix)
    }

    /// ชนิดที่ถอดออกจากตู้แล้ว → พี่น้องในตระกูลเดียวกันที่ใกล้ที่สุด
    ///
    /// ถ้าปล่อยให้อ่านไม่ออก ชิ้นนั้นหายไปจากการ์ดเงียบ ๆ ทิ้งรูโหว่ไว้กลางหน้า — แปลงแทน
    /// แล้วเจ้าของการ์ดเลือกแบบใหม่เองได้จากแถว "แบบอื่น" (ชื่อ · รูปช่อง 1 · สายงาน ยังอยู่ครบ)
    private static let retired: [String: WidgetKind] = [
        "artPortrait": .artTypeOver,      // ปกนิตยสาร → ตัวอักษรทับภาพ (รูปเต็มกรอบ + ชื่อบนรูป)
        "artNameBehind": .artPortfolio,   // ชื่ออยู่หลังคน → โปสเตอร์พอร์ต (คนยืนคร่อมคำ)
        "artBreakout": .artPortfolio,     // ทะลุกรอบ → โปสเตอร์พอร์ต
        "artPolaroid": .artTypeOver,      // โพลารอยด์ → ตัวอักษรทับภาพ
        "heroAura": .artTypeOver,         // ออร่า → ตัวอักษรทับภาพ
        // 30 ก.ย. 2569 — ถ้อยคำ · สัดส่วน ถูกถอดทั้งตระกูล (ข้อมูลไม่มีใน Star Profile) **ไม่แปลง** — หายจากการ์ด
    ]

    /// หน้าที่ของกล่องในสำรับสติกเกอร์ — "กล่องนี้เล่าเรื่องอะไร" (วัสดุอยู่ที่ `popSkin`)
    ///
    /// ชื่อ ไอคอน และขนาด เป็นของหน้าที่ ไม่ใช่ของวัสดุ — ฝาแฝดสองใบจึงต่างกันแค่คำต่อท้ายชื่อ
    enum PopRole {
        case hero, video, stats, work, rate, niche, body, contact

        var title: String {
            switch self {
            case .hero:    return "ป้ายชื่อ"
            case .video:   return "หน้าต่างวิดีโอ"
            case .stats:   return "ผู้ติดตามสามช่อง"
            case .work:    return "ผลงานสามใบ"
            case .rate:    return "ใบเรตราคา"
            case .niche:   return "สายงานแบบลิสต์"
            case .body:    return "สัดส่วน"
            case .contact: return "ช่องทางติดต่อสามแถว"
            }
        }

        var symbol: String {
            switch self {
            case .hero:    return "person.crop.square.fill"
            case .video:   return "play.rectangle.fill"
            case .stats:   return "flag.fill"
            case .work:    return "rosette"
            case .rate:    return "tag.fill"
            case .niche:   return "list.bullet.clipboard.fill"
            case .body:    return "figure.stand"
            case .contact: return "person.fill"
            }
        }

        /// ผังในเทมเพลต `storyPop*` (แปลงจาก 810×1080 → กว้าง 504)
        var defaultSize: CGSize {
            switch self {
            case .hero:    return CGSize(width: 277, height: 250)
            case .video:   return CGSize(width: 215, height: 202)
            case .stats:   return CGSize(width: 504, height: 172)
            case .work:    return CGSize(width: 350, height: 172)
            case .rate:    return CGSize(width: 142, height: 182)
            case .niche:   return CGSize(width: 160, height: 214)
            case .body, .contact: return CGSize(width: 160, height: 214)
            }
        }
    }

    /// หน้าที่ + วัสดุ ในสวิตช์เดียว — ที่เหลือทั้งไฟล์อ่านต่อจากตรงนี้
    /// จึงไม่มี switch ไหนต้องไล่สิบหกตัวอีก
    private var popParts: (role: PopRole, skin: PopSkin)? {
        switch self {
        case .popHeroPaper:    return (.hero, .paper)
        case .popHeroGlass:    return (.hero, .glass)
        case .popVideoPaper:   return (.video, .paper)
        case .popVideoGlass:   return (.video, .glass)
        case .popStatsGlass:   return (.stats, .glass)
        case .popWorkPaper:    return (.work, .paper)
        case .popWorkGlass:    return (.work, .glass)
        case .popRatePaper:    return (.rate, .paper)
        case .popRateGlass:    return (.rate, .glass)
        case .popNichePaper:   return (.niche, .paper)
        case .popNicheGlass:   return (.niche, .glass)
        case .popContactPaper: return (.contact, .paper)
        case .popContactGlass: return (.contact, .glass)
        default:               return nil
        }
    }

    var popRole: PopRole? { popParts?.role }
    /// วัสดุของแผ่น — `nil` แปลว่าไม่ใช่สำรับสติกเกอร์
    var popSkin: PopSkin? { popParts?.skin }

    /// สำรับแผ่นสติกเกอร์ — เช็คทีเดียวแทนไล่ทั้งสำรับทุก switch
    var isPop: Bool { popParts != nil }

    /// ฝาแฝดอีกวัสดุหนึ่งของกล่องเดียวกัน — ใช้ตอนสลับวัสดุทั้งการ์ด
    var popTwin: WidgetKind? {
        guard let p = popParts else { return nil }
        let other: PopSkin = p.skin == .paper ? .glass : .paper
        return WidgetKind.allCases.first { $0.popRole == p.role && $0.popSkin == other }
    }

    /// หมวดใน gallery
    /// ตัวเลขผู้ติดตามอยู่ "เกี่ยวกับฉัน" เพราะมันคือขนาดของตัวเรา ไม่ใช่งานที่เคยทำ
    /// ส่วนแถบวิ่งโชว์ชื่อแบรนด์ที่ร่วมงาน จึงเป็นผลงาน ไม่ใช่ของตกแต่ง
    var group: WidgetGroup {
        switch self {
        case .artTypeOver, .heroMinimal,
             .artPortfolio, .portfolioWindow, .portfolioGingham,
             .aboutText, .statGiant, .socialChips, .socialTiles, .statWrapped, .statPoster, .socialWindow,
             .socialGingham,
             .nicheTags, .stickerTags, .interestTags, .nichePoster, .textBlock,
             // ประชากรผู้ติดตามคือ "หน้าตาของคนที่ตามเรา" จึงอยู่หมวดเดียวกับยอดฟอลโลว์
             .audienceLine, .audienceSplit, .audienceAge, .audienceMap, .audiencePoster,
             // ตรารับรองตอบคำถาม "เชื่อคนนี้ได้แค่ไหน" — เรื่องของตัวคน ไม่ใช่ของงานชิ้นใด
             .proofSeal,
             // สำรับสติกเกอร์ — สองวัสดุอยู่หมวดเดียวกันเสมอ (หมวดมาจากหน้าที่ ไม่ใช่วัสดุ)
             .popHeroPaper, .popHeroGlass, .popStatsGlass,
             .popNichePaper, .popNicheGlass, 
             // สำรับบรรณาธิการ — หน้าแนะนำตัว · ประโยคเดี่ยว · การ์ดขั้นตอน คือ "ฉันเป็นใคร"
             .aboutEditorial, .aboutBehind, .flowCards,
             .scrapFolder, .scrapBadge, .scrapKeyTab, .scrapFeed, .scrapTags, .scrapAbout, .scrapInfo,
             .scrapStats, .scrapStamp, .scrapLabel:
            return .about
        // ทุกอย่างที่ตอบคำถาม "จ้างยังไง เท่าไหร่ ติดต่อใคร"
        case .rateTags, .rateNeon,
             .contactCard, .contactQR,
             .contactBar, .contactStack, .contactLine, .contactChips, .contactPoster,
             .popRatePaper, .popRateGlass, .popContactPaper, .popContactGlass,
             .scrapReceipt, .scrapNote:
            return .booking
        case .proofBrandGrid, .proofBrandRail, .proofBrandCoins,
             .proofWork, .proofTicket, .typeMarquee,
             .artFilmstrip, .artDuo, .artPair, .workFeatured, .workReel, .artPhotobooth,
             .galleryStack, .galleryCarousel, .galleryMasonry, .galleryMosaic,
             .galleryPost, .galleryStory, .galleryFilm, .galleryTape, .reelShowcase,
             .popVideoPaper, .popVideoGlass, .popWorkPaper, .popWorkGlass,
             // กองรูปแบบบรรณาธิการ — ทั้งสามใบมีรูปเป็นเนื้อหาหลัก
             .wallPolaroid, .wallMemory, .zineCover,
             .scrapPhones, .scrapChat:
            return .work
        }
    }

    /// ตระกูล — ใช้หา "แบบอื่น" ที่สลับกันแล้วยังเล่าเรื่องเดิม
    var family: WidgetFamily {
        // ฝาแฝดสองวัสดุอยู่ตระกูลเดียวกัน — ปุ่ม "เปลี่ยนแบบ" จึงสลับกระดาษ↔กระจกได้ในตัว
        switch self {
        case .artTypeOver, .heroMinimal,
             // โปสเตอร์คัตเอาต์อยู่ตระกูลเดียวกับหน้าโปรไฟล์ที่เหลือ — กด "เปลี่ยนแบบ" แล้วเจอได้
             // ซึ่งแปลว่าคนที่ไม่เคยรู้จักคัตเอาต์จะเจอมันเอง · ราคาของการวางไว้ตรงนี้คือ
             // รูปทึบจะเด้งเข้าโหมดกรอบทันที โหมดกรอบจึงต้องเป็นหน้าตาที่ดีพอ ไม่ใช่ของสำรอง
             .artPortfolio, .portfolioWindow, .portfolioGingham,
             .popHeroPaper, .popHeroGlass,
             .scrapFolder, .scrapBadge: return .hero
        case .aboutText, .aboutEditorial, .aboutBehind, .scrapAbout, .scrapInfo: return .intro
        case .popStatsGlass: return .followers
        case .popVideoPaper, .popVideoGlass, .popWorkPaper, .popWorkGlass: return .photo
        case .popRatePaper, .popRateGlass: return .rate
        case .popNichePaper, .popNicheGlass: return .tags
        case .popContactPaper, .popContactGlass: return .contact
        case .proofBrandGrid, .proofBrandRail, .proofBrandCoins, .typeMarquee: return .brand
        // กำแพงโพลารอยด์อ่าน `track.works` เหมือนอีกห้าใบแล้ว — หนึ่งใบคือผลงานหนึ่งชิ้น
        // อยู่ตระกูลเดียวกันจึงถูกต้องสองทาง: กด "เปลี่ยนแบบ" สลับกับใบอื่นที่เล่าเรื่องเดียวกันได้
        // และได้สถานะ "รอข้อมูล" ของชั้นหลักฐานมาด้วย แทนที่จะวาดผนังเปล่าตอนยังไม่มีผลงาน
        case .proofWork, .proofTicket,
             .wallPolaroid,
             // รีวิวอ้างถึงงานจริงในระบบ — ได้สถานะ "รอข้อมูล" ของชั้นหลักฐานเหมือนกัน
             .scrapChat: return .verified
        // ตระกูลของตัวเอง — ไม่มีใบไหนเล่าเรื่องเดียวกันให้สลับได้
        case .proofSeal, .scrapStamp: return .seal
        case .statGiant, .socialChips, .socialTiles, .statWrapped, .statPoster, .socialWindow,
             .socialGingham, .scrapKeyTab, .scrapFeed: return .followers
        case .artFilmstrip, .artDuo, .artPair, .workFeatured, .workReel, .artPhotobooth,
             .galleryStack, .galleryCarousel, .galleryMasonry, .galleryMosaic,
             .galleryPost, .galleryStory, .galleryFilm, .galleryTape,
             .wallMemory, .zineCover, .scrapPhones: return .photo
        // ตระกูลของตัวเอง — ใบเดียวในตู้ที่ถือทั้งหัวเรื่อง รูปสี่ใบ และคำบรรยายรายชิ้น
        // ไม่มีใบไหนสลับกับมันได้โดยไม่ทำข้อความหาย (กติกาสัญญาของตระกูล)
        case .reelShowcase: return .showcase
        case .textBlock, .flowCards, .scrapLabel: return .text
        // สายงาน (พิมพ์เอง) กับ หมวดหมู่ (ของแพลตฟอร์ม) สลับกันได้ — เล่าเรื่องเดียวกัน
        case .nicheTags, .stickerTags, .interestTags, .nichePoster, .scrapTags: return .tags
        case .rateTags, .rateNeon, .scrapReceipt: return .rate
        case .contactCard, .contactQR,
             .contactBar, .contactStack, .contactLine, .contactChips,
             .contactPoster, .scrapNote: return .contact
        case .audienceLine, .audienceSplit, .audienceAge, .audienceMap, .audiencePoster,
             .scrapStats: return .audience
        }
    }

    /// ชั้นสิทธิ์ — ผูกกับที่มาของข้อมูล ไม่ใช่หมวดใน gallery
    /// (หมวดเหลือสามหมวดหยาบ ๆ แล้ว ใช้แทนกันไม่ได้อีก)
    var tier: WidgetTier {
        if let role = popRole { return role == .stats || role == .rate ? .connected : .personal }
        switch self {
        case .proofBrandGrid, .proofBrandRail, .proofBrandCoins,
             .proofWork, .proofTicket, .proofSeal,
             .wallPolaroid, .scrapStamp, .scrapChat:
            return .verified                       // แพลตฟอร์มออกให้จากงานที่ส่งจริง
        case .statGiant, .socialChips, .socialTiles, .statWrapped, .statPoster, .socialWindow,
             .socialGingham,
             .interestTags,
             // สถิติผู้ชมมาจาก OAuth · เรตมีราคาที่ระบบแนะนำกำกับ
             .audienceLine, .audienceSplit, .audienceAge, .audienceMap, .audiencePoster,
             .rateTags, .rateNeon,
             .scrapKeyTab, .scrapFeed, .scrapStats, .scrapReceipt:
            return .connected                      // ยอด OAuth · ราคาที่ระบบแนะนำ · ตั้งค่าจากโปรไฟล์
        default:
            return .personal
        }
    }

    /// widget ที่ **มีพื้นผิวของตัวเองอยู่แล้ว** — chrome จึงไม่ครอบแผ่นซ้ำ
    ///
    /// กติกาของการ์ดคือ *ทุกชิ้นต้องมีพื้น* (เข้ม หรือ กระจก) — ของที่ลอยอยู่บนพื้นการ์ดเปล่า ๆ
    /// อ่านไม่ออกว่าเป็นชิ้นเดียวกันหรือคนละชิ้น ที่นี่จึงตอบแค่ว่า **ใครเป็นคนวาดพื้นนั้น**:
    /// ตัวในลิสต์วาดเอง (กระดาษ · ฟิล์ม · ป้ายไฟ · รูปเต็มกรอบ · แผ่นสติกเกอร์)
    /// ตัวที่เหลือให้ `WidgetChrome` วาดให้ตามพื้นผิวที่ผู้ใช้เลือก
    ///
    /// ก้อนข้อความอยู่ในลิสต์นี้ด้วย — มันคือตัวอักษรที่พิมพ์ลงบนการ์ดแบบ IG ไม่ใช่กล่อง
    /// ครอบแผ่นให้เมื่อไหร่มันกลายเป็นป้าย และไม่มีปุ่มไหนให้เอาออกได้ด้วย
    var drawsOwnSurface: Bool {
        // แผ่นสติกเกอร์ — กล่องขาวกับป้ายหัวข้อคือพื้นผิวของมันเอง (แต่ยังอ่านพื้นผิวที่เลือกไปใช้)
        if isPop || isScrap { return true }
        switch self {
        // รูปเต็มกรอบ/วัสดุรูป — ตัวรูปคือพื้นอยู่แล้ว
        case .artTypeOver, .artFilmstrip, .artDuo, .artPair,
             // โปสเตอร์พอร์ตวาดกระดาษของตัวเอง — และถอดกระดาษนั้นออกได้ด้วย (ดู `surfaceOptions`)
             .artPortfolio,
             // โปสเตอร์สายงาน — แผ่นสีเข้มของมันคือดีไซน์ และถอดออกได้ (ดู `surfaceOptions`)
             .nichePoster,
             // โปสเตอร์ผู้ติดตาม — เหตุผลเดียวกัน แผ่นเข้มคือดีไซน์ ไม่ใช่กรอบที่ chrome ครอบให้
             .statPoster,
             // โปสเตอร์อินไซต์ — เหตุผลเดียวกัน
             .audiencePoster,
             // ตรารับรอง — แผ่นเข้มกับลายกิโยเช่คือดีไซน์ และถอดออกได้ (ดู `surfaceOptions`)
             .proofSeal,
             .statGiant,
             // ข้อความล้วน — ตัวมันเองคือตัวอักษร ครอบกระจกแล้วกลายเป็นป้ายแทนที่จะเป็นข้อความ
             .textBlock,
             // ตั๋วผลงานวาดพื้นผิวของตัวเอง (กระดาษตั๋ว) — ครอบกระจกทับแล้วจะได้กล่องซ้อนกล่อง
             // และพื้นกระดาษจะสู้กับพื้นกระจกจนสีเพี้ยน
             .proofTicket,
             // สำรับ Gen Z — วัสดุของแต่ละตัวคือพื้นผิวของมันเอง (แสง · กระดาษโน้ต ·
             // บล็อกสีทึบ · กระดาษภาพ · ฟองแชต · สติกเกอร์) ครอบกระจกแล้วจะสู้กันทั้งชุด
             .statWrapped, .artPhotobooth, .stickerTags,
             // บัตรกระดาษที่วาดพื้นผิวของตัวเอง
             .contactQR,
             // โปสเตอร์ติดต่อ — แผ่นไล่เฉดของมันคือดีไซน์ ครอบกระจกทับแล้วคนจะกลับไปอยู่ในกล่อง
             .contactPoster,
             // ป้ายราคาเป็นกระดาษแข็งที่มีเงาของตัวเอง — ครอบกระจกแล้วได้กล่องซ้อนกล่อง
             .rateTags,
             // ป้ายไฟวาดแผ่นมืดของตัวเอง — กระจกที่ครอบทับจะสู้กับพื้นวัสดุจนสีเพี้ยน
             .rateNeon,
             // สำรับกองรูป — กระเบื้องรูปลอยบนการ์ด (บอร์ดพิน · โมเสก · สไลด์)
             // และของที่วาดวัสดุของตัวเอง (กระดาษอัดรูป · ฟิล์ม · เทปกาว)
             // ครอบกระจกทับแล้วได้กล่องซ้อนกล่อง และพื้นวัสดุจะสู้กับพื้นกระจกจนสีเพี้ยน
             // ยกเว้น `โพสต์` กับ `สตอรี่` — สองตัวนั้นคือ *กรอบของแพลตฟอร์ม* กระจกคือกรอบนั้น
             .galleryStack, .galleryCarousel, .galleryMasonry, .galleryMosaic,
             .galleryFilm, .galleryTape,
             // สำรับบรรณาธิการ — ทุกใบเป็น *แผ่นกระดาษของตัวเอง* (ครีม · เทา · รูปเต็มแผ่น)
             // กระจกที่ครอบทับจะกลายเป็นขอบที่สองรอบกระดาษ แล้วผังที่ชนขอบทั้งใบก็เสียไป
             .wallPolaroid, .wallMemory, .zineCover, .aboutEditorial, .aboutBehind,
             .flowCards,
             // แผ่นโชว์คลิป — แผ่นสีเข้มของมันคือตัวงาน ไม่ใช่กรอบที่ chrome วาดให้
             .reelShowcase,
             // สำรับหน้าต่าง — กรอบหน้าต่าง macOS คือพื้นของมัน ครอบกระจกทับแล้วได้หน้าต่างในกล่อง
             .socialWindow, .portfolioWindow,
             // สำรับผ้าปิกนิก — กระดาษครีมกับผ้าตารางคือพื้นของมัน ไม่มีพื้นให้เลือก
             .socialGingham, .portfolioGingham:
            return true
        // ตัวหนังสือ · ชิป · แถบโลโก้ ที่เคยลอยบนการ์ดเปล่า — ตอนนี้ได้แผ่นจาก chrome เหมือนแผ่นข้อมูล
        default:
            return false
        }
    }

    /// ชิ้นที่ให้ผู้ใช้เลือกพื้นผิวได้
    ///
    /// เดิมคือ "ทุกตัวยกเว้นของที่วาดพื้นเอง" — จริงตอนที่ตัวเลือกมีแค่ กระจก/เข้ม
    /// เพราะสองอย่างนั้นเป็นแผ่นที่ *chrome* วาด ซึ่งของที่มีวัสดุของตัวเองไม่ได้ใช้
    ///
    /// แต่ **ไม่มีพื้น** เป็นคำถามคนละข้อ: "ใบนี้ต้องมีกระดาษรองไหม" ซึ่งเป็นคำถามที่
    /// ของที่วาดพื้นเองต้องตอบมากกว่าใครเสีย — กระดาษของมันคือกรอบที่ตัดมันออกจากการ์ด
    /// ตัวที่มีตัวเลือกให้เลือกมากกว่าหนึ่งแบบจึงได้แถวนี้ทั้งหมด (ดู `surfaceOptions`)
    var usesSurfaceChoice: Bool { surfaceOptions.count > 1 }
    /// ใบที่มีแผ่นทึบของตัวเอง (สำรับโปสเตอร์ · บรรณาธิการ · โชว์คลิป) — ใส่ลายทางบนแผ่นได้
    var takesPattern: Bool { surfaceOptions.contains(.pane) && !isScrap }
    /// โปสเตอร์ที่คน **ยืนบนการ์ด** — รูปทึบถูกลบพื้นหลังให้อัตโนมัติ (Vision ของ Apple ในเครื่อง)
    /// ปิดได้รายชิ้นในถาด (`WidgetInstance.liftPhoto`) สำหรับคนที่อยากได้รูปในกรอบ
    var liftsSubject: Bool {
        self == .artPortfolio || self == .nichePoster || self == .contactPoster || self == .portfolioWindow
            || self == .portfolioGingham || self == .scrapFolder
    }
    /// ใบที่รับ **ตราปั๊มนูน Sale Here STAR** บนแผ่นของตัวเองได้ — ปิดได้รายชิ้นในถาด (`WidgetInstance.emboss`)
    ///
    /// เลือกเฉพาะใบที่มี *วัสดุทึบ* ให้ปั๊ม (แผ่นโปสเตอร์ · บล็อกสี) — บนกระจกหรือบนรูปถ่าย
    /// ตรานูนไม่มีอะไรให้กดลงไป · สองใบหลังเป็นใบที่โชว์ตัวเลขของ Sale Here แต่ตั้งใจไม่มีป้ายตัวอักษร
    /// ส่วนโปสเตอร์พอร์ตคือปกของการ์ด ตรานูนบนปกคือลายเซ็นผู้ออกแบบเดียวกับปกหนังสือเดินทาง
    ///
    /// `ตั๋วผลงาน` เคยอยู่ในลิสต์นี้: หางตั๋วกว้างแค่ราว 66pt ตราที่ 11pt อ่านเป็นรอยเปื้อนข้างชื่อแบรนด์
    /// และใบนั้นมีป้าย "Verified by" ที่หัวอยู่แล้ว — ตราที่สองไม่ได้เพิ่มความหมาย จึงถอดออก
    var takesEmboss: Bool {
        self == .artPortfolio || self == .statPoster || self == .statWrapped
    }

    /// widget ที่อ่าน `WidgetInstance.textStyle` — แผงของมันจะมีเรื่องฟอนต์/สี/ขนาด/จัดวางเพิ่ม
    ///
    /// เปิดเฉพาะตัวที่ **ทั้งใบเป็นตัวอักษรที่ผู้ใช้พิมพ์เอง** เท่านั้น
    /// ตัวอื่นหน้าตาถูกออกแบบมาแล้วเป็นชุด — เปิดให้เปลี่ยนฟอนต์ทีละก้อนเมื่อไหร่
    /// การ์ดจะกลายเป็นเอกสารที่มีสิบฟอนต์ ซึ่งเป็นสิ่งที่ตู้ทั้งตู้พยายามกันไม่ให้เกิด
    var usesTextStyle: Bool { self == .textBlock }

    /// widget ที่แสดงรูปครีเอเตอร์หรือรูปผลงาน — เปิดให้อัปโหลดรูปของตัวเองทับรูปตั้งต้นได้
    var usesPhoto: Bool {
        if let role = popRole { return role == .hero || role == .video || role == .work }
        switch self {
        case .artTypeOver, .statGiant, 
             .artPortfolio, .nichePoster, .contactPoster,
             .audiencePoster, .portfolioWindow, .portfolioGingham,
             .artFilmstrip, .artDuo, .artPair, .workFeatured, .workReel, .proofWork,
             .artPhotobooth,
             // ชั้นหลักฐานตอนนี้ใช้รูปทุกตัว — ตัวที่ไม่ใช้ถูกถอดออกไปแล้ว
             .proofTicket,
             // สำรับกองรูปใช้รูปทั้งแปดตัว — มันคือทั้งหมดที่ตระกูลนี้มี
             .galleryStack, .galleryCarousel, .galleryMasonry, .galleryMosaic,
             .galleryPost, .galleryStory, .galleryFilm, .galleryTape,
             // สำรับบรรณาธิการที่มีช่องรูป — สามใบกองรูป และสองหน้าแนะนำตัว
             .wallPolaroid, .wallMemory, .zineCover, .aboutEditorial, .aboutBehind,
             // แผ่นโชว์คลิป — สี่ช่องในเครื่องคือรูปปกคลิปของเจ้าของการ์ด
             .reelShowcase,
             // สำรับสแครปบุ๊ก — ใบที่มีโพลารอยด์ · จอมือถือ · รูปโปรไฟล์
             .scrapFolder, .scrapBadge, .scrapFeed, .scrapAbout, .scrapPhones:
            return true
        default:
            return false
        }
    }

    /// widget ที่มีรูปเป็นแกนหลัก — ต้องเว้น padding เป็นศูนย์เพื่อให้รูปชนขอบ
    var isFullBleed: Bool {
        switch self {
        // สตอรี่คือเฟรมเต็มจอของแพลตฟอร์ม — เว้นขอบเมื่อไหร่มันเลิกเป็นสตอรี่ทันที
        case .workFeatured, .workReel, .galleryStory: return true
        default: return false
        }
    }

    var title: String {
        switch self {
        case .artTypeOver: return "ตัวอักษรทับภาพ"
        case .artPortfolio: return "โปสเตอร์พอร์ต"
        case .portfolioWindow: return "หน้าต่างพอร์ต"
        case .portfolioGingham: return "พอร์ตผ้าปิกนิก"
        case .heroMinimal: return "ชื่อมินิมอล"
        case .aboutText: return "แนะนำตัว"
        case .interestTags: return "หมวดหมู่ที่สนใจ"
        case .proofBrandGrid: return "แผงโลโก้ครบ"
        case .proofBrandRail: return "โลโก้เลื่อน"
        case .proofBrandCoins: return "เหรียญโลโก้"
        case .proofWork: return "ผลงานที่ยืนยันแล้ว"
        case .proofTicket: return "ตั๋วผลงาน"
        case .proofSeal: return "ตรารับรอง Sale Here"
        case .statGiant: return "ตัวเลขยักษ์"
        case .socialChips: return "ผู้ติดตามแบบแถว"
        case .socialTiles: return "ผู้ติดตามแบบชิป"
        case .statWrapped: return "การ์ดสรุปยอด"
        case .statPoster: return "โปสเตอร์ผู้ติดตาม"
        case .socialWindow: return "หน้าต่างช่องทาง"
        case .socialGingham: return "ช่องทางผ้าปิกนิก"
        case .artPhotobooth: return "ตู้ถ่ายรูป"
        case .stickerTags: return "สติกเกอร์สายงาน"
        case .artFilmstrip: return "แถบภาพ"
        case .artDuo: return "เบนโตะ"
        case .artPair: return "คู่แนวตั้ง"
        case .workFeatured: return "ผลงานชิ้นเด่น"
        case .workReel: return "คลิปแนวตั้ง"
        case .galleryStack: return "กองรูปซ้อน"
        case .galleryCarousel: return "สไลด์การ์ด"
        case .galleryMasonry: return "บอร์ดพิน"
        case .galleryMosaic: return "โมเสก"
        case .galleryPost: return "โพสต์โซเชียล"
        case .galleryStory: return "สตอรี่"
        case .galleryFilm: return "ฟิล์ม 35 มม."
        case .galleryTape: return "เทปกาว"
        case .reelShowcase: return "คลิปล่าสุด"
        case .typeMarquee: return "แถบวิ่ง"
        case .textBlock: return "ข้อความ"
        case .wallPolaroid: return "กำแพงโพลารอยด์"
        case .wallMemory: return "บอร์ดรูปติดหมุด"
        case .zineCover: return "ปกผลงาน"
        case .aboutEditorial: return "หน้าแนะนำตัว"
        case .aboutBehind: return "ชื่อหลังภาพ"
        case .flowCards: return "การ์ดขั้นตอน"
        case .scrapFolder: return "แฟ้มสแครปบุ๊ก"
        case .scrapBadge: return "บัตรครีเอเตอร์"
        case .scrapKeyTab: return "พวงกุญแจโซเชียล"
        case .scrapFeed: return "ฟีดของฉัน"
        case .scrapTags: return "ป้ายห้อยสายงาน"
        case .scrapAbout: return "รู้จักตัวฉัน"
        case .scrapInfo: return "บัตรข้อมูลของฉัน"
        case .scrapReceipt: return "ใบเสร็จเรท"
        case .scrapStats: return "สถิติผู้ชม"
        case .scrapStamp: return "ตรายางยืนยันตัวตน"
        case .scrapPhones: return "กำแพงมือถือ"
        case .scrapChat: return "แชทจากแบรนด์"
        case .scrapNote: return "โน้ตติดต่อ"
        case .scrapLabel: return "หัวข้อกล่องคำ"
        case .nicheTags: return "สายงาน"
        case .nichePoster: return "โปสเตอร์สายงาน"
        case .rateTags: return "ป้ายราคา"
        case .rateNeon: return "ป้ายไฟ"
        case .contactCard: return "นามบัตร"
        case .contactQR: return "คิวอาร์การ์ด"
        case .contactBar: return "แถบติดต่อ"
        case .contactStack: return "สามบรรทัด"
        case .contactLine: return "ไลน์ตัวใหญ่"
        case .contactChips: return "ชิปช่องทาง"
        case .contactPoster: return "โปสเตอร์ติดต่อ"
        case .audienceLine: return "ประโยคเดียว"
        case .audienceSplit: return "สัดส่วนผู้ชม"
        case .audienceAge: return "ช่วงอายุผู้ชม"
        case .audienceMap: return "ผู้ชมในประเทศ"
        case .audiencePoster: return "โปสเตอร์อินไซต์"
        // สำรับสติกเกอร์ — ค่ามาจากหน้าที่ (ดู `PopRole`) แต่ยังเขียนครบทุกชนิดตรงนี้
        // เพื่อให้คอมไพเลอร์ฟ้องเมื่อมีชนิดใหม่โผล่มาโดยไม่มีใครตอบให้
        case .popHeroPaper, .popHeroGlass, .popVideoPaper, .popVideoGlass,
             .popStatsGlass, .popWorkPaper, .popWorkGlass,
             .popRatePaper, .popRateGlass, .popNichePaper, .popNicheGlass,
             .popContactPaper, .popContactGlass:
            // ชื่อ = หน้าที่ + วัสดุ · สองใบในตู้ต้องแยกกันด้วยชื่อ ไม่ใช่ด้วยรูปอย่างเดียว
            guard let p = popParts else { return "" }
            return p.role.title + " " + p.skin.label
        }
    }

    var symbol: String {
        switch self {
        case .artTypeOver: return "textformat.alt"
        case .artPortfolio: return "person.and.background.striped.horizontal"
        case .portfolioWindow: return "macwindow.on.rectangle"
        case .portfolioGingham: return "person.crop.artframe"
        case .heroMinimal: return "textformat"
        case .aboutText: return "text.alignleft"
        case .interestTags: return "heart.text.square.fill"
        case .proofBrandGrid: return "square.grid.3x3.fill"
        case .proofBrandRail: return "arrow.left.arrow.right"
        case .proofBrandCoins: return "circle.grid.2x1.fill"
        case .proofWork: return "checkmark.seal.fill"
        case .proofTicket: return "ticket.fill"
        case .proofSeal: return "checkmark.seal.fill"
        case .statGiant: return "number.circle.fill"
        case .socialChips: return "list.bullet.rectangle.fill"
        case .socialTiles: return "circle.grid.3x1.fill"
        case .statWrapped: return "list.number"
        case .statPoster: return "number.square.fill"
        case .socialWindow: return "macwindow"
        case .socialGingham: return "square.grid.3x3.square"
        case .artPhotobooth: return "camera.fill"
        case .stickerTags: return "seal.fill"
        case .artFilmstrip: return "rectangle.split.3x1.fill"
        case .artDuo: return "square.grid.2x2.fill"
        case .artPair: return "rectangle.split.2x1.fill"
        case .workFeatured: return "rectangle.grid.1x2.fill"
        case .workReel: return "play.rectangle.fill"
        case .galleryStack: return "square.stack.fill"
        case .galleryCarousel: return "square.on.square"
        case .galleryMasonry: return "rectangle.split.2x2.fill"
        case .galleryMosaic: return "circle.grid.3x3.fill"
        case .galleryPost: return "text.below.photo.fill"
        case .galleryStory: return "camera.viewfinder"
        case .galleryFilm: return "film.fill"
        case .galleryTape: return "paperclip"
        case .reelShowcase: return "iphone"
        case .typeMarquee: return "text.line.first.and.arrowtriangle.forward"
        case .textBlock: return "textformat.size"
        case .wallPolaroid: return "photo.stack"
        case .wallMemory: return "pin.fill"
        case .zineCover: return "magazine.fill"
        case .aboutEditorial: return "text.word.spacing"
        case .aboutBehind: return "person.and.background.dotted"
        case .flowCards: return "rectangle.3.group.fill"
        case .scrapFolder: return "folder.fill"
        case .scrapBadge: return "person.text.rectangle"
        case .scrapKeyTab: return "key.fill"
        case .scrapFeed: return "square.grid.2x2"
        case .scrapTags: return "tag.fill"
        case .scrapAbout: return "person.crop.square"
        case .scrapInfo: return "list.bullet.rectangle.portrait"
        case .scrapReceipt: return "scroll.fill"
        case .scrapStats: return "chart.bar.xaxis"
        case .scrapStamp: return "checkmark.seal"
        case .scrapPhones: return "iphone.gen3"
        case .scrapChat: return "bubble.left.and.bubble.right.fill"
        case .scrapNote: return "note.text"
        case .scrapLabel: return "character.textbox"
        case .nicheTags: return "tag"
        case .nichePoster: return "tags.fill"
        case .rateTags: return "tag.fill"
        case .rateNeon: return "lightbulb.fill"
        case .contactCard: return "person.text.rectangle.fill"
        case .contactQR: return "qrcode"
        case .contactBar: return "text.append"
        case .contactStack: return "list.bullet"
        case .contactLine: return "bubble.left.fill"
        case .contactChips: return "capsule.portrait.fill"
        case .contactPoster: return "person.crop.rectangle.fill"
        case .audienceLine: return "text.alignleft"
        case .audienceSplit: return "person.2.fill"
        case .audienceAge: return "chart.bar.fill"
        case .audienceMap: return "mappin.and.ellipse"
        case .audiencePoster: return "chart.pie.fill"
        // สำรับสติกเกอร์ — ค่ามาจากหน้าที่ (ดู `PopRole`) แต่ยังเขียนครบทุกชนิดตรงนี้
        // เพื่อให้คอมไพเลอร์ฟ้องเมื่อมีชนิดใหม่โผล่มาโดยไม่มีใครตอบให้
        case .popHeroPaper, .popHeroGlass, .popVideoPaper, .popVideoGlass,
             .popStatsGlass, .popWorkPaper, .popWorkGlass,
             .popRatePaper, .popRateGlass, .popNichePaper, .popNicheGlass,
             .popContactPaper, .popContactGlass:
            return popRole?.symbol ?? "square.fill"
        }
    }

    /// ขนาดตั้งต้นตอนหยิบออกจากตู้ — **หน่วย pt บนพื้นที่ออกแบบ** (ดู `PageLayout.designWidth`)
    ///
    /// เป็นค่าที่ "พอดีสวย" ไม่ใช่ค่าที่ "เล็กสุดที่ยังได้"
    ///
    /// # ทำไมเป็น pt ไม่ใช่คอลัมน์/แถวอีกแล้ว
    ///
    /// ค่าชุดนี้แปลงตรงมาจากตารางกริดเดิม (คอลัมน์ → ความกว้าง · แถว → ความสูงจริงเป็น pt)
    /// สิ่งที่เปลี่ยนไม่ใช่ตัวเลข แต่คือ **ความหมาย**: เดิม "6 คอลัมน์" แปลว่าเต็มหน้าเสมอ
    /// หน้าจะกว้างเท่าไหร่ก็ตาม — ตอนนี้ 492 คือ 492 เท่ากันทุกเครื่องและในไฟล์ที่ export
    ///
    /// 492 = ความกว้างหน้าเต็ม (540 − ขอบ 24 สองข้าง) จึงยังเป็นตัวที่กินเต็มหน้าอยู่
    var defaultSize: CGSize {
        switch self {
        case .artTypeOver:     return CGSize(width: 366, height: 367)
        // สูงกว่าตระกูลเดียวกัน — ตัวคนเต็มตัวต้องมีที่ยืน กรอบเตี้ยได้แค่ครึ่งตัวลอย
        // โปสเตอร์เต็มแผ่น — คำยักษ์กินความกว้างทั้งใบ คนต้องมีที่ยืนเต็มตัวใต้คำนั้น
        case .artPortfolio:    return CGSize(width: 366, height: 488)
        // หน้าต่างพอร์ตตั้งตรง — สัดส่วนของแผ่นต้นฉบับ 420 × 648 (ดู `PWin`)
        case .portfolioWindow: return CGSize(width: PWin.w, height: PWin.h)
        // โปสเตอร์ผ้าปิกนิกตั้งตรง — สัดส่วนของแผ่นต้นฉบับ 444 × 760 (ดู `PG`)
        case .portfolioGingham: return CGSize(width: PG.w, height: PG.h)
        case .heroMinimal:     return CGSize(width: 366, height: 135)
        case .aboutText:       return CGSize(width: 366, height: 135)
        case .interestTags:    return CGSize(width: 366, height: 117)
        case .proofBrandGrid:  return CGSize(width: 366, height: 206)
        case .proofBrandRail:  return CGSize(width: 366, height: 81)
        case .proofBrandCoins: return CGSize(width: 366, height: 94)
        case .proofWork:       return CGSize(width: 366, height: 295)
        case .proofTicket:     return CGSize(width: 366, height: 260)
        // โปสเตอร์เต็มแผ่นแนวนอน — ผังของมัน (ดู `VS` ใน `VerifiedSealWidget.swift`)
        case .proofSeal:       return CGSize(width: 366, height: 232)
        case .statGiant:       return CGSize(width: 366, height: 206)
        case .socialChips:     return CGSize(width: 366, height: 224)
        case .socialTiles:     return CGSize(width: 366, height: 117)
        case .statWrapped:     return CGSize(width: 366, height: 260)
        // โปสเตอร์เต็มแผ่นแนวนอน — ผังของมัน (ดู `SP` ใน `StatPosterWidget.swift`)
        case .statPoster:      return CGSize(width: 366, height: 214)
        // หน้าต่างแนวนอนเต็มหน้า — สัดส่วนของแผ่นต้นฉบับ 842 × 208 (ดู `SW`)
        case .socialWindow:    return CGSize(width: SW.w, height: SW.h)
        // ป้ายผ้าปิกนิกแนวนอนเต็มหน้า — สัดส่วนของแผ่นต้นฉบับ 974 × 248 (ดู `SG`)
        case .socialGingham:   return CGSize(width: SG.w, height: SG.h)
        case .artPhotobooth:   return CGSize(width: 366, height: 188)
        case .stickerTags:     return CGSize(width: 366, height: 135)
        case .artFilmstrip:    return CGSize(width: 366, height: 99)
        case .artDuo:          return CGSize(width: 366, height: 260)
        case .artPair:         return CGSize(width: 366, height: 188)
        case .workFeatured:    return CGSize(width: 366, height: 260)
        case .workReel:        return CGSize(width: 117, height: 313)
        case .galleryStack:    return CGSize(width: 366, height: 224)
        case .galleryCarousel: return CGSize(width: 366, height: 206)
        case .galleryMasonry:  return CGSize(width: 366, height: 242)
        case .galleryMosaic:   return CGSize(width: 366, height: 313)
        case .galleryPost:     return CGSize(width: 366, height: 313)
        case .galleryStory:    return CGSize(width: 179, height: 295)
        case .galleryFilm:     return CGSize(width: 366, height: 117)
        case .galleryTape:     return CGSize(width: 366, height: 206)
        // แผ่นโชว์คลิป — ผังถูกออกแบบที่ขนาดนี้เป๊ะ (ดู `Reel` ใน `ShowcaseWidgets.swift`)
        case .reelShowcase:    return CGSize(width: 366, height: 254)
        case .typeMarquee:     return CGSize(width: 366, height: 46)
        case .textBlock:       return CGSize(width: 366, height: 117)
        // สำรับบรรณาธิการ — ทุกใบเต็มความกว้างหน้า เพราะผังของมันเป็น *หน้า* ไม่ใช่ป้าย
        case .wallPolaroid:    return CGSize(width: 366, height: 470)
        case .wallMemory:      return CGSize(width: 366, height: 366)
        case .zineCover:       return CGSize(width: 366, height: 430)
        case .aboutEditorial:  return CGSize(width: 366, height: 340)
        case .aboutBehind:     return CGSize(width: 366, height: 330)
        case .flowCards:       return CGSize(width: 366, height: 300)
        // สำรับสแครปบุ๊ก — ผังของแต่ละใบ (ดู `ScrapSize`) ที่ความกว้างเต็มหน้า 366 · ครึ่งหน้า 178
        case .scrapFolder, .scrapBadge, .scrapKeyTab, .scrapFeed, .scrapTags, .scrapAbout, .scrapInfo,
             .scrapReceipt, .scrapStats, .scrapStamp, .scrapPhones, .scrapChat, .scrapNote, .scrapLabel:
            guard let d = scrapDesign else { return CGSize(width: 366, height: 300) }
            let w: CGFloat = d.width > 200 ? 366 : (d.width > 150 ? 178 : 109)
            return CGSize(width: w, height: (d.height * w / d.width).rounded())
        case .nicheTags:       return CGSize(width: 366, height: 81)
        // โปสเตอร์เต็มแผ่นแนวนอน — สัดส่วนของต้นฉบับ (ดู `NP` ใน `NichePosterWidget.swift`)
        case .nichePoster:     return CGSize(width: 366, height: 221)
        case .rateTags:        return CGSize(width: 366, height: 117)
        case .rateNeon:        return CGSize(width: 366, height: 224)
        case .contactCard:     return CGSize(width: 366, height: 135)
        case .contactQR:       return CGSize(width: 179, height: 224)
        case .contactBar:      return CGSize(width: 366, height: 64)
        case .contactStack:    return CGSize(width: 366, height: 153)
        case .contactLine:     return CGSize(width: 366, height: 117)
        case .contactChips:    return CGSize(width: 366, height: 117)
        // โปสเตอร์เต็มแผ่น — คนต้องมีที่ยืนเต็มตัวข้างคอลัมน์ช่องทาง (ดู `CP`)
        case .contactPoster:   return CGSize(width: 366, height: 270)
        case .audienceLine:    return CGSize(width: 366, height: 153)
        case .audienceSplit:   return CGSize(width: 366, height: 135)
        case .audienceAge:     return CGSize(width: 366, height: 171)
        case .audienceMap:     return CGSize(width: 366, height: 188)
        // แผ่นอินไซต์ตั้งตรง — ผังของมัน (ดู `IP` ใน `InsightPosterWidget.swift`)
        case .audiencePoster:  return CGSize(width: 366, height: 520)
        // สำรับสติกเกอร์ — ค่ามาจากหน้าที่ (ดู `PopRole`) แต่ยังเขียนครบทุกชนิดตรงนี้
        // เพื่อให้คอมไพเลอร์ฟ้องเมื่อมีชนิดใหม่โผล่มาโดยไม่มีใครตอบให้
        case .popHeroPaper, .popHeroGlass, .popVideoPaper, .popVideoGlass,
             .popStatsGlass, .popWorkPaper, .popWorkGlass,
             .popRatePaper, .popRateGlass, .popNichePaper, .popNicheGlass,
             .popContactPaper, .popContactGlass:
            // สองวัสดุใช้ผังเดียวกันเป๊ะ ขนาดจึงขึ้นกับหน้าที่อย่างเดียว
            return popRole?.defaultSize ?? CGSize(width: 366, height: 224)
        }
    }

    /// **สัดส่วนที่ผังถูกออกแบบไว้** — ไม่ใช่กรงที่ขังกรอบ แต่เป็นจุดอ้างอิงของการสเกล
    ///
    /// # กรอบยืดได้อิสระ · สัดส่วนเป็นแค่ "ขนาดอ้างอิง"
    ///
    /// เคยล็อกกรอบให้ตรงสัดส่วนนี้เป๊ะ (ยืดได้ทางเดียวคือลากทแยง) ซึ่งแก้ปัญหาผังเพี้ยนได้จริง
    /// แต่สร้างปัญหาที่ใหญ่กว่าขึ้นมาแทน: **ทำให้กว้างขึ้นต้องยอมให้สูงขึ้นด้วยเสมอ** —
    /// แถบติดต่อที่อยากได้เต็มความกว้างบนสตอรี่ต้องแลกด้วยความสูงที่เพิ่มขึ้น 24pt
    /// ทั้งที่เนื้อหาไม่ได้เพิ่ม · ห้าใบบนหน้าเดียวคือ 22% ของหน้าที่หายไปเฉย ๆ
    ///
    /// ตอนนี้กรอบยืดได้ทั้งสองแกนตามใจ แล้ว **การโชว์เป็นฝ่ายรับมือ**: เนื้อหาถูกสเกลด้วย
    /// แกนที่คับที่สุด ส่วนแกนที่เหลือกลายเป็นที่ว่างให้ผังไหลออกไป (ดู `WidgetChrome`)
    /// ผลคือกรอบเตี้ยกว้างได้แถบที่กระจายออกโดยตัวหนังสือไม่เล็กลง · กรอบตรงสัดส่วนเดิม
    /// ได้พฤติกรรม "ย่อขยายทั้งก้อนเหมือนรูป" เหมือนเดิมทุกประการ · และไม่มีทางถูกกรอบตัด
    var aspect: CGFloat {
        let s = defaultSize
        return s.height / max(s.width, 1)
    }

    /// ความสูงที่คู่กับความกว้างนี้ตามสัดส่วนที่ออกแบบไว้ — ใช้ตอนลากหมุดมุม (สเกลทั้งชิ้น)
    /// และเป็นความสูงตั้งต้นของผังในเทมเพลตที่ระบุมาแค่ความกว้าง
    func height(forWidth w: CGFloat) -> CGFloat { max(1, (w * aspect).rounded()) }

    /// ขนาดเต็มที่ความกว้างนี้
    func size(forWidth w: CGFloat) -> CGSize { CGSize(width: w, height: height(forWidth: w)) }

    /// ปรับขนาดได้ไหม — ก้อนข้อความปรับผ่านขนาดตัวอักษรแทน จึงไม่มีหมุดย่อขยายกล่อง
    var canResize: Bool { self != .textBlock }

    /// **ใบที่วาดผังของตัวเองที่ขนาดออกแบบตายตัว** แล้วสเกลตามความกว้าง (สำรับโปสเตอร์)
    ///
    /// ต่างจากใบอื่นตรงที่ข้างในไม่ได้จัดตัวเองตามกรอบ — มันคือแผ่นที่จัดหน้ามาแล้วทั้งแผ่น
    /// (พาดหัว · ตัวคน · แถวค่า วางสัมพันธ์กันแบบตายตัว) สิ่งที่ยืดได้คือ *พื้นของแผ่น* เท่านั้น
    ///
    /// ผลที่ตามมาสองข้อ ซึ่งเป็นเหตุผลที่ต้องมีธงนี้:
    /// 1. **ความสูงต่ำสุดของมันคือสัดส่วนที่ออกแบบไว้** ที่ความกว้างนั้น — เตี้ยกว่านั้น
    ///    เนื้อหาจะถูกกรอบตัด (เบอร์โทรหายไปครึ่งใบ) ซึ่งเป็นสิ่งที่ผู้ใช้ไม่ควรทำได้โดยบังเอิญ
    ///    ตัววัดความสูงอัตโนมัติ (`CardScreen.minHeight`) แยกใบพวกนี้จากใบที่ยืดหดได้จริงไม่ได้
    ///    เพราะทั้งคู่ "กินความสูงเท่าที่ยื่นให้" เหมือนกัน — จึงต้องบอกตรงนี้
    /// 2. ใบพวกนี้ต้องไม่ถูกครอบ chrome ซ้ำ (อยู่ใน `drawsOwnSurface` อยู่แล้ว)
    var keepsDesignAspect: Bool {
        switch self {
        case .reelShowcase, .nichePoster, .contactPoster, .statPoster, .audiencePoster,
             .proofSeal, .socialWindow, .portfolioWindow,
             .socialGingham, .portfolioGingham: return true
        default: return isScrap
        }
    }

    /// พื้นผิวตั้งต้นตอนหยิบออกจากตู้/สลับแบบ — **กระจกเสมอ** ไม่มีชิ้นไหนเริ่มต้นแบบไม่มีพื้น
    ///
    /// สำรับสติกเกอร์วาดแผ่นของตัวเอง (`drawsOwnSurface`) แต่แผ่นนั้น **อ่านค่าพื้นผิวของชิ้น** ผ่าน
    /// `widgetSurface` — กระจกโปร่งเห็นกริดพื้นหลังทะลุตามไฟล์ดีไซน์ · เข้มคือแผ่นทึบ
    var defaultSurface: WidgetSurface {
        // โปสเตอร์อินไซต์ — ต้นฉบับไม่มีกรอบ พื้นของมันคือสีพื้นหลังการ์ดที่เจ้าของเลือก
        self == .audiencePoster ? .clear : .glass
    }

    /// พื้นผิวที่ใบนี้ให้เลือก — ไม่ใช่ทุกใบที่ถอดพื้นออกแล้วยังอ่านออก
    ///
    /// สองกลุ่มที่ถอดไม่ได้:
    /// - **สำรับสติกเกอร์** — ตัวหนังสือเป็นถ่านคงที่ที่จูนมาสำหรับกล่องขาว
    ///   ถอดกล่องบนการ์ดมืดเมื่อไหร่ตัวหนังสือหายไปทั้งใบ (ดู `Pop.ink`)
    /// - **ปกผลงาน** — พื้นของมันคือ *รูปที่ผู้ใช้อัปโหลด* ไม่ใช่กรอบ ถอดแล้วไม่เหลืออะไร
    var surfaceOptions: [WidgetSurface] {
        // สำรับสติกเกอร์ — ตัวหนังสือเป็นถ่านคงที่ที่จูนมาสำหรับกล่องขาว ถอดกล่องแล้วหายทั้งใบ
        if isPop { return [.glass, .dim] }
        // สำรับสแครปบุ๊ก — ใบที่มีกระดาษชมพูถามว่า "เอากระดาษไหม" · ใบที่เป็นวัตถุ (บัตร ป้าย พวงกุญแจ)
        // ไม่มีพื้นให้ถอด ตัววัตถุคือพื้นของมัน
        if isScrap { return scrapSheet ? [.glass, .pane, .clear] : [] }
        // แผ่นโชว์คลิป — แผ่นสีเข้มคือดีไซน์ของมัน ถอดออกแล้วเหลือหัวเรื่องกับเครื่องสี่เครื่อง
        // วางตรงบนการ์ด (ผู้ใช้ขอทั้งสองแบบ — ปุ่มเดียวในถาด ไม่ใช่สองใบในตู้)
        if self == .reelShowcase { return [.glass, .pane, .clear] }
        // โปสเตอร์พอร์ต — กระดาษของมันคือ *ดีไซน์* ไม่ใช่กรอบที่ chrome ครอบให้
        // คำถามเดียวที่เหลือจึงเป็น "เอากระดาษไหม" เหมือนสำรับบรรณาธิการ:
        // มีกระดาษ = โปสเตอร์ที่พิมพ์เสร็จแล้ว · ไม่มี = คำกับคนลอยอยู่บนการ์ดตรง ๆ
        if self == .artPortfolio { return [.glass, .pane, .clear] }
        // โปสเตอร์สายงาน — เหตุผลเดียวกัน: แผ่นสีเข้มคือดีไซน์ ไม่ใช่กรอบที่ chrome ครอบให้
        // (ผู้ใช้ขอทั้งสองแบบ — ปุ่มเดียวในถาด ไม่ใช่สองใบในตู้)
        if self == .nichePoster { return [.glass, .pane, .clear] }
        // โปสเตอร์ผู้ติดตาม — เหตุผลเดียวกัน (ผู้ใช้ขอทั้งสองแบบ: มีพื้นหลังและไม่มี)
        if self == .statPoster { return [.glass, .pane, .clear] }
        // ตรารับรอง — เหตุผลเดียวกัน: ถอดแผ่นแล้วเหรียญกับตัวอักษรนั่งบนการ์ดตรง ๆ
        if self == .proofSeal { return [.glass, .pane, .clear] }
        // โปสเตอร์อินไซต์ — เริ่มที่ไม่มีพื้น (ดู `defaultSurface`) แผ่นข้อมูลขาวอ่านออกบนทุกพื้น
        if self == .audiencePoster { return [.clear, .glass, .pane] }
        // โปสเตอร์ติดต่อ — แผ่นสีเรียบคือดีไซน์ · ถอดออกแล้วเหลือพาดหัว สามแถว และคน
        // นั่งบนการ์ดตรง ๆ หมึกพลิกตามธีมให้เอง (ผู้ใช้ขอทั้งสองแบบ)
        if self == .contactPoster { return [.glass, .pane, .clear] }
        // สำรับหน้าต่าง — คำถามเดียวคือ "หน้าต่างสว่างหรือมืด" (Aqua / Dark Mode) · ถอดกรอบไม่ได้
        // เพราะกรอบหน้าต่าง *คือ* ดีไซน์ ถอดแล้วเหลือแค่ตัวเลขลอย ๆ ที่มีใบอื่นในตระกูลทำอยู่แล้ว
        if isWindow { return [.glass, .dim] }
        if isEditorial {
            // ปกผลงาน — พื้นของมันคือรูปที่ผู้ใช้อัปโหลด ไม่ใช่กรอบ ไม่มีอะไรให้ถอด
            if self == .zineCover { return [] }
            // ที่เหลือ: "เข้ม" ไม่มีความหมาย (มันวาดกระดาษของตัวเอง) เหลือสามคำตอบ —
            // กระดาษของมัน · กระจกใบเดียวกับทั้งการ์ด · ไม่มีพื้นเลย
            return [.glass, .pane, .clear]
        }
        // ของที่วาดวัสดุของตัวเองแบบอื่น (ฟิล์ม · ป้ายไฟ · กระดาษอัดรูป) ไม่มีแถวนี้เหมือนเดิม —
        // วัสดุคือตัวงาน ไม่ใช่กรอบที่ถอดได้ ใส่ตัวเลือกให้ก็เป็นปุ่มที่กดแล้วไม่มีอะไรเกิดขึ้น
        if drawsOwnSurface { return [] }
        // ใบที่ chrome ครอบแผ่นให้อยู่แล้ว — `กระจก` ของมันคือ `.glass` ตัวเดิม
        // `.pane` เป็นของสำหรับใบที่วาดวัสดุเอง จึงไม่โผล่ในถาดของใบพวกนี้ (ปุ่มซ้ำ)
        return [.glass, .dim, .clear]
    }

    /// สำรับบรรณาธิการ — แปดใบที่แปลงมาจากแผ่นตัวอย่าง (ดู `EditorialWidgets.swift`)
    /// ทั้งสำรับอ่าน `\.widgetSurface` เองเพื่อตอบว่าจะวาดกระดาษรองไหม
    var isEditorial: Bool {
        switch self {
        case .wallPolaroid, .wallMemory, .zineCover, .aboutEditorial, .aboutBehind,
             .flowCards:
            return true
        default:
            return false
        }
    }

    /// ชื่อของตัวเลือกพื้นผิวบนถาด — ใบที่วาดกระดาษเองไม่ได้กำลังเลือก *วัสดุของแผ่น*
    /// แต่กำลังตอบว่า "เอากระดาษรองไหม" คำว่า "กระจก" ตรงนั้นจึงผิดความหมาย
    ///
    /// (`.pane` ยังชื่อ "กระจก" ตามเดิมทุกใบ — มันคือแผ่นกระจกจริงที่ chrome ครอบให้)
    func surfaceName(_ s: WidgetSurface) -> String {
        if isWindow { return s == .dim ? "มืด" : "สว่าง" }
        return drawsOwnPaper && s == .glass ? "มีพื้น" : s.name
    }

    /// สำรับหน้าต่าง macOS (ดู `WindowWidgets.swift`) — `.glass` = หน้าต่างสว่าง · `.dim` = มืด
    var isWindow: Bool { self == .socialWindow || self == .portfolioWindow }

    /// ใบที่โชว์ช่องทางเดียวแบบเต็มยศ — ถาดมีแถว "ช่องทาง" ให้เลือกช่อง (ดู `WindowChannel`)
    var picksChannel: Bool { self == .socialWindow || self == .socialGingham }

    /// ใบที่วาดกระดาษ/แผ่นพิมพ์ของตัวเอง **และถอดออกได้** — ถาดของมันถามว่า "เอาพื้นไหม"
    var drawsOwnPaper: Bool {
        isEditorial || self == .artPortfolio || self == .reelShowcase
            || self == .nichePoster || self == .contactPoster || self == .statPoster
            || self == .audiencePoster || self == .proofSeal
            || (isScrap && scrapSheet)
    }

    /// สำรับสมุดสแครปบุ๊ก (ดู `ScrapbookWidgets.swift`)
    var isScrap: Bool { scrapDesign != nil }
    /// ใบในสำรับสแครปบุ๊กที่วาดกระดาษชมพูของตัวเอง — ที่เหลือเป็นวัตถุลอย (บัตร ป้าย พวงกุญแจ ตรายาง)
    var scrapSheet: Bool {
        switch self {
        case .scrapFolder, .scrapFeed, .scrapTags, .scrapAbout, .scrapReceipt, .scrapStats,
             .scrapPhones, .scrapChat, .scrapNote: return true
        default: return false
        }
    }
    /// ขนาดผังของใบในสำรับสแครปบุ๊ก — nil = ไม่ใช่ใบของสำรับนี้
    var scrapDesign: CGSize? {
        switch self {
        case .scrapFolder: return ScrapSize.folder
        case .scrapBadge: return ScrapSize.badge
        case .scrapKeyTab: return ScrapSize.keyTab
        case .scrapFeed: return ScrapSize.feed
        case .scrapTags: return ScrapSize.tags
        case .scrapAbout: return ScrapSize.about
        case .scrapInfo: return ScrapSize.info
        case .scrapReceipt: return ScrapSize.receipt
        case .scrapStats: return ScrapSize.stats
        case .scrapStamp: return ScrapSize.stamp
        case .scrapPhones: return ScrapSize.phones
        case .scrapChat: return ScrapSize.chat
        case .scrapNote: return ScrapSize.note
        case .scrapLabel: return ScrapSize.label
        default: return nil
        }
    }
    /// เส้นขอบเป็นของ "แผ่นข้อมูล" เท่านั้น — ของที่วาดวัสดุเองมีขอบของตัวมันอยู่แล้ว
    var defaultBorder: Bool { isPop ? false : !drawsOwnSurface }
}

// MARK: - พื้นผิวของชิ้นที่กำลังวาด (ส่งลงทาง environment)

private struct WidgetSurfaceKey: EnvironmentKey {
    static let defaultValue = WidgetSurface.glass
}
private struct WidgetPatternKey: EnvironmentKey {
    static let defaultValue = PlatePattern.plain
}
private struct WidgetEmbossKey: EnvironmentKey {
    static let defaultValue = true
}
private struct WidgetSealStyleKey: EnvironmentKey {
    static let defaultValue = SealStyle.medal
}
private struct WidgetEmbossBlindKey: EnvironmentKey {
    static let defaultValue = false
}
private struct WidgetLiftsPhotoKey: EnvironmentKey {
    static let defaultValue = false
}
private struct WidgetBorderKey: EnvironmentKey {
    static let defaultValue = false
}
/// วัสดุของแผ่นสติกเกอร์ — `nil` แปลว่าไม่ได้วาดจากชนิดใดชนิดหนึ่ง (พรีวิวใน Xcode)
private struct PopSkinKey: EnvironmentKey {
    static let defaultValue: PopSkin? = nil
}

extension EnvironmentValues {
    /// พื้นผิวที่ผู้ใช้เลือกให้ชิ้นนี้ — widget ที่วาดแผ่นเองอ่านค่านี้แทนที่จะให้ `WidgetChrome` ครอบ
    var widgetSurface: WidgetSurface {
        get { self[WidgetSurfaceKey.self] }
        set { self[WidgetSurfaceKey.self] = newValue }
    }
    var widgetPattern: PlatePattern {
        get { self[WidgetPatternKey.self] }
        set { self[WidgetPatternKey.self] = newValue }
    }
    /// ชิ้นนี้ลบพื้นหลังรูปคนให้เองไหม — ดู `WidgetKind.liftsSubject`
    var widgetLiftsPhoto: Bool {
        get { self[WidgetLiftsPhotoKey.self] }
        set { self[WidgetLiftsPhotoKey.self] = newValue }
    }
    /// ใบนี้ปั๊มตรานูนไหม — ดู `WidgetKind.takesEmboss` (ตั้งต้นเปิด พรีวิวในตู้จึงเห็นตราด้วย)
    var widgetEmboss: Bool {
        get { self[WidgetEmbossKey.self] }
        set { self[WidgetEmbossKey.self] = newValue }
    }
    /// ตราของใบนี้เป็นปั๊มนูนเปล่า (false = ตราพิมพ์ด้วยหมึกของแผ่น)
    var widgetEmbossBlind: Bool {
        get { self[WidgetEmbossBlindKey.self] }
        set { self[WidgetEmbossBlindKey.self] = newValue }
    }
    /// หน้าตาของตรารับรองใบนี้ — ดู `SealStyle`
    var widgetSealStyle: SealStyle {
        get { self[WidgetSealStyleKey.self] }
        set { self[WidgetSealStyleKey.self] = newValue }
    }
    var widgetBorder: Bool {
        get { self[WidgetBorderKey.self] }
        set { self[WidgetBorderKey.self] = newValue }
    }
    /// วัสดุที่ชนิดของชิ้นสั่งมา — ชิ้นส่วนร่วมของสำรับสติกเกอร์อยู่ลึกหลายชั้น
    /// ส่งทาง environment จึงถึงทุกตัวโดยไม่ต้องไล่เติมพารามิเตอร์ทั้งไฟล์
    var popSkin: PopSkin? {
        get { self[PopSkinKey.self] }
        set { self[PopSkinKey.self] = newValue }
    }
}


// MARK: - Plate pattern

/// ลายบนแผ่นทึบของ widget — เรียบ · ลายทาง · ข้าวหลามตัด
enum PlatePattern: String, CaseIterable, Identifiable {
    case plain, stripe, diamond
    var id: String { rawValue }

    var name: String {
        switch self {
        case .plain:   return "เรียบ"
        case .stripe:  return "ลายทาง"
        case .diamond: return "ข้าวหลามตัด"
        }
    }
}

// MARK: - Surface

/// พื้นผิวของ widget — ผู้ใช้เลือกทับค่าตั้งต้นของชนิดได้ทุกตัว
///
/// มีสองแบบเท่านั้น และ **ไม่มีแบบ "ไม่มีพื้น"** ตั้งใจ: ชิ้นที่ไม่มีพื้นจะลอยหายไปกับการ์ด
/// จนอ่านไม่ออกว่าตรงไหนคือชิ้นเดียวกัน (และบนพื้นหลังรูป ตัวหนังสือก็จมหายไปเลย)
/// ของเดิมมี `จาง` กับ `โปร่ง` ด้วย — จางอ่อนเกินกว่าจะเป็นพื้นจริง ส่วนโปร่งคือ "ไม่มีพื้น"
/// ทั้งคู่ถูกยุบมาเป็นกระจก (ดู `decode`) การ์ดเก่าจึงเปิดแล้วได้พื้นครบทุกชิ้นทันที
enum WidgetSurface: String, CaseIterable, Identifiable {
    case glass   // liquid glass
    case dim     // แผ่นเข้มทึบ
    /// **ไม่มีพื้นเลย** — เนื้อหานั่งบนการ์ดตรง ๆ ไม่มีแผ่น ไม่มีกระดาษ ไม่มีเงา
    ///
    /// กติกาเดิมของการ์ดคือ "ทุกชิ้นต้องมีพื้น" เพราะของที่ลอยอยู่บนการ์ดเปล่าอ่านไม่ออกว่า
    /// เป็นชิ้นเดียวกันหรือคนละชิ้น — ซึ่งจริงสำหรับ *แผ่นข้อมูล* ที่วางติดกันหลายใบ
    ///
    /// แต่มันไม่จริงสำหรับใบที่เป็น **ภาพทั้งใบ**: กองโพลารอยด์ · ประโยคตัวใหญ่ · การ์ดขั้นตอน
    /// สามอย่างนี้มีรูปทรงของตัวเองอยู่แล้ว กระดาษที่รองอยู่ข้างหลังจึงกลายเป็น *กรอบ*
    /// ที่ตัดมันออกจากการ์ด แทนที่จะช่วยให้มันเป็นส่วนหนึ่งของการ์ด
    ///
    /// ตัวที่เลือกได้อยู่ที่ `WidgetKind.surfaceOptions` — ไม่ใช่ทุกใบที่ถอดพื้นแล้วยังอ่านออก
    case clear

    /// **กระจกของ chrome บนใบที่วาดวัสดุเอง** — กระดาษ/แผ่นพิมพ์ของมันถูกถอดออก
    /// แล้วเอาเนื้อหาไปวางบนแผ่นกระจกใบเดียวกับที่ widget ตัวอื่นทั้งการ์ดใช้อยู่
    ///
    /// ทำไมต้องมีแบบที่สาม: สำรับที่วาดวัสดุเองเคยมีคำถามเดียวคือ "เอาแผ่นของมันไหม"
    /// ตอบว่าไม่ แล้วเนื้อหาไปนั่งบนการ์ดเปล่า ๆ ซึ่งคือคนละเรื่องกับ "อยากได้ของชิ้นนี้
    /// ให้เข้าชุดกับใบอื่นบนหน้าเดียวกัน" — ใบอื่นทั้งหน้าเป็นกระจก ใบนี้จึงต้องเป็นกระจกได้ด้วย
    ///
    /// ตอนวาด ตัวนี้ถูกแปลงเป็นสองอย่างพร้อมกัน (ดู `WidgetChrome`): chrome ครอบกระจกให้
    /// ส่วน widget ได้รับค่า `.clear` ลงไป — มันจึงไม่วาดแผ่นของตัวเองและพลิกหมึกตามการ์ดให้เอง
    /// โดยไม่ต้องรู้จักพื้นผิวแบบนี้เลยสักใบ
    case pane

    var id: String { rawValue }

    var name: String {
        switch self {
        case .glass: return "กระจก"
        case .dim:   return "เข้ม"
        case .clear: return "ไม่มีพื้น"
        case .pane:  return "กระจก"
        }
    }

    /// อ่านค่าจากไฟล์ — ชื่อที่เลิกใช้แล้ว (`faint`/`plain`) ตกมาเป็นกระจก ไม่ใช่ค่าว่าง
    static func decode(_ raw: String) -> WidgetSurface {
        WidgetSurface(rawValue: raw) ?? .glass
    }
}

// MARK: - Instance

struct WidgetInstance: Identifiable, Equatable {
    let id: UUID
    var kind: WidgetKind
    /// มุมบนซ้ายของกรอบ — **หน่วย pt บนพื้นที่ออกแบบ** อ้างมุมบนซ้ายของหน้า
    ///
    /// เป็นพิกัดที่ผู้ใช้ *ขอ* ไม่ใช่พิกัดที่ได้จริง — `PageLayout.solve` เป็นคนตัดสินตอนวาด
    /// และจะ **ดันตัวที่ไปตกทับของที่วางไว้ก่อนลงจนมีที่ว่าง** (ของทับกันไม่ได้บนหน้ากระดาษ)
    /// ค่าที่ถูกดันไม่ถูกเขียนกลับมาที่นี่ ย้ายตัวที่ขวางออกเมื่อไหร่ของก็เด้งกลับขึ้นที่เดิมเอง
    ///
    /// ลำดับใน `CardPage.items` คือลำดับ "ใครได้ที่ก่อน" เวลาสองตัวขอที่เดียวกัน
    var x: CGFloat
    var y: CGFloat
    var w: CGFloat
    var h: CGFloat

    /// กรอบที่ตัวนี้ *ขอ* — ยังไม่ผ่านการรูดเข้าหน้าและการดันไม่ให้ทับกัน
    var rect: CGRect {
        get { CGRect(x: x, y: y, width: w, height: h) }
        set { x = newValue.minX; y = newValue.minY; w = newValue.width; h = newValue.height }
    }
    /// พื้นผิว — ตั้งต้นตามบุคลิกของชนิด (typography โปร่ง · แผ่นข้อมูลกระจก)
    var surface: WidgetSurface
    /// เส้นขอบรอบ widget — แยกจากพื้นผิว เพราะบางทีอยากได้กรอบโดยไม่เอาพื้น
    /// (พื้นโปร่ง + มีขอบ = การ์ดเส้นขอบล้วน ซึ่งเป็นอีกหน้าตาหนึ่ง)
    var border: Bool
    /// ลายบนแผ่นทึบ — เลือกรายชิ้นในถาด (ดู `WidgetKind.takesPattern`)
    var pattern: PlatePattern = .plain
    /// ลบพื้นหลังรูปคนให้อัตโนมัติ — มีผลเฉพาะ `kind.liftsSubject` · ตั้งต้นเปิด
    var liftPhoto = true
    /// ตรา Sale Here STAR บนแผ่นของใบนี้ — มีผลเฉพาะ `kind.takesEmboss` · ตั้งต้นเปิด
    var emboss = true
    /// ปั๊มนูนเปล่าแทนตราพิมพ์ — ตั้งต้นเป็นตราพิมพ์ด้วยหมึกของแผ่น เพราะตรานูนสีเดียวกับแผ่นมองจากภาพรวมไม่เห็น
    var embossBlind = false
    /// ชิ้นที่ Sale Here วางให้และ **ตรึงไว้กับก้นหน้า** — ลบ ย้าย ยืด สลับแบบไม่ได้ (ดู `PinnedSeal`)
    ///
    /// ผังให้ที่มันก่อนใคร และ `y` ที่ถือไว้ไม่ถูกใช้: ก้นหน้าของพอร์ตสูงไม่เท่ากันทุกเครื่อง
    /// ตำแหน่งจึงคิดจากก้นหน้าตอนวาดทุกครั้ง (ดู `PageLayout.pinnedFrame`)
    var pinned = false
    /// หน้าตาของตรารับรอง — มีผลเฉพาะ `proofSeal` (ดู `SealStyle`) · เลือกรายชิ้นในถาด
    var sealStyle = SealStyle.medal
    /// หน้าตาตัวอักษร — ฟอนต์ · สี · ขนาด · การจัดวาง
    ///
    /// อยู่ที่ชิ้น ไม่ใช่ที่ตระกูล ด้วยเหตุผลเดียวกับ `surface`/`border`: มันคือ *หน้าตา* ไม่ใช่ *เนื้อหา*
    /// ตอนนี้มีแค่ `textBlock` ที่อ่านค่านี้ (ดู `CardFont`) ตัวอื่นถือไว้เฉย ๆ โดยไม่มีผล
    var textStyle = WidgetTextStyle()

    /// `id` ส่งเข้ามาได้เฉพาะตอนกู้จากไฟล์ — ข้อความกับรูปของก้อนผูกกับ id นี้ (ดู `Profile.note`,
    /// `PhotoStore.perWidget`) ถ้าสุ่มใหม่ทุกครั้งที่เปิดแอป ของที่พิมพ์ไว้จะหายทั้งที่ยังอยู่ในไฟล์
    ///
    /// ไม่ระบุ `h` = ได้ความสูงตาม **สัดส่วนที่ออกแบบไว้** ของความกว้างนั้น ไม่ใช่ความสูงตั้งต้นดิบ ๆ
    /// (ผังในเทมเพลตจึงเขียนแค่ x/y/w แล้วได้ชิ้นที่สัดส่วนถูกต้องเสมอ — ยืดทีหลังได้ตามใจ)
    init(_ kind: WidgetKind, x: CGFloat = PageLayout.margin, y: CGFloat = PageLayout.margin,
         w: CGFloat? = nil, h: CGFloat? = nil, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        self.x = x
        self.y = y
        let width = w ?? kind.defaultSize.width
        self.w = width
        self.h = h ?? kind.height(forWidth: width)
        self.surface = kind.defaultSurface
        self.border = kind.defaultBorder
    }

    /// ย่อ/ขยาย **ทั้งชิ้นตามสัดส่วนที่เป็นอยู่** — หมุดมุมใช้ตัวนี้
    ///
    /// ใช้สัดส่วนปัจจุบันของชิ้น ไม่ใช่สัดส่วนของชนิด: ชิ้นที่ผู้ใช้ยืดเป็นแถบเตี้ยไว้แล้ว
    /// พอลากมุมต่อ ต้องได้แถบเตี้ยที่ใหญ่ขึ้น ไม่ใช่เด้งกลับไปเป็นสัดส่วนตั้งต้น
    mutating func scale(toWidth width: CGFloat) {
        let ratio = h / max(w, 1)
        w = width
        h = max(1, (width * ratio).rounded())
    }

    /// คืนความสูงให้ตรงสัดส่วนที่ออกแบบไว้ — ใช้ตอนสลับแบบ (แบบใหม่มีผังของตัวเอง)
    mutating func resetAspect() { h = kind.height(forWidth: w) }

    /// สเกลของชิ้นเทียบกับผังที่ออกแบบไว้ — 1 = ขนาดจริง
    var scale: CGFloat { w / max(kind.defaultSize.width, 1) }

    // ใช้ == ที่สังเคราะห์ให้ (เทียบทุก field รวม kind)
    // ตัวเดิมที่เขียนเองข้าม kind ไป — สลับแบบในหมวดเดียวกันที่ขนาดเท่ากันแล้ว
    // onChange(of: pages) เลยไม่ยิง การ์ดไม่วาดใหม่ กดเปลี่ยนแบบแล้วเหมือนไม่ติด
}

// MARK: - Catalog entry

/// รายการใน Widget Gallery — "ตู้รางวัล"
struct CatalogEntry: Identifiable {
    let id: String
    let kind: WidgetKind
    let unlocked: Bool
    /// เงื่อนไขที่ต้องทำเพื่อปลดล็อก — nil เมื่อปลดล็อกแล้ว
    let requirement: String?

    init(kind: WidgetKind, unlocked: Bool = true, requirement: String? = nil) {
        self.id = kind.rawValue + (unlocked ? "" : "-locked")
        self.kind = kind
        self.unlocked = unlocked
        self.requirement = requirement
    }
}
