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

import Security

/// Namespace for Keychain configuration types used with ``DataStoreConfiguration``.
///
/// Use the nested ``Accessibility`` and ``AuthenticationPolicy`` types when constructing
/// a Keychain-backed store:
///
/// ```swift
/// var store = PersistentKeyValueStoreImpl(dataStore: .keychain(
///     service: "com.example.app",
///     accessibility: .whenUnlockedThisDeviceOnly,
///     authenticationPolicy: .biometryAny
/// ))
/// ```
public enum Keychain {
    // MARK: - Accessibility

    /// Controls when a keychain item's data can be accessed.
    ///
    /// Maps directly to the `kSecAttrAccessible` constants in the Security framework.
    /// The default used by ``DataStoreConfiguration/keychain(service:accessGroup:accessibility:authenticationPolicy:synchronizable:)``
    /// is ``whenUnlockedThisDeviceOnly``.
    public enum Accessibility: Sendable {
        /// Accessible only while the device is unlocked.
        /// Items are backed up and can migrate to new devices.
        case whenUnlocked

        /// Accessible after the first unlock following a device restart.
        /// Items are backed up and can migrate to new devices.
        case afterFirstUnlock

        /// Accessible only while the device is unlocked.
        /// Items are **not** backed up and do **not** migrate to new devices.
        case whenUnlockedThisDeviceOnly

        /// Accessible after the first unlock following a device restart.
        /// Items are **not** backed up and do **not** migrate to new devices.
        case afterFirstUnlockThisDeviceOnly

        /// Accessible only when a passcode is set on the device.
        /// Items are removed if the passcode is cleared. Not backed up.
        case whenPasscodeSetThisDeviceOnly

        /// The corresponding `kSecAttrAccessible` constant.
        var cfValue: CFString {
            switch self {
            case .whenUnlocked:
                kSecAttrAccessibleWhenUnlocked
            case .afterFirstUnlock:
                kSecAttrAccessibleAfterFirstUnlock
            case .whenUnlockedThisDeviceOnly:
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .afterFirstUnlockThisDeviceOnly:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            case .whenPasscodeSetThisDeviceOnly:
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            }
        }
    }

    // MARK: - AuthenticationPolicy

    /// A policy that requires user authentication before a keychain item can be accessed.
    ///
    /// Mirrors `SecAccessControlCreateFlags` from the Security framework. When a policy is set
    /// on a keychain item, the item's accessibility and the authentication requirement are
    /// combined via `SecAccessControlCreateWithFlags`.
    ///
    /// Use `.none` (the default) when no authentication beyond device unlock is required.
    ///
    /// ## Example — biometric protection
    /// ```swift
    /// var store = PersistentKeyValueStoreImpl(dataStore: .keychain(
    ///     service: "com.example.app",
    ///     accessibility: .whenPasscodeSetThisDeviceOnly,
    ///     authenticationPolicy: .biometryAny
    /// ))
    /// ```
    public struct AuthenticationPolicy: OptionSet, Sendable {
        /// The raw flag value used by `SecAccessControlCreateWithFlags`.
        ///
        /// - Note: This is an implementation detail consumed by ``KeychainDataStore``.
        ///   Do not rely on specific raw values across OS versions.
        @_documentation(visibility: internal)
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /// No authentication policy. The item is accessible based solely on the
        /// ``Keychain/Accessibility`` setting. This is the default.
        public static let none = Self([])

        /// Touch ID / Face ID or passcode. Touch ID does not need to be enrolled.
        public static let userPresence = Self(
            rawValue: SecAccessControlCreateFlags.userPresence.rawValue
        )

        /// Any enrolled biometric (any finger / any face).
        ///
        /// Does **not** include a passcode fallback by itself. To allow the device passcode
        /// as a fallback when biometry is not available or not enrolled, combine with
        /// `.devicePasscode`:
        /// ```swift
        /// authenticationPolicy: [.biometryAny, .devicePasscode]
        /// ```
        public static let biometryAny = Self(
            rawValue: SecAccessControlCreateFlags.biometryAny.rawValue
        )

        /// The currently enrolled biometric only. Access is revoked if new biometrics are added
        /// or existing ones are removed.
        public static let biometryCurrentSet = Self(
            rawValue: SecAccessControlCreateFlags.biometryCurrentSet.rawValue
        )

        /// Device passcode only (no biometric prompt).
        public static let devicePasscode = Self(
            rawValue: SecAccessControlCreateFlags.devicePasscode.rawValue
        )

        /// Apple Watch or other companion devices (requires iOS 18.0+, macOS 15.0+).
        @available(iOS 18.0, macOS 15.0, *)
        public static let companion = Self(
            rawValue: SecAccessControlCreateFlags.companion.rawValue
        )

        // MARK: - Internal conversion

        /// The equivalent `SecAccessControlCreateFlags` value for use with
        /// `SecAccessControlCreateWithFlags`.
        ///
        /// Centralises the `rawValue` → `CFOptionFlags` → `SecAccessControlCreateFlags`
        /// cast so it occurs in exactly one place and is easy to audit.
        var secFlags: SecAccessControlCreateFlags {
            SecAccessControlCreateFlags(rawValue: CFOptionFlags(rawValue))
        }
    }
}
