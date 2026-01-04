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

    /// Snips sorted by their order index
    var sortedSnips: [Snip] {
        snips.sorted { $0.orderIndex < $1.orderIndex }
    }

    init(orderIndex: Int = 0) {
        self.id = UUID()
        self.createdAt = Date()
        self.orderIndex = orderIndex
        self.snips = []
    }

    func addSnip(_ snip: Snip) {
        guard !isFull else { return }
        snip.orderIndex = snips.count
        snips.append(snip)
    }

    /// Reorder a snip from one position to another
    func reorderSnip(from sourceIndex: Int, to destinationIndex: Int) {
        var sorted = sortedSnips
        guard sourceIndex >= 0, sourceIndex < sorted.count,
              destinationIndex >= 0, destinationIndex < sorted.count else { return }

        let snip = sorted.remove(at: sourceIndex)
        sorted.insert(snip, at: destinationIndex)

        // Update all order indices
        for (index, snip) in sorted.enumerated() {
            snip.orderIndex = index
        }
    }

    /// Normalize order indices after changes
    func normalizeOrderIndices() {
        let sorted = snips.sorted { $0.orderIndex < $1.orderIndex }
        for (index, snip) in sorted.enumerated() {
            snip.orderIndex = index
        }
    }
}
