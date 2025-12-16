import Foundation
import SwiftData

@Model
final class Snip {
    var id: UUID
    @Attribute(.externalStorage) var maskedImageData: Data
    var shapeTypeRaw: String
    var createdAt: Date

    @Relationship(inverse: \Page.snips) var page: Page?

    var shapeType: ShapeType {
        get { ShapeType(rawValue: shapeTypeRaw) ?? .rectangle }
        set { shapeTypeRaw = newValue.rawValue }
    }

    init(maskedImageData: Data, shapeType: ShapeType) {
        self.id = UUID()
        self.maskedImageData = maskedImageData
        self.shapeTypeRaw = shapeType.rawValue
        self.createdAt = Date()
    }
}
