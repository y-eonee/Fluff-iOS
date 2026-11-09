#if DEBUG
import Darwin
import Metal
import SwiftUI

/// Launch with --memory-audit. Fixtures use in-memory stores and synthetic photos only.
struct MemoryAuditView: View {
    @State private var route: String?
    @State private var samples: [Sample] = []
    @State private var finished = false
    private struct Sample: Codable {
        var stage: String
        var footprintMB: Double
        var metalMB: Double
        var liveViews: Int
        var visibleViews: Int
        var fixtures: Int
        var timestamp: Date
    }

    var body: some View {
        Group {
            if let route { DesignPreview(route: route).id(route) }
            else { Text(finished ? "Memory audit complete" : "Memory audit · releasing scene") }
        }
        .task {
            let wasDisabled = UIApplication.shared.isIdleTimerDisabled
            UIApplication.shared.isIdleTimerDisabled = true
            defer { UIApplication.shared.isIdleTimerDisabled = wasDisabled }
            sample("start")
            let arguments = ProcessInfo.processInfo.arguments
            let cycles = arguments.first { $0.hasPrefix("--memory-cycles=") }.flatMap { Int($0.split(separator: "=").last ?? "") } ?? 3
            let routes = arguments.first { $0.hasPrefix("--memory-route=") }.map { [String($0.split(separator: "=").last!)] } ?? ["home-ui", "photo-cat", "running"]
            for cycle in 1...max(1, cycles) {
                for next in routes {
                    route = next
                    try? await Task.sleep(for: .seconds(8))
                    guard !Task.isCancelled else { return }
                    sample("\(cycle)-\(next)")
                    route = nil
                    try? await Task.sleep(for: .seconds(3))
                    guard !Task.isCancelled else { return }
                    sample("\(cycle)-released-\(next)")
                }
            }
            NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
            try? await Task.sleep(for: .seconds(3))
            sample("after-memory-warning")
            finished = true
            let url = URL.documentsDirectory.appending(path: "memory-audit.json")
            if let data = try? JSONEncoder().encode(samples) { try? data.write(to: url, options: .atomic) }
        }
    }

    private func sample(_ stage: String) {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }
        let views = EfficientARView.auditViews.allObjects
        let value = Sample(stage: stage, footprintMB: Double(info.phys_footprint) / 1_048_576,
                           metalMB: Double(MTLCreateSystemDefaultDevice()?.currentAllocatedSize ?? 0) / 1_048_576,
                           liveViews: views.count, visibleViews: views.filter { $0.window != nil }.count,
                           fixtures: DesignPreviewData.auditFixtures.allObjects.count, timestamp: .now)
        samples.append(value)
        if let data = try? JSONEncoder().encode(samples) {
            try? data.write(to: URL.documentsDirectory.appending(path: "memory-audit.json"), options: .atomic)
        }
        print("MEMORY_AUDIT \(stage) \(value.footprintMB) MB")
    }
}
#endif
