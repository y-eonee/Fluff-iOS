import SwiftData
import SwiftUI

@main
struct MalrangApp: App {
    @State private var friendStore = FriendStore(api: MockFriendAPI())
    @State private var isShowingSplash = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        Font.registerCustomFonts()
    }

    @ViewBuilder private var appContent: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--memory-audit") { MemoryAuditView() }
        else if let route = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--design-preview=") })?.split(separator: "=").last {
            DesignPreview(route: String(route))
        } else { RootView() }
        #else
        RootView()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                appContent
                    .allowsHitTesting(!isShowingSplash)
                    .accessibilityHidden(isShowingSplash)
                if isShowingSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                #if DEBUG
                await PresetModelExporter.exportIfRequested()
                await CozyModelExporter.exportIfRequested()
                await CozyModelExporter.auditIfRequested()
                #endif
                do { try await Task.sleep(for: .seconds(1.2)) }
                catch { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) {
                    isShowingSplash = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                RenderMemory.clearCaches()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { RenderMemory.clearCaches() }
            }
            .environment(friendStore)
            .font(.custom("Pretendard-Regular", size: 17, relativeTo: .body))
            .tint(Color.app.ink)
            .preferredColorScheme(.light)
        }
        .modelContainer(for: [Doll.self, RoomItem.self, DecorPhoto.self])
    }
}
