#if DEBUG
import Foundation
import Darwin
import Metal
import UIKit
import RealityKit

@MainActor
enum RenderResourceAudit {
    static func run() async {
        var results: [String] = []
        func check(_ valid: Bool, _ name: String) { results.append("\(valid ? "PASS" : "FAIL"): \(name)") }
        let player = YouTubePlayer()
        for _ in 0..<10 { player.pause(); player.stop() }
        check(!player.hasLoadedWebView, "pausing/stopping an unused player never creates a web view")
        let first = player.webView
        check(first === player.webView, "watching and mini-player share one web view")
        player.stop()
        check(!player.hasLoadedWebView, "ending playback releases the retained web view")
        player.pause()
        check(!player.hasLoadedWebView, "pausing after stop does not recreate the web view")
        for shape in DollShape.presets {
            let model = await PresetDollModel.make(PresetConfiguration(shape: shape))
            let parts = DollPart.allCases.compactMap { model.findEntity(named: $0.rawValue) }
            check(parts.count == 7 && parts.allSatisfy { $0.components[CollisionComponent.self]?.shapes.count == 1 },
                  "\(shape): all seven editable parts remain selectable")
            func collisions(_ entity: Entity) -> Int {
                (entity.components[CollisionComponent.self] == nil ? 0 : 1)
                    + entity.children.reduce(0) { $0 + collisions($1) }
            }
            check(collisions(model) == 7, "\(shape): decorative thread does not allocate collision hulls")
        }
        try? results.joined(separator: "\n").write(to: URL.documentsDirectory.appending(path: "render-resource-audit.txt"), atomically: true, encoding: .utf8)
    }
}

/// Measures the normal, saved room without creating or editing fixtures.
@MainActor
enum LiveRenderAudit {
    static func run() async {
        let wasIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = true
        defer { UIApplication.shared.isIdleTimerDisabled = wasIdleTimerDisabled }
        var samples: [[String: Any]] = []
        for seconds in [20, 40, 60] {
            do { try await Task.sleep(for: .seconds(20)) } catch { return }
            var info = task_vm_info_data_t()
            var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
            let status = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                }
            }
            guard status == KERN_SUCCESS else { continue }
            let views = EfficientARView.auditViews.allObjects.filter { $0.window != nil }
            var furniture = 0, dolls = 0
            func visit(_ entity: Entity) {
                if entity.name.hasPrefix("item|") { furniture += 1 }
                if entity.name.hasPrefix("doll|") { dolls += 1 }
                for child in entity.children { visit(child) }
            }
            for view in views { for anchor in view.scene.anchors { visit(anchor) } }
            samples.append(["seconds": seconds, "timestamp": Date().timeIntervalSince1970,
                            "footprintMB": Double(info.phys_footprint) / 1_048_576,
                            "metalMB": Double(MTLCreateSystemDefaultDevice()?.currentAllocatedSize ?? 0) / 1_048_576,
                            "visibleRenderers": views.count, "roomFurniture": furniture, "roomDolls": dolls,
                            "renderScales": views.map(\.contentScaleFactor),
                            "comparisonBudget": ProcessInfo.processInfo.arguments.contains("--render-comparison"),
                            "baselineResources": ProcessInfo.processInfo.arguments.contains("--render-baseline"),
                            "thermalState": ProcessInfo.processInfo.thermalState.rawValue])
            if let data = try? JSONSerialization.data(withJSONObject: samples, options: .prettyPrinted) {
                try? data.write(to: URL.documentsDirectory.appending(path: "live-render-audit.json"), options: .atomic)
            }
        }
    }
}
#endif
