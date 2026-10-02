// StarCard.swift — Model กลางของ Star Card
//
// สัญญาเดียวกันทั้ง iOS · Android (StarCard.kt) · Web · API
// ไฟล์นี้คือ "รูปร่างของข้อมูลที่เก็บและส่ง" ไม่ใช่โมเดลที่ใช้วาด — แอปแปลงเป็นโมเดลของตัวเองตอนโหลด
// (เช่น token → enum พร้อมค่าสำรอง) แล้วแปลงกลับตอนบันทึก
//
// ─── กติกากลาง 7 ข้อ (มาจากสิ่งที่เจอในโหมดลองทำ 25 ก.ย. 2569) ───────────────────────────
// 1. token ทุกตัว (kind · font · color · palette …) เป็น String ไม่ใช่ enum
//    แอปเก่าต้องอ่านค่าที่ตัวเองไม่รู้จักผ่าน แล้วค่อยแปลงเป็น enum ตอนวาดพร้อมค่าสำรอง
// 2. ตัวเลขเป็น Double เสมอ (Android เคยใช้ Float: 18.3 → 18.299999237…)
//    พิกัด/ขนาด (pt) ปัด 2 ตำแหน่ง · ค่าจัดรูป 4 ตำแหน่ง — ดู `canonicalized()`
// 3. id เป็น UUID ตัวพิมพ์เล็ก (iOS เคยเขียนตัวใหญ่ Android ตัวเล็ก → key ซ้ำสองอัน)
// 4. เวลาเป็น String ISO-8601 UTC "2026-09-25T09:48:22Z" · วันปฏิทิน "1998-04-11"
//    (ห้ามใช้ Date ของ Codable ตรง ๆ — iOS นับวินาทีจากปี 2001 Android นับ ms จากปี 1970)
// 5. ชุดค่า (set) ส่งเป็น array เรียงน้อยไปมาก (Swift Set สลับลำดับทุกครั้งที่เปิดแอป)
// 6. ค่าที่ไม่มี (nil) และ map/array ว่าง = ไม่ส่ง key เลย · ฟิลด์บังคับส่งเสมอ
// 7. ฟิลด์ที่แอปนี้ไม่รู้จัก เก็บไว้ใน `extra` แล้วส่งกลับครบตอนบันทึก — ห้ามทิ้ง
//
// ─── ข้อมูลแบ่ง 4 ก้อนตาม "ใครเป็นเจ้าของค่า" ───────────────────────────────────────
//   StarCardDoc   การ์ด 1 ใบ         แอปเขียนทั้งก้อน · มี rev          (§1)
//   StarOwner     ข้อมูลเจ้าของ      แอปเขียนทีละช่อง · ใช้ร่วมทุกใบ      (§2)
//   ImageRef      รูป               อัปครั้งเดียว อ้างด้วย id           (§3)
//   StarFacts     ข้อเท็จจริงระบบ     server เขียนเท่านั้น                (§4)
// ตอนมีคนเปิดดูการ์ด server ประกอบ 4 ก้อนเป็น `StarCardView` (§6)

import Foundation

// MARK: - §1 การ์ด — ก้อนที่เก็บใน star_cards.draft_doc / star_card_versions.doc

/// การ์ด 1 ใบ — ผัง · ธีม · ชิ้นทั้งหมด (รวมข้อความ หน้าตา และรูปของแต่ละชิ้น)
///
/// **ไม่มี**: ชื่อ/เบอร์/เรตของเจ้าของ (อยู่ใน `StarOwner`) · ยอดผู้ติดตาม/Verified (อยู่ใน `StarFacts`)
/// · URL รูป (มีแค่ imageId) · สถานะหน้าจอ เช่น หน้าที่เปิดอยู่หรือชิ้นที่เลือกอยู่
///
/// ขนาดจริงราว 3 KB ต่อ 8 ชิ้น 3 หน้า — server รับได้ไม่เกิน 64 KB
struct StarCardDoc: Codable, Equatable {
    /// รุ่นของรูปร่างก้อนนี้ — เพิ่มเลขเฉพาะตอนเปลี่ยนแบบที่เข้ากันไม่ได้ · server แปลงฉบับเก่าให้ตอนอ่าน
    static let currentSchema = 1
    var schemaVersion: Int
    /// `"portfolio"` = 3 หน้า กว้าง 402 pt · `"story"` = 1 หน้า 540×960 pt (= 1080×1920 px @2x)
    ///
    /// ความกว้างตายตัวนี้คือเหตุที่การ์ดหน้าตาเหมือนกันทุกเครื่อง — จอไหนก็แค่ย่อ/ขยายทั้งหน้าตาม
    /// `ความกว้างจอ ÷ ความกว้างออกแบบ` ไม่มีการจัดผังใหม่ตามจอ
    var format: String
    /// ชื่อใบที่เจ้าของตั้งไว้แยกใบในคลัง เช่น "ใบส่ง Cathy Doll" — ไม่ขึ้นบนการ์ด
    var name: String
    var theme: CardTheme
    /// portfolio มี 3 หน้าเสมอ (หน้าว่างได้) · story มี 1 หน้า
    var pages: [CardPage]
    /// ฟิลด์ที่แอปนี้ยังไม่รู้จัก (กติกาข้อ 7)
    var extra: [String: JSONValue] = [:]

