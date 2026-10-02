import SwiftUI

// MARK: - โหมดลองทำ — การ์ดกลางบน sync-server
//
// # ทำไมมีไฟล์นี้
//
// ทดสอบว่า "การ์ดเป็น JSON ก้อนเดียว" ใช้ได้จริงข้ามแพลตฟอร์มไหม: iOS กับ Android แก้การ์ดใบเดียวกัน
// ผ่านที่เก็บกลาง (`sync-server/`) แล้วดูว่าค่าที่อีกฝั่งเขียน พอเครื่องนี้อ่านแล้วเขียนกลับ **ค่าเปลี่ยนไหม**
// สัญญาเต็ม (รูปร่าง JSON · API · ขั้นตอน) อยู่ที่ `sync-server/README.md` — Android ทำตามไฟล์เดียวกัน
//
// # ข้อมูลเดิมไม่หาย
//
// เปิดโหมดครั้งแรก = สำรอง UserDefaults + Documents ทั้งหมดไว้ก่อน (`LabMode.bootstrap`)
// ระหว่างลองจะแก้/ลบอะไรในเครื่องก็ได้ ปิดโหมดเมื่อไหร่ของเดิมถูกคืนกลับทั้งก้อน
// การสลับโหมดจึงมีผลตอนเปิดแอปครั้งถัดไปเท่านั้น — ต้องสำรอง/คืนก่อนสโตร์ตัวไหนอ่านดิสก์

enum LabMode {
    /// ตัดสินครั้งเดียวตอนเปิดแอป — ระหว่างรันเปลี่ยนไม่ได้ (ดูหัวไฟล์)
    private(set) static var isOn = false

    static let defaultServer = "http://127.0.0.1:8787"

    private struct Flag: Codable {
        var enabled = false
        var server: String?
    }

    private static let fm = FileManager.default
    private static var support: URL {
        let u = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? fm.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }
    /// ธงอยู่นอกทุกอย่างที่ถูกสำรอง — ไม่งั้นการคืนข้อมูลจะเขียนทับธงของตัวเอง
    private static var flagURL: URL { support.appendingPathComponent("lab-mode.json") }
    static var stateURL: URL { support.appendingPathComponent("lab-state.json") }
    private static var backupURL: URL { support.appendingPathComponent("lab-backup", isDirectory: true) }
    private static var documents: URL { fm.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    private static var bundleID: String { Bundle.main.bundleIdentifier ?? "starcard" }

    private static func readFlag() -> Flag {
        guard let d = try? Data(contentsOf: flagURL), let f = try? JSONDecoder().decode(Flag.self, from: d) else { return Flag() }
        return f
    }
    private static func writeFlag(_ f: Flag) {
        if let d = try? JSONEncoder().encode(f) { try? d.write(to: flagURL, options: .atomic) }
    }

    static var server: URL {
        URL(string: readFlag().server ?? defaultServer) ?? URL(string: defaultServer)!
    }

    /// เรียกก่อนสโตร์ใด ๆ โหลดดิสก์ — `StarCardApp.init`
    ///
    /// launch argument `-labSync YES|NO` ตั้งธงได้ตรง ๆ (ไว้ทดสอบอัตโนมัติ) · `-labServer URL` เปลี่ยนที่อยู่
    static func bootstrap() {
        var flag = readFlag()
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-labSync"), args.indices.contains(i + 1) {
            flag.enabled = ["1", "YES", "true", "on"].contains(args[i + 1])
        }
        if let i = args.firstIndex(of: "-labServer"), args.indices.contains(i + 1) {
            flag.server = args[i + 1]
        }
        writeFlag(flag)

        let hasBackup = fm.fileExists(atPath: backupURL.path)
        if flag.enabled && !hasBackup { makeBackup() }
        if !flag.enabled && hasBackup {
            restoreBackup()
            try? fm.removeItem(at: stateURL)
        }
        isOn = flag.enabled
    }

