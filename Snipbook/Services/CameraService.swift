import AVFoundation
import UIKit
import Combine
import Photos

/// Manages camera capture session
final class CameraService: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isAuthorized = false
    @Published var error: CameraError?
    @Published var isReady = false
    @Published var zoomFactor: CGFloat = 1.0

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentCamera: AVCaptureDevice?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    // Stored preview layer - created once
    private(set) lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    enum CameraError: LocalizedError {
        case unauthorized
        case configurationFailed
        case captureFailed

        var errorDescription: String? {
            switch self {
            case .unauthorized: return "Camera access not authorized"
            case .configurationFailed: return "Failed to configure camera"
            case .captureFailed: return "Failed to capture photo"
            }
        }
    }

    override init() {
        super.init()
        checkAuthorization()
    }

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.error = .unauthorized
                    }
                }
            }
        default:
            isAuthorized = false
            error = .unauthorized
        }
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo

            // Add camera input
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("CameraService: No back camera available")
                DispatchQueue.main.async {
                    self.error = .configurationFailed
                }
                self.captureSession.commitConfiguration()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    self.currentCamera = camera
                } else {
                    print("CameraService: Cannot add camera input")
                    DispatchQueue.main.async {
                        self.error = .configurationFailed
                    }
                    self.captureSession.commitConfiguration()
                    return
                }
            } catch {
                print("CameraService: Error creating input: \(error)")
                DispatchQueue.main.async {
                    self.error = .configurationFailed
                }
                self.captureSession.commitConfiguration()
                return
            }

            // Add photo output
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
                // Use max photo dimensions for highest quality capture
                // Software crop will be applied to match the preview zoom
                if let maxDimensions = camera.activeFormat.supportedMaxPhotoDimensions.max(by: { $0.width * $0.height < $1.width * $1.height }) {
                    self.photoOutput.maxPhotoDimensions = maxDimensions
                }
            } else {
                print("CameraService: Cannot add photo output")
                DispatchQueue.main.async {
                    self.error = .configurationFailed
                }
                self.captureSession.commitConfiguration()
                return
            }

            self.captureSession.commitConfiguration()
            print("CameraService: Session configured successfully")
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if self.captureSession.isRunning {
                print("CameraService: Session already running")
                DispatchQueue.main.async {
                    self.isReady = true
                }
                return
            }

            print("CameraService: Starting session...")
            self.captureSession.startRunning()

            let isRunning = self.captureSession.isRunning
            print("CameraService: Session running = \(isRunning)")

            DispatchQueue.main.async {
                self.isReady = isRunning
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if self.captureSession.isRunning {
                print("CameraService: Stopping session...")
                self.captureSession.stopRunning()
            }

            DispatchQueue.main.async {
                self.isReady = false
            }
        }
    }

    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            guard self.captureSession.isRunning else {
                print("CameraService: Cannot capture - session not running")
                DispatchQueue.main.async {
                    self.error = .captureFailed
                }
                return
            }

            guard let connection = self.photoOutput.connection(with: .video) else {
                print("CameraService: Cannot capture - no video connection")
                DispatchQueue.main.async {
                    self.error = .captureFailed
                }
                return
            }

            if !connection.isEnabled {
                connection.isEnabled = true
            }

            // Ensure zoom is locked during capture
            if let camera = self.currentCamera {
                do {
                    try camera.lockForConfiguration()
                    print("CameraService: Capturing photo at zoom: \(camera.videoZoomFactor)")

                    let settings = AVCapturePhotoSettings()
                    self.photoOutput.capturePhoto(with: settings, delegate: self)

                    camera.unlockForConfiguration()
                } catch {
                    print("CameraService: Error locking camera: \(error)")
                    let settings = AVCapturePhotoSettings()
                    self.photoOutput.capturePhoto(with: settings, delegate: self)
                }
            } else {
                print("CameraService: Capturing photo...")
                let settings = AVCapturePhotoSettings()
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    func setZoom(_ factor: CGFloat) {
        guard let camera = currentCamera else { return }

        sessionQueue.async { [weak self] in
            do {
                try camera.lockForConfiguration()
                let maxZoom = min(camera.activeFormat.videoMaxZoomFactor, 5.0)
                let clampedFactor = max(1.0, min(factor, maxZoom))
                camera.videoZoomFactor = clampedFactor
                camera.unlockForConfiguration()

                DispatchQueue.main.async {
                    self?.zoomFactor = clampedFactor
                }
            } catch {
                print("CameraService: Error setting zoom: \(error)")
            }
        }
    }

    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isReady = false
            }

            self.captureSession.beginConfiguration()

            // Remove existing input
            if let currentInput = self.captureSession.inputs.first as? AVCaptureDeviceInput {
                self.captureSession.removeInput(currentInput)
            }

            // Toggle position
            let currentPosition = self.currentCamera?.position ?? .back
            let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
            print("CameraService: Switching from \(currentPosition) to \(newPosition)")

            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
                print("CameraService: No camera available for position \(newPosition)")
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async {
                    self.isReady = self.captureSession.isRunning
                }
                return
            }

            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.currentCamera = newCamera

                    // Configure connection for front camera mirroring
                    if let connection = self.photoOutput.connection(with: .video) {
                        connection.isEnabled = true
                        if connection.isVideoMirroringSupported {
                            connection.isVideoMirrored = (newPosition == .front)
                        }
                    }
                }
            } catch {
                print("CameraService: Error switching camera: \(error)")
            }

            self.captureSession.commitConfiguration()

            DispatchQueue.main.async {
                self.isReady = self.captureSession.isRunning
            }
        }
    }
}

