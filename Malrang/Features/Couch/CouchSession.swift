import Foundation
import Observation

@MainActor @Observable
final class CouchSession {
    let player = YouTubePlayer()
    let account = YouTubeAccount()
    let library: CouchLibrary
    var dolls: [DollState] = []
    var sofaID: UUID?
    var current: CouchVideo?
    var choosing = true
    var resting = false
    var onActivityStarted: (([UUID]) -> Void)?
    private var recordedActivity = false
    init(library: CouchLibrary? = nil) {
        self.library = library ?? CouchLibrary()
        player.onVideoStarted = { [weak self] id, title in
            guard let self else { return }
            if !self.recordedActivity {
                self.recordedActivity = true
                self.onActivityStarted?(self.dolls.map(\.id))
            }
            let source = YouTubeSource(videoID: id, playlistID: nil)
            let video = self.library.add(source, title: title.isEmpty ? nil : title)
            self.library.record(video)
        }
    }
    func watch(_ video: CouchVideo) {
        resting = false; choosing = false; current = video
        library.record(video)
        player.load(video.source)
        if AmbientPlayer.shared.isPlaying { AmbientPlayer.shared.pause() }
    }
    func stop() { player.stop(); current = nil; choosing = true; resting = false; recordedActivity = false }
}
