import Foundation

/// A type that defines a method for decoding from `Data`.
public protocol DataDecoder {
    
    /// Converts a decodable object from `Data`.
    /// - Parameters:
    ///   - type: The type to attempt to decode.
    ///   - from: The raw `Data` that will be decoded.
    /// - Returns: The decoded object.
    func decode<T: Decodable>(_ type: T.Type, from: Data) throws -> T
}

extension JSONDecoder: DataDecoder {}
extension PropertyListDecoder: DataDecoder {}
