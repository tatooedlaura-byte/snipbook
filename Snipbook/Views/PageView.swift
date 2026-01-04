import SwiftUI

/// Displays a single page in the book (1-2 snips)
struct PageView: View {
    let page: Page
    let pageNumber: Int
    let backgroundTexture: String
    var backgroundPattern: String = "none"
    var bookTitle: String? = nil
    @Binding var isReordering: Bool

    @State private var draggingSnip: Snip?

    var body: some View {
        ZStack {
            // Paper background
            paperBackground

            // Snips on page
            snipsLayout
        }
        .frame(height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    // MARK: - Paper Background

    private var paperBackground: some View {
        ZStack {
            // Base color based on texture
            backgroundColor

            // Pattern overlay
            if backgroundPattern != "none" {
                PatternOverlay(pattern: backgroundPattern, isDark: isDarkTexture)
            }
        }
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
        // Check for dark fun backgrounds
        let darkPatterns = ["stars", "retro", "waves"]
        if darkPatterns.contains(backgroundPattern) {
            return true
        }

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

    // MARK: - Snips Layout

    private var snipsLayout: some View {
        GeometryReader { geo in
            let snips = page.sortedSnips

            ZStack {
                VStack(spacing: 0) {
                    // Book title at top of page
                    if let title = bookTitle {
                        Text(title)
                            .font(.custom("Pacifico-Regular", size: 16))
                            .foregroundColor(isDarkTexture ? .white.opacity(0.6) : Color(red: 0.4, green: 0.4, blue: 0.4))
                            .padding(.top, 12)
                    }

                    Spacer()

                    if snips.isEmpty {
                        emptyPagePlaceholder
                    } else {
                        gridLayout(snips, in: geo.size)
                    }

                    Spacer().frame(height: 40)
                }

                // Page number
                pageNumberLabel
            }
        }
    }

    private var emptyPagePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "scissors")
                .font(.system(size: 32))
                .foregroundColor(isDarkTexture ? .white.opacity(0.3) : .gray.opacity(0.3))
            Text("Tap + to add a snip")
                .font(.caption)
                .foregroundColor(isDarkTexture ? .white.opacity(0.5) : .gray.opacity(0.5))
        }
    }

    @ViewBuilder
    private func draggableSnipView(_ snip: Snip, index: Int, maxSize: CGFloat) -> some View {
        let snipView = SnipView(snip: snip, maxSize: maxSize, isDarkBackground: isDarkTexture)

        if isReordering {
            snipView
                .opacity(draggingSnip?.id == snip.id ? 0.5 : 1.0)
                .scaleEffect(draggingSnip?.id == snip.id ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: draggingSnip?.id)
                .draggable(snip.id.uuidString) {
                    // Drag preview
                    SnipView(snip: snip, maxSize: maxSize * 0.8, isDarkBackground: isDarkTexture)
                        .opacity(0.8)
                }
                .dropDestination(for: String.self) { items, _ in
                    guard let droppedIdString = items.first,
                          let droppedId = UUID(uuidString: droppedIdString),
                          droppedId != snip.id else { return false }

                    // Find source and destination indices
                    let sortedSnips = page.sortedSnips
                    guard let sourceIndex = sortedSnips.firstIndex(where: { $0.id == droppedId }),
                          let destIndex = sortedSnips.firstIndex(where: { $0.id == snip.id }) else { return false }

                    withAnimation(.easeInOut(duration: 0.3)) {
                        page.reorderSnip(from: sourceIndex, to: destIndex)
                    }
                    return true
                }
                .onDrag {
                    draggingSnip = snip
                    return NSItemProvider(object: snip.id.uuidString as NSString)
                }
        } else {
            snipView
        }
    }

    private func gridLayout(_ snips: [Snip], in size: CGSize) -> some View {
        let spacing: CGFloat = 10

        // Single snip gets displayed larger and centered
        if snips.count == 1 {
            let singleSnipSize = min(size.width * 0.65, 220)
            return AnyView(
                draggableSnipView(snips[0], index: 0, maxSize: singleSnipSize)
            )
        }

        // 7-9 snips: use 3x3 grid
        if snips.count > 6 {
            let maxSnipSize = min(size.width * 0.28, 85)
            return AnyView(VStack(spacing: spacing) {
                // Row 1
                HStack(spacing: spacing) {
                    draggableSnipView(snips[0], index: 0, maxSize: maxSnipSize)
                    draggableSnipView(snips[1], index: 1, maxSize: maxSnipSize)
                    draggableSnipView(snips[2], index: 2, maxSize: maxSnipSize)
                }
                // Row 2
                HStack(spacing: spacing) {
                    draggableSnipView(snips[3], index: 3, maxSize: maxSnipSize)
                    draggableSnipView(snips[4], index: 4, maxSize: maxSnipSize)
                    draggableSnipView(snips[5], index: 5, maxSize: maxSnipSize)
                }
                // Row 3
                HStack(spacing: spacing) {
                    draggableSnipView(snips[6], index: 6, maxSize: maxSnipSize)
                    if snips.count > 7 {
                        draggableSnipView(snips[7], index: 7, maxSize: maxSnipSize)
                    } else {
                        Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                    }
                    if snips.count > 8 {
                        draggableSnipView(snips[8], index: 8, maxSize: maxSnipSize)
                    } else {
                        Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                    }
                }
            })
        }

        // 5-6 snips: use 3x2 grid with smaller snips
        if snips.count > 4 {
            let maxSnipSize = min(size.width * 0.28, 100)
            return AnyView(VStack(spacing: spacing) {
                // Top row (3 snips)
                HStack(spacing: spacing) {
                    draggableSnipView(snips[0], index: 0, maxSize: maxSnipSize)
                    draggableSnipView(snips[1], index: 1, maxSize: maxSnipSize)
                    draggableSnipView(snips[2], index: 2, maxSize: maxSnipSize)
                }
                // Bottom row (up to 3 snips)
                HStack(spacing: spacing) {
                    draggableSnipView(snips[3], index: 3, maxSize: maxSnipSize)
                    if snips.count > 4 {
                        draggableSnipView(snips[4], index: 4, maxSize: maxSnipSize)
                    } else {
                        Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                    }
                    if snips.count > 5 {
                        draggableSnipView(snips[5], index: 5, maxSize: maxSnipSize)
                    } else {
                        Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                    }
                }
            })
        }

        // 2-4 snips: use 2x2 grid
        let maxSnipSize = min(size.width * 0.4, 140)

        return AnyView(VStack(spacing: spacing) {
            // Top row
            HStack(spacing: spacing) {
                draggableSnipView(snips[0], index: 0, maxSize: maxSnipSize)
                if snips.count > 1 {
                    draggableSnipView(snips[1], index: 1, maxSize: maxSnipSize)
                } else {
                    Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                }
            }

            // Bottom row
            HStack(spacing: spacing) {
                if snips.count > 2 {
                    draggableSnipView(snips[2], index: 2, maxSize: maxSnipSize)
                } else {
                    Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                }
                if snips.count > 3 {
                    draggableSnipView(snips[3], index: 3, maxSize: maxSnipSize)
                } else {
                    Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                }
            }
        })
    }

    private var pageNumberLabel: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("\(pageNumber)")
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(isDarkTexture ? .white.opacity(0.4) : .gray.opacity(0.4))
                    .padding(8)
            }
        }
    }
}

#Preview {
    PageView(
        page: Page(),
        pageNumber: 1,
        backgroundTexture: "paper-cream",
        isReordering: .constant(false)
    )
    .padding()
}
