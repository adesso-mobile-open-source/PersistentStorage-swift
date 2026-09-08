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

/// Extension providing ``PersistentKeyDataStore`` conformance for `UserDefaults`.
///
/// This extension allows any `UserDefaults` instance to be used as a backing store for the
/// persistent storage stack. Data is written to the user defaults database on disk and
/// survives app launches.
///
/// `UserDefaults` is best suited for storing non-sensitive preferences and lightweight state.
/// For sensitive data (tokens, credentials), prefer the `Keychain` backing store instead.
///
/// ## Usage
/// ```swift
/// extension PersistentKey {
///     static let userSettings: Self = "user_settings"
/// }
///
/// var store = PersistentKeyValueStoreImpl(dataStore: .userDefaults())
/// try store.set(value: userSettings, for: .userSettings)
/// let settings: Settings? = try store.get(valueFor: .userSettings)
///
/// // Using an isolated suite for an App Group
/// let sharedDefaults = UserDefaults(suiteName: "group.com.example.myapp")!
/// var sharedStore = PersistentKeyValueStoreImpl(dataStore: .userDefaults(sharedDefaults))
/// ```
///
/// ## Thread Safety
/// `UserDefaults` is thread-safe; this implementation can be used from multiple threads
/// and async contexts without additional synchronisation.
///
/// ## Persistence
/// Values persist across app launches and survive device restarts. They are removed when the
/// app is uninstalled. Use iCloud Key-Value Store or a shared App Group suite for cross-device
/// or cross-app data sharing.
extension UserDefaults: PersistentKeyDataStore {
    /// Returns `true` if a `Data` value is stored for `key` in this `UserDefaults` instance.
    ///
    /// - Parameter key: The ``PersistentKey`` identifying the entry to check.
    /// - Returns: `true` if a `Data` entry exists for `key`; `false` otherwise.
    ///
    /// - Note: This method checks specifically for `Data` values. Keys associated with other
    ///   types (e.g. `String`, `Int`) will return `false`.
    public func contains(dataFor key: PersistentKey) -> Bool {
        data(forKey: key.stringValue) != nil
    }

    /// Retrieves the raw `Data` stored under `key`.
    ///
    /// - Parameter key: The ``PersistentKey`` identifying the entry to read.
    /// - Returns: The stored `Data`, or `nil` if no `Data` entry exists for `key`.
    ///
    /// - Note: This method never throws; the signature includes `throws` to satisfy the
    ///   ``PersistentKeyDataStore`` protocol contract.
    public func get(dataFor key: PersistentKey) throws -> Data? {
        data(forKey: key.stringValue)
    }

    /// Stores `data` in user defaults under `key`, creating or overwriting the entry.
    ///
    /// - Parameters:
    ///   - data: The raw bytes to persist.
    ///   - key: The ``PersistentKey`` to associate the data with.
    ///
    /// - Note: This method never throws; the signature includes `throws` to satisfy the
    ///   ``PersistentKeyDataStore`` protocol contract. `UserDefaults` writes are atomic at
    ///   the framework level and are eventually synchronised to disk.
    public func set(data: Data, for key: PersistentKey) throws {
        setValue(data, forKey: key.stringValue)
    }

    /// Removes the value stored under `key` from user defaults.
    ///
    /// If no entry exists for `key`, the call is a no-op.
    ///
    /// - Parameter key: The ``PersistentKey`` identifying the entry to remove.
    ///
    /// - Note: This method never throws; the signature includes `throws` to satisfy the
    ///   ``PersistentKeyDataStore`` protocol contract.
    public func remove(dataFor key: PersistentKey) throws {
        removeObject(forKey: key.stringValue)
    }
}
