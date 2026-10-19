import SwiftData
import SwiftUI

struct DollListView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Doll.createdAt, order: .reverse) private var dolls: [Doll]
    @State private var selectedDoll: Doll?
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.s), GridItem(.flexible())], spacing: Spacing.s) {
                    ForEach(dolls) { doll in
                        Button {
                            selectedDoll = doll
                        } label: {
                            card(doll)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.m)
            }
            .overlay {
                if dolls.isEmpty {
                    NoticeCard(symbol: "teddybear", title: "아직 인형이 없어요",
                               message: "아래 + 버튼으로 갤러리 속 사진을 인형으로 만들어 보세요")
                }
            }
            .overlay(alignment: .bottomTrailing) {
                FloatingCircleButton(title: "인형 만들기", symbol: "teddybear", isPrimary: true) { isCreating = true }
                    .padding(Spacing.m)
            }
            .background { AppBackground() }
            .navigationTitle("인형 목록")
            .notebookTabBar()
            .toolbar { NotificationsButton() }
            .sheet(item: $selectedDoll) { doll in
                DollActionSheet(doll: doll)
            }
            .fullScreenCover(isPresented: $isCreating) {
                CreateFlowView { doll in appState.place(doll) }
            }
        }
    }

    private func card(_ doll: Doll) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(uiImage: doll.image)
                .resizable()
                .scaledToFit()
                .frame(height: 140)
            Text(doll.name)
                .appFont(.headline)
        }
        .foregroundStyle(Color.app.ink)
        .frame(maxWidth: .infinity)
        .padding(Spacing.s)
        .cardStyle()
        .overlay(alignment: .topTrailing) {
            Image(systemName: doll.isPlaced ? "house.fill" : "house")
                .appFont(.body)
                .foregroundStyle(Color.app.ink)
                .frame(width: 36, height: 36)
                .background(doll.isPlaced ? Color.app.pastelMint : Color.app.background, in: Circle())
                .overlay(Circle().stroke(Color.app.ink.opacity(doll.isPlaced ? 0.5 : 0.15)))
                .padding(Spacing.xs)
                .accessibilityLabel(doll.isPlaced ? "방에 있어요" : "보관 중")
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    DollListView()
        .environment(AppState())
        .environment(FriendStore(api: MockFriendAPI()))
        .modelContainer(.preview)
}
