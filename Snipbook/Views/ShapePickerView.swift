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
            VStack(spacing: 24) {
                // Shape grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ShapeType.allCases) { shape in
                        shapeButton(for: shape)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

                Spacer()
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
            selectedShape = shape
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                onContinue()
            }
        } label: {
            VStack(spacing: 12) {
                // Shape preview
                SnipShape(shapeType: shape)
                    .stroke(
                        isSelected ? Color.accentColor : Color.primary.opacity(0.4),
                        lineWidth: isSelected ? 2 : 1.5
                    )
                    .frame(width: 60, height: 60 * aspectRatio(for: shape))
                    .frame(height: 75)

                // Label
                Text(shape.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground).opacity(0.01))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func aspectRatio(for shape: ShapeType) -> CGFloat {
        switch shape {
        case .postageStamp: return 1.2
        case .circle: return 1.0
        case .tornPaper: return 1.1
        case .rectangle: return 0.75
        case .polaroid: return 1.25
        }
    }
}

#Preview {
    ShapePickerView(selectedShape: .constant(.postageStamp)) {
        print("Continue")
    }
}
