import SwiftUI
import UIKit
import PhosphorSwift

// MARK: - ตัววาดผัง (iOS)
//
// รู้จักของไม่กี่อย่าง — กล่องมุมมน · เส้น · ไล่สี · ข้อความ · รูป · ไอคอน — และ **ไม่ตัดสินใจอะไร**
// ตำแหน่ง/ขนาด/ขนาดตัวอักษร/จำนวนบรรทัด มาจาก `SpecSolver` ทั้งหมด · Android/Web เขียนตัวนี้ใหม่ด้วย
// primitive ชุดเดียวกัน (ดู WIDGET-SPEC.md §5) แล้วได้ภาพเดียวกัน เพราะตัวเลขที่ได้มาเท่ากัน

struct SpecPainter: View {
    let spec: WidgetSpec
    let kind: WidgetKind
    let theme: CardTheme
    /// กล่องรากในหน่วยออกแบบ (= `box` ของสูตรเดียวใน `WidgetChrome`)
    let size: CGSize

    @Environment(\.cardInk) private var ink
    @Environment(\.cardAccent) private var accent
    @Environment(\.widgetID) private var wid
    @Environment(\.sampleData) private var sample
    @Environment(\.kitConfig) private var kitRaw
    /// ค่าของชิ้น + หน้าตาของชนิด (`widget.kit.look`)
    private var kit: KitConfig { kitRaw.looking(kind) }
    @Environment(\.widgetBorder) private var border
    @Environment(\.widgetSurface) private var surface
    @Environment(\.saleHereStamped) private var stamped
    @Environment(\.widgetRenderScale) private var renderScale
    @Environment(PhotoStore.self) private var photos

    /// สีทั้ง 6 บทบาท × พื้น ของชิ้นนี้ (`SpecPalette` — สูตรของทุกสำรับอยู่ที่นั่น · ผังอ้างแค่ `ink` `bg` … + `on`)
    private var palette: SpecPalette {
        SpecPalette(theme: theme, ink: ink, accent: accent, kit: kit, border: border, surface: surface,
                    popSkin: kind.popSkin, base: spec.widget?.on)
    }

    var body: some View {
        #if DEBUG
        let _ = { HitchMonitor.paints += 1 }()
        #endif
        // กล่องรากคือ **ที่ที่ได้จริง** (chrome หักระยะขอบในออกแล้ว) ไม่ใช่ `size` ที่ส่งมาซึ่งเป็นกรอบเต็มก่อนหักขอบ
        GeometryReader { geo in
            let box = CGSize(width: max(1, geo.size.width), height: max(1, geo.size.height))
            let data = IOSSpecData(sample: sample, widget: wid, inkLight: ink.isLight, kit: kit, border: border,
                                   surface: surface, duo: theme.activeDuo != nil, stamped: stamped,
                                   cutout: { if case .subject = cutoutPlane(photos, slot: 1, widget: wid) { return true }; return false }(),
                                   kitDark: spec.widget?.on == "dark")   // `kit.dark` = ใบนี้นั่งบนแผ่นเข้ม (พื้น `dark`) — ไม่ใช่ความมืดของสีพื้น Canva อีกแล้ว (20 ต.ค. 2569)
            let (boxes, k) = Self.solve(spec, box: box, data: data, renderScale: renderScale)
            // QR ชี้ไปที่ handle ของ **แหล่งข้อมูลของใบนี้** (ตัวอย่าง = handle ตัวอย่าง) ไม่ใช่ของเครื่อง — ทุกแพลตฟอร์มถามคำถามเดียวกัน (21 ต.ค. 2569)
            let tree = SpecTree(boxes, handle: data.text(slot: "handle", preset: nil))
            Group {
                if let root = tree.root { node(root, tree) }
            }
            .frame(width: box.width / k, height: box.height / k, alignment: .topLeading)
            .scaleEffect(k, anchor: .topLeading)
            .frame(width: box.width, height: box.height, alignment: .topLeading)
        }
    }

    /// ตัวคำนวณ + ขั้นย่อ · ตอนส่งออก fixture (`SpecExport.capture`) จดทุกคำถาม/คำตอบของ **รอบที่วาดจริง**
    /// — fixture กับรูปจึงมาจากข้อมูลชุดเดียวกันเสมอ (พื้นผิว · ขอบ · หมึกของ chrome ที่ใบนั้นได้จริง)
    private static func solve(_ spec: WidgetSpec, box: CGSize, data: IOSSpecData, renderScale: CGFloat) -> ([SpecBox], CGFloat) {
        #if DEBUG
        if let cap = SpecExport.capture {
            let rdata = SpecExport.RecordingData(data)
            let rec = SpecExport.RecordingMeasurer()
            let solver = SpecSolver(spec: spec, box: box, data: rdata, measurer: rec, renderScale: renderScale)
            let boxes = solver.solve()
            _ = rdata.text(slot: "handle", preset: nil)   // จดลง fixture ให้ Android/เว็บเข้ารหัส QR ด้วยค่าเดียวกัน
            cap.record(box: box, boxes: boxes, measures: rec.log, lines: rec.lines, data: rdata.log, scale: solver.scale,
                       renderScale: renderScale)
            return (boxes, solver.scale)
        }
        #endif
        #if DEBUG
        let t0 = CFAbsoluteTimeGetCurrent()
        defer { HitchMonitor.solveMs += (CFAbsoluteTimeGetCurrent() - t0) * 1000; HitchMonitor.solves += 1 }
        #endif
        return SpecSolveMemo.shared.solve(spec, box: box, data: data, renderScale: renderScale)
    }

    // MARK: ต้นไม้ — วาดซ้อนตามโครงสร้าง (clip · opacity · rotate ใช้กับทั้งกิ่ง)

    /// กล่องของโหนดหนึ่ง + ลูกทั้งหมดซ้อนข้างใน (พิกัดลูกสัมพัทธ์กับแม่) — `clip`/`opacity`/`rotate` ของแม่จึงพาลูกไปด้วย
    private func node(_ b: SpecBox, _ t: SpecTree) -> AnyView {
        let n = b.node
        let kids = t.children[b.id] ?? []
        let v = SpecPlace {
            paint(b, t)
            ForEach(kids) { c in
                node(c, t)
                    .frame(width: c.frame.width, height: c.frame.height)
                    .layoutValue(key: SpecOrigin.self, value: CGPoint(x: c.frame.minX - b.frame.minX, y: c.frame.minY - b.frame.minY))
            }
        }
        .frame(width: b.frame.width, height: b.frame.height, alignment: .topLeading)
        let shape = SpecShapes.make(n.shape, corner: corner(n, b.frame.size))
        return AnyView(
            Group {
                if n.clip == true { v.clipShape(shape) } else { v }
            }
            .opacity(n.opacity ?? 1)
            .rotationEffect(.degrees(rotation(n, b.item)))
        )
    }

