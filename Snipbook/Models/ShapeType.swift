import Foundation

enum ShapeType: String, Codable, CaseIterable, Identifiable {
    case postageStamp
    case circle
    case tornPaper
    case rectangle
    case polaroid

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .postageStamp: return "Stamp"
        case .circle: return "Circle"
        case .tornPaper: return "Torn"
        case .rectangle: return "Rectangle"
        case .polaroid: return "Polaroid"
        }
    }

    var iconName: String {
        switch self {
        case .postageStamp: return "stamp"
        case .circle: return "circle"
        case .tornPaper: return "scribble"
        case .rectangle: return "rectangle"
        case .polaroid: return "photo"
        }
    }
}
