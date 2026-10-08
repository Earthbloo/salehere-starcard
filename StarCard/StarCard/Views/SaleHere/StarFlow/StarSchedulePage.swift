import SwiftUI
import PhosphorSwift

// MARK: - ตารางงาน (ผู้ใช้ 5 ต.ค. 2569)
//
// หน้าต่อจาก Star Profile — เปิดมาเจอ "วันนี้ต้องทำอะไร" ก่อน ไม่ใช่ตารางเดือน
// ผู้ใช้สั่ง "ต้อง Minimal UI ที่สุด และเพิ่มงานไหน Sale Here ต้องชัด อันไหนธรรมดาต้องชัด" จึงแยกสองแบบด้วยของสองอย่างเท่านั้น:
//   · **ตราหน้าแถว** — งาน Sale Here = โลโก้แบรนด์ + ตรา Sale Here แดงเกาะมุม · งานทั่วไป = วงเทากับอักษรตัวแรก
//   · **ท้ายแถว** — งาน Sale Here ไม่มีช่องติ๊ก (สถานะมาจากแอปเอง) · งานทั่วไปมีวงติ๊ก
// หน้ารายการไม่มีแท็บ ไม่มีตัวกรอง ไม่มีชิป — แถบ 7 วัน + รายการ + ปุ่มเดียว
// ฟอร์ม "ลงงาน" สามขั้น ขั้นละจอ (ผู้ใช้: "อันนี้มันยาวลงไปเรื่อยๆ") · แพลตฟอร์มเป็นช่องติ๊กที่สลับแท็บได้ · จำนวนใช้ − n +
// ขั้นสามไม่มีสวิตช์ (ผู้ใช้: "ตรงนี้ดูลำบาก") — วันเป็นแถว "+ ใส่วัน" · ได้อะไรเลือกหนึ่งในสาม
// "ข้อห้ามจากแบรนด์" และ "จ่ายภายใน" เอาออกจากฟอร์มแล้ว (ผู้ใช้ 5 ต.ค. 2569) — วันครบกำหนดรับเงินใช้ 30 วันหลังลง

// MARK: ชิ้นส่วนร่วม

/// ตราหน้าแถว — ตัวแยก "งาน Sale Here" กับ "งานทั่วไป"
struct JobMark: View {
    let job: StarJob
    var size: CGFloat = 38

    var body: some View {
        if job.isSaleHere {
            Group {
                if let logo = job.logo {
                    Image(logo).resizable().aspectRatio(contentMode: .fill)
                } else {
                    SH.red
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(SH.red, lineWidth: 1.5))
            .overlay(alignment: .bottomTrailing) {
                Image("ic-salehere-logo-red42").resizable().aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.42, height: size * 0.42)
                    .background(Circle().fill(.white).padding(-1.5))
                    .offset(x: 3, y: 3)
            }
        } else {
            Text(String(job.brand.prefix(1)).uppercased())
                .font(.sh(size * 0.4, .bold)).foregroundStyle(GL.muted)
                .frame(width: size, height: size)
                .background(Circle().fill(PK.fieldFill))
        }
    }
}

/// วงติ๊กของขั้น — เส้นประ = กำลังรอคนอื่น
struct StepCheck: View {
    let done: Bool
    var wait = false
    var size: CGFloat = 26
    /// ติ๊กเองไม่ได้ (งาน Sale Here) — ขั้นที่ยังไม่ถึงเป็นจุดเทา ไม่ใช่วงให้กด
    var locked = false

    var body: some View {
        ZStack {
            if done {
                Circle().fill(GL.green)
                PIcon(.check, size: size * 0.5, weight: .bold).foregroundStyle(.white)
            } else if locked {
                Circle().fill(PK.line2).frame(width: 8, height: 8)
            } else {
                Circle().strokeBorder(wait ? GL.hint : PK.line2, style: StrokeStyle(lineWidth: 1.6, dash: wait ? [3, 3] : []))
            }
        }
        .frame(width: size, height: size)
    }
}

/// แถวทางเข้าบนหน้า Star Profile — การ์ดขาวแถวเดียว: งานถัดไปหนึ่งบรรทัด
struct ScheduleEntryRow: View {
    let onOpen: () -> Void
    @State private var schedule = StarSchedule.shared

    var body: some View {
        Button {
            Haptics.impact(.light)
            onOpen()
        } label: {
            HStack(spacing: 12) {
                PIcon(.calendarDots, size: 20, weight: .bold).foregroundStyle(GL.ink)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(PK.fieldFill))
                VStack(alignment: .leading, spacing: 1) {
                    Text("ตารางงาน").font(.sh(15, .bold)).foregroundStyle(GL.ink)
                    Text(line).font(.sh(12.5)).foregroundStyle(GL.muted).lineLimit(1)
                }
                Spacer(minLength: 4)
                PIcon(.caretRight, size: 13, weight: .bold).foregroundStyle(GL.hint)
            }
            .padding(14)
            .background(PK.shape(22).fill(.white))
            .overlay(PK.shape(22).strokeBorder(GL.ink.opacity(0.06), lineWidth: 1))
            .shadow(color: GL.ink.opacity(0.07), radius: 15, y: 12)
            .contentShape(PK.shape(22))
        }
        .buttonStyle(DockPress())
        .accessibilityLabel("ตารางงาน \(line)")
    }

    private var line: String {
        guard let n = schedule.next else { return "ยังไม่มีงาน · ลงงานแรก" }
        let when = SD.label(n.step.date) + (n.step.time.map { " \($0)" } ?? "")
        return "\(when) · \(n.step.label) \(n.job.brand)"
    }
}

// MARK: - หน้ารายการ

struct StarSchedulePage: View {
    let onClose: () -> Void

    @State private var schedule = StarSchedule.shared
    @State private var sel = SD.today
    enum Mode { case day, month }
    /// หน้าวัน (แถบสัปดาห์ + รายการ) หรือหน้าเดือน (ตารางเต็มจอ) — สลับกันแบบ Calendar ของ iOS
    @State private var mode: Mode = UserDefaults.standard.bool(forKey: "scheduleMonth") ? .month : .day
    @State private var openJob: UUID?
    @State private var adding = false
    @State private var ask: ScheduleAsk?
    @State private var toast: String?
    @State private var toastToken = 0