    /// มุมของกล่อง ณ ขนาดจริง — `circle` = ครึ่งด้านสั้น (วงกลม/แคปซูล)
    private func corner(_ n: SpecNode, _ size: CGSize) -> CGFloat {
        n.circle == true ? min(size.width, size.height) / 2 : CGFloat(n.radius ?? 0)
    }

    // MARK: primitive

    @ViewBuilder
    private func paint(_ b: SpecBox, _ tree: SpecTree) -> some View {
        let n = b.node
        switch n.type {
        case .col, .row, .stack, .chips, .spacer:
            background(n, item: b.item, size: b.frame.size)
        case .rect, .line:
            background(n, item: b.item, size: b.frame.size, defaultFill: n.type == .line ? "ink@0.12" : nil)
        case .text:
            text(b)
        case .image:
            image(b)
        case .icon:
            icon(b, handle: tree.handle)
        }
    }

    /// พื้น · ไล่สี · เส้นขอบ · เงา ของกล่องหนึ่งใบ — ไม่มีค่าไหนตั้ง = ไม่วาดอะไร
    private func rotation(_ n: SpecNode, _ item: SpecItem?) -> Double {
        if let c = n.rotateCycle, !c.isEmpty, let item { return c[item.i % c.count] }
        return n.rotate ?? 0
    }

    @ViewBuilder
    private func background(_ n: SpecNode, item: SpecItem?, size: CGSize, defaultFill: String? = nil) -> some View {
        let fill = (n.fillCycle.flatMap { c in item.map { c.isEmpty ? nil : c[$0.i % c.count] } ?? nil }) ?? n.fill ?? defaultFill
        if let pp = n.platePattern {
            // ลายแผ่นของถาด (ลายทาง · ข้าวหลามตัด) — ไม่เลือก = `.plain` ไม่วาดอะไร
            PlatePatternLayer(sheet: color(pp, on: n.on, item: item))
                .clipShape(SpecShapes.make(n.shape, corner: corner(n, size)))
        }
        if fill != nil || n.gradient != nil || n.stroke != nil || n.pattern != nil {
            let shape = SpecShapes.make(n.shape, corner: corner(n, size))
            ZStack {
                if let g = n.gradient {
                    let a = Angle.degrees(g.angle)
                    let dx = cos(a.radians), dy = sin(a.radians)
                    shape.fill(LinearGradient(colors: [color(g.from, on: n.on, item: item), color(g.to, on: n.on, item: item)],
                                              startPoint: UnitPoint(x: 0.5 - dx / 2, y: 0.5 - dy / 2),
                                              endPoint: UnitPoint(x: 0.5 + dx / 2, y: 0.5 + dy / 2)))
                } else if let fill {
                    shape.fill(color(fill, on: n.on, item: item))
                }
                if let pat = n.pattern {
                    SpecPatternView(pattern: pat, color: color(pat.color, on: n.on, item: item), color2: color(pat.color2 ?? pat.color, on: n.on, item: item))
                        .clipShape(shape)
                }
                if let s = n.stroke {
                    if let dash = s.dash {
                        shape.stroke(color(s.color, on: n.on, item: item), style: StrokeStyle(lineWidth: CGFloat(s.width), dash: dash.map { CGFloat($0) }))
                            .clipShape(shape)
                    } else {
                        shape.stroke(color(s.color, on: n.on, item: item), lineWidth: CGFloat(s.width) * 2).clipShape(shape)
                    }
                }
            }
            .modifier(SpecShadowModifier(shadow: n.shadow, resolve: { color($0, on: n.on, item: item) }))
        }
    }

