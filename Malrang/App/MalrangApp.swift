import AuthenticationServices
import GoogleSignIn
import SwiftData
import SwiftUI

@main
struct MalrangApp: App {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @State private var startupPresentationFinished = false
    private var isStartupReady: Bool {
        startupPresentationFinished || skipsBrandSplash
    }
    private var skipsBrandSplash: Bool {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--show-startup-splash") { return false }
        return args.contains { $0.hasPrefix("--design-preview=") || $0.hasPrefix("--export-") || $0.hasSuffix("-audit") || $0 == "--onboarding-preview" }
        #else
        return false
        #endif
    }
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
        if ProcessInfo.processInfo.arguments.contains("--furniture-appearance-audit") {
            FurnitureAppearanceAudit().frame(width: 320, height: 320)
        } else if ProcessInfo.processInfo.arguments.contains("--export-motion-review") {
            MotionReviewExporter().frame(width: 720, height: 480)
        } else if ProcessInfo.processInfo.arguments.contains("--export-furniture-thumbnails") {
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

    @ViewBuilder private var startupContent: some View {
        #if DEBUG
        DesignDataResetGate { appContent }
        #else
        appContent
        #endif
    }

    var body: some Scene {
        WindowGroup {
            startupContent
                .allowsHitTesting(isStartupReady)
                .accessibilityHidden(!isStartupReady)
                .overlay {
                    if !isStartupReady {
                        if isSignedIn { BrandSplashView().transition(.opacity) }
                        else { PreloginSplashView { startupPresentationFinished = true } }
                    }
                }
                .task(id: isSignedIn) {
                    guard isSignedIn || skipsBrandSplash else { return }
                    if !isStartupReady { try? await Task.sleep(for: .milliseconds(1100)) }
                    guard !Task.isCancelled else { return }
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) { startupPresentationFinished = true }
                }
                .environment(\.startupPresentationFinished, isStartupReady)
            .task {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--data-reset-audit") { try? DesignDataReset.audit() }
                if ProcessInfo.processInfo.arguments.contains("--activity-audit") { DollActivityAudit.run() }
                if ProcessInfo.processInfo.arguments.contains("--doll-attachment-audit") { await DollAttachmentAudit.run() }
                if ProcessInfo.processInfo.arguments.contains("--render-resource-audit") { await RenderResourceAudit.run() }
                if ProcessInfo.processInfo.arguments.contains("--youtube-privacy-audit") { await YouTubePrivacyAudit.run() }
                if ProcessInfo.processInfo.arguments.contains("--furniture-audit") { await FurnitureInteractionAudit.run() }
                if ProcessInfo.processInfo.arguments.contains("--furniture-matrix-audit") { await FurnitureMatrixAudit.run() }
                await PresetModelExporter.exportIfRequested()
                await CozyModelExporter.exportIfRequested()
                await CozyModelExporter.auditIfRequested()
                #endif
                #if DEBUG
                try? await Task.sleep(for: .milliseconds(400))
                let nativeRoutes = ["radio-playing", "radio-paused", "radio-timer", "radio-sound", "tabs-dolls", "tabs-profile", "photo-pick", "cutout-auto", "cutout-move", "create-ready", "selection", "couch-playlist"]
                if let route = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--design-preview=") })?.split(separator: "=").last,
                   nativeRoutes.contains(String(route)) { DesignPreviewSignal.sceneReady() }
                DesignPreviewSignal.startupDidFinish()
                #endif
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
            .task { await RoomPerformanceAudit.runIfRequested() }
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
