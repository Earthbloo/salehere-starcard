import UIKit
@preconcurrency import Vision

/// อ่านตัวเลขจากรูปแคปหน้า Insights (เพศ · ช่วงอายุ · พื้นที่) ในเครื่อง ด้วย Vision
/// ของจริง = `analyzeSocialProfileInsight` ฝั่ง backend — ตัวนี้ใช้แทนในต้นแบบ ผู้ใช้จึงไม่ต้องพิมพ์ตัวเลขเอง
nonisolated enum InsightReader {
    /// ป้าย + % ตามหัวข้อ (`gender` · `age` · `location`) — อ่านไม่ออก = ว่าง
    static func read(_ image: UIImage, slot: String) async -> [InsightSeg] {
        let pairs = pairs(await lines(image))
        switch slot {
        case "gender": return gender(pairs)
        case "age": return age(pairs)
        default: return location(pairs)
        }
    }

    // MARK: OCR → บรรทัด

    private static func lines(_ image: UIImage) async -> [String] {
        guard let cg = image.cgImage else { return [] }
        return await withCheckedContinuation { c in
            let req = VNRecognizeTextRequest { req, _ in
                let obs = (req.results as? [VNRecognizedTextObservation]) ?? []
                c.resume(returning: group(obs))
            }
            req.recognitionLevel = .accurate
            req.usesLanguageCorrection = false
            let want = ["th-TH", "en-US"]
            let have = (try? req.supportedRecognitionLanguages()) ?? ["en-US"]
            req.recognitionLanguages = want.filter(have.contains)
            DispatchQueue.global(qos: .userInitiated).async {
                do { try VNImageRequestHandler(cgImage: cg, orientation: .up).perform([req]) }
                catch { c.resume(returning: []) }
            }
        }
    }

    /// ข้อความที่อยู่แถวเดียวกัน (กลางแนวตั้งใกล้กัน) ต่อเป็นบรรทัดเดียว เรียงบนลงล่าง ซ้ายไปขวา
    private static func group(_ obs: [VNRecognizedTextObservation]) -> [String] {
        let items = obs.compactMap { o in o.topCandidates(1).first.map { (box: o.boundingBox, text: $0.string) } }
            .sorted { $0.box.midY > $1.box.midY }
        var rows: [[(box: CGRect, text: String)]] = []
        for it in items {
            if let last = rows.last?.last, abs(last.box.midY - it.box.midY) < min(last.box.height, it.box.height) * 0.6 {
                rows[rows.count - 1].append(it)
            } else {
                rows.append([it])
            }
        }
        return rows.map { $0.sorted { $0.box.minX < $1.box.minX }.map(\.text).joined(separator: " ") }
    }

    // MARK: บรรทัด → (ป้าย, %)

    private static let pctRe = try! NSRegularExpression(pattern: #"(\d{1,3}(?:[.,]\d+)?)\s*%"#)

    /// ป้ายอยู่หน้า % ในบรรทัดเดียวกัน หรืออยู่บรรทัดก่อนหน้า (ป้ายเหนือตัวเลข · หลายคอลัมน์ = แยกคำจับคู่ตามลำดับ)
    private static func pairs(_ lines: [String]) -> [(label: String, pct: Double)] {
        var out: [(String, Double)] = []
        var pending: String?
        for line in lines {
            let ns = line as NSString
            let ms = pctRe.matches(in: line, range: NSRange(location: 0, length: ns.length))
            guard !ms.isEmpty else {
                let t = line.trimmingCharacters(in: .whitespaces)
                pending = t.isEmpty || t.count > 40 ? nil : t
                continue
            }
            var cursor = 0
            var found: [(String, Double)] = []
            for m in ms {
                let label = clean(ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor)))
                let num = Double(ns.substring(with: m.range(at: 1)).replacingOccurrences(of: ",", with: ".")) ?? 0
                found.append((label, num))
                cursor = m.range.location + m.range.length
            }
            if found.allSatisfy({ $0.0.isEmpty }), let pending {
                let words = pending.split(separator: " ").map(String.init)
                if found.count > 1, words.count == found.count {
                    found = zip(words, found).map { ($0, $1.1) }
                } else if found.count == 1 {
                    found[0].0 = clean(pending)
                }
            }
            out += found.filter { !$0.0.isEmpty && $0.1 > 0 && $0.1 <= 100 }
            pending = nil
        }
        return out
    }

    /// ตัดเลขลำดับ จุด ขีด ออกจากหัวป้าย
    private static func clean(_ s: String) -> String {
        s.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "·•-–—:|")))
            .replacingOccurrences(of: #"^\d{1,2}[.)]?\s+"#, with: "", options: .regularExpression)
    }

    // MARK: แยกตามหัวข้อ

    private static func gender(_ p: [(label: String, pct: Double)]) -> [InsightSeg] {
        var f: Double?, m: Double?, o: Double?
        for (label, pct) in p {
            let l = label.lowercased()
            if l.contains("หญิง") || l.contains("women") || l.contains("female") { f = f ?? pct }
            else if l.contains("ชาย") || l.contains("men") || l.contains("male") { m = m ?? pct }
            else if l.contains("อื่น") || l.contains("other") || l.contains("ไม่ระบุ") { o = o ?? pct }
        }
        return [("หญิง", f), ("ชาย", m), ("อื่น ๆ", o)].compactMap { l, v in v.map { InsightSeg(label: l, pct: $0) } }
    }

    private static let ageRe = try! NSRegularExpression(pattern: #"(\d{2})\s*(?:[-–—]\s*\d{2}|\+)"#)

    /// ช่วงของแพลตฟอร์ม (13-17 … 65+) รวมเข้าช่วงที่การ์ดใช้ — 45 ขึ้นไปรวมเป็นช่องเดียว
    private static func age(_ p: [(label: String, pct: Double)]) -> [InsightSeg] {
        var seen: Set<Int> = []
        var buckets: [String: Double] = [:]
        for (label, pct) in p {
            let ns = label as NSString
            guard let m = ageRe.firstMatch(in: label, range: NSRange(location: 0, length: ns.length)),
                  let lo = Int(ns.substring(with: m.range(at: 1))), !seen.contains(lo) else { continue }
            seen.insert(lo)
            let key = lo < 18 ? "13–17 ปี" : lo < 25 ? "18–24 ปี" : lo < 35 ? "25–34 ปี" : lo < 45 ? "35–44 ปี" : "45+ ปี"
            buckets[key, default: 0] += pct
        }
        return ["13–17 ปี", "18–24 ปี", "25–34 ปี", "35–44 ปี", "45+ ปี"].compactMap { k in
            buckets[k].map { InsightSeg(label: k, pct: ($0 * 10).rounded() / 10) }
        }
    }

    /// 3 อันดับแรกที่เป็นชื่อสถานที่ (ไม่ใช่ช่วงอายุ/เพศ)
    private static func location(_ p: [(label: String, pct: Double)]) -> [InsightSeg] {
        var out: [InsightSeg] = []
        for (label, pct) in p where out.count < 3 {
            let l = label.lowercased()
            let ns = label as NSString
            if ageRe.firstMatch(in: label, range: NSRange(location: 0, length: ns.length)) != nil { continue }
            if ["หญิง", "ชาย", "women", "men", "male", "female"].contains(where: l.contains) { continue }
            if label.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," || $0 == " " }) { continue }
            if out.contains(where: { $0.label == label }) { continue }
            out.append(InsightSeg(label: label, pct: pct))
        }
        return out
    }
}
