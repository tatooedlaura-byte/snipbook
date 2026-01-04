import SwiftUI

/// Grid view for selecting a snip as the book cover
struct CoverPickerView: View {
    @Bindable var book: Book
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if book.allSnips.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(book.allSnips, id: \.id) { snip in
                            snipCell(snip)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Choose Cover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func snipCell(_ snip: Snip) -> some View {
        let isSelected = book.coverSnipId == snip.id

        return Button {
            book.coverSnipId = snip.id
            book.coverType = "snip"
            dismiss()
        } label: {
            ZStack {
                if let image = UIImage(data: snip.maskedImageData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                }

                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 3)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                // Checkmark for selected
                Group {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .background(Circle().fill(Color.white))
                            .offset(x: -4, y: -4)
                    }
                },
                alignment: .topTrailing
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No snips yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Add some snips to your book first")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    CoverPickerView(book: Book())
        .modelContainer(for: [Book.self, Page.self, Snip.self], inMemory: true)
}
