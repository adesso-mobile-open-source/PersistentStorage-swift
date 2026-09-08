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

// Keychain unit tests are defined below but are disabled via a compile-time flag because
// SecItem* operations require a host app entitlement that is not available in a hostless
// `swift test` run. To run these tests, execute them from an Xcode scheme that targets a
// simulator or device.
//
// To enable: pass -D KEYCHAIN_TESTS_ENABLED to the Swift compiler for the test target, or
// change the condition below to `true` for a local run.

#if KEYCHAIN_TESTS_ENABLED

import Foundation
@testable import PersistentStorage
import Testing

/// A unique service name per test run so parallel runs don't interfere.
private let testService = "com.adesso.PersistentStorageTests.\(UUID().uuidString)"

@Suite("KeychainDataStore Tests", .serialized)
struct KeychainDataStoreTests {
    // Helper: a fresh store with the shared test service and default accessibility.
    private func makeStore(
        accessibility: Keychain.Accessibility = .whenUnlockedThisDeviceOnly,
        synchronizable: Bool = false
    ) -> KeychainDataStore {
        KeychainDataStore(
            service: testService,
            accessGroup: nil,
            accessibility: accessibility,
            authenticationPolicy: nil,
            synchronizable: synchronizable
        )
    }

    // Helper: removes all items written during a test.
    private func cleanup(store: KeychainDataStore, keys: [PersistentKey]) {
        for key in keys {
            try? store.remove(dataFor: key)
        }
    }

    // MARK: - contains

    @Test
    func `contains returns false when item does not exist`() {
        let store = makeStore()
        let key: PersistentKey = "keychain_contains_absent"
        defer { cleanup(store: store, keys: [key]) }

        #expect(store.contains(dataFor: key) == false)
    }

    @Test
    func `contains returns true after item is written`() throws {
        let store = makeStore()
        let key: PersistentKey = "keychain_contains_present"
        defer { cleanup(store: store, keys: [key]) }

        try store.set(data: Data([0x01]), for: key)
        #expect(store.contains(dataFor: key) == true)
    }

    @Test
    func `contains returns false after item is removed`() throws {
        let store = makeStore()
        let key: PersistentKey = "keychain_contains_after_remove"
        defer { cleanup(store: store, keys: [key]) }

        try store.set(data: Data([0x01]), for: key)
        try store.remove(dataFor: key)
        #expect(store.contains(dataFor: key) == false)
    }

    // MARK: - get

    @Test
    func `get returns nil when item does not exist`() throws {
        let store = makeStore()
        let key: PersistentKey = "keychain_get_absent"
        defer { cleanup(store: store, keys: [key]) }

        let result = try store.get(dataFor: key)
        #expect(result == nil)
    }

    @Test
    func `get returns the data that was set`() throws {
        let store = makeStore()
        let key: PersistentKey = "keychain_get_roundtrip"
        let payload = Data("hello keychain".utf8)
        defer { cleanup(store: store, keys: [key]) }

        try store.set(data: payload, for: key)
        let result = try store.get(dataFor: key)
        #expect(result == payload)
    }

    @Test
    func `get returns nil after item is removed`() throws {
        let store = makeStore()
        let key: PersistentKey = "keychain_get_after_remove"
        defer { cleanup(store: store, keys: [key]) }

        try store.set(data: Data([0xFF]), for: key)
        try store.remove(dataFor: key)
        let result = try store.get(dataFor: key)
        #expect(result == nil)
    }

    // MARK: - set (upsert semantics)

    @Test
    func `set inserts a new item`() throws {
        let store = makeStore()
        let key: PersistentKey = "keychain_set_insert"
        let payload = Data([0xAA, 0xBB])
        defer { cleanup(store: store, keys: [key]) }

        try store.set(data: payload, for: key)
        let result = try store.get(dataFor: key)
        #expect(result == payload)
    }

    @Test
    func `set overwrites an existing item`() throws {
        let store = makeStore()
        let key: PersistentKey = "keychain_set_overwrite"
        let initial = Data([0x01])
        let updated = Data([0x02, 0x03])
        defer { cleanup(store: store, keys: [key]) }

        try store.set(data: initial, for: key)
        try store.set(data: updated, for: key)

        let result = try store.get(dataFor: key)
        #expect(result == updated)
    }

    @Test
    func `set with empty Data stores and retrieves correctly`() throws {
        let store = makeStore()
        let key: PersistentKey = "keychain_set_empty"
        defer { cleanup(store: store, keys: [key]) }

        try store.set(data: Data(), for: key)
        let result = try store.get(dataFor: key)
        // Keychain may return nil for empty data on some OS versions; accept both outcomes.
        #expect(result == Data() || result == nil)
    }

    @Test
    func `set is repeatable with the same data`() throws {
        let store = makeStore()
        let key: PersistentKey = "keychain_set_idempotent"
        let payload = Data("idempotent".utf8)
        defer { cleanup(store: store, keys: [key]) }

        try store.set(data: payload, for: key)
        try store.set(data: payload, for: key)
        let result = try store.get(dataFor: key)
        #expect(result == payload)
    }

    // MARK: - remove

    @Test
    func `remove succeeds when item exists`() throws {
        let store = makeStore()
        let key: PersistentKey = "keychain_remove_exists"
        defer { cleanup(store: store, keys: [key]) }

        try store.set(data: Data([0x01]), for: key)
        try store.remove(dataFor: key)
        #expect(store.contains(dataFor: key) == false)
    }

    @Test
    func `remove is a no-op when item does not exist`() throws {
        let store = makeStore()
        let key: PersistentKey = "keychain_remove_absent"

        // Must not throw.
        try store.remove(dataFor: key)
    }

    @Test
    func `remove does not affect other keys`() throws {
        let store = makeStore()
        let keyA: PersistentKey = "keychain_multi_a"
        let keyB: PersistentKey = "keychain_multi_b"
        defer { cleanup(store: store, keys: [keyA, keyB]) }

        let payloadA = Data("alpha".utf8)
        let payloadB = Data("beta".utf8)

        try store.set(data: payloadA, for: keyA)
        try store.set(data: payloadB, for: keyB)
        try store.remove(dataFor: keyA)

        #expect(store.contains(dataFor: keyA) == false)
        let resultB = try store.get(dataFor: keyB)
        #expect(resultB == payloadB)
    }

    // MARK: - Accessibility variants (structural / no-crash tests)

    @Test
    func `set with afterFirstUnlock accessibility does not throw`() throws {
        let store = makeStore(accessibility: .afterFirstUnlock)
        let key: PersistentKey = "keychain_accessibility_afterFirstUnlock"
        defer { cleanup(store: store, keys: [key]) }

        try store.set(data: Data([0x01]), for: key)
        let result = try store.get(dataFor: key)
        #expect(result == Data([0x01]))
    }

    @Test
    func `set with whenUnlocked accessibility does not throw`() throws {
        let store = makeStore(accessibility: .whenUnlocked)
        let key: PersistentKey = "keychain_accessibility_whenUnlocked"
        defer { cleanup(store: store, keys: [key]) }

        try store.set(data: Data([0x02]), for: key)
        let result = try store.get(dataFor: key)
        #expect(result == Data([0x02]))
    }
}

#endif // KEYCHAIN_TESTS_ENABLED
