//
//  PersistentStorage
//
//  Created by Holloh, Niklas on 22.08.25 for adesso SE.
//  Copyright © 2025 adesso SE. All rights reserved.
//

import Foundation

/// Retroactive ``AnyDecoder`` conformance for `JSONDecoder`.
///
/// Configure the decoder before passing it to ``PersistentKeyValueStoreImpl``:
/// ```swift
/// let decoder = JSONDecoder()
/// decoder.dateDecodingStrategy = .iso8601
/// decoder.keyDecodingStrategy = .convertFromSnakeCase
///
/// let store = PersistentKeyValueStoreImpl(
///     dataStore: .userDefaults(),
///     decoder: decoder
/// )
/// ```
extension JSONDecoder: AnyDecoder { }
