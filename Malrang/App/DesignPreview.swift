#if DEBUG
import SwiftUI
import SwiftData
import simd

/// Isolated visual fixtures: never modifies the user's saved dolls, room, or focus history.
@Observable
final class DesignPreviewData {
    static let auditFixtures = NSHashTable<DesignPreviewData>.weakObjects()
    let route: String
    let container: ModelContainer
    let defaults: UserDefaults
    let session: FocusSession
    let draft: DollDraft
    let ambient: AmbientPlayer
    let couch: CouchSession
    let appState = AppState()
    init(route: String) {
        self.route = route
        if route == "room-loading" {
            appState.roomEntrance.previewTime = ProcessInfo.processInfo.arguments.first { $0.hasPrefix("--room-loading-time=") }
                .flatMap { Double($0.replacingOccurrences(of: "--room-loading-time=", with: "")) }
        }
        if route == "tabs-dolls" || route == "tabs-profile" { appState.tab = .dolls }
        if ProcessInfo.processInfo.arguments.contains("--home-tools-preview") { appState.roomToolsOpen = true }
        ambient = route.hasPrefix("radio-") && !["radio-setup", "radio-scroll"].contains(route)
            ? AmbientPlayer.designPreview(paused: route == "radio-paused") : AmbientPlayer()
        container = try! ModelContainer(for: Doll.self, RoomItem.self, DecorPhoto.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let domain = route == "signup" ? "fluff.signup-preview" : "fluff.design-preview.\(UUID())"
        defaults = UserDefaults(suiteName: domain)!
        defaults.set(!ProcessInfo.processInfo.arguments.contains("--furniture-preview=guide"), forKey: "didSeeFurnitureGuideV2")
        if !ProcessInfo.processInfo.arguments.contains("--furniture-hint-preview") {
            defaults.set("소파,책상,창문,침대,액자", forKey: "usedFurnitureActions")
        }
        if route == "signup", ProcessInfo.processInfo.arguments.contains("--reset-signup-preview") {
            defaults.removePersistentDomain(forName: domain)
        }
        couch = CouchSession(library: CouchLibrary(defaults: defaults))
        session = FocusSession(defaults: defaults)
        draft = DollDraft()
        if route == "signup" {
            defaults.set(true, forKey: "isSignedIn")
            return
        }
        draft.shape = route.hasSuffix("rabbit") ? .rabbit : route.hasSuffix("cat") ? .cat : .bear
        draft.preset.shape = draft.shape
        if route == "create-custom" { draft.shape = .pillow; draft.photo = UIImage(data: Self.cutoutCharacter()); draft.cutout = draft.photo }
        if route == "create-name" { draft.name = "귀염둥이" }
        if ["cutout-auto", "cutout-move", "create-ready"].contains(route) {
            let renderer = ImageRenderer(content: CottonArtwork(shape: .bear).frame(width: 240, height: 253))
            draft.photo = renderer.uiImage; draft.cutout = renderer.uiImage
        }
        if route.hasPrefix("photo-") && route != "photo-pick" {
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
        let companions: [(DollShape, String)] = ProcessInfo.processInfo.arguments.contains("--empty-reference-room")
            ? [] : [(.cat, "귀염둥이"), (.bear, "몽글이"), (.rabbit, "포근이")]
        let sleepShape = ProcessInfo.processInfo.arguments.first { $0.hasPrefix("--sleep-shape=") }?.split(separator: "=").last
        for (shape, name) in companions {
            if let sleepShape, shape.rawValue != sleepShape { continue }
            let renderer = ImageRenderer(content: CottonArtwork(shape: shape).frame(width: 240, height: 253))
            let doll = Doll(name: name, shape: shape, filling: .fluffy, imageData: renderer.uiImage?.pngData() ?? Data())
            doll.presetConfiguration = PresetConfiguration(shape: shape)
            let focusDoll = ProcessInfo.processInfo.arguments.first { $0.hasPrefix("--focus-doll=") }?.split(separator: "=").last
            if (["cutout-front", "window-cutout"].contains(route) || focusDoll == "cutout"), shape == .cat {
                doll.presetConfiguration = nil
                doll.imageData = Self.cutoutCharacter()
            }
            if ProcessInfo.processInfo.arguments.contains("--memory-audit") || route == "walking" || route == "home-ui" || ["tabs-ui", "room-loading"].contains(route) {
                doll.id = UUID(uuidString: "00000000-0000-0000-0000-00000000000\(shape == .cat ? 1 : shape == .bear ? 2 : 3)")!
                doll.isPlaced = true
                doll.position = [shape == .cat ? 0 : shape == .bear ? -0.35 : 0.35, 0, 0]
                if route == "walking" {
                    doll.position = shape == .cat ? [-0.4, 0, 0.84] : shape == .bear ? [0.15, 0, -0.8] : [-0.41, 0.39, 0.18]
                }
            }
            if route == "doll-history" {
                for _ in 0..<128 { doll.record(.touch) }
                for _ in 0..<24 { doll.record(.desk) }
                for _ in 0..<18 { doll.record(.window) }
                for _ in 0..<12 { doll.record(.sofa) }
                for _ in 0..<9 { doll.record(.bed) }
            }
            container.mainContext.insert(doll)
            if shape.rawValue == (focusDoll == "cutout" ? "cat" : String(focusDoll ?? "cat")) { session.select(doll.id) }
        }
        for (index, item) in RoomItem.starterRoom.enumerated() {
            if ProcessInfo.processInfo.arguments.contains("--memory-audit") {
                item.id = UUID(uuidString: String(format: "00000000-0000-0000-0001-%012d", index))!
            }
            container.mainContext.insert(item)
        }
        if route == "home-ui", ProcessInfo.processInfo.arguments.contains("--bed-occupied"),
           let bed = (try? container.mainContext.fetch(FetchDescriptor<RoomItem>()))?.first(where: { $0.kind == .bed }),
           let dolls = try? container.mainContext.fetch(FetchDescriptor<Doll>()) {
            if let sleeper = dolls.first(where: { $0.presetConfiguration?.shape == .cat }) {
                sleeper.restingBedID = bed.id; sleeper.position = DollRestPose.bedPosition(bed.state)
                if ProcessInfo.processInfo.arguments.contains("--bed-cutout") {
                    sleeper.presetConfiguration = nil; sleeper.imageData = Self.cutoutCharacter()
                }
            }
            if let sitter = dolls.first(where: { $0.presetConfiguration?.shape == .bear }) {
                let offset = simd_quatf(angle: Float(bed.yaw), axis: [0, 1, 0]).act(SIMD3<Float>(0.20, 0, 0.365))
                sitter.position = SIMD3<Float>(Float(bed.x), 0.32, Float(bed.z)) + offset
            }
        }
        if route == "home-ui", ProcessInfo.processInfo.arguments.contains("--chair-seat-preview"),
           let chair = (try? container.mainContext.fetch(FetchDescriptor<RoomItem>()))?.first(where: { $0.kind == .chair }),
           let doll = (try? container.mainContext.fetch(FetchDescriptor<Doll>()))?.first(where: { $0.presetConfiguration?.shape == .cat }) {
            doll.restingBedID = nil
            doll.position = [Float(chair.x), chair.kind.seatHeight ?? 0.227, Float(chair.z)]
        }
        if route == "create-large" {
            for part in DollPart.allCases {
                var value = draft.preset.part(part)
                value.size = 1.3; value.length = 1.4; value.width = 1.4
                draft.preset.parts[part.rawValue] = value
            }
        }
        if route == "floor-photo" {
            let floor = try? container.mainContext.fetch(FetchDescriptor<RoomItem>()).first { $0.kind == .floor }
            floor?.photoData = Self.framePhoto("FLOOR", first: .systemTeal, second: .systemOrange)
        }
        if ["frame-photo", "desk-photo", "wall-photo"].contains(route) {
            let pictures = [Self.framePhoto("PHOTO A", first: .systemTeal, second: .systemOrange), Self.framePhoto("PHOTO B", first: .systemIndigo, second: .systemPink)]
            for data in pictures { container.mainContext.insert(DecorPhoto(data: data)) }
            let frames = try? container.mainContext.fetch(FetchDescriptor<RoomItem>())
            frames?.first(where: { $0.kind == (route == "wall-photo" ? .wall : route == "desk-photo" ? .desk : .frame) })?.photoData = pictures[0]
        }
        // The source editor frames show a separately furnished room state.
        // Reproduce that state in the isolated comparison store; never rewrite a saved room.
        if route.hasPrefix("decorate") || route.hasPrefix("desk-") || route.hasPrefix("wall-photo") {
            let furniture = (try? container.mainContext.fetch(FetchDescriptor<RoomItem>())) ?? []
            for item in furniture where item.kind == .sofa { container.mainContext.delete(item) }
            if let chair = furniture.first(where: { $0.kind == .chair }) {
                chair.x = 0.71; chair.z = 0.13; chair.yaw = 1.3; chair.colorName = "#ECA8BD"
            }
            if let desk = furniture.first(where: { $0.kind == .desk }) { desk.x = 0.45; desk.z = -0.69 }
            if let lamp = furniture.first(where: { $0.kind == .lamp }) { lamp.x = 0.70; lamp.z = -0.82 }
            if let bed = furniture.first(where: { $0.kind == .bed }) { bed.x = -0.50; bed.z = 0.15; bed.yaw = .pi / 2 }
            if let rug = furniture.first(where: { $0.kind == .rugRound }) {
                rug.x = 0.26; rug.z = 0.23; rug.yaw = 0; rug.colorName = nil
            }
            container.mainContext.insert(RoomItem(kind: .plant, x: -0.90, z: 0.60))
        }
        if route.hasPrefix("decorate") || route.hasPrefix("desk-") || route.hasPrefix("wall-photo"),
           let bed = (try? container.mainContext.fetch(FetchDescriptor<RoomItem>()))?.first(where: { $0.kind == .bed }),
           let doll = (try? container.mainContext.fetch(FetchDescriptor<Doll>()))?.first(where: { $0.presetConfiguration?.shape == .bear }) {
            doll.isPlaced = true; doll.position = [Float(bed.x) + 0.33, bed.kind.seatHeight ?? 0.39, Float(bed.z)]
        }
        if route == "decorate-added" || route == "decorate-exit" {
            container.mainContext.insert(RoomItem(kind: .plant, x: 0.05, z: -0.60))
        }
        if route.hasPrefix("couch-") {
            let all = (try? container.mainContext.fetch(FetchDescriptor<Doll>())) ?? []
            let requested = ProcessInfo.processInfo.arguments.first { $0.hasPrefix("--couch-doll=") }?.split(separator: "=").last.map(String.init)
            couch.dolls = Array(all.filter { requested == nil || $0.shapeRaw == requested }.prefix(1)).map(\.state)
            let sample = couch.library.add(YouTubeSource(videoID: "M7lc1UVf-VE", playlistID: nil), title: "YouTube IFrame Player API")
            if ["couch-watch", "couch-mini", "couch-transition"].contains(route) { couch.watch(sample) }

        }
        try? container.mainContext.save()
        if ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("--qa-capture-id=") }) {
            let values = ((try? container.mainContext.fetch(FetchDescriptor<Doll>())) ?? []).map { doll in
                ["name": doll.name, "placed": String(doll.isPlaced), "shape": doll.presetConfiguration?.shape.rawValue ?? "none", "position": String(describing: doll.position)]
            }
            if let data = try? JSONSerialization.data(withJSONObject: values) {
                try? data.write(to: URL.documentsDirectory.appending(path: "design-fixture-dolls.json"), options: .atomic)
            }
        }
        if ProcessInfo.processInfo.arguments.contains("--memory-audit") { Self.auditFixtures.add(self) }
        if ["running", "rest", "paused", "pet", "exit"].contains(route) {
            session.confirmTime()
            let now = Date.now
            session.start(at: now.addingTimeInterval(["running", "paused", "exit"].contains(route) ? -1122 : -1500))
            session.tick(at: now)
            if route == "paused" || route == "rest" { session.togglePause(at: now) }
        }
    }
    /// Asymmetric, hand-drawn character makes inverted geometry and UVs obvious.
    private static func cutoutCharacter() -> Data {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 200, height: 280), format: format).image { context in
            UIColor.systemTeal.setFill()
            UIBezierPath(roundedRect: CGRect(x: 65, y: 20, width: 70, height: 110), cornerRadius: 30).fill()
            UIColor.systemOrange.setFill()
            UIBezierPath(roundedRect: CGRect(x: 22, y: 120, width: 156, height: 135), cornerRadius: 36).fill()
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 78, y: 55, width: 12, height: 12)).fill()
            UIBezierPath(ovalIn: CGRect(x: 110, y: 55, width: 12, height: 12)).fill()
            ("TOP" as NSString).draw(at: CGPoint(x: 73, y: 82), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 22), .foregroundColor: UIColor.white])
            ("FEET" as NSString).draw(at: CGPoint(x: 66, y: 211), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 26), .foregroundColor: UIColor.white])
        }.pngData()!
    }

    private static func framePhoto(_ title: String, first: UIColor, second: UIColor) -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 240, height: 320)).image { context in
            first.setFill(); context.fill(CGRect(x: 0, y: 0, width: 120, height: 320))
            second.setFill(); context.fill(CGRect(x: 120, y: 0, width: 120, height: 320))
            (title as NSString).draw(at: CGPoint(x: 24, y: 130), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 32), .foregroundColor: UIColor.white])
        }.pngData()!
    }

}

