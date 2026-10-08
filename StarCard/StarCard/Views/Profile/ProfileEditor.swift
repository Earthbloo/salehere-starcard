import SwiftUI
import PhotosUI
import AVKit
import PhosphorSwift

// MARK: - แก้ไขโปรไฟล์
//
// ช่องชุดเดียวกับหน้า "แก้ไขโปรไฟล์" ของแอป Sale Here เดิม — รูปโปรไฟล์ · ชื่อผู้ใช้ · ลิงก์โปรไฟล์ ·
// About Me · รูปโปรไฟล์ครีเอเตอร์ 3 ช่อง · รูปผลงาน · วิดีโอผลงาน
//
// ไม่อยู่ใน wizard — ลำดับขั้นของ wizard เป็นของทีม MKT (ดูฟอร์มเว็บ v16.1) และช่องพวกนี้ไม่มีในฟอร์มนั้น
// เปิดจากบัตร STAR สีดำบนหน้าโปรไฟล์ ซึ่งเป็นตัวตนเดียวกับที่หน้านี้แก้
//
// ทุกอย่างบันทึกทันที: ข้อความลง `Profile.me` · รูปวงกลมลง `PhotoStore` · ผลงานลง `Portfolio`
// การ์ดอ่านจากที่เดียวกันจึงเปลี่ยนตามโดยไม่ต้องกดบันทึก

struct ProfileEditor: View {
    let onClose: () -> Void

    @Environment(PhotoStore.self) private var photos
    private var p: Profile { Profile.me }
    private var folio: Portfolio { Portfolio.shared }

    @FocusState private var focus: String?

    @State private var avatarPick: PhotosPickerItem?
    @State private var avatarMenu = false
    @State private var avatarLibrary = false
    @State private var cameraOpen = false
    /// ช่องที่กำลังโหลดรูปเข้า — "avatar" · "c0"…"c2" · "w<uuid>" — ขึ้นวงหมุนทับช่องนั้น
    @State private var busy: Set<String> = []
    @State private var importingWorks = 0
    /// ข้อความผิดพลาดล่างจอ — หายเองในไม่กี่วินาที
    @State private var toast: String?
    /// ช่องที่กำลังเลือกรูปให้ — ต้องแยกจากตัวเปิดตัวเลือก เพราะตัวเลือกปิดตัวเองก่อนรูปที่เลือกจะมาถึง
    /// (ถ้าล้างเป้าหมายตอนปิด รูปมาถึงแล้วไม่รู้ว่าจะลงช่องไหน)
    @State private var creatorTarget = 0
    @State private var creatorPicking = false
    @State private var creatorPick: PhotosPickerItem?
    @State private var workPicks: [PhotosPickerItem] = []
    /// รูปผลงานที่กำลังเลือกรูปใหม่มาแทน
    @State private var workTarget: UUID?
    @State private var workPicking = false
    @State private var workReplacePick: PhotosPickerItem?
    @State private var videoPicks: [PhotosPickerItem] = []
    @State private var importingVideos = 0
    @State private var playing: Portfolio.Video?
    @State private var pendingDelete: Removal?

