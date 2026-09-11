import SwiftUI
import PhotosUI
import CoreImage.CIFilterBuiltins

/// คลังรูปของการ์ด
///
/// รูปที่ผู้ใช้อัปโหลดจะถูกใช้ก่อนเสมอ ถ้ายังไม่มีค่อยตกไปใช้รูปสังเคราะห์ที่แถมมา
/// ทำให้ทดลอง layout ได้โดยไม่ต้องรอ asset จริง แล้ววันที่ต่อ ImageKit ก็แทนที่แค่ชั้นนี้
/// การจัดกรอบรูปในช่องหนึ่งช่อง — เลื่อนและซูมหลังวางรูปเข้าไป
///
/// # ทำไมต้องมี
///
/// ทุกช่องรูปในตู้ใช้ `.aspectRatio(contentMode: .fill)` ซึ่งครอบ **จากกึ่งกลางเสมอ** —
/// รูปที่คนถ่ายมาส่วนใหญ่ไม่ได้วางของสำคัญไว้กลางเฟรม (หน้าอยู่บน · สินค้าอยู่มุมล่าง)
/// พอวางลงช่องแนวตั้งแคบ ๆ สิ่งที่อยากโชว์จึงหลุดกรอบไปเฉย ๆ และผู้ใช้แก้อะไรไม่ได้เลย
/// นอกจากไปครอปในแอปอื่นแล้วอัปโหลดใหม่ ซึ่งคือจุดที่คนเลิกแต่งการ์ด
///
/// # ทำไมเก็บเป็นสัดส่วน ไม่ใช่พิกเซล
///
/// `dx`/`dy` คือสัดส่วนของ **ขนาดภาพที่เรนเดอร์จริง** ไม่ใช่จำนวนพอยต์ —
/// ผู้ใช้ยืดกรอบ widget ทีหลัง จุดที่เลือกไว้จึงยังอยู่ตรงเดิม ไม่เลื่อนตามขนาดกรอบ
struct PhotoFit: Equatable {
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    /// ซูมเข้าอย่างเดียว (≥ 1) — ต่ำกว่า 1 เมื่อไหร่ภาพหดจนเห็นพื้นว่างในกรอบ
    var zoom: CGFloat = 1

    static let identity = PhotoFit()
    var isIdentity: Bool { self == .identity }
}

/// ที่อยู่ของช่องรูปหนึ่งช่อง — widget ไหน ช่องที่เท่าไหร่
struct PhotoSlotRef: Hashable {
    let widget: UUID
    let slot: Int
}

@Observable
final class PhotoStore {
    private(set) var uploaded: [UIImage] = []
    /// รูปพื้นหลังการ์ดที่ผู้ใช้อัปโหลดเอง — แยกจากคลังรูปเนื้อหา
    private(set) var background: UIImage?
    /// รูปเฉพาะของ widget แต่ละตัว — ทับคลังรวมและรูปตั้งต้นของระบบ
    ///
    /// เก็บเป็น "ช่องที่เท่าไหร่ของ widget ไหน" ไม่ใช่กองรวมต่อ widget
    /// เพราะ widget อย่างเบนโตะ/แถบภาพมีรูปหลายใบ ครีเอเตอร์ต้องชี้ได้ว่าจะเปลี่ยนใบไหน
    private(set) var perWidget: [UUID: [Int: UIImage]] = [:]
    /// การจัดกรอบของแต่ละช่อง — ว่างไว้แปลว่ายังเป็นครอปกลางเฟรมตามเดิม
    private(set) var fits: [UUID: [Int: PhotoFit]] = [:]
    /// ช่องที่กำลังถูกจัดกรอบอยู่ · nil = ไม่มีใครถูกจัด
    ///
    /// อยู่ในสโตร์ ไม่ใช่ใน `CardScreen` เพราะทั้งปุ่มบนตัวรูปและชั้นการ์ดที่วางแผ่นลากทับ
    /// ต้องอ่านค่าเดียวกัน (เหตุผลเดียวกับ `Profile.editing`)
    var framing: PhotoSlotRef?

