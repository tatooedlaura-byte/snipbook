import SwiftUI
import SwiftData

/// Main view showing the scrollable book with all pages
struct BookView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var book: Book

    @State private var showingShapePicker = false
    @State private var showingCapture = false
    @State private var showingSettings = false
    @State private var selectedShape: ShapeType = .postageStamp
    @State private var lastAddedSnip: Snip?
    @State private var showUndoBanner = false
    @State private var currentPageIndex = 0
    @State private var pageZoom: CGFloat = 1.0
    @State private var lastPageZoom: CGFloat = 1.0
    @State private var pageOffset: CGSize = .zero
    @State private var lastPageOffset: CGSize = .zero
    @StateObject private var locationService = LocationService()

    var body: some View {
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingCapture = true
                }
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
            SettingsView(book: book)
        }
    }

    // MARK: - Book Content

    private var bookContent: some View {
        VStack(spacing: 24) {
            // Book header
            bookHeader
                .padding(.top, 16)

            // Pages
            if book.pages.isEmpty {
                emptyBookView
            } else {
                PageFlipView(
                    pages: book.sortedPages,
                    backgroundTexture: book.backgroundTexture,
                    bookTitle: book.title,
                    currentPageIndex: $currentPageIndex
                )
                .frame(height: 400)
                .scaleEffect(pageZoom)
                .offset(pageOffset)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            let newZoom = lastPageZoom * value.magnification
                            pageZoom = min(max(newZoom, 1.0), 3.0)
                        }
                        .onEnded { _ in
                            lastPageZoom = pageZoom
                            if pageZoom <= 1.0 {
                                withAnimation(.spring()) {
                                    pageOffset = .zero
                                    lastPageOffset = .zero
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if pageZoom > 1.0 {
                                pageOffset = CGSize(
                                    width: lastPageOffset.width + value.translation.width,
                                    height: lastPageOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastPageOffset = pageOffset
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        if pageZoom > 1.0 {
                            pageZoom = 1.0
                            lastPageZoom = 1.0
                            pageOffset = .zero
                            lastPageOffset = .zero
                        } else {
                            pageZoom = 2.0
                            lastPageZoom = 2.0
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
    }

    // MARK: - Book Header

    private var bookHeader: some View {
        VStack(spacing: 8) {
            Text("Little Moments, Cut & Kept")
                .font(.custom("Pacifico-Regular", size: 18))
                .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.35))

            HStack(spacing: 16) {
                Label("\(book.snipCount)", systemImage: "scissors")
                Label("\(book.pageCount)", systemImage: "book.pages")
            }
            .font(.custom("Lexend-Regular", size: 12))
            .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.35))
        }
        .padding(.bottom, 8)
    }

    // MARK: - Empty Book View

    private var emptyBookView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))

            VStack(spacing: 8) {
                Text("Your book is empty")
                    .font(.custom("Pacifico-Regular", size: 22))
                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))

                Text("Tap the + button to add your first snip")
                    .font(.custom("Lexend-Regular", size: 14))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
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
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 35, height: 35)
                        .background(
                            Circle()
                                .fill(Color(red: 0.45, green: 0.45, blue: 0.50))
                        )
                }
                .buttonStyle(.plain)
                .padding(.trailing, 24)
                .padding(.bottom, 104)
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
        let snip = Snip(
            maskedImageData: imageData,
            shapeType: selectedShape,
            latitude: locationService.currentLocation?.coordinate.latitude,
            longitude: locationService.currentLocation?.coordinate.longitude,
            locationName: locationService.currentPlaceName
        )
        book.addSnip(snip)
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
        for page in book.pages {
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
    NavigationStack {
        BookView(book: Book())
    }
    .modelContainer(for: [Book.self, Page.self, Snip.self], inMemory: true)
}
