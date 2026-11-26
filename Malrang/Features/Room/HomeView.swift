import simd
import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.roomActionButtonFrame) private var roomActionButtonFrame
    @Query(sort: \Doll.createdAt) private var dolls: [Doll]
    @Query(sort: \RoomItem.createdAt) private var items: [RoomItem]
    @State private var isCreating = false
    @State private var isConfirmingPlacementExit = false
    @State private var isFocusing = false
    @State private var deskPoint: CGPoint?
    @State private var focusBackground: UIImage?
    @State private var openingFocus = false
    @State private var lastLookTranslation = CGSize.zero
    @State private var pendingDoll: Doll?
    @State private var isDecorating = false
    /// 배치 모드일 때 시작 위치. 취소하면 여기로 되돌린다. nil이면 배치 모드가 아니다.
    @State private var placementStart: [UUID: SIMD3<Float>]?
    @State private var roomPlacement = RoomSceneView.Placement()
    @State private var placementPositions: [UUID: SIMD3<Float>] = [:]
    @State private var lastMovedID: UUID?
    @State private var placementAddedID: UUID?
    @State private var isPlacementSaveFailed = false
    @AppStorage("hapticOn") private var hapticOn = true
    @AppStorage("didRestoreBackWallDesk20261124") private var didRestoreBackWallDesk = false
    @State private var feelCount = 0
    @State private var hold: RoomSceneView.Hold?
    @State private var removalTargetFrame = CGRect.zero
    @State private var toast: Toast?
    @State private var sceneReadiness = RoomSceneReadiness()
    private var isSceneReady: Bool { sceneReadiness.isReady }
    @State private var furnitureRects: [String: CGRect] = [:]
    @State private var furnitureMenu: RoomItem?
    @State private var dollMenu: Doll?
    @State private var dancingDoll: Doll?
    @State private var homeDance: HomeDollDance?
    @State private var dollPopupAnchor = CGRect.zero
    @State private var dollARDoll: Doll?
    @State private var travelingDollID: UUID?
    @State private var furnitureChoice: FurnitureChoice?
    @State private var blockedPlacement: FurnitureKind?
    @State private var blockedDollRect: CGRect?
    @State private var windowSelection: [DollState] = []
    @State private var showingWindow = false
    @State private var showingSound = false
    @State private var couch: CouchSession
    @State private var showingCouch = false
    @State private var pendingCouch = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var frameARDoll: Doll?
    @State private var frameTarget: RoomItem?
    @State private var pendingFrameDoll: Doll?
    @State private var showGuide = false
    @State private var showFurnitureHint = true
    @State private var interactionMessage: String?
    @State private var interactionError: String?
    @AppStorage("didSeeFurnitureGuideV2") private var didSeeFurnitureGuide = false
    @AppStorage("usedFurnitureActions") private var usedFurnitureActions = ""
    private enum FurnitureChoice: String, Identifiable { case window, sleep, frame, couch; var id: String { rawValue } }
    private var sleeper: Doll? { placedDolls.first { $0.restingBedID != nil } }
    private var hintName: String? { ["책상", "창문", "침대", "액자"].first { furnitureRects[$0] != nil && !usedFurnitureActions.split(separator:",").contains(Substring($0)) } }


    init(couch: CouchSession? = nil) {
        _couch = State(initialValue: couch ?? CouchSession())
    }

    /// One-time correction requested for an already saved room. Later user edits
    /// remain untouched; entering the editor never reapplies this restoration.
    private func restoreBackWallDeskIfNeeded() {
        guard !didRestoreBackWallDesk, let desk = items.first(where: { $0.kind == .desk }) else { return }
        let before = items.map(\.state)
        let oldDesk = desk.state
        let supportedLamps = items.filter { RoomLayout.lampSupport(for: $0.state, in: before)?.id == desk.id }
        let oldRotation = simd_quatf(angle: oldDesk.yaw, axis: [0, 1, 0])
        for lamp in supportedLamps {
            let local = oldRotation.inverse.act(SIMD3<Float>(Float(lamp.x) - oldDesk.x, 0, Float(lamp.z) - oldDesk.z))
            lamp.x = 0.25 + Double(local.x)
            lamp.z = -0.68 + Double(local.z)
        }
        desk.x = 0.25; desk.z = -0.68; desk.yaw = 0
        do {
            try modelContext.save()
            didRestoreBackWallDesk = true
        } catch {
            for item in items {
                if let original = before.first(where: { $0.id == item.id }) { item.restore(original) }
            }
            interactionError = "책상 위치를 복원하지 못했어요. 다시 시도해 주세요."
        }
    }

    private struct Toast: Equatable {
        let message: String
        let undo: [UUID: SIMD3<Float>]
        let addedID: UUID?
        var removedID: UUID? = nil
    }

    private var placedDolls: [Doll] { dolls.filter(\.isPlaced) }
    private var showsRoomScene: Bool {
        appState.tab == .home && !appState.isShowingAR && !isCreating && !isFocusing
            && !isDecorating && !showingWindow && !showingSound && !showingCouch
    }
    private var roomDolls: [DollState] {
        placedDolls.map { doll in
            var state = doll.state
            if let position = placementPositions[doll.id] { state.position = position }
            if dancingDoll?.id == doll.id { state.dance = homeDance?.move }
            if placementStart == nil, (couch.current != nil || couch.resting), doll.restingBedID == nil,
               let index = couch.dolls.firstIndex(where: { $0.id == doll.id }),
               let sofa = items.first(where: { $0.id == couch.sofaID && $0.kind == .sofa }) {
                let offset = simd_act(simd_quatf(angle: Float(sofa.yaw), axis: [0, 1, 0]),
                                     SIMD3<Float>((Float(index) - Float(couch.dolls.count - 1) / 2) * 0.22, 0, 0.06))
                state.position = SIMD3<Float>(Float(sofa.x), sofa.kind.seatHeight ?? 0.16, Float(sofa.z)) + offset
                state.dance = nil
                state.couchCompanionScale = 1
            }
            return state
        }
    }
    @Environment(\.startupPresentationFinished) private var startupPresentationFinished

    var body: some View {
        NavigationStack {
            homeContent
            .alert("변경사항을 저장하지 못했어요", isPresented: Binding(get: { interactionError != nil }, set: { if !$0 { interactionError = nil } })) {
                Button("확인", role: .cancel) { interactionError = nil }
            } message: { Text(interactionError ?? "다시 시도해 주세요.") }
            .task(id: showFurnitureHint && didSeeFurnitureGuide && !showGuide && isSceneReady) {
                guard showFurnitureHint, didSeeFurnitureGuide, !showGuide, isSceneReady else { return }
                #if DEBUG
                // Capture the same transient production hint without racing its dismissal.
                if ProcessInfo.processInfo.arguments.contains("--furniture-hint-preview") { return }
                #endif
                do { try await Task.sleep(for: .seconds(10)) } catch { return }
                showFurnitureHint = false
            }
            .task(id: interactionMessage) {
                guard interactionMessage != nil else { return }
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                interactionMessage = nil
            }
            .onChange(of: items.map(\.id), initial: true) { _, _ in restoreBackWallDeskIfNeeded() }
            .task(id: items.map(\.state)) {
                if !isDecorating { relocateBlockedDolls() }
            }
            .task(id: isDecorating) {
                if !isDecorating { relocateBlockedDolls() }
            }
            .task(id: isSceneReady && !items.isEmpty && appState.roomEntrance.finished) { await sceneReady() }
            .task(id: startupPresentationFinished && appState.tab == .home) {
                if startupPresentationFinished && appState.tab == .home { appState.roomEntrance.present() }
            }
            .background(Color.a.pinkLight)
            .navigationTitle("내 방")
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .preference(key: AppTabBarHiddenPreference.self,
                        value: (!didSeeFurnitureGuide && appState.roomEntrance.finished) || showGuide || placementStart != nil || hold != nil || isDecorating || dancingDoll != nil)
            .navigationDestination(isPresented: $isDecorating) {
                DecorateView()
            }
            .alert("배치를 저장하지 못했어요", isPresented: $isPlacementSaveFailed) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("배치한 위치는 유지돼요. 잠시 후 다시 완료를 눌러 주세요.")
            }
            .fullScreenCover(isPresented: $isFocusing, onDismiss: { focusBackground = nil }) { FocusFlowView(roomSnapshot: focusBackground) }
            .fullScreenCover(isPresented: $isCreating, onDismiss: {
                if let doll = pendingDoll {
                    pendingDoll = nil
                    place(doll)
                }
            }) {
                CreateFlowView { doll in pendingDoll = doll }
            }
            .onChange(of: items.map(\.id)) { _, ids in
                if let sofaID = couch.sofaID, !ids.contains(sofaID) { couch.stop() }
                for doll in placedDolls {
                    if let bed = doll.restingBedID, !ids.contains(bed) { doll.restingBedID = nil }
                }
                do { try modelContext.save() } catch { interactionError = "변경한 방 상태를 저장하지 못했어요." }
            }
            .task(id: appState.dollToPlace?.id) {
                if let doll = appState.dollToPlace {
                    place(doll)
                    appState.dollToPlace = nil
                }
            }
            .task(id: toast) {
                guard toast != nil else { return }
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                toast = nil
            }
            .sensoryFeedback(.success, trigger: toast?.message)
            .sensoryFeedback(trigger: feelCount) { _, _ in hapticOn ? .impact(weight: .heavy) : nil }
        }
        .sheet(isPresented: Binding(get: { dancingDoll != nil }, set: { if !$0 { dismissDollPopup() } }), onDismiss: dismissDollPopup) {
            HomeDollDancePicker(selection: $homeDance, onClose: dismissDollPopup)
                .presentationDetents([.height(160)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .presentationBackground(.white)
        }
    }

    private func sceneReady() async {
                guard isSceneReady, appState.roomEntrance.finished else { return }
                if isSceneReady && appState.roomEntrance.finished && !items.isEmpty && !didSeeFurnitureGuide { showGuide = true }
                #if DEBUG
                if isSceneReady, ProcessInfo.processInfo.arguments.contains("--home-drag-audit") {
                    showGuide = false
                    try? await Task.sleep(for: .seconds(1))
                    var report = await roomPlacement.auditDrag()
                    if !ProcessInfo.processInfo.arguments.contains("--hold-trash-preview") {
                        let stored = dolls.first { !$0.isPlaced }
                        report.append(stored != nil && dolls.count == 3 ? "PASS: stored doll remains in collection" : "FAIL: storage persistence")
                        if let toast { undo(toast) }
                        report.append(dolls.allSatisfy(\.isPlaced) ? "PASS: undo restores room membership" : "FAIL: undo")
                    }
                    let text = report.joined(separator: "\n")
                    print(text)
                    try? text.write(to: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("home-drag-audit.txt"), atomically: true, encoding: .utf8)
                }
                if (ProcessInfo.processInfo.arguments.contains("--design-preview=home-ui") || ProcessInfo.processInfo.arguments.contains("--design-preview=tabs-ui")), isSceneReady {
                    if ProcessInfo.processInfo.arguments.contains("--furniture-preview=guide") { showGuide = true }
                    else if ProcessInfo.processInfo.arguments.contains("--furniture-preview=sleep"), sleeper == nil, let doll = placedDolls.first { showGuide = false; putToBed(doll) }
                    else if ProcessInfo.processInfo.arguments.contains("--furniture-preview=window") { showGuide=false;windowSelection=placedDolls.map(\.state);showingWindow=true }
                    else if ProcessInfo.processInfo.arguments.contains("--furniture-preview=couch-mini"), couch.current == nil {
                        showGuide=false; couch.sofaID=items.first { $0.kind == .sofa }?.id
                        couch.dolls=Array(placedDolls.prefix(1)).map(\.state)
                        couch.watch(CouchVideo(source: YouTubeSource(videoID: "M7lc1UVf-VE", playlistID: nil), title: "YouTube IFrame Player API"))
                    }
                    else if ProcessInfo.processInfo.arguments.contains("--furniture-preview=couch-rest"), !couch.resting, let sofa = items.first(where: { $0.kind == .sofa }) {
                        showGuide=false; beginCouch(resting: true, sofa: sofa)
                    }
                    else if ProcessInfo.processInfo.arguments.contains("--furniture-preview=placement") {
                        showGuide = false; beginPlacement()
                        lastMovedID = placedDolls.first(where: { $0.presetConfiguration?.shape == .cat })?.id ?? placedDolls.first?.id
                        if ProcessInfo.processInfo.arguments.contains("--blocked-preview") {
                            blockedPlacement = .bed
                            blockedDollRect = lastMovedID.flatMap { roomPlacement.screenRect(of: $0, bodyOnly: true) }
                        }
                        if ProcessInfo.processInfo.arguments.contains("--placement-exit-preview") { isConfirmingPlacementExit = true }
                    }
                    else if ProcessInfo.processInfo.arguments.contains("--furniture-preview=couch-choice") { showGuide=false; furnitureChoice = .couch }
                    else if ProcessInfo.processInfo.arguments.contains("--furniture-preview=sofa") { showGuide=false;furnitureMenu=items.first { $0.kind == .sofa } }
                    else if ProcessInfo.processInfo.arguments.contains("--furniture-preview=focus") { showGuide=false; openFocus() }
                    else if ProcessInfo.processInfo.arguments.contains("--furniture-preview=sound") { showGuide=false;showingSound=true }
                }
                #endif
    }

    private var homeContent: some View {
        // 3D 화면은 상단바·탭바가 사라져도 크기가 변하지 않게 화면 전체에 깐다.
        ZStack {
            RoomLoadingBackdrop(entrance: appState.roomEntrance)
            Group {
                // 3D 화면 두 개를 동시에 그리면 위에 뜬 쪽이 그려지지 않아서, AR이나 다른 3D 화면을 쓰는 동안 방을 내린다.
                if !showsRoomScene {
                    Color.app.background
                } else {
                    RoomSceneView(
                        items: items.map(\.state),
                        dolls: roomDolls,
                        mode: .home,
                        onTapDoll: openDollMenu,
                        canMoveDolls: placementStart != nil,
                        canLongPressDolls: !showGuide && furnitureMenu == nil && dollMenu == nil && dancingDoll == nil && travelingDollID == nil,
                        dollRemovalTarget: placementStart == nil ? removalTargetFrame : .zero,
                        onDropDoll: dropDoll,
                        onCannotMoveDoll: { interactionMessage = "잠든 인형은 침대에서 깨운 뒤 옮겨 주세요" },
                        allowsDollWandering: appState.roomEntrance.finished && !openingFocus && furnitureMenu == nil && dollMenu == nil && dancingDoll == nil && !showGuide && !appState.roomToolsOpen && !ProcessInfo.processInfo.arguments.contains("--home-drag-audit") && !ProcessInfo.processInfo.arguments.contains("--ui-testing"),
                        movingDollID: lastMovedID,
                        placement: roomPlacement,
                        onPickDoll: { lastMovedID = $0 },
                        onHoldDoll: { value in
                            if hold == nil, value != nil {
                                toast = nil; showFurnitureHint = false
                                if let value, couch.dolls.contains(where: { $0.id == value.id }) { couch.stop() }
                            }
                            hold = value
                            if value == nil {
                                if placementStart == nil { blockedPlacement = nil; blockedDollRect = nil }
                                removalTargetFrame = .zero
                            }
                        },
                        onMoveDoll: moveDoll,
                        onBlockedPlacement: {
                            blockedPlacement = $0
                            blockedDollRect = $0 == nil ? nil : lastMovedID.flatMap { roomPlacement.screenRect(of: $0, bodyOnly: true) }
                            if placementStart == nil, let kind = $0 { interactionMessage = "\(kind.label) 위에는 인형을 놓을 수 없어요." }
                        },
                        onDoubleTapItem: { id in
                            guard placementStart == nil, let item = items.first(where: { $0.id == id }) else { return }
                            openFurniture(item)
                        },
                        onTapItem: { id in
                            guard placementStart == nil,
                                  let id, let item = items.first(where: { $0.id == id }) else { return }
                            openFurniture(item)
                        },
                        onFeel: { feelCount += 1 },
                        isTransparent: true,
                        illustrationTargetY: 0.84,
                        isCozyRoom: true,
                        onSleepSettled: { id in
                            guard travelingDollID == id else { return }
                            travelingDollID = nil
                            if let doll = placedDolls.first(where: { $0.id == id }) { interactionMessage = doll.restingBedID == nil ? "\(doll.name.josa("이", "가")) 자리로 돌아왔어요" : "\(doll.name.josa("이", "가")) 잠들었어요" }
                        },
                        readiness: sceneReadiness,
                        onDeskScreen: { deskPoint = $0 },
                        onFurnitureScreen: { furnitureRects = $0 },
                        entrance: appState.roomEntrance
                    )
                    .renderedOnlyWhileVisible(background: .clear)
                    .padding(.bottom, dancingDoll == nil ? 0 : 152)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        let previous = lastLookTranslation
                        lastLookTranslation = value.translation
                        roomPlacement.look(by: CGSize(width: value.translation.width - previous.width,
                                                      height: value.translation.height - previous.height))
                    }
                    .onEnded { _ in lastLookTranslation = .zero },
                including: placementStart == nil ? .all : .none
            )
            .overlay {
                if placementStart != nil, blockedPlacement != nil, let rect = blockedDollRect {
                    Ellipse().stroke(Color.red.opacity(0.54), lineWidth: 12)
                        .blur(radius: 14)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY + 9)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
                holdTooltip
            }
            .ignoresSafeArea()
        }
        .overlay(alignment: .top) { if !showGuide { topOverlay.modifier(RoomEntranceMotion(entrance: appState.roomEntrance, node: appState.roomEntrance.loadingDoll == nil ? "1932:6512" : "1913:7875")) } }
        .overlay {
            ZStack {
                if showsRoomScene, !isSceneReady, appState.roomEntrance.finished {
                    RoomLoadingView(entrance: appState.roomEntrance, waitsForScene: true)
                }
            }
        }
        .overlay {
            if appState.roomToolsOpen && placementStart == nil && hold == nil && !showGuide {
                GeometryReader { geometry in
                    let frame = geometry.frame(in: .global)
                    let bottom = roomActionButtonFrame.isEmpty ? geometry.safeAreaInsets.bottom + 20
                        : max(0, frame.maxY - roomActionButtonFrame.minY + 12)
                    let trailing = roomActionButtonFrame.isEmpty ? 22
                        : max(0, frame.maxX - roomActionButtonFrame.maxX)
                    Color.clear.contentShape(Rectangle()).onTapGesture { appState.roomToolsOpen = false }
                        .overlay(alignment: .bottomTrailing) {
                            roomActions.padding(.trailing, trailing).padding(.bottom, bottom)
                        }
                }
            }
        }
        .animation(RoomMotion.response(reduceMotion: reduceMotion), value: appState.roomToolsOpen)
        .onChange(of: appState.roomToolsOpen) { _, open in
            if open { showFurnitureHint = false; showGuide = false; furnitureMenu = nil; dismissDollPopup() }
        }
        .onChange(of: placementStart != nil || hold != nil || showGuide) { _, unavailable in
            if unavailable { appState.roomToolsOpen = false; furnitureMenu = nil; dismissDollPopup() }
        }
        .safeAreaInset(edge: .bottom) { bottomBar.accessibilityHidden(showGuide) }
        .overlay { if !appState.roomToolsOpen { furnitureOverlays } }
        .overlay { dollOverlays }
        .overlay(alignment: .bottom) {
            if showGuide {
                Button("확인했어요") {
                    showFurnitureHint = false
                    didSeeFurnitureGuide = true
                    showGuide = false
                }
                .buttonStyle(D1PrimaryStyle())
                .padding(.horizontal, D1.inset)
                .padding(.bottom, Spacing.l)
            }
        }
        .overlay(alignment: .bottom) { removalTarget }
        .overlay {
            if couch.current != nil, !couch.choosing, !showingCouch, appState.tab == .home, placementStart == nil,
               !isFocusing, !showingSound, !showingWindow, !isCreating, !isDecorating, !showGuide, !appState.isShowingAR, furnitureChoice == nil, furnitureMenu == nil, dollMenu == nil, dancingDoll == nil {
                GeometryReader { geometry in
                    CouchMiniPlayer(session: couch) { showingCouch = true }
                        .frame(width: 200.034, height: 111.873)
                        .position(x: geometry.size.width * 238.117 / 390, y: geometry.size.height * 460.7565 / 844)
                    CouchMiniControls(session: couch) { showingCouch = true }
                        .frame(width: 171, height: 48).position(x: 107.5, y: 156)
                }.ignoresSafeArea()
            }
        }
        .allowsHitTesting(!isConfirmingPlacementExit)
        .accessibilityHidden(isConfirmingPlacementExit)
        .overlay {
            if isConfirmingPlacementExit {
                RepresentativeConfirmDialog(title: "인형 만들기를 그만할까요?", message: "지금 바꾼 위치는 저장되지 않아요.", verticalOffset: 24.47, onLeave: {
                    isConfirmingPlacementExit = false; cancelPlacement()
                }, onStay: { isConfirmingPlacementExit = false })
            }
        }
        .fullScreenCover(isPresented: $showingCouch) { CouchFlowView(session: couch) }
        .onChange(of: placementStart != nil) { _, placing in if placing && couch.resting { couch.stop() } }
        .onChange(of: scenePhase) { _, phase in if phase != .active { couch.player.pause(); roomPlacement.cancelDrag() } }
        .onAppear {
            let context = modelContext
            couch.onActivityStarted = { ids in DollActivityRecorder.record(.sofa, ids: ids, in: context) }
        }
        .onChange(of: showingWindow) { wasShowing, showing in
            if !wasShowing, showing { DollActivityRecorder.record(.window, ids: windowSelection.map(\.id), in: modelContext) }
        }
        .onChange(of: appState.tab) { _, tab in
            if tab != .home { couch.player.pause(); furnitureMenu = nil; dismissDollPopup() }
        }
        .onChange(of: isFocusing || showingSound || showingWindow || isCreating || isDecorating || appState.isShowingAR || placementStart != nil || furnitureChoice != nil || showGuide) { _, hidden in
            if hidden { couch.player.pause() }
        }
        .sheet(item: Binding(get: { furnitureChoice == .couch ? nil : furnitureChoice },
                             set: { furnitureChoice = $0 }), onDismiss: finishFurnitureChoice) { choice in
            furnitureChoiceContent(choice)
        }
        .fullScreenCover(isPresented: Binding(get: { furnitureChoice == .couch },
                                             set: { if !$0 { furnitureChoice = nil } }),
                         onDismiss: finishFurnitureChoice) {
            CouchChoicePresentation { furnitureChoiceContent(.couch) }.presentationBackground(.clear)
        }
        .fullScreenCover(isPresented: $showingWindow, onDismiss: { windowSelection = [] }) {
            WindowCompanionView(dolls: windowSelection, frameColor: items.first { $0.kind == .wall }?.windowFrameColor)
        }
        .fullScreenCover(item: $frameARDoll, onDismiss: { frameTarget = nil; appState.isShowingAR = false }) { doll in
            ARCaptureView(doll: doll, onUsePhoto: { photo in
                guard let frame = frameTarget, items.contains(where: { $0.id == frame.id }),
                      let data = photo.jpegData(compressionQuality: 0.9) else {
                    throw CocoaError(.fileWriteUnknown)
                }
                let previous = frame.state
                frame.photoData = data
                frame.photoScale = 1
                frame.photoFit = 0
                frame.photoFlipped = false
                frame.photoTurns = 0
                frame.photoOffsetX = 0
                frame.photoOffsetY = 0
                do { try modelContext.save() }
                catch { frame.restore(previous); throw error }
                interactionMessage = "촬영한 사진을 액자에 넣었어요"
            })
        }
        .fullScreenCover(item: $dollARDoll, onDismiss: { appState.isShowingAR = false }) { doll in
            ARCaptureView(doll: doll)
        }
        .fullScreenCover(isPresented: $showingSound) {
            AmbientSoundView(dolls: soundCompanions)
        }
    }

    private func finishFurnitureChoice() {
        if !windowSelection.isEmpty { showingWindow = true }
        if pendingCouch { pendingCouch = false; showingCouch = true }
        if let doll = pendingFrameDoll {
            pendingFrameDoll = nil
            appState.isShowingAR = true
            frameARDoll = doll
        } else { frameTarget = nil }
    }

    private func furnitureChoiceContent(_ choice: FurnitureChoice) -> some View {
        let forCouch = choice == .couch
        return DollChoiceSheet(dolls: choice == .frame ? dolls : ((choice == .window || forCouch) ? placedDolls.filter { $0.restingBedID == nil } : placedDolls), multiple: choice == .window || forCouch,
                               title: forCouch ? "같이 볼 인형" : choice == .frame ? "누구와 사진을 찍을까요?" : nil,
                               subtitle: forCouch ? "소파에는 최대 2명까지 앉을 수 있어요" : choice == .frame ? "함께 찍은 사진을 이 액자에 넣어요" : nil,
                               actionTitle: forCouch ? "다음" : choice == .frame ? "AR 카메라 열기" : nil,
                               maximumSelection: forCouch ? 2 : nil, sourceLayout: forCouch) { chosen in
            if forCouch {
                couch.stop(); couch.dolls = Array(chosen.prefix(2)).map(\.state)
                pendingCouch = true
            } else if choice == .window { windowSelection = chosen.map(\.state) }
            else if choice == .frame { pendingFrameDoll = chosen.first }
            else if let doll = chosen.first { putToBed(doll) }
        }
    }

    private func relocateBlockedDolls() {
        let furniture = items.map(\.state)
        var occupied = placedDolls.map(\.position)
        var changed = false
        for doll in placedDolls where doll.restingBedID == nil {
            if !RoomLayout.canPlaceDoll(at: [doll.position.x, doll.position.z], in: furniture) {
                if let spot = RoomLayout.dollSpot(avoiding: furniture, dolls: occupied) {
                    doll.position = spot; occupied.append(spot)
                } else {
                    doll.isPlaced = false
                    interactionMessage = "인형을 놓을 빈자리가 없어 인형 목록에 보관했어요"
                }
                changed = true
            }
        }
        if changed { do { try modelContext.save() } catch { interactionError = "인형의 새 위치를 저장하지 못했어요." } }
    }

    private func openFocus() {
        guard !openingFocus, !isFocusing else { return }
        openingFocus = true
        roomPlacement.captureImage { image in
            focusBackground = image
            openingFocus = false
            isFocusing = true
        }
    }

    private var topOverlay: some View {
        VStack(spacing: Spacing.s) {
            if placementStart == nil && hold == nil { headerA }
            topMessage
        }
    }

    private var headerA: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image("home_logo_icon").accessibilityHidden(true)
                    Text("my room").notCliche(25.397, relativeTo: .title).tracking(-1.778)
                        .foregroundStyle(Color.white)
                }.frame(height: 44)
                AmbientMiniPlayer { showingSound = true }
            }
            Spacer(minLength: 12)

        }.padding(.horizontal, 39.79).padding(.top, 22.5)
    }

    private var roomActions: some View {
        VStack(alignment: .trailing, spacing: 12) {
            roomAction("인형 만들기", icon: "doll") { isCreating = true }
            roomAction("방 꾸미기", icon: "bed") { isDecorating = true }
            roomAction("ASMR", icon: nil) { showingSound = true }
        }.modifier(RoomReveal())
            .transition(RoomMotion.reveal(reduceMotion: reduceMotion, anchor: .bottomTrailing))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("방 도구")
            .accessibilityAction(.escape) { appState.roomToolsOpen = false }
    }

    private func roomAction(_ title: String, icon: String?, action: @escaping () -> Void) -> some View {
        Button {
            appState.roomToolsOpen = false
            action()
        } label: {
            HStack(spacing: 12) {
                if let icon { D1Icon(name: icon) }
                else { Image(systemName: "headphones").font(.system(size: 24)).frame(width: 24, height: 24) }
                Text(title).pretendard(.bold, D1.ctaFontSize).fixedSize()
            }.foregroundStyle(Color.mib.text.primary)
                .padding(.horizontal, 12).frame(height: 44).d1ImageSurface(radius: 22)
        }.buttonStyle(RoomPressStyle())
    }

    @ViewBuilder
    private var topMessage: some View {
        if placementStart != nil {
            VStack(spacing: 14.73) {
                HStack {
                    Button { isConfirmingPlacementExit = true } label: {
                        Image("rep4_edit_back").resizable().frame(width: 31.854, height: 31.854)
                            .frame(width: 44, height: 44, alignment: .topLeading)
                    }.buttonStyle(.plain).accessibilityLabel("배치 취소")
                        .disabled(isConfirmingPlacementExit).accessibilityHidden(isConfirmingPlacementExit)
                    Spacer()
                }.padding(.horizontal, 23.81)
                Text(blockedPlacement.map { "\($0.label) 위에는 인형을 놓을 수 없어요." } ?? "인형을 끌거나 놓을 자리를 눌러요.")
                    .pretendard(.regular, 14).tracking(-0.7).foregroundStyle(Color.mib.text.onPrimary)
                    .multilineTextAlignment(.center).frame(width: 280, height: 34)
                    .background {
                        Group {
                            if blockedPlacement == nil {
                                LinearGradient(colors: [Color(uiColor: Palette.uiColor("#525252")).opacity(0.58), Color(uiColor: Palette.uiColor("#696969")).opacity(0.58)], startPoint: .top, endPoint: .bottom)
                            } else { Color(uiColor: Palette.uiColor("#AD4141")).opacity(0.77) }
                        }.clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(blockedPlacement == nil ? Color.clear : Color.white))
                    .offset(x: 3.9).opacity(isConfirmingPlacementExit ? 0 : 1)
                    .accessibilityAddTraits(.updatesFrequently)
            }.padding(.top, 14.73)
        } else if hold != nil {
            HintCapsule(text: blockedPlacement.map { "\($0.label)에는 이동시킬 수 없어요" } ?? "끌어서 옮기고, 아래 휴지통에 놓으면 보관해요")
                .padding(.horizontal, 22).padding(.top, 8)
        } else if let toast {
            HStack(spacing: Spacing.s) {
                Text(toast.message)
                Button("되돌리기") { undo(toast) }
                    .bold()
            }
            .appFont(.footnote)
            .foregroundStyle(Color.app.surface)
            .padding(.horizontal, Spacing.m)
            .frame(minHeight: 44)
            .background(Color.app.ink, in: Capsule())
            .padding(.top, Spacing.xs)
        }
    }

    /// 인형을 든 동안 머리 위를 따라다니며 어디에 놓일지 알려준다.
    @ViewBuilder
    private var holdTooltip: some View {
        if let hold, placementStart == nil, !hold.isOverRemovalTarget {
            let seat = RoomLayout.seat(at: [hold.position.x, hold.position.z], in: items.map(\.state)).item
            HintCapsule(text: blockedPlacement.map { "\($0.label)에는 이동시킬 수 없어요" } ?? "옮기는 중 · \(seat?.kind.label ?? "바닥")")
                .fixedSize()
                .position(x: hold.screen.x, y: hold.screen.y)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if placementStart != nil {
            HStack(spacing: 12) {
                Button("취소", action: cancelPlacement).buttonStyle(CreationSecondaryButton())
                Button("완료", action: finishPlacement).buttonStyle(.plain)
                    .modifier(RepresentativeActionSurface(primaryFill: LinearGradient(stops: [
                        .init(color: Color(uiColor: Palette.uiColor("#121212")), location: 0.32171),
                        .init(color: Color(uiColor: Palette.uiColor("#212226")), location: 0.97364)
                    ], startPoint: .top, endPoint: .bottom)))
                    .disabled(blockedPlacement != nil)
            }.environment(\.updatedFlowDesign, true)
                .padding(.horizontal, 18).padding(.bottom, 16)
        }
    }

    private func beginPlacement() {
        guard placementStart == nil else { return }
        toast = nil
        blockedPlacement = nil; blockedDollRect = nil
        placementStart = Dictionary(uniqueKeysWithValues: placedDolls.map { ($0.id, $0.position) })
        placementPositions = placementStart ?? [:]
    }

    private func moveDoll(_ id: UUID, to position: SIMD3<Float>) {
        guard placementStart != nil else { return }
        placementPositions[id] = position
        lastMovedID = id
    }

    /// A long-press drop commits immediately; the creation flow keeps its explicit confirmation.
    private func dropDoll(_ id: UUID, at position: SIMD3<Float>, store: Bool) -> Bool {
        guard placementStart == nil, let doll = placedDolls.first(where: { $0.id == id }) else { return false }
        let oldPosition = doll.position
        doll.position = position
        if store { doll.isPlaced = false }
        do { try modelContext.save() }
        catch {
            doll.position = oldPosition; doll.isPlaced = true
            interactionError = "인형의 위치를 저장하지 못했어요. 다시 시도해 주세요."
            return false
        }
        let seat = RoomLayout.seat(at: [position.x, position.z], in: items.map(\.state)).item
        toast = Toast(message: store ? "인형 목록에 보관했어요" : "\(seat?.kind.label ?? "바닥")에 배치했어요",
                      undo: [id: oldPosition], addedID: nil, removedID: store ? id : nil)
        return true
    }

    @ViewBuilder
    private var removalTarget: some View {
        if let hold, placementStart == nil {
            VStack(spacing: 8) {
                Text(hold.isOverRemovalTarget ? "놓으면 인형 목록에 보관해요" : "방에서 빼기")
                    .pretendard(.medium, 13).padding(.horizontal, 14).padding(.vertical, 8)
                    .d1ImageSurface(radius: 16)
                Image("d1_trash").renderingMode(.template).resizable().frame(width: 24, height: 24)
                    .foregroundStyle(hold.isOverRemovalTarget ? Color.app.danger : Color.mib.text.primary)
                    .frame(width: 72, height: 72).d1ImageSurface(radius: 36)
                    .scaleEffect(hold.isOverRemovalTarget ? 1.15 : 1)
                    .frame(width: 96, height: 96)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { removalTargetFrame = $0 }
                    .overlay(alignment: .top) {
                        if hold.isOverRemovalTarget, let doll = dolls.first(where: { $0.id == hold.id }) {
                            DollThumbnail(data: doll.imageData).frame(width: 64, height: 64).offset(y: -90)
                        }
                    }
            }.padding(.bottom, 16).frame(maxWidth: .infinity)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.15), value: hold.isOverRemovalTarget)
                .sensoryFeedback(.selection, trigger: hold.isOverRemovalTarget)
        }
    }

    private func finishPlacement() {
        guard blockedPlacement == nil, let start = placementStart else { return }
        if let hold, let id = lastMovedID { placementPositions[id] = hold.position }
        placementPositions.merge(roomPlacement.finish(), uniquingKeysWith: { _, visible in visible })
        for doll in placedDolls {
            if let position = placementPositions[doll.id] { doll.position = position }
        }
        do {
            try modelContext.save()
        } catch {
            isPlacementSaveFailed = true
            return
        }
        placementStart = nil
        placementPositions = [:]
        hold = nil
        blockedPlacement = nil; blockedDollRect = nil
        guard let moved = dolls.first(where: { $0.id == lastMovedID }) else { return }
        let seat = RoomLayout.seat(at: [moved.position.x, moved.position.z], in: items.map(\.state)).item
        toast = Toast(message: "\(seat?.kind.label ?? "바닥")에 배치했어요", undo: start, addedID: placementAddedID)
        placementAddedID = nil
        lastMovedID = nil
    }

    private func cancelPlacement() {
        if let start = placementStart { restore(start) }
        if let id = placementAddedID { dolls.first { $0.id == id }?.isPlaced = false }
        placementAddedID = nil
        placementStart = nil
        placementPositions = [:]
        hold = nil
        blockedPlacement = nil; blockedDollRect = nil
        lastMovedID = nil
        try? modelContext.save()
    }

    private func undo(_ toast: Toast) {
        if let id = toast.removedID { dolls.first { $0.id == id }?.isPlaced = true }
        restore(toast.undo)
        if let id = toast.addedID { dolls.first { $0.id == id }?.isPlaced = false }
        try? modelContext.save()
        self.toast = nil
    }

    private func restore(_ positions: [UUID: SIMD3<Float>]) {
        for doll in placedDolls {
            if let position = positions[doll.id] { doll.position = position }
        }
    }

    /// 새로 만들었거나 목록에서 고른 인형을 앞쪽 바닥에 두고 배치 모드를 연다.
    private func place(_ doll: Doll) {
        let spot = doll.isPlaced ? doll.position : RoomLayout.dollSpot(avoiding: items.map(\.state), dolls: placedDolls.map(\.position))
        guard let spot else { interactionMessage = "놓을 빈자리가 없어요. 가구나 인형을 옮겨 주세요"; return }
        beginPlacement()
        if !doll.isPlaced {
            placementAddedID = doll.id
            doll.position = spot
            doll.isPlaced = true
        }
        placementPositions[doll.id] = doll.position
        lastMovedID = doll.id
    }
}

