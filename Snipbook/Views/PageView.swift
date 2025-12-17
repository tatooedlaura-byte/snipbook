import SwiftUI

/// Displays a single page in the book (1-2 snips)
struct PageView: View {
    let page: Page
    let pageNumber: Int
    let backgroundTexture: String

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

    private var isDarkTexture: Bool {
        backgroundTexture == "paper-midnight"
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
                if snips.isEmpty {
                    emptyPagePlaceholder
                } else {
                    gridLayout(snips, in: geo.size)
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
        let maxSnipSize = min(size.width * 0.4, 140)
        let spacing: CGFloat = 12

        return VStack(spacing: spacing) {
            // Top row
            HStack(spacing: spacing) {
                if snips.count > 0 {
                    SnipView(snip: snips[0], maxSize: maxSnipSize)
                }
                if snips.count > 1 {
                    SnipView(snip: snips[1], maxSize: maxSnipSize)
                } else {
                    Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                }
            }

            // Bottom row
            HStack(spacing: spacing) {
                if snips.count > 2 {
                    SnipView(snip: snips[2], maxSize: maxSnipSize)
                } else {
                    Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                }
                if snips.count > 3 {
                    SnipView(snip: snips[3], maxSize: maxSnipSize)
                } else {
                    Color.clear.frame(width: maxSnipSize, height: maxSnipSize)
                }
            }
        }
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
