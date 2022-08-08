import Foundation

/// An error containing a message from a network response.
public struct NetworkError: Decodable, LocalizedError {
    
    // MARK: - Static properties
    
    /// The `String` representation of a the `CodingKey` that contains the error message in the JSON.
    public static var errorMessageCodingKey: String = "error"
    
    // MARK: - Properties
    public let errorDescription: String?
    
    // MARK: - Initialiser
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        
        guard
            container.allKeys.map(\.stringValue).contains(NetworkError.errorMessageCodingKey),
            let errorKey = DynamicCodingKey(stringValue: NetworkError.errorMessageCodingKey)
        else {
            self.errorDescription = nil
            return
        }
        
        self.errorDescription = try container.decodeIfPresent(String.self, forKey: errorKey)
    }
}

// MARK: - Dynamic coding key
extension NetworkError {
    
    private struct DynamicCodingKey: CodingKey {
        
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
}
