#if DEBUG
import Foundation
import UIKit
import WebKit

@MainActor enum YouTubePrivacyAudit {
    static func run() async {
        var checks: [[String: Any]] = []
        var live: [[String: Any]] = []
        func check(_ passed: Bool, _ name: String) { checks.append(["name": name, "passed": passed]) }
        let player = YouTubePlayer()
        let web = player.webView
        web.configuration.userContentController.addUserScript(WKUserScript(source: "window.auditErrors=[];window.addEventListener('error',e=>window.auditErrors.push(e.message || 'resource load error'),true)", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        web.frame = CGRect(x: 0, y: 100, width: 390, height: 300)
        let window = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first { $0.isKeyWindow }
        window?.addSubview(web)
        defer { player.stop(); web.removeFromSuperview() }
        check(!web.configuration.websiteDataStore.isPersistent, "isolated nonpersistent browser")
        var external: [URL] = []
        player.openExternalURL = { external.append($0) }
        // Exercise WKNavigationDelegate and WKUIDelegate, not just the URL classifier.
        for (name, markup, script) in [
            ("same-frame link", "<a id='out' href='https://www.youtube.com/watch?v=M7lc1UVf-VE'>open</a>", "document.getElementById('out').click()"),
            ("new-window link", "<a id='out' target='_blank' href='https://www.youtube.com/@YouTube'>open</a>", "document.getElementById('out').click()"),
            ("child-frame account link", "<iframe id='child'></iframe>", "let d=document.getElementById('child').contentDocument;d.body.innerHTML=\"<a id='out' href='https://accounts.google.com/ServiceLogin'>open</a>\";d.getElementById('out').click()")
        ] {
            external = []
            web.loadHTMLString("<html><head><title>isolation fixture</title></head><body>\(markup)</body></html>", baseURL: URL(string: YouTubeEmbedPolicy.origin))
            for _ in 0..<40 {
                if (try? await web.evaluateJavaScript("document.title")) as? String == "isolation fixture", !web.isLoading { break }
                try? await Task.sleep(for: .milliseconds(100))
            }
            _ = try? await web.evaluateJavaScript(script)
            for _ in 0..<30 {
                if !external.isEmpty { break }
                try? await Task.sleep(for: .milliseconds(100))
            }
            check(external.count == 1, name + " opens externally once")
            check((try? await web.evaluateJavaScript("document.title")) as? String == "isolation fixture", name + " preserves wrapper")
        }
        for source in [YouTubeSource(videoID: "M7lc1UVf-VE", playlistID: nil),
                       YouTubeSource(videoID: nil, playlistID: "PLBCF2DAC6FFB574DE")] {
            player.load(source)
            for _ in 0..<100 {
                if player.ready || player.error != nil { break }
                try? await Task.sleep(for: .milliseconds(250))
            }
            let src = (try? await web.evaluateJavaScript("document.getElementById('player')?.src || ''")) as? String ?? ""
            check(URL(string: src)?.host == "www.youtube-nocookie.com", "actual iframe uses privacy host: \(source.id)")
            let initiallyPlaying = player.playing
            let diagnostics = (try? await web.evaluateJavaScript("JSON.stringify({api:typeof YT,loaded:typeof YT==='undefined'?false:YT.loaded,player:typeof player,errors:window.auditErrors,resources:performance.getEntriesByType('resource').map(x=>({host:new URL(x.name).host,type:x.initiatorType,duration:x.duration}))})")) as? String ?? ""
            var advanced = false
            if player.ready {
                _ = try? await web.evaluateJavaScript("player.mute()")
                player.toggle()
                for _ in 0..<40 {
                    if player.elapsed > 1 { advanced = true; break }
                    if player.error != nil { break }
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
            player.pause()
            live.append(["source": source.id, "ready": player.ready, "autoplay": initiallyPlaying,
                         "timeAdvanced": advanced, "playlistCount": player.count, "error": player.error ?? "", "diagnostics": diagnostics])
        }
        player.stop()
        check(!player.hasLoadedWebView, "stop releases player after external navigation and source changes")
        let result: [String: Any] = ["checks": checks, "livePlayback": live,
            "navigations": player.auditNavigations,
            "isolationPassed": checks.allSatisfy { $0["passed"] as? Bool == true },
            "livePlaybackPassed": live.allSatisfy { $0["ready"] as? Bool == true && $0["timeAdvanced"] as? Bool == true && $0["autoplay"] as? Bool == false }]
        if let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL.documentsDirectory.appending(path: "youtube-privacy-audit.json"), options: .atomic)
        }
    }
}
#endif
