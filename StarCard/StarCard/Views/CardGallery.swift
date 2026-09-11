import SwiftUI
import UIKit

/// คลังการ์ด — หน้าแรกของแอปเมื่อมีการ์ดอย่างน้อยหนึ่งใบ
///
/// # หน้าที่ของหน้านี้ (ตาม use case ที่ตกลงกัน)
///
/// 1. เห็นการ์ดทุกใบเป็นของจริงย่อส่วน — ไม่ต้องจำว่าใบไหนหน้าตายังไง
/// 2. รู้ใน 0 วินาทีว่าใบไหนคือ **ใบหลัก** (ใบที่ลิงก์ประจำตัวพาคนอื่นไปหา) — อยู่บนสุด + ป้ายเขียว
/// 3. ทุกใบมีลิงก์ของตัวเอง คัดลอกได้จากการ์ดเลย — ส่งใบไหนให้แบรนด์ไหนก็เลือกเอา
/// 4. แตะการ์ด = เข้าไปแก้ · กดค้าง = เมนูทำสำเนา/ลบ · ตั้งใบหลักได้ในแตะเดียว
struct CardGallery: View {
    let onCreate: () -> Void
    let onOpen: (CardRecord) -> Void

    private var library: CardLibrary { CardLibrary.shared }
    @Environment(ClipInvocation.self) private var invocation
    @Environment(PhotoStore.self) private var photos

    /// ใบที่เพิ่งคัดลอกลิงก์ — โชว์ "คัดลอกแล้ว" ชั่วครู่ตรงใบนั้น
    @State private var copiedID: String?

    /// ชีตคำสั่งรองของใบ — ทำเองทั้งใบแทน `Menu`/`alert` ของระบบ
    ///
    /// เมนูระบบบังคับฟอนต์ระบบ ปฏิเสธฟอนต์แอปทุกกรณี — แอปที่ตัวหนังสือทุกจุดเป็น
    /// NotoSansThai แล้วเมนูโผล่มาเป็นฟอนต์อื่นคือรอยต่อที่เห็นด้วยตาเปล่า
    /// ชีตของเราคุมได้ทั้งฟอนต์ สี และจังหวะ ภาษาเดียวกับชีตเครื่องมือในห้องแต่ง
    @State private var sheetTarget: CardRecord?
    @State private var sheetMode: CardSheetMode = .menu
    @State private var renameText = ""

    private enum CardSheetMode { case menu, rename, confirmDelete }
    /// สวิตช์ท่าเข้าฉาก — การ์ดไหลขึ้นทีละใบตอนเปิดหน้า
    @State private var appeared = false

