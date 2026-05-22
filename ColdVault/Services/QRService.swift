import CoreImage.CIFilterBuiltins
import Foundation
import UIKit

protocol QRServiceProtocol {
    func makeQRCode(from value: String) -> UIImage?
    func decodePayload(from rawValue: String) -> ExchangePayload?
}

final class QRService: QRServiceProtocol {
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    func makeQRCode(from value: String) -> UIImage? {
        filter.message = Data(value.utf8)
        guard let output = filter.outputImage else {
            return nil
        }

        let transformed = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    func decodePayload(from rawValue: String) -> ExchangePayload? {
        guard let data = rawValue.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(ExchangePayload.self, from: data)
    }
}
