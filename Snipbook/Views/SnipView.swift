import SwiftUI

/// Displays a single snip (masked image) with name below
struct SnipView: View {
    let snip: Snip
    var maxSize: CGFloat = 150
    var isDarkBackground: Bool = false
    @State private var showingDetail = false

    var body: some View {
        VStack(spacing: 6) {
            // Snip image
            if let image = UIImage(data: snip.maskedImageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxSize, maxHeight: maxSize)
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

            // Name label in Pacifico font
            if let name = snip.name, !name.isEmpty {
                Text(name)
                    .font(.custom("Pacifico-Regular", size: 14))
                    .foregroundColor(isDarkBackground ? .white : Color(red: 0.2, green: 0.2, blue: 0.2))
                    .lineLimit(1)
                    .frame(maxWidth: maxSize)
            }
        }
        .onTapGesture {
            showingDetail = true
        }
        .fullScreenCover(isPresented: $showingDetail) {
            SnipDetailView(snip: snip)
        }
    }
}

/// Full screen detail view for a snip
struct SnipDetailView: View {
    @Bindable var snip: Snip
    @Environment(\.dismiss) private var dismiss
    @State private var isEditingName = false
    @State private var editedName = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button at top
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

                // Image in the middle
                if let image = UIImage(data: snip.maskedImageData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                        .padding(.horizontal, 30)
                }

                Spacer()

                // Info section below image
                VStack(spacing: 16) {
                    // Editable name
                    if isEditingName {
                        TextField("Name this snip", text: $editedName)
                            .font(.custom("Pacifico-Regular", size: 20))
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 250)
                            .onSubmit {
                                snip.name = editedName.isEmpty ? nil : editedName
                                isEditingName = false
                            }
                    } else {
                        Button(action: {
                            editedName = snip.name ?? ""
                            isEditingName = true
                        }) {
                            HStack(spacing: 8) {
                                Text(snip.name ?? "Tap to name")
                                    .font(.custom("Pacifico-Regular", size: 26))
                                    .foregroundColor(snip.name == nil ? .white.opacity(0.5) : .white)
                                Image(systemName: "pencil")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }

                    // Date and location info
                    VStack(spacing: 10) {
                        Text(snip.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.custom("Lexend-Regular", size: 15))
                            .foregroundColor(.white.opacity(0.8))

                        if let locationName = snip.locationName {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.footnote)
                                Text(locationName)
                                    .font(.custom("Lexend-Regular", size: 15))
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onTapGesture {
            if isEditingName {
                snip.name = editedName.isEmpty ? nil : editedName
                isEditingName = false
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