    @ViewBuilder
    private func text(_ b: SpecBox) -> some View {
        let n = b.node
        if let r = b.text {
            let align: TextAlignment = n.textAlign == "center" ? .center : n.textAlign == "right" ? .trailing : .leading
            let frameAlign: Alignment = n.textAlign == "center" ? .top : n.textAlign == "right" ? .topTrailing : .topLeading
            let face = CardFont(rawValue: n.face ?? "") ?? .noto
            let weight = Font.Weight.from(n.weight ?? 400)
            let col = color(n.color ?? "ink", on: n.on, item: b.item)
            // ข้อความบน widget = ข้อมูลของหมวดล้วน — แตะไม่ได้ ไม่มีการพิมพ์/ปรับขนาด/สี/ฟอนต์ (หน้าตาตามผัง + ธีม)
            let style = TextSlotStyle(size: r.size, weight: weight, face: face, color: col,
                                      align: align, tracking: CGFloat(n.tracking ?? 0),
                                      lineSpacing: lineSpacing(n, size: r.size),
                                      uppercase: n.textCase == "upper", italic: n.italic ?? false)
            // พาดหัวสองเสียงของสำรับโปสเตอร์ (`mixHead`): คำแรกตามฟอนต์ของโหนด · ที่เหลือ noto บางเอียง ×1.04
            // — ท่าเดียวกับ `StatPosterWidget.mixedLine` / `NichePosterWidget.mixedLine` (คืน Text ก้อนเดียว ย่อพร้อมกัน)
            let parts = n.mixHead == true ? r.string.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true) : []
            let mixed: Text? = parts.count > 1 ? {
                let head = Text(String(parts[0])).font(face.font(r.size, weight)).kerning(CGFloat(n.kerning ?? 0))
                let tail = Text(" " + String(parts[1])).font(CardFont.noto.font(r.size * 1.04, .light).italic())
                return head + tail
            }() : nil
            let base = (mixed ?? Text(r.string))
                .kerning(mixed == nil ? CGFloat(n.kerning ?? 0) : 0)
                .lineLimit(max(1, r.lines))
                .minimumScaleFactor(mixed == nil ? 1 : 0.5)
                .truncationMode(.tail)
                .multilineTextAlignment(align)
            base.font(style.font).foregroundStyle(col)
                .tracking(style.tracking)
                .lineSpacing(style.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: b.frame.width, height: b.frame.height, alignment: frameAlign)
            // เงา/เรืองแสงของตัวอักษร (ป้ายไฟ)
            .modifier(SpecShadowModifier(shadow: n.shadow, resolve: { color($0, on: n.on, item: b.item) }))
        }
    }

    private func lineSpacing(_ n: SpecNode, size: CGFloat) -> CGFloat {
        guard let lh = n.lineHeight, lh != 1 else { return 0 }
        let f = IOSSpecMeasurer.shared.uiFont(SpecFont(face: n.face ?? "body", size: size, weight: n.weight ?? 400))
        return f.lineHeight * CGFloat(lh - 1)
    }

    @ViewBuilder
    private func image(_ b: SpecBox) -> some View {
        let n = b.node
        let shape = SpecShapes.make(n.shape, corner: corner(n, b.frame.size))
        let slot = n.photoRef.flatMap { r in r.hasPrefix("$") ? Int(b.item?.value(String(r.dropFirst())) ?? "") : Int(r) }
            ?? n.photo ?? Int(b.item?.value("photo") ?? "") ?? 0
        // `src`: รูปจาก asset ของแอป (`"$cover"` = ปกผลงาน) — ว่าง = ช่องรูปของชิ้นตามเดิม
        let src = n.src.map { $0.hasPrefix("$") ? (b.item?.value(String($0.dropFirst())) ?? "") : $0 } ?? ""
        Color.clear
            .overlay {
                if !src.isEmpty, UIImage(named: src) != nil {
                    Image(src).resizable()
                        .aspectRatio(contentMode: n.fit == "contain" ? .fit : .fill)
                } else if src.hasPrefix("http") {
                    RemoteLogo(url: src)
                } else {
                    WidgetPhoto(index: slot)
                        .aspectRatio(contentMode: n.fit == "contain" ? .fit : .fill)
                }
            }
            .clipShape(shape)
            // ขาวดำ — ใส่หลัง clip (ทั้งชั้นที่ประกอบแล้ว) · `.saturation` บนรูปข้างใน overlay ไม่มีผลกับรูปที่ `WidgetPhoto` วาดผ่าน visualEffect
            .compositingGroup()
            .grayscale(n.mono == true ? 1 : 0)
            .overlay {
                if let s = n.stroke { shape.stroke(color(s.color, on: n.on), lineWidth: CGFloat(s.width) * 2).clipShape(shape) }
            }
            .modifier(SpecShadowModifier(shadow: n.shadow, resolve: { color($0, on: n.on) }))
            .photoSlot(slot)
    }

    @ViewBuilder
    private func icon(_ b: SpecBox, handle: String) -> some View {
        let n = b.node
        let name = n.icon.map { $0.hasPrefix("$") ? (b.item?.value(String($0.dropFirst())) ?? "") : $0 } ?? ""
        let tint = n.tint.map { color($0, on: n.on, item: b.item) }
        let f = b.frame
        Group {
            switch name {
            case "qr":
                QRCode(text: "https://salehere.co.th/star/\(handle)", tint: tint ?? color("ink"))
                    .aspectRatio(1, contentMode: .fit)
            case "provenance", "provenance:profile":
                ProvenanceTag(kind: .profile).fixedSize()
            case "provenance:socials":
                ProvenanceTag(kind: Profile.me.shownSocials.provenance).fixedSize()
            case "provenance:photo":
                ProvenanceTag(kind: Profile.me.shownSocials.provenance, onPhoto: true).fixedSize()
            case "provenance:screenshot":
                ProvenanceTag(kind: .screenshot("12 ก.ย.")).fixedSize()
            // ป้าย "Verified by Sale Here" ของโค้ดเดิม (`SaleHereByline`) — `byline` (หมึกของใบ) · `byline:dark` · `byline:light`
            // ขนาดตัวอักษร = ความสูงกล่อง × 0.45 · `tint` = หมึก (ตั้งต้น ink@0.9)
            case "byline", "byline:dark", "byline:light":
                SaleHereByline(tint: tint ?? color("ink@0.9"), size: max(6, f.height * 0.45),
                               tone: name == "byline:dark" ? .dark : name == "byline:light" ? .light : .ink)
                    .fixedSize()
            case "verifiedBadge":
                VerifiedBadge().fixedSize()
            case "verifiedSeal":
                VerifiedSeal(radius: min(f.width, f.height) / 2, punch: ink.isLight ? .white : Color(white: 0.1), tint: tint ?? color("ink"), compact: false)
            case "guilloche":
                Guilloche(color: tint ?? color("ink@0.2"))
            case "ringText":
                RingText(text: n.text ?? "", radius: min(f.width, f.height) / 2 - CGFloat(n.size ?? 7), size: CGFloat(n.size ?? 7), color: tint ?? color("ink"))
            case "washi":
                WashiTape(width: f.width, height: f.height, tint: tint ?? .white)
            case "binderClip":
                BinderClip(width: f.width)
            case "paperClip":
                PaperClip().stroke(tint ?? color("ink@0.6"), lineWidth: 1.6)
            case "barcode":
                ScrapBarcode(color: tint ?? color("ink"))
            case "bow":
                ScrapBow(width: f.width)
            case "spark":
                ScrapSpark(size: min(f.width, f.height), color: tint ?? .white)
            case "windowDots":
                ScrapWindowDots()
            case "embossedLockup":
                EmbossedLockup(height: f.height, light: ink.isLight, foil: false, tint: tint ?? color("ink@0.8"))
            case "starLockup":
                StarLockup(height: f.height, tint: tint ?? color("accent"))
            case "starSeal":
                StarSeal(size: min(f.width, f.height), tint: tint ?? color("accent"), punch: ink.isLight ? .white : Color(white: 0.1))
            case "saleHereStar":
                Image(SHIcon.star).renderingMode(.template).resizable().scaledToFit().foregroundStyle(tint ?? color("ink"))
            default:
                if name.hasPrefix("url:") || name.hasPrefix("http") {
                    RemoteLogo(url: name.hasPrefix("url:") ? String(name.dropFirst(4)) : name)
                } else if name.hasPrefix("ph:") {
                    // asset ของแอปก่อน (ph-<name>) · ไม่มีก็ชุด Phosphor เต็ม (ชื่อ kebab-case ตรงกับ `Ph.rawValue`)
                    let short = String(name.dropFirst(3))
                    if UIImage(named: "ph-" + short) != nil {
                        Image("ph-" + short).renderingMode(.template).resizable().scaledToFit()
                            .foregroundStyle(tint ?? color("ink"))
                    } else if let ph = Ph(rawValue: short.replacingOccurrences(of: "-fill", with: "")) {
                        PIcon(ph, size: min(f.width, f.height), weight: short.hasSuffix("-fill") ? .fill : .bold)
                            .foregroundStyle(tint ?? color("ink"))
                    }
                } else if name.hasPrefix("sh:") {
                    let asset = SHIcon.named(String(name.dropFirst(3)))
                    if let tint {
                        Image(asset).renderingMode(.template).resizable().scaledToFit().foregroundStyle(tint)
                    } else {
                        Image(asset).renderingMode(.original).resizable().scaledToFit()
                    }
                } else if !name.isEmpty {
                    // ชื่อ asset ตรง ๆ (เช่นโลโก้ช่องจากรายการ `socials` ฟิลด์ `icon`)
                    if let tint {
                        Image(name).renderingMode(.template).resizable().scaledToFit().foregroundStyle(tint)
                    } else {
                        Image(name).renderingMode(.original).resizable().scaledToFit()
                    }
                }
            }
        }
        .frame(width: f.width, height: f.height)
        .clipShape(RoundedRectangle(cornerRadius: corner(n, f.size), style: .continuous))
    }

    // MARK: สี

    /// token → สี · `bg` `bg2` `ink` `ink2` `accent` `line` คิดจากพื้น `on` ของโหนด · `white` `black` `clear` `#RRGGBB[AA]` · `@ความทึบ`
    private func color(_ token: String, on: String? = nil) -> Color {
        palette.color(token, on: on)
    }
    /// token ที่อ้างฟิลด์ของรายการ (`$tint` · `$tint@0.3`) — แทนค่าแล้วค่อยแปลง
    private func color(_ token: String, on: String?, item: SpecItem?) -> Color {
        guard token.hasPrefix("$"), let item else { return color(token, on: on) }
        var name = String(token.dropFirst()); var alpha = ""
        if let at = name.firstIndex(of: "@") { alpha = String(name[at...]); name = String(name[..<at]) }
        return color(item.value(name) + alpha, on: on)
    }
}

