import SwiftUI

/// รากของแอป — แอป Sale Here จำลอง (สองแท็บ) ครอบ Star Card ไว้ ตาม flow เดิมของแอปหลัก 22 ก.ย. 2569
///
/// โปรไฟล์ → "โปรไฟล์ครีเอเตอร์" → Star Profile (flow ใหม่) → "แต่ง Star Card" → `StarCardSpace` (hub → คลัง → ห้องแต่ง)
/// คลิปและโต๊ะ lab ยังเปิดตรงเหมือนเดิม ไม่ผ่านแอปจำลอง
struct ContentView: View {
    @State private var photos = PhotoStore()
    @State private var invocation = ClipInvocation()

    var body: some View {
        Group {
            if EditorialLab.on {
                EditorialLab()
            } else if AppRuntime.isClip {
                // คลิปเปิดการ์ดของคนอื่นจากลิงก์ — ไม่ผ่านคลังหรือหน้าเทมเพลตของเจ้าของเครื่อง
                CardScreen(viewOnly: true)
            } else {
                SaleHereShell()
            }
        }
        .environment(photos)
        .environment(invocation)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            invocation.consume(activity)
        }
        .onOpenURL { url in
            invocation.consume(url)
        }
        .task {
            LabSync.shared.start(photos: photos)
            invocation.consumeLaunchURL()
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-exportDesignedTemplates") {
                await TemplateThumbs.shared.exportDesigned(photos: photos)
            }
            // เมทริกซ์ widget ทุกชนิด × ทุกตัวเลือก → PNG (เทียบพิกเซลกับ Android · ดู `WidgetMatrixExport`)
            if ProcessInfo.processInfo.arguments.contains("-exportWidgetMatrix") {
                await WidgetMatrixExport.run(photos: photos)
            }
            #endif
        }
    }
}

/// พื้นที่ Star Card ทั้งชุด — เข้าที่ hub "ข้อมูลของฉัน" ก่อนเสมอ (ประตูจากปุ่ม "โปรไฟล์ครีเอเตอร์")
/// แล้วค่อยไปคลังการ์ด / หน้าเทมเพลต / ห้องแต่ง
/// เปิดพื้นที่ Star Card ที่ไหน — คลังการ์ดฝังอยู่ในหน้า Star Profile แล้ว (toggle ข้อมูล | การ์ด)
/// พื้นที่นี้จึงถูกเรียกเพื่อ "ทำอะไรกับใบหนึ่ง" เป็นหลัก
enum StarCardIntent: Identifiable, Equatable {
    case gallery
    case edit(String)
    case create
    case preview(String)
    var id: String {
        switch self {
        case .gallery: return "gallery"
        case .edit(let id): return "edit-" + id
        case .create: return "create"
        case .preview(let id): return "preview-" + id
        }
    }
}

struct StarCardSpace: View {
    var intent: StarCardIntent = .gallery
    /// ปิดทั้งพื้นที่กลับไปแอป Sale Here จำลอง
    let onExit: () -> Void
    /// คลังโฟกัสใบไหน — shell เปลี่ยนสีดวงไฟตาม
    var onFocusTheme: ((CardTheme) -> Void)? = nil
    /// คลังการ์ดกำลังเป็นหน้าที่เห็นอยู่ไหม (ไม่ใช่เทมเพลต/ห้องแต่ง/มุมมองแบรนด์) — shell โชว์หัวร่วมเฉพาะตอนนั้น
    var onGalleryVisible: ((Bool) -> Void)? = nil

    @Environment(PhotoStore.self) private var photos
    @Environment(ClipInvocation.self) private var invocation
    @State private var flow = StarFlow.shared

