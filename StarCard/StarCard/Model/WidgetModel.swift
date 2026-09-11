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
    case hero, intro, text, followers, audience, tags, brand, verified,
         photo, words, rate, contact

    var label: String {
        switch self {
        case .hero:      return "โปรไฟล์"
        case .intro:     return "แนะนำตัว"
        case .brand:     return "แบรนด์"
        case .verified:  return "ผลงานยืนยัน"
        case .followers: return "ผู้ติดตาม"
        case .photo:     return "รูปผลงาน"
        case .words:     return "ถ้อยคำ"
        case .text:      return "ข้อความ"
        case .tags:      return "หมวดหมู่"
        case .audience:  return "ผู้ชม"
        case .rate:      return "เรตราคา"
        case .contact:   return "ติดต่อ"
        }
    }
}

// MARK: - Kind

enum WidgetKind: String, CaseIterable, Identifiable {
    // โปรไฟล์
    case artPortrait, artTypeOver, artPolaroid, heroMinimal, heroAura
    // เกี่ยวกับฉัน
    case aboutText, aboutNote, interestTags
    // หลักฐาน — โลโก้แบรนด์
    case proofBrands, proofBrandWall, proofBrandGrid, proofBrandRail, proofBrandList
    // หลักฐาน — ผลงานยืนยัน ห้าหน้าตาของเรื่องเดียวกัน
    //
    // ทั้งชั้นนี้ **รูปคือตัวนำ** ไม่ใช่ตัวประกอบ เคยมีอีกสี่แบบที่เป็นตาราง/ใบเสร็จ/แถวรายการ
    // (กระดานคะแนน · ใบเสร็จ · เพลย์ลิสต์ · ป้ายโลหะ) แต่วัดแล้วรูปกินพื้นที่ 0–5%
    // มันคือเครื่องมืออ่านข้อมูล ไม่ใช่ผลงาน — ถอดออกทั้งหมด
    // เรียงจากรูปน้อยไปรูปมาก — ลำดับนี้คือลำดับที่โผล่ในตู้
    case proofWork, proofTicket, proofHolo, proofZine, proofShelf
    // ผู้ติดตาม
    case statGiant, socialChips, socialTiles, statWrapped
    // ผลงาน
    case artFilmstrip, artDuo, artPair, workFeatured, workReel, artPhotobooth
    // ผลงาน — สำรับ "กองรูป" แปดสถานการณ์ (ดู `GalleryWidgets.swift`)
    // เรียงตามความหนาแน่นของรูป: กองน้อย → กองเยอะ → กรอบแพลตฟอร์ม → วัสดุ
    case galleryStack, galleryCarousel, galleryMasonry, galleryMosaic,
         galleryPost, galleryStory, galleryFilm, galleryTape
    // เนื้อหา
    case typeMarquee, typeQuote, nicheTags, stickerTags
    // ข้อความล้วน — ตัวเดียวในตู้ที่ *ไม่มีเนื้อหาของตัวเอง* นอกจากที่เจ้าของการ์ดพิมพ์ลงไป
    case textBlock
    // เรตราคา — สเปกหมวด 5.1 ที่ตู้เดิมไม่มีเลย · หกหน้าตาของราคาชุดเดียวกัน
    // สองตัวแรกเป็น "เอกสาร" (เมนู · ป้ายห้อย) · สี่ตัวหลังเป็นสำรับศิลป์
    // ที่ทำให้การ์ดสายดีไซน์มีเรตที่เข้ากับหน้าตัวเอง (ดู `RateArtWidgets.swift`)
    case rateMenu, rateTags, rateReceipt, rateNeon, rateStamp, rateBlock
    // ช่องทางติดต่อ — สเปก 1.3
    case contactCard, contactQR,
         // สี่แบบมินิมอล — บรรทัดเดียว · สามบรรทัด · ไลน์ตัวใหญ่ · ชิป
         contactBar, contactStack, contactLine, contactChips
    // ประชากรผู้ติดตาม — สเปก 2.3
    case audienceLine, audienceSplit, audienceAge, audienceMap

    var id: String { rawValue }

