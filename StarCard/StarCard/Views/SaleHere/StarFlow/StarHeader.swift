import SwiftUI
import PhosphorSwift

// MARK: - หัวร่วมของสองหน้า (Star Profile ↔ Star Card) — ชิ้นเดียว ไม่เปลี่ยนตำแหน่งตอนสลับหน้า
//
// ผู้ใช้ 23 ก.ย. 2569: "title กับ toggle ต้องรักษาไว้เหมือนชิ้นเดียวกัน" — หัวนี้จึงไม่ได้อยู่ในหน้าใดหน้าหนึ่ง
// แต่ลอยอยู่บนทั้งสองหน้าใน `SaleHereShell` เปลี่ยนแค่คำ (Profile ⇄ Card) สี (หมึก ⇄ ขาว) และลูกบิดของ toggle

struct StarHeader: View {
    let isCard: Bool
    /// ยังไม่มีการ์ด = หัว "สมัครเป็น STAR" ไม่มี toggle (ยังไม่มีหน้าการ์ดให้สลับ)
    var hasCard = true
    let showsDot: Bool
    /// ปุ่มสลับ ข้อมูล | การ์ด — เลิกใช้ 24 ก.ย. 2569 (การ์ดอยู่บนหน้า Profile แล้ว หน้า Card มีปุ่ม ‹ กลับแทน)
    var showsToggle = true
    let onToggle: (Bool) -> Void
    @Namespace private var knob

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if hasCard { title } else { GlassTitle(words: [("สมัครเป็น", false), ("STAR", true)], small: true) }
            Spacer(minLength: 0)
            if hasCard && showsToggle { toggle.padding(.bottom, 6) }
        }
        .padding(.horizontal, 16)
        .frame(height: 64, alignment: .bottom)
        .animation(Motion.page, value: isCard)
    }

    /// ตรา ST★R + คำ serif — คำ serif ไขว้จางกัน ตราเปลี่ยนสีตามพื้น (หมึกบนสว่าง · ขาวบนมืด)
    /// (ผู้ใช้ 30 ก.ย. 2569: เอา STAR จากไอคอนมาแทนคำ Star — ดู `StarCaps`)
    private var title: some View {
        HStack(alignment: .lastTextBaseline, spacing: StarCaps.gap(forSerif: 54)) {
            StarCaps(height: StarCaps.height(forSerif: 54), color: isCard ? .white : GL.ink)
                .shadow(color: isCard ? .black.opacity(0.35) : GL.ink.opacity(0.14), radius: 15, y: 14)
            ZStack(alignment: .leading) {
                serif("Profile").opacity(isCard ? 0 : 1).offset(y: isCard ? -6 : 0)
                serif("Card").opacity(isCard ? 1 : 0).offset(y: isCard ? 0 : 6)
            }
        }
        .lineLimit(1).minimumScaleFactor(0.7)
    }

    private func serif(_ t: String) -> some View {
        Text(t).font(GL.serif(54))
            .foregroundStyle(LinearGradient(colors: isCard ? [.white, .white, Color(red: 232 / 255, green: 199 / 255, blue: 102 / 255)]
                                                          : [GL.ink, GL.ink, GL.goldInk],
                                            startPoint: .top, endPoint: .bottom))
            .shadow(color: isCard ? .black.opacity(0.3) : GL.ink.opacity(0.12), radius: 9, y: 12)
    }

    /// toggle ข้อมูล | การ์ด — ลูกบิดเลื่อนไปมาในรางเดียว (matchedGeometry) ไม่ใช่สองปุ่มคนละหน้า
    private var toggle: some View {
        HStack(spacing: 2) {
            chip("ข้อมูล", on: !isCard, dot: false) { onToggle(false) }
            chip("การ์ด", on: isCard, dot: showsDot && !isCard) { onToggle(true) }
        }
        .padding(3)
        .background(
            Capsule().fill(.white.opacity(isCard ? 0.14 : 0.6))
                .glassEffect(.regular, in: Capsule())
        )
        .overlay(Capsule().strokeBorder(.white.opacity(isCard ? 0.22 : 0.95), lineWidth: isCard ? 0.6 : 1))
        .shadow(color: GL.ink.opacity(isCard ? 0 : 0.07), radius: 8, y: 4)
    }

    private func chip(_ t: String, on: Bool, dot: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard !on else { return }
            Haptics.impact(.light)
            action()
        } label: {
            HStack(spacing: 5) {
                Text(t).font(.sh(13, .bold))
                if dot { Circle().fill(GL.green).frame(width: 6, height: 6) }
            }
            .foregroundStyle(on ? (isCard ? Color.black.opacity(0.88) : .white) : (isCard ? .white.opacity(0.85) : GL.ink))
            .padding(.horizontal, 13).frame(height: 32)
            .background {
                if on {
                    Capsule().fill(isCard ? Color.white.opacity(0.92) : GL.ink)
                        .matchedGeometryEffect(id: "knob", in: knob)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - พื้นร่วม + ดวงไฟ — แสงเดียวกันเดินทางจากหน้าโปรไฟล์ไปหน้าการ์ด
//
// ผู้ใช้: "แสงที่หมุนจาก dark กับ light มันต้องสวิตช์ไฟเหมือน move ดวงไฟ" — พื้นสว่าง ↔ เวทีมืดของธีมการ์ด
// และดวงไฟ champagne สองดวงของหน้าโปรไฟล์คือดวงเดียวกับแสงสีธีมที่ส่องการ์ด แค่ย้ายที่และเปลี่ยนสี

struct StarGround: View {
    let isCard: Bool
    /// ธีมของใบที่กำลังดู — สีของดวงไฟและเวทีในสถานะการ์ด
    let theme: CardTheme?

    private var accent: Color { theme?.rawAccent ?? GL.gold }

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                GL.bg
                if let theme {
                    ZStack {
                        CardBackdrop(theme: theme, ignoreSafeArea: false)
                        LinearGradient(colors: [.black.opacity(0.54), .black.opacity(0.36), .black.opacity(0.6)],
                                       startPoint: .top, endPoint: .bottom)
                        SignaturePattern(opacity: 0.06)
                    }
                    .opacity(isCard ? 1 : 0)
                }
                // ดวงไฟหลัก: มุมซ้ายบน champagne → กลางจอเป็นสีธีมส่องการ์ด
                Circle().fill(isCard ? accent : GL.orb1)
                    .frame(width: 340, height: 340).blur(radius: 70)
                    .opacity(isCard ? 0.5 : 0.7)
                    .position(isCard ? CGPoint(x: w * 0.5, y: h * 0.46) : CGPoint(x: 30, y: 110))
                // ดวงรอง: ขวา → ตามไปคล้อยหลัง
                Circle().fill(isCard ? accent : GL.orb2)
                    .frame(width: 320, height: 320).blur(radius: 70)
                    .opacity(isCard ? 0.28 : 0.5)
                    .position(isCard ? CGPoint(x: w * 0.62, y: h * 0.56) : CGPoint(x: w + 10, y: 250))
                // จุดสว่างขาว: หายไปเมื่อเป็นเวทีมืด
                Circle().fill(.white)
                    .frame(width: 140, height: 140).blur(radius: 30)
                    .opacity(isCard ? 0.08 : 0.9)
                    .position(isCard ? CGPoint(x: w * 0.5, y: h * 0.42) : CGPoint(x: 260, y: 110))
            }
            .animation(Motion.lamp, value: isCard)
            .animation(Motion.settle, value: accent)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

extension Motion {
    /// ดวงไฟเดินทาง — ช้ากว่าเปลี่ยนหน้านิดหน่อย ให้เห็นแสงย้ายที่จริง ๆ
    static let lamp = Animation.interpolatingSpring(stiffness: 110, damping: 22)
}
