import Foundation
import simd

@main struct CutoutSurfaceChecks {
    struct Point: Hashable {
        let x: Int; let y: Int; let z: Int
        init(_ p: SIMD3<Float>) { x = Int((p.x * 100_000).rounded()); y = Int((p.y * 100_000).rounded()); z = Int((p.z * 100_000).rounded()) }
    }
    struct Edge: Hashable {
        let a: Point; let b: Point
        init(_ a: Point, _ b: Point) {
            if [a.x, a.y, a.z].lexicographicallyPrecedes([b.x, b.y, b.z]) { self.a = a; self.b = b }
            else { self.a = b; self.b = a }
        }
    }
    static func main() {
        for shape in ["circle", "concave", "separate", "empty"] {
            let count = 97
            let alpha: [Float] = (0..<count * count).map { i in
                let p = SIMD2<Float>(Float(i % count) / Float(count - 1), Float(i / count) / Float(count - 1))
                let distance: Float
                switch shape {
                case "circle": distance = simd_distance(p, [0.5, 0.5]) - 0.34
                case "concave": distance = max(simd_distance(p, [0.5, 0.5]) - 0.37, 0.28 - simd_distance(p, [0.69, 0.59]))
                case "separate": distance = min(simd_distance(p, [0.25, 0.5]) - 0.16, simd_distance(p, [0.75, 0.5]) - 0.16)
                default: distance = 1
                }
                return min(1, max(0, 0.5 - distance * Float(count)))
            }
            let model = CutoutSurface.make(alpha: alpha, columns: count, rows: count, aspect: 1, height: 0.54)
            if shape == "empty" { precondition(model.front.indices.isEmpty && model.seam.indices.isEmpty); continue }
            var edges: [Edge: Int] = [:]
            for mesh in [model.front, model.back, model.seam] {
                precondition(mesh.positions.count == mesh.normals.count && mesh.positions.count == mesh.uv.count)
                precondition(mesh.normals.allSatisfy { $0.x.isFinite && abs(simd_length($0) - 1) < 0.001 })
                for i in stride(from: 0, to: mesh.indices.count, by: 3) {
                    let points = (0..<3).map { Point(mesh.positions[Int(mesh.indices[i + $0])]) }
                    guard Set(points).count == 3 else { continue }
                    for j in 0..<3 { edges[Edge(points[j], points[(j + 1) % 3]), default: 0] += 1 }
                }
            }
            precondition(edges.values.allSatisfy { $0 == 2 }, "\(shape): front/back/seam must form a closed surface")
            precondition(model.front.normals.allSatisfy { $0.z > 0 }, "Front surface normals must point toward the photo")
            precondition(model.back.normals.allSatisfy { $0.z < 0 }, "Back surface normals must face away from photo")
            if shape == "circle" {
                let contour = model.seam.positions.filter { $0.z > 0 }
                let errors = contour.map { abs(simd_length(SIMD2<Float>($0.x / 0.54, $0.y / 0.54 - 0.5)) - 0.34) }
                precondition(errors.max()! < 0.25 / Float(count - 1), "Curved contour must stay within a quarter of one sample cell")
            }
            print("PASS: \(shape) — smooth contour, closed seam and consistent normals")
        }
        print("PASS: transparent input produces no geometry")
    }
}
