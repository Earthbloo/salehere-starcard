// PNG ตัดพื้น (Apple Vision) ของรูปที่อยู่ในคลังแล้ว → เพิ่มลง photos/cutouts.json {รูปต้นฉบับ: รูปตัดพื้น}
// ใช้: swift cutout.swift <imageDir> <cutouts.json> <photoId>...
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Vision
import CoreImage
import CryptoKit

let args = CommandLine.arguments
let imageDir = URL(fileURLWithPath: args[1])
let outJSON = URL(fileURLWithPath: args[2])

func load(_ path: String) -> CGImage {
  let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!
  return CGImageSourceCreateImageAtIndex(src, 0, nil)!
}
func rgba(_ img: CGImage) -> [UInt8] {
  let w = img.width, h = img.height
  var buf = [UInt8](repeating: 0, count: w * h * 4)
  let ctx = CGContext(data: &buf, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
  return buf
}
let WHITE = UInt8(ProcessInfo.processInfo.environment["WHITE"].flatMap { Int($0) } ?? 238)
let GAP = Double(ProcessInfo.processInfo.environment["GAP"] ?? "0.97")!
func white(_ p: [UInt8], _ w: Int, _ x: Int, _ y: Int) -> Bool { let i = (y * w + x) * 4; return p[i] > WHITE && p[i + 1] > WHITE && p[i + 2] > WHITE }
/// ช่วงที่ไม่ใช่เส้นขาว ตามแนว (เส้นขาว = ≥97% ของพิกเซลในแนวตั้งฉากเป็นสีขาว)
func segments(count: Int, isGap: (Int) -> Bool, minLen: Int) -> [(Int, Int)] {
  var out: [(Int, Int)] = [], start: Int? = nil
  for i in 0..<count { if isGap(i) { if let s = start { if i - s >= minLen { out.append((s, i)) }; start = nil } } else if start == nil { start = i } }
  if let s = start, count - s >= minLen { out.append((s, count)) }
  return out
}
func encode(_ img: CGImage, type: UTType, quality: Double = 0.9) -> Data {
  let data = NSMutableData()
  let dest = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(dest, img, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
  CGImageDestinationFinalize(dest)
  return data as Data
}
func save(_ data: Data, mime: String) -> String {
  let id = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
  try! data.write(to: imageDir.appendingPathComponent(id))
  try! mime.data(using: .utf8)!.write(to: imageDir.appendingPathComponent(id + ".type"))
  return id
}
/// คนบนพื้นโปร่ง ครอปชิดตัว (ขอบล่างคงไว้ = เท้า/ตัวชนขอบ)
func cutout(_ img: CGImage) -> CGImage? {
  let req = VNGenerateForegroundInstanceMaskRequest()
  let handler = VNImageRequestHandler(cgImage: img)
  do { try handler.perform([req]) } catch { FileHandle.standardError.write("vision: \(error)\n".data(using: .utf8)!); return nil }
  guard let obs = req.results?.first, !obs.allInstances.isEmpty else { return nil }
  guard let buf = try? obs.generateMaskedImage(ofInstances: obs.allInstances, from: handler, croppedToInstancesExtent: false) else { return nil }
  let ci = CIImage(cvPixelBuffer: buf)
  let ctx = CIContext()
  guard let full = ctx.createCGImage(ci, from: ci.extent) else { return nil }
  // ครอปชิดส่วนที่ทึบ
  let p = rgba(full), w = full.width, h = full.height
  var minX = w, minY = h, maxX = 0, maxY = 0
  for y in stride(from: 0, to: h, by: 2) { for x in stride(from: 0, to: w, by: 2) where p[(y * w + x) * 4 + 3] > 20 { minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y) } }
  if maxX <= minX || maxY <= minY { return nil }
  let pad = 6
  let r = CGRect(x: max(0, minX - pad), y: max(0, minY - pad), width: min(w, maxX + pad) - max(0, minX - pad), height: min(h, maxY + pad) - max(0, minY - pad))
  return full.cropping(to: r)
}


var map = (try? JSONSerialization.jsonObject(with: Data(contentsOf: outJSON))) as? [String: String] ?? [:]
for id in args.dropFirst(3) {
  let img = load(imageDir.appendingPathComponent(id).path)
  if let cut = cutout(img) { map[id] = save(encode(cut, type: .png), mime: "image/png"); print(id, "→", map[id]!, cut.width, "x", cut.height) } else { print(id, "ตัดไม่ได้") }
}
try! JSONSerialization.data(withJSONObject: map, options: [.prettyPrinted, .sortedKeys]).write(to: outJSON)
