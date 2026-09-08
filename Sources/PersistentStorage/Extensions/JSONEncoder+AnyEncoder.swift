//
//  PersistentStorage
//
//  Created by Holloh, Niklas on 22.08.25 for adesso SE.
//  Copyright © 2025 adesso SE. All rights reserved.
//

import Foundation

/// Retroactive ``AnyEncoder`` conformance for `JSONEncoder`.
///
/// Configure the encoder before passing it to ``PersistentKeyValueStoreImpl``:
/// ```swift
/// let encoder = JSONEncoder()
/// encoder.dateEncodingStrategy = .iso8601
/// encoder.keyEncodingStrategy = .convertToSnakeCase
///
/// let store = PersistentKeyValueStoreImpl(
///     dataStore: .userDefaults(),
///     encoder: encoder
/// )
/// ```
extension JSONEncoder: AnyEncoder { }
