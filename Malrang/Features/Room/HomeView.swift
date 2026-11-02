import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Doll.createdAt) private var dolls: [Doll]
    @Query(sort: \RoomItem.createdAt) private var items: [RoomItem]
    @State private var selectedDoll: Doll?
    @State private var isCreating = false
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
    @State private var feelCount = 0
    @State private var hold: RoomSceneView.Hold?
    @State private var toast: Toast?
    @State private var isSceneReady = false
    @State private var furnitureRects: [String: CGRect] = [:]
    @State private var furnitureMenu: RoomItem?
    @State private var travelingDollID: UUID?
    @State private var furnitureChoice: FurnitureChoice?
    @State private var windowSelection: [DollState] = []
    @State private var showingWindow = false
    @State private var showingSound = false
    @State private var frameARDoll: Doll?
    @State private var showGuide = false
    @State private var showFurnitureHint = true
    @State private var interactionMessage: String?
    @State private var interactionError: String?
    @AppStorage("didSeeFurnitureGuide") private var didSeeFurnitureGuide = false
    @AppStorage("usedFurnitureActions") private var usedFurnitureActions = ""
    private enum FurnitureChoice: String, Identifiable { case window, sleep; var id: String { rawValue } }
    private var sleeper: Doll? { placedDolls.first { $0.restingBedID != nil } }
    private var hintName: String? { ["창문", "침대", "액자"].first { !usedFurnitureActions.split(separator:",").contains(Substring($0)) } }


    private struct Toast: Equatable {
        let message: String
        let undo: [UUID: SIMD3<Float>]
        let addedID: UUID?
    }

    private var placedDolls: [Doll] { dolls.filter(\.isPlaced) }
    private var roomDolls: [DollState] {
        placedDolls.map { doll in
            var state = doll.state
            if let position = placementPositions[doll.id] { state.position = position }
            return state
        }
    }
    var body: some View {
        NavigationStack {
            homeContent
            .alert("변경사항을 저장하지 못했어요", isPresented: Binding(get: { interactionError != nil }, set: { if !$0 { interactionError = nil } })) {
                Button("확인", role: .cancel) { interactionError = nil }
            } message: { Text(interactionError ?? "다시 시도해 주세요.") }
            .task(id: showFurnitureHint && didSeeFurnitureGuide && !showGuide && isSceneReady) {
                guard showFurnitureHint, didSeeFurnitureGuide, !showGuide, isSceneReady else { return }
                do { try await Task.sleep(for: .seconds(6)) } catch { return }
                showFurnitureHint = false
            }
            .task(id: interactionMessage) {
                guard interactionMessage != nil else { return }
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                interactionMessage = nil
            }
            .task(id: items.map(\.state)) {
                if !isDecorating { relocateBlockedDolls() }
            }
            .task(id: isDecorating) {
                if !isDecorating { relocateBlockedDolls() }
            }
            .task(id: isSceneReady) {
                if isSceneReady && !placedDolls.isEmpty && !didSeeFurnitureGuide { showGuide = true }
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--design-preview=home-ui"), isSceneReady {
                    if ProcessInfo.processInfo.arguments.contains("--furniture-preview=sleep"), sleeper == nil, let doll = placedDolls.first { showGuide = false; putToBed(doll) }
                    else if ProcessInfo.processInfo.arguments.contains("--furniture-preview=window") { showGuide=false;windowSelection=placedDolls.map(\.state);showingWindow=true }
                    else if ProcessInfo.processInfo.arguments.contains("--furniture-preview=sound") { showGuide=false;showingSound=true }
                }
                #endif
            }
            .background(Color.a.pinkLight)
            .navigationTitle("내 방")
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .navigationDestination(isPresented: $isDecorating) {
                DecorateView()
            }
            .alert("배치를 저장하지 못했어요", isPresented: $isPlacementSaveFailed) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("배치한 위치는 유지돼요. 잠시 후 다시 완료를 눌러 주세요.")
            }
            .sheet(item: $selectedDoll) { doll in
                DollActionSheet(doll: doll)
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
                try? await Task.sleep(for: .seconds(3))
                toast = nil
            }
            .sensoryFeedback(.success, trigger: toast?.message)
            .sensoryFeedback(trigger: feelCount) { _, _ in hapticOn ? .impact(weight: .heavy) : nil }
        }
    }

    private var homeContent: some View {
        // 3D 화면은 상단바·탭바가 사라져도 크기가 변하지 않게 화면 전체에 깐다.
        ZStack {
            Group {
                // 3D 화면 두 개를 동시에 그리면 위에 뜬 쪽이 그려지지 않아서, AR이나 다른 3D 화면을 쓰는 동안 방을 내린다.
                if appState.isShowingAR || isCreating || isFocusing || isDecorating || showingWindow || showingSound {
                    Color.app.background
                } else {
                    RoomSceneView(
                        items: items.map(\.state),
                        dolls: roomDolls,
                        mode: .home,
                        onTapDoll: { id in
                            if placementStart == nil, let doll = dolls.first(where: { $0.id == id }) {
                                if doll.restingBedID == nil { selectedDoll = doll }
                                else { furnitureMenu = items.first { $0.id == doll.restingBedID } }
                            }
                        },
                        canMoveDolls: placementStart != nil,
                        allowsDollWandering: selectedDoll == nil && !openingFocus && furnitureMenu == nil && !showGuide,
                        movingDollID: lastMovedID,
                        placement: roomPlacement,
                        onPickDoll: { lastMovedID = $0 },
                        onHoldDoll: { hold = $0 },
                        onMoveDoll: moveDoll,
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
                            if let doll = placedDolls.first(where: { $0.id == id }) { interactionMessage = "\(doll.name)가 잠들었어요" }
                        },
                        onSceneReady: { isSceneReady = true },
                        onDeskScreen: { deskPoint = $0 },
                        onFurnitureScreen: { furnitureRects = $0 }
                    )
                    .renderedOnlyWhileVisible(background: .clear)
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
            .overlay { holdTooltip }
            .ignoresSafeArea()
        }
        .overlay(alignment: .top) { topOverlay.accessibilityHidden(showGuide) }
        .overlay {
            if !isSceneReady, !appState.isShowingAR {
                VStack(spacing: Spacing.s) {
                    ProgressView().tint(Color.a.brown)
                    Text("포근한 방을 준비하고 있어요").appFont(.footnote)
                }
                .foregroundStyle(Color.a.brown)
                .padding(Spacing.l)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.card))
                .overlay(RoundedRectangle(cornerRadius: Radius.card).strokeBorder(CozyHomeStyle.glassHighlight))
            }
        }
        .overlay(alignment: .topTrailing) {
            if placementStart == nil { roomActions.accessibilityHidden(showGuide) }
        }
        .safeAreaInset(edge: .bottom) { bottomBar.accessibilityHidden(showGuide) }
        .overlay { furnitureOverlays }
        .sheet(item: $furnitureChoice, onDismiss: {
            if !windowSelection.isEmpty { showingWindow = true }
        }) { choice in
            DollChoiceSheet(dolls: choice == .window ? placedDolls.filter { $0.restingBedID == nil } : placedDolls, multiple: choice == .window) { chosen in
                if choice == .window { windowSelection = chosen.map(\.state) }
                else if let doll = chosen.first { putToBed(doll) }
            }
        }
        .fullScreenCover(isPresented: $showingWindow, onDismiss: { windowSelection = [] }) {
            WindowCompanionView(dolls: windowSelection)
        }
        .fullScreenCover(item: $frameARDoll) { doll in ARCaptureView(doll: doll) }
        .fullScreenCover(isPresented: $showingSound) {
            AmbientSoundView(dolls: soundCompanions)
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
                    interactionMessage = "인형을 놓을 빈자리가 없어 솜뭉치 목록에 보관했어요"
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
            if placementStart == nil { headerA }
            topMessage
        }
    }

    private var headerA: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) { D1Icon(name: "home"); Text("my room").notCliche(34, relativeTo: .largeTitle).tracking(-1.36) }
                    .padding(.horizontal, 16).frame(height: 60).d1ImageSurface()
                AmbientMiniPlayer { showingSound = true }
            }
            Spacer(minLength: 12)

        }.padding(.horizontal, 22).padding(.top, 8)
    }

    private var roomActions: some View {
        VStack(spacing: 12) {
            D1IconButton(icon: "doll", label: "인형 만들기") { isCreating = true }
            D1IconButton(icon: "bed", label: "방 꾸미기") { isDecorating = true }
        }.padding(.trailing, 22).padding(.top, 96)
    }

    @ViewBuilder
    private var topMessage: some View {
        if placementStart != nil {
            HintCapsule(text: "인형을 끌거나 놓을 자리를 눌러요")
                .padding(.top, Spacing.xs)
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
        if let hold {
            let seat = RoomLayout.seat(at: [hold.position.x, hold.position.z], in: items.map(\.state)).item
            HintCapsule(text: "옮기는 중 · \(seat?.kind.label ?? "바닥")")
                .fixedSize()
                .position(x: hold.screen.x, y: hold.screen.y)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if placementStart != nil {
            CancelConfirmButtons(onCancel: cancelPlacement, onConfirm: finishPlacement)
                .padding(Spacing.m)
        } else {
            bottomBarA
        }
    }

    private var bottomBarA: some View {
        D1HomeTabs(selection: Binding(get: { appState.tab }, set: { appState.tab = $0 }))
    }

    private func beginPlacement() {
        guard placementStart == nil else { return }
        toast = nil
        placementStart = Dictionary(uniqueKeysWithValues: placedDolls.map { ($0.id, $0.position) })
        placementPositions = placementStart ?? [:]
    }

    private func moveDoll(_ id: UUID, to position: SIMD3<Float>) {
        guard placementStart != nil else { return }
        placementPositions[id] = position
        lastMovedID = id
    }

    private func finishPlacement() {
        guard let start = placementStart else { return }
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
        lastMovedID = nil
        try? modelContext.save()
    }

    private func undo(_ toast: Toast) {
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
        showFurnitureHint = false
        switch item.kind {
        case .wall:
            markUsed("창문")
            guard !placedDolls.isEmpty else { interactionMessage="먼저 솜뭉치를 만들어 방에 놓아 주세요";return }
            let awake = placedDolls.filter { $0.restingBedID == nil }
            guard !awake.isEmpty else { interactionMessage="침대에서 솜뭉치를 깨운 뒤 같이 구경해요";return }
            if awake.count == 1 { windowSelection=awake.map(\.state);showingWindow=true }
            else { furnitureChoice = .window }
        case .bed: furnitureMenu=item;markUsed("침대")
        case .frame: furnitureMenu=item;markUsed("액자")
        case .desk: openFocus()
        default: break
        }
    }
    private func putToBed(_ doll: Doll) {
        guard sleeper == nil, let bed=items.first(where:{$0.kind == .bed}) else { return }
        let start = roomPlacement.currentPosition(of: doll.id) ?? doll.position
        guard DollBedRoute.plan(from: start, bed: bed.state, items: items.map(\.state)) != nil else {
            interactionMessage = "침대까지 갈 길이 없어요. 주변 가구를 조금 옮겨 주세요"; return
        }
        let previous=(doll.restingBedID,doll.position,doll.danceRaw)
        doll.restingBedID=bed.id;doll.position=DollRestPose.bedPosition(bed.state);doll.danceRaw=nil
        do { try modelContext.save();travelingDollID=doll.id;interactionMessage="\(doll.name)가 침대로 걸어가요" }
        catch { doll.restingBedID=previous.0;doll.position=previous.1;doll.danceRaw=previous.2;interactionError="재우기를 저장하지 못했어요. 다시 시도해 주세요." }
    }
    private func wakeSleeper() {
        guard let doll=sleeper else { return }
        guard let spot = RoomLayout.dollSpot(avoiding: items.map(\.state), dolls: placedDolls.filter { $0.id != doll.id }.map(\.position)) else {
            interactionMessage = "일어설 빈자리가 없어요. 가구나 인형을 옮겨 주세요"; return
        }
        travelingDollID = nil
        let bed=doll.restingBedID, oldPosition=doll.position
        doll.restingBedID=nil;doll.position=spot
        do { try modelContext.save();interactionMessage="\(doll.name)가 일어났어요" }
        catch { doll.restingBedID=bed;doll.position=oldPosition;interactionError="깨우기를 저장하지 못했어요. 다시 시도해 주세요." }
    }
    private var furnitureOverlays: some View {
        GeometryReader { geometry in
            ZStack(alignment:.topLeading) {
                if sleeper != nil, travelingDollID == nil, let rect=furnitureRects["침대"] {
                    Text("z z Z").pretendard(.bold,17).foregroundStyle(Color.mib.text.primary)
                        .position(x:rect.midX-24,y:rect.minY-16).allowsHitTesting(false)
                }
                if showFurnitureHint, !showGuide, furnitureMenu == nil, let name=hintName, didSeeFurnitureGuide, !placedDolls.isEmpty, let rect=furnitureRects[name] {
                    RoundedRectangle(cornerRadius:22).stroke(Color.mib.line.selected,style:StrokeStyle(lineWidth:2,dash:[6,4]))
                        .frame(width:rect.width,height:rect.height).position(x:rect.midX,y:rect.midY).allowsHitTesting(false)
                    D1Bubble(text:name == "창문" ? "창문 두 번 톡톡! 같이 구름 보자" : name == "침대" ? "침대 톡톡! 소리 틀어줄까, 재워줄래?" : "액자 톡톡 하면 같이 사진 찍을 수 있어")
                        .frame(width:242).position(x:min(max(rect.midX,130),geometry.size.width-130),y:min(rect.maxY+24,geometry.size.height-180)).allowsHitTesting(false)
                }
                if let item=furnitureMenu {
                    Color.black.opacity(0.001).contentShape(Rectangle()).onTapGesture{furnitureMenu=nil}
                    let key=item.kind == .bed ? "침대" : "액자"
                    let rect=furnitureRects[key] ?? CGRect(x:geometry.size.width/2,y:geometry.size.height/2,width:44,height:44)
                    VStack(alignment:.leading,spacing:8) {
                        Text(item.kind == .bed ? (sleeper.map{"침대 · \($0.name)가 \(travelingDollID == $0.id ? "이동 중" : "자는 중")"} ?? "침대") : "액자").pretendard(.medium,13)
                        if item.kind == .bed {
                            furnitureMenuRow("ASMR 틀기",icon:"♪",selected:false) { furnitureMenu=nil;showingSound=true }
                            furnitureMenuRow(sleeper == nil ? "재우기" : "깨우기",icon:sleeper == nil ? "z" : "↑",selected:true) {
                                furnitureMenu=nil
                                if sleeper != nil { wakeSleeper() }
                                else if placedDolls.count == 1,let doll=placedDolls.first { putToBed(doll) }
                                else if placedDolls.isEmpty { interactionMessage="먼저 솜뭉치를 만들어 방에 놓아 주세요" }
                                else { furnitureChoice = .sleep }
                            }
                        } else {
                            NavigationLink { FurnitureCustomView(item:item) } label: { Text("사진 넣기 · 크기 조절").pretendard(.regular,16).frame(minHeight:44) }.simultaneousGesture(TapGesture().onEnded{furnitureMenu=nil})
                            if let doll=placedDolls.first {
                                Button("AR 카메라") { furnitureMenu=nil;appState.isShowingAR=true;frameARDoll=doll }.pretendard(.regular,16).frame(minHeight:44)
                            }
                        }
                    }.padding(12).d1Surface(radius:22).frame(width:220)
                        .position(x:min(max(rect.midX+70,120),geometry.size.width-120),y:max(180,rect.minY-50))
                }
                if let message=interactionMessage {
                    HStack {
                        Text(message).pretendard(.medium,13)
                        Spacer()
                        if sleeper != nil { Button("소리 틀어줄까? →"){showingSound=true}.pretendard(.medium,13) }
                        else if placedDolls.isEmpty { Button("만들기"){isCreating=true}.pretendard(.medium,13) }
                    }.padding(16).frame(height:56).d1Surface(radius:14).padding(.horizontal,22)
                        .position(x:geometry.size.width/2,y:geometry.size.height-130)
                }
                if showGuide {
                    Color.mib.text.primary.opacity(0.28).ignoresSafeArea()
                    VStack(spacing:6) {
                        Text("가구를 두 번 톡톡 눌러보세요").pretendard(.bold,17)
                        Text("솜뭉치랑 함께 할 수 있는 게 생겨요").pretendard(.medium,13)
                    }.foregroundStyle(Color.mib.text.onPrimary).frame(maxWidth:.infinity).padding(.top,64)
                    ForEach(["창문","액자","침대"],id:\.self) { name in
                        if let rect=furnitureRects[name] {
                            RoundedRectangle(cornerRadius:22).stroke(Color.mib.line.selected,style:StrokeStyle(lineWidth:2,dash:[6,4]))
                                .frame(width:rect.width,height:rect.height).position(x:rect.midX,y:rect.midY)
                            VStack(alignment:.leading,spacing:4) {
                                Text(name);Text(name == "창문" ? "같이 바깥 구경하기" : name == "침대" ? "소리 틀기 · 재우기 · 깨우기" : "AR 카메라 · 사진 넣기 · 크기 조절")
                            }.pretendard(.medium,13).padding(8).d1Surface(radius:10)
                                .position(x:min(max(rect.midX,110),geometry.size.width-110),y:min(rect.maxY-30,geometry.size.height-180))
                        }
                    }
                    VStack { Spacer();Button("확인했어요") { showFurnitureHint=false;didSeeFurnitureGuide=true;showGuide=false }.buttonStyle(D1PrimaryStyle()).padding(.horizontal,22).padding(.bottom,32) }
                }
            }
        }.ignoresSafeArea()
    }
    private func furnitureMenuRow(_ title:String,icon:String,selected:Bool,action:@escaping()->Void)->some View {
        Button(action:action) {
            HStack(spacing:12){Text(icon).frame(width:28,height:28);Text(title);Spacer()}
                .pretendard(.regular,16).padding(.horizontal,8).frame(height:44)
                .background(selected ? Color.mib.bg.mintSoft : Color.mib.bg.screen,in:RoundedRectangle(cornerRadius:10))
        }.buttonStyle(.plain)
    }
}
