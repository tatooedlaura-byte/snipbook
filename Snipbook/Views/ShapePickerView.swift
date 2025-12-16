import SwiftUI

/// Simple grid picker for selecting a shape before capture
struct ShapePickerView: View {
    @Binding var selectedShape: ShapeType
    let onContinue: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose a shape")
                        .font(.title2.weight(.medium))

                    Text("This will be your snip's outline")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)

                // Shape grid
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(ShapeType.allCases) { shape in
                        shapeButton(for: shape)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Continue button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.accentColor)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Shape Button

    private func shapeButton(for shape: ShapeType) -> some View {
        let isSelected = selectedShape == shape

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedShape = shape
            }
        } label: {
            VStack(spacing: 12) {
                // Shape preview
                SnipShape(shapeType: shape)
                    .stroke(
                        isSelected ? Color.accentColor : Color.primary.opacity(0.4),
                        lineWidth: isSelected ? 2.5 : 1.5
                    )
                    .frame(width: 70, height: 70 * aspectRatio(for: shape))
                    .frame(height: 85)

                // Label
                Text(shape.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func aspectRatio(for shape: ShapeType) -> CGFloat {
        switch shape {
        case .postageStamp: return 1.2
        case .circle: return 1.0
        case .ticket: return 0.5
        case .label: return 0.45
        case .tornPaper: return 1.1
        case .rectangle: return 0.75
        }
    }
}

#Preview {
    ShapePickerView(selectedShape: .constant(.postageStamp)) {
        print("Continue")
    }
}