    /// kind ทั้งหมดที่ใช้ในใบนี้ เรียงแล้ว — เก็บคู่กับฉบับเผยแพร่ ให้แอปรู้ทันทีว่ามีชิ้นที่ตัวเองวาดไม่ได้ไหม
    var kinds: [String] { Array(Set(pages.flatMap { $0.items.map(\.kind) })).sorted() }
}

/// ธีมของทั้งใบ — สีพื้น · หมึก · มุม · พื้นหลัง · แถบผู้ออกบัตร
///
/// ชื่อฟิลด์ตรงกับ `CardSnapshot.Theme` ของ prototype เพื่อให้แปลงไฟล์เก่าได้ตรงตัว
struct CardTheme: Codable, Equatable {
    /// พาเลตต์สีพื้น: midnight sky ocean mint lime lavender orchid rose ruby coral champagne noir
    var palette: String
    /// หมึก = โทนของตัวหนังสือและแผ่นบนการ์ด: night (พื้นมืด) · paper (พื้นสว่าง) · mist
    var ink: String
    /// ให้ระบบเลือกหมึกจากความสว่างของสีพื้นเอง · nil = true · ผู้ใช้แตะเลือกโทนเมื่อไหร่ = false
    var inkAuto: Bool?
    /// มุมของชิ้น: soft · round · pill
    var corner: String
    /// พื้นหลัง: solid gradient grid stripe diamond glow marble photo
    var backdrop: String
    /// ความสว่างพื้น 0 (เกือบดำ) … 1 (สว่าง)
    var brightness: Double
    /// เลื่อนเฉดพื้นออกจากสีพาเลตต์ −0.5 … 0.5 รอบวงล้อสี
    var hueShift: Double
    /// สีที่ผู้ใช้เลือกเอง (HSB 0…1) — มี `customBri` = สีจริงเป๊ะ · มีแค่ hue/sat = โทนที่ดูดจากรูป
    var customHue: Double?
    var customSat: Double?
    var customBri: Double?
    /// คู่สีสำเร็จรูป (indigo · ink …) — มีค่าเมื่อไหร่ สีพื้นและหมึกมาจากคู่นี้ทั้งคู่
    var duo: String?
    /// true = สีอ่อนของคู่เป็นพื้น · nil/false = สีเข้มเป็นพื้น
    var duoFlipped: Bool?
    /// แบบแถบผู้ออกบัตรขอบล่าง: line ticket ghost emboss foil (ถอดไม่ได้ เลือกได้แค่แบบ)
    var strip: String?
    /// รูปพื้นหลัง — ใช้เมื่อ `backdrop == "photo"` · เก็บต่อใบ (prototype เคยเก็บรูปเดียวต่อเครื่อง)
    var photo: PhotoRef?
    /// เอฟเฟกต์บนรูปพื้นหลัง: none mono blur halftone
    var photoEffect: String?
    /// แผ่นสีคลุมรูปพื้นหลัง 0 … 0.8 · nil = 0.42
    var photoDim: Double?
    /// รูปพื้นหลังเอียงไปทางสว่างแค่ไหน −1 … 1 — **วัดครั้งเดียวตอนเลือกรูปแล้วเก็บไว้**
    /// ทุกเครื่องใช้ค่านี้ตัดสินหมึก ไม่วัดใหม่ (วัดคนละเครื่องได้ค่าไม่ตรงกัน)
    var photoLean: Double?
    var extra: [String: JSONValue] = [:]
}

/// หนึ่งหน้า — ลำดับใน `items` คือลำดับ "ใครได้ที่ก่อน" ตอนสองชิ้นขอพื้นที่เดียวกัน
struct CardPage: Codable, Equatable {
    var items: [WidgetItem]
    var extra: [String: JSONValue] = [:]
}

