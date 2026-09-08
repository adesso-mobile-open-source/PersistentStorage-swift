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

public class AnyEncoderMock: AnyEncoder, @unchecked Sendable {
    public init() { }

    public var encodeCallsCount = 0
    public var encodeCalled: Bool {
        encodeCallsCount > 0
    }

    public var encodeReceivedModel: Any?
    public var encodeReceivedInvocations: [Any] = []
    public var encodeThrowableError: (any Error)?
    public var encodeReturnValue: Data?
    public var encodeClosure: ((Any) throws -> Data)?

    /// Encodes the model into a `Data` representation.
    /// - Parameter model: The `Encodable` conforming model to encode.
    /// - Returns: The encoded data representation.
    /// - Throws: An encoding error if the operation fails.
    public func encode(_ model: some Encodable) throws -> Data {
        encodeCallsCount += 1
        encodeReceivedModel = model
        encodeReceivedInvocations.append(model)
        if let encodeThrowableError {
            throw encodeThrowableError
        }
        if let encodeClosure {
            return try encodeClosure(model)
        } else {
            return try encodeReturnValue.unwrap
        }
    }
}
