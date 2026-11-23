import Foundation

/// Yellow rabbit in Xb8O89LQ15U, source 13–17s. Screen-relative directions.
/// The quick hip flicks are followed by a distinct, larger lean at 16.6s.
nonisolated enum WiggleSequence {
    static let duration: TimeInterval = 4
    typealias Pose = MorningExerciseSequence.Pose
    typealias Keyframe = MorningExerciseSequence.Keyframe

    private static func p(_ flick: Float = 0, direction: Float = 1, big: Bool = false) -> Pose {
        var pose = MorningExerciseSequence.p(
            roll: big ? 18 : flick * direction * 7,
            la: [-8, 0, big ? -46 : -18],
            ra: [-8, 0, big ? 28 : 18 + flick * 48],
            lift: big ? -0.025 : 0, travel: big ? -0.04 : 0)
        pose.hipSway = (big ? 28 : flick * direction * 20) * .pi / 180
        pose.rightReach = big ? 0.095 : flick * 0.018
        return pose
    }
    static let keyframes: [Keyframe] = [
        // 13.00–13.48: waiting pose; do not start the flicks immediately.
        .init(0.00, p()), .init(0.48, p()), .init(0.72, p()),
        .init(0.87, p(1, direction: -1)), .init(0.95, p(1, direction: -1)), .init(1.04, p()),
        .init(1.19, p(1)), .init(1.26, p(1)), .init(1.35, p()),
        .init(1.51, p(1, direction: -1)), .init(1.58, p(1, direction: -1)), .init(1.67, p()),
        .init(1.83, p(1)), .init(1.90, p(1)), .init(1.99, p()),
        .init(2.15, p(1, direction: -1)), .init(2.23, p(1, direction: -1)), .init(2.34, p()),
        .init(2.47, p()), .init(2.55, p(1)), .init(2.63, p()),
        .init(2.79, p()), .init(2.94, p(1, direction: -1)), .init(3.02, p()),
        .init(3.18, p(1)), .init(3.25, p(1)), .init(3.34, p()),
        // 16.50 crouch / 16.58 smear / 16.74–17.00 large sideways extension.
        .init(3.50, MorningExerciseSequence.p(la: [-8,0,-34], ra: [-8,0,34], lift: -0.025)),
        .init(3.58, p(0.5)), .init(3.74, p(big: true)), .init(4.00, p(big: true))
    ]
    static func sourcePose(at time: TimeInterval) -> Pose { MorningExerciseSequence.sample(keyframes, at: time) }
    static func pose(at elapsed: TimeInterval) -> Pose {
        MorningExerciseSequence.loop(keyframes, duration: duration, elapsed: elapsed)
    }
}
