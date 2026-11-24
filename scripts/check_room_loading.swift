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
        let editorData = try Data(contentsOf: URL(fileURLWithPath: "Malrang/Resources/RoomEditorMotion.json"))
        let editor = try JSONDecoder().decode(RoomLoadingTimeline.self, from: editorData)
        close(editor.duration, 2, "editor duration")
        close(editor.value("8444", "opacity", at: 0.35), 1, "live room arrives")
        close(editor.value("8452", "opacity", at: 0.34), 0, "chair waits for room")
        close(editor.value("8452", "--motion-translate-y", at: 0.65), 0, "chair lands")
        close(editor.value("8510", "opacity", at: 0.69), 0, "doll waits for chair")
        close(editor.value("8510", "--motion-scale-y", at: 1), 0.94, "doll landing squash")
        close(editor.value("8510", "--motion-scale-y", at: 1.3), 1, "doll restores its size")
        close(editor.value("8467", "opacity", at: 1.19), 0, "hint follows landing")
        close(editor.value("8467", "opacity", at: 1.45), 1, "hint arrives")
        close(editor.value("8457", "opacity", at: 1.1), 0.65, "history linear fade")
        for (index, node) in ["8480", "8482", "8484", "8486", "8488"].enumerated() {
            let delay = 0.25 + Double(index) * 0.04
            close(editor.value(node, "opacity", at: delay), 0, "card waits")
            close(editor.value(node, "opacity", at: delay + 0.2), 1, "card arrives")
        }
        let cottonData = try Data(contentsOf: URL(fileURLWithPath: "Malrang/Resources/CottonLoadingMotion.json"))
        let cotton = try JSONDecoder().decode(RoomLoadingTimeline.self, from: cottonData)
        close(cotton.duration, 8.4, "cotton duration")
        close(cotton.value("1932:6465", "opacity", at: 7.8), 1, "cotton veil holds")
        close(cotton.value("1932:6465", "opacity", at: 8.3), 0, "cotton veil clears")
        close(RoomLoadingTimeline.Curve("step-end").value(at: 0.9), 0, "hold before boundary")
        close(RoomLoadingTimeline.Curve("step-end").value(at: 1), 1, "snap at boundary")
        print("PASS: home keyframes, spring samples, editor order, card stagger and landing restoration")
    }
}
