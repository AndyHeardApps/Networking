
/// Defines types expressible in the `Content-Type` HTTP header.
public struct HTTPContentType: Hashable, ExpressibleByStringLiteral {
    
    // MARK: - Properties
    let name: String
    
    // MARK: - Initialiser
    public init(stringLiteral value: StringLiteralType) {
        
        self.name = String(value)
    }
}

// MARK: - Types
extension HTTPContentType {

    /// The `application/octet-stream` `Content-Type`.
    public static var octetStream: HTTPContentType {
        "application/octet-stream"
    }

    /// The `application/json` `Content-Type`.
    public static var json: HTTPContentType{
        "application/json"
    }
}
