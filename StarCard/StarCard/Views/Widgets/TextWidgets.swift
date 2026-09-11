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
// # สิ่งที่ผู้ใช้เลือกได้ (อยู่ในแผงของชิ้น ไม่ใช่ในตู้)
//
// ฟอนต์ · สี · ขนาด · การจัดวาง — เก็บใน `WidgetInstance.textStyle` (ดู `TextStyle.swift`)
// สี่อย่างนี้อยู่ที่ *ชิ้น* จึงตั้งคนละแบบได้ทุกก้อนบนหน้าเดียวกัน
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
    let theme: CardTheme
    let size: CGSize

    private var style: TextSlotStyle {
        .init(size: spec.scale.size,
              weight: spec.scale.weight,
              face: spec.face,
              color: spec.tint.color(ink: ink, accent: accent),
              align: spec.align.text,
              lineSpacing: spec.scale.lineSpacing,
              corner: 5)
    }

    var body: some View {
        Group {
            // ไม่มี id ของชิ้น = ไม่ได้อยู่บนการ์ด (พรีวิวในตู้ · thumb ในแผงสลับแบบ)
            //
            // ที่นั่นต้องวาด **ตัวอย่างที่มีน้ำหนัก** ไม่ใช่ประโยคชวนพิมพ์บรรทัดเดียว —
            // ใบนี้ไม่มีรูป ไม่มีชิป ไม่มีกรอบ ถ้าพรีวิวเป็นบรรทัดจาง ๆ บรรทัดเดียว
            // มันจะหายไปกับพื้นตู้ แล้วคนเลื่อนผ่านโดยไม่รู้ว่ามีใบนี้อยู่ (เจอมาแล้ว)
            if wid == nil {
                Text(Self.sample)
                    .font(style.font)
                    .foregroundStyle(style.color)
                    .lineSpacing(style.lineSpacing)
                    .multilineTextAlignment(style.align)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: spec.align.frame)
            } else {
                EditableParagraph(field: .note, style: style,
                                  widget: wid, anchor: spec.align.frame)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .scrubVeil(scrub.d, lead: 0.1, drop: 26, pull: 12)
    }

    /// ตัวอย่างในตู้ — สองบรรทัดที่บอกว่าใบนี้ทำอะไรได้ โดยไม่ต้องมีป้ายกำกับ
    private static let sample = "เขียนอะไรก็ได้ที่นี่\nเลือกฟอนต์ สี ขนาด เองได้"
}
