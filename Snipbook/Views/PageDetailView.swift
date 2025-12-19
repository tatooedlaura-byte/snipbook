import SwiftUI

/// Full screen zoomable view of a book page
struct PageDetailView: View {
    let page: Page
    let pageNumber: Int
    let backgroundTexture: String
    var backgroundPattern: String = "none"
    let bookTitle: String
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()

                // Zoomable page content
                pageContent(in: geometry.size)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                let newScale = lastScale * value.magnification
                                scale = min(max(newScale, 1.0), 4.0)
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale <= 1.0 {
                                    withAnimation(.spring()) {
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
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
                        withAnimation(.spring()) {
                            if scale > 1.0 {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.0
                                lastScale = 2.0
                            }
                        }
                    }

                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.8))
                                .padding()
                        }
                    }
                    Spacer()
                }

                // Instructions hint (shows briefly)
                VStack {
                    Spacer()
                    Text("Pinch to zoom • Double-tap to toggle")
                        .font(.custom("Lexend-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 40)
                }
            }
        }
        .statusBar(hidden: true)
    }

    private func pageContent(in size: CGSize) -> some View {
        let pageWidth = min(size.width - 40, 500)
        let pageHeight = pageWidth * 1.3 // Maintain aspect ratio

        return ZStack {
            // Paper background
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)

            // Pattern overlay
            if backgroundPattern != "none" {
                PatternOverlay(pattern: backgroundPattern, isDark: isDarkTexture)
            }

            // Snips layout
            snipsLayout(pageWidth: pageWidth, pageHeight: pageHeight)
        }
        .frame(width: pageWidth, height: pageHeight)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .white.opacity(0.1), radius: 20)
    }

    private var backgroundColor: Color {
        if backgroundTexture.hasPrefix("#"), backgroundTexture.count == 7 {
            let start = backgroundTexture.index(backgroundTexture.startIndex, offsetBy: 1)
            let hexColor = String(backgroundTexture[start...])
            if let rgb = UInt64(hexColor, radix: 16) {
                return Color(
                    red: Double((rgb >> 16) & 0xFF) / 255.0,
                    green: Double((rgb >> 8) & 0xFF) / 255.0,
                    blue: Double(rgb & 0xFF) / 255.0
                )
            }
        }
        return Color(red: 0.98, green: 0.96, blue: 0.93)
    }

    private var isDarkTexture: Bool {
        if backgroundTexture.hasPrefix("#"), backgroundTexture.count == 7 {
            let start = backgroundTexture.index(backgroundTexture.startIndex, offsetBy: 1)
            let hexColor = String(backgroundTexture[start...])
            if let rgb = UInt64(hexColor, radix: 16) {
                let r = Double((rgb >> 16) & 0xFF) / 255.0
                let g = Double((rgb >> 8) & 0xFF) / 255.0
                let b = Double(rgb & 0xFF) / 255.0
                let luminance = 0.299 * r + 0.587 * g + 0.114 * b
                return luminance < 0.5
            }
        }
        return false
    }

    private func snipsLayout(pageWidth: CGFloat, pageHeight: CGFloat) -> some View {
        let snips = page.snips.sorted { $0.createdAt < $1.createdAt }
        let maxSnipSize = pageWidth * 0.38
        let spacing: CGFloat = 16

        return VStack(spacing: 0) {
            // Book title at top
            Text(bookTitle)
                .font(.custom("Pacifico-Regular", size: 18))
                .foregroundColor(isDarkTexture ? .white.opacity(0.6) : Color(red: 0.4, green: 0.4, blue: 0.4))
                .padding(.top, 16)

            Spacer()

            if snips.isEmpty {
                emptyPagePlaceholder
            } else {
                VStack(spacing: spacing) {
                    // Top row
                    HStack(spacing: spacing) {
                        if snips.count > 0 {
                            snipImage(snips[0], maxSize: maxSnipSize)
                        }
                        if snips.count > 1 {
                            snipImage(snips[1], maxSize: maxSnipSize)
                        } else {
                            Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                        }
                    }

                    // Bottom row
                    HStack(spacing: spacing) {
                        if snips.count > 2 {
                            snipImage(snips[2], maxSize: maxSnipSize)
                        } else {
                            Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                        }
                        if snips.count > 3 {
                            snipImage(snips[3], maxSize: maxSnipSize)
                        } else {
                            Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                        }
                    }
                }
            }

            Spacer()

            // Page number
            HStack {
                Spacer()
                Text("\(pageNumber)")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(isDarkTexture ? .white.opacity(0.4) : .gray.opacity(0.4))
                    .padding(12)
            }
        }
    }

    private func snipImage(_ snip: Snip, maxSize: CGFloat) -> some View {
        VStack(spacing: 6) {
            if let image = UIImage(data: snip.maskedImageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxSize, maxHeight: maxSize)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 3)
            }

            if let name = snip.name, !name.isEmpty {
                Text(name)
                    .font(.custom("Pacifico-Regular", size: 14))
                    .foregroundColor(isDarkTexture ? .white : Color(red: 0.2, green: 0.2, blue: 0.2))
                    .lineLimit(1)
                    .frame(maxWidth: maxSize)
            }
        }
    }

    private var emptyPagePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "scissors")
                .font(.system(size: 32))
                .foregroundColor(isDarkTexture ? .white.opacity(0.3) : .gray.opacity(0.3))
            Text("Empty page")
                .font(.caption)
                .foregroundColor(isDarkTexture ? .white.opacity(0.5) : .gray.opacity(0.5))
        }
    }
}