/// ชิ้นหนึ่งชิ้นบนการ์ด — **widget ใคร widget มัน**: ตำแหน่ง · ข้อความ · หน้าตา · รูป ของชิ้นนี้อยู่ในตัวมันครบ
///
/// ผลคือ ทำสำเนาชิ้น/การ์ด = ได้ของทั้งหมดติดไปและแยกขาดจากต้นฉบับ · ลบชิ้น = ของของมันหายไปด้วย
/// (prototype เคยเก็บข้อความและรูปไว้นอกชิ้น ผูกด้วย id — ทำสำเนาแล้วสองใบแก้ทับกัน)
///
/// ช่องข้อความและช่องรูปของแต่ละ kind ประกาศไว้ใน `WidgetSpec` (§5) — key ใน `text`/`style`/`photos`
/// ต้องเป็นชื่อช่องจากสเปกนั้นเท่านั้น
struct WidgetItem: Codable, Equatable {
    /// UUID ตัวพิมพ์เล็ก · สร้างใหม่ทุกครั้งที่ทำสำเนาหรือสร้างจากเทมเพลต
    var id: String
    /// ชนิดของชิ้น เช่น "statPoster" — แอปที่ไม่รู้จัก kind นี้ต้องเก็บชิ้นไว้ตามเดิม แล้วโชว์ PNG ของหน้าแทน
    var kind: String
    /// กรอบที่ผู้ใช้ **ขอ** (pt บนพื้นที่ออกแบบ มุมซ้ายบนของหน้า) — ไม่ใช่ตำแหน่งหลังจัดผัง
    /// ตอนวาด แอปดันชิ้นที่ทับกันลงไปเอง (PageLayout.solve) โดยไม่เขียนค่าที่ถูกดันกลับมาที่นี่
    var x: Double
    var y: Double
    var w: Double
    var h: Double
    /// พื้นผิวแผ่น: glass dim clear pane · nil = ตามบุคลิกของ kind
    var surface: String?
    /// มีเส้นขอบรอบชิ้น · nil = ตามบุคลิกของ kind
    var border: Bool?
    /// ลายบนแผ่น: plain stripe diamond · nil = plain
    var pattern: String?
    /// ลบพื้นหลังรูปคนอัตโนมัติ (เฉพาะ kind ที่ยกตัวแบบได้) · nil = true
    var liftPhoto: Bool?
    /// ตรา Sale Here บนแผ่น: print (พิมพ์) · blind (ปั๊มนูน) · off · nil = print
    var emboss: String?
    /// ข้อความของชิ้นนี้ — key = ชื่อช่องจากสเปก เช่น `"headline"`
    ///
    /// ช่อง `own` เก็บถ้อยคำที่ผู้ใช้พิมพ์ · ช่องที่ผูกโปรไฟล์แบบ override ได้ เก็บคำที่ทับเฉพาะชิ้นนี้
    /// ไม่มี key = ใช้ค่าจากโปรไฟล์ / ข้อความตั้งต้นในสเปก · เก็บ "ตามที่พิมพ์" — ตัวพิมพ์ใหญ่ทำตอนวาด
    var text: [String: String] = [:]
    /// หน้าตาของแต่ละช่อง — key = ชื่อช่อง (ช่องรายการใช้ชื่อคอลัมน์ เช่น "rate.price" มีผลทุกแถว)
    /// ไม่มี key หรือค่าย่อยเป็น nil = ตามที่สเปกของช่องตั้งไว้
    var style: [String: SlotStyle] = [:]
    /// รูปที่ผู้ใช้ใส่เองในช่องรูปของชิ้นนี้ — key = เลขช่องรูปจากสเปก เช่น `"1"`
    /// ช่องที่ไม่มี key ใช้รูปสำรองตามลำดับกลาง (ดู `StarOwner.photos`)
    var photos: [String: PhotoRef] = [:]
    var extra: [String: JSONValue] = [:]
}

/// หน้าตาของช่องข้อความหนึ่งช่อง — ทุกค่าเป็น optional: nil = ตามสเปก → ตามธีม
///
/// ลำดับหาค่าตอนวาด: `item.style[ช่อง].ค่า` → `WidgetSpec.slots[ช่อง].style.ค่า` → ธีมของการ์ด
struct SlotStyle: Codable, Equatable {
    /// ฟอนต์: noto mitr … — ต้องเป็นไฟล์ฟอนต์ที่ฝังได้ทุกแพลตฟอร์ม (ห้ามฟอนต์ระบบ)
    var font: String?
    /// ขั้นขนาด: xs(0.6) s(0.78) m(1) l(1.3) xl(1.7) xxl(2.2) × ขนาดที่สเปกตั้ง แล้วจำกัด 6–160 pt
    var size: String?
    /// ขนาดเป็น pt ต่อเนื่อง — ใช้เฉพาะช่องที่สเปกอนุญาต (ช่อง body ของ textBlock) · มีค่านี้ = ไม่ใช้ `size`
    var pt: Double?
    /// สี: ตามธีม ink soft accent · ตายตัว white black rose coral gold mint sky lavender
    /// สีตายตัว (ยกเว้นขาว/ดำ) ถูกขยับให้อ่านออกบนพื้นตอนวาด — สูตรต้องเหมือนกันทุกแพลตฟอร์ม
    var color: String?
    /// การจัดแนว: leading center trailing — ใช้เฉพาะช่องที่สเปกอนุญาต
    var align: String?
    var extra: [String: JSONValue] = [:]
}

/// รูปในช่องหนึ่งช่อง — เก็บแค่ตัวอ้างอิงกับตัวเลข ไม่เก็บไฟล์หรือ URL
struct PhotoRef: Codable, Equatable {
    /// รูปต้นฉบับใน image-service
    var imageId: Int
    /// PNG ที่ลบพื้นหลังแล้ว — อัปเป็นไฟล์แยก เพราะ Vision (iOS) กับ ML Kit (Android) ตัดไม่เหมือนกัน
    /// เครื่องที่เปิดดูใช้ไฟล์นี้เลย ไม่คำนวณใหม่
    var liftImageId: Int?
    /// การจัดกรอบ · nil = ครอปกลางเฟรม
    var fit: PhotoFit?
    var extra: [String: JSONValue] = [:]
}

