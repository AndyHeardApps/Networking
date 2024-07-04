import Foundation

/// A collection of ``DataEncoder`` and ``DataDecoder`` objects for specific ``HTTPContentType`` values. 
///
/// Each ``HTTPContentType`` can have one encoder and one decoder registered. The coders can be fetched during ``HTTPRequest/encode(body:headers:using:)-7qe3v``, and ``HTTPRequest/decode(data:statusCode:using:)`` to allow shared coders to be used across all requests.
/// The coders being used can be updated for a specific ``HTTPContentType`` using the ``DataCoders/set(_:for:)-63yj2`` and ``DataCoders/set(_:for:)-3sjye`` functions, and then fetched using the ``DataCoders/requireEncoder(for:)`` and ``DataCoders/requireDecoder(for:)`` functions.
public struct DataCoders: Sendable {

    // MARK: - Static properties
    
    /// The default ``DataCoders``, containing only `JSONEncoder` and `JSONDecoder` for ``HTTPContentType/json``.
    public static let `default`: DataCoders = {
        
        var coders = DataCoders()
        coders.set(JSONDecoder(), for: .json)
        coders.set(JSONEncoder(), for: .json)
        
        return coders
    }()
    
    // MARK: - Properties
    private var encoders: [HTTPContentType : DataEncoder & Sendable] = [:]
    private var decoders: [HTTPContentType : DataDecoder & Sendable] = [:]

    // MARK: - Initialiser
    
    /// Creates a set of empty ``DataCoders``.
    public init() {}
}

// MARK: - Setting
extension DataCoders {
    
    /// Sets the provided `encoder` for the specified `contentType`. This will override any existing value.
    /// - Parameters:
    ///   - encoder: The ``DataEncoder`` to use for the provided content type.
    ///   - contentType: The ``HTTPContentType`` to use the encoder for.
    public mutating func set(
        _ encoder: some DataEncoder & Sendable,
        for contentType: HTTPContentType
    ) {
        
        encoders[contentType] = encoder
    }
    
    /// Sets the provided `decoder` for the specified `contentType`. This will override any existing value.
    /// - Parameters:
    ///   - decoder: The ``DataDecoder`` to use for the provided content type.
    ///   - contentType: The ``HTTPContentType`` to use the decoder for.
    public mutating func set(
        _ decoder: some DataDecoder & Sendable,
        for contentType: HTTPContentType
    ) {
        
        decoders[contentType] = decoder
    }
}

// MARK: - Fetching
extension DataCoders {
    
    /// Fetches the encoder for the specified `contentType`.
    /// - Parameter contentType: The ``HTTPContentType`` to fetch a ``DataEncoder`` for.
    /// - Returns: A ``DataEncoder`` that can be used for encoding to the provided `contentType`.
    /// - Throws: An error if no ``DataEncoder`` has been set for the `contentType`.
    public func requireEncoder(for contentType: HTTPContentType) throws -> DataEncoder {
        
        guard let encoder = encoders[contentType] else {
            throw Error.encoderNotSet(contentType: contentType)
        }
        
        return encoder
    }

    /// Fetches the decoder for the specified `contentType`.
    /// - Parameter contentType: The ``HTTPContentType`` to fetch a ``DataDecoder`` for.
    /// - Returns: A ``DataDecoder`` that can be used for decoding to the provided `contentType`.
    /// - Throws: An error if no ``DataEncoder`` has been set for the `contentType`.
    public func requireDecoder(for contentType: HTTPContentType) throws -> DataDecoder {
        
        guard let decoder = decoders[contentType] else {
            throw Error.decoderNotSet(contentType: contentType)
        }
        
        return decoder
    }
}

// MARK: - Error
extension DataCoders {
    enum Error: Equatable {

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