    /// วางรูปลงช่อง `slot` แล้วไหลต่อไปช่องถัดไปตามลำดับที่ widget วางไว้
    /// เลือกมาใบเดียว = เปลี่ยนเฉพาะช่องนั้น · เลือกมาหลายใบ = ไล่เติมช่องที่เหลือให้ในทีเดียว
    func set(_ images: [UIImage], from slot: Int, order: [Int], for id: UUID) {
        guard let start = order.firstIndex(of: slot) else { return }
        for (k, image) in images.enumerated() where order.indices.contains(start + k) {
            let s = order[start + k]
            perWidget[id, default: [:]][s] = image
            // รูปใหม่ = กรอบใหม่ · การเก็บค่าเลื่อนของรูปเก่าไว้ทำให้รูปที่เพิ่งวางเข้าไปเบี้ยวทันที
            fits[id]?[s] = nil
        }
    }
    func clear(_ id: UUID) {
        perWidget[id] = nil
        fits[id] = nil
    }
    func clear(slot: Int, for id: UUID) {
        perWidget[id]?[slot] = nil
        // คืนรูประบบ = คืนกรอบตั้งต้นด้วย ไม่งั้นรูปใหม่โผล่มาพร้อมกรอบของรูปเก่า
        fits[id]?[slot] = nil
        if framing == PhotoSlotRef(widget: id, slot: slot) { framing = nil }
    }
    func has(slot: Int, for id: UUID) -> Bool { perWidget[id]?[slot] != nil }

    // MARK: จัดกรอบรูป

    func fit(slot: Int, for id: UUID?) -> PhotoFit {
        guard let id else { return .identity }
        return fits[id]?[slot] ?? .identity
    }
    func setFit(_ f: PhotoFit, slot: Int, for id: UUID) {
        fits[id, default: [:]][slot] = f
    }
    func resetFit(slot: Int, for id: UUID) { fits[id]?[slot] = nil }
    /// รูปจริงในช่อง — ตัวจัดกรอบต้องรู้สัดส่วนของภาพถึงจะคำนวณขอบเขตการเลื่อนได้
    ///
    /// ไล่ลำดับเดียวกับ `image(_:for:)` เป๊ะ ๆ รวมถึงรูประบบที่แคชไว้แล้ว —
    /// ถ้าตัวนี้ตอบไม่ตรงกับที่วาดจริง ขอบเขตการเลื่อนจะคำนวณจากสัดส่วนของภาพอื่น
    @MainActor
    func uiImage(slot i: Int, for id: UUID) -> UIImage? {
        if let own = perWidget[id]?[i] { return own }
        if !uploaded.isEmpty { return uploaded[i % uploaded.count] }
        return ImageCache.shared.cached(PhotoLib.url(i))
    }
    func count(for id: UUID) -> Int { perWidget[id]?.count ?? 0 }

    var hasUploads: Bool { !uploaded.isEmpty }
    var count: Int { max(uploaded.count, PhotoLib.count) }

    // MARK: รูปพื้นหลัง

