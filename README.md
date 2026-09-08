# PersistentStorage

A lightweight, protocol-oriented Swift package for persisting `Codable` values on iOS. It provides a two-layer abstraction that separates *how data is serialised* from *where it is stored*, making it trivially easy to switch between `UserDefaults` and `Keychain` — or to provide your own backing store.

**Requirements:** iOS 16.4+ · macOS 13+ · Swift 6

---

## Overview

```
PersistentKeyValueStore          ← encode / decode Codable types
        │
        ▼
PersistentKeyDataStore           ← read / write raw Data
        │
   ┌────┴─────┐
   ▼           ▼
UserDefaults  Keychain
```

| Layer | Protocol | Concrete implementation |
|---|---|---|
| High-level (typed values) | `PersistentKeyValueStore` | `PersistentKeyValueStoreImpl` |
| Low-level (raw data) | `PersistentKeyDataStore` | `UserDefaults` (public); Keychain via `DataStoreConfiguration.keychain(...)` (internal) |

Both layers are protocols, so every boundary is mockable in tests.

---

## Keys

All storage operations accept a `PersistentKey` rather than a plain `String`. Declare your keys once in an extension and refer to them everywhere with leading-dot notation, guided by the compiler's type inference — no stringly-typed arguments, no duplication.

```swift
extension PersistentKey {
    static let accountNumber: Self = "account_number"
    static let authToken:     Self = "auth_token"
    static let userSettings:  Self = "user_settings"
    static let currentUser:   Self = "current_user"
}
```

### Dynamic keys

For keys that must be composed at runtime (e.g. namespaced by user ID), use the memberwise initialiser:

```swift
let userKey = PersistentKey("profile_\(userID)")
```

### Raw string access

The underlying identifier is available via `rawValue` (or the `stringValue` alias) for logging or legacy migration:

```swift
print(PersistentKey.accountNumber.rawValue) // "account_number"
```

### Key stability

> **Important:** A key's raw string value is the sole identifier used by the backing store.
> Changing a key's value between app versions orphans any data previously written under the
> old value. If migration is necessary: read the old key, write to the new key, then delete
> the old entry.

---

## Quick Start

### Store and retrieve a `Codable` value

```swift
import PersistentStorage

struct UserProfile: Codable {
    let id: UUID
    var displayName: String
}

extension PersistentKey {
    static let userProfile: Self = "user_profile"
}

// Create a store backed by UserDefaults
let store = PersistentKeyValueStoreImpl(dataStore: .userDefaults())

// Write
let profile = UserProfile(id: UUID(), displayName: "Alice")
try store.set(value: profile, for: .userProfile)

// Read
let loaded: UserProfile? = try store.get(valueFor: .userProfile)

// Check existence
let exists = store.contains(valueFor: .userProfile)  // true

// Delete
try store.remove(valueFor: .userProfile)
```

### Store sensitive data in the Keychain

```swift
import PersistentStorage

struct AuthToken: Codable {
    let accessToken: String
    let expiresAt: Date
}

extension PersistentKey {
    static let authToken: Self = "auth_token"
}

let secureStore = PersistentKeyValueStoreImpl(
    dataStore: .keychain(service: "com.example.myapp")
)

try secureStore.set(value: token, for: .authToken)
let token: AuthToken? = try secureStore.get(valueFor: .authToken)
```

---

## Backing Stores

### `UserDefaults`

Suited for non-sensitive preferences, feature flags, and lightweight app state.

```swift
extension PersistentKey {
    static let theme:      Self = "theme"
    static let onboarded:  Self = "has_completed_onboarding"
}

// Standard defaults
let store = PersistentKeyValueStoreImpl(dataStore: .userDefaults())

// App Group suite for sharing data between targets (e.g. app + widget)
let sharedDefaults = UserDefaults(suiteName: "group.com.example.myapp")!
let sharedStore = PersistentKeyValueStoreImpl(dataStore: .userDefaults(sharedDefaults))
```

