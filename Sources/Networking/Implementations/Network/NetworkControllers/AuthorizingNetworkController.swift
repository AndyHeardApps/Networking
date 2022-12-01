import Foundation

public struct AuthorizingNetworkController<Authorization: AuthorizationProvider> {
    
    // MARK: - Properties
    
    public let baseURL: URL
    
    public let session: NetworkSession
        
    public let authorization: Authorization
    
    public let decoder: DataDecoder
    
    public let errorHandler: (any NetworkErrorHandler<Error>)?

    public let universalHeaders: [String : String]?
    
    // MARK: - Initialisers

    public init(
        baseURL: URL,
        session: NetworkSession = URLSession.shared,
        authorization: Authorization,
        decoder: DataDecoder = JSONDecoder(),
        errorHandler: (any NetworkErrorHandler<Error>)? = nil,
        universalHeaders: [String : String]? = nil
    ) {
        
        self.baseURL = baseURL
        self.session = session
        self.authorization = authorization
        self.decoder = decoder
        self.errorHandler = errorHandler
        self.universalHeaders = universalHeaders
    }
}

// MARK: - Network controller
extension AuthorizingNetworkController: NetworkController {
    
    public func fetchResponse<Request: NetworkRequest>(_ request: Request) async throws -> NetworkResponse<Request.ResponseType> {
        
        let requestWithUniversalHeaders = add(
            universalHeaders: universalHeaders,
            to: request
        )
        let authorizedRequest = authorize(request: requestWithUniversalHeaders)
        
        let dataResponse = try await session.submit(
            request: authorizedRequest,
            to: baseURL
        )
        
        do {
            let response = try transform(
                dataResponse: dataResponse,
                from: request,
                using: decoder
            )
            
            extractAuthorizationContent(
                from: response,
                returnedBy: request
            )
            
            return response
            
        } catch {
            
            guard let errorHandler else {
                throw error
            }
            
            let handledError = errorHandler.handle(
                error,
                from: dataResponse
            )
            
            throw handledError
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
}
    
// MARK: - Authorized content extraction
extension AuthorizingNetworkController {
    
    private func extractAuthorizationContent<Response>(
        from response: NetworkResponse<Response>,
        returnedBy request: some NetworkRequest
    ) {
        
        if
            let authorizationRequest = request as? Authorization.AuthorizationRequest,
            let authorizionResponse = response as? NetworkResponse<Authorization.AuthorizationRequest.ResponseType>
        {
            authorization.handle(
                authorizationResponse: authorizionResponse,
                from: authorizationRequest
            )
        }
    }
}
