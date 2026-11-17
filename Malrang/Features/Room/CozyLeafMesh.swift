import RealityKit

/// A folded leaf replaces the dense fleece spheres used by plush furniture.
/// One small shared mesh supplies every leaf in the interior ivy.
enum CozyLeafMesh {
    private static var cached: MeshResource?
    static func clearCache() { cached = nil }
    static func make() -> MeshResource {
        if let cached { return cached }
        let rows = 12
        var points: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = [], indices: [UInt32] = []
        for row in 0...rows {
            let t = Float(row) / Float(rows)
            let width = pow(max(0, sin(t * .pi)), 0.75) * 0.5
            for side in -1...1 {
                let x = Float(side) * width
                points.append([x, t - 0.5, sin(t * .pi) * (side == 0 ? 0.06 : -0.025)])
                normals.append(simd_normalize(SIMD3(Float(side) * 0.22, 0.03, 1)))
                uv.append([Float(side + 1) / 2, t])
            }
        }
        for row in 0..<rows {
            for column in 0..<2 {
                let a = UInt32(row * 3 + column), b = a + 3
                indices += [a, a + 1, b, a + 1, b + 1, b]
            }
        }
        var mesh = MeshDescriptor(name: "interior-ivy-leaf")
        mesh.positions = .init(points); mesh.normals = .init(normals)
        mesh.textureCoordinates = .init(uv); mesh.primitives = .triangles(indices)
        let result = try! MeshResource.generate(from: [mesh])
        cached = result
        return result
    }
}
