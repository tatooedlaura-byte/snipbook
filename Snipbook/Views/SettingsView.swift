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

    private let textures = [
        // Warm tones
        ("paper-cream", "Cream"),
        ("paper-butter", "Butter"),
        ("paper-blush", "Blush"),
        ("paper-linen", "Linen"),
        // Neutral tones
        ("paper-white", "White"),
        ("paper-gray", "Gray"),
        ("paper-newsprint", "Newsprint"),
        ("paper-kraft", "Kraft"),
        // Cool tones
        ("paper-sage", "Sage"),
        ("paper-sky", "Sky"),
        ("paper-lavender", "Lavender"),
        // Dark mode
        ("paper-midnight", "Midnight")
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
        // Warm tones
        case "paper-cream": return Color(red: 0.98, green: 0.96, blue: 0.93)
        case "paper-butter": return Color(red: 0.98, green: 0.95, blue: 0.86)
        case "paper-blush": return Color(red: 0.97, green: 0.91, blue: 0.89)
        case "paper-linen": return Color(red: 0.95, green: 0.92, blue: 0.88)
        // Neutral tones
        case "paper-white": return Color(red: 0.99, green: 0.99, blue: 0.99)
        case "paper-gray": return Color(red: 0.94, green: 0.94, blue: 0.94)
        case "paper-newsprint": return Color(red: 0.91, green: 0.89, blue: 0.86)
        case "paper-kraft": return Color(red: 0.85, green: 0.78, blue: 0.70)
        // Cool tones
        case "paper-sage": return Color(red: 0.91, green: 0.93, blue: 0.90)
        case "paper-sky": return Color(red: 0.90, green: 0.93, blue: 0.96)
        case "paper-lavender": return Color(red: 0.93, green: 0.91, blue: 0.95)
        // Dark mode
        case "paper-midnight": return Color(red: 0.17, green: 0.24, blue: 0.31)
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

        let data = renderer.pdfData { context in
            for page in book.sortedPages {
                context.beginPage()

                let contentRect = pageRect.insetBy(dx: margin, dy: margin)

                // Draw page background
                UIColor(red: 0.98, green: 0.96, blue: 0.91, alpha: 1).setFill()
                UIBezierPath(rect: contentRect).fill()

                // Draw snips
                let snips = page.snips.sorted { $0.createdAt < $1.createdAt }

                for (index, snip) in snips.enumerated() {
                    if let image = UIImage(data: snip.maskedImageData) {
                        let maxSize: CGFloat = snips.count == 1 ? 350 : 250
                        let aspectRatio = image.size.height / image.size.width
                        let width = min(maxSize, image.size.width)
                        let height = width * aspectRatio

                        var x: CGFloat
                        var y: CGFloat

                        if snips.count == 1 {
                            x = contentRect.midX - width / 2
                            y = contentRect.midY - height / 2
                        } else {
                            x = index == 0 ? contentRect.minX + 50 : contentRect.maxX - width - 50
                            y = index == 0 ? contentRect.minY + 100 : contentRect.maxY - height - 100
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
}

#Preview {
    SettingsView(book: Book())
}
