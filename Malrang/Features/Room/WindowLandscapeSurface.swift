import RealityKit
import UIKit

/// Shared, mipmapped surface detail; the landscape remains geometry, never a background image.
enum WindowLandscapeSurface {
    private static var cached: (TextureResource, TextureResource)?
    static func clearCache() { cached = nil }
    static func textures() async -> (color: TextureResource, normal: TextureResource)? {
        if let cached { return cached }
        let width = 512
        var color = [UInt8](repeating: 255, count: width * width * 4)
        var normal = color
        func noise(_ x: Int, _ y: Int, _ size: Int) -> Float {
            // Periodic value noise has no seams when tiled across a large hill.
            let xx = Float(x) / Float(size), yy = Float(y) / Float(size)
            let ix = Int(floor(xx)), iy = Int(floor(yy)), cells = width / size
            func hash(_ a: Int, _ b: Int) -> Float {
                var n = UInt32((a % cells + cells) % cells) &* 374761393
                n &+= UInt32((b % cells + cells) % cells) &* 668265263
                n = (n ^ (n >> 13)) &* 1274126177
                return Float((n ^ (n >> 16)) & 65535) / 65535
            }
            let fx = xx - Float(ix), fy = yy - Float(iy)
            let u = fx * fx * (3 - 2 * fx), v = fy * fy * (3 - 2 * fy)
            let top = hash(ix, iy) * (1 - u) + hash(ix + 1, iy) * u
            let bottom = hash(ix, iy + 1) * (1 - u) + hash(ix + 1, iy + 1) * u
            return top * (1 - v) + bottom * v
        }
        var heights = [Float](repeating: 0, count: width * width)
        for y in 0..<width {
            for x in 0..<width {
                heights[y * width + x] = noise(x, y, 4) * 0.45 + noise(x, y, 16) * 0.35 + noise(x, y, 64) * 0.20
            }
        }
        for y in 0..<width {
            for x in 0..<width {
                let i = y * width + x, at = i * 4
                let shade = UInt8(min(255, max(0, 220 + heights[i] * 32)))
                color[at] = shade; color[at + 1] = shade; color[at + 2] = shade
                let dx = heights[y * width + (x + 1) % width] - heights[y * width + (x + width - 1) % width]
                let dy = heights[((y + 1) % width) * width + x] - heights[((y + width - 1) % width) * width + x]
                let n = simd_normalize(SIMD3<Float>(-dx * 1.5, -dy * 1.5, 1))
                for channel in 0..<3 { normal[at + channel] = UInt8(min(255, max(0, (n[channel] * 0.5 + 0.5) * 255))) }
            }
        }
        func image(_ pixels: [UInt8]) -> CGImage? {
            guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
            return CGImage(width: width, height: width, bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        }
        guard let c = image(color), let n = image(normal),
              let diffuse = try? await TextureResource(image: c, options: .init(semantic: .color)),
              let bumps = try? await TextureResource(image: n, options: .init(semantic: .normal)) else { return nil }
        cached = (diffuse, bumps)
        return (diffuse, bumps)
    }

}