    /// หมวดใน gallery
    /// ตัวเลขผู้ติดตามอยู่ "เกี่ยวกับฉัน" เพราะมันคือขนาดของตัวเรา ไม่ใช่งานที่เคยทำ
    /// ส่วนแถบวิ่งโชว์ชื่อแบรนด์ที่ร่วมงาน จึงเป็นผลงาน ไม่ใช่ของตกแต่ง
    var group: WidgetGroup {
        switch self {
        case .artPortrait, .artTypeOver, .artPolaroid, .heroMinimal, .heroAura,
             .aboutText, .aboutNote, .statGiant, .socialChips, .socialTiles, .statWrapped,
             .nicheTags, .stickerTags, .interestTags, .typeQuote, .textBlock,
             // ประชากรผู้ติดตามคือ "หน้าตาของคนที่ตามเรา" จึงอยู่หมวดเดียวกับยอดฟอลโลว์
             .audienceLine, .audienceSplit, .audienceAge, .audienceMap:
            return .about
        // ทุกอย่างที่ตอบคำถาม "จ้างยังไง เท่าไหร่ ติดต่อใคร"
        case .rateMenu, .rateTags, .rateReceipt, .rateNeon, .rateStamp, .rateBlock,
             .contactCard, .contactQR,
             .contactBar, .contactStack, .contactLine, .contactChips:
            return .booking
        case .proofBrands, .proofBrandWall, .proofBrandGrid, .proofBrandRail, .proofBrandList,
             .proofWork, .proofTicket, .proofHolo, .proofShelf, .proofZine, .typeMarquee,
             .artFilmstrip, .artDuo, .artPair, .workFeatured, .workReel, .artPhotobooth,
             .galleryStack, .galleryCarousel, .galleryMasonry, .galleryMosaic,
             .galleryPost, .galleryStory, .galleryFilm, .galleryTape:
            return .work
        }
    }

    /// ตระกูล — ใช้หา "แบบอื่น" ที่สลับกันแล้วยังเล่าเรื่องเดิม
    var family: WidgetFamily {
        switch self {
        case .artPortrait, .artTypeOver, .artPolaroid, .heroMinimal, .heroAura: return .hero
        case .aboutText, .aboutNote: return .intro
        case .proofBrands, .proofBrandWall, .proofBrandGrid, .proofBrandRail,
             .proofBrandList, .typeMarquee: return .brand
        case .proofWork, .proofTicket, .proofHolo, .proofShelf, .proofZine: return .verified
        case .statGiant, .socialChips, .socialTiles, .statWrapped: return .followers
        case .artFilmstrip, .artDuo, .artPair, .workFeatured, .workReel, .artPhotobooth,
             .galleryStack, .galleryCarousel, .galleryMasonry, .galleryMosaic,
             .galleryPost, .galleryStory, .galleryFilm, .galleryTape: return .photo
        case .typeQuote: return .words
        case .textBlock: return .text
        // สายงาน (พิมพ์เอง) กับ หมวดหมู่ (ของแพลตฟอร์ม) สลับกันได้ — เล่าเรื่องเดียวกัน
        case .nicheTags, .stickerTags, .interestTags: return .tags
        case .rateMenu, .rateTags, .rateReceipt, .rateNeon, .rateStamp, .rateBlock: return .rate
        case .contactCard, .contactQR,
             .contactBar, .contactStack, .contactLine, .contactChips: return .contact
        case .audienceLine, .audienceSplit, .audienceAge, .audienceMap: return .audience
        }
    }

    /// ชั้นสิทธิ์ — ผูกกับที่มาของข้อมูล ไม่ใช่หมวดใน gallery
    /// (หมวดเหลือสามหมวดหยาบ ๆ แล้ว ใช้แทนกันไม่ได้อีก)
    var tier: WidgetTier {
        switch self {
        case .proofBrands, .proofBrandWall, .proofBrandGrid, .proofBrandRail, .proofBrandList,
             .proofWork, .proofTicket, .proofHolo, .proofShelf, .proofZine:
            return .verified                       // แพลตฟอร์มออกให้จากงานที่ส่งจริง
        case .statGiant, .socialChips, .socialTiles, .statWrapped,
             .interestTags,
             // สถิติผู้ชมมาจาก OAuth · เรตมีราคาที่ระบบแนะนำกำกับ
             .audienceLine, .audienceSplit, .audienceAge, .audienceMap,
             .rateMenu, .rateTags, .rateReceipt, .rateNeon, .rateStamp, .rateBlock:
            return .connected                      // ยอด OAuth · ราคาที่ระบบแนะนำ · ตั้งค่าจากโปรไฟล์
        default:
            return .personal
        }
    }

