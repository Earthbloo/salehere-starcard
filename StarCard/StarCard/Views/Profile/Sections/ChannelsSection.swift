import SwiftUI
import PhosphorSwift

/// ช่องทางของฉัน — ข้อ `type` + `chan` (`platrate`) ของฟอร์มเว็บ
///
/// Creator/Page → แต่ละแพลตฟอร์มตามลำดับ `PLAT`: ลิงก์ · ยอดผู้ติดตาม (ดึงจากลิงก์ / เชื่อมบัญชี / กรอกเอง)
/// · เรทต่อรูปแบบของแพลตฟอร์มนั้น พร้อมเรทแนะนำจากยอด (`recoRate`) และคำเตือนถ้าต่ำ/สูงกว่าตลาดมาก
/// ผ่านได้เมื่อทุกช่องที่เลือกมี ลิงก์ถูก · ยอด > 0 · เรทอย่างน้อย 1 รูปแบบ (= `platValid()` ของเว็บ)
struct ChannelsSection: View {
    let showIssues: Bool
    @Binding var focusRequest: String?

    @FocusState private var focus: String?
    private var p: Profile { Profile.me }
    private var platforms: [SocialType] { SocialType.allCases.sorted { $0.formOrder < $1.formOrder } }

    var body: some View {
        SectionScroll(focus: $focus, request: $focusRequest) {
            // ข้อ `type` — ถามก่อนช่องทาง
            VStack(alignment: .leading, spacing: 10) {
                Text("คุณเป็นแบบไหน?").font(.sh(16, .bold)).foregroundStyle(PK.ink)
                    .padding(.horizontal, 4)
                PKTileGrid(items: CreatorKind.allCases) { k in
                    PKTile(icon: k.icon, title: k.title, on: p.intake?.kind == k) {
                        Profile.me.updateIntake { $0.kind = k }
                    }
                }
                if let e = sectionIssue(.channels, PField.kind, shown: showIssues) {
                    Text(e).font(.sh(11.5, .medium)).foregroundStyle(PK.err).padding(.horizontal, 4)
                }
            }
            .id(PField.kind)

            if let e = sectionIssue(.channels, PField.channelsAny, shown: showIssues) {
                Text(e).font(.sh(12, .semibold)).foregroundStyle(PK.err).padding(.horizontal, 4)
            }

            VStack(spacing: 10) {
                ForEach(platforms) { t in
                    ChannelRow(type: t, showIssues: showIssues, focus: $focus)
                }
            }
            .id(PField.channelsAny)
        }
    }
}

// MARK: - แถวของแพลตฟอร์มหนึ่ง (= `rowHTML(p)`)

private struct ChannelRow: View {
    let type: SocialType
    let showIssues: Bool
    var focus: FocusState<String?>.Binding

    @State private var busy = false
    private var p: Profile { Profile.me }
    private var entry: SocialEntry? { p.intake?.social(type) }
    private var on: Bool { entry?.enabled ?? false }
    private var rates: [RateCell] { (p.intake?.rates ?? []).filter { $0.platform == type } }
    private var priced: [RateCell] { rates.filter { $0.price > 0 } }
    private var done: Bool {
        guard on, let e = entry else { return false }
        return !e.link.isEmpty && e.linkError == nil && e.followers > 0 && !priced.isEmpty
    }

    private var linkID: String { PField.link(type) }
    private var folID: String { PField.followers(type) }
    private var ratesID: String { PField.rates(type) }

    var body: some View {
        VStack(spacing: 0) {
            header
            if on, let e = entry {
                body(e)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(PKSurface())
        .animation(Motion.settle, value: on)
        .animation(Motion.settle, value: done)
    }

    // MARK: หัวแถว

    private var header: some View {
        Button {
            Haptics.impact(.light)
            toggle()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    PK.shape(12).fill(PK.fieldFill)
                    BrandIcon(name: type.icon, size: 22)
                }
                .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.name).font(.sh(14.5, .bold)).foregroundStyle(PK.ink)
                    if !subtitle.isEmpty {
                        Text(subtitle).font(.sh(12, .semibold)).foregroundStyle(PK.muted)
                            .lineLimit(1).truncationMode(.middle)
                    }
                }
                Spacer(minLength: 6)
                ZStack {
                    if on { Circle().fill(PK.pick); Circle().strokeBorder(PK.pickLine, lineWidth: 1.5) } else { Circle().strokeBorder(PK.line2, lineWidth: 1.5) }
                    if on { PIcon(.check, size: 10).foregroundStyle(PK.onPick) }
                }
                .frame(width: 22, height: 22)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(DockPress())
    }

