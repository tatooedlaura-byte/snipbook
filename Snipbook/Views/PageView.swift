import SwiftUI

/// Displays a single page in the book (1-2 snips)
struct PageView: View {
    let page: Page
    let pageNumber: Int
    let backgroundTexture: String
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

            // Subtle texture overlay
            textureOverlay
        }
    }

    private var backgroundColor: Color {
        switch backgroundTexture {
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

    private var isDarkTexture: Bool {
        backgroundTexture == "paper-midnight" || backgroundTexture == "paper-charcoal"
    }

    private var textureOverlay: some View {
        Canvas { context, size in
            // Add subtle paper grain
            for _ in 0..<200 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let opacity = Double.random(in: 0.02...0.05)

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.gray.opacity(opacity))
                )
            }
        }
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
