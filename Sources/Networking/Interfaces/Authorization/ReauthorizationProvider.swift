
public protocol ReauthorizationProvider<AuthorizationRequest, ReauthorizationRequest>: AuthorizationProvider {
    
    associatedtype ReauthorizationRequest: NetworkRequest

    // MARK: - Functions
    
    func makeReauthorizationRequest() -> ReauthorizationRequest?
        
    func handle(reauthorizationResponse: NetworkResponse<ReauthorizationRequest.ResponseType>, from request: ReauthorizationRequest)
}
