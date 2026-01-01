import UIKit
import CoreGraphics
import SwiftUI

/// Core service for masking images with shape paths
/// This is the "magic" of Snipbook - creating transparent cutouts
final class ImageMaskingService {

    static let shared = ImageMaskingService()

    private init() {}

    /// Masks an image using the specified shape, returning a transparent PNG
    /// - Parameters:
    ///   - image: The source image to mask
    ///   - shapeType: The shape to use for masking
    ///   - rotation: Rotation in degrees (0, 90, 180, 270)
    ///   - outputSize: Desired output size (default 800x800)
    /// - Returns: PNG data with transparency, or nil if masking fails
    func maskImage(_ image: UIImage, with shapeType: ShapeType, rotation: Double = 0, outputSize: CGSize = CGSize(width: 800, height: 800)) -> Data? {

        // Handle Polaroid specially - it needs a frame composited
        if shapeType == .polaroid {
            return maskPolaroid(image, rotation: rotation, outputSize: outputSize)
        }


        // Calculate the shape's aspect ratio for proper sizing
        let aspectRatio = shapeAspectRatio(for: shapeType)
        var shapeSize: CGSize

        if aspectRatio >= 1.0 {
            // Taller than wide
            shapeSize = CGSize(width: outputSize.width, height: outputSize.width * aspectRatio)
        } else {
            // Wider than tall
            shapeSize = CGSize(width: outputSize.height / aspectRatio, height: outputSize.height)
        }

        // Swap dimensions if rotated 90 or 270 degrees
        let isRotated90 = Int(rotation) % 180 == 90
        if isRotated90 {
            shapeSize = CGSize(width: shapeSize.height, height: shapeSize.width)
        }

        // Create the mask path (in original orientation)
        let originalShapeSize = isRotated90 ? CGSize(width: shapeSize.height, height: shapeSize.width) : shapeSize
        let shapeRect = CGRect(origin: .zero, size: originalShapeSize)
        let path = ShapePaths.path(for: shapeType, in: shapeRect)

        // Use UIKit drawing which handles orientation correctly
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: shapeSize, format: format)

        let maskedImage = renderer.image { context in
            let cgContext = context.cgContext

            // Move to center, rotate, move back
            cgContext.translateBy(x: shapeSize.width / 2, y: shapeSize.height / 2)
            cgContext.rotate(by: rotation * .pi / 180)
            cgContext.translateBy(x: -originalShapeSize.width / 2, y: -originalShapeSize.height / 2)

            // Create clipping path
            let uiPath = UIBezierPath(cgPath: path.cgPath)
            uiPath.addClip()

            // Calculate how to fill the shape with the image (aspect fill)
            let imageRect = aspectFillRect(for: image.size, in: shapeRect)

            // Draw the image - UIImage.draw respects orientation
            image.draw(in: imageRect)
        }

        // Return as PNG data with transparency
        return maskedImage.pngData()
    }

    /// Special handling for Polaroid - creates the classic frame with thick bottom
    private func maskPolaroid(_ image: UIImage, rotation: Double = 0, outputSize: CGSize) -> Data? {
        // Polaroid dimensions
        let frameWidth = outputSize.width
        let frameHeight = frameWidth * 1.25  // Taller to accommodate thick bottom

        let borderWidth = frameWidth * 0.04
        let bottomBorder = frameHeight * 0.20  // Thicker bottom strip for classic look
        let cornerRadius = frameWidth * 0.02

        // Photo area inside the frame
        let photoRect = CGRect(
            x: borderWidth,
            y: borderWidth,
            width: frameWidth - borderWidth * 2,
            height: frameHeight - borderWidth - bottomBorder
        )

        // Swap dimensions if rotated 90 or 270
        let isRotated90 = Int(rotation) % 180 == 90
        let finalSize = isRotated90 ? CGSize(width: frameHeight, height: frameWidth) : CGSize(width: frameWidth, height: frameHeight)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: finalSize, format: format)

        let polaroidImage = renderer.image { context in
            let cgContext = context.cgContext

            // Apply rotation
            cgContext.translateBy(x: finalSize.width / 2, y: finalSize.height / 2)
            cgContext.rotate(by: rotation * .pi / 180)
            cgContext.translateBy(x: -frameWidth / 2, y: -frameHeight / 2)

            // Draw white frame background
            let frameRect = CGRect(origin: .zero, size: CGSize(width: frameWidth, height: frameHeight))
            let framePath = UIBezierPath(roundedRect: frameRect, cornerRadius: cornerRadius)
            UIColor.white.setFill()
            framePath.fill()

            // Add subtle shadow/border to the frame
            UIColor(white: 0.85, alpha: 1.0).setStroke()
            framePath.lineWidth = 1
            framePath.stroke()

            // Clip to photo area and draw image
            cgContext.saveGState()
            let photoPath = UIBezierPath(rect: photoRect)
            photoPath.addClip()

            let imageRect = aspectFillRect(for: image.size, in: photoRect)
            image.draw(in: imageRect)
            cgContext.restoreGState()
        }

        return polaroidImage.pngData()
    }

    /// Quick preview of masking (lower resolution for UI feedback)
    func previewMask(_ image: UIImage, with shapeType: ShapeType) -> UIImage? {
        guard let data = maskImage(image, with: shapeType, outputSize: CGSize(width: 400, height: 400)) else {
            return nil
        }
        return UIImage(data: data)
    }

    // MARK: - Helper Methods

    private func shapeAspectRatio(for shapeType: ShapeType) -> CGFloat {
        switch shapeType {
        case .postageStamp: return 1.2
        case .circle: return 1.0
        case .ticket: return 0.5
        case .label: return 0.45
        case .tornPaper: return 1.1
        case .rectangle: return 0.75
        case .polaroid: return 1.25
        }
    }

    /// Calculate rect for aspect-fill image placement
    private func aspectFillRect(for imageSize: CGSize, in targetRect: CGRect) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let targetAspect = targetRect.width / targetRect.height

        var drawRect: CGRect

        if imageAspect > targetAspect {
            // Image is wider - fit height, overflow width
            let height = targetRect.height
            let width = height * imageAspect
            let x = targetRect.midX - width / 2
            drawRect = CGRect(x: x, y: targetRect.minY, width: width, height: height)
        } else {
            // Image is taller - fit width, overflow height
            let width = targetRect.width
            let height = width / imageAspect
            let y = targetRect.midY - height / 2
            drawRect = CGRect(x: targetRect.minX, y: y, width: width, height: height)
        }

        return drawRect
    }
}

// MARK: - UIImage Extension for convenience
extension UIImage {
    func masked(with shapeType: ShapeType, rotation: Double = 0) -> Data? {
        ImageMaskingService.shared.maskImage(self.normalizedOrientation(), with: shapeType, rotation: rotation)
    }

    func maskedPreview(with shapeType: ShapeType, rotation: Double = 0) -> UIImage? {
        guard let data = ImageMaskingService.shared.maskImage(self.normalizedOrientation(), with: shapeType, rotation: rotation, outputSize: CGSize(width: 400, height: 400)) else {
            return nil
        }
        return UIImage(data: data)
    }

    /// Fixes image orientation by redrawing to .up orientation
    func normalizedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalized ?? self
    }
}