    /// hub "ข้อมูลของฉัน" เลิกเป็นประตูแล้ว (ผู้ใช้ 23 ก.ย. 2569: "หน้านี้ไม่ต้องมีแล้ว ใช้ Star Profile") — เข้าคลังทันที
    @State private var atEntry = false
    /// การ์ดที่กำลังแต่งอยู่ — nil = ยังอยู่ชั้นเลือก (คลัง/เทมเพลต)
    @State private var editingCardID: String?
    /// ใบที่กำลังแต่งเพิ่งเกิดจากการแตะเทมเพลต — ออกโดยไม่แตะแก้อะไร = ทิ้งใบนั้น
    @State private var freshFromTemplate = false
    /// เปิดหน้าเทมเพลตทับคลัง — จากปุ่ม + (คลังว่างไม่ต้องพึ่งสวิตช์นี้ ไปหน้าเทมเพลตเองอยู่แล้ว)
    @State private var showPicker = false
    /// แบบล่าสุดที่เลือกในหน้าเทมเพลต — จำไว้ให้สวิตช์เปิดค้างแบบเดิมรอบหน้า
    @State private var lastFormat: CardFormat = .portfolio
    /// ใบที่กำลังเปิดดู "แบบที่แบรนด์เห็น" ทับคลัง — nil = ไม่ได้เปิด
    @State private var brandPreviewID: String?
    /// แตะการ์ดเข้าห้องแต่งไปแล้วในรอบนี้ — กลับมาคลังต้องเจอใบที่เพิ่งแก้ ไม่ใช่ใบที่กำลังแสดง
    @State private var editedHere = false
    private var openedAtGallery: Bool { if case .gallery = intent { return true } else { return false } }
    /// หน้า "ข้อมูลของฉัน" ทับทุกอย่าง — ข้อมูลตั้งต้นของทุกการ์ด เปิดได้จากคลังและหน้าเทมเพลต
    @State private var showProfile = false
    /// นับครั้งที่กลับเข้าคลังการ์ด — คลังเห็นค่านี้เปลี่ยนแล้วเล่นท่าเข้าฉากใหม่
    @State private var galleryEntry = 0

    var body: some View {
        Group {
            if atEntry {
                // ประตูเข้า — hub ก่อน ปิดจากตรงนี้ = ออกจาก Star Card ทั้งชุด
                ProfileFlow(onClose: onExit, onMyCards: enterGallery)
                    .transition(.opacity)
            } else if let cardID = editingCardID {
                // `id` ผูกกับใบ — เปิดคนละใบต้องได้ `CardScreen` ใหม่จริง ๆ
                // ไม่งั้น `@State pages` ของใบเดิมค้างอยู่ (ค่าตั้งต้นของ State ใช้แค่ตอนสร้างครั้งแรก)
                CardScreen(cardID: cardID, discardIfUntouched: freshFromTemplate,
                           onChangeFormat: {
                    withAnimation(Motion.settle) {
                        editingCardID = nil
                        showPicker = false
                    }
                })
                // เปิดมาเพื่อแต่งใบเดียวจาก Star Profile — ออกจากห้องแต่ง = กลับไปหน้านั้นเลย ไม่แวะคลังซ้ำ
                .onDisappear { if case .edit = intent, editingCardID == nil { onExit() } }
                .id(cardID)
                .transition(.opacity)
            } else if showPicker || CardLibrary.shared.isEmpty {
                // คลังว่าง = ยังไม่มีอะไรให้ดู พาไปเริ่มจากเทมเพลตเลย (หน้านี้คือหน้าแรกของมือใหม่)
                TemplatePicker(
                    initialFormat: lastFormat,
                    onPick: { pickedFormat, picked in
                        lastFormat = pickedFormat
                        let record = CardLibrary.shared.create(from: picked)
                        freshFromTemplate = true
                        editedHere = true
                        withAnimation(Motion.settle) { editingCardID = record.id }
                    },
                    onBlank: { pickedFormat in
                        lastFormat = pickedFormat
                        let record = CardLibrary.shared.createBlank(format: pickedFormat)
                        freshFromTemplate = true
                        editedHere = true
                        withAnimation(Motion.settle) { editingCardID = record.id }
                    },
                    // คลังว่าง = ไม่มีคลังให้กลับ → ปิดกลับ Star Profile
                    onBack: CardLibrary.shared.isEmpty ? onExit : {
                        withAnimation(Motion.settle) { showPicker = false }
                    }
                )
                .transition(.opacity)
            } else {
                CardGallery(
                    onCreate: { withAnimation(Motion.settle) { showPicker = true } },
                    onOpen: { record in
                        freshFromTemplate = false
                        editedHere = true
                        withAnimation(Motion.settle) { editingCardID = record.id }
                    },
                    onPreview: { record in brandPreviewID = record.id },
                    // ป้าย "Star Profile" ในหัวคลัง = กลับหน้า Star Profile (หน้าเดียวที่เก็บข้อมูลตั้งต้นของทุกใบ)
                    onProfile: onExit,
                    entryToken: galleryEntry,
                    sharedStage: true, onFocusTheme: onFocusTheme,
                    startAtLive: openedAtGallery && !editedHere
                )
                .transition(.opacity)
                // หน้าดูแบบที่แบรนด์เห็น — หน้าเดียวกับที่ลิงก์/คลิปเปิด แค่มีปุ่มปิดกลับคลัง
                .fullScreenCover(isPresented: Binding(
                    get: { brandPreviewID != nil },
                    set: { if !$0 { brandPreviewID = nil } }
                )) {
                    if let id = brandPreviewID {
                        CardScreen(viewOnly: true, cardID: id, onClose: { brandPreviewID = nil })
                            .id(id)
                            .environment(photos)
                            .environment(invocation)
                    }
                }
            }
        }
        .onChange(of: galleryVisible, initial: true) { _, v in onGalleryVisible?(v) }
        // ตั้งฉากจาก Lab ระหว่างอยู่ในห้องแต่ง (การ์ดเพิ่งมี) → เติมข้อมูลตัวอย่างให้การ์ดทันที ไม่ใช่ค้าง "ยังไม่ใส่ช่องทาง"
        .onChange(of: flow.have) { _, _ in syncCardData() }
        .onAppear {
            syncCardData()
            switch intent {
            case .gallery: break
            case .edit(let id): freshFromTemplate = false; editingCardID = id
            case .create: showPicker = true
            case .preview(let id): brandPreviewID = id
            }
        }
        // ตู้ widget ขอไปดูงาน → ปิดพื้นที่การ์ดกลับแอปจำลอง (shell สลับแท็บให้)
        .onChange(of: flow.jobsRequested) { _, on in if on { onExit() } }
    }

