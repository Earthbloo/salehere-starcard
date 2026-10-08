import SwiftUI
import PhosphorSwift

// MARK: - ST★R Insight — ใครมาดู Star Card ของฉัน (ผู้ใช้ 4 ต.ค. 2569)
//
// "ให้ user เข้ามาดูได้ว่ามีคน View เท่าไหร่ กดมาดู Star Card เท่าไหร่ เป็น Brand สไตล์ไหน"
// แล้วตามด้วย "เอาดู Minimal ไม่ต้องใส่ข้อมูลเยอะ แบบเข้ามา scan แล้วเข้าใจ"
//
// หน้านี้จึงมีแค่ 3 ก้อน เรียงเป็นกรวยเดียวจากบนลงล่าง: ยอดวิว (เลขเด่นตัวเดียว + กราฟเดียว) → กดเข้ามาดูการ์ด → แบรนด์สายไหน
// แล้วจบด้วยปุ่มชุดเดียวกับหน้า Star Card (แต่งการ์ด · แชร์) — ไม่มีกล่อง ไม่มีแท็บ ไม่มีตัวกรองนอกจากช่วงเวลา 2 ค่า
// โทน = ดำล้วน ตัวเลขขาว ตัวกราฟมีสี สีเดียวทั้งหน้า = สีของการ์ดใบที่แสดงอยู่ (ผู้ใช้เห็นรุ่นย้อมสีธีมการ์ดทั้งหน้าแล้วสั่ง
// "เอาเป็นดำโทนเท่ไปเลย" · กราฟสีทอง "กราฟสีนี้ไม่เวิค" · กราฟขาว "ไม่เอา เอาสีสิ … ขาวดูไม่ออกเลย" · "สีตาม card ละกัน")
// หัว ST★R + คำ serif และปุ่มกระจก ชุดเดียวกับหน้า Star Card · เขียวใช้กับลูกศรขึ้นของ % เท่านั้น ไม่ใช้เป็นสีกราฟ
// ตัวเลขทั้งหมดมาจาก `StarInsight.mock` — ยังไม่มีระบบนับยอดดูจริง

enum InsightInk {
    /// สีของกราฟทั้งหน้า (เส้น · แถบเด่น · จุด) = **เฉดสีของการ์ดใบที่แสดงอยู่** ปรับความสว่าง/ความสดให้เท่ากันทุกเฉด
    /// (OKLCH L 0.66 · C สูงสุดที่จอแสดงได้) — แยกจากตัวหนังสือขาวได้ (≥3:1) และจากพื้นดำ (≥5:1) ไม่ว่าการ์ดสีอะไร
    /// การ์ดโทนไม่มีสี (ดำ/ขาว/เทา) หรือยังไม่มีการ์ด = ฟ้า · ลองสีตายตัว: เปิดแอปด้วย `-insightTint blue|green|violet|red`
    static func mark(for theme: CardTheme?) -> Color {
        switch UserDefaults.standard.string(forKey: "insightTint") {
        case "blue": return blue
        case "green": return Color(red: 31 / 255, green: 174 / 255, blue: 110 / 255)    // #1FAE6E
        case "violet": return Color(red: 146 / 255, green: 119 / 255, blue: 242 / 255)  // #9277F2
        case "red": return Color(red: 248 / 255, green: 69 / 255, blue: 79 / 255)       // #F8454F
        default: break
        }
        guard let theme else { return blue }
        // เฉดของพื้นการ์ดก่อน (สีที่คนจำการ์ดใบนั้นได้) · พื้นไม่มีสี = ใช้เฉดของสีเน้น
        for source in [theme.backdropColors.top, theme.rawAccent] {
            let lab = OKLab(RGB(source))
            if lab.chroma >= 0.035 { return OKLab.color(lightness: 0.66, chroma: 0.2, hue: lab.hue) }
        }
        return blue
    }
    static let blue = Color(red: 61 / 255, green: 141 / 255, blue: 245 / 255)           // #3D8DF5
    static let up = Color(red: 110 / 255, green: 231 / 255, blue: 170 / 255)
    static let soft = Color.white.opacity(0.74)
    static let faint = Color.white.opacity(0.6)
    static let rule = Color.white.opacity(0.13)
}

