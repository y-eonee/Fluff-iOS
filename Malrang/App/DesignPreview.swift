#if DEBUG
import SwiftUI
import SwiftData

/// Isolated visual fixtures: never modifies the user's saved dolls, room, or focus history.
@Observable
final class DesignPreviewData {
    let route: String
    let container: ModelContainer
    let session: FocusSession
    let draft: DollDraft
    init(route: String) {
        self.route = route
        container = try! ModelContainer(for: Doll.self, RoomItem.self, DecorPhoto.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let domain = "fluff.design-preview.\(UUID())"
        let defaults = UserDefaults(suiteName: domain)!
        session = FocusSession(defaults: defaults)
        draft = DollDraft()
        draft.shape = route.hasSuffix("rabbit") ? .rabbit : route.hasSuffix("bear") ? .bear : .cat
        draft.preset.shape = draft.shape
        if route.hasPrefix("photo-") {
            draft.usesPresetPhoto = true
            let renderer = ImageRenderer(content: VStack(spacing: 8) {
                Text("TOP").font(.title.bold())
                Image(systemName: "face.smiling.fill").resizable().scaledToFit().foregroundStyle(.orange)
                Text("PHOTO").font(.title.bold())
            }.padding(24).frame(width: 240, height: 300).background(.mint.opacity(0.3)))
            draft.photo = renderer.uiImage
            if route == "photo-finish" {
                draft.preset.face = draft.presetPhotoData
                draft.preset.faceScale = 1.4
                draft.preset.faceOpeningScale = 0.9
            }
        }
        for (shape, name) in [(DollShape.cat, "귀염둥이"), (.bear, "몽글이"), (.rabbit, "포근이")] {
            let renderer = ImageRenderer(content: CottonArtwork(shape: shape).frame(width: 240, height: 253))
            let doll = Doll(name: name, shape: shape, filling: .fluffy, imageData: renderer.uiImage?.pngData() ?? Data())
            doll.presetConfiguration = PresetConfiguration(shape: shape)
            container.mainContext.insert(doll)
            if shape == .cat { session.select(doll.id) }
        }
        RoomItem.starterRoom.forEach(container.mainContext.insert)
        try? container.mainContext.save()
        if ["running", "rest", "reward"].contains(route) {
            session.start(at: .now.addingTimeInterval(route == "running" ? -1122 : -1501))
            session.tick()
        }
    }
}

struct DesignPreview: View {
    @State private var fixture: DesignPreviewData
    init(route: String) { _fixture = State(initialValue: DesignPreviewData(route: route)) }
    private var route: String { fixture.route }
    private var draft: DollDraft { fixture.draft }
    var body: some View {
        Group {
            if route == "tabs-ui" { MainTabs() }
            else if route == "model-compare" { PresetComparisonView() }
            else if route == "model-side" { PresetComparisonView(cameraYaw: .pi / 4) }
            else if ["create-method", "photo-method"].contains(route) {
                NavigationStack { CreateMethodStep(draft: draft, onPreset: {}, onCutout: {}).safeAreaInset(edge: .top) { CreationProgress(step: 2) } }
            }
            else if route == "photo-finish" { CreateFlowView(previewDraft: draft, startAtMaking: true) { _ in } }
            else if route == "photo-flow" { CreateFlowView(previewDraft: draft) { _ in } }
            else if route == "create-entry" { CreateFlowView { _ in } }
            else if ["create", "rabbit", "bear", "photo-cat", "photo-rabbit", "photo-bear"].contains(route) {
                NavigationStack { DollCustomizeStepA(draft: draft) {} }
            } else if route == "home-ui" { NavigationStack { HomeView() } }
            else if route == "decorate" { NavigationStack { DecorateView() } }
            else if route == "decorate-selected" {
                NavigationStack { DecorateView(selectedID: (try? fixture.container.mainContext.fetch(FetchDescriptor<RoomItem>()))?.first { $0.kind == .desk }?.id) }
            }
            else { FocusFlowView(session: fixture.session, showMain: route == "main", showReward: route == "reward") }
        }.modelContainer(fixture.container).environment(AppState()).environment(MultiRoom()).environment(FriendStore(api: MockFriendAPI()))
    }
}

private struct PresetComparisonView: View {
    var cameraYaw: Float = 0
    var body: some View {
        VStack(spacing: 8) {
            HStack { Text("피그마 원본"); Spacer(); Text("3D 렌더링") }.font(.headline).padding(.horizontal, 32)
            ForEach(DollShape.presets, id: \.self) { shape in
                VStack(spacing: 0) {
                    Text(shape.label).font(.caption)
                    HStack(spacing: 0) {
                        CottonArtwork(shape: shape).frame(width: 180, height: 190)
                        PresetDollView(configuration: .init(shape: shape), cameraDistance: shape == .cat ? 0.89 : 0.97, cameraTarget: 0.185, cameraYaw: cameraYaw)
                            .frame(width: 180, height: 220)
                    }
                }
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(FocusStyle.paper)
    }
}
#endif
