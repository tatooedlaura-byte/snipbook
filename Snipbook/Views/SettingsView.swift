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
    @State private var selectedColor: Color = .white

    private func initializeColor() {
        selectedColor = colorFromHex(book.backgroundTexture) ?? Color(red: 0.98, green: 0.96, blue: 0.93)
    }

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

                // Background color section
                Section {
                    ColorPicker("Background Color", selection: $selectedColor, supportsOpacity: false)
                        .onChange(of: selectedColor) { _, newColor in
                            book.backgroundTexture = newColor.toHex()
                        }
                } header: {
                    Text("Page Background")
                }

                // Pattern section
                Section {
                    patternGrid
                } header: {
                    Text("Pattern Overlay")
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
            .onAppear {
                initializeColor()
            }
        }
    }

    // MARK: - Hex Color Helpers

    private func colorFromHex(_ hex: String) -> Color? {
        guard hex.hasPrefix("#"), hex.count == 7 else { return nil }
        let start = hex.index(hex.startIndex, offsetBy: 1)
        let hexColor = String(hex[start...])
        guard let rgb = UInt64(hexColor, radix: 16) else { return nil }
        return Color(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }

    // MARK: - Pattern Grid

    private let patterns = [
        ("none", "None"),
        ("dots", "Dots"),
        ("grid", "Grid"),
        ("lines", "Lines"),
        ("crosshatch", "Crosshatch"),
        ("paper", "Paper Grain")
    ]

    private var patternGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
            ForEach(patterns, id: \.0) { pattern, name in
                Button {
                    book.backgroundPattern = pattern
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedColor)
                                .frame(width: 60, height: 60)

                            PatternPreview(pattern: pattern)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(book.backgroundPattern == pattern ? Color.accentColor : Color.clear, lineWidth: 2)
                        )

                        Text(name)
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
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

    // Convert hex or texture name to UIColor for PDF rendering
    private static func textureToUIColor(_ texture: String) -> UIColor {
        // Try hex first
        if texture.hasPrefix("#"), texture.count == 7 {
            let start = texture.index(texture.startIndex, offsetBy: 1)
            let hexColor = String(texture[start...])
            if let rgb = UInt64(hexColor, radix: 16) {
                return UIColor(
                    red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
                    green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
                    blue: CGFloat(rgb & 0xFF) / 255.0,
                    alpha: 1
                )
            }
        }
        // Default cream color
        return UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1)
    }
}

// MARK: - Pattern Preview (for settings grid)

struct PatternPreview: View {
    let pattern: String

    var body: some View {
        Canvas { context, size in
            drawPattern(context: context, size: size, pattern: pattern)
        }
    }

    private func drawPattern(context: GraphicsContext, size: CGSize, pattern: String) {
        let color = Color.gray.opacity(0.5)

        switch pattern {
        case "dots":
            let spacing: CGFloat = 8
            for x in stride(from: spacing / 2, to: size.width, by: spacing) {
                for y in stride(from: spacing / 2, to: size.height, by: spacing) {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)),
                        with: .color(color)
                    )
                }
            }

        case "grid":
            let spacing: CGFloat = 12
            for x in stride(from: 0, to: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(color), lineWidth: 1)
            }
            for y in stride(from: 0, to: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(color), lineWidth: 1)
            }

        case "lines":
            let spacing: CGFloat = 10
            for y in stride(from: 0, to: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(color), lineWidth: 1)
            }

        case "crosshatch":
            let spacing: CGFloat = 10
            for i in stride(from: -size.height, to: size.width + size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: i, y: 0))
                path.addLine(to: CGPoint(x: i + size.height, y: size.height))
                context.stroke(path, with: .color(color), lineWidth: 0.8)

                var path2 = Path()
                path2.move(to: CGPoint(x: i + size.height, y: 0))
                path2.addLine(to: CGPoint(x: i, y: size.height))
                context.stroke(path2, with: .color(color), lineWidth: 0.8)
            }

        case "paper":
            for _ in 0..<Int(size.width * size.height / 15) {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let opacity = Double.random(in: 0.1...0.2)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                    with: .color(.gray.opacity(opacity))
                )
            }

        default:
            break
        }
    }
}

// MARK: - Pattern Overlay (for page views)

struct PatternOverlay: View {
    let pattern: String
    let isDark: Bool

    var body: some View {
        Canvas { context, size in
            drawPattern(context: context, size: size)
        }
    }

    private func drawPattern(context: GraphicsContext, size: CGSize) {
        let color = (isDark ? Color.white : Color.black).opacity(0.25)

        switch pattern {
        case "dots":
            let spacing: CGFloat = 16
            for x in stride(from: spacing / 2, to: size.width, by: spacing) {
                for y in stride(from: spacing / 2, to: size.height, by: spacing) {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)),
                        with: .color(color)
                    )
                }
            }

        case "grid":
            let spacing: CGFloat = 24
            for x in stride(from: 0, to: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(color), lineWidth: 1)
            }
            for y in stride(from: 0, to: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(color), lineWidth: 1)
            }

        case "lines":
            let spacing: CGFloat = 20
            for y in stride(from: 0, to: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(color), lineWidth: 1)
            }

        case "crosshatch":
            let spacing: CGFloat = 20
            for i in stride(from: -size.height, to: size.width + size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: i, y: 0))
                path.addLine(to: CGPoint(x: i + size.height, y: size.height))
                context.stroke(path, with: .color(color), lineWidth: 0.8)

                var path2 = Path()
                path2.move(to: CGPoint(x: i + size.height, y: 0))
                path2.addLine(to: CGPoint(x: i, y: size.height))
                context.stroke(path2, with: .color(color), lineWidth: 0.8)
            }

        case "paper":
            for _ in 0..<Int(size.width * size.height / 20) {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let opacity = Double.random(in: 0.08...0.15)
                let c = isDark ? Color.white : Color.gray
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                    with: .color(c.opacity(opacity))
                )
            }

        default:
            break
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#FAF5EE" }
        let r = Int((components[0] * 255).rounded())
        let g = Int(((components.count > 1 ? components[1] : components[0]) * 255).rounded())
        let b = Int(((components.count > 2 ? components[2] : components[0]) * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

#Preview {
    SettingsView(book: Book())
}