/// การเลื่อน/ซูมรูปในกรอบ — **เป็นสัดส่วน ไม่ใช่ pixel** ย่อขยายกรอบทีหลัง จุดที่เลือกไว้ยังอยู่ที่เดิม
///
/// สูตรตอนวาด (ทุกแพลตฟอร์มต้องเหมือนกัน):
///   1. วางรูปแบบ aspect-fill เต็มกรอบ จัดกลาง → ได้ขนาด R
///   2. ขยาย `zoom` เท่า ยึดจุดกลาง (รูปคนที่ลบพื้นหลังแล้ว ยึดขอบล่าง = เท้า)
///   3. เลื่อน (dx × R.w, dy × R.h)
///   4. จำกัดค่าทุกครั้งที่วาด: zoom 1–8 · |dx| ≤ max(0, (zoom − กว้างกรอบ/R.w) / 2) (dy เช่นเดียวกัน)
///      รูปคนลบพื้นหลัง: zoom 0.4–8 · |dx|,|dy| ≤ 0.5 × max(1, zoom)
struct PhotoFit: Codable, Equatable {
    var dx: Double
    var dy: Double
    var zoom: Double
    var extra: [String: JSONValue] = [:]
}

// MARK: - §2 ข้อมูลเจ้าของ — ไม่อยู่ในการ์ด · ใช้ร่วมทุกใบ · server ประกอบจากตารางโปรไฟล์เดิม

/// ข้อมูลเจ้าของ **ส่วนที่ขึ้นบนการ์ดได้** (อ่านอย่างเดียวในห้องแต่ง — แก้ผ่าน `StarProfileUpdate`)
///
/// แก้ชื่อบนการ์ด = แก้ที่นี่ การ์ดทุกใบเปลี่ยนตาม (ยกเว้นชิ้นที่ทับชื่อไว้เองใน `WidgetItem.text`)
/// **ไม่มีข้อมูลส่วนตัว**: บัญชีธนาคาร · วันเกิด · ศาสนา · ที่อยู่ — อยู่ในโปรไฟล์ แต่ไม่ถูกส่งมากับการ์ด
struct StarOwner: Codable, Equatable {
    /// ชื่อที่แสดง (ProfileField.name)
    var displayName: String
    var nickname: String?
    /// ชื่อผู้ใช้ที่อยู่ในลิงก์ salehere.co.th/star/{handle}
    var handle: String
    /// สายงาน / คำโปรยสั้น
    var tagline: String?
    var about: String?
    var quote: String?
    /// พื้นที่รับงาน
    var workArea: String?
    /// หมวดหมู่ (ตามลำดับที่เจ้าของเรียง) · ความสนใจ (เรียงตามตัวอักษร)
    var categories: [String] = []
    var interests: [String] = []
    /// ลิงก์โซเชียลที่เจ้าของวางไว้ — ยอดผู้ติดตามไม่อยู่ที่นี่ (เป็นข้อเท็จจริงของระบบ ดู `StarFacts`)
    var socials: [SocialLink] = []
    /// เรตราคา — แบรนด์เอาไปเทียบข้ามคน จึงทับรายชิ้นไม่ได้
    var rates: [RateRow] = []
    /// ช่องทางติดต่อ — server ส่งเฉพาะช่องที่เจ้าของเปิดให้โชว์ (show_tel · show_line_id …)
    var contact: ContactInfo?
    var body: BodyMeasurement?
    var availability: Availability?
    var photos: OwnerPhotos
}

struct SocialLink: Codable, Equatable {
    /// instagram tiktok facebook youtube twitter lemon8
    var type: String
    var url: String
}

struct RateRow: Codable, Equatable {
    /// แพลตฟอร์ม: instagram tiktok …
    var platform: String
    /// รูปแบบงาน: post carousel reel story video …
    var format: String
    var price: Double
    /// ISO 4217 · ตอนนี้ "THB" อย่างเดียว
    var currency: String
}

struct ContactInfo: Codable, Equatable {
    /// ชื่อผู้รับงาน · บทบาท เช่น "ติดต่อโดยตรง · ไม่ผ่านผู้จัดการ"
    var name: String?
    var role: String?
    var phone: String?
    var email: String?
    var lineId: String?
}

/// สัดส่วน — ตรงกับ `CreatorBodyMeasurement` ของ backend เดิม (value + unit)
struct BodyMeasurement: Codable, Equatable {
    var height: Measure?
    var weight: Measure?
    var bust: Measure?
    var waist: Measure?
    var hips: Measure?
    var shoe: Measure?
}

struct Measure: Codable, Equatable {
    var value: Double
    /// cm · inch · kg · eur
    var unit: String
}

struct Availability: Codable, Equatable {
    /// สถานะรับงาน: available · busy · closed
    var booking: String
    /// วันที่รับงาน 0 = อาทิตย์ … 6 = เสาร์ — **เรียงน้อยไปมาก** (กติกาข้อ 5)
    var days: [Int] = []
    /// ช่วงเวลา (เลขช่วงตามสเปก) — เรียงน้อยไปมาก
    var slots: [Int] = []
}

