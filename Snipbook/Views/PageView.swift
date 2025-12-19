import SwiftUI

/// Displays a single page in the book (1-2 snips)
struct PageView: View {
    let page: Page
    let pageNumber: Int
    let backgroundTexture: String
    var backgroundPattern: String = "none"
    var bookTitle: String? = nil

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
            let snips = page.snips.sorted { $0.createdAt < $1.createdAt }

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

    private func gridLayout(_ snips: [Snip], in size: CGSize) -> some View {
        let spacing: CGFloat = 12

        // Single snip gets displayed larger and centered
        if snips.count == 1 {
            let singleSnipSize = min(size.width * 0.65, 220)
            return AnyView(
                SnipView(snip: snips[0], maxSize: singleSnipSize, isDarkBackground: isDarkTexture)
            )
        }

        // Multiple snips use grid layout
        let maxSnipSize = min(size.width * 0.4, 140)

        return AnyView(VStack(spacing: spacing) {
            // Top row
            HStack(spacing: spacing) {
                SnipView(snip: snips[0], maxSize: maxSnipSize, isDarkBackground: isDarkTexture)
                if snips.count > 1 {
                    SnipView(snip: snips[1], maxSize: maxSnipSize, isDarkBackground: isDarkTexture)
                } else {
                    Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                }
            }

            // Bottom row
            HStack(spacing: spacing) {
                if snips.count > 2 {
                    SnipView(snip: snips[2], maxSize: maxSnipSize, isDarkBackground: isDarkTexture)
                } else {
                    Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                }
                if snips.count > 3 {
                    SnipView(snip: snips[3], maxSize: maxSnipSize, isDarkBackground: isDarkTexture)
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
        backgroundTexture: "paper-cream"
    )
    .padding()
}
