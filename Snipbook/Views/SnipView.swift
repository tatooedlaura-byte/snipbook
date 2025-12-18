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

/// Full screen detail view for a snip
struct SnipDetailView: View {
    @Bindable var snip: Snip
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with delete and close buttons
                HStack {
                    Button(action: { showingDeleteConfirmation = true }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title)
                            .foregroundColor(.red.opacity(0.8))
                            .padding()
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

                // Image in the middle - large and prominent
                if let image = UIImage(data: snip.maskedImageData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.9,
                               maxHeight: UIScreen.main.bounds.height * 0.65)
                        .shadow(color: .white.opacity(0.1), radius: 20)
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
    }
}

#Preview {
    // Preview with mock data
    VStack {
        Text("Snip Preview")
    }
}
