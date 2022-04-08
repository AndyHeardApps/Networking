import Foundation

/// The `NetworkController` is what ties all of the network and converting of data together, including authentication. It accepts a `baseURL` which all submitted requests are resolved against using the provided `NetworkSession`. The `JSONDecoder` is handed to all requests to decode any JSON data.
public struct NetworkController {
    
    // MARK: - Static properties
    private static let authorizationHeaderName = "Authorization"
    private static var authorizationToken: String?
    
    // MARK: - Properties
    
    /// The base `URL` that all `NetworkRequest`s are resolved against.
    public let baseURL: URL
    
    /// The `NetworkSession` used to fetch `NetworkResponse`s for `NetworkRequest`s.
    public let session: NetworkSession
    
    /// The `JSONDecoder` used to convert any JSON data in `NetworkRequest`s.
    public let jsonDecoder: JSONDecoder
    
    // MARK: - Initialiser
    
    /// Creates a new `NetworkController` instance.
    /// - Parameters:
    ///   - baseURL: The `baseURL` the `NetworkController` uses to resolve requests.
    ///   - session: The `session` the `NetworkController` uses to fetch `Data` for requests.
    ///   - jsonDecoder: The `jsondDecoder` the `NetworkController` uses to decode JSON data returned by requests.
    public init(baseURL: URL, session: NetworkSession, jsonDecoder: JSONDecoder = .init()) {
        
        self.baseURL = baseURL
        self.session = session
        self.jsonDecoder = jsonDecoder
    }
}

// MARK: - Submit
extension NetworkController {
    
    /// Submits a `request` and returns only the transformed contents of the `request`.
    /// - Parameters:
    ///     - request: The request to be submitted.
    /// - Returns: The transformed contents of the `request`s endpoint.
    public func fetchContents<Request: NetworkRequest>(_ request: Request) async throws -> Request.ResponseType {
        
        let response = try await fetchResponse(request)
        return response.contents
    }
    
    /// Submits a `request` and returns the transformed contents of the `request` alongside the `HTTPStatusCode` and `headers`.
    /// - Parameters:
    ///     - request: The request to be submitted.
    /// - Returns: A `NetworkResponse` containing transformed contents of the `request`s endpoint, as well as the `HTTPStatusCode` and `headers` returned.
    public func fetchResponse<Request: NetworkRequest>(_ request: Request) async throws -> NetworkResponse<Request.ResponseType> {

        let response: NetworkResponse<Data>
        if request.requiresAuthorization {
            let authorizedRequest = AuthorizedRequest(request, authorizationToken: "")
            response = try await session.submit(request: authorizedRequest, to: baseURL)
        } else {
            response = try await session.submit(request: request, to: baseURL)
        }
        
        let transformedContent = try request.transform(data: response.contents, using: jsonDecoder)
        
        return .init(
            contents: transformedContent,
            statusCode: response.statusCode,
            headers: response.headers
        )
    }
}

// MARK: - Authorized request
extension NetworkController {
    
    private struct AuthorizedRequest<ResponseType>: NetworkRequest {
        
        // MARK: Properties
        let httpMethod: HTTPMethod
        let pathComponents: [String]
        let headers: [String : String]?
        let queryItems: [String : String]?
        let body: Data?
        let requiresAuthorization: Bool
        private let _transform: (Data, JSONDecoder) throws -> ResponseType
        
        // MARK: Initialiser
        init<Request: NetworkRequest>(_ request: Request, authorizationToken: String) where ResponseType == Request.ResponseType {
            
            self.httpMethod = request.httpMethod
            self.pathComponents = request.pathComponents
            self.queryItems = request.queryItems
            self.body = request.body
            self.requiresAuthorization = request.requiresAuthorization
            self._transform = request.transform
            
            var headers = request.headers ?? [:]
            headers[NetworkController.authorizationHeaderName] = authorizationToken
            self.headers = headers
        }
        
        func transform(data: Data, using decoder: JSONDecoder) throws -> ResponseType {
            
            try _transform(data, decoder)
        }
    }
}
