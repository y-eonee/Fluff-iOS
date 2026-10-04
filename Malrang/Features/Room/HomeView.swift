import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(FriendStore.self) private var friendStore
    @Environment(MultiRoom.self) private var multiRoom
    @Query(sort: \Doll.createdAt) private var dolls: [Doll]
    @Query(sort: \RoomItem.createdAt) private var items: [RoomItem]
    @State private var selectedDoll: Doll?
    @State private var isCreating = false
    @State private var isStartingMultiRoom = false
    /// 배치 모드일 때 시작 위치. 취소하면 여기로 되돌린다. nil이면 배치 모드가 아니다.
    @State private var placementStart: [UUID: SIMD3<Float>]?
    @State private var lastMovedID: UUID?
    @State private var toast: Toast?

    private struct Toast: Equatable {
        let message: String
        let undo: [UUID: SIMD3<Float>]
    }

    private var placedDolls: [Doll] { dolls.filter(\.isPlaced) }

    var body: some View {
        NavigationStack {
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
                        onPickDoll: { _ in beginPlacement() },
                        onMoveDoll: { id, position in
                            dolls.first { $0.id == id }?.position = position
                            lastMovedID = id
                        }
                    )
                }
            }
            .ignoresSafeArea(edges: .horizontal)
            .overlay(alignment: .top) { topMessage }
            .overlay { emptyState }
            .safeAreaInset(edge: .bottom) { bottomBar }
            .background(Color.app.background)
            .navigationTitle("내 방")
            .toolbar { toolbar }
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
                DecorateView()
            } label: {
                Label("꾸미기", systemImage: "paintbrush")
            }
            NavigationLink {
                GuestbookView(ownerID: "me", title: "내 방명록", canWrite: false)
            } label: {
                Label("방명록", systemImage: "book")
            }
            NavigationLink {
                NotificationsView()
            } label: {
                Label("알림함", systemImage: friendStore.hasUnreadNotifications ? "bell.badge" : "bell")
                    .symbolRenderingMode(.multicolor)
            }
        }
    }

    @ViewBuilder
    private var topMessage: some View {
        if placementStart != nil {
            Text("원하는 위치로 끌어다 놓으세요")
                .font(.footnote.bold())
                .foregroundStyle(Color.app.surface)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.xs)
                .background(Color.app.ink, in: Capsule())
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
            Text("인형을 길게 눌러 위치 옮기기")
                .font(.footnote)
                .foregroundStyle(Color.app.inkSecondary)
                .padding(.top, Spacing.xs)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if dolls.isEmpty {
            NoticeCard(symbol: "teddybear", title: "아직 방이 비어 있어요",
                       message: "갤러리 속 사진으로 첫 인형을 만들어 방에 놓아 보세요",
                       actionTitle: "첫 인형 만들러 가기") { isCreating = true }
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if placementStart != nil {
            HStack(spacing: Spacing.s) {
                Button("취소", action: cancelPlacement)
                    .buttonStyle(.secondary)
                Button("완료", action: finishPlacement)
                    .buttonStyle(.primary)
            }
            .padding(Spacing.m)
        } else if !dolls.isEmpty {
            Button {
                isCreating = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(Color.app.ink)
                    .frame(width: 56, height: 56)
                    .background(Color.app.accent, in: Circle())
            }
            .accessibilityLabel("인형 만들기")
            .padding(.bottom, Spacing.m)
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
            doll.position = RoomLayout.dollSpot(index: placedDolls.count)
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
