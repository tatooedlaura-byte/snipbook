import SwiftUI
import SwiftData

/// Displays a single snip (masked image) with name below
struct SnipView: View {
    @Environment(\.modelContext) private var modelContext
    let snip: Snip
    var maxSize: CGFloat = 150
    var isDarkBackground: Bool = false
    var onDelete: (() -> Void)? = nil
    @State private var showingDetail = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 6) {
            // Snip image
            if let image = UIImage(data: snip.maskedImageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxSize, maxHeight: maxSize)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 3)
            } else {
                // Fallback placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: maxSize, height: maxSize)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }

            // Name label in Pacifico font
            if let name = snip.name, !name.isEmpty {
                Text(name)
                    .font(.custom("Pacifico-Regular", size: 14))
                    .foregroundColor(isDarkBackground ? .white : Color(red: 0.2, green: 0.2, blue: 0.2))
                    .lineLimit(1)
                    .frame(maxWidth: maxSize)
            }
        }
        .onTapGesture {
            showingDetail = true
        }
        .onLongPressGesture {
            showingDeleteConfirmation = true
        }
        .confirmationDialog("Delete this snip?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteSnip()
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showingDetail) {
            SnipDetailView(snip: snip, onDelete: {
                showingDetail = false
                deleteSnip()
            })
        }
    }

    private func deleteSnip() {
        // Get book reference before modifying
        let book = snip.page?.book

        // Remove from page first
        if let page = snip.page {
            page.snips.removeAll { $0.id == snip.id }
        }

        // Delete the snip
        modelContext.delete(snip)

        // Rebalance pages in the book and remove empty pages
        if let book = book {
            book.rebalancePages()
            // Remove any empty pages
            for page in book.pages where page.isEmpty {
                modelContext.delete(page)
            }
        }

        onDelete?()
    }
}

/// Notification for requesting snip edit
extension Notification.Name {
    static let editSnipRequested = Notification.Name("editSnipRequested")
}

/// Full screen detail view for a snip
struct SnipDetailView: View {
    @Bindable var snip: Snip
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingShareSheet = false

    // Zoom and pan state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Image fills most of the screen with pinch-to-zoom
            if let image = UIImage(data: snip.maskedImageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.95,
                           maxHeight: UIScreen.main.bounds.height * 0.70)
                    .shadow(color: .white.opacity(0.1), radius: 20)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                let newScale = lastScale * value.magnification
                                scale = min(max(newScale, 1.0), 5.0)
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale == 1.0 {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            if scale > 1.0 {
                                // Reset zoom
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                // Zoom in to 2x
                                scale = 2.0
                                lastScale = 2.0
                            }
                        }
                    }
            }

            VStack {
                // Top bar with delete, share, edit, and close buttons
                HStack {
                    Button(action: { showingDeleteConfirmation = true }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title)
                            .foregroundColor(.red.opacity(0.8))
                            .padding()
                    }

                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical)
                    }

                    Button(action: requestEdit) {
                        Image(systemName: "scissors.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical)
                    }

                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }

                Spacer()

                // Info section below image - compact
                VStack(spacing: 12) {
                    // Editable name
                    if isEditingName {
                        TextField("Name this snip", text: $editedName)
                            .font(.custom("Pacifico-Regular", size: 18))
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 250)
                            .onSubmit {
                                snip.name = editedName.isEmpty ? nil : editedName
                                isEditingName = false
                            }
                    } else {
                        Button(action: {
                            editedName = snip.name ?? ""
                            isEditingName = true
                        }) {
                            HStack(spacing: 6) {
                                Text(snip.name ?? "Tap to name")
                                    .font(.custom("Pacifico-Regular", size: 22))
                                    .foregroundColor(snip.name == nil ? .white.opacity(0.5) : .white)
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }

                    // Date and location info - single line when possible
                    HStack(spacing: 12) {
                        Text(snip.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.custom("Lexend-Regular", size: 13))
                            .foregroundColor(.white.opacity(0.7))

                        if let locationName = snip.locationName {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                Text(locationName)
                                    .font(.custom("Lexend-Regular", size: 13))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onTapGesture {
            if isEditingName {
                snip.name = editedName.isEmpty ? nil : editedName
                isEditingName = false
            }
        }
        .confirmationDialog("Delete this snip?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = UIImage(data: snip.maskedImageData) {
                ShareSheet(items: [image])
            }
        }
    }

    private func requestEdit() {
        dismiss()
        // Post notification to trigger edit flow in BookView
        NotificationCenter.default.post(
            name: .editSnipRequested,
            object: snip
        )
    }
}

#Preview {
    // Preview with mock data
    VStack {
        Text("Snip Preview")
    }
}
