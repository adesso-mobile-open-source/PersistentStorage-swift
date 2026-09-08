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

/// A protocol defining a persistent key-value store that supports both raw data and typed value storage.
///
/// `PersistentKeyValueStore` is the high-level interface in the two-layer storage architecture.
/// It wraps a ``PersistentKeyDataStore`` and adds automatic encoding/decoding of `Codable` types
/// via configurable ``AnyEncoder`` and ``AnyDecoder`` instances.
///
/// Keys are expressed as ``PersistentKey`` values rather than raw strings, providing a single
/// definition point for each identifier and enabling type-safe, leading-dot notation at every call site.
///
/// The default concrete implementation is ``PersistentKeyValueStoreImpl``, which uses `JSONEncoder`
/// and `JSONDecoder` out of the box.
///
/// ## Architecture
/// ```
/// PersistentKeyValueStore
///         │  (encodes/decodes Codable types)
///         ▼
/// PersistentKeyDataStore
///         │  (stores raw Data by PersistentKey)
///         ▼
///   UserDefaults / Keychain (via DataStoreConfiguration)
/// ```
///
/// ## Usage
/// ```swift
/// extension PersistentKey {
///     static let currentUser: Self = "current_user"
///     static let authToken:   Self = "auth_token"
/// }
///
/// // Using UserDefaults as the backing store
/// var store = PersistentKeyValueStoreImpl(dataStore: .userDefaults())
/// try store.set(value: myUser, for: .currentUser)
/// let user: User? = try store.get(valueFor: .currentUser)
///
/// // Using Keychain as the backing store for sensitive data
/// var secureStore = PersistentKeyValueStoreImpl(
///     dataStore: .keychain(service: "com.example.myapp")
/// )
/// try secureStore.set(value: authToken, for: .authToken)
/// ```
public protocol PersistentKeyValueStore: Sendable {
    /// The encoder used to convert `Encodable` values to `Data` for storage.
    ///
    /// Swap this out to change the serialisation format. For example, assign a `JSONEncoder`
    /// configured with `.outputFormatting = .prettyPrinted` for human-readable storage, or
    /// provide a completely custom ``AnyEncoder`` implementation for a different wire format.
    ///
    /// - Note: ``PersistentKeyValueStoreImpl`` uses `JSONEncoder` by default.
    var encoder: AnyEncoder { get }

    /// The decoder used to convert stored `Data` back to `Decodable` values.
    ///
    /// The decoder must be compatible with the format produced by the current ``encoder``;
    /// mismatches will result in a `DecodingError` at retrieval time.
    ///
    /// - Note: ``PersistentKeyValueStoreImpl`` uses `JSONDecoder` by default.
    var decoder: AnyDecoder { get }

    /// Returns a Boolean value indicating whether a value is associated with the given key.
    ///
    /// - Parameter key: The ``PersistentKey`` identifying the entry to check.
    /// - Returns: `true` if a value (or raw data) exists for `key`; `false` otherwise.
    func contains(valueFor key: PersistentKey) -> Bool

    /// Retrieves raw `Data` associated with the given key without decoding it.
    ///
    /// Use this method when you need direct access to the serialised bytes, for example to
    /// forward them to another system or to inspect the payload for debugging purposes.
    ///
    /// - Parameter key: The ``PersistentKey`` identifying the entry to read.
    /// - Returns: The stored `Data`, or `nil` if no entry exists for `key`.
    /// - Throws: An error if the underlying data store fails to read the value.
    func get(dataFor key: PersistentKey) throws -> Data?

    /// Retrieves and decodes a typed value associated with the given key.
    ///
    /// The method first fetches the raw `Data` from the underlying store and then passes it
    /// to the current ``decoder``. If no data is found for `key`, `nil` is returned immediately
    /// without invoking the decoder.
    ///
    /// - Parameter key: The ``PersistentKey`` identifying the entry to read.
    /// - Returns: A decoded instance of type `V`, or `nil` if no data is stored under `key`.
    /// - Throws: A `DecodingError` if the stored data cannot be decoded into type `V`, or any
    ///   error thrown by the underlying data store.
    func get<V: Decodable>(valueFor key: PersistentKey) throws -> V?