// MARK: - Photo Capture Delegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("CameraService: Capture error: \(error)")
            DispatchQueue.main.async {
                self.error = .captureFailed
            }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("CameraService: Could not create image from photo data")
            DispatchQueue.main.async {
                self.error = .captureFailed
            }
            return
        }

        print("CameraService: Photo captured successfully")

        // Apply software crop to match the preview zoom
        // Hardware zoom only affects the preview, not the captured photo
        let currentZoom = self.zoomFactor
        let finalImage: UIImage

        if currentZoom > 1.0 {
            finalImage = cropImageForZoom(image, zoomFactor: currentZoom)
            print("CameraService: Applied zoom crop at \(currentZoom)x")
        } else {
            finalImage = image
        }

        // Save original photo to the photo library
        saveToPhotoLibrary(finalImage)

        DispatchQueue.main.async {
            self.capturedImage = finalImage
        }
    }

    private func cropImageForZoom(_ image: UIImage, zoomFactor: CGFloat) -> UIImage {
        // Normalize orientation first
        let normalizedImage = image.normalizedOrientation()
        let originalSize = normalizedImage.size

        // Calculate the cropped region based on zoom
        let cropWidth = originalSize.width / zoomFactor
        let cropHeight = originalSize.height / zoomFactor
        let cropX = (originalSize.width - cropWidth) / 2
        let cropY = (originalSize.height - cropHeight) / 2

        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)

        guard let cgImage = normalizedImage.cgImage?.cropping(to: cropRect) else {
            return normalizedImage
        }

        return UIImage(cgImage: cgImage, scale: normalizedImage.scale, orientation: .up)
    }

    private func saveToPhotoLibrary(_ image: UIImage) {
        // Check if user has enabled saving to photo library
        guard UserDefaults.standard.object(forKey: "savePhotosToLibrary") == nil ||
              UserDefaults.standard.bool(forKey: "savePhotosToLibrary") else {
            print("CameraService: Save to photo library disabled in settings")
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                print("CameraService: Photo library access not authorized")
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    print("CameraService: Photo saved to library")
                } else if let error = error {
                    print("CameraService: Failed to save photo: \(error.localizedDescription)")
                }
            }
        }
    }
}
