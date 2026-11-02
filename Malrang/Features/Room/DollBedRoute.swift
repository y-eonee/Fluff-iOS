import Foundation
import simd

/// A visibility graph routes around the complete, rotated furniture footprints.
/// Only the final climb may cross the bed footprint.
enum DollBedRoute {
    static func plan(from start: SIMD3<Float>, bed: RoomItemState, items: [RoomItemState]) -> [SIMD3<Float>]? {
        let radius: Float = 0.10
        let boxes = items.filter(\.kind.blocksFloor).map {
            DollWalkArea.Box(center: [$0.x, $0.z], half: [$0.kind.size.x / 2, $0.kind.size.z / 2], yaw: $0.yaw)
        }
        let area = DollWalkArea(boundary: .init(center: .zero, half: [1.08, 1.08]), obstacles: boxes, radius: radius)
        let origin = SIMD2(start.x, start.z)
        func world(_ local: SIMD2<Float>) -> SIMD2<Float> {
            let p = simd_act(simd_quatf(angle: bed.yaw, axis: [0, 1, 0]), SIMD3(local.x, 0, local.y))
            return [bed.x + p.x, bed.z + p.z]
        }
        let approaches = [world([0, bed.kind.size.z / 2 + radius + 0.025]),
                          world([bed.kind.size.x / 2 + radius + 0.025, 0]),
                          world([-bed.kind.size.x / 2 - radius - 0.025, 0])].filter { area.contains($0) }
        guard !approaches.isEmpty else { return nil }
        var corners: [SIMD2<Float>] = []
        for box in boxes {
            for x: Float in [-1, 1] { for z: Float in [-1, 1] {
                let local = SIMD3(x * (box.half.x + radius + 0.015), 0, z * (box.half.y + radius + 0.015))
                let p = simd_act(simd_quatf(angle: box.yaw, axis: [0, 1, 0]), local)
                let point = box.center + SIMD2(p.x, p.z)
                if area.contains(point) { corners.append(point) }
            } }
        }
        // An elevated doll first steps down beside its chair; other furniture still blocks that step.
        let startArea = DollWalkArea(boundary: area.boundary, obstacles: boxes.filter { !$0.contains(origin, margin: radius) }, radius: radius)
        var entrances = [origin]
        if !area.contains(origin) {
            entrances = []
            for distance: Float in [0.18, 0.30, 0.45, 0.60] {
                for i in 0..<16 {
                    let angle = Float(i) * .pi / 8
                    let point = origin + SIMD2(cos(angle), sin(angle)) * distance
                    if area.contains(point), startArea.canTravel(from: origin, to: point) { entrances.append(point) }
                }
            }
        }
        var best: [SIMD2<Float>]?
        var bestLength = Float.infinity
        for entrance in entrances {
            let nodes = [entrance] + corners + approaches
            var distances = [Float](repeating: .infinity, count: nodes.count)
            var previous = [Int?](repeating: nil, count: nodes.count)
            var visited = Set<Int>()
            distances[0] = simd_distance(origin, entrance)
            while let current = nodes.indices.filter({ !visited.contains($0) && distances[$0].isFinite }).min(by: { distances[$0] < distances[$1] }) {
                visited.insert(current)
                for next in nodes.indices where !visited.contains(next) && area.canTravel(from: nodes[current], to: nodes[next]) {
                    let length = distances[current] + simd_distance(nodes[current], nodes[next])
                    if length < distances[next] { distances[next] = length; previous[next] = current }
                }
            }
            for end in (nodes.count - approaches.count)..<nodes.count where distances[end] < bestLength {
                var index: Int? = end, route: [SIMD2<Float>] = []
                while let i = index { route.append(nodes[i]); index = previous[i] }
                best = route.reversed(); bestLength = distances[end]
            }
        }
        guard let best else { return nil }
        return best.map { SIMD3($0.x, 0, $0.y) }
    }
}
