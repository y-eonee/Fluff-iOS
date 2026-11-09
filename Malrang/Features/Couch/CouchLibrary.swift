import Foundation
import Observation

@MainActor @Observable
final class CouchLibrary {
    private(set) var videos: [CouchVideo]
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        videos = defaults.data(forKey: "couch.videoLibrary").flatMap { try? JSONDecoder().decode([CouchVideo].self, from: $0) } ?? []
    }
    @discardableResult func add(_ source: YouTubeSource, title: String? = nil) -> CouchVideo {
        if let index = videos.firstIndex(where: { $0.id == source.id }) {
            if let title, !title.isEmpty, videos[index].title != title { videos[index].title = title; save() }
            return videos[index]
        }
        let video = CouchVideo(source: source, title: title ?? source.fallbackTitle,
                               thumbnailURL: source.videoID.flatMap { URL(string: "https://i.ytimg.com/vi/\($0)/mqdefault.jpg") })
        videos.insert(video, at: 0); save(); return video
    }
    func record(_ video: CouchVideo) {
        var value = videos.first(where: { $0.id == video.id }) ?? video
        value.lastWatched = .now
        videos.removeAll { $0.id == value.id }; videos.insert(value, at: 0); save()
    }
    func favorite(_ video: CouchVideo) -> Bool { videos.first { $0.id == video.id }?.favorite ?? false }
    func toggleFavorite(_ video: CouchVideo) {
        if !videos.contains(where: { $0.id == video.id }) { _ = add(video.source, title: video.title) }
        if let index = videos.firstIndex(where: { $0.id == video.id }) { videos[index].favorite.toggle(); save() }
    }
    func remove(_ video: CouchVideo) { videos.removeAll { $0.id == video.id }; save() }
    private func save() {
        videos = Array(videos.prefix(100))
        if let data = try? JSONEncoder().encode(videos) { defaults.set(data, forKey: "couch.videoLibrary") }
    }
    func resolveTitle(for source: YouTubeSource) async {
        var endpoint = URLComponents(string: "https://www.youtube.com/oembed")!
        endpoint.queryItems = [URLQueryItem(name: "url", value: source.url.absoluteString), URLQueryItem(name: "format", value: "json")]
        do {
            var request = URLRequest(url: endpoint.url!); request.timeoutInterval = 12
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let result = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let title = result["title"] as? String, !title.isEmpty,
                  let index = videos.firstIndex(where: { $0.id == source.id }) else { return }
            videos[index].title = title
            save()
        } catch { /* A valid link remains usable if metadata is temporarily unavailable. */ }
    }
}
