import Foundation

nonisolated enum RenderCadence {
    static func framesPerSecond(interacting: Bool, constrained: Bool) -> Int {
        if constrained { return 15 }
        return interacting ? 60 : 30
    }
}