struct DesignPreview: View {
    @State private var fixture: DesignPreviewData
    init(route: String) { _fixture = State(initialValue: DesignPreviewData(route: route)) }
    private var route: String { fixture.route }
    private var draft: DollDraft { fixture.draft }
    private func creationShell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content().toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CreationBackButton(label: "뒤로") {}
                }.sharedBackgroundVisibility(.hidden)
            }
        }
    }
    var body: some View {
        Group {
            if route == "signup" { RootView().defaultAppStorage(fixture.defaults) }
            else if route == "korean-title" { NavigationStack { Color.mib.bg.screen.cozyPageTitle("AR로 함께하기") } }
            else if route == "doll-list" { DollListView() }
            else if ["doll-profile", "doll-history"].contains(route), let doll = (try? fixture.container.mainContext.fetch(FetchDescriptor<Doll>()))?.first {
                DollActionSheet(doll: doll, initiallyShowsHistory: route == "doll-history")
            }
            else if route == "photo-pick" { creationShell { PhotoPickStep(draft: draft) {}.safeAreaInset(edge: .top, spacing: 0) { CreationProgress(step: 0) } } }
            else if ["cutout-auto", "cutout-move"].contains(route) { creationShell { CutoutEditStep(draft: draft, onReselect: {}, onNext: {}).safeAreaInset(edge: .top, spacing: 0) { CreationProgress(step: 1) } } }
            else if route == "create-ready" { creationShell { CutoutReadyStep(draft: draft, onEdit: {}, onNext: {}).safeAreaInset(edge: .top, spacing: 0) { CreationProgress(step: 1) } } }
            else if route == "create-done", let doll = (try? fixture.container.mainContext.fetch(FetchDescriptor<Doll>()))?.first(where: { $0.presetConfiguration?.shape == .bear }) {
                NavigationStack { DoneStep(doll: doll, onRestart: {}, onPlace: {}) }
            }
            else if route == "room-loading" { MainTabs(couch: fixture.couch) }
            else if route == "splash-approved" { SplashView() }
            else if route == "profile-create" { NavigationStack { ProfileEditView(isCreating: true) } }
            else if ["tabs-ui", "tabs-dolls", "tabs-profile"].contains(route) { MainTabs(couch: fixture.couch) }
            else if route == "couch-artwork" {
                VStack(spacing: 24) {
                    Text("couch time").notCliche(28, relativeTo: .title)
                    CouchCompanionPreview(dolls: fixture.couch.dolls)
                }.padding(16).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.mib.bg.screen)
            }
            else if route == "couch-transition" { CouchPlaybackAuditView(session: fixture.couch) }
            else if route == "couch-mini" { VStack { Spacer(); CouchMiniPlayer(session: fixture.couch) {}.frame(width: 300); Spacer() }.frame(maxWidth: .infinity).background(Color.mib.bg.screen) }
            else if route == "couch-choice" {
                let dolls = (try? fixture.container.mainContext.fetch(FetchDescriptor<Doll>())) ?? []
                DollChoiceSheet(dolls: dolls, multiple: false, title: "같이 볼 인형", subtitle: "함께 볼 인형 1개를 골라주세요", actionTitle: "다음", maximumSelection: 1) { _ in }
            }
            else if route.hasPrefix("couch-") { CouchFlowView(session: fixture.couch) }
            else if route.hasPrefix("radio-") {
                let dolls = (try? fixture.container.mainContext.fetch(FetchDescriptor<Doll>())) ?? []
                AmbientSoundView(dolls: dolls.sorted { ($0.presetConfiguration?.shape == .cat ? 0 : 1) < ($1.presetConfiguration?.shape == .cat ? 0 : 1) }.map(\.state), player: fixture.ambient,
                                 initialSheet: route == "radio-timer" ? .timer : route == "radio-sound" ? .sound : nil,
                                 initiallyScrolled: route == "radio-scroll")
            }
            else if route == "model-compare" { PresetComparisonView() }
            else if route == "model-side" { PresetComparisonView(cameraYaw: .pi / 4) }
            else if ["create-method", "photo-method", "create-custom"].contains(route) {
                creationShell { CreateMethodStep(draft: draft, onPreset: {}, onCutout: {}).safeAreaInset(edge: .top, spacing: 0) { CreationProgress(step: 2) } }
            }
            else if route == "photo-finish" { CreateFlowView(previewDraft: draft, startAtMaking: true) { _ in } }
            else if route == "photo-flow" { CreateFlowView(previewDraft: draft) { _ in } }
            else if route == "create-entry" { CreateFlowView { _ in } }
            else if ["create-name", "create-name-empty", "create-parts", "create-large", "create", "rabbit", "bear", "photo-cat", "photo-rabbit", "photo-bear"].contains(route) {
                creationShell { DollCustomizeStepA(draft: draft) {} }
            } else if ["home-ui", "walking"].contains(route) { NavigationStack { HomeView(couch: fixture.couch) } }
            else if ["window-sky", "window-cutout", "cutout-front"].contains(route) {
                let dolls = ((try? fixture.container.mainContext.fetch(FetchDescriptor<Doll>())) ?? []).sorted { $0.name < $1.name }
                if route == "cutout-front", let doll = dolls.first(where: { $0.presetConfiguration == nil }) {
                    CompanionScene(dolls: [doll.state], kind: .radio(playing: false)).frame(height: 350)
                } else {
                    WindowCompanionView(dolls: dolls.map(\.state))
                }
            }
            else if ["floor-photo", "window-frame"].contains(route), let item = (try? fixture.container.mainContext.fetch(FetchDescriptor<RoomItem>()))?.first(where: { $0.kind == (route == "floor-photo" ? .floor : .wall) }) {
                NavigationStack { FurnitureCustomView(item: item, initialStyle: route == "floor-photo" ? .photo : .color) }
            }
            else if route == "frame-photo", let frame = (try? fixture.container.mainContext.fetch(FetchDescriptor<RoomItem>()))?.first(where: { $0.kind == .frame }) {
                NavigationStack { FurnitureCustomView(item: frame, initialStyle: .photo) }
            }
            else if ["desk-color", "desk-photo-empty", "desk-photo"].contains(route), let item = (try? fixture.container.mainContext.fetch(FetchDescriptor<RoomItem>()))?.first(where: { $0.kind == .desk }) {
                NavigationStack { FurnitureCustomView(item: item, initialStyle: route == "desk-color" ? .color : .photo) }
            }
            else if ["decorate-wall", "wall-photo-empty", "wall-photo", "decorate-floor"].contains(route) {
                NavigationStack { DecorateView(category: route == "decorate-floor" ? .flooring : .wallpaper, surfacePhotoMode: route.hasPrefix("wall-photo")) }
            }
            else if route == "decorate-decor" { NavigationStack { DecorateView(category: .decor) } }
            else if ["decorate-added", "decorate-exit"].contains(route) {
                NavigationStack { DecorateView(selectedID: (try? fixture.container.mainContext.fetch(FetchDescriptor<RoomItem>()))?.filter { $0.kind == .plant }.max { $0.createdAt < $1.createdAt }?.id, isConfirmingDiscard: route == "decorate-exit") }
            }
            else if route == "decorate" { NavigationStack { DecorateView() } }
            else if route == "decorate-selected" {
                NavigationStack { DecorateView(selectedID: (try? fixture.container.mainContext.fetch(FetchDescriptor<RoomItem>()))?.first { $0.kind == .desk }?.id) }
            }
            else { FocusFlowView(session: fixture.session, showMain: ["main", "main-scroll"].contains(route)) }
        }.modelContainer(fixture.container).defaultAppStorage(fixture.defaults).environment(fixture.appState)
    }
}

