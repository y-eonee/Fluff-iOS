import RealityKit

/// The reference uses a rising ceiling; a level ceiling cannot reproduce its
/// cornice lines and the downward view of the furniture with the same camera.
enum CozyRoomShell {
    static let cornerHeight: Float = 1.48
    static let riseX: Float = 0.2644
    static let riseZ: Float = 0.3976
    static let maximumHeight = cornerHeight + 2 * (riseX + riseZ)

    static func height(x: Float, z: Float) -> Float {
        cornerHeight + riseX * (x + 1) + riseZ * (z + 1)
    }

    static func panel(size: SIMD2<Float>, center: SIMD2<Float>, cutaway: Bool = false) -> MeshResource {
        let lo = center - size / 2, hi = center + size / 2
        let vertices: [SIMD3<Float>] = [
            [lo.x, 0, lo.y], [hi.x, 0, lo.y], [hi.x, 0, hi.y], [lo.x, 0, hi.y],
            [lo.x, (cutaway ? 1.50 : height(x: lo.x, z: lo.y)), lo.y], [hi.x, (cutaway ? 1.50 : height(x: hi.x, z: lo.y)), lo.y],
            [hi.x, (cutaway ? 1.50 : height(x: hi.x, z: hi.y)), hi.y], [lo.x, (cutaway ? 1.50 : height(x: lo.x, z: hi.y)), hi.y]
        ]
        let faces = [[0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]]
        var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = [], indices: [UInt32] = []
        for face in faces {
            let normal = simd_normalize(simd_cross(vertices[face[1]] - vertices[face[0]], vertices[face[2]] - vertices[face[0]]))
            let start = UInt32(positions.count)
            positions += face.map { vertices[$0] }
            normals += Array(repeating: normal, count: 4)
            uv += [[0, 0], [1, 0], [1, 1], [0, 1]]
            indices += [start, start + 1, start + 2, start, start + 2, start + 3]
        }
        var mesh = MeshDescriptor(name: "sloped-room-panel")
        mesh.positions = .init(positions)
        mesh.normals = .init(normals)
        mesh.textureCoordinates = .init(uv)
        mesh.primitives = .triangles(indices)
        return (try? MeshResource.generate(from: [mesh])) ?? .generateBox(size: [size.x, cornerHeight, size.y])
    }

    static func ceiling() -> MeshResource {
        let corners: [SIMD2<Float>] = [[-4, -4], [4, -4], [4, 4], [-4, 4]]
        var mesh = MeshDescriptor(name: "sloped-ceiling")
        mesh.positions = .init(corners.map { [$0.x, height(x: $0.x, z: $0.y) + 0.015, $0.y] })
        mesh.normals = .init(Array(repeating: simd_normalize(SIMD3<Float>(riseX, -1, riseZ)), count: 4))
        mesh.textureCoordinates = .init([[0, 0], [1, 0], [1, 1], [0, 1]])
        mesh.primitives = .triangles([0, 1, 2, 0, 2, 3])
        return (try? MeshResource.generate(from: [mesh])) ?? .generatePlane(width: 8, depth: 8)
    }
}
