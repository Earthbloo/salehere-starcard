import SwiftUI

// MARK: - ข้อความล้วน
//
// # ทำไมตู้ที่มีสี่สิบกว่าใบยังต้องมีใบนี้
//
// ทุกใบที่มีอยู่ตอบ *คำถามที่รู้ล่วงหน้า* — ชื่ออะไร · ตามกี่คน · เคยทำงานกับใคร
// ซึ่งครอบคลุมเกือบทั้งการ์ด แต่ไม่ครอบคลุมสิ่งที่เจ้าของการ์ดอยากเขียนเองแล้วไม่มีช่องให้:
// หัวเรื่องคั่นหน้า · ประโยคปิดท้าย · เงื่อนไขสั้น ๆ ท้ายเรตราคา · ชื่อหมวดของกองรูปข้างล่าง
//
// เดิมคนใช้ต้องไปยืม `แนะนำตัว` หรือ `คำพูดตัวใหญ่` มาทำหน้าที่นี้ ซึ่งพังสองทาง:
// สองตัวนั้นผูกกับช่อง `about`/`quote` ที่ทั้งการ์ดใช้ร่วมกัน — วางสองที่แล้วพิมพ์คนละเรื่องไม่ได้
// และหน้าตาก็ล็อกไว้แล้ว (มีรูปพื้นหลัง มีเครื่องหมายคำพูด มีชื่อคนพูดต่อท้าย)
//
// ใบนี้จึงมีข้อเดียว: **ตัวอักษรที่เจ้าของการ์ดคุมได้ทั้งหมด** ไม่มีของแถมสักชิ้น
// — ไม่มีรูป ไม่มีไอคอน ไม่มีหัวข้อ ไม่มีเส้นคั่น มีแต่สิ่งที่เขาพิมพ์ลงไป
//
// # สิ่งที่ผู้ใช้เลือกได้ (อยู่เหนือแป้นพิมพ์ตอนพิมพ์ ไม่ใช่ในตู้)
//
// ฟอนต์ · สี · การจัดวาง — เก็บใน `WidgetInstance.textStyle` (ดู `TextStyle.swift`)
// **ขนาดปรับที่หมุดมุมของกล่อง** (`points`) — ลากออกโต ลากเข้าเล็ก · กล่องคือตัวอักษรพอดีเสมอ
// **ไม่ตัดบรรทัดเอง** — บรรทัดใหม่มีเฉพาะที่ผู้ใช้กด Return · ยาวจนล้นหน้าค่อยหดขนาดให้ชั่วคราว (ดู `TextFit`)
//
// # ท่าเปลี่ยนหน้า — "บรรทัดมุดใต้ขอบตัวเอง"
//
// ท่าเดียวกับข้อความก้อนอื่นทั้งการ์ด (`scrubVeil`) โดยตั้งใจ — ใบนี้ไม่มีวัสดุเป็นของตัวเอง
// ให้ท่าพิเศษเมื่อไหร่มันจะเด่นกว่าเนื้อหาที่มันควรจะเป็นแค่ตัวพา

/// ข้อความอิสระหนึ่งก้อน — ทั้งใบคือตัวอักษรที่แก้ได้ก้อนเดียว
///
/// ข้อความเก็บต่อ **ชิ้น** ไม่ใช่ต่อตระกูล (ดู `ProfileField.note`) — id ของชิ้นมาทาง
/// environment เส้นเดียวกับที่รูปใช้ จึงไม่ต้องส่ง `WidgetInstance` ลงมาทั้งก้อน
struct TextBlock: View {
    @Environment(\.pageScrub) private var scrub
    @Environment(\.cardInk) private var ink
    @Environment(\.cardAccent) private var accent
    @Environment(\.widgetID) private var wid
    @Environment(\.widgetTextStyle) private var spec
    /// กำลังถูกพิมพ์บนการ์ดอยู่ — ตัวอักษรหลบให้ `CanvasTextField` ที่ทับตำแหน่งเดียวกันพอดี
    @Environment(\.canvasTyping) private var typing
    let theme: CardTheme
    let size: CGSize

