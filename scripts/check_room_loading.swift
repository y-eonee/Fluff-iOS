import Foundation

@main
struct CheckRoomLoading {
    static func main() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: "Malrang/Resources/RoomLoadingMotion.json"))
        let timeline = try JSONDecoder().decode(RoomLoadingTimeline.self, from: data)
        func close(_ value: Double, _ expected: Double, _ label: String) {
            precondition(abs(value - expected) < 0.002, "\(label): \(value), expected \(expected)")
        }
        precondition(timeline.nodes.count == 14)
        close(timeline.duration, 3.4, "shared duration")
        for (time, width) in [(0.0, 6.0), (0.6, 52.0), (1.2, 98.0), (1.8, 140.0)] {
            close(timeline.value("6442", "width", at: time), width, "thread width")
        }
        close(timeline.value("6457", "--motion-scale-x", at: 0.45), 1.04, "breathing width")
        close(timeline.value("6457", "--motion-scale-y", at: 0.45), 0.94, "breathing height")
        close(timeline.value("6457", "--motion-translate-y", at: 2.25), -70, "jump apex")
        close(timeline.value("6457", "--motion-scale-y", at: 2.63), 0.86, "landing squash")
        close(timeline.value("6438", "opacity", at: 2.45), 0, "veil clears")
        close(timeline.value("6434", "filter", at: 2.5), 0, "room sharpens")
        close(timeline.value("6458", "opacity", at: 2.7), 1, "header arrives")
        precondition(timeline.value("6449", "--motion-translate-y", at: 2.70) < 0, "preserve exported spring overshoot")
        close(timeline.value("6449", "--motion-translate-y", at: 3.4), 0, "navigation settles")
        var slow = RoomLoadingClock(start: 100)
        close(slow.time(at: 100.8), 0.8, "initial playback")
        close(slow.time(at: 120), 1.55, "wait before claiming success")
        precondition(timeline.value("6445", "opacity", at: slow.time(at: 120)) == 0)
        slow.markReady(at: 120)
        close(slow.time(at: 120.5), 2.05, "resume from readiness gate")
        slow.markReady(at: 121)
        close(slow.time(at: 122), 3.4, "duplicate readiness must not restart")
        var fast = RoomLoadingClock(start: 100)
        fast.markReady(at: 100.2)
        close(fast.time(at: 103.4), 3.4, "fast loading retains choreography")
        close(fast.time(at: 120), 3.4, "production does not loop")
        print("PASS: Figma keyframes, spring samples, readiness gate and one-shot completion")
    }
}
