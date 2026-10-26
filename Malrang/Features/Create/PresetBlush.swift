import RealityKit
import UIKit

enum PresetBlush {
    static func clearCache() { texture = nil }

    private static var texture: TextureResource?

    static func make(side: Float, headWidth: Float, yOffset: Float = 0) async -> ModelEntity? {
        if texture == nil {
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let image = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64), format: format).image { context in
                let colors = [UIColor(red: 0.94, green: 0.61, blue: 0.65, alpha: 0.72).cgColor,
                              UIColor(red: 0.94, green: 0.61, blue: 0.65, alpha: 0).cgColor]
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.62, 1]) {
                    context.cgContext.drawRadialGradient(gradient, startCenter: CGPoint(x: 32, y: 32), startRadius: 0,
                                                         endCenter: CGPoint(x: 32, y: 32), endRadius: 32, options: [])
                }
            }
            if let cg = image.cgImage { texture = try? await TextureResource(image: cg, options: .init(semantic: .color)) }
        }
        guard let texture else { return nil }
        var points: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = [], indices: [UInt32] = []
        let steps = 16
        for row in 0...steps {
            for column in 0...steps {
                let u = Float(column) / Float(steps), v = Float(row) / Float(steps)
                let x = side * 0.068 + (u - 0.5) * 0.041
                let y = -0.036 + yOffset + (v - 0.5) * 0.027
                let z = PresetHeadSurface.front(x: x, y: y, width: headWidth) + 0.0015
                points.append([x, y, z]); uv.append([u, v])
                if row < steps && column < steps {
                    let a = UInt32(row * (steps + 1) + column), b = a + UInt32(steps + 1)
                    indices += [a, a + 1, b, a + 1, b + 1, b]
                }
            }
        }
        var mesh = MeshDescriptor(name: "soft-blush-on-fur")
        mesh.positions = .init(points); mesh.textureCoordinates = .init(uv); mesh.primitives = .triangles(indices)
        guard let resource = try? MeshResource.generate(from: [mesh]) else { return nil }
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .white, texture: .init(texture))
        material.blending = .transparent(opacity: .init(floatLiteral: 1))
        material.roughness = .init(floatLiteral: 1)
        let blush = ModelEntity(mesh: resource, materials: [material]); blush.name = "cheek"
        blush.components.set(DynamicLightShadowComponent(castsShadow: false))
        return blush
    }
}
