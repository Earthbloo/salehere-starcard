import SwiftUI

struct CardScreen: View {
    /// คลิปเปิดมาดูอย่างเดียว — ห้ามเข้าโหมดแต่ง / ตู้ widget / ลากวาง
    var viewOnly = false

    @State private var pages: [CardPage] = Mock.starterPages
    @State private var theme = CardTheme()
    @State private var showHire = false

    /// โหมดแต่ง + ชีตควบคุมล่าง — เปิดจากปุ่ม "แต่ง" ซ้ายบนเท่านั้น
    /// ทางอื่น (ปุ่ม + / ลาก widget) ห้ามเด้งชีตนี้เอง
    @State private var isEditing = false
    /// ตู้ widget — เปิดจากปุ่ม + ขวาบน
    @State private var showGallery = false
    @State private var selected: UUID?
    @State private var sheetDetent: PresentationDetent = SheetStop.normal

    /// หน้าที่กำลังดูอยู่
    @State private var index = 0
    /// ความคืบหน้าของการปัด -1…1 · ขับ crossfade เอง ไม่ใช้ ScrollView เพราะ ScrollView สไลด์เสมอ
    @State private var swipe: CGFloat = 0

    /// ผังที่แคชไว้ของหน้าปัจจุบัน — ห้าม solve ใหม่ทุก touch event
    @State private var placed: [Placed] = []
    /// `placed` เป็นผังของหน้าไหน — ตัวกันไม่ให้หน้าใหม่ถูกวาดด้วยผังของหน้าเก่า
    @State private var placedPage: UUID? = nil
    @State private var pageSize: CGSize = .zero
    /// ความกว้างจอ — ใช้ล็อกความกว้างแผงล่าง ไม่ให้เนื้อหาข้างในดันจนล้นจอ
    @State private var viewportW: CGFloat = 402

    // การลาก
    @State private var dragID: UUID?
    @State private var dragStart: CGRect = .zero
    @State private var dragTranslation: CGSize = .zero
    @State private var baseline: [Placed] = []
    @State private var pendingIndex: Int?
    @State private var dwell: DispatchWorkItem?
    /// ตัวจับเวลาตอนลากค้างที่ขอบหน้า — ครบเวลาแล้วพา widget ข้ามหน้า
    @State private var edgeFlip: DispatchWorkItem?
    /// ตำแหน่งนิ้วภายใน widget ตอนเริ่มลาก — ใช้คำนวณนิ้วจริงบนหน้า
    /// (เช็คจากจุดกลาง widget ไม่ได้ เพราะตัวกว้างเต็มหน้าจุดกลางไปไม่ถึงขอบ)
    @State private var dragGripX: CGFloat = 0
    /// ความสูงจอ — ใช้คำนวณสเกลแคนวาสตอนแต่ง
    @State private var viewportH: CGFloat = 874

    /// สเกลของแคนวาสตอนแต่ง — ย่อ "พอให้ทำงานได้" ไม่ใช่ย่อจนพ้นชีตทุกมิลลิเมตร
    ///
    /// สูตรเดิมบังคับให้ทั้งใบลอยเหนือชีต การ์ดเลยเหลือ ~0.67 ซึ่งเล็กเกินกว่าจะแต่งถนัด
    /// ตอนนี้ตั้งเพดานการย่อไว้ที่ 0.82 — ท้ายการ์ดโดนชีตบังบ้างก็ยอม
    /// เพราะดันชีตลงเป็นแถบเตี้ยได้ทุกเมื่อ (แล้วการ์ดกลับมาเต็มขนาดเอง)
    private var editScale: CGFloat {
        let sheetH: CGFloat = sheetDetent == SheetStop.compact ? 84 : 268
        let fit = (viewportH - sheetH - 74 - 8) / max(pageSize.height, 1)
        // ชีตหุบแล้วแทบไม่บังอะไร — ปล่อยเต็มขนาดไปเลย ไม่ต้องย่อให้เสียอารมณ์
        return fit > 0.9 ? 1 : min(1, max(0.82, fit))
    }
    /// สเกลของแคนวาสตอนนี้ — ใช้ทั้งวาดและแปลงระยะนิ้วเป็นพิกัดหน้า
    private var canvasScale: CGFloat { isEditing ? editScale : 1 }
    /// สำเนา widget ที่กำลังลาก — ใช้วาดชั้นลอยที่ระดับ deck ให้อยู่รอดข้ามการสลับหน้า
    @State private var dragItem: WidgetInstance?
    /// ตำแหน่งบ้านเดิมของตัวที่ลาก — ไว้เด้งกลับเมื่อวางในที่ที่วางไม่ได้
    @State private var dragOriginPage = 0
    @State private var dragOriginIndex = 0
    @State private var lifted = false
    /// จุดที่นิ้วแตะบน widget ตัวที่กำลังกด — ขับการเอียง 3 มิติ
    @State private var pressPoint: (id: UUID, at: CGPoint)?
    /// ให้กรอบเลือกไหลจาก widget เดิมไปตัวใหม่ แทนที่จะกระพริบหายแล้วโผล่
    @Namespace private var selectionNS

    // การปรับขนาด
    @State private var resizeID: UUID?
    @State private var resizeCols = 0
    @State private var resizeRows = 0

    private var current: CardPage? { pages.indices.contains(index) ? pages[index] : nil }
    private var selectedItem: WidgetInstance? {
        pages.flatMap(\.items).first { $0.id == selected }
    }

