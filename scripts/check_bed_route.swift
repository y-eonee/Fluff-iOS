import Foundation
import simd

enum Kind {
    case bed, desk
    var blocksFloor: Bool { true }
    var size: SIMD3<Float> { self == .bed ? [0.98, 0.67, 0.922] : [0.45, 0.5, 0.4] }
}
struct RoomItemState { var id = UUID(); var kind: Kind; var x: Float; var z: Float; var yaw: Float = 0 }

@main struct CheckBedRoute {
    static func main() {
        for yaw: Float in [0, .pi / 2, .pi, .pi * 1.5, 0.63] {
            let bed = RoomItemState(kind: .bed, x: 0, z: -0.15, yaw: yaw)
            let desk = RoomItemState(kind: .desk, x: 0.60, z: 0.18, yaw: 0.42)
            let items = [bed, desk]
            let start: SIMD3<Float> = [0.75, 0, 0.8]
            guard let route = DollBedRoute.plan(from: start, bed: bed, items: items) else { preconditionFailure("No path for yaw \(yaw)") }
            let area = DollWalkArea(boundary: .init(center: .zero, half: [1.08, 1.08]), obstacles: items.map { .init(center: [$0.x, $0.z], half: [$0.kind.size.x / 2, $0.kind.size.z / 2], yaw: $0.yaw) }, radius: 0.10)
            precondition(route.allSatisfy { abs($0.y) < 0.001 }, "Walking stays on the floor before the climb")
            for (a, b) in zip(route, route.dropFirst()) { precondition(area.canTravel(from: [a.x, a.z], to: [b.x, b.z]), "Crossed a rotated furniture footprint") }
            let last = route.last!
            let local = simd_act(simd_quatf(angle: -yaw, axis: [0, 1, 0]), last - SIMD3(bed.x, 0, bed.z))
            precondition(local.z > 0 || abs(local.x) > bed.kind.size.x / 2, "Approach must not come through the headboard")
        }
        let bed = RoomItemState(kind: .bed, x: 0, z: 0)
        let barriers = [RoomItemState(kind: .desk, x: 0, z: 0.60), RoomItemState(kind: .desk, x: 0.62, z: 0), RoomItemState(kind: .desk, x: -0.62, z: 0)]
        precondition(DollBedRoute.plan(from: [0.8, 0, 0.8], bed: bed, items: [bed] + barriers) == nil, "An inaccessible bed must not cause furniture crossings")
        print("PASS: floor route, furniture avoidance, five bed rotations, headboard exclusion, inaccessible bed")
    }
}
