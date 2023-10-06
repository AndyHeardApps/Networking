import Foundation

public struct DataCoders {
    
    // MARK: - Static properties
    public static let `default`: DataCoders = {
        
        var coders = DataCoders()
        coders.set(JSONDecoder(), for: .json)
        coders.set(JSONEncoder(), for: .json)
        
        return coders
    }()
    
    // MARK: - Properties
    private var encoders: [HTTPContentType : DataEncoder] = [:]
    private var decoders: [HTTPContentType : DataDecoder] = [:]
    
    // MARK: - Initialiser
    public init() {}
}

// MARK: - Setting
extension DataCoders {
    
    public mutating func set(_ encoder: some DataEncoder, for contentType: HTTPContentType) {
        
        encoders[contentType] = encoder
    }
    
    public mutating func set(_ decoder: some DataDecoder, for contentType: HTTPContentType) {
        
        decoders[contentType] = decoder
    }
}

// MARK: - Fetching
extension DataCoders {
    
    public func requireEncoder(for contentType: HTTPContentType) throws -> DataEncoder {
        
        guard let encoder = encoders[contentType] else {
            throw Error.encoderNotSet(contentType: contentType)
        }
        
        return encoder
    }

    public func requireDecoder(for contentType: HTTPContentType) throws -> DataDecoder {
        
        guard let decoder = decoders[contentType] else {
            throw Error.decoderNotSet(contentType: contentType)
        }
        
        return decoder
    }
}

// MARK: - Error
extension DataCoders {
    enum Error {
        
        case encoderNotSet(contentType: HTTPContentType)
        case decoderNotSet(contentType: HTTPContentType)
    }
}

extension DataCoders.Error: LocalizedError {
    
    var errorDescription: String? {
        
        switch self {
            
        case let .encoderNotSet(contentType):
            "No encoder set for 'Content-Type' \(contentType.name)"
            
        case let .decoderNotSet(contentType):
            "No decoder set for 'Content-Type' \(contentType.name)"

        }
    }
}
