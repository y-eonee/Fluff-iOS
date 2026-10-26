#if DEBUG
import Darwin
import SwiftUI

/// Launch with --memory-audit. Fixtures use in-memory stores and synthetic photos only.
struct MemoryAuditView: View {
    @State private var route: String?
    @State private var samples: [Sample] = []
    @State private var finished = false
    private struct Sample: Codable {
        var stage: String
        var footprintMB: Double
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
            for cycle in 1...3 {
                for next in ["home-ui", "photo-cat", "running"] {
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
        let value = Sample(stage: stage, footprintMB: Double(info.phys_footprint) / 1_048_576)
        samples.append(value)
        print("MEMORY_AUDIT \(stage) \(value.footprintMB) MB")
    }
}
#endif
