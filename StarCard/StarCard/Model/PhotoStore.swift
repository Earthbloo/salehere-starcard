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
struct PhotoFit: Equatable, Codable {
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
    /// ชื่อไฟล์ของรูปในคลังรวม เรียงคู่กับ `uploaded` — รูปไม่มีตัวตนในตัว ต้องมีชื่อไว้ลบถูกใบ
    @ObservationIgnored private var uploadedIDs: [UUID] = []
    /// รูปพื้นหลังการ์ดที่ผู้ใช้อัปโหลดเอง — แยกจากคลังรูปเนื้อหา
    private(set) var background: UIImage?
    /// รูปโปรไฟล์จากหน้า "ข้อมูลของฉัน" — ใช้แทนรูปครีเอเตอร์ตั้งต้นในช่อง 1–3 ของทุก widget
    /// (ดู `PhotoLib.isProfileSlot`) และหัวหน้าคลัง · เก็บลงดิสก์เหมือนรูปพื้นหลัง
    private(set) var profile: UIImage? { didSet { profileRevision &+= 1 } }
    /// นับทุกครั้งที่รูปโปรไฟล์เปลี่ยน — ดู `TemplateThumbs.stamp`
    @ObservationIgnored private(set) var profileRevision = 0
    /// รูปหน้าสมุดบัญชีจากส่วน "การรับเงิน" — เอกสาร ไม่ใช่รูปการ์ด · เก็บลงดิสก์เหมือนรูปโปรไฟล์
    private(set) var bookBank: UIImage?
    /// รูปเฉพาะของ widget แต่ละตัว — ทับคลังรวมและรูปตั้งต้นของระบบ
    ///
    /// เก็บเป็น "ช่องที่เท่าไหร่ของ widget ไหน" ไม่ใช่กองรวมต่อ widget
    /// เพราะ widget อย่างเบนโตะ/แถบภาพมีรูปหลายใบ ครีเอเตอร์ต้องชี้ได้ว่าจะเปลี่ยนใบไหน
    private(set) var perWidget: [UUID: [Int: UIImage]] = [:]
    /// การจัดกรอบของแต่ละช่อง — ว่างไว้แปลว่ายังเป็นครอปกลางเฟรมตามเดิม
    private(set) var fits: [UUID: [Int: PhotoFit]] = [:]
    /// ช่องที่ถูก **ลบพื้นหลัง** แล้ว — เก็บผลไว้ต่างหาก ไม่ทับรูปต้นฉบับ
    ///
    /// เก็บแยกเพราะปุ่มนี้ต้องกดคืนได้ทันทีโดยไม่ต้องอัปโหลดใหม่ (ดู `PhotoLift`)
    /// และเพราะรูปต้นฉบับยังเป็นของที่ผู้ใช้เลือกมา — การกดปุ่มหนึ่งครั้งไม่ควรทำลายมันทิ้ง
    private(set) var lifted: [UUID: [Int: UIImage]] = [:]
    /// ช่องที่กำลังคำนวณหน้ากากอยู่ — ปุ่มหมุนรอระหว่างนี้ และกดซ้ำไม่ได้
    private(set) var lifting: Set<PhotoSlotRef> = []
    /// ช่องที่กำลังถูกจัดกรอบอยู่ · nil = ไม่มีใครถูกจัด
    ///
    /// อยู่ในสโตร์ ไม่ใช่ใน `CardScreen` เพราะทั้งปุ่มบนตัวรูปและชั้นการ์ดที่วางแผ่นลากทับ
    /// ต้องอ่านค่าเดียวกัน (เหตุผลเดียวกับ `Profile.editing`)
    var framing: PhotoSlotRef?
    /// ขนาดของช่องที่กำลังจัด (หน่วยการ์ด) — `PhotoFitSurface` รายงาน `PhotoFitCatcher` อ่าน
    @ObservationIgnored var framingSize: CGSize = .zero

