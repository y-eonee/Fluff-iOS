import SwiftUI

/// 방명록 메모보드. 새 글은 메모지로 붙고, 꾹 눌러 옮기거나 휴지통으로 끌어 지운다.
/// 내 보드는 모든 메모지를, 친구 보드는 내가 쓴 메모지만 옮기고 지울 수 있다.
struct GuestbookView: View {
    let ownerID: String
    let title: String
    let canWrite: Bool
    @Environment(FriendStore.self) private var store
    @State private var entries: [GuestbookEntry]?
    @State private var didFail = false
    @State private var draft = ""
    @State private var postCount = 0
    @State private var deleteCount = 0
    @State private var heldID: UUID?
    @State private var heldCenter = CGPoint.zero
    @State private var grabOffset: CGPoint?

    private let noteSize: CGFloat = 112
    private let trashSize: CGFloat = 64
    private let maxLength = 40

    var body: some View {
        VStack(spacing: Spacing.xs) {
            if entries?.contains(where: canEdit) == true {
                Text("메모지를 꾹 눌러 옮기고, 휴지통에 끌어다 놓으면 지워요")
                    .font(.footnote)
                    .foregroundStyle(Color.app.inkSecondary)
            }
            board
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.app.background)
        .safeAreaInset(edge: .bottom) {
            if canWrite { composer }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: postCount)
        .sensoryFeedback(.warning, trigger: deleteCount)
        .task { await load() }
    }

