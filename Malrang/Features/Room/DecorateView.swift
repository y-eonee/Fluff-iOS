import SwiftData
import SwiftUI

/// 마이 홈: 가구를 더하고 옮기고, 두 번 탭해 색이나 사진으로 꾸민다. 적용하기 전에는 되돌릴 수 있다.
struct DecorateView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Namespace var categoryIndicator
    @State var editFeedbackCount = 0
    @State var entrance = RoomEntrance(.editor)
    @State var loadingEntrance = RoomEntrance(.home)
    @Environment(\.startupPresentationFinished) var startupPresentationFinished
    @Query(sort: \RoomItem.createdAt) var items: [RoomItem]
    @Query(sort: \Doll.createdAt) var dolls: [Doll]
    @State var category = FurnitureCategory.furniture
    @State var catalogSelection = FurnitureKind.bed
    @State var surfacePhotoMode: Bool? = nil
    @State var dollPoint: CGPoint?
    @State var furnitureBounds: [String: CGRect] = [:]
    @State var wallPolygon: [CGPoint] = []
    @State var rightWallPolygon: [CGPoint] = []
    @State var selectedRightWall = false
    @State var undoStack: [[RoomItemState]] = []
    @State var redoStack: [[RoomItemState]] = []
    @State var isApplyingHistory = false
    @State var lastEdit = Date.distantPast
    @State var original: [RoomItemState]?
    @State var furniturePrepared = false
    @State var originalDolls: [UUID: SIMD3<Float>] = [:]
    @State var hold: RoomSceneView.Hold?
    @AppStorage("hapticOn") var hapticOn = true
    @State var feelCount = 0
    @State var selectedID: UUID?
    @State var rotationFailCount = 0
    @State var editingItem: RoomItem?
    @State var photoRemovalItem: RoomItem?
    @State var photoRemovalRightWall = false
    @State var isConfirmingDiscard = false
    @State var isFull = false
    @State var saveFailed = false
    @State var isBlocked = false

    var hasChanges: Bool {
        original != nil && (original != items.map(\.state) || dolls.contains { originalDolls[$0.id] != $0.position })
    }

    var body: some View {
        contentA
        .background(Color.mib.bg.screen)
        .allowsHitTesting(loadingEntrance.finished && entrance.finished)
        .accessibilityHidden(!loadingEntrance.finished)
        .overlay {
            if !loadingEntrance.finished {
                RoomLoadingView(entrance: loadingEntrance)
                    .accessibilityIdentifier("decorate-loading")
            }
        }
        .sensoryFeedback(trigger: feelCount) { _, _ in hapticOn ? .impact(weight: .heavy) : nil }
        .sensoryFeedback(trigger: category) { _, _ in hapticOn ? .selection : nil }
        .sensoryFeedback(trigger: selectedID) { _, new in hapticOn && new != nil ? .selection : nil }
        .sensoryFeedback(trigger: editFeedbackCount) { _, _ in hapticOn ? .impact(weight: .light) : nil }
        .alert("꾸민 내용을 저장하지 못했어요", isPresented: $saveFailed) { Button("확인", role: .cancel) {} }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .preference(key: AppTabBarHiddenPreference.self, value: true)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: items.map(\.state)) { old, _ in
            if isApplyingHistory {
                isApplyingHistory = false
            } else if Date.now.timeIntervalSince(lastEdit) > 0.6 {
                undoStack.append(old)
                redoStack = []
            }
            lastEdit = .now
        }
        .overlay {
            if let item = photoRemovalItem {
                RoomPhotoRemovalDialog(itemName: photoRemovalRightWall ? "오른쪽 벽" : item.kind.label, cancel: { photoRemovalItem = nil }) {
                    if photoRemovalRightWall { item.rightWallPhotoData = nil } else { item.photoData = nil }
                    photoRemovalItem = nil
                }
            } else if isConfirmingDiscard {
                RepresentativeConfirmDialog(title: "꾸민 내용을 버릴까요?", message: "지금까지 만든 내용은 저장되지 않아요.", verticalOffset: 10.56, outlinesSecondary: true, onLeave: {
                    restoreOriginal(); dismiss()
                }, onStay: { isConfirmingDiscard = false })
            }
        }
        .environment(\.roomFlowDesign, true)
        .onChange(of: selectedID) { _, id in
            if editingItem?.id != id { editingItem = nil }
        }
        .task(id: startupPresentationFinished) {
            guard startupPresentationFinished else { return }
            if !furniturePrepared {
                if original == nil {
                    original = items.map(\.state)
                    originalDolls = Dictionary(uniqueKeysWithValues: dolls.map { ($0.id, $0.position) })
                }
                for kind in FurnitureKind.catalog where kind.isMovable {
                    _ = await SceneFactory.furniture(RoomItemState(id: UUID(), kind: kind, x: 0, z: 0), cozy: true, cutaway: true)
                }
                guard !Task.isCancelled else { return }
                // Opening the editor must not relocate the saved home layout.
                // Placement constraints apply only to explicit user edits.
                furniturePrepared = true
            }
            loadingEntrance.present()
            while !loadingEntrance.finished && !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                loadingEntrance.finishIfNeeded()
            }
            // The cotton veil remains opaque until 7.8s. Starting the 2s room
            // motion underneath it hid the furniture rise and chair arrival.
            // Play the existing source motion only after the loading handoff.
            guard !Task.isCancelled else { return }
            entrance.present()
        }
        .onAppear {
            if original == nil {
                original = items.map(\.state)
                originalDolls = Dictionary(uniqueKeysWithValues: dolls.map { ($0.id, $0.position) })
            }
        }
        #if DEBUG
        .onChange(of: entrance.finished) { _, finished in
            guard finished, ProcessInfo.processInfo.arguments.contains("--editor-entrance-audit"),
                  let loadedAt = loadingEntrance.start, let animatedAt = entrance.start else { return }
            let checks = ["starts_after_loading": animatedAt >= loadedAt + loadingEntrance.timeline.duration,
                          "saved_furniture_unchanged": original == items.map(\.state)]
            if let data = try? JSONSerialization.data(withJSONObject: checks, options: .sortedKeys) {
                try? data.write(to: URL.documentsDirectory.appending(path: "editor-handoff-audit.json"))
            }
        }
        #endif
        .task(id: isBlocked) {
            guard isBlocked else { return }
            do { try await Task.sleep(for: .seconds(3)) } catch { return }
            isBlocked = false
        }
        .task(id: isFull) {
            guard isFull else { return }
            do { try await Task.sleep(for: .seconds(3)) } catch { return }
            isFull = false
        }
    }

    /// 인형을 든 동안 머리 위를 따라다니며 어디에 놓일지 알려준다.
    @ViewBuilder
    var holdTooltip: some View {
        if let hold {
            let seat = RoomLayout.seat(at: [hold.position.x, hold.position.z], in: items.map(\.state)).item
            D1Bubble(text: "옮기는 중 · \(seat?.kind.label ?? "바닥")")
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
        let spot = RoomLayout.snapped([rotated.x, rotated.z], for: rotated.kind, yaw: rotated.yaw, isMirrored: rotated.isMirrored)
        (rotated.x, rotated.z) = (spot.x, spot.y)
        guard RoomLayout.canMove(item.state, to: rotated, among: items.map(\.state)) else {
            rotationFailCount += 1
            isBlocked = true
            return
        }
        withAnimation(reduceMotion ? nil : .spring) {
            item.yaw = Double(rotated.yaw)
            item.x = Double(spot.x)
            item.z = Double(spot.y)
        }
    }

    func mirror(_ item: RoomItem) {
        var mirrored = item.state; mirrored.isMirrored.toggle()
        let spot = RoomLayout.constrained(mirrored)
        mirrored.x = spot.x; mirrored.z = spot.y
        guard RoomLayout.canMove(item.state, to: mirrored, among: items.map(\.state)) else {
            rotationFailCount += 1; isBlocked = true; return
        }
        move(item.id, to: spot)
        item.isMirrored = mirrored.isMirrored
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
        guard let spot = RoomLayout.freeSpot(for: kind, among: items.map(\.state), dolls: dolls.filter(\.isPlaced).map(\.position)) else {
            isFull = true
            return
        }
        catalogSelection = kind
        let item = RoomItem(kind: kind, x: Double(spot.x), z: Double(spot.y))
        modelContext.insert(item)
        selectedID = item.id
    }

    /// 가구를 옮기면 그 위에 있던 인형과 책상 위 조명도 함께 옮긴다.
    func move(_ id: UUID, to point: SIMD2<Float>) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        let states = items.map(\.state)
        let delta = point - SIMD2(Float(item.x), Float(item.z))
        for doll in dolls where doll.isPlaced && RoomLayout.seat(at: [doll.position.x, doll.position.z], in: states).item?.id == id {
            doll.position += [delta.x, 0, delta.y]
        }
        for lamp in items where RoomLayout.lampSupport(for: lamp.state, in: states)?.id == id {
            lamp.x += Double(delta.x)
            lamp.z += Double(delta.y)
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