/// อ้างช่องของโปรไฟล์จากสตริงในผัง — `name` · `categories#2` · `note#1`
struct SlotRef {
    let field: ProfileField
    let index: Int?

    /// ชื่อช่องในผังมีไม่กี่สิบแบบ แต่ถูกแยกซ้ำทุกครั้งที่ตัวคำนวณถามฟอนต์ — จำผลไว้ (รวมชื่อที่ไม่ใช่ช่อง)
    private static var parsed: [String: SlotRef?] = [:]
    static func cached(_ s: String) -> SlotRef? {
        if let hit = parsed[s] { return hit }
        let r = SlotRef(s)
        parsed[s] = .some(r)
        return r
    }

    init?(_ s: String) {
        let parts = s.split(separator: "#", maxSplits: 1).map(String.init)
        guard let f = ProfileField(rawValue: parts[0]) else { return nil }
        field = f
        index = parts.count > 1 ? Int(parts[1]) : nil
    }
}

extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        if h.count == 6 { h += "FF" }
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self.init(red: Double((v >> 24) & 0xFF) / 255, green: Double((v >> 16) & 0xFF) / 255,
                  blue: Double((v >> 8) & 0xFF) / 255, opacity: Double(v & 0xFF) / 255)
    }
}

extension Font.Weight {
    static func from(_ w: Int) -> Font.Weight {
        switch w {
        case ..<200: return .ultraLight
        case ..<300: return .thin
        case ..<400: return .light
        case ..<500: return .regular
        case ..<600: return .medium
        case ..<700: return .semibold
        case ..<800: return .bold
        case ..<900: return .heavy
        default: return .black
        }
    }
}

extension SHIcon {
    /// ชื่อสั้นในผัง → ชื่อ asset
    static func named(_ short: String) -> String {
        switch short {
        case "instagram": return instagram
        case "tiktok": return tiktok
        case "youtube": return youtube
        case "facebook": return facebook
        case "x": return x
        case "lemon8": return lemon8
        case "line": return line
        case "sealCheck": return sealCheck
        case "verifiedPill": return verifiedPill
        case "star": return star
        case "wordmark": return wordmark
        case "watermark": return watermark
        case "qr": return qr
        default: return short
        }
    }
}

private struct SpecShadowModifier: ViewModifier {
    let shadow: SpecShadow?
    let resolve: (String) -> Color
    func body(content: Content) -> some View {
        if let s = shadow {
            // sigma → radius ของ SwiftUI (blur radius ≈ 2σ)
            content.compositingGroup().shadow(color: resolve(s.color), radius: CGFloat(s.sigma) * 2, x: CGFloat(s.x), y: CGFloat(s.y))
        } else {
            content
        }
    }
}

// MARK: - ตัววัดข้อความ (iOS)

final class IOSSpecMeasurer: SpecMeasurer {
    static let shared = IOSSpecMeasurer()
    private var fontCache: [SpecFont: UIFont] = [:]

    func uiFont(_ f: SpecFont) -> UIFont {
        if let c = fontCache[f] { return c }
        let face = CardFont(rawValue: f.face) ?? .noto
        var ui = face.uiFont(f.size, Font.Weight.from(f.weight))
        if f.italic, let d = ui.fontDescriptor.withSymbolicTraits(.traitItalic) { ui = UIFont(descriptor: d, size: f.size) }
        fontCache[f] = ui
        return ui
    }

    func lineHeight(_ font: SpecFont) -> CGFloat {
        let ui = uiFont(font)
        return (ui.lineHeight * font.lineHeight * 100).rounded() / 100
    }

    /// ผลวัดที่เคยวัดแล้ว — ตอนยืดกรอบ ข้อความ/ฟอนต์/ความกว้างเดิมถูกวัดซ้ำทุกเฟรม (และหลายรอบในเฟรมเดียวตอนลองย่อ)
    /// ผลของ `boundingRect` ขึ้นกับสามค่านี้อย่างเดียว จึงจำได้โดยภาพไม่เปลี่ยน
    private struct MeasureKey: Hashable { let text: String; let font: SpecFont; let width: CGFloat? }
    private var measureCache: [MeasureKey: (size: CGSize, lines: Int)] = [:]

