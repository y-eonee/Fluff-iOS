import Foundation

nonisolated struct YouTubeSource: Codable, Equatable, Identifiable {
    let videoID: String?
    let playlistID: String?
    var startSeconds: Int = 0
    var id: String { playlistID.map { "playlist:\($0)" } ?? "video:\(videoID ?? "")" }
    var isPlaylist: Bool { playlistID != nil }
    var fallbackTitle: String { isPlaylist ? "YouTube 플레이리스트" : "YouTube 영상" }
    var url: URL {
        var parts = URLComponents(string: "https://www.youtube.com/\(videoID == nil ? "playlist" : "watch")")!
        parts.queryItems = [videoID.map { URLQueryItem(name: "v", value: $0) },
                            playlistID.map { URLQueryItem(name: "list", value: $0) },
                            startSeconds > 0 ? URLQueryItem(name: "t", value: String(startSeconds)) : nil].compactMap { $0 }
        return parts.url!
    }
    static func parse(_ input: String) -> Self? {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.contains("://") { value = "https://" + value }
        guard let url = URLComponents(string: value), let host = url.host?.lowercased(),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              url.user == nil, url.password == nil, url.port == nil || url.port == 443,
              ["youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com", "youtu.be", "www.youtu.be", "www.youtube-nocookie.com", "youtube-nocookie.com"].contains(host)
        else { return nil }
        let query = url.queryItems ?? []
        func item(_ key: String) -> String? { query.first { $0.name == key }?.value }
        let path = url.path.split(separator: "/").map(String.init)
        var video: String?
        if host.hasSuffix("youtu.be") { video = path.first }
        else if path.first == "watch" { video = item("v") }
        else if path.count == 2 && ["shorts", "live", "embed", "v"].contains(path[0]) && path[1] != "videoseries" { video = path[1] }
        let playlist = item("list")
        guard video != nil || playlist != nil,
              video.map({ validID($0, lengths: 11...11) }) ?? true,
              playlist.map({ validID($0, lengths: 10...128) }) ?? true else { return nil }
        let seconds = parseTime(item("t") ?? item("start") ?? url.fragment?.replacingOccurrences(of: "t=", with: "") ?? "0")
        return Self(videoID: video, playlistID: playlist, startSeconds: seconds)
    }
    static func validID(_ value: String, lengths: ClosedRange<Int>) -> Bool {
        lengths.contains(value.count) && value.unicodeScalars.allSatisfy {
            (48...57).contains($0.value) || (65...90).contains($0.value) || (97...122).contains($0.value) || $0 == "_" || $0 == "-"
        }
    }
    private static func parseTime(_ text: String) -> Int {
        if let seconds = Int(text) { return min(86400, max(0, seconds)) }
        var result = 0, digits = ""
        for character in text {
            if character.isNumber { digits.append(character) }
            else {
                guard let value = Int(digits), let unit = ["h": 3600, "m": 60, "s": 1][String(character)], value <= 86400 else { return 0 }
                result += value * unit; digits = ""
            }
        }
        return digits.isEmpty ? min(86400, result) : 0
    }
}

nonisolated struct CouchVideo: Codable, Identifiable, Equatable {
    var source: YouTubeSource
    var title: String
    var thumbnailURL: URL?
    var videoCount: Int?
    var lastWatched: Date?
    var favorite = false
    var id: String { source.id }
}