/// รูปของเจ้าของ — แหล่งรูปสำรองของช่องที่ไม่ได้ใส่รูปเอง
///
/// ลำดับกลาง (ทุกแพลตฟอร์มต้องเหมือนกัน) ของช่องรูปที่ `i` ในชิ้นหนึ่ง:
///   ช่อง 1–3 → `creator[(i − 1) % จำนวนที่มี]` → `avatar` → รูปตัวอย่างในแอป
///   ช่องอื่น  → `works[i % จำนวน]` → รูปตัวอย่างในแอป
/// (prototype มีคลังรูปรวมอีกกอง — ยุบทิ้ง เหลือสองกองที่ backend มีอยู่แล้ว: profile กับ portfolio)
struct OwnerPhotos: Codable, Equatable {
    var avatar: ImageRef?
    /// รูปครีเอเตอร์ 3 ช่อง (user_creator_images type = profile เรียงตาม seq) · ช่องว่าง = null
    var creator: [ImageRef?] = []
    /// รูปผลงาน (type = portfolio เรียงตาม seq)
    var works: [ImageRef] = []
    var videos: [VideoRef] = []
}

// MARK: - §3 รูป

/// รูปหนึ่งรูปใน image-service — แอปสร้าง URL ตามขนาดที่ต้องใช้จาก `path`
/// ผ่าน CDN เดิม: https://img.salehere.co.th/p/{W}x{H}/{path} (ขอขนาดตามกรอบจริง ไม่โหลดต้นฉบับ)
struct ImageRef: Codable, Equatable {
    var id: Int
    var path: String
    /// ขนาดต้นฉบับ (px) — ใช้คำนวณ aspect-fill ก่อนรูปโหลดเสร็จ
    var width: Int
    var height: Int
}

struct VideoRef: Codable, Equatable {
    var id: Int
    var url: String
    var thumb: ImageRef
    /// ความยาว (วินาที)
    var duration: Double
}

// MARK: - §4 ข้อเท็จจริงจากระบบ — server เขียนเท่านั้น ไม่มี mutation ให้แอป

/// สิ่งที่ทำให้การ์ด "แต่งได้ แต่ปลอมไม่ได้" — widget ตระกูล followers/verified/brand/seal อ่านจากที่นี่
/// ตัวเลขอัปเดตเองโดยไม่ต้องเผยแพร่การ์ดใหม่ (ยกเว้นใน PNG ที่ค้างค่าตอนเผยแพร่)
struct StarFacts: Codable, Equatable {
    /// ยืนยันตัวตนแล้ว (KYC)
    var verified: Bool
    /// ระดับ: "star" หรือ nil
    var rank: String?
    /// ยอดผู้ติดตามต่อแพลตฟอร์ม (จาก scrape) — key = type ของ `SocialLink`
    var followers: [String: Int] = [:]
    /// เวลาที่ดึงยอดล่าสุด (ISO-8601)
    var followersUpdatedAt: String?
    var track: TrackRecord
}

struct TrackRecord: Codable, Equatable {
    /// งานกับ Sale Here ที่ทำจบ · ที่ส่งตรงเวลา
    var completedCampaigns: Int
    var onTimeCampaigns: Int
    var brands: [BrandWork] = []
}

struct BrandWork: Codable, Equatable {
    var brandId: Int
    var name: String
    var logo: ImageRef?
    var campaigns: Int
}

// MARK: - §5 สเปกของ widget และเทมเพลต — เก็บบน server · แก้/เพิ่มได้โดยไม่ต้องออกแอป

/// สเปกของ widget หนึ่งชนิด — **ที่เดียวที่ประกาศว่าชิ้นนี้มีช่องอะไร** ใช้ร่วมทุกแพลตฟอร์ม
///
/// ข้อความตั้งต้นและหน้าตาตั้งต้นอยู่ที่นี่ ไม่เขียนซ้ำในโค้ด Swift/Kotlin (เดิมซ้ำสองที่ → วันหนึ่งไม่ตรงกัน)
struct WidgetSpec: Codable, Equatable {
    var kind: String
    /// ตระกูล — ทุกแบบในตระกูลเดียวกันใช้ชื่อช่องชุดเดียวกัน สลับ "แบบอื่น" แล้วข้อความตามไปถูกช่องเอง
    var family: String
    /// เวอร์ชันแอปขั้นต่ำที่วาดชิ้นนี้ได้ — ถาดของแอปที่เก่ากว่าไม่โชว์ชิ้นนี้ · nil = ยังไม่มีบนแพลตฟอร์มนั้น
    var minIos: String?
    var minAndroid: String?
    var enabled: Bool
    /// ขนาดตั้งต้นตอนวางลงการ์ด (pt)
    var defaultSize: Size
    /// ช่องข้อความ — key = ชื่อช่อง (ตั้งตามความหมาย ห้ามเปลี่ยนชื่อ ห้ามเอาชื่อเก่ามาใช้ใหม่)
    var slots: [String: SlotSpec] = [:]
    /// เลขช่องรูปที่ชิ้นนี้มี เช่น [1] หรือ [4, 5, 6]
    var photoSlots: [Int] = []
    /// key แบบเก่าของ prototype → ชื่อช่องใหม่ เช่น "note#1" → "headline" ใช้แปลงการ์ดเก่าครั้งเดียว
    var legacy: [String: String] = [:]

    struct Size: Codable, Equatable {
        var w: Double
        var h: Double
    }
}

