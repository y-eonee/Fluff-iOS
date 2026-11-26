import Foundation

/// Only the isolated, privacy-enhanced embed stays inside the app. Ordinary
/// YouTube/account pages must not replace it, including in child/new frames.
nonisolated enum YouTubeEmbedPolicy {
    static let origin = "https://" + (Bundle.main.bundleIdentifier ?? "com.nayeon.Malrang").lowercased()
    enum Navigation: Equatable { case allow, external, cancel }

    static func embedURL(for source: YouTubeSource) -> URL {
        var url = URLComponents(string: "https://www.youtube-nocookie.com")!
        url.path = "/embed/" + (source.videoID ?? "videoseries")
        url.queryItems = [
            .init(name: "enablejsapi", value: "1"), .init(name: "playsinline", value: "1"),
            .init(name: "controls", value: "1"), .init(name: "rel", value: "0"),
            .init(name: "autoplay", value: "0"), .init(name: "origin", value: origin),
            .init(name: "start", value: String(source.startSeconds))
        ]
        if let playlist = source.playlistID { url.queryItems?.append(.init(name: "list", value: playlist)) }
        return url.url!
    }

    static func navigation(to url: URL?, mainFrame: Bool, newWindow: Bool, userLink: Bool) -> Navigation {
        guard let url else { return .cancel }
        if url.absoluteString == "about:blank" { return newWindow ? .cancel : .allow }
        guard let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme),
              url.user == nil, url.password == nil, let host = url.host?.lowercased() else { return .cancel }
        let privacyHost = host == "www.youtube-nocookie.com" || host == "youtube-nocookie.com"
        let embed = scheme == "https" && privacyHost && url.path.hasPrefix("/embed/")
        // A user's link or window.open belongs in the system browser, not in
        // another in-app browser. Do not launch external apps for redirects.
        if newWindow || userLink { return .external }
        if mainFrame {
            return url.absoluteString == origin || url.absoluteString == origin + "/" ? .allow : .cancel
        }
        if embed { return .allow }
        if privacyHost || host == "youtube.com" || host.hasSuffix(".youtube.com")
            || host == "youtu.be" || host == "accounts.google.com" || host == "consent.google.com" {
            return .cancel
        }
        // Keep the provider's media/ad subframes functional. This is navigation
        // isolation, not an ad/content blocker or a filter on media requests.
        return .allow
    }
}
