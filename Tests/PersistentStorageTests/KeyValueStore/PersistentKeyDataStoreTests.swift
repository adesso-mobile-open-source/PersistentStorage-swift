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
@testable import PersistentStorage
import Spyable
import Testing

@Suite("PersistentKeyDataStore Tests")
struct PersistentKeyDataStoreTests {
    // These tests focus on the protocol interface and would use spy objects
    // to test implementations that depend on PersistentKeyDataStore

    @Test
    func `persistentKeyDataStore protocol provides contains/get/set/remove methods`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let testKey: PersistentKey = "test_key"
        let testData = Data("test data".utf8)

        // Configure spy behavior
        mockDataStore.containsDataForReturnValue = true
        mockDataStore.getDataForReturnValue = testData

        // When/Then - Verify all protocol methods are available
        let containsResult = mockDataStore.contains(dataFor: testKey)
        let getData = try mockDataStore.get(dataFor: testKey)
        try mockDataStore.set(data: testData, for: testKey)
        try mockDataStore.remove(dataFor: testKey)

        // Verify spy recorded all calls
        #expect(containsResult == true)
        #expect(getData == testData)
        #expect(mockDataStore.containsDataForCallsCount == 1)
        #expect(mockDataStore.getDataForCallsCount == 1)
        #expect(mockDataStore.setDataForCallsCount == 1)
        #expect(mockDataStore.removeDataForCallsCount == 1)
    }

    @Test
    func `contains(dataFor:) returns configured boolean and receives correct key`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let testKey: PersistentKey = "signature_test"

        mockDataStore.containsDataForReturnValue = false

        // When
        let result = mockDataStore.contains(dataFor: testKey)

        // Then
        #expect(result == false)
        #expect(mockDataStore.containsDataForReceivedKey == testKey)
    }

    @Test
    func `get(dataFor:) returns data and receives correct key`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let testKey: PersistentKey = "signature_test"
        let testData = Data("signature data".utf8)

        mockDataStore.getDataForReturnValue = testData

        // When
        let result = try mockDataStore.get(dataFor: testKey)

        // Then
        #expect(result == testData)
        #expect(mockDataStore.getDataForReceivedKey == testKey)
    }

    @Test
    func `set(data:for:) stores data and records calls`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let testKey: PersistentKey = "signature_test"
        let testData = Data("signature data".utf8)

        // When
        try mockDataStore.set(data: testData, for: testKey)

        // Then
        #expect(mockDataStore.setDataForCallsCount == 1)
        #expect(mockDataStore.setDataForReceivedArguments?.data == testData)
        #expect(mockDataStore.setDataForReceivedArguments?.key == testKey)
    }

    @Test
    func `remove(dataFor:) removes data and records the key`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let testKey: PersistentKey = "signature_test"

        // When
        try mockDataStore.remove(dataFor: testKey)

        // Then
        #expect(mockDataStore.removeDataForCallsCount == 1)
        #expect(mockDataStore.removeDataForReceivedKey == testKey)
    }

    @Test
    func `multiple calls to data store methods are tracked correctly`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let keys: [PersistentKey] = ["key1", "key2", "key3"]
        let data = Data("test data".utf8)

        mockDataStore.containsDataForReturnValue = true
        mockDataStore.getDataForReturnValue = data

        // When
        for key in keys {
            _ = mockDataStore.contains(dataFor: key)
            _ = try mockDataStore.get(dataFor: key)
            try mockDataStore.set(data: data, for: key)
            try mockDataStore.remove(dataFor: key)
        }

        // Then
        #expect(mockDataStore.containsDataForCallsCount == keys.count)
        #expect(mockDataStore.getDataForCallsCount == keys.count)
        #expect(mockDataStore.setDataForCallsCount == keys.count)
        #expect(mockDataStore.removeDataForCallsCount == keys.count)
    }
}