    enum Removal: Identifiable {
        case creator(Int), work(UUID), video(UUID)
        var id: String {
            switch self {
            case .creator(let i): return "c\(i)"
            case .work(let u):    return "w\(u)"
            case .video(let u):   return "v\(u)"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            PKHeader(title: "แก้ไขโปรไฟล์", leftSymbol: .x, leftLabel: "ปิด", onLeft: onClose)
            ScrollView {
                VStack(spacing: 14) {
                    avatar
                    textPanel
                    creatorPanel
                    worksPanel
                    videosPanel
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 60)
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button { focus = nil } label: {
                        Text("เสร็จ").font(.sh(15, .bold)).foregroundStyle(PK.ink)
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                HStack(spacing: 8) {
                    PIcon(.warningCircle, size: 16, weight: .fill).foregroundStyle(PK.red)
                    Text(toast).font(.sh(13.5, .semibold)).foregroundStyle(PK.onInk)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Capsule().fill(PK.ink))
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: toast) {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation(Motion.settle) { self.toast = nil }
                }
            }
        }
        .confirmationDialog("รูปโปรไฟล์", isPresented: $avatarMenu, titleVisibility: .hidden) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("ถ่ายรูป") { cameraOpen = true }
            }
            Button("เลือกจากคลังรูป") { avatarLibrary = true }
        }
        .photosPicker(isPresented: $avatarLibrary, selection: $avatarPick, matching: .images)
        .fullScreenCover(isPresented: $cameraOpen) {
            CameraPicker { img in photos.setProfile(img.fitted(1200)) }
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $creatorPicking, selection: $creatorPick, matching: .images)
        .photosPicker(isPresented: $workPicking, selection: $workReplacePick, matching: .images)
        .onChange(of: avatarPick) { _, item in
            load(item, key: "avatar") { photos.setProfile($0.fitted(1200)) }
            avatarPick = nil
        }
        .onChange(of: creatorPick) { _, item in
            guard let item else { return }
            let i = creatorTarget
            load(item, key: "c\(i)") { folio.setCreator($0, at: i) }
            creatorPick = nil
        }
        .onChange(of: workReplacePick) { _, item in
            guard let item, let id = workTarget else { return }
            load(item, key: "w\(id)") { folio.replaceWork(id, with: $0) }
            workReplacePick = nil
        }
        .onChange(of: workPicks) { _, items in
            guard !items.isEmpty else { return }
            importingWorks = items.count
            workPicks = []
            Task { @MainActor in
                var failed = 0
                // ทีละรูป — ใบที่โหลดเสร็จขึ้นก่อน ไม่ต้องรอทั้งชุด
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        withAnimation(Motion.settle) { folio.addWorks([ui]) }
                    } else {
                        failed += 1
                    }
                    withAnimation(Motion.settle) { importingWorks -= 1 }
                }
                importingWorks = 0
                if failed > 0 { fail("โหลดรูปไม่สำเร็จ \(failed) รูป ลองเลือกใหม่อีกครั้ง") }
                else { Haptics.impact(.medium) }
            }
        }
        .onChange(of: videoPicks) { _, items in
            guard !items.isEmpty else { return }
            importingVideos = items.count
            videoPicks = []
            Task { @MainActor in
                var tooBig = 0, failed = 0
                for item in items {
                    if let movie = try? await item.loadTransferable(type: PickedMovie.self) {
                        switch await folio.addVideo(from: movie.url) {
                        case .added:   break
                        case .tooBig:  tooBig += 1
                        case .failed:  failed += 1
                        }
                    } else {
                        failed += 1
                    }
                    withAnimation(Motion.settle) { importingVideos -= 1 }
                }
                importingVideos = 0
                if tooBig > 0 {
                    fail("วิดีโอใหญ่เกิน \(Portfolio.videoMaxMB) MB — ตัดให้สั้นลงแล้วลองใหม่")
                } else if failed > 0 {
                    fail("โหลดวิดีโอไม่สำเร็จ ลองเลือกใหม่อีกครั้ง")
                } else {
                    Haptics.impact(.medium)
                }
            }
        }
        .confirmationDialog(deleteTitle, isPresented: Binding(get: { pendingDelete != nil },
                                                              set: { if !$0 { pendingDelete = nil } }),
                            titleVisibility: .visible) {
            Button("ลบ", role: .destructive) { remove() }
            Button("ยกเลิก", role: .cancel) { pendingDelete = nil }
        }
        .fullScreenCover(item: $playing) { v in
            VideoSheet(url: v.file) { playing = nil }
        }
    }

    // MARK: รูปโปรไฟล์

    private var avatar: some View {
        Button {
            Haptics.impact(.light)
            avatarMenu = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    // รูปเดียวกับบัตร STAR ในหน้าก่อน — ยังไม่ตั้งรูปเองก็เห็นรูปที่การ์ดใช้อยู่ ไม่ใช่วงกลมว่าง
                    photos.avatar().aspectRatio(contentMode: .fill)
                }
                .frame(width: 108, height: 108)
                .overlay { if busy.contains("avatar") { LoadingVeil() } }
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.12), radius: 14, y: 6)

                PIcon(.camera, size: 16, weight: .fill)
                    .foregroundStyle(PK.onInk)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(PK.ink))
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                    .offset(x: 2, y: 2)
            }
        }
        .buttonStyle(DockPress())
        .accessibilityLabel("เปลี่ยนรูปโปรไฟล์")
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    // MARK: ข้อความ

    private var textPanel: some View {
        PKPanel {
            VStack(alignment: .leading, spacing: 16) {
                PKField(label: "ชื่อผู้ใช้", text: p.binding(.name), placeholder: "ชื่อที่แสดงบนการ์ด",
                        limit: ProfileField.name.limit, id: "name", focus: $focus,
                        onCommit: { p.commit(TextSlotID(field: .name)) })
                PKField(label: "ลิงก์โปรไฟล์", text: handleBinding, placeholder: "yourname",
                        autocap: .never, noCorrect: true, limit: ProfileField.handle.limit,
                        leading: "\(ClipInvocation.host)/star/", id: "handle", focus: $focus,
                        onCommit: { p.commit(TextSlotID(field: .handle)) })
                PKField(label: "About Me", text: p.binding(.about), placeholder: "แนะนำตัวสั้น ๆ ให้แบรนด์รู้จัก",
                        paragraph: true, limit: ProfileField.about.limit, id: "about", focus: $focus,
                        onCommit: { p.commit(TextSlotID(field: .about)) })
            }
        }
    }

    /// ลิงก์ใช้ได้แค่ a–z 0–9 . _ — กรองตั้งแต่ตอนพิมพ์ ไม่ปล่อยให้พิมพ์ผิดแล้วค่อยด่า
    private var handleBinding: Binding<String> {
        let id = TextSlotID(field: .handle)
        return Binding(get: { p.raw(id) },
                       set: { v in
                           let clean = v.lowercased().filter { c in
                               c == "." || c == "_" || (c.isASCII && (c.isLetter || c.isNumber))
                           }
                           p.set(id, clean)
                       })
    }

    // MARK: รูปโปรไฟล์ครีเอเตอร์ — 3 ช่องคงที่

    private var creatorPanel: some View {
        PKPanel(title: "รูปโปรไฟล์ครีเอเตอร์", trailing: AnyView(count(folio.creatorImages.count, Portfolio.creatorSlots))) {
            HStack(spacing: 10) {
                ForEach(0..<Portfolio.creatorSlots, id: \.self) { i in
                    if let img = folio.creators[i] {
                        MediaTile(image: img, loading: busy.contains("c\(i)"),
                                  onTap: { creatorTarget = i; creatorPicking = true },
                                  onRemove: { pendingDelete = .creator(i) })
                    } else {
                        Button {
                            Haptics.impact(.light)
                            creatorTarget = i
                            creatorPicking = true
                        } label: {
                            AddTile(label: "รูปที่ \(i + 1)")
                                .overlay { if busy.contains("c\(i)") { LoadingVeil().clipShape(PK.shape(16)) } }
                        }
                        .buttonStyle(DockPress())
                    }
                }
            }
        }
    }

    // MARK: รูปผลงาน

    private var worksPanel: some View {
        let left = Portfolio.workMax - folio.works.count - importingWorks
        return PKPanel(title: "รูปผลงาน", trailing: AnyView(count(folio.works.count, Portfolio.workMax))) {
            LazyVGrid(columns: grid, spacing: 10) {
                ForEach(folio.works) { w in
                    MediaTile(image: w.image, loading: busy.contains("w\(w.id)"),
                              onTap: { workTarget = w.id; workPicking = true },
                              onRemove: { pendingDelete = .work(w.id) })
                }
                ForEach(0..<max(0, importingWorks), id: \.self) { _ in PendingTile() }
                if left > 0 {
                    PhotosPicker(selection: $workPicks, maxSelectionCount: left, matching: .images) {
                        AddTile(label: "เพิ่มรูป")
                    }
                    .buttonStyle(DockPress())
                }
            }
        }
    }

    // MARK: วิดีโอผลงาน

    private var videosPanel: some View {
        let left = Portfolio.videoMax - folio.videos.count - importingVideos
        return PKPanel(title: "วิดีโอผลงาน", subtitle: "ไฟล์ละไม่เกิน \(Portfolio.videoMaxMB) MB", trailing: AnyView(count(folio.videos.count, Portfolio.videoMax))) {
            LazyVGrid(columns: grid, spacing: 10) {
                ForEach(folio.videos) { v in
                    MediaTile(image: v.thumb, duration: v.duration,
                              onTap: { playing = v },
                              onRemove: { pendingDelete = .video(v.id) })
                }
                ForEach(0..<max(0, importingVideos), id: \.self) { _ in PendingTile() }
                if left > 0 {
                    PhotosPicker(selection: $videoPicks, maxSelectionCount: left, matching: .videos) {
                        AddTile(label: "เพิ่มวิดีโอ")
                    }
                    .buttonStyle(DockPress())
                }
            }
        }
    }

    // MARK: ส่วนประกอบ

    private var grid: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 10), count: 3) }

    private func count(_ n: Int, _ max: Int) -> some View {
        Text("\(n)/\(max)").font(.sh(12, .bold)).monospacedDigit()
            .foregroundStyle(PK.hint)
    }

    private var deleteTitle: String {
        switch pendingDelete {
        case .video: return "ลบวิดีโอนี้?"
        default:     return "ลบรูปนี้?"
        }
    }

    private func remove() {
        guard let r = pendingDelete else { return }
        Haptics.impact(.medium)
        withAnimation(Motion.settle) {
            switch r {
            case .creator(let i): folio.clearCreator(at: i)
            case .work(let id):   folio.removeWork(id)
            case .video(let id):  folio.removeVideo(id)
            }
        }
        pendingDelete = nil
    }

    private func load(_ item: PhotosPickerItem?, key: String, _ done: @escaping (UIImage) -> Void) {
        guard let item else { return }
        busy.insert(key)
        Task { @MainActor in
            defer { busy.remove(key) }
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let ui = UIImage(data: data) else {
                fail("โหลดรูปไม่สำเร็จ ลองเลือกใหม่อีกครั้ง")
                return
            }
            withAnimation(Motion.settle) { done(ui) }
            Haptics.impact(.medium)
        }
    }

    private func fail(_ message: String) {
        Haptics.impact(.heavy)
        withAnimation(Motion.settle) { toast = message }
    }
}

