import Foundation

@main
struct FocusSessionAudit {
    static func main() throws {
        let domain = "fluff.focus.audit.\(UUID())"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let session = FocusSession(defaults: defaults)
        let start = Date.now.addingTimeInterval(60)
        let first = UUID(), second = UUID()
        session.select(first)
        session.selectActivity(.read)
        precondition(session.activity == .read && session.record.focusMinutes == 45)
        session.selectActivity(.task)
        precondition(session.record.focusMinutes == 60 && session.record.restMinutes == 10)
        session.selectActivity(.study)
        session.start(at: start)
        session.selectActivity(.read); session.configure(focus: 1, rest: 1); session.select(second)
        precondition(session.activity == .study && session.record.focusMinutes == 25 && session.record.dollID == first, "Running sessions must retain their activity and companion")
        session.tick(at: start.addingTimeInterval(30))
        precondition(session.record.seconds == 30)
        session.togglePause(at: start.addingTimeInterval(45))
        session.tick(at: start.addingTimeInterval(60))
        precondition(session.record.seconds == 45 && session.paused)
        session.togglePause(at: start.addingTimeInterval(60))
        session.tick(at: start.addingTimeInterval(75))
        precondition(session.record.seconds == 60)
        session.tick(at: start.addingTimeInterval(1600))
        precondition(session.resting)
        precondition(session.record.daily.values.reduce(0, +) == 1500)
        precondition(session.total(with: first) == 1500 && session.total(with: second) == 0)
        session.tick(at: start.addingTimeInterval(10000))
        precondition(session.paused && session.record.daily.values.reduce(0, +) == 1500, "Offline rest must not start endless focus cycles")
        let reloaded = FocusSession(defaults: defaults)
        precondition(reloaded.record == session.record)
        let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(reloaded.record)) as! [String: Any]
        precondition(encoded["rewardIDs"] == nil && encoded["completedMinutes"] == nil, "Focus must not generate prop rewards")
        reloaded.stop(at: start.addingTimeInterval(10001))
        reloaded.select(second)
        let midnight = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: start))!
        reloaded.start(at: midnight.addingTimeInterval(-30)); reloaded.tick(at: midnight.addingTimeInterval(30))
        precondition(reloaded.record.daily.count >= 2 && reloaded.today(at: midnight) == 30)
        precondition(reloaded.total(with: second) == 60 && reloaded.total(with: first) == 1500)
        // Old installs have no activity or per-companion totals; unknown reward fields are ignored.
        var legacy = encoded
        legacy.removeValue(forKey: "activity"); legacy.removeValue(forKey: "companionSeconds")
        legacy["rewardIDs"] = [UUID().uuidString]; legacy["completedMinutes"] = 25
        defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: "cotton.focus.session.v1")
        let migrated = FocusSession(defaults: defaults)
        precondition(migrated.activity == .study && migrated.total(with: first) == 1500 && migrated.paused)
        precondition(migrated.record.daily == session.record.daily)
        print("PASS: activities, locked running settings, pause/resume, bounded offline credit, no prop rewards, persistence, per-companion totals, legacy migration, midnight split")
    }
}
