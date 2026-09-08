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

/// A type-erased protocol for encoder types.
///
/// Conform to this protocol to provide a custom serialisation format (e.g. Property List,
/// MessagePack) to ``PersistentKeyValueStoreImpl``. `JSONEncoder` conforms out of the box.
///
/// ## Built-in Conformances
/// - `JSONEncoder` — encodes values as JSON data.
///
/// ## Custom Conformance
/// ```swift
/// struct PropertyListEncoder: AnyEncoder {
///     private let encoder = Foundation.PropertyListEncoder()
///
///     func encode(_ model: some Encodable) throws -> Data {
///         try encoder.encode(model)
///     }
/// }
///
/// let store = PersistentKeyValueStoreImpl(
///     dataStore: .userDefaults(),
///     encoder: PropertyListEncoder(),
///     decoder: PropertyListDecoder()
/// )
/// ```
public protocol AnyEncoder: Sendable {
    /// Encodes a value into its `Data` representation.
    ///
    /// - Parameter model: The `Encodable` value to encode.
    /// - Returns: The encoded bytes.
    /// - Throws: An `EncodingError` if the value cannot be encoded. The specific error
    ///   depends on the conforming implementation.
    func encode(_ model: some Encodable) throws -> Data
}
