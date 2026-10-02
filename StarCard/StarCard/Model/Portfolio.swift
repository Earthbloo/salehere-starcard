import SwiftUI
import AVFoundation
import CoreTransferable
import UniformTypeIdentifiers

// MARK: - ผลงานของเจ้าของการ์ด
//
// ของชุดเดียวกับหน้า "แก้ไขโปรไฟล์" ของแอป Sale Here เดิม:
// รูปโปรไฟล์ครีเอเตอร์ 3 ช่อง · รูปผลงาน · วิดีโอผลงาน
//
// # ทำไมเก็บลงดิสก์ ไม่ใช่ในหน่วยความจำแบบ `PhotoStore.uploaded`
//
// คลังรูปของการ์ดเป็นของชั่วคราวระหว่างแต่ง ส่วนชุดนี้คือ **ข้อมูลโปรไฟล์** —
// เจ้าของกรอกครั้งเดียวแล้วการ์ดทุกใบดึงไปใช้ (เหมือน `Profile.me`) ปิดแอปแล้วหายไม่ได้
// วันที่ต่อ API ของ Sale Here ก็แทนแค่ `load`/`persist` ในไฟล์นี้
//
// # การ์ดอ่านยังไง
//
// `PhotoStore.image(_:)` ถามที่นี่ก่อนตกไปรูปตัวอย่าง:
// ช่องรูปครีเอเตอร์ (1–3) → `creators` · ช่องอื่น → `works` (ดู `PhotoStore.library`)
//
// singleton ด้วยเหตุผลเดียวกับ `Profile.me` — ตัวเรนเดอร์รูปตอนแชร์สร้างต้นไม้ใหม่ทั้งก้อน

@Observable
final class Portfolio {
    static let shared = Portfolio()

    static let creatorSlots = 3
    static let workMax = 10
    static let videoMax = 5
    /// เท่ากับขีดของแอป Sale Here เดิม
    static let videoMaxMB = 100

    enum VideoResult { case added, tooBig, failed }

    struct Photo: Identifiable {
        let id: UUID
        let image: UIImage
    }

    struct Video: Identifiable {
        let id: UUID
        let file: URL
        let thumb: UIImage
        let duration: Double
    }

    /// ช่องคงที่ 3 ช่อง — ว่างได้ทีละช่อง ลำดับช่องคือลำดับบนการ์ด
    private(set) var creators: [UIImage?] = Array(repeating: nil, count: creatorSlots) { didSet { revision &+= 1 } }
    private(set) var works: [Photo] = [] { didSet { revision &+= 1 } }
    private(set) var videos: [Video] = [] { didSet { revision &+= 1 } }
    /// นับทุกครั้งที่รูป/วิดีโอเปลี่ยน — ให้รูปย่อเทมเพลตที่อบไว้รู้ว่าต้องอบใหม่
    @ObservationIgnored private(set) var revision = 0

    private init() { load() }

    // MARK: อ่านให้การ์ด

    /// รูปครีเอเตอร์ที่ใส่แล้ว เรียงตามช่อง — ใส่ไว้ใบเดียวก็วนใบเดียวให้ทั้งสามช่องบนการ์ด
    var creatorImages: [UIImage] { creators.compactMap { $0 } }

    func creatorImage(slot i: Int) -> UIImage? {
        let set = creatorImages
        guard !set.isEmpty else { return nil }
        let n = i % PhotoLib.count
        return set[max(0, n - 1) % set.count]
    }

    func workImage(slot i: Int) -> UIImage? {
        works.isEmpty ? nil : works[i % works.count].image
    }

    // MARK: เขียน

    func setCreator(_ image: UIImage, at i: Int) {
        guard creators.indices.contains(i) else { return }
        let img = image.fitted()
        creators[i] = img
        write(img, to: Self.file("creator-\(i).jpg"))
    }

    func clearCreator(at i: Int) {
        guard creators.indices.contains(i) else { return }
        creators[i] = nil
        write(nil, to: Self.file("creator-\(i).jpg"))
    }

    func addWorks(_ images: [UIImage]) {
        for image in images.prefix(Self.workMax - works.count) {
            let p = Photo(id: UUID(), image: image.fitted())
            works.append(p)
            write(p.image, to: Self.file("work-\(p.id.uuidString).jpg"))
        }
        persist()
    }