    /// สั่งเปิด/ปิดจากแผง Lab — แอปปิดตัวเอง แล้วโหมดใหม่มีผลตอนเปิดครั้งถัดไป
    static func request(_ on: Bool) {
        var f = readFlag()
        f.enabled = on
        writeFlag(f)
        UserDefaults.standard.synchronize()
        // รอให้สโตร์ที่หน่วงการเขียนไว้ (manifest รูป 0.4 วิ · ข้อความ) ลงดิสก์ก่อน
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { exit(0) }
    }

    private static func makeBackup() {
        try? fm.createDirectory(at: backupURL, withIntermediateDirectories: true)
        let domain = UserDefaults.standard.persistentDomain(forName: bundleID) ?? [:]
        if let d = try? PropertyListSerialization.data(fromPropertyList: domain, format: .binary, options: 0) {
            try? d.write(to: backupURL.appendingPathComponent("defaults.plist"))
        }
        try? fm.copyItem(at: documents, to: backupURL.appendingPathComponent("Documents", isDirectory: true))
    }

    private static func restoreBackup() {
        if let d = try? Data(contentsOf: backupURL.appendingPathComponent("defaults.plist")),
           let dict = try? PropertyListSerialization.propertyList(from: d, format: nil) as? [String: Any] {
            UserDefaults.standard.setPersistentDomain(dict, forName: bundleID)
            UserDefaults.standard.synchronize()
        }
        let saved = backupURL.appendingPathComponent("Documents", isDirectory: true)
        if fm.fileExists(atPath: saved.path) {
            for f in (try? fm.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil)) ?? [] {
                try? fm.removeItem(at: f)
            }
            for f in (try? fm.contentsOfDirectory(at: saved, includingPropertiesForKeys: nil)) ?? [] {
                try? fm.moveItem(at: f, to: documents.appendingPathComponent(f.lastPathComponent))
            }
        }
        try? fm.removeItem(at: backupURL)
    }
}

// MARK: - JSON ของการ์ด (= api/star-card/example-doc.json)

struct LabDoc: Codable {
    struct Fit: Codable { var dx: Double; var dy: Double; var zoom: Double }
    struct Photo: Codable {
        var imageId: String?
        var fit: Fit?
    }

    /// ข้อมูลเจ้าของการ์ด — ข้อความส่วนใหญ่บนการ์ด (ชื่อ แนะนำตัว เรต…) และรูปในช่องที่ไม่ได้ใส่รูปเอง
    ///
    /// ของจริงไม่อยู่ในก้อนการ์ด server เติมให้จาก `owner: User` (ดู `api/star-card/star-card.schema.graphql`)
    /// แต่โหมดลองทำคือ "คนเดียวกันสองเครื่อง" จึงต้องส่งไปด้วย ไม่งั้นสองเครื่องโชว์คนละชื่อคนละรูป
    struct Owner: Codable {
        /// `Profile` — ค่าที่พิมพ์เอง (คีย์ = ProfileField.rawValue) · รายการชิป · ข้อมูลฟอร์ม
        var values: [String: String] = [:]
        var list: [String: [String]] = [:]
        var intake: IntakeData?
        /// รูปโปรไฟล์ (`PhotoStore.profile`)
        var avatarImageId: String?
        /// รูปครีเอเตอร์ 3 ช่อง (`Portfolio.creators`) — null = ช่องว่าง
        var creatorImageIds: [String?] = []
        /// รูปผลงาน (`Portfolio.works`) และคลังรูป (`PhotoStore.uploaded`) ตามลำดับ
        var workImageIds: [String] = []
        var libraryImageIds: [String] = []

