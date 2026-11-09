import Foundation

/// Active listening time and the independent, editable auto-stop countdown.
nonisolated struct AmbientPlaybackClock {
    private(set) var isPlaying = false
    private(set) var duration: TimeInterval?
    private(set) var endDate: Date?
    private var pausedRemaining: TimeInterval?
    private var accumulated: TimeInterval = 0
    private var resumedAt: Date?

    func remaining(at date: Date) -> TimeInterval? {
        endDate.map { max(0, $0.timeIntervalSince(date)) } ?? pausedRemaining
    }

    func elapsed(at date: Date) -> TimeInterval {
        guard let resumedAt else { return accumulated }
        let until = min(date, endDate ?? date)
        return accumulated + max(0, until.timeIntervalSince(resumedAt))
    }

    func progress(at date: Date) -> Double {
        guard let duration, duration > 0, let remaining = remaining(at: date) else { return 1 }
        return min(1, max(0, 1 - remaining / duration))
    }

    mutating func start(minutes: Int?, at date: Date) {
        self = Self()
        isPlaying = true
        resumedAt = date
        setTimer(minutes, at: date)
    }

    mutating func setTimer(_ minutes: Int?, at date: Date) {
        // Changing the countdown must not reset accumulated listening time.
        accumulated = elapsed(at: date)
        resumedAt = isPlaying ? date : nil
        duration = minutes.map { TimeInterval(max(1, $0) * 60) }
        pausedRemaining = isPlaying ? nil : duration
        endDate = isPlaying ? duration.map { date.addingTimeInterval($0) } : nil
    }

    mutating func pause(at date: Date) {
        guard isPlaying else { return }
        accumulated = elapsed(at: date)
        pausedRemaining = remaining(at: date)
        resumedAt = nil
        endDate = nil
        isPlaying = false
    }

    mutating func resume(at date: Date) {
        guard !isPlaying else { return }
        isPlaying = true
        resumedAt = date
        endDate = pausedRemaining.map { date.addingTimeInterval($0) }
        pausedRemaining = nil
    }
}
