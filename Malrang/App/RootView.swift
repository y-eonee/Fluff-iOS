import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [RoomItem]
    @State private var appState = AppState()

    var body: some View {
        if isSignedIn {
            MainTabs().environment(appState)
                .task {
                    for item in items where item.kind == .flowerCushion { modelContext.delete(item) }
                    try? modelContext.save()
                    if items.isEmpty {
                        RoomItem.starterRoom.forEach(modelContext.insert)
                        try? modelContext.save()
                    }
                }
        } else {
            OnboardingView {
                appState = AppState()
                isSignedIn = true
            }
        }
    }
}

#Preview { RootView().modelContainer(.preview) }
