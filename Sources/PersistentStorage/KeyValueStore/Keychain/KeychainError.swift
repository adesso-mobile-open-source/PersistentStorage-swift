//
//  PersistentStorage
//
//  Created by Holloh, Niklas on 22.08.25 for adesso SE.
//  Copyright © 2025 adesso SE. All rights reserved.
//

import Foundation
import Security

/// An error thrown by ``KeychainDataStore`` when a Security framework operation fails.
///
/// Each case maps to a specific `OSStatus` code that the `SecItem*` functions can return.
/// Codes that are not explicitly enumerated are represented by ``unknown(_:)`` so that
/// callers can always pattern-match on a known set of cases while retaining access to the
/// raw status for diagnostics.
///
/// `KeychainError` conforms to `LocalizedError`. For `.unknown` cases, `errorDescription`
/// delegates to `SecCopyErrorMessageString` so the Security framework's own human-readable
/// message is returned.
///
/// ## Example
/// ```swift
/// do {
///     try store.set(data: data, for: .authToken)
/// } catch KeychainError.interactionNotAllowed {
///     // Item is protected and the device is currently locked.
/// } catch KeychainError.missingEntitlement {
///     // App is missing the keychain-access-groups entitlement.
/// } catch let error as KeychainError {
///     print("Keychain failure: \(error.localizedDescription)")
/// }
/// ```
public enum KeychainError: Error, Sendable {

    /// The item already exists in the keychain (`errSecDuplicateItem`, -25299).
    ///
    /// Typically indicates a logic error — ``KeychainDataStore`` uses an upsert pattern
    /// internally so this should not surface under normal operation.
    case duplicateItem

    /// No matching item was found (`errSecItemNotFound`, -25300).
    ///
    /// ``KeychainDataStore`` treats this as a non-error in most contexts (returning `nil`
    /// from `get` and silently succeeding in `remove`). It is only thrown if encountered
    /// in an unexpected code path.
    case itemNotFound

    /// The item requires user authentication but the device is currently locked or the
    /// authentication UI could not be shown (`errSecInteractionNotAllowed`, -25308).
    case interactionNotAllowed

    /// The user explicitly cancelled a biometric or passcode prompt
    /// (`errSecUserCanceled`, -128).
    case userCanceled

    /// Authentication failed (wrong biometric or passcode) (`errSecAuthFailed`, -25293).
    case authFailed

    /// The operation failed because no keychain is available on this device
    /// (`errSecNoDefaultKeychain`, -25307).
    case noDefaultKeychain

    /// The requested operation is not available on this platform
    /// (`errSecUnimplemented`, -4).
    case unimplemented

    /// The parameter passed to the Security framework was invalid
    /// (`errSecParam`, -50).
    case invalidParam

    /// Memory allocation failed inside the Security framework
    /// (`errSecAllocate`, -108).
    case memoryAllocation

    /// The keychain item or service is not currently available
    /// (`errSecNotAvailable`, -25291).
    ///
    /// Commonly occurs when the keychain is locked during background access, or when
    /// the device has not yet been unlocked after a restart.
    case notAvailable

    /// The app is missing a required keychain entitlement
    /// (`errSecMissingEntitlement`, -34018).
    ///
    /// Ensure the app target has the `Keychain Sharing` capability configured in Xcode,
    /// or that the correct access group is specified in the provisioning profile.
    case missingEntitlement

    /// The data in the keychain item could not be decoded
    /// (`errSecDecode`, -26275).
    ///
    /// May indicate data corruption or that the item was written by an incompatible
    /// version of the app.
    case decode

    /// `SecAccessControlCreateWithFlags` failed to create a `SecAccessControl` object.
    ///
    /// This prevents a keychain item from being written with the requested authentication
    /// policy. The underlying `CFError` is included when available.
    case accessControlCreationFailed(underlying: CFError?)

    /// An unrecognised `OSStatus` code was returned by the Security framework.
    ///
    /// - Parameter status: The raw `OSStatus` value for diagnostics.
    case unknown(OSStatus)

    // MARK: - Internal factory

    /// Creates a ``KeychainError`` from a raw `OSStatus` code.
    init(status: OSStatus) {
        switch status {
        case errSecDuplicateItem:         self = .duplicateItem
        case errSecItemNotFound:          self = .itemNotFound
        case errSecInteractionNotAllowed: self = .interactionNotAllowed
        case errSecUserCanceled:          self = .userCanceled
        case errSecAuthFailed:            self = .authFailed
        case errSecNoDefaultKeychain:     self = .noDefaultKeychain
        case errSecUnimplemented:         self = .unimplemented
        case errSecParam:                 self = .invalidParam
        case errSecAllocate:              self = .memoryAllocation
        case errSecNotAvailable:          self = .notAvailable
        case errSecMissingEntitlement:    self = .missingEntitlement
        case errSecDecode:                self = .decode
        default:                          self = .unknown(status)
        }
    }

}

// MARK: - LocalizedError

extension KeychainError: LocalizedError {
    /// A human-readable description of the error, suitable for display or logging.
    ///
    /// For ``unknown(_:)`` cases, delegates to `SecCopyErrorMessageString` so that the
    /// Security framework's own description is returned rather than a generic fallback.
    /// For all other cases, returns a concise description of the known condition.
    public var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "A keychain item with this key already exists."
        case .itemNotFound:
            return "No keychain item was found for the given key."
        case .interactionNotAllowed:
            return "The keychain item requires authentication but the device is locked or the authentication UI cannot be shown."
        case .userCanceled:
            return "The user cancelled the authentication prompt."
        case .authFailed:
            return "Authentication failed — wrong biometric or passcode."
        case .noDefaultKeychain:
            return "No default keychain is available on this device."
        case .unimplemented:
            return "The requested keychain operation is not available on this platform."
        case .invalidParam:
            return "An invalid parameter was passed to the Security framework."
        case .memoryAllocation:
            return "The Security framework failed to allocate memory."
        case .notAvailable:
            return "The keychain or keychain item is not currently available. The device may need to be unlocked."
        case .missingEntitlement:
            return "The app is missing a required keychain entitlement. Check the Keychain Sharing capability and provisioning profile."
        case .decode:
            return "The keychain item data could not be decoded. It may be corrupted or written by an incompatible app version."
        case .accessControlCreationFailed(let underlying):
            if let msg = underlying.map({ $0.localizedDescription }) {
                return "Failed to create access control for the keychain item: \(msg)"
            }
            return "Failed to create access control for the keychain item."
        case .unknown(let status):
            return SecCopyErrorMessageString(status, nil) as String?
                ?? "An unknown Security framework error occurred (OSStatus \(status))."
        }
    }
}