**Characteristics:**
- Data persists across launches; removed on uninstall.
- Thread-safe (UserDefaults is thread-safe natively).
- Not encrypted — do not use for passwords or tokens.

### `Keychain`

Suited for credentials, tokens, cryptographic keys, and any data that must remain confidential.
Configure the keychain store via `DataStoreConfiguration.keychain(...)`.

```swift
extension PersistentKey {
    static let authToken: Self = "auth_token"
}

// Default accessibility (.whenUnlockedThisDeviceOnly)
let store = PersistentKeyValueStoreImpl(
    dataStore: .keychain(service: "com.example.myapp")
)

// Accessible after first unlock (survives device restarts without re-unlock)
let backgroundStore = PersistentKeyValueStoreImpl(
    dataStore: .keychain(
        service: "com.example.myapp",
        accessibility: .afterFirstUnlockThisDeviceOnly
    )
)

// Require biometric authentication before access
let biometricStore = PersistentKeyValueStoreImpl(
    dataStore: .keychain(
        service: "com.example.myapp",
        accessibility: .whenPasscodeSetThisDeviceOnly,
        authenticationPolicy: .biometryAny
    )
)

// iCloud Keychain sync across devices
let syncedStore = PersistentKeyValueStoreImpl(
    dataStore: .keychain(service: "com.example.myapp", synchronizable: true)
)

// Shared across app + extension via access group
let sharedStore = PersistentKeyValueStoreImpl(
    dataStore: .keychain(
        service: "com.example.myapp",
        accessGroup: "A1B2C3D4E5.group.shared"
    )
)
```

**Characteristics:**
- All data is encrypted by the Secure Enclave where available.
- Persists across app reinstalls by default.
- Thread-safe via the underlying Security framework.

---

## Encoding and Decoding

`PersistentKeyValueStoreImpl` defaults to `JSONEncoder` and `JSONDecoder`. Both can be replaced with any type conforming to `AnyEncoder` / `AnyDecoder`.

### Custom encoder/decoder configuration

The encoder and decoder are supplied at construction time:

```swift
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
encoder.keyEncodingStrategy = .convertToSnakeCase
encoder.outputFormatting = .sortedKeys

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
decoder.keyDecodingStrategy = .convertFromSnakeCase

let store = PersistentKeyValueStoreImpl(
    dataStore: .userDefaults(),
    encoder: encoder,
    decoder: decoder
)
```

### Custom serialisation format

Conform any encoder/decoder pair to `AnyEncoder` / `AnyDecoder` to use a completely different format (e.g. Property List, MessagePack):

```swift
import Foundation

struct PropertyListEncoder: AnyEncoder {
    private let plistEncoder = Foundation.PropertyListEncoder()

    func encode(_ model: some Encodable) throws -> Data {
        try plistEncoder.encode(model)
    }
}

struct PropertyListDecoder: AnyDecoder {
    private let plistDecoder = Foundation.PropertyListDecoder()

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try plistDecoder.decode(type, from: data)
    }
}

let store = PersistentKeyValueStoreImpl(
    dataStore: .userDefaults(),
    encoder: PropertyListEncoder(),
    decoder: PropertyListDecoder()
)
```

---

## Raw Data Access

Both store layers expose raw `Data` operations for cases where you already have serialised bytes:

```swift
extension PersistentKey {
    static let rawPayload: Self = "raw_payload"
}

// Write pre-encoded data directly (bypasses the encoder)
let rawBytes = try JSONEncoder().encode(myValue)
try store.set(data: rawBytes, for: .rawPayload)

// Read raw bytes (bypasses the decoder)
let data: Data? = try store.get(dataFor: .rawPayload)
```

---

## Custom Backing Store

Implement `PersistentKeyDataStore` to add a completely custom storage backend:

