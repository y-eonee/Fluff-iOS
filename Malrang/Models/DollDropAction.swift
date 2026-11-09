import Foundation
import CoreGraphics

nonisolated enum DollDropAction: Equatable {
    case cancel, move, store

    static func resolve(ended: Bool, overStorage: Bool, blocked: Bool) -> Self {
        guard ended else { return .cancel }
        if overStorage { return .store }
        return blocked ? .cancel : .move
    }

    static func isOverStorage(_ point: CGPoint, target: CGRect) -> Bool {
        !target.isEmpty && target.insetBy(dx: -12, dy: -12).contains(point)
    }
}
