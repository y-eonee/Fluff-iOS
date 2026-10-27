import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("nickname") private var nickname = ""
    @AppStorage("didRestoreIllustrationShelf") private var didRestoreIllustrationShelf = false
    @AppStorage("didApplyCozyRoomLayout") private var didApplyCozyRoomLayout = false
    @AppStorage("didMatchHomeReferenceComposition") private var didMatchHomeReferenceComposition = false
    @AppStorage("didAlignLegacyCozyRoom") private var didAlignLegacyCozyRoom = false
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [RoomItem]
    @State private var appState = AppState()

    var body: some View {
        if isSignedIn && nickname.isEmpty {
            NavigationStack { ProfileEditView(isCreating: true) }
        } else if isSignedIn {
            MainTabs()
            .environment(appState)
            .task {
                if items.isEmpty {
                    RoomItem.starterRoom.forEach(modelContext.insert)
                } else if !didRestoreIllustrationShelf,
                          !items.contains(where: { $0.kind == .shelf }),
                          let shelf = RoomItem.starterRoom.first(where: { $0.kind == .shelf }) {
                    // 기존 방에는 새 기본 가구가 없으므로 한 번만 보충한다.
                    modelContext.insert(shelf)
                }
                if !didRestoreIllustrationShelf, (try? modelContext.save()) != nil {
                    didRestoreIllustrationShelf = true
                }
                if !didApplyCozyRoomLayout {
                    let old: [FurnitureKind: SIMD2<Double>] = [
                        .wall: .zero, .floor: .zero, .bed: [-0.5996, -0.22],
                        .desk: [0.4105, -0.7995], .chair: [0.54, 0.0201],
                        .plant: [-0.8425, 0.6975], .rugRound: [0.2118, 0.2119],
                        .frame: [-0.5, -0.9775], .shelf: [0.4, -0.919]
                    ]
                    let isOriginalLayout = items.count == old.count && items.allSatisfy { item in
                        guard let point = old[item.kind] else { return false }
                        return abs(item.x - point.x) < 0.03 && abs(item.z - point.y) < 0.03 && abs(item.yaw) < 0.01
                    }
                    if isOriginalLayout {
                        // 사용자가 옮긴 방은 유지하고, 이전 기본 배치만 새 시안으로 옮긴다.
                        for replacement in RoomItem.starterRoom {
                            if let item = items.first(where: { $0.kind == replacement.kind }) {
                                item.x = replacement.x
                                item.z = replacement.z
                                item.yaw = replacement.yaw
                            } else {
                                modelContext.insert(replacement)
                            }
                        }
                    }
                    if (try? modelContext.save()) != nil {
                        didApplyCozyRoomLayout = true
                    }
                }
                if !didMatchHomeReferenceComposition {
                    let previous: [FurnitureKind: SIMD2<Double>] = [
                        .wall: .zero, .floor: .zero, .bed: [-0.52, 0.15],
                        .desk: [0.28, -0.50], .chair: [0.49, -0.08],
                        .sofa: [0.68, 0.75], .lamp: [0.48, -0.57],
                        .rugRound: [0.38, 0.70], .frame: [-0.70, -0.9775], .shelf: [-0.10, -0.919]
                    ]
                    let originalItems = items.filter { $0.kind != .plant }
                    let unchanged = originalItems.count == previous.count && originalItems.allSatisfy { item in
                        guard let position = previous[item.kind] else { return false }
                        let yaw: Double = item.kind == .bed || item.kind == .sofa ? .pi / 2 : (item.kind == .chair ? .pi : 0)
                        return abs(item.x - position.x) < 0.005 && abs(item.z - position.y) < 0.005 && abs(item.yaw - yaw) < 0.005
                    }
                    if unchanged {
                        for replacement in RoomItem.starterRoom {
                            if let item = items.first(where: { $0.kind == replacement.kind }) {
                                item.x = replacement.x
                                item.z = replacement.z
                                item.yaw = replacement.yaw
                            }
                        }
                    }
                    if (try? modelContext.save()) != nil { didMatchHomeReferenceComposition = true }
                }
                if !didAlignLegacyCozyRoom {
                    // The first prototype saved a snapped layout before the reference
                    // composition existed. Match that layout only; retain edited rooms.
                    let legacy: [FurnitureKind: SIMD2<Double>] = [
                        .wall: .zero, .floor: .zero, .plant: [-0.8, 0.75],
                        .desk: [0.45, -0.77], .bed: [-0.5, -0.3], .frame: [-0.5, -0.9775],
                        .rugRound: [0.15, 0.25], .chair: [0.55, 0.05], .shelf: [0.4, -0.919]
                    ]
                    let matches = items.count == legacy.count && items.allSatisfy { item in
                        guard let position = legacy[item.kind] else { return false }
                        let yaw: Double = item.kind == .bed ? .pi / 2 : 0
                        return abs(item.x - position.x) < 0.005 && abs(item.z - position.y) < 0.005 && abs(item.yaw - yaw) < 0.005
                    }
                    if matches {
                        for replacement in RoomItem.starterRoom {
                            if let existing = items.first(where: { $0.kind == replacement.kind }) {
                                existing.x = replacement.x
                                existing.z = replacement.z
                                existing.yaw = replacement.yaw
                            } else {
                                modelContext.insert(replacement)
                            }
                        }
                    }
                    if (try? modelContext.save()) != nil { didAlignLegacyCozyRoom = true }
                }
            }
        } else {
            OnboardingView { isSignedIn = true }
        }
    }
}

#Preview {
    RootView()
        .environment(FriendStore(api: MockFriendAPI()))
        .modelContainer(.preview)
}
