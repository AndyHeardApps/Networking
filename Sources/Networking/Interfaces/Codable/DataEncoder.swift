import Foundation

/// A type that defines a method for encoding objects to `Data`.
///
/// The `JSONEncoder` and `PropertyListEncoder` Swift types conform to this protocol by default.
public protocol DataEncoder {

    /// Converts an encodable object to `Data`.
    /// - Parameters:
    ///   - value: The value to attempt to encode.
    /// - Returns: The data representation of the value.
    /// - Throws: Any encoding errors, usually `EncodingError`.
    func encode(_ value: some Encodable) throws -> Data
}

#if swift(>=6.0)
extension JSONEncoder: DataEncoder {}
extension JSONEncoder: @retroactive @unchecked Sendable {}
extension PropertyListEncoder: DataEncoder {}
extension PropertyListEncoder: @retroactive @unchecked Sendable {}
#else
extension JSONEncoder: DataEncoder {}
extension JSONEncoder: @unchecked Sendable {}
extension PropertyListEncoder: DataEncoder {}
extension PropertyListEncoder: @unchecked Sendable {}
#endif
