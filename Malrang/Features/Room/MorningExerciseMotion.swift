import Foundation
import RealityKit

/// Applies one motion to the existing named parts, preserving custom meshes and proportions.
@MainActor
enum MorningExerciseMotion {
    enum Clip: CaseIterable {
        case exercise, danceDance, wiggle, tapDance
        var sourceDuration: TimeInterval {
            switch self {
            case .exercise: MorningExerciseSequence.duration
            case .danceDance: DanceDanceSequence.duration
            case .wiggle: WiggleSequence.duration
            case .tapDance: TapDanceSequence.duration
            }
        }
        var sourceStart: TimeInterval {
            switch self { case .exercise: 34; case .wiggle: 13; default: 0 }
        }
        var duration: TimeInterval {
            sourceDuration + (self == .tapDance ? TapDanceSequence.resetDuration : MorningExerciseSequence.resetDuration)
        }
        var name: String {
            switch self {
            case .exercise: "morning-exercise"
            case .danceDance: "dance-dance"
            case .wiggle: "wiggle"
            case .tapDance: "tap-dance"
            }
        }
        func pose(at time: TimeInterval) -> MorningExerciseSequence.Pose {
            switch self {
            case .exercise: MorningExerciseSequence.pose(at: time)
            case .danceDance: DanceDanceSequence.pose(at: time)
            case .wiggle: WiggleSequence.pose(at: time)
            case .tapDance: TapDanceSequence.pose(at: time)
            }
        }
    }
    private struct RestPose: Component { var transform: Transform }

    struct Track {
        let entity: Entity
        let frames: [Transform]
    }

    static func play(on doll: Entity, reducedMotion: Bool, clip: Clip = .exercise) {
        stop(on: doll)
        guard !reducedMotion else { return }
        let tracks = tracks(on: doll, clip: clip)
        #if DEBUG
        if let value = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--\(clip.name)-time=") }),
           let time = Double(value.split(separator: "=").last ?? ""), time.isFinite {
            let index = Int(max(0, time).truncatingRemainder(dividingBy: clip.duration) * Double(MorningExerciseSequence.frameRate))
            for track in tracks {
                track.entity.components.set(RestPose(transform: track.entity.transform))
                track.entity.transform = track.frames[min(index, track.frames.count - 1)]
            }
            return
        }
        #endif
        // Prepare every resource first so failure cannot leave just one limb animating.
        do {
            let clips = try tracks.map { track in
                let definition = SampledAnimation(frames: track.frames, name: "\(clip.name).\(track.entity.name)",
                    frameInterval: 1 / MorningExerciseSequence.frameRate, bindTarget: .transform,
                    trimDuration: clip.duration)
                return (track, try AnimationResource.generate(with: definition))
            }
            for (track, clip) in clips {
                track.entity.components.set(RestPose(transform: track.entity.transform))
                track.entity.playAnimation(clip.repeat())
            }
        } catch {
            assertionFailure("Could not prepare \(clip.name): \(error)")
        }
    }

    static func stop(on doll: Entity) {
        if let rest = doll.components[RestPose.self] {
            doll.stopAllAnimations()
            doll.transform = rest.transform
            doll.components.remove(RestPose.self)
        }
        for child in doll.children { stop(on: child) }
    }

