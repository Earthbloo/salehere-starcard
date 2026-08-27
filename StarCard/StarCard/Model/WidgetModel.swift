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
/// แยกจาก `WidgetGroup` เพราะหมวดใน gallery หยาบแค่สามหมวด
/// ถ้าใช้หมวดมาหาแบบอื่น มันจะเสนอสลับ "ฟิล์มสตริป → โลโก้แบรนด์" ซึ่งคนละเรื่องกัน
enum WidgetFamily: String, CaseIterable {
    // ลำดับนี้คือลำดับที่โผล่ในตู้ — ของหลักมาก่อน ถ้อยคำปิดท้ายทั้งสองหมวด
    case hero, intro, followers, tags, brand, verified, photo, words,
         schedule, format

    var label: String {
        switch self {
        case .hero:      return "โปรไฟล์"
        case .intro:     return "แนะนำตัว"
        case .brand:     return "แบรนด์"
        case .verified:  return "ผลงานยืนยัน"
        case .followers: return "ผู้ติดตาม"
        case .photo:     return "รูปผลงาน"
        case .schedule:  return "เวลารับงาน"
        case .format:    return "ประเภทคอนเทนต์"
        case .words:     return "ถ้อยคำ"
        case .tags:      return "หมวดหมู่"
        }
    }
}

// MARK: - Kind

enum WidgetKind: String, CaseIterable, Identifiable {
    // โปรไฟล์
    case artPortrait, artTypeOver, artPolaroid, heroMinimal, heroAura
    // เกี่ยวกับฉัน
    case aboutText, aboutNote, interestTags
    // เงื่อนไขรับงาน
    case workSchedule, workFormat
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
    case statGiant, socialChips, statWrapped
    // ผลงาน
    case artFilmstrip, artDuo, workFeatured, workReel, artPhotobooth
    // เนื้อหา
    case typeMarquee, typeQuote, nicheTags, stickerTags

    var id: String { rawValue }

    /// หมวดใน gallery
    /// ตัวเลขผู้ติดตามอยู่ "เกี่ยวกับฉัน" เพราะมันคือขนาดของตัวเรา ไม่ใช่งานที่เคยทำ
    /// ส่วนแถบวิ่งโชว์ชื่อแบรนด์ที่ร่วมงาน จึงเป็นผลงาน ไม่ใช่ของตกแต่ง
    var group: WidgetGroup {
        switch self {
        case .artPortrait, .artTypeOver, .artPolaroid, .heroMinimal, .heroAura,
             .aboutText, .aboutNote, .statGiant, .socialChips, .statWrapped,
             .nicheTags, .stickerTags, .interestTags, .typeQuote:
            return .about
        case .workSchedule, .workFormat:
            return .booking
        case .proofBrands, .proofBrandWall, .proofBrandGrid, .proofBrandRail, .proofBrandList,
             .proofWork, .proofTicket, .proofHolo, .proofShelf, .proofZine, .typeMarquee,
             .artFilmstrip, .artDuo, .workFeatured, .workReel, .artPhotobooth:
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
        case .statGiant, .socialChips, .statWrapped: return .followers
        case .artFilmstrip, .artDuo, .workFeatured, .workReel, .artPhotobooth: return .photo
        case .workSchedule: return .schedule
        case .workFormat: return .format
        case .typeQuote: return .words
        // สายงาน (พิมพ์เอง) กับ หมวดหมู่ (ของแพลตฟอร์ม) สลับกันได้ — เล่าเรื่องเดียวกัน
        case .nicheTags, .stickerTags, .interestTags: return .tags
        }
    }

    /// ชั้นสิทธิ์ — ผูกกับที่มาของข้อมูล ไม่ใช่หมวดใน gallery
    /// (หมวดเหลือสามหมวดหยาบ ๆ แล้ว ใช้แทนกันไม่ได้อีก)
    var tier: WidgetTier {
        switch self {
        case .proofBrands, .proofBrandWall, .proofBrandGrid, .proofBrandRail, .proofBrandList,
             .proofWork, .proofTicket, .proofHolo, .proofShelf, .proofZine:
            return .verified                       // แพลตฟอร์มออกให้จากงานที่ส่งจริง
        case .statGiant, .socialChips, .statWrapped,
             .workSchedule, .workFormat, .interestTags:
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
        case .artPortrait, .artTypeOver, .artPolaroid, .artFilmstrip, .artDuo,
             .typeMarquee, .typeQuote, .statGiant,
             // text/ชิปลอยบนการ์ด — ครอบกระจกซ้ำแล้วอ่านเป็นกล่องซ้อนกล่อง
             .heroMinimal, .aboutText, .proofBrandList, .nicheTags, .socialChips,
             // โลโก้ไหลบนการ์ดแบบเดียวกับแถบวิ่ง
             .proofBrandRail,
             // ผลงานยืนยันแบบใหม่ — ทุกตัววาดพื้นผิวของตัวเอง (กระดาษตั๋ว · ฟอยล์ · กระดานปะ · โปสเตอร์)
             // ครอบกระจกทับแล้วจะได้กล่องซ้อนกล่อง และพื้นกระดาษจะสู้กับพื้นกระจกจนสีเพี้ยน
             .proofTicket, .proofHolo, .proofShelf, .proofZine,
             // สำรับ Gen Z — วัสดุของแต่ละตัวคือพื้นผิวของมันเอง (แสง · กระดาษโน้ต ·
             // บล็อกสีทึบ · กระดาษภาพ · ฟองแชต · สติกเกอร์) ครอบกระจกแล้วจะสู้กันทั้งชุด
             .heroAura, .aboutNote, .statWrapped, .artPhotobooth, .stickerTags:
            return true
        default:
            return false
        }
    }