    /// รูปพื้นหลังอยู่บนดิสก์ ไม่ใช่แค่ในหน่วยความจำ
    ///
    /// # ทำไมตัวนี้ตัวเดียวถึงถูกเซฟ
    ///
    /// รูปในคลังกับรูปต่อ widget เป็น **เนื้อหา** ซึ่งของจริงต้องไปอยู่บน API พร้อมกับ
    /// ตัวการ์ด (ดู `WidgetContent.swift`) ยัดลงเครื่องตอนนี้เท่ากับสร้างที่เก็บซ้อนที่ต้องรื้อทีหลัง
    /// ส่วนรูปพื้นหลังเป็น **ธีม** — มันถูกอ้างจาก `CardTheme.backdrop == .photo` ที่เซฟลง
    /// `UserDefaults` ไปแล้ว ถ้าไม่เก็บตัวรูปไว้ด้วย การเปิดแอปครั้งถัดไปจะได้การ์ดที่บอกว่า
    /// "พื้นหลังเป็นรูป" แต่ไม่มีรูป แล้วตกไปใช้รูประบบเบลอ ๆ แทนโดยไม่มีใครสั่ง
    private static var backgroundURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("starcard-backdrop.jpg")
    }

    init() {
        // อ่านตอนเกิดเลย ไม่รอ `.task` — `CardBackdrop` วาดในเฟรมแรกที่การ์ดขึ้น
        // ถ้าโหลดทีหลังผู้ใช้จะเห็นพื้นกระพริบจากรูปสำรองไปเป็นรูปตัวเองทุกครั้งที่เปิดแอป
        if let url = Self.backgroundURL { background = UIImage(contentsOfFile: url.path) }
    }

    func setBackground(_ image: UIImage) {
        background = image
        baked.removeAll()
        write(image)
    }

    func clearBackground() {
        background = nil
        baked.removeAll()
        write(nil)
    }

    /// รูปพื้นหลังที่ผ่านเอฟเฟกต์แล้ว
    ///
    /// ขาวดำกับเบลอไม่ผ่านทางนี้ — สองตัวนั้นเป็น modifier ของ SwiftUI ที่ทำสดได้ทุกเฟรม
    /// ส่วนจุดปะต้องผ่าน CoreImage ซึ่งแพงเกินกว่าจะทำใน `body` ที่วาดใหม่ทุกครั้งที่ลาก widget
    /// จึงอบครั้งเดียวแล้วแคชไว้ — ท่าเดียวกับ QR ใน `BookingWidgets`
    func background(_ effect: BackdropEffect) -> UIImage? {
        guard let base = background else { return nil }
        guard effect.isBaked else { return base }
        if let hit = baked[effect.rawValue] { return hit }
        let made = Self.bake(effect, base) ?? base
        baked[effect.rawValue] = made
        return made
    }

    /// แคชของที่อบแล้ว — **ห้ามให้ระบบ observation มองเห็น** เพราะมันถูกเขียนระหว่างวาด
    /// ถ้าประกาศเป็นตัวแปรปกติ การอบครั้งแรกจะสั่งให้วาดใหม่ แล้ววนกลับมาอบอีกไม่จบ
    @ObservationIgnored private var baked: [String: UIImage] = [:]
    @ObservationIgnored private static let ciContext = CIContext()

    private static func bake(_ effect: BackdropEffect, _ image: UIImage) -> UIImage? {
        guard effect == .halftone, let cg = image.cgImage else { return nil }
        let ci = CIImage(cgImage: cg)
        // ย่อก่อนอบ — จุดปะที่ความละเอียดกล้องคือจุดเล็กจนตาไม่อ่านว่าเป็นลาย เห็นเป็นภาพเทา ๆ
        // และ CoreImage บนภาพสิบกว่าล้านพิกเซลใช้เวลานานพอให้รู้สึกว่าแอปค้างตอนกดชิป
        let long = max(ci.extent.width, ci.extent.height)
        let k = min(1, 1200 / max(long, 1))
        let small = ci.transformed(by: CGAffineTransform(scaleX: k, y: k))
        let f = CIFilter.dotScreen()
        f.inputImage = small
        f.center = CGPoint(x: small.extent.midX, y: small.extent.midY)
        f.angle = 0
        f.width = 8
        f.sharpness = 0.7
        guard let out = f.outputImage,
              let made = ciContext.createCGImage(out, from: small.extent) else { return nil }
        return UIImage(cgImage: made)
    }

    /// บีบอัดและเขียนนอกเธรดหลัก — รูปจากกล้องใบหนึ่งใช้เวลานานพอให้จังหวะที่แตะเลือกรูปสะดุด
    private func write(_ image: UIImage?) {
        guard let url = Self.backgroundURL else { return }
        DispatchQueue.global(qos: .utility).async {
            guard let image else {
                try? FileManager.default.removeItem(at: url)
                return
            }
            guard let data = image.jpegData(compressionQuality: 0.9) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }

    func add(_ images: [UIImage]) {
        uploaded.append(contentsOf: images)
    }

    func remove(at index: Int) {
        guard uploaded.indices.contains(index) else { return }
        uploaded.remove(at: index)
    }

    func clear() { uploaded.removeAll() }

    /// รูปลำดับที่ i — วนซ้ำถ้าขอเกินจำนวนที่มี
    ///
    /// ลำดับความสำคัญ: รูปที่วางไว้ในช่องนี้ของ widget ตัวนั้น → คลังรวมของการ์ด → รูปตั้งต้นจากระบบ
    /// ตกท้ายที่รูประบบเสมอ การ์ดจึงไม่มีวันว่างเปล่าตั้งแต่เปิดแอป
    @ViewBuilder
    func image(_ i: Int, for id: UUID? = nil) -> some View {
        if let id, let own = perWidget[id]?[i] {
            Image(uiImage: own).resizable()
        } else if !uploaded.isEmpty {
            Image(uiImage: uploaded[i % uploaded.count]).resizable()
        } else {
            RemotePhoto(url: PhotoLib.url(i))
        }
    }
}

