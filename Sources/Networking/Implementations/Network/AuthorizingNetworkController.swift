import Foundation

/// The `AuthorizingNetworkController` is what ties all of the networking and converting of data together, including authorization. It accepts a `baseURL` which all submitted requests are resolved against using the provided `NetworkSession`. The `DataDecoder` is handed to all requests to decode any `Data` returned by a request. The `AuthorizationProvider` provided is used to authorize all requests that return `true` for `requiresAuthorization`. If a request fails, the controller can attempt to reauthorize and retry the request when the  provided`AuthorizationErrorHandler` `handle` function returns `.attemptReauthorization`.
public struct AuthorizingNetworkController<Authorization> where Authorization: AuthorizationProvider {
    
    // MARK: - Properties
    
    /// The base `URL` that all `NetworkRequest`s are resolved against.
    public let baseURL: URL
    
    /// The `NetworkSession` used to fetch `NetworkResponse`s for `NetworkRequest`s.
    public let session: NetworkSession
    
    /// The authorization method to apply to all requests with `requiresAuthorization` equal to `true`.
    public let authorization: Authorization

    /// The `AuthorizationErrorHandler` used to handle errors and decide whether or not to attempt reauthorization and request resubmission.
    public let errorHandler: AuthorizationErrorHandler
    
    /// The `DataDecoder` provided to `NetworkRequest` `transform` methods used to convert any `Data`.
    public let decoder: DataDecoder
    
    /// An optional set of headers that are applied to all requests submitted through this `AuthorizingNetworkController`.
    public var universalHeaders: [String : String]? = nil
    
    // MARK: - Initialisers
    
    /// Creates a new `NetworkController` instance.
    /// - Parameters:
    ///   - baseURL: The `baseURL` the `AuthorizingNetworkController` uses to resolve requests.
    ///   - session: The `session` the `AuthorizingNetworkController` uses to fetch the request `Data`.
    ///   - authorization: The `authorization` used to authorize any requests that need it.
    ///   - errorHandler: The `AuthorizationErrorHandler` used to handle errors and decide whether or not to attempt reauthorization and request resubmission. The default handler will try to reauthorize when a `HTTPStatusCode.unauthorized` error is recieved, otherwise, the error is thrown unmodified.
    ///   - decoder: The `DataDecoder` provided to `NetworkRequest` `transform` methods used to convert any `Data`.

    public init(
        baseURL: URL,
        session: NetworkSession = URLSession.shared,
        authorization: Authorization,
        errorHandler: AuthorizationErrorHandler = DefaultAuthorizationErrorHandler(),
        decoder: DataDecoder = JSONDecoder()
    ) {
        
        self.baseURL = baseURL
        self.session = session
        self.authorization = authorization
        self.errorHandler = errorHandler
        self.decoder = decoder
    }
}

extension AuthorizingNetworkController where Authorization == EmptyAuthorizationProvider {
    
    /// Creates a new `NetworkController` instance.
    /// - Parameters:
    ///   - baseURL: The `baseURL` the `AuthorizingNetworkController` uses to resolve requests.
    ///   - session: The `session` the `AuthorizingNetworkController` uses to fetch the request `Data`.
    ///   - decoder: The `DataDecoder` provided to `NetworkRequest` `transform` methods used to convert any `Data`.
    public init(
        baseURL: URL,
        session: NetworkSession = URLSession.shared,
        decoder: DataDecoder = JSONDecoder()
    ) {
        
        self.baseURL = baseURL
        self.session = session
        self.authorization = EmptyAuthorizationProvider()
        self.errorHandler = DefaultAuthorizationErrorHandler()
        self.decoder = decoder
    }
}

// MARK: - Network controller
extension AuthorizingNetworkController: NetworkController {
    
    public func fetchContent<Request: NetworkRequest>(_ request: Request) async throws -> Request.ResponseType {
        
        let response = try await fetchResponse(request)
        
        return response.content
    }
    
