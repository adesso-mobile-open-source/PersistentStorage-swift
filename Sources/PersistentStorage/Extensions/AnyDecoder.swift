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

/// A type-erased protocol for decoder types.
///
/// Conform to this protocol to provide a custom deserialisation format (e.g. Property List,
/// MessagePack) to ``PersistentKeyValueStoreImpl``. `JSONDecoder` conforms out of the box.
///
/// ## Built-in Conformances
/// - `JSONDecoder` — decodes values from JSON data.
///
/// ## Custom Conformance
/// ```swift
/// struct PropertyListDecoder: AnyDecoder {
///     private let decoder = Foundation.PropertyListDecoder()
///
///     func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
///         try decoder.decode(type, from: data)
///     }
/// }
///
/// let store = PersistentKeyValueStoreImpl(
///     dataStore: .userDefaults(),
///     encoder: PropertyListEncoder(),
///     decoder: PropertyListDecoder()
/// )
/// ```
public protocol AnyDecoder: Sendable {
    /// Decodes a top-level value of the given type from its `Data` representation.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - data: The serialised bytes to decode from.
    /// - Returns: A decoded value of type `T`.
    /// - Throws: A decoding error (typically `DecodingError`) if the data cannot be decoded
    ///   into the requested type. The specific error depends on the conforming implementation.
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}