    func measure(_ text: String, font: SpecFont, width: CGFloat?) -> (size: CGSize, lines: Int) {
        let key = MeasureKey(text: text, font: font, width: width)
        if let hit = measureCache[key] { return hit }
        // ความกว้างพอให้ข้อความไม่ต้องตัดบรรทัด = ผลเท่ากับวัดแบบไม่จำกัดความกว้างทุกค่า — ใช้ผลนั้นซ้ำ
        // (ตอนยืดกรอบความกว้างเปลี่ยนทุกเฟรม แต่ข้อความส่วนใหญ่สั้นกว่ากล่อง จึงไม่ต้องวัดใหม่เลย)
        if let width {
            let free = measure(text, font: font, width: nil)
            if width >= free.size.width { return free }
            // ตัดบรรทัดแบบใส่คำให้เต็มบรรทัดก่อน (first-fit): วัดที่ W ได้บรรทัดยาวสุด m ⇒ ทุกความกว้างใน [m, W]
            // ตัดตรงเดิมทุกบรรทัด ผลจึงเท่ากันเป๊ะ — จำเป็นช่วงต่อ (ข้อความ, ฟอนต์) แทนการวัดใหม่ทุกเฟรมตอนยืด
            let tf = TextFontKey(text: text, font: font)
            if let hit = wrapRanges[tf]?.first(where: { $0.lo <= width && width <= $0.hi }) { return hit.out }
            let out = measureUncached(text, font: font, width: width)
            if out.size.width <= width {
                if wrapRanges.count > 4_000 { wrapRanges.removeAll(keepingCapacity: true) }
                wrapRanges[tf, default: []].append((out.size.width, width, out))
            }
            return out
        }
        let out = measureUncached(text, font: font, width: width)
        if measureCache.count > 20_000 { measureCache.removeAll(keepingCapacity: true) }
        measureCache[key] = out
        return out
    }
    private struct TextFontKey: Hashable { let text: String; let font: SpecFont }
    private var wrapRanges: [TextFontKey: [(lo: CGFloat, hi: CGFloat, out: (size: CGSize, lines: Int))]] = [:]

    private func measureUncached(_ text: String, font: SpecFont, width: CGFloat?) -> (size: CGSize, lines: Int) {
        let ui = uiFont(font)
        let para = NSMutableParagraphStyle()
        para.lineBreakMode = .byWordWrapping
        var attrs: [NSAttributedString.Key: Any] = [.font: ui, .paragraphStyle: para]
        if font.kerning != 0 { attrs[.kern] = font.kerning }
        if font.tracking != 0 { attrs[.tracking] = font.tracking }
        let a = NSAttributedString(string: text, attributes: attrs)
        let lh = ui.lineHeight
        let w = width ?? CGFloat.greatestFiniteMagnitude
        let r = a.boundingRect(with: CGSize(width: w, height: .greatestFiniteMagnitude),
                               options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let lines = max(1, Int((r.height / max(lh, 1)).rounded()))
        let h = CGFloat(lines) * lineHeight(font)
        return (CGSize(width: (ceil(r.width * 100)) / 100, height: h), lines)
    }
}

// MARK: - แหล่งข้อมูล (iOS)

struct IOSSpecData: SpecDataSource {
    let sample: Bool
    let widget: UUID?
    var inkLight: Bool = false
    var kit: KitConfig = KitConfig()
    var border: Bool = false
    /// พื้นผิวที่ผู้ใช้เลือกให้ชิ้น (ถาด "พื้นหลัง") — ผังอ่านเป็น `surface=glass` · `papered` (WIDGET-SPEC.md §3.4)
    var surface: WidgetSurface = .glass
    /// การ์ดคู่สีอยู่ไหม — สำรับกระดาษ/โปสเตอร์สลับแผ่นเป็นสีเข้มของคู่
    var duo: Bool = false
    /// ใบนี้ได้ดวงตรา "Verified by Sale Here" (ข้อมูลตรวจแล้ว — ดู `SaleHereStamp`) · ผังวาดพิล `icon: verifiedPill` เมื่อ `stamped`
    var stamped: Bool = false
    /// รูปช่อง 1 เป็นคนที่ตัดพื้นแล้ว (PNG ของผู้ใช้ หรือ Vision ยกตัวได้) — ใบโปสเตอร์สลับ "คนยืนคร่อม" กับ "รูปในกรอบ" (`cutout`)
    var cutout: Bool = false
    /// แผ่นของชุดห้าสไตล์มืดไหม (`KitLook.dark`) — พิล/แถบที่สลับอ่อน-เข้มตามแผ่น
    var kitDark: Bool = false

