import Foundation

public extension HTTPRequest {
    
    /// Encodes the provided value into a `[String : String]` dictionary for use in the query of the request. The value must not contain any nested `Codable` types.
    /// - Parameters:
    ///   - value: The value to encode
    ///   - encoder: The encoder to when encoding.  If `nil` then a default encoder is used.
    /// - Returns: A `[String : String]` dictionary representation of the `value`.
    static func queryEncode(
        _ value: some Encodable,
        with encoder: QueryEncoder? = nil
    ) -> [String : String] {
        let encoder = encoder ?? .init()
        return (try? encoder.encode(value)) ?? [:]
    }
}
