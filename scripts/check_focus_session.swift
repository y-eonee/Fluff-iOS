import Foundation

@main
struct FocusSessionAudit {
    static func main() {
        let domain = "fluff.focus.audit.\(UUID())"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let session = FocusSession(defaults: defaults)
        let start = Date.now.addingTimeInterval(60)
        session.select(UUID()); session.configure(focus: 25, rest: 5); session.start(at: start)
        session.tick(at: start.addingTimeInterval(30))
        precondition(session.record.seconds == 30)
        session.togglePause(at: start.addingTimeInterval(45))
        session.tick(at: start.addingTimeInterval(60))
        precondition(session.record.seconds == 45 && session.paused)
        session.togglePause(at: start.addingTimeInterval(60))
        session.tick(at: start.addingTimeInterval(75))
        precondition(session.record.seconds == 60)
        session.tick(at: start.addingTimeInterval(1600))
        precondition(session.resting && session.record.rewardIDs.count == 1)
        precondition(session.record.daily.values.reduce(0, +) == 1500)
        session.tick(at: start.addingTimeInterval(10000))
        precondition(session.paused && session.record.rewardIDs.count == 1)
        precondition(session.record.daily.values.reduce(0, +) == 1500, "Offline rest must not start endless focus cycles")
        let reloaded = FocusSession(defaults: defaults)
        precondition(reloaded.record == session.record)
        reloaded.claim(session.record.rewardIDs[0]); precondition(reloaded.record.rewardIDs.isEmpty)
        reloaded.stop(at: start.addingTimeInterval(10001))
        let midnight = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: start))!
        reloaded.start(at: midnight.addingTimeInterval(-30)); reloaded.tick(at: midnight.addingTimeInterval(30))
        precondition(reloaded.record.daily.count >= 2)
        precondition(reloaded.today(at: midnight) == 30)
        print("PASS: pause/resume, bounded offline credit, reward once, persistence, midnight split")
    }
}
