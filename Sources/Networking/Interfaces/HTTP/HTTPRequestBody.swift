//
//  HTTPRequestBody.swift
//
//
//  Created by Andy Heard on 05/10/2023.
//

import Foundation

/// A wrapper for the body of a ``HTTPRequest``, providing multiple ways to define the contents of the request body.
public enum HTTPRequestBody {
    
    // MARK: - Cases
    
    /// An object to be encoded to JSON.
    case json(Encodable)
    
    /// Raw data that is to be used unmodified.
    case data(Data)
}
