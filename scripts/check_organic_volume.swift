import Foundation
import simd

@main struct OrganicVolumeChecks {
    struct Edge: Hashable {
        let a: UInt32; let b: UInt32
        init(_ a: UInt32, _ b: UInt32) { self.a = min(a, b); self.b = max(a, b) }
    }
    static func main() {
        let shapes: [[OrganicVolumeGeometry.Lobe]] = [
            [.init(center: .zero, radius: [0.43, 0.22, 0.19])],
            [.init(center: [-0.19, 0.075, 0.01], radius: [0.22, 0.22, 0.20]),
             .init(center: [0.055, 0.15, -0.015], radius: [0.24, 0.255, 0.22]),
             .init(center: [0.29, 0.045, 0.015], radius: [0.20, 0.18, 0.18])]
        ]
        for (caseIndex, lobes) in shapes.enumerated() {
            let model = OrganicVolumeGeometry.build(lobes: lobes, blend: 0.065, resolution: 64, seed: caseIndex)
            precondition(!model.indices.isEmpty)
            precondition(model.positions.count == model.normals.count && model.positions.count == model.uv.count)
            precondition(model.normals.allSatisfy { $0.x.isFinite && $0.y.isFinite && $0.z.isFinite && abs(simd_length($0) - 1) < 0.001 })
            var edges: [Edge: Int] = [:], adjacency: [UInt32: Set<UInt32>] = [:]
            for i in stride(from: 0, to: model.indices.count, by: 3) {
                let ids = Array(model.indices[i..<i + 3])
                let a = model.positions[Int(ids[0])], b = model.positions[Int(ids[1])], c = model.positions[Int(ids[2])]
                let cross = simd_cross(b - a, c - a)
                precondition(cross.x.isFinite && cross.y.isFinite && cross.z.isFinite)
                let normal = ids.reduce(SIMD3<Float>.zero) { $0 + model.normals[Int($1)] }
                precondition(simd_dot(cross, normal) >= -1e-10, "Triangle must face outwards")
                for j in 0..<3 {
                    let a = ids[j], b = ids[(j + 1) % 3]
                    edges[Edge(a, b), default: 0] += 1
                    adjacency[a, default: []].insert(b); adjacency[b, default: []].insert(a)
                }
            }
            precondition(edges.values.allSatisfy { $0 == 2 }, "Every surface edge must be closed")
            var visited: Set<UInt32> = [0], queue: [UInt32] = [0]
            while let id = queue.popLast() {
                for next in adjacency[id, default: []] where visited.insert(next).inserted { queue.append(next) }
            }
            precondition(visited.count == model.positions.count, "Overlapping lobes must become one connected surface")
            precondition(model.positions.count - edges.count + model.indices.count / 3 == 2, "Closed surface must have no accidental holes")
            print("PASS: shape \(caseIndex), \(model.positions.count) vertices — closed, connected, outward normals")
        }
        precondition(OrganicVolumeGeometry.build(lobes: [], blend: 0.065).positions.isEmpty)
        print("PASS: empty volume")
    }
}
