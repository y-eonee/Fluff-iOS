import Foundation
import RealityKit

enum DollPart: String { case leftArm, rightArm, leftLeg, rightLeg }
enum Kind { case bed, chair, sofa, obstacle
    var size: SIMD3<Float> { [0.5, 0.3, 0.5] }
    var seatHeight: Float? { self == .obstacle ? nil : 0.3 }
    var blocksFloor: Bool { true }
}
struct RoomItemState { var id = UUID(); var kind: Kind; var x: Float; var z: Float; var yaw: Float = 0 }
struct DollState { var id: UUID; var preset: Int? = 1; var dance: Int? = nil }
enum SceneFactory { static let dollHeight: Float = 0.45 }
enum RoomLayout {
    static func seat(at point: SIMD2<Float>, in items: [RoomItemState]) -> (height: Float, item: RoomItemState?) { (0, nil) }
    static func furnitureHeight(_ item: RoomItemState, in items: [RoomItemState]) -> Float { 0 }
}

@main
struct CheckRoomWander {
    @MainActor static func main() {
        let content = Entity()
        let states = [DollState(id: UUID()), DollState(id: UUID()), DollState(id: UUID(), preset: nil), DollState(id: UUID(), dance: 1)]
        var entities: [Entity] = []
        for (index, state) in states.enumerated() {
            let doll = Entity(); doll.name = "doll|\(state.id)"; doll.position = [Float(index) * 0.4 - 0.6, 0, 0]
            let body = Entity(); body.name = "body"; body.position.y = 0.225; doll.addChild(body)
            for part in [DollPart.leftArm, .rightArm, .leftLeg, .rightLeg] {
                let limb = Entity(); limb.name = part.rawValue; body.addChild(limb)
            }
            content.addChild(doll); entities.append(doll)
        }
        let starts = entities.map(\.position)
        let motion = RoomDollWander(content: content, states: states, items: [])
        var moved = false, posed = false
        for _ in 0..<1500 {
            motion.update(delta: 1.0 / 30, running: true)
            moved = moved || simd_distance(entities[0].position, starts[0]) > 0.03
            posed = posed || abs(entities[0].findEntity(named: "leftLeg")!.orientation.angle) > 0.01
            precondition(abs(entities[0].position.x) <= 0.86 && abs(entities[0].position.z) <= 0.86)
            precondition(simd_distance(entities[0].position, entities[1].position) >= 0.299)
        }
        precondition(moved && posed, "Walking must change both position and limb poses")
        precondition(entities[2].position == starts[2] && entities[3].position == starts[3], "Cutouts and dancing dolls stay untouched")
        motion.update(delta: 1, running: false)
        let stopped = entities.map(\.position)
        for _ in 0..<100 { motion.update(delta: 1, running: false) }
        precondition(entities.map(\.position) == stopped, "Paused scenes must not drift")
        precondition(abs(entities[0].findEntity(named: "leftLeg")!.orientation.angle) < 0.001)
        precondition(entities[0].findEntity(named: "body")!.position.y == 0.225)
        for _ in 0..<300 { motion.update(delta: 1.0 / 30, running: true) }
        precondition(entities[0].position != stopped[0], "Resume must restart motion")
        print("PASS: wandering, gait, bounds, doll avoidance, pause/reset/resume, cutout/dance exclusion")
    }
}
