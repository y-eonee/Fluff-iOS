import SwiftUI

/// 방명록. 새 글은 목록 맨 위에 붙고, 방 주인에게 알림이 간다(서버 연결 뒤).
struct GuestbookView: View {
    let ownerID: String
    let title: String
    let canWrite: Bool
    @Environment(FriendStore.self) private var store
    @State private var entries: [GuestbookEntry]?
    @State private var didFail = false
    @State private var draft = ""
    @State private var postCount = 0

    var body: some View {
        List {
            if didFail {
                Text("방명록을 불러오지 못했어요")
            } else if let entries, entries.isEmpty {
                Text(canWrite ? "첫 방명록을 남겨 보세요" : "아직 방명록이 없어요")
                    .foregroundStyle(Color.app.inkSecondary)
            } else if let entries {
                ForEach(entries) { entry in
                    Text("\(Text(entry.author).bold())  \(entry.message)")
                        .padding(.vertical, Spacing.xxs)
                }
            } else {
                ProgressView()
            }
        }
        .font(.body)
        .foregroundStyle(Color.app.ink)
        .scrollContentBackground(.hidden)
        .background(Color.app.background)
        .safeAreaInset(edge: .bottom) {
            if canWrite { composer }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: postCount)
        .task {
            do {
                entries = try await store.api.guestbook(of: ownerID)
            } catch {
                didFail = true
            }
        }
    }

    private var composer: some View {
        HStack(spacing: Spacing.xs) {
            TextField("방명록을 남겨 보세요", text: $draft)
                .padding(.horizontal, Spacing.s)
                .frame(minHeight: 44)
                .background(Color.app.surface, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
            Button("등록") {
                Task { await post() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(Spacing.m)
        .background(Color.app.background)
    }

    private func post() async {
        let message = draft.trimmingCharacters(in: .whitespaces)
        guard let entry = try? await store.api.writeGuestbook(message, to: ownerID) else { return }
        entries?.insert(entry, at: 0)
        draft = ""
        postCount += 1
    }
}

#Preview {
    NavigationStack {
        GuestbookView(ownerID: "me", title: "지윤의 방명록", canWrite: true)
    }
    .environment(FriendStore(api: MockFriendAPI()))
}
