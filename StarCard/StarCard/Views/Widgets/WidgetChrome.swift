import SwiftUI

/// เปลือกของ widget หนึ่งตัว — พื้น · กระจก · ขอบ — ใช้ทั้งบนแคนวาสและตอนเรนเดอร์รูป
///
/// เนื้อหาข้างในปิด hit testing ไว้เสมอ รูปแบบ `.fill` ที่ล้นกรอบจะได้ไม่ไปแย่งทัชของตัวข้างเคียง
/// ชั้นการ์ดเป็นคนวาง catcher ทับเองถ้าต้องการให้ลาก/เลือกได้
struct WidgetChrome: View {
    let placed: Placed
    let theme: CardTheme

    var body: some View {
        let p = placed
        let ink = theme.inkStyle
        let kind = p.item.kind
        let surface = p.item.surface
        let shape = RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
        // "ไม่มีขอบ" = ไม่มีเปลือกอะไรเลย — ทั้งพื้นและเส้นขอบหายไปพร้อมกัน
        let framed = p.item.border
        // มีเปลือกเมื่อไหร่ต้องมีระยะหายใจข้างใน ยกเว้น full-bleed ที่รูปต้องชนขอบ
        let inset: CGFloat = kind.isFullBleed || !framed ? 0 : 12

        // MARK: ย่อเนื้อหาลงเมื่อกรอบแคบกว่าความกว้างที่มันถูกออกแบบมา
        //
        // # ปัญหา
        //
        // เนื้อหาข้างในหลายตัวมีความกว้าง **ต่ำสุด** ของมันเอง (ไอคอน 34pt สามอัน + ตัวเลข
        // + ระยะห่าง) พอผู้ใช้ย่อกรอบให้แคบกว่านั้น `HStack` ไม่บีบให้ต่ำกว่าค่าต่ำสุด
        // มันจึงล้นออกนอกกรอบ — เห็นเป็นของที่โผล่พ้นเส้นเลือกไปอยู่บนวิดเจ็ตตัวอื่น
        //
        // # กติกา
        //
        // เนื้อหาถูกออกแบบมาที่ความกว้าง `kind.defaultSize.width` — ถือว่านั่นคือ "ขนาดจริง"
        // ของมัน กรอบที่แคบกว่านั้นจึงไม่ใช่การจัดผังใหม่ แต่คือการ **ย่อทั้งชิ้น**
        // เหมือนย่อรูป ทุกอย่างเล็กลงพร้อมกันตามสัดส่วน ไม่มีอะไรหลุดกรอบและไม่มีอะไรพัง
        //
        // กรอบที่กว้างกว่าหรือเท่ากันได้พฤติกรรมเดิมทุกประการ (`s == 1`) —
        // ตัวนี้จึงไม่แตะการ์ดที่ยังใช้ขนาดตั้งต้นอยู่เลย
        let natural = max(kind.defaultSize.width, 1)
        let s = min(1, max(p.frame.width, 1) / natural)
        // ผังถูกวางในหน่วย "ก่อนย่อ" แล้วค่อยหดทั้งก้อน — ความสูงจึงต้องหารกลับด้วย
        // ไม่งั้นเนื้อหาจะสูงไม่ถึงก้นกรอบเมื่อถูกย่อ
        let layout = CGSize(width: max(p.frame.width, 1) / s,
                            height: max(p.frame.height, 1) / s)

        let content = WidgetBody(kind: kind, theme: theme, size: layout)
            .environment(\.widgetID, p.item.id)
            // ฟอนต์/สี/ขนาด/การจัดวางของตัวอักษร — เก็บอยู่ที่ชิ้น ส่งลงไปทางเดียวกับ id
            // (วิดเจ็ตที่ไม่ได้อ่านค่านี้ก็แค่ไม่หยิบไปใช้ ไม่ต้องรู้จักมันด้วยซ้ำ)
            .environment(\.widgetTextStyle, p.item.textStyle)
            .padding(inset)
            .frame(width: layout.width, height: layout.height, alignment: .topLeading)
            .scaleEffect(s, anchor: .topLeading)
            .frame(width: p.frame.width, height: p.frame.height, alignment: .topLeading)
            .allowsHitTesting(false)

        Group {
            switch framed ? surface : .plain {
            case .plain:
                // ต้อง clip เหมือนอีกสามแบบ — ไม่มีเปลือกไม่ได้แปลว่าไม่มีขอบเขต
                // ของที่ล้นออกไปนอกกรอบคือของที่ไปทับวิดเจ็ตตัวอื่นโดยที่ผังไม่รู้เรื่องด้วย
                //
                // แต่ต้องเป็น **สี่เหลี่ยมตรง** ไม่ใช่ `shape` ที่มุมมน: แบบนี้ไม่มีแผ่นพื้น
                // มุมมนจึงไม่มีอะไรให้อ้างอิง มันกลายเป็นแค่ของที่กินหัวข้อซึ่งนั่งชิดมุมบนซ้าย
                // (รัศมี 22pt กินตัวแรกของ "ผู้ติดตาม" หายไปทั้งตัว)
                content.clipShape(Rectangle())

            case .glass:
                GlassPanel(tint: kind.tier == .verified ? theme.accent : nil,
                           tintStrength: kind.tier == .verified ? 0.13 : 0,
                           radius: theme.radius) {
                    content.clipShape(shape)
                }

            case .dim:
                ZStack {
                    shape.fill(ink.isLight ? ink.fill(0.4) : Color.black.opacity(0.4))
                    content.clipShape(shape)
                }

            case .faint:
                ZStack {
                    shape.fill(ink.isLight ? Color.white.opacity(0.55) : Color.white.opacity(0.06))
                    content.clipShape(shape)
                }
                .shadow(color: ink.lift.opacity(0.6), radius: ink.liftRadius * 0.7, y: 4)
            }
        }
        .overlay {
            if p.item.border {
                shape.strokeBorder(ink.line(surface == .plain ? 0.18 : 0.12), lineWidth: 0.7)
            }
        }
    }
}