#Preview("인형 있음") {
    HomeView()
        .environment(AppState())
        .modelContainer(.preview)
}

#Preview("빈 방") {
    HomeView()
        .environment(AppState())
        .modelContainer(for: [Doll.self, RoomItem.self], inMemory: true)
}

extension HomeView {
    private var soundCompanions: [DollState] { if let doll = sleeper ?? placedDolls.first { return [doll.state] };return [] }
    private func markUsed(_ name: String) {
        if !usedFurnitureActions.split(separator:",").contains(Substring(name)) { usedFurnitureActions += (usedFurnitureActions.isEmpty ? "" : ",") + name }
    }
    private func openFurniture(_ item: RoomItem) {
        dismissDollPopup()
        showFurnitureHint = false
        switch item.kind {
        case .wall:
            markUsed("창문")
            guard !placedDolls.isEmpty else { interactionMessage="먼저 인형을 만들어 방에 놓아 주세요";return }
            let awake = placedDolls.filter { $0.restingBedID == nil }
            guard !awake.isEmpty else { interactionMessage="침대에서 인형을 깨운 뒤 같이 구경해요";return }
            if awake.count == 1 { windowSelection=awake.map(\.state);showingWindow=true }
            else { furnitureChoice = .window }
        case .sofa: furnitureMenu=item;markUsed("소파")
        case .bed: furnitureMenu=item;markUsed("침대")
        case .frame: furnitureMenu=item;markUsed("액자")
        case .desk: furnitureMenu = item; markUsed("책상")
        default: break
        }
    }
    private func beginCouch(resting: Bool, sofa: RoomItem) {
        furnitureMenu = nil
        guard placedDolls.contains(where: { $0.restingBedID == nil }) else {
            interactionMessage = placedDolls.isEmpty ? "먼저 인형을 만들어 방에 놓아 주세요" : "인형을 깨운 뒤 함께 소파에 앉아요"
            return
        }
        if resting {
            if couch.resting, couch.sofaID == sofa.id { couch.stop(); return }
            let candidates = placedDolls.filter { $0.restingBedID == nil }.sorted {
                let center = SIMD3<Float>(Float(sofa.x), 0, Float(sofa.z))
                return simd_distance(roomPlacement.currentPosition(of: $0.id) ?? $0.position, center)
                    < simd_distance(roomPlacement.currentPosition(of: $1.id) ?? $1.position, center)
            }
            guard let doll = candidates.first(where: {
                DollBedRoute.plan(from: roomPlacement.currentPosition(of: $0.id) ?? $0.position,
                                  bed: sofa.state, items: items.map(\.state)) != nil
            }) else { interactionMessage = "의자까지 갈 길이 없어요. 주변 가구를 조금 옮겨 주세요"; return }
            couch.stop(); couch.sofaID = sofa.id; couch.dolls = [doll.state]; couch.resting = true
            DollActivityRecorder.record(.sofa, ids: [doll.id], in: modelContext)
            return
        }
        if couch.current != nil { showingCouch = true; return }
        couch.sofaID = sofa.id
        furnitureChoice = .couch
    }
    private func sofaMenuRow(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HomePopupLabel(title: title, primary: selected) {
                Image(systemName: title.hasPrefix("유튜브") ? "play.rectangle" : "sofa").frame(width: 28, height: 28)
            }
        }.buttonStyle(.plain)
    }
    private func putToBed(_ doll: Doll) {
        guard sleeper == nil, let bed=items.first(where:{$0.kind == .bed}) else { return }
        let start = roomPlacement.currentPosition(of: doll.id) ?? doll.position
        guard DollBedRoute.plan(from: start, bed: bed.state, items: items.map(\.state)) != nil else {
            interactionMessage = "침대까지 갈 길이 없어요. 주변 가구를 조금 옮겨 주세요"; return
        }
        let previous=(doll.restingBedID,doll.position,doll.danceRaw)
        let oldReturn = (doll.beforeSleepX, doll.beforeSleepY, doll.beforeSleepZ)
        let saved = doll.position
        doll.beforeSleepX = Double(saved.x); doll.beforeSleepY = Double(saved.y); doll.beforeSleepZ = Double(saved.z)
        doll.restingBedID=bed.id;doll.position=DollRestPose.bedPosition(bed.state);doll.danceRaw=nil
        do { try modelContext.save(); DollActivityRecorder.record(.bed, ids: [doll.id], in: modelContext);travelingDollID=doll.id;interactionMessage="\(doll.name.josa("이", "가")) 침대로 걸어가요" }
        catch { (doll.beforeSleepX, doll.beforeSleepY, doll.beforeSleepZ) = oldReturn; doll.restingBedID=previous.0;doll.position=previous.1;doll.danceRaw=previous.2;interactionError="재우기를 저장하지 못했어요. 다시 시도해 주세요." }
    }
    private func wakeSleeper() {
        guard let doll=sleeper else { return }
        guard let bedItem = items.first(where: { $0.id == doll.restingBedID }) else { return }
        let states = items.map(\.state)
        let occupied = placedDolls.filter { $0.id != doll.id }.map(\.position)
        let saved = doll.beforeSleepPosition.flatMap { spot -> SIMD3<Float>? in
            let seat = RoomLayout.seat(at: [spot.x, spot.z], in: states)
            guard abs(seat.height - spot.y) < 0.03,
                  occupied.allSatisfy({ simd_distance($0, spot) > 0.28 }),
                  DollBedRoute.plan(from: spot, bed: bedItem.state, items: states) != nil else { return nil }
            return spot
        }
        guard let spot = saved ?? RoomLayout.dollSpot(avoiding: states, dolls: occupied),
              DollBedRoute.plan(from: spot, bed: bedItem.state, items: states) != nil else {
            interactionMessage = "일어설 빈자리가 없어요. 가구나 인형을 옮겨 주세요"; return
        }
        let bed=doll.restingBedID, oldPosition=doll.position
        doll.restingBedID=nil;doll.position=spot
        do { try modelContext.save();travelingDollID=doll.id;interactionMessage="\(doll.name.josa("이", "가")) 일어나서 자리로 돌아가요" }
        catch { doll.restingBedID=bed;doll.position=oldPosition;interactionError="깨우기를 저장하지 못했어요. 다시 시도해 주세요." }
    }
    private var furnitureOverlays: some View {
        GeometryReader { geometry in
            ZStack(alignment:.topLeading) {
                if appState.roomEntrance.finished, isSceneReady, sleeper != nil, travelingDollID == nil, let rect=furnitureRects["침대"] {
                    Text("z z Z").pretendard(.bold,17).foregroundStyle(Color.mib.text.primary)
                        .position(x:rect.midX-24,y:rect.minY-16).allowsHitTesting(false)
                }
                if placementStart == nil, hold == nil, showFurnitureHint, !showGuide, furnitureMenu == nil, dollMenu == nil, dancingDoll == nil, furnitureChoice == nil, couch.current == nil, !couch.resting, let name=hintName, didSeeFurnitureGuide, !placedDolls.isEmpty, let rect=furnitureRects[name] {
                    RoundedRectangle(cornerRadius:22).stroke(Color.mib.line.selected,style:StrokeStyle(lineWidth:2,dash:[6,4]))
                        .frame(width:rect.width,height:rect.height).position(x:rect.midX,y:rect.midY).allowsHitTesting(false)
                    D1Bubble(text:name == "책상" ? "책상 톡톡! 같이 집중해볼까?" : name == "창문" ? "창문 두 번 톡톡! 같이 구름 보자" : name == "침대" ? "침대 톡톡! 인형을 재워줄래?" : "액자 톡톡 하면 같이 사진 찍을 수 있어")
                        .frame(width:242).position(x:min(max(rect.midX,130),geometry.size.width-130),y:min(rect.maxY+24,geometry.size.height-180)).allowsHitTesting(false)
                }
                if let item=furnitureMenu {
                    Color.black.opacity(0.001).contentShape(Rectangle()).onTapGesture{furnitureMenu=nil}
                    let key=item.kind == .bed ? "침대" : item.kind == .sofa ? "소파" : item.kind == .desk ? "책상" : "액자"
                    let rect=furnitureRects[key] ?? CGRect(x:geometry.size.width/2,y:geometry.size.height/2,width:44,height:44)
                    HomePopup(title: item.kind == .bed ? (sleeper.map{"침대 · \($0.name.josa("이", "가")) \(travelingDollID == $0.id ? "이동 중" : "자는 중")"} ?? "침대") : key) {
                        if item.kind == .bed {
                            furnitureMenuRow(sleeper == nil ? "재우기" : "깨우기",icon:sleeper == nil ? "z" : "↑",selected:false) {
                                furnitureMenu=nil
                                if sleeper != nil { wakeSleeper() }
                                else if placedDolls.count == 1,let doll=placedDolls.first { putToBed(doll) }
                                else if placedDolls.isEmpty { interactionMessage="먼저 인형을 만들어 방에 놓아 주세요" }
                                else { furnitureChoice = .sleep }
                            }
                        } else if item.kind == .desk {
                            Button { furnitureMenu = nil; openFocus() } label: {
                                HomePopupLabel(title: "함께 집중하기") { Image(systemName: "book") }
                            }.buttonStyle(.plain)
                        } else if item.kind == .sofa {
                            sofaMenuRow("유튜브 같이 보기", selected: false) { beginCouch(resting: false, sofa: item) }
                            sofaMenuRow(couch.resting && couch.sofaID == item.id ? "일어나기" : "앉아서 쉬기", selected: false) { beginCouch(resting: true, sofa: item) }
                        } else {
                            NavigationLink { FurnitureCustomView(item:item) } label: {
                                HomePopupLabel(title: "사진 꾸미기", primary: false) { D1Icon(name: "paint") }
                            }.buttonStyle(.plain).accessibilityLabel("사진 넣기 · 크기 조절")
                                .simultaneousGesture(TapGesture().onEnded{furnitureMenu=nil})
                            Button {
                                furnitureMenu = nil
                                if dolls.isEmpty { interactionMessage = "먼저 함께 찍을 인형을 만들어 주세요" }
                                else { frameTarget = item; pendingFrameDoll = nil; furnitureChoice = .frame }
                            } label: {
                                HomePopupLabel(title: "사진 찍어 넣기") { Image("home_popup_camera") }
                            }.buttonStyle(.plain).accessibilityLabel("AR로 찍어 액자에 넣기")
                        }
                    }
                        .position(x: item.kind == .sofa ? min(max(rect.midX + 70, 122), geometry.size.width - 122) : min(max(rect.midX+70,120),geometry.size.width-120),
                                  y: item.kind == .sofa ? max(180, rect.minY + 13) : max(180,rect.minY-50))
                }
                if let message=interactionMessage {
                    HStack {
                        Text(message).pretendard(.medium,13)
                        Spacer()
                        if placedDolls.isEmpty { Button("만들기"){isCreating=true}.pretendard(.medium,13) }
                    }.padding(16).frame(height:56).d1Surface(radius:14).padding(.horizontal,22)
                        .position(x:geometry.size.width/2,y:geometry.size.height-130)
                }
                if showGuide && furnitureChoice == nil {
                    let guideFurniture = ["창문", "액자", "침대", "책상", "소파"]
                    Color.mib.text.primary.opacity(0.28).ignoresSafeArea()
                    VStack(spacing:6) {
                        Text("가구를 두 번 톡톡 눌러보세요").pretendard(.bold,17)
                        Text("인형이랑 함께 할 수 있는 게 생겨요").pretendard(.medium,13)
                    }.foregroundStyle(Color.mib.text.onPrimary).frame(maxWidth:.infinity).padding(.top,64)
                    ForEach(guideFurniture, id: \.self) { name in
                        if let rect=furnitureRects[name] {
                            RoundedRectangle(cornerRadius:22).stroke(Color.mib.line.selected,style:StrokeStyle(lineWidth:2,dash:[6,4]))
                                .frame(width:rect.width,height:rect.height).position(x:rect.midX,y:rect.midY)
                        }
                    }
                    ForEach(guideFurniture, id: \.self) { name in
                        if let rect=furnitureRects[name] {
                            VStack(alignment:.leading,spacing:4) {
                                Text(name);Text(name == "책상" ? "함께 집중하기 · 시간 설정" : name == "창문" ? "같이 바깥 구경하기" : name == "침대" ? "재우기 · 깨우기" : name == "소파" ? "유튜브 같이 보기 · 앉아서 쉬기" : "AR 카메라 · 사진 넣기 · 크기 조절")
                            }.pretendard(.medium,13).padding(8).d1Surface(radius:10)
                                .position(x:min(max(rect.midX,110),geometry.size.width-110),y:min(name == "소파" ? rect.midY : rect.maxY-30,geometry.size.height-180))
                        }
                    }
                }
            }
        }.ignoresSafeArea()
    }
    private func furnitureMenuRow(_ title:String,icon:String,selected:Bool,action:@escaping()->Void)->some View {
        Button(action:action) {
            HomePopupLabel(title: title, primary: selected) { Text(icon) }
        }.buttonStyle(.plain)
    }
}