    /// ข้อความใต้ชื่อช่อง — เหมือน `sub` ใน `rowHTML`
    private var subtitle: String {
        guard on, let e = entry else { return "" }
        guard done else { return "" }
        return "\(rangeText) · \(priced.count) รูปแบบ · ผู้ติดตาม \(Fmt.compact(e.followers))"
    }

    private var rangeText: String {
        let v = priced.map(\.price)
        guard let lo = v.min(), let hi = v.max() else { return "" }
        return hi > lo ? "฿\(Fmt.baht(lo))–฿\(Fmt.baht(hi))" : "฿\(Fmt.baht(lo))"
    }

    // MARK: ตัวแถว

    private func body(_ e: SocialEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle().fill(PK.line).frame(height: 1)

            // ไม่มีป้าย "ลิงก์โปรไฟล์" — ช่องเดียวในการ์ดของแพลตฟอร์มนั้น ตัวอย่างในช่องบอกอยู่แล้ว
            PKField(label: "", text: linkBinding,
                    placeholder: type.placeholderLink, keyboard: .URL, contentType: .URL,
                    autocap: .never, noCorrect: true,
                    error: e.linkError ?? sectionIssue(.channels, linkID, shown: showIssues),
                    id: linkID, focus: focus, onCommit: { autoFetchIfPossible() })

            followers(e)
            ratesBlock(e)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: ยอดผู้ติดตาม (= `folBlock`)

    @ViewBuilder
    private func followers(_ e: SocialEntry) -> some View {
        let issue = sectionIssue(.channels, folID, shown: showIssues)
        switch type.fetch {
        case .api:
            // YouTube: ดึงจากลิงก์ — ยังไม่มีลิงก์ = ไม่ต้องมีแถวบอกว่าจะดึง
            VStack(alignment: .leading, spacing: 6) {
                if busy {
                    HStack(spacing: 7) {
                        ProgressView().controlSize(.small)
                        Text("กำลังดึงยอดผู้ติดตาม…").font(.sh(12.5, .medium)).foregroundStyle(PK.muted)
                    }
                    .padding(.horizontal, 4)
                } else if e.followers > 0 {
                    verifiedRow(e, note: "ยืนยันจาก YouTube")
                }
                if let issue { errorLine(issue) }
            }
            .id(folID)
        case .connect:
            if e.source == .connected {
                verifiedRow(e, note: "เชื่อมบัญชีแล้ว").id(folID)
            } else {
                // กรอกเองไปก่อน — ปุ่มเชื่อมบัญชีถอดออกจนกว่าจะต่อ OAuth จริง (ผู้ใช้ 1 ต.ค. 2569)
                PKField(label: "", text: followersBinding, placeholder: "24800",
                        keyboard: .numberPad, autocap: .never, noCorrect: true,
                        error: issue, leading: "ผู้ติดตาม", id: folID, focus: focus)
            }
        case .manual:
            PKField(label: "", text: followersBinding, placeholder: "24800",
                    keyboard: .numberPad, autocap: .never, noCorrect: true,
                    error: issue, leading: "ผู้ติดตาม", id: folID, focus: focus)
        }
    }

    /// ยอดที่ระบบยืนยันแล้ว — แถวเขียวบรรทัดเดียว ยอด · ระดับ ซ้าย / ที่มาของยอดขวา
    private func verifiedRow(_ e: SocialEntry, note: String) -> some View {
        HStack(spacing: 7) {
            PIcon(.sealCheck, size: 15, weight: .fill).foregroundStyle(PK.ok)
            Text("\(Fmt.compact(e.followers)) ผู้ติดตาม · \(IntakeCatalog.tier(e.followers))")
                .font(.sh(13.5, .bold)).foregroundStyle(PK.ink).lineLimit(1)
            Spacer(minLength: 4)
            Text(note).font(.sh(11, .semibold)).foregroundStyle(PK.ok).lineLimit(1)
        }
        .padding(.horizontal, 12).frame(height: 40)
        .background(PK.shape(PK.fieldRadius).fill(PK.okTint))
    }

    // MARK: เรท (= `fmthead` + `allbtn` + `fmts` + `dev`)

    private func ratesBlock(_ e: SocialEntry) -> some View {
        let base = IntakeCatalog.recoRate(type, followers: e.followers)
        return VStack(alignment: .leading, spacing: 8) {
            // หัวเรท + ปุ่มเรทแนะนำแถวเดียว (ปุ่มเต็มแถวกินอีก 40pt ต่อแพลตฟอร์ม)
            HStack(spacing: 4) {
                Text("เรทต่องาน").font(.sh(14, .bold)).foregroundStyle(PK.ink)
                Text("*").font(.sh(13, .bold)).foregroundStyle(PK.red)
                Spacer(minLength: 6)
                if base > 0 {
                    Button {
                        Haptics.impact(.light)
                        fillAll(e)
                    } label: {
                        Text("✨ ใช้เรทแนะนำ").font(.sh(12.5, .bold)).foregroundStyle(PK.ink)
                            .padding(.horizontal, 11).padding(.vertical, 6)
                            .background(Capsule().fill(PK.fieldFill))
                            .overlay(Capsule().strokeBorder(PK.line2, lineWidth: 1))
                    }
                    .buttonStyle(DockPress())
                }
            }
            .padding(.horizontal, 4)

            // รูปแบบงานเป็นรายการในกล่องเดียว แถวละบรรทัด — เรทตลาดอยู่ในช่องราคาเป็นตัวอย่าง
            VStack(spacing: 0) {
                ForEach(Array(type.formats.enumerated()), id: \.element.id) { i, f in
                    if i > 0 { Rectangle().fill(PK.line).frame(height: 1).padding(.leading, 40) }
                    formatRow(e, f)
                }
            }
            .background(PK.shape(PK.fieldRadius).fill(PK.fieldFill.opacity(0.6)))
            if let issue = sectionIssue(.channels, ratesID, shown: showIssues) { errorLine(issue) }
            if let dev = deviation(e) {
                PKNote(text: dev, symbol: .warning, color: PK.warn)
            }
        }
        .id(ratesID)
    }

    private func formatRow(_ e: SocialEntry, _ f: PlatFormat) -> some View {
        let cell = rates.first { $0.formatKey == f.key }
        let on = cell != nil
        let reco = IntakeCatalog.reco(type, followers: e.followers, format: f)
        return HStack(spacing: 10) {
            Button {
                Haptics.impact(.light)
                toggleFormat(f, reco: reco)
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        if on { PK.shape(6).fill(PK.pick); PK.shape(6).strokeBorder(PK.pickLine, lineWidth: 1.5) } else { PK.shape(6).strokeBorder(PK.line2, lineWidth: 1.5) }
                        if on { PIcon(.check, size: 10).foregroundStyle(PK.onPick) }
                    }
                    .frame(width: 20, height: 20)
                    Text(f.label).font(.sh(13.5, on ? .bold : .medium))
                        .foregroundStyle(on ? PK.ink : PK.muted)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            HStack(spacing: 3) {
                Text("฿").font(.sh(13, .semibold)).foregroundStyle(PK.hint)
                TextField("", text: priceBinding(f, reco: reco),
                          prompt: Text(reco > 0 ? Fmt.baht(reco) : "0").font(.sh(14.5)).foregroundStyle(PK.hint.opacity(0.6)))
                    .font(.sh(14.5, .semibold)).foregroundStyle(PK.ink).tint(PK.ink)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 64)
                    .focused(focus, equals: PField.price(type, f.key))
            }
            .padding(.horizontal, 9).frame(height: 32)
            .background(PK.shape(9).fill(on ? PK.surface : .clear))
            .overlay(PK.shape(9).strokeBorder(on ? PK.ink.opacity(0.5) : PK.line, lineWidth: 1))
        }
        .padding(.horizontal, 10).frame(height: 44)
        .animation(Motion.snap, value: on)
    }

