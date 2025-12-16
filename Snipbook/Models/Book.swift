import Foundation
import SwiftData

@Model
final class Book {
    var id: UUID
    var title: String
    var createdAt: Date
    var backgroundTexture: String

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

    init(title: String = "My Snipbook") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.backgroundTexture = "paper-cream"
        self.pages = []
    }

    func addSnip(_ snip: Snip) {
        // Find or create a page with space
        if let page = sortedPages.last, !page.isFull {
            page.addSnip(snip)
        } else {
            let newPage = Page(orderIndex: pages.count)
            newPage.addSnip(snip)
            pages.append(newPage)
        }
    }

    func createNewPage() -> Page {
        let newPage = Page(orderIndex: pages.count)
        pages.append(newPage)
        return newPage
    }
}