    /// widget ที่แสดงรูปครีเอเตอร์หรือรูปผลงาน — เปิดให้อัปโหลดรูปของตัวเองทับรูปตั้งต้นได้
    var usesPhoto: Bool {
        switch self {
        case .artPortrait, .artTypeOver, .artPolaroid, .statGiant, .typeQuote,
             .artFilmstrip, .artDuo, .workFeatured, .workReel, .proofWork,
             .heroAura, .artPhotobooth,
             // ชั้นหลักฐานตอนนี้ใช้รูปทุกตัว — ตัวที่ไม่ใช้ถูกถอดออกไปแล้ว
             .proofTicket, .proofHolo, .proofShelf, .proofZine:
            return true
        default:
            return false
        }
    }

    /// widget ที่มีรูปเป็นแกนหลัก — ต้องเว้น padding เป็นศูนย์เพื่อให้รูปชนขอบ
    var isFullBleed: Bool {
        switch self {
        case .workFeatured, .workReel: return true
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
        case .workSchedule: return "เวลาที่รับงาน"
        case .workFormat: return "ประเภทคอนเทนต์"
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
        case .socialChips: return "ไอคอนช่องทาง"
        case .statWrapped: return "การ์ดสรุปยอด"
        case .artPhotobooth: return "ตู้ถ่ายรูป"
        case .stickerTags: return "สติกเกอร์สายงาน"
        case .artFilmstrip: return "แถบภาพ"
        case .artDuo: return "เบนโตะ"
        case .workFeatured: return "ผลงานชิ้นเด่น"
        case .workReel: return "คลิปแนวตั้ง"
        case .typeMarquee: return "แถบวิ่ง"
        case .typeQuote: return "คำพูดตัวใหญ่"
        case .nicheTags: return "สายงาน"
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
        case .workSchedule: return "calendar.badge.clock"
        case .workFormat: return "square.grid.2x2.fill"
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
        case .socialChips: return "circle.grid.3x1.fill"
        case .statWrapped: return "list.number"
        case .artPhotobooth: return "camera.fill"
        case .stickerTags: return "seal.fill"
        case .artFilmstrip: return "rectangle.split.3x1.fill"
        case .artDuo: return "square.grid.2x2.fill"
        case .workFeatured: return "rectangle.grid.1x2.fill"
        case .workReel: return "play.rectangle.fill"
        case .typeMarquee: return "text.line.first.and.arrowtriangle.forward"
        case .typeQuote: return "quote.bubble.fill"
        case .nicheTags: return "tag"
        }
    }