extension HomeView {
    private func dismissDollPopup() {
        dollMenu = nil
        dancingDoll = nil
    }

    private func openDollMenu(_ id: UUID) {
        guard placementStart == nil, hold == nil, !showGuide, appState.roomEntrance.finished,
              let doll = placedDolls.first(where: { $0.id == id }) else { return }
        furnitureMenu = nil
        appState.roomToolsOpen = false
        showFurnitureHint = false
        dancingDoll = nil
        dollPopupAnchor = roomPlacement.screenRect(of: id) ?? .zero
        dollMenu = doll
    }

    private func takeDollPhoto(_ doll: Doll) {
        dismissDollPopup()
        appState.isShowingAR = true
        Task {
            // Release the home renderer before presenting the AR camera.
            await Task.yield()
            dollARDoll = doll
        }
    }

    private func startHomeDance(_ doll: Doll) {
        guard doll.restingBedID == nil, travelingDollID != doll.id else {
            dollMenu = nil
            interactionMessage = "침대에서 인형을 깨운 뒤 함께 춤춰요"
            return
        }
        if couch.dolls.contains(where: { $0.id == doll.id }) { couch.stop() }
        dollMenu = nil
        homeDance = nil
        dancingDoll = doll
    }

    private var dollOverlays: some View {
        GeometryReader { geometry in
            if dollMenu != nil || dancingDoll != nil {
                let anchor = dollPopupAnchor.isEmpty
                    ? CGRect(x: geometry.size.width * 0.27, y: geometry.size.height * 0.64, width: 1, height: 1)
                    : dollPopupAnchor
                ZStack(alignment: .topLeading) {
                    Button(action: dismissDollPopup) { Color.clear.contentShape(Rectangle()) }
                        .buttonStyle(.plain).accessibilityLabel("인형 메뉴 닫기")
                    if let doll = dollMenu {
                        HomePopup(title: "인형") {
                            Button { takeDollPhoto(doll) } label: {
                                HomePopupLabel(title: "사진 찍기", primary: false) { Image("home_popup_camera") }
                            }.buttonStyle(.plain)
                            Button { startHomeDance(doll) } label: {
                                HomePopupLabel(title: "춤추기") { Image("home_popup_star") }
                            }.buttonStyle(.plain)
                        }.accessibilityIdentifier("home-doll-menu")
                            .accessibilityValue(doll.name)
                            .position(x: min(max(anchor.midX + 116, 128), max(128, geometry.size.width - 128)),
                                      y: min(max(anchor.minY - 68, geometry.safeAreaInsets.top + 100), max(175, geometry.size.height - 170)))
                    }
                }.accessibilityAction(.escape) { dismissDollPopup() }
            }
        }.ignoresSafeArea()
            .animation(.easeOut(duration: 0.22), value: dancingDoll?.id)
    }
}