// MARK: - ช่องรูป/วิดีโอ

/// รูปหนึ่งช่อง 3:4 — แตะ = เปลี่ยน (วิดีโอ = เล่น) · ✕ มุมขวาบน = ลบ
struct MediaTile: View {
    let image: UIImage
    var duration: Double? = nil
    /// กว้าง/สูง — หน้าแก้ไขโปรไฟล์ 3:4 · wizard รูปและผลงานใช้จัตุรัสให้สามหมวดอยู่ในจอเดียว
    var ratio: CGFloat = 3 / 4
    var loading = false
    let onTap: () -> Void
    let onRemove: () -> Void
    /// ปุ่มมุมเป็น "เปลี่ยน" แทน "ลบ" (เป็น STAR แล้ว — `StarFlow.keepsData`) · `onRemove` = เลือกไฟล์ใหม่มาแทน
    var swaps = false
    /// ปุ่มมุม ✕/⟳ — ช่อง "รูปของคุณ" ใน wizard ไม่มี (แตะช่องเพื่อเปลี่ยนรูป แบบ salehere-ios)
    var showsCorner = true

    var body: some View {
        Button {
            Haptics.impact(.light)
            onTap()
        } label: {
            Color.clear
                .aspectRatio(ratio, contentMode: .fit)
                .overlay {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
                }
                .overlay {
                    if duration != nil {
                        PlayGlyph()
                            .fill(.white)
                            .frame(width: 13, height: 15)
                            .offset(x: 1.5)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(.black.opacity(0.38)))
                            .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1))
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if let duration {
                        Text(Self.clock(duration))
                            .font(.sh(11, .bold)).monospacedDigit()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(.black.opacity(0.45)))
                            .padding(7)
                    }
                }
                .overlay { if loading { LoadingVeil() } }
                .clipShape(PK.shape(16))
                .overlay(PK.shape(16).strokeBorder(PK.line2, lineWidth: 1))
        }
        .buttonStyle(DockPress())
        .overlay(alignment: .topTrailing) {
            if showsCorner {
            Button(action: onRemove) {
                PIcon(swaps ? .arrowsClockwise : .x, size: swaps ? 12 : 11, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.black.opacity(0.55)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 1))
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(swaps ? "เปลี่ยน" : "ลบ")
            }
        }
    }

    static func clock(_ s: Double) -> String {
        let t = Int(s.rounded())
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}