    func text(slot: String, preset: String?) -> String {
        let p = Profile.me
        // ค่าที่ระบบคิดให้ (อ่านอย่างเดียว) — `stat:<name>` (WIDGET-SPEC.md §3.2)
        if slot.hasPrefix("stat:") {
            let f = StarFlow.shared
            switch String(slot.dropFirst(5)) {
            // ช่องทางติดต่อของ Star Profile (ชุดห้าสไตล์อ่านจาก StarFlow · เบอร์จัดรูป 3-3-4)
            case "phoneFmt":
                let v = f.phone
                if v.isEmpty { return sample ? "081-234-5678" : "" }
                let d = v.filter(\.isNumber)
                return d.count == 10 ? "\(d.prefix(3))-\(d.dropFirst(3).prefix(3))-\(d.suffix(4))" : v
            case "site":
                let v = f.website.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
                return v.isEmpty && sample ? "nirabeauty.co" : v
            case "lineFlow":
                let v = f.lineID; return v.isEmpty && sample ? "@nirabeauty" : v
            case "totalFollowers": return Fmt.compact(p.shownSocials.reduce(0) { $0 + $1.followerCount })
            case "avgViews": return Fmt.compact(p.shownSocials.reduce(0) { $0 + $1.avgViewCount } / max(1, p.shownSocials.count))
            case "brandCount": return String(p.shownTrack(.brand).brands.count)
            case "workCount": return String(p.shownTrack(.verified).works.count)
            case "socialCount": return String(p.shownSocials.count)
            // ประเภทครีเอเตอร์ของ Star Profile (API `creatorType`) — ยังไม่ตอบ = ว่าง ผังซ่อนเอง
            case "creatorKind":
                switch p.intake?.kind { case .creator: return "บุคคล"; case .page: return "เพจ"; case nil: return sample ? "บุคคล" : "" }
            case "rateCount": return String(p.shownRates.filter { $0.price > 0 }.count)
            case "cardURL": return "https://salehere.co.th/star/" + p.handle
            case "year": return "2026"
            case "placeCount": return String(p.shownAudience.places.count)
            // ยังไม่มีการเข้าถึง (0) = ว่าง — ผังซ่อนบล็อกด้วย `has:stat:reach` แทนการโชว์ "0"
            case "reach": let r = p.shownAudience.reach; return r.accounts > 0 ? Fmt.compact(r.accounts) : ""
            case "reachRaw": let r = p.shownAudience.reach; return r.accounts > 0 ? String(r.accounts) : ""
            case "reachDelta": let r = p.shownAudience.reach; return r.accounts > 0 ? (r.delta >= 0 ? "+" : "") + Fmt.pct(r.delta) : ""
            case "reachNew": let r = p.shownAudience.reach; return r.accounts > 0 ? Fmt.pct(r.newShare) : ""
            case "reachWindow": return p.shownAudience.reach.window
            case "reachPlatform": return p.shownAudience.reach.platform.name
            case "reachIcon": return p.shownAudience.reach.platform.icon
            default: return ""
            }
        }
        // จำนวนชิ้นของรายการ — `count:<list>`
        if slot.hasPrefix("count:") { return String(list(String(slot.dropFirst(6))).count) }
        guard let ref = SlotRef(slot) else { return "" }
        if ref.field == .about, sample { return p.shownAbout }
        // ช่องอิสระของชิ้น: ค่าที่พิมพ์ → ข้อความตั้งต้นของดีไซน์ (preset) → ป้ายชวนพิมพ์ (เหมือน `Profile.note`)
        let id = TextSlotID(field: ref.field, index: ref.index, widget: ref.field == .note ? widget : nil, preset: preset ?? "")
        return p.text(id)
    }

    func flag(_ name: String) -> Bool {
        switch name {
        case "owner.verified": return VerifiedFacts.sealed || Profile.me.creator.verified
        case "sample": return sample
        case "ink.light": return inkLight
        case "bordered": return border
        // พื้นผิวของชิ้น: `papered` = ใบวาดแผ่น/กระดาษของตัวเอง (กระจก · เข้ม) · `pane` = chrome ครอบกระจกให้ · `clear` = ไม่มีพื้น
        case "papered": return surface == .glass || surface == .dim
        case "duo": return duo
        case "stamped": return stamped
        case "cutout": return cutout
        case "kit.dark": return kitDark
        default: break
        }
        if name.hasPrefix("surface=") { return surface.rawValue == String(name.dropFirst(8)) }
        // ค่าของชิ้นในชุดห้าสไตล์: `cfg:fill=clear` · `cfg:corner=square` · `opt:qr` · `opt:mode=fmt` · `hidden:instagram`
        if name.hasPrefix("cfg:") {
            let body = name.dropFirst(4)
            guard let eq = body.firstIndex(of: "=") else { return false }
            let k = String(body[..<eq]), v = String(body[body.index(after: eq)...])
            switch k {
            case "fill": return kit.fill.rawValue == v
            case "corner": return kit.corner.rawValue == v
            default: return false
            }
        }
        if name.hasPrefix("opt:") {
            let body = name.dropFirst(4)
            if let eq = body.firstIndex(of: "=") {
                return (kit.opts[String(body[..<eq])] ?? "") == String(body[body.index(after: eq)...])
            }
            let v = kit.opts[String(body)] ?? ""
            return !v.isEmpty && v != "0"
        }
        if name.hasPrefix("hidden:") { return kit.list(KitOpt.hide).contains(String(name.dropFirst(7))) }
        return false
    }

