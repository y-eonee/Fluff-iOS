import SwiftData
import SwiftUI

/// 마이 홈: 가구를 더하고 옮기고, 두 번 탭해 색이나 사진으로 꾸민다. 적용하기 전에는 되돌릴 수 있다.
struct DecorateView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Query(sort: \RoomItem.createdAt) var items: [RoomItem]
    @Query(sort: \Doll.createdAt) var dolls: [Doll]
    @AppStorage("designVariant") var variant = DesignVariant.a
    @State var category = FurnitureCategory.furniture
    @State var dollPoint: CGPoint?
    @State var undoStack: [[RoomItemState]] = []
    @State var redoStack: [[RoomItemState]] = []
    @State var isApplyingHistory = false
    @State var lastEdit = Date.distantPast
    @State var original: [RoomItemState]?
    @State var originalDolls: [UUID: SIMD3<Float>] = [:]
    @State var hold: RoomSceneView.Hold?
    @AppStorage("hapticOn") var hapticOn = true
    @State var feelCount = 0
    @State var selectedID: UUID?
    @State var rotationFailCount = 0
    @State var editingItem: RoomItem?
    @State var isConfirmingDiscard = false
    @State var isFull = false
    @State var isBlocked = false
    @State var isShowingGuestbook = false

    var hasChanges: Bool {
        original != nil && (original != items.map(\.state) || dolls.contains { originalDolls[$0.id] != $0.position })
    }

    var body: some View {
        Group {
            if variant == .a { contentA } else { contentB }
        }
        .background { if variant == .a { GridPaper() } else { BBackground(grid: true) } }
        .sensoryFeedback(trigger: feelCount) { _, _ in hapticOn ? .impact(weight: .heavy) : nil }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if variant == .a {
                toolbarA
            } else {
                toolbarB
            }
        }
        .onChange(of: items.map(\.state)) { old, _ in
            if isApplyingHistory {
                isApplyingHistory = false
            } else if Date.now.timeIntervalSince(lastEdit) > 0.6 {
                undoStack.append(old)
                redoStack = []
            }
            lastEdit = .now
        }
        .confirmationDialog("꾸민 내용을 버릴까요?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
            Button("버리고 나가기", role: .destructive) {
                restoreOriginal()
                dismiss()
            }
        }
        .navigationDestination(item: $editingItem) { item in
            FurnitureCustomView(item: item)
        }
        .navigationDestination(isPresented: $isShowingGuestbook) {
            GuestbookView(ownerID: "me", title: "내 방명록", canWrite: false)
        }
        .onAppear {
            if original == nil {
                original = items.map(\.state)
                originalDolls = Dictionary(uniqueKeysWithValues: dolls.map { ($0.id, $0.position) })
            }
        }
        .task(id: isBlocked) {
            try? await Task.sleep(for: .seconds(3))
            isBlocked = false
        }
        .task(id: isFull) {
            try? await Task.sleep(for: .seconds(3))
            isFull = false
        }
    }

    /// 인형을 든 동안 머리 위를 따라다니며 어디에 놓일지 알려준다.
    @ViewBuilder
    var holdTooltip: some View {
        if let hold {
            let seat = RoomLayout.seat(at: [hold.position.x, hold.position.z], in: items.map(\.state)).item
            HintCapsule(text: "옮기는 중 · \(seat?.kind.label ?? "바닥")")
                .fixedSize()
                .position(x: hold.screen.x, y: hold.screen.y)
                .allowsHitTesting(false)
        }
    }

    var selectedItem: RoomItem? { items.first { $0.id == selectedID } }

    func selectCategory(_ tab: FurnitureCategory) {
        selectedID = nil
        category = tab
    }

    /// 90도씩 돌린다. 돌린 자리가 다른 가구와 겹치면 돌리지 않는다.
    func rotate(_ item: RoomItem) {
        var rotated = item.state
        rotated.yaw = (rotated.yaw + .pi / 2).truncatingRemainder(dividingBy: 2 * .pi)
        let spot = RoomLayout.snapped([rotated.x, rotated.z], for: rotated.kind, yaw: rotated.yaw)
        (rotated.x, rotated.z) = (spot.x, spot.y)
        guard !RoomLayout.overlaps(rotated, in: items.map(\.state)) else {
            rotationFailCount += 1
            isBlocked = true
            return
        }
        withAnimation(.spring) {
            item.yaw = Double(rotated.yaw)
            item.x = Double(spot.x)
            item.z = Double(spot.y)
        }
    }

    func remove(_ item: RoomItem) {
        selectedID = nil
        modelContext.delete(item)
    }

    /// 벽지·바닥재 탭이면 그 면의 종류
    var surfaceKind: FurnitureKind? {
        switch category {
        case .wallpaper: .wall
        case .flooring: .floor
        default: nil
        }
    }

    func add(_ kind: FurnitureKind) {
        guard let spot = RoomLayout.freeSpot(for: kind, among: items.map(\.state)) else {
            isFull = true
            return
        }
        let item = RoomItem(kind: kind, x: Double(spot.x), z: Double(spot.y))
        modelContext.insert(item)
        selectedID = item.id
    }

    /// 가구를 옮기면 그 위에 있던 인형도 함께 옮긴다.
    func move(_ id: UUID, to point: SIMD2<Float>) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        let states = items.map(\.state)
        let delta = point - SIMD2(Float(item.x), Float(item.z))
        for doll in dolls where doll.isPlaced && RoomLayout.seat(at: [doll.position.x, doll.position.z], in: states).item?.id == id {
            doll.position += [delta.x, 0, delta.y]
        }
        item.x = Double(point.x)
        item.z = Double(point.y)
    }

    func restoreOriginal() {
        guard let original else { return }
        for doll in dolls {
            if let position = originalDolls[doll.id] { doll.position = position }
        }
        apply(original)
    }

    /// 가구를 주어진 상태로 되돌린다. 지워진 가구는 다시 만들고, 새로 생긴 가구는 지운다.
    func apply(_ states: [RoomItemState]) {
        if states != items.map(\.state) { isApplyingHistory = true }
        for item in items where !states.contains(where: { $0.id == item.id }) {
            modelContext.delete(item)
        }
        for state in states {
            if let item = items.first(where: { $0.id == state.id }) {
                item.restore(state)
            } else {
                let item = RoomItem(kind: state.kind)
                item.id = state.id
                item.restore(state)
                modelContext.insert(item)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DecorateView()
    }
    .modelContainer(.preview)
}