/// ช่องที่กำลังโหลดของเข้า — ขนาดเท่าช่องจริง ของใหม่จึงขึ้นตรงที่เดิม ไม่ดันกริด
struct PendingTile: View {
    var ratio: CGFloat = 3 / 4
    var body: some View {
        Color.clear
            .aspectRatio(ratio, contentMode: .fit)
            .overlay { ProgressView().tint(PK.ink) }
            .background(PK.shape(16).fill(PK.fieldFill))
    }
}

/// ม่านหมุนทับรูปเดิมระหว่างโหลดรูปใหม่มาแทน
struct LoadingVeil: View {
    var body: some View {
        ZStack {
            Color.white.opacity(0.55)
            ProgressView().tint(PK.ink)
        }
    }
}

/// ช่องว่างสำหรับเพิ่ม — เส้นประ ไอคอนบวก ป้ายสั้น
struct AddTile: View {
    let label: String
    var ratio: CGFloat = 3 / 4
    /// หมวดนี้ยังขาดตอนกดถัดไป — เส้นประ + ไอคอนแดง (salehere-ios `WzMediaTiles`)
    var invalid = false

    var body: some View {
        Color.clear
            .aspectRatio(ratio, contentMode: .fit)
            .overlay {
                VStack(spacing: 6) {
                    PIcon(.plus, size: 18, weight: .bold)
                        .foregroundStyle(invalid ? PK.red : PK.ink.opacity(0.7))
                    Text(label).font(.sh(11.5, .semibold)).foregroundStyle(invalid ? PK.red : PK.muted)
                        .lineLimit(1)
                }
            }
            .background(PK.shape(16).fill(PK.fieldFill))
        .overlay(PK.shape(16).strokeBorder(invalid ? PK.red : PK.line2, style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])))
        .contentShape(PK.shape(16))
    }
}

