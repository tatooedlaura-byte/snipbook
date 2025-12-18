import SwiftUI
import PDFKit

/// Minimal settings screen
struct SettingsView: View {
    @Bindable var book: Book
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportedPDFURL: URL?
    @State private var showExportSuccess = false
    @State private var showShareSheet = false
    @AppStorage("savePhotosToLibrary") private var savePhotosToLibrary = true

    private let textures = [
        // Classic
        ("paper-cream", "Cream"),
        ("paper-white", "White"),
        ("paper-kraft", "Kraft"),
        // Warm & Bright
        ("paper-butter", "Butter"),
        ("paper-sunshine", "Sunshine"),
        ("paper-peach", "Peach"),
        ("paper-coral", "Coral"),
        ("paper-blush", "Blush"),
        ("paper-rose", "Rose"),
        // Cool & Fresh
        ("paper-mint", "Mint"),
        ("paper-seafoam", "Seafoam"),
        ("paper-aqua", "Aqua"),
        ("paper-sky", "Sky"),
        ("paper-periwinkle", "Periwinkle"),
        ("paper-lavender", "Lavender"),
        ("paper-lilac", "Lilac"),
        // Earthy
        ("paper-sage", "Sage"),
        ("paper-olive", "Olive"),
        ("paper-terracotta", "Terracotta"),
        ("paper-linen", "Linen"),
        // Neutral
        ("paper-gray", "Gray"),
        ("paper-newsprint", "Newsprint"),
        // Dark
        ("paper-midnight", "Midnight"),
        ("paper-charcoal", "Charcoal")
    ]

