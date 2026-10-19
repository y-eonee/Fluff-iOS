import CoreGraphics
import Foundation

enum FloorArtwork {
    /// 체크의 밝기 차이와 갈색 윤곽선은 남기고 바탕색만 교체한다.
    nonisolated static func recolored(_ image: CGImage, tint: SIMD3<Float>) -> CGImage? {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        return pixels.withUnsafeMutableBytes { bytes in
            guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue),
                  let data = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            for i in stride(from: 0, to: bytes.count, by: 4) {
                let alpha = Float(data[i + 3]) / 255
                guard alpha > 0 else { continue }
                let r = Float(data[i]) / (255 * alpha)
                let g = Float(data[i + 1]) / (255 * alpha)
                let b = Float(data[i + 2]) / (255 * alpha)
                if b < g && r - g > 0.07 { continue }
                // 원본의 분홍 칸은 선택색, 크림 칸은 같은 색의 밝은 톤으로 칠한다.
                let light = min(1, max(0, (g / max(r, 0.001) - 0.746) / 0.207))
                let amount = 1 - 0.82 * light
                let shade = min(1, r / 0.957)
                for channel in 0..<3 {
                    let value = (1 - amount + tint[channel] * amount) * shade
                    data[i + channel] = UInt8(clamping: Int((value * alpha * 255).rounded()))
                }
            }
            return context.makeImage()
        }
    }
}
