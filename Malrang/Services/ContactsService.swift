import Contacts
import CryptoKit
import Foundation

/// 연락처 접근. 서버에는 전화번호 원문 대신 해시만 보낸다.
enum ContactsService {
    static func requestAccess() async -> Bool {
        (try? await CNContactStore().requestAccess(for: .contacts)) ?? false
    }

    /// 연락처의 전화번호를 숫자만 남기고(+82는 0으로) 해시한 값들
    @concurrent nonisolated static func phoneHashes() async -> [String] {
        let request = CNContactFetchRequest(keysToFetch: [CNContactPhoneNumbersKey as CNKeyDescriptor])
        var hashes = Set<String>()
        try? CNContactStore().enumerateContacts(with: request) { contact, _ in
            for phone in contact.phoneNumbers {
                var digits = phone.value.stringValue.filter(\.isNumber)
                if digits.hasPrefix("82") { digits = "0" + digits.dropFirst(2) }
                let hash = SHA256.hash(data: Data(digits.utf8)).map { String(format: "%02x", $0) }.joined()
                hashes.insert(hash)
            }
        }
        return Array(hashes)
    }
}
