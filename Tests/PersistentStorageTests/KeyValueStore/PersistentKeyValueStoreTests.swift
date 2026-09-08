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

@Suite("PersistentKeyValueStore Tests")
struct PersistentKeyValueStoreTests {
    // MARK: - Test Helpers

    // Note: Tests using mock objects (AnyEncoderMock, AnyDecoderMock) work with String types
    // since the manual mock decoder returns string representations. For complex object testing,
    // see the integration tests which use real encoder/decoder implementations.

    @Test
    func `persistentKeyValueStoreImpl initializes encoder and decoder when created with a data store`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()

        // When
        let keyValueStore = PersistentKeyValueStoreImpl(dataStore: mockDataStore)

        // Then
        #expect(keyValueStore.encoder is JSONEncoder)
        #expect(keyValueStore.decoder is JSONDecoder)
    }

    @Test
    func `contains(valueFor:) returns true when data store contains the value`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let keyValueStore = PersistentKeyValueStoreImpl(dataStore: mockDataStore)
        let testKey: PersistentKey = "test_key"

        mockDataStore.containsDataForReturnValue = true

        // When
        let result = keyValueStore.contains(valueFor: testKey)

        // Then
        #expect(result == true)
        #expect(mockDataStore.containsDataForCallsCount == 1)
        #expect(mockDataStore.containsDataForReceivedKey == testKey)
    }

    @Test
    func `get(dataFor:) returns data from data store when data exists`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let keyValueStore = PersistentKeyValueStoreImpl(dataStore: mockDataStore)
        let testKey: PersistentKey = "test_key"
        let testData = Data("test data".utf8)

        mockDataStore.getDataForReturnValue = testData

        // When
        let result = try keyValueStore.get(dataFor: testKey)

        // Then
        #expect(result == testData)
        #expect(mockDataStore.getDataForCallsCount == 1)
        #expect(mockDataStore.getDataForReceivedKey == testKey)
    }

    @Test
    func `get(dataFor:) returns nil when data store has no data`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let keyValueStore = PersistentKeyValueStoreImpl(dataStore: mockDataStore)
        let testKey: PersistentKey = "test_key"

        mockDataStore.getDataForReturnValue = nil

        // When
        let result = try keyValueStore.get(dataFor: testKey)

        // Then
        #expect(result == nil)
        #expect(mockDataStore.getDataForCallsCount == 1)
    }

    @Test
    func `get(valueFor:) decodes and returns typed value when decoder succeeds`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let mockDecoder = AnyDecoderMock()
        let keyValueStore = PersistentKeyValueStoreImpl(dataStore: mockDataStore, decoder: mockDecoder)

        let testKey: PersistentKey = "test_key"
        let testValue = "John" // Using string for mock decoder
        let testData = Data("test data".utf8)

        mockDataStore.getDataForReturnValue = testData
        mockDecoder.decodeFromReturnValue = testValue

        // When
        let result: String? = try keyValueStore.get(valueFor: testKey)

        // Then
        #expect(result == testValue)
        #expect(mockDataStore.getDataForCallsCount == 1)
        #expect(mockDecoder.decodeFromCallsCount == 1)
        #expect(mockDecoder.decodeFromReceivedArguments?.data == testData)
    }

    @Test
    func `get(valueFor:) returns nil when no data exists`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let mockDecoder = AnyDecoderMock()
        let keyValueStore = PersistentKeyValueStoreImpl(dataStore: mockDataStore, decoder: mockDecoder)

        let testKey: PersistentKey = "test_key"

        mockDataStore.getDataForReturnValue = nil

        // When
        let result: String? = try keyValueStore.get(valueFor: testKey)

        // Then
        #expect(result == nil)
        #expect(mockDataStore.getDataForCallsCount == 1)
        #expect(mockDecoder.decodeFromCallsCount == 0) // Should not be called when no data
    }

    @Test
    func `set(data:for:) stores raw data by delegating to data store`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let keyValueStore = PersistentKeyValueStoreImpl(dataStore: mockDataStore)
        let testKey: PersistentKey = "test_key"
        let testData = Data("test data".utf8)

        // When
        try keyValueStore.set(data: testData, for: testKey)

        // Then
        #expect(mockDataStore.setDataForCallsCount == 1)
        #expect(mockDataStore.setDataForReceivedArguments?.data == testData)
        #expect(mockDataStore.setDataForReceivedArguments?.key == testKey)
    }

    @Test
    func `set(value:for:) encodes and stores typed value`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let mockEncoder = AnyEncoderMock()
        let keyValueStore = PersistentKeyValueStoreImpl(dataStore: mockDataStore, encoder: mockEncoder)

        let testKey: PersistentKey = "test_key"
        let testValue = "John" // Using string for mock encoder
        let encodedData = Data("encoded data".utf8)

        mockEncoder.encodeReturnValue = encodedData

        // When
        try keyValueStore.set(value: testValue, for: testKey)

        // Then
        #expect(mockEncoder.encodeCallsCount == 1)
        #expect(mockEncoder.encodeReceivedModel as? String == testValue)
        #expect(mockDataStore.setDataForCallsCount == 1)
        #expect(mockDataStore.setDataForReceivedArguments?.data == encodedData)
        #expect(mockDataStore.setDataForReceivedArguments?.key == testKey)
    }

    @Test
    func `remove(valueFor:) removes data via data store`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let keyValueStore = PersistentKeyValueStoreImpl(dataStore: mockDataStore)
        let testKey: PersistentKey = "test_key"

        // When
        try keyValueStore.remove(valueFor: testKey)

        // Then
        #expect(mockDataStore.removeDataForCallsCount == 1)
        #expect(mockDataStore.removeDataForReceivedKey == testKey)
    }

    @Test
    func `encoder and decoder are set at init time on PersistentKeyValueStoreImpl`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let customEncoder = AnyEncoderMock()
        let customDecoder = AnyDecoderMock()

        // When
        let keyValueStore = PersistentKeyValueStoreImpl(
            dataStore: mockDataStore,
            encoder: customEncoder,
            decoder: customDecoder
        )

        // Then
        #expect(keyValueStore.encoder as? AnyEncoderMock === customEncoder)
        #expect(keyValueStore.decoder as? AnyDecoderMock === customDecoder)
    }

    @Test
    func `persistentKeyValueStore protocol methods are available and delegate correctly`() throws {
        // Given
        let mockDataStore = PersistentKeyDataStoreSpy()
        let keyValueStore: PersistentKeyValueStore = PersistentKeyValueStoreImpl(dataStore: mockDataStore)

        mockDataStore.containsDataForReturnValue = false
        mockDataStore.getDataForReturnValue = nil

        // When/Then - Verify all protocol methods are available
        #expect(keyValueStore.contains(valueFor: "test") == false)
        #expect(try keyValueStore.get(dataFor: "test") == nil)

        let testData = Data("test".utf8)
        try keyValueStore.set(data: testData, for: "test")
        try keyValueStore.remove(valueFor: "test")

        // Verify calls were made
        #expect(mockDataStore.containsDataForCallsCount >= 1)
        #expect(mockDataStore.getDataForCallsCount >= 1)
        #expect(mockDataStore.setDataForCallsCount >= 1)
        #expect(mockDataStore.removeDataForCallsCount >= 1)
    }
}
