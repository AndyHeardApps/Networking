import Foundation

/// A type that defines a method for encoding to `Data`.
///
/// The `JSONEncoder` and `PropertyListEncoder` Swift types conform to this protocol by default.
public protocol DataEncoder {
    
    /// Converts an encodable object to `Data`.
    /// - Parameters:
    ///   - value: The value to attempt to encode.
    /// - Returns: The data representation of the value.
    func encode(_ value: some Encodable) throws -> Data
}

extension JSONEncoder: DataEncoder {}
extension PropertyListEncoder: DataEncoder {}
