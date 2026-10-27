import Foundation
import simd

@main
struct CheckDollWalk {
    static func main() {
        let floor = DollWalkArea.Box(center: .zero, half: [1, 1])
        let empty = DollWalkArea(boundary: floor, obstacles: [])
        precondition(empty.contains([0.85, 0]))
        precondition(!empty.contains([0.87, 0]), "Keep the full doll inside the room")
        let blocked = DollWalkArea(boundary: floor, obstacles: [.init(center: .zero, half: [0.1, 0.4])])
        precondition(!blocked.canTravel(from: [-0.7, 0], to: [0.7, 0]), "Reject crossing a desk even with free endpoints")
        precondition(blocked.canTravel(from: [-0.7, 0.7], to: [0.7, 0.7]))
        let bed = DollWalkArea.Box(center: [0.1, -0.2], half: [0.5, 0.45], yaw: .pi / 4)
        let surface = DollWalkArea(boundary: bed, obstacles: [])
        precondition(surface.contains(bed.center))
        precondition(!surface.canTravel(from: bed.center, to: [0.8, 0.5]), "Cannot walk off elevated furniture")
        let rotated = DollWalkArea(boundary: floor, obstacles: [bed])
        precondition(!rotated.canTravel(from: [-0.8, -0.2], to: [0.8, -0.2]))
        let crowded = DollWalkArea(boundary: .init(center: .zero, half: [0.1, 0.1]), obstacles: [])
        precondition(!crowded.contains(.zero), "Too-small seats must remain stationary")
        for _ in 0..<1000 {
            let a = SIMD2<Float>(.random(in: -1...1), .random(in: -1...1))
            let b = SIMD2<Float>(.random(in: -1...1), .random(in: -1...1))
            if rotated.canTravel(from: a, to: b) {
                for i in 0...100 {
                    precondition(rotated.contains(simd_mix(a, b, SIMD2(repeating: Float(i) / 100))))
                }
            }
        }
        print("PASS: room bounds, furniture clearance, crossing rejection, rotated surfaces and narrow seats")
    }
}
