import SwiftUI

/// 연락처로 친구를 찾아 요청을 보내고, 문자·카카오톡으로 초대한다.
struct AddFriendSheet: View {
    @Environment(FriendStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("friendCode") private var friendCode = ""
    @State private var contactPhase = ContactPhase.idle
    @State private var requested: Set<String> = []

    enum ContactPhase {
        case idle, loading, denied, failed, loaded([Friend])
    }

    var body: some View {
        NavigationStack {
            contactList
            .background(Color.app.background)
            .safeAreaInset(edge: .bottom) { invite }
            .navigationTitle("친구 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("닫기", systemImage: "xmark") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private var contactList: some View {
        switch contactPhase {
        case .idle:
            NoticeCard(symbol: "person.crop.rectangle.stack", title: "연락처로 친구를 찾아요",
                       message: "연락처 속 전화번호는 해시로 바꿔서 비교해요. 번호 원문은 보내지 않아요",
                       actionTitle: "연락처 불러오기") { Task { await loadContacts() } }
                .frame(maxHeight: .infinity)
        case .loading:
            ProgressView("연락처를 살펴보는 중이에요")
                .frame(maxHeight: .infinity)
        case .denied:
            NoticeCard(symbol: "lock", title: "연락처 접근이 꺼져 있어요",
                       message: "설정에서 연락처를 허용하면 친구를 찾을 수 있어요", actionTitle: "설정 열기") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            .frame(maxHeight: .infinity)
        case .failed:
            NoticeCard(symbol: "wifi.exclamationmark", title: "친구를 찾지 못했어요",
                       message: "잠시 뒤 다시 시도해 주세요", actionTitle: "다시 불러오기") { Task { await loadContacts() } }
                .frame(maxHeight: .infinity)
        case .loaded(let friends):
            if friends.isEmpty {
                NoticeCard(symbol: "person.2", title: "아직 가입한 친구가 없어요",
                           message: "아래 버튼으로 친구를 초대해 보세요")
                    .frame(maxHeight: .infinity)
            } else {
                List(friends, rowContent: row)
                    .font(.body)
                    .scrollContentBackground(.hidden)
            }
        }
    }

    private var invite: some View {
        ShareLink(item: "Fluff에서 내 방에 놀러 와요! 친구 코드: \(friendCode)") {
            Label("문자·카카오톡으로 초대하기", systemImage: "paperplane")
        }
        .buttonStyle(.primary)
        .padding(Spacing.m)
        .background(Color.app.background)
    }

    private func row(_ friend: Friend) -> some View {
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
        .frame(minHeight: 44)
    }

    private func loadContacts() async {
        contactPhase = .loading
        guard await ContactsService.requestAccess() else {
            contactPhase = .denied
            return
        }
        do {
            contactPhase = .loaded(try await store.api.friends(matching: await ContactsService.phoneHashes()))
        } catch {
            contactPhase = .failed
        }
    }
}

#Preview {
    AddFriendSheet()
        .environment(FriendStore(api: MockFriendAPI()))
}
