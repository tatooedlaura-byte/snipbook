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

                // Page layout section
                Section {
                    Picker("Snips per Page", selection: $book.snipsPerPage) {
                        Text("4").tag(4)
                        Text("6").tag(6)
                        Text("9").tag(9)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Page Layout")
                } footer: {
                    Text("Maximum snips on each page. Changing this will reflow existing snips.")
                        .onChange(of: book.snipsPerPage) { _, _ in
                            book.rebalancePages()
                        }
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

                // Fun backgrounds section
                Section {
                    funPatternGrid
                } header: {
                    Text("Fun Backgrounds")
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

    private let funPatterns = [
        ("bubbles", "Bubbles"),
        ("retro", "80s Retro"),
        ("stars", "Stars"),
        ("hearts", "Hearts"),
        ("confetti", "Confetti"),
        ("waves", "Waves")
    ]

    private var patternGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
            ForEach(patterns, id: \.0) { pattern, name in
                patternButton(pattern: pattern, name: name)
            }
        }
        .padding(.vertical, 8)
    }

    private var funPatternGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
            ForEach(funPatterns, id: \.0) { pattern, name in
                patternButton(pattern: pattern, name: name)
            }
        }
        .padding(.vertical, 8)
    }

    private func patternButton(pattern: String, name: String) -> some View {
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

        let pattern = book.backgroundPattern
        let snipsPerPage = book.snipsPerPage

        let data = renderer.pdfData { context in
            for page in book.sortedPages {
                context.beginPage()

                let contentRect = pageRect.insetBy(dx: margin, dy: margin)

                // Draw background (color, pattern, or fun background)
                drawBackground(in: contentRect, texture: book.backgroundTexture, pattern: pattern)

                // Draw snips
                let snips = page.snips.sorted { $0.createdAt < $1.createdAt }
                let snipCount = snips.count

                // Calculate grid based on snip count
                let gridSpacing: CGFloat = 20
                let columns: Int
                let rows: Int
                if snipCount > 6 {
                    columns = 3
                    rows = 3
                } else if snipCount > 4 {
                    columns = 3
                    rows = 2
                } else {
                    columns = 2
                    rows = 2
                }
                let cellWidth = (contentRect.width - CGFloat(columns - 1) * gridSpacing) / CGFloat(columns)
                let cellHeight = (contentRect.height - CGFloat(rows - 1) * gridSpacing) / CGFloat(rows)

                for (index, snip) in snips.enumerated() {
                    if let image = UIImage(data: snip.maskedImageData) {
                        let col = index % columns
                        let row = index / columns

                        let cellX = contentRect.minX + CGFloat(col) * (cellWidth + gridSpacing)
                        let cellY = contentRect.minY + CGFloat(row) * (cellHeight + gridSpacing)

                        let maxSize: CGFloat = snipCount == 1 ? min(cellWidth * 1.5, cellHeight * 1.5) : min(cellWidth * 0.85, cellHeight * 0.85)
                        let aspectRatio = image.size.height / image.size.width
                        var width = min(maxSize, image.size.width)
                        var height = width * aspectRatio

                        if height > maxSize {
                            height = maxSize
                            width = height / aspectRatio
                        }

                        let x: CGFloat
                        let y: CGFloat

                        if snipCount == 1 {
                            x = contentRect.midX - width / 2
                            y = contentRect.midY - height / 2
                        } else {
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

    // Draw background with color, pattern, or fun background
    private static func drawBackground(in rect: CGRect, texture: String, pattern: String) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Fun backgrounds draw their own base color
        let funPatterns = ["bubbles", "retro", "stars", "hearts", "confetti", "waves"]
        if funPatterns.contains(pattern) {
            drawFunBackground(in: rect, pattern: pattern, context: context)
            return
        }

        // Draw solid background color
        let bgColor = textureToUIColor(texture)
        context.setFillColor(bgColor.cgColor)
        context.fill(rect)

        // Draw pattern overlay if not "none"
        if pattern != "none" {
            drawPatternOverlay(in: rect, pattern: pattern, context: context, texture: texture)
        }
    }

    // Draw pattern overlays (dots, grid, lines, crosshatch, paper)
    private static func drawPatternOverlay(in rect: CGRect, pattern: String, context: CGContext, texture: String) {
        let isDark = isTextureDark(texture)
        let overlayColor = isDark ? UIColor.white.withAlphaComponent(0.25) : UIColor.black.withAlphaComponent(0.25)

        context.saveGState()
        context.clip(to: rect)

        switch pattern {
        case "dots":
            let spacing: CGFloat = 16
            context.setFillColor(overlayColor.cgColor)
            for x in stride(from: rect.minX + spacing / 2, to: rect.maxX, by: spacing) {
                for y in stride(from: rect.minY + spacing / 2, to: rect.maxY, by: spacing) {
                    context.fillEllipse(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
                }
            }

        case "grid":
            let spacing: CGFloat = 24
            context.setStrokeColor(overlayColor.cgColor)
            context.setLineWidth(1)
            for x in stride(from: rect.minX, to: rect.maxX, by: spacing) {
                context.move(to: CGPoint(x: x, y: rect.minY))
                context.addLine(to: CGPoint(x: x, y: rect.maxY))
            }
            for y in stride(from: rect.minY, to: rect.maxY, by: spacing) {
                context.move(to: CGPoint(x: rect.minX, y: y))
                context.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
            context.strokePath()

        case "lines":
            let spacing: CGFloat = 20
            context.setStrokeColor(overlayColor.cgColor)
            context.setLineWidth(1)
            for y in stride(from: rect.minY, to: rect.maxY, by: spacing) {
                context.move(to: CGPoint(x: rect.minX, y: y))
                context.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
            context.strokePath()

        case "crosshatch":
            let spacing: CGFloat = 20
            context.setStrokeColor(overlayColor.cgColor)
            context.setLineWidth(0.8)
            for i in stride(from: -rect.height, to: rect.width + rect.height, by: spacing) {
                context.move(to: CGPoint(x: rect.minX + i, y: rect.minY))
                context.addLine(to: CGPoint(x: rect.minX + i + rect.height, y: rect.maxY))
                context.move(to: CGPoint(x: rect.minX + i + rect.height, y: rect.minY))
                context.addLine(to: CGPoint(x: rect.minX + i, y: rect.maxY))
            }
            context.strokePath()

        case "paper":
            let particleColor = isDark ? UIColor.white : UIColor.gray
            for _ in 0..<Int(rect.width * rect.height / 20) {
                let x = CGFloat.random(in: rect.minX...rect.maxX)
                let y = CGFloat.random(in: rect.minY...rect.maxY)
                let opacity = CGFloat.random(in: 0.08...0.15)
                context.setFillColor(particleColor.withAlphaComponent(opacity).cgColor)
                context.fillEllipse(in: CGRect(x: x, y: y, width: 1.5, height: 1.5))
            }

        default:
            break
        }

        context.restoreGState()
    }

    // Draw fun backgrounds (bubbles, retro, stars, hearts, confetti, waves)
    private static func drawFunBackground(in rect: CGRect, pattern: String, context: CGContext) {
        context.saveGState()
        context.clip(to: rect)

        switch pattern {
        case "bubbles":
            // Light blue base
            context.setFillColor(UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1).cgColor)
            context.fill(rect)
            // Colorful bubbles
            let colors: [UIColor] = [.systemPink, .systemPurple, .systemBlue, .systemCyan, .systemMint, .systemYellow, .systemOrange]
            for _ in 0..<35 {
                let x = CGFloat.random(in: rect.minX...rect.maxX)
                let y = CGFloat.random(in: rect.minY...rect.maxY)
                let radius = CGFloat.random(in: 10...35)
                let color = colors.randomElement()!.withAlphaComponent(0.4)
                context.setFillColor(color.cgColor)
                context.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                context.setStrokeColor(color.withAlphaComponent(0.6).cgColor)
                context.setLineWidth(2)
                context.strokeEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
            }

        case "retro":
            // 80s sunset gradient
            let gradientColors: [CGColor] = [
                UIColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 1).cgColor,
                UIColor(red: 0.3, green: 0.0, blue: 0.3, alpha: 1).cgColor,
                UIColor(red: 0.6, green: 0.1, blue: 0.4, alpha: 1).cgColor,
                UIColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 1).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors as CFArray, locations: [0, 0.33, 0.66, 1])!
            context.drawLinearGradient(gradient, start: CGPoint(x: rect.midX, y: rect.minY), end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
            // Neon grid
            let gridColor = UIColor.cyan.withAlphaComponent(0.6)
            context.setStrokeColor(gridColor.cgColor)
            context.setLineWidth(1)
            let spacing: CGFloat = 25
            for x in stride(from: rect.minX, to: rect.maxX, by: spacing) {
                context.move(to: CGPoint(x: x, y: rect.minY))
                context.addLine(to: CGPoint(x: x, y: rect.maxY))
            }
            for y in stride(from: rect.minY, to: rect.maxY, by: spacing) {
                context.move(to: CGPoint(x: rect.minX, y: y))
                context.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
            context.strokePath()

        case "stars":
            // Night sky gradient
            let gradientColors: [CGColor] = [
                UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1).cgColor,
                UIColor(red: 0.1, green: 0.1, blue: 0.25, alpha: 1).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors as CFArray, locations: [0, 1])!
            context.drawLinearGradient(gradient, start: rect.origin, end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])
            // Stars
            let starColors: [UIColor] = [.white, .yellow, .cyan, .systemPink, .orange]
            for _ in 0..<50 {
                let x = CGFloat.random(in: (rect.minX + 10)...(rect.maxX - 10))
                let y = CGFloat.random(in: (rect.minY + 10)...(rect.maxY - 10))
                let size: CGFloat = CGFloat.random(in: 6...14)
                let color = starColors.randomElement()!.withAlphaComponent(CGFloat.random(in: 0.6...1.0))
                context.setFillColor(color.cgColor)
                drawStar(at: CGPoint(x: x, y: y), size: size, context: context)
            }

        case "hearts":
            // Pink gradient
            let gradientColors: [CGColor] = [
                UIColor(red: 1.0, green: 0.9, blue: 0.95, alpha: 1).cgColor,
                UIColor(red: 1.0, green: 0.8, blue: 0.85, alpha: 1).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors as CFArray, locations: [0, 1])!
            context.drawLinearGradient(gradient, start: CGPoint(x: rect.midX, y: rect.minY), end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
            // Hearts
            let heartColors: [UIColor] = [.red, .systemPink, UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1), UIColor(red: 0.9, green: 0.2, blue: 0.4, alpha: 1)]
            for _ in 0..<30 {
                let x = CGFloat.random(in: (rect.minX + 10)...(rect.maxX - 10))
                let y = CGFloat.random(in: (rect.minY + 10)...(rect.maxY - 10))
                let size: CGFloat = CGFloat.random(in: 12...28)
                let color = heartColors.randomElement()!.withAlphaComponent(CGFloat.random(in: 0.3...0.7))
                context.setFillColor(color.cgColor)
                drawHeart(at: CGPoint(x: x, y: y), size: size, context: context)
            }

        case "confetti":
            // Light party background
            context.setFillColor(UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1).cgColor)
            context.fill(rect)
            // Confetti pieces
            let confettiColors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .purple, .systemPink, .cyan]
            for _ in 0..<80 {
                let x = CGFloat.random(in: rect.minX...rect.maxX)
                let y = CGFloat.random(in: rect.minY...rect.maxY)
                let w = CGFloat.random(in: 4...10)
                let h = CGFloat.random(in: 10...20)
                let rotation = CGFloat.random(in: 0...(2 * .pi))
                let color = confettiColors.randomElement()!.withAlphaComponent(CGFloat.random(in: 0.6...0.9))
                context.saveGState()
                context.translateBy(x: x, y: y)
                context.rotate(by: rotation)
                context.setFillColor(color.cgColor)
                let confettiRect = CGRect(x: -w/2, y: -h/2, width: w, height: h)
                let confettiPath = UIBezierPath(roundedRect: confettiRect, cornerRadius: 2)
                context.addPath(confettiPath.cgPath)
                context.fillPath()
                context.restoreGState()
            }

        case "waves":
            // Ocean gradient
            let gradientColors: [CGColor] = [
                UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1).cgColor,
                UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1).cgColor,
                UIColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 1).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors as CFArray, locations: [0, 0.5, 1])!
            context.drawLinearGradient(gradient, start: CGPoint(x: rect.midX, y: rect.minY), end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
            // Waves
            let waveColors: [UIColor] = [
                UIColor.white.withAlphaComponent(0.3),
                UIColor.cyan.withAlphaComponent(0.2),
                UIColor.white.withAlphaComponent(0.2)
            ]
            let spacing: CGFloat = 20
            var colorIndex = 0
            for y in stride(from: rect.minY + spacing, to: rect.maxY + 20, by: spacing) {
                context.setStrokeColor(waveColors[colorIndex % waveColors.count].cgColor)
                context.setLineWidth(3)
                context.move(to: CGPoint(x: rect.minX - 10, y: y))
                for x in stride(from: rect.minX - 10, to: rect.maxX + 10, by: 4) {
                    let yOffset = sin(x / 20 * .pi + Double(colorIndex)) * 8
                    context.addLine(to: CGPoint(x: x, y: y + yOffset))
                }
                context.strokePath()
                colorIndex += 1
            }

        default:
            break
        }

        context.restoreGState()
    }

    // Helper to draw a star shape
    private static func drawStar(at center: CGPoint, size: CGFloat, context: CGContext) {
        let path = UIBezierPath()
        let points = 5
        for i in 0..<points * 2 {
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let radius = i % 2 == 0 ? size : size * 0.4
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.close()
        context.addPath(path.cgPath)
        context.fillPath()
    }

    // Helper to draw a heart shape
    private static func drawHeart(at center: CGPoint, size: CGFloat, context: CGContext) {
        let path = UIBezierPath()
        let s = size * 0.5
        path.move(to: CGPoint(x: center.x, y: center.y + s))
        path.addCurve(
            to: CGPoint(x: center.x - s, y: center.y - s * 0.3),
            controlPoint1: CGPoint(x: center.x - s * 0.5, y: center.y + s * 0.3),
            controlPoint2: CGPoint(x: center.x - s, y: center.y + s * 0.2)
        )
        path.addArc(withCenter: CGPoint(x: center.x - s * 0.5, y: center.y - s * 0.3),
                    radius: s * 0.5, startAngle: .pi, endAngle: 0, clockwise: false)
        path.addArc(withCenter: CGPoint(x: center.x + s * 0.5, y: center.y - s * 0.3),
                    radius: s * 0.5, startAngle: .pi, endAngle: 0, clockwise: false)
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + s),
            controlPoint1: CGPoint(x: center.x + s, y: center.y + s * 0.2),
            controlPoint2: CGPoint(x: center.x + s * 0.5, y: center.y + s * 0.3)
        )
        context.addPath(path.cgPath)
        context.fillPath()
    }

    // Check if texture is dark for overlay color
    private static func isTextureDark(_ texture: String) -> Bool {
        if texture.hasPrefix("#"), texture.count == 7 {
            let start = texture.index(texture.startIndex, offsetBy: 1)
            let hexColor = String(texture[start...])
            if let rgb = UInt64(hexColor, radix: 16) {
                let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
                let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
                let b = CGFloat(rgb & 0xFF) / 255.0
                let luminance = 0.299 * r + 0.587 * g + 0.114 * b
                return luminance < 0.5
            }
        }
        return false
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

        case "bubbles":
            // Colorful bubbles preview
            let colors: [Color] = [.pink, .purple, .blue, .cyan, .mint]
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.95, green: 0.95, blue: 1.0)))
            for _ in 0..<8 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let radius = CGFloat.random(in: 4...12)
                let bubbleColor = colors.randomElement()!.opacity(0.5)
                context.fill(
                    Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(bubbleColor)
                )
            }

        case "retro":
            // 80s neon preview
            let gradient = Gradient(colors: [Color(red: 0.2, green: 0.0, blue: 0.3), Color(red: 0.8, green: 0.2, blue: 0.5)])
            context.fill(Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            let gridColor = Color.cyan.opacity(0.7)
            for x in stride(from: 0, to: size.width, by: 12) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }
            for y in stride(from: 0, to: size.height, by: 12) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }

        case "stars":
            // Night sky preview
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.08, green: 0.08, blue: 0.2)))
            let starColors: [Color] = [.white, .yellow, .cyan]
            for _ in 0..<12 {
                let x = CGFloat.random(in: 3...(size.width - 3))
                let y = CGFloat.random(in: 3...(size.height - 3))
                let starSize: CGFloat = CGFloat.random(in: 3...6)
                let path = starPath(center: CGPoint(x: x, y: y), size: starSize)
                context.fill(path, with: .color(starColors.randomElement()!))
            }

        case "hearts":
            // Pink hearts preview
            let gradient = Gradient(colors: [Color(red: 1.0, green: 0.9, blue: 0.95), Color(red: 1.0, green: 0.8, blue: 0.88)])
            context.fill(Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            let heartColors: [Color] = [.red, .pink, Color(red: 1.0, green: 0.4, blue: 0.6)]
            for _ in 0..<8 {
                let x = CGFloat.random(in: 5...(size.width - 5))
                let y = CGFloat.random(in: 5...(size.height - 5))
                let heartSize: CGFloat = CGFloat.random(in: 6...12)
                let path = heartPath(center: CGPoint(x: x, y: y), size: heartSize)
                context.fill(path, with: .color(heartColors.randomElement()!.opacity(0.6)))
            }

        case "confetti":
            // Colorful confetti preview
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 1.0, green: 0.98, blue: 0.95)))
            let confettiColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
            for _ in 0..<20 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let w = CGFloat.random(in: 2...4)
                let h = CGFloat.random(in: 4...8)
                let rotation = Angle.degrees(Double.random(in: 0...360))
                var path = Path(roundedRect: CGRect(x: -w/2, y: -h/2, width: w, height: h), cornerRadius: 1)
                let transform = CGAffineTransform(translationX: x, y: y).rotated(by: rotation.radians)
                path = path.applying(transform)
                context.fill(path, with: .color(confettiColors.randomElement()!.opacity(0.8)))
            }

        case "waves":
            // Ocean waves preview
            let gradient = Gradient(colors: [Color(red: 0.4, green: 0.7, blue: 0.9), Color(red: 0.15, green: 0.4, blue: 0.7)])
            context.fill(Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            for y in stride(from: 8, to: size.height, by: 10) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                for x in stride(from: 0, to: size.width, by: 4) {
                    let yOffset = sin(x / 8 * .pi) * 3
                    path.addLine(to: CGPoint(x: x, y: y + yOffset))
                }
                context.stroke(path, with: .color(.white.opacity(0.4)), lineWidth: 1.5)
            }

        default:
            break
        }
    }

    private func starPath(center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        let points = 5
        for i in 0..<points * 2 {
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let radius = i % 2 == 0 ? size : size * 0.4
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }

    private func heartPath(center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        let s = size * 0.5
        path.move(to: CGPoint(x: center.x, y: center.y + s))
        path.addCurve(
            to: CGPoint(x: center.x - s, y: center.y - s * 0.3),
            control1: CGPoint(x: center.x - s * 0.5, y: center.y + s * 0.3),
            control2: CGPoint(x: center.x - s, y: center.y + s * 0.2)
        )
        path.addArc(center: CGPoint(x: center.x - s * 0.5, y: center.y - s * 0.3),
                    radius: s * 0.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addArc(center: CGPoint(x: center.x + s * 0.5, y: center.y - s * 0.3),
                    radius: s * 0.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + s),
            control1: CGPoint(x: center.x + s, y: center.y + s * 0.2),
            control2: CGPoint(x: center.x + s * 0.5, y: center.y + s * 0.3)
        )
        return path
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

        case "bubbles":
            // Colorful bubbles background
            let colors: [Color] = [.pink, .purple, .blue, .cyan, .mint, .yellow, .orange]
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.95, green: 0.95, blue: 1.0)))
            for _ in 0..<35 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let radius = CGFloat.random(in: 10...35)
                let bubbleColor = colors.randomElement()!.opacity(0.4)
                context.fill(
                    Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(bubbleColor)
                )
                context.stroke(
                    Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(bubbleColor.opacity(0.6)),
                    lineWidth: 2
                )
            }

        case "retro":
            // 80s neon grid with sunset gradient
            let gradient = Gradient(colors: [
                Color(red: 0.1, green: 0.0, blue: 0.2),
                Color(red: 0.3, green: 0.0, blue: 0.3),
                Color(red: 0.6, green: 0.1, blue: 0.4),
                Color(red: 0.9, green: 0.3, blue: 0.5)
            ])
            context.fill(Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: size.height)))
            // Neon grid
            let gridColor = Color.cyan.opacity(0.6)
            let spacing: CGFloat = 25
            for x in stride(from: 0, to: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(gridColor), lineWidth: 1)
            }
            for y in stride(from: 0, to: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(gridColor), lineWidth: 1)
            }

        case "stars":
            // Night sky with colorful stars
            let gradient = Gradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.25)])
            context.fill(Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
            let starColors: [Color] = [.white, .yellow, .cyan, .pink, .orange]
            for _ in 0..<50 {
                let x = CGFloat.random(in: 10...(size.width - 10))
                let y = CGFloat.random(in: 10...(size.height - 10))
                let starSize: CGFloat = CGFloat.random(in: 6...14)
                let starColor = starColors.randomElement()!.opacity(Double.random(in: 0.6...1.0))
                let path = starPath(center: CGPoint(x: x, y: y), size: starSize)
                context.fill(path, with: .color(starColor))
            }

        case "hearts":
            // Pink hearts on soft gradient
            let gradient = Gradient(colors: [Color(red: 1.0, green: 0.9, blue: 0.95), Color(red: 1.0, green: 0.8, blue: 0.85)])
            context.fill(Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            let heartColors: [Color] = [.red, .pink, Color(red: 1.0, green: 0.4, blue: 0.6), Color(red: 0.9, green: 0.2, blue: 0.4)]
            for _ in 0..<30 {
                let x = CGFloat.random(in: 10...(size.width - 10))
                let y = CGFloat.random(in: 10...(size.height - 10))
                let heartSize: CGFloat = CGFloat.random(in: 12...28)
                let heartColor = heartColors.randomElement()!.opacity(Double.random(in: 0.3...0.7))
                let path = heartPath(center: CGPoint(x: x, y: y), size: heartSize)
                context.fill(path, with: .color(heartColor))
            }

        case "confetti":
            // Party confetti on light background
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 1.0, green: 0.98, blue: 0.95)))
            let confettiColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan]
            for _ in 0..<80 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let w = CGFloat.random(in: 4...10)
                let h = CGFloat.random(in: 10...20)
                let rotation = Angle.degrees(Double.random(in: 0...360))
                var path = Path(roundedRect: CGRect(x: -w/2, y: -h/2, width: w, height: h), cornerRadius: 2)
                let transform = CGAffineTransform(translationX: x, y: y).rotated(by: rotation.radians)
                path = path.applying(transform)
                let confettiColor = confettiColors.randomElement()!.opacity(Double.random(in: 0.6...0.9))
                context.fill(path, with: .color(confettiColor))
            }

        case "waves":
            // Ocean waves gradient
            let gradient = Gradient(colors: [
                Color(red: 0.4, green: 0.7, blue: 0.9),
                Color(red: 0.2, green: 0.5, blue: 0.8),
                Color(red: 0.1, green: 0.3, blue: 0.6)
            ])
            context.fill(Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: size.height)))
            let waveColors: [Color] = [.white.opacity(0.3), .cyan.opacity(0.2), .white.opacity(0.2)]
            let spacing: CGFloat = 20
            var colorIndex = 0
            for y in stride(from: spacing, to: size.height + 20, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: -10, y: y))
                for x in stride(from: -10, to: size.width + 10, by: 4) {
                    let yOffset = sin(x / 20 * .pi + Double(colorIndex)) * 8
                    path.addLine(to: CGPoint(x: x, y: y + yOffset))
                }
                context.stroke(path, with: .color(waveColors[colorIndex % waveColors.count]), lineWidth: 3)
                colorIndex += 1
            }

        default:
            break
        }
    }

    private func starPath(center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        let points = 5
        for i in 0..<points * 2 {
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let radius = i % 2 == 0 ? size : size * 0.4
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }

    private func heartPath(center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        let s = size * 0.5
        path.move(to: CGPoint(x: center.x, y: center.y + s))
        path.addCurve(
            to: CGPoint(x: center.x - s, y: center.y - s * 0.3),
            control1: CGPoint(x: center.x - s * 0.5, y: center.y + s * 0.3),
            control2: CGPoint(x: center.x - s, y: center.y + s * 0.2)
        )
        path.addArc(center: CGPoint(x: center.x - s * 0.5, y: center.y - s * 0.3),
                    radius: s * 0.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addArc(center: CGPoint(x: center.x + s * 0.5, y: center.y - s * 0.3),
                    radius: s * 0.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + s),
            control1: CGPoint(x: center.x + s, y: center.y + s * 0.2),
            control2: CGPoint(x: center.x + s * 0.5, y: center.y + s * 0.3)
        )
        return path
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
