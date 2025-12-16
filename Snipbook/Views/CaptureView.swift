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

            // Shape overlay
            shapeOverlay

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
            CameraPreviewView(cameraService: cameraService)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    // MARK: - Imported Image View

    private func importedImageView(_ image: UIImage) -> some View {
        GeometryReader { geo in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
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
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                    )

                // Shape border
                SnipShape(shapeType: selectedShape)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: size, height: size * aspectRatio)
            }
        }
        .ignoresSafeArea()
    }

    private var shapeAspectRatio: CGFloat {
        switch selectedShape {
        case .postageStamp: return 1.2
        case .circle: return 1.0
        case .ticket: return 0.5
        case .label: return 0.45
        case .tornPaper: return 1.1
        case .rectangle: return 0.75
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

            // Shape indicator
            VStack(spacing: 4) {
                Text(selectedShape.displayName)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Button(action: { cameraService.switchCamera() }) {
                Image(systemName: "camera.rotate")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .opacity(importedImage == nil ? 1 : 0)
        }
        .padding(.top, 20)
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
                        .fill(Color.white)
                        .frame(width: 68, height: 68)

                    if importedImage != nil {
                        Image(systemName: "checkmark")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
            }

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

        DispatchQueue.global(qos: .userInitiated).async {
            guard let maskedData = image.masked(with: selectedShape) else {
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
