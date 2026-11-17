import SwiftUI

/// One clock for the live scene and its SwiftUI controls. Never changes saved placement.
@Observable
final class RoomEntrance {
    enum Kind { case home, editor }
    let kind: Kind
    private(set) var start: TimeInterval?
    private(set) var finished = false
    private var sceneReady = false
    private var presentationReady = false
    #if DEBUG
    var previewTime: Double?
    #endif

    init(_ kind: Kind) { self.kind = kind }
    var timeline: RoomLoadingTimeline { kind == .home ? .shared : .editor }
    var time: Double {
        #if DEBUG
        if let previewTime, sceneReady { return previewTime }
        #endif
        guard let start else { return 0 }
        return min(timeline.duration, max(0, ProcessInfo.processInfo.systemUptime - start))
    }

    func prepareScene() { sceneReady = true; beginIfReady() }
    func present() { presentationReady = true; beginIfReady() }
    private func beginIfReady() {
        guard sceneReady, presentationReady, start == nil, !finished else { return }
        start = ProcessInfo.processInfo.systemUptime
    }
    func finishIfNeeded() {
        #if DEBUG
        if previewTime != nil { return }
        #endif
        if start != nil, time >= timeline.duration { finished = true }
    }
}

struct RoomEntranceMotion: ViewModifier {
    let entrance: RoomEntrance
    let node: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: entrance.finished || scenePhase != .active)) { _ in
            let time = entrance.finished ? entrance.timeline.duration : entrance.time
            let timeline = entrance.timeline
            content
                .scaleEffect(x: reduceMotion ? 1 : timeline.value(node, "--motion-scale-x", at: time, fallback: 1),
                             y: reduceMotion ? 1 : timeline.value(node, "--motion-scale-y", at: time, fallback: 1))
                .offset(x: reduceMotion ? 0 : timeline.value(node, "--motion-translate-x", at: time),
                        y: reduceMotion ? 0 : timeline.value(node, "--motion-translate-y", at: time))
                .opacity(timeline.value(node, "opacity", at: time, fallback: 1))
                .allowsHitTesting(entrance.finished || node.isEmpty)
                .accessibilityHidden(!entrance.finished && !node.isEmpty)
        }
    }
}

/// Sits BEHIND the real renderer, so the arriving doll is the user's actual entity.
struct RoomLoadingBackdrop: View {
    let entrance: RoomEntrance
    var body: some View {
        Color(uiColor: Palette.uiColor("#FFFFF4"))
            .overlay {
                RepresentativeGradientFill(definition: RepresentativeGradients.selected)
                    .modifier(RoomEntranceMotion(entrance: entrance, node: "6438"))
            }
            .ignoresSafeArea()
    }
}
