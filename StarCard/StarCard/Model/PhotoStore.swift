import SwiftUI
import PhotosUI

/// คลังรูปของการ์ด
///
/// รูปที่ผู้ใช้อัปโหลดจะถูกใช้ก่อนเสมอ ถ้ายังไม่มีค่อยตกไปใช้รูปสังเคราะห์ที่แถมมา
/// ทำให้ทดลอง layout ได้โดยไม่ต้องรอ asset จริง แล้ววันที่ต่อ ImageKit ก็แทนที่แค่ชั้นนี้
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

    /// วางรูปลงช่อง `slot` แล้วไหลต่อไปช่องถัดไปตามลำดับที่ widget วางไว้
    /// เลือกมาใบเดียว = เปลี่ยนเฉพาะช่องนั้น · เลือกมาหลายใบ = ไล่เติมช่องที่เหลือให้ในทีเดียว
    func set(_ images: [UIImage], from slot: Int, order: [Int], for id: UUID) {
        guard let start = order.firstIndex(of: slot) else { return }
        for (k, image) in images.enumerated() where order.indices.contains(start + k) {
            perWidget[id, default: [:]][order[start + k]] = image
        }
    }
    func clear(_ id: UUID) { perWidget[id] = nil }
    func clear(slot: Int, for id: UUID) { perWidget[id]?[slot] = nil }
    func has(slot: Int, for id: UUID) -> Bool { perWidget[id]?[slot] != nil }
    func count(for id: UUID) -> Int { perWidget[id]?.count ?? 0 }

    var hasUploads: Bool { !uploaded.isEmpty }
    var count: Int { max(uploaded.count, PhotoLib.count) }

    func setBackground(_ image: UIImage) { background = image }
    func clearBackground() { background = nil }

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
        store.image(index, for: wid)
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

    @State private var picks: [PhotosPickerItem] = []

    private var isCustom: Bool { store.has(slot: slot, for: widgetID) }
    /// เลือกได้มากสุดเท่าจำนวนช่องที่เหลือนับจากช่องนี้ไป — เกินกว่านั้นก็ไม่มีที่ให้ลง
    private var room: Int {
        guard let i = order.firstIndex(of: slot) else { return 1 }
        return max(1, order.count - i)
    }

    var body: some View {
        HStack(spacing: 4) {
            // ช่องที่เปลี่ยนรูปไปแล้วค่อยมีปุ่มถอย — ช่องที่ยังเป็นรูประบบไม่มีอะไรให้คืน
            if isCustom {
                Button {
                    store.clear(slot: slot, for: widgetID)
                    Haptics.impact(.light)
                } label: {
                    orb("arrow.counterclockwise", tinted: false)
                }
                .buttonStyle(.plain)
            }

            PhotosPicker(selection: $picks, maxSelectionCount: room, matching: .images) {
                orb("photo.badge.plus.fill", tinted: true)
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
    private func orb(_ symbol: String, tinted: Bool) -> some View {
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
                    Text("รูปของฉัน").font(.sh(9.5, .semibold))
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