        init() {}

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            values = try c.decodeIfPresent([String: String].self, forKey: .values) ?? [:]
            list = try c.decodeIfPresent([String: [String]].self, forKey: .list) ?? [:]
            intake = try c.decodeIfPresent(IntakeData.self, forKey: .intake)
            avatarImageId = try c.decodeIfPresent(String.self, forKey: .avatarImageId)
            creatorImageIds = try c.decodeIfPresent([String?].self, forKey: .creatorImageIds) ?? []
            workImageIds = try c.decodeIfPresent([String].self, forKey: .workImageIds) ?? []
            libraryImageIds = try c.decodeIfPresent([String].self, forKey: .libraryImageIds) ?? []
        }
    }

    var schemaVersion = 1
    var format: String
    var name: String
    var theme: CardSnapshot.Theme
    var pages: [CardSnapshot.Page]
    var photos: [String: Photo] = [:]
    var notes: [String: String] = [:]
    var backgroundImageId: String?
    var owner: Owner?

    init(format: String, name: String, theme: CardSnapshot.Theme, pages: [CardSnapshot.Page],
         photos: [String: Photo], notes: [String: String], backgroundImageId: String?, owner: Owner?) {
        self.format = format
        self.name = name
        self.theme = theme
        self.pages = pages
        self.photos = photos
        self.notes = notes
        self.backgroundImageId = backgroundImageId
        self.owner = owner
    }

    // อีกฝั่งอาจไม่ส่ง photos/notes มาเลย — ขาดสองก้อนนี้ต้องไม่ทำให้ทั้งการ์ดอ่านไม่ได้
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        format = try c.decodeIfPresent(String.self, forKey: .format) ?? CardFormat.portfolio.rawValue
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        theme = try c.decode(CardSnapshot.Theme.self, forKey: .theme)
        pages = try c.decode([CardSnapshot.Page].self, forKey: .pages)
        photos = try c.decodeIfPresent([String: Photo].self, forKey: .photos) ?? [:]
        notes = try c.decodeIfPresent([String: String].self, forKey: .notes) ?? [:]
        backgroundImageId = try c.decodeIfPresent(String.self, forKey: .backgroundImageId)
        owner = try c.decodeIfPresent(Owner.self, forKey: .owner)
    }

    /// คีย์ของช่องรูป `"<UUID>#<slot>"` → (widget, slot)
    static func slotKey(_ key: String) -> (UUID, Int)? {
        let parts = key.split(separator: "#", maxSplits: 1)
        guard parts.count == 2, let id = UUID(uuidString: String(parts[0])), let s = Int(parts[1]) else { return nil }
        return (id, s)
    }
}

// MARK: - ตัวซิงก์

@Observable
@MainActor
final class LabSync {
    static let shared = LabSync()

    enum Phase: Equatable {
        case idle, connecting, synced, pushing
        case offline(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var rev = 0
    /// ผลตรวจล่าสุดของเครื่องนี้ — รับ rev ของอีกฝั่งมาแล้วเขียนกลับ ค่าเพี้ยนกี่จุด · nil = ยังไม่เคยรับ
    private(set) var lastEcho: Int?
    /// เพิ่มทุกครั้งที่รับการ์ดจากเครื่องอื่นมาใช้ — ห้องแต่งที่เปิดใบนี้อยู่ดูค่านี้แล้วโหลดใหม่
    private(set) var remoteStamp = 0
    /// ใบในคลังที่เป็นการ์ดกลาง
    private(set) var cardID: String?

    @ObservationIgnored private weak var photos: PhotoStore?
    /// doc ที่ซิงก์ล่าสุด (ตามที่เครื่องนี้ encode) — ต่างจากนี้เมื่อไหร่ = ผู้ใช้แก้ ต้องส่ง
    @ObservationIgnored private var lastJSON: Data?
    /// รูปที่รู้ id แล้ว — ถือตัวรูปไว้ด้วย กัน ObjectIdentifier ถูกใช้ซ้ำหลังรูปเก่าถูกคืนหน่วยความจำ
    @ObservationIgnored private var known: [ObjectIdentifier: (image: UIImage, id: String)] = [:]
    /// "<UUID>#<slot>" / "bg" → imageId — จำข้ามการเปิดแอป (รูปที่โหลดจากดิสก์เป็นอ็อบเจกต์ใหม่ทุกครั้ง)
    @ObservationIgnored private var slotIDs: [String: String] = [:]
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var busy = false
    @ObservationIgnored private let server = LabMode.server
    @ObservationIgnored private let session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.timeoutIntervalForRequest = 8
        return URLSession(configuration: c)
    }()