    func replaceWork(_ id: UUID, with image: UIImage) {
        guard let i = works.firstIndex(where: { $0.id == id }) else { return }
        let p = Photo(id: id, image: image.fitted())
        works[i] = p
        write(p.image, to: Self.file("work-\(id.uuidString).jpg"))
    }

    func removeWork(_ id: UUID) {
        works.removeAll { $0.id == id }
        write(nil, to: Self.file("work-\(id.uuidString).jpg"))
        persist()
    }

    /// รับไฟล์วิดีโอที่เลือกมา (ไฟล์ชั่วคราว) — ย้ายเข้าที่เก็บ ทำรูปปก แล้วจดลงรายการ
    @MainActor
    func addVideo(from temp: URL) async -> VideoResult {
        guard videos.count < Self.videoMax else { return .failed }
        let bytes = (try? temp.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard bytes <= Self.videoMaxMB * 1_000_000 else {
            try? FileManager.default.removeItem(at: temp)
            return .tooBig
        }
        let id = UUID()
        let ext = temp.pathExtension.isEmpty ? "mov" : temp.pathExtension
        let dest = Self.file("video-\(id.uuidString).\(ext)")
        do {
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: temp, to: dest)
        } catch { return .failed }
        guard let v = await Self.makeVideo(id: id, file: dest) else {
            try? FileManager.default.removeItem(at: dest)
            return .failed
        }
        videos.append(v)
        write(v.thumb, to: Self.file("video-\(id.uuidString).jpg"))
        persist()
        return .added
    }

    func removeVideo(_ id: UUID) {
        guard let v = videos.first(where: { $0.id == id }) else { return }
        videos.removeAll { $0.id == id }
        try? FileManager.default.removeItem(at: v.file)
        write(nil, to: Self.file("video-\(id.uuidString).jpg"))
        persist()
    }

    func resetAll() {
        for i in creators.indices { clearCreator(at: i) }
        for w in works { removeWork(w.id) }
        for v in videos { removeVideo(v.id) }
    }

    // MARK: ตัวอย่างสำหรับทดสอบ flow (`StarFlow.autofill`)

    /// เติมช่องที่ยังไม่ถึงขั้นต่ำ: รูปของคุณ 3 · ผลงาน 2 · คลิป 2 (คลิปทำจากรูปตัวอย่าง 2 วินาที)
    @MainActor
    func fillSample() async {
        guard !filling else { return }
        filling = true
        defer { filling = false }
        let pics = ["ph01", "ph02", "ph03", "ph04"].compactMap { UIImage(named: $0) }
        guard pics.count == 4 else { return }
        for i in creators.indices where creators[i] == nil { setCreator(pics[i], at: i) }
        if works.count < 2 { addWorks(Array([pics[3], pics[1]].prefix(2 - works.count))) }
        var k = 0
        while videos.count < 2, k < 4 {
            guard let tmp = await Self.sampleClip(pics[(videos.count + 2) % 4]) else { break }
            _ = await addVideo(from: tmp)
            k += 1
        }
    }
    @ObservationIgnored private var filling = false