    /// Stores raw `Data` for the given key, bypassing the encoder.
    ///
    /// Use this overload when you already hold a serialised payload and want to write it
    /// directly without re-encoding it through the current ``encoder``.
    ///
    /// - Parameters:
    ///   - data: The raw bytes to persist.
    ///   - key: The ``PersistentKey`` to associate the data with.
    /// - Throws: An error if the underlying data store fails to write the value.
    func set(data: Data, for key: PersistentKey) throws

    /// Encodes and stores a typed value for the given key.
    ///
    /// The value is first passed to the current ``encoder``, and the resulting `Data` is then
    /// written to the underlying store. An existing entry for `key` is overwritten.
    ///
    /// - Parameters:
    ///   - value: The `Encodable` value to encode and persist.
    ///   - key: The ``PersistentKey`` to associate the encoded value with.
    /// - Throws: An `EncodingError` if the value cannot be encoded, or any error thrown by
    ///   the underlying data store.
    func set(value: some Encodable, for key: PersistentKey) throws

    /// Removes the value associated with the given key.
    ///
    /// If no value exists for `key`, the call is a no-op.
    ///
    /// - Parameter key: The ``PersistentKey`` identifying the entry to remove.
    /// - Throws: An error if the underlying data store fails to remove the value.
    /// - Note: Custom ``PersistentKeyDataStore`` conformers may choose to throw on a missing
    ///   key. Both built-in stores (`UserDefaults` and the Keychain store) treat it as a no-op.
    func remove(valueFor key: PersistentKey) throws
}

/// A concrete implementation of ``PersistentKeyValueStore`` backed by any ``PersistentKeyDataStore``.
///
/// `PersistentKeyValueStoreImpl` is a `final class` that adds automatic encode/decode on top
/// of a raw ``PersistentKeyDataStore``. The encoder and decoder are fixed at construction time
/// and are immutable thereafter — pass them to ``init(dataStore:encoder:decoder:)`` to customise
/// the serialisation format.
///
/// ## Example
/// ```swift
/// extension PersistentKey {
///     static let user: Self = "user"
/// }
///
/// // Basic usage with UserDefaults
/// var store = PersistentKeyValueStoreImpl(dataStore: .userDefaults())
/// try store.set(value: myUser, for: .user)
/// let user: User? = try store.get(valueFor: .user)
///
/// // Custom encoder/decoder configuration — pass at init time
/// let encoder = JSONEncoder()
/// encoder.dateEncodingStrategy = .iso8601
/// encoder.keyEncodingStrategy = .convertToSnakeCase
///
/// let decoder = JSONDecoder()
/// decoder.dateDecodingStrategy = .iso8601
/// decoder.keyDecodingStrategy = .convertFromSnakeCase
///
/// let configuredStore = PersistentKeyValueStoreImpl(
///     dataStore: .userDefaults(),
///     encoder: encoder,
///     decoder: decoder
/// )
/// ```
public final class PersistentKeyValueStoreImpl: PersistentKeyValueStore {
    // MARK: - Dependency

    /// The underlying data store that handles raw `Data` persistence.
    private let dataStore: PersistentKeyDataStore

    /// The encoder used to convert `Encodable` values to `Data` for storage.
    ///
    /// Set at construction time via ``init(dataStore:encoder:decoder:)``. Defaults to
    /// `JSONEncoder`. Pass a custom ``AnyEncoder`` conformer to change the serialisation
    /// format.
    public let encoder: AnyEncoder

    /// The decoder used to convert stored `Data` back to `Decodable` values.
    ///
    /// Set at construction time via ``init(dataStore:encoder:decoder:)``. Defaults to
    /// `JSONDecoder`. Must be compatible with the format produced by ``encoder``;
    /// mismatches result in a `DecodingError` at retrieval time.
    public let decoder: AnyDecoder

    // MARK: - Init

