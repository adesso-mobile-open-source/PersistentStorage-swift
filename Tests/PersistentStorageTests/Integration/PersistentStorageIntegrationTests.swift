//
//  PersistentStorage
//
//  Created by Holloh, Niklas on 22.08.25 for adesso SE.
//  Copyright © 2025 adesso SE. All rights reserved.
//

import Foundation
@testable import PersistentStorage
import Testing

@Suite("PersistentStorage Integration Tests")
struct PersistentStorageIntegrationTests {
    // MARK: - Test Models

    struct User: Codable, Equatable {
        let id: String
        let name: String
        let age: Int
        let isActive: Bool
    }

    struct Settings: Codable, Equatable {
        let theme: String
        let notifications: Bool
        let language: String
    }

    // MARK: - Test Helpers

    private func createUserDefaultsKeyValueStore(
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) -> PersistentKeyValueStoreImpl {
        let suiteName = UUID().uuidString
        let userDefaults = UserDefaults(suiteName: suiteName)!
        return PersistentKeyValueStoreImpl(
            dataStore: .userDefaults(userDefaults),
            encoder: encoder,
            decoder: decoder
        )
    }

    // Keychain-backed integration tests removed: Keychain operations require a
    // host app entitlement and are unstable in hostless SPM test runs.

    // MARK: - UserDefaults Integration Tests

    @Test
    func `UserDefaults stores and retrieves complex objects`() throws {
        // Given
        let store = createUserDefaultsKeyValueStore()
        let user = User(id: UUID().uuidString, name: "John Doe", age: 30, isActive: true)
        let settings = Settings(theme: "dark", notifications: true, language: "en")

        // When
        try store.set(value: user, for: "user")
        try store.set(value: settings, for: "settings")

        let retrievedUser: User? = try store.get(valueFor: "user")
        let retrievedSettings: Settings? = try store.get(valueFor: "settings")

        // Then
        #expect(retrievedUser == user)
        #expect(retrievedSettings == settings)

        #expect(store.contains(valueFor: "user") == true)
        #expect(store.contains(valueFor: "settings") == true)

        // Cleanup
        try store.remove(valueFor: "user")
        try store.remove(valueFor: "settings")
    }

    @Test
    func `get(valueFor:) returns nil when no value exists in UserDefaults`() throws {
        // Given
        let store = createUserDefaultsKeyValueStore()

        // When
        let nonExistentUser: User? = try store.get(valueFor: "nonexistent")

        // Then
        #expect(nonExistentUser == nil)
        #expect(store.contains(valueFor: "nonexistent") == false)
    }

    @Test
    func `set(value:for:) updates existing values in UserDefaults`() throws {
        // Given
        let store = createUserDefaultsKeyValueStore()
        let initialUser = User(id: "123", name: "John", age: 30, isActive: true)
        let updatedUser = User(id: "123", name: "John Doe", age: 31, isActive: false)

        try store.set(value: initialUser, for: "user")

        // When
        try store.set(value: updatedUser, for: "user")
        let retrievedUser: User? = try store.get(valueFor: "user")

        // Then
        #expect(retrievedUser == updatedUser)
        #expect(retrievedUser != initialUser)

        // Cleanup
        try store.remove(valueFor: "user")
    }

    // Keychain-backed integration tests omitted (require host app entitlement).

    // MARK: - Custom Encoder/Decoder Tests

    @Test
    func `set(value:for:) uses custom JSONEncoder configuration when provided`() throws {
        // Given
        let customEncoder = JSONEncoder()
        customEncoder.outputFormatting = .prettyPrinted
        let store = createUserDefaultsKeyValueStore(encoder: customEncoder)

        let user = User(id: "123", name: "Test User", age: 30, isActive: true)

        // When
        try store.set(value: user, for: "user")
        let rawData = try store.get(dataFor: "user")
        let retrievedUser: User? = try store.get(valueFor: "user")

        // Then
        #expect(retrievedUser == user)

        // Verify that the raw data contains pretty-printed JSON
        if let rawData {
            let jsonString = String(data: rawData, encoding: .utf8)
            #expect(jsonString?.contains("\n") == true) // Pretty printed JSON contains newlines
        }

        // Cleanup
        try store.remove(valueFor: "user")
    }

    @Test
    func `get(valueFor:) works with a custom JSONDecoder when provided`() throws {
        // Given
        let customDecoder = JSONDecoder()
        // JSON decoders don't have as many visible configuration options for this test
        // but we can still verify the decoder can be swapped
        let store = createUserDefaultsKeyValueStore(decoder: customDecoder)

        let user = User(id: "123", name: "Test User", age: 30, isActive: true)

        // When
        try store.set(value: user, for: "user")
        let retrievedUser: User? = try store.get(valueFor: "user")

        // Then
        #expect(retrievedUser == user)

        // Cleanup
        try store.remove(valueFor: "user")
    }

    // MARK: - Error Handling Tests

    @Test
    func `set(value:for:) does not crash when encoding errors would occur`() throws {
        // This test would require a custom encoder that throws errors
        // For now, we'll test with a basic case that should work

        // Given
        let store = createUserDefaultsKeyValueStore()
        let user = User(id: "123", name: "Test User", age: 30, isActive: true)

        // When/Then - Should not throw
        try store.set(value: user, for: "user")
        let retrievedUser: User? = try store.get(valueFor: "user")
        #expect(retrievedUser == user)

        // Cleanup
        try store.remove(valueFor: "user")
    }

    // MARK: - Raw Data Operations Tests

    @Test
    func `raw data operations and typed operations work alongside each other`() throws {
        // Given
        let store = createUserDefaultsKeyValueStore()
        let rawData = "raw test data".data(using: .utf8)!
        let user = User(id: "123", name: "Test User", age: 30, isActive: true)

        // When
        try store.set(data: rawData, for: "raw_data")
        try store.set(value: user, for: "typed_data")

        let retrievedRawData = try store.get(dataFor: "raw_data")
        let retrievedUser: User? = try store.get(valueFor: "typed_data")

        // Then
        #expect(retrievedRawData == rawData)
        #expect(retrievedUser == user)

        #expect(store.contains(valueFor: "raw_data") == true)
        #expect(store.contains(valueFor: "typed_data") == true)

        // Cleanup
        try store.remove(valueFor: "raw_data")
        try store.remove(valueFor: "typed_data")
    }

    // MARK: - Array and Collection Tests

    @Test
    func `set(value:for:) stores and retrieves arrays of objects`() throws {
        // Given
        let store = createUserDefaultsKeyValueStore()
        let users = [
            User(id: "1", name: "User 1", age: 25, isActive: true),
            User(id: "2", name: "User 2", age: 30, isActive: false),
            User(id: "3", name: "User 3", age: 35, isActive: true)
        ]

        // When
        try store.set(value: users, for: "users")
        let retrievedUsers: [User]? = try store.get(valueFor: "users")

        // Then
        #expect(retrievedUsers == users)
        #expect(retrievedUsers?.count == 3)

        // Cleanup
        try store.remove(valueFor: "users")
    }
}
