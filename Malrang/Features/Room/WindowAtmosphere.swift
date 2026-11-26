import RealityKit
import UIKit

/// An enclosing sky dome with elevation-based haze and directional sunlight.
/// Celestial bodies remain actual rounded geometry in front of the atmosphere.
enum WindowAtmosphere {
    static func sunPosition(hour: Double) -> SIMD3<Float> { WindowDayCycle.at(hour: hour).sunPosition }

    private static var lookup: TextureResource?
    static func dome(hour: Double, weather: Int) async -> ModelEntity {
        if lookup == nil {
            let width = 1024, height = 4
            var pixels = [UInt8](repeating: 255, count: width * height * 4)
            for x in 0..<width {
                let profile = WindowDayCycle.at(hour: Double(x) / Double(width - 1) * 24)
                let rows = profile.sky + [SIMD3(profile.daylight, profile.warmth, profile.nightVisibility)]
                for row in 0..<height { for c in 0..<3 {
                    pixels[(row * width + x) * 4 + c] = UInt8(min(255,max(0,rows[row][c]*255)))
                } }
            }
            if let provider = CGDataProvider(data: Data(pixels) as CFData),
               let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                    bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                    provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
                lookup = try? await TextureResource(image: image, options: .init(semantic: .raw))
            }
        }
        var fallback = UnlitMaterial(color: UIColor(red: 0.55,green: 0.77,blue: 0.92,alpha: 1))
        fallback.faceCulling = .none
        var material: any Material = fallback
        if let library = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary(), let lookup,
           var custom = try? CustomMaterial(surfaceShader: .init(named: "windowAtmosphere", in: library), lightingModel: .unlit) {
            custom.custom.texture = .init(lookup)
            custom.custom.value = [Float(hour), Float(weather), 0, 0]
            custom.faceCulling = .none
            material = custom
        }
        // Explicit UVs match the atmospheric directions; no dependence on sphere-generator UVs.
        let rows = 96, columns = 192
        var positions: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = [], indices: [UInt32] = []
        for row in 0...rows { for col in 0...columns {
            let u = Float(col) / Float(columns), v = Float(row) / Float(rows)
            positions.append([sin(v * .pi) * cos(u * 2 * .pi) * 18, cos(v * .pi) * 18, sin(v * .pi) * sin(u * 2 * .pi) * 18])
            // TextureResource's image origin is opposite the mesh latitude origin.
            uv.append([u, 1 - v])
            if row < rows && col < columns {
                let a = UInt32(row * (columns + 1) + col), b = a + UInt32(columns + 1)
                indices += [a, b, a + 1, a + 1, b, b + 1]
            }
        } }
        var descriptor = MeshDescriptor(name: "elevation-atmosphere-dome")
        descriptor.positions = .init(positions); descriptor.textureCoordinates = .init(uv)
        descriptor.primitives = .triangles(indices)
        let entity = ModelEntity(mesh: try! MeshResource.generate(from: [descriptor]), materials: [material])
        entity.name = "sky.atmosphere"; entity.position = [0, 0.68, 2.15]
        entity.components.set(DynamicLightShadowComponent(castsShadow: false))
        return entity
    }

    static let moon: MeshResource = {
        let rows = 128, columns = 32, radius: Float = 0.21, shift: Float = 0.12
        let angle = acos(shift / (2 * radius))
        func point(_ t: Float, _ v: Float) -> SIMD3<Float> {
            let outerAngle = angle + t * (2 * .pi - 2 * angle)
            let innerAngle = .pi - angle + t * 2 * angle
            let outer = SIMD3<Float>(radius * cos(outerAngle), radius * sin(outerAngle), 0)
            let inner = SIMD3<Float>(shift + radius * cos(innerAngle), radius * sin(innerAngle), 0)
            let thickness = pow(max(0, sin(t * .pi)), 0.65) * 0.055
            return (outer + inner) * 0.5 + (outer - inner) * 0.5 * cos(v) + [0, 0, thickness * sin(v)]
        }
        var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = [], indices: [UInt32] = []
        for row in 0...rows { for col in 0...columns {
            let t = Float(row) / Float(rows), v = Float(col) / Float(columns) * 2 * .pi
            let p = point(t, v), e: Float = 0.0001
            let dt = point(min(0.99999, max(0.00001, t + e)), v) - point(min(0.99999, max(0.00001, t - e)), v)
            let dv = point(min(0.99999, max(0.00001, t)), v + e) - point(min(0.99999, max(0.00001, t)), v - e)
            let cross = simd_cross(dt, dv)
            positions.append(p); normals.append(simd_length_squared(cross) > 1e-20 ? simd_normalize(cross) : [0, t < 0.5 ? 1 : -1, 0])
            uv.append([t * 2, Float(col) / Float(columns)])
            if row < rows && col < columns {
                let a = UInt32(row * (columns + 1) + col), b = a + UInt32(columns + 1)
                indices += [a, b, a + 1, a + 1, b, b + 1]
            }
        } }
        var mesh = MeshDescriptor(name: "rounded-plush-crescent")
        mesh.positions = .init(positions); mesh.normals = .init(normals); mesh.textureCoordinates = .init(uv)
        mesh.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [mesh])
    }()
}
