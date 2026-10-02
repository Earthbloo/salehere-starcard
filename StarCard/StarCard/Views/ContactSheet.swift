import SwiftUI

/// ชีต "ติดต่อ" ของหน้าดู — **flow** ตาม `ContactBoxView` ของ salehere-ios
/// (กดปุ่มติดต่อ → ชีตช่องทางเรียงแถวเดียว → แตะแล้วออกไปแอปนั้นทันที)
/// แต่หน้าตาเป็นของเวทีนี้: พื้นมืดชุดเดียวกับหน้าดู ตัวอักษรขาว ไทล์ทรงเดียวกันทุกช่อง
///
/// ไทล์ทุกช่องเป็นสี่เหลี่ยมมนสีแบรนด์ของช่องทาง + ไอคอนขาว — ทรงเดียวกับไอคอน LINE ของจริง
/// สามช่องจึงอ่านเป็นชุดเดียวกัน · โชว์เฉพาะช่องทางที่เจ้าของการ์ดกรอกไว้จริง
struct ContactSheet: View {
    /// ปลายทางที่เลือก — ผู้เรียกเป็นคนเปิด (แอปเจ้าของลิงก์ก่อน แล้วค่อยเบราว์เซอร์ในแอป)
    let onPick: (URL) -> Void

    private struct Channel: Identifiable {
        let id: String
        let label: String
        let value: String
        let url: URL
        let tile: AnyView
    }

    private static let tileSize: CGFloat = 56
    private static let tileShape = RoundedRectangle(cornerRadius: 16, style: .continuous)
    private static let phoneTint = Color(red: 1.0, green: 0.55, blue: 0.2)
    private static let mailTint = Color(red: 0.36, green: 0.56, blue: 0.98)

    private var channels: [Channel] {
        let me = Profile.me
        var list: [Channel] = []
        if let url = ProfileField.lineId.contactURL {
            list.append(.init(id: "line", label: "LINE", value: me.lineId, url: url,
                              tile: AnyView(Image("ic-share-line").resizable()
                                .frame(width: Self.tileSize, height: Self.tileSize)
                                .clipShape(Self.tileShape))))
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("ติดต่อ")
                .font(.sh(16, .semibold))
                .foregroundStyle(.white)
                .padding(.top, 24)

            let list = channels
            if list.isEmpty {
                Text("ยังไม่มีช่องทางติดต่อ")
                    .font(.sh(13, .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxHeight: .infinity)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(list) { c in
                        Button {
                            Haptics.impact(.light)
                            onPick(c.url)
                        } label: {
                            VStack(spacing: 8) {
                                c.tile
                                    .overlay(Self.tileShape.strokeBorder(.white.opacity(0.14), lineWidth: 0.8))
                                VStack(spacing: 2) {
                                    Text(c.label)
                                        .font(.sh(13, .semibold))
                                        .foregroundStyle(.white)
                                    // ค่าจริงใต้ป้าย — คนดูรู้ก่อนกดว่าจะโทรเบอร์ไหน ทักไอดีไหน
                                    Text(c.value)
                                        .font(.sh(10.5, .medium))
                                        .foregroundStyle(.white.opacity(0.5))
                                        .lineLimit(1).truncationMode(.middle)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(DockPress())
                    }
                }
                .padding(.horizontal, 20)
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func glyph(_ image: Image, tint: Color) -> some View {
        image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .frame(width: Self.tileSize, height: Self.tileSize)
            .background(tint.gradient, in: Self.tileShape)
    }
}
