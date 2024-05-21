import Foundation

/// A type erased ``WebSocketRequest``.
///
/// **Note:** This is no longer widely used since the introduction of existential types in Swift.
public struct AnyWebSocketRequest<Input, Output>: WebSocketRequest {
    
    // MARK: - Properties
    public let pathComponents: [String]
    public let headers: [String : String]?
    public let queryItems: [String : String]?
    private let _encode: @Sendable (Input, DataCoders) throws -> Data
    private let _decode: @Sendable (Data, DataCoders) throws -> Output

    // MARK: - Initialisers
    public init(
        pathComponents: [String],
        headers: [String : String]?,
        queryItems: [String : String]?,
        encode: @Sendable @escaping (Input, DataCoders) throws -> Data,
        decode: @Sendable @escaping (Data, DataCoders) throws -> Output
    ) {
        
        self.pathComponents = pathComponents
        self.headers = headers
        self.queryItems = queryItems
        self._encode = encode
        self._decode = decode
    }
    
    public init<Request: WebSocketRequest>(_ request: Request)
    where Self.Input == Request.Input,
          Self.Output == Request.Output
    {
        
        self.pathComponents = request.pathComponents
        self.headers = request.headers
        self.queryItems = request.queryItems
        self._encode = { try request.encode(input: $0, using: $1) }
        self._decode = { try request.decode(data: $0, using: $1) }
    }
    
    // MARK: - Coding
    public func encode(
        input: Input,
        using coders: DataCoders
    ) throws -> Data {
        
        try _encode(input, coders)
    }
    
    public func decode(
        data: Data,
        using coders: DataCoders
    ) throws -> Output {
        
        try _decode(data, coders)
    }
}
