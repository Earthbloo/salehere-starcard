// swift-tools-version: 5.9
import PackageDescription

// ชุดย่อยของ phosphor-icons/swift 2.1.0 (MIT) — เฉพาะไอคอนที่แอปใช้ ดู Sources/PhosphorSwift/PhosphorSwift.swift
let package = Package(
    name: "PhosphorSwift",
    platforms: [.iOS(.v16)],
    products: [.library(name: "PhosphorSwift", targets: ["PhosphorSwift"])],
    targets: [.target(name: "PhosphorSwift", resources: [.process("Resources")])]
)