// MARK: - รูปในบริบทของ widget

/// id ของ widget ที่กำลังวาดอยู่ — ส่งลงมาทาง environment
/// ให้รูปข้างในรู้ว่าตัวเองสังกัด widget ไหน โดยไม่ต้องส่ง id ผ่านทุกชั้น
private struct WidgetIDKey: EnvironmentKey {
    static let defaultValue: UUID? = nil
}

extension EnvironmentValues {
    var widgetID: UUID? {
        get { self[WidgetIDKey.self] }
        set { self[WidgetIDKey.self] = newValue }
    }
}

/// กรอบของช่องรูปหนึ่งช่อง — ส่งขึ้นไปให้ชั้นการ์ดรู้ว่าจะแปะปุ่มเปลี่ยนรูปตรงไหน
///
/// ส่งเป็น anchor แทนพิกัดดิบ เพราะช่องรูปอยู่ลึกหลายชั้นในตัว widget
/// และ widget ทั้งก้อนถูกปิด hit testing ไว้ ปุ่มจึงต้องไปวาดที่ชั้นบนสุดของ tile แทน
struct PhotoSlotAnchor: Equatable {
    let index: Int
    let bounds: Anchor<CGRect>
}

struct PhotoSlotKey: PreferenceKey {
    static let defaultValue: [PhotoSlotAnchor] = []
    static func reduce(value: inout [PhotoSlotAnchor], nextValue: () -> [PhotoSlotAnchor]) {
        value += nextValue()
    }
}

extension View {
    /// ประกาศว่ากรอบนี้คือช่องรูปหมายเลข `index` ของ widget
    /// ติดไว้ที่ "กรอบของช่อง" ไม่ใช่ที่ตัวรูป เพราะรูปแบบ .fill ล้นกรอบ ปุ่มจะไปเกาะนอกช่อง
    func photoSlot(_ index: Int) -> some View {
        anchorPreference(key: PhotoSlotKey.self, value: .bounds) {
            [PhotoSlotAnchor(index: index, bounds: $0)]
        }
    }
}

/// รูปหนึ่งใบในบริบทของ widget — เลือกให้เองว่าใช้รูปของ widget นี้ ของการ์ด หรือของระบบ
struct WidgetPhoto: View {
    let index: Int

    @Environment(PhotoStore.self) private var store
    @Environment(\.widgetID) private var wid

    var body: some View {
        let f = store.fit(slot: index, for: wid)
        // `visualEffect` ไม่แตะเลย์เอาต์ — ภาพยังรายงานสัดส่วนเดิมให้ `.aspectRatio(.fill)`
        // ของผู้เรียกทุกตัวได้เหมือนเดิม ที่เปลี่ยนคือ *ตำแหน่งที่มันถูกวาด* เท่านั้น
        // (ถ้าใช้ .offset/.scaleEffect ตรง ๆ ยังพอได้ แต่ต้องรู้ขนาดกรอบซึ่งอยู่คนละชั้น)
        store.image(index, for: wid)
            .visualEffect { content, proxy in
                content
                    .scaleEffect(f.zoom)
                    .offset(x: f.dx * proxy.size.width, y: f.dy * proxy.size.height)
            }
    }
}

// MARK: - โทนสีเด่นของภาพ

