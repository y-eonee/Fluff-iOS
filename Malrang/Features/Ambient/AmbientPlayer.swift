import AVFoundation
import Observation

nonisolated enum AmbientSound: String, CaseIterable, Identifiable {
  case rain, fire, wave, forest, cafe, noise
  var id: String { rawValue }
  var title: String {
    switch self {
    case .rain: "빗소리"
    case .fire: "모닥불"
    case .wave: "파도"
    case .forest: "숲속"
    case .cafe: "카페"
    case .noise: "백색소음"
    }
  }
}

/// AVAudioPlayer can activate the session internally in prepare/play. Keep all
/// player operations on one serial queue, including pauses that race a start.
nonisolated private final class AmbientAudioTrack: @unchecked Sendable {
  private static let queue = DispatchQueue(label: "com.nayeon.Malrang.ambient-audio", qos: .userInitiated)
  private let audio: AVAudioPlayer
  private init(_ audio: AVAudioPlayer) { self.audio = audio }
  static func load(_ sound: AmbientSound) async throws -> AmbientAudioTrack {
    try await withCheckedThrowingContinuation { continuation in
      queue.async {
        do {
          guard let url = Bundle.main.url(forResource: "ambient_\(sound.rawValue)", withExtension: "wav") else { throw CocoaError(.fileReadNoSuchFile) }
          let audio = try AVAudioPlayer(contentsOf: url)
          audio.numberOfLoops = -1
          audio.volume = 0.55
          audio.prepareToPlay()
          continuation.resume(returning: AmbientAudioTrack(audio))
        } catch { continuation.resume(throwing: error) }
      }
    }
  }
  func play() async -> Bool {
    await withCheckedContinuation { continuation in
      Self.queue.async { continuation.resume(returning: self.audio.play()) }
    }
  }
  func resume() { Self.queue.async { self.audio.play() } }
  func pause() { Self.queue.async { self.audio.pause() } }
  func stop() { Self.queue.async { self.audio.stop() } }
  func mute() { Self.queue.async { self.audio.volume = 0 } }
}

@MainActor @Observable
final class AmbientPlayer {
  static let shared = AmbientPlayer()
  private(set) var sound: AmbientSound?
  private var clock = AmbientPlaybackClock()
  var isPlaying: Bool { clock.isPlaying }
  var endDate: Date? { clock.endDate }
  var duration: TimeInterval? { clock.duration }
  private(set) var error: String?
  private var player: AmbientAudioTrack?
  private var previewPlayer: AmbientAudioTrack?
  private var previewTask: Task<Void, Never>?
  private var playbackTask: Task<Void, Never>?
  private var expiryTask: Task<Void, Never>?
  private var interruption: NSObjectProtocol?
  private var shouldResume = false

