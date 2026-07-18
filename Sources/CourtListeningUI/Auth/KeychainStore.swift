import Foundation
import Security

public enum KeychainError: Error, Equatable, Sendable {
    case unexpectedStatus(OSStatus)
    case dataEncodingFailed
}

/// Secure persistence for the API token, backed by the system Keychain (generic password).
///
/// Actor-isolated because it owns an OS resource (the Keychain item) — the documented
/// exception to the no-shared-mutable-singletons rule. One instance per session is owned by
/// `SessionStore`; there is no global singleton.
public actor KeychainStore {
    private let service: String
    private let account: String

    public init(
        service: String = "com.courtlistening.apitoken",
        account: String = "default"
    ) {
        self.service = service
        self.account = account
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    public func save(_ token: String) throws {
        guard let data = token.data(using: .utf8) else { throw KeychainError.dataEncodingFailed }
        // Upsert: delete any existing item, then add fresh.
        SecItemDelete(baseQuery as CFDictionary)
        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }

    public func load() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
