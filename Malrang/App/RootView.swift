import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [RoomItem]
    @State private var appState = AppState()
    @State private var signedOutLoadingFinished = false

    var body: some View {
        if isSignedIn {
            MainTabs().environment(appState)
                .task {
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
            .allowsHitTesting(signedOutLoadingFinished)
            .accessibilityHidden(!signedOutLoadingFinished)
            .overlay { StartupLoadingView { signedOutLoadingFinished = true } }
        }
    }
}

#Preview { RootView().modelContainer(.preview) }
