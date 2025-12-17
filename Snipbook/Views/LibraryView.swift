import SwiftUI
import SwiftData

/// Main library view showing all snipbooks
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.createdAt, order: .reverse) private var books: [Book]

    @State private var showingNewBookSheet = false
    @State private var newBookTitle = ""
    @State private var bookToDelete: Book?
    @State private var showingDeleteConfirmation = false
    @State private var bookToEdit: Book?
    @State private var editedTitle = ""
    @State private var showingEditSheet = false
    @State private var selectedBook: Book?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.15, green: 0.15, blue: 0.18)
                    .ignoresSafeArea()

                if books.isEmpty {
                    emptyLibraryView
                } else {
                    booksList
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewBookSheet) {
                newBookSheet
            }
            .sheet(isPresented: $showingEditSheet) {
                editBookSheet
            }
            .alert("Delete Book?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    bookToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let book = bookToDelete {
                        deleteBook(book)
                    }
                }
            } message: {
                if let book = bookToDelete {
                    Text("Are you sure you want to delete \"\(book.title)\"? This will permanently remove all \(book.snipCount) snips in this book. This cannot be undone.")
                }
            }
            .navigationDestination(item: $selectedBook) { book in
                BookView(book: book)
            }
        }
    }

    // MARK: - Empty Library View

    private var emptyLibraryView: some View {
        VStack {
            libraryHeader
                .padding(.top, 16)
            Spacer()
            Text("Tap + to create a snipbook")
                .font(.custom("Lexend-Regular", size: 14))
                .foregroundColor(Color.white.opacity(0.5))
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Library Header

    private var libraryHeader: some View {
        HStack {
            Text("My Library")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Spacer()
            Button(action: { showingNewBookSheet = true }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Books List

    private var booksList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                libraryHeader
                    .padding(.top, 16)

                ForEach(books) { book in
                    BookCard(book: book)
                        .onTapGesture {
                            selectedBook = book
                        }
                        .contextMenu {
                            Button(action: {
                                bookToEdit = book
                                editedTitle = book.title
                                showingEditSheet = true
                            }) {
                                Label("Rename", systemImage: "pencil")
                            }

                            Button(role: .destructive, action: {
                                bookToDelete = book
                                showingDeleteConfirmation = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - New Book Sheet

    private var newBookSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Snipbook Name", text: $newBookTitle)
                } header: {
                    Text("Name your new snipbook")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        newBookTitle = ""
                        showingNewBookSheet = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        createNewBook()
                    }
                    .fontWeight(.semibold)
                    .disabled(newBookTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(200)])
    }

    // MARK: - Edit Book Sheet

    private var editBookSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Snipbook Name", text: $editedTitle)
                } header: {
                    Text("Rename your snipbook")
                }
            }
            .navigationTitle("Edit Snipbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        editedTitle = ""
                        bookToEdit = nil
                        showingEditSheet = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveEditedBook()
                    }
                    .fontWeight(.semibold)
                    .disabled(editedTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(200)])
    }

    // MARK: - Actions

    private func createNewBook() {
        let title = newBookTitle.trimmingCharacters(in: .whitespaces)
        let book = Book(title: title.isEmpty ? "My Snipbook" : title)
        modelContext.insert(book)
        newBookTitle = ""
        showingNewBookSheet = false

        // Navigate to the new book
        selectedBook = book
    }

    private func saveEditedBook() {
        if let book = bookToEdit {
            book.title = editedTitle.trimmingCharacters(in: .whitespaces)
        }
        editedTitle = ""
        bookToEdit = nil
        showingEditSheet = false
    }

    private func deleteBook(_ book: Book) {
        modelContext.delete(book)
        bookToDelete = nil
    }
}

// MARK: - Book Card

struct BookCard: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Book cover preview
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .frame(height: 140)

                if book.snipCount > 0 {
                    // Show preview of recent snips
                    HStack(spacing: 8) {
                        ForEach(recentSnips.prefix(3), id: \.id) { snip in
                            if let image = UIImage(data: snip.maskedImageData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 80, maxHeight: 100)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 2)
                            }
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "book.closed")
                            .font(.title)
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Empty")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }

            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.custom("Pacifico-Regular", size: 18))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label("\(book.snipCount)", systemImage: "scissors")
                    Label("\(book.pageCount)", systemImage: "book.pages")
                }
                .font(.custom("Lexend-Regular", size: 12))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private var backgroundColor: Color {
        switch book.backgroundTexture {
        case "paper-cream": return Color(red: 0.98, green: 0.96, blue: 0.93)
        case "paper-butter": return Color(red: 0.98, green: 0.95, blue: 0.86)
        case "paper-blush": return Color(red: 0.97, green: 0.91, blue: 0.89)
        case "paper-linen": return Color(red: 0.95, green: 0.92, blue: 0.88)
        case "paper-white": return Color(red: 0.99, green: 0.99, blue: 0.99)
        case "paper-gray": return Color(red: 0.94, green: 0.94, blue: 0.94)
        case "paper-newsprint": return Color(red: 0.91, green: 0.89, blue: 0.86)
        case "paper-kraft": return Color(red: 0.85, green: 0.78, blue: 0.70)
        case "paper-sage": return Color(red: 0.91, green: 0.93, blue: 0.90)
        case "paper-sky": return Color(red: 0.90, green: 0.93, blue: 0.96)
        case "paper-lavender": return Color(red: 0.93, green: 0.91, blue: 0.95)
        case "paper-midnight": return Color(red: 0.17, green: 0.24, blue: 0.31)
        default: return Color(red: 0.98, green: 0.96, blue: 0.93)
        }
    }

    private var recentSnips: [Snip] {
        book.sortedPages
            .flatMap { $0.snips }
            .sorted { $0.createdAt > $1.createdAt }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [Book.self, Page.self, Snip.self], inMemory: true)
}