extension UIImage {
    /// หาโทนสีเด่นของภาพ — คืน (hue, saturation) ให้ธีมทั้งการ์ดล้อตามพื้นหลัง
    ///
    /// ย่อเหลือ 32×32 แล้วโหวตเป็นถัง hue 24 ช่อง ถ่วงน้ำหนักด้วยความสด×ความสว่าง
    /// จึงได้ "สีที่รู้สึกเด่น" ไม่ใช่ค่าเฉลี่ยจืด ๆ ของทั้งภาพ · คืน nil เมื่อภาพแทบไร้สี
    func dominantTone() -> (hue: Double, saturation: Double)? {
        let side = 32
        guard let cg = cgImage,
              let ctx = CGContext(data: nil, width: side, height: side,
                                  bitsPerComponent: 8, bytesPerRow: side * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.interpolationQuality = .low
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let data = ctx.data else { return nil }
        let buf = data.bindMemory(to: UInt8.self, capacity: side * side * 4)

        var weight = [Double](repeating: 0, count: 24)
        var hueSum = [Double](repeating: 0, count: 24)
        var satSum = [Double](repeating: 0, count: 24)
        for i in 0..<(side * side) {
            let ui = UIColor(red: CGFloat(buf[i * 4]) / 255,
                             green: CGFloat(buf[i * 4 + 1]) / 255,
                             blue: CGFloat(buf[i * 4 + 2]) / 255, alpha: 1)
            var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0
            ui.getHue(&h, saturation: &s, brightness: &v, alpha: nil)
            let w = Double(s) * Double(v)
            guard w > 0.05 else { continue }
            let k = min(23, Int(h * 24))
            weight[k] += w
            hueSum[k] += Double(h) * w
            satSum[k] += Double(s) * w
        }
        guard let top = weight.indices.max(by: { weight[$0] < weight[$1] }),
              weight[top] > 0.5 else { return nil }
        return (hueSum[top] / weight[top], min(1, satSum[top] / weight[top]))
    }
}

// MARK: - ปุ่มเปลี่ยนรูปรายช่อง

/// ปุ่มไอคอนประจำ "ช่องรูปหนึ่งช่อง" — ลอยอยู่มุมขวาบนของรูปใบนั้น
///
/// หนึ่งปุ่มต่อหนึ่งรูป ไม่ใช่หนึ่งปุ่มต่อ widget เพราะเบนโตะ/แถบภาพมีรูปหลายใบ
/// ปุ่มเดียวจะตอบไม่ได้ว่ากำลังจะเปลี่ยนใบไหน · แตะที่ใบไหนก็ได้ใบนั้น
///
/// ต้องเป็น `PhotosPicker` ทรงปุ่มตรง ๆ เท่านั้น ห้ามใช้ `.photosPicker(isPresented:)`
/// เพราะการ์ดเป็นตัวเปิดชีตแต่งอยู่แล้ว สั่งเปิดชีตซ้อนจากตัวเดิมระบบจะเงียบไปเฉย ๆ
struct PhotoSlotButton: View {
    @Environment(PhotoStore.self) private var store
    let theme: CardTheme
    let widgetID: UUID
    /// หมายเลขช่องของตัวเอง
    let slot: Int
    /// ลำดับช่องทั้งหมดของ widget นี้ — ใช้ไล่เติมต่อเมื่อผู้ใช้เลือกมาหลายรูป
    let order: [Int]
    /// ช่องกว้างพอให้มีคำกำกับใต้ปุ่มไหม — ช่องเล็ก ๆ ในเบนโตะใส่ไม่ลง
    var labelled: Bool = true

    @State private var picks: [PhotosPickerItem] = []