private struct CouchPlaybackAuditView: View {
    let session: CouchSession
    @State private var fullScreen = false
    var body: some View {
        VStack {
            Spacer()
            if !fullScreen { CouchMiniPlayer(session: session) { fullScreen = true }.frame(width: 300) }
            Spacer()
        }.frame(maxWidth: .infinity).background(Color.mib.bg.screen)
            .fullScreenCover(isPresented: $fullScreen) { CouchFlowView(session: session) }
            .task {
                fullScreen = true
                try? await Task.sleep(for: .seconds(12))
                session.player.pause()
                try? await Task.sleep(for: .seconds(1))
                let before = session.player.elapsed
                let web = session.player.webView
                fullScreen = false
                try? await Task.sleep(for: .seconds(3))
                let kept = session.player.ready && web === session.player.webView && abs(session.player.elapsed - before) < 1.5 && !session.player.playing
                session.player.toggle()
                try? await Task.sleep(for: .seconds(3))
                let resumed = session.player.playing && session.player.elapsed > before
                session.player.pause()
                let history = session.library.videos.contains { $0.title == session.player.title && $0.lastWatched != nil }
                let report = "actual playback history: \(history); same player and position after full → mini: \(kept); resumed: \(resumed); time: \(session.player.elapsed)"
                try? report.write(to: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("couch-playback-audit.txt"), atomically: true, encoding: .utf8)
            }
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

#if DEBUG
/// Readiness is scoped to a capture nonce, so stale frames cannot pass a later run.
enum DesignPreviewSignal {
    private static var startupFinished = false
    private static var sceneRendered = false
    private static var renderedDollCount: Int?
    static func startupDidFinish() {
        startupFinished = true
        writeIfReady()
    }
    static func sceneReady(dollCount: Int? = nil) {
        sceneRendered = true
        if let dollCount { renderedDollCount = dollCount }
        writeIfReady()
    }
    private static func writeIfReady() {
        guard startupFinished && sceneRendered else { return }
        guard let nonce = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--qa-capture-id=") })?.split(separator: "=", maxSplits: 1).last else { return }
        var report = ["captureID": String(nonce), "readyAt": Date.now.ISO8601Format()]
        if let renderedDollCount { report["dollCount"] = String(renderedDollCount) }
        report["startupFinished"] = "true"
        guard let data = try? JSONSerialization.data(withJSONObject: report) else { return }
        try? data.write(to: URL.documentsDirectory.appending(path: "design-frame-ready.json"), options: .atomic)
    }
}
#endif