    private static let platform = "ios"
    private static var device: String {
        ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? UIDevice.current.name
    }

    enum LabError: LocalizedError {
        case http(Int), badImage
        var errorDescription: String? {
            switch self {
            case .http(let c): return "server ตอบ \(c)"
            case .badImage: return "อ่านรูปไม่ได้"
            }
        }
    }

    // MARK: เริ่ม

    func start(photos: PhotoStore) {
        guard LabMode.isOn, loop == nil else { return }
        self.photos = photos
        loadState()
        loop = Task { [weak self] in
            while !Task.isCancelled {
                await self?.tick()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func tick() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            if phase == .idle || phase == .connecting { try await connect(); return }
            if let id = cardID, CardLibrary.shared.card(id: id) == nil { cardID = nil; rev = 0; lastJSON = nil }
            guard cardID != nil else { try await connect(); return }

            // ดึงก่อนส่ง — มี rev ใหม่ระหว่างที่เครื่องนี้ก็แก้อยู่ = ชนกัน ของที่ server ชนะ
            if let remote = try await fetch(known: rev), remote.rev != rev {
                try await receive(remote)
                return
            }
            guard let id = cardID, let record = CardLibrary.shared.card(id: id) else { return }
            let doc = try await build(record)
            let json = try encode(doc)
            if json != lastJSON { try await push(doc, json) }
            phase = .synced
        } catch {
            phase = .offline(error.localizedDescription)
        }
    }

    /// เปิดครั้งแรก: server ว่าง = ใบหลักของเครื่องนี้เป็นการ์ดกลาง · มีแล้ว = รับมาใช้
    private func connect() async throws {
        phase = .connecting
        guard let remote = try await fetch(known: nil) else { return }
        if remote.doc == nil {
            guard let first = CardLibrary.shared.displayOrder.first else { return }   // ยังไม่มีการ์ด — รอบหน้าลองใหม่
            CardLibrary.shared.labKeepOnly(first.id)
            cardID = first.id
            rev = 0
            let doc = try await build(first)
            try await push(doc, try encode(doc))
        } else if remote.rev == rev, let id = cardID, CardLibrary.shared.card(id: id) != nil,
                  !hasNewFields(remote.doc) {
            CardLibrary.shared.labKeepOnly(id)   // เปิดแอปใหม่ในโหมดเดิม — rev เท่าเดิม ไม่ต้องโหลดซ้ำ
        } else {
            try await receive(remote)
        }
        phase = .synced
    }

    /// ฉบับบน server มีก้อนที่ตอนซิงก์ล่าสุดเครื่องนี้ยังไม่รู้จักไหม (เช่นเพิ่งอัปเดตแอปจนอ่าน `owner` ได้)
    ///
    /// rev เท่าเดิมแต่ต้องโหลดใหม่ — ไม่งั้นรอบแรกหลังอัปเดตจะส่งข้อมูลในเครื่องขึ้นไปทับของอีกฝั่ง
    /// (เกิดจริง 25 ก.ย. 2569: Android อัปเดตแล้วเขียน owner ของตัวเองทับชื่อ/รูปของ iOS)
    private func hasNewFields(_ doc: LabDoc?) -> Bool {
        guard let doc, let last = lastJSON,
              let seen = (try? JSONSerialization.jsonObject(with: last)) as? [String: Any],
              let now = (try? JSONSerialization.jsonObject(with: encode(doc))) as? [String: Any] else { return false }
        return !Set(now.keys).subtracting(seen.keys).isEmpty
    }

    // MARK: ส่ง

    private func push(_ doc: LabDoc, _ json: Data) async throws {
        struct Body: Encodable { var baseRev: Int; var doc: LabDoc; var platform: String; var device: String }
        phase = .pushing
        var req = URLRequest(url: server.appendingPathComponent("api/card"))
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(Body(baseRev: rev, doc: doc, platform: Self.platform, device: Self.device))
        let (data, resp) = try await session.data(for: req)
        switch (resp as? HTTPURLResponse)?.statusCode ?? 0 {
        case 200:
            struct Ok: Decodable { var rev: Int }
            rev = try JSONDecoder().decode(Ok.self, from: data).rev
            lastJSON = json
            saveState()
        case 409:
            // อีกเครื่องเขียนก่อน — รับฉบับของเขามาใช้ (งานแก้ล่าสุดของเครื่องนี้ถูกทิ้ง)
            try await receive(try JSONDecoder().decode(Remote.self, from: data))
        case let code:
            throw LabError.http(code)
        }
    }

    // MARK: รับ

    private struct Remote: Decodable {
        struct By: Decodable { var platform: String?; var device: String? }
        var rev: Int
        var doc: LabDoc?
        var by: By?
    }

    private func fetch(known: Int?) async throws -> Remote? {
        var c = URLComponents(url: server.appendingPathComponent("api/card"), resolvingAgainstBaseURL: false)!
        if let known { c.queryItems = [URLQueryItem(name: "known", value: String(known))] }
        let (data, resp) = try await session.data(from: c.url!)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if code == 204 { return nil }
        guard code == 200 else { throw LabError.http(code) }
        return try JSONDecoder().decode(Remote.self, from: data)
    }

    private func receive(_ remote: Remote) async throws {
        guard let doc = remote.doc else {
            // server ถูกล้าง — รอบหน้าเครื่องนี้ส่งการ์ดของตัวเองขึ้นไปเป็นใบตั้งต้น
            rev = 0
            lastJSON = nil
            return
        }
        try await apply(doc)
        rev = remote.rev
        guard let id = cardID, let record = CardLibrary.shared.card(id: id) else { return }
        // echo = สิ่งที่เครื่องนี้จะเขียน ถ้าให้เขียนตอนนี้ — server เทียบกับ doc ของ rev นั้น
        let mine = try await build(record)
        lastJSON = try encode(mine)
        saveState()
        lastEcho = try await echo(mine, rev: remote.rev)
    }

    /// ใช้ doc จากเครื่องอื่นกับการ์ดในเครื่องนี้ — รูปที่ยังไม่มีโหลดมาก่อน
    private func apply(_ doc: LabDoc) async throws {
        guard let photos else { return }
        // การ์ดต้องผ่านโมเดลจริงไปกลับหนึ่งรอบ — ค่าที่แอปทิ้ง/ปัดระหว่างโหลดจะได้โผล่ใน echo
        let raw = CardSnapshot(pages: doc.pages, theme: doc.theme, index: 0)
        let snap = CardStore.restore(raw, format: CardFormat(rawValue: doc.format) ?? .portfolio).map { CardStore.snapshot(pages: $0.pages, theme: $0.theme, index: 0) } ?? raw
        cardID = CardLibrary.shared.labUpsert(id: cardID, name: doc.name,
                                               format: CardFormat(rawValue: doc.format) ?? .portfolio,
                                               snapshot: snap)
        let widgets = Set(snap.pages.flatMap(\.items).compactMap { $0.id.flatMap(UUID.init(uuidString:)) })

        // รูปในช่อง + การจัดกรอบ
        for (key, p) in doc.photos {
            guard let (wid, slot) = LabDoc.slotKey(key) else { continue }
            let mine = "\(wid.uuidString)#\(slot)"
            if let imageID = p.imageId, slotIDs[mine] != imageID || !photos.has(slot: slot, for: wid) {
                let img = try await download(imageID)
                photos.set([img], from: slot, order: [slot], for: wid)
                remember(img, imageID, slot: mine)
            }
            if let f = p.fit {
                photos.setFit(PhotoFit(dx: f.dx, dy: f.dy, zoom: f.zoom), slot: slot, for: wid)
            } else {
                photos.resetFit(slot: slot, for: wid)
            }
        }
        // ช่องที่อีกฝั่งไม่มีแล้ว — คืนเป็นรูประบบ/กรอบตั้งต้น
        let incoming = Set(doc.photos.keys.compactMap { LabDoc.slotKey($0) }.map { "\($0.0.uuidString)#\($0.1)" })
        let withImage = Set(doc.photos.compactMap { k, v in v.imageId == nil ? nil : LabDoc.slotKey(k).map { "\($0.0.uuidString)#\($0.1)" } })
        for wid in widgets {
            for slot in (photos.perWidget[wid] ?? [:]).keys where !withImage.contains("\(wid.uuidString)#\(slot)") {
                photos.clear(slot: slot, for: wid)
                slotIDs["\(wid.uuidString)#\(slot)"] = nil
            }
            for slot in (photos.fits[wid] ?? [:]).keys where !incoming.contains("\(wid.uuidString)#\(slot)") {
                photos.resetFit(slot: slot, for: wid)
            }
        }
        // พื้นหลัง
        if let bg = doc.backgroundImageId, slotIDs["bg"] != bg || photos.background == nil {
            let img = try await download(bg)
            photos.setBackground(img)
            remember(img, bg, slot: "bg")
        }
        Profile.me.applyLabNotes(doc.notes, for: widgets)
        if let o = doc.owner { try await applyOwner(o, photos: photos) }
        remoteStamp &+= 1
    }

    /// ข้อความและรูปของเจ้าของการ์ด — ทุกรูปอ่านกลับจากสโตร์หลังใส่ (บางสโตร์ย่อรูปเป็นอ็อบเจกต์ใหม่)
    /// ไม่งั้นรอบถัดไปจะไม่รู้จักรูปนั้นแล้วอัปขึ้นไปซ้ำเป็นรูปใหม่
    private func applyOwner(_ o: LabDoc.Owner, photos: PhotoStore) async throws {
        Profile.me.applyLabOwner(values: o.values, list: o.list, intake: o.intake)

        if let id = o.avatarImageId {
            if slotIDs["avatar"] != id || photos.profile == nil {
                photos.setProfile(try await download(id))
                if let p = photos.profile { remember(p, id, slot: "avatar") }
            }
        } else if photos.profile != nil {
            photos.clearProfile()
            slotIDs["avatar"] = nil
        }

        let folio = Portfolio.shared
        for i in 0..<Portfolio.creatorSlots {
            let key = "creator#\(i)"
            let want = o.creatorImageIds.indices.contains(i) ? o.creatorImageIds[i] : nil
            if let id = want {
                if slotIDs[key] != id || folio.creators[i] == nil {
                    folio.setCreator(try await download(id), at: i)
                    if let img = folio.creators[i] { remember(img, id, slot: key) }
                }
            } else if folio.creators[i] != nil {
                folio.clearCreator(at: i)
                slotIDs[key] = nil
            }
        }

        // รายการ — ลำดับเปลี่ยนหรือของไม่ตรง = ล้างแล้วใส่ใหม่ทั้งชุด (ง่ายกว่าไล่แก้ทีละตัว และรายการสั้น)
        if folio.works.map({ known[ObjectIdentifier($0.image)]?.id }) != o.workImageIds.map(Optional.some) {
            var imgs: [UIImage] = []
            for id in o.workImageIds { imgs.append(try await download(id)) }
            for w in folio.works { folio.removeWork(w.id) }
            folio.addWorks(imgs)
            for (i, w) in folio.works.enumerated() where o.workImageIds.indices.contains(i) {
                remember(w.image, o.workImageIds[i], slot: "work#\(i)")
            }
        }
        if photos.uploaded.map({ known[ObjectIdentifier($0)]?.id }) != o.libraryImageIds.map(Optional.some) {
            var imgs: [UIImage] = []
            for id in o.libraryImageIds { imgs.append(try await download(id)) }
            photos.clear()
            photos.add(imgs)
            for (i, img) in photos.uploaded.enumerated() where o.libraryImageIds.indices.contains(i) {
                remember(img, o.libraryImageIds[i], slot: "lib#\(i)")
            }
        }
    }

    // MARK: สร้าง doc จากสถานะในเครื่อง

    private func build(_ record: CardRecord) async throws -> LabDoc {
        let snap = record.snapshot
        let widgets = snap.pages.flatMap(\.items).compactMap { $0.id.flatMap(UUID.init(uuidString:)) }
        var out: [String: LabDoc.Photo] = [:]
        if let photos {
            for wid in widgets {
                let own = photos.perWidget[wid] ?? [:]
                let fits = photos.fits[wid] ?? [:]
                for slot in Set(own.keys).union(fits.keys).sorted() {
                    let key = "\(wid.uuidString)#\(slot)"
                    var p = LabDoc.Photo()
                    if let img = own[slot] { p.imageId = try await imageID(img, slot: key) }
                    if let f = fits[slot], !f.isIdentity { p.fit = .init(dx: f.dx, dy: f.dy, zoom: f.zoom) }
                    if p.imageId != nil || p.fit != nil { out[key] = p }
                }
            }
        }
        var bg: String?
        if snap.theme.backdrop == BackdropStyle.photo.rawValue, let b = photos?.background {
            bg = try await imageID(b, slot: "bg")
        }
        return LabDoc(format: record.formatRaw, name: record.name, theme: snap.theme, pages: snap.pages,
                      photos: out, notes: Profile.me.labNotes(for: Set(widgets)), backgroundImageId: bg,
                      owner: try await buildOwner())
    }

    private func buildOwner() async throws -> LabDoc.Owner {
        var o = LabDoc.Owner()
        let text = Profile.me.labOwner()
        o.values = text.values
        o.list = text.list
        o.intake = text.intake
        if let p = photos?.profile { o.avatarImageId = try await imageID(p, slot: "avatar") }
        let folio = Portfolio.shared
        for (i, img) in folio.creators.enumerated() {
            if let img { o.creatorImageIds.append(try await imageID(img, slot: "creator#\(i)")) } else { o.creatorImageIds.append(nil) }
        }
        for (i, w) in folio.works.enumerated() { o.workImageIds.append(try await imageID(w.image, slot: "work#\(i)")) }
        for (i, img) in (photos?.uploaded ?? []).enumerated() { o.libraryImageIds.append(try await imageID(img, slot: "lib#\(i)")) }
        return o
    }

    private func encode(_ doc: LabDoc) throws -> Data {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return try e.encode(doc)
    }

    // MARK: รูป

    private func remember(_ img: UIImage, _ id: String, slot: String) {
        known[ObjectIdentifier(img)] = (img, id)
        slotIDs[slot] = id
    }

    private func imageID(_ img: UIImage, slot: String) async throws -> String {
        if let k = known[ObjectIdentifier(img)] { slotIDs[slot] = k.id; return k.id }
        let (data, type) = Self.uploadData(img)
        var req = URLRequest(url: server.appendingPathComponent("api/images"))
        req.httpMethod = "POST"
        req.setValue(type, forHTTPHeaderField: "Content-Type")
        let (body, resp) = try await session.upload(for: req, from: data)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw LabError.http((resp as? HTTPURLResponse)?.statusCode ?? 0) }
        struct Ok: Decodable { var imageId: String }
        let id = try JSONDecoder().decode(Ok.self, from: body).imageId
        remember(img, id, slot: slot)
        return id
    }

