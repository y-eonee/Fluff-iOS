import Foundation
import GoogleSignIn
import Observation
import UIKit

@MainActor @Observable
final class YouTubeAccount {
    private(set) var playlists: [CouchVideo] = []
    private(set) var email: String?
    private(set) var isLoading = false
    var message: String?
    private var restored = false
    private let scope = "https://www.googleapis.com/auth/youtube.readonly"
    var isConnected: Bool { email != nil }
    private var clientID: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              value.hasSuffix(".apps.googleusercontent.com"), !value.hasPrefix("YOUR") else { return nil }
        return value
    }
    private func configure() -> Bool {
        guard let clientID else { return false }
        let expectedScheme = clientID.split(separator: ".").reversed().joined(separator: ".")
        let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
        guard types.contains(where: { ($0["CFBundleURLSchemes"] as? [String])?.contains(expectedScheme) == true }) else { return false }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        return true
    }
    func restore() async {
        guard !restored, configure() else { return }
        restored = true
        guard let user = try? await GIDSignIn.sharedInstance.restorePreviousSignIn(),
              user.grantedScopes?.contains(scope) == true else { return }
        email = user.profile?.email ?? "YouTube"
        await refresh()
    }
    func connect() async {
        guard !isLoading else { return }
        guard configure() else {
            message = "YouTube 계정 연결이 아직 설정되지 않았어요. 지금은 영상이나 플레이리스트 링크로 함께 볼 수 있어요."
            return
        }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }),
              var presenter = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        while let presented = presenter.presentedViewController { presenter = presented }
        isLoading = true; message = nil
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter, hint: nil, additionalScopes: [scope])
            guard result.user.grantedScopes?.contains(scope) == true else {
                message = "플레이리스트를 불러오려면 YouTube 읽기 권한을 허용해 주세요."
                isLoading = false; return
            }
            email = result.user.profile?.email ?? "YouTube"
            isLoading = false
            await refresh()
        } catch {
            isLoading = false
            if (error as NSError).code != GIDSignInError.canceled.rawValue {
                message = "계정을 연결하지 못했어요. 잠시 후 다시 시도해 주세요."
            }
        }
    }
    func refresh() async {
        guard !isLoading else { return }
        guard let current = GIDSignIn.sharedInstance.currentUser else {
            email = nil; playlists = []
            return
        }
        isLoading = true; message = nil
        defer { isLoading = false }
        do {
            let user = try await current.refreshTokensIfNeeded()
            guard user.grantedScopes?.contains(scope) == true else {
                email = nil; playlists = []
                message = "YouTube 읽기 권한이 없어요. 계정을 다시 연결해 주세요."
                return
            }
            var results: [CouchVideo] = [], page: String?
            var seen = Set<String>()
            repeat {
                var url = URLComponents(string: "https://www.googleapis.com/youtube/v3/playlists")!
                url.queryItems = [URLQueryItem(name: "part", value: "snippet,contentDetails"), URLQueryItem(name: "mine", value: "true"), URLQueryItem(name: "maxResults", value: "50")]
                if let page { url.queryItems?.append(URLQueryItem(name: "pageToken", value: page)) }
                var request = URLRequest(url: url.url!); request.timeoutInterval = 20
                request.setValue("Bearer \(user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let status = (response as? HTTPURLResponse)?.statusCode, status == 200 else {
                    let status = (response as? HTTPURLResponse)?.statusCode
                    if status == 401 {
                        GIDSignIn.sharedInstance.signOut()
                        email = nil; playlists = []
                    }
                    message = status == 401 ? "로그인이 만료됐어요. 계정을 다시 연결해 주세요." : "플레이리스트를 불러오지 못했어요. YouTube 접근 권한을 확인하고 다시 시도해 주세요."
                    return
                }
                let result = try JSONDecoder().decode(YouTubePlaylistPage.self, from: data)
                results.append(contentsOf: result.videos)
                page = result.nextPageToken
                if let page, !seen.insert(page).inserted { break }
            } while page != nil && !Task.isCancelled
            guard !Task.isCancelled else { return }
            playlists = results
        } catch { message = "연결 상태를 확인한 뒤 다시 불러와 주세요." }
    }
    func disconnect() async {
        guard !isLoading else { return }
        isLoading = true
        do {
            try await GIDSignIn.sharedInstance.disconnect()
            email = nil; playlists = []; message = nil
        } catch { message = "연결 해제에 실패했어요. 인터넷 연결을 확인하고 다시 시도해 주세요." }
        isLoading = false
    }
}
