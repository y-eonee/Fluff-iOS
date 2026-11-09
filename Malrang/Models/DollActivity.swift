import Foundation

nonisolated enum DollActivity: String, Codable, CaseIterable {
    case touch, desk, window, sofa, bed
}

/// Counts remain cumulative; only the three state scores are capped.
nonisolated struct DollActivityHistory: Codable, Equatable {
    private var counts: [String: Int] = [:]

    subscript(_ activity: DollActivity) -> Int { max(0, counts[activity.rawValue, default: 0]) }

    mutating func record(_ activity: DollActivity) {
        let current = self[activity]
        counts[activity.rawValue] = current == Int.max ? current : current + 1
    }

    var intelligence: Int { min(100, self[.desk]) }
    var sensitivity: Int { min(100, min(100, self[.window]) + min(100, self[.sofa])) }
    var stamina: Int { min(100, self[.bed]) }
}