  init() {
    interruption = NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
    ) { [weak self] notification in
      let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
      let options = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
      Task { @MainActor [weak self] in
        guard let self else { return }
        if type == AVAudioSession.InterruptionType.began.rawValue {
          self.shouldResume = self.isPlaying
          self.pause()
        } else if self.shouldResume
          && AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume)
        {
          self.resume()
          self.shouldResume = false
        }
      }
    }
  }

  func remaining(at date: Date = .now) -> TimeInterval? {
    clock.remaining(at: date)
  }
  func timeLabel(at date: Date = .now) -> String {
    guard let remaining = remaining(at: date) else { return "계속" }
    let seconds = Int(remaining.rounded(.up))
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
  }
  func elapsedLabel(at date: Date = .now) -> String {
    let seconds = Int(clock.elapsed(at: date))
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
  }
  func progress(at date: Date = .now) -> Double { clock.progress(at: date) }
  nonisolated private static func activate() async throws {
    try await Task.detached(priority: .userInitiated) {
      let session = AVAudioSession.sharedInstance()
      if session.category != .playback || session.mode != .default {
        try session.setCategory(.playback, mode: .default)
      }
      if #available(iOS 27.0, *) {
        guard try await session.activate() else { throw CocoaError(.featureUnsupported) }
      } else {
        try session.setActive(true)
      }
    }.value
  }
  func preview(_ sound: AmbientSound) {
    stopPreview()
    if isPlaying { player?.pause() }
    previewTask = Task { [weak self] in
      do {
        try await Self.activate()
        try Task.checkCancellation()
        guard let self else { return }
        let next = try await AmbientAudioTrack.load(sound)
        try Task.checkCancellation()
        guard await next.play() else { throw CocoaError(.fileReadCorruptFile) }
        if Task.isCancelled { next.stop(); return }
        self.previewPlayer = next
        self.error = nil
        try await Task.sleep(for: .seconds(2.5))
        self.stopPreview()
      } catch is CancellationError { }
      catch {
        guard !Task.isCancelled, let self else { return }
        self.stopPreview()
        self.error = "미리듣기를 시작하지 못했어요. 다시 눌러 주세요."
      }
    }
  }
  func stopPreview() {
    previewTask?.cancel()
    previewTask = nil
    previewPlayer?.stop()
    previewPlayer = nil
    if isPlaying { player?.resume() }
  }
  func start(_ sound: AmbientSound, minutes: Int?) {
    playbackTask?.cancel()
    stopPreview()
    playbackTask = Task { [weak self] in
      do {
        try await Self.activate()
        try Task.checkCancellation()
        guard let self else { return }
        let next = try await AmbientAudioTrack.load(sound)
        try Task.checkCancellation()
        guard await next.play() else { throw CocoaError(.fileReadCorruptFile) }
        if Task.isCancelled { next.stop(); return }
        self.player?.stop()
        self.player = next
        self.sound = sound
        self.clock.start(minutes: minutes, at: .now)
        self.error = nil
        self.scheduleExpiry()
      } catch is CancellationError { }
      catch {
        if !Task.isCancelled { self?.error = "소리를 재생하지 못했어요. 다시 시도해 주세요." }
      }
    }
  }
  /// Replace only the audio; retain the timer and paused/running state.
  func changeSound(_ sound: AmbientSound) {
    reconcile()
    guard self.sound != nil else { return }
    playbackTask?.cancel()
    stopPreview()
    playbackTask = Task { [weak self] in
      do {
        try await Self.activate()
        try Task.checkCancellation()
        guard let self, self.sound != nil else { return }
        self.reconcile()
        guard self.sound != nil else { return }
        let next = try await AmbientAudioTrack.load(sound)
        try Task.checkCancellation()
        if self.isPlaying, await !next.play() { throw CocoaError(.fileReadCorruptFile) }
        if Task.isCancelled { next.stop(); return }
        self.player?.stop()
        self.player = next
        self.sound = sound
        self.error = nil
      } catch is CancellationError { }
      catch {
        if !Task.isCancelled { self?.error = "소리를 바꾸지 못했어요. 다시 시도해 주세요." }
      }
    }
  }
  func setTimer(_ minutes: Int?) {
    reconcile()
    guard sound != nil else { return }
    clock.setTimer(minutes, at: .now)
    error = nil
    scheduleExpiry()
  }
  private func scheduleExpiry() {
    expiryTask?.cancel()
    expiryTask = nil
    guard let endDate, isPlaying else { return }
    expiryTask = Task { [weak self] in
      do { try await Task.sleep(for: .seconds(max(0, endDate.timeIntervalSinceNow))) } catch {
        return
      }
      self?.stop()
    }
  }
  func pause() {
    playbackTask?.cancel()
    guard isPlaying else { return }
    clock.pause(at: .now)
    expiryTask?.cancel()
    player?.pause()
  }
  func resume() {
    guard sound != nil else { return }
    playbackTask?.cancel()
    playbackTask = Task { [weak self] in
      do {
        try await Self.activate()
        try Task.checkCancellation()
        guard let self, self.sound != nil else { return }
        guard await self.player?.play() == true else { throw CocoaError(.fileReadCorruptFile) }
        try Task.checkCancellation()
        self.clock.resume(at: .now)
        self.error = nil
        self.scheduleExpiry()
      } catch is CancellationError { }
      catch {
        if !Task.isCancelled { self?.error = "재생을 다시 시작하지 못했어요." }
      }
    }
  }
  func toggle() { if isPlaying { pause() } else { resume() } }
  func stop() {
    playbackTask?.cancel(); playbackTask = nil
    clock = AmbientPlaybackClock()
    stopPreview()
    expiryTask?.cancel()
    player?.stop()
    player = nil
    sound = nil
    error = nil
  }
  func reconcile() { if let endDate, endDate <= .now { stop() } }

  #if DEBUG
  func waitForPlayback() async { await playbackTask?.value }

  static func designPreview(paused: Bool) -> AmbientPlayer {
    let instance = AmbientPlayer()
    instance.sound = .rain
    Task {
      let track = try? await AmbientAudioTrack.load(.rain)
      track?.mute()
      instance.player = track
    }
    instance.clock.start(minutes: 40, at: .now.addingTimeInterval(-1752))
    instance.scheduleExpiry()
    if paused { instance.pause() }
    return instance
  }
  #endif
}
