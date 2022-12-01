
public protocol AuthorizationProvider<AuthorizationRequest>  {
    
    associatedtype AuthorizationRequest: NetworkRequest

    // MARK: - Functions
    
    func authorize<Request: NetworkRequest>(_ request: Request) -> any NetworkRequest<Request.ResponseType>

    func handle(authorizationResponse: NetworkResponse<AuthorizationRequest.ResponseType>, from request: AuthorizationRequest)    
}
