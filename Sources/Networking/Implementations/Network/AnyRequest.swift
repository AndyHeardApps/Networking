import Foundation
import Combine

/// A type-erased request that can wrap any other request to allow for concrete `NetworkRequest` implementations to be passed around.
public struct AnyRequest<ResponseType>: NetworkRequest {
    
    // MARK: Properties
    public let httpMethod: HTTPMethod
    public let pathComponents: [String]
    public let headers: [String : String]?
    public let queryItems: [String : String]?
    public let body: Data?
    public let requiresAuthorization: Bool
    private let _transform: (Data, HTTPStatusCode, DataDecoder) throws -> ResponseType
    
    // MARK: Initialisers
    public init(
        httpMethod: HTTPMethod,
        pathComponents: [String],
        headers: [String : String]?,
        queryItems: [String : String]?,
        body: Data?,
        requiresAuthorization: Bool,
        transform: @escaping (Data, HTTPStatusCode, DataDecoder) throws -> ResponseType
    ) {
        self.httpMethod = httpMethod
        self.pathComponents = pathComponents
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.requiresAuthorization = requiresAuthorization
        self._transform = transform
    }
    
    public init<Request: NetworkRequest>(_ request: Request) where Self.ResponseType == Request.ResponseType {
        
        self.httpMethod = request.httpMethod
        self.pathComponents = request.pathComponents
        self.headers = request.headers
        self.queryItems = request.queryItems
        self.body = request.body
        self.requiresAuthorization = request.requiresAuthorization
        self._transform = request.transform
    }
    
    // MARK: - Transform
    public func transform(data: Data, statusCode: HTTPStatusCode, using decoder: DataDecoder) throws -> ResponseType {
        
        try _transform(data, statusCode, decoder)
    }
}
