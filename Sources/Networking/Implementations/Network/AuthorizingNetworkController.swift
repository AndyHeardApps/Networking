import Foundation

/// The `AuthorizingNetworkController` is what ties all of the network and converting of data together, including authorization. It accepts a `baseURL` which all submitted requests are resolved against using the provided `NetworkSession`. The `JSONDecoder` is handed to all requests to decode any JSON data.
public struct AuthorizingNetworkController<Authorization, NetworkError>
where Authorization: AuthorizationProvider,
      NetworkError: Error,
      NetworkError: Decodable
{
    
    // MARK: - Properties
    
    /// The base `URL` that all `NetworkRequest`s are resolved against.
    public let baseURL: URL
    
    /// The `NetworkSession` used to fetch `NetworkResponse`s for `NetworkRequest`s.
    public let session: NetworkSession
    
    /// The authorization method to apply to all requests with `requiresAuthorization` equal to `true`.
    public let authorization: Authorization
    
    /// The `JSONDecoder` used to convert any JSON data in `NetworkRequest`s.
    public let jsonDecoder: JSONDecoder
    
    /// A closure that decides whether reauthentication should be attempted when a request returns the provided `Error`.
    public let shouldReauthenticateOnError: (Error) -> Bool
    
    /// An optional set of headers that are applied to all requests submitted through this `AuthorizingNetworkController`.
    public var universalHeaders: [String : String]? = nil
    
    // MARK: - Initialisers
    
    /// Creates a new `NetworkController` instance.
    /// - Parameters:
    ///   - baseURL: The `baseURL` the `AuthorizingNetworkController` uses to resolve requests.
    ///   - session: The `session` the `AuthorizingNetworkController` uses to fetch `Data` for requests.
    ///   - authorization: The `authorization` used to authorize any requests that need it.
    ///   - jsonDecoder: The `JSONDecoder` the `AuthorizingNetworkController` uses to decode JSON data returned by requests.
    ///   -  shouldReauthenticateOnError: A closure that decides whether reauthentication should be attempted when a request returns the provided `Error`. If `nil` is provided (the default), then a `403` response will result in reauthentication being attempted.

    public init(
        baseURL: URL,
        session: NetworkSession = URLSession.shared,
        authorization: Authorization,
        jsonDecoder: JSONDecoder = .init(),
        shouldReauthenticateOnError: ((Error) -> Bool)? = nil
    ) {
        
        self.baseURL = baseURL
        self.session = session
        self.authorization = authorization
        self.jsonDecoder = jsonDecoder
        
        if let shouldReauthenticateOnError {
            self.shouldReauthenticateOnError = shouldReauthenticateOnError
        } else {
            self.shouldReauthenticateOnError = { error in
                switch error {
                case HTTPStatusCode.unauthorized:
                    return true
                default:
                    return false
                }
            }
        }
    }
}

extension AuthorizingNetworkController where Authorization == EmptyAuthorizationProvider {
    
    /// Creates a new `NetworkController` instance.
    /// - Parameters:
    ///   - baseURL: The `baseURL` the `AuthorizingNetworkController` uses to resolve requests.
    ///   - session: The `session` the `AuthorizingNetworkController` uses to fetch `Data` for requests.
    ///   - jsonDecoder: The `JSONDecoder` the `AuthorizingNetworkController` uses to decode JSON data returned by requests.
    public init(
        baseURL: URL,
        session: NetworkSession = URLSession.shared,
        jsonDecoder: JSONDecoder = .init()
    ) {
        
        self.baseURL = baseURL
        self.session = session
        self.authorization = EmptyAuthorizationProvider()
        self.jsonDecoder = jsonDecoder
        self.shouldReauthenticateOnError = { _ in false }
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
        
        do {
            let dataResponse = try await session.submit(request: authorizedRequest, to: baseURL)
            let response = try transform(
                dataResponse: dataResponse,
                from: request
            )
            return response
                        
        } catch {
            
            guard shouldReauthenticateOnError(error) else {
                throw error
            }

            try await reauthorize()

            let reauthorizedRequest = authorize(request: requestWithUniversalHeaders)
            let dataResponse = try await session.submit(request: reauthorizedRequest, to: baseURL)
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
        headers.merge(universalHeaders) { $1 }
        
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
    
    private func transform<Request: NetworkRequest>(dataResponse: NetworkResponse<Data>, from request: Request) throws -> NetworkResponse<Request.ResponseType> {
        
        do {
            let transformedContents = try request.transform(
                data: dataResponse.content,
                statusCode: dataResponse.statusCode,
                using: jsonDecoder
            )
            
            let transformedResponse = NetworkResponse(
                content: transformedContents,
                statusCode: dataResponse.statusCode,
                headers: dataResponse.headers
            )
            extractAuthorizationContent(from: transformedResponse, returnedBy: request)
            
            return transformedResponse
            
        } catch {
            guard let networkError = try? jsonDecoder.decode(NetworkError.self, from: dataResponse.content) else {
                throw error
            }
            
            throw networkError
            
        }
    }
}

// MARK: - Reauthorization
extension AuthorizingNetworkController {
    
    private func reauthorize() async throws {
        
        guard let reauthorizationRequest = authorization.makeReauthorizationRequest(), !reauthorizationRequest.requiresAuthorization else {
            throw HTTPStatusCode.unauthorized
        }
        let requestWithUniversalHeaders = addUniversalHeadersTo(request: reauthorizationRequest)
        
        let dataResponse = try await session.submit(request: requestWithUniversalHeaders, to: baseURL)
        _ = try transform(dataResponse: dataResponse, from: reauthorizationRequest)
    }
}

// MARK: - Authorization content extraction
extension AuthorizingNetworkController {
    
    private func extractAuthorizationContent<Response>(from response: NetworkResponse<Response>, returnedBy request: some NetworkRequest) {
        
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
