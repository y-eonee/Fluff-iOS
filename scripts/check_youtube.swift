import Foundation

@main
struct YouTubeAudit {
    @MainActor static func main() {
        let video = "M7lc1UVf-VE"
        let playlist = "PL1234567890abcdef"
        let cases: [(String, String?, String?, Int)] = [
            ("https://youtu.be/\(video)?t=1m12s", video, nil, 72),
            ("youtube.com/watch?v=\(video)&list=\(playlist)&t=90", video, playlist, 90),
            ("https://www.youtube.com/playlist?list=\(playlist)", nil, playlist, 0),
            ("https://www.youtube.com/shorts/\(video)", video, nil, 0),
            ("https://www.youtube.com/live/\(video)#t=2m", video, nil, 120),
            ("https://www.youtube-nocookie.com/embed/videoseries?list=\(playlist)", nil, playlist, 0),
            (" https://m.youtube.com/watch?v=\(video)&start=999999 ", video, nil, 86400)
        ]
        for (input, id, list, seconds) in cases {
            let parsed = YouTubeSource.parse(input)
            precondition(parsed?.videoID == id && parsed?.playlistID == list && parsed?.startSeconds == seconds, input)
            precondition(YouTubeSource.parse(parsed!.url.absoluteString)?.id == parsed!.id)
        }
        for input in ["https://youtube.com.evil.test/watch?v=\(video)", "https://evil.test/?list=\(playlist)", "javascript:alert(1)", "https://user@youtube.com/watch?v=\(video)", "https://youtube.com:9000/watch?v=\(video)", "https://youtu.be/short", "https://youtube.com/watch?v=bad%22id12345", "https://youtube.com/playlist?list=bad", ""] {
            precondition(YouTubeSource.parse(input) == nil, "Rejected input: \(input)")
        }
        let pageJSON = #"{"items":[{"id":"PL1234567890abcdef","snippet":{"title":"내 플레이리스트","thumbnails":{"medium":{"url":"https://i.ytimg.com/vi/M7lc1UVf-VE/mqdefault.jpg"}}},"contentDetails":{"itemCount":12}},{"id":"PLabcdef1234567890","snippet":{"title":"빈 목록"},"contentDetails":{"itemCount":0}}],"nextPageToken":"next-page"}"#
        let page = try! JSONDecoder().decode(YouTubePlaylistPage.self, from: Data(pageJSON.utf8))
        precondition(page.nextPageToken == "next-page" && page.videos.count == 2)
        precondition(page.videos[0].videoCount == 12 && page.videos[0].title == "내 플레이리스트")
        precondition(page.videos[1].thumbnailURL == nil && page.videos[1].videoCount == 0)
        let domain = "malrang.youtube.audit.\(UUID())"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let library = CouchLibrary(defaults: defaults)
        let source = YouTubeSource.parse(cases[0].0)!
        let first = library.add(source, title: "테스트 영상")
        _ = library.add(source)
        precondition(library.videos.count == 1)
        _ = library.add(source, title: "재생 중 확인한 제목")
        precondition(library.videos.first?.title == "재생 중 확인한 제목")
        library.record(first)
        library.toggleFavorite(first)
        let restored = CouchLibrary(defaults: defaults)
        precondition(restored.videos.first?.title == "재생 중 확인한 제목")
        precondition(restored.videos.first?.lastWatched != nil && restored.favorite(first))
        restored.toggleFavorite(first)
        precondition(!restored.favorite(first))
        restored.remove(first)
        precondition(CouchLibrary(defaults: defaults).videos.isEmpty)
        print("YouTube URL validation, identity deduplication, history and favorites persistence, paginated playlist decoding passed")
    }
}
