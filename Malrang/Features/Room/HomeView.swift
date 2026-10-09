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
    @State private var isMenuOpen = false
    @State private var isDecorating = false
    @State private var isShowingGuestbook = false
    @State private var isStartingMultiRoom = false
    /// 배치 모드일 때 시작 위치. 취소하면 여기로 되돌린다. nil이면 배치 모드가 아니다.
    @State private var placementStart: [UUID: SIMD3<Float>]?
    @State private var lastMovedID: UUID?
    @AppStorage("hapticOn") private var hapticOn = true
    @State private var feelCount = 0
    @State private var hold: RoomSceneView.Hold?
    @State private var toast: Toast?

    private struct Toast: Equatable {
        let message: String
        let undo: [UUID: SIMD3<Float>]
    }

    private var placedDolls: [Doll] { dolls.filter(\.isPlaced) }

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
                            onHoldDoll: { hold = $0 },
                            onMoveDoll: { id, position in
                                dolls.first { $0.id == id }?.position = position
                                lastMovedID = id
                            },
                            onTapBoard: { if placementStart == nil { isShowingGuestbook = true } },
                            onFeel: { feelCount += 1 }
                        )
                        .renderedOnlyWhileVisible()
                    }
                }
                .overlay { holdTooltip }
                .ignoresSafeArea()
            }
            .overlay(alignment: .top) { topMessage }
            .overlay { emptyState }
            .safeAreaInset(edge: .bottom) { bottomBar }
            .background(Color.app.background)
            .navigationTitle("내 방")
            .toolbar { toolbar }
            .toolbar(placementStart == nil ? .automatic : .hidden, for: .navigationBar)
            .toolbar(placementStart == nil ? .automatic : .hidden, for: .tabBar)
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
            .fullScreenCover(isPresented: $isCreating) {
                CreateFlowView { doll in place(doll) }
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
            Button {
                isStartingMultiRoom = true
            } label: {
                Label("멀티 룸", systemImage: "shareplay")
            }
            NavigationLink {
                MyPageView()
            } label: {
                Label("마이페이지", systemImage: "person.crop.circle")
            }
            NotificationsButton()
        }
    }

    @ViewBuilder
    private var topMessage: some View {
        if placementStart != nil {
            HintCapsule(text: "원하는 위치로 끌어다 놓으세요")
                .padding(.top, Spacing.xs)
        } else if let toast {
            HStack(spacing: Spacing.s) {
                Text(toast.message)
                Button("되돌리기") { undo(toast) }
                    .bold()
            }
            .font(.footnote)
            .foregroundStyle(Color.app.surface)
            .padding(.horizontal, Spacing.m)
            .frame(minHeight: 44)
            .background(Color.app.ink, in: Capsule())
            .padding(.top, Spacing.xs)
        } else if !placedDolls.isEmpty {
            Text("인형을 눌러 만지고, 벽의 메모보드를 눌러 방명록을 봐요")
                .font(.footnote)
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
                       message: "아래 + 버튼으로 갤러리 속 사진을 인형으로 만들어 보세요")
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if placementStart != nil {
            CancelConfirmButtons(onCancel: cancelPlacement, onConfirm: finishPlacement)
                .padding(Spacing.m)
        } else {
            VStack(alignment: .trailing, spacing: Spacing.s) {
                if isMenuOpen {
                    menuButton("인형 만들기", symbol: "teddybear") { isCreating = true }
                    menuButton("방 꾸미기", symbol: "paintbrush") { isDecorating = true }
                }
                FloatingAddButton(label: "메뉴 열기", isOpen: isMenuOpen) { isMenuOpen.toggle() }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(Spacing.m)
            .animation(.spring, value: isMenuOpen)
        }
    }

    private func menuButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            isMenuOpen = false
            action()
        } label: {
            Label(title, systemImage: symbol)
                .padding(.horizontal, Spacing.m)
        }
        .buttonStyle(.secondary)
        .fixedSize()
        .transition(.scale(scale: 0.8, anchor: .bottomTrailing).combined(with: .opacity))
    }

    private func beginPlacement() {
        guard placementStart == nil else { return }
        toast = nil
        placementStart = Dictionary(uniqueKeysWithValues: placedDolls.map { ($0.id, $0.position) })
    }

    private func finishPlacement() {
        guard let start = placementStart else { return }
        placementStart = nil
        guard let moved = dolls.first(where: { $0.id == lastMovedID }) else { return }
        let seat = RoomLayout.seat(at: [moved.position.x, moved.position.z], in: items.map(\.state)).item
        toast = Toast(message: "\(seat?.kind.label ?? "바닥")에 배치했어요", undo: start)
        lastMovedID = nil
    }

    private func cancelPlacement() {
        if let start = placementStart { restore(start) }
        placementStart = nil
        lastMovedID = nil
    }

    private func undo(_ toast: Toast) {
        restore(toast.undo)
        self.toast = nil
    }

    private func restore(_ positions: [UUID: SIMD3<Float>]) {
        for doll in placedDolls {
            if let position = positions[doll.id] { doll.position = position }
        }
    }

    /// 새로 만들었거나 목록에서 고른 인형을 앞쪽 바닥에 두고 배치 모드를 연다.
    private func place(_ doll: Doll) {
        if !doll.isPlaced {
            doll.position = RoomLayout.dollSpot(avoiding: items.map(\.state), dolls: placedDolls.map(\.position))
            doll.isPlaced = true
        }
        lastMovedID = doll.id
        beginPlacement()
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
