import Foundation

/// An encoder that converts basic objects in to a `[String : String]` dictionary for use when creating query dictionaries. This encoder does not support any nesting.
public struct QueryEncoder {
    
    // MARK: - Properties
    let userInfo: [CodingUserInfoKey : Any]
    
    // MARK: - Initializer
    public init(userInfo: [CodingUserInfoKey : Any] = [:]) {
        
        self.userInfo = userInfo
    }
}

// MARK: - Encoding
extension QueryEncoder {
    
    func encode(_ value: Encodable) throws -> [String : String] {
        
        let encoder = Encoder(
            codingPath: [],
            userInfo: userInfo
        )
        try value.encode(to: encoder)
        let contents = encoder.contents

        return contents
    }
}