struct StarInsightPage: View {
    /// ธีมของการ์ดใบที่แสดงอยู่ — สีของกราฟ
    let theme: CardTheme?
    let onClose: () -> Void
    var onEditCard: () -> Void = {}
    var onShare: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var range: StarInsight.Range = .week
    @State private var drawn = false
    /// จุดที่นิ้วลากอยู่บนกราฟ — nil = ไม่ได้ลาก (โชว์ป้ายวันที่ยอดสูงสุดแทน)
    @State private var scrub: Int?
    /// ข้อมูลชุดนี้ดึงมาเมื่อไหร่ — ลากหน้าลงเพื่อดึงใหม่
    @State private var updated = Date()

    private var data: StarInsight { .mock(range) }
    private var mark: Color { InsightInk.mark(for: theme) }

    var body: some View {
        ZStack(alignment: .top) {
            ground
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if StarInsight.neverSeen {
                        emptyState.padding(.top, 72)
                    } else if data.isEmpty {
                        quietRange.padding(.top, 72)
                    } else {
                        Group {
                            todayLine.padding(.top, 14)
                            hero.padding(.top, 12)
                            InsightChart(data: data, mark: mark, drawn: drawn, scrub: $scrub)
                                .frame(height: 128)
                                .padding(.top, 8)
                            rule
                            opens
                            rule
                            brands
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 108)
            }
            // ลากลง = ดึงข้อมูลใหม่ (ต้นแบบ: หน่วงสั้น ๆ แล้ววาดกราฟใหม่ ข้อมูลชุดเดิม)
            .refreshable {
                Haptics.impact(.medium)
                try? await Task.sleep(nanoseconds: 700_000_000)
                updated = Date()
                redraw()
            }
            HStack {
                Button {
                    Haptics.impact(.light)
                    onClose()
                } label: {
                    PIcon(.caretLeft, size: 17, weight: .bold).foregroundStyle(.white.opacity(0.92))
                        .frame(width: 44, height: 44).contentShape(Circle())
                }
                .buttonStyle(DockPress())
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel("กลับ")
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 8)
        }
        .overlay(alignment: .bottom) { dock }
        // ปัดจากขอบซ้าย = กลับ (ปุ่ม ‹ อยู่มุมบนที่นิ้วโป้งเอื้อมยาก)
        .overlay(alignment: .leading) {
            Color.clear.frame(width: 18).contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 12).onEnded { v in
                    if v.translation.width > 70, abs(v.translation.height) < 90 { onClose() }
                })
                .accessibilityHidden(true)
        }
        // กระจกของปุ่ม/รางบนเวทีมืดต้องเป็นกระจกโทนมืด (shell ทั้งแอปตั้งเป็นโทนสว่าง)
        .environment(\.colorScheme, .dark)
        .onAppear { redraw() }
        .onChange(of: range) { _, _ in redraw() }
    }

    private func redraw() {
        scrub = nil
        guard !reduceMotion else { drawn = true; return }
        drawn = false
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 1.1).delay(0.12)) { drawn = true }
    }

    // MARK: เวที — ดำล้วน ไม่ย้อมสีธีมการ์ด · แสงขาวจางมากดวงเดียวหลังหัวกับเลขเด่น

    private var ground: some View {
        GeometryReader { g in
            ZStack {
                LinearGradient(colors: [Color(red: 14 / 255, green: 14 / 255, blue: 16 / 255), Color(red: 6 / 255, green: 6 / 255, blue: 8 / 255)],
                               startPoint: .top, endPoint: .bottom)
                Circle().fill(.white)
                    .frame(width: 380, height: 380).blur(radius: 120)
                    .opacity(0.07)
                    .position(x: g.size.width * 0.16, y: 170)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: หัว: ST★R Insight + ช่วงเวลา (ตัวกรองเดียวของหน้า อยู่เหนือทุกอย่างที่มันคุม)

    private var header: some View {
        HStack(alignment: .bottom, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: StarCaps.gap(forSerif: 46)) {
                StarCaps(height: StarCaps.height(forSerif: 46), color: .white)
                Text("Insight").font(GL.serif(46)).foregroundStyle(GL.serifInk(onDark: true))
            }
            .lineLimit(1).fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Star Insight")
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            // ยังไม่เคยมีคนเห็น = ไม่มีช่วงให้เลือก · ช่วงนี้เงียบแต่ช่วงอื่นมี = ตัวเลือกต้องยังอยู่
            if !StarInsight.neverSeen { rangeToggle.padding(.bottom, 5) }
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
        .frame(height: 114, alignment: .bottom)
    }

    private var rangeToggle: some View {
        HStack(spacing: 2) {
            ForEach(StarInsight.Range.allCases) { r in
                let on = r == range
                Button {
                    guard !on else { return }
                    Haptics.impact(.light)
                    withAnimation(Motion.settle) { range = r }
                } label: {
                    Text(r.rawValue).font(.sh(13, .bold))
                        .foregroundStyle(on ? Color.black.opacity(0.88) : .white.opacity(0.88))
                        .padding(.horizontal, 11).frame(height: 32)
                        .background { if on { Capsule().fill(.white.opacity(0.94)) } }
                        // พื้นที่แตะสูง 44 โดยไม่ดันความสูงของราง
                        .padding(.vertical, 6).contentShape(Rectangle()).padding(.vertical, -6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("ช่วง \(r.rawValue)ล่าสุด")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .glassEffect(.regular, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 0.6))
    }

    // MARK: ของใหม่วันนี้ — บรรทัดเดียว เรื่องเดียวกับข้อความแจ้งเตือน (ไม่มีอะไรใหม่ = ไม่มีบรรทัดนี้)

    @ViewBuilder
    private var todayLine: some View {
        if let t = data.today {
            HStack(spacing: 7) {
                Circle().fill(InsightInk.up).frame(width: 7, height: 7)
                Text("วันนี้ แบรนด์สาย\(t.name)เข้ามาดู \(t.brands) ราย")
                    .font(.sh(13.5, .semibold)).foregroundStyle(.white.opacity(0.92)).lineLimit(1)
            }
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: ก้อน 1 — ยอดวิว: เลขเด่นตัวเดียวของหน้า + เทียบช่วงก่อนหน้า

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("ยอดวิว").font(.sh(15, .semibold)).foregroundStyle(InsightInk.soft)
                Spacer(minLength: 8)
                // ข้อมูลสดแค่ไหน — นับจากครั้งล่าสุดที่ดึง (ลากหน้าลงเพื่อดึงใหม่)
                TimelineView(.periodic(from: updated, by: 30)) { t in
                    Text(freshness(at: t.date)).font(.sh(12, .medium)).foregroundStyle(InsightInk.faint)
                }
            }
            // เลขกับ % อยู่บรรทัดเดียวกัน — ไม่พอ (เลขยาว/จอแคบ) จึงค่อยลงบรรทัดใหม่
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .lastTextBaseline, spacing: 12) { number; delta }
                VStack(alignment: .leading, spacing: 0) { number; delta }
            }
            .padding(.top, -4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ยอดวิว \(range.rawValue)ล่าสุด \(data.views) ครั้ง")
        .accessibilityValue(data.previousViews > 0 ? DeltaLine.spoken(data.change, baseline: "\(range.rawValue)ก่อน") : "")
    }

    private func freshness(at now: Date) -> String {
        let m = Int(now.timeIntervalSince(updated) / 60)
        return m < 1 ? "อัปเดตเมื่อสักครู่" : m < 60 ? "อัปเดต \(m) นาทีที่แล้ว" : "อัปเดต \(m / 60) ชม. ที่แล้ว"
    }

    private var number: some View {
        Text(StarInsight.fmt(data.views))
            .font(.sh(54, .heavy)).tracking(-1).foregroundStyle(.white)
            .contentTransition(.numericText())
            .fixedSize()
    }

    @ViewBuilder
    private var delta: some View {
        if data.previousViews > 0 {
            DeltaLine(change: data.change, baseline: "\(range.rawValue)ก่อน", before: data.previousViews, now: data.views).fixedSize()
        }
    }

    // MARK: ก้อน 2 — กดเข้ามาดูการ์ด: จำนวน + สัดส่วนของยอดวิว

    private var opens: some View {
        let pct = Int((data.openRate * 100).rounded())
        return VStack(alignment: .leading, spacing: 12) {
            rowHead("กดเข้ามาดูการ์ด", StarInsight.fmt(data.opened), "ครั้ง")
            HStack(spacing: 12) {
                // รางเป็นสีเดียวกับแถบแต่จางกว่า — อ่านเป็นส่วนของทั้งหมด
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(mark.opacity(0.24))
                        Capsule().fill(mark)
                            .frame(width: max(8, g.size.width * (drawn ? data.openRate : 0)))
                    }
                }
                .frame(height: 8)
                Text(data.opened == 0 ? "ยังไม่มีคนกดเข้ามา" : "\(pct)% ของยอดวิว").font(.sh(13, .medium)).foregroundStyle(InsightInk.soft)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("กดเข้ามาดูการ์ด \(data.opened) ครั้ง")
        .accessibilityValue(data.opened == 0 ? "" : "คิดเป็น \(pct) เปอร์เซ็นต์ของยอดวิว")
    }

    // MARK: ก้อน 3 — แบรนด์สายไหน: หัวข้อคือข้อสรุป แถบเรียงมากไปน้อย เน้นแถวแรกแถวเดียว

    private var brands: some View {
        let top = data.styles.first
        let most = Double(top?.brands ?? 1)
        return VStack(alignment: .leading, spacing: 12) {
            rowHead(top.map { "แบรนด์สาย\($0.name)ดูคุณมากที่สุด" } ?? "แบรนด์ที่ดูคุณ", "\(data.brands)", "แบรนด์")
            // ตาราง 3 คอลัมน์: ชื่อสาย (กว้างเท่าชื่อยาวสุด) · แถบ · จำนวน
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                ForEach(Array(data.styles.enumerated()), id: \.element.id) { i, s in
                    GridRow {
                        Text(s.name).font(.sh(14, i == 0 ? .semibold : .medium))
                            .foregroundStyle(i == 0 ? .white : InsightInk.soft)
                            .lineLimit(1).fixedSize()
                        GeometryReader { g in
                            // โคนแถบเหลี่ยม ปลายมน — ทุกแถวโตจากเส้นฐานเดียวกัน
                            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 1, bottomLeading: 1, bottomTrailing: 4, topTrailing: 4))
                                .fill(i == 0 ? mark : Color.white.opacity(0.42))
                                .frame(width: max(4, g.size.width * (drawn ? Double(s.brands) / most : 0)))
                        }
                        .frame(height: 8)
                        Text("\(s.brands)").font(.sh(14, .bold)).monospacedDigit()
                            .foregroundStyle(.white)
                            .gridColumnAlignment(.trailing)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("สาย\(s.name) \(s.brands) แบรนด์")
                }
            }
            if let top {
                Text("ลองวางผลงาน\(top.name)ไว้หน้าแรกของการ์ด").font(.sh(13, .medium)).foregroundStyle(InsightInk.faint)
            } else {
                // มีคนเห็นแล้วแต่ยังไม่มีแบรนด์ — บอกตรง ๆ ไม่ปล่อยเป็นที่ว่าง
                Text("ยังไม่มีแบรนด์เข้ามาดูในช่วงนี้").font(.sh(14, .medium)).foregroundStyle(InsightInk.soft)
            }
        }
    }

    /// หัวของก้อน: ข้อความซ้าย · ตัวเลข + หน่วย ขวา (ตัวเลขทุกก้อนอยู่แนวเดียวกัน กวาดตาลงมาอ่านได้)
    private func rowHead(_ title: String, _ value: String, _ unit: String) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(title).font(.sh(16, .semibold)).foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            Text(value).font(.sh(20, .heavy)).foregroundStyle(.white).monospacedDigit()
                .contentTransition(.numericText())
            Text(unit).font(.sh(13, .medium)).foregroundStyle(InsightInk.soft)
                .padding(.leading, -3)
        }
    }

    private var rule: some View {
        InsightInk.rule.frame(height: 1).padding(.vertical, 13)
    }

    // MARK: ยังไม่มีคนเห็น — บอกว่าต้องทำอะไร ไม่โชว์กราฟเปล่า

    private var emptyState: some View {
        VStack(spacing: 10) {
            PIcon(.chartLineUp, size: 30, weight: .bold).foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Circle().fill(.white.opacity(0.08)))
                .overlay(Circle().strokeBorder(.white.opacity(0.16), lineWidth: 0.8))
                .padding(.bottom, 6)
            Text("ยังไม่มีคนเห็นการ์ด").font(.sh(20, .bold)).foregroundStyle(.white)
            Text("แชร์ลิงก์การ์ดของคุณ\nยอดวิวและแบรนด์ที่เข้ามาดูจะขึ้นที่นี่")
                .font(.sh(15)).foregroundStyle(InsightInk.soft).multilineTextAlignment(.center).lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    /// ช่วงที่เลือกเงียบ แต่ช่วงอื่นมีข้อมูล — บอกว่าช่วงไหน แล้วพาไปช่วงที่มี
    private var quietRange: some View {
        let other = StarInsight.Range.allCases.first { !StarInsight.mock($0).isEmpty }
        return VStack(spacing: 10) {
            Text("\(range.rawValue)ล่าสุดยังไม่มีคนเห็นการ์ด").font(.sh(20, .bold)).foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("แชร์การ์ดอีกรอบ ยอดวิวจะกลับมาขึ้นที่นี่").font(.sh(15)).foregroundStyle(InsightInk.soft)
            if let other {
                Button {
                    Haptics.impact(.light)
                    withAnimation(Motion.settle) { range = other }
                } label: {
                    Text("ดู \(other.rawValue)").font(.sh(14, .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 18).frame(height: 44)
                        .contentShape(Capsule())
                }
                .buttonStyle(DockPress())
                .glassEffect(.regular.interactive(), in: Capsule())
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: ปุ่มล่าง — ชุดเดียวกับหน้า Star Card (ปุ่มหลักทึบ · แชร์เป็นกระจก)

    private var dock: some View {
        HStack(spacing: 10) {
            if data.isEmpty {
                dockPrimary("square.and.arrow.up", "แชร์การ์ด", action: onShare)
            } else {
                dockPrimary("pencil", "แต่งการ์ด", action: onEditCard)
                Button {
                    Haptics.impact(.light)
                    onShare()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "square.and.arrow.up").font(.system(size: 14, weight: .semibold)).offset(y: -1)
                        Text("แชร์").font(.sh(15, .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 22).frame(height: 52)
                    .contentShape(Capsule())
                }
                .buttonStyle(DockPress())
                .glassEffect(.regular.interactive(), in: Capsule())
                .accessibilityLabel("แชร์การ์ด")
            }
        }
        .padding(.horizontal, 20).padding(.top, 28).padding(.bottom, 8)
        .background(
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        )
    }

    private func dockPrimary(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.medium)
            action()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: symbol).font(.system(size: 14, weight: .bold))
                Text(title).font(.sh(15, .bold))
            }
            .foregroundStyle(Color.black.opacity(0.88))
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(Capsule().fill(.white.opacity(0.94)))
            .contentShape(Capsule())
        }
        .buttonStyle(DockPress())
    }
}

/// ▲ 18% จาก 7 วันก่อน — ลูกศร + ตัวเลข + ช่วงที่เทียบ (ไม่ใช้สีอย่างเดียว) · ลดลง = สีกลาง ไม่ใช้แดง
/// ฐานเล็ก (ช่วงก่อนไม่ถึง 20 ครั้ง) % แกว่งจนไม่มีความหมาย — บอกเป็นจำนวนครั้งแทน
struct DeltaLine: View {
    let change: Double
    let baseline: String
    var before = 100
    var now = 100

    var body: some View {
        let up = change >= 0
        HStack(spacing: 5) {
            PIcon(up ? .trendUp : .trendDown, size: 14, weight: .bold)
            Text(before < 20 ? "\(abs(now - before)) ครั้ง" : "\(Int((abs(change) * 100).rounded()))%").font(.sh(15, .bold))
            Text("จาก \(baseline)").font(.sh(14, .medium)).foregroundStyle(InsightInk.soft)
        }
        .foregroundStyle(up ? InsightInk.up : InsightInk.soft)
    }

    static func spoken(_ change: Double, baseline: String) -> String {
        "\(change >= 0 ? "เพิ่มขึ้น" : "ลดลง") \(Int((abs(change) * 100).rounded())) เปอร์เซ็นต์ จาก \(baseline)"
    }
}

// MARK: - กราฟยอดวิวรายวัน

/// เส้นโค้งผ่านทุกจุดแบบไม่โด่งเกินค่าจริง (monotone cubic) · แกนตั้งเริ่มที่ 0 เสมอ — พื้นที่ใต้เส้นจึงบอกปริมาณจริง
struct TrendShape: Shape {
    let values: [Int]
    var closed = false

    static func points(_ values: [Int], in r: CGRect) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let hi = max(1, Double(values.max() ?? 1))
        return values.enumerated().map { i, v in
            CGPoint(x: r.minX + r.width * CGFloat(i) / CGFloat(values.count - 1),
                    y: r.maxY - r.height * CGFloat(Double(v) / hi))
        }
    }

    func path(in r: CGRect) -> Path {
        let p = TrendShape.points(values, in: r)
        guard p.count > 1 else { return Path() }
        let n = p.count
        // ความชันของแต่ละช่วง แล้วเฉลี่ยเป็นความชันที่จุด — ช่วงที่เปลี่ยนทิศ = 0 (ยอด/ก้นไม่โด่ง)
        let d = (0..<n - 1).map { (p[$0 + 1].y - p[$0].y) / (p[$0 + 1].x - p[$0].x) }
        var m = [CGFloat](repeating: 0, count: n)
        m[0] = d[0]; m[n - 1] = d[n - 2]
        for i in 1..<n - 1 { m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2 }
        for i in 0..<n - 1 where d[i] != 0 {
            let a = m[i] / d[i], b = m[i + 1] / d[i], s = a * a + b * b
            if s > 9 { let t = 3 / s.squareRoot(); m[i] = t * a * d[i]; m[i + 1] = t * b * d[i] }
        }
        var path = Path()
        path.move(to: p[0])
        for i in 0..<n - 1 {
            let dx = (p[i + 1].x - p[i].x) / 3
            path.addCurve(to: p[i + 1],
                          control1: CGPoint(x: p[i].x + dx, y: p[i].y + m[i] * dx),
                          control2: CGPoint(x: p[i + 1].x - dx, y: p[i + 1].y - m[i + 1] * dx))
        }
        if closed {
            path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            path.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            path.closeSubpath()
        }
        return path
    }
}