    private var isCustom: Bool { store.has(slot: slot, for: widgetID) }
    /// เลือกได้มากสุดเท่าจำนวนช่องที่เหลือนับจากช่องนี้ไป — เกินกว่านั้นก็ไม่มีที่ให้ลง
    private var room: Int {
        guard let i = order.firstIndex(of: slot) else { return 1 }
        return max(1, order.count - i)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            // ช่องที่เปลี่ยนรูปไปแล้วค่อยมีปุ่มถอย — ช่องที่ยังเป็นรูประบบไม่มีอะไรให้คืน
            if isCustom {
                Button {
                    store.clear(slot: slot, for: widgetID)
                    Haptics.impact(.light)
                } label: {
                    orb("arrow.counterclockwise", "รูปเดิม", tinted: false)
                }
                .buttonStyle(.plain)

            }

            // จัดกรอบ — มีทุกช่องที่มีรูป ไม่ใช่เฉพาะรูปที่อัปโหลดเอง
            // รูปตั้งต้นก็ถูกครอปจากกึ่งกลางเหมือนกัน และคนแต่งการ์ดควรเล็งได้ตั้งแต่ก่อนเปลี่ยนรูป
            Button {
                store.framing = PhotoSlotRef(widget: widgetID, slot: slot)
                Haptics.impact(.light)
            } label: {
                orb("arrow.up.and.down.and.arrow.left.and.right", "จัดรูป", tinted: false)
            }
            .buttonStyle(.plain)

            PhotosPicker(selection: $picks, maxSelectionCount: room, matching: .images) {
                orb("photo.badge.plus.fill", "เปลี่ยนรูป", tinted: true)
            }
        }
        .onChange(of: picks) { _, new in
            guard !new.isEmpty else { return }
            Task {
                var images: [UIImage] = []
                for item in new {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) { images.append(ui) }
                }
                await MainActor.run {
                    store.set(images, from: slot, order: order, for: widgetID)
                    picks = []
                    Haptics.impact(.medium)
                }
            }
        }
    }

    /// วงกลมเล็กพอให้ลงช่องเบนโตะช่องจิ๋วได้ แต่ยังกดติดด้วยนิ้ว
    /// ปุ่มกลม + คำกำกับใต้ปุ่ม
    ///
    /// ไอคอนสามตัวนี้ไม่มีตัวไหนอ่านออกด้วยตัวเอง — ตอนเทสผู้ใช้อ่าน
    /// `arrow.up.and.down.and.arrow.left.and.right` ว่า "ย้ายชิ้นงาน" ทั้งที่มันแปลว่า
    /// "เลื่อนรูปในกรอบ" คนละเรื่องกันคนละชั้นกัน · หนึ่งคำใต้ปุ่มถูกกว่าการให้เดาผิดแล้ว
    /// ต้อง undo และถูกกว่ากล่องสอนวิธีใช้ที่ไม่มีใครอ่าน
    ///
    /// คำถูกซ่อนเมื่อช่องแคบ (`labelled == false`) — ป้ายที่ล้นออกนอกรูปอ่านยากกว่าไม่มีป้าย
    private func orb(_ symbol: String, _ label: String, tinted: Bool) -> some View {
        VStack(spacing: 2.5) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tinted ? .black.opacity(0.85) : .white.opacity(0.9))
                .frame(width: 25, height: 25)
                .background {
                    if tinted {
                        Circle().fill(LinearGradient(colors: [theme.accentSoft, theme.accent],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                    } else {
                        Circle().fill(.black.opacity(0.55))
                    }
                }
                .overlay(Circle().strokeBorder(.white.opacity(0.28), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.35), radius: 5, y: 2)

            if labelled {
                Text(label)
                    .font(.sh(8.5, .semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 4.5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(.black.opacity(0.6)))
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
            }
        }
    }
}

// MARK: - ปุ่มอัปโหลดพื้นหลัง

/// เลือกรูปพื้นหลังการ์ดหนึ่งรูป — ตั้งพื้นหลังแล้วส่งโทนสีเด่นกลับไปให้ธีมล้อตาม
struct BackgroundPickButton: View {
    @Environment(PhotoStore.self) private var store
    let theme: CardTheme
    /// แบบย่อ — ไอคอนล้วน สำหรับวางคู่แถบเลือกสีที่หัวชีต
    var compact = false
    /// เรียกหลังตั้งพื้นหลังเสร็จ พร้อมโทนสีเด่นของรูป (nil เมื่อภาพแทบไร้สี)
    let onPicked: ((hue: Double, saturation: Double)?) -> Void