/// ช่องข้อความหนึ่งช่องในสเปก
struct SlotSpec: Codable, Equatable {
    /// ชื่อที่ผู้ใช้เห็นในห้องแต่ง เช่น "พาดหัวบรรทัดบน"
    var label: String
    /// ข้อความมาจากไหน:
    ///   "own"                    ถ้อยคำของชิ้นนี้ (ผู้ใช้พิมพ์ใน `WidgetItem.text`)
    ///   "profile.<ฟิลด์>"         ผูกกับโปรไฟล์ เช่น "profile.displayName"
    ///   "profile.rates[].price"  รายการ — วาดซ้ำทุกแถว (`list` = true)
    ///   "fact.<ค่า>"              ข้อเท็จจริงระบบ เช่น "fact.followers.instagram" — แก้ข้อความไม่ได้
    var from: String
    /// ช่องที่ผูกโปรไฟล์ ให้ทับเฉพาะชิ้นนี้ได้ไหม (ชื่อที่แสดง · คำโปรย = ได้ · เบอร์ · เรต = ไม่ได้)
    var override: Bool?
    var list: Bool?
    /// ข้อความตั้งต้น — ขึ้นจนกว่าผู้ใช้จะพิมพ์ทับ (ช่อง own) หรือเมื่อโปรไฟล์ยังว่าง
    var defaultText: String?
    /// จำนวนตัวอักษรสูงสุด — server ตรวจตอนบันทึก
    var maxLength: Int?
    /// แปลงตอนวาด: "upper" — ในการ์ดเก็บตามที่พิมพ์จริง
    var textCase: String?
    /// หน้าตาตั้งต้นของช่องนี้ (ขนาดเป็น pt ใน `pt`) — `WidgetItem.style` ทับทีละค่า
    var style: SlotStyle?
    /// ผู้ใช้ปรับอะไรได้บ้าง เช่น ["font", "size", "color"] · textBlock เพิ่ม "align", "pt"
    var styleable: [String] = []
}

/// เทมเพลต = การ์ดตัวอย่างที่ทีมออกแบบทำไว้
///
/// สร้างการ์ดจากเทมเพลต: server คัดลอก `doc` → สร้าง UUID ใหม่ให้ทุกชิ้น → ลบ `text`/`photos` ของดีไซเนอร์
/// (เหลือ `style` กับผัง) → การ์ดดึงชื่อและรูปของผู้ใช้เองจาก `StarOwner`
struct CardTemplate: Codable, Equatable {
    var id: String
    var name: String
    var format: String
    var doc: StarCardDoc
    /// รูปตัวอย่างที่อบจากการ์ดของดีไซเนอร์ (ไม่อบใหม่ด้วยข้อมูลของผู้ดู)
    var preview: ImageRef
    var order: Int
    var active: Bool
}

// MARK: - §6 ระเบียนและคำตอบของ API

/// การ์ดของฉัน (เจ้าของเห็น) — ร่างล่าสุด + ฉบับที่เผยแพร่อยู่
struct StarCardRecord: Codable, Equatable {
    var id: Int
    /// ท้ายลิงก์เฉพาะใบ 6–8 ตัว: /star/{handle}/c/{shortId}
    var shortId: String
    var isPrimary: Bool
    var templateId: String?
    /// เลขรุ่นของร่าง — บันทึกครั้งหน้าต้องส่ง `baseRev` = เลขนี้
    var draftRev: Int
    var draft: StarCardDoc
    var published: StarCardVersion?
    var updatedAt: String
}

/// ฉบับที่กดเผยแพร่แล้ว — แก้ไม่ได้ เผยแพร่ใหม่ = ฉบับใหม่ (เก็บย้อนหลัง 20 ฉบับ)
struct StarCardVersion: Codable, Equatable {
    var version: Int
    var doc: StarCardDoc
    /// PNG ทั้งหน้าที่เครื่องผู้แต่งวาด เรียงตามหน้า — ใช้บนเว็บ · พรีวิวลิงก์ · ตอนแอปวาดบาง kind ไม่ได้
    var pageImages: [ImageRef]
    /// 1200×630 สำหรับ og:image (LINE / Facebook)
    var ogImage: ImageRef?
    /// = `doc.kinds`
    var kinds: [String]
    /// แต่งจากเครื่องไหน เวอร์ชันอะไร — ไว้ไล่บั๊ก "iOS เห็นอย่าง Android เห็นอีกอย่าง"
    var platform: String
    var appVersion: String
    var publishedAt: String
}

/// สิ่งที่คนเปิดลิงก์การ์ดได้รับ (/star/{handle}) — ไม่ต้องล็อกอิน
/// ไม่มีร่าง · ไม่มีข้อมูลส่วนตัวของเจ้าของ
struct StarCardView: Codable, Equatable {
    var card: StarCardVersion
    var owner: StarOwner
    var facts: StarFacts
}

/// บันทึกร่าง — ส่งทั้งก้อน 1 วินาทีหลังผู้ใช้หยุดแก้
struct SaveDraftRequest: Codable, Equatable {
    var cardId: Int
    /// rev ที่ร่างนี้แก้ต่อมา — ไม่ตรงกับของ server = มีอีกเครื่องบันทึกก่อน
    var baseRev: Int
    var doc: StarCardDoc
}

struct SaveDraftResult: Codable, Equatable {
    var saved: Bool
    var rev: Int
    /// มีเมื่อชนกัน (saved = false) — ฉบับล่าสุดบน server ให้แอปถามผู้ใช้ว่าจะเก็บฉบับไหน
    var latest: StarCardRecord?
    /// ก้อนที่ server จัดตามกติกากลางแล้ว — แอปใช้ก้อนนี้ต่อ ค่าจะได้ไม่เพี้ยนข้ามเครื่อง
    var canonical: StarCardDoc?
}