/// กราฟเดียวของหน้า — เส้นเดียว สีเดียว ป้ายสองจุด (วันที่ยอดสูงสุด + วันนี้) · แตะหรือกดค้างแล้วลากเพื่ออ่านค่ารายวัน
struct InsightChart: View {
    let data: StarInsight
    let mark: Color
    let drawn: Bool
    @Binding var scrub: Int?

    /// ที่ว่างเหนือกราฟสำหรับป้าย · ใต้กราฟสำหรับป้ายแกนนอน
    private let top: CGFloat = 30
    private let labels: CGFloat = 22
    /// นิ้วกดค้างอยู่บนกราฟ (กำลังไล่ดูทีละวัน)
    @State private var pressing = false

    private func index(at x: CGFloat, plot: CGRect, last: Int) -> Int {
        let t = (x - plot.minX) / max(1, plot.width)
        return min(max(Int((t * CGFloat(last)).rounded()), 0), last)
    }

    var body: some View {
        GeometryReader { g in
            let plot = CGRect(x: 5, y: top, width: g.size.width - 10, height: g.size.height - top - labels)
            let pts = TrendShape.points(data.daily, in: plot)
            let peak = data.peakIndex
            let last = data.daily.count - 1
            let focus = scrub ?? peak
            ZStack(alignment: .topLeading) {
                // เส้นฐาน (0) เส้นเดียว — ไม่มีตาราง
                Rectangle().fill(.white.opacity(0.16)).frame(width: g.size.width, height: 1)
                    .offset(y: plot.maxY)
                TrendShape(values: data.daily, closed: true).path(in: plot)
                    .fill(LinearGradient(colors: [mark.opacity(0.32), mark.opacity(0)],
                                         startPoint: .top, endPoint: .bottom))
                    .opacity(drawn ? 1 : 0)
                TrendShape(values: data.daily).path(in: plot)
                    .trim(from: 0, to: drawn ? 1 : 0)
                    .stroke(mark, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                if pts.count > 1 {
                    Group {
                        if scrub != nil {
                            // เส้นนำสายตาตอนลากนิ้ว: จากป้ายลงมาถึงเส้นฐาน
                            Rectangle().fill(.white.opacity(0.28))
                                .frame(width: 1, height: plot.maxY - top + 4)
                                .position(x: pts[focus].x, y: (plot.maxY + top - 4) / 2)
                        } else if last != peak {
                            dot(at: pts[last])
                            // ค่าของวันนี้ — จุดที่สองที่มีตัวเลขกำกับ (ยอดสูงสุด + วันนี้) พอให้กะสเกลของเส้นได้โดยไม่ต้องมีแกนตั้ง
                            if pts[last].y - 16 > top - 2 {
                                Text(StarInsight.fmt(data.daily[last])).font(.sh(13, .bold)).foregroundStyle(.white)
                                    .fixedSize()
                                    .position(x: g.size.width - 18, y: pts[last].y - 16)
                            }
                        }
                        dot(at: pts[focus])
                        tag(focus, peak: scrub == nil)
                            .position(x: min(max(pts[focus].x, tagHalf), g.size.width - tagHalf), y: top / 2 - 5)
                    }
                    .opacity(drawn ? 1 : 0)
                }
                // ป้ายแกนนอน: หัว-ท้ายชิดขอบ ที่เหลือกระจายเท่ากัน
                HStack(spacing: 0) {
                    ForEach(Array(data.axis.enumerated()), id: \.offset) { i, l in
                        if i > 0 { Spacer(minLength: 0) }
                        Text(l).font(.sh(12, .medium)).foregroundStyle(InsightInk.faint)
                    }
                }
                .frame(width: g.size.width - 2)
                .offset(x: 1, y: g.size.height - 16)
            }
            .contentShape(Rectangle())
            // แตะ = ดูค่าของวันนั้นครู่หนึ่ง · กดค้างแล้วลาก = ไล่ดูทีละวัน — ทั้งกราฟคือพื้นที่แตะ ไม่ต้องเล็งเส้น
            // (ไม่ใช้ลากเฉย ๆ: ลากบนกราฟต้องยังเลื่อนหน้า/ดึงรีเฟรชได้)
            .onTapGesture(coordinateSpace: .local) { p in
                let i = index(at: p.x, plot: plot, last: last)
                Haptics.impact(.light)
                scrub = scrub == i ? nil : i
                guard scrub != nil else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if scrub == i, !pressing { withAnimation(Motion.settle) { scrub = nil } }
                }
            }
            .gesture(PressScrub { x in
                guard let x else {
                    pressing = false
                    withAnimation(Motion.settle) { scrub = nil }
                    return
                }
                pressing = true
                let i = index(at: x, plot: plot, last: last)
                if i != scrub { Haptics.impact(.light) }
                scrub = i
            })
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("กราฟยอดวิวรายวัน")
        .accessibilityValue("สูงสุด \(data.dayNames[data.peakIndex]) \(data.daily[data.peakIndex]) ครั้ง \(data.peakNote) · วันนี้ \(data.daily.last ?? 0) ครั้ง")
    }

    private let tagHalf: CGFloat = 104

    /// จุดบนเส้น — สีเดียวกับเส้น มีวงสีพื้นคั่นให้อ่านออกตอนทับเส้น
    private func dot(at p: CGPoint) -> some View {
        Circle().fill(Color(red: 10 / 255, green: 10 / 255, blue: 12 / 255)).frame(width: 13, height: 13)
            .overlay(Circle().fill(mark).frame(width: 9, height: 9))
            .position(p)
    }

    /// ป้ายค่าบรรทัดเดียว: "948 · วันที่แชร์ลง IG Story" · ตอนลากนิ้ว = "622 · พฤหัสบดี"
    private func tag(_ i: Int, peak: Bool) -> some View {
        HStack(spacing: 5) {
            Text(StarInsight.fmt(data.daily[i])).font(.sh(14, .heavy)).foregroundStyle(.white)
            Text("·").font(.sh(13, .medium)).foregroundStyle(InsightInk.faint)
            Text(peak ? data.peakNote : data.dayNames[i]).font(.sh(13, .medium)).foregroundStyle(InsightInk.soft)
        }
        .lineLimit(1).fixedSize()
        .frame(width: tagHalf * 2)
    }
}

/// กดค้างแล้วลากบนกราฟ — ใช้ตัวจับของ UIKit เพราะ gesture ลากของ SwiftUI บนลูกของ ScrollView กันการเลื่อนหน้าทั้งแถบ
/// (ลองแล้วทั้ง simultaneousGesture และ LongPress.sequenced: ลากเริ่มบนกราฟแล้วหน้าไม่เลื่อน ดึงรีเฟรชไม่ได้)
/// ตัวนี้เริ่มทำงานหลังนิ้วนิ่ง 0.18 วินาทีเท่านั้น — ลากทันทียังเป็นการเลื่อนหน้าตามปกติ
struct PressScrub: UIGestureRecognizerRepresentable {
    /// ตำแหน่งนิ้วแนวนอนในกรอบกราฟ · nil = ยกนิ้วแล้ว
    let onChange: (CGFloat?) -> Void

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let g = UILongPressGestureRecognizer()
        g.minimumPressDuration = 0.18
        g.allowableMovement = 10
        return g
    }