    @State private var pick: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $pick, matching: .images) {
            HStack(spacing: 4) {
                Image(systemName: store.background == nil ? "photo.badge.plus.fill" : "photo.fill")
                    .font(.sh(compact ? 11 : 10, .semibold))
                if !compact {
                    // ป้ายบอกสิ่งที่จะเกิดขึ้น ไม่ใช่ชื่อของที่อยู่ปลายทาง — ปุ่มนี้ยืนอยู่ข้างรูปย่อ
                    // ของรูปที่ตั้งไว้แล้ว คำว่า "รูปของฉัน" ตรงนั้นอ่านเป็นชื่อของรูปใบที่เห็น
                    Text(store.background == nil ? "เลือกรูป" : "เปลี่ยนรูป")
                        .font(.sh(9.5, .semibold))
                }
            }
            .fixedSize()
            .foregroundStyle(.black.opacity(0.85))
            .padding(.horizontal, compact ? 10 : 9)
            .padding(.vertical, compact ? 7 : 6)
            .background(Capsule().fill(LinearGradient(colors: [theme.accentSoft, theme.accent],
                                                      startPoint: .leading, endPoint: .trailing)))
        }
        .onChange(of: pick) { _, item in
            guard let item else { return }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let ui = UIImage(data: data) else { return }
                let tone = ui.dominantTone()
                await MainActor.run {
                    store.setBackground(ui)
                    pick = nil
                    onPicked(tone)
                    Haptics.impact(.medium)
                }
            }
        }
    }
}

// MARK: - ปุ่มอัปโหลด

struct PhotoUploadButton: View {
    @Environment(PhotoStore.self) private var store
    let theme: CardTheme
    var compact = false

    @State private var picks: [PhotosPickerItem] = []
    @State private var loading = false

    var body: some View {
        PhotosPicker(selection: $picks, maxSelectionCount: 12, matching: .images) {
            HStack(spacing: 6) {
                Image(systemName: loading ? "arrow.triangle.2.circlepath" : "photo.badge.plus.fill")
                    .font(.system(size: compact ? 11 : 12, weight: .semibold))
                if !compact {
                    Text(store.hasUploads ? "รูป \(store.uploaded.count)" : "อัปโหลดรูป")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundStyle(.black.opacity(0.85))
            .padding(.horizontal, compact ? 10 : 13)
            .padding(.vertical, 7)
            .background(Capsule().fill(LinearGradient(colors: [theme.accentSoft, theme.accent],
                                                      startPoint: .leading, endPoint: .trailing)))
        }
        .onChange(of: picks) { _, new in
            guard !new.isEmpty else { return }
            loading = true
            Task {
                var images: [UIImage] = []
                for item in new {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        images.append(ui)
                    }
                }
                await MainActor.run {
                    store.add(images)
                    picks = []
                    loading = false
                    Haptics.impact(.medium)
                }
            }
        }
    }
}

// MARK: - แผ่นจัดกรอบรูป

/// แผ่นลากที่วางทับช่องรูปหนึ่งช่องขณะจัดกรอบ — ลากเพื่อเลื่อน · หุบสองนิ้วเพื่อซูม
///
/// # ทำไมต้องเข้าโหมดก่อน ไม่ใช่ลากได้เลย
///
/// ถ้าลากบนรูปแล้วรูปเลื่อนทันที ท่า "กดค้างแล้วลากย้าย widget" จะใช้ไม่ได้กับทุกตัวที่มีรูป
/// ซึ่งคือครึ่งตู้ · เข้าโหมดก่อนจึงเป็นทางเดียวที่ทั้งสองท่าอยู่ร่วมกันได้
/// (กติกาเดียวกับข้อความ: แตะแรกเลือก แตะสองถึงพิมพ์)
///
/// # ขอบเขตการเลื่อน
///
/// เลื่อนได้ไกลสุดเท่าที่ **ภาพยังคลุมกรอบอยู่** — ปล่อยให้เลื่อนจนเห็นพื้นว่างเมื่อไหร่
/// ผู้ใช้จะได้ช่องรูปที่มีขอบดำโดยไม่ตั้งใจ ซึ่งอ่านเป็นงานพัง ไม่ใช่งานที่ตั้งใจเว้น
struct PhotoFitSurface: View {
    @Environment(PhotoStore.self) private var store
    let theme: CardTheme
    let widgetID: UUID
    let slot: Int
    /// ขนาดของช่องบนจอ — ใช้แปลงระยะนิ้วเป็นสัดส่วนของภาพ
    let size: CGSize

