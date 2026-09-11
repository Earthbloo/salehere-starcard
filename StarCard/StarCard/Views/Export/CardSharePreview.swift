import Photos
import SwiftUI
import UIKit

/// หน้าตัวอย่างก่อนแชร์ — รูปที่จะได้จริง บนฉากหลังผืนเดียว
/// (พอร์ต = 3 หน้าต่อกัน · สตอรี่ = หน้าเดียว 9:16)
///
/// เป็นเครื่องมือ ไม่ใช่ชิ้นงาน จึงพื้นมืดเสมอ แผ่นการ์ดลอยเป็นงานพิมพ์บนโต๊ะ
struct CardSharePreview: View {
    let pages: [CardPage]
    let theme: CardTheme
    /// ขนาดหน้าบนจอที่ผู้ใช้วาง widget
    let pageSize: CGSize
    /// รูปแบบการ์ด — ตัดสินว่ารูปที่ได้เป็นแถบ 3 หน้า หรือสตอรี่หน้าเดียว
    var format: CardFormat = .portfolio

    @Environment(PhotoStore.self) private var photos
    @Environment(ClipInvocation.self) private var invocation
    @Environment(\.dismiss) private var dismiss

    @State private var image: UIImage?
    @State private var fileURL: URL?
    @State private var failed = false
    @State private var copied = false
    @State private var saving = false
    @State private var saved = false
    @State private var saveFailed = false

    var body: some View {
        ZStack {
            Color(white: 0.07).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 12)
                previewStage
                Spacer(minLength: 16)
                footer
                    .padding(.horizontal, 18)
                    .padding(.bottom, 22)
            }
        }
        .preferredColorScheme(.dark)
        .task { await render() }
        .alert("บันทึกรูปไม่ได้", isPresented: $saveFailed) {
            Button("ตกลง", role: .cancel) {}
        } message: {
            Text("ไปที่ ตั้งค่า > StarCard แล้วอนุญาตให้เพิ่มรูปลงคลังรูป")
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.sh(11, .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.white.opacity(0.1)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("ปิด")

            Spacer()
            VStack(spacing: 1) {
                Text("ตัวอย่าง").font(.sh(16, .semibold)).foregroundStyle(.white)
                Text(format == .story ? "หน้าเดียว · 9:16" : "3 หน้า · แผ่นเดียว")
                    .font(.sh(10.5, .medium))
                    .foregroundStyle(.white.opacity(0.42))
            }
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var previewStage: some View {
        GeometryReader { geo in
            ZStack {
                if let image {
                    let fit = Self.fit(image.size, in: geo.size)
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: fit.width, height: fit.height)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .shadow(color: .black.opacity(0.55), radius: 28, y: 14)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
                        }
                        .accessibilityLabel(format == .story
                                            ? "ตัวอย่างการ์ดแบบสตอรี่"
                                            : "ตัวอย่างการ์ดสามหน้า")
                } else if failed {
                    Text("สร้างรูปไม่สำเร็จ")
                        .font(.sh(14, .medium))
                        .foregroundStyle(.white.opacity(0.55))
                } else {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.15)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(.horizontal, 18)
    }

    /// ย่อรูปให้สุดขอบกล่องโดยคงอัตราส่วนของผืนที่เรนเดอร์
    private static func fit(_ size: CGSize, in box: CGSize) -> CGSize {
        let s = min(box.width / max(size.width, 1), box.height / max(size.height, 1))
        return CGSize(width: size.width * s, height: size.height * s)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            linkRow
            HStack(spacing: 10) {
                shareButton
                // ลิงก์คัดลอกได้จากแถวบนอยู่แล้ว ช่องนี้จึงยกให้ "บันทึกรูป"
                // คลิปเซฟลงคลังรูปไม่ได้ — คลิปเลยได้ปุ่มคัดลอกลิงก์ไปแทน
                if AppRuntime.isClip {
                    copyButton
                } else {
                    saveButton
                }
            }
        }
    }

    private var linkRow: some View {
        Button(action: copyLink) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.sh(11, .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                Text(invocation.shareURLDisplay)
                    .font(.sh(12, .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 8)
                Text(copied ? "คัดลอกแล้ว" : "คัดลอก")
                    .font(.sh(11, .semibold))
                    .foregroundStyle(copied ? Color(red: 0.45, green: 0.92, blue: 0.62) : .white.opacity(0.45))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("คัดลอกลิงก์การ์ด")
    }

    @ViewBuilder
    private var shareButton: some View {
        let label = actionLabel("แชร์รูป", "square.and.arrow.up", prominent: true)
        if let image, let fileURL {
            ShareLink(item: fileURL,
                      preview: SharePreview("Star Card @\(invocation.slug)",
                                            image: Image(uiImage: image))) {
                label
            }
            .buttonStyle(.plain)
        } else {
            label.opacity(0.38)
        }
    }

    /// เซฟลงคลังรูปตรง ๆ — เร็วกว่าไปหา "Save Image" ในชีตแชร์ของระบบ
    private var saveButton: some View {
        Button {
            Task { await saveToPhotos() }
        } label: {
            actionLabel(saved ? "บันทึกแล้ว" : "บันทึกรูป",
                        saved ? "checkmark" : "square.and.arrow.down",
                        prominent: false)
        }
        .buttonStyle(.plain)
        .disabled(image == nil || saving)
        .opacity(image == nil ? 0.38 : 1)
        .accessibilityLabel("บันทึกรูปลงคลังรูป")
    }

    private var copyButton: some View {
        Button(action: copyLink) {
            actionLabel(copied ? "คัดลอกแล้ว" : "คัดลอกลิงก์",
                        copied ? "checkmark" : "doc.on.doc",
                        prominent: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("คัดลอกลิงก์")
    }

    private func actionLabel(_ title: String, _ icon: String, prominent: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).font(.sh(13, .semibold))
            Text(title).font(.sh(14.5, .semibold))
        }
        .foregroundStyle(prominent ? .black.opacity(0.86) : .white.opacity(0.9))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(prominent ? Color.white : Color.white.opacity(0.10))
        )
    }

    private func copyLink() {
        UIPasteboard.general.string = invocation.shareURL.absoluteString
        Haptics.impact(.medium)
        withAnimation(Motion.snap) { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(Motion.snap) { copied = false }
        }
    }

    /// ขอสิทธิ์แบบ addOnly — เราแค่เพิ่มรูปเข้าไป ไม่ต้องเปิดดูคลังรูปของเจ้าของเครื่อง
    @MainActor
    private func saveToPhotos() async {
        guard let image, !saving else { return }
        saving = true
        defer { saving = false }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            saveFailed = true
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            Haptics.impact(.medium)
            withAnimation(Motion.snap) { saved = true }
        } catch {
            saveFailed = true
        }
    }

    @MainActor
    private func render() async {
        await Task.yield()
        if let pack = CardExport.jpegFile(pages: pages, theme: theme,
                                            photos: photos, pageSize: pageSize,
                                            slug: invocation.slug, format: format) {
            image = pack.image
            fileURL = pack.url
        } else {
            failed = true
        }
    }
}
