import SwiftUI

/// Figma Loading_01_Room / 개선안 (Motion), node 1825:6433.
/// The art is a loading illustration; the user's live, editable room stays mounted
/// underneath and takes over only after its first frame is ready.
struct RoomLoadingView: View {
    let isReady: Bool
    var previewTime: Double? = nil
    var repeats = false
    var onComplete: () -> Void = {}
    @Environment(\.scenePhase) private var scenePhase
    @State private var clock = RoomLoadingClock(start: ProcessInfo.processInfo.systemUptime)
    @State private var completed = false
    private let ink = Color(uiColor: Palette.uiColor("#614A40"))

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: completed || previewTime != nil || scenePhase != .active)) { _ in
            let time = previewTime ?? (repeats
                ? (ProcessInfo.processInfo.systemUptime - clock.start).truncatingRemainder(dividingBy: 3.4)
                : clock.time(at: ProcessInfo.processInfo.systemUptime))
            GeometryReader { geometry in
                let scale = max(geometry.size.width / 390, geometry.size.height / 844)
                artwork(at: time)
                    .frame(width: 390, height: 844)
                    .scaleEffect(scale)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .background { RepresentativeGradientFill(definition: RepresentativeGradients.selected) }
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(time < 0.85 ? "솜뭉치를 깨우고 있어요" : time < 1.65 ? "이불을 폭신하게 펴는 중" : "포근한 방 완성")
            .accessibilityIdentifier("room-loading")
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .task(id: isReady) {
            guard isReady, !completed, !repeats, previewTime == nil else { return }
            clock.markReady(at: ProcessInfo.processInfo.systemUptime)
            let remaining = max(0, 3.4 - clock.time(at: ProcessInfo.processInfo.systemUptime))
            do { try await Task.sleep(for: .seconds(remaining)) } catch { return }
            completed = true
            onComplete()
        }
    }

    private func artwork(at time: Double) -> some View {
        ZStack(alignment: .topLeading) {
            Color(uiColor: Palette.uiColor("#FBF7EF"))
            Image("room_loading_room").resizable().scaledToFill()
                .frame(width: 477.154, height: 844).clipped()
                .modifier(LoadingLayerMotion(node: "6434", time: time))
                .offset(x: -87.154)
            Image("room_loading_doll").frame(width: 60.1491, height: 81.3779)
                .offset(x: 90.01, y: 309.78)
            RepresentativeGradientFill(definition: RepresentativeGradients.selected)
                .overlay { RoundedRectangle(cornerRadius: 13.23).strokeBorder(Color.rep4.c04, lineWidth: 0.525) }
                .modifier(LoadingLayerMotion(node: "6438", time: time))
            message("솜뭉치를 깨우고 있어요", node: "6439", time: time)
            message("이불을 폭신하게 펴는 중…", node: "6444", time: time)
            message("포근한 방 완성!", node: "6445", time: time)
            Capsule().fill(.white.opacity(0.75)).frame(width: 140, height: 6)
                .overlay(alignment: .leading) {
                    Capsule().fill(Color(uiColor: Palette.uiColor("#007499")))
                        .frame(width: RoomLoadingTimeline.shared.value("6442", "width", at: time), height: 6)
                }
                .modifier(LoadingLayerMotion(node: "6440", time: time))
                .offset(x: 125, y: 520)
            Text("잠시만 기다려 주세요").pretendard(.medium, 12)
                .foregroundStyle(ink.opacity(0.55)).frame(width: 390)
                .modifier(LoadingLayerMotion(node: "6443", time: time))
                .offset(y: 540)
            navigationPreview(at: time)
            Image("room_loading_bear").resizable().scaledToFill()
                .frame(width: 98, height: 135).clipped()
                .modifier(LoadingLayerMotion(node: "6457", time: time))
                .offset(x: 51.49, y: 317)
            Text("my room").notCliche(25.397, relativeTo: .title).tracking(-1.7778)
                .foregroundStyle(Color.black)
                .modifier(LoadingLayerMotion(node: "6458", time: time))
                .offset(x: 69.69, y: 74.51)
            Image("room_loading_logo").frame(width: 21.5396, height: 19.7195)
                .modifier(LoadingLayerMotion(node: "6459", time: time))
                .offset(x: 39.157, y: 77.808)
            // Status bar and home indicator remain iOS-owned, per DESIGN.md.
        }
        .frame(width: 390, height: 844, alignment: .topLeading)
        .clipped()
    }

    private func message(_ text: String, node: String, time: Double) -> some View {
        Text(text).pretendard(.semiBold, 16).foregroundStyle(ink)
            .frame(width: 390)
            .modifier(LoadingLayerMotion(node: node, time: time))
            .offset(y: 478)
    }

    private func navigationPreview(at time: Double) -> some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                Capsule().fill(.white).frame(width: 220.578, height: 63.691)
                previewTab("솜뭉치들", icon: "cloud", small: true).offset(x: 10.92, y: 4)
                previewTab("내 방", icon: "home").offset(x: 75.27, y: 4)
                previewTab("마이", icon: "user").offset(x: 141.69, y: 4)
            }.frame(width: 220.578, height: 63.691)
                .modifier(LoadingLayerMotion(node: "6449", time: time))
                .offset(x: 47.04, y: 732.36)
            Image("room_loading_tools_circle").frame(width: 63.6914, height: 63.6914)
                .modifier(LoadingLayerMotion(node: "6448", time: time))
                .offset(x: 290.41, y: 732.36)
            Image("room_loading_tools").frame(width: 29.1978, height: 21.7768)
                .modifier(LoadingLayerMotion(node: "6454", time: time))
                .offset(x: 307.671, y: 753.354)
        }
    }

    private func previewTab(_ title: String, icon: String, small: Bool = false) -> some View {
        VStack(spacing: 3.481) {
            Image("room_loading_" + icon).renderingMode(.template)
                .frame(width: 20.8832, height: 20.8832)
            Text(title).pretendard(small ? .medium : .regular, small ? 12 : 14, tracking: small ? 0 : -0.7)
        }.frame(width: 70.046, height: 55.688)
            .foregroundStyle(Color.rep4.c08)
    }
}

private struct LoadingLayerMotion: ViewModifier {
    let node: String
    let time: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let motion = RoomLoadingTimeline.shared
        let opacity = motion.value(node, "opacity", at: time, fallback: 1)
        let chromeStart: Double = node == "6449" ? 2.45 : 2.55
        let isNavigation = ["6448", "6449", "6454"].contains(node)
        content
            .scaleEffect(x: reduceMotion ? 1 : motion.value(node, "--motion-scale-x", at: time, fallback: 1),
                         y: reduceMotion ? 1 : motion.value(node, "--motion-scale-y", at: time, fallback: 1))
            .offset(x: reduceMotion ? (node == "6457" ? 94.5 : 0) : motion.value(node, "--motion-translate-x", at: time),
                    y: reduceMotion ? (node == "6457" ? -12 : 0) : motion.value(node, "--motion-translate-y", at: time))
            .blur(radius: reduceMotion ? 0 : motion.value(node, "filter", at: time))
            .opacity(reduceMotion && isNavigation && time < chromeStart ? 0 : opacity)
    }
}