    /// Creates a new key-value store from a ``DataStoreConfiguration``.
    ///
    /// The `configuration` value is consumed — it is a lightweight syntactic-sugar
    /// wrapper and is discarded immediately after the underlying ``PersistentKeyDataStore``
    /// is extracted.
    ///
    /// The encoder and decoder are accepted as concrete generic type parameters, allowing
    /// the compiler to verify `Sendable` conformance at the call site. Internally they are
    /// stored as `any AnyEncoder` / `any AnyDecoder` existentials so the class itself
    /// carries no generic parameters.
    ///
    /// ## Example
    /// ```swift
    /// // Default JSON encoder/decoder
    /// let store = PersistentKeyValueStoreImpl(
    ///     dataStore: .keychain(service: "com.example.app")
    /// )
    ///
    /// // Custom encoder/decoder
    /// let encoder = JSONEncoder()
    /// encoder.dateEncodingStrategy = .iso8601
    /// let decoder = JSONDecoder()
    /// decoder.dateDecodingStrategy = .iso8601
    /// let store = PersistentKeyValueStoreImpl(
    ///     dataStore: .userDefaults(),
    ///     encoder: encoder,
    ///     decoder: decoder
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - dataStore: A ``DataStoreConfiguration`` produced by one of the static
    ///     factory functions (`.keychain(...)`, `.userDefaults(...)`, `.custom(...)`).
    ///   - encoder: An encoder conforming to ``AnyEncoder`` (which refines `Sendable`). Defaults to `JSONEncoder`.
    ///   - decoder: A decoder conforming to ``AnyDecoder`` (which refines `Sendable`). Defaults to `JSONDecoder`.
    public init<E: AnyEncoder, D: AnyDecoder>(
        dataStore configuration: consuming DataStoreConfiguration,
        encoder: E = JSONEncoder(),
        decoder: D = JSONDecoder()
    ) {
        self.dataStore = configuration.dataStore
        self.encoder = encoder
        self.decoder = decoder
    }

    /// Creates a new key-value store backed by the given raw data store.
    ///
    /// This initialiser is **internal** and is intended for use in unit tests where a
    /// spy or mock ``PersistentKeyDataStore`` must be injected directly. Production code
    /// should use ``init(dataStore:encoder:decoder:)`` instead.
    ///
    /// - Parameters:
    ///   - dataStore: Any ``PersistentKeyDataStore``-conforming value.
    ///   - encoder: A `Sendable` encoder. Defaults to `JSONEncoder`.
    ///   - decoder: A `Sendable` decoder. Defaults to `JSONDecoder`.
    init<E: AnyEncoder, D: AnyDecoder>(
        dataStore: any PersistentKeyDataStore,
        encoder: E = JSONEncoder(),
        decoder: D = JSONDecoder()
    ) {
        self.dataStore = dataStore
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: - PersistentKeyValueStore

    /// Returns `true` if the underlying store contains a value for `key`.
    ///
    /// Delegates directly to ``PersistentKeyDataStore/contains(dataFor:)`` on the backing store.
    public func contains(valueFor key: PersistentKey) -> Bool {
        dataStore.contains(dataFor: key)
    }

    /// Retrieves raw `Data` for `key` from the backing store without decoding.
    ///
    /// Delegates directly to ``PersistentKeyDataStore/get(dataFor:)`` on the backing store.
    public func get(dataFor key: PersistentKey) throws -> Data? {
        try dataStore.get(dataFor: key)
    }

    /// Retrieves and decodes a typed value for `key`.
    ///
    /// Returns `nil` immediately — without invoking the ``decoder`` — if no data is stored
    /// under `key`. This avoids unnecessary decode work and prevents spurious `DecodingError`s
    /// on missing keys.
    public func get<V: Decodable>(valueFor key: PersistentKey) throws -> V? {
        guard let data = try get(dataFor: key) else {
            return nil
        }

        return try decoder.decode(V.self, from: data)
    }

    /// Stores raw `Data` for `key` in the backing store, bypassing the ``encoder``.
    ///
    /// Delegates directly to ``PersistentKeyDataStore/set(data:for:)`` on the backing store.
    public func set(data: Data, for key: PersistentKey) throws {
        try dataStore.set(data: data, for: key)
    }

    /// Encodes `value` using the current ``encoder`` and stores the resulting `Data` for `key`.
    ///
    /// The encoded bytes are forwarded to ``set(data:for:)`` on this store, which in turn
    /// delegates to the backing ``PersistentKeyDataStore``.
    public func set(value: some Encodable, for key: PersistentKey) throws {
        let encoded = try encoder.encode(value)
        try set(data: encoded, for: key)
    }

    /// Removes the value for `key` from the backing store.
    ///
    /// Delegates directly to ``PersistentKeyDataStore/remove(dataFor:)`` on the backing store.
    public func remove(valueFor key: PersistentKey) throws {
        try dataStore.remove(dataFor: key)
    }
}