    var body: some View {
        GeometryReader { geo in
            // หน้าเต็มจอ — ไม่บังคับอัตราส่วนแล้ว เหลือแค่เว้นแถบบนกับพื้นที่จุดบอกหน้า
            let size = CGSize(width: geo.size.width,
                              height: geo.size.height - 74 - 34)

            ZStack {
                CardBackdrop(theme: theme)

                Group {
                    if isEditing {
                        CanvasGrid(theme: theme, ink: theme.inkStyle, page: size, top: 74)
                            .ignoresSafeArea()
                    }
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 74)
                        deck(size: size, viewport: geo.size)
                        Color.clear.frame(height: 34)
                    }
                }
                // โหมดแต่ง: ย่อแคนวาสแค่พอพ้นชีต ณ ระดับปัจจุบัน — ชีตหุบการ์ดเกือบเต็ม
                // ดึงชีตขึ้นเมื่อไหร่ค่อยหลบเพิ่ม ไม่ย่อทิ้งขว้างจนการ์ดจิ๋ว
                .scaleEffect(canvasScale, anchor: .top)

                topBar
                pageRail
            }
            .animation(Motion.settle, value: sheetDetent)
            .onAppear { viewportH = geo.size.height }
            .onChange(of: geo.size.height) { _, h in viewportH = h }
            .onAppear { pageSize = size; viewportW = geo.size.width; resolve() }
            .onChange(of: size) { _, s in pageSize = s; resolve() }
            .onChange(of: geo.size.width) { _, w in viewportW = w }
            .onChange(of: index) { _, _ in
                // เปลี่ยนหน้าเพราะลาก widget ข้ามหน้า — ตัวที่ลากยังต้องถูกเลือกอยู่
                if dragID == nil { selected = nil }
                resolve()
            }
            .onChange(of: pages) { _, _ in
                withAnimation(Motion.flow) { resolve() }
            }
            .animation(Motion.settle, value: isEditing)
        }
        // ให้ระบบรู้ว่าพื้นสว่างหรือมืด — แถบสถานะกับ affordance ของ OS จะได้อ่านออก
        .preferredColorScheme(theme.activeInk.isLight ? .light : .dark)
        .sheet(isPresented: Binding(get: { isEditing }, set: { if !$0 { isEditing = false } })) {
            VStack(spacing: 0) {
                // แถบเลือกสีอยู่นอก ScrollView — ถ้าอยู่ข้างใน ScrollView จะกินการลากจนเลื่อนไม่ได้
                if selectedItem == nil {
                    HStack(spacing: 10) {
                        SpectrumPicker(hue: theme.customHue ?? theme.palette.backdropHue,
                                       sat: theme.customSat ?? 0.55) { h, s in
                            theme.customHue = h
                            theme.customSat = s
                        }
                        // ปุ่มนี้อยู่คู่แถบเลือกสี = อยู่ในบริบท "ฉากหลังของการ์ด"
                        // ของเดิมเป็น `PhotoUploadButton` ซึ่งยัดรูปเข้าคลังรวมของ PhotoStore
                        // แล้วรูปนั้นไปแทนภาพใน widget ทุกช่องแทนที่จะเป็นพื้นหลัง — คนละเรื่องกับที่ตาคาด
                        // (รูปของ widget แต่ละช่องมีปุ่มของตัวเองอยู่บนรูปนั้น ๆ ในโหมดแต่งอยู่แล้ว)
                        // เลือกรูปแล้วต้องถอยได้ — ไม่งั้นทางเดียวที่จะเอารูปออกคือ
                        // ไปกดฉากหลังแบบอื่น ซึ่งไม่ใช่คำว่า "ยกเลิก" ในหัวคน
                        if photos.background != nil {
                            Button {
                                withAnimation(Motion.flow) {
                                    photos.clearBackground()
                                    theme.backdrop = .gradient
                                    // คืนสีธีมที่ดูดมาจากรูปด้วย — ยกเลิกต้องยกเลิกทั้งผล
                                    theme.customHue = nil
                                    theme.customSat = nil
                                }
                                Haptics.impact(.medium)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.sh(10, .bold))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(Color.white.opacity(0.14)))
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                            .accessibilityLabel("เอารูปพื้นหลังออก")
                        }
                        BackgroundPickButton(theme: theme.toolTheme, compact: true) { tone in
                            withAnimation(Motion.flow) {
                                theme.backdrop = .photo
                                theme.customHue = tone?.hue
                                theme.customSat = tone?.saturation
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if let sel = selectedItem {
                            widgetPanel(sel)
                            variantPicker(sel)
                        } else {
                            themePanel
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, selectedItem == nil ? 12 : 16)
                    .padding(.bottom, 28)
                }
            }
            .environment(photos)
            .presentationDetents([SheetStop.compact, SheetStop.normal, .large], selection: $sheetDetent)
            .presentationDragIndicator(.visible)
            // แผงควบคุมต้องทึมมืดสม่ำเสมอ — ห้ามเอาฉากหลัง/รูป wallpaper ของการ์ดมาปน
            // เครื่องมือมืดเสมอ ไม่ว่าการ์ดจะใช้หมึกอะไร — ตาต้องแยกออกทันทีว่า
            // อะไรคือ "ชิ้นงานที่กำลังออกแบบ" อะไรคือ "ปุ่มที่ใช้ออกแบบมัน"
            // (แบบเดียวกับแคนวาสขาวบนหน้าจอมืดของ Figma)
            .environment(\.colorScheme, .dark)
            .presentationBackground {
                // `.ultraThinMaterial` อ่าน colorScheme ของ presentation ซึ่งตอนนี้ล้อหมึกของการ์ด
                // พอเลือกกระดาษ ชีตจะพลิกเป็นแผ่นขาว แล้วปุ่มทั้งแผงที่เขียนด้วยสีขาวหายไปกับพื้น
                // ความมืดของเครื่องมือจึงต้องทาเอง ไม่ฝากไว้กับ colorScheme
                Rectangle().fill(.ultraThinMaterial)
                    .overlay(Color(white: 0.07).opacity(theme.activeInk.isLight ? 0.86 : 0))
            }
            // ต้องแตะ/ลาก widget บนการ์ดได้ทั้งที่ชีตยังเปิดอยู่ ไม่งั้นแก้งานไม่ได้เลย
            .presentationBackgroundInteraction(.enabled(upThrough: SheetStop.normal))
            .interactiveDismissDisabled()
            // ตู้ widget ตอนอยู่ในโหมดแต่ง — ต้องซ้อนบนชีตแต่งที่เปิดค้างอยู่
            // เป็น sheet พี่น้องกันไม่ได้ ระบบจะยอมโชว์ได้ทีละใบ ตู้จะไม่มีวันขึ้น
            .sheet(isPresented: Binding(get: { showGallery && isEditing },
                                        set: { if !$0 { showGallery = false } })) {
                gallerySheet
            }
        }
        // ตู้ widget ตอนอยู่โหมดดู — ไม่มีชีตแต่งบัง เปิดตรงจาก root ได้เลย
        // แยกสองจุดเพราะจุด presentation ต้องอยู่บน view ที่กำลังโชว์อยู่จริง
        .sheet(isPresented: Binding(get: { showGallery && !isEditing },
                                    set: { if !$0 { showGallery = false } })) {
            gallerySheet
        }
        .alert("ส่งคำขอแล้ว", isPresented: $showHire) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("ในคลิปนี้ยังเป็น mock — ของจริงจะพาไป inbox ของ @\(invocation.slug)")
        }
    }

    private var gallerySheet: some View {
        ScrollView(showsIndicators: false) {
            WidgetGallery(theme: theme.toolTheme, onAdd: { kind in
                addWidget(kind)
                showGallery = false
            }, onClose: { showGallery = false })
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .environment(photos)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        // ตู้ widget ก็ทึมมืดเช่นกัน — พรีวิวข้างในต้องเด่นกว่าฉากหลัง
        // เครื่องมือมืดเสมอ ไม่ว่าการ์ดจะใช้หมึกอะไร — ตาต้องแยกออกทันทีว่า
            // อะไรคือ "ชิ้นงานที่กำลังออกแบบ" อะไรคือ "ปุ่มที่ใช้ออกแบบมัน"
            // (แบบเดียวกับแคนวาสขาวบนหน้าจอมืดของ Figma)
            .environment(\.colorScheme, .dark)
            .presentationBackground {
                // `.ultraThinMaterial` อ่าน colorScheme ของ presentation ซึ่งตอนนี้ล้อหมึกของการ์ด
                // พอเลือกกระดาษ ชีตจะพลิกเป็นแผ่นขาว แล้วปุ่มทั้งแผงที่เขียนด้วยสีขาวหายไปกับพื้น
                // ความมืดของเครื่องมือจึงต้องทาเอง ไม่ฝากไว้กับ colorScheme
                Rectangle().fill(.ultraThinMaterial)
                    .overlay(Color(white: 0.07).opacity(theme.activeInk.isLight ? 0.86 : 0))
            }
    }

    @Environment(PhotoStore.self) private var photos
    @Environment(ClipInvocation.self) private var invocation

    // MARK: - Deck

    /// เพจเจอร์แบบเลื่อนภาพ — ดันซ้ายขวาเต็มความกว้าง ไม่มีการจางหาย
    ///
    /// ตัวที่ทำให้ไม่ใช่แค่ "สไลด์ธรรมดา" คือ **พารัลแลกซ์ในหน้า**:
    /// widget ข้างในเลื่อนช้ากว่าตัวหน้าเล็กน้อย และตัวที่กินเต็มความกว้างเลื่อนช้ากว่าตัวแคบ
    /// สมองจึงอ่านว่าเป็นชั้นลึกซ้อนกัน ไม่ใช่ภาพแบนแผ่นเดียวที่ถูกดันไปมา
    private func deck(size: CGSize, viewport: CGSize) -> some View {
        ZStack {
            ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                let d = CGFloat(i) - (CGFloat(index) + swipe)
                // ระหว่างลากข้ามหน้า ต้องคงทุกหน้าไว้ในต้นไม้ view — ถ้าหน้าต้นทางถูกถอด
                // gesture recognizer ที่ถือการลากอยู่จะตายไปด้วย แล้วจะไม่มีวันได้ event ปล่อยนิ้ว
                if abs(d) < 1.35 || dragID != nil {
                    // `current` = หน้านี้คือหน้าปัจจุบัน (ใช้คุมการเข้าฉาก — ห้ามผูกกับ swipe)
                    // `interactive` = รับ touch ได้ (ปิดระหว่างปัด กันไปโดน widget)
                    sheet(page, size: size,
                          current: i == index,
                          // ระยะหน้า — ตัวขับท่าเข้า/ออกของทุก widget ให้สครับตามนิ้ว
                          dist: d,
                          interactive: i == index && abs(swipe) < 0.02,
                          // พารัลแลกซ์ต้องเป็นศูนย์ทั้งตอนอยู่กลางจอและตอนออกไปสุด
                          // ถ้าค้างค่าไว้ที่ปลาย หน้าที่ออกไปแล้วจะเลื่อนไม่พ้นจอ เหลือเศษค้างขอบ
                          parallax: d * max(0, 1 - abs(d)))
                        // บีบแนวนอนนิดหน่อยตอนถูกดันออก ให้รู้สึกว่ามีแรง ไม่ใช่แผ่นแข็ง
                        // (เคยเอียงหน้า 3 มิติด้วย แต่ 3D transform ทำให้ Liquid Glass
                        //  หยุด sample พื้นหลังแล้วตกเป็นแผ่นเข้มทั้งหน้าตลอดการปัด — ตัดทิ้ง)
                        .scaleEffect(x: 1 - abs(d) * 0.05, y: 1 - abs(d) * 0.08)
                        .offset(x: d * (size.width + 26))
                        .zIndex(Double(-abs(d)))
                        .allowsHitTesting(i == index)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            // ชั้นลอยของตัวที่ลาก — อยู่ระดับ deck ไม่ผูกกับหน้าใดหน้าหนึ่ง จึงลอยข้ามหน้าได้
            if dragID != nil, let item = dragItem {
                dragLayer(Placed(item: item, frame: dragStart))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        // หมึกของการ์ดครอบทั้งสำรับ — ทั้ง widget · เปลือกแผ่น · เส้นเลือก
        // ไม่ครอบไปถึงแถบเครื่องมือกับชีตแต่ง เพราะนั่นคือ "เครื่องมือ" ไม่ใช่ "ชิ้นงาน"
        // (แคนวาสขาวบนหน้าจอมืดแบบ Figma — ตาจะแยกออกทันทีว่าอะไรคืองาน อะไรคือปุ่ม)
        .environment(\.cardInk, theme.inkStyle)
        .simultaneousGesture(pageSwipe(width: size.width))
        .onTapGesture { if isEditing { select(nil) } }
    }

    private func pageSwipe(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { g in
                guard dragID == nil, resizeID == nil else { return }
                guard abs(g.translation.width) > abs(g.translation.height) else { return }
                // หักระยะ dead zone ออก ไม่งั้นพอ gesture ติดครั้งแรกหน้าจะกระโดดไป 12pt ทันที
                let raw = -g.translation.width
                let dead: CGFloat = 12
                let adjusted = raw > 0 ? max(0, raw - dead) : min(0, raw + dead)
                var p = adjusted / max(width, 1)
                // หน่วงยางที่หน้าแรกและหน้าสุดท้าย
                if (index == 0 && p < 0) || (index == pages.count - 1 && p > 0) { p *= 0.32 }
                swipe = max(-1, min(1, p))
            }
            .onEnded { g in
                guard dragID == nil, resizeID == nil else { swipe = 0; return }
                let velocity = -g.predictedEndTranslation.width / max(width, 1)
                let target = (swipe > 0.28 || velocity > 0.75) ? index + 1
                           : (swipe < -0.28 || velocity < -0.75) ? index - 1
                           : index
                let next = max(0, min(pages.count - 1, target))
                if next != index { Haptics.impact(.light) }
                withAnimation(Motion.page) {
                    index = next
                    swipe = 0
                }
            }
    }

    /// ขอบเขต A4 — ในโหมดดูไม่มีพื้นหลังของตัวเอง ทุกหน้าจึงลอยอยู่บนฉากหลังผืนเดียวกัน
    /// ถ้าใส่พื้นหลังให้แต่ละหน้า มันจะอ่านออกมาเป็น "แผ่นกระดาษหลายแผ่น" แทนที่จะเป็นงานชิ้นเดียว
    private func sheet(_ page: CardPage, size: CGSize, current: Bool, dist: CGFloat, interactive: Bool, parallax: CGFloat) -> some View {
        // `placed` คือผังของหน้าปัจจุบันที่หน่วงไว้ใน state — มีไว้เพื่อให้ "จัดเรียงใหม่"
        // (ลาก widget สลับที่ · เพิ่ม/ลบ) ไหลตามสปริงได้ เพราะ `resolve()` ถูกเรียกใน withAnimation
        //
        // แต่ตอน **เปลี่ยนหน้า** state ตัวนี้ยังเป็นผังของหน้าเดิมอยู่หนึ่งรอบ (resolve() วิ่งใน
        // onChange ซึ่งมาทีหลัง body) ถ้าเผลอใช้ หน้าใหม่จะถูกวาดด้วย id ของ widget หน้าเก่า
        // แล้วพอ resolve() ตามมา ForEach จะเห็น id เปลี่ยนยกชุด → SwiftUI รื้อ tile ทิ้งทั้งหน้า
        // → ท่าที่กำลังไหลอยู่ถูกยกเลิกหมด นี่คือเหตุผลที่ "ปล่อยนิ้วแล้วไม่ animate"
        //
        // จึงต้องเช็คเจ้าของผังก่อนเสมอ · ถ้าไม่ใช่ของหน้านี้ให้คำนวณสด ๆ ซึ่งได้ค่าเดียวกับที่
        // resolve() กำลังจะเซ็ตพอดี — id กับกรอบไม่ขยับ อนิเมชันจึงไหลต่อไม่สะดุด
        let solved = placedPage == page.id ? placed : PageLayout.solve(page.items, page: size)

        // หมายเหตุ: เคยครอบด้วย GlassEffectContainer เพื่อให้กระจกหลอมเชื่อมกัน
        // แต่มันแคชการวาดทั้งกลุ่ม พอ widget โดน transform 3D ตอนเปลี่ยนหน้า
        // เนื้อหาในกระจกจะหายไปเลย — จึงให้แต่ละชิ้นเป็นกระจกอิสระแทน
        return sheetBody(page, size: size, current: current, dist: dist,
                         interactive: interactive, parallax: parallax, solved: solved)
    }

    private func sheetBody(_ page: CardPage, size: CGSize, current: Bool, dist: CGFloat,
                           interactive: Bool, parallax: CGFloat, solved: [Placed]) -> some View {
        ZStack(alignment: .topLeading) {
            // ตัวยึดขนาดหน้า — ถ้าไม่มี ZStack จะมีขนาดเท่า widget ที่ใหญ่ที่สุด (เพราะ .offset ไม่นับเป็นขนาด)
            // แล้ว .frame ข้างล่างจะจัดก้อนเนื้อหาไว้กึ่งกลางแทนที่จะชิดมุมบนซ้ายของกระดาษ
            Color.clear.frame(width: size.width, height: size.height)

            if isEditing {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 0.8, dash: [5, 5]))
                    .foregroundStyle(theme.inkStyle.line(0.16))
                    .frame(width: size.width, height: size.height)
            }

            ForEach(solved) { p in
                tile(p, on: page, current: current, dist: dist, interactive: interactive,
                     parallax: parallax, pageWidth: size.width)
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay(alignment: .bottomTrailing) {
            if page.isOverflowing && isEditing {
                Label("เกินหน้า", systemImage: "exclamationmark.triangle.fill")
                    .font(.sh(9.5, .semibold))
                    .foregroundStyle(.black.opacity(0.8))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(Color.orange))
                    .offset(y: 22)
            }
        }
    }

    // MARK: - Tile

    @ViewBuilder
    private func tile(_ p: Placed, on page: CardPage, current: Bool, dist: CGFloat, interactive: Bool,
                      parallax: CGFloat, pageWidth: CGFloat) -> some View {
        let isSel = selected == p.id
        // ไม่ผูกกับ current — ระหว่างลากข้ามหน้า tile ต้นทางต้องซ่อนอยู่แม้หน้ามันไม่ใช่หน้าปัจจุบัน
        let isDrag = dragID == p.id
        let order = page.items.firstIndex { $0.id == p.id } ?? 0
        let touch = (pressPoint?.id == p.id && dragID == nil) ? pressPoint?.at : nil

        widgetSurface(p)
            .frame(width: p.frame.width, height: p.frame.height)
            // ส่งระยะหน้าลงไปให้ "ข้างใน" widget ด้วย — ตัวที่มีท่าเป็นของตัวเอง (เช่นบานเกล็ดของ
            // ผลงานที่ยืนยันแล้ว) จะเล่นจังหวะของมันเองแทนที่จะถูกกรอบลากไปทั้งแผ่น
            .environment(\.pageScrub, PageScrub(d: dist, order: order,
                                                flat: p.item.surface == .glass))
            .pressTilt(touch, size: p.frame.size, glow: theme.accent)
            .overlay {
                // คง catcher ไว้ขณะที่มันถือการลากอยู่ — หลัง flip หน้า interactive ของหน้าต้นทาง
                // กลายเป็น false ถ้าถอดตรงนี้ recognizer ตายกลาง gesture แล้ว event ปล่อยนิ้วหาย
                if interactive || dragID == p.id {
                    PressDragCatcher(
                        onBegan: { beginDrag(p) },
                        onChanged: { t in
                            guard dragID == p.id else { return }
                            // นิ้ววัดบนจอ แต่หน้าแสดงแบบย่อ — หารสเกลให้ widget วิ่งเท่านิ้วจริง
                            let s = max(canvasScale, 0.01)
                            let scaled = CGSize(width: t.width / s, height: t.height / s)
                            dragTranslation = scaled
                            updateInsertion(p, scaled)
                            checkEdgeFlip(p, scaled)
                        },
                        onEnded: { endDrag(p) },
                        onTap: { if isEditing { select(p.id) } },
                        onPress: { at in
                            if let at { pressPoint = (p.id, at) }
                            else if pressPoint?.id == p.id { pressPoint = nil }
                        }
                    )
                }
            }
            .overlay { if isEditing { selectionChrome(p, selected: isSel) } }
            // ปุ่มเปลี่ยนรูปอยู่บนตัวรูปเลย — "รูปนี้แก้ได้" ต้องอ่านออกจากตัวรูป ไม่ใช่ไปงมในชีตล่าง
            // วางทับ catcher จึงกินทัชก่อน แตะปุ่มแล้วไม่กลายเป็นลาก widget
            .overlayPreferenceValue(PhotoSlotKey.self) { slots in
                if isEditing, interactive, !slots.isEmpty {
                    photoSlotButtons(slots, on: p)
                }
            }
            .overlay(alignment: .trailing) {
                // isEditing ด้วย — เพิ่ม widget จากโหมดดูแล้วถูก select ห้ามมี handle โผล่
                if isSel && interactive && isEditing && p.item.kind.canResizeWidth { widthHandle(p) }
            }
            .overlay(alignment: .bottom) {
                if isSel && interactive && isEditing && p.item.kind.canResizeHeight { heightHandle(p) }
            }
            .opacity(isDrag ? 0 : 1)
            .pageChoreo(p.item.kind, order, d: dist, flat: p.item.surface == .glass)
            // widget ที่กินเต็มความกว้าง = ชั้นหลัง เลื่อนช้ากว่า · ตัวแคบ = ชั้นหน้า เลื่อนเร็วกว่า
            .offset(x: p.frame.minX - parallax * pageWidth * (p.item.cols >= 5 ? 0.22 : 0.52),
                    y: p.frame.minY)
            .zIndex(isSel ? 10 : 0)
    }

    @ViewBuilder
    private func widgetSurface(_ p: Placed) -> some View {
        let ink = theme.inkStyle
        let kind = p.item.kind
        let surface = p.item.surface
        let shape = RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
        // เนื้อหา widget เป็นภาพล้วน ห้ามรับทัชเอง — รูปแบบ .fill ที่ล้นกรอบ (clipped ตัดแค่ภาพ
        // ไม่ตัดพื้นที่ทัช) จะไปทับ widget ข้างเคียงจนกด/ลากตัวนั้นไม่ได้
        // ทัชทั้งหมดเป็นหน้าที่ของ PressDragCatcher ที่ขนาดตรงกรอบ tile เป๊ะ
        // "ไม่มีขอบ" = ไม่มีเปลือกอะไรเลย — ทั้งพื้นและเส้นขอบหายไปพร้อมกัน
        // เนื้อหาจึงลอยบนการ์ดตรง ๆ และเรียงตรงกริดหน้าเหมือน widget สายตัวอักษร
        let framed = p.item.border
        // มีเปลือกเมื่อไหร่ต้องมีระยะหายใจข้างใน ยกเว้น full-bleed ที่รูปต้องชนขอบ
        let inset: CGFloat = kind.isFullBleed || !framed ? 0 : 12
        let body = WidgetBody(kind: kind, theme: theme, size: p.frame.size)
            .environment(\.widgetID, p.item.id)
            .padding(inset)
            .frame(width: p.frame.width, height: p.frame.height, alignment: .topLeading)
            .allowsHitTesting(false)

        Group {
            switch framed ? surface : .plain {
            case .plain:
                body

            case .glass:
                GlassPanel(tint: kind.tier == .verified ? theme.accent : nil,
                           tintStrength: kind.tier == .verified ? 0.13 : 0,
                           radius: theme.radius) {
                    body.clipShape(shape)
                }

            case .dim:
                // แผ่นทึบที่ "จมลงไป" ในฉากหลัง ให้เนื้อหาเด่นสุด
                // พื้นมืดจมด้วยสีดำ · กระดาษจมด้วยหมึกจาง ๆ — ความหมายเดียวกัน คนละทิศ
                ZStack {
                    shape.fill(ink.isLight ? ink.fill(0.4) : Color.black.opacity(0.4))
                    body.clipShape(shape)
                }

            case .faint:
                // แผ่นบางที่เห็นขอบเขตแต่ไม่แย่งซีน
                // บนกระดาษต้องเป็นแผ่นขาว "ยกขึ้น" ไม่ใช่แผ่นจางที่มองไม่เห็น
                ZStack {
                    shape.fill(ink.isLight ? Color.white.opacity(0.55) : Color.white.opacity(0.06))
                    body.clipShape(shape)
                }
                .shadow(color: ink.lift.opacity(0.6), radius: ink.liftRadius * 0.7, y: 4)
            }
        }
        // ขอบเป็นตัวเลือกแยก — พื้นโปร่ง + มีขอบ ก็เป็นการ์ดเส้นขอบล้วนได้
        // พื้นโปร่งต้องเข้มกว่าหน่อยเพราะไม่มีพื้นช่วยแยกตัวออกจากฉากหลัง
        .overlay {
            if p.item.border {
                shape.strokeBorder(ink.line(surface == .plain ? 0.18 : 0.12), lineWidth: 0.7)
            }
        }
    }

    /// ปุ่มเปลี่ยนรูปหนึ่งปุ่มต่อหนึ่งช่องรูป — อ่านตำแหน่งช่องจาก anchor ที่ตัว widget ประกาศไว้
    ///
    /// วาดที่ชั้นนี้แทนที่จะให้ widget ใส่ปุ่มเอง เพราะเนื้อหา widget ถูกปิด hit testing ทั้งก้อน
    /// (รูปแบบ .fill ล้นกรอบ ถ้าเปิดทัชไว้มันจะไปแย่งทัชของ widget ข้างเคียง)
    private func photoSlotButtons(_ slots: [PhotoSlotAnchor], on p: Placed) -> some View {
        // เรียงตามตำแหน่งบนหน้าจอ — บนลงล่าง ซ้ายไปขวา
        // ลำดับนี้คือลำดับที่รูปจะไหลลงช่องเวลาผู้ใช้เลือกมาทีเดียวหลายใบ
        GeometryReader { geo in
            let sorted = slots.sorted {
                let a = geo[$0.bounds], b = geo[$1.bounds]
                return a.minY == b.minY ? a.minX < b.minX : a.minY < b.minY
            }
            let order = sorted.map(\.index)
            ForEach(sorted, id: \.index) { slot in
                let r = geo[slot.bounds]
                PhotoSlotButton(theme: theme, widgetID: p.item.id, slot: slot.index, order: order)
                    // ชิดขวาบนของช่อง — คู่ปุ่ม (เปลี่ยน + ถอย) จึงงอกไปทางซ้าย ไม่ล้นออกนอกรูป
                    // .frame ไม่กินทัชในพื้นที่ว่าง ทัชนอกตัวปุ่มจึงตกไปถึง catcher ตามเดิม
                    .padding(5)
                    .frame(width: r.width, height: r.height, alignment: .topTrailing)
                    .position(x: r.midX, y: r.midY)
            }
        }
    }

    @ViewBuilder
    private func selectionChrome(_ p: Placed, selected isSel: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
        ZStack {
            shape.strokeBorder(isSel ? theme.accent
                                     : theme.inkStyle.line(p.item.surface == .plain ? 0.07 : 0.14),
                               lineWidth: isSel ? 1.5 : 0.7)
            if isSel {
                shape.strokeBorder(theme.accent.opacity(0.18), lineWidth: 7).blur(radius: 5)
                    .matchedGeometryEffect(id: "selectionGlow", in: selectionNS)
                ForEach(0..<4, id: \.self) { i in
                    Circle().fill(.white).frame(width: 8, height: 8)
                        .overlay(Circle().strokeBorder(theme.accent, lineWidth: 1.6))
                        .shadow(color: .black.opacity(0.4), radius: 3)
                        .position(x: i % 2 == 0 ? 0 : p.frame.width,
                                  y: i < 2 ? 0 : p.frame.height)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func dragLayer(_ p: Placed) -> some View {
        widgetSurface(p)
            .frame(width: p.frame.width, height: p.frame.height)
            .scaleEffect(lifted ? 1.05 : 1.0)
            .shadow(color: .black.opacity(lifted ? 0.55 : 0), radius: lifted ? 30 : 0, y: lifted ? 16 : 0)
            .overlay {
                RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                    .strokeBorder(theme.accent, lineWidth: 1.5)
            }
            .offset(x: dragStart.minX + dragTranslation.width,
                    y: dragStart.minY + dragTranslation.height)
            .allowsHitTesting(false)
            .zIndex(200)
    }

    // MARK: - State

    private func resolve() {
        guard let page = current else { placed = []; placedPage = nil; return }
        placed = PageLayout.solve(page.items, page: pageSize)
        placedPage = page.id
    }

    private func select(_ id: UUID?) {
        guard selected != id else { return }
        withAnimation(Motion.snap) { selected = id }
        // เลือกตัวไหนชีตยกขึ้นมาโชว์แผงของมัน · วางมือแล้วหุบกลับให้การ์ดใหญ่เต็มที่
        if isEditing { sheetDetent = id == nil ? SheetStop.compact : SheetStop.normal }
        if id != nil { Haptics.impact(.light) }
    }

    private func addWidget(_ kind: WidgetKind) {
        guard pages.indices.contains(index) else { return }
        let w = WidgetInstance(kind)
        withAnimation(Motion.flow) {
            // แทรกบนสุดเสมอ — ของใหม่ต้องเห็นทันที ไม่ใช่จมอยู่ท้ายหน้า
            pages[index].items.insert(w, at: 0)
            rebalance(from: index)
        }
        select(w.id)
        Haptics.impact(.medium)
    }

    /// กติกา: หน้าห้ามล้น — ตัวล่างสุดของหน้าที่ล้นไหลไปอยู่บนสุดของหน้าถัดไป ต่อเนื่องเป็นลูกโซ่
    /// ถึงหน้าสุดท้ายแล้วยังล้นก็เปิดหน้าใหม่รับเอง
    private func rebalance(from start: Int) {
        var p = start
        while pages.indices.contains(p) {
            // เหลืออย่างน้อย 1 ตัวต่อหน้า — widget เดี่ยวที่สูงเกินหน้าไม่มีที่ให้ไป อย่าวนไม่จบ
            while pages[p].isOverflowing, pages[p].items.count > 1 {
                let last = pages[p].items.removeLast()
                if p + 1 >= pages.count { pages.append(CardPage()) }
                pages[p + 1].items.insert(last, at: 0)
            }
            p += 1
        }
    }

    // MARK: - Drag

    private func beginDrag(_ p: Placed) {
        // คลิปเป็นตัวเปิดการ์ด — กดค้างแล้วห้ามหลุดเข้าโหมดแต่ง
        if viewOnly { return }
        // กดค้างจากโหมดดู = เข้าโหมดแต่งแล้วลากต่อได้ทันที (แบบ home screen ของ iOS)
        // ชีตขึ้นแบบหุบเป็นแถบเตี้ย ๆ — แคนวาสยังใหญ่เกือบเต็ม
        if !isEditing {
            withAnimation(Motion.settle) { isEditing = true }
            sheetDetent = SheetStop.compact
        }
        guard dragID == nil, let live = placed.first(where: { $0.id == p.id }) else { return }
        select(p.id)
        withAnimation(Motion.snap) { swipe = 0 }
        dragID = p.id
        dragItem = p.item
        dragOriginPage = index
        dragOriginIndex = pages[index].items.firstIndex { $0.id == p.id } ?? 0
        dragStart = live.frame
        dragGripX = (pressPoint?.id == p.id ? pressPoint?.at.x : nil) ?? live.frame.width / 2
        dragTranslation = .zero
        baseline = PageLayout.solve(current?.items.filter { $0.id != p.id } ?? [], page: pageSize)
        Haptics.impact(.medium)
        withAnimation(Motion.lift) { lifted = true }
    }

    private func endDrag(_ p: Placed) {
        guard dragID == p.id else { return }
        dwell?.cancel(); dwell = nil; pendingIndex = nil
        edgeFlip?.cancel(); edgeFlip = nil

        // ปล่อยนอกพื้นที่หน้า (เหนือชีต/พ้นขอบ) = วางไม่ได้ — เด้งกลับบ้านเดิม
        let drop = CGPoint(x: dragStart.midX + dragTranslation.width,
                           y: dragStart.midY + dragTranslation.height)
        let margin: CGFloat = 40
        guard drop.x > -margin, drop.x < pageSize.width + margin,
              drop.y > -margin, drop.y < pageSize.height + margin else {
            bounceBack(p)
            return
        }

        // ปล่อยนิ้วบนหน้าอื่นที่ไม่ใช่หน้าต้นทาง — ย้าย item จริงตอนนี้ ตรงตำแหน่งที่ปล่อย
        if let src = pages.firstIndex(where: { pg in pg.items.contains { $0.id == p.id } }),
           src != index, pages.indices.contains(index),
           let i = pages[src].items.firstIndex(where: { $0.id == p.id }) {
            let center = CGPoint(x: dragStart.midX + dragTranslation.width,
                                 y: dragStart.midY + dragTranslation.height)
            let at = PageLayout.insertionIndex(
                for: center, in: PageLayout.solve(pages[index].items, page: pageSize))
            let item = pages[src].items.remove(at: i)
            pages[index].items.insert(item, at: min(at, pages[index].items.count))
        }

        // "ห่างบน" ตามตำแหน่งที่ปล่อยจริง — ลากชิดตัวบนคือชิด (0) ปล่อยต่ำลงมาคือเว้นเท่าที่เห็น
        // ปัดเป็นช่องกริด ระยะสั้นกว่าครึ่งช่องถือว่าชิด
        var droppedGap: (at: Int, gap: Int)?
        if let i = pages[index].items.firstIndex(where: { $0.id == p.id }) {
            var probe = pages[index].items
            probe[i].gap = 0
            if let natural = PageLayout.solve(probe, page: pageSize).first(where: { $0.id == p.id }) {
                let dropY = dragStart.minY + dragTranslation.height
                let step = PageLayout.cell(pageSize).height + PageLayout.gutter(pageSize.width)
                let g = Int(((dropY - natural.frame.minY) / step).rounded())
                droppedGap = (i, min(max(g, 0), 12))
            }
        }

        baseline = []
        Haptics.impact(.medium)
        withAnimation(Motion.settle) {
            lifted = false
            dragID = nil
            dragItem = nil
            dragTranslation = .zero
            if let d = droppedGap { pages[index].items[d.at].gap = d.gap }
            // หน้าปลายทางอาจล้นเพราะเพิ่งรับ widget มา — ใช้กติกาเดียวกับตอน add
            rebalance(from: index)
        }
    }

    /// วางไม่ได้ — คืนของกลับตำแหน่งเดิม แล้วให้ชั้นลอย "สปริงเด้งกลับ" ไปที่บ้านของมัน
    /// ค้าง dragID ไว้จนสปริงจบ ไม่งั้นชั้นลอยหายวับแทนที่จะเห็นมันบินกลับ
    private func bounceBack(_ p: Placed) {
        // ลำดับในหน้าอาจถูกสลับไปแล้วระหว่างลาก — ย้ายกลับ index บ้านเดิม
        if pages.indices.contains(dragOriginPage),
           let cur = pages.firstIndex(where: { pg in pg.items.contains { $0.id == p.id } }),
           let ci = pages[cur].items.firstIndex(where: { $0.id == p.id }),
           !(cur == dragOriginPage && ci == dragOriginIndex) {
            let item = pages[cur].items.remove(at: ci)
            pages[dragOriginPage].items.insert(item, at: min(dragOriginIndex, pages[dragOriginPage].items.count))
        }
        // ถ้าลากข้ามหน้าไปแล้ว พากลับหน้าต้นทางด้วย
        if index != dragOriginPage, pages.indices.contains(dragOriginPage) {
            withAnimation(Motion.page) { index = dragOriginPage; swipe = 0 }
        }
        baseline = []
        Haptics.rigid()

        withAnimation(.interpolatingSpring(stiffness: 320, damping: 18)) {
            dragTranslation = .zero
            lifted = false
        }
        // รอสปริงเข้าที่ก่อนค่อยสลับชั้นลอยเป็น tile จริง — สลับก่อนจะเห็นวูบ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            guard dragID == p.id else { return }
            dragID = nil
            dragItem = nil
        }
    }

    /// ลากค้างที่ขอบขวา = ไปหน้าถัดไป · ขอบซ้าย = หน้าก่อนหน้า
    /// หน่วง 0.35 วิ กันสลับหน้าโดยไม่ตั้งใจตอนลากผ่านขอบเฉย ๆ
    private func checkEdgeFlip(_ p: Placed, _ t: CGSize) {
        let x = dragStart.minX + dragGripX + t.width
        let margin: CGFloat = 30
        let dir: Int? = x > pageSize.width - margin ? 1 : (x < margin ? -1 : nil)
        guard let dir, pages.indices.contains(index + dir) else {
            edgeFlip?.cancel(); edgeFlip = nil
            return
        }
        guard edgeFlip == nil else { return }
        let work = DispatchWorkItem { flipPage(p, by: dir) }
        edgeFlip = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    /// สลับหน้าที่แสดงระหว่างลาก — ห้ามย้ายข้อมูลตอนนี้เด็ดขาด
    /// ถ้าย้าย item ออกจากหน้าเดิม tile ต้นทาง (ที่ถือ gesture การลากอยู่) จะถูกถอดจากต้นไม้ view
    /// แล้ว event ปล่อยนิ้วจะไม่มีวันมาถึง — การย้ายจริงเกิดตอน endDrag เท่านั้น
    private func flipPage(_ p: Placed, by dir: Int) {
        edgeFlip = nil
        let target = index + dir
        guard dragID == p.id, pages.indices.contains(target) else { return }
        dwell?.cancel(); dwell = nil; pendingIndex = nil

        // ผังอ้างอิงของหน้าใหม่ — ตัวที่ลากยังไม่อยู่ในหน้านี้ ใช้ทั้งหน้าได้เลย
        baseline = PageLayout.solve(pages[target].items.filter { $0.id != p.id }, page: pageSize)
        withAnimation(Motion.page) {
            index = target
            swipe = 0
        }
        Haptics.impact(.medium)
    }

    /// ย้ายตำแหน่งทันทีที่นิ้วผ่านจุดกึ่งกลางของตัวอื่น · หน่วง 45ms แค่กันสั่นตรงเส้นแบ่ง
    private func updateInsertion(_ p: Placed, _ t: CGSize) {
        guard pages.indices.contains(index) else { return }
        let center = CGPoint(x: dragStart.midX + t.width, y: dragStart.midY + t.height)
        let target = PageLayout.insertionIndex(for: center, in: baseline)
        guard let from = pages[index].items.firstIndex(where: { $0.id == p.id }) else { return }

        guard target != from else {
            dwell?.cancel(); pendingIndex = nil
            return
        }
        guard target != pendingIndex else { return }

        pendingIndex = target
        dwell?.cancel()
        let work = DispatchWorkItem {
            guard pendingIndex == target, pages.indices.contains(index),
                  let cur = pages[index].items.firstIndex(where: { $0.id == p.id }) else { return }
            var next = pages[index].items
            next.insert(next.remove(at: cur), at: min(target, next.count))
            pages[index].items = next
            Haptics.impact(.light)
            pendingIndex = nil
        }
        dwell = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.045, execute: work)
    }

    // MARK: - Handles

    private func widthHandle(_ p: Placed) -> some View {
        HandleGrip(theme: theme, axis: .horizontal)
            .offset(x: 3)
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { g in
                        guard let i = pages[index].items.firstIndex(where: { $0.id == p.id }) else { return }
                        if resizeID != p.id { resizeID = p.id; resizeCols = pages[index].items[i].cols }
                        let step = PageLayout.cell(pageSize).width + PageLayout.gutter(pageSize.width)
                        let r = p.item.kind.colRange
                        let next = min(max(resizeCols + Int((g.translation.width / step).rounded()),
                                           r.lowerBound), r.upperBound)
                        if next != pages[index].items[i].cols {
                            pages[index].items[i].cols = next
                            Haptics.impact(.light)
                        }
                    }
                    .onEnded { _ in resizeID = nil; Haptics.impact(.medium) }
            )
    }

    private func heightHandle(_ p: Placed) -> some View {
        HandleGrip(theme: theme, axis: .vertical)
            .offset(y: 3)
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { g in
                        guard let i = pages[index].items.firstIndex(where: { $0.id == p.id }) else { return }
                        if resizeID != p.id { resizeID = p.id; resizeRows = pages[index].items[i].rows }
                        let step = PageLayout.cell(pageSize).height + PageLayout.gutter(pageSize.width)
                        let r = p.item.kind.rowRange
                        let next = min(max(resizeRows + Int((g.translation.height / step).rounded()),
                                           r.lowerBound), r.upperBound)
                        if next != pages[index].items[i].rows {
                            pages[index].items[i].rows = next
                            Haptics.impact(.light)
                        }
                    }
                    .onEnded { _ in resizeID = nil; Haptics.impact(.medium) }
            )
    }

    // MARK: - Chrome

    private var topBar: some View {
        VStack {
            GlassEffectContainer(spacing: 14) {
                HStack(spacing: 10) {
                    if viewOnly {
                        Color.clear.frame(width: 34, height: 22)
                    } else {
                        // แต่ง — ซ้ายบน · ทางเข้าเดียวของชีตควบคุมล่าง
                        Button {
                            withAnimation(Motion.settle) {
                                isEditing.toggle()
                                if !isEditing { selected = nil }
                            }
                            // เข้าโหมดแต่งเริ่มที่ชีตหุบ — การ์ดใหญ่ไว้ก่อน อยากได้แผงค่อยดึงขึ้น
                            if isEditing { sheetDetent = SheetStop.compact }
                            Haptics.impact(.medium)
                        } label: {
                            Text(isEditing ? "เสร็จ" : "แต่ง")
                                .font(.sh(13, .semibold)).frame(minWidth: 34)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(theme.accent)
                    }

                    Spacer()
                    VStack(spacing: 0) {
                        // แถบนี้ลอยอยู่บน "ฉากหลังของการ์ด" ไม่ใช่บนพื้นแอปแยกต่างหาก
                        // จึงต้องพลิกตามหมึกด้วย ไม่งั้นพอเลือกกระดาษแล้วชื่อจะหายไปกับพื้น
                        Text("STARCARD").font(.sh(9, .bold)).tracking(1.6)
                            .foregroundStyle(theme.inkStyle.text(0.4))
                        Text("@\(invocation.slug)").font(.sh(12, .semibold))
                            .foregroundStyle(theme.inkStyle.text(0.85))
                        if viewOnly, let url = invocation.url {
                            Text(url.host.map { $0 + url.path } ?? url.absoluteString)
                                .font(.sh(9, .medium))
                                .foregroundStyle(theme.inkStyle.text(0.35))
                                .lineLimit(1)
                        }
                    }
                    Spacer()

                    if viewOnly {
                        Button {
                            showHire = true
                            Haptics.impact(.medium)
                        } label: {
                            Text("คุยงาน")
                                .font(.sh(13, .semibold)).frame(minWidth: 34)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(theme.accent)
                    } else {
                        // เพิ่ม widget — ขวาบน · เปิดตู้อย่างเดียว ไม่เด้งชีตแต่ง
                        Button {
                            selected = nil
                            showGallery = true
                            Haptics.impact(.light)
                        } label: {
                            // SF Symbol ตรง ๆ — SHIcon เป็น asset ของแบรนด์ ไม่มี glyph บวก
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(width: 34, height: 22)
                        }
                        .buttonStyle(.glass)
                        .accessibilityLabel("เพิ่ม widget")
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
            }
            .padding(.horizontal, 15).padding(.top, 4)
            Spacer()
        }
    }

    /// แถบบอกหน้า — แตะกระโดดข้ามหน้าได้ ไม่ต้องปัดทีละหน้า
    private var pageRail: some View {
        VStack {
            Spacer()
            HStack(spacing: 6) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { i, _ in
                    Capsule()
                        .fill(i == index ? theme.accent : Color.white.opacity(0.22))
                        .frame(width: i == index ? 22 : 7, height: 7)
                        .onTapGesture {
                            withAnimation(Motion.page) { index = i }
                        }
                }
                Text("\(index + 1) / \(pages.count)")
                    .font(.sh(9.5, .semibold)).tracking(0.6)
                    .foregroundStyle(theme.inkStyle.text(0.4))
                    .padding(.leading, 6)
            }
            .padding(.bottom, 14)
        }
    }

    /// หัวข้อของแต่ละเรื่องในชีต — **จัดกลาง ตัวใหญ่ ทุกเรื่องใช้ตัวเดียวกัน**
    ///
    /// ของเดิมเป็นป้ายจิ๋ว 9.5pt ในคอลัมน์ซ้ายกว้าง 46pt: มันเบียดกับแถวปุ่มจนอ่านเป็นส่วนหนึ่งของปุ่ม
    /// และคำที่ยาวกว่าคอลัมน์ก็ถูกบีบจนเสียน้ำหนัก ชีตทั้งใบเลยอ่านออกมาเป็นปุ่มสิบกว่าปุ่มเรียงกัน
    /// ไม่ใช่คำถามไม่กี่ข้อที่ต้องตอบ
    ///
    /// พอหัวข้อขึ้นไปอยู่กลางเหนือแถวของตัวเอง แต่ละเรื่องก็มีหัวและตัวชัดเจน
    /// และแถวปุ่มได้ความกว้างคืนไปเต็มบรรทัด
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.sh(13.5, .semibold))
            .foregroundStyle(.white.opacity(0.72))
            .lineLimit(1).minimumScaleFactor(0.7)
            // ชิดซ้าย — ขอบซ้ายของหัวข้อทุกเรื่องกับแถวตัวเลือกใต้มันเป็นเส้นเดียวกันทั้งชีต
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// เรื่องหนึ่งเรื่องในชีต — หัวข้อชิดซ้าย แล้วตัวเลือกอยู่ใต้หัวข้อ
    private func section<V: View>(_ title: String, @ViewBuilder content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(title)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// เปลือกของตัวเลือกหนึ่งตัว — ตัวอย่างจริงนำหน้า ชื่อตามหลัง
    private func optionChip<V: View>(_ name: String, on: Bool,
                                     @ViewBuilder preview: () -> V) -> some View {
        HStack(spacing: 5) {
            preview()
                .frame(width: 24, height: 17)
                .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 0.5))
            Text(name).font(.sh(9.5, .semibold))
        }
        .fixedSize()
        .foregroundStyle(on ? .black.opacity(0.85) : .white.opacity(0.7))
        .padding(.horizontal, 6).padding(.vertical, 4.5)
        .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(on ? Color.white.opacity(0.92) : Color.white.opacity(0.08)))
    }

    private var themePanel: some View {
        VStack(spacing: 18) {
            // ── สี ─────────────────────────────────────────────────────
            section("สี") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(Palette.allCases) { p in
                            let active = theme.palette == p && theme.customHue == nil
                            Button {
                                withAnimation(Motion.flow) {
                                    theme.palette = p
                                    // เลือกสีสำเร็จรูป = ตั้งใจเลิกใช้สีที่เลือกเอง/สีจากรูปพื้นหลัง
                                    theme.customHue = nil
                                    theme.customSat = nil
                                }
                                Haptics.impact(.light)
                            } label: {
                                Circle()
                                    .fill(LinearGradient(colors: [p.accentSoft, p.accent],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().strokeBorder(.white.opacity(active ? 0.95 : 0.2),
                                                                   lineWidth: active ? 2 : 0.5))
                                    .scaleEffect(active ? 1.12 : 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 3).padding(.horizontal, 2)
                }
            }

            // ── โทน ────────────────────────────────────────────────────
            // อยู่เหนือฉากหลัง เพราะมันเปลี่ยนความหมายของทุกตัวเลือกที่เหลือ
            //
            // ซ่อนทั้งเรื่องเมื่อฉากหลังเป็นรูป — รูปคุมความสว่างไม่ได้ หมึกเลยถูกล็อกเป็นกลางคืน
            // (ดู `CardTheme.activeInk`) ตัวเลือกที่กดแล้วไม่มีอะไรเกิดขึ้นแย่กว่าไม่มีตัวเลือก
            if theme.backdrop != .photo {
                section("โทน") {
                    // ชิปน้อยพอจะวางได้หมดในบรรทัดเดียว — ไม่ต้องมีรางเลื่อนให้ตาไล่หา
                    HStack(spacing: 7) {
                        ForEach(CardInk.allCases) { i in
                            Button {
                                withAnimation(Motion.flow) { theme.ink = i }
                                Haptics.impact(.light)
                            } label: {
                                optionChip(i.name, on: theme.ink == i) {
                                    InkSwatch(theme: theme, ink: i)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }

            // ── ฉากหลัง ────────────────────────────────────────────────
            section("ฉากหลัง") {
                HStack(spacing: 7) {
                    ForEach(BackdropStyle.allCases) { st in
                        Button {
                            withAnimation(Motion.flow) { theme.backdrop = st }
                            Haptics.impact(.light)
                        } label: {
                            optionChip(st.name, on: theme.backdrop == st) {
                                BackdropSwatch(theme: theme, style: st)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }

            // ── มุม ────────────────────────────────────────────────────
            section("มุม") {
                HStack(spacing: 7) {
                    ForEach(CornerStyle.allCases) { c in
                        Button {
                            withAnimation(Motion.snap) { theme.corner = c }
                        } label: {
                            Text(c.name).font(.sh(11, .semibold))
                                .foregroundStyle(theme.corner == c ? .black.opacity(0.85) : .white.opacity(0.7))
                                .padding(.horizontal, 13).padding(.vertical, 6)
                                .background(Capsule().fill(theme.corner == c ? Color.white.opacity(0.92) : Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    @ViewBuilder
    private func widgetPanel(_ sel: WidgetInstance) -> some View {
        let kind = sel.kind
        VStack(alignment: .leading, spacing: 16) {
            // ชื่อ widget คือหัวเรื่องของทั้งชีต — จัดกลางและใหญ่ที่สุดในแผง
            // ปุ่มปิดวางทับด้านขวาแทนที่จะอยู่ในแถวเดียวกัน ไม่งั้นชื่อจะถูกดันออกจากกึ่งกลางจริง
            HStack(spacing: 7) {
                Image(systemName: kind.symbol).font(.sh(13))
                    .foregroundStyle(kind.tier == .verified ? theme.rawAccent : .white.opacity(0.75))
                Text(kind.title).font(.sh(16, .semibold)).foregroundStyle(.white)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 8)
                Button { select(nil) } label: {
                    Image(systemName: "xmark").font(.sh(10, .bold))
                        .foregroundStyle(.white.opacity(0.6)).frame(width: 24, height: 24)
                        .background(Circle().fill(.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }

            // ไม่มีสเต็ปเปอร์ขนาด/ระยะแล้ว — ปรับบนการ์ดโดยตรง
            // (ลากหมุดที่ขอบเพื่อย่อขยาย · ลากตัว widget เพื่อจัดตำแหน่งและระยะห่าง)
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: kind.canResizeWidth || kind.canResizeHeight
                          ? "hand.draw.fill" : "lock.fill")
                        .font(.sh(9))
                    Text(kind.canResizeWidth || kind.canResizeHeight
                         ? "ลากหมุดที่ขอบเพื่อปรับขนาด"
                         : "ขนาดล็อก · หลักฐานต้องเทียบกันได้")
                        .font(.sh(10.5, .medium))
                        .lineLimit(1).minimumScaleFactor(0.65)
                }
                .foregroundStyle(.white.opacity(0.42))

                Spacer(minLength: 0)
                Button {
                    withAnimation(Motion.flow) {
                        for i in pages.indices { pages[i].items.removeAll { $0.id == sel.id } }
                        selected = nil
                    }
                    Haptics.impact(.medium)
                } label: {
                    Image(systemName: "trash.fill").font(.sh(12))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 32, height: 30)
                        .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.red.opacity(0.42)))
                }
                .buttonStyle(.plain)
            }

            // พื้นผิว — เลือกได้ทุก widget: กระจก · เข้ม · จาง · โปร่ง
            section("พื้น") {
                HStack(spacing: 7) {
                    ForEach(WidgetSurface.allCases) { s in
                        let active = sel.surface == s
                        Button {
                            setSurface(sel, s)
                        } label: {
                            Text(s.name).font(.sh(11, .semibold))
                                .foregroundStyle(active ? .black.opacity(0.85) : .white.opacity(0.65))
                                .padding(.horizontal, 13).padding(.vertical, 6)
                                .background(Capsule().fill(active ? Color.white.opacity(0.9) : Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }

            // ขอบ — แยกจากพื้น เพราะบางแบบอยากได้แค่เส้นกรอบโดยไม่เอาพื้น
            section("ขอบ") {
                HStack(spacing: 7) {
                    ForEach([true, false], id: \.self) { on in
                        let active = sel.border == on
                        Button {
                            setBorder(sel, on)
                        } label: {
                            Text(on ? "มีขอบ" : "ไม่มีขอบ").font(.sh(11, .semibold))
                                .foregroundStyle(active ? .black.opacity(0.85) : .white.opacity(0.65))
                                .padding(.horizontal, 13).padding(.vertical, 6)
                                .background(Capsule().fill(active ? Color.white.opacity(0.9) : Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func setSurface(_ sel: WidgetInstance, _ s: WidgetSurface) {
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            withAnimation(Motion.flow) { pages[pi].items[i].surface = s }
            Haptics.impact(.light)
            return
        }
    }

    private func setBorder(_ sel: WidgetInstance, _ on: Bool) {
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            withAnimation(Motion.flow) { pages[pi].items[i].border = on }
            Haptics.impact(.light)
            return
        }
    }

    /// แถวสลับแบบภายในหมวดเดียวกัน
    ///
    /// วางไว้ตรงนี้แทนที่จะต้องไปเปิด gallery ใหม่ เพราะเวลาผู้ใช้แตะ widget
    /// สิ่งที่เขาอยากรู้อันดับแรกคือ "มันมีหน้าตาแบบอื่นไหม" ไม่ใช่ "จะเพิ่มตัวใหม่"
    @ViewBuilder
    private func variantPicker(_ sel: WidgetInstance) -> some View {
        let siblings = WidgetKind.allCases.filter { $0.family == sel.kind.family }
        if siblings.count > 1 {
            VStack(alignment: .leading, spacing: 9) {
                sectionTitle("แบบอื่นของ \(sel.kind.family.label)")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(siblings) { k in
                            let active = k == sel.kind
                            Button { swap(sel, to: k) } label: {
                                VStack(spacing: 6) {
                                    WidgetThumb(kind: k, theme: theme.toolTheme)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(active ? theme.rawAccent : .white.opacity(0.12),
                                                              lineWidth: active ? 2 : 0.6)
                                        )
                                    Text(k.title)
                                        .font(.sh(9.5, active ? .semibold : .regular))
                                        .foregroundStyle(active ? .white : .white.opacity(0.5))
                                        .lineLimit(1).minimumScaleFactor(0.7)
                                        .frame(width: 104)
                                }
                                // พรีวิวปิด hit testing ไว้ (กันไม่ให้ widget ข้างในกินทัช)
                                // ถ้าไม่ประกาศ contentShape ปุ่มจะกดติดแค่ตรงข้อความใต้รูป
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    /// สลับแบบโดยคงตำแหน่งเดิมไว้ · บีบขนาดให้เข้ากรอบของแบบใหม่
    private func swap(_ sel: WidgetInstance, to kind: WidgetKind) {
        guard kind != sel.kind else { return }
        for pi in pages.indices {
            guard let i = pages[pi].items.firstIndex(where: { $0.id == sel.id }) else { continue }
            var w = pages[pi].items[i]
            w.kind = kind
            w.cols = min(max(w.cols, kind.colRange.lowerBound), kind.colRange.upperBound)
            w.rows = min(max(w.rows, kind.rowRange.lowerBound), kind.rowRange.upperBound)
            // แบบใหม่บุคลิกต่างจากเดิม — กลับไปใช้พื้นตั้งต้นของมัน
            w.surface = kind.isPlain ? .plain : .glass
            w.border = !kind.isPlain
            withAnimation(Motion.flow) {
                pages[pi].items[i] = w
                // แบบใหม่อาจสูงกว่าเดิมจนหน้าล้น — หน้าห้ามล้นเสมอ
                rebalance(from: pi)
            }
            Haptics.impact(.medium)
            return
        }
    }

}

// MARK: - Spectrum picker

/// แถบเลือกสี — ลากบนสเปกตรัมเลือกเฉด · แถบล่างปรับความสด
///
/// ฝังในแผงแทน `ColorPicker` ของระบบ เพราะตัวระบบเป็นชีตซ้อนชีตแล้วเปิดไม่ขึ้น
/// และแบบฝังยังดีกว่าตรงที่การ์ดเปลี่ยนสีให้เห็นสด ๆ ทุกเฟรมระหว่างลาก
private struct SpectrumPicker: View {
    let hue: Double
    let sat: Double
    let onChange: (Double, Double) -> Void

    private let knob: CGFloat = 20

    var body: some View {
        VStack(spacing: 7) {
            bar(colors: (0...12).map { Color(hue: Double($0) / 12, saturation: 0.9, brightness: 1) },
                value: hue) { onChange($0, sat) }
            bar(colors: [Color(hue: hue, saturation: 0.04, brightness: 0.96),
                         Color(hue: hue, saturation: 1, brightness: 1)],
                value: sat) { onChange(hue, max(0.15, $0)) }
        }
    }

    private func bar(colors: [Color], value: Double,
                     _ set: @escaping (Double) -> Void) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 0.5))
                    .frame(height: 16)
                Circle()
                    .fill(Color(hue: hue, saturation: max(sat, 0.15), brightness: 1))
                    .frame(width: knob, height: knob)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                    .offset(x: CGFloat(min(max(value, 0), 1)) * max(w - knob, 0))
            }
            .frame(width: w, height: geo.size.height)
            // แถบสูงกว่าเส้นสี — ให้นิ้วจับติดง่าย ไม่ต้องเล็งเป๊ะ
            .contentShape(Rectangle())
            // ต้อง highPriority ไม่งั้น ScrollView ของชีตแย่ง pan ไปหมด แถบเลื่อนไม่ได้เลย
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        // หักครึ่งปุ่มออก ให้จุดที่นิ้วแตะตรงกับกึ่งกลางปุ่มพอดี
                        set(Double(min(1, max(0, (g.location.x - knob / 2) / max(w - knob, 1)))))
                    }
                    .onEnded { _ in Haptics.impact(.light) }
            )
        }
        .frame(height: 26)
    }
}

// MARK: - Canvas grid

/// จุดปะคือ "กริดจริง" ไม่ใช่ลายตกแต่ง — แถวจุดแต่ละแถวคือตำแหน่ง snap ของ widget (แบบ Figma)
/// แนวตั้งวางตรง pitch ของแถว layout เป๊ะ · แนวนอนซอยคอลัมน์ละ 3 จุดให้ถี่ใกล้เคียงกัน
private struct CanvasGrid: View {
    let theme: CardTheme
    /// จุดกริดอยู่บนหน้ากระดาษ จึงต้องพลิกตามหมึกเหมือนทุกอย่างบนการ์ด
    var ink: InkStyle = .night
    let page: CGSize
    /// ระยะจากขอบบนจอถึงขอบบนหน้ากระดาษ
    let top: CGFloat

    var body: some View {
        Canvas { ctx, _ in
            guard page.width > 0, page.height > 0 else { return }
            let m = PageLayout.margin(page.width)
            let g = PageLayout.gutter(page.width)
            let cell = PageLayout.cell(page)
            let stepY = cell.height + g
            let stepX = (cell.width + g) / 3
            let dot: CGFloat = 1.8

            var y = top + m
            while y <= top + page.height - m + 1 {
                var x = m
                while x <= page.width - m + 1 {
                    ctx.fill(Path(ellipseIn: CGRect(x: x - dot / 2, y: y - dot / 2,
                                                    width: dot, height: dot)),
                             with: .color(ink.line(0.13)))
                    x += stepX
                }
                y += stepY
            }
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}

// MARK: - Handle

private struct HandleGrip: View {
    let theme: CardTheme
    enum Axis { case horizontal, vertical }
    let axis: Axis

    var body: some View {
        Capsule()
            .fill(.white)
            .frame(width: axis == .horizontal ? 6 : 32, height: axis == .horizontal ? 32 : 6)
            .overlay(Capsule().strokeBorder(theme.accent, lineWidth: 1.4))
            .shadow(color: .black.opacity(0.5), radius: 5, y: 2)
            .contentShape(Rectangle().inset(by: -16))
    }
}

// MARK: - Haptics

enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func rigid() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
}

// MARK: - ตัวอย่างย่อของตัวเลือกธีม

/// ตัวอย่างย่อของ "โทน" หนึ่งแบบ — ฉากหลังจริง + แผ่นการ์ดจริง + สีหมึกจริง
///
/// ชื่ออย่าง "กระดาษ" กับ "ใสใส" ไม่ได้บอกว่ากดแล้วได้อะไร ต้องเห็นถึงจะรู้
/// วาดด้วยสูตรเดียวกับของจริงทุกค่า ไม่ใช่ภาพประกอบที่วาดแยก — เปลี่ยนธีมเมื่อไหร่ตัวอย่างตามทันที
private struct InkSwatch: View {
    let theme: CardTheme
    let ink: CardInk

    var body: some View {
        var t = theme
        t.ink = ink
        // ฉากหลังแบบรูปบังคับหมึกกลางคืน ตัวอย่างทั้งสามจะเหมือนกันหมด — สลับเป็นไล่เฉดให้เห็นความต่าง
        if t.backdrop == .photo { t.backdrop = .gradient }
        let c = t.backdropColors
        let s = t.inkStyle
        return ZStack {
            LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(s.isLight ? Color.white.opacity(0.64) : Color.white.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(s.line(0.22), lineWidth: 0.5))
                .overlay(alignment: .leading) {
                    // สามบรรทัดจำลอง — เส้นบางและระยะห่างต้องคุมเป็นสัดส่วนของกรอบ
                    // ไม่ใช่ค่าคงที่ ไม่งั้นพอย่อกรอบลงบรรทัดจะเบียดกันจนเป็นก้อนเดียว
                    VStack(alignment: .leading, spacing: 1.6) {
                        Capsule().fill(t.accent).frame(width: 5, height: 1.8)
                        Capsule().fill(s.text(0.82)).frame(width: 12, height: 2.2)
                        Capsule().fill(s.text(0.36)).frame(width: 8, height: 1.8)
                    }
                    .padding(.leading, 3)
                }
                .padding(2.5)
        }
    }
}

/// ตัวอย่างย่อของ "ฉากหลัง" หนึ่งแบบ — ใช้สีและชั้นเดียวกับ `CardBackdrop`
private struct BackdropSwatch: View {
    let theme: CardTheme
    let style: BackdropStyle

    @Environment(PhotoStore.self) private var photos: PhotoStore?

    var body: some View {
        var t = theme
        t.backdrop = style
        let c = t.backdropColors
        return ZStack {
            switch style {
            case .gradient:
                LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
            case .glow:
                c.bottom
                // ดวงแสงย่อ — ต้องเบลอน้อยกว่าของจริงตามสัดส่วน ไม่งั้นเละเป็นสีเดียว
                Circle().fill(t.accent.opacity(0.75)).frame(width: 16, height: 16)
                    .blur(radius: 6).offset(x: -6, y: -5)
                Circle().fill(t.accentSoft.opacity(0.5)).frame(width: 14, height: 14)
                    .blur(radius: 6).offset(x: 7, y: 6)
            case .solid:
                c.top
            case .photo:
                c.bottom
                if let bg = photos?.background {
                    Image(uiImage: bg).resizable().aspectRatio(contentMode: .fill)
                        .overlay(c.top.opacity(theme.activeInk.isLight ? 0.6 : 0.35))
                } else if let photos {
                    photos.image(0).aspectRatio(contentMode: .fill)
                        .blur(radius: 4, opaque: true)
                        .overlay(c.bottom.opacity(0.45))
                }
            }
        }
    }
}
