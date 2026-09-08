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
