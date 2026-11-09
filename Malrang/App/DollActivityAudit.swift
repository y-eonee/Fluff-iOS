#if DEBUG
import Foundation
import SwiftData

@MainActor
enum DollActivityAudit {
    static func run() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("activity-audit-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let storeURL = directory.appendingPathComponent("history.store")
            let identifier = UUID()
            try autoreleasepool {
                let container = try ModelContainer(for: Doll.self, configurations: ModelConfiguration(url: storeURL))
                let context = container.mainContext
                let doll = Doll(name: "기록 테스트", shape: .cat, filling: .fluffy, imageData: Data())
                doll.id = identifier
                context.insert(doll)
                try context.save()
                precondition(doll.activityData == nil && doll.history[.desk] == 0)
                for activity in DollActivity.allCases {
                    // Duplicate ids must not double count a selected doll.
                    DollActivityRecorder.record(activity, ids: [identifier, identifier], in: context)
                }
                try context.save()
            }
            let container = try ModelContainer(for: Doll.self, configurations: ModelConfiguration(url: storeURL))
            let restored = try container.mainContext.fetch(FetchDescriptor<Doll>()).first!
            precondition(restored.id == identifier)
            precondition(DollActivity.allCases.allSatisfy { restored.history[$0] == 1 })
            precondition(restored.history.intelligence == 1 && restored.history.sensitivity == 2 && restored.history.stamina == 1)
            write("PASS: empty legacy history, selected-doll deduplication, saved history after reopening the store")
        } catch { write("FAIL: \(error)") }
    }

    private static func write(_ message: String) {
        let url = URL.documentsDirectory.appendingPathComponent("doll-activity-audit.txt")
        try? message.write(to: url, atomically: true, encoding: .utf8)
    }
}
#endif