    @ViewBuilder
    private var board: some View {
        if didFail {
            NoticeCard(symbol: "wifi.exclamationmark", title: "방명록을 불러오지 못했어요",
                       message: "잠시 뒤 다시 시도해 주세요", actionTitle: "다시 불러오기") {
                Task { await load() }
            }
            .frame(maxHeight: .infinity)
        } else if let entries {
            GeometryReader { proxy in
                ZStack {
                    ForEach(entries) { entry in
                        note(entry, boardSize: proxy.size)
                    }
                    if heldID != nil {
                        trash(boardSize: proxy.size)
                    }
                    if entries.isEmpty {
                        Text(canWrite ? "첫 방명록을 남겨 보세요" : "아직 방명록이 없어요")
                            .font(.body)
                            .foregroundStyle(Color.app.inkSecondary)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .coordinateSpace(name: "board")
            .background(Color.app.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .shadow(color: Color.app.ink.opacity(0.08), radius: 12, y: 4)
        } else {
            ProgressView()
                .frame(maxHeight: .infinity)
        }
    }

    private func note(_ entry: GuestbookEntry, boardSize: CGSize) -> some View {
        let isHeld = heldID == entry.id
        let center = isHeld ? heldCenter : center(of: entry, in: boardSize)
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(entry.message)
                .font(.footnote)
                .lineLimit(4)
            Spacer(minLength: 0)
            Text("- \(entry.author) -")
                .font(.footnote.bold())
        }
        .foregroundStyle(Color.app.ink)
        .padding(Spacing.xs)
        .frame(width: noteSize, height: noteSize, alignment: .topLeading)
        .background(Color(entry.colorName), in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
        .shadow(color: Color.app.ink.opacity(0.08), radius: 12, y: 4)
        .rotationEffect(.degrees(isHeld ? 0 : Double(entry.id.uuid.0 % 7) - 3))
        .scaleEffect(isHeld ? 1.08 : 1)
        .position(center)
        .zIndex(isHeld ? 1 : 0)
        .gesture(canEdit(entry) ? hold(entry, boardSize: boardSize) : nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.author)의 메모, \(entry.message)")
        .accessibilityActions {
            if canEdit(entry) {
                Button("삭제") { delete(entry) }
            }
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.spring, value: isHeld)
    }

    private func trash(boardSize: CGSize) -> some View {
        let isOver = isOverTrash(heldCenter, in: boardSize)
        return Image(systemName: isOver ? "trash.fill" : "trash")
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: trashSize, height: trashSize)
            .background(Color.app.danger, in: Circle())
            .scaleEffect(isOver ? 1.2 : 1)
            .position(trashCenter(in: boardSize))
            .animation(.spring, value: isOver)
            .transition(.scale.combined(with: .opacity))
            .accessibilityHidden(true)
    }

    private var composer: some View {
        HStack(spacing: Spacing.xs) {
            TextField("방명록을 남겨 보세요", text: $draft)
                .padding(.horizontal, Spacing.s)
                .frame(minHeight: 44)
                .background(Color.app.surface, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                .onChange(of: draft) {
                    if draft.count > maxLength { draft = String(draft.prefix(maxLength)) }
                }
            Button("등록") {
                Task { await post() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.app.accent)
            .foregroundStyle(Color.app.ink)
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(Spacing.m)
        .background(Color.app.background)
    }

    // MARK: 메모지 옮기기

    private func canEdit(_ entry: GuestbookEntry) -> Bool {
        ownerID == "me" || entry.author == "나"
    }

    private func center(of entry: GuestbookEntry, in size: CGSize) -> CGPoint {
        CGPoint(x: noteSize / 2 + entry.x * max(0, size.width - noteSize),
                y: noteSize / 2 + entry.y * max(0, size.height - noteSize))
    }

    private func trashCenter(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height - trashSize / 2 - Spacing.m)
    }

    private func isOverTrash(_ point: CGPoint, in size: CGSize) -> Bool {
        let trash = trashCenter(in: size)
        return hypot(point.x - trash.x, point.y - trash.y) < trashSize
    }

    /// 꾹 누르면 집어 올리고, 그대로 끌면 따라온다.
    private func hold(_ entry: GuestbookEntry, boardSize: CGSize) -> some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("board")))
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                if heldID != entry.id {
                    heldID = entry.id
                    heldCenter = center(of: entry, in: boardSize)
                    grabOffset = nil
                }
                guard let drag else { return }
                let offset = grabOffset ?? CGPoint(x: heldCenter.x - drag.startLocation.x, y: heldCenter.y - drag.startLocation.y)
                grabOffset = offset
                heldCenter = CGPoint(x: drag.location.x + offset.x, y: drag.location.y + offset.y)
            }
            .onEnded { _ in
                defer {
                    heldID = nil
                    grabOffset = nil
                }
                guard heldID == entry.id else { return }
                if isOverTrash(heldCenter, in: boardSize) {
                    delete(entry)
                } else {
                    drop(entry, at: heldCenter, in: boardSize)
                }
            }
    }

    private func drop(_ entry: GuestbookEntry, at point: CGPoint, in size: CGSize) {
        let x = min(1, max(0, (point.x - noteSize / 2) / max(1, size.width - noteSize)))
        let y = min(1, max(0, (point.y - noteSize / 2) / max(1, size.height - noteSize)))
        guard let index = entries?.firstIndex(where: { $0.id == entry.id }) else { return }
        entries?[index].x = x
        entries?[index].y = y
        Task { try? await store.api.moveGuestbookEntry(entry.id, to: CGPoint(x: x, y: y), of: ownerID) }
    }

    private func delete(_ entry: GuestbookEntry) {
        withAnimation(.spring) { entries?.removeAll { $0.id == entry.id } }
        deleteCount += 1
        Task { try? await store.api.deleteGuestbookEntry(entry.id, of: ownerID) }
    }

    private func load() async {
        didFail = false
        do {
            entries = try await store.api.guestbook(of: ownerID)
        } catch {
            didFail = true
        }
    }

    private func post() async {
        let message = draft.trimmingCharacters(in: .whitespaces)
        guard let entry = try? await store.api.writeGuestbook(message, to: ownerID) else { return }
        withAnimation(.spring) { entries?.insert(entry, at: 0) }
        draft = ""
        postCount += 1
    }
}

#Preview("메모 있음") {
    NavigationStack {
        GuestbookView(ownerID: "me", title: "내 방명록", canWrite: false)
    }
    .environment(FriendStore(api: MockFriendAPI()))
}

#Preview("빈 보드") {
    NavigationStack {
        GuestbookView(ownerID: "haneul", title: "하늘이의 방명록", canWrite: true)
    }
    .environment(FriendStore(api: MockFriendAPI()))
}