    /// widget ที่ไม่ต้องครอบกรอบกระจก — วาดพื้นหลังของตัวเอง หรือเป็น typography/ชิปที่ผิวของมันพอแล้ว
    /// ถ้าครอบทุกอันการ์ดจะกลายเป็นตารางสี่เหลี่ยมมนเรียงกันทั้งหน้า ซึ่งอ่านออกมาเป็น dashboard ไม่ใช่งานพอร์ต
    /// กรอบเหลือไว้เฉพาะ "แผ่นข้อมูล" ที่ต้องเก็บทรง: ตารางเวลา · กริดหลักฐาน · รูป full-bleed
    var isPlain: Bool {
        switch self {
        case .artPortrait, .artTypeOver, .artPolaroid, .artFilmstrip, .artDuo, .artPair,
             .typeMarquee, .typeQuote, .statGiant,
             // ข้อความล้วน — ตัวมันเองคือตัวอักษร ครอบกระจกแล้วกลายเป็นป้ายแทนที่จะเป็นข้อความ
             .textBlock,
             // text/ชิปลอยบนการ์ด — ครอบกระจกซ้ำแล้วอ่านเป็นกล่องซ้อนกล่อง
             .heroMinimal, .aboutText, .proofBrandList, .nicheTags, .socialChips, .socialTiles,
             // โลโก้ไหลบนการ์ดแบบเดียวกับแถบวิ่ง
             .proofBrandRail,
             // ผลงานยืนยันแบบใหม่ — ทุกตัววาดพื้นผิวของตัวเอง (กระดาษตั๋ว · ฟอยล์ · กระดานปะ · โปสเตอร์)
             // ครอบกระจกทับแล้วจะได้กล่องซ้อนกล่อง และพื้นกระดาษจะสู้กับพื้นกระจกจนสีเพี้ยน
             .proofTicket, .proofHolo, .proofShelf, .proofZine,
             // สำรับ Gen Z — วัสดุของแต่ละตัวคือพื้นผิวของมันเอง (แสง · กระดาษโน้ต ·
             // บล็อกสีทึบ · กระดาษภาพ · ฟองแชต · สติกเกอร์) ครอบกระจกแล้วจะสู้กันทั้งชุด
             .heroAura, .aboutNote, .statWrapped, .artPhotobooth, .stickerTags,
             // สำรับรอบสอง — บัตรกระดาษ · โปสเตอร์ · สติกเกอร์ ที่วาดพื้นผิวของตัวเอง
             // บัตรกระดาษที่วาดพื้นผิวของตัวเอง · ตัวหนังสือล้วนที่ผิวของมันพอแล้ว
             .contactQR, .audienceLine,
             // ป้ายราคาเป็นกระดาษแข็งที่มีเงาของตัวเอง — ครอบกระจกแล้วได้กล่องซ้อนกล่อง
             .rateTags,
             // สำรับเรตแบบศิลป์ — ทั้งสี่วาดวัสดุของตัวเอง (กระดาษใบเสร็จ · แผ่นป้ายไฟ ·
             // กระดาษหนา · บล็อกสีทึบ) กระจกที่ครอบทับจะสู้กับพื้นวัสดุจนสีเพี้ยน
             .rateReceipt, .rateNeon, .rateStamp, .rateBlock,
             // สี่แบบมินิมอลของช่องทางติดต่อ — ตัวหนังสือกับชิปลอยบนการ์ด ไม่ต้องมีกรอบ
             .contactBar, .contactStack, .contactLine, .contactChips,
             // สำรับกองรูป — กระเบื้องรูปลอยบนการ์ด (บอร์ดพิน · โมเสก · สไลด์)
             // และของที่วาดวัสดุของตัวเอง (กระดาษอัดรูป · ฟิล์ม · เทปกาว)
             // ครอบกระจกทับแล้วได้กล่องซ้อนกล่อง และพื้นวัสดุจะสู้กับพื้นกระจกจนสีเพี้ยน
             // ยกเว้น `โพสต์` กับ `สตอรี่` — สองตัวนั้นคือ *กรอบของแพลตฟอร์ม* กระจกคือกรอบนั้น
             .galleryStack, .galleryCarousel, .galleryMasonry, .galleryMosaic,
             .galleryFilm, .galleryTape:
            return true
        default:
            return false
        }
    }

