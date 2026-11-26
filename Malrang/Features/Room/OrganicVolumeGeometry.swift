import Foundation
import simd

/// A smooth union is meshed as one closed surface, without intersecting sphere seams.
nonisolated enum OrganicVolumeGeometry {
    struct Lobe: Sendable { let center: SIMD3<Float>; let radius: SIMD3<Float> }
    struct Surface: Sendable {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = []
        var indices: [UInt32] = []
    }
    private struct Edge: Hashable { let a: Int; let b: Int }
    static func build(lobes: [Lobe], blend: Float, resolution: Int = 60, seed: Int = 0) -> Surface {
        guard let first = lobes.first else { return Surface() }
        let minimum = lobes.reduce(first.center - first.radius) { simd_min($0, $1.center - $1.radius) } - SIMD3(repeating: blend * 2)
        let maximum = lobes.reduce(first.center + first.radius) { simd_max($0, $1.center + $1.radius) } + SIMD3(repeating: blend * 2)
        let extent = maximum - minimum, longest = max(extent.x, max(extent.y, extent.z))
        let nx = max(8, Int(ceil(extent.x / longest * Float(resolution))))
        let ny = max(8, Int(ceil(extent.y / longest * Float(resolution))))
        let nz = max(8, Int(ceil(extent.z / longest * Float(resolution))))
        let size = SIMD3<Float>(Float(nx), Float(ny), Float(nz))
        func field(_ p: SIMD3<Float>) -> Float {
            var distance = Float.greatestFiniteMagnitude
            for lobe in lobes {
                let q = p - lobe.center
                let a = simd_length(q / lobe.radius), b = simd_length(q / (lobe.radius * lobe.radius))
                let d = b < 0.00001 ? -min(lobe.radius.x, min(lobe.radius.y, lobe.radius.z)) : a * (a - 1) / b
                let h = max(0, blend - abs(distance - d)) / blend
                distance = min(distance, d) - h * h * blend * 0.25
            }
            let phase = Float(seed) * 0.73
            return distance + 0.0025 * sin(p.x * 41 + phase) * sin(p.y * 37) * cos(p.z * 43 - phase)
        }
        func normal(_ p: SIMD3<Float>) -> SIMD3<Float> {
            let e: Float = 0.0005
            let n = SIMD3<Float>(field(p + [e, 0, 0]) - field(p - [e, 0, 0]),
                                field(p + [0, e, 0]) - field(p - [0, e, 0]),
                                field(p + [0, 0, e]) - field(p - [0, 0, e]))
            return simd_length_squared(n) > 1e-15 ? simd_normalize(n) : [0, 1, 0]
        }
        let row = nx + 1, plane = row * (ny + 1), count = plane * (nz + 1)
        var grid = [SIMD3<Float>](repeating: .zero, count: count), values = [Float](repeating: 0, count: count)
        for z in 0...nz { for y in 0...ny { for x in 0...nx {
            let i = z * plane + y * row + x
            grid[i] = minimum + SIMD3(Float(x), Float(y), Float(z)) / size * extent
            values[i] = field(grid[i])
        } } }
        var result = Surface(), vertices: [Edge: UInt32] = [:]
        func crossing(_ a: Int, _ b: Int) -> UInt32 {
            let key = Edge(a: min(a, b), b: max(a, b))
            if let old = vertices[key] { return old }
            let t = values[a] / (values[a] - values[b]), p = grid[a] + (grid[b] - grid[a]) * t
            let index = UInt32(result.positions.count)
            result.positions.append(p); result.normals.append(normal(p))
            result.uv.append([(p.x - minimum.x) / extent.x, (p.y - minimum.y) / extent.y])
            vertices[key] = index
            return index
        }
        let edges = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let tetrahedra = [[0, 5, 1, 6], [0, 1, 2, 6], [0, 2, 3, 6], [0, 3, 7, 6], [0, 7, 4, 6], [0, 4, 5, 6]]
        for z in 0..<nz { for y in 0..<ny { for x in 0..<nx {
            let i = z * plane + y * row + x
            let cube = [i, i + 1, i + row + 1, i + row, i + plane, i + plane + 1, i + plane + row + 1, i + plane + row]
            guard cube.contains(where: { values[$0] < 0 }) && cube.contains(where: { values[$0] >= 0 }) else { continue }
            for tetra in tetrahedra {
                let ids = tetra.map { cube[$0] }
                var polygon: [UInt32] = []
                for (a, b) in edges where (values[ids[a]] < 0) != (values[ids[b]] < 0) { polygon.append(crossing(ids[a], ids[b])) }
                guard polygon.count >= 3 else { continue }
                let center = polygon.reduce(SIMD3<Float>.zero) { $0 + result.positions[Int($1)] } / Float(polygon.count)
                let n = normal(center), tangent = simd_normalize(simd_cross(n, abs(n.y) < 0.9 ? SIMD3<Float>(0, 1, 0) : [1, 0, 0]))
                let other = simd_cross(n, tangent)
                polygon.sort {
                    let a = result.positions[Int($0)] - center, b = result.positions[Int($1)] - center
                    return atan2(simd_dot(a, other), simd_dot(a, tangent)) < atan2(simd_dot(b, other), simd_dot(b, tangent))
                }
                for j in 1..<(polygon.count - 1) { result.indices += [polygon[0], polygon[j], polygon[j + 1]] }
            }
        } } }
        return result
    }
}
