import SwiftUI

/// 아이디로 친구를 찾아 요청을 보낸다.
struct AddFriendSheet: View {
    @Environment(FriendStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [Friend]?
    @State private var requested: Set<String> = []
    @State private var isSearching = false
    @State private var didFail = false

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    ProgressView()
                } else if didFail {
                    Text("찾지 못했어요. 잠시 뒤 다시 시도해 주세요")
                } else if let results, results.isEmpty {
                    Text("'\(query)' 아이디를 가진 친구가 없어요")
                } else if let results {
                    ForEach(results) { friend in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(friend.name).font(.headline)
                                Text("@\(friend.id)").font(.footnote).foregroundStyle(Color.app.inkSecondary)
                            }
                            Spacer()
                            Button(requested.contains(friend.id) ? "요청 보냄" : "요청 보내기") {
                                Task {
                                    try? await store.api.sendRequest(to: friend)
                                    requested.insert(friend.id)
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(requested.contains(friend.id))
                        }
                    }
                } else {
                    Text("친구 아이디를 입력해 주세요. 예: soyul")
                        .foregroundStyle(Color.app.inkSecondary)
                }
            }
            .font(.body)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "친구 아이디")
            .onSubmit(of: .search) {
                Task { await search() }
            }
            .navigationTitle("친구 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("닫기", systemImage: "xmark") { dismiss() }
            }
        }
    }

    private func search() async {
        isSearching = true
        didFail = false
        defer { isSearching = false }
        do {
            results = try await store.api.search(id: query)
        } catch {
            didFail = true
        }
    }
}

#Preview {
    AddFriendSheet()
        .environment(FriendStore(api: MockFriendAPI()))
}