```swift
import PersistentStorage

final class InMemoryStore: PersistentKeyDataStore, @unchecked Sendable {
    private var storage: [PersistentKey: Data] = [:]

    func contains(dataFor key: PersistentKey) -> Bool {
        storage[key] != nil
    }

    func get(dataFor key: PersistentKey) throws -> Data? {
        storage[key]
    }

    func set(data: Data, for key: PersistentKey) throws {
        storage[key] = data
    }

    func remove(dataFor key: PersistentKey) throws {
        storage.removeValue(forKey: key)
    }
}

let store = PersistentKeyValueStoreImpl(dataStore: .custom(InMemoryStore()))
```

---

## Testing

### Mocking the high-level store

Use the `PersistentKeyValueStore` protocol to inject a test double at the call site:

```swift
protocol SettingsRepository {
    func loadTheme() throws -> Theme?
    func saveTheme(_ theme: Theme) throws
}

extension PersistentKey {
    static let theme: Self = "theme"
}

struct DefaultSettingsRepository: SettingsRepository {
    private var store: any PersistentKeyValueStore

    init(store: any PersistentKeyValueStore) {
        self.store = store
    }

    func loadTheme() throws -> Theme? {
        try store.get(valueFor: .theme)
    }

    func saveTheme(_ theme: Theme) throws {
        try store.set(value: theme, for: .theme)
    }
}
```

In tests, substitute any conforming type — for example a `PersistentKeyValueStoreImpl` backed by an isolated `UserDefaults` suite or the `InMemoryStore` shown above.

### Mocking the low-level store with `@Spyable`

`PersistentKeyDataStore` is decorated with
`@Spyable(behindPreprocessorFlag: "DEBUG", accessLevel: .public)`.
In `DEBUG` builds this macro generates a `PersistentKeyDataStoreSpy` class that tracks every
call, capturing arguments and supporting configurable return values and thrown errors:

```swift
import PersistentStorage
import Testing

@Suite("MyFeature store tests")
struct MyFeatureStoreTests {

    @Test
    func getValueCallsDataStore() throws {
        let spy = PersistentKeyDataStoreSpy()
        spy.getDataForReturnValue = try JSONEncoder().encode("hello")

        let store = PersistentKeyValueStoreImpl(dataStore: spy)
        let value: String? = try store.get(valueFor: "greeting")

        #expect(spy.getDataForCallsCount == 1)
        #expect(value == "hello")
    }
}
```

---

## Error Handling

`UserDefaults` operations never throw. Keychain operations throw `KeychainError` — a typed
`enum` conforming to both `Error` and `LocalizedError`. Pattern-match on the cases you care
about and fall back to the generic case for diagnostics:

```swift
do {
    let token: AuthToken? = try store.get(valueFor: .authToken)
} catch KeychainError.interactionNotAllowed {
    // Item is protected and the device is currently locked.
    // Re-try after the user unlocks.
} catch KeychainError.missingEntitlement {
    // The app target is missing the Keychain Sharing entitlement.
    // Check Build Settings → Signing & Capabilities.
} catch KeychainError.authFailed {
    // The user failed biometric / passcode authentication.
} catch let error as KeychainError {
    // Any other keychain failure — errorDescription provides a human-readable message.
    print("Keychain error: \(error.localizedDescription)")
}
```

Key `KeychainError` cases:

| Case | OSStatus | When it occurs |
|---|---|---|
| `.interactionNotAllowed` | -25308 | Device is locked; item requires auth |
| `.userCanceled` | -128 | User dismissed the biometric/passcode prompt |
| `.authFailed` | -25293 | Wrong biometric or passcode |
| `.missingEntitlement` | -34018 | App lacks Keychain Sharing entitlement |
| `.notAvailable` | -25291 | Keychain not yet available (e.g. first boot before unlock) |
| `.decode` | -26275 | Item data is corrupted or written by an incompatible version |
| `.accessControlCreationFailed` | — | Access control policy could not be created |
| `.unknown(OSStatus)` | — | Unmapped status; `localizedDescription` queries the Security framework |

---

## API Reference

### `PersistentKey`

A type-safe, `Hashable`, `RawRepresentable<String>` storage identifier.