struct PublishRequest: Codable, Equatable {
    var cardId: Int
    var rev: Int
    var pageImageIds: [Int]
    var ogImageId: Int?
    var platform: String
    var appVersion: String
}

/// แก้ข้อมูลเจ้าของ **ทีละช่อง** — ห้ามส่งทั้งก้อน (บทเรียน rev 17: ทั้งก้อนทับข้อมูลอีกเครื่อง)
/// เช่น field = "displayName", value = "klll"
struct StarProfileUpdate: Codable, Equatable {
    var field: String
    var value: JSONValue
}

// MARK: - กติกาข้อ 2 · 3 · 5 — จัดก้อนการ์ดให้เป็นรูปแบบกลาง (server ทำซ้ำอีกรอบตอนบันทึก)

extension StarCardDoc {
    func canonicalized() -> StarCardDoc {
        var d = self
        d.theme = theme.canonicalized()
        d.pages = pages.map { page in
            var p = page
            p.items = page.items.map { $0.canonicalized() }
            return p
        }
        return d
    }
}

extension CardTheme {
    func canonicalized() -> CardTheme {
        var t = self
        t.brightness = round(brightness, 4)
        t.hueShift = round(hueShift, 4)
        t.customHue = customHue.map { round($0, 4) }
        t.customSat = customSat.map { round($0, 4) }
        t.customBri = customBri.map { round($0, 4) }
        t.photoDim = photoDim.map { round($0, 4) }
        t.photoLean = photoLean.map { round($0, 4) }
        t.photo = photo?.canonicalized()
        return t
    }
}

extension WidgetItem {
    func canonicalized() -> WidgetItem {
        var i = self
        i.id = id.lowercased()
        i.x = round(x, 2)
        i.y = round(y, 2)
        i.w = round(w, 2)
        i.h = round(h, 2)
        i.style = style.mapValues { s in
            var s = s
            s.pt = s.pt.map { round($0, 1) }
            return s
        }
        i.photos = photos.mapValues { $0.canonicalized() }
        return i
    }
}

extension PhotoRef {
    func canonicalized() -> PhotoRef {
        var p = self
        p.fit = fit.map { PhotoFit(dx: round($0.dx, 4), dy: round($0.dy, 4), zoom: round($0.zoom, 4), extra: $0.extra) }
        return p
    }
}

private func round(_ v: Double, _ places: Int) -> Double {
    let k = pow(10.0, Double(places))
    return (v * k).rounded() / k
}

// MARK: - กติกาข้อ 6 · 7 — encode/decode ที่เก็บฟิลด์ไม่รู้จักไว้ และไม่ส่งค่าว่าง
//
// Codable ที่ Swift สร้างให้ทิ้งฟิลด์ที่ไม่รู้จักเงียบ ๆ — ก้อนที่เดินทางไปกลับ (การ์ด) จึงเขียนเองทุกตัว
// ก้อนที่อ่านอย่างเดียว (เจ้าของ · ข้อเท็จจริง · สเปก · คำตอบ API) ใช้ของที่ Swift สร้างให้
// → server ต้องส่ง key ของ array/map ในก้อนเหล่านั้นเสมอ (ว่างได้) เพราะของที่ Swift สร้างให้ไม่ใช้ค่าตั้งต้นตอน decode

/// ค่า JSON อะไรก็ได้ — ใช้เก็บฟิลด์ที่ไม่รู้จักให้ส่งกลับได้ตรงตัว
enum JSONValue: Codable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(Double.self) { self = .number(v) }
        else if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode([JSONValue].self) { self = .array(v) }
        else { self = .object(try c.decode([String: JSONValue].self)) }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .object(let v): try c.encode(v)
        }
    }
}

private struct AnyKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(_ s: String) { stringValue = s }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

private extension KeyedDecodingContainer where K == AnyKey {
    func req<T: Decodable>(_ k: String) throws -> T { try decode(T.self, forKey: AnyKey(k)) }
    func opt<T: Decodable>(_ k: String) throws -> T? { try decodeIfPresent(T.self, forKey: AnyKey(k)) }
    func unknown(_ known: [String]) throws -> [String: JSONValue] {
        let known = Set(known)
        var out: [String: JSONValue] = [:]
        for k in allKeys where !known.contains(k.stringValue) {
            out[k.stringValue] = try decode(JSONValue.self, forKey: k)
        }
        return out
    }
}

private extension KeyedEncodingContainer where K == AnyKey {
    mutating func put<T: Encodable>(_ v: T, _ k: String) throws { try encode(v, forKey: AnyKey(k)) }
    mutating func put<T: Encodable>(_ v: T?, _ k: String) throws { if let v { try encode(v, forKey: AnyKey(k)) } }
    mutating func put<V: Encodable>(_ v: [String: V], _ k: String) throws { if !v.isEmpty { try encode(v, forKey: AnyKey(k)) } }
    mutating func put(extra: [String: JSONValue]) throws { for (k, v) in extra { try encode(v, forKey: AnyKey(k)) } }
}