    /// ขนาดบนกริด A4 (6 คอลัมน์ × 9 แถว)
    ///
    /// `c` = ช่วงคอลัมน์ที่อนุญาต · `r` = ช่วงแถว · `d` = ขนาดตั้งต้น
    /// เก็บเป็นหน่วยกริดไม่ใช่ pt เพื่อให้หน้ากระดาษเต็มพอดีเสมอและ export ไม่มีที่ว่างค้าง
    // หน่วยแถว = หนึ่งจุดของ dot grid (36 แถว/หน้า) — ละเอียดพอให้ขยับทีละจุดแบบ Figma
    var grid: (c: ClosedRange<Int>, r: ClosedRange<Int>, d: (Int, Int)) {
        switch self {
        case .artPortrait: return (4...6, 21...30, (6, 24))
        case .artTypeOver: return (4...6, 15...27, (6, 21))
        // ฟิล์มจริงอยู่ที่ ~1:1.22 — ของเดิมตั้งไว้ 18 แถวซึ่งเป็นแท่งสูง
        // การ์ดเลยไม่มีวันเต็มกรอบ และช่องว่างที่เหลือคือต้นเหตุของแผ่นสีโล้น ๆ ครึ่งล่าง
        case .artPolaroid: return (3...4, 10...20, (3, 12))
        // กลุ่ม text/ชิปไร้กรอบ — แถวตั้งต้นต้องกอดเนื้อหา ไม่เผื่อที่ว่างท้ายก้อน
        case .heroMinimal: return (4...6, 6...12, (6, 7))
        // ออร่าต้องได้ที่มากกว่า hero ตัวอื่น — ดวงแสงกินขอบภาพไปรอบด้าน
        case .heroAura: return (4...6, 18...30, (6, 22))
        case .aboutText: return (4...6, 4...18, (6, 5))
        // โน้ตเป็นกระดาษ ไม่ใช่ย่อหน้า — ต้องมีขอบกระดาษเหลือรอบตัวหนังสือเสมอ
        case .aboutNote: return (4...6, 8...16, (6, 9))
        case .interestTags: return (4...6, 6...12, (6, 7))
        case .workSchedule: return (4...6, 9...15, (6, 12))
        case .workFormat: return (3...6, 9...18, (6, 12))
        case .proofBrands: return (6...6, 6...9, (6, 6))
        case .proofBrandWall: return (3...6, 9...12, (6, 12))
        // สิบสองแบรนด์ = สี่คอลัมน์สามแถว — เตี้ยกว่านี้ช่องจะแบนจนโลโก้ถูกบีบ
        case .proofBrandGrid: return (4...6, 12...22, (6, 17))
        case .proofBrandRail: return (6...6, 5...6, (6, 5))
        // สิบสองชื่อที่ 17pt ตกสี่บรรทัด — ตั้งต้นต่ำกว่านี้แล้วบรรทัดสุดท้ายจะล้นไปทับ widget ถัดไป
        // (ก้อนนี้ไม่ได้ถูก clip ที่ขอบ ความสูงตั้งต้นจึงต้องเผื่อของจริงเสมอ)
        case .proofBrandList: return (4...6, 7...16, (6, 11))
        case .proofWork: return (6...6, 14...20, (6, 15))
        // แถวตั้งต้นมาจากการวัดความสูงจริงตอนกว้าง 6 คอลัมน์
        // ทั้งชั้นตั้งไว้สูงกว่าเดิม เพราะพอให้รูปเป็นตัวนำแล้วช่องรูปต้องได้ที่มากกว่าครึ่ง
        case .proofTicket: return (6...6, 13...19, (6, 15))
        case .proofHolo: return (6...6, 12...18, (6, 14))
        case .proofShelf: return (6...6, 12...18, (6, 15))
        case .proofZine: return (6...6, 12...18, (6, 14))
        case .statGiant: return (4...6, 9...12, (6, 9))
        case .socialChips: return (3...6, 6...12, (6, 6))
        // ตัวเลขรวม + สามอันดับ — เตี้ยกว่านี้แล้วอันดับจะเบียดจนอ่านเป็นตาราง
        case .statWrapped: return (4...6, 13...20, (6, 15))
        case .artPhotobooth: return (4...6, 8...15, (6, 11))
        case .stickerTags: return (3...6, 6...12, (6, 8))
        case .artFilmstrip: return (4...6, 5...10, (6, 6))
        case .artDuo: return (4...6, 12...18, (6, 15))
        case .workFeatured: return (4...6, 12...18, (6, 15))
        case .workReel: return (2...3, 15...21, (2, 18))
        case .typeMarquee: return (6...6, 3...3, (6, 3))
        case .typeQuote: return (4...6, 12...12, (6, 12))
        case .nicheTags: return (3...6, 5...9, (6, 5))
        }
    }

    var colRange: ClosedRange<Int> { grid.c }
    var rowRange: ClosedRange<Int> { grid.r }

    var canResizeWidth: Bool { colRange.lowerBound != colRange.upperBound }
    var canResizeHeight: Bool { rowRange.lowerBound != rowRange.upperBound }
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
    var cols: Int
    var rows: Int
    /// แถวว่างเหนือ widget (หน่วยเดียวกับกริด/dot ฉากหลัง) — 0 คือชิดตามปกติ
    /// ให้การ์ดมีจังหวะหายใจได้ ไม่ต้องอัดทุกก้อนติดกันตลอด
    var gap: Int = 0
    /// พื้นผิว — ตั้งต้นตามบุคลิกของชนิด (typography โปร่ง · แผ่นข้อมูลกระจก)
    var surface: WidgetSurface
    /// เส้นขอบรอบ widget — แยกจากพื้นผิว เพราะบางทีอยากได้กรอบโดยไม่เอาพื้น
    /// (พื้นโปร่ง + มีขอบ = การ์ดเส้นขอบล้วน ซึ่งเป็นอีกหน้าตาหนึ่ง)
    var border: Bool

    init(_ kind: WidgetKind, cols: Int? = nil, rows: Int? = nil) {
        self.kind = kind
        self.cols = cols ?? kind.grid.d.0
        self.rows = rows ?? kind.grid.d.1
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