    var body: some View {
        NavigationStack {
            List {
                // Book info section
                Section {
                    HStack {
                        Text("Pages")
                        Spacer()
                        Text("\(book.pageCount)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Snips")
                        Spacer()
                        Text("\(book.snipCount)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Created")
                        Spacer()
                        Text(book.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Book Info")
                }

                // Camera section
                Section {
                    Toggle("Save to Photos", isOn: $savePhotosToLibrary)
                } header: {
                    Text("Camera")
                } footer: {
                    Text("Also save original photos to your photo library when capturing snips")
                }

                // Background texture section
                Section {
                    ForEach(textures, id: \.0) { texture, name in
                        textureRow(texture: texture, name: name)
                    }
                } header: {
                    Text("Page Background")
                }

                // Export section
                Section {
                    Button(action: exportToPDF) {
                        HStack {
                            Text("Export as PDF")
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .disabled(isExporting || book.snipCount == 0)
                } header: {
                    Text("Export")
                } footer: {
                    if book.snipCount == 0 {
                        Text("Add some snips to export your book")
                    }
                }

                // About section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://tatooedlaura-byte.github.io/snipbook/privacy.html")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Export Complete", isPresented: $showExportSuccess) {
                Button("Share") {
                    showShareSheet = true
                }
                Button("Done", role: .cancel) {}
            } message: {
                Text("Your snipbook has been exported as a PDF.")
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedPDFURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Texture Row

    private func textureRow(texture: String, name: String) -> some View {
        Button {
            book.backgroundTexture = texture
        } label: {
            HStack {
                // Color preview
                RoundedRectangle(cornerRadius: 6)
                    .fill(textureColor(texture))
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )

                Text(name)
                    .foregroundColor(.primary)

                Spacer()

                if book.backgroundTexture == texture {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }

    private func textureColor(_ texture: String) -> Color {
        switch texture {
        // Classic
        case "paper-cream": return Color(red: 0.98, green: 0.96, blue: 0.93)
        case "paper-white": return Color(red: 0.99, green: 0.99, blue: 0.99)
        case "paper-kraft": return Color(red: 0.82, green: 0.73, blue: 0.62)
        // Warm & Bright
        case "paper-butter": return Color(red: 1.0, green: 0.96, blue: 0.76)
        case "paper-sunshine": return Color(red: 1.0, green: 0.92, blue: 0.55)
        case "paper-peach": return Color(red: 1.0, green: 0.85, blue: 0.73)
        case "paper-coral": return Color(red: 1.0, green: 0.75, blue: 0.70)
        case "paper-blush": return Color(red: 1.0, green: 0.84, blue: 0.84)
        case "paper-rose": return Color(red: 1.0, green: 0.76, blue: 0.82)
        // Cool & Fresh
        case "paper-mint": return Color(red: 0.75, green: 0.95, blue: 0.85)
        case "paper-seafoam": return Color(red: 0.70, green: 0.92, blue: 0.88)
        case "paper-aqua": return Color(red: 0.70, green: 0.90, blue: 0.95)
        case "paper-sky": return Color(red: 0.80, green: 0.90, blue: 1.0)
        case "paper-periwinkle": return Color(red: 0.80, green: 0.80, blue: 1.0)
        case "paper-lavender": return Color(red: 0.88, green: 0.82, blue: 0.95)
        case "paper-lilac": return Color(red: 0.92, green: 0.80, blue: 0.92)
        // Earthy
        case "paper-sage": return Color(red: 0.80, green: 0.88, blue: 0.78)
        case "paper-olive": return Color(red: 0.75, green: 0.78, blue: 0.62)
        case "paper-terracotta": return Color(red: 0.90, green: 0.70, blue: 0.58)
        case "paper-linen": return Color(red: 0.95, green: 0.92, blue: 0.88)
        // Neutral
        case "paper-gray": return Color(red: 0.92, green: 0.92, blue: 0.92)
        case "paper-newsprint": return Color(red: 0.91, green: 0.89, blue: 0.86)
        // Dark
        case "paper-midnight": return Color(red: 0.15, green: 0.20, blue: 0.28)
        case "paper-charcoal": return Color(red: 0.25, green: 0.25, blue: 0.27)
        default: return Color(red: 0.98, green: 0.96, blue: 0.93)
        }
    }

    // MARK: - PDF Export

    private func exportToPDF() {
        isExporting = true

        Task {
            let url = await PDFExporter.export(book: book)
            await MainActor.run {
                isExporting = false
                if let url = url {
                    exportedPDFURL = url
                    showExportSuccess = true
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - PDF Exporter

actor PDFExporter {
    static func export(book: Book) async -> URL? {
        let pageWidth: CGFloat = 612  // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50

        let pdfMetaData = [
            kCGPDFContextCreator: "Snipbook",
            kCGPDFContextAuthor: "Snipbook User",
            kCGPDFContextTitle: book.title
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        // Get background color from book's texture setting
        let backgroundColor = textureToUIColor(book.backgroundTexture)

        let data = renderer.pdfData { context in
            for page in book.sortedPages {
                context.beginPage()

                let contentRect = pageRect.insetBy(dx: margin, dy: margin)

                // Draw page background with selected color
                backgroundColor.setFill()
                UIBezierPath(rect: contentRect).fill()

                // Draw snips in a 2x2 grid layout
                let snips = page.snips.sorted { $0.createdAt < $1.createdAt }
                let snipCount = snips.count

                // Calculate grid cell size
                let gridSpacing: CGFloat = 20
                let cellWidth = (contentRect.width - gridSpacing) / 2
                let cellHeight = (contentRect.height - gridSpacing) / 2

                for (index, snip) in snips.enumerated() {
                    if let image = UIImage(data: snip.maskedImageData) {
                        // Determine grid position (0=top-left, 1=top-right, 2=bottom-left, 3=bottom-right)
                        let col = index % 2
                        let row = index / 2

                        // Calculate cell origin
                        let cellX = contentRect.minX + CGFloat(col) * (cellWidth + gridSpacing)
                        let cellY = contentRect.minY + CGFloat(row) * (cellHeight + gridSpacing)

                        // Calculate image size to fit in cell while maintaining aspect ratio
                        let maxSize: CGFloat = snipCount == 1 ? min(cellWidth * 1.5, cellHeight * 1.5) : min(cellWidth * 0.85, cellHeight * 0.85)
                        let aspectRatio = image.size.height / image.size.width
                        var width = min(maxSize, image.size.width)
                        var height = width * aspectRatio

                        // Ensure height doesn't exceed cell
                        if height > maxSize {
                            height = maxSize
                            width = height / aspectRatio
                        }

                        // Center image in cell (or center of page for single snip)
                        let x: CGFloat
                        let y: CGFloat

                        if snipCount == 1 {
                            // Single snip: center on page
                            x = contentRect.midX - width / 2
                            y = contentRect.midY - height / 2
                        } else {
                            // Multiple snips: center in grid cell
                            x = cellX + (cellWidth - width) / 2
                            y = cellY + (cellHeight - height) / 2
                        }

                        image.draw(in: CGRect(x: x, y: y, width: width, height: height))
                    }
                }
            }
        }

        // Save to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(book.title).pdf")

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }

    // Convert texture name to UIColor for PDF rendering
    private static func textureToUIColor(_ texture: String) -> UIColor {
        switch texture {
        // Classic
        case "paper-cream": return UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1)
        case "paper-white": return UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1)
        case "paper-kraft": return UIColor(red: 0.82, green: 0.73, blue: 0.62, alpha: 1)
        // Warm & Bright
        case "paper-butter": return UIColor(red: 1.0, green: 0.96, blue: 0.76, alpha: 1)
        case "paper-sunshine": return UIColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 1)
        case "paper-peach": return UIColor(red: 1.0, green: 0.85, blue: 0.73, alpha: 1)
        case "paper-coral": return UIColor(red: 1.0, green: 0.75, blue: 0.70, alpha: 1)
        case "paper-blush": return UIColor(red: 1.0, green: 0.84, blue: 0.84, alpha: 1)
        case "paper-rose": return UIColor(red: 1.0, green: 0.76, blue: 0.82, alpha: 1)
        // Cool & Fresh
        case "paper-mint": return UIColor(red: 0.75, green: 0.95, blue: 0.85, alpha: 1)
        case "paper-seafoam": return UIColor(red: 0.70, green: 0.92, blue: 0.88, alpha: 1)
        case "paper-aqua": return UIColor(red: 0.70, green: 0.90, blue: 0.95, alpha: 1)
        case "paper-sky": return UIColor(red: 0.80, green: 0.90, blue: 1.0, alpha: 1)
        case "paper-periwinkle": return UIColor(red: 0.80, green: 0.80, blue: 1.0, alpha: 1)
        case "paper-lavender": return UIColor(red: 0.88, green: 0.82, blue: 0.95, alpha: 1)
        case "paper-lilac": return UIColor(red: 0.92, green: 0.80, blue: 0.92, alpha: 1)
        // Earthy
        case "paper-sage": return UIColor(red: 0.80, green: 0.88, blue: 0.78, alpha: 1)
        case "paper-olive": return UIColor(red: 0.75, green: 0.78, blue: 0.62, alpha: 1)
        case "paper-terracotta": return UIColor(red: 0.90, green: 0.70, blue: 0.58, alpha: 1)
        case "paper-linen": return UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1)
        // Neutral
        case "paper-gray": return UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        case "paper-newsprint": return UIColor(red: 0.91, green: 0.89, blue: 0.86, alpha: 1)
        // Dark
        case "paper-midnight": return UIColor(red: 0.15, green: 0.20, blue: 0.28, alpha: 1)
        case "paper-charcoal": return UIColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 1)
        default: return UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1)
        }
    }
}

#Preview {
    SettingsView(book: Book())
}
