//
//  PersistentStorage
//
//  Created by Holloh, Niklas on 22.08.25 for adesso SE.
//  Copyright © 2025 adesso SE. All rights reserved.
//

import Foundation
@testable import PersistentStorage
import Testing

@Suite("UserDefaults PersistentKeyDataStore Tests")
struct UserDefaultsPersistentKeyDataStoreTests {
    // MARK: - Test Helpers

    private func createTestUserDefaults() -> UserDefaults {
        // Create a temporary UserDefaults instance for testing
        let suiteName = UUID().uuidString
        return UserDefaults(suiteName: suiteName)!
    }

    @Test
    func `contains(dataFor:) returns true when data exists in UserDefaults`() throws {
        // Given
        let userDefaults = createTestUserDefaults()
        let testKey: PersistentKey = "test_key"
        let testData = "test data".data(using: .utf8)!

        userDefaults.set(testData, forKey: testKey.stringValue)

        // When
        let result = userDefaults.contains(dataFor: testKey)

        // Then
        #expect(result == true)

        // Cleanup
        userDefaults.removeObject(forKey: testKey.stringValue)
    }

    @Test
    func `contains(dataFor:) returns false when no data exists in UserDefaults`() throws {
        // Given
        let userDefaults = createTestUserDefaults()
        let testKey: PersistentKey = "nonexistent_key"

        // When
        let result = userDefaults.contains(dataFor: testKey)

        // Then
        #expect(result == false)
    }

    @Test
    func `get(dataFor:) returns stored data from UserDefaults`() throws {
        // Given
        let userDefaults = createTestUserDefaults()
        let testKey: PersistentKey = "test_key"
        let testData = "test data".data(using: .utf8)!

        userDefaults.set(testData, forKey: testKey.stringValue)

        // When
        let result = try userDefaults.get(dataFor: testKey)

        // Then
        #expect(result == testData)

        // Cleanup
        userDefaults.removeObject(forKey: testKey.stringValue)
    }

    @Test
    func `get(dataFor:) returns nil when no data exists in UserDefaults`() throws {
        // Given
        let userDefaults = createTestUserDefaults()
        let testKey: PersistentKey = "nonexistent_key"

        // When
        let result = try userDefaults.get(dataFor: testKey)

        // Then
        #expect(result == nil)
    }

    @Test
    func `set(data:for:) stores data successfully in UserDefaults`() throws {
        // Given
        let userDefaults = createTestUserDefaults()
        let testKey: PersistentKey = "test_key"
        let testData = "test data".data(using: .utf8)!

        // When
        try userDefaults.set(data: testData, for: testKey)

        // Then
        let storedData = userDefaults.data(forKey: testKey.stringValue)
        #expect(storedData == testData)

        // Cleanup
        userDefaults.removeObject(forKey: testKey.stringValue)
    }

    @Test
    func `remove(dataFor:) removes stored data from UserDefaults`() throws {
        // Given
        let userDefaults = createTestUserDefaults()
        let testKey: PersistentKey = "test_key"
        let testData = "test data".data(using: .utf8)!

        userDefaults.set(testData, forKey: testKey.stringValue)
        #expect(userDefaults.data(forKey: testKey.stringValue) != nil) // Verify data is stored

        // When
        try userDefaults.remove(dataFor: testKey)

        // Then
        let storedData = userDefaults.data(forKey: testKey.stringValue)
        #expect(storedData == nil)
    }

    @Test
    func `remove(dataFor:) is safe when no data exists in UserDefaults`() throws {
        // Given
        let userDefaults = createTestUserDefaults()
        let testKey: PersistentKey = "nonexistent_key"

        // When/Then (should not throw)
        try userDefaults.remove(dataFor: testKey)
    }

    @Test
    func `set(data:for:) overwrites existing data in UserDefaults`() throws {
        // Given
        let userDefaults = createTestUserDefaults()
        let testKey: PersistentKey = "test_key"
        let initialData = "initial data".data(using: .utf8)!
        let newData = "new data".data(using: .utf8)!

        userDefaults.set(initialData, forKey: testKey.stringValue)
        #expect(userDefaults.data(forKey: testKey.stringValue) == initialData)

        // When
        try userDefaults.set(data: newData, for: testKey)

        // Then
        let storedData = userDefaults.data(forKey: testKey.stringValue)
        #expect(storedData == newData)
        #expect(storedData != initialData)

        // Cleanup
        userDefaults.removeObject(forKey: testKey.stringValue)
    }

    @Test
    func `set(data:for:) works with empty Data in UserDefaults`() throws {
        // Given
        let userDefaults = createTestUserDefaults()
        let testKey: PersistentKey = "test_key"
        let emptyData = Data()

        // When
        try userDefaults.set(data: emptyData, for: testKey)
        let result = try userDefaults.get(dataFor: testKey)

        // Then
        #expect(result == emptyData)
        #expect(userDefaults.contains(dataFor: testKey) == true)

        // Cleanup
        userDefaults.removeObject(forKey: testKey.stringValue)
    }
}