    /// เรทที่ตั้งไว้ห่างจากที่คนอื่นรับมาก — บอกแต่ไม่ห้าม (= `.dev.lo` / `.dev.hi`)
    private func deviation(_ e: SocialEntry) -> String? {
        for f in type.formats {
            guard let c = rates.first(where: { $0.formatKey == f.key }), c.price > 0 else { continue }
            let reco = IntakeCatalog.reco(type, followers: e.followers, format: f)
            guard reco > 0 else { continue }
            if c.price < IntakeCatalog.recoLow(reco) {
                return "เรท “\(f.label)” ต่ำกว่าที่คนอื่นเขารับกันพอสมควรนะ ถ้าตั้งใจก็ไปต่อได้เลย"
            }
            if c.price > IntakeCatalog.recoHigh(reco) {
                return "เรท “\(f.label)” สูงกว่าที่คนส่วนใหญ่รับ แบรนด์อาจขอต่อรอง — ตั้งไว้แบบนี้ก็ได้"
            }
        }
        return nil
    }

    private func errorLine(_ text: String) -> some View {
        HStack(spacing: 5) {
            PIcon(.warningCircle, size: 12, weight: .fill)
            Text(text).font(.sh(12, .medium))
        }
        .foregroundStyle(PK.red)
    }

    // MARK: เขียนกลับ

