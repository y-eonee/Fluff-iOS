import Foundation

@main struct YouTubePrivacyChecks {
    static func main() {
        var checks = 0
        func check(_ valid: Bool, _ message: String) {
            precondition(valid, message)
            checks += 1
        }
        for input in ["https://youtu.be/M7lc1UVf-VE?t=90", "https://www.youtube.com/playlist?list=PLBCF2DAC6FFB574DE",
                      "https://www.youtube.com/watch?v=M7lc1UVf-VE&list=PLBCF2DAC6FFB574DE&start=32"] {
            let source = YouTubeSource.parse(input)!
            let url = YouTubeEmbedPolicy.embedURL(for: source)
            let parts = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            let query = Dictionary(uniqueKeysWithValues: parts.queryItems!.map { ($0.name, $0.value!) })
            check(parts.host == "www.youtube-nocookie.com", "every source uses privacy host")
            check(parts.path == "/embed/" + (source.videoID ?? "videoseries"), "video and playlist routes")
            check(query["list"] == source.playlistID, "playlist retained")
            check(query["start"] == String(source.startSeconds), "start time retained")
            check(query["autoplay"] == "0" && query["enablejsapi"] == "1", "no pre-play autoplay")
            check(query["origin"] == YouTubeEmbedPolicy.origin, "app identity retained")
            check(query.keys.allSatisfy { ["list", "start", "origin", "autoplay", "enablejsapi", "playsinline", "controls", "rel"].contains($0) }, "no account/token/device identifiers")
        }
        func route(_ url: String, main: Bool = false, popup: Bool = false, link: Bool = false) -> YouTubeEmbedPolicy.Navigation {
            YouTubeEmbedPolicy.navigation(to: URL(string: url), mainFrame: main, newWindow: popup, userLink: link)
        }
        for url in ["https://www.youtube.com/watch?v=M7lc1UVf-VE", "https://m.youtube.com/@YouTube",
                    "https://www.youtube.com/embed/M7lc1UVf-VE", "https://accounts.google.com/ServiceLogin",
                    "https://consent.google.com/m", "https://youtu.be/M7lc1UVf-VE"] {
            check(route(url, link: true) == .external, "outbound link external")
            check(route(url, main: true, link: true) == .external, "main-frame link external")
            check(route(url, popup: true) == .external, "new window external")
            check(route(url) == .cancel, "no automatic downgrade/account navigation")
            check(route(url, main: true) == .cancel, "no redirect replaces wrapper")
        }
        for url in ["javascript:alert(1)", "file:///etc/passwd", "data:text/html,test", "https://name:password@youtube.com/watch"] {
            check(route(url, link: true) == .cancel, "unsafe URL blocked")
            check(route(url, popup: true) == .cancel, "unsafe popup blocked")
        }
        check(route("about:blank", main: true) == .allow, "HTML wrapper allowed")
        check(route("https://www.youtube-nocookie.com/embed/M7lc1UVf-VE") == .allow, "privacy iframe allowed")
        check(route("http://www.youtube-nocookie.com/embed/M7lc1UVf-VE") == .cancel, "no insecure embed")
        check(route("https://www.youtube-nocookie.com/watch?v=M7lc1UVf-VE") == .cancel, "no ordinary page in privacy host")
        check(route("https://www.google.com/pagead/ad-frame") == .allow, "provider ad subframes not blocked")
        check(route("https://example.com/ad-landing", link: true) == .external, "ad links external")
        print("PASS: \(checks) privacy embed URL and navigation checks")
    }
}
