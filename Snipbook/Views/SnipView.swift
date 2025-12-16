import SwiftUI

/// Displays a single snip (masked image)
struct SnipView: View {
    let snip: Snip
    var maxSize: CGFloat = 150

    var body: some View {
        if let image = UIImage(data: snip.maskedImageData) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: maxSize, maxHeight: maxSize * 1.2)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 3)
        } else {
            // Fallback placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: maxSize, height: maxSize)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
        }
    }
}

#Preview {
    // Preview with mock data
    VStack {
        Text("Snip Preview")
    }
}