    private var linkBinding: Binding<String> {
        Binding(get: { entry?.link ?? "" },
                set: { v in
                    Profile.me.updateIntake { d in
                        guard let i = d.socials.firstIndex(where: { $0.type == type }) else { return }
                        d.socials[i].link = v
                        // ลิงก์เปลี่ยน = ยอดที่ API เคยดึงมาไม่ใช่ของช่องนี้แล้ว
                        if d.socials[i].source == .api { d.socials[i].source = .manual; d.socials[i].followers = 0 }
                    }
                })
    }

    /// ตัวเลขล้วน — พิมพ์ยอดแล้วเรทแนะนำเดินตามทันที
    private var followersBinding: Binding<String> {
        Binding(get: { (entry?.followers ?? 0) > 0 ? String(entry!.followers) : "" },
                set: { v in
                    let n = Int(String(v.filter(\.isNumber).prefix(9))) ?? 0
                    Profile.me.updateIntake { d in
                        guard let i = d.socials.firstIndex(where: { $0.type == type }) else { return }
                        d.socials[i].followers = n
                        if d.socials[i].source != .connected { d.socials[i].source = .manual }
                        Self.autoRates(&d, type)
                    }
                })
    }

    private func priceBinding(_ f: PlatFormat, reco: Int) -> Binding<String> {
        Binding(get: {
            guard let c = rates.first(where: { $0.formatKey == f.key }), c.price > 0 else { return "" }
            return String(c.price)
        }, set: { v in
            let n = Int(String(v.filter(\.isNumber).prefix(7))) ?? 0
            Profile.me.updateIntake { d in
                if let i = d.rates.firstIndex(where: { $0.platform == type && $0.formatKey == f.key }) {
                    d.rates[i].price = n
                    d.rates[i].touched = true
                } else if n > 0 {
                    // พิมพ์ราคาลงรูปแบบที่ยังไม่ติ๊ก = ติ๊กให้เลย
                    d.rates.append(RateCell(platform: type, formatKey: f.key, price: n, touched: true))
                    Self.sortRates(&d)
                }
            }
        })
    }

    private func toggleFormat(_ f: PlatFormat, reco: Int) {
        Profile.me.updateIntake { d in
            if let i = d.rates.firstIndex(where: { $0.platform == type && $0.formatKey == f.key }) {
                d.rates.remove(at: i)
            } else {
                d.rates.append(RateCell(platform: type, formatKey: f.key, price: reco, touched: false))
                Self.sortRates(&d)
            }
        }
    }

