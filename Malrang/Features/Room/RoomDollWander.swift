import Foundation
import RealityKit

/// Scene-local motion: saved placements and cached model templates are never changed.
@MainActor
final class RoomDollWander {
    private struct Walker {
        let entity: Entity
        let area: DollWalkArea
        let body: Entity
        let bodyPose: Transform
        let parts: [(part: DollPart, entity: Entity, pose: Transform)]
        var destination: SIMD2<Float>?
        var rest = Float.random(in: 0.5...2)
        var phase: Float = 0
    }
    private var walkers: [Walker] = []
    private var dolls: [Entity] = []
    private var elapsed: TimeInterval = 0
    private var wasRunning = false

    init(content: Entity, states: [DollState], items: [RoomItemState]) {
        dolls = states.compactMap { content.findEntity(named: "doll|\($0.id)") }
        func box(_ item: RoomItemState) -> DollWalkArea.Box {
            .init(center: [item.x, item.z], half: [item.kind.size.x / 2, item.kind.size.z / 2], yaw: item.yaw)
        }
        for state in states where state.preset != nil && state.dance == nil {
            guard let entity = content.findEntity(named: "doll|\(state.id)"),
                  let body = entity.findEntity(named: "body") else { continue }
            let point = SIMD2(entity.position.x, entity.position.z)
            let support = RoomLayout.seat(at: point, in: items).item
            let elevated = support.flatMap { ($0.kind.seatHeight ?? 0) > 0.02 ? $0 : nil }
            var boundary = elevated.map(box) ?? .init(center: .zero, half: [1, 1])
            if let elevated, elevated.kind == .bed || elevated.kind == .chair || elevated.kind == .sofa {
                // Keep clear of pillows and the backrest as well as the outer edge.
                let inset: Float = elevated.kind == .bed ? 0.12 : 0.05
                boundary.half.y -= inset / 2
                boundary.center += SIMD2(sin(elevated.yaw), cos(elevated.yaw)) * (inset / 2)
            }
            let obstacles = items.filter {
                guard $0.id != elevated?.id, $0.kind.blocksFloor else { return false }
                let bottom = RoomLayout.furnitureHeight($0, in: items)
                return bottom < entity.position.y + SceneFactory.dollHeight
                    && bottom + $0.kind.size.y > entity.position.y + 0.025
            }.map(box)
            let area = DollWalkArea(boundary: boundary, obstacles: obstacles)
            // A tightly packed placement stays still instead of teleporting to a free space.
            guard area.contains(point) else { continue }
            let parts = [DollPart.leftArm, .rightArm, .leftLeg, .rightLeg].compactMap { part -> (DollPart, Entity, Transform)? in
                guard let limb = entity.findEntity(named: part.rawValue) else { return nil }
                return (part, limb, limb.transform)
            }
            walkers.append(Walker(entity: entity, area: area, body: body, bodyPose: body.transform, parts: parts))
        }
    }

    func update(delta: TimeInterval, running: Bool) {
        guard running else {
            if wasRunning {
                for walker in walkers { resetPose(walker) }
                for index in walkers.indices { walkers[index].destination = nil; walkers[index].rest = 0.6 }
            }
            wasRunning = false; elapsed = 0
            return
        }
        wasRunning = true
        elapsed += min(delta, 0.1)
        guard elapsed >= 1.0 / 30 else { return }
        let dt = Float(min(elapsed, 0.07)); elapsed = 0
        for index in walkers.indices {
            var walker = walkers[index]
            let point = SIMD2(walker.entity.position.x, walker.entity.position.z)
            if let target = walker.destination {
                let distance = simd_distance(point, target)
                if distance < 0.012 {
                    walker.destination = nil; walker.rest = .random(in: 1.2...3.5)
                    resetPose(walker)
                } else {
                    let direction = (target - point) / distance
                    let next = point + direction * min(distance, dt * 0.085)
                    if walker.area.canTravel(from: point, to: next) && isFree(next, for: walker.entity) {
                        walker.entity.position.x = next.x; walker.entity.position.z = next.y
                        let facing = simd_quatf(angle: atan2(direction.x, direction.y), axis: [0, 1, 0])
                        walker.entity.orientation = simd_slerp(walker.entity.orientation, facing, min(1, dt * 5))
                        walker.phase += dt * 9
                        pose(walker)
                    } else {
                        walker.destination = nil; walker.rest = .random(in: 0.5...1.5)
                        resetPose(walker)
                    }
                }
            } else {
                walker.rest -= dt
                if walker.rest <= 0 {
                    // Short, checked segments naturally meander without per-frame path allocation.
                    for _ in 0..<20 {
                        let angle = Float.random(in: -.pi ... .pi), length = Float.random(in: 0.12...0.55)
                        let candidate = point + SIMD2(sin(angle), cos(angle)) * length
                        if walker.area.canTravel(from: point, to: candidate) && isFree(candidate, for: walker.entity) {
                            walker.destination = candidate; break
                        }
                    }
                    walker.rest = .random(in: 1...2)
                }
            }
            walkers[index] = walker
        }
    }

    private func isFree(_ point: SIMD2<Float>, for entity: Entity) -> Bool {
        dolls.allSatisfy { other in
            other === entity || abs(other.position.y - entity.position.y) > 0.3
                || simd_distance(point, SIMD2(other.position.x, other.position.z)) >= 0.30
        }
    }

    private func resetPose(_ walker: Walker) {
        walker.body.transform = walker.bodyPose
        for limb in walker.parts { limb.entity.transform = limb.pose }
    }

    private func pose(_ walker: Walker) {
        let swing = sin(walker.phase)
        var body = walker.bodyPose
        body.translation.y += abs(swing) * 0.004
        body.rotation = simd_quatf(angle: swing * 0.025, axis: [0, 0, 1]) * body.rotation
        walker.body.transform = body
        for limb in walker.parts {
            let left = limb.part == .leftArm || limb.part == .leftLeg
            let arm = limb.part == .leftArm || limb.part == .rightArm
            let angle = swing * (left ? 1 : -1) * (arm ? -0.18 : 0.24)
            let pivot: SIMD3<Float> = arm ? [left ? 0.013 : -0.013, 0.028, -0.02] : [0, 0.025, 0]
            let offset = pivot * limb.pose.scale
            let rotation = simd_quatf(angle: angle, axis: [1, 0, 0])
            var result = limb.pose
            result.translation += offset - rotation.act(offset)
            result.rotation = rotation * result.rotation
            limb.entity.transform = result
        }
    }
}
