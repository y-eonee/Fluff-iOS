import Foundation

/// Exported from Figma 1825:6433. One clock drives every layer, including the
/// sampled CSS springs, so header, bear and navigation never drift apart.
struct RoomLoadingTimeline: Decodable {
    let duration: Double
    let nodes: [String: [String: [Key]]]

    static let shared: Self = {
        guard let url = Bundle.main.url(forResource: "RoomLoadingMotion", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let timeline = try? JSONDecoder().decode(Self.self, from: data) else {
            assertionFailure("Missing bundled RoomLoadingMotion.json")
            return Self(duration: 3.4, nodes: [:])
        }
        return timeline
    }()

    struct Key: Decodable {
        let time: Double
        let value: Double
        let curve: Curve
        private enum CodingKeys: String, CodingKey { case time, value, easing }
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            time = try values.decode(Double.self, forKey: .time)
            value = try values.decode(Double.self, forKey: .value)
            curve = Curve(try values.decode(String.self, forKey: .easing))
        }
    }

    enum Curve {
        case linear, bezier(Double, Double, Double, Double), samples([Double])
        init(_ css: String) {
            switch css {
            case "ease-in": self = .bezier(0.42, 0, 1, 1)
            case "ease-out": self = .bezier(0, 0, 0.58, 1)
            case "ease-in-out": self = .bezier(0.42, 0, 0.58, 1)
            default:
                if css.hasPrefix("linear(") {
                    self = .samples(css.dropFirst(7).dropLast().split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) })
                } else { self = .linear }
            }
        }

        func value(at fraction: Double) -> Double {
            let x = min(1, max(0, fraction))
            switch self {
            case .linear: return x
            case let .samples(values):
                guard values.count > 1 else { return x }
                let index = x * Double(values.count - 1)
                let lower = min(Int(index), values.count - 2)
                return values[lower] + (values[lower + 1] - values[lower]) * (index - Double(lower))
            case let .bezier(x1, y1, x2, y2):
                // CSS solves x(t) before evaluating y(t); using y(x) changes timing.
                func coordinate(_ t: Double, _ a: Double, _ b: Double) -> Double {
                    3 * (1 - t) * (1 - t) * t * a + 3 * (1 - t) * t * t * b + t * t * t
                }
                var low = 0.0, high = 1.0
                for _ in 0..<20 {
                    let mid = (low + high) / 2
                    if coordinate(mid, x1, x2) < x { low = mid } else { high = mid }
                }
                return coordinate((low + high) / 2, y1, y2)
            }
        }
    }

    func value(_ node: String, _ property: String, at time: Double, fallback: Double = 0) -> Double {
        guard let keys = nodes[node]?[property], let first = keys.first, let last = keys.last else { return fallback }
        if time <= first.time { return first.value }
        for index in 1..<keys.count where time < keys[index].time {
            let a = keys[index - 1], b = keys[index]
            return a.value + (b.value - a.value) * a.curve.value(at: (time - a.time) / (b.time - a.time))
        }
        return last.value
    }
}

/// Hold before the completion message until RealityKit reports an actual frame.
/// The exported loop is a Figma preview; the app plays a single arrival per session.
struct RoomLoadingClock {
    var start: TimeInterval
    private(set) var ready: TimeInterval?
    static let readinessGate = 1.55

    mutating func markReady(at now: TimeInterval) {
        if ready == nil { ready = now }
    }

    func time(at now: TimeInterval) -> Double {
        let elapsed = max(0, now - start)
        guard let ready else { return min(elapsed, Self.readinessGate) }
        let wait = max(0, ready - start - Self.readinessGate)
        return min(3.4, max(0, elapsed - wait))
    }
}