extension StarCardDoc {
    private static let known = ["schemaVersion", "format", "name", "theme", "pages"]
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        schemaVersion = try c.req("schemaVersion")
        format = try c.req("format")
        name = try c.opt("name") ?? ""
        theme = try c.req("theme")
        pages = try c.req("pages")
        extra = try c.unknown(Self.known)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: AnyKey.self)
        try c.put(schemaVersion, "schemaVersion")
        try c.put(format, "format")
        try c.put(name, "name")
        try c.put(theme, "theme")
        try c.put(pages, "pages")
        try c.put(extra: extra)
    }
}

extension CardTheme {
    private static let known = ["palette", "ink", "inkAuto", "corner", "backdrop", "brightness", "hueShift",
                                "customHue", "customSat", "customBri", "duo", "duoFlipped", "strip",
                                "photo", "photoEffect", "photoDim", "photoLean"]
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        palette = try c.req("palette")
        ink = try c.req("ink")
        inkAuto = try c.opt("inkAuto")
        corner = try c.req("corner")
        backdrop = try c.req("backdrop")
        brightness = try c.req("brightness")
        hueShift = try c.opt("hueShift") ?? 0
        customHue = try c.opt("customHue")
        customSat = try c.opt("customSat")
        customBri = try c.opt("customBri")
        duo = try c.opt("duo")
        duoFlipped = try c.opt("duoFlipped")
        strip = try c.opt("strip")
        photo = try c.opt("photo")
        photoEffect = try c.opt("photoEffect")
        photoDim = try c.opt("photoDim")
        photoLean = try c.opt("photoLean")
        extra = try c.unknown(Self.known)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: AnyKey.self)
        try c.put(palette, "palette")
        try c.put(ink, "ink")
        try c.put(inkAuto, "inkAuto")
        try c.put(corner, "corner")
        try c.put(backdrop, "backdrop")
        try c.put(brightness, "brightness")
        try c.put(hueShift, "hueShift")
        try c.put(customHue, "customHue")
        try c.put(customSat, "customSat")
        try c.put(customBri, "customBri")
        try c.put(duo, "duo")
        try c.put(duoFlipped, "duoFlipped")
        try c.put(strip, "strip")
        try c.put(photo, "photo")
        try c.put(photoEffect, "photoEffect")
        try c.put(photoDim, "photoDim")
        try c.put(photoLean, "photoLean")
        try c.put(extra: extra)
    }
}

extension CardPage {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        items = try c.opt("items") ?? []
        extra = try c.unknown(["items"])
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: AnyKey.self)
        try c.put(items, "items")
        try c.put(extra: extra)
    }
}

extension WidgetItem {
    private static let known = ["id", "kind", "x", "y", "w", "h", "surface", "border", "pattern",
                                "liftPhoto", "emboss", "text", "style", "photos"]
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        id = try c.req("id")
        kind = try c.req("kind")
        x = try c.req("x")
        y = try c.req("y")
        w = try c.req("w")
        h = try c.req("h")
        surface = try c.opt("surface")
        border = try c.opt("border")
        pattern = try c.opt("pattern")
        liftPhoto = try c.opt("liftPhoto")
        emboss = try c.opt("emboss")
        text = try c.opt("text") ?? [:]
        style = try c.opt("style") ?? [:]
        photos = try c.opt("photos") ?? [:]
        extra = try c.unknown(Self.known)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: AnyKey.self)
        try c.put(id, "id")
        try c.put(kind, "kind")
        try c.put(x, "x")
        try c.put(y, "y")
        try c.put(w, "w")
        try c.put(h, "h")
        try c.put(surface, "surface")
        try c.put(border, "border")
        try c.put(pattern, "pattern")
        try c.put(liftPhoto, "liftPhoto")
        try c.put(emboss, "emboss")
        try c.put(text, "text")
        try c.put(style, "style")
        try c.put(photos, "photos")
        try c.put(extra: extra)
    }
}

extension SlotStyle {
    private static let known = ["font", "size", "pt", "color", "align"]
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        font = try c.opt("font")
        size = try c.opt("size")
        pt = try c.opt("pt")
        color = try c.opt("color")
        align = try c.opt("align")
        extra = try c.unknown(Self.known)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: AnyKey.self)
        try c.put(font, "font")
        try c.put(size, "size")
        try c.put(pt, "pt")
        try c.put(color, "color")
        try c.put(align, "align")
        try c.put(extra: extra)
    }
}

extension PhotoRef {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        imageId = try c.req("imageId")
        liftImageId = try c.opt("liftImageId")
        fit = try c.opt("fit")
        extra = try c.unknown(["imageId", "liftImageId", "fit"])
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: AnyKey.self)
        try c.put(imageId, "imageId")
        try c.put(liftImageId, "liftImageId")
        try c.put(fit, "fit")
        try c.put(extra: extra)
    }
}

extension PhotoFit {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyKey.self)
        dx = try c.opt("dx") ?? 0
        dy = try c.opt("dy") ?? 0
        zoom = try c.opt("zoom") ?? 1
        extra = try c.unknown(["dx", "dy", "zoom"])
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: AnyKey.self)
        try c.put(dx, "dx")
        try c.put(dy, "dy")
        try c.put(zoom, "zoom")
        try c.put(extra: extra)
    }
}
