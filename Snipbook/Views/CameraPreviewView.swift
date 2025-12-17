import SwiftUI
import AVFoundation

/// UIViewRepresentable wrapper for camera preview layer
struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.backgroundColor = .black

        // Get the preview layer from camera service and add it
        let previewLayer = cameraService.previewLayer
        view.previewLayer = previewLayer
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        // Frame is updated in layoutSubviews of PreviewContainerView
    }
}

/// Custom UIView that properly handles preview layer resizing
class PreviewContainerView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
