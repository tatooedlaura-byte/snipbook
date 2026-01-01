import Foundation

enum ShapeType: String, Codable, CaseIterable, Identifiable {
    case postageStamp
    case circle
    case ticket
    case label
    case tornPaper
    case rectangle
    case polaroid
    case filmstrip

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .postageStamp: return "Stamp"
        case .circle: return "Circle"
        case .ticket: return "Ticket"
        case .label: return "Label"
        case .tornPaper: return "Torn"
        case .rectangle: return "Rectangle"
        case .polaroid: return "Polaroid"
        case .filmstrip: return "Film"
        }
    }

    var iconName: String {
        switch self {
        case .postageStamp: return "stamp"
        case .circle: return "circle"
        case .ticket: return "ticket"
        case .label: return "tag"
        case .tornPaper: return "scribble"
        case .rectangle: return "rectangle"
        case .polaroid: return "photo"
        case .filmstrip: return "film"
        }
    }
}
