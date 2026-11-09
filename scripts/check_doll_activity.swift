import Foundation

@main
struct CheckDollActivity {
    static func main() throws {
        var history = DollActivityHistory()
        precondition(DollActivity.allCases.allSatisfy { history[$0] == 0 })
        history.record(.touch)
        precondition(history.intelligence == 0 && history.sensitivity == 0 && history.stamina == 0)
        for _ in 0..<24 { history.record(.desk) }
        for _ in 0..<18 { history.record(.window) }
        for _ in 0..<12 { history.record(.sofa) }
        for _ in 0..<9 { history.record(.bed) }
        precondition(history.intelligence == 24 && history.sensitivity == 30 && history.stamina == 9)
        let restored = try JSONDecoder().decode(DollActivityHistory.self, from: JSONEncoder().encode(history))
        precondition(restored == history && restored[.touch] == 1)
        for activity in [DollActivity.desk, .window, .sofa, .bed] {
            for _ in 0..<120 { history.record(activity) }
        }
        precondition(history.intelligence == 100 && history.sensitivity == 100 && history.stamina == 100)
        precondition(history[.desk] == 144 && history[.window] == 138 && history[.sofa] == 132 && history[.bed] == 129)
        print("PASS: activity counts, touch independence, shared sensitivity, 100-point cap, and saved history round trip")
    }
}
