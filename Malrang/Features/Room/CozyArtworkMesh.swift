import RealityKit

/// Shallow rounded reliefs: their outline radius is independent of their depth.
/// Three immutable meshes are shared by every instance and released with the room.
enum CozyArtworkMesh {
    enum Shape: CaseIterable { case blue, sand, mat }
    private static var cache: [Shape: MeshResource] = [:]
    static func clearCache() { cache.removeAll() }

    static func make(_ shape: Shape) -> MeshResource {
        if let mesh = cache[shape] { return mesh }
        let corners: [SIMD2<Float>]
        let rounding: Float
        let depth: Float
        switch shape {
        case .blue:
            corners = [[-0.082, 0.324], [0.094, 0.306], [0.075, 0.151]]
            rounding = 0.28; depth = 0.012
        case .sand:
            corners = [[-0.098, 0.087], [0.040, 0.098], [-0.090, 0.251]]
            rounding = 0.28; depth = 0.012
        case .mat:
            corners = [[-0.1216, -0.154], [0.1216, -0.154], [0.1216, 0.154], [-0.1216, 0.154]]
            rounding = 0.12; depth = 0.009
        }
        var outline: [SIMD2<Float>] = []
        for i in corners.indices {
            let corner = corners[i]
            let incoming = corner + (corners[(i + corners.count - 1) % corners.count] - corner) * rounding
            let outgoing = corner + (corners[(i + 1) % corners.count] - corner) * rounding
            for step in 0...8 {
                let t = Float(step) / 8
                outline.append(incoming * ((1 - t) * (1 - t)) + corner * (2 * t * (1 - t)) + outgoing * (t * t))
            }
        }
        let signedArea = outline.indices.reduce(Float.zero) { area, i in
            let a = outline[i], b = outline[(i + 1) % outline.count]
            return area + a.x * b.y - b.x * a.y
        }
        if signedArea < 0 { outline.reverse() }
        let center = outline.reduce(SIMD2<Float>.zero, +) / Float(outline.count)
        var points: [SIMD3<Float>] = [[center.x, center.y, depth / 2]]
        var normals: [SIMD3<Float>] = [[0, 0, 1]]
        var uv: [SIMD2<Float>] = [[0.5, 0.5]]
        var indices: [UInt32] = []
        let count = outline.count
        // The bevel is a narrow ring, not a dense subdivision or a fur shell.
        for ring in 0..<3 {
            for i in outline.indices {
                let p = outline[i]
                let previous = outline[(i + count - 1) % count]
                let next = outline[(i + 1) % count]
                let tangent = next - previous
                let outward = simd_normalize(SIMD2(tangent.y, -tangent.x))
                let xy = ring == 0 ? center + (p - center) * 0.94 : p
                let z: Float = ring == 0 ? depth / 2 : (ring == 1 ? 0 : -depth / 2)
                points.append([xy.x, xy.y, z])
                normals.append(ring == 0 ? [0, 0, 1] : simd_normalize(SIMD3(outward.x, outward.y, ring == 1 ? 0.7 : 0)))
                uv.append((p - center) * 3 + SIMD2(repeating: 0.5))
            }
        }
        for i in 0..<count {
            let a = UInt32(i + 1), b = UInt32((i + 1) % count + 1)
            indices += [0, a, b]
            for ring in 0..<2 {
                let offset = UInt32(ring * count), next = offset + UInt32(count)
                indices += [a + offset, a + next, b + offset, b + offset, a + next, b + next]
            }
        }
        // A separate rear cap keeps its normal independent from the bevel.
        let backCenter = UInt32(points.count)
        points.append([center.x, center.y, -depth / 2]); normals.append([0, 0, -1]); uv.append([0.5, 0.5])
        for p in outline {
            points.append([p.x, p.y, -depth / 2]); normals.append([0, 0, -1]); uv.append((p - center) * 3 + SIMD2(repeating: 0.5))
        }
        for i in 0..<count {
            indices += [backCenter, backCenter + UInt32((i + 1) % count + 1), backCenter + UInt32(i + 1)]
        }
        var descriptor = MeshDescriptor(name: "rounded-artwork-\(shape)")
        descriptor.positions = .init(points); descriptor.normals = .init(normals)
        descriptor.textureCoordinates = .init(uv); descriptor.primitives = .triangles(indices)
        let mesh = try! MeshResource.generate(from: [descriptor])
        cache[shape] = mesh
        return mesh
    }
}