    /// Kept deterministic for clip/rig validation, and sampled only when a dance starts.
    static func tracks(on doll: Entity, clip: Clip = .exercise) -> [Track] {
        let body = doll.findEntity(named: "body") ?? doll
        let bounds = body.visualBounds(relativeTo: body)
        let height = max(bounds.extents.y, 0.1)
        let floor = bounds.min.y
        let samples = (0...Int(clip.duration * Double(MorningExerciseSequence.frameRate)))
            .map { clip.pose(at: Double($0) / Double(MorningExerciseSequence.frameRate)) }
        let hasRig = body.findEntity(named: "leftArm") != nil
        let base = body.transform
        var result = [Track(entity: body, frames: samples.map { pose in
            var angles = pose.body
            if !hasRig { angles.x += pose.bend }
            var transform = rotated(base, angles: angles, pivot: [0, floor, 0])
            transform.translation += base.rotation.act(SIMD3(pose.travel, pose.lift, 0) * height * base.scale)
            return transform
        })]
        let hipInBody = SIMD3<Float>(0, floor + height * 0.18, 0)
        let torso = body.findEntity(named: "torso")
        let torsoRest = torso?.transform
        let torsoTop = torso.map { $0.visualBounds(relativeTo: $0).max.y } ?? 0

        func upperTransform(_ rest: Transform, parent: Entity, pose: MorningExerciseSequence.Pose) -> Transform {
            let hip = parent.convert(position: hipInBody, from: body)
            let axis = simd_normalize(parent.convert(direction: [1, 0, 0], from: body))
            let rotation = simd_quatf(angle: pose.bend, axis: axis)
            var frame = rest
            frame.translation = hip + rotation.act(frame.translation - hip)
            frame.rotation = rotation * frame.rotation
            return frame
        }
        func torsoFrame(_ pose: MorningExerciseSequence.Pose) -> Transform? {
            guard let torso, let rest = torsoRest, let parent = torso.parent else { return nil }
            let sway = rotated(rest, angles: [0, 0, pose.hipSway], pivot: [0, torsoTop, 0])
            return upperTransform(sway, parent: parent, pose: pose)
        }

        for name in ["head", "ears", "torso", "leftArm", "rightArm", "leftLeg", "rightLeg"] {
            guard let part = body.findEntity(named: name), let parent = part.parent else { continue }
            let rest = part.transform
            let arm = name.hasSuffix("Arm"), leg = name.hasSuffix("Leg"), left = name.hasPrefix("left")
            // These are the sewn shoulder and top of the stuffed foot, not their mesh centres.
            let pivot: SIMD3<Float> = arm ? [left ? 0.013 : -0.013, 0.028, -0.020] : [0, 0.025, 0]
            let attachment = (arm || leg) ? torso.map { attachedPoint(part: part, pivot: pivot, torso: $0) } : nil
            let headBounds = body.findEntity(named: "head")?.visualBounds(relativeTo: parent)
            result.append(Track(entity: part, frames: samples.map { pose in
                if name == "torso", let frame = torsoFrame(pose) { return frame }
                guard (arm || leg), let torso, let torsoParent = torso.parent,
                      let torsoRest, let attachment, let frame = torsoFrame(pose) else {
                    return upperTransform(rest, parent: parent, pose: pose)
                }
                let oldAnchor = parent.convert(position: point(attachment, through: torsoRest), from: torsoParent)
                let anchor = parent.convert(position: point(attachment, through: frame), from: torsoParent)
                var rotation = rest.rotation
                if arm {
                    rotation = rotated(rest, angles: left ? pose.leftArm : pose.rightArm, pivot: pivot).rotation
                    let contact = left ? pose.leftCheek : pose.rightCheek
                    if contact > 0, let headBounds {
                        let target = headBounds.center + SIMD3<Float>(
                            (left ? -1 : 1) * headBounds.extents.x * 0.12,
                            -headBounds.extents.y * 0.28, headBounds.extents.z * 0.5 + 0.004)
                        let pawVector = rest.rotation.act((SIMD3<Float>(0, 0.005, 0.012) - pivot) * rest.scale)
                        // A reach turns at the shoulder. An unreachable mouth target must never
                        // translate the entire arm away from the body or stretch the edited mesh.
                        let aim = limitedAim(from: pawVector, to: target - oldAnchor, limit: 1.75)
                        rotation = simd_slerp(rotation, aim * rest.rotation, contact)
                    }
                    // Shoulders follow both the bow and the pelvis sway, just like sewn joints.
                    let delta = frame.rotation * torsoRest.rotation.inverse
                    if delta.angle > 0.00001 {
                        let axis = simd_normalize(parent.convert(direction: delta.axis, from: torsoParent))
                        rotation = simd_quatf(angle: delta.angle, axis: axis) * rotation
                    }
                } else {
                    let step = left ? pose.leftStep : pose.rightStep
                    let reach = pose.stance + (left ? pose.leftReach : pose.rightReach)
                    let footVector = rest.rotation.act(-pivot * rest.scale)
                    let requested = parent.convert(direction: SIMD3<Float>(
                        (left ? -1 : 1) * reach, step, step * 0.65) * height, from: body)
                    rotation = limitedAim(from: footVector, to: footVector + requested, limit: 1.22) * rest.rotation
                }
                // Recompute translation from the SAME attachment after every rotation. This
                // remains fixed in torso space even through bends, cheek holds and wide taps.
                var transform = rest
                transform.rotation = rotation
                transform.translation = anchor - rotation.act(pivot * rest.scale)
                return transform
            }))
        }
        return result
    }

    /// Keep edited limbs embedded in the actual stuffed body, excluding apron/neck bounds.
    private static func attachedPoint(part: Entity, pivot: SIMD3<Float>, torso: Entity) -> SIMD3<Float> {
        let surface = torso.findEntity(named: "body.fur") ?? torso
        let bounds = surface.visualBounds(relativeTo: torso)
        let radii = simd_max(bounds.extents * 0.5, SIMD3<Float>(repeating: 0.001))
        let offset = torso.convert(position: pivot, from: part) - bounds.center
        let distance = simd_length(offset / radii)
        return bounds.center + offset * min(1, 0.90 / max(distance, 0.0001))
    }

    private static func point(_ point: SIMD3<Float>, through transform: Transform) -> SIMD3<Float> {
        transform.translation + transform.rotation.act(point * transform.scale)
    }

    private static func limitedAim(from: SIMD3<Float>, to: SIMD3<Float>, limit: Float) -> simd_quatf {
        guard simd_length_squared(from) > 0.00000001, simd_length_squared(to) > 0.00000001 else {
            return simd_quatf(angle: 0, axis: [1, 0, 0])
        }
        let aim = simd_quatf(from: simd_normalize(from), to: simd_normalize(to))
        return simd_slerp(simd_quatf(angle: 0, axis: [1, 0, 0]), aim, min(1, limit / max(aim.angle, 0.0001)))
    }

    private static func rotated(_ rest: Transform, angles: SIMD3<Float>, pivot: SIMD3<Float>) -> Transform {
        let rotation = simd_quatf(angle: angles.y, axis: [0, 1, 0])
            * simd_quatf(angle: angles.x, axis: [1, 0, 0])
            * simd_quatf(angle: angles.z, axis: [0, 0, 1])
        let offset = rest.rotation.act(pivot * rest.scale)
        var result = rest
        result.rotation = rotation * rest.rotation
        result.translation += offset - rotation.act(offset)
        return result
    }
}