    var body: some View {
        ZStack(alignment: .top) {
            GL.bg.ignoresSafeArea()
            if mode == .month {
                monthView.transition(.opacity)
            } else {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    monthStrip.padding(.top, 12)
                    if schedule.jobs.isEmpty { empty } else { list }
                }
                .padding(.horizontal, 16)
                .padding(.top, 64)
                .padding(.bottom, 130)
            }
            .transition(.opacity)
            }
            topBar

            if let id = openJob, let job = schedule.job(id) {
                JobDetailPage(job: job, onBack: { withAnimation(Motion.page) { openJob = nil } }, onTick: tick)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .overlay(alignment: .bottom) { bottom }
        .overlay {
            if adding {
                AddJobSheet(onClose: { withAnimation(Motion.settle) { adding = false } }) { job in
                    schedule.add(job)
                    withAnimation(Motion.settle) { adding = false; sel = SD.today; openJob = nil }
                    say("ลงงานแล้ว · ตั้งเตือน \(job.steps.count) อย่าง")
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            // ทางลัดไว้แคปจอ: `-scheduleDemo YES` = เปิดฟอร์มลงงานที่กรอกตัวอย่างไว้ (ไม่บันทึกจนกว่าจะกดบันทึกเอง)
            if UserDefaults.standard.bool(forKey: "scheduleDemo") { adding = true }
        }
    }

    // MARK: ปฏิทิน — สองมุมมอง หัวเดียวกัน
    //
    // ลำดับที่ผู้ใช้สั่ง (5 ต.ค. 2569): ส่งหน้า Calendar ของ iOS มา → "รายเดือนต้องสลับ เป็นแบบ calendar ใน ios" → "ไม่เอา เอาเป็น Toggle สลับ 2 แบบ"
    // → เห็นหน้าเดือนแบบเลื่อนต่อเนื่องแล้วสั่ง "เอาเป็นหน้าเดียว แล้วสลับเดือนเอา ไม่ต้องเลื่อน และใน toggle mode วัน มันก็มี Title เดือน สลับได้เหมือนกัน"
    // จึงเป็น: หัว "ตุลาคม 2569  ‹ ›" เหมือนกันทั้งสองโหมด · โหมดวัน = แถบวันของเดือนนั้น + รายการของวันที่เลือก · โหมดเดือน = ตารางเดือนเดียวพอดีจอ
    // ไม่มีตารางรายชั่วโมง: งานของ Star ส่วนใหญ่เป็นเดดไลน์ทั้งวัน · สีแยกชนิดงานทุกที่: แดง = Sale Here · เทา/ดำ = งานทั่วไป

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(schedule.pendingMoney > 0 ? "ตารางงาน · รอรับ \(SD.baht(schedule.pendingMoney))" : "ตารางงาน")
                .font(.sh(13, .bold)).foregroundStyle(GL.muted)
            HStack(spacing: 6) {
                Text(SD.monthTitle(sel)).font(.sh(28, .heavy)).foregroundStyle(GL.ink).lineLimit(1).minimumScaleFactor(0.8)
                    .contentTransition(.opacity)
                Spacer(minLength: 4)
                monthArrow(.caretLeft, -1)
                monthArrow(.caretRight, 1)
            }
        }
    }

