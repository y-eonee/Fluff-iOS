import RealityKit
import UIKit

@MainActor enum DollBedMotion {
    static func walkAndSleep(_ model: Entity, bed: RoomItemState, items: [RoomItemState]) async {
        guard let route = DollBedRoute.plan(from: model.position, bed: bed, items: items) else {
            // A scene rebuild can interrupt a previously validated route. The saved rest state wins.
            DollRestPose.sleeping(model, bed: bed, animated: false)
            model.addChild(DollRestPose.quilt(color: bed.colorName))
            return
        }
        let body = model.findEntity(named: "body")
        let bodyPose = body?.transform
        let parts = [DollPart.leftArm, .rightArm, .leftLeg, .rightLeg].compactMap { part -> (DollPart, Entity, Transform)? in
            guard let limb = model.findEntity(named: part.rawValue) else { return nil }
            return (part, limb, limb.transform)
        }
        var phase: Float = 0
        func reset() {
            if let bodyPose { body?.transform = bodyPose }
            for (_, limb, pose) in parts { limb.transform = pose }
        }
        func move(to destination: SIMD3<Float>, climbing: Bool = false) async -> Bool {
            let start = model.position
            let delta = destination - start
            let distance = simd_length(delta)
            if distance < 0.005 { return true }
            if UIAccessibility.isReduceMotionEnabled || UIApplication.shared.applicationState != .active {
                model.position = destination; return true
            }
            let frames = max(1, Int((climbing ? 0.7 : Double(distance / 0.30)) * 30))
            let direction = SIMD2(delta.x, delta.z)
            let facing = simd_length(direction) > 0.001 ? simd_quatf(angle: atan2(direction.x, direction.y), axis: [0, 1, 0]) : model.orientation
            for frame in 1...frames {
                guard !Task.isCancelled else { return false }
                let t = Float(frame) / Float(frames)
                model.position = simd_mix(start, destination, SIMD3(repeating: t))
                if climbing { model.position.y += sin(t * .pi) * 0.07 }
                model.orientation = simd_slerp(model.orientation, facing, 0.24)
                phase += 0.34
                let swing = sin(phase)
                if var pose = bodyPose { pose.translation.y += abs(swing) * 0.006; body?.transform = pose }
                for (part, limb, pose) in parts {
                    let left = part == .leftArm || part == .leftLeg
                    let arm = part == .leftArm || part == .rightArm
                    let angle = swing * (left ? 1 : -1) * (arm ? -0.22 : 0.30)
                    let pivot: SIMD3<Float> = arm ? [left ? 0.013 : -0.013, 0.028, -0.02] : [0, 0.025, 0]
                    let rotation = simd_quatf(angle: angle, axis: [1, 0, 0])
                    var value = pose
                    value.translation += pivot * pose.scale - rotation.act(pivot * pose.scale)
                    value.rotation = rotation * pose.rotation
                    limb.transform = value
                }
                do { try await Task.sleep(for: .seconds(1.0 / 30)) } catch { return false }
            }
            model.position = destination
            return true
        }
        for point in route { guard await move(to: point, climbing: abs(model.position.y - point.y) > 0.05) else { return } }
        let inverse = simd_quatf(angle: -bed.yaw, axis: [0, 1, 0])
        let local = simd_act(inverse, model.position - SIMD3(bed.x, 0, bed.z))
        let edge = SIMD3<Float>(max(-bed.kind.size.x / 2 + 0.16, min(bed.kind.size.x / 2 - 0.16, local.x)), bed.kind.seatHeight ?? 0.39,
                                max(-bed.kind.size.z / 2 + 0.16, min(bed.kind.size.z / 2 - 0.16, local.z)))
        let mount = SIMD3(bed.x, 0, bed.z) + simd_act(simd_quatf(angle: bed.yaw, axis: [0, 1, 0]), edge)
        guard await move(to: mount, climbing: true), await move(to: DollRestPose.bedPosition(bed)) else { return }
        reset()
        guard !Task.isCancelled else { return }
        DollRestPose.sleeping(model, bed: bed, animated: true)
        do { try await Task.sleep(for: .milliseconds(850)) } catch { return }
        guard !Task.isCancelled else { return }
        // RealityKit animations and live scale updates must not compete for the final transform.
        func stop(_ entity: Entity) { entity.stopAllAnimations(); for child in entity.children { stop(child) } }
        stop(model)
        DollRestPose.sleeping(model, bed: bed, animated: false)
        model.addChild(DollRestPose.quilt(color: bed.colorName))
    }
}
