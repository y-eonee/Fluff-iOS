import Foundation
import SwiftData

@MainActor
enum DollActivityRecorder {
    static func record(_ activity: DollActivity, ids: [UUID], in context: ModelContext) {
        guard !ids.isEmpty, let dolls = try? context.fetch(FetchDescriptor<Doll>()) else { return }
        let selected = Set(ids)
        for doll in dolls where selected.contains(doll.id) { doll.record(activity) }
        try? context.save()
    }
}