    var body: some View {
        // เวทีมืดล้วน + แดงแบรนด์เป็นสี action — ลองพื้นสว่างตามสเปกหลักแล้วการ์ดจม
        // และลองอาบแสงแดงจาง ๆ แล้วพื้นเลิกเป็นสีดำ จึงเหลือดำสนิทให้การ์ดเด่นคนเดียว
        // (แดง `#ED1C24` · success `#12B76A` จาก `SHColor` — บริบทพื้นเข้มของแอปหลักก็ใช้คู่นี้)
        ZStack {
            Color(white: 0.06).ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if library.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        // Lazy — เหตุผลเดียวกับลิสต์เทมเพลต: สร้างเฉพาะใบที่อยู่ในจอ
                        LazyVStack(spacing: 16) {
                            ForEach(Array(library.displayOrder.enumerated()),
                                    id: \.element.id) { i, record in
                                row(record)
                                    // ท่าเข้าฉาก: ไหลขึ้นทีละใบ ใบบนก่อน — จังหวะไล่กัน
                                    // อ่านออกว่า "ของหลายชิ้นในคลัง" ไม่ใช่ภาพนิ่งแผ่นเดียว
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 28)
                                    .animation(Motion.settle.delay(Double(i) * 0.07),
                                               value: appeared)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)
                        // เผื่อท้ายลิสต์ให้พ้นปุ่มลอย — ใบสุดท้ายต้องไม่โดนปุ่ม + ทับ
                        .padding(.bottom, 96)
                    }
                }
            }

            if !library.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        createButton
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 18)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { appeared = true }
        // อบรูปเทมเพลตล่วงหน้าตั้งแต่ยังอยู่หน้าคลัง — กด + แล้วหน้าเลือกได้รูปพร้อมใช้ทันที
        .task {
            await TemplateThumbs.shared.warm(
                photos: photos,
                cellWidth: (min(UIScreen.main.bounds.width, 480) - 36 - 14) / 2)
        }
        .sheet(isPresented: Binding(get: { sheetTarget != nil },
                                    set: { if !$0 { sheetTarget = nil } })) {
            if let target = sheetTarget {
                actionSheet(target)
                    .presentationDetents([.height(sheetMode == .menu ? 292 : 252)])
                    .presentationDragIndicator(.visible)
                    .environment(\.colorScheme, .dark)
                    .presentationBackground {
                        // มืดแบบเดียวกับชีตเครื่องมือในห้องแต่ง — เครื่องมือมืดเสมอ
                        Rectangle().fill(.ultraThinMaterial)
                            .overlay(Color(white: 0.07).opacity(0.5))
                    }
            }
        }
    }

    // MARK: - ชีตคำสั่งรอง (ฟอนต์แอปทุกตัวอักษร)

    @ViewBuilder
    private func actionSheet(_ record: CardRecord) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            switch sheetMode {
            case .menu:
                Text(record.name)
                    .font(.sh(15, .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1).truncationMode(.tail)
                    .padding(.top, 4)

                sheetRow("pencil", "เปลี่ยนชื่อ") {
                    renameText = record.name
                    withAnimation(Motion.settle) { sheetMode = .rename }
                }
                sheetRow("plus.square.on.square", "ทำสำเนาไว้ลองแก้") {
                    withAnimation(Motion.settle) { _ = library.duplicate(record.id) }
                    Haptics.impact(.medium)
                    sheetTarget = nil
                }
                sheetRow("trash", "ลบการ์ด", destructive: true) {
                    withAnimation(Motion.settle) { sheetMode = .confirmDelete }
                }

            case .rename:
                Text("เปลี่ยนชื่อการ์ด")
                    .font(.sh(15, .semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 4)
                Text("ตั้งชื่อให้จำง่าย เช่น \"ใบส่งสายบิวตี้\"")
                    .font(.sh(11.5, .medium))
                    .foregroundStyle(.white.opacity(0.45))

                TextField("ชื่อการ์ด", text: $renameText)
                    .font(.sh(14.5, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.08)))
                    .submitLabel(.done)
                    .onSubmit { commitRename(record) }

                HStack(spacing: 10) {
                    sheetPill("ยกเลิก") { sheetTarget = nil }
                    sheetPill("บันทึก", prominent: true) { commitRename(record) }
                }

            case .confirmDelete:
                Text("ลบ \"\(record.name)\"?")
                    .font(.sh(15, .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1).truncationMode(.middle)
                    .padding(.top, 4)
                Text("ลิงก์ของใบนี้จะใช้ไม่ได้อีก และกู้คืนไม่ได้")
                    .font(.sh(11.5, .medium))
                    .foregroundStyle(.white.opacity(0.45))

                HStack(spacing: 10) {
                    sheetPill("เก็บไว้") { sheetTarget = nil }
                    sheetPill("ลบการ์ดนี้", destructive: true) {
                        withAnimation(Motion.settle) { library.delete(record.id) }
                        Haptics.impact(.medium)
                        sheetTarget = nil
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .onDisappear { sheetMode = .menu }
    }

    private func commitRename(_ record: CardRecord) {
        withAnimation(Motion.settle) { library.rename(record.id, to: renameText) }
        Haptics.impact(.light)
        sheetTarget = nil
    }

    /// แถวคำสั่งในชีต — ไอคอน + ตัวหนังสือฟอนต์แอป บนแผ่นจาง ๆ
    private func sheetRow(_ symbol: String, _ title: String,
                          destructive: Bool = false,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 22)
                Text(title)
                    .font(.sh(14.5, .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(destructive ? SHColor.red : .white.opacity(0.9))
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    /// ปุ่มแคปซูลคู่ท้ายชีต — ยืนยัน/ยกเลิก
    private func sheetPill(_ title: String, prominent: Bool = false,
                           destructive: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.sh(13.5, .semibold))
                .foregroundStyle(destructive || prominent ? .white : .white.opacity(0.75))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Capsule().fill(
                    destructive ? SHColor.red
                    : prominent ? Color.white.opacity(0.18)
                    : Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - ส่วนหัว

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("การ์ดของฉัน")
                    .font(.sh(22, .bold))
                    .foregroundStyle(.white)
                Text("ใบหลักคือใบที่ลิงก์ของคุณพาแบรนด์ไปเจอ")
                    .font(.sh(12, .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    /// ปุ่มสร้างการ์ด — Primary CTA หนึ่งเดียวของหน้า (สเปก §6.4) ลอยมุมขวาล่าง
    ///
    /// เคยอยู่มุมขวาบนตามความเคยชินของเดสก์ท็อป — แต่บนมือถือโซนบนสุดคือที่ที่นิ้วโป้ง
    /// เอื้อมไม่ถึงตอนถือมือเดียว (audit ข้อ thumb-zone) ปุ่มที่กดบ่อยสุดจึงย้ายลงมาหานิ้ว
    private var createButton: some View {
        Button {
            Haptics.impact(.medium)
            onCreate()
        } label: {
            Image(systemName: "plus")
                .font(.sh(19, .bold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(Circle().fill(SHColor.red))
                .shadow(color: SHColor.red.opacity(0.35), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("สร้างการ์ดใหม่")
    }

    // MARK: - การ์ดหนึ่งใบ

    @ViewBuilder
    private func row(_ record: CardRecord) -> some View {
        let restored = CardStore.restore(record.snapshot)
        let theme = restored?.theme ?? CardTheme()
        let pages = restored?.pages ?? []
        let isPublished = record.id == library.publishedID

        Button {
            Haptics.impact(.light)
            onOpen(record)
        } label: {
            VStack(spacing: 12) {
                // พรีวิวตามรูปทรงจริง — แถบยาวของแนวนอน · เฟรมตั้งคู่ข้อมูลของแนวตั้ง
                if record.format == .portfolio {
                    CardStripPreview(pages: pages, theme: theme,
                                     width: rowWidth, showsDividers: false)
                    info(record, theme: theme, isPublished: isPublished)
                } else {
                    HStack(alignment: .top, spacing: 14) {
                        CardFramePreview(page: pages.first ?? CardPage(),
                                         theme: theme,
                                         pageSize: CardTemplate.previewPageSize(for: .story),
                                         height: 172, cornerRadius: 10)
                        info(record, theme: theme, isPublished: isPublished)
                            .frame(maxHeight: 172)
                    }
                }
            }
            .padding(12)
            // แผ่นมืดยกตัวจาง ๆ — ใบหลักเรืองด้วย **สีธีมของการ์ดใบนั้นเอง** ไม่ใช่สีระบบ
            // (ลองทั้งแดงแบรนด์และทองดาวแล้วอ่านเป็นป้ายเตือน/ราคาถูก — สีของงานคือสีที่เข้ากับงานเสมอ)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.055)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isPublished ? theme.rawAccent.opacity(0.7) : .white.opacity(0.09),
                              lineWidth: isPublished ? 1.2 : 0.6))
            .shadow(color: isPublished ? theme.rawAccent.opacity(0.2) : .clear, radius: 18, y: 7)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(record.name) · \(record.format.title)"
                            + (isPublished ? " · ใบหลัก" : ""))
    }

    /// ปุ่ม ⋯ ประจำใบ — เปิดชีตคำสั่งรองของเราเอง (ไม่ใช่ `Menu` ระบบ ที่บังคับฟอนต์ระบบ)
    private func moreMenu(_ record: CardRecord) -> some View {
        Button {
            Haptics.impact(.light)
            sheetMode = .menu
            sheetTarget = record
        } label: {
            Image(systemName: "ellipsis")
                .font(.sh(13, .bold))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("ตัวเลือกของ \(record.name)")
    }

    /// ความกว้างแถบพรีวิวในแถว — จอ 402 หักขอบหน้า 18×2 และขอบในการ์ด 12×2
    private var rowWidth: CGFloat { UIScreen.main.bounds.width - 36 - 24 }

    // MARK: แถวข้อมูลใต้/ข้างพรีวิว

    @ViewBuilder
    private func info(_ record: CardRecord, theme: CardTheme, isPublished: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(record.name)
                    .font(.sh(14.5, .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1).truncationMode(.tail)
                if isPublished {
                    publishedChip(theme)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
                Spacer(minLength: 0)
                moreMenu(record)
            }

            Text("\(record.format == .portfolio ? "แนวนอน · 3 หน้า" : "แนวตั้ง · 9:16")  ·  แก้\(Self.ago(record.updatedAt))")
                .font(.sh(10.5, .medium))
                .foregroundStyle(.white.opacity(0.42))

            linkRow(record)

            if isPublished {
                // สัญญาณ live — ผลรีเสิร์ช: user รู้ว่า "แสดงอยู่" ก็ต่อเมื่อบอกผลตรง ๆ
                // ไม่ใช่บอกยศ ("ใบหลัก") อย่างเดียว และแอปเราแก้แล้วเห็นผลทันทีซึ่งต้องประกาศ
                HStack(spacing: 6) {
                    Circle()
                        .fill(SHColor.success)
                        .frame(width: 5, height: 5)
                    Text("ใครเปิดลิงก์ของคุณจะเห็นใบนี้ · แก้แล้วเห็นผลทันที")
                        .font(.sh(10, .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .transition(.opacity)
            }

            if record.format == .story { Spacer(minLength: 0) }

            if !isPublished {
                // ปุ่มข้อความตรง ๆ กลาง ๆ — คำพูดคือตัวสื่อ (ลองทั้ง outline แดงและไอคอนดาวแล้ว
                // อ่านเป็นปุ่มอันตราย/ปุ่ม favorite — ไม่มีอันไหนแปลว่า "ใบที่ลิงก์พาไป")
                Button {
                    // ใบที่เพิ่งตั้งสปริงขึ้นไปยอดลิสต์เอง (ลำดับโชว์เอาใบหลักขึ้นก่อนเสมอ)
                    // — การเลื่อนคือคำยืนยันที่ชัดกว่าข้อความไหน ๆ
                    withAnimation(Motion.settle) { library.setPublished(record.id) }
                    Haptics.impact(.medium)
                } label: {
                    Text("ตั้งเป็นใบหลัก")
                        .font(.sh(11.5, .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(.white.opacity(0.1)))
                        .overlay(Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// ป้าย "ใบหลัก" — สีธีมของการ์ดใบนั้น เสียงเดียวกับขอบเรืองรอบแถว
    private func publishedChip(_ theme: CardTheme) -> some View {
        Text("ใบหลัก")
            .font(.sh(9.5, .bold)).tracking(0.4)
            .foregroundStyle(theme.rawAccent)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(theme.rawAccent.opacity(0.14)))
    }

    /// ลิงก์ของใบนี้ + ปุ่มคัดลอก — ลิงก์คือของประจำใบ ไม่ใช่ของหน้าแชร์เท่านั้น
    private func linkRow(_ record: CardRecord) -> some View {
        let copied = copiedID == record.id
        return Button {
            UIPasteboard.general.string =
                library.url(for: record, slug: invocation.slug).absoluteString
            Haptics.impact(.light)
            withAnimation(Motion.settle) { copiedID = record.id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(Motion.settle) {
                    if copiedID == record.id { copiedID = nil }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: copied ? "checkmark" : "link")
                    .font(.sh(9, .bold))
                Text(copied ? "คัดลอกลิงก์แล้ว"
                            : library.urlDisplay(for: record, slug: invocation.slug))
                    .font(.sh(10.5, .semibold))
                    .lineLimit(1).truncationMode(.middle)
            }
            .foregroundStyle(copied ? SHColor.success : .white.opacity(0.6))
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(copied ? SHColor.success.opacity(0.12)
                                              : Color.white.opacity(0.07)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(copied ? "คัดลอกลิงก์แล้ว" : "คัดลอกลิงก์การ์ดใบนี้")
    }

    // MARK: - คลังว่าง

    /// ปกติคลังว่างจะไม่เห็นหน้านี้ (แอปพาไปเลือกเทมเพลตเลย) — เจอได้ทางเดียวคือ
    /// ลบใบสุดท้ายทิ้งจากตรงนี้ จึงต้องมีทางไปต่อในที่เกิดเหตุ ไม่ใช่จอว่างเปล่า
    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white.opacity(0.35))
            Text("ยังไม่มีการ์ด")
                .font(.sh(16, .semibold))
                .foregroundStyle(.white.opacity(0.85))
            Text("เริ่มจากเทมเพลตสวย ๆ แล้วแต่งให้เป็นของคุณ")
                .font(.sh(12, .medium))
                .foregroundStyle(.white.opacity(0.45))
            Button {
                Haptics.impact(.medium)
                onCreate()
            } label: {
                Text("เลือกเทมเพลต")
                    .font(.sh(13.5, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22).padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(SHColor.red))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
            Spacer()
            Spacer()
        }
    }

    /// เวลาแบบคนพูด — "แก้เมื่อครู่ · แก้ 3 ชม. ที่แล้ว" อ่านเร็วกว่าวันที่เต็ม
    private static func ago(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        switch s {
        case ..<90:        return "เมื่อครู่"
        case ..<3_600:     return " \(s / 60) นาทีที่แล้ว"
        case ..<86_400:    return " \(s / 3_600) ชม. ที่แล้ว"
        default:           return " \(s / 86_400) วันที่แล้ว"
        }
    }
}

#Preview {
    CardGallery(onCreate: {}, onOpen: { _ in })
        .environment(PhotoStore())
        .environment(ClipInvocation())
}