    private func monthArrow(_ icon: Ph, _ dir: Int) -> some View {
        Button {
            Haptics.impact(.light)
            let m = SD.cal.date(byAdding: .month, value: dir, to: SD.firstOfMonth(sel)) ?? sel
            withAnimation(Motion.snap) { sel = m == SD.firstOfMonth(SD.today) ? SD.today : m }
        } label: {
            PIcon(icon, size: 14, weight: .bold).foregroundStyle(GL.ink)
                .frame(width: 38, height: 38)
                .background(Circle().fill(.white))
                .overlay(Circle().strokeBorder(PK.line, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dir < 0 ? "เดือนก่อน" : "เดือนถัดไป")
    }

    /// โหมดวัน: แถบวันของทั้งเดือน เลื่อนซ้ายขวา — วันที่เลือกอยู่กลางเสมอ
    private var monthStrip: some View {
        let first = SD.firstOfMonth(sel)
        let count = SD.cal.range(of: .day, in: .month, for: first)?.count ?? 30
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<count, id: \.self) { i in
                        let d = SD.day(i, from: first)
                        dayCell(d).id(d)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear { proxy.scrollTo(sel, anchor: .center) }
            .onChange(of: sel) { _, v in withAnimation(Motion.snap) { proxy.scrollTo(v, anchor: .center) } }
        }
        .padding(.horizontal, -16)
    }

    private func dayCell(_ d: Date) -> some View {
        let on = d == sel
        let marks = schedule.marks(on: d)
        let total = marks.saleHere + marks.own
        return Button {
            Haptics.impact(.light)
            withAnimation(Motion.snap) { sel = d }
        } label: {
            VStack(spacing: 1) {
                Text(SD.weekday(d)).font(.sh(11)).foregroundStyle(on ? .white.opacity(0.75) : GL.hint)
                Text("\(SD.dayNumber(d))").font(.sh(16, .semibold)).monospacedDigit()
                    .foregroundStyle(on ? .white : (d == SD.today ? SH.red : GL.ink))
                // จำนวนเรื่องที่ยังต้องทำของวันนั้น แทนจุด — เลขเดียว รวมทุกชนิดงาน
                // (ผู้ใช้ 5 ต.ค. 2569: "จุดๆ เปลี่ยนเป็นจำนวนงาน" → เห็นป้ายแดง/เทาแยกชนิดแล้วสั่ง "ไม่ต้องแยก รวมงานไปเลย")
                Group {
                    if total > 0 { countBadge(total, fill: on ? .white.opacity(0.24) : PK.fieldFocus, ink: on ? .white : GL.ink) }
                }
                .frame(height: 15).padding(.top, 2)
            }
            .frame(width: 48, height: 66)
            // ทุกวันมีกรอบ — วันที่เลือกทึบดำ วันอื่นขาวขอบเทา (ผู้ใช้ 5 ต.ค. 2569: "วันอื่นต้องมีกรอบทุกวัน")
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(on ? GL.ink : .white))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(on ? .clear : PK.line, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(SD.label(d))\(total > 0 ? " \(total) งาน" : "")")
    }

    private func countBadge(_ n: Int, fill: Color, ink: Color) -> some View {
        Text("\(n)").font(.sh(10, .bold)).monospacedDigit().foregroundStyle(ink)
            .frame(minWidth: 15).frame(height: 15)
            .background(Capsule().fill(fill))
    }

    /// โหมดเดือน: เดือนเดียวพอดีจอ ไม่เลื่อน — เปลี่ยนเดือนด้วยลูกศรที่หัว
    private var monthView: some View {
        let first = SD.firstOfMonth(sel)
        let lead = (SD.cal.component(.weekday, from: first) + 5) % 7
        let count = SD.cal.range(of: .day, in: .month, for: first)?.count ?? 30
        let weeks = (lead + count + 6) / 7
        return VStack(alignment: .leading, spacing: 0) {
            header.padding(.horizontal, 16)
            HStack(spacing: 0) {
                ForEach([1, 2, 3, 4, 5, 6, 0], id: \.self) { w in
                    Text(SD.weekdays[w]).font(.sh(11.5, .medium)).foregroundStyle(GL.hint).frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 16).padding(.bottom, 8)
            ForEach(0..<weeks, id: \.self) { w in
                PK.line.frame(height: 1)
                HStack(alignment: .top, spacing: 0) {
                    ForEach(0..<7, id: \.self) { c in
                        let i = w * 7 + c - lead
                        if i >= 0 && i < count { monthCell(SD.day(i, from: first)) } else { Color.clear.frame(maxWidth: .infinity) }
                    }
                }
                .frame(height: weeks > 5 ? 82 : 92)
            }
            PK.line.frame(height: 1)
            Spacer(minLength: 0)
        }
        .padding(.top, 64)
    }

    /// ช่องวันของโหมดเดือน — เลขวัน (วันนี้ = วงแดง) + ป้ายงานสูงสุด 2 ป้าย แดง = Sale Here · เทา = งานทั่วไป
    private func monthCell(_ d: Date) -> some View {
        let all = schedule.entries.filter { $0.step.date == d }.sorted { !$0.step.done && $1.step.done }
        let today = d == SD.today
        return Button {
            Haptics.impact(.light)
            withAnimation(Motion.settle) { sel = d; mode = .day }
        } label: {
            VStack(spacing: 3) {
                Text("\(SD.dayNumber(d))").font(.sh(15, today ? .bold : .medium)).monospacedDigit()
                    .foregroundStyle(today ? .white : GL.ink)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(today ? SH.red : .clear))
                ForEach(all.prefix(2)) { e in
                    Text(e.job.brand).font(.sh(9.5, .semibold)).lineLimit(1)
                        .foregroundStyle(e.job.isSaleHere ? SH.red : GL.ink)
                        .opacity(e.step.done ? 0.45 : 1)
                        .padding(.horizontal, 4).frame(maxWidth: .infinity, alignment: .leading).frame(height: 16)
                        .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(e.job.isSaleHere ? SH.red.opacity(0.12) : PK.fieldFocus))
                }
                if all.count > 2 { Text("+\(all.count - 2)").font(.sh(9.5)).foregroundStyle(GL.muted) }
                Spacer(minLength: 0)
            }
            .padding(.top, 5).padding(.horizontal, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(SD.label(d)) \(all.isEmpty ? "ไม่มีงาน" : "\(all.count) อย่าง")")
    }

    // แถบบน: ‹ กลับ Star Profile เสมอ · ขวา = วันนี้ + สวิตช์ วัน | เดือน
    // (ผู้ใช้ 5 ต.ค. 2569 เห็นรุ่นปุ่ม "‹ ตุลาคม" ถอยไปหน้าเดือนแบบ iOS แล้วสั่ง "ไม่เอา เอาเป็น Toggle สลับ 2 แบบ")

    private var topBar: some View {
        HStack(spacing: 8) {
            GlassCircleButton(symbol: .caretLeft, action: onClose)
            Spacer()
            if sel != SD.today {
                glassPill {
                    Haptics.impact(.light)
                    withAnimation(Motion.snap) { sel = SD.today }
                } label: {
                    Text("วันนี้").font(.sh(14, .bold)).foregroundStyle(GL.ink)
                }
                .transition(.opacity)
            }
            modeToggle
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach([Mode.day, .month], id: \.self) { m in
                let on = mode == m
                Button {
                    guard !on else { return }
                    Haptics.impact(.light)
                    withAnimation(Motion.settle) { mode = m }
                } label: {
                    Text(m == .day ? "วัน" : "เดือน").font(.sh(14, on ? .bold : .medium))
                        .foregroundStyle(on ? .white : GL.muted)
                        .frame(width: 58, height: 36)
                        .background(Capsule().fill(on ? GL.ink : .clear))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(m == .day ? "ดูรายวัน" : "ดูทั้งเดือน")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(4)
        .glassEffect(.regular.tint(.white.opacity(0.55)), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.95), lineWidth: 1))
        .shadow(color: GL.ink.opacity(0.08), radius: 7, y: 4)
    }

    private func glassPill<L: View>(action: @escaping () -> Void, @ViewBuilder label: () -> L) -> some View {
        Button(action: action) {
            label()
                .padding(.horizontal, 14).frame(height: 44)
                .contentShape(Capsule())
                .glassEffect(.regular.tint(.white.opacity(0.55)).interactive(), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.95), lineWidth: 1))
                .shadow(color: GL.ink.opacity(0.08), radius: 7, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: รายการ

    // แถบวัน = ตัวเลือกวัน: แตะวันไหน เห็นเฉพาะงานของวันนั้น (ผู้ใช้ 5 ต.ค. 2569: "กดวันที่ 6 แต่มี พรุ่งนี้ และวันอื่น โครตจะงง")
    // รุ่นแรกแถบวันเป็น "เริ่มดูจากวันนี้" แล้วไล่วันถัด ๆ ไปต่อท้าย — คนอ่านว่าเป็นตัวกรองวัน จึงงงที่เห็นวันอื่นปน
    // หัวรายการมีทั้งคำ (วันนี้/พรุ่งนี้) และวันที่ ให้ตรงกับเลขที่แตะ · วันว่าง = บอกงานถัดไปเป็นแถวเดียวให้กดข้ามไป
    @ViewBuilder
    private var list: some View {
        let overdue = sel == SD.today ? schedule.overdue : []
        let rows = schedule.entries.filter { $0.step.date == sel }.sorted { ($0.step.time ?? "99") < ($1.step.time ?? "99") }
        if !overdue.isEmpty {
            label("ค้างอยู่", red: true)
            card(overdue)
        }
        label(SD.title(sel))
        if rows.isEmpty {
            Text("ไม่มีงาน").font(.sh(13.5)).foregroundStyle(GL.hint)
                .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                .background(PK.shape(18).fill(.white))
                .overlay(PK.shape(18).strokeBorder(PK.line, lineWidth: 1))
            if let next = schedule.nextDay(after: sel) {
                Button {
                    Haptics.impact(.light)
                    withAnimation(Motion.snap) { sel = next }
                } label: {
                    HStack(spacing: 6) {
                        Text("งานถัดไป \(SD.label(next))").font(.sh(13.5, .semibold)).foregroundStyle(GL.ink)
                        PIcon(.caretRight, size: 11, weight: .bold).foregroundStyle(GL.hint)
                    }
                    .frame(height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 2).padding(.top, 4)
            }
        } else {
            card(rows)
        }
    }

    private func label(_ text: String, red: Bool = false) -> some View {
        Text(text).font(.sh(12.5, .bold)).foregroundStyle(red ? SH.red : GL.muted)
            .padding(.top, 18).padding(.bottom, 8).padding(.leading, 2)
    }

    // การ์ดงาน — หนึ่งใบต่อหนึ่งงานในวันนั้น (ผู้ใช้ 5 ต.ค. 2569: "แต่ละ social รวบเป็น Task เดียวดิ เป็น card เดียวก็ได้ แบบนี้งง ทำ card สำหรับงาน Influencer")
    // รุ่นก่อนแตกเป็นแถวละแพลตฟอร์ม ("ลง IG · Oriental" / "ลง YouTube · Oriental") — งานเดียวกันแต่ดูเป็นสองงาน
    // การ์ด = หัว (แบรนด์ + ชื่องาน · แตะเปิดหน้างาน) แล้วเรื่องที่ต้องทำวันนั้น: "ลงคอนเทนต์" เป็นเรื่องเดียว ติ๊กเดียว มีทุกแพลตฟอร์มเรียงอยู่ข้างใน
    private func card(_ rows: [StarSchedule.Entry]) -> some View {
        var order: [UUID] = []
        for e in rows where !order.contains(e.job.id) { order.append(e.job.id) }
        return VStack(spacing: 10) {
            ForEach(order, id: \.self) { id in
                if let job = schedule.job(id) { jobCard(job, rows.filter { $0.job.id == id }.map(\.step)) }
            }
        }
    }

    private func jobCard(_ job: StarJob, _ steps: [JobStep]) -> some View {
        VStack(spacing: 0) {
            Button {
                Haptics.impact(.light)
                withAnimation(Motion.page) { openJob = job.id }
            } label: {
                HStack(spacing: 12) {
                    JobMark(job: job)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(job.brand).font(.sh(15.5, .bold)).foregroundStyle(GL.ink).lineLimit(1)
                        HStack(spacing: 0) {
                            if job.isSaleHere { Text("Sale Here · ").font(.sh(12.5, .bold)).foregroundStyle(SH.red) }
                            Text(job.isSaleHere ? (job.episode ?? job.title) : job.title).font(.sh(12.5)).foregroundStyle(GL.muted).lineLimit(1)
                        }
                    }
                    Spacer(minLength: 4)
                    PIcon(.caretRight, size: 12, weight: .bold).foregroundStyle(GL.hint)
                }
                .padding(.horizontal, 14).frame(height: 64).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            ForEach(steps) { s in
                PK.line.frame(height: 1)
                action(job, s)
            }
        }
        .background(PK.shape(20).fill(.white))
        .overlay(PK.shape(20).strokeBorder(PK.line, lineWidth: 1))
    }

    private func action(_ job: StarJob, _ s: JobStep) -> some View {
        let late = s.date < SD.today && !s.done
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Text(s.label).font(.sh(14.5, s.done ? .medium : .semibold))
                        .foregroundStyle(s.done ? GL.hint : GL.ink).strikethrough(s.done, color: GL.hint)
                    if let t = s.time { Text(t).font(.sh(12.5)).monospacedDigit().foregroundStyle(GL.muted) }
                    if s.kind == .pay { Text(SD.baht(job.fee)).font(.sh(12.5)).monospacedDigit().foregroundStyle(GL.muted) }
                    if late { Text("เกิน \(SD.gap(SD.today, s.date)) วัน").font(.sh(12.5, .semibold)).foregroundStyle(SH.red) }
                }
                if let place = s.sub, s.kind == .event {
                    Text(place).font(.sh(13.5)).foregroundStyle(s.done ? GL.hint : GL.ink)
                }
                if s.kind == .post {
                    ForEach(job.posts.filter { $0.date == s.date }) { p in
                        HStack(spacing: 8) {
                            Image(p.platform.icon).resizable().aspectRatio(contentMode: .fit).frame(width: 22, height: 22).clipShape(Circle())
                            Text(p.itemsText).font(.sh(13.5)).foregroundStyle(s.done ? GL.hint : GL.ink)
                        }
                    }
                }
            }
            Spacer(minLength: 4)
            if job.isSaleHere {
                // งาน Sale Here ติ๊กเองไม่ได้ — สถานะมาจากแอป
                StepCheck(done: s.done, locked: true)
            } else {
                Button { tick(job.id, s.id) } label: {
                    StepCheck(done: s.done, wait: s.isWait, size: 28).frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, -8)
                .accessibilityLabel("\(s.done ? "เสร็จแล้ว" : "ติ๊กเสร็จ") \(s.label) \(job.brand)")
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var empty: some View {
        VStack(spacing: 4) {
            Text("ยังไม่มีงานในตาราง").font(.sh(17, .bold)).foregroundStyle(GL.ink)
            Text("ลงงานที่รับไว้ แอปจำเดดไลน์ให้\nงาน Sale Here ขึ้นเอง").font(.sh(13.5)).foregroundStyle(GL.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.top, 70)
    }

    // MARK: ล่างจอ — ปุ่มเดียว หรือคำถามตามจังหวะ

    @ViewBuilder
    private var bottom: some View {
        VStack(spacing: 10) {
            if let toast {
                Text(toast).font(.sh(13, .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 16).frame(height: 38)
                    .background(Capsule().fill(GL.ink))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            if let ask {
                askCard(ask).transition(.move(edge: .bottom).combined(with: .opacity))
            } else if openJob == nil && !adding {
                Button {
                    Haptics.impact(.medium)
                    withAnimation(Motion.settle) { adding = true }
                } label: {
                    HStack(spacing: 8) {
                        PIcon(.plus, size: 16, weight: .bold)
                        Text("ลงงาน").font(.sh(16, .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Capsule().fill(GL.ink))
                    .shadow(color: GL.ink.opacity(0.18), radius: 18, y: 12)
                    .contentShape(Capsule())
                }
                .buttonStyle(DockPress())
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    private func askCard(_ a: ScheduleAsk) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(a.title).font(.sh(15, .bold)).foregroundStyle(.white)
                Text(a.sub).font(.sh(12.5)).foregroundStyle(.white.opacity(0.65))
            }
            HStack(spacing: 8) {
                askButton(a.no, light: false) { withAnimation(Motion.settle) { ask = nil } }
                askButton(a.yes, light: true) {
                    schedule.answer(a)
                    withAnimation(Motion.settle) { ask = nil }
                    say(a.doneText)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(GL.ink))
        .shadow(color: GL.ink.opacity(0.3), radius: 22, y: 12)
    }

    private func askButton(_ title: String, light: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Text(title).font(.sh(14, .bold)).foregroundStyle(light ? GL.ink : .white)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(light ? .white : .white.opacity(0.14)))
        }
        .buttonStyle(DockPress())
    }

    private func tick(_ job: UUID, _ step: UUID) {
        Haptics.impact(.light)
        var next: ScheduleAsk?
        withAnimation(Motion.snap) { next = schedule.toggle(job: job, step: step) }
        withAnimation(Motion.settle) { ask = next }
    }

    private func say(_ text: String) {
        toastToken += 1
        let token = toastToken
        withAnimation(Motion.settle) { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if token == toastToken { withAnimation(Motion.settle) { toast = nil } }
        }
    }
}

// MARK: - หน้างาน

private struct JobDetailPage: View {
    let job: StarJob
    let onBack: () -> Void
    let onTick: (UUID, UUID) -> Void
    @State private var schedule = StarSchedule.shared
    @State private var confirmDelete = false

    var body: some View {
        ZStack(alignment: .top) {
            GL.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        JobMark(job: job, size: 52)
                        VStack(alignment: .leading, spacing: 3) {
                            sourceTag
                            Text(job.brand).font(.sh(24, .heavy)).foregroundStyle(GL.ink).lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                    Text([job.episode, job.title].compactMap { $0 }.joined(separator: " · ")).font(.sh(14)).foregroundStyle(GL.muted).padding(.top, 8)

                    head("ลงอะไร ที่ไหน วันไหน")
                    box {
                        ForEach(Array(job.posts.enumerated()), id: \.element.id) { i, p in
                            if i > 0 { divider }
                            HStack(spacing: 12) {
                                Image(p.platform.icon).resizable().aspectRatio(contentMode: .fit).frame(width: 28, height: 28).clipShape(Circle())
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(p.platform.name).font(.sh(14.5, .semibold)).foregroundStyle(GL.ink)
                                    Text(p.itemsText).font(.sh(12.5)).foregroundStyle(GL.muted)
                                }
                                Spacer()
                                Text(SD.label(p.date)).font(.sh(13)).foregroundStyle(GL.muted)
                            }
                            .frame(minHeight: 54)
                        }
                    }

                    head(job.isSaleHere ? "ขั้นตอน · อัปเดตเองจาก Sale Here" : "ขั้นตอน")
                    box {
                        ForEach(Array(job.steps.filter { $0.kind != .pay }.enumerated()), id: \.element.id) { i, s in
                            if i > 0 { divider }
                            stepRow(s)
                        }
                    }

                    if job.fee > 0 { money.padding(.top, 12) }

                    if !job.terms.isEmpty {
                        head("ข้อห้ามจากแบรนด์")
                        box {
                            ForEach(Array(job.terms.enumerated()), id: \.offset) { i, t in
                                if i > 0 { divider }
                                HStack {
                                    Text(t.text).font(.sh(14.5, .semibold)).foregroundStyle(GL.ink)
                                    Spacer()
                                    Text("ถึง \(SD.short(t.end))").font(.sh(13)).foregroundStyle(GL.muted)
                                }
                                .frame(minHeight: 50)
                            }
                        }
                    }

                    if !job.isSaleHere {
                        box {
                            Toggle(isOn: Binding(get: { job.showOnCard }, set: { schedule.setShow(job.id, $0) })) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("โชว์บน Star Card").font(.sh(14.5, .semibold)).foregroundStyle(GL.ink)
                                    Text("แบรนด์ไม่เห็นค่าตัว").font(.sh(12.5)).foregroundStyle(GL.muted)
                                }
                            }
                            .tint(GL.green)
                            .frame(minHeight: 56)
                        }
                        .padding(.top, 12)
                        // ลบงาน — ยืนยันด้วยการแตะซ้ำที่เดิม (แผ่นยืนยันของระบบไม่ขึ้นเสมอในหน้าที่ซ้อนใน ZStack ของ shell)
                        Button {
                            Haptics.impact(confirmDelete ? .medium : .light)
                            if confirmDelete {
                                onBack()
                                schedule.remove(job.id)
                            } else {
                                withAnimation(Motion.snap) { confirmDelete = true }
                            }
                        } label: {
                            Text(confirmDelete ? "แตะอีกครั้งเพื่อลบ" : "ลบงานนี้").font(.sh(14.5, .semibold)).foregroundStyle(SH.red)
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(PK.shape(18).fill(confirmDelete ? SH.red.opacity(0.09) : .clear))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 14)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 64)
                .padding(.bottom, 150)
            }
            HStack {
                GlassCircleButton(symbol: .caretLeft, action: onBack)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 8)
        }
    }

    /// ป้ายบอกชนิดงาน — แดงมีโลโก้ = Sale Here · เทา = งานทั่วไป
    private var sourceTag: some View {
        HStack(spacing: 5) {
            if job.isSaleHere {
                Image("ic-salehere-logo-red42").resizable().aspectRatio(contentMode: .fit).frame(width: 13, height: 13)
            }
            Text(job.isSaleHere ? "งาน Sale Here" : "งานทั่วไป · เห็นคนเดียว").font(.sh(12, .bold))
        }
        .foregroundStyle(job.isSaleHere ? SH.red : GL.muted)
        .padding(.horizontal, 9).frame(height: 24)
        .background(Capsule().fill(job.isSaleHere ? SH.red.opacity(0.09) : PK.fieldFill))
    }

    private func stepRow(_ s: JobStep) -> some View {
        HStack(spacing: 12) {
            if job.isSaleHere {
                StepCheck(done: s.done, locked: true)
            } else {
                Button { onTick(job.id, s.id) } label: {
                    StepCheck(done: s.done, wait: s.isWait).frame(width: 34, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, -4)
                .accessibilityLabel("\(s.done ? "เสร็จแล้ว" : "ติ๊กเสร็จ") \(s.label)")
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(s.label).font(.sh(14.5, s.done ? .medium : .semibold))
                    .foregroundStyle(s.done ? GL.hint : GL.ink).strikethrough(s.done, color: GL.hint)
                if s.kind == .post {
                    Text(job.posts.filter { $0.date == s.date }.map(\.platform.short).joined(separator: " · ")).font(.sh(12.5)).foregroundStyle(GL.muted)
                } else if let sub = s.sub { Text(sub).font(.sh(12.5)).foregroundStyle(GL.muted) }
            }
            Spacer()
            Text(SD.label(s.date) + (s.time.map { " \($0)" } ?? "")).font(.sh(13, s.date == SD.today && !s.done ? .bold : .regular))
                .foregroundStyle(s.date == SD.today && !s.done ? GL.ink : GL.muted)
        }
        .frame(minHeight: 50)
    }

    /// เงินของงาน — ยอดเดียว ปุ่มเดียว (ไม่มีวันครบกำหนด/หัก ณ ที่จ่ายแล้ว ฟอร์มไม่ได้ถาม)
    private var money: some View {
        let paid = job.paid == true
        return box {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(SD.baht(job.fee)).font(.sh(24, .bold)).monospacedDigit().foregroundStyle(GL.ink)
                    Text(paid ? "ได้รับแล้ว" : "ยังไม่ได้รับ · เห็นคนเดียว").font(.sh(12.5)).foregroundStyle(GL.muted)
                }
                Spacer()
                Button {
                    Haptics.impact(.light)
                    withAnimation(Motion.snap) { schedule.setPaid(job.id, !paid) }
                } label: {
                    Text(paid ? "รับแล้ว ✓" : "รับแล้ว").font(.sh(13.5, .bold))
                        .foregroundStyle(paid ? GL.greenInk : .white)
                        .padding(.horizontal, 16).frame(height: 38)
                        .background(Capsule().fill(paid ? GL.greenTint : GL.ink))
                }
                .buttonStyle(DockPress())
            }
            .padding(.vertical, 12)
        }
    }

    private func head(_ text: String) -> some View {
        Text(text).font(.sh(12.5, .bold)).foregroundStyle(GL.muted).padding(.top, 20).padding(.bottom, 8).padding(.leading, 2)
    }
    private var divider: some View { PK.line.frame(height: 1) }
    private func box<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PK.shape(18).fill(.white))
            .overlay(PK.shape(18).strokeBorder(PK.line, lineWidth: 1))
    }
}

// MARK: - ลงงาน (งานทั่วไป) — สามขั้น

private struct AddJobSheet: View {
    let onClose: () -> Void
    let onSave: (StarJob) -> Void

    @State private var d = UserDefaults.standard.bool(forKey: "scheduleDemo") ? JobDraft.demo : JobDraft()
    @State private var step = max(1, min(3, UserDefaults.standard.integer(forKey: "scheduleStep")))
    private let titles = ["แบรนด์และงาน", "ลงอะไรบ้าง", "ไปหน้างาน และเงิน"]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.42).ignoresSafeArea().onTapGesture { onClose() }
            VStack(alignment: .leading, spacing: 14) {
                // หัวแผ่น: ชื่อแผ่นอยู่กลางเสมอ (ผู้ใช้ 5 ต.ค. 2569: "BottomSheet ต้องมี Title") · ซ้าย = ย้อน · ขวา = ปิด
                ZStack {
                    Text("ลงงาน").font(.sh(16, .bold)).foregroundStyle(GL.ink)
                    HStack {
                        if step > 1 {
                            Button { Haptics.impact(.light); withAnimation(Motion.snap) { step -= 1 } } label: {
                                PIcon(.caretLeft, size: 14, weight: .bold).foregroundStyle(GL.ink)
                                    .frame(width: 34, height: 34).background(Circle().fill(PK.fieldFill))
                            }
                            .buttonStyle(.plain).accessibilityLabel("ย้อนกลับ")
                        }
                        Spacer()
                        Button { Haptics.impact(.light); onClose() } label: {
                            PIcon(.x, size: 13, weight: .bold).foregroundStyle(GL.ink)
                                .frame(width: 34, height: 34).background(Circle().fill(PK.fieldFill))
                        }
                        .buttonStyle(.plain).accessibilityLabel("ปิด")
                    }
                }
                .frame(height: 34)
                HStack(spacing: 5) {
                    ForEach(1...3, id: \.self) { n in
                        Capsule().fill(n <= step ? GL.ink : PK.line2).frame(height: 4)
                    }
                }
                Text(titles[step - 1]).font(.sh(20, .heavy)).foregroundStyle(GL.ink)
                if step == 1 {
                    VStack(alignment: .leading, spacing: 12) { stepOne }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 12) {
                            if step == 2 { stepTwo } else { stepThree }
                        }
                        .padding(.bottom, 4)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(height: 470)
                }
                primary
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 12)
            .background(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous).fill(GL.bg).ignoresSafeArea(edges: .bottom))
            .transition(.move(edge: .bottom))
        }
    }