    /// widget ที่อ่าน `WidgetInstance.textStyle` — แผงของมันจะมีเรื่องฟอนต์/สี/ขนาด/จัดวางเพิ่ม
    ///
    /// เปิดเฉพาะตัวที่ **ทั้งใบเป็นตัวอักษรที่ผู้ใช้พิมพ์เอง** เท่านั้น
    /// ตัวอื่นหน้าตาถูกออกแบบมาแล้วเป็นชุด — เปิดให้เปลี่ยนฟอนต์ทีละก้อนเมื่อไหร่
    /// การ์ดจะกลายเป็นเอกสารที่มีสิบฟอนต์ ซึ่งเป็นสิ่งที่ตู้ทั้งตู้พยายามกันไม่ให้เกิด
    var usesTextStyle: Bool { self == .textBlock }

    /// widget ที่แสดงรูปครีเอเตอร์หรือรูปผลงาน — เปิดให้อัปโหลดรูปของตัวเองทับรูปตั้งต้นได้
    var usesPhoto: Bool {
        switch self {
        case .artPortrait, .artTypeOver, .artPolaroid, .statGiant, .typeQuote,
             .artFilmstrip, .artDuo, .artPair, .workFeatured, .workReel, .proofWork,
             .heroAura, .artPhotobooth,
             // ชั้นหลักฐานตอนนี้ใช้รูปทุกตัว — ตัวที่ไม่ใช้ถูกถอดออกไปแล้ว
             .proofTicket, .proofHolo, .proofShelf, .proofZine,
             // สำรับกองรูปใช้รูปทั้งแปดตัว — มันคือทั้งหมดที่ตระกูลนี้มี
             .galleryStack, .galleryCarousel, .galleryMasonry, .galleryMosaic,
             .galleryPost, .galleryStory, .galleryFilm, .galleryTape:
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
        case .artPortrait: return "ปกนิตยสาร"
        case .artTypeOver: return "ตัวอักษรทับภาพ"
        case .artPolaroid: return "โพลารอยด์"
        case .heroMinimal: return "ชื่อมินิมอล"
        case .heroAura: return "ออร่า"
        case .aboutText: return "แนะนำตัว"
        case .aboutNote: return "โน้ตแปะ"
        case .interestTags: return "หมวดหมู่ที่สนใจ"
        case .proofBrands: return "โลโก้แบรนด์"
        case .proofBrandWall: return "กำแพงโลโก้"
        case .proofBrandGrid: return "แผงโลโก้ครบ"
        case .proofBrandRail: return "โลโก้เลื่อน"
        case .proofBrandList: return "รายชื่อแบรนด์"
        case .proofWork: return "ผลงานที่ยืนยันแล้ว"
        case .proofTicket: return "ตั๋วผลงาน"
        case .proofHolo: return "การ์ดสะสม"
        case .proofShelf: return "ปกซีรีส์"
        case .proofZine: return "ตัดแปะ"
        case .statGiant: return "ตัวเลขยักษ์"
        case .socialChips: return "ผู้ติดตามแบบแถว"
        case .socialTiles: return "ผู้ติดตามแบบชิป"
        case .statWrapped: return "การ์ดสรุปยอด"
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
        case .typeMarquee: return "แถบวิ่ง"
        case .typeQuote: return "คำพูดตัวใหญ่"
        case .textBlock: return "ข้อความ"
        case .nicheTags: return "สายงาน"
        case .rateMenu: return "เมนูราคา"
        case .rateTags: return "ป้ายราคา"
        case .rateReceipt: return "ใบเสร็จ"
        case .rateNeon: return "ป้ายไฟ"
        case .rateStamp: return "ตราประทับ"
        case .rateBlock: return "บล็อกราคา"
        case .contactCard: return "นามบัตร"
        case .contactQR: return "คิวอาร์การ์ด"
        case .contactBar: return "แถบติดต่อ"
        case .contactStack: return "สามบรรทัด"
        case .contactLine: return "ไลน์ตัวใหญ่"
        case .contactChips: return "ชิปช่องทาง"
        case .audienceLine: return "ประโยคเดียว"
        case .audienceSplit: return "สัดส่วนผู้ชม"
        case .audienceAge: return "ช่วงอายุผู้ชม"
        case .audienceMap: return "ผู้ชมในประเทศ"
        }
    }