| Member | Description |
|---|---|
| `init(stringLiteral:)` | Create from a string literal — used in `static let` key declarations |
| `init(_ stringValue: String)` | Create from a dynamic string at runtime |
| `init(rawValue: String)` | Create from `RawRepresentable` raw value |
| `let rawValue: String` | The backing string identifier passed to the storage backend |
| `var stringValue: String` | Alias for `rawValue` |

### `DataStoreConfiguration`

Factory struct passed to `PersistentKeyValueStoreImpl.init(dataStore:encoder:decoder:)`.

| Factory | Description |
|---|---|
| `.keychain(service:accessGroup:accessibility:authenticationPolicy:synchronizable:)` | Keychain-backed store |
| `.userDefaults(_ defaults:)` | `UserDefaults`-backed store (defaults to `.standard`) |
| `.custom(_ store:)` | Any custom `PersistentKeyDataStore` conformer |

### `PersistentKeyValueStore`

The primary read/write interface. Use `PersistentKeyValueStoreImpl` for a concrete instance.

| Member | Description |
|---|---|
| `var encoder: AnyEncoder { get }` | Serialisation strategy — set at construction time |
| `var decoder: AnyDecoder { get }` | Deserialisation strategy — set at construction time |
| `contains(valueFor:) -> Bool` | Check key existence |
| `get(dataFor:) throws -> Data?` | Read raw bytes (bypasses decoder) |
| `get<V: Decodable>(valueFor:) throws -> V?` | Read and decode a typed value |
| `set(data:for:) throws` | Write raw bytes (bypasses encoder) |
| `set(value: some Encodable, for:) throws` | Encode and write a value |
| `remove(valueFor:) throws` | Delete a value |

### `PersistentKeyDataStore`

The low-level backing-store protocol. Conform any type to plug in a custom storage mechanism.

| Member | Description |
|---|---|
| `contains(dataFor:) -> Bool` | Check key existence |
| `get(dataFor:) throws -> Data?` | Read raw bytes |
| `set(data:for:) throws` | Write raw bytes |
| `remove(dataFor:) throws` | Delete raw bytes |

### `KeychainError`

Thrown by Keychain-backed store operations. Conforms to `LocalizedError`.
See the [Error Handling](#error-handling) section for the full case list and pattern-matching example.

### `Keychain.Accessibility`

Controls when a keychain item can be read. Key values:

| Case | Backed up | Migrates to new device |
|---|---|---|
| `.whenUnlocked` | ✓ | ✓ |
| `.afterFirstUnlock` | ✓ | ✓ |
| `.whenUnlockedThisDeviceOnly` | ✗ | ✗ |
| `.afterFirstUnlockThisDeviceOnly` | ✗ | ✗ |
| `.whenPasscodeSetThisDeviceOnly` | ✗ | ✗ |

### `Keychain.AuthenticationPolicy`

An `OptionSet` of biometric / passcode constraints applied via `SecAccessControlCreateWithFlags`.
Use `.none` (default) for no additional authentication requirement.

| Member | Behaviour |
|---|---|
| `.none` | No authentication required beyond accessibility |
| `.userPresence` | Touch ID / Face ID or passcode |
| `.biometryAny` | Any enrolled biometric (no automatic passcode fallback — combine with `.devicePasscode` if desired) |
| `.biometryCurrentSet` | Current enrolled biometric only; revoked on biometry changes |
| `.devicePasscode` | Device passcode only |
| `.watch` | Apple Watch (iOS 14.5+) |

### `AnyEncoder`

Type-erased encoder protocol. `JSONEncoder` conforms out of the box.

| Member | Description |
|---|---|
| `encode(_ model: some Encodable) throws -> Data` | Encode a value to `Data` |

### `AnyDecoder`

Type-erased decoder protocol. `JSONDecoder` conforms out of the box.

| Member | Description |
|---|---|
| `decode<T: Decodable>(_ type:, from:) throws -> T` | Decode a value from `Data` |

---

## License

Copyright © 2025 adesso SE. All rights reserved.
