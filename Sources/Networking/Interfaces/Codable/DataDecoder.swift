import Foundation

/// A type that defines a method for decoding objects from `Data`.
///
/// The `JSONDecoder` and `PropertyListDecoder` Swift types conform to this protocol by default.
public protocol DataDecoder {
    
    /// Converts a decodable object from `Data`.
    /// - Parameters:
    ///   - type: The type to attempt to decode.
    ///   - from: The raw `Data` that will be decoded.
    /// - Returns: The decoded object.
    /// - Throws: Any decoding errors, usually `DecodingError`.
    func decode<T: Decodable>(
        _ type: T.Type,
        from: Data
    ) throws -> T
}

#if swift(>=6.0)
extension JSONDecoder: DataDecoder {}
extension JSONDecoder: @retroactive @unchecked Sendable {}
extension PropertyListDecoder: DataDecoder {}
extension PropertyListDecoder: @retroactive @unchecked Sendable {}
#else
extension JSONDecoder: DataDecoder & @unchecked Sendable {}
extension PropertyListDecoder: DataDecoder & @unchecked Sendable {}

#endif