    /// คลิปนิ่ง 2 วินาทีจากรูปเดียว — ไฟล์ชั่วคราว (addVideo ย้ายเข้าที่เก็บเอง)
    private static func sampleClip(_ image: UIImage) async -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        let size = CGSize(width: 540, height: 960)
        guard let w = try? AVAssetWriter(outputURL: url, fileType: .mp4) else { return nil }
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: size.width, AVVideoHeightKey: size.height])
        let px = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: size.width, kCVPixelBufferHeightKey as String: size.height])
        w.add(input)
        guard w.startWriting() else { return nil }
        w.startSession(atSourceTime: .zero)
        let frame = UIGraphicsImageRenderer(size: size, format: { let f = UIGraphicsImageRendererFormat.default(); f.scale = 1; return f }()).image { _ in
            let k = max(size.width / image.size.width, size.height / image.size.height)
            let d = CGSize(width: image.size.width * k, height: image.size.height * k)
            image.draw(in: CGRect(x: (size.width - d.width) / 2, y: (size.height - d.height) / 2, width: d.width, height: d.height))
        }
        guard let cg = frame.cgImage, let pool = px.pixelBufferPool else { return nil }
        var buf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buf)
        guard let buf else { return nil }
        CVPixelBufferLockBaseAddress(buf, [])
        let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buf), width: Int(size.width), height: Int(size.height), bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buf), space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        ctx?.draw(cg, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buf, [])
        for t in [0, 1, 2] {
            while !input.isReadyForMoreMediaData { try? await Task.sleep(nanoseconds: 5_000_000) }
            px.append(buf, withPresentationTime: CMTime(value: CMTimeValue(t), timescale: 1))
        }
        input.markAsFinished()
        await w.finishWriting()
        return w.status == .completed ? url : nil
    }

    // MARK: ที่เก็บ

    private struct Manifest: Codable {
        var works: [UUID]
        var videos: [VideoEntry]
    }

    private struct VideoEntry: Codable {
        let id: UUID
        let fileName: String
        let duration: Double
    }

    private static var dir: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let d = base.appendingPathComponent("starcard-portfolio", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    private static func file(_ name: String) -> URL { dir.appendingPathComponent(name) }

    private func persist() {
        let m = Manifest(works: works.map(\.id),
                         videos: videos.map { VideoEntry(id: $0.id, fileName: $0.file.lastPathComponent,
                                                         duration: $0.duration) })
        guard let data = try? JSONEncoder().encode(m) else { return }
        try? data.write(to: Self.file("manifest.json"), options: .atomic)
    }

    /// อ่านตอนเกิดเลย — การ์ดวาดเฟรมแรกด้วยรูปของเจ้าของ ไม่ใช่รูปตัวอย่างแล้วกระพริบเปลี่ยน
    private func load() {
        for i in creators.indices {
            creators[i] = UIImage(contentsOfFile: Self.file("creator-\(i).jpg").path)
        }
        guard let data = try? Data(contentsOf: Self.file("manifest.json")),
              let m = try? JSONDecoder().decode(Manifest.self, from: data) else { return }
        works = m.works.compactMap { id in
            UIImage(contentsOfFile: Self.file("work-\(id.uuidString).jpg").path).map { Photo(id: id, image: $0) }
        }
        videos = m.videos.compactMap { e in
            let f = Self.file(e.fileName)
            guard FileManager.default.fileExists(atPath: f.path),
                  let thumb = UIImage(contentsOfFile: Self.file("video-\(e.id.uuidString).jpg").path)
            else { return nil }
            return Video(id: e.id, file: f, thumb: thumb, duration: e.duration)
        }
    }

    private func write(_ image: UIImage?, to url: URL) {
        DispatchQueue.global(qos: .utility).async {
            guard let image else {
                try? FileManager.default.removeItem(at: url)
                return
            }
            guard let data = image.diskData(quality: 0.88) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }

    private static func makeVideo(id: UUID, file: URL) async -> Video? {
        let asset = AVURLAsset(url: file)
        let seconds = (try? await asset.load(.duration)).map(CMTimeGetSeconds) ?? 0
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 900, height: 900)
        let at = CMTime(seconds: min(0.5, seconds / 2), preferredTimescale: 600)
        guard let cg = try? await gen.image(at: at).image else { return nil }
        return Video(id: id, file: file, thumb: UIImage(cgImage: cg), duration: seconds.isFinite ? seconds : 0)
    }
}

// MARK: - รับวิดีโอจาก PhotosPicker

/// วิดีโอที่เลือกจากคลังรูป — ระบบให้ไฟล์ชั่วคราวที่จะถูกลบทันทีหลังคืนค่า จึงต้องคัดลอกออกมาก่อน
struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension)
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

extension UIImage {
    /// ย่อด้านยาวให้ไม่เกิน `side` — รูปจากกล้องสิบกว่าล้านพิกเซลสิบใบคือหน่วยความจำหลายร้อย MB
    func fitted(_ side: CGFloat = 1600) -> UIImage {
        let long = max(size.width, size.height)
        guard long > side else { return self }
        let k = side / long
        let target = CGSize(width: (size.width * k).rounded(), height: (size.height * k).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
