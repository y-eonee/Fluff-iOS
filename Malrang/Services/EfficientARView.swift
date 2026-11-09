import Combine
import Metal
import RealityKit
import UIKit

/// Limit 3D pixel cost independently of crisp, native-resolution SwiftUI controls.
/// Uses public UIView display scaling; no private RealityKit frame-rate controls.
class EfficientARView: ARView {
    private var observations: [AnyCancellable] = []
    private var bloomPreset: Bool?
    private var bloomEnabled = false
    #if DEBUG
    private var lastBudget: String?
    static let auditViews = NSHashTable<EfficientARView>.weakObjects()
    #endif

    override func didMoveToWindow() {
        super.didMoveToWindow()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--memory-audit") || ProcessInfo.processInfo.arguments.contains("--live-render-audit") { Self.auditViews.add(self) }
        #endif
        // Keep bounded shared model resources across navigation. Rebuilding all
        // geometry on every visit needlessly recreates rendering resources.
        // Memory warnings and app backgrounding still purge them via RenderMemory.
        guard window != nil else { return }
        if observations.isEmpty {
            for name in [ProcessInfo.thermalStateDidChangeNotification, .NSProcessInfoPowerStateDidChange] {
                observations.append(NotificationCenter.default.publisher(for: name).receive(on: RunLoop.main).sink { [weak self] _ in
                    MainActor.assumeIsolated { self?.applyRenderBudget() }
                })
            }
        }
        applyRenderBudget()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyRenderBudget()
    }

    func configureBloom(preset: Bool = false) {
        bloomPreset = preset
        applyRenderBudget()
    }

    private func applyRenderBudget() {
        let constrained = ProcessInfo.processInfo.isLowPowerModeEnabled || ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
        let scale = min(max(1, traitCollection.displayScale), constrained ? 1 : 1.5)
        if contentScaleFactor != scale { contentScaleFactor = scale }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--render-audit") {
            let budget = "scale=\(scale), display=\(traitCollection.displayScale), thermal=\(ProcessInfo.processInfo.thermalState.rawValue), lowPower=\(ProcessInfo.processInfo.isLowPowerModeEnabled), bloom=\(!constrained)"
            if budget != lastBudget {
                lastBudget = budget
                try? budget.write(to: URL.documentsDirectory.appending(path: "render-budget.txt"), atomically: true, encoding: .utf8)
            }
        }
        #endif
        guard let preset = bloomPreset else { return }
        let enabled = !constrained
        guard enabled != bloomEnabled else { return }
        bloomEnabled = enabled
        if enabled, let device = MTLCreateSystemDefaultDevice(), let bloom = CozyBloom(device: device, preset: preset) {
            renderCallbacks.postProcess = { context in bloom.render(context) }
        } else { renderCallbacks.postProcess = nil }
    }
}