    /// ค่าเริ่มต้นของท่าที่กำลังทำอยู่ — ท่าลากคืน translation สะสม จึงต้องบวกจากค่าตอนเริ่ม
    @State private var base: PhotoFit?

    private var fit: PhotoFit { store.fit(slot: slot, for: widgetID) }

    /// ขนาดที่ภาพถูกวาดจริงในกรอบ (ก่อนซูม) — คำนวณจากสัดส่วนของภาพกับกฎ `.fill`
    private var rendered: CGSize {
        guard let img = store.uiImage(slot: slot, for: widgetID),
              img.size.width > 0, img.size.height > 0,
              size.width > 0, size.height > 0 else { return size }
        let ia = img.size.width / img.size.height
        let sa = size.width / size.height
        return ia > sa ? CGSize(width: size.height * ia, height: size.height)
                       : CGSize(width: size.width, height: size.width / ia)
    }

    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.001))     // โปร่งแต่ยังกินทัช
            .contentShape(Rectangle())
            .gesture(drag)
            .simultaneousGesture(zoom)
            .overlay { frameHint }
            .overlay(alignment: .bottom) { bar }
    }

    // MARK: ท่า

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                let start = base ?? fit
                if base == nil { base = start }
                var f = start
                f.dx = start.dx + g.translation.width / max(1, rendered.width)
                f.dy = start.dy + g.translation.height / max(1, rendered.height)
                store.setFit(clamped(f), slot: slot, for: widgetID)
            }
            .onEnded { _ in
                base = nil
                Haptics.impact(.light)
            }
    }

    private var zoom: some Gesture {
        MagnifyGesture()
            .onChanged { g in
                let start = base ?? fit
                if base == nil { base = start }
                var f = start
                f.zoom = min(3, max(1, start.zoom * g.magnification))
                store.setFit(clamped(f), slot: slot, for: widgetID)
            }
            .onEnded { _ in base = nil }
    }

    /// หนีบให้ภาพคลุมกรอบเสมอ — คิดเป็นสัดส่วนของภาพ เพราะ `dx`/`dy` เก็บหน่วยนั้น
    private func clamped(_ f: PhotoFit) -> PhotoFit {
        var out = f
        let limX = max(0, (f.zoom - size.width / max(1, rendered.width)) / 2)
        let limY = max(0, (f.zoom - size.height / max(1, rendered.height)) / 2)
        out.dx = min(limX, max(-limX, f.dx))
        out.dy = min(limY, max(-limY, f.dy))
        return out
    }

    // MARK: หน้าตา

    /// เส้นตัดสามส่วน — บอกว่าตอนนี้ "กำลังเล็งกรอบ" ไม่ใช่กำลังลากตัว widget
    private var frameHint: some View {
        ZStack {
            ForEach(1..<3, id: \.self) { i in
                Rectangle().fill(.white.opacity(0.35)).frame(width: 0.6)
                    .offset(x: size.width * (CGFloat(i) / 3 - 0.5))
                Rectangle().fill(.white.opacity(0.35)).frame(height: 0.6)
                    .offset(y: size.height * (CGFloat(i) / 3 - 0.5))
            }
            Rectangle().strokeBorder(theme.accent, lineWidth: 1.5)
        }
        .allowsHitTesting(false)
    }

    private var bar: some View {
        HStack(spacing: 6) {
            if !fit.isIdentity {
                Button {
                    store.resetFit(slot: slot, for: widgetID)
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 25, height: 25)
                        .background(Circle().fill(.black.opacity(0.55)))
                }
                .buttonStyle(.plain)
            }
            Button {
                store.framing = nil
                Haptics.impact(.medium)
            } label: {
                Text("เสร็จ")
                    .font(.sh(11, .semibold))
                    .foregroundStyle(.black.opacity(0.85))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(LinearGradient(
                        colors: [theme.accentSoft, theme.accent],
                        startPoint: .leading, endPoint: .trailing)))
            }
            .buttonStyle(.plain)
        }
        .shadow(color: .black.opacity(0.35), radius: 5, y: 2)
        .padding(6)
    }
}
