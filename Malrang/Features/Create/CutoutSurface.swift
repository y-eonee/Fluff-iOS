import Foundation
import simd

/// Clip a dense triangular surface to the interpolated image alpha contour.
/// Shared vertices keep the inflated surface smooth; paired contour edges close the seam.
enum CutoutSurface {
    struct Mesh {
        var positions: [SIMD3<Float>]
        var normals: [SIMD3<Float>]
        var uv: [SIMD2<Float>]
        var indices: [UInt32]
    }
    struct Geometry { let front: Mesh; let back: Mesh; let seam: Mesh }
    private struct Vertex { var p: SIMD2<Float>; var alpha: Float; var depth: Float }
    private struct Key: Hashable { let x: Int; let y: Int }

    static func make(alpha: [Float], columns: Int, rows: Int, aspect: Float, height: Float) -> Geometry {
        precondition(columns > 1 && rows > 1 && alpha.count == columns * rows)
        let threshold: Float = 0.50
        let size = Float(max(columns - 1, rows - 1))
        var distance = alpha.map { $0 >= threshold ? size : 0 }
        for y in 0..<rows {
            for x in 0..<columns {
                let i = y * columns + x
                if x == 0 || y == 0 || x == columns - 1 || y == rows - 1 { distance[i] = 0 }
                if x > 0 { distance[i] = min(distance[i], distance[i - 1] + 1) }
                if y > 0 { distance[i] = min(distance[i], distance[i - columns] + 1) }
                if x > 0 && y > 0 { distance[i] = min(distance[i], distance[i - columns - 1] + 1.4142) }
                if x + 1 < columns && y > 0 { distance[i] = min(distance[i], distance[i - columns + 1] + 1.4142) }
            }
        }
        for y in (0..<rows).reversed() {
            for x in (0..<columns).reversed() {
                let i = y * columns + x
                if x + 1 < columns { distance[i] = min(distance[i], distance[i + 1] + 1) }
                if y + 1 < rows { distance[i] = min(distance[i], distance[i + columns] + 1) }
                if x + 1 < columns && y + 1 < rows { distance[i] = min(distance[i], distance[i + columns + 1] + 1.4142) }
                if x > 0 && y + 1 < rows { distance[i] = min(distance[i], distance[i + columns - 1] + 1.4142) }
            }
        }
        // Round the distance field before inflation so the cloth has no diagonal
        // ridges where distances from different edges meet.
        for _ in 0..<3 {
            let previous = distance
            for y in 1..<(rows - 1) {
                for x in 1..<(columns - 1) where alpha[y * columns + x] >= threshold {
                    let i = y * columns + x
                    var value = previous[i] * 4
                    for dy in -1...1 {
                        for dx in -1...1 where dx != 0 || dy != 0 { value += previous[i + dy * columns + dx] }
                    }
                    distance[i] = value / 12
                }
            }
        }
        var front = Mesh(positions: [], normals: [], uv: [], indices: [])
        var seam = Mesh(positions: [], normals: [], uv: [], indices: [])
        var vertexIDs: [Key: UInt32] = [:]
        func vertex(_ x: Int, _ y: Int) -> Vertex {
            let i = y * columns + x
            return Vertex(p: [Float(x) / Float(columns - 1), Float(y) / Float(rows - 1)],
                          alpha: alpha[i], depth: 0.015 + 0.045 * (1 - exp(-distance[i] / (size * 0.075))))
        }
        func position(_ v: Vertex, back: Bool = false) -> SIMD3<Float> {
            [(v.p.x - 0.5) * height * aspect, v.p.y * height, back ? -v.depth : v.depth]
        }
        func index(_ v: Vertex) -> UInt32 {
            let key = Key(x: Int((v.p.x * 1_000_000).rounded()), y: Int((v.p.y * 1_000_000).rounded()))
            if let id = vertexIDs[key] { return id }
            let id = UInt32(front.positions.count)
            vertexIDs[key] = id
            front.positions.append(position(v)); front.uv.append(v.p)
            return id
        }
        func clip(_ triangle: [Vertex]) {
            var polygon: [Vertex] = []
            var crossings: [(vertex: Vertex, exiting: Bool)] = []
            for i in 0..<3 {
                let a = triangle[i], b = triangle[(i + 1) % 3]
                let insideA = a.alpha >= threshold, insideB = b.alpha >= threshold
                if insideA { polygon.append(a) }
                if insideA != insideB {
                    let t = (threshold - a.alpha) / (b.alpha - a.alpha)
                    let edge = Vertex(p: a.p + (b.p - a.p) * t, alpha: threshold, depth: 0.015)
                    polygon.append(edge); crossings.append((edge, insideA))
                }
            }
            guard polygon.count >= 3 else { return }
            let ids = polygon.map(index)
            for i in 1..<(ids.count - 1) { front.indices += [ids[0], ids[i], ids[i + 1]] }
            if crossings.count == 2 {
                let a = crossings.first { $0.exiting }!.vertex, b = crossings.first { !$0.exiting }!.vertex
                let start = UInt32(seam.positions.count)
                seam.positions += [position(a), position(b), position(b, back: true), position(a, back: true)]
                seam.uv += [[a.p.x + a.p.y, 0], [b.p.x + b.p.y, 0], [b.p.x + b.p.y, 1], [a.p.x + a.p.y, 1]]
                seam.indices += [start, start + 2, start + 1, start, start + 3, start + 2]
            }
        }
        for y in 0..<(rows - 1) {
            for x in 0..<(columns - 1) {
                let a = vertex(x, y), b = vertex(x + 1, y), c = vertex(x + 1, y + 1), d = vertex(x, y + 1)
                clip([a, b, c]); clip([a, c, d])
            }
        }
        func smoothNormals(_ mesh: inout Mesh) {
            mesh.normals = Array(repeating: .zero, count: mesh.positions.count)
            for i in stride(from: 0, to: mesh.indices.count, by: 3) {
                let a = Int(mesh.indices[i]), b = Int(mesh.indices[i + 1]), c = Int(mesh.indices[i + 2])
                let n = simd_cross(mesh.positions[b] - mesh.positions[a], mesh.positions[c] - mesh.positions[a])
                mesh.normals[a] += n; mesh.normals[b] += n; mesh.normals[c] += n
            }
            mesh.normals = mesh.normals.map { simd_length_squared($0) > 0.000000000001 ? simd_normalize($0) : [0, 0, 1] }
        }
        smoothNormals(&front); smoothNormals(&seam)
        var back = front
        back.positions = front.positions.map { [$0.x, $0.y, -$0.z] }
        back.normals = front.normals.map { [$0.x, $0.y, -$0.z] }
        for i in stride(from: 0, to: back.indices.count, by: 3) { back.indices.swapAt(i + 1, i + 2) }
        return Geometry(front: front, back: back, seam: seam)
    }
}
