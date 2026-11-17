import SwiftUI

/// Short, local feedback: never animate the RealityKit scene's layout or data.
enum RoomMotion {
    static func response(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.3, dampingFraction: 0.82)
    }

    static func reveal(reduceMotion: Bool, anchor: UnitPoint = .center) -> AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96, anchor: anchor))
    }
}

struct RoomPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = isEnabled && configuration.isPressed
        configuration.label
            .scaleEffect(pressed && !reduceMotion ? 0.95 : 1)
            .opacity(pressed ? 0.82 : 1)
            .animation(RoomMotion.response(reduceMotion: reduceMotion), value: pressed)
    }
}

/// Runs once per mounted piece of chrome; cancellation leaves no delayed work.
struct RoomReveal: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    var distance: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : distance)
            .task {
                withAnimation(RoomMotion.response(reduceMotion: reduceMotion)) { appeared = true }
            }
    }
}
