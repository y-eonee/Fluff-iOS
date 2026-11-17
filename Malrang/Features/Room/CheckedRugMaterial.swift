import RealityKit
import UIKit

/// Shared planar checker weave for the round rug in the cutaway room.
@MainActor
enum CheckedRugMaterial {
    private static var cached: PhysicallyBasedMaterial?
    private static var meshes: [String: MeshResource] = [:]
    static func clearCache() { cached = nil; meshes.removeAll() }
    static func material() async -> PhysicallyBasedMaterial {
        if let cached { return cached }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).image { renderer in
            let context = renderer.cgContext
            let tile = 256.0 / 12
            for row in 0..<12 { for column in 0..<12 {
                Palette.uiColor((row + column).isMultiple(of: 2) ? "#F9F9F4" : "#AFCDE8").setFill()
                context.fill(CGRect(x: Double(column) * tile, y: Double(row) * tile, width: tile, height: tile))
            } }
            // Bake the room's wool fibers into the checker texture once. Keeping
            // the edge weave in this cached image avoids extra fiber geometry.
            if let url = Bundle.main.url(forResource: "CozyFabricColor", withExtension: "png"),
               let wool = UIImage(contentsOfFile: url.path) {
                for y in 0..<2 { for x in 0..<2 {
                    wool.draw(in: CGRect(x: x * 128, y: y * 128, width: 128, height: 128),
                              blendMode: .multiply, alpha: 0.85)
                } }
            }
            // Fine, deterministic weave; generated once, never during rendering.
            for line in stride(from: 0, to: 256, by: 2) {
                context.setStrokeColor(UIColor(white: 1, alpha: 0.13).cgColor)
                context.setLineWidth(0.5)
                context.move(to: CGPoint(x: line, y: 0)); context.addLine(to: CGPoint(x: line, y: 256))
                context.move(to: CGPoint(x: 0, y: line)); context.addLine(to: CGPoint(x: 256, y: line)); context.strokePath()
            }
        }
        var material = PhysicallyBasedMaterial()
        if let cg = image.cgImage, let texture = try? await TextureResource(image: cg, options: .init(semantic: .color)) {
            material.baseColor.texture = .init(texture)
        }
        if let url = Bundle.main.url(forResource: "CozyFabricNormal", withExtension: "png"),
           let wool = UIImage(contentsOfFile: url.path) {
            let tiled = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).image { _ in
                for y in 0..<2 { for x in 0..<2 {
                    wool.draw(in: CGRect(x: x * 128, y: y * 128, width: 128, height: 128))
                } }
            }
            if let cg = tiled.cgImage,
               let texture = try? await TextureResource(image: cg, options: .init(semantic: .normal)) {
                material.normal = .init(texture: .init(texture))
            }
        }
        material.roughness = 1.0; material.metallic = 0.0
        cached = material
        return material
    }
    static func mesh(size: SIMD3<Float>) -> MeshResource {
        let key = String(describing: size)
        if let cached = meshes[key] { return cached }
        var positions: [SIMD3<Float>] = [[0, 0.032, 0]]
        var normals: [SIMD3<Float>] = [[0, 1, 0]]
        var uv: [SIMD2<Float>] = [[0.5, 0.5]]
        var indices: [UInt32] = []
        // Two narrow edge rings turn the weave down around the wool base.
        // This is static cached geometry, with no cloth simulation.
        let rings: [(Float, Float)] = [(0.94, 0.032), (0.985, 0.026), (1, 0.014)]
        for (ring, profile) in rings.enumerated() {
            for i in 0...64 {
                let angle = Float(i) / 64 * 2 * .pi
                let x = cos(angle), z = sin(angle)
                positions.append([x * size.x / 2 * profile.0, profile.1, z * size.z / 2 * profile.0])
                normals.append(ring == 0 ? [0, 1, 0] : simd_normalize([x * Float(ring) * 0.25, 1, z * Float(ring) * 0.25]))
                uv.append([(x * profile.0 + 1) / 2, (z * profile.0 + 1) / 2])
                if i > 0 {
                    let b = UInt32(1 + ring * 65 + i)
                    if ring == 0 { indices += [0, b, b - 1] }
                    else {
                        let a = b - 65
                        indices += [a - 1, a, b, a - 1, b, b - 1]
                    }
                }
            }
        }
        var descriptor = MeshDescriptor(name: "round-checker-weave")
        descriptor.positions = .init(positions); descriptor.normals = .init(normals)
        descriptor.textureCoordinates = .init(uv); descriptor.primitives = .triangles(indices)
        let mesh = (try? MeshResource.generate(from: [descriptor])) ?? .generatePlane(width: size.x, depth: size.z)
        meshes[key] = mesh
        return mesh
    }
}
