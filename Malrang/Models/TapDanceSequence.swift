import Foundation

/// White character in 7cImQZLjlaI, source 0–1s.
/// Arms stay open; independent feet lift, close and tap outward in the observed order.
nonisolated enum TapDanceSequence {
    static let duration: TimeInterval = 1
    static let resetDuration: TimeInterval = 0.1
    typealias Pose = MorningExerciseSequence.Pose
    typealias Keyframe = MorningExerciseSequence.Keyframe
    private static func p(roll: Float = 0, ls: Float = 0, rs: Float = 0,
                          leftOut: Float = 0, rightOut: Float = 0) -> Pose {
        var pose = MorningExerciseSequence.p(roll: roll, la: [-8,0,-68], ra: [-8,0,68], ls: ls, rs: rs)
        pose.leftReach = leftOut; pose.rightReach = rightOut
        return pose
    }
    static let keyframes: [Keyframe] = [
        .init(0.00, p()), .init(0.04, p()),
        .init(0.13, p(roll: -2, ls: 0.065, leftOut: -0.018)),
        .init(0.17, p()),
        .init(0.22, p(roll: 2, rs: 0.065, rightOut: -0.018)),
        .init(0.30, p(roll: 2, rs: 0.065, rightOut: -0.018)),
        .init(0.34, p()),
        .init(0.39, p(roll: -2, leftOut: 0.065)),
        .init(0.43, p()),
        .init(0.47, p(roll: 2, rightOut: 0.065)),
        .init(0.56, p(roll: 2, rightOut: 0.065)),
        .init(0.64, p()),
        .init(0.73, p(roll: -2, ls: 0.065, leftOut: -0.018)),
        .init(0.78, p()),
        .init(0.82, p(roll: 2, rs: 0.05)),
        .init(0.91, p(roll: 2, rightOut: 0.065)),
        .init(0.95, p()),
        .init(0.99, p(roll: -2, leftOut: 0.065)),
        .init(1.00, p(roll: -2, leftOut: 0.065))
    ]
    static func sourcePose(at time: TimeInterval) -> Pose { MorningExerciseSequence.sample(keyframes, at: time) }
    static func pose(at elapsed: TimeInterval) -> Pose {
        MorningExerciseSequence.loop(keyframes, duration: duration, elapsed: elapsed, reset: resetDuration)
    }
}
