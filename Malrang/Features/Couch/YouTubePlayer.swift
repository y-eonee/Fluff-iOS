import Observation
import SwiftUI
import WebKit

/// One retained player moves between the watching screen and the room without reloading.
@MainActor @Observable
final class YouTubePlayer: NSObject {
    private(set) var ready = false
    private(set) var playing = false
    private(set) var elapsed: Double = 0
    private(set) var duration: Double = 0
    private(set) var title = ""
    private(set) var index = 0
    private(set) var count = 0
    private(set) var error: String?
    private(set) var source: YouTubeSource?
    private var timeout: Task<Void, Never>?
    private var mayPlay = true
    private var recordedVideoID: String?
    @ObservationIgnored var onVideoStarted: ((String, String) -> Void)?
    @ObservationIgnored private var bridge: PlayerMessageBridge?
    @ObservationIgnored private var loadedWebView: WKWebView?
    var hasLoadedWebView: Bool { loadedWebView != nil }
    var webView: WKWebView {
        if let loadedWebView { return loadedWebView }
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsPictureInPictureMediaPlayback = false
        let bridge = PlayerMessageBridge(owner: self)
        self.bridge = bridge
        configuration.userContentController.add(bridge, name: "player")
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.isOpaque = false; view.backgroundColor = .black
        view.scrollView.isScrollEnabled = false
        view.navigationDelegate = self
        loadedWebView = view
        return view
    }
    func load(_ source: YouTubeSource) {
        self.source = source; ready = false; playing = false; error = nil
        elapsed = 0; duration = 0; title = ""; index = 0; count = 0; mayPlay = true; recordedVideoID = nil
        let origin = "https://" + (Bundle.main.bundleIdentifier ?? "com.nayeon.Malrang").lowercased()
        var vars: [String: Any] = ["playsinline": 1, "controls": 1, "rel": 0, "origin": origin, "start": source.startSeconds]
        if let playlist = source.playlistID { vars["listType"] = "playlist"; vars["list"] = playlist }
        let settings: [String: Any] = ["width": "100%", "height": "100%", "videoId": source.videoID ?? "", "playerVars": vars]
        let json = String(data: try! JSONSerialization.data(withJSONObject: settings), encoding: .utf8)!
        // A base URL supplies the app's Referer identity for locally loaded embedded HTML.
        webView.loadHTMLString("""
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1"><meta name="referrer" content="strict-origin-when-cross-origin"><style>html,body,#player{margin:0;width:100%;height:100%;overflow:hidden;background:#000}</style></head><body><div id="player"></div><script>
        let player; let allowed=true;
        function send(o){window.webkit.messageHandlers.player.postMessage(o)}
        function state(){if(!player || !player.getVideoData)return;let d=player.getVideoData(),l=player.getPlaylist();send({type:'state',playing:player.getPlayerState()===1,time:player.getCurrentTime()||0,duration:player.getDuration()||0,title:d.title||'',videoID:d.video_id||'',index:player.getPlaylistIndex()||0,count:l?l.length:0})}
        function onYouTubeIframeAPIReady(){let c=\(json);c.events={onReady:function(){send({type:'ready'});if(allowed)player.playVideo();state()},onStateChange:function(e){if(e.data===1&&!allowed)player.pauseVideo();state()},onError:function(e){send({type:'error',code:e.data})},onAutoplayBlocked:function(){send({type:'blocked'})}};player=new YT.Player('player',c)}
        setInterval(state,750);
        </script><script src="https://www.youtube.com/iframe_api"></script></body></html>
        """, baseURL: URL(string: origin))
        timeout?.cancel()
        timeout = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(20)) } catch { return }
            guard let self, !ready else { return }
            error = "영상을 불러오지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요."
        }
    }
    func toggle() { if playing { pause() } else { mayPlay = true; command("allowed=true;player.playVideo()") } }
    func pause() { mayPlay = false; command("allowed=false;player.pauseVideo()"); playing = false }
    func previous() { command("player.previousVideo()") }
    func next() { command("player.nextVideo()") }
    func stop() {
        timeout?.cancel(); timeout = nil
        pause(); source = nil; ready = false
        // Pause/stop must never create a browser for a user who has not played
        // a video. Release the actual player when watching is explicitly ended.
        loadedWebView?.stopLoading()
        loadedWebView?.configuration.userContentController.removeScriptMessageHandler(forName: "player")
        loadedWebView?.navigationDelegate = nil
        loadedWebView?.loadHTMLString("", baseURL: nil)
        loadedWebView?.removeFromSuperview()
        loadedWebView = nil
        bridge = nil
    }
    private func command(_ js: String) { loadedWebView?.evaluateJavaScript("try{\(js)}catch(e){}", completionHandler: nil) }
    fileprivate func receive(_ body: Any) {
        guard let value = body as? [String: Any], source != nil else { return }
        switch value["type"] as? String {
        case "ready": ready = true; timeout?.cancel(); if !mayPlay { pause() }
        case "state":
            playing = value["playing"] as? Bool ?? false
            elapsed = value["time"] as? Double ?? 0; duration = value["duration"] as? Double ?? 0
            title = value["title"] as? String ?? ""; index = value["index"] as? Int ?? 0; count = value["count"] as? Int ?? 0
            if playing {
                error = nil
                if !mayPlay { pause() }
                else if let id = value["videoID"] as? String, YouTubeSource.validID(id, lengths: 11...11), id != recordedVideoID {
                    recordedVideoID = id; onVideoStarted?(id, title)
                }
            }
        case "blocked": playing = false
        case "error":
            timeout?.cancel(); playing = false
            let code = value["code"] as? Int ?? 0
            error = [100,101,150].contains(code) ? "이 영상은 앱 안에서 재생할 수 없어요. YouTube에서 열거나 다른 영상을 골라 주세요." : "영상을 재생하지 못했어요. 다시 시도하거나 YouTube에서 열어 주세요."
        default: break
        }
    }
}

@MainActor private final class PlayerMessageBridge: NSObject, WKScriptMessageHandler {
    weak var owner: YouTubePlayer?
    init(owner: YouTubePlayer) { self.owner = owner }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame else { return }
        owner?.receive(message.body)
    }
}
extension YouTubePlayer: WKNavigationDelegate {
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        ready = false; playing = false; error = "재생이 중단됐어요. 다시 시도해 주세요."
    }
}

struct YouTubePlayerView: UIViewRepresentable {
    let player: YouTubePlayer
    func makeUIView(context: Context) -> UIView { UIView() }
    func updateUIView(_ view: UIView, context: Context) {
        let web = player.webView
        guard web.superview !== view else { return }
        web.removeFromSuperview(); web.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(web)
        NSLayoutConstraint.activate([web.leadingAnchor.constraint(equalTo: view.leadingAnchor),web.trailingAnchor.constraint(equalTo: view.trailingAnchor),web.topAnchor.constraint(equalTo: view.topAnchor),web.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }
    static func dismantleUIView(_ view: UIView, coordinator: ()) {
        view.subviews.forEach { $0.removeFromSuperview() }
    }
}
