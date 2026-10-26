import Foundation

nonisolated enum DollPart: String, CaseIterable, Codable, Identifiable {
    case head, torso, leftArm, rightArm, leftLeg, rightLeg, ears
    var id: Self { self }
    var label: String {
        switch self {
        case .head: "머리"
        case .torso: "몸통"
        case .leftArm: "왼팔"
        case .rightArm: "오른팔"
        case .leftLeg: "왼다리"
        case .rightLeg: "오른다리"
        case .ears: "귀"
        }
    }
}

nonisolated struct PresetConfiguration: Codable, Equatable {
    struct Part: Codable, Equatable {
        var width: Float = 1
        var size: Float = 1
        var length: Float = 1
        var offset: Float = 0
        var color: String?
    }
    var shape: DollShape = .cat
    var parts: [String: Part] = [:]
    var face: Data?
    var faceScale: Float = 1
    /// Optional for compatibility with previously saved dolls.
    var faceOpeningScale: Float?
    var openingScale: Float { min(1.1, max(0.8, faceOpeningScale ?? 1)) }
    var faceOffsetX: Float?
    var faceOffsetY: Float?
    var isPhotoSuit: Bool?
    func part(_ part: DollPart) -> Part { parts[part.rawValue] ?? Part() }
}