    /// น้ำหนักเดียวทุกขนาด — ขนาดเปลี่ยนตามกล่องตลอดเวลา ถ้าน้ำหนักไต่ตามด้วยจะเห็นตัวอักษรกระพริบหนาบาง
    static let weight: Font.Weight = .semibold
    /// ขอบระหว่างตัวอักษรกับกล่อง — **ชิด** แค่พอให้เส้นกรอบไม่ทับสระบน/วรรณยุกต์ (ผู้ใช้ขอ "ไม่มี padding")
    static let inset: CGFloat = 4
    /// มุมของกล่องข้อความ — เล็กกว่าการ์ด เพราะกล่องหุ้มตัวอักษรพอดี มุมมนใหญ่จะกินมุมตัวอักษร
    static let radius: CGFloat = 10

    /// เกณฑ์ตัวใหญ่ของ WCAG (ราว 18pt ตัวหนา) — ตัวขนาดนี้ขึ้นไปอ่านออกที่ contrast 3:1
    static func isLarge(_ points: CGFloat) -> Bool { points >= 20 }

    @Environment(\.pageContentWidth) private var pageW

    private var text: String { wid == nil ? Self.sample : Profile.me.note(wid) }

    /// ขนาดที่ใช้จริง — ตามที่ตั้ง เว้นแต่บรรทัดยาวเกิน **หน้า** จึงหดพอดี
    /// คิดจากความกว้างหน้า ไม่ใช่ความกว้างกล่อง — กล่องถูกคิดจากตัวเลขนี้อีกที ถ้าย้อนกลับไปพึ่งกล่องจะวนเป็นงู
    private var fitted: CGFloat {
        TextFit.capped(spec.points, text, face: spec.face, weight: Self.weight,
                       maxWidth: pageW - Self.inset * 2)
    }

    var body: some View {
        let font = spec.face.font(fitted, Self.weight)
        let large = Self.isLarge(fitted)
        // สีที่เลือกคือคำขอ — สีที่วาดคือเวอร์ชันที่อ่านออกบนพื้นการ์ดตอนนี้ (ดู `TextTint.color`)
        let color = spec.tint.color(ink: ink, accent: accent, large: large)
        let halo = spec.tint.halo(ink: ink, large: large)
        Group {
            if typing {
                // ช่องพิมพ์บนการ์ด *คือ* ตัวอักษรตอนนี้ — วาดซ้ำจะเห็นสองชั้นเหลื่อมกัน
                Color.clear
            } else if wid == nil {
                // พรีวิวในตู้ — ไม่มีกล่องที่วัดจากหมึก แค่วางกลางช่องให้ดูออกว่าเป็นอะไร
                Text(text).font(font).foregroundStyle(color)
                    .lineSpacing(fitted * TextFit.spacing)
                    .multilineTextAlignment(spec.align.text)
                    .fixedSize()
                    .legibilityHalo(halo, size: fitted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let m = TextFit.metrics(text, face: spec.face, weight: Self.weight, size: fitted, align: spec.align)
                Text(text).font(font).foregroundStyle(color)
                    .lineSpacing(fitted * TextFit.spacing)
                    .multilineTextAlignment(spec.align.text)
                    // ห้ามตัดบรรทัดเอง — ทั้งสองแกนคงขนาดธรรมชาติ บรรทัดใหม่มีเฉพาะที่พิมพ์ไว้
                    .fixedSize()
                    .legibilityHalo(halo, size: fitted)
                    .frame(width: m.typo.width, height: m.typo.height, alignment: .topLeading)
                    // กล่องถูกวัดจาก **หมึก** (ดู `TextFit.metrics`) — เลื่อน line box ให้หมึกชิดมุมบนซ้ายพอดี
                    .offset(x: -m.ink.minX, y: -m.ink.minY)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrubVeil(scrub.d, lead: 0.1, drop: 26, pull: 12)
    }

    /// ตัวอย่างในตู้ — สองบรรทัดที่บอกว่าใบนี้ทำอะไรได้ โดยไม่ต้องมีป้ายกำกับ
    private static let sample = "เขียนอะไรก็ได้\nยืดกล่องแล้วตัวอักษรโตตาม"
}

private struct PageContentWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 366
}

extension EnvironmentValues {
    /// ความกว้างเนื้อหาของหน้าที่ widget นี้อยู่ — ก้อนข้อความใช้ตัดสินว่าบรรทัดยาวเกินหน้าเมื่อไหร่
    /// ค่าตั้งต้นคือหน้าพอร์ต (402 − ขอบ 18×2) สำหรับพรีวิวในตู้ที่ไม่ได้อยู่บนหน้าไหน
    var pageContentWidth: CGFloat {
        get { self[PageContentWidthKey.self] }
        set { self[PageContentWidthKey.self] = newValue }
    }
}