    public func fetchResponse<Request: NetworkRequest>(_ request: Request) async throws -> NetworkResponse<Request.ResponseType> {
        
        let requestWithUniversalHeaders = addUniversalHeadersTo(request: request)
        let authorizedRequest = authorize(request: requestWithUniversalHeaders)
        
        // Errors thrown here cannot be fixed with reauth
        let dataResponse = try await session.submit(
            request: authorizedRequest,
            to: baseURL
        )
        
        do {
            let response = try transform(
                dataResponse: dataResponse,
                from: request
            )
            
            return response
                        
        } catch {
            
            switch errorHandler.handle(error, from: dataResponse) {
            case .attemptReauthorization:
                break
                
            case .error(let error):
                throw error
                
            }

            try await reauthorize()

            let reauthorizedRequest = authorize(request: requestWithUniversalHeaders)
            let dataResponse = try await session.submit(
                request: reauthorizedRequest,
                to: baseURL
            )
            let response = try transform(
                dataResponse: dataResponse,
                from: request
            )

            return response
        }
    }
}

// MARK: - Request modification
extension AuthorizingNetworkController {
    
    private func authorize<Request: NetworkRequest>(request: Request) -> any NetworkRequest<Request.ResponseType> {
        
        guard request.requiresAuthorization else {
            return request
        }
        
        let authorizedRequest = authorization.authorize(request)
        
        return authorizedRequest
    }
    
    private func addUniversalHeadersTo<Request: NetworkRequest>(request: Request) -> any NetworkRequest<Request.ResponseType> {
        
        guard let universalHeaders else {
            return request
        }
        
        var headers = request.headers ?? [:]
        headers.merge(universalHeaders) { requestHeader, universalHeader in
            requestHeader
        }
        
        let updatedRequest = AnyRequest(
            httpMethod: request.httpMethod,
            pathComponents: request.pathComponents,
            headers: headers,
            queryItems: request.queryItems,
            body: request.body,
            requiresAuthorization: request.requiresAuthorization,
            transform: request.transform
        )
        
        return updatedRequest
    }
}

// MARK: - Response transform
extension AuthorizingNetworkController {
    
    private func transform<Request: NetworkRequest>(
        dataResponse: NetworkResponse<Data>,
        from request: Request
    ) throws -> NetworkResponse<Request.ResponseType> {
        
        let transformedContents = try request.transform(
            data: dataResponse.content,
            statusCode: dataResponse.statusCode,
            using: decoder
        )
        
        let transformedResponse = NetworkResponse(
            content: transformedContents,
            statusCode: dataResponse.statusCode,
            headers: dataResponse.headers
        )
        extractAuthorizationContent(from: transformedResponse, returnedBy: request)
        
        return transformedResponse
    }
}

// MARK: - Reauthorization
extension AuthorizingNetworkController {
    
    private func reauthorize() async throws {
        
        guard
            let reauthorizationRequest = authorization.makeReauthorizationRequest(),
            !reauthorizationRequest.requiresAuthorization
        else {
            throw HTTPStatusCode.unauthorized
        }
        
        let requestWithUniversalHeaders = addUniversalHeadersTo(request: reauthorizationRequest)
        
        let dataResponse = try await session.submit(request: requestWithUniversalHeaders, to: baseURL)
        _ = try transform(dataResponse: dataResponse, from: reauthorizationRequest)
    }
}

// MARK: - Authorization content extraction
extension AuthorizingNetworkController {
    
    private func extractAuthorizationContent<Response>(
        from response: NetworkResponse<Response>,
        returnedBy request: some NetworkRequest
    ) {
        
        if
            let authorizationRequest = request as? Authorization.AuthorizationRequest,
            let authorizionResponse = response as? NetworkResponse<Authorization.AuthorizationRequest.ResponseType>
        {
            authorization.handle(authorizationResponse: authorizionResponse, from: authorizationRequest)
        }
        
        if
            let reauthorizationRequest = request as? Authorization.ReauthorizationRequest,
            let reauthorizionResponse = response as? NetworkResponse<Authorization.ReauthorizationRequest.ResponseType>
        {
            authorization.handle(reauthorizationResponse: reauthorizionResponse, from: reauthorizationRequest)
        }
    }
}
