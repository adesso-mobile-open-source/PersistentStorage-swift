//
//  Optional+Unwrap.swift
//  PersistentStorage
//
//  Created by Holloh, Niklas on 18.07.26 for adesso SE.
//  Copyright 2026 adesso SE
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//

/// Errors that occur when unwrapping an optional value.
enum OptionalError: Error {
    /// The unwrapped optional is nil.
    case optionalIsNil
}

extension Optional {
    /// Returns the wrapped value if the optional is not nil,
    /// throws otherwise.
    var unwrap: Wrapped {
        get throws {
            guard let value = self else {
                throw OptionalError.optionalIsNil
            }

            return value
        }
    }
}