    private func download(_ id: String) async throws -> UIImage {
        let (data, resp) = try await session.data(from: server.appendingPathComponent("api/images/\(id)"))
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw LabError.http((resp as? HTTPURLResponse)?.statusCode ?? 0) }
        guard let img = UIImage(data: data) else { throw LabError.badImage }
        return img
    }

    /// ย่อด้านยาวไม่เกิน 2048 px · มีพื้นโปร่ง = PNG ที่เหลือ JPEG 0.85 (ตามแผน API จริง)
    private static func uploadData(_ img: UIImage) -> (Data, String) {
        let alpha: Bool = {
            switch img.cgImage?.alphaInfo {
            case .none?, .noneSkipFirst?, .noneSkipLast?: return false
            default: return true
            }
        }()
        let px = CGSize(width: img.size.width * img.scale, height: img.size.height * img.scale)
        let k = min(1, 2048 / max(px.width, px.height, 1))
        var out = img
        if k < 1 {
            let size = CGSize(width: (px.width * k).rounded(), height: (px.height * k).rounded())
            let fmt = UIGraphicsImageRendererFormat.default()
            fmt.scale = 1
            fmt.opaque = !alpha
            out = UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
                img.draw(in: CGRect(origin: .zero, size: size))
            }
        }
        if alpha, let png = out.pngData() { return (png, "image/png") }
        return (out.jpegData(compressionQuality: 0.85) ?? Data(), "image/jpeg")
    }

    // MARK: echo

    private func echo(_ doc: LabDoc, rev: Int) async throws -> Int {
        struct Body: Encodable { var rev: Int; var doc: LabDoc; var platform: String; var device: String }
        struct Res: Decodable { struct D: Decodable { var path: String }; var diffs: [D] }
        var req = URLRequest(url: server.appendingPathComponent("api/echo"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(Body(rev: rev, doc: doc, platform: Self.platform, device: Self.device))
        let (data, _) = try await session.data(for: req)
        return (try? JSONDecoder().decode(Res.self, from: data).diffs.count) ?? 0
    }

    // MARK: สถานะข้ามการเปิดแอป (อยู่นอกของที่ถูกสำรอง — ดู `LabMode`)

    private struct State: Codable {
        var cardID: String?
        var rev: Int
        var lastJSON: String?
        var slotIDs: [String: String]
    }

    private func loadState() {
        guard let d = try? Data(contentsOf: LabMode.stateURL),
              let s = try? JSONDecoder().decode(State.self, from: d) else { return }
        cardID = s.cardID
        rev = s.rev
        lastJSON = s.lastJSON.map { Data($0.utf8) }
        slotIDs = s.slotIDs
        // รูปที่โหลดจากดิสก์เป็นอ็อบเจกต์ใหม่ — ผูก id เดิมกลับ ไม่งั้นเปิดแอปทีไรอัปรูปซ้ำทุกใบ
        guard let photos else { return }
        let folio = Portfolio.shared
        func bind(_ img: UIImage?, _ id: String) { if let img { known[ObjectIdentifier(img)] = (img, id) } }
        func index(_ key: String, _ prefix: String) -> Int? { key.hasPrefix(prefix) ? Int(key.dropFirst(prefix.count)) : nil }
        for (key, id) in slotIDs {
            if key == "bg" {
                bind(photos.background, id)
            } else if key == "avatar" {
                bind(photos.profile, id)
            } else if let i = index(key, "creator#"), folio.creators.indices.contains(i) {
                bind(folio.creators[i], id)
            } else if let i = index(key, "work#"), folio.works.indices.contains(i) {
                bind(folio.works[i].image, id)
            } else if let i = index(key, "lib#"), photos.uploaded.indices.contains(i) {
                bind(photos.uploaded[i], id)
            } else if let (wid, slot) = LabDoc.slotKey(key) {
                bind(photos.perWidget[wid]?[slot], id)
            }
        }
    }

    private func saveState() {
        let s = State(cardID: cardID, rev: rev, lastJSON: lastJSON.flatMap { String(data: $0, encoding: .utf8) }, slotIDs: slotIDs)
        if let d = try? JSONEncoder().encode(s) { try? d.write(to: LabMode.stateURL, options: .atomic) }
    }
}
