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
    @State private var pendingDoll: Doll?
    @State private var isDecorating = false
    @State private var isShowingGuestbook = false
    @State private var isStartingMultiRoom = false
    /// 배치 모드일 때 시작 위치. 취소하면 여기로 되돌린다. nil이면 배치 모드가 아니다.
    @State private var placementStart: [UUID: SIMD3<Float>]?
    @State private var lastMovedID: UUID?
    @State private var placementAddedID: UUID?
    @AppStorage("hapticOn") private var hapticOn = true
    @AppStorage("designVariant") private var variant = DesignVariant.a
    @State private var feelCount = 0
    @State private var hold: RoomSceneView.Hold?
    @State private var toast: Toast?

    private struct Toast: Equatable {
        let message: String
        let undo: [UUID: SIMD3<Float>]
        let addedID: UUID?
    }

    private var placedDolls: [Doll] { dolls.filter(\.isPlaced) }
    private var isA: Bool { variant == .a }
    var body: some View {
        NavigationStack {
            // 3D 화면은 상단바·탭바가 사라져도 크기가 변하지 않게 화면 전체에 깐다.
            ZStack {
                Group {
                    // 3D 화면 두 개를 동시에 그리면 위에 뜬 쪽이 그려지지 않아서, AR이나 멀티 룸을 쓰는 동안 방을 내린다.
                    if appState.isShowingAR || multiRoom.session != nil {
                        Color.app.background
                    } else {
                        RoomSceneView(
                            items: items.map(\.state),
                            dolls: placedDolls.map(\.state),
                            mode: .home,
                            onTapDoll: { id in
                                if placementStart == nil { selectedDoll = dolls.first { $0.id == id } }
                            },
                            canMoveDolls: placementStart != nil,
                            movingDollID: lastMovedID,
                            onPickDoll: { lastMovedID = $0 },
                            onHoldDoll: { hold = $0 },
                            onMoveDoll: { id, position in
                                dolls.first { $0.id == id }?.position = position
                                lastMovedID = id
                            },
                            onTapBoard: { if placementStart == nil { isShowingGuestbook = true } },
                            onFeel: { feelCount += 1 },
                            isTransparent: true,
                            illustrationTargetY: isA ? 0.84 : 0.7
                        )
                        .renderedOnlyWhileVisible(background: .clear)
                    }
                }
                .overlay { holdTooltip }
                .ignoresSafeArea()
            }
            .overlay(alignment: .top) { topOverlay }
            .overlay { emptyState }
            .safeAreaInset(edge: .bottom) { bottomBar }
            .background { if isA { GridPaper() } else { BBackground(grid: true) } }
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
            .sheet(item: $selectedDoll) { doll in
                DollActionSheet(doll: doll)
            }
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

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            NotificationsButton()
        }
    }

    @ViewBuilder
    private var topOverlay: some View {
        if isA {
            ZStack(alignment: .top) {
                Image("a_awning")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .top)
                    .allowsHitTesting(false)
                if placementStart == nil { headerA }
                topMessage
                    .padding(.top, placementStart == nil ? Spacing.xl + Spacing.m : 0)
            }
        } else {
            VStack {
                if placementStart == nil {
                    HStack {
                        Text("my room").origin(32, relativeTo: .largeTitle).foregroundStyle(Color.b.brown)
                        Spacer()
                        NavigationLink { NotificationsView() } label: {
                            Image("b_screen0_img").resizable().frame(width: 44, height: 44)
                        }.accessibilityLabel("알림함")
                    }.padding(.horizontal, Spacing.l)
                }
                if placementStart != nil || toast != nil { topMessage }
            }.padding(.top, Spacing.xs)
        }
    }

    /// 시안 A 상단: 마스킹테이프 위에 놓인 집 아이콘과 my room 제목, 알림. 피그마 좌표(390pt 기준)를 화면 맨 위부터 그대로 쓴다.
    private var headerA: some View {
        ZStack(alignment: .topLeading) {
            Image("a_tape_mint")
                .rotationEffect(.degrees(-3.27))
                .offset(x: 71.78 + 0.5, y: 61.62 + 3.4)
            Image("a_tape_pink")
                .rotationEffect(.degrees(11))
                .offset(x: 150.9, y: 74)
            Image("a_roof")
                .offset(x: 22.2, y: 55.2)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.a.brown)
                .frame(width: 37.5, height: 19.9)
                .offset(x: 25.2, y: 67.3)
            Text("my room")
                .notCliche(34, relativeTo: .largeTitle)
                .tracking(-1.36)
                .foregroundStyle(Color.a.brown)
                .fixedSize()
                .offset(x: 74.6, y: 50)
            NavigationLink {
                NotificationsView()
            } label: {
                Image("a_bell")
                    .resizable()
                    .frame(width: 46, height: 46)
            }
            .accessibilityLabel("알림함")
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 22)
            .offset(y: 48)
        }
        .frame(maxWidth: .infinity, maxHeight: 110, alignment: .topLeading)
        .ignoresSafeArea()
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
        } else if !placedDolls.isEmpty {
            Text("인형을 눌러 만지고, 벽의 메모보드를 눌러 방명록을 봐요")
                .appFont(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
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
    private var emptyState: some View {
        if dolls.isEmpty {
            NoticeCard(symbol: "teddybear", title: "아직 방이 비어 있어요",
                       message: "아래 인형 만들기 버튼으로 갤러리 속 사진을 인형으로 만들어 보세요")
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if placementStart != nil {
            CancelConfirmButtons(onCancel: cancelPlacement, onConfirm: finishPlacement)
                .padding(Spacing.m)
        } else if isA {
            bottomBarA
        } else {
            bottomBarB
        }
    }

    private var bottomBarB: some View {
        VStack(spacing: Spacing.l) {
            VStack(spacing: Spacing.xs) {
                Button { isStartingMultiRoom = true } label: {
                    Image(systemName: "shareplay").frame(width: 44, height: 44).background(.white.opacity(0.8), in: Circle())
                }.accessibilityLabel("멀티 룸")
                Button { isDecorating = true } label: {
                    Image(systemName: "paintbrush").frame(width: 44, height: 44).background(.white.opacity(0.8), in: Circle())
                }.accessibilityLabel("방 꾸미기")
                Button { isCreating = true } label: {
                    Image("b_screen0_imgIcon").resizable().frame(width: 36, height: 36)
                        .frame(width: 76, height: 76)
                        .background(BStyle.orange, in: Circle())
                        .overlay(Image("b_screen0_imgEllipse2086").resizable().scaledToFit().blendMode(.softLight))
                        .overlay(Image("b_screen0_imgEllipse2087").resizable().scaledToFit().blendMode(.softLight))
                        .overlay(alignment: .topLeading) {
                            Image("b_screen0_imgEllipse2088").resizable().frame(width: 40, height: 40)
                        }
                        .clipShape(Circle())
                }.accessibilityLabel("인형 만들기")
            }
            .buttonStyle(BGlossButtonStyle(radius: 38))
            .foregroundStyle(Color.b.brown)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, Spacing.l)
            BTabBar(selection: Binding(get: { appState.tab }, set: { appState.tab = $0 }))
        }
    }

    /// 시안 A 하단: 동그란 버튼들과 수첩 탭바. 인형 만들기는 구름 모양 큰 버튼이다.
    private var bottomBarA: some View {
        VStack(spacing: Spacing.s) {
            VStack(spacing: Spacing.xs) {
                SketchCircleButton(symbol: "shareplay", label: "멀티 룸") { isStartingMultiRoom = true }
                SketchCircleButton(symbol: "paintbrush", label: "방 꾸미기") { isDecorating = true }
                Button {
                    isCreating = true
                } label: {
                    Image("a_fab")
                        .resizable()
                        .frame(width: 65, height: 65)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("인형 만들기")
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, Spacing.m)
            NotebookTabBar(selection: Binding(get: { appState.tab }, set: { appState.tab = $0 }))
        }
    }

    private func beginPlacement() {
        guard placementStart == nil else { return }
        toast = nil
        placementStart = Dictionary(uniqueKeysWithValues: placedDolls.map { ($0.id, $0.position) })
    }

    private func finishPlacement() {
        guard let start = placementStart else { return }
        placementStart = nil
        try? modelContext.save()
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
