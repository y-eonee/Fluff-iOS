import AuthenticationServices
import GoogleSignIn
import SwiftData
import SwiftUI

@main
struct MalrangApp: App {
    @State private var isShowingSplash = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        Font.registerCustomFonts()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--reset-onboarding-preview") {
            UserDefaults.standard.removePersistentDomain(forName: "fluff.onboarding-preview")
        }
        #endif
    }

    @ViewBuilder private var appContent: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--export-furniture-thumbnails") {
            FurnitureThumbnailExporter().frame(width: 512, height: 384)
        } else if ProcessInfo.processInfo.arguments.contains("--onboarding-preview") {
            RootView().defaultAppStorage(UserDefaults(suiteName: "fluff.onboarding-preview")!).modelContainer(.preview)
        }
        else if ProcessInfo.processInfo.arguments.contains("--memory-audit") { MemoryAuditView() }
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
                if ProcessInfo.processInfo.arguments.contains("--activity-audit") { DollActivityAudit.run() }
                if ProcessInfo.processInfo.arguments.contains("--render-resource-audit") { await RenderResourceAudit.run() }
                if ProcessInfo.processInfo.arguments.contains("--furniture-audit") { await FurnitureInteractionAudit.run() }
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
            #if DEBUG
            .task {
                if ProcessInfo.processInfo.arguments.contains("--live-render-audit") { await LiveRenderAudit.run() }
            }
            #endif
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { RenderMemory.clearCaches() }
                if phase == .active { Task { await AppleAccount.validateSession() } }
            }
            .task { await AppleAccount.validateSession() }
            .onReceive(NotificationCenter.default.publisher(for: ASAuthorizationAppleIDProvider.credentialRevokedNotification)) { _ in
                Task { await AppleAccount.validateSession() }
            }
            .onOpenURL { url in _ = GIDSignIn.sharedInstance.handle(url) }
            .font(.custom("Pretendard-Regular", size: 17, relativeTo: .body))
            .tint(Color.app.accent)
            .preferredColorScheme(.light)
        }
        .modelContainer(for: [Doll.self, RoomItem.self, DecorPhoto.self])
    }
}
