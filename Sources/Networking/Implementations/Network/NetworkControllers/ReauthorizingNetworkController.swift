import Foundation

public struct ReauthorizingNetworkController<Authorization: ReauthorizationProvider> {
    
    // MARK: - Properties
    
    public let baseURL: URL
    
    public let session: NetworkSession
    
    public let authorization: Authorization
    
    public let decoder: DataDecoder
    
    public let errorHandler: (any NetworkErrorHandler<ReauthorizationErrorHandlerResult>)?
    
    public let universalHeaders: [String : String]?
    
    // MARK: - Initialisers

    public init(
        baseURL: URL,
        session: NetworkSession = URLSession.shared,
        authorization: Authorization,
        decoder: DataDecoder = JSONDecoder(),
        errorHandler: (any NetworkErrorHandler<ReauthorizationErrorHandlerResult>)? = nil,
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
extension ReauthorizingNetworkController: NetworkController {
    
    public func fetchResponse<Request: NetworkRequest>(_ request: Request) async throws -> NetworkResponse<Request.ResponseType> {
        
        let requestWithUniversalHeaders = add(universalHeaders: universalHeaders, to: request)
        let authorizedRequest = authorize(request: requestWithUniversalHeaders)
        
        // Errors thrown here cannot be fixed with reauth
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
            
            switch handle(error, from: dataResponse) {
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
                from: request,
                using: decoder
            )
            
            extractAuthorizationContent(
                from: response,
                returnedBy: request
            )
            
            return response
        }
    }
}

// MARK: - Request modification
extension ReauthorizingNetworkController {
    
    private func authorize<Request: NetworkRequest>(request: Request) -> any NetworkRequest<Request.ResponseType> {
        
        guard request.requiresAuthorization else {
            return request
        }
        
        let authorizedRequest = authorization.authorize(request)
        
        return authorizedRequest
    }
}

// MARK: - Error handler
extension ReauthorizingNetworkController {
    
    private func handle(_ error: Error, from response: NetworkResponse<Data>) -> ReauthorizationErrorHandlerResult {
        
        if let errorHandler {
            return errorHandler.handle(error, from: response)
        }
        
        switch error {
        case HTTPStatusCode.unauthorized:
            return .attemptReauthorization
            
        default:
            return .error(error)
            
        }
    }
}

// MARK: - Reauthorization
extension ReauthorizingNetworkController {
    
    private func reauthorize() async throws {
        
        guard
            let reauthorizationRequest = authorization.makeReauthorizationRequest(),
            !reauthorizationRequest.requiresAuthorization
        else {
            throw HTTPStatusCode.unauthorized
        }
        
        let requestWithUniversalHeaders = add(universalHeaders: universalHeaders, to: reauthorizationRequest)
        
        let dataResponse = try await session.submit(
            request: requestWithUniversalHeaders,
            to: baseURL
        )
        _ = try transform(
            dataResponse: dataResponse,
            from: reauthorizationRequest,
            using: decoder
        )
    }
}

// MARK: - Authorized content extraction
extension ReauthorizingNetworkController {
    
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
        
        if
            let reauthorizationRequest = request as? Authorization.ReauthorizationRequest,
            let reauthorizionResponse = response as? NetworkResponse<Authorization.ReauthorizationRequest.ResponseType>
        {
            authorization.handle(
                reauthorizationResponse: reauthorizionResponse,
                from: reauthorizationRequest
            )
        }
    }
}