    private var galleryVisible: Bool {
        !atEntry && editingCardID == nil && !showPicker && !CardLibrary.shared.isEmpty && brandPreviewID == nil
    }

    /// การ์ดอ่านจาก `Profile.me` ซึ่งรับคำตอบมาจาก Star Profile ทุกครั้งที่ `StarFlow` บันทึก (ดู `Profile.sync(from:)`) —
    /// เรียกซ้ำตอนเปิดพื้นที่การ์ดเผื่อกรณีที่ยังไม่เคยบันทึก · **ห้าม** เติมข้อมูลตัวอย่างที่นี่:
    /// เคยเรียก `fillSample()` แล้วการ์ดโชว์แนะนำตัว/สายงาน/เบอร์ของตัวอย่างทั้งที่ผู้ใช้ยังไม่ได้กรอก (30 ก.ย. 2569)
    private func syncCardData() {
        Profile.me.sync(from: StarFlow.shared)
    }

    /// กลับเข้าคลังการ์ด — ปลุกท่าเข้าฉากของคลังให้เล่นใหม่ตอนหน้าโปรไฟล์เลื่อนพ้นจอ
    ///
    /// รอให้ของระบบเลื่อนไปก่อน ไม่งั้นสำรับจะคลี่ตัวอยู่หลังหน้าที่ยังบังอยู่ แล้วไม่มีใครเห็น
    private func enterGallery() {
        showProfile = false
        editingCardID = nil
        showPicker = false
        if atEntry {
            withAnimation(Motion.settle) { atEntry = false }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            galleryEntry += 1
        }
    }
}

#Preview {
    ContentView()
}


/// ท่าเข้า/ออกของหน้า Star Card ทับหน้าโปรไฟล์ — ไหลจากขวา 72pt พร้อมจางและขยายเข้าที่ (ไม่ใช่เลื่อนเต็มจอแบบ push)
///
/// ระยะสั้นกับการจางทำให้ toggle สองตัวที่อยู่ตำแหน่งเดียวกันบนสองหน้าอ่านเป็น "ตัวเดียวกันเปลี่ยนสี"
/// แทนที่จะเป็นหน้าใหม่ทั้งหน้าดันเข้ามา
struct PageSlide: ViewModifier {
    let progress: CGFloat
    func body(content: Content) -> some View {
        content
            .offset(x: (1 - progress) * 72)
            .opacity(Double(progress))
            .scaleEffect(0.97 + 0.03 * progress)
    }
}
