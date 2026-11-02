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
  private(set) var isPlaying = false
  private(set) var endDate: Date?
  private(set) var duration: TimeInterval?
  private(set) var error: String?
  private var pausedRemaining: TimeInterval?
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
    endDate.map { max(0, $0.timeIntervalSince(date)) } ?? pausedRemaining
  }
  func timeLabel(at date: Date = .now) -> String {
    guard let remaining = remaining(at: date) else { return "계속" }
    let seconds = Int(remaining.rounded(.up))
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
  }
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
      previewPlayer?.play()
      previewTask = Task { [weak self] in
        do { try await Task.sleep(for: .seconds(2.5)) } catch { return }
        self?.stopPreview()
      }
    } catch { self.error = "미리듣기를 시작하지 못했어요. 다시 눌러 주세요." }
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
      isPlaying = true
      error = nil
      setTimer(minutes)
    } catch { self.error = "소리를 재생하지 못했어요. 다시 시도해 주세요." }
  }
  func setTimer(_ minutes: Int?) {
    duration = minutes.map { TimeInterval($0 * 60) }
    pausedRemaining = isPlaying ? nil : duration
    endDate = isPlaying ? duration.map { Date.now.addingTimeInterval($0) } : nil
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
    pausedRemaining = remaining()
    endDate = nil
    expiryTask?.cancel()
    player?.pause()
    isPlaying = false
  }
  func resume() {
    guard sound != nil else { return }
    do {
      try activate()
      guard player?.play() == true else { throw CocoaError(.fileReadCorruptFile) }
      isPlaying = true
      endDate = pausedRemaining.map { Date.now.addingTimeInterval($0) }
      pausedRemaining = nil
      scheduleExpiry()
    } catch { self.error = "재생을 다시 시작하지 못했어요." }
  }
  func toggle() { if isPlaying { pause() } else { resume() } }
  func stop() {
    expiryTask?.cancel()
    player?.stop()
    player = nil
    sound = nil
    isPlaying = false
    endDate = nil
    pausedRemaining = nil
    duration = nil
  }
  func reconcile() { if let endDate, endDate <= .now { stop() } }
}
