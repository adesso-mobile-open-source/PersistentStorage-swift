//
//  PersistentKey.swift
//  PersistentStorage
//
//  Created by Holloh, Niklas on 03.07.26 for adesso SE.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// A type-safe identifier for a persistent storage entry.
///
/// `PersistentKey` wraps a plain `String` identifier but exposes it as a dedicated type,
/// eliminating stringly-typed key arguments across the storage API. Keys are defined once —
/// typically in a file-scoped or module-scoped `extension` — and then referenced everywhere
/// via leading-dot notation, guided by type inference at the call site.
///
/// ## Defining Keys
///
/// Declare your application's keys in an extension on `PersistentKey`:
///
/// ```swift
/// extension PersistentKey {
///     static let accountNumber: Self = "account_number"
///     static let authToken:     Self = "auth_token"
///     static let userSettings:  Self = "user_settings"
/// }
/// ```
///
/// ## Using Keys
///
/// Because `PersistentKey` conforms to `ExpressibleByStringLiteral`, static members are
/// inferred at any call site that expects a `PersistentKey`:
///
/// ```swift
/// try store.set(value: "124512423", for: .accountNumber)
/// let number: String? = try store.get(valueFor: .accountNumber)
/// store.contains(valueFor: .accountNumber)
/// try store.remove(valueFor: .accountNumber)
/// ```
///
/// ## Raw String Access
///
/// The underlying string identifier is available via ``stringValue`` for cases where a plain
/// `String` is required, such as logging or migrating legacy data:
///
/// ```swift
/// print("Stored under key: \(PersistentKey.accountNumber.stringValue)")
/// ```
///
/// ## Hashable
///
/// Because `PersistentKey` conforms to `Hashable`, keys can be used as `Dictionary` keys
/// or `Set` members — useful when building in-memory caches or change-tracking layers on
/// top of the storage stack:
///
/// ```swift
/// var cachedValues: [PersistentKey: Any] = [:]
/// cachedValues[.authToken] = loadedToken
/// ```
///
/// ## Key Stability
///
/// A key's ``rawValue`` is the sole identifier used by the backing store. Changing a key's
/// raw value between app versions orphans any data previously written under the old value.
/// If migration is necessary, read from the old key, write to the new key, then delete the
/// old entry.
public struct PersistentKey: RawRepresentable, ExpressibleByStringLiteral, Equatable, Hashable {
    // MARK: - RawRepresentable

    /// The raw string identifier that backs this key.
    ///
    /// This is the value passed directly to the underlying storage backend (e.g.
    /// `UserDefaults`, Keychain). It should be a stable, non-localised string
    /// that does not change between app versions, as changing it would orphan any
    /// previously stored data under the old identifier.
    public let rawValue: String

    /// Alias for ``rawValue``.
    ///
    /// Provided for readability at call sites where the semantic intent of "this is a
    /// storage key string" is clearer than the generic `rawValue` name.
    public var stringValue: String { rawValue }

    /// Creates a key from its raw string value.
    ///
    /// - Parameter rawValue: The string to use as the storage key identifier.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    // MARK: - ExpressibleByStringLiteral

    /// Creates a key from a string literal.
    ///
    /// This initialiser is invoked automatically by the compiler when a string literal is used
    /// in a context that expects a `PersistentKey`, including the body of `static let` key
    /// declarations in extensions:
    ///
    /// ```swift
    /// extension PersistentKey {
    ///     static let authToken: Self = "auth_token"   // calls this init
    /// }
    /// ```
    ///
    /// - Parameter value: The string literal to use as the storage key identifier.
    public init(stringLiteral value: StringLiteralType) {
        rawValue = value
    }

    // MARK: - Dynamic init

    /// Creates a key from a dynamic `String` value.
    ///
    /// Prefer declaring static constants via `ExpressibleByStringLiteral` for all known keys.
    /// Use this initialiser only when a key must be constructed dynamically at runtime — for
    /// example, when namespacing keys by user ID:
    ///
    /// ```swift
    /// let userKey = PersistentKey("profile_\(userID)")
    /// ```
    ///
    /// - Parameter stringValue: The string to use as the storage key identifier.
    public init(_ stringValue: String) {
        rawValue = stringValue
    }
}
