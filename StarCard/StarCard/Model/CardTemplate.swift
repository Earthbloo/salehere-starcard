import SwiftUI

/// เทมเพลตการ์ดสำเร็จรูป — ผังทั้งใบ + ธีม ที่ประกอบเสร็จแล้วให้เลือกเป็นจุดตั้งต้น
///
/// ทุกใบมาจากการ์ดที่ออกแบบเสร็จจริงในแอป (ดู `DesignedTemplate`)
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

    /// ช่องว่างระหว่างหน้า (และขอบรอบแถบ) ของแถบสามหน้าในสำรับ — ทั้งหน้าเลือกสไตล์และคลัง (หน่วยออกแบบ)
    ///
    /// 26 จาก 402 = 6.5% ของความกว้างหน้า — ที่ขนาดใบในสำรับ (กว้างเกือบเต็มจอ) ราว 7pt
    /// พอที่จะอ่านเป็น "คนละแผ่น" แต่ยังไม่ถึงขั้นแยกกันจนไม่เห็นว่าต่อกันเป็นแถบเดียว
    static let thumbGutter: CGFloat = 26

    /// ขนาดหน้ามาตรฐานที่ใช้ทั้งตอนออกแบบผังและตอนวาดพรีวิว
    static func previewPageSize(for format: CardFormat) -> CGSize {
        switch format {
        case .portfolio: return CGSize(width: 402, height: 670)
        case .story:     return CGSize(width: 540, height: 960)
        }
    }

    /// ตู้เทมเพลต = การ์ดที่ออกแบบเสร็จในแอปเท่านั้น (ผังตั้งต้นที่เขียนด้วยโค้ดถูกถอดออก 18 ก.ย. 2026)
    static func all(for format: CardFormat) -> [CardTemplate] {
        designed(for: format)
    }
}

// MARK: - เทมเพลตจากการ์ดที่ออกแบบจริงในแอป

/// การ์ดที่ทีมแต่งเสร็จในแอป ถูกยกมาเป็นเทมเพลต — ผัง · ธีม · หน้าตาตัวอักษร มาครบทุกอย่าง
///
/// # รูปตัวอย่างเป็นของผู้ออกแบบ แต่ใบที่ได้เป็นของผู้ใช้
///
/// รูปบนผนัง (`Resources/DesignedTemplates/<id>.png`) อบจากการ์ดต้นฉบับพร้อมรูปของผู้ออกแบบ — โชว์ว่าผังนี้
/// "ทำเสร็จแล้วหน้าตาเป็นแบบนี้" ไม่ใช่ช่องว่างรอเติม · ตอนเลือก ทุกชิ้นได้ id ใหม่ (`id = nil`)
/// รูปเฉพาะชิ้นกับข้อความที่ผูก id เดิมจึงไม่ตามมา ช่องรูป/ชื่อ/ตัวเลขตกไปอ่านข้อมูลของผู้ใช้เอง
struct DesignedTemplate: Codable {
    let id: String
    let name: String
    let format: String
    let snapshot: CardSnapshot

    /// ไฟล์อยู่ใน `Resources/DesignedTemplates/` แต่ถูกคัดลอกแบนลงรากของ bundle
    static let bundleFolder = "DesignedTemplates"

    static let all: [DesignedTemplate] = {
        guard let url = Bundle.main.url(forResource: "designed-templates", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([DesignedTemplate].self, from: data)) ?? []
    }()

    /// รูปตัวอย่างที่อบไว้ — nil = ยังไม่มีรูป ผนังตกไปอบสดแบบเทมเพลตอื่น
    static func preview(_ id: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: id, withExtension: "png") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

extension CardTemplate {
    static func designed(for format: CardFormat) -> [CardTemplate] {
        DesignedTemplate.all.compactMap { d in
            guard d.format == format.rawValue,
                  let theme = CardStore.restore(d.snapshot)?.theme else { return nil }
            return CardTemplate(
                id: d.id,
                format: format,
                name: d.name,
                vibe: "DESIGNED",
                blurb: "การ์ดที่ออกแบบเสร็จแล้ว — ใส่รูปและข้อมูลของคุณให้อัตโนมัติ",
                theme: theme,
                builder: {
                    var snap = d.snapshot
                    for p in snap.pages.indices {
                        for i in snap.pages[p].items.indices { snap.pages[p].items[i].id = nil }
                    }
                    return CardStore.restore(snap, format: format)?.pages ?? [CardPage()]
                }
            )
        }
    }
}
