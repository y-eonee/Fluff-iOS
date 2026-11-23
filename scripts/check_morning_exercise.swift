import Foundation
import RealityKit

@main
struct CheckReferenceMotions {
    @MainActor static func main() throws {
        // Observable source constraints, independent of the interpolation implementation.
        precondition(MorningExerciseSequence.duration == 14 && DanceDanceSequence.duration == 5)
        for time in [1.3, 1.6, 2.0, 2.4] {
            let pose = DanceDanceSequence.sourcePose(at: time)
            precondition(pose.leftCheek > 0.95 && pose.rightCheek == 0, "First hand must hold, not alternate")
        }
        for time in [2.95, 3.2, 3.6, 3.9] {
            let pose = DanceDanceSequence.sourcePose(at: time)
            precondition(pose.rightCheek > 0.95 && pose.leftCheek == 0)
            precondition(abs(pose.body.y) < 0.01, "Turn must not start before the source's 4.1s cue")
        }
        precondition(DanceDanceSequence.sourcePose(at: 4.2).body.y > 1.5)
        precondition(DanceDanceSequence.sourcePose(at: 5).body.y > 4.6, "Preserve the source's final side pose")
        precondition(DanceDanceSequence.pose(at: 5) == DanceDanceSequence.sourcePose(at: 5), "Reset must not overwrite requested source time")
        precondition(MorningExerciseSequence.sourcePose(at: 5.5).travel > 0.2, "Exercise must step sideways")
        for time in [8.0, 8.5, 9.0, 10.0] {
            let pose = MorningExerciseSequence.sourcePose(at: time)
            precondition(pose.bend > 0.45 && pose.stance > 0.04, "Sustained bow with feet apart")
            precondition(pose.leftStep == 0 && pose.rightStep == 0, "No generic marching during the planted bow")
        }
        precondition(MorningExerciseSequence.sourcePose(at: 12).bend == 0)
        precondition(MorningExerciseSequence.pose(at: 14) == MorningExerciseSequence.sourcePose(at: 14))
        precondition(WiggleSequence.duration == 4 && TapDanceSequence.duration == 1)
        precondition(WiggleSequence.sourcePose(at: 0.4).hipSway == 0, "Preserve the waiting opening")
        precondition(WiggleSequence.sourcePose(at: 1.2).hipSway > 0.3)
        precondition(WiggleSequence.sourcePose(at: 0.9).body.z < 0 && WiggleSequence.sourcePose(at: 1.2).body.z > 0,
                     "Successive source flicks lean in opposite directions")
        precondition(WiggleSequence.sourcePose(at: 1.35).hipSway == 0)
        precondition(WiggleSequence.sourcePose(at: 3.8).body.z > 0.25, "Final lean differs from the repeated small flicks")
        precondition(WiggleSequence.pose(at: 4) == WiggleSequence.sourcePose(at: 4))
        precondition(TapDanceSequence.sourcePose(at: 0.13).leftStep > 0.06)
        precondition(TapDanceSequence.sourcePose(at: 0.25).rightStep > 0.06)
        precondition(TapDanceSequence.sourcePose(at: 0.39).leftReach > 0.06)
        precondition(TapDanceSequence.sourcePose(at: 0.52).rightReach > 0.06)
        for time in stride(from: 0.0, through: 1.0, by: 0.01) {
            let p = TapDanceSequence.sourcePose(at: time)
            precondition(p.leftStep == 0 || p.rightStep == 0, "No two-foot jump in the tap excerpt")
            precondition(p.lift == 0 && p.body.y == 0, "Tap keeps a planted supporting foot and faces forward")
        }
        precondition(TapDanceSequence.pose(at: 1) == TapDanceSequence.sourcePose(at: 1))
        for proportions: Float in [0.65, 1, 1.5] {
            let doll = Entity(); doll.position = [0.4, 0.2, -0.3]
            doll.orientation = simd_quatf(angle: 0.8, axis: [0,1,0])
            let body = Entity(); body.name = "body"; body.position.y = 0.27; doll.addChild(body)
            let visual = Entity(); visual.scale = [1.2,0.85,1.1]; body.addChild(visual)
            for name in ["head","ears","torso","leftArm","rightArm","leftLeg","rightLeg"] {
                let part = ModelEntity(mesh: .generateBox(size: name == "head" ? [0.20,0.18,0.15] : [0.04,0.05,0.04]))
                part.name = name
                let left = name.hasPrefix("left")
                part.position = name == "head" ? [0,0.24,0] : name == "ears" ? [0,0.34,0] : name == "torso" ? [0,0.11,0] : [left ? -0.07 : 0.07,name.hasSuffix("Arm") ? 0.12 : 0.025,0.02]
                part.scale = [proportions,proportions * 1.2,proportions * 0.9]
                visual.addChild(part)
            }
            let rootRest = doll.transform
            let rest = Array(visual.children).map { ($0, $0.transform) } + [(body, body.transform)]
            for clip in MorningExerciseMotion.Clip.allCases {
                let tracks = MorningExerciseMotion.tracks(on: doll, clip: clip)
                precondition(tracks.count == 8)
                precondition(tracks[0].frames.count == Int((clip.duration * 30).rounded()) + 1)
                for track in tracks {
                    precondition(track.frames.allSatisfy { $0.scale == track.entity.scale }, "Never overwrite custom proportions")
                    let frames = track.frames + [track.frames[1]]
                    for (a,b) in zip(frames,frames.dropFirst()) {
                        precondition(a.translation.x.isFinite && a.translation.y.isFinite && a.translation.z.isFinite)
                        precondition(abs(simd_dot(a.rotation.vector,b.rotation.vector)) > 0.70, "No discontinuous quaternion wrap")
                        precondition(simd_distance(a.translation,b.translation) < 0.15, "No teleport at source/reset boundaries")
                    }
                    _ = try AnimationResource.generate(with: SampledAnimation(frames: track.frames,
                        frameInterval: 1 / MorningExerciseSequence.frameRate, bindTarget: .transform, trimDuration: clip.duration))
                }
                MorningExerciseMotion.play(on: doll, reducedMotion: false, clip: clip)
                MorningExerciseMotion.stop(on: doll)
                precondition(doll.transform == rootRest)
                for (entity, transform) in rest { precondition(entity.transform == transform, "Restore REST, not first reference pose") }
                MorningExerciseMotion.play(on: doll, reducedMotion: true, clip: clip)
                for (entity, transform) in rest { precondition(entity.transform == transform) }
            }
            // All four sewn joints must stay embedded at one torso-local point for EVERY
            // sample, including the previously detached cheek reach, bow and wide step.
            for clip in MorningExerciseMotion.Clip.allCases {
                let tracks = MorningExerciseMotion.tracks(on: doll, clip: clip)
                let torso = visual.findEntity(named: "torso")!
                var anchors: [String: SIMD3<Float>] = [:]
                for index in tracks[0].frames.indices {
                    for track in tracks { track.entity.transform = track.frames[index] }
                    for name in ["leftArm", "rightArm", "leftLeg", "rightLeg"] {
                        let limb = visual.findEntity(named: name)!
                        let pivot: SIMD3<Float> = name.hasSuffix("Arm")
                            ? [name.hasPrefix("left") ? 0.013 : -0.013, 0.028, -0.020] : [0, 0.025, 0]
                        let joint = torso.convert(position: pivot, from: limb)
                        if let first = anchors[name] {
                            precondition(simd_distance(first, joint) < 0.00001, "Sewn joint detached: \(clip.name) \(name) \(index)")
                        } else { anchors[name] = joint }
                        let bounds = torso.visualBounds(relativeTo: torso)
                        let radius = bounds.extents * 0.5
                        precondition(simd_length((joint - bounds.center) / radius) < 0.91, "Joint must overlap torso volume")
                    }
                }
                for (entity, transform) in rest { entity.transform = transform }
            }
            MorningExerciseMotion.play(on: doll, reducedMotion: false, clip: .exercise)
            MorningExerciseMotion.play(on: doll, reducedMotion: false, clip: .danceDance)
            MorningExerciseMotion.stop(on: doll)
            for (entity, transform) in rest { precondition(entity.transform == transform) }
        }
        let cutout = Entity(); let body = ModelEntity(mesh: .generateBox(size: [0.3,0.54,0.03]))
        body.name = "body"; cutout.addChild(body)
        precondition(MorningExerciseMotion.tracks(on: cutout).count == 1)
        precondition(MorningExerciseMotion.tracks(on: body, clip: .danceDance).count == 1)
        print("PASS: source timing, sustained cheek holds, late turn, preserved endpoints, side steps, hip bow, 3 edited proportions, attached shoulder/hip joints throughout all four clips, reset continuity, switching/restoration, reduced motion, cutout/AR fallback")
    }
}
