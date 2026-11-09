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

@MainActor @Observable
final class AmbientPlayer {
  static let shared = AmbientPlayer()
  private(set) var sound: AmbientSound?
  private var clock = AmbientPlaybackClock()
  var isPlaying: Bool { clock.isPlaying }
  var endDate: Date? { clock.endDate }
  var duration: TimeInterval? { clock.duration }
  private(set) var error: String?
  private var player: AVAudioPlayer?
  private var previewPlayer: AVAudioPlayer?
  private var previewTask: Task<Void, Never>?
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
  private func load(_ sound: AmbientSound) throws -> AVAudioPlayer {
    guard let url = Bundle.main.url(forResource: "ambient_\(sound.rawValue)", withExtension: "wav")
    else {
      throw CocoaError(.fileReadNoSuchFile)
    }
    let player = try AVAudioPlayer(contentsOf: url)
    player.numberOfLoops = -1
    player.volume = 0.55
    player.prepareToPlay()
    return player
  }
  private func activate() throws {
    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
    try AVAudioSession.sharedInstance().setActive(true)
  }
  func preview(_ sound: AmbientSound) {
    stopPreview()
    if isPlaying { player?.pause() }
    do {
      try activate()
      previewPlayer = try load(sound)
      guard previewPlayer?.play() == true else { throw CocoaError(.fileReadCorruptFile) }
      error = nil
      previewTask = Task { [weak self] in
        do { try await Task.sleep(for: .seconds(2.5)) } catch { return }
        self?.stopPreview()
      }
    } catch {
      stopPreview()
      self.error = "미리듣기를 시작하지 못했어요. 다시 눌러 주세요."
    }
  }
  func stopPreview() {
    previewTask?.cancel()
    previewTask = nil
    previewPlayer?.stop()
    previewPlayer = nil
    if isPlaying { player?.play() }
  }
  func start(_ sound: AmbientSound, minutes: Int?) {
    do {
      try activate()
      let next = try load(sound)
      guard next.play() else { throw CocoaError(.fileReadCorruptFile) }
      stopPreview()
      player?.stop()
      player = next
      self.sound = sound
      clock.start(minutes: minutes, at: .now)
      error = nil
      scheduleExpiry()
    } catch { self.error = "소리를 재생하지 못했어요. 다시 시도해 주세요." }
  }
  /// Replace only the audio; retain the timer and paused/running state.
  func changeSound(_ sound: AmbientSound) {
    guard self.sound != nil else { return }
    reconcile()
    guard self.sound != nil else { return }
    do {
      let next = try load(sound)
      if isPlaying {
        try activate()
        guard next.play() else { throw CocoaError(.fileReadCorruptFile) }
      }
      stopPreview()
      player?.stop()
      player = next
      self.sound = sound
      error = nil
    } catch { self.error = "소리를 바꾸지 못했어요. 다시 시도해 주세요." }
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
    guard isPlaying else { return }
    clock.pause(at: .now)
    expiryTask?.cancel()
    player?.pause()
  }
  func resume() {
    guard sound != nil else { return }
    do {
      try activate()
      guard player?.play() == true else { throw CocoaError(.fileReadCorruptFile) }
      clock.resume(at: .now)
      error = nil
      scheduleExpiry()
    } catch { self.error = "재생을 다시 시작하지 못했어요." }
  }
  func toggle() { if isPlaying { pause() } else { resume() } }
  func stop() {
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
  static func designPreview(paused: Bool) -> AmbientPlayer {
    let instance = AmbientPlayer()
    instance.start(.rain, minutes: 40)
    instance.player?.volume = 0
    instance.clock.start(minutes: 40, at: .now.addingTimeInterval(-1752))
    instance.scheduleExpiry()
    if paused { instance.pause() }
    return instance
  }
  #endif
}
