import Foundation
import SwiftData

@Model
final class Book {
    var id: UUID
    var title: String
    var createdAt: Date
    var backgroundTexture: String
    var backgroundPattern: String = "none"
    var snipsPerPage: Int = 4

    // Cover properties
    var coverType: String = "auto"  // "auto", "snip", "custom"
    var coverSnipId: UUID?          // For "snip" type - ID of selected snip
    @Attribute(.externalStorage) var customCoverData: Data?  // For "custom" type

    @Relationship(deleteRule: .cascade) var pages: [Page]

    var sortedPages: [Page] {
        pages.sorted { $0.orderIndex < $1.orderIndex }
    }

    var currentPage: Page? {
        sortedPages.last
    }

    var pageCount: Int {
        pages.count
    }

    var snipCount: Int {
        pages.reduce(0) { $0 + $1.snips.count }
    }

    /// All snips in the book, sorted by creation date (newest first)
    var allSnips: [Snip] {
        pages.flatMap { $0.snips }.sorted { $0.createdAt > $1.createdAt }
    }

    /// The snip selected as the cover (if coverType is "snip")
    var coverSnip: Snip? {
        guard let snipId = coverSnipId else { return nil }
        return pages.flatMap { $0.snips }.first { $0.id == snipId }
    }

    init(title: String = "My Snipbook") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.backgroundTexture = "paper-cream"
        self.pages = []
    }

    func addSnip(_ snip: Snip) {
        // Find or create a page with space
        if let page = sortedPages.last, page.snips.count < snipsPerPage {
            page.snips.append(snip)
        } else {
            let newPage = Page(orderIndex: pages.count)
            newPage.snips.append(snip)
            pages.append(newPage)
        }
    }

    func createNewPage() -> Page {
        let newPage = Page(orderIndex: pages.count)
        pages.append(newPage)
        return newPage
    }

    /// Rebalances snips across pages after deletion to fill gaps
    func rebalancePages() {
        // Collect all snips in order
        var allSnips: [Snip] = []
        for page in sortedPages {
            allSnips.append(contentsOf: page.snips)
        }

        // Clear all pages
        for page in pages {
            page.snips.removeAll()
        }

        // Redistribute snips based on snipsPerPage setting
        var pageIndex = 0
        for snip in allSnips {
            // Get or create page at index
            while pageIndex >= pages.count {
                let newPage = Page(orderIndex: pages.count)
                pages.append(newPage)
            }

            let page = sortedPages[pageIndex]
            page.snips.append(snip)

            // Move to next page if this one is full
            if page.snips.count >= snipsPerPage {
                pageIndex += 1
            }
        }

        // Update order indices
        for (index, page) in sortedPages.enumerated() {
            page.orderIndex = index
        }
    }
}
