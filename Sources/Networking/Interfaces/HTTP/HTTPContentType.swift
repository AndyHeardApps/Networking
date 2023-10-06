
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

    public static var octetStream: HTTPContentType {
        "application/octet-stream"
    }

    public static var json: HTTPContentType{
        "application/json"
    }
}
