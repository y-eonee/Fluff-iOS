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
        let walker = Walker(model)
        for point in route { guard await walker.move(to: point, climbing: abs(model.position.y - point.y) > 0.05) else { return } }
        let inverse = simd_quatf(angle: -bed.yaw, axis: [0, 1, 0])
        let local = simd_act(inverse, model.position - SIMD3(bed.x, 0, bed.z))
        let edge = SIMD3<Float>(max(-bed.kind.size.x / 2 + 0.16, min(bed.kind.size.x / 2 - 0.16, local.x)), bed.kind.seatHeight ?? 0.39,
                                max(-bed.kind.size.z / 2 + 0.16, min(bed.kind.size.z / 2 - 0.16, local.z)))
        let mount = SIMD3(bed.x, 0, bed.z) + simd_act(simd_quatf(angle: bed.yaw, axis: [0, 1, 0]), edge)
        guard await walker.move(to: mount, climbing: true), await walker.move(to: DollRestPose.bedPosition(bed)) else { return }
        walker.reset()
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
    static func wakeAndReturn(_ model: Entity, bed: RoomItemState, destination: SIMD3<Float>, items: [RoomItemState]) async {
        guard let route = DollBedRoute.plan(from: destination, bed: bed, items: items), let edge = route.last else { return }
        let walker = Walker(model)
        model.position = DollRestPose.bedPosition(bed)
        let parts = (["body"] + DollPart.allCases.map(\.rawValue)).compactMap { name -> (Entity, Transform)? in
            guard let node = model.findEntity(named: name) else { return nil }
            return (node, node.transform)
        }
        DollRestPose.sleeping(model, bed: bed, animated: false)
        model.findEntity(named: "sleep.closed-eyes")?.removeFromParent()
        if let head = model.findEntity(named: DollPart.head.rawValue) {
            for eye in head.children where eye.name == "eye" { eye.isEnabled = true }
        }
        let duration: TimeInterval = UIAccessibility.isReduceMotionEnabled ? 0 : 0.7
        for (node, pose) in parts {
            if duration == 0 { node.transform = pose }
            else { node.move(to: pose, relativeTo: node.parent, duration: duration, timingFunction: .easeInOut) }
        }
        do { try await Task.sleep(for: .seconds(duration)) } catch { return }
        guard !Task.isCancelled else { return }
        for (node, pose) in parts { node.stopAllAnimations(); node.transform = pose }
        // Rise on the mattress first, step down beside it, then retrace the checked route.
        let local = simd_act(simd_quatf(angle: -bed.yaw, axis: [0, 1, 0]), edge - SIMD3(bed.x, 0, bed.z))
        let mount = SIMD3(bed.x, 0, bed.z) + simd_act(simd_quatf(angle: bed.yaw, axis: [0, 1, 0]),
            SIMD3<Float>(max(-bed.kind.size.x / 2 + 0.16, min(bed.kind.size.x / 2 - 0.16, local.x)), bed.kind.seatHeight ?? 0.39,
                         max(-bed.kind.size.z / 2 + 0.16, min(bed.kind.size.z / 2 - 0.16, local.z))))
        guard await walker.move(to: mount), await walker.move(to: edge, climbing: true) else { return }
        for point in route.reversed() { guard await walker.move(to: point) else { return } }
        guard await walker.move(to: destination, climbing: destination.y > 0.05) else { return }
        walker.reset()
    }

    private final class Walker {
        let model: Entity
        let body: Entity?
        let bodyPose: Transform?
        let parts: [(DollPart, Entity, Transform)]
        var phase: Float = 0
        init(_ model: Entity) {
        self.model = model
        body = model.findEntity(named: "body")
        bodyPose = body?.transform
        parts = [DollPart.leftArm, .rightArm, .leftLeg, .rightLeg].compactMap { part -> (DollPart, Entity, Transform)? in
            guard let limb = model.findEntity(named: part.rawValue) else { return nil }
            return (part, limb, limb.transform)
        }
        }
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
    }
}
