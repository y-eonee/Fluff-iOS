import Foundation
import Observation

/// Readiness belongs to a renderer instance, not SwiftUI's navigation callbacks.
/// A departing screen may disappear after its replacement has already rendered.
@Observable
final class RoomSceneReadiness {
    private var sceneID: UUID?
    private(set) var isReady = false

    @discardableResult
    func begin(_ id: UUID) -> Bool {
        guard sceneID != id else { return false }
        sceneID = id
        isReady = false
        return true
    }

    func presented(_ id: UUID) {
        guard sceneID == id else { return }
        isReady = true
    }

    @discardableResult
    func remove(_ id: UUID) -> Bool {
        guard sceneID == id else { return false }
        sceneID = nil
        isReady = false
        return true
    }
}
