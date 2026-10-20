import SwiftUI

// MARK: - ชิ้นส่วนของถาดชุดห้าสไตล์
//
// ตามกติกาตัวควบคุมของแอป: หลายตัวเลือก = ช่องติ๊กที่มองเห็น · จำนวน = − n + · ของเสริม = สวิตช์
// (ชิปเปล่าที่กดแล้วสลับสีอ่านไม่ออกว่าเลือกอยู่หรือไม่ — ผู้ใช้เคยปฏิเสธ)

/// แถวสี — วงกลมเรียง แตะแล้วมีวงแหวนรอบสีที่เลือก
struct KitSwatches: View {
    /// ค่าที่เก็บ — hex หรือโทเคนสีของการ์ด
    let colors: [String]
    /// แปลงค่าที่เก็บเป็น hex ที่วาดได้ (โทเคนของการ์ด → สีตามธีมตอนนี้)
    var display: (String) -> String = { $0 }
    let selected: String
    /// ชิปแรก = ค่าตั้งต้นของสไตล์ — มีเส้นคั่นหลังมัน แยกจากสีของการ์ด
    var firstIsDefault = false
    let onPick: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(Array(colors.enumerated()), id: \.offset) { i, token in
                    let on = token.lowercased() == selected.lowercased()
                    Button { onPick(token) } label: {
                        Circle().fill(Color(kitHex: display(token)))
                            .overlay(Circle().strokeBorder(.white.opacity(0.22), lineWidth: 0.8))
                            .frame(width: 26, height: 26)
                            .padding(3)
                            .overlay(Circle().strokeBorder(on ? .white : .clear, lineWidth: 2))
                            .contentShape(Circle())
                    }
                    .buttonStyle(DockPress())
                    .accessibilityLabel(i == 0 && firstIsDefault ? "สีของสไตล์" : "สีจากพื้นหลังการ์ด")
                    if i == 0 && firstIsDefault {
                        Rectangle().fill(.white.opacity(0.18)).frame(width: 1, height: 22)
                    }
                }
            }
            .padding(.vertical, 1)
        }
    }
}

/// ช่องติ๊ก — ขึ้นบรรทัดใหม่เองเมื่อเต็ม · ช่องสุดท้ายที่ติ๊กอยู่เอาออกไม่ได้
struct KitCheckRow: View {
    let items: [(String, String)]
    let hidden: Set<String>
    var minShown = 1
    let shownCount: Int
    let onToggle: (String) -> Void

    var body: some View {
        KitWrap(spacing: 6) {
            ForEach(items, id: \.0) { key, title in
                let on = !hidden.contains(key)
                let locked = on && shownCount <= minShown
                Button { if !locked { onToggle(key) } } label: {
                    HStack(spacing: 6) {
                        Image(systemName: on ? "checkmark.square.fill" : "square")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(on ? .white : .white.opacity(0.45))
                        Text(title).font(.sh(12, .semibold))
                            .foregroundStyle(.white.opacity(on ? 0.92 : 0.55))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10).frame(height: 30)
                    .background(Capsule().fill(.white.opacity(on ? 0.12 : 0.05)))
                    .opacity(locked ? 0.6 : 1)
                    .contentShape(Capsule())
                }
                .buttonStyle(DockPress())
            }
        }
    }
}

/// − n + — ค่าที่เลือกได้เป็นขั้น (เช่น 1 · 2 · 4 · 6)
struct KitStepper: View {
    let values: [Int]
    let value: Int
    let onChange: (Int) -> Void

    var body: some View {
        let i = values.firstIndex(of: value) ?? 0
        HStack(spacing: 0) {
            step("minus", enabled: i > 0) { onChange(values[i - 1]) }
            Text("\(value)").font(.sh(14, .bold)).foregroundStyle(.white)
                .monospacedDigit().frame(width: 40)
            step("plus", enabled: i < values.count - 1) { onChange(values[i + 1]) }
        }
        .frame(height: 32)
        .background(Capsule().fill(Color.black.opacity(0.28)))
    }

    private func step(_ sym: String, enabled: Bool, _ act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Image(systemName: sym).font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(enabled ? 0.9 : 0.25))
                .frame(width: 40, height: 32).contentShape(Rectangle())
        }
        .buttonStyle(DockPress())
        .disabled(!enabled)
    }
}

/// แถวสวิตช์ — ป้ายซ้าย สวิตช์ขวา
struct KitSwitchRow: View {
    let label: String
    let on: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        HStack {
            Text(label).font(.sh(12, .semibold)).foregroundStyle(.white.opacity(0.8))
            Spacer()
            Toggle("", isOn: Binding(get: { on }, set: { onChange($0) }))
                .labelsHidden().tint(Color(red: 0.2, green: 0.78, blue: 0.35))
        }
    }
}