    func list(_ name: String) -> [SpecItem] {
        let p = Profile.me
        switch name {
        case "categories":
            let cats = p.categories
            return cats.enumerated().map { SpecItem(id: "cat\($0.offset)", i: $0.offset, fields: ["text": $0.element]) }
        case "socials":
            return p.shownSocials.enumerated().map { (i, s) in
                SpecItem(id: s.type.rawValue, i: i, fields: [
                    "platform": s.type.rawValue, "name": s.type.name, "short": s.type.shortName,
                    "icon": s.type.icon, "tint": s.type.tintHex, "handle": s.handle, "followers": Fmt.compact(s.followerCount),
                    "followersRaw": String(s.followerCount), "followersFull": Fmt.thousands(s.followerCount), "viewsFull": Fmt.thousands(s.avgViewCount),
                    "views": Fmt.compact(s.avgViewCount), "viewsRaw": String(s.avgViewCount), "engagement": Fmt.fixed(s.engagementRate, 1) + "%",
                    "engagementRaw": String(s.engagementRate), "synced": s.syncedAgo, "verified": s.source.isVerified ? "1" : ""])
            }
        case "rates":
            return p.shownRates.filter { $0.price > 0 }.enumerated().map { (i, r) in
                SpecItem(id: r.id, i: i, fields: [
                    "label": r.label, "price": "฿" + Fmt.thousands(r.price), "priceRaw": String(r.price),
                    "unit": r.unit, "platform": r.platform.rawValue, "platformName": r.platform.name,
                    "platformOrder": String(SocialType.allCases.firstIndex(of: r.platform) ?? 99), "priceNum": Fmt.thousands(r.price), "icon": r.platform.icon, "tint": r.platform.tintHex, "format": r.format.rawValue])
            }
        case "brands":
            return p.shownTrack(.brand).brands.enumerated().map { (i, b) in
                SpecItem(id: b.name, i: i, fields: ["name": b.name, "logo": b.logo ?? "", "industry": b.industry])
            }
        case "works":
            return p.shownTrack(.verified).works.enumerated().map { (i, w) in
                SpecItem(id: w.id.uuidString, i: i, fields: [
                    "brand": w.brand, "ep": w.ep, "campaign": w.campaign, "platform": w.platform.rawValue,
                    "icon": w.platform.icon, "tint": w.platform.tintHex, "format": w.format, "views": Fmt.compact(w.views), "viewsRaw": String(w.views), "photo": String(4 + i),
                    // ผลงานตัวจริงของชิ้น (`WorkPicture`): ปก asset ก่อน · ไม่มีก็ช่องรูปของผลงาน — `image` ใช้ `"src": "$cover"` + `"photo": "$workPhoto"`
                    "workPhoto": String(w.photo), "cover": w.cover ?? "",
                    "saves": Fmt.compact(w.saves), "savesRaw": String(w.saves), "shares": Fmt.compact(w.shares), "sharesRaw": String(w.shares),
                    "likes": Fmt.compact(w.likes), "comments": Fmt.compact(w.comments),
                    "engageRaw": String(w.likes + w.comments + w.shares + w.saves),
                    "engagement": Fmt.fixed(w.engagementRate, 1) + "%", "viralTag": w.viralTag ?? "",
                    "brandLogo": p.shownTrack(.verified).brands.first { $0.name == w.brand }.flatMap { $0.logo ?? $0.asset } ?? ""])
            }
        case "body":
            // สัดส่วน (`KitWidget.bodyCells`) — id h/w/g/s · label · value ("165 cm") · num · unit · wide ("1" = เต็มแถว)
            let f = StarFlow.shared
            let b = f.bodyInfo.filled || !sample ? f.bodyInfo : StarBody.sample
            var out: [(String, String, String, String, String, Bool)] = []
            if !b.height.isEmpty { out.append(("h", "ส่วนสูง", "\(b.height) cm", b.height, "ซม.", false)) }
            if !b.weight.isEmpty { out.append(("w", "น้ำหนัก", "\(b.weight) kg", b.weight, "กก.", false)) }
            let girth = [b.chest, b.waist, b.hip]
            if girth.contains(where: { !$0.isEmpty }) {
                let same = Set([b.chestUnit, b.waistUnit, b.hipUnit]).count == 1
                let v = same ? girth.map { $0.isEmpty ? "–" : $0 }.joined(separator: " / ")
                             : [(b.chest, b.chestUnit), (b.waist, b.waistUnit), (b.hip, b.hipUnit)].map { "\($0.0) \($0.1)" }.joined(separator: " · ")
                out.append(("g", "รอบอก / เอว / สะโพก", v, v, same ? b.chestUnit : "", true))
            }
            if !b.shoe.isEmpty { out.append(("s", "ไซซ์รองเท้า", "EU \(b.shoe)", b.shoe, "EU", false)) }
            return out.enumerated().map { (i, c) in
                SpecItem(id: c.0, i: i, fields: ["kind": c.0, "label": c.1, "value": c.2, "num": c.3, "unit": c.4, "wide": c.5 ? "1" : ""])
            }
        case "avail":
            let s = StarFlow.shared.availSummary
            let lines = s.isEmpty && sample ? ["ส–อา 17.00 เป็นต้นไป"] : s
            return lines.enumerated().map { SpecItem(id: "t\($0.offset)", i: $0.offset, fields: ["text": $0.element]) }
        case "areas":
            let p = StarFlow.shared.provinces
            let lines = p.isEmpty && sample ? ["กรุงเทพมหานคร", "นนทบุรี"] : p
            return lines.enumerated().map { SpecItem(id: "a\($0.offset)", i: $0.offset, fields: ["text": $0.element]) }
        case "contacts":
            var out: [SpecItem] = []
            let pairs: [(String, String, String, String)] = [
                ("phone", p.phone, "ph:phone", "phone"), ("email", p.email, "ph:envelope", "email"),
                ("line", p.lineId, "sh:line", "lineId"), ("web", p.website, "ph:globe", "website")]
            // ไอคอนที่สร้างที่นี่ (ไม่อยู่ในผัง) ต้องมี asset ทั้งสามแพลตฟอร์ม — Android `SpecIconCoverageTest` ตรวจชื่อชุดนี้ด้วย
            for (k, v, icon, slot) in pairs where !v.isEmpty {
                out.append(SpecItem(id: k, i: out.count, fields: ["kind": k, "value": v, "icon": icon, "slot": slot]))
            }
            return out
        case "ages":
            return p.shownAudience.ages.enumerated().map { (i, a) in
                SpecItem(id: a.label, i: i, fields: ["label": a.label, "share": Fmt.fixed(a.share, 0) + "%", "shareRaw": String(a.share)])
            }
        case "places":
            return p.shownAudience.places.enumerated().map { (i, a) in
                SpecItem(id: a.name, i: i, fields: ["name": a.name, "share": Fmt.fixed(a.share, 0) + "%", "shareRaw": String(a.share)])
            }
        case "gender":
            let a = p.shownAudience
            return [("หญิง", a.female, "#FF8CBD"), ("ชาย", a.male, "#8299FF"), ("อื่น ๆ", a.other, "#5CE6AD")].enumerated().map { (i, g) in
                SpecItem(id: g.0, i: i, fields: ["label": g.0, "share": Fmt.fixed(g.1, 0) + "%", "shareRaw": String(g.1), "tint": g.2])
            }
        case "photos":
            return (0..<6).map { SpecItem(id: "p\($0)", i: $0, fields: ["photo": String(4 + $0)]) }
        default:
            return []
        }
    }

    func font(slot: String?, face: String, size: CGFloat, weight: Int) -> SpecFont {
        var f = SpecFont(face: CardFont(rawValue: face)?.rawValue ?? "noto", size: size, weight: weight)
        // ช่องที่ผูกข้อมูลจำกัดขนาด 6–160 (ไม่มีการปรับขนาด/ฟอนต์ของผู้ใช้แล้ว)
        if let slot, SlotRef.cached(slot) != nil { f.size = min(max(size, 6), 160) }
        return f
    }
}

extension Fmt {
    static func thousands(_ n: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.groupingSeparator = ","
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }
}


extension SocialType {
    /// สีของช่องเป็น hex ตายตัว — ตารางเดียวกันทุกแพลตฟอร์ม (WIDGET-SPEC.md §3.2)
    var tintHex: String {
        switch self {
        case .instagram: return "#E85C9E"
        case .tiktok:    return "#33F0EB"
        case .youtube:   return "#FF524D"
        case .facebook:  return "#5C8FFA"
        case .lemon8:    return "#FFD640"
        case .x:         return "#D9D9E0"
        }
    }
}


/// ต้นไม้จากรายการกล่องแบน — ลูกของ `r/0` คือ `r/0/<n>` และ `r/0/c<n>`
struct SpecTree {
    let root: SpecBox?
    let children: [String: [SpecBox]]
    /// handle ที่ QR ของใบนี้ชี้ไป (จากแหล่งข้อมูลของใบ — ตั้งโดยตัววาด)
    let handle: String
    init(_ boxes: [SpecBox], handle: String = "") {
        self.handle = handle
        root = boxes.first { $0.id == "r" }
        var map: [String: [SpecBox]] = [:]
        for b in boxes where b.id != "r" {
            guard let cut = b.id.lastIndex(of: "/") else { continue }
            map[String(b.id[..<cut]), default: []].append(b)
        }
        children = map
    }
}

private struct WidgetRenderScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    /// สเกลที่ chrome คูณทั้งใบ (`min(W/w0, H/h0)`) — ตัวคำนวณใช้คิดขั้นต่ำที่อ่านออก (`SpecLegibility`)
    /// ภาพย่อในตู้/แม่แบบไม่ผ่าน chrome = 1 (ไม่มีขั้นต่ำ)
    var widgetRenderScale: CGFloat {
        get { self[WidgetRenderScaleKey.self] }
        set { self[WidgetRenderScaleKey.self] = newValue }
    }
}

