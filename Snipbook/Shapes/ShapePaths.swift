import SwiftUI

/// Vector path definitions for all snip shapes
/// These are used both for display overlays and image masking
struct ShapePaths {

    // MARK: - Postage Stamp
    /// Classic postage stamp with perforated edges
    static func postageStamp(in rect: CGRect) -> Path {
        let perforationRadius: CGFloat = rect.width * 0.025
        let perforationSpacing: CGFloat = rect.width * 0.08
        let inset: CGFloat = perforationRadius * 2

        var path = Path()

        let innerRect = rect.insetBy(dx: inset, dy: inset)

        // Start at top-left corner
        path.move(to: CGPoint(x: innerRect.minX, y: innerRect.minY))

        // Top edge with scallops
        var x = innerRect.minX + perforationSpacing
        while x < innerRect.maxX - perforationSpacing / 2 {
            path.addLine(to: CGPoint(x: x - perforationRadius, y: innerRect.minY))
            path.addArc(
                center: CGPoint(x: x, y: innerRect.minY),
                radius: perforationRadius,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: true
            )
            x += perforationSpacing
        }
        path.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.minY))

        // Right edge with scallops
        var y = innerRect.minY + perforationSpacing
        while y < innerRect.maxY - perforationSpacing / 2 {
            path.addLine(to: CGPoint(x: innerRect.maxX, y: y - perforationRadius))
            path.addArc(
                center: CGPoint(x: innerRect.maxX, y: y),
                radius: perforationRadius,
                startAngle: .degrees(270),
                endAngle: .degrees(90),
                clockwise: true
            )
            y += perforationSpacing
        }
        path.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.maxY))

        // Bottom edge with scallops (right to left)
        x = innerRect.maxX - perforationSpacing
        while x > innerRect.minX + perforationSpacing / 2 {
            path.addLine(to: CGPoint(x: x + perforationRadius, y: innerRect.maxY))
            path.addArc(
                center: CGPoint(x: x, y: innerRect.maxY),
                radius: perforationRadius,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: true
            )
            x -= perforationSpacing
        }
        path.addLine(to: CGPoint(x: innerRect.minX, y: innerRect.maxY))

        // Left edge with scallops (bottom to top)
        y = innerRect.maxY - perforationSpacing
        while y > innerRect.minY + perforationSpacing / 2 {
            path.addLine(to: CGPoint(x: innerRect.minX, y: y + perforationRadius))
            path.addArc(
                center: CGPoint(x: innerRect.minX, y: y),
                radius: perforationRadius,
                startAngle: .degrees(90),
                endAngle: .degrees(270),
                clockwise: true
            )
            y -= perforationSpacing
        }

        path.closeSubpath()
        return path
    }

    // MARK: - Circle
    static func circle(in rect: CGRect) -> Path {
        let size = min(rect.width, rect.height) * 0.9
        let circleRect = CGRect(
            x: rect.midX - size / 2,
            y: rect.midY - size / 2,
            width: size,
            height: size
        )
        return Path(ellipseIn: circleRect)
    }

    // MARK: - Ticket
    /// Ticket shape with notched sides
    static func ticket(in rect: CGRect) -> Path {
        let notchRadius: CGFloat = rect.width * 0.06
        let cornerRadius: CGFloat = rect.width * 0.03
        let inset: CGFloat = rect.width * 0.05

        let innerRect = rect.insetBy(dx: inset, dy: inset)
        var path = Path()

        // Top-left corner
        path.move(to: CGPoint(x: innerRect.minX + cornerRadius, y: innerRect.minY))

        // Top edge
        path.addLine(to: CGPoint(x: innerRect.maxX - cornerRadius, y: innerRect.minY))

        // Top-right corner
        path.addArc(
            center: CGPoint(x: innerRect.maxX - cornerRadius, y: innerRect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Right edge to notch
        path.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.midY - notchRadius))

        // Right notch
        path.addArc(
            center: CGPoint(x: innerRect.maxX, y: innerRect.midY),
            radius: notchRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: true
        )

        // Right edge from notch
        path.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.maxY - cornerRadius))

        // Bottom-right corner
        path.addArc(
            center: CGPoint(x: innerRect.maxX - cornerRadius, y: innerRect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: innerRect.minX + cornerRadius, y: innerRect.maxY))

        // Bottom-left corner
        path.addArc(
            center: CGPoint(x: innerRect.minX + cornerRadius, y: innerRect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Left edge to notch
        path.addLine(to: CGPoint(x: innerRect.minX, y: innerRect.midY + notchRadius))

        // Left notch
        path.addArc(
            center: CGPoint(x: innerRect.minX, y: innerRect.midY),
            radius: notchRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(-90),
            clockwise: true
        )

        // Left edge from notch
        path.addLine(to: CGPoint(x: innerRect.minX, y: innerRect.minY + cornerRadius))

        // Top-left corner
        path.addArc(
            center: CGPoint(x: innerRect.minX + cornerRadius, y: innerRect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }

    // MARK: - Label
    /// Tag/label shape with pointed left side
    static func label(in rect: CGRect) -> Path {
        let inset: CGFloat = rect.width * 0.05
        let pointDepth: CGFloat = rect.width * 0.12
        let cornerRadius: CGFloat = rect.width * 0.03
        let holeRadius: CGFloat = rect.width * 0.025

        let innerRect = rect.insetBy(dx: inset, dy: inset)
        var path = Path()

        // Start at the point
        path.move(to: CGPoint(x: innerRect.minX, y: innerRect.midY))

        // Left edge to top (angled)
        path.addLine(to: CGPoint(x: innerRect.minX + pointDepth, y: innerRect.minY))

        // Top edge
        path.addLine(to: CGPoint(x: innerRect.maxX - cornerRadius, y: innerRect.minY))

        // Top-right corner
        path.addArc(
            center: CGPoint(x: innerRect.maxX - cornerRadius, y: innerRect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Right edge
        path.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.maxY - cornerRadius))

        // Bottom-right corner
        path.addArc(
            center: CGPoint(x: innerRect.maxX - cornerRadius, y: innerRect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: innerRect.minX + pointDepth, y: innerRect.maxY))

        // Back to point
        path.closeSubpath()

        // Add hole near point
        let holeCenter = CGPoint(x: innerRect.minX + pointDepth + holeRadius * 2, y: innerRect.midY)
        path.addEllipse(in: CGRect(
            x: holeCenter.x - holeRadius,
            y: holeCenter.y - holeRadius,
            width: holeRadius * 2,
            height: holeRadius * 2
        ))

        return path
    }

    // MARK: - Torn Paper
    /// Organic torn paper blob shape
    static func tornPaper(in rect: CGRect) -> Path {
        let inset: CGFloat = rect.width * 0.08
        let innerRect = rect.insetBy(dx: inset, dy: inset)

        var path = Path()

        // Create organic blob using bezier curves
        // Seed some control points for a natural torn look
        let points: [(CGPoint, CGPoint, CGPoint)] = [
            // (point, controlIn, controlOut)
            (
                CGPoint(x: innerRect.midX, y: innerRect.minY + innerRect.height * 0.05),
                CGPoint(x: innerRect.minX + innerRect.width * 0.3, y: innerRect.minY),
                CGPoint(x: innerRect.maxX - innerRect.width * 0.2, y: innerRect.minY + innerRect.height * 0.08)
            ),
            (
                CGPoint(x: innerRect.maxX - innerRect.width * 0.08, y: innerRect.minY + innerRect.height * 0.35),
                CGPoint(x: innerRect.maxX + innerRect.width * 0.02, y: innerRect.minY + innerRect.height * 0.15),
                CGPoint(x: innerRect.maxX - innerRect.width * 0.05, y: innerRect.midY - innerRect.height * 0.1)
            ),
            (
                CGPoint(x: innerRect.maxX - innerRect.width * 0.05, y: innerRect.midY + innerRect.height * 0.15),
                CGPoint(x: innerRect.maxX + innerRect.width * 0.03, y: innerRect.midY),
                CGPoint(x: innerRect.maxX - innerRect.width * 0.1, y: innerRect.maxY - innerRect.height * 0.25)
            ),
            (
                CGPoint(x: innerRect.midX + innerRect.width * 0.1, y: innerRect.maxY - innerRect.height * 0.08),
                CGPoint(x: innerRect.maxX - innerRect.width * 0.15, y: innerRect.maxY + innerRect.height * 0.02),
                CGPoint(x: innerRect.midX - innerRect.width * 0.1, y: innerRect.maxY - innerRect.height * 0.05)
            ),
            (
                CGPoint(x: innerRect.minX + innerRect.width * 0.12, y: innerRect.maxY - innerRect.height * 0.2),
                CGPoint(x: innerRect.minX + innerRect.width * 0.2, y: innerRect.maxY),
                CGPoint(x: innerRect.minX - innerRect.width * 0.02, y: innerRect.maxY - innerRect.height * 0.35)
            ),
            (
                CGPoint(x: innerRect.minX + innerRect.width * 0.05, y: innerRect.midY),
                CGPoint(x: innerRect.minX - innerRect.width * 0.03, y: innerRect.midY + innerRect.height * 0.15),
                CGPoint(x: innerRect.minX + innerRect.width * 0.02, y: innerRect.midY - innerRect.height * 0.2)
            ),
            (
                CGPoint(x: innerRect.minX + innerRect.width * 0.15, y: innerRect.minY + innerRect.height * 0.15),
                CGPoint(x: innerRect.minX, y: innerRect.minY + innerRect.height * 0.25),
                CGPoint(x: innerRect.minX + innerRect.width * 0.25, y: innerRect.minY - innerRect.height * 0.02)
            )
        ]

        path.move(to: points[0].0)

        for i in 0..<points.count {
            let next = (i + 1) % points.count
            path.addCurve(
                to: points[next].0,
                control1: points[i].2,
                control2: points[next].1
            )
        }

        path.closeSubpath()
        return path
    }

    // MARK: - Rectangle
    /// Simple rounded rectangle
    static func rectangle(in rect: CGRect) -> Path {
        let inset: CGFloat = rect.width * 0.05
        let cornerRadius: CGFloat = rect.width * 0.04
        let innerRect = rect.insetBy(dx: inset, dy: inset)
        return Path(roundedRect: innerRect, cornerRadius: cornerRadius)
    }

    // MARK: - Polaroid
    /// Classic polaroid photo shape - just the photo area (frame is added by ImageMaskingService)
    static func polaroid(in rect: CGRect) -> Path {
        let inset: CGFloat = rect.width * 0.05
        let borderWidth: CGFloat = rect.width * 0.04
        let bottomBorder: CGFloat = rect.height * 0.20  // Thicker bottom for classic look
        let cornerRadius: CGFloat = rect.width * 0.02

        let outerRect = rect.insetBy(dx: inset, dy: inset)

        var path = Path()

        // Outer frame
        path.addRoundedRect(in: outerRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

        // Inner photo area cutout (using even-odd fill rule, this creates the frame effect)
        let photoRect = CGRect(
            x: outerRect.minX + borderWidth,
            y: outerRect.minY + borderWidth,
            width: outerRect.width - borderWidth * 2,
            height: outerRect.height - borderWidth - bottomBorder
        )
        path.addRect(photoRect)

        return path
    }

    // MARK: - Get Path for Shape Type
    static func path(for shapeType: ShapeType, in rect: CGRect) -> Path {
        switch shapeType {
        case .postageStamp: return postageStamp(in: rect)
        case .circle: return circle(in: rect)
        case .ticket: return ticket(in: rect)
        case .label: return label(in: rect)
        case .tornPaper: return tornPaper(in: rect)
        case .rectangle: return rectangle(in: rect)
        case .polaroid: return polaroid(in: rect)
        }
    }
}
