import Foundation

extension QueryEncoder {
    final class Encoder {
        
        // MARK: - Properties
        let codingPath: [CodingKey]
        let userInfo: [CodingUserInfoKey : Any]
        
        var contents: [String : String]
        
        // MARK: - Initializer
        init(
            codingPath: [CodingKey],
            userInfo: [CodingUserInfoKey : Any]
        ) {
            
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.contents = [:]
        }
    }
}

// MARK: - Encoder
extension QueryEncoder.Encoder: Swift.Encoder {
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) -> Swift.KeyedEncodingContainer<Key> {
        
        let container = QueryEncoder.Encoder.KeyedEncodingContainer<Key>(
            encoder: self,
            codingPath: codingPath
        )
        
        return .init(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Unkeyed containers are not supported.")
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError("Single value containers are not supported.")
    }
}
