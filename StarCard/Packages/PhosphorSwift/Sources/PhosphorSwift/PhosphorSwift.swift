//
//  PhosphorSwift.swift — ชุดย่อยของ https://github.com/phosphor-icons/swift (2.1.0, MIT)
//
//  แพ็กเกจต้นทางมี asset ~9,000 ไฟล์ (71 MB) — `actool` ใช้เวลาเกือบ 20 นาทีทุก clean build
//  จึงคัดมาเฉพาะไอคอนที่แอปใช้ ในน้ำหนัก regular · bold · fill โดยคง API เดิม (`Ph.check.bold`)
//  เพิ่มไอคอน: คัดลอก `<name>.imageset` `<name>-bold.imageset` `<name>-fill.imageset`
//  จาก Sources/PhosphorSwift/Resources/Assets.xcassets/SVG ของ repo ต้นทางมาไว้ที่โฟลเดอร์เดียวกันที่นี่ แล้วเพิ่ม case
//

import SwiftUI

public enum Ph: String, CaseIterable, Identifiable {
    public var id: Self { self }

    case arrowRight = "arrow-right"
    case arrowUpRight = "arrow-up-right"
    case arrowsClockwise = "arrows-clockwise"
    case briefcase = "briefcase"
    case broadcast = "broadcast"
    case browsers = "browsers"
    case buildings = "buildings"
    case calendarDots = "calendar-dots"
    case camera = "camera"
    case caretDown = "caret-down"
    case caretLeft = "caret-left"
    case caretRight = "caret-right"
    case caretUpDown = "caret-up-down"
    case check = "check"
    case checkCircle = "check-circle"
    case circleDashed = "circle-dashed"
    case circleHalf = "circle-half"
    case clock = "clock"
    case creditCard = "credit-card"
    case fileImage = "file-image"
    case hourglass = "hourglass"
    case info = "info"
    case lightning = "lightning"
    case link = "link"
    case listChecks = "list-checks"
    case lock = "lock"
    case lockOpen = "lock-open"
    case magicWand = "magic-wand"
    case paperPlaneTilt = "paper-plane-tilt"
    case pencilSimple = "pencil-simple"
    case plus = "plus"
    case sealCheck = "seal-check"
    case sparkle = "sparkle"
    case star = "star"
    case student = "student"
    case sunHorizon = "sun-horizon"
    case user = "user"
    case userCircle = "user-circle"
    case warning = "warning"
    case warningCircle = "warning-circle"
    case x = "x"
    case xCircle = "x-circle"
    case prohibit = "prohibit"
    case handsPraying = "hands-praying"
    case genderIntersex = "gender-intersex"
    case cake = "cake"
    case plusCircle = "plus-circle"
    case headset = "headset"
    case bell = "bell"
    case shareFat = "share-fat"
    case calendarBlank = "calendar-blank"
    case qrCode = "qr-code"
    case identificationCard = "identification-card"
    case ticket = "ticket"
    case squaresFour = "squares-four"
    case list = "list"
    case at = "at"
    case chatCircleText = "chat-circle-text"
    case clipboardText = "clipboard-text"
    case notePencil = "note-pencil"
    case imageSquare = "image-square"
    case videoCamera = "video-camera"
    case chatCircle = "chat-circle"
    case shareNetwork = "share-network"
    case house = "house"
    case coins = "coins"
    case textAlignLeft = "text-align-left"
    case usersThree = "users-three"
    case mapPin = "map-pin"
    case bank = "bank"
    case package = "package"
    case eye = "eye"
    case gift = "gift"
    case chartBar = "chart-bar"
}

public extension Ph {
    enum IconWeight: String, CaseIterable, Identifiable {
        public var id: Self { self }
        case regular, bold, fill
    }

    var regular: Image { Ph.icon(rawValue) }
    var bold: Image { Ph.icon("\(rawValue)-bold") }
    var fill: Image { Ph.icon("\(rawValue)-fill") }

    func weight(_ weight: IconWeight) -> Image {
        switch weight {
        case .regular: return regular
        case .bold:    return bold
        case .fill:    return fill
        }
    }

    private static func icon(_ name: String) -> Image {
        Image(name, bundle: .module)
            .interpolation(.medium)
            .resizable()
    }
}
