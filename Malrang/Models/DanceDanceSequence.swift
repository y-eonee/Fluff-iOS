import Foundation

/// Front-left pink character in Xb8O89LQ15U, 00:00–00:05.
/// Holds, hand change and late turn are keyed independently of the exercise clip.
nonisolated enum DanceDanceSequence {
    static let duration: TimeInterval = 5
    typealias Pose = MorningExerciseSequence.Pose
    typealias Keyframe = MorningExerciseSequence.Keyframe
    private static func p(roll: Float = 0, yaw: Float = 0, ls: Float = 0, rs: Float = 0,
                          lift: Float = 0, lc: Float = 0, rc: Float = 0) -> Pose {
        MorningExerciseSequence.p(roll: roll, yaw: yaw, la: [0,0,-12], ra: [0,0,12],
                                  ls: ls, rs: rs, lift: lift, lc: lc, rc: rc)
    }
    static let keyframes: [Keyframe] = [
        .init(0.00,p()), .init(0.18,p(lift: 0.018)), .init(0.40,p()),
        .init(0.62,p(lift: 0.018)), .init(0.84,p()), .init(1.05,p(lift: 0.012)),
        // The same hand stays at the mouth through the first phrase.
        .init(1.23,p(lc: 1)), .init(1.42,p(roll: 3, rs: 0.025, lift: 0.012, lc: 1)),
        .init(1.63,p(roll: 2, lc: 1)), .init(1.83,p(roll: -4, ls: 0.035, lift: 0.012, lc: 1)),
        .init(2.03,p(roll: -4, ls: 0.035, lc: 1)), .init(2.23,p(roll: -3, ls: 0.02, lc: 1)),
        .init(2.43,p(roll: -2, lc: 1)), .init(2.66,p(lc: 0.85)),
        // 2.7–2.9: a single hand exchange, not continual alternating arm swings.
        .init(2.78,p(lc: 0.2, rc: 0.4)), .init(2.90,p(rc: 1)),
        .init(3.14,p(roll: 4, rs: 0.035, lift: 0.012, rc: 1)),
        .init(3.38,p(roll: 4, rs: 0.035, rc: 1)),
        .init(3.62,p(roll: 3, rs: 0.025, rc: 1)),
        .init(3.94,p(roll: 2, rc: 1)), .init(4.02,p(roll: -3, rc: 0.5)),
        // Actual excerpt ends facing left. Do not invent a completed 360° spin at 5s.
        .init(4.10,p(yaw: 45, ls: 0.025, lift: 0.015)),
        .init(4.18,p(yaw: 90, ls: 0.025)), .init(4.25,p(yaw: 90)),
        .init(4.33,p(yaw: 180, rs: 0.02, lift: 0.018)),
        .init(4.41,p(yaw: 270, rs: 0.025)), .init(4.49,p(yaw: 270)),
        .init(4.65,p(yaw: 180, ls: 0.025, lift: 0.018)),
        .init(4.81,p(yaw: 180)), .init(4.97,p(yaw: 270, rs: 0.025)),
        .init(5.00,p(yaw: 270, rs: 0.025))
    ]
    static func sourcePose(at time: TimeInterval) -> Pose { MorningExerciseSequence.sample(keyframes, at: time) }
    static func pose(at elapsed: TimeInterval) -> Pose {
        MorningExerciseSequence.loop(keyframes, duration: duration, elapsed: elapsed)
    }
}
