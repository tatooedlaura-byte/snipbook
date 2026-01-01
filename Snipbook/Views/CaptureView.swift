import SwiftUI
import PhotosUI

/// Main capture screen with camera preview and shape overlay
struct CaptureView: View {
    let selectedShape: ShapeType
    let onCapture: (Data) -> Void
    let onCancel: () -> Void

    @StateObject private var cameraService = CameraService()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var importedImage: UIImage?
    @State private var showingPhotosPicker = false
    @State private var isProcessing = false
    @State private var showPreview = false
    @State private var previewImage: UIImage?

    // Pan and zoom state for imported images
    @State private var imageOffset: CGSize = .zero
    @State private var imageScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0

    // Camera zoom state
    @State private var lastCameraZoom: CGFloat = 1.0

    // Shape rotation state (0, 90, 180, 270 degrees)
    @State private var shapeRotation: Double = 0

    private var isCaptureEnabled: Bool {
        if importedImage != nil {
            return true
        }
        return cameraService.isReady
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            if let importedImage = importedImage {
                // Imported image mode
                importedImageView(importedImage)
            } else {
                // Camera mode
                cameraView
            }

            // Shape overlay (doesn't block touches)
            shapeOverlay
                .allowsHitTesting(false)

            // Controls
            VStack {
                topBar
                Spacer()
                bottomControls
            }
            .padding()

            // Processing overlay
            if isProcessing {
                processingOverlay
            }

            // Preview overlay
            if showPreview, let preview = previewImage {
                previewOverlay(preview)
            }
        }
        .onAppear {
            cameraService.startSession()
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .onChange(of: cameraService.capturedImage) { _, newImage in
            if let image = newImage {
                processImage(image)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        // Reset pan/zoom for new image
                        imageOffset = .zero
                        imageScale = 1.0
                        lastOffset = .zero
                        lastScale = 1.0
                        importedImage = image
                    }
                }
            }
        }
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedPhotoItem, matching: .images)
    }

    // MARK: - Camera View

    private var cameraView: some View {
        GeometryReader { geo in
            ZStack {
                CameraPreviewView(cameraService: cameraService)
                    .frame(width: geo.size.width, height: geo.size.height)

                // Loading indicator while camera initializes
                if !cameraService.isReady {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        Text("Starting camera...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Zoom indicator
                if cameraService.zoomFactor > 1.0 {
                    VStack {
                        Text(String(format: "%.1fx", cameraService.zoomFactor))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                        Spacer()
                    }
                    .padding(.top, 100)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        let newZoom = lastCameraZoom * value.magnification
                        cameraService.setZoom(newZoom)
                    }
                    .onEnded { _ in
                        lastCameraZoom = cameraService.zoomFactor
                    }
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Imported Image View

    private func importedImageView(_ image: UIImage) -> some View {
        GeometryReader { geo in
            let imageAspect = image.size.width / image.size.height
            let viewAspect = geo.size.width / geo.size.height

            // Calculate base size that fills the view
            let baseSize: (width: CGFloat, height: CGFloat) = {
                if imageAspect > viewAspect {
                    let h = geo.size.height
                    return (h * imageAspect, h)
                } else {
                    let w = geo.size.width
                    return (w, w / imageAspect)
                }
            }()

            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: baseSize.width * imageScale, height: baseSize.height * imageScale)
                .offset(imageOffset)
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Rectangle())
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    imageOffset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    lastOffset = imageOffset
                }
        )
        .gesture(
            MagnifyGesture()
                .onChanged { value in
                    let newScale = lastScale * value.magnification
                    // Allow zooming out to 0.3x and in to 5x
                    imageScale = min(max(newScale, 0.3), 5.0)
                }
                .onEnded { _ in
                    lastScale = imageScale
                }
        )
        .onTapGesture(count: 2) {
            // Double-tap to reset zoom and pan
            withAnimation(.easeOut(duration: 0.25)) {
                imageScale = 1.0
                imageOffset = .zero
                lastScale = 1.0
                lastOffset = .zero
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Shape Overlay

    private var shapeOverlay: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height) * 0.85
            let aspectRatio = shapeAspectRatio

            ZStack {
                // Darkened outside area
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .mask(
                        ZStack {
                            Rectangle()
                            SnipShape(shapeType: selectedShape)
                                .frame(width: size, height: size * aspectRatio)
                                .rotationEffect(.degrees(shapeRotation))
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                    )

                // Shape border
                SnipShape(shapeType: selectedShape)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: size, height: size * aspectRatio)
                    .rotationEffect(.degrees(shapeRotation))
            }
        }
        .ignoresSafeArea()
    }

    private var shapeAspectRatio: CGFloat {
        switch selectedShape {
        case .postageStamp: return 1.2
        case .circle: return 1.0
        case .tornPaper: return 1.1
        case .rectangle: return 0.75
        case .polaroid: return 1.25     // Classic polaroid ratio with thick bottom
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }

            Spacer()

            // Shape indicator and hint
            VStack(spacing: 4) {
                Text(selectedShape.displayName)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                if importedImage != nil {
                    Text("Drag & pinch to adjust")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            // Rotate shape button
            Button(action: rotateShape) {
                Image(systemName: "rotate.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }

            if importedImage == nil {
                Button(action: { cameraService.switchCamera() }) {
                    Image(systemName: "camera.rotate")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
            }
        }
        .padding(.top, 20)
    }

    private func rotateShape() {
        withAnimation(.easeInOut(duration: 0.2)) {
            shapeRotation = (shapeRotation + 90).truncatingRemainder(dividingBy: 360)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 40) {
            // Photo library button
            Button(action: { showingPhotosPicker = true }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }

            // Capture / Confirm button
            Button(action: captureOrConfirm) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 80, height: 80)

                    Circle()
                        .fill(isCaptureEnabled ? Color.white : Color.white.opacity(0.5))
                        .frame(width: 68, height: 68)

                    if importedImage != nil {
                        Image(systemName: "checkmark")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
            }
            .disabled(!isCaptureEnabled)

            // Clear imported image
            if importedImage != nil {
                Button(action: { importedImage = nil }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
            } else {
                Color.clear.frame(width: 60, height: 60)
            }
        }
        .padding(.bottom, 30)
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("Cutting...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Preview Overlay

    private func previewOverlay(_ image: UIImage) -> some View {
        ZStack {
            Color.black.opacity(0.9)

            VStack(spacing: 24) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300, maxHeight: 400)
                    .background(
                        // Checkerboard pattern to show transparency
                        CheckerboardPattern()
                            .foregroundColor(Color.gray.opacity(0.3))
                    )

                Text("Added to book!")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Auto-dismiss after showing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showPreview = false
                onCancel() // Return to book view
            }
        }
    }

    // MARK: - Actions

    private func captureOrConfirm() {
        if let image = importedImage {
            processImage(image)
        } else {
            cameraService.capturePhoto()
        }
    }

    private func processImage(_ image: UIImage) {
        isProcessing = true

        let currentOffset = imageOffset
        let currentScale = imageScale
        let currentRotation = shapeRotation

        DispatchQueue.global(qos: .userInitiated).async {
            // Apply crop based on pan/zoom if it's an imported image
            let imageToMask: UIImage
            if importedImage != nil {
                imageToMask = cropImage(image, offset: currentOffset, scale: currentScale)
            } else {
                imageToMask = image
            }

            guard let maskedData = imageToMask.masked(with: selectedShape, rotation: currentRotation) else {
                DispatchQueue.main.async {
                    isProcessing = false
                }
                return
            }

            let preview = UIImage(data: maskedData)

            DispatchQueue.main.async {
                isProcessing = false
                previewImage = preview
                showPreview = true
                onCapture(maskedData)
            }
        }
    }

    private func cropImage(_ image: UIImage, offset: CGSize, scale: CGFloat) -> UIImage {
        // First normalize orientation
        let normalizedImage = image.normalizedOrientation()
        let imageSize = normalizedImage.size

        // Calculate visible area based on offset and scale
        let viewWidth: CGFloat = 400 // approximate view size
        let viewHeight: CGFloat = 800

        // Convert view coordinates to image coordinates
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewWidth / viewHeight

        var drawWidth: CGFloat
        var drawHeight: CGFloat

        if imageAspect > viewAspect {
            drawHeight = imageSize.height
            drawWidth = drawHeight * viewAspect
        } else {
            drawWidth = imageSize.width
            drawHeight = drawWidth / viewAspect
        }

        // Apply scale
        drawWidth /= scale
        drawHeight /= scale

        // Calculate center offset
        let centerX = imageSize.width / 2 - (offset.width / viewWidth) * drawWidth
        let centerY = imageSize.height / 2 - (offset.height / viewHeight) * drawHeight

        let cropRect = CGRect(
            x: centerX - drawWidth / 2,
            y: centerY - drawHeight / 2,
            width: drawWidth,
            height: drawHeight
        )

        // Clamp to image bounds
        let clampedRect = CGRect(
            x: max(0, min(cropRect.minX, imageSize.width - cropRect.width)),
            y: max(0, min(cropRect.minY, imageSize.height - cropRect.height)),
            width: min(cropRect.width, imageSize.width),
            height: min(cropRect.height, imageSize.height)
        )

        guard let cgImage = normalizedImage.cgImage?.cropping(to: clampedRect) else {
            return normalizedImage
        }

        return UIImage(cgImage: cgImage, scale: normalizedImage.scale, orientation: .up)
    }
}

// MARK: - Checkerboard Pattern

struct CheckerboardPattern: View {
    var body: some View {
        Canvas { context, size in
            let tileSize: CGFloat = 10
            let rows = Int(size.height / tileSize) + 1
            let cols = Int(size.width / tileSize) + 1

            for row in 0..<rows {
                for col in 0..<cols {
                    if (row + col) % 2 == 0 {
                        let rect = CGRect(
                            x: CGFloat(col) * tileSize,
                            y: CGFloat(row) * tileSize,
                            width: tileSize,
                            height: tileSize
                        )
                        context.fill(Path(rect), with: .foreground)
                    }
                }
            }
        }
    }
}

#Preview {
    CaptureView(
        selectedShape: .postageStamp,
        onCapture: { _ in },
        onCancel: { }
    )
}
