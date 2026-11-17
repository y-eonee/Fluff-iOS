#if DEBUG
import SwiftData
import SwiftUI

/// Explicitly invoked for this user's requested clean rebuild. Normal launches
/// never delete stored content, and the switch is absent from Release builds.
@MainActor
enum DesignDataReset {
    static var requested: Bool { ProcessInfo.processInfo.arguments.contains("--reset-design-data") }

    static func perform(in context: ModelContext, defaults: UserDefaults = .standard,
                        reportURL: URL = URL.documentsDirectory.appending(path: "design-data-reset.json")) throws {
        let before = try counts(in: context)
        do {
            try context.delete(model: Doll.self)
            try context.delete(model: RoomItem.self)
            try context.delete(model: DecorPhoto.self)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        let after = try counts(in: context)
        guard after.values.allSatisfy({ $0 == 0 }) else { throw NSError(domain: "Malrang.DesignReset", code: 1, userInfo: [NSLocalizedDescriptionKey: "저장된 자료가 남아 있어요."]) }
        let keys = [
            "cotton.focus.session.v1", "couch.videoLibrary", "avatarData",
            "didSeeFurnitureGuideV2", "usedFurnitureActions", "didRestoreIllustrationShelf",
            "didApplyCozyRoomLayout", "didMatchHomeReferenceComposition", "didAddReferenceLoungeChair",
            "didAlignLegacyCozyRoom", "didApplyNovemberReferenceRoom"
        ]
        keys.forEach(defaults.removeObject(forKey:))
        RenderMemory.clearCaches()
        let report: [String: Any] = ["before": before, "after": after, "clearedPreferenceKeys": keys, "completed": true]
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: reportURL, options: .atomic)
    }

    static func audit() throws {
        let container = try ModelContainer(for: Doll.self, RoomItem.self, DecorPhoto.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        context.insert(Doll(name: "reset-audit", shape: .bear, filling: .fluffy, imageData: Data([1])))
        let item = RoomItem(kind: .frame); item.photoData = Data([2]); context.insert(item)
        context.insert(DecorPhoto(data: Data([3])))
        try context.save()
        let domain = "fluff.reset-audit.\(UUID())"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        defaults.set(true, forKey: "isSignedIn")
        defaults.set(Data([4]), forKey: "avatarData")
        defaults.set(Data([5]), forKey: "cotton.focus.session.v1")
        let reportURL = FileManager.default.temporaryDirectory.appending(path: "reset-audit-report.json")
        try perform(in: context, defaults: defaults, reportURL: reportURL)
        let remaining = try counts(in: context)
        let checks = ["allRecordsRemoved": remaining.values.allSatisfy { $0 == 0 },
                      "photoPreferenceRemoved": defaults.object(forKey: "avatarData") == nil,
                      "focusReferenceRemoved": defaults.object(forKey: "cotton.focus.session.v1") == nil,
                      "signInRetained": defaults.bool(forKey: "isSignedIn")]
        let data = try JSONSerialization.data(withJSONObject: ["checks": checks, "passed": checks.values.allSatisfy { $0 }], options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL.documentsDirectory.appending(path: "design-data-reset-audit.json"), options: .atomic)
    }

    private static func counts(in context: ModelContext) throws -> [String: Int] {
        ["dolls": try context.fetchCount(FetchDescriptor<Doll>()),
         "roomItems": try context.fetchCount(FetchDescriptor<RoomItem>()),
         "photos": try context.fetchCount(FetchDescriptor<DecorPhoto>())]
    }
}

struct DesignDataResetGate<Content: View>: View {
    @Environment(\.modelContext) private var context
    @State private var ready = !DesignDataReset.requested
    @State private var failure: String?
    @ViewBuilder var content: () -> Content
    var body: some View {
        Group {
            if ready { content() }
            else if let failure { ContentUnavailableView("초기화를 완료하지 못했어요", systemImage: "exclamationmark.triangle", description: Text(failure)) }
            else { ProgressView("새 방을 준비하고 있어요") }
        }.task {
            guard !ready else { return }
            do { try DesignDataReset.perform(in: context); ready = true }
            catch { failure = error.localizedDescription }
        }
    }
}
#endif