    func handleUIGestureRecognizerAction(_ g: UILongPressGestureRecognizer, context: Context) {
        switch g.state {
        case .began, .changed: onChange(context.converter.localLocation.x)
        default: onChange(nil)
        }
    }
}

// MARK: - สีในระบบ OKLab — ไว้ดึง "เฉดสี" ของการ์ดมาใช้ที่ความสว่างเดียวกันทุกเฉด

struct OKLab {
    var l: Double, a: Double, b: Double
    var chroma: Double { (a * a + b * b).squareRoot() }
    var hue: Double { atan2(b, a) }

    init(_ c: RGB) {
        func lin(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        let r = lin(c.r), g = lin(c.g), bl = lin(c.b)
        let l_ = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * bl)
        let m_ = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * bl)
        let s_ = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * bl)
        l = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
        a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
        b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    }

    /// สีจากความสว่าง + ความสด + เฉด — ความสดเกินที่จอแสดงได้ = ลดลงทีละน้อยจนอยู่ในช่วง sRGB
    static func color(lightness: Double, chroma: Double, hue: Double) -> Color {
        func gam(_ v: Double) -> Double { v <= 0.0031308 ? 12.92 * v : 1.055 * pow(v, 1 / 2.4) - 0.055 }
        var c = chroma
        while c > 0 {
            let a = c * cos(hue), b = c * sin(hue)
            let l_ = pow(lightness + 0.3963377774 * a + 0.2158037573 * b, 3)
            let m_ = pow(lightness - 0.1055613458 * a - 0.0638541728 * b, 3)
            let s_ = pow(lightness - 0.0894841775 * a - 1.2914855480 * b, 3)
            let r = 4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_
            let g = -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_
            let bl = -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_
            if (0...1).contains(r), (0...1).contains(g), (0...1).contains(bl) {
                return Color(.sRGB, red: gam(r), green: gam(g), blue: gam(bl))
            }
            c -= 0.01
        }
        return Color(.sRGB, white: lightness, opacity: 1)
    }
}

