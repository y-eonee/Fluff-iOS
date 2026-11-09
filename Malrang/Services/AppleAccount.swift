import AuthenticationServices
import CryptoKit
import GoogleSignIn
import Observation
import Security

/// Native authentication for the on-device room. No identity/access tokens are
/// written to preferences, and no server account or cloud sync is implied.
@MainActor @Observable
final class AppleAccount {
    var message: String?
    private var expectedState: String?
    private static let service = "com.nayeon.Malrang.apple-account"
    private static let account = "room-owner"

    func prepare(_ request: ASAuthorizationAppleIDRequest) {
        message = nil
        let state = UUID().uuidString
        expectedState = state
        request.state = state
        request.nonce = SHA256.hash(data: Data(UUID().uuidString.utf8))
            .map { String(format: "%02x", $0) }.joined()
        // Nickname/photo are chosen inside the app; email is not needed.
        request.requestedScopes = []
    }

    func complete(_ result: Result<ASAuthorization, Error>) -> Bool {
        defer { expectedState = nil }
        do {
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  !credential.user.isEmpty, let expectedState,
                  credential.state == expectedState else {
                message = "Apple 로그인 정보를 확인하지 못했어요. 다시 시도해 주세요."
                return false
            }
            // A different Apple account must not inherit this device's saved room.
            if let owner = try Self.owner(), owner != credential.user {
                message = "이 기기의 방과 연결된 Apple 계정으로 로그인해 주세요."
                return false
            }
            try Self.saveOwner(credential.user)
            return true
        } catch {
            if let authError = error as? ASAuthorizationError, authError.code == .canceled { return false }
            message = "Apple 로그인에 실패했어요. 연결 상태를 확인한 뒤 다시 시도해 주세요."
            return false
        }
    }

    /// Errors (for example offline access) do not erase a valid local session.
    static func validateSession() async {
        guard UserDefaults.standard.bool(forKey: "isSignedIn"),
              let user = try? owner() else { return }
        do {
            let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: user)
            // Do not let a late callback sign out a newly authenticated owner.
            guard (try? owner()) == user else { return }
            switch state {
            case .revoked, .notFound, .transferred: signOut()
            case .authorized: break
            @unknown default: break
            }
        } catch { /* Retain the session until Apple explicitly reports revocation. */ }
    }

    static func signOut() {
        GIDSignIn.sharedInstance.signOut()
        UserDefaults.standard.set(false, forKey: "isSignedIn")
        // Keep the owner while their room remains on this device.
    }

    static func removeLocalIdentity() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw StorageError.failed }
        UserDefaults.standard.removeObject(forKey: "couch.videoLibrary")
        signOut()
    }

    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service, kSecAttrAccount as String: account]
    }
    private static func owner() throws -> String? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var value: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &value)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = value as? Data,
              let user = String(data: data, encoding: .utf8) else { throw StorageError.failed }
        return user
    }
    private static func saveOwner(_ user: String) throws {
        let attributes: [String: Any] = [kSecValueData as String: Data(user.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let insert = query.merging(attributes) { _, new in new }
            guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else { throw StorageError.failed }
        } else if status != errSecSuccess { throw StorageError.failed }
    }
    private enum StorageError: Error { case failed }
}
