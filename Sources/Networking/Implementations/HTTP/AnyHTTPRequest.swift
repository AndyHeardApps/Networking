import Foundation

/// A type erased ``HTTPRequest``.
///
/// **Note:** This is no longer widely used since the introduction of existential types in Swift.
public struct AnyHTTPRequest<Body, Response>: HTTPRequest {
    
    // MARK: - Properties
    public let httpMethod: HTTPMethod
    public let pathComponents: [String]
    public let headers: [String : String]?
    public let queryItems: [String : String]?
    private let _body: () -> Body
    public var body: Body {
        _body()
    }
    public let requiresAuthorization: Bool
    private let _encode: ((Body, inout [String : String], DataCoders) throws -> Data)?
    private let _decode: (Data, HTTPStatusCode, DataCoders) throws -> Response
    
    // MARK: - Initialisers
    public init(
        httpMethod: HTTPMethod,
        pathComponents: [String],
        headers: [String : String]?,
        queryItems: [String : String]?,
        body: @autoclosure @escaping () -> Body,
        requiresAuthorization: Bool,
        encode: @escaping (Body, inout [String : String], DataCoders) throws -> Data,
        decode: @escaping (Data, HTTPStatusCode, DataCoders) throws -> Response
    ) {
        
        self.httpMethod = httpMethod
        self.pathComponents = pathComponents
        self.headers = headers
        self.queryItems = queryItems
        self._body = body
        self.requiresAuthorization = requiresAuthorization
        self._encode = encode
        self._decode = decode
    }
    
    public init<Request: HTTPRequest>(_ request: Request)
    where Self.Response == Request.Response,
          Self.Body == Request.Body
    {
        
        self.httpMethod = request.httpMethod
        self.pathComponents = request.pathComponents
        self.headers = request.headers
        self.queryItems = request.queryItems
        self._body = { request.body }
        self.requiresAuthorization = request.requiresAuthorization
        self._encode = request.encode
        self._decode = request.decode
    }

    // MARK: - Coding
    public func encode(
        body: Body,
        headers: inout [String : String],
        using coders: DataCoders
    ) throws -> Data {
        
        guard let _encode else {
            fatalError("Attempting to encode body of type Never")
        }
        return try _encode(body, &headers, coders)
    }
    
    public func decode(
        data: Data,
        statusCode: HTTPStatusCode,
        using coders: DataCoders
    ) throws -> Response {
        
        try _decode(data, statusCode, coders)
    }
}

extension AnyHTTPRequest where Body == Data {
    
    init(
        httpMethod: HTTPMethod,
        pathComponents: [String],
        headers: [String : String]?,
        queryItems: [String : String]?,
        body: Data,
        requiresAuthorization: Bool,
        decode: @escaping (Data, HTTPStatusCode, DataCoders) throws -> Response
    ) {
        
        self.httpMethod = httpMethod
        self.pathComponents = pathComponents
        self.headers = headers
        self.queryItems = queryItems
        self._body = { body }
        self.requiresAuthorization = requiresAuthorization
        self._encode = { body, _, _ in
            body
        }
        self._decode = decode
    }
}