    /// วางรูปลงช่อง `slot` แล้วไหลต่อไปช่องถัดไปตามลำดับที่ widget วางไว้
    /// เลือกมาใบเดียว = เปลี่ยนเฉพาะช่องนั้น · เลือกมาหลายใบ = ไล่เติมช่องที่เหลือให้ในทีเดียว
    func set(_ images: [UIImage], from slot: Int, order: [Int], for id: UUID) {
        guard let start = order.firstIndex(of: slot) else { return }
        for (k, image) in images.enumerated() where order.indices.contains(start + k) {
            let s = order[start + k]
            perWidget[id, default: [:]][s] = image
            write(image, to: Self.slotURL(id, s))
            // รูปใหม่ = กรอบใหม่ · การเก็บค่าเลื่อนของรูปเก่าไว้ทำให้รูปที่เพิ่งวางเข้าไปเบี้ยวทันที
            fits[id]?[s] = nil
            // และหน้ากากของรูปเก่าก็ใช้กับรูปใหม่ไม่ได้ — ต้องกดลบพื้นหลังใหม่ถ้าต้องการ
            if lifted[id]?[s] != nil {
                lifted[id]?[s] = nil
                write(nil, to: Self.liftURL(id, s))
            }
        }
        saveManifest()
    }
    func clear(_ id: UUID) {
        for s in (perWidget[id] ?? [:]).keys { write(nil, to: Self.slotURL(id, s)) }
        for s in (lifted[id] ?? [:]).keys { write(nil, to: Self.liftURL(id, s)) }
        perWidget[id] = nil
        fits[id] = nil
        lifted[id] = nil
        saveManifest()
    }
    func clear(slot: Int, for id: UUID) {
        perWidget[id]?[slot] = nil
        // คืนรูประบบ = คืนกรอบตั้งต้นด้วย ไม่งั้นรูปใหม่โผล่มาพร้อมกรอบของรูปเก่า
        fits[id]?[slot] = nil
        // พื้นหลังที่ลบไว้เป็นของ *รูปใบนั้น* — คืนรูปเดิมแล้วหน้ากากของใบเก่าใช้ต่อไม่ได้
        lifted[id]?[slot] = nil
        write(nil, to: Self.slotURL(id, slot))
        write(nil, to: Self.liftURL(id, slot))
        saveManifest()
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
        // ถูกเรียกทุกเฟรมระหว่างลาก — รอให้นิ้วหยุดก่อนค่อยเขียน
        saveManifest(debounced: true)
    }
    func resetFit(slot: Int, for id: UUID) {
        fits[id]?[slot] = nil
        saveManifest()
    }
    /// รูปจริงในช่อง — ตัวจัดกรอบต้องรู้สัดส่วนของภาพถึงจะคำนวณขอบเขตการเลื่อนได้
    ///
    /// ไล่ลำดับเดียวกับ `image(_:for:)` เป๊ะ ๆ รวมถึงรูประบบที่แคชไว้แล้ว —
    /// ถ้าตัวนี้ตอบไม่ตรงกับที่วาดจริง ขอบเขตการเลื่อนจะคำนวณจากสัดส่วนของภาพอื่น
    @MainActor
    func uiImage(slot i: Int, for id: UUID) -> UIImage? {
        if let cut = lifted[id]?[i] { return cut }
        if let own = perWidget[id]?[i] { return own }
        if let own = library(i) { return own }
        return ImageCache.shared.cached(PhotoLib.url(i))
    }
    func count(for id: UUID) -> Int { perWidget[id]?.count ?? 0 }

    // MARK: ลบพื้นหลัง

    func hasLift(slot: Int, for id: UUID) -> Bool { lifted[id]?[slot] != nil }
    func isLifting(slot: Int, for id: UUID) -> Bool {
        lifting.contains(PhotoSlotRef(widget: id, slot: slot))
    }

    /// รูปต้นฉบับของช่อง — **ไม่นับใบที่ลบพื้นหลังไปแล้ว** (ตัวที่ส่งเข้า Vision ต้องมีพื้นหลัง)
    @MainActor
    private func sourceImage(slot i: Int, for id: UUID) -> UIImage? {
        if let own = perWidget[id]?[i] { return own }
        if let own = library(i) { return own }
        return ImageCache.shared.cached(PhotoLib.url(i))
    }

    /// ยกตัวแบบออกจากพื้นหลังของช่องนี้ — คืน `false` เมื่อในรูปไม่มีวัตถุที่แยกได้
    ///
    /// รูปต้นฉบับไม่ถูกแตะเลย กดคืนพื้นหลังได้ตลอดเวลาด้วย `dropLift`
    @MainActor
    @discardableResult
    func liftBackground(slot i: Int, for id: UUID) async -> Bool {
        let ref = PhotoSlotRef(widget: id, slot: i)
        guard !lifting.contains(ref), let source = sourceImage(slot: i, for: id) else { return false }
        lifting.insert(ref)
        let out = await PhotoLift.lift(source)
        lifting.remove(ref)
        guard let out else { return false }
        lifted[id, default: [:]][i] = out
        write(out, to: Self.liftURL(id, i), png: true)
        saveManifest()
        return true
    }

    /// คืนพื้นหลังให้ช่องนี้
    func dropLift(slot i: Int, for id: UUID) {
        lifted[id]?[i] = nil
        write(nil, to: Self.liftURL(id, i))
        saveManifest()
    }

    var hasUploads: Bool { !uploaded.isEmpty }
    var count: Int { max(uploaded.count, PhotoLib.count) }

    // MARK: รูปพื้นหลัง

