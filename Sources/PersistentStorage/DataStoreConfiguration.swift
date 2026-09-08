//
//  PersistentStorage
//
//  Created by Holloh, Niklas on 22.08.25 for adesso SE.
//  Copyright © 2025 adesso SE. All rights reserved.
//

import Foundation

/// Selects and configures a backing data store for ``PersistentKeyValueStoreImpl``.
///
/// Pass one of the static factory functions to
/// ``PersistentKeyValueStoreImpl/init(dataStore:encoder:decoder:)``. The struct is a
/// lightweight syntactic-sugar wrapper; it carries no runtime state beyond the
/// ``PersistentKeyDataStore`` instance it constructs. The `init` parameter is marked
/// `consuming` — once passed to ``PersistentKeyValueStoreImpl``, the configuration value
/// is moved into the initialiser and is no longer accessible to the caller. This is
/// enforced by the compiler.
///
/// ## Examples
/// ```swift
/// // Keychain — default accessibility (.whenUnlockedThisDeviceOnly)
/// var store = PersistentKeyValueStoreImpl(
///     dataStore: .keychain(service: "com.example.app")
/// )
///
/// // Keychain — biometric protection
/// var store = PersistentKeyValueStoreImpl(
///     dataStore: .keychain(
///         service: "com.example.app",
///         accessibility: .whenPasscodeSetThisDeviceOnly,
///         authenticationPolicy: .biometryAny
///     )
/// )
///
/// // Keychain — iCloud sync
/// var store = PersistentKeyValueStoreImpl(
///     dataStore: .keychain(service: "com.example.app", synchronizable: true)
/// )
///
/// // UserDefaults — standard suite
/// var store = PersistentKeyValueStoreImpl(dataStore: .userDefaults())
///
/// // UserDefaults — App Group suite
/// let sharedDefaults = UserDefaults(suiteName: "group.com.example.app")!
/// var store = PersistentKeyValueStoreImpl(dataStore: .userDefaults(sharedDefaults))
///
/// // Custom backing store
/// var store = PersistentKeyValueStoreImpl(dataStore: .custom(myStore))
/// ```
public struct DataStoreConfiguration {

    // The extracted data store — package-internal, not part of the public API.
    let dataStore: any PersistentKeyDataStore

    // MARK: - Keychain

    /// A Keychain-backed store with full configuration.
    ///
    /// All items are stored as generic password keychain entries
    /// (`kSecClassGenericPassword`) keyed by `service` + the `PersistentKey` string value.
    ///
    /// - Parameters:
    ///   - service: The service name recorded as `kSecAttrService`. Typically your app's
    ///     bundle ID (e.g. `"com.example.myapp"`). Items are scoped to this service name,
    ///     so changing it orphans previously written data.
    ///   - accessGroup: Optional keychain access group (`kSecAttrAccessGroup`) for sharing
    ///     items between apps in the same team (e.g. `"A1B2C3D4E5.group.shared"`).
    ///     On macOS this attribute requires `kSecUseDataProtectionKeychain` or
    ///     `kSecAttrSynchronizable` to be effective; on iOS it works unconditionally.
    ///   - accessibility: When the keychain item's data can be read. Defaults to
    ///     ``Keychain/Accessibility/whenUnlockedThisDeviceOnly``, which restricts
    ///     access to when the device is unlocked and prevents backup / migration.
    ///   - authenticationPolicy: A biometric or passcode policy layered on top of
    ///     `accessibility`. Defaults to ``Keychain/AuthenticationPolicy/none``, which applies
    ///     no additional authentication constraint beyond the accessibility setting.
    ///     When any other policy is set, `SecAccessControlCreateWithFlags` combines both
    ///     constraints into a single `SecAccessControl` object attached to the item.
    ///     `kSecAttrAccessible` is **not** set separately in this case (Security framework
    ///     requirement).
    ///   - synchronizable: When `true`, the item is eligible for iCloud Keychain sync
    ///     (`kSecAttrSynchronizable`). Defaults to `false`.
    /// - Returns: A `DataStoreConfiguration` that creates a ``KeychainDataStore`` with the
    ///   given parameters.
    public static func keychain(
        service: String,
        accessGroup: String? = nil,
        accessibility: Keychain.Accessibility = .whenUnlockedThisDeviceOnly,
        authenticationPolicy: Keychain.AuthenticationPolicy = .none,
        synchronizable: Bool = false
    ) -> DataStoreConfiguration {
        DataStoreConfiguration(dataStore: KeychainDataStore(
            service: service,
            accessGroup: accessGroup,
            accessibility: accessibility,
            authenticationPolicy: authenticationPolicy,
            synchronizable: synchronizable
        ))
    }

    // MARK: - UserDefaults

    /// A `UserDefaults`-backed store.
    ///
    /// Suitable for non-sensitive preferences and lightweight state. For sensitive data
    /// (tokens, credentials) use ``keychain(service:accessGroup:accessibility:authenticationPolicy:synchronizable:)``
    /// instead.
    ///
    /// - Parameter defaults: The `UserDefaults` instance to use.
    ///   Defaults to `UserDefaults.standard`.
    /// - Returns: A `DataStoreConfiguration` wrapping the provided `UserDefaults` instance.
    public static func userDefaults(
        _ defaults: UserDefaults = .standard
    ) -> DataStoreConfiguration {
        DataStoreConfiguration(dataStore: defaults)
    }

    // MARK: - Custom

    /// A custom backing store conforming to ``PersistentKeyDataStore``.
    ///
    /// Use this escape hatch to plug in any store implementation not provided by this library,
    /// for example an in-memory store for testing or a custom encrypted store.
    ///
    /// - Parameter store: Any ``PersistentKeyDataStore``-conforming value.
    /// - Returns: A `DataStoreConfiguration` wrapping the provided store.
    public static func custom(
        _ store: any PersistentKeyDataStore
    ) -> DataStoreConfiguration {
        DataStoreConfiguration(dataStore: store)
    }
}