// MARK: - ปุ่มเข้า ST★R Insight บนหน้า Star Profile

/// ปุ่มเล็กใต้ปุ่ม "ดูการ์ด" ในหมวด ST★R Card — ไอคอนกราฟ + ยอดวิวตัวเล็ก (ผู้ใช้ 4 ต.ค. 2569: แถบกราฟเต็มแถว
/// "ใหญ่ไปสำหรับหน้า Profile เอาแค่ปุ่มไป และตัวเลขเล็กๆพอ" แล้ว "ปุ่มไว้ข้างล่างดู card") · วัสดุเดียวกับปุ่มในหมวดนั้น
struct InsightChip: View {
    let onOpen: () -> Void
    private let data = StarInsight.mock(.week)

    var body: some View {
        Button {
            Haptics.impact(.light)
            onOpen()
        } label: {
            HStack(spacing: 5) {
                PIcon(.chartLineUp, size: 13, weight: .bold).foregroundStyle(GL.ink)
                if data.isEmpty {
                    Text("สถิติ").font(.sh(12.5, .bold)).foregroundStyle(GL.ink)
                } else {
                    Text(StarInsight.fmt(data.views)).font(.sh(12.5, .bold)).foregroundStyle(GL.ink).monospacedDigit()
                    Text("วิว").font(.sh(12, .medium)).foregroundStyle(GL.muted)
                }
                PIcon(.caretRight, size: 9, weight: .bold).foregroundStyle(GL.hint)
            }
            .frame(maxWidth: .infinity).frame(height: 32)
            .background(Capsule().fill(.white.opacity(0.85)))
            .overlay(Capsule().strokeBorder(GL.ink.opacity(0.1), lineWidth: 1))
            // พื้นที่แตะยืดลงล่าง (ข้างบนติดปุ่มดูการ์ด) โดยไม่ดันความสูงของหมวด
            .padding(.bottom, 10).contentShape(Rectangle())
        }
        .buttonStyle(DockPress())
        .padding(.bottom, -10)
        .accessibilityLabel(data.isEmpty ? "ดูสถิติคนดูการ์ด" : "ดูสถิติ ยอดวิว 7 วันล่าสุด \(data.views) ครั้ง")
    }
}
