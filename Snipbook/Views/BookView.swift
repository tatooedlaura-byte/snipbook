import SwiftUI
import SwiftData

/// Main view showing the scrollable book with all pages
struct BookView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.createdAt, order: .reverse) private var books: [Book]

    @State private var showingShapePicker = false
    @State private var showingCapture = false
    @State private var showingSettings = false
    @State private var selectedShape: ShapeType = .postageStamp
    @State private var lastAddedSnip: Snip?
    @State private var showUndoBanner = false

    private var currentBook: Book {
        if let book = books.first {
            return book
        } else {
            // Create default book if none exists
            let newBook = Book()
            modelContext.insert(newBook)
            return newBook
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.96, green: 0.95, blue: 0.93)
                    .ignoresSafeArea()

                // Book content
                bookContent

                // Floating add button
                addButton

                // Undo banner
                if showUndoBanner {
                    undoBanner
                }
            }
            .navigationTitle(currentBook.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingShapePicker) {
                ShapePickerView(selectedShape: $selectedShape) {
                    showingShapePicker = false
                    showingCapture = true
                }
            }
            .fullScreenCover(isPresented: $showingCapture) {
                CaptureView(
                    selectedShape: selectedShape,
                    onCapture: { imageData in
                        addSnipToBook(imageData: imageData)
                    },
                    onCancel: {
                        showingCapture = false
                    }
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(book: currentBook)
            }
        }
    }

    // MARK: - Book Content

    private var bookContent: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Book header
                bookHeader

                // Pages
                if currentBook.pages.isEmpty {
                    emptyBookView
                } else {
                    ForEach(Array(currentBook.sortedPages.enumerated()), id: \.element.id) { index, page in
                        PageView(
                            page: page,
                            pageNumber: index + 1,
                            backgroundTexture: currentBook.backgroundTexture
                        )
                        .padding(.horizontal, 20)
                    }
                }

                // Bottom spacing
                Color.clear.frame(height: 100)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Book Header

    private var bookHeader: some View {
        VStack(spacing: 8) {
            Text("Little Moments, Cut & Kept")
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Label("\(currentBook.snipCount)", systemImage: "scissors")
                Label("\(currentBook.pageCount)", systemImage: "book.pages")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Empty Book View

    private var emptyBookView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.4))

            VStack(spacing: 8) {
                Text("Your book is empty")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("Tap the + button to add your first snip")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Spacer()
        }
        .frame(height: 300)
    }

    // MARK: - Add Button

    private var addButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showingShapePicker = true }) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(Color.accentColor)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Undo Banner

    private var undoBanner: some View {
        VStack {
            Spacer()
            HStack {
                Text("Snip added")
                    .foregroundColor(.white)
                Spacer()
                Button("Undo") {
                    undoLastSnip()
                }
                .foregroundColor(.white.opacity(0.9))
                .fontWeight(.medium)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func addSnipToBook(imageData: Data) {
        let snip = Snip(maskedImageData: imageData, shapeType: selectedShape)
        currentBook.addSnip(snip)
        lastAddedSnip = snip

        // Show undo banner briefly
        withAnimation {
            showUndoBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showUndoBanner = false
            }
        }
    }

    private func undoLastSnip() {
        guard let snip = lastAddedSnip else { return }

        // Find and remove the snip
        for page in currentBook.pages {
            if let index = page.snips.firstIndex(where: { $0.id == snip.id }) {
                page.snips.remove(at: index)

                // Remove empty pages
                if page.isEmpty {
                    modelContext.delete(page)
                }
                break
            }
        }

        lastAddedSnip = nil
        withAnimation {
            showUndoBanner = false
        }
    }
}

#Preview {
    BookView()
        .modelContainer(for: [Book.self, Page.self, Snip.self], inMemory: true)
}