// MARK: - จำผลของตัวคำนวณ

/// SwiftUI เรียก `body` ซ้ำทุกเฟรมตอนลาก/ย่อขยาย/มีแอนิเมชัน — คิดผังใหม่ทุกครั้งเปลืองเปล่า (15 ต.ค. 2569)
///
/// กุญแจ = ผัง (+ รุ่นของแคตตาล็อก) · กรอบ · สเกล · ค่าของชิ้น · และ **ทุกคำถามที่ตัวคำนวณถามแหล่งข้อมูลรอบก่อน**
/// ถามซ้ำแล้วได้คำตอบเดิมทุกข้อ = ผลเดิมแน่นอน (ข้อมูลโปรไฟล์/โน้ต/Star Profile เปลี่ยนเมื่อไหร่ คำตอบต่าง → คิดใหม่เอง)
final class SpecSolveMemo {
    static let shared = SpecSolveMemo()

    private enum Q: Hashable {
        case text(String, String?, String)
        case list(String, [SpecItem])
        case flag(String, Bool)
        case font(String?, String, CGFloat, Int, SpecFont)
    }

    /// ตัวจดคำถาม/คำตอบระหว่างคิดผังหนึ่งรอบ
    private final class Recorder: SpecDataSource {
        let base: SpecDataSource
        var log: [Q] = []
        init(_ base: SpecDataSource) { self.base = base }
        func text(slot: String, preset: String?) -> String { let v = base.text(slot: slot, preset: preset); log.append(.text(slot, preset, v)); return v }
        func list(_ name: String) -> [SpecItem] { let v = base.list(name); log.append(.list(name, v)); return v }
        func flag(_ name: String) -> Bool { let v = base.flag(name); log.append(.flag(name, v)); return v }
        func font(slot: String?, face: String, size: CGFloat, weight: Int) -> SpecFont {
            let v = base.font(slot: slot, face: face, size: size, weight: weight); log.append(.font(slot, face, size, weight, v)); return v
        }
    }

    private struct Entry { var questions: [Q]; var boxes: [SpecBox]; var scale: CGFloat }
    private var entries: [String: Entry] = [:]

    private func same(_ q: Q, _ d: SpecDataSource) -> Bool {
        switch q {
        case let .text(slot, preset, v): return d.text(slot: slot, preset: preset) == v
        case let .list(name, v): return d.list(name) == v
        case let .flag(name, v): return d.flag(name) == v
        case let .font(slot, face, size, weight, v): return d.font(slot: slot, face: face, size: size, weight: weight) == v
        }
    }

    func solve(_ spec: WidgetSpec, box: CGSize, data: IOSSpecData, renderScale: CGFloat) -> ([SpecBox], CGFloat) {
        let key = "\(spec.kind)|\(SpecCatalog.generation)|\(box.width)x\(box.height)|\(renderScale)|\(data.sample)|\(data.widget?.uuidString ?? "")|"
            + "\(data.inkLight)|\(data.surface)|\(data.border)|\(data.duo)|\(data.stamped)|\(data.cutout)|\(data.kitDark)|\(data.kit)"
        if let e = entries[key], e.questions.allSatisfy({ same($0, data) }) { return (e.boxes, e.scale) }
        let rec = Recorder(data)
        let solver = SpecSolver(spec: spec, box: box, data: rec, measurer: IOSSpecMeasurer.shared, renderScale: renderScale)
        let boxes = solver.solve()
        if entries.count > 600 { entries.removeAll(keepingCapacity: true) }
        entries[key] = Entry(questions: rec.log, boxes: boxes, scale: solver.scale)
        return (boxes, solver.scale)
    }
}


// MARK: - วางลูกตามพิกัดที่ตัวคำนวณให้มาแล้ว

/// ที่มุมบนซ้ายของลูกในกล่องแม่ (หน่วยออกแบบ) — ตั้งด้วย `.layoutValue(key: SpecOrigin.self, …)`
private struct SpecOrigin: LayoutValueKey {
    static let defaultValue = CGPoint.zero
}

/// คอนเทนเนอร์ของโหนด — วางลูกทุกตัวที่พิกัดที่ `SpecSolver` คิดไว้แล้ว ไม่จัดอะไรเอง
///
/// เดิมเป็น `ZStack(alignment: .topLeading)` + `.offset` ซึ่งได้ภาพเท่ากัน แต่ทุกรอบจัดหน้า SwiftUI ไล่ถาม
/// เส้นจัดแนว (`explicitAlignment`) ลงไปทุกชั้นของต้นไม้ผัง — ตอนยืดกรอบ (ทุกเฟรม) นั่นคือเวลาส่วนใหญ่ของเธรดหลัก
/// ที่นี่ตอบ "ไม่มีเส้นจัดแนว" ทันที การถามจึงหยุดที่กล่องนี้
private struct SpecPlace: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let size = ProposedViewSize(width: bounds.width, height: bounds.height)
        for v in subviews {
            let o = v[SpecOrigin.self]
            v.place(at: CGPoint(x: bounds.minX + o.x, y: bounds.minY + o.y), anchor: .topLeading, proposal: size)
        }
    }

    func explicitAlignment(of guide: HorizontalAlignment, in bounds: CGRect, proposal: ProposedViewSize,
                           subviews: Subviews, cache: inout ()) -> CGFloat? { nil }

    func explicitAlignment(of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize,
                           subviews: Subviews, cache: inout ()) -> CGFloat? { nil }
}
