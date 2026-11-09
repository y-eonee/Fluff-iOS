import Darwin
import Metal
import UIKit
import RealityKit

/// Opt-in, local-only Release profiling. Never edits dolls or their saved room.
@MainActor
enum RoomPerformanceAudit {
    static let enabled = ProcessInfo.processInfo.arguments.contains("--room-performance-audit")
    static let duration = ProcessInfo.processInfo.arguments.first { $0.hasPrefix("--performance-seconds=") }
        .flatMap { Int($0.split(separator: "=").last ?? "") } ?? 660
    #if DEBUG
    static let configuration = "Debug"
    #else
    static let configuration = "Release"
    #endif
    static func runIfRequested() async {
        guard enabled else { return }
        let idle = UIApplication.shared.isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = true
        defer { UIApplication.shared.isIdleTimerDisabled = idle }
        let started = ProcessInfo.processInfo.systemUptime
        var lastTime = started
        var lastFrames = 0
        var lastCPU = cpuSeconds()
        var samples: [[String: Any]] = []
        for _ in 0..<max(1, duration / 10) {
            do { try await Task.sleep(for: .seconds(10)) } catch { return }
            let now = ProcessInfo.processInfo.systemUptime
            let views = RoomRenderView.liveViews.allObjects.filter { $0.window != nil }
            if samples.count == 1, ProcessInfo.processInfo.arguments.contains("--performance-snapshot") {
                views.first?.snapshot { image in
                    try? image?.pngData()?.write(to: URL.documentsDirectory.appending(path: "room-performance-snapshot.png"), options: .atomic)
                }
            }
            let frames = views.reduce(0) { $0 + $1.completedFrames }
            let cpu = cpuSeconds()
            var models = 0, savedModels = 0, instances = 0, dolls = 0, furniture = 0
            func visit(_ entity: Entity) {
                if entity.components[ModelComponent.self] != nil { models += 1 }
                if entity.name.hasPrefix("doll|") { dolls += 1 }
                if entity.name.hasPrefix("item|") { furniture += 1 }
                if let count = entity.components[FurnitureInstances.Counts.self] {
                    savedModels += count.batchedModels; instances += count.instances
                }
                for child in entity.children { visit(child) }
            }
            views.compactMap(\.root).forEach(visit)
            samples.append([
                "seconds": now - started, "footprintMiB": footprint(),
                "metalMiB": Double(MTLCreateSystemDefaultDevice()?.currentAllocatedSize ?? 0) / 1_048_576,
                "cpuPercentOfOneCore": (cpu - lastCPU) / (now - lastTime) * 100,
                "observedFPS": Double(max(0, frames - lastFrames)) / (now - lastTime),
                "requestedFPS": views.map(\.requestedFPS), "renderScales": views.map(\.renderScale),
                "thermalState": ProcessInfo.processInfo.thermalState.rawValue,
                "lowPower": ProcessInfo.processInfo.isLowPowerModeEnabled,
                "active": UIApplication.shared.applicationState == .active,
                "visibleRenderers": views.count, "adaptive": views.map(\.isAdaptive),
                "models": models, "batchedModelReduction": savedModels, "instances": instances,
                "dolls": dolls, "furniture": furniture,
                "renderErrors": views.compactMap(\.lastRenderError)
            ])
            lastTime = now; lastFrames = frames; lastCPU = cpu
            let report: [String: Any] = [
                "configuration": configuration,
                "durationRequested": duration,
                "scenario": "Saved room, first 10 seconds of each minute camera pan at 60 FPS, remaining time idle at 30 FPS; no saved data changes.",
                "legacyRenderer": ProcessInfo.processInfo.arguments.contains("--legacy-room-renderer"),
                "unbatchedFurniture": ProcessInfo.processInfo.arguments.contains("--unbatched-furniture"),
                "finished": now - started >= Double(duration), "samples": samples
            ]
            if let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
                try? data.write(to: URL.documentsDirectory.appending(path: "room-performance-audit.json"), options: .atomic)
            }
        }
    }
    private static func cpuSeconds() -> Double {
        var value = rusage()
        getrusage(RUSAGE_SELF, &value)
        return Double(value.ru_utime.tv_sec + value.ru_stime.tv_sec)
            + Double(value.ru_utime.tv_usec + value.ru_stime.tv_usec) / 1_000_000
    }
    private static func footprint() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : -1
    }
}
