//
//  PersistentStorage
//
//  Created by Holloh, Niklas on 22.08.25 for adesso SE.
//  Copyright © 2025 adesso SE. All rights reserved.
//

import Foundation
import Spyable

/// A protocol defining the basic interface for persistent storage of raw data by string keys.
///
/// This protocol provides the foundational layer for persistent storage, handling only raw `Data`
/// objects. Higher-level abstractions like `PersistentKeyValueStore` can build upon this protocol
/// to provide encoding/decoding capabilities.
///
/// ## Conforming Types
/// - `UserDefaults` — standard user defaults backed store, accessed via
///   ``DataStoreConfiguration/userDefaults(_:)``.
///
/// Keychain storage is provided internally; use
/// ``DataStoreConfiguration/keychain(service:accessGroup:accessibility:authenticationPolicy:synchronizable:)``
/// to create a Keychain-backed store.
///
/// ## Thread Safety
/// The protocol itself imposes no thread-safety requirement — conforming types are
/// responsible for their own synchronisation. Built-in implementations:
/// - `UserDefaults` is thread-safe natively.
/// - The internal `KeychainDataStore` is thread-safe because all stored properties are
///   immutable and all Security framework calls serialise through the keychain daemon.
@Spyable(behindPreprocessorFlag: "DEBUG", accessLevel: .public)
public protocol PersistentKeyDataStore: Sendable {
    /// Returns a Boolean value indicating whether data exists for the given key.
    ///
    /// - Parameter key: The ``PersistentKey`` identifying the entry to check.
    /// - Returns: `true` if data is stored under `key`; `false` otherwise.
    func contains(dataFor key: PersistentKey) -> Bool

    /// Retrieves the raw `Data` stored under the given key.
    ///
    /// - Parameter key: The ``PersistentKey`` identifying the entry to read.
    /// - Returns: The stored `Data`, or `nil` if no entry exists for `key`.
    /// - Throws: An error if the underlying storage operation fails.
    func get(dataFor key: PersistentKey) throws -> Data?

    /// Writes raw `Data` to the store, associating it with the given key.
    ///
    /// An existing entry for `key` is overwritten.
    ///
    /// - Parameters:
    ///   - data: The raw bytes to persist.
    ///   - key: The ``PersistentKey`` to associate the data with.
    /// - Throws: An error if the underlying storage operation fails.
    func set(data: Data, for key: PersistentKey) throws

    /// Removes the data stored under the given key.
    ///
    /// If no entry exists for `key`, the call is a no-op.
    ///
    /// - Parameter key: The ``PersistentKey`` identifying the entry to remove.
    /// - Throws: An error if the underlying storage operation fails.
    func remove(dataFor key: PersistentKey) throws
}