/// สามเหลี่ยมเล่น — ชุด Phosphor ในแพ็กเกจไม่มี `play` และหน้าเดียวไม่คุ้มเพิ่มไอคอนสามน้ำหนัก
struct PlayGlyph: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// เล่นวิดีโอผลงานเต็มจอ
struct VideoSheet: View {
    let url: URL
    let onClose: () -> Void
    @State private var player: AVPlayer?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player).ignoresSafeArea()
            }
            PKCircleButton(symbol: .x, label: "ปิด", action: onClose)
                .padding(.leading, 20)
                .padding(.top, 6)
        }
        .onAppear {
            let p = AVPlayer(url: url)
            player = p
            p.play()
        }
        .onDisappear { player?.pause() }
    }
}

// MARK: - ถ่ายรูปโปรไฟล์

/// กล้องของระบบ พร้อมขั้นครอปสี่เหลี่ยมจัตุรัส — รูปจากกล้องไม่ได้จัดเฟรมมาสำหรับวงกลม
private struct CameraPicker: UIViewControllerRepresentable {
    let onPick: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let c = UIImagePickerController()
        c.sourceType = .camera
        c.cameraDevice = .front
        c.allowsEditing = true
        c.delegate = context.coordinator
        return c
    }

    func updateUIViewController(_ c: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ p: CameraPicker) { parent = p }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = (info[.editedImage] ?? info[.originalImage]) as? UIImage { parent.onPick(img) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
