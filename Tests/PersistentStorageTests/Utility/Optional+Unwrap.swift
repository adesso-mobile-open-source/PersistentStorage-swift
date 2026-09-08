//
//  Optional+Unwrap.swift
//  PersistentStorage
//
//  Created by Holloh, Niklas on 18.07.26.
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