    var symbol: String {
        switch self {
        case .artPortrait: return "person.crop.rectangle.stack.fill"
        case .artTypeOver: return "textformat.alt"
        case .artPolaroid: return "photo.artframe"
        case .heroMinimal: return "textformat"
        case .heroAura: return "sparkles"
        case .aboutText: return "text.alignleft"
        case .aboutNote: return "note.text"
        case .interestTags: return "heart.text.square.fill"
        case .proofBrands: return "building.2.fill"
        case .proofBrandWall: return "square.grid.3x2.fill"
        case .proofBrandGrid: return "square.grid.3x3.fill"
        case .proofBrandRail: return "arrow.left.arrow.right"
        case .proofBrandList: return "text.justify.leading"
        case .proofWork: return "checkmark.seal.fill"
        case .proofTicket: return "ticket.fill"
        case .proofHolo: return "rectangle.stack.fill"
        case .proofShelf: return "film.stack.fill"
        case .proofZine: return "scissors"
        case .statGiant: return "number.circle.fill"
        case .socialChips: return "list.bullet.rectangle.fill"
        case .socialTiles: return "circle.grid.3x1.fill"
        case .statWrapped: return "list.number"
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
        case .typeMarquee: return "text.line.first.and.arrowtriangle.forward"
        case .typeQuote: return "quote.bubble.fill"
        case .textBlock: return "textformat.size"
        case .nicheTags: return "tag"
        case .rateMenu: return "list.bullet.rectangle.portrait.fill"
        case .rateTags: return "tag.fill"
        case .rateReceipt: return "doc.plaintext.fill"
        case .rateNeon: return "lightbulb.fill"
        case .rateStamp: return "signature"
        case .rateBlock: return "rectangle.split.1x2.fill"
        case .contactCard: return "person.text.rectangle.fill"
        case .contactQR: return "qrcode"
        case .contactBar: return "text.append"
        case .contactStack: return "list.bullet"
        case .contactLine: return "bubble.left.fill"
        case .contactChips: return "capsule.portrait.fill"
        case .audienceLine: return "text.alignleft"
        case .audienceSplit: return "person.2.fill"
        case .audienceAge: return "chart.bar.fill"
        case .audienceMap: return "mappin.and.ellipse"
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
        case .artPortrait:     return CGSize(width: 366, height: 420)
        case .artTypeOver:     return CGSize(width: 366, height: 367)
        case .artPolaroid:     return CGSize(width: 179, height: 206)
        case .heroMinimal:     return CGSize(width: 366, height: 135)
        case .heroAura:        return CGSize(width: 366, height: 384)
        case .aboutText:       return CGSize(width: 366, height: 135)
        case .aboutNote:       return CGSize(width: 366, height: 153)
        case .interestTags:    return CGSize(width: 366, height: 117)
        case .proofBrands:     return CGSize(width: 366, height: 99)
        case .proofBrandWall:  return CGSize(width: 366, height: 206)
        case .proofBrandGrid:  return CGSize(width: 366, height: 206)
        case .proofBrandRail:  return CGSize(width: 366, height: 81)
        case .proofBrandList:  return CGSize(width: 366, height: 117)
        case .proofWork:       return CGSize(width: 366, height: 295)
        case .proofTicket:     return CGSize(width: 366, height: 260)
        case .proofHolo:       return CGSize(width: 366, height: 242)
        case .proofShelf:      return CGSize(width: 366, height: 260)
        case .proofZine:       return CGSize(width: 366, height: 242)
        case .statGiant:       return CGSize(width: 366, height: 206)
        case .socialChips:     return CGSize(width: 366, height: 224)
        case .socialTiles:     return CGSize(width: 366, height: 117)
        case .statWrapped:     return CGSize(width: 366, height: 260)
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
        case .typeMarquee:     return CGSize(width: 366, height: 46)
        case .typeQuote:       return CGSize(width: 366, height: 206)
        case .textBlock:       return CGSize(width: 366, height: 117)
        case .nicheTags:       return CGSize(width: 366, height: 81)
        case .rateMenu:        return CGSize(width: 366, height: 242)
        case .rateTags:        return CGSize(width: 366, height: 117)
        case .rateReceipt:     return CGSize(width: 366, height: 313)
        case .rateNeon:        return CGSize(width: 366, height: 224)
        case .rateStamp:       return CGSize(width: 366, height: 242)
        case .rateBlock:       return CGSize(width: 366, height: 277)
        case .contactCard:     return CGSize(width: 366, height: 135)
        case .contactQR:       return CGSize(width: 179, height: 224)
        case .contactBar:      return CGSize(width: 366, height: 64)
        case .contactStack:    return CGSize(width: 366, height: 153)
        case .contactLine:     return CGSize(width: 366, height: 117)
        case .contactChips:    return CGSize(width: 366, height: 117)
        case .audienceLine:    return CGSize(width: 366, height: 153)
        case .audienceSplit:   return CGSize(width: 366, height: 135)
        case .audienceAge:     return CGSize(width: 366, height: 171)
        case .audienceMap:     return CGSize(width: 366, height: 188)
        }
    }

