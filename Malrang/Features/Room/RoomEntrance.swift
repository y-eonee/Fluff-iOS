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
    private(set) var loadingDoll: DollState?
    private var selectedLoadingDoll = false
    private(set) var presentsSceneDoll = false
    func useSceneDoll(_ available: Bool) { presentsSceneDoll = available }
    #if DEBUG
    var previewTime: Double?
    #endif

    init(_ kind: Kind) { self.kind = kind }
    var timeline: RoomLoadingTimeline { kind == .home ? (loadingDoll == nil ? .cotton : .ownedDoll) : .editor }
    func chooseLoadingDoll(from dolls: [Doll]) {
        guard !selectedLoadingDoll else { return }
        selectedLoadingDoll = true
        loadingDoll = nil
    }
    func beginArrival(of doll: DollState) {
        loadingDoll = nil
        selectedLoadingDoll = true
        finished = false; start = nil; sceneReady = false; presentsSceneDoll = false
    }
    var time: Double {
        #if DEBUG
        if let previewTime, sceneReady { return previewTime }
        #endif
        guard let start else { return 0 }
        return min(timeline.duration, max(0, ProcessInfo.processInfo.systemUptime - start))
    }

    var dollArrivalProgress: Float {
        guard time >= 1.95 else { return 0 }
        guard time < 2.95 else { return 1 }
        let x = timeline.value("1904:6939", "--motion-translate-x", at: time, fallback: 80.131523)
        return Float(min(1, max(0, 1 - x / 81.13221)))
    }

    func sceneWasRemoved() {
        sceneReady = false
        presentsSceneDoll = false
        if !finished { start = nil }
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
    var spatialScale: Double = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @ViewBuilder func body(content: Content) -> some View {
        if entrance.finished || node.isEmpty {
            // Remove the animation wrapper at handoff so paused timeline content
            // cannot retain its disabled hit-testing state over the live controls.
            content
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: scenePhase != .active)) { _ in
                let time = entrance.time
                let timeline = entrance.timeline
                content
                    .scaleEffect(x: reduceMotion ? 1 : timeline.value(node, "--motion-scale-x", at: time, fallback: 1),
                                 y: reduceMotion ? 1 : timeline.value(node, "--motion-scale-y", at: time, fallback: 1))
                    .offset(x: reduceMotion ? 0 : timeline.value(node, "--motion-translate-x", at: time) * spatialScale,
                            y: reduceMotion ? 0 : timeline.value(node, "--motion-translate-y", at: time) * spatialScale)
                    .opacity(timeline.value(node, "opacity", at: time, fallback: 1))
            }.allowsHitTesting(false).accessibilityHidden(true)
        }
    }
}

/// Sits BEHIND the real renderer, so the arriving doll is the user's actual entity.
struct RoomLoadingBackdrop: View {
    let entrance: RoomEntrance
    var body: some View {
        Color(uiColor: Palette.uiColor("#FFFFF4"))
            .overlay {
                RepresentativeGradientFill(definition: RoomLoadingView.veil)
                    .modifier(RoomEntranceMotion(entrance: entrance, node: entrance.loadingDoll == nil ? "1932:6465" : "1904:6845"))
            }
            .ignoresSafeArea()
    }
}
