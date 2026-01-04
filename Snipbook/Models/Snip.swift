import Foundation
import SwiftData

@Model
final class Snip {
    var id: UUID
    @Attribute(.externalStorage) var maskedImageData: Data
    var shapeTypeRaw: String
    var createdAt: Date

    // Location data
    var latitude: Double?
    var longitude: Double?
    var locationName: String?

    // User-editable name
    var name: String?

    // Order within page (for drag-and-drop reordering)
    var orderIndex: Int = 0

    @Relationship(inverse: \Page.snips) var page: Page?

    var shapeType: ShapeType {
        get { ShapeType(rawValue: shapeTypeRaw) ?? .rectangle }
        set { shapeTypeRaw = newValue.rawValue }
    }

    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    init(maskedImageData: Data, shapeType: ShapeType, latitude: Double? = nil, longitude: Double? = nil, locationName: String? = nil) {
        self.id = UUID()
        self.maskedImageData = maskedImageData
        self.shapeTypeRaw = shapeType.rawValue
        self.createdAt = Date()
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
    }
}
