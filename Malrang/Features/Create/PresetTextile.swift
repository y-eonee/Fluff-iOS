import RealityKit
import UIKit

/// Low-contrast minky pile; kept separate from the room's coarse woven fabric.
enum PresetTextile {
    private static var cached: (color: TextureResource, normal: TextureResource)?

    static func textures() async -> (color: TextureResource, normal: TextureResource)? {
        if let cached { return cached }
        let size = 256
        func noise(_ x: Int, _ y: Int) -> Float {
            var n = (UInt32(truncatingIfNeeded: x) &* 747796405) ^ (UInt32(truncatingIfNeeded: y) &* 2891336453)
            n = ((n >> ((n >> 28) + 4)) ^ n) &* 277803737
            return Float((n ^ (n >> 22)) & 65535) / 65535
        }
        // Overlapping short curved fibers, rather than isotropic pebble noise.
        var pile = Array(repeating: Float(0.15), count: size * size)
        for strand in 0..<9000 {
            let x = noise(strand, 11) * Float(size), y = noise(strand, 83) * Float(size)
            let angle = noise(strand, 151) * 2 * Float.pi
            let length = 3 + noise(strand, 217) * 5
            let curl = (noise(strand, 41) - 0.5) * 1.4
            let amplitude = 0.45 + noise(strand, 109) * 0.5
            for step in 0...12 {
                let t = Float(step) / 12
                let a = angle + curl * t
                let px = x + cos(a) * length * t, py = y + sin(a) * length * t
                for dy in -1...1 {
                    for dx in -1...1 {
                        let ix = Int(floor(px)) + dx, iy = Int(floor(py)) + dy
                        let distance = pow(Float(ix) + 0.5 - px, 2) + pow(Float(iy) + 0.5 - py, 2)
                        let value = amplitude * exp(-distance / 0.48)
                        let index = (iy & 255) * size + (ix & 255)
                        pile[index] = max(pile[index], value)
                    }
                }
            }
        }
        func height(_ x: Int, _ y: Int) -> Float { pile[(y & 255) * size + (x & 255)] }
        var color: [UInt8] = [], normal: [UInt8] = []
        for y in 0..<size {
            for x in 0..<size {
                let h = height(x, y)
                let c = UInt8(230 + h * 25)
                color += [c, c, c, 255]
                let dx = (height(x + 1, y) - height(x - 1, y)) * 25
                let dy = (height(x, y + 1) - height(x, y - 1)) * 25
                normal += [UInt8(128 - dx), UInt8(128 - dy), 254, 255]
            }
        }
        func image(_ bytes: [UInt8]) -> CGImage? {
            guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
            return CGImage(width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 32,
                           bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
                           bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                           provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        }
        guard let c = image(color), let n = image(normal),
              let colorTexture = try? await TextureResource(image: c, options: .init(semantic: .color)),
              let normalTexture = try? await TextureResource(image: n, options: .init(semantic: .normal)) else { return nil }
        cached = (colorTexture, normalTexture)
        return cached
    }
}
