import SwiftUI

/// A SwiftUI Shape that renders any ShapeType
struct SnipShape: Shape {
    let shapeType: ShapeType

    func path(in rect: CGRect) -> Path {
        ShapePaths.path(for: shapeType, in: rect)
    }
}

// MARK: - Preview Helpers
struct ShapePreviewView: View {
    let shapeType: ShapeType
    let size: CGFloat

    init(_ shapeType: ShapeType, size: CGFloat = 100) {
        self.shapeType = shapeType
        self.size = size
    }

    var body: some View {
        SnipShape(shapeType: shapeType)
            .stroke(Color.primary.opacity(0.6), lineWidth: 2)
            .frame(width: size, height: size * aspectRatio)
    }

    private var aspectRatio: CGFloat {
        switch shapeType {
        case .postageStamp: return 1.2
        case .circle: return 1.0
        case .ticket: return 0.5
        case .label: return 0.45
        case .tornPaper: return 1.1
        case .rectangle: return 0.75
        case .polaroid: return 1.2
        case .filmstrip: return 1.5
        }
    }
}

#Preview("All Shapes") {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 20) {
        ForEach(ShapeType.allCases) { shape in
            VStack {
                ShapePreviewView(shape, size: 100)
                Text(shape.displayName)
                    .font(.caption)
            }
        }
    }
    .padding()
}