    /// ปุ่มเดียวเติมครบทุกฟอร์แมต ไม่ใช่แค่ฟอร์แมตที่ติ๊กไว้ — ราคาที่ผู้ใช้แก้เองแล้วไม่ทับ
    private func fillAll(_ e: SocialEntry) {
        Profile.me.updateIntake { d in
            for f in type.formats {
                let reco = IntakeCatalog.reco(type, followers: e.followers, format: f)
                if let i = d.rates.firstIndex(where: { $0.platform == type && $0.formatKey == f.key }) {
                    if !d.rates[i].touched { d.rates[i].price = reco }
                } else {
                    d.rates.append(RateCell(platform: type, formatKey: f.key, price: reco, touched: false))
                }
            }
            Self.sortRates(&d)
        }
    }

    /// รู้ยอดแล้ว: ครั้งแรกติ๊กรูปแบบหลักให้ · รูปแบบที่ติ๊กไว้และยังไม่แก้เอง ปรับตามเรทแนะนำใหม่ (= `autoRates`)
    private static func autoRates(_ d: inout IntakeData, _ t: SocialType) {
        guard let e = d.social(t), e.followers > 0 else { return }
        let mine = d.rates.filter { $0.platform == t }
        if mine.isEmpty {
            let f = t.defaultFormat
            d.rates.append(RateCell(platform: t, formatKey: f.key,
                                    price: IntakeCatalog.reco(t, followers: e.followers, format: f), touched: false))
        } else {
            for i in d.rates.indices where d.rates[i].platform == t && !d.rates[i].touched {
                if let f = d.rates[i].spec { d.rates[i].price = IntakeCatalog.reco(t, followers: e.followers, format: f) }
            }
        }
        sortRates(&d)
    }

    /// เรียงตามลำดับแพลตฟอร์มของฟอร์ม แล้วตามลำดับรูปแบบใน `PLAT.fmts`
    private static func sortRates(_ d: inout IntakeData) {
        func idx(_ c: RateCell) -> Int { c.platform.formats.firstIndex { $0.key == c.formatKey } ?? 0 }
        d.rates.sort { ($0.platform.formOrder, idx($0)) < ($1.platform.formOrder, idx($1)) }
    }

    private func toggle() {
        Profile.me.updateIntake { d in
            if let i = d.socials.firstIndex(where: { $0.type == type }) {
                d.socials[i].enabled.toggle()
            } else {
                d.socials.append(SocialEntry(type: type))
            }
        }
        if !on {
            // เปิดแถวใหม่ = พาไปที่ช่องลิงก์เลย ไม่ต้องแตะซ้ำ
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(260))
                focus.wrappedValue = linkID
            }
        }
    }

    /// YouTube: ดึงจากลิงก์ได้จริง — **ตอนนี้จำลอง** รอต่อ YouTube Data API
    private func autoFetchIfPossible() {
        guard type.fetch == .api, let e = entry, !e.link.isEmpty, e.linkError == nil,
              e.source != .api, !busy else { return }
        busy = true
        let seed = e.link
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            Profile.me.updateIntake { d in
                guard let i = d.socials.firstIndex(where: { $0.type == type }) else { return }
                d.socials[i].followers = IntakeCatalog.simulatedFollowers(seed: seed)
                d.socials[i].source = .api
                Self.autoRates(&d, type)
            }
            busy = false
            Haptics.impact(.light)
        }
    }

    /// OAuth ของแพลตฟอร์ม — **ตอนนี้จำลอง** รอต่อ `createSocialAuthorizeParams` ของ backend
    private func connect() {
        guard !busy else { return }
        busy = true
        Haptics.impact(.light)
        let seed = entry?.link ?? type.rawValue
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            Profile.me.updateIntake { d in
                guard let i = d.socials.firstIndex(where: { $0.type == type }) else { return }
                d.socials[i].source = .connected
                if d.socials[i].followers == 0 { d.socials[i].followers = IntakeCatalog.simulatedFollowers(seed: seed) }
                // เชื่อมแล้ว = ยอดของจริง เรทที่ยังไม่แก้เองเดินตามใหม่
                for j in d.rates.indices where d.rates[j].platform == type { d.rates[j].touched = false }
                Self.autoRates(&d, type)
            }
            busy = false
            Haptics.impact(.medium)
        }
    }
}
