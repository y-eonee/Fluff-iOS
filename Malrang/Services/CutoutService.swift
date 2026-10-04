import CoreImage
import UIKit
import Vision

enum CutoutService {
    enum Failure: Error {
        case noSubject
    }

    /// 사진에서 피사체만 남기고 배경을 투명하게 만든다. 메인 스레드 밖에서 돈다.
    @concurrent
    nonisolated static func cutout(_ image: CGImage) async throws -> CGImage {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: image)
        try handler.perform([request])
        guard let observation = request.results?.first, !observation.allInstances.isEmpty else {
            throw Failure.noSubject
        }
        let buffer = try observation.generateMaskedImage(ofInstances: observation.allInstances, from: handler, croppedToInstancesExtent: false)
        let ciImage = CIImage(cvPixelBuffer: buffer)
        guard let result = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
            throw Failure.noSubject
        }
        return result
    }

    /// 긴 변을 maxSide 이하로 줄이고 사진 방향을 바로잡는다.
    static func normalized(_ image: UIImage, maxSide: CGFloat = 2048) -> UIImage {
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