    /// รูปพื้นหลังอยู่บนดิสก์ ไม่ใช่แค่ในหน่วยความจำ
    ///
    /// มันถูกอ้างจาก `CardTheme.backdrop == .photo` ที่เซฟลง `UserDefaults` ไปแล้ว
    /// ถ้าไม่เก็บตัวรูปไว้ด้วย การเปิดแอปครั้งถัดไปจะได้การ์ดที่บอกว่า "พื้นหลังเป็นรูป"
    /// แต่ไม่มีรูป แล้วตกไปใช้รูประบบเบลอ ๆ แทนโดยไม่มีใครสั่ง
    private static var backgroundURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("starcard-backdrop.jpg")
    }

    private static var profileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("starcard-profile.jpg")
    }

    private static var bookBankURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("starcard-bookbank.jpg")
    }

    // MARK: รูปในช่อง widget และคลังรวม
    //
    // รูปที่ผู้ใช้วางเองต้องอยู่รอดข้ามการเปิดแอป — ไม่งั้นการ์ดที่ `CardStore` จำโครงไว้
    // จะกลับมาพร้อมรูปตัวอย่างของระบบแทนรูปของเขา · ของจริงย้ายไป API พร้อมตัวการ์ดทีหลัง
    // (ดู `WidgetContent.swift`) แต่ถึงวันนั้นชั้นนี้เปลี่ยนแค่ที่เก็บ ไม่ต้องเปลี่ยนคนเรียก
    //
    // ผูกกับ widget ด้วย `WidgetInstance.id` ซึ่ง `CardStore` เซฟไว้คงที่ข้ามการเปิดแอปแล้ว

    private struct Manifest: Codable {
        var slots: [String: [Int]] = [:]
        var lifts: [String: [Int]] = [:]
        var fits: [String: [Int: PhotoFit]] = [:]
        var library: [UUID] = []
    }

    private static var photoDir: URL? {
        guard let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return nil }
        let d = base.appendingPathComponent("starcard-photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    private static func slotURL(_ id: UUID, _ s: Int) -> URL? {
        photoDir?.appendingPathComponent("slot-\(id.uuidString)-\(s).jpg")
    }
    /// PNG ไม่ใช่ JPEG — รูปที่ลบพื้นหลังแล้วต้องเก็บความโปร่งใสไว้
    private static func liftURL(_ id: UUID, _ s: Int) -> URL? {
        photoDir?.appendingPathComponent("lift-\(id.uuidString)-\(s).png")
    }
    private static func libraryURL(_ id: UUID) -> URL? {
        photoDir?.appendingPathComponent("lib-\(id.uuidString).jpg")
    }
    private static var manifestURL: URL? { photoDir?.appendingPathComponent("manifest.json") }

    @ObservationIgnored private var pendingSave: DispatchWorkItem?

    private func saveManifest(debounced: Bool = false) {
        pendingSave?.cancel()
        let job = DispatchWorkItem { [weak self] in self?.writeManifest() }
        pendingSave = job
        if debounced {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: job)
        } else {
            job.perform()
        }
    }

    private func writeManifest() {
        guard let url = Self.manifestURL else { return }
        var m = Manifest()
        for (id, slots) in perWidget where !slots.isEmpty { m.slots[id.uuidString] = Array(slots.keys) }
        for (id, slots) in lifted where !slots.isEmpty { m.lifts[id.uuidString] = Array(slots.keys) }
        for (id, slots) in fits where !slots.isEmpty { m.fits[id.uuidString] = slots }
        m.library = uploadedIDs
        guard let data = try? JSONEncoder().encode(m) else { return }
        // คิวเดียวกับไฟล์รูป — manifest ต้องไม่แซงหน้ารูปที่มันอ้างถึง
        Self.io.async { try? data.write(to: url, options: .atomic) }
    }

    private func loadWidgetPhotos() {
        guard let url = Self.manifestURL,
              let data = try? Data(contentsOf: url),
              let m = try? JSONDecoder().decode(Manifest.self, from: data) else { return }
        for (key, slots) in m.slots {
            guard let id = UUID(uuidString: key) else { continue }
            for s in slots {
                if let path = Self.slotURL(id, s)?.path, let img = UIImage(contentsOfFile: path) {
                    perWidget[id, default: [:]][s] = img
                }
            }
        }
        for (key, slots) in m.lifts {
            guard let id = UUID(uuidString: key) else { continue }
            for s in slots {
                if let path = Self.liftURL(id, s)?.path, let img = UIImage(contentsOfFile: path) {
                    lifted[id, default: [:]][s] = img
                }
            }
        }
        for (key, slots) in m.fits {
            guard let id = UUID(uuidString: key) else { continue }
            fits[id] = slots
        }
        for id in m.library {
            if let path = Self.libraryURL(id)?.path, let img = UIImage(contentsOfFile: path) {
                uploaded.append(img)
                uploadedIDs.append(id)
            }
        }
    }

    init() {
        // อ่านตอนเกิดเลย ไม่รอ `.task` — `CardBackdrop` วาดในเฟรมแรกที่การ์ดขึ้น
        // ถ้าโหลดทีหลังผู้ใช้จะเห็นพื้นกระพริบจากรูปสำรองไปเป็นรูปตัวเองทุกครั้งที่เปิดแอป
        if let url = Self.backgroundURL { background = UIImage(contentsOfFile: url.path) }
        if let url = Self.profileURL { profile = UIImage(contentsOfFile: url.path) }
        if let url = Self.bookBankURL { bookBank = UIImage(contentsOfFile: url.path) }
        loadWidgetPhotos()
    }

    // MARK: รูปโปรไฟล์

    func setProfile(_ image: UIImage) {
        profile = image
        write(image, to: Self.profileURL)
    }

    func clearProfile() {
        profile = nil
        write(nil, to: Self.profileURL)
    }

    // MARK: หน้าสมุดบัญชี

    func setBookBank(_ image: UIImage) {
        bookBank = image
        write(image, to: Self.bookBankURL)
    }

    func clearBookBank() {
        bookBank = nil
        write(nil, to: Self.bookBankURL)
    }

    func setBackground(_ image: UIImage) {
        background = image
        baked.removeAll()
        lumas.removeAll()
        veils.removeAll()
        write(image, to: Self.backgroundURL)
    }

    func clearBackground() {
        background = nil
        baked.removeAll()
        lumas.removeAll()
        veils.removeAll()
        write(nil, to: Self.backgroundURL)
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

    // MARK: ม่านกันตัวหนังสือจม (ดู `PhotoLuma`)

    /// แผนที่ความสว่างของรูปพื้นหลังต่อเอฟเฟกต์ — วัดครั้งเดียวต่อรูปต่อเอฟเฟกต์
    /// (เบลอกับจุดปะเปลี่ยนความสว่างของรูปจริง · ขาวดำแทบไม่เปลี่ยน แต่แยกกฎไว้ก็ไม่ได้ถูกลง)
    @ObservationIgnored private var lumas: [BackdropEffect: PhotoLuma] = [:]
    /// ม่านที่วาดแล้ว — ห้ามให้ระบบ observation เห็นด้วยเหตุผลเดียวกับ `baked`
    @ObservationIgnored private var veils: [VeilKey: UIImage] = [:]

    private struct VeilKey: Hashable {
        let effect: BackdropEffect
        let spec: PhotoVeil
    }

    func luma(_ effect: BackdropEffect) -> PhotoLuma? {
        if let hit = lumas[effect] { return hit }
        guard let image = background(effect),
              let made = PhotoLuma.measure(image, blurred: effect == .blur) else { return nil }
        lumas[effect] = made
        return made
    }

    /// ม่านของรูปพื้นหลังตามธีม — nil เมื่อยังไม่มีรูปของผู้ใช้
    ///
    /// ลากแถบความจางทีไรได้กุญแจใหม่ทุกเฟรม — ม่านหนึ่งผืนคือกริดสองร้อยกว่าช่องกับภาพเล็ก ๆ หนึ่งใบ
    /// ทำใหม่ได้ทุกเฟรม ที่จำไว้มีไว้ให้การ์ดหลายใบที่ใช้ธีมเดียวกัน (คลัง · หน้าแชร์) ไม่ต้องทำซ้ำ
    func veil(_ effect: BackdropEffect, _ spec: PhotoVeil) -> UIImage? {
        let key = VeilKey(effect: effect, spec: spec)
        if let hit = veils[key] { return hit }
        guard let luma = luma(effect), let made = luma.veilImage(luma.veil(spec), color: spec.color)
        else { return nil }
        if veils.count > 12 { veils.removeAll() }
        veils[key] = made
        return made
    }

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

    /// คิวเขียนไฟล์ตัวเดียวแบบเรียงลำดับ — วางรูปแล้วกดคืนทันที การลบต้องไม่วิ่งแซงการเขียน
    private static let io = DispatchQueue(label: "starcard.photos.io", qos: .utility)

    /// บีบอัดและเขียนนอกเธรดหลัก — รูปจากกล้องใบหนึ่งใช้เวลานานพอให้จังหวะที่แตะเลือกรูปสะดุด
    private func write(_ image: UIImage?, to url: URL?, png: Bool = false) {
        guard let url else { return }
        Self.io.async {
            guard let image else {
                try? FileManager.default.removeItem(at: url)
                return
            }
            guard let data = png ? image.pngData() : image.diskData(quality: 0.9) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }

    func add(_ images: [UIImage]) {
        for image in images {
            let id = UUID()
            uploaded.append(image)
            uploadedIDs.append(id)
            write(image, to: Self.libraryURL(id))
        }
        saveManifest()
    }

    func remove(at index: Int) {
        guard uploaded.indices.contains(index) else { return }
        uploaded.remove(at: index)
        write(nil, to: Self.libraryURL(uploadedIDs.remove(at: index)))
        saveManifest()
    }

    func clear() {
        uploadedIDs.forEach { write(nil, to: Self.libraryURL($0)) }
        uploaded.removeAll()
        uploadedIDs.removeAll()
        saveManifest()
    }

    /// รูปลำดับที่ i — วนซ้ำถ้าขอเกินจำนวนที่มี
    ///
    /// ลำดับความสำคัญ: รูปที่วางไว้ในช่องนี้ของ widget ตัวนั้น → คลังรวมของการ์ด → รูปตั้งต้นจากระบบ
    /// ตกท้ายที่รูประบบเสมอ การ์ดจึงไม่มีวันว่างเปล่าตั้งแต่เปิดแอป
    /// รูป **ของผู้ใช้** ในช่องนี้ — ไม่รวมรูปตัวอย่างของระบบ
    ///
    /// ต่างจาก `uiImage(slot:for:)` ตรงท้ายสุด: ตัวนั้นตกไปที่รูประบบเสมอเพราะตัวจัดกรอบ
    /// ต้องรู้สัดส่วนของสิ่งที่วาดอยู่จริง ส่วนตัวนี้ตอบคำถามคนละข้อ — "เจ้าของการ์ดใส่รูปมาหรือยัง"
    /// ซึ่งเป็นคำถามที่ตระกูลคัตเอาต์ใช้แยกระหว่าง *รูปตัวอย่างที่เราแถมให้ดูท่า* กับ *รูปจริงของเขา*
    func userImage(slot i: Int, for id: UUID?) -> UIImage? {
        if let id, let own = perWidget[id]?[i] { return own }
        return library(i)
    }

    /// รูปของเจ้าของการ์ดสำหรับช่องนี้ (ยังไม่นับรูปที่วางเฉพาะชิ้น)
    ///
    /// ช่องรูปครีเอเตอร์ (1–3): รูปโปรไฟล์ครีเอเตอร์ → รูปโปรไฟล์วงกลม
    /// ช่องอื่น / ช่องครีเอเตอร์ที่ยังไม่มีรูป: คลังที่อัปโหลดตอนแต่ง → รูปผลงานจากหน้าแก้ไขโปรไฟล์
    /// nil = ยังไม่มีรูปของเจ้าของเลย ผู้เรียกตกไปใช้รูปตัวอย่าง
    func library(_ i: Int) -> UIImage? {
        let folio = Portfolio.shared
        if PhotoLib.isProfileSlot(i) {
            if let c = folio.creatorImage(slot: i) { return c }
            if let profile { return profile }
        }
        if !uploaded.isEmpty { return uploaded[i % uploaded.count] }
        return folio.workImage(slot: i)
    }

    /// รูปวงกลมข้างชื่อ — รูปโปรไฟล์ก่อน ไม่มีค่อยใช้รูปช่องครีเอเตอร์แรก
    @ViewBuilder
    func avatar() -> some View {
        if let profile {
            Image(uiImage: profile).resizable().unredacted()
        } else {
            image(1)
        }
    }

    /// รูปไม่ถูก redact — ตู้ widget วาดใบที่ "ยังไม่มีข้อมูล" ด้วย `.redacted(.placeholder)`
    /// ให้ตัวหนังสือกลายเป็นแท่ง แต่รูปต้องยังเป็นรูป ไม่งั้นพรีวิวกลายเป็นก้อนเทาทั้งใบ
    @ViewBuilder
    func image(_ i: Int, for id: UUID? = nil) -> some View {
        if let id, let cut = lifted[id]?[i] {
            // รูปที่ลบพื้นหลังแล้วมาก่อนเสมอ — ขนาดเท่าต้นฉบับ ช่องจึงครอปเหมือนเดิมทุกประการ
            Image(uiImage: cut).resizable().unredacted()
        } else if let id, let own = perWidget[id]?[i] {
            Image(uiImage: own).resizable().unredacted()
        } else if let own = library(i) {
            Image(uiImage: own).resizable().unredacted()
        } else {
            RemotePhoto(url: PhotoLib.url(i)).unredacted()
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
    /// รูปที่มีพื้นโปร่งเก็บเป็น PNG · ที่เหลือเป็น JPEG
    ///
    /// JPEG ไม่มีช่องโปร่ง — PNG ตัดพื้นที่ผู้ใช้เตรียมมาเอง (ตระกูลคัตเอาต์) เซฟเป็น JPEG แล้ว
    /// เปิดแอปรอบหน้าจะได้พื้นทึบกลับมาแทน · ชื่อไฟล์ยังลงท้าย .jpg ได้ `UIImage(contentsOfFile:)`
    /// ดูชนิดจากเนื้อไฟล์ ไม่ได้ดูจากนามสกุล
    func diskData(quality: CGFloat) -> Data? {
        switch cgImage?.alphaInfo {
        case .none?, .noneSkipFirst?, .noneSkipLast?: return jpegData(compressionQuality: quality)
        default: return pngData() ?? jpegData(compressionQuality: quality)
        }
    }
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
/// ปุ่มเปลี่ยนรูปเป็น `Button` ธรรมดา + `.photosPicker(isPresented:)` — **ไม่ใช่** `PhotosPicker` ทรงปุ่ม
/// ตัวนั้นวางบนการ์ดที่มีตัวรับนิ้วของ UIKit อยู่ข้างใต้ (`PressDragCatcher`) แล้วกดไม่ติดบ่อยมาก
/// ขณะที่ `Button` ข้าง ๆ ที่ตำแหน่งเดียวกันกดติดทุกครั้ง (ถาดแต่งเป็น `EditorDock` ไม่ใช่ชีตแล้ว
/// จึงไม่มีปัญหาเปิดชีตซ้อน)
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
    /// สเกลของการ์ดบนจอ — ใช้ขยาย **พื้นที่กด** ให้ได้ขนาดนิ้วบนจอเสมอ
    ///
    /// ปุ่มอยู่ในการ์ด การ์ดย่อลงราว 0.6 ทุกครั้งที่เลือกชิ้น (ดู `CardScreen.editScale`)
    /// วงกลม 25pt จึงเหลือราว 15pt บนจอ — เล็กกว่านิ้วมาก กดแล้วพลาดไปโดนการ์ดแทน
    ///
    /// ขยายแค่พื้นที่กด ไม่ขยายตัวปุ่ม — ลองหารสเกลกลับทั้งปุ่มแล้ว ปุ่มสามชุดในแถบภาพ
    /// บังรูปที่มันควรจะให้ดูจนมิด
    var scale: CGFloat = 1

    @State private var picks: [PhotosPickerItem] = []
    @State private var picking = false

    private var isCustom: Bool { store.has(slot: slot, for: widgetID) }
    /// เลือกได้มากสุดเท่าจำนวนช่องที่เหลือนับจากช่องนี้ไป — เกินกว่านั้นก็ไม่มีที่ให้ลง
    private var room: Int {
        guard let i = order.firstIndex(of: slot) else { return 1 }
        return max(1, order.count - i)
    }

    var body: some View {
        // **ช่องแคบเรียงสองแถว** — ปุ่มทั้งแถวในแถวเดียวกว้าง ซึ่งกว้างกว่าช่องเล็ก
        // ในเบนโตะทั้งช่อง แถวที่ล้นจะไปทับปุ่มของช่องข้าง ๆ แล้วนิ้วกดโดนใบที่ไม่ได้ตั้งใจ
        Group {
            if labelled {
                HStack(alignment: .top, spacing: 4) { buttons }
            } else {
                VStack(alignment: .trailing, spacing: 4) {
                    undoButton
                    HStack(alignment: .top, spacing: 4) { framingButton; pickerButton }
                }
            }
        }
        .photosPicker(isPresented: $picking, selection: $picks,
                      maxSelectionCount: room, matching: .images)
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

    @ViewBuilder
    private var buttons: some View {
        undoButton
        framingButton
        pickerButton
    }

    /// ช่องที่เปลี่ยนรูปไปแล้วค่อยมีปุ่มถอย — ช่องที่ยังเป็นรูประบบไม่มีอะไรให้คืน
    @ViewBuilder
    private var undoButton: some View {
        Group {
            if isCustom {
                Button {
                    store.clear(slot: slot, for: widgetID)
                    Haptics.impact(.light)
                } label: {
                    orb("arrow.counterclockwise", "รูปเดิม", tinted: false, reach: [.top, .leading])
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// จัดกรอบ — มีทุกช่องที่มีรูป ไม่ใช่เฉพาะรูปที่อัปโหลดเอง
    /// รูปตั้งต้นก็ถูกครอปจากกึ่งกลางเหมือนกัน และคนแต่งการ์ดควรเล็งได้ตั้งแต่ก่อนเปลี่ยนรูป
    private var framingButton: some View {
        Button {
            store.framing = PhotoSlotRef(widget: widgetID, slot: slot)
            Haptics.impact(.light)
        } label: {
            orb("arrow.up.and.down.and.arrow.left.and.right", "จัดรูป", tinted: false,
                // มีปุ่มถอยอยู่ซ้าย (แถวมีป้าย) = ยื่นไปทางซ้ายไม่ได้
                reach: isCustom && labelled ? [.bottom] : [.leading, .bottom])
        }
        .buttonStyle(.plain)
    }

    private var pickerButton: some View {
        Button {
            picking = true
        } label: {
            orb("photo.badge.plus.fill", "เปลี่ยนรูป", tinted: true,
                // มีปุ่มถอยอยู่บน (ช่องแคบเรียงสองแถว) = ยื่นขึ้นไม่ได้
                reach: isCustom && !labelled ? [.trailing, .bottom] : [.top, .trailing, .bottom])
        }
        .buttonStyle(.plain)
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
    /// ขอบกดรอบวงกลม 25pt ในหน่วยการ์ด — ให้รวมกันได้ 44pt บนจอ
    private var hitPad: CGFloat { max(4, (44 / max(scale, 0.01) - 25) / 2) }

    ///
    /// `reach` = ด้านที่พื้นที่กดยื่นออกไปได้ — ห้ามยื่นเข้าหาปุ่มข้าง ๆ ที่ห่างกันแค่ 4pt
    /// ไม่งั้นพื้นที่กดทับกัน แตะ "เปลี่ยนรูป" แล้วได้ "จัดรูป" · ปุ่มหลักจึงได้ด้านที่โล่งมากที่สุด
    private func orb(_ symbol: String, _ label: String, tinted: Bool, reach: Edge.Set) -> some View {
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
                // ตาเห็นเท่าเดิม แต่นิ้วโดนเท่าปุ่มมาตรฐาน 44pt **บนจอ**
                .contentShape(HitArea(pad: hitPad, reach: reach))

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

/// สี่เหลี่ยมที่ยื่นออกจากกรอบเฉพาะด้านที่สั่ง — พื้นที่กดของปุ่มกลมบนรูป
private struct HitArea: Shape {
    let pad: CGFloat
    let reach: Edge.Set
    /// ด้านที่ไม่ยื่นยังได้นิดหนึ่ง — ครึ่งหนึ่งของช่องไฟ 4pt ระหว่างปุ่ม
    private let gap: CGFloat = 2

    func path(in rect: CGRect) -> Path {
        func d(_ e: Edge.Set) -> CGFloat { reach.contains(e) ? pad : gap }
        return Path(CGRect(x: rect.minX - d(.leading), y: rect.minY - d(.top),
                           width: rect.width + d(.leading) + d(.trailing),
                           height: rect.height + d(.top) + d(.bottom)))
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
/// กรอบของช่องที่กำลังจัดอยู่ — **แค่หน้าตา** (เส้นสามส่วน + ขอบสีธีม) ไม่รับทัช
///
/// ท่าลาก/ถ่างอยู่ที่ `PhotoFitCatcher` ซึ่งคลุมทั้งจอ — เคยอยู่ที่แผ่นนี้แล้วนิ้วต้องอยู่ *ในช่อง* เท่านั้น
/// ช่องคนของโปสเตอร์บนการ์ดที่ถูกย่อเหลือนิ้วกว่า ๆ ถ่างสองนิ้วลงไปไม่ได้ด้วยซ้ำ
/// แผ่นนี้จึงเหลือหน้าที่เดียว: รายงานขนาดช่องให้ตัวคลุมจอเอาไปแปลงระยะนิ้วเป็นสัดส่วนของภาพ
struct PhotoFitSurface: View {
    @Environment(PhotoStore.self) private var store
    let theme: CardTheme
    let widgetID: UUID
    let slot: Int
    /// ขนาดของช่องในหน่วยการ์ด
    let size: CGSize

    var body: some View {
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
        .onChange(of: size, initial: true) { _, s in store.framingSize = s }
    }
}

/// ตัวรับนิ้วของโหมดจัดรูป — **คลุมทั้งจอ** ลากหรือถ่างตรงไหนก็ได้
///
/// ระยะนิ้ววัดบนจอ แต่ช่องรูปอยู่ในการ์ดที่ถูกย่อ (`scale`) — หารกลับก่อนแปลงเป็นสัดส่วนของภาพ
/// ไม่งั้นรูปวิ่งเร็วกว่านิ้วเท่ากับที่การ์ดถูกย่อ · แถบ "เสร็จ" อยู่ในชั้นนี้ด้วย เพราะชั้นนี้ทับทุกอย่าง
struct PhotoFitCatcher: View {
    @Environment(PhotoStore.self) private var store
    let theme: CardTheme
    /// สเกลการ์ด → จอ
    let scale: CGFloat

    /// ซูมได้มากแค่ไหน — ใหญ่เท่าที่ผู้ใช้อยากได้ ไม่ใช่ 3× ที่คิดแทนเขา
    static let maxZoom: CGFloat = 8

    @State private var base: PhotoFit?

    private var ref: PhotoSlotRef? { store.framing }
    private var size: CGSize { store.framingSize }
    private var fit: PhotoFit {
        guard let ref else { return .identity }
        return store.fit(slot: ref.slot, for: ref.widget)
    }

    /// ช่องนี้เป็น **คนที่ตัดพื้นแล้ว** ไหม — ตัวคนไม่มีกรอบให้ต้องคลุม
    ///
    /// รูปในกรอบต้องคลุมกรอบเสมอ (ซูมไม่ต่ำกว่า 1 · เลื่อนได้แค่ส่วนที่ล้น) แต่ตัวคัตเอาต์
    /// ถูกวาด *พอดีกรอบ* อยู่แล้ว ส่วนล้นเป็นศูนย์ — กฎเดียวกันจึงล็อกมันตายอยู่กับที่ทั้งตัว
    @MainActor private var isCutout: Bool {
        guard let ref else { return false }
        guard let img = store.userImage(slot: ref.slot, for: ref.widget) else { return true }
        if CutoutCache.shared.result(for: img).isCutout { return true }
        return SubjectLift.shared.result(for: img)?.isCutout == true
    }

    /// ขนาดที่ภาพถูกวาดจริงในกรอบ (ก่อนซูม) — คำนวณจากสัดส่วนของภาพกับกฎ `.fill`
    @MainActor private var rendered: CGSize {
        guard let ref, !isCutout,
              let img = store.uiImage(slot: ref.slot, for: ref.widget),
              img.size.width > 0, img.size.height > 0,
              size.width > 0, size.height > 0 else { return size }
        let ia = img.size.width / img.size.height
        let sa = size.width / size.height
        return ia > sa ? CGSize(width: size.height * ia, height: size.height)
                       : CGSize(width: size.width, height: size.width / ia)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.001))     // โปร่งแต่ยังกินทัช
                .contentShape(Rectangle())
                .gesture(drag)
                .simultaneousGesture(zoom)
                .ignoresSafeArea()
            bar
        }
    }

    // MARK: ท่า

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                guard let ref else { return }
                let start = base ?? fit
                if base == nil { base = start }
                let s = max(scale, 0.01)
                var f = start
                f.dx = start.dx + g.translation.width / s / max(1, rendered.width)
                f.dy = start.dy + g.translation.height / s / max(1, rendered.height)
                store.setFit(clamped(f), slot: ref.slot, for: ref.widget)
            }
            .onEnded { _ in
                base = nil
                Haptics.impact(.light)
            }
    }

    private var zoom: some Gesture {
        MagnifyGesture()
            .onChanged { g in
                guard let ref else { return }
                let start = base ?? fit
                if base == nil { base = start }
                var f = start
                f.zoom = min(Self.maxZoom, max(isCutout ? 0.4 : 1, start.zoom * g.magnification))
                store.setFit(clamped(f), slot: ref.slot, for: ref.widget)
            }
            .onEnded { _ in base = nil }
    }

    /// หนีบค่า — คิดเป็นสัดส่วนของภาพ เพราะ `dx`/`dy` เก็บหน่วยนั้น
    @MainActor private func clamped(_ f: PhotoFit) -> PhotoFit {
        var out = f
        // ตัวคัตเอาต์: เลื่อนได้อิสระครึ่งกรอบทุกทิศ (ยิ่งซูยิ่งไปได้ไกล) — ไกลกว่านั้นคนหลุดออกนอกใบ
        if isCutout {
            let lim = 0.5 * max(1, f.zoom)
            out.dx = min(lim, max(-lim, f.dx))
            out.dy = min(lim, max(-lim, f.dy))
            return out
        }
        // รูปในกรอบ: ภาพต้องคลุมกรอบเสมอ
        let limX = max(0, (f.zoom - size.width / max(1, rendered.width)) / 2)
        let limY = max(0, (f.zoom - size.height / max(1, rendered.height)) / 2)
        out.dx = min(limX, max(-limX, f.dx))
        out.dy = min(limY, max(-limY, f.dy))
        return out
    }

    // MARK: หน้าตา

    private var bar: some View {
        HStack(spacing: 8) {
            Text("ลากหรือถ่างนิ้วตรงไหนก็ได้")
                .font(.sh(11.5, .medium))
                .foregroundStyle(.white.opacity(0.75))
            Spacer(minLength: 6)
            if !fit.isIdentity, let ref {
                Button {
                    store.resetFit(slot: ref.slot, for: ref.widget)
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            Button {
                store.framing = nil
                Haptics.impact(.medium)
            } label: {
                Text("เสร็จ")
                    .font(.sh(14, .semibold))
                    .foregroundStyle(.black.opacity(0.85))
                    .padding(.horizontal, 20).frame(height: 38)
                    .background(Capsule().fill(LinearGradient(
                        colors: [theme.accentSoft, theme.accent],
                        startPoint: .leading, endPoint: .trailing)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Capsule().fill(Color(white: 0.09)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.1), lineWidth: 0.6))
        .padding(.horizontal, 16).padding(.bottom, 8)
    }
}
