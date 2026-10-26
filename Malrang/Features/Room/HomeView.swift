import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(MultiRoom.self) private var multiRoom
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
    @State private var isShowingGuestbook = false
    @State private var isStartingMultiRoom = false
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
            // 3D 화면은 상단바·탭바가 사라져도 크기가 변하지 않게 화면 전체에 깐다.
            ZStack {
                Group {
                    // 3D 화면 두 개를 동시에 그리면 위에 뜬 쪽이 그려지지 않아서, AR이나 멀티 룸을 쓰는 동안 방을 내린다.
                    if appState.isShowingAR || multiRoom.session != nil || isCreating || isFocusing || isDecorating {
                        Color.app.background
                    } else {
                        RoomSceneView(
                            items: items.map(\.state),
                            dolls: roomDolls,
                            mode: .home,
                            onTapDoll: { id in
                                if placementStart == nil { selectedDoll = dolls.first { $0.id == id } }
                            },
                            canMoveDolls: placementStart != nil,
                            movingDollID: lastMovedID,
                            placement: roomPlacement,
                            onPickDoll: { lastMovedID = $0 },
                            onHoldDoll: { hold = $0 },
                            onMoveDoll: moveDoll,
                            onTapBoard: { if placementStart == nil { isShowingGuestbook = true } },
                            onTapItem: { id in
                                guard placementStart == nil,
                                      let id, items.first(where: { $0.id == id })?.kind == .desk else { return }
                                openFocus()
                            },
                            onFeel: { feelCount += 1 },
                            isTransparent: true,
                            illustrationTargetY: 0.84,
                            isCozyRoom: true,
                            onSceneReady: { isSceneReady = true },
                            onDeskScreen: { deskPoint = $0 }
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
                .overlay {
                    if placementStart == nil, !isFocusing, let deskPoint {
                        Button(action: openFocus) {
                            Circle().strokeBorder(.white, style: StrokeStyle(lineWidth: 2, dash: [7, 6]))
                                .frame(width: 88, height: 88).contentShape(Circle())
                        }.buttonStyle(.plain).position(deskPoint)
                            .accessibilityLabel("책상에서 함께 집중하기")
                            .accessibilityHint("함께 집중할 솜뭉치를 선택해요")
                    }
                }
                .ignoresSafeArea()
            }
            .overlay(alignment: .top) { topOverlay }
            .overlay {
                if !isSceneReady, !appState.isShowingAR, multiRoom.session == nil {
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
                if placementStart == nil { roomActions }
            }
            .safeAreaInset(edge: .bottom) { bottomBar }
            .background(Color.a.pinkLight)
            .navigationTitle("내 방")
            .toolbar { toolbar }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .navigationDestination(isPresented: $isDecorating) {
                DecorateView()
            }
            .navigationDestination(isPresented: $isShowingGuestbook) {
                GuestbookView(ownerID: "me", title: "내 방명록", canWrite: false)
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
            .sheet(isPresented: $isStartingMultiRoom) {
                MultiRoomStartSheet()
            }
            .fullScreenCover(isPresented: $isCreating, onDismiss: {
                if let doll = pendingDoll {
                    pendingDoll = nil
                    place(doll)
                }
            }) {
                CreateFlowView { doll in pendingDoll = doll }
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

    private func openFocus() {
        guard !openingFocus, !isFocusing else { return }
        openingFocus = true
        roomPlacement.captureImage { image in
            focusBackground = image
            openingFocus = false
            isFocusing = true
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            NotificationsButton()
        }
    }

    private var topOverlay: some View {
        VStack(spacing: Spacing.s) {
            if placementStart == nil { headerA }
            topMessage
        }
    }

    private var headerA: some View {
        HStack(spacing: 0) {
            Image("cozy_roof").renderingMode(.template).foregroundStyle(.white)
                .accessibilityHidden(true)
            Text("my room")
                .notCliche(CozyHomeStyle.titleSize, relativeTo: .largeTitle)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .tracking(CozyHomeStyle.titleTracking)
                .foregroundStyle(.white)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.s)
            NavigationLink {
                NotificationsView()
            } label: {
                Image("cozy_bell")
                    .frame(width: CozyHomeStyle.button, height: CozyHomeStyle.button)
            }
            .accessibilityLabel("알림함")
        }
        .frame(height: CozyHomeStyle.headerHeight)
        .padding(.horizontal, CozyHomeStyle.headerInset)
        .padding(.top, Spacing.xxs)
    }

    private var roomActions: some View {
        VStack(spacing: Spacing.xs) {
            CozyHomeAction(asset: "cozy_create", label: "인형 만들기") { isCreating = true }
                .accessibilityHint(dolls.isEmpty ? "첫 솜뭉치를 만들어 방에 놓아 보세요" : "사진으로 새 인형을 만들어요")
            CozyHomeAction(asset: "cozy_decorate", label: "방 꾸미기") { isDecorating = true }
            CozyHomeAction(asset: "cozy_guestbook", label: "방명록") { isShowingGuestbook = true }

        }
        .padding(.trailing, CozyHomeStyle.headerInset)
        .padding(.top, CozyHomeStyle.headerHeight + Spacing.xl + Spacing.s)
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
        CozyHomeTabs(selection: Binding(get: { appState.tab }, set: { appState.tab = $0 }))
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
        beginPlacement()
        if !doll.isPlaced {
            placementAddedID = doll.id
            doll.position = RoomLayout.dollSpot(avoiding: items.map(\.state), dolls: placedDolls.map(\.position))
            doll.isPlaced = true
        }
        placementPositions[doll.id] = doll.position
        lastMovedID = doll.id
    }
}

#Preview("인형 있음") {
    HomeView()
        .environment(AppState())
        .environment(FriendStore(api: MockFriendAPI()))
        .environment(MultiRoom())
        .modelContainer(.preview)
}

#Preview("빈 방") {
    HomeView()
        .environment(AppState())
        .environment(FriendStore(api: MockFriendAPI()))
        .environment(MultiRoom())
        .modelContainer(for: [Doll.self, RoomItem.self], inMemory: true)
}
