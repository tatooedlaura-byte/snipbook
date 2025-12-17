import Foundation
import SwiftData

@Model
final class Page {
    var id: UUID
    var createdAt: Date
    var orderIndex: Int

    @Relationship(deleteRule: .cascade) var snips: [Snip]
    @Relationship(inverse: \Book.pages) var book: Book?

    var isFull: Bool {
        snips.count >= 4
    }

    var isEmpty: Bool {
        snips.isEmpty
    }

    init(orderIndex: Int = 0) {
        self.id = UUID()
        self.createdAt = Date()
        self.orderIndex = orderIndex
        self.snips = []
    }

    func addSnip(_ snip: Snip) {
        guard !isFull else { return }
        snips.append(snip)
    }
}