    /// ยืดได้ทุกตัวทั้งสองแกน — ข้อบังคับเหลือข้อเดียวคือ **ต้องอยู่ในหน้า**
    /// (เล็กสุดที่ `PageLayout.minSize` · ใหญ่สุดคือพื้นที่ใช้งานของหน้า)
    ///
    /// เนื้อหาจะเบียดหรือถูกตัดเป็นการตัดสินใจของคนแต่ง ซึ่งเขาเห็นผลทันทีตอนลาก
    /// เร็วกว่าที่ระบบจะเดาแทนเขา — และเป็นสิ่งเดียวที่ทำให้ "จัดหน้าเอง" มีความหมายจริง
    var canResizeWidth: Bool { true }
    var canResizeHeight: Bool { true }
}


// MARK: - Surface

/// พื้นผิวของ widget — ผู้ใช้เลือกทับค่าตั้งต้นของชนิดได้ทุกตัว
enum WidgetSurface: String, CaseIterable, Identifiable {
    case glass   // liquid glass
    case dim     // แผ่นเข้มทึบ
    case faint   // ขาวจางบาง ๆ
    case plain   // โปร่ง ไม่มีพื้น

    var id: String { rawValue }

    var name: String {
        switch self {
        case .glass: return "กระจก"
        case .dim:   return "เข้ม"
        case .faint: return "จาง"
        case .plain: return "โปร่ง"
        }
    }
}

// MARK: - Instance

struct WidgetInstance: Identifiable, Equatable {
    let id = UUID()
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
    /// หน้าตาตัวอักษร — ฟอนต์ · สี · ขนาด · การจัดวาง
    ///
    /// อยู่ที่ชิ้น ไม่ใช่ที่ตระกูล ด้วยเหตุผลเดียวกับ `surface`/`border`: มันคือ *หน้าตา* ไม่ใช่ *เนื้อหา*
    /// ตอนนี้มีแค่ `textBlock` ที่อ่านค่านี้ (ดู `CardFont`) ตัวอื่นถือไว้เฉย ๆ โดยไม่มีผล
    var textStyle = WidgetTextStyle()

    init(_ kind: WidgetKind, x: CGFloat = PageLayout.margin, y: CGFloat = PageLayout.margin,
         w: CGFloat? = nil, h: CGFloat? = nil) {
        self.kind = kind
        self.x = x
        self.y = y
        self.w = w ?? kind.defaultSize.width
        self.h = h ?? kind.defaultSize.height
        self.surface = kind.isPlain ? .plain : .glass
        self.border = !kind.isPlain
    }

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
