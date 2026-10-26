import Foundation
import Observation

/// Dates, rather than timer ticks, keep focus accurate across backgrounding and relaunch.
@Observable
final class FocusSession {
    enum Phase: String, Codable { case ready, focusing, resting, pausedFocus, pausedRest }
    struct Record: Codable, Equatable {
        var phase = Phase.ready
        var dollID: UUID?
        var focusMinutes = 25
        var restMinutes = 5
        var seconds: TimeInterval = 0
        var checkpoint: Date?
        var daily: [String: TimeInterval] = [:]
        var rewardIDs: [UUID] = []
        var completedMinutes = 0
    }
    private(set) var record: Record
    private let defaults: UserDefaults
    private let key = "cotton.focus.session.v1"
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        record = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(Record.self, from: $0) } ?? Record()
        tick()
    }
    var active: Bool { record.phase != .ready }
    var resting: Bool { record.phase == .resting || record.phase == .pausedRest }
    var paused: Bool { record.phase == .pausedFocus || record.phase == .pausedRest }
    var duration: TimeInterval { TimeInterval((resting ? record.restMinutes : record.focusMinutes) * 60) }
    var remaining: TimeInterval { max(0, duration - record.seconds) }
    var progress: Double { min(1, record.seconds / max(1, duration)) }
    func today(at date: Date = .now) -> TimeInterval { record.daily[dayKey(date), default: 0] }
    func minutes(on date: Date) -> Int { Int(record.daily[dayKey(date), default: 0] / 60) }
    func select(_ id: UUID) { record.dollID = id; save() }
    func configure(focus: Int, rest: Int) {
        record.focusMinutes = min(180, max(1, focus)); record.restMinutes = min(60, max(1, rest)); save()
    }
    func start(at date: Date = .now) {
        guard !active, record.dollID != nil else { return }
        record.phase = .focusing; record.seconds = 0; record.checkpoint = date; save()
    }
    func togglePause(at date: Date = .now) {
        tick(at: date)
        switch record.phase {
        case .focusing: record.phase = .pausedFocus
        case .resting: record.phase = .pausedRest
        case .pausedFocus: record.phase = .focusing
        case .pausedRest: record.phase = .resting
        case .ready: return
        }
        record.checkpoint = paused ? nil : date; save()
    }
    func nextFocus(at date: Date = .now) {
        guard resting else { return }
        record.phase = .focusing; record.seconds = 0; record.checkpoint = date; save()
    }
    func stop(at date: Date = .now) {
        tick(at: date); record.phase = .ready; record.seconds = 0; record.checkpoint = nil; save()
    }
    func tick(at date: Date = .now) {
        guard let checkpoint = record.checkpoint, !paused, active else { return }
        let elapsed = max(0, date.timeIntervalSince(checkpoint))
        let credit = min(elapsed, remaining)
        if record.phase == .focusing { creditTime(from: checkpoint, seconds: credit) }
        record.seconds += credit; record.checkpoint = date
        if remaining <= 0 {
            if record.phase == .focusing {
                record.completedMinutes = record.focusMinutes
                record.rewardIDs.append(UUID())
                record.phase = .resting
                record.seconds = min(TimeInterval(record.restMinutes * 60), elapsed - credit)
                if record.seconds >= TimeInterval(record.restMinutes * 60) {
                    record.phase = .pausedRest; record.checkpoint = nil
                }
            } else { record.phase = .pausedRest; record.checkpoint = nil }
        }
        save()
    }
    func claim(_ id: UUID) { record.rewardIDs.removeAll { $0 == id }; save() }
    private func creditTime(from start: Date, seconds: TimeInterval) {
        var cursor = start, left = seconds
        while left > 0 {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: cursor))!
            let interval = min(left, tomorrow.timeIntervalSince(cursor))
            record.daily[dayKey(cursor), default: 0] += interval
            cursor = cursor.addingTimeInterval(interval); left -= interval
        }
    }
    private func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }
    private func save() { if let data = try? JSONEncoder().encode(record) { defaults.set(data, forKey: key) } }
    static func clock(_ seconds: TimeInterval, hours: Bool = true) -> String {
        let n = max(0, Int(seconds))
        return hours ? String(format: "%02d:%02d:%02d", n / 3600, n / 60 % 60, n % 60) : String(format: "%02d:%02d", n / 60, n % 60)
    }
    static func summary(_ seconds: TimeInterval) -> String {
        let m = max(0, Int(seconds / 60))
        return m >= 60 ? "\(m / 60)시간 \(m % 60)분" : "\(m)분"
    }
}
