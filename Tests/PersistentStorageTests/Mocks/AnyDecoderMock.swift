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

public class AnyDecoderMock: AnyDecoder, @unchecked Sendable {
    public init() { }

    public var decodeFromCallsCount = 0
    public var decodeFromCalled: Bool {
        decodeFromCallsCount > 0
    }

    public var decodeFromReceivedArguments: (String, data: Data)?
    public var decodeFromReceivedInvocations: [(String, data: Data)] = []
    public var decodeFromThrowableError: (any Error)?
    public var decodeFromReturnValue: Any?
    public var decodeFromClosure: ((String, Data) throws -> Any)?

    /// Decodes a top-level value of the given type from the given data representation.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - data: The data to decode from.
    /// - Returns: A value of the requested type.
    /// - Throws: `DecodingError.dataCorrupted` if values requested from the payload are
    ///   corrupted, or if the given data is not valid for the decoder format.
    /// - Throws: An error if any value throws an error during decoding.
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        decodeFromCallsCount += 1
        decodeFromReceivedArguments = ("\(type)", data)
        decodeFromReceivedInvocations.append(("\(type)", data))
        if let decodeFromThrowableError {
            throw decodeFromThrowableError
        }
        if let decodeFromClosure {
            return try (decodeFromClosure("\(type)", data) as? T).unwrap
        } else {
            return try (decodeFromReturnValue as? T).unwrap
        }
    }
}
