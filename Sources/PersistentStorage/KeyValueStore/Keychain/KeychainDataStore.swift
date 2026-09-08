//
//  PersistentStorage
//
//  Created by Holloh, Niklas on 22.08.25 for adesso SE.
//  Copyright 2025 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation
import Security

/// Internal `PersistentKeyDataStore` implementation backed by the native Security framework.
///
/// `KeychainDataStore` wraps the four `SecItem*` functions (`SecItemCopyMatching`,
/// `SecItemAdd`, `SecItemUpdate`, `SecItemDelete`) and translates them into the
/// ``PersistentKeyDataStore`` contract. All configuration (service, accessibility, auth
/// policy, etc.) is immutable and supplied at construction time.
///
/// Declared as a `final class` rather than a `struct` because all stored properties are
/// immutable `let` values, which makes `Sendable` conformance straightforward and
/// unconditional — no `@unchecked` annotation is needed. The class is always held as an
/// existential (`any PersistentKeyDataStore`), so the heap indirection is unavoidable
/// regardless of whether the underlying type is a class or struct.
///
/// Clients never interact with this type directly — they use
/// ``DataStoreConfiguration/keychain(service:accessGroup:accessibility:authenticationPolicy:synchronizable:)``
/// which constructs the appropriate `KeychainDataStore` internally.
final class KeychainDataStore: PersistentKeyDataStore, Sendable {

    // MARK: - Configuration

    private let service: String
    private let accessGroup: String?
    private let accessibility: Keychain.Accessibility
    private let authenticationPolicy: Keychain.AuthenticationPolicy
    private let synchronizable: Bool

    // MARK: - Init

    init(
        service: String,
        accessGroup: String?,
        accessibility: Keychain.Accessibility,
        authenticationPolicy: Keychain.AuthenticationPolicy,
        synchronizable: Bool
    ) {
        self.service = service
        self.accessGroup = accessGroup
        self.accessibility = accessibility
        self.authenticationPolicy = authenticationPolicy
        self.synchronizable = synchronizable
    }

    // MARK: - PersistentKeyDataStore

    /// Returns `true` if a keychain item exists for `key`.
    ///
    /// Uses `kSecUseAuthenticationUISkip` so that Face ID / Touch ID / passcode prompts
    /// are suppressed. If the item requires authentication and the device is locked,
    /// `errSecInteractionNotAllowed` is returned by the Security framework — this is
    /// treated as "item exists", returning `true` rather than blocking on a UI prompt.
    ///
    /// - Note: `kSecUseAuthenticationUISkip` is deprecated in iOS 18 / macOS 15. At a future
    ///   date this may need to be replaced with an `LAContext`-based existence check.
    func contains(dataFor key: PersistentKey) -> Bool {
        var query = baseQuery(for: key.rawValue)
        query[kSecUseAuthenticationUI] = kSecUseAuthenticationUISkip
        query[kSecReturnData] = false as CFBoolean

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }

    /// Retrieves the raw `Data` stored under `key`, or `nil` if no item exists.
    ///
    /// - Throws: ``KeychainError`` if the Security framework returns any status other than
    ///   `errSecSuccess` or `errSecItemNotFound`.
    func get(dataFor key: PersistentKey) throws -> Data? {
        var query = baseQuery(for: key.rawValue)
        query[kSecReturnData] = true as CFBoolean
        query[kSecMatchLimit] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError(status: status)
        }
    }

    /// Writes `data` to the keychain under `key`.
    ///
    /// Uses an optimistic upsert: attempts `SecItemAdd` first. On `errSecDuplicateItem`
    /// it falls back to `SecItemUpdate`. This avoids the extra `SecItemCopyMatching`
    /// round-trip that a read-before-write pattern would require.
    ///
    /// - Throws: ``KeychainError`` if either the add or the update operation fails.
    func set(data: Data, for key: PersistentKey) throws {
        let attrs = try buildWriteAttributes(for: key.rawValue, data: data)
        let addStatus = SecItemAdd(attrs as CFDictionary, nil)

        switch addStatus {
        case errSecSuccess:
            break // Item added — done.

        case errSecDuplicateItem:
            // Item already exists — update data only.
            let query = baseQuery(for: key.rawValue)
            let update: [CFString: Any] = [kSecValueData: data]
            let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError(status: updateStatus)
            }

        default:
            throw KeychainError(status: addStatus)
        }
    }

    /// Removes the keychain item stored under `key`.
    ///
    /// If no item exists for `key` the call succeeds silently (`errSecItemNotFound` is ignored).
    ///
    /// - Throws: ``KeychainError`` for any other Security framework failure.
    func remove(dataFor key: PersistentKey) throws {
        let query = baseQuery(for: key.rawValue)
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }

    // MARK: - Private helpers

    /// Builds the base `[CFString: Any]` query dictionary shared by all operations.
    ///
    /// Contains `kSecClass`, `kSecAttrService`, `kSecAttrAccount`, and optionally
    /// `kSecAttrAccessGroup` and `kSecAttrSynchronizable`. Does **not** include
    /// access-control or data-value attributes — those are appended only for `SecItemAdd`
    /// via ``buildWriteAttributes(for:data:)``.
    private func baseQuery(for key: String) -> [CFString: Any] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup] = accessGroup
        }
        if synchronizable {
            query[kSecAttrSynchronizable] = kCFBooleanTrue
        }
        return query
    }

    /// Builds the full attribute dictionary for `SecItemAdd`.
    ///
    /// Appends the data value and access-control attributes on top of the base query.
    ///
    /// - When ``Keychain/AuthenticationPolicy`` is not `.none`, both the accessibility level
    ///   and the authentication flags are encoded into a `SecAccessControl` object via
    ///   `SecAccessControlCreateWithFlags`. In this case `kSecAttrAccessControl` is used and
    ///   `kSecAttrAccessible` must **not** be set simultaneously (Security framework requirement).
    /// - When the policy is `.none`, `kSecAttrAccessible` is set directly.
    ///
    /// - Throws: ``KeychainError/invalidParam`` if `SecAccessControlCreateWithFlags` fails.
    ///   The `CFError` produced by the Security framework is consumed and released before throwing.
    private func buildWriteAttributes(for key: String, data: Data) throws -> [CFString: Any] {
        var attrs = baseQuery(for: key)
        attrs[kSecValueData] = data

        if authenticationPolicy != .none {
            var cfError: Unmanaged<CFError>?
            guard let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                accessibility.cfValue as CFTypeRef,
                authenticationPolicy.secFlags,
                &cfError
            ) else {
                // Consume and release the CFError to prevent a memory leak, then throw.
                let error = cfError?.takeRetainedValue()
                throw KeychainError.accessControlCreationFailed(underlying: error)
            }
            attrs[kSecAttrAccessControl] = accessControl
            // Do NOT also set kSecAttrAccessible when kSecAttrAccessControl is present.
        } else {
            attrs[kSecAttrAccessible] = accessibility.cfValue
        }

        return attrs
    }
}
