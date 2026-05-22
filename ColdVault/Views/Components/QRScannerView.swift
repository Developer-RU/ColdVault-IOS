import AVFoundation
import SwiftUI

struct QRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let overlayLayer = CAShapeLayer()
    private let frameLayer = CAShapeLayer()
    private var cornerLayers: [CAShapeLayer] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        layoutOverlay()
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            return
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            return
        }

        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        previewLayer = preview

        overlayLayer.fillRule = .evenOdd
        overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.42).cgColor
        view.layer.addSublayer(overlayLayer)

        frameLayer.fillColor = UIColor.clear.cgColor
        frameLayer.strokeColor = UIColor.white.withAlphaComponent(0.3).cgColor
        frameLayer.lineWidth = 1
        view.layer.addSublayer(frameLayer)

        for _ in 0..<4 {
            let corner = CAShapeLayer()
            corner.fillColor = UIColor.clear.cgColor
            corner.strokeColor = UIColor.systemCyan.cgColor
            corner.lineWidth = 4
            corner.lineCap = .round
            view.layer.addSublayer(corner)
            cornerLayers.append(corner)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    private func layoutOverlay() {
        let bounds = view.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        let scanSize = min(bounds.width * 0.72, 310)
        let scanRect = CGRect(
            x: (bounds.width - scanSize) / 2,
            y: (bounds.height - scanSize) / 2,
            width: scanSize,
            height: scanSize
        )

        let outerPath = UIBezierPath(rect: bounds)
        let innerPath = UIBezierPath(roundedRect: scanRect, cornerRadius: 18)
        outerPath.append(innerPath)
        overlayLayer.path = outerPath.cgPath

        frameLayer.path = UIBezierPath(roundedRect: scanRect, cornerRadius: 18).cgPath

        let cornerLength: CGFloat = 28
        cornerLayers[0].path = cornerPath(
            at: scanRect.origin,
            horizontal: (cornerLength, 0),
            vertical: (0, cornerLength)
        )
        cornerLayers[1].path = cornerPath(
            at: CGPoint(x: scanRect.maxX, y: scanRect.minY),
            horizontal: (-cornerLength, 0),
            vertical: (0, cornerLength)
        )
        cornerLayers[2].path = cornerPath(
            at: CGPoint(x: scanRect.minX, y: scanRect.maxY),
            horizontal: (cornerLength, 0),
            vertical: (0, -cornerLength)
        )
        cornerLayers[3].path = cornerPath(
            at: CGPoint(x: scanRect.maxX, y: scanRect.maxY),
            horizontal: (-cornerLength, 0),
            vertical: (0, -cornerLength)
        )
    }

    private func cornerPath(
        at point: CGPoint,
        horizontal: (CGFloat, CGFloat),
        vertical: (CGFloat, CGFloat)
    ) -> CGPath {
        let path = UIBezierPath()
        path.move(to: point)
        path.addLine(to: CGPoint(x: point.x + horizontal.0, y: point.y + horizontal.1))
        path.move(to: point)
        path.addLine(to: CGPoint(x: point.x + vertical.0, y: point.y + vertical.1))
        return path.cgPath
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue
        else {
            return
        }

        session.stopRunning()
        onCodeScanned?(value)
    }
}
