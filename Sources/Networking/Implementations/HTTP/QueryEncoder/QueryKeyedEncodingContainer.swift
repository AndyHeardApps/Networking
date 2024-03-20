import Foundation

extension QueryEncoder.Encoder {
    struct KeyedEncodingContainer<Key: CodingKey> {
        
        // MARK: - Properties
        private let encoder: QueryEncoder.Encoder
        let codingPath: [CodingKey]
                
        // MARK: - Initializer
        init(
            encoder: QueryEncoder.Encoder,
            codingPath: [CodingKey]
        ) {
            
            self.encoder = encoder
            self.codingPath = codingPath
        }
    }
}

// MARK: - Keyed encoding container
extension QueryEncoder.Encoder.KeyedEncodingContainer: KeyedEncodingContainerProtocol {
    
    mutating func encodeNil(forKey key: Key) throws {
        encoder.contents.removeValue(forKey: key.stringValue)
    }
    
    mutating func encode(
        _ value: Bool,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = value ? "true" : "false"
    }
    
    mutating func encode(
        _ value: String,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = value
    }
    
    mutating func encode(
        _ value: Double,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = String(describing: value)
    }
    
    mutating func encode(
        _ value: Float,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = String(describing: value)
    }
    
    mutating func encode(
        _ value: Int,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = String(describing: value)
    }
    
    mutating func encode(
        _ value: Int8,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = String(describing: value)
    }
    
    mutating func encode(
        _ value: Int16,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = String(describing: value)
    }
    
    mutating func encode(
        _ value: Int32,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = String(describing: value)
    }
    
    mutating func encode(
        _ value: Int64,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = String(describing: value)
    }
    
    mutating func encode(
        _ value: UInt,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = String(describing: value)
    }
    
    mutating func encode(
        _ value: UInt8,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = String(describing: value)
    }
    
    mutating func encode(
        _ value: UInt16,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = String(describing: value)
    }
    
    mutating func encode(
        _ value: UInt32,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = String(describing: value)
    }
    
    mutating func encode(
        _ value: UInt64,
        forKey key: Key
    ) throws {
        encoder.contents[key.stringValue] = String(describing: value)
    }
    
    mutating func encode<T: Encodable>(
        _ value: T,
        forKey key: Key
    ) throws {
        if let rawRepresentable = value as? any RawRepresentable<String> {
            encoder.contents[key.stringValue] = rawRepresentable.rawValue
        } else if let stringConvertible = value as? CustomStringConvertible {
            encoder.contents[key.stringValue] = stringConvertible.description
        } else {
            throw EncodingError.invalidValue(value, .init(codingPath: codingPath, debugDescription: "Type must be RawRepresentable<String> or CustomStringConvertible."))
        }
    }
    
    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        fatalError("Nested containers are not supported.")
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError("Nested containers are not supported.")
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        encoder
    }
    
    mutating func superEncoder() -> Encoder {
        encoder
    }
}