    // ขั้น 1 — แบรนด์อะไร งานอะไร
    @ViewBuilder
    private var stepOne: some View {
        WzInput(label: "แบรนด์อะไร", text: $d.brand, placeholder: "ชื่อแบรนด์")
        WzInput(label: "งานอะไร", text: $d.title, placeholder: "เช่น รีวิวเซรั่ม")
        Text("งาน Sale Here ขึ้นในตารางเอง ไม่ต้องลง").font(.sh(12.5)).foregroundStyle(GL.hint).padding(.leading, 2)
    }

    // ขั้น 2 — ลงที่ไหน (ช่องติ๊กที่สลับแท็บได้) · ลงอะไร · วันไหน
    @ViewBuilder
    private var stepTwo: some View {
        Text("เลือกได้หลายที่").font(.sh(12.5)).foregroundStyle(GL.hint).padding(.leading, 2)
        HStack(spacing: 8) {
            ForEach(JobPlatform.all) { p in tile(p) }
        }
        if let p = d.active, let v = d.plats[p] {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(p.name).font(.sh(15, .bold)).foregroundStyle(GL.ink)
                    Spacer()
                    Button("ไม่ลง \(p.short)") {
                        Haptics.impact(.light)
                        withAnimation(Motion.snap) { d.plats[p] = nil; d.active = d.chosen.first }
                    }
                    .font(.sh(12.5)).foregroundStyle(GL.muted).underline()
                }
                .frame(height: 40)
                ForEach(JobPlatform.formats(p), id: \.self) { f in
                    PK.line.frame(height: 1)
                    stepper(p, f, v.counts[f] ?? 0)
                }
                PK.line.frame(height: 1)
                HStack(spacing: 6) {
                    Text("วันลง").font(.sh(12.5, .semibold)).foregroundStyle(GL.muted)
                    Text(v.date.map(SD.label) ?? "ยังไม่เลือก").font(.sh(12.5, .bold)).foregroundStyle(v.date == nil ? GL.hint : GL.ink)
                }
                .padding(.top, 12).padding(.bottom, 8)
                DayScroller(selection: v.date) { d.plats[p]?.date = $0 }
                    .padding(.horizontal, -14).padding(.bottom, 14)
                    .id(p)
            }
            .padding(.horizontal, 14)
            .background(PK.shape(18).fill(.white))
            .overlay(PK.shape(18).strokeBorder(GL.ink, lineWidth: 1.5))
        }
    }

    private func tile(_ p: StarSocial) -> some View {
        let picked = d.plats[p] != nil, active = d.active == p
        return Button {
            Haptics.impact(.light)
            withAnimation(Motion.snap) {
                // แตะอันที่ยังไม่เลือก = เลือก + เปิดการ์ด · แตะอันที่เลือกแล้ว = สลับไปดูของอันนั้น
                if !picked {
                    var counts: [String: Int] = [:]
                    counts[JobPlatform.formats(p)[0]] = 1
                    d.plats[p] = JobDraft.Plat(counts: counts, date: d.firstDate)
                }
                d.active = p
            }
        } label: {
            VStack(spacing: 4) {
                Image(p.icon).resizable().aspectRatio(contentMode: .fit).frame(width: 26, height: 26).clipShape(Circle())
                Text(p.short).font(.sh(12, picked ? .bold : .medium)).foregroundStyle(active ? .white : (picked ? GL.ink : GL.muted)).lineLimit(1).minimumScaleFactor(0.8)
                Text(picked ? (d.plats[p]?.date.map(SD.short) ?? "ยังไม่มีวัน") : " ").font(.sh(10.5)).foregroundStyle(active ? .white.opacity(0.7) : GL.hint)
            }
            .frame(maxWidth: .infinity).padding(.top, 12).padding(.bottom, 8)
            .background(PK.shape(16).fill(active ? GL.ink : .white))
            .overlay(PK.shape(16).strokeBorder(picked ? GL.ink : PK.line, lineWidth: picked ? 1.5 : 1))
            // กล่องติ๊กมุมขวา = เลือกได้หลายที่
            .overlay(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(picked ? (active ? Color.white : GL.ink) : .white)
                    RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(picked ? .clear : PK.line2, lineWidth: 1.5)
                    if picked { PIcon(.check, size: 10, weight: .bold).foregroundStyle(active ? GL.ink : .white) }
                }
                .frame(width: 18, height: 18).padding(6)
            }
            .contentShape(PK.shape(16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(p.name) \(picked ? "เลือกแล้ว" : "ยังไม่เลือก")")
    }

    private func stepper(_ p: StarSocial, _ f: String, _ n: Int) -> some View {
        HStack(spacing: 6) {
            Text(f).font(.sh(14.5, n > 0 ? .semibold : .regular)).foregroundStyle(n > 0 ? GL.ink : GL.hint)
            Spacer()
            round("−", enabled: n > 0) { d.plats[p]?.counts[f] = max(0, n - 1) }
                .accessibilityLabel("ลด \(f)")
            Text("\(n)").font(.sh(16, n > 0 ? .bold : .regular)).monospacedDigit().foregroundStyle(n > 0 ? GL.ink : GL.hint).frame(width: 26)
            round("+", enabled: n < 9) { d.plats[p]?.counts[f] = n + 1 }
                .accessibilityLabel("เพิ่ม \(f)")
        }
        .frame(height: 48)
    }

    private func round(_ glyph: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Text(glyph).font(.sh(19, .medium)).foregroundStyle(GL.ink)
                .frame(width: 36, height: 36).background(Circle().fill(PK.fieldFill))
                .opacity(enabled ? 1 : 0.35)
        }
        .buttonStyle(.plain).disabled(!enabled)
    }

    // ขั้น 3 — ไปหน้างานไหม (ที่ไหน วันไหน เวลาอะไร) · ได้เงินเท่าไหร่
    @ViewBuilder
    private var stepThree: some View {
        caption("ต้องไปหน้างานไหม", "ถ่ายนอกสถานที่ ออกงาน ไปร้าน")
        HStack(spacing: 8) {
            choice("ไม่ต้องไป", d.site == false) { d.site = false }
            choice("ต้องไป", d.site == true) { d.site = true }
        }
        if d.site == true {
            WzInput(label: "ที่ไหน", text: $d.sitePlace, placeholder: "เช่น สยามพารากอน")
            group {
                HStack(spacing: 6) {
                    Text("วันไหน").font(.sh(12.5, .semibold)).foregroundStyle(GL.muted)
                    Text(d.siteDate.map(SD.label) ?? "ยังไม่เลือก").font(.sh(12.5, .bold)).foregroundStyle(d.siteDate == nil ? GL.hint : GL.ink)
                }
                .padding(.top, 12).padding(.bottom, 8)
                DayScroller(selection: d.siteDate) { d.siteDate = $0 }
                    .padding(.horizontal, -14)
                HStack(spacing: 6) {
                    Text("เวลา").font(.sh(12.5, .semibold)).foregroundStyle(GL.muted)
                    Text(d.siteTime ?? "ยังไม่เลือก").font(.sh(12.5, .bold)).foregroundStyle(d.siteTime == nil ? GL.hint : GL.ink)
                }
                .padding(.top, 14).padding(.bottom, 8)
                TimeScroller(selection: d.siteTime) { d.siteTime = $0 }
                    .padding(.horizontal, -14).padding(.bottom, 14)
            }
        }
        caption("ได้เงินเท่าไหร่", "เห็นคนเดียว · ไม่ใส่ก็ได้")
        WzInput(label: "ค่าตัว", text: $d.fee, placeholder: "0", unit: "บาท", keyboard: .numberPad)
    }

    private func choice(_ text: String, _ on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            withAnimation(Motion.snap) { action() }
        } label: {
            Text(text).font(.sh(14.5, on ? .bold : .regular)).foregroundStyle(on ? GL.ink : GL.muted)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(PK.shape(14).fill(.white))
                .overlay(PK.shape(14).strokeBorder(on ? GL.ink : PK.line, lineWidth: on ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func pill(_ text: String, _ on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            withAnimation(Motion.snap) { action() }
        } label: {
            Text(text).font(.sh(13, on ? .bold : .regular)).foregroundStyle(GL.ink)
                .padding(.horizontal, 12).frame(height: 34)
                .background(Capsule().fill(on ? .white : PK.fieldFill))
                .overlay(Capsule().strokeBorder(on ? GL.ink : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private func caption(_ a: String, _ b: String?) -> some View {
        HStack(spacing: 6) {
            Text(a).font(.sh(12.5, .bold)).foregroundStyle(GL.muted)
            if let b { Text(b).font(.sh(12.5)).foregroundStyle(GL.hint) }
        }
        .padding(.leading, 2).padding(.top, 2)
    }

    private func group<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(.horizontal, 14)
            .background(PK.shape(18).fill(.white))
            .overlay(PK.shape(18).strokeBorder(PK.line, lineWidth: 1))
    }

    /// ปุ่มล่าง — บอกว่ายังขาดอะไรแทนการเป็นสีเทาเฉย ๆ
    private var primary: some View {
        let miss = d.missing(step: step)
        return Button {
            guard miss.isEmpty else {
                Haptics.rigid()
                if step == 2, let p = d.firstIncomplete { withAnimation(Motion.snap) { d.active = p } }
                return
            }
            Haptics.impact(.medium)
            if step < 3 { withAnimation(Motion.snap) { step += 1 } } else { onSave(d.job()) }
        } label: {
            Text(miss.isEmpty ? (step < 3 ? "ถัดไป" : "บันทึก · ตั้งเตือน \(d.steps().count) อย่าง") : "ยังขาด: \(miss)")
                .font(.sh(16, .bold)).foregroundStyle(miss.isEmpty ? .white : GL.muted)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(Capsule().fill(miss.isEmpty ? GL.ink : PK.fieldFocus))
                .contentShape(Capsule())
        }
        .buttonStyle(DockPress())
    }
}

/// แถบเวลาเลื่อนซ้ายขวา ทุกครึ่งชั่วโมง 06:00–23:30 — ไม่ใช้ตัวเลือกเวลาของระบบ (popover ไม่ขึ้นเสมอในหน้าที่ซ้อนใน ZStack ของ shell)
private struct TimeScroller: View {
    let selection: String?
    let onPick: (String) -> Void
    private let slots: [String] = (12..<48).map { String(format: "%02d:%02d", $0 / 2, $0 % 2 * 30) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(slots, id: \.self) { t in
                        let on = selection == t
                        Button {
                            Haptics.impact(.light)
                            onPick(t)
                        } label: {
                            Text(t).font(.sh(15, on ? .bold : .medium)).monospacedDigit().foregroundStyle(GL.ink)
                                .frame(width: 64, height: 42)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(on ? .white : PK.fieldFill))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(on ? GL.ink : .clear, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .id(t)
                    }
                }
                .padding(.horizontal, 14)
            }
            .onAppear { proxy.scrollTo(selection ?? "10:00", anchor: .center) }
        }
    }
}

/// แถบวันเลื่อนซ้ายขวา 28 วันข้างหน้า — วันที่ 1 ขึ้นชื่อเดือนแทนชื่อวัน
private struct DayScroller: View {
    let selection: Date?
    let onPick: (Date) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0..<28, id: \.self) { i in
                        let day = SD.day(i)
                        let on = selection == day
                        Button {
                            Haptics.impact(.light)
                            onPick(day)
                        } label: {
                            VStack(spacing: 0) {
                                Text(i == 0 ? "วันนี้" : (SD.dayNumber(day) == 1 ? SD.month(day) : SD.weekday(day))).font(.sh(11)).foregroundStyle(GL.muted)
                                Text("\(SD.dayNumber(day))").font(.sh(17, .semibold)).monospacedDigit().foregroundStyle(GL.ink)
                            }
                            .frame(width: 50, height: 52)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(on ? .white : PK.fieldFill))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(on ? GL.ink : .clear, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .id(i)
                        .accessibilityLabel(SD.label(day))
                    }
                }
                .padding(.horizontal, 14)
            }
            .onAppear {
                if let selection { proxy.scrollTo(max(0, SD.gap(selection, SD.today)), anchor: .center) }
            }
        }
    }
}
