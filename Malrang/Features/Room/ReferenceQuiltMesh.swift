import Foundation
import RealityKit

/// A thin textile surface rolls over the mattress edges. The same cached mesh
/// is reused through bedding poses; no simulation or geometry updates per frame.
@MainActor
enum ReferenceQuiltMesh {
    private static var meshes: [String: MeshResource] = [:]
    static func clearCache() { meshes.removeAll() }
    /// A single cached surface follows the seat and falls over its front edge.
    /// Pleats and fringe are baked into the mesh, with no cloth simulation.
    static func sofaThrow(width: Float, depth: Float) -> MeshResource {
        let key = "sofa-\(width)-\(depth)"
        if let mesh = meshes[key] { return mesh }
        let rows = 30, columns = 24
        func point(_ u: Float, _ v: Float) -> SIMD3<Float> {
            let fold = sin(u * 45 + v * 0.8) * 0.0008 + sin(u * 19 - v) * 0.0005
            let start = -depth * 0.27, lip = depth * 0.49
            if v < 0.70 {
                return [u * width * 0.5, 0.168 + fold, start + (lip - start) * v / 0.70]
            }
            let t = (v - 0.70) / 0.30
            return [u * width * 0.5, 0.168 - 0.142 * sin(t * .pi / 2), lip + 0.026 * sin(t * .pi / 2) + fold]
        }
        var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = [], indices: [UInt32] = []
        for row in 0...rows {
            let v = Float(row) / Float(rows)
            for column in 0...columns {
                let u = Float(column) / Float(columns) * 2 - 1
                positions.append(point(u, v))
                let du = point(u + 0.001, v) - point(u - 0.001, v)
                let dv = point(u, min(1, v + 0.001)) - point(u, max(0, v - 0.001))
                normals.append(simd_normalize(simd_cross(dv, du)))
                uv.append([(u + 1) / 2, v])
                if row < rows && column < columns {
                    let a = UInt32(row * (columns + 1) + column), b = a + UInt32(columns + 1)
                    indices += [a, b, a + 1, a + 1, b, b + 1]
                }
            }
        }
        for strand in 0..<38 {
            let u = Float(strand) / 37 * 2 - 1
            let p = point(u, 1), a = UInt32(positions.count)
            let length: Float = 0.014 + Float(strand % 4) * 0.002
            positions += [p + [-0.0012, 0, 0], p + [0.0012, 0, 0], p + [-0.001, -length, 0.001], p + [0.001, -length, 0.001]]
            normals += Array(repeating: [0, 0, 1], count: 4)
            uv += [[u, 1], [u + 0.01, 1], [u, 1.05], [u + 0.01, 1.05]]
            indices += [a, a + 2, a + 1, a + 1, a + 2, a + 3]
        }
        var descriptor = MeshDescriptor(name: "sofa-draped-throw")
        descriptor.positions = .init(positions); descriptor.normals = .init(normals)
        descriptor.textureCoordinates = .init(uv); descriptor.primitives = .triangles(indices)
        let mesh = (try? MeshResource.generate(from: [descriptor])) ?? .generateBox(size: [width, 0.01, depth])
        meshes[key] = mesh
        return mesh
    }
    static func make(size: SIMD3<Float>) -> MeshResource {
        let key = String(describing: size)
        if let mesh = meshes[key] { return mesh }
        let rows = 24, columns = 40
        func point(_ u: Float, _ v: Float) -> SIMD3<Float> {
            // Turn down only after clearing the mattress; an earlier fold
            // intersected its rounded sides and exposed white patches.
            let side = pow(max(0, (abs(u) - 0.90) / 0.10), 1.3) * size.y * 0.65
            let foot = pow(max(0, (v - 0.86) / 0.14), 1.3) * size.y * 0.90
            let ripple = sin(u * 17 + v * 2) * 0.003 + sin(v * 25) * 0.0015
            let corner = max(0, abs(u) - 0.84) * max(0, abs(v) - 0.84) * 0.5
            return [u * size.x * 0.5 * (1 - corner), size.y * 0.5 - max(side, foot) + ripple,
                    v * size.z * 0.5 * (1 - corner)]
        }
        var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], uv: [SIMD2<Float>] = [], indices: [UInt32] = []
        for row in 0...rows {
            let v = Float(row) / Float(rows) * 2 - 1
            for column in 0...columns {
                let u = Float(column) / Float(columns) * 2 - 1
                positions.append(point(u, v))
                let du = point(min(1, u + 0.001), v) - point(max(-1, u - 0.001), v)
                let dv = point(u, min(1, v + 0.001)) - point(u, max(-1, v - 0.001))
                normals.append(simd_normalize(simd_cross(dv, du)))
                uv.append([(u + 1) / 2, (v + 1) / 2])
                if row < rows && column < columns {
                    let a = UInt32(row * (columns + 1) + column), b = a + UInt32(columns + 1)
                    indices += [a, b, a + 1, a + 1, b, b + 1]
                }
            }
        }
        var descriptor = MeshDescriptor(name: "reference-draped-quilt")
        descriptor.positions = .init(positions); descriptor.normals = .init(normals)
        descriptor.textureCoordinates = .init(uv); descriptor.primitives = .triangles(indices)
        let mesh = (try? MeshResource.generate(from: [descriptor])) ?? .generateBox(size: size)
        meshes[key] = mesh
        return mesh
    }
}
